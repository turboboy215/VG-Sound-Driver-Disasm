;==============================================================================
; SLICK sound driver - EARLIEST VERSION (Bitmasters, 1991)
; as used in Home Alone (SNES), taken from "01 - Main Theme.spc"
; (SPC PC = $0904, inside NoteOn).  Surviving driver code $0322-$1096.
;
; The reset code and everything below $0322 was wiped by the driver's own
; RAM-clear loop (see ClearLoop), so the entry point is not in the snapshot.
; No version string.  Labels follow SLICK_Aero_Circus_labeled.s /
; SLICK_EarthwormJim_labeled.s where a routine has a counterpart; see
; SLICK_Version_Comparison.md for the three-way comparison.
;
; Syntax identical to the other two listings (SPCdas conventions).
; Channel records are 9 bytes in direct page ($22 + 9*n, SFX pseudo channel
; $6a); "Ch_xxx+x" operands are fields of the record whose address is in X.
;
; Every byte of $0322-$1096 is accounted for: a recursive trace from $0324
; reaches all code except two dead JMPs ($038c, $0e36).  Data inside the
; image: PatternTable ($062f), InstTable ($06b6), voice tables ($07b6),
; BuiltinSongTable ($0991), two pitch tables ($0b6e-$0d1d).
;
; Memory outside the image used by the driver:
;   $0200         KeyOnHistory (write-only)
;   $1400-        song uploaded for I/O $04
;   $2800-        DIR (page $28), samples
;   $7000-$8fff   echo buffer (ESA $70, EDL 4 = 8 KB)
;==============================================================================

; ---- I/O registers
TEST             = $f0
CONTROL          = $f1
DSPADDR          = $f2
DSPDATA          = $f3
APUIO0           = $f4
APUIO1           = $f5
APUIO2           = $f6
APUIO3           = $f7
T0DIV            = $fa
T1DIV            = $fb
T2DIV            = $fc
T0OUT            = $fd
T1OUT            = $fe
T2OUT            = $ff

; ---- RAM ([n] = number of entries; tracks = 22, voices = 8)
TickStep         = $000f   ; [1] T0OUT*2 = amount subtracted from channel timers
SeqPtr           = $0010   ; [2] sequence pointer of current channel
ChRec            = $0012   ; [1] DP address of current channel record ($22+9n, SFX: $6a)
ChBit            = $0013   ; [1] bit of current channel
ChIndex          = $0016   ; [1] current channel number
SongFlags        = $0017   ; [1] flags byte of the song header
ChFlags          = $0018   ; [1] flags of current channel
ChActive         = $0019   ; [1] channels being sequenced (bit per channel)
VoiceIdx         = $001a   ; [1] voice of the current note / gate loop DSP base
VoiceBit         = $001b   ; [1] bit of that voice
NonShadow        = $001c   ; [1] NON shadow
EonShadow        = $001d   ; [1] EON shadow
PmonShadow       = $001e   ; [1] PMON shadow
ChAllocated      = $001f   ; [1] allocated channels (bit per channel)
ChRecords        = $0022   ; [72] 8 channel records x 9 bytes
SfxRecord        = $006a   ; [9] pseudo channel record used by sound effects
NoteNum          = $0073   ; [1] note being started
NoteVel          = $0074   ; [1] velocity nibble -> 8..15 / song start: volume byte
VolTmpL          = $0075   ; [1]
VolTmpR          = $0076   ; [1]
InstFlagsTmp     = $0078   ; [1] flags of the instrument being started
VGateHi          = $0079   ; [8] note length remaining, hi (ticks)
VGateLo          = $0081   ; [8] note length remaining, lo
VoiceFlags       = $0089   ; [8] channel flags of the note on this voice (0 = no gate)
SfxSweep         = $0091   ; [1] SFX pitch sweep: 3 up, 4 down, 5 = reset DSP
FadeActive       = $0092   ; [1] master fade running
FadeLevel        = $0093   ; [1] master volume during fade
FadeCount        = $0094   ; [1]
FadeRate         = $0095   ; [1] timer-1 ticks per fade step
SfxPitch         = $0096   ; [2] current P(L)/P(H) of voice 7
SfxSweepRate     = $0098   ; [1]
SfxVolume        = $0099   ; [1]
SfxDspBits       = $009a   ; [1] extra EON/NON bits for the SFX voice
SfxEndMode       = $009b   ; [1] 0: SFX ends on ENDX, else on ENVX = 0
SfxPriority      = $009c   ; [1]
SfxLastCmd       = $009d   ; [2] saved SFX params for repeats
SfxFlags         = $009f   ; [1] bit0 playing, bit1 repeat, bit2 no volume halving, bit3 ?
SfxRepeatCnt     = $00a0   ; [1]
SfxRepeatVol     = $00a2   ; [1] halved on every repeat
SfxRepeatRate    = $00a6   ; [1]
UploadParam      = $00a7   ; [2] second word of I/O $05 (unused)
VolSelect        = $00a9   ; [1] I/O $06: selects the 2nd volume byte of each track
KeyOnHistory     = $0200   ; [1] OR of all keyed-on voice bits (write-only)

; =============================================================================
; End of the (lost) reset code.  Everything from the start of the clear
; pointer up to $0323 is zero in the snapshot: the loop's own store
; instruction (presumably "mov ($00)+y,a" = d7 00 at $0322) erased itself,
; after which the loop only counts the pointer up to $0500 and falls through.
; The driver entry point and the code before $0322 cannot be recovered
; from this SPC (driver probably loaded at $0200).
; =============================================================================
ClearLoop:
0322: 00        nop                          ; (was the store that cleared RAM)
0323: 00        nop
0324: 3a 00     incw   $00
0326: 78 05 01  cmp    $01,#$05              ; until pointer = $0500
0329: d0 f7     bne    ClearLoop

Init:
032b: cd 5f     mov    x,#$5f                ; (X unused)
032d: 3f 61 05  call   InitDSP               ; DSP + timers
0330: 8f 00 0f  mov    TickStep,#$00

; =============================================================================
; MainLoop - polls T0OUT (music, T0DIV from the song header), T1OUT (12.5 ms:
; sound effects / fade) and the CPU ports.  No event queue.
; =============================================================================
MainLoop:
0333: e4 fd     mov    a,T0OUT               ; timer 0 tick -> music
0335: d0 58     bne    MusicTick
0337: e4 fe     mov    a,T1OUT               ; timer 1 tick -> SFX / fade
0339: f0 09     beq    L0344
033b: 3f 96 0f  call   SfxRepeatTick
033e: 3f 1e 0d  call   SfxTick
0341: 5f 33 03  jmp    MainLoop

L0344:
0344: e4 f5     mov    a,APUIO1              ; APUIO1 = $ab : command
0346: 68 ab     cmp    a,#$ab
0348: d0 1b     bne    L0365
034a: e4 f4     mov    a,APUIO0              ; APUIO0 = command
034c: c4 00     mov    $00,a
034e: fa f6 02  mov    ($02),(APUIO2)        ; APUIO2/3 = parameters
0351: fa f7 03  mov    ($03),(APUIO3)
0354: 8f 33 f1  mov    CONTROL,#$33          ; CONTROL: clear input ports, timers on
0357: 00        nop
0358: 00        nop
0359: 8f ab f4  mov    APUIO0,#$ab           ; acknowledge
035c: 8f 00 f5  mov    APUIO1,#$00
035f: 3f be 09  call   IoDispatch            ; run command
0362: 5f 33 03  jmp    MainLoop

L0365:
0365: 68 ba     cmp    a,#$ba                ; APUIO1 = $ba : command, wait for $cc before running it
0367: d0 ca     bne    MainLoop
0369: e4 f4     mov    a,APUIO0
036b: c4 00     mov    $00,a
036d: fa f6 02  mov    ($02),(APUIO2)
0370: fa f7 03  mov    ($03),(APUIO3)
0373: 8f 33 f1  mov    CONTROL,#$33
0376: 00        nop
0377: 00        nop
0378: 8f ba f4  mov    APUIO0,#$ba
037b: 8f 00 f5  mov    APUIO1,#$00

L037E:
037e: 78 cc f5  cmp    APUIO1,#$cc
0381: d0 fb     bne    L037E
0383: 8f 00 f4  mov    APUIO0,#$00
0386: 3f be 09  call   IoDispatch
0389: 5f 33 03  jmp    MainLoop

DeadJmp:
038c: 5f 33 03  jmp    MainLoop

MusicTick:
038f: 1c        asl    a                     ; TickStep = ticks * 2
0390: c4 0f     mov    TickStep,a
0392: 8f 00 f4  mov    APUIO0,#$00
0395: 8f 01 1b  mov    VoiceBit,#$01

; --- gate countdown for voices 0-7 (1 per timer event) ---------------
0398: cd 00     mov    x,#$00
039a: d8 00     mov    $00,x
039c: 8d 08     mov    y,#$08
039e: 8f 00 1a  mov    VoiceIdx,#$00
.gateLoop:
03a1: f4 89     mov    a,VoiceFlags+x        ; VoiceFlags 0 : no gate running
03a3: f0 34     beq    L03D9
03a5: 28 02     and    a,#$02                ; bit1 : sustain (no countdown)
03a7: d0 30     bne    L03D9
03a9: f4 81     mov    a,VGateLo+x
03ab: c4 02     mov    $02,a
03ad: f4 79     mov    a,VGateHi+x
03af: c4 03     mov    $03,a
03b1: 04 02     or     a,$02
03b3: f0 1c     beq    L03D1
03b5: 1a 02     decw   $02                   ; gate - 1
03b7: d0 18     bne    L03D1
03b9: 4d        push   x                     ; expired: ADSR1 = 0, GAIN = $b7
03ba: e4 1a     mov    a,VoiceIdx
03bc: 60        clrc
03bd: 88 05     adc    a,#$05
03bf: 5d        mov    x,a
03c0: d8 f2     mov    DSPADDR,x
03c2: 8f 00 f3  mov    DSPDATA,#$00
03c5: 3d        inc    x
03c6: 3d        inc    x
03c7: d8 f2     mov    DSPADDR,x
03c9: 8f b7 f3  mov    DSPDATA,#$b7
03cc: ce        pop    x
03cd: e8 00     mov    a,#$00
03cf: d4 89     mov    VoiceFlags+x,a

L03D1:
03d1: e4 02     mov    a,$02
03d3: d4 81     mov    VGateLo+x,a
03d5: e4 03     mov    a,$03
03d7: d4 79     mov    VGateHi+x,a

L03D9:
03d9: 0b 1b     asl    VoiceBit
03db: 60        clrc
03dc: 98 10 1a  adc    VoiceIdx,#$10
03df: 3d        inc    x
03e0: dc        dec    y
03e1: d0 be     bne    .gateLoop

; --- channels 0-7: timer -= TickStep, run events when <= 0 ------------
ChannelLoop:
03e3: 8f 00 16  mov    ChIndex,#$00
03e6: 8f 22 12  mov    ChRec,#$22            ; first record at $22
03e9: 8f 01 13  mov    ChBit,#$01
03ec: 8f 00 1a  mov    VoiceIdx,#$00

L03EF:
03ef: f8 12     mov    x,ChRec
03f1: e4 13     mov    a,ChBit
03f3: 24 19     and    a,ChActive
03f5: f0 1a     beq    .nextChannel
03f7: 80        setc
03f8: f4 00     mov    a,Ch_TimerLo+x
03fa: a4 0f     sbc    a,TickStep
03fc: d4 00     mov    Ch_TimerLo+x,a
03fe: f4 01     mov    a,Ch_TimerHi+x
0400: a8 00     sbc    a,#$00
0402: d4 01     mov    Ch_TimerHi+x,a
0404: f4 01     mov    a,Ch_TimerHi+x
0406: 30 04     bmi    L040C
0408: 14 00     or     a,Ch_TimerLo+x
040a: d0 05     bne    .nextChannel

L040C:
040c: f8 12     mov    x,ChRec
040e: 3f 23 04  call   ProcessChannelEvents
.nextChannel:
0411: 0b 13     asl    ChBit
0413: b0 0b     bcs    L0420
0415: 98 09 12  adc    ChRec,#$09            ; next record (+9)
0418: 60        clrc
0419: ab 16     inc    ChIndex
041b: ab 1a     inc    VoiceIdx
041d: 5f ef 03  jmp    L03EF

L0420:
0420: 5f 33 03  jmp    MainLoop

; =============================================================================
; ProcessChannelEvents - one event per call (the timer loop calls again
; while the timer is <= 0).  Events:
;   E3        end of channel
;   E5        sync: wait until every active channel sits on an E5,
;             then all continue (no delta follows)
;   E1 d      rest (delta only)
;   E4 p      continue at pattern p (PatternTable), then delta
;   other     note: nn vv [gate] delta
;             vv: low nibble velocity; high nibble = voice if ChFlags <> 0
;             gate only if ChFlags <> 0 (else voice = channel, no gate)
;   delta / gate: 1 byte, or 2 bytes if bit7 of the first (MIDI VLQ, max 14 bits)
; =============================================================================
ProcessChannelEvents:
0423: f8 12     mov    x,ChRec
0425: f4 02     mov    a,Ch_PtrLo+x
0427: c4 10     mov    SeqPtr,a
0429: f4 03     mov    a,Ch_PtrHi+x
042b: c4 11     mov    SeqPtr+1,a
042d: f4 06     mov    a,Ch_Flags+x          ; channel flags
042f: c4 18     mov    ChFlags,a
0431: f4 07     mov    a,Ch_Transp+x         ; channel transpose
0433: c4 0e     mov    $0e,a
0435: 8d 00     mov    y,#$00
0437: f7 10     mov    a,(SeqPtr)+y
0439: 68 e3     cmp    a,#$e3
043b: d0 0f     bne    L044C
043d: e4 13     mov    a,ChBit               ; E3: channel off
043f: 48 ff     eor    a,#$ff
0441: 2d        push   a
0442: 24 19     and    a,ChActive
0444: c4 19     mov    ChActive,a
0446: ae        pop    a
0447: 24 1f     and    a,ChAllocated
0449: c4 1f     mov    ChAllocated,a
044b: 6f        ret

L044C:
044c: 68 e5     cmp    a,#$e5
044e: f0 03     beq    .sync
0450: 5f ae 04  jmp    .otherCmds
.sync:
0453: e8 00     mov    a,#$00                ; E5: timer = 1, status bit0 = waiting
0455: d4 01     mov    Ch_TimerHi+x,a
0457: bc        inc    a
0458: d4 00     mov    Ch_TimerLo+x,a
045a: 14 08     or     a,Ch_Status+x
045c: d4 08     mov    Ch_Status+x,a
045e: 8f 22 00  mov    $00,#$22              ; all active channels waiting?
0461: 8f 01 02  mov    $02,#$01

L0464:
0464: f8 00     mov    x,$00
0466: e4 02     mov    a,$02
0468: 24 19     and    a,ChActive
046a: f0 06     beq    L0472
046c: f4 08     mov    a,Ch_Status+x
046e: 28 01     and    a,#$01
0470: f0 0a     beq    L047C

L0472:
0472: 0b 02     asl    $02
0474: b0 06     bcs    L047C
0476: 98 09 00  adc    $00,#$09
0479: 5f 64 04  jmp    L0464

L047C:
047c: e4 02     mov    a,$02                 ; no -> keep waiting (E5 is executed again next tick)
047e: d0 2d     bne    L04AD
0480: 8f 22 00  mov    $00,#$22              ; yes -> clear waiting, step every pointer past its E5, rerun the loop
0483: 8f 01 02  mov    $02,#$01

L0486:
0486: f8 00     mov    x,$00
0488: e4 02     mov    a,$02
048a: 24 19     and    a,ChActive
048c: f0 12     beq    L04A0
048e: e8 fe     mov    a,#$fe
0490: 34 08     and    a,Ch_Status+x
0492: d4 08     mov    Ch_Status+x,a
0494: f4 02     mov    a,Ch_PtrLo+x
0496: bc        inc    a
0497: d4 02     mov    Ch_PtrLo+x,a
0499: d0 05     bne    L04A0
049b: f4 03     mov    a,Ch_PtrHi+x
049d: bc        inc    a
049e: d4 03     mov    Ch_PtrHi+x,a

L04A0:
04a0: 0b 02     asl    $02
04a2: b0 06     bcs    L04AA
04a4: 98 09 00  adc    $00,#$09
04a7: 5f 86 04  jmp    L0486

L04AA:
04aa: 5f e3 03  jmp    ChannelLoop

L04AD:
04ad: 6f        ret
.otherCmds:
04ae: 68 e1     cmp    a,#$e1
04b0: d0 05     bne    .goto
04b2: 3a 10     incw   SeqPtr
04b4: 5f 2a 05  jmp    ReadDelta
.goto:
04b7: 68 e4     cmp    a,#$e4                ; E4 p : SeqPtr = PatternTable[p]
04b9: d0 13     bne    .note
04bb: 3a 10     incw   SeqPtr
04bd: f7 10     mov    a,(SeqPtr)+y
04bf: 1c        asl    a
04c0: fd        mov    y,a
04c1: f6 2f 06  mov    a,PatternTable+y
04c4: c4 10     mov    SeqPtr,a
04c6: f6 30 06  mov    a,PatternTable+1+y
04c9: c4 11     mov    SeqPtr+1,a
04cb: 5f 2a 05  jmp    ReadDelta
.note:
04ce: 2d        push   a
04cf: 3a 10     incw   SeqPtr
04d1: f7 10     mov    a,(SeqPtr)+y
04d3: 28 0f     and    a,#$0f                ; velocity nibble
04d5: c4 74     mov    NoteVel,a
04d7: eb 18     mov    y,ChFlags             ; ChFlags = 0 -> voice = channel, no gate
04d9: d0 03     bne    L04DE
04db: 5f 19 05  jmp    .noGate

L04DE:
04de: 8d 00     mov    y,#$00
04e0: f7 10     mov    a,(SeqPtr)+y          ; voice = high nibble
04e2: 5c        lsr    a
04e3: 5c        lsr    a
04e4: 5c        lsr    a
04e5: 5c        lsr    a
04e6: c4 1a     mov    VoiceIdx,a
04e8: 5d        mov    x,a
04e9: e4 18     mov    a,ChFlags             ; ChFlags bit2 : voice = channel anyway
04eb: 28 04     and    a,#$04
04ed: f0 05     beq    L04F4
04ef: e4 16     mov    a,ChIndex
04f1: c4 1a     mov    VoiceIdx,a
04f3: 5d        mov    x,a

L04F4:
04f4: e4 18     mov    a,ChFlags             ; VoiceFlags = ChFlags
04f6: d4 89     mov    VoiceFlags+x,a
04f8: 3a 10     incw   SeqPtr
04fa: f7 10     mov    a,(SeqPtr)+y          ; gate, 1 or 2 bytes
04fc: 30 09     bmi    L0507
04fe: d4 81     mov    VGateLo+x,a
0500: e8 00     mov    a,#$00
0502: d4 79     mov    VGateHi+x,a
0504: 5f 16 05  jmp    L0516

L0507:
0507: 28 7f     and    a,#$7f
0509: 5c        lsr    a
050a: d4 79     mov    VGateHi+x,a
050c: 3a 10     incw   SeqPtr
050e: f7 10     mov    a,(SeqPtr)+y
0510: 90 02     bcc    L0514
0512: 08 80     or     a,#$80

L0514:
0514: d4 81     mov    VGateLo+x,a

L0516:
0516: 5f 22 05  jmp    L0522
.noGate:
0519: e4 16     mov    a,ChIndex
051b: c4 1a     mov    VoiceIdx,a
051d: 5d        mov    x,a
051e: e8 00     mov    a,#$00
0520: d4 89     mov    VoiceFlags+x,a

L0522:
0522: ae        pop    a
0523: f8 1a     mov    x,VoiceIdx
0525: 3f c7 07  call   NoteOn                ; key the note on
0528: 3a 10     incw   SeqPtr

ReadDelta:
052a: f8 12     mov    x,ChRec
052c: 8d 00     mov    y,#$00
052e: f7 10     mov    a,(SeqPtr)+y          ; 1 or 2 byte delta, added to the 16-bit channel timer
0530: 10 19     bpl    L054B
0532: 3a 10     incw   SeqPtr
0534: 28 7f     and    a,#$7f
0536: 5c        lsr    a
0537: 2d        push   a
0538: f7 10     mov    a,(SeqPtr)+y
053a: 90 02     bcc    L053E
053c: 08 80     or     a,#$80

L053E:
053e: 60        clrc
053f: 94 00     adc    a,Ch_TimerLo+x
0541: d4 00     mov    Ch_TimerLo+x,a
0543: ae        pop    a
0544: 94 01     adc    a,Ch_TimerHi+x
0546: d4 01     mov    Ch_TimerHi+x,a
0548: 5f 56 05  jmp    L0556

L054B:
054b: 60        clrc
054c: 94 00     adc    a,Ch_TimerLo+x
054e: d4 00     mov    Ch_TimerLo+x,a
0550: e8 00     mov    a,#$00
0552: 94 01     adc    a,Ch_TimerHi+x
0554: d4 01     mov    Ch_TimerHi+x,a

L0556:
0556: 3a 10     incw   SeqPtr
0558: e4 10     mov    a,SeqPtr
055a: d4 02     mov    Ch_PtrLo+x,a
055c: e4 11     mov    a,SeqPtr+1
055e: d4 03     mov    Ch_PtrHi+x,a
0560: 6f        ret

InitDSP:
0561: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
0564: 8f f8 f3  mov    DSPDATA,#$f8          ; FLG = $f8 (reset, mute, echo off)
0567: 8f 4d f2  mov    DSPADDR,#$4d          ; EON = 0
056a: 8f 00 f3  mov    DSPDATA,#$00
056d: 8f 00 00  mov    $00,#$00
0570: 8d 08     mov    y,#$08                ; VOL L/R of all voices = 0

L0572:
0572: f8 00     mov    x,$00
0574: d8 f2     mov    DSPADDR,x
0576: 8f 00 f3  mov    DSPDATA,#$00
0579: 3d        inc    x
057a: d8 f2     mov    DSPADDR,x
057c: 8f 00 f3  mov    DSPDATA,#$00
057f: 60        clrc
0580: 98 10 00  adc    $00,#$10
0583: dc        dec    y
0584: d0 ec     bne    L0572
0586: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
0589: 8f 18 f3  mov    DSPDATA,#$18          ; FLG = $18 (unmute, echo writes on, noise clock $18)
058c: 8f 6d f2  mov    DSPADDR,#$6d          ; ESA
058f: 8f 70 f3  mov    DSPDATA,#$70          ; ESA = $70
0592: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
0595: 8f 00 f3  mov    DSPDATA,#$00
0598: 8f 2d f2  mov    DSPADDR,#$2d          ; PMON
059b: 8f 00 f3  mov    DSPDATA,#$00
059e: 8f 5d f2  mov    DSPADDR,#$5d          ; DIR
05a1: 8f 28 f3  mov    DSPDATA,#$28          ; DIR = $28 ($2800)
05a4: e8 0f     mov    a,#$0f                ; FIR = $7f,0,0,0,0,0,0,0
05a6: c4 f2     mov    DSPADDR,a
05a8: 8f 7f f3  mov    DSPDATA,#$7f
05ab: 60        clrc
05ac: 88 10     adc    a,#$10
05ae: c4 f2     mov    DSPADDR,a
05b0: 8f 00 f3  mov    DSPDATA,#$00
05b3: 60        clrc
05b4: 88 10     adc    a,#$10
05b6: c4 f2     mov    DSPADDR,a
05b8: 8f 00 f3  mov    DSPDATA,#$00
05bb: 60        clrc
05bc: 88 10     adc    a,#$10
05be: c4 f2     mov    DSPADDR,a
05c0: 8f 00 f3  mov    DSPDATA,#$00
05c3: 60        clrc
05c4: 88 10     adc    a,#$10
05c6: c4 f2     mov    DSPADDR,a
05c8: 8f 00 f3  mov    DSPDATA,#$00
05cb: 60        clrc
05cc: 88 10     adc    a,#$10
05ce: c4 f2     mov    DSPADDR,a
05d0: 8f 00 f3  mov    DSPDATA,#$00
05d3: 60        clrc
05d4: 88 10     adc    a,#$10
05d6: c4 f2     mov    DSPADDR,a
05d8: 8f 00 f3  mov    DSPDATA,#$00
05db: 60        clrc
05dc: 88 10     adc    a,#$10
05de: c4 f2     mov    DSPADDR,a
05e0: 8f 00 f3  mov    DSPDATA,#$00
05e3: 8f 7d f2  mov    DSPADDR,#$7d          ; EDL
05e6: 8f 04 f3  mov    DSPDATA,#$04          ; EDL = 4
05e9: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
05ec: 8f 20 f3  mov    DSPDATA,#$20          ; EFB = $20
05ef: 8f 42 fa  mov    T0DIV,#$42            ; T0DIV = $42 (8.25 ms) - replaced by the song header value
05f2: 8f 03 f1  mov    CONTROL,#$03
05f5: 8f 42 fa  mov    T0DIV,#$42
05f8: 8f 64 fb  mov    T1DIV,#$64            ; T1DIV = $64 (12.5 ms)
05fb: cd 00     mov    x,#$00                ; MVOL / EVOL = 0
05fd: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOLL
0600: d8 f3     mov    DSPDATA,x
0602: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOLR
0605: d8 f3     mov    DSPDATA,x
0607: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
060a: d8 f3     mov    DSPDATA,x
060c: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
060f: d8 f3     mov    DSPDATA,x
0611: e4 fd     mov    a,T0OUT
0613: e4 fe     mov    a,T1OUT
0615: 6f        ret

; SetMasterVolume - MVOL = $7f, EVOL = $3f
SetMasterVolume:
0616: cd 7f     mov    x,#$7f
0618: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOLL
061b: d8 f3     mov    DSPDATA,x
061d: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOLR
0620: d8 f3     mov    DSPDATA,x
0622: cd 3f     mov    x,#$3f
0624: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
0627: d8 f3     mov    DSPDATA,x
0629: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
062c: d8 f3     mov    DSPDATA,x
062e: 6f        ret

; -----------------------------------------------------------------------------
; PatternTable - 16 pattern pointers, filled by I/O $04 (runtime data;
; snapshot values).  Linear decoding shows "call $0514 / or a,$16a1+x ...".
; -----------------------------------------------------------------------------
PatternTable:
062f: dw    $143f,$1505,$16a1,$1921,$2900,$500c,$5e15,$353c ; snapshot values (runtime data)
063f: dw    $5306,$8481,$1a37,$8c3a,$2736,$8c42,$ffff,$ffff

; =============================================================================
; StartChannel - A = pattern, X = instrument, Y = unused header byte,
;  $74 = volume byte, $18 = flags, $0e = transpose.  Takes the lowest free
;  channel (ChAllocated) - there is no priority or stealing.
; =============================================================================
StartChannel:
064f: 4d        push   x
0650: 6d        push   y
0651: cd 7f     mov    x,#$7f                ; MVOL $7f / EVOL $3f (inline copy of SetMasterVolume)
0653: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOLL
0656: d8 f3     mov    DSPDATA,x
0658: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOLR
065b: d8 f3     mov    DSPDATA,x
065d: cd 3f     mov    x,#$3f
065f: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
0662: d8 f3     mov    DSPDATA,x
0664: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
0667: d8 f3     mov    DSPDATA,x
0669: 1c        asl    a
066a: 5d        mov    x,a
066b: f5 2f 06  mov    a,PatternTable+x      ; pattern pointer
066e: c4 10     mov    SeqPtr,a
0670: f5 30 06  mov    a,PatternTable+1+x
0673: c4 11     mov    SeqPtr+1,a
0675: e4 1f     mov    a,ChAllocated         ; find a free channel
0677: 8f 01 1b  mov    VoiceBit,#$01
067a: cd 00     mov    x,#$00

L067C:
067c: 5c        lsr    a
067d: 90 07     bcc    L0686
067f: 0b 1b     asl    VoiceBit
0681: 3d        inc    x
0682: c8 08     cmp    x,#$08
0684: d0 f6     bne    L067C

L0686:
0686: c8 08     cmp    x,#$08
0688: f0 2b     beq    .full
068a: 09 1b 1f  or     (ChAllocated),(VoiceBit)
068d: 09 1b 19  or     (ChActive),(VoiceBit)
0690: 7d        mov    a,x
0691: fd        mov    y,a
0692: e8 09     mov    a,#$09
0694: cf        mul    ya
0695: 60        clrc
0696: 88 22     adc    a,#$22
0698: 5d        mov    x,a
0699: c4 12     mov    ChRec,a
069b: ae        pop    a                     ; drop Y, keep X (instrument)
069c: ae        pop    a
069d: d4 04     mov    Ch_Instr+x,a
069f: e8 00     mov    a,#$00
06a1: d4 00     mov    Ch_TimerLo+x,a
06a3: d4 01     mov    Ch_TimerHi+x,a
06a5: e4 18     mov    a,ChFlags
06a7: d4 06     mov    Ch_Flags+x,a
06a9: e4 0e     mov    a,$0e
06ab: d4 07     mov    Ch_Transp+x,a
06ad: e4 74     mov    a,NoteVel
06af: d4 05     mov    Ch_Volume+x,a
06b1: 3f 2a 05  call   ReadDelta
06b4: 6f        ret
.full:
06b5: 6f        ret

; -----------------------------------------------------------------------------
; InstTable - 32 instruments x 8 bytes, part of the driver image:
;   0 SRCN (bit7: percussion hack at $0908)  1 ADSR1/GAIN  2 ADSR2
;   3 flags: b0 echo, b1 PMON, b2 ADSR, b3 noise  4 transpose
;   5 ($7f, unused)  6 pitch table 0/1  7 (unused)
; -----------------------------------------------------------------------------
InstTable:
06b6: db    $01,$0f,$ec,$05,$f4,$7f,$00,$00  ; instrument $00
06be: db    $02,$4d,$b0,$05,$f4,$7f,$00,$00  ; instrument $01
06c6: db    $00,$7f,$7f,$01,$00,$7f,$01,$00  ; instrument $02
06ce: db    $04,$de,$de,$01,$f4,$7f,$00,$00  ; instrument $03
06d6: db    $05,$5f,$33,$05,$0c,$7f,$01,$00  ; instrument $04
06de: db    $00,$0f,$ed,$05,$00,$7f,$01,$00  ; instrument $05
06e6: db    $06,$4d,$b0,$05,$0c,$7f,$01,$00  ; instrument $06
06ee: db    $88,$7f,$7f,$01,$00,$7f,$01,$00  ; instrument $07
06f6: db    $07,$0e,$d0,$05,$0c,$7f,$01,$00  ; instrument $08
06fe: db    $0c,$4e,$90,$05,$0c,$7f,$01,$00  ; instrument $09
0706: db    $0d,$0f,$ec,$04,$f4,$7f,$00,$00  ; instrument $0a
070e: db    $0e,$1e,$d1,$05,$0c,$7f,$01,$00  ; instrument $0b
0716: db    $0f,$0f,$ec,$05,$f4,$7f,$00,$00  ; instrument $0c
071e: db    $0d,$3f,$b0,$05,$f4,$7f,$00,$00  ; instrument $0d
0726: db    $04,$3f,$b0,$05,$f4,$7f,$00,$00  ; instrument $0e
072e: db    $10,$4f,$70,$05,$f4,$7f,$00,$00  ; instrument $0f
0736: db    $11,$0f,$eb,$05,$f4,$7f,$00,$00  ; instrument $10
073e: db    $12,$19,$cc,$05,$f4,$7f,$00,$00  ; instrument $11
0746: db    $0e,$4f,$b0,$05,$0c,$7f,$01,$00  ; instrument $12
074e: db    $07,$4f,$b0,$05,$0c,$7f,$01,$00  ; instrument $13
0756: db    $13,$7f,$7f,$00,$00,$7f,$00,$00  ; instrument $14
075e: db    $10,$0f,$eb,$05,$f4,$7f,$00,$00  ; instrument $15
0766: db    $14,$0d,$eb,$05,$f4,$7f,$00,$00  ; instrument $16
076e: db    $15,$2e,$f3,$04,$f4,$7f,$00,$00  ; instrument $17
0776: db    $13,$3e,$b9,$05,$f4,$7f,$00,$00  ; instrument $18
077e: db    $16,$7f,$7f,$00,$00,$7f,$00,$00  ; instrument $19
0786: db    $17,$7f,$7f,$00,$00,$7f,$00,$00  ; instrument $1a
078e: db    $08,$7f,$7f,$01,$00,$7f,$01,$00  ; instrument $1b
0796: db    $18,$7f,$7f,$00,$00,$7f,$01,$00  ; instrument $1c
079e: db    $19,$7f,$7f,$00,$00,$7f,$01,$00  ; instrument $1d
07a6: db    $07,$4e,$d5,$05,$0c,$7f,$01,$00  ; instrument $1e
07ae: db    $07,$4e,$d5,$05,$0c,$7f,$01,$00  ; instrument $1f

Unused07B6:
07b6: db    $00                              ; unused

VoiceDspBase:
07b7: db    $00,$10,$20,$30,$40,$50,$60,$70  ; DSP register base of voice 0-7

VoiceBitMask:
07bf: db    $01,$02,$04,$08,$10,$20,$40,$80  ; bit mask of voice 0-7

; =============================================================================
; NoteOn - A = note, X = voice, $12 = channel record
;  VOL L = vol hi nibble * vel, VOL R = vol lo nibble * vel (vel = 8..15)
;  P = PitchTable[inst transpose + note + channel transpose] (no fine tune)
; =============================================================================
NoteOn:
07c7: c4 73     mov    NoteNum,a
07c9: d8 1a     mov    VoiceIdx,x
07cb: f5 bf 07  mov    a,VoiceBitMask+x
07ce: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF this voice
07d1: c4 f3     mov    DSPDATA,a
07d3: c4 1b     mov    VoiceBit,a
07d5: f5 b7 07  mov    a,VoiceDspBase+x      ; DSP base
07d8: 2d        push   a
07d9: 7d        mov    a,x
07da: fd        mov    y,a
07db: f8 12     mov    x,ChRec
07dd: e4 74     mov    a,NoteVel             ; velocity nibble -> 8 + v/2
07df: 5c        lsr    a
07e0: 60        clrc
07e1: 88 08     adc    a,#$08
07e3: c4 74     mov    NoteVel,a
07e5: e4 1b     mov    a,VoiceBit            ; remember keyed voices
07e7: 05 00 02  or     a,KeyOnHistory
07ea: c5 00 02  mov    KeyOnHistory,a
07ed: dd        mov    a,y
07ee: 1c        asl    a
07ef: fd        mov    y,a
07f0: f4 05     mov    a,Ch_Volume+x         ; R level
07f2: 28 0f     and    a,#$0f
07f4: eb 74     mov    y,NoteVel
07f6: cf        mul    ya
07f7: c4 76     mov    VolTmpR,a
07f9: 2d        push   a
07fa: 9f        xcn    a
07fb: 28 0f     and    a,#$0f
07fd: fd        mov    y,a
07fe: ae        pop    a
07ff: 9f        xcn    a
0800: 28 f0     and    a,#$f0
0802: f4 05     mov    a,Ch_Volume+x         ; L level
0804: 9f        xcn    a
0805: 28 0f     and    a,#$0f
0807: eb 74     mov    y,NoteVel
0809: cf        mul    ya
080a: c4 75     mov    VolTmpL,a
080c: f4 04     mov    a,Ch_Instr+x          ; instrument * 8
080e: 1c        asl    a
080f: 1c        asl    a
0810: 1c        asl    a
0811: fd        mov    y,a
0812: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0815: 8f 00 f3  mov    DSPDATA,#$00
0818: ce        pop    x
0819: 4b 76     lsr    VolTmpR
081b: 4b 76     lsr    VolTmpR
081d: 4b 75     lsr    VolTmpL
081f: 4b 75     lsr    VolTmpL
0821: f6 b6 06  mov    a,InstTable+y         ; SRCN bit7 : percussion hack
0824: 10 03     bpl    L0829
0826: 3f 08 09  call   PercussionHack

L0829:
0829: 78 07 1a  cmp    VoiceIdx,#$07         ; voice 7 (SFX voice) uses the SFX volume
082c: d0 11     bne    L083F
082e: 33 9f 05  bbc1   SfxFlags,L0836
0831: e4 a2     mov    a,SfxRepeatVol
0833: 5f 38 08  jmp    L0838

L0836:
0836: e4 99     mov    a,SfxVolume

L0838:
0838: c4 75     mov    VolTmpL,a
083a: c4 76     mov    VolTmpR,a
083c: 5f 43 08  jmp    L0843

L083F:
083f: 4b 75     lsr    VolTmpL
0841: 4b 76     lsr    VolTmpR

L0843:
0843: d8 f2     mov    DSPADDR,x
0845: fa 75 f3  mov    (DSPDATA),(VolTmpL)
0848: 3d        inc    x
0849: d8 f2     mov    DSPADDR,x
084b: fa 76 f3  mov    (DSPDATA),(VolTmpR)
084e: 3d        inc    x
084f: d8 f2     mov    DSPADDR,x
0851: 4d        push   x
0852: f6 ba 06  mov    a,InstTable+4+y       ; pitch index
0855: 60        clrc
0856: 84 73     adc    a,NoteNum
0858: 60        clrc
0859: 84 0e     adc    a,$0e
085b: 1c        asl    a
085c: 5d        mov    x,a
085d: f6 bc 06  mov    a,InstTable+6+y       ; table 0 or 1
0860: d0 12     bne    L0874
0862: f5 6e 0b  mov    a,PitchTable0+x
0865: c4 f3     mov    DSPDATA,a
0867: 78 07 1a  cmp    VoiceIdx,#$07
086a: d0 02     bne    L086E
086c: c4 96     mov    SfxPitch,a

L086E:
086e: f5 6f 0b  mov    a,PitchTable0+1+x
0871: 5f 83 08  jmp    L0883

L0874:
0874: f5 46 0c  mov    a,PitchTable1+x
0877: c4 f3     mov    DSPDATA,a
0879: 78 07 1a  cmp    VoiceIdx,#$07
087c: d0 02     bne    L0880
087e: c4 96     mov    SfxPitch,a

L0880:
0880: f5 47 0c  mov    a,PitchTable1+1+x

L0883:
0883: ce        pop    x
0884: 3d        inc    x
0885: d8 f2     mov    DSPADDR,x
0887: c4 f3     mov    DSPDATA,a
0889: 78 07 1a  cmp    VoiceIdx,#$07
088c: d0 02     bne    L0890
088e: c4 97     mov    SfxPitch+1,a

L0890:
0890: 3d        inc    x
0891: d8 f2     mov    DSPADDR,x
0893: f6 b6 06  mov    a,InstTable+y         ; SRCN
0896: 28 7f     and    a,#$7f
0898: c4 f3     mov    DSPDATA,a
089a: f6 b9 06  mov    a,InstTable+3+y
089d: c4 78     mov    InstFlagsTmp,a
089f: 43 78 12  bbs2   InstFlagsTmp,L08B4    ; ADSR (flags bit2) or GAIN
08a2: 3d        inc    x
08a3: d8 f2     mov    DSPADDR,x
08a5: 8f 00 f3  mov    DSPDATA,#$00
08a8: 3d        inc    x
08a9: 3d        inc    x
08aa: d8 f2     mov    DSPADDR,x
08ac: f6 b7 06  mov    a,InstTable+1+y
08af: c4 f3     mov    DSPDATA,a
08b1: 5f c6 08  jmp    L08C6

L08B4:
08b4: 3d        inc    x
08b5: d8 f2     mov    DSPADDR,x
08b7: f6 b7 06  mov    a,InstTable+1+y
08ba: 08 80     or     a,#$80
08bc: c4 f3     mov    DSPDATA,a
08be: 3d        inc    x
08bf: d8 f2     mov    DSPADDR,x
08c1: f6 b8 06  mov    a,InstTable+2+y
08c4: c4 f3     mov    DSPDATA,a

L08C6:
08c6: 09 1b 1d  or     (EonShadow),(VoiceBit) ; EON (voice 7: SfxDspBits)
08c9: 10 09     bpl    L08D4
08cb: 49 9a 1d  eor    (EonShadow),(SfxDspBits)
08ce: 03 78 09  bbs0   InstFlagsTmp,L08DA
08d1: 49 9a 1d  eor    (EonShadow),(SfxDspBits)

L08D4:
08d4: 03 78 03  bbs0   InstFlagsTmp,L08DA
08d7: 49 1b 1d  eor    (EonShadow),(VoiceBit)

L08DA:
08da: 8f 4d f2  mov    DSPADDR,#$4d          ; EON
08dd: fa 1d f3  mov    (DSPDATA),(EonShadow)
08e0: 09 1b 1e  or     (PmonShadow),(VoiceBit) ; PMON (flags bit1)
08e3: 23 78 03  bbs1   InstFlagsTmp,L08E9
08e6: 49 1b 1e  eor    (PmonShadow),(VoiceBit)

L08E9:
08e9: 8f 2d f2  mov    DSPADDR,#$2d          ; PMON
08ec: fa 1e f3  mov    (DSPDATA),(PmonShadow)
08ef: 09 1b 1c  or     (NonShadow),(VoiceBit) ; NON (flags bit3)
08f2: 63 78 03  bbs3   InstFlagsTmp,L08F8
08f5: 49 1b 1c  eor    (NonShadow),(VoiceBit)

L08F8:
08f8: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
08fb: 09 9a 1c  or     (NonShadow),(SfxDspBits)
08fe: fa 1c f3  mov    (DSPDATA),(NonShadow)
0901: 8f 4c f2  mov    DSPADDR,#$4c          ; KON
0904: fa 1b f3  mov    (DSPDATA),(VoiceBit)
0907: 6f        ret

; =============================================================================
; PercussionHack - game specific: for notes $15,$1c,$1d,$1a,$21 rewrite the
; instrument's SRCN (samples 8-11) and flags IN THE TABLE, replace the note
; by a fixed pitch ($63-$66) and double the volume.  A hard-wired drum kit;
; later versions replaced it with the drum map / key-split records.
; =============================================================================
PercussionHack:
0908: 4d        push   x
0909: 6d        push   y
090a: e4 73     mov    a,NoteNum
090c: 68 15     cmp    a,#$15
090e: d0 16     bne    L0926
0910: 8f 63 73  mov    NoteNum,#$63
0913: e8 08     mov    a,#$08
0915: 08 80     or     a,#$80
0917: d6 b6 06  mov    InstTable+y,a
091a: 0b 76     asl    VolTmpR
091c: 0b 75     asl    VolTmpL
091e: e8 01     mov    a,#$01
0920: d6 b9 06  mov    InstTable+3+y,a
0923: 5f 8e 09  jmp    L098E

L0926:
0926: 68 1c     cmp    a,#$1c
0928: d0 16     bne    L0940
092a: 8f 66 73  mov    NoteNum,#$66
092d: e8 09     mov    a,#$09
092f: 08 80     or     a,#$80
0931: d6 b6 06  mov    InstTable+y,a
0934: 0b 76     asl    VolTmpR
0936: 0b 75     asl    VolTmpL
0938: e8 01     mov    a,#$01
093a: d6 b9 06  mov    InstTable+3+y,a
093d: 5f 8e 09  jmp    L098E

L0940:
0940: 68 1d     cmp    a,#$1d
0942: d0 16     bne    L095A
0944: 8f 65 73  mov    NoteNum,#$65
0947: e8 0a     mov    a,#$0a
0949: 08 80     or     a,#$80
094b: d6 b6 06  mov    InstTable+y,a
094e: 0b 76     asl    VolTmpR
0950: 0b 75     asl    VolTmpL
0952: e8 01     mov    a,#$01
0954: d6 b9 06  mov    InstTable+3+y,a
0957: 5f 8e 09  jmp    L098E

L095A:
095a: 68 1a     cmp    a,#$1a
095c: d0 16     bne    L0974
095e: 8f 63 73  mov    NoteNum,#$63
0961: e8 0a     mov    a,#$0a
0963: 08 80     or     a,#$80
0965: d6 b6 06  mov    InstTable+y,a
0968: 0b 76     asl    VolTmpR
096a: 0b 75     asl    VolTmpL
096c: e8 01     mov    a,#$01
096e: d6 b9 06  mov    InstTable+3+y,a
0971: 5f 8e 09  jmp    L098E

L0974:
0974: 68 21     cmp    a,#$21
0976: d0 16     bne    L098E
0978: 8f 64 73  mov    NoteNum,#$64
097b: e8 0b     mov    a,#$0b
097d: 08 80     or     a,#$80
097f: d6 b6 06  mov    InstTable+y,a
0982: 0b 76     asl    VolTmpR
0984: 0b 75     asl    VolTmpL
0986: e8 00     mov    a,#$00
0988: d6 b9 06  mov    InstTable+3+y,a
098b: 5f 8e 09  jmp    L098E

L098E:
098e: ee        pop    y
098f: ce        pop    x
0990: 6f        ret

; -----------------------------------------------------------------------------
; BuiltinSongTable - songs for I/O $00: {tracks, flags, T0DIV,
; tracks x {volume, instrument, unused, pattern, flags, transpose}}.
; The only entry uses patterns $20-$26, beyond the 16-entry PatternTable
; (they would read code at $066f+) - a leftover from another build.
; -----------------------------------------------------------------------------
BuiltinSongTable:
0991: db    $07,$04,$64                      ; song 0: 7 tracks, flags $04, T0DIV $64
0994: db    $88,$10,$10,$20,$00,$00          ; track 1: vol, instr, -, pattern, flags, transp
099a: db    $88,$10,$10,$21,$00,$00          ; track 2
09a0: db    $77,$10,$10,$22,$00,$00          ; track 3
09a6: db    $77,$10,$10,$23,$00,$00          ; track 4
09ac: db    $77,$0e,$10,$24,$00,$00          ; track 5
09b2: db    $66,$01,$10,$25,$02,$00          ; track 6
09b8: db    $66,$01,$10,$26,$02,$00          ; track 7

; =============================================================================
; IoDispatch - $00 = command (APUIO0), $02/$03 = APUIO2/3
;   $00 play built-in song $02        $01 stop all
;   $02 T0DIV = $02 (tempo)           $04 play the song uploaded at $1400
;   $05 stop all + upload data        $06 VolSelect = $02
;   $07 report status in APUIO0       $80+n sound effect / fade
; =============================================================================
IoDispatch:
09be: 78 05 00  cmp    $00,#$05
09c1: d0 07     bne    L09CA
09c3: 3f e5 0f  call   StopAll               ; $05: stop, then receive a block
09c6: 3f 05 10  call   UploadBlock
09c9: 6f        ret

L09CA:
09ca: 78 06 00  cmp    $00,#$06
09cd: d0 04     bne    L09D3
09cf: fa 02 a9  mov    (VolSelect),($02)     ; $06
09d2: 6f        ret

L09D3:
09d3: 78 07 00  cmp    $00,#$07              ; $07: bit0 fade running, bit1 music active, bit2 SFX voice busy
09d6: d0 26     bne    L09FE
09d8: e8 cd     mov    a,#$cd
09da: e8 00     mov    a,#$00
09dc: f8 92     mov    x,FadeActive
09de: f0 02     beq    L09E2
09e0: 08 01     or     a,#$01

L09E2:
09e2: f8 19     mov    x,ChActive
09e4: f0 02     beq    L09E8
09e6: 08 02     or     a,#$02

L09E8:
09e8: 2d        push   a
09e9: 3f 19 0e  call   SfxVoiceBusy
09ec: ae        pop    a
09ed: 90 02     bcc    L09F1
09ef: 08 04     or     a,#$04

L09F1:
09f1: c4 f4     mov    APUIO0,a              ; APUIO0 = status, APUIO1 = $cd, wait for $ef
09f3: e8 cd     mov    a,#$cd
09f5: c4 f5     mov    APUIO1,a
09f7: e8 ef     mov    a,#$ef

L09F9:
09f9: 64 f4     cmp    a,APUIO0
09fb: d0 fc     bne    L09F9
09fd: 6f        ret

L09FE:
09fe: 78 00 00  cmp    $00,#$00
0a01: f0 03     beq    .playBuiltin
0a03: 5f 80 0a  jmp    .playUploaded
.playBuiltin:
0a06: 3f 61 05  call   InitDSP               ; $00
0a09: e8 00     mov    a,#$00
0a0b: c4 0f     mov    TickStep,a
0a0d: c4 19     mov    ChActive,a
0a0f: c5 00 02  mov    KeyOnHistory,a
0a12: c4 1f     mov    ChAllocated,a
0a14: f8 02     mov    x,$02
0a16: 8f 91 04  mov    $04,#$91              ; BuiltinSongTable
0a19: 8f 09 05  mov    $05,#$09
0a1c: 8d 00     mov    y,#$00

L0A1E:
0a1e: 1d        dec    x                     ; skip $02 songs (3 + 6*tracks bytes each)
0a1f: 30 19     bmi    L0A3A
0a21: f7 04     mov    a,($04)+y
0a23: c4 06     mov    $06,a

L0A25:
0a25: 60        clrc
0a26: 98 06 04  adc    $04,#$06
0a29: 98 00 05  adc    $05,#$00
0a2c: 8b 06     dec    $06
0a2e: d0 f5     bne    L0A25
0a30: 60        clrc
0a31: 98 03 04  adc    $04,#$03
0a34: 98 00 05  adc    $05,#$00
0a37: 5f 1e 0a  jmp    L0A1E

L0A3A:
0a3a: f7 04     mov    a,($04)+y
0a3c: fc        inc    y
0a3d: 5d        mov    x,a
0a3e: f7 04     mov    a,($04)+y
0a40: c4 18     mov    ChFlags,a
0a42: fc        inc    y
0a43: f7 04     mov    a,($04)+y
0a45: c4 fa     mov    T0DIV,a               ; T0DIV (tempo)
0a47: fc        inc    y

L0A48:
0a48: f7 04     mov    a,($04)+y
0a4a: c4 74     mov    NoteVel,a
0a4c: fc        inc    y
0a4d: f7 04     mov    a,($04)+y
0a4f: c4 02     mov    $02,a
0a51: fc        inc    y
0a52: f7 04     mov    a,($04)+y
0a54: c4 03     mov    $03,a
0a56: fc        inc    y
0a57: f7 04     mov    a,($04)+y
0a59: fc        inc    y
0a5a: 2d        push   a
0a5b: 29 01 18  and    (ChFlags),($01)
0a5e: f7 04     mov    a,($04)+y
0a60: fc        inc    y
0a61: 04 18     or     a,ChFlags
0a63: c4 18     mov    ChFlags,a
0a65: f7 04     mov    a,($04)+y
0a67: fc        inc    y
0a68: c4 0e     mov    $0e,a
0a6a: ae        pop    a
0a6b: 4d        push   x
0a6c: 6d        push   y
0a6d: f8 02     mov    x,$02
0a6f: eb 03     mov    y,$03
0a71: 3f 4f 06  call   StartChannel
0a74: ee        pop    y
0a75: ce        pop    x
0a76: 1d        dec    x
0a77: f0 03     beq    L0A7C
0a79: 5f 48 0a  jmp    L0A48

L0A7C:
0a7c: 3f 16 06  call   SetMasterVolume
0a7f: 6f        ret
.playUploaded:
0a80: 78 04 00  cmp    $00,#$04
0a83: f0 03     beq    L0A88
0a85: 5f 2c 0b  jmp    .setTempo

L0A88:
0a88: 3f 61 05  call   InitDSP               ; $04: song header at $1400
0a8b: e8 00     mov    a,#$00
0a8d: c4 0f     mov    TickStep,a
0a8f: c4 19     mov    ChActive,a
0a91: c5 00 02  mov    KeyOnHistory,a
0a94: c4 1f     mov    ChAllocated,a
0a96: cd 22     mov    x,#$22                ; clear the sync flags
0a98: 8d 08     mov    y,#$08

L0A9A:
0a9a: e8 00     mov    a,#$00
0a9c: d4 08     mov    Ch_Status+x,a
0a9e: 7d        mov    a,x
0a9f: 60        clrc
0aa0: 88 09     adc    a,#$09
0aa2: 5d        mov    x,a
0aa3: dc        dec    y
0aa4: d0 f4     bne    L0A9A
0aa6: f8 02     mov    x,$02
0aa8: 8f 00 04  mov    $04,#$00              ; word = offset of the pattern list (+$1400)
0aab: 8f 14 05  mov    $05,#$14
0aae: 8d 00     mov    y,#$00
0ab0: f7 04     mov    a,($04)+y
0ab2: c4 06     mov    $06,a
0ab4: fc        inc    y
0ab5: f7 04     mov    a,($04)+y
0ab7: 60        clrc
0ab8: 88 14     adc    a,#$14
0aba: c4 07     mov    $07,a
0abc: fc        inc    y
0abd: f7 04     mov    a,($04)+y             ; 2 * n words copied (only the first n are pattern pointers)
0abf: 1c        asl    a
0ac0: c4 00     mov    $00,a
0ac2: fc        inc    y
0ac3: 6d        push   y
0ac4: 8d 00     mov    y,#$00

L0AC6:
0ac6: f7 06     mov    a,($06)+y
0ac8: d6 2f 06  mov    PatternTable+y,a
0acb: fc        inc    y
0acc: f7 06     mov    a,($06)+y
0ace: 60        clrc
0acf: 88 14     adc    a,#$14
0ad1: d6 2f 06  mov    PatternTable+y,a
0ad4: fc        inc    y
0ad5: 8b 00     dec    $00
0ad7: d0 ed     bne    L0AC6
0ad9: ee        pop    y
0ada: f7 04     mov    a,($04)+y
0adc: fc        inc    y
0add: 5d        mov    x,a
0ade: f7 04     mov    a,($04)+y
0ae0: c4 18     mov    ChFlags,a
0ae2: c4 17     mov    SongFlags,a
0ae4: fc        inc    y
0ae5: f7 04     mov    a,($04)+y
0ae7: c4 fa     mov    T0DIV,a               ; T0DIV (tempo)
0ae9: fc        inc    y

L0AEA:
0aea: e4 a9     mov    a,VolSelect           ; VolSelect: first or second volume byte
0aec: f0 01     beq    L0AEF
0aee: fc        inc    y

L0AEF:
0aef: f7 04     mov    a,($04)+y
0af1: c4 74     mov    NoteVel,a
0af3: fc        inc    y
0af4: e4 a9     mov    a,VolSelect
0af6: d0 01     bne    L0AF9
0af8: fc        inc    y

L0AF9:
0af9: f7 04     mov    a,($04)+y
0afb: c4 02     mov    $02,a
0afd: fc        inc    y
0afe: f7 04     mov    a,($04)+y
0b00: c4 03     mov    $03,a
0b02: fc        inc    y
0b03: f7 04     mov    a,($04)+y
0b05: fc        inc    y
0b06: 2d        push   a
0b07: fa 17 18  mov    (ChFlags),(SongFlags)
0b0a: f7 04     mov    a,($04)+y
0b0c: fc        inc    y
0b0d: 04 18     or     a,ChFlags
0b0f: c4 18     mov    ChFlags,a
0b11: f7 04     mov    a,($04)+y
0b13: fc        inc    y
0b14: c4 0e     mov    $0e,a
0b16: ae        pop    a
0b17: 4d        push   x
0b18: 6d        push   y
0b19: f8 02     mov    x,$02
0b1b: eb 03     mov    y,$03
0b1d: 3f 4f 06  call   StartChannel
0b20: ee        pop    y
0b21: ce        pop    x
0b22: 1d        dec    x
0b23: f0 03     beq    L0B28
0b25: 5f ea 0a  jmp    L0AEA

L0B28:
0b28: 3f 16 06  call   SetMasterVolume
0b2b: 6f        ret
.setTempo:
0b2c: 78 02 00  cmp    $00,#$02
0b2f: d0 05     bne    .stopAll
0b31: e4 02     mov    a,$02
0b33: c4 fa     mov    T0DIV,a
0b35: 6f        ret
.stopAll:
0b36: 78 01 00  cmp    $00,#$01
0b39: d0 22     bne    .sfx
0b3b: 3f 61 05  call   InitDSP
0b3e: e8 00     mov    a,#$00
0b40: c4 0f     mov    TickStep,a
0b42: c4 19     mov    ChActive,a
0b44: c5 00 02  mov    KeyOnHistory,a
0b47: c4 1f     mov    ChAllocated,a
0b49: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0b4c: 8f ff f3  mov    DSPDATA,#$ff
0b4f: cd ff     mov    x,#$ff                ; short delay with all voices keyed off

L0B51:
0b51: 00        nop
0b52: 00        nop
0b53: 1d        dec    x
0b54: d0 fb     bne    L0B51
0b56: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0b59: 8f 00 f3  mov    DSPDATA,#$00
0b5c: 6f        ret
.sfx:
0b5d: e4 00     mov    a,$00
0b5f: 28 80     and    a,#$80
0b61: f0 0a     beq    L0B6D
0b63: e4 00     mov    a,$00
0b65: 28 7f     and    a,#$7f
0b67: c4 00     mov    $00,a
0b69: 3f b1 0d  call   SfxCommand
0b6c: 6f        ret

L0B6D:
0b6d: 6f        ret

; -----------------------------------------------------------------------------
; Two global pitch tables, 108 words each (table 1 ends with 12 junk values)
; -----------------------------------------------------------------------------
PitchTable0:
0b6e: dw    $0080,$0088,$0090,$0098,$00a1,$00ab,$00b5,$00c0,$00cb,$00d7,$00e4,$00f2
0b86: dw    $0100,$010f,$011f,$0130,$0143,$0156,$016a,$0180,$0196,$01af,$01c8,$01e3
0b9e: dw    $0200,$021e,$023f,$0261,$0285,$02ab,$02d4,$02ff,$032d,$035d,$0390,$03c7
0bb6: dw    $0400,$043d,$047d,$04c2,$050a,$0557,$05a8,$05fe,$065a,$06ba,$0721,$078d
0bce: dw    $0800,$087a,$08fb,$0984,$0a14,$0aae,$0b50,$0bfd,$0cb3,$0d74,$0e41,$0f1a
0be6: dw    $1000,$10f4,$11f6,$1307,$1429,$155c,$16a1,$17f9,$1966,$1ae9,$1c82,$1e34
0bfe: dw    $2000,$21e7,$23eb,$260e,$2851,$2ab7,$2d41,$2ff2,$32cc,$35d1,$3904,$3c68
0c16: dw    $4000,$43ce,$47d6,$4c1c,$50a2,$556e,$5a82,$5fe4,$6598,$6ba3,$7209,$78d1
0c2e: dw    $8000,$879d,$8fad,$9838,$a02b,$aadd,$b505,$bfc8,$cb30,$d745,$e412,$f1a2

PitchTable1:
0c46: dw    $0043,$0047,$004b,$0050,$0054,$0059,$005f,$0064,$006a,$0071,$0077,$007e
0c5e: dw    $0086,$008e,$0096,$009f,$00a9,$00b3,$00bd,$00c9,$00d5,$00e1,$00ef,$00fd
0c76: dw    $010c,$011c,$012d,$013f,$0152,$0166,$017b,$0191,$01a9,$01c3,$01dd,$01fa
0c8e: dw    $0218,$0238,$0259,$027d,$02a3,$02cb,$02f6,$0323,$0353,$0385,$03bb,$03f3
0ca6: dw    $0430,$046f,$04b3,$04fa,$0546,$0596,$05eb,$0646,$06a5,$070a,$0775,$07e7
0cbe: dw    $085f,$08df,$0966,$09f5,$0a8c,$0b2d,$0bd7,$0c8b,$0d4a,$0e14,$0eeb,$0fce
0cd6: dw    $10be,$11bd,$12cb,$13ea,$1519,$165a,$17ae,$1916,$1a94,$1c29,$1dd6,$1f9c
0cee: dw    $217d,$237b,$2597,$27d3,$29e7,$2cb4,$2f5c,$322d,$3529,$3852,$3bab,$3f37
0d06: dw    $0100,$0200,$0400,$0500,$0600,$0700,$0800,$0a00,$0b00,$0c00,$0d00,$1000

; =============================================================================
; SfxTick (timer 1, 12.5 ms) - master fade-out (command $81) and the
; pitch sweep of the SFX voice (SfxSweep 3 up / 4 down)
; =============================================================================
SfxTick:
0d1e: 78 00 92  cmp    FadeActive,#$00
0d21: f0 29     beq    .sweep
0d23: 8b 94     dec    FadeCount
0d25: d0 25     bne    .sweep
0d27: fa 95 94  mov    (FadeCount),(FadeRate) ; fade step: MVOL = 2*level, EVOL = level
0d2a: e4 93     mov    a,FadeLevel
0d2c: 1c        asl    a
0d2d: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOLL
0d30: c4 f3     mov    DSPDATA,a
0d32: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOLR
0d35: c4 f3     mov    DSPDATA,a
0d37: 5c        lsr    a
0d38: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
0d3b: c4 f3     mov    DSPDATA,a
0d3d: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
0d40: c4 f3     mov    DSPDATA,a
0d42: 8b 93     dec    FadeLevel
0d44: 10 06     bpl    .sweep
0d46: 3f e5 0f  call   StopAll               ; faded out: stop everything
0d49: 8f 00 92  mov    FadeActive,#$00
.sweep:
0d4c: 78 00 91  cmp    SfxSweep,#$00
0d4f: d0 01     bne    L0D52
0d51: 6f        ret

L0D52:
0d52: 78 05 91  cmp    SfxSweep,#$05
0d55: d0 07     bne    L0D5E
0d57: 8f 00 91  mov    SfxSweep,#$00
0d5a: 3f 61 05  call   InitDSP
0d5d: 6f        ret

L0D5E:
0d5e: 78 03 91  cmp    SfxSweep,#$03
0d61: d0 20     bne    L0D83
0d63: e4 97     mov    a,SfxPitch+1
0d65: 5c        lsr    a
0d66: d0 02     bne    L0D6A
0d68: e8 01     mov    a,#$01

L0D6A:
0d6a: eb 98     mov    y,SfxSweepRate
0d6c: cf        mul    ya
0d6d: 7a 96     addw   ya,SfxPitch
0d6f: c4 96     mov    SfxPitch,a
0d71: dd        mov    a,y
0d72: 28 3f     and    a,#$3f
0d74: c4 97     mov    SfxPitch+1,a
0d76: 8f 72 f2  mov    DSPADDR,#$72          ; V7PL
0d79: fa 96 f3  mov    (DSPDATA),(SfxPitch)
0d7c: 8f 73 f2  mov    DSPADDR,#$73          ; V7PH
0d7f: fa 97 f3  mov    (DSPDATA),(SfxPitch+1)
0d82: 6f        ret

L0D83:
0d83: 78 04 91  cmp    SfxSweep,#$04
0d86: d0 28     bne    L0DB0
0d88: e4 97     mov    a,SfxPitch+1
0d8a: 5c        lsr    a
0d8b: d0 02     bne    L0D8F
0d8d: e8 01     mov    a,#$01

L0D8F:
0d8f: eb 98     mov    y,SfxSweepRate
0d91: cf        mul    ya
0d92: da 00     movw   $00,ya
0d94: e4 96     mov    a,SfxPitch
0d96: 80        setc
0d97: a4 00     sbc    a,$00
0d99: c4 96     mov    SfxPitch,a
0d9b: e4 97     mov    a,SfxPitch+1
0d9d: a4 01     sbc    a,$01
0d9f: 28 3f     and    a,#$3f
0da1: c4 97     mov    SfxPitch+1,a
0da3: 8f 72 f2  mov    DSPADDR,#$72          ; V7PL
0da6: fa 96 f3  mov    (DSPDATA),(SfxPitch)
0da9: 8f 73 f2  mov    DSPADDR,#$73          ; V7PH
0dac: fa 97 f3  mov    (DSPDATA),(SfxPitch+1)
0daf: 6f        ret

L0DB0:
0db0: 6f        ret

; =============================================================================
; SfxCommand - $00 = n: $01 = fade out music (rate $02), else sound effect n
;  on voice 7 through the SFX pseudo channel ($6a).  $03 = priority (bits0-5),
;  bit6 = keep volume, bit7 = repeat (echo) mode
; =============================================================================
SfxCommand:
0db1: 78 01 00  cmp    $00,#$01
0db4: d0 10     bne    L0DC6
0db6: 8f 01 92  mov    FadeActive,#$01
0db9: 8f 00 91  mov    SfxSweep,#$00
0dbc: 8f 3f 93  mov    FadeLevel,#$3f
0dbf: fa 02 95  mov    (FadeRate),($02)
0dc2: fa 02 94  mov    (FadeCount),($02)
0dc5: 6f        ret

L0DC6:
0dc6: 78 01 92  cmp    FadeActive,#$01
0dc9: d0 01     bne    L0DCC
0dcb: 6f        ret

L0DCC:
0dcc: 3f 19 0e  call   SfxVoiceBusy          ; SFX voice busy and new priority lower -> ignore
0dcf: 90 09     bcc    L0DDA
0dd1: e4 03     mov    a,$03
0dd3: 28 3f     and    a,#$3f
0dd5: 64 9c     cmp    a,SfxPriority
0dd7: b0 01     bcs    L0DDA
0dd9: 6f        ret

L0DDA:
0dda: 52 9f     clr12  SfxFlags
0ddc: d3 03 02  bbc6   $03,L0DE1
0ddf: 42 9f     set12  SfxFlags

L0DE1:
0de1: 62 9f     set13  SfxFlags
0de3: fa 03 9c  mov    (SfxPriority),($03)
0de6: 3f 16 06  call   SetMasterVolume
0de9: 8f 00 70  mov    SfxRecord+6,#$00
0dec: 8f 00 71  mov    SfxRecord+7,#$00
0def: 8f 6a 12  mov    ChRec,#$6a
0df2: 8f 3f 99  mov    SfxVolume,#$3f
0df5: 8f 00 9a  mov    SfxDspBits,#$00
0df8: cd 07     mov    x,#$07
0dfa: fa 02 9d  mov    (SfxLastCmd),($02)
0dfd: fa 00 9e  mov    (SfxLastCmd+1),($00)
0e00: e4 02     mov    a,$02
0e02: 32 9f     clr11  SfxFlags
0e04: 8f 10 a6  mov    SfxRepeatRate,#$10
0e07: 3f 45 0e  call   SfxStart
0e0a: f3 9c 02  bbc7   SfxPriority,L0E0F
0e0d: 22 9f     set11  SfxFlags

L0E0F:
0e0f: 38 3f 9c  and    SfxPriority,#$3f
0e12: fa 99 a2  mov    (SfxRepeatVol),(SfxVolume)
0e15: fa a6 a0  mov    (SfxRepeatCnt),(SfxRepeatRate)
0e18: 6f        ret

; SfxVoiceBusy - C = 1 while voice 7 still sounds (ENDX or ENVX)
SfxVoiceBusy:
0e19: 03 9f 02  bbs0   SfxFlags,L0E1E
0e1c: 60        clrc
0e1d: 6f        ret

L0E1E:
0e1e: 78 00 9b  cmp    SfxEndMode,#$00
0e21: d0 16     bne    L0E39
0e23: 8f 7c f2  mov    DSPADDR,#$7c          ; ENDX
0e26: e4 f3     mov    a,DSPDATA
0e28: 8f 00 f3  mov    DSPDATA,#$00
0e2b: 28 ff     and    a,#$ff
0e2d: 80        setc
0e2e: 10 03     bpl    L0E33
0e30: 60        clrc
0e31: 12 9f     clr10  SfxFlags

L0E33:
0e33: 5f 44 0e  jmp    L0E44
0e36: 5f 44 0e  jmp    L0E44

L0E39:
0e39: 8f 78 f2  mov    DSPADDR,#$78          ; V7ENVX
0e3c: e4 f3     mov    a,DSPDATA
0e3e: 80        setc
0e3f: d0 03     bne    L0E44
0e41: 60        clrc
0e42: 12 9f     clr10  SfxFlags

L0E44:
0e44: 6f        ret

; =============================================================================
; SfxStart - hard-coded effect list: $10-$20 each pick an instrument ($6e),
; volume ($99), optional sweep; $1e keys voice 7 off.  No SFX data format.
; =============================================================================
SfxStart:
0e45: 02 9f     set10  SfxFlags
0e47: 78 1e 00  cmp    $00,#$1e
0e4a: d0 0d     bne    L0E59
0e4c: 8f 75 f2  mov    DSPADDR,#$75          ; V7ADSR1
0e4f: 8f 00 f3  mov    DSPDATA,#$00
0e52: 8f 77 f2  mov    DSPADDR,#$77          ; V7GAIN
0e55: 8f b7 f3  mov    DSPDATA,#$b7
0e58: 6f        ret

L0E59:
0e59: 78 13 00  cmp    $00,#$13
0e5c: d0 11     bne    L0E6F
0e5e: 72 9f     clr13  SfxFlags
0e60: 8f 19 6e  mov    SfxRecord+4,#$19
0e63: e8 2b     mov    a,#$2b
0e65: 8f 7f 99  mov    SfxVolume,#$7f
0e68: 3f d1 0f  call   SfxPlayNote
0e6b: 8f 00 91  mov    SfxSweep,#$00
0e6e: 6f        ret

L0E6F:
0e6f: 78 14 00  cmp    $00,#$14
0e72: d0 15     bne    L0E89
0e74: 8f 80 9a  mov    SfxDspBits,#$80
0e77: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
0e7a: c4 f3     mov    DSPDATA,a
0e7c: 8f 04 6e  mov    SfxRecord+4,#$04
0e7f: 8f 20 99  mov    SfxVolume,#$20
0e82: 3f d1 0f  call   SfxPlayNote
0e85: 8f 00 91  mov    SfxSweep,#$00
0e88: 6f        ret

L0E89:
0e89: 78 18 00  cmp    $00,#$18
0e8c: d0 10     bne    L0E9E
0e8e: 8f 1e 6e  mov    SfxRecord+4,#$1e
0e91: 8f 4f 99  mov    SfxVolume,#$4f
0e94: 3f d1 0f  call   SfxPlayNote
0e97: 8f 03 91  mov    SfxSweep,#$03
0e9a: 8f 10 98  mov    SfxSweepRate,#$10
0e9d: 6f        ret

L0E9E:
0e9e: 78 1b 00  cmp    $00,#$1b
0ea1: d0 10     bne    L0EB3
0ea3: 8f 08 6e  mov    SfxRecord+4,#$08
0ea6: 8f 2f 99  mov    SfxVolume,#$2f
0ea9: 3f d1 0f  call   SfxPlayNote
0eac: 8f 04 91  mov    SfxSweep,#$04
0eaf: 8f 50 98  mov    SfxSweepRate,#$50
0eb2: 6f        ret

L0EB3:
0eb3: 78 15 00  cmp    $00,#$15
0eb6: d0 12     bne    L0ECA
0eb8: 8f 20 a6  mov    SfxRepeatRate,#$20
0ebb: 72 9f     clr13  SfxFlags
0ebd: 8f 1d 6e  mov    SfxRecord+4,#$1d
0ec0: 8f 5f 99  mov    SfxVolume,#$5f
0ec3: 3f d1 0f  call   SfxPlayNote
0ec6: 8f 00 91  mov    SfxSweep,#$00
0ec9: 6f        ret

L0ECA:
0eca: 78 16 00  cmp    $00,#$16
0ecd: d0 0f     bne    L0EDE
0ecf: 72 9f     clr13  SfxFlags
0ed1: 8f 1c 6e  mov    SfxRecord+4,#$1c
0ed4: 8f 5f 99  mov    SfxVolume,#$5f
0ed7: 3f d1 0f  call   SfxPlayNote
0eda: 8f 00 91  mov    SfxSweep,#$00
0edd: 6f        ret

L0EDE:
0ede: 78 1f 00  cmp    $00,#$1f
0ee1: d0 12     bne    L0EF5
0ee3: 8f 20 a6  mov    SfxRepeatRate,#$20
0ee6: 72 9f     clr13  SfxFlags
0ee8: 8f 02 6e  mov    SfxRecord+4,#$02
0eeb: 8f 5f 99  mov    SfxVolume,#$5f
0eee: 3f d1 0f  call   SfxPlayNote
0ef1: 8f 00 91  mov    SfxSweep,#$00
0ef4: 6f        ret

L0EF5:
0ef5: 78 20 00  cmp    $00,#$20
0ef8: d0 12     bne    L0F0C
0efa: 8f 20 a6  mov    SfxRepeatRate,#$20
0efd: 72 9f     clr13  SfxFlags
0eff: 8f 05 6e  mov    SfxRecord+4,#$05
0f02: 8f 5f 99  mov    SfxVolume,#$5f
0f05: 3f d1 0f  call   SfxPlayNote
0f08: 8f 00 91  mov    SfxSweep,#$00
0f0b: 6f        ret

L0F0C:
0f0c: 78 10 00  cmp    $00,#$10
0f0f: d0 0d     bne    L0F1E
0f11: 8f 17 6e  mov    SfxRecord+4,#$17
0f14: 8f 20 99  mov    SfxVolume,#$20
0f17: 3f d1 0f  call   SfxPlayNote
0f1a: 8f 00 91  mov    SfxSweep,#$00
0f1d: 6f        ret

L0F1E:
0f1e: 78 17 00  cmp    $00,#$17
0f21: d0 0d     bne    L0F30
0f23: 8f 01 6e  mov    SfxRecord+4,#$01
0f26: 8f 3f 99  mov    SfxVolume,#$3f
0f29: 3f d1 0f  call   SfxPlayNote
0f2c: 8f 00 91  mov    SfxSweep,#$00
0f2f: 6f        ret

L0F30:
0f30: 78 19 00  cmp    $00,#$19
0f33: d0 0f     bne    L0F44
0f35: 72 9f     clr13  SfxFlags
0f37: 8f 1b 6e  mov    SfxRecord+4,#$1b
0f3a: 8f 7f 99  mov    SfxVolume,#$7f
0f3d: 3f d1 0f  call   SfxPlayNote
0f40: 8f 00 91  mov    SfxSweep,#$00
0f43: 6f        ret

L0F44:
0f44: 78 1a 00  cmp    $00,#$1a
0f47: d0 10     bne    L0F59
0f49: 8f 01 6e  mov    SfxRecord+4,#$01
0f4c: 8f 2f 99  mov    SfxVolume,#$2f
0f4f: 3f d1 0f  call   SfxPlayNote
0f52: 8f 03 91  mov    SfxSweep,#$03
0f55: 8f 60 98  mov    SfxSweepRate,#$60
0f58: 6f        ret

L0F59:
0f59: 78 12 00  cmp    $00,#$12
0f5c: d0 10     bne    L0F6E
0f5e: 8f 16 6e  mov    SfxRecord+4,#$16
0f61: 8f 20 99  mov    SfxVolume,#$20
0f64: 3f d1 0f  call   SfxPlayNote
0f67: 8f 04 91  mov    SfxSweep,#$04
0f6a: 8f 04 98  mov    SfxSweepRate,#$04
0f6d: 6f        ret

L0F6E:
0f6e: 78 11 00  cmp    $00,#$11
0f71: d0 10     bne    L0F83
0f73: 8f 18 6e  mov    SfxRecord+4,#$18
0f76: 8f 20 99  mov    SfxVolume,#$20
0f79: 3f d1 0f  call   SfxPlayNote
0f7c: 8f 04 91  mov    SfxSweep,#$04
0f7f: 8f 01 98  mov    SfxSweepRate,#$01
0f82: 6f        ret

L0F83:
0f83: 78 1c 00  cmp    $00,#$1c
0f86: d0 0d     bne    L0F95
0f88: 8f 00 6e  mov    SfxRecord+4,#$00
0f8b: 8f 5f 99  mov    SfxVolume,#$5f
0f8e: 3f d1 0f  call   SfxPlayNote
0f91: 8f 00 91  mov    SfxSweep,#$00
0f94: 6f        ret

L0F95:
0f95: 6f        ret

; SfxRepeatTick - repeat mode: replay the effect every SfxRepeatRate ticks
; at half the previous volume until it reaches 0
SfxRepeatTick:
0f96: 23 9f 01  bbs1   SfxFlags,L0F9A
0f99: 6f        ret

L0F9A:
0f9a: 03 9f 01  bbs0   SfxFlags,L0F9E
0f9d: 6f        ret

L0F9E:
0f9e: 8b a0     dec    SfxRepeatCnt
0fa0: f0 01     beq    L0FA3
0fa2: 6f        ret

L0FA3:
0fa3: fa a6 a0  mov    (SfxRepeatCnt),(SfxRepeatRate)
0fa6: 8f 01 9b  mov    SfxEndMode,#$01
0fa9: 3f 16 06  call   SetMasterVolume
0fac: 8f 00 70  mov    SfxRecord+6,#$00
0faf: 8f 00 71  mov    SfxRecord+7,#$00
0fb2: 8f 6a 12  mov    ChRec,#$6a
0fb5: 4b a2     lsr    SfxRepeatVol
0fb7: d0 05     bne    L0FBE
0fb9: 32 9f     clr11  SfxFlags
0fbb: 12 9f     clr10  SfxFlags
0fbd: 6f        ret

L0FBE:
0fbe: 8f 2f 99  mov    SfxVolume,#$2f
0fc1: 8f 00 9a  mov    SfxDspBits,#$00
0fc4: cd 07     mov    x,#$07
0fc6: fa 9d 02  mov    ($02),(SfxLastCmd)
0fc9: fa 9e 00  mov    ($00),(SfxLastCmd+1)
0fcc: e4 02     mov    a,$02
0fce: 5f 45 0e  jmp    SfxStart

SfxPlayNote:
0fd1: 43 9f 0e  bbs2   SfxFlags,L0FE2
0fd4: 2d        push   a
0fd5: e4 99     mov    a,SfxVolume
0fd7: 5c        lsr    a
0fd8: c4 00     mov    $00,a
0fda: e4 99     mov    a,SfxVolume
0fdc: 80        setc
0fdd: a4 00     sbc    a,$00
0fdf: c4 99     mov    SfxVolume,a
0fe1: ae        pop    a

L0FE2:
0fe2: 5f c7 07  jmp    NoteOn

StopAll:
0fe5: e8 00     mov    a,#$00
0fe7: c4 0f     mov    TickStep,a
0fe9: c4 19     mov    ChActive,a
0feb: c5 00 02  mov    KeyOnHistory,a
0fee: c4 1f     mov    ChAllocated,a
0ff0: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0ff3: 8f ff f3  mov    DSPDATA,#$ff
0ff6: cd 00     mov    x,#$00

L0FF8:
0ff8: e8 00     mov    a,#$00
0ffa: d4 89     mov    VoiceFlags+x,a
0ffc: 3d        inc    x
0ffd: c8 08     cmp    x,#$08
0fff: d0 f7     bne    L0FF8
1001: 3f 61 05  call   InitDSP
1004: 6f        ret

; =============================================================================
; UploadBlock (I/O $05) - handshake $aa/$bb, $cc; APUIO2/3 = address,
;  second word -> $a7/$a8; then one byte per step in APUIO1 with a counter
;  in APUIO0 (4,5,...,$fe, skipping $ff); APUIO0 = $ff ends the transfer.
; =============================================================================
UploadBlock:
1005: 8f 33 f1  mov    CONTROL,#$33
1008: 00        nop
1009: 00        nop
100a: 00        nop
100b: 8f aa f4  mov    APUIO0,#$aa
100e: 8f aa f4  mov    APUIO0,#$aa
1011: 8f bb f5  mov    APUIO1,#$bb
1014: 8f bb f5  mov    APUIO1,#$bb

L1017:
1017: 78 cc f4  cmp    APUIO0,#$cc
101a: d0 fb     bne    L1017
101c: 8f cc f4  mov    APUIO0,#$cc
101f: 8f cc f4  mov    APUIO0,#$cc
1022: 8f 00 f5  mov    APUIO1,#$00
1025: 8f 00 f5  mov    APUIO1,#$00

L1028:
1028: 78 01 f4  cmp    APUIO0,#$01
102b: d0 fb     bne    L1028
102d: ba f6     movw   ya,APUIO2
102f: da 00     movw   $00,ya
1031: 8f 01 f4  mov    APUIO0,#$01
1034: 8f 01 f4  mov    APUIO0,#$01

L1037:
1037: 78 01 f4  cmp    APUIO0,#$01
103a: f0 fb     beq    L1037
103c: 78 02 f4  cmp    APUIO0,#$02
103f: d0 f6     bne    L1037
1041: e4 f6     mov    a,APUIO2
1043: c4 a7     mov    UploadParam,a
1045: e4 f7     mov    a,APUIO3
1047: c4 a8     mov    UploadParam+1,a
1049: 8f 02 f4  mov    APUIO0,#$02
104c: 8f 02 f4  mov    APUIO0,#$02
104f: 8f 00 f6  mov    APUIO2,#$00
1052: 8f 00 f6  mov    APUIO2,#$00

L1055:
1055: 78 02 f4  cmp    APUIO0,#$02
1058: f0 fb     beq    L1055
105a: 78 04 f4  cmp    APUIO0,#$04
105d: d0 f6     bne    L1055
105f: cd 04     mov    x,#$04
1061: 8d 00     mov    y,#$00

L1063:
1063: e4 f5     mov    a,APUIO1
1065: d7 00     mov    ($00)+y,a
1067: 3a 00     incw   $00
1069: d8 f6     mov    APUIO2,x
106b: d8 f6     mov    APUIO2,x
106d: 3d        inc    x
106e: c8 ff     cmp    x,#$ff
1070: d0 01     bne    L1073
1072: 3d        inc    x

L1073:
1073: 78 ff f4  cmp    APUIO0,#$ff
1076: d0 05     bne    L107D
1078: 78 ff f4  cmp    APUIO0,#$ff
107b: f0 0e     beq    L108B

L107D:
107d: 3e f4     cmp    x,APUIO0
107f: d0 04     bne    L1085
1081: 3e f4     cmp    x,APUIO0
1083: f0 03     beq    L1088

L1085:
1085: 5f 73 10  jmp    L1073

L1088:
1088: 5f 63 10  jmp    L1063

L108B:
108b: 8f ff f4  mov    APUIO0,#$ff
108e: 8f ff f4  mov    APUIO0,#$ff
1091: cd 05     mov    x,#$05

L1093:
1093: 1d        dec    x
1094: d0 fd     bne    L1093
1096: 6f        ret

; end of driver image ($1096)
