; ============================================================================
;  Toy Story (SNES, 1995) - sound driver by Allister Brimble
;  Annotated disassembly of code/tables $0200-$13F8
;  Source: "03 - That Old Army Game.spc" (dumper Knurek)
;  Disassembled from the ARAM image; labels and comments are reconstructions.
;  SPC700 syntax: !abs, $dp, [dp]+Y, (X) etc.
; ============================================================================
;
;  ARAM MAP
;   $0000-$005A  zero page (see ZP list below)       $00F0-$00FF  I/O
;   $0100-$011F  sample directory: 8 entries, SRCN n = voice n (rewritten per note)
;   $0120-$01FF  stack (SP starts $FF)
;   $0200-$13F8  driver code + tables (this file)
;   $13F9-$14F8  per-track arrays (16 bytes each)
;   $14F9-$15F8  sample pointer table lo/hi (128 samples)
;   $15F9-$1EF8  region tables, 18 x 128 bytes (column-major, see extractor)
;   $1EF9-$1FD8  per-voice arrays (8 bytes each)
;   $1FD9-$2058  pitch envelope pointer table lo/hi (64)
;   $2059-$2178  synth wave buffers, 36 bytes per voice
;   $2179-...    upload area: pitch envelopes, samples, song (pointer $14/$15)
;   top of RAM   echo buffer (ESA = ~(EDL*8)), unused in practice
;
;  ZERO PAGE
;   $00 last CPU command     $01-$03 command args      $04-$0B scratch
;   $0C-$11 SMul8 operands/result                      $12/$13 LFSR
;   $14/$15 upload pointer   $16/$17 upload mark       $18 song volume
;   $19 master vol  $1A fade target  $1B fade speed  $1C fade counter
;   $1D KON accumulator      $1E current voice         $1F current program/region
;   $20 current track  $21 note  $22 velocity  $23 duration
;   $24 noise-block index    $25/$26 event pointer     $27/$28 song base
;   $29 LFO frame counter    $2B/$2C sequencer clock   $2D timer0 ticks this pass
;   $2F-$46 level meter buffer (cmd $17/$18)           $4F SFX track (15)
;   $50 clock multiplier  $51 stereo  $52 walk dir  $53 random-walk LFO
;   $54 half-rate LFO  $55 double-rate LFO  $57/$58/$59 global PWM step/limit/pos
;   $5A pause
;
;  PER-TRACK (+track 0-15)
;   $13F9/$1409 event ptr   $1419/$1429 loop ptr (hi 0 = none)
;   $1439/$1449 next event time   $1459 active   $1489 program
;   $1499 pitch-env enable  $14A9 glide/legato  $14B9 pan  $14C9 volume
;   $14D9 polyphony  $14E9 priority
;
;  PER-VOICE (+voice 0-7)
;   $1EF9 last ENVX  $1F01 key-on delay  $1F09 region  $1F11 track  $1F19 note
;   $1F21/$1F29 pitch (fine / note+transpose)  $1F31 velocity volume
;   $1F39 priority (0 = free)  $1F41 env frames left  $1F49 env offset
;   $1F51/$1F59 env value  $1F61/$1F69 env slope  $1F71 polyphony counter
;   $1F79 flags: b0 pitch dirty, b6 volume dirty, b7 released
;   $1F81 gate (ticks)  $1F89 pan  $1F99/$1FA1 glide offset  $1FA9 sample #
;   $1FB1/$1FB9 sample tune  $1FC1/$1FC9/$1FD1 synth position/step/limit
;
;  TIMING: timer0 = sequencer (10000/BPM x 125 us, 48 ticks per quarter at
;          multiplier 1); timer1 = 10 ms frames (all effects, key-on, volume).

;=============================================================================
; RESET  (entry point; the SPC dump's IPL upload jumps here)
; - clears ZP $00-$EF and ALL RAM $13F9-$FFFF (song/samples are uploaded later
;   by CPU commands), checksums the driver code $0200-$13F8 into port 3,
;   initialises tables, DSP, timers and globals, then syncs with the CPU
;   (writes $33 to ports 0-2 until the CPU echoes $33 on port 0).
;=============================================================================
Reset:
        0200: C0        DI
        0201: 20        CLRP
        0202: CD FF     MOV X,#$FF
        0204: BD        MOV SP,X
        0205: D8 F4     MOV $F4,X
        0207: D8 F5     MOV $F5,X
        0209: D8 F6     MOV $F6,X
        020B: D8 F7     MOV $F7,X
        020D: E8 00     MOV A,#$00
        020F: CD F0     MOV X,#$F0
  .clrZP:
        0211: 1D        DEC X
        0212: C6        MOV (X),A
        0213: D0 FC     BNE .clrZP             ; clear $00-$EF
        0215: 8F F9 04  MOV $04,#$F9           ; $04/05 = $13F9: clear everything above the driver
        0218: 8F 13 05  MOV $05,#$13
        021B: FD        MOV Y,A
  .clrHigh:
        021C: D7 04     MOV [$04]+Y,A
        021E: 3A 04     INCW $04
        0220: D0 FA     BNE .clrHigh
        0222: 8F 00 04  MOV $04,#$00           ; checksum: A = rotate-add of $0200..$13F8 ($11F9 bytes)
        0225: 8F 02 05  MOV $05,#$02
        0228: 8F F9 06  MOV $06,#$F9
        022B: 8F 11 07  MOV $07,#$11
        022E: FD        MOV Y,A
        022F: 60        CLRC
  .cksum:
        0230: 97 04     ADC A,[$04]+Y
        0232: 3C        ROL A
        0233: 3A 04     INCW $04
        0235: 1A 06     DECW $06
        0237: D0 F7     BNE .cksum
        0239: C4 F7     MOV $F7,A              ; port 3 = checksum
        023B: 3F 09 0F  CALL !DSPReset         ; DSP reset (all voices off, echo off, DIR=$01)
        023E: 3F 02 0A  CALL !InitSampleTable  ; all 128 samples -> DefaultSample
        0241: 3F 12 0A  CALL !InitPitchEnvTable ; all 64 pitch envelopes -> DefaultPitchEnv
        0244: 3F 3A 0A  CALL !FreeAllVoices    ; all voices free (priority 0)
        0247: 3F C3 05  CALL !InitTracks       ; all 16 tracks: defaults, inactive
        024A: 3F 2B 0A  CALL !InitRegions      ; all 128 regions: khi=0, next=$FF
        024D: 3F 9E 04  CALL !ResetUploadPtr   ; upload pointer = $2179
        0250: 8F 0F 4F  MOV $4F,#$0F           ; SFX/direct-note track = 15
        0253: E8 7F     MOV A,#$7F             ; master volume $7F immediately
        0255: 8D 00     MOV Y,#$00
        0257: 3F 2C 05  CALL !SetMasterFade
        025A: 8F 30 F1  MOV $F1,#$30           ; reset ports, stop timers
        025D: E8 53     MOV A,#$53             ; timer0 = $53 (10.375 ms) = sequencer clock, set by tempo event
        025F: C4 FA     MOV $FA,A
        0261: E8 50     MOV A,#$50             ; timer1 = $50 (10.0 ms) = frame clock (effects)
        0263: C4 FB     MOV $FB,A
        0265: 8F 03 F1  MOV $F1,#$03           ; start timers 0+1
        0268: 8F 01 50  MOV $50,#$01           ; clock multiplier = 1
        026B: 8F 01 51  MOV $51,#$01           ; stereo on
        026E: 8F 00 53  MOV $53,#$00           ; LFO $53 (random walk) = 0
        0271: 8F 01 52  MOV $52,#$01           ; $52 = random-walk direction +1
        0274: 8F 00 54  MOV $54,#$00           ; LFO $54 (half rate)
        0277: 8F 20 29  MOV $29,#$20           ; LFO $29 (frame counter)
        027A: 8F 40 55  MOV $55,#$40           ; LFO $55 (double rate)
        027D: 8F 02 57  MOV $57,#$02           ; global PWM step +2
        0280: 8F FE 58  MOV $58,#$FE           ; global PWM limit $FE
        0283: E8 33     MOV A,#$33
  .syncCPU:
        0285: C4 F4     MOV $F4,A
        0287: C4 F5     MOV $F5,A
        0289: C4 F6     MOV $F6,A
        028B: 64 F4     CMP A,$F4
        028D: D0 F6     BNE .syncCPU
        028F: C4 00     MOV $00,A              ; $00 = last command seen
;-----------------------------------------------------------------------------
; MAIN LOOP - no interrupts; polls the timers and the CPU port forever.
;  NoiseWaveUpdate runs every pass, so the noise blocks change at a rate set
;  by CPU load rather than by a timer.
;-----------------------------------------------------------------------------
MainLoop:
        0291: 3F 9C 02  CALL !TimerService
        0294: 3F 1C 03  CALL !PollCPU
        0297: 3F AB 07  CALL !NoiseWaveUpdate
        029A: 2F F5     BRA MainLoop
;-----------------------------------------------------------------------------
; TimerService
;  timer1 ($FE, 10 ms): one FRAME, however many ticks elapsed:
;     FrameUpdate (voices), GlobalFX, master fade, global LFO counters
;       $29 += 1   $55 += 2   $54 += 1 every other frame
;       $53 += $52 (random walk; $52 flips sign when RNG low byte & $1F == 0)
;  timer0 ($FD, tempo-driven): sequencer.
;       $2D = ticks elapsed; clock $2B/$2C += ticks * multiplier($50)
;       (MUL result high byte is dropped: ticks*mult must stay < 256)
;       If paused ($5A != 0) the sequencer is skipped and song voices are
;       keyed off every tick instead.
;-----------------------------------------------------------------------------
TimerService:
        029C: E4 FE     MOV A,$FE
        029E: F0 2A     BEQ .seqTimer
        02A0: 3F 45 0A  CALL !FrameUpdate
        02A3: 3F 6C 0F  CALL !GlobalFX
        02A6: 3F 38 05  CALL !MasterFadeStep
        02A9: AB 29     INC $29
        02AB: AB 55     INC $55
        02AD: AB 55     INC $55
        02AF: E4 29     MOV A,$29
        02B1: 5C        LSR A
        02B2: 90 02     BCC .noLfo54
        02B4: AB 54     INC $54
  .noLfo54:
        02B6: E4 12     MOV A,$12
        02B8: 28 1F     AND A,#$1F
        02BA: D0 07     BNE .walk53
        02BC: E4 52     MOV A,$52
        02BE: 48 FF     EOR A,#$FF
        02C0: BC        INC A
        02C1: C4 52     MOV $52,A
  .walk53:
        02C3: E4 53     MOV A,$53
        02C5: 60        CLRC
        02C6: 84 52     ADC A,$52
        02C8: C4 53     MOV $53,A
  .seqTimer:
        02CA: E4 FD     MOV A,$FD
        02CC: F0 14     BEQ .ret
        02CE: C4 2D     MOV $2D,A
        02D0: EB 5A     MOV Y,$5A
        02D2: D0 0F     BNE .paused
        02D4: EB 50     MOV Y,$50
        02D6: CF        MUL YA                 ; YA = ticks * $50
        02D7: 60        CLRC
        02D8: 84 2B     ADC A,$2B              ; clock += A only (Y lost)
        02DA: C4 2B     MOV $2B,A
        02DC: 98 00 2C  ADC $2C,#$00
        02DF: 3F 75 06  CALL !SeqTick          ; run tracks
  .ret:
        02E2: 6F        RET
  .paused:
        02E3: 5F DC 05  JMP !KeyOffSongVoices  ; paused: KOF song voices each tick
;-----------------------------------------------------------------------------
; CPU command jump table ($00-$1A). Index = port0 value. Args: $01=port1,
; $02=port2, $03=port3 (latched when the command byte changes).
;-----------------------------------------------------------------------------
:
        02E6: dw $04AA    ; 00 -> NullHandler
        02E8: dw $04EB    ; 01 -> Cmd01_UploadSample
        02EA: dw $051E    ; 02 -> Cmd02_UploadPitchEnv
        02EC: dw $04AB    ; 03 -> Cmd03_UploadRegions
        02EE: dw $04E5    ; 04 -> Cmd04_UploadSong
        02F0: dw $0487    ; 05 -> Cmd05_ResetToIPL
        02F2: dw $04A4    ; 06 -> Cmd06_MarkPtr
        02F4: dw $0493    ; 07 -> Cmd07_RestorePtr
        02F6: dw $0342    ; 08 -> Cmd08_MasterFade
        02F8: dw $03C5    ; 09 -> Cmd09_PlaySong
        02FA: dw $03C8    ; 0A -> Cmd0A_StopAll
        02FC: dw $03CB    ; 0B -> Cmd0B_Pause
        02FE: dw $0349    ; 0C -> Cmd0C_PlayNote
        0300: dw $0379    ; 0D -> Cmd0D_SelectSfxTrack
        0302: dw $0381    ; 0E -> Cmd0E_SfxPolyphony
        0304: dw $03BD    ; 0F -> Cmd0F_SfxPriority
        0306: dw $0389    ; 10 -> Cmd10_SfxGlide
        0308: dw $0391    ; 11 -> Cmd11_SfxVolume
        030A: dw $03A6    ; 12 -> Cmd12_SongVolume
        030C: dw $0425    ; 13 -> Cmd13_EchoSetup
        030E: dw $03B9    ; 14 -> Cmd14_Stereo
        0310: dw $0F09    ; 15 -> DSPReset
        0312: dw $037D    ; 16 -> Cmd16_ClockMult
        0314: dw $03FB    ; 17 -> Cmd17_MeasureLevels
        0316: dw $03F0    ; 18 -> Cmd18_ReadLevel
        0318: dw $03D7    ; 19 -> Cmd19_ActiveTracks
        031A: dw $03CF    ; 1A -> Cmd1A_FreeMemory
;-----------------------------------------------------------------------------
; PollCPU - a command is accepted when port0 differs from the last value
; ($00) and reads the same twice (4 NOP debounce). Ports 1-3 = arguments.
; After the handler returns, port0 is echoed back as the acknowledge.
; => the CPU must alternate/toggle something in port0 between commands;
;    sending the same command twice in a row needs a different byte in between.
;-----------------------------------------------------------------------------
PollCPU:
        031C: E4 F4     MOV A,$F4
        031E: 00        NOP
        031F: 00        NOP
        0320: 00        NOP
        0321: 00        NOP
        0322: 64 F4     CMP A,$F4
        0324: D0 F6     BNE PollCPU
        0326: 64 00     CMP A,$00
        0328: D0 01     BNE .newCmd
        032A: 6F        RET
  .newCmd:
        032B: C4 00     MOV $00,A
        032D: FA F5 01  MOV $01,$F5
        0330: FA F6 02  MOV $02,$F6
        0333: FA F7 03  MOV $03,$F7
        0336: 1C        ASL A
        0337: 5D        MOV X,A
        0338: 3F 3F 03  CALL !CmdDispatch
        033B: FA 00 F4  MOV $F4,$00            ; ack: echo the command
        033E: 6F        RET
CmdDispatch:
        033F: 1F E6 02  JMP [!$02E6+X]
; $08 MasterFade: arg1 = target volume, arg2 = speed (frames per step). Speed 0 = immediate.
Cmd08_MasterFade:
        0342: E4 01     MOV A,$01
        0344: EB 02     MOV Y,$02
        0346: 5F 2C 05  JMP !SetMasterFade
; $0C PlayNote (SFX/direct): track = $4F (default 15). arg1 = program,
;     arg2 = note, arg3 = velocity (0 = note off). Duration 0 = no auto-release.
Cmd0C_PlayNote:
        0349: F8 4F     MOV X,$4F
        034B: D8 20     MOV $20,X
        034D: E4 01     MOV A,$01
        034F: 3F 64 03  CALL !SetProgram
        0352: 8F 00 23  MOV $23,#$00
        0355: FA 02 21  MOV $21,$02
        0358: E4 03     MOV A,$03
        035A: C4 22     MOV $22,A
        035C: F0 03     BEQ .off
        035E: 5F D7 08  JMP !NoteOn
  .off:
        0361: 5F BB 08  JMP !NoteOff
; SetProgram  X=track A=program. Sets $1489 and, if the program's head region
; has non-zero defaults, polyphony ($1A79[p]) and priority ($1AF9[p]).
SetProgram:
        0364: D5 89 14  MOV !$1489+X,A
        0367: FD        MOV Y,A
        0368: F6 79 1A  MOV A,!$1A79+Y
        036B: F0 03     BEQ .noPoly
        036D: D5 D9 14  MOV !$14D9+X,A
  .noPoly:
        0370: F6 F9 1A  MOV A,!$1AF9+Y
        0373: F0 03     BEQ .ret
        0375: D5 E9 14  MOV !$14E9+X,A
  .ret:
        0378: 6F        RET
; $0D: SFX track number ($4F) for commands $0C/$0E/$0F/$10/$11
Cmd0D_SelectSfxTrack:
        0379: FA 01 4F  MOV $4F,$01
        037C: 6F        RET
; $16: clock multiplier $50 (sequencer units added per timer0 tick)
Cmd16_ClockMult:
        037D: FA 01 50  MOV $50,$01
        0380: 6F        RET
; $0E: SFX track polyphony
Cmd0E_SfxPolyphony:
        0381: F8 4F     MOV X,$4F
        0383: E4 01     MOV A,$01
        0385: D5 D9 14  MOV !$14D9+X,A
        0388: 6F        RET
; $10: SFX track glide/legato ($14A9)
Cmd10_SfxGlide:
        0389: F8 4F     MOV X,$4F
        038B: E4 01     MOV A,$01
        038D: D5 A9 14  MOV !$14A9+X,A
        0390: 6F        RET
; $11: SFX track volume; marks every voice volume-dirty
Cmd11_SfxVolume:
        0391: F8 4F     MOV X,$4F
        0393: E4 01     MOV A,$01
        0395: D5 C9 14  MOV !$14C9+X,A
        0398: CD 07     MOV X,#$07
  .dirty:
        039A: F5 79 1F  MOV A,!$1F79+X
        039D: 08 40     OR A,#$40
        039F: D5 79 1F  MOV !$1F79+X,A
        03A2: 1D        DEC X
        03A3: 10 F5     BPL .dirty
        03A5: 6F        RET
; $12: song volume - $18 (used by StartSong) and $14C9 of all active tracks
Cmd12_SongVolume:
        03A6: FA 01 18  MOV $18,$01
        03A9: CD 0F     MOV X,#$0F
  .trk:
        03AB: F5 59 14  MOV A,!$1459+X
        03AE: F0 05     BEQ .next
        03B0: E4 18     MOV A,$18
        03B2: D5 C9 14  MOV !$14C9+X,A
  .next:
        03B5: 1D        DEC X
        03B6: 10 F3     BPL .trk
        03B8: 6F        RET
; $14: stereo flag $51 (0 = mono: pan ignored)
Cmd14_Stereo:
        03B9: FA 01 51  MOV $51,$01
        03BC: 6F        RET
; $0F: SFX track priority
Cmd0F_SfxPriority:
        03BD: F8 4F     MOV X,$4F
        03BF: E4 01     MOV A,$01
        03C1: D5 E9 14  MOV !$14E9+X,A
        03C4: 6F        RET
; $09: start the song at $27/$28 (StartSong)
Cmd09_PlaySong:
        03C5: 5F 2B 06  JMP !StartSong
; $0A: stop all tracks and key off their voices
Cmd0A_StopAll:
        03C8: 5F CE 05  JMP !StopAll
; $0B: pause flag $5A (non-zero = sequencer frozen, song voices keyed off each tick). StartSong clears it.
Cmd0B_Pause:
        03CB: FA 01 5A  MOV $5A,$01
        03CE: 6F        RET
; $1A: return free memory = $FFFF - upload pointer in ports 2/3
Cmd1A_FreeMemory:
        03CF: E8 00     MOV A,#$00
        03D1: 8D FF     MOV Y,#$FF
        03D3: 9A 14     SUBW YA,$14
        03D5: 2F 16     BRA ReturnWord
; $19: return 16-bit active-track mask in ports 2/3 (bit n = track n)
Cmd19_ActiveTracks:
        03D7: CD 0F     MOV X,#$0F
        03D9: 8F 00 04  MOV $04,#$00
        03DC: 8F 00 05  MOV $05,#$00
  .bit:
        03DF: F5 59 14  MOV A,!$1459+X
        03E2: 68 01     CMP A,#$01
        03E4: 2B 04     ROL $04
        03E6: 2B 05     ROL $05
        03E8: 1D        DEC X
        03E9: 10 F4     BPL .bit
        03EB: BA 04     MOVW YA,$04
ReturnWord:
        03ED: DA F6     MOVW $F6,YA
        03EF: 6F        RET
; $18: return word $2F+2*arg1 in ports 2/3 (reads the level buffer built by $17)
Cmd18_ReadLevel:
        03F0: E4 01     MOV A,$01
        03F2: 1C        ASL A
        03F3: 5D        MOV X,A
        03F4: F4 30     MOV A,$30+X
        03F6: FD        MOV Y,A
        03F7: F4 2F     MOV A,$2F+X
        03F9: 2F F2     BRA ReturnWord
; $17: level meter - for each voice, ENVX*2 is stored at $2F+voice and added
;      (saturating) into $37+track. Read back with $18.
;      (The voice/track areas overlap: $37+track covers $37-$46.)
Cmd17_MeasureLevels:
        03FB: E8 00     MOV A,#$00
        03FD: CD 0F     MOV X,#$0F
  .clr:
        03FF: D4 37     MOV $37+X,A
        0401: 1D        DEC X
        0402: 10 FB     BPL .clr
        0404: CD 07     MOV X,#$07
  .voice:
        0406: F5 11 1F  MOV A,!$1F11+X
        0409: FD        MOV Y,A
        040A: 7D        MOV A,X
        040B: 9F        XCN A
        040C: 08 08     OR A,#$08
        040E: C4 F2     MOV $F2,A
        0410: E4 F3     MOV A,$F3
        0412: 1C        ASL A
        0413: D4 2F     MOV $2F+X,A
        0415: 5C        LSR A
        0416: 60        CLRC
        0417: 96 37 00  ADC A,!$0037+Y
        041A: 90 02     BCC .store
        041C: E8 FF     MOV A,#$FF
  .store:
        041E: D6 37 00  MOV !$0037+Y,A
        0421: 1D        DEC X
        0422: 10 E2     BPL .voice
        0424: 6F        RET
; $13 EchoSetup: arg1 = EDL (0 = echo writes off), arg2 = EFB, arg3 = EVOL (L=R).
;      ESA = ~(EDL*8) (buffer at the very top of RAM), FIR = FF 08 17 24 24 17 08 FF.
;      NOTE: EON is never written anywhere in the driver (DSPReset sets it to 0),
;      so no voice is ever sent to the echo - the effect is inaudible.
Cmd13_EchoSetup:
        0425: 8F 6C F2  MOV $F2,#$6C
        0428: 8F 20 F3  MOV $F3,#$20
        042B: E4 01     MOV A,$01
        042D: F0 57     BEQ .ret
        042F: 8F 7D F2  MOV $F2,#$7D
        0432: C4 F3     MOV $F3,A
        0434: 1C        ASL A
        0435: 1C        ASL A
        0436: 1C        ASL A
        0437: 48 FF     EOR A,#$FF
        0439: 8F 6D F2  MOV $F2,#$6D
        043C: C4 F3     MOV $F3,A
        043E: 8F 0D F2  MOV $F2,#$0D
        0441: FA 02 F3  MOV $F3,$02
        0444: 8F 2C F2  MOV $F2,#$2C
        0447: FA 03 F3  MOV $F3,$03
        044A: 8F 3C F2  MOV $F2,#$3C
        044D: FA 03 F3  MOV $F3,$03
        0450: 8F C0 F2  MOV $F2,#$C0
        0453: 8F FF F3  MOV $F3,#$FF
        0456: 8F C1 F2  MOV $F2,#$C1
        0459: 8F 08 F3  MOV $F3,#$08
        045C: 8F C2 F2  MOV $F2,#$C2
        045F: 8F 17 F3  MOV $F3,#$17
        0462: 8F C3 F2  MOV $F2,#$C3
        0465: 8F 24 F3  MOV $F3,#$24
        0468: 8F C4 F2  MOV $F2,#$C4
        046B: 8F 24 F3  MOV $F3,#$24
        046E: 8F C5 F2  MOV $F2,#$C5
        0471: 8F 17 F3  MOV $F3,#$17
        0474: 8F C6 F2  MOV $F2,#$C6
        0477: 8F 08 F3  MOV $F3,#$08
        047A: 8F C7 F2  MOV $F2,#$C7
        047D: 8F FF F3  MOV $F3,#$FF
        0480: 8F 6C F2  MOV $F2,#$6C
        0483: 8F 00 F3  MOV $F3,#$00
  .ret:
        0486: 6F        RET
; $05: hand control back to the IPL ROM (re-enable ROM, FLG=$FF, jump $FFC0) for a new driver/bulk upload
Cmd05_ResetToIPL:
        0487: 8F 80 F1  MOV $F1,#$80
        048A: 8F 6C F2  MOV $F2,#$6C
        048D: 8F FF F3  MOV $F3,#$FF
        0490: 5F C0 FF  JMP !$FFC0
; $07: arg1 != 0 -> upload pointer = mark; arg1 == 0 -> pointer = mark = $2179 (free everything)
Cmd07_RestorePtr:
        0493: E4 01     MOV A,$01
        0495: F0 07     BEQ ResetUploadPtr
        0497: FA 16 14  MOV $14,$16
        049A: FA 17 15  MOV $15,$17
        049D: 6F        RET
ResetUploadPtr:
        049E: 8F 79 14  MOV $14,#$79
        04A1: 8F 21 15  MOV $15,#$21
; $06: mark = current upload pointer (so the next song can overwrite the old one)
Cmd06_MarkPtr:
        04A4: FA 14 16  MOV $16,$14
        04A7: FA 15 17  MOV $17,$15
; $00 (and unused table slots): no-op
NullHandler:
        04AA: 6F        RET
; $03 UploadRegions: arg1 = first region index, arg2 = number of byte PAIRS.
;   Each received byte goes to $15F9 + index + k*$80 (k = 0,1,2...) - i.e. one
;   region record is written as a COLUMN through the 18 region tables.
;   Uses its own 2-byte handshake (ports 2,3 = data; port0 = new token).
Cmd03_UploadRegions:
        04AB: EB 01     MOV Y,$01
        04AD: 8F F9 25  MOV $25,#$F9
        04B0: 8F 15 26  MOV $26,#$15
        04B3: F8 02     MOV X,$02
        04B5: FA 00 F4  MOV $F4,$00
  .wait:
        04B8: E4 F4     MOV A,$F4
        04BA: 00        NOP
        04BB: 00        NOP
        04BC: 00        NOP
        04BD: 00        NOP
        04BE: 64 F4     CMP A,$F4
        04C0: D0 F6     BNE .wait
        04C2: 64 00     CMP A,$00
        04C4: F0 F2     BEQ .wait
        04C6: C4 00     MOV $00,A
        04C8: E4 F6     MOV A,$F6
        04CA: D7 25     MOV [$25]+Y,A
        04CC: 60        CLRC
        04CD: 98 80 25  ADC $25,#$80
        04D0: 98 00 26  ADC $26,#$00
        04D3: E4 F7     MOV A,$F7
        04D5: FA 00 F4  MOV $F4,$00
        04D8: D7 25     MOV [$25]+Y,A
        04DA: 60        CLRC
        04DB: 98 80 25  ADC $25,#$80
        04DE: 98 00 26  ADC $26,#$00
        04E1: 1D        DEC X
        04E2: D0 D4     BNE .wait
        04E4: 6F        RET
; $04 UploadSong: song base $27/$28 = upload pointer, then receive arg2/arg3 words
Cmd04_UploadSong:
        04E5: BA 14     MOVW YA,$14
        04E7: DA 27     MOVW $27,YA
        04E9: 2F 0C     BRA RecvWords
; $01 UploadSample: sample[arg1] = upload pointer, then receive (header + BRR)
Cmd01_UploadSample:
        04EB: F8 01     MOV X,$01
        04ED: E4 14     MOV A,$14
        04EF: D5 F9 14  MOV !$14F9+X,A
        04F2: E4 15     MOV A,$15
        04F4: D5 79 15  MOV !$1579+X,A
; RecvWords: count = $02/$03 words. Per word: wait for port0 to change,
; take ports 2/3, echo port0. Data goes to [$14]++ (the upload pointer).
RecvWords:
        04F7: FA 00 F4  MOV $F4,$00
  .wait:
        04FA: F8 F4     MOV X,$F4
        04FC: 00        NOP
        04FD: 00        NOP
        04FE: 00        NOP
        04FF: 00        NOP
        0500: 3E F4     CMP X,$F4
        0502: D0 F6     BNE .wait
        0504: 3E 00     CMP X,$00
        0506: F0 F2     BEQ .wait
        0508: BA F6     MOVW YA,$F6
        050A: D8 F4     MOV $F4,X
        050C: D8 00     MOV $00,X
        050E: CD 00     MOV X,#$00
        0510: C7 14     MOV [$14+X],A
        0512: 3A 14     INCW $14
        0514: DD        MOV A,Y
        0515: C7 14     MOV [$14+X],A
        0517: 3A 14     INCW $14
        0519: 1A 02     DECW $02
        051B: D0 DD     BNE .wait
        051D: 6F        RET
; $02 UploadPitchEnv: pitch-envelope table[arg1] (0-63) = upload pointer, then receive
Cmd02_UploadPitchEnv:
        051E: F8 01     MOV X,$01
        0520: E4 14     MOV A,$14
        0522: D5 D9 1F  MOV !$1FD9+X,A
        0525: E4 15     MOV A,$15
        0527: D5 19 20  MOV !$2019+X,A
        052A: 2F CB     BRA RecvWords
; SetMasterFade A=target Y=speed. Speed 0 writes MVOL at once.
; MasterFadeStep (every frame): the counter $1C is decremented 4 times per
; frame and $19 steps one unit toward $1A each time it expires
; -> 4/speed units per frame.
SetMasterFade:
        052C: C4 1A     MOV $1A,A
        052E: CB 1B     MOV $1B,Y
        0530: 8F 01 1C  MOV $1C,#$01
        0533: AD 00     CMP Y,#$00
        0535: F0 1D     BEQ WriteMVOL
        0537: 6F        RET
MasterFadeStep:
        0538: E4 19     MOV A,$19
        053A: 2E 1A 01  CBNE $1A,.go
        053D: 6F        RET
  .go:
        053E: 8D 04     MOV Y,#$04
        0540: E4 19     MOV A,$19
  .step:
        0542: 6E 1C 0D  DBNZ $1C,.next
        0545: FA 1B 1C  MOV $1C,$1B
        0548: 64 1A     CMP A,$1A
        054A: F0 06     BEQ .next
        054C: 90 03     BCC .up
        054E: 9C        DEC A
        054F: 2F 01     BRA .next
  .up:
        0551: BC        INC A
  .next:
        0552: FE EE     DBNZ Y,.step
WriteMVOL:
        0554: C4 19     MOV $19,A
        0556: 8F 0C F2  MOV $F2,#$0C
        0559: C4 F3     MOV $F3,A
        055B: 8F 1C F2  MOV $F2,#$1C
        055E: C4 F3     MOV $F3,A
        0560: 6F        RET
; SMul8: signed 8x8 multiply, $10/$11 = $0C * $0E (sign-extended through $0D/$0F)
SMul8:
        0561: 8F 00 0D  MOV $0D,#$00
        0564: E4 0C     MOV A,$0C
        0566: 10 02     BPL .y
        0568: 8B 0D     DEC $0D
  .y:
        056A: 8F 00 0F  MOV $0F,#$00
        056D: EB 0E     MOV Y,$0E
        056F: 10 02     BPL .mul
        0571: 8B 0F     DEC $0F
  .mul:
        0573: CF        MUL YA
        0574: DA 10     MOVW $10,YA
        0576: E4 0D     MOV A,$0D
        0578: EB 0E     MOV Y,$0E
        057A: CF        MUL YA
        057B: 60        CLRC
        057C: 84 11     ADC A,$11
        057E: C4 11     MOV $11,A
        0580: E4 0C     MOV A,$0C
        0582: EB 0F     MOV Y,$0F
        0584: CF        MUL YA
        0585: 60        CLRC
        0586: 84 11     ADC A,$11
        0588: C4 11     MOV $11,A
        058A: 6F        RET
; unreferenced code (an unsigned multiply variant + a call to Random/DIV) - never reached
DeadCode:
        058B: db $E4, $0C, $EB, $0E, $CF, $DA, $10, $E4, $0D, $EB, $0E, $CF, $60, $84, $11, $C4
        059B: db $11, $E4, $0C, $EB, $0F, $CF, $60, $84, $11, $C4, $11, $6F, $3F, $AF, $05, $8D
        05AB: db $00, $9E, $DD, $6F
; Random: 16-bit Galois LFSR at $12/$13 shifted left, XOR $ABCD when the bit shifted out is 0, then the two bytes are swapped. Returns A = new $12.
Random:
        05AF: 0B 12     ASL $12
        05B1: 2B 13     ROL $13
        05B3: B0 06     BCS .swap
        05B5: 58 CD 12  EOR $12,#$CD
        05B8: 58 AB 13  EOR $13,#$AB
  .swap:
        05BB: E4 13     MOV A,$13
        05BD: FA 12 13  MOV $13,$12
        05C0: C4 12     MOV $12,A
        05C2: 6F        RET
; InitTracks: all 16 tracks to defaults with volume $60, then StopAll
InitTracks:
        05C3: 8F 60 18  MOV $18,#$60
        05C6: CD 0F     MOV X,#$0F
  .trk:
        05C8: 3F 0C 06  CALL !ResetTrackDefaults
        05CB: 1D        DEC X
        05CC: 10 FA     BPL .trk
; StopAll: key off every voice owned by an active track, then mark all tracks inactive
StopAll:
        05CE: 3F DC 05  CALL !KeyOffSongVoices
        05D1: CD 0F     MOV X,#$0F
        05D3: E8 00     MOV A,#$00
  .clr:
        05D5: D5 59 14  MOV !$1459+X,A
        05D8: 1D        DEC X
        05D9: 10 FA     BPL .clr
        05DB: 6F        RET
; KeyOffSongVoices: KOF (and free) every voice belonging to an active track
KeyOffSongVoices:
        05DC: 8F 00 04  MOV $04,#$00
        05DF: CD 0F     MOV X,#$0F
  .trk:
        05E1: F5 59 14  MOV A,!$1459+X
        05E4: F0 03     BEQ .next
        05E6: 3F F4 05  CALL !CollectTrackVoices
  .next:
        05E9: 1D        DEC X
        05EA: 10 F5     BPL .trk
        05EC: 8F 5C F2  MOV $F2,#$5C
        05EF: E4 04     MOV A,$04
        05F1: C4 F3     MOV $F3,A
        05F3: 6F        RET
CollectTrackVoices:
        05F4: 8D 07     MOV Y,#$07
  .voice:
        05F6: 7D        MOV A,X
        05F7: 76 11 1F  CMP A,!$1F11+Y
        05FA: D0 0C     BNE .next
        05FC: E8 00     MOV A,#$00
        05FE: D6 39 1F  MOV !$1F39+Y,A
        0601: F6 B5 11  MOV A,!$11B5+Y
        0604: 04 04     OR A,$04
        0606: C4 04     MOV $04,A
  .next:
        0608: DC        DEC Y
        0609: 10 EB     BPL .voice
        060B: 6F        RET
; ResetTrackDefaults X=track: glide 0, polyphony 0, program 1 (via SetProgram),
; pitch-env enable $7F, volume $18, priority $40, pan $40
ResetTrackDefaults:
        060C: E8 00     MOV A,#$00
        060E: D5 A9 14  MOV !$14A9+X,A
        0611: D5 D9 14  MOV !$14D9+X,A
        0614: BC        INC A
        0615: 3F 64 03  CALL !SetProgram
        0618: E8 7F     MOV A,#$7F
        061A: D5 99 14  MOV !$1499+X,A
        061D: E4 18     MOV A,$18
        061F: D5 C9 14  MOV !$14C9+X,A
        0622: E8 40     MOV A,#$40
        0624: D5 E9 14  MOV !$14E9+X,A
        0627: D5 B9 14  MOV !$14B9+X,A
        062A: 6F        RET
;=============================================================================
; StartSong - song header at $27/$28 = 16 words, offset of each track's data
; relative to the song base (0 = track unused). Track data starts with ONE
; initial-delay byte; the first event time = clock + delay. The clock is NOT
; reset, so all times are relative to the free-running clock $2B/$2C.
;=============================================================================
StartSong:
        062B: 8F 00 5A  MOV $5A,#$00
        062E: CD 0F     MOV X,#$0F
  .trk:
        0630: 7D        MOV A,X
        0631: 1C        ASL A
        0632: FD        MOV Y,A
        0633: F7 27     MOV A,[$27]+Y
        0635: C4 04     MOV $04,A
        0637: 60        CLRC
        0638: 84 27     ADC A,$27
        063A: C4 25     MOV $25,A
        063C: FC        INC Y
        063D: F7 27     MOV A,[$27]+Y
        063F: C4 05     MOV $05,A
        0641: 84 28     ADC A,$28
        0643: C4 26     MOV $26,A
        0645: E4 04     MOV A,$04
        0647: 04 05     OR A,$05
        0649: D5 59 14  MOV !$1459+X,A         ; $1459 = active (non-zero offset)
        064C: F0 23     BEQ .next
        064E: 3F 0C 06  CALL !ResetTrackDefaults
        0651: 8D 00     MOV Y,#$00
        0653: F7 25     MOV A,[$25]+Y
        0655: 3A 25     INCW $25
        0657: 60        CLRC
        0658: 84 2B     ADC A,$2B              ; event time = clock + delay byte
        065A: D5 39 14  MOV !$1439+X,A
        065D: DD        MOV A,Y
        065E: 84 2C     ADC A,$2C
        0660: D5 49 14  MOV !$1449+X,A
        0663: DD        MOV A,Y
        0664: D5 29 14  MOV !$1429+X,A         ; $1429 = 0: no loop point yet
        0667: E4 25     MOV A,$25
        0669: D5 F9 13  MOV !$13F9+X,A
        066C: E4 26     MOV A,$26
        066E: D5 09 14  MOV !$1409+X,A
  .next:
        0671: 1D        DEC X
        0672: 10 BC     BPL .trk
        0674: 6F        RET
;=============================================================================
; SeqTick - once per timer0 pass.
; 1) Gate countdowns: each voice with a duration ($1F81) loses $2D ticks;
;    at <= 0 the voice is released (ReleaseVoice).
; 2) Every active track: process all events whose time <= clock.
;=============================================================================
SeqTick:
        0675: 8F 07 1E  MOV $1E,#$07
  .gate:
        0678: F8 1E     MOV X,$1E
        067A: F5 39 1F  MOV A,!$1F39+X
        067D: F0 12     BEQ .nextV
        067F: F5 81 1F  MOV A,!$1F81+X
        0682: F0 0D     BEQ .nextV
        0684: 80        SETC
        0685: A4 2D     SBC A,$2D
        0687: D5 81 1F  MOV !$1F81+X,A
        068A: 90 02     BCC .release
        068C: D0 03     BNE .nextV
  .release:
        068E: 3F CF 0E  CALL !ReleaseVoice
  .nextV:
        0691: 8B 1E     DEC $1E
        0693: 10 E3     BPL .gate
        0695: CD 0F     MOV X,#$0F
  .trk:
        0697: F5 59 14  MOV A,!$1459+X
        069A: F0 07     BEQ .nextT
        069C: D8 20     MOV $20,X
        069E: 3F 08 07  CALL !TrackService
        06A1: F8 20     MOV X,$20
  .nextT:
        06A3: 1D        DEC X
        06A4: 10 F1     BPL .trk
        06A6: 6F        RET
;-----------------------------------------------------------------------------
; EVENT FORMAT - every event is 4 bytes:  [b0] [b1] [b2] [delta]
;   b0 = $01-$7F : NOTE  b1 = velocity (0 = note off), b2 = duration in ticks
;                  (0 = hold until a note-off), delta = ticks to next event
;   b0 = $00     : WAIT  event time hi += b1  (long rest: b1*256 + delta)
;   b0 = $80-$FF : CONTROL b1 = value (b2 ignored), see Ev_Control
; Time is 16-bit and compared signed against the clock, so it wraps safely.
;-----------------------------------------------------------------------------
ReadEvent:
        06A7: F5 F9 13  MOV A,!$13F9+X
        06AA: C4 25     MOV $25,A
        06AC: F5 09 14  MOV A,!$1409+X
        06AF: C4 26     MOV $26,A
        06B1: 8D 00     MOV Y,#$00
        06B3: F7 25     MOV A,[$25]+Y
        06B5: 3A 25     INCW $25
        06B7: 68 00     CMP A,#$00
        06B9: 30 59     BMI Ev_Control
        06BB: F0 1C     BEQ Ev_Wait
        06BD: C4 21     MOV $21,A              ; $21 = note
        06BF: F7 25     MOV A,[$25]+Y
        06C1: 3A 25     INCW $25
        06C3: C4 22     MOV $22,A              ; $22 = velocity
        06C5: F7 25     MOV A,[$25]+Y
        06C7: 3A 25     INCW $25
        06C9: C4 23     MOV $23,A              ; $23 = duration
        06CB: E4 22     MOV A,$22
        06CD: F0 05     BEQ .noteOff
        06CF: 3F D7 08  CALL !NoteOn
        06D2: 2F 12     BRA Ev_Delta
  .noteOff:
        06D4: 3F BB 08  CALL !NoteOff
        06D7: 2F 0D     BRA Ev_Delta
Ev_Wait:
        06D9: F7 25     MOV A,[$25]+Y          ; b1 -> time high byte
        06DB: 60        CLRC
        06DC: 95 49 14  ADC A,!$1449+X
        06DF: D5 49 14  MOV !$1449+X,A
Ev_SkipArgs:
        06E2: 3A 25     INCW $25
        06E4: 3A 25     INCW $25
Ev_Delta:
        06E6: F8 20     MOV X,$20
        06E8: 8D 00     MOV Y,#$00
        06EA: F7 25     MOV A,[$25]+Y          ; delta -> time low byte (+carry)
        06EC: 60        CLRC
        06ED: 95 39 14  ADC A,!$1439+X
        06F0: D5 39 14  MOV !$1439+X,A
        06F3: 90 07     BCC .savePtr
        06F5: F5 49 14  MOV A,!$1449+X
        06F8: BC        INC A
        06F9: D5 49 14  MOV !$1449+X,A
  .savePtr:
        06FC: 3A 25     INCW $25
        06FE: E4 25     MOV A,$25
        0700: D5 F9 13  MOV !$13F9+X,A
        0703: E4 26     MOV A,$26
        0705: D5 09 14  MOV !$1409+X,A
TrackService:
        0708: F5 49 14  MOV A,!$1449+X
        070B: FD        MOV Y,A
        070C: F5 39 14  MOV A,!$1439+X
        070F: 5A 2B     CMPW YA,$2B            ; event time - clock
        0711: 30 94     BMI ReadEvent          ; negative = due: read the next event
        0713: 6F        RET
; Ev_Control - b0 values:
;   $80 LoopEnd   jump to the LoopStart point if one was set, else track ends.
;                 A taken LoopEnd never reads its own delta (the LoopStart's
;                 delta is re-applied). Only one loop level per track.
;   $82 LoopStart remember this position
;   $83 Volume    $14C9   $84 Tempo  timer0 = 10000/b1 (BPM; 48 ticks/beat)
;   $85 Program   $86 Polyphony $14D9   $87 Glide $14A9   $88 Priority $14E9
;   $89 Pan $14B9 $8A PitchEnvEnable $1499 (0 = pitch envelopes off)
;   $81, $8B-$FF  ignored
Ev_Control:
        0714: 68 83     CMP A,#$83
        0716: F0 4C     BEQ Ev_Volume
        0718: 68 84     CMP A,#$84
        071A: F0 78     BEQ Ev_Tempo
        071C: 68 85     CMP A,#$85
        071E: F0 3C     BEQ Ev_Program
        0720: 68 86     CMP A,#$86
        0722: F0 58     BEQ Ev_Polyphony
        0724: 68 87     CMP A,#$87
        0726: F0 5C     BEQ Ev_Glide
        0728: 68 88     CMP A,#$88
        072A: F0 60     BEQ Ev_Priority
        072C: 68 89     CMP A,#$89
        072E: F0 3C     BEQ Ev_Pan
        0730: 68 82     CMP A,#$82
        0732: F0 1C     BEQ Ev_LoopStart
        0734: 68 8A     CMP A,#$8A
        0736: F0 3C     BEQ Ev_PitchEnvEnable
        0738: 68 80     CMP A,#$80
        073A: D0 A6     BNE Ev_SkipArgs
Ev_LoopEnd:
        073C: F5 29 14  MOV A,!$1429+X
        073F: F0 09     BEQ TrackEnd
        0741: C4 26     MOV $26,A
        0743: F5 19 14  MOV A,!$1419+X
        0746: C4 25     MOV $25,A
        0748: 2F 98     BRA Ev_SkipArgs
TrackEnd:
        074A: E8 00     MOV A,#$00
        074C: D5 59 14  MOV !$1459+X,A
        074F: 6F        RET
Ev_LoopStart:
        0750: E4 26     MOV A,$26
        0752: D5 29 14  MOV !$1429+X,A
        0755: E4 25     MOV A,$25
        0757: D5 19 14  MOV !$1419+X,A
        075A: 2F 86     BRA Ev_SkipArgs
Ev_Program:
        075C: F7 25     MOV A,[$25]+Y
        075E: 3F 64 03  CALL !SetProgram
        0761: 5F E2 06  JMP !Ev_SkipArgs
Ev_Volume:
        0764: F7 25     MOV A,[$25]+Y
        0766: D5 C9 14  MOV !$14C9+X,A
        0769: 5F E2 06  JMP !Ev_SkipArgs
Ev_Pan:
        076C: F7 25     MOV A,[$25]+Y
        076E: D5 B9 14  MOV !$14B9+X,A
        0771: 5F E2 06  JMP !Ev_SkipArgs
Ev_PitchEnvEnable:
        0774: F7 25     MOV A,[$25]+Y
        0776: D5 99 14  MOV !$1499+X,A
        0779: 5F E2 06  JMP !Ev_SkipArgs
Ev_Polyphony:
        077C: F7 25     MOV A,[$25]+Y
        077E: D5 D9 14  MOV !$14D9+X,A
        0781: 5F E2 06  JMP !Ev_SkipArgs
Ev_Glide:
        0784: F7 25     MOV A,[$25]+Y
        0786: D5 A9 14  MOV !$14A9+X,A
        0789: 5F E2 06  JMP !Ev_SkipArgs
Ev_Priority:
        078C: F7 25     MOV A,[$25]+Y
        078E: D5 E9 14  MOV !$14E9+X,A
        0791: 5F E2 06  JMP !Ev_SkipArgs
; Ev_Tempo: timer0 target = 10000 / BPM (units of 125 us) -> 1 tick = 1.25 s / BPM,
; i.e. 48 ticks per quarter note. BPM < 40 overflows the 8-bit target.
Ev_Tempo:
        0794: F7 25     MOV A,[$25]+Y
        0796: 4D        PUSH X
        0797: 6D        PUSH Y
        0798: 5D        MOV X,A
        0799: 8D 27     MOV Y,#$27
        079B: E8 10     MOV A,#$10
        079D: 9E        DIV YA,X
        079E: 8F 02 F1  MOV $F1,#$02
        07A1: C4 FA     MOV $FA,A
        07A3: 8F 03 F1  MOV $F1,#$03
        07A6: EE        POP Y
        07A7: CE        POP X
        07A8: 5F E2 06  JMP !Ev_SkipArgs
;=============================================================================
; NoiseWaveUpdate (every main-loop pass) - rewrites random bytes into the 8
; BRR blocks at $11E1-$1228 (synth waves 16-23 point straight at them) and
; randomises the header of block $120E (wave 22): range 8-15, filter 1,
; end+loop set. This is the driver's own "noise" - the DSP noise
; generator (NON) is never used.
;=============================================================================
NoiseWaveUpdate:
        07AB: 3F AF 05  CALL !Random
        07AE: 28 70     AND A,#$70
        07B0: 08 87     OR A,#$87
        07B2: C5 0E 12  MOV !$120E,A
        07B5: AB 24     INC $24
        07B7: E4 24     MOV A,$24
        07B9: 28 03     AND A,#$03
        07BB: 5D        MOV X,A
        07BC: 3F AF 05  CALL !Random
        07BF: D5 E2 11  MOV !$11E2+X,A
        07C2: D5 F4 11  MOV !$11F4+X,A
        07C5: D5 06 12  MOV !$1206+X,A
        07C8: D5 0F 12  MOV !$120F+X,A
        07CB: D5 18 12  MOV !$1218+X,A
        07CE: D5 21 12  MOV !$1221+X,A
        07D1: 48 FF     EOR A,#$FF
        07D3: D5 0A 12  MOV !$120A+X,A
        07D6: 9F        XCN A
        07D7: 44 13     EOR A,$13
        07D9: D5 E6 11  MOV !$11E6+X,A
        07DC: D5 F8 11  MOV !$11F8+X,A
        07DF: D5 13 12  MOV !$1213+X,A
        07E2: D5 1C 12  MOV !$121C+X,A
        07E5: D5 25 12  MOV !$1225+X,A
        07E8: 3F AF 05  CALL !Random
        07EB: D5 EB 11  MOV !$11EB+X,A
        07EE: D5 FD 11  MOV !$11FD+X,A
        07F1: 9F        XCN A
        07F2: 44 13     EOR A,$13
        07F4: D5 EF 11  MOV !$11EF+X,A
        07F7: D5 01 12  MOV !$1201+X,A
        07FA: 6F        RET
; Mod_PWM (per frame, synth wave 24): pulse position $1FC1 += step $1FC9,
; bouncing when it passes the limit $1FD1; then WritePulseEdge moves one
; edge of the square wave in the voice's own 4-block buffer.
Mod_PWM:
        07FB: F6 AD 11  MOV A,!$11AD+Y
        07FE: C4 04     MOV $04,A
        0800: F6 A5 11  MOV A,!$11A5+Y
        0803: C4 05     MOV $05,A
        0805: F6 C1 1F  MOV A,!$1FC1+Y
        0808: 60        CLRC
        0809: 96 C9 1F  ADC A,!$1FC9+Y
        080C: 76 D1 1F  CMP A,!$1FD1+Y
        080F: 90 0B     BCC .store
        0811: F6 C9 1F  MOV A,!$1FC9+Y
        0814: 48 FF     EOR A,#$FF
        0816: BC        INC A
        0817: D6 C9 1F  MOV !$1FC9+Y,A
        081A: 2F 03     BRA .write
  .store:
        081C: D6 C1 1F  MOV !$1FC1+Y,A
  .write:
        081F: F6 C1 1F  MOV A,!$1FC1+Y
; WritePulseEdge A = position (bit7 selects block 1 or 2 of the buffer at $04/$05).
; Position bits 4-6 = byte inside the block, bits 0-3 = sub-sample edge byte from
; PulseEdgeTable. Bytes before the edge become $77, after it $88, so only the
; two neighbours are touched: the position must change slowly (< 16 per frame).
WritePulseEdge:
        0822: 1C        ASL A
        0823: B0 27     BCS .block2
        0825: 5C        LSR A
        0826: C4 06     MOV $06,A
        0828: 9F        XCN A
        0829: 28 07     AND A,#$07
        082B: BC        INC A
        082C: FD        MOV Y,A
        082D: E4 06     MOV A,$06
        082F: 28 0F     AND A,#$0F
        0831: 5D        MOV X,A
        0832: F5 75 08  MOV A,!$0875+X
        0835: D7 04     MOV [$04]+Y,A
        0837: AD 01     CMP Y,#$01
        0839: F0 06     BEQ .chk
        083B: DC        DEC Y
        083C: E8 77     MOV A,#$77
        083E: D7 04     MOV [$04]+Y,A
        0840: FC        INC Y
  .chk:
        0841: AD 08     CMP Y,#$08
        0843: D0 01     BNE .after
        0845: FC        INC Y
  .after:
        0846: FC        INC Y
        0847: E8 88     MOV A,#$88
        0849: D7 04     MOV [$04]+Y,A
        084B: 6F        RET
  .block2:
        084C: 5C        LSR A
        084D: C4 06     MOV $06,A
        084F: 9F        XCN A
        0850: 28 07     AND A,#$07
        0852: 60        CLRC
        0853: 88 0A     ADC A,#$0A
        0855: FD        MOV Y,A
        0856: E4 06     MOV A,$06
        0858: 28 0F     AND A,#$0F
        085A: 5D        MOV X,A
        085B: F5 75 08  MOV A,!$0875+X
        085E: D7 04     MOV [$04]+Y,A
        0860: AD 11     CMP Y,#$11
        0862: F0 06     BEQ .chk2
        0864: FC        INC Y
        0865: E8 88     MOV A,#$88
        0867: D7 04     MOV [$04]+Y,A
        0869: DC        DEC Y
  .chk2:
        086A: AD 0A     CMP Y,#$0A
        086C: D0 01     BNE .before2
        086E: DC        DEC Y
  .before2:
        086F: DC        DEC Y
        0870: E8 77     MOV A,#$77
        0872: D7 04     MOV [$04]+Y,A
        0874: 6F        RET
PulseEdgeTable:
        0875: db $88, $A8, $C8, $E8, $08, $28, $48, $68, $78, $7A, $7C, $7E, $70, $72, $74, $76
; Mod_Noise (per frame, synth waves 26/27): walk through the 32 data bytes of the
; voice buffer; byte = (Random & mask $1FC9) XOR ($88 for the first 12, $77 after)
; -> a square wave with a controllable amount of noise (mask from NoiseMaskTable[syn1&7]).
Mod_Noise:
        0885: F6 AD 11  MOV A,!$11AD+Y
        0888: C4 04     MOV $04,A
        088A: F6 A5 11  MOV A,!$11A5+Y
        088D: C4 05     MOV $05,A
        088F: F6 C1 1F  MOV A,!$1FC1+Y
        0892: BC        INC A
        0893: D6 C1 1F  MOV !$1FC1+Y,A
        0896: 28 1F     AND A,#$1F
        0898: 8F 77 06  MOV $06,#$77
        089B: 68 0C     CMP A,#$0C
        089D: B0 03     BCS .idx
        089F: 8F 88 06  MOV $06,#$88
  .idx:
        08A2: 68 18     CMP A,#$18
        08A4: 88 00     ADC A,#$00
        08A6: 68 10     CMP A,#$10
        08A8: 88 00     ADC A,#$00
        08AA: 68 08     CMP A,#$08
        08AC: 88 01     ADC A,#$01
        08AE: 2D        PUSH A
        08AF: 3F AF 05  CALL !Random
        08B2: 36 C9 1F  AND A,!$1FC9+Y
        08B5: 44 06     EOR A,$06
        08B7: EE        POP Y
        08B8: D7 04     MOV [$04]+Y,A
        08BA: 6F        RET
;=============================================================================
; NoteOff - release every voice of this track ($20) playing note $21.
;=============================================================================
NoteOff:
        08BB: 8F 07 1E  MOV $1E,#$07
  .voice:
        08BE: EB 1E     MOV Y,$1E
        08C0: F8 20     MOV X,$20
        08C2: E4 21     MOV A,$21
        08C4: 76 19 1F  CMP A,!$1F19+Y
        08C7: D0 09     BNE .next
        08C9: 7D        MOV A,X
        08CA: 76 11 1F  CMP A,!$1F11+Y
        08CD: D0 03     BNE .next
        08CF: 3F CF 0E  CALL !ReleaseVoice
  .next:
        08D2: 8B 1E     DEC $1E
        08D4: 10 E8     BPL .voice
        08D6: 6F        RET
;=============================================================================
; NoteOn - track $20, note $21, velocity $22, duration $23.
;  1) Older voices of this track:
;       glide == 0: their polyphony counters $1F71 are decremented and a voice
;                   reaching 0 is killed (KOF)  -> per-track polyphony limit
;       glide != 0: released voices of the track are killed
;  2) Walk the program's region chain (head region = program number, link
;     $1E79, bit7 = end). Every region whose key range contains the note
;     starts a voice -> layered and split instruments.
;=============================================================================
NoteOn:
        08D7: F8 20     MOV X,$20
        08D9: F5 89 14  MOV A,!$1489+X
        08DC: C4 1F     MOV $1F,A
        08DE: 8F 07 1E  MOV $1E,#$07
  .voice:
        08E1: EB 1E     MOV Y,$1E
        08E3: E4 20     MOV A,$20
        08E5: 76 11 1F  CMP A,!$1F11+Y
        08E8: D0 18     BNE .next
        08EA: F5 A9 14  MOV A,!$14A9+X
        08ED: F0 07     BEQ .poly
        08EF: F6 79 1F  MOV A,!$1F79+Y
        08F2: 10 0E     BPL .next
        08F4: 2F 09     BRA .kill
  .poly:
        08F6: F6 71 1F  MOV A,!$1F71+Y
        08F9: 9C        DEC A
        08FA: D6 71 1F  MOV !$1F71+Y,A
        08FD: D0 03     BNE .next
  .kill:
        08FF: 3F F8 0E  CALL !KillVoice
  .next:
        0902: 8B 1E     DEC $1E
        0904: 10 DB     BPL .voice
  .region:
        0906: F8 1F     MOV X,$1F
        0908: E4 21     MOV A,$21
        090A: 75 79 17  CMP A,!$1779+X
        090D: 90 0A     BCC .nextRgn
        090F: 75 F9 17  CMP A,!$17F9+X
        0912: F0 02     BEQ .inRange
        0914: B0 03     BCS .nextRgn
  .inRange:
        0916: 3F 23 09  CALL !NoteOnRegion
  .nextRgn:
        0919: F8 1F     MOV X,$1F
        091B: F5 79 1E  MOV A,!$1E79+X
        091E: C4 1F     MOV $1F,A
        0920: 10 E4     BPL .region
        0922: 6F        RET
; NoteOnRegion: in glide/legato mode a held (unreleased) voice of the same track
; and region is re-used (LegatoNote); otherwise a voice is allocated.
NoteOnRegion:
        0923: F8 20     MOV X,$20
        0925: F5 A9 14  MOV A,!$14A9+X
        0928: F0 1D     BEQ AllocVoice
        092A: 8D 07     MOV Y,#$07
  .findLegato:
        092C: F6 39 1F  MOV A,!$1F39+Y
        092F: F0 13     BEQ .next
        0931: E4 20     MOV A,$20
        0933: 76 11 1F  CMP A,!$1F11+Y
        0936: D0 0C     BNE .next
        0938: F6 79 1F  MOV A,!$1F79+Y
        093B: 30 07     BMI .next
        093D: E4 1F     MOV A,$1F
        093F: 76 09 1F  CMP A,!$1F09+Y
        0942: F0 1D     BEQ LegatoNote
  .next:
        0944: DC        DEC Y
        0945: 10 E5     BPL .findLegato
; AllocVoice - priority = track priority*2+1. Picks the voice with the LOWEST
; current priority that is <= the new one (free voices have 0). No candidate ->
; note dropped. Priorities of playing voices decay by 1 every 4 frames (GlobalFX)
; to a floor of 1, so old notes get stolen first.
AllocVoice:
        0947: F5 E9 14  MOV A,!$14E9+X
        094A: 1C        ASL A
        094B: BC        INC A
        094C: 8D FF     MOV Y,#$FF
        094E: CD 07     MOV X,#$07
  .scan:
        0950: 75 39 1F  CMP A,!$1F39+X
        0953: 90 05     BCC .next
        0955: 4D        PUSH X
        0956: EE        POP Y
        0957: F5 39 1F  MOV A,!$1F39+X
  .next:
        095A: 1D        DEC X
        095B: 10 F3     BPL .scan
        095D: DD        MOV A,Y
        095E: 10 59     BPL StartVoice
        0960: 6F        RET
; LegatoNote - same voice, no key-on. New duration. If glide ($14A9) is $7F-$FE
; the pitch jumps (ClearGlide). Otherwise the pitch difference old-new is added
; to the glide offset $1F99/$1FA1, which VoiceFX shrinks by glide*4/256
; semitone per frame -> portamento.
; (Jump case: the pitch-dirty flag is not set, so the new pitch is only written
;  when something else - glide or a pitch envelope - marks the voice dirty.)
LegatoNote:
        0961: E4 23     MOV A,$23
        0963: D6 81 1F  MOV !$1F81+Y,A
        0966: F5 A9 14  MOV A,!$14A9+X
        0969: BC        INC A
        096A: 30 2E     BMI ClearGlide
        096C: F6 21 1F  MOV A,!$1F21+Y
        096F: C4 04     MOV $04,A
        0971: F6 29 1F  MOV A,!$1F29+Y
        0974: C4 05     MOV $05,A
        0976: 3F A2 09  CALL !SetVoicePitch
        0979: 80        SETC
        097A: E4 04     MOV A,$04
        097C: B6 21 1F  SBC A,!$1F21+Y
        097F: C4 04     MOV $04,A
        0981: E4 05     MOV A,$05
        0983: B6 29 1F  SBC A,!$1F29+Y
        0986: C4 05     MOV $05,A
        0988: 60        CLRC
        0989: E4 04     MOV A,$04
        098B: 96 99 1F  ADC A,!$1F99+Y
        098E: D6 99 1F  MOV !$1F99+Y,A
        0991: E4 05     MOV A,$05
        0993: 96 A1 1F  ADC A,!$1FA1+Y
        0996: D6 A1 1F  MOV !$1FA1+Y,A
        0999: 6F        RET
ClearGlide:
        099A: E8 00     MOV A,#$00
        099C: D6 99 1F  MOV !$1F99+Y,A
        099F: D6 A1 1F  MOV !$1FA1+Y,A
; SetVoicePitch: $1F21 = region fine tune, $1F19 = note, $1F29 = note + region transpose
SetVoicePitch:
        09A2: F6 09 1F  MOV A,!$1F09+Y
        09A5: 5D        MOV X,A
        09A6: F5 79 16  MOV A,!$1679+X
        09A9: D6 21 1F  MOV !$1F21+Y,A
        09AC: 60        CLRC
        09AD: E4 21     MOV A,$21
        09AF: D6 19 1F  MOV !$1F19+Y,A
        09B2: 95 F9 16  ADC A,!$16F9+X
        09B5: D6 29 1F  MOV !$1F29+Y,A
        09B8: 6F        RET
; StartVoice Y=voice: owner track, priority, polyphony counter, region,
; key-on delay ($15F9 region, >= 1 frames), duration, and the velocity volume:
;   v = (vel-64)*2+1 ; v = hi(v * vsens) + $41 ; $1F31 = hi(v * vol*2)
StartVoice:
        09B9: E4 20     MOV A,$20
        09BB: D6 11 1F  MOV !$1F11+Y,A
        09BE: 5D        MOV X,A
        09BF: F5 E9 14  MOV A,!$14E9+X
        09C2: 1C        ASL A
        09C3: BC        INC A
        09C4: D6 39 1F  MOV !$1F39+Y,A
        09C7: F5 D9 14  MOV A,!$14D9+X
        09CA: D6 71 1F  MOV !$1F71+Y,A
        09CD: F8 1F     MOV X,$1F
        09CF: 7D        MOV A,X
        09D0: D6 09 1F  MOV !$1F09+Y,A
        09D3: F5 F9 15  MOV A,!$15F9+X
        09D6: D6 01 1F  MOV !$1F01+Y,A
        09D9: E4 23     MOV A,$23
        09DB: D6 81 1F  MOV !$1F81+Y,A
        09DE: E4 22     MOV A,$22
        09E0: 80        SETC
        09E1: A8 40     SBC A,#$40
        09E3: 1C        ASL A
        09E4: BC        INC A
        09E5: C4 0C     MOV $0C,A
        09E7: F5 F9 1C  MOV A,!$1CF9+X
        09EA: C4 0E     MOV $0E,A
        09EC: 6D        PUSH Y
        09ED: 3F 61 05  CALL !SMul8
        09F0: E4 11     MOV A,$11
        09F2: 60        CLRC
        09F3: 88 41     ADC A,#$41
        09F5: FD        MOV Y,A
        09F6: F5 F9 1D  MOV A,!$1DF9+X
        09F9: 1C        ASL A
        09FA: CF        MUL YA
        09FB: DD        MOV A,Y
        09FC: EE        POP Y
        09FD: D6 31 1F  MOV !$1F31+Y,A
        0A00: 2F 98     BRA ClearGlide
; InitSampleTable: sample pointers 0-127 -> DefaultSample ($119C)
InitSampleTable:
        0A02: CD 7F     MOV X,#$7F
  .loop:
        0A04: E8 9C     MOV A,#$9C
        0A06: D5 F9 14  MOV !$14F9+X,A
        0A09: E8 11     MOV A,#$11
        0A0B: D5 79 15  MOV !$1579+X,A
        0A0E: 1D        DEC X
        0A0F: 10 F3     BPL .loop
        0A11: 6F        RET
; InitPitchEnvTable: envelopes 0-63 -> DefaultPitchEnv ($0A22)
InitPitchEnvTable:
        0A12: CD 3F     MOV X,#$3F
  .loop:
        0A14: E8 22     MOV A,#$22
        0A16: D5 D9 1F  MOV !$1FD9+X,A
        0A19: E8 0A     MOV A,#$0A
        0A1B: D5 19 20  MOV !$2019+X,A
        0A1E: 1D        DEC X
        0A1F: 10 F3     BPL .loop
        0A21: 6F        RET
; DefaultPitchEnv: end 9, loop 4, one segment: value 0, slope 0, $FF frames
DefaultPitchEnv:
        0A22: db $09, $00, $04, $00, $00, $00, $00, $00
        0A2A: db $FF
; InitRegions: key-high 0 (never matches) and next = $FF for all 128 regions
InitRegions:
        0A2B: CD 7F     MOV X,#$7F
  .loop:
        0A2D: E8 00     MOV A,#$00
        0A2F: D5 F9 17  MOV !$17F9+X,A
        0A32: 9C        DEC A
        0A33: D5 79 1E  MOV !$1E79+X,A
        0A36: 1D        DEC X
        0A37: 10 F4     BPL .loop
        0A39: 6F        RET
FreeAllVoices:
        0A3A: E8 00     MOV A,#$00
        0A3C: CD 07     MOV X,#$07
  .loop:
        0A3E: D5 39 1F  MOV !$1F39+X,A
        0A41: 1D        DEC X
        0A42: 10 FA     BPL .loop
        0A44: 6F        RET
;=============================================================================
; FrameUpdate (every 10 ms frame) for each voice with priority != 0:
;   key-on delay running: count down; at 0 -> KeyOnVoice + effects
;   playing: read ENVX; when it changes and becomes 0 the voice is freed
;            (priority 0); otherwise VoiceFX, UpdatePitch, UpdateVolume.
;   Finally KOF = 0 and KON = the voices collected in $1D.
;=============================================================================
FrameUpdate:
        0A45: 8F 07 1E  MOV $1E,#$07
  .voice:
        0A48: F8 1E     MOV X,$1E
        0A4A: F5 39 1F  MOV A,!$1F39+X
        0A4D: F0 3C     BEQ .next
        0A4F: F5 01 1F  MOV A,!$1F01+X
        0A52: F0 14     BEQ .playing
        0A54: 9C        DEC A
        0A55: D5 01 1F  MOV !$1F01+X,A
        0A58: D0 31     BNE .next
        0A5A: 3F 9F 0A  CALL !KeyOnVoice
        0A5D: 3F F9 0D  CALL !VoiceFX
        0A60: 3F 6A 0C  CALL !UpdatePitch
        0A63: 3F FF 0C  CALL !UpdateVolume
        0A66: 2F 23     BRA .next
  .playing:
        0A68: 7D        MOV A,X
        0A69: 9F        XCN A
        0A6A: 08 08     OR A,#$08
        0A6C: C4 F2     MOV $F2,A
        0A6E: E4 F3     MOV A,$F3
        0A70: 75 F9 1E  CMP A,!$1EF9+X
        0A73: F0 0D     BEQ .update
        0A75: D5 F9 1E  MOV !$1EF9+X,A
        0A78: 9C        DEC A
        0A79: 10 07     BPL .update
        0A7B: E8 00     MOV A,#$00
        0A7D: D5 39 1F  MOV !$1F39+X,A
        0A80: 2F 09     BRA .next
  .update:
        0A82: 3F F9 0D  CALL !VoiceFX
        0A85: 3F 6A 0C  CALL !UpdatePitch
        0A88: 3F FF 0C  CALL !UpdateVolume
  .next:
        0A8B: 8B 1E     DEC $1E
        0A8D: 10 B9     BPL .voice
        0A8F: 8F 5C F2  MOV $F2,#$5C
        0A92: 8F 00 F3  MOV $F3,#$00
        0A95: 8F 4C F2  MOV $F2,#$4C
        0A98: FA 1D F3  MOV $F3,$1D
        0A9B: 8F 00 1D  MOV $1D,#$00
        0A9E: 6F        RET
; KeyOnVoice: KOF this voice now (KON follows at the end of the frame),
; sample/DIR setup, ADSR1 = region|$80, ADSR2, initial pan, flags = $41
; (pitch + volume dirty), pitch-env state reset (first segment next frame).
KeyOnVoice:
        0A9F: F8 1E     MOV X,$1E
        0AA1: 8F 5C F2  MOV $F2,#$5C
        0AA4: F5 B5 11  MOV A,!$11B5+X
        0AA7: C4 F3     MOV $F3,A
        0AA9: 04 1D     OR A,$1D
        0AAB: C4 1D     MOV $1D,A
        0AAD: 3F FC 0A  CALL !SetupSample
        0AB0: F8 1E     MOV X,$1E
        0AB2: F5 09 1F  MOV A,!$1F09+X
        0AB5: FD        MOV Y,A
        0AB6: 7D        MOV A,X
        0AB7: 9F        XCN A
        0AB8: 08 05     OR A,#$05
        0ABA: C4 F2     MOV $F2,A
        0ABC: F6 79 1B  MOV A,!$1B79+Y
        0ABF: 08 80     OR A,#$80
        0AC1: C4 F3     MOV $F3,A
        0AC3: 7D        MOV A,X
        0AC4: 9F        XCN A
        0AC5: 08 06     OR A,#$06
        0AC7: C4 F2     MOV $F2,A
        0AC9: F6 F9 1B  MOV A,!$1BF9+Y
        0ACC: C4 F3     MOV $F3,A
        0ACE: F5 09 1F  MOV A,!$1F09+X         ; (dead load - immediately overwritten)
        0AD1: F6 79 1D  MOV A,!$1D79+Y
        0AD4: D5 89 1F  MOV !$1F89+X,A
        0AD7: 10 03     BPL .flags
        0AD9: 3F 68 0D  CALL !AutoPan
  .flags:
        0ADC: E8 41     MOV A,#$41
        0ADE: D5 79 1F  MOV !$1F79+X,A
        0AE1: E8 00     MOV A,#$00
        0AE3: D5 F9 1E  MOV !$1EF9+X,A
        0AE6: D5 51 1F  MOV !$1F51+X,A
        0AE9: D5 59 1F  MOV !$1F59+X,A
        0AEC: D5 61 1F  MOV !$1F61+X,A
        0AEF: D5 69 1F  MOV !$1F69+X,A
        0AF2: BC        INC A
        0AF3: D5 41 1F  MOV !$1F41+X,A
        0AF6: E8 04     MOV A,#$04
        0AF8: D5 49 1F  MOV !$1F49+X,A
        0AFB: 6F        RET
; SetupSample: region sample number ($1879).
;  bit7 clear: sample table entry -> header [fine][semitone][loop offset word],
;              BRR follows. DIR entry for SRCN = voice number is rewritten
;              (start, start+loop offset). Every voice owns DIR slot n.
;  bit7 set:   synthetic wave (SetupSynthWave)
SetupSample:
        0AFC: F5 09 1F  MOV A,!$1F09+X
        0AFF: FD        MOV Y,A
        0B00: F6 79 18  MOV A,!$1879+Y
        0B03: D5 A9 1F  MOV !$1FA9+X,A
        0B06: 10 03     BPL .brr
        0B08: 5F 70 0B  JMP !SetupSynthWave
  .brr:
        0B0B: FD        MOV Y,A
        0B0C: F6 F9 14  MOV A,!$14F9+Y
        0B0F: C4 04     MOV $04,A
        0B11: F6 79 15  MOV A,!$1579+Y
        0B14: C4 05     MOV $05,A
        0B16: 8D 00     MOV Y,#$00
        0B18: F7 04     MOV A,[$04]+Y
        0B1A: 3A 04     INCW $04
        0B1C: D5 B1 1F  MOV !$1FB1+X,A
        0B1F: F7 04     MOV A,[$04]+Y
        0B21: 3A 04     INCW $04
        0B23: D5 B9 1F  MOV !$1FB9+X,A
        0B26: F7 04     MOV A,[$04]+Y
        0B28: 3A 04     INCW $04
        0B2A: 2D        PUSH A
        0B2B: F7 04     MOV A,[$04]+Y
        0B2D: 3A 04     INCW $04
        0B2F: FD        MOV Y,A
        0B30: AE        POP A
        0B31: 7A 04     ADDW YA,$04
        0B33: DA 06     MOVW $06,YA
; WriteDirEntry X=voice: DIR $0100 + voice*4 = start $04/05, loop $06/07
WriteDirEntry:
        0B35: 7D        MOV A,X
        0B36: 1C        ASL A
        0B37: 1C        ASL A
        0B38: FD        MOV Y,A
        0B39: E4 04     MOV A,$04
        0B3B: D6 00 01  MOV !$0100+Y,A
        0B3E: E4 05     MOV A,$05
        0B40: D6 01 01  MOV !$0101+Y,A
        0B43: E4 06     MOV A,$06
        0B45: D6 02 01  MOV !$0102+Y,A
        0B48: E4 07     MOV A,$07
        0B4A: D6 03 01  MOV !$0103+Y,A
        0B4D: 6F        RET
; DirSilentThenBuffer: start = SilentBlock $1193, loop = this voice's 36-byte buffer
DirSilentThenBuffer:
        0B4E: F5 AD 11  MOV A,!$11AD+X
        0B51: 8F 93 04  MOV $04,#$93
        0B54: C4 06     MOV $06,A
        0B56: F5 A5 11  MOV A,!$11A5+X
        0B59: 8F 11 05  MOV $05,#$11
        0B5C: C4 07     MOV $07,A
        0B5E: 2F D5     BRA WriteDirEntry
; Wave_Direct: DIR start = loop = the wave source itself (noise blocks / global PWM wave)
Wave_Direct:
        0B60: F8 1E     MOV X,$1E
        0B62: FA 08 04  MOV $04,$08
        0B65: FA 08 06  MOV $06,$08
        0B68: FA 09 05  MOV $05,$09
        0B6B: FA 09 07  MOV $07,$09
        0B6E: 2F C5     BRA WriteDirEntry
; SetupSynthWave A = $80 | (h<<5) | n : wave n (0-31) picks semitone offset
; SynthTuneTable[n], source SynthSourceTable[n] and init routine SynthInitTable[n];
; h (0-3) picks the BRR header from SynthHeaderTable (B0/84/58/5C = amplitude).
SetupSynthWave:
        0B70: 2D        PUSH A
        0B71: 28 1F     AND A,#$1F
        0B73: FD        MOV Y,A
        0B74: F6 19 13  MOV A,!$1319+Y
        0B77: D5 B9 1F  MOV !$1FB9+X,A
        0B7A: E8 00     MOV A,#$00
        0B7C: D5 B1 1F  MOV !$1FB1+X,A
        0B7F: DD        MOV A,Y
        0B80: 1C        ASL A
        0B81: 5D        MOV X,A
        0B82: F5 39 13  MOV A,!$1339+X
        0B85: C4 08     MOV $08,A
        0B87: F5 3A 13  MOV A,!$133A+X
        0B8A: C4 09     MOV $09,A
        0B8C: AE        POP A
        0B8D: 9F        XCN A
        0B8E: 5C        LSR A
        0B8F: 28 03     AND A,#$03
        0B91: 1F 79 13  JMP [!SynthInitTable+X]
; Wave_1Block: one 16-sample block (end+loop) copied into the voice buffer
Wave_1Block:
        0B94: F8 1E     MOV X,$1E
        0B96: 2D        PUSH A
        0B97: 3F 4E 0B  CALL !DirSilentThenBuffer
        0B9A: CE        POP X
        0B9B: F5 29 12  MOV A,!$1229+X
        0B9E: 3F D3 0B  CALL !CopyBRRBlock
        0BA1: 08 03     OR A,#$03
        0BA3: 2F 2E     BRA CopyBRRBlock
; Wave_NoisySquare: as Wave_4Block, plus Mod_Noise state (pos 0, mask NoiseMaskTable[syn1&7])
Wave_NoisySquare:
        0BA5: F8 1E     MOV X,$1E
        0BA7: 2D        PUSH A
        0BA8: E8 00     MOV A,#$00
        0BAA: D5 C1 1F  MOV !$1FC1+X,A
        0BAD: F5 09 1F  MOV A,!$1F09+X
        0BB0: FD        MOV Y,A
        0BB1: F6 F9 18  MOV A,!$18F9+Y
        0BB4: 28 07     AND A,#$07
        0BB6: FD        MOV Y,A
        0BB7: F6 1C 0C  MOV A,!$0C1C+Y
        0BBA: D5 C9 1F  MOV !$1FC9+X,A
        0BBD: AE        POP A
; Wave_4Block: four blocks (64 samples) copied into the voice buffer, last = end+loop
Wave_4Block:
        0BBE: F8 1E     MOV X,$1E
        0BC0: 2D        PUSH A
        0BC1: 3F 4E 0B  CALL !DirSilentThenBuffer
        0BC4: CE        POP X
        0BC5: F5 29 12  MOV A,!$1229+X
        0BC8: 3F D3 0B  CALL !CopyBRRBlock
        0BCB: 3F D3 0B  CALL !CopyBRRBlock
        0BCE: 3F D3 0B  CALL !CopyBRRBlock
        0BD1: 08 03     OR A,#$03
; CopyBRRBlock: header A + 8 bytes from [$08]++ to [$06]++
CopyBRRBlock:
        0BD3: 8D 00     MOV Y,#$00
        0BD5: D7 06     MOV [$06]+Y,A
        0BD7: 3A 06     INCW $06
        0BD9: 2D        PUSH A
        0BDA: F7 08     MOV A,[$08]+Y
        0BDC: 3A 08     INCW $08
        0BDE: D7 06     MOV [$06]+Y,A
        0BE0: 3A 06     INCW $06
        0BE2: F7 08     MOV A,[$08]+Y
        0BE4: 3A 08     INCW $08
        0BE6: D7 06     MOV [$06]+Y,A
        0BE8: 3A 06     INCW $06
        0BEA: F7 08     MOV A,[$08]+Y
        0BEC: 3A 08     INCW $08
        0BEE: D7 06     MOV [$06]+Y,A
        0BF0: 3A 06     INCW $06
        0BF2: F7 08     MOV A,[$08]+Y
        0BF4: 3A 08     INCW $08
        0BF6: D7 06     MOV [$06]+Y,A
        0BF8: 3A 06     INCW $06
        0BFA: F7 08     MOV A,[$08]+Y
        0BFC: 3A 08     INCW $08
        0BFE: D7 06     MOV [$06]+Y,A
        0C00: 3A 06     INCW $06
        0C02: F7 08     MOV A,[$08]+Y
        0C04: 3A 08     INCW $08
        0C06: D7 06     MOV [$06]+Y,A
        0C08: 3A 06     INCW $06
        0C0A: F7 08     MOV A,[$08]+Y
        0C0C: 3A 08     INCW $08
        0C0E: D7 06     MOV [$06]+Y,A
        0C10: 3A 06     INCW $06
        0C12: F7 08     MOV A,[$08]+Y
        0C14: 3A 08     INCW $08
        0C16: D7 06     MOV [$06]+Y,A
        0C18: 3A 06     INCW $06
        0C1A: AE        POP A
        0C1B: 6F        RET
NoiseMaskTable:
        0C1C: db $10, $11, $13, $33, $37, $77, $7F, $FF
; Wave_PWM: 4-block square from wave data, step = syn1 ($18F9),
; limit = min(-step, syn2 $1979), start position = limit/2, then pre-fill
; position>>4 bytes of block 1 with $77.
Wave_PWM:
        0C24: F8 1E     MOV X,$1E
        0C26: 3F BE 0B  CALL !Wave_4Block
        0C29: F8 1E     MOV X,$1E
        0C2B: F5 09 1F  MOV A,!$1F09+X
        0C2E: FD        MOV Y,A
        0C2F: F6 F9 18  MOV A,!$18F9+Y
        0C32: D5 C9 1F  MOV !$1FC9+X,A
        0C35: 48 FF     EOR A,#$FF
        0C37: BC        INC A
        0C38: 76 79 19  CMP A,!$1979+Y
        0C3B: 90 03     BCC .lim
        0C3D: F6 79 19  MOV A,!$1979+Y
  .lim:
        0C40: D5 D1 1F  MOV !$1FD1+X,A
        0C43: 5C        LSR A
        0C44: D5 C1 1F  MOV !$1FC1+X,A
        0C47: F5 AD 11  MOV A,!$11AD+X
        0C4A: C4 04     MOV $04,A
        0C4C: F5 A5 11  MOV A,!$11A5+X
        0C4F: C4 05     MOV $05,A
        0C51: F5 C1 1F  MOV A,!$1FC1+X
        0C54: 9F        XCN A
        0C55: 28 0F     AND A,#$0F
        0C57: 5D        MOV X,A
        0C58: 8D 01     MOV Y,#$01
        0C5A: E8 77     MOV A,#$77
        0C5C: 2F 08     BRA .cnt
  .fill:
        0C5E: D7 04     MOV [$04]+Y,A
        0C60: FC        INC Y
        0C61: AD 09     CMP Y,#$09
        0C63: D0 01     BNE .cnt
        0C65: FC        INC Y
  .cnt:
        0C66: 1D        DEC X
        0C67: 10 F5     BPL .fill
        0C69: 6F        RET
;=============================================================================
; UpdatePitch (when flag bit0 set)
;   p (8.8 semitones) = $1F29:$1F21 (note+transpose : fine)
;                     + glide $1FA1:$1F99 + pitch env $1F59:$1F51
;                     + sample tune $1FB9:$1FB1
;   hi clamped to $77 (119). idx = (hi mod 12)*16 + lo/16 (1/16-semitone steps),
;   linear interpolation by lo&15 between PitchTable[idx] and [idx+1],
;   then >> (9 - hi div 12).  Note 108 (+0 tune) = $215B: a 16-sample loop
;   then sounds at the note's true frequency.
;=============================================================================
UpdatePitch:
        0C6A: F8 1E     MOV X,$1E
        0C6C: F5 79 1F  MOV A,!$1F79+X
        0C6F: 5C        LSR A
        0C70: B0 01     BCS .go
        0C72: 6F        RET
  .go:
        0C73: 1C        ASL A
        0C74: D5 79 1F  MOV !$1F79+X,A
        0C77: 60        CLRC
        0C78: F5 21 1F  MOV A,!$1F21+X
        0C7B: 95 99 1F  ADC A,!$1F99+X
        0C7E: C4 04     MOV $04,A
        0C80: F5 29 1F  MOV A,!$1F29+X
        0C83: 95 A1 1F  ADC A,!$1FA1+X
        0C86: C4 05     MOV $05,A
        0C88: 60        CLRC
        0C89: E4 04     MOV A,$04
        0C8B: 95 51 1F  ADC A,!$1F51+X
        0C8E: C4 04     MOV $04,A
        0C90: E4 05     MOV A,$05
        0C92: 95 59 1F  ADC A,!$1F59+X
        0C95: C4 05     MOV $05,A
        0C97: 60        CLRC
        0C98: E4 04     MOV A,$04
        0C9A: 95 B1 1F  ADC A,!$1FB1+X
        0C9D: C4 04     MOV $04,A
        0C9F: E4 05     MOV A,$05
        0CA1: 95 B9 1F  ADC A,!$1FB9+X
        0CA4: C4 05     MOV $05,A
        0CA6: E4 04     MOV A,$04
        0CA8: 28 F0     AND A,#$F0
        0CAA: C4 06     MOV $06,A
        0CAC: E4 05     MOV A,$05
        0CAE: 68 77     CMP A,#$77
        0CB0: 90 05     BCC .oct
        0CB2: E8 77     MOV A,#$77
        0CB4: 8F 00 06  MOV $06,#$00
  .oct:
        0CB7: 8D 0A     MOV Y,#$0A
        0CB9: 80        SETC
  .div12:
        0CBA: DC        DEC Y
        0CBB: A8 0C     SBC A,#$0C
        0CBD: B0 FB     BCS .div12
        0CBF: 88 0C     ADC A,#$0C
        0CC1: 04 06     OR A,$06
        0CC3: 9F        XCN A
        0CC4: 5D        MOV X,A
        0CC5: F5 80 10  MOV A,!$1080+X
        0CC8: C4 06     MOV $06,A
        0CCA: 6D        PUSH Y
        0CCB: F5 81 10  MOV A,!$1081+X
        0CCE: 80        SETC
        0CCF: A4 06     SBC A,$06
        0CD1: FD        MOV Y,A
        0CD2: E4 04     MOV A,$04
        0CD4: 28 0F     AND A,#$0F
        0CD6: 9F        XCN A
        0CD7: CF        MUL YA
        0CD8: DD        MOV A,Y
        0CD9: 60        CLRC
        0CDA: 84 06     ADC A,$06
        0CDC: C4 06     MOV $06,A
        0CDE: EE        POP Y
        0CDF: E8 00     MOV A,#$00
        0CE1: 95 C0 0F  ADC A,!$0FC0+X
        0CE4: 2F 03     BRA .cnt
  .shift:
        0CE6: 5C        LSR A
        0CE7: 6B 06     ROR $06
  .cnt:
        0CE9: DC        DEC Y
        0CEA: 10 FA     BPL .shift
        0CEC: C4 07     MOV $07,A
        0CEE: E4 1E     MOV A,$1E
        0CF0: 9F        XCN A
        0CF1: 08 02     OR A,#$02
        0CF3: C4 F2     MOV $F2,A
        0CF5: FA 06 F3  MOV $F3,$06
        0CF8: BC        INC A
        0CF9: C4 F2     MOV $F2,A
        0CFB: FA 07 F3  MOV $F3,$07
        0CFE: 6F        RET
;=============================================================================
; UpdateVolume (when flag bit6 set)
;   v = (trackVol $14C9 * voiceVol $1F31) >> 7   (both sides)
;   stereo on and pan != $40:  d = pan-$40, the far side is scaled by
;   (4*(31-|d|)+2)/128 (signed): |d| = 32 -> 0, |d| > 32 -> NEGATIVE volume
;   (phase-inverted far side). pan < $40 = left, > $40 = right.
;   So $20/$60 are hard left/right and $00/$7F are "surround" pans.
;=============================================================================
UpdateVolume:
        0CFF: F8 1E     MOV X,$1E
        0D01: F5 79 1F  MOV A,!$1F79+X
        0D04: 1C        ASL A
        0D05: 30 01     BMI .go
        0D07: 6F        RET
  .go:
        0D08: F5 79 1F  MOV A,!$1F79+X
        0D0B: 28 BF     AND A,#$BF
        0D0D: D5 79 1F  MOV !$1F79+X,A
        0D10: F5 11 1F  MOV A,!$1F11+X
        0D13: FD        MOV Y,A
        0D14: F6 C9 14  MOV A,!$14C9+Y
        0D17: FD        MOV Y,A
        0D18: F5 31 1F  MOV A,!$1F31+X
        0D1B: CF        MUL YA
        0D1C: 1C        ASL A
        0D1D: DD        MOV A,Y
        0D1E: 3C        ROL A
        0D1F: C4 04     MOV $04,A
        0D21: C4 05     MOV $05,A
        0D23: E4 51     MOV A,$51
        0D25: F0 33     BEQ .write
        0D27: F5 89 1F  MOV A,!$1F89+X
        0D2A: 80        SETC
        0D2B: A8 40     SBC A,#$40
        0D2D: F0 2B     BEQ .write
        0D2F: C4 06     MOV $06,A
        0D31: 30 02     BMI .side
        0D33: 48 FF     EOR A,#$FF
  .side:
        0D35: 60        CLRC
        0D36: 88 20     ADC A,#$20
        0D38: 1C        ASL A
        0D39: BC        INC A
        0D3A: 1C        ASL A
        0D3B: C4 0C     MOV $0C,A
        0D3D: FA 05 0E  MOV $0E,$05
        0D40: 3F 61 05  CALL !SMul8
        0D43: E4 11     MOV A,$11
        0D45: 0B 10     ASL $10
        0D47: 3C        ROL A
        0D48: BC        INC A
        0D49: 10 02     BPL .pos
        0D4B: 80        SETC
        0D4C: 7C        ROR A
  .pos:
        0D4D: C4 05     MOV $05,A
        0D4F: E4 06     MOV A,$06
        0D51: 30 07     BMI .write
        0D53: E4 04     MOV A,$04
        0D55: FA 05 04  MOV $04,$05
        0D58: C4 05     MOV $05,A
  .write:
        0D5A: 7D        MOV A,X
        0D5B: 9F        XCN A
        0D5C: C4 F2     MOV $F2,A
        0D5E: FA 04 F3  MOV $F3,$04
        0D61: BC        INC A
        0D62: C4 F2     MOV $F2,A
        0D64: FA 05 F3  MOV $F3,$05
        0D67: 6F        RET
; AutoPan A = region pan with bit7 set: mode = A & 15 -> AutoPanTable entry
;   [LFO zp addr][shift][offset][0]. pan = fold(LFO + track pan) >> shift + offset
;   LFOs: $54 (slow), $29 (frame count), $55 (fast), $53 (random walk).
;   Shift/offset pairs per LFO: (0,0) full sweep, (1,$20), (2,$20), (2,$40) narrower.
;   A = $FF means "use the track pan" (StaticPan).
AutoPan:
        0D68: C4 04     MOV $04,A
        0D6A: BC        INC A
        0D6B: F0 41     BEQ StaticPan
        0D6D: F5 11 1F  MOV A,!$1F11+X
        0D70: FD        MOV Y,A
        0D71: F6 B9 14  MOV A,!$14B9+Y
        0D74: C4 05     MOV $05,A
        0D76: E4 04     MOV A,$04
        0D78: 28 0F     AND A,#$0F
        0D7A: 1C        ASL A
        0D7B: 1C        ASL A
        0D7C: FD        MOV Y,A
        0D7D: F6 B9 0D  MOV A,!$0DB9+Y
        0D80: 5D        MOV X,A
        0D81: E6        MOV A,(X)
        0D82: 60        CLRC
        0D83: 84 05     ADC A,$05
        0D85: 10 02     BPL .fold
        0D87: 48 FF     EOR A,#$FF
  .fold:
        0D89: C4 04     MOV $04,A
        0D8B: F6 BA 0D  MOV A,!$0DBA+Y
        0D8E: F0 05     BEQ .ofs
  .shr:
        0D90: 4B 04     LSR $04
        0D92: 9C        DEC A
        0D93: D0 FB     BNE .shr
  .ofs:
        0D95: F6 BB 0D  MOV A,!$0DBB+Y
        0D98: 60        CLRC
        0D99: 84 04     ADC A,$04
        0D9B: F8 1E     MOV X,$1E
        0D9D: 75 89 1F  CMP A,!$1F89+X
        0DA0: F0 0B     BEQ .ret
        0DA2: D5 89 1F  MOV !$1F89+X,A
        0DA5: F5 79 1F  MOV A,!$1F79+X
        0DA8: 08 40     OR A,#$40
        0DAA: D5 79 1F  MOV !$1F79+X,A
  .ret:
        0DAD: 6F        RET
StaticPan:
        0DAE: F5 11 1F  MOV A,!$1F11+X
        0DB1: FD        MOV Y,A
        0DB2: F6 B9 14  MOV A,!$14B9+Y
        0DB5: D5 89 1F  MOV !$1F89+X,A
        0DB8: 6F        RET
; AutoPanTable: 16 x [zp LFO][shift][offset][pad]
AutoPanTable:
        0DB9: db $54, $00, $00, $00
        0DBD: db $54, $01, $20, $00
        0DC1: db $54, $02, $20, $00
        0DC5: db $54, $02, $40, $00
        0DC9: db $29, $00, $00, $00
        0DCD: db $29, $01, $20, $00
        0DD1: db $29, $02, $20, $00
        0DD5: db $29, $02, $40, $00
        0DD9: db $55, $00, $00, $00
        0DDD: db $55, $01, $20, $00
        0DE1: db $55, $02, $20, $00
        0DE5: db $55, $02, $40, $00
        0DE9: db $53, $00, $00, $00
        0DED: db $53, $01, $20, $00
        0DF1: db $53, $02, $20, $00
        0DF5: db $53, $02, $40, $00
;=============================================================================
; VoiceFX (per frame): auto-pan, glide decay, pitch envelope.
;  Pitch envelope (region $19F9 < $80, track $1499 != 0):
;   table [end][?][loop][?] then 5-byte segments:
;     value(16, 1/256 semitone)  slope(16, per frame)  frames
;   at each segment start the value is loaded; then value += slope every frame.
;   After the last segment (offset >= end) it continues at 'loop'.
;=============================================================================
VoiceFX:
        0DF9: F8 1E     MOV X,$1E
        0DFB: F5 09 1F  MOV A,!$1F09+X
        0DFE: FD        MOV Y,A
        0DFF: F6 79 1D  MOV A,!$1D79+Y
        0E02: 10 03     BPL .glide
        0E04: 3F 68 0D  CALL !AutoPan
  .glide:
        0E07: F5 A1 1F  MOV A,!$1FA1+X
        0E0A: 15 99 1F  OR A,!$1F99+X
        0E0D: F0 3A     BEQ .penv
        0E0F: F5 11 1F  MOV A,!$1F11+X
        0E12: FD        MOV Y,A
        0E13: F6 A9 14  MOV A,!$14A9+Y
        0E16: C4 04     MOV $04,A
        0E18: 1C        ASL A
        0E19: 1C        ASL A
        0E1A: C4 04     MOV $04,A
        0E1C: 8F 00 05  MOV $05,#$00
        0E1F: 2B 05     ROL $05
        0E21: F5 A1 1F  MOV A,!$1FA1+X
        0E24: FD        MOV Y,A
        0E25: 30 0C     BMI .neg
        0E27: F5 99 1F  MOV A,!$1F99+X
        0E2A: 9A 04     SUBW YA,$04
        0E2C: 10 0C     BPL .store
  .zero:
        0E2E: E8 00     MOV A,#$00
        0E30: FD        MOV Y,A
        0E31: 2F 07     BRA .store
  .neg:
        0E33: F5 99 1F  MOV A,!$1F99+X
        0E36: 7A 04     ADDW YA,$04
        0E38: 10 F4     BPL .zero
  .store:
        0E3A: D5 99 1F  MOV !$1F99+X,A
        0E3D: DD        MOV A,Y
        0E3E: D5 A1 1F  MOV !$1FA1+X,A
        0E41: F5 79 1F  MOV A,!$1F79+X
        0E44: 08 01     OR A,#$01
        0E46: D5 79 1F  MOV !$1F79+X,A
  .penv:
        0E49: F5 11 1F  MOV A,!$1F11+X
        0E4C: FD        MOV Y,A
        0E4D: F6 99 14  MOV A,!$1499+Y
        0E50: F0 7C     BEQ .ret
        0E52: F5 09 1F  MOV A,!$1F09+X
        0E55: FD        MOV Y,A
        0E56: F6 F9 19  MOV A,!$19F9+Y
        0E59: 30 73     BMI .ret
        0E5B: FD        MOV Y,A
        0E5C: F5 41 1F  MOV A,!$1F41+X
        0E5F: 9C        DEC A
        0E60: D5 41 1F  MOV !$1F41+X,A
        0E63: D0 44     BNE .slope
        0E65: F6 D9 1F  MOV A,!$1FD9+Y
        0E68: C4 04     MOV $04,A
        0E6A: F6 19 20  MOV A,!$2019+Y
        0E6D: C4 05     MOV $05,A
        0E6F: 8D 00     MOV Y,#$00
        0E71: F7 04     MOV A,[$04]+Y
        0E73: C4 06     MOV $06,A
        0E75: 8D 02     MOV Y,#$02
        0E77: F7 04     MOV A,[$04]+Y
        0E79: C4 07     MOV $07,A
        0E7B: F5 49 1F  MOV A,!$1F49+X
        0E7E: FD        MOV Y,A
        0E7F: 7E 06     CMP Y,$06
        0E81: 90 02     BCC .loadSeg
        0E83: EB 07     MOV Y,$07
  .loadSeg:
        0E85: F7 04     MOV A,[$04]+Y
        0E87: FC        INC Y
        0E88: D5 51 1F  MOV !$1F51+X,A
        0E8B: F7 04     MOV A,[$04]+Y
        0E8D: FC        INC Y
        0E8E: D5 59 1F  MOV !$1F59+X,A
        0E91: F7 04     MOV A,[$04]+Y
        0E93: FC        INC Y
        0E94: D5 61 1F  MOV !$1F61+X,A
        0E97: F7 04     MOV A,[$04]+Y
        0E99: FC        INC Y
        0E9A: D5 69 1F  MOV !$1F69+X,A
        0E9D: F7 04     MOV A,[$04]+Y
        0E9F: FC        INC Y
        0EA0: D5 41 1F  MOV !$1F41+X,A
        0EA3: DD        MOV A,Y
        0EA4: D5 49 1F  MOV !$1F49+X,A
        0EA7: 2F 1D     BRA .dirty
  .slope:
        0EA9: 60        CLRC
        0EAA: F5 61 1F  MOV A,!$1F61+X
        0EAD: C4 04     MOV $04,A
        0EAF: 95 51 1F  ADC A,!$1F51+X
        0EB2: D5 51 1F  MOV !$1F51+X,A
        0EB5: F5 69 1F  MOV A,!$1F69+X
        0EB8: C4 05     MOV $05,A
        0EBA: 95 59 1F  ADC A,!$1F59+X
        0EBD: D5 59 1F  MOV !$1F59+X,A
        0EC0: E4 04     MOV A,$04
        0EC2: 04 05     OR A,$05
        0EC4: F0 08     BEQ .ret
  .dirty:
        0EC6: F5 79 1F  MOV A,!$1F79+X
        0EC9: 08 01     OR A,#$01
        0ECB: D5 79 1F  MOV !$1F79+X,A
  .ret:
        0ECE: 6F        RET
; ReleaseVoice: flag bit7 (released), stop key-on delay, GAIN = $A0|rate
; (exponential decrease, rate from region $1C79), ADSR1 = 0 (GAIN mode).
ReleaseVoice:
        0ECF: F8 1E     MOV X,$1E
        0ED1: F5 79 1F  MOV A,!$1F79+X
        0ED4: 08 80     OR A,#$80
        0ED6: D5 79 1F  MOV !$1F79+X,A
        0ED9: E8 00     MOV A,#$00
        0EDB: D5 01 1F  MOV !$1F01+X,A
        0EDE: 7D        MOV A,X
        0EDF: 9F        XCN A
        0EE0: 08 07     OR A,#$07
        0EE2: FD        MOV Y,A
        0EE3: F5 09 1F  MOV A,!$1F09+X
        0EE6: 5D        MOV X,A
        0EE7: F5 79 1C  MOV A,!$1C79+X
        0EEA: 08 A0     OR A,#$A0
        0EEC: CB F2     MOV $F2,Y
        0EEE: C4 F3     MOV $F3,A
        0EF0: DC        DEC Y
        0EF1: DC        DEC Y
        0EF2: CB F2     MOV $F2,Y
        0EF4: 8F 00 F3  MOV $F3,#$00
        0EF7: 6F        RET
; KillVoice: KOF + priority 0
KillVoice:
        0EF8: F8 1E     MOV X,$1E
        0EFA: 8F 5C F2  MOV $F2,#$5C
        0EFD: F5 B5 11  MOV A,!$11B5+X
        0F00: C4 F3     MOV $F3,A
        0F02: E8 00     MOV A,#$00
        0F04: D5 39 1F  MOV !$1F39+X,A
        0F07: 80        SETC
        0F08: 6F        RET
; DSPReset: echo off/ESA $FF/EDL 0, wait, FLG $27 (echo writes off, noise clk 7),
; EFB/EON/EVOL/PMON/NON = 0, DIR = $01 ($0100), KOF all, SRCN n = n, priorities 0,
; KON $FF (keys all voices once with whatever DIR holds), wait.
DSPReset:
        0F09: E8 00     MOV A,#$00
        0F0B: 8F 6D F2  MOV $F2,#$6D
        0F0E: 8F FF F3  MOV $F3,#$FF
        0F11: 8F 7D F2  MOV $F2,#$7D
        0F14: C4 F3     MOV $F3,A
  .wait:
        0F16: 00        NOP
        0F17: 00        NOP
        0F18: 9C        DEC A
        0F19: D0 FB     BNE .wait
        0F1B: 8F 6C F2  MOV $F2,#$6C
        0F1E: 8F 27 F3  MOV $F3,#$27
        0F21: 8F 0D F2  MOV $F2,#$0D
        0F24: C4 F3     MOV $F3,A
        0F26: 8F 4D F2  MOV $F2,#$4D
        0F29: C4 F3     MOV $F3,A
        0F2B: 8F 2C F2  MOV $F2,#$2C
        0F2E: C4 F3     MOV $F3,A
        0F30: 8F 3C F2  MOV $F2,#$3C
        0F33: C4 F3     MOV $F3,A
        0F35: 8F 2D F2  MOV $F2,#$2D
        0F38: C4 F3     MOV $F3,A
        0F3A: 8F 5D F2  MOV $F2,#$5D
        0F3D: 8F 01 F3  MOV $F3,#$01
        0F40: 8F 3D F2  MOV $F2,#$3D
        0F43: C4 F3     MOV $F3,A
        0F45: 8F 5C F2  MOV $F2,#$5C
        0F48: 8F FF F3  MOV $F3,#$FF
        0F4B: 8D 07     MOV Y,#$07
  .srcn:
        0F4D: DD        MOV A,Y
        0F4E: 9F        XCN A
        0F4F: 08 04     OR A,#$04
        0F51: C4 F2     MOV $F2,A
        0F53: CB F3     MOV $F3,Y
        0F55: E8 00     MOV A,#$00
        0F57: D6 39 1F  MOV !$1F39+Y,A
        0F5A: DC        DEC Y
        0F5B: 10 F0     BPL .srcn
        0F5D: 8F 00 1D  MOV $1D,#$00
        0F60: 8F 4C F2  MOV $F2,#$4C
        0F63: 8F FF F3  MOV $F3,#$FF
        0F66: E8 00     MOV A,#$00
  .wait2:
        0F68: 9C        DEC A
        0F69: D0 FD     BNE .wait2
        0F6B: 6F        RET
;=============================================================================
; GlobalFX (per frame)
;  - global PWM wave at $11BD (synth wave 28): position $59 += $57 bouncing at $58
;  - every 4th frame: priorities of busy voices decay by 1 (floor 1)
;  - per-voice wave modulators via SynthModTable for synth regions
;=============================================================================
GlobalFX:
        0F6C: 8F BD 04  MOV $04,#$BD
        0F6F: 8F 11 05  MOV $05,#$11
        0F72: E4 59     MOV A,$59
        0F74: 60        CLRC
        0F75: 84 57     ADC A,$57
        0F77: 64 58     CMP A,$58
        0F79: 90 09     BCC .store
        0F7B: E4 57     MOV A,$57
        0F7D: 48 FF     EOR A,#$FF
        0F7F: BC        INC A
        0F80: C4 57     MOV $57,A
        0F82: 2F 02     BRA .write
  .store:
        0F84: C4 59     MOV $59,A
  .write:
        0F86: E4 59     MOV A,$59
        0F88: 3F 22 08  CALL !WritePulseEdge
        0F8B: E4 29     MOV A,$29
        0F8D: 28 03     AND A,#$03
        0F8F: D0 13     BNE .mods
        0F91: 8D 07     MOV Y,#$07
  .decay:
        0F93: F6 39 1F  MOV A,!$1F39+Y
        0F96: F0 09     BEQ .next
        0F98: 68 FF     CMP A,#$FF
        0F9A: 88 FF     ADC A,#$FF
        0F9C: F0 03     BEQ .next
        0F9E: D6 39 1F  MOV !$1F39+Y,A
  .next:
        0FA1: DC        DEC Y
        0FA2: 10 EF     BPL .decay
  .mods:
        0FA4: 8D 07     MOV Y,#$07
  .voice:
        0FA6: F6 39 1F  MOV A,!$1F39+Y
        0FA9: F0 0E     BEQ .nextM
        0FAB: F6 A9 1F  MOV A,!$1FA9+Y
        0FAE: 10 09     BPL .nextM
        0FB0: 6D        PUSH Y
        0FB1: 28 1F     AND A,#$1F
        0FB3: 1C        ASL A
        0FB4: 5D        MOV X,A
        0FB5: 3F BD 0F  CALL !ModDispatch
        0FB8: EE        POP Y
  .nextM:
        0FB9: DC        DEC Y
        0FBA: 10 EA     BPL .voice
        0FBC: 6F        RET
ModDispatch:
        0FBD: 1F B9 13  JMP [!SynthModTable+X]
; Pitch table: 192 entries = one octave in 1/16 semitones, DSP pitch for
; notes 108-119 (C8-B8). Hi bytes at $0FC0, lo bytes at $1080.
; Entry 0 = $215B, entry 191 = $4278.
PitchTableHi:
        0FC0: db $21, $21, $21, $21, $21, $21, $22, $22, $22, $22, $22, $22, $22, $22, $23, $23
        0FD0: db $23, $23, $23, $23, $23, $23, $24, $24, $24, $24, $24, $24, $24, $25, $25, $25
        0FE0: db $25, $25, $25, $25, $25, $26, $26, $26, $26, $26, $26, $26, $27, $27, $27, $27
        0FF0: db $27, $27, $27, $28, $28, $28, $28, $28, $28, $28, $29, $29, $29, $29, $29, $29
        1000: db $2A, $2A, $2A, $2A, $2A, $2A, $2A, $2B, $2B, $2B, $2B, $2B, $2B, $2C, $2C, $2C
        1010: db $2C, $2C, $2C, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2E, $2E, $2E, $2E, $2E, $2F
        1020: db $2F, $2F, $2F, $2F, $2F, $30, $30, $30, $30, $30, $30, $31, $31, $31, $31, $31
        1030: db $31, $32, $32, $32, $32, $32, $33, $33, $33, $33, $33, $34, $34, $34, $34, $34
        1040: db $34, $35, $35, $35, $35, $35, $36, $36, $36, $36, $36, $37, $37, $37, $37, $37
        1050: db $38, $38, $38, $38, $38, $39, $39, $39, $39, $39, $3A, $3A, $3A, $3A, $3B, $3B
        1060: db $3B, $3B, $3B, $3C, $3C, $3C, $3C, $3C, $3D, $3D, $3D, $3D, $3E, $3E, $3E, $3E
        1070: db $3E, $3F, $3F, $3F, $3F, $40, $40, $40, $40, $41, $41, $41, $41, $41, $42, $42
PitchTableLo:
        1080: db $5B, $7A, $99, $B8, $D7, $F7, $16, $36, $55, $75, $95, $B5, $D5, $F5, $16, $36
        1090: db $57, $77, $98, $B9, $DA, $FC, $1D, $3E, $60, $82, $A3, $C5, $E7, $09, $2C, $4E
        10A0: db $71, $93, $B6, $D9, $FC, $1F, $43, $66, $8A, $AD, $D1, $F5, $19, $3D, $62, $86
        10B0: db $AB, $CF, $F4, $19, $3E, $64, $89, $AF, $D4, $FA, $20, $46, $6C, $93, $B9, $E0
        10C0: db $06, $2D, $54, $7C, $A3, $CA, $F2, $1A, $42, $6A, $92, $BA, $E3, $0B, $34, $5D
        10D0: db $86, $AF, $D9, $02, $2C, $56, $80, $AA, $D4, $FF, $29, $54, $7F, $AA, $D5, $00
        10E0: db $2C, $58, $83, $AF, $DC, $08, $34, $61, $8E, $BB, $E8, $15, $43, $70, $9E, $CC
        10F0: db $FA, $28, $57, $85, $B4, $E3, $12, $41, $71, $A1, $D0, $00, $30, $61, $91, $C2
        1100: db $F3, $24, $55, $86, $B8, $EA, $1C, $4E, $80, $B2, $E5, $18, $4B, $7E, $B2, $E5
        1110: db $19, $4D, $81, $B5, $EA, $1E, $53, $88, $BE, $F3, $29, $5F, $95, $CB, $01, $38
        1120: db $6F, $A6, $DD, $14, $4C, $84, $BC, $F4, $2D, $65, $9E, $D7, $10, $4A, $84, $BD
        1130: db $F7, $32, $6C, $A7, $E2, $1D, $58, $94, $D0, $0C, $48, $84, $C1, $FE, $3B, $78
; $1140-$1192: unreferenced bytes (random-looking padding). NOTE: the pitch
; interpolation reads PitchTableLo[idx+1], so for idx 191 it reads $1140 ($3E)
; instead of a real entry 192 -> wrong step for B + 15/16 semitone.
Unused1140:
        1140: db $3E, $26, $7C, $41, $7D, $61, $BF, $B8, $33, $F6, $37, $25, $40, $FE, $9C, $29
        1150: db $3F, $AA, $03, $2A, $FB, $06, $A8, $73, $31, $F8, $62, $82, $B9, $6A, $50, $B6
        1160: db $B2, $21, $26, $63, $09, $1C, $9F, $17, $56, $8C, $33, $A1, $59, $11, $A2, $77
        1170: db $EC, $EF, $39, $BD, $FE, $BE, $94, $B8, $07, $0F, $93, $B2, $DC, $3C, $50, $9D
        1180: db $9C, $43, $A6, $57, $C0, $DA, $60, $E1, $80, $12, $B7, $3C, $95, $BF, $1E, $E4
        1190: db $55, $98, $EC
; SilentBlock: one silent BRR block (end+loop)
SilentBlock:
        1193: db $03, $00, $00, $00, $00, $00, $00, $00, $00
; DefaultSample: header (fine 1, semitone 0, loop 0); its 'BRR' is the bytes at
; $11A0 onward (tables, no end flag) - unloaded samples play garbage.
DefaultSample:
        119C: db $01, $00, $00, $00, $00, $00, $00, $00, $00
; Voice wave buffers (36 bytes = 4 BRR blocks each): $2059,$207D,$20A1,$20C5,$20E9,$210D,$2131,$2155
VoiceBufHi:
        11A5: db $20, $20, $20, $20, $20, $21, $21, $21
VoiceBufLo:
        11AD: db $59, $7D, $A1, $C5, $E9, $0D, $31, $55
; BitMask: voice n -> 1<<n
BitMask:
        11B5: db $01, $02, $04, $08, $10, $20, $40, $80
; GlobalPWMWave: 4 BRR blocks modulated by GlobalFX (synth wave 28)
GlobalPWMWave:
        11BD: db $B0, $77, $77, $77, $77, $77, $77, $77, $77, $B0, $77, $77, $77, $77, $77, $74
        11CD: db $88, $88, $B0, $77, $77, $77, $77, $77, $77, $77, $77, $B3, $77, $77, $77, $77
        11DD: db $77, $77, $77, $77
; NoiseBlocks: 8 x 9-byte BRR blocks rewritten by NoiseWaveUpdate (synth waves 16-23)
NoiseBlocks:
        11E1: db $B0, $6B, $9F, $FF, $53, $1C, $3C, $0C, $52, $B3, $01, $DE, $B2, $30, $0B, $1E
        11F1: db $18, $A5, $84, $6B, $9F, $FF, $53, $1C, $3C, $0C, $52, $87, $01, $DE, $B2, $30
        1201: db $0B, $1E, $18, $A5, $B3, $6B, $9F, $FF, $53, $94, $60, $00, $AC, $97, $6B, $9F
        1211: db $FF, $53, $1C, $3C, $0C, $52, $CF, $6B, $9F, $FF, $53, $1C, $3C, $0C, $52, $D7
        1221: db $6B, $9F, $FF, $53, $1C, $3C, $0C, $52
; SynthHeaderTable: BRR header per amplitude select h
SynthHeaderTable:
        1229: db $B0, $84, $58, $5C
; WaveData: 4-bit waveform data (squares, saws, triangles, steps) used by the synth waves
WaveData:
        122D: db $22, $22, $88, $88, $22, $22, $28, $88, $88, $22, $22, $22, $88, $88, $88, $22
        123D: db $77, $77, $7D, $DD, $DD, $DD, $77, $77, $77, $77, $DD, $DD, $DD, $DD, $77, $77
        124D: db $88, $77, $11, $11, $22, $22, $33, $33, $88, $88, $99, $99, $AA, $AA, $BB, $BB
        125D: db $44, $44, $55, $55, $66, $66, $77, $77, $CC, $CC, $DD, $DD, $EE, $EE, $FF, $FF
        126D: db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77
        127D: db $88, $77, $88, $77, $88, $88, $88, $88, $77, $88, $77, $88, $77, $77, $77, $77
        128D: db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
        129D: db $00, $11, $22, $33, $44, $55, $66, $77, $77, $66, $55, $44, $33, $22, $11, $00
        12AD: db $FE, $DC, $BA, $98, $89, $AB, $CD, $EF, $01, $23, $45, $67, $76, $54, $32, $10
        12BD: db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88
        12CD: db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77
        12DD: db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $00, $11, $22, $33
        12ED: db $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $00, $00, $11, $11
        12FD: db $22, $22, $33, $33, $44, $44, $55, $55, $66, $66, $77, $77, $88, $88, $99, $99
        130D: db $AA, $AA, $BB, $BB, $CC, $CC, $DD, $DD, $EE, $EE, $FF, $FF
; SynthTuneTable[32]: semitone offset per synth wave ($24 = 4-block, $18 = 1-block)
SynthTuneTable:
        1319: db $24, $18, $24, $18, $24, $18, $24, $18, $24, $18, $24, $24, $24, $18, $00, $00
        1329: db $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $00, $00, $00
; SynthSourceTable[32]: source address per synth wave
SynthSourceTable:
        1339: dw $12BD    ; 00 -> wave 0 data
        133B: dw $12C5    ; 01 -> wave 1 data
        133D: dw $12C5    ; 02 -> wave 2 data
        133F: dw $12C9    ; 03 -> wave 3 data
        1341: dw $12C9    ; 04 -> wave 4 data
        1343: dw $12CB    ; 05 -> wave 5 data
        1345: dw $12F9    ; 06 -> wave 6 data
        1347: dw $12E9    ; 07 -> wave 7 data
        1349: dw $128D    ; 08 -> wave 8 data
        134B: dw $12AD    ; 09 -> wave 9 data
        134D: dw $122D    ; 0A -> wave 10 data
        134F: dw $124D    ; 0B -> wave 11 data
        1351: dw $12A1    ; 0C -> wave 12 data
        1353: dw $126D    ; 0D -> wave 13 data
        1355: dw $0000    ; 0E -> undefined
        1357: dw $0000    ; 0F -> undefined
        1359: dw $1217    ; 10 -> wave 16 data
        135B: dw $11E1    ; 11 -> wave 17 data
        135D: dw $11EA    ; 12 -> wave 18 data
        135F: dw $11F3    ; 13 -> wave 19 data
        1361: dw $11FC    ; 14 -> wave 20 data
        1363: dw $1205    ; 15 -> wave 21 data
        1365: dw $120E    ; 16 -> wave 22 data
        1367: dw $1220    ; 17 -> wave 23 data
        1369: dw $12BD    ; 18 -> wave 24 data
        136B: dw $11E2    ; 19 -> wave 25 data
        136D: dw $12F9    ; 1A -> wave 26 data
        136F: dw $11E2    ; 1B -> wave 27 data
        1371: dw $11BD    ; 1C -> wave 28 data
        1373: dw $0000    ; 1D -> undefined
        1375: dw $0000    ; 1E -> undefined
        1377: dw $0000    ; 1F -> undefined
; SynthInitTable[32]: init routine per synth wave (NullHandler = undefined wave)
SynthInitTable:
        1379: dw $0BBE    ; 00 -> wave 0: Wave_4Block
        137B: dw $0B94    ; 01 -> wave 1: Wave_1Block
        137D: dw $0BBE    ; 02 -> wave 2: Wave_4Block
        137F: dw $0B94    ; 03 -> wave 3: Wave_1Block
        1381: dw $0BBE    ; 04 -> wave 4: Wave_4Block
        1383: dw $0B94    ; 05 -> wave 5: Wave_1Block
        1385: dw $0BBE    ; 06 -> wave 6: Wave_4Block
        1387: dw $0B94    ; 07 -> wave 7: Wave_1Block
        1389: dw $0BBE    ; 08 -> wave 8: Wave_4Block
        138B: dw $0B94    ; 09 -> wave 9: Wave_1Block
        138D: dw $0BBE    ; 0A -> wave 10: Wave_4Block
        138F: dw $0BBE    ; 0B -> wave 11: Wave_4Block
        1391: dw $0BBE    ; 0C -> wave 12: Wave_4Block
        1393: dw $0BBE    ; 0D -> wave 13: Wave_4Block
        1395: dw $04AA    ; 0E -> wave 14: NullHandler
        1397: dw $04AA    ; 0F -> wave 15: NullHandler
        1399: dw $0B60    ; 10 -> wave 16: Wave_Direct
        139B: dw $0B60    ; 11 -> wave 17: Wave_Direct
        139D: dw $0B60    ; 12 -> wave 18: Wave_Direct
        139F: dw $0B60    ; 13 -> wave 19: Wave_Direct
        13A1: dw $0B60    ; 14 -> wave 20: Wave_Direct
        13A3: dw $0B60    ; 15 -> wave 21: Wave_Direct
        13A5: dw $0B60    ; 16 -> wave 22: Wave_Direct
        13A7: dw $0B60    ; 17 -> wave 23: Wave_Direct
        13A9: dw $0C24    ; 18 -> wave 24: Wave_PWM
        13AB: dw $0BBE    ; 19 -> wave 25: Wave_4Block
        13AD: dw $0BA5    ; 1A -> wave 26: Wave_NoisySquare
        13AF: dw $0BA5    ; 1B -> wave 27: Wave_NoisySquare
        13B1: dw $0B60    ; 1C -> wave 28: Wave_Direct
        13B3: dw $04AA    ; 1D -> wave 29: NullHandler
        13B5: dw $04AA    ; 1E -> wave 30: NullHandler
        13B7: dw $04AA    ; 1F -> wave 31: NullHandler
; SynthModTable[32]: per-frame modulator per synth wave (24 = PWM, 26/27 = noisy square)
SynthModTable:
        13B9: dw $04AA    ; 00 -> wave 0: NullHandler
        13BB: dw $04AA    ; 01 -> wave 1: NullHandler
        13BD: dw $04AA    ; 02 -> wave 2: NullHandler
        13BF: dw $04AA    ; 03 -> wave 3: NullHandler
        13C1: dw $04AA    ; 04 -> wave 4: NullHandler
        13C3: dw $04AA    ; 05 -> wave 5: NullHandler
        13C5: dw $04AA    ; 06 -> wave 6: NullHandler
        13C7: dw $04AA    ; 07 -> wave 7: NullHandler
        13C9: dw $04AA    ; 08 -> wave 8: NullHandler
        13CB: dw $04AA    ; 09 -> wave 9: NullHandler
        13CD: dw $04AA    ; 0A -> wave 10: NullHandler
        13CF: dw $04AA    ; 0B -> wave 11: NullHandler
        13D1: dw $04AA    ; 0C -> wave 12: NullHandler
        13D3: dw $04AA    ; 0D -> wave 13: NullHandler
        13D5: dw $04AA    ; 0E -> wave 14: NullHandler
        13D7: dw $04AA    ; 0F -> wave 15: NullHandler
        13D9: dw $04AA    ; 10 -> wave 16: NullHandler
        13DB: dw $04AA    ; 11 -> wave 17: NullHandler
        13DD: dw $04AA    ; 12 -> wave 18: NullHandler
        13DF: dw $04AA    ; 13 -> wave 19: NullHandler
        13E1: dw $04AA    ; 14 -> wave 20: NullHandler
        13E3: dw $04AA    ; 15 -> wave 21: NullHandler
        13E5: dw $04AA    ; 16 -> wave 22: NullHandler
        13E7: dw $04AA    ; 17 -> wave 23: NullHandler
        13E9: dw $07FB    ; 18 -> wave 24: Mod_PWM
        13EB: dw $04AA    ; 19 -> wave 25: NullHandler
        13ED: dw $0885    ; 1A -> wave 26: Mod_Noise
        13EF: dw $0885    ; 1B -> wave 27: Mod_Noise
        13F1: dw $04AA    ; 1C -> wave 28: NullHandler
        13F3: dw $04AA    ; 1D -> wave 29: NullHandler
        13F5: dw $04AA    ; 1E -> wave 30: NullHandler
        13F7: dw $04AA    ; 1F -> wave 31: NullHandler
