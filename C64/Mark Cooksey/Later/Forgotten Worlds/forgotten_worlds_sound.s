;==============================================================================
;  Mark Cooksey C64 sound driver -- FORGOTTEN WORLDS (1989 US Gold / Capcom)
;  Later driver: the data format the NES driver (Dragon's Lair, Joe & Mac,
;  Aladdin) was built on.
;
;  Source: Forgotten_Worlds.sid (PSID v2, load $E000-$FA4F, 2 songs).
;  Reassembles byte-identically to the .sid file:
;            ca65 forgotten_worlds_sound.s
;            ld65 -C forgotten_worlds_sound.cfg -o out.sid forgotten_worlds_sound.o
;
;  The file holds two separate copies of the driver, each with its own song:
;    $E000  T_  title driver (song 1). Full build: PWM, vibrato, filter presets
;               with a cutoff sweep, 7 instruments, 21 patterns.
;    $EE00  G_  in-game driver (song 2). Cut-down build: no PWM, no filter, 3
;               instruments, 18 patterns. The game ran it at $C000; the ripper
;               moved it to $EE00 and only relocated addresses on code paths the
;               tune executes. The rest still point into $C000-$C2FF and are
;               written here as Label-RIP_RELOC (RIP_RELOC = $2E00).
;    $EDD0      ripper wrapper (PSID init/play).
;
;  ENTRY POINTS (per driver)
;    +$00  Init   A = song (only 0)        +$03  Play   once per frame (50 Hz)
;    Play saves and restores zero page $FB/$FC (the track pointer).
;
;  TRACK / PATTERN DATA (2-byte events, same layout as the NES driver)
;    byte 0  bit 7     = bit 4 of the instrument number
;            bits 0-6  = note $00-$5F (C0-B7, index into FreqLo/FreqHi); the
;                        transpose of the current CMD_CALL is added.
;                        $60-$7F (with bit 7 clear) = command
;    byte 1  bits 4-7  = instrument bits 0-3
;            bits 0-3  = length index: DurTable gives the note length in frames,
;                        RelTable the frame on which the gate is released
;    An event is read one frame before it starts.
;    Commands:
;      $60 CMD_REST     len            rest (length index as above)
;      $61 CMD_TIE                     toggle tie: no gate release and no
;                                       retrigger (legato) until toggled back
;      $62 CMD_NOP62    x              stores x; nothing reads it
;      $63 CMD_VOLUME   v              master volume
;      $64 CMD_CALL     pat,trn        play pattern pat once, transposed
;      $65 CMD_CALLN    cnt,pat,trn    play pattern pat cnt times (1 level)
;      $66 CMD_RETURN                  end of pattern
;      $67 CMD_RESTART                 back to the start of the track
;      $68 CMD_JUMP     .word addr     continue at addr (song loop)
;      $69 CMD_FILTER   n              filter preset n (title driver only)
;      $6A CMD_FILTER2  n              same handler as $69
;      $6B CMD_STOP                    silence, stop the driver
;
;  INSTRUMENTS: one byte per instrument in each column table (InsCtrl ...
;  InsVibDelay). The in-game build keeps the two PWM columns but never reads
;  them.
;
;  DIFFERENCES FROM THE NES DRIVER
;    Same event layout, same command idea ($60 rest, CALL with pattern number
;    and transpose, RETURN, JUMP) and nearly the same 16-entry duration table.
;    The NES version renumbers the commands ($60 rest, $61 end, $62 call,
;    $63 return, $64 jump), moves the duration table pointer into the song,
;    and replaces the SID instrument columns with envelope pointers.
;
;  Bytes the driver never reads are kept (so the file reassembles) and are
;  marked "not referenced".
;==============================================================================

; ---------------------------------------------------------------- constants
RIP_RELOC            = $2E00        ; the in-game driver ran at $C000 in the game
CMD_REST             = $60
CMD_TIE              = $61
CMD_NOP62            = $62
CMD_VOLUME           = $63
CMD_CALL             = $64
CMD_CALLN            = $65
CMD_RETURN           = $66
CMD_RESTART          = $67
CMD_JUMP             = $68
CMD_FILTER           = $69
CMD_FILTER2          = $6A
CMD_STOP             = $6B
zTrkPtr              = $FB          ; track pointer (saved and restored by Play)

; ---------------------------------------------------------------- pattern numbers
T_Pattern00_ID       = $00
T_Pattern01_ID       = $01
T_Pattern02_ID       = $02
T_Pattern03_ID       = $03
T_Pattern04_ID       = $04
T_Pattern05_ID       = $05
T_Pattern06_ID       = $06
T_Pattern07_ID       = $07
T_Pattern08_ID       = $08
T_Pattern09_ID       = $09
T_Pattern10_ID       = $0A
T_Pattern11_ID       = $0B
T_Pattern12_ID       = $0C
T_Pattern13_ID       = $0D
T_Pattern14_ID       = $0E
T_Pattern15_ID       = $0F
T_Pattern16_ID       = $10
T_Pattern17_ID       = $11
T_Pattern18_ID       = $12
T_Pattern19_ID       = $13
T_Pattern20_ID       = $14
G_Pattern00_ID       = $00
G_Pattern01_ID       = $01
G_Pattern02_ID       = $02
G_Pattern03_ID       = $03
G_Pattern04_ID       = $04
G_Pattern05_ID       = $05
G_Pattern06_ID       = $06
G_Pattern07_ID       = $07
G_Pattern08_ID       = $08
G_Pattern09_ID       = $09
G_Pattern10_ID       = $0A
G_Pattern11_ID       = $0B
G_Pattern12_ID       = $0C
G_Pattern13_ID       = $0D
G_Pattern14_ID       = $0E
G_Pattern15_ID       = $0F
G_Pattern16_ID       = $10
G_Pattern17_ID       = $11

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
        .dbyt Rip_Play                      ; play
        .dbyt $0002                         ; number of songs
        .dbyt $0001                         ; default song
        .dbyt $0000, $0000                  ; speed bits per song: 1 = CIA timer, 0 = VBI
        .byte "Forgotten Worlds"
        .res 16, $00                       ; name (32 bytes)
        .byte "Mark Cooksey"
        .res 20, $00                       ; author (32 bytes)
        .byte "1989 US Gold/Capcom"
        .res 13, $00                       ; released (32 bytes)
        .dbyt $0000                         ; flags: clock unknown, SID unknown
        .byte $00, $00                      ; start page, page length
        .dbyt $0000                         ; second/third SID
        .word LoadAddress                   ; load address (little-endian)

.segment "PLAYER"

; Entry points. Init: A = song (this driver holds one song: 0).
T_Init:
LoadAddress:
        jmp T_SongInit

; Play: once per frame. Voices 2, 1, 0.
T_Play:
        lda zTrkPtr
        pha
        lda zTrkPtr+1
        pha
        lda T_mEnabled
        bne T_Run
        jmp T_PlayExit

T_Run:
        ldx #$02

; X = voice. Release the gate when the release timer runs out
; (unless tied).
T_VoiceLoop:
        stx T_mVoice
        lda T_VoiceRegOfs,x
        sta T_mRegOfs
        ldy T_mCurInst,x
        sty T_mInst
        lda T_mRelTimer,x
        beq T_TickNote
        dec T_mRelTimer,x
        bne T_TickNote
        lda T_mTie,x
        bne T_TickNote
        sta T_mPlaying                      ; no ,x: always clears voice 0 (never read anyway)
        lda T_InsCtrlRel,y
        ldy T_mRegOfs
        sta SID_V1_CTRL,y

; Note timer: 0 = start the read-ahead note, 1 = read the next
; event (one frame early), otherwise run the effects.
T_TickNote:
        dec T_mTimer,x
        lda T_mTimer,x
        beq T_StartNote
        cmp #$01
        beq T_ReadEvent
        jmp T_Effects

T_ReadEvent:
        lda T_mTrkLo,x
        sta zTrkPtr
        lda T_mTrkHi,x
        sta zTrkPtr+1
        ldy #$00

; Y = offset in the track. Notes are $00-$5F, or any byte with
; bit 7 set; $60-$7F are commands.
T_ParseEvent:
        lda (zTrkPtr),y
        bmi T_Note
        cmp #$60
        bcc T_Note
        jmp T_Command

; Note: byte 0 = note (+ bit 7: instrument bit 4), byte 1 = instrument
; bits 0-3 (high nibble), DurTable/RelTable index (low nibble).
T_Note:
        sta T_zEvByte0
        and #$7F
        clc
        adc T_mTranspose,x
        sta T_mNextNote,x
        iny
        lda (zTrkPtr),y
        pha
        iny
        sty T_mEvLen
        and #$0F
        tay
        lda T_DurTable,y
        sta T_mNextLen,x
        lda T_RelTable,y
        sta T_mNextRel,x
        pla
        rol T_zEvByte0
        ror a
        lsr a
        lsr a
        lsr a
        sta T_mNextInst,x
        lda #$00
        sta T_mNextRest,x

; Track pointer += Y.
T_AdvanceTrack:
        lda T_mEvLen
        clc
        adc zTrkPtr
        sta T_mTrkLo,x
        lda zTrkPtr+1
        adc #$00
        sta T_mTrkHi,x
        jmp T_WriteVoice

; Timer ran out: the read-ahead event becomes current.
T_StartNote:
        lda T_mNextInst,x
        sta T_mCurInst,x
        sta T_mInst
        tay
        lda T_mNextRest,x
        beq T_LoadInstrument
        jmp T_StartTimers

; Pulse width, PWM, vibrato from the instrument; frequency from the
; note; AD, SR, control (gate on).
T_LoadInstrument:
        lda T_InsPwLo,y
        sta T_mPwLo,x
        lda T_InsPwHi,y
        sta T_mPwHi,x
        lda T_InsPwmLen,y
        sta T_mPwmTimer,x
        lda T_InsVibDepth,y
        sta T_mVibDepth,x
        lda T_InsVibLen,y
        sta T_mVibTimer,x
        lda T_InsVibDelay,y
        sta T_mVibDelay,x
        lda #$00
        sta T_mPwmDir,x
        sta T_mVibDir,x
        sta T_mVibFull,x
        lda #$01
        sta T_mPlaying,x
        lda T_mNextNote,x
        sta T_mNote,x
        tay
        lda T_FreqLo,y
        sta T_mFreqLo,x
        lda T_FreqHi,y
        sta T_mFreqHi,x
        ldy T_mInst
        ldx T_mRegOfs
        lda T_InsAD,y
        sta SID_V1_AD,x
        lda T_InsSR,y
        sta SID_V1_SR,x
        lda T_InsCtrl,y
        sta SID_V1_CTRL,x
        ldx T_mVoice

; Note and rest: timers from the read-ahead event.
T_StartTimers:
        lda T_mNextLen,x
        sta T_mTimer,x
        lda T_mNextRel,x
        sta T_mRelTimer,x
        lda T_mNextRest,x
        sta T_mRest,x
        ldy T_mFilter
        bmi T_StartDone
        lda T_FltRoute,y
        and T_VoiceBit,x
        beq T_StartDone
        lda T_mTie,x
        bne T_StartDone
        lda T_FltCutoff,y
        sta T_mCutoff
        lda #$00
        sta T_mSweepCount
        sta T_mSweepDir

T_StartDone:
        jmp T_WriteVoice

; Pulse-width modulation: step up / down, flip every InsPwmLen frames.
T_Effects:
        ldy T_mInst
        lda T_InsPwmStep,y
        beq T_Vibrato
        dec T_mPwmTimer,x
        bne T_PwmApply
        lda T_InsPwmLen,y
        sta T_mPwmTimer,x
        lda T_mPwmDir,x
        eor #$01
        sta T_mPwmDir,x

T_PwmApply:
        lda T_mPwmDir,x
        bne T_PwmDown
        lda T_mPwLo,x
        clc
        adc T_InsPwmStep,y
        sta T_mPwLo,x
        bcc T_Vibrato
        inc T_mPwHi,x
        jmp T_Vibrato

T_PwmDown:
        lda T_mPwLo,x
        sec
        sbc T_InsPwmStep,y
        sta T_mPwLo,x
        bcs T_Vibrato
        dec T_mPwHi,x

; Vibrato: after InsVibDelay frames, swing the frequency by mVibDepth
; each frame, flipping direction every InsVibLen frames; the depth
; is doubled after the first flip so the swing is centred.
T_Vibrato:
        lda T_InsVibDepth,y
        beq T_WriteVoice
        lda T_mVibDelay,x
        beq T_VibTick
        dec T_mVibDelay,x
        bpl T_WriteVoice

T_VibTick:
        dec T_mVibTimer,x
        bne T_VibApply
        lda T_InsVibLen,y
        sta T_mVibTimer,x
        lda T_mVibDir,x
        eor #$01
        sta T_mVibDir,x
        lda T_mVibFull,x
        bne T_VibApply
        inc T_mVibFull,x
        asl T_mVibDepth,x

T_VibApply:
        lda T_mVibDir,x
        bne T_VibDown
        lda T_mFreqLo,x                     ; no CLC: a leftover carry adds 1
        adc T_mVibDepth,x
        sta T_mFreqLo,x
        bcc T_WriteVoice
        inc T_mFreqHi,x
        jmp T_WriteVoice

T_VibDown:
        lda T_mFreqLo,x
        sec
        sbc T_mVibDepth,x
        sta T_mFreqLo,x
        bcs T_WriteVoice
        dec T_mFreqHi,x

; Frequency and pulse width to the SID; next voice.
T_WriteVoice:
        ldy T_mRegOfs
        lda T_mFreqLo,x
        sta SID_V1_FREQ_LO,y
        lda T_mFreqHi,x
        sta SID_V1_FREQ_HI,y
        lda T_mPwLo,x
        sta SID_V1_PW_LO,y
        lda T_mPwHi,x
        sta SID_V1_PW_HI,y
        dex
        bmi T_FilterSweep
        jmp T_VoiceLoop

; Filter sweep (global): cutoff moves by FltStep for FltLen frames,
; then back.
T_FilterSweep:
        ldx T_mFilter
        bpl T_SweepTick
        lda #$F0
        bne T_SetRouting

T_SweepTick:
        lda T_mSweepCount
        cmp T_FltLen,x
        bne T_SweepStep
        lda #$00
        sta T_mSweepCount
        lda T_mSweepDir
        eor #$01
        sta T_mSweepDir

T_SweepStep:
        inc T_mSweepCount
        lda T_mSweepDir
        bne T_SweepDown
        lda T_mCutoff
        clc
        adc T_FltStep,x
        sta T_mCutoff
        jmp T_SetCutoff

T_SweepDown:
        lda T_mCutoff
        sec
        sbc T_FltStep,x
        sta T_mCutoff

T_SetCutoff:
        sta SID_FC_HI
        lda T_FltRoute,x

T_SetRouting:
        sta SID_RES_FILT

T_PlayExit:
        pla
        sta zTrkPtr+1
        pla
        sta zTrkPtr
        rts

; Command byte: $6B stops the driver, $60-$6A jump through
; CmdLo/CmdHi (the JMP operand below is patched).
T_Command:
        cmp #$6B
        beq T_Cmd_Stop
        sec
        sbc #$60
        tax
        lda T_CmdLo,x
        sta T_CmdJumpVec
        lda T_CmdHi,x
        sta T_CmdJump+2
        ldx T_mVoice
        iny
        sty T_mEvLen

T_CmdJump:
T_CmdJumpVec := * + 1
        jmp T_Cmd_Rest

; $6B CMD_STOP: silence and disable the driver.
T_Cmd_Stop:
        lda #$00
        sta T_mEnabled
        sta SID_V1_CTRL
        sta SID_V2_CTRL
        sta SID_V3_CTRL
        jmp T_PlayExit

; $60 CMD_REST len: rest (the gate stays off).
T_Cmd_Rest:
        lda (zTrkPtr),y
        iny
        sty T_mEvLen
        tay
        lda T_DurTable,y
        sta T_mNextLen,x
        lda #$01
        sta T_mNextRest,x
        jmp T_AdvanceTrack

; $61 CMD_TIE: toggle tie/legato for this voice.
T_Cmd_Tie:
        lda T_mTie,x
        eor #$01
        sta T_mTie,x
        jmp T_ParseEvent

; $62 x: stores x in mNop62, which nothing reads.
T_Cmd_Nop62:
        lda (zTrkPtr),y
        sta T_mNop62
        iny
        jmp T_ParseEvent

; $63 CMD_VOLUME v: master volume (filter mode bits kept).
T_Cmd_Volume:
        lda (zTrkPtr),y
        sta T_mVolume
        ora T_mFilterMode
        sta SID_MODE_VOL
        iny
        jmp T_ParseEvent

; $65 CMD_CALLN count, pattern, transpose
T_Cmd_CallN:
        lda (zTrkPtr),y
        sta T_mRepeat,x
        iny

; $64 CMD_CALL pattern, transpose (enters Cmd_CallN here, so the
; count left over from the last call, normally 0, is kept: play once).
T_Cmd_Call:
        lda (zTrkPtr),y
        pha
        iny
        lda (zTrkPtr),y
        sta T_mTranspose,x
        iny
        tya
        clc
        adc zTrkPtr
        sta T_mRetLo,x
        lda zTrkPtr+1
        adc #$00
        sta T_mRetHi,x
        pla
        tay
        lda T_PatLo,y
        sta zTrkPtr
        sta T_mPatLo,x
        lda T_PatHi,y
        sta zTrkPtr+1
        sta T_mPatHi,x
        ldy #$00
        jmp T_ParseEvent

; $66 CMD_RETURN: repeat the pattern while the count lasts, else
; continue after the call with transpose 0.
T_Cmd_Return:
        lda T_mRepeat,x
        beq T_ReturnDone
        dec T_mRepeat,x
        beq T_ReturnDone
        lda T_mPatLo,x
        sta zTrkPtr
        lda T_mPatHi,x
        sta zTrkPtr+1
        bne T_ReturnGo

T_ReturnDone:
        lda T_mRetLo,x
        sta zTrkPtr
        lda T_mRetHi,x
        sta zTrkPtr+1
        lda #$00
        sta T_mTranspose,x

T_ReturnGo:
        ldy #$00
        jmp T_ParseEvent

; $67 CMD_RESTART: back to the start of the track.
T_Cmd_Restart:
        lda T_mTrkStartLo,x
        sta T_mTrkLo,x
        lda T_mTrkStartHi,x
        sta T_mTrkHi,x
        lda #$00
        sta T_mTranspose,x
        jmp T_ReadEvent

; $68 CMD_JUMP .word address
T_Cmd_Jump:
        lda (zTrkPtr),y
        sta T_mTrkLo,x
        iny
        lda (zTrkPtr),y
        sta T_mTrkHi,x
        jmp T_ReadEvent

; $69/$6A CMD_FILTER preset: filter mode, routing, cutoff, sweep.
T_Cmd_Filter:
        lda (zTrkPtr),y
        sta T_mFilter
        iny
        sty T_mEvLen
        tay
        lda T_FltMode,y
        sta T_mFilterMode
        ora T_mVolume
        sta SID_MODE_VOL
        lda T_FltCutoff,y
        sta T_mCutoff
        lda #$00
        sta T_mSweepCount
        sta T_mSweepDir
        ldy T_mEvLen
        jmp T_ParseEvent

T_zEvByte0:
        .byte $38                           ; byte 0 of the event being read (bit 7 = instrument bit 4)

T_Unused01:
        .byte $00

T_mEvLen:
        .byte $02                           ; Y: length of the event just read

T_mVoice:
        .byte $00                           ; current voice (2, 1, 0)

T_mRegOfs:
        .byte $00                           ; SID register offset of the current voice

T_mInst:
        .byte $00                           ; instrument of the current voice

T_mEnabled:
        .byte $00                           ; 0 = driver stopped (CMD_STOP)

T_VoiceRegOfs:
        .byte $00,$07,$0E                   ; SID register offset per voice

T_VoiceBit:
        .byte $01,$02,$04                   ; filter routing bit per voice

T_mTrkLo:
        .byte $0C,$31,$EC                   ; track / pattern pointer

T_mTrkHi:
        .byte $E6,$E8,$EA

T_mRetLo:
        .byte $9F,$B7,$CF                   ; return address (after a CMD_CALL)

T_mRetHi:
        .byte $E5,$E5,$E5

T_mTrkStartLo:
        .byte $99,$B1,$C9                   ; start of the track (CMD_RESTART)

T_mTrkStartHi:
        .byte $E5,$E5,$E5

T_mPatLo:
        .byte $F4,$13,$8C                   ; start of the called pattern (for repeats)

T_mPatHi:
        .byte $E5,$E8,$EA

T_mNote:
        .byte $39,$4A,$1C                   ; note playing (written, never read)

T_mNextNote:
        .byte $39,$4A,$1C                   ; note read ahead (transposed)

T_mCurInst:
        .byte $00,$04,$02                   ; instrument playing

T_mNextInst:
        .byte $00,$04,$02                   ; instrument read ahead

T_mTimer:
        .byte $06,$06,$06                   ; frames left of the note

T_mNextLen:
        .byte $48,$30,$0C                   ; length of the next note (DurTable)

T_mRelTimer:
        .byte $00,$00,$02                   ; frames until the gate is released

T_mNextRel:
        .byte $10,$20,$08                   ; release time of the next note (RelTable)

T_mNextRest:
        .byte $01,$00,$00                   ; 1 = the next event is a rest

T_mRest:
        .byte $01,$00,$00                   ; rest flag of the current event (written, never read)

T_mTie:
        .byte $00,$00,$00                   ; toggled by CMD_TIE: no gate release, no retrigger

T_mPlaying:
        .byte $00,$01,$01                   ; set at each note start (written, never read)

T_mTranspose:
        .byte $00,$00,$00                   ; added to the notes of a called pattern

T_mRepeat:
        .byte $00,$00,$00                   ; CMD_CALLN repeat count

T_mVolume:
        .byte $0F                           ; master volume (CMD_VOLUME)

T_mNop62:
        .byte $00                           ; CMD_NOP62 parameter (written, never read)

T_mFreqLo:
        .byte $42,$20,$7B                   ; current frequency (with vibrato)

T_mFreqHi:
        .byte $1D,$4E,$05

T_mPwLo:
        .byte $00,$00,$D0                   ; current pulse width

T_mPwHi:
        .byte $08,$05,$06

T_mPwmDir:
        .byte $01,$00,$00                   ; PWM direction (0 = up)

T_mPwmTimer:
        .byte $0A,$00,$1A                   ; frames left in this PWM direction

T_mVibDepth:
        .byte $20,$00,$00                   ; vibrato step (doubled after the first half swing)

T_mVibTimer:
        .byte $02,$00,$00                   ; frames left in this vibrato direction

T_mVibDelay:
        .byte $00,$00,$00                   ; frames before the vibrato starts

T_mVibDir:
        .byte $01,$00,$00                   ; vibrato direction (0 = up)

T_mVibFull:
        .byte $01,$00,$00                   ; 1 once the depth has been doubled

T_mFilter:
        .byte $02                           ; filter preset, $80+ = filter off

T_mCutoff:
        .byte $70                           ; filter cutoff (high byte)

T_mSweepDir:
        .byte $01                           ; cutoff sweep direction (0 = up)

T_mSweepCount:
        .byte $07                           ; frames in this sweep direction

T_mFilterMode:
        .byte $10                           ; filter mode bits for SID_MODE_VOL

T_CmdLo:
        .lobytes T_Cmd_Rest                 ; $60 CMD_REST
        .lobytes T_Cmd_Tie                  ; $61 CMD_TIE
        .lobytes T_Cmd_Nop62                ; $62 CMD_NOP62
        .lobytes T_Cmd_Volume               ; $63 CMD_VOLUME
        .lobytes T_Cmd_Call                 ; $64 CMD_CALL
        .lobytes T_Cmd_CallN                ; $65 CMD_CALLN
        .lobytes T_Cmd_Return               ; $66 CMD_RETURN
        .lobytes T_Cmd_Restart              ; $67 CMD_RESTART
        .lobytes T_Cmd_Jump                 ; $68 CMD_JUMP
        .lobytes T_Cmd_Filter               ; $69 CMD_FILTER
        .lobytes T_Cmd_Filter               ; $6A CMD_FILTER2

T_CmdHi:
        .hibytes T_Cmd_Rest                 ; $60 CMD_REST
        .hibytes T_Cmd_Tie                  ; $61 CMD_TIE
        .hibytes T_Cmd_Nop62                ; $62 CMD_NOP62
        .hibytes T_Cmd_Volume               ; $63 CMD_VOLUME
        .hibytes T_Cmd_Call                 ; $64 CMD_CALL
        .hibytes T_Cmd_CallN                ; $65 CMD_CALLN
        .hibytes T_Cmd_Return               ; $66 CMD_RETURN
        .hibytes T_Cmd_Restart              ; $67 CMD_RESTART
        .hibytes T_Cmd_Jump                 ; $68 CMD_JUMP
        .hibytes T_Cmd_Filter               ; $69 CMD_FILTER
        .hibytes T_Cmd_Filter               ; $6A CMD_FILTER2

; SID frequency per note, C0..B7 (PAL tuned: A4 = $1D46 = 440.1 Hz on PAL).
T_FreqLo:
        .lobytes $0116,$0127,$0128,$014B,$015F,$0173,$018A,$01A1,$01BA,$01D4,$01F0,$020E ; octave 0
        .lobytes $022D,$024E,$0271,$0296,$02BD,$02E7,$0313,$0342,$0374,$03A9,$03E0,$041B ; octave 1
        .lobytes $045A,$049B,$04E2,$052C,$057B,$05CE,$0627,$0685,$06E8,$0751,$07C1,$0837 ; octave 2
        .lobytes $08B4,$0937,$09C4,$0A57,$0AF5,$0B9C,$0C4E,$0D09,$0DD0,$0EA3,$0F82,$106E ; octave 3
        .lobytes $1168,$126E,$1388,$14AF,$15EB,$1739,$189C,$1A13,$1BA1,$1D46,$1F04,$20DC ; octave 4
        .lobytes $22D0,$24DC,$2710,$295E,$2BD6,$2E72,$3138,$3426,$3742,$3A8C,$3E08,$41B8 ; octave 5
        .lobytes $45A0,$49B8,$4E20,$52BC,$57AC,$5CE4,$6270,$684C,$6E84,$7581,$7C10,$8370 ; octave 6
        .lobytes $8B40,$9370,$9C40,$A578,$AF58,$B9C8,$C4E0,$D098,$DD08,$EA30,$F820,$FD2E ; octave 7

T_FreqHi:
        .hibytes $0116,$0127,$0128,$014B,$015F,$0173,$018A,$01A1,$01BA,$01D4,$01F0,$020E ; octave 0
        .hibytes $022D,$024E,$0271,$0296,$02BD,$02E7,$0313,$0342,$0374,$03A9,$03E0,$041B ; octave 1
        .hibytes $045A,$049B,$04E2,$052C,$057B,$05CE,$0627,$0685,$06E8,$0751,$07C1,$0837 ; octave 2
        .hibytes $08B4,$0937,$09C4,$0A57,$0AF5,$0B9C,$0C4E,$0D09,$0DD0,$0EA3,$0F82,$106E ; octave 3
        .hibytes $1168,$126E,$1388,$14AF,$15EB,$1739,$189C,$1A13,$1BA1,$1D46,$1F04,$20DC ; octave 4
        .hibytes $22D0,$24DC,$2710,$295E,$2BD6,$2E72,$3138,$3426,$3742,$3A8C,$3E08,$41B8 ; octave 5
        .hibytes $45A0,$49B8,$4E20,$52BC,$57AC,$5CE4,$6270,$684C,$6E84,$7581,$7C10,$8370 ; octave 6
        .hibytes $8B40,$9370,$9C40,$A578,$AF58,$B9C8,$C4E0,$D098,$DD08,$EA30,$F820,$FD2E ; octave 7

; Song A: track pointers (A indexes TrkLo/TrkHi, so only 0 is
; valid), timers = 2, clear the SID, volume 15, enable.
T_SongInit:
        tax
        ldy #$00

T_InitLoop:
        lda T_TrkLo,x
        sta T_mTrkLo,y
        sta T_mTrkStartLo,y
        lda T_TrkHi,x
        sta T_mTrkHi,y
        sta T_mTrkStartHi,y
        lda #$02
        sta T_mTimer,y
        inx
        iny
        cpy #$03
        bne T_InitLoop
        ldx #$17
        lda #$00

T_ClearSid:
        sta SID_V1_FREQ_LO,x
        dex
        bpl T_ClearSid
        lda #$0F
        sta SID_MODE_VOL
        sta T_mVolume
        sta T_mEnabled
        rts

T_DurTable:
        .byte $03,$04,$06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$08,$10,$20 ; frames per length index 0-15

T_RelTable:
        .byte $02,$02,$04,$06,$08,$0C,$10,$18,$20,$34,$40,$60,$80,$05,$0B,$15 ; frames before the gate is released, per length index

; INSTRUMENTS: 7 instruments, stored as 11 columns (one byte per
; instrument in each).
T_InsCtrl:
        .byte $41,$41,$41,$41,$21,$41,$41   ; control register at note start (waveform + gate)

T_InsCtrlRel:
        .byte $40,$40,$40,$40,$20,$40,$40   ; control register at release (gate off)

T_InsAD:
        .byte $38,$28,$28,$37,$39,$21,$28   ; attack / decay

T_InsSR:
        .byte $9B,$B9,$A9,$6B,$8A,$49,$A9   ; sustain / release

T_InsPwLo:
        .byte $00,$D0,$10,$00,$00,$00,$30   ; pulse width low

T_InsPwHi:
        .byte $06,$00,$06,$06,$05,$05,$07   ; pulse width high

T_InsPwmStep:
        .byte $40,$00,$20,$40,$00,$50,$50   ; PWM: added to / taken from the pulse width every frame (0 = off)

T_InsPwmLen:
        .byte $20,$00,$20,$20,$00,$20,$15   ; PWM: frames per direction

T_InsVibDepth:
        .byte $10,$10,$00,$10,$00,$00,$10   ; vibrato depth (frequency units, 0 = off)

T_InsVibLen:
        .byte $04,$04,$00,$04,$00,$00,$04   ; vibrato: frames per direction

T_InsVibDelay:
        .byte $00,$00,$00,$00,$00,$00,$00   ; vibrato delay in frames

; FILTER PRESETS 0-3 (CMD_FILTER), one column per field.
T_FltMode:
        .byte $10,$10,$10,$10               ; filter mode bits (SID_MODE_VOL high nibble)

T_FltRoute:
        .byte $00,$05,$07,$06               ; SID_RES_FILT: resonance / voices into the filter

T_FltCutoff:
        .byte $00,$70,$70,$70               ; start cutoff (SID_FC_HI)

T_FltStep:
        .byte $00,$00,$00,$00               ; cutoff change per frame

T_FltLen:
        .byte $00,$00,$00,$00               ; frames per sweep direction

; SONG: one track per voice.
T_TrkLo:
        .lobytes T_Track_V1, T_Track_V2, T_Track_V3 ; song 0: voice 1, 2, 3

T_TrkHi:
        .hibytes T_Track_V1, T_Track_V2, T_Track_V3

; PATTERNS (CMD_CALL numbers).
T_PatLo:
        .lobytes T_Pattern00, T_Pattern01, T_Pattern02, T_Pattern03, T_Pattern04, T_Pattern05, T_Pattern06, T_Pattern07
        .lobytes T_Pattern08, T_Pattern09, T_Pattern10, T_Pattern11, T_Pattern12, T_Pattern13, T_Pattern14, T_Pattern15
        .lobytes T_Pattern16, T_Pattern17, T_Pattern18, T_Pattern19, T_Pattern20

T_PatHi:
        .hibytes T_Pattern00, T_Pattern01, T_Pattern02, T_Pattern03, T_Pattern04, T_Pattern05, T_Pattern06, T_Pattern07
        .hibytes T_Pattern08, T_Pattern09, T_Pattern10, T_Pattern11, T_Pattern12, T_Pattern13, T_Pattern14, T_Pattern15
        .hibytes T_Pattern16, T_Pattern17, T_Pattern18, T_Pattern19, T_Pattern20

T_Track_V1:
        .byte CMD_CALL,T_Pattern00_ID,$00   ; T_Pattern00, transpose +0

T_Track_V1_Loop:
        .byte CMD_CALL,T_Pattern03_ID,$00   ; T_Pattern03, transpose +0
        .byte CMD_CALL,T_Pattern06_ID,$00   ; T_Pattern06, transpose +0
        .byte CMD_CALL,T_Pattern09_ID,$00   ; T_Pattern09, transpose +0
        .byte CMD_CALL,T_Pattern12_ID,$00   ; T_Pattern12, transpose +0
        .byte CMD_CALL,T_Pattern15_ID,$00   ; T_Pattern15, transpose +0
        .byte CMD_CALL,T_Pattern18_ID,$00   ; T_Pattern18, transpose +0
        .byte CMD_JUMP
        .word T_Track_V1_Loop               ; loop

T_Track_V2:
        .byte CMD_CALL,T_Pattern01_ID,$00   ; T_Pattern01, transpose +0

T_Track_V2_Loop:
        .byte CMD_CALL,T_Pattern04_ID,$00   ; T_Pattern04, transpose +0
        .byte CMD_CALL,T_Pattern07_ID,$00   ; T_Pattern07, transpose +0
        .byte CMD_CALL,T_Pattern10_ID,$00   ; T_Pattern10, transpose +0
        .byte CMD_CALL,T_Pattern13_ID,$00   ; T_Pattern13, transpose +0
        .byte CMD_CALL,T_Pattern16_ID,$00   ; T_Pattern16, transpose +0
        .byte CMD_CALL,T_Pattern19_ID,$00   ; T_Pattern19, transpose +0
        .byte CMD_JUMP
        .word T_Track_V2_Loop               ; loop

T_Track_V3:
        .byte CMD_CALL,T_Pattern02_ID,$F4   ; T_Pattern02, transpose -12

T_Track_V3_Loop:
        .byte CMD_CALL,T_Pattern05_ID,$00   ; T_Pattern05, transpose +0
        .byte CMD_CALL,T_Pattern08_ID,$00   ; T_Pattern08, transpose +0
        .byte CMD_CALL,T_Pattern11_ID,$00   ; T_Pattern11, transpose +0
        .byte CMD_CALL,T_Pattern14_ID,$00   ; T_Pattern14, transpose +0
        .byte CMD_CALL,T_Pattern17_ID,$0C   ; T_Pattern17, transpose +12
        .byte CMD_CALL,T_Pattern20_ID,$00   ; T_Pattern20, transpose +0
        .byte CMD_JUMP
        .word T_Track_V3_Loop               ; loop

T_Pattern00:
        .byte CMD_FILTER2,$02               ; filter preset 2
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte CMD_REST,$0D                  ; rest  len[13] =   8 fr
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte CMD_RETURN

T_Pattern03:
        .byte $3B,$09                       ; B-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3D,$0C                       ; C#5  ins  0  len[12] = 192 fr, release after 128
        .byte $38,$09                       ; G#4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte $34,$09                       ; E-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $31,$05                       ; C#4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $36,$02                       ; F#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $36,$05                       ; F#4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $38,$02                       ; G#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $39,$09                       ; A-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3D,$06                       ; C#5  ins  0  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte $34,$09                       ; E-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $36,$05                       ; F#4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $38,$02                       ; G#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3B,$05                       ; B-4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3D,$02                       ; C#5  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3E,$09                       ; D-5  ins  0  len[ 9] =  72 fr, release after 52
        .byte $40,$06                       ; E-5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $41,$08                       ; F-5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $43,$06                       ; G-5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $44,$06                       ; G#5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $45,$06                       ; A-5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $39,$08                       ; A-4  ins  0  len[ 8] =  48 fr, release after 32
        .byte $3D,$06                       ; C#5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3E,$08                       ; D-5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $42,$08                       ; F#5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $40,$08                       ; E-5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $40,$08                       ; E-5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $40,$05                       ; E-5  ins  0  len[ 5] =  18 fr, release after 12
        .byte $39,$02                       ; A-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $39,$09                       ; A-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_RETURN

T_Pattern06:
        .byte $33,$07                       ; D#4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $31,$07                       ; C#4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $31,$02                       ; C#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $33,$02                       ; D#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  12 fr, release after 8
        .byte $36,$09                       ; F#4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $36,$07                       ; F#4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $34,$07                       ; E-4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $34,$02                       ; E-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $36,$02                       ; F#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $37,$04                       ; G-4  ins  0  len[ 4] =  12 fr, release after 8
        .byte $37,$07                       ; G-4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $35,$07                       ; F-4  ins  0  len[ 7] =  36 fr, release after 24
        .byte $35,$02                       ; F-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $37,$02                       ; G-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $3F,$10                       ; D#5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $40,$10                       ; E-5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $41,$12                       ; F-5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $46,$14                       ; A#5  ins  1  len[ 4] =  12 fr, release after 8
        .byte $46,$12                       ; A#5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $45,$16                       ; A-5  ins  1  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $3F,$10                       ; D#5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $40,$10                       ; E-5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $41,$12                       ; F-5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $46,$14                       ; A#5  ins  1  len[ 4] =  12 fr, release after 8
        .byte $46,$12                       ; A#5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $45,$12                       ; A-5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $4B,$1D                       ; D#6  ins  1  len[13] =   8 fr, release after 5
        .byte $4C,$1D                       ; E-6  ins  1  len[13] =   8 fr, release after 5
        .byte $4B,$1D                       ; D#6  ins  1  len[13] =   8 fr, release after 5
        .byte $48,$1A                       ; C-6  ins  1  len[10] =  96 fr, release after 64
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $3D,$10                       ; C#5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $3E,$10                       ; D-5  ins  1  len[ 0] =   3 fr, release after 2
        .byte $3F,$12                       ; D#5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $44,$14                       ; G#5  ins  1  len[ 4] =  12 fr, release after 8
        .byte $44,$12                       ; G#5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $43,$15                       ; G-5  ins  1  len[ 5] =  18 fr, release after 12
        .byte $3F,$14                       ; D#5  ins  1  len[ 4] =  12 fr, release after 8
        .byte $3E,$14                       ; D-5  ins  1  len[ 4] =  12 fr, release after 8
        .byte $43,$12                       ; G-5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $42,$12                       ; F#5  ins  1  len[ 2] =   6 fr, release after 4
        .byte $48,$1D                       ; C-6  ins  1  len[13] =   8 fr, release after 5
        .byte $47,$1D                       ; B-5  ins  1  len[13] =   8 fr, release after 5
        .byte $44,$1D                       ; G#5  ins  1  len[13] =   8 fr, release after 5
        .byte $4B,$1D                       ; D#6  ins  1  len[13] =   8 fr, release after 5
        .byte $4D,$1D                       ; F-6  ins  1  len[13] =   8 fr, release after 5
        .byte $4B,$1D                       ; D#6  ins  1  len[13] =   8 fr, release after 5
        .byte $51,$1D                       ; A-6  ins  1  len[13] =   8 fr, release after 5
        .byte $52,$1D                       ; A#6  ins  1  len[13] =   8 fr, release after 5
        .byte $51,$1D                       ; A-6  ins  1  len[13] =   8 fr, release after 5
        .byte $42,$16                       ; F#5  ins  1  len[ 6] =  24 fr, release after 16
        .byte $39,$1D                       ; A-4  ins  1  len[13] =   8 fr, release after 5
        .byte $3A,$1D                       ; A#4  ins  1  len[13] =   8 fr, release after 5
        .byte $39,$1D                       ; A-4  ins  1  len[13] =   8 fr, release after 5
        .byte $35,$18                       ; F-4  ins  1  len[ 8] =  48 fr, release after 32
        .byte CMD_FILTER2,$02               ; filter preset 2
        .byte CMD_RETURN

T_Pattern09:
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$06                       ; E-5  ins  0  len[ 6] =  24 fr, release after 16
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN

T_Pattern12:
        .byte $3B,$09                       ; B-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $37,$06                       ; G-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $33,$06                       ; D#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $37,$06                       ; G-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  36 fr, release after 24
        .byte $3C,$01                       ; C-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3D,$01                       ; C#5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3E,$01                       ; D-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  36 fr, release after 24
        .byte $3C,$01                       ; C-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3D,$01                       ; C#5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3E,$01                       ; D-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  36 fr, release after 24
        .byte $3C,$01                       ; C-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3D,$01                       ; C#5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3E,$01                       ; D-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  36 fr, release after 24
        .byte $3C,$01                       ; C-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3D,$01                       ; C#5  ins  0  len[ 1] =   4 fr, release after 2
        .byte $3E,$01                       ; D-5  ins  0  len[ 1] =   4 fr, release after 2
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte $35,$02                       ; F-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $34,$69                       ; E-4  ins  6  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3A,$67                       ; A#4  ins  6  len[ 7] =  36 fr, release after 24
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $3C,$0D                       ; C-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3C,$0D                       ; C-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3C,$0D                       ; C-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3C,$05                       ; C-5  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3D,$08                       ; C#5  ins  0  len[ 8] =  48 fr, release after 32
        .byte $3E,$0D                       ; D-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3E,$0D                       ; D-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3E,$0D                       ; D-5  ins  0  len[13] =   8 fr, release after 5
        .byte $3E,$05                       ; D-5  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3F,$08                       ; D#5  ins  0  len[ 8] =  48 fr, release after 32
        .byte CMD_RETURN

T_Pattern15:
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  12 fr, release after 8
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  12 fr, release after 8
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $38,$06                       ; G#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $36,$06                       ; F#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3B,$09                       ; B-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $3B,$0D                       ; B-4  ins  0  len[13] =   8 fr, release after 5
        .byte $3B,$0D                       ; B-4  ins  0  len[13] =   8 fr, release after 5
        .byte $3B,$0D                       ; B-4  ins  0  len[13] =   8 fr, release after 5
        .byte $3D,$09                       ; C#5  ins  0  len[ 9] =  72 fr, release after 52
        .byte $3D,$0D                       ; C#5  ins  0  len[13] =   8 fr, release after 5
        .byte $3D,$0D                       ; C#5  ins  0  len[13] =   8 fr, release after 5
        .byte $3D,$0D                       ; C#5  ins  0  len[13] =   8 fr, release after 5
        .byte $3E,$0A                       ; D-5  ins  0  len[10] =  96 fr, release after 64
        .byte $42,$42                       ; F#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $40,$42                       ; E-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3E,$42                       ; D-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $39,$42                       ; A-4  ins  4  len[ 2] =   6 fr, release after 4
        .byte $42,$42                       ; F#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $40,$42                       ; E-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3E,$42                       ; D-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $39,$42                       ; A-4  ins  4  len[ 2] =   6 fr, release after 4
        .byte $42,$42                       ; F#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $40,$42                       ; E-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3E,$42                       ; D-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $39,$42                       ; A-4  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $36,$05                       ; F#4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3B,$05                       ; B-4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3D,$02                       ; C#5  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3E,$09                       ; D-5  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $41,$0A                       ; F-5  ins  0  len[10] =  96 fr, release after 64
        .byte $41,$42                       ; F-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3F,$42                       ; D#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3D,$42                       ; C#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $38,$42                       ; G#4  ins  4  len[ 2] =   6 fr, release after 4
        .byte $41,$42                       ; F-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3F,$42                       ; D#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3D,$42                       ; C#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $38,$42                       ; G#4  ins  4  len[ 2] =   6 fr, release after 4
        .byte $41,$42                       ; F-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3F,$42                       ; D#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $3D,$42                       ; C#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $38,$42                       ; G#4  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4D,$42                       ; F-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4B,$42                       ; D#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $49,$42                       ; C#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $44,$42                       ; G#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $29,$05                       ; F-3  ins  0  len[ 5] =  18 fr, release after 12
        .byte $2E,$02                       ; A#3  ins  0  len[ 2] =   6 fr, release after 4
        .byte $2C,$06                       ; G#3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2E,$05                       ; A#3  ins  0  len[ 5] =  18 fr, release after 12
        .byte $2F,$02                       ; B-3  ins  0  len[ 2] =   6 fr, release after 4
        .byte $30,$09                       ; C-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $30,$0D                       ; C-4  ins  0  len[13] =   8 fr, release after 5
        .byte $30,$0D                       ; C-4  ins  0  len[13] =   8 fr, release after 5
        .byte $30,$0D                       ; C-4  ins  0  len[13] =   8 fr, release after 5
        .byte $2F,$08                       ; B-3  ins  0  len[ 8] =  48 fr, release after 32
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  24 fr, release after 16
        .byte CMD_RETURN

T_Pattern18:
        .byte $39,$0C                       ; A-4  ins  0  len[12] = 192 fr, release after 128
        .byte CMD_RETURN

T_Pattern01:
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2D,$26                       ; A-3  ins  2  len[ 6] =  24 fr, release after 16
        .byte $2C,$26                       ; G#3  ins  2  len[ 6] =  24 fr, release after 16
        .byte $2A,$25                       ; F#3  ins  2  len[ 5] =  18 fr, release after 12
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $28,$25                       ; E-3  ins  2  len[ 5] =  18 fr, release after 12
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2D,$2E                       ; A-3  ins  2  len[14] =  16 fr, release after 11
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2C,$2E                       ; G#3  ins  2  len[14] =  16 fr, release after 11
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2A,$25                       ; F#3  ins  2  len[ 5] =  18 fr, release after 12
        .byte $28,$25                       ; E-3  ins  2  len[ 5] =  18 fr, release after 12
        .byte $2D,$2E                       ; A-3  ins  2  len[14] =  16 fr, release after 11
        .byte $2C,$2E                       ; G#3  ins  2  len[14] =  16 fr, release after 11
        .byte $2A,$2D                       ; F#3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $28,$2D                       ; E-3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $2D,$24                       ; A-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2C,$24                       ; G#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2A,$24                       ; F#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $28,$24                       ; E-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2D,$24                       ; A-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2C,$24                       ; G#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2A,$24                       ; F#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $28,$2D                       ; E-3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_RETURN

T_Pattern04:
        .byte $35,$39                       ; F-4  ins  3  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $38,$32                       ; G#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $39,$3C                       ; A-4  ins  3  len[12] = 192 fr, release after 128
        .byte $35,$39                       ; F-4  ins  3  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $38,$32                       ; G#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $30,$36                       ; C-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$0A                  ; rest  len[10] =  96 fr
        .byte $3D,$42                       ; C#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $45,$44                       ; A-5  ins  4  len[ 4] =  12 fr, release after 8
        .byte $40,$42                       ; E-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4A,$48                       ; D-6  ins  4  len[ 8] =  48 fr, release after 32
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte $40,$42                       ; E-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $49,$49                       ; C#6  ins  4  len[ 9] =  72 fr, release after 52
        .byte CMD_TIE                       ; toggle tie
        .byte $31,$36                       ; C#4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3D,$39                       ; C#5  ins  3  len[ 9] =  72 fr, release after 52
        .byte CMD_TIE                       ; toggle tie
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $2D,$35                       ; A-3  ins  3  len[ 5] =  18 fr, release after 12
        .byte $2D,$32                       ; A-3  ins  3  len[ 2] =   6 fr, release after 4
        .byte $2D,$36                       ; A-3  ins  3  len[ 6] =  24 fr, release after 16
        .byte $31,$35                       ; C#4  ins  3  len[ 5] =  18 fr, release after 12
        .byte $31,$32                       ; C#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $32,$39                       ; D-4  ins  3  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $34,$36                       ; E-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $53,$42                       ; B-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $51,$42                       ; A-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $31,$35                       ; C#4  ins  3  len[ 5] =  18 fr, release after 12
        .byte $31,$32                       ; C#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $34,$36                       ; E-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $34,$35                       ; E-4  ins  3  len[ 5] =  18 fr, release after 12
        .byte $34,$32                       ; E-4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $39,$39                       ; A-4  ins  3  len[ 9] =  72 fr, release after 52
        .byte $39,$36                       ; A-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3E,$38                       ; D-5  ins  3  len[ 8] =  48 fr, release after 32
        .byte $3E,$36                       ; D-5  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3E,$36                       ; D-5  ins  3  len[ 6] =  24 fr, release after 16
        .byte $45,$36                       ; A-5  ins  3  len[ 6] =  24 fr, release after 16
        .byte $49,$36                       ; C#6  ins  3  len[ 6] =  24 fr, release after 16
        .byte $4C,$36                       ; E-6  ins  3  len[ 6] =  24 fr, release after 16
        .byte $51,$36                       ; A-6  ins  3  len[ 6] =  24 fr, release after 16
        .byte $39,$38                       ; A-4  ins  3  len[ 8] =  48 fr, release after 32
        .byte $50,$44                       ; G#6  ins  4  len[ 4] =  12 fr, release after 8
        .byte $4E,$44                       ; F#6  ins  4  len[ 4] =  12 fr, release after 8
        .byte $4C,$44                       ; E-6  ins  4  len[ 4] =  12 fr, release after 8
        .byte $4A,$44                       ; D-6  ins  4  len[ 4] =  12 fr, release after 8
        .byte $4C,$46                       ; E-6  ins  4  len[ 6] =  24 fr, release after 16
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $3E,$38                       ; D-5  ins  3  len[ 8] =  48 fr, release after 32
        .byte $39,$35                       ; A-4  ins  3  len[ 5] =  18 fr, release after 12
        .byte $31,$32                       ; C#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $31,$39                       ; C#4  ins  3  len[ 9] =  72 fr, release after 52
        .byte CMD_RETURN

T_Pattern07:
        .byte $2D,$57                       ; A-3  ins  5  len[ 7] =  36 fr, release after 24
        .byte $2D,$57                       ; A-3  ins  5  len[ 7] =  36 fr, release after 24
        .byte $2D,$52                       ; A-3  ins  5  len[ 2] =   6 fr, release after 4
        .byte $2D,$52                       ; A-3  ins  5  len[ 2] =   6 fr, release after 4
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2E,$56                       ; A#3  ins  5  len[ 6] =  24 fr, release after 16
        .byte $35,$56                       ; F-4  ins  5  len[ 6] =  24 fr, release after 16
        .byte $3A,$56                       ; A#4  ins  5  len[ 6] =  24 fr, release after 16
        .byte $42,$56                       ; F#5  ins  5  len[ 6] =  24 fr, release after 16
        .byte $2F,$57                       ; B-3  ins  5  len[ 7] =  36 fr, release after 24
        .byte $2F,$57                       ; B-3  ins  5  len[ 7] =  36 fr, release after 24
        .byte $2F,$52                       ; B-3  ins  5  len[ 2] =   6 fr, release after 4
        .byte $2F,$52                       ; B-3  ins  5  len[ 2] =   6 fr, release after 4
        .byte $2F,$54                       ; B-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $30,$57                       ; C-4  ins  5  len[ 7] =  36 fr, release after 24
        .byte $30,$57                       ; C-4  ins  5  len[ 7] =  36 fr, release after 24
        .byte $30,$52                       ; C-4  ins  5  len[ 2] =   6 fr, release after 4
        .byte $30,$52                       ; C-4  ins  5  len[ 2] =   6 fr, release after 4
        .byte $30,$54                       ; C-4  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$54                       ; A-2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte $20,$54                       ; G#2  ins  5  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN

T_Pattern10:
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$56                       ; A-3  ins  5  len[ 6] =  24 fr, release after 16
        .byte $21,$56                       ; A-2  ins  5  len[ 6] =  24 fr, release after 16
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $35,$54                       ; F-4  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte $21,$56                       ; A-2  ins  5  len[ 6] =  24 fr, release after 16
        .byte $35,$54                       ; F-4  ins  5  len[ 4] =  12 fr, release after 8
        .byte $2D,$54                       ; A-3  ins  5  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN

T_Pattern13:
        .byte $32,$36                       ; D-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $2F,$36                       ; B-3  ins  3  len[ 6] =  24 fr, release after 16
        .byte $33,$36                       ; D#4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $35,$36                       ; F-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $32,$36                       ; D-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $2F,$36                       ; B-3  ins  3  len[ 6] =  24 fr, release after 16
        .byte $32,$36                       ; D-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $35,$36                       ; F-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3B,$37                       ; B-4  ins  3  len[ 7] =  36 fr, release after 24
        .byte $38,$31                       ; G#4  ins  3  len[ 1] =   4 fr, release after 2
        .byte $39,$31                       ; A-4  ins  3  len[ 1] =   4 fr, release after 2
        .byte $3A,$31                       ; A#4  ins  3  len[ 1] =   4 fr, release after 2
        .byte $3B,$36                       ; B-4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3E,$36                       ; D-5  ins  3  len[ 6] =  24 fr, release after 16
        .byte $3B,$32                       ; B-4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $3E,$32                       ; D-5  ins  3  len[ 2] =   6 fr, release after 4
        .byte $44,$37                       ; G#5  ins  3  len[ 7] =  36 fr, release after 24
        .byte $3B,$32                       ; B-4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $38,$32                       ; G#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $35,$37                       ; F-4  ins  3  len[ 7] =  36 fr, release after 24
        .byte $32,$32                       ; D-4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $31,$69                       ; C#4  ins  6  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte $38,$32                       ; G#4  ins  3  len[ 2] =   6 fr, release after 4
        .byte $37,$69                       ; G-4  ins  6  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$05                  ; rest  len[ 5] =  18 fr
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$36                       ; G#4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $35,$38                       ; F-4  ins  3  len[ 8] =  48 fr, release after 32
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$3D                       ; G#4  ins  3  len[13] =   8 fr, release after 5
        .byte $38,$36                       ; G#4  ins  3  len[ 6] =  24 fr, release after 16
        .byte $38,$38                       ; G#4  ins  3  len[ 8] =  48 fr, release after 32
        .byte CMD_RETURN

T_Pattern16:
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2F,$0D                       ; B-3  ins  0  len[13] =   8 fr, release after 5
        .byte $2F,$0D                       ; B-3  ins  0  len[13] =   8 fr, release after 5
        .byte $2F,$0D                       ; B-3  ins  0  len[13] =   8 fr, release after 5
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2F,$04                       ; B-3  ins  0  len[ 4] =  12 fr, release after 8
        .byte $2F,$04                       ; B-3  ins  0  len[ 4] =  12 fr, release after 8
        .byte $31,$06                       ; C#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $2D,$06                       ; A-3  ins  0  len[ 6] =  24 fr, release after 16
        .byte $34,$09                       ; E-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $39,$09                       ; A-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $39,$0D                       ; A-4  ins  0  len[13] =   8 fr, release after 5
        .byte $39,$0D                       ; A-4  ins  0  len[13] =   8 fr, release after 5
        .byte $39,$0D                       ; A-4  ins  0  len[13] =   8 fr, release after 5
        .byte $36,$0A                       ; F#4  ins  0  len[10] =  96 fr, release after 64
        .byte $4E,$42                       ; F#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4A,$42                       ; D-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $45,$42                       ; A-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4E,$42                       ; F#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4A,$42                       ; D-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $45,$42                       ; A-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4E,$42                       ; F#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4C,$42                       ; E-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4A,$42                       ; D-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $45,$42                       ; A-5  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $31,$06                       ; C#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3B,$05                       ; B-4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $39,$02                       ; A-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $3A,$09                       ; A#4  ins  0  len[ 9] =  72 fr, release after 52
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  12 fr, release after 8
        .byte $3B,$0A                       ; B-4  ins  0  len[10] =  96 fr, release after 64
        .byte $4D,$42                       ; F-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4B,$42                       ; D#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $49,$42                       ; C#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $44,$42                       ; G#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4D,$42                       ; F-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4B,$42                       ; D#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $49,$42                       ; C#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $44,$42                       ; G#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4D,$42                       ; F-6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $4B,$42                       ; D#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $49,$42                       ; C#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte $44,$42                       ; G#5  ins  4  len[ 2] =   6 fr, release after 4
        .byte $59,$42                       ; F-7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $57,$42                       ; D#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $55,$42                       ; C#7  ins  4  len[ 2] =   6 fr, release after 4
        .byte $50,$42                       ; G#6  ins  4  len[ 2] =   6 fr, release after 4
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $35,$05                       ; F-4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3A,$02                       ; A#4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $38,$06                       ; G#4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $3A,$05                       ; A#4  ins  0  len[ 5] =  18 fr, release after 12
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   6 fr, release after 4
        .byte $34,$09                       ; E-4  ins  0  len[ 9] =  72 fr, release after 52
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $34,$0D                       ; E-4  ins  0  len[13] =   8 fr, release after 5
        .byte $32,$08                       ; D-4  ins  0  len[ 8] =  48 fr, release after 32
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  24 fr, release after 16
        .byte $32,$16                       ; D-4  ins  1  len[ 6] =  24 fr, release after 16
        .byte CMD_RETURN

T_Pattern19:
        .byte $31,$1C                       ; C#4  ins  1  len[12] = 192 fr, release after 128
        .byte CMD_RETURN

T_Pattern02:
        .byte $2D,$26                       ; A-3  ins  2  len[ 6] =  24 fr, release after 16
        .byte $2C,$26                       ; G#3  ins  2  len[ 6] =  24 fr, release after 16
        .byte $2A,$25                       ; F#3  ins  2  len[ 5] =  18 fr, release after 12
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $28,$25                       ; E-3  ins  2  len[ 5] =  18 fr, release after 12
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2D,$2E                       ; A-3  ins  2  len[14] =  16 fr, release after 11
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2C,$2E                       ; G#3  ins  2  len[14] =  16 fr, release after 11
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte $2A,$25                       ; F#3  ins  2  len[ 5] =  18 fr, release after 12
        .byte $28,$25                       ; E-3  ins  2  len[ 5] =  18 fr, release after 12
        .byte $2D,$2E                       ; A-3  ins  2  len[14] =  16 fr, release after 11
        .byte $2C,$2E                       ; G#3  ins  2  len[14] =  16 fr, release after 11
        .byte $2A,$2D                       ; F#3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $28,$2D                       ; E-3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_REST,$02                  ; rest  len[ 2] =   6 fr
        .byte $2D,$24                       ; A-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2C,$24                       ; G#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2A,$24                       ; F#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $28,$24                       ; E-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2D,$24                       ; A-3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2C,$24                       ; G#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $2A,$24                       ; F#3  ins  2  len[ 4] =  12 fr, release after 8
        .byte $28,$2D                       ; E-3  ins  2  len[13] =   8 fr, release after 5
        .byte CMD_REST,$01                  ; rest  len[ 1] =   4 fr
        .byte CMD_RETURN

T_Pattern05:
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN

T_Pattern08:
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$04                  ; rest  len[ 4] =  12 fr
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$09                  ; rest  len[ 9] =  72 fr
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$08                  ; rest  len[ 8] =  48 fr
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte CMD_REST,$06                  ; rest  len[ 6] =  24 fr
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_REST,$07                  ; rest  len[ 7] =  36 fr
        .byte CMD_RETURN

T_Pattern11:
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$26                       ; F-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $11,$26                       ; F-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $11,$26                       ; F-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN

T_Pattern14:
        .byte $13,$26                       ; G-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $13,$26                       ; G-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $13,$26                       ; G-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $13,$26                       ; G-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1F,$26                       ; G-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1F,$26                       ; G-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1F,$26                       ; G-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $1F,$26                       ; G-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$2D                       ; C-2  ins  2  len[13] =   8 fr, release after 5
        .byte $18,$2D                       ; C-2  ins  2  len[13] =   8 fr, release after 5
        .byte $18,$2D                       ; C-2  ins  2  len[13] =   8 fr, release after 5
        .byte $18,$25                       ; C-2  ins  2  len[ 5] =  18 fr, release after 12
        .byte $18,$22                       ; C-2  ins  2  len[ 2] =   6 fr, release after 4
        .byte $1A,$28                       ; D-2  ins  2  len[ 8] =  48 fr, release after 32
        .byte $1A,$2D                       ; D-2  ins  2  len[13] =   8 fr, release after 5
        .byte $1A,$2D                       ; D-2  ins  2  len[13] =   8 fr, release after 5
        .byte $1A,$2D                       ; D-2  ins  2  len[13] =   8 fr, release after 5
        .byte $1A,$25                       ; D-2  ins  2  len[ 5] =  18 fr, release after 12
        .byte $1A,$22                       ; D-2  ins  2  len[ 2] =   6 fr, release after 4
        .byte $1B,$28                       ; D#2  ins  2  len[ 8] =  48 fr, release after 32
        .byte CMD_RETURN

T_Pattern17:
        .byte $14,$06                       ; G#1  ins  0  len[ 6] =  24 fr, release after 16
        .byte $14,$2D                       ; G#1  ins  2  len[13] =   8 fr, release after 5
        .byte $14,$2D                       ; G#1  ins  2  len[13] =   8 fr, release after 5
        .byte $14,$2D                       ; G#1  ins  2  len[13] =   8 fr, release after 5
        .byte $14,$26                       ; G#1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $14,$26                       ; G#1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $12,$26                       ; F#1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1A,$24                       ; D-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $13,$24                       ; G-1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  12 fr, release after 8
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  24 fr, release after 16
        .byte $10,$26                       ; E-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $10,$26                       ; E-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $10,$26                       ; E-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte $10,$26                       ; E-1  ins  2  len[ 6] =  24 fr, release after 16
        .byte CMD_RETURN

T_Pattern20:
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  12 fr, release after 8
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  12 fr, release after 8
        .byte CMD_RETURN
; ---- 46 byte(s) not referenced by the sound engine ----
        .res 46, $00

; SID ripper wrapper (not part of the game): song 1 = title driver at
; $E000, song 2 = in-game driver at $EE00. Patches the high byte of
; both JMPs, then inits the chosen driver with A = 0.
Rip_Init:
        jmp Rip_InitSong

Rip_Play:
Rip_PlayHi := * + 2
        jmp T_Play

Rip_InitSong:
        tax
        lda Rip_DriverHi,x
        sta Rip_InitHi
        sta Rip_PlayHi
        lda #$00
Rip_InitHi := * + 2
        jmp T_Init

Rip_DriverHi:
        .byte $E0,$EE                       ; high byte of each driver, per song
; ---- 25 byte(s) not referenced by the sound engine ----
        .res 25, $00

; Entry points. Init: A = song (this driver holds one song: 0).
G_Init:
        jmp G_SongInit

; Play: once per frame. Voices 2, 1, 0.
; If the driver is stopped it jumps to $C19F: the ripper did not
; relocate this JMP (should be G_PlayExit). Only reachable after
; CMD_STOP, which the in-game tune never uses.
G_Play:
        lda zTrkPtr
        pha
        lda zTrkPtr+1
        pha
        lda G_mEnabled
        bne G_Run
        jmp G_PlayExit-RIP_RELOC            ; unrelocated ($C19F)

G_Run:
        ldx #$02

; X = voice. Release the gate when the release timer runs out
; (unless tied).
G_VoiceLoop:
        stx G_mVoice
        lda G_VoiceRegOfs,x
        sta G_mRegOfs
        ldy G_mCurInst,x
        sty G_mInst
        lda G_mRelTimer,x
        beq G_TickNote
        dec G_mRelTimer,x
        bne G_TickNote
        lda G_mTie,x
        bne G_TickNote
        sta G_mPlaying                      ; no ,x: always clears voice 0 (never read anyway)
        lda G_InsCtrlRel,y
        ldy G_mRegOfs
        sta SID_V1_CTRL,y

; Note timer: 0 = start the read-ahead note, 1 = read the next
; event (one frame early), otherwise run the vibrato.
G_TickNote:
        dec G_mTimer,x
        lda G_mTimer,x
        beq G_StartNote
        cmp #$01
        beq G_ReadEvent
        jmp G_Vibrato

G_ReadEvent:
        lda G_mTrkLo,x
        sta zTrkPtr
        lda G_mTrkHi,x
        sta zTrkPtr+1
        ldy #$00

G_ParseEvent:
        lda (zTrkPtr),y
        bmi G_Note
        cmp #$60
        bcc G_Note
        jmp G_Command

; Note: same 2-byte format as the title driver.
G_Note:
        sta G_zEvByte0
        and #$7F
        clc
        adc G_mTranspose,x
        sta G_mNextNote,x
        iny
        lda (zTrkPtr),y
        pha
        iny
        sty G_mEvLen
        and #$0F
        tay
        lda G_DurTable,y
        sta G_mNextLen,x
        lda G_RelTable,y
        sta G_mNextRel,x
        pla
        rol G_zEvByte0
        ror a
        lsr a
        lsr a
        lsr a
        sta G_mNextInst,x
        lda #$00
        sta G_mNextRest,x

; Track pointer += Y.
G_AdvanceTrack:
        lda G_mEvLen
        clc
        adc zTrkPtr
        sta G_mTrkLo,x
        lda zTrkPtr+1
        adc #$00
        sta G_mTrkHi,x
        jmp G_WriteVoice

G_StartNote:
        lda G_mNextInst,x
        sta G_mCurInst,x
        sta G_mInst
        tay
        lda G_mNextRest,x
        beq G_LoadInstrument
        jmp G_StartTimers

; Pulse width and vibrato from the instrument (the PWM columns are
; still in the table but not read), frequency, AD, SR, control.
G_LoadInstrument:
        lda G_InsPwLo,y
        sta G_mPwLo,x
        lda G_InsPwHi,y
        sta G_mPwHi,x
        lda G_InsVibDepth,y
        sta G_mVibDepth,x
        lda G_InsVibLen,y
        sta G_mVibTimer,x
        lda G_InsVibDelay,y
        sta G_mVibDelay,x
        lda #$00
        sta G_mVibDir,x
        sta G_mVibFull,x
        lda #$01
        sta G_mPlaying,x
        lda G_mNextNote,x
        sta G_mNote,x
        tay
        lda G_FreqLo,y
        sta G_mFreqLo,x
        lda G_FreqHi,y
        sta G_mFreqHi,x
        ldy G_mInst
        ldx G_mRegOfs
        lda G_InsAD,y
        sta SID_V1_AD,x
        lda G_InsSR,y
        sta SID_V1_SR,x
        lda G_InsCtrl,y
        sta SID_V1_CTRL,x
        ldx G_mVoice

G_StartTimers:
        lda G_mNextLen,x
        sta G_mTimer,x
        lda G_mNextRel,x
        sta G_mRelTimer,x
        lda G_mNextRest,x
        sta G_mRest,x
        jmp G_WriteVoice

; Vibrato (as the title driver). The delay countdown below writes to
; $C2EE,x: not relocated by the ripper (should be G_mVibDelay); no
; instrument in this tune has a vibrato delay.
G_Vibrato:
        ldy G_mInst
        lda G_InsVibDepth,y
        beq G_WriteVoice
        lda G_mVibDelay,x
        beq G_VibTick
        dec G_mVibDelay-RIP_RELOC,x         ; unrelocated ($C2EE)
        bpl G_WriteVoice

G_VibTick:
        dec G_mVibTimer,x
        bne G_VibApply
        lda G_InsVibLen,y
        sta G_mVibTimer,x
        lda G_mVibDir,x
        eor #$01
        sta G_mVibDir,x
        lda G_mVibFull,x
        bne G_VibApply
        inc G_mVibFull,x
        asl G_mVibDepth,x

G_VibApply:
        lda G_mVibDir,x
        bne G_VibDown
        lda G_mFreqLo,x                     ; no CLC: a leftover carry adds 1
        adc G_mVibDepth,x
        sta G_mFreqLo,x
        bcc G_WriteVoice
        inc G_mFreqHi,x
        jmp G_WriteVoice

G_VibDown:
        lda G_mFreqLo,x
        sec
        sbc G_mVibDepth,x
        sta G_mFreqLo,x
        bcs G_WriteVoice
        dec G_mFreqHi,x

; Frequency and pulse width to the SID; next voice.
G_WriteVoice:
        ldy G_mRegOfs
        lda G_mFreqLo,x
        sta SID_V1_FREQ_LO,y
        lda G_mFreqHi,x
        sta SID_V1_FREQ_HI,y
        lda G_mPwLo,x
        sta SID_V1_PW_LO,y
        lda G_mPwHi,x
        sta SID_V1_PW_HI,y
        dex
        bmi G_PlayExit
        jmp G_VoiceLoop

G_PlayExit:
        pla
        sta zTrkPtr+1
        pla
        sta zTrkPtr
        rts

; Command byte: $6B stops, $60-$6A jump through CmdLo/CmdHi.
G_Command:
        cmp #$6B
        beq G_Cmd_Stop
        sec
        sbc #$60
        tax
        lda G_CmdLo,x
        sta G_CmdJumpVec
        lda G_CmdHi,x
        sta G_CmdJump+2
        ldx G_mVoice
        iny
        sty G_mEvLen

G_CmdJump:
G_CmdJumpVec := * + 1
        jmp G_Cmd_Rest-RIP_RELOC            ; operand patched by Command (snapshot $C1D5: unrelocated)

; $6B CMD_STOP (two unrelocated addresses: the STA should hit
; G_mEnabled, the JMP G_PlayExit).
G_Cmd_Stop:
        lda #$00
        sta G_mEnabled-RIP_RELOC            ; unrelocated ($C291)
        sta SID_V1_CTRL
        sta SID_V2_CTRL
        sta SID_V3_CTRL
        jmp G_PlayExit-RIP_RELOC            ; unrelocated ($C19F)

; $60 CMD_REST len
G_Cmd_Rest:
        lda (zTrkPtr),y
        iny
        sty G_mEvLen
        tay
        lda G_DurTable,y
        sta G_mNextLen,x
        lda #$01
        sta G_mNextRest,x
        jmp G_AdvanceTrack

; $61 CMD_TIE (unrelocated: $C2CE = G_mTie, $C058 = G_ParseEvent).
G_Cmd_Tie:
        lda G_mTie-RIP_RELOC,x              ; unrelocated ($C2CE)
        eor #$01
        sta G_mTie-RIP_RELOC,x              ; unrelocated ($C2CE)
        jmp G_ParseEvent-RIP_RELOC          ; unrelocated ($C058)

; $62 x (unrelocated: $C2DB = G_mNop62, $C058 = G_ParseEvent).
G_Cmd_Nop62:
        lda (zTrkPtr),y
        sta G_mNop62-RIP_RELOC              ; unrelocated ($C2DB)
        iny
        jmp G_ParseEvent-RIP_RELOC          ; unrelocated ($C058)

; $63 CMD_VOLUME v (no filter in this build: plain volume).
G_Cmd_Volume:
        lda (zTrkPtr),y
        sta G_mVolume
        sta SID_MODE_VOL
        iny
        jmp G_ParseEvent

; $65 CMD_CALLN count, pattern, transpose
G_Cmd_CallN:
        lda (zTrkPtr),y
        sta G_mRepeat,x
        iny

; $64 CMD_CALL pattern, transpose
G_Cmd_Call:
        lda (zTrkPtr),y
        pha
        iny
        lda (zTrkPtr),y
        sta G_mTranspose,x
        iny
        tya
        clc
        adc zTrkPtr
        sta G_mRetLo,x
        lda zTrkPtr+1
        adc #$00
        sta G_mRetHi,x
        pla
        tay
        lda G_PatLo,y
        sta zTrkPtr
        sta G_mPatLo,x
        lda G_PatHi,y
        sta zTrkPtr+1
        sta G_mPatHi,x
        ldy #$00
        jmp G_ParseEvent

; $66 CMD_RETURN
G_Cmd_Return:
        lda G_mRepeat,x
        beq G_ReturnDone
        dec G_mRepeat,x
        beq G_ReturnDone
        lda G_mPatLo,x
        sta zTrkPtr
        lda G_mPatHi,x
        sta zTrkPtr+1
        bne G_ReturnGo

G_ReturnDone:
        lda G_mRetLo,x
        sta zTrkPtr
        lda G_mRetHi,x
        sta zTrkPtr+1
        lda #$00
        sta G_mTranspose,x

G_ReturnGo:
        ldy #$00
        jmp G_ParseEvent

; $67 CMD_RESTART (unrelocated: $C2xx = G_ variables, $C04C =
; G_ReadEvent).
G_Cmd_Restart:
        lda G_mTrkStartLo-RIP_RELOC,x       ; unrelocated ($C2A4)
        sta G_mTrkLo-RIP_RELOC,x            ; unrelocated ($C298)
        lda G_mTrkStartHi-RIP_RELOC,x       ; unrelocated ($C2A7)
        sta G_mTrkHi-RIP_RELOC,x            ; unrelocated ($C29B)
        lda #$00
        sta G_mTranspose-RIP_RELOC,x        ; unrelocated ($C2D4)
        jmp G_ReadEvent-RIP_RELOC           ; unrelocated ($C04C)

; $68 CMD_JUMP .word address
G_Cmd_Jump:
        lda (zTrkPtr),y
        sta G_mTrkLo,x
        iny
        lda (zTrkPtr),y
        sta G_mTrkHi,x
        jmp G_ReadEvent

G_zEvByte0:
        .byte $6A                           ; byte 0 of the event being read (bit 7 = instrument bit 4)

G_Unused01:
        .byte $00

G_mEvLen:
        .byte $02                           ; Y: length of the event just read

G_mVoice:
        .byte $00                           ; current voice (2, 1, 0)

G_mRegOfs:
        .byte $00                           ; SID register offset of the current voice

G_mInst:
        .byte $00                           ; instrument of the current voice

G_mEnabled:
        .byte $0F                           ; 0 = driver stopped (CMD_STOP)

G_VoiceRegOfs:
        .byte $00,$07,$0E                   ; SID register offset per voice

G_VoiceBit:
        .byte $01,$02,$04                   ; filter routing bit per voice

G_mTrkLo:
        .byte $D5,$41,$77                   ; track / pattern pointer

G_mTrkHi:
        .byte $C4,$C7,$C9

G_mRetLo:
        .byte $4F,$6C,$8B                   ; return address (after a CMD_CALL)

G_mRetHi:
        .byte $C4,$C4,$C4

G_mTrkStartLo:
        .byte $47,$66,$85                   ; start of the track (CMD_RESTART)

G_mTrkStartHi:
        .byte $C4,$C4,$C4

G_mPatLo:
        .byte $A3,$0F,$45                   ; start of the called pattern (for repeats)

G_mPatHi:
        .byte $C4,$C7,$C9

G_mNote:
        .byte $35,$32,$28                   ; note playing (written, never read)

G_mNextNote:
        .byte $35,$32,$28                   ; note read ahead (transposed)

G_mCurInst:
        .byte $00,$01,$02                   ; instrument playing

G_mNextInst:
        .byte $00,$01,$02                   ; instrument read ahead

G_mTimer:
        .byte $0E,$0E,$04                   ; frames left of the note

G_mNextLen:
        .byte $14,$14,$0A                   ; length of the next note (DurTable)

G_mRelTimer:
        .byte $07,$07,$00                   ; frames until the gate is released

G_mNextRel:
        .byte $0D,$0D,$01                   ; release time of the next note (RelTable)

G_mNextRest:
        .byte $00,$00,$01                   ; 1 = the next event is a rest

G_mRest:
        .byte $00,$00,$01                   ; rest flag of the current event (written, never read)

G_mTie:
        .byte $00,$00,$00                   ; toggled by CMD_TIE: no gate release, no retrigger

G_mPlaying:
        .byte $00,$01,$01                   ; set at each note start (written, never read)

G_mTranspose:
        .byte $00,$00,$0C                   ; added to the notes of a called pattern

G_mRepeat:
        .byte $00,$00,$00                   ; CMD_CALLN repeat count

G_mVolume:
        .byte $0F                           ; master volume (CMD_VOLUME)

G_mNop62:
        .byte $00                           ; CMD_NOP62 parameter (written, never read)

G_mFreqLo:
        .byte $0C,$5B,$F5                   ; current frequency (with vibrato)

G_mFreqHi:
        .byte $17,$13,$0A

G_mPwLo:
        .byte $00,$00,$10                   ; current pulse width

G_mPwHi:
        .byte $00,$00,$06

G_mVibDepth:
        .byte $20,$20,$00                   ; vibrato step (doubled after the first half swing)

G_mVibTimer:
        .byte $02,$02,$00                   ; frames left in this vibrato direction

G_mVibDelay:
        .byte $00,$00,$00                   ; frames before the vibrato starts

G_mVibDir:
        .byte $01,$01,$00                   ; vibrato direction (0 = up)

G_mVibFull:
        .byte $01,$01,$00                   ; 1 once the depth has been doubled

G_CmdLo:
        .lobytes G_Cmd_Rest                 ; $60 CMD_REST
        .lobytes G_Cmd_Tie-RIP_RELOC        ; $61 CMD_TIE  unrelocated ($C1EA)
        .lobytes G_Cmd_Nop62-RIP_RELOC      ; $62 CMD_NOP62  unrelocated ($C1F5)
        .lobytes G_Cmd_Volume               ; $63 CMD_VOLUME
        .lobytes G_Cmd_Call                 ; $64 CMD_CALL
        .lobytes G_Cmd_CallN                ; $65 CMD_CALLN
        .lobytes G_Cmd_Return               ; $66 CMD_RETURN
        .lobytes G_Cmd_Restart-RIP_RELOC    ; $67 CMD_RESTART  unrelocated ($C269)
        .lobytes G_Cmd_Jump                 ; $68 CMD_JUMP
        .lobytes G_zEvByte0-RIP_RELOC       ; $69 CMD_FILTER  unrelocated ($C28B): no filter command in this build, points at a variable
        .lobytes G_zEvByte0-RIP_RELOC       ; $6A CMD_FILTER2  unrelocated ($C28B): no filter command in this build, points at a variable

G_CmdHi:
        .hibytes G_Cmd_Rest                 ; $60 CMD_REST
        .hibytes G_Cmd_Tie-RIP_RELOC        ; $61 CMD_TIE  unrelocated ($C1EA)
        .hibytes G_Cmd_Nop62-RIP_RELOC      ; $62 CMD_NOP62  unrelocated ($C1F5)
        .hibytes G_Cmd_Volume               ; $63 CMD_VOLUME
        .hibytes G_Cmd_Call                 ; $64 CMD_CALL
        .hibytes G_Cmd_CallN                ; $65 CMD_CALLN
        .hibytes G_Cmd_Return               ; $66 CMD_RETURN
        .hibytes G_Cmd_Restart-RIP_RELOC    ; $67 CMD_RESTART  unrelocated ($C269)
        .hibytes G_Cmd_Jump                 ; $68 CMD_JUMP
        .hibytes G_zEvByte0-RIP_RELOC       ; $69 CMD_FILTER  unrelocated ($C28B): no filter command in this build, points at a variable
        .hibytes G_zEvByte0-RIP_RELOC       ; $6A CMD_FILTER2  unrelocated ($C28B): no filter command in this build, points at a variable

; SID frequency per note, C0..B7 (PAL tuned: A4 = $1D46 = 440.1 Hz on PAL).
G_FreqLo:
        .lobytes $0116,$0127,$0128,$014B,$015F,$0173,$018A,$01A1,$01BA,$01D4,$01F0,$020E ; octave 0
        .lobytes $022D,$024E,$0271,$0296,$02BD,$02E7,$0313,$0342,$0374,$03A9,$03E0,$041B ; octave 1
        .lobytes $045A,$049B,$04E2,$052C,$057B,$05CE,$0627,$0685,$06E8,$0751,$07C1,$0837 ; octave 2
        .lobytes $08B4,$0937,$09C4,$0A57,$0AF5,$0B9C,$0C4E,$0D09,$0DD0,$0EA3,$0F82,$106E ; octave 3
        .lobytes $1168,$126E,$1388,$14AF,$15EB,$1739,$189C,$1A13,$1BA1,$1D46,$1F04,$20DC ; octave 4
        .lobytes $22D0,$24DC,$2710,$295E,$2BD6,$2E72,$3138,$3426,$3742,$3A8C,$3E08,$41B8 ; octave 5
        .lobytes $45A0,$49B8,$4E20,$52BC,$57AC,$5CE4,$6270,$684C,$6E84,$7581,$7C10,$8370 ; octave 6
        .lobytes $8B40,$9370,$9C40,$A578,$AF58,$B9C8,$C4E0,$D098,$DD08,$EA30,$F820,$FD2E ; octave 7

G_FreqHi:
        .hibytes $0116,$0127,$0128,$014B,$015F,$0173,$018A,$01A1,$01BA,$01D4,$01F0,$020E ; octave 0
        .hibytes $022D,$024E,$0271,$0296,$02BD,$02E7,$0313,$0342,$0374,$03A9,$03E0,$041B ; octave 1
        .hibytes $045A,$049B,$04E2,$052C,$057B,$05CE,$0627,$0685,$06E8,$0751,$07C1,$0837 ; octave 2
        .hibytes $08B4,$0937,$09C4,$0A57,$0AF5,$0B9C,$0C4E,$0D09,$0DD0,$0EA3,$0F82,$106E ; octave 3
        .hibytes $1168,$126E,$1388,$14AF,$15EB,$1739,$189C,$1A13,$1BA1,$1D46,$1F04,$20DC ; octave 4
        .hibytes $22D0,$24DC,$2710,$295E,$2BD6,$2E72,$3138,$3426,$3742,$3A8C,$3E08,$41B8 ; octave 5
        .hibytes $45A0,$49B8,$4E20,$52BC,$57AC,$5CE4,$6270,$684C,$6E84,$7581,$7C10,$8370 ; octave 6
        .hibytes $8B40,$9370,$9C40,$A578,$AF58,$B9C8,$C4E0,$D098,$DD08,$EA30,$F820,$FD2E ; octave 7

; Song A: track pointers, timers = 2, clear the SID, volume 15, enable.
G_SongInit:
        tax
        ldy #$00

G_InitLoop:
        lda G_TrkLo,x
        sta G_mTrkLo,y
        sta G_mTrkStartLo,y
        lda G_TrkHi,x
        sta G_mTrkHi,y
        sta G_mTrkStartHi,y
        lda #$02
        sta G_mTimer,y
        inx
        iny
        cpy #$03
        bne G_InitLoop
        ldx #$17
        lda #$00

G_ClearSid:
        sta SID_V1_FREQ_LO,x
        dex
        bpl G_ClearSid
        lda #$0F
        sta SID_MODE_VOL
        sta G_mEnabled
        rts

G_DurTable:
        .byte $02,$03,$05,$07,$0A,$0F,$14,$1E,$28,$3C,$50,$78,$A0,$08,$04,$06 ; frames per length index 0-15

G_RelTable:
        .byte $01,$02,$03,$04,$06,$0A,$0D,$14,$1A,$28,$3C,$50,$6E,$06,$02,$04 ; frames before the gate is released, per length index

; INSTRUMENTS: 3 instruments, stored as 11 columns (one byte per
; instrument in each).
G_InsCtrl:
        .byte $11,$11,$11                   ; control register at note start (waveform + gate)

G_InsCtrlRel:
        .byte $10,$10,$10                   ; control register at release (gate off)

G_InsAD:
        .byte $75,$64,$7D                   ; attack / decay

G_InsSR:
        .byte $6A,$4A,$F8                   ; sustain / release

G_InsPwLo:
        .byte $00,$00,$10                   ; pulse width low

G_InsPwHi:
        .byte $00,$00,$06                   ; pulse width high

G_InsPwmStep:
        .byte $00,$00,$20                   ; PWM: added to / taken from the pulse width every frame (0 = off) -- not read by this build

G_InsPwmLen:
        .byte $00,$00,$20                   ; PWM: frames per direction -- not read by this build

G_InsVibDepth:
        .byte $10,$10,$00                   ; vibrato depth (frequency units, 0 = off)

G_InsVibLen:
        .byte $04,$04,$00                   ; vibrato: frames per direction

G_InsVibDelay:
        .byte $00,$00,$00                   ; vibrato delay in frames

; SONG: one track per voice.
G_TrkLo:
        .lobytes G_Track_V1, G_Track_V2, G_Track_V3 ; song 0: voice 1, 2, 3

G_TrkHi:
        .hibytes G_Track_V1, G_Track_V2, G_Track_V3

G_Track_V1:
        .byte CMD_VOLUME,$0F                ; volume 15

G_Track_V1_Loop:
        .byte CMD_CALL,G_Pattern00_ID,$00   ; G_Pattern00, transpose +0
        .byte CMD_CALL,G_Pattern03_ID,$00   ; G_Pattern03, transpose +0
        .byte CMD_REST,$0A                  ; rest  len[10] =  80 fr
        .byte CMD_CALL,G_Pattern06_ID,$00   ; G_Pattern06, transpose +0
        .byte CMD_CALL,G_Pattern06_ID,$0C   ; G_Pattern06, transpose +12
        .byte CMD_CALL,G_Pattern09_ID,$00   ; G_Pattern09, transpose +0
        .byte CMD_CALL,G_Pattern12_ID,$00   ; G_Pattern12, transpose +0
        .byte CMD_CALL,G_Pattern12_ID,$05   ; G_Pattern12, transpose +5
        .byte CMD_CALL,G_Pattern15_ID,$0C   ; G_Pattern15, transpose +12
        .byte CMD_JUMP
        .word G_Track_V1_Loop               ; loop

G_Track_V2:
        .byte CMD_CALL,G_Pattern01_ID,$00   ; G_Pattern01, transpose +0
        .byte CMD_CALL,G_Pattern04_ID,$00   ; G_Pattern04, transpose +0
        .byte CMD_REST,$0A                  ; rest  len[10] =  80 fr
        .byte CMD_CALL,G_Pattern07_ID,$00   ; G_Pattern07, transpose +0
        .byte CMD_CALL,G_Pattern07_ID,$0C   ; G_Pattern07, transpose +12
        .byte CMD_CALL,G_Pattern10_ID,$00   ; G_Pattern10, transpose +0
        .byte CMD_CALL,G_Pattern13_ID,$00   ; G_Pattern13, transpose +0
        .byte CMD_CALL,G_Pattern13_ID,$F9   ; G_Pattern13, transpose -7
        .byte CMD_CALL,G_Pattern16_ID,$0C   ; G_Pattern16, transpose +12
        .byte CMD_JUMP
        .word G_Track_V2                    ; loop
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $60,$0A

G_Track_V3:
        .byte CMD_CALL,G_Pattern02_ID,$0C   ; G_Pattern02, transpose +12
        .byte CMD_CALL,G_Pattern05_ID,$0C   ; G_Pattern05, transpose +12
        .byte CMD_CALLN,$09,G_Pattern08_ID,$0C ; G_Pattern08, transpose +12, play 9x
        .byte CMD_CALL,G_Pattern11_ID,$0C   ; G_Pattern11, transpose +12
        .byte CMD_CALL,G_Pattern14_ID,$0C   ; G_Pattern14, transpose +12
        .byte CMD_CALL,G_Pattern14_ID,$11   ; G_Pattern14, transpose +17
        .byte CMD_CALL,G_Pattern17_ID,$0C   ; G_Pattern17, transpose +12
        .byte CMD_JUMP
        .word G_Track_V3                    ; loop

G_Pattern00:
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$07                  ; rest  len[ 7] =  30 fr
        .byte CMD_RETURN

G_Pattern03:
        .byte $35,$06                       ; F-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $34,$05                       ; E-4  ins  0  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $30,$05                       ; C-4  ins  0  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $32,$04                       ; D-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $2F,$04                       ; B-3  ins  0  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $30,$04                       ; C-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $35,$06                       ; F-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $30,$06                       ; C-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  20 fr, release after 13
        .byte $30,$06                       ; C-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $35,$06                       ; F-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $30,$06                       ; C-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $32,$06                       ; D-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $2F,$06                       ; B-3  ins  0  len[ 6] =  20 fr, release after 13
        .byte $30,$06                       ; C-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3C,$0A                       ; C-5  ins  0  len[10] =  80 fr, release after 60
        .byte $40,$0A                       ; E-5  ins  0  len[10] =  80 fr, release after 60
        .byte CMD_RETURN

G_Pattern06:
        .byte $3C,$06                       ; C-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$06                       ; B-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$07                       ; E-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $40,$07                       ; E-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $40,$06                       ; E-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern09:
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3A,$04                       ; A#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3F,$06                       ; D#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3D,$06                       ; C#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3F,$04                       ; D#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $41,$04                       ; F-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $42,$06                       ; F#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3F,$06                       ; D#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$04                       ; F-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $43,$04                       ; G-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $44,$04                       ; G#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $44,$06                       ; G#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $43,$04                       ; G-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$06                       ; C-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3C,$06                       ; C-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $44,$04                       ; G#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $43,$06                       ; G-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$08                       ; C-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $41,$02                       ; F-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $43,$02                       ; G-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $48,$04                       ; C-6  ins  0  len[ 4] =  10 fr, release after 6
        .byte $48,$04                       ; C-6  ins  0  len[ 4] =  10 fr, release after 6
        .byte $46,$04                       ; A#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $43,$04                       ; G-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $46,$04                       ; A#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $44,$04                       ; G#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $43,$04                       ; G-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $41,$04                       ; F-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $41,$04                       ; F-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $42,$06                       ; F#5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $49,$07                       ; C#6  ins  0  len[ 7] =  30 fr, release after 20
        .byte $49,$06                       ; C#6  ins  0  len[ 6] =  20 fr, release after 13
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3D,$04                       ; C#5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3A,$04                       ; A#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$06                       ; B-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$07                       ; F-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $30,$07                       ; C-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $2F,$02                       ; B-3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $2D,$02                       ; A-3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $2C,$04                       ; G#3  ins  0  len[ 4] =  10 fr, release after 6
        .byte $28,$07                       ; E-3  ins  0  len[ 7] =  30 fr, release after 20
        .byte $33,$07                       ; D#4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $34,$02                       ; E-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $36,$02                       ; F#4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $34,$08                       ; E-4  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3C,$07                       ; C-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$02                       ; A-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$07                       ; E-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $42,$02                       ; F#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $40,$08                       ; E-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3D,$07                       ; C#5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3A,$02                       ; A#4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $35,$07                       ; F-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $40,$07                       ; E-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $42,$02                       ; F#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $43,$02                       ; G-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $41,$08                       ; F-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3E,$07                       ; D-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $3D,$02                       ; C#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3A,$04                       ; A#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $36,$07                       ; F#4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $41,$07                       ; F-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $42,$02                       ; F#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $44,$02                       ; G#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $42,$08                       ; F#5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3F,$07                       ; D#5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $37,$07                       ; G-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $42,$07                       ; F#5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $43,$02                       ; G-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $45,$02                       ; A-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $43,$07                       ; G-5  ins  0  len[ 7] =  30 fr, release after 20
        .byte $44,$02                       ; G#5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $45,$02                       ; A-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $44,$08                       ; G#5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $41,$08                       ; F-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $40,$08                       ; E-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3E,$08                       ; D-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $40,$06                       ; E-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$09                  ; rest  len[ 9] =  60 fr
        .byte CMD_RETURN

G_Pattern12:
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$06                       ; C-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3E,$06                       ; D-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $41,$06                       ; F-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$02                       ; A-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$02                       ; A-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $38,$02                       ; G#4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $35,$04                       ; F-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $32,$04                       ; D-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $30,$04                       ; C-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $38,$06                       ; G#4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3B,$06                       ; B-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$08                       ; E-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $41,$02                       ; F-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $43,$02                       ; G-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $41,$02                       ; F-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$08                       ; D-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $41,$02                       ; F-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$08                       ; C-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3E,$04                       ; D-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $40,$04                       ; E-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3C,$04                       ; C-5  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$04                       ; A-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $3B,$04                       ; B-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $39,$06                       ; A-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern15:
        .byte $2B,$06                       ; G-3  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $32,$04                       ; D-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $31,$06                       ; C#4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $36,$04                       ; F#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $33,$06                       ; D#4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $36,$04                       ; F#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $37,$04                       ; G-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $33,$04                       ; D#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $2F,$04                       ; B-3  ins  0  len[ 4] =  10 fr, release after 6
        .byte $30,$06                       ; C-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $36,$04                       ; F#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$04                       ; E-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $33,$06                       ; D#4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $36,$04                       ; F#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $3A,$04                       ; A#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $38,$04                       ; G#4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $37,$04                       ; G-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $35,$04                       ; F-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $37,$04                       ; G-4  ins  0  len[ 4] =  10 fr, release after 6
        .byte $27,$08                       ; D#3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $2E,$08                       ; A#3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $2F,$08                       ; B-3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $26,$07                       ; D-3  ins  0  len[ 7] =  30 fr, release after 20
        .byte $27,$02                       ; D#3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $29,$02                       ; F-3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $27,$08                       ; D#3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3A,$08                       ; A#4  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3B,$08                       ; B-4  ins  0  len[ 8] =  40 fr, release after 26
        .byte $32,$07                       ; D-4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $33,$02                       ; D#4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $35,$02                       ; F-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $28,$08                       ; E-3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $2F,$08                       ; B-3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $30,$08                       ; C-4  ins  0  len[ 8] =  40 fr, release after 26
        .byte $27,$07                       ; D#3  ins  0  len[ 7] =  30 fr, release after 20
        .byte $28,$02                       ; E-3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $2A,$02                       ; F#3  ins  0  len[ 2] =   5 fr, release after 3
        .byte $28,$08                       ; E-3  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3B,$08                       ; B-4  ins  0  len[ 8] =  40 fr, release after 26
        .byte $3C,$08                       ; C-5  ins  0  len[ 8] =  40 fr, release after 26
        .byte $33,$07                       ; D#4  ins  0  len[ 7] =  30 fr, release after 20
        .byte $34,$02                       ; E-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $36,$02                       ; F#4  ins  0  len[ 2] =   5 fr, release after 3
        .byte $34,$06                       ; E-4  ins  0  len[ 6] =  20 fr, release after 13
        .byte $40,$06                       ; E-5  ins  0  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $41,$02                       ; F-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $40,$02                       ; E-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3E,$02                       ; D-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3C,$02                       ; C-5  ins  0  len[ 2] =   5 fr, release after 3
        .byte $3B,$02                       ; B-4  ins  0  len[ 2] =   5 fr, release after 3
        .byte CMD_RETURN

G_Pattern01:
        .byte $30,$14                       ; C-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$07                  ; rest  len[ 7] =  30 fr
        .byte CMD_RETURN

G_Pattern04:
        .byte $32,$16                       ; D-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $30,$15                       ; C-4  ins  1  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $2D,$15                       ; A-3  ins  1  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $2C,$14                       ; G#3  ins  1  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $2D,$14                       ; A-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $30,$14                       ; C-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $32,$16                       ; D-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $30,$16                       ; C-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2C,$16                       ; G#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $30,$16                       ; C-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $32,$16                       ; D-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $30,$16                       ; C-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2C,$16                       ; G#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $30,$16                       ; C-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $36,$1A                       ; F#4  ins  1  len[10] =  80 fr, release after 60
        .byte $38,$1A                       ; G#4  ins  1  len[10] =  80 fr, release after 60
        .byte CMD_RETURN

G_Pattern07:
        .byte $34,$16                       ; E-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$16                       ; E-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$17                       ; B-3  ins  1  len[ 7] =  30 fr, release after 20
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $37,$14                       ; G-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3B,$17                       ; B-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3B,$16                       ; B-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern10:
        .byte $3D,$14                       ; C#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$14                       ; G#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$14                       ; G#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $35,$14                       ; F-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$16                       ; C-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3A,$16                       ; A#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3A,$14                       ; A#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3A,$14                       ; A#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3E,$14                       ; D-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3D,$14                       ; C#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3D,$14                       ; C#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $37,$14                       ; G-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$16                       ; C-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3C,$16                       ; C-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $41,$16                       ; F-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $41,$14                       ; F-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$16                       ; G#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $38,$16                       ; G#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $41,$14                       ; F-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $41,$14                       ; F-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$14                       ; G#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$18                       ; G#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $44,$14                       ; G#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $44,$14                       ; G#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $43,$14                       ; G-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $43,$14                       ; G-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $41,$14                       ; F-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3F,$14                       ; D#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3F,$16                       ; D#5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $46,$17                       ; A#5  ins  1  len[ 7] =  30 fr, release after 20
        .byte $46,$16                       ; A#5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $35,$14                       ; F-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $35,$16                       ; F-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3B,$17                       ; B-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3B,$16                       ; B-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $39,$16                       ; A-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $39,$16                       ; A-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $38,$16                       ; G#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $38,$16                       ; G#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $37,$16                       ; G-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $37,$16                       ; G-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $36,$16                       ; F#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $36,$16                       ; F#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $27,$17                       ; D#3  ins  1  len[ 7] =  30 fr, release after 20
        .byte $27,$12                       ; D#3  ins  1  len[ 2] =   5 fr, release after 3
        .byte $27,$12                       ; D#3  ins  1  len[ 2] =   5 fr, release after 3
        .byte $28,$14                       ; E-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $23,$17                       ; B-2  ins  1  len[ 7] =  30 fr, release after 20
        .byte $2D,$17                       ; A-3  ins  1  len[ 7] =  30 fr, release after 20
        .byte $2D,$14                       ; A-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2C,$18                       ; G#3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $33,$17                       ; D#4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $33,$12                       ; D#4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $33,$12                       ; D#4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$17                       ; B-3  ins  1  len[ 7] =  30 fr, release after 20
        .byte $39,$17                       ; A-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$18                       ; G#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $34,$17                       ; E-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $34,$12                       ; E-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $34,$12                       ; E-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $35,$14                       ; F-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $30,$17                       ; C-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3A,$17                       ; A#4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3A,$14                       ; A#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3A,$18                       ; A#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $35,$17                       ; F-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $35,$12                       ; F-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $35,$12                       ; F-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $31,$17                       ; C#4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3B,$17                       ; B-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$18                       ; B-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $36,$17                       ; F#4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $36,$14                       ; F#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $37,$14                       ; G-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $32,$17                       ; D-4  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3C,$17                       ; C-5  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3D,$17                       ; C#5  ins  1  len[ 7] =  30 fr, release after 20
        .byte $3D,$14                       ; C#5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$18                       ; B-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $3E,$18                       ; D-5  ins  1  len[ 8] =  40 fr, release after 26
        .byte $39,$18                       ; A-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $38,$18                       ; G#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $3C,$16                       ; C-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$09                  ; rest  len[ 9] =  60 fr
        .byte CMD_RETURN

G_Pattern13:
        .byte CMD_REST,$0A                  ; rest  len[10] =  80 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3E,$14                       ; D-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $40,$14                       ; E-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$16                       ; C-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $3E,$16                       ; D-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $41,$16                       ; F-5  ins  1  len[ 6] =  20 fr, release after 13
        .byte $40,$14                       ; E-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3E,$12                       ; D-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$12                       ; A-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$12                       ; A-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $38,$12                       ; G#4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $35,$14                       ; F-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $32,$14                       ; D-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3E,$12                       ; D-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$12                       ; A-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $38,$12                       ; G#4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$18                       ; A-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3C,$12                       ; C-5  ins  1  len[ 2] =   5 fr, release after 3
        .byte $3B,$12                       ; B-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $39,$12                       ; A-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $37,$12                       ; G-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $35,$12                       ; F-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $37,$18                       ; G-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $39,$18                       ; A-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3C,$14                       ; C-5  ins  1  len[ 4] =  10 fr, release after 6
        .byte $3B,$14                       ; B-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $38,$14                       ; G#4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $39,$14                       ; A-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $30,$14                       ; C-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $34,$14                       ; E-4  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern16:
        .byte $26,$16                       ; D-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $31,$16                       ; C#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2D,$14                       ; A-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2B,$14                       ; G-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2F,$14                       ; B-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $28,$14                       ; E-3  ins  1  len[ 4] =  10 fr, release after 6
        .byte $2D,$16                       ; A-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $31,$16                       ; C#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2F,$16                       ; B-3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $33,$16                       ; D#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2C,$16                       ; G#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $32,$16                       ; D-4  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2E,$16                       ; A#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $2E,$16                       ; A#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $22,$18                       ; A#2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2B,$18                       ; G-3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2C,$18                       ; G#3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $22,$18                       ; A#2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $23,$18                       ; B-2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $37,$18                       ; G-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $38,$18                       ; G#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2E,$18                       ; A#3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $23,$18                       ; B-2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2C,$18                       ; G#3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2D,$18                       ; A-3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $23,$18                       ; B-2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $23,$18                       ; B-2  ins  1  len[ 8] =  40 fr, release after 26
        .byte $38,$18                       ; G#4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $39,$18                       ; A-4  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2F,$18                       ; B-3  ins  1  len[ 8] =  40 fr, release after 26
        .byte $2C,$16                       ; G#3  ins  1  len[ 6] =  20 fr, release after 13
        .byte $38,$16                       ; G#4  ins  1  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $35,$12                       ; F-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $34,$12                       ; E-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $32,$12                       ; D-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $30,$12                       ; C-4  ins  1  len[ 2] =   5 fr, release after 3
        .byte $2F,$12                       ; B-3  ins  1  len[ 2] =   5 fr, release after 3
        .byte CMD_RETURN

G_Pattern02:
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern05:
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$06                  ; rest  len[ 6] =  20 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $1C,$25                       ; E-2  ins  2  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $1C,$25                       ; E-2  ins  2  len[ 5] =  15 fr, release after 10
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$20                       ; E-2  ins  2  len[ 0] =   2 fr, release after 1
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte CMD_REST,$00                  ; rest  len[ 0] =   2 fr
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$20                       ; E-2  ins  2  len[ 0] =   2 fr, release after 1
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_REST,$04                  ; rest  len[ 4] =  10 fr
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$0A                       ; D#2  ins  0  len[10] =  80 fr, release after 60
        .byte $1C,$0A                       ; E-2  ins  0  len[10] =  80 fr, release after 60
        .byte CMD_RETURN

G_Pattern08:
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $15,$24                       ; A-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte CMD_RETURN

G_Pattern11:
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $12,$24                       ; F#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $16,$24                       ; A#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $11,$24                       ; F-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $18,$24                       ; C-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $22,$24                       ; A#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $23,$24                       ; B-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $23,$24                       ; B-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $23,$24                       ; B-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $23,$24                       ; B-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$26                       ; F#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1E,$26                       ; F#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1D,$26                       ; F-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1D,$26                       ; F-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1B,$26                       ; D#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1B,$26                       ; D#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1D,$24                       ; F-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1E,$24                       ; F#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $21,$24                       ; A-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1F,$24                       ; G-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $20,$24                       ; G#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern14:
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1A,$26                       ; D-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1A,$26                       ; D-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_RETURN

G_Pattern17:
        .byte $13,$26                       ; G-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $14,$26                       ; G#1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $16,$26                       ; A#1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $19,$24                       ; C#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $17,$24                       ; B-1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $14,$24                       ; G#1  ins  2  len[ 4] =  10 fr, release after 6
        .byte $15,$26                       ; A-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $16,$26                       ; A#1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $17,$26                       ; B-1  ins  2  len[ 6] =  20 fr, release after 13
        .byte $18,$26                       ; C-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $19,$26                       ; C#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1A,$26                       ; D-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1B,$26                       ; D#2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1B,$24                       ; D#2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$24                       ; E-2  ins  2  len[ 4] =  10 fr, release after 6
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte $1C,$26                       ; E-2  ins  2  len[ 6] =  20 fr, release after 13
        .byte CMD_REST,$05                  ; rest  len[ 5] =  15 fr
        .byte $1D,$22                       ; F-2  ins  2  len[ 2] =   5 fr, release after 3
        .byte $1C,$22                       ; E-2  ins  2  len[ 2] =   5 fr, release after 3
        .byte $1A,$22                       ; D-2  ins  2  len[ 2] =   5 fr, release after 3
        .byte $18,$22                       ; C-2  ins  2  len[ 2] =   5 fr, release after 3
        .byte $17,$22                       ; B-1  ins  2  len[ 2] =   5 fr, release after 3
        .byte CMD_RETURN

; PATTERNS (CMD_CALL numbers).
G_PatLo:
        .lobytes G_Pattern00, G_Pattern01, G_Pattern02, G_Pattern03, G_Pattern04, G_Pattern05, G_Pattern06, G_Pattern07
        .lobytes G_Pattern08, G_Pattern09, G_Pattern10, G_Pattern11, G_Pattern12, G_Pattern13, G_Pattern14, G_Pattern15
        .lobytes G_Pattern16, G_Pattern17

G_PatHi:
        .hibytes G_Pattern00, G_Pattern01, G_Pattern02, G_Pattern03, G_Pattern04, G_Pattern05, G_Pattern06, G_Pattern07
        .hibytes G_Pattern08, G_Pattern09, G_Pattern10, G_Pattern11, G_Pattern12, G_Pattern13, G_Pattern14, G_Pattern15
        .hibytes G_Pattern16, G_Pattern17
