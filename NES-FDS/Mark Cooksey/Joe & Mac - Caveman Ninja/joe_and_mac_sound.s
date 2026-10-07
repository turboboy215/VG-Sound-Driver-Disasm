;==============================================================================
;  Mark Cooksey NES sound engine - JOE & MAC: CAVEMAN NINJA (E)
;  Later version: adds a 5th track for DMC (PCM samples) and DMC effects.
;
;  Source: Joe & Mac - Caveman Ninja (E) [!].nes, MMC3, PRG 8K bank 11
;  (file offset $16010) at $8000-$9FFF. The samples live in the fixed
;  bank at $C000 (file offset $1C010): see joe_and_mac_dmc_samples.s.
;  Reassembles byte-identically:  ca65 joe_and_mac_sound.s
;                    ld65 -C joe_and_mac_sound.cfg -o out.bin joe_and_mac_sound.o
;
;  ENTRY POINTS (SoundJumpTable, $8000)
;    $8000 Sfx_Init      silence/reset all sound effects
;    $8003 Sfx_Play      A = priority, X = effect number
;    $8006 Sfx_Update    once per frame
;    $8009 Music_Play    A = song; $80 or $82+ = stop, $81 = re-enable
;                        all channels (resume)
;    $800C Music_Update  once per frame
;
;  SONG TABLE: SongLo/SongHi, 6 pointers per song:
;    Sq1, Sq2, Tri, Noise, DMC track, duration table.
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
;      $65 CMD_DMC_END                stop the DMC track
;      $66 CMD_DMC_REST  len          DMC rest (the sample is cut
;                                      whenever a DMC event is read)
;
;  DMC TRACK: same 2-byte events, but
;      byte 0  bits 0-3 = DMC rate (DMC_FREQ); bit 6 is set from the
;                         sample's loop flag
;      byte 1  bits 4-7 = sample number (DmcSampleLo/Hi)
;              bits 0-3 = length index
;    CMD_CALL/CMD_RETURN work on the DMC track. CMD_JUMP re-enters the
;    tone channel routine; this is only safe because every DMC jump
;    target in this game starts with a command (CMD_CALL).
;    Sample definition: loop flag, DMC_START value, DMC_LEN value.
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
;            An effect only starts if its priority > the one playing on that
;            channel (Dragon's Lair: >=). While it plays, the music on that
;            channel keeps running but stops writing to the APU.
;    then every (speed+1) frames one step:
;      square/triangle:  reg0, reg3, reg2     reg3 = reg2 = 0  -> end
;      noise:            reg0, period         period = 0       -> end
;      any channel:      reg0, $FF                             -> restart effect
;    channel >= 4 = DMC effect: DMC_START, DMC_LEN, DMC_FREQ values. It plays
;            once; Sfx_Update gives the DMC back to the music when the sample
;            has finished.
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
mTrkPtrLo            = $0300        ; track pointer low, per channel
mTrkPtrHi            = $0305        ; track pointer high, per channel
mDurTabLo            = $030A        ; duration table pointer (global)
mDurTabHi            = $030B
mNoteTimer           = $030C        ; frames left of the current note
mDmcTimer            = $0310        ; frames left of the DMC event
mVolEnvTimer         = $0311        ; volume envelope
mVolEnvHi            = $0315
mVolEnvLo            = $0319
mPitchEnvTimer       = $031D        ; pitch envelope
mPitchEnvHi          = $0321
mPitchEnvLo          = $0325
mArpEnvTimer         = $0329        ; arpeggio envelope
mArpEnvHi            = $032D
mArpEnvLo            = $0331
mInstTemp            = $0335        ; instrument number / flags while loading
mTranspose           = $0336        ; transpose added to notes (CMD_CALL)
mRetLo               = $033B        ; CMD_CALL return address
mRetHi               = $0340
mLoopCount           = $0345        ; CMD_CALL repeat count
mLoopActive          = $034A        ; nonzero while a CMD_CALL repeats
mChanFlags           = $034F        ; bit 0 = track running, bit 1 = owns the APU (no effect)
mDmcFlags            = $0353        ; mChanFlags for the DMC track
mRegDirty            = $0354        ; bit 0 = reg3, bit 1 = reg2, bit 2 = reg0 need writing
mDmcDirty            = $0358        ; DMC write pending
mNote                = $0359        ; current note (after transpose)
mReg3                = $035D        ; shadow of register 3 (period high, length)
mReg2                = $0361        ; shadow of register 2 (period low)
mReg0                = $0365        ; shadow of register 0 (duty, volume)
mDmcFreq             = $0369        ; shadow DMC_FREQ
mDmcRaw              = $036A        ; (cleared, never written to the APU)
mDmcStart            = $036B        ; shadow DMC_START
mDmcLen              = $036C        ; shadow DMC_LEN
mApuStatus           = $036D        ; shadow APU_STATUS
mCmdVector           = $036E        ; command handler address (JMP indirect)
sPtrHi               = $0370        ; effect pointer high, per channel (0 = none)
sPtrLo               = $0375        ; effect pointer low
mChanFlagsSave       = $037A        ; mChanFlags restored when an effect ends
mDmcFlagsSave        = $037E        ; mDmcFlags restored when a DMC effect ends
sDmcActive           = $037F        ; nonzero while a DMC effect plays
sTimer               = $0380        ; frames until the next effect step
sSpeed               = $0384        ; effect speed / step delay
sId                  = $0388        ; effect number (for restart)
sNewPriority         = $038C        ; priority passed to Sfx_Play
sPriority            = $038D        ; priority of the effect on each channel
sDmcPriority         = $0391        ; priority of the DMC effect

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
CMD_DMC_END          = $65
CMD_DMC_REST         = $66

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
; Start song A. $81 = re-enable all channels (resume), $80/$82+ = stop.
Music_Play:
        cmp #$80
        bcc Music_LoadSong
        cmp #$81
        bne Music_Stop
        lda #$03
        sta mChanFlags
        sta mChanFlags+1
        sta mChanFlags+2
        sta mChanFlags+3
        sta mDmcFlags
        rts

;----------------------------------------------------------------------
; Stop: clear all channel flags, APU_STATUS = $E0.
Music_Stop:
        lda #$00
        sta mChanFlags
        sta mChanFlagsSave
        sta mChanFlags+1
        sta mChanFlagsSave+1
        sta mChanFlags+2
        sta mChanFlagsSave+2
        sta mChanFlags+3
        sta mChanFlagsSave+3
        sta mDmcFlags
        sta mDmcFlagsSave
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
        sta mTrkPtrLo+4
        lda SongHi,x
        sta mTrkPtrHi+4
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
        sta mDmcTimer
        lda #$00
        sta mTranspose
        sta mTranspose+1
        sta mTranspose+2
        sta mTranspose+3
        sta mLoopActive
        sta mLoopActive+1
        sta mLoopActive+2
        sta mLoopActive+3
        sta mLoopActive+4
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
        sta mDmcFlags
        sta mDmcFlagsSave
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
        ldy #$04
        ldx #$10
        jsr Dmc_UpdateChannel
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
        bcc L8188
        lda #$00

L8188:
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
        beq L8312
        cmp #$80
        bne L8303
        iny
        lda (zPtr),y
        sta mPitchEnvLo,x
        iny
        lda (zPtr),y
        sta mPitchEnvHi,x
        lda #$01
        sta mPitchEnvTimer,x
        jmp Music_ArpEnvTick

L8303:
        clc
        adc mReg2,x
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

L8312:
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
        bne L8358
        iny
        lda (zPtr),y
        sta mArpEnvLo,x
        iny
        lda (zPtr),y
        sta mArpEnvHi,x
        lda #$01
        sta mArpEnvTimer,x
        jmp Music_Output

L8358:
        clc
        adc mNote,x
        tay
        lda mReg3,x
        and #$F8
        clc
        cpy #$21
        bcs L836A
        adc PeriodHi,y

L836A:
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
        beq L83B4
        lda mReg3,x
        sta SQ1_HI,y
        lda mRegDirty,x
        and #$FE
        sta mRegDirty,x

L83B4:
        lda mRegDirty,x
        and #$02
        beq L83C9
        lda mReg2,x
        sta SQ1_LO,y
        lda mRegDirty,x
        and #$FD
        sta mRegDirty,x

L83C9:
        lda mRegDirty,x
        and #$04
        beq L83DE
        lda mReg0,x
        sta SQ1_VOL,y
        lda mRegDirty,x
        and #$FB
        sta mRegDirty,x

L83DE:
        rts

;
; Track command handlers, commands $60-$66 (7 entries, split low/high byte tables)
CmdHandlerHi:
        .hibytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .hibytes Cmd_Jump, Cmd_DmcEnd, Cmd_DmcRest ; 4-6

CmdHandlerLo:
        .lobytes Cmd_Rest, Cmd_End, Cmd_Call, Cmd_Return ; 0-3
        .lobytes Cmd_Jump, Cmd_DmcEnd, Cmd_DmcRest ; 4-6

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
        beq L8418
        lda mReg0,x
        and #$F0
        sta mReg0,x
        lda mRegDirty,x
        ora #$04
        sta mRegDirty,x

L8418:
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
        bne L8461
        ldy #$03
        lda (zPtr),y
        sta mLoopCount,x

L8461:
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
        beq L84A0
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

L84A0:
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
        cpy #$04
        bcc L84B8
        jmp Dmc_UpdateChannel

L84B8:
        jmp Music_UpdateChannel

;----------------------------------------------------------------------
; $65 CMD_DMC_END: stop the DMC track.
Cmd_DmcEnd:
        lda mDmcFlags
        and #$02
        sta mDmcFlags
        sta mDmcFlagsSave
        jsr Dmc_Silence
        jmp Dmc_Output

;----------------------------------------------------------------------
; $66 CMD_DMC_REST len
Cmd_DmcRest:
        ldy #$01
        lda (zPtr),y
        and #$0F
        tay
        lda (zDurTab),y
        sta mDmcTimer
        ldy #$01
        jmp Dmc_AdvancePtr

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
        jmp Music_UpdateChannel             ; also reached from the DMC track (see header)

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

;----------------------------------------------------------------------
; DMC track (channel 4).
Dmc_UpdateChannel:
        sty zChan
        stx zRegOfs
        lda mDmcFlags
        and #$01
        bne L8538
        rts

L8538:
        dec mDmcTimer
        beq Dmc_ReadEvent
        rts

;----------------------------------------------------------------------
; Stop the current sample, then read the next DMC event.
Dmc_ReadEvent:
        lda #$03
        sta mDmcDirty
        lda #$00
        sta mDmcFreq
        sta mDmcRaw
        sta mDmcStart
        sta mDmcLen
        lda mApuStatus
        and #$EF
        sta mApuStatus
        jsr Dmc_Output
        lda #$01
        sta mDmcDirty
        lda mTrkPtrLo+4
        sta zPtr
        lda mTrkPtrHi+4
        sta zPtr+1
        lda mDurTabLo
        sta zDurTab
        lda mDurTabHi
        sta zDurTab+1
        ldy #$00
        lda (zPtr),y
        cmp #$60
        bcc Dmc_Note
        jmp Music_Command

;----------------------------------------------------------------------
; Rate from byte 0, sample number and length from byte 1.
Dmc_Note:
        and #$0F
        sta mDmcFreq
        ldy #$01
        lda (zPtr),y
        pha
        and #$0F
        tay
        lda (zDurTab),y
        sta mDmcTimer
        pla
        and #$F0
        lsr a
        lsr a
        lsr a
        lsr a
        tay
        lda DmcSampleLo,y
        sta zPtr
        lda DmcSampleHi,y
        sta zPtr+1
        ldy #$00
        lda (zPtr),y
        beq L85B2
        lda mDmcFreq
        ora #$40
        sta mDmcFreq

L85B2:
        ldy #$01
        lda (zPtr),y
        sta mDmcStart
        iny
        lda (zPtr),y
        sta mDmcLen
        lda mApuStatus
        ora #$10
        sta mApuStatus
        ldy #$01
        jsr Dmc_AdvancePtr
        jmp Dmc_Output

;----------------------------------------------------------------------
; unreferenced code (nothing jumps here)
Unused_DmcSetTimerAndAdvance:
        lda #$01
        sta mDmcTimer

;----------------------------------------------------------------------
; DMC track pointer += Y + 1.
Dmc_AdvancePtr:
        iny
        tya
        clc
        adc mTrkPtrLo+4
        sta mTrkPtrLo+4
        lda mTrkPtrHi+4
        adc #$00
        sta mTrkPtrHi+4
        rts

;----------------------------------------------------------------------
; Clear the DMC registers and disable the DMC.
Dmc_Silence:
        lda #$00
        sta mDmcLen
        lda #$00
        sta mDmcFreq
        lda mApuStatus
        and #$EF
        sta mApuStatus
        jmp Dmc_WriteRegs

;----------------------------------------------------------------------
; Write the DMC registers if the music owns the DMC.
Dmc_Output:
        lda mDmcFlags
        and #$02
        bne Dmc_WriteRegs
        rts

;----------------------------------------------------------------------
; Write DMC_FREQ, DMC_START, DMC_LEN and APU_STATUS.
Dmc_WriteRegs:
        lda #$00
        sta mDmcDirty
        lda mDmcFreq
        sta DMC_FREQ
        lda mDmcStart
        sta DMC_START
        lda mDmcLen
        sta DMC_LEN
        lda mApuStatus
        sta APU_STATUS
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
; DMC sample definitions (7 entries, split low/high byte tables)
DmcSampleLo:
        .lobytes DmcSampleDef_0, DmcSampleDef_1, DmcSampleDef_2, DmcSampleDef_3 ; 0-3
        .lobytes DmcSampleDef_4, DmcSampleDef_5, DmcSampleDef_6 ; 4-6

DmcSampleHi:
        .hibytes DmcSampleDef_0, DmcSampleDef_1, DmcSampleDef_2, DmcSampleDef_3 ; 0-3
        .hibytes DmcSampleDef_4, DmcSampleDef_5, DmcSampleDef_6 ; 4-6

DmcSampleDef_0:
        .byte $00                           ; nonzero = loop sample
        .byte $00                           ; DMC_START: $C000
        .byte $2B                           ; DMC_LEN: 689 bytes

DmcSampleDef_1:
        .byte $00                           ; nonzero = loop sample
        .byte $0B                           ; DMC_START: $C2C0
        .byte $18                           ; DMC_LEN: 385 bytes

DmcSampleDef_2:
        .byte $00                           ; nonzero = loop sample
        .byte $11                           ; DMC_START: $C440
        .byte $14                           ; DMC_LEN: 321 bytes

DmcSampleDef_3:
        .byte $00                           ; nonzero = loop sample
        .byte $17                           ; DMC_START: $C5C0
        .byte $30                           ; DMC_LEN: 769 bytes

DmcSampleDef_4:
        .byte $00                           ; nonzero = loop sample
        .byte $25                           ; DMC_START: $C940
        .byte $0B                           ; DMC_LEN: 177 bytes

DmcSampleDef_5:
        .byte $00                           ; nonzero = loop sample
        .byte $27                           ; DMC_START: $C9C0
        .byte $0B                           ; DMC_LEN: 177 bytes

DmcSampleDef_6:
        .byte $00                           ; nonzero = loop sample
        .byte $2A                           ; DMC_START: $CA80
        .byte $0D                           ; DMC_LEN: 209 bytes

;
; Instrument pointers (18 entries, split low/high byte tables)
InstrumentLo:
        .lobytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .lobytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .lobytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .lobytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15
        .lobytes Instrument_10, Instrument_11 ; 16-17

InstrumentHi:
        .hibytes Instrument_00, Instrument_01, Instrument_02, Instrument_03 ; 0-3
        .hibytes Instrument_04, Instrument_05, Instrument_06, Instrument_07 ; 4-7
        .hibytes Instrument_08, Instrument_09, Instrument_0A, Instrument_0B ; 8-11
        .hibytes Instrument_0C, Instrument_0D, Instrument_0E, Instrument_0F ; 12-15
        .hibytes Instrument_10, Instrument_11 ; 16-17

Instrument_00:
        .byte $00                           ; flags: volume envelope
        .word $0000                         ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $00                           ; reg0 bits (duty/const/halt): 00
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_01:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_878B                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_02:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_879E                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_03:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_87B1                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_04:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_87C4                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_05:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_87D7                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_06:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_87EA                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_07:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_87FD                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_08:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8810                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $08                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_09:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8823                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0A:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8836                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0B:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_884B                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0C:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8850                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0D:
        .byte $00                           ; flags: volume envelope
        .word VolEnv_8855                   ; volume envelope
        .word $0000                         ; pitch envelope (none)
        .byte $B0                           ; reg0 bits (duty/const/halt): B0
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0E:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $4F                           ; reg0 bits (duty/const/halt): 4F
        .byte $F0                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_0F:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $7F                           ; reg0 bits (duty/const/halt): 7F
        .byte $F8                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_10:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word PitchEnv_888B                 ; pitch envelope
        .byte $FF                           ; reg0 bits (duty/const/halt): FF
        .byte $00                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

Instrument_11:
        .byte $02                           ; flags: no volume envelope
        .byte $00,$00                       ; (unused)
        .word $0000                         ; pitch envelope (none)
        .byte $2F                           ; reg0 bits (duty/const/halt): 2F
        .byte $F0                           ; reg3 bits (length counter)
        .word $0000                         ; arpeggio envelope (none)

VolEnv_878B:
        .byte $0A,$01                       ; volume 10 for 1 frame(s)
        .byte $07,$04                       ; volume 7 for 4 frame(s)
        .byte $06,$0A                       ; volume 6 for 10 frame(s)
        .byte $05,$0F                       ; volume 5 for 15 frame(s)
        .byte $04,$0F                       ; volume 4 for 15 frame(s)
        .byte $03,$0F                       ; volume 3 for 15 frame(s)
        .byte $02,$0F                       ; volume 2 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_879E:
        .byte $08,$01                       ; volume 8 for 1 frame(s)
        .byte $05,$04                       ; volume 5 for 4 frame(s)
        .byte $04,$0A                       ; volume 4 for 10 frame(s)
        .byte $03,$0F                       ; volume 3 for 15 frame(s)
        .byte $02,$0F                       ; volume 2 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_87B1:
        .byte $06,$01                       ; volume 6 for 1 frame(s)
        .byte $03,$04                       ; volume 3 for 4 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $02,$0F                       ; volume 2 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $01,$0F                       ; volume 1 for 15 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_87C4:
        .byte $0A,$01                       ; volume 10 for 1 frame(s)
        .byte $07,$04                       ; volume 7 for 4 frame(s)
        .byte $06,$0A                       ; volume 6 for 10 frame(s)
        .byte $05,$0A                       ; volume 5 for 10 frame(s)
        .byte $04,$0A                       ; volume 4 for 10 frame(s)
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_87D7:
        .byte $08,$01                       ; volume 8 for 1 frame(s)
        .byte $05,$04                       ; volume 5 for 4 frame(s)
        .byte $04,$0A                       ; volume 4 for 10 frame(s)
        .byte $03,$0A                       ; volume 3 for 10 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_87EA:
        .byte $06,$01                       ; volume 6 for 1 frame(s)
        .byte $03,$04                       ; volume 3 for 4 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $02,$0A                       ; volume 2 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $01,$0A                       ; volume 1 for 10 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_87FD:
        .byte $0A,$01                       ; volume 10 for 1 frame(s)
        .byte $07,$09                       ; volume 7 for 9 frame(s)
        .byte $06,$14                       ; volume 6 for 20 frame(s)
        .byte $05,$14                       ; volume 5 for 20 frame(s)
        .byte $04,$14                       ; volume 4 for 20 frame(s)
        .byte $03,$14                       ; volume 3 for 20 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8810:
        .byte $08,$01                       ; volume 8 for 1 frame(s)
        .byte $05,$09                       ; volume 5 for 9 frame(s)
        .byte $04,$14                       ; volume 4 for 20 frame(s)
        .byte $03,$14                       ; volume 3 for 20 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8823:
        .byte $06,$01                       ; volume 6 for 1 frame(s)
        .byte $03,$09                       ; volume 3 for 9 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $02,$14                       ; volume 2 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $01,$14                       ; volume 1 for 20 frame(s)
        .byte $01,$1E                       ; volume 1 for 30 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8836:
        .byte $02,$04                       ; volume 2 for 4 frame(s)
        .byte $03,$04                       ; volume 3 for 4 frame(s)
        .byte $04,$04                       ; volume 4 for 4 frame(s)
        .byte $05,$04                       ; volume 5 for 4 frame(s)
        .byte $06,$04                       ; volume 6 for 4 frame(s)
        .byte $07,$06                       ; volume 7 for 6 frame(s)
        .byte $08,$06                       ; volume 8 for 6 frame(s)
        .byte $09,$06                       ; volume 9 for 6 frame(s)
        .byte $0A,$14                       ; volume 10 for 20 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_884B:
        .byte $03,$01                       ; volume 3 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8850:
        .byte $06,$01                       ; volume 6 for 1 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

VolEnv_8855:
        .byte $03,$02                       ; volume 3 for 2 frame(s)
        .byte $00,$01                       ; volume 0 for 1 frame(s)
        .byte $80                           ; end (hold last volume)

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_885A:
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $03,$02                       ; value +3 for 2 fr
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $03,$02                       ; value +3 for 2 fr
        .byte $80                           ; jump
        .word UnusedEnv_885A

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_8865:
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $04,$02                       ; value +4 for 2 fr
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $04,$02                       ; value +4 for 2 fr
        .byte $80                           ; jump
        .word UnusedEnv_8865

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_8870:
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $05,$02                       ; value +5 for 2 fr
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $05,$02                       ; value +5 for 2 fr
        .byte $80                           ; jump
        .word UnusedEnv_8870

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_887B:
        .byte $00,$02                       ; value +0 for 2 fr
        .byte $03,$02                       ; value +3 for 2 fr
        .byte $07,$02                       ; value +7 for 2 fr
        .byte $03,$02                       ; value +3 for 2 fr
        .byte $80                           ; jump
        .word UnusedEnv_887B

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_8886:
        .byte $01,$FF                       ; value +1 for 255 fr
        .byte $80                           ; jump
        .word UnusedEnv_8886

PitchEnv_888B:
        .byte $00,$01                       ; wait 1

PitchEnv_888D:
        .byte $00,$02                       ; wait 2
        .byte $02,$01                       ; period +2, wait 1
        .byte $FE,$01                       ; period -2, wait 1
        .byte $FE,$01                       ; period -2, wait 1
        .byte $02,$01                       ; period +2, wait 1
        .byte $80                           ; jump
        .word PitchEnv_888D

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_889A:
        .byte $01,$FF                       ; value +1 for 255 fr
        .byte $80                           ; jump
        .word UnusedEnv_889A

; (unreferenced envelope - pitch or arpeggio format)
UnusedEnv_889F:
        .byte $0C,$01                       ; value +12 for 1 fr
        .byte $05,$01                       ; value +5 for 1 fr
        .byte $02,$01                       ; value +2 for 1 fr
        .byte $02,$01                       ; value +2 for 1 fr
        .byte $0A,$01                       ; value +10 for 1 fr
        .byte $02,$01                       ; value +2 for 1 fr
        .byte $0A,$01                       ; value +10 for 1 fr
        .byte $80                           ; jump
        .word UnusedEnv_889F

;
; Song table: 8 songs x 6 pointers (Sq1, Sq2, Tri, Noise, DMC, duration table)
SongHi:
        .hibytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, Song00_DMC, DurTable_8920 ; song $00
        .hibytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, Song01_DMC, DurTable_8920 ; song $01
        .hibytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, Song02_DMC, DurTable_8920 ; song $02
        .hibytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, Song03_DMC, DurTable_8920 ; song $03
        .hibytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, Song04_DMC, DurTable_8920 ; song $04
        .hibytes Song05_Sq1, Song05_Sq2, Song05_Tri, Song05_Noise, Song05_DMC, DurTable_8920 ; song $05
        .hibytes Song06_Sq1, Song06_Sq2, Song06_Tri, Song06_Noise, Song06_DMC, DurTable_8920 ; song $06
        .hibytes Song07_Sq1, Song07_Sq2, Song07_Tri, Song07_Noise, Song07_DMC, DurTable_8920 ; song $07

SongLo:
        .lobytes Song00_Sq1, Song00_Sq2, Song00_Tri, Song00_Noise, Song00_DMC, DurTable_8920 ; song $00
        .lobytes Song01_Sq1, Song01_Sq2, Song01_Tri, Song01_Noise, Song01_DMC, DurTable_8920 ; song $01
        .lobytes Song02_Sq1, Song02_Sq2, Song02_Tri, Song02_Noise, Song02_DMC, DurTable_8920 ; song $02
        .lobytes Song03_Sq1, Song03_Sq2, Song03_Tri, Song03_Noise, Song03_DMC, DurTable_8920 ; song $03
        .lobytes Song04_Sq1, Song04_Sq2, Song04_Tri, Song04_Noise, Song04_DMC, DurTable_8920 ; song $04
        .lobytes Song05_Sq1, Song05_Sq2, Song05_Tri, Song05_Noise, Song05_DMC, DurTable_8920 ; song $05
        .lobytes Song06_Sq1, Song06_Sq2, Song06_Tri, Song06_Noise, Song06_DMC, DurTable_8920 ; song $06
        .lobytes Song07_Sq1, Song07_Sq2, Song07_Tri, Song07_Noise, Song07_DMC, DurTable_8920 ; song $07

; (unreferenced duration table)
UnusedDurTable_8910:
        .byte $02,$03,$04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$C0,$FE,$09

DurTable_8920:
        .byte $03,$04,$06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$08,$10,$20 ; frames for len[0..15]

; (unreferenced duration table)
UnusedDurTable_8930:
        .byte $05,$07,$0A,$0F,$14,$1E,$28,$3C,$50,$78,$A0,$F0,$0D,$0E,$19,$06

; (unreferenced duration table)
UnusedDurTable_8940:
        .byte $04,$06,$08,$0C,$10,$18,$20,$30,$40,$60,$80,$15,$05,$06,$0A,$0B

; (unreferenced duration table)
UnusedDurTable_8950:
        .byte $06,$09,$0C,$12,$18,$24,$30,$48,$60,$90,$C0,$FF,$21,$08,$10,$20

; (unreferenced duration table)
UnusedDurTable_8960:
        .byte $07,$0A,$0F,$14,$1E,$2D,$3C,$5A,$78,$B4,$F0,$08,$0A,$0A,$0A,$0D

;======================================================================
; Song $00
;======================================================================
Song00_Sq1:
Song00_Sq2:
Song00_Tri:
Song00_Noise:
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_REST,$0C                  ; rest len[12] = 192 fr
        .byte CMD_END

Song00_DMC:
        .byte CMD_DMC_REST,$0C              ; rest len[12] = 192 fr
        .byte CMD_DMC_REST,$0C              ; rest len[12] = 192 fr
        .byte CMD_DMC_REST,$0C              ; rest len[12] = 192 fr
        .byte CMD_DMC_REST,$0C              ; rest len[12] = 192 fr
        .byte CMD_DMC_END

;======================================================================
; Song $01
;======================================================================
Song01_Sq1:
        .byte $1F,$17                       ; G-4    ins  1  len[7] = 36 fr
        .byte $1C,$18                       ; E-4    ins  1  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1A,$17                       ; D-4    ins  1  len[7] = 36 fr
        .byte $1C,$18                       ; E-4    ins  1  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_JUMP
        .word Song01_Sq1

Song01_Sq2:
        .byte $1C,$27                       ; E-4    ins  2  len[7] = 36 fr
        .byte $17,$28                       ; B-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $15,$27                       ; A-3    ins  2  len[7] = 36 fr
        .byte $17,$28                       ; B-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_JUMP
        .word Song01_Sq2

Song01_Tri:
        .byte $1C,$E4                       ; E-4    ins 14  len[4] = 12 fr
        .byte $1C,$E4                       ; E-4    ins 14  len[4] = 12 fr
        .byte $17,$E4                       ; B-3    ins 14  len[4] = 12 fr
        .byte $1A,$E2                       ; D-4    ins 14  len[2] = 6 fr
        .byte $1C,$E4                       ; E-4    ins 14  len[4] = 12 fr
        .byte $1C,$E4                       ; E-4    ins 14  len[4] = 12 fr
        .byte $1C,$E2                       ; E-4    ins 14  len[2] = 6 fr
        .byte $17,$E4                       ; B-3    ins 14  len[4] = 12 fr
        .byte $1A,$E4                       ; D-4    ins 14  len[4] = 12 fr
        .byte CMD_JUMP
        .word Song01_Tri

Song01_Noise:
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C5                       ; noise $09 ins 12  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C6                       ; noise $09 ins 12  len[6] = 24 fr
        .byte CMD_JUMP
        .word Song01_Noise

Song01_DMC:
        .byte CMD_CALL,$28,$00,$08          ; Pattern_28, transpose +0, play 8x
        .byte CMD_JUMP
        .word Song02_DMC

Pattern_28:
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$65                       ; sample 6, rate 15, len[5] = 18 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$66                       ; sample 6, rate 15, len[6] = 24 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte CMD_RETURN

;======================================================================
; Song $02
;======================================================================
Song02_Sq1:
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte CMD_CALL,$00,$05,$04          ; Pattern_00, transpose +5, play 4x
        .byte CMD_CALL,$04,$05,$01          ; Pattern_04, transpose +5, play 1x
        .byte CMD_CALL,$08,$05,$01          ; Pattern_08, transpose +5, play 1x
        .byte CMD_JUMP
        .word Song02_Sq1
        .byte $61                           ; CMD_END - never reached

Song02_Sq2:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte CMD_CALL,$01,$05,$02          ; Pattern_01, transpose +5, play 2x
        .byte CMD_CALL,$05,$05,$01          ; Pattern_05, transpose +5, play 1x
        .byte CMD_CALL,$09,$05,$01          ; Pattern_09, transpose +5, play 1x
        .byte CMD_JUMP
        .word Song02_Sq2
        .byte $61                           ; CMD_END - never reached

Song02_Tri:
        .byte CMD_CALL,$02,$11,$03          ; Pattern_02, transpose +17, play 3x
        .byte CMD_CALL,$06,$11,$05          ; Pattern_06, transpose +17, play 5x
        .byte CMD_CALL,$0A,$11,$01          ; Pattern_0A, transpose +17, play 1x
        .byte CMD_JUMP
        .word Song02_Tri
        .byte $61                           ; CMD_END - never reached

Song02_Noise:
        .byte CMD_CALL,$03,$00,$03          ; Pattern_03, transpose +0, play 3x
        .byte CMD_CALL,$07,$00,$05          ; Pattern_07, transpose +0, play 5x
        .byte CMD_CALL,$0B,$00,$01          ; Pattern_0B, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song02_Noise
        .byte $61                           ; CMD_END - never reached

Song02_DMC:
        .byte CMD_CALL,$29,$00,$08          ; Pattern_29, transpose +0, play 8x
        .byte CMD_JUMP
        .word Song02_DMC

Pattern_29:
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$04                       ; sample 0, rate 15, len[4] = 12 fr
        .byte CMD_RETURN

Pattern_00:
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $17,$54                       ; B-3    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $13,$56                       ; G-3    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_04:
        .byte $5F,$04                       ; B-9    ins  0  len[4] = 12 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $1F,$57                       ; G-4    ins  5  len[7] = 36 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$54                       ; B-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$54                       ; B-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $28,$2A                       ; E-5    ins  2  len[10] = 96 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $29,$52                       ; F-5    ins  5  len[2] = 6 fr
        .byte $2B,$54                       ; G-5    ins  5  len[4] = 12 fr
        .byte $2B,$54                       ; G-5    ins  5  len[4] = 12 fr
        .byte $29,$52                       ; F-5    ins  5  len[2] = 6 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $28,$55                       ; E-5    ins  5  len[5] = 18 fr
        .byte $24,$55                       ; C-5    ins  5  len[5] = 18 fr
        .byte $1F,$28                       ; G-4    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $1F,$57                       ; G-4    ins  5  len[7] = 36 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1C,$52                       ; E-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$54                       ; B-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$54                       ; B-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_08:
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$58                       ; F-4    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $1E,$55                       ; F#4    ins  5  len[5] = 18 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 48 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$58                       ; F-4    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$58                       ; G-4    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$58                       ; A-4    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 24 fr
        .byte $20,$54                       ; G#4    ins  5  len[4] = 12 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 24 fr
        .byte CMD_REST,$06                  ; rest len[6] = 24 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $22,$56                       ; A#4    ins  5  len[6] = 24 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $22,$56                       ; A#4    ins  5  len[6] = 24 fr
        .byte $21,$56                       ; A-4    ins  5  len[6] = 24 fr
        .byte $1F,$2A                       ; G-4    ins  2  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_01:
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$55                       ; B-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte $17,$56                       ; B-3    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_05:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_09:
        .byte $15,$54                       ; A-3    ins  5  len[4] = 12 fr
        .byte $15,$58                       ; A-3    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $17,$54                       ; B-3    ins  5  len[4] = 12 fr
        .byte $17,$55                       ; B-3    ins  5  len[5] = 18 fr
        .byte $16,$55                       ; A#3    ins  5  len[5] = 18 fr
        .byte $17,$58                       ; B-3    ins  5  len[8] = 48 fr
        .byte $15,$54                       ; A-3    ins  5  len[4] = 12 fr
        .byte $15,$58                       ; A-3    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $17,$54                       ; B-3    ins  5  len[4] = 12 fr
        .byte $17,$58                       ; B-3    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $19,$54                       ; C#4    ins  5  len[4] = 12 fr
        .byte $19,$58                       ; C#4    ins  5  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $19,$54                       ; C#4    ins  5  len[4] = 12 fr
        .byte $19,$56                       ; C#4    ins  5  len[6] = 24 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $19,$58                       ; C#4    ins  5  len[8] = 48 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1A,$56                       ; D-4    ins  5  len[6] = 24 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $17,$2A                       ; B-3    ins  2  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_02:
Pattern_06:
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0B,$E4                       ; B-2    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E6                       ; D-3    ins 14  len[6] = 24 fr
        .byte $07,$E6                       ; G-2    ins 14  len[6] = 24 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0B,$E4                       ; B-2    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E6                       ; D-3    ins 14  len[6] = 24 fr
        .byte $13,$E6                       ; G-3    ins 14  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_0A:
        .byte $05,$E4                       ; F-2    ins 14  len[4] = 12 fr
        .byte $05,$E8                       ; F-2    ins 14  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $07,$E4                       ; G-2    ins 14  len[4] = 12 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $06,$E5                       ; F#2    ins 14  len[5] = 18 fr
        .byte $07,$E8                       ; G-2    ins 14  len[8] = 48 fr
        .byte $05,$E4                       ; F-2    ins 14  len[4] = 12 fr
        .byte $05,$E8                       ; F-2    ins 14  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $07,$E4                       ; G-2    ins 14  len[4] = 12 fr
        .byte $07,$E8                       ; G-2    ins 14  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $09,$E4                       ; A-2    ins 14  len[4] = 12 fr
        .byte $09,$E8                       ; A-2    ins 14  len[8] = 48 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $09,$E4                       ; A-2    ins 14  len[4] = 12 fr
        .byte $09,$E6                       ; A-2    ins 14  len[6] = 24 fr
        .byte $08,$E4                       ; G#2    ins 14  len[4] = 12 fr
        .byte $09,$E8                       ; A-2    ins 14  len[8] = 48 fr
        .byte $0A,$E4                       ; A#2    ins 14  len[4] = 12 fr
        .byte $0A,$E6                       ; A#2    ins 14  len[6] = 24 fr
        .byte $0A,$E4                       ; A#2    ins 14  len[4] = 12 fr
        .byte $0A,$E6                       ; A#2    ins 14  len[6] = 24 fr
        .byte $09,$E6                       ; A-2    ins 14  len[6] = 24 fr
        .byte $07,$FA                       ; G-2    ins 15  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_03:
Pattern_07:
Pattern_0B:
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B5                       ; noise $09 ins 11  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B5                       ; noise $09 ins 11  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B5                       ; noise $09 ins 11  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B5                       ; noise $09 ins 11  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte CMD_RETURN

;======================================================================
; Song $03
;======================================================================
Song03_Sq1:
        .byte CMD_CALL,$0C,$00,$01          ; Pattern_0C, transpose +0, play 1x
        .byte CMD_CALL,$10,$00,$01          ; Pattern_10, transpose +0, play 1x
        .byte CMD_CALL,$14,$0C,$02          ; Pattern_14, transpose +12, play 2x
        .byte CMD_CALL,$14,$08,$02          ; Pattern_14, transpose +8, play 2x
        .byte CMD_CALL,$14,$04,$02          ; Pattern_14, transpose +4, play 2x
        .byte CMD_CALL,$14,$02,$02          ; Pattern_14, transpose +2, play 2x
        .byte CMD_CALL,$14,$0C,$02          ; Pattern_14, transpose +12, play 2x
        .byte CMD_CALL,$14,$08,$02          ; Pattern_14, transpose +8, play 2x
        .byte CMD_CALL,$14,$04,$02          ; Pattern_14, transpose +4, play 2x
        .byte CMD_CALL,$14,$02,$02          ; Pattern_14, transpose +2, play 2x
        .byte CMD_JUMP
        .word Song03_Sq1
        .byte $61                           ; CMD_END - never reached

Song03_Sq2:
        .byte CMD_CALL,$0D,$00,$01          ; Pattern_0D, transpose +0, play 1x
        .byte CMD_CALL,$11,$00,$01          ; Pattern_11, transpose +0, play 1x
        .byte CMD_CALL,$15,$0C,$02          ; Pattern_15, transpose +12, play 2x
        .byte CMD_CALL,$15,$08,$02          ; Pattern_15, transpose +8, play 2x
        .byte CMD_CALL,$15,$04,$02          ; Pattern_15, transpose +4, play 2x
        .byte CMD_CALL,$15,$02,$02          ; Pattern_15, transpose +2, play 2x
        .byte CMD_CALL,$15,$0C,$02          ; Pattern_15, transpose +12, play 2x
        .byte CMD_CALL,$15,$08,$02          ; Pattern_15, transpose +8, play 2x
        .byte CMD_CALL,$15,$04,$02          ; Pattern_15, transpose +4, play 2x
        .byte CMD_CALL,$15,$02,$02          ; Pattern_15, transpose +2, play 2x
        .byte CMD_JUMP
        .word Song03_Sq2
        .byte $61                           ; CMD_END - never reached

Song03_Tri:
        .byte CMD_CALL,$0E,$0C,$01          ; Pattern_0E, transpose +12, play 1x
        .byte CMD_CALL,$12,$0C,$01          ; Pattern_12, transpose +12, play 1x
        .byte CMD_CALL,$16,$0C,$02          ; Pattern_16, transpose +12, play 2x
        .byte CMD_CALL,$16,$14,$02          ; Pattern_16, transpose +20, play 2x
        .byte CMD_CALL,$16,$10,$02          ; Pattern_16, transpose +16, play 2x
        .byte CMD_CALL,$16,$0E,$02          ; Pattern_16, transpose +14, play 2x
        .byte CMD_CALL,$16,$0C,$02          ; Pattern_16, transpose +12, play 2x
        .byte CMD_CALL,$16,$14,$02          ; Pattern_16, transpose +20, play 2x
        .byte CMD_CALL,$16,$10,$02          ; Pattern_16, transpose +16, play 2x
        .byte CMD_CALL,$16,$0E,$02          ; Pattern_16, transpose +14, play 2x
        .byte CMD_JUMP
        .word Song03_Tri
        .byte $61                           ; CMD_END - never reached

Song03_Noise:
        .byte CMD_CALL,$0F,$00,$0B          ; Pattern_0F, transpose +0, play 11x
        .byte CMD_CALL,$13,$00,$02          ; Pattern_13, transpose +0, play 2x
        .byte CMD_CALL,$17,$00,$10          ; Pattern_17, transpose +0, play 16x
        .byte CMD_JUMP
        .word Song03_Noise
        .byte $61                           ; CMD_END - never reached

Song03_DMC:
        .byte CMD_CALL,$2A,$00,$06          ; Pattern_2A, transpose +0, play 6x
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte CMD_CALL,$2B,$00,$10          ; Pattern_2B, transpose +0, play 16x
        .byte CMD_JUMP
        .word Song03_DMC

Pattern_2A:
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$65                       ; sample 6, rate 15, len[5] = 18 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte CMD_RETURN

Pattern_2B:
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$12                       ; sample 1, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$12                       ; sample 1, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$34                       ; sample 3, rate 15, len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0C:
        .byte $1C,$9A                       ; E-4    ins  9  len[10] = 96 fr
        .byte $22,$9C                       ; A#4    ins  9  len[12] = 192 fr
        .byte $23,$9C                       ; B-4    ins  9  len[12] = 192 fr
        .byte $22,$9C                       ; A#4    ins  9  len[12] = 192 fr
        .byte $23,$9C                       ; B-4    ins  9  len[12] = 192 fr
        .byte $24,$9A                       ; C-5    ins  9  len[10] = 96 fr
        .byte $23,$9A                       ; B-4    ins  9  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_10:
        .byte $22,$64                       ; A#4    ins  6  len[4] = 12 fr
        .byte $22,$64                       ; A#4    ins  6  len[4] = 12 fr
        .byte $22,$68                       ; A#4    ins  6  len[8] = 48 fr
        .byte $22,$64                       ; A#4    ins  6  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $22,$66                       ; A#4    ins  6  len[6] = 24 fr
        .byte $22,$64                       ; A#4    ins  6  len[4] = 12 fr
        .byte $22,$64                       ; A#4    ins  6  len[4] = 12 fr
        .byte $22,$68                       ; A#4    ins  6  len[8] = 48 fr
        .byte CMD_RETURN

Pattern_14:
        .byte $1A,$64                       ; D-4    ins  6  len[4] = 12 fr
        .byte $1A,$66                       ; D-4    ins  6  len[6] = 24 fr
        .byte $1A,$64                       ; D-4    ins  6  len[4] = 12 fr
        .byte $1A,$64                       ; D-4    ins  6  len[4] = 12 fr
        .byte $1A,$66                       ; D-4    ins  6  len[6] = 24 fr
        .byte $1A,$64                       ; D-4    ins  6  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0D:
        .byte $18,$9A                       ; C-4    ins  9  len[10] = 96 fr
        .byte $1E,$9C                       ; F#4    ins  9  len[12] = 192 fr
        .byte $1F,$9C                       ; G-4    ins  9  len[12] = 192 fr
        .byte $1E,$9C                       ; F#4    ins  9  len[12] = 192 fr
        .byte $1F,$9C                       ; G-4    ins  9  len[12] = 192 fr
        .byte $20,$9A                       ; G#4    ins  9  len[10] = 96 fr
        .byte $1F,$9A                       ; G-4    ins  9  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_11:
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$68                       ; F#4    ins  6  len[8] = 48 fr
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$66                       ; F#4    ins  6  len[6] = 24 fr
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$64                       ; F#4    ins  6  len[4] = 12 fr
        .byte $1E,$68                       ; F#4    ins  6  len[8] = 48 fr
        .byte CMD_RETURN

Pattern_15:
        .byte $16,$64                       ; A#3    ins  6  len[4] = 12 fr
        .byte $16,$66                       ; A#3    ins  6  len[6] = 24 fr
        .byte $16,$64                       ; A#3    ins  6  len[4] = 12 fr
        .byte $16,$64                       ; A#3    ins  6  len[4] = 12 fr
        .byte $16,$66                       ; A#3    ins  6  len[6] = 24 fr
        .byte $16,$64                       ; A#3    ins  6  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0E:
        .byte $88,$09                       ; G#2    ins 16  len[9] = 72 fr
        .byte $8C,$04                       ; C-3    ins 16  len[4] = 12 fr
        .byte $8F,$04                       ; D#3    ins 16  len[4] = 12 fr
        .byte $8E,$0A                       ; D-3    ins 16  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $8F,$0A                       ; D#3    ins 16  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $8E,$0A                       ; D-3    ins 16  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $8F,$0A                       ; D#3    ins 16  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte $90,$0A                       ; E-3    ins 16  len[10] = 96 fr
        .byte $8F,$0A                       ; D#3    ins 16  len[10] = 96 fr
        .byte CMD_RETURN

Pattern_12:
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$18                       ; D-3    ins 17  len[8] = 48 fr
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$16                       ; D-3    ins 17  len[6] = 24 fr
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$14                       ; D-3    ins 17  len[4] = 12 fr
        .byte $8E,$18                       ; D-3    ins 17  len[8] = 48 fr
        .byte CMD_RETURN

Pattern_16:
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte $86,$15                       ; F#2    ins 17  len[5] = 18 fr
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte $86,$12                       ; F#2    ins 17  len[2] = 6 fr
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte $86,$14                       ; F#2    ins 17  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_0F:
Pattern_13:
Pattern_17:
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C5                       ; noise $09 ins 12  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$D4                       ; noise $09 ins 13  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte CMD_RETURN

;======================================================================
; Song $04
;======================================================================
Song04_Sq1:
        .byte CMD_CALL,$18,$0C,$01          ; Pattern_18, transpose +12, play 1x
        .byte CMD_JUMP
        .word Song04_Sq1

Song04_Sq2:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte CMD_JUMP
        .word Song04_Sq2

Song04_Tri:
        .byte CMD_CALL,$1A,$00,$08          ; Pattern_1A, transpose +0, play 8x
        .byte CMD_JUMP
        .word Song04_Tri

Song04_Noise:
        .byte CMD_CALL,$1B,$00,$08          ; Pattern_1B, transpose +0, play 8x
        .byte CMD_JUMP
        .word Song04_Noise

Song04_DMC:
        .byte CMD_CALL,$2C,$00,$01          ; Pattern_2C, transpose +0, play 1x
        .byte CMD_JUMP
        .word Song04_DMC

Pattern_2C:
        .byte $0F,$24                       ; sample 2, rate 15, len[4] = 12 fr
        .byte $0F,$44                       ; sample 4, rate 15, len[4] = 12 fr
        .byte $0F,$14                       ; sample 1, rate 15, len[4] = 12 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$24                       ; sample 2, rate 15, len[4] = 12 fr
        .byte $0F,$24                       ; sample 2, rate 15, len[4] = 12 fr
        .byte $0F,$14                       ; sample 1, rate 15, len[4] = 12 fr
        .byte $0F,$04                       ; sample 0, rate 15, len[4] = 12 fr
        .byte $0F,$24                       ; sample 2, rate 15, len[4] = 12 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$14                       ; sample 1, rate 15, len[4] = 12 fr
        .byte $0F,$44                       ; sample 4, rate 15, len[4] = 12 fr
        .byte $0F,$24                       ; sample 2, rate 15, len[4] = 12 fr
        .byte $0F,$44                       ; sample 4, rate 15, len[4] = 12 fr
        .byte $0F,$14                       ; sample 1, rate 15, len[4] = 12 fr
        .byte $0F,$34                       ; sample 3, rate 15, len[4] = 12 fr
        .byte CMD_RETURN

Pattern_18:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $13,$28                       ; G-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $0E,$22                       ; D-3    ins  2  len[2] = 6 fr
        .byte $10,$28                       ; E-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$05                  ; rest len[5] = 18 fr
        .byte $10,$22                       ; E-3    ins  2  len[2] = 6 fr
        .byte $13,$22                       ; G-3    ins  2  len[2] = 6 fr
        .byte $17,$29                       ; B-3    ins  2  len[9] = 72 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $18,$24                       ; C-4    ins  2  len[4] = 12 fr
        .byte $17,$29                       ; B-3    ins  2  len[9] = 72 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $1C,$27                       ; E-4    ins  2  len[7] = 36 fr
        .byte $1A,$22                       ; D-4    ins  2  len[2] = 6 fr
        .byte $1C,$22                       ; E-4    ins  2  len[2] = 6 fr
        .byte $1A,$22                       ; D-4    ins  2  len[2] = 6 fr
        .byte $17,$26                       ; B-3    ins  2  len[6] = 24 fr
        .byte CMD_REST,$02                  ; rest len[2] = 6 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $10,$26                       ; E-3    ins  2  len[6] = 24 fr
        .byte $12,$22                       ; F#3    ins  2  len[2] = 6 fr
        .byte $13,$27                       ; G-3    ins  2  len[7] = 36 fr
        .byte CMD_REST,$02                  ; rest len[2] = 6 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $0E,$29                       ; D-3    ins  2  len[9] = 72 fr
        .byte $0B,$24                       ; B-2    ins  2  len[4] = 12 fr
        .byte $0E,$24                       ; D-3    ins  2  len[4] = 12 fr
        .byte $10,$2A                       ; E-3    ins  2  len[10] = 96 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $13,$28                       ; G-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $17,$29                       ; B-3    ins  2  len[9] = 72 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $1F,$22                       ; G-4    ins  2  len[2] = 6 fr
        .byte $1F,$22                       ; G-4    ins  2  len[2] = 6 fr
        .byte $1F,$22                       ; G-4    ins  2  len[2] = 6 fr
        .byte $1F,$22                       ; G-4    ins  2  len[2] = 6 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $17,$25                       ; B-3    ins  2  len[5] = 18 fr
        .byte $13,$25                       ; G-3    ins  2  len[5] = 18 fr
        .byte $10,$28                       ; E-3    ins  2  len[8] = 48 fr
        .byte CMD_REST,$04                  ; rest len[4] = 12 fr
        .byte $17,$29                       ; B-3    ins  2  len[9] = 72 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $0E,$22                       ; D-3    ins  2  len[2] = 6 fr
        .byte $10,$25                       ; E-3    ins  2  len[5] = 18 fr
        .byte $0E,$25                       ; D-3    ins  2  len[5] = 18 fr
        .byte $0B,$26                       ; B-2    ins  2  len[6] = 24 fr
        .byte CMD_REST,$02                  ; rest len[2] = 6 fr
        .byte $09,$24                       ; A-2    ins  2  len[4] = 12 fr
        .byte $0B,$28                       ; B-2    ins  2  len[8] = 48 fr
        .byte CMD_REST,$02                  ; rest len[2] = 6 fr
        .byte $09,$22                       ; A-2    ins  2  len[2] = 6 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 12 fr
        .byte $09,$24                       ; A-2    ins  2  len[4] = 12 fr
        .byte $0B,$24                       ; B-2    ins  2  len[4] = 12 fr
        .byte $07,$26                       ; G-2    ins  2  len[6] = 24 fr
        .byte $04,$29                       ; E-2    ins  2  len[9] = 72 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $15,$22                       ; A-3    ins  2  len[2] = 6 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $13,$22                       ; G-3    ins  2  len[2] = 6 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $0E,$24                       ; D-3    ins  2  len[4] = 12 fr
        .byte $0E,$24                       ; D-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $13,$22                       ; G-3    ins  2  len[2] = 6 fr
        .byte $10,$26                       ; E-3    ins  2  len[6] = 24 fr
        .byte CMD_REST,$05                  ; rest len[5] = 18 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $1A,$22                       ; D-4    ins  2  len[2] = 6 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $17,$22                       ; B-3    ins  2  len[2] = 6 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $15,$24                       ; A-3    ins  2  len[4] = 12 fr
        .byte $13,$22                       ; G-3    ins  2  len[2] = 6 fr
        .byte $10,$25                       ; E-3    ins  2  len[5] = 18 fr
        .byte CMD_REST,$07                  ; rest len[7] = 36 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $17,$22                       ; B-3    ins  2  len[2] = 6 fr
        .byte $1F,$24                       ; G-4    ins  2  len[4] = 12 fr
        .byte $17,$22                       ; B-3    ins  2  len[2] = 6 fr
        .byte $1E,$24                       ; F#4    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $1C,$24                       ; E-4    ins  2  len[4] = 12 fr
        .byte $1A,$24                       ; D-4    ins  2  len[4] = 12 fr
        .byte $17,$24                       ; B-3    ins  2  len[4] = 12 fr
        .byte $15,$22                       ; A-3    ins  2  len[2] = 6 fr
        .byte $17,$22                       ; B-3    ins  2  len[2] = 6 fr
        .byte CMD_REST,$08                  ; rest len[8] = 48 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $13,$24                       ; G-3    ins  2  len[4] = 12 fr
        .byte $10,$24                       ; E-3    ins  2  len[4] = 12 fr
        .byte $0E,$24                       ; D-3    ins  2  len[4] = 12 fr
        .byte $0B,$24                       ; B-2    ins  2  len[4] = 12 fr
        .byte $0E,$24                       ; D-3    ins  2  len[4] = 12 fr
        .byte $0B,$24                       ; B-2    ins  2  len[4] = 12 fr
        .byte $09,$24                       ; A-2    ins  2  len[4] = 12 fr
        .byte $07,$24                       ; G-2    ins  2  len[4] = 12 fr
        .byte $04,$24                       ; E-2    ins  2  len[4] = 12 fr
        .byte $04,$28                       ; E-2    ins  2  len[8] = 48 fr
        .byte CMD_RETURN

; (not called by any song)
Pattern_19:
        .byte $5F,$0A                       ; B-9    ins  0  len[10]
        .byte CMD_RETURN

Pattern_1A:
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0E,$E2                       ; D-3    ins 14  len[2] = 6 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $10,$E2                       ; E-3    ins 14  len[2] = 6 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0E,$E2                       ; D-3    ins 14  len[2] = 6 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $10,$E2                       ; E-3    ins 14  len[2] = 6 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $15,$E4                       ; A-3    ins 14  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_1B:
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C5                       ; noise $09 ins 12  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$D4                       ; noise $09 ins 13  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C5                       ; noise $09 ins 12  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$D4                       ; noise $09 ins 13  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte CMD_RETURN

;======================================================================
; Song $05
;======================================================================
Song05_Sq1:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $24,$28                       ; C-5    ins  2  len[8] = 48 fr
        .byte CMD_END
; ---- 2 byte(s) not referenced by the sound engine ----
        .byte $A2,$90

Song05_Sq2:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $18,$52                       ; C-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $10,$56                       ; E-3    ins  5  len[6] = 24 fr
        .byte $1C,$28                       ; E-4    ins  2  len[8] = 48 fr
        .byte CMD_END

Song05_Tri:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $13,$E8                       ; G-3    ins 14  len[8] = 48 fr
        .byte $1F,$E4                       ; G-4    ins 14  len[4] = 12 fr
        .byte $1A,$E4                       ; D-4    ins 14  len[4] = 12 fr
        .byte $13,$E6                       ; G-3    ins 14  len[6] = 24 fr
        .byte $11,$E4                       ; F-3    ins 14  len[4] = 12 fr
        .byte $18,$E2                       ; C-4    ins 14  len[2] = 6 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E2                       ; G-3    ins 14  len[2] = 6 fr
        .byte $11,$E4                       ; F-3    ins 14  len[4] = 12 fr
        .byte $18,$E6                       ; C-4    ins 14  len[6] = 24 fr
        .byte $0C,$F8                       ; C-3    ins 15  len[8] = 48 fr
        .byte CMD_END

Song05_Noise:
        .byte CMD_CALL,$1B,$00,$01          ; Pattern_1B, transpose +0, play 1x
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C5                       ; noise $09 ins 12  len[5] = 18 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$D4                       ; noise $09 ins 13  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte CMD_END

Song05_DMC:
        .byte CMD_CALL,$2D,$00,$0C          ; Pattern_2D, transpose +0, play 12x
        .byte CMD_JUMP
        .word Song05_DMC

Pattern_2D:
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_RETURN

;======================================================================
; Song $06
;======================================================================
Song06_Sq1:
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $21,$55                       ; A-4    ins  5  len[5] = 18 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $23,$55                       ; B-4    ins  5  len[5] = 18 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $27,$58                       ; D#5    ins  5  len[8] = 48 fr
        .byte $27,$55                       ; D#5    ins  5  len[5] = 18 fr
        .byte $28,$55                       ; E-5    ins  5  len[5] = 18 fr
        .byte $26,$53                       ; D-5    ins  5  len[3] = 9 fr
        .byte $24,$55                       ; C-5    ins  5  len[5] = 18 fr
        .byte $23,$53                       ; B-4    ins  5  len[3] = 9 fr
        .byte $21,$55                       ; A-4    ins  5  len[5] = 18 fr
        .byte $23,$8A                       ; B-4    ins  8  len[10] = 96 fr
        .byte CMD_END

Song06_Sq2:
        .byte $13,$55                       ; G-3    ins  5  len[5] = 18 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $18,$55                       ; C-4    ins  5  len[5] = 18 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $23,$54                       ; B-4    ins  5  len[4] = 12 fr
        .byte $23,$58                       ; B-4    ins  5  len[8] = 48 fr
        .byte $23,$55                       ; B-4    ins  5  len[5] = 18 fr
        .byte $24,$55                       ; C-5    ins  5  len[5] = 18 fr
        .byte $23,$53                       ; B-4    ins  5  len[3] = 9 fr
        .byte $21,$55                       ; A-4    ins  5  len[5] = 18 fr
        .byte $1F,$53                       ; G-4    ins  5  len[3] = 9 fr
        .byte $1D,$55                       ; F-4    ins  5  len[5] = 18 fr
        .byte $1C,$8A                       ; E-4    ins  8  len[10] = 96 fr
        .byte CMD_END

Song06_Tri:
        .byte $18,$E5                       ; C-4    ins 14  len[5] = 18 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $18,$E4                       ; C-4    ins 14  len[4] = 12 fr
        .byte $1D,$E5                       ; F-4    ins 14  len[5] = 18 fr
        .byte $18,$E5                       ; C-4    ins 14  len[5] = 18 fr
        .byte $1D,$E4                       ; F-4    ins 14  len[4] = 12 fr
        .byte $1F,$E5                       ; G-4    ins 14  len[5] = 18 fr
        .byte $1A,$E5                       ; D-4    ins 14  len[5] = 18 fr
        .byte $1F,$E4                       ; G-4    ins 14  len[4] = 12 fr
        .byte $1F,$E8                       ; G-4    ins 14  len[8] = 48 fr
        .byte CMD_REST,$05                  ; rest len[5] = 18 fr
        .byte $1D,$F7                       ; F-4    ins 15  len[7] = 36 fr
        .byte $1F,$F7                       ; G-4    ins 15  len[7] = 36 fr
        .byte $8C,$0A                       ; C-3    ins 16  len[10] = 96 fr
        .byte $00,$0A                       ; C-2    ins  0  len[10] = 96 fr
        .byte CMD_END

Song06_Noise:
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_JUMP
        .word Song06_Noise

Song06_DMC:
        .byte CMD_CALL,$2E,$00,$10          ; Pattern_2E, transpose +0, play 16x
        .byte CMD_JUMP
        .word Song06_DMC

Pattern_2E:
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_DMC_REST,$0A              ; rest len[10] = 96 fr
        .byte CMD_RETURN

;======================================================================
; Song $07
;======================================================================
Song07_Sq1:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr

Loop_9194:
        .byte CMD_CALL,$1C,$0C,$01          ; Pattern_1C, transpose +12, play 1x
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte CMD_CALL,$1C,$0C,$01          ; Pattern_1C, transpose +12, play 1x
        .byte CMD_REST,$06                  ; rest len[6] = 24 fr
        .byte CMD_CALL,$20,$00,$01          ; Pattern_20, transpose +0, play 1x
        .byte CMD_CALL,$24,$00,$04          ; Pattern_24, transpose +0, play 4x
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_JUMP
        .word Loop_9194

Song07_Sq2:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr

Loop_91B5:
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$09                  ; rest len[9] = 72 fr
        .byte $29,$54                       ; F-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte CMD_CALL,$1D,$00,$01          ; Pattern_1D, transpose +0, play 1x
        .byte CMD_REST,$06                  ; rest len[6] = 24 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_CALL,$21,$00,$01          ; Pattern_21, transpose +0, play 1x
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_CALL,$25,$00,$03          ; Pattern_25, transpose +0, play 3x
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$0A                  ; rest len[10] = 96 fr
        .byte CMD_JUMP
        .word Loop_91B5

Song07_Tri:
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr
        .byte $5F,$0A                       ; B-9    ins  0  len[10] = 96 fr

Loop_91FA:
        .byte CMD_CALL,$1E,$0C,$01          ; Pattern_1E, transpose +12, play 1x
        .byte $1A,$E4                       ; D-4    ins 14  len[4] = 12 fr
        .byte $18,$E4                       ; C-4    ins 14  len[4] = 12 fr
        .byte CMD_CALL,$1E,$0C,$01          ; Pattern_1E, transpose +12, play 1x
        .byte CMD_REST,$06                  ; rest len[6] = 24 fr
        .byte CMD_CALL,$22,$0C,$01          ; Pattern_22, transpose +12, play 1x
        .byte CMD_CALL,$26,$18,$04          ; Pattern_26, transpose +24, play 4x
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E6                       ; G-3    ins 14  len[6] = 24 fr
        .byte $1F,$E4                       ; G-4    ins 14  len[4] = 12 fr
        .byte $1D,$E4                       ; F-4    ins 14  len[4] = 12 fr
        .byte $1C,$E4                       ; E-4    ins 14  len[4] = 12 fr
        .byte $1A,$E4                       ; D-4    ins 14  len[4] = 12 fr
        .byte $18,$E4                       ; C-4    ins 14  len[4] = 12 fr
        .byte $17,$E4                       ; B-3    ins 14  len[4] = 12 fr
        .byte $15,$E4                       ; A-3    ins 14  len[4] = 12 fr
        .byte $11,$E4                       ; F-3    ins 14  len[4] = 12 fr
        .byte CMD_JUMP
        .word Loop_91FA

Song07_Noise:
        .byte CMD_CALL,$1F,$00,$02          ; Pattern_1F, transpose +0, play 2x

Loop_9235:
        .byte CMD_CALL,$1F,$00,$08          ; Pattern_1F, transpose +0, play 8x
        .byte CMD_CALL,$23,$00,$14          ; Pattern_23, transpose +0, play 20x
        .byte CMD_CALL,$27,$00,$09          ; Pattern_27, transpose +0, play 9x
        .byte CMD_JUMP
        .word Loop_9235

Song07_DMC:
        .byte CMD_CALL,$2F,$00,$02          ; Pattern_2F, transpose +0, play 2x
        .byte CMD_CALL,$2F,$00,$08          ; Pattern_2F, transpose +0, play 8x
        .byte CMD_CALL,$30,$00,$14          ; Pattern_30, transpose +0, play 20x
        .byte CMD_CALL,$31,$00,$09          ; Pattern_31, transpose +0, play 9x
        .byte CMD_JUMP
        .word Song07_DMC

Pattern_2F:
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$55                       ; sample 5, rate 15, len[5] = 18 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$66                       ; sample 6, rate 15, len[6] = 24 fr
        .byte CMD_RETURN

Pattern_30:
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$22                       ; sample 2, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte $0F,$42                       ; sample 4, rate 15, len[2] = 6 fr
        .byte CMD_RETURN

Pattern_31:
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$64                       ; sample 6, rate 15, len[4] = 12 fr
        .byte $0F,$62                       ; sample 6, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$52                       ; sample 5, rate 15, len[2] = 6 fr
        .byte $0F,$54                       ; sample 5, rate 15, len[4] = 12 fr
        .byte CMD_RETURN

Pattern_1C:
        .byte $16,$55                       ; A#3    ins  5  len[5] = 18 fr
        .byte $16,$55                       ; A#3    ins  5  len[5] = 18 fr
        .byte $15,$54                       ; A-3    ins  5  len[4] = 12 fr
        .byte $16,$54                       ; A#3    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $18,$56                       ; C-4    ins  5  len[6] = 24 fr
        .byte $15,$55                       ; A-3    ins  5  len[5] = 18 fr
        .byte $15,$55                       ; A-3    ins  5  len[5] = 18 fr
        .byte $16,$54                       ; A#3    ins  5  len[4] = 12 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $13,$54                       ; G-3    ins  5  len[4] = 12 fr
        .byte $13,$56                       ; G-3    ins  5  len[6] = 24 fr
        .byte $10,$55                       ; E-3    ins  5  len[5] = 18 fr
        .byte $10,$55                       ; E-3    ins  5  len[5] = 18 fr
        .byte $11,$54                       ; F-3    ins  5  len[4] = 12 fr
        .byte $13,$54                       ; G-3    ins  5  len[4] = 12 fr
        .byte $0C,$54                       ; C-3    ins  5  len[4] = 12 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 24 fr
        .byte $0A,$55                       ; A#2    ins  5  len[5] = 18 fr
        .byte $0A,$55                       ; A#2    ins  5  len[5] = 18 fr
        .byte $0B,$54                       ; B-2    ins  5  len[4] = 12 fr
        .byte $0C,$56                       ; C-3    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_20:
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $24,$52                       ; C-5    ins  5  len[2] = 6 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $26,$56                       ; D-5    ins  5  len[6] = 24 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $24,$52                       ; C-5    ins  5  len[2] = 6 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $28,$54                       ; E-5    ins  5  len[4] = 12 fr
        .byte $26,$56                       ; D-5    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$58                  ; rest len[8] = 48 fr
        .byte CMD_REST,$55                  ; rest len[5] = 18 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$57                       ; G-4    ins  5  len[7] = 36 fr
        .byte CMD_REST,$56                  ; rest len[6] = 24 fr
        .byte CMD_REST,$55                  ; rest len[5] = 18 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$52                       ; D-4    ins  5  len[2] = 6 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$58                  ; rest len[8] = 48 fr
        .byte CMD_REST,$05                  ; rest len[5] = 18 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$52                       ; D-4    ins  5  len[2] = 6 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$58                  ; rest len[8] = 48 fr
        .byte $26,$52                       ; D-5    ins  5  len[2] = 6 fr
        .byte $29,$52                       ; F-5    ins  5  len[2] = 6 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 6 fr
        .byte $30,$54                       ; C-6    ins  5  len[4] = 12 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 6 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $32,$56                       ; D-6    ins  5  len[6] = 24 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$56                  ; rest len[6] = 24 fr
        .byte $2B,$64                       ; G-5    ins  6  len[4] = 12 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2B,$62                       ; G-5    ins  6  len[2] = 6 fr
        .byte CMD_REST,$55                  ; rest len[5] = 18 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $23,$52                       ; B-4    ins  5  len[2] = 6 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$57                       ; G-4    ins  5  len[7] = 36 fr
        .byte $2B,$64                       ; G-5    ins  6  len[4] = 12 fr
        .byte $2A,$62                       ; F#5    ins  6  len[2] = 6 fr
        .byte $2B,$62                       ; G-5    ins  6  len[2] = 6 fr
        .byte CMD_REST,$55                  ; rest len[5] = 18 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$52                       ; D-4    ins  5  len[2] = 6 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$58                  ; rest len[8] = 48 fr
        .byte CMD_REST,$05                  ; rest len[5] = 18 fr
        .byte $1D,$52                       ; F-4    ins  5  len[2] = 6 fr
        .byte $1F,$52                       ; G-4    ins  5  len[2] = 6 fr
        .byte $1D,$54                       ; F-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1A,$52                       ; D-4    ins  5  len[2] = 6 fr
        .byte $18,$54                       ; C-4    ins  5  len[4] = 12 fr
        .byte $1A,$54                       ; D-4    ins  5  len[4] = 12 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1C,$55                       ; E-4    ins  5  len[5] = 18 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte CMD_REST,$58                  ; rest len[8] = 48 fr
        .byte $26,$52                       ; D-5    ins  5  len[2] = 6 fr
        .byte $29,$52                       ; F-5    ins  5  len[2] = 6 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 6 fr
        .byte $30,$54                       ; C-6    ins  5  len[4] = 12 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $2D,$52                       ; A-5    ins  5  len[2] = 6 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $2F,$54                       ; B-5    ins  5  len[4] = 12 fr
        .byte $32,$56                       ; D-6    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_24:
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte CMD_REST,$5A                  ; rest len[10] = 96 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $21,$52                       ; A-4    ins  5  len[2] = 6 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $1F,$54                       ; G-4    ins  5  len[4] = 12 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $1F,$56                       ; G-4    ins  5  len[6] = 24 fr
        .byte CMD_REST,$5A                  ; rest len[10] = 96 fr
        .byte CMD_RETURN

Pattern_1D:
        .byte $26,$55                       ; D-5    ins  5  len[5] = 18 fr
        .byte $26,$55                       ; D-5    ins  5  len[5] = 18 fr
        .byte $24,$54                       ; C-5    ins  5  len[4] = 12 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $29,$54                       ; F-5    ins  5  len[4] = 12 fr
        .byte $28,$56                       ; E-5    ins  5  len[6] = 24 fr
        .byte $24,$55                       ; C-5    ins  5  len[5] = 18 fr
        .byte $24,$55                       ; C-5    ins  5  len[5] = 18 fr
        .byte $26,$54                       ; D-5    ins  5  len[4] = 12 fr
        .byte $27,$54                       ; D#5    ins  5  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $22,$56                       ; A#4    ins  5  len[6] = 24 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $1F,$55                       ; G-4    ins  5  len[5] = 18 fr
        .byte $21,$54                       ; A-4    ins  5  len[4] = 12 fr
        .byte $22,$54                       ; A#4    ins  5  len[4] = 12 fr
        .byte $1C,$54                       ; E-4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1A,$55                       ; D-4    ins  5  len[5] = 18 fr
        .byte $1B,$54                       ; D#4    ins  5  len[4] = 12 fr
        .byte $1C,$56                       ; E-4    ins  5  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_21:
        .byte CMD_REST,$69                  ; rest len[9] = 72 fr
        .byte $28,$64                       ; E-5    ins  6  len[4] = 12 fr
        .byte $27,$62                       ; D#5    ins  6  len[2] = 6 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte CMD_REST,$6A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$69                  ; rest len[9] = 72 fr
        .byte $28,$64                       ; E-5    ins  6  len[4] = 12 fr
        .byte $27,$62                       ; D#5    ins  6  len[2] = 6 fr
        .byte $28,$62                       ; E-5    ins  6  len[2] = 6 fr
        .byte CMD_REST,$6A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$68                  ; rest len[8] = 48 fr
        .byte CMD_REST,$64                  ; rest len[4] = 12 fr
        .byte $24,$34                       ; C-5    ins  3  len[4] = 12 fr
        .byte $26,$34                       ; D-5    ins  3  len[4] = 12 fr
        .byte $28,$32                       ; E-5    ins  3  len[2] = 6 fr
        .byte $29,$38                       ; F-5    ins  3  len[8] = 48 fr
        .byte CMD_REST,$62                  ; rest len[2] = 6 fr
        .byte CMD_REST,$68                  ; rest len[8] = 48 fr
        .byte CMD_REST,$6A                  ; rest len[10] = 96 fr
        .byte CMD_REST,$6A                  ; rest len[10] = 96 fr
        .byte CMD_RETURN

Pattern_25:
        .byte $2D,$36                       ; A-5    ins  3  len[6] = 24 fr
        .byte $2F,$36                       ; B-5    ins  3  len[6] = 24 fr
        .byte $30,$36                       ; C-6    ins  3  len[6] = 24 fr
        .byte $2D,$36                       ; A-5    ins  3  len[6] = 24 fr
        .byte $2B,$36                       ; G-5    ins  3  len[6] = 24 fr
        .byte $2D,$35                       ; A-5    ins  3  len[5] = 18 fr
        .byte $28,$38                       ; E-5    ins  3  len[8] = 48 fr
        .byte CMD_REST,$62                  ; rest len[2] = 6 fr
        .byte $2D,$36                       ; A-5    ins  3  len[6] = 24 fr
        .byte $2F,$36                       ; B-5    ins  3  len[6] = 24 fr
        .byte $30,$36                       ; C-6    ins  3  len[6] = 24 fr
        .byte $2D,$36                       ; A-5    ins  3  len[6] = 24 fr
        .byte $32,$36                       ; D-6    ins  3  len[6] = 24 fr
        .byte $34,$35                       ; E-6    ins  3  len[5] = 18 fr
        .byte $32,$38                       ; D-6    ins  3  len[8] = 48 fr
        .byte CMD_REST,$62                  ; rest len[2] = 6 fr
        .byte CMD_RETURN

Pattern_1E:
        .byte $16,$E5                       ; A#3    ins 14  len[5] = 18 fr
        .byte $16,$E5                       ; A#3    ins 14  len[5] = 18 fr
        .byte $15,$E4                       ; A-3    ins 14  len[4] = 12 fr
        .byte $16,$E4                       ; A#3    ins 14  len[4] = 12 fr
        .byte $1A,$E4                       ; D-4    ins 14  len[4] = 12 fr
        .byte $18,$E6                       ; C-4    ins 14  len[6] = 24 fr
        .byte $15,$E5                       ; A-3    ins 14  len[5] = 18 fr
        .byte $15,$E5                       ; A-3    ins 14  len[5] = 18 fr
        .byte $16,$E4                       ; A#3    ins 14  len[4] = 12 fr
        .byte $18,$E4                       ; C-4    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $13,$E6                       ; G-3    ins 14  len[6] = 24 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $11,$E4                       ; F-3    ins 14  len[4] = 12 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E6                       ; C-3    ins 14  len[6] = 24 fr
        .byte $0A,$E5                       ; A#2    ins 14  len[5] = 18 fr
        .byte $0A,$E5                       ; A#2    ins 14  len[5] = 18 fr
        .byte $0B,$E4                       ; B-2    ins 14  len[4] = 12 fr
        .byte $0C,$E6                       ; C-3    ins 14  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_22:
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0B,$E4                       ; B-2    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0B,$E4                       ; B-2    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $0B,$E5                       ; B-2    ins 14  len[5] = 18 fr
        .byte $17,$E4                       ; B-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $09,$E4                       ; A-2    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $0B,$E5                       ; B-2    ins 14  len[5] = 18 fr
        .byte $17,$E4                       ; B-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $10,$E5                       ; E-3    ins 14  len[5] = 18 fr
        .byte $09,$E4                       ; A-2    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $13,$E5                       ; G-3    ins 14  len[5] = 18 fr
        .byte $0E,$E5                       ; D-3    ins 14  len[5] = 18 fr
        .byte $13,$E4                       ; G-3    ins 14  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_26:
        .byte $05,$E5                       ; F-2    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $05,$E5                       ; F-2    ins 14  len[5] = 18 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E4                       ; C-3    ins 14  len[4] = 12 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0B,$E5                       ; B-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $07,$E5                       ; G-2    ins 14  len[5] = 18 fr
        .byte $0B,$E5                       ; B-2    ins 14  len[5] = 18 fr
        .byte $0E,$E4                       ; D-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte $09,$E5                       ; A-2    ins 14  len[5] = 18 fr
        .byte $0C,$E5                       ; C-3    ins 14  len[5] = 18 fr
        .byte $10,$E4                       ; E-3    ins 14  len[4] = 12 fr
        .byte CMD_RETURN

Pattern_1F:
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B5                       ; noise $09 ins 11  len[5] = 18 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B6                       ; noise $09 ins 11  len[6] = 24 fr
        .byte CMD_RETURN

Pattern_23:
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C2                       ; noise $09 ins 12  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C2                       ; noise $09 ins 12  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C2                       ; noise $09 ins 12  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$C2                       ; noise $09 ins 12  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte CMD_RETURN

Pattern_27:
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B6                       ; noise $09 ins 11  len[6] = 24 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B2                       ; noise $09 ins 11  len[2] = 6 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$C4                       ; noise $09 ins 12  len[4] = 12 fr
        .byte $09,$B4                       ; noise $09 ins 11  len[4] = 12 fr
        .byte $09,$B6                       ; noise $09 ins 11  len[6] = 24 fr
        .byte CMD_RETURN

;
; Pattern (subroutine) pointers, used by CMD_CALL (50 entries, split low/high byte tables)
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
        .lobytes Pattern_2C, Pattern_2D, Pattern_2E, Pattern_2F ; 44-47
        .lobytes Pattern_30, Pattern_31     ; 48-49

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
        .hibytes Pattern_2C, Pattern_2D, Pattern_2E, Pattern_2F ; 44-47
        .hibytes Pattern_30, Pattern_31     ; 48-49

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
        sta sDmcPriority
        sta sDmcActive
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
        bcs Sfx_PlayDmc
        tax
        lda sNewPriority
        cmp sPriority,x
        beq L9713
        bcc L9713
        jmp L9715

L9713:
        pla
        rts

L9715:
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

;----------------------------------------------------------------------
; DMC effect: take the DMC away from the music and start the sample.
Sfx_PlayDmc:
        lda sNewPriority
        cmp sDmcPriority
        beq L9713
        bcc L9713
        jmp L977B

;----------------------------------------------------------------------
; unreferenced code (nothing jumps here)
Unused_PullReturn:
        pla
        rts

L977B:
        sta sDmcPriority
        pla
        lda #$00
        sta mDmcFreq
        sta mDmcRaw
        sta mDmcStart
        sta mDmcLen
        lda mApuStatus
        and #$EF
        sta mApuStatus
        jsr Dmc_WriteRegs
        lda mDmcFlags
        and #$FD
        sta mDmcFlags
        lda #$01
        sta sDmcActive
        iny
        lda (zPtr),y
        sta mDmcStart
        iny
        lda (zPtr),y
        sta mDmcLen
        iny
        lda (zPtr),y
        sta mDmcFreq
        lda mApuStatus
        ora #$10
        sta mApuStatus
        jsr Dmc_WriteRegs
        rts

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
        lda sDmcActive
        beq L9808
        lda APU_STATUS
        and #$10
        bne L9808
        lda mDmcFlagsSave
        sta mDmcFlags
        lda #$00
        sta sDmcPriority
        sta sDmcActive
        sta mDmcFreq
        sta mDmcRaw
        sta mDmcStart
        sta mDmcLen
        lda mApuStatus
        and #$EF
        sta mApuStatus
        jsr Dmc_WriteRegs

L9808:
        rts

;----------------------------------------------------------------------
; X = channel.
Sfx_UpdateChannel:
        lda sTimer,x
        beq L9812
        dec sTimer,x
        rts

L9812:
        lda sSpeed,x
        sta sTimer,x
        lda sPtrHi,x
        bne L981E
        rts

L981E:
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
        bne L9846
        ldy sPriority,x
        lda sId,x
        tax
        tya
        jmp Sfx_Play

L9846:
        cpx #$03
        bne L9862
        cmp mReg2,x
        beq L9885
        sta mReg2,x
        lda #$00
        sta mReg3,x
        lda mRegDirty,x
        ora #$03
        sta mRegDirty,x
        jmp L9885

L9862:
        cmp mReg3,x
        beq L9872
        sta mReg3,x
        lda mRegDirty,x
        ora #$01
        sta mRegDirty,x

L9872:
        iny
        lda (zPtr),y
        cmp mReg2,x
        beq L9885
        sta mReg2,x
        lda mRegDirty,x
        ora #$02
        sta mRegDirty,x

L9885:
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
        rts

;
; Sound effect pointers (index passed in X to Sfx_Play) (24 entries, split low/high byte tables)
SfxHi:
        .hibytes Sfx_00, Sfx_01, Sfx_02, Sfx_03 ; 0-3
        .hibytes Sfx_04, Sfx_05, Sfx_06, Sfx_07 ; 4-7
        .hibytes Sfx_08, Sfx_09, Sfx_0A, Sfx_0B ; 8-11
        .hibytes Sfx_0C, Sfx_0D, Sfx_0E, Sfx_0F ; 12-15
        .hibytes Sfx_10, Sfx_11, Sfx_12, Sfx_13 ; 16-19
        .hibytes Sfx_14, Sfx_15, Sfx_16, Sfx_17 ; 20-23

SfxLo:
        .lobytes Sfx_00, Sfx_01, Sfx_02, Sfx_03 ; 0-3
        .lobytes Sfx_04, Sfx_05, Sfx_06, Sfx_07 ; 4-7
        .lobytes Sfx_08, Sfx_09, Sfx_0A, Sfx_0B ; 8-11
        .lobytes Sfx_0C, Sfx_0D, Sfx_0E, Sfx_0F ; 12-15
        .lobytes Sfx_10, Sfx_11, Sfx_12, Sfx_13 ; 16-19
        .lobytes Sfx_14, Sfx_15, Sfx_16, Sfx_17 ; 20-23

Sfx_00:
        .byte $00                           ; channel: Sq1
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_01:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_02:
        .byte $02                           ; channel: Tri
        .byte $00                           ; speed (frames per step - 1)
        .byte $00,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_03:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $10,$00,$01                   ; reg0, reg3, reg2
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_04:
        .byte $03                           ; channel: Noise
        .byte $03                           ; speed (frames per step - 1)
        .byte $21,$00,$0C                   ; reg0, reg3, reg2
        .byte $21,$0F                       ; reg0, period
        .byte $22,$0A                       ; reg0, period
        .byte $21,$0D                       ; reg0, period
        .byte $21,$09                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $28,$0A                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $27,$0D                       ; reg0, period
        .byte $29,$09                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_05:
        .byte $03                           ; channel: Noise
        .byte $05                           ; speed (frames per step - 1)
        .byte $22,$00,$0E                   ; reg0, reg3, reg2
        .byte $22,$0D                       ; reg0, period
        .byte $3F,$0D                       ; reg0, period
        .byte $3C,$0D                       ; reg0, period
        .byte $3A,$0D                       ; reg0, period
        .byte $39,$0D                       ; reg0, period
        .byte $38,$0D                       ; reg0, period
        .byte $37,$0D                       ; reg0, period
        .byte $36,$0D                       ; reg0, period
        .byte $36,$0D                       ; reg0, period
        .byte $35,$0D                       ; reg0, period
        .byte $34,$0D                       ; reg0, period
        .byte $33,$0D                       ; reg0, period
        .byte $32,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $31,$0D                       ; reg0, period
        .byte $31,$30                       ; reg0, period
        .byte $0D,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_06:
        .byte $02                           ; channel: Tri
        .byte $02                           ; speed (frames per step - 1)
        .byte $FF,$01,$A0                   ; reg0, reg3, reg2
        .byte $FF,$01,$A8                   ; reg0, reg3, reg2
        .byte $FF,$01,$B0                   ; reg0, reg3, reg2
        .byte $FF,$01,$B8                   ; reg0, reg3, reg2
        .byte $FF,$01,$C0                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_07:
        .byte $03                           ; channel: Noise
        .byte $02                           ; speed (frames per step - 1)
        .byte $21,$00,$0E                   ; reg0, reg3, reg2
        .byte $21,$0D                       ; reg0, period
        .byte $21,$0E                       ; reg0, period
        .byte $21,$0D                       ; reg0, period
        .byte $22,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3C,$0F                       ; reg0, period
        .byte $3A,$0F                       ; reg0, period
        .byte $39,$0F                       ; reg0, period
        .byte $37,$0F                       ; reg0, period
        .byte $35,$0F                       ; reg0, period
        .byte $34,$0F                       ; reg0, period
        .byte $32,$0F                       ; reg0, period
        .byte $31,$0F                       ; reg0, period
        .byte $31,$0F                       ; reg0, period
        .byte $31,$0F                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_08:
        .byte $02                           ; channel: Tri
        .byte $01                           ; speed (frames per step - 1)
        .byte $FF,$01,$80                   ; reg0, reg3, reg2
        .byte $FF,$01,$90                   ; reg0, reg3, reg2
        .byte $FF,$01,$A0                   ; reg0, reg3, reg2
        .byte $FF,$01,$B0                   ; reg0, reg3, reg2
        .byte $FF,$01,$C0                   ; reg0, reg3, reg2
        .byte $FF,$01,$D0                   ; reg0, reg3, reg2
        .byte $FF,$01,$E0                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_09:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; speed (frames per step - 1)
        .byte $BF,$04,$00                   ; reg0, reg3, reg2
        .byte $BF,$03,$FF                   ; reg0, reg3, reg2
        .byte $BE,$03,$E0                   ; reg0, reg3, reg2
        .byte $BE,$03,$C0                   ; reg0, reg3, reg2
        .byte $BC,$03,$B0                   ; reg0, reg3, reg2
        .byte $BC,$03,$90                   ; reg0, reg3, reg2
        .byte $BB,$03,$70                   ; reg0, reg3, reg2
        .byte $BB,$03,$50                   ; reg0, reg3, reg2
        .byte $B8,$03,$40                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_0A:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$0F                   ; reg0, reg3, reg2
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0D                       ; reg0, period
        .byte $3F,$0C                       ; reg0, period
        .byte $3F,$0B                       ; reg0, period
        .byte $3F,$0A                       ; reg0, period
        .byte $3F,$0A                       ; reg0, period
        .byte $3F,$0A                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $30,$01                       ; reg0, period
        .byte $3F,$04                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_0B:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$06                   ; reg0, reg3, reg2
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$07                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$08                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$09                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0A                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0B                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0C                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $3F,$00                       ; reg0, period -> end
        .byte $00,$00,$00                   ; never read

Sfx_0C:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$06                   ; reg0, reg3, reg2
        .byte $3F,$09                       ; reg0, period
        .byte $3F,$06                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0F                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_0D:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $BF,$00,$2F                   ; reg0, reg3, reg2
        .byte $B0,$00,$2F                   ; reg0, reg3, reg2
        .byte $BF,$00,$2C                   ; reg0, reg3, reg2
        .byte $BC,$00,$2C                   ; reg0, reg3, reg2
        .byte $B8,$00,$2C                   ; reg0, reg3, reg2
        .byte $BF,$00,$2A                   ; reg0, reg3, reg2
        .byte $B8,$00,$2A                   ; reg0, reg3, reg2
        .byte $BF,$00,$28                   ; reg0, reg3, reg2
        .byte $B8,$00,$28                   ; reg0, reg3, reg2
        .byte $B0,$00,$00                   ; reg0, reg3, reg2 -> end
        .byte $00,$00,$00                   ; never read

Sfx_0E:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $BC,$00,$38                   ; reg0, reg3, reg2
        .byte $BC,$00,$3A                   ; reg0, reg3, reg2
        .byte $BC,$00,$3C                   ; reg0, reg3, reg2
        .byte $BC,$00,$3E                   ; reg0, reg3, reg2
        .byte $BC,$00,$40                   ; reg0, reg3, reg2
        .byte $BC,$00,$42                   ; reg0, reg3, reg2
        .byte $BC,$00,$44                   ; reg0, reg3, reg2
        .byte $BC,$00,$46                   ; reg0, reg3, reg2
        .byte $BC,$00,$48                   ; reg0, reg3, reg2
        .byte $BC,$00,$4A                   ; reg0, reg3, reg2
        .byte $BC,$00,$4C                   ; reg0, reg3, reg2
        .byte $BC,$00,$4E                   ; reg0, reg3, reg2
        .byte $BC,$00,$50                   ; reg0, reg3, reg2
        .byte $BC,$00,$52                   ; reg0, reg3, reg2
        .byte $BC,$00,$54                   ; reg0, reg3, reg2
        .byte $BC,$00,$56                   ; reg0, reg3, reg2
        .byte $BC,$00,$58                   ; reg0, reg3, reg2
        .byte $BC,$00,$5A                   ; reg0, reg3, reg2
        .byte $BC,$00,$5C                   ; reg0, reg3, reg2
        .byte $BC,$00,$5E                   ; reg0, reg3, reg2
        .byte $BC,$00,$60                   ; reg0, reg3, reg2
        .byte $BC,$00,$62                   ; reg0, reg3, reg2
        .byte $BC,$00,$64                   ; reg0, reg3, reg2
        .byte $BC,$00,$66                   ; reg0, reg3, reg2
        .byte $BC,$00,$68                   ; reg0, reg3, reg2
        .byte $BC,$00,$6A                   ; reg0, reg3, reg2
        .byte $BC,$00,$6C                   ; reg0, reg3, reg2
        .byte $BC,$00,$6E                   ; reg0, reg3, reg2
        .byte $BC,$00,$70                   ; reg0, reg3, reg2
        .byte $B0,$00,$70                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_0F:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $3F,$00,$8F                   ; reg0, reg3, reg2
        .byte $3F,$00,$8C                   ; reg0, reg3, reg2
        .byte $30,$00,$8C                   ; reg0, reg3, reg2
        .byte $30,$00,$8C                   ; reg0, reg3, reg2
        .byte $30,$00,$8C                   ; reg0, reg3, reg2
        .byte $30,$00,$8C                   ; reg0, reg3, reg2
        .byte $3F,$00,$72                   ; reg0, reg3, reg2
        .byte $3F,$00,$70                   ; reg0, reg3, reg2
        .byte $30,$00,$70                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_10:
        .byte $03                           ; channel: Noise
        .byte $00                           ; speed (frames per step - 1)
        .byte $38,$00,$0E                   ; reg0, reg3, reg2
        .byte $38,$0E                       ; reg0, period
        .byte $3A,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $38,$0D                       ; reg0, period
        .byte $3A,$0D                       ; reg0, period
        .byte $3F,$0D                       ; reg0, period
        .byte $38,$0C                       ; reg0, period
        .byte $3A,$0C                       ; reg0, period
        .byte $3F,$0C                       ; reg0, period
        .byte $38,$0B                       ; reg0, period
        .byte $3A,$0B                       ; reg0, period
        .byte $3F,$0B                       ; reg0, period
        .byte $38,$0A                       ; reg0, period
        .byte $3A,$0A                       ; reg0, period
        .byte $3F,$0A                       ; reg0, period
        .byte $00,$0A                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
        .byte $00                           ; never read

Sfx_11:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; speed (frames per step - 1)
        .byte $34,$01,$40                   ; reg0, reg3, reg2
        .byte $36,$01,$30                   ; reg0, reg3, reg2
        .byte $78,$01,$20                   ; reg0, reg3, reg2
        .byte $BA,$01,$10                   ; reg0, reg3, reg2
        .byte $FF,$01,$00                   ; reg0, reg3, reg2
        .byte $34,$01,$30                   ; reg0, reg3, reg2
        .byte $36,$01,$20                   ; reg0, reg3, reg2
        .byte $78,$01,$10                   ; reg0, reg3, reg2
        .byte $BA,$01,$00                   ; reg0, reg3, reg2
        .byte $FF,$00,$F0                   ; reg0, reg3, reg2
        .byte $34,$01,$10                   ; reg0, reg3, reg2
        .byte $36,$01,$00                   ; reg0, reg3, reg2
        .byte $78,$00,$F0                   ; reg0, reg3, reg2
        .byte $BA,$00,$E0                   ; reg0, reg3, reg2
        .byte $FF,$00,$D0                   ; reg0, reg3, reg2
        .byte $32,$00,$F0                   ; reg0, reg3, reg2
        .byte $34,$00,$E0                   ; reg0, reg3, reg2
        .byte $76,$00,$D0                   ; reg0, reg3, reg2
        .byte $B8,$00,$C0                   ; reg0, reg3, reg2
        .byte $FA,$00,$B0                   ; reg0, reg3, reg2
        .byte $31,$00,$D0                   ; reg0, reg3, reg2
        .byte $33,$00,$C0                   ; reg0, reg3, reg2
        .byte $75,$00,$B0                   ; reg0, reg3, reg2
        .byte $B7,$00,$A0                   ; reg0, reg3, reg2
        .byte $F9,$00,$90                   ; reg0, reg3, reg2
        .byte $31,$00,$B0                   ; reg0, reg3, reg2
        .byte $32,$00,$A0                   ; reg0, reg3, reg2
        .byte $74,$00,$90                   ; reg0, reg3, reg2
        .byte $B6,$00,$80                   ; reg0, reg3, reg2
        .byte $F7,$00,$70                   ; reg0, reg3, reg2
        .byte $31,$00,$B0                   ; reg0, reg3, reg2
        .byte $32,$00,$A0                   ; reg0, reg3, reg2
        .byte $73,$00,$90                   ; reg0, reg3, reg2
        .byte $B4,$00,$80                   ; reg0, reg3, reg2
        .byte $F5,$00,$70                   ; reg0, reg3, reg2
        .byte $31,$00,$A0                   ; reg0, reg3, reg2
        .byte $31,$00,$98                   ; reg0, reg3, reg2
        .byte $72,$00,$90                   ; reg0, reg3, reg2
        .byte $B2,$00,$88                   ; reg0, reg3, reg2
        .byte $F3,$00,$80                   ; reg0, reg3, reg2
        .byte $F3,$00,$78                   ; reg0, reg3, reg2
        .byte $F3,$00,$60                   ; reg0, reg3, reg2
        .byte $F2,$00,$6E                   ; reg0, reg3, reg2
        .byte $F2,$00,$6C                   ; reg0, reg3, reg2
        .byte $F2,$00,$6A                   ; reg0, reg3, reg2
        .byte $F1,$00,$68                   ; reg0, reg3, reg2
        .byte $F1,$00,$66                   ; reg0, reg3, reg2
        .byte $F1,$00,$64                   ; reg0, reg3, reg2
        .byte $F1,$00,$62                   ; reg0, reg3, reg2
        .byte $F1,$00,$60                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_12:
        .byte $00                           ; channel: Sq1
        .byte $01                           ; speed (frames per step - 1)
        .byte $7A,$00,$80                   ; reg0, reg3, reg2
        .byte $7B,$00,$78                   ; reg0, reg3, reg2
        .byte $7C,$00,$70                   ; reg0, reg3, reg2
        .byte $7D,$00,$68                   ; reg0, reg3, reg2
        .byte $7F,$00,$60                   ; reg0, reg3, reg2
        .byte $7F,$00,$68                   ; reg0, reg3, reg2
        .byte $7D,$00,$78                   ; reg0, reg3, reg2
        .byte $7B,$00,$80                   ; reg0, reg3, reg2
        .byte $7A,$00,$88                   ; reg0, reg3, reg2
        .byte $76,$00,$98                   ; reg0, reg3, reg2
        .byte $75,$00,$A0                   ; reg0, reg3, reg2
        .byte $73,$00,$B0                   ; reg0, reg3, reg2
        .byte $B0,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_13:
        .byte $01                           ; channel: Sq2
        .byte $01                           ; speed (frames per step - 1)
        .byte $7A,$00,$83                   ; reg0, reg3, reg2
        .byte $7B,$00,$7B                   ; reg0, reg3, reg2
        .byte $7C,$00,$73                   ; reg0, reg3, reg2
        .byte $7D,$00,$6B                   ; reg0, reg3, reg2
        .byte $7F,$00,$63                   ; reg0, reg3, reg2
        .byte $7F,$00,$6B                   ; reg0, reg3, reg2
        .byte $7D,$00,$7B                   ; reg0, reg3, reg2
        .byte $7B,$00,$83                   ; reg0, reg3, reg2
        .byte $7A,$00,$8B                   ; reg0, reg3, reg2
        .byte $76,$00,$9B                   ; reg0, reg3, reg2
        .byte $75,$00,$A3                   ; reg0, reg3, reg2
        .byte $73,$00,$B3                   ; reg0, reg3, reg2
        .byte $30,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_14:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $BF,$00,$43                   ; reg0, reg3, reg2
        .byte $B6,$00,$43                   ; reg0, reg3, reg2
        .byte $BF,$00,$3B                   ; reg0, reg3, reg2
        .byte $B6,$00,$3B                   ; reg0, reg3, reg2
        .byte $BF,$00,$35                   ; reg0, reg3, reg2
        .byte $B6,$00,$35                   ; reg0, reg3, reg2
        .byte $BF,$00,$32                   ; reg0, reg3, reg2
        .byte $BA,$00,$32                   ; reg0, reg3, reg2
        .byte $B8,$00,$32                   ; reg0, reg3, reg2
        .byte $B6,$00,$32                   ; reg0, reg3, reg2
        .byte $B4,$00,$32                   ; reg0, reg3, reg2
        .byte $B2,$00,$32                   ; reg0, reg3, reg2
        .byte $B1,$00,$32                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_15:
        .byte $01                           ; channel: Sq2
        .byte $00                           ; speed (frames per step - 1)
        .byte $BF,$00,$50                   ; reg0, reg3, reg2
        .byte $BB,$00,$50                   ; reg0, reg3, reg2
        .byte $B7,$00,$50                   ; reg0, reg3, reg2
        .byte $BF,$00,$4B                   ; reg0, reg3, reg2
        .byte $BD,$00,$4B                   ; reg0, reg3, reg2
        .byte $BB,$00,$4B                   ; reg0, reg3, reg2
        .byte $B9,$00,$4B                   ; reg0, reg3, reg2
        .byte $B7,$00,$4B                   ; reg0, reg3, reg2
        .byte $B5,$00,$4B                   ; reg0, reg3, reg2
        .byte $B4,$00,$4B                   ; reg0, reg3, reg2
        .byte $B4,$00,$4B                   ; reg0, reg3, reg2
        .byte $B4,$00,$4B                   ; reg0, reg3, reg2
        .byte $B1,$00,$4B                   ; reg0, reg3, reg2
        .byte $00,$00,$00                   ; reg0, reg3, reg2 -> end

Sfx_16:
        .byte $04                           ; channel: DMC
        .byte $2F,$3F,$0F                   ; DMC_START ($CBC0), DMC_LEN (1009 bytes), DMC_FREQ

Sfx_17:
        .byte $03                           ; channel: Noise
        .byte $03                           ; speed (frames per step - 1)
        .byte $32,$00,$0E                   ; reg0, reg3, reg2
        .byte $33,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $35,$0E                       ; reg0, period
        .byte $36,$0E                       ; reg0, period
        .byte $37,$0E                       ; reg0, period
        .byte $38,$0E                       ; reg0, period
        .byte $39,$0E                       ; reg0, period
        .byte $3A,$0E                       ; reg0, period
        .byte $3B,$0E                       ; reg0, period
        .byte $3C,$0E                       ; reg0, period
        .byte $3D,$0E                       ; reg0, period
        .byte $3E,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3F,$0E                       ; reg0, period
        .byte $3E,$0E                       ; reg0, period
        .byte $3D,$0E                       ; reg0, period
        .byte $3C,$0E                       ; reg0, period
        .byte $3B,$0E                       ; reg0, period
        .byte $3A,$0E                       ; reg0, period
        .byte $39,$0E                       ; reg0, period
        .byte $38,$0E                       ; reg0, period
        .byte $37,$0E                       ; reg0, period
        .byte $36,$0E                       ; reg0, period
        .byte $35,$0E                       ; reg0, period
        .byte $34,$0E                       ; reg0, period
        .byte $33,$0E                       ; reg0, period
        .byte $32,$0E                       ; reg0, period
        .byte $31,$0E                       ; reg0, period
        .byte $31,$0E                       ; reg0, period
        .byte $31,$0E                       ; reg0, period
        .byte $30,$0E                       ; reg0, period
        .byte $30,$0E                       ; reg0, period
        .byte $00,$00                       ; reg0, period -> end
; ---- 856 byte(s) not referenced by the sound engine ----
        .byte $0F
        .res 855, $00
