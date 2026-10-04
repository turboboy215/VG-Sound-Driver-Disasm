;==============================================================================
; SLICK/Audio v1.01  (C)1994 Bitmasters, Inc.  -  SPC700 sound driver
; as used in Earthworm Jim (SNES).  Image $0580-$1d78, entry point Reset ($0878)
;
; Labeled / commented disassembly based on the SPCdas listing "Earthworm Jim.s"
; and verified against "Earthworm Jim ($0580).bin" and "04 - Snot a Problem.spc".
; See SLICK_Engine_Notes.md for the full description of formats and commands.
;
; Syntax is kept identical to SPCdas so the two files can be compared:
;   bbcN dp,rel / bbsN dp,rel   = test bit N of dp
;   (dst),(src)                 = dp-to-dp operations (mov/or/cmp/adc... dd,ss)
;   (dp)+y, (dp+x), (abs+x)     = indirect modes
;   mov1 c,$aaaa,b              = bit b of address $aaaa
; Addresses and opcode bytes are left in every line.  Unnamed branch targets
; are called Lxxxx.  RAM equates are listed below.
;
; CORRECTIONS TO THE SPCdas LISTING
;   1. $086f-$0877 is a data table (KeySplitOffsetTable), not code.
;   2. $1005-$1024 are 32 unreferenced garbage bytes.  Decoding them as code
;      mis-aligned the real routine StealTrack: it starts at $1025
;      ("cmp $0b,#$e0 / bcc $1075 / mov $16,#$ff ...", called from $0f54);
;      SPCdas showed "1023: sbc ($78),($e4) / 1026: clrv / 1027: asl $90 /
;      1029: lsr $8f / 102b: stop ..." until it re-synchronised at $1036.
;   3. $05f1 is a RAM variable (the .s shows the SPC snapshot value $2b; the
;      .bin contains $3d).
;   4. The instructions at $1a75 and $1a7e are self-modified: their operand
;      "$2324" is only the value left in the snapshot (see IoCmd_10).
;   5. "jmp ($0581+x)" at $0580: the table really starts at $0583 because
;      command numbers start at $02 (noted; the bytes were already correct).
;   All other opcode/operand decodings of SPCdas were checked instruction by
;   instruction against an independent SPC700 table and are correct.  A
;   recursive trace from all entry points and jump tables reaches every byte
;   of the image except the data areas marked below (and the dead RET $1960).
;
; ORIGINAL (driver) BUGS worth knowing - NOT disassembly errors:
;   $0d06  note with TrkFlags bit4 set jumps to RET with a byte still pushed
;   $0d93  E3/EB end-of-track compares A instead of X with VOwnerTrack
;   $1961  I/O $0C writes "$6c" to DSPDATA and $ff to DSPADDR (swapped)
;   $18e8  SetEchoDelay compares with EchoDelayCur, which is always $ff
;   $07ad  key-split near-miss ranges are one key wider than the table
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
BlockEnd         = $0000   ; install commands: end of block
LoadID           = $0002   ; [2] I/O $0E param: ID / slot offset added by install commands
LoadAddr         = $0004   ; [2] I/O $0E param: address of uploaded block
CurTrack         = $001c   ; [1] current track index (0-21)
CurVoice         = $001d   ; [1] current voice index (0-7)
CurVoiceDsp      = $001e   ; [1] DSP register base of the voice in VoiceLoop ($70..$00)
SeqPtr           = $001f   ; [2] sequence read pointer of the current track
StereoMode       = $0025   ; [1] 0 mono, 1 stereo, 2 stereo + surround
DirPage          = $0027   ; [1] DIR page ($23 -> $2300)
Delta            = $0028   ; [3] result of ReadVLQ (lo, mid, hi)
TicksElapsed     = $002e   ; [1] timer-0 ticks since last frame (normally 1)
HdrTempo         = $002f   ; [1] tempo byte of the sound being started
VState           = $0030   ; [1] copy of VoiceState[x] in VoiceLoop
HdrFlags         = $0031   ; [1] sound-level flags of the sound being started
HdrTrkFlags      = $0032   ; [1] track flags of the track being started
CurFlags         = $0033   ; [1] copy of TrkFlags / VFlags
CurStatus        = $0034   ; [1] copy of TrkStatus
VoiceBit         = $0035   ; [1] bit of the current voice
NonShadow        = $0036   ; [1] NON shadow
EonShadow        = $0037   ; [1] EON shadow
NoteNum          = $0039   ; [1] note being started
Velocity         = $003a   ; [1] velocity being started
VolTmpL          = $003b   ; [1] CalcVoiceVolume result L
VolTmpR          = $003c   ; [1] CalcVoiceVolume result R
InstFlagsTmp     = $003e   ; [1] InstFlags of the instrument being started
PriorityTmp      = $003f   ; [1] priority for AllocTrack/StealTrack
HandshakeCnt     = $0040   ; [1] next expected APUIO1 counter
EndxLatch        = $0042   ; [1] ENDX, shifted left once per voice
FlgShadow        = $0043   ; [1] FLG shadow
HdrTranspose     = $0044   ; [1] transpose of the track being started / extra transpose
Status           = $0045   ; [1] value sent on APUIO2: bit0 sync flag changed, bit1 queue done
FrameCounter     = $0048   ; [1] incremented every tick
FirReg           = $004a   ; [1] SetFIR register index
TrkTimerHi       = $004b   ; [22] track timer byte 3 (bit7: negative = event due / disabled)
TrkTimerMid      = $0061   ; [22] track timer byte 2
TrkTimerLo       = $0077   ; [22] track timer byte 1 (delta ticks are added here)
TrkTimerFrac     = $008d   ; [22] track timer byte 0 (fraction)
VSoundID         = $00a3   ; [8] sound ID of voice
VGateHi          = $00ab   ; [8] note length remaining, byte 3 (bit7 = infinite)
VGateMid         = $00b3   ; [8] note length byte 2
VGateLo          = $00bb   ; [8] note length byte 1
VGateFrac        = $00c3   ; [8] note length byte 0
VAgeHi           = $00cb   ; [8] voice age hi
VAgeLo           = $00d3   ; [8] voice age lo
VoiceState       = $00db   ; [8] bit7 playing, bit5 tremolo, bit4 ignore ENDX, bit3 fade, bits0-1 key-on state
VMod             = $00e3   ; [8] bit0 vibrato direction, bit1 muted
QueueRead        = $00eb   ; [1] event ring read index
QueueWrite       = $0202   ; [1] event ring write index
EventQueue       = $0204   ; [64] 16 x 4-byte events (ring)
SyncFlags        = $0264   ; [16] set by sequence commands EC/ED/EE, read by the CPU
StartPan         = $0278   ; [1] start-sound param: pan (bit7 = use header value)
StartVolume      = $0279   ; [1] start-sound param: volume
StartTempoOfs    = $027a   ; [1] start-sound param: tempo offset
ChainList        = $027b   ; [8] 4 x {ID, next ID} - written by system $14, never read
PauseState       = $0283   ; [1] 0 run, $40..$7f fading, $80 paused
TmpADSR1         = $0284   ; [1] instrument ADSR1/GAIN being started
TmpADSR2         = $0285   ; [1] instrument ADSR2 being started
TmpSRCN          = $0286   ; [1] sample number being started
MasterVolume     = $0287   ; [1] $80+ = full
EchoDelay        = $028b   ; [1] EDL
EchoDelayCur     = $028c   ; [1] compared by SetEchoDelay, always $ff
EchoTimer        = $028d   ; [1] echo start-up countdown ($ff/neg = idle)
EchoPhase        = $028e   ; [1] echo start-up phase 0,1,2
EchoVolLTgt      = $028f   ; [1] EVOL L target
EchoVolRTgt      = $0290   ; [1] EVOL R target
EchoFeedback     = $0291   ; [1] EFB
EchoVolLCur      = $0292   ; [1] EVOL L current
EchoVolRCur      = $0293   ; [1] EVOL R current
PatBaseTmp       = $0294   ; [2] pattern base of the sound being started
TrkNumTmp        = $0296   ; [1] track number counter while starting a sound
BankStart        = $0297   ; [16] 8 registered banks, start words (hi=0: empty)
BankEnd          = $02a7   ; [16] 8 registered banks, end words
TrkStatus        = $02b7   ; [22] bit7 active, bit4 chain, bit3 fade, bit1 stop requested, bit0 muted
TrkPriority      = $02cd   ; [22] priority (&$3f)
TrkSoundID       = $02e3   ; [22] sound ID (handle); >= $e0 = music
TrkProgram       = $02f9   ; [22] instrument number
TrkFlags         = $030f   ; [22] bit0 no velocity bytes, bit1 no early-end, bit2 order list, bit3 mono, bit4 (bug), bit5 surround, bit7 E3 loops
TrkPtrLo         = $0325   ; [22] sequence pointer lo
TrkPtrHi         = $033b   ; [22] sequence pointer hi
TrkListHi        = $0351   ; [22] order-list pointer hi
TrkListLo        = $0367   ; [22] order-list pointer lo
TrkLoopPtrHi     = $037d   ; [22] loop point hi
TrkLoopPtrLo     = $0393   ; [22] loop point lo
TrkLoopListHi    = $03a9   ; [22] order-list pointer at loop point hi
TrkLoopListLo    = $03bf   ; [22] order-list pointer at loop point lo
TrkNumber        = $03d5   ; [22] track number inside its sound (1..n)
TrkBendHi        = $03eb   ; [22] pitch bend, semitones (signed)
TrkBendLo        = $0401   ; [22] pitch bend, fraction
TrkTempoLo       = $0417   ; [22] tempo 8.8 fraction
TrkTempoHi       = $042d   ; [22] tempo 8.8 integer
TrkVelocity      = $0443   ; [22] velocity scale
TrkVolume        = $0459   ; [22] volume
TrkTranspose     = $046f   ; [22] transpose
TrkKeyOffset     = $0485   ; [22] key offset (from start event / system $5n)
TrkPan           = $049b   ; [22] pan
TrkTempoOfs      = $04b1   ; [22] tempo offset
VBendLo          = $04c7   ; [8]
VBendHi          = $04cf   ; [8]
VSRCN            = $04d7   ; [8]
VVolL            = $04df   ; [8]
VVolR            = $04e7   ; [8]
VPriority        = $04ef   ; [8]
VPrevEnvx        = $04f7   ; [8]
VRelFlags        = $04ff   ; [8] bit7 released, bit0 one-shot, bit1 GAIN $b7, bit2 GAIN $b0 (else $bf)
VFlags           = $0507   ; [8] copy of TrkFlags
VTrkNumber       = $050f   ; [8]
VNote            = $0517   ; [8]
VVelocity        = $051f   ; [8]
VTrack           = $0527   ; [8] owning track
VVibRate         = $052f   ; [8]
VVibDepth        = $0537   ; [8]
VVibDelay        = $053f   ; [8]
VVibOffset       = $0547   ; [8]
VTremDepth       = $054f   ; [8]
VTremDelay       = $0557   ; [8]
VTremPhase       = $055f   ; [8]
VVolume          = $0567   ; [8]
VVelScale        = $056f   ; [8]
VVelocityAdj     = $0577   ; [8] velocity after instrument sensitivity
InstSRCN         = $1e00   ; [128] sample ($ff empty, $f8-$fe key split)
InstADSR1        = $1e80   ; [128] ADSR1 / GAIN / key-split ptr lo
InstADSR2        = $1f00   ; [128] ADSR2 / key-split ptr hi
InstFlags        = $1f80   ; [128] b0 echo b1 tremolo b2 ADSR b3 noise b4 ignore ENDX b5 rel $b7 b6 one-shot
InstTranspose    = $2000   ; [128]
InstFineTune     = $2080   ; [128]
InstFlags2       = $2100   ; [128] b0 P(L) coarse, b3 vibrato, b4-7 tremolo rate
InstVelTrem      = $2180   ; [128] b0-3 velocity sensitivity, b4-7 tremolo depth
InstVibrato      = $2200   ; [128] b0-3 vibrato step, b4-7 depth
InstModDelay     = $2280   ; [128] vibrato/tremolo delay (nibble-swapped /2)
SampleDir        = $2300   ; [256] DIR
VEnvxStatus      = $ff08   ; [8]
VActiveMask      = $ff10   ; [1]
VTranspose       = $ff12   ; [8]
VKeyOffset       = $ff1a   ; [8]
VBaseNote        = $ff22   ; [8]
VFineTune        = $ff2a   ; [8]
VInstFlags2      = $ff32   ; [8]
VPan             = $ff3a   ; [8]
VOwnerTrack      = $ff42   ; [8]
TrkPatBaseHi     = $ff4a   ; [22]
TrkPatBaseLo     = $ff60   ; [22]
TrkTempo         = $ff76   ; [22] raw tempo byte
VChanVol         = $ff8c   ; [8]
TrkChanVol       = $ff94   ; [22]

; =============================================================================
; IoCmdDispatch - CPU->APU command dispatcher (called from PollCPU, X = command)
;  X = raw value the 65816 wrote to APUIO0. Only even values $02..$16 are valid.
;  NOTE: the jmp operand is $0581, not $0583. Command $00 would fetch the
;  pointer from the operand bytes of this very instruction (never happens:
;  PollCPU treats $00 as "no command"), so the real table starts at $0583.
; =============================================================================
IoCmdDispatch:
0580: 1f 81 05  jmp    (IoCmdTable-2+x)      ; jump through IoCmdTable-2

IoCmdTable:
0583: 6d 19     dw     IoCmd_02_WriteBytes   ; $02 write byte stream
0585: 12 1a     dw     IoCmd_04_BlockUpload  ; $04 block upload
0587: 93 19     dw     IoCmd_06_ReadBytes    ; $06 read byte stream
0589: 8a 19     dw     IoCmd_08_AckRead      ; $08 clear sync bit + read
058b: ad 19     dw     IoCmd_0A_QueueEvents  ; $0A queue events
058d: 61 19     dw     IoCmd_0C_Reboot       ; $0C reboot to IPL
058f: 06 1a     dw     IoCmd_0E_LoadParams   ; $0E set load params + upload
0591: 33 1a     dw     IoCmd_10_InstallSamples ; $10 install samples
0593: 8d 1a     dw     IoCmd_12_InstallBank  ; $12 install sound bank
0595: de 1a     dw     IoCmd_14_InstallInstruments ; $14 install instruments
0597: 90 19     dw     IoCmd_16_VoiceStatus  ; $16 voice status + read

; =============================================================================
; QueueEventDispatch - event-queue dispatcher (X = event type * 2)
; =============================================================================
QueueEventDispatch:
0599: 1f 9c 05  jmp    (QueueEventTable+x)

QueueEventTable:
059c: 52 1c     dw     QEv_Midi              ; 0 MIDI message
059e: a8 10     dw     QEv_System            ; 1 system
05a0: e3 1b     dw     QEv_StartSound        ; 2 start sound
05a2: 01 1c     dw     QEv_Nop               ; 3 no-op
05a4: d7 1b     dw     QEv_RestartSound      ; 4 restart sound

; =============================================================================
; TrkParamDispatch - "set parameter" on a TRACK.  X = param index*2,
;  Y = track index (0-21), A = value.  See TrkParamTable.
; =============================================================================
TrkParamDispatch:
05a6: 1f a9 05  jmp    (TrkParamTable+x)

TrkParamTable:
05a9: b4 14     dw     TP_Volume             ; $00 volume
05ab: b8 14     dw     TP_Pan                ; $02 pan
05ad: dc 14     dw     TP_KeyOffset          ; $04 key offset
05af: c0 14     dw     TP_TempoOffset        ; $06 tempo offset
05b1: cd 14     dw     TP_Velocity           ; $08 velocity
05b3: d1 14     dw     TP_PitchBend          ; $0A pitch bend
05b5: bc 14     dw     TP_Transpose          ; $0C transpose
05b7: e0 14     dw     TP_Program            ; $0E program
05b9: e4 14     dw     TP_Mute               ; $10 mute
05bb: f9 14     dw     TP_Flags              ; $12 flags
05bd: 10 15     dw     TP_Ret                ; $14 pause/resume
05bf: d0 14     dw     TP_Nop                ; $16 refresh volume
05c1: b0 14     dw     TP_ChanVolume         ; $18 channel volume

; =============================================================================
; VoiceParamDispatch - same parameter indexes, applied to a sounding VOICE.
;  X = param index*2, Y = voice (0-7), A = value.  See VoiceParamTable.
; =============================================================================
VoiceParamDispatch:
05c3: 1f c6 05  jmp    (VoiceParamTable+x)

VoiceParamTable:
05c6: 16 15     dw     VP_Volume             ; $00 volume
05c8: 1d 15     dw     VP_Pan                ; $02 pan
05ca: 3a 15     dw     VP_KeyOffset          ; $04 key offset
05cc: 1c 15     dw     VP_Nop                ; $06 tempo offset
05ce: 22 15     dw     VP_Velocity           ; $08 velocity
05d0: 2e 15     dw     VP_PitchBend          ; $0A pitch bend
05d2: 27 15     dw     VP_Transpose          ; $0C transpose
05d4: 1c 15     dw     VP_Nop                ; $0E program
05d6: 3f 15     dw     VP_Mute               ; $10 mute
05d8: 55 15     dw     VP_Flags              ; $12 flags
05da: 70 15     dw     VP_Pause              ; $14 pause/resume
05dc: 19 15     dw     VP_UpdateVolume       ; $16 refresh volume
05de: 11 15     dw     VP_ChanVolume         ; $18 channel volume

Unused05E0:
05e0: db    $00                              ; unused

VoiceDspBase:
05e1: db    $00,$10,$20,$30,$40,$50,$60,$70  ; DSP register base of voice 0-7

VoiceBitMask:
05e9: db    $01,$02,$04,$08,$10,$20,$40,$80  ; bit mask of voice 0-7

; (variable) instrument number currently being set up by VoiceNoteOn.
; The .bin holds $3d here, the SPC snapshot $2b - it is RAM, not code/data.
CurInstrument:
05f1: db    $3d                              ; variable (snapshot value in the SPC: $2b)

; =============================================================================
; VoiceNoteOn - set up hardware voice X for a note and key it on.
;  In : A = note number, X = voice, $1c = owning track, $3a = velocity,
;       $44 = extra transpose (always 0 here)
;  Out: C=1 -> failed (no instrument / empty key-split slot), voice freed
; =============================================================================
VoiceNoteOn:
05f2: c4 39     mov    NoteNum,a             ; NoteNum = note
05f4: d8 1d     mov    CurVoice,x            ; CurVoice
05f6: f5 e9 05  mov    a,VoiceBitMask+x      ; voice bit
05f9: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF = this voice (cut previous note)
05fc: c4 f3     mov    DSPDATA,a
05fe: c4 35     mov    VoiceBit,a            ; remember voice bit for KON/EON/NON
0600: eb 1c     mov    y,CurTrack
0602: f6 f9 02  mov    a,TrkProgram+y        ; TrkProgram[track]
0605: 68 ff     cmp    a,#$ff                ; $ff = no instrument assigned
0607: d0 08     bne    L0611
.fail:
0609: f4 db     mov    a,VoiceState+x        ; clear key-on state bits (and fade bit)
060b: 28 7c     and    a,#$7c
060d: d4 db     mov    VoiceState+x,a
060f: 80        setc                         ; C=1 : failure
0610: 6f        ret

L0611:
0611: c5 f1 05  mov    CurInstrument,a       ; CurInstrument = program
0614: fd        mov    y,a
0615: f6 80 1e  mov    a,InstADSR1+y         ; InstADSR1
0618: c5 84 02  mov    TmpADSR1,a
061b: f6 00 1f  mov    a,InstADSR2+y         ; InstADSR2
061e: c5 85 02  mov    TmpADSR2,a
0621: f6 00 1e  mov    a,InstSRCN+y          ; InstSRCN
0624: c5 86 02  mov    TmpSRCN,a
0627: 10 0d     bpl    L0636                 ; SRCN < $80 : ordinary sample
0629: 68 f8     cmp    a,#$f8                ; $80..$f7 : also ordinary sample
062b: 90 09     bcc    L0636
062d: 68 ff     cmp    a,#$ff                ; $ff = empty instrument slot
062f: f0 d8     beq    .fail
0631: 3f ad 07  call   KeySplitLookup        ; $f8..$fe : key-split / drum map
0634: b0 d3     bcs    .fail

L0636:
0636: eb 1c     mov    y,CurTrack            ; copy TRACK status bit3 (fade) into voice state
0638: f6 b7 02  mov    a,TrkStatus+y
063b: 28 08     and    a,#$08
063d: 14 db     or     a,VoiceState+x
063f: d4 db     mov    VoiceState+x,a
0641: ec f1 05  mov    y,CurInstrument       ; velocity sensitivity (InstVelTrem low nibble)
0644: f6 80 21  mov    a,InstVelTrem+y
0647: bc        inc    a                     ; (n+1)&$f ; n=$f -> 0 -> raw velocity
0648: 28 0f     and    a,#$0f
064a: f0 08     beq    L0654
064c: 9f        xcn    a                     ; A = (n+1)*16
064d: eb 3a     mov    y,Velocity
064f: cf        mul    ya                    ; Y = velocity * (n+1)/16
0650: dd        mov    a,y
0651: 5f 56 06  jmp    L0656

L0654:
0654: e4 3a     mov    a,Velocity            ; no scaling: raw velocity

L0656:
0656: d5 77 05  mov    VVelocityAdj+x,a      ; VVelocityAdj
0659: eb 1c     mov    y,CurTrack
065b: f6 43 04  mov    a,TrkVelocity+y       ; TrkVelocity -> VVelScale
065e: d5 6f 05  mov    VVelScale+x,a
0661: f6 59 04  mov    a,TrkVolume+y         ; TrkVolume -> VVolume
0664: 28 7f     and    a,#$7f
0666: d5 67 05  mov    VVolume+x,a
0669: f6 94 ff  mov    a,TrkChanVol+y        ; TrkChanVol -> VChanVol
066c: d5 8c ff  mov    VChanVol+x,a
066f: f6 9b 04  mov    a,TrkPan+y            ; TrkPan -> VPan
0672: d5 3a ff  mov    VPan+x,a
0675: 4d        push   x
0676: 7d        mov    a,x
0677: fd        mov    y,a
0678: 3f 84 15  call   CalcVoiceVolume       ; compute + write VOL L/R
067b: ce        pop    x
067c: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF = 0
067f: 8f 00 f3  mov    DSPDATA,#$00
0682: f5 e1 05  mov    a,VoiceDspBase+x      ; X = DSP base of voice
0685: 5d        mov    x,a
0686: ec f1 05  mov    y,CurInstrument
0689: f6 80 1f  mov    a,InstFlags+y         ; InstFlags
068c: c4 3e     mov    InstFlagsTmp,a
068e: 3d        inc    x                     ; X = voice base + 2 (P(L))
068f: 3d        inc    x
0690: 4d        push   x
0691: d8 f2     mov    DSPADDR,x
0693: f8 1d     mov    x,CurVoice
0695: e8 00     mov    a,#$00                ; clear vibrato offset
0697: d5 47 05  mov    VVibOffset+x,a
069a: f6 00 21  mov    a,InstFlags2+y        ; InstFlags2 -> VInstFlags2
069d: d5 32 ff  mov    VInstFlags2+x,a
06a0: 28 08     and    a,#$08                ; bit3 = vibrato enabled
06a2: f0 1c     beq    L06C0
06a4: f6 80 22  mov    a,InstModDelay+y      ; InstModDelay : nibble-swap, /2 = delay
06a7: 9f        xcn    a
06a8: 5c        lsr    a
06a9: d5 3f 05  mov    VVibDelay+x,a         ; VVibDelay
06ac: f6 00 22  mov    a,InstVibrato+y       ; InstVibrato
06af: d5 2f 05  mov    VVibRate+x,a          ; VVibRate (low nibble = step)
06b2: 28 f0     and    a,#$f0                ; high nibble >> 1 | 7 = depth
06b4: 5c        lsr    a
06b5: 08 07     or     a,#$07
06b7: d5 37 05  mov    VVibDepth+x,a         ; VVibDepth
06ba: f4 e3     mov    a,VMod+x              ; vibrato direction = down
06bc: 28 fe     and    a,#$fe
06be: d4 e3     mov    VMod+x,a

L06C0:
06c0: 33 3e 16  bbc1   InstFlagsTmp,L06D9    ; InstFlags bit1 = tremolo enabled
06c3: f6 80 22  mov    a,InstModDelay+y      ; same delay byte
06c6: 9f        xcn    a
06c7: 5c        lsr    a
06c8: d5 57 05  mov    VTremDelay+x,a        ; VTremDelay
06cb: f6 80 21  mov    a,InstVelTrem+y       ; InstVelTrem high nibble = tremolo depth
06ce: 9f        xcn    a
06cf: 28 0f     and    a,#$0f
06d1: d5 4f 05  mov    VTremDepth+x,a        ; VTremDepth
06d4: e8 00     mov    a,#$00
06d6: d5 5f 05  mov    VTremPhase+x,a        ; VTremPhase = 0

L06D9:
06d9: f6 00 20  mov    a,InstTranspose+y     ; InstTranspose
06dc: 60        clrc
06dd: 84 39     adc    a,NoteNum             ; + note
06df: 60        clrc
06e0: 84 44     adc    a,HdrTranspose        ; + extra transpose
06e2: c4 06     mov    $06,a
06e4: f8 1d     mov    x,CurVoice
06e6: d5 22 ff  mov    VBaseNote+x,a         ; VBaseNote
06e9: f6 80 20  mov    a,InstFineTune+y      ; InstFineTune -> VFineTune
06ec: d5 2a ff  mov    VFineTune+x,a
06ef: eb 1c     mov    y,CurTrack
06f1: f6 85 04  mov    a,TrkKeyOffset+y      ; TrkKeyOffset -> VKeyOffset
06f4: d5 1a ff  mov    VKeyOffset+x,a
06f7: 73 3e 24  bbc3   InstFlagsTmp,L071E    ; InstFlags bit3 = noise voice
06fa: 60        clrc                         ; note used as noise clock: base note + key offset - 24
06fb: 84 06     adc    a,$06
06fd: 2d        push   a
06fe: 80        setc
06ff: a8 18     sbc    a,#$18
0701: 10 02     bpl    L0705
0703: e8 00     mov    a,#$00

L0705:
0705: 68 1f     cmp    a,#$1f                ; clamp to $1f
0707: 90 02     bcc    L070B
0709: e8 1f     mov    a,#$1f

L070B:
070b: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
070e: e9 8d 02  mov    x,EchoTimer           ; echo still starting up?
0711: 30 02     bmi    L0715
0713: 08 20     or     a,#$20                ; yes: keep ECEN (echo write disable) set

L0715:
0715: c4 43     mov    FlgShadow,a           ; FLG shadow
0717: c4 f3     mov    DSPDATA,a
0719: ae        pop    a
071a: ce        pop    x
071b: d8 f2     mov    DSPADDR,x
071d: 4d        push   x

L071E:
071e: e5 86 02  mov    a,TmpSRCN             ; sample number
0721: eb 1d     mov    y,CurVoice
0723: d6 d7 04  mov    VSRCN+y,a             ; VSRCN
0726: 3f 3f 16  call   CalcVoicePitch        ; compute + write pitch
0729: ce        pop    x
072a: 3d        inc    x                     ; X = base+4 (SRCN)
072b: 3d        inc    x
072c: d8 f2     mov    DSPADDR,x
072e: ec f1 05  mov    y,CurInstrument
0731: e5 86 02  mov    a,TmpSRCN
0734: c4 f3     mov    DSPDATA,a
0736: 43 3e 12  bbs2   InstFlagsTmp,L074B    ; InstFlags bit2 : ADSR (1) or GAIN (0)
0739: 3d        inc    x                     ; GAIN mode: ADSR1 = 0 ...
073a: d8 f2     mov    DSPADDR,x
073c: 8f 00 f3  mov    DSPDATA,#$00
073f: 3d        inc    x
0740: 3d        inc    x
0741: d8 f2     mov    DSPADDR,x
0743: e5 84 02  mov    a,TmpADSR1            ; ... GAIN = "ADSR1" byte of instrument
0746: c4 f3     mov    DSPDATA,a
0748: 5f 5d 07  jmp    L075D

L074B:
074b: 3d        inc    x                     ; ADSR mode: ADSR1 | $80 (enable)
074c: d8 f2     mov    DSPADDR,x
074e: e5 84 02  mov    a,TmpADSR1
0751: 08 80     or     a,#$80
0753: c4 f3     mov    DSPDATA,a
0755: 3d        inc    x                     ; ADSR2
0756: d8 f2     mov    DSPADDR,x
0758: e5 85 02  mov    a,TmpADSR2
075b: c4 f3     mov    DSPDATA,a

L075D:
075d: f8 1d     mov    x,CurVoice            ; build release flags (VRelFlags)
075f: e8 00     mov    a,#$00
0761: d3 3e 02  bbc6   InstFlagsTmp,L0766    ; InstFlags bit6 -> bit2 ($b0 release) ...
0764: 08 04     or     a,#$04

L0766:
0766: b3 3e 07  bbc5   InstFlagsTmp,L0770    ; InstFlags bit5 -> bit1 ($b7 release)
0769: 08 02     or     a,#$02
076b: d3 3e 02  bbc6   InstFlagsTmp,L0770    ; InstFlags bit6 -> bit0 (no key-off: one-shot)
076e: 08 01     or     a,#$01

L0770:
0770: d5 ff 04  mov    VRelFlags+x,a         ; VRelFlags
0773: f5 32 ff  mov    a,VInstFlags2+x
0776: c4 08     mov    $08,a
0778: f4 db     mov    a,VoiceState+x
077a: 93 3e 02  bbc4   InstFlagsTmp,L077F    ; InstFlags bit4 -> state bit4 (ignore ENDX)
077d: 08 10     or     a,#$10

L077F:
077f: 33 3e 02  bbc1   InstFlagsTmp,L0784    ; InstFlags bit1 -> state bit5 (tremolo running)
0782: 08 20     or     a,#$20

L0784:
0784: d4 db     mov    VoiceState+x,a
0786: 09 35 37  or     (EonShadow),(VoiceBit) ; EON shadow |= voice
0789: 03 3e 03  bbs0   InstFlagsTmp,L078F    ; InstFlags bit0 = echo on
078c: 49 35 37  eor    (EonShadow),(VoiceBit) ; ... else remove voice from EON

L078F:
078f: 8f 4d f2  mov    DSPADDR,#$4d          ; EON
0792: fa 37 f3  mov    (DSPDATA),(EonShadow)
0795: 09 35 36  or     (NonShadow),(VoiceBit) ; NON shadow |= voice
0798: 63 3e 03  bbs3   InstFlagsTmp,L079E    ; InstFlags bit3 = noise
079b: 49 35 36  eor    (NonShadow),(VoiceBit)

L079E:
079e: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
07a1: fa 36 f3  mov    (DSPDATA),(NonShadow)
07a4: 8f 4c f2  mov    DSPADDR,#$4c          ; KON = voice  -> note starts
07a7: fa 35 f3  mov    (DSPDATA),(VoiceBit)
07aa: f8 1d     mov    x,CurVoice
07ac: 6f        ret

; =============================================================================
; KeySplitLookup - resolve a key-split / drum-map instrument (SRCN $f8-$fe)
;  Record pointed to by InstADSR1/InstADSR2 (lo/hi):
;    +0 ADSR1   +1 ADSR2   +2 n = number of zones
;    +3.. n * { key, target, flags }
;      key    : note that selects this zone (exact match)
;      target : bit7=1 -> SRCN = target&$7f (keep this record's ADSR)
;               bit7=0 -> use instrument #target (its ADSR/SRCN/params)
;      flags  : bits0-2 : zone also answers key+1, pitch += (flags&7)
;               bit3    : zone also answers key+1..key+4 (pitch +6,+11,+15,+0)
;               bit4    : zone also answers key+1..key+5 (pitch +6,+9,+12,+15,
;                         and +32 = a byte read past the table - range off by one)
;               bits5-7 : extra pitch offset added (0-7 semitones)
;  The note is replaced by 60 (C-4) + offsets, i.e. drums play at base pitch.
;  Out: C=0 found, C=1 not found.  First matching zone wins.
; =============================================================================
KeySplitLookup:
07ad: 4d        push   x
07ae: 6d        push   y
07af: f6 80 1e  mov    a,InstADSR1+y         ; pointer lo
07b2: c4 0c     mov    $0c,a
07b4: f6 00 1f  mov    a,InstADSR2+y         ; pointer hi
07b7: c4 0d     mov    $0d,a
07b9: 8d 00     mov    y,#$00
07bb: f7 0c     mov    a,($0c)+y             ; +0 -> ADSR1
07bd: c5 84 02  mov    TmpADSR1,a
07c0: fc        inc    y
07c1: f7 0c     mov    a,($0c)+y             ; +1 -> ADSR2
07c3: c5 85 02  mov    TmpADSR2,a
07c6: fc        inc    y
07c7: f7 0c     mov    a,($0c)+y             ; +2 zone count
07c9: d0 04     bne    L07CF
07cb: ee        pop    y                     ; 0 zones -> fail
07cc: ce        pop    x
07cd: 80        setc
07ce: 6f        ret

L07CF:
07cf: 5d        mov    x,a
07d0: fc        inc    y
07d1: e4 39     mov    a,NoteNum             ; $08 = note
07d3: c4 08     mov    $08,a
07d5: 9c        dec    a                     ; $09 = note-1
07d6: c4 09     mov    $09,a
07d8: 80        setc
07d9: a8 03     sbc    a,#$03                ; $0a = note-4 (bit3 range limit)
07db: c4 0a     mov    $0a,a
07dd: 9c        dec    a                     ; $0b = note-5 (bit4 range limit)
07de: c4 0b     mov    $0b,a
07e0: 8f 3c 39  mov    NoteNum,#$3c          ; NoteNum = 60 (base pitch for drum hits)

L07E3:
07e3: f7 0c     mov    a,($0c)+y             ; zone key
07e5: c4 0e     mov    $0e,a
07e7: fc        inc    y
07e8: f7 0c     mov    a,($0c)+y             ; zone target
07ea: c4 0f     mov    $0f,a
07ec: fc        inc    y
07ed: f7 0c     mov    a,($0c)+y             ; zone flags
07ef: c4 10     mov    $10,a
07f1: fc        inc    y
07f2: 69 08 0e  cmp    ($0e),($08)           ; key == note ?
07f5: f0 29     beq    L0820
07f7: b0 1b     bcs    L0814                 ; key > note : try next zone
07f9: 73 10 05  bbc3   $10,L0801             ; flags bit3 : key >= note-4 ?
07fc: 69 0a 0e  cmp    ($0e),($0a)
07ff: b0 49     bcs    L084A

L0801:
0801: 93 10 05  bbc4   $10,L0809             ; flags bit4 : key >= note-5 ?
0804: 69 0b 0e  cmp    ($0e),($0b)
0807: b0 3c     bcs    L0845

L0809:
0809: e4 10     mov    a,$10                 ; flags bits0-2 : key+1 with fixed offset
080b: 28 07     and    a,#$07
080d: f0 05     beq    L0814
080f: 69 09 0e  cmp    ($0e),($09)
0812: f0 07     beq    L081B

L0814:
0814: 1d        dec    x                     ; next zone
0815: d0 cc     bne    L07E3
0817: ee        pop    y
0818: ce        pop    x
0819: 80        setc
081a: 6f        ret

L081B:
081b: 60        clrc                         ; NoteNum += flags&7
081c: 84 39     adc    a,NoteNum
081e: c4 39     mov    NoteNum,a

L0820:
0820: e4 0f     mov    a,$0f                 ; target
0822: 10 08     bpl    L082C                 ; bit7 clear: instrument number
0824: 28 7f     and    a,#$7f                ; bit7 set: raw sample number
0826: c5 86 02  mov    TmpSRCN,a
0829: 5f 5f 08  jmp    L085F

L082C:
082c: c5 f1 05  mov    CurInstrument,a       ; switch to target instrument
082f: fd        mov    y,a
0830: f6 80 1e  mov    a,InstADSR1+y
0833: c5 84 02  mov    TmpADSR1,a
0836: f6 00 1f  mov    a,InstADSR2+y
0839: c5 85 02  mov    TmpADSR2,a
083c: f6 00 1e  mov    a,InstSRCN+y
083f: c5 86 02  mov    TmpSRCN,a
0842: 5f 5f 08  jmp    L085F

L0845:
0845: 8f 03 11  mov    $11,#$03              ; bit4 zone: index = (note-key)+4  (carry is set after SBC)
0848: 2f 03     bra    L084D

L084A:
084a: 8f ff 11  mov    $11,#$ff              ; bit3 zone: index = (note-key)

L084D:
084d: e4 08     mov    a,$08
084f: 80        setc
0850: a4 0e     sbc    a,$0e
0852: 84 11     adc    a,$11
0854: fd        mov    y,a
0855: f6 6f 08  mov    a,KeySplitOffsetTable+y ; KeySplitOffsetTable
0858: 60        clrc
0859: 84 39     adc    a,NoteNum
085b: c4 39     mov    NoteNum,a
085d: 2f c1     bra    L0820

L085F:
085f: e4 10     mov    a,$10                 ; NoteNum += flags >> 5
0861: 5c        lsr    a
0862: 5c        lsr    a
0863: 5c        lsr    a
0864: 5c        lsr    a
0865: 5c        lsr    a
0866: 60        clrc
0867: 84 39     adc    a,NoteNum
0869: c4 39     mov    NoteNum,a
086b: ee        pop    y
086c: ce        pop    x
086d: 60        clrc                         ; C=0 : found
086e: 6f        ret

; -----------------------------------------------------------------------------
; KeySplitOffsetTable - DATA (SPCdas disassembled these 9 bytes as code:
; "nop / or a,(x) / asl $0f / nop / or a,(x) / or ($0f),($0c)").
; Read by "mov a,$086f+y" at $0855.  [1..4] used by zone flag bit3,
; [5..9] used by zone flag bit4 ([9] is the first byte of Reset, $20).
; [0] is never read.  Looks like two lists {0,6,11,15} {0,6,9,12,15}.
; -----------------------------------------------------------------------------
KeySplitOffsetTable:
086f: db    $00,$06,$0b,$0f,$00,$06,$09,$0c,$0f

; =============================================================================
; Reset - driver entry point (execution starts here after upload)
; =============================================================================
Reset:
0878: 20        clrp
0879: e8 00     mov    a,#$00                ; clear all four output ports
087b: c4 f4     mov    APUIO0,a
087d: c4 f5     mov    APUIO1,a
087f: c4 f6     mov    APUIO2,a
0881: c4 f7     mov    APUIO3,a
0883: cd ff     mov    x,#$ff                ; stack = $01ff
0885: bd        mov    sp,x
0886: 5d        mov    x,a                   ; clear $00-$ef

L0887:
0887: af        mov    (x)+,a
0888: c8 f0     cmp    x,#$f0
088a: d0 fb     bne    L0887
088c: fd        mov    y,a                   ; clear $0100-$04ff

L088D:
088d: d6 00 01  mov    $0100+y,a
0890: d6 00 02  mov    $0200+y,a
0893: d6 00 03  mov    TrkProgram+7+y,a
0896: d6 00 04  mov    TrkBendHi+21+y,a
0899: fe f2     dbnz   y,L088D
089b: fd        mov    y,a                   ; fill instrument tables $1e00-$21ff with $ff (= "empty")
089c: 9c        dec    a

L089D:
089d: d6 00 1e  mov    InstSRCN+y,a
08a0: d6 00 1f  mov    InstADSR2+y,a
08a3: d6 00 20  mov    InstTranspose+y,a
08a6: d6 00 21  mov    InstFlags2+y,a
08a9: fe f2     dbnz   y,L089D
08ab: e8 01     mov    a,#$01                ; StereoMode = 1 (stereo)
08ad: c4 25     mov    StereoMode,a          ; HandshakeCnt = 1
08af: c4 40     mov    HandshakeCnt,a
08b1: 8f 23 27  mov    DirPage,#$23          ; DirPage = $23 (sample directory at $2300)
08b4: 8f 00 26  mov    $26,#$00
08b7: 3f ed 0b  call   InitDSP               ; DSP / timer init
08ba: e8 ff     mov    a,#$ff                ; ChainList = empty
08bc: c5 7b 02  mov    ChainList,a
08bf: c5 7d 02  mov    ChainList+2,a
08c2: c5 7f 02  mov    ChainList+4,a
08c5: c5 81 02  mov    ChainList+6,a
08c8: e8 80     mov    a,#$80                ; MasterVolume = $80 (full)
08ca: c5 87 02  mov    MasterVolume,a
08cd: 8f 00 2e  mov    TicksElapsed,#$00

; =============================================================================
; MainLoop - one iteration per 8 ms timer-0 tick
; =============================================================================
MainLoop:
08d0: 3f ae 1b  call   ProcessEventQueue     ; execute queued events from the 65816
08d3: 38 fd 45  and    Status,#$fd           ; status bit1 = 0 (queue drained)
08d6: fa 45 f6  mov    (APUIO2),(Status)     ; publish status on APUIO2
.waitTimer:
08d9: e4 fd     mov    a,T0OUT               ; T0OUT : ticks since last read (clears on read)
08db: d0 06     bne    L08E3
08dd: 3f 2e 19  call   PollCPU               ; no tick yet: service CPU commands meanwhile
08e0: 5f d9 08  jmp    .waitTimer

L08E3:
08e3: c4 2e     mov    TicksElapsed,a        ; TicksElapsed
08e5: ab 48     inc    FrameCounter          ; FrameCounter++
08e7: 3f d3 13  call   ProcessFades          ; volume fades

; --- echo start-up state machine (after SetEchoDelay) ---------------------
08ea: e5 8d 02  mov    a,EchoTimer           ; EchoTimer negative : idle
08ed: 10 03     bpl    L08F2
08ef: 5f 76 09  jmp    .voices

L08F2:
08f2: 8c 8d 02  dec    EchoTimer             ; count down
08f5: 30 03     bmi    L08FA
08f7: 5f 76 09  jmp    .voices

L08FA:
08fa: e5 8e 02  mov    a,EchoPhase           ; phase 0 -> 1 : enable echo writes, wait $28 more ticks
08fd: d0 17     bne    L0916
08ff: bc        inc    a
0900: c5 8e 02  mov    EchoPhase,a
0903: e8 28     mov    a,#$28
0905: c5 8d 02  mov    EchoTimer,a
0908: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG: clear ECEN (bit5) and noise bits
090b: e4 43     mov    a,FlgShadow
090d: 28 1f     and    a,#$1f
090f: c4 43     mov    FlgShadow,a
0911: c4 f3     mov    DSPDATA,a
0913: 5f 76 09  jmp    .voices

L0916:
0916: 68 01     cmp    a,#$01                ; phase 1 -> 2 : write feedback
0918: d0 0c     bne    L0926
091a: bc        inc    a
091b: c5 8e 02  mov    EchoPhase,a
091e: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
0921: e5 91 02  mov    a,EchoFeedback
0924: c4 f3     mov    DSPDATA,a

L0926:
0926: 8d ff     mov    y,#$ff                ; phase 2 : ramp EVOL L/R toward targets by 1 per tick
0928: e5 8f 02  mov    a,EchoVolLTgt
092b: 10 0d     bpl    L093A
092d: 65 92 02  cmp    a,EchoVolLCur
0930: f0 05     beq    L0937
0932: 8c 92 02  dec    EchoVolLCur
0935: 8d 00     mov    y,#$00

L0937:
0937: 5f 44 09  jmp    L0944

L093A:
093a: 65 92 02  cmp    a,EchoVolLCur
093d: f0 05     beq    L0944
093f: ac 92 02  inc    EchoVolLCur
0942: 8d 00     mov    y,#$00

L0944:
0944: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
0947: e5 92 02  mov    a,EchoVolLCur
094a: c4 f3     mov    DSPDATA,a
094c: e5 90 02  mov    a,EchoVolRTgt
094f: 10 0d     bpl    L095E
0951: 65 93 02  cmp    a,EchoVolRCur
0954: f0 05     beq    L095B
0956: 8c 93 02  dec    EchoVolRCur
0959: 8d 00     mov    y,#$00

L095B:
095b: 5f 68 09  jmp    L0968

L095E:
095e: 65 93 02  cmp    a,EchoVolRCur
0961: f0 05     beq    L0968
0963: ac 93 02  inc    EchoVolRCur
0966: 8d 00     mov    y,#$00

L0968:
0968: c5 93 02  mov    EchoVolRCur,a         ; (EchoVolRCur = target, harmless)
096b: cc 8d 02  mov    EchoTimer,y           ; EchoTimer = 0 while ramping, $ff when both reached
096e: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
0971: e5 93 02  mov    a,EchoVolRCur
0974: c4 f3     mov    DSPDATA,a

; --- per-voice processing, voice 7 down to 0 ----------------------------
.voices:
0976: 8f 7c f2  mov    DSPADDR,#$7c          ; ENDX
0979: e4 f3     mov    a,DSPDATA
097b: c4 42     mov    EndxLatch,a           ; latch ENDX (shifted left once per voice)
097d: 8f 00 f3  mov    DSPDATA,#$00          ; clear ENDX
0980: 8f 70 1e  mov    CurVoiceDsp,#$70      ; DSP base of voice 7
0983: 8f 80 35  mov    VoiceBit,#$80         ; voice bit of voice 7
0986: cd 07     mov    x,#$07

VoiceLoop:
0988: 3f 2e 19  call   PollCPU
098b: d8 1d     mov    CurVoice,x
098d: f4 db     mov    a,VoiceState+x        ; state copy
098f: c4 30     mov    VState,a
0991: e5 83 02  mov    a,PauseState          ; PauseState
0994: d0 20     bne    .paused
0996: bb d3     inc    VAgeLo+x              ; voice age++ (16 bit, used for voice stealing)
0998: d0 02     bne    L099C
099a: bb cb     inc    VAgeHi+x

L099C:
099c: f4 db     mov    a,VoiceState+x        ; key-on state (bits0-1)
099e: 28 03     and    a,#$03
09a0: f0 11     beq    L09B3                 ; 0 : nothing pending
09a2: 9c        dec    a
09a3: f0 08     beq    L09AD                 ; 1 : key-on now
09a5: 38 fc 30  and    VState,#$fc           ; 2/3 : count down one step (delayed key-on; unused in this build)
09a8: 04 30     or     a,VState
09aa: 5f 2f 0a  jmp    L0A2F

L09AD:
09ad: 3f ba 0e  call   VoiceKeyOn            ; key on the note stored for this voice
09b0: 5f 31 0a  jmp    .nextVoice

L09B3:
09b3: 5f dc 09  jmp    .checkVoice
.paused:
09b6: 30 24     bmi    .checkVoice           ; PauseState >= $80 : fully faded
09b8: f5 e1 05  mov    a,VoiceDspBase+x      ; halve VOL L (arithmetic shift right)
09bb: c4 f2     mov    DSPADDR,a
09bd: aa f3 e0  mov1   c,$00f3,7
09c0: 6b f3     ror    DSPDATA
09c2: 78 ff f3  cmp    DSPDATA,#$ff
09c5: d0 03     bne    L09CA
09c7: 8f 00 f3  mov    DSPDATA,#$00

L09CA:
09ca: ab f2     inc    DSPADDR               ; halve VOL R
09cc: aa f3 e0  mov1   c,$00f3,7
09cf: 6b f3     ror    DSPDATA
09d1: 78 ff f3  cmp    DSPDATA,#$ff
09d4: d0 03     bne    L09D9
09d6: 8f 00 f3  mov    DSPDATA,#$00

L09D9:
09d9: ac 83 02  inc    PauseState            ; PauseState counts $40 -> $80
.checkVoice:
09dc: f3 30 52  bbc7   VState,.nextVoice     ; state bit7 : voice playing?
09df: 83 30 06  bbs4   VState,L09E8          ; state bit4 : ignore ENDX (looped sample)
09e2: f3 42 03  bbc7   EndxLatch,L09E8       ; sample ended (ENDX) ?
09e5: 8f 00 30  mov    VState,#$00           ; -> voice free

L09E8:
09e8: f5 07 05  mov    a,VFlags+x            ; VFlags
09eb: c4 33     mov    CurFlags,a
09ed: b3 30 03  bbc5   VState,L09F3          ; tremolo running?
09f0: 3f 63 17  call   TremoloUpdate

L09F3:
09f3: f5 32 ff  mov    a,VInstFlags2+x       ; VInstFlags2 bit3 = vibrato
09f6: 28 08     and    a,#$08
09f8: f0 03     beq    L09FD
09fa: 3f e2 17  call   VibratoUpdate

L09FD:
09fd: e4 1e     mov    a,CurVoiceDsp         ; ENVX of this voice
09ff: 60        clrc
0a00: 88 08     adc    a,#$08
0a02: c4 f2     mov    DSPADDR,a
0a04: e4 f3     mov    a,DSPDATA
0a06: d0 07     bne    L0A0F
0a08: f5 ff 04  mov    a,VRelFlags+x         ; envelope 0 and already released -> free
0a0b: 28 80     and    a,#$80
0a0d: d0 0c     bne    L0A1B

L0A0F:
0a0f: 75 f7 04  cmp    a,VPrevEnvx+x         ; envelope falling ...
0a12: b0 10     bcs    L0A24
0a14: 68 08     cmp    a,#$08                ; ... below 8 ...
0a16: b0 0c     bcs    L0A24
0a18: 23 33 09  bbs1   CurFlags,L0A24        ; ... and flag bit1 clear -> treat as finished

L0A1B:
0a1b: 8f 00 30  mov    VState,#$00           ; voice free: KOF it
0a1e: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0a21: fa 35 f3  mov    (DSPDATA),(VoiceBit)

L0A24:
0a24: d5 f7 04  mov    VPrevEnvx+x,a         ; VPrevENVX
0a27: f3 30 03  bbc7   VState,L0A2D
0a2a: 3f a9 0a  call   VoiceGateCountdown    ; count down note length

L0A2D:
0a2d: e4 30     mov    a,VState

L0A2F:
0a2f: d4 db     mov    VoiceState+x,a
.nextVoice:
0a31: 0b 42     asl    EndxLatch             ; next ENDX bit
0a33: 4b 35     lsr    VoiceBit              ; next voice bit
0a35: 80        setc
0a36: b8 10 1e  sbc    CurVoiceDsp,#$10      ; next DSP base
0a39: 1d        dec    x
0a3a: 30 03     bmi    L0A3F
0a3c: 5f 88 09  jmp    VoiceLoop

L0A3F:
0a3f: e5 83 02  mov    a,PauseState          ; paused -> skip sequencer
0a42: f0 03     beq    TrackLoop
0a44: 5f d0 08  jmp    MainLoop

; --- per-track sequencer, track 21 down to 0 ----------------------------
TrackLoop:
0a47: 8f 15 1c  mov    CurTrack,#$15

L0A4A:
0a4a: 3f 2e 19  call   PollCPU
0a4d: f8 1c     mov    x,CurTrack
0a4f: f4 4b     mov    a,TrkTimerHi+x        ; timer negative -> sequence disabled (e.g. MIDI track)
0a51: 30 39     bmi    L0A8C
0a53: f5 b7 02  mov    a,TrkStatus+x         ; TrkStatus bit7 : active?
0a56: 28 80     and    a,#$80
0a58: f0 32     beq    L0A8C
0a5a: 3f 93 0a  call   CalcTempoStep         ; $08/$09 = tempo * ticks
0a5d: 80        setc                         ; TrkTimer -= step (32-bit, $8d = fraction)
0a5e: f4 8d     mov    a,TrkTimerFrac+x
0a60: a4 08     sbc    a,$08
0a62: d4 8d     mov    TrkTimerFrac+x,a
0a64: f4 77     mov    a,TrkTimerLo+x
0a66: a4 09     sbc    a,$09
0a68: d4 77     mov    TrkTimerLo+x,a
0a6a: f4 61     mov    a,TrkTimerMid+x
0a6c: a8 00     sbc    a,#$00
0a6e: d4 61     mov    TrkTimerMid+x,a
0a70: f4 4b     mov    a,TrkTimerHi+x
0a72: a8 00     sbc    a,#$00
0a74: d4 4b     mov    TrkTimerHi+x,a
.runEvents:
0a76: f4 4b     mov    a,TrkTimerHi+x        ; timer <= 0 -> run events
0a78: 30 08     bmi    L0A82
0a7a: 14 61     or     a,TrkTimerMid+x
0a7c: 14 77     or     a,TrkTimerLo+x
0a7e: 14 8d     or     a,TrkTimerFrac+x
0a80: d0 0a     bne    L0A8C

L0A82:
0a82: 3f c2 0c  call   ProcessTrackEvents    ; process events (adds next delta)
0a85: f5 b7 02  mov    a,TrkStatus+x         ; still active?
0a88: 28 80     and    a,#$80
0a8a: d0 ea     bne    .runEvents

L0A8C:
0a8c: 8b 1c     dec    CurTrack              ; next track
0a8e: 10 ba     bpl    L0A4A
0a90: 5f d0 08  jmp    MainLoop

; =============================================================================
; CalcTempoStep - $08/$09 = TrkTempo(8.8) * TicksElapsed   (X = track)
; =============================================================================
CalcTempoStep:
0a93: f5 2d 04  mov    a,TrkTempoHi+x
0a96: eb 2e     mov    y,TicksElapsed
0a98: cf        mul    ya
0a99: c4 09     mov    $09,a
0a9b: 8f 00 08  mov    $08,#$00
0a9e: eb 2e     mov    y,TicksElapsed
0aa0: f5 17 04  mov    a,TrkTempoLo+x
0aa3: cf        mul    ya
0aa4: 7a 08     addw   ya,$08
0aa6: da 08     movw   $08,ya
0aa8: 6f        ret

; =============================================================================
; VoiceGateCountdown - count down the note length (gate) of voice X
;  VGate ($ab/$b3/$bb/$c3) is decremented with the owning track's tempo.
;  VGate hi bit7 set = infinite (no countdown).  At zero: key release.
; =============================================================================
VoiceGateCountdown:
0aa9: f4 ab     mov    a,VGateHi+x           ; negative : sustain forever
0aab: 10 01     bpl    L0AAE

L0AAD:
0aad: 6f        ret

L0AAE:
0aae: e5 83 02  mov    a,PauseState          ; paused -> nothing
0ab1: d0 fa     bne    L0AAD
0ab3: 4d        push   x
0ab4: f5 27 05  mov    a,VTrack+x            ; owning track
0ab7: 5d        mov    x,a
0ab8: 3f 93 0a  call   CalcTempoStep
0abb: ce        pop    x
0abc: 80        setc
0abd: f4 c3     mov    a,VGateFrac+x
0abf: a4 08     sbc    a,$08
0ac1: d4 c3     mov    VGateFrac+x,a
0ac3: f4 bb     mov    a,VGateLo+x
0ac5: a4 09     sbc    a,$09
0ac7: d4 bb     mov    VGateLo+x,a
0ac9: f4 b3     mov    a,VGateMid+x
0acb: a8 00     sbc    a,#$00
0acd: d4 b3     mov    VGateMid+x,a
0acf: b0 04     bcs    L0AD5
0ad1: 9b ab     dec    VGateHi+x
0ad3: 30 09     bmi    .gateExpired

L0AD5:
0ad5: 14 c3     or     a,VGateFrac+x
0ad7: 14 bb     or     a,VGateLo+x
0ad9: 14 ab     or     a,VGateHi+x
0adb: f0 01     beq    .gateExpired
0add: 6f        ret
.gateExpired:
0ade: f5 ff 04  mov    a,VRelFlags+x         ; VRelFlags
0ae1: c4 08     mov    $08,a
0ae3: 13 08 09  bbc0   $08,L0AEF             ; bit0 : one-shot - don't release,
0ae6: e8 00     mov    a,#$00                ; just mark the voice "very old" (age $8000) so it is stolen first
0ae8: d4 d3     mov    VAgeLo+x,a
0aea: e8 80     mov    a,#$80
0aec: d4 cb     mov    VAgeHi+x,a
0aee: 6f        ret

L0AEF:
0aef: f5 ff 04  mov    a,VRelFlags+x         ; mark released (bit7)
0af2: 08 80     or     a,#$80
0af4: d5 ff 04  mov    VRelFlags+x,a
0af7: 8f b7 06  mov    $06,#$b7              ; default release: GAIN $b7 (exp. decrease)
0afa: 23 08 0c  bbs1   $08,L0B09             ; bit1 -> $b7
0afd: 43 08 06  bbs2   $08,L0B06             ; bit2 -> $b0 (slow)
0b00: 8f bf 06  mov    $06,#$bf              ; else $bf (fast)
0b03: 5f 09 0b  jmp    L0B09

L0B06:
0b06: 8f b0 06  mov    $06,#$b0

L0B09:
0b09: e4 1e     mov    a,CurVoiceDsp         ; ADSR1 = 0 (GAIN mode)
0b0b: 60        clrc
0b0c: 88 05     adc    a,#$05
0b0e: c4 f2     mov    DSPADDR,a
0b10: 8f 00 f3  mov    DSPDATA,#$00
0b13: bc        inc    a                     ; GAIN = release value
0b14: bc        inc    a
0b15: c4 f2     mov    DSPADDR,a
0b17: fa 06 f3  mov    (DSPDATA),($06)
0b1a: 6f        ret

; =============================================================================
; CalcTempo - A = tempo byte; TrkTempo[X] = (A+40)/60 as 8.8 fixed point
;  = sequence ticks per 8 ms timer tick. BPM = A+40 with 125 ticks per beat
;  (a sequence written at 128 ticks/beat plays ~2.3% slow).
; =============================================================================
CalcTempo:
0b1b: 6d        push   y
0b1c: 8d 00     mov    y,#$00
0b1e: 60        clrc
0b1f: 88 28     adc    a,#$28
0b21: 90 01     bcc    L0B24
0b23: fc        inc    y

L0B24:
0b24: 4d        push   x                     ; integer part
0b25: cd 3c     mov    x,#$3c
0b27: 9e        div    ya,x
0b28: ce        pop    x
0b29: 4d        push   x
0b2a: d5 2d 04  mov    TrkTempoHi+x,a
0b2d: e8 00     mov    a,#$00                ; remainder*256 / 60 = fraction
0b2f: cd 3c     mov    x,#$3c
0b31: 9e        div    ya,x
0b32: ce        pop    x
0b33: d5 17 04  mov    TrkTempoLo+x,a
0b36: ee        pop    y
0b37: 6f        ret

; =============================================================================
; AllocVoice - find a hardware voice for track $1c
;  Order: (mono flag) voice already owned by this track
;         -> oldest free voice -> oldest voice of LOWER priority
;         -> oldest voice of EQUAL priority.  Priority: higher number wins.
;  Out: C=0, X = voice (cut with GAIN $9f), C=1 no voice.
; =============================================================================
AllocVoice:
0b38: 6d        push   y
0b39: f8 1c     mov    x,CurTrack
0b3b: f5 cd 02  mov    a,TrkPriority+x       ; TrkPriority & $3f
0b3e: 28 3f     and    a,#$3f
0b40: c4 09     mov    $09,a
0b42: f5 0f 03  mov    a,TrkFlags+x          ; TrkFlags
0b45: c4 18     mov    $18,a
0b47: e8 00     mov    a,#$00
0b49: fd        mov    y,a
0b4a: c4 0a     mov    $0a,a
0b4c: c4 0c     mov    $0c,a
0b4e: c4 0e     mov    $0e,a
0b50: da 10     movw   $10,ya
0b52: da 12     movw   $12,ya
0b54: da 14     movw   $14,ya
0b56: 73 18 19  bbc3   $18,L0B72             ; TrkFlags bit3 : monophonic - reuse own voice
0b59: cd 07     mov    x,#$07

L0B5B:
0b5b: f4 db     mov    a,VoiceState+x
0b5d: 28 83     and    a,#$83
0b5f: f0 0e     beq    L0B6F
0b61: f5 27 05  mov    a,VTrack+x            ; owner == this track?
0b64: 64 1c     cmp    a,CurTrack
0b66: d0 07     bne    L0B6F
0b68: ab 0a     inc    $0a
0b6a: d8 0b     mov    $0b,x
0b6c: 5f b8 0b  jmp    L0BB8

L0B6F:
0b6f: 1d        dec    x
0b70: 10 e9     bpl    L0B5B

L0B72:
0b72: cd 07     mov    x,#$07

L0B74:
0b74: fb cb     mov    y,VAgeHi+x            ; age hi
0b76: f4 db     mov    a,VoiceState+x        ; busy?
0b78: 28 83     and    a,#$83
0b7a: d0 0f     bne    L0B8B
0b7c: f4 d3     mov    a,VAgeLo+x            ; free: keep the oldest
0b7e: 5a 10     cmpw   ya,$10
0b80: 90 06     bcc    L0B88
0b82: ab 0a     inc    $0a
0b84: da 10     movw   $10,ya
0b86: d8 0b     mov    $0b,x

L0B88:
0b88: 5f b5 0b  jmp    L0BB5

L0B8B:
0b8b: e4 0a     mov    a,$0a                 ; busy voice: only if no free voice found
0b8d: d0 26     bne    L0BB5
0b8f: f5 ef 04  mov    a,VPriority+x         ; VPriority
0b92: 28 3f     and    a,#$3f
0b94: 64 09     cmp    a,$09                 ; same priority -> candidate #3
0b96: d0 0f     bne    L0BA7
0b98: f4 d3     mov    a,VAgeLo+x
0b9a: 5a 12     cmpw   ya,$12
0b9c: 90 06     bcc    L0BA4
0b9e: ab 0c     inc    $0c
0ba0: da 12     movw   $12,ya
0ba2: d8 0d     mov    $0d,x

L0BA4:
0ba4: 5f b5 0b  jmp    L0BB5

L0BA7:
0ba7: b0 0c     bcs    L0BB5                 ; higher priority -> untouchable
0ba9: f4 d3     mov    a,VAgeLo+x            ; lower priority -> candidate #2
0bab: 5a 14     cmpw   ya,$14
0bad: 90 06     bcc    L0BB5
0baf: ab 0e     inc    $0e
0bb1: da 14     movw   $14,ya
0bb3: d8 0f     mov    $0f,x

L0BB5:
0bb5: 1d        dec    x
0bb6: 10 bc     bpl    L0B74

L0BB8:
0bb8: f8 0b     mov    x,$0b                 ; 1st choice: free voice
0bba: e4 0a     mov    a,$0a
0bbc: d0 0f     bne    L0BCD
0bbe: f8 0f     mov    x,$0f                 ; 2nd: lower priority
0bc0: e4 0e     mov    a,$0e
0bc2: d0 09     bne    L0BCD
0bc4: f8 0d     mov    x,$0d                 ; 3rd: same priority
0bc6: e4 0c     mov    a,$0c
0bc8: d0 03     bne    L0BCD
0bca: ee        pop    y                     ; none: C=1
0bcb: 80        setc
0bcc: 6f        ret

L0BCD:
0bcd: e8 00     mov    a,#$00                ; reset age
0bcf: d4 d3     mov    VAgeLo+x,a
0bd1: d4 cb     mov    VAgeHi+x,a
0bd3: e4 09     mov    a,$09                 ; voice takes our priority
0bd5: d5 ef 04  mov    VPriority+x,a
0bd8: f5 e1 05  mov    a,VoiceDspBase+x      ; ADSR1 = 0, GAIN = $9f : fast linear fade of old note
0bdb: 60        clrc
0bdc: 88 05     adc    a,#$05
0bde: c4 f2     mov    DSPADDR,a
0be0: 8f 00 f3  mov    DSPDATA,#$00
0be3: bc        inc    a
0be4: bc        inc    a
0be5: c4 f2     mov    DSPADDR,a
0be7: 8f 9f f3  mov    DSPDATA,#$9f
0bea: ee        pop    y
0beb: 60        clrc
0bec: 6f        ret

; =============================================================================
; InitDSP - reset DSP registers, echo defaults, timers
; =============================================================================
InitDSP:
0bed: e8 00     mov    a,#$00
0bef: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0bf2: c4 f3     mov    DSPDATA,a
0bf4: 8f 2d f2  mov    DSPADDR,#$2d          ; PMON
0bf7: c4 f3     mov    DSPDATA,a
0bf9: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
0bfc: c4 f3     mov    DSPDATA,a
0bfe: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOL L
0c01: c4 f3     mov    DSPDATA,a
0c03: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOL R
0c06: c4 f3     mov    DSPDATA,a
0c08: e8 7f     mov    a,#$7f
0c0a: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOL L = $7f
0c0d: c4 f3     mov    DSPDATA,a
0c0f: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOL R = $7f
0c12: c4 f3     mov    DSPDATA,a
0c14: 8f 5d f2  mov    DSPADDR,#$5d          ; DIR = DirPage ($23)
0c17: fa 27 f3  mov    (DSPDATA),(DirPage)
0c1a: cd 00     mov    x,#$00                ; clear VOL L/R, SRCN, ADSR1, GAIN of all 8 voices
0c1c: 8d 08     mov    y,#$08

L0C1E:
0c1e: 4d        push   x
0c1f: e8 00     mov    a,#$00
0c21: d8 f2     mov    DSPADDR,x
0c23: c4 f3     mov    DSPDATA,a
0c25: 3d        inc    x
0c26: d8 f2     mov    DSPADDR,x
0c28: c4 f3     mov    DSPDATA,a
0c2a: 3d        inc    x
0c2b: 3d        inc    x
0c2c: 3d        inc    x
0c2d: d8 f2     mov    DSPADDR,x
0c2f: c4 f3     mov    DSPDATA,a
0c31: 3d        inc    x
0c32: d8 f2     mov    DSPADDR,x
0c34: c4 f3     mov    DSPDATA,a
0c36: 3d        inc    x
0c37: 3d        inc    x
0c38: d8 f2     mov    DSPADDR,x
0c3a: c4 f3     mov    DSPDATA,a
0c3c: ae        pop    a
0c3d: 60        clrc
0c3e: 88 10     adc    a,#$10
0c40: 5d        mov    x,a
0c41: fe db     dbnz   y,L0C1E
0c43: e8 ff     mov    a,#$ff                ; EchoDelayCur = $ff (never changes again - see SetEchoDelay)
0c45: c5 8c 02  mov    EchoDelayCur,a
0c48: 8f 40 43  mov    FlgShadow,#$40        ; FLG shadow = $40 (mute until the first sound starts)
0c4b: 8f 5c 0c  mov    $0c,#$5c              ; EchoDefaults at $185c
0c4e: 8f 18 0d  mov    $0d,#$18
0c51: 8d 00     mov    y,#$00
0c53: 3f 68 18  call   SetEchoParams
0c56: 8f 03 f1  mov    CONTROL,#$03          ; CONTROL = $03: T0+T1 on, IPL ROM hidden (RAM at $ffc0-$ffff)
0c59: 8f 40 fa  mov    T0DIV,#$40            ; T0 = 64 * 125us = 8 ms
0c5c: 8f 40 fb  mov    T1DIV,#$40            ; T1 (unused)
0c5f: e4 fd     mov    a,T0OUT               ; clear timer counters
0c61: e4 fe     mov    a,T1OUT
0c63: 6f        ret

; UnmuteDSP - clear FLG mute bit (called after a sound is started)
UnmuteDSP:
0c64: e4 43     mov    a,FlgShadow
0c66: 28 bf     and    a,#$bf
0c68: c4 43     mov    FlgShadow,a
0c6a: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
0c6d: c4 f3     mov    DSPDATA,a
0c6f: 6f        ret

Copyright:
0c70: db    "SLICK/Audio v1.01 Copyright(C)1994 Bitmasters,Inc."

; -----------------------------------------------------------------------------
; VcmdTable - sequence commands $E0-$EF.  Bytes $F0-$FF would index past the
; end of this table (into code) - they must not appear in sequence data.
; -----------------------------------------------------------------------------
VcmdTable:
0ca2: 7a 0d     dw     Vcmd_Nop              ; E0 nop
0ca4: 7a 0d     dw     Vcmd_Nop              ; E1 nop
0ca6: aa 0d     dw     Vcmd_E2_Loop          ; E2 xx   loop point / loop back
0ca8: 7e 0d     dw     Vcmd_E3_End           ; E3 end of track
0caa: 7a 0d     dw     Vcmd_Nop              ; E4 nop
0cac: 7a 0d     dw     Vcmd_Nop              ; E5 nop
0cae: 0f 0e     dw     Vcmd_E6_Program       ; E6 pp   program
0cb0: 19 0e     dw     Vcmd_E7_Tempo         ; E7 tt   tempo
0cb2: 2a 0e     dw     Vcmd_E8_NextPattern   ; E8 next pattern (order list)
0cb4: 61 0e     dw     Vcmd_E9_Control       ; E9 cc vv controller
0cb6: 7a 0d     dw     Vcmd_Nop              ; EA nop
0cb8: f9 0d     dw     Vcmd_EB_StopPoint     ; EB stop point
0cba: 94 0e     dw     Vcmd_EC_ClearFlag     ; EC n    clear sync flag
0cbc: 9f 0e     dw     Vcmd_ED_SetFlag       ; ED n    set sync flag
0cbe: aa 0e     dw     Vcmd_EE_IncFlag       ; EE n    increment sync flag
0cc0: b7 0e     dw     Vcmd_EF_Nop           ; EF nop

; =============================================================================
; ProcessTrackEvents - interpret sequence data of track X until the track
;  timer becomes positive again.
;  Event syntax (every event is followed by a delta-time VLQ):
;    00-7F  note  [velocity if TrkFlags bit0=0] <gate VLQ> <delta VLQ>
;    80-BF  (ignored)  1 data byte             <delta VLQ>
;    C0-DF  pitch bend: semitones = sign-extended low 5 bits,
;           next byte = fraction/256          <delta VLQ>
;    E0-EF  command (VcmdTable)                <delta VLQ>
; =============================================================================
ProcessTrackEvents:
0cc2: f5 25 03  mov    a,TrkPtrLo+x          ; SeqPtr
0cc5: c4 1f     mov    SeqPtr,a
0cc7: f5 3b 03  mov    a,TrkPtrHi+x
0cca: c4 20     mov    SeqPtr+1,a

L0CCC:
0ccc: f5 0f 03  mov    a,TrkFlags+x          ; TrkFlags
0ccf: c4 33     mov    CurFlags,a
0cd1: f5 b7 02  mov    a,TrkStatus+x         ; TrkStatus
0cd4: c4 34     mov    CurStatus,a
.nextEvent:
0cd6: 8d 00     mov    y,#$00
0cd8: f7 1f     mov    a,(SeqPtr)+y
0cda: 10 27     bpl    .note
0cdc: 3a 1f     incw   SeqPtr                ; status byte
0cde: 68 e0     cmp    a,#$e0
0ce0: 90 0a     bcc    L0CEC
0ce2: 4d        push   x                     ; command E0-EF
0ce3: 28 1f     and    a,#$1f
0ce5: 1c        asl    a
0ce6: 5d        mov    x,a
0ce7: f7 1f     mov    a,(SeqPtr)+y          ; A = byte after the command (not consumed yet), Y = 0
0ce9: 1f a2 0c  jmp    (VcmdTable+x)

L0CEC:
0cec: 68 c0     cmp    a,#$c0                ; C0-DF : pitch bend
0cee: 90 0e     bcc    L0CFE
0cf0: c4 13     mov    $13,a
0cf2: f7 1f     mov    a,(SeqPtr)+y
0cf4: 3a 1f     incw   SeqPtr
0cf6: c4 12     mov    $12,a
0cf8: 3f eb 10  call   TrkSetBendFromEvent   ; set bend on this track + its voices
0cfb: 5f 51 0d  jmp    ReadDeltaAndAdvance

L0CFE:
0cfe: 3a 1f     incw   SeqPtr                ; 80-BF : skip data byte
0d00: 5f 51 0d  jmp    ReadDeltaAndAdvance
.note:
0d03: 3a 1f     incw   SeqPtr
0d05: 2d        push   a                     ; keep note number
0d06: 93 33 03  bbc4   CurFlags,L0D0C        ; TrkFlags bit4 : ORIGINAL BUG - jumps to a RET with the note still
0d09: 5f 79 0d  jmp    NoteSkipBug           ; pushed (stack corruption). Flag bit4 must never be set in song data.

L0D0C:
0d0c: 8f 7f 3a  mov    Velocity,#$7f         ; default velocity
0d0f: 03 33 06  bbs0   CurFlags,L0D18        ; TrkFlags bit0 : note events carry no velocity byte
0d12: f7 1f     mov    a,(SeqPtr)+y
0d14: c4 3a     mov    Velocity,a
0d16: 3a 1f     incw   SeqPtr

L0D18:
0d18: 03 34 05  bbs0   CurStatus,L0D20       ; TrkStatus bit0 : track muted -> no voice
0d1b: 3f 38 0b  call   AllocVoice            ; get a voice
0d1e: 90 07     bcc    L0D27

L0D20:
0d20: ae        pop    a                     ; no voice/muted: skip gate time, keep timing
0d21: 3f 04 0f  call   ReadVLQ
0d24: 5f 51 0d  jmp    ReadDeltaAndAdvance

L0D27:
0d27: d8 1d     mov    CurVoice,x            ; remember voice
0d29: e4 3a     mov    a,Velocity
0d2b: d5 1f 05  mov    VVelocity+x,a         ; VVelocity
0d2e: ae        pop    a
0d2f: d5 17 05  mov    VNote+x,a             ; VNote
0d32: e4 1c     mov    a,CurTrack
0d34: d5 27 05  mov    VTrack+x,a            ; VTrack = owner
0d37: 3f 04 0f  call   ReadVLQ               ; gate time VLQ
0d3a: e8 00     mov    a,#$00                ; VGate = gate*2 (gate is stored at half resolution)
0d3c: d4 c3     mov    VGateFrac+x,a
0d3e: e4 28     mov    a,Delta
0d40: 1c        asl    a
0d41: d4 bb     mov    VGateLo+x,a
0d43: e4 29     mov    a,Delta+1
0d45: 3c        rol    a
0d46: d4 b3     mov    VGateMid+x,a
0d48: e4 2a     mov    a,Delta+2
0d4a: 3c        rol    a
0d4b: d4 ab     mov    VGateHi+x,a
0d4d: e8 01     mov    a,#$01                ; state = 1 : key on at next voice pass
0d4f: d4 db     mov    VoiceState+x,a

ReadDeltaAndAdvance:
0d51: f8 1c     mov    x,CurTrack
0d53: 3f 04 0f  call   ReadVLQ               ; delta VLQ
0d56: 60        clrc                         ; TrkTimer += delta
0d57: e4 28     mov    a,Delta
0d59: 94 77     adc    a,TrkTimerLo+x
0d5b: d4 77     mov    TrkTimerLo+x,a
0d5d: e4 29     mov    a,Delta+1
0d5f: 94 61     adc    a,TrkTimerMid+x
0d61: d4 61     mov    TrkTimerMid+x,a
0d63: e4 2a     mov    a,Delta+2
0d65: 94 4b     adc    a,TrkTimerHi+x
0d67: d4 4b     mov    TrkTimerHi+x,a
0d69: 10 03     bpl    L0D6E                 ; timer >= 0 : done, save SeqPtr
0d6b: 5f cc 0c  jmp    L0CCC                 ; timer still negative : next event now

L0D6E:
0d6e: e4 1f     mov    a,SeqPtr              ; save SeqPtr
0d70: d5 25 03  mov    TrkPtrLo+x,a
0d73: e4 20     mov    a,SeqPtr+1
0d75: d5 3b 03  mov    TrkPtrHi+x,a
0d78: 6f        ret

NoteSkipBug:
0d79: 6f        ret

; --- E0, E1, E4, E5, EA : no operation, no parameter (EF: see $0eb7) ----
Vcmd_Nop:
0d7a: ce        pop    x
0d7b: 5f 51 0d  jmp    ReadDeltaAndAdvance

; --- E3 : end of track -------------------------------------------------
;  If TrkFlags bit7 is set the track restarts at its loop point instead.
Vcmd_E3_End:
0d7e: ce        pop    x
0d7f: f3 33 03  bbc7   CurFlags,L0D85        ; TrkFlags bit7 : loop whole track
0d82: 5f e0 0d  jmp    LoopBack

L0D85:
0d85: f5 b7 02  mov    a,TrkStatus+x         ; TrkStatus: clear active
0d88: 28 7f     and    a,#$7f
0d8a: d5 b7 02  mov    TrkStatus+x,a
0d8d: 93 34 03  bbc4   CurStatus,.clearVoiceLinks ; chain flag -> (stubbed) chain hook
0d90: 3f 3b 0f  call   ChainHookStub
.clearVoiceLinks:
0d93: 8d 08     mov    y,#$08                ; intended: VOwnerTrack[v] == this track -> $ff.
0d95: d8 0e     mov    $0e,x                 ; ORIGINAL BUG: compares A (status value), not X (track number)

L0D97:
0d97: 76 41 ff  cmp    a,VOwnerTrack-1+y
0d9a: d0 06     bne    L0DA2
0d9c: e8 ff     mov    a,#$ff
0d9e: d6 41 ff  mov    VOwnerTrack-1+y,a
0da1: 7d        mov    a,x

L0DA2:
0da2: fe f3     dbnz   y,L0D97
0da4: e8 00     mov    a,#$00                ; TrkStatus = 0
0da6: d5 b7 02  mov    TrkStatus+x,a
0da9: 6f        ret

; --- E2 00 : set loop point / E2 nn (nn<>0) : jump to loop point ---------
;  E2 00 saves SeqPtr AND the order-list position. E2 nn loops forever,
;  unless a stop was requested (TrkStatus bit1/2, system cmd $14) -> track ends.
Vcmd_E2_Loop:
0daa: ce        pop    x
0dab: f7 1f     mov    a,(SeqPtr)+y
0dad: d0 1b     bne    .loopEnd
0daf: 3a 1f     incw   SeqPtr                ; consume $00
0db1: e4 1f     mov    a,SeqPtr              ; TrkLoopPtr = SeqPtr
0db3: d5 93 03  mov    TrkLoopPtrLo+x,a
0db6: e4 20     mov    a,SeqPtr+1
0db8: d5 7d 03  mov    TrkLoopPtrHi+x,a
0dbb: f5 67 03  mov    a,TrkListLo+x         ; TrkLoopList = TrkList
0dbe: d5 bf 03  mov    TrkLoopListLo+x,a
0dc1: f5 51 03  mov    a,TrkListHi+x
0dc4: d5 a9 03  mov    TrkLoopListHi+x,a
0dc7: 5f 51 0d  jmp    ReadDeltaAndAdvance
.loopEnd:
0dca: e4 34     mov    a,CurStatus           ; stop requested?
0dcc: 28 06     and    a,#$06
0dce: f0 10     beq    LoopBack
0dd0: e4 34     mov    a,CurStatus           ; yes: deactivate track
0dd2: 28 7f     and    a,#$7f
0dd4: d5 b7 02  mov    TrkStatus+x,a
0dd7: 93 34 03  bbc4   CurStatus,L0DDD
0dda: 3f 3b 0f  call   ChainHookStub

L0DDD:
0ddd: 3a 1f     incw   SeqPtr
0ddf: 6f        ret

LoopBack:
0de0: f5 7d 03  mov    a,TrkLoopPtrHi+x      ; SeqPtr = TrkLoopPtr
0de3: c4 20     mov    SeqPtr+1,a
0de5: f5 93 03  mov    a,TrkLoopPtrLo+x
0de8: c4 1f     mov    SeqPtr,a
0dea: f5 bf 03  mov    a,TrkLoopListLo+x     ; TrkList = TrkLoopList
0ded: d5 67 03  mov    TrkListLo+x,a
0df0: f5 a9 03  mov    a,TrkLoopListHi+x
0df3: d5 51 03  mov    TrkListHi+x,a

VcmdNextDelta:
0df6: 5f 51 0d  jmp    ReadDeltaAndAdvance

; --- EB : stop point - ends the track only if a stop was requested -------
Vcmd_EB_StopPoint:
0df9: ce        pop    x
0dfa: 33 34 10  bbc1   CurStatus,L0E0D
0dfd: e4 34     mov    a,CurStatus
0dff: 28 7f     and    a,#$7f
0e01: d5 b7 02  mov    TrkStatus+x,a
0e04: 93 34 03  bbc4   CurStatus,L0E0A
0e07: 3f 3b 0f  call   ChainHookStub

L0E0A:
0e0a: 5f 93 0d  jmp    .clearVoiceLinks

L0E0D:
0e0d: 2f e7     bra    VcmdNextDelta

; --- E6 pp : program change (instrument pp) -----------------------------
Vcmd_E6_Program:
0e0f: ce        pop    x
0e10: f7 1f     mov    a,(SeqPtr)+y
0e12: d5 f9 02  mov    TrkProgram+x,a
0e15: 3a 1f     incw   SeqPtr
0e17: 2f dd     bra    VcmdNextDelta

; --- E7 tt : tempo, BPM = tt + 40 (+ TrkTempoOfs) -----------------------
Vcmd_E7_Tempo:
0e19: ce        pop    x
0e1a: f7 1f     mov    a,(SeqPtr)+y
0e1c: d5 76 ff  mov    TrkTempo+x,a
0e1f: 60        clrc
0e20: 95 b1 04  adc    a,TrkTempoOfs+x
0e23: 3f 1b 0b  call   CalcTempo
0e26: 3a 1f     incw   SeqPtr
0e28: 2f cc     bra    VcmdNextDelta

; --- E8 : end of pattern -> next entry of the order list ----------------
;  Order list = words, offsets from the sound's pattern base. SeqPtr =
;  base + word + 1 (first byte of every pattern is skipped).
;  E8 has no parameter; the order list has no terminator (use E2/E3 in a pattern).
Vcmd_E8_NextPattern:
0e2a: ce        pop    x
0e2b: f5 67 03  mov    a,TrkListLo+x         ; TrkList += 2
0e2e: c4 08     mov    $08,a
0e30: f5 51 03  mov    a,TrkListHi+x
0e33: c4 09     mov    $09,a
0e35: 3a 08     incw   $08
0e37: 3a 08     incw   $08
0e39: e4 09     mov    a,$09
0e3b: d5 51 03  mov    TrkListHi+x,a
0e3e: e4 08     mov    a,$08
0e40: d5 67 03  mov    TrkListLo+x,a
0e43: f7 08     mov    a,($08)+y
0e45: c4 1f     mov    SeqPtr,a
0e47: fc        inc    y
0e48: f7 08     mov    a,($08)+y
0e4a: c4 20     mov    SeqPtr+1,a
0e4c: dc        dec    y
0e4d: f5 60 ff  mov    a,TrkPatBaseLo+x      ; + pattern base
0e50: 60        clrc
0e51: 84 1f     adc    a,SeqPtr
0e53: c4 1f     mov    SeqPtr,a
0e55: f5 4a ff  mov    a,TrkPatBaseHi+x
0e58: 84 20     adc    a,SeqPtr+1
0e5a: c4 20     mov    SeqPtr+1,a
0e5c: 3a 1f     incw   SeqPtr                ; skip pattern's first byte
0e5e: 5f 51 0d  jmp    ReadDeltaAndAdvance

; --- E9 cc vv : controller.  cc=01 volume (param $18), cc=02 pan (param 2)
;  any other cc: value ignored.
Vcmd_E9_Control:
0e61: ce        pop    x
0e62: f7 1f     mov    a,(SeqPtr)+y
0e64: 3a 1f     incw   SeqPtr
0e66: 68 01     cmp    a,#$01
0e68: d0 0c     bne    L0E76
0e6a: f7 1f     mov    a,(SeqPtr)+y
0e6c: c4 0b     mov    $0b,a
0e6e: 8f 18 0e  mov    $0e,#$18
0e71: 3f fe 10  call   TrkApplyParam
0e74: 2f 0e     bra    VcmdSkip1Delta

L0E76:
0e76: 68 02     cmp    a,#$02
0e78: d0 0a     bne    VcmdSkip1Delta
0e7a: f7 1f     mov    a,(SeqPtr)+y
0e7c: c4 0b     mov    $0b,a
0e7e: 8f 02 0e  mov    $0e,#$02
0e81: 3f fe 10  call   TrkApplyParam

VcmdSkip1Delta:
0e84: 3a 1f     incw   SeqPtr

L0E86:
0e86: 5f 51 0d  jmp    ReadDeltaAndAdvance

; GetSyncFlagIdx - notify CPU (status bit0) and X = param & $0f
GetSyncFlagIdx:
0e89: 3f 02 1c  call   SignalSyncFlag
0e8c: f7 1f     mov    a,(SeqPtr)+y
0e8e: 28 0f     and    a,#$0f
0e90: 3a 1f     incw   SeqPtr
0e92: 5d        mov    x,a
0e93: 6f        ret

; --- EC n : SyncFlag[n] = 0 --------------------------------------------
Vcmd_EC_ClearFlag:
0e94: 3f 89 0e  call   GetSyncFlagIdx
0e97: e8 00     mov    a,#$00
0e99: d5 64 02  mov    SyncFlags+x,a
0e9c: ce        pop    x

L0E9D:
0e9d: 2f e7     bra    L0E86

; --- ED n : SyncFlag[n] = 1 --------------------------------------------
Vcmd_ED_SetFlag:
0e9f: 3f 89 0e  call   GetSyncFlagIdx
0ea2: e8 01     mov    a,#$01
0ea4: d5 64 02  mov    SyncFlags+x,a
0ea7: ce        pop    x
0ea8: 2f f3     bra    L0E9D

; --- EE n : SyncFlag[n]++ ----------------------------------------------
Vcmd_EE_IncFlag:
0eaa: 3f 89 0e  call   GetSyncFlagIdx
0ead: f5 64 02  mov    a,SyncFlags+x
0eb0: bc        inc    a
0eb1: d5 64 02  mov    SyncFlags+x,a
0eb4: ce        pop    x
0eb5: 2f e6     bra    L0E9D

; --- EF : no operation, no parameter (jumps past the INCW at $0e84) ----
Vcmd_EF_Nop:
0eb7: ce        pop    x
0eb8: 2f e3     bra    L0E9D

; =============================================================================
; VoiceKeyOn - copy owning track's state into voice X and start its note
; =============================================================================
VoiceKeyOn:
0eba: d8 1d     mov    CurVoice,x
0ebc: f5 27 05  mov    a,VTrack+x            ; VTrack
0ebf: c4 1c     mov    CurTrack,a
0ec1: fd        mov    y,a
0ec2: d5 42 ff  mov    VOwnerTrack+x,a       ; VOwnerTrack
0ec5: f6 0f 03  mov    a,TrkFlags+y          ; TrkFlags -> VFlags
0ec8: d5 07 05  mov    VFlags+x,a
0ecb: 8f 00 44  mov    HdrTranspose,#$00
0ece: f6 6f 04  mov    a,TrkTranspose+y      ; TrkTranspose -> VTranspose
0ed1: d5 12 ff  mov    VTranspose+x,a
0ed4: f6 e3 02  mov    a,TrkSoundID+y        ; TrkSoundID -> VSoundID
0ed7: d4 a3     mov    VSoundID+x,a
0ed9: f6 d5 03  mov    a,TrkNumber+y         ; TrkNumber -> VTrkNumber
0edc: d5 0f 05  mov    VTrkNumber+x,a
0edf: f6 eb 03  mov    a,TrkBendHi+y         ; TrkBend -> VBend
0ee2: d5 cf 04  mov    VBendHi+x,a
0ee5: f6 01 04  mov    a,TrkBendLo+y
0ee8: d5 c7 04  mov    VBendLo+x,a
0eeb: e8 80     mov    a,#$80                ; state = playing
0eed: d4 db     mov    VoiceState+x,a
0eef: e8 00     mov    a,#$00
0ef1: d5 f7 04  mov    VPrevEnvx+x,a
0ef4: d4 e3     mov    VMod+x,a
0ef6: f5 1f 05  mov    a,VVelocity+x         ; VVelocity
0ef9: c4 3a     mov    Velocity,a
0efb: f5 17 05  mov    a,VNote+x             ; VNote
0efe: 3f f2 05  call   VoiceNoteOn
0f01: f8 1d     mov    x,CurVoice
0f03: 6f        ret

; =============================================================================
; ReadVLQ - read a MIDI-style variable-length number (1-3 bytes, 7 bits
;  per byte, bit7 = "more follows") at SeqPtr into $28(lo)/$29/$2a(hi).
; =============================================================================
ReadVLQ:
0f04: 8d 00     mov    y,#$00
0f06: cb 28     mov    Delta,y
0f08: cb 29     mov    Delta+1,y
0f0a: cb 2a     mov    Delta+2,y
0f0c: f7 1f     mov    a,(SeqPtr)+y
0f0e: 10 26     bpl    L0F36
0f10: 28 7f     and    a,#$7f
0f12: c4 29     mov    Delta+1,a
0f14: 4b 29     lsr    Delta+1
0f16: 6b 28     ror    Delta
0f18: 3a 1f     incw   SeqPtr
0f1a: f7 1f     mov    a,(SeqPtr)+y
0f1c: 10 16     bpl    L0F34
0f1e: 28 7f     and    a,#$7f
0f20: fa 29 2a  mov    (Delta+2),(Delta+1)
0f23: 04 28     or     a,Delta
0f25: c4 29     mov    Delta+1,a
0f27: 8f 00 28  mov    Delta,#$00
0f2a: 4b 2a     lsr    Delta+2
0f2c: 6b 29     ror    Delta+1
0f2e: 6b 28     ror    Delta
0f30: 3a 1f     incw   SeqPtr
0f32: f7 1f     mov    a,(SeqPtr)+y

L0F34:
0f34: 04 28     or     a,Delta

L0F36:
0f36: c4 28     mov    Delta,a
0f38: 3a 1f     incw   SeqPtr
0f3a: 6f        ret

; ChainHookStub - empty. Called when a track with the "chain" status bit
; (bit4, set by system cmd $14) stops. The chain list at $027b is never read.
ChainHookStub:
0f3b: 6f        ret

; =============================================================================
; AllocTrack - allocate + initialise one sequencer track (from StartSound)
;  In : X = initial program, Y = priority, $1f/$20 = data pointer,
;       $0a = key offset, $0b = sound ID, $2f tempo, $32 flags, $3a velocity,
;       $44 transpose, $0294 pattern base, $0296 track number
; =============================================================================
AllocTrack:
0f3c: 4d        push   x
0f3d: cb 3f     mov    PriorityTmp,y         ; $3f = priority
0f3f: 8f 01 35  mov    VoiceBit,#$01
0f42: cd 00     mov    x,#$00

L0F44:
0f44: f5 b7 02  mov    a,TrkStatus+x         ; find a free track (0-21)
0f47: 28 80     and    a,#$80
0f49: f0 05     beq    L0F50
0f4b: 3d        inc    x
0f4c: c8 16     cmp    x,#$16
0f4e: d0 f4     bne    L0F44

L0F50:
0f50: c8 16     cmp    x,#$16
0f52: d0 07     bne    L0F5B
0f54: 3f 25 10  call   StealTrack            ; none free: try stealing one
0f57: 90 02     bcc    L0F5B
0f59: ce        pop    x
0f5a: 6f        ret

L0F5B:
0f5b: d8 1c     mov    CurTrack,x
0f5d: e5 96 02  mov    a,BankStart-1         ; TrkNumber
0f60: d5 d5 03  mov    TrkNumber+x,a
0f63: e5 94 02  mov    a,PatBaseTmp          ; TrkPatBase
0f66: d5 60 ff  mov    TrkPatBaseLo+x,a
0f69: e5 95 02  mov    a,PatBaseTmp+1
0f6c: d5 4a ff  mov    TrkPatBaseHi+x,a
0f6f: e4 3f     mov    a,PriorityTmp         ; TrkPriority
0f71: d5 cd 02  mov    TrkPriority+x,a
0f74: ae        pop    a                     ; TrkProgram
0f75: d5 f9 02  mov    TrkProgram+x,a
0f78: e8 00     mov    a,#$00                ; TrkTimer = 0 : first delta read immediately
0f7a: d4 4b     mov    TrkTimerHi+x,a
0f7c: d4 61     mov    TrkTimerMid+x,a
0f7e: d4 77     mov    TrkTimerLo+x,a
0f80: d4 8d     mov    TrkTimerFrac+x,a
0f82: d5 eb 03  mov    TrkBendHi+x,a         ; TrkBend = 0
0f85: d5 01 04  mov    TrkBendLo+x,a
0f88: e4 32     mov    a,HdrTrkFlags         ; TrkFlags
0f8a: d5 0f 03  mov    TrkFlags+x,a
0f8d: e4 44     mov    a,HdrTranspose        ; TrkTranspose
0f8f: d5 6f 04  mov    TrkTranspose+x,a
0f92: e4 2f     mov    a,HdrTempo            ; TrkTempo (raw)
0f94: d5 76 ff  mov    TrkTempo+x,a
0f97: e5 7a 02  mov    a,StartTempoOfs       ; TrkTempoOfs from start event
0f9a: d5 b1 04  mov    TrkTempoOfs+x,a
0f9d: 60        clrc
0f9e: 84 2f     adc    a,HdrTempo
0fa0: 3f 1b 0b  call   CalcTempo
0fa3: f8 1c     mov    x,CurTrack            ; TrkTempo (8.8)
0fa5: e4 3a     mov    a,Velocity
0fa7: d5 43 04  mov    TrkVelocity+x,a       ; TrkVelocity
0faa: e5 79 02  mov    a,StartVolume         ; TrkVolume from start event
0fad: d5 59 04  mov    TrkVolume+x,a
0fb0: e8 7f     mov    a,#$7f                ; TrkChanVol = $7f
0fb2: d5 94 ff  mov    TrkChanVol+x,a
0fb5: e8 80     mov    a,#$80                ; active
0fb7: d5 b7 02  mov    TrkStatus+x,a
0fba: e4 0a     mov    a,$0a                 ; TrkKeyOffset
0fbc: d5 85 04  mov    TrkKeyOffset+x,a
0fbf: e5 78 02  mov    a,StartPan            ; TrkPan
0fc2: 28 7f     and    a,#$7f
0fc4: d5 9b 04  mov    TrkPan+x,a
0fc7: e4 0b     mov    a,$0b                 ; TrkSoundID
0fc9: d5 e3 02  mov    TrkSoundID+x,a
0fcc: 53 32 28  bbc2   HdrTrkFlags,L0FF7     ; TrkFlags bit2 : order-list (pattern) mode
0fcf: e4 20     mov    a,SeqPtr+1            ; TrkList = TrkLoopList = pointer to order list
0fd1: d5 51 03  mov    TrkListHi+x,a
0fd4: d5 a9 03  mov    TrkLoopListHi+x,a
0fd7: e4 1f     mov    a,SeqPtr
0fd9: d5 67 03  mov    TrkListLo+x,a
0fdc: d5 bf 03  mov    TrkLoopListLo+x,a
0fdf: 8d 00     mov    y,#$00                ; SeqPtr = base + first word + 1
0fe1: f7 1f     mov    a,(SeqPtr)+y
0fe3: fc        inc    y
0fe4: 60        clrc
0fe5: 85 94 02  adc    a,PatBaseTmp
0fe8: c4 16     mov    $16,a
0fea: f7 1f     mov    a,(SeqPtr)+y
0fec: dc        dec    y
0fed: 85 95 02  adc    a,PatBaseTmp+1
0ff0: c4 20     mov    SeqPtr+1,a
0ff2: fa 16 1f  mov    (SeqPtr),($16)
0ff5: 3a 1f     incw   SeqPtr

L0FF7:
0ff7: e4 20     mov    a,SeqPtr+1            ; TrkLoopPtr = SeqPtr
0ff9: d5 7d 03  mov    TrkLoopPtrHi+x,a
0ffc: e4 1f     mov    a,SeqPtr
0ffe: d5 93 03  mov    TrkLoopPtrLo+x,a
1001: 3f 51 0d  call   ReadDeltaAndAdvance   ; read first delta
1004: 6f        ret

; -----------------------------------------------------------------------------
; 32 unreferenced bytes (build leftover).  SPCdas disassembled them as code,
; which also MIS-ALIGNED the real routine StealTrack at $1025 (the listing
; showed "1023: sbc ($78),($e4) / 1026: clrv / 1027: asl $90 ..." up to $1036).
; -----------------------------------------------------------------------------
GarbageBytes:
1005: db    $76,$5a,$45,$4c,$b8,$a3,$ad,$a2,$41,$1d,$76,$1c,$fb,$f3,$f3,$fe
1015: db    $77,$5c,$41,$58,$ab,$b9,$be,$af,$47,$46,$19,$15,$83,$a4,$a9,$e4

; =============================================================================
; StealTrack - no free track: take one over.  $3f = new priority, $0b = new ID
;  ID >= $e0 (music) : takes any SFX track (ID < $e0) first, else the
;                      lowest-priority music track if its priority <= new one
;  ID <  $e0 (SFX)   : lowest-priority SFX track if its priority <= new one
;  Out: C=0, X = track;  C=1 failed.
; =============================================================================
StealTrack:
1025: 78 e0 0b  cmp    $0b,#$e0              ; SFX request?
1028: 90 4b     bcc    .sfxRequest
102a: 8f ff 16  mov    $16,#$ff              ; $16/$17 = lowest SFX priority/track, $18/$19 = lowest music priority/track
102d: 8f ff 17  mov    $17,#$ff
1030: 8f ff 18  mov    $18,#$ff
1033: 8f ff 19  mov    $19,#$ff
1036: cd 15     mov    x,#$15

L1038:
1038: f5 e3 02  mov    a,TrkSoundID+x
103b: 68 e0     cmp    a,#$e0                ; music track?
103d: b0 0e     bcs    L104D
103f: f5 cd 02  mov    a,TrkPriority+x
1042: 64 16     cmp    a,$16
1044: b0 04     bcs    L104A
1046: c4 16     mov    $16,a
1048: d8 17     mov    $17,x

L104A:
104a: 5f 58 10  jmp    L1058

L104D:
104d: f5 cd 02  mov    a,TrkPriority+x
1050: 64 18     cmp    a,$18
1052: b0 04     bcs    L1058
1054: c4 18     mov    $18,a
1056: d8 19     mov    $19,x

L1058:
1058: 1d        dec    x
1059: 10 dd     bpl    L1038
105b: f8 17     mov    x,$17                 ; any SFX track -> take it
105d: 30 04     bmi    L1063
105f: 60        clrc
1060: 5f 72 10  jmp    L1072

L1063:
1063: e4 18     mov    a,$18
1065: 64 3f     cmp    a,PriorityTmp
1067: f0 02     beq    L106B
1069: b0 06     bcs    L1071

L106B:
106b: f8 19     mov    x,$19
106d: 60        clrc
106e: 5f 72 10  jmp    L1072

L1071:
1071: 80        setc

L1072:
1072: 5f a7 10  jmp    L10A7
.sfxRequest:
1075: 8f ff 16  mov    $16,#$ff
1078: 8f ff 17  mov    $17,#$ff
107b: cd 15     mov    x,#$15

L107D:
107d: f5 e3 02  mov    a,TrkSoundID+x
1080: 68 e0     cmp    a,#$e0
1082: b0 0b     bcs    L108F
1084: f5 cd 02  mov    a,TrkPriority+x
1087: 64 16     cmp    a,$16
1089: b0 04     bcs    L108F
108b: c4 16     mov    $16,a
108d: d8 17     mov    $17,x

L108F:
108f: 1d        dec    x
1090: 10 eb     bpl    L107D
1092: f8 17     mov    x,$17
1094: 30 10     bmi    L10A6
1096: e4 16     mov    a,$16
1098: 64 3f     cmp    a,PriorityTmp
109a: f0 02     beq    L109E
109c: b0 04     bcs    L10A2

L109E:
109e: 60        clrc
109f: 5f a3 10  jmp    L10A3

L10A2:
10a2: 80        setc

L10A3:
10a3: 5f a7 10  jmp    L10A7

L10A6:
10a6: 80        setc

L10A7:
10a7: 6f        ret

; =============================================================================
; QEv_System - queue event type 1.  $08 = sub command, $0a/$0b = params
;   $01          stop everything
;   $20-$3F      pitch bend of sound ID $0a: semitones = signed (cmd&$1f),
;                fraction = $0b
;   $80-$FF      SystemSubCommand (cmd & $7f)
; =============================================================================
QEv_System:
10a8: 78 01 08  cmp    $08,#$01
10ab: d0 04     bne    L10B1
10ad: 3f 9e 13  call   StopAllAudio
10b0: 6f        ret

L10B1:
10b1: e4 08     mov    a,$08
10b3: 10 08     bpl    L10BD
10b5: 28 7f     and    a,#$7f
10b7: c4 08     mov    $08,a
10b9: 3f 6f 12  call   SystemSubCommand
10bc: 6f        ret

L10BD:
10bd: e4 08     mov    a,$08
10bf: fd        mov    y,a
10c0: 28 20     and    a,#$20
10c2: d0 01     bne    L10C5
10c4: 6f        ret

L10C5:
10c5: dd        mov    a,y
10c6: 28 10     and    a,#$10
10c8: d0 06     bne    L10D0
10ca: dd        mov    a,y
10cb: 28 0f     and    a,#$0f
10cd: 5f d3 10  jmp    L10D3

L10D0:
10d0: dd        mov    a,y
10d1: 08 f0     or     a,#$f0

L10D3:
10d3: 28 1f     and    a,#$1f
10d5: 68 10     cmp    a,#$10
10d7: 90 02     bcc    L10DB
10d9: 08 e0     or     a,#$e0

L10DB:
10db: c4 13     mov    $13,a
10dd: e4 0b     mov    a,$0b
10df: c4 12     mov    $12,a
10e1: 8f 0a 0e  mov    $0e,#$0a
10e4: 8f ff 0f  mov    $0f,#$ff
10e7: 3f 1a 14  call   ApplyParamToSound
10ea: 6f        ret

; TrkSetBendFromEvent - $13 = sign-extended 5-bit semitones, $12 fraction
TrkSetBendFromEvent:
10eb: e4 13     mov    a,$13
10ed: 28 1f     and    a,#$1f
10ef: 68 10     cmp    a,#$10
10f1: 90 02     bcc    L10F5
10f3: 08 e0     or     a,#$e0

L10F5:
10f5: c4 13     mov    $13,a
10f7: 8f 0a 0e  mov    $0e,#$0a
10fa: 3f fe 10  call   TrkApplyParam
10fd: 6f        ret

; =============================================================================
; TrkApplyParam - apply parameter $0e (value $0b) to track X and to all
;  playing voices owned by it
; =============================================================================
TrkApplyParam:
10fe: 4d        push   x
10ff: 6d        push   y
1100: d8 0a     mov    $0a,x
1102: f5 d5 03  mov    a,TrkNumber+x
1105: c4 0f     mov    $0f,a
1107: eb 0a     mov    y,$0a
1109: f8 0e     mov    x,$0e
110b: e4 0b     mov    a,$0b
110d: 3f a6 05  call   TrkParamDispatch
1110: ee        pop    y
1111: ce        pop    x
1112: 4d        push   x
1113: 6d        push   y
1114: d8 0a     mov    $0a,x
1116: f5 d5 03  mov    a,TrkNumber+x
1119: c4 0f     mov    $0f,a
111b: 8d 07     mov    y,#$07

L111D:
111d: e4 0a     mov    a,$0a
111f: 76 42 ff  cmp    a,VOwnerTrack+y       ; VOwnerTrack
1122: d0 13     bne    L1137
1124: e4 0f     mov    a,$0f
1126: 76 0f 05  cmp    a,VTrkNumber+y        ; VTrkNumber
1129: d0 0c     bne    L1137
112b: f6 db 00  mov    a,VoiceState+y        ; playing?
112e: 10 07     bpl    L1137
1130: f8 0e     mov    x,$0e
1132: e4 0b     mov    a,$0b
1134: 3f c3 05  call   VoiceParamDispatch

L1137:
1137: dc        dec    y
1138: 10 e3     bpl    L111D
113a: ee        pop    y
113b: ce        pop    x
113c: 6f        ret

; =============================================================================
; StartSound - start sound number $08 (music or SFX)
;  Searches the registered banks (BankStart[]) for an entry with ID $08.
;  Entry layout:
;    +0 word  size of entry (link to next; ID $ff = end of bank)
;    +2 byte  ID
;    +3 byte  number of tracks n
;    +4 byte  tempo (BPM-40)
;    +5 byte  flags (OR'ed into every track's flags)
;    +6 byte  echo present (0/1); if 1, 12 bytes follow:
;             EDL, EVOL L, EVOL R, EFB, FIR0-7
;    then n * 8 bytes track headers:
;             flags, priority, velocity, pan, transpose, program,
;             word data offset (from entry start)
;    pattern base = first byte after the track headers
; =============================================================================
StartSound:
113d: 8f 97 0e  mov    $0e,#$97              ; BankStart list
1140: 8f 02 0f  mov    $0f,#$02
1143: 8d 00     mov    y,#$00

L1145:
1145: fc        inc    y
1146: ad 11     cmp    y,#$11                ; 8 slots
1148: f0 31     beq    L117B
114a: f7 0e     mov    a,($0e)+y             ; slot hi = 0 : empty
114c: d0 04     bne    L1152
114e: fc        inc    y
114f: 5f 78 11  jmp    L1178

L1152:
1152: c4 0d     mov    $0d,a
1154: dc        dec    y
1155: f7 0e     mov    a,($0e)+y
1157: c4 0c     mov    $0c,a
1159: 6d        push   y

L115A:
115a: 8d 02     mov    y,#$02
115c: f7 0c     mov    a,($0c)+y             ; entry ID
115e: 68 ff     cmp    a,#$ff
1160: f0 13     beq    L1175                 ; end of bank
1162: 64 08     cmp    a,$08
1164: f0 16     beq    L117C                 ; found
1166: dc        dec    y                     ; next entry = entry + size
1167: f7 0c     mov    a,($0c)+y
1169: 2d        push   a
116a: dc        dec    y
116b: f7 0c     mov    a,($0c)+y
116d: ee        pop    y
116e: 7a 0c     addw   ya,$0c
1170: da 0c     movw   $0c,ya
1172: 5f 5a 11  jmp    L115A

L1175:
1175: ee        pop    y
1176: fc        inc    y
1177: fc        inc    y

L1178:
1178: 5f 45 11  jmp    L1145

L117B:
117b: 6f        ret

L117C:
117c: ee        pop    y
117d: e8 00     mov    a,#$00                ; $0f:A = n*8+7
117f: c4 0f     mov    $0f,a
1181: 8d 03     mov    y,#$03
1183: f7 0c     mov    a,($0c)+y
1185: 5d        mov    x,a
1186: fc        inc    y
1187: 1c        asl    a
1188: 2b 0f     rol    $0f
118a: 1c        asl    a
118b: 2b 0f     rol    $0f
118d: 1c        asl    a
118e: 2b 0f     rol    $0f
1190: 60        clrc
1191: 88 07     adc    a,#$07
1193: c4 0e     mov    $0e,a
1195: 98 00 0f  adc    $0f,#$00
1198: 60        clrc
1199: 89 0c 0e  adc    ($0e),($0c)           ; + entry  -> pattern base (no echo)
119c: 89 0d 0f  adc    ($0f),($0d)
119f: e4 0e     mov    a,$0e
11a1: c5 94 02  mov    PatBaseTmp,a
11a4: e4 0f     mov    a,$0f
11a6: c5 95 02  mov    PatBaseTmp+1,a
11a9: f7 0c     mov    a,($0c)+y             ; tempo
11ab: c4 2f     mov    HdrTempo,a
11ad: fc        inc    y
11ae: f7 0c     mov    a,($0c)+y             ; song flags
11b0: c4 32     mov    HdrTrkFlags,a
11b2: c4 31     mov    HdrFlags,a
11b4: fc        inc    y
11b5: f7 0c     mov    a,($0c)+y             ; echo block present?
11b7: f0 17     beq    L11D0
11b9: fc        inc    y
11ba: 3f 68 18  call   SetEchoParams         ; program echo
11bd: dd        mov    a,y
11be: 60        clrc
11bf: 88 0b     adc    a,#$0b
11c1: fd        mov    y,a
11c2: 60        clrc                         ; pattern base += 12
11c3: e5 94 02  mov    a,PatBaseTmp
11c6: 88 0c     adc    a,#$0c
11c8: c5 94 02  mov    PatBaseTmp,a
11cb: 90 03     bcc    L11D0
11cd: ac 95 02  inc    PatBaseTmp+1

L11D0:
11d0: fc        inc    y
11d1: e8 01     mov    a,#$01                ; track number counter = 1
11d3: c5 96 02  mov    BankStart-1,a
.trackLoop:
11d6: fa 31 32  mov    (HdrTrkFlags),(HdrFlags)
11d9: f7 0c     mov    a,($0c)+y             ; track flags | song flags
11db: 04 32     or     a,HdrTrkFlags
11dd: c4 32     mov    HdrTrkFlags,a
11df: fc        inc    y
11e0: f7 0c     mov    a,($0c)+y             ; priority
11e2: c4 0f     mov    $0f,a
11e4: fc        inc    y
11e5: f7 0c     mov    a,($0c)+y             ; velocity
11e7: c4 3a     mov    Velocity,a
11e9: fc        inc    y
11ea: e5 78 02  mov    a,StartPan            ; StartPan bit7 set = take pan from the header
11ed: 10 07     bpl    L11F6
11ef: f7 0c     mov    a,($0c)+y
11f1: 08 80     or     a,#$80
11f3: c5 78 02  mov    StartPan,a

L11F6:
11f6: fc        inc    y
11f7: f7 0c     mov    a,($0c)+y             ; transpose
11f9: c4 44     mov    HdrTranspose,a
11fb: fc        inc    y
11fc: f7 0c     mov    a,($0c)+y             ; program
11fe: c4 0e     mov    $0e,a
1200: fc        inc    y
1201: f7 0c     mov    a,($0c)+y             ; data pointer = entry + offset
1203: 60        clrc
1204: 84 0c     adc    a,$0c
1206: c4 1f     mov    SeqPtr,a
1208: fc        inc    y
1209: f7 0c     mov    a,($0c)+y
120b: 84 0d     adc    a,$0d
120d: c4 20     mov    SeqPtr+1,a
120f: fc        inc    y
1210: 4d        push   x
1211: 6d        push   y
1212: f8 0e     mov    x,$0e
1214: eb 0f     mov    y,$0f
1216: 3f 3c 0f  call   AllocTrack            ; allocate + start this track
1219: ac 96 02  inc    BankStart-1
121c: ee        pop    y
121d: ce        pop    x
121e: 1d        dec    x
121f: f0 03     beq    L1224
1221: 5f d6 11  jmp    .trackLoop

L1224:
1224: 3f 64 0c  call   UnmuteDSP             ; sound started: unmute DSP
1227: 6f        ret

; FindNextTrackByID - next active track >= $1c whose TrkSoundID = $0a
; ($0a=$ff: any active track).  C=0 found (X), C=1 no more.
FindNextTrackByID:
1228: f8 1c     mov    x,CurTrack
122a: c8 16     cmp    x,#$16
122c: 90 02     bcc    L1230
122e: 80        setc
122f: 6f        ret

L1230:
1230: ab 1c     inc    CurTrack
1232: f5 b7 02  mov    a,TrkStatus+x
1235: 28 80     and    a,#$80
1237: f0 0c     beq    L1245
1239: 78 ff 0a  cmp    $0a,#$ff
123c: f0 0e     beq    L124C
123e: f5 e3 02  mov    a,TrkSoundID+x
1241: 64 0a     cmp    a,$0a
1243: f0 07     beq    L124C

L1245:
1245: 3d        inc    x
1246: c8 16     cmp    x,#$16
1248: 90 e6     bcc    L1230
124a: 80        setc
124b: 6f        ret

L124C:
124c: 60        clrc
124d: 6f        ret

; =============================================================================
; ReadVoiceStatus - $ff08-$ff0f = |ENVX| of voices 0-7,
;  $ff10 = bitmask of playing voices (for I/O command $16)
; =============================================================================
ReadVoiceStatus:
124e: 8d 08     mov    y,#$08
1250: 8f 78 f2  mov    DSPADDR,#$78          ; V7ENVX

L1253:
1253: e4 f3     mov    a,DSPDATA
1255: 10 03     bpl    L125A
1257: 48 ff     eor    a,#$ff
1259: bc        inc    a

L125A:
125a: d6 07 ff  mov    VEnvxStatus-1+y,a
125d: f6 da 00  mov    a,VoiceState-1+y
1260: 1c        asl    a
1261: 6b 21     ror    $21
1263: 80        setc
1264: b8 10 f2  sbc    DSPADDR,#$10
1267: fe ea     dbnz   y,L1253
1269: e4 21     mov    a,$21
126b: c5 10 ff  mov    VActiveMask,a
126e: 6f        ret

; =============================================================================
; SystemSubCommand - A = sub command, $0a = p1, $0b = p2
;  $02 stop sound ID p1 ($ff = all)       $04 write DSP register p1 = p2
;  $05 stop all tracks + voices           $06 pause (p2<>0) / resume (p2=0)
;  $07 clear instrument table + banks     $10 tempo offset of sound p1 = p2
;  $14 request stop of sound p1 at next loop/stop point (p2<>$ff: chain p2)
;  $15 master volume = p2                 $20 stereo mode = p1
;  $22 mute bit4 of p2, track p2&$0f (0=all) of sound p1
;  $4n program (p2<$80) or flag change (p2>=$80) - track n (0=all) of p1
;  $5n key offset (p2 in $c0-$3f) or transpose (p2 in $40-$bf, xor $80)
;  $6n pan  = p2, track n of sound p1
;  $7n volume (p2<$80) or velocity scale (p2>=$80), track n of sound p1
; =============================================================================
SystemSubCommand:
126f: 8f ff 0f  mov    $0f,#$ff
1272: 68 02     cmp    a,#$02
1274: d0 04     bne    L127A
1276: 3f 18 17  call   StopSound
1279: 6f        ret

L127A:
127a: 68 04     cmp    a,#$04
127c: d0 07     bne    L1285
127e: fa 0a f2  mov    (DSPADDR),($0a)
1281: fa 0b f3  mov    (DSPDATA),($0b)
1284: 6f        ret

L1285:
1285: 68 05     cmp    a,#$05
1287: d0 04     bne    L128D
1289: 3f 09 1c  call   StopAllTracks
128c: 6f        ret

L128D:
128d: 68 06     cmp    a,#$06
128f: d0 04     bne    L1295
1291: 3f 88 13  call   PauseResume
1294: 6f        ret

L1295:
1295: 68 07     cmp    a,#$07
1297: d0 12     bne    L12AB
1299: e8 ff     mov    a,#$ff                ; instrument SRCN table ($1e00-$1e7f) = $ff
129b: 8d 80     mov    y,#$80

L129D:
129d: d6 ff 1d  mov    InstSRCN-1+y,a
12a0: fe fb     dbnz   y,L129D
12a2: bc        inc    a                     ; BankStart/End list = 0
12a3: 8d 10     mov    y,#$10

L12A5:
12a5: d6 96 02  mov    BankStart-1+y,a
12a8: fe fb     dbnz   y,L12A5
12aa: 6f        ret

L12AB:
12ab: 68 10     cmp    a,#$10
12ad: d0 06     bne    L12B5
12af: 8f 06 0e  mov    $0e,#$06
12b2: 5f 1a 14  jmp    ApplyParamToSound

L12B5:
12b5: 68 14     cmp    a,#$14
12b7: d0 3b     bne    L12F4
12b9: 8f 02 10  mov    $10,#$02
12bc: 78 ff 0b  cmp    $0b,#$ff              ; p2 <> $ff : also set chain bit
12bf: f0 03     beq    L12C4
12c1: 18 10 10  or     $10,#$10

L12C4:
12c4: 8f 00 1c  mov    CurTrack,#$00

L12C7:
12c7: 3f 28 12  call   FindNextTrackByID
12ca: b0 0b     bcs    L12D7
12cc: f5 b7 02  mov    a,TrkStatus+x
12cf: 04 10     or     a,$10
12d1: d5 b7 02  mov    TrkStatus+x,a
12d4: 5f c7 12  jmp    L12C7

L12D7:
12d7: aa 10 80  mov1   c,$0010,4             ; C = chain bit
12da: 90 17     bcc    L12F3
12dc: 8d 06     mov    y,#$06

L12DE:
12de: f6 7b 02  mov    a,ChainList+y         ; find free chain slot (never read by the driver)
12e1: 68 ff     cmp    a,#$ff
12e3: f0 04     beq    L12E9
12e5: dc        dec    y
12e6: dc        dec    y
12e7: 10 f5     bpl    L12DE

L12E9:
12e9: e4 0a     mov    a,$0a
12eb: d6 7b 02  mov    ChainList+y,a
12ee: e4 0b     mov    a,$0b
12f0: d6 7c 02  mov    ChainList+1+y,a

L12F3:
12f3: 6f        ret

L12F4:
12f4: 68 15     cmp    a,#$15
12f6: d0 0e     bne    L1306
12f8: e4 0b     mov    a,$0b
12fa: c5 87 02  mov    MasterVolume,a
12fd: 8f 16 0e  mov    $0e,#$16
1300: 8f ff 0a  mov    $0a,#$ff
1303: 5f 1a 14  jmp    ApplyParamToSound

L1306:
1306: 68 20     cmp    a,#$20
1308: d0 04     bne    L130E
130a: fa 0a 25  mov    (StereoMode),($0a)
130d: 6f        ret

L130E:
130e: 68 22     cmp    a,#$22
1310: d0 12     bne    L1324
1312: e4 0b     mov    a,$0b
1314: 28 0f     and    a,#$0f
1316: d0 01     bne    L1319
1318: 9c        dec    a                     ; track 0 -> $ff (all tracks)

L1319:
1319: c4 0f     mov    $0f,a
131b: 38 f0 0b  and    $0b,#$f0
131e: 8f 10 0e  mov    $0e,#$10              ; param $10 (mute)
1321: 5f 1a 14  jmp    ApplyParamToSound

L1324:
1324: 68 70     cmp    a,#$70
1326: 90 15     bcc    L133D
1328: 80        setc
1329: a8 71     sbc    a,#$71
132b: 30 01     bmi    L132E
132d: bc        inc    a

L132E:
132e: c4 0f     mov    $0f,a
1330: 8f 08 0e  mov    $0e,#$08
1333: e4 0b     mov    a,$0b
1335: 30 03     bmi    L133A
1337: 8f 00 0e  mov    $0e,#$00

L133A:
133a: 5f 1a 14  jmp    ApplyParamToSound

L133D:
133d: 68 60     cmp    a,#$60
133f: 90 0e     bcc    L134F
1341: 80        setc
1342: a8 61     sbc    a,#$61
1344: 30 01     bmi    L1347
1346: bc        inc    a

L1347:
1347: c4 0f     mov    $0f,a
1349: 8f 02 0e  mov    $0e,#$02
134c: 5f 1a 14  jmp    ApplyParamToSound

L134F:
134f: 68 50     cmp    a,#$50
1351: 90 1b     bcc    L136E
1353: 80        setc
1354: a8 51     sbc    a,#$51
1356: 30 01     bmi    L1359
1358: bc        inc    a

L1359:
1359: c4 0f     mov    $0f,a
135b: 8f 04 0e  mov    $0e,#$04
135e: e4 0b     mov    a,$0b
1360: 1c        asl    a
1361: 44 0b     eor    a,$0b
1363: 10 06     bpl    L136B
1365: 8f 0c 0e  mov    $0e,#$0c
1368: 58 80 0b  eor    $0b,#$80

L136B:
136b: 5f 1a 14  jmp    ApplyParamToSound

L136E:
136e: 68 40     cmp    a,#$40
1370: 90 15     bcc    L1387
1372: 80        setc
1373: a8 41     sbc    a,#$41
1375: 30 01     bmi    L1378
1377: bc        inc    a

L1378:
1378: c4 0f     mov    $0f,a
137a: 8f 0e 0e  mov    $0e,#$0e
137d: e4 0b     mov    a,$0b
137f: 10 03     bpl    L1384
1381: 8f 12 0e  mov    $0e,#$12

L1384:
1384: 5f 1a 14  jmp    ApplyParamToSound

L1387:
1387: 6f        ret

PauseResume:
1388: 8f ff 0a  mov    $0a,#$ff
138b: e4 0b     mov    a,$0b
138d: f0 06     beq    L1395
138f: e8 40     mov    a,#$40
1391: c5 83 02  mov    PauseState,a
1394: 6f        ret

L1395:
1395: c5 83 02  mov    PauseState,a
1398: 8f 14 0e  mov    $0e,#$14
139b: 5f 5f 14  jmp    ApplyParamToVoices

; StopAllAudio - system $01: stop all voices + tracks, echo off
StopAllAudio:
139e: e8 00     mov    a,#$00
13a0: c4 2e     mov    TicksElapsed,a
13a2: 3f c1 13  call   KeyOffAllVoices
13a5: cd 00     mov    x,#$00
13a7: e8 00     mov    a,#$00

L13A9:
13a9: d5 b7 02  mov    TrkStatus+x,a
13ac: 3d        inc    x
13ad: c8 16     cmp    x,#$16
13af: d0 f8     bne    L13A9
13b1: e8 00     mov    a,#$00
13b3: 3f e8 18  call   SetEchoDelay
13b6: e8 00     mov    a,#$00
13b8: 3f 9d 18  call   SetEchoVolL
13bb: e8 00     mov    a,#$00
13bd: 3f b6 18  call   SetEchoVolR
13c0: 6f        ret

KeyOffAllVoices:
13c1: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
13c4: 8f ff f3  mov    DSPDATA,#$ff
13c7: cd 00     mov    x,#$00

L13C9:
13c9: e8 00     mov    a,#$00
13cb: d4 db     mov    VoiceState+x,a
13cd: 3d        inc    x
13ce: c8 08     cmp    x,#$08
13d0: d0 f7     bne    L13C9
13d2: 6f        ret

; =============================================================================
; ProcessFades - status bit3 (fade) : decrement TrkVolume / VVolume each tick,
;  stop at 0.  Nothing in this build sets bit3, so it is effectively unused.
; =============================================================================
ProcessFades:
13d3: cd 15     mov    x,#$15

L13D5:
13d5: f5 b7 02  mov    a,TrkStatus+x
13d8: 28 80     and    a,#$80
13da: f0 16     beq    L13F2
13dc: f5 b7 02  mov    a,TrkStatus+x
13df: 28 08     and    a,#$08
13e1: f0 0f     beq    L13F2
13e3: f5 59 04  mov    a,TrkVolume+x
13e6: d0 06     bne    L13EE
13e8: d5 b7 02  mov    TrkStatus+x,a
13eb: 5f f2 13  jmp    L13F2

L13EE:
13ee: 9c        dec    a
13ef: d5 59 04  mov    TrkVolume+x,a

L13F2:
13f2: 1d        dec    x
13f3: 10 e0     bpl    L13D5
13f5: cd 07     mov    x,#$07

L13F7:
13f7: f4 db     mov    a,VoiceState+x
13f9: 28 80     and    a,#$80
13fb: f0 19     beq    L1416
13fd: f4 db     mov    a,VoiceState+x
13ff: 28 08     and    a,#$08
1401: f0 13     beq    L1416
1403: f5 67 05  mov    a,VVolume+x
1406: d0 05     bne    L140D
1408: d4 db     mov    VoiceState+x,a
140a: 5f 16 14  jmp    L1416

L140D:
140d: 4d        push   x
140e: 9c        dec    a
140f: d5 67 05  mov    VVolume+x,a
1412: 3f 84 15  call   CalcVoiceVolume
1415: ce        pop    x

L1416:
1416: 1d        dec    x
1417: 10 de     bpl    L13F7
1419: 6f        ret

; =============================================================================
; ApplyParamToSound - param $0e = value $0b for all tracks of sound $0a
;  ($ff = all sounds) and track number $0f ($ff = all), then voices.
; =============================================================================
ApplyParamToSound:
141a: 8d 15     mov    y,#$15
141c: 78 ff 0a  cmp    $0a,#$ff
141f: f0 1f     beq    L1440
1421: 78 ff 0f  cmp    $0f,#$ff
1424: f0 26     beq    L144C

L1426:
1426: e4 0a     mov    a,$0a
1428: 76 e3 02  cmp    a,TrkSoundID+y
142b: d0 0e     bne    L143B
142d: e4 0f     mov    a,$0f
142f: 76 d5 03  cmp    a,TrkNumber+y
1432: d0 07     bne    L143B
1434: f8 0e     mov    x,$0e
1436: e4 0b     mov    a,$0b
1438: 3f a6 05  call   TrkParamDispatch

L143B:
143b: dc        dec    y
143c: 10 e8     bpl    L1426
143e: 2f 1f     bra    ApplyParamToVoices

L1440:
1440: f8 0e     mov    x,$0e
1442: e4 0b     mov    a,$0b
1444: 3f a6 05  call   TrkParamDispatch
1447: dc        dec    y
1448: 10 f6     bpl    L1440
144a: 2f 13     bra    ApplyParamToVoices

L144C:
144c: e4 0a     mov    a,$0a
144e: 76 e3 02  cmp    a,TrkSoundID+y
1451: d0 07     bne    L145A
1453: f8 0e     mov    x,$0e
1455: e4 0b     mov    a,$0b
1457: 3f a6 05  call   TrkParamDispatch

L145A:
145a: dc        dec    y
145b: 10 ef     bpl    L144C
145d: 2f 00     bra    ApplyParamToVoices

ApplyParamToVoices:
145f: 8d 07     mov    y,#$07
1461: 78 ff 0a  cmp    $0a,#$ff
1464: f0 23     beq    L1489
1466: 78 ff 0f  cmp    $0f,#$ff
1469: f0 2e     beq    L1499

L146B:
146b: e4 0a     mov    a,$0a
146d: 76 a3 00  cmp    a,VSoundID+y
1470: d0 13     bne    L1485
1472: e4 0f     mov    a,$0f
1474: 76 0f 05  cmp    a,VTrkNumber+y
1477: d0 0c     bne    L1485
1479: f6 db 00  mov    a,VoiceState+y
147c: 10 07     bpl    L1485
147e: f8 0e     mov    x,$0e
1480: e4 0b     mov    a,$0b
1482: 3f c3 05  call   VoiceParamDispatch

L1485:
1485: dc        dec    y
1486: 10 e3     bpl    L146B
1488: 6f        ret

L1489:
1489: f6 db 00  mov    a,VoiceState+y
148c: 10 07     bpl    L1495
148e: f8 0e     mov    x,$0e
1490: e4 0b     mov    a,$0b
1492: 3f c3 05  call   VoiceParamDispatch

L1495:
1495: dc        dec    y
1496: 10 f1     bpl    L1489
1498: 6f        ret

L1499:
1499: e4 0a     mov    a,$0a
149b: 76 a3 00  cmp    a,VSoundID+y
149e: d0 0c     bne    L14AC
14a0: f6 db 00  mov    a,VoiceState+y
14a3: 10 07     bpl    L14AC
14a5: f8 0e     mov    x,$0e
14a7: e4 0b     mov    a,$0b
14a9: 3f c3 05  call   VoiceParamDispatch

L14AC:
14ac: dc        dec    y
14ad: 10 ea     bpl    L1499
14af: 6f        ret

; --- track parameter setters (Y = track, A = value) ----------------------
TP_ChanVolume:
14b0: d6 94 ff  mov    TrkChanVol+y,a
14b3: 6f        ret

TP_Volume:
14b4: d6 59 04  mov    TrkVolume+y,a
14b7: 6f        ret

TP_Pan:
14b8: d6 9b 04  mov    TrkPan+y,a
14bb: 6f        ret

TP_Transpose:
14bc: d6 6f 04  mov    TrkTranspose+y,a
14bf: 6f        ret

TP_TempoOffset:
14c0: 6d        push   y
14c1: ce        pop    x
14c2: d5 b1 04  mov    TrkTempoOfs+x,a
14c5: 60        clrc
14c6: 95 76 ff  adc    a,TrkTempo+x
14c9: 3f 1b 0b  call   CalcTempo
14cc: 6f        ret

TP_Velocity:
14cd: d6 43 04  mov    TrkVelocity+y,a

TP_Nop:
14d0: 6f        ret

TP_PitchBend:
14d1: e4 13     mov    a,$13
14d3: d6 eb 03  mov    TrkBendHi+y,a
14d6: e4 12     mov    a,$12
14d8: d6 01 04  mov    TrkBendLo+y,a
14db: 6f        ret

TP_KeyOffset:
14dc: d6 85 04  mov    TrkKeyOffset+y,a
14df: 6f        ret

TP_Program:
14e0: d6 f9 02  mov    TrkProgram+y,a
14e3: 6f        ret

TP_Mute:
14e4: 28 10     and    a,#$10                ; value bit4 -> TrkStatus bit0 (muted: notes are skipped)
14e6: d0 08     bne    L14F0
14e8: f6 b7 02  mov    a,TrkStatus+y
14eb: 28 fe     and    a,#$fe
14ed: 5f f5 14  jmp    L14F5

L14F0:
14f0: f6 b7 02  mov    a,TrkStatus+y
14f3: 08 01     or     a,#$01

L14F5:
14f5: d6 b7 02  mov    TrkStatus+y,a
14f8: 6f        ret

; TP_Flags - value bits 1/3/5 = new state of flag bits 1/3/5,
;            value bits 0/2/4 = "change flag bit 1/3/5" masks
TP_Flags:
14f9: 2d        push   a
14fa: 28 2a     and    a,#$2a
14fc: c4 06     mov    $06,a
14fe: ae        pop    a
14ff: 28 15     and    a,#$15
1501: 1c        asl    a
1502: 48 ff     eor    a,#$ff
1504: c4 07     mov    $07,a
1506: f6 0f 03  mov    a,TrkFlags+y
1509: 24 07     and    a,$07
150b: 04 06     or     a,$06
150d: d6 0f 03  mov    TrkFlags+y,a

TP_Ret:
1510: 6f        ret

; --- voice parameter setters (Y = voice, A = value) ----------------------
VP_ChanVolume:
1511: d6 8c ff  mov    VChanVol+y,a
1514: 2f 03     bra    VP_UpdateVolume

VP_Volume:
1516: d6 67 05  mov    VVolume+y,a

VP_UpdateVolume:
1519: 3f 84 15  call   CalcVoiceVolume

VP_Nop:
151c: 6f        ret

VP_Pan:
151d: d6 3a ff  mov    VPan+y,a
1520: 2f f7     bra    VP_UpdateVolume

VP_Velocity:
1522: d6 6f 05  mov    VVelScale+y,a
1525: 2f f2     bra    VP_UpdateVolume

VP_Transpose:
1527: d6 12 ff  mov    VTranspose+y,a

VP_UpdatePitch:
152a: 3f 3f 16  call   CalcVoicePitch
152d: 6f        ret

VP_PitchBend:
152e: e4 13     mov    a,$13
1530: d6 cf 04  mov    VBendHi+y,a
1533: e4 12     mov    a,$12
1535: d6 c7 04  mov    VBendLo+y,a
1538: 2f f0     bra    VP_UpdatePitch

VP_KeyOffset:
153a: d6 1a ff  mov    VKeyOffset+y,a
153d: 2f eb     bra    VP_UpdatePitch

VP_Mute:
153f: 28 10     and    a,#$10
1541: d0 08     bne    L154B
1543: f6 e3 00  mov    a,VMod+y
1546: 28 fd     and    a,#$fd
1548: 5f 50 15  jmp    L1550

L154B:
154b: f6 e3 00  mov    a,VMod+y
154e: 08 02     or     a,#$02

L1550:
1550: d6 e3 00  mov    VMod+y,a
1553: 2f c4     bra    VP_UpdateVolume

VP_Flags:
1555: 2d        push   a
1556: 28 2a     and    a,#$2a
1558: c4 06     mov    $06,a
155a: ae        pop    a
155b: 28 15     and    a,#$15
155d: 1c        asl    a
155e: 48 ff     eor    a,#$ff
1560: c4 07     mov    $07,a
1562: f6 07 05  mov    a,VFlags+y
1565: 24 07     and    a,$07
1567: 04 06     or     a,$06
1569: d6 07 05  mov    VFlags+y,a
156c: 3f 84 15  call   CalcVoiceVolume
156f: 6f        ret

VP_Pause:
1570: 28 ff     and    a,#$ff                ; value <> 0 : silence (VOL L/R = 0), value 0 : recompute volume
1572: f0 0e     beq    L1582
1574: f6 e1 05  mov    a,VoiceDspBase+y
1577: c4 f2     mov    DSPADDR,a
1579: e8 00     mov    a,#$00
157b: c4 f3     mov    DSPDATA,a
157d: ab f2     inc    DSPADDR
157f: c4 f3     mov    DSPDATA,a
1581: 6f        ret

L1582:
1582: 2f 00     bra    CalcVoiceVolume

; =============================================================================
; CalcVoiceVolume - Y = voice.  v = VVelocityAdj * f(VVelScale) * f(VVolume)
;  * f(VChanVol) * g(MasterVolume), with f(n) = (2n+2)/256 (n=$7f -> 1.0,
;  n=0 -> 0) and g(m) = 2m/256 (m>=$80 -> 1.0).
;  Pan p (0-$7f, $40 = centre): R = v*2p/256, L = v*($ff-2p)/256.
;  StereoMode 0: mono (L=R=(L+R)/2); 2: invert R if VFlags bit5 (surround).
;  Written to VOL L/R unless tremolo is running (then via ApplyTremolo).
; =============================================================================
CalcVoiceVolume:
1584: f6 e1 05  mov    a,VoiceDspBase+y
1587: c4 f2     mov    DSPADDR,a
1589: 6d        push   y
158a: dd        mov    a,y
158b: 5d        mov    x,a
158c: f5 77 05  mov    a,VVelocityAdj+x      ; VVelocityAdj
158f: fd        mov    y,a
1590: f5 6f 05  mov    a,VVelScale+x         ; VVelScale
1593: d0 04     bne    L1599
1595: fd        mov    y,a
1596: 5f 9f 15  jmp    L159F

L1599:
1599: 80        setc
159a: 3c        rol    a
159b: bc        inc    a
159c: f0 01     beq    L159F
159e: cf        mul    ya

L159F:
159f: f5 67 05  mov    a,VVolume+x           ; VVolume
15a2: d0 04     bne    L15A8
15a4: fd        mov    y,a
15a5: 5f ae 15  jmp    L15AE

L15A8:
15a8: 80        setc
15a9: 3c        rol    a
15aa: bc        inc    a
15ab: f0 01     beq    L15AE
15ad: cf        mul    ya

L15AE:
15ae: f5 8c ff  mov    a,VChanVol+x          ; VChanVol
15b1: d0 04     bne    L15B7
15b3: fd        mov    y,a
15b4: 5f bd 15  jmp    L15BD

L15B7:
15b7: 80        setc
15b8: 3c        rol    a
15b9: bc        inc    a
15ba: f0 01     beq    L15BD
15bc: cf        mul    ya

L15BD:
15bd: e5 87 02  mov    a,MasterVolume        ; MasterVolume
15c0: 1c        asl    a
15c1: b0 07     bcs    L15CA
15c3: d0 04     bne    L15C9
15c5: fd        mov    y,a
15c6: 5f ca 15  jmp    L15CA

L15C9:
15c9: cf        mul    ya

L15CA:
15ca: cb 3b     mov    VolTmpL,y             ; $3b/$3c = level
15cc: cb 3c     mov    VolTmpR,y
15ce: f5 3a ff  mov    a,VPan+x              ; VPan * 2
15d1: 1c        asl    a
15d2: c4 18     mov    $18,a
15d4: eb 3c     mov    y,VolTmpR
15d6: cf        mul    ya
15d7: cb 3c     mov    VolTmpR,y             ; right
15d9: e8 ff     mov    a,#$ff
15db: 80        setc
15dc: a4 18     sbc    a,$18
15de: eb 3b     mov    y,VolTmpL
15e0: cf        mul    ya
15e1: cb 3b     mov    VolTmpL,y             ; left
15e3: 78 00 25  cmp    StereoMode,#$00       ; StereoMode 0 : mono
15e6: d0 0d     bne    L15F5
15e8: e4 3c     mov    a,VolTmpR
15ea: 60        clrc
15eb: 84 3b     adc    a,VolTmpL
15ed: 7c        ror    a
15ee: c4 3c     mov    VolTmpR,a
15f0: c4 3b     mov    VolTmpL,a
15f2: 5f 06 16  jmp    L1606

L15F5:
15f5: 78 02 25  cmp    StereoMode,#$02       ; StereoMode 2 : surround
15f8: d0 0c     bne    L1606
15fa: f5 07 05  mov    a,VFlags+x
15fd: 28 20     and    a,#$20
15ff: f0 05     beq    L1606
1601: 58 ff 3c  eor    VolTmpR,#$ff
1604: ab 3c     inc    VolTmpR

L1606:
1606: ee        pop    y
1607: f6 e3 00  mov    a,VMod+y              ; VMod bit1 : voice muted
160a: 28 02     and    a,#$02
160c: f0 06     beq    L1614
160e: 8f 00 3b  mov    VolTmpL,#$00
1611: 8f 00 3c  mov    VolTmpR,#$00

L1614:
1614: f4 db     mov    a,VoiceState+x        ; tremolo running?
1616: 28 20     and    a,#$20
1618: d0 11     bne    L162B
161a: e4 3b     mov    a,VolTmpL             ; VVolL, write VOL L
161c: d6 df 04  mov    VVolL+y,a
161f: c4 f3     mov    DSPDATA,a
1621: ab f2     inc    DSPADDR
1623: e4 3c     mov    a,VolTmpR             ; VVolR, write VOL R
1625: d6 e7 04  mov    VVolR+y,a
1628: c4 f3     mov    DSPDATA,a
162a: 6f        ret

L162B:
162b: 4d        push   x
162c: e4 3b     mov    a,VolTmpL
162e: d6 df 04  mov    VVolL+y,a
1631: e4 3c     mov    a,VolTmpR
1633: d6 e7 04  mov    VVolR+y,a
1636: dd        mov    a,y
1637: 5d        mov    x,a
1638: 3f ac 17  call   ApplyTremolo
163b: 7d        mov    a,x
163c: fd        mov    y,a
163d: ce        pop    x
163e: 6f        ret

; =============================================================================
; CalcVoicePitch - Y = voice.  Compute and write P(L)/P(H).
;  pitch = VBaseNote + VKeyOffset + VTranspose + VBendHi (semitones)
;        + (VFineTune + VBendLo + VVibOffset)/256
;  Every BRR sample carries a 27-byte header in front of its DIR start:
;    start-27 : 13 words = pitch values for the 12 semitones of one octave
;               (+ the next C) for "base octave"
;    start-1  : base octave number
;  P = table[note%12] interpolated towards table[note%12+1] by the
;  fraction, then shifted left/right by (note/12 - base octave).
; =============================================================================
CalcVoicePitch:
163f: 8f 00 06  mov    $06,#$00
1642: 8f 23 07  mov    $07,#$23
1645: 6d        push   y
1646: 8f 00 15  mov    $15,#$00
1649: f6 47 05  mov    a,VVibOffset+y        ; VVibOffset (signed) -> $14/$15
164c: c4 14     mov    $14,a
164e: 10 02     bpl    L1652
1650: 8b 15     dec    $15

L1652:
1652: f6 2a ff  mov    a,VFineTune+y         ; VFineTune + VBendLo
1655: 60        clrc
1656: 96 c7 04  adc    a,VBendLo+y
1659: c4 21     mov    $21,a
165b: f6 1a ff  mov    a,VKeyOffset+y        ; VKeyOffset + VBaseNote + VBendHi + VTranspose
165e: 96 22 ff  adc    a,VBaseNote+y
1661: 60        clrc
1662: 96 cf 04  adc    a,VBendHi+y
1665: 60        clrc
1666: 96 12 ff  adc    a,VTranspose+y
1669: cb 1a     mov    $1a,y
166b: fd        mov    y,a
166c: e4 21     mov    a,$21
166e: 7a 14     addw   ya,$14                ; + vibrato
1670: c4 21     mov    $21,a
1672: dd        mov    a,y
1673: 2d        push   a
1674: eb 1a     mov    y,$1a
1676: 8f 00 07  mov    $07,#$00
1679: f6 d7 04  mov    a,VSRCN+y             ; VSRCN * 4 + $2300 -> DIR entry
167c: 1c        asl    a
167d: 2b 07     rol    $07
167f: 1c        asl    a
1680: 2b 07     rol    $07
1682: 98 23 07  adc    $07,#$23
1685: c4 06     mov    $06,a
1687: 8d 01     mov    y,#$01                ; sample start address
1689: f7 06     mov    a,($06)+y
168b: c4 15     mov    $15,a
168d: dc        dec    y
168e: f7 06     mov    a,($06)+y
1690: 80        setc                         ; - 27 : pitch header
1691: a8 1b     sbc    a,#$1b
1693: b8 00 15  sbc    $15,#$00
1696: c4 14     mov    $14,a
1698: ae        pop    a
1699: 8d 00     mov    y,#$00
169b: cd 0c     mov    x,#$0c                ; note / 12
169d: 9e        div    ya,x
169e: cb 06     mov    $06,y
16a0: 8d 1a     mov    y,#$1a                ; octave - base octave  (header byte at start-1)
16a2: 80        setc
16a3: b7 14     sbc    a,($14)+y
16a5: c4 07     mov    $07,a
16a7: e4 06     mov    a,$06                 ; note%12 * 2
16a9: 1c        asl    a
16aa: fd        mov    y,a
16ab: f7 14     mov    a,($14)+y             ; table[n]
16ad: c4 16     mov    $16,a
16af: fc        inc    y
16b0: f7 14     mov    a,($14)+y
16b2: c4 17     mov    $17,a
16b4: e4 21     mov    a,$21                 ; fraction = 0 -> no interpolation
16b6: f0 23     beq    L16DB
16b8: fc        inc    y                     ; table[n+1]
16b9: f7 14     mov    a,($14)+y
16bb: c4 18     mov    $18,a
16bd: fc        inc    y
16be: f7 14     mov    a,($14)+y
16c0: c4 19     mov    $19,a
16c2: 8f 00 15  mov    $15,#$00
16c5: ba 18     movw   ya,$18                ; ($18-$16) * fraction / 256 + $16
16c7: 9a 16     subw   ya,$16
16c9: cb 06     mov    $06,y
16cb: eb 21     mov    y,$21
16cd: cf        mul    ya
16ce: cb 14     mov    $14,y
16d0: e4 06     mov    a,$06
16d2: eb 21     mov    y,$21
16d4: cf        mul    ya
16d5: 7a 14     addw   ya,$14
16d7: 7a 16     addw   ya,$16
16d9: da 16     movw   $16,ya

L16DB:
16db: eb 07     mov    y,$07                 ; shift by octave difference
16dd: f0 13     beq    L16F2
16df: 30 0a     bmi    L16EB

L16E1:
16e1: 0b 16     asl    $16
16e3: 2b 17     rol    $17
16e5: dc        dec    y
16e6: d0 f9     bne    L16E1
16e8: 5f f2 16  jmp    L16F2

L16EB:
16eb: 4b 17     lsr    $17
16ed: 6b 16     ror    $16
16ef: fc        inc    y
16f0: d0 f9     bne    L16EB

L16F2:
16f2: eb 1a     mov    y,$1a
16f4: f6 e1 05  mov    a,VoiceDspBase+y      ; P(L)
16f7: bc        inc    a
16f8: bc        inc    a
16f9: c4 f2     mov    DSPADDR,a
16fb: 2d        push   a
16fc: f8 16     mov    x,$16
16fe: f6 32 ff  mov    a,VInstFlags2+y       ; VInstFlags2 bit0 : clear low nibble of P(L)
1701: 28 01     and    a,#$01
1703: d0 05     bne    L170A
1705: d8 f3     mov    DSPDATA,x
1707: 5f 0f 17  jmp    L170F

L170A:
170a: 7d        mov    a,x
170b: 28 f0     and    a,#$f0
170d: c4 f3     mov    DSPDATA,a

L170F:
170f: ae        pop    a
1710: bc        inc    a
1711: c4 f2     mov    DSPADDR,a             ; P(H)
1713: fa 17 f3  mov    (DSPDATA),($17)
1716: ee        pop    y
1717: 6f        ret

; =============================================================================
; StopSound - stop all tracks + voices of sound ID $0a ($ff = everything)
; =============================================================================
StopSound:
1718: 8f 00 1c  mov    CurTrack,#$00

L171B:
171b: 3f 28 12  call   FindNextTrackByID
171e: b0 08     bcs    L1728
1720: e8 00     mov    a,#$00
1722: d5 b7 02  mov    TrkStatus+x,a
1725: 5f 1b 17  jmp    L171B

L1728:
1728: 8f 00 10  mov    $10,#$00              ; KOF mask
172b: 8d 07     mov    y,#$07

L172D:
172d: f6 db 00  mov    a,VoiceState+y
1730: 28 83     and    a,#$83
1732: f0 25     beq    L1759
1734: 78 ff 0a  cmp    $0a,#$ff
1737: f0 14     beq    L174D
1739: 28 03     and    a,#$03                ; key-on pending: use the track's ID
173b: d0 05     bne    L1742
173d: f6 a3 00  mov    a,VSoundID+y          ; playing: VSoundID
1740: 2f 07     bra    L1749

L1742:
1742: f6 27 05  mov    a,VTrack+y
1745: 5d        mov    x,a
1746: f5 e3 02  mov    a,TrkSoundID+x

L1749:
1749: 64 0a     cmp    a,$0a
174b: d0 0c     bne    L1759

L174D:
174d: f6 e9 05  mov    a,VoiceBitMask+y
1750: 04 10     or     a,$10
1752: c4 10     mov    $10,a
1754: e8 00     mov    a,#$00
1756: d6 db 00  mov    VoiceState+y,a

L1759:
1759: dc        dec    y
175a: 10 d1     bpl    L172D
175c: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
175f: fa 10 f3  mov    (DSPDATA),($10)
1762: 6f        ret

; TremoloUpdate - per tick: delay, then ApplyTremolo and advance the phase
;  (triangle 0..$3f, bit7 = direction) by VInstFlags2 high nibble.
TremoloUpdate:
1763: f5 57 05  mov    a,VTremDelay+x
1766: f0 05     beq    L176D
1768: 9c        dec    a
1769: d5 57 05  mov    VTremDelay+x,a
176c: 6f        ret

L176D:
176d: f5 e1 05  mov    a,VoiceDspBase+x
1770: c4 f2     mov    DSPADDR,a
1772: c4 0c     mov    $0c,a
1774: 3f ac 17  call   ApplyTremolo
1777: f5 32 ff  mov    a,VInstFlags2+x
177a: 9f        xcn    a
177b: 28 0f     and    a,#$0f
177d: c4 0c     mov    $0c,a
177f: f5 5f 05  mov    a,VTremPhase+x
1782: 30 15     bmi    L1799
1784: 60        clrc
1785: 84 0c     adc    a,$0c
1787: 68 40     cmp    a,#$40
1789: 90 0b     bcc    L1796
178b: 28 3f     and    a,#$3f
178d: 48 ff     eor    a,#$ff
178f: 60        clrc
1790: 88 40     adc    a,#$40
1792: 28 3f     and    a,#$3f
1794: 08 80     or     a,#$80

L1796:
1796: 5f a8 17  jmp    L17A8

L1799:
1799: 28 3f     and    a,#$3f
179b: 80        setc
179c: a4 0c     sbc    a,$0c
179e: 30 05     bmi    L17A5
17a0: 08 80     or     a,#$80
17a2: 5f a8 17  jmp    L17A8

L17A5:
17a5: 48 ff     eor    a,#$ff
17a7: bc        inc    a

L17A8:
17a8: d5 5f 05  mov    VTremPhase+x,a
17ab: 6f        ret

; ApplyTremolo - VOL = VVol * (255 - (phase/4)*(depth+1)) / 256
ApplyTremolo:
17ac: f5 5f 05  mov    a,VTremPhase+x
17af: 5c        lsr    a
17b0: 5c        lsr    a
17b1: 28 0f     and    a,#$0f
17b3: c4 09     mov    $09,a
17b5: fd        mov    y,a
17b6: f5 4f 05  mov    a,VTremDepth+x
17b9: 28 0f     and    a,#$0f
17bb: c4 0b     mov    $0b,a
17bd: bc        inc    a
17be: cf        mul    ya
17bf: 48 ff     eor    a,#$ff
17c1: c4 0a     mov    $0a,a
17c3: fd        mov    y,a
17c4: f5 df 04  mov    a,VVolL+x
17c7: cf        mul    ya
17c8: cb f3     mov    DSPDATA,y
17ca: ab f2     inc    DSPADDR
17cc: eb 0a     mov    y,$0a
17ce: f5 e7 04  mov    a,VVolR+x
17d1: 30 04     bmi    L17D7
17d3: cf        mul    ya
17d4: cb f3     mov    DSPDATA,y
17d6: 6f        ret

L17D7:
17d7: 48 ff     eor    a,#$ff
17d9: bc        inc    a
17da: cf        mul    ya
17db: dd        mov    a,y
17dc: 48 ff     eor    a,#$ff
17de: bc        inc    a
17df: c4 f3     mov    DSPDATA,a
17e1: 6f        ret

; VibratoUpdate - per tick: delay, then CalcVoicePitch and move VVibOffset
;  as a triangle wave between -VVibDepth and +VVibDepth, step VVibRate&$0f.
;  VMod bit0 = direction.
VibratoUpdate:
17e2: f5 3f 05  mov    a,VVibDelay+x
17e5: f0 05     beq    L17EC
17e7: 9c        dec    a
17e8: d5 3f 05  mov    VVibDelay+x,a
17eb: 6f        ret

L17EC:
17ec: 4d        push   x
17ed: 7d        mov    a,x
17ee: fd        mov    y,a
17ef: 3f 3f 16  call   CalcVoicePitch
17f2: ce        pop    x
17f3: f5 2f 05  mov    a,VVibRate+x
17f6: 28 0f     and    a,#$0f
17f8: c4 0c     mov    $0c,a
17fa: f5 37 05  mov    a,VVibDepth+x
17fd: c4 08     mov    $08,a
17ff: 48 ff     eor    a,#$ff
1801: bc        inc    a
1802: c4 09     mov    $09,a
1804: f4 e3     mov    a,VMod+x
1806: c4 0a     mov    $0a,a
1808: 03 0a 21  bbs0   $0a,L182C
180b: 80        setc
180c: f5 47 05  mov    a,VVibOffset+x
180f: a4 0c     sbc    a,$0c
1811: 70 0a     bvs    L181D
1813: 68 80     cmp    a,#$80
1815: 90 12     bcc    L1829
1817: 64 09     cmp    a,$09
1819: f0 02     beq    L181D
181b: b0 0c     bcs    L1829

L181D:
181d: 80        setc
181e: a4 09     sbc    a,$09
1820: 48 ff     eor    a,#$ff
1822: bc        inc    a
1823: 60        clrc
1824: 84 09     adc    a,$09
1826: 58 01 0a  eor    $0a,#$01

L1829:
1829: 5f 48 18  jmp    L1848

L182C:
182c: 60        clrc
182d: f5 47 05  mov    a,VVibOffset+x
1830: 84 0c     adc    a,$0c
1832: 70 08     bvs    L183C
1834: 68 80     cmp    a,#$80
1836: b0 10     bcs    L1848
1838: 64 08     cmp    a,$08
183a: 90 0c     bcc    L1848

L183C:
183c: 80        setc
183d: a4 08     sbc    a,$08
183f: 48 ff     eor    a,#$ff
1841: bc        inc    a
1842: 60        clrc
1843: 84 08     adc    a,$08
1845: 58 01 0a  eor    $0a,#$01

L1848:
1848: d5 47 05  mov    VVibOffset+x,a
184b: e4 0a     mov    a,$0a
184d: d4 e3     mov    VMod+x,a
184f: 6f        ret

; -----------------------------------------------------------------------------
; EchoRegList - DSP register numbers EDL, EVOL L, EVOL R, EFB, FIR0-7.
; Not referenced by the code (documentation/leftover table).
; -----------------------------------------------------------------------------
EchoRegList:
1850: db    $7d,$2c,$3c,$0d,$0f,$1f,$2f,$3f,$4f,$5f,$6f,$7f ; EDL EVOLL EVOLR EFB FIR0..7

; EchoDefaults - default echo parameters used by InitDSP
; (EDL 0, EVOL 0/0, EFB 0, FIR = $7f,0,0,0,0,0,0,0)
EchoDefaults:
185c: db    $00,$00,$00,$00,$7f,$00,$00,$00,$00,$00,$00,$00

; =============================================================================
; SetEchoParams - ($0c)+Y -> EDL, EVOL L, EVOL R, EFB, FIR0-7 (12 bytes)
; =============================================================================
SetEchoParams:
1868: 6d        push   y
1869: f7 0c     mov    a,($0c)+y
186b: 3f e8 18  call   SetEchoDelay
186e: fc        inc    y
186f: f7 0c     mov    a,($0c)+y
1871: 3f 9d 18  call   SetEchoVolL
1874: fc        inc    y
1875: f7 0c     mov    a,($0c)+y
1877: 3f b6 18  call   SetEchoVolR
187a: fc        inc    y
187b: f7 0c     mov    a,($0c)+y
187d: 3f cf 18  call   SetEchoFeedback
1880: fc        inc    y
1881: 3f 86 18  call   SetFIR
1884: ee        pop    y
1885: 6f        ret

SetFIR:
1886: 4d        push   x
1887: 8f 0f 4a  mov    FirReg,#$0f
188a: cd 08     mov    x,#$08

L188C:
188c: f7 0c     mov    a,($0c)+y
188e: fc        inc    y
188f: fa 4a f2  mov    (DSPADDR),(FirReg)
1892: c4 f3     mov    DSPDATA,a
1894: 60        clrc
1895: 98 10 4a  adc    FirReg,#$10
1898: 1d        dec    x
1899: d0 f1     bne    L188C
189b: ce        pop    x
189c: 6f        ret

; SetEchoVolL/R, SetEchoFeedback - store target; write DSP directly only
; when the echo start-up sequence has finished (EchoPhase >= 2).
SetEchoVolL:
189d: 2d        push   a
189e: e5 8e 02  mov    a,EchoPhase
18a1: 9c        dec    a
18a2: 9c        dec    a
18a3: 10 07     bpl    L18AC
18a5: ae        pop    a
18a6: c5 8f 02  mov    EchoVolLTgt,a
18a9: 5f b5 18  jmp    L18B5

L18AC:
18ac: ae        pop    a
18ad: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
18b0: c4 f3     mov    DSPDATA,a
18b2: c5 8f 02  mov    EchoVolLTgt,a

L18B5:
18b5: 6f        ret

SetEchoVolR:
18b6: 2d        push   a
18b7: e5 8e 02  mov    a,EchoPhase
18ba: 9c        dec    a
18bb: 9c        dec    a
18bc: 10 07     bpl    L18C5
18be: ae        pop    a
18bf: c5 90 02  mov    EchoVolRTgt,a
18c2: 5f ce 18  jmp    L18CE

L18C5:
18c5: ae        pop    a
18c6: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
18c9: c4 f3     mov    DSPDATA,a
18cb: c5 90 02  mov    EchoVolRTgt,a

L18CE:
18ce: 6f        ret

SetEchoFeedback:
18cf: 2d        push   a
18d0: e5 8e 02  mov    a,EchoPhase
18d3: 9c        dec    a
18d4: 9c        dec    a
18d5: 10 07     bpl    L18DE
18d7: ae        pop    a
18d8: c5 91 02  mov    EchoFeedback,a
18db: 5f e7 18  jmp    L18E7

L18DE:
18de: ae        pop    a
18df: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
18e2: c4 f3     mov    DSPDATA,a
18e4: c5 91 02  mov    EchoFeedback,a

L18E7:
18e7: 6f        ret

; =============================================================================
; SetEchoDelay - A = EDL.  Disables echo writes, zeroes EVOL/EFB, sets
;  EDL and ESA = ~(EDL*8) (buffer at the top of RAM), then lets the main
;  loop wait $4f+$28 ticks before re-enabling echo and ramping EVOL.
;  NOTE: compares with EchoDelayCur ($028c) which is only ever set to $ff,
;  so the echo is re-initialised on every song start that has echo data.
; =============================================================================
SetEchoDelay:
18e8: 65 8c 02  cmp    a,EchoDelayCur
18eb: d0 01     bne    L18EE
18ed: 6f        ret

L18EE:
18ee: c5 8b 02  mov    EchoDelay,a
18f1: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG: ECEN = 1 (echo writes off)
18f4: e4 43     mov    a,FlgShadow
18f6: 08 20     or     a,#$20
18f8: c4 f3     mov    DSPDATA,a
18fa: c4 43     mov    FlgShadow,a
18fc: e8 00     mov    a,#$00
18fe: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
1901: c4 f3     mov    DSPDATA,a
1903: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
1906: c4 f3     mov    DSPDATA,a
1908: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
190b: c4 f3     mov    DSPDATA,a
190d: c5 8e 02  mov    EchoPhase,a
1910: c5 92 02  mov    EchoVolLCur,a
1913: c5 93 02  mov    EchoVolRCur,a
1916: e5 8b 02  mov    a,EchoDelay
1919: 8f 7d f2  mov    DSPADDR,#$7d          ; EDL
191c: c4 f3     mov    DSPDATA,a
191e: 1c        asl    a                     ; ESA page = $ff - EDL*8
191f: 1c        asl    a
1920: 1c        asl    a
1921: 48 ff     eor    a,#$ff
1923: 8f 6d f2  mov    DSPADDR,#$6d          ; ESA
1926: c4 f3     mov    DSPDATA,a
1928: e8 4f     mov    a,#$4f                ; wait $4f ticks
192a: c5 8d 02  mov    EchoTimer,a
192d: 6f        ret

; =============================================================================
; PollCPU - check APUIO0 for a command; called from the idle loop.
;  Handshake: CPU writes command to APUIO0 and a counter to APUIO1;
;  driver echoes APUIO1, runs the command, writes status to APUIO2,
;  clears APUIO0 and waits for the next counter.  A new non-zero command
;  in APUIO0 is executed immediately (commands can be chained); $00 ends.
; =============================================================================
PollCPU:
192e: 2d        push   a

L192F:
192f: e4 f4     mov    a,APUIO0              ; read APUIO0 until stable
1931: 2e f4 fb  cbne   APUIO0,L192F
1934: d0 02     bne    L1938
1936: ae        pop    a                     ; 0 : nothing to do
1937: 6f        ret

L1938:
1938: fa f5 40  mov    (HandshakeCnt),(APUIO1) ; expected next counter = APUIO1 + 1
193b: ab 40     inc    HandshakeCnt
193d: fa f5 f5  mov    (APUIO1),(APUIO1)     ; acknowledge (echo APUIO1)
1940: 4d        push   x
1941: 6d        push   y

L1942:
1942: 5d        mov    x,a
1943: 3f 80 05  call   IoCmdDispatch         ; dispatch command X
1946: fa 45 f6  mov    (APUIO2),(Status)     ; APUIO2 = status
1949: 8f 00 f4  mov    APUIO0,#$00           ; APUIO0 = 0 : done

L194C:
194c: 69 f5 40  cmp    (HandshakeCnt),(APUIO1) ; wait for next counter
194f: d0 fb     bne    L194C
1951: e4 f4     mov    a,APUIO0
1953: fa 40 f5  mov    (APUIO1),(HandshakeCnt) ; acknowledge
1956: ab 40     inc    HandshakeCnt
1958: 68 00     cmp    a,#$00
195a: d0 e6     bne    L1942
195c: ee        pop    y
195d: ce        pop    x
195e: ae        pop    a
195f: 6f        ret

UnusedRet:
1960: 6f        ret

; =============================================================================
; I/O $0C - return to the IPL boot ROM (for uploading a new driver)
;  ORIGINAL BUG: operands are swapped - it writes $6c to whatever DSP
;  register is selected and then selects register $ff.  Intended:
;  "mov $f2,#$6c / mov $f3,#$ff" (FLG = reset + mute + echo off).
; =============================================================================
IoCmd_0C_Reboot:
1961: 8f 80 f1  mov    CONTROL,#$80          ; CONTROL: map IPL ROM, stop timers
1964: 8f 6c f3  mov    DSPDATA,#$6c          ; bug: meant "mov DSPADDR,#$6c" (FLG) ...
1967: 8f ff f2  mov    DSPADDR,#$ff          ; ... and "mov DSPDATA,#$ff"
196a: 5f c0 ff  jmp    IPL_ROM

; =============================================================================
; I/O $02 - write byte stream.  Per step: APUIO0 = data, APUIO2/3 = target
;  address, APUIO1 = counter. Ends when the CPU writes a counter value
;  "ahead" of the expected one.
; =============================================================================
IoCmd_02_WriteBytes:
196d: f8 40     mov    x,HandshakeCnt
196f: 8d 00     mov    y,#$00

L1971:
1971: 3e f5     cmp    x,APUIO1
1973: d0 07     bne    L197C
1975: e4 f4     mov    a,APUIO0
1977: d7 f6     mov    (APUIO2)+y,a          ; [APUIO2/3] = APUIO0   (the input ports are used as a pointer)
1979: d8 f5     mov    APUIO1,x
197b: 3d        inc    x

L197C:
197c: 10 f3     bpl    L1971
197e: 3e f5     cmp    x,APUIO1
1980: 10 ef     bpl    L1971

L1982:
1982: f8 f5     mov    x,APUIO1
1984: d8 f5     mov    APUIO1,x
1986: 3d        inc    x
1987: d8 40     mov    HandshakeCnt,x
1989: 6f        ret

; I/O $08 - clear status bit0 ("sync flag changed"), then read like $06
IoCmd_08_AckRead:
198a: 38 fe 45  and    Status,#$fe
198d: 5f 93 19  jmp    IoCmd_06_ReadBytes

; I/O $16 - refresh $ff08-$ff10 (ReadVoiceStatus), then read like $06
IoCmd_16_VoiceStatus:
1990: 3f 4e 12  call   ReadVoiceStatus

; =============================================================================
; I/O $06 - read byte stream: APUIO2/3 = address, APUIO1 = counter,
;  result in APUIO3.  Same termination rule as $02.
; =============================================================================
IoCmd_06_ReadBytes:
1993: 8d 00     mov    y,#$00
1995: f8 40     mov    x,HandshakeCnt

L1997:
1997: 3e f5     cmp    x,APUIO1
1999: d0 07     bne    L19A2
199b: f7 f6     mov    a,(APUIO2)+y
199d: c4 f7     mov    APUIO3,a
199f: d8 f5     mov    APUIO1,x
19a1: 3d        inc    x

L19A2:
19a2: 10 f3     bpl    L1997
19a4: 3e f5     cmp    x,APUIO1
19a6: 10 ef     bpl    L1997
19a8: 8f 00 f7  mov    APUIO3,#$00
19ab: 2f d5     bra    L1982

; =============================================================================
; I/O $0A - append events to the 64-byte event ring buffer at $0204.
;  Driver reports its write index in APUIO2; CPU answers with the number
;  of bytes (APUIO3, multiple of 4) and then block-writes them (FastReceive)
;  directly to $0204+index.  Sets status bit1.
; =============================================================================
IoCmd_0A_QueueEvents:
19ad: 8f ff f4  mov    APUIO0,#$ff
19b0: e5 02 02  mov    a,QueueWrite
19b3: c4 f6     mov    APUIO2,a
19b5: 3f f8 19  call   WaitWord
19b8: 2d        push   a
19b9: dd        mov    a,y
19ba: 60        clrc
19bb: 85 02 02  adc    a,QueueWrite
19be: 28 3f     and    a,#$3f
19c0: c5 02 02  mov    QueueWrite,a
19c3: ae        pop    a
19c4: 3f cb 19  call   FastReceive
19c7: 18 02 45  or     Status,#$02
19ca: 6f        ret

; =============================================================================
; FastReceive - 2 bytes per handshake.  APUIO2/3 = destination address
;  (also serves as handshake: APUIO2 must change every step), APUIO0/1 =
;  data.  Acknowledged by alternately writing 0/1 to APUIO0.  "dbnz $f7"
;  reads APUIO3 (address hi): the transfer ends when the CPU puts $01 there.
; =============================================================================
FastReceive:
19cb: 8d 01     mov    y,#$01
19cd: cd 00     mov    x,#$00

L19CF:
19cf: 64 f6     cmp    a,APUIO2
19d1: f0 fc     beq    L19CF
19d3: e4 f4     mov    a,APUIO0
19d5: c7 f6     mov    (APUIO2+x),a
19d7: e4 f5     mov    a,APUIO1
19d9: d7 f6     mov    (APUIO2)+y,a
19db: e4 f6     mov    a,APUIO2
19dd: d8 f4     mov    APUIO0,x
19df: 6e f7 02  dbnz   APUIO3,L19E4
19e2: 2f 13     bra    L19F7

L19E4:
19e4: 64 f6     cmp    a,APUIO2
19e6: f0 fc     beq    L19E4
19e8: e4 f4     mov    a,APUIO0
19ea: c7 f6     mov    (APUIO2+x),a
19ec: e4 f5     mov    a,APUIO1
19ee: d7 f6     mov    (APUIO2)+y,a
19f0: e4 f6     mov    a,APUIO2
19f2: cb f4     mov    APUIO0,y
19f4: 6e f7 d8  dbnz   APUIO3,L19CF

L19F7:
19f7: 6f        ret

; WaitWord - wait for the next APUIO1 counter, return YA = APUIO2/3
WaitWord:
19f8: f8 40     mov    x,HandshakeCnt

L19FA:
19fa: 3e f5     cmp    x,APUIO1
19fc: d0 fc     bne    L19FA
19fe: ba f6     movw   ya,APUIO2
1a00: d8 f5     mov    APUIO1,x
1a02: 3d        inc    x
1a03: d8 40     mov    HandshakeCnt,x
1a05: 6f        ret

; =============================================================================
; I/O $0E - receive two words: LoadID ($02, ID / slot offset) and LoadAddr
;  ($04, address of the data block), then continue like $04.
; =============================================================================
IoCmd_0E_LoadParams:
1a06: 3f f8 19  call   WaitWord
1a09: da 02     movw   LoadID,ya
1a0b: 3f f8 19  call   WaitWord
1a0e: da 04     movw   LoadAddr,ya
1a10: 2f 03     bra    L1A15

; I/O $04 - block upload with FastReceive
IoCmd_04_BlockUpload:
1a12: 8f f2 f6  mov    APUIO2,#$f2           ; APUIO2 = $f2 (ready signature)

L1A15:
1a15: 8f ff f4  mov    APUIO0,#$ff
1a18: 3f f8 19  call   WaitWord
1a1b: 3f cb 19  call   FastReceive
1a1e: 6f        ret

; InstallAck - final handshake of an install command.  The install
; commands exit through InstallExit, which drops the dispatcher's return
; address: they always END the current command chain.
InstallAck:
1a1f: 8f f5 f6  mov    APUIO2,#$f5
1a22: 8f 00 f4  mov    APUIO0,#$00

L1A25:
1a25: 69 f5 40  cmp    (HandshakeCnt),(APUIO1)
1a28: d0 fb     bne    L1A25
1a2a: fa 40 f5  mov    (APUIO1),(HandshakeCnt)
1a2d: fa 45 f6  mov    (APUIO2),(Status)
1a30: ab 40     inc    HandshakeCnt
1a32: 6f        ret

; =============================================================================
; I/O $10 - install a sample block at LoadAddr into the DIR ($2300)
;  Block: +0 word size, +2 byte n = number of samples, +3 byte first
;  SRCN (+LoadID), +4 n*{word start, word loop} offsets relative to +3.
;  SELF-MODIFYING: the operand of the two "mov $2324+x,a" below is
;  patched at $1a5c-$1a69; $2324 is just the value left in the snapshot.
; =============================================================================
IoCmd_10_InstallSamples:
1a33: 3f 1f 1a  call   InstallAck
1a36: 3f 3f 1b  call   EvictOverlappingBanks
1a39: 3a 04     incw   LoadAddr
1a3b: 3a 04     incw   LoadAddr
1a3d: 8d 00     mov    y,#$00
1a3f: fa 04 23  mov    ($23),(LoadAddr)
1a42: fa 05 24  mov    ($24),(LoadAddr+1)
1a45: f7 04     mov    a,(LoadAddr)+y        ; n*2 words
1a47: 1c        asl    a
1a48: c4 21     mov    $21,a
1a4a: 3a 04     incw   LoadAddr
1a4c: f7 04     mov    a,(LoadAddr)+y        ; first SRCN
1a4e: 60        clrc
1a4f: 84 02     adc    a,LoadID
1a51: 8f 00 22  mov    $22,#$00
1a54: 1c        asl    a                     ; *4
1a55: 2b 22     rol    $22
1a57: 1c        asl    a
1a58: 2b 22     rol    $22
1a5a: 88 00     adc    a,#$00
1a5c: c5 76 1a  mov    SmcStoreA+1,a         ; patch operands of $1a75 and $1a7e (lo)
1a5f: c5 7f 1a  mov    SmcStoreB+1,a
1a62: e4 22     mov    a,$22
1a64: 88 23     adc    a,#$23
1a66: c5 77 1a  mov    SmcStoreA+2,a         ; patch operands (hi)
1a69: c5 80 1a  mov    SmcStoreB+2,a
1a6c: cd 00     mov    x,#$00
1a6e: 3a 04     incw   LoadAddr

L1A70:
1a70: f7 04     mov    a,(LoadAddr)+y        ; offset lo + base + 1 (SETC)
1a72: 80        setc
1a73: 84 23     adc    a,$23

SmcStoreA:
1a75: d5 24 23  mov    $2324+x,a             ; operand patched at run time
1a78: 3d        inc    x
1a79: fc        inc    y
1a7a: f7 04     mov    a,(LoadAddr)+y
1a7c: 84 24     adc    a,$24

SmcStoreB:
1a7e: d5 24 23  mov    $2324+x,a             ; operand patched at run time
1a81: fc        inc    y
1a82: 3d        inc    x
1a83: 8b 21     dec    $21
1a85: d0 e9     bne    L1A70

InstallExit:
1a87: ae        pop    a                     ; drop return address into PollCPU ...
1a88: ae        pop    a
1a89: ee        pop    y                     ; ... restore PollCPU's registers and return to its caller
1a8a: ce        pop    x
1a8b: ae        pop    a
1a8c: 6f        ret

; =============================================================================
; I/O $12 - register the sound bank at LoadAddr in a free BankStart slot
;  (max 8) and add LoadID to every entry ID in it.
; =============================================================================
IoCmd_12_InstallBank:
1a8d: 3f 1f 1a  call   InstallAck
1a90: 3f 3f 1b  call   EvictOverlappingBanks
1a93: 3f 9b 1b  call   CalcBlockEnd
1a96: cd 0f     mov    x,#$0f

L1A98:
1a98: f5 97 02  mov    a,BankStart+x
1a9b: f0 04     beq    L1AA1
1a9d: 1d        dec    x
1a9e: 1d        dec    x
1a9f: 10 f7     bpl    L1A98

L1AA1:
1aa1: d0 1b     bne    L1ABE
1aa3: 3a 04     incw   LoadAddr
1aa5: 3a 04     incw   LoadAddr
1aa7: e4 05     mov    a,LoadAddr+1
1aa9: d5 97 02  mov    BankStart+x,a
1aac: e4 04     mov    a,LoadAddr
1aae: d5 96 02  mov    BankStart-1+x,a
1ab1: e4 01     mov    a,BlockEnd+1
1ab3: d5 a7 02  mov    BankEnd+x,a
1ab6: e4 00     mov    a,BlockEnd
1ab8: d5 a6 02  mov    BankEnd-1+x,a
1abb: 3f c1 1a  call   RelocateBankIDs

L1ABE:
1abe: 5f 87 1a  jmp    InstallExit

RelocateBankIDs:
1ac1: 8d 02     mov    y,#$02
1ac3: f7 04     mov    a,(LoadAddr)+y
1ac5: 68 ff     cmp    a,#$ff
1ac7: f0 14     beq    L1ADD
1ac9: 60        clrc
1aca: 84 02     adc    a,LoadID
1acc: d7 04     mov    (LoadAddr)+y,a
1ace: dc        dec    y
1acf: f7 04     mov    a,(LoadAddr)+y
1ad1: 2d        push   a
1ad2: dc        dec    y
1ad3: f7 04     mov    a,(LoadAddr)+y
1ad5: ee        pop    y
1ad6: 7a 04     addw   ya,LoadAddr
1ad8: da 04     movw   LoadAddr,ya
1ada: 5f c1 1a  jmp    RelocateBankIDs

L1ADD:
1add: 6f        ret

; =============================================================================
; I/O $14 - install instrument records from the block at LoadAddr
;  Block: +0 word size, +2 word offset to records.  Record = 11 bytes:
;  instrument number (+LoadID, &$7f; $ff = end), then the 10 table bytes
;  ($1e00,$1e80 ... $2280).  Key-split instruments ($1e00 >= $fd) get
;  their record pointer relocated by the block address.
; =============================================================================
IoCmd_14_InstallInstruments:
1ade: 3f 1f 1a  call   InstallAck
1ae1: 3f 3f 1b  call   EvictOverlappingBanks
1ae4: 8d 02     mov    y,#$02
1ae6: f7 04     mov    a,(LoadAddr)+y
1ae8: 60        clrc
1ae9: 84 04     adc    a,LoadAddr
1aeb: c4 21     mov    $21,a
1aed: fc        inc    y
1aee: f7 04     mov    a,(LoadAddr)+y
1af0: 84 05     adc    a,LoadAddr+1
1af2: c4 22     mov    $22,a
1af4: fa 04 00  mov    (BlockEnd),(LoadAddr)
1af7: fa 05 01  mov    (BlockEnd+1),(LoadAddr+1)
1afa: 8d 00     mov    y,#$00

L1AFC:
1afc: f7 21     mov    a,($21)+y
1afe: 3a 21     incw   $21
1b00: 68 ff     cmp    a,#$ff
1b02: b0 38     bcs    L1B3C
1b04: 84 02     adc    a,LoadID
1b06: 28 7f     and    a,#$7f
1b08: cd 0a     mov    x,#$0a
1b0a: 8f 1e 24  mov    $24,#$1e
1b0d: c4 23     mov    $23,a

L1B0F:
1b0f: f7 21     mov    a,($21)+y
1b11: d7 23     mov    ($23)+y,a
1b13: 60        clrc
1b14: 98 80 23  adc    $23,#$80
1b17: 98 00 24  adc    $24,#$00
1b1a: 3a 21     incw   $21
1b1c: 1d        dec    x
1b1d: d0 f0     bne    L1B0F
1b1f: f8 23     mov    x,$23
1b21: f5 00 1e  mov    a,InstSRCN+x
1b24: 68 fd     cmp    a,#$fd
1b26: 90 11     bcc    L1B39
1b28: 60        clrc
1b29: f5 80 1e  mov    a,InstADSR1+x
1b2c: 84 00     adc    a,BlockEnd
1b2e: d5 80 1e  mov    InstADSR1+x,a
1b31: f5 00 1f  mov    a,InstADSR2+x
1b34: 84 01     adc    a,BlockEnd+1
1b36: d5 00 1f  mov    InstADSR2+x,a

L1B39:
1b39: 5f fc 1a  jmp    L1AFC

L1B3C:
1b3c: 5f 87 1a  jmp    InstallExit

; EvictOverlappingBanks - drop every registered bank overlapping the new
; block (LoadAddr .. LoadAddr+size-1) and compact the list.
EvictOverlappingBanks:
1b3f: 3f 9b 1b  call   CalcBlockEnd
1b42: cd 0e     mov    x,#$0e

L1B44:
1b44: f5 98 02  mov    a,BankStart+1+x
1b47: fd        mov    y,a
1b48: f5 97 02  mov    a,BankStart+x
1b4b: 5a 00     cmpw   ya,BlockEnd
1b4d: b0 1a     bcs    L1B69
1b4f: 5a 04     cmpw   ya,LoadAddr
1b51: 90 0b     bcc    L1B5E

L1B53:
1b53: e8 00     mov    a,#$00
1b55: d5 98 02  mov    BankStart+1+x,a
1b58: 3f 6e 1b  call   CompactBankList
1b5b: 5f 69 1b  jmp    L1B69

L1B5E:
1b5e: f5 a8 02  mov    a,BankEnd+1+x
1b61: fd        mov    y,a
1b62: f5 a7 02  mov    a,BankEnd+x
1b65: 5a 04     cmpw   ya,LoadAddr
1b67: b0 ea     bcs    L1B53

L1B69:
1b69: 1d        dec    x
1b6a: 1d        dec    x
1b6b: 10 d7     bpl    L1B44
1b6d: 6f        ret

CompactBankList:
1b6e: 4d        push   x
1b6f: 7d        mov    a,x
1b70: fd        mov    y,a

L1B71:
1b71: dc        dec    y
1b72: dc        dec    y
1b73: 10 02     bpl    L1B77
1b75: ce        pop    x
1b76: 6f        ret

L1B77:
1b77: f6 98 02  mov    a,BankStart+1+y
1b7a: f0 1c     beq    L1B98
1b7c: d5 98 02  mov    BankStart+1+x,a
1b7f: f6 97 02  mov    a,BankStart+y
1b82: d5 97 02  mov    BankStart+x,a
1b85: f6 a7 02  mov    a,BankEnd+y
1b88: d5 a7 02  mov    BankEnd+x,a
1b8b: f6 a8 02  mov    a,BankEnd+1+y
1b8e: d5 a8 02  mov    BankEnd+1+x,a
1b91: e8 00     mov    a,#$00
1b93: d6 98 02  mov    BankStart+1+y,a
1b96: 1d        dec    x
1b97: 1d        dec    x

L1B98:
1b98: 5f 71 1b  jmp    L1B71

; CalcBlockEnd - $00/$01 = LoadAddr + size - 1
CalcBlockEnd:
1b9b: 8d 00     mov    y,#$00
1b9d: f7 04     mov    a,(LoadAddr)+y
1b9f: fc        inc    y
1ba0: 60        clrc
1ba1: 84 04     adc    a,LoadAddr
1ba3: c4 00     mov    BlockEnd,a
1ba5: f7 04     mov    a,(LoadAddr)+y
1ba7: 84 05     adc    a,LoadAddr+1
1ba9: c4 01     mov    BlockEnd+1,a
1bab: 1a 00     decw   BlockEnd
1bad: 6f        ret

; =============================================================================
; ProcessEventQueue - execute all 4-byte events between QueueRead ($eb)
;  and QueueWrite ($0202).  Event: type, p0 ($08), p1 ($0a), p2 ($0b)
;    0 MIDI channel message   1 system   2 start sound
;    3 no-op                  4 restart sound (stop handle p2 first)
;  Type 2/4 consume a second 4-byte entry: pan, volume, tempo offset, -
; =============================================================================
ProcessEventQueue:
1bae: eb eb     mov    y,QueueRead
1bb0: 5e 02 02  cmp    y,QueueWrite
1bb3: f0 21     beq    .done
1bb5: f6 05 02  mov    a,EventQueue+1+y
1bb8: c4 08     mov    $08,a
1bba: f6 06 02  mov    a,EventQueue+2+y
1bbd: c4 0a     mov    $0a,a
1bbf: f6 07 02  mov    a,EventQueue+3+y
1bc2: c4 0b     mov    $0b,a
1bc4: 60        clrc
1bc5: 98 04 eb  adc    QueueRead,#$04
1bc8: 38 3f eb  and    QueueRead,#$3f
1bcb: f6 04 02  mov    a,EventQueue+y
1bce: 1c        asl    a
1bcf: 5d        mov    x,a
1bd0: 3f 99 05  call   QueueEventDispatch
1bd3: 5f ae 1b  jmp    ProcessEventQueue
.done:
1bd6: 6f        ret

QEv_RestartSound:
1bd7: e4 0a     mov    a,$0a
1bd9: 2d        push   a
1bda: fa 0b 0a  mov    ($0a),($0b)
1bdd: 3f 18 17  call   StopSound
1be0: ae        pop    a
1be1: c4 0a     mov    $0a,a

QEv_StartSound:
1be3: eb eb     mov    y,QueueRead
1be5: f6 05 02  mov    a,EventQueue+1+y      ; StartPan   (bit7 = use header pan)
1be8: c5 78 02  mov    StartPan,a
1beb: f6 06 02  mov    a,EventQueue+2+y      ; StartVolume
1bee: c5 79 02  mov    StartVolume,a
1bf1: f6 07 02  mov    a,EventQueue+3+y      ; StartTempoOfs
1bf4: c5 7a 02  mov    StartTempoOfs,a
1bf7: 60        clrc
1bf8: 98 04 eb  adc    QueueRead,#$04
1bfb: 38 3f eb  and    QueueRead,#$3f
1bfe: 5f 3d 11  jmp    StartSound

QEv_Nop:
1c01: 6f        ret

; SignalSyncFlag - status bit0 = 1 (a sync flag changed) -> APUIO2
SignalSyncFlag:
1c02: 18 01 45  or     Status,#$01
1c05: fa 45 f6  mov    (APUIO2),(Status)
1c08: 6f        ret

StopAllTracks:
1c09: 3f c1 13  call   KeyOffAllVoices
1c0c: 8d 15     mov    y,#$15

L1C0E:
1c0e: e8 00     mov    a,#$00
1c10: d6 b7 02  mov    TrkStatus+y,a
1c13: dc        dec    y
1c14: 10 f8     bpl    L1C0E
1c16: 6f        ret

; MidiReset - make all 22 tracks idle MIDI channels (ID = track index,
; sequencer disabled, vol/vel $7f, pan $40)
MidiReset:
1c17: 8d 15     mov    y,#$15

L1C19:
1c19: e8 80     mov    a,#$80
1c1b: d6 b7 02  mov    TrkStatus+y,a
1c1e: e8 40     mov    a,#$40
1c20: d6 9b 04  mov    TrkPan+y,a
1c23: e8 7f     mov    a,#$7f
1c25: d6 94 ff  mov    TrkChanVol+y,a
1c28: d6 59 04  mov    TrkVolume+y,a
1c2b: d6 43 04  mov    TrkVelocity+y,a
1c2e: bc        inc    a
1c2f: d6 4b 00  mov    TrkTimerHi+y,a
1c32: dd        mov    a,y
1c33: d6 e3 02  mov    TrkSoundID+y,a
1c36: e8 00     mov    a,#$00
1c38: d6 d5 03  mov    TrkNumber+y,a
1c3b: d6 cd 02  mov    TrkPriority+y,a
1c3e: d6 0f 03  mov    TrkFlags+y,a
1c41: d6 6f 04  mov    TrkTranspose+y,a
1c44: d6 85 04  mov    TrkKeyOffset+y,a
1c47: d6 f9 02  mov    TrkProgram+y,a
1c4a: bc        inc    a
1c4b: d6 2d 04  mov    TrkTempoHi+y,a
1c4e: dc        dec    y
1c4f: 10 c8     bpl    L1C19
1c51: 6f        ret

; =============================================================================
; QEv_Midi - queue event type 0 : MIDI channel message
;  p0 = status (channel n = track n), p1/p2 = data bytes
;  8n note off   9n note on (vel 0 = off)   An ignored   Bn controller
;  Cn program    Dn ignored   En pitch bend (p1 = semitones, p2 = fraction)
;  F0: channel $c -> all voices off; channel $f -> MidiReset
;  Ignored for tracks with the mute bit (TrkStatus bit0) set.
; =============================================================================
QEv_Midi:
1c52: e4 08     mov    a,$08
1c54: 28 0f     and    a,#$0f
1c56: c4 1c     mov    CurTrack,a
1c58: 5d        mov    x,a
1c59: f5 b7 02  mov    a,TrkStatus+x
1c5c: 28 01     and    a,#$01
1c5e: f0 01     beq    L1C61
1c60: 6f        ret

L1C61:
1c61: e4 08     mov    a,$08
1c63: 28 f0     and    a,#$f0
1c65: 68 80     cmp    a,#$80
1c67: d0 04     bne    L1C6D

L1C69:
1c69: 3f ff 1c  call   MidiNoteOff
1c6c: 6f        ret

L1C6D:
1c6d: 68 90     cmp    a,#$90
1c6f: d0 09     bne    L1C7A
1c71: 78 00 0b  cmp    $0b,#$00
1c74: f0 f3     beq    L1C69
1c76: 3f cd 1c  call   MidiNoteOn
1c79: 6f        ret

L1C7A:
1c7a: 68 a0     cmp    a,#$a0
1c7c: d0 01     bne    L1C7F
1c7e: 6f        ret

L1C7F:
1c7f: 68 b0     cmp    a,#$b0
1c81: d0 04     bne    L1C87
1c83: 3f 57 1d  call   MidiControl
1c86: 6f        ret

L1C87:
1c87: 68 c0     cmp    a,#$c0
1c89: d0 06     bne    L1C91
1c8b: e4 0a     mov    a,$0a
1c8d: d5 f9 02  mov    TrkProgram+x,a
1c90: 6f        ret

L1C91:
1c91: 68 d0     cmp    a,#$d0
1c93: d0 01     bne    L1C96
1c95: 6f        ret

L1C96:
1c96: 68 e0     cmp    a,#$e0
1c98: d0 1a     bne    L1CB4
1c9a: e4 0a     mov    a,$0a
1c9c: d5 eb 03  mov    TrkBendHi+x,a
1c9f: c4 13     mov    $13,a
1ca1: e4 0b     mov    a,$0b
1ca3: d5 01 04  mov    TrkBendLo+x,a
1ca6: c4 12     mov    $12,a
1ca8: d8 0a     mov    $0a,x
1caa: 8f 0a 0e  mov    $0e,#$0a
1cad: 8f ff 0f  mov    $0f,#$ff
1cb0: 3f 5f 14  call   ApplyParamToVoices
1cb3: 6f        ret

L1CB4:
1cb4: 68 f0     cmp    a,#$f0
1cb6: d0 14     bne    L1CCC
1cb8: 78 0c 1c  cmp    CurTrack,#$0c
1cbb: d0 04     bne    L1CC1
1cbd: 3f c1 13  call   KeyOffAllVoices
1cc0: 6f        ret

L1CC1:
1cc1: 78 0f 1c  cmp    CurTrack,#$0f
1cc4: d0 06     bne    L1CCC
1cc6: 3f c1 13  call   KeyOffAllVoices
1cc9: 5f 17 1c  jmp    MidiReset

L1CCC:
1ccc: 6f        ret

MidiNoteOn:
1ccd: e8 00     mov    a,#$00
1ccf: c4 33     mov    CurFlags,a
1cd1: e4 0b     mov    a,$0b
1cd3: 13 33 02  bbc0   CurFlags,L1CD8
1cd6: e8 7f     mov    a,#$7f

L1CD8:
1cd8: c4 3a     mov    Velocity,a
1cda: e4 0a     mov    a,$0a
1cdc: 2d        push   a
1cdd: 3f 38 0b  call   AllocVoice
1ce0: 90 02     bcc    L1CE4
1ce2: ae        pop    a
1ce3: 6f        ret

L1CE4:
1ce4: d8 1d     mov    CurVoice,x
1ce6: e4 3a     mov    a,Velocity
1ce8: d5 1f 05  mov    VVelocity+x,a
1ceb: ae        pop    a
1cec: d5 17 05  mov    VNote+x,a
1cef: e4 1c     mov    a,CurTrack
1cf1: d5 27 05  mov    VTrack+x,a
1cf4: e8 01     mov    a,#$01
1cf6: d4 db     mov    VoiceState+x,a
1cf8: e8 7f     mov    a,#$7f
1cfa: d4 ab     mov    VGateHi+x,a
1cfc: d4 b3     mov    VGateMid+x,a
1cfe: 6f        ret

; MidiNoteOff - release the oldest voice of this track playing note p1
MidiNoteOff:
1cff: e8 00     mov    a,#$00
1d01: c4 0c     mov    $0c,a
1d03: c4 0d     mov    $0d,a
1d05: c4 0e     mov    $0e,a
1d07: c4 0f     mov    $0f,a
1d09: cd 07     mov    x,#$07

L1D0B:
1d0b: f4 db     mov    a,VoiceState+x
1d0d: 28 83     and    a,#$83
1d0f: f0 29     beq    L1D3A
1d11: 28 03     and    a,#$03
1d13: d0 05     bne    L1D1A
1d15: f5 ff 04  mov    a,VRelFlags+x
1d18: 30 20     bmi    L1D3A

L1D1A:
1d1a: f4 ab     mov    a,VGateHi+x
1d1c: 30 1c     bmi    L1D3A
1d1e: f5 17 05  mov    a,VNote+x
1d21: 64 0a     cmp    a,$0a
1d23: d0 15     bne    L1D3A
1d25: f5 27 05  mov    a,VTrack+x
1d28: 64 1c     cmp    a,CurTrack
1d2a: d0 0e     bne    L1D3A
1d2c: f4 d3     mov    a,VAgeLo+x
1d2e: fb cb     mov    y,VAgeHi+x
1d30: 5a 0e     cmpw   ya,$0e
1d32: 90 06     bcc    L1D3A
1d34: ab 0c     inc    $0c
1d36: da 0e     movw   $0e,ya
1d38: d8 0d     mov    $0d,x

L1D3A:
1d3a: 1d        dec    x
1d3b: 10 ce     bpl    L1D0B
1d3d: e4 0c     mov    a,$0c
1d3f: d0 01     bne    L1D42
1d41: 6f        ret

L1D42:
1d42: f8 0d     mov    x,$0d
1d44: f4 db     mov    a,VoiceState+x
1d46: 28 03     and    a,#$03
1d48: f0 04     beq    L1D4E
1d4a: e8 00     mov    a,#$00
1d4c: d4 db     mov    VoiceState+x,a

L1D4E:
1d4e: e8 00     mov    a,#$00
1d50: d4 ab     mov    VGateHi+x,a
1d52: d4 b3     mov    VGateMid+x,a
1d54: d4 bb     mov    VGateLo+x,a
1d56: 6f        ret

; MidiControl - CC 7 = volume, CC 10 = pan (others ignored)
MidiControl:
1d57: 8f ff 0f  mov    $0f,#$ff
1d5a: f8 1c     mov    x,CurTrack
1d5c: e4 0a     mov    a,$0a
1d5e: 68 07     cmp    a,#$07
1d60: d0 09     bne    L1D6B
1d62: d8 0a     mov    $0a,x
1d64: 8f 00 0e  mov    $0e,#$00
1d67: 3f 1a 14  call   ApplyParamToSound
1d6a: 6f        ret

L1D6B:
1d6b: 68 0a     cmp    a,#$0a
1d6d: d0 09     bne    L1D78
1d6f: d8 0a     mov    $0a,x
1d71: 8f 02 0e  mov    $0e,#$02
1d74: 3f 1a 14  call   ApplyParamToSound
1d77: 6f        ret

L1D78:
1d78: 6f        ret

; end of driver image ($1d78)
