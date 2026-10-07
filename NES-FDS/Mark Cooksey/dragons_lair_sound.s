;==============================================================================
;  Mark Cooksey NES sound engine - DRAGON'S LAIR (E)
;  First version: 4 channels (2 squares, triangle, noise), no DMC.
;
;  Source: Dragon's Lair (E) [!].nes, MMC3, PRG 8K banks 0 and 1
;  (file offset $0010) at $8000-$A028. The last sound effect runs 41
;  bytes into bank 1; the rest of bank 1 is leftover assembler source
;  text, not included here.
;  Reassembles byte-identically:  ca65 dragons_lair_sound.s
;                    ld65 -C dragons_lair_sound.cfg -o out.bin dragons_lair_sound.o
;
;  ENTRY POINTS (SoundJumpTable, $8000)
;    $8000 Sfx_Init      silence/reset all sound effects
;    $8003 Sfx_Play      A = priority, X = effect number
;    $8006 Sfx_Update    once per frame
;    $8009 Music_Play    A = song number; A >= $80 stops the music
;    $800C Music_Update  once per frame
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
;
;  INSTRUMENTS (9 bytes, InstrumentLo/Hi)
;      +0      flags: 0 or 1 = uses a volume envelope, >= 2 = no volume envelope
;      +1,+2   volume envelope pointer (only if flags < 2)
;      +3,+4   pitch envelope pointer (high byte 0 = none)
;      +5      OR'ed into register 0 (duty, length-halt, constant volume)
;      +6      OR'ed into register 3 (length counter load)
;      +7,+8   arpeggio envelope pointer (high byte 0 = none)
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
;    header: channel (0-3), speed, reg0, reg3, reg2
;            An effect only starts if its priority >= the one playing on that
;            channel. While it plays, the music on that channel keeps running
;            but stops writing to the APU.
;    then every (speed+1) frames one step:
;      square/triangle:  reg0, reg3, reg2     reg3 = reg2 = 0  -> end
;      noise:            reg0, period         period = 0       -> end
;      any channel:      reg0, $FF                             -> restart effect
;    Channels >= 4 are rejected, but Sfx_Play returns without pulling the X it
;    pushed (stack bug; no effect in the table uses that path).
;
;  Bytes the engine never reads are kept (so the file reassembles) and are
;  marked "unreferenced", "never read" or "never reached".
;==============================================================================

; ---------------------------------------------------------------- RAM
zPtr                 = $00          ; pointer: track / instrument / envelope / effect data
zDurTab              = $02          ; pointer: current duration table
zChan                = $04          ; current channel number
zRegOfs              = $05          ; current channel * 4 (APU register offset)
zTemp                = $06          ; scratch
mTrkPtrLo            = $0781        ; track pointer low, per channel
mTrkPtrHi            = $0785        ; track pointer high, per channel
mDurTabLo            = $0789        ; duration table pointer (global)
mDurTabHi            = $078A
mNoteTimer           = $078B        ; frames left of the current note
mVolEnvTimer         = $078F        ; volume envelope
mVolEnvHi            = $0793
mVolEnvLo            = $0797
mPitchEnvTimer       = $079B        ; pitch envelope
mPitchEnvHi          = $079F
mPitchEnvLo          = $07A3
mArpEnvTimer         = $07A7        ; arpeggio envelope
mArpEnvHi            = $07AB
mArpEnvLo            = $07AF
mInstTemp            = $07B3        ; instrument number / flags while loading
mTranspose           = $07B4        ; transpose added to notes (CMD_CALL)
mRetLo               = $07B8        ; CMD_CALL return address
mRetHi               = $07BC
mLoopCount           = $07C0        ; CMD_CALL repeat count
mLoopActive          = $07C4        ; nonzero while a CMD_CALL repeats
mChanFlags           = $07C8        ; bit 0 = track running, bit 1 = owns the APU (no effect)
mRegDirty            = $07CC        ; bit 0 = reg3, bit 1 = reg2, bit 2 = reg0 need writing
mNote                = $07D0        ; current note (after transpose)
mReg3                = $07D4        ; shadow of register 3 (period high, length)
mReg2                = $07D8        ; shadow of register 2 (period low)
mReg0                = $07DC        ; shadow of register 0 (duty, volume)
mApuStatus           = $07E0        ; shadow APU_STATUS
mCmdVector           = $07E1        ; command handler address (JMP indirect)
sPtrHi               = $07E3        ; effect pointer high, per channel (0 = none)
sPtrLo               = $07E7        ; effect pointer low
mChanFlagsSave       = $07EB        ; mChanFlags restored when an effect ends
sTimer               = $07EF        ; frames until the next effect step
sSpeed               = $07F3        ; effect speed / step delay
sId                  = $07F7        ; effect number (for restart)
sNewPriority         = $07FB        ; priority passed to Sfx_Play
sPriority            = $07FC        ; priority of the effect on each channel

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
        sta mNoteTimer,y
        beq Music_ReadEvent
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
        bcc L814A
        lda #$00

L814A:
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
        sta mArpEnvLo,x
        iny
        lda (zPtr),y
        sta mArpEnvHi,x
        lda #$01
        sta mArpEnvTimer,x
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
        sta mArpEnvLo,x
        iny
        lda (zPtr),y
        sta mArpEnvHi,x
        lda #$01
        sta mArpEnvTimer,x

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
        bne Music_ArpEnvTick
        lda mPitchEnvLo,x
        sta zPtr
        lda mPitchEnvHi,x
        beq Music_ArpEnvTick
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        sta zTemp
        beq L82D4
        cmp #$80
        bne L82C5
        iny
        lda (zPtr),y
        sta mPitchEnvLo,x
        iny
        lda (zPtr),y
        sta mPitchEnvHi,x
        lda #$01
        sta mPitchEnvTimer,x
        jmp Music_ArpEnvTick

L82C5:
        clc
        adc mReg2,x
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

L82D4:
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
; Arpeggio envelope: (note offset, frames) pairs, $80 lo hi = jump.
Music_ArpEnvTick:
        ldx zChan
        dec mArpEnvTimer,x
        bne Music_Output
        lda mArpEnvLo,x
        sta zPtr
        lda mArpEnvHi,x
        beq Music_Output
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        cmp #$80
        bne L831A
        iny
        lda (zPtr),y
        sta mArpEnvLo,x
        iny
        lda (zPtr),y
        sta mArpEnvHi,x
        lda #$01
        sta mArpEnvTimer,x
        jmp Music_Output

L831A:
        clc
        adc mNote,x
        tay
        lda mReg3,x
        and #$F8
        clc
        cpy #$21
        bcs L832C
        adc PeriodHi,y

L832C:
        sta mReg3,x
        lda PeriodLo,y
        sta mReg2,x
        lda mRegDirty,x
        ora #$03
        sta mRegDirty,x
        ldy #$01
        lda (zPtr),y
        sta mArpEnvTimer,x
        lda mArpEnvLo,x
        clc
        adc #$02
        sta mArpEnvLo,x
        lda mArpEnvHi,x
        adc #$00
        sta mArpEnvHi,x

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
        beq L8376
        lda mReg3,x
        sta SQ1_HI,y
        lda mRegDirty,x
        and #$FE
        sta mRegDirty,x

L8376:
        lda mRegDirty,x
        and #$02
        beq L838B
        lda mReg2,x
        sta SQ1_LO,y
        lda mRegDirty,x
        and #$FD
        sta mRegDirty,x

L838B:
        lda mRegDirty,x
        and #$04
        beq L83A0
        lda mReg0,x
        sta SQ1_VOL,y
        lda mRegDirty,x
        and #$FB
        sta mRegDirty,x

L83A0:
        rts

;
; Track command handlers, commands $60-$64 (5 entries, split low/high byte tables)
CmdHandlerHi:
        .hibytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .hibytes Cmd_Jump                   ; 4

CmdHandlerLo:
        .lobytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .lobytes Cmd_Jump                   ; 4

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
        beq L83D6
        lda mReg0,x
        and #$F0
        sta mReg0,x
        lda mRegDirty,x
        ora #$04
        sta mRegDirty,x

L83D6:
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
        bne L841F
        ldy #$03
        lda (zPtr),y
        sta mLoopCount,x

L841F:
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
        beq L845E
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

L845E:
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
; unreferenced code (nothing jumps here)
Unused_SetTimerAndAdvance:
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
        .byte $1A,$19,$17,$16,$15,$14,$12,$11,$10,$0F,$0E,$0E ; octave 8
        .byte $0D,$0C,$0B,$0B,$0A,$0A,$09,$08,$08,$07,$07,$07 ; octave 9

; Note period table, high bytes (notes >= $21 use 0)
PeriodHi:
        .byte $06,$06,$05,$05,$05,$05,$04,$04,$04,$03,$03,$03 ; octave 2
        .byte $03,$03,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01 ; octave 3
        .byte $01,$01,$01,$01,$01,$01,$01,$01,$01 ; octave 4

;
; Instrument pointers (23 entries, split low/high byte tables)
InstrumentLo:
        .lobytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .lobytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .lobytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .lobytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15
        .lobytes Instrument_10, Instrument_11, Instrument_12, Instrument_13 ; 16-19
        .lobytes Instrument_14, Instrument_15, Instrument_16 ; 20-22

InstrumentHi:
        .hibytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .hibytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .hibytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .hibytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15
        .hibytes Instrument_10, Instrument_11, Instrument_12, Instrument_13 ; 16-19
        .hibytes Instrument_14, Instrument_15, Instrument_16 ; 20-22

Instrument_00:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_863F                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_01:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8648                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_02:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8651                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $70                           ; reg0 bits (duty/const/halt): 70
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_03:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8664                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $F0                           ; reg0 bits (duty/const/halt): F0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_04:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $00                           ; reg0 bits (duty/const/halt): 00
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_05:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word PitchEnv_874F                 ; pitch envelope
        .byte $FF                           ; reg0 bits (duty/const/halt): FF
        .byte $08                           ; reg3 bits (length counter)
        .word ArpEnv_8731                   ; arpeggio envelope

Instrument_06:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_866F                   ; volume envelope
        .word PitchEnv_875F                 ; pitch envelope
        .byte $F0                           ; reg0 bits (duty/const/halt): F0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_07:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_867C                   ; volume envelope
        .word PitchEnv_876A                 ; pitch envelope
        .byte $F0                           ; reg0 bits (duty/const/halt): F0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_08:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8689                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_8736                   ; arpeggio envelope

Instrument_09:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8689                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_873F                   ; arpeggio envelope

Instrument_0A:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8689                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0B:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_86BC                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $70                           ; reg0 bits (duty/const/halt): 70
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0C:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_86D1                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0D:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $14                           ; reg0 bits (duty/const/halt): 14
        .byte $A0                           ; reg3 bits (length counter)
        .word ArpEnv_8731                   ; arpeggio envelope

Instrument_0E:
        .byte $01                           ; flags: volume envelope
        .word VolEnv_86EE                   ; volume envelope
        .word PitchEnv_875A                 ; pitch envelope
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0F:
        .byte $01                           ; flags: volume envelope
        .word VolEnv_86F3                   ; volume envelope
        .word PitchEnv_8775                 ; pitch envelope
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_10:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8702                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_8736                   ; arpeggio envelope

Instrument_11:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8702                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_873F                   ; arpeggio envelope

Instrument_12:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word PitchEnv_8786                 ; pitch envelope
        .byte $FF                           ; reg0 bits (duty/const/halt): FF
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_8731                   ; arpeggio envelope

Instrument_13:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_870D                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_14:
        .byte $01                           ; flags: volume envelope
        .word VolEnv_8718                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word ArpEnv_8748                   ; arpeggio envelope

Instrument_15:
        .byte $01                           ; flags: volume envelope
        .word VolEnv_8723                   ; volume envelope
        .word PitchEnv_8791                 ; pitch envelope
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_16:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_872C                   ; volume envelope
        .word PitchEnv_8796                 ; pitch envelope
        .byte $30                           ; reg0 bits (duty/const/halt): 30
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

VolEnv_863F:
        .byte $02,$02                       ; volume 2 for 2 frame(s)
        .byte $02,$08                       ; volume 2 for 8 frame(s)
        .byte $01,$10                       ; volume 1 for 16 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8648:
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $02,$10                       ; volume 2 for 16 frame(s)
        .byte $02,$18                       ; volume 2 for 24 frame(s)
        .byte $01,$20                       ; volume 1 for 32 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8651:
        .byte $09,$02                       ; volume 9 for 2 frame(s)
        .byte $08,$14                       ; volume 8 for 20 frame(s)
        .byte $07,$0A                       ; volume 7 for 10 frame(s)
        .byte $06,$05                       ; volume 6 for 5 frame(s)
        .byte $05,$06                       ; volume 5 for 6 frame(s)
        .byte $04,$08                       ; volume 4 for 8 frame(s)
        .byte $03,$14                       ; volume 3 for 20 frame(s)
        .byte $02,$19                       ; volume 2 for 25 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8664:
        .byte $05,$02                       ; volume 5 for 2 frame(s)
        .byte $04,$03                       ; volume 4 for 3 frame(s)
        .byte $03,$03                       ; volume 3 for 3 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_866F:
        .byte $05,$03                       ; volume 5 for 3 frame(s)
        .byte $04,$03                       ; volume 4 for 3 frame(s)
        .byte $03,$04                       ; volume 3 for 4 frame(s)
        .byte $02,$03                       ; volume 2 for 3 frame(s)
        .byte $01,$02                       ; volume 1 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_867C:
        .byte $05,$03                       ; volume 5 for 3 frame(s)
        .byte $04,$03                       ; volume 4 for 3 frame(s)
        .byte $03,$04                       ; volume 3 for 4 frame(s)
        .byte $02,$03                       ; volume 2 for 3 frame(s)
        .byte $01,$02                       ; volume 1 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8689:
        .byte $03,$06                       ; volume 3 for 6 frame(s)
        .byte $00,$06                       ; volume 0 for 6 frame(s)
        .byte $02,$06                       ; volume 2 for 6 frame(s)
        .byte $00,$06                       ; volume 0 for 6 frame(s)
        .byte $02,$05                       ; volume 2 for 5 frame(s)
        .byte $00,$07                       ; volume 0 for 7 frame(s)
        .byte $02,$04                       ; volume 2 for 4 frame(s)
        .byte $00,$08                       ; volume 0 for 8 frame(s)
        .byte $01,$06                       ; volume 1 for 6 frame(s)
        .byte $00,$06                       ; volume 0 for 6 frame(s)
        .byte $01,$06                       ; volume 1 for 6 frame(s)
        .byte $00,$06                       ; volume 0 for 6 frame(s)
        .byte $01,$06                       ; volume 1 for 6 frame(s)
        .byte $00,$06                       ; volume 0 for 6 frame(s)
        .byte $01,$05                       ; volume 1 for 5 frame(s)
        .byte $00,$07                       ; volume 0 for 7 frame(s)
        .byte $01,$04                       ; volume 1 for 4 frame(s)
        .byte $00,$08                       ; volume 0 for 8 frame(s)
        .byte $01,$03                       ; volume 1 for 3 frame(s)
        .byte $00,$09                       ; volume 0 for 9 frame(s)
        .byte $01,$02                       ; volume 1 for 2 frame(s)
        .byte $00,$0A                       ; volume 0 for 10 frame(s)
        .byte $01,$01                       ; volume 1 for 1 frame(s)
        .byte $00,$0B                       ; volume 0 for 11 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_86BC:
        .byte $09,$02                       ; volume 9 for 2 frame(s)
        .byte $08,$02                       ; volume 8 for 2 frame(s)
        .byte $07,$02                       ; volume 7 for 2 frame(s)
        .byte $06,$02                       ; volume 6 for 2 frame(s)
        .byte $05,$03                       ; volume 5 for 3 frame(s)
        .byte $04,$02                       ; volume 4 for 2 frame(s)
        .byte $03,$0F                       ; volume 3 for 15 frame(s)
        .byte $02,$0F                       ; volume 2 for 15 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_86D1:
        .byte $0F,$01                       ; volume 15 for 1 frame(s)
        .byte $0E,$01                       ; volume 14 for 1 frame(s)
        .byte $0D,$01                       ; volume 13 for 1 frame(s)
        .byte $0C,$01                       ; volume 12 for 1 frame(s)
        .byte $0A,$02                       ; volume 10 for 2 frame(s)
        .byte $08,$02                       ; volume 8 for 2 frame(s)
        .byte $07,$04                       ; volume 7 for 4 frame(s)
        .byte $06,$04                       ; volume 6 for 4 frame(s)
        .byte $05,$06                       ; volume 5 for 6 frame(s)
        .byte $04,$06                       ; volume 4 for 6 frame(s)
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_86EE:
        .byte $03,$02                       ; volume 3 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_86F3:
        .byte $01,$04                       ; volume 1 for 4 frame(s)
        .byte $02,$04                       ; volume 2 for 4 frame(s)
        .byte $03,$20                       ; volume 3 for 32 frame(s)
        .byte $03,$30                       ; volume 3 for 48 frame(s)
        .byte $03,$20                       ; volume 3 for 32 frame(s)
        .byte $02,$20                       ; volume 2 for 32 frame(s)
        .byte $01,$20                       ; volume 1 for 32 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8702:
        .byte $05,$0A                       ; volume 5 for 10 frame(s)
        .byte $04,$14                       ; volume 4 for 20 frame(s)
        .byte $03,$1E                       ; volume 3 for 30 frame(s)
        .byte $02,$28                       ; volume 2 for 40 frame(s)
        .byte $01,$32                       ; volume 1 for 50 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_870D:
        .byte $04,$14                       ; volume 4 for 20 frame(s)
        .byte $03,$16                       ; volume 3 for 22 frame(s)
        .byte $02,$18                       ; volume 2 for 24 frame(s)
        .byte $01,$1A                       ; volume 1 for 26 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8718:
        .byte $07,$01                       ; volume 7 for 1 frame(s)
        .byte $06,$01                       ; volume 6 for 1 frame(s)
        .byte $05,$01                       ; volume 5 for 1 frame(s)
        .byte $02,$01                       ; volume 2 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8723:
        .byte $0C,$01                       ; volume 12 for 1 frame(s)
        .byte $0A,$01                       ; volume 10 for 1 frame(s)
        .byte $07,$01                       ; volume 7 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_872C:
        .byte $04,$01                       ; volume 4 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

ArpEnv_8731:
        .byte $F4,$FF                       ; note -12 for 255 fr
        .byte $80                           ; jump
        .word ArpEnv_8731

ArpEnv_8736:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $04,$02                       ; note +4 for 2 fr
        .byte $07,$02                       ; note +7 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_8736

ArpEnv_873F:
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $03,$02                       ; note +3 for 2 fr
        .byte $07,$02                       ; note +7 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_873F

ArpEnv_8748:
        .byte $D0,$02                       ; note -48 for 2 fr
        .byte $00,$02                       ; note +0 for 2 fr
        .byte $80                           ; jump
        .word ArpEnv_8748

PitchEnv_874F:
        .byte $01,$02                       ; period +1, wait 2
        .byte $00,$02                       ; wait 2
        .byte $FF,$02                       ; period -1, wait 2
        .byte $00,$02                       ; wait 2
        .byte $80                           ; jump
        .word PitchEnv_874F

PitchEnv_875A:
        .byte $00,$FF                       ; wait 255
        .byte $80                           ; jump
        .word PitchEnv_875A

PitchEnv_875F:
        .byte $01,$7F                       ; period +1, wait 127
        .byte $01,$7F                       ; period +1, wait 127
        .byte $01,$7F                       ; period +1, wait 127
        .byte $01,$7F                       ; period +1, wait 127
        .byte $80                           ; jump
        .word PitchEnv_875F

PitchEnv_876A:
        .byte $FF,$7F                       ; period -1, wait 127
        .byte $FF,$7F                       ; period -1, wait 127
        .byte $FF,$7F                       ; period -1, wait 127
        .byte $FF,$7F                       ; period -1, wait 127
        .byte $80                           ; jump
        .word PitchEnv_876A

PitchEnv_8775:
        .byte $01,$0A                       ; period +1, wait 10
        .byte $02,$0A                       ; period +2, wait 10
        .byte $03,$0A                       ; period +3, wait 10
        .byte $04,$0A                       ; period +4, wait 10
        .byte $03,$0A                       ; period +3, wait 10
        .byte $02,$0A                       ; period +2, wait 10
        .byte $01,$05                       ; period +1, wait 5
        .byte $80                           ; jump
        .word PitchEnv_8775

PitchEnv_8786:
        .byte $05,$04                       ; period +5, wait 4
        .byte $00,$04                       ; wait 4
        .byte $FB,$04                       ; period -5, wait 4
        .byte $00,$04                       ; wait 4
        .byte $80                           ; jump
        .word PitchEnv_8786

PitchEnv_8791:
        .byte $FF,$FF                       ; period -1, wait 255
        .byte $80                           ; jump
        .word PitchEnv_8791

PitchEnv_8796:
        .byte $F4,$01                       ; period -12, wait 1
        .byte $F3,$7E                       ; period -13, wait 126
        .byte $80                           ; jump
        .word PitchEnv_8796

;
; Song table: 9 songs x 5 pointers (Sq1, Sq2, Tri, Noise, duration table)
SongHi:
        .hibytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, DurTable_8807 ; song $00
        .hibytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, DurTable_87F7 ; song $01
        .hibytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, DurTable_87F7 ; song $02
        .hibytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, DurTable_87F7 ; song $03
        .hibytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, DurTable_8807 ; song $04
        .hibytes Song05_Sq1, Song05_Sq2, Song05_Tri, Song05_Noise, DurTable_8837 ; song $05
        .hibytes Song06_Sq1, Song06_Sq2, Song06_Tri, Song06_Noise, DurTable_8827 ; song $06
        .hibytes Song07_Sq1, Song07_Sq2, Song07_Tri, Song07_Noise, DurTable_87F7 ; song $07
        .hibytes Song08_Sq1, Song08_Sq2, Song08_Tri, Song08_Noise, DurTable_8817 ; song $08

SongLo:
        .lobytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, DurTable_8807 ; song $00
        .lobytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, DurTable_87F7 ; song $01
        .lobytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, DurTable_87F7 ; song $02
        .lobytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, DurTable_87F7 ; song $03
        .lobytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, DurTable_8807 ; song $04
        .lobytes Song05_Sq1, Song05_Sq2, Song05_Tri, Song05_Noise, DurTable_8837 ; song $05
        .lobytes Song06_Sq1, Song06_Sq2, Song06_Tri, Song06_Noise, DurTable_8827 ; song $06
        .lobytes Song07_Sq1, Song07_Sq2, Song07_Tri, Song07_Noise, DurTable_87F7 ; song $07
        .lobytes Song08_Sq1, Song08_Sq2, Song08_Tri, Song08_Noise, DurTable_8817 ; song $08

DurTable_87F7:
        .byte $03,$04,$06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$08,$10,$3C ; frames for len[0..15]

DurTable_8807:
        .byte $04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$C0,$FC,$05,$0A,$50 ; frames for len[0..15]

DurTable_8817:
        .byte $05,$07,$0A,$0F,$14,$1E,$28,$3C,$50,$78,$A0,$F0,$0D,$0E,$1A,$1B ; frames for len[0..15]

DurTable_8827:
        .byte $02,$03,$04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$03,$05,$28 ; frames for len[0..15]

DurTable_8837:
        .byte $02,$02,$05,$06,$0A,$0F,$14,$1E,$28,$3C,$50,$78,$A0,$04,$07,$10 ; frames for len[0..15]

;======================================================================
; Song $00
;======================================================================
Song00_Sq1:
        .byte $5D,$00                       ; A-9    ins  0  len[0] = 4 fr
        .byte CMD_CALL,$00,$00,$01          ; Pattern_00, transpose +0, play 1x
        .byte CMD_CALL,$00,$FC,$01          ; Pattern_00, transpose -4, play 1x
        .byte CMD_CALL,$00,$F8,$01          ; Pattern_00, transpose -8, play 1x
        .byte CMD_CALL,$00,$F4,$01          ; Pattern_00, transpose -12, play 1x
        .byte CMD_CALL,$00,$F0,$01          ; Pattern_00, transpose -16, play 1x
        .byte CMD_CALL,$00,$EC,$01          ; Pattern_00, transpose -20, play 1x
        .byte CMD_CALL,$00,$E8,$01          ; Pattern_00, transpose -24, play 1x
        .byte CMD_CALL,$00,$E4,$01          ; Pattern_00, transpose -28, play 1x
        .byte CMD_REST,$00                  ; rest len[0] = 4 fr
        .byte CMD_END

Pattern_00:
        .byte $3B,$00                       ; B-6    ins  0  len[0] = 4 fr
        .byte $38,$00                       ; G#6    ins  0  len[0] = 4 fr
        .byte $35,$00                       ; F-6    ins  0  len[0] = 4 fr
        .byte $32,$00                       ; D-6    ins  0  len[0] = 4 fr
        .byte $2F,$00                       ; B-5    ins  0  len[0] = 4 fr
        .byte $2C,$00                       ; G#5    ins  0  len[0] = 4 fr
        .byte $29,$00                       ; F-5    ins  0  len[0] = 4 fr
        .byte $26,$00                       ; D-5    ins  0  len[0] = 4 fr
        .byte $23,$00                       ; B-4    ins  0  len[0] = 4 fr
        .byte $26,$00                       ; D-5    ins  0  len[0] = 4 fr
        .byte $29,$00                       ; F-5    ins  0  len[0] = 4 fr
        .byte $2C,$00                       ; G#5    ins  0  len[0] = 4 fr
        .byte $2F,$00                       ; B-5    ins  0  len[0] = 4 fr
        .byte $32,$00                       ; D-6    ins  0  len[0] = 4 fr
        .byte $35,$00                       ; F-6    ins  0  len[0] = 4 fr
        .byte $38,$00                       ; G#6    ins  0  len[0] = 4 fr
        .byte $3A,$00                       ; A#6    ins  0  len[0] = 4 fr
        .byte $37,$00                       ; G-6    ins  0  len[0] = 4 fr
        .byte $34,$00                       ; E-6    ins  0  len[0] = 4 fr
        .byte $31,$00                       ; C#6    ins  0  len[0] = 4 fr
        .byte $2E,$00                       ; A#5    ins  0  len[0] = 4 fr
        .byte $2B,$00                       ; G-5    ins  0  len[0] = 4 fr
        .byte $28,$00                       ; E-5    ins  0  len[0] = 4 fr
        .byte $25,$00                       ; C#5    ins  0  len[0] = 4 fr
        .byte $22,$00                       ; A#4    ins  0  len[0] = 4 fr
        .byte $25,$00                       ; C#5    ins  0  len[0] = 4 fr
        .byte $28,$00                       ; E-5    ins  0  len[0] = 4 fr
        .byte $2B,$00                       ; G-5    ins  0  len[0] = 4 fr
        .byte $2E,$00                       ; A#5    ins  0  len[0] = 4 fr
        .byte $31,$00                       ; C#6    ins  0  len[0] = 4 fr
        .byte $34,$00                       ; E-6    ins  0  len[0] = 4 fr
        .byte $37,$00                       ; G-6    ins  0  len[0] = 4 fr
        .byte $39,$00                       ; A-6    ins  0  len[0] = 4 fr
        .byte $36,$00                       ; F#6    ins  0  len[0] = 4 fr
        .byte $33,$00                       ; D#6    ins  0  len[0] = 4 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 4 fr
        .byte $2D,$00                       ; A-5    ins  0  len[0] = 4 fr
        .byte $2A,$00                       ; F#5    ins  0  len[0] = 4 fr
        .byte $27,$00                       ; D#5    ins  0  len[0] = 4 fr
        .byte $24,$00                       ; C-5    ins  0  len[0] = 4 fr
        .byte $21,$00                       ; A-4    ins  0  len[0] = 4 fr
        .byte $24,$00                       ; C-5    ins  0  len[0] = 4 fr
        .byte $27,$00                       ; D#5    ins  0  len[0] = 4 fr
        .byte $2A,$00                       ; F#5    ins  0  len[0] = 4 fr
        .byte $2D,$00                       ; A-5    ins  0  len[0] = 4 fr
        .byte $30,$00                       ; C-6    ins  0  len[0] = 4 fr
        .byte $33,$00                       ; D#6    ins  0  len[0] = 4 fr
        .byte $36,$00                       ; F#6    ins  0  len[0] = 4 fr
        .byte $38,$00                       ; G#6    ins  0  len[0] = 4 fr
        .byte $35,$00                       ; F-6    ins  0  len[0] = 4 fr
        .byte $32,$00                       ; D-6    ins  0  len[0] = 4 fr
        .byte $2F,$00                       ; B-5    ins  0  len[0] = 4 fr
        .byte $2C,$00                       ; G#5    ins  0  len[0] = 4 fr
        .byte $29,$00                       ; F-5    ins  0  len[0] = 4 fr
        .byte $26,$00                       ; D-5    ins  0  len[0] = 4 fr
        .byte $23,$00                       ; B-4    ins  0  len[0] = 4 fr
        .byte $20,$00                       ; G#4    ins  0  len[0] = 4 fr
        .byte $23,$00                       ; B-4    ins  0  len[0] = 4 fr
        .byte $26,$00                       ; D-5    ins  0  len[0] = 4 fr
        .byte $29,$00                       ; F-5    ins  0  len[0] = 4 fr
        .byte $2C,$00                       ; G#5    ins  0  len[0] = 4 fr
        .byte $2F,$00                       ; B-5    ins  0  len[0] = 4 fr
        .byte $32,$00                       ; D-6    ins  0  len[0] = 4 fr
        .byte $35,$00                       ; F-6    ins  0  len[0] = 4 fr
        .byte CMD_RETURN

Song00_Sq2:
        .byte $5D,$A0                       ; A-9    ins 10  len[0] = 4 fr
        .byte CMD_REST,$00                  ; rest len[0] = 4 fr
        .byte CMD_CALL,$01,$00,$01          ; Pattern_01, transpose +0, play 1x
        .byte CMD_CALL,$01,$FC,$01          ; Pattern_01, transpose -4, play 1x
        .byte CMD_CALL,$01,$F8,$01          ; Pattern_01, transpose -8, play 1x
        .byte CMD_CALL,$01,$F4,$01          ; Pattern_01, transpose -12, play 1x
        .byte CMD_CALL,$01,$F0,$01          ; Pattern_01, transpose -16, play 1x
        .byte CMD_CALL,$01,$EC,$01          ; Pattern_01, transpose -20, play 1x
        .byte CMD_CALL,$01,$E8,$01          ; Pattern_01, transpose -24, play 1x
        .byte CMD_CALL,$01,$E4,$01          ; Pattern_01, transpose -28, play 1x
        .byte CMD_END

Pattern_01:
        .byte $23,$18                       ; B-4    ins  1  len[8] = 64 fr
        .byte $22,$18                       ; A#4    ins  1  len[8] = 64 fr
        .byte $21,$18                       ; A-4    ins  1  len[8] = 64 fr
        .byte $20,$18                       ; G#4    ins  1  len[8] = 64 fr
        .byte CMD_RETURN

Song00_Tri:
        .byte CMD_END

Song00_Noise:
Pattern_02:
        .byte CMD_END

;======================================================================
; Song $01
;======================================================================
Song01_Sq1:
Pattern_03:
Pattern_04:
        .byte CMD_CALL,$05,$F7,$01          ; Pattern_05, transpose -9, play 1x
        .byte CMD_CALL,$05,$FC,$01          ; Pattern_05, transpose -4, play 1x
        .byte CMD_CALL,$05,$F7,$01          ; Pattern_05, transpose -9, play 1x
        .byte CMD_CALL,$05,$FE,$01          ; Pattern_05, transpose -2, play 1x
        .byte CMD_JUMP
        .word Song01_Sq1

Song01_Sq2:
        .byte CMD_CALL,$06,$F7,$01          ; Pattern_06, transpose -9, play 1x
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte CMD_CALL,$06,$FC,$01          ; Pattern_06, transpose -4, play 1x
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte CMD_CALL,$06,$F7,$01          ; Pattern_06, transpose -9, play 1x
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte CMD_CALL,$06,$FE,$01          ; Pattern_06, transpose -2, play 1x
        .byte $05,$B2                       ; F-2    ins 11  len[2] = 6 fr
        .byte $04,$B2                       ; E-2    ins 11  len[2] = 6 fr
        .byte $03,$B2                       ; D#2    ins 11  len[2] = 6 fr
        .byte $02,$B2                       ; D-2    ins 11  len[2] = 6 fr
        .byte CMD_JUMP
        .word Song01_Sq2

Song01_Tri:
        .byte CMD_CALL,$07,$F7,$06          ; Pattern_07, transpose -9, play 6x
        .byte CMD_CALL,$07,$FC,$06          ; Pattern_07, transpose -4, play 6x
        .byte CMD_CALL,$07,$F7,$06          ; Pattern_07, transpose -9, play 6x
        .byte CMD_CALL,$07,$FE,$06          ; Pattern_07, transpose -2, play 6x
        .byte CMD_JUMP
        .word Song01_Tri

Song01_Noise:
        .byte CMD_CALL,$08,$00,$10          ; Pattern_08, transpose +0, play 16x
        .byte CMD_JUMP
        .word Song01_Noise

Pattern_05:
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1B,$B2                       ; D#4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1B,$B2                       ; D#4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1A,$B2                       ; D-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1A,$B2                       ; D-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte CMD_REST,$06                  ; rest len[6] = 24 fr
        .byte CMD_REST,$02                  ; rest len[2] = 6 fr
        .byte CMD_RETURN

Pattern_06:
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $18,$B2                       ; C-4    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $17,$B2                       ; B-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $17,$B2                       ; B-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $15,$B2                       ; A-3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte $14,$B2                       ; G#3    ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; A-2    ins 11  len[2] = 6 fr
        .byte CMD_RETURN

Pattern_07:
        .byte $21,$C2                       ; A-4    ins 12  len[2] = 6 fr
        .byte $15,$C2                       ; A-3    ins 12  len[2] = 6 fr
        .byte $21,$C2                       ; A-4    ins 12  len[2] = 6 fr
        .byte $15,$C2                       ; A-3    ins 12  len[2] = 6 fr
        .byte $21,$C2                       ; A-4    ins 12  len[2] = 6 fr
        .byte $15,$C2                       ; A-3    ins 12  len[2] = 6 fr
        .byte $21,$C2                       ; A-4    ins 12  len[2] = 6 fr
        .byte $15,$C2                       ; A-3    ins 12  len[2] = 6 fr
        .byte CMD_RETURN

Pattern_08:
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte $D1,$62                       ; noise $51 ins 22  len[2] = 6 fr
        .byte CMD_RETURN

;======================================================================
; Song $02
;======================================================================
Song02_Sq1:
        .byte CMD_CALL,$09,$00,$02          ; Pattern_09, transpose +0, play 2x
        .byte CMD_CALL,$0B,$00,$02          ; Pattern_0B, transpose +0, play 2x
        .byte CMD_CALL,$0B,$FE,$02          ; Pattern_0B, transpose -2, play 2x
        .byte $28,$8A                       ; E-5    ins  8  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song02_Sq1

Pattern_09:
        .byte $09,$66                       ; A-2    ins  6  len[6] = 24 fr
        .byte $10,$66                       ; E-3    ins  6  len[6] = 24 fr
        .byte $21,$98                       ; A-4    ins  9  len[8] = 48 fr
        .byte $0A,$66                       ; A#2    ins  6  len[6] = 24 fr
        .byte $11,$66                       ; F-3    ins  6  len[6] = 24 fr
        .byte $22,$98                       ; A#4    ins  9  len[8] = 48 fr
        .byte CMD_RETURN

Pattern_0B:
        .byte $0E,$64                       ; D-3    ins  6  len[4] = 12 fr
        .byte $11,$64                       ; F-3    ins  6  len[4] = 12 fr
        .byte $15,$64                       ; A-3    ins  6  len[4] = 12 fr
        .byte $17,$64                       ; B-3    ins  6  len[4] = 12 fr
        .byte $18,$64                       ; C-4    ins  6  len[4] = 12 fr
        .byte $15,$64                       ; A-3    ins  6  len[4] = 12 fr
        .byte $11,$64                       ; F-3    ins  6  len[4] = 12 fr
        .byte $0E,$64                       ; D-3    ins  6  len[4] = 12 fr
        .byte $10,$62                       ; E-3    ins  6  len[2] = 6 fr
        .byte $12,$62                       ; F#3    ins  6  len[2] = 6 fr
        .byte $14,$64                       ; G#3    ins  6  len[4] = 12 fr
        .byte $15,$64                       ; A-3    ins  6  len[4] = 12 fr
        .byte $17,$64                       ; B-3    ins  6  len[4] = 12 fr
        .byte $1A,$62                       ; D-4    ins  6  len[2] = 6 fr
        .byte $17,$62                       ; B-3    ins  6  len[2] = 6 fr
        .byte $15,$64                       ; A-3    ins  6  len[4] = 12 fr
        .byte $14,$64                       ; G#3    ins  6  len[4] = 12 fr
        .byte $10,$64                       ; E-3    ins  6  len[4] = 12 fr
        .byte CMD_RETURN

Song02_Sq2:
        .byte CMD_CALL,$0A,$00,$02          ; Pattern_0A, transpose +0, play 2x
        .byte CMD_CALL,$0C,$00,$01          ; Pattern_0C, transpose +0, play 1x
        .byte $10,$16                       ; E-3    ins  1  len[6] = 24 fr
        .byte $0B,$16                       ; B-2    ins  1  len[6] = 24 fr
        .byte $04,$18                       ; E-2    ins  1  len[8] = 48 fr
        .byte CMD_JUMP
        .word Song02_Sq2

Pattern_0A:
        .byte $09,$76                       ; A-2    ins  7  len[6] = 24 fr
        .byte $10,$76                       ; E-3    ins  7  len[6] = 24 fr
        .byte $09,$78                       ; A-2    ins  7  len[8] = 48 fr
        .byte $16,$9A                       ; A#3    ins  9  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_0C:
        .byte $02,$18                       ; D-2    ins  1  len[8] = 48 fr
        .byte $0E,$18                       ; D-3    ins  1  len[8] = 48 fr
        .byte $04,$18                       ; E-2    ins  1  len[8] = 48 fr
        .byte $10,$18                       ; E-3    ins  1  len[8] = 48 fr
        .byte $02,$18                       ; D-2    ins  1  len[8] = 48 fr
        .byte $26,$98                       ; D-5    ins  9  len[8] = 48 fr
        .byte $04,$18                       ; E-2    ins  1  len[8] = 48 fr
        .byte $28,$88                       ; E-5    ins  8  len[8] = 48 fr
        .byte $00,$18                       ; C-2    ins  1  len[8] = 48 fr
        .byte $24,$98                       ; C-5    ins  9  len[8] = 48 fr
        .byte $02,$18                       ; D-2    ins  1  len[8] = 48 fr
        .byte $26,$88                       ; D-5    ins  8  len[8] = 48 fr
        .byte $00,$18                       ; C-2    ins  1  len[8] = 48 fr
        .byte $24,$98                       ; C-5    ins  9  len[8] = 48 fr
        .byte $02,$18                       ; D-2    ins  1  len[8] = 48 fr
        .byte $26,$88                       ; D-5    ins  8  len[8] = 48 fr
        .byte CMD_RETURN

Song02_Tri:
        .byte CMD_END

Song02_Noise:
        .byte CMD_END

;======================================================================
; Song $03
;======================================================================
Song03_Sq1:
        .byte CMD_CALL,$0D,$00,$01          ; Pattern_0D, transpose +0, play 1x
        .byte CMD_CALL,$0F,$00,$01          ; Pattern_0F, transpose +0, play 1x
        .byte CMD_CALL,$11,$00,$01          ; Pattern_11, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song03_Sq1

Pattern_0D:
        .byte $18,$A4                       ; C-4    ins 10  len[4] = 12 fr
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 24 fr
        .byte $24,$A4                       ; C-5    ins 10  len[4] = 12 fr
        .byte $23,$A7                       ; B-4    ins 10  len[7] = 36 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $21,$A7                       ; A-4    ins 10  len[7] = 36 fr
        .byte $20,$A4                       ; G#4    ins 10  len[4] = 12 fr
        .byte $1F,$A7                       ; G-4    ins 10  len[7] = 36 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $1D,$AB                       ; F-4    ins 10  len[11] = 144 fr
        .byte CMD_REST,$08                  ; rest len[8] = 48 fr
        .byte $18,$A4                       ; C-4    ins 10  len[4] = 12 fr
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 24 fr
        .byte $24,$A4                       ; C-5    ins 10  len[4] = 12 fr
        .byte $23,$A7                       ; B-4    ins 10  len[7] = 36 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $21,$A7                       ; A-4    ins 10  len[7] = 36 fr
        .byte $20,$A4                       ; G#4    ins 10  len[4] = 12 fr
        .byte $1F,$A7                       ; G-4    ins 10  len[7] = 36 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $20,$AB                       ; G#4    ins 10  len[11] = 144 fr
        .byte CMD_REST,$08                  ; rest len[8] = 48 fr
        .byte CMD_RETURN

Pattern_0F:
        .byte $19,$A4                       ; C#4    ins 10  len[4] = 12 fr
        .byte $1D,$A6                       ; F-4    ins 10  len[6] = 24 fr
        .byte $25,$A4                       ; C#5    ins 10  len[4] = 12 fr
        .byte $24,$A7                       ; C-5    ins 10  len[7] = 36 fr
        .byte $23,$A4                       ; B-4    ins 10  len[4] = 12 fr
        .byte $22,$A7                       ; A#4    ins 10  len[7] = 36 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $20,$A4                       ; G#4    ins 10  len[4] = 12 fr
        .byte $1F,$A4                       ; G-4    ins 10  len[4] = 12 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $1D,$A4                       ; F-4    ins 10  len[4] = 12 fr
        .byte $1D,$AB                       ; F-4    ins 10  len[11] = 144 fr
        .byte CMD_REST,$08                  ; rest len[8] = 48 fr
        .byte $19,$A4                       ; C#4    ins 10  len[4] = 12 fr
        .byte $1D,$A6                       ; F-4    ins 10  len[6] = 24 fr
        .byte $25,$A4                       ; C#5    ins 10  len[4] = 12 fr
        .byte $24,$A7                       ; C-5    ins 10  len[7] = 36 fr
        .byte $23,$A4                       ; B-4    ins 10  len[4] = 12 fr
        .byte $22,$A7                       ; A#4    ins 10  len[7] = 36 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $20,$A4                       ; G#4    ins 10  len[4] = 12 fr
        .byte $1F,$A4                       ; G-4    ins 10  len[4] = 12 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $1D,$A4                       ; F-4    ins 10  len[4] = 12 fr
        .byte $21,$AB                       ; A-4    ins 10  len[11] = 144 fr
        .byte CMD_REST,$08                  ; rest len[8] = 48 fr
        .byte CMD_RETURN

Pattern_11:
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $1B,$A4                       ; D#4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $1F,$A4                       ; G-4    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $26,$A4                       ; D-5    ins 10  len[4] = 12 fr
        .byte $27,$A4                       ; D#5    ins 10  len[4] = 12 fr
        .byte $26,$A4                       ; D-5    ins 10  len[4] = 12 fr
        .byte $25,$A4                       ; C#5    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $24,$A4                       ; C-5    ins 10  len[4] = 12 fr
        .byte $22,$A6                       ; A#4    ins 10  len[6] = 24 fr
        .byte $1E,$A7                       ; F#4    ins 10  len[7] = 36 fr
        .byte $1A,$A6                       ; D-4    ins 10  len[6] = 24 fr
        .byte $1D,$AA                       ; F-4    ins 10  len[10] = 96 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $24,$A4                       ; C-5    ins 10  len[4] = 12 fr
        .byte $26,$A4                       ; D-5    ins 10  len[4] = 12 fr
        .byte $1E,$A4                       ; F#4    ins 10  len[4] = 12 fr
        .byte $22,$A4                       ; A#4    ins 10  len[4] = 12 fr
        .byte $21,$A4                       ; A-4    ins 10  len[4] = 12 fr
        .byte $1F,$A4                       ; G-4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $1B,$A4                       ; D#4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $19,$A4                       ; C#4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $1B,$A4                       ; D#4    ins 10  len[4] = 12 fr
        .byte $1A,$A4                       ; D-4    ins 10  len[4] = 12 fr
        .byte $19,$AA                       ; C#4    ins 10  len[10] = 96 fr
        .byte $1A,$AA                       ; D-4    ins 10  len[10] = 96 fr
        .byte CMD_RETURN

Song03_Sq2:
        .byte CMD_CALL,$0E,$00,$01          ; Pattern_0E, transpose +0, play 1x
        .byte CMD_CALL,$10,$00,$01          ; Pattern_10, transpose +0, play 1x
        .byte CMD_CALL,$12,$00,$01          ; Pattern_12, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song03_Sq2

Pattern_0E:
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $18,$A4                       ; C-4    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $17,$A4                       ; B-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $17,$A4                       ; B-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $05,$A4                       ; F-2    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $14,$A4                       ; G#3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $05,$A4                       ; F-2    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $18,$A4                       ; C-4    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $17,$A4                       ; B-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $17,$A4                       ; B-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $05,$A4                       ; F-2    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $14,$A4                       ; G#3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $05,$A4                       ; F-2    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $14,$A4                       ; G#3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0C,$A4                       ; C-3    ins 10  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_10:
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $19,$A4                       ; C#4    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $02,$A4                       ; D-2    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $02,$A4                       ; D-2    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $19,$A4                       ; C#4    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $02,$A4                       ; D-2    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $02,$A4                       ; D-2    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $09,$A4                       ; A-2    ins 10  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_12:
        .byte $07,$A4                       ; G-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $07,$A4                       ; G-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $03,$A4                       ; D#2    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $0F,$A4                       ; D#3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $12,$A4                       ; F#3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $03,$A4                       ; D#2    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $0F,$A4                       ; D#3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $12,$A4                       ; F#3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $07,$A4                       ; G-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $05,$A4                       ; F-2    ins 10  len[4] = 12 fr
        .byte $0E,$A4                       ; D-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $16,$A4                       ; A#3    ins 10  len[4] = 12 fr
        .byte $15,$A4                       ; A-3    ins 10  len[4] = 12 fr
        .byte $13,$A4                       ; G-3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $03,$A4                       ; D#2    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $0F,$A4                       ; D#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $12,$A4                       ; F#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $0F,$A4                       ; D#3    ins 10  len[4] = 12 fr
        .byte $0A,$A4                       ; A#2    ins 10  len[4] = 12 fr
        .byte $04,$A4                       ; E-2    ins 10  len[4] = 12 fr
        .byte $0B,$A4                       ; B-2    ins 10  len[4] = 12 fr
        .byte $04,$A4                       ; E-2    ins 10  len[4] = 12 fr
        .byte $14,$A4                       ; G#3    ins 10  len[4] = 12 fr
        .byte $17,$A4                       ; B-3    ins 10  len[4] = 12 fr
        .byte $14,$A4                       ; G#3    ins 10  len[4] = 12 fr
        .byte $11,$A4                       ; F-3    ins 10  len[4] = 12 fr
        .byte $10,$A4                       ; E-3    ins 10  len[4] = 12 fr
        .byte CMD_RETURN

Song03_Tri:
        .byte CMD_END

Song03_Noise:
        .byte CMD_END

;======================================================================
; Song $04
;======================================================================
Song04_Sq1:
        .byte CMD_CALL,$13,$00,$01          ; Pattern_13, transpose +0, play 1x
        .byte CMD_CALL,$17,$00,$01          ; Pattern_17, transpose +0, play 1x
        .byte CMD_CALL,$13,$00,$01          ; Pattern_13, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song04_Sq1

Pattern_13:
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B6                       ; A-4    ins 11  len[6] = 32 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B7                       ; A-4    ins 11  len[7] = 48 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $26,$B2                       ; D-5    ins 11  len[2] = 8 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B4                       ; A-4    ins 11  len[4] = 16 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $1F,$B2                       ; G-4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $1F,$B4                       ; G-4    ins 11  len[4] = 16 fr
        .byte $21,$B8                       ; A-4    ins 11  len[8] = 64 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B6                       ; A-4    ins 11  len[6] = 32 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B7                       ; A-4    ins 11  len[7] = 48 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $26,$B2                       ; D-5    ins 11  len[2] = 8 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $24,$B2                       ; C-5    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $24,$B4                       ; C-5    ins 11  len[4] = 16 fr
        .byte $21,$B4                       ; A-4    ins 11  len[4] = 16 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $1F,$B2                       ; G-4    ins 11  len[2] = 8 fr
        .byte $22,$B2                       ; A#4    ins 11  len[2] = 8 fr
        .byte $21,$B6                       ; A-4    ins 11  len[6] = 32 fr
        .byte $1F,$B8                       ; G-4    ins 11  len[8] = 64 fr
        .byte CMD_RETURN

Pattern_17:
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $1D,$B4                       ; F-4    ins 11  len[4] = 16 fr
        .byte $21,$B4                       ; A-4    ins 11  len[4] = 16 fr
        .byte $1D,$B4                       ; F-4    ins 11  len[4] = 16 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $18,$B4                       ; C-4    ins 11  len[4] = 16 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $1F,$B4                       ; G-4    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $21,$B8                       ; A-4    ins 11  len[8] = 64 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $26,$B4                       ; D-5    ins 11  len[4] = 16 fr
        .byte $22,$B4                       ; A#4    ins 11  len[4] = 16 fr
        .byte $21,$B4                       ; A-4    ins 11  len[4] = 16 fr
        .byte $1D,$B4                       ; F-4    ins 11  len[4] = 16 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $18,$B4                       ; C-4    ins 11  len[4] = 16 fr
        .byte $21,$B2                       ; A-4    ins 11  len[2] = 8 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $1A,$B4                       ; D-4    ins 11  len[4] = 16 fr
        .byte $1E,$B2                       ; F#4    ins 11  len[2] = 8 fr
        .byte $1C,$B2                       ; E-4    ins 11  len[2] = 8 fr
        .byte $1A,$B2                       ; D-4    ins 11  len[2] = 8 fr
        .byte $1E,$B2                       ; F#4    ins 11  len[2] = 8 fr
        .byte $16,$B8                       ; A#3    ins 11  len[8] = 64 fr
        .byte CMD_RETURN

Song04_Sq2:
        .byte CMD_CALL,$14,$00,$01          ; Pattern_14, transpose +0, play 1x
        .byte CMD_CALL,$18,$00,$01          ; Pattern_18, transpose +0, play 1x
        .byte CMD_CALL,$14,$00,$01          ; Pattern_14, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song04_Sq2

Pattern_14:
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $0E,$C6                       ; D-3    ins 12  len[6] = 32 fr
        .byte $12,$C6                       ; F#3    ins 12  len[6] = 32 fr
        .byte $13,$C6                       ; G-3    ins 12  len[6] = 32 fr
        .byte $07,$C2                       ; G-2    ins 12  len[2] = 8 fr
        .byte $09,$C2                       ; A-2    ins 12  len[2] = 8 fr
        .byte $0A,$C2                       ; A#2    ins 12  len[2] = 8 fr
        .byte $0C,$C2                       ; C-3    ins 12  len[2] = 8 fr
        .byte $0E,$C7                       ; D-3    ins 12  len[7] = 48 fr
        .byte $11,$C4                       ; F-3    ins 12  len[4] = 16 fr
        .byte $0A,$C6                       ; A#2    ins 12  len[6] = 32 fr
        .byte $16,$C6                       ; A#3    ins 12  len[6] = 32 fr
        .byte $11,$C6                       ; F-3    ins 12  len[6] = 32 fr
        .byte $0E,$C6                       ; D-3    ins 12  len[6] = 32 fr
        .byte $13,$C6                       ; G-3    ins 12  len[6] = 32 fr
        .byte $0F,$C4                       ; D#3    ins 12  len[4] = 16 fr
        .byte $0C,$C4                       ; C-3    ins 12  len[4] = 16 fr
        .byte $0E,$C6                       ; D-3    ins 12  len[6] = 32 fr
        .byte $02,$C2                       ; D-2    ins 12  len[2] = 8 fr
        .byte $04,$C2                       ; E-2    ins 12  len[2] = 8 fr
        .byte $06,$C4                       ; F#2    ins 12  len[4] = 16 fr
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $0E,$C6                       ; D-3    ins 12  len[6] = 32 fr
        .byte $12,$C6                       ; F#3    ins 12  len[6] = 32 fr
        .byte $13,$C6                       ; G-3    ins 12  len[6] = 32 fr
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $0E,$C7                       ; D-3    ins 12  len[7] = 48 fr
        .byte $15,$C4                       ; A-3    ins 12  len[4] = 16 fr
        .byte $16,$C6                       ; A#3    ins 12  len[6] = 32 fr
        .byte $0A,$C2                       ; A#2    ins 12  len[2] = 8 fr
        .byte $0C,$C2                       ; C-3    ins 12  len[2] = 8 fr
        .byte $0E,$C2                       ; D-3    ins 12  len[2] = 8 fr
        .byte $0F,$C2                       ; D#3    ins 12  len[2] = 8 fr
        .byte $11,$C6                       ; F-3    ins 12  len[6] = 32 fr
        .byte $0E,$C6                       ; D-3    ins 12  len[6] = 32 fr
        .byte $0F,$C4                       ; D#3    ins 12  len[4] = 16 fr
        .byte $0C,$C4                       ; C-3    ins 12  len[4] = 16 fr
        .byte $0E,$C4                       ; D-3    ins 12  len[4] = 16 fr
        .byte $02,$C4                       ; D-2    ins 12  len[4] = 16 fr
        .byte $07,$C8                       ; G-2    ins 12  len[8] = 64 fr
        .byte CMD_RETURN

Pattern_18:
        .byte $0A,$C4                       ; A#2    ins 12  len[4] = 16 fr
        .byte $11,$C4                       ; F-3    ins 12  len[4] = 16 fr
        .byte $16,$C6                       ; A#3    ins 12  len[6] = 32 fr
        .byte $05,$C4                       ; F-2    ins 12  len[4] = 16 fr
        .byte $0C,$C4                       ; C-3    ins 12  len[4] = 16 fr
        .byte $11,$C6                       ; F-3    ins 12  len[6] = 32 fr
        .byte $13,$C4                       ; G-3    ins 12  len[4] = 16 fr
        .byte $0E,$C4                       ; D-3    ins 12  len[4] = 16 fr
        .byte $07,$C2                       ; G-2    ins 12  len[2] = 8 fr
        .byte $09,$C2                       ; A-2    ins 12  len[2] = 8 fr
        .byte $0A,$C2                       ; A#2    ins 12  len[2] = 8 fr
        .byte $0C,$C2                       ; C-3    ins 12  len[2] = 8 fr
        .byte $0E,$C2                       ; D-3    ins 12  len[2] = 8 fr
        .byte $0F,$C2                       ; D#3    ins 12  len[2] = 8 fr
        .byte $0E,$C2                       ; D-3    ins 12  len[2] = 8 fr
        .byte $10,$C2                       ; E-3    ins 12  len[2] = 8 fr
        .byte $0E,$C2                       ; D-3    ins 12  len[2] = 8 fr
        .byte $0C,$C2                       ; C-3    ins 12  len[2] = 8 fr
        .byte $0A,$C2                       ; A#2    ins 12  len[2] = 8 fr
        .byte $09,$C2                       ; A-2    ins 12  len[2] = 8 fr
        .byte $0A,$C4                       ; A#2    ins 12  len[4] = 16 fr
        .byte $11,$C4                       ; F-3    ins 12  len[4] = 16 fr
        .byte $16,$C4                       ; A#3    ins 12  len[4] = 16 fr
        .byte $02,$C2                       ; D-2    ins 12  len[2] = 8 fr
        .byte $04,$C2                       ; E-2    ins 12  len[2] = 8 fr
        .byte $05,$C4                       ; F-2    ins 12  len[4] = 16 fr
        .byte $0C,$C4                       ; C-3    ins 12  len[4] = 16 fr
        .byte $11,$C4                       ; F-3    ins 12  len[4] = 16 fr
        .byte $0E,$C4                       ; D-3    ins 12  len[4] = 16 fr
        .byte $13,$C6                       ; G-3    ins 12  len[6] = 32 fr
        .byte $0E,$C4                       ; D-3    ins 12  len[4] = 16 fr
        .byte $15,$C4                       ; A-3    ins 12  len[4] = 16 fr
        .byte $07,$C6                       ; G-2    ins 12  len[6] = 32 fr
        .byte $02,$C2                       ; D-2    ins 12  len[2] = 8 fr
        .byte $04,$C2                       ; E-2    ins 12  len[2] = 8 fr
        .byte $06,$C4                       ; F#2    ins 12  len[4] = 16 fr
        .byte CMD_RETURN

Song04_Tri:
        .byte CMD_CALL,$15,$0C,$01          ; Pattern_15, transpose +12, play 1x
        .byte CMD_CALL,$19,$0C,$01          ; Pattern_19, transpose +12, play 1x
        .byte CMD_CALL,$15,$0C,$01          ; Pattern_15, transpose +12, play 1x
        .byte CMD_JUMP
        .word Song04_Tri

Pattern_15:
        .byte $26,$58                       ; D-5    ins  5  len[8] = 64 fr
        .byte $2A,$56                       ; F#5    ins  5  len[6] = 32 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 32 fr
        .byte $26,$56                       ; D-5    ins  5  len[6] = 32 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 16 fr
        .byte $2B,$52                       ; G-5    ins  5  len[2] = 8 fr
        .byte $27,$52                       ; D#5    ins  5  len[2] = 8 fr
        .byte $2A,$57                       ; F#5    ins  5  len[7] = 48 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 16 fr
        .byte $29,$56                       ; F-5    ins  5  len[6] = 32 fr
        .byte $29,$54                       ; F-5    ins  5  len[4] = 16 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 16 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 16 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 16 fr
        .byte $2A,$56                       ; F#5    ins  5  len[6] = 32 fr
        .byte $26,$56                       ; D-5    ins  5  len[6] = 32 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 16 fr
        .byte $27,$54                       ; D#5    ins  5  len[4] = 16 fr
        .byte $2B,$56                       ; G-5    ins  5  len[6] = 32 fr
        .byte $2A,$56                       ; F#5    ins  5  len[6] = 32 fr
        .byte $26,$58                       ; D-5    ins  5  len[8] = 64 fr
        .byte $2A,$56                       ; F#5    ins  5  len[6] = 32 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 32 fr
        .byte $26,$58                       ; D-5    ins  5  len[8] = 64 fr
        .byte $2A,$57                       ; F#5    ins  5  len[7] = 48 fr
        .byte $29,$54                       ; F-5    ins  5  len[4] = 16 fr
        .byte $29,$56                       ; F-5    ins  5  len[6] = 32 fr
        .byte $29,$56                       ; F-5    ins  5  len[6] = 32 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 16 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 16 fr
        .byte $2A,$56                       ; F#5    ins  5  len[6] = 32 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 16 fr
        .byte $27,$54                       ; D#5    ins  5  len[4] = 16 fr
        .byte $2B,$54                       ; G-5    ins  5  len[4] = 16 fr
        .byte $2A,$54                       ; F#5    ins  5  len[4] = 16 fr
        .byte $22,$58                       ; A#4    ins  5  len[8] = 64 fr
        .byte CMD_RETURN

Pattern_19:
        .byte $35,$52                       ; F-6    ins  5  len[2] = 8 fr
        .byte $34,$52                       ; E-6    ins  5  len[2] = 8 fr
        .byte $32,$52                       ; D-6    ins  5  len[2] = 8 fr
        .byte $34,$52                       ; E-6    ins  5  len[2] = 8 fr
        .byte $35,$54                       ; F-6    ins  5  len[4] = 16 fr
        .byte $32,$54                       ; D-6    ins  5  len[4] = 16 fr
        .byte $30,$50                       ; C-6    ins  5  len[0] = 4 fr
        .byte $32,$50                       ; D-6    ins  5  len[0] = 4 fr
        .byte $30,$50                       ; C-6    ins  5  len[0] = 4 fr
        .byte $2E,$50                       ; A#5    ins  5  len[0] = 4 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $30,$52                       ; C-6    ins  5  len[2] = 8 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $30,$52                       ; C-6    ins  5  len[2] = 8 fr
        .byte $2B,$52                       ; G-5    ins  5  len[2] = 8 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $30,$52                       ; C-6    ins  5  len[2] = 8 fr
        .byte $32,$52                       ; D-6    ins  5  len[2] = 8 fr
        .byte $34,$52                       ; E-6    ins  5  len[2] = 8 fr
        .byte $36,$52                       ; F#6    ins  5  len[2] = 8 fr
        .byte $37,$52                       ; G-6    ins  5  len[2] = 8 fr
        .byte $36,$58                       ; F#6    ins  5  len[8] = 64 fr
        .byte $35,$52                       ; F-6    ins  5  len[2] = 8 fr
        .byte $34,$52                       ; E-6    ins  5  len[2] = 8 fr
        .byte $32,$52                       ; D-6    ins  5  len[2] = 8 fr
        .byte $34,$52                       ; E-6    ins  5  len[2] = 8 fr
        .byte $35,$54                       ; F-6    ins  5  len[4] = 16 fr
        .byte $32,$54                       ; D-6    ins  5  len[4] = 16 fr
        .byte $30,$50                       ; C-6    ins  5  len[0] = 4 fr
        .byte $32,$50                       ; D-6    ins  5  len[0] = 4 fr
        .byte $30,$50                       ; C-6    ins  5  len[0] = 4 fr
        .byte $2E,$50                       ; A#5    ins  5  len[0] = 4 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $30,$52                       ; C-6    ins  5  len[2] = 8 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $30,$52                       ; C-6    ins  5  len[2] = 8 fr
        .byte $2E,$50                       ; A#5    ins  5  len[0] = 4 fr
        .byte $30,$50                       ; C-6    ins  5  len[0] = 4 fr
        .byte $2E,$50                       ; A#5    ins  5  len[0] = 4 fr
        .byte $2D,$50                       ; A-5    ins  5  len[0] = 4 fr
        .byte $2B,$52                       ; G-5    ins  5  len[2] = 8 fr
        .byte $2E,$52                       ; A#5    ins  5  len[2] = 8 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2B,$52                       ; G-5    ins  5  len[2] = 8 fr
        .byte $2A,$52                       ; F#5    ins  5  len[2] = 8 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 8 fr
        .byte $2B,$58                       ; G-5    ins  5  len[8] = 64 fr
        .byte CMD_RETURN

Song04_Noise:
        .byte CMD_CALL,$16,$00,$04          ; Pattern_16, transpose +0, play 4x
        .byte CMD_CALL,$1A,$00,$04          ; Pattern_1A, transpose +0, play 4x
        .byte CMD_CALL,$16,$00,$04          ; Pattern_16, transpose +0, play 4x
        .byte CMD_JUMP
        .word Song04_Noise

Pattern_16:
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte CMD_RETURN

Pattern_1A:
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$56                       ; noise $3E ins 21  len[6] = 32 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte $BE,$54                       ; noise $3E ins 21  len[4] = 16 fr
        .byte CMD_RETURN

;======================================================================
; Song $05
;======================================================================
Song05_Sq1:
        .byte CMD_CALL,$1B,$00,$01          ; Pattern_1B, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song05_Sq1

Pattern_1B:
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte CMD_REST,$0E                  ; rest len[14] = 7 fr
        .byte $1C,$A3                       ; E-4    ins 10  len[3] = 6 fr
        .byte $21,$AE                       ; A-4    ins 10  len[14] = 7 fr
        .byte $24,$A6                       ; C-5    ins 10  len[6] = 20 fr
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte $1D,$A8                       ; F-4    ins 10  len[8] = 40 fr
        .byte $18,$A8                       ; C-4    ins 10  len[8] = 40 fr
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte CMD_REST,$0E                  ; rest len[14] = 7 fr
        .byte $1C,$A3                       ; E-4    ins 10  len[3] = 6 fr
        .byte $21,$AE                       ; A-4    ins 10  len[14] = 7 fr
        .byte $28,$A6                       ; E-5    ins 10  len[6] = 20 fr
        .byte $24,$A6                       ; C-5    ins 10  len[6] = 20 fr
        .byte $27,$AA                       ; D#5    ins 10  len[10] = 80 fr
        .byte $25,$A9                       ; C#5    ins 10  len[9] = 60 fr
        .byte $20,$A6                       ; G#4    ins 10  len[6] = 20 fr
        .byte $23,$AA                       ; B-4    ins 10  len[10] = 80 fr
        .byte $25,$A9                       ; C#5    ins 10  len[9] = 60 fr
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte $24,$AA                       ; C-5    ins 10  len[10] = 80 fr
        .byte $23,$A9                       ; B-4    ins 10  len[9] = 60 fr
        .byte $1E,$A6                       ; F#4    ins 10  len[6] = 20 fr
        .byte $22,$AA                       ; A#4    ins 10  len[10] = 80 fr
        .byte $22,$A9                       ; A#4    ins 10  len[9] = 60 fr
        .byte $1D,$A6                       ; F-4    ins 10  len[6] = 20 fr
        .byte $21,$AA                       ; A-4    ins 10  len[10] = 80 fr
        .byte $20,$AC                       ; G#4    ins 10  len[12] = 160 fr
        .byte CMD_RETURN

Song05_Sq2:
        .byte CMD_CALL,$1C,$00,$01          ; Pattern_1C, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song05_Sq2

Pattern_1C:
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 20 fr
        .byte CMD_REST,$0E                  ; rest len[14] = 7 fr
        .byte $15,$A3                       ; A-3    ins 10  len[3] = 6 fr
        .byte $1C,$AE                       ; E-4    ins 10  len[14] = 7 fr
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 20 fr
        .byte $18,$A6                       ; C-4    ins 10  len[6] = 20 fr
        .byte $18,$A8                       ; C-4    ins 10  len[8] = 40 fr
        .byte $14,$A8                       ; G#3    ins 10  len[8] = 40 fr
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 20 fr
        .byte CMD_REST,$0E                  ; rest len[14] = 7 fr
        .byte $15,$A3                       ; A-3    ins 10  len[3] = 6 fr
        .byte $1C,$AE                       ; E-4    ins 10  len[14] = 7 fr
        .byte $24,$A6                       ; C-5    ins 10  len[6] = 20 fr
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte $24,$AA                       ; C-5    ins 10  len[10] = 80 fr
        .byte $1D,$A9                       ; F-4    ins 10  len[9] = 60 fr
        .byte $19,$A6                       ; C#4    ins 10  len[6] = 20 fr
        .byte $20,$A8                       ; G#4    ins 10  len[8] = 40 fr
        .byte $1C,$A6                       ; E-4    ins 10  len[6] = 20 fr
        .byte $21,$A6                       ; A-4    ins 10  len[6] = 20 fr
        .byte $1D,$A9                       ; F-4    ins 10  len[9] = 60 fr
        .byte $1B,$A6                       ; D#4    ins 10  len[6] = 20 fr
        .byte $20,$AA                       ; G#4    ins 10  len[10] = 80 fr
        .byte $1E,$A9                       ; F#4    ins 10  len[9] = 60 fr
        .byte $17,$A6                       ; B-3    ins 10  len[6] = 20 fr
        .byte $1D,$AA                       ; F-4    ins 10  len[10] = 80 fr
        .byte $1D,$A9                       ; F-4    ins 10  len[9] = 60 fr
        .byte $16,$A6                       ; A#3    ins 10  len[6] = 20 fr
        .byte $1B,$AA                       ; D#4    ins 10  len[10] = 80 fr
        .byte $1C,$AC                       ; E-4    ins 10  len[12] = 160 fr
        .byte CMD_RETURN

Song05_Tri:
        .byte CMD_CALL,$1D,$0C,$01          ; Pattern_1D, transpose +12, play 1x
        .byte CMD_JUMP
        .word Song05_Tri

Pattern_1D:
        .byte $15,$D6                       ; A-3    ins 13  len[6] = 20 fr
        .byte $24,$DE                       ; C-5    ins 13  len[14] = 7 fr
        .byte $24,$D3                       ; C-5    ins 13  len[3] = 6 fr
        .byte $24,$DE                       ; C-5    ins 13  len[14] = 7 fr
        .byte $21,$D6                       ; A-4    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte $11,$D6                       ; F-3    ins 13  len[6] = 20 fr
        .byte $20,$DE                       ; G#4    ins 13  len[14] = 7 fr
        .byte $20,$D3                       ; G#4    ins 13  len[3] = 6 fr
        .byte $20,$DE                       ; G#4    ins 13  len[14] = 7 fr
        .byte $1D,$D6                       ; F-4    ins 13  len[6] = 20 fr
        .byte $11,$D6                       ; F-3    ins 13  len[6] = 20 fr
        .byte $15,$D6                       ; A-3    ins 13  len[6] = 20 fr
        .byte $24,$DE                       ; C-5    ins 13  len[14] = 7 fr
        .byte $24,$D3                       ; C-5    ins 13  len[3] = 6 fr
        .byte $24,$DE                       ; C-5    ins 13  len[14] = 7 fr
        .byte $21,$D6                       ; A-4    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte $11,$D6                       ; F-3    ins 13  len[6] = 20 fr
        .byte $20,$DE                       ; G#4    ins 13  len[14] = 7 fr
        .byte $20,$D3                       ; G#4    ins 13  len[3] = 6 fr
        .byte $20,$DE                       ; G#4    ins 13  len[14] = 7 fr
        .byte $1D,$D6                       ; F-4    ins 13  len[6] = 20 fr
        .byte $11,$D6                       ; F-3    ins 13  len[6] = 20 fr
        .byte $16,$D6                       ; A#3    ins 13  len[6] = 20 fr
        .byte $25,$DE                       ; C#5    ins 13  len[14] = 7 fr
        .byte $25,$D3                       ; C#5    ins 13  len[3] = 6 fr
        .byte $25,$DE                       ; C#5    ins 13  len[14] = 7 fr
        .byte $22,$D6                       ; A#4    ins 13  len[6] = 20 fr
        .byte $1D,$D6                       ; F-4    ins 13  len[6] = 20 fr
        .byte $1C,$D6                       ; E-4    ins 13  len[6] = 20 fr
        .byte $10,$DE                       ; E-3    ins 13  len[14] = 7 fr
        .byte $10,$D3                       ; E-3    ins 13  len[3] = 6 fr
        .byte $10,$DE                       ; E-3    ins 13  len[14] = 7 fr
        .byte $14,$D6                       ; G#3    ins 13  len[6] = 20 fr
        .byte $17,$D6                       ; B-3    ins 13  len[6] = 20 fr
        .byte $16,$D6                       ; A#3    ins 13  len[6] = 20 fr
        .byte $25,$DE                       ; C#5    ins 13  len[14] = 7 fr
        .byte $25,$D3                       ; C#5    ins 13  len[3] = 6 fr
        .byte $25,$DE                       ; C#5    ins 13  len[14] = 7 fr
        .byte $22,$D6                       ; A#4    ins 13  len[6] = 20 fr
        .byte $1D,$D6                       ; F-4    ins 13  len[6] = 20 fr
        .byte $1C,$D6                       ; E-4    ins 13  len[6] = 20 fr
        .byte $10,$DE                       ; E-3    ins 13  len[14] = 7 fr
        .byte $10,$D3                       ; E-3    ins 13  len[3] = 6 fr
        .byte $10,$DE                       ; E-3    ins 13  len[14] = 7 fr
        .byte $14,$D6                       ; G#3    ins 13  len[6] = 20 fr
        .byte $17,$D6                       ; B-3    ins 13  len[6] = 20 fr
        .byte $0F,$D6                       ; D#3    ins 13  len[6] = 20 fr
        .byte $1B,$DE                       ; D#4    ins 13  len[14] = 7 fr
        .byte $1B,$D3                       ; D#4    ins 13  len[3] = 6 fr
        .byte $1B,$DE                       ; D#4    ins 13  len[14] = 7 fr
        .byte $1B,$D6                       ; D#4    ins 13  len[6] = 20 fr
        .byte $0F,$D6                       ; D#3    ins 13  len[6] = 20 fr
        .byte $0E,$D6                       ; D-3    ins 13  len[6] = 20 fr
        .byte $1A,$DE                       ; D-4    ins 13  len[14] = 7 fr
        .byte $1A,$D3                       ; D-4    ins 13  len[3] = 6 fr
        .byte $1A,$DE                       ; D-4    ins 13  len[14] = 7 fr
        .byte $1A,$D6                       ; D-4    ins 13  len[6] = 20 fr
        .byte $0E,$D6                       ; D-3    ins 13  len[6] = 20 fr
        .byte $0D,$D6                       ; C#3    ins 13  len[6] = 20 fr
        .byte $19,$DE                       ; C#4    ins 13  len[14] = 7 fr
        .byte $19,$D3                       ; C#4    ins 13  len[3] = 6 fr
        .byte $19,$DE                       ; C#4    ins 13  len[14] = 7 fr
        .byte $19,$D6                       ; C#4    ins 13  len[6] = 20 fr
        .byte $0D,$D6                       ; C#3    ins 13  len[6] = 20 fr
        .byte $0C,$D6                       ; C-3    ins 13  len[6] = 20 fr
        .byte $18,$DE                       ; C-4    ins 13  len[14] = 7 fr
        .byte $18,$D3                       ; C-4    ins 13  len[3] = 6 fr
        .byte $18,$DE                       ; C-4    ins 13  len[14] = 7 fr
        .byte $18,$D6                       ; C-4    ins 13  len[6] = 20 fr
        .byte $0C,$D6                       ; C-3    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte $23,$DE                       ; B-4    ins 13  len[14] = 7 fr
        .byte $23,$D3                       ; B-4    ins 13  len[3] = 6 fr
        .byte $23,$DE                       ; B-4    ins 13  len[14] = 7 fr
        .byte $1C,$D6                       ; E-4    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte $23,$DE                       ; B-4    ins 13  len[14] = 7 fr
        .byte $23,$D3                       ; B-4    ins 13  len[3] = 6 fr
        .byte $23,$DE                       ; B-4    ins 13  len[14] = 7 fr
        .byte $1C,$D6                       ; E-4    ins 13  len[6] = 20 fr
        .byte $10,$D6                       ; E-3    ins 13  len[6] = 20 fr
        .byte CMD_RETURN

Song05_Noise:
        .byte CMD_CALL,$1E,$00,$07          ; Pattern_1E, transpose +0, play 7x
        .byte CMD_JUMP
        .word Song05_Noise

Pattern_1E:
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 10 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 10 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 10 fr
        .byte $4D,$E2                       ; noise $4D ins 14  len[2] = 5 fr
        .byte $4D,$E2                       ; noise $4D ins 14  len[2] = 5 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E3                       ; noise $4D ins 14  len[3] = 6 fr
        .byte $4D,$EE                       ; noise $4D ins 14  len[14] = 7 fr
        .byte $4D,$E6                       ; noise $4D ins 14  len[6] = 20 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 10 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 10 fr
        .byte CMD_RETURN

;======================================================================
; Song $06
;======================================================================
Song06_Sq1:
        .byte CMD_CALL,$1F,$00,$01          ; Pattern_1F, transpose +0, play 1x
        .byte CMD_CALL,$1F,$02,$01          ; Pattern_1F, transpose +2, play 1x
        .byte CMD_JUMP
        .word Song06_Sq1

Pattern_1F:
        .byte $00,$2F                       ; C-2    ins  2  len[15] = 40 fr
        .byte $03,$24                       ; D#2    ins  2  len[4] = 8 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0C,$24                       ; C-3    ins  2  len[4] = 8 fr
        .byte $0B,$26                       ; B-2    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $05,$26                       ; F-2    ins  2  len[6] = 16 fr
        .byte $02,$26                       ; D-2    ins  2  len[6] = 16 fr
        .byte $00,$2F                       ; C-2    ins  2  len[15] = 40 fr
        .byte $03,$24                       ; D#2    ins  2  len[4] = 8 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0F,$24                       ; D#3    ins  2  len[4] = 8 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $0B,$26                       ; B-2    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $05,$26                       ; F-2    ins  2  len[6] = 16 fr
        .byte $03,$2F                       ; D#2    ins  2  len[15] = 40 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0C,$24                       ; C-3    ins  2  len[4] = 8 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 8 fr
        .byte $12,$26                       ; F#3    ins  2  len[6] = 16 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $09,$26                       ; A-2    ins  2  len[6] = 16 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $0F,$26                       ; D#3    ins  2  len[6] = 16 fr
        .byte $0C,$26                       ; C-3    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $0C,$26                       ; C-3    ins  2  len[6] = 16 fr
        .byte $09,$2A                       ; A-2    ins  2  len[10] = 64 fr
        .byte $00,$2F                       ; C-2    ins  2  len[15] = 40 fr
        .byte $03,$B4                       ; D#2    ins 11  len[4] = 8 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0C,$24                       ; C-3    ins  2  len[4] = 8 fr
        .byte $0B,$26                       ; B-2    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $05,$26                       ; F-2    ins  2  len[6] = 16 fr
        .byte $02,$26                       ; D-2    ins  2  len[6] = 16 fr
        .byte $00,$2F                       ; C-2    ins  2  len[15] = 40 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0C,$24                       ; C-3    ins  2  len[4] = 8 fr
        .byte $0F,$24                       ; D#3    ins  2  len[4] = 8 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $0B,$26                       ; B-2    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $05,$26                       ; F-2    ins  2  len[6] = 16 fr
        .byte $03,$2F                       ; D#2    ins  2  len[15] = 40 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 8 fr
        .byte $0C,$24                       ; C-3    ins  2  len[4] = 8 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 8 fr
        .byte $12,$26                       ; F#3    ins  2  len[6] = 16 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $09,$26                       ; A-2    ins  2  len[6] = 16 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $0F,$26                       ; D#3    ins  2  len[6] = 16 fr
        .byte $0C,$26                       ; C-3    ins  2  len[6] = 16 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 16 fr
        .byte $0C,$26                       ; C-3    ins  2  len[6] = 16 fr
        .byte $0E,$26                       ; D-3    ins  2  len[6] = 16 fr
        .byte $09,$26                       ; A-2    ins  2  len[6] = 16 fr
        .byte $06,$26                       ; F#2    ins  2  len[6] = 16 fr
        .byte $09,$26                       ; A-2    ins  2  len[6] = 16 fr
        .byte $07,$2A                       ; G-2    ins  2  len[10] = 64 fr
        .byte $13,$2A                       ; G-3    ins  2  len[10] = 64 fr
        .byte CMD_RETURN

Song06_Sq2:
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$07,$01          ; Pattern_23, transpose +7, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$07,$01          ; Pattern_23, transpose +7, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$0E,$01          ; Pattern_23, transpose +14, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$0E,$01          ; Pattern_23, transpose +14, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$07,$01          ; Pattern_23, transpose +7, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$07,$01          ; Pattern_23, transpose +7, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$0E,$01          ; Pattern_23, transpose +14, play 1x
        .byte CMD_CALL,$20,$0C,$01          ; Pattern_20, transpose +12, play 1x
        .byte CMD_CALL,$23,$0E,$01          ; Pattern_23, transpose +14, play 1x
        .byte CMD_CALL,$23,$07,$02          ; Pattern_23, transpose +7, play 2x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$09,$01          ; Pattern_23, transpose +9, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$09,$01          ; Pattern_23, transpose +9, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$10,$01          ; Pattern_23, transpose +16, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$10,$01          ; Pattern_23, transpose +16, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$09,$01          ; Pattern_23, transpose +9, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$09,$01          ; Pattern_23, transpose +9, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$10,$01          ; Pattern_23, transpose +16, play 1x
        .byte CMD_CALL,$20,$0E,$01          ; Pattern_20, transpose +14, play 1x
        .byte CMD_CALL,$23,$10,$01          ; Pattern_23, transpose +16, play 1x
        .byte CMD_CALL,$23,$09,$02          ; Pattern_23, transpose +9, play 2x
        .byte CMD_JUMP
        .word Song06_Sq2

Pattern_20:
        .byte $00,$61                       ; C-2    ins  6  len[1] = 3 fr
        .byte $03,$61                       ; D#2    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $0F,$60                       ; D#3    ins  6  len[0] = 2 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $18,$61                       ; C-4    ins  6  len[1] = 3 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $0F,$60                       ; D#3    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $03,$61                       ; D#2    ins  6  len[1] = 3 fr
        .byte $00,$61                       ; C-2    ins  6  len[1] = 3 fr
        .byte $03,$61                       ; D#2    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $0F,$60                       ; D#3    ins  6  len[0] = 2 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $18,$61                       ; C-4    ins  6  len[1] = 3 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $0F,$60                       ; D#3    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $03,$61                       ; D#2    ins  6  len[1] = 3 fr
        .byte CMD_RETURN

Pattern_23:
        .byte $00,$61                       ; C-2    ins  6  len[1] = 3 fr
        .byte $04,$61                       ; E-2    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $10,$60                       ; E-3    ins  6  len[0] = 2 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $18,$61                       ; C-4    ins  6  len[1] = 3 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $10,$60                       ; E-3    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $04,$61                       ; E-2    ins  6  len[1] = 3 fr
        .byte $00,$61                       ; C-2    ins  6  len[1] = 3 fr
        .byte $04,$61                       ; E-2    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $10,$60                       ; E-3    ins  6  len[0] = 2 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $18,$61                       ; C-4    ins  6  len[1] = 3 fr
        .byte $13,$61                       ; G-3    ins  6  len[1] = 3 fr
        .byte $10,$60                       ; E-3    ins  6  len[0] = 2 fr
        .byte $0C,$61                       ; C-3    ins  6  len[1] = 3 fr
        .byte $07,$60                       ; G-2    ins  6  len[0] = 2 fr
        .byte $04,$61                       ; E-2    ins  6  len[1] = 3 fr
        .byte CMD_RETURN

Song06_Tri:
        .byte CMD_CALL,$21,$24,$01          ; Pattern_21, transpose +36, play 1x
        .byte CMD_CALL,$21,$26,$01          ; Pattern_21, transpose +38, play 1x
        .byte CMD_JUMP
        .word Song06_Tri

Pattern_21:
        .byte $00,$5F                       ; C-2    ins  5  len[15] = 40 fr
        .byte $03,$54                       ; D#2    ins  5  len[4] = 8 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 8 fr
        .byte $0B,$56                       ; B-2    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $05,$56                       ; F-2    ins  5  len[6] = 16 fr
        .byte $02,$56                       ; D-2    ins  5  len[6] = 16 fr
        .byte $00,$5F                       ; C-2    ins  5  len[15] = 40 fr
        .byte $03,$54                       ; D#2    ins  5  len[4] = 8 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0F,$54                       ; D#3    ins  5  len[4] = 8 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $0B,$56                       ; B-2    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $05,$56                       ; F-2    ins  5  len[6] = 16 fr
        .byte $03,$5F                       ; D#2    ins  5  len[15] = 40 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 8 fr
        .byte $13,$54                       ; G-3    ins  5  len[4] = 8 fr
        .byte $12,$56                       ; F#3    ins  5  len[6] = 16 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $09,$56                       ; A-2    ins  5  len[6] = 16 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $0F,$56                       ; D#3    ins  5  len[6] = 16 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 16 fr
        .byte $09,$5A                       ; A-2    ins  5  len[10] = 64 fr
        .byte $00,$5F                       ; C-2    ins  5  len[15] = 40 fr
        .byte $03,$54                       ; D#2    ins  5  len[4] = 8 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 8 fr
        .byte $0B,$56                       ; B-2    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $05,$56                       ; F-2    ins  5  len[6] = 16 fr
        .byte $02,$56                       ; D-2    ins  5  len[6] = 16 fr
        .byte $00,$5F                       ; C-2    ins  5  len[15] = 40 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 8 fr
        .byte $0F,$54                       ; D#3    ins  5  len[4] = 8 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $0B,$56                       ; B-2    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $05,$56                       ; F-2    ins  5  len[6] = 16 fr
        .byte $03,$5F                       ; D#2    ins  5  len[15] = 40 fr
        .byte $07,$54                       ; G-2    ins  5  len[4] = 8 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 8 fr
        .byte $13,$54                       ; G-3    ins  5  len[4] = 8 fr
        .byte $12,$56                       ; F#3    ins  5  len[6] = 16 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $09,$56                       ; A-2    ins  5  len[6] = 16 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $0F,$56                       ; D#3    ins  5  len[6] = 16 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 16 fr
        .byte $07,$56                       ; G-2    ins  5  len[6] = 16 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 16 fr
        .byte $0E,$56                       ; D-3    ins  5  len[6] = 16 fr
        .byte $09,$56                       ; A-2    ins  5  len[6] = 16 fr
        .byte $06,$56                       ; F#2    ins  5  len[6] = 16 fr
        .byte $09,$56                       ; A-2    ins  5  len[6] = 16 fr
        .byte $07,$5A                       ; G-2    ins  5  len[10] = 64 fr
        .byte $13,$5A                       ; G-3    ins  5  len[10] = 64 fr
        .byte CMD_RETURN

Song06_Noise:
        .byte CMD_CALL,$22,$00,$12          ; Pattern_22, transpose +0, play 18x
        .byte CMD_CALL,$22,$00,$12          ; Pattern_22, transpose +0, play 18x
        .byte CMD_JUMP
        .word Song06_Noise

Pattern_22:
        .byte $4F,$F6                       ; noise $4F ins 15  len[6] = 16 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte $4D,$E4                       ; noise $4D ins 14  len[4] = 8 fr
        .byte CMD_RETURN

;======================================================================
; Song $07
;======================================================================
Song07_Sq1:
        .byte CMD_CALL,$24,$00,$01          ; Pattern_24, transpose +0, play 1x
        .byte CMD_CALL,$24,$02,$01          ; Pattern_24, transpose +2, play 1x
        .byte CMD_CALL,$24,$04,$01          ; Pattern_24, transpose +4, play 1x
        .byte CMD_JUMP
        .word Song07_Sq1

Pattern_24:
        .byte $89,$36                       ; A-2    ins 19  len[6] = 24 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $8C,$32                       ; C-3    ins 19  len[2] = 6 fr
        .byte $90,$32                       ; E-3    ins 19  len[2] = 6 fr
        .byte $91,$36                       ; F-3    ins 19  len[6] = 24 fr
        .byte $90,$36                       ; E-3    ins 19  len[6] = 24 fr
        .byte $88,$38                       ; G#2    ins 19  len[8] = 48 fr
        .byte $84,$38                       ; E-2    ins 19  len[8] = 48 fr
        .byte $89,$36                       ; A-2    ins 19  len[6] = 24 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $8C,$32                       ; C-3    ins 19  len[2] = 6 fr
        .byte $90,$32                       ; E-3    ins 19  len[2] = 6 fr
        .byte $91,$36                       ; F-3    ins 19  len[6] = 24 fr
        .byte $90,$36                       ; E-3    ins 19  len[6] = 24 fr
        .byte $88,$38                       ; G#2    ins 19  len[8] = 48 fr
        .byte $84,$38                       ; E-2    ins 19  len[8] = 48 fr
        .byte $89,$39                       ; A-2    ins 19  len[9] = 72 fr
        .byte $84,$36                       ; E-2    ins 19  len[6] = 24 fr
        .byte $88,$39                       ; G#2    ins 19  len[9] = 72 fr
        .byte $81,$36                       ; C#2    ins 19  len[6] = 24 fr
        .byte $89,$39                       ; A-2    ins 19  len[9] = 72 fr
        .byte $84,$36                       ; E-2    ins 19  len[6] = 24 fr
        .byte $88,$38                       ; G#2    ins 19  len[8] = 48 fr
        .byte $81,$38                       ; C#2    ins 19  len[8] = 48 fr
        .byte $80,$3A                       ; C-2    ins 19  len[10] = 96 fr
        .byte $80,$3A                       ; C-2    ins 19  len[10] = 96 fr
        .byte CMD_RETURN

Song07_Sq2:
        .byte CMD_CALL,$25,$00,$01          ; Pattern_25, transpose +0, play 1x
        .byte CMD_CALL,$25,$02,$01          ; Pattern_25, transpose +2, play 1x
        .byte CMD_CALL,$25,$04,$01          ; Pattern_25, transpose +4, play 1x
        .byte CMD_JUMP
        .word Song07_Sq2

Pattern_25:
        .byte $A1,$18                       ; A-4    ins 17  len[8] = 48 fr
        .byte $95,$18                       ; A-3    ins 17  len[8] = 48 fr
        .byte $9C,$08                       ; E-4    ins 16  len[8] = 48 fr
        .byte $90,$08                       ; E-3    ins 16  len[8] = 48 fr
        .byte $A1,$18                       ; A-4    ins 17  len[8] = 48 fr
        .byte $95,$18                       ; A-3    ins 17  len[8] = 48 fr
        .byte $9C,$08                       ; E-4    ins 16  len[8] = 48 fr
        .byte $90,$08                       ; E-3    ins 16  len[8] = 48 fr
        .byte $95,$18                       ; A-3    ins 17  len[8] = 48 fr
        .byte $A1,$18                       ; A-4    ins 17  len[8] = 48 fr
        .byte $8D,$08                       ; C#3    ins 16  len[8] = 48 fr
        .byte $99,$08                       ; C#4    ins 16  len[8] = 48 fr
        .byte $95,$18                       ; A-3    ins 17  len[8] = 48 fr
        .byte $A1,$18                       ; A-4    ins 17  len[8] = 48 fr
        .byte $8D,$08                       ; C#3    ins 16  len[8] = 48 fr
        .byte $99,$08                       ; C#4    ins 16  len[8] = 48 fr
        .byte $8C,$06                       ; C-3    ins 16  len[6] = 24 fr
        .byte $98,$06                       ; C-4    ins 16  len[6] = 24 fr
        .byte $A4,$06                       ; C-5    ins 16  len[6] = 24 fr
        .byte $98,$06                       ; C-4    ins 16  len[6] = 24 fr
        .byte $8C,$0A                       ; C-3    ins 16  len[10] = 96 fr
        .byte CMD_RETURN

Song07_Tri:
        .byte CMD_CALL,$26,$18,$01          ; Pattern_26, transpose +24, play 1x
        .byte CMD_CALL,$26,$1A,$01          ; Pattern_26, transpose +26, play 1x
        .byte CMD_CALL,$26,$1C,$01          ; Pattern_26, transpose +28, play 1x
        .byte CMD_JUMP
        .word Song07_Tri

Pattern_26:
        .byte $89,$26                       ; A-2    ins 18  len[6] = 24 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $8C,$22                       ; C-3    ins 18  len[2] = 6 fr
        .byte $90,$22                       ; E-3    ins 18  len[2] = 6 fr
        .byte $91,$26                       ; F-3    ins 18  len[6] = 24 fr
        .byte $90,$26                       ; E-3    ins 18  len[6] = 24 fr
        .byte $88,$28                       ; G#2    ins 18  len[8] = 48 fr
        .byte $84,$28                       ; E-2    ins 18  len[8] = 48 fr
        .byte $89,$26                       ; A-2    ins 18  len[6] = 24 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $8C,$22                       ; C-3    ins 18  len[2] = 6 fr
        .byte $90,$22                       ; E-3    ins 18  len[2] = 6 fr
        .byte $91,$26                       ; F-3    ins 18  len[6] = 24 fr
        .byte $90,$26                       ; E-3    ins 18  len[6] = 24 fr
        .byte $88,$28                       ; G#2    ins 18  len[8] = 48 fr
        .byte $84,$28                       ; E-2    ins 18  len[8] = 48 fr
        .byte $89,$29                       ; A-2    ins 18  len[9] = 72 fr
        .byte $84,$26                       ; E-2    ins 18  len[6] = 24 fr
        .byte $88,$29                       ; G#2    ins 18  len[9] = 72 fr
        .byte $81,$26                       ; C#2    ins 18  len[6] = 24 fr
        .byte $89,$29                       ; A-2    ins 18  len[9] = 72 fr
        .byte $84,$26                       ; E-2    ins 18  len[6] = 24 fr
        .byte $88,$28                       ; G#2    ins 18  len[8] = 48 fr
        .byte $81,$28                       ; C#2    ins 18  len[8] = 48 fr
        .byte $80,$2A                       ; C-2    ins 18  len[10] = 96 fr
        .byte $80,$2A                       ; C-2    ins 18  len[10] = 96 fr
        .byte CMD_RETURN

Song07_Noise:
        .byte CMD_END

;======================================================================
; Song $08
;======================================================================
Song08_Sq1:
        .byte CMD_CALL,$27,$00,$01          ; Pattern_27, transpose +0, play 1x
        .byte CMD_CALL,$2C,$00,$01          ; Pattern_2C, transpose +0, play 1x
        .byte CMD_CALL,$27,$00,$01          ; Pattern_27, transpose +0, play 1x
        .byte CMD_REST,$08                  ; rest len[8] = 80 fr
        .byte $B0,$38                       ; C-6    ins 19  len[8] = 80 fr
        .byte CMD_END

Pattern_27:
        .byte $A4,$37                       ; C-5    ins 19  len[7] = 60 fr
        .byte $A6,$32                       ; D-5    ins 19  len[2] = 10 fr
        .byte $A8,$32                       ; E-5    ins 19  len[2] = 10 fr
        .byte $9F,$37                       ; G-4    ins 19  len[7] = 60 fr
        .byte $A1,$32                       ; A-4    ins 19  len[2] = 10 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A4,$37                       ; C-5    ins 19  len[7] = 60 fr
        .byte $A4,$32                       ; C-5    ins 19  len[2] = 10 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A3,$36                       ; B-4    ins 19  len[6] = 40 fr
        .byte $A1,$34                       ; A-4    ins 19  len[4] = 20 fr
        .byte $9F,$32                       ; G-4    ins 19  len[2] = 10 fr
        .byte $9D,$32                       ; F-4    ins 19  len[2] = 10 fr
        .byte $9F,$37                       ; G-4    ins 19  len[7] = 60 fr
        .byte $A6,$32                       ; D-5    ins 19  len[2] = 10 fr
        .byte $A8,$32                       ; E-5    ins 19  len[2] = 10 fr
        .byte $9F,$37                       ; G-4    ins 19  len[7] = 60 fr
        .byte $A1,$32                       ; A-4    ins 19  len[2] = 10 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A4,$37                       ; C-5    ins 19  len[7] = 60 fr
        .byte $A4,$32                       ; C-5    ins 19  len[2] = 10 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A3,$36                       ; B-4    ins 19  len[6] = 40 fr
        .byte $A1,$34                       ; A-4    ins 19  len[4] = 20 fr
        .byte $9F,$32                       ; G-4    ins 19  len[2] = 10 fr
        .byte $9D,$32                       ; F-4    ins 19  len[2] = 10 fr
        .byte $9C,$38                       ; E-4    ins 19  len[8] = 80 fr
        .byte CMD_RETURN

Pattern_2C:
        .byte CMD_REST,$04                  ; rest len[4] = 20 fr
        .byte $A8,$34                       ; E-5    ins 19  len[4] = 20 fr
        .byte $AB,$35                       ; G-5    ins 19  len[5] = 30 fr
        .byte $A9,$32                       ; F-5    ins 19  len[2] = 10 fr
        .byte $A8,$35                       ; E-5    ins 19  len[5] = 30 fr
        .byte $A6,$32                       ; D-5    ins 19  len[2] = 10 fr
        .byte $A1,$37                       ; A-4    ins 19  len[7] = 60 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A4,$32                       ; C-5    ins 19  len[2] = 10 fr
        .byte $A6,$35                       ; D-5    ins 19  len[5] = 30 fr
        .byte $A9,$32                       ; F-5    ins 19  len[2] = 10 fr
        .byte $A8,$38                       ; E-5    ins 19  len[8] = 80 fr
        .byte CMD_REST,$04                  ; rest len[4] = 20 fr
        .byte $A4,$32                       ; C-5    ins 19  len[2] = 10 fr
        .byte $A6,$32                       ; D-5    ins 19  len[2] = 10 fr
        .byte $A8,$35                       ; E-5    ins 19  len[5] = 30 fr
        .byte $A8,$32                       ; E-5    ins 19  len[2] = 10 fr
        .byte $A8,$35                       ; E-5    ins 19  len[5] = 30 fr
        .byte $A6,$32                       ; D-5    ins 19  len[2] = 10 fr
        .byte $A6,$37                       ; D-5    ins 19  len[7] = 60 fr
        .byte $A1,$32                       ; A-4    ins 19  len[2] = 10 fr
        .byte $A3,$32                       ; B-4    ins 19  len[2] = 10 fr
        .byte $A4,$34                       ; C-5    ins 19  len[4] = 20 fr
        .byte $A6,$34                       ; D-5    ins 19  len[4] = 20 fr
        .byte $A6,$39                       ; D-5    ins 19  len[9] = 120 fr
        .byte CMD_REST,$06                  ; rest len[6] = 40 fr
        .byte CMD_RETURN

Song08_Sq2:
        .byte CMD_CALL,$28,$F4,$01          ; Pattern_28, transpose -12, play 1x
        .byte CMD_CALL,$28,$EF,$01          ; Pattern_28, transpose -17, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$28,$ED,$01          ; Pattern_28, transpose -19, play 1x
        .byte CMD_CALL,$28,$F4,$01          ; Pattern_28, transpose -12, play 1x
        .byte CMD_CALL,$28,$EF,$01          ; Pattern_28, transpose -17, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$28,$ED,$01          ; Pattern_28, transpose -19, play 1x
        .byte CMD_CALL,$28,$F4,$02          ; Pattern_28, transpose -12, play 2x
        .byte CMD_CALL,$2A,$F6,$01          ; Pattern_2A, transpose -10, play 1x
        .byte CMD_CALL,$28,$F8,$01          ; Pattern_28, transpose -8, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$2A,$F6,$01          ; Pattern_2A, transpose -10, play 1x
        .byte CMD_CALL,$28,$F6,$01          ; Pattern_28, transpose -10, play 1x
        .byte CMD_CALL,$28,$F2,$01          ; Pattern_28, transpose -14, play 1x
        .byte CMD_CALL,$28,$EF,$01          ; Pattern_28, transpose -17, play 1x
        .byte CMD_CALL,$28,$F4,$01          ; Pattern_28, transpose -12, play 1x
        .byte CMD_CALL,$28,$EF,$01          ; Pattern_28, transpose -17, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$28,$ED,$01          ; Pattern_28, transpose -19, play 1x
        .byte CMD_CALL,$28,$F4,$01          ; Pattern_28, transpose -12, play 1x
        .byte CMD_CALL,$28,$EF,$01          ; Pattern_28, transpose -17, play 1x
        .byte CMD_CALL,$2A,$F1,$01          ; Pattern_2A, transpose -15, play 1x
        .byte CMD_CALL,$28,$ED,$01          ; Pattern_28, transpose -19, play 1x
        .byte CMD_CALL,$28,$F4,$02          ; Pattern_28, transpose -12, play 2x
        .byte $A8,$38                       ; E-5    ins 19  len[8] = 80 fr
        .byte CMD_END

Pattern_28:
        .byte $18,$10                       ; C-4    ins  1  len[0] = 5 fr
        .byte $1C,$10                       ; E-4    ins  1  len[0] = 5 fr
        .byte $1F,$10                       ; G-4    ins  1  len[0] = 5 fr
        .byte $24,$10                       ; C-5    ins  1  len[0] = 5 fr
        .byte $28,$10                       ; E-5    ins  1  len[0] = 5 fr
        .byte $2B,$10                       ; G-5    ins  1  len[0] = 5 fr
        .byte $30,$10                       ; C-6    ins  1  len[0] = 5 fr
        .byte $34,$10                       ; E-6    ins  1  len[0] = 5 fr
        .byte $37,$10                       ; G-6    ins  1  len[0] = 5 fr
        .byte $34,$10                       ; E-6    ins  1  len[0] = 5 fr
        .byte $30,$10                       ; C-6    ins  1  len[0] = 5 fr
        .byte $2B,$10                       ; G-5    ins  1  len[0] = 5 fr
        .byte $28,$10                       ; E-5    ins  1  len[0] = 5 fr
        .byte $24,$10                       ; C-5    ins  1  len[0] = 5 fr
        .byte $1F,$10                       ; G-4    ins  1  len[0] = 5 fr
        .byte $1C,$10                       ; E-4    ins  1  len[0] = 5 fr
        .byte CMD_RETURN

Pattern_2A:
        .byte $18,$10                       ; C-4    ins  1  len[0] = 5 fr
        .byte $1B,$10                       ; D#4    ins  1  len[0] = 5 fr
        .byte $1F,$10                       ; G-4    ins  1  len[0] = 5 fr
        .byte $24,$10                       ; C-5    ins  1  len[0] = 5 fr
        .byte $27,$10                       ; D#5    ins  1  len[0] = 5 fr
        .byte $2B,$10                       ; G-5    ins  1  len[0] = 5 fr
        .byte $30,$10                       ; C-6    ins  1  len[0] = 5 fr
        .byte $33,$10                       ; D#6    ins  1  len[0] = 5 fr
        .byte $37,$10                       ; G-6    ins  1  len[0] = 5 fr
        .byte $33,$10                       ; D#6    ins  1  len[0] = 5 fr
        .byte $30,$10                       ; C-6    ins  1  len[0] = 5 fr
        .byte $2B,$10                       ; G-5    ins  1  len[0] = 5 fr
        .byte $27,$10                       ; D#5    ins  1  len[0] = 5 fr
        .byte $24,$10                       ; C-5    ins  1  len[0] = 5 fr
        .byte $1F,$10                       ; G-4    ins  1  len[0] = 5 fr
        .byte $1C,$10                       ; E-4    ins  1  len[0] = 5 fr
        .byte CMD_RETURN

Song08_Tri:
        .byte CMD_CALL,$29,$00,$01          ; Pattern_29, transpose +0, play 1x
        .byte CMD_CALL,$2D,$00,$01          ; Pattern_2D, transpose +0, play 1x
        .byte CMD_CALL,$29,$00,$01          ; Pattern_29, transpose +0, play 1x
        .byte $24,$58                       ; C-5    ins  5  len[8] = 80 fr
        .byte CMD_END

Pattern_29:
        .byte $24,$54                       ; C-5    ins  5  len[4] = 20 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 20 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 40 fr
        .byte $2B,$56                       ; G-5    ins  5  len[6] = 40 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 40 fr
        .byte $2D,$54                       ; A-5    ins  5  len[4] = 20 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 20 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 40 fr
        .byte $1D,$56                       ; F-4    ins  5  len[6] = 40 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 40 fr
        .byte $24,$58                       ; C-5    ins  5  len[8] = 80 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 40 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 20 fr
        .byte $2B,$54                       ; G-5    ins  5  len[4] = 20 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 40 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 40 fr
        .byte $29,$56                       ; F-5    ins  5  len[6] = 40 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 20 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 20 fr
        .byte $18,$58                       ; C-4    ins  5  len[8] = 80 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 20 fr
        .byte $18,$47                       ; C-4    ins  4  len[7] = 60 fr
        .byte CMD_RETURN

Pattern_2D:
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $28,$58                       ; E-5    ins  5  len[8] = 80 fr
        .byte $21,$55                       ; A-4    ins  5  len[5] = 30 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 10 fr
        .byte $21,$55                       ; A-4    ins  5  len[5] = 30 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 10 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 80 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 30 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 10 fr
        .byte $22,$55                       ; A#4    ins  5  len[5] = 30 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 10 fr
        .byte $22,$55                       ; A#4    ins  5  len[5] = 30 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 10 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 30 fr
        .byte $1A,$52                       ; D-4    ins  5  len[2] = 10 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 40 fr
        .byte CMD_RETURN

Song08_Noise:
        .byte CMD_CALL,$2B,$00,$38          ; Pattern_2B, transpose +0, play 56x
        .byte CMD_END

Pattern_2B:
        .byte $4D,$E2                       ; noise $4D ins 14  len[2] = 10 fr
        .byte $4D,$E2                       ; noise $4D ins 14  len[2] = 10 fr
        .byte $CA,$42                       ; noise $4A ins 20  len[2] = 10 fr
        .byte $4D,$E2                       ; noise $4D ins 14  len[2] = 10 fr
        .byte CMD_RETURN

;
; Pattern (subroutine) pointers, used by CMD_CALL (46 entries, split low/high byte tables)
PatternLo:
        .lobytes Pattern_00, Pattern_01, Pattern_02, Pattern_03 ; 0-3
        .lobytes Pattern_04, Pattern_05, Pattern_06, Pattern_07 ; 4-7
        .lobytes Pattern_08, Pattern_09, Pattern_0A, Pattern_0B ; 8-11
        .lobytes Pattern_0C, Pattern_0D, Pattern_0E, Pattern_0F ; 12-15
        .lobytes Pattern_10, Pattern_11, Pattern_12, Pattern_13 ; 16-19
        .lobytes Pattern_14, Pattern_15, Pattern_16, Pattern_17 ; 20-23
        .lobytes Pattern_18, Pattern_19, Pattern_1A, Pattern_1B ; 24-27
        .lobytes Pattern_1C, Pattern_1D, Pattern_1E, Pattern_1F ; 28-31
        .lobytes Pattern_20, Pattern_21, Pattern_22, Pattern_23 ; 32-35
        .lobytes Pattern_24, Pattern_25, Pattern_26, Pattern_27 ; 36-39
        .lobytes Pattern_28, Pattern_29, Pattern_2A, Pattern_2B ; 40-43
        .lobytes Pattern_2C, Pattern_2D     ; 44-45

PatternHi:
        .hibytes Pattern_00, Pattern_01, Pattern_02, Pattern_03 ; 0-3
        .hibytes Pattern_04, Pattern_05, Pattern_06, Pattern_07 ; 4-7
        .hibytes Pattern_08, Pattern_09, Pattern_0A, Pattern_0B ; 8-11
        .hibytes Pattern_0C, Pattern_0D, Pattern_0E, Pattern_0F ; 12-15
        .hibytes Pattern_10, Pattern_11, Pattern_12, Pattern_13 ; 16-19
        .hibytes Pattern_14, Pattern_15, Pattern_16, Pattern_17 ; 20-23
        .hibytes Pattern_18, Pattern_19, Pattern_1A, Pattern_1B ; 24-27
        .hibytes Pattern_1C, Pattern_1D, Pattern_1E, Pattern_1F ; 28-31
        .hibytes Pattern_20, Pattern_21, Pattern_22, Pattern_23 ; 32-35
        .hibytes Pattern_24, Pattern_25, Pattern_26, Pattern_27 ; 36-39
        .hibytes Pattern_28, Pattern_29, Pattern_2A, Pattern_2B ; 40-43
        .hibytes Pattern_2C, Pattern_2D     ; 44-45

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
        bcs L96A9
        tax
        lda sNewPriority
        cmp sPriority,x
        bcs L9652
        pla
        rts

L9652:
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

L96A9:
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
        beq L96C8
        dec sTimer,x
        rts

L96C8:
        lda sSpeed,x
        sta sTimer,x
        lda sPtrHi,x
        bne L96D4
        rts

L96D4:
        sta zPtr+1
        lda sPtrLo,x
        sta zPtr
        ldy #$00
        tya
        sta mRegDirty,x
        lda (zPtr),y
        ldy ChanRegOfs,x
        sta SQ1_VOL,y
        ldy #$01
        lda (zPtr),y
        cmp #$FF
        bne L96FC
        ldy sPriority,x
        lda sId,x
        tax
        tya
        jmp Sfx_Play

L96FC:
        cpx #$03
        bne L9718
        cmp mReg2,x
        beq L973B
        sta mReg2,x
        lda #$00
        sta mReg3,x
        lda mRegDirty,x
        ora #$03
        sta mRegDirty,x
        jmp L973B

L9718:
        cmp mReg3,x
        beq L9728
        sta mReg3,x
        lda mRegDirty,x
        ora #$01
        sta mRegDirty,x

L9728:
        iny
        lda (zPtr),y
        cmp mReg2,x
        beq L973B
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

L973B:
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
        and ChanDisableMask,x
        sta APU_STATUS
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
; Sound effect pointers (index passed in X to Sfx_Play) (47 entries, split low/high byte tables)
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
        .hibytes Sfx_28, Sfx_29, Sfx_2A, Sfx_2B ; 40-43
        .hibytes Sfx_2C, Sfx_2D, Sfx_2E     ; 44-46

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
        .lobytes Sfx_28, Sfx_29, Sfx_2A, Sfx_2B ; 40-43
        .lobytes Sfx_2C, Sfx_2D, Sfx_2E     ; 44-46

Sfx_29:
        .byte $00                           ; channel: Sq1
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_2A:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_2B:
        .byte $02                           ; channel: Tri
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_2C:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $10,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_02:
        .byte $03                           ; channel: Noise
        .byte $0A                           ; speed (frames per step - 1)
        .byte $22,$02,$0F                   ; reg0, reg3, reg2
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_03:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $38,$00,$3C                   ; reg0, reg3, reg2
        .byte $36,$00,$3B                   ; reg0, reg3, reg2
        .byte $35,$00,$3A                   ; reg0, reg3, reg2
        .byte $34,$00,$39                   ; reg0, reg3, reg2
        .byte $34,$00,$38                   ; reg0, reg3, reg2
        .byte $34,$00,$3C                   ; reg0, reg3, reg2
        .byte $33,$00,$3D                   ; reg0, reg3, reg2
        .byte $33,$00,$3E                   ; reg0, reg3, reg2
        .byte $34,$00,$3F                   ; reg0, reg3, reg2
        .byte $33,$00,$01                   ; reg0, reg3, reg2
        .byte $32,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_01:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $32,$00,$0C                   ; reg0, reg3, reg2
        .byte $3C,$09                       ; reg0, period
        .byte $35,$0A                       ; reg0, period
        .byte $31,$0B                       ; reg0, period
        .byte $31,$0C                       ; reg0, period
        .byte $30,$00                       ; reg0, period -> end
; ---- 7 byte(s) not referenced by the sound engine ----
        .byte $30,$00,$30,$00,$30,$00,$00

Sfx_25:
        .byte $03                           ; channel: Noise
        .byte $05                           ; speed (frames per step - 1)
        .byte $36,$00,$0A                   ; reg0, reg3, reg2
        .byte $36,$0B                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0E                       ; reg0, period
        .byte $00,$10                       ; reg0, period
        .byte $A8,$0D                       ; reg0, period
        .byte $A8,$0E                       ; reg0, period
        .byte $A8,$0F                       ; reg0, period
        .byte $A8,$0F                       ; reg0, period
        .byte $A8,$0F                       ; reg0, period
        .byte $A8,$0F                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_26:
        .byte $00                           ; channel: Sq1
        .byte $02                           ; speed (frames per step - 1)
        .byte $A0,$00,$71                   ; reg0, reg3, reg2
        .byte $A0,$00,$32                   ; reg0, reg3, reg2
        .byte $A0,$00,$38                   ; reg0, reg3, reg2
        .byte $A0,$00,$3F                   ; reg0, reg3, reg2
        .byte $A0,$00,$47                   ; reg0, reg3, reg2
        .byte $A0,$00,$50                   ; reg0, reg3, reg2
        .byte $A0,$00,$59                   ; reg0, reg3, reg2
        .byte $A0,$00,$64                   ; reg0, reg3, reg2
        .byte $A0,$10,$00                   ; reg0, reg3, reg2
        .byte $A0,$10,$00                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $A8,$06,$AE                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_15:
        .byte $03                           ; channel: Noise
        .byte $12                           ; speed (frames per step - 1)
        .byte $32,$00,$0E                   ; reg0, reg3, reg2
        .byte $33,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $00,$FF                       ; restart effect

Sfx_16:
        .byte $01                           ; channel: Sq2
        .byte $06                           ; speed (frames per step - 1)
        .byte $B1,$02,$80                   ; reg0, reg3, reg2
        .byte $B1,$02,$78                   ; reg0, reg3, reg2
        .byte $B1,$02,$82                   ; reg0, reg3, reg2
        .byte $B1,$02,$8C                   ; reg0, reg3, reg2
        .byte $B1,$02,$96                   ; reg0, reg3, reg2
        .byte $B1,$02,$8C                   ; reg0, reg3, reg2
        .byte $B1,$02,$82                   ; reg0, reg3, reg2
        .byte $B1,$02,$78                   ; reg0, reg3, reg2
        .byte $B1,$02,$6E                   ; reg0, reg3, reg2
        .byte $B1,$02,$64                   ; reg0, reg3, reg2
        .byte $B1,$02,$5E                   ; reg0, reg3, reg2
        .byte $B1,$02,$58                   ; reg0, reg3, reg2
        .byte $B1,$02,$52                   ; reg0, reg3, reg2
        .byte $B1,$02,$4C                   ; reg0, reg3, reg2
        .byte $B1,$02,$46                   ; reg0, reg3, reg2
        .byte $B1,$02,$40                   ; reg0, reg3, reg2
        .byte $B1,$02,$4A                   ; reg0, reg3, reg2
        .byte $B1,$02,$54                   ; reg0, reg3, reg2
        .byte $B1,$02,$5E                   ; reg0, reg3, reg2
        .byte $B1,$02,$68                   ; reg0, reg3, reg2
        .byte $B1,$02,$72                   ; reg0, reg3, reg2
        .byte $B1,$02,$7C                   ; reg0, reg3, reg2
        .byte $B1,$02,$68                   ; reg0, reg3, reg2
        .byte $B1,$02,$7C                   ; reg0, reg3, reg2
        .byte $B1,$02,$86                   ; reg0, reg3, reg2
        .byte $B1,$02,$9A                   ; reg0, reg3, reg2
        .byte $B1,$02,$AE                   ; reg0, reg3, reg2
        .byte $B1,$02,$B8                   ; reg0, reg3, reg2
        .byte $B1,$02,$A4                   ; reg0, reg3, reg2
        .byte $B1,$02,$90                   ; reg0, reg3, reg2
        .byte $B1,$02,$7C                   ; reg0, reg3, reg2
        .byte $B1,$02,$90                   ; reg0, reg3, reg2
        .byte $B1,$02,$A4                   ; reg0, reg3, reg2
        .byte $B1,$02,$B8                   ; reg0, reg3, reg2
        .byte $B1,$02,$CC                   ; reg0, reg3, reg2
        .byte $B1,$02,$E0                   ; reg0, reg3, reg2
        .byte $B1,$02,$F4                   ; reg0, reg3, reg2
        .byte $B1,$02,$CC                   ; reg0, reg3, reg2
        .byte $B1,$02,$B8                   ; reg0, reg3, reg2
        .byte $B1,$02,$A4                   ; reg0, reg3, reg2
        .byte $B1,$02,$90                   ; reg0, reg3, reg2
        .byte $B1,$02,$72                   ; reg0, reg3, reg2
        .byte $00,$FF                       ; restart effect
        .byte $00                           ; never read

Sfx_17:
        .byte $03                           ; channel: Noise
        .byte $0C                           ; speed (frames per step - 1)
        .byte $32,$00,$0D                   ; reg0, reg3, reg2
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $36,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $32,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $00,$FF                       ; restart effect
        .byte $00                           ; never read

Sfx_18:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; speed (frames per step - 1)
        .byte $B1,$02,$80                   ; reg0, reg3, reg2
        .byte $B1,$01,$78                   ; reg0, reg3, reg2
        .byte $B1,$01,$82                   ; reg0, reg3, reg2
        .byte $B1,$01,$8C                   ; reg0, reg3, reg2
        .byte $B1,$01,$96                   ; reg0, reg3, reg2
        .byte $B1,$01,$8C                   ; reg0, reg3, reg2
        .byte $B1,$01,$82                   ; reg0, reg3, reg2
        .byte $B1,$01,$78                   ; reg0, reg3, reg2
        .byte $B1,$01,$6E                   ; reg0, reg3, reg2
        .byte $B1,$01,$64                   ; reg0, reg3, reg2
        .byte $B1,$01,$5E                   ; reg0, reg3, reg2
        .byte $B1,$01,$58                   ; reg0, reg3, reg2
        .byte $B1,$01,$52                   ; reg0, reg3, reg2
        .byte $B1,$01,$4C                   ; reg0, reg3, reg2
        .byte $B1,$01,$46                   ; reg0, reg3, reg2
        .byte $B1,$01,$40                   ; reg0, reg3, reg2
        .byte $B1,$01,$4A                   ; reg0, reg3, reg2
        .byte $B1,$01,$54                   ; reg0, reg3, reg2
        .byte $B1,$01,$5E                   ; reg0, reg3, reg2
        .byte $B1,$01,$68                   ; reg0, reg3, reg2
        .byte $B1,$01,$72                   ; reg0, reg3, reg2
        .byte $B1,$01,$7C                   ; reg0, reg3, reg2
        .byte $B1,$01,$68                   ; reg0, reg3, reg2
        .byte $B1,$01,$7C                   ; reg0, reg3, reg2
        .byte $B1,$01,$86                   ; reg0, reg3, reg2
        .byte $B1,$01,$9A                   ; reg0, reg3, reg2
        .byte $B1,$01,$AE                   ; reg0, reg3, reg2
        .byte $B1,$01,$B8                   ; reg0, reg3, reg2
        .byte $B1,$01,$A4                   ; reg0, reg3, reg2
        .byte $B1,$01,$90                   ; reg0, reg3, reg2
        .byte $B1,$01,$7C                   ; reg0, reg3, reg2
        .byte $B1,$01,$90                   ; reg0, reg3, reg2
        .byte $B1,$01,$A4                   ; reg0, reg3, reg2
        .byte $B1,$01,$B8                   ; reg0, reg3, reg2
        .byte $B1,$01,$CC                   ; reg0, reg3, reg2
        .byte $B1,$01,$E0                   ; reg0, reg3, reg2
        .byte $B1,$01,$F4                   ; reg0, reg3, reg2
        .byte $B1,$01,$CC                   ; reg0, reg3, reg2
        .byte $B1,$01,$B8                   ; reg0, reg3, reg2
        .byte $B1,$01,$A4                   ; reg0, reg3, reg2
        .byte $B1,$01,$90                   ; reg0, reg3, reg2
        .byte $B1,$01,$72                   ; reg0, reg3, reg2
        .byte $00,$FF                       ; restart effect
        .byte $00                           ; never read

Sfx_19:
        .byte $03                           ; channel: Noise
        .byte $0C                           ; speed (frames per step - 1)
        .byte $34,$00,$0B                   ; reg0, reg3, reg2
        .byte $36,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $39,$0B                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $34,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $34,$0B                       ; reg0, period
        .byte $34,$0B                       ; reg0, period
        .byte $00,$FF                       ; restart effect

Sfx_1A:
        .byte $01                           ; channel: Sq2
        .byte $04                           ; speed (frames per step - 1)
        .byte $B1,$02,$80                   ; reg0, reg3, reg2
        .byte $B2,$00,$BC                   ; reg0, reg3, reg2
        .byte $B2,$00,$C1                   ; reg0, reg3, reg2
        .byte $B2,$00,$C6                   ; reg0, reg3, reg2
        .byte $B2,$00,$CB                   ; reg0, reg3, reg2
        .byte $B2,$00,$C6                   ; reg0, reg3, reg2
        .byte $B2,$00,$C1                   ; reg0, reg3, reg2
        .byte $B2,$00,$BC                   ; reg0, reg3, reg2
        .byte $B2,$00,$B7                   ; reg0, reg3, reg2
        .byte $B2,$00,$B2                   ; reg0, reg3, reg2
        .byte $B2,$00,$AF                   ; reg0, reg3, reg2
        .byte $B2,$00,$AC                   ; reg0, reg3, reg2
        .byte $B2,$00,$A9                   ; reg0, reg3, reg2
        .byte $B2,$00,$A6                   ; reg0, reg3, reg2
        .byte $B2,$00,$A3                   ; reg0, reg3, reg2
        .byte $B2,$00,$A0                   ; reg0, reg3, reg2
        .byte $B2,$00,$A5                   ; reg0, reg3, reg2
        .byte $B2,$00,$AA                   ; reg0, reg3, reg2
        .byte $B2,$00,$AF                   ; reg0, reg3, reg2
        .byte $B2,$00,$B4                   ; reg0, reg3, reg2
        .byte $B2,$00,$B9                   ; reg0, reg3, reg2
        .byte $B2,$00,$BE                   ; reg0, reg3, reg2
        .byte $B2,$00,$B4                   ; reg0, reg3, reg2
        .byte $B2,$00,$BE                   ; reg0, reg3, reg2
        .byte $B2,$00,$C3                   ; reg0, reg3, reg2
        .byte $B2,$00,$CD                   ; reg0, reg3, reg2
        .byte $B2,$00,$D7                   ; reg0, reg3, reg2
        .byte $B2,$00,$DC                   ; reg0, reg3, reg2
        .byte $B2,$00,$D7                   ; reg0, reg3, reg2
        .byte $B2,$00,$D2                   ; reg0, reg3, reg2
        .byte $B2,$00,$CD                   ; reg0, reg3, reg2
        .byte $B2,$00,$C8                   ; reg0, reg3, reg2
        .byte $B2,$00,$CD                   ; reg0, reg3, reg2
        .byte $B2,$00,$D2                   ; reg0, reg3, reg2
        .byte $B2,$00,$D7                   ; reg0, reg3, reg2
        .byte $B2,$00,$DC                   ; reg0, reg3, reg2
        .byte $B2,$00,$E1                   ; reg0, reg3, reg2
        .byte $B2,$00,$D7                   ; reg0, reg3, reg2
        .byte $B2,$00,$D2                   ; reg0, reg3, reg2
        .byte $B2,$00,$CD                   ; reg0, reg3, reg2
        .byte $B2,$00,$C8                   ; reg0, reg3, reg2
        .byte $B2,$00,$C3                   ; reg0, reg3, reg2
        .byte $B2,$00,$BE                   ; reg0, reg3, reg2
        .byte $00,$FF                       ; restart effect
        .byte $00                           ; never read

Sfx_1B:
        .byte $03                           ; channel: Noise
        .byte $03                           ; speed (frames per step - 1)
        .byte $32,$00,$0C                   ; reg0, reg3, reg2
        .byte $33,$0C                       ; reg0, period
        .byte $34,$0C                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $34,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $39,$0B                       ; reg0, period
        .byte $3B,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_1C:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; speed (frames per step - 1)
        .byte $B1,$01,$96                   ; reg0, reg3, reg2
        .byte $B2,$01,$8C                   ; reg0, reg3, reg2
        .byte $B2,$01,$82                   ; reg0, reg3, reg2
        .byte $B2,$01,$78                   ; reg0, reg3, reg2
        .byte $B2,$01,$6E                   ; reg0, reg3, reg2
        .byte $B2,$01,$64                   ; reg0, reg3, reg2
        .byte $B2,$01,$5A                   ; reg0, reg3, reg2
        .byte $B2,$01,$50                   ; reg0, reg3, reg2
        .byte $B2,$01,$46                   ; reg0, reg3, reg2
        .byte $B2,$01,$3C                   ; reg0, reg3, reg2
        .byte $B2,$01,$32                   ; reg0, reg3, reg2
        .byte $B2,$01,$28                   ; reg0, reg3, reg2
        .byte $B2,$01,$1E                   ; reg0, reg3, reg2
        .byte $B2,$01,$14                   ; reg0, reg3, reg2
        .byte $B2,$01,$0A                   ; reg0, reg3, reg2
        .byte $B2,$01,$00                   ; reg0, reg3, reg2
        .byte $B2,$00,$F0                   ; reg0, reg3, reg2
        .byte $B2,$00,$E6                   ; reg0, reg3, reg2
        .byte $B2,$00,$DC                   ; reg0, reg3, reg2
        .byte $B2,$00,$D2                   ; reg0, reg3, reg2
        .byte $B3,$00,$C8                   ; reg0, reg3, reg2
        .byte $B3,$00,$BE                   ; reg0, reg3, reg2
        .byte $B3,$00,$B4                   ; reg0, reg3, reg2
        .byte $B4,$00,$AA                   ; reg0, reg3, reg2
        .byte $B4,$00,$AF                   ; reg0, reg3, reg2
        .byte $B3,$00,$B4                   ; reg0, reg3, reg2
        .byte $B2,$00,$B9                   ; reg0, reg3, reg2
        .byte $B2,$00,$BE                   ; reg0, reg3, reg2
        .byte $B1,$00,$C3                   ; reg0, reg3, reg2
        .byte $B2,$00,$C8                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_1D:
        .byte $03                           ; channel: Noise
        .byte $03                           ; speed (frames per step - 1)
        .byte $34,$00,$0B                   ; reg0, reg3, reg2
        .byte $36,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $37,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $35,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $36,$0B                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $35,$0E                       ; reg0, period
        .byte $35,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_1E:
        .byte $00                           ; channel: Sq1
        .byte $02                           ; speed (frames per step - 1)
        .byte $B2,$00,$BE                   ; reg0, reg3, reg2
        .byte $B2,$00,$C8                   ; reg0, reg3, reg2
        .byte $B2,$00,$C3                   ; reg0, reg3, reg2
        .byte $B2,$00,$C8                   ; reg0, reg3, reg2
        .byte $B2,$00,$CD                   ; reg0, reg3, reg2
        .byte $B2,$00,$D2                   ; reg0, reg3, reg2
        .byte $B2,$00,$D7                   ; reg0, reg3, reg2
        .byte $B2,$00,$E1                   ; reg0, reg3, reg2
        .byte $B2,$00,$EB                   ; reg0, reg3, reg2
        .byte $B2,$00,$F5                   ; reg0, reg3, reg2
        .byte $B2,$00,$FA                   ; reg0, reg3, reg2
        .byte $B2,$01,$00                   ; reg0, reg3, reg2
        .byte $B2,$01,$14                   ; reg0, reg3, reg2
        .byte $B2,$01,$28                   ; reg0, reg3, reg2
        .byte $B2,$01,$3C                   ; reg0, reg3, reg2
        .byte $B2,$01,$46                   ; reg0, reg3, reg2
        .byte $B2,$01,$4B                   ; reg0, reg3, reg2
        .byte $B1,$01,$50                   ; reg0, reg3, reg2
        .byte $B1,$01,$55                   ; reg0, reg3, reg2
        .byte $B1,$01,$5A                   ; reg0, reg3, reg2
        .byte $B1,$01,$64                   ; reg0, reg3, reg2
        .byte $B1,$01,$6E                   ; reg0, reg3, reg2
        .byte $B1,$01,$78                   ; reg0, reg3, reg2
        .byte $B1,$01,$82                   ; reg0, reg3, reg2
        .byte $B1,$01,$8C                   ; reg0, reg3, reg2
        .byte $B1,$01,$A0                   ; reg0, reg3, reg2
        .byte $B1,$01,$AA                   ; reg0, reg3, reg2
        .byte $B1,$01,$BE                   ; reg0, reg3, reg2
        .byte $B1,$01,$C8                   ; reg0, reg3, reg2
        .byte $B1,$01,$F0                   ; reg0, reg3, reg2
        .byte $B1,$02,$00                   ; reg0, reg3, reg2
        .byte $B1,$02,$0A                   ; reg0, reg3, reg2
        .byte $B1,$02,$00                   ; reg0, reg3, reg2
        .byte $B1,$02,$0A                   ; reg0, reg3, reg2
        .byte $B1,$02,$14                   ; reg0, reg3, reg2
        .byte $B1,$02,$28                   ; reg0, reg3, reg2
        .byte $B1,$02,$B4                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_11:
        .byte $03                           ; channel: Noise
        .byte $02                           ; speed (frames per step - 1)
        .byte $3F,$00,$0A                   ; reg0, reg3, reg2
        .byte $3D,$0A                       ; reg0, period
        .byte $3B,$0B                       ; reg0, period
        .byte $3A,$0B                       ; reg0, period
        .byte $37,$0C                       ; reg0, period
        .byte $32,$0C                       ; reg0, period
        .byte $32,$0D                       ; reg0, period
        .byte $32,$0D                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $31,$0E                       ; reg0, period
        .byte $31,$0F                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_10:
        .byte $03                           ; channel: Noise
        .byte $04                           ; speed (frames per step - 1)
        .byte $A7,$00,$0E                   ; reg0, reg3, reg2
        .byte $A7,$0D                       ; reg0, period
        .byte $A7,$0E                       ; reg0, period
        .byte $A7,$0C                       ; reg0, period
        .byte $A7,$0D                       ; reg0, period
        .byte $A7,$0D                       ; reg0, period
        .byte $A7,$0D                       ; reg0, period
        .byte $A7,$0D                       ; reg0, period
        .byte $A7,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_0F:
        .byte $03                           ; channel: Noise
        .byte $01                           ; speed (frames per step - 1)
        .byte $33,$00,$0A                   ; reg0, reg3, reg2
        .byte $35,$09                       ; reg0, period
        .byte $37,$08                       ; reg0, period
        .byte $3B,$08                       ; reg0, period
        .byte $3F,$08                       ; reg0, period
        .byte $31,$0B                       ; reg0, period
        .byte $33,$0A                       ; reg0, period
        .byte $35,$09                       ; reg0, period
        .byte $37,$08                       ; reg0, period
        .byte $39,$08                       ; reg0, period
        .byte $31,$0C                       ; reg0, period
        .byte $33,$0B                       ; reg0, period
        .byte $35,$0A                       ; reg0, period
        .byte $37,$09                       ; reg0, period
        .byte $39,$08                       ; reg0, period
        .byte $31,$0C                       ; reg0, period
        .byte $32,$0B                       ; reg0, period
        .byte $34,$0A                       ; reg0, period
        .byte $36,$09                       ; reg0, period
        .byte $38,$08                       ; reg0, period
        .byte $31,$0C                       ; reg0, period
        .byte $32,$0B                       ; reg0, period
        .byte $34,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_12:
        .byte $00                           ; channel: Sq1
        .byte $1E                           ; speed (frames per step - 1)
        .byte $A7,$00,$28                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_13:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $A0,$00,$D5                   ; reg0, reg3, reg2
        .byte $A0,$00,$8E                   ; reg0, reg3, reg2
        .byte $A0,$00,$A9                   ; reg0, reg3, reg2
        .byte $A0,$00,$6A                   ; reg0, reg3, reg2
        .byte $A0,$00,$35                   ; reg0, reg3, reg2
        .byte $A0,$00,$35                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_04:
        .byte $03                           ; channel: Noise
        .byte $02                           ; speed (frames per step - 1)
        .byte $A2,$00,$0D                   ; reg0, reg3, reg2
        .byte $A2,$05                       ; reg0, period
        .byte $A2,$08                       ; reg0, period
        .byte $A2,$0E                       ; reg0, period
        .byte $A2,$0F                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_00:
Sfx_14:
        .byte $03                           ; channel: Noise
        .byte $02                           ; speed (frames per step - 1)
        .byte $32,$00,$0B                   ; reg0, reg3, reg2
        .byte $33,$0A                       ; reg0, period
        .byte $34,$09                       ; reg0, period
        .byte $35,$08                       ; reg0, period
        .byte $36,$07                       ; reg0, period
        .byte $37,$06                       ; reg0, period
        .byte $38,$05                       ; reg0, period
        .byte $37,$06                       ; reg0, period
        .byte $36,$07                       ; reg0, period
        .byte $35,$08                       ; reg0, period
        .byte $34,$09                       ; reg0, period
        .byte $33,$08                       ; reg0, period
        .byte $32,$09                       ; reg0, period
        .byte $32,$0A                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end

Sfx_1F:
        .byte $00                           ; channel: Sq1
        .byte $0B                           ; speed (frames per step - 1)
        .byte $B8,$02,$80                   ; reg0, reg3, reg2
        .byte $B8,$02,$1A                   ; reg0, reg3, reg2
        .byte $B8,$01,$7C                   ; reg0, reg3, reg2
        .byte $B8,$01,$93                   ; reg0, reg3, reg2
        .byte $B8,$01,$93                   ; reg0, reg3, reg2
        .byte $B8,$01,$93                   ; reg0, reg3, reg2
        .byte $B8,$01,$AB                   ; reg0, reg3, reg2
        .byte $B8,$01,$AB                   ; reg0, reg3, reg2
        .byte $B8,$01,$AB                   ; reg0, reg3, reg2
        .byte $B8,$01,$C4                   ; reg0, reg3, reg2
        .byte $B8,$01,$C4                   ; reg0, reg3, reg2
        .byte $B8,$01,$C4                   ; reg0, reg3, reg2
        .byte $B8,$01,$DF                   ; reg0, reg3, reg2
        .byte $B8,$01,$DF                   ; reg0, reg3, reg2
        .byte $B8,$01,$DF                   ; reg0, reg3, reg2
        .byte $B8,$01,$DF                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_20:
        .byte $01                           ; channel: Sq2
        .byte $23                           ; speed (frames per step - 1)
        .byte $B8,$05,$F3                   ; reg0, reg3, reg2
        .byte $B8,$05,$9E                   ; reg0, reg3, reg2
        .byte $B8,$04,$B9                   ; reg0, reg3, reg2
        .byte $B8,$05,$01                   ; reg0, reg3, reg2
        .byte $B8,$05,$4D                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_21:
        .byte $02                           ; channel: Tri
        .byte $96                           ; speed (frames per step - 1)
        .byte $00,$00,$00                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_22:
        .byte $03                           ; channel: Noise
        .byte $96                           ; speed (frames per step - 1)
        .byte $00,$00,$00                   ; reg0, reg3, reg2
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_23:
        .byte $00                           ; channel: Sq1
        .byte $0B                           ; speed (frames per step - 1)
        .byte $38,$01,$53                   ; reg0, reg3, reg2
        .byte $3F,$01,$52                   ; reg0, reg3, reg2
        .byte $38,$01,$7C                   ; reg0, reg3, reg2
        .byte $2F,$00,$FE                   ; reg0, reg3, reg2
        .byte $2F,$00,$FE                   ; reg0, reg3, reg2
        .byte $2F,$00,$FE                   ; reg0, reg3, reg2
        .byte $2F,$00,$FE                   ; reg0, reg3, reg2
        .byte $2F,$00,$FE                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_24:
        .byte $01                           ; channel: Sq2
        .byte $0B                           ; speed (frames per step - 1)
        .byte $38,$01,$AB                   ; reg0, reg3, reg2
        .byte $38,$01,$AC                   ; reg0, reg3, reg2
        .byte $38,$01,$FC                   ; reg0, reg3, reg2
        .byte $2F,$01,$7C                   ; reg0, reg3, reg2
        .byte $2F,$01,$7C                   ; reg0, reg3, reg2
        .byte $2F,$01,$7C                   ; reg0, reg3, reg2
        .byte $2F,$01,$7C                   ; reg0, reg3, reg2
        .byte $2F,$01,$7C                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_06:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $B4,$00,$50                   ; reg0, reg3, reg2
        .byte $B0,$00,$50                   ; reg0, reg3, reg2
        .byte $B4,$00,$54                   ; reg0, reg3, reg2
        .byte $B0,$00,$54                   ; reg0, reg3, reg2
        .byte $B4,$00,$58                   ; reg0, reg3, reg2
        .byte $B0,$00,$58                   ; reg0, reg3, reg2
        .byte $B4,$00,$5C                   ; reg0, reg3, reg2
        .byte $B0,$00,$5C                   ; reg0, reg3, reg2
        .byte $B4,$00,$60                   ; reg0, reg3, reg2
        .byte $B0,$00,$60                   ; reg0, reg3, reg2
        .byte $B4,$00,$64                   ; reg0, reg3, reg2
        .byte $B0,$00,$64                   ; reg0, reg3, reg2
        .byte $B4,$00,$68                   ; reg0, reg3, reg2
        .byte $B0,$00,$68                   ; reg0, reg3, reg2
        .byte $B4,$00,$6C                   ; reg0, reg3, reg2
        .byte $B0,$00,$6C                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_07:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $B4,$00,$6C                   ; reg0, reg3, reg2
        .byte $B0,$00,$6C                   ; reg0, reg3, reg2
        .byte $B4,$00,$68                   ; reg0, reg3, reg2
        .byte $B0,$00,$68                   ; reg0, reg3, reg2
        .byte $B4,$00,$64                   ; reg0, reg3, reg2
        .byte $B0,$00,$64                   ; reg0, reg3, reg2
        .byte $B4,$00,$60                   ; reg0, reg3, reg2
        .byte $B0,$00,$60                   ; reg0, reg3, reg2
        .byte $B4,$00,$5C                   ; reg0, reg3, reg2
        .byte $B0,$00,$5C                   ; reg0, reg3, reg2
        .byte $B4,$00,$58                   ; reg0, reg3, reg2
        .byte $B0,$00,$58                   ; reg0, reg3, reg2
        .byte $B4,$00,$54                   ; reg0, reg3, reg2
        .byte $B0,$00,$54                   ; reg0, reg3, reg2
        .byte $B4,$00,$50                   ; reg0, reg3, reg2
        .byte $B0,$00,$50                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_08:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $39,$02,$30                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $37,$02,$10                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_09:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; speed (frames per step - 1)
        .byte $37,$02,$20                   ; reg0, reg3, reg2
        .byte $37,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$30                   ; reg0, reg3, reg2
        .byte $37,$02,$40                   ; reg0, reg3, reg2
        .byte $38,$02,$30                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $36,$02,$10                   ; reg0, reg3, reg2
        .byte $36,$02,$00                   ; reg0, reg3, reg2
        .byte $38,$02,$10                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $38,$02,$20                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_05:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$06                   ; reg0, reg3, reg2
        .byte $3C,$06                       ; reg0, period
        .byte $3F,$06                       ; reg0, period
        .byte $3A,$06                       ; reg0, period
        .byte $38,$06                       ; reg0, period
        .byte $36,$06                       ; reg0, period
        .byte $35,$06                       ; reg0, period
        .byte $34,$06                       ; reg0, period
        .byte $34,$06                       ; reg0, period
        .byte $33,$06                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $35,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $35,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $35,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $34,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $34,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $34,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $33,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $33,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $33,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $32,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $32,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $32,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $30,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $30,$06                       ; reg0, period
        .byte $31,$06                       ; reg0, period
        .byte $30,$06                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_0A:
        .byte $02                           ; channel: Tri
        .byte $02                           ; speed (frames per step - 1)
        .byte $FF,$02,$40                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$02,$20                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$40                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$20                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$40                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$20                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$40                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $FF,$01,$20                   ; reg0, reg3, reg2
        .byte $FF,$01,$30                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_0B:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $B9,$06,$FF                   ; reg0, reg3, reg2
        .byte $BC,$06,$80                   ; reg0, reg3, reg2
        .byte $BC,$06,$00                   ; reg0, reg3, reg2
        .byte $BC,$05,$C0                   ; reg0, reg3, reg2
        .byte $BC,$05,$80                   ; reg0, reg3, reg2
        .byte $BC,$05,$40                   ; reg0, reg3, reg2
        .byte $BC,$05,$00                   ; reg0, reg3, reg2
        .byte $BC,$04,$C0                   ; reg0, reg3, reg2
        .byte $BC,$04,$80                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_0C:
        .byte $03                           ; channel: Noise
        .byte $02                           ; speed (frames per step - 1)
        .byte $34,$00,$0A                   ; reg0, reg3, reg2
        .byte $32,$09                       ; reg0, period
        .byte $34,$09                       ; reg0, period
        .byte $36,$0A                       ; reg0, period
        .byte $38,$0A                       ; reg0, period
        .byte $30,$05                       ; reg0, period
        .byte $30,$05                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_0D:
        .byte $02                           ; channel: Tri
        .byte $00                           ; speed (frames per step - 1)
        .byte $FF,$00,$20                   ; reg0, reg3, reg2
        .byte $FF,$00,$20                   ; reg0, reg3, reg2
        .byte $FF,$00,$1F                   ; reg0, reg3, reg2
        .byte $FF,$00,$21                   ; reg0, reg3, reg2
        .byte $FF,$00,$20                   ; reg0, reg3, reg2
        .byte $FF,$00,$22                   ; reg0, reg3, reg2
        .byte $FF,$00,$21                   ; reg0, reg3, reg2
        .byte $FF,$00,$24                   ; reg0, reg3, reg2
        .byte $FF,$00,$23                   ; reg0, reg3, reg2
        .byte $FF,$00,$26                   ; reg0, reg3, reg2
        .byte $FF,$00,$25                   ; reg0, reg3, reg2
        .byte $FF,$00,$28                   ; reg0, reg3, reg2
        .byte $FF,$00,$27                   ; reg0, reg3, reg2
        .byte $FF,$00,$2A                   ; reg0, reg3, reg2
        .byte $FF,$00,$29                   ; reg0, reg3, reg2
        .byte $FF,$00,$2C                   ; reg0, reg3, reg2
        .byte $FF,$00,$2B                   ; reg0, reg3, reg2
        .byte $FF,$00,$2E                   ; reg0, reg3, reg2
        .byte $FF,$00,$2D                   ; reg0, reg3, reg2
        .byte $FF,$00,$30                   ; reg0, reg3, reg2
        .byte $FF,$00,$2F                   ; reg0, reg3, reg2
        .byte $FF,$00,$32                   ; reg0, reg3, reg2
        .byte $FF,$00,$31                   ; reg0, reg3, reg2
        .byte $FF,$00,$34                   ; reg0, reg3, reg2
        .byte $FF,$00,$33                   ; reg0, reg3, reg2
        .byte $FF,$00,$36                   ; reg0, reg3, reg2
        .byte $FF,$00,$35                   ; reg0, reg3, reg2
        .byte $FF,$00,$38                   ; reg0, reg3, reg2
        .byte $FF,$00,$37                   ; reg0, reg3, reg2
        .byte $FF,$00,$3A                   ; reg0, reg3, reg2
        .byte $FF,$00,$39                   ; reg0, reg3, reg2
        .byte $FF,$00,$3C                   ; reg0, reg3, reg2
        .byte $FF,$00,$3B                   ; reg0, reg3, reg2
        .byte $FF,$00,$40                   ; reg0, reg3, reg2
        .byte $FF,$00,$3E                   ; reg0, reg3, reg2
        .byte $FF,$00,$44                   ; reg0, reg3, reg2
        .byte $FF,$00,$42                   ; reg0, reg3, reg2
        .byte $FF,$00,$48                   ; reg0, reg3, reg2
        .byte $FF,$00,$46                   ; reg0, reg3, reg2
        .byte $FF,$00,$4C                   ; reg0, reg3, reg2
        .byte $FF,$00,$4A                   ; reg0, reg3, reg2
        .byte $FF,$00,$50                   ; reg0, reg3, reg2
        .byte $FF,$00,$4E                   ; reg0, reg3, reg2
        .byte $FF,$00,$54                   ; reg0, reg3, reg2
        .byte $FF,$00,$52                   ; reg0, reg3, reg2
        .byte $FF,$00,$58                   ; reg0, reg3, reg2
        .byte $FF,$00,$56                   ; reg0, reg3, reg2
        .byte $FF,$00,$5C                   ; reg0, reg3, reg2
        .byte $FF,$00,$5A                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_0E:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$0E                   ; reg0, reg3, reg2
        .byte $3F,$0E                       ; reg0, period
        .byte $3D,$0D                       ; reg0, period
        .byte $3C,$0E                       ; reg0, period
        .byte $3A,$0D                       ; reg0, period
        .byte $39,$0C                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $37,$0A                       ; reg0, period
        .byte $36,$0A                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_27:
        .byte $02                           ; channel: Tri
        .byte $00                           ; speed (frames per step - 1)
        .byte $FF,$00,$40                   ; reg0, reg3, reg2
        .byte $FF,$00,$40                   ; reg0, reg3, reg2
        .byte $FF,$00,$40                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end
        .byte $00                           ; never read

Sfx_28:
        .byte $00                           ; channel: Sq1
        .byte $00                           ; speed (frames per step - 1)
        .byte $BF,$06,$80                   ; reg0, reg3, reg2
        .byte $BF,$06,$00                   ; reg0, reg3, reg2
        .byte $BF,$06,$80                   ; reg0, reg3, reg2
        .byte $BF,$06,$00                   ; reg0, reg3, reg2
        .byte $BF,$06,$80                   ; reg0, reg3, reg2
        .byte $BF,$06,$00                   ; reg0, reg3, reg2
        .byte $BF,$06,$80                   ; reg0, reg3, reg2
        .byte $BF,$06,$00                   ; reg0, reg3, reg2
        .byte $BF,$06,$80                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_2D:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $3F,$00,$45                   ; reg0, reg3, reg2
        .byte $3F,$00,$50                   ; reg0, reg3, reg2
        .byte $3F,$00,$60                   ; reg0, reg3, reg2
        .byte $3F,$00,$70                   ; reg0, reg3, reg2
        .byte $3F,$00,$A0                   ; reg0, reg3, reg2
        .byte $3F,$00,$90                   ; reg0, reg3, reg2
        .byte $3F,$00,$A0                   ; reg0, reg3, reg2
        .byte $3F,$00,$B0                   ; reg0, reg3, reg2
        .byte $3F,$00,$C0                   ; reg0, reg3, reg2
        .byte $3F,$00,$D0                   ; reg0, reg3, reg2
        .byte $3F,$00,$E0                   ; reg0, reg3, reg2
        .byte $3F,$00,$F0                   ; reg0, reg3, reg2
        .byte $3F,$01,$00                   ; reg0, reg3, reg2
        .byte $3F,$01,$10                   ; reg0, reg3, reg2
        .byte $3F,$01,$20                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_2E:
        .byte $02                           ; channel: Tri
        .byte $01                           ; speed (frames per step - 1)
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$00,$40                   ; reg0, reg3, reg2
        .byte $08,$80,$4D                   ; reg0, reg3, reg2
        .byte $08,$80,$4D                   ; reg0, reg3, reg2
        .byte $08,$80,$50                   ; reg0, reg3, reg2
        .byte $08,$80,$50                   ; reg0, reg3, reg2
        .byte $08,$80,$50                   ; reg0, reg3, reg2
        .byte $08,$80,$50                   ; reg0, reg3, reg2
        .byte $08,$80,$50                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end
