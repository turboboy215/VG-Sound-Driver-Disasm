;==============================================================================
;  Mark Cooksey C64 sound driver -- BOMB JACK (1986 Elite)
;  Early driver: one copy of the player code per voice, SID shadow registers,
;  duration + note byte pairs. Not the format of the NES driver.
;
;  Source: Bomb_Jack.sid (PSID v2, load $73A0-$96FA, 6 songs).
;  Reassembles byte-identically to the .sid file:
;            ca65 bomb_jack_sound.s
;            ld65 -C bomb_jack_sound.cfg -o out.sid bomb_jack_sound.o
;
;  MEMORY
;    $73A0-$7447  variables (inside the image)
;    $7448-$7E32  player
;    $8000-$8171  SID ripper wrapper (not the game's)
;    $8400-$96FA  six song modules: init routine, 3 order lists, patterns
;
;  TIMING
;    Play runs the effects and the SID writes on every call, and reads the
;    patterns every mSpeed calls (one "tick"). The rip calls Play twice per
;    50 Hz frame.
;
;  ORDER LISTS: .word pattern pointers; a high byte of 0 restarts the list.
;
;  PATTERNS (read once per tick per voice)
;    $00            end of pattern: next order list entry
;    $01-$C7 nn     note: length in ticks, then the note byte
;                     nn bits 0-3 = semitone (1 = C ... 12 = B), 0 = rest
;                     nn bits 4-6 = octave. A rest turns the gate off; a note
;                     turns it off and on again (retrigger) when the voice's
;                     mOutputOn bit is set.
;    $C8-$F5        commands (see the C_ equates). Voice 1 knows all of them;
;                   voices 2 and 3 only C9-CB, D0, D1, D4, D5, D8 (+ D2, D6 on
;                   voice 2). Other bytes are skipped as 1-byte commands.
;      C8 v    SID_MODE_VOL        CC/CE  voice 1 track on/off
;      C9 w    waveform (ctrl)     CD/CF  voice 1 SID output on/off
;      CA ad   attack/decay        D0/D4  octave trill on/off
;      CB sr   sustain/release     D1/D5  pulse sweep on/off
;      D8 l h  pulse width         D2/D6  slide on/off
;      D9 s    speed (calls/tick)  D3/D7  slide after delay on / delay off
;      DA a b  pulse sweep range
;    $F6 cnt        noise drum for cnt-1 ticks (the voice's pattern waits)
;    $F7-$FA cnt    empty drums (would stop the voice for good; unused)
;
;  TUNING: FreqTable holds the NTSC note values from the C64 Programmer's
;  Reference Guide. On a PAL machine every note is about 65 cents (2/3 of a
;  semitone) flat. Paperboy, from the same year, already uses PAL values.
;
;  Bytes the driver never reads are kept (so the file reassembles) and are
;  marked "not referenced".
;==============================================================================

; ---------------------------------------------------------------- zero page
zPat1                = $4B          ; voice 1 pattern pointer
zPat2                = $4D          ; voice 2 pattern pointer
zPat3                = $4F          ; voice 3 pattern pointer (kept only here)
zOrder               = $51          ; order list pointer (temporary)

; ---------------------------------------------------------------- pattern commands
C_VOLUME             = $C8
C_WAVE               = $C9
C_AD                 = $CA
C_SR                 = $CB
C_TRACK_ON           = $CC
C_OUTPUT_ON          = $CD
C_TRACK_OFF          = $CE
C_OUTPUT_OFF         = $CF
C_TRILL              = $D0
C_PWSWEEP            = $D1
C_SLIDE              = $D2
C_SLIDE_DELAY        = $D3
C_TRILL_OFF          = $D4
C_PWSWEEP_OFF        = $D5
C_SLIDE_OFF          = $D6
C_DELAY_OFF          = $D7
C_PULSE              = $D8
C_SPEED              = $D9
C_PWRANGE            = $DA
C_DRUM               = $F6
C_DRUM_F7            = $F7
C_DRUM_F8            = $F8
C_DRUM_F9            = $F9
C_DRUM_FA            = $FA

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
        .dbyt $0006                         ; number of songs
        .dbyt $0006                         ; default song
        .dbyt $0000, $0000                  ; speed bits per song: 1 = CIA timer, 0 = VBI
        .byte "Bomb Jack"
        .res 23, $00                       ; name (32 bytes)
        .byte "Mark Cooksey"
        .res 20, $00                       ; author (32 bytes)
        .byte "1986 Elite"
        .res 22, $00                       ; released (32 bytes)
        .dbyt $0000                         ; flags: clock unknown, SID unknown
        .byte $00, $00                      ; start page, page length
        .dbyt $0000                         ; second/third SID
        .word LoadAddress                   ; load address (little-endian)

.segment "PLAYER"

; VARIABLES (the values are the ripper's snapshot).
; Shadow SID registers, written every call by Output.
mModeVol:
LoadAddress:
        .byte $0F                           ; shadow SID_MODE_VOL

mResFilt:
        .byte $00                           ; shadow SID_RES_FILT (never changed by the driver)

mCutoffHi:
        .byte $00                           ; shadow SID_FC_HI (never changed by the driver)

mCutoffLo:
        .byte $00                           ; shadow SID_FC_LO (never changed by the driver)

; Shadow voice registers, 7 bytes per voice in SID order:
; freq lo/hi, pulse lo/hi, control, AD, SR.
mV1FreqLo:
        .byte $44                           ; voice 1: frequency

mV1FreqHi:
        .byte $4B

mV1PwLo:
        .byte $0A                           ; voice 1: pulse width

mV1PwHi:
        .byte $0E

mV1Ctrl:
        .byte $41                           ; voice 1: control (waveform, gate on)

mV1AD:
        .byte $09

mV1SR:
        .byte $20

mV2FreqLo:
        .byte $BE                           ; voice 2

mV2FreqHi:
        .byte $3B

mV2PwLo:
        .byte $06

mV2PwHi:
        .byte $06

mV2Ctrl:
        .byte $41

mV2AD:
        .byte $07

mV2SR:
        .byte $20

mV3FreqLo:
        .byte $30                           ; voice 3

mV3FreqHi:
        .byte $04

mV3PwLo:
        .byte $0A

mV3PwHi:
        .byte $0A

mV3Ctrl:
        .byte $41

mV3AD:
        .byte $09

mV3SR:
        .byte $40
; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00,$00

; Pulse-width sweep (all voices share speed and range).
mPwSweepOn:
        .byte $01                           ; pulse sweep: bit n = voice n+1

mPwSweepSpeed:
        .byte $02                           ; calls per step

mPwSweepTimer:
        .byte $02

mPwSweepMin:
        .byte $01                           ; pulse high byte restarts here...

mPwSweepMax:
        .byte $0F                           ; ...when it reaches this
; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00,$00

; Octave trill: the frequency is doubled and halved in turn.
mTrillOn:
        .byte $01                           ; octave trill: bit n = voice n+1

mTrillSpeed:
        .byte $02                           ; calls per flip (never set by songs)

mTrillTimer:
        .byte $02
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

mTrillUp:
        .byte $00,$01,$00                   ; per voice: 1 = currently an octave up
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Pitch slide.
mSlideOn:
        .byte $00                           ; slide: bits 0-2 = on per voice, bits 3-5 = wait for the delay

mSlideTimer:
        .byte $01,$01,$00                   ; per voice

mSlideSpeed:
        .byte $01,$01                       ; voices 1, 2 (set by the song init)

mSlideSpeed3:
        .byte $00                           ; voice 3

mSlideDelay3:
        .byte $00                           ; voice 3: delay counter

mSlideDelay3Set:
        .byte $00                           ; voice 3: delay at each note

mSlideStepHi:
        .byte $00                           ; step added to / taken from the frequency (all voices)

mSlideStepLo:
        .byte $3C

mSlideFloor:
        .byte $01,$00,$00                   ; per voice: slide down stops at this freq high byte

mSlideCeil:
        .byte $C8,$00                       ; voices 1, 2: slide up stops at this freq high byte
; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00

mSlideCeil3:
        .byte $00                           ; voice 3 (not next to the others)

mSlideUp:
        .byte $00                           ; bit n = 1: voice n+1 slides up (0 = down)

mSlideDelay1:
        .byte $0A                           ; voice 1: delay counter

mSlideDelay1Set:
        .byte $0A                           ; voice 1: delay at each note

mSlideDelay2:
        .byte $00                           ; voice 2: delay counter

mSlideDelay2Set:
        .byte $00                           ; voice 2: delay at each note
; ---- 24 byte(s) not referenced by the sound engine ----
        .res 24, $00

; Player state.
mTrackOn:
        .byte $07                           ; bit n = voice n+1 reads its track

mOutputOn:
        .byte $07                           ; bit n = voice n+1 writes the SID (0 = no SID writes at all)

mSpeed:
        .byte $06                           ; calls per tick

mSpeedCount:
        .byte $02
; ---- 6 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00,$00,$00

mDrum:
        .byte $00,$00,$00                   ; per voice: drum command ($F6-$FA) playing, 0 = none

mFreqHi:
        .byte $3B                           ; NoteToFreq result

mFreqLo:
        .byte $BE
; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00,$00

mDuration:
        .byte $01,$01,$03                   ; per voice: ticks left of the note

mDrumCount:
        .byte $00,$00,$00                   ; per voice: ticks left of the drum
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

mNoteTemp:
        .byte $5B

mOrderIdx:
        .byte $08,$08,$08                   ; per voice: offset in the order list

mOrder1:
        .byte $6E,$91                       ; order list pointers

mOrder2:
        .byte $8A,$91

mOrder3:
        .byte $A6,$91
; ---- 30 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$4C
        .res 19, $00
        .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; PLAY: called twice per frame by the rip (see Rip_Play).
; Copies the saved pattern pointers of voices 1 and 2 into zero page
; (voice 3 keeps its pointer in $4F/$50 only). Patterns are read every
; mSpeed calls; the effects and the SID writes run on every call.
Play:
        lda SavedPtrs
        sta zPat1
        lda SavedPtrs+1
        sta zPat1+1
        lda SavedPtrs+2
        sta zPat2
        lda SavedPtrs+3
        sta zPat2+1
        ldy #$00
        dec mSpeedCount
        beq Tick
        jmp Output

Tick:
        lda mSpeed
        sta mSpeedCount

; VOICE 1 (pattern pointer $4B/$4C, SID registers +$00).
V1_Start:
        lda mTrackOn
        and #$01
        bne V1_Tick
        jmp V2_Start

; A drum playing on this voice replaces the pattern.
V1_Tick:
        ldx #$00
        lda mDrum
        beq V1_Count
        cmp #$F6
        bne V1_Busy_F7
        jsr Drum_Count
        jmp V2_Start

V1_Busy_F7:
        cmp #$F7
        bne V1_Busy_F8
        jsr Drum_F7
        jmp V2_Start

V1_Busy_F8:
        cmp #$F8
        bne V1_Busy_F9
        jsr Drum_F8
        jmp V2_Start

V1_Busy_F9:
        cmp #$F9
        bne V1_Busy_FA
        jsr Drum_F9
        jmp V2_Start

V1_Busy_FA:
        cmp #$FA
        bne V1_BusyDone
        jsr Drum_FA

V1_BusyDone:
        jmp V2_Start

; Count the note down; read the pattern when it reaches 0.
V1_Count:
        dec mDuration
        beq V1_Read
        jmp V2_Start

; $00 = end of pattern, $01-$C7 = length + note, $C8-$F5 = command,
; $F6-$FF = drum + count.
V1_Read:
        lda (zPat1),y
        bne V1_NotEnd
        jmp V1_NextPattern

V1_NotEnd:
        cmp #$F6
        bcc V1_Note

; Drum: count byte, then start the drum.
V1_DrumCmd:
        iny
        lda (zPat1),y
        sta mDrumCount
        dec mDrumCount
        dey
        lda (zPat1),y
        cmp #$F6
        bne V1_Drum_F7
        sta mDrum
        jsr Drum_Noise
        iny
        jmp V1_Advance

V1_Drum_F7:
        cmp #$F7
        bne V1_Drum_F8
        sta mDrum
        jsr Drum_F7
        iny
        jmp V1_Advance

V1_Drum_F8:
        cmp #$F8
        bne V1_Drum_F9
        sta mDrum
        jsr Drum_F8
        iny
        jmp V1_Advance

V1_Drum_F9:
        cmp #$F9
        bne V1_Drum_FA
        sta mDrum
        jsr Drum_F9
        iny
        jmp V1_Advance

V1_Drum_FA:
        cmp #$FA
        beq V1_DrumIsFA
        jmp V1_Advance

V1_DrumIsFA:
        sta mDrum
        jsr Drum_FA
        iny
        jmp V1_Advance

; Length byte, then the note byte (0 = rest).
V1_Note:
        cmp #$C8
        bcc V1_NoteLen
        jmp V1_Command

V1_NoteLen:
        sta mDuration
        lda mSlideDelay1Set
        sta mSlideDelay1
        iny
        lda (zPat1),y
        beq V1_Gate
        jsr NoteToFreq
        lda mFreqHi
        sta mV1FreqHi
        lda mFreqLo
        sta mV1FreqLo
        lda mOutputOn
        and #$01
        bne V1_Gate
        jmp V1_Advance

; Gate off; on again unless the note is a rest.
V1_Gate:
        ldx mV1Ctrl
        dex
        stx SID_V1_CTRL
        lda (zPat1),y
        beq V1_Advance
        inx
        stx SID_V1_CTRL
        lda #$00
        sta mTrillUp                        ; only voice 1 resets its trill state on a new note

; Pattern pointer += Y + 1.
V1_Advance:
        iny
        clc
        tya
        adc zPat1
        sta zPat1
        lda zPat1+1
        adc #$00
        sta zPat1+1

; VOICE 2 (pattern pointer $4D/$4E, SID registers +$07).
V2_Start:
        ldy #$00
        lda mTrackOn
        and #$02
        bne V2_Tick
        jmp V3_Start

; A drum playing on this voice replaces the pattern.
V2_Tick:
        ldx #$07
        lda mDrum+1
        beq V2_Count
        cmp #$F6
        bne V2_Busy_F7
        jsr Drum_Count
        jmp V3_Start

V2_Busy_F7:
        cmp #$F7
        bne V2_Busy_F8
        jsr Drum_F7
        jmp V3_Start

V2_Busy_F8:
        cmp #$F8
        bne V2_Busy_F9
        jsr Drum_F8
        jmp V3_Start

V2_Busy_F9:
        cmp #$F9
        bne V2_Busy_FA
        jsr Drum_F9
        jmp V3_Start

V2_Busy_FA:
        cmp #$FA
        bne V2_BusyDone
        jsr Drum_FA

V2_BusyDone:
        jmp V3_Start

; Count the note down; read the pattern when it reaches 0.
V2_Count:
        dec mDuration+1
        beq V2_Read
        jmp V3_Start

; $00 = end of pattern, $01-$C7 = length + note, $C8-$F5 = command,
; $F6-$FF = drum + count.
V2_Read:
        lda (zPat2),y
        bne V2_NotEnd
        jmp V2_NextPattern

V2_NotEnd:
        cmp #$F6
        bcc V2_Note

; Drum: count byte, then start the drum.
V2_DrumCmd:
        iny
        lda (zPat2),y
        sta mDrumCount+1
        dec mDrumCount+1
        dey
        lda (zPat2),y
        cmp #$F6
        bne V2_Drum_F7
        sta mDrum+1
        jsr Drum_Noise
        iny
        jmp V2_Advance

V2_Drum_F7:
        cmp #$F7
        bne V2_Drum_F8
        sta mDrum+1
        jsr Drum_F7
        iny
        jmp V2_Advance

V2_Drum_F8:
        cmp #$F8
        bne V2_Drum_F9
        sta mDrum+1
        jsr Drum_F8
        iny
        jmp V2_Advance

V2_Drum_F9:
        cmp #$F9
        bne V2_Drum_FA
        sta mDrum+1
        jsr Drum_F9
        iny
        jmp V2_Advance

V2_Drum_FA:
        cmp #$FA
        beq V2_DrumIsFA
        jmp V3_Start

V2_DrumIsFA:
        sta mDrum+1
        jsr Drum_FA
        iny
        jmp V2_Advance

; Length byte, then the note byte (0 = rest).
V2_Note:
        cmp #$C8
        bcc V2_NoteLen
        jmp V2_Command

V2_NoteLen:
        sta mDuration+1
        lda mSlideDelay2Set
        sta mSlideDelay2
        iny
        lda (zPat2),y
        beq V2_Gate
        jsr NoteToFreq
        lda mFreqHi
        sta mV2FreqHi
        lda mFreqLo
        sta mV2FreqLo
        lda mOutputOn
        and #$02
        bne V2_Gate
        jmp V2_Advance

; Gate off; on again unless the note is a rest.
V2_Gate:
        ldx mV2Ctrl
        dex
        stx SID_V2_CTRL
        lda (zPat2),y
        beq V2_Advance
        inx
        stx SID_V2_CTRL

; Pattern pointer += Y + 1.
V2_Advance:
        iny
        clc
        tya
        adc zPat2
        sta zPat2
        lda zPat2+1
        adc #$00
        sta zPat2+1

; VOICE 3 (pattern pointer $4F/$50, SID registers +$0E).
V3_Start:
        ldy #$00
        lda mTrackOn
        and #$04
        bne V3_Tick
        jmp Output

; A drum playing on this voice replaces the pattern.
V3_Tick:
        ldx #$0E
        lda mDrum+2
        beq V3_Count
        cmp #$F6
        bne V3_Busy_F7
        jsr Drum_Count
        jmp Output

V3_Busy_F7:
        cmp #$F7
        bne V3_Busy_F8
        jsr Drum_F7
        jmp Output

V3_Busy_F8:
        cmp #$F8
        bne V3_Busy_F9
        jsr Drum_F8
        jmp Output

V3_Busy_F9:
        cmp #$F9
        bne V3_Busy_FA
        jsr Drum_F9
        jmp Output

V3_Busy_FA:
        cmp #$FA
        bne V3_BusyDone
        jsr Drum_FA

V3_BusyDone:
        jmp Output

; Count the note down; read the pattern when it reaches 0.
V3_Count:
        dec mDuration+2
        beq V3_Read
        jmp Output

; $00 = end of pattern, $01-$C7 = length + note, $C8-$F5 = command,
; $F6-$FF = drum + count.
V3_Read:
        lda (zPat3),y
        bne V3_NotEnd
        jmp V3_NextPattern

V3_NotEnd:
        cmp #$F6
        bcc V3_Note

; Drum: count byte, then start the drum.
V3_DrumCmd:
        iny
        lda (zPat3),y
        sta mDrumCount+2
        dec mDrumCount+2
        dey
        lda (zPat3),y
        cmp #$F6
        bne V3_Drum_F7
        sta mDrum+2
        jsr Drum_Noise
        iny
        jmp V3_Advance

V3_Drum_F7:
        cmp #$F7
        bne V3_Drum_F8
        sta mDrum+2
        jsr Drum_F7
        iny
        jmp V3_Advance

V3_Drum_F8:
        cmp #$F8
        bne V3_Drum_F9
        sta mDrum+2
        jsr Drum_F8
        iny
        jmp V3_Advance

V3_Drum_F9:
        cmp #$F9
        bne V3_Drum_FA
        sta mDrum+2
        jsr Drum_F9
        iny
        jmp V3_Advance

V3_Drum_FA:
        cmp #$FA
        beq V3_DrumIsFA
        jmp Output

V3_DrumIsFA:
        sta mDrum+2
        jsr Drum_FA
        iny
        jmp V3_Advance

; Length byte, then the note byte (0 = rest).
V3_Note:
        cmp #$C8
        bcc V3_NoteLen
        jmp V3_Command

V3_NoteLen:
        sta mDuration+2
        lda mSlideDelay3Set
        sta mSlideDelay3
        iny
        lda (zPat3),y
        beq V3_Gate
        jsr NoteToFreq
        lda mFreqHi
        sta mV3FreqHi
        lda mFreqLo
        sta mV3FreqLo
        lda mOutputOn
        and #$04
        bne V3_Gate
        jmp V3_Advance

; Gate off; on again unless the note is a rest.
V3_Gate:
        ldx mV3Ctrl
        dex
        stx SID_V3_CTRL
        lda (zPat3),y
        beq V3_Advance
        inx
        stx SID_V3_CTRL

; Pattern pointer += Y + 1.
V3_Advance:
        iny
        clc
        tya
        adc zPat3
        sta zPat3
        lda zPat3+1
        adc #$00
        sta zPat3+1

; Write the shadow registers to the SID (if mOutputOn is not 0):
; filter/volume always, each voice unless its output bit is off or a
; drum owns it. The control register is only written at note starts.
Output:
        lda mOutputOn
        bne Output_Write
        jmp PwSweep

Output_Write:
        lda mModeVol
        sta SID_MODE_VOL
        lda mResFilt
        sta SID_RES_FILT
        lda mCutoffHi
        sta SID_FC_HI
        lda mCutoffLo
        sta SID_FC_LO
        lda mOutputOn
        and #$01
        beq Output_V2
        lda mDrum
        bne Output_V2
        lda mV1AD
        sta SID_V1_AD
        lda mV1SR
        sta SID_V1_SR
        lda mV1PwHi
        sta SID_V1_PW_HI
        lda mV1PwLo
        sta SID_V1_PW_LO
        lda mV1FreqHi
        sta SID_V1_FREQ_HI
        lda mV1FreqLo
        sta SID_V1_FREQ_LO

Output_V2:
        lda mOutputOn
        and #$02
        beq Output_V3
        lda mDrum+1
        bne Output_V3
        lda mV2AD
        sta SID_V2_AD
        lda mV2SR
        sta SID_V2_SR
        lda mV2PwHi
        sta SID_V2_PW_HI
        lda mV2PwLo
        sta SID_V2_PW_LO
        lda mV2FreqHi
        sta SID_V2_FREQ_HI
        lda mV2FreqLo
        sta SID_V2_FREQ_LO

Output_V3:
        lda mOutputOn
        and #$04
        beq PwSweep
        lda mDrum+2
        bne PwSweep
        lda mV3AD
        sta SID_V3_AD
        lda mV3SR
        sta SID_V3_SR
        lda mV3PwHi
        sta SID_V3_PW_HI
        lda mV3PwLo
        sta SID_V3_PW_LO
        lda mV3FreqHi
        sta SID_V3_FREQ_HI
        lda mV3FreqLo
        sta SID_V3_FREQ_LO

; Pulse sweep: every mPwSweepSpeed calls, raise the pulse high byte;
; past mPwSweepMax it restarts at mPwSweepMin.
PwSweep:
        dec mPwSweepTimer
        bne Trill
        lda mPwSweepSpeed
        sta mPwSweepTimer
        lda mPwSweepOn
        and #$01
        beq PwSweep_V2
        inc mV1PwHi
        lda mV1PwHi
        cmp mPwSweepMax
        bcc PwSweep_V2
        lda mPwSweepMin
        sta mV1PwHi

PwSweep_V2:
        lda mPwSweepOn
        and #$02
        beq PwSweep_V3
        inc mV2PwHi
        lda mV2PwHi
        cmp mPwSweepMax
        bcc PwSweep_V3
        lda mPwSweepMin
        sta mV2PwHi

PwSweep_V3:
        lda mPwSweepOn
        and #$04
        beq Trill
        inc mV3PwHi
        lda mV3PwHi
        cmp mPwSweepMax
        bcc Trill
        lda mPwSweepMin
        sta mV3PwHi

; Octave trill: every mTrillSpeed calls, shift the frequency one octave
; up or back down.
Trill:
        dec mTrillTimer
        beq Trill_Go
        jmp Slide1

Trill_Go:
        lda mTrillSpeed
        sta mTrillTimer
        lda mTrillOn
        and #$01
        beq Trill_V2
        lda mDrum
        bne Trill_V2
        lda mTrillUp
        bne Trill_V1Down
        clc
        asl mV1FreqLo
        rol mV1FreqHi
        lda #$01
        sta mTrillUp
        jmp Trill_V2

Trill_V1Down:
        lsr mV1FreqHi
        ror mV1FreqLo
        lda #$00
        sta mTrillUp

Trill_V2:
        lda mTrillOn
        and #$02
        beq Trill_V3
        lda mDrum+1
        bne Trill_V3
        lda mTrillUp+1
        bne Trill_V2Down
        clc
        asl mV2FreqLo
        rol mV2FreqHi
        lda #$01
        sta mTrillUp+1
        jmp Trill_V3

Trill_V2Down:
        lsr mV2FreqHi
        ror mV2FreqLo
        lda #$00
        sta mTrillUp+1

Trill_V3:
        lda mTrillOn
        and #$04
        beq Slide1
        lda mDrum+2
        bne Slide1
        lda mTrillUp+2
        bne Trill_V3Down
        clc
        asl mV3FreqLo
        rol mV3FreqHi
        lda #$01
        sta mTrillUp+2
        jmp Slide1

Trill_V3Down:
        lsr mV3FreqHi
        ror mV3FreqLo
        lda #$00
        sta mTrillUp+2

; Slide, voice 1: wait for the delay (if bit 3), then every
; mSlideSpeed calls move the frequency by mSlideStep towards
; mSlideFloor / mSlideCeil.
Slide1:
        lda mSlideOn
        and #$01
        bne Slide1_On
        jmp Slide2

Slide1_On:
        lda mSlideOn
        and #$08
        beq Slide1_Tick
        lda mSlideDelay1
        beq Slide1_Tick
        dec mSlideDelay1
        beq Slide1_Tick
        jmp Slide2

Slide1_Tick:
        dec mSlideTimer
        beq Slide1_Step
        jmp Slide2

Slide1_Step:
        lda mSlideSpeed
        sta mSlideTimer
        lda mDrum
        bne Slide2
        lda mSlideUp
        and #$01
        bne Slide1_Up
        lda mV1FreqHi
        cmp mSlideFloor
        bcc Slide2
        beq Slide2
        lda mV1FreqLo
        sec
        sbc mSlideStepLo
        sta mV1FreqLo
        lda mV1FreqHi
        sbc mSlideStepHi
        sta mV1FreqHi
        jmp Slide2

Slide1_Up:
        lda mV1FreqHi
        cmp mSlideCeil
        bcs Slide2
        lda mV1FreqLo
        clc
        adc mSlideStepLo
        sta mV1FreqLo
        lda mV1FreqHi
        adc mSlideStepHi
        sta mV1FreqHi

; Slide, voice 2.
Slide2:
        lda mSlideOn
        and #$02
        bne Slide2_On
        jmp Slide3

Slide2_On:
        lda mSlideOn
        and #$10
        beq Slide2_Tick
        lda mSlideDelay2
        beq Slide2_Tick
        dec mSlideDelay2
        beq Slide2_Tick
        jmp Slide3

Slide2_Tick:
        dec mSlideTimer+1
        beq Slide2_Step
        jmp Slide3

Slide2_Step:
        lda mSlideSpeed+1
        sta mSlideTimer+1
        lda mDrum+1
        bne Slide3
        lda mSlideUp
        and #$02
        bne Slide2_Up
        lda mV2FreqHi
        cmp mSlideFloor+1
        bcc Slide3
        beq Slide3
        lda mV2FreqLo
        sec
        sbc mSlideStepLo
        sta mV2FreqLo
        lda mV2FreqHi
        sbc mSlideStepHi
        sta mV2FreqHi
        jmp Slide3

Slide2_Up:
        lda mV2FreqHi
        cmp mSlideCeil+1
        bcs Slide3
        lda mV2FreqLo
        clc
        adc mSlideStepLo
        sta mV2FreqLo
        lda mV2FreqHi
        adc mSlideStepHi
        sta mV2FreqHi

; Slide, voice 3 (no voice 3 command turns it on).
Slide3:
        lda mSlideOn
        and #$04
        bne Slide3_On
        jmp PlayDone

Slide3_On:
        lda mSlideOn
        and #$20
        beq Slide3_Tick
        lda mSlideDelay3
        beq Slide3_Tick
        dec mSlideDelay3
        beq Slide3_Tick
        jmp PlayDone

Slide3_Tick:
        dec mSlideTimer+2
        beq Slide3_Step
        jmp PlayDone

Slide3_Step:
        lda mSlideSpeed3
        sta mSlideTimer+2
        lda mDrum+2
        bne PlayDone
        lda mSlideUp
        and #$04
        bne Slide3_Up
        lda mV3FreqHi
        cmp mSlideFloor+2
        bcc PlayDone
        beq PlayDone
        lda mV3FreqLo
        sec
        sbc mSlideStepLo
        sta mV3FreqLo
        lda mV3FreqHi
        sbc mSlideStepHi
        sta mV3FreqHi
        jmp PlayDone

Slide3_Up:
        lda mV3FreqHi
        cmp mSlideCeil3
        bcs PlayDone
        lda mV3FreqLo
        clc
        adc mSlideStepLo
        sta mV3FreqLo
        lda mV3FreqHi
        adc mSlideStepHi
        sta mV3FreqHi

PlayDone:
        jmp SavePtrs                        ; JMP to the next instruction

; Save the voice 1 and 2 pattern pointers.
SavePtrs:
        lda zPat1
        sta SavedPtrs
        lda zPat1+1
        sta SavedPtrs+1
        lda zPat2
        sta SavedPtrs+2
        lda zPat2+1
        sta SavedPtrs+3
        rts

UnusedRts:
        rts

; End of pattern: next pointer from the order list; a high byte of
; 0 restarts the list.
V1_NextPattern:
        lda mOrder1
        sta zOrder
        lda mOrder1+1
        sta zOrder+1
        ldy mOrderIdx
        lda (zOrder),y
        sta zPat1
        iny
        lda (zOrder),y
        bne V1_SetPattern
        ldy #$00
        sty mOrderIdx
        jmp V1_NextPattern

V1_SetPattern:
        sta zPat1+1
        iny
        sty mOrderIdx
        lda #$01
        sta mDuration
        ldy #$00
        jmp V1_Tick

; End of pattern: next pointer from the order list; a high byte of
; 0 restarts the list.
V2_NextPattern:
        lda mOrder2
        sta zOrder
        lda mOrder2+1
        sta zOrder+1
        ldy mOrderIdx+1
        lda (zOrder),y
        sta zPat2
        iny
        lda (zOrder),y
        bne V2_SetPattern
        ldy #$00
        sty mOrderIdx+1
        jmp V2_NextPattern

V2_SetPattern:
        sta zPat2+1
        iny
        sty mOrderIdx+1
        lda #$01
        sta mDuration+1
        ldy #$00
        jmp V2_Start

; End of pattern: next pointer from the order list; a high byte of
; 0 restarts the list.
V3_NextPattern:
        lda mOrder3
        sta zOrder
        lda mOrder3+1
        sta zOrder+1
        ldy mOrderIdx+2
        lda (zOrder),y
        sta zPat3
        iny
        lda (zOrder),y
        bne V3_SetPattern
        ldy #$00
        sty mOrderIdx+2
        jmp V3_NextPattern

V3_SetPattern:
        sta zPat3+1
        iny
        sty mOrderIdx+2
        lda #$01
        sta mDuration+2
        ldy #$00
        jmp V3_Start

; Commands $C8-$F5. Unknown ones are skipped as 1 byte.
V1_Command:
        cmp #$C8
        bne V1_Cmd_C9
        iny
        lda (zPat1),y
        sta mModeVol
        jmp V1_CmdDone

V1_Cmd_C9:
        cmp #$C9
        bne V1_Cmd_CA
        iny
        lda (zPat1),y
        sta mV1Ctrl
        jmp V1_CmdDone

V1_Cmd_CA:
        cmp #$CA
        bne V1_Cmd_CB
        iny
        lda (zPat1),y
        sta mV1AD
        jmp V1_CmdDone

V1_Cmd_CB:
        cmp #$CB
        bne V1_Cmd_CC
        iny
        lda (zPat1),y
        sta mV1SR
        jmp V1_CmdDone

V1_Cmd_CC:
        cmp #$CC
        bne V1_Cmd_CD
        lda mTrackOn
        ora #$01
        sta mTrackOn
        jmp V1_CmdDone

V1_Cmd_CD:
        cmp #$CD
        bne V1_Cmd_CE
        lda mOutputOn
        ora #$01
        sta mOutputOn
        jmp V1_CmdDone

V1_Cmd_CE:
        cmp #$CE
        bne V1_Cmd_CF
        lda mTrackOn
        and #$FE
        sta mTrackOn
        jmp V1_CmdDone

V1_Cmd_CF:
        cmp #$CF
        bne V1_Cmd_D0
        lda mOutputOn
        and #$FE
        sta mOutputOn
        jmp V1_CmdDone

V1_Cmd_D0:
        cmp #$D0
        bne V1_Cmd_D1
        lda #$01
        ora mTrillOn
        sta mTrillOn
        lda #$01
        sta mTrillTimer
        jmp V1_CmdDone

V1_Cmd_D1:
        cmp #$D1
        bne V1_Cmd_D2
        lda #$01
        ora mPwSweepOn
        sta mPwSweepOn
        lda #$01
        sta mPwSweepTimer
        jmp V1_CmdDone

V1_Cmd_D2:
        cmp #$D2
        bne V1_Cmd_D3
        lda #$01
        ora mSlideOn
        and #$F7
        sta mSlideOn
        lda #$01
        sta mSlideTimer
        jmp V1_CmdDone

V1_Cmd_D3:
        cmp #$D3
        bne V1_Cmd_D4
        lda #$09
        ora mSlideOn
        sta mSlideOn
        lda #$01
        sta mSlideTimer
        jmp V1_CmdDone

V1_Cmd_D4:
        cmp #$D4
        bne V1_Cmd_D5
        lda mTrillOn
        and #$FE
        sta mTrillOn
        jmp V1_CmdDone

V1_Cmd_D5:
        cmp #$D5
        bne V1_Cmd_D6
        lda mPwSweepOn
        and #$FE
        sta mPwSweepOn
        jmp V1_CmdDone

V1_Cmd_D6:
        cmp #$D6
        bne V1_Cmd_D7
        lda mSlideOn
        and #$FE
        sta mSlideOn
        jmp V1_CmdDone

V1_Cmd_D7:
        cmp #$D7
        bne V1_Cmd_D8
        lda mSlideOn
        and #$F7
        sta mSlideOn
        jmp V1_CmdDone

V1_Cmd_D8:
        cmp #$D8
        bne V1_Cmd_D9
        iny
        lda (zPat1),y
        sta mV1PwLo
        iny
        lda (zPat1),y
        sta mV1PwHi
        jmp V1_CmdDone

V1_Cmd_D9:
        cmp #$D9
        bne V1_Cmd_DA
        iny
        lda (zPat1),y
        sta mSpeed
        jmp V1_CmdDone

V1_Cmd_DA:
        cmp #$DA
        bne V1_CmdDone
        iny
        lda (zPat1),y
        sta mPwSweepMin
        iny
        lda (zPat1),y
        sta mPwSweepMax

; Pointer += Y + 1; read the next event in the same call.
V1_CmdDone:
        iny
        clc
        tya
        adc zPat1
        sta zPat1
        lda zPat1+1
        adc #$00
        sta zPat1+1
        ldy #$00
        lda #$01
        sta mDuration
        jmp V1_Tick

; Commands $C8-$F5. Unknown ones are skipped as 1 byte.
V2_Command:
        cmp #$C9
        bne V2_Cmd_CA
        iny
        lda (zPat2),y
        sta mV2Ctrl
        jmp V2_CmdDone

V2_Cmd_CA:
        cmp #$CA
        bne V2_Cmd_CB
        iny
        lda (zPat2),y
        sta mV2AD
        jmp V2_CmdDone

V2_Cmd_CB:
        cmp #$CB
        bne V2_Cmd_D0
        iny
        lda (zPat2),y
        sta mV2SR
        jmp V2_CmdDone

V2_Cmd_D0:
        cmp #$D0
        bne V2_Cmd_D1
        lda #$02
        ora mTrillOn
        sta mTrillOn
        lda #$01
        sta mTrillTimer
        jmp V2_CmdDone

V2_Cmd_D1:
        cmp #$D1
        bne V2_Cmd_D4
        lda #$02
        ora mPwSweepOn
        sta mPwSweepOn
        lda #$01                            ; BUG: the timer is never stored (no STA mPwSweepTimer)
        jmp V2_CmdDone

V2_Cmd_D4:
        cmp #$D4
        bne V2_Cmd_D5
        lda mTrillOn
        and #$FD
        sta mTrillOn
        jmp V2_CmdDone

V2_Cmd_D5:
        cmp #$D5
        bne V2_Cmd_D8
        lda mPwSweepOn
        and #$FD
        sta mPwSweepOn
        jmp V2_CmdDone

V2_Cmd_D8:
        cmp #$D8
        bne V2_Cmd_D2
        iny
        lda (zPat2),y
        sta mV2PwLo
        iny
        lda (zPat2),y
        sta mV2PwHi                         ; BUG: no JMP: falls into the $D2 test with A = pulse high (harmless)

V2_Cmd_D2:
        cmp #$D2
        bne V2_Cmd_D6
        lda #$02
        ora mSlideOn
        and #$EF
        sta mSlideOn
        lda #$01
        sta mSlideTimer+1
        jmp V2_CmdDone

V2_Cmd_D6:
        cmp #$D6
        bne V2_CmdDone
        lda mSlideOn
        and #$ED
        sta mSlideOn

; Pointer += Y + 1; read the next event in the same call.
V2_CmdDone:
        iny
        clc
        tya
        adc zPat2
        sta zPat2
        lda zPat2+1
        adc #$00
        sta zPat2+1
        ldy #$00
        lda #$01
        sta mDuration+1
        jmp V2_Start

; Commands $C8-$F5. Unknown ones are skipped as 1 byte.
V3_Command:
        cmp #$C9
        bne V3_Cmd_CA
        iny
        lda (zPat3),y
        sta mV3Ctrl
        jmp V3_CmdDone

V3_Cmd_CA:
        cmp #$CA
        bne V3_Cmd_CB
        iny
        lda (zPat3),y
        sta mV3AD
        jmp V3_CmdDone

V3_Cmd_CB:
        cmp #$CB
        bne V3_Cmd_D0
        iny
        lda (zPat3),y
        sta mV3SR
        jmp V3_CmdDone

V3_Cmd_D0:
        cmp #$D0
        bne V3_Cmd_D1
        lda #$04
        ora mTrillOn
        sta mTrillOn
        lda #$01
        sta mTrillTimer
        jmp V3_CmdDone

V3_Cmd_D1:
        cmp #$D1
        bne V3_Cmd_D4
        lda #$04
        ora mPwSweepOn
        sta mPwSweepOn
        lda #$01
        sta mPwSweepTimer
        jmp V3_CmdDone

V3_Cmd_D4:
        cmp #$D4
        bne V3_Cmd_D5
        lda mTrillOn
        and #$FB
        sta mTrillOn
        jmp V3_CmdDone

V3_Cmd_D5:
        cmp #$D5
        bne V3_Cmd_D8
        lda mPwSweepOn
        and #$FB
        sta mPwSweepOn
        jmp V3_CmdDone

V3_Cmd_D8:
        cmp #$D8
        bne V3_CmdDone
        iny
        lda (zPat3),y
        sta mV3PwLo
        iny
        lda (zPat3),y
        sta mV3PwHi

; Pointer += Y + 1; read the next event in the same call.
V3_CmdDone:
        iny
        clc
        tya
        adc zPat3
        sta zPat3
        lda zPat3+1
        adc #$00
        sta zPat3+1
        ldy #$00
        lda #$01
        sta mDuration+2
        jmp V3_Start

; A = note: bits 0-3 semitone (1 = C .. 12 = B, 0 = frequency 0),
; bits 4-6 octave. FreqTable holds octave 5; lower octaves are shifted
; right, 6 and 7 left. Result in mFreqHi/mFreqLo.
NoteToFreq:
        sta mNoteTemp
        and #$0F
        asl a
        tax
        lda FreqTable,x
        sta mFreqHi
        inx
        lda FreqTable,x
        sta mFreqLo
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
        asl mFreqLo
        rol mFreqHi
        cmp #$06
        beq NoteToFreq_Done
        clc
        asl mFreqLo
        rol mFreqHi
        jmp NoteToFreq_Done

NoteToFreq_Down:
        tax
        lda OctaveShift,x
        tax

NoteToFreq_Shift:
        clc
        clc                                 ; second CLC (redundant)
        lsr mFreqHi
        ror mFreqLo
        dex
        bpl NoteToFreq_Shift

NoteToFreq_Done:
        rts

; Octave 5 frequencies, big-endian (high byte first), index = semitone.
; These are the NTSC values of the C64 Programmer's Reference Guide
; table: C5 = $2187 = 523.2 Hz on NTSC, but 504.0 Hz on a PAL C64 (65 cents
; flat). See the tuning notes.
FreqTable:
        .dbyt $0000                         ; (0)  semitone 0: silent
        .dbyt $2187                         ; C-5  523.2 Hz NTSC / 504.0 Hz PAL
        .dbyt $2386                         ; C#5  554.4 Hz NTSC / 534.0 Hz PAL
        .dbyt $25A2                         ; D-5  587.3 Hz NTSC / 565.8 Hz PAL
        .dbyt $27DF                         ; D#5  622.2 Hz NTSC / 599.4 Hz PAL
        .dbyt $2A3E                         ; E-5  659.2 Hz NTSC / 635.1 Hz PAL
        .dbyt $2CC1                         ; F-5  698.4 Hz NTSC / 672.8 Hz PAL
        .dbyt $2F6B                         ; F#5  740.0 Hz NTSC / 712.9 Hz PAL
        .dbyt $323C                         ; G-5  783.9 Hz NTSC / 755.2 Hz PAL
        .dbyt $3539                         ; G#5  830.6 Hz NTSC / 800.1 Hz PAL
        .dbyt $3863                         ; A-5  879.9 Hz NTSC / 847.7 Hz PAL
        .dbyt $3BBE                         ; A#5  932.3 Hz NTSC / 898.1 Hz PAL
        .dbyt $3F4B                         ; B-5  987.7 Hz NTSC / 951.5 Hz PAL

OctaveShift:
        .byte $04,$03,$02,$01,$00           ; octave 0-4: shift right this + 1 times

; X = voice register offset: count the drum down; at 0 the voice goes
; back to its pattern on the next tick.
Drum_Count:
        cpx #$00
        bne Drum_Count2
        dec mDrumCount
        beq Drum_Count1Done
        rts

Drum_Count1Done:
        lda #$00
        sta mDrum
        lda #$01
        sta mDuration
        rts

Drum_Count2:
        cpx #$07
        bne Drum_Count3
        dec mDrumCount+1
        beq Drum_Count2Done
        rts

Drum_Count2Done:
        lda #$00
        sta mDrum+1
        lda #$01
        sta mDuration+1
        rts

Drum_Count3:
        dec mDrumCount+2
        beq Drum_Count3Done
        rts

Drum_Count3Done:
        lda #$00
        sta mDrum+2
        lda #$01
        sta mDuration+2
        rts

; $F6 drum: noise, AD = $08, SR = $00, frequency high $FA, gate.
Drum_Noise:
        lda #$08
        sta SID_V1_AD,x
        lda #$00
        sta SID_V1_SR,x
        lda #$FA
        sta SID_V1_FREQ_HI,x
        lda #$80
        sta SID_V1_CTRL,x
        lda #$81                            ; gate on
        sta SID_V1_CTRL,x
        rts

; $F7-$FA: empty drums. They never count down, so a voice that used
; one would stop for good.
Drum_F7:
        rts

Drum_F8:
        rts

Drum_F9:
        rts

Drum_FA:
        rts

SavedPtrs:
        .word $922A, $93E9                  ; voice 1 and 2 pattern pointers between calls (snapshot)
; ---- 461 byte(s) not referenced by the sound engine ----
        .res 461, $00

; SID RIPPER WRAPPER (not part of the game).
; Init: A = song; patches the JMP below with that song's stub.
Rip_Init:
        tax
        lda Rip_SongLo,x
        sta Rip_InitJmp+1
        lda Rip_SongHi,x
        sta Rip_InitJmp+2

Rip_InitJmp:
        jmp Rip_Song5

Rip_SongLo:
        .lobytes Rip_Song0, Rip_Song1, Rip_Song2, Rip_Song3, Rip_Song4, Rip_Song5
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

Rip_SongHi:
        .hibytes Rip_Song0, Rip_Song1, Rip_Song2, Rip_Song3, Rip_Song4, Rip_Song5
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Play: calls the driver twice per frame.
Rip_Play:
        jsr Play
        jmp Play

; ---- 203 byte(s) not referenced by the sound engine ----
        .res 203, $00

; Song 0: init its module, then save the pointers.
Rip_Song0:
        nop
        bit Rip_BitTarget
        jsr S0_Init
        jmp Rip_SongDone

; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60

Rip_Song1:
        nop
        bit Rip_BitTarget
        jsr S1_Init
        jmp Rip_SongDone

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60

Rip_Song2:
        nop
        bit Rip_BitTarget
        jsr S2_Init
        jmp Rip_SongDone

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60

Rip_Song3:
        nop
        bit Rip_BitTarget
        jsr S3_Init
        jmp Rip_SongDone

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60

Rip_Song4:
        nop
        bit Rip_BitTarget
        jsr S4_Init
        jmp Rip_SongDone

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60

Rip_Song5:
        nop
        bit Rip_BitTarget
        jsr S5_Init
        jmp Rip_SongDone

; ---- 5 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60

Rip_BitTarget:
        .byte $60                           ; the stubs BIT this byte (a no-op)
; ---- 13 byte(s) not referenced by the sound engine ----
        .byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60

; Save the zero-page pointers like Play does, slides off.
Rip_SongDone:
        lda zPat1
        sta SavedPtrs
        lda zPat1+1
        sta SavedPtrs+1
        lda zPat2
        sta SavedPtrs+2
        lda zPat2+1
        sta SavedPtrs+3
        lda #$00
        sta mSlideOn
        rts

; ---- 654 byte(s) not referenced by the sound engine ----
        .res 654, $00

; SONG 0 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S0_Init:
        lda #<S0_Pat00
        sta zPat1
        lda #>S0_Pat00
        sta zPat1+1
        lda #<S0_Pat03
        sta zPat2
        lda #>S0_Pat03
        sta zPat2+1
        lda #<S0_Pat06
        sta zPat3
        lda #>S0_Pat06
        sta zPat3+1
        lda #<S0_Order1
        sta mOrder1
        lda #>S0_Order1
        sta mOrder1+1
        lda #<S0_Order2
        sta mOrder2
        lda #>S0_Order2
        sta mOrder2+1
        lda #<S0_Order3
        sta mOrder3
        lda #>S0_Order3
        sta mOrder3+1
        lda #$04
        sta mSpeed
        lda #$01
        sta mSlideSpeed
        sta mSlideSpeed+1
        lda #$00
        sta mSlideStepHi
        lda #$3C
        sta mSlideStepLo
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S0_Order1:
        .word S0_Pat00, S0_Pat00, S0_Pat01, S0_Pat01
        .word S0_Pat02, S0_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S0_Order2:
        .word S0_Pat03, S0_Pat03, S0_Pat04, S0_Pat04
        .word S0_Pat05, S0_Pat05
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S0_Order3:
        .word S0_Pat06, S0_Pat06, S0_Pat07, S0_Pat07
        .word S0_Pat08, S0_Pat08
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S0_Pat00:
        .byte C_TRILL                       ; octave trill on
        .byte C_PULSE,$0A,$0A               ; pulse width $0A0A
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $0C,$53                       ; D-5    12 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $0C,$53                       ; D-5    12 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $0C,$51                       ; C-5    12 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $0C,$51                       ; C-5    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $10,$4B                       ; A#4    16 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $0C,$46                       ; F-4    12 ticks
        .byte $0C,$44                       ; D#4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte C_AD,$0B                      ; attack/decay $0B
        .byte $10,$43                       ; D-4    16 ticks
        .byte $10,$47                       ; F#4    16 ticks
        .byte $10,$4A                       ; A-4    16 ticks
        .byte $10,$54                       ; D#5    16 ticks
        .byte $40,$53                       ; D-5    64 ticks
        .byte C_AD,$09                      ; attack/decay $09
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat01:
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_PULSE,$01,$02               ; pulse width $0201
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $0C,$53                       ; D-5    12 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $0C,$51                       ; C-5    12 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $0C,$51                       ; C-5    12 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte C_SLIDE_DELAY                 ; slide on, after the delay
        .byte C_TRILL                       ; octave trill on
        .byte C_AD,$0F                      ; attack/decay $0F
        .byte $40,$6A                       ; A-6    64 ticks
        .byte C_SLIDE_OFF                   ; slide off
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S0_Pat02:
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte C_PWRANGE,$00,$04             ; pulse sweep range $00-$04
        .byte C_TRILL_OFF                   ; octave trill off
        .byte $04,$00                       ; rest    4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $08,$4B                       ; A#4     8 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $18,$58                       ; G-5    24 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $08,$4B                       ; A#4     8 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $18,$58                       ; G-5    24 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $18,$57                       ; F#5    24 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $18,$57                       ; F#5    24 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $18,$54                       ; D#5    24 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $18,$54                       ; D#5    24 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $18,$54                       ; D#5    24 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$54                       ; D#5     4 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $18,$54                       ; D#5    24 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $18,$53                       ; D-5    24 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$57                       ; F#5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $14,$53                       ; D-5    20 ticks
        .byte C_PWRANGE,$01,$0F             ; pulse sweep range $01-$0F
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat03:
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_PULSE,$0A,$0A               ; pulse width $0A0A
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_SLIDE_OFF                   ; slide off
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $10,$48                       ; G-4    16 ticks
        .byte $34,$00                       ; rest   52 ticks
        .byte C_AD,$0B                      ; attack/decay $0B
        .byte $10,$00                       ; rest   16 ticks
        .byte $10,$43                       ; D-4    16 ticks
        .byte $10,$47                       ; F#4    16 ticks
        .byte $10,$4A                       ; A-4    16 ticks
        .byte $40,$47                       ; F#4    64 ticks
        .byte C_AD,$09                      ; attack/decay $09
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat04:
        .byte C_PULSE,$01,$02               ; pulse width $0201
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL                       ; octave trill on
        .byte C_SLIDE_OFF                   ; slide off
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$4B                       ; A#4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $0C,$48                       ; G-4    12 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$44                       ; D#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte C_SLIDE                       ; slide on
        .byte C_AD,$0F                      ; attack/decay $0F
        .byte $40,$67                       ; F#6    64 ticks
        .byte C_SLIDE_OFF                   ; slide off
        .byte C_AD,$09                      ; attack/decay $09
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S0_Pat05:
        .byte C_AD,$07                      ; attack/decay $07
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PULSE,$64,$02               ; pulse width $0264
        .byte C_WAVE,$21                    ; waveform $21
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$3B                       ; A#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$54                       ; D#5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$44                       ; D#4     2 ticks
        .byte $02,$41                       ; C-4     2 ticks
        .byte $02,$38                       ; G-3     2 ticks
        .byte $02,$34                       ; D#3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$57                       ; F#5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$47                       ; F#4     2 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $02,$3A                       ; A-3     2 ticks
        .byte $02,$37                       ; F#3     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte C_WAVE,$41                    ; waveform $41
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat06:
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S0_Pat07:
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $04,$2B                       ; A#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $04,$2B                       ; A#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $04,$2B                       ; A#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $04,$2B                       ; A#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S0_Pat08:
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $04,$28                       ; G-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$11                       ; C-1     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$13                       ; D-1     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte C_DRUM,$08                    ; drum for 7 ticks
        .byte $00                           ; end of pattern
; ---- 3 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$1E

; SONG 1 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S1_Init:
        lda #<S1_Pat00
        sta zPat1
        lda #>S1_Pat00
        sta zPat1+1
        lda #<S1_Pat01
        sta zPat2
        lda #>S1_Pat01
        sta zPat2+1
        lda #<S1_Pat02
        sta zPat3
        lda #>S1_Pat02
        sta zPat3+1
        lda #<S1_Order1
        sta mOrder1
        lda #>S1_Order1
        sta mOrder1+1
        lda #<S1_Order2
        sta mOrder2
        lda #>S1_Order2
        sta mOrder2+1
        lda #<S1_Order3
        sta mOrder3
        lda #>S1_Order3
        sta mOrder3+1
        lda #$03
        sta mSpeed
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S1_Order1:
        .word S1_Pat00, S1_Pat00
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S1_Order2:
        .word S1_Pat01, S1_Pat01
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S1_Order3:
        .word S1_Pat02, S1_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S1_Pat00:
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat01:
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S1_Pat02:
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte $18,$21                       ; C-2    24 ticks
        .byte $08,$1C                       ; B-1     8 ticks
        .byte $18,$1A                       ; A-1    24 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $18,$16                       ; F-1    24 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $18,$18                       ; G-1    24 ticks
        .byte $08,$1C                       ; B-1     8 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$35

; SONG 2 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S2_Init:
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
        lda #<S2_Order1
        sta mOrder1
        lda #>S2_Order1
        sta mOrder1+1
        lda #<S2_Order2
        sta mOrder2
        lda #>S2_Order2
        sta mOrder2+1
        lda #<S2_Order3
        sta mOrder3
        lda #>S2_Order3
        sta mOrder3+1
        lda #$04
        sta mSpeed
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S2_Order1:
        .word S2_Pat00, S2_Pat01, S2_Pat01, S2_Pat01
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S2_Order2:
        .word S2_Pat02, S2_Pat03, S2_Pat03, S2_Pat03
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S2_Order3:
        .word S2_Pat04, S2_Pat05, S2_Pat06, S2_Pat06
        .word S2_Pat06
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S2_Pat00:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_TRILL                       ; octave trill on
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$00                      ; sustain/release $00
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4B                       ; A#4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $08,$4C                       ; B-4     8 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$49                       ; G#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$49                       ; G#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$49                       ; G#4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$41                       ; C-4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$42                       ; C#4     4 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$42                       ; C#4     4 ticks
        .byte $08,$43                       ; D-4     8 ticks
        .byte $08,$53                       ; D-5     8 ticks
        .byte $08,$53                       ; D-5     8 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $08,$4C                       ; B-4     8 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte $10,$4C                       ; B-4    16 ticks
        .byte $10,$4A                       ; A-4    16 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $02,$43                       ; D-4     2 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $08,$38                       ; G-3     8 ticks
        .byte $20,$58                       ; G-5    32 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat01:
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat02:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_TRILL                       ; octave trill on
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_SR,$00                      ; sustain/release $00
        .byte $08,$00                       ; rest    8 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $08,$45                       ; E-4     8 ticks
        .byte $08,$45                       ; E-4     8 ticks
        .byte $04,$43                       ; D-4     4 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $04,$47                       ; F#4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $08,$43                       ; D-4     8 ticks
        .byte $08,$43                       ; D-4     8 ticks
        .byte $08,$43                       ; D-4     8 ticks
        .byte $04,$38                       ; G-3     4 ticks
        .byte $04,$3A                       ; A-3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$3B                       ; A#3     4 ticks
        .byte $04,$3C                       ; B-3     4 ticks
        .byte $04,$3B                       ; A#3     4 ticks
        .byte $08,$3C                       ; B-3     8 ticks
        .byte $08,$4C                       ; B-4     8 ticks
        .byte $08,$4C                       ; B-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $08,$48                       ; G-4     8 ticks
        .byte $08,$44                       ; D#4     8 ticks
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte $10,$43                       ; D-4    16 ticks
        .byte $10,$41                       ; C-4    16 ticks
        .byte $18,$00                       ; rest   24 ticks
        .byte $20,$53                       ; D-5    32 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat03:
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat04:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_SLIDE_OFF                   ; ignored on voice 3
        .byte C_PULSE,$0A,$0A               ; pulse width $0A0A
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat05:
        .byte $08,$18                       ; G-1     8 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $08,$13                       ; D-1     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte $04,$25                       ; E-2     4 ticks
        .byte $08,$15                       ; E-1     8 ticks
        .byte $08,$25                       ; E-2     8 ticks
        .byte $08,$13                       ; D-1     8 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $04,$1A                       ; A-1     4 ticks
        .byte $08,$0A                       ; A-0     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $08,$13                       ; D-1     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $08,$13                       ; D-1     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$21                       ; C-2     8 ticks
        .byte $04,$34                       ; D#3     4 ticks
        .byte $04,$34                       ; D#3     4 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $08,$34                       ; D#3     8 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $08,$13                       ; D-1     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$28                       ; G-2     8 ticks
        .byte $08,$23                       ; D-2     8 ticks
        .byte $08,$18                       ; G-1     8 ticks
        .byte $28,$18                       ; G-1    40 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S2_Pat06:
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $64,$00                       ; rest  100 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; SONG 3 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S3_Init:
        lda #<S3_Pat00
        sta zPat1
        lda #>S3_Pat00
        sta zPat1+1
        lda #<S3_Pat01
        sta zPat2
        lda #>S3_Pat01
        sta zPat2+1
        lda #<S3_Pat02
        sta zPat3
        lda #>S3_Pat02
        sta zPat3+1
        lda #<S3_Order1
        sta mOrder1
        lda #>S3_Order1
        sta mOrder1+1
        lda #<S3_Order2
        sta mOrder2
        lda #>S3_Order2
        sta mOrder2+1
        lda #<S3_Order3
        sta mOrder3
        lda #>S3_Order3
        sta mOrder3+1
        lda #$04
        sta mSpeed
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S3_Order1:
        .word S3_Pat00, S3_Pat00
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S3_Order2:
        .word S3_Pat01, S3_Pat01
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S3_Order3:
        .word S3_Pat02, S3_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S3_Pat00:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$00                      ; sustain/release $00
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_SLIDE_OFF                   ; slide off
        .byte C_TRILL                       ; octave trill on
        .byte $04,$6A                       ; A-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $0C,$4A                       ; A-4    12 ticks
        .byte $0C,$6A                       ; A-6    12 ticks
        .byte $04,$6A                       ; A-6     4 ticks
        .byte $04,$6C                       ; B-6     4 ticks
        .byte $04,$6A                       ; A-6     4 ticks
        .byte $10,$69                       ; G#6    16 ticks
        .byte $20,$00                       ; rest   32 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat01:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$00                      ; sustain/release $00
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL                       ; octave trill on
        .byte C_SLIDE_OFF                   ; slide off
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $0C,$6A                       ; A-6    12 ticks
        .byte $0C,$65                       ; E-6    12 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $10,$5C                       ; B-5    16 ticks
        .byte $20,$00                       ; rest   32 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S3_Pat02:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte C_SR,$00                      ; sustain/release $00
        .byte $0C,$1A                       ; A-1    12 ticks
        .byte $0C,$25                       ; E-2    12 ticks
        .byte $0C,$1A                       ; A-1    12 ticks
        .byte $0C,$1A                       ; A-1    12 ticks
        .byte $0C,$25                       ; E-2    12 ticks
        .byte $10,$15                       ; E-1    16 ticks
        .byte $20,$00                       ; rest   32 ticks
        .byte $00                           ; end of pattern
; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $00,$00,$00,$00

; SONG 4 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S4_Init:
        lda #<S4_Pat00
        sta zPat1
        lda #>S4_Pat00
        sta zPat1+1
        lda #<S4_Pat01
        sta zPat2
        lda #>S4_Pat01
        sta zPat2+1
        lda #<S4_Pat02
        sta zPat3
        lda #>S4_Pat02
        sta zPat3+1
        lda #<S4_Order1
        sta mOrder1
        lda #>S4_Order1
        sta mOrder1+1
        lda #<S4_Order2
        sta mOrder2
        lda #>S4_Order2
        sta mOrder2+1
        lda #<S4_Order3
        sta mOrder3
        lda #>S4_Order3
        sta mOrder3+1
        lda #$04
        sta mSpeed
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S4_Order1:
        .word S4_Pat00, S4_Pat00
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S4_Order2:
        .word S4_Pat01, S4_Pat01
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S4_Order3:
        .word S4_Pat02, S4_Pat02
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S4_Pat00:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$00                      ; sustain/release $00
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_SLIDE_OFF                   ; slide off
        .byte C_TRILL                       ; octave trill on
        .byte $08,$55                       ; E-5     8 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $10,$45                       ; E-4    16 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $08,$49                       ; G#4     8 ticks
        .byte $04,$49                       ; G#4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $10,$4A                       ; A-4    16 ticks
        .byte $C7,$00                       ; rest  199 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S4_Pat01:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$05                      ; attack/decay $05
        .byte C_SR,$20                      ; sustain/release $20
        .byte C_PWSWEEP_OFF                 ; pulse sweep off
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_SLIDE_OFF                   ; slide off
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$59                       ; G#5     4 ticks
        .byte $04,$5C                       ; B-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$65                       ; E-6     4 ticks
        .byte $0C,$00                       ; rest   12 ticks
        .byte $C7,$00                       ; rest  199 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S4_Pat02:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$0A                      ; attack/decay $0A
        .byte C_SR,$10                      ; sustain/release $10
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $08,$15                       ; E-1     8 ticks
        .byte $08,$15                       ; E-1     8 ticks
        .byte $08,$15                       ; E-1     8 ticks
        .byte $08,$15                       ; E-1     8 ticks
        .byte $08,$1A                       ; A-1     8 ticks
        .byte $10,$1A                       ; A-1    16 ticks
        .byte $C7,$00                       ; rest  199 ticks
        .byte $00                           ; end of pattern
; ---- 4 byte(s) not referenced by the sound engine ----
        .byte $00,$FF,$FF,$FF

; SONG 5 MODULE
; Init: first pattern of each voice, order lists, speed,
; counters (order index 2: entry 0 is the pattern loaded here).
S5_Init:
        lda #<S5_Pat00
        sta zPat1
        lda #>S5_Pat00
        sta zPat1+1
        lda #<S5_Pat05
        sta zPat2
        lda #>S5_Pat05
        sta zPat2+1
        lda #<S5_Pat10
        sta zPat3
        lda #>S5_Pat10
        sta zPat3+1
        lda #<S5_Order1
        sta mOrder1
        lda #>S5_Order1
        sta mOrder1+1
        lda #<S5_Order2
        sta mOrder2
        lda #>S5_Order2
        sta mOrder2+1
        lda #<S5_Order3
        sta mOrder3
        lda #>S5_Order3
        sta mOrder3+1
        lda #$06
        sta mSpeed
        lda #$04
        sta mSpeedCount
        sta mDuration
        sta mDuration+1
        sta mDuration+2
        lda #$02
        sta mOrderIdx
        sta mOrderIdx+1
        sta mOrderIdx+2
        rts

; Voice 1 order list (pattern pointers; high byte 0 = restart).
S5_Order1:
        .word S5_Pat00, S5_Pat00, S5_Pat01, S5_Pat01
        .word S5_Pat02, S5_Pat02, S5_Pat00, S5_Pat00
        .word S5_Pat03, S5_Pat03, S5_Pat04, S5_Pat03
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 2 order list (pattern pointers; high byte 0 = restart).
S5_Order2:
        .word S5_Pat05, S5_Pat05, S5_Pat06, S5_Pat06
        .word S5_Pat07, S5_Pat07, S5_Pat05, S5_Pat05
        .word S5_Pat08, S5_Pat08, S5_Pat09, S5_Pat08
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

; Voice 3 order list (pattern pointers; high byte 0 = restart).
S5_Order3:
        .word S5_Pat10, S5_Pat10, S5_Pat11, S5_Pat11
        .word S5_Pat12, S5_Pat12, S5_Pat10, S5_Pat10
        .word S5_Pat13, S5_Pat13, S5_Pat14, S5_Pat13
        .word $0000                         ; end: back to the start
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S5_Pat00:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$00                      ; sustain/release $00
        .byte C_PWSWEEP                     ; pulse sweep on
        .byte C_SLIDE_OFF                   ; slide off
        .byte C_TRILL                       ; octave trill on
        .byte C_VOLUME,$0D                  ; mode/volume $0D
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $08,$53                       ; D-5     8 ticks
        .byte $04,$45                       ; E-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $04,$48                       ; G-4     4 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$56                       ; F-5     8 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$53                       ; D-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$4C                       ; B-4     4 ticks
        .byte C_SR,$20                      ; sustain/release $20
        .byte $20,$51                       ; C-5    32 ticks
        .byte $00                           ; end of pattern
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $00,$00

S5_Pat01:
        .byte C_VOLUME,$0F                  ; mode/volume $0F
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $08,$5A                       ; A-5     8 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $08,$51                       ; C-5     8 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $08,$5A                       ; A-5     8 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat02:
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $04,$66                       ; F-6     4 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $08,$61                       ; C-6     8 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $04,$46                       ; F-4     4 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $04,$66                       ; F-6     4 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $10,$56                       ; F-5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat03:
        .byte C_TRILL_OFF                   ; octave trill off
        .byte C_VOLUME,$0C                  ; mode/volume $0C
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $10,$5A                       ; A-5    16 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$55                       ; E-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $18,$56                       ; F-5    24 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat04:
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$66                       ; F-6     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$64                       ; D#6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $08,$63                       ; D-6     8 ticks
        .byte $08,$5B                       ; A#5     8 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$66                       ; F-6     4 ticks
        .byte $04,$5B                       ; A#5     4 ticks
        .byte $04,$63                       ; D-6     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $04,$64                       ; D#6     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$61                       ; C-6     4 ticks
        .byte $18,$5B                       ; A#5    24 ticks
        .byte $08,$00                       ; rest    8 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat05:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$07                      ; attack/decay $07
        .byte C_SR,$20                      ; sustain/release $20
        .byte C_PULSE,$01,$01               ; pulse width $0101
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5C                       ; B-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat06:
        .byte C_PULSE,$06,$06               ; pulse width $0606
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$56                       ; F-5     8 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$4A                       ; A-4     8 ticks
        .byte $04,$4A                       ; A-4     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $04,$51                       ; C-5     4 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $08,$56                       ; F-5     8 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $10,$51                       ; C-5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat07:
        .byte C_PULSE,$01,$01               ; pulse width $0101
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte C_PULSE,$06,$06               ; pulse width $0606
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $08,$5A                       ; A-5     8 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $10,$51                       ; C-5    16 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat08:
        .byte C_PULSE,$02,$02               ; pulse width $0202
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$71                       ; C-7     2 ticks
        .byte $02,$68                       ; G-6     2 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$71                       ; C-7     2 ticks
        .byte $02,$68                       ; G-6     2 ticks
        .byte $02,$65                       ; E-6     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$58                       ; G-5     2 ticks
        .byte $02,$55                       ; E-5     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$48                       ; G-4     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat09:
        .byte C_PULSE,$06,$06               ; pulse width $0606
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6B                       ; A#6     2 ticks
        .byte $02,$73                       ; D-7     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$56                       ; F-5     4 ticks
        .byte $04,$58                       ; G-5     4 ticks
        .byte $04,$5A                       ; A-5     4 ticks
        .byte $08,$5B                       ; A#5     8 ticks
        .byte $08,$58                       ; G-5     8 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6B                       ; A#6     2 ticks
        .byte $02,$73                       ; D-7     2 ticks
        .byte $02,$46                       ; F-4     2 ticks
        .byte $02,$4A                       ; A-4     2 ticks
        .byte $02,$51                       ; C-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5A                       ; A-5     2 ticks
        .byte $02,$61                       ; C-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6A                       ; A-6     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$6B                       ; A#6     2 ticks
        .byte $02,$73                       ; D-7     2 ticks
        .byte $02,$73                       ; D-7     2 ticks
        .byte $02,$6B                       ; A#6     2 ticks
        .byte $02,$66                       ; F-6     2 ticks
        .byte $02,$63                       ; D-6     2 ticks
        .byte $02,$5B                       ; A#5     2 ticks
        .byte $02,$56                       ; F-5     2 ticks
        .byte $02,$53                       ; D-5     2 ticks
        .byte $02,$4B                       ; A#4     2 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat10:
        .byte C_WAVE,$41                    ; waveform $41
        .byte C_AD,$09                      ; attack/decay $09
        .byte C_SR,$40                      ; sustain/release $40
        .byte C_PULSE,$0A,$0A               ; pulse width $0A0A
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$18                       ; G-1     2 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$33                       ; D-3     2 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$18                       ; G-1     2 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte $04,$16                       ; F-1     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$14                       ; D#1     4 ticks
        .byte $06,$18                       ; G-1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$23                       ; D-2     2 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$23                       ; D-2     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$18                       ; G-1     2 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat11:
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$24                       ; D#2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat12:
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$16                       ; F-1     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$16                       ; F-1     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$21                       ; C-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$28                       ; G-2     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat13:
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$21                       ; C-2     2 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$18                       ; G-1     4 ticks
        .byte $06,$26                       ; F-2     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $02,$36                       ; F-3     2 ticks
        .byte $02,$31                       ; C-3     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $00                           ; end of pattern
; ---- 1 byte(s) not referenced by the sound engine ----
        .byte $00

S5_Pat14:
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $02,$2B                       ; A#2     2 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$21                       ; C-2     4 ticks
        .byte $06,$1B                       ; A#1     6 ticks
        .byte $02,$00                       ; rest    2 ticks
        .byte C_DRUM,$06                    ; drum for 5 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $02,$2B                       ; A#2     2 ticks
        .byte $02,$26                       ; F-2     2 ticks
        .byte $04,$1B                       ; A#1     4 ticks
        .byte C_DRUM,$04                    ; drum for 3 ticks
        .byte $04,$26                       ; F-2     4 ticks
        .byte $00                           ; end of pattern
