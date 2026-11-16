;==============================================================================
;  Mark Cooksey C64 sound driver -- PAPERBOY (1986 Elite)
;  Middle driver: Bomb Jack's pattern idea (length + note pairs, commands
;  from $C8) rewritten as one loop over the voices, with a command jump table,
;  per-voice effects, drum macros and a sound effect player.
;
;  Source: Paperboy.sid (PSID v2, load $A5FE-$C017, 5 songs, CIA timing, PAL,
;  6581). Reassembles byte-identically to the .sid file:
;            ca65 paperboy_sound.s
;            ld65 -C paperboy_sound.cfg -o out.sid paperboy_sound.o
;
;  MEMORY
;    $A5FE-$A6CE  variables          $B108-$B10F  sound effect variables
;    $A6CF-$B0C4  player             $B110-$B257  sound effect player
;    $B0C5-$B107  drums              $B258-$B4E1  sound effects
;    $B4E6-$BFDF  4 songs (init routine, order lists, patterns)
;    $BFE0-$C017  SID ripper wrapper
;
;  ENTRY POINTS
;    Song0_Init .. Song3_Init   start a song (the rip's songs 1+2 both use
;                               Song0 at 150 Hz and 50 Hz)
;    Play $B06A                 call at the song's rate (CIA timer)
;    sRequest                   write 1-15 to start a sound effect
;
;  TIMING: Play runs the patterns every mSpeed calls (one tick); effects and
;  register writes run on every call, drum steps every mDrumSpeed calls.
;
;  ORDER LISTS: .word pattern pointers; a high byte of 0 restarts the list.
;
;  PATTERNS
;    $00            end of pattern
;    $01-$C7 nn     length in ticks, then the note byte: bits 0-3 semitone
;                   (1 = C ... 12 = B, 0 = rest), bits 4-6 octave. The gate is
;                   released when mReleaseAt ticks are left; a note retriggers
;                   the gate (if the voice's output is on) and restarts the
;                   effect delays.
;    $C8-$DE        commands (C_ equates), parameters follow
;    $F0-$FF ll     drum n for ll ticks (the voice's pattern waits)
;
;  Bytes the driver never reads are kept (so the file reassembles) and are
;  marked "not referenced".
;==============================================================================

; ---------------------------------------------------------------- zero page
zPat1                = $92          ; voice 1 pattern pointer
zPat2                = $94          ; voice 2 pattern pointer
zPat3                = $4B          ; voice 3 pattern pointer
zUnused4D            = $4D          ; written before every voice, never read
zOrder               = $4F          ; order list pointer (temporary)
zCmd                 = $51          ; command / drum data pointer
zSfx                 = $96          ; sound effect data

; ---------------------------------------------------------------- pattern commands
C_VOLUME             = $C8
C_SPEED              = $C9
C_AD                 = $CA
C_SR                 = $CB
C_WAVE               = $CC
C_PULSE              = $CD
C_FILTER             = $CE
C_PWSWEEP            = $CF
C_TRILL              = $D0
C_VIBRATO            = $D1
C_SLIDE              = $D2
C_WAVEALT            = $D3
C_PWSWEEP_OFF        = $D4
C_TRILL_OFF          = $D5
C_VIBRATO_OFF        = $D6
C_SLIDE_OFF          = $D7
C_WAVEALT_OFF        = $D8
C_FILTER_OFF         = $D9
C_RELEASE            = $DA
C_SLIDESTEP          = $DB
C_PWRANGE            = $DC
C_DRUMSPEED          = $DD
C_STOP               = $DE
C_DRUM               = $F0          ; drum 0-15: C_DRUM+n, length

; ---------------------------------------------------------------- SID / CIA
SID_V1_FREQ_LO       = $D400
SID_V1_FREQ_HI       = $D401
SID_V1_PW_LO         = $D402
SID_V1_PW_HI         = $D403
SID_V1_CTRL          = $D404
SID_V1_AD            = $D405
SID_V1_SR            = $D406
SID_V2_FREQ_LO       = $D407
SID_V2_FREQ_HI       = $D408
SID_V2_PW_LO         = $D409
SID_V2_PW_HI         = $D40A
SID_V2_CTRL          = $D40B
SID_V2_AD            = $D40C
SID_V2_SR            = $D40D
SID_V3_FREQ_LO       = $D40E
SID_V3_FREQ_HI       = $D40F
SID_V3_PW_LO         = $D410
SID_V3_PW_HI         = $D411
SID_V3_CTRL          = $D412
SID_V3_AD            = $D413
SID_V3_SR            = $D414
SID_FC_LO            = $D415
SID_FC_HI            = $D416
SID_RES_FILT         = $D417
SID_MODE_VOL         = $D418
CIA1_TA_LO           = $DC04
CIA1_TA_HI           = $DC05

.segment "PSIDHDR"

; PSID v2 header (big-endian fields), written by the SID ripper,
; not by the game. The first two bytes after it are the load address.
PsidHeader:
        .byte "PSID"                          ; magic
        .dbyt $0002                         ; version
        .dbyt $007C                         ; offset of the data
        .dbyt $0000                         ; load address (0 = first 2 data bytes)
        .dbyt Rip_Init                      ; init (A = song - 1)
        .dbyt Play                          ; play
        .dbyt $0005                         ; number of songs
        .dbyt $0001                         ; default song
        .dbyt $0000, $001F                  ; speed bits per song: 1 = CIA timer, 0 = VBI
        .byte "Paperboy"
        .res 24, $00                       ; name (32 bytes)
        .byte "Mark Cooksey"
        .res 20, $00                       ; author (32 bytes)
        .byte "1986 Elite"
        .res 22, $00                       ; released (32 bytes)
        .dbyt $0014                         ; flags: clock PAL, SID 6581
        .byte $00, $00                      ; start page, page length
        .dbyt $0000                         ; second/third SID
        .word LoadAddress                   ; load address (little-endian)

.segment "PLAYER"

; VARIABLES (values are the ripper's snapshot). Arrays hold voices 1-3.
mPwSweepOn:
LoadAddress:
        .byte $07                           ; pulse sweep: bit n = voice n+1 (C_PWSWEEP)

mPwSpeed:
        .byte $01,$01,$01                   ; pulse sweep: calls per step

mPwTimer:
        .byte $01,$01,$01

mPwStartHi:
        .byte $04,$00,$00                   ; pulse sweep start (C_PWRANGE)

mPwStartLo:
        .byte $02,$32,$32

mPwLimitHi:
        .byte $0C,$0E,$0C                   ; back to the start when the high byte reaches this

mPwLimitLo:
        .byte $00,$00,$64                   ; (never read)

mPwStepHi:
        .byte $00,$00,$00                   ; added each step

mPwStepLo:
        .byte $28,$14,$28

mPwDelaySet:
        .byte $01,$02,$02                   ; delay at each note

mPwDelay:
        .byte $00,$00,$00

mPwResetOn:
        .byte $06                           ; bit n: restart the pulse width at each note

mTrillOn:
        .byte $00                           ; octave trill: bit n = voice n+1 (C_TRILL)

mTrillSpeed:
        .byte $02,$02,$02

mTrillTimer:
        .byte $01,$01,$01

mTrillUp:
        .byte $00,$00,$00                   ; 1 = an octave up now

mTrillDelaySet:
        .byte $04,$04,$04

mTrillDelay:
        .byte $04,$04,$04

mVibOn:
        .byte $01                           ; vibrato: bit n = voice n+1 (C_VIBRATO)

mVibSpeed:
        .byte $02,$02,$02                   ; calls per phase

mVibTimer:
        .byte $02,$01,$01

mVibDepthHi:
        .byte $01,$01,$01

mVibDepthLo:
        .byte $64,$64,$64

mVibDelaySet:
        .byte $28,$32,$04

mVibDelay:
        .byte $00,$32,$04

mBaseFreqHi:
        .byte $22,$22,$00                   ; note frequency without vibrato

mBaseFreqLo:
        .byte $D2,$D2,$00

mVibPhase:
        .byte $02,$00,$00                   ; 0 base, 1 +depth, 2 base, 3 -depth

mSlideOn:
        .byte $00                           ; slide: bit n = voice n+1 (C_SLIDE)

mSlideSpeed:
        .byte $01,$02,$02                   ; calls per step (C_SLIDESTEP)

mSlideTimer:
        .byte $01,$01,$01

mSlideStepHi:
        .byte $00,$00,$00

mSlideStepLo:
        .byte $C4,$14,$14

mSlideDelaySet:
        .byte $04,$04,$04

mSlideDelay:
        .byte $00,$04,$04

mSlideUp:
        .byte $00,$00,$00                   ; 1 = slide up

mSlideToHi:
        .byte $22,$00,$00                   ; slide target

mSlideToLo:
        .byte $D2,$00,$00

mSlideArmed:
        .byte $01                           ; set by every note (any voice); the slide only snaps to the target and switches off while it is set

mWaveAltOn:
        .byte $00                           ; waveform alternation: bit n = voice n+1 (C_WAVEALT)

mWaveAltSpeed:
        .byte $02,$02,$02

mWaveAltTimer:
        .byte $01,$01,$01

mWaveAltDelaySet:
        .byte $04,$04,$04

mWaveAltDelay:
        .byte $04,$04,$04

mWaveA:
        .byte $20,$20,$20                   ; first waveform

mWaveB:
        .byte $80,$80,$80                   ; second waveform

mWaveAltPhase:
        .byte $00,$00,$00

mCtrl:
        .byte $41,$41,$40                   ; last control value written (bit 0 = gate)

mModeVol:
        .byte $1F                           ; shadow SID_MODE_VOL

mResFilt:
        .byte $80                           ; shadow SID_RES_FILT

mCutoffHi:
        .byte $A0                           ; shadow SID_FC_HI

mCutoffLo:
        .byte $C8                           ; shadow SID_FC_LO

mWave:
        .byte $40,$40,$40                   ; control register without the gate (C_WAVE)

mFreqHi:
        .byte $24,$22,$00                   ; frequency written to the SID

mFreqLo:
        .byte $36,$D2,$00

mAD:
        .byte $01,$08,$08

mSR:
        .byte $89,$47,$C8

mPwHi:
        .byte $09,$00,$04

mPwLo:
        .byte $7A,$5A,$E2

mOutputOn:
        .byte $07                           ; bit n: voice n+1 writes the SID

mTrackOn:
        .byte $07                           ; bit n: voice n+1 reads its pattern

mSpeed:
        .byte $04                           ; calls per tick (C_SPEED)

mSpeedCount:
        .byte $01

mDuration:
        .byte $06,$02,$00                   ; ticks left of the note

mDrum:
        .byte $00,$00,$03                   ; drum playing: number + 1, 0 = none

mRegOfs:
        .byte $0E                           ; current voice: SID register offset

mVoiceBit:
        .byte $04                           ; current voice: 1, 2, 4

mNoteHi:
        .byte $22                           ; NoteToFreq result

mNoteLo:
        .byte $D2

mReleaseAt:
        .byte $02,$02,$02                   ; gate off when this many ticks are left (C_RELEASE)

mSaveX:
        .byte $01

mNoteTemp:
        .byte $51

mOrderHi:
        .byte $B5,$B5,$B5                   ; order list pointers

mOrderLo:
        .byte $66,$8E,$EA

mOrderIdx:
        .byte $0C,$22,$22

mVoice:
        .byte $02                           ; current voice 0-2

mCmdByte:
        .byte $03

mDrumOfs:
        .byte $00,$00,$04                   ; drum number * 2
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

mDrumPtrHi:
        .byte $00,$00,$B0                   ; drum data

mDrumPtrLo:
        .byte $00,$00,$CF

mDrumLen:
        .byte $01,$01,$03                   ; ticks left of the drum

mDrumPos:
        .byte $00,$00,$2C                   ; offset of the next drum step

mDrumSpeed:
        .byte $01                           ; calls per drum step (C_DRUMSPEED)

mDrumCount:
        .byte $01

mSaveY:
        .byte $00

mDrumStepping:
        .byte $00,$00,$03                   ; 1 while the drum steps run

mCmdVector:
        .byte $2D,$AF                       ; JMP (mCmdVector)

; EFFECTS: run the per-voice effects for voices 1, 2, 3.
Effects:
        jsr SelectV1
        jsr Fx_PwSweep
        jsr SelectV2
        jsr Fx_PwSweep
        jsr SelectV3
        jsr Fx_PwSweep
        rts

; X = voice. Pulse sweep: after the delay, every mPwSpeed calls add the
; step; restart at mPwStart once the high byte reaches mPwLimitHi.
; Every effect is skipped while the voice is muted or plays a drum.
Fx_PwSweep:
        ldx mVoice
        lda mOutputOn
        and mVoiceBit
        beq Fx_Trill
        lda mPwSweepOn
        and mVoiceBit
        beq Fx_Trill
        lda mDrum,x
        bne Fx_Trill
        lda mPwDelay,x
        beq Fx_PwStep
        dec mPwDelay,x
        jmp Fx_Trill

Fx_PwStep:
        dec mPwTimer,x
        bne Fx_Trill
        lda mPwSpeed,x
        sta mPwTimer,x
        jsr PwAddStep
        cmp mPwLimitHi,x
        bcc Fx_Trill
        jsr PwRestart
        jmp Fx_Trill

PwAddStep:
        clc
        lda mPwLo,x
        adc mPwStepLo,x
        sta mPwLo,x
        lda mPwHi,x
        adc mPwStepHi,x
        sta mPwHi,x
        rts

PwRestart:
        lda mPwStartLo,x
        sta mPwLo,x
        lda mPwStartHi,x
        sta mPwHi,x
        rts

; Octave trill: after the delay, every mTrillSpeed calls shift the
; frequency an octave up, then back down.
Fx_Trill:
        lda mOutputOn
        and mVoiceBit
        beq Fx_Vibrato
        lda mTrillOn
        and mVoiceBit
        beq Fx_Vibrato
        lda mDrum,x
        bne Fx_Vibrato
        lda mTrillDelay,x
        beq Fx_TrillStep
        dec mTrillDelay,x
        jmp Fx_Vibrato

Fx_TrillStep:
        dec mTrillTimer,x
        bne Fx_Vibrato
        jsr TrillFlip
        jmp Fx_Vibrato

TrillFlip:
        lda mTrillSpeed,x
        sta mTrillTimer,x
        lda mTrillUp,x
        bne TrillDown
        clc
        asl mFreqLo,x
        rol mFreqHi,x
        lda #$01
        sta mTrillUp,x
        rts

TrillDown:
        lsr mFreqHi,x
        ror mFreqLo,x
        lda #$00
        sta mTrillUp,x
        rts

; Vibrato: after the delay, every mVibSpeed calls step through
; base, base+depth, base, base-depth (a square wave, not a sine).
Fx_Vibrato:
        lda mOutputOn
        and mVoiceBit
        beq Fx_VibSkip
        lda mVibOn
        and mVoiceBit
        beq Fx_VibSkip
        lda mDrum,x
        bne Fx_Slide
        lda mVibDelay,x
        beq Fx_VibStep
        dec mVibDelay,x

Fx_VibSkip:
        jmp Fx_Slide

Fx_VibStep:
        dec mVibTimer,x
        bne Fx_Slide
        jsr VibNextPhase
        jmp Fx_Slide

VibNextPhase:
        lda mVibSpeed,x
        sta mVibTimer,x
        lda mVibPhase,x
        bne VibPhase1
        jsr VibBase
        lda #$01
        sta mVibPhase,x
        rts

VibPhase1:
        cmp #$01
        bne VibPhase2
        clc
        lda mBaseFreqLo,x
        adc mVibDepthLo,x
        sta mFreqLo,x
        lda mBaseFreqHi,x
        adc mVibDepthHi,x
        sta mFreqHi,x
        lda #$02
        sta mVibPhase,x
        rts

VibPhase2:
        cmp #$02
        bne VibPhase3
        jsr VibBase
        lda #$03
        sta mVibPhase,x
        rts

VibPhase3:
        cmp #$03
        beq VibMinus
        rts

VibMinus:
        sec
        lda mBaseFreqLo,x
        sbc mVibDepthLo,x
        sta mFreqLo,x
        lda mBaseFreqHi,x
        sbc mVibDepthHi,x
        sta mFreqHi,x
        lda #$00
        sta mVibPhase,x
        rts

VibBase:
        lda mBaseFreqLo,x
        sta mFreqLo,x
        lda mBaseFreqHi,x
        sta mFreqHi,x
        rts

; Slide: after the delay, every mSlideSpeed calls move the frequency
; by the step towards the target.
Fx_Slide:
        lda mOutputOn
        and mVoiceBit
        beq Fx_SlideSkip
        lda mSlideOn
        and mVoiceBit
        beq Fx_SlideSkip
        lda mDrum,x
        bne Fx_SlideSkip
        lda mSlideDelay,x
        beq Fx_SlideTick
        dec mSlideDelay,x

Fx_SlideSkip:
        jmp Fx_WaveAlt

Fx_SlideTick:
        dec mSlideTimer,x
        bne Fx_SlideSkip
        jsr SlideStep
        jmp Fx_WaveAlt

SlideStep:
        lda mSlideSpeed,x
        sta mSlideTimer,x
        lda mSlideUp,x
        bne SlideUp
        jsr SlideDown
        rts

; Never called.
SlideUpUnused:
        jsr SlideUp
        rts

SlideDown:
        lda mSlideToHi,x
        cmp mFreqHi,x
        bne SlideDownCheck
        jmp SlideArrive

SlideDownCheck:
        bcc SlideDownGo
        jmp SlideArrive

SlideDownGo:
        sec
        lda mFreqLo,x
        sbc mSlideStepLo,x
        sta mFreqLo,x
        sta mBaseFreqLo,x
        lda mFreqHi,x
        sbc mSlideStepHi,x
        sta mFreqHi,x
        sta mBaseFreqHi,x
        rts

SlideUp:
        lda mFreqHi,x
        cmp mSlideToHi,x
        bcc SlideUpGo
        jmp SlideArrive

SlideUpGo:
        clc
        lda mFreqLo,x
        adc mSlideStepLo,x
        sta mFreqLo,x
        sta mBaseFreqLo,x
        lda mFreqHi,x
        adc mSlideStepHi,x
        sta mFreqHi,x
        sta mBaseFreqHi,x
        rts

; Target reached: snap to it and switch the slide off, but only if
; mSlideArmed is set (any voice's note sets it, the first arrival
; clears it).
SlideArrive:
        lda mSlideArmed
        beq SlideArriveDone
        lda mSlideToHi,x
        sta mFreqHi,x
        lda mSlideToLo,x
        sta mFreqLo,x
        lda #$00
        sta mSlideArmed
        lda mVoiceBit
        eor #$FF
        and mSlideOn
        sta mSlideOn

SlideArriveDone:
        rts

; Waveform alternation: after the delay, every mWaveAltSpeed calls
; write mWaveA / mWaveB (keeping the gate bit) to the control register.
Fx_WaveAlt:
        lda mOutputOn
        and mVoiceBit
        beq FxDone
        lda mWaveAltOn
        and mVoiceBit
        beq FxDone
        lda mDrum,x
        bne FxDone
        lda mWaveAltDelay,x
        beq Fx_WaveAltTick
        dec mWaveAltDelay,x
        jmp FxDone

Fx_WaveAltTick:
        dec mWaveAltTimer,x
        bne FxDone
        jsr WaveAltFlip
        jmp FxDone

WaveAltFlip:
        lda mWaveAltSpeed,x
        sta mWaveAltTimer,x
        lda mWaveAltPhase,x
        bne WaveAltB
        lda #$01
        sta mWaveAltPhase,x
        lda mCtrl,x
        and #$01
        ora mWaveA,x

WaveAltWrite:
        cpx #$00
        bne WaveAltV2
        sta SID_V1_CTRL
        rts

WaveAltV2:
        cpx #$01
        bne WaveAltV3
        sta SID_V2_CTRL
        rts

WaveAltV3:
        sta SID_V3_CTRL
        rts

WaveAltB:
        lda #$00
        sta mWaveAltPhase,x
        lda mCtrl,x
        and #$01
        ora mWaveB                          ; BUG: no ,x -- every voice uses voice 1's second waveform
        jmp WaveAltWrite

FxDone:
        rts

; Write frequency, pulse width, AD and SR of every voice whose output
; is on and which is not playing a drum.
WriteRegs:
        lda mOutputOn
        and #$01
        beq WriteRegs_V2
        ldx #$00
        ldy #$00
        lda mDrum,x
        bne WriteRegs_V2
        jsr WriteVoice

WriteRegs_V2:
        lda mOutputOn
        and #$02
        beq WriteRegs_V3
        ldx #$01
        ldy #$07
        lda mDrum,x
        bne WriteRegs_V3
        jsr WriteVoice

WriteRegs_V3:
        lda mOutputOn
        and #$04
        beq WriteRegs_Done
        ldx #$02
        ldy #$0E
        lda mDrum,x
        bne WriteRegs_Done
        jsr WriteVoice

WriteRegs_Done:
        rts

; X = voice, Y = register offset.
WriteVoice:
        lda mFreqHi,x
        sta SID_V1_FREQ_HI,y
        lda mFreqLo,x
        sta SID_V1_FREQ_LO,y
        lda mPwHi,x
        sta SID_V1_PW_HI,y
        lda mPwLo,x
        sta SID_V1_PW_LO,y
        lda mAD,x
        sta SID_V1_AD,y
        lda mSR,x
        sta SID_V1_SR,y
        rts

; PATTERNS: every mSpeed calls, run voices 1, 2, 3.
Patterns:
        dec mSpeedCount
        beq Patterns_Tick
        rts

Patterns_Tick:
        lda mSpeed
        sta mSpeedCount
        lda mTrackOn
        and #$01
        bne V1_Read
        jmp V2_Start

; Voice 1 (pattern pointer zPat1).
V1_Read:
        ldy #$00
        jsr SelectV1
        lda zPat1
        sta zUnused4D
        lda zPat1+1
        sta zUnused4D+1
        jsr CountNote
        bcs V2_Start
        beq V1_Event
        jmp V2_Start

V1_Event:
        lda (zPat1),y
        bne V1_NotEnd
        jsr NextPattern
        jmp V1_Read

V1_NotEnd:
        cmp #$F0
        bcc V1_NotDrum
        iny
        lda (zPat1),y
        sta mDrumLen
        dey
        lda (zPat1),y
        iny
        jsr Drum
        jmp V1_Advance

V1_NotDrum:
        cmp #$C8
        bcc V1_Note
        jsr Command
        jmp V1_Read

V1_Note:
        sta mDuration
        iny
        lda (zPat1),y
        beq V1_Gate
        jsr NoteToFreq
        jsr SetNoteFreq
        jsr NoteResetFx
        lda mOutputOn
        and #$01
        bne V1_Gate
        jmp V1_Nop

V1_Gate:
        txa
        pha
        ldx mWave
        stx SID_V1_CTRL
        stx mCtrl
        lda (zPat1),y
        beq V1_GateDone
        inx
        stx SID_V1_CTRL
        stx mCtrl

V1_GateDone:
        pla
        tax

V1_Nop:
        nop                                 ; NOP (also at the same place for voices 2 and 3)

V1_Advance:
        iny
        clc
        tya
        adc zPat1
        sta zPat1
        lda zPat1+1
        adc #$00
        sta zPat1+1

; Voice 2 (zPat2).
V2_Start:
        lda mTrackOn
        and #$02
        bne V2_Read
        jmp V3_Start

V2_Read:
        ldy #$00
        jsr SelectV2
        lda zPat2
        sta zUnused4D
        lda zPat2+1
        sta zUnused4D+1
        jsr CountNote
        bcs V3_Start
        beq V2_Event
        jmp V3_Start

V2_Event:
        lda (zPat2),y
        bne V2_NotEnd
        jsr NextPattern
        jmp V2_Start

V2_NotEnd:
        cmp #$F0
        bcc V2_NotDrum
        iny
        lda (zPat2),y
        sta mDrumLen+1
        dey
        lda (zPat2),y
        iny
        jsr Drum
        jmp V2_Advance

V2_NotDrum:
        cmp #$C8
        bcc V2_Note
        jsr Command
        jmp V2_Start

V2_Note:
        sta mDuration+1
        iny
        lda (zPat2),y
        beq V2_Gate
        jsr NoteToFreq
        jsr SetNoteFreq
        jsr NoteResetFx
        lda mOutputOn
        and #$02
        bne V2_Gate
        jmp V2_Nop

V2_Gate:
        txa
        pha
        ldx mWave+1
        stx SID_V2_CTRL
        stx mCtrl+1
        lda (zPat2),y
        beq V2_GateDone
        inx
        stx SID_V2_CTRL
        stx mCtrl+1

V2_GateDone:
        pla
        tax

V2_Nop:
        nop

V2_Advance:
        iny
        clc
        tya
        adc zPat2
        sta zPat2
        lda zPat2+1
        adc #$00
        sta zPat2+1

; Voice 3 (zPat3).
V3_Start:
        lda mTrackOn
        and #$04
        bne V3_Read
        rts

V3_Read:
        ldy #$00
        jsr SelectV3
        lda zPat3
        sta zUnused4D
        lda zPat3+1
        sta zUnused4D+1
        jsr CountNote
        bcs V3_Exit
        beq V3_Event

V3_Exit:
        rts

V3_Event:
        lda (zPat3),y
        bne V3_NotEnd
        jsr NextPattern
        jmp V3_Start

V3_NotEnd:
        cmp #$F0
        bcc V3_NotDrum
        iny
        lda (zPat3),y
        sta mDrumLen+2
        dey
        lda (zPat3),y
        iny
        jsr Drum
        jmp V3_Advance

V3_NotDrum:
        cmp #$C8
        bcc V3_Note
        jsr Command
        jmp V3_Start

V3_Note:
        sta mDuration+2
        iny
        lda (zPat3),y
        beq V3_Gate
        jsr NoteToFreq
        jsr SetNoteFreq
        jsr NoteResetFx
        lda mOutputOn
        and #$04
        bne V3_Gate
        jmp V3_Nop

V3_Gate:
        txa
        pha
        ldx mWave+2
        stx SID_V3_CTRL
        stx mCtrl+2
        lda (zPat3),y
        beq V3_GateDone
        inx
        stx SID_V3_CTRL
        stx mCtrl+2

V3_GateDone:
        pla
        tax

V3_Nop:
        nop

V3_Advance:
        iny
        clc
        tya
        adc zPat3
        sta zPat3
        lda zPat3+1
        adc #$00
        sta zPat3+1
        rts

; A = note (bits 0-3 semitone 1-12, bits 4-6 octave) -> mNoteHi/Lo.
; FreqTable holds octave 5 (PAL tuned).
NoteToFreq:
        sta mNoteTemp
        and #$0F
        asl a
        stx mSaveX
        tax
        lda FreqTable,x
        sta mNoteHi
        inx
        lda FreqTable,x
        sta mNoteLo
        lda mNoteTemp
        and #$70
        lsr a
        lsr a
        lsr a
        lsr a
        cmp #$05
        beq NoteToFreq_Done
        bcc NoteToFreq_Down
        clc
        asl mNoteLo
        rol mNoteHi
        cmp #$06
        beq NoteToFreq_Done
        clc
        asl mNoteLo
        rol mNoteHi
        jmp NoteToFreq_Done

NoteToFreq_Down:
        tax
        lda OctaveShift,x
        tax

NoteToFreq_Shift:
        clc
        lsr mNoteHi
        ror mNoteLo
        dex
        bpl NoteToFreq_Shift

NoteToFreq_Done:
        ldx mSaveX
        rts

; Frequency and vibrato base = the note.
SetNoteFreq:
        lda mNoteHi
        sta mFreqHi,x
        sta mBaseFreqHi,x
        lda mNoteLo
        sta mFreqLo,x
        sta mBaseFreqLo,x
        rts

; Octave 5 frequencies, big-endian, index = semitone. PAL values:
; C5 = $22D2 = 523.5 Hz on a PAL C64.
FreqTable:
        .dbyt $0000                         ; (0)  semitone 0: silent
        .dbyt $22D2                         ; C-5  523.5 Hz PAL
        .dbyt $24D2                         ; C#5  553.5 Hz PAL
        .dbyt $2714                         ; D-5  587.5 Hz PAL
        .dbyt $2964                         ; D#5  622.3 Hz PAL
        .dbyt $2BE8                         ; E-5  660.1 Hz PAL
        .dbyt $2E78                         ; F-5  698.6 Hz PAL
        .dbyt $313C                         ; F#5  740.2 Hz PAL
        .dbyt $3428                         ; G-5  784.1 Hz PAL
        .dbyt $3750                         ; G#5  831.6 Hz PAL
        .dbyt $3A96                         ; A-5  880.8 Hz PAL
        .dbyt $3E19                         ; A#5  933.6 Hz PAL
        .dbyt $41C8                         ; B-5  988.9 Hz PAL

OctaveShift:
        .byte $04,$03,$02,$01,$00           ; octave 0-4: shift right this + 1 times

; X = voice. Drum playing: run it, return C=1. Otherwise count the
; note down, release the gate at mReleaseAt, return C=0 and Z=1 when
; the next event is due.
CountNote:
        lda mDrum,x
        beq CountNote_Tick
        jsr Drum
        sec
        rts

CountNote_Tick:
        dec mDuration,x
        lda mOutputOn
        and mVoiceBit
        beq CountNote_Done
        lda mDuration,x
        cmp mReleaseAt,x
        beq CountNote_Release
        bcc CountNote_Release
        jmp CountNote_Done

CountNote_Release:
        lda mWave,x
        stx mSaveX
        ldx mRegOfs
        sta SID_V1_CTRL,x
        ldx mSaveX
        sta mCtrl,x

CountNote_Done:
        lda mDuration,x
        clc
        rts

; New note: restart the effect delays (and the pulse width if
; mPwResetOn), arm the slide.
NoteResetFx:
        lda mTrillDelaySet,x
        sta mTrillDelay,x
        lda #$00
        sta mTrillUp,x
        lda mPwDelaySet,x
        sta mPwDelay,x
        lda mPwResetOn
        and mVoiceBit
        beq NoteResetFx_NoPw
        lda mPwStartHi,x
        sta mPwHi,x
        lda mPwStartLo,x
        sta mPwLo,x

NoteResetFx_NoPw:
        lda mVibDelaySet,x
        sta mVibDelay,x
        lda mSlideDelaySet,x
        sta mSlideDelay,x
        lda mWaveAltDelaySet,x
        sta mWaveAltDelay,x
        lda #$00
        sta mWaveAltPhase,x
        lda #$01
        sta mSlideArmed
        rts

; End of pattern: next pointer from the order list (high byte 0 =
; restart the list).
NextPattern:
        lda mOrderLo,x
        sta zOrder
        lda mOrderHi,x
        sta zOrder+1
        ldy mOrderIdx,x
        lda (zOrder),y
        cpx #$00
        bne NextPattern_V2
        sta zPat1
        iny
        lda (zOrder),y
        bne NextPattern_V1Set
        ldy #$00
        sty mOrderIdx
        jmp NextPattern

NextPattern_V1Set:
        sta zPat1+1
        jmp NextPattern_Done

NextPattern_V2:
        cpx #$01
        bne NextPattern_V3
        sta zPat2
        iny
        lda (zOrder),y
        bne NextPattern_V2Set
        ldy #$00
        sty mOrderIdx+1
        jmp NextPattern

NextPattern_V2Set:
        sta zPat2+1
        jmp NextPattern_Done

NextPattern_V3:
        sta zPat3
        iny
        lda (zOrder),y
        bne NextPattern_V3Set
        ldy #$00
        sty mOrderIdx+2
        jmp NextPattern

NextPattern_V3Set:
        sta zPat3+1

NextPattern_Done:
        iny
        tya
        sta mOrderIdx,x
        lda #$01
        sta mDuration,x
        rts

; A = target note: store it and pick the direction.
SetSlideTarget:
        jsr NoteToFreq
        ldx mVoice
        lda mNoteLo
        sta mSlideToLo,x
        lda mNoteHi
        sta mSlideToHi,x
        cmp mFreqHi,x
        bcc SetSlideTarget_Down
        beq SetSlideTarget_Down
        lda #$01
        sta mSlideUp,x
        bne SetSlideTarget_Done

SetSlideTarget_Down:
        lda #$00
        sta mSlideUp,x

SetSlideTarget_Done:
        rts

; A = $F0-$FF drum byte, Y = offset: start drum A-$F0 (first step from
; the drum header), or count down the one playing.
Drum:
        sta mCmdByte
        sty mSaveY
        ldx mVoice
        lda mDrum,x
        beq Drum_Start
        jmp Drum_Count

Drum_Start:
        lda #$00
        sta mFreqHi,x
        sta mBaseFreqHi,x
        sta mFreqLo,x
        sta mBaseFreqLo,x
        lda mCmdByte
        sec
        sbc #$F0
        sta mDrum,x
        sta mDrumOfs,x
        inc mDrum,x
        lda mDrum,x
        sta mDrumStepping,x
        clc
        asl mDrumOfs,x
        lda mDrumOfs,x
        tax
        lda DrumTable,x
        sta zCmd
        inx
        lda DrumTable,x
        sta zCmd+1
        ldy #$00
        ldx mRegOfs
        lda mOutputOn
        and mVoiceBit
        beq Drum_Count
        lda (zCmd),y
        sta SID_V1_AD,x
        iny
        lda (zCmd),y
        sta SID_V1_SR,x
        iny
        lda (zCmd),y
        sta SID_V1_PW_HI,x
        iny
        lda (zCmd),y
        sta SID_V1_PW_LO,x
        iny
        lda (zCmd),y
        beq Drum_NoFilter
        lda mVoiceBit
        ora mResFilt
        sta SID_RES_FILT

Drum_NoFilter:
        iny
        lda (zCmd),y
        sta SID_V1_CTRL,x
        clc
        adc #$01
        sta SID_V1_CTRL,x
        iny
        lda (zCmd),y
        sta SID_V1_FREQ_HI,x
        iny
        lda (zCmd),y
        sta SID_V1_FREQ_LO,x
        ldx mVoice
        lda zCmd
        sta mDrumPtrLo,x
        lda zCmd+1
        sta mDrumPtrHi,x
        iny
        tya
        sta mDrumPos,x
        dec mDrumLen,x
        jmp Drum_Exit

Drum_Count:
        ldx mVoice
        dec mDrumLen,x
        bne Drum_Exit
        lda #$00
        sta mDrum,x
        lda #$01
        sta mDuration,x
        jmp Drum_End

; Every mDrumSpeed calls: next step of the drum (control, freq hi,
; freq lo); $FF ends the steps and takes the voice out of the filter.
Drum_Step:
        ldx mVoice
        lda mOutputOn
        and mVoiceBit
        beq Drum_Exit
        lda mDrumStepping,x
        beq Drum_Exit
        ldy mDrumPos,x
        lda mDrumPtrLo,x
        sta zCmd
        lda mDrumPtrHi,x
        sta zCmd+1
        lda (zCmd),y
        cmp #$FF
        bne Drum_WriteStep

Drum_End:
        lda mVoiceBit
        and mResFilt
        bne Drum_EndDone
        lda mVoiceBit
        eor #$FF
        and mResFilt
        sta SID_RES_FILT

Drum_EndDone:
        lda #$00
        sta mDrumStepping,x
        jmp Drum_Exit

Drum_WriteStep:
        ldx mRegOfs
        sta SID_V1_CTRL,x
        iny
        lda (zCmd),y
        sta SID_V1_FREQ_HI,x
        iny
        lda (zCmd),y
        sta SID_V1_FREQ_LO,x
        iny
        ldx mVoice
        tya
        sta mDrumPos,x

Drum_Exit:
        ldy mSaveY
        rts

; A = $C8-$DE: jump through CmdTable with zCmd = pattern pointer.
; Bytes above $DE would jump to garbage.
Command:
        sta mCmdByte
        iny
        lda mCmdByte
        sec
        sbc #$C8
        clc
        asl a
        tax
        lda CmdTable,x
        sta mCmdVector
        inx
        lda CmdTable,x
        sta mCmdVector+1
        ldx mVoice
        bne Command_V2
        lda zPat1
        sta zCmd
        lda zPat1+1
        sta zCmd+1
        jmp (mCmdVector)

Command_V2:
        cpx #$01
        bne Command_V3
        lda zPat2
        sta zCmd
        lda zPat2+1
        sta zCmd+1
        jmp (mCmdVector)

Command_V3:
        lda zPat3
        sta zCmd
        lda zPat3+1
        sta zCmd+1
        jmp (mCmdVector)

CmdTable:
        .word Cmd_Volume                    ; $C8 C_VOLUME
        .word Cmd_Speed                     ; $C9 C_SPEED
        .word Cmd_AD                        ; $CA C_AD
        .word Cmd_SR                        ; $CB C_SR
        .word Cmd_Wave                      ; $CC C_WAVE
        .word Cmd_Pulse                     ; $CD C_PULSE
        .word Cmd_Filter                    ; $CE C_FILTER
        .word Cmd_PwSweep                   ; $CF C_PWSWEEP
        .word Cmd_Trill                     ; $D0 C_TRILL
        .word Cmd_Vibrato                   ; $D1 C_VIBRATO
        .word Cmd_Slide                     ; $D2 C_SLIDE
        .word Cmd_WaveAlt                   ; $D3 C_WAVEALT
        .word Cmd_PwSweepOff                ; $D4 C_PWSWEEP_OFF
        .word Cmd_TrillOff                  ; $D5 C_TRILL_OFF
        .word Cmd_VibratoOff                ; $D6 C_VIBRATO_OFF
        .word Cmd_SlideOff                  ; $D7 C_SLIDE_OFF
        .word Cmd_WaveAltOff                ; $D8 C_WAVEALT_OFF
        .word Cmd_FilterOff                 ; $D9 C_FILTER_OFF
        .word Cmd_Release                   ; $DA C_RELEASE
        .word Cmd_SlideStep                 ; $DB C_SLIDESTEP
        .word Cmd_PwRange                   ; $DC C_PWRANGE
        .word Cmd_DrumSpeed                 ; $DD C_DRUMSPEED
        .word Cmd_Stop                      ; $DE C_STOP

; $C8 C_VOLUME
Cmd_Volume:
        lda mModeVol
        and #$F0
        ora (zCmd),y
        sta SID_MODE_VOL
        sta mModeVol
        jmp Cmd_Done

; $C9 C_SPEED
Cmd_Speed:
        lda (zCmd),y
        sta mSpeed
        jmp Cmd_Done

; $CA C_AD
Cmd_AD:
        lda (zCmd),y
        sta mAD,x
        jmp Cmd_Done

; $CB C_SR
Cmd_SR:
        lda (zCmd),y
        sta mSR,x
        jmp Cmd_Done

; $CC C_WAVE
Cmd_Wave:
        lda (zCmd),y
        sta mWave,x
        jmp Cmd_Done

; $CD C_PULSE
Cmd_Pulse:
        lda (zCmd),y
        sta mPwHi,x
        iny
        lda (zCmd),y
        sta mPwLo,x
        jmp Cmd_Done

; $CE C_FILTER
Cmd_Filter:
        lda mVoiceBit
        ora mResFilt
        sta mResFilt
        sta SID_RES_FILT
        lda (zCmd),y
        ora mModeVol
        sta mModeVol
        sta SID_MODE_VOL
        iny
        lda (zCmd),y
        sta SID_FC_HI
        iny
        lda (zCmd),y
        sta SID_FC_LO
        jmp Cmd_Done

; $CF C_PWSWEEP
Cmd_PwSweep:
        lda mVoiceBit
        ora mPwSweepOn
        sta mPwSweepOn
        lda (zCmd),y
        sta mPwSpeed,x
        iny
        lda (zCmd),y
        sta mPwDelaySet,x
        sta mPwDelay,x
        iny
        lda (zCmd),y
        sta mPwStepHi,x
        iny
        lda (zCmd),y
        sta mPwStepLo,x
        iny
        lda (zCmd),y
        bne Cmd_PwSweep_Reset
        lda mVoiceBit
        eor #$FF
        and mPwResetOn
        sta mPwResetOn
        jmp Cmd_Done

Cmd_PwSweep_Reset:
        lda mVoiceBit
        ora mPwResetOn
        sta mPwResetOn
        jmp Cmd_Done

; $D0 C_TRILL
Cmd_Trill:
        lda mVoiceBit
        ora mTrillOn
        sta mTrillOn
        lda (zCmd),y
        sta mTrillSpeed,x
        iny
        lda (zCmd),y
        sta mTrillDelaySet,x
        sta mTrillDelay,x
        jmp Cmd_Done

; $D1 C_VIBRATO
Cmd_Vibrato:
        lda mVoiceBit
        ora mVibOn
        sta mVibOn
        lda (zCmd),y
        sta mVibSpeed,x
        iny
        lda (zCmd),y
        sta mVibDelaySet,x
        sta mVibDelay,x
        iny
        lda (zCmd),y
        sta mVibDepthHi,x
        iny
        lda (zCmd),y
        sta mVibDepthLo,x
        jmp Cmd_Done

; $D2 C_SLIDE
Cmd_Slide:
        lda mVoiceBit
        ora mSlideOn
        sta mSlideOn
        lda (zCmd),y
        sta mSlideDelaySet,x
        sta mSlideDelay,x
        iny
        lda (zCmd),y
        jsr NoteToFreq
        ldx mVoice
        lda mNoteHi
        sta mFreqHi,x
        lda mNoteLo
        sta mFreqLo,x
        iny
        lda (zCmd),y
        jsr SetSlideTarget
        jmp Cmd_Done

; $D3 C_WAVEALT
Cmd_WaveAlt:
        lda mVoiceBit
        ora mWaveAltOn
        sta mWaveAltOn
        lda (zCmd),y
        sta mWaveAltSpeed,x
        iny
        lda (zCmd),y
        sta mWaveAltDelaySet,x
        sta mWaveAltDelay,x
        iny
        lda (zCmd),y
        sta mWaveA,x
        iny
        lda (zCmd),y
        sta mWaveB,x
        jmp Cmd_Done

; $D4 C_PWSWEEP_OFF
Cmd_PwSweepOff:
        lda mVoiceBit
        eor #$FF
        and mPwSweepOn
        sta mPwSweepOn
        lda mVoiceBit
        eor #$FF
        and mPwResetOn
        sta mPwResetOn
        dey
        jmp Cmd_Done

; $D5 C_TRILL_OFF
Cmd_TrillOff:
        lda mVoiceBit
        eor #$FF
        and mTrillOn
        sta mTrillOn
        dey
        jmp Cmd_Done

; $D6 C_VIBRATO_OFF
Cmd_VibratoOff:
        lda mVoiceBit
        eor #$FF
        and mVibOn
        sta mVibOn
        dey
        jmp Cmd_Done

; $D7 C_SLIDE_OFF
Cmd_SlideOff:
        dey
        jmp Cmd_Done

; $D8 C_WAVEALT_OFF
Cmd_WaveAltOff:
        lda mVoiceBit
        eor #$FF
        and mWaveAltOn
        sta mWaveAltOn
        dey
        jmp Cmd_Done

; $D9 C_FILTER_OFF
Cmd_FilterOff:
        lda mVoiceBit
        eor #$FF
        and mResFilt
        sta mResFilt
        sta SID_RES_FILT
        dey
        jmp Cmd_Done

; $DA C_RELEASE
Cmd_Release:
        lda (zCmd),y
        sta mReleaseAt,x
        jmp Cmd_Done

; $DB C_SLIDESTEP
Cmd_SlideStep:
        lda (zCmd),y
        sta mSlideSpeed,x
        iny
        lda (zCmd),y
        sta mSlideStepHi,x
        iny
        lda (zCmd),y
        sta mSlideStepLo,x
        jmp Cmd_Done

; $DC C_PWRANGE
Cmd_PwRange:
        lda (zCmd),y
        sta mPwStartHi,x
        iny
        lda (zCmd),y
        sta mPwStartLo,x
        iny
        lda (zCmd),y
        sta mPwLimitHi,x
        iny
        lda (zCmd),y
        sta mPwLimitLo,x
        jmp Cmd_Done

; $DD C_DRUMSPEED
Cmd_DrumSpeed:
        lda (zCmd),y
        sta mDrumSpeed
        sta mDrumCount
        jmp Cmd_Done

; $DE C_STOP
Cmd_Stop:
        lda #$00
        sta mTrackOn
        sta mOutputOn
        dey
        jmp Cmd_Done

; Pointer += Y + 1, next event in the same call (mDuration = 1).
Cmd_Done:
        lda #$01
        ldx mVoice
        sta mDuration,x
        clc
        iny
        tya
        adc zCmd
        sta zCmd
        lda zCmd+1
        adc #$00
        sta zCmd+1
        ldx mVoice
        bne Cmd_Done_V2
        lda zCmd
        sta zPat1
        lda zCmd+1
        sta zPat1+1
        rts

Cmd_Done_V2:
        cpx #$01
        bne Cmd_Done_V3
        lda zCmd
        sta zPat2
        lda zCmd+1
        sta zPat2+1
        rts

Cmd_Done_V3:
        lda zCmd
        sta zPat3
        lda zCmd+1
        sta zPat3+1
        rts

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $69,$00,$85,$4C,$60

; PLAY (PSID play address). Patterns, registers, effects, registers again,
; drum steps, sound effects.
Play:
        jsr Patterns
        jsr WriteRegs
        jsr Effects
        jsr WriteRegs
        dec mDrumCount
        bne Play_Sfx
        lda mDrumSpeed
        sta mDrumCount
        jsr SelectV1
        jsr Drum_Step
        jsr SelectV2
        jsr Drum_Step
        jsr SelectV3
        jsr Drum_Step

Play_Sfx:
        jsr Sfx_Update
        rts

; Set mVoice, mRegOfs, mVoiceBit.
SelectV1:
        ldx #$00
        stx mVoice
        stx mRegOfs
        lda #$01
        sta mVoiceBit
        rts

SelectV2:
        ldx #$01
        stx mVoice
        lda #$07
        sta mRegOfs
        lda #$02
        sta mVoiceBit
        rts

SelectV3:
        ldx #$02
        stx mVoice
        lda #$0E
        sta mRegOfs
        lda #$04
        sta mVoiceBit
        rts

; DRUMS ($F0-$F4 in patterns; all five point at the same drum). Header:
; AD, SR, pulse hi, pulse lo, filter flag, control, freq hi, freq lo; then
; steps of control, freq hi, freq lo until $FF.
DrumTable:
        .word Drum0, Drum0, Drum0, Drum0, Drum0

Drum0:
        .byte $09,$49,$00,$00,$00,$80,$14,$00 ; AD $09 SR $49 pulse $0000 filter no, control $80, freq $1400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $81,$14,$00                   ; control $81, freq $1400
        .byte $81,$64,$00                   ; control $81, freq $6400
        .byte $80,$14,$00                   ; control $80, freq $1400
        .byte $80,$64,$00                   ; control $80, freq $6400
        .byte $80,$14,$00                   ; control $80, freq $1400
        .byte $FF                           ; end
; ---- 3 byte(s) not referenced by the sound engine ----
        .byte $FF,$FF,$FF

; SOUND EFFECT VARIABLES
sRequest:
        .byte $00                           ; effect to start (set by the game), 0 = none

sActive:
        .byte $00                           ; effect number * 2 while one plays

sPos:
        .byte $31                           ; offset of the next step

sPtr:
        .byte $70,$B4                       ; effect data

sTwoVoices:
        .byte $00                           ; 1 = the effect also uses voice 2

sSpeed:
        .byte $04                           ; calls per step

sCount:
        .byte $04

; SOUND EFFECTS (not used by the rip). The game writes an effect
; number to sRequest; effects take voice 1 (and voice 2 if the header
; says so). Only voice 1 of the music is muted while one plays.
Sfx_Update:
        lda sRequest
        bne Sfx_Start
        lda sActive
        beq Sfx_UpdateDone
        jmp Sfx_Step

Sfx_UpdateDone:
        rts

; A = effect number: read the header, write the first step.
Sfx_Start:
        clc
        asl a
        sta sActive
        tax
        lda SfxTable,x
        sta zSfx
        inx
        lda SfxTable,x
        sta zSfx+1
        ldy #$00
        sty sRequest
        lda #$FE                            ; mute music voice 1 only
        and mOutputOn
        sta mOutputOn
        lda (zSfx),y
        sta sSpeed
        sta sCount
        iny
        lda (zSfx),y
        sta SID_V1_AD
        iny
        lda (zSfx),y
        sta SID_V1_SR
        iny
        lda (zSfx),y
        sta SID_V1_PW_HI
        iny
        lda (zSfx),y
        sta SID_V1_PW_LO
        lda #$00
        sta SID_V1_CTRL
        iny
        lda (zSfx),y
        beq Sfx_NoFilter
        sta SID_RES_FILT
        iny
        lda (zSfx),y
        and #$F0
        ora mModeVol
        sta SID_MODE_VOL
        iny
        lda (zSfx),y
        sta SID_FC_HI
        iny
        lda (zSfx),y
        sta SID_FC_LO

Sfx_NoFilter:
        iny
        lda (zSfx),y
        beq Sfx_OneVoice
        iny
        lda (zSfx),y
        sta SID_V2_AD
        iny
        lda (zSfx),y
        sta SID_V2_SR
        iny
        lda (zSfx),y
        sta SID_V2_PW_HI
        iny
        lda (zSfx),y
        sta SID_V2_PW_LO
        lda #$00
        sta SID_V2_CTRL
        lda #$01
        sta sTwoVoices
        jmp Sfx_FirstStep

Sfx_OneVoice:
        lda #$00
        sta sTwoVoices

Sfx_FirstStep:
        iny
        lda (zSfx),y
        sta SID_V1_CTRL
        iny
        lda (zSfx),y
        sta SID_V1_FREQ_HI
        iny
        lda (zSfx),y
        sta SID_V1_FREQ_LO
        lda sTwoVoices
        beq Sfx_SavePos
        iny
        lda (zSfx),y
        sta SID_V2_CTRL
        iny
        lda (zSfx),y
        sta SID_V2_FREQ_HI
        iny
        lda (zSfx),y
        sta SID_V2_FREQ_LO

Sfx_SavePos:
        iny
        sty sPos
        lda zSfx
        sta sPtr
        lda zSfx+1
        sta sPtr+1
        rts

; Every sSpeed calls: next step, $FF = end (restores the filter
; registers and turns music voices 1 and 2 back on).
Sfx_Step:
        dec sCount
        beq Sfx_StepGo
        rts

Sfx_StepGo:
        lda sSpeed
        sta sCount
        ldy sPos
        lda sPtr
        sta zSfx
        lda sPtr+1
        sta zSfx+1
        lda (zSfx),y
        cmp #$FF
        bne Sfx_WriteStep
        lda #$03                            ; turns music voices 1 AND 2 back on
        ora mOutputOn
        sta mOutputOn
        lda mModeVol
        sta SID_MODE_VOL
        lda mResFilt
        sta SID_RES_FILT
        lda mCutoffHi
        sta SID_FC_HI
        lda mCutoffLo
        sta SID_FC_LO
        lda #$00
        sta sRequest
        sta sActive
        rts

Sfx_WriteStep:
        sta SID_V1_CTRL
        iny
        lda (zSfx),y
        sta SID_V1_FREQ_HI
        iny
        lda (zSfx),y
        sta SID_V1_FREQ_LO
        lda sTwoVoices
        beq Sfx_WriteDone
        iny
        lda (zSfx),y
        sta SID_V2_CTRL
        iny
        lda (zSfx),y
        sta SID_V2_FREQ_HI
        iny
        lda (zSfx),y
        sta SID_V2_FREQ_LO

Sfx_WriteDone:
        jmp Sfx_SavePos

; SOUND EFFECT TABLE (sRequest 1-15; entry 0 is never used). Effect:
; speed, AD, SR, pulse hi, pulse lo; filter (0, or routing, mode, cutoff
; hi, lo); voice 2 (0, or nonzero, AD, SR, pulse hi, pulse lo); then steps
; of control, freq hi, freq lo (+ the same for voice 2) until $FF.
SfxTable:
        .word Sfx00, Sfx00, Sfx02, Sfx03    ; effects 0-3
        .word Sfx03, Sfx05, Sfx06, Sfx07    ; effects 4-7
        .word Sfx08, Sfx09, Sfx10, Sfx10    ; effects 8-11
        .word Sfx10, Sfx10, Sfx10, Sfx10    ; effects 12-15

Sfx00:
        .byte $03,$0A,$09,$08,$08           ; speed 3, voice 1 AD $0A SR $09 pulse $0808
        .byte $00                           ; no filter
        .byte $01,$0A,$09,$06,$06           ; voice 2: AD $0A SR $09 pulse $0606
        .byte $40,$64,$00,$40,$C8,$00       ; ctrl $40 freq $6400 | ctrl $40 freq $C800
        .byte $41,$2F,$00,$41,$D3,$00       ; ctrl $41 freq $2F00 | ctrl $41 freq $D300
        .byte $41,$8E,$00,$41,$E5,$00       ; ctrl $41 freq $8E00 | ctrl $41 freq $E500
        .byte $41,$92,$00,$41,$D6,$00       ; ctrl $41 freq $9200 | ctrl $41 freq $D600
        .byte $41,$EE,$00,$41,$EE,$00       ; ctrl $41 freq $EE00 | ctrl $41 freq $EE00
        .byte $41,$F9,$00,$41,$FE,$00       ; ctrl $41 freq $F900 | ctrl $41 freq $FE00
        .byte $40,$C6,$00,$40,$6B,$00       ; ctrl $40 freq $C600 | ctrl $40 freq $6B00
        .byte $40,$D4,$00,$40,$CF,$00       ; ctrl $40 freq $D400 | ctrl $40 freq $CF00
        .byte $40,$FE,$00,$40,$6D,$00       ; ctrl $40 freq $FE00 | ctrl $40 freq $6D00
        .byte $40,$A8,$00,$40,$8C,$00       ; ctrl $40 freq $A800 | ctrl $40 freq $8C00
        .byte $40,$8F,$00,$40,$FE,$00       ; ctrl $40 freq $8F00 | ctrl $40 freq $FE00
        .byte $40,$FE,$00,$40,$F9,$00       ; ctrl $40 freq $FE00 | ctrl $40 freq $F900
        .byte $40,$00,$00,$40,$00,$00       ; ctrl $40 freq $0000 | ctrl $40 freq $0000
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx02:
        .byte $02,$08,$87,$03,$03           ; speed 2, voice 1 AD $08 SR $87 pulse $0303
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $40,$5A,$00                   ; ctrl $40 freq $5A00
        .byte $41,$5A,$00                   ; ctrl $41 freq $5A00
        .byte $41,$58,$00                   ; ctrl $41 freq $5800
        .byte $41,$56,$00                   ; ctrl $41 freq $5600
        .byte $41,$54,$00                   ; ctrl $41 freq $5400
        .byte $41,$52,$00                   ; ctrl $41 freq $5200
        .byte $41,$50,$00                   ; ctrl $41 freq $5000
        .byte $41,$4E,$00                   ; ctrl $41 freq $4E00
        .byte $41,$4C,$00                   ; ctrl $41 freq $4C00
        .byte $41,$4A,$00                   ; ctrl $41 freq $4A00
        .byte $41,$48,$00                   ; ctrl $41 freq $4800
        .byte $41,$46,$00                   ; ctrl $41 freq $4600
        .byte $41,$44,$00                   ; ctrl $41 freq $4400
        .byte $41,$42,$00                   ; ctrl $41 freq $4200
        .byte $41,$42,$00                   ; ctrl $41 freq $4200
        .byte $40,$44,$00                   ; ctrl $40 freq $4400
        .byte $40,$46,$00                   ; ctrl $40 freq $4600
        .byte $40,$48,$00                   ; ctrl $40 freq $4800
        .byte $40,$4A,$00                   ; ctrl $40 freq $4A00
        .byte $40,$4C,$00                   ; ctrl $40 freq $4C00
        .byte $40,$4E,$00                   ; ctrl $40 freq $4E00
        .byte $40,$50,$00                   ; ctrl $40 freq $5000
        .byte $40,$50,$00                   ; ctrl $40 freq $5000
        .byte $40,$00,$00                   ; ctrl $40 freq $0000
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx03:
        .byte $08,$05,$C0,$08,$08           ; speed 8, voice 1 AD $05 SR $C0 pulse $0808
        .byte $00                           ; no filter
        .byte $01,$05,$80,$04,$04           ; voice 2: AD $05 SR $80 pulse $0404
        .byte $40,$1C,$31,$40,$13,$EF       ; ctrl $40 freq $1C31 | ctrl $40 freq $13EF
        .byte $41,$1C,$31,$41,$14,$EF       ; ctrl $41 freq $1C31 | ctrl $41 freq $14EF
        .byte $41,$1C,$31,$41,$14,$EF       ; ctrl $41 freq $1C31 | ctrl $41 freq $14EF
        .byte $40,$1C,$31,$40,$14,$EF       ; ctrl $40 freq $1C31 | ctrl $40 freq $14EF
        .byte $40,$1C,$31,$40,$14,$EF       ; ctrl $40 freq $1C31 | ctrl $40 freq $14EF
        .byte $41,$1C,$31,$41,$14,$EF       ; ctrl $41 freq $1C31 | ctrl $41 freq $14EF
        .byte $41,$1C,$31,$41,$14,$EF       ; ctrl $41 freq $1C31 | ctrl $41 freq $14EF
        .byte $40,$1C,$31,$40,$14,$EF       ; ctrl $40 freq $1C31 | ctrl $40 freq $14EF
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx05:
        .byte $03,$09,$C8,$00,$00           ; speed 3, voice 1 AD $09 SR $C8 pulse $0000
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $80,$0A,$00                   ; ctrl $80 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $81,$0A,$00                   ; ctrl $81 freq $0A00
        .byte $80,$0A,$00                   ; ctrl $80 freq $0A00
        .byte $80,$0A,$00                   ; ctrl $80 freq $0A00
        .byte $80,$00,$00                   ; ctrl $80 freq $0000
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx06:
        .byte $04,$04,$88,$04,$04           ; speed 4, voice 1 AD $04 SR $88 pulse $0404
        .byte $00                           ; no filter
        .byte $01,$04,$48,$04,$04           ; voice 2: AD $04 SR $48 pulse $0404
        .byte $40,$0E,$EF,$40,$11,$C3       ; ctrl $40 freq $0EEF | ctrl $40 freq $11C3
        .byte $41,$0E,$EF,$41,$11,$C3       ; ctrl $41 freq $0EEF | ctrl $41 freq $11C3
        .byte $40,$0E,$EF,$36,$11,$C3       ; ctrl $40 freq $0EEF | ctrl $36 freq $11C3
        .byte $41,$11,$C3,$41,$15,$1F       ; ctrl $41 freq $11C3 | ctrl $41 freq $151F
        .byte $40,$11,$C3,$40,$15,$1F       ; ctrl $40 freq $11C3 | ctrl $40 freq $151F
        .byte $41,$15,$1F,$41,$19,$1E       ; ctrl $41 freq $151F | ctrl $41 freq $191E
        .byte $40,$15,$1F,$40,$19,$1E       ; ctrl $40 freq $151F | ctrl $40 freq $191E
        .byte $41,$19,$1E,$41,$21,$87       ; ctrl $41 freq $191E | ctrl $41 freq $2187
        .byte $40,$19,$1E,$40,$21,$87       ; ctrl $40 freq $191E | ctrl $40 freq $2187
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx07:
        .byte $06,$04,$CA,$00,$64           ; speed 6, voice 1 AD $04 SR $CA pulse $0064
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $40,$01,$00                   ; ctrl $40 freq $0100
        .byte $41,$01,$64                   ; ctrl $41 freq $0164
        .byte $41,$01,$6E                   ; ctrl $41 freq $016E
        .byte $41,$01,$78                   ; ctrl $41 freq $0178
        .byte $41,$01,$82                   ; ctrl $41 freq $0182
        .byte $41,$01,$8C                   ; ctrl $41 freq $018C
        .byte $41,$01,$96                   ; ctrl $41 freq $0196
        .byte $41,$01,$A0                   ; ctrl $41 freq $01A0
        .byte $41,$01,$AA                   ; ctrl $41 freq $01AA
        .byte $41,$01,$B4                   ; ctrl $41 freq $01B4
        .byte $41,$01,$BE                   ; ctrl $41 freq $01BE
        .byte $41,$01,$C8                   ; ctrl $41 freq $01C8
        .byte $41,$01,$C8                   ; ctrl $41 freq $01C8
        .byte $40,$01,$C8                   ; ctrl $40 freq $01C8
        .byte $40,$01,$C8                   ; ctrl $40 freq $01C8
        .byte $40,$01,$C8                   ; ctrl $40 freq $01C8
        .byte $40,$01,$C8                   ; ctrl $40 freq $01C8
        .byte $40,$00,$00                   ; ctrl $40 freq $0000
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx08:
        .byte $02,$29,$F0,$03,$03           ; speed 2, voice 1 AD $29 SR $F0 pulse $0303
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $41,$19,$1E                   ; ctrl $41 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $41,$1F,$A5                   ; ctrl $41 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $41,$25,$A2                   ; ctrl $41 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $41,$19,$1E                   ; ctrl $41 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $41,$1F,$A5                   ; ctrl $41 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $41,$25,$A2                   ; ctrl $41 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $41,$19,$1E                   ; ctrl $41 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $40,$19,$1E                   ; ctrl $40 freq $191E
        .byte $41,$1F,$A5                   ; ctrl $41 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $40,$1F,$A5                   ; ctrl $40 freq $1FA5
        .byte $41,$25,$A2                   ; ctrl $41 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $40,$25,$A2                   ; ctrl $40 freq $25A2
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx09:
        .byte $04,$08,$F0,$00,$00           ; speed 4, voice 1 AD $08 SR $F0 pulse $0000
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $10,$21,$87                   ; ctrl $10 freq $2187
        .byte $11,$21,$87                   ; ctrl $11 freq $2187
        .byte $10,$21,$87                   ; ctrl $10 freq $2187
        .byte $11,$1F,$A5                   ; ctrl $11 freq $1FA5
        .byte $10,$1F,$A5                   ; ctrl $10 freq $1FA5
        .byte $11,$21,$87                   ; ctrl $11 freq $2187
        .byte $10,$21,$87                   ; ctrl $10 freq $2187
        .byte $11,$19,$1E                   ; ctrl $11 freq $191E
        .byte $10,$19,$1E                   ; ctrl $10 freq $191E
        .byte $11,$21,$87                   ; ctrl $11 freq $2187
        .byte $10,$21,$87                   ; ctrl $10 freq $2187
        .byte $11,$10,$C3                   ; ctrl $11 freq $10C3
        .byte $11,$10,$C3                   ; ctrl $11 freq $10C3
        .byte $10,$10,$C3                   ; ctrl $10 freq $10C3
        .byte $FF                           ; end
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $FF

Sfx10:
        .byte $04,$01,$B8,$08,$08           ; speed 4, voice 1 AD $01 SR $B8 pulse $0808
        .byte $00                           ; no filter
        .byte $00                           ; voice 1 only
        .byte $40,$0A,$8F                   ; ctrl $40 freq $0A8F
        .byte $41,$0A,$96                   ; ctrl $41 freq $0A96
        .byte $41,$0A,$AA                   ; ctrl $41 freq $0AAA
        .byte $41,$0A,$BE                   ; ctrl $41 freq $0ABE
        .byte $41,$0A,$D2                   ; ctrl $41 freq $0AD2
        .byte $41,$0A,$E6                   ; ctrl $41 freq $0AE6
        .byte $41,$0A,$FA                   ; ctrl $41 freq $0AFA
        .byte $41,$0B,$00                   ; ctrl $41 freq $0B00
        .byte $41,$0B,$14                   ; ctrl $41 freq $0B14
        .byte $41,$0B,$28                   ; ctrl $41 freq $0B28
        .byte $41,$0B,$3C                   ; ctrl $41 freq $0B3C
        .byte $41,$0B,$50                   ; ctrl $41 freq $0B50
        .byte $41,$0B,$64                   ; ctrl $41 freq $0B64
        .byte $41,$0B,$78                   ; ctrl $41 freq $0B78
        .byte $41,$0B,$8C                   ; ctrl $41 freq $0B8C
        .byte $41,$0B,$A0                   ; ctrl $41 freq $0BA0
        .byte $40,$0B,$B4                   ; ctrl $40 freq $0BB4
        .byte $40,$0B,$C8                   ; ctrl $40 freq $0BC8
        .byte $40,$0B,$DA                   ; ctrl $40 freq $0BDA
        .byte $FF                           ; end
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; SONG INIT ROUTINES: order list pointers and the first pattern of
; each voice, then the common part. They leave interrupts disabled
; (SEI).
Song0_Init:
        sei
        lda #<S0_Order1
        sta mOrderLo
        lda #>S0_Order1
        sta mOrderHi
        lda #<S0_Order2
        sta mOrderLo+1
        lda #>S0_Order2
        sta mOrderHi+1
        lda #<S0_Order3
        sta mOrderLo+2
        lda #>S0_Order3
        sta mOrderHi+2
        lda #<S0_Pat00
        sta zPat1
        lda #>S0_Pat00
        sta zPat1+1
        lda #<S0_Pat08
        sta zPat2
        lda #>S0_Pat08
        sta zPat2+1
        lda #<S0_Pat12
        sta zPat3
        lda #>S0_Pat12
        sta zPat3+1

; Filter registers from the shadows, all voices on, durations 2,
; order index 2 (entry 0 is the pattern set above), speed 4.
Song_InitCommon:
        lda mModeVol
        sta SID_MODE_VOL
        lda mResFilt
        sta SID_RES_FILT
        lda mCutoffHi
        sta SID_FC_HI
        lda mCutoffLo
        sta SID_FC_LO
        lda #$07
        sta mOutputOn
        sta mTrackOn
        lda #$02
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        lda #$04
        sta mSpeed
        sta mSpeedCount
        lda #$00
        sta mDrum
        sta mDrum+1
        sta mDrum+2
        nop
        rts

; Song 0, voice 1 order list (high byte 0 = restart).
S0_Order1:
        .word S0_Pat00, S0_Pat01, S0_Pat01, S0_Pat02
        .word S0_Pat02, S0_Pat03, S0_Pat01, S0_Pat02
        .word S0_Pat03, S0_Pat04, S0_Pat00, S0_Pat00
        .word S0_Pat00, S0_Pat00, S0_Pat05, S0_Pat06
        .word S0_Pat07, S0_Pat00
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 0, voice 2 order list (high byte 0 = restart).
S0_Order2:
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat08
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat09
        .word S0_Pat08, S0_Pat08, S0_Pat08, S0_Pat10
        .word S0_Pat10, S0_Pat10, S0_Pat10, S0_Pat10
        .word S0_Pat10, S0_Pat10, S0_Pat10, S0_Pat10
        .word S0_Pat10, S0_Pat11, S0_Pat11, S0_Pat08
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 0, voice 3 order list (high byte 0 = restart).
S0_Order3:
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat12
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat13
        .word S0_Pat12, S0_Pat12, S0_Pat12, S0_Pat14
        .word S0_Pat14, S0_Pat14, S0_Pat14, S0_Pat14
        .word S0_Pat14, S0_Pat14, S0_Pat14, S0_Pat14
        .word S0_Pat14, S0_Pat15, S0_Pat15, S0_Pat12
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S0_Pat00:
        .byte C_VOLUME,$0F                  ; volume $0F (filter mode kept)
        .byte C_SPEED,$04                   ; speed 4 calls/tick
        .byte C_AD,$01                      ; attack/decay $01
        .byte C_SR,$89                      ; sustain/release $89
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$01,$00,$28,$00 ; pulse sweep: speed 1, delay 1, step $0028, reset 0
        .byte C_PWRANGE,$04,$02,$0C,$00     ; pulse sweep from $0402, back at $0C00
        .byte C_VIBRATO,$02,$28,$01,$64     ; vibrato: speed 2, delay 40, depth $0164
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_DRUMSPEED,$01               ; drum step every 1 calls
        .byte $40,$00                       ; rest   64 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat01:
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $06,$56                       ; F-5     6 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $30,$51                       ; C-5    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $06,$56                       ; F-5     6 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $20,$51                       ; C-5    32 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat02:
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $20,$51                       ; C-5    32 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat03:
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$58                       ; G-5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$58                       ; G-5     6 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $06,$56                       ; F-5     6 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $30,$51                       ; C-5    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$58                       ; G-5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $06,$58                       ; G-5     6 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $06,$56                       ; F-5     6 ticks
        .byte C_SLIDESTEP,$01,$00,$C4       ; slide speed 1, step $00C4
        .byte C_SLIDE,$0F,$54,$51           ; slide: delay 15, from D#5 to C-5
        .byte $08,$54                       ; D#5     8 ticks
        .byte C_SLIDE,$05,$51,$4B           ; slide: delay 5, from C-5 to A#4
        .byte $04,$51                       ; C-5     4 ticks
        .byte C_SLIDE,$04,$51,$54           ; slide: delay 4, from C-5 to D#5
        .byte $02,$51                       ; C-5     2 ticks
        .byte C_SLIDE,$04,$54,$51           ; slide: delay 4, from D#5 to C-5
        .byte $02,$54                       ; D#5     2 ticks
        .byte C_SLIDE,$04,$51,$54           ; slide: delay 4, from C-5 to D#5
        .byte $02,$51                       ; C-5     2 ticks
        .byte C_SLIDE,$04,$54,$51           ; slide: delay 4, from D#5 to C-5
        .byte $02,$54                       ; D#5     2 ticks
        .byte C_SLIDE,$04,$51,$54           ; slide: delay 4, from C-5 to D#5
        .byte $02,$51                       ; C-5     2 ticks
        .byte C_SLIDE,$04,$54,$51           ; slide: delay 4, from D#5 to C-5
        .byte $02,$54                       ; D#5     2 ticks
        .byte $24,$51                       ; C-5    36 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat04:
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $02,$52                       ; C#5     2 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$52                       ; C#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $02,$52                       ; C#5     2 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $30,$48                       ; G-4    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat05:
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$64                       ; D#6     6 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $02,$59                       ; G#5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $30,$56                       ; F-5    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$64                       ; D#6     6 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $02,$59                       ; G#5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $20,$56                       ; F-5    32 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat06:
        .byte $06,$64                       ; D#6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$61                       ; C-6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$64                       ; D#6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$61                       ; C-6     6 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $02,$59                       ; G#5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $30,$56                       ; F-5    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $06,$64                       ; D#6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$61                       ; C-6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$64                       ; D#6     6 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $06,$61                       ; C-6     6 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $02,$59                       ; G#5     2 ticks
        .byte $06,$5B                       ; A#5     6 ticks
        .byte C_SLIDE,$0F,$59,$56           ; slide: delay 15, from G#5 to F-5
        .byte $08,$59                       ; G#5     8 ticks
        .byte C_SLIDE,$05,$56,$54           ; slide: delay 5, from F-5 to D#5
        .byte $04,$56                       ; F-5     4 ticks
        .byte C_SLIDE,$04,$56,$59           ; slide: delay 4, from F-5 to G#5
        .byte $02,$56                       ; F-5     2 ticks
        .byte C_SLIDE,$04,$59,$56           ; slide: delay 4, from G#5 to F-5
        .byte $02,$59                       ; G#5     2 ticks
        .byte C_SLIDE,$04,$56,$59           ; slide: delay 4, from F-5 to G#5
        .byte $02,$56                       ; F-5     2 ticks
        .byte C_SLIDE,$04,$59,$56           ; slide: delay 4, from G#5 to F-5
        .byte $02,$59                       ; G#5     2 ticks
        .byte C_SLIDE,$04,$56,$59           ; slide: delay 4, from F-5 to G#5
        .byte $02,$56                       ; F-5     2 ticks
        .byte C_SLIDE,$04,$59,$56           ; slide: delay 4, from G#5 to F-5
        .byte $02,$59                       ; G#5     2 ticks
        .byte $24,$56                       ; F-5    36 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat07:
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4C                       ; B-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4C                       ; B-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4C                       ; B-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$68                       ; G-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$68                       ; G-6     2 ticks
        .byte $02,$6C                       ; B-6     2 ticks
        .byte $02,$68                       ; G-6     2 ticks
        .byte $02,$6C                       ; B-6     2 ticks
        .byte $02,$73                       ; D-7     2 ticks
        .byte $04,$79                       ; G#7     4 ticks
        .byte C_SLIDESTEP,$01,$03,$C4       ; slide speed 1, step $03C4
        .byte C_SLIDE,$14,$78,$48           ; slide: delay 20, from G-7 to G-4
        .byte $30,$78                       ; G-7    48 ticks
        .byte $10,$00                       ; rest   16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat08:
        .byte C_AD,$08                      ; attack/decay $08
        .byte C_SR,$47                      ; sustain/release $47
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$02,$00,$14,$01 ; pulse sweep: speed 1, delay 2, step $0014, reset 1
        .byte C_PWRANGE,$00,$32,$0E,$00     ; pulse sweep from $0032, back at $0E00
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$45                       ; E-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$45                       ; E-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$45                       ; E-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$45                       ; E-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat09:
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat10:
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat11:
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3C                       ; B-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat12:
        .byte C_AD,$08                      ; attack/decay $08
        .byte C_SR,$C8                      ; sustain/release $C8
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$02,$00,$28,$01 ; pulse sweep: speed 1, delay 2, step $0028, reset 1
        .byte C_PWRANGE,$00,$32,$0C,$64     ; pulse sweep from $0032, back at $0C64
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte $08,$21                       ; C-2     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$2B                       ; A#2     2 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $08,$26                       ; F-2     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat13:
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $02,$27                       ; F#2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $02,$27                       ; F#2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat14:
        .byte $08,$16                       ; F-1     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $02,$24                       ; D#2     2 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $08,$1B                       ; A#1     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $02,$29                       ; G#2     2 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$19                       ; G#1     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat15:
        .byte $08,$18                       ; G-1     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte C_DRUM+2,$06                  ; drum 2 for 6 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $00                           ; end of pattern
; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00

Song1_Init:
        sei
        lda #<S1_Order1
        sta mOrderLo
        lda #>S1_Order1
        sta mOrderHi
        lda #<S1_Order2
        sta mOrderLo+1
        lda #>S1_Order2
        sta mOrderHi+1
        lda #<S1_Order3
        sta mOrderLo+2
        lda #>S1_Order3
        sta mOrderHi+2
        lda #<S1_Pat00
        sta zPat1
        lda #>S1_Pat00
        sta zPat1+1
        lda #<S1_Pat03
        sta zPat2
        lda #>S1_Pat03
        sta zPat2+1
        lda #<S1_Pat06
        sta zPat3
        lda #>S1_Pat06
        sta zPat3+1
        jmp Song_InitCommon

; Song 1, voice 1 order list (high byte 0 = restart).
S1_Order1:
        .word S1_Pat00, S1_Pat01, S1_Pat02, S1_Pat01
        .word S1_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 1, voice 2 order list (high byte 0 = restart).
S1_Order2:
        .word S1_Pat03, S1_Pat04, S1_Pat05, S1_Pat04
        .word S1_Pat05
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 1, voice 3 order list (high byte 0 = restart).
S1_Order3:
        .word S1_Pat06, S1_Pat07, S1_Pat08, S1_Pat07
        .word S1_Pat08
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S1_Pat00:
        .byte C_VOLUME,$0F                  ; volume $0F (filter mode kept)
        .byte C_SPEED,$03                   ; speed 3 calls/tick
        .byte C_AD,$00                      ; attack/decay $00
        .byte C_SR,$49                      ; sustain/release $49
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$01,$00,$32,$01 ; pulse sweep: speed 1, delay 1, step $0032, reset 1
        .byte C_PWRANGE,$00,$64,$0E,$00     ; pulse sweep from $0064, back at $0E00
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_DRUMSPEED,$01               ; drum step every 1 calls
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat01:
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat02:
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat03:
        .byte C_AD,$00                      ; attack/decay $00
        .byte C_SR,$29                      ; sustain/release $29
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$01,$00,$28,$01 ; pulse sweep: speed 1, delay 1, step $0028, reset 1
        .byte C_PWRANGE,$00,$32,$0E,$00     ; pulse sweep from $0032, back at $0E00
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat04:
        .byte $10,$55                       ; E-5    16 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $10,$57                       ; F#5    16 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $10,$55                       ; E-5    16 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $10,$57                       ; F#5    16 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat05:
        .byte $10,$5A                       ; A-5    16 ticks
        .byte $10,$5B                       ; A#5    16 ticks
        .byte $10,$5C                       ; B-5    16 ticks
        .byte $10,$5B                       ; A#5    16 ticks
        .byte $10,$5A                       ; A-5    16 ticks
        .byte $10,$5B                       ; A#5    16 ticks
        .byte $10,$5C                       ; B-5    16 ticks
        .byte $10,$5B                       ; A#5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat06:
        .byte C_AD,$07                      ; attack/decay $07
        .byte C_SR,$49                      ; sustain/release $49
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP,$01,$02,$00,$32,$01 ; pulse sweep: speed 1, delay 2, step $0032, reset 1
        .byte C_PWRANGE,$00,$32,$0C,$64     ; pulse sweep from $0032, back at $0C64
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat07:
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$25                       ; E-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$26                       ; F-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$27                       ; F#2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$26                       ; F-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$25                       ; E-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$26                       ; F-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$27                       ; F#2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$26                       ; F-2     8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat08:
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2A                       ; A-2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2B                       ; A#2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2C                       ; B-2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2B                       ; A#2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2A                       ; A-2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2B                       ; A#2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2C                       ; B-2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$2B                       ; A#2     8 ticks
        .byte $00                           ; end of pattern
; ---- 3 byte(s) not referenced by the sound engine ----
        .byte $00,$FF,$FF

Song2_Init:
        sei
        lda #<S2_Order1
        sta mOrderLo
        lda #>S2_Order1
        sta mOrderHi
        lda #<S2_Order2
        sta mOrderLo+1
        lda #>S2_Order2
        sta mOrderHi+1
        lda #<S2_Order3
        sta mOrderLo+2
        lda #>S2_Order3
        sta mOrderHi+2
        lda #<S2_Pat00
        sta zPat1
        lda #>S2_Pat00
        sta zPat1+1
        lda #<S2_Pat02
        sta zPat2
        lda #>S2_Pat02
        sta zPat2+1
        lda #<S2_Pat04
        sta zPat3
        lda #>S2_Pat04
        sta zPat3+1
        jmp Song_InitCommon

; Song 2, voice 1 order list (high byte 0 = restart).
S2_Order1:
        .word S2_Pat00, S2_Pat00, S2_Pat01
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 2, voice 2 order list (high byte 0 = restart).
S2_Order2:
        .word S2_Pat02, S2_Pat02, S2_Pat03
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 2, voice 3 order list (high byte 0 = restart).
S2_Order3:
        .word S2_Pat04, S2_Pat04, S2_Pat05
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S2_Pat00:
        .byte C_VOLUME,$0F                  ; volume $0F (filter mode kept)
        .byte C_SPEED,$03                   ; speed 3 calls/tick
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$E9                      ; sustain/release $E9
        .byte C_WAVE,$10                    ; waveform $10
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_VIBRATO,$02,$02,$01,$00     ; vibrato: speed 2, delay 2, depth $0100
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $08,$5C                       ; B-5     8 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat01:
        .byte $20,$61                       ; C-6    32 ticks
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte $04,$00                       ; rest    4 ticks
        .byte C_STOP                        ; stop the music
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat02:
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$C9                      ; sustain/release $C9
        .byte C_WAVE,$10                    ; waveform $10
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_VIBRATO,$02,$02,$00,$C8     ; vibrato: speed 2, delay 2, depth $00C8
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$52                       ; C#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$52                       ; C#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$52                       ; C#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$52                       ; C#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $08,$58                       ; G-5     8 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat03:
        .byte $20,$55                       ; E-5    32 ticks
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte $04,$00                       ; rest    4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat04:
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$89                      ; sustain/release $89
        .byte C_WAVE,$10                    ; waveform $10
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$29                       ; G#2     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$2A                       ; A-2     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$2A                       ; A-2     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$17                       ; F#1     4 ticks
        .byte $08,$28                       ; G-2     8 ticks
        .byte $04,$2A                       ; A-2     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat05:
        .byte $20,$31                       ; C-3    32 ticks
        .byte $04,$00                       ; rest    4 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

Song3_Init:
        sei
        lda #<S3_Order1
        sta mOrderLo
        lda #>S3_Order1
        sta mOrderHi
        lda #<S3_Order2
        sta mOrderLo+1
        lda #>S3_Order2
        sta mOrderHi+1
        lda #<S3_Order3
        sta mOrderLo+2
        lda #>S3_Order3
        sta mOrderHi+2
        lda #<S3_Pat00
        sta zPat1
        lda #>S3_Pat00
        sta zPat1+1
        lda #<S3_Pat03
        sta zPat2
        lda #>S3_Pat03
        sta zPat2+1
        lda #<S3_Pat06
        sta zPat3
        lda #>S3_Pat06
        sta zPat3+1
        jmp Song_InitCommon

; Song 3, voice 1 order list (high byte 0 = restart).
S3_Order1:
        .word S3_Pat00, S3_Pat01, S3_Pat00, S3_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 3, voice 2 order list (high byte 0 = restart).
S3_Order2:
        .word S3_Pat03, S3_Pat04, S3_Pat03, S3_Pat05
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Song 3, voice 3 order list (high byte 0 = restart).
S3_Order3:
        .word S3_Pat06, S3_Pat07, S3_Pat06, S3_Pat08
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat00:
        .byte C_VOLUME,$0F                  ; volume $0F (filter mode kept)
        .byte C_SPEED,$05                   ; speed 5 calls/tick
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$8A                      ; sustain/release $8A
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$03                 ; release gate 3 ticks before the end
        .byte C_PWSWEEP,$01,$01,$00,$28,$00 ; pulse sweep: speed 1, delay 1, step $0028, reset 0
        .byte C_PWRANGE,$01,$00,$0E,$00     ; pulse sweep from $0100, back at $0E00
        .byte C_VIBRATO,$02,$32,$00,$C8     ; vibrato: speed 2, delay 50, depth $00C8
        .byte $10,$4C                       ; B-4    16 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $10,$53                       ; D-5    16 ticks
        .byte $10,$4A                       ; A-4    16 ticks
        .byte $10,$55                       ; E-5    16 ticks
        .byte $08,$57                       ; F#5     8 ticks
        .byte $08,$58                       ; G-5     8 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $1C,$53                       ; D-5    28 ticks
        .byte $10,$55                       ; E-5    16 ticks
        .byte $08,$53                       ; D-5     8 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $1C,$4C                       ; B-4    28 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat01:
        .byte $10,$4C                       ; B-4    16 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $18,$4A                       ; A-4    24 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat02:
        .byte $18,$51                       ; C-5    24 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $08,$4C                       ; B-4     8 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $08,$47                       ; F#4     8 ticks
        .byte $38,$48                       ; G-4    56 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat03:
        .byte C_AD,$03                      ; attack/decay $03
        .byte C_SR,$3A                      ; sustain/release $3A
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_PWSWEEP,$01,$01,$00,$28,$00 ; pulse sweep: speed 1, delay 1, step $0028, reset 0
        .byte C_PWRANGE,$01,$00,$0E,$00     ; pulse sweep from $0100, back at $0E00
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat04:
        .byte $04,$36                       ; F-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$36                       ; F-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat05:
        .byte $04,$2A                       ; A-2     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$2A                       ; A-2     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$37                       ; F#3     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$31                       ; C-3     4 ticks
        .byte $04,$35                       ; E-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $04,$2C                       ; B-2     4 ticks
        .byte $04,$33                       ; D-3     4 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat06:
        .byte C_AD,$08                      ; attack/decay $08
        .byte C_SR,$C9                      ; sustain/release $C9
        .byte C_WAVE,$40                    ; waveform $40
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VIBRATO_OFF                 ; vibrato off
        .byte C_SLIDE_OFF                   ; nothing (slides stop by themselves)
        .byte C_WAVEALT_OFF                 ; waveform alternation off
        .byte C_FILTER_OFF                  ; filter off
        .byte C_RELEASE,$02                 ; release gate 2 ticks before the end
        .byte C_PWSWEEP,$01,$01,$00,$28,$00 ; pulse sweep: speed 1, delay 1, step $0028, reset 0
        .byte C_PWRANGE,$04,$00,$0C,$00     ; pulse sweep from $0400, back at $0C00
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$27                       ; F#2     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1C                       ; B-1     4 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat07:
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat08:
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$15                       ; E-1     4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM+2,$04                  ; drum 2 for 4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $00                           ; end of pattern
; ---- 15 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; SID RIPPER WRAPPER (not part of the game). A = song: patch the JMP with
; the song's init routine and set CIA 1 timer A from Rip_SongTable.
Rip_Init:
        asl a
        asl a
        tax
        lda Rip_SongTable,x
        sta Rip_InitJmp+2
        lda Rip_SongTable+1,x
        sta Rip_InitJmp+1
        lda Rip_SongTable+2,x
        sta CIA1_TA_HI
        lda Rip_SongTable+3,x
        sta CIA1_TA_LO

Rip_InitJmp:
        jmp Song0_Init

; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

Rip_SongTable:
        .dbyt Song0_Init, $1997             ; song 1: CIA timer 6551 cycles = 150.4 Hz (PAL)
        .dbyt Song0_Init, $4CC7             ; song 2: CIA timer 19655 cycles = 50.1 Hz (PAL)
        .dbyt Song1_Init, $4CC7             ; song 3: CIA timer 19655 cycles = 50.1 Hz (PAL)
        .dbyt Song2_Init, $4CC7             ; song 4: CIA timer 19655 cycles = 50.1 Hz (PAL)
        .dbyt Song3_Init, $2663             ; song 5: CIA timer 9827 cycles = 100.3 Hz (PAL)
; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $5B,$53,$46,$5D
