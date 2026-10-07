;==============================================================================
;  Mark Cooksey NES sound engine - ALADDIN (E)
;  Alternate version without DMC: 4 channels, but the RAM layout keeps
;  5-byte arrays like the DMC version. Differences from Dragon's Lair:
;    * tempo: Music_Update adds mTempo to mTempoAcc and only runs the
;      tracks on carry. There is no CLC before the add, and mTempo is
;      only ever set to $FF (by Music_Play).
;    * no arpeggio envelopes (instrument bytes +7/+8 are read and
;      dropped; the data they point at is still in the ROM)
;    * new command $65 CMD_DURTABLE .word table (the duration table
;      pointer is shared by all channels; no song here uses it)
;    * new sound effect step format with a delay per step
;
;  Source: Aladdin (E) [!].nes, AxROM, 32K PRG bank 0 (file offset $506B)
;  at $D05B-$EFD9. $D000-$D05A belongs to the game, and unrelated
;  code starts at $EFDA.
;  Reassembles byte-identically:  ca65 aladdin_sound.s
;                    ld65 -C aladdin_sound.cfg -o out.bin aladdin_sound.o
;
;  ENTRY POINTS (SoundJumpTable, $D05B)
;    $D05B Sfx_Init      silence/reset all sound effects
;    $D05E Sfx_Play      A = priority, X = effect number
;    $D061 Sfx_Update    once per frame
;    $D064 Music_Play    A = song number; A >= $80 stops the music
;    $D067 Music_Update  once per frame
;
;  SONG TABLE: SongLo/SongHi, 5 pointers per song:
;    Sq1, Sq2, Tri, Noise track, duration table.
;
;  TRACK / PATTERN DATA
;    Each channel reads a stream of 2-byte events (some commands are longer).
;      byte 0  bit 7     = bit 4 of the instrument number
;              bits 0-6  = note number $00-$5F (index into PeriodLo/PeriodHi;
;                          $00 = C2 on a square channel, the triangle sounds an
;                          octave lower). The channel transpose (set by
;                          CMD_CALL) is added to it. Values $60-$7F are commands.
;      byte 1  bits 4-7  = instrument number bits 0-3
;              bits 0-3  = length index into the current duration table
;                          (16 entries, frames per note)
;    Note names in the comments are the untransposed values; "= n fr" is the
;    length in frames, shown when only one duration table can apply.
;    Commands (byte 0 & $7F):
;      $60 CMD_REST    len            rest (volume -> 0 if reg0 bit 4, constant
;                                      volume, is set); byte 1 low nibble =
;                                      length index
;      $61 CMD_END                    stop this channel
;      $62 CMD_CALL    pat,trn,cnt    play pattern #pat (PatternLo/Hi), adding
;                                      trn to every note, cnt times, then
;                                      continue after this command (one level
;                                      only: one return address per channel)
;      $63 CMD_RETURN                 end of pattern
;      $64 CMD_JUMP    .word addr     continue at addr (song loop)
;      $65 CMD_DURTABLE .word table   switch the duration table
;
;  INSTRUMENTS (9 bytes, InstrumentLo/Hi)
;      +0      flags: 0 or 1 = uses a volume envelope, >= 2 = no volume envelope
;      +1,+2   volume envelope pointer (only if flags < 2)
;      +3,+4   pitch envelope pointer (high byte 0 = none)
;      +5      OR'ed into register 0 (duty, length-halt, constant volume)
;      +6      OR'ed into register 3 (length counter load)
;      +7,+8   arpeggio envelope pointer (high byte 0 = none)
;      (Aladdin: +7,+8 still present but ignored)
;
;  ENVELOPES  (each step is a value and a frame count; count 0 = 256)
;    Volume:    vol,frames ... $80            $80 = stop, keep the last volume
;    Pitch:     delta,frames ... $80 .word a  delta is added to the low period
;                                            byte (no carry), 0 = just wait,
;                                            $80 = jump to a (loop)
;    Arpeggio:  semis,frames ... $80 .word a  note offset from the played note,
;                                            $80 = jump to a (loop)
;
;  SOUND EFFECTS (SfxLo/SfxHi, Sfx_Play: A = priority, X = effect number)
;    header: channel (0-3), initial delay, reg0, reg3, reg2
;            An effect only starts if its priority >= the one playing on that
;            channel. While it plays, the music on that channel keeps running
;            but stops writing to the APU.
;    then steps that carry their own delay (a step lasts delay+1 frames;
;    different from Dragon's Lair):
;      square/triangle:  delay, reg0, reg3, reg2   reg3 = reg2 = 0 -> end
;      noise:            delay, reg0, period       period = 0      -> end
;      any channel:      $FF                                       -> end
;                        delay, reg0, $FF                          -> restart
;    Sfx_Play: channel >= 4 returns without pulling X (stack bug, unused).
;    Sfx_Stop: "lda mApuStatus / and ChanDisableMask,x" - result discarded.
;
;  Bytes the engine never reads are kept (so the file reassembles) and are
;  marked "unreferenced", "never read" or "never reached".
;==============================================================================

; ---------------------------------------------------------------- RAM
zPtr                 = $F6          ; pointer: track / instrument / envelope / effect data
zDurTab              = $F8          ; pointer: current duration table
zChan                = $FA          ; current channel number
zRegOfs              = $FB          ; current channel * 4 (APU register offset)
zTemp                = $FC          ; scratch
mTrkPtrLo            = $013E        ; track pointer low, per channel
mTrkPtrHi            = $0143        ; track pointer high, per channel
mDurTabLo            = $0148        ; duration table pointer (global)
mDurTabHi            = $0149
mNoteTimer           = $014A        ; frames left of the current note
mVolEnvTimer         = $014F        ; volume envelope
mVolEnvHi            = $0153
mVolEnvLo            = $0157
mPitchEnvTimer       = $015B        ; pitch envelope
mPitchEnvHi          = $015F
mPitchEnvLo          = $0163
mInstTemp            = $0168        ; instrument number / flags while loading
mTranspose           = $0169        ; transpose added to notes (CMD_CALL)
mRetLo               = $016E        ; CMD_CALL return address
mRetHi               = $0173
mLoopCount           = $0178        ; CMD_CALL repeat count
mLoopActive          = $017D        ; nonzero while a CMD_CALL repeats
mChanFlags           = $0182        ; bit 0 = track running, bit 1 = owns the APU (no effect)
mRegDirty            = $0187        ; bit 0 = reg3, bit 1 = reg2, bit 2 = reg0 need writing
mNote                = $018C        ; current note (after transpose)
mReg3                = $0190        ; shadow of register 3 (period high, length)
mReg2                = $0194        ; shadow of register 2 (period low)
mReg0                = $0198        ; shadow of register 0 (duty, volume)
mApuStatus           = $019C        ; shadow APU_STATUS
mCmdVector           = $019D        ; command handler address (JMP indirect)
sPtrHi               = $019F        ; effect pointer high, per channel (0 = none)
sPtrLo               = $01A4        ; effect pointer low
mChanFlagsSave       = $01A9        ; mChanFlags restored when an effect ends
sTimer               = $01AF        ; frames until the next effect step
sSpeed               = $01B3        ; effect speed / step delay
sId                  = $01B7        ; effect number (for restart)
sNewPriority         = $01BB        ; priority passed to Sfx_Play
sPriority            = $01BC        ; priority of the effect on each channel
mTempo               = $01C0        ; tempo (added to mTempoAcc each frame)
mTempoAcc            = $01C1        ; tempo accumulator

; ---------------------------------------------------------------- APU
SQ1_VOL              = $4000
SQ1_SWEEP            = $4001
SQ1_LO               = $4002
SQ1_HI               = $4003
SQ2_VOL              = $4004
SQ2_SWEEP            = $4005
SQ2_LO               = $4006
SQ2_HI               = $4007
TRI_LINEAR           = $4008
TRI_LO               = $400A
TRI_HI               = $400B
NOISE_VOL            = $400C
NOISE_LO             = $400E
NOISE_HI             = $400F
DMC_FREQ             = $4010
DMC_RAW              = $4011
DMC_START            = $4012
DMC_LEN              = $4013
OAM_DMA              = $4014
APU_STATUS           = $4015
APU_FRAME            = $4017

; ---------------------------------------------------------------- track commands
CMD_REST             = $60
CMD_END              = $61
CMD_CALL             = $62
CMD_RETURN           = $63
CMD_JUMP             = $64
CMD_DURTABLE         = $65

.segment "SOUND"

;----------------------------------------------------------------------
; Sound jump table: the game only calls these five entries.
SoundJumpTable:
        jmp Sfx_Init

        jmp Sfx_Play

        jmp Sfx_Update

        jmp Music_Play

        jmp Music_Update

;----------------------------------------------------------------------
; Start song A. A >= $80 stops the music (all channel flags cleared,
; APU_STATUS = $E0).
Music_Play:
        cmp #$80
        bcc Music_LoadSong
        lda #$00
        sta mChanFlags
        sta mChanFlagsSave
        sta mChanFlags+1
        sta mChanFlagsSave+1
        sta mChanFlags+2
        sta mChanFlagsSave+2
        sta mChanFlags+3
        sta mChanFlagsSave+3
        lda #$E0
        sta APU_STATUS
        sta mApuStatus
        rts

;----------------------------------------------------------------------
; Load the track pointers and the duration table pointer of song A,
; reset timers/transpose/loops, enable the channels (flags = 3).
Music_LoadSong:
        sta zTemp
        asl a
        asl a
        adc zTemp
        tax
        lda SongLo,x
        sta mTrkPtrLo
        lda SongHi,x
        sta mTrkPtrHi
        inx
        lda SongLo,x
        sta mTrkPtrLo+1
        lda SongHi,x
        sta mTrkPtrHi+1
        inx
        lda SongLo,x
        sta mTrkPtrLo+2
        lda SongHi,x
        sta mTrkPtrHi+2
        inx
        lda SongLo,x
        sta mTrkPtrLo+3
        lda SongHi,x
        sta mTrkPtrHi+3
        inx
        lda SongLo,x
        sta mDurTabLo
        lda SongHi,x
        sta mDurTabHi
        lda #$01
        sta mNoteTimer
        sta mNoteTimer+1
        lda #$02
        sta mNoteTimer+2
        sta mNoteTimer+3
        lda #$01
        sta mTempoAcc
        lda #$FF
        sta mTempo
        lda #$00
        sta mTranspose
        sta mTranspose+1
        sta mTranspose+2
        sta mTranspose+3
        sta mLoopActive
        sta mLoopActive+1
        sta mLoopActive+2
        sta mLoopActive+3
        lda #$0F
        sta APU_STATUS
        lda #$08
        sta SQ1_SWEEP
        sta SQ2_SWEEP
        lda #$03
        sta mChanFlags
        sta mChanFlagsSave
        sta mChanFlags+1
        sta mChanFlagsSave+1
        sta mChanFlags+2
        sta mChanFlagsSave+2
        sta mChanFlags+3
        sta mChanFlagsSave+3
        rts

;----------------------------------------------------------------------
; Called once per frame: run every music channel.
Music_Update:
        lda mTempo
        adc mTempoAcc                       ; no CLC before this ADC
        sta mTempoAcc
        bcs Music_UpdateAll
        rts

;----------------------------------------------------------------------
; Run the four music channels.
Music_UpdateAll:
        ldy #$00
        ldx #$00
        jsr Music_UpdateChannel
        ldy #$01
        ldx #$04
        jsr Music_UpdateChannel
        ldy #$02
        ldx #$08
        jsr Music_UpdateChannel
        ldy #$03
        ldx #$0C
        jsr Music_UpdateChannel
        rts

;----------------------------------------------------------------------
; Y = channel, X = channel*4 (APU register offset).
; mChanFlags bit 0 = track running, bit 1 = channel owns the APU
; (cleared while a sound effect uses the channel).
Music_UpdateChannel:
        sty zChan
        stx zRegOfs
        lda mChanFlags,y
        and #$01
        bne Music_TickNote
        rts

;----------------------------------------------------------------------
; Count down the note; read a new event when it reaches 0.
Music_TickNote:
        lda mNoteTimer,y
        sec
        sbc #$01
        beq Music_ReadEvent
        sta mNoteTimer,y
        jmp Music_VolEnvTick

;----------------------------------------------------------------------
; Read the next event. Bit 7 of byte 0 becomes bit 4 of the instrument.
Music_ReadEvent:
        lda mTrkPtrLo,y
        sta zPtr
        lda mTrkPtrHi,y
        sta zPtr+1
        lda mDurTabLo
        sta zDurTab
        lda mDurTabHi
        sta zDurTab+1
        ldy #$00
        lda (zPtr),y
        pha
        and #$80
        lsr a
        lsr a
        lsr a
        sta mInstTemp
        pla
        and #$7F
        cmp #$60
        bcc Music_Note
        jmp Music_Command

;----------------------------------------------------------------------
; Note: add the transpose, look up the period (unless a sound effect
; owns the channel).
Music_Note:
        ldx zChan
        adc mTranspose,x
        sta mNote,x
        tay
        lda mChanFlags,x
        and #$02
        beq Music_NoteSetInstrument
        lda PeriodHi,y
        cpy #$21
        bcc LD1BB
        lda #$00

LD1BB:
        sta mReg3,x
        lda PeriodLo,y
        sta mReg2,x
        lda mRegDirty,x
        ora #$03
        sta mRegDirty,x

;----------------------------------------------------------------------
; Note length from the duration table, advance 2 bytes, then load
; the instrument (bit 4 from byte 0, bits 0-3 from byte 1).
Music_NoteSetInstrument:
        ldy #$01
        lda (zPtr),y
        pha
        and #$0F
        tay
        lda (zDurTab),y
        ldy zChan
        sta mNoteTimer,y
        ldx zChan
        lda mTrkPtrLo,x
        clc
        adc #$02
        sta mTrkPtrLo,x
        lda mTrkPtrHi,x
        adc #$00
        sta mTrkPtrHi,x
        pla
        lsr a
        lsr a
        lsr a
        lsr a
        ora mInstTemp
        sta mInstTemp
        tay
        lda InstrumentLo,y
        sta zPtr
        lda InstrumentHi,y
        sta zPtr+1
        lda #$00
        sta mInstTemp
        ldx zChan
        lda mApuStatus
        ora ChanEnableBit,x
        sta mApuStatus
        ora APU_STATUS
        ldy #$00
        lda (zPtr),y
        sta mInstTemp
        cmp #$02
        bcs Music_InstNoVolEnv
        jmp Music_InstVolEnv

;----------------------------------------------------------------------
; Instrument flags >= 2: no volume envelope.
Music_InstNoVolEnv:
        ldx zChan
        iny
        iny
        iny
        lda #$00
        sta mReg0,x
        lda (zPtr),y
        sta mPitchEnvLo,x
        iny
        lda (zPtr),y
        sta mPitchEnvHi,x
        lda #$01
        sta mPitchEnvTimer,x
        iny
        lda (zPtr),y
        ora mReg0,x
        sta mReg0,x
        iny
        lda (zPtr),y
        ora mReg3,x
        sta mReg3,x
        lda mRegDirty,x
        ora #$05
        sta mRegDirty,x
        iny
        lda (zPtr),y
        iny
        lda (zPtr),y
        lda #$01
        jmp Music_VolEnvTick

;----------------------------------------------------------------------
; Instrument flags 0/1: start the volume envelope.
Music_InstVolEnv:
        iny
        lda (zPtr),y
        sta mVolEnvLo,x
        iny
        lda (zPtr),y
        sta mVolEnvHi,x
        lda #$01
        sta mVolEnvTimer,x
        lda #$00
        sta mReg0,x
        iny
        lda (zPtr),y
        sta mPitchEnvLo,x
        iny
        lda (zPtr),y
        sta mPitchEnvHi,x
        lda #$01
        sta mPitchEnvTimer,x
        iny
        lda (zPtr),y
        ora mReg0,x
        sta mReg0,x
        iny
        lda (zPtr),y
        ora mReg3,x
        sta mReg3,x
        lda mRegDirty,x
        ora #$05
        sta mRegDirty,x
        iny
        lda (zPtr),y
        iny
        lda (zPtr),y
        lda #$01

;----------------------------------------------------------------------
; Volume envelope: (volume, frames) pairs, $80 = stop.
Music_VolEnvTick:
        ldx zChan
        dec mVolEnvTimer,x
        bne Music_PitchEnvTick
        lda mVolEnvLo,x
        sta zPtr
        lda mVolEnvHi,x
        beq Music_PitchEnvTick
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        cmp #$80
        beq Music_PitchEnvTick
        lda mReg0,x
        and #$F0
        ora (zPtr),y
        sta mReg0,x
        lda mRegDirty,x
        ora #$04
        sta mRegDirty,x
        iny
        lda (zPtr),y
        sta mVolEnvTimer,x
        lda mVolEnvLo,x
        clc
        adc #$02
        sta mVolEnvLo,x
        lda mVolEnvHi,x
        adc #$00
        sta mVolEnvHi,x

;----------------------------------------------------------------------
; Pitch envelope: (delta, frames) pairs added to the low period byte,
; $80 lo hi = jump.
Music_PitchEnvTick:
        ldx zChan
        dec mPitchEnvTimer,x
        bne Music_Output
        lda mPitchEnvLo,x
        sta zPtr
        lda mPitchEnvHi,x
        beq Music_Output
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        sta zTemp
        beq LD333
        cmp #$80
        bne LD324
        iny
        lda (zPtr),y
        sta mPitchEnvLo,x
        iny
        lda (zPtr),y
        sta mPitchEnvHi,x
        lda #$01
        sta mPitchEnvTimer,x
        jmp Music_Output

LD324:
        clc
        adc mReg2,x
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

LD333:
        iny
        lda (zPtr),y
        sta mPitchEnvTimer,x
        lda mPitchEnvLo,x
        clc
        adc #$02
        sta mPitchEnvLo,x
        lda mPitchEnvHi,x
        adc #$00
        sta mPitchEnvHi,x

;----------------------------------------------------------------------
; Write the registers that changed, if this channel owns the APU.
Music_Output:
        ldx zChan
        ldy zRegOfs
        lda mChanFlags,x
        and #$02
        bne WriteChannelRegs
        rts

;----------------------------------------------------------------------
; Write the shadow registers to the APU, Y = register offset.
; mRegDirty bit 0 = reg3, bit 1 = reg2, bit 2 = reg0.
WriteChannelRegs:
        lda mRegDirty,x
        and #$01
        beq LD36B
        lda mReg3,x
        sta SQ1_HI,y
        lda mRegDirty,x
        and #$FE
        sta mRegDirty,x

LD36B:
        lda mRegDirty,x
        and #$02
        beq LD380
        lda mReg2,x
        sta SQ1_LO,y
        lda mRegDirty,x
        and #$FD
        sta mRegDirty,x

LD380:
        lda mRegDirty,x
        and #$04
        beq LD395
        lda mReg0,x
        sta SQ1_VOL,y
        lda mRegDirty,x
        and #$FB
        sta mRegDirty,x

LD395:
        rts

;
; Track command handlers, commands $60-$65 (6 entries, split low/high byte tables)
CmdHandlerHi:
        .hibytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .hibytes Cmd_Jump, Cmd_SetDurTable  ; 4-5

CmdHandlerLo:
        .lobytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .lobytes Cmd_Jump, Cmd_SetDurTable  ; 4-5

;----------------------------------------------------------------------
; Command byte $60+: jump through CmdHandlerLo/Hi.
Music_Command:
        ldx zChan
        sbc #$60
        tay
        lda CmdHandlerLo,y
        sta mCmdVector
        lda CmdHandlerHi,y
        sta mCmdVector+1
        jmp (mCmdVector)

;----------------------------------------------------------------------
; $60 CMD_REST len: volume 0 (if reg0 bit 4, constant volume, is set), wait.
Cmd_Rest:
        lda mReg0,x
        and #$10
        beq LD3CD
        lda mReg0,x
        and #$F0
        sta mReg0,x
        lda mRegDirty,x
        ora #$04
        sta mRegDirty,x

LD3CD:
        ldy #$01
        lda (zPtr),y
        and #$0F
        tay
        lda (zDurTab),y
        sta mNoteTimer,x
        ldy #$01
        jsr AdvanceTrackPtr
        jmp Music_Output

;----------------------------------------------------------------------
; $61 CMD_END: stop the track and silence the channel.
Cmd_End:
        lda mChanFlags,x
        and #$02
        sta mChanFlags,x
        sta mChanFlagsSave,x
        jsr SilenceChannel
        jmp Music_Output

;----------------------------------------------------------------------
; $62 CMD_CALL pattern, transpose, count
Cmd_Call:
        ldy #$01
        lda (zPtr),y
        tay
        lda PatternLo,y
        sta mTrkPtrLo,x
        lda PatternHi,y
        sta mTrkPtrHi,x
        ldy #$02
        lda (zPtr),y
        sta mTranspose,x
        lda mLoopActive,x
        bne LD416
        ldy #$03
        lda (zPtr),y
        sta mLoopCount,x

LD416:
        lda zPtr
        clc
        adc #$04
        sta mRetLo,x
        lda zPtr+1
        adc #$00
        sta mRetHi,x
        jmp Cmd_ReadNextNow

;----------------------------------------------------------------------
; $63 CMD_RETURN: go back to the CMD_CALL; repeat it while the count
; is not 0, otherwise continue after it with transpose 0.
Cmd_Return:
        lda mRetLo,x
        pha
        ldy mRetHi,x
        pla
        sta mTrkPtrLo,x
        tya
        sta mTrkPtrHi,x
        dec mLoopCount,x
        beq LD455
        lda #$01
        sta mLoopActive,x
        lda mTrkPtrLo,x
        sec
        sbc #$04
        sta mTrkPtrLo,x
        lda mTrkPtrHi,x
        sbc #$00
        sta mTrkPtrHi,x
        jmp Cmd_ReadNextNow

LD455:
        lda #$00
        sta mLoopActive,x
        sta mTranspose,x

;----------------------------------------------------------------------
; Timer = 1 and run the channel again so the next event is read in
; the same frame.
Cmd_ReadNextNow:
        lda #$01
        ldy zChan
        sta mNoteTimer,y
        ldx zRegOfs
        jmp Music_UpdateChannel

;----------------------------------------------------------------------
; $64 CMD_JUMP .word address
Cmd_Jump:
        ldy #$01
        lda (zPtr),y
        sta mTrkPtrLo,x
        iny
        lda (zPtr),y
        sta mTrkPtrHi,x
        lda #$01
        sta mNoteTimer,x
        ldy zChan
        ldx zRegOfs
        jmp Music_UpdateChannel

;----------------------------------------------------------------------
; $65 CMD_DURTABLE .word table (pointer shared by all channels).
Cmd_SetDurTable:
        ldy #$01
        lda (zPtr),y
        sta mDurTabLo
        iny
        lda (zPtr),y
        sta mDurTabHi
        ldx zChan
        lda #$01
        sta mNoteTimer,x

;----------------------------------------------------------------------
; Track pointer += Y + 1.
AdvanceTrackPtr:
        iny
        tya
        clc
        adc mTrkPtrLo,x
        sta mTrkPtrLo,x
        lda mTrkPtrHi,x
        adc #$00
        sta mTrkPtrHi,x
        ldy zChan
        ldx zRegOfs
        rts

;----------------------------------------------------------------------
; Volume 0, period 0, mark all registers dirty.
SilenceChannel:
        lda #$00
        sta mReg2,x
        sta mReg0,x
        lda mReg3,x
        and #$F8
        sta mReg3,x
        lda mRegDirty,x
        ora #$07
        sta mRegDirty,x
        rts

;
; Note period table, low bytes. Index 0 = C2 (65.4 Hz on a square channel).
PeriodLo:
        .byte $AE,$4E,$F3,$9E,$4D,$01,$B9,$75,$35,$F8,$BF,$89 ; octave 2
        .byte $57,$27,$F9,$CF,$A6,$80,$5C,$3A,$1A,$FC,$DF,$C4 ; octave 3
        .byte $AB,$93,$7C,$67,$53,$40,$2E,$1D,$0D,$FE,$EF,$E2 ; octave 4
        .byte $D5,$C9,$BE,$B3,$A9,$A0,$97,$8E,$86,$7F,$77,$71 ; octave 5
        .byte $6A,$64,$5F,$59,$54,$50,$4B,$47,$43,$3F,$3B,$38 ; octave 6
        .byte $35,$32,$2F,$2C,$2A,$28,$25,$23,$21,$1F,$1D,$1C ; octave 7
        .byte $1A,$19,$17,$16,$15,$14,$12,$11,$10,$00,$00,$00 ; octave 8
        .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; octave 9

; Note period table, high bytes (notes >= $21 use 0)
PeriodHi:
        .byte $06,$06,$05,$05,$05,$05,$04,$04,$04,$03,$03,$03 ; octave 2
        .byte $03,$03,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01 ; octave 3
        .byte $01,$01,$01,$01,$01,$01,$01,$01,$01 ; octave 4

;
; Instrument pointers (16 entries, split low/high byte tables)
InstrumentLo:
        .lobytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .lobytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .lobytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .lobytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15

InstrumentHi:
        .hibytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .hibytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .hibytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .hibytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15

Instrument_00:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D5ED                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_01:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D5F0                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_02:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D5FB                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_D656                   ; (read but ignored in this version)

Instrument_03:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $18                           ; reg0 bits (duty/const/halt): 18
        .byte $08                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_04:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $28                           ; reg0 bits (duty/const/halt): 28
        .byte $08                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_05:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $FF                           ; reg0 bits (duty/const/halt): FF
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_06:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D611                   ; volume envelope
        .word PitchEnv_D6AD                 ; pitch envelope
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_07:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D61C                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_D671                   ; (read but ignored in this version)

Instrument_08:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D61C                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_D680                   ; (read but ignored in this version)

Instrument_09:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D61C                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_D68F                   ; (read but ignored in this version)

Instrument_0A:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D61C                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_D69E                   ; (read but ignored in this version)

Instrument_0B:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D643                   ; volume envelope
        .word PitchEnv_D700                 ; pitch envelope
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_0C:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D648                   ; volume envelope
        .word PitchEnv_D6EC                 ; pitch envelope
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_0D:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_D64D                   ; volume envelope
        .word PitchEnv_D705                 ; pitch envelope
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

Instrument_0E:
Instrument_0F:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $00                           ; reg0 bits (duty/const/halt): 00
        .byte $01                           ; reg3 bits (length counter)
        .word $0000                         ; (read but ignored in this version)

VolEnv_D5ED:
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D5F0:
        .byte $04,$01                       ; volume 4 for 1 frame(s)
        .byte $03,$14                       ; volume 3 for 20 frame(s)
        .byte $02,$1E                       ; volume 2 for 30 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D5FB:
        .byte $03,$01                       ; volume 3 for 1 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

; (unreferenced volume envelope)
UnusedVolEnv_D604:
        .byte $04,$04                       ; volume 4 for 4 frame(s)
        .byte $03,$08                       ; volume 3 for 8 frame(s)
        .byte $02,$0C                       ; volume 2 for 12 frame(s)
        .byte $02,$18                       ; volume 2 for 24 frame(s)
        .byte $01,$18                       ; volume 1 for 24 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D611:
        .byte $04,$02                       ; volume 4 for 2 frame(s)
        .byte $03,$28                       ; volume 3 for 40 frame(s)
        .byte $02,$28                       ; volume 2 for 40 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $00,$00                       ; volume 0 for 256 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D61C:
        .byte $04,$0A                       ; volume 4 for 10 frame(s)
        .byte $03,$24                       ; volume 3 for 36 frame(s)
        .byte $02,$2E                       ; volume 2 for 46 frame(s)
        .byte $01,$2E                       ; volume 1 for 46 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

; (unreferenced volume envelope)
UnusedVolEnv_D627:
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $04,$0A                       ; volume 4 for 10 frame(s)
        .byte $05,$14                       ; volume 5 for 20 frame(s)
        .byte $04,$1E                       ; volume 4 for 30 frame(s)
        .byte $03,$1E                       ; volume 3 for 30 frame(s)
        .byte $02,$1E                       ; volume 2 for 30 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

; (unreferenced volume envelope)
UnusedVolEnv_D638:
        .byte $04,$02                       ; volume 4 for 2 frame(s)
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D643:
        .byte $08,$01                       ; volume 8 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D648:
        .byte $0F,$02                       ; volume 15 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_D64D:
        .byte $08,$01                       ; volume 8 for 1 frame(s)
        .byte $04,$02                       ; volume 4 for 2 frame(s)
        .byte $05,$02                       ; volume 5 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

; (arpeggio envelope format - ignored by this engine version)
ArpEnv_D656:
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $00,$01                       ; note +0 for 1 fr
        .byte $07,$01                       ; note +7 for 1 fr
        .byte $80                           ; jump
        .word ArpEnv_D656

; (arpeggio envelope format - ignored by this engine version)
ArpEnv_D671:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $0A,$02                       ; note +10 for 2 fr
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $0A,$02                       ; note +10 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_D671

; (arpeggio envelope format - ignored by this engine version)
ArpEnv_D680:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $09,$02                       ; note +9 for 2 fr
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $09,$02                       ; note +9 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_D680

; (arpeggio envelope format - ignored by this engine version)
ArpEnv_D68F:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $08,$02                       ; note +8 for 2 fr
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $08,$02                       ; note +8 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_D68F

; (arpeggio envelope format - ignored by this engine version)
ArpEnv_D69E:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $07,$02                       ; note +7 for 2 fr
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $07,$02                       ; note +7 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_D69E

PitchEnv_D6AD:
        .byte $FF,$02                       ; period -1, wait 2
        .byte $01,$02                       ; period +1, wait 2
        .byte $01,$02                       ; period +1, wait 2
        .byte $FF,$02                       ; period -1, wait 2
        .byte $80                           ; jump
        .word PitchEnv_D6AD

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_D6B8:
        .byte $0A,$02                       ; value +10 for 2 fr
        .byte $08,$02                       ; value +8 for 2 fr
        .byte $06,$02                       ; value +6 for 2 fr
        .byte $05,$02                       ; value +5 for 2 fr
        .byte $04,$64                       ; value +4 for 100 fr
        .byte $80                           ; jump
        .word UnusedEnv_D6B8

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_D6C5:
        .byte $0F,$04                       ; value +15 for 4 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$08                       ; value -1 for 8 fr
        .byte $FF,$50                       ; value -1 for 80 fr
        .byte $00,$50                       ; value +0 for 80 fr
        .byte $00,$50                       ; value +0 for 80 fr
        .byte $80                           ; jump
        .word UnusedEnv_D6C5

PitchEnv_D6EC:
        .byte $00,$FF                       ; wait 255
        .byte $80                           ; jump
        .word PitchEnv_D6EC

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_D6F1:
        .byte $08,$01                       ; value +8 for 1 fr
        .byte $08,$01                       ; value +8 for 1 fr
        .byte $08,$01                       ; value +8 for 1 fr
        .byte $08,$01                       ; value +8 for 1 fr
        .byte $08,$01                       ; value +8 for 1 fr
        .byte $02,$01                       ; value +2 for 1 fr
        .byte $80                           ; jump
        .word UnusedEnv_D6F1

PitchEnv_D700:
        .byte $01,$FF                       ; period +1, wait 255
        .byte $80                           ; jump
        .word PitchEnv_D700

PitchEnv_D705:
        .byte $0C,$01                       ; period +12, wait 1
        .byte $05,$01                       ; period +5, wait 1
        .byte $02,$01                       ; period +2, wait 1
        .byte $02,$01                       ; period +2, wait 1
        .byte $0A,$01                       ; period +10, wait 1
        .byte $02,$01                       ; period +2, wait 1
        .byte $0A,$01                       ; period +10, wait 1
        .byte $80                           ; jump
        .word PitchEnv_D705

;
; Song table: 5 songs x 5 pointers (Sq1, Sq2, Tri, Noise, duration table)
SongHi:
        .hibytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, DurTable_D758 ; song $00
        .hibytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, DurTable_D758 ; song $01
        .hibytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, DurTable_D758 ; song $02
        .hibytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, DurTable_D758 ; song $03
        .hibytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, DurTable_D758 ; song $04

SongLo:
        .lobytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, DurTable_D758 ; song $00
        .lobytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, DurTable_D758 ; song $01
        .lobytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, DurTable_D758 ; song $02
        .lobytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, DurTable_D758 ; song $03
        .lobytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, DurTable_D758 ; song $04

; (unreferenced duration table)
UnusedDurTable_D748:
        .byte $02,$03,$04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$05,$0B,$0A

DurTable_D758:
        .byte $03,$04,$06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$08,$10,$20 ; frames for len[0..15]

; (unreferenced duration table)
UnusedDurTable_D768:
        .byte $05,$07,$0A,$0F,$14,$1E,$28,$3C,$50,$78,$A0,$F0,$0D,$0E,$19,$06

; (unreferenced duration table)
UnusedDurTable_D778:
        .byte $04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$C0,$05,$06,$0A,$0B

; (unreferenced duration table)
UnusedDurTable_D788:
        .byte $06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$FF,$21,$08,$10,$20

;======================================================================
; Song $00
;======================================================================
Song00_Sq1:
        .byte CMD_CALL,$00,$EB,$01          ; Pattern_00, transpose -21, play 1x
        .byte CMD_CALL,$04,$EB,$01          ; Pattern_04, transpose -21, play 1x
        .byte CMD_JUMP
        .word Song00_Sq1

Song00_Sq2:
        .byte CMD_CALL,$01,$EB,$01          ; Pattern_01, transpose -21, play 1x
        .byte CMD_CALL,$05,$EB,$01          ; Pattern_05, transpose -21, play 1x
        .byte CMD_JUMP
        .word Song00_Sq2

Song00_Tri:
        .byte CMD_CALL,$02,$F7,$01          ; Pattern_02, transpose -9, play 1x
        .byte CMD_CALL,$06,$F7,$01          ; Pattern_06, transpose -9, play 1x
        .byte CMD_JUMP
        .word Song00_Tri

Song00_Noise:
        .byte CMD_CALL,$03,$00,$18          ; Pattern_03, transpose +0, play 24x
        .byte CMD_JUMP
        .word Song00_Noise

Pattern_00:
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$65                       ; C-7    ins  6  len[5] = 18 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $33,$64                       ; D#6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $35,$65                       ; F-6    ins  6  len[5] = 18 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $32,$69                       ; D-6    ins  6  len[9] = 72 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $30,$67                       ; C-6    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3A,$64                       ; A#6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $40,$69                       ; E-7    ins  6  len[9] = 72 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$65                       ; C-7    ins  6  len[5] = 18 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $33,$64                       ; D#6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $35,$65                       ; F-6    ins  6  len[5] = 18 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $32,$69                       ; D-6    ins  6  len[9] = 72 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $30,$67                       ; C-6    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_01:
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2C,$14                       ; G#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2C,$14                       ; G#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2E,$14                       ; A#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2E,$14                       ; A#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2C,$14                       ; G#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2C,$14                       ; G#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2E,$14                       ; A#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2E,$14                       ; A#5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_02:
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $28,$44                       ; E-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $28,$44                       ; E-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $28,$44                       ; E-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $28,$44                       ; E-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $2B,$44                       ; G-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_03:
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $54,$C2                       ; noise $54 ins 12  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte $56,$D2                       ; noise $56 ins 13  len[2] = 6 fr
        .byte $5A,$B2                       ; noise $5A ins 11  len[2] = 6 fr
        .byte CMD_RETURN

Pattern_04:
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$69                       ; C-7    ins  6  len[9] = 72 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $34,$69                       ; E-6    ins  6  len[9] = 72 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3A,$64                       ; A#6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_05:
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $30,$12                       ; C-6    ins  1  len[2] = 6 fr
        .byte $30,$12                       ; C-6    ins  1  len[2] = 6 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $30,$12                       ; C-6    ins  1  len[2] = 6 fr
        .byte $30,$12                       ; C-6    ins  1  len[2] = 6 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$14                       ; C-6    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_06:
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $29,$44                       ; F-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $2D,$42                       ; A-5    ins  4  len[2] = 6 fr
        .byte $2D,$42                       ; A-5    ins  4  len[2] = 6 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $2D,$42                       ; A-5    ins  4  len[2] = 6 fr
        .byte $2D,$42                       ; A-5    ins  4  len[2] = 6 fr
        .byte $2D,$44                       ; A-5    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $23,$44                       ; B-4    ins  4  len[4] = 12 fr
        .byte $33,$44                       ; D#6    ins  4  len[4] = 12 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $33,$44                       ; D#6    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $2C,$44                       ; G#5    ins  4  len[4] = 12 fr
        .byte CMD_RETURN

;======================================================================
; Song $01
;======================================================================
Song01_Sq1:
        .byte CMD_CALL,$07,$EB,$01          ; Pattern_07, transpose -21, play 1x
        .byte CMD_CALL,$08,$EB,$01          ; Pattern_08, transpose -21, play 1x
        .byte CMD_JUMP
        .word Song01_Sq1

Song01_Sq2:
        .byte CMD_CALL,$09,$EB,$01          ; Pattern_09, transpose -21, play 1x
        .byte CMD_CALL,$0A,$EB,$01          ; Pattern_0A, transpose -21, play 1x
        .byte CMD_JUMP
        .word Song01_Sq2

Song01_Tri:
        .byte CMD_CALL,$0B,$F7,$01          ; Pattern_0B, transpose -9, play 1x
        .byte CMD_JUMP
        .word Song01_Tri

Song01_Noise:
        .byte CMD_CALL,$0C,$00,$03          ; Pattern_0C, transpose +0, play 3x
        .byte CMD_CALL,$0E,$00,$08          ; Pattern_0E, transpose +0, play 8x
        .byte CMD_CALL,$0C,$00,$02          ; Pattern_0C, transpose +0, play 2x
        .byte CMD_CALL,$0D,$00,$01          ; Pattern_0D, transpose +0, play 1x
        .byte CMD_CALL,$0C,$00,$03          ; Pattern_0C, transpose +0, play 3x
        .byte CMD_CALL,$0E,$00,$08          ; Pattern_0E, transpose +0, play 8x
        .byte CMD_CALL,$0C,$00,$02          ; Pattern_0C, transpose +0, play 2x
        .byte CMD_CALL,$0D,$00,$01          ; Pattern_0D, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song01_Noise

Pattern_07:
        .byte $45,$68                       ; A-7    ins  6  len[8] = 48 fr
        .byte $30,$08                       ; C-6    ins  0  len[8] = 48 fr
        .byte $39,$68                       ; A-6    ins  6  len[8] = 48 fr
        .byte $30,$08                       ; C-6    ins  0  len[8] = 48 fr
        .byte $45,$68                       ; A-7    ins  6  len[8] = 48 fr
        .byte $30,$08                       ; C-6    ins  0  len[8] = 48 fr
        .byte $39,$68                       ; A-6    ins  6  len[8] = 48 fr
        .byte $30,$08                       ; C-6    ins  0  len[8] = 48 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$67                       ; E-7    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$63                       ; A-6    ins  6  len[3] = 9 fr
        .byte $38,$60                       ; G#6    ins  6  len[0] = 3 fr
        .byte $37,$60                       ; G-6    ins  6  len[0] = 3 fr
        .byte $36,$60                       ; F#6    ins  6  len[0] = 3 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$67                       ; E-7    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$63                       ; A-6    ins  6  len[3] = 9 fr
        .byte $38,$60                       ; G#6    ins  6  len[0] = 3 fr
        .byte $37,$60                       ; G-6    ins  6  len[0] = 3 fr
        .byte $36,$60                       ; F#6    ins  6  len[0] = 3 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$68                       ; D-7    ins  6  len[8] = 48 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$67                       ; F-7    ins  6  len[7] = 36 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $33,$6A                       ; D#6    ins  6  len[10] = 96 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $3C,$68                       ; C-7    ins  6  len[8] = 48 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $33,$6A                       ; D#6    ins  6  len[10] = 96 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $39,$68                       ; A-6    ins  6  len[8] = 48 fr
        .byte $3E,$6A                       ; D-7    ins  6  len[10] = 96 fr
        .byte $3B,$68                       ; B-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $36,$62                       ; F#6    ins  6  len[2] = 6 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $38,$6A                       ; G#6    ins  6  len[10] = 96 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$65                       ; D-7    ins  6  len[5] = 18 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $38,$6A                       ; G#6    ins  6  len[10] = 96 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$65                       ; D-7    ins  6  len[5] = 18 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $40,$61                       ; E-7    ins  6  len[1] = 4 fr
        .byte $42,$61                       ; F#7    ins  6  len[1] = 4 fr
        .byte $44,$61                       ; G#7    ins  6  len[1] = 4 fr
        .byte CMD_RETURN

Pattern_09:
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $3B,$68                       ; B-6    ins  6  len[8] = 48 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $36,$64                       ; F#6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $37,$66                       ; G-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$67                       ; D-7    ins  6  len[7] = 36 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$6A                       ; C-6    ins  6  len[10] = 96 fr
        .byte $2F,$6A                       ; B-5    ins  6  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $37,$66                       ; G-6    ins  6  len[6] = 24 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$68                       ; F-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $33,$66                       ; D#6    ins  6  len[6] = 24 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2C,$66                       ; G#5    ins  6  len[6] = 24 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte $29,$62                       ; F-5    ins  6  len[2] = 6 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2C,$62                       ; G#5    ins  6  len[2] = 6 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $37,$66                       ; G-6    ins  6  len[6] = 24 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$68                       ; F-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $33,$66                       ; D#6    ins  6  len[6] = 24 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2C,$66                       ; G#5    ins  6  len[6] = 24 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte $29,$62                       ; F-5    ins  6  len[2] = 6 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2C,$62                       ; G#5    ins  6  len[2] = 6 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_0B:
        .byte $21,$48                       ; A-4    ins  4  len[8] = 48 fr
        .byte $30,$F8                       ; C-6    ins 15  len[8] = 48 fr
        .byte $15,$48                       ; A-3    ins  4  len[8] = 48 fr
        .byte $30,$F8                       ; C-6    ins 15  len[8] = 48 fr
        .byte $21,$48                       ; A-4    ins  4  len[8] = 48 fr
        .byte $30,$F8                       ; C-6    ins 15  len[8] = 48 fr
        .byte $15,$48                       ; A-3    ins  4  len[8] = 48 fr
        .byte $30,$F8                       ; C-6    ins 15  len[8] = 48 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $23,$42                       ; B-4    ins  4  len[2] = 6 fr
        .byte $21,$42                       ; A-4    ins  4  len[2] = 6 fr
        .byte $1F,$44                       ; G-4    ins  4  len[4] = 12 fr
        .byte $21,$42                       ; A-4    ins  4  len[2] = 6 fr
        .byte $1F,$42                       ; G-4    ins  4  len[2] = 6 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $18,$46                       ; C-4    ins  4  len[6] = 24 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $23,$44                       ; B-4    ins  4  len[4] = 12 fr
        .byte $24,$42                       ; C-5    ins  4  len[2] = 6 fr
        .byte $26,$42                       ; D-5    ins  4  len[2] = 6 fr
        .byte $24,$44                       ; C-5    ins  4  len[4] = 12 fr
        .byte $23,$42                       ; B-4    ins  4  len[2] = 6 fr
        .byte $24,$42                       ; C-5    ins  4  len[2] = 6 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $23,$42                       ; B-4    ins  4  len[2] = 6 fr
        .byte $21,$42                       ; A-4    ins  4  len[2] = 6 fr
        .byte $1F,$44                       ; G-4    ins  4  len[4] = 12 fr
        .byte $21,$42                       ; A-4    ins  4  len[2] = 6 fr
        .byte $1F,$42                       ; G-4    ins  4  len[2] = 6 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $18,$46                       ; C-4    ins  4  len[6] = 24 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $23,$44                       ; B-4    ins  4  len[4] = 12 fr
        .byte $24,$42                       ; C-5    ins  4  len[2] = 6 fr
        .byte $26,$42                       ; D-5    ins  4  len[2] = 6 fr
        .byte $24,$44                       ; C-5    ins  4  len[4] = 12 fr
        .byte $23,$42                       ; B-4    ins  4  len[2] = 6 fr
        .byte $24,$42                       ; C-5    ins  4  len[2] = 6 fr
        .byte $1D,$48                       ; F-4    ins  4  len[8] = 48 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $23,$46                       ; B-4    ins  4  len[6] = 24 fr
        .byte $24,$44                       ; C-5    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $20,$46                       ; G#4    ins  4  len[6] = 24 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $23,$44                       ; B-4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1F,$46                       ; G-4    ins  4  len[6] = 24 fr
        .byte $1D,$46                       ; F-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1A,$48                       ; D-4    ins  4  len[8] = 48 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1F,$46                       ; G-4    ins  4  len[6] = 24 fr
        .byte $1D,$46                       ; F-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1B,$47                       ; D#4    ins  4  len[7] = 36 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $1B,$44                       ; D#4    ins  4  len[4] = 12 fr
        .byte $1B,$46                       ; D#4    ins  4  len[6] = 24 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1F,$46                       ; G-4    ins  4  len[6] = 24 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $14,$44                       ; G#3    ins  4  len[4] = 12 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $20,$46                       ; G#4    ins  4  len[6] = 24 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $14,$44                       ; G#3    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $15,$44                       ; A-3    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1F,$44                       ; G-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1A,$44                       ; D-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $23,$44                       ; B-4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $24,$46                       ; C-5    ins  4  len[6] = 24 fr
        .byte $23,$46                       ; B-4    ins  4  len[6] = 24 fr
        .byte $21,$47                       ; A-4    ins  4  len[7] = 36 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $21,$49                       ; A-4    ins  4  len[9] = 72 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1F,$46                       ; G-4    ins  4  len[6] = 24 fr
        .byte $1D,$47                       ; F-4    ins  4  len[7] = 36 fr
        .byte $18,$46                       ; C-4    ins  4  len[6] = 24 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $1D,$49                       ; F-4    ins  4  len[9] = 72 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1D,$46                       ; F-4    ins  4  len[6] = 24 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $17,$46                       ; B-3    ins  4  len[6] = 24 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $1C,$49                       ; E-4    ins  4  len[9] = 72 fr
        .byte $1E,$46                       ; F#4    ins  4  len[6] = 24 fr
        .byte $20,$46                       ; G#4    ins  4  len[6] = 24 fr
        .byte $21,$47                       ; A-4    ins  4  len[7] = 36 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1E,$46                       ; F#4    ins  4  len[6] = 24 fr
        .byte $20,$46                       ; G#4    ins  4  len[6] = 24 fr
        .byte $21,$47                       ; A-4    ins  4  len[7] = 36 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $21,$47                       ; A-4    ins  4  len[7] = 36 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1F,$44                       ; G-4    ins  4  len[4] = 12 fr
        .byte $1F,$44                       ; G-4    ins  4  len[4] = 12 fr
        .byte $1D,$47                       ; F-4    ins  4  len[7] = 36 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $18,$47                       ; C-4    ins  4  len[7] = 36 fr
        .byte $18,$44                       ; C-4    ins  4  len[4] = 12 fr
        .byte $1D,$47                       ; F-4    ins  4  len[7] = 36 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $21,$44                       ; A-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1D,$44                       ; F-4    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $17,$47                       ; B-3    ins  4  len[7] = 36 fr
        .byte $17,$44                       ; B-3    ins  4  len[4] = 12 fr
        .byte $1C,$47                       ; E-4    ins  4  len[7] = 36 fr
        .byte $1C,$44                       ; E-4    ins  4  len[4] = 12 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $1E,$44                       ; F#4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $20,$44                       ; G#4    ins  4  len[4] = 12 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $21,$46                       ; A-4    ins  4  len[6] = 24 fr
        .byte $1C,$46                       ; E-4    ins  4  len[6] = 24 fr
        .byte $1E,$46                       ; F#4    ins  4  len[6] = 24 fr
        .byte $20,$46                       ; G#4    ins  4  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_0C:
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0D:
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B6                       ; noise $54 ins 11  len[6] = 24 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B2                       ; noise $54 ins 11  len[2] = 6 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0E:
        .byte $30,$0A                       ; noise $30 ins  0  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_08:
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $30,$07                       ; C-6    ins  0  len[7] = 36 fr
        .byte $30,$08                       ; C-6    ins  0  len[8] = 48 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$67                       ; E-7    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$63                       ; A-6    ins  6  len[3] = 9 fr
        .byte $38,$60                       ; G#6    ins  6  len[0] = 3 fr
        .byte $37,$60                       ; G-6    ins  6  len[0] = 3 fr
        .byte $36,$60                       ; F#6    ins  6  len[0] = 3 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$67                       ; E-7    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$63                       ; A-6    ins  6  len[3] = 9 fr
        .byte $38,$60                       ; G#6    ins  6  len[0] = 3 fr
        .byte $37,$60                       ; G-6    ins  6  len[0] = 3 fr
        .byte $36,$60                       ; F#6    ins  6  len[0] = 3 fr
        .byte $35,$67                       ; F-6    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$68                       ; D-7    ins  6  len[8] = 48 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$67                       ; F-7    ins  6  len[7] = 36 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $33,$6A                       ; D#6    ins  6  len[10] = 96 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $3C,$68                       ; C-7    ins  6  len[8] = 48 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $33,$6A                       ; D#6    ins  6  len[10] = 96 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $36,$62                       ; F#6    ins  6  len[2] = 6 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $39,$68                       ; A-6    ins  6  len[8] = 48 fr
        .byte $3E,$6A                       ; D-7    ins  6  len[10] = 96 fr
        .byte $3B,$68                       ; B-6    ins  6  len[8] = 48 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $36,$62                       ; F#6    ins  6  len[2] = 6 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $38,$6A                       ; G#6    ins  6  len[10] = 96 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$65                       ; D-7    ins  6  len[5] = 18 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $30,$06                       ; C-6    ins  0  len[6] = 24 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $38,$6A                       ; G#6    ins  6  len[10] = 96 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$65                       ; D-7    ins  6  len[5] = 18 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_0A:
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $30,$0A                       ; C-6    ins  0  len[10] = 96 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $44,$64                       ; G#7    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $44,$62                       ; G#7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $44,$62                       ; G#7    ins  6  len[2] = 6 fr
        .byte $45,$67                       ; A-7    ins  6  len[7] = 36 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $47,$64                       ; B-7    ins  6  len[4] = 12 fr
        .byte $48,$66                       ; C-8    ins  6  len[6] = 24 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $44,$64                       ; G#7    ins  6  len[4] = 12 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 3 fr
        .byte $40,$60                       ; E-7    ins  6  len[0] = 3 fr
        .byte $3F,$60                       ; D#7    ins  6  len[0] = 3 fr
        .byte $3E,$60                       ; D-7    ins  6  len[0] = 3 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $47,$64                       ; B-7    ins  6  len[4] = 12 fr
        .byte $48,$62                       ; C-8    ins  6  len[2] = 6 fr
        .byte $4A,$62                       ; D-8    ins  6  len[2] = 6 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $48,$62                       ; C-8    ins  6  len[2] = 6 fr
        .byte $45,$62                       ; A-7    ins  6  len[2] = 6 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $45,$62                       ; A-7    ins  6  len[2] = 6 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $44,$62                       ; G#7    ins  6  len[2] = 6 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $45,$62                       ; A-7    ins  6  len[2] = 6 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $44,$64                       ; G#7    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $44,$62                       ; G#7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $40,$62                       ; E-7    ins  6  len[2] = 6 fr
        .byte $44,$62                       ; G#7    ins  6  len[2] = 6 fr
        .byte $45,$67                       ; A-7    ins  6  len[7] = 36 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $47,$64                       ; B-7    ins  6  len[4] = 12 fr
        .byte $48,$66                       ; C-8    ins  6  len[6] = 24 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $44,$64                       ; G#7    ins  6  len[4] = 12 fr
        .byte $41,$62                       ; F-7    ins  6  len[2] = 6 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 3 fr
        .byte $40,$60                       ; E-7    ins  6  len[0] = 3 fr
        .byte $3F,$60                       ; D#7    ins  6  len[0] = 3 fr
        .byte $3E,$60                       ; D-7    ins  6  len[0] = 3 fr
        .byte $3C,$67                       ; C-7    ins  6  len[7] = 36 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $41,$64                       ; F-7    ins  6  len[4] = 12 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $47,$64                       ; B-7    ins  6  len[4] = 12 fr
        .byte $48,$62                       ; C-8    ins  6  len[2] = 6 fr
        .byte $4A,$62                       ; D-8    ins  6  len[2] = 6 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $48,$62                       ; C-8    ins  6  len[2] = 6 fr
        .byte $45,$62                       ; A-7    ins  6  len[2] = 6 fr
        .byte $30,$02                       ; C-6    ins  0  len[2] = 6 fr
        .byte $45,$62                       ; A-7    ins  6  len[2] = 6 fr
        .byte $47,$62                       ; B-7    ins  6  len[2] = 6 fr
        .byte $44,$64                       ; G#7    ins  6  len[4] = 12 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3B,$68                       ; B-6    ins  6  len[8] = 48 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $36,$64                       ; F#6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $37,$66                       ; G-6    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$67                       ; D-7    ins  6  len[7] = 36 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $39,$66                       ; A-6    ins  6  len[6] = 24 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$6A                       ; C-6    ins  6  len[10] = 96 fr
        .byte $2F,$6A                       ; B-5    ins  6  len[10] = 96 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $34,$62                       ; E-6    ins  6  len[2] = 6 fr
        .byte $32,$62                       ; D-6    ins  6  len[2] = 6 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$66                       ; C-7    ins  6  len[6] = 24 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3F,$62                       ; D#7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $38,$66                       ; G#6    ins  6  len[6] = 24 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $39,$64                       ; A-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $38,$62                       ; G#6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3C,$64                       ; C-7    ins  6  len[4] = 12 fr
        .byte $43,$64                       ; G-7    ins  6  len[4] = 12 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $41,$69                       ; F-7    ins  6  len[9] = 72 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$62                       ; D-7    ins  6  len[2] = 6 fr
        .byte $3C,$62                       ; C-7    ins  6  len[2] = 6 fr
        .byte $3B,$62                       ; B-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$68                       ; F-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $33,$66                       ; D#6    ins  6  len[6] = 24 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2C,$66                       ; G#5    ins  6  len[6] = 24 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte $29,$62                       ; F-5    ins  6  len[2] = 6 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2C,$62                       ; G#5    ins  6  len[2] = 6 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $38,$64                       ; G#6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $34,$66                       ; E-6    ins  6  len[6] = 24 fr
        .byte $39,$67                       ; A-6    ins  6  len[7] = 36 fr
        .byte $37,$64                       ; G-6    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $34,$64                       ; E-6    ins  6  len[4] = 12 fr
        .byte $35,$68                       ; F-6    ins  6  len[8] = 48 fr
        .byte $2D,$66                       ; A-5    ins  6  len[6] = 24 fr
        .byte $30,$66                       ; C-6    ins  6  len[6] = 24 fr
        .byte $33,$66                       ; D#6    ins  6  len[6] = 24 fr
        .byte $38,$67                       ; G#6    ins  6  len[7] = 36 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $35,$64                       ; F-6    ins  6  len[4] = 12 fr
        .byte $34,$68                       ; E-6    ins  6  len[8] = 48 fr
        .byte $2C,$66                       ; G#5    ins  6  len[6] = 24 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte $32,$66                       ; D-6    ins  6  len[6] = 24 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2F,$64                       ; B-5    ins  6  len[4] = 12 fr
        .byte $2D,$62                       ; A-5    ins  6  len[2] = 6 fr
        .byte $30,$05                       ; C-6    ins  0  len[5] = 18 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte $29,$62                       ; F-5    ins  6  len[2] = 6 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2C,$62                       ; G#5    ins  6  len[2] = 6 fr
        .byte $2D,$64                       ; A-5    ins  6  len[4] = 12 fr
        .byte $30,$04                       ; C-6    ins  0  len[4] = 12 fr
        .byte $2F,$66                       ; B-5    ins  6  len[6] = 24 fr
        .byte CMD_RETURN

;======================================================================
; Song $02
;======================================================================
Song02_Sq1:
        .byte CMD_CALL,$0F,$E3,$01          ; Pattern_0F, transpose -29, play 1x
        .byte CMD_CALL,$10,$E3,$01          ; Pattern_10, transpose -29, play 1x
        .byte CMD_CALL,$11,$E3,$01          ; Pattern_11, transpose -29, play 1x
        .byte CMD_JUMP
        .word Song02_Sq1

Song02_Sq2:
        .byte CMD_CALL,$12,$E3,$02          ; Pattern_12, transpose -29, play 2x
        .byte CMD_CALL,$13,$E3,$02          ; Pattern_13, transpose -29, play 2x
        .byte CMD_JUMP
        .word Song02_Sq2

Song02_Tri:
        .byte CMD_CALL,$14,$FB,$02          ; Pattern_14, transpose -5, play 2x
        .byte CMD_CALL,$15,$FB,$02          ; Pattern_15, transpose -5, play 2x
        .byte CMD_JUMP
        .word Song02_Tri

Song02_Noise:
        .byte CMD_CALL,$16,$00,$09          ; Pattern_16, transpose +0, play 9x
        .byte CMD_JUMP
        .word Song02_Noise

Pattern_0F:
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $42,$68                       ; F#7    ins  6  len[8] = 48 fr
        .byte $40,$68                       ; E-7    ins  6  len[8] = 48 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3F,$64                       ; D#7    ins  6  len[4] = 12 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3D,$66                       ; C#7    ins  6  len[6] = 24 fr
        .byte $40,$67                       ; E-7    ins  6  len[7] = 36 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $3D,$66                       ; C#7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $3B,$68                       ; B-6    ins  6  len[8] = 48 fr
        .byte $3B,$64                       ; B-6    ins  6  len[4] = 12 fr
        .byte $3D,$66                       ; C#7    ins  6  len[6] = 24 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_10:
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $39,$6A                       ; A-6    ins  6  len[10] = 96 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $42,$68                       ; F#7    ins  6  len[8] = 48 fr
        .byte $40,$68                       ; E-7    ins  6  len[8] = 48 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3F,$64                       ; D#7    ins  6  len[4] = 12 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$64                       ; E-7    ins  6  len[4] = 12 fr
        .byte $3D,$66                       ; C#7    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $3D,$66                       ; C#7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $3B,$66                       ; B-6    ins  6  len[6] = 24 fr
        .byte $3D,$64                       ; C#7    ins  6  len[4] = 12 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $3B,$67                       ; B-6    ins  6  len[7] = 36 fr
        .byte $42,$67                       ; F#7    ins  6  len[7] = 36 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $47,$66                       ; B-7    ins  6  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_12:
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $34,$14                       ; E-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $34,$14                       ; E-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_14:
        .byte $1A,$59                       ; D-4    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $15,$54                       ; A-3    ins  5  len[4] = 12 fr
        .byte $1A,$59                       ; D-4    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $15,$54                       ; A-3    ins  5  len[4] = 12 fr
        .byte $1A,$59                       ; D-4    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $13,$58                       ; G-3    ins  5  len[8] = 48 fr
        .byte $15,$58                       ; A-3    ins  5  len[8] = 48 fr
        .byte $10,$59                       ; E-3    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $10,$54                       ; E-3    ins  5  len[4] = 12 fr
        .byte $17,$59                       ; B-3    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $17,$54                       ; B-3    ins  5  len[4] = 12 fr
        .byte $13,$59                       ; G-3    ins  5  len[9] = 72 fr
        .byte $30,$F4                       ; C-6    ins 15  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $15,$59                       ; A-3    ins  5  len[9] = 72 fr
        .byte $19,$56                       ; C#4    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_16:
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte $54,$B4                       ; noise $54 ins 11  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_11:
        .byte $45,$6A                       ; A-7    ins  6  len[10] = 96 fr
        .byte $30,$07                       ; C-6    ins  0  len[7] = 36 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $47,$66                       ; B-7    ins  6  len[6] = 24 fr
        .byte $45,$66                       ; A-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$68                       ; D-7    ins  6  len[8] = 48 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $49,$66                       ; C#8    ins  6  len[6] = 24 fr
        .byte $47,$64                       ; B-7    ins  6  len[4] = 12 fr
        .byte $45,$68                       ; A-7    ins  6  len[8] = 48 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $49,$66                       ; C#8    ins  6  len[6] = 24 fr
        .byte $4A,$64                       ; D-8    ins  6  len[4] = 12 fr
        .byte $45,$68                       ; A-7    ins  6  len[8] = 48 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $45,$67                       ; A-7    ins  6  len[7] = 36 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $47,$66                       ; B-7    ins  6  len[6] = 24 fr
        .byte $45,$6A                       ; A-7    ins  6  len[10] = 96 fr
        .byte $30,$07                       ; C-6    ins  0  len[7] = 36 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $47,$66                       ; B-7    ins  6  len[6] = 24 fr
        .byte $45,$66                       ; A-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $42,$68                       ; F#7    ins  6  len[8] = 48 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $45,$64                       ; A-7    ins  6  len[4] = 12 fr
        .byte $49,$66                       ; C#8    ins  6  len[6] = 24 fr
        .byte $4A,$66                       ; D-8    ins  6  len[6] = 24 fr
        .byte $45,$67                       ; A-7    ins  6  len[7] = 36 fr
        .byte $3E,$64                       ; D-7    ins  6  len[4] = 12 fr
        .byte $49,$66                       ; C#8    ins  6  len[6] = 24 fr
        .byte $4A,$64                       ; D-8    ins  6  len[4] = 12 fr
        .byte $45,$68                       ; A-7    ins  6  len[8] = 48 fr
        .byte $42,$64                       ; F#7    ins  6  len[4] = 12 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte $43,$66                       ; G-7    ins  6  len[6] = 24 fr
        .byte $42,$66                       ; F#7    ins  6  len[6] = 24 fr
        .byte $3E,$66                       ; D-7    ins  6  len[6] = 24 fr
        .byte $40,$66                       ; E-7    ins  6  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_13:
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $34,$14                       ; E-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $34,$14                       ; E-6    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $32,$14                       ; D-6    ins  1  len[4] = 12 fr
        .byte $2A,$14                       ; F#5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $2F,$14                       ; B-5    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2B,$14                       ; G-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte $2D,$14                       ; A-5    ins  1  len[4] = 12 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $28,$14                       ; E-5    ins  1  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_15:
        .byte $1A,$5A                       ; D-4    ins  5  len[10] = 96 fr
        .byte $1A,$58                       ; D-4    ins  5  len[8] = 48 fr
        .byte $1C,$58                       ; E-4    ins  5  len[8] = 48 fr
        .byte $1E,$58                       ; F#4    ins  5  len[8] = 48 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 48 fr
        .byte $17,$5A                       ; B-3    ins  5  len[10] = 96 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 48 fr
        .byte $1E,$58                       ; F#4    ins  5  len[8] = 48 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 48 fr
        .byte $1E,$58                       ; F#4    ins  5  len[8] = 48 fr
        .byte $1C,$5A                       ; E-4    ins  5  len[10] = 96 fr
        .byte $15,$5A                       ; A-3    ins  5  len[10] = 96 fr
        .byte CMD_RETURN

;======================================================================
; Song $03
;======================================================================
Song03_Sq1:
        .byte $24,$0A                       ; C-5    ins  0  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song03_Sq1

Song03_Sq2:
        .byte $24,$0A                       ; C-5    ins  0  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song03_Sq2

Song03_Tri:
        .byte $24,$FA                       ; C-5    ins 15  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song03_Tri

Song03_Noise:
        .byte $24,$0A                       ; noise $24 ins  0  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song03_Noise

;======================================================================
; Song $04
;======================================================================
Song04_Sq1:
        .byte CMD_CALL,$17,$F4,$01          ; Pattern_17, transpose -12, play 1x
        .byte CMD_END

Song04_Sq2:
        .byte CMD_CALL,$18,$E8,$01          ; Pattern_18, transpose -24, play 1x
        .byte CMD_END

Song04_Tri:
        .byte CMD_CALL,$19,$F4,$01          ; Pattern_19, transpose -12, play 1x
        .byte CMD_END

Song04_Noise:
        .byte CMD_END

Pattern_17:
        .byte $2E,$64                       ; A#5    ins  6  len[4] = 12 fr
        .byte $2E,$64                       ; A#5    ins  6  len[4] = 12 fr
        .byte $35,$66                       ; F-6    ins  6  len[6] = 24 fr
        .byte $33,$62                       ; D#6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $33,$64                       ; D#6    ins  6  len[4] = 12 fr
        .byte $31,$65                       ; C#6    ins  6  len[5] = 18 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $31,$62                       ; C#6    ins  6  len[2] = 6 fr
        .byte $30,$64                       ; C-6    ins  6  len[4] = 12 fr
        .byte $2E,$64                       ; A#5    ins  6  len[4] = 12 fr
        .byte $30,$62                       ; C-6    ins  6  len[2] = 6 fr
        .byte $31,$62                       ; C#6    ins  6  len[2] = 6 fr
        .byte $33,$62                       ; D#6    ins  6  len[2] = 6 fr
        .byte $35,$62                       ; F-6    ins  6  len[2] = 6 fr
        .byte $37,$62                       ; G-6    ins  6  len[2] = 6 fr
        .byte $39,$62                       ; A-6    ins  6  len[2] = 6 fr
        .byte $3A,$66                       ; A#6    ins  6  len[6] = 24 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 3 fr
        .byte CMD_RETURN

Pattern_18:
        .byte $30,$07                       ; C-6    ins  0  len[7] = 36 fr
        .byte $31,$16                       ; C#6    ins  1  len[6] = 24 fr
        .byte $31,$16                       ; C#6    ins  1  len[6] = 24 fr
        .byte $31,$16                       ; C#6    ins  1  len[6] = 24 fr
        .byte $30,$16                       ; C-6    ins  1  len[6] = 24 fr
        .byte $31,$16                       ; C#6    ins  1  len[6] = 24 fr
        .byte $30,$16                       ; C-6    ins  1  len[6] = 24 fr
        .byte $31,$14                       ; C#6    ins  1  len[4] = 12 fr
        .byte $31,$16                       ; C#6    ins  1  len[6] = 24 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 3 fr
        .byte CMD_RETURN

Pattern_19:
        .byte $30,$F6                       ; C-6    ins 15  len[6] = 24 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $2E,$54                       ; A#5    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $2E,$54                       ; A#5    ins  5  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $2E,$54                       ; A#5    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $2E,$54                       ; A#5    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $2E,$54                       ; A#5    ins  5  len[4] = 12 fr
        .byte $2E,$56                       ; A#5    ins  5  len[6] = 24 fr
        .byte $30,$F0                       ; C-6    ins 15  len[0] = 3 fr
        .byte CMD_RETURN

;
; Pattern (subroutine) pointers, used by CMD_CALL (26 entries, split low/high byte tables)
PatternLo:
        .lobytes Pattern_00, Pattern_01, Pattern_02, Pattern_03 ; 0-3
        .lobytes Pattern_04, Pattern_05, Pattern_06, Pattern_07 ; 4-7
        .lobytes Pattern_08, Pattern_09, Pattern_0A, Pattern_0B ; 8-11
        .lobytes Pattern_0C, Pattern_0D, Pattern_0E, Pattern_0F ; 12-15
        .lobytes Pattern_10, Pattern_11, Pattern_12, Pattern_13 ; 16-19
        .lobytes Pattern_14, Pattern_15, Pattern_16, Pattern_17 ; 20-23
        .lobytes Pattern_18, Pattern_19     ; 24-25

PatternHi:
        .hibytes Pattern_00, Pattern_01, Pattern_02, Pattern_03 ; 0-3
        .hibytes Pattern_04, Pattern_05, Pattern_06, Pattern_07 ; 4-7
        .hibytes Pattern_08, Pattern_09, Pattern_0A, Pattern_0B ; 8-11
        .hibytes Pattern_0C, Pattern_0D, Pattern_0E, Pattern_0F ; 12-15
        .hibytes Pattern_10, Pattern_11, Pattern_12, Pattern_13 ; 16-19
        .hibytes Pattern_14, Pattern_15, Pattern_16, Pattern_17 ; 20-23
        .hibytes Pattern_18, Pattern_19     ; 24-25

ChanRegOfs:
        .byte $00,$04,$08,$0C               ; APU register offset per channel

ChanEnableBit:
        .byte $01,$02,$04,$08,$10           ; APU_STATUS bit per channel

ChanDisableMask:
        .byte $FE,$FD,$FB,$F7,$EF           ; APU_STATUS mask per channel

;----------------------------------------------------------------------
; Clear all sound effect state.
Sfx_Init:
        lda #$00
        sta sPtrHi
        sta sPtrLo
        sta sPtrHi+1
        sta sPtrLo+1
        sta sPtrHi+2
        sta sPtrLo+2
        sta sPtrHi+3
        sta sPtrLo+3
        sta sPriority
        sta sPriority+1
        sta sPriority+2
        sta sPriority+3
        sta mApuStatus
        rts

;----------------------------------------------------------------------
; A = priority, X = effect number. Effects with a lower priority than
; the one playing on the same channel are ignored.
Sfx_Play:
        sta sNewPriority
        txa
        pha
        lda #$08
        sta SQ1_SWEEP
        sta SQ2_SWEEP
        lda SfxLo,x
        sta zPtr
        lda SfxHi,x
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        cmp #$04
        bcs LE9F7
        tax
        lda sNewPriority
        cmp sPriority,x
        bcs LE9A0
        pla
        rts

LE9A0:
        sta sPriority,x
        pla
        sta sId,x
        lda mApuStatus
        ora ChanEnableBit,x
        sta APU_STATUS
        sta mApuStatus
        lda mChanFlags,x
        and #$FD
        sta mChanFlags,x
        iny
        lda (zPtr),y
        sta sSpeed,x
        sta sTimer,x
        iny
        lda (zPtr),y
        ldy ChanRegOfs,x
        sta SQ1_VOL,y
        ldy #$03
        lda (zPtr),y
        sta mReg3,x
        iny
        lda (zPtr),y
        sta mReg2,x
        lda #$03
        sta mRegDirty,x
        ldy ChanRegOfs,x
        jsr WriteChannelRegs
        ldy #$04

;----------------------------------------------------------------------
; Effect pointer = zPtr + Y + 1.
Sfx_SetPtr:
        iny
        tya
        clc
        adc zPtr
        sta sPtrLo,x
        lda zPtr+1
        adc #$00
        sta sPtrHi,x
        rts

LE9F7:
        rts                                 ; BUG: returns with X still pushed

;----------------------------------------------------------------------
; Called once per frame: run every sound effect channel.
Sfx_Update:
        ldx #$00
        jsr Sfx_UpdateChannel
        ldx #$01
        jsr Sfx_UpdateChannel
        ldx #$02
        jsr Sfx_UpdateChannel
        ldx #$03
        jsr Sfx_UpdateChannel
        rts

;----------------------------------------------------------------------
; X = channel.
Sfx_UpdateChannel:
        lda sTimer,x
        beq LEA16
        dec sTimer,x
        rts

LEA16:
        lda sPtrHi,x
        bne LEA1C
        rts

LEA1C:
        sta zPtr+1
        lda sPtrLo,x
        sta zPtr
        ldy #$00
        lda (zPtr),y
        cmp #$FF
        beq Sfx_Stop
        sta sTimer,x
        sta sSpeed,x
        tya
        sta mRegDirty,x
        ldy #$01
        lda (zPtr),y
        ldy ChanRegOfs,x
        sta SQ1_VOL,y
        ldy #$02
        lda (zPtr),y
        cmp #$FF
        bne LEA52
        ldy sPriority,x
        lda sId,x
        tax
        tya
        jmp Sfx_Play

LEA52:
        cpx #$03
        bne LEA6E
        cmp mReg2,x
        beq LEA91
        sta mReg2,x
        lda #$00
        sta mReg3,x
        lda mRegDirty,x
        ora #$03
        sta mRegDirty,x
        jmp LEA91

LEA6E:
        cmp mReg3,x
        beq LEA7E
        sta mReg3,x
        lda mRegDirty,x
        ora #$01
        sta mRegDirty,x

LEA7E:
        iny
        lda (zPtr),y
        cmp mReg2,x
        beq LEA91
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

LEA91:
        jsr Sfx_SetPtr
        lda mReg3,x
        ora mReg2,x
        beq Sfx_Stop
        ldy ChanRegOfs,x
        jmp WriteChannelRegs

;----------------------------------------------------------------------
; Effect finished: give the channel back to the music.
Sfx_Stop:
        lda mChanFlagsSave,x
        sta mChanFlags,x
        lda mApuStatus
        and ChanDisableMask,x               ; result discarded (no STA)
        lda #$00
        sta sPtrHi,x
        sta sPtrLo,x
        sta sPriority,x
        ldy ChanRegOfs,x
        lda mReg0,x
        sta SQ1_VOL,y
        lda mApuStatus
        sta APU_STATUS
        rts

;
; Sound effect pointers (index passed in X to Sfx_Play) (41 entries, split low/high byte tables)
SfxHi:
        .hibytes Sfx_00, Sfx_01, Sfx_02, Sfx_03 ; 0-3
        .hibytes Sfx_04, Sfx_05, Sfx_06, Sfx_07 ; 4-7
        .hibytes Sfx_08, Sfx_09, Sfx_0A, Sfx_0B ; 8-11
        .hibytes Sfx_0C, Sfx_0D, Sfx_0E, Sfx_0F ; 12-15
        .hibytes Sfx_10, Sfx_11, Sfx_12, Sfx_13 ; 16-19
        .hibytes Sfx_14, Sfx_15, Sfx_16, Sfx_17 ; 20-23
        .hibytes Sfx_18, Sfx_19, Sfx_1A, Sfx_1B ; 24-27
        .hibytes Sfx_1C, Sfx_1D, Sfx_1E, Sfx_1F ; 28-31
        .hibytes Sfx_20, Sfx_21, Sfx_22, Sfx_23 ; 32-35
        .hibytes Sfx_24, Sfx_25, Sfx_26, Sfx_27 ; 36-39
        .hibytes Sfx_28                     ; 40

SfxLo:
        .lobytes Sfx_00, Sfx_01, Sfx_02, Sfx_03 ; 0-3
        .lobytes Sfx_04, Sfx_05, Sfx_06, Sfx_07 ; 4-7
        .lobytes Sfx_08, Sfx_09, Sfx_0A, Sfx_0B ; 8-11
        .lobytes Sfx_0C, Sfx_0D, Sfx_0E, Sfx_0F ; 12-15
        .lobytes Sfx_10, Sfx_11, Sfx_12, Sfx_13 ; 16-19
        .lobytes Sfx_14, Sfx_15, Sfx_16, Sfx_17 ; 20-23
        .lobytes Sfx_18, Sfx_19, Sfx_1A, Sfx_1B ; 24-27
        .lobytes Sfx_1C, Sfx_1D, Sfx_1E, Sfx_1F ; 28-31
        .lobytes Sfx_20, Sfx_21, Sfx_22, Sfx_23 ; 32-35
        .lobytes Sfx_24, Sfx_25, Sfx_26, Sfx_27 ; 36-39
        .lobytes Sfx_28                     ; 40

Sfx_28:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; delay before the first step
        .byte $BC,$80,$E2                   ; reg0, reg3, reg2
        .byte $04,$BC,$80,$B3               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$97               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$71               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$59               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$4B               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$38               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$2C               ; delay 4, reg0, reg3, reg2
        .byte $18,$BC,$80,$25               ; delay 24, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_27:
        .byte $01                           ; channel: Sq2
        .byte $08                           ; delay before the first step
        .byte $BC,$80,$A9                   ; reg0, reg3, reg2
        .byte $04,$BC,$80,$86               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$7F               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$71               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$64               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$59               ; delay 4, reg0, reg3, reg2
        .byte $0C,$BC,$80,$54               ; delay 12, reg0, reg3, reg2
        .byte $04,$BC,$80,$59               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$64               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$71               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$7F               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$86               ; delay 4, reg0, reg3, reg2
        .byte $04,$BC,$80,$97               ; delay 4, reg0, reg3, reg2
        .byte $FF                           ; end

Sfx_26:
        .byte $03                           ; channel: Noise
        .byte $0A                           ; delay before the first step
        .byte $32,$80,$0D                   ; reg0, reg3, reg2
        .byte $0A,$34,$0D                   ; delay 10, reg0, period
        .byte $0A,$36,$0D                   ; delay 10, reg0, period
        .byte $0A,$38,$0D                   ; delay 10, reg0, period
        .byte $0A,$3C,$0D                   ; delay 10, reg0, period
        .byte $0A,$3E,$0D                   ; delay 10, reg0, period
        .byte $64,$3F,$0D                   ; delay 100, reg0, period
        .byte $0A,$3E,$0D                   ; delay 10, reg0, period
        .byte $0A,$3C,$0D                   ; delay 10, reg0, period
        .byte $0A,$3A,$0D                   ; delay 10, reg0, period
        .byte $0A,$38,$0D                   ; delay 10, reg0, period
        .byte $0A,$36,$0D                   ; delay 10, reg0, period
        .byte $0A,$34,$0D                   ; delay 10, reg0, period
        .byte $0A,$32,$0D                   ; delay 10, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_25:
        .byte $03                           ; channel: Noise
        .byte $04                           ; delay before the first step
        .byte $3F,$80,$0A                   ; reg0, reg3, reg2
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_22:
        .byte $00                           ; channel: Sq1
        .byte $03                           ; delay before the first step
        .byte $BF,$86,$AE                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_21:
Sfx_23:
Sfx_24:
        .byte $03                           ; channel: Noise
        .byte $02                           ; delay before the first step
        .byte $3F,$80,$05                   ; reg0, reg3, reg2
        .byte $02,$37,$06                   ; delay 2, reg0, period
        .byte $02,$3C,$07                   ; delay 2, reg0, period
        .byte $02,$35,$08                   ; delay 2, reg0, period
        .byte $02,$3B,$09                   ; delay 2, reg0, period
        .byte $02,$34,$0A                   ; delay 2, reg0, period
        .byte $02,$3A,$0B                   ; delay 2, reg0, period
        .byte $02,$33,$0C                   ; delay 2, reg0, period
        .byte $02,$39,$0D                   ; delay 2, reg0, period
        .byte $02,$32,$0E                   ; delay 2, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_20:
        .byte $03                           ; channel: Noise
        .byte $02                           ; delay before the first step
        .byte $31,$80,$0D                   ; reg0, reg3, reg2
        .byte $02,$32,$0D                   ; delay 2, reg0, period
        .byte $02,$33,$0D                   ; delay 2, reg0, period
        .byte $02,$34,$0D                   ; delay 2, reg0, period
        .byte $02,$35,$0D                   ; delay 2, reg0, period
        .byte $02,$37,$0D                   ; delay 2, reg0, period
        .byte $02,$39,$0D                   ; delay 2, reg0, period
        .byte $02,$3A,$0D                   ; delay 2, reg0, period
        .byte $02,$3C,$0D                   ; delay 2, reg0, period
        .byte $02,$3E,$0D                   ; delay 2, reg0, period
        .byte $02,$3F,$0D                   ; delay 2, reg0, period
        .byte $02,$3F,$0D                   ; delay 2, reg0, period
        .byte $02,$3F,$0D                   ; delay 2, reg0, period
        .byte $04,$3F,$0D                   ; delay 4, reg0, period
        .byte $04,$3E,$0D                   ; delay 4, reg0, period
        .byte $04,$3D,$0D                   ; delay 4, reg0, period
        .byte $04,$3C,$0D                   ; delay 4, reg0, period
        .byte $04,$3B,$0D                   ; delay 4, reg0, period
        .byte $04,$3A,$0D                   ; delay 4, reg0, period
        .byte $04,$39,$0D                   ; delay 4, reg0, period
        .byte $04,$38,$0D                   ; delay 4, reg0, period
        .byte $04,$37,$0D                   ; delay 4, reg0, period
        .byte $04,$36,$0D                   ; delay 4, reg0, period
        .byte $04,$35,$0D                   ; delay 4, reg0, period
        .byte $04,$34,$0D                   ; delay 4, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_1E:
        .byte $01                           ; channel: Sq2
        .byte $05                           ; delay before the first step
        .byte $BF,$81,$FE                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_1F:
        .byte $00                           ; channel: Sq1
        .byte $05                           ; delay before the first step
        .byte $BC,$81,$53                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_1B:
        .byte $03                           ; channel: Noise
        .byte $02                           ; delay before the first step
        .byte $3F,$80,$1B                   ; reg0, reg3, reg2
        .byte $02,$3F,$19                   ; delay 2, reg0, period
        .byte $02,$3F,$17                   ; delay 2, reg0, period
        .byte $02,$3F,$15                   ; delay 2, reg0, period
        .byte $02,$3F,$13                   ; delay 2, reg0, period
        .byte $02,$3F,$11                   ; delay 2, reg0, period
        .byte $02,$3F,$0E                   ; delay 2, reg0, period
        .byte $02,$3F,$0C                   ; delay 2, reg0, period
        .byte $02,$3F,$0A                   ; delay 2, reg0, period
        .byte $01,$00,$0A                   ; delay 1, reg0, period
        .byte $FF                           ; end

Sfx_1C:
        .byte $00                           ; channel: Sq1
        .byte $14                           ; delay before the first step
        .byte $30,$00,$86                   ; reg0, reg3, reg2
        .byte $02,$B8,$80,$86               ; delay 2, reg0, reg3, reg2
        .byte $27,$80,$2F,$80               ; delay 39, reg0, reg3, reg2
        .byte $86,$01,$00,$00               ; delay 134, reg0, reg3, reg2 -> end
        .byte $00,$FF                       ; never read

Sfx_1D:
        .byte $01                           ; channel: Sq2
        .byte $14                           ; delay before the first step
        .byte $30,$00,$21                   ; reg0, reg3, reg2
        .byte $02,$BF,$80,$21               ; delay 2, reg0, reg3, reg2
        .byte $27,$AF,$80,$21               ; delay 39, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_1A:
        .byte $03                           ; channel: Noise
        .byte $05                           ; delay before the first step
        .byte $31,$80,$0A                   ; reg0, reg3, reg2
        .byte $05,$32,$0A                   ; delay 5, reg0, period
        .byte $05,$34,$0A                   ; delay 5, reg0, period
        .byte $05,$38,$0A                   ; delay 5, reg0, period
        .byte $05,$3C,$0A                   ; delay 5, reg0, period
        .byte $05,$3E,$0A                   ; delay 5, reg0, period
        .byte $05,$3F,$0A                   ; delay 5, reg0, period
        .byte $05,$3F,$0A                   ; delay 5, reg0, period
        .byte $64,$3F,$0A                   ; delay 100, reg0, period
        .byte $0A,$3F,$0A                   ; delay 10, reg0, period
        .byte $0A,$3E,$0A                   ; delay 10, reg0, period
        .byte $0A,$3D,$0A                   ; delay 10, reg0, period
        .byte $0A,$3C,$0A                   ; delay 10, reg0, period
        .byte $0A,$3B,$0A                   ; delay 10, reg0, period
        .byte $0A,$3A,$0A                   ; delay 10, reg0, period
        .byte $0A,$39,$0A                   ; delay 10, reg0, period
        .byte $0A,$38,$0A                   ; delay 10, reg0, period
        .byte $0A,$36,$0A                   ; delay 10, reg0, period
        .byte $0A,$35,$0A                   ; delay 10, reg0, period
        .byte $0A,$34,$0A                   ; delay 10, reg0, period
        .byte $0A,$33,$0A                   ; delay 10, reg0, period
        .byte $0A,$35,$0A                   ; delay 10, reg0, period
        .byte $0A,$31,$0A                   ; delay 10, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_18:
Sfx_19:
        .byte $03                           ; channel: Noise
        .byte $01                           ; delay before the first step
        .byte $1F,$80,$18                   ; reg0, reg3, reg2
        .byte $01,$10,$18                   ; delay 1, reg0, period
        .byte $01,$1F,$14                   ; delay 1, reg0, period
        .byte $01,$10,$14                   ; delay 1, reg0, period
        .byte $01,$1F,$10                   ; delay 1, reg0, period
        .byte $01,$10,$10                   ; delay 1, reg0, period
        .byte $01,$1F,$08                   ; delay 1, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_16:
        .byte $01                           ; channel: Sq2
        .byte $0A                           ; delay before the first step
        .byte $00,$04,$75                   ; reg0, reg3, reg2
        .byte $04,$00,$04,$75               ; delay 4, reg0, reg3, reg2
        .byte $01,$BA,$80,$6A               ; delay 1, reg0, reg3, reg2
        .byte $02,$00,$00,$6A               ; delay 2, reg0, reg3, reg2
        .byte $01,$BA,$80,$5F               ; delay 1, reg0, reg3, reg2
        .byte $02,$00,$00,$5F               ; delay 2, reg0, reg3, reg2
        .byte $01,$BA,$80,$54               ; delay 1, reg0, reg3, reg2
        .byte $02,$00,$00,$54               ; delay 2, reg0, reg3, reg2
        .byte $01,$BA,$80,$50               ; delay 1, reg0, reg3, reg2
        .byte $02,$00,$00,$50               ; delay 2, reg0, reg3, reg2
        .byte $01,$BA,$80,$47               ; delay 1, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_17:
        .byte $03                           ; channel: Noise
        .byte $3C                           ; delay before the first step
        .byte $2F,$80,$1A                   ; reg0, reg3, reg2
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_14:
        .byte $03                           ; channel: Noise
        .byte $02                           ; delay before the first step
        .byte $3F,$80,$1A                   ; reg0, reg3, reg2
        .byte $01,$00,$1A                   ; delay 1, reg0, period
        .byte $01,$3F,$0A                   ; delay 1, reg0, period
        .byte $01,$3F,$0B                   ; delay 1, reg0, period
        .byte $01,$3F,$0C                   ; delay 1, reg0, period
        .byte $01,$3F,$0D                   ; delay 1, reg0, period
        .byte $01,$3F,$0E                   ; delay 1, reg0, period
        .byte $01,$3F,$0F                   ; delay 1, reg0, period
        .byte $01,$3F,$10                   ; delay 1, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_13:
Sfx_15:
        .byte $03                           ; channel: Noise
        .byte $01                           ; delay before the first step
        .byte $34,$80,$14                   ; reg0, reg3, reg2
        .byte $01,$3C,$14                   ; delay 1, reg0, period
        .byte $01,$36,$14                   ; delay 1, reg0, period
        .byte $01,$3F,$14                   ; delay 1, reg0, period
        .byte $01,$37,$14                   ; delay 1, reg0, period
        .byte $01,$3E,$14                   ; delay 1, reg0, period
        .byte $01,$3F,$14                   ; delay 1, reg0, period
        .byte $0A,$01,$14                   ; delay 10, reg0, period
        .byte $01,$32,$14                   ; delay 1, reg0, period
        .byte $01,$38,$14                   ; delay 1, reg0, period
        .byte $01,$34,$14                   ; delay 1, reg0, period
        .byte $01,$3F,$14                   ; delay 1, reg0, period
        .byte $01,$36,$14                   ; delay 1, reg0, period
        .byte $01,$3F,$14                   ; delay 1, reg0, period
        .byte $01,$3D,$14                   ; delay 1, reg0, period
        .byte $5A,$07,$14                   ; delay 90, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_12:
        .byte $03                           ; channel: Noise
        .byte $01                           ; delay before the first step
        .byte $3F,$80,$0F                   ; reg0, reg3, reg2
        .byte $01,$3E,$14                   ; delay 1, reg0, period
        .byte $01,$3D,$10                   ; delay 1, reg0, period
        .byte $01,$3C,$15                   ; delay 1, reg0, period
        .byte $01,$3B,$11                   ; delay 1, reg0, period
        .byte $01,$3A,$16                   ; delay 1, reg0, period
        .byte $01,$39,$12                   ; delay 1, reg0, period
        .byte $01,$38,$17                   ; delay 1, reg0, period
        .byte $01,$37,$13                   ; delay 1, reg0, period
        .byte $01,$36,$18                   ; delay 1, reg0, period
        .byte $01,$34,$14                   ; delay 1, reg0, period
        .byte $01,$32,$19                   ; delay 1, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_0F:
Sfx_10:
Sfx_11:
        .byte $03                           ; channel: Noise
        .byte $01                           ; delay before the first step
        .byte $31,$80,$19                   ; reg0, reg3, reg2
        .byte $01,$32,$19                   ; delay 1, reg0, period
        .byte $01,$34,$19                   ; delay 1, reg0, period
        .byte $02,$38,$19                   ; delay 2, reg0, period
        .byte $03,$3F,$19                   ; delay 3, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_0C:
        .byte $00                           ; channel: Sq1
        .byte $02                           ; delay before the first step
        .byte $B4,$80,$6A                   ; reg0, reg3, reg2
        .byte $02,$B6,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B8,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$BA,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$BC,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$1A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B6,$80,$1A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B8,$80,$1A               ; delay 2, reg0, reg3, reg2
        .byte $02,$BA,$80,$1A               ; delay 2, reg0, reg3, reg2
        .byte $02,$BC,$80,$1A               ; delay 2, reg0, reg3, reg2
        .byte $05,$B4,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $05,$B6,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $05,$B8,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $05,$BA,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $05,$BC,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $05,$BE,$80,$23               ; delay 5, reg0, reg3, reg2
        .byte $3C,$AF,$80,$23               ; delay 60, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_0D:
        .byte $01                           ; channel: Sq2
        .byte $02                           ; delay before the first step
        .byte $B4,$80,$D5                   ; reg0, reg3, reg2
        .byte $02,$B4,$80,$C9               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$BE               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$B3               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$A9               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$BE               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$B3               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$A9               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$A0               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$97               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$A9               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$A0               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$97               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$8E               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$86               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$97               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$8E               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$86               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$7F               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$77               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$86               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$7F               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$77               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$71               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$77               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$71               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$64               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$5F               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$6A               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$64               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$5F               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$5F               ; delay 2, reg0, reg3, reg2
        .byte $02,$B4,$80,$54               ; delay 2, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_0E:
        .byte $03                           ; channel: Noise
        .byte $05                           ; delay before the first step
        .byte $31,$80,$1C                   ; reg0, reg3, reg2
        .byte $05,$32,$1C                   ; delay 5, reg0, period
        .byte $05,$34,$1C                   ; delay 5, reg0, period
        .byte $05,$38,$1C                   ; delay 5, reg0, period
        .byte $05,$3C,$1C                   ; delay 5, reg0, period
        .byte $05,$3E,$1C                   ; delay 5, reg0, period
        .byte $05,$3F,$1C                   ; delay 5, reg0, period
        .byte $05,$3F,$1C                   ; delay 5, reg0, period
        .byte $05,$3E,$1C                   ; delay 5, reg0, period
        .byte $05,$3D,$1C                   ; delay 5, reg0, period
        .byte $05,$3C,$1C                   ; delay 5, reg0, period
        .byte $05,$3B,$1C                   ; delay 5, reg0, period
        .byte $05,$3A,$1C                   ; delay 5, reg0, period
        .byte $05,$39,$1C                   ; delay 5, reg0, period
        .byte $05,$38,$1C                   ; delay 5, reg0, period
        .byte $05,$37,$1C                   ; delay 5, reg0, period
        .byte $05,$36,$1C                   ; delay 5, reg0, period
        .byte $05,$35,$1C                   ; delay 5, reg0, period
        .byte $05,$34,$1C                   ; delay 5, reg0, period
        .byte $05,$33,$1C                   ; delay 5, reg0, period
        .byte $05,$32,$1C                   ; delay 5, reg0, period
        .byte $05,$31,$1C                   ; delay 5, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_0B:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; delay before the first step
        .byte $81,$80,$32                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$32               ; delay 1, reg0, reg3, reg2
        .byte $04,$81,$80,$43               ; delay 4, reg0, reg3, reg2
        .byte $01,$00,$00,$32               ; delay 1, reg0, reg3, reg2
        .byte $14,$81,$80,$32               ; delay 20, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_0A:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; delay before the first step
        .byte $8D,$80,$35                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$35               ; delay 1, reg0, reg3, reg2
        .byte $04,$8D,$80,$47               ; delay 4, reg0, reg3, reg2
        .byte $01,$00,$00,$35               ; delay 1, reg0, reg3, reg2
        .byte $14,$84,$80,$35               ; delay 20, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_09:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; delay before the first step
        .byte $8D,$80,$38                   ; reg0, reg3, reg2
        .byte $01,$00,$00,$38               ; delay 1, reg0, reg3, reg2
        .byte $04,$8D,$80,$4B               ; delay 4, reg0, reg3, reg2
        .byte $01,$00,$00,$38               ; delay 1, reg0, reg3, reg2
        .byte $14,$84,$80,$38               ; delay 20, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_08:
        .byte $03                           ; channel: Noise
        .byte $03                           ; delay before the first step
        .byte $3F,$80,$16                   ; reg0, reg3, reg2
        .byte $3C,$2F,$1C                   ; delay 60, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_06:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; delay before the first step
        .byte $BF,$86,$AE                   ; reg0, reg3, reg2
        .byte $01,$B1,$86,$AE               ; delay 1, reg0, reg3, reg2
        .byte $01,$BF,$86,$AE               ; delay 1, reg0, reg3, reg2
        .byte $01,$BA,$81,$AB               ; delay 1, reg0, reg3, reg2
        .byte $01,$B7,$81,$53               ; delay 1, reg0, reg3, reg2
        .byte $01,$B5,$81,$1D               ; delay 1, reg0, reg3, reg2
        .byte $01,$B2,$80,$6A               ; delay 1, reg0, reg3, reg2
        .byte $01,$B1,$80,$6A               ; delay 1, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_05:
Sfx_07:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; delay before the first step
        .byte $3F,$80,$71                   ; reg0, reg3, reg2
        .byte $01,$7F,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$BF,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$FF,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$BF,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$7F,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$3F,$80,$71               ; delay 1, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_00:
        .byte $03                           ; channel: Noise
        .byte $01                           ; delay before the first step
        .byte $36,$80,$14                   ; reg0, reg3, reg2
        .byte $01,$3A,$0F                   ; delay 1, reg0, period
        .byte $01,$3C,$0D                   ; delay 1, reg0, period
        .byte $01,$3F,$0A                   ; delay 1, reg0, period
        .byte $01,$3C,$08                   ; delay 1, reg0, period
        .byte $01,$38,$04                   ; delay 1, reg0, period
        .byte $01,$34,$07                   ; delay 1, reg0, period
        .byte $02,$33,$0A                   ; delay 2, reg0, period
        .byte $03,$32,$0C                   ; delay 3, reg0, period
        .byte $04,$31,$0E                   ; delay 4, reg0, period
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_01:
        .byte $03                           ; channel: Noise
        .byte $04                           ; delay before the first step
        .byte $3F,$80,$0F                   ; reg0, reg3, reg2
        .byte $01,$00,$00                   ; delay 1, reg0, period -> end
        .byte $FF                           ; never read

Sfx_02:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; delay before the first step
        .byte $3F,$80,$A9                   ; reg0, reg3, reg2
        .byte $01,$7F,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$BF,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$FF,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$BF,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$7F,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$3F,$80,$A9               ; delay 1, reg0, reg3, reg2
        .byte $01,$00,$00,$00               ; delay 1, reg0, reg3, reg2 -> end
        .byte $FF                           ; never read

Sfx_03:
Sfx_04:
        .byte $DC                           ; channel >= 4: ignored by Sfx_Play
