;==============================================================================
; SLICK sound driver - EARLIER VERSION (Bitmasters, 1993)
; as used in Aero the Acro-Bat, taken from "01 - Circus 1 (Main Theme).spc"
; (SPC PC = $087c, inside the track loop).  Driver image $0700-$1e01, entry
; point Reset ($0700).  No copyright / version string is present.
;
; Labels follow the ones used for SLICK/Audio v1.01 (Earthworm Jim) where a
; routine has a counterpart - see SLICK_Version_Comparison.md for the
; differences, and SLICK_Engine_Notes.md for the v1.01 description.
;
; Syntax identical to SLICK_EarthwormJim_labeled.s (SPCdas conventions).
;
; Memory outside the image that belongs to the driver:
;   $0500-$06cf  instrument table, 58 x 8 bytes (uploaded, not cleared)
;   $06d0-$06ff  global drum map, 16 x {instrument, key, flags}
;   $1f00-$1fff  sample directory (DIR = $1f)
;   $2000-       sound banks / samples
;
; Every byte of $0700-$1e01 is accounted for: a recursive trace from Reset
; reaches all code except the parts marked "unreachable" and the complete
; MIDI section ($1cc3-$1e01), which no event type calls in this version.
; Data inside the image: TrackPtrTable ($0d9a), voice tables ($0f07),
; DrumRangeOffsets ($1153), three global pitch tables ($1314-$1571),
; EchoDefaults ($1968), BankTable ($1cab).  Linear disassemblers (SPCdas)
; decode all of these as code.
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
BlockEnd         = $0000   ; [2] scratch / FIR pointer for SetEchoParams
StereoMode       = $0014   ; [1] 0 mono, else stereo (no surround mode yet)
DirPtr           = $0015   ; [2] pointer to DIR ($1f00); $16 is also written to DSP DIR
TicksElapsed     = $001f   ; [1] timer-0 ticks since last frame
SeqPtr           = $0020   ; [2] sequence pointer of current track
CurTrack         = $0022   ; [1] current track (0-21)
CurTempo         = $0023   ; [1] tempo of current track / sound being started
VState           = $0024   ; [1] copy of VoiceState[x]
HdrFlags         = $0025   ; [1] sound flags of sound being started
HdrTrkFlags      = $0026   ; [1] track flags of track being started
CurFlags         = $0027   ; [1] copy of TrkFlags / VFlags
CurVoice         = $0028   ; [1] current voice (0-7)
VoiceBit         = $0029   ; [1] bit of current voice
NonShadow        = $002a   ; [1] NON shadow
EonShadow        = $002b   ; [1] EON shadow
PmonShadow       = $002c   ; [1] PMON shadow (never set, written as 0)
TrkTimerHi       = $002d   ; [22] track timer byte 3
TrkTimerMid      = $0043   ; [22] track timer byte 2
TrkTimerLo       = $0059   ; [22] track timer byte 1 (deltas added here)
TrkTimerFrac     = $006f   ; [22] track timer byte 0
VSoundID         = $0085   ; [8] sound ID of voice
VGateHi          = $008d   ; [8] gate (8 ms ticks) hi, bit7 = infinite
VGateMid         = $0095   ; [8] gate mid
VGateLo          = $009d   ; [8] gate lo
VAgeHi           = $00a5   ; [8] voice age hi
VAgeLo           = $00ad   ; [8] voice age lo
VoiceState       = $00b5   ; [8] bit7 playing, bit5 tremolo, bit4 ignore ENDX, bit3 fade, bits0-1 key-on countdown
VTremDir         = $00bd   ; [8] tremolo/auto-pan direction (bit0)
NoteNum          = $00c5   ; [1] note being started
Velocity         = $00c6   ; [1] velocity being started
VolTmpL          = $00c7   ; [1]
VolTmpR          = $00c8   ; [1]
InstFlagsTmp     = $00ca   ; [1] InstFlags of instrument being started
PriorityTmp      = $00cb   ; [1]
StreamPrev       = $00cc   ; [2] last BRR block given end flags by system $08 ($cd bit7 = none)
HandshakeCnt     = $00ce   ; [1] expected APUIO1 counter
IoWord1          = $00d0   ; [2] I/O word 1: data address
IoWord2          = $00d2   ; [2] I/O word 2: install type (lo)
IoWord3          = $00d4   ; [2] I/O word 3: params (lo = p1, hi = command/p0)
EndxLatch        = $00d7   ; [1] ENDX, shifted per voice
FlgShadow        = $00d8   ; [1] FLG shadow
HdrTranspose     = $00d9   ; [1] transpose of track being started
CurVoiceDsp      = $00da   ; [1] DSP base of voice in VoiceLoop
NotifyStatus     = $00db   ; [1] APUIO3: bit3 = notifications pending, bits0-2 = count
UnusedMaskA      = $00de   ; [1] cleared per voice in AllocVoice, otherwise unused
UnusedMaskB      = $00df   ; [1] cleared per voice in AllocVoice, otherwise unused
FrameCounter     = $00e0   ; [1]
SeqDisable       = $00e1   ; [1] non-zero: sequencer stopped (set only by dead MidiReset)
FirReg           = $00e2   ; [1]
VEnvxStatus      = $0200   ; [8] I/O bit6: |ENVX| per voice
VActiveMask      = $0208   ; [1] I/O bit6: playing-voice mask
VTremCount       = $020a   ; [8] tremolo step countdown
VTremParam       = $0212   ; [8] tremolo: hi nibble steps left, lo nibble step size
TrkStatus        = $021a   ; [22] bit7 active, bit4 chain, bit3 fade, bit2/1 stop requested, bit0 muted
VPriority        = $0230   ; [8]
VPrevEnvx        = $0238   ; [8]
VFlags           = $0240   ; [8] track flags bits0-3/7 + release bits: 4 one-shot, 5 GAIN $b7, 6 GAIN $b0
VTrkNumber       = $0248   ; [8]
VNote            = $0250   ; [8]
VVelocity        = $0258   ; [8]
VTrack           = $0260   ; [8] owning track
TrkPriority      = $0268   ; [22]
TrkTranspose     = $027e   ; [22]
TrkSoundID       = $02aa   ; [22] handle; >= $e0 = music
TrkProgram       = $02c0   ; [22] instrument (0 = none)
TrkFlags         = $02d6   ; [22]
TrkPtrLo         = $02ec   ; [22]
TrkPtrHi         = $0302   ; [22]
TrkListHi        = $0318   ; [22]
TrkListLo        = $032e   ; [22]
TrkNumber        = $0344   ; [22]
TrkBendHi        = $035a   ; [22]
TrkBendLo        = $0370   ; [22]
TrkTempo         = $0386   ; [22] tempo byte incl. offset (no +40, no 8.8)
TrkVelocity      = $039c   ; [22]
TrkPatBaseHi     = $03b2   ; [22]
StartPan         = $03c8   ; [1] start param: pan (bit7 = header)
StartVolume      = $03c9   ; [1] start param: volume, bit7 = notify when finished
StartTempoOfs    = $03ca   ; [1] start param: tempo offset
ChainList        = $03cb   ; [8] 4 x {ID, next ID} - used by ChainNext
VVolume          = $03d3   ; [8]
VKeyOffset       = $03db   ; [8]
VPan             = $03e3   ; [8]
VBendLo          = $03eb   ; [8]
VBendHi          = $03f3   ; [8]
VVolL            = $03fb   ; [8]
VVolR            = $0403   ; [8]
VTremL           = $040b   ; [8] tremolo multiplier L
VTremR           = $0413   ; [8] tremolo multiplier R
EchoDelay        = $041e   ; [1]
EchoDelayCur     = $041f   ; [1] always $ff
EchoTimer        = $0420   ; [1]
EchoPhase        = $0421   ; [1]
EchoVolLTgt      = $0422   ; [1]
EchoVolRTgt      = $0423   ; [1]
EchoFeedback     = $0424   ; [1]
EchoVolLCur      = $0425   ; [1]
EchoVolRCur      = $0426   ; [1]
PatBaseTmp       = $0427   ; [2]
TrkNumTmp        = $0449   ; [1]
QueueWrite       = $0490   ; [1] event ring write index (written by the CPU!)
QueueRead        = $0491   ; [1]
EventQueue       = $0492   ; [64] 16 x 4-byte events
NotifyCount      = $04e8   ; [1]
NotifyBuf        = $04ea   ; [16] 8 x {type, ID}
InstTable        = $0500   ; [464] 58 instruments x 8 bytes
DrumMap          = $06d0   ; [48] 16 zones x {instrument, key, flags}
SampleDir        = $1f00   ; [256] DIR
VVelScale        = $ff08   ; [8]
VVelocityAdj     = $ff10   ; [8]
VBaseNote        = $ff18   ; [8]
VInstFlags2      = $ff20   ; [8]
VFineTune        = $ff28   ; [8]
TrkLoopPtrHi     = $ff30   ; [22]
TrkLoopPtrLo     = $ff46   ; [22]
TrkVolume        = $ff5c   ; [22] bit7 = notify CPU when sound ends
TrkKeyOffset     = $ff72   ; [22]
TrkTempoOfs      = $ff88   ; [22]
TrkPan           = $ff9e   ; [22]
TrkLoopListHi    = $ffb4   ; [22]
TrkLoopListLo    = $ffca   ; [22]
TrkPatBaseLo     = $ffe0   ; [22] reaches $fff5: needs the IPL ROM hidden (CONTROL=$03)

; =============================================================================
; Reset - driver entry point
; =============================================================================
Reset:
0700: 20        clrp
0701: e8 00     mov    a,#$00                ; clear the output ports
0703: c4 f4     mov    APUIO0,a
0705: c4 f5     mov    APUIO1,a
0707: c4 f6     mov    APUIO2,a
0709: c4 f7     mov    APUIO3,a
070b: cd ff     mov    x,#$ff                ; stack = $01ff
070d: bd        mov    sp,x
070e: 5d        mov    x,a                   ; clear $00-$ef

L070F:
070f: af        mov    (x)+,a
0710: c8 f0     cmp    x,#$f0
0712: d0 fb     bne    L070F
0714: fd        mov    y,a                   ; clear $0100-$04ff  (NOTE: the instrument table at $0500 is NOT cleared)

L0715:
0715: d6 00 01  mov    $0100+y,a
0718: d6 00 02  mov    VEnvxStatus+y,a
071b: d6 00 03  mov    TrkPtrLo+20+y,a
071e: d6 00 04  mov    VVolL+5+y,a
0721: fe f2     dbnz   y,L0715
0723: e8 01     mov    a,#$01                ; StereoMode = 1, HandshakeCnt = 1
0725: c4 14     mov    StereoMode,a
0727: c4 ce     mov    HandshakeCnt,a
0729: 8f 1f 16  mov    DirPtr+1,#$1f         ; DirPtr = $1f00 (DIR page $1f)
072c: 8f 00 15  mov    DirPtr,#$00
072f: 3f d5 09  call   InitDSP               ; DSP / timer init
0732: e8 ff     mov    a,#$ff                ; ChainList = empty
0734: c5 cb 03  mov    ChainList,a
0737: c5 cd 03  mov    ChainList+2,a
073a: c5 cf 03  mov    ChainList+4,a
073d: c5 d1 03  mov    ChainList+6,a
0740: 8f 00 1f  mov    TicksElapsed,#$00

; =============================================================================
; MainLoop - one iteration per 8 ms tick.  APUIO2 = $01 while idle/waiting,
; $ff while a CPU command is being handled, $00 while the frame is processed.
; =============================================================================
MainLoop:
0743: 3f fb 1b  call   ProcessEventQueue     ; run queued events
0746: 8f 01 f6  mov    APUIO2,#$01           ; APUIO2 = $01 : ready
.wait:
0749: e4 fd     mov    a,T0OUT               ; timer tick?
074b: d0 18     bne    L0765
074d: e4 f4     mov    a,APUIO0              ; CPU command in APUIO0 ?
074f: f0 f8     beq    .wait
0751: e4 f4     mov    a,APUIO0              ; (read twice to be sure)
0753: f0 f4     beq    .wait
0755: 8f ff f6  mov    APUIO2,#$ff           ; APUIO2 = $ff : busy
0758: 3f 3a 1a  call   IoCommand             ; handle the CPU command
075b: e4 fd     mov    a,T0OUT
075d: d0 06     bne    L0765
075f: 8f 01 f6  mov    APUIO2,#$01
0762: 5f 49 07  jmp    .wait

L0765:
0765: 8f 00 f6  mov    APUIO2,#$00           ; APUIO2 = $00 : processing frame
0768: c4 1f     mov    TicksElapsed,a        ; TicksElapsed
076a: ab e0     inc    FrameCounter
076c: 3f a6 16  call   ProcessFades          ; volume fades

; --- echo start-up state machine (same as in v1.01) ----------------------
076f: e5 20 04  mov    a,EchoTimer
0772: 10 03     bpl    L0777
0774: 5f fe 07  jmp    .voices

L0777:
0777: 8c 20 04  dec    EchoTimer
077a: 30 03     bmi    L077F
077c: 5f fe 07  jmp    .voices

L077F:
077f: e5 21 04  mov    a,EchoPhase
0782: d0 12     bne    L0796
0784: bc        inc    a
0785: c5 21 04  mov    EchoPhase,a
0788: e8 28     mov    a,#$28
078a: c5 20 04  mov    EchoTimer,a
078d: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG = shadow (echo writes on)
0790: fa d8 f3  mov    (DSPDATA),(FlgShadow)
0793: 5f fe 07  jmp    .voices

L0796:
0796: 68 01     cmp    a,#$01
0798: d0 14     bne    L07AE
079a: bc        inc    a
079b: c5 21 04  mov    EchoPhase,a
079e: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
07a1: e5 24 04  mov    a,EchoFeedback
07a4: c4 f3     mov    DSPDATA,a
07a6: e8 00     mov    a,#$00
07a8: c5 20 04  mov    EchoTimer,a
07ab: 5f fe 07  jmp    .voices

L07AE:
07ae: 8d ff     mov    y,#$ff
07b0: e5 22 04  mov    a,EchoVolLTgt
07b3: 10 0d     bpl    L07C2
07b5: 65 25 04  cmp    a,EchoVolLCur
07b8: f0 05     beq    L07BF
07ba: 8c 25 04  dec    EchoVolLCur
07bd: 8d 00     mov    y,#$00

L07BF:
07bf: 5f cc 07  jmp    L07CC

L07C2:
07c2: 65 22 04  cmp    a,EchoVolLTgt
07c5: f0 05     beq    L07CC
07c7: ac 25 04  inc    EchoVolLCur
07ca: 8d 00     mov    y,#$00

L07CC:
07cc: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
07cf: e5 25 04  mov    a,EchoVolLCur
07d2: c4 f3     mov    DSPDATA,a
07d4: e5 23 04  mov    a,EchoVolRTgt
07d7: 10 0d     bpl    L07E6
07d9: 65 26 04  cmp    a,EchoVolRCur
07dc: f0 05     beq    L07E3
07de: 8c 26 04  dec    EchoVolRCur
07e1: 8d 00     mov    y,#$00

L07E3:
07e3: 5f f0 07  jmp    L07F0

L07E6:
07e6: 65 26 04  cmp    a,EchoVolRCur
07e9: f0 05     beq    L07F0
07eb: ac 26 04  inc    EchoVolRCur
07ee: 8d 00     mov    y,#$00

L07F0:
07f0: c5 26 04  mov    EchoVolRCur,a
07f3: cc 20 04  mov    EchoTimer,y
07f6: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
07f9: e5 26 04  mov    a,EchoVolRCur
07fc: c4 f3     mov    DSPDATA,a
.voices:
07fe: 8f 7c f2  mov    DSPADDR,#$7c          ; latch + clear ENDX
0801: e4 f3     mov    a,DSPDATA
0803: c4 d7     mov    EndxLatch,a
0805: 8f 00 f3  mov    DSPDATA,#$00
0808: 8f 70 da  mov    CurVoiceDsp,#$70      ; DSP base / bit of voice 7
080b: 8f 80 29  mov    VoiceBit,#$80
080e: cd 07     mov    x,#$07

VoiceLoop:
0810: d8 28     mov    CurVoice,x
0812: bb ad     inc    VAgeLo+x              ; voice age++
0814: d0 02     bne    L0818
0816: bb a5     inc    VAgeHi+x

L0818:
0818: f4 b5     mov    a,VoiceState+x        ; key-on state
081a: c4 24     mov    VState,a
081c: 28 03     and    a,#$03
081e: f0 11     beq    .checkVoice
0820: 9c        dec    a                     ; 2 -> 1 : one-frame delay after the old note was cut
0821: f0 08     beq    L082B
0823: 38 fc 24  and    VState,#$fc
0826: 04 24     or     a,VState
0828: 5f 71 08  jmp    L0871

L082B:
082b: 3f 72 0c  call   VoiceKeyOn            ; 1 : key on now
082e: 5f 73 08  jmp    .nextVoice
.checkVoice:
0831: f3 24 3f  bbc7   VState,.nextVoice     ; playing?
0834: 83 24 06  bbs4   VState,L083D          ; ignore ENDX?
0837: f3 d7 03  bbc7   EndxLatch,L083D       ; sample ended
083a: 8f 00 24  mov    VState,#$00

L083D:
083d: f5 40 02  mov    a,VFlags+x            ; VFlags
0840: c4 27     mov    CurFlags,a
0842: b3 24 03  bbc5   VState,L0848          ; tremolo / auto-pan running?
0845: 3f e2 18  call   TremoloUpdate

L0848:
0848: e4 da     mov    a,CurVoiceDsp         ; ENVX
084a: 60        clrc
084b: 88 08     adc    a,#$08
084d: c4 f2     mov    DSPADDR,a
084f: e4 f3     mov    a,DSPDATA
0851: 75 38 02  cmp    a,VPrevEnvx+x         ; falling ...
0854: b0 10     bcs    L0866
0856: 68 10     cmp    a,#$10                ; ... below $10 (v1.01: 8) ...
0858: b0 0c     bcs    L0866
085a: 23 27 09  bbs1   CurFlags,L0866        ; ... and flag bit1 clear -> finished
085d: 8f 00 24  mov    VState,#$00
0860: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0863: fa 29 f3  mov    (DSPDATA),(VoiceBit)

L0866:
0866: d5 38 02  mov    VPrevEnvx+x,a
0869: f3 24 03  bbc7   VState,L086F          ; gate countdown
086c: 3f e0 08  call   VoiceGateCountdown

L086F:
086f: e4 24     mov    a,VState

L0871:
0871: d4 b5     mov    VoiceState+x,a
.nextVoice:
0873: 0b d7     asl    EndxLatch
0875: 4b 29     lsr    VoiceBit
0877: 80        setc
0878: b8 10 da  sbc    CurVoiceDsp,#$10
087b: 1d        dec    x
087c: 30 03     bmi    L0881
087e: 5f 10 08  jmp    VoiceLoop

L0881:
0881: e4 e1     mov    a,SeqDisable          ; SeqDisable -> skip sequencer
0883: f0 03     beq    TrackLoop
0885: 5f 43 07  jmp    MainLoop

TrackLoop:
0888: 8f 15 22  mov    CurTrack,#$15

L088B:
088b: f8 22     mov    x,CurTrack
088d: f5 1a 02  mov    a,TrkStatus+x
0890: 28 80     and    a,#$80
0892: f0 45     beq    L08D9
0894: f5 86 03  mov    a,TrkTempo+x          ; TrkTempo * ticks * 16 : one byte tempo, no 8.8 table as in v1.01
0897: eb 1f     mov    y,TicksElapsed
0899: cf        mul    ya
089a: cb 03     mov    $03,y
089c: 1c        asl    a
089d: 2b 03     rol    $03
089f: 1c        asl    a
08a0: 2b 03     rol    $03
08a2: 1c        asl    a
08a3: 2b 03     rol    $03
08a5: 1c        asl    a
08a6: 2b 03     rol    $03
08a8: c4 02     mov    $02,a
08aa: 80        setc                         ; TrkTimer -= step
08ab: f4 6f     mov    a,TrkTimerFrac+x
08ad: a4 02     sbc    a,$02
08af: d4 6f     mov    TrkTimerFrac+x,a
08b1: f4 59     mov    a,TrkTimerLo+x
08b3: a4 03     sbc    a,$03
08b5: d4 59     mov    TrkTimerLo+x,a
08b7: f4 43     mov    a,TrkTimerMid+x
08b9: a8 00     sbc    a,#$00
08bb: d4 43     mov    TrkTimerMid+x,a
08bd: f4 2d     mov    a,TrkTimerHi+x
08bf: a8 00     sbc    a,#$00
08c1: d4 2d     mov    TrkTimerHi+x,a
.runEvents:
08c3: f4 2d     mov    a,TrkTimerHi+x
08c5: 30 08     bmi    L08CF
08c7: 14 43     or     a,TrkTimerMid+x
08c9: 14 59     or     a,TrkTimerLo+x
08cb: 14 6f     or     a,TrkTimerFrac+x
08cd: d0 0a     bne    L08D9

L08CF:
08cf: 3f 4e 0a  call   ProcessTrackEvents
08d2: f5 1a 02  mov    a,TrkStatus+x
08d5: 28 80     and    a,#$80
08d7: d0 ea     bne    .runEvents

L08D9:
08d9: 8b 22     dec    CurTrack
08db: 10 ae     bpl    L088B
08dd: 5f 43 07  jmp    MainLoop

; =============================================================================
; VoiceGateCountdown - the gate is kept in 8 ms ticks (converted from the
; sequence value when the note starts), so it is NOT affected by later tempo
; changes (v1.01 counts it down with the track tempo instead).
; =============================================================================
VoiceGateCountdown:
08e0: f4 8d     mov    a,VGateHi+x
08e2: 10 01     bpl    L08E5
08e4: 6f        ret

L08E5:
08e5: f4 9d     mov    a,VGateLo+x           ; gate -= ticks
08e7: 80        setc
08e8: a4 1f     sbc    a,TicksElapsed
08ea: d4 9d     mov    VGateLo+x,a
08ec: f4 95     mov    a,VGateMid+x
08ee: a8 00     sbc    a,#$00
08f0: d4 95     mov    VGateMid+x,a
08f2: b0 04     bcs    L08F8
08f4: 9b 8d     dec    VGateHi+x
08f6: 30 07     bmi    L08FF

L08F8:
08f8: 14 9d     or     a,VGateLo+x
08fa: 14 8d     or     a,VGateHi+x
08fc: f0 01     beq    L08FF
08fe: 6f        ret

L08FF:
08ff: 93 27 09  bbc4   CurFlags,L090B        ; VFlags bit4 : one-shot -> mark old, no release
0902: e8 00     mov    a,#$00
0904: d4 ad     mov    VAgeLo+x,a
0906: e8 80     mov    a,#$80
0908: d4 a5     mov    VAgeHi+x,a
090a: 6f        ret

L090B:
090b: 8f b7 00  mov    BlockEnd,#$b7         ; release GAIN: $b7 (bit5), $b0 (bit6), else $bf
090e: a3 27 0c  bbs5   CurFlags,L091D
0911: c3 27 06  bbs6   CurFlags,L091A
0914: 8f bf 00  mov    BlockEnd,#$bf
0917: 5f 1d 09  jmp    L091D

L091A:
091a: 8f b0 00  mov    BlockEnd,#$b0

L091D:
091d: e4 da     mov    a,CurVoiceDsp
091f: 60        clrc
0920: 88 05     adc    a,#$05
0922: c4 f2     mov    DSPADDR,a
0924: 8f 00 f3  mov    DSPDATA,#$00
0927: bc        inc    a
0928: bc        inc    a
0929: c4 f2     mov    DSPADDR,a
092b: fa 00 f3  mov    (DSPDATA),(BlockEnd)
092e: 6f        ret

; AllocVoice - same algorithm as v1.01 (free/oldest, lower, equal priority)
AllocVoice:
092f: 6d        push   y
0930: f8 22     mov    x,CurTrack
0932: f5 68 02  mov    a,TrkPriority+x
0935: 28 3f     and    a,#$3f
0937: c4 03     mov    $03,a
0939: e8 00     mov    a,#$00
093b: fd        mov    y,a
093c: c4 04     mov    $04,a
093e: c4 06     mov    $06,a
0940: c4 08     mov    $08,a
0942: da 0a     movw   $0a,ya
0944: da 0c     movw   $0c,ya
0946: da 0e     movw   $0e,ya
0948: cd 07     mov    x,#$07

L094A:
094a: fb a5     mov    y,VAgeHi+x
094c: f4 b5     mov    a,VoiceState+x
094e: 28 83     and    a,#$83
0950: d0 0f     bne    L0961
0952: f4 ad     mov    a,VAgeLo+x
0954: 5a 0a     cmpw   ya,$0a
0956: 90 06     bcc    L095E                 ; (no monophonic mode in this version)
0958: ab 04     inc    $04
095a: da 0a     movw   $0a,ya
095c: d8 05     mov    $05,x

L095E:
095e: 5f 8b 09  jmp    L098B

L0961:
0961: e4 04     mov    a,$04
0963: d0 26     bne    L098B
0965: f5 30 02  mov    a,VPriority+x
0968: 28 3f     and    a,#$3f
096a: 64 03     cmp    a,$03
096c: d0 0f     bne    L097D
096e: f4 ad     mov    a,VAgeLo+x
0970: 5a 0c     cmpw   ya,$0c
0972: 90 06     bcc    L097A
0974: ab 06     inc    $06
0976: da 0c     movw   $0c,ya
0978: d8 07     mov    $07,x

L097A:
097a: 5f 8b 09  jmp    L098B

L097D:
097d: b0 0c     bcs    L098B
097f: f4 ad     mov    a,VAgeLo+x
0981: 5a 0e     cmpw   ya,$0e
0983: 90 06     bcc    L098B
0985: ab 08     inc    $08
0987: da 0e     movw   $0e,ya
0989: d8 09     mov    $09,x

L098B:
098b: 1d        dec    x
098c: 10 bc     bpl    L094A
098e: f8 05     mov    x,$05
0990: e4 04     mov    a,$04
0992: d0 0f     bne    L09A3
0994: f8 09     mov    x,$09
0996: e4 08     mov    a,$08
0998: d0 09     bne    L09A3
099a: f8 07     mov    x,$07
099c: e4 06     mov    a,$06
099e: d0 03     bne    L09A3
09a0: ee        pop    y
09a1: 80        setc
09a2: 6f        ret

L09A3:
09a3: e8 00     mov    a,#$00
09a5: d4 ad     mov    VAgeLo+x,a
09a7: d4 a5     mov    VAgeHi+x,a
09a9: e4 03     mov    a,$03
09ab: d5 30 02  mov    VPriority+x,a
09ae: f5 10 0f  mov    a,VoiceBitMask+x      ; clear voice bit in two unused masks
09b1: 48 ff     eor    a,#$ff
09b3: 24 df     and    a,UnusedMaskB
09b5: c4 df     mov    UnusedMaskB,a
09b7: f5 10 0f  mov    a,VoiceBitMask+x
09ba: 48 ff     eor    a,#$ff
09bc: 24 de     and    a,UnusedMaskA
09be: c4 de     mov    UnusedMaskA,a
09c0: f5 08 0f  mov    a,VoiceDspBase+x      ; cut the voice: ADSR1 = 0, GAIN = $9f
09c3: 60        clrc
09c4: 88 05     adc    a,#$05
09c6: c4 f2     mov    DSPADDR,a
09c8: 8f 00 f3  mov    DSPDATA,#$00
09cb: bc        inc    a
09cc: bc        inc    a
09cd: c4 f2     mov    DSPADDR,a
09cf: 8f 9f f3  mov    DSPDATA,#$9f
09d2: ee        pop    y
09d3: 60        clrc
09d4: 6f        ret

InitDSP:
09d5: e8 00     mov    a,#$00
09d7: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
09da: c4 f3     mov    DSPDATA,a
09dc: 8f 2d f2  mov    DSPADDR,#$2d          ; PMON
09df: c4 f3     mov    DSPDATA,a
09e1: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
09e4: c4 f3     mov    DSPDATA,a
09e6: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
09e9: c4 f3     mov    DSPDATA,a
09eb: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
09ee: c4 f3     mov    DSPDATA,a
09f0: e8 7f     mov    a,#$7f
09f2: 8f 0c f2  mov    DSPADDR,#$0c          ; MVOLL
09f5: c4 f3     mov    DSPDATA,a
09f7: 8f 1c f2  mov    DSPADDR,#$1c          ; MVOLR
09fa: c4 f3     mov    DSPDATA,a
09fc: 8f 5d f2  mov    DSPADDR,#$5d          ; DIR
09ff: fa 16 f3  mov    (DSPDATA),(DirPtr+1)
0a02: cd 00     mov    x,#$00
0a04: 8d 08     mov    y,#$08

L0A06:
0a06: 4d        push   x
0a07: e8 00     mov    a,#$00
0a09: d8 f2     mov    DSPADDR,x
0a0b: c4 f3     mov    DSPDATA,a
0a0d: 3d        inc    x
0a0e: d8 f2     mov    DSPADDR,x
0a10: c4 f3     mov    DSPDATA,a
0a12: 3d        inc    x
0a13: 3d        inc    x
0a14: 3d        inc    x
0a15: d8 f2     mov    DSPADDR,x
0a17: c4 f3     mov    DSPDATA,a
0a19: 3d        inc    x
0a1a: d8 f2     mov    DSPADDR,x
0a1c: c4 f3     mov    DSPDATA,a
0a1e: 3d        inc    x
0a1f: 3d        inc    x
0a20: d8 f2     mov    DSPADDR,x
0a22: c4 f3     mov    DSPDATA,a
0a24: ae        pop    a
0a25: 60        clrc
0a26: 88 10     adc    a,#$10
0a28: 5d        mov    x,a
0a29: fe db     dbnz   y,L0A06
0a2b: e8 ff     mov    a,#$ff                ; EchoDelayCur = $ff
0a2d: c5 1f 04  mov    EchoDelayCur,a
0a30: 8f 40 d8  mov    FlgShadow,#$40        ; FLG shadow = $40 while writing echo defaults ...
0a33: 8f 68 00  mov    BlockEnd,#$68         ; EchoDefaults at $1968
0a36: 8f 19 01  mov    BlockEnd+1,#$19
0a39: 3f 74 19  call   SetEchoParams
0a3c: 8f 00 d8  mov    FlgShadow,#$00        ; ... then FLG shadow = 0 (v1.01 keeps the mute until the first sound)
0a3f: 8f 03 f1  mov    CONTROL,#$03          ; CONTROL = $03: timers 0/1 on, IPL ROM hidden (RAM at $ffc0-$ffff)
0a42: 8f 40 fa  mov    T0DIV,#$40
0a45: 8f 40 fb  mov    T1DIV,#$40
0a48: e4 fd     mov    a,T0OUT
0a4a: e4 fe     mov    a,T1OUT
0a4c: 6f        ret

; NullSub - empty (called at the end of StartSound; v1.01 unmutes the DSP there)
NullSub:
0a4d: 6f        ret

; =============================================================================
; ProcessTrackEvents - older command set, decoded with a CMP chain
;   00-BF  note  [vel] <gate VLQ> <delta VLQ>   (80-BF are notes too)
;   C0-DF  pitch bend (5-bit signed semitones, fraction byte)
;   E1 nop   E2 loop   E3 end   E6 program   E7 tempo   E8 next pattern
;   E9 cc vv controller   EA xx yy (skipped)   EB stop point
;   Any other E0-FF byte falls through to the NOTE handler (no nop/sync cmds)
; =============================================================================
ProcessTrackEvents:
0a4e: f5 ec 02  mov    a,TrkPtrLo+x
0a51: c4 20     mov    SeqPtr,a
0a53: f5 02 03  mov    a,TrkPtrHi+x
0a56: c4 21     mov    SeqPtr+1,a
0a58: f5 d6 02  mov    a,TrkFlags+x
0a5b: c4 27     mov    CurFlags,a
0a5d: f5 7e 02  mov    a,TrkTranspose+x      ; TrkTranspose (header transpose)
0a60: c4 d9     mov    HdrTranspose,a
0a62: f5 86 03  mov    a,TrkTempo+x          ; TrkTempo
0a65: c4 23     mov    CurTempo,a
.nextEvent:
0a67: 8d 00     mov    y,#$00
0a69: f7 20     mov    a,(SeqPtr)+y
0a6b: 3a 20     incw   SeqPtr
0a6d: 68 c0     cmp    a,#$c0                ; < $c0 : note
0a6f: b0 03     bcs    L0A74
0a71: 5f ea 0b  jmp    .note

L0A74:
0a74: 68 e0     cmp    a,#$e0                ; >= $e0 : command
0a76: b0 2d     bcs    .cmd
0a78: 28 1f     and    a,#$1f                ; C0-DF : bend semitones (signed 5 bit)
0a7a: 68 10     cmp    a,#$10
0a7c: 90 02     bcc    L0A80
0a7e: 08 e0     or     a,#$e0

L0A80:
0a80: d5 5a 03  mov    TrkBendHi+x,a
0a83: c4 0d     mov    $0d,a
0a85: f7 20     mov    a,(SeqPtr)+y          ; bend fraction
0a87: 3a 20     incw   SeqPtr
0a89: c4 0c     mov    $0c,a
0a8b: d5 70 03  mov    TrkBendLo+x,a
0a8e: f5 aa 02  mov    a,TrkSoundID+x
0a91: c4 04     mov    $04,a
0a93: 8f fd 08  mov    $08,#$fd              ; param $fd = bend, applied to the voices only
0a96: f5 44 03  mov    a,TrkNumber+x
0a99: c4 09     mov    $09,a
0a9b: 4d        push   x
0a9c: 6d        push   y
0a9d: 3f 46 17  call   ApplyParamToVoices
0aa0: ee        pop    y
0aa1: ce        pop    x
0aa2: 5f 4f 0c  jmp    ReadDeltaAndAdvance
.cmd:
0aa5: 68 e3     cmp    a,#$e3                ; E3 : end of track
0aa7: d0 26     bne    L0ACF
0aa9: 1a 20     decw   SeqPtr                ; pointer stays on the E3
0aab: f5 d6 02  mov    a,TrkFlags+x          ; TrkFlags bit7 : loop
0aae: 28 80     and    a,#$80
0ab0: d0 64     bne    LoopBack
0ab2: f5 1a 02  mov    a,TrkStatus+x         ; deactivate
0ab5: 28 7f     and    a,#$7f
0ab7: d5 1a 02  mov    TrkStatus+x,a
0aba: 28 10     and    a,#$10                ; chain bit -> start the chained sound
0abc: f0 03     beq    .endNotify
0abe: 3f 3a 0d  call   ChainNext
.endNotify:
0ac1: f5 5c ff  mov    a,TrkVolume+x         ; TrkVolume bit7 : notify the CPU when the sound has finished
0ac4: 10 03     bpl    L0AC9
0ac6: 3f 83 1c  call   NotifySoundEnded

L0AC9:
0ac9: e8 00     mov    a,#$00
0acb: d5 1a 02  mov    TrkStatus+x,a
0ace: 6f        ret

L0ACF:
0acf: 68 e1     cmp    a,#$e1                ; E1 : nop
0ad1: d0 03     bne    L0AD6
0ad3: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0AD6:
0ad6: 68 e2     cmp    a,#$e2                ; E2 : loop start (00) / loop back
0ad8: d0 55     bne    L0B2F
0ada: f7 20     mov    a,(SeqPtr)+y
0adc: d0 1b     bne    L0AF9
0ade: 3a 20     incw   SeqPtr
0ae0: e4 20     mov    a,SeqPtr
0ae2: d5 46 ff  mov    TrkLoopPtrLo+x,a
0ae5: e4 21     mov    a,SeqPtr+1
0ae7: d5 30 ff  mov    TrkLoopPtrHi+x,a
0aea: f5 2e 03  mov    a,TrkListLo+x
0aed: d5 ca ff  mov    TrkLoopListLo+x,a
0af0: f5 18 03  mov    a,TrkListHi+x
0af3: d5 b4 ff  mov    TrkLoopListHi+x,a
0af6: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0AF9:
0af9: f5 1a 02  mov    a,TrkStatus+x         ; stop requested (bit1/2) -> end track
0afc: 28 06     and    a,#$06
0afe: f0 16     beq    LoopBack
0b00: f5 1a 02  mov    a,TrkStatus+x
0b03: 28 7f     and    a,#$7f
0b05: d5 1a 02  mov    TrkStatus+x,a
0b08: 28 10     and    a,#$10
0b0a: f0 03     beq    L0B0F
0b0c: 3f 3a 0d  call   ChainNext

L0B0F:
0b0f: 5f c1 0a  jmp    .endNotify

DeadCode1:
0b12: 6f        ret                          ; unreachable leftovers
0b13: 5f 2c 0b  jmp    L0B2C

LoopBack:
0b16: f5 30 ff  mov    a,TrkLoopPtrHi+x
0b19: c4 21     mov    SeqPtr+1,a
0b1b: f5 46 ff  mov    a,TrkLoopPtrLo+x
0b1e: c4 20     mov    SeqPtr,a
0b20: f5 ca ff  mov    a,TrkLoopListLo+x
0b23: d5 2e 03  mov    TrkListLo+x,a
0b26: f5 b4 ff  mov    a,TrkLoopListHi+x
0b29: d5 18 03  mov    TrkListHi+x,a

L0B2C:
0b2c: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0B2F:
0b2f: 68 eb     cmp    a,#$eb                ; EB : stop point (bit1 only)
0b31: d0 1d     bne    L0B50
0b33: f5 1a 02  mov    a,TrkStatus+x
0b36: 28 02     and    a,#$02
0b38: f0 13     beq    L0B4D
0b3a: f5 1a 02  mov    a,TrkStatus+x
0b3d: 28 7f     and    a,#$7f
0b3f: d5 1a 02  mov    TrkStatus+x,a
0b42: 28 10     and    a,#$10
0b44: f0 03     beq    L0B49
0b46: 3f 3a 0d  call   ChainNext

L0B49:
0b49: 5f c1 0a  jmp    .endNotify

DeadCode2:
0b4c: 6f        ret                          ; unreachable

L0B4D:
0b4d: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0B50:
0b50: 68 e6     cmp    a,#$e6                ; E6 pp : program
0b52: d0 0a     bne    L0B5E
0b54: f7 20     mov    a,(SeqPtr)+y
0b56: d5 c0 02  mov    TrkProgram+x,a
0b59: 3a 20     incw   SeqPtr
0b5b: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0B5E:
0b5e: 68 e7     cmp    a,#$e7                ; E7 tt : tempo (raw byte, 125*tt/16 ticks per second)
0b60: d0 0a     bne    L0B6C
0b62: f7 20     mov    a,(SeqPtr)+y
0b64: d5 86 03  mov    TrkTempo+x,a
0b67: 3a 20     incw   SeqPtr
0b69: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0B6C:
0b6c: 68 e8     cmp    a,#$e8                ; E8 : next pattern
0b6e: d0 36     bne    L0BA6
0b70: f5 2e 03  mov    a,TrkListLo+x
0b73: c4 02     mov    $02,a
0b75: f5 18 03  mov    a,TrkListHi+x
0b78: c4 03     mov    $03,a
0b7a: 3a 02     incw   $02
0b7c: 3a 02     incw   $02
0b7e: e4 03     mov    a,$03
0b80: d5 18 03  mov    TrkListHi+x,a
0b83: e4 02     mov    a,$02
0b85: d5 2e 03  mov    TrkListLo+x,a
0b88: f7 02     mov    a,($02)+y
0b8a: c4 20     mov    SeqPtr,a
0b8c: fc        inc    y
0b8d: f7 02     mov    a,($02)+y
0b8f: c4 21     mov    SeqPtr+1,a
0b91: dc        dec    y
0b92: f5 e0 ff  mov    a,TrkPatBaseLo+x
0b95: 60        clrc
0b96: 84 20     adc    a,SeqPtr
0b98: c4 20     mov    SeqPtr,a
0b9a: f5 b2 03  mov    a,TrkPatBaseHi+x
0b9d: 84 21     adc    a,SeqPtr+1
0b9f: c4 21     mov    SeqPtr+1,a
0ba1: 3a 20     incw   SeqPtr
0ba3: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0BA6:
0ba6: 68 e9     cmp    a,#$e9                ; E9 cc vv : 1 = volume, 2 = pan
0ba8: d0 35     bne    L0BDF
0baa: f5 aa 02  mov    a,TrkSoundID+x
0bad: c4 04     mov    $04,a
0baf: f5 44 03  mov    a,TrkNumber+x
0bb2: c4 09     mov    $09,a
0bb4: f7 20     mov    a,(SeqPtr)+y
0bb6: 3a 20     incw   SeqPtr
0bb8: 68 01     cmp    a,#$01
0bba: d0 0d     bne    L0BC9
0bbc: f7 20     mov    a,(SeqPtr)+y
0bbe: c4 05     mov    $05,a
0bc0: 8f 00 08  mov    $08,#$00
0bc3: 3f ed 16  call   ApplyParamToSound
0bc6: 5f da 0b  jmp    L0BDA

L0BC9:
0bc9: 68 02     cmp    a,#$02
0bcb: d0 0d     bne    L0BDA
0bcd: f7 20     mov    a,(SeqPtr)+y
0bcf: c4 05     mov    $05,a
0bd1: 8f 01 08  mov    $08,#$01
0bd4: 3f ed 16  call   ApplyParamToSound
0bd7: 5f da 0b  jmp    L0BDA

L0BDA:
0bda: 3a 20     incw   SeqPtr
0bdc: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0BDF:
0bdf: 68 ea     cmp    a,#$ea                ; EA xx yy : skipped
0be1: d0 07     bne    .note
0be3: 3a 20     incw   SeqPtr
0be5: 3a 20     incw   SeqPtr
0be7: 5f 4f 0c  jmp    ReadDeltaAndAdvance
.note:
0bea: 2d        push   a
0beb: 03 27 09  bbs0   CurFlags,L0BF7        ; TrkFlags bit0 : no velocity byte
0bee: f7 20     mov    a,(SeqPtr)+y
0bf0: c4 c6     mov    Velocity,a
0bf2: 3a 20     incw   SeqPtr
0bf4: 5f fa 0b  jmp    L0BFA

L0BF7:
0bf7: 8f 7f c6  mov    Velocity,#$7f

L0BFA:
0bfa: f5 1a 02  mov    a,TrkStatus+x         ; TrkStatus bit0 : muted
0bfd: 28 01     and    a,#$01
0bff: f0 07     beq    L0C08
0c01: 3f b3 0c  call   ReadVLQ               ; skip gate
0c04: ae        pop    a
0c05: 5f 4f 0c  jmp    ReadDeltaAndAdvance

L0C08:
0c08: 3f 2f 09  call   AllocVoice            ; get a voice
0c0b: 90 12     bcc    .gotVoice
0c0d: f7 20     mov    a,(SeqPtr)+y          ; no voice: skip gate VLQ by hand
0c0f: 10 08     bpl    L0C19
0c11: 3a 20     incw   SeqPtr
0c13: f7 20     mov    a,(SeqPtr)+y
0c15: 10 02     bpl    L0C19
0c17: 3a 20     incw   SeqPtr

L0C19:
0c19: ae        pop    a
0c1a: 3a 20     incw   SeqPtr
0c1c: 5f 4f 0c  jmp    ReadDeltaAndAdvance
.gotVoice:
0c1f: d8 28     mov    CurVoice,x
0c21: e4 c6     mov    a,Velocity
0c23: d5 58 02  mov    VVelocity+x,a
0c26: ae        pop    a
0c27: d5 50 02  mov    VNote+x,a
0c2a: e4 22     mov    a,CurTrack
0c2c: d5 60 02  mov    VTrack+x,a
0c2f: 8d 00     mov    y,#$00
0c31: 3f b3 0c  call   ReadVLQ               ; gate VLQ
0c34: fa 19 02  mov    ($02),($19)
0c37: fa 1a 03  mov    ($03),($1a)
0c3a: 3f fc 0c  call   GateToTicks           ; gate -> 8 ms ticks: gate*32/tempo
0c3d: e4 02     mov    a,$02
0c3f: d4 9d     mov    VGateLo+x,a
0c41: e4 03     mov    a,$03
0c43: d4 95     mov    VGateMid+x,a
0c45: e4 04     mov    a,$04
0c47: d4 8d     mov    VGateHi+x,a
0c49: f4 b5     mov    a,VoiceState+x
0c4b: e8 02     mov    a,#$02                ; (dead load) state = 2 : key on after a one-frame delay
0c4d: d4 b5     mov    VoiceState+x,a

ReadDeltaAndAdvance:
0c4f: f8 22     mov    x,CurTrack
0c51: 3f b3 0c  call   ReadVLQ
0c54: 60        clrc
0c55: e4 19     mov    a,$19
0c57: 94 59     adc    a,TrkTimerLo+x
0c59: d4 59     mov    TrkTimerLo+x,a
0c5b: e4 1a     mov    a,$1a
0c5d: 94 43     adc    a,TrkTimerMid+x
0c5f: d4 43     mov    TrkTimerMid+x,a
0c61: e4 1b     mov    a,$1b
0c63: 94 2d     adc    a,TrkTimerHi+x
0c65: d4 2d     mov    TrkTimerHi+x,a
0c67: e4 20     mov    a,SeqPtr
0c69: d5 ec 02  mov    TrkPtrLo+x,a
0c6c: e4 21     mov    a,SeqPtr+1
0c6e: d5 02 03  mov    TrkPtrHi+x,a
0c71: 6f        ret

; VoiceKeyOn - copy track state into voice X and call VoiceNoteOn
VoiceKeyOn:
0c72: d8 28     mov    CurVoice,x
0c74: f5 60 02  mov    a,VTrack+x
0c77: c4 22     mov    CurTrack,a
0c79: fd        mov    y,a
0c7a: f6 d6 02  mov    a,TrkFlags+y
0c7d: d5 40 02  mov    VFlags+x,a
0c80: f6 7e 02  mov    a,TrkTranspose+y
0c83: c4 d9     mov    HdrTranspose,a
0c85: f6 aa 02  mov    a,TrkSoundID+y
0c88: d4 85     mov    VSoundID+x,a
0c8a: f6 44 03  mov    a,TrkNumber+y
0c8d: d5 48 02  mov    VTrkNumber+x,a
0c90: f6 5a 03  mov    a,TrkBendHi+y
0c93: d5 f3 03  mov    VBendHi+x,a
0c96: f6 70 03  mov    a,TrkBendLo+y
0c99: d5 eb 03  mov    VBendLo+x,a
0c9c: e8 80     mov    a,#$80
0c9e: d4 b5     mov    VoiceState+x,a
0ca0: e8 00     mov    a,#$00
0ca2: d5 38 02  mov    VPrevEnvx+x,a
0ca5: f5 58 02  mov    a,VVelocity+x
0ca8: c4 c6     mov    Velocity,a
0caa: f5 50 02  mov    a,VNote+x
0cad: 3f 18 0f  call   VoiceNoteOn
0cb0: f8 28     mov    x,CurVoice
0cb2: 6f        ret

; ReadVLQ - identical to v1.01 (result in $19-$1b)
ReadVLQ:
0cb3: 8d 00     mov    y,#$00
0cb5: cb 19     mov    $19,y
0cb7: cb 1a     mov    $1a,y
0cb9: cb 1b     mov    $1b,y
0cbb: f7 20     mov    a,(SeqPtr)+y
0cbd: 10 38     bpl    L0CF7
0cbf: 28 7f     and    a,#$7f
0cc1: c4 1a     mov    $1a,a
0cc3: 4b 1a     lsr    $1a
0cc5: 6b 19     ror    $19
0cc7: 3a 20     incw   SeqPtr
0cc9: f7 20     mov    a,(SeqPtr)+y
0ccb: 10 20     bpl    L0CED
0ccd: 28 7f     and    a,#$7f
0ccf: fa 1a 1b  mov    ($1b),($1a)
0cd2: 04 19     or     a,$19
0cd4: c4 1a     mov    $1a,a
0cd6: 8f 00 19  mov    $19,#$00
0cd9: 4b 1b     lsr    $1b
0cdb: 6b 1a     ror    $1a
0cdd: 6b 19     ror    $19
0cdf: 3a 20     incw   SeqPtr
0ce1: f7 20     mov    a,(SeqPtr)+y
0ce3: 04 19     or     a,$19
0ce5: c4 19     mov    $19,a
0ce7: 3a 20     incw   SeqPtr
0ce9: 6f        ret

DeadCode3:
0cea: 5f f4 0c  jmp    DeadCode4             ; unreachable

L0CED:
0ced: 04 19     or     a,$19
0cef: c4 19     mov    $19,a
0cf1: 3a 20     incw   SeqPtr
0cf3: 6f        ret

DeadCode4:
0cf4: 5f fc 0c  jmp    GateToTicks           ; unreachable

L0CF7:
0cf7: c4 19     mov    $19,a
0cf9: 3a 20     incw   SeqPtr
0cfb: 6f        ret

; GateToTicks - $02/$03 = ($02/$03/$04 << 5) / CurTempo
GateToTicks:
0cfc: 4d        push   x
0cfd: 6d        push   y
0cfe: 8d 00     mov    y,#$00
0d00: cb 04     mov    $04,y
0d02: 0b 02     asl    $02
0d04: 2b 03     rol    $03
0d06: 2b 04     rol    $04
0d08: 0b 02     asl    $02
0d0a: 2b 03     rol    $03
0d0c: 2b 04     rol    $04
0d0e: 0b 02     asl    $02
0d10: 2b 03     rol    $03
0d12: 2b 04     rol    $04
0d14: 0b 02     asl    $02
0d16: 2b 03     rol    $03
0d18: 2b 04     rol    $04
0d1a: 0b 02     asl    $02
0d1c: 2b 03     rol    $03
0d1e: 2b 04     rol    $04
0d20: f8 23     mov    x,CurTempo
0d22: e4 04     mov    a,$04
0d24: 9e        div    ya,x
0d25: c4 08     mov    $08,a
0d27: e4 03     mov    a,$03
0d29: 9e        div    ya,x
0d2a: c4 07     mov    $07,a
0d2c: e4 02     mov    a,$02
0d2e: 9e        div    ya,x
0d2f: c4 06     mov    $06,a
0d31: fa 06 02  mov    ($02),($06)
0d34: fa 07 03  mov    ($03),($07)
0d37: ee        pop    y
0d38: ce        pop    x
0d39: 6f        ret

; =============================================================================
; ChainNext - track with the chain bit ended: look the sound up in ChainList
;  and push a "start sound" event (type 2 + parameter entry) into the event
;  queue.  v1.01 still records the list but this routine became a RET stub.
; =============================================================================
ChainNext:
0d3a: f5 aa 02  mov    a,TrkSoundID+x
0d3d: 8d 06     mov    y,#$06

L0D3F:
0d3f: f6 cb 03  mov    a,ChainList+y
0d42: 68 ff     cmp    a,#$ff
0d44: f0 05     beq    L0D4B
0d46: 75 aa 02  cmp    a,TrkSoundID+x
0d49: f0 05     beq    L0D50

L0D4B:
0d4b: dc        dec    y
0d4c: dc        dec    y
0d4d: 10 f0     bpl    L0D3F
0d4f: 6f        ret

L0D50:
0d50: e8 ff     mov    a,#$ff
0d52: d6 cb 03  mov    ChainList+y,a
0d55: f6 cc 03  mov    a,ChainList+1+y
0d58: 2d        push   a
0d59: ec 90 04  mov    y,QueueWrite          ; queue: type 2, next ID, key offset, handle
0d5c: e8 02     mov    a,#$02
0d5e: d6 92 04  mov    EventQueue+y,a
0d61: ae        pop    a
0d62: fc        inc    y
0d63: d6 92 04  mov    EventQueue+y,a
0d66: fc        inc    y
0d67: f5 72 ff  mov    a,TrkKeyOffset+x
0d6a: d6 92 04  mov    EventQueue+y,a
0d6d: fc        inc    y
0d6e: f5 aa 02  mov    a,TrkSoundID+x
0d71: d6 92 04  mov    EventQueue+y,a
0d74: fc        inc    y
0d75: dd        mov    a,y
0d76: 28 3f     and    a,#$3f
0d78: fd        mov    y,a
0d79: e8 03     mov    a,#$03                ; parameter entry: (3), pan $ff = header, volume, tempo offset
0d7b: d6 92 04  mov    EventQueue+y,a
0d7e: fc        inc    y
0d7f: e8 ff     mov    a,#$ff
0d81: d6 92 04  mov    EventQueue+y,a
0d84: fc        inc    y
0d85: f5 5c ff  mov    a,TrkVolume+x
0d88: d6 92 04  mov    EventQueue+y,a
0d8b: fc        inc    y
0d8c: f5 88 ff  mov    a,TrkTempoOfs+x
0d8f: d6 92 04  mov    EventQueue+y,a
0d92: fc        inc    y
0d93: dd        mov    a,y
0d94: 28 3f     and    a,#$3f
0d96: c5 90 04  mov    QueueWrite,a
0d99: 6f        ret

; -----------------------------------------------------------------------------
; TrackPtrTable - 16 words, filled by StartSound with the absolute track
; data pointers of the sound being started (variables inside the code area;
; the values shown are from the snapshot).  SPCdas-style linear decoding
; would show "tcall 4 / clrp / cmp (x),(y) ..." here.
; -----------------------------------------------------------------------------
TrackPtrTable:
0d9a: dw    $2041,$2079,$20b1,$20e9,$2121,$2159,$215e ; snapshot values (runtime data)
0da8: db    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; unused slots ($ff)
0db8: db    $ff,$ff

; =============================================================================
; AllocTrack - X = program, Y = priority, A = index into TrackPtrTable
; =============================================================================
AllocTrack:
0dba: 4d        push   x
0dbb: cb cb     mov    PriorityTmp,y
0dbd: 1c        asl    a
0dbe: 5d        mov    x,a
0dbf: f5 9a 0d  mov    a,TrackPtrTable+x     ; track data pointer
0dc2: c4 20     mov    SeqPtr,a
0dc4: f5 9b 0d  mov    a,TrackPtrTable+1+x
0dc7: c4 21     mov    SeqPtr+1,a
0dc9: 8f 01 29  mov    VoiceBit,#$01
0dcc: cd 00     mov    x,#$00

L0DCE:
0dce: f5 1a 02  mov    a,TrkStatus+x
0dd1: 28 80     and    a,#$80
0dd3: f0 05     beq    L0DDA
0dd5: 3d        inc    x
0dd6: c8 16     cmp    x,#$16
0dd8: d0 f4     bne    L0DCE

L0DDA:
0dda: c8 16     cmp    x,#$16
0ddc: d0 07     bne    L0DE5
0dde: 3f 84 0e  call   StealTrack            ; no free track: steal
0de1: 90 02     bcc    L0DE5
0de3: ce        pop    x
0de4: 6f        ret

L0DE5:
0de5: d8 22     mov    CurTrack,x
0de7: e5 49 04  mov    a,TrkNumTmp
0dea: d5 44 03  mov    TrkNumber+x,a
0ded: e5 27 04  mov    a,PatBaseTmp
0df0: d5 e0 ff  mov    TrkPatBaseLo+x,a
0df3: e5 28 04  mov    a,PatBaseTmp+1
0df6: d5 b2 03  mov    TrkPatBaseHi+x,a
0df9: e4 cb     mov    a,PriorityTmp
0dfb: d5 68 02  mov    TrkPriority+x,a
0dfe: ae        pop    a
0dff: d5 c0 02  mov    TrkProgram+x,a
0e02: e8 00     mov    a,#$00
0e04: d4 2d     mov    TrkTimerHi+x,a
0e06: d4 43     mov    TrkTimerMid+x,a
0e08: d4 59     mov    TrkTimerLo+x,a
0e0a: d4 6f     mov    TrkTimerFrac+x,a
0e0c: d5 5a 03  mov    TrkBendHi+x,a
0e0f: d5 70 03  mov    TrkBendLo+x,a
0e12: e4 26     mov    a,HdrTrkFlags
0e14: d5 d6 02  mov    TrkFlags+x,a
0e17: e4 d9     mov    a,HdrTranspose
0e19: d5 7e 02  mov    TrkTranspose+x,a
0e1c: e5 ca 03  mov    a,StartTempoOfs       ; StartTempoOfs -> TrkTempoOfs, added to the tempo byte
0e1f: d5 88 ff  mov    TrkTempoOfs+x,a
0e22: 60        clrc
0e23: 84 23     adc    a,CurTempo
0e25: d5 86 03  mov    TrkTempo+x,a
0e28: e4 c6     mov    a,Velocity
0e2a: d5 9c 03  mov    TrkVelocity+x,a
0e2d: e5 c9 03  mov    a,StartVolume         ; StartVolume (bit7 = notify)
0e30: d5 5c ff  mov    TrkVolume+x,a
0e33: e8 80     mov    a,#$80
0e35: d5 1a 02  mov    TrkStatus+x,a
0e38: e4 04     mov    a,$04
0e3a: d5 72 ff  mov    TrkKeyOffset+x,a
0e3d: e5 c8 03  mov    a,StartPan
0e40: 28 7f     and    a,#$7f
0e42: d5 9e ff  mov    TrkPan+x,a
0e45: e4 05     mov    a,$05
0e47: d5 aa 02  mov    TrkSoundID+x,a
0e4a: 53 26 29  bbc2   HdrTrkFlags,L0E76     ; TrkFlags bit2 : order-list mode
0e4d: e4 21     mov    a,SeqPtr+1
0e4f: d5 18 03  mov    TrkListHi+x,a
0e52: d5 b4 ff  mov    TrkLoopListHi+x,a
0e55: e4 20     mov    a,SeqPtr
0e57: d5 2e 03  mov    TrkListLo+x,a
0e5a: d5 ca ff  mov    TrkLoopListLo+x,a
0e5d: 8d 00     mov    y,#$00
0e5f: f7 20     mov    a,(SeqPtr)+y
0e61: fc        inc    y
0e62: 60        clrc
0e63: 85 27 04  adc    a,PatBaseTmp
0e66: c4 10     mov    $10,a
0e68: f7 20     mov    a,(SeqPtr)+y
0e6a: dc        dec    y
0e6b: 85 28 04  adc    a,PatBaseTmp+1
0e6e: c4 21     mov    SeqPtr+1,a
0e70: e4 10     mov    a,$10
0e72: c4 20     mov    SeqPtr,a
0e74: 3a 20     incw   SeqPtr

L0E76:
0e76: e4 21     mov    a,SeqPtr+1
0e78: d5 30 ff  mov    TrkLoopPtrHi+x,a
0e7b: e4 20     mov    a,SeqPtr
0e7d: d5 46 ff  mov    TrkLoopPtrLo+x,a
0e80: 3f 4f 0c  call   ReadDeltaAndAdvance
0e83: 6f        ret

; StealTrack - identical to v1.01
StealTrack:
0e84: 78 e0 05  cmp    $05,#$e0
0e87: 90 4b     bcc    L0ED4
0e89: 8f ff 10  mov    $10,#$ff
0e8c: 8f ff 11  mov    $11,#$ff
0e8f: 8f ff 12  mov    $12,#$ff
0e92: 8f ff 13  mov    $13,#$ff
0e95: cd 15     mov    x,#$15

L0E97:
0e97: f5 aa 02  mov    a,TrkSoundID+x
0e9a: 68 e0     cmp    a,#$e0
0e9c: b0 0e     bcs    L0EAC
0e9e: f5 68 02  mov    a,TrkPriority+x
0ea1: 64 10     cmp    a,$10
0ea3: b0 04     bcs    L0EA9
0ea5: c4 10     mov    $10,a
0ea7: d8 11     mov    $11,x

L0EA9:
0ea9: 5f b7 0e  jmp    L0EB7

L0EAC:
0eac: f5 68 02  mov    a,TrkPriority+x
0eaf: 64 12     cmp    a,$12
0eb1: b0 04     bcs    L0EB7
0eb3: c4 12     mov    $12,a
0eb5: d8 13     mov    $13,x

L0EB7:
0eb7: 1d        dec    x
0eb8: 10 dd     bpl    L0E97
0eba: f8 11     mov    x,$11
0ebc: 30 04     bmi    L0EC2
0ebe: 60        clrc
0ebf: 5f d1 0e  jmp    L0ED1

L0EC2:
0ec2: e4 12     mov    a,$12
0ec4: 64 cb     cmp    a,PriorityTmp
0ec6: f0 02     beq    L0ECA
0ec8: b0 06     bcs    L0ED0

L0ECA:
0eca: f8 13     mov    x,$13
0ecc: 60        clrc
0ecd: 5f d1 0e  jmp    L0ED1

L0ED0:
0ed0: 80        setc

L0ED1:
0ed1: 5f 06 0f  jmp    L0F06

L0ED4:
0ed4: 8f ff 10  mov    $10,#$ff
0ed7: 8f ff 11  mov    $11,#$ff
0eda: cd 15     mov    x,#$15

L0EDC:
0edc: f5 aa 02  mov    a,TrkSoundID+x
0edf: 68 e0     cmp    a,#$e0
0ee1: b0 0b     bcs    L0EEE
0ee3: f5 68 02  mov    a,TrkPriority+x
0ee6: 64 10     cmp    a,$10
0ee8: b0 04     bcs    L0EEE
0eea: c4 10     mov    $10,a
0eec: d8 11     mov    $11,x

L0EEE:
0eee: 1d        dec    x
0eef: 10 eb     bpl    L0EDC
0ef1: f8 11     mov    x,$11
0ef3: 30 10     bmi    L0F05
0ef5: e4 10     mov    a,$10
0ef7: 64 cb     cmp    a,PriorityTmp
0ef9: f0 02     beq    L0EFD
0efb: b0 04     bcs    L0F01

L0EFD:
0efd: 60        clrc
0efe: 5f 02 0f  jmp    L0F02

L0F01:
0f01: 80        setc

L0F02:
0f02: 5f 06 0f  jmp    L0F06

L0F05:
0f05: 80        setc

L0F06:
0f06: 6f        ret

Unused0F07:
0f07: db    $00                              ; unused

VoiceDspBase:
0f08: db    $00,$10,$20,$30,$40,$50,$60,$70  ; DSP register base of voice 0-7

VoiceBitMask:
0f10: db    $01,$02,$04,$08,$10,$20,$40,$80  ; bit mask of voice 0-7

; =============================================================================
; VoiceNoteOn - A = note.  Instrument record = $0500 + program*8:
;   0 SRCN (bit7: drum map, $ff/>= $3a: use record 0)  1 ADSR1/GAIN  2 ADSR2
;   3 flags  4 transpose  5 fine  6 flags2  7 vel. sens. / tremolo depth
; =============================================================================
VoiceNoteOn:
0f18: c4 c5     mov    NoteNum,a
0f1a: d8 28     mov    CurVoice,x
0f1c: f5 10 0f  mov    a,VoiceBitMask+x      ; KOF
0f1f: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0f22: c4 f3     mov    DSPDATA,a
0f24: c4 29     mov    VoiceBit,a
0f26: eb 22     mov    y,CurTrack
0f28: f6 c0 02  mov    a,TrkProgram+y        ; program 0 = none
0f2b: d0 02     bne    L0F2F
0f2d: 80        setc
0f2e: 6f        ret

L0F2F:
0f2f: 8f 05 07  mov    $07,#$05              ; record = $0500 + program*8
0f32: 1c        asl    a
0f33: 1c        asl    a
0f34: 1c        asl    a
0f35: c4 06     mov    $06,a
0f37: 98 00 07  adc    $07,#$00
0f3a: 8d 00     mov    y,#$00
0f3c: f7 06     mov    a,($06)+y
0f3e: 10 10     bpl    L0F50                 ; bit7 : drum map
0f40: 68 ff     cmp    a,#$ff                ; $ff : record 0
0f42: f0 10     beq    L0F54
0f44: 3f d1 10  call   DrumMapLookup
0f47: 90 07     bcc    L0F50
0f49: f4 b5     mov    a,VoiceState+x
0f4b: 28 7c     and    a,#$7c
0f4d: d4 b5     mov    VoiceState+x,a
0f4f: 6f        ret

L0F50:
0f50: 68 3a     cmp    a,#$3a                ; sample number >= 58 -> record 0
0f52: 90 08     bcc    L0F5C

L0F54:
0f54: e8 00     mov    a,#$00
0f56: c4 06     mov    $06,a
0f58: e8 05     mov    a,#$05
0f5a: c4 07     mov    $07,a

L0F5C:
0f5c: eb 22     mov    y,CurTrack
0f5e: f6 1a 02  mov    a,TrkStatus+y
0f61: 28 08     and    a,#$08
0f63: 14 b5     or     a,VoiceState+x
0f65: d4 b5     mov    VoiceState+x,a
0f67: 8d 07     mov    y,#$07                ; velocity sensitivity
0f69: f7 06     mov    a,($06)+y
0f6b: bc        inc    a
0f6c: 28 0f     and    a,#$0f
0f6e: f0 08     beq    L0F78
0f70: 9f        xcn    a
0f71: eb c6     mov    y,Velocity
0f73: cf        mul    ya
0f74: dd        mov    a,y
0f75: 5f 7a 0f  jmp    L0F7A

L0F78:
0f78: e4 c6     mov    a,Velocity

L0F7A:
0f7a: d5 10 ff  mov    VVelocityAdj+x,a
0f7d: eb 22     mov    y,CurTrack
0f7f: f6 9c 03  mov    a,TrkVelocity+y       ; TrkVelocity -> VVelScale
0f82: d5 08 ff  mov    VVelScale+x,a
0f85: f6 5c ff  mov    a,TrkVolume+y         ; TrkVolume -> VVolume (bit7 = notify flag removed)
0f88: 28 7f     and    a,#$7f
0f8a: d5 d3 03  mov    VVolume+x,a
0f8d: f6 9e ff  mov    a,TrkPan+y            ; TrkPan -> VPan
0f90: d5 e3 03  mov    VPan+x,a
0f93: 3f b7 17  call   CalcVoiceVolume
0f96: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
0f99: 8f 00 f3  mov    DSPDATA,#$00
0f9c: f5 08 0f  mov    a,VoiceDspBase+x
0f9f: 5d        mov    x,a
0fa0: 8d 03     mov    y,#$03
0fa2: f7 06     mov    a,($06)+y             ; InstFlags
0fa4: c4 ca     mov    InstFlagsTmp,a
0fa6: 3d        inc    x
0fa7: 3d        inc    x
0fa8: 4d        push   x
0fa9: d8 f2     mov    DSPADDR,x
0fab: f8 28     mov    x,CurVoice
0fad: 8d 06     mov    y,#$06
0faf: f7 06     mov    a,($06)+y             ; flags2 -> VInstFlags2 (bits0-1 pitch table, 4-7 tremolo rate)
0fb1: d5 20 ff  mov    VInstFlags2+x,a
0fb4: 33 ca 37  bbc1   InstFlagsTmp,L0FEE    ; InstFlags bit1 : tremolo / auto-pan
0fb7: e8 23     mov    a,#$23
0fb9: d5 0a 02  mov    VTremCount+x,a
0fbc: 8d 07     mov    y,#$07
0fbe: f7 06     mov    a,($06)+y
0fc0: 9f        xcn    a
0fc1: 28 0f     and    a,#$0f
0fc3: d5 12 02  mov    VTremParam+x,a
0fc6: f5 20 ff  mov    a,VInstFlags2+x
0fc9: 9f        xcn    a
0fca: 28 0f     and    a,#$0f
0fcc: 80        setc
0fcd: a8 06     sbc    a,#$06
0fcf: 30 05     bmi    L0FD6
0fd1: e8 0f     mov    a,#$0f
0fd3: 5f d9 0f  jmp    L0FD9

L0FD6:
0fd6: 60        clrc
0fd7: 88 0f     adc    a,#$0f

L0FD9:
0fd9: 9f        xcn    a
0fda: 15 12 02  or     a,VTremParam+x
0fdd: d5 12 02  mov    VTremParam+x,a
0fe0: e8 7f     mov    a,#$7f
0fe2: d5 0b 04  mov    VTremL+x,a
0fe5: d5 13 04  mov    VTremR+x,a
0fe8: f4 bd     mov    a,VTremDir+x
0fea: 28 fe     and    a,#$fe
0fec: d4 bd     mov    VTremDir+x,a

L0FEE:
0fee: 8d 04     mov    y,#$04                ; base note = transpose + note + header transpose
0ff0: f7 06     mov    a,($06)+y
0ff2: 60        clrc
0ff3: 84 c5     adc    a,NoteNum
0ff5: 60        clrc
0ff6: 84 d9     adc    a,HdrTranspose
0ff8: c4 00     mov    BlockEnd,a
0ffa: f8 28     mov    x,CurVoice
0ffc: d5 18 ff  mov    VBaseNote+x,a
0fff: 8d 05     mov    y,#$05                ; fine tune
1001: f7 06     mov    a,($06)+y
1003: d5 28 ff  mov    VFineTune+x,a
1006: eb 22     mov    y,CurTrack            ; TrkKeyOffset -> VKeyOffset
1008: f6 72 ff  mov    a,TrkKeyOffset+y
100b: d5 db 03  mov    VKeyOffset+x,a
100e: 73 ca 24  bbc3   InstFlagsTmp,L1035    ; noise: note -> noise clock
1011: 60        clrc
1012: 84 00     adc    a,BlockEnd
1014: 2d        push   a
1015: 80        setc
1016: a8 18     sbc    a,#$18
1018: 10 02     bpl    L101C
101a: e8 00     mov    a,#$00

L101C:
101c: 68 1f     cmp    a,#$1f
101e: 90 02     bcc    L1022
1020: e8 1f     mov    a,#$1f

L1022:
1022: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
1025: c4 d8     mov    FlgShadow,a
1027: e9 20 04  mov    x,EchoTimer
102a: 30 02     bmi    L102E
102c: 08 20     or     a,#$20

L102E:
102e: c4 f3     mov    DSPDATA,a
1030: ae        pop    a
1031: ce        pop    x
1032: d8 f2     mov    DSPADDR,x
1034: 4d        push   x

L1035:
1035: f8 28     mov    x,CurVoice
1037: 3f 21 18  call   CalcVoicePitch        ; pitch (global table)
103a: ce        pop    x
103b: 3d        inc    x
103c: 3d        inc    x
103d: d8 f2     mov    DSPADDR,x
103f: 8d 00     mov    y,#$00                ; SRCN (bit7 stripped)
1041: f7 06     mov    a,($06)+y
1043: 10 02     bpl    L1047
1045: e8 00     mov    a,#$00

L1047:
1047: 28 7f     and    a,#$7f
1049: c4 f3     mov    DSPDATA,a
104b: 43 ca 13  bbs2   InstFlagsTmp,L1061    ; ADSR (bit2) / GAIN
104e: 3d        inc    x
104f: d8 f2     mov    DSPADDR,x
1051: 8f 00 f3  mov    DSPDATA,#$00
1054: 3d        inc    x
1055: 3d        inc    x
1056: d8 f2     mov    DSPADDR,x
1058: 8d 01     mov    y,#$01
105a: f7 06     mov    a,($06)+y
105c: c4 f3     mov    DSPDATA,a
105e: 5f 75 10  jmp    L1075

L1061:
1061: 3d        inc    x
1062: d8 f2     mov    DSPADDR,x
1064: 8d 01     mov    y,#$01
1066: f7 06     mov    a,($06)+y
1068: 08 80     or     a,#$80
106a: c4 f3     mov    DSPDATA,a
106c: 3d        inc    x
106d: d8 f2     mov    DSPADDR,x
106f: 8d 02     mov    y,#$02
1071: f7 06     mov    a,($06)+y
1073: c4 f3     mov    DSPDATA,a

L1075:
1075: f8 28     mov    x,CurVoice            ; release bits from flags 5/6 (bit4 = one-shot)
1077: f5 40 02  mov    a,VFlags+x
107a: 28 8f     and    a,#$8f
107c: c3 ca 08  bbs6   InstFlagsTmp,L1087
107f: b3 ca 02  bbc5   InstFlagsTmp,L1084
1082: 08 20     or     a,#$20

L1084:
1084: 5f 91 10  jmp    L1091

L1087:
1087: a3 ca 05  bbs5   InstFlagsTmp,L108F
108a: 08 40     or     a,#$40
108c: 5f 91 10  jmp    L1091

L108F:
108f: 08 10     or     a,#$10

L1091:
1091: d5 40 02  mov    VFlags+x,a
1094: f4 b5     mov    a,VoiceState+x
1096: 08 10     or     a,#$10
1098: 83 ca 02  bbs4   InstFlagsTmp,L109D
109b: 48 10     eor    a,#$10

L109D:
109d: 33 ca 02  bbc1   InstFlagsTmp,L10A2
10a0: 08 20     or     a,#$20

L10A2:
10a2: d4 b5     mov    VoiceState+x,a
10a4: 09 29 2b  or     (EonShadow),(VoiceBit) ; EON
10a7: 03 ca 03  bbs0   InstFlagsTmp,L10AD
10aa: 49 29 2b  eor    (EonShadow),(VoiceBit)

L10AD:
10ad: 8f 4d f2  mov    DSPADDR,#$4d          ; EON
10b0: fa 2b f3  mov    (DSPDATA),(EonShadow)
10b3: 8f 2d f2  mov    DSPADDR,#$2d          ; PMON (shadow is always 0)
10b6: fa 2c f3  mov    (DSPDATA),(PmonShadow)
10b9: 09 29 2a  or     (NonShadow),(VoiceBit) ; NON
10bc: 63 ca 03  bbs3   InstFlagsTmp,L10C2
10bf: 49 29 2a  eor    (NonShadow),(VoiceBit)

L10C2:
10c2: 8f 3d f2  mov    DSPADDR,#$3d          ; NON
10c5: fa 2a f3  mov    (DSPDATA),(NonShadow)
10c8: 8f 4c f2  mov    DSPADDR,#$4c          ; KON
10cb: fa 29 f3  mov    (DSPDATA),(VoiceBit)
10ce: f8 28     mov    x,CurVoice
10d0: 6f        ret

; =============================================================================
; DrumMapLookup - global 16-zone map at $06d0 {instrument, key, flags}
;  exact key or key+1 (flags<>0); note becomes 36 + 3..6 by flags bits0-2.
;  Zone 15 (last) also covers key..key+3 with offsets DrumRangeOffsets.
;  (v1.01 replaced this by per-instrument key-split records, base note 60)
; =============================================================================
DrumMapLookup:
10d1: 4d        push   x
10d2: 6d        push   y
10d3: e4 c5     mov    a,NoteNum
10d5: 8f 24 c5  mov    NoteNum,#$24
10d8: cd 00     mov    x,#$00

L10DA:
10da: 75 d1 06  cmp    a,DrumMap+1+x
10dd: f0 1d     beq    L10FC
10df: 9c        dec    a
10e0: 75 d1 06  cmp    a,DrumMap+1+x
10e3: d0 0c     bne    L10F1
10e5: 2d        push   a
10e6: f5 d2 06  mov    a,DrumMap+2+x
10e9: f0 05     beq    L10F0
10eb: ae        pop    a
10ec: bc        inc    a
10ed: 5f fc 10  jmp    L10FC

L10F0:
10f0: ae        pop    a

L10F1:
10f1: bc        inc    a
10f2: 3d        inc    x
10f3: 3d        inc    x
10f4: 3d        inc    x
10f5: c8 30     cmp    x,#$30
10f7: f0 33     beq    L112C
10f9: 5f da 10  jmp    L10DA

L10FC:
10fc: f0 18     beq    L1116
10fe: 60        clrc
10ff: 98 03 c5  adc    NoteNum,#$03
1102: f5 d2 06  mov    a,DrumMap+2+x
1105: 5c        lsr    a
1106: b0 0e     bcs    L1116
1108: ab c5     inc    NoteNum
110a: 5c        lsr    a
110b: b0 09     bcs    L1116
110d: ab c5     inc    NoteNum
110f: 5c        lsr    a
1110: b0 04     bcs    L1116
1112: ab c5     inc    NoteNum
1114: ab c5     inc    NoteNum

L1116:
1116: f5 d0 06  mov    a,DrumMap+x
1119: 1c        asl    a
111a: 1c        asl    a
111b: 1c        asl    a
111c: c4 06     mov    $06,a
111e: e8 05     mov    a,#$05
1120: 88 00     adc    a,#$00
1122: c4 07     mov    $07,a
1124: ee        pop    y
1125: ce        pop    x
1126: 60        clrc
1127: 6f        ret

L1128:
1128: ee        pop    y
1129: ce        pop    x
112a: 80        setc
112b: 6f        ret

L112C:
112c: cd 2a     mov    x,#$2a
112e: 75 d1 06  cmp    a,DrumMap+1+x
1131: 90 1d     bcc    L1150
1133: 80        setc
1134: a8 04     sbc    a,#$04
1136: 75 d1 06  cmp    a,DrumMap+1+x
1139: b0 15     bcs    L1150
113b: 60        clrc
113c: 88 04     adc    a,#$04
113e: 80        setc
113f: b5 d1 06  sbc    a,DrumMap+1+x
1142: 5d        mov    x,a
1143: f5 53 11  mov    a,DrumRangeOffsets+x
1146: 60        clrc
1147: 84 c5     adc    a,NoteNum
1149: c4 c5     mov    NoteNum,a
114b: cd 2a     mov    x,#$2a
114d: 5f 16 11  jmp    L1116

L1150:
1150: 5f 28 11  jmp    L1128

DrumRangeOffsets:
1153: db    $00,$06,$0b,$0e                  ; v1.01 table: 0,6,11,15 / 0,6,9,12,15

; =============================================================================
; QEv_System - $02 = command, $04/$05 = params
;  $01 stop all    $08 stream sample segment    $80+n : SystemSubCommand
; =============================================================================
QEv_System:
1157: 78 08 02  cmp    $02,#$08
115a: d0 04     bne    L1160
115c: 3f b9 12  call   StreamSampleSegment
115f: 6f        ret

L1160:
1160: 78 01 02  cmp    $02,#$01
1163: d0 04     bne    L1169
1165: 3f 75 16  call   StopAllAudio
1168: 6f        ret

L1169:
1169: e4 02     mov    a,$02
116b: 28 80     and    a,#$80
116d: f0 0a     beq    L1179
116f: e4 02     mov    a,$02
1171: 28 7f     and    a,#$7f
1173: c4 02     mov    $02,a
1175: 3f 72 15  call   SystemSubCommand
1178: 6f        ret

L1179:
1179: 6f        ret

; =============================================================================
; StartSound - sound ID $02, key offset $04, handle $05
;  BankTable (8 x {first ID, pointer}); bank = {count, -, word offsets};
;  sound header: word offset of track pointer list, byte n pointers,
;  byte tracks, flags, tempo, echo flag [+12 echo bytes], 7-byte track
;  headers {velocity, pan, program, priority, pointer index, flags, transpose}
; =============================================================================
StartSound:
117a: 8f ab 08  mov    $08,#$ab
117d: 8f 1c 09  mov    $09,#$1c
1180: 8d 15     mov    y,#$15                ; search from the last slot

L1182:
1182: f7 08     mov    a,($08)+y
1184: 64 02     cmp    a,$02
1186: f0 02     beq    L118A
1188: b0 26     bcs    L11B0

L118A:
118a: c4 0a     mov    $0a,a
118c: 6d        push   y
118d: fc        inc    y
118e: f7 08     mov    a,($08)+y
1190: c4 06     mov    $06,a
1192: fc        inc    y
1193: f7 08     mov    a,($08)+y
1195: c4 07     mov    $07,a
1197: 8d 00     mov    y,#$00
1199: f7 06     mov    a,($06)+y
119b: 60        clrc
119c: 84 0a     adc    a,$0a
119e: 64 02     cmp    a,$02
11a0: f0 0d     beq    L11AF
11a2: 90 0b     bcc    L11AF
11a4: ee        pop    y
11a5: e4 02     mov    a,$02
11a7: 80        setc
11a8: a4 0a     sbc    a,$0a
11aa: c4 02     mov    $02,a
11ac: 5f b6 11  jmp    L11B6

L11AF:
11af: ee        pop    y

L11B0:
11b0: dc        dec    y
11b1: dc        dec    y
11b2: dc        dec    y
11b3: 10 cd     bpl    L1182
11b5: 6f        ret

L11B6:
11b6: e4 02     mov    a,$02                 ; header pointer
11b8: bc        inc    a
11b9: 1c        asl    a
11ba: fd        mov    y,a
11bb: f7 06     mov    a,($06)+y
11bd: c4 08     mov    $08,a
11bf: fc        inc    y
11c0: f7 06     mov    a,($06)+y
11c2: c4 09     mov    $09,a
11c4: e4 06     mov    a,$06
11c6: 60        clrc
11c7: 84 08     adc    a,$08
11c9: c4 06     mov    $06,a
11cb: e4 07     mov    a,$07
11cd: 84 09     adc    a,$09
11cf: c4 07     mov    $07,a
11d1: 8d 00     mov    y,#$00                ; copy the track pointers into TrackPtrTable
11d3: f7 06     mov    a,($06)+y
11d5: 60        clrc
11d6: 84 06     adc    a,$06
11d8: c4 08     mov    $08,a
11da: fc        inc    y
11db: f7 06     mov    a,($06)+y
11dd: 84 07     adc    a,$07
11df: c4 09     mov    $09,a
11e1: fc        inc    y
11e2: f7 06     mov    a,($06)+y
11e4: c4 02     mov    $02,a
11e6: fc        inc    y
11e7: 6d        push   y
11e8: 8d 00     mov    y,#$00

L11EA:
11ea: f7 08     mov    a,($08)+y
11ec: 60        clrc
11ed: 84 06     adc    a,$06
11ef: d6 9a 0d  mov    TrackPtrTable+y,a
11f2: fc        inc    y
11f3: f7 08     mov    a,($08)+y
11f5: 84 07     adc    a,$07
11f7: d6 9a 0d  mov    TrackPtrTable+y,a
11fa: fc        inc    y
11fb: 8b 02     dec    $02
11fd: d0 eb     bne    L11EA
11ff: 60        clrc                         ; pattern base = after the pointer list
1200: dd        mov    a,y
1201: 84 08     adc    a,$08
1203: c5 27 04  mov    PatBaseTmp,a
1206: e8 00     mov    a,#$00
1208: 84 09     adc    a,$09
120a: c5 28 04  mov    PatBaseTmp+1,a
120d: ee        pop    y
120e: f7 06     mov    a,($06)+y             ; number of tracks
1210: fc        inc    y
1211: 5d        mov    x,a
1212: f7 06     mov    a,($06)+y             ; sound flags
1214: c4 26     mov    HdrTrkFlags,a
1216: c4 25     mov    HdrFlags,a
1218: fc        inc    y
1219: f7 06     mov    a,($06)+y             ; tempo
121b: c4 23     mov    CurTempo,a
121d: e8 40     mov    a,#$40                ; restart timer 0 (T0DIV write)
121f: c4 fa     mov    T0DIV,a
1221: fc        inc    y
1222: f7 06     mov    a,($06)+y             ; echo block?
1224: f0 19     beq    L123F
1226: fc        inc    y
1227: 6d        push   y
1228: dd        mov    a,y
1229: 60        clrc
122a: 84 06     adc    a,$06
122c: c4 00     mov    BlockEnd,a
122e: e8 00     mov    a,#$00
1230: 84 07     adc    a,$07
1232: c4 01     mov    BlockEnd+1,a
1234: 3f 74 19  call   SetEchoParams
1237: ae        pop    a
1238: 60        clrc
1239: 88 0c     adc    a,#$0c
123b: fd        mov    y,a
123c: 5f 40 12  jmp    L1240

L123F:
123f: fc        inc    y

L1240:
1240: e8 01     mov    a,#$01
1242: c5 49 04  mov    TrkNumTmp,a
.trackLoop:
1245: f7 06     mov    a,($06)+y
1247: c4 c6     mov    Velocity,a
1249: fc        inc    y
124a: e5 c8 03  mov    a,StartPan
124d: 10 07     bpl    L1256
124f: f7 06     mov    a,($06)+y
1251: 08 80     or     a,#$80
1253: c5 c8 03  mov    StartPan,a

L1256:
1256: fc        inc    y
1257: f7 06     mov    a,($06)+y
1259: c4 08     mov    $08,a
125b: fc        inc    y
125c: f7 06     mov    a,($06)+y
125e: 28 3f     and    a,#$3f
1260: c4 09     mov    $09,a
1262: fc        inc    y
1263: f7 06     mov    a,($06)+y
1265: fc        inc    y
1266: c4 0a     mov    $0a,a
1268: fa 25 26  mov    (HdrTrkFlags),(HdrFlags)
126b: f7 06     mov    a,($06)+y
126d: fc        inc    y
126e: 04 26     or     a,HdrTrkFlags
1270: c4 26     mov    HdrTrkFlags,a
1272: f7 06     mov    a,($06)+y
1274: fc        inc    y
1275: c4 d9     mov    HdrTranspose,a
1277: e4 0a     mov    a,$0a
1279: 4d        push   x
127a: 6d        push   y
127b: f8 08     mov    x,$08
127d: eb 09     mov    y,$09
127f: e4 0a     mov    a,$0a
1281: 3f ba 0d  call   AllocTrack
1284: ac 49 04  inc    TrkNumTmp
1287: ee        pop    y
1288: ce        pop    x
1289: 1d        dec    x
128a: f0 03     beq    L128F
128c: 5f 45 12  jmp    .trackLoop

L128F:
128f: 3f 4d 0a  call   NullSub
1292: 6f        ret

FindNextTrackByID:
1293: f8 22     mov    x,CurTrack
1295: c8 16     cmp    x,#$16
1297: 90 02     bcc    L129B
1299: 80        setc
129a: 6f        ret

L129B:
129b: ab 22     inc    CurTrack
129d: f5 1a 02  mov    a,TrkStatus+x
12a0: 28 80     and    a,#$80
12a2: f0 0c     beq    L12B0
12a4: 78 ff 04  cmp    $04,#$ff
12a7: f0 0e     beq    L12B7
12a9: f5 aa 02  mov    a,TrkSoundID+x
12ac: 64 04     cmp    a,$04
12ae: f0 07     beq    L12B7

L12B0:
12b0: 3d        inc    x
12b1: c8 16     cmp    x,#$16
12b3: 90 e6     bcc    L129B
12b5: 80        setc
12b6: 6f        ret

L12B7:
12b7: 60        clrc
12b8: 6f        ret

; =============================================================================
; System $08 - advance a streamed sample: DIR[p1] start += IoWord1,
;  loop += IoWord2; the previous block loses its END/LOOP flags and the
;  block at the new loop address gets END (+LOOP unless IoWord1 bit15).
;  (not present in v1.01)
; =============================================================================
StreamSampleSegment:
12b9: e4 d4     mov    a,IoWord3
12bb: 1c        asl    a
12bc: 1c        asl    a
12bd: fd        mov    y,a
12be: f7 15     mov    a,(DirPtr)+y
12c0: c4 06     mov    $06,a
12c2: c4 08     mov    $08,a
12c4: fc        inc    y
12c5: f7 15     mov    a,(DirPtr)+y
12c7: c4 07     mov    $07,a
12c9: c4 09     mov    $09,a
12cb: fc        inc    y
12cc: f7 15     mov    a,(DirPtr)+y
12ce: c4 0a     mov    $0a,a
12d0: fc        inc    y
12d1: f7 15     mov    a,(DirPtr)+y
12d3: c4 0b     mov    $0b,a
12d5: dc        dec    y
12d6: 6d        push   y
12d7: ba d0     movw   ya,IoWord1
12d9: 7a 06     addw   ya,$06
12db: da 06     movw   $06,ya
12dd: ba d2     movw   ya,IoWord2
12df: 7a 08     addw   ya,$08
12e1: da 08     movw   $08,ya
12e3: ee        pop    y
12e4: e4 06     mov    a,$06
12e6: d7 15     mov    (DirPtr)+y,a
12e8: e4 07     mov    a,$07
12ea: fc        inc    y
12eb: d7 15     mov    (DirPtr)+y,a
12ed: e4 cd     mov    a,StreamPrev+1
12ef: 30 08     bmi    L12F9
12f1: 8d 00     mov    y,#$00
12f3: f7 cc     mov    a,(StreamPrev)+y
12f5: 28 fc     and    a,#$fc
12f7: d7 cc     mov    (StreamPrev)+y,a

L12F9:
12f9: e4 d1     mov    a,IoWord1+1
12fb: 10 0a     bpl    L1307
12fd: f7 08     mov    a,($08)+y
12ff: 08 01     or     a,#$01
1301: 8f ff cd  mov    StreamPrev+1,#$ff
1304: 5f 11 13  jmp    L1311

L1307:
1307: f7 08     mov    a,($08)+y
1309: 08 03     or     a,#$03
130b: fa 08 cc  mov    (StreamPrev),($08)
130e: fa 09 cd  mov    (StreamPrev+1),($09)

L1311:
1311: d7 08     mov    ($08)+y,a
1313: 6f        ret

; -----------------------------------------------------------------------------
; Global pitch tables (v1.01 uses a table stored in front of each sample).
; Table 0: 108 words (9 octaves from $0040); tables 1 and 2: 96 words.
; Selected by instrument flags2 bits0-1 through PitchTableSet.
; -----------------------------------------------------------------------------
PitchTable0:
1314: dw    $0040,$0043,$0047,$004c,$0050,$0055,$005a,$005f,$0065,$006b,$0072,$0078
132c: dw    $0080,$0087,$008f,$0098,$00a1,$00aa,$00b5,$00bf,$00cb,$00d7,$00e4,$00f1
1344: dw    $0100,$010f,$011f,$0130,$0142,$0155,$016a,$017f,$0196,$01ae,$01c8,$01e3
135c: dw    $0200,$021e,$023e,$0260,$0285,$02ab,$02d4,$02ff,$032c,$035d,$0390,$03c6
1374: dw    $0400,$043c,$047d,$04c1,$050a,$0556,$05a8,$05fe,$0659,$06ba,$0720,$078d
138c: dw    $0800,$0879,$08fa,$0983,$0a14,$0aad,$0b50,$0bfc,$0cb3,$0d74,$0e41,$0f1a
13a4: dw    $1000,$10f3,$11f5,$1307,$1428,$155b,$16a0,$17f9,$1966,$1ae8,$1c82,$1e34
13bc: dw    $2000,$21e7,$23eb,$260e,$280a,$2ab7,$2d41,$2ff2,$32cc,$35d1,$3904,$3c68
13d4: dw    $4000,$43ce,$47d6,$4c1c,$50a2,$556e,$5a82,$5fe4,$6598,$6ba2,$7208,$78d0

PitchTable1:
13ec: dw    $0058,$005d,$0063,$0068,$006f,$0075,$007c,$0084,$008c,$0094,$009d,$00a6
1404: dw    $00b0,$00ba,$00c6,$00d1,$00de,$00eb,$00f9,$0108,$0118,$0128,$013a,$014c
141c: dw    $0160,$0175,$018c,$01a3,$01bc,$01d6,$01f2,$0210,$0230,$0251,$0274,$0299
1434: dw    $02c1,$02eb,$0318,$0347,$0378,$03ad,$03e5,$0421,$0460,$04a2,$04e9,$0533
144c: dw    $0583,$05d7,$0630,$068e,$06f1,$075b,$07cb,$0842,$08c0,$0945,$09d2,$0a67
1464: dw    $0b06,$0bae,$0c60,$0d1c,$0de3,$0eb7,$0f97,$1084,$1180,$128a,$13a4,$14cf
147c: dw    $160c,$175c,$18c0,$1a38,$1bc7,$1d6f,$1f2e,$2109,$2300,$2515,$2749,$299f
1494: dw    $2c19,$2eb9,$3180,$3471,$378f,$3ade,$3e5d,$4213,$4601,$4a2a,$4e93,$533f

PitchTable2:
14ac: dw    $0042,$0046,$004b,$004f,$0054,$0059,$005e,$0064,$006a,$0070,$0077,$007e
14c4: dw    $0085,$008d,$0096,$009f,$00a8,$00b2,$00bd,$00c8,$00d4,$00e1,$00ee,$00fc
14dc: dw    $010b,$011b,$012c,$013e,$0151,$0165,$017a,$0191,$01a9,$01c2,$01dd,$01f9
14f4: dw    $0217,$0237,$0259,$027d,$02a3,$02cb,$02f5,$0322,$0352,$0385,$03ba,$03f3
150c: dw    $042f,$046f,$04b2,$04fa,$0546,$0596,$05eb,$0645,$06a5,$070a,$0775,$07e6
1524: dw    $085f,$08de,$0965,$09f4,$0a8c,$0b2c,$0bd6,$0c8b,$0d4a,$0e14,$0eea,$0fcd
153c: dw    $10be,$11bd,$12cb,$13e9,$1518,$1659,$17ad,$1916,$1a94,$1c28,$1dd5,$1f9b
1554: dw    $217c,$237a,$2596,$27d3,$29e7,$2cb3,$2f5b,$322c,$3528,$3851,$3bab,$3f37

; PitchTableSet - 3 pointers.  Index 3 would read "$ff8f" from the code
; that follows (bytes 8f ff of $1572) - flags2 bits0-1 = 3 is invalid.
PitchTableSet:
156c: dw    $1314,$13ec,$14ac                ; PitchTable0, PitchTable1, PitchTable2

; =============================================================================
; SystemSubCommand - A = cmd & $7f, $04 = sound ID, $05 = value
;  $01 fade out   $02 stop   $10 tempo ofs   $11 key offset   $12 nop
;  $13/$14 stop request (+chain)  $16 volume  $17 pan  $20 stereo  $22 mute
; =============================================================================
SystemSubCommand:
1572: 8f ff 09  mov    $09,#$ff
1575: 68 01     cmp    a,#$01
1577: d0 2d     bne    L15A6
1579: 8f 00 22  mov    CurTrack,#$00         ; $01: set fade bit on the sound's tracks ...

L157C:
157c: 3f 93 12  call   FindNextTrackByID
157f: b0 0b     bcs    L158C
1581: f5 1a 02  mov    a,TrkStatus+x
1584: 08 08     or     a,#$08
1586: d5 1a 02  mov    TrkStatus+x,a
1589: 5f 7c 15  jmp    L157C

L158C:
158c: 8d 07     mov    y,#$07                ; ... and on its voices

L158E:
158e: 78 ff 04  cmp    $04,#$ff
1591: f0 07     beq    L159A
1593: f6 85 00  mov    a,VSoundID+y
1596: 64 04     cmp    a,$04
1598: d0 08     bne    L15A2

L159A:
159a: f6 b5 00  mov    a,VoiceState+y
159d: 08 08     or     a,#$08
159f: d6 b5 00  mov    VoiceState+y,a

L15A2:
15a2: dc        dec    y
15a3: 10 e9     bpl    L158E
15a5: 6f        ret

L15A6:
15a6: 68 02     cmp    a,#$02
15a8: d0 04     bne    L15AE
15aa: 3f a0 18  call   StopSound
15ad: 6f        ret

L15AE:
15ae: 68 11     cmp    a,#$11
15b0: d0 06     bne    L15B8
15b2: 8f 80 08  mov    $08,#$80
15b5: 5f ed 16  jmp    ApplyParamToSound

L15B8:
15b8: 68 12     cmp    a,#$12
15ba: d0 01     bne    L15BD
15bc: 6f        ret

L15BD:
15bd: 68 10     cmp    a,#$10
15bf: d0 06     bne    L15C7
15c1: 8f ff 08  mov    $08,#$ff
15c4: 5f ed 16  jmp    ApplyParamToSound

L15C7:
15c7: 68 13     cmp    a,#$13
15c9: d0 06     bne    L15D1
15cb: 8f 04 0a  mov    $0a,#$04
15ce: 5f d8 15  jmp    L15D8

L15D1:
15d1: 68 14     cmp    a,#$14
15d3: d0 3b     bne    L1610
15d5: 8f 02 0a  mov    $0a,#$02

L15D8:
15d8: 78 ff 05  cmp    $05,#$ff
15db: f0 03     beq    L15E0
15dd: 18 10 0a  or     $0a,#$10

L15E0:
15e0: 8f 00 22  mov    CurTrack,#$00

L15E3:
15e3: 3f 93 12  call   FindNextTrackByID
15e6: b0 0b     bcs    L15F3
15e8: f5 1a 02  mov    a,TrkStatus+x
15eb: 04 0a     or     a,$0a
15ed: d5 1a 02  mov    TrkStatus+x,a
15f0: 5f e3 15  jmp    L15E3

L15F3:
15f3: aa 0a 80  mov1   c,$000a,4
15f6: 90 17     bcc    L160F
15f8: 8d 06     mov    y,#$06

L15FA:
15fa: f6 cb 03  mov    a,ChainList+y
15fd: 68 ff     cmp    a,#$ff
15ff: f0 04     beq    L1605
1601: dc        dec    y
1602: dc        dec    y
1603: 10 f5     bpl    L15FA

L1605:
1605: e4 04     mov    a,$04
1607: d6 cb 03  mov    ChainList+y,a
160a: e4 05     mov    a,$05
160c: d6 cc 03  mov    ChainList+1+y,a

L160F:
160f: 6f        ret

L1610:
1610: 68 16     cmp    a,#$16
1612: d0 06     bne    L161A
1614: 8f 00 08  mov    $08,#$00
1617: 5f ed 16  jmp    ApplyParamToSound

L161A:
161a: 68 17     cmp    a,#$17
161c: d0 06     bne    L1624
161e: 8f 01 08  mov    $08,#$01
1621: 5f ed 16  jmp    ApplyParamToSound

L1624:
1624: 68 20     cmp    a,#$20
1626: d0 04     bne    L162C
1628: fa 04 14  mov    (StereoMode),($04)
162b: 6f        ret

L162C:
162c: 68 22     cmp    a,#$22
162e: d0 44     bne    L1674
1630: e4 05     mov    a,$05
1632: 28 f0     and    a,#$f0
1634: 48 10     eor    a,#$10
1636: f0 02     beq    L163A
1638: e8 01     mov    a,#$01

L163A:
163a: c4 09     mov    $09,a
163c: e4 05     mov    a,$05
163e: 28 0f     and    a,#$0f
1640: c4 05     mov    $05,a
1642: 78 ff 04  cmp    $04,#$ff
1645: f0 2c     beq    L1673
1647: 8f 00 22  mov    CurTrack,#$00

L164A:
164a: 3f 93 12  call   FindNextTrackByID
164d: b0 14     bcs    L1663
164f: f5 44 03  mov    a,TrkNumber+x
1652: 64 05     cmp    a,$05
1654: d0 0a     bne    L1660
1656: f5 1a 02  mov    a,TrkStatus+x
1659: 28 fe     and    a,#$fe
165b: 04 09     or     a,$09
165d: d5 1a 02  mov    TrkStatus+x,a

L1660:
1660: 5f 4a 16  jmp    L164A

L1663:
1663: e4 09     mov    a,$09
1665: f0 0c     beq    L1673
1667: fa 05 09  mov    ($09),($05)
166a: 8f 00 08  mov    $08,#$00
166d: 8f 00 05  mov    $05,#$00
1670: 3f 46 17  call   ApplyParamToVoices

L1673:
1673: 6f        ret

L1674:
1674: 6f        ret

StopAllAudio:
1675: e8 00     mov    a,#$00
1677: c4 1f     mov    TicksElapsed,a
1679: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
167c: 8f ff f3  mov    DSPDATA,#$ff
167f: cd 00     mov    x,#$00

L1681:
1681: e8 00     mov    a,#$00
1683: d4 b5     mov    VoiceState+x,a
1685: 3d        inc    x
1686: c8 08     cmp    x,#$08
1688: d0 f7     bne    L1681
168a: cd 00     mov    x,#$00
168c: e8 00     mov    a,#$00

L168E:
168e: d5 1a 02  mov    TrkStatus+x,a
1691: 3d        inc    x
1692: c8 16     cmp    x,#$16
1694: d0 f8     bne    L168E
1696: e8 00     mov    a,#$00
1698: 3f f6 19  call   SetEchoDelay
169b: e8 00     mov    a,#$00
169d: 3f ab 19  call   SetEchoVolL
16a0: e8 00     mov    a,#$00
16a2: 3f c4 19  call   SetEchoVolR
16a5: 6f        ret

; ProcessFades - bit3: TrkVolume / VVolume -1 per tick until 0 (fade out)
ProcessFades:
16a6: cd 15     mov    x,#$15

L16A8:
16a8: f5 1a 02  mov    a,TrkStatus+x
16ab: 28 80     and    a,#$80
16ad: f0 16     beq    L16C5
16af: f5 1a 02  mov    a,TrkStatus+x
16b2: 28 08     and    a,#$08
16b4: f0 0f     beq    L16C5
16b6: f5 5c ff  mov    a,TrkVolume+x
16b9: d0 06     bne    L16C1
16bb: d5 1a 02  mov    TrkStatus+x,a
16be: 5f c5 16  jmp    L16C5

L16C1:
16c1: 9c        dec    a
16c2: d5 5c ff  mov    TrkVolume+x,a

L16C5:
16c5: 1d        dec    x
16c6: 10 e0     bpl    L16A8
16c8: cd 07     mov    x,#$07

L16CA:
16ca: f4 b5     mov    a,VoiceState+x
16cc: 28 80     and    a,#$80
16ce: f0 19     beq    L16E9
16d0: f4 b5     mov    a,VoiceState+x
16d2: 28 08     and    a,#$08
16d4: f0 13     beq    L16E9
16d6: f5 d3 03  mov    a,VVolume+x
16d9: d0 05     bne    L16E0
16db: d4 b5     mov    VoiceState+x,a
16dd: 5f e9 16  jmp    L16E9

L16E0:
16e0: 4d        push   x
16e1: 9c        dec    a
16e2: d5 d3 03  mov    VVolume+x,a
16e5: 3f b7 17  call   CalcVoiceVolume
16e8: ce        pop    x

L16E9:
16e9: 1d        dec    x
16ea: 10 de     bpl    L16CA
16ec: 6f        ret

; =============================================================================
; ApplyParamToSound - $04 sound ID ($ff all), $09 track number ($ff all),
;  $08 = parameter: 0 volume, 1 pan, $ff tempo offset, $fe velocity,
;  other negative: key offset (voices: $fd = bend from $0c/$0d).
;  If-chains instead of v1.01's two jump tables.
; =============================================================================
ApplyParamToSound:
16ed: cd 15     mov    x,#$15
16ef: eb 05     mov    y,$05

L16F1:
16f1: e4 04     mov    a,$04
16f3: 68 ff     cmp    a,#$ff
16f5: f0 10     beq    L1707
16f7: 75 aa 02  cmp    a,TrkSoundID+x
16fa: d0 47     bne    L1743
16fc: e4 09     mov    a,$09
16fe: 68 ff     cmp    a,#$ff
1700: f0 05     beq    L1707
1702: 75 44 03  cmp    a,TrkNumber+x
1705: d0 3c     bne    L1743

L1707:
1707: e4 08     mov    a,$08
1709: d0 08     bne    L1713
170b: e4 05     mov    a,$05
170d: d5 5c ff  mov    TrkVolume+x,a
1710: 5f 43 17  jmp    L1743

L1713:
1713: 30 08     bmi    L171D
1715: e4 05     mov    a,$05
1717: d5 9e ff  mov    TrkPan+x,a
171a: 5f 43 17  jmp    L1743

L171D:
171d: bc        inc    a
171e: d0 14     bne    L1734
1720: f5 86 03  mov    a,TrkTempo+x
1723: 80        setc
1724: b5 88 ff  sbc    a,TrkTempoOfs+x
1727: 60        clrc
1728: 84 05     adc    a,$05
172a: d5 86 03  mov    TrkTempo+x,a
172d: dd        mov    a,y
172e: d5 88 ff  mov    TrkTempoOfs+x,a
1731: 5f 43 17  jmp    L1743

L1734:
1734: bc        inc    a
1735: d0 08     bne    L173F
1737: e4 05     mov    a,$05
1739: d5 9c 03  mov    TrkVelocity+x,a
173c: 5f 43 17  jmp    L1743

L173F:
173f: dd        mov    a,y
1740: d5 72 ff  mov    TrkKeyOffset+x,a

L1743:
1743: 1d        dec    x
1744: 10 ab     bpl    L16F1

ApplyParamToVoices:
1746: cd 07     mov    x,#$07

L1748:
1748: e4 04     mov    a,$04
174a: 68 ff     cmp    a,#$ff
174c: f0 0f     beq    L175D
174e: 74 85     cmp    a,VSoundID+x
1750: d0 54     bne    L17A6
1752: e4 09     mov    a,$09
1754: 68 ff     cmp    a,#$ff
1756: f0 05     beq    L175D
1758: 75 48 02  cmp    a,VTrkNumber+x
175b: d0 49     bne    L17A6

L175D:
175d: f4 b5     mov    a,VoiceState+x
175f: 28 80     and    a,#$80
1761: f0 43     beq    L17A6
1763: 4d        push   x
1764: e4 08     mov    a,$08
1766: d0 06     bne    L176E
1768: 3f aa 17  call   VP_Volume
176b: 5f a5 17  jmp    L17A5

L176E:
176e: 30 06     bmi    L1776
1770: 3f b2 17  call   VP_Pan
1773: 5f a5 17  jmp    L17A5

L1776:
1776: bc        inc    a
1777: d0 03     bne    L177C
1779: 5f a5 17  jmp    L17A5

L177C:
177c: bc        inc    a
177d: d0 0b     bne    L178A
177f: e4 05     mov    a,$05
1781: d5 08 ff  mov    VVelScale+x,a
1784: 3f b7 17  call   CalcVoiceVolume
1787: 5f a5 17  jmp    L17A5

L178A:
178a: bc        inc    a
178b: d0 10     bne    L179D
178d: e4 0d     mov    a,$0d
178f: d5 f3 03  mov    VBendHi+x,a
1792: e4 0c     mov    a,$0c
1794: d5 eb 03  mov    VBendLo+x,a
1797: 3f 21 18  call   CalcVoicePitch
179a: 5f a5 17  jmp    L17A5

L179D:
179d: e4 05     mov    a,$05
179f: d5 db 03  mov    VKeyOffset+x,a
17a2: 3f 21 18  call   CalcVoicePitch

L17A5:
17a5: ce        pop    x

L17A6:
17a6: 1d        dec    x
17a7: 10 9f     bpl    L1748
17a9: 6f        ret

VP_Volume:
17aa: e4 05     mov    a,$05
17ac: d5 d3 03  mov    VVolume+x,a
17af: 5f b7 17  jmp    CalcVoiceVolume

VP_Pan:
17b2: e4 05     mov    a,$05
17b4: d5 e3 03  mov    VPan+x,a

; =============================================================================
; CalcVoiceVolume - vol = VVelocityAdj*f(VVelScale)*f(VVolume); pan $40 =
; centre, pan < $40 attenuates R, > $40 attenuates L (no master volume,
; no channel volume, no surround).
; =============================================================================
CalcVoiceVolume:
17b7: 4d        push   x
17b8: f5 10 ff  mov    a,VVelocityAdj+x
17bb: fd        mov    y,a
17bc: f5 08 ff  mov    a,VVelScale+x
17bf: d0 04     bne    L17C5
17c1: fd        mov    y,a
17c2: 5f cb 17  jmp    L17CB

L17C5:
17c5: 80        setc
17c6: 3c        rol    a
17c7: bc        inc    a
17c8: f0 01     beq    L17CB
17ca: cf        mul    ya

L17CB:
17cb: f5 d3 03  mov    a,VVolume+x
17ce: d0 04     bne    L17D4
17d0: fd        mov    y,a
17d1: 5f da 17  jmp    L17DA

L17D4:
17d4: 80        setc
17d5: 3c        rol    a
17d6: bc        inc    a
17d7: f0 01     beq    L17DA
17d9: cf        mul    ya

L17DA:
17da: cb c7     mov    VolTmpL,y
17dc: cb c8     mov    VolTmpR,y
17de: f5 e3 03  mov    a,VPan+x
17e1: 68 40     cmp    a,#$40
17e3: f0 14     beq    L17F9
17e5: 1c        asl    a
17e6: 1c        asl    a
17e7: b0 08     bcs    L17F1
17e9: eb c8     mov    y,VolTmpR
17eb: cf        mul    ya
17ec: cb c8     mov    VolTmpR,y
17ee: 5f f9 17  jmp    L17F9

L17F1:
17f1: 48 ff     eor    a,#$ff
17f3: bc        inc    a
17f4: eb c7     mov    y,VolTmpL
17f6: cf        mul    ya
17f7: cb c7     mov    VolTmpL,y

L17F9:
17f9: 78 00 14  cmp    StereoMode,#$00
17fc: d0 0a     bne    L1808
17fe: e4 c8     mov    a,VolTmpR
1800: 60        clrc
1801: 84 c7     adc    a,VolTmpL
1803: 7c        ror    a
1804: c4 c8     mov    VolTmpR,a
1806: c4 c7     mov    VolTmpL,a

L1808:
1808: ce        pop    x
1809: f5 08 0f  mov    a,VoiceDspBase+x
180c: fd        mov    y,a
180d: cb f2     mov    DSPADDR,y
180f: e4 c7     mov    a,VolTmpL
1811: d5 fb 03  mov    VVolL+x,a
1814: c4 f3     mov    DSPDATA,a
1816: fc        inc    y
1817: cb f2     mov    DSPADDR,y
1819: e4 c8     mov    a,VolTmpR
181b: d5 03 04  mov    VVolR+x,a
181e: c4 f3     mov    DSPDATA,a
1820: 6f        ret

; =============================================================================
; CalcVoicePitch - index = (base note + key offset + bend) * 2 into the global
; table selected by flags2 bits0-1, linear interpolation by fine+bend lo.
; =============================================================================
CalcVoicePitch:
1821: 7d        mov    a,x
1822: fd        mov    y,a
1823: f5 08 0f  mov    a,VoiceDspBase+x
1826: 5d        mov    x,a
1827: 3d        inc    x
1828: 3d        inc    x
1829: 4d        push   x
182a: d8 f2     mov    DSPADDR,x
182c: f6 28 ff  mov    a,VFineTune+y
182f: 60        clrc
1830: 96 eb 03  adc    a,VBendLo+y
1833: c4 00     mov    BlockEnd,a
1835: f6 db 03  mov    a,VKeyOffset+y
1838: 96 18 ff  adc    a,VBaseNote+y
183b: 96 f3 03  adc    a,VBendHi+y
183e: 1c        asl    a
183f: 2d        push   a
1840: f6 20 ff  mov    a,VInstFlags2+y
1843: 28 03     and    a,#$03
1845: 1c        asl    a
1846: fd        mov    y,a
1847: f6 6c 15  mov    a,PitchTableSet+y
184a: c4 0e     mov    $0e,a
184c: f6 6d 15  mov    a,PitchTableSet+1+y
184f: c4 0f     mov    $0f,a
1851: ee        pop    y
1852: f7 0e     mov    a,($0e)+y
1854: fc        inc    y
1855: c4 10     mov    $10,a
1857: f7 0e     mov    a,($0e)+y
1859: fc        inc    y
185a: c4 11     mov    $11,a
185c: f7 0e     mov    a,($0e)+y
185e: fc        inc    y
185f: c4 12     mov    $12,a
1861: f7 0e     mov    a,($0e)+y
1863: c4 13     mov    $13,a
1865: e4 00     mov    a,BlockEnd
1867: d0 09     bne    L1872
1869: e4 10     mov    a,$10
186b: c4 f3     mov    DSPDATA,a
186d: e4 11     mov    a,$11
186f: 5f 99 18  jmp    L1899

L1872:
1872: ba 12     movw   ya,$12
1874: 9a 10     subw   ya,$10
1876: da 0e     movw   $0e,ya
1878: eb 00     mov    y,BlockEnd
187a: cf        mul    ya
187b: cb 0e     mov    $0e,y
187d: e4 0f     mov    a,$0f
187f: eb 00     mov    y,BlockEnd
1881: cf        mul    ya
1882: cb 0f     mov    $0f,y
1884: 60        clrc
1885: 84 0e     adc    a,$0e
1887: c4 0e     mov    $0e,a
1889: dd        mov    a,y
188a: 84 0f     adc    a,$0f
188c: c4 0f     mov    $0f,a
188e: e4 0e     mov    a,$0e
1890: 60        clrc
1891: 84 10     adc    a,$10
1893: c4 f3     mov    DSPDATA,a
1895: e4 0f     mov    a,$0f
1897: 84 11     adc    a,$11

L1899:
1899: ce        pop    x
189a: 3d        inc    x
189b: d8 f2     mov    DSPADDR,x
189d: c4 f3     mov    DSPDATA,a
189f: 6f        ret

StopSound:
18a0: 78 ff 04  cmp    $04,#$ff
18a3: d0 06     bne    L18AB
18a5: 3f 75 16  call   StopAllAudio
18a8: 5f e1 18  jmp    L18E1

L18AB:
18ab: 8f 00 22  mov    CurTrack,#$00

L18AE:
18ae: 3f 93 12  call   FindNextTrackByID
18b1: b0 08     bcs    L18BB
18b3: e8 00     mov    a,#$00
18b5: d5 1a 02  mov    TrkStatus+x,a
18b8: 5f ae 18  jmp    L18AE

L18BB:
18bb: 8f 00 0a  mov    $0a,#$00
18be: 8d 07     mov    y,#$07

L18C0:
18c0: f6 85 00  mov    a,VSoundID+y
18c3: 64 04     cmp    a,$04
18c5: d0 11     bne    L18D8
18c7: f6 b5 00  mov    a,VoiceState+y
18ca: 10 0c     bpl    L18D8
18cc: f6 10 0f  mov    a,VoiceBitMask+y
18cf: 04 0a     or     a,$0a
18d1: c4 0a     mov    $0a,a
18d3: e8 00     mov    a,#$00
18d5: d6 b5 00  mov    VoiceState+y,a

L18D8:
18d8: dc        dec    y
18d9: 10 e5     bpl    L18C0
18db: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
18de: fa 0a f3  mov    (DSPDATA),($0a)

L18E1:
18e1: 6f        ret

; TremoloUpdate - "auto-pan"/tremolo: moves VTremL/VTremR in opposite
; directions and rescales VOL L/R (no pitch vibrato in this version)
TremoloUpdate:
18e2: f5 0a 02  mov    a,VTremCount+x
18e5: 9c        dec    a
18e6: f0 04     beq    L18EC
18e8: d5 0a 02  mov    VTremCount+x,a
18eb: 6f        ret

L18EC:
18ec: f5 20 ff  mov    a,VInstFlags2+x
18ef: 9f        xcn    a
18f0: 28 0f     and    a,#$0f
18f2: 80        setc
18f3: a8 06     sbc    a,#$06
18f5: 30 0a     bmi    L1901
18f7: 8f 00 06  mov    $06,#$00
18fa: bc        inc    a
18fb: d5 0a 02  mov    VTremCount+x,a
18fe: 5f 08 19  jmp    L1908

L1901:
1901: c4 06     mov    $06,a
1903: e8 01     mov    a,#$01
1905: d5 0a 02  mov    VTremCount+x,a

L1908:
1908: f4 bd     mov    a,VTremDir+x
190a: c4 02     mov    $02,a
190c: f5 12 02  mov    a,VTremParam+x
190f: c4 03     mov    $03,a
1911: 28 0f     and    a,#$0f
1913: c4 05     mov    $05,a
1915: 03 02 03  bbs0   $02,L191B
1918: 48 ff     eor    a,#$ff
191a: bc        inc    a

L191B:
191b: c4 04     mov    $04,a
191d: 60        clrc
191e: 95 0b 04  adc    a,VTremL+x
1921: d5 0b 04  mov    VTremL+x,a
1924: fd        mov    y,a
1925: f5 fb 03  mov    a,VVolL+x
1928: 80        setc
1929: 3c        rol    a
192a: cf        mul    ya
192b: cb 08     mov    $08,y
192d: e4 04     mov    a,$04
192f: 60        clrc
1930: 95 13 04  adc    a,VTremR+x
1933: d5 13 04  mov    VTremR+x,a
1936: fd        mov    y,a
1937: f5 03 04  mov    a,VVolR+x
193a: 80        setc
193b: 3c        rol    a
193c: cf        mul    ya
193d: cb 09     mov    $09,y
193f: f5 08 0f  mov    a,VoiceDspBase+x
1942: fd        mov    y,a
1943: cb f2     mov    DSPADDR,y
1945: fa 08 f3  mov    (DSPDATA),($08)
1948: fc        inc    y
1949: cb f2     mov    DSPADDR,y
194b: fa 09 f3  mov    (DSPDATA),($09)
194e: e4 03     mov    a,$03
1950: 9f        xcn    a
1951: 28 0f     and    a,#$0f
1953: 9c        dec    a
1954: 10 0b     bpl    L1961
1956: e4 02     mov    a,$02
1958: 48 01     eor    a,#$01
195a: d4 bd     mov    VTremDir+x,a
195c: e8 0f     mov    a,#$0f
195e: 60        clrc
195f: 84 06     adc    a,$06

L1961:
1961: 9f        xcn    a
1962: 04 05     or     a,$05
1964: d5 12 02  mov    VTremParam+x,a
1967: 6f        ret

EchoDefaults:
1968: db    $00,$00,$00,$00,$7f,$00,$00,$00,$00,$00,$00,$00 ; EDL EVOLL EVOLR EFB FIR0..7

SetEchoParams:
1974: 6d        push   y
1975: 8d 00     mov    y,#$00
1977: f7 00     mov    a,(BlockEnd)+y
1979: 3f f6 19  call   SetEchoDelay
197c: fc        inc    y
197d: f7 00     mov    a,(BlockEnd)+y
197f: 3f ab 19  call   SetEchoVolL
1982: fc        inc    y
1983: f7 00     mov    a,(BlockEnd)+y
1985: 3f c4 19  call   SetEchoVolR
1988: fc        inc    y
1989: f7 00     mov    a,(BlockEnd)+y
198b: 3f dd 19  call   SetEchoFeedback
198e: fc        inc    y
198f: 3f 94 19  call   SetFIR
1992: ee        pop    y
1993: 6f        ret

SetFIR:
1994: 4d        push   x
1995: 8f 0f e2  mov    FirReg,#$0f
1998: cd 08     mov    x,#$08

L199A:
199a: f7 00     mov    a,(BlockEnd)+y
199c: fc        inc    y
199d: fa e2 f2  mov    (DSPADDR),(FirReg)
19a0: c4 f3     mov    DSPDATA,a
19a2: 60        clrc
19a3: 98 10 e2  adc    FirReg,#$10
19a6: 1d        dec    x
19a7: d0 f1     bne    L199A
19a9: ce        pop    x
19aa: 6f        ret

SetEchoVolL:
19ab: 2d        push   a
19ac: e5 21 04  mov    a,EchoPhase
19af: 9c        dec    a
19b0: 9c        dec    a
19b1: 10 07     bpl    L19BA
19b3: ae        pop    a
19b4: c5 22 04  mov    EchoVolLTgt,a
19b7: 5f c3 19  jmp    L19C3

L19BA:
19ba: ae        pop    a
19bb: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
19be: c4 f3     mov    DSPDATA,a
19c0: c5 22 04  mov    EchoVolLTgt,a

L19C3:
19c3: 6f        ret

SetEchoVolR:
19c4: 2d        push   a
19c5: e5 21 04  mov    a,EchoPhase
19c8: 9c        dec    a
19c9: 9c        dec    a
19ca: 10 07     bpl    L19D3
19cc: ae        pop    a
19cd: c5 23 04  mov    EchoVolRTgt,a
19d0: 5f dc 19  jmp    L19DC

L19D3:
19d3: ae        pop    a
19d4: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
19d7: c4 f3     mov    DSPDATA,a
19d9: c5 23 04  mov    EchoVolRTgt,a

L19DC:
19dc: 6f        ret

SetEchoFeedback:
19dd: 2d        push   a
19de: e5 21 04  mov    a,EchoPhase
19e1: 9c        dec    a
19e2: 9c        dec    a
19e3: 10 07     bpl    L19EC
19e5: ae        pop    a
19e6: c5 24 04  mov    EchoFeedback,a
19e9: 5f f5 19  jmp    L19F5

L19EC:
19ec: ae        pop    a
19ed: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
19f0: c4 f3     mov    DSPDATA,a
19f2: c5 24 04  mov    EchoFeedback,a

L19F5:
19f5: 6f        ret

SetEchoDelay:
19f6: 65 1f 04  cmp    a,EchoDelayCur
19f9: d0 01     bne    L19FC
19fb: 6f        ret

L19FC:
19fc: c5 1e 04  mov    EchoDelay,a
19ff: 8f 6c f2  mov    DSPADDR,#$6c          ; FLG
1a02: e4 d8     mov    a,FlgShadow
1a04: 08 20     or     a,#$20
1a06: c4 f3     mov    DSPDATA,a
1a08: e8 00     mov    a,#$00
1a0a: 8f 2c f2  mov    DSPADDR,#$2c          ; EVOLL
1a0d: c4 f3     mov    DSPDATA,a
1a0f: 8f 3c f2  mov    DSPADDR,#$3c          ; EVOLR
1a12: c4 f3     mov    DSPDATA,a
1a14: 8f 0d f2  mov    DSPADDR,#$0d          ; EFB
1a17: c4 f3     mov    DSPDATA,a
1a19: c5 21 04  mov    EchoPhase,a
1a1c: c5 25 04  mov    EchoVolLCur,a
1a1f: c5 26 04  mov    EchoVolRCur,a
1a22: e5 1e 04  mov    a,EchoDelay
1a25: 8f 7d f2  mov    DSPADDR,#$7d          ; EDL
1a28: c4 f3     mov    DSPDATA,a
1a2a: 1c        asl    a
1a2b: 1c        asl    a
1a2c: 1c        asl    a
1a2d: 48 ff     eor    a,#$ff
1a2f: 8f 6d f2  mov    DSPADDR,#$6d          ; ESA
1a32: c4 f3     mov    DSPDATA,a
1a34: e8 4f     mov    a,#$4f
1a36: c5 20 04  mov    EchoTimer,a
1a39: 6f        ret

; =============================================================================
; IoCommand - called from MainLoop when APUIO0 <> 0.  APUIO0 is a set of
; flag bits (echoed back):
;   bit3       read notification buffer (no parameter words)
;   otherwise  3 words are received through APUIO2/3 with APUIO1 counters:
;              IoWord1 (address), IoWord2 (install type), IoWord3 (params)
;   bit5       stop all audio first
;   bit7       upload a block to IoWord1 (2 bytes per counter step), then
;              install by IoWord2 lo: 1 samples, 3 sound bank, 4 instruments,
;              8 read notifications
;   bit7=0:    bit6 -> voice status + read from IoWord1, else run system
;              command IoWord3 hi with p1 = IoWord3 lo
; =============================================================================
IoCommand:
1a3a: e4 f4     mov    a,APUIO0
1a3c: f0 fc     beq    IoCommand
1a3e: c4 f4     mov    APUIO0,a
1a40: 28 08     and    a,#$08
1a42: f0 03     beq    L1A47
1a44: 5f cf 1a  jmp    ReadNotifications     ; bit3 : read notifications

L1A47:
1a47: f8 ce     mov    x,HandshakeCnt        ; receive 3 words

L1A49:
1a49: 3e f5     cmp    x,APUIO1
1a4b: d0 fc     bne    L1A49
1a4d: ba f6     movw   ya,APUIO2
1a4f: da d0     movw   IoWord1,ya
1a51: da 10     movw   $10,ya
1a53: d8 f5     mov    APUIO1,x
1a55: 3d        inc    x

L1A56:
1a56: 3e f5     cmp    x,APUIO1
1a58: d0 fc     bne    L1A56
1a5a: ba f6     movw   ya,APUIO2
1a5c: da d2     movw   IoWord2,ya
1a5e: 8f 00 f6  mov    APUIO2,#$00
1a61: d8 f5     mov    APUIO1,x
1a63: 3d        inc    x

L1A64:
1a64: 3e f5     cmp    x,APUIO1
1a66: d0 fc     bne    L1A64
1a68: ba f6     movw   ya,APUIO2
1a6a: da d4     movw   IoWord3,ya
1a6c: d8 f5     mov    APUIO1,x
1a6e: 3d        inc    x
1a6f: b3 f4 05  bbc5   APUIO0,L1A77          ; bit5 : stop all
1a72: 4d        push   x
1a73: 3f 75 16  call   StopAllAudio
1a76: ce        pop    x

L1A77:
1a77: e3 f4 03  bbs7   APUIO0,.upload        ; bit7 : upload
1a7a: 5f e2 1a  jmp    .noUpload
.upload:
1a7d: 8d 00     mov    y,#$00

L1A7F:
1a7f: 3e f5     cmp    x,APUIO1
1a81: d0 21     bne    L1AA4
1a83: e4 f6     mov    a,APUIO2
1a85: d7 10     mov    ($10)+y,a
1a87: fc        inc    y
1a88: e4 f7     mov    a,APUIO3
1a8a: d8 f5     mov    APUIO1,x
1a8c: 3d        inc    x
1a8d: d7 10     mov    ($10)+y,a
1a8f: fc        inc    y
1a90: d0 ed     bne    L1A7F
1a92: ab 11     inc    $11
1a94: e4 fd     mov    a,T0OUT               ; keep the echo start-up timer running during long uploads
1a96: f0 0c     beq    L1AA4
1a98: e5 20 04  mov    a,EchoTimer
1a9b: 30 04     bmi    L1AA1
1a9d: 9c        dec    a
1a9e: 10 01     bpl    L1AA1
1aa0: bc        inc    a

L1AA1:
1aa1: c5 20 04  mov    EchoTimer,a

L1AA4:
1aa4: 10 d9     bpl    L1A7F
1aa6: 3e f5     cmp    x,APUIO1
1aa8: 10 d5     bpl    L1A7F
1aaa: 3d        inc    x
1aab: d8 f5     mov    APUIO1,x
1aad: 3d        inc    x
1aae: d8 ce     mov    HandshakeCnt,x
1ab0: fa f4 f4  mov    (APUIO0),(APUIO0)
1ab3: e4 d2     mov    a,IoWord2             ; install type
1ab5: 68 01     cmp    a,#$01
1ab7: d0 03     bne    L1ABC
1ab9: 5f a6 1b  jmp    InstallSamples

L1ABC:
1abc: 68 03     cmp    a,#$03
1abe: d0 03     bne    L1AC3
1ac0: 5f 3e 1b  jmp    InstallBank

L1AC3:
1ac3: 68 04     cmp    a,#$04
1ac5: d0 03     bne    L1ACA
1ac7: 5f cb 1b  jmp    InstallInstruments

L1ACA:
1aca: 68 08     cmp    a,#$08
1acc: f0 01     beq    ReadNotifications
1ace: 6f        ret

; ReadNotifications - send the 16-byte notification buffer, clear it
ReadNotifications:
1acf: f8 ce     mov    x,HandshakeCnt
1ad1: 8f ea 10  mov    $10,#$ea
1ad4: 8f 04 11  mov    $11,#$04
1ad7: 8f 00 db  mov    NotifyStatus,#$00
1ada: e8 00     mov    a,#$00
1adc: c5 e8 04  mov    NotifyCount,a
1adf: 5f 14 1b  jmp    SendBlock
.noUpload:
1ae2: d8 ce     mov    HandshakeCnt,x
1ae4: fa f4 f4  mov    (APUIO0),(APUIO0)
1ae7: fa d5 02  mov    ($02),(IoWord3+1)     ; $02 = command
1aea: c3 f4 03  bbs6   APUIO0,L1AF0          ; bit6 : voice status
1aed: 5f 57 11  jmp    QEv_System            ; else: system command

L1AF0:
1af0: 4d        push   x
1af1: 8d 08     mov    y,#$08
1af3: cd 78     mov    x,#$78

L1AF5:
1af5: d8 f2     mov    DSPADDR,x
1af7: e4 f3     mov    a,DSPDATA
1af9: 10 03     bpl    L1AFE
1afb: 48 ff     eor    a,#$ff
1afd: bc        inc    a

L1AFE:
1afe: d6 ff 01  mov    VEnvxStatus-1+y,a
1b01: f6 b4 00  mov    a,VoiceState-1+y
1b04: 1c        asl    a
1b05: 6b 00     ror    BlockEnd
1b07: 7d        mov    a,x
1b08: 80        setc
1b09: a8 10     sbc    a,#$10
1b0b: 5d        mov    x,a
1b0c: fe e7     dbnz   y,L1AF5
1b0e: ce        pop    x
1b0f: e4 00     mov    a,BlockEnd
1b11: c5 08 02  mov    VActiveMask,a

; SendBlock - stream ($10) to APUIO2/3, 2 bytes per APUIO1 counter step
SendBlock:
1b14: 8d 00     mov    y,#$00

L1B16:
1b16: 3e f5     cmp    x,APUIO1
1b18: d0 11     bne    L1B2B
1b1a: f7 10     mov    a,($10)+y
1b1c: c4 f6     mov    APUIO2,a
1b1e: fc        inc    y
1b1f: f7 10     mov    a,($10)+y
1b21: c4 f7     mov    APUIO3,a
1b23: d8 f5     mov    APUIO1,x
1b25: 3d        inc    x
1b26: fc        inc    y
1b27: d0 ed     bne    L1B16
1b29: ab 11     inc    $11

L1B2B:
1b2b: 10 e9     bpl    L1B16
1b2d: 3e f5     cmp    x,APUIO1
1b2f: 10 e5     bpl    L1B16
1b31: 3d        inc    x
1b32: d8 f5     mov    APUIO1,x
1b34: 3d        inc    x
1b35: d8 ce     mov    HandshakeCnt,x
1b37: fa db f7  mov    (APUIO3),(NotifyStatus)
1b3a: fa f4 f4  mov    (APUIO0),(APUIO0)
1b3d: 6f        ret

; =============================================================================
; Install type 3 - register the sound bank at IoWord1 with first ID IoWord3
;  lo; add IoWord3 hi to every program number of its track headers.
; =============================================================================
InstallBank:
1b3e: 8f ab 02  mov    $02,#$ab
1b41: 8f 1c 03  mov    $03,#$1c
1b44: 8d 15     mov    y,#$15

L1B46:
1b46: f7 02     mov    a,($02)+y
1b48: 68 ff     cmp    a,#$ff
1b4a: f0 09     beq    L1B55
1b4c: 64 d4     cmp    a,IoWord3
1b4e: f0 05     beq    L1B55
1b50: dc        dec    y
1b51: dc        dec    y
1b52: dc        dec    y
1b53: 10 f1     bpl    L1B46

L1B55:
1b55: e4 d4     mov    a,IoWord3
1b57: d7 02     mov    ($02)+y,a
1b59: e4 d0     mov    a,IoWord1
1b5b: fc        inc    y
1b5c: d7 02     mov    ($02)+y,a
1b5e: e4 d1     mov    a,IoWord1+1
1b60: fc        inc    y
1b61: d7 02     mov    ($02)+y,a
1b63: 8d 00     mov    y,#$00
1b65: f7 d0     mov    a,(IoWord1)+y
1b67: c4 04     mov    $04,a
1b69: fc        inc    y
1b6a: fc        inc    y

L1B6B:
1b6b: 60        clrc
1b6c: f7 d0     mov    a,(IoWord1)+y
1b6e: fc        inc    y
1b6f: 84 d0     adc    a,IoWord1
1b71: c4 06     mov    $06,a
1b73: f7 d0     mov    a,(IoWord1)+y
1b75: 84 d1     adc    a,IoWord1+1
1b77: c4 07     mov    $07,a
1b79: fc        inc    y
1b7a: 6d        push   y
1b7b: 8d 03     mov    y,#$03
1b7d: f7 06     mov    a,($06)+y
1b7f: c4 02     mov    $02,a
1b81: fc        inc    y
1b82: fc        inc    y
1b83: fc        inc    y
1b84: f7 06     mov    a,($06)+y
1b86: f0 05     beq    L1B8D
1b88: dd        mov    a,y
1b89: 60        clrc
1b8a: 88 0c     adc    a,#$0c
1b8c: fd        mov    y,a

L1B8D:
1b8d: fc        inc    y

L1B8E:
1b8e: fc        inc    y
1b8f: fc        inc    y
1b90: f7 06     mov    a,($06)+y
1b92: 60        clrc
1b93: 84 d5     adc    a,IoWord3+1
1b95: d7 06     mov    ($06)+y,a
1b97: fc        inc    y
1b98: fc        inc    y
1b99: fc        inc    y
1b9a: fc        inc    y
1b9b: fc        inc    y
1b9c: 8b 02     dec    $02
1b9e: d0 ee     bne    L1B8E
1ba0: ee        pop    y
1ba1: 8b 04     dec    $04
1ba3: d0 c6     bne    L1B6B
1ba5: 6f        ret

; Install type 1 - DIR entries from IoWord3 lo on (no self-modifying code)
InstallSamples:
1ba6: 8d 00     mov    y,#$00
1ba8: e4 d4     mov    a,IoWord3
1baa: 1c        asl    a
1bab: 1c        asl    a
1bac: 5d        mov    x,a
1bad: f7 d0     mov    a,(IoWord1)+y
1baf: 1c        asl    a
1bb0: c4 02     mov    $02,a
1bb2: fc        inc    y

L1BB3:
1bb3: f7 d0     mov    a,(IoWord1)+y
1bb5: 80        setc
1bb6: 84 d0     adc    a,IoWord1
1bb8: d5 00 1f  mov    SampleDir+x,a
1bbb: 3d        inc    x
1bbc: fc        inc    y
1bbd: f7 d0     mov    a,(IoWord1)+y
1bbf: 84 d1     adc    a,IoWord1+1
1bc1: d5 00 1f  mov    SampleDir+x,a
1bc4: fc        inc    y
1bc5: 3d        inc    x
1bc6: 8b 02     dec    $02
1bc8: d0 e9     bne    L1BB3
1bca: 6f        ret

; Install type 4 - 8-byte records to $0500+IoWord3 hi*8, SRCN += IoWord3 lo
InstallInstruments:
1bcb: 8d 00     mov    y,#$00
1bcd: 8f 00 04  mov    $04,#$00
1bd0: 8f 05 05  mov    $05,#$05
1bd3: e4 d5     mov    a,IoWord3+1
1bd5: 1c        asl    a
1bd6: 1c        asl    a
1bd7: 1c        asl    a
1bd8: 90 02     bcc    L1BDC
1bda: ab 05     inc    $05

L1BDC:
1bdc: c4 04     mov    $04,a
1bde: f7 d0     mov    a,(IoWord1)+y
1be0: c4 02     mov    $02,a
1be2: 3a d0     incw   IoWord1

L1BE4:
1be4: f7 d0     mov    a,(IoWord1)+y
1be6: 60        clrc
1be7: 84 d4     adc    a,IoWord3
1be9: d7 04     mov    ($04)+y,a
1beb: fc        inc    y
1bec: cd 07     mov    x,#$07

L1BEE:
1bee: f7 d0     mov    a,(IoWord1)+y
1bf0: d7 04     mov    ($04)+y,a
1bf2: fc        inc    y
1bf3: 1d        dec    x
1bf4: d0 f8     bne    L1BEE
1bf6: 8b 02     dec    $02
1bf8: d0 ea     bne    L1BE4
1bfa: 6f        ret

; =============================================================================
; ProcessEventQueue - 4-byte events at $0492, written directly by the CPU
;  (upload to $0490-$04d1).  Types: 1 system, 2 start sound,
;  3+ restart (stop handle p2 first).  No MIDI type (MIDI code is dead).
;  Start/restart use a second entry {-, pan, volume, tempo offset}.
; =============================================================================
ProcessEventQueue:
1bfb: e5 91 04  mov    a,QueueRead
1bfe: 65 90 04  cmp    a,QueueWrite
1c01: f0 55     beq    L1C58
1c03: fd        mov    y,a
1c04: f6 92 04  mov    a,EventQueue+y
1c07: 2d        push   a
1c08: fc        inc    y
1c09: f6 92 04  mov    a,EventQueue+y
1c0c: c4 02     mov    $02,a
1c0e: fc        inc    y
1c0f: f6 92 04  mov    a,EventQueue+y
1c12: c4 04     mov    $04,a
1c14: fc        inc    y
1c15: f6 92 04  mov    a,EventQueue+y
1c18: c4 05     mov    $05,a
1c1a: fc        inc    y
1c1b: cc 91 04  mov    QueueRead,y
1c1e: ae        pop    a
1c1f: 9c        dec    a
1c20: d0 06     bne    L1C28
1c22: 3f 57 11  call   QEv_System
1c25: 5f 55 1c  jmp    L1C55

L1C28:
1c28: 9c        dec    a
1c29: f0 0e     beq    L1C39
1c2b: 6d        push   y
1c2c: e4 04     mov    a,$04
1c2e: 2d        push   a
1c2f: fa 05 04  mov    ($04),($05)
1c32: 3f a0 18  call   StopSound
1c35: ae        pop    a
1c36: c4 04     mov    $04,a
1c38: ee        pop    y

L1C39:
1c39: fc        inc    y
1c3a: f6 92 04  mov    a,EventQueue+y
1c3d: c5 c8 03  mov    StartPan,a
1c40: fc        inc    y
1c41: f6 92 04  mov    a,EventQueue+y
1c44: c5 c9 03  mov    StartVolume,a
1c47: fc        inc    y
1c48: f6 92 04  mov    a,EventQueue+y
1c4b: c5 ca 03  mov    StartTempoOfs,a
1c4e: fc        inc    y
1c4f: cc 91 04  mov    QueueRead,y
1c52: 3f 7a 11  call   StartSound

L1C55:
1c55: 5f fb 1b  jmp    ProcessEventQueue

L1C58:
1c58: 6f        ret

; PostNotification - A = type, Y = value -> NotifyBuf (8 entries), APUIO3
PostNotification:
1c59: 4d        push   x
1c5a: 2d        push   a
1c5b: e5 e8 04  mov    a,NotifyCount
1c5e: 68 08     cmp    a,#$08
1c60: 90 02     bcc    L1C64
1c62: e8 00     mov    a,#$00

L1C64:
1c64: c4 02     mov    $02,a
1c66: bc        inc    a
1c67: c5 e8 04  mov    NotifyCount,a
1c6a: 9c        dec    a
1c6b: 1c        asl    a
1c6c: 5d        mov    x,a
1c6d: ae        pop    a
1c6e: d5 ea 04  mov    NotifyBuf+x,a
1c71: dd        mov    a,y
1c72: d5 eb 04  mov    NotifyBuf+1+x,a
1c75: ce        pop    x
1c76: e4 db     mov    a,NotifyStatus
1c78: 28 f0     and    a,#$f0
1c7a: 04 02     or     a,$02
1c7c: 08 08     or     a,#$08
1c7e: c4 db     mov    NotifyStatus,a
1c80: c4 f7     mov    APUIO3,a
1c82: 6f        ret

; NotifySoundEnded - if no other active track has this ID, post {1, ID}
NotifySoundEnded:
1c83: 4d        push   x
1c84: f5 aa 02  mov    a,TrkSoundID+x
1c87: c4 02     mov    $02,a
1c89: 8d 16     mov    y,#$16
1c8b: cd 00     mov    x,#$00

L1C8D:
1c8d: f6 19 02  mov    a,TrkStatus-1+y
1c90: 10 08     bpl    L1C9A
1c92: e4 02     mov    a,$02
1c94: 76 a9 02  cmp    a,TrkSoundID-1+y
1c97: d0 01     bne    L1C9A
1c99: 3d        inc    x

L1C9A:
1c9a: fe f1     dbnz   y,L1C8D
1c9c: c8 00     cmp    x,#$00
1c9e: d0 07     bne    L1CA7
1ca0: eb 02     mov    y,$02
1ca2: e8 01     mov    a,#$01
1ca4: 3f 59 1c  call   PostNotification

L1CA7:
1ca7: ce        pop    x
1ca8: 6f        ret

UnusedWord:
1ca9: dw    $1cab                            ; unused (= address of BankTable)

; BankTable - 8 x {first sound ID ($ff = empty), bank pointer}
BankTable:
1cab: db    $ff,$00,$00                      ; snapshot: IDs $f8@$2000, $53@$5500, $3e@$4e00, $00@$3800
1cae: db    $ff,$00,$00
1cb1: db    $ff,$00,$00
1cb4: db    $ff,$00,$00
1cb7: db    $f8,$00,$20
1cba: db    $53,$00,$55
1cbd: db    $3e,$00,$4e
1cc0: db    $00,$00,$38

; =============================================================================
; MIDI support ($1cc3-$1e01): complete but UNREFERENCED - no event type
; reaches it.  MidiReset stops the sequencer (SeqDisable) instead of
; disabling each track's timer as v1.01 does.
; =============================================================================
MidiReset:
1cc3: ab e1     inc    SeqDisable
1cc5: 8d 15     mov    y,#$15

L1CC7:
1cc7: e8 80     mov    a,#$80
1cc9: d6 1a 02  mov    TrkStatus+y,a
1ccc: e8 40     mov    a,#$40
1cce: d6 9e ff  mov    TrkPan+y,a
1cd1: e8 7f     mov    a,#$7f
1cd3: d6 5c ff  mov    TrkVolume+y,a
1cd6: d6 9c 03  mov    TrkVelocity+y,a
1cd9: dd        mov    a,y
1cda: d6 aa 02  mov    TrkSoundID+y,a
1cdd: e8 00     mov    a,#$00
1cdf: d6 44 03  mov    TrkNumber+y,a
1ce2: d6 68 02  mov    TrkPriority+y,a
1ce5: d6 d6 02  mov    TrkFlags+y,a
1ce8: d6 7e 02  mov    TrkTranspose+y,a
1ceb: d6 72 ff  mov    TrkKeyOffset+y,a
1cee: e8 01     mov    a,#$01
1cf0: d6 c0 02  mov    TrkProgram+y,a
1cf3: dc        dec    y
1cf4: 10 d1     bpl    L1CC7
1cf6: 6f        ret

; Midi_Message - 8n/9n note, Bn ignored (v1.01 adds CC7/CC10), Cn program,
; En bend, F0 channel $c/$f
Midi_Message:
1cf7: e4 02     mov    a,$02
1cf9: 28 0f     and    a,#$0f
1cfb: c4 22     mov    CurTrack,a
1cfd: 5d        mov    x,a
1cfe: e4 02     mov    a,$02
1d00: 28 f0     and    a,#$f0
1d02: 68 80     cmp    a,#$80
1d04: d0 04     bne    L1D0A

L1D06:
1d06: 3f b4 1d  call   MidiNoteOff
1d09: 6f        ret

L1D0A:
1d0a: 68 90     cmp    a,#$90
1d0c: d0 09     bne    L1D17
1d0e: 78 00 05  cmp    $05,#$00
1d11: f0 f3     beq    L1D06
1d13: 3f 73 1d  call   MidiNoteOn
1d16: 6f        ret

L1D17:
1d17: 68 a0     cmp    a,#$a0
1d19: d0 01     bne    L1D1C
1d1b: 6f        ret

L1D1C:
1d1c: 68 b0     cmp    a,#$b0
1d1e: d0 04     bne    L1D24
1d20: 3f f8 1d  call   MidiControl
1d23: 6f        ret

L1D24:
1d24: 68 c0     cmp    a,#$c0
1d26: d0 04     bne    L1D2C
1d28: 3f f9 1d  call   MidiProgram
1d2b: 6f        ret

L1D2C:
1d2c: 68 d0     cmp    a,#$d0
1d2e: d0 01     bne    L1D31
1d30: 6f        ret

L1D31:
1d31: 68 e0     cmp    a,#$e0
1d33: d0 1a     bne    L1D4F
1d35: e4 04     mov    a,$04
1d37: d5 5a 03  mov    TrkBendHi+x,a
1d3a: c4 0d     mov    $0d,a
1d3c: e4 05     mov    a,$05
1d3e: d5 70 03  mov    TrkBendLo+x,a
1d41: c4 0c     mov    $0c,a
1d43: d8 04     mov    $04,x
1d45: 8f fd 08  mov    $08,#$fd
1d48: 8f ff 09  mov    $09,#$ff
1d4b: 3f 46 17  call   ApplyParamToVoices
1d4e: 6f        ret

L1D4F:
1d4f: 68 f0     cmp    a,#$f0
1d51: d0 1f     bne    L1D72
1d53: 78 0c 22  cmp    CurTrack,#$0c
1d56: d0 12     bne    L1D6A
1d58: 8f 5c f2  mov    DSPADDR,#$5c          ; KOF
1d5b: 8f ff f3  mov    DSPDATA,#$ff
1d5e: cd 00     mov    x,#$00

L1D60:
1d60: e8 00     mov    a,#$00
1d62: d4 b5     mov    VoiceState+x,a
1d64: 3d        inc    x
1d65: c8 08     cmp    x,#$08
1d67: d0 f7     bne    L1D60
1d69: 6f        ret

L1D6A:
1d6a: 78 0f 22  cmp    CurTrack,#$0f
1d6d: d0 03     bne    L1D72
1d6f: 5f c3 1c  jmp    MidiReset

L1D72:
1d72: 6f        ret

MidiNoteOn:
1d73: e8 00     mov    a,#$00
1d75: c4 27     mov    CurFlags,a
1d77: f5 7e 02  mov    a,TrkTranspose+x
1d7a: c4 d9     mov    HdrTranspose,a
1d7c: e4 05     mov    a,$05
1d7e: 13 27 02  bbc0   CurFlags,L1D83
1d81: e8 7f     mov    a,#$7f

L1D83:
1d83: c4 c6     mov    Velocity,a
1d85: f5 1a 02  mov    a,TrkStatus+x
1d88: 28 01     and    a,#$01
1d8a: f0 01     beq    L1D8D
1d8c: 6f        ret

L1D8D:
1d8d: e4 04     mov    a,$04
1d8f: 2d        push   a
1d90: 3f 2f 09  call   AllocVoice
1d93: 90 02     bcc    L1D97
1d95: ae        pop    a
1d96: 6f        ret

L1D97:
1d97: d8 28     mov    CurVoice,x
1d99: e4 c6     mov    a,Velocity
1d9b: d5 58 02  mov    VVelocity+x,a
1d9e: ae        pop    a
1d9f: d5 50 02  mov    VNote+x,a
1da2: e4 22     mov    a,CurTrack
1da4: d5 60 02  mov    VTrack+x,a
1da7: f4 b5     mov    a,VoiceState+x
1da9: 08 01     or     a,#$01
1dab: d4 b5     mov    VoiceState+x,a
1dad: e8 7f     mov    a,#$7f
1daf: d4 8d     mov    VGateHi+x,a
1db1: d4 95     mov    VGateMid+x,a
1db3: 6f        ret

MidiNoteOff:
1db4: e8 00     mov    a,#$00
1db6: c4 06     mov    $06,a
1db8: c4 07     mov    $07,a
1dba: c4 08     mov    $08,a
1dbc: c4 09     mov    $09,a
1dbe: cd 07     mov    x,#$07

L1DC0:
1dc0: f4 b5     mov    a,VoiceState+x
1dc2: 28 83     and    a,#$83
1dc4: f0 1f     beq    L1DE5
1dc6: f4 8d     mov    a,VGateHi+x
1dc8: 30 1b     bmi    L1DE5
1dca: f5 50 02  mov    a,VNote+x
1dcd: 64 04     cmp    a,$04
1dcf: d0 14     bne    L1DE5
1dd1: f4 85     mov    a,VSoundID+x
1dd3: 64 22     cmp    a,CurTrack
1dd5: d0 0e     bne    L1DE5
1dd7: ab 06     inc    $06
1dd9: f4 ad     mov    a,VAgeLo+x
1ddb: fb a5     mov    y,VAgeHi+x
1ddd: 5a 08     cmpw   ya,$08
1ddf: 90 04     bcc    L1DE5
1de1: da 08     movw   $08,ya
1de3: d8 07     mov    $07,x

L1DE5:
1de5: 1d        dec    x
1de6: 10 d8     bpl    L1DC0
1de8: e4 06     mov    a,$06
1dea: d0 01     bne    L1DED
1dec: 6f        ret

L1DED:
1ded: f8 07     mov    x,$07
1def: e8 00     mov    a,#$00
1df1: d4 8d     mov    VGateHi+x,a
1df3: d4 95     mov    VGateMid+x,a
1df5: d4 9d     mov    VGateLo+x,a
1df7: 6f        ret

MidiControl:
1df8: 6f        ret

MidiProgram:
1df9: f8 22     mov    x,CurTrack
1dfb: e4 04     mov    a,$04
1dfd: d5 c0 02  mov    TrkProgram+x,a
1e00: 6f        ret
1e01: 6f        ret

; end of driver image ($1e01)
