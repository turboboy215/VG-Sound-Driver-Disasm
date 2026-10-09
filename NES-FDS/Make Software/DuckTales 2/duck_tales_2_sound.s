;==============================================================================
;  Make Software NES sound engine - DUCK TALES 2 (E)
;  Version with two entry points and no fade.
;
;  Source: Duck Tales 2 (E) [!].nes, UxROM, 16K PRG bank 0 (file offset $0010)
;  at $8000-$ADED. $ADEE-$ADFF is $FF fill and game data starts at $AE00.
;  The fixed bank switches bank 0 in before each call.
;  Reassembles byte-identically:  ca65 duck_tales_2_sound.s
;               ld65 -C duck_tales_2_sound.cfg -o out.bin duck_tales_2_sound.o
;
;  ENTRY POINTS (both called from the NMI handler)
;    $8000 Sound_Update     request, music channels 0-3, APU output
;    $8003 Sound_UpdateSfx  sound effect channels 4-5 (called earlier in NMI)
;
;  19 music tracks ($01-$14), 62 sound effects ($20-$5D); entries $10 and
;  $15-$1F point at the empty header. Requests $7B/$7C do nothing; the
;  fade variables zFadeIn/zFadeOut/zMasterAtten are only ever cleared.
;
;  CHANNELS
;    0 Sq1, 1 Sq2, 2 Tri, 3 Noise (music)   4 Sq2, 5 Noise (sound effects)
;    While channel 4 or 5 runs, the music's square 2 / noise keep running but
;    are not written to the APU (OutputSkipMask).
;
;  REQUESTS (zSoundReq = $F0; the game writes a number, bit 7 is set when
;    the engine has taken it; one request per frame)
;    $00        Sound_Init (silence and reset everything)
;    $01-$78    Sound_Start: SoundTable entry
;    $79 resume  $7A pause  $7B / $7C see below  $7D stop music  $7E stop
;    sound effects  $7F Sound_Init
;
;  SOUND HEADER (SoundTable entry)
;    byte    bits 0-3 = music channels 0-3, bits 4-5 = sound effect channels
;            4-5 (if bits 4-5 are set, bits 0-3 are not loaded)
;    .word   one track pointer per set bit, lowest channel first
;    A music header with no bits ($00) stops the music.
;
;  TRACK DATA (one byte per event; commands may have arguments)
;    $00-$BF  note: high nibble = note C..B (0-11), low nibble = length - 1
;    $C0-$CF  rest, low nibble = length - 1
;             length in frames = (n + 1) * speed (CMD_SPEED; speed 0 = x1)
;    Pitch = PeriodTable[octave*12 + note + CMD_TRANSPOSE + CMD_TRANSPOSE_ADD]
;    + CMD_DETUNE. On channel 3 the note picks drum macro mDrumMap[note]
;    (mDrumMap = 0-12 when a song starts). On channel 5 the noise period is
;    (note - both transposes) & 15; the octave is ignored.
;    Comment notation: note names use the octave command in effect (C-4 =
;    octave 4), before transposes; "a/b" = more than one octave reaches it.
;    "= n fr" is shown when only one speed can be in effect.
;    Commands:
;      $D0-$D6 CMD_OCTAVE0-6        octave
;      $D7 CMD_OCTAVE_UP / $D8 CMD_OCTAVE_DOWN
;      $D9 CMD_TRANSPOSE n          transpose = n (signed)
;      $DA CMD_TRANSPOSE_ADD n      second transpose += n
;      $DB CMD_DETUNE n             signed period offset
;      $E0 CMD_SPEED n              length multiplier
;      $E1 CMD_DUTY n               duty n & 3
;      $E2 CMD_ENVELOPE n           volume envelope n, starts with the next note
;      $E3-$E5 n                    argument skipped (no effect)
;      $E8 CMD_TIE                  next note keeps the envelope and period
;      $E9 CMD_VOLUME n             attenuation = n (subtracted from the volume)
;      $EA CMD_VOLUME_ADD n         attenuation += n
;      $EB CMD_SWEEP n / $EC CMD_SWEEP_OFF (= $08)
;      $ED CMD_DRUM_SWAP xy         swap mDrumMap[x] and mDrumMap[y] (unused)
;      $F0 CMD_LOOP n ... $F1 CMD_LOOP_END     play the block n times
;      $F2 CMD_CALL .word sub ... $F3 CMD_RETURN
;      $F8 CMD_JUMP .word addr
;      $FF CMD_END                  stop the channel
;      Loops and calls share a 16-byte stack per channel (nesting allowed).
;      $DC-$DF, $E6, $E7, $EE, $EF, $F4-$F7, $F9-$FE have no handler
;      ($0000 in CmdTable) and would crash.
;
;  VOLUME ENVELOPES (EnvTable)
;    frames, delta lo, delta hi   add the signed 16-bit delta to mVol:mVolFrac
;                                 every frame, for 'frames' frames (0 = 256)
;    $FE, lo, hi                  set mVol:mVolFrac = hi:lo
;    $FF                          end: volume 0, envelope off
;    The APU volume is the high nibble of mVol, minus CMD_VOLUME and
;    zMasterAtten. A rest turns the envelope off (volume 0).
;
;  DRUM MACROS (DrumTable, channel 3; one step per frame while the envelope
;    is on)
;    $00-$1F      noise period (value >> 1); ends this frame
;    $40-$4F lo   square 2 plays a tone instead: period ((n&15)<<8 | lo) >> 1,
;                 with the noise channel's volume and duty; ends this frame
;    $80-$BF      volume envelope n & $3F (keep reading)
;    $E0-$FE      duty n & 3 (keep reading; used by the square 2 tone)
;    $FF / other  stop (the macro stays on this byte)
;
;  Bytes nothing reads are kept so the file reassembles; they are marked
;  "never reached" or "not used".
;
;==============================================================================

; ---------------------------------------------------------------- RAM
zSoundReq            = $F0          ; sound request from the game; bit 7 = done
zChanActive          = $F1          ; bit n = channel n running
zChanNew             = $F2          ; channels started this frame (OR'ed in after the update)
zTemp                = $F3          ; scratch / jump vector
zTrkPtr              = $F5          ; pointer: track / envelope / drum / header data
zChan                = $F7          ; current channel
zFadeIn              = $F8          ; fade-in request flag
zFadeOut             = $F9          ; fade-out request flag
zMasterAtten         = $FB          ; subtracted from every channel's volume
zPaused              = $FC          ; nonzero = music channels paused
zTie                 = $FD          ; set by CMD_TIE for the next note (shared)
mStackPtr            = $0700        ; per channel: index into mStack
mStack               = $0706        ; loop/call stack, 16 bytes per channel
mTrkPtrLo            = $0766        ; track pointer, per channel (6 channels)
mTrkPtrHi            = $076C
mSpeed               = $0772        ; note length multiplier (CMD_SPEED)
mOctave              = $0778        ; octave * 12
mTranspose           = $077E        ; CMD_TRANSPOSE
mTransposeAdd        = $0784        ; CMD_TRANSPOSE_ADD
mNoteTimer           = $078A        ; frames left of the current note
mDuty                = $0790        ; duty in bits 6-7
mVolAtten            = $0796        ; CMD_VOLUME attenuation
mEnv                 = $079C        ; envelope number; bit 7 = off
mEnvTimer            = $07A2        ; frames left of the envelope segment
mEnvPos              = $07A8        ; offset into the envelope
mVolFrac             = $07AE        ; volume, fraction
mVol                 = $07B4        ; volume, high nibble = APU volume
mEnvDeltaLo          = $07BA        ; envelope delta per frame
mEnvDeltaHi          = $07C0
mPeriodLo            = $07C6        ; period x 2
mPeriodHi            = $07CC
mPeriodDirty         = $07D2        ; nonzero = write the period
mSweep               = $07D8        ; sweep register value
mSweepDirty          = $07DE        ; nonzero = write the sweep register
mDetune              = $07E4        ; signed period offset
mDrumPtrLo           = $07EA        ; drum macro pointer (channel 3)
mDrumPtrHi           = $07EB
mSq2DrumLo           = $07EC        ; square 2 drum tone period x 2
mSq2DrumHi           = $07ED
mSq2DrumOn           = $07EE        ; square 2 plays the drum tone this frame
mNoiseOn             = $07EF        ; noise registers written this frame
mDrumMap             = $07F0        ; note -> drum number (13 entries, CMD_DRUM_SWAP)

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
CMD_OCTAVE0          = $D0
CMD_OCTAVE1          = $D1
CMD_OCTAVE2          = $D2
CMD_OCTAVE3          = $D3
CMD_OCTAVE4          = $D4
CMD_OCTAVE5          = $D5
CMD_OCTAVE6          = $D6
CMD_OCTAVE_UP        = $D7
CMD_OCTAVE_DOWN      = $D8
CMD_TRANSPOSE        = $D9
CMD_TRANSPOSE_ADD    = $DA
CMD_DETUNE           = $DB
CMD_SPEED            = $E0
CMD_DUTY             = $E1
CMD_ENVELOPE         = $E2
CMD_NOP_E3           = $E3
CMD_NOP_E4           = $E4
CMD_NOP_E5           = $E5
CMD_TIE              = $E8
CMD_VOLUME           = $E9
CMD_VOLUME_ADD       = $EA
CMD_SWEEP            = $EB
CMD_SWEEP_OFF        = $EC
CMD_DRUM_SWAP        = $ED
CMD_LOOP             = $F0
CMD_LOOP_END         = $F1
CMD_CALL             = $F2
CMD_RETURN           = $F3
CMD_JUMP             = $F8
CMD_END              = $FF

.segment "SOUND"

;----------------------------------------------------------------------
; Duck Tales 2: two entry points, both called from the NMI handler.
; $8000 Sound_Update (requests, music tracks, register output),
; $8003 Sound_UpdateSfx (sound effect tracks only).
SoundJumpTable:
        jmp Sound_Update

;----------------------------------------------------------------------
; Run the two sound effect channels (4 = square 2, 5 = noise).
Sound_UpdateSfx:
        ldy #$02
        ldx #$04
        stx zChan
        jmp Sound_RunChannels

;----------------------------------------------------------------------
; Once per frame. Handle a new request in zSoundReq (bit 7 clear),
; run the tracks, write the APU, then enable the channels that
; Sound_Start set up this frame (zChanNew).
Sound_Update:
        lda zSoundReq
        bmi L8013
        jsr Sound_Request

L8013:
        ldy #$04
        ldx zPaused
        bne L801E
        stx zChan
        jsr Sound_RunChannels

L801E:
        jsr Sound_Output
        lda zChanActive
        ora zChanNew
        sta zChanActive
        lda #$00
        sta zChanNew
        rts

;----------------------------------------------------------------------
; Y = number of channels, zChan = first channel. For every active
; channel: read the track, run the drum macro (channel 3), then the
; volume envelope.
Sound_RunChannels:
        tya
        pha
        ldx zChan
        lda zChanActive
        and ChanBit,x
        beq L8040
        jsr Track_Update
        jsr Drum_Update
        jsr Env_Update

L8040:
        inc zChan
        pla
        tay
        dey
        bne Sound_RunChannels
        rts

;----------------------------------------------------------------------
; Volume envelope of channel X. mEnv bit 7 = off (volume forced to 0).
; Segments are 3 bytes: frames, delta low, delta high. The 16-bit delta is
; added to mVol:mVolFrac every frame; the volume is the high nibble of mVol.
; $FE lo hi = set mVolFrac/mVol, $FF = end (volume 0, envelope off).
Env_Update:
        ldy mEnv,x
        bmi L806B
        lda mEnvTimer,x
        bne Env_Step
        tya
        asl a
        tay
        lda EnvTable,y
        sta zTrkPtr
        lda EnvTable+1,y
        sta zTrkPtr+1
        ldy mEnvPos,x

L8062:
        lda (zTrkPtr),y
        iny
        cmp #$FE
        beq Env_SetValue
        bcc Env_NewSegment

L806B:
        lda #$00
        sta mVol,x
        lda mEnv,x
        ora #$80
        sta mEnv,x
        rts

;----------------------------------------------------------------------
; $FE lo hi: set the volume directly and keep reading.
Env_SetValue:
        lda (zTrkPtr),y
        sta mVolFrac,x
        iny
        lda (zTrkPtr),y
        sta mVol,x
        iny
        jmp L8062

;----------------------------------------------------------------------
; frames, delta low, delta high
Env_NewSegment:
        sta mEnvTimer,x
        lda (zTrkPtr),y
        sta mEnvDeltaLo,x
        iny
        lda (zTrkPtr),y
        sta mEnvDeltaHi,x
        iny
        tya
        sta mEnvPos,x

;----------------------------------------------------------------------
; Add the delta, count down the segment.
Env_Step:
        clc
        lda mVolFrac,x
        adc mEnvDeltaLo,x
        sta mVolFrac,x
        lda mVol,x
        adc mEnvDeltaHi,x
        sta mVol,x
        dec mEnvTimer,x
        rts

;----------------------------------------------------------------------
; Write the APU registers. Music channels 0-3 run only when not paused,
; and square 2 / noise are skipped while a sound effect uses them
; (OutputSkipMask). Then the active sound effect channels 4 and 5.
Sound_Output:
        lda zPaused
        bne L80C7
        ldx #$00

L80B8:
        lda zChanActive
        and OutputSkipMask,x
        bne L80C2
        jsr Output_Channel

L80C2:
        inx
        cpx #$04
        bcc L80B8

L80C7:
        ldx #$04

L80C9:
        lda zChanActive
        and ChanBit,x
        beq L80D3
        jsr Output_Channel

L80D3:
        inx
        cpx #$06
        bcc L80C9
        rts

OutputSkipMask:
        .byte $00,$10,$00,$20               ; music channel muted while these sfx bits are set

;----------------------------------------------------------------------
; Jump through OutputTable for channel X.
Output_Channel:
        txa
        asl a
        tay
        lda OutputTable,y
        sta zTemp
        lda OutputTable+1,y
        sta zTemp+1
        jmp (zTemp)

Output_Done:
        rts

;
; Register output routine per channel (X = 0-5)
OutputTable:
        .word Out_Sq1                       ; channel 0 (Sq1)
        .word Out_Sq2                       ; channel 1 (Sq2)
        .word Out_Tri                       ; channel 2 (Tri)
        .word Out_Noise                     ; channel 3 (Noise)
        .word Out_SfxSq2                    ; channel 4 (SfxSq2)
        .word Out_SfxNoise                  ; channel 5 (SfxNoise)

Out_Sq1:
        ldy #$00
        jsr WriteVolume
        jsr WritePeriod
        jmp Output_Done

Out_Sq2:
        lda mSq2DrumOn
        beq Out_SfxSq2
        jsr Out_Sq2Drum
        jmp Output_Done

Out_SfxSq2:
        ldy #$04
        jsr WriteVolume
        jsr WritePeriod
        jmp Output_Done

Out_Tri:
        ldy #$08
        jsr WriteVolume
        jsr WritePeriod
        jmp Output_Done

Out_Noise:
        lda mNoiseOn
        beq L8133

Out_SfxNoise:
        ldy #$0C
        jsr WriteVolume
        jsr WritePeriod

L8133:
        jmp Output_Done

;----------------------------------------------------------------------
; Y = APU register offset. Volume = (mVol >> 4) - mVolAtten - zMasterAtten,
; at least 0. Triangle: linear counter = volume * 4 with the control bit
; set (0 = silent). Others: volume | duty | $30 (constant volume, halt).
WriteVolume:
        lda mVol,x
        lsr a
        lsr a
        lsr a
        lsr a
        sec
        sbc mVolAtten,x
        bcc L8148
        sec
        sbc zMasterAtten
        bcs L814A

L8148:
        lda #$00

L814A:
        cpy #$08
        bne L8154
        asl a
        asl a
        ora #$80
        bne L8159

L8154:
        ora mDuty,x
        ora #$30

L8159:
        sta SQ1_VOL,y
        rts

;----------------------------------------------------------------------
; Sweep register when the period or sweep changed; period (stored x2)
; shifted right once, high bits OR $F8 (length counter load).
WritePeriod:
        lda mPeriodDirty,x
        ora mSweepDirty,x
        beq L8170
        lda mSweep,x
        sta SQ1_SWEEP,y
        lda #$00
        sta mSweepDirty,x

L8170:
        lda mPeriodDirty,x
        bne L8176
        rts

L8176:
        lda #$00
        sta mPeriodDirty,x
        tya
        pha
        lda mPeriodLo,x
        sta zTemp
        lda mPeriodHi,x
        sta zTemp+1
        pla
        tay
        lsr zTemp+1
        ror zTemp
        lda zTemp
        sta SQ1_LO,y
        lda zTemp+1
        and #$07
        ora #$F8
        sta SQ1_HI,y
        rts

;----------------------------------------------------------------------
; Square 2 played by the noise channel's drum macro (mSq2DrumOn): uses
; channel 3's volume, attenuation and duty. All three registers are
; written every frame.
Out_Sq2Drum:
        lda mVol+3
        lsr a
        lsr a
        lsr a
        lsr a
        sec
        sbc mVolAtten+3
        bcc L81AE
        sec
        sbc zMasterAtten
        bcs L81B0

L81AE:
        lda #$00

L81B0:
        ora mDuty+3
        ora #$10
        sta SQ2_VOL
        lda mSq2DrumHi
        lsr a
        tay
        lda mSq2DrumLo
        ror a
        sta SQ2_LO
        tya
        ora #$F8
        sta SQ2_HI
        rts

;----------------------------------------------------------------------
; A = zSoundReq. Mark it done (bit 7). $00 = Sound_Init, $01-$78 =
; Sound_Start, $79-$7F = RequestTable.
Sound_Request:
        ora #$80
        sta zSoundReq
        and #$7F
        beq Sound_Init
        cmp #$79
        bcs L81DA
        jmp Sound_Start

L81DA:
        sbc #$79
        asl a
        tay
        lda RequestTable,y
        sta zTemp
        lda RequestTable+1,y
        sta zTemp+1
        jmp (zTemp)

;
; Special requests $79-$7F (zSoundReq)
RequestTable:
        .word Req_Resume                    ; $79
        .word Req_Pause                     ; $7A
        .word Req_7B                        ; $7B
        .word Req_7C                        ; $7C
        .word Req_StopMusic                 ; $7D
        .word Req_StopSfx                   ; $7E
        .word Sound_Init                    ; $7F

;----------------------------------------------------------------------
; $79: resume the music channels.
Req_Resume:
        lda #$00
        sta zPaused
        rts

;----------------------------------------------------------------------
; $7A: pause the music channels (sound effects keep running) and
; silence them.
Req_Pause:
        lda #$01
        sta zPaused
        lda #$00
        sta SQ1_VOL
        sta SQ2_VOL
        sta TRI_LO
        sta TRI_HI
        sta NOISE_VOL
        rts

;----------------------------------------------------------------------
; $7C: does nothing in this version.
Req_7C:
        rts

;----------------------------------------------------------------------
; $7B: does nothing in this version.
Req_7B:
        rts

;----------------------------------------------------------------------
; $7D: stop the music (reset channels 0-3).
Req_StopMusic:
        lda #$00
        sta zFadeIn
        sta zFadeOut
        ldx #$00
        ldy #$04
        jmp ResetChannels

;----------------------------------------------------------------------
; $7E: stop the sound effects (reset channels 4-5).
Req_StopSfx:
        ldx #$04
        ldy #$02

;----------------------------------------------------------------------
; Reset Y channels starting at X.
ResetChannels:
        jsr Chan_Reset
        inx
        dey
        bne ResetChannels
        rts

;----------------------------------------------------------------------
; $00 / $7F: silence the APU, clear $0700-$07FC and reset the channels.
Sound_Init:
L822F:
        ldy #$13
        lda #$00

L8233:
        sta SQ1_VOL,y
        dey
        bpl L8233
        lda #$08
        sta SQ1_VOL
        sta SQ2_VOL
        lda #$40
        sta TRI_LINEAR
        lda #$10
        sta NOISE_VOL
        lda #$8F
        sta APU_STATUS
        lda #$C0
        sta APU_FRAME
        lda #$00
        sta zTrkPtr
        lda #$07
        sta zTrkPtr+1
        lda #$FD
        sta zTemp
        lda #$00
        sta zTemp+1
        ldy #$00

L8267:
        tya
        sta (zTrkPtr),y
        inc zTrkPtr
        bne L8270
        inc zTrkPtr+1

L8270:
        sec
        lda zTemp
        sbc #$01
        sta zTemp
        lda zTemp+1
        sbc #$00
        sta zTemp+1
        ora zTemp
        bne L8267
        lda #<Drum_Silent
        sta mDrumPtrLo
        lda #>Drum_Silent
        sta mDrumPtrHi
        ldx #$00

L828D:
        jsr Chan_Reset
        inx
        cpx #$06
        bne L828D
        rts

;----------------------------------------------------------------------
; Reset channel X: empty stack, track = SilentTrack, envelope off.
Chan_Reset:
        lda StackBase,x
        sta mStackPtr,x
        lda #<SilentTrack
        sta mTrkPtrLo,x
        lda #>SilentTrack
        sta mTrkPtrHi,x
        lda #$00
        sta mVolAtten,x
        sta mDetune,x
        sta mTranspose,x
        sta mTransposeAdd,x
        sta mNoteTimer,x
        sta zTie
        sta mPeriodLo,x
        sta mPeriodHi,x
        sta mVol,x
        sta mEnvTimer,x
        sta mEnvPos,x
        sta mSweepDirty,x
        lda #$08
        sta mSweep,x
        lda #$80
        sta mEnv,x
        lda #$00
        sta mPeriodDirty,x
        rts

StackBase:
        .byte $00,$10,$20,$30,$40,$50       ; start of each channel's 16-byte area in mStack

;----------------------------------------------------------------------
; Start sound A ($01-$78). Header byte: bits 0-3 = music channels 0-3,
; bits 4-5 = sound effect channels 4-5, followed by one track pointer
; per set bit. Music also clears pause/fade, the drum flags and resets
; mDrumMap. The header byte is OR'ed into zChanActive at the end of
; Sound_Update.
Sound_Start:
        asl a
        tax
        lda SoundTable,x
        sta zTrkPtr
        lda SoundTable+1,x
        sta zTrkPtr+1
        ldy #$00
        lda (zTrkPtr),y
        sta zTemp
        sta zChanNew
        and #$30
        bne L831F
        lda #$00
        sta zPaused
        sta zFadeIn
        sta zFadeOut
        sta zMasterAtten
        sta mSq2DrumOn
        sta mNoiseOn
        ldx #$0C

L830B:
        txa
        sta mDrumMap,x
        dex
        bpl L830B
        ldx #$00
        ldy #$04
        lda zChanActive
        and #$30
        sta zChanActive
        jmp L832F

L831F:
        lsr a
        lsr a
        lsr a
        lsr a
        sta zTemp
        lda zChanActive
        and #$0F
        sta zChanActive
        ldx #$04
        ldy #$02

L832F:
        sty zTemp+1
        ldy #$01

L8333:
        jsr Chan_Reset
        lsr zTemp
        bcc L8346
        lda (zTrkPtr),y
        sta mTrkPtrLo,x
        iny
        lda (zTrkPtr),y
        sta mTrkPtrHi,x
        iny

L8346:
        inx
        dec zTemp+1
        bne L8333
        lda #$F0
        sta NOISE_VOL
        rts

;----------------------------------------------------------------------
; Count down the note; read the track when it reaches 0.
Track_Update:
        lda mNoteTimer,x
        beq Track_Read
        dec mNoteTimer,x
        beq Track_Read
        rts

;----------------------------------------------------------------------
; Commands ($D0-$FF) run through CmdTable with TrackLoopRet pushed, so
; reading continues until a note or rest.
Track_Read:
        lda mTrkPtrLo,x
        sta zTrkPtr
        lda mTrkPtrHi,x
        sta zTrkPtr+1

Track_NextByte:
        jsr Track_ReadByte
        cmp #$D0
        bcc Track_Note
        sec
        sbc #$D0
        asl a
        tay
        lda CmdTable,y
        sta zTemp
        lda CmdTable+1,y
        sta zTemp+1
        lda TrackLoopRet+1
        pha
        lda TrackLoopRet
        pha
        jmp (zTemp)

; return address (minus 1) pushed before a command handler runs,
; so that its RTS reads the next track byte
TrackLoopRet:
        .byte <(Track_NextByte-1), >(Track_NextByte-1)

;----------------------------------------------------------------------
; Note/rest byte: high nibble = note (0-11) or $C = rest, low nibble =
; length - 1. Length = (n + 1) * mSpeed (mSpeed 0 = x1).
Track_Note:
        pha
        clc
        and #$0F
        adc #$01
        sta mNoteTimer,x
        ldy mSpeed,x
        beq L83A3
        lda #$00

L8399:
        clc
        adc mNoteTimer,x
        dey
        bne L8399
        sta mNoteTimer,x

L83A3:
        pla
        and #$F0
        cmp #$C0
        bne Track_NoteOn
        lda mEnv,x
        ora #$80
        sta mEnv,x
        lda #$00
        sta mPeriodLo,x
        sta mPeriodHi,x
        sta mEnvPos,x
        sta mEnvTimer,x
        sta mVol,x
        inc mPeriodDirty,x
        jmp Track_SavePtr

;----------------------------------------------------------------------
; Note: unless tied, restart the envelope. Channel 3: start drum
; macro mDrumMap[note]. Channel 5: noise period = (note - transposes) & 15.
; Others: PeriodTable[octave + note + transposes] + mDetune.
Track_NoteOn:
        ldy zTie
        beq L83D0
        jmp Track_SavePtr

L83D0:
        pha
        lda #$00
        sta mEnvPos,x
        sta mEnvTimer,x
        sta mVolFrac,x
        sta mVol,x
        lda mEnv,x
        and #$7F
        sta mEnv,x
        pla
        lsr a
        lsr a
        lsr a
        lsr a
        cpx #$03
        bne L83F6
        jsr Drum_Start
        jmp Track_SavePtr

L83F6:
        cpx #$05
        bne L8413
        sec
        sbc mTranspose,x
        sec
        sbc mTransposeAdd,x
        asl a
        and #$1E
        sta mPeriodLo,x
        lda #$00
        sta mPeriodHi,x
        inc mPeriodDirty,x
        jmp Track_SavePtr

L8413:
        clc
        adc mOctave,x
        clc
        adc mTranspose,x
        clc
        adc mTransposeAdd,x
        asl a
        tay
        lda PeriodTable,y
        sta mPeriodLo,x
        lda PeriodTable+1,y
        sta mPeriodHi,x
        ldy #$00
        lda mDetune,x
        bpl L8435
        dey

L8435:
        clc
        adc mPeriodLo,x
        sta mPeriodLo,x
        tya
        adc mPeriodHi,x
        sta mPeriodHi,x
        inc mPeriodDirty,x

;----------------------------------------------------------------------
; Clear the tie flag and store the track pointer.
Track_SavePtr:
        lda #$00
        sta zTie
        lda zTrkPtr
        sta mTrkPtrLo,x
        lda zTrkPtr+1
        sta mTrkPtrHi,x
        rts

;
; Track command handlers, commands $D0-$FF ($0000 = not used)
CmdTable:
        .word Cmd_Octave0                   ; $D0 CMD_OCTAVE0
        .word Cmd_Octave1                   ; $D1 CMD_OCTAVE1
        .word Cmd_Octave2                   ; $D2 CMD_OCTAVE2
        .word Cmd_Octave3                   ; $D3 CMD_OCTAVE3
        .word Cmd_Octave4                   ; $D4 CMD_OCTAVE4
        .word Cmd_Octave5                   ; $D5 CMD_OCTAVE5
        .word Cmd_Octave6                   ; $D6 CMD_OCTAVE6
        .word Cmd_OctaveUp                  ; $D7 CMD_OCTAVE_UP
        .word Cmd_OctaveDown                ; $D8 CMD_OCTAVE_DOWN
        .word Cmd_Transpose                 ; $D9 CMD_TRANSPOSE
        .word Cmd_TransposeAdd              ; $DA CMD_TRANSPOSE_ADD
        .word Cmd_Detune                    ; $DB CMD_DETUNE
        .word $0000                         ; $DC (unused)
        .word $0000                         ; $DD (unused)
        .word $0000                         ; $DE (unused)
        .word $0000                         ; $DF (unused)
        .word Cmd_Speed                     ; $E0 CMD_SPEED
        .word Cmd_Duty                      ; $E1 CMD_DUTY
        .word Cmd_Envelope                  ; $E2 CMD_ENVELOPE
        .word Cmd_NopE3                     ; $E3 CMD_NOP_E3
        .word Cmd_NopE4                     ; $E4 CMD_NOP_E4
        .word Cmd_NopE5                     ; $E5 CMD_NOP_E5
        .word $0000                         ; $E6 (unused)
        .word $0000                         ; $E7 (unused)
        .word Cmd_Tie                       ; $E8 CMD_TIE
        .word Cmd_Volume                    ; $E9 CMD_VOLUME
        .word Cmd_VolumeAdd                 ; $EA CMD_VOLUME_ADD
        .word Cmd_Sweep                     ; $EB CMD_SWEEP
        .word Cmd_SweepOff                  ; $EC CMD_SWEEP_OFF
        .word Cmd_DrumSwap                  ; $ED CMD_DRUM_SWAP
        .word $0000                         ; $EE (unused)
        .word $0000                         ; $EF (unused)
        .word Cmd_Loop                      ; $F0 CMD_LOOP
        .word Cmd_LoopEnd                   ; $F1 CMD_LOOP_END
        .word Cmd_Call                      ; $F2 CMD_CALL
        .word Cmd_Return                    ; $F3 CMD_RETURN
        .word $0000                         ; $F4 (unused)
        .word $0000                         ; $F5 (unused)
        .word $0000                         ; $F6 (unused)
        .word $0000                         ; $F7 (unused)
        .word Cmd_Jump                      ; $F8 CMD_JUMP
        .word $0000                         ; $F9 (unused)
        .word $0000                         ; $FA (unused)
        .word $0000                         ; $FB (unused)
        .word $0000                         ; $FC (unused)
        .word $0000                         ; $FD (unused)
        .word $0000                         ; $FE (unused)
        .word Cmd_End                       ; $FF CMD_END

;----------------------------------------------------------------------
; $D0-$D6: octave 0-6.
Cmd_Octave0:
        lda #$00
        beq L84CF

Cmd_Octave1:
        lda #$0C
        bne L84CF

Cmd_Octave2:
        lda #$18
        bne L84CF

Cmd_Octave3:
        lda #$24
        bne L84CF

Cmd_Octave4:
        lda #$30
        bne L84CF

Cmd_Octave5:
        lda #$3C
        bne L84CF

Cmd_Octave6:
        lda #$48

L84CF:
        sta mOctave,x
        rts

;----------------------------------------------------------------------
; $D7: octave + 1.
Cmd_OctaveUp:
        clc
        lda mOctave,x
        adc #$0C
        sta mOctave,x
        rts

;----------------------------------------------------------------------
; $D8: octave - 1.
Cmd_OctaveDown:
        sec
        lda mOctave,x
        sbc #$0C
        sta mOctave,x
        rts

;----------------------------------------------------------------------
; $D9 n: transpose = n.
Cmd_Transpose:
        jsr Track_ReadByte
        sta mTranspose,x
        rts

;----------------------------------------------------------------------
; $DA n: second transpose += n.
Cmd_TransposeAdd:
        jsr Track_ReadByte
        clc
        adc mTransposeAdd,x
        sta mTransposeAdd,x
        rts

;----------------------------------------------------------------------
; $DB n: signed value added to the period.
Cmd_Detune:
        jsr Track_ReadByte
        sta mDetune,x
        rts

;----------------------------------------------------------------------
; $E0 n: note length multiplier.
Cmd_Speed:
        jsr Track_ReadByte
        sta mSpeed,x
        rts

;----------------------------------------------------------------------
; $E1 n: duty = n & 3.
Cmd_Duty:
        jsr Track_ReadByte
        ror a
        ror a
        ror a
        and #$C0
        sta mDuty,x
        rts

;----------------------------------------------------------------------
; $E2 n: volume envelope n; it starts with the next note.
Cmd_Envelope:
        jsr Track_ReadByte
        ora #$80
        sta mEnv,x
        lda #$00
        sta mEnvPos,x
        sta mEnvTimer,x
        rts

;----------------------------------------------------------------------
; $E3 n: argument read and ignored.
Cmd_NopE3:
        jsr Track_ReadByte
        rts

;----------------------------------------------------------------------
; $E4 n: argument read and ignored.
Cmd_NopE4:
        jsr Track_ReadByte
        rts

;----------------------------------------------------------------------
; $E5 n: argument read and ignored.
Cmd_NopE5:
        jsr Track_ReadByte
        rts

;----------------------------------------------------------------------
; $E8: the next note does not restart the envelope or the period.
; (zTie is shared by all channels.)
Cmd_Tie:
        lda #$01
        sta zTie
        rts

;----------------------------------------------------------------------
; $E9 n: volume attenuation = n.
Cmd_Volume:
        jsr Track_ReadByte
        sta mVolAtten,x
        rts

;----------------------------------------------------------------------
; $EA n: volume attenuation += n.
Cmd_VolumeAdd:
        jsr Track_ReadByte
        clc
        adc mVolAtten,x
        sta mVolAtten,x
        rts

;----------------------------------------------------------------------
; $EB n: sweep register = n.
Cmd_Sweep:
        jsr Track_ReadByte
        sta mSweep,x
        inc mSweepDirty,x
        rts

;----------------------------------------------------------------------
; $EC: sweep register = $08 (off).
Cmd_SweepOff:
        lda #$08
        sta mSweep,x
        inc mSweepDirty,x
        rts

;----------------------------------------------------------------------
; $F0 n: push the loop start and the count n.
Cmd_Loop:
        jsr Track_ReadByte
        pha
        jsr Stack_PushPtr
        pla
        jmp Stack_Push

;----------------------------------------------------------------------
; $F1: count - 1; jump back while not 0, else drop the loop.
Cmd_LoopEnd:
        jsr Stack_Pop
        sec
        sbc #$01
        beq L8578
        pha
        jsr Stack_PopPtr
        jsr Stack_PushPtr
        pla
        jmp Stack_Push

L8578:
        jsr Stack_Pop
        jmp Stack_Pop

;----------------------------------------------------------------------
; $F2 .word sub: push the return address, go to sub.
Cmd_Call:
        jsr Track_ReadByte
        pha
        jsr Track_ReadByte
        pha
        jsr Stack_PushPtr
        pla
        sta zTrkPtr+1
        pla
        sta zTrkPtr
        rts

;----------------------------------------------------------------------
; $F3: pop the return address.
Cmd_Return:
        jmp Stack_PopPtr

;----------------------------------------------------------------------
; $F8 .word addr
Cmd_Jump:
        jsr Track_ReadByte
        pha
        jsr Track_ReadByte
        sta zTrkPtr+1
        pla
        sta zTrkPtr
        rts

;----------------------------------------------------------------------
; $ED xy: swap mDrumMap[x] and mDrumMap[y].
Cmd_DrumSwap:
        txa
        pha
        jsr Track_ReadByte
        pha
        ror a
        ror a
        ror a
        ror a
        and #$0F
        tax
        pla
        and #$0F
        tay
        lda mDrumMap,x
        pha
        lda mDrumMap,y
        sta mDrumMap,x
        pla
        sta mDrumMap,y
        pla
        tax
        rts

;----------------------------------------------------------------------
; $FF: stop the channel. Drops TrackLoopRet so it returns straight to
; Sound_RunChannels.
Cmd_End:
        lda zChanActive
        and ChanClearMask,x
        sta zChanActive
        jsr Chan_Reset
        pla
        pla
        rts

ChanBit:
        .byte $01,$02,$04,$08,$10,$20,$40,$80

ChanClearMask:
        .byte $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

;----------------------------------------------------------------------
; A = next track byte.
Track_ReadByte:
        ldy #$00
        lda (zTrkPtr),y
        inc zTrkPtr
        bne L85E9
        inc zTrkPtr+1

L85E9:
        rts

;----------------------------------------------------------------------
; Per-channel stack (16 bytes each in mStack): push the track pointer.
Stack_PushPtr:
        lda zTrkPtr+1
        jsr Stack_Push
        lda zTrkPtr

;----------------------------------------------------------------------
; Push A.
Stack_Push:
        ldy mStackPtr,x
        sta mStack,y
        inc mStackPtr,x
        rts

;----------------------------------------------------------------------
; Pop the track pointer.
Stack_PopPtr:
        jsr Stack_Pop
        sta zTrkPtr
        jsr Stack_Pop
        sta zTrkPtr+1
        rts

;----------------------------------------------------------------------
; Pop A.
Stack_Pop:
        dec mStackPtr,x
        ldy mStackPtr,x
        lda mStack,y
        rts

;----------------------------------------------------------------------
; Channel 3 note: drum macro pointer = DrumTable[mDrumMap[note]].
Drum_Start:
        tay
        lda mDrumMap,y
        asl a
        tay
        lda DrumTable,y
        sta mDrumPtrLo
        lda DrumTable+1,y
        sta mDrumPtrHi
        rts

;----------------------------------------------------------------------
; Channel 3, every frame while its envelope is on: run the drum macro
; until a step that ends the frame.
Drum_Update:
        ldx zChan
        cpx #$03
        beq L862A

L8629:
        rts

L862A:
        lda mEnv,x
        bmi L8629
        lda #$00
        sta mSq2DrumOn
        sta mNoiseOn
        lda mDrumPtrLo
        sta zTrkPtr
        lda mDrumPtrHi
        sta zTrkPtr+1

;----------------------------------------------------------------------
; $00-$1F noise period (value >> 1), ends the frame
; $40-$4F lo square 2 tone (period = ((n & 15) << 8 | lo) >> 1), ends the frame
; $80-$BF envelope n & $3F,  $E0-$FE duty n & 3,  others / $FF stop.
Drum_Step:
        jsr Track_ReadByte
        tay
        cmp #$FF
        beq Drum_Stop
        and #$E0
        beq L867D
        cmp #$E0
        beq L8671
        cmp #$40
        beq L8691
        cmp #$80
        beq L8660
        cmp #$A0
        beq L8660
        jmp Drum_Stop

L8660:
        tya
        and #$3F
        sta mEnv,x
        lda #$00
        sta mEnvPos,x
        sta mEnvTimer,x
        jmp Drum_Step

L8671:
        tya
        ror a
        ror a
        ror a
        and #$C0
        sta mDuty,x
        jmp Drum_Step

L867D:
        inc mNoiseOn
        tya
        and #$1F
        sta mPeriodLo,x
        lda #$00
        sta mPeriodHi,x
        inc mPeriodDirty,x
        jmp L86A3

L8691:
        inc mSq2DrumOn
        tya
        and #$0F
        sta mSq2DrumHi
        jsr Track_ReadByte
        sta mSq2DrumLo
        inc mPeriodDirty+1

L86A3:
        lda zTrkPtr
        sta mDrumPtrLo
        lda zTrkPtr+1
        sta mDrumPtrHi
        rts

;----------------------------------------------------------------------
; End: noise period 0, keep writing the noise volume; the pointer is
; not saved, so the macro stays on this byte.
Drum_Stop:
        lda #$00
        sta mSq2DrumOn
        sta mNoiseOn
        sta mPeriodHi,x
        sta mPeriodLo,x
        inc mNoiseOn
        rts

;
; Note periods x 2 (the output routine shifts right once), 12 per octave.
; Index 0 = C0; the entries below A0 are 0. Square: 1789773 / (16 * (value/2 + 1)) Hz;
; the triangle sounds an octave lower.
PeriodTable:
        .word $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0FE2,$0EFE,$0E26 ; octave 0
        .word $0D5C,$0C9A,$0BE6,$0B3A,$0A9A,$0A00,$0972,$08EA,$086A,$07F0,$077E,$0712 ; octave 1
        .word $06AC,$064C,$05F2,$059C,$054C,$0500,$04B8,$0474,$0434,$03F8,$03BE,$0388 ; octave 2
        .word $0356,$0326,$02F8,$02CE,$02A4,$027E,$025A,$0238,$0218,$01FA,$01DE,$01C4 ; octave 3
        .word $01AA,$0192,$017A,$0166,$0152,$013E,$012C,$011C,$010C,$00FC,$00EE,$00E0 ; octave 4
        .word $00D4,$00C8,$00BC,$00B2,$00A8,$009E,$0096,$008C,$0084,$007E,$0076,$0070 ; octave 5
        .word $0068,$0062,$005E,$0058,$0052,$004E,$004A,$0046,$0042,$003E,$003A,$0036 ; octave 6

;
; Sound table, indexed by the request number (zSoundReq $01-$5D; $00 = reset). Requests $5E-$78 would read past the end.
SoundTable:
        .word Sound_00                      ; $00 empty: stops the music
        .word Sound_01                      ; $01 music
        .word Sound_02                      ; $02 music
        .word Sound_03                      ; $03 music
        .word Sound_04                      ; $04 music
        .word Sound_05                      ; $05 music
        .word Sound_06                      ; $06 music
        .word Sound_07                      ; $07 music
        .word Sound_08                      ; $08 music
        .word Sound_09                      ; $09 music
        .word Sound_0A                      ; $0A music
        .word Sound_0B                      ; $0B music
        .word Sound_0C                      ; $0C music
        .word Sound_0D                      ; $0D music
        .word Sound_0E                      ; $0E music
        .word Sound_0F                      ; $0F music
        .word Sound_00                      ; $10 empty: stops the music
        .word Sound_11                      ; $11 music
        .word Sound_12                      ; $12 music
        .word Sound_13                      ; $13 music
        .word Sound_14                      ; $14 music
        .word Sound_00                      ; $15 empty: stops the music
        .word Sound_00                      ; $16 empty: stops the music
        .word Sound_00                      ; $17 empty: stops the music
        .word Sound_00                      ; $18 empty: stops the music
        .word Sound_00                      ; $19 empty: stops the music
        .word Sound_00                      ; $1A empty: stops the music
        .word Sound_00                      ; $1B empty: stops the music
        .word Sound_00                      ; $1C empty: stops the music
        .word Sound_00                      ; $1D empty: stops the music
        .word Sound_00                      ; $1E empty: stops the music
        .word Sound_00                      ; $1F empty: stops the music
        .word Sound_20                      ; $20 sound effect
        .word Sound_21                      ; $21 sound effect
        .word Sound_22                      ; $22 sound effect
        .word Sound_23                      ; $23 sound effect
        .word Sound_24                      ; $24 sound effect
        .word Sound_25                      ; $25 sound effect
        .word Sound_26                      ; $26 sound effect
        .word Sound_27                      ; $27 sound effect
        .word Sound_28                      ; $28 sound effect
        .word Sound_29                      ; $29 sound effect
        .word Sound_2A                      ; $2A sound effect
        .word Sound_2B                      ; $2B sound effect
        .word Sound_2C                      ; $2C sound effect
        .word Sound_2D                      ; $2D sound effect
        .word Sound_2E                      ; $2E sound effect
        .word Sound_2F                      ; $2F sound effect
        .word Sound_30                      ; $30 sound effect
        .word Sound_30                      ; $31 sound effect
        .word Sound_30                      ; $32 sound effect
        .word Sound_33                      ; $33 sound effect
        .word Sound_34                      ; $34 sound effect
        .word Sound_35                      ; $35 sound effect
        .word Sound_36                      ; $36 sound effect
        .word Sound_37                      ; $37 sound effect
        .word Sound_38                      ; $38 sound effect
        .word Sound_39                      ; $39 sound effect
        .word Sound_3A                      ; $3A sound effect
        .word Sound_3B                      ; $3B sound effect
        .word Sound_3C                      ; $3C sound effect
        .word Sound_3D                      ; $3D sound effect
        .word Sound_3E                      ; $3E sound effect
        .word Sound_3F                      ; $3F sound effect
        .word Sound_3F                      ; $40 sound effect
        .word Sound_3F                      ; $41 sound effect
        .word Sound_42                      ; $42 sound effect
        .word Sound_42                      ; $43 sound effect
        .word Sound_44                      ; $44 sound effect
        .word Sound_45                      ; $45 sound effect
        .word Sound_46                      ; $46 sound effect
        .word Sound_47                      ; $47 sound effect
        .word Sound_48                      ; $48 sound effect
        .word Sound_49                      ; $49 sound effect
        .word Sound_4A                      ; $4A sound effect
        .word Sound_4B                      ; $4B sound effect
        .word Sound_4C                      ; $4C sound effect
        .word Sound_4C                      ; $4D sound effect
        .word Sound_4E                      ; $4E sound effect
        .word Sound_4E                      ; $4F sound effect
        .word Sound_50                      ; $50 sound effect
        .word Sound_51                      ; $51 sound effect
        .word Sound_52                      ; $52 sound effect
        .word Sound_53                      ; $53 sound effect
        .word Sound_54                      ; $54 sound effect
        .word Sound_55                      ; $55 sound effect
        .word Sound_56                      ; $56 sound effect
        .word Sound_57                      ; $57 sound effect
        .word Sound_58                      ; $58 sound effect
        .word Sound_59                      ; $59 sound effect
        .word Sound_5A                      ; $5A sound effect
        .word Sound_5B                      ; $5B sound effect
        .word Sound_5C                      ; $5C sound effect
        .word Sound_5D                      ; $5D sound effect

;======================================================================
; Sound $20 (sound effect)
;======================================================================
Sound_20:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd20_SfxSq2
        .word Snd20_SfxNoise

Snd20_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 2 fr
        .byte CMD_VOLUME,$07                ; volume -7
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte $60                           ; F#4      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd20_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $81                           ; noise 8  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $21 (sound effect)
;======================================================================
Sound_21:
        .byte $10                           ; channels: SfxSq2
        .word Snd21_SfxSq2

Snd21_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$FA            ; volume attenuation -6
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$05                  ; repeat 5x
        .byte $80                           ; G#4      len 1 = 2 fr
        .byte $90                           ; A-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$06            ; volume attenuation +6
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $22 (sound effect)
;======================================================================
Sound_22:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd22_SfxSq2
        .word Snd22_SfxNoise

Snd22_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_OCTAVE3
        .byte CMD_DUTY,$02                  ; duty 2
        .byte $71                           ; G-3      len 2 = 2 fr
        .byte CMD_DUTY,$00                  ; duty 0
        .byte $70                           ; G-3      len 1 = 1 fr
        .byte $C4                           ; rest     len 5 = 5 fr
        .byte CMD_OCTAVE6
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $70                           ; G-6      len 1 = 1 fr
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $80                           ; G#6      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte CMD_DETUNE,$02                ; period +2
        .byte CMD_DUTY,$03                  ; duty 3
        .byte $91                           ; A-6      len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd22_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $B2                           ; noise B  len 3 = 3 fr
        .byte $C4                           ; rest     len 5 = 5 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_CALL
        .word Sub_88AC
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_CALL
        .word Sub_88AC
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_CALL
        .word Sub_88AC
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_CALL
        .word Sub_88AC
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_88AC:
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $B3                           ; noise B  len 4 = 4 fr
        .byte CMD_TRANSPOSE,$FD             ; -3 semitones
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_RETURN

;======================================================================
; Sound $23 (sound effect)
;======================================================================
Sound_23:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd23_SfxSq2
        .word Snd23_SfxNoise

Snd23_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE4
        .byte CMD_CALL
        .word Sub_88CC
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_VOLUME_ADD,$F8            ; volume attenuation -8
        .byte CMD_CALL
        .word Sub_88CC
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_88CC:
        .byte CMD_VOLUME,$00                ; volume -0
        .byte $91                           ; A-4      len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $91                           ; A-4      len 2 = 2 fr
        .byte CMD_RETURN

Snd23_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$F9            ; volume attenuation -7
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $24 (sound effect)
;======================================================================
Sound_24:
        .byte $10                           ; channels: SfxSq2
        .word Snd24_SfxSq2

Snd24_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_TRANSPOSE,$FF             ; -1 semitones
        .byte CMD_OCTAVE4
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte CMD_CALL
        .word Sub_890A
        .byte CMD_DETUNE,$F1                ; period -15
        .byte CMD_TRANSPOSE_ADD,$01         ; transpose +1 more
        .byte CMD_CALL
        .word Sub_890A
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte CMD_CALL
        .word Sub_890A
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Sub_890A:
        .byte $40                           ; E-4      len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte $50                           ; F-4      len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_RETURN

;======================================================================
; Sound $25 (sound effect)
;======================================================================
Sound_25:
        .byte $20                           ; channels: SfxNoise
        .word Snd25_SfxNoise

Snd25_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$03                 ; note length x3
        .byte CMD_TRANSPOSE,$FD             ; -3 semitones
        .byte $B0                           ; noise B  len 1 = 3 fr
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte $A0                           ; noise A  len 1 = 3 fr
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte $A0                           ; noise A  len 1 = 3 fr
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $A0                           ; noise A  len 1 = 3 fr
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte CMD_END

;======================================================================
; Sound $26 (sound effect)
;======================================================================
Sound_26:
        .byte $10                           ; channels: SfxSq2
        .word Snd26_SfxSq2

Snd26_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE5
        .byte $20                           ; D-5      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$0B            ; volume attenuation +11
        .byte $21                           ; D-5      len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$F5            ; volume attenuation -11
        .byte $52                           ; F-5      len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$0B            ; volume attenuation +11
        .byte $51                           ; F-5      len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte $51                           ; F-5      len 2 = 2 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$07            ; volume attenuation +7
        .byte $51                           ; F-5      len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $27 (sound effect)
;======================================================================
Sound_27:
        .byte $10                           ; channels: SfxSq2
        .word Snd27_SfxSq2

Snd27_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_OCTAVE5
        .byte $30                           ; D#5      len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte $20                           ; D-5      len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $28 (sound effect)
;======================================================================
Sound_28:
        .byte $20                           ; channels: SfxNoise
        .word Snd28_SfxNoise

Snd28_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $B2                           ; noise B  len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $91                           ; noise 9  len 2 = 2 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte $91                           ; noise 9  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $29 (sound effect)
;======================================================================
Sound_29:
        .byte $10                           ; channels: SfxSq2
        .word Snd29_SfxSq2

Snd29_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$03                 ; note length x3
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $80                           ; G#4      len 1 = 3 fr
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte CMD_LOOP_END
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_SWEEP_OFF
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$0A                  ; repeat 10x
        .byte $60                           ; F#4      len 1 = 2 fr
        .byte CMD_TRANSPOSE_ADD,$FF         ; transpose -1 more
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$0A                  ; repeat 10x
        .byte $60                           ; F#4      len 1 = 2 fr
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $2A (sound effect)
;======================================================================
Sound_2A:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd2A_SfxSq2
        .word Snd2A_SfxNoise

Snd2A_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 1 fr
        .byte $90                           ; A-4      len 1 = 1 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_OCTAVE_UP
        .byte $91                           ; A-5      len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd2A_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $A1                           ; noise A  len 2 = 2 fr
        .byte $80                           ; noise 8  len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $11                           ; noise 1  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $2B (sound effect)
;======================================================================
Sound_2B:
        .byte $20                           ; channels: SfxNoise
        .word Snd2B_SfxNoise

Snd2B_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_TRANSPOSE,$FC             ; -4 semitones
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$08                ; volume -8
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $2C (sound effect)
;======================================================================
Sound_2C:
        .byte $10                           ; channels: SfxSq2
        .word Snd2C_SfxSq2

Snd2C_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE5
        .byte $52                           ; F-5      len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$0B            ; volume attenuation +11
        .byte $51                           ; F-5      len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$F5            ; volume attenuation -11
        .byte $20                           ; D-5      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$0B            ; volume attenuation +11
        .byte $22                           ; D-5      len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $2D (sound effect)
;======================================================================
Sound_2D:
        .byte $10                           ; channels: SfxSq2
        .word Snd2D_SfxSq2

Snd2D_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $20                           ; D-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$F8            ; volume attenuation -8
        .byte $70                           ; G-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $70                           ; G-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$F8            ; volume attenuation -8
        .byte CMD_OCTAVE_UP
        .byte $00                           ; C-5      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $00                           ; C-5      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $2E (sound effect)
;======================================================================
Sound_2E:
        .byte $10                           ; channels: SfxSq2
        .word Snd2E_SfxSq2

Snd2E_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte CMD_OCTAVE5
        .byte $20                           ; D-5      len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $2F (sound effect)
;======================================================================
Sound_2F:
        .byte $10                           ; channels: SfxSq2
        .word Snd2F_SfxSq2

Snd2F_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $00                           ; C-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $00                           ; C-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$F8            ; volume attenuation -8
        .byte $50                           ; F-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $50                           ; F-4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$F8            ; volume attenuation -8
        .byte $A0                           ; A#4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $A0                           ; A#4      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $30, Sound $31, Sound $32 (sound effect)
;======================================================================
Sound_30:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd30_SfxSq2
        .word Snd30_SfxNoise

Snd30_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_OCTAVE1
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $02                           ; C-1      len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd30_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$04                 ; note length x4
        .byte $B0                           ; noise B  len 1 = 4 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte $50                           ; noise 5  len 1 = 4 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $33 (sound effect)
;======================================================================
Sound_33:
        .byte $10                           ; channels: SfxSq2
        .word Snd33_SfxSq2

Snd33_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $40                           ; E-3      len 1 = 1 fr
        .byte $50                           ; F-3      len 1 = 1 fr
        .byte $40                           ; E-3      len 1 = 1 fr
        .byte $50                           ; F-3      len 1 = 1 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $00                           ; C-3      len 1 = 1 fr
        .byte $10                           ; C#3      len 1 = 1 fr
        .byte $00                           ; C-3      len 1 = 1 fr
        .byte $10                           ; C#3      len 1 = 1 fr
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_SWEEP,$95                 ; sweep register $95
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_OCTAVE_UP
        .byte $47                           ; E-4      len 8 = 32 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $34 (sound effect)
;======================================================================
Sound_34:
        .byte $10                           ; channels: SfxSq2
        .word Snd34_SfxSq2

Snd34_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte CMD_OCTAVE2
        .byte $92                           ; A-2      len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte $91                           ; A-2      len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $35 (sound effect)
;======================================================================
Sound_35:
        .byte $20                           ; channels: SfxNoise
        .word Snd35_SfxNoise

Snd35_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $60                           ; noise 6  len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $80                           ; noise 8  len 1 = 1 fr
        .byte $40                           ; noise 4  len 1 = 1 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $40                           ; noise 4  len 1 = 1 fr
        .byte $60                           ; noise 6  len 1 = 1 fr
        .byte $20                           ; noise 2  len 1 = 1 fr
        .byte $00                           ; noise 0  len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$04            ; volume attenuation +4
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $36 (sound effect)
;======================================================================
Sound_36:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd36_SfxSq2
        .word Snd36_SfxNoise

Snd36_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_OCTAVE2
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $90                           ; A-2      len 1 = 2 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $00                           ; C-2      len 1 = 2 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $91                           ; A-3      len 2 = 4 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $01                           ; C-3      len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd36_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte $A0                           ; noise A  len 1 = 1 fr
        .byte $80                           ; noise 8  len 1 = 1 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_8AE2
        .byte CMD_VOLUME,$08                ; volume -8
        .byte CMD_CALL
        .word Sub_8AE2
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_8AE2:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $70                           ; noise 7  len 1 = 1 fr
        .byte $A0                           ; noise A  len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $50                           ; noise 5  len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$04            ; volume attenuation +4
        .byte CMD_LOOP_END
        .byte CMD_RETURN

;======================================================================
; Sound $37 (sound effect)
;======================================================================
Sound_37:
        .byte $10                           ; channels: SfxSq2
        .word Snd37_SfxSq2

Snd37_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$03                 ; note length x3
        .byte CMD_SWEEP,$8B                 ; sweep register $8B
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 3 fr
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte CMD_END

;======================================================================
; Sound $38 (sound effect)
;======================================================================
Sound_38:
        .byte $20                           ; channels: SfxNoise
        .word Snd38_SfxNoise

Snd38_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $31                           ; noise 3  len 2 = 2 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $39 (sound effect)
;======================================================================
Sound_39:
        .byte $20                           ; channels: SfxNoise
        .word Snd39_SfxNoise

Snd39_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $3A (sound effect)
;======================================================================
Sound_3A:
        .byte $10                           ; channels: SfxSq2
        .word Snd3A_SfxSq2

Snd3A_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_DETUNE,$00                ; period +0
        .byte CMD_CALL
        .word Sub_8B3E
        .byte CMD_DETUNE,$3C                ; period +60
        .byte CMD_CALL
        .word Sub_8B3E
        .byte CMD_DETUNE,$EC                ; period -20
        .byte CMD_CALL
        .word Sub_8B3E
        .byte CMD_DETUNE,$BA                ; period -70
        .byte CMD_CALL
        .word Sub_8B3E
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Sub_8B3E:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE2
        .byte $90                           ; A-2      len 1 = 2 fr
        .byte $A0                           ; A#2      len 1 = 2 fr
        .byte CMD_OCTAVE_UP
        .byte $00                           ; C-3      len 1 = 2 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

;======================================================================
; Sound $3B (sound effect)
;======================================================================
Sound_3B:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd3B_SfxSq2
        .word Snd3B_SfxNoise

Snd3B_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte CMD_TRANSPOSE,$F8             ; -8 semitones
        .byte CMD_OCTAVE2
        .byte $92                           ; A-2      len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $91                           ; A-2      len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd3B_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_TRANSPOSE,$FD             ; -3 semitones
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte $B1                           ; noise B  len 2 = 4 fr
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte $B2                           ; noise B  len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $3C (sound effect)
;======================================================================
Sound_3C:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd3C_SfxSq2
        .word Snd3C_SfxNoise

Snd3C_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE1
        .byte $50                           ; F-1      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd3C_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$FF             ; -1 semitones
        .byte $B2                           ; noise B  len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $93                           ; noise 9  len 4 = 4 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$03            ; volume attenuation +3
        .byte $93                           ; noise 9  len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $3D (sound effect)
;======================================================================
Sound_3D:
        .byte $20                           ; channels: SfxNoise
        .word Snd3D_SfxNoise

Snd3D_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$08                ; volume -8
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte $51                           ; noise 5  len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $51                           ; noise 5  len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$FF            ; volume attenuation -1
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$0F                ; volume -15
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $3E (sound effect)
;======================================================================
Sound_3E:
        .byte $20                           ; channels: SfxNoise
        .word Snd3E_SfxNoise

Snd3E_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $70                           ; noise 7  len 1 = 1 fr
        .byte $A0                           ; noise A  len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $50                           ; noise 5  len 1 = 1 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $60                           ; noise 6  len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $40                           ; noise 4  len 1 = 1 fr
        .byte $00                           ; noise 0  len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_VOLUME_ADD,$06            ; volume attenuation +6
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $3F, Sound $40, Sound $41 (sound effect)
;======================================================================
Sound_3F:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd3F_SfxSq2
        .word Snd3F_SfxNoise

Snd3F_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_LOOP,$07                  ; repeat 7x
        .byte CMD_OCTAVE0
        .byte $90                           ; A-0      len 1 = 2 fr
        .byte $A0                           ; A#0      len 1 = 2 fr
        .byte CMD_OCTAVE_UP
        .byte $00                           ; C-1      len 1 = 2 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd3F_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_TRANSPOSE,$FD             ; -3 semitones
        .byte $B7                           ; noise B  len 8 = 32 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $42, Sound $43 (sound effect)
;======================================================================
Sound_42:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd42_SfxSq2
        .word Snd42_SfxNoise

Snd42_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte CMD_TRANSPOSE,$F8             ; -8 semitones
        .byte CMD_OCTAVE2
        .byte $92                           ; A-2      len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte $91                           ; A-2      len 2 = 4 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd42_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$FC             ; -4 semitones
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $B1                           ; noise B  len 2 = 2 fr
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $93                           ; noise 9  len 4 = 4 fr
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte $93                           ; noise 9  len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $44 (sound effect)
;======================================================================
Sound_44:
        .byte $20                           ; channels: SfxNoise
        .word Snd44_SfxNoise

Snd44_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$03                 ; note length x3
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_CALL
        .word Sub_8C48
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte $C0                           ; rest     len 1 = 3 fr
        .byte $B2                           ; noise B  len 3 = 9 fr
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_8C48
        .byte CMD_VOLUME_ADD,$06            ; volume attenuation +6
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Sub_8C48:
        .byte $B0                           ; noise B  len 1
        .byte CMD_VOLUME_ADD,$FC            ; volume attenuation -4
        .byte $A0                           ; noise A  len 1
        .byte $90                           ; noise 9  len 1
        .byte $80                           ; noise 8  len 1
        .byte $70                           ; noise 7  len 1
        .byte $60                           ; noise 6  len 1
        .byte $50                           ; noise 5  len 1
        .byte CMD_RETURN

;======================================================================
; Sound $45 (sound effect)
;======================================================================
Sound_45:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd45_SfxSq2
        .word Snd45_SfxNoise

Snd45_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_OCTAVE0
        .byte $91                           ; A-0      len 2 = 4 fr
        .byte CMD_CALL
        .word Sub_8C73
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_CALL
        .word Sub_8C73
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_CALL
        .word Sub_8C73
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

Sub_8C73:
        .byte $91                           ; A-0      len 2
        .byte $C0                           ; rest     len 1
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte $91                           ; A-0      len 2
        .byte $C0                           ; rest     len 1
        .byte CMD_RETURN

Snd45_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_CALL
        .word Sub_8C96
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_VOLUME,$07                ; volume -7
        .byte CMD_CALL
        .word Sub_8C96
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $B0                           ; noise B  len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_VOLUME_ADD,$04            ; volume attenuation +4
        .byte $B6                           ; noise B  len 7 = 35 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Sub_8C96:
        .byte $B2                           ; noise B  len 3 = 6 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$04            ; volume attenuation +4
        .byte $B0                           ; noise B  len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_RETURN

;======================================================================
; Sound $46 (sound effect)
;======================================================================
Sound_46:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd46_SfxSq2
        .word Snd46_SfxNoise

Snd46_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE4
        .byte CMD_CALL
        .word Sub_8CBC
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_OCTAVE6
        .byte CMD_CALL
        .word Sub_8CBC
        .byte CMD_CALL
        .word Sub_8CBC
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_8CBC:
        .byte CMD_DUTY,$00                  ; duty 0
        .byte $60                           ; F#4/F#6  len 1 = 1 fr
        .byte CMD_DUTY,$03                  ; duty 3
        .byte $60                           ; F#4/F#6  len 1 = 1 fr
        .byte CMD_RETURN

Snd46_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $51                           ; noise 5  len 2 = 2 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte $73                           ; noise 7  len 4 = 4 fr
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $47 (sound effect)
;======================================================================
Sound_47:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd47_SfxSq2
        .word Snd47_SfxNoise

Snd47_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_OCTAVE0
        .byte $90                           ; A-0      len 1 = 2 fr
        .byte $A0                           ; A#0      len 1 = 2 fr
        .byte CMD_OCTAVE_UP
        .byte $00                           ; C-1      len 1 = 2 fr
        .byte $C1                           ; rest     len 2 = 4 fr
        .byte CMD_VOLUME_ADD,$04            ; volume attenuation +4
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd47_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte $C1                           ; rest     len 2 = 4 fr
        .byte $B1                           ; noise B  len 2 = 4 fr
        .byte $70                           ; noise 7  len 1 = 2 fr
        .byte CMD_VOLUME,$03                ; volume -3
        .byte $C3                           ; rest     len 4 = 8 fr
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte $B2                           ; noise B  len 3 = 6 fr
        .byte $70                           ; noise 7  len 1 = 2 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $48 (sound effect)
;======================================================================
Sound_48:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd48_SfxSq2
        .word Snd48_SfxNoise

Snd48_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_OCTAVE2
        .byte CMD_SWEEP,$9D                 ; sweep register $9D
        .byte $97                           ; A-2      len 8 = 32 fr
        .byte CMD_VOLUME,$07                ; volume -7
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte $93                           ; A-2      len 4 = 16 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

Snd48_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_VOLUME,$09                ; volume -9
        .byte $71                           ; noise 7  len 2 = 8 fr
        .byte $61                           ; noise 6  len 2 = 8 fr
        .byte $51                           ; noise 5  len 2 = 8 fr
        .byte $41                           ; noise 4  len 2 = 8 fr
        .byte $31                           ; noise 3  len 2 = 8 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $49 (sound effect)
;======================================================================
Sound_49:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd49_SfxSq2
        .word Snd49_SfxNoise

Snd49_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE3
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_CALL
        .word Sub_8D66
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_VOLUME,$07                ; volume -7
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte CMD_CALL
        .word Sub_8D66
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_8D66:
        .byte CMD_DUTY,$00                  ; duty 0
        .byte $90                           ; A-3      len 1 = 1 fr
        .byte CMD_DUTY,$03                  ; duty 3
        .byte $90                           ; A-3      len 1 = 1 fr
        .byte CMD_RETURN

Snd49_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $73                           ; noise 7  len 4 = 4 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_VOLUME,$07                ; volume -7
        .byte $71                           ; noise 7  len 2 = 2 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte $43                           ; noise 4  len 4 = 4 fr
        .byte CMD_VOLUME,$0C                ; volume -12
        .byte $C3                           ; rest     len 4 = 4 fr
        .byte $45                           ; noise 4  len 6 = 6 fr
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte $41                           ; noise 4  len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte $43                           ; noise 4  len 4 = 4 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $4A (sound effect)
;======================================================================
Sound_4A:
        .byte $20                           ; channels: SfxNoise
        .word Snd4A_SfxNoise

Snd4A_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_CALL
        .word Sub_8DA7
        .byte CMD_VOLUME,$08                ; volume -8
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $B1                           ; noise B  len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_8DA7
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_8DA7:
        .byte $A0                           ; noise A  len 1 = 1 fr
        .byte $90                           ; noise 9  len 1 = 1 fr
        .byte $80                           ; noise 8  len 1 = 1 fr
        .byte $70                           ; noise 7  len 1 = 1 fr
        .byte $60                           ; noise 6  len 1 = 1 fr
        .byte $50                           ; noise 5  len 1 = 1 fr
        .byte CMD_RETURN

;======================================================================
; Sound $4B (sound effect)
;======================================================================
Sound_4B:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd4B_SfxSq2
        .word Snd4B_SfxNoise

Snd4B_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_OCTAVE3
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $80                           ; G#3      len 1 = 2 fr
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte $60                           ; F#3      len 1 = 2 fr
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $00                           ; C-3      len 1 = 2 fr
        .byte $90                           ; A-3      len 1 = 2 fr
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte $20                           ; D-3      len 1 = 2 fr
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $50                           ; F-3      len 1 = 2 fr
        .byte $10                           ; C#3      len 1 = 2 fr
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte $70                           ; G-3      len 1 = 2 fr
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $A0                           ; A#3      len 1 = 2 fr
        .byte CMD_SWEEP,$85                 ; sweep register $85
        .byte $30                           ; D#3      len 1 = 2 fr
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $B0                           ; B-3      len 1 = 2 fr
        .byte $40                           ; E-3      len 1 = 2 fr
        .byte CMD_VOLUME_ADD,$03            ; volume attenuation +3
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd4B_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$0B                ; volume -11
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $70                           ; noise 7  len 1 = 2 fr
        .byte $A0                           ; noise A  len 1 = 2 fr
        .byte $80                           ; noise 8  len 1 = 2 fr
        .byte $B0                           ; noise B  len 1 = 2 fr
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$FF         ; transpose -1 more
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $4C, Sound $4D (sound effect)
;======================================================================
Sound_4C:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd4C_SfxSq2
        .word Snd4C_SfxNoise

Snd4C_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_OCTAVE1
        .byte $51                           ; F-1      len 2 = 2 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 1 fr
        .byte CMD_OCTAVE1
        .byte $52                           ; F-1      len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd4C_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $61                           ; noise 6  len 2 = 10 fr
        .byte $A1                           ; noise A  len 2 = 10 fr
        .byte $9B                           ; noise 9  len 12 = 60 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

;======================================================================
; Sound $4E, Sound $4F (sound effect)
;======================================================================
Sound_4E:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd4E_SfxSq2
        .word Snd4E_SfxNoise

Snd4E_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$18                  ; repeat 24x
        .byte CMD_OCTAVE0
        .byte $91                           ; A-0      len 2 = 2 fr
        .byte $A1                           ; A#0      len 2 = 2 fr
        .byte CMD_OCTAVE_UP
        .byte $02                           ; C-1      len 3 = 3 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd4E_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_TRANSPOSE,$FD             ; -3 semitones
        .byte CMD_LOOP,$18                  ; repeat 24x
        .byte $B3                           ; noise B  len 4 = 8 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $50 (sound effect)
;======================================================================
Sound_50:
        .byte $20                           ; channels: SfxNoise
        .word Snd50_SfxNoise

Snd50_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_TRANSPOSE,$FC             ; -4 semitones
        .byte $BF                           ; noise B  len 16 = 64 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $51 (sound effect)
;======================================================================
Sound_51:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd51_SfxSq2
        .word Snd51_SfxNoise

Snd51_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE6
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_DUTY,$00                  ; duty 0
        .byte $70                           ; G-6      len 1 = 1 fr
        .byte CMD_DUTY,$01                  ; duty 1
        .byte $70                           ; G-6      len 1 = 1 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd51_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $70                           ; noise 7  len 1 = 1 fr
        .byte $00                           ; noise 0  len 1 = 1 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $52 (sound effect)
;======================================================================
Sound_52:
        .byte $20                           ; channels: SfxNoise
        .word Snd52_SfxNoise

Snd52_SfxNoise:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_LOOP,$80                  ; repeat 128x
        .byte $70                           ; noise 7  len 1 = 1 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $53 (sound effect)
;======================================================================
Sound_53:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd53_SfxSq2
        .word Snd53_SfxNoise

Snd53_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE_ADD,$06         ; transpose +6 more
        .byte CMD_TRANSPOSE,$FB             ; -5 semitones
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $41                           ; E-3      len 2 = 8 fr
        .byte CMD_TRANSPOSE,$F8             ; -8 semitones
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $00                           ; C-3      len 1 = 4 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_TRANSPOSE,$F8             ; -8 semitones
        .byte CMD_OCTAVE2
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $90                           ; A-2      len 1 = 2 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $00                           ; C-2      len 1 = 2 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

Snd53_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$04                ; volume -4
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_VOLUME,$05                ; volume -5
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $B0                           ; noise B  len 1 = 1 fr
        .byte CMD_VOLUME,$09                ; volume -9
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_8ED3
        .byte CMD_VOLUME,$08                ; volume -8
        .byte CMD_CALL
        .word Sub_8ED3
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Sub_8ED3:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $B3                           ; noise B  len 4 = 4 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_LOOP_END
        .byte CMD_RETURN

;======================================================================
; Sound $54 (sound effect)
;======================================================================
Sound_54:
        .byte $10                           ; channels: SfxSq2
        .word Snd54_SfxSq2

Snd54_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$06             ; +6 semitones
        .byte CMD_LOOP,$06                  ; repeat 6x
        .byte CMD_OCTAVE1
        .byte $50                           ; F-1      len 1 = 1 fr
        .byte CMD_OCTAVE_UP
        .byte $50                           ; F-2      len 1 = 1 fr
        .byte CMD_TRANSPOSE_ADD,$01         ; transpose +1 more
        .byte CMD_LOOP_END
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_OCTAVE1
        .byte $52                           ; F-1      len 3 = 3 fr
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_OCTAVE_UP
        .byte $50                           ; F-2      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $55 (sound effect)
;======================================================================
Sound_55:
        .byte $10                           ; channels: SfxSq2
        .word Snd55_SfxSq2

Snd55_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE5
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte $31                           ; D#5      len 2 = 2 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_VOLUME_ADD,$05            ; volume attenuation +5
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $56 (sound effect)
;======================================================================
Sound_56:
        .byte $10                           ; channels: SfxSq2
        .word Snd56_SfxSq2

Snd56_SfxSq2:
        .byte CMD_ENVELOPE,$2A              ; volume envelope $2A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$05             ; +5 semitones
        .byte CMD_OCTAVE2
        .byte $51                           ; F-2      len 2 = 2 fr
        .byte $41                           ; E-2      len 2 = 2 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $53                           ; F-2      len 4 = 4 fr
        .byte $43                           ; E-2      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $57 (sound effect)
;======================================================================
Sound_57:
        .byte $10                           ; channels: SfxSq2
        .word Snd57_SfxSq2

Snd57_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_SWEEP,$00                 ; sweep register $00
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte CMD_OCTAVE3
        .byte $54                           ; F-3      len 5 = 5 fr
        .byte CMD_SWEEP,$00                 ; sweep register $00
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $58 (sound effect)
;======================================================================
Sound_58:
        .byte $20                           ; channels: SfxNoise
        .word Snd58_SfxNoise

Snd58_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_SWEEP,$00                 ; sweep register $00
        .byte CMD_VOLUME,$00                ; volume -0
        .byte $B1                           ; noise B  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $27                           ; noise 2  len 8 = 8 fr
        .byte CMD_VOLUME_ADD,$03            ; volume attenuation +3
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $59 (sound effect)
;======================================================================
Sound_59:
        .byte $10                           ; channels: SfxSq2
        .word Snd59_SfxSq2

Snd59_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$93                 ; sweep register $93
        .byte $40                           ; E-3      len 1 = 4 fr
        .byte CMD_SWEEP,$9B                 ; sweep register $9B
        .byte $00                           ; C-3      len 1 = 4 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_END

;======================================================================
; Sound $5A (sound effect)
;======================================================================
Sound_5A:
        .byte $10                           ; channels: SfxSq2
        .word Snd5A_SfxSq2

Snd5A_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte CMD_OCTAVE3
        .byte CMD_TRANSPOSE,$07             ; +7 semitones
        .byte $01                           ; C-3      len 2 = 2 fr
        .byte $21                           ; D-3      len 2 = 2 fr
        .byte $01                           ; C-3      len 2 = 2 fr
        .byte $21                           ; D-3      len 2 = 2 fr
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $5B (sound effect)
;======================================================================
Sound_5B:
        .byte $10                           ; channels: SfxSq2
        .word Snd5B_SfxSq2

Snd5B_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_SWEEP,$84                 ; sweep register $84
        .byte CMD_OCTAVE2
        .byte $92                           ; A-2      len 3 = 3 fr
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$FB             ; -5 semitones
        .byte CMD_OCTAVE4
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_SWEEP,$8C                 ; sweep register $8C
        .byte $41                           ; E-4      len 2 = 2 fr
        .byte $C9                           ; rest     len 10 = 10 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $5C (sound effect)
;======================================================================
Sound_5C:
        .byte $10                           ; channels: SfxSq2
        .word Snd5C_SfxSq2

Snd5C_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$02                 ; note length x2
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_OCTAVE5
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $01                           ; C-4/C-5  len 2 = 4 fr
        .byte CMD_OCTAVE4
        .byte $71                           ; G-4      len 2 = 4 fr
        .byte $41                           ; E-4      len 2 = 4 fr
        .byte $71                           ; G-4      len 2 = 4 fr
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE5
        .byte $05                           ; C-5      len 6 = 12 fr
        .byte $C0                           ; rest     len 1 = 2 fr
        .byte CMD_END

;======================================================================
; Sound $5D (sound effect)
;======================================================================
Sound_5D:
        .byte $30                           ; channels: SfxSq2, SfxNoise
        .word Snd5D_SfxSq2
        .word Snd5D_SfxNoise

Snd5D_SfxSq2:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE_ADD,$0C         ; transpose +12 more
        .byte CMD_OCTAVE1
        .byte $91                           ; A-1      len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_OCTAVE1
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $01                           ; C-1      len 2 = 2 fr
        .byte $01                           ; C-1      len 2 = 2 fr
        .byte CMD_TRANSPOSE_ADD,$FF         ; transpose -1 more
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd5D_SfxNoise:
        .byte CMD_ENVELOPE,$30              ; volume envelope $30 (starts with the next note)
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$05                ; volume -5
        .byte $01                           ; noise 0  len 2 = 2 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_TRANSPOSE,$00             ; +0 semitones
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $11                           ; noise 1  len 2 = 2 fr
        .byte $01                           ; noise 0  len 2 = 2 fr
        .byte CMD_TRANSPOSE_ADD,$01         ; transpose +1 more
        .byte CMD_VOLUME_ADD,$08            ; volume attenuation +8
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $00, Sound $10, Sound $15, Sound $16, Sound $17, Sound $18, Sound $19, Sound $1A, Sound $1B, Sound $1C, Sound $1D, Sound $1E, Sound $1F (empty: stops the music)
;======================================================================
Sound_00:
        .byte $00                           ; channels: none (stops the music)

; every channel points here after a reset
SilentTrack:
        .byte $C0                           ; rest     len 1
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;
; Noise drum macros, indexed by mDrumMap[note] (13 entries)
DrumTable:
        .word Drum_00                       ; $00
        .word Drum_01                       ; $01
        .word Drum_02                       ; $02
        .word Drum_03                       ; $03
        .word Drum_04                       ; $04
        .word Drum_05                       ; $05
        .word Drum_06                       ; $06
        .word Drum_07                       ; $07
        .word Drum_Silent                   ; $08
        .word Drum_Silent                   ; $09
        .word Drum_Silent                   ; $0A
        .word Drum_Silent                   ; $0B
        .word Drum_Silent                   ; $0C

Drum_00:
        .byte $9E                           ; volume envelope $1E
        .byte $1D                           ; noise period 14, next frame
        .byte $FF                           ; end (stays here)

Drum_01:
        .byte $9F                           ; volume envelope $1F
        .byte $07                           ; noise period 3, next frame
        .byte $FF                           ; end (stays here)

Drum_02:
        .byte $A0                           ; volume envelope $20
        .byte $17                           ; noise period 11, next frame
        .byte $FF                           ; end (stays here)

Drum_03:
        .byte $A1                           ; volume envelope $21
        .byte $05                           ; noise period 2, next frame
        .byte $FF                           ; end (stays here)

Drum_04:
        .byte $A2                           ; volume envelope $22
        .byte $12                           ; noise period 9, next frame
        .byte $FF                           ; end (stays here)

Drum_05:
        .byte $A2                           ; volume envelope $22
        .byte $1A                           ; noise period 13, next frame
        .byte $FF                           ; end (stays here)

Drum_06:
        .byte $A3                           ; volume envelope $23
        .byte $16                           ; noise period 11, next frame
        .byte $FF                           ; end (stays here)

Drum_07:
        .byte $A4                           ; volume envelope $24
        .byte $13                           ; noise period 9, next frame
        .byte $FF                           ; end (stays here)

Drum_Silent:
        .byte $FF                           ; end (stays here)

;
; Volume envelopes (CMD_ENVELOPE n, drum $80+n)
EnvTable:
        .word Env_00                        ; $00
        .word Env_01                        ; $01 (not used by any track or drum)
        .word Env_02                        ; $02
        .word Env_03                        ; $03
        .word Env_04                        ; $04
        .word Env_05                        ; $05 (not used by any track or drum)
        .word Env_06                        ; $06 (not used by any track or drum)
        .word Env_07                        ; $07
        .word Env_08                        ; $08
        .word Env_09                        ; $09
        .word Env_0A                        ; $0A
        .word Env_0B                        ; $0B
        .word Env_0C                        ; $0C
        .word Env_0D                        ; $0D (not used by any track or drum)
        .word Env_0E                        ; $0E (not used by any track or drum)
        .word Env_0F                        ; $0F (not used by any track or drum)
        .word Env_10                        ; $10 (not used by any track or drum)
        .word Env_11                        ; $11 (not used by any track or drum)
        .word Env_12                        ; $12 (not used by any track or drum)
        .word Env_13                        ; $13 (not used by any track or drum)
        .word Env_14                        ; $14 (not used by any track or drum)
        .word Env_15                        ; $15 (not used by any track or drum)
        .word Env_16                        ; $16 (not used by any track or drum)
        .word Env_16                        ; $17 (not used by any track or drum)
        .word Env_18                        ; $18
        .word Env_19                        ; $19
        .word Env_1A                        ; $1A
        .word Env_1B                        ; $1B
        .word Env_1C                        ; $1C
        .word Env_1D                        ; $1D (not used by any track or drum)
        .word Env_1E                        ; $1E
        .word Env_1F                        ; $1F
        .word Env_20                        ; $20
        .word Env_21                        ; $21
        .word Env_22                        ; $22
        .word Env_23                        ; $23
        .word Env_24                        ; $24
        .word Env_25                        ; $25 (not used by any track or drum)
        .word Env_25                        ; $26 (not used by any track or drum)
        .word Env_25                        ; $27 (not used by any track or drum)
        .word Env_25                        ; $28 (not used by any track or drum)
        .word Env_29                        ; $29 (not used by any track or drum)
        .word Env_2A                        ; $2A
        .word Env_2B                        ; $2B (not used by any track or drum)
        .word Env_2C                        ; $2C (not used by any track or drum)
        .word Env_2D                        ; $2D (not used by any track or drum)
        .word Env_2E                        ; $2E (not used by any track or drum)
        .word Env_2F                        ; $2F (not used by any track or drum)
        .word Env_30                        ; $30
        .word Env_31                        ; $31 (not used by any track or drum)
        .word Env_32                        ; $32 (not used by any track or drum)

Env_00:
        .byte $FE,$00,$B0                   ; set volume 11 ($B000)
        .byte $03,$00,$00                   ;   3 frame(s), +0.0000 per frame
        .byte $02,$00,$C8                   ;   2 frame(s), -3.5000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $40,$60,$FF                   ;  64 frame(s), -0.0391 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_01:
        .byte $FF                           ; end: volume 0, envelope off

Env_02:
        .byte $FE,$00,$B0                   ; set volume 11 ($B000)
        .byte $0C,$00,$F8                   ;  12 frame(s), -0.5000 per frame
        .byte $05,$00,$00                   ;   5 frame(s), +0.0000 per frame
        .byte $01,$00,$F0                   ;   1 frame(s), -1.0000 per frame
        .byte $06,$AB,$FE                   ;   6 frame(s), -0.0833 per frame
        .byte $0C,$AB,$FE                   ;  12 frame(s), -0.0833 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_03:
        .byte $FE,$00,$90                   ; set volume 9 ($9000)
        .byte $14,$00,$FC                   ;  20 frame(s), -0.2500 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $09,$56,$FD                   ;   9 frame(s), -0.1665 per frame
        .byte $3C,$56,$FF                   ;  60 frame(s), -0.0415 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_04:
        .byte $FE,$00,$68                   ; set volume 6 ($6800)
        .byte $20,$00,$00                   ;  32 frame(s), +0.0000 per frame
        .byte $C8,$7B,$FF                   ; 200 frame(s), -0.0325 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_05:
        .byte $FF                           ; end: volume 0, envelope off

Env_06:
        .byte $FF                           ; end: volume 0, envelope off

Env_07:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $14,$00,$FC                   ;  20 frame(s), -0.2500 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $13,$E6,$FD                   ;  19 frame(s), -0.1313 per frame
        .byte $3C,$9A,$FF                   ;  60 frame(s), -0.0249 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_08:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $20,$00,$00                   ;  32 frame(s), +0.0000 per frame
        .byte $C8,$7B,$FF                   ; 200 frame(s), -0.0325 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_09:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $04,$00,$00                   ;   4 frame(s), +0.0000 per frame
        .byte $07,$DC,$EE                   ;   7 frame(s), -1.0713 per frame
        .byte $07,$B6,$0D                   ;   7 frame(s), +0.8569 per frame
        .byte $07,$6E,$F3                   ;   7 frame(s), -0.7856 per frame
        .byte $07,$49,$0A                   ;   7 frame(s), +0.6428 per frame
        .byte $07,$DC,$F6                   ;   7 frame(s), -0.5713 per frame
        .byte $07,$DB,$06                   ;   7 frame(s), +0.4285 per frame
        .byte $07,$25,$F9                   ;   7 frame(s), -0.4285 per frame
        .byte $07,$6D,$03                   ;   7 frame(s), +0.2141 per frame
        .byte $07,$93,$FC                   ;   7 frame(s), -0.2141 per frame
        .byte $07,$49,$02                   ;   7 frame(s), +0.1428 per frame
        .byte $07,$B7,$FD                   ;   7 frame(s), -0.1428 per frame
        .byte $07,$49,$02                   ;   7 frame(s), +0.1428 per frame
        .byte $07,$B7,$FD                   ;   7 frame(s), -0.1428 per frame
        .byte $20,$C0,$FE                   ;  32 frame(s), -0.0781 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_0A:
        .byte $FE,$00,$98                   ; set volume 9 ($9800)
        .byte $04,$00,$00                   ;   4 frame(s), +0.0000 per frame
        .byte $07,$DC,$EE                   ;   7 frame(s), -1.0713 per frame
        .byte $07,$B6,$0D                   ;   7 frame(s), +0.8569 per frame
        .byte $07,$6E,$F3                   ;   7 frame(s), -0.7856 per frame
        .byte $07,$49,$0A                   ;   7 frame(s), +0.6428 per frame
        .byte $07,$DC,$F6                   ;   7 frame(s), -0.5713 per frame
        .byte $07,$DB,$06                   ;   7 frame(s), +0.4285 per frame
        .byte $07,$25,$F9                   ;   7 frame(s), -0.4285 per frame
        .byte $07,$6D,$03                   ;   7 frame(s), +0.2141 per frame
        .byte $07,$93,$FC                   ;   7 frame(s), -0.2141 per frame
        .byte $07,$49,$02                   ;   7 frame(s), +0.1428 per frame
        .byte $07,$B7,$FD                   ;   7 frame(s), -0.1428 per frame
        .byte $07,$49,$02                   ;   7 frame(s), +0.1428 per frame
        .byte $07,$B7,$FD                   ;   7 frame(s), -0.1428 per frame
        .byte $20,$C0,$FE                   ;  32 frame(s), -0.0781 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_0B:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $01,$00,$00                   ;   1 frame(s), +0.0000 per frame
        .byte $FE,$00,$D8                   ; set volume 13 ($D800)
        .byte $7F,$67,$FE                   ; 127 frame(s), -0.0999 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_0C:
        .byte $FE,$00,$F0                   ; set volume 15 ($F000)
        .byte $01,$00,$08                   ;   1 frame(s), +0.5000 per frame
        .byte $02,$00,$F8                   ;   2 frame(s), -0.5000 per frame
        .byte $0F,$00,$00                   ;  15 frame(s), +0.0000 per frame
        .byte $EF,$BC,$FF                   ; 239 frame(s), -0.0166 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_0D:
        .byte $FF                           ; end: volume 0, envelope off

Env_0E:
        .byte $FF                           ; end: volume 0, envelope off

Env_0F:
        .byte $FF                           ; end: volume 0, envelope off

Env_10:
        .byte $FF                           ; end: volume 0, envelope off

Env_11:
        .byte $FF                           ; end: volume 0, envelope off

Env_12:
        .byte $FF                           ; end: volume 0, envelope off

Env_13:
        .byte $FF                           ; end: volume 0, envelope off

Env_14:
        .byte $FE,$00,$38                   ; set volume 3 ($3800)
        .byte $04,$00,$10                   ;   4 frame(s), +1.0000 per frame
        .byte $29,$13,$FD                   ;  41 frame(s), -0.1829 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_15:
        .byte $FF                           ; end: volume 0, envelope off

Env_16:
        .byte $FF                           ; end: volume 0, envelope off

Env_18:
        .byte $FE,$00,$C0                   ; set volume 12 ($C000)
        .byte $02,$00,$F0                   ;   2 frame(s), -1.0000 per frame
        .byte $02,$00,$E4                   ;   2 frame(s), -1.7500 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $06,$00,$00                   ;   6 frame(s), +0.0000 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_19:
        .byte $FE,$00,$D8                   ; set volume 13 ($D800)
        .byte $05,$00,$F8                   ;   5 frame(s), -0.5000 per frame
        .byte $05,$00,$00                   ;   5 frame(s), +0.0000 per frame
        .byte $02,$00,$C8                   ;   2 frame(s), -3.5000 per frame
        .byte $06,$00,$F8                   ;   6 frame(s), -0.5000 per frame
        .byte $0C,$AB,$FE                   ;  12 frame(s), -0.0833 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_1A:
        .byte $FE,$00,$90                   ; set volume 9 ($9000)
        .byte $14,$00,$FC                   ;  20 frame(s), -0.2500 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $13,$E6,$FD                   ;  19 frame(s), -0.1313 per frame
        .byte $3C,$9A,$FF                   ;  60 frame(s), -0.0249 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_1B:
        .byte $FE,$00,$C0                   ; set volume 12 ($C000)
        .byte $04,$00,$F0                   ;   4 frame(s), -1.0000 per frame
        .byte $02,$00,$E4                   ;   2 frame(s), -1.7500 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $06,$00,$00                   ;   6 frame(s), +0.0000 per frame
        .byte $04,$00,$FC                   ;   4 frame(s), -0.2500 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_1C:
        .byte $FE,$00,$68                   ; set volume 6 ($6800)
        .byte $20,$00,$00                   ;  32 frame(s), +0.0000 per frame
        .byte $C8,$7B,$FF                   ; 200 frame(s), -0.0325 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_1D:
        .byte $FF                           ; end: volume 0, envelope off

Env_1E:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $01,$00,$00                   ;   1 frame(s), +0.0000 per frame
        .byte $01,$00,$E0                   ;   1 frame(s), -2.0000 per frame
        .byte $01,$00,$A8                   ;   1 frame(s), -5.5000 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $01,$00,$E0                   ;   1 frame(s), -2.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$F0                   ;   1 frame(s), -1.0000 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_1F:
        .byte $FE,$00,$C8                   ; set volume 12 ($C800)
        .byte $14,$00,$FC                   ;  20 frame(s), -0.2500 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $09,$8F,$FB                   ;   9 frame(s), -0.2776 per frame
        .byte $3C,$AB,$FE                   ;  60 frame(s), -0.0833 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_20:
        .byte $FE,$00,$E8                   ; set volume 14 ($E800)
        .byte $01,$00,$00                   ;   1 frame(s), +0.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$A8                   ;   1 frame(s), -5.5000 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $01,$00,$E0                   ;   1 frame(s), -2.0000 per frame
        .byte $01,$00,$F0                   ;   1 frame(s), -1.0000 per frame
        .byte $18,$56,$FF                   ;  24 frame(s), -0.0415 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_21:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $01,$00,$00                   ;   1 frame(s), +0.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$A8                   ;   1 frame(s), -5.5000 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $01,$00,$E0                   ;   1 frame(s), -2.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_22:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $01,$00,$00                   ;   1 frame(s), +0.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$A8                   ;   1 frame(s), -5.5000 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $01,$00,$E0                   ;   1 frame(s), -2.0000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $01,$00,$E8                   ;   1 frame(s), -1.5000 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_23:
        .byte $FE,$00,$C0                   ; set volume 12 ($C000)
        .byte $04,$00,$F0                   ;   4 frame(s), -1.0000 per frame
        .byte $02,$00,$E4                   ;   2 frame(s), -1.7500 per frame
        .byte $01,$00,$C8                   ;   1 frame(s), -3.5000 per frame
        .byte $2A,$00,$00                   ;  42 frame(s), +0.0000 per frame
        .byte $28,$9A,$FF                   ;  40 frame(s), -0.0249 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_24:
        .byte $FE,$00,$78                   ; set volume 7 ($7800)
        .byte $0A,$9A,$F9                   ;  10 frame(s), -0.3999 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $09,$56,$FD                   ;   9 frame(s), -0.1665 per frame
        .byte $3C,$78,$FF                   ;  60 frame(s), -0.0332 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_25:
        .byte $FF                           ; end: volume 0, envelope off

Env_29:
        .byte $FF                           ; end: volume 0, envelope off

Env_2A:
        .byte $FE,$00,$F0                   ; set volume 15 ($F000)
        .byte $14,$00,$FC                   ;  20 frame(s), -0.2500 per frame
        .byte $0A,$00,$00                   ;  10 frame(s), +0.0000 per frame
        .byte $09,$1D,$F7                   ;   9 frame(s), -0.5554 per frame
        .byte $3C,$AB,$FE                   ;  60 frame(s), -0.0833 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_2B:
        .byte $FF                           ; end: volume 0, envelope off

Env_2C:
        .byte $FF                           ; end: volume 0, envelope off

Env_2D:
        .byte $FF                           ; end: volume 0, envelope off

Env_2E:
        .byte $FF                           ; end: volume 0, envelope off

Env_2F:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $1F,$22,$FC                   ;  31 frame(s), -0.2417 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_30:
        .byte $FE,$00,$F8                   ; set volume 15 ($F800)
        .byte $F0,$00,$00                   ; 240 frame(s), +0.0000 per frame
        .byte $FE,$00,$00                   ; set volume 0 ($0000)
        .byte $FF                           ; end: volume 0, envelope off

Env_31:
        .byte $FF                           ; end: volume 0, envelope off

Env_32:
        .byte $FF                           ; end: volume 0, envelope off

;======================================================================
; Sound $01 (music)
;======================================================================
Sound_01:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd01_Sq1
        .word Snd01_Sq2
        .word Snd01_Tri
        .word Snd01_Noise

Snd01_Sq1:
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones

Loop_92DA:
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte CMD_CALL
        .word Sub_935C
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9372
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_935C
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_937A
        .byte CMD_LOOP_END
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $B2                           ; B-4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $62                           ; F#5      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9382
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_938D
        .byte CMD_LOOP_END
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C7                           ; rest     len 8 = 40 fr
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_OCTAVE6
        .byte $41                           ; E-6      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $61                           ; F#6      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#6      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B1                           ; B-6      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9397
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte CMD_LOOP_END
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $62                           ; F#5      len 3 = 15 fr
        .byte $82                           ; G#5      len 3 = 15 fr
        .byte $A1                           ; A#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_939F
        .byte CMD_CALL
        .word Sub_93A8
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_93AC
        .byte CMD_LOOP_END
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_939F
        .byte CMD_OCTAVE5
        .byte $A0                           ; A#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $A0                           ; A#5      len 1 = 5 fr
        .byte $C7                           ; rest     len 8 = 40 fr
        .byte CMD_JUMP
        .word Loop_92DA

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_935C:
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $80                           ; G#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $22                           ; D-5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_9372:
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $80                           ; G#4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $82                           ; G#4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_RETURN

Sub_937A:
        .byte CMD_OCTAVE5
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $12                           ; C#5      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_RETURN

Sub_9382:
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $B2                           ; B-5      len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $80                           ; G#5      len 1 = 5 fr
        .byte $CA                           ; rest     len 11 = 55 fr
        .byte CMD_RETURN

Sub_938D:
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_9397:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $82                           ; G#5      len 3 = 15 fr
        .byte $42                           ; E-5      len 3 = 15 fr
        .byte CMD_RETURN

Sub_939F:
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte CMD_OCTAVE6
        .byte $12                           ; C#6      len 3 = 15 fr
        .byte CMD_RETURN

Sub_93A8:
        .byte CMD_OCTAVE5
        .byte $A0                           ; A#5      len 1 = 5 fr
        .byte $CA                           ; rest     len 11 = 55 fr
        .byte CMD_RETURN

Sub_93AC:
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Snd01_Sq2:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$01                ; volume -1
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones

Loop_93C0:
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte CMD_TRANSPOSE_ADD,$F4         ; transpose -12 more
        .byte CMD_CALL
        .word Sub_935C
        .byte CMD_TRANSPOSE_ADD,$0C         ; transpose +12 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_94E9
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$F4         ; transpose -12 more
        .byte CMD_CALL
        .word Sub_935C
        .byte CMD_TRANSPOSE_ADD,$0C         ; transpose +12 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_94F2
        .byte CMD_LOOP_END
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_OCTAVE3
        .byte $6B                           ; F#3      len 12 = 60 fr
        .byte $B8                           ; B-3      len 9 = 45 fr
        .byte CMD_OCTAVE4
        .byte $11                           ; C#4      len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $4A                           ; E-4      len 11 = 55 fr
        .byte CMD_TIE
        .byte $48                           ; E-4      len 9 = 45 fr
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $80                           ; G#4      len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_94FA
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $80                           ; G#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_CALL
        .word Sub_9503
        .byte CMD_OCTAVE5
        .byte $45                           ; E-5      len 6 = 30 fr
        .byte CMD_TIE
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_94FA
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_CALL
        .word Sub_9503
        .byte $45                           ; E-5      len 6 = 30 fr
        .byte CMD_TIE
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C7                           ; rest     len 8 = 40 fr
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE6
        .byte $42                           ; E-6      len 3 = 15 fr
        .byte $62                           ; F#6      len 3 = 15 fr
        .byte $82                           ; G#6      len 3 = 15 fr
        .byte $B1                           ; B-6      len 2 = 10 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $B1                           ; B-6      len 2 = 2 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_CALL
        .word Sub_9507
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_9507
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $91                           ; A-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_VOLUME_ADD,$03            ; volume attenuation +3
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$FD            ; volume attenuation -3
        .byte CMD_VOLUME_ADD,$05            ; volume attenuation +5
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $A1                           ; A#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$FB            ; volume attenuation -5
        .byte CMD_CALL
        .word Sub_9515
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $6B                           ; F#5      len 12 = 60 fr
        .byte CMD_TIE
        .byte $65                           ; F#5      len 6 = 30 fr
        .byte CMD_TIE
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $90                           ; A-5      len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_9515
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $90                           ; A-5      len 1 = 5 fr
        .byte $80                           ; G#5      len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_ENVELOPE,$04              ; volume envelope $04 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $6B                           ; F#5      len 12 = 60 fr
        .byte CMD_TIE
        .byte $65                           ; F#5      len 6 = 30 fr
        .byte CMD_TIE
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_9515
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $A1                           ; A#5      len 2 = 10 fr
        .byte CMD_OCTAVE6
        .byte $10                           ; C#6      len 1 = 5 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $B5                           ; B-5      len 6 = 30 fr
        .byte CMD_TIE
        .byte $B1                           ; B-5      len 2 = 10 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $92                           ; A-5      len 3 = 15 fr
        .byte CMD_CALL
        .word Sub_9515
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $C7                           ; rest     len 8 = 40 fr
        .byte CMD_JUMP
        .word Loop_93C0

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_94E9:
        .byte CMD_OCTAVE4
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_RETURN

Sub_94F2:
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $92                           ; A-4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_RETURN

Sub_94FA:
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $82                           ; G#5      len 3 = 15 fr
        .byte CMD_RETURN

Sub_9503:
        .byte CMD_OCTAVE5
        .byte $4B                           ; E-5      len 12 = 60 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_9507:
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $81                           ; G#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_RETURN

Sub_9515:
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $A2                           ; A#5      len 3 = 15 fr
        .byte CMD_RETURN

Snd01_Tri:
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_DUTY,$03                  ; duty 3
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0

Loop_9525:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_95A3
        .byte CMD_CALL
        .word Sub_95AD
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $80                           ; G#3      len 1 = 5 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_95BA
        .byte CMD_CALL
        .word Sub_95C4
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_95A3
        .byte CMD_CALL
        .word Sub_95AD
        .byte CMD_CALL
        .word Sub_95CE
        .byte CMD_CALL
        .word Sub_95D8
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_95A3
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $80                           ; G#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $B0                           ; B-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $81                           ; G#3      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $80                           ; G#3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $80                           ; G#3      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $21                           ; D-3      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $41                           ; E-3      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $11                           ; C#3      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $10                           ; C#3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $10                           ; C#3      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $10                           ; C#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_95E2
        .byte CMD_CALL
        .word Sub_95EC
        .byte CMD_CALL
        .word Sub_95F9
        .byte CMD_CALL
        .word Sub_9603
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_95E2
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C7                           ; rest     len 8 = 40 fr
        .byte CMD_JUMP
        .word Loop_9525

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_95A3:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_95AD:
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_95BA:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_95C4:
        .byte CMD_OCTAVE3
        .byte $B0                           ; B-3      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $B0                           ; B-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte $80                           ; G#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_95CE:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_95D8:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_95E2:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_95EC:
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_95F9:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_9603:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Snd01_Noise:
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_SPEED,$05                 ; note length x5

Loop_9611:
        .byte CMD_CALL
        .word Sub_966B
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $32                           ; drum 3   len 3 = 15 fr
        .byte CMD_LOOP,$0B                  ; repeat 11x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9671
        .byte CMD_LOOP,$07                  ; repeat 7x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9671
        .byte CMD_CALL
        .word Sub_966B
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $31                           ; drum 3   len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $31                           ; drum 3   len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $32                           ; drum 3   len 3 = 15 fr
        .byte CMD_LOOP,$05                  ; repeat 5x
        .byte CMD_CALL
        .word Sub_9678
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9678
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9678
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9678
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_966B
        .byte CMD_LOOP_END
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $32                           ; drum 3   len 3 = 15 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $C5                           ; rest     len 6 = 30 fr
        .byte CMD_JUMP
        .word Loop_9611

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_966B:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_9671:
        .byte $32                           ; drum 3   len 3 = 15 fr
        .byte $31                           ; drum 3   len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $30                           ; drum 3   len 1 = 5 fr
        .byte $32                           ; drum 3   len 3 = 15 fr
        .byte CMD_RETURN

Sub_9678:
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte CMD_RETURN

;======================================================================
; Sound $02 (music)
;======================================================================
Sound_02:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd02_Sq1
        .word Snd02_Sq2
        .word Snd02_Tri
        .word Snd02_Noise

Snd02_Sq1:
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$05                ; volume -5
        .byte CMD_TRANSPOSE,$EF             ; -17 semitones
        .byte $C7                           ; rest     len 8 = 48 fr

Loop_9693:
        .byte CMD_CALL
        .word Sub_96BF
        .byte CMD_CALL
        .word Sub_96CB
        .byte CMD_CALL
        .word Sub_96BF
        .byte CMD_OCTAVE4
        .byte $97                           ; A-4      len 8 = 48 fr
        .byte CMD_OCTAVE5
        .byte $52                           ; F-5      len 3 = 18 fr
        .byte $00                           ; C-5      len 1 = 6 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_CALL
        .word Sub_96BF
        .byte CMD_CALL
        .word Sub_96CB
        .byte $05                           ; C-5      len 6 = 36 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $A0                           ; A#4      len 1 = 6 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $22                           ; D-5      len 3 = 18 fr
        .byte $20                           ; D-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte $22                           ; D-5      len 3 = 18 fr
        .byte CMD_JUMP
        .word Loop_9693

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_96BF:
        .byte CMD_OCTAVE5
        .byte $05                           ; C-5      len 6 = 36 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $A0                           ; A#4      len 1 = 6 fr
        .byte CMD_RETURN

Sub_96CB:
        .byte CMD_OCTAVE4
        .byte $97                           ; A-4      len 8 = 48 fr
        .byte CMD_OCTAVE5
        .byte $50                           ; F-5      len 1 = 6 fr
        .byte $70                           ; G-5      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $90                           ; A-5      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $A0                           ; A#5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_RETURN

Snd02_Sq2:
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$05                ; volume -5
        .byte CMD_TRANSPOSE,$EF             ; -17 semitones
        .byte $C7                           ; rest     len 8 = 48 fr

Loop_96E1:
        .byte CMD_CALL
        .word Sub_9710
        .byte CMD_CALL
        .word Sub_971B
        .byte CMD_CALL
        .word Sub_9710
        .byte CMD_OCTAVE4
        .byte $57                           ; F-4      len 8 = 48 fr
        .byte CMD_OCTAVE5
        .byte $02                           ; C-5      len 3 = 18 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_CALL
        .word Sub_9710
        .byte CMD_CALL
        .word Sub_971B
        .byte CMD_OCTAVE4
        .byte $95                           ; A-4      len 6 = 36 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $50                           ; F-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $A2                           ; A#4      len 3 = 18 fr
        .byte $A0                           ; A#4      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $A1                           ; A#4      len 2 = 12 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $A1                           ; A#4      len 2 = 12 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $A2                           ; A#4      len 3 = 18 fr
        .byte CMD_JUMP
        .word Loop_96E1

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9710:
        .byte CMD_OCTAVE4
        .byte $95                           ; A-4      len 6 = 36 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte $50                           ; F-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $30                           ; D#4      len 1 = 6 fr
        .byte $50                           ; F-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte CMD_RETURN

Sub_971B:
        .byte CMD_OCTAVE4
        .byte $57                           ; F-4      len 8 = 48 fr
        .byte CMD_OCTAVE5
        .byte $57                           ; F-5      len 8 = 48 fr
        .byte CMD_RETURN

Snd02_Tri:
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$05                ; volume -5
        .byte CMD_TRANSPOSE,$07             ; +7 semitones
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $20                           ; D-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $42                           ; E-3      len 3 = 18 fr

Loop_9731:
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_9759
        .byte CMD_CALL
        .word Sub_9769
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $51                           ; F-3      len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $A2                           ; A#2      len 3 = 18 fr
        .byte $A0                           ; A#2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $A1                           ; A#2      len 2 = 12 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A1                           ; A#3      len 2 = 12 fr
        .byte CMD_OCTAVE2
        .byte $A0                           ; A#2      len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $A2                           ; A#3      len 3 = 18 fr
        .byte CMD_JUMP
        .word Loop_9731

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9759:
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $72                           ; G-3      len 3 = 18 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_RETURN

Sub_9769:
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte CMD_TIE
        .byte $33                           ; D#3      len 4 = 24 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_RETURN

Snd02_Noise:
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$03                ; volume -3
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $21                           ; drum 2   len 2 = 12 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $21                           ; drum 2   len 2 = 12 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr

Loop_9784:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_9795
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_979B
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_9784

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9795:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $03                           ; drum 0   len 4 = 24 fr
        .byte $23                           ; drum 2   len 4 = 24 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_979B:
        .byte $03                           ; drum 0   len 4 = 24 fr
        .byte $23                           ; drum 2   len 4 = 24 fr
        .byte $03                           ; drum 0   len 4 = 24 fr
        .byte $21                           ; drum 2   len 2 = 12 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte CMD_RETURN

;======================================================================
; Sound $03 (music)
;======================================================================
Sound_03:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd03_Sq1
        .word Snd03_Sq2
        .word Snd03_Tri
        .word Snd03_Noise

Snd03_Sq1:
        .byte CMD_ENVELOPE,$07              ; volume envelope $07 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones

Loop_97B5:
        .byte CMD_CALL
        .word Sub_9804
        .byte CMD_CALL
        .word Sub_9811
        .byte CMD_CALL
        .word Sub_9804
        .byte CMD_OCTAVE4
        .byte $52                           ; F-4      len 3 = 21 fr
        .byte $92                           ; A-4      len 3 = 21 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $B2                           ; B-4      len 3 = 21 fr
        .byte $92                           ; A-4      len 3 = 21 fr
        .byte $81                           ; G#4      len 2 = 14 fr
        .byte CMD_CALL
        .word Sub_9804
        .byte CMD_CALL
        .word Sub_9811
        .byte CMD_CALL
        .word Sub_9804
        .byte $52                           ; F-4      len 3 = 21 fr
        .byte $92                           ; A-4      len 3 = 21 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $B2                           ; B-4      len 3 = 21 fr
        .byte CMD_OCTAVE5
        .byte $02                           ; C-5      len 3 = 21 fr
        .byte $21                           ; D-5      len 2 = 14 fr
        .byte CMD_CALL
        .word Sub_981A
        .byte CMD_CALL
        .word Sub_9823
        .byte CMD_CALL
        .word Sub_982D
        .byte CMD_OCTAVE5
        .byte $58                           ; F-5      len 9 = 63 fr
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 7 fr
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $90                           ; A-4      len 1 = 7 fr
        .byte $A0                           ; A#4      len 1 = 7 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 14 fr
        .byte $20                           ; D-5      len 1 = 7 fr
        .byte CMD_CALL
        .word Sub_981A
        .byte CMD_CALL
        .word Sub_9823
        .byte CMD_CALL
        .word Sub_982D
        .byte CMD_OCTAVE5
        .byte $78                           ; G-5      len 9 = 63 fr
        .byte $70                           ; G-5      len 1 = 7 fr
        .byte $50                           ; F-5      len 1 = 7 fr
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte $20                           ; D-5      len 1 = 7 fr
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 7 fr
        .byte $90                           ; A-4      len 1 = 7 fr
        .byte CMD_JUMP
        .word Loop_97B5

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9804:
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $40                           ; E-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $40                           ; E-4      len 1 = 7 fr
        .byte $B0                           ; B-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $94                           ; A-4      len 5 = 35 fr
        .byte $71                           ; G-4      len 2 = 14 fr
        .byte CMD_RETURN

Sub_9811:
        .byte CMD_OCTAVE4
        .byte $52                           ; F-4      len 3 = 21 fr
        .byte $92                           ; A-4      len 3 = 21 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 14 fr
        .byte $42                           ; E-5      len 3 = 21 fr
        .byte $22                           ; D-5      len 3 = 21 fr
        .byte $C1                           ; rest     len 2 = 14 fr
        .byte CMD_RETURN

Sub_981A:
        .byte CMD_OCTAVE5
        .byte $3B                           ; D#5      len 12 = 84 fr
        .byte $20                           ; D-5      len 1 = 7 fr
        .byte $30                           ; D#5      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 7 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_9823:
        .byte CMD_OCTAVE4
        .byte $A1                           ; A#4      len 2 = 14 fr
        .byte $71                           ; G-4      len 2 = 14 fr
        .byte $A1                           ; A#4      len 2 = 14 fr
        .byte CMD_OCTAVE5
        .byte $31                           ; D#5      len 2 = 14 fr
        .byte $72                           ; G-5      len 3 = 21 fr
        .byte $52                           ; F-5      len 3 = 21 fr
        .byte $31                           ; D#5      len 2 = 14 fr
        .byte CMD_RETURN

Sub_982D:
        .byte CMD_OCTAVE5
        .byte $52                           ; F-5      len 3 = 21 fr
        .byte $02                           ; C-5      len 3 = 21 fr
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 14 fr
        .byte CMD_OCTAVE5
        .byte $52                           ; F-5      len 3 = 21 fr
        .byte $02                           ; C-5      len 3 = 21 fr
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 14 fr
        .byte CMD_RETURN

Snd03_Sq2:
        .byte CMD_ENVELOPE,$07              ; volume envelope $07 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C1                           ; rest     len 2 = 14 fr
        .byte CMD_JUMP
        .word Loop_97B5

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Snd03_Tri:
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_VOLUME,$06                ; volume -6

Loop_9850:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_9890
        .byte CMD_CALL
        .word Sub_989D
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9890
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$FD         ; transpose -3 more
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9890
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$FB         ; transpose -5 more
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9890
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$FD         ; transpose -3 more
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_CALL
        .word Sub_9890
        .byte CMD_TRANSPOSE_ADD,$FB         ; transpose -5 more
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 7 fr
        .byte $71                           ; G-4      len 2 = 14 fr
        .byte $20                           ; D-4      len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 7 fr
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_9850

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9890:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 14 fr
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 14 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte $00                           ; C-3      len 1 = 7 fr
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_989D:
        .byte CMD_OCTAVE3
        .byte $51                           ; F-3      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte $51                           ; F-4      len 2 = 14 fr
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 7 fr
        .byte $71                           ; G-4      len 2 = 14 fr
        .byte $20                           ; D-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte CMD_RETURN

Snd03_Noise:
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_VOLUME,$03                ; volume -3

Loop_98B5:
        .byte $02                           ; drum 0   len 3 = 21 fr
        .byte $00                           ; drum 0   len 1 = 7 fr
        .byte $23                           ; drum 2   len 4 = 28 fr
        .byte $00                           ; drum 0   len 1 = 7 fr
        .byte $01                           ; drum 0   len 2 = 14 fr
        .byte $00                           ; drum 0   len 1 = 7 fr
        .byte $21                           ; drum 2   len 2 = 14 fr
        .byte $01                           ; drum 0   len 2 = 14 fr
        .byte CMD_JUMP
        .word Loop_98B5

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;======================================================================
; Sound $04 (music)
;======================================================================
Sound_04:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd04_Sq1
        .word Snd04_Sq2
        .word Snd04_Tri
        .word Snd04_Noise

Snd04_Sq1:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_DETUNE,$FF                ; period -1
        .byte CMD_VOLUME,$04                ; volume -4

Loop_98D5:
        .byte CMD_TRANSPOSE,$FB             ; -5 semitones
        .byte $CF                           ; rest     len 16 = 64 fr
        .byte $CD                           ; rest     len 14 = 56 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte CMD_CALL
        .word Sub_996E
        .byte $CD                           ; rest     len 14 = 56 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte CMD_CALL
        .word Sub_996E
        .byte CMD_OCTAVE3
        .byte $C9                           ; rest     len 10 = 40 fr
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte CMD_OCTAVE4
        .byte $27                           ; D-4      len 8 = 32 fr
        .byte $C7                           ; rest     len 8 = 32 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $43                           ; E-4      len 4 = 16 fr
        .byte $43                           ; E-4      len 4 = 16 fr
        .byte $07                           ; C-4      len 8 = 32 fr
        .byte $C7                           ; rest     len 8 = 32 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte CMD_OCTAVE4
        .byte $22                           ; D-4      len 3 = 12 fr
        .byte $C4                           ; rest     len 5 = 20 fr
        .byte $C7                           ; rest     len 8 = 32 fr
        .byte $C7                           ; rest     len 8 = 32 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $CD                           ; rest     len 14 = 56 fr
        .byte $CF                           ; rest     len 16 = 64 fr
        .byte $37                           ; D#4      len 8 = 32 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $30                           ; D#4      len 1 = 4 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $53                           ; F-4      len 4 = 16 fr
        .byte $33                           ; D#4      len 4 = 16 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $33                           ; D#4      len 4 = 16 fr
        .byte $23                           ; D-4      len 4 = 16 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $23                           ; D-4      len 4 = 16 fr
        .byte $03                           ; C-4      len 4 = 16 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $33                           ; D#4      len 4 = 16 fr
        .byte $22                           ; D-4      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte $53                           ; F-4      len 4 = 16 fr
        .byte $33                           ; D#4      len 4 = 16 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $33                           ; D#4      len 4 = 16 fr
        .byte $23                           ; D-4      len 4 = 16 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#4      len 2 = 8 fr
        .byte $23                           ; D-4      len 4 = 16 fr
        .byte $03                           ; C-4      len 4 = 16 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C5                           ; rest     len 6 = 24 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $11                           ; C#4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $71                           ; G-4      len 2 = 8 fr
        .byte CMD_TIE
        .byte $7C                           ; G-4      len 13 = 52 fr
        .byte $C2                           ; rest     len 3 = 12 fr
        .byte CMD_JUMP
        .word Loop_98D5

Sub_996E:
        .byte CMD_OCTAVE4
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $CD                           ; rest     len 14 = 56 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $51                           ; F-4      len 2 = 8 fr
        .byte $41                           ; E-4      len 2 = 8 fr
        .byte $21                           ; D-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $01                           ; C-4      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 8 fr
        .byte CMD_RETURN

Snd04_Sq2:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_DETUNE,$01                ; period +1
        .byte CMD_VOLUME,$0B                ; volume -11
        .byte $C3                           ; rest     len 4 = 16 fr
        .byte CMD_JUMP
        .word Loop_98D5

Snd04_Tri:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_TRANSPOSE,$13             ; +19 semitones
        .byte CMD_VOLUME,$02                ; volume -2

Loop_999D:
        .byte CMD_LOOP,$05                  ; repeat 5x
        .byte CMD_CALL
        .word Sub_9A1A
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $A1                           ; A#2      len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $51                           ; F-2      len 2 = 8 fr
        .byte $71                           ; G-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $A1                           ; A#2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $83                           ; G#2      len 4 = 16 fr
        .byte $52                           ; F-2      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-2      len 2 = 8 fr
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $51                           ; F-2      len 2 = 8 fr
        .byte $71                           ; G-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $71                           ; G-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $53                           ; F-2      len 4 = 16 fr
        .byte $02                           ; C-2      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9A33
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $11                           ; C#2      len 2 = 8 fr
        .byte $31                           ; D#2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $13                           ; C#2      len 4 = 16 fr
        .byte $32                           ; D#2      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_CALL
        .word Sub_9A33
        .byte CMD_CALL
        .word Sub_9A4B
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_9A4B
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte $A1                           ; A#1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte $A3                           ; A#1      len 4 = 16 fr
        .byte CMD_OCTAVE2
        .byte $02                           ; C-2      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_9A4B
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte CMD_CALL
        .word Sub_9A4B
        .byte CMD_CALL
        .word Sub_9A1A
        .byte CMD_JUMP
        .word Loop_999D

Sub_9A1A:
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $03                           ; C-2      len 4 = 16 fr
        .byte CMD_OCTAVE1
        .byte $52                           ; F-1      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_RETURN

Sub_9A33:
        .byte CMD_OCTAVE1
        .byte $21                           ; D-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $91                           ; A-1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 8 fr
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $21                           ; D-1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $91                           ; A-1      len 2 = 8 fr
        .byte CMD_OCTAVE2
        .byte $03                           ; C-2      len 4 = 16 fr
        .byte $22                           ; D-2      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_RETURN

Sub_9A4B:
        .byte CMD_OCTAVE0
        .byte $81                           ; G#0      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $81                           ; G#1      len 2 = 8 fr
        .byte $31                           ; D#1      len 2 = 8 fr
        .byte $61                           ; F#1      len 2 = 8 fr
        .byte $81                           ; G#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE0
        .byte $81                           ; G#0      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte CMD_OCTAVE1
        .byte $81                           ; G#1      len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $31                           ; D#1      len 2 = 8 fr
        .byte $63                           ; F#1      len 4 = 16 fr
        .byte $82                           ; G#1      len 3 = 12 fr
        .byte $C0                           ; rest     len 1 = 4 fr
        .byte CMD_RETURN

Snd04_Noise:
        .byte CMD_SPEED,$04                 ; note length x4
        .byte CMD_VOLUME,$02                ; volume -2

Loop_9A63:
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte CMD_CALL
        .word Sub_9A7D
        .byte CMD_LOOP_END
        .byte $05                           ; drum 0   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $25                           ; drum 2   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $03                           ; drum 0   len 4 = 16 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte CMD_LOOP,$08                  ; repeat 8x
        .byte CMD_CALL
        .word Sub_9A87
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_9A63

Sub_9A7D:
        .byte $05                           ; drum 0   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $25                           ; drum 2   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $03                           ; drum 0   len 4 = 16 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $23                           ; drum 2   len 4 = 16 fr
        .byte $23                           ; drum 2   len 4 = 16 fr
        .byte CMD_RETURN

Sub_9A87:
        .byte $05                           ; drum 0   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $25                           ; drum 2   len 6 = 24 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $C1                           ; rest     len 2 = 8 fr
        .byte $03                           ; drum 0   len 4 = 16 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte $21                           ; drum 2   len 2 = 8 fr
        .byte $01                           ; drum 0   len 2 = 8 fr
        .byte CMD_RETURN

;======================================================================
; Sound $05 (music)
;======================================================================
Sound_05:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd05_Sq1
        .word Snd05_Sq2
        .word Snd05_Tri
        .word Snd05_Noise

Snd05_Sq1:
        .byte CMD_ENVELOPE,$0A              ; volume envelope $0A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$ED             ; -19 semitones

Loop_9AA6:
        .byte CMD_CALL
        .word Sub_9AE4
        .byte CMD_CALL
        .word Sub_9AFA
        .byte CMD_CALL
        .word Sub_9AE4
        .byte CMD_CALL
        .word Sub_9AFA
        .byte CMD_CALL
        .word Sub_9B0A
        .byte CMD_CALL
        .word Sub_9B24
        .byte CMD_CALL
        .word Sub_9B0A
        .byte CMD_CALL
        .word Sub_9B24
        .byte CMD_CALL
        .word Sub_9B34
        .byte CMD_CALL
        .word Sub_9B34
        .byte CMD_CALL
        .word Sub_9B5D
        .byte CMD_CALL
        .word Sub_9B5D
        .byte CMD_CALL
        .word Sub_9B87
        .byte CMD_CALL
        .word Sub_9B87
        .byte CMD_OCTAVE4
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte CMD_JUMP
        .word Loop_9AA6

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9AE4:
        .byte CMD_OCTAVE4
        .byte $2B                           ; D-4      len 12 = 96 fr
        .byte CMD_TIE
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $00                           ; C-4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte CMD_TIE
        .byte $37                           ; D#4      len 8 = 64 fr
        .byte CMD_TIE
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte $60                           ; F#4      len 1 = 8 fr
        .byte $30                           ; D#4      len 1 = 8 fr
        .byte $00                           ; C-4      len 1 = 8 fr
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte CMD_TIE
        .byte $2F                           ; D-4      len 16 = 128 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_9AFA:
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $71                           ; G-5      len 2 = 16 fr
        .byte $60                           ; F#5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $01                           ; C-5      len 2 = 16 fr
        .byte $00                           ; C-5      len 1 = 8 fr
        .byte $21                           ; D-5      len 2 = 16 fr
        .byte CMD_RETURN

Sub_9B0A:
        .byte CMD_OCTAVE4
        .byte $9B                           ; A-4      len 12 = 96 fr
        .byte CMD_TIE
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte CMD_TIE
        .byte $A7                           ; A#4      len 8 = 64 fr
        .byte CMD_TIE
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_TIE
        .byte $9F                           ; A-4      len 16 = 128 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_9B24:
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $71                           ; G-5      len 2 = 16 fr
        .byte $60                           ; F#5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $01                           ; C-5      len 2 = 16 fr
        .byte $00                           ; C-5      len 1 = 8 fr
        .byte $21                           ; D-5      len 2 = 16 fr
        .byte CMD_RETURN

Sub_9B34:
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 16 fr
        .byte $10                           ; C#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_RETURN

Sub_9B5D:
        .byte CMD_OCTAVE5
        .byte $80                           ; G#5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $00                           ; C-5      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $00                           ; C-5      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $80                           ; G#5      len 1 = 8 fr
        .byte $90                           ; A-5      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $90                           ; A-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $00                           ; C-5      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $31                           ; D#5      len 2 = 16 fr
        .byte CMD_RETURN

Sub_9B87:
        .byte CMD_OCTAVE4
        .byte $25                           ; D-4      len 6 = 48 fr
        .byte $37                           ; D#4      len 8 = 64 fr
        .byte CMD_OCTAVE5
        .byte $25                           ; D-5      len 6 = 48 fr
        .byte $07                           ; C-5      len 8 = 64 fr
        .byte CMD_RETURN

Snd05_Sq2:
        .byte CMD_ENVELOPE,$0A              ; volume envelope $0A (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_VOLUME,$01                ; volume -1
        .byte CMD_TRANSPOSE,$ED             ; -19 semitones

Loop_9B98:
        .byte CMD_CALL
        .word Sub_9B0A
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_DETUNE,$03                ; period +3
        .byte CMD_CALL
        .word Sub_9B24
        .byte CMD_DETUNE,$00                ; period +0
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_CALL
        .word Sub_9B0A
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_DETUNE,$03                ; period +3
        .byte CMD_CALL
        .word Sub_9B24
        .byte CMD_DETUNE,$00                ; period +0
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_TRANSPOSE_ADD,$0C         ; transpose +12 more
        .byte CMD_CALL
        .word Sub_9AE4
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_DETUNE,$03                ; period +3
        .byte CMD_TRANSPOSE_ADD,$F4         ; transpose -12 more
        .byte CMD_CALL
        .word Sub_9AFA
        .byte CMD_TRANSPOSE_ADD,$0C         ; transpose +12 more
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_DETUNE,$00                ; period +0
        .byte CMD_CALL
        .word Sub_9AE4
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_DETUNE,$03                ; period +3
        .byte CMD_TRANSPOSE_ADD,$F4         ; transpose -12 more
        .byte CMD_CALL
        .word Sub_9AFA
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_DETUNE,$00                ; period +0
        .byte CMD_VOLUME_ADD,$03            ; volume attenuation +3
        .byte CMD_CALL
        .word Sub_9C04
        .byte CMD_CALL
        .word Sub_9C04
        .byte CMD_CALL
        .word Sub_9C2E
        .byte CMD_CALL
        .word Sub_9C2E
        .byte CMD_CALL
        .word Sub_9C2E
        .byte CMD_CALL
        .word Sub_9C2E
        .byte CMD_VOLUME_ADD,$FD            ; volume attenuation -3
        .byte CMD_CALL
        .word Sub_9C44
        .byte CMD_CALL
        .word Sub_9C44
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $30                           ; D#3      len 1 = 8 fr
        .byte $30                           ; D#3      len 1 = 8 fr
        .byte CMD_JUMP
        .word Loop_9B98

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9C04:
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $20                           ; D-5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 8 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $A0                           ; A#5      len 1 = 8 fr
        .byte $70                           ; G-5      len 1 = 8 fr
        .byte $30                           ; D#5      len 1 = 8 fr
        .byte CMD_RETURN

Sub_9C2E:
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte $A0                           ; A#3      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $10                           ; C#4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte $A0                           ; A#3      len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $10                           ; C#4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte CMD_RETURN

Sub_9C44:
        .byte CMD_OCTAVE3
        .byte $95                           ; A-3      len 6 = 48 fr
        .byte $A7                           ; A#3      len 8 = 64 fr
        .byte CMD_OCTAVE4
        .byte $95                           ; A-4      len 6 = 48 fr
        .byte $77                           ; G-4      len 8 = 64 fr
        .byte CMD_RETURN

Snd05_Tri:
        .byte CMD_ENVELOPE,$08              ; volume envelope $08 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_VOLUME,$00                ; volume -0

Loop_9C53:
        .byte CMD_TRANSPOSE,$F9             ; -7 semitones
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_CALL
        .word Sub_9CE7
        .byte CMD_CALL
        .word Sub_9CCE
        .byte CMD_OCTAVE3
        .byte $21                           ; D-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE2
        .byte $9D                           ; A-2      len 14 = 14 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_SPEED,$08                 ; note length x8
        .byte $90                           ; A-2      len 1 = 8 fr
        .byte CMD_TRANSPOSE,$05             ; +5 semitones
        .byte CMD_CALL
        .word Sub_9CF8
        .byte CMD_CALL
        .word Sub_9CF8
        .byte CMD_CALL
        .word Sub_9D1D
        .byte CMD_CALL
        .word Sub_9D1D
        .byte CMD_CALL
        .word Sub_9D1D
        .byte CMD_CALL
        .word Sub_9D1D
        .byte CMD_ENVELOPE,$18              ; volume envelope $18 (starts with the next note)
        .byte CMD_CALL
        .word Sub_9D2B
        .byte CMD_CALL
        .word Sub_9D2B
        .byte CMD_CALL
        .word Sub_9D2B
        .byte CMD_CALL
        .word Sub_9D2B
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_OCTAVE2
        .byte $81                           ; G#2      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $81                           ; G#2      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $81                           ; G#2      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $81                           ; G#2      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $80                           ; G#2      len 1 = 8 fr
        .byte $80                           ; G#2      len 1 = 8 fr
        .byte CMD_JUMP
        .word Loop_9C53

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9CCE:
        .byte CMD_OCTAVE3
        .byte $21                           ; D-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $90                           ; A-3      len 1 = 8 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE2
        .byte $9D                           ; A-2      len 14 = 14 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_SPEED,$08                 ; note length x8
        .byte $90                           ; A-2      len 1 = 8 fr
        .byte CMD_RETURN

Sub_9CE7:
        .byte CMD_OCTAVE3
        .byte $21                           ; D-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte $93                           ; A-3      len 4 = 32 fr
        .byte CMD_RETURN

Sub_9CF8:
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 8 fr
        .byte CMD_OCTAVE2
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $30                           ; D#3      len 1 = 8 fr
        .byte CMD_OCTAVE2
        .byte $30                           ; D#2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $30                           ; D#2      len 1 = 8 fr
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte CMD_RETURN

Sub_9D1D:
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 8 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $22                           ; D-3      len 3 = 24 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $21                           ; D-3      len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $31                           ; D#3      len 2 = 16 fr
        .byte $20                           ; D-3      len 1 = 8 fr
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_RETURN

Sub_9D2B:
        .byte CMD_OCTAVE2
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_RETURN

Snd05_Noise:
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_VOLUME,$00                ; volume -0

Loop_9D3F:
        .byte CMD_LOOP,$30                  ; repeat 48x
        .byte $03                           ; drum 0   len 4 = 32 fr
        .byte $23                           ; drum 2   len 4 = 32 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $05                           ; drum 0   len 6 = 48 fr
        .byte $25                           ; drum 2   len 6 = 48 fr
        .byte $21                           ; drum 2   len 2 = 16 fr
        .byte CMD_LOOP_END
        .byte $22                           ; drum 2   len 3 = 24 fr
        .byte $22                           ; drum 2   len 3 = 24 fr
        .byte $22                           ; drum 2   len 3 = 24 fr
        .byte $22                           ; drum 2   len 3 = 24 fr
        .byte $21                           ; drum 2   len 2 = 16 fr
        .byte CMD_JUMP
        .word Loop_9D3F

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;======================================================================
; Sound $06 (music)
;======================================================================
Sound_06:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd06_Sq1
        .word Snd06_Sq2
        .word Snd06_Tri
        .word Snd06_Noise

Snd06_Sq1:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$02                ; volume -2
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr

Loop_9D69:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_9DD4
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $13                           ; C#5      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $A1                           ; A#4      len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9DDB
        .byte CMD_CALL
        .word Sub_9DD4
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $13                           ; C#5      len 4 = 20 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $A1                           ; A#4      len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9DDB
        .byte CMD_OCTAVE5
        .byte $13                           ; C#5      len 4 = 20 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $63                           ; F#5      len 4 = 20 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $90                           ; A-5      len 1 = 5 fr
        .byte $71                           ; G-5      len 2 = 10 fr
        .byte $23                           ; D-5      len 4 = 20 fr
        .byte $63                           ; F#5      len 4 = 20 fr
        .byte $43                           ; E-5      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte CMD_OCTAVE5
        .byte $43                           ; E-5      len 4 = 20 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $67                           ; F#5      len 8 = 40 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9DE1
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9DE1
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $65                           ; F#5      len 6 = 30 fr
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE4
        .byte CMD_CALL
        .word Sub_9DEA
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9DEA
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_JUMP
        .word Loop_9D69

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9DD4:
        .byte CMD_OCTAVE4
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte CMD_OCTAVE5
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $43                           ; E-5      len 4 = 20 fr
        .byte CMD_RETURN

Sub_9DDB:
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $B7                           ; B-4      len 8 = 40 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_9DE1:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $11                           ; C#5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte CMD_RETURN

Sub_9DEA:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $11                           ; C#4      len 2 = 10 fr
        .byte $11                           ; C#4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $11                           ; C#4      len 2 = 10 fr
        .byte $11                           ; C#4      len 2 = 10 fr
        .byte CMD_RETURN

Snd06_Sq2:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_CALL
        .word Sub_9E2E

Loop_9DFC:
        .byte CMD_VOLUME,$01                ; volume -1
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_9E2E
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $23                           ; D-4      len 4 = 20 fr
        .byte $63                           ; F#4      len 4 = 20 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $23                           ; D-4      len 4 = 20 fr
        .byte $43                           ; E-4      len 4 = 20 fr
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9E32
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$04                ; volume -4
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9E37
        .byte CMD_CALL
        .word Sub_9EA4
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9E37
        .byte CMD_CALL
        .word Sub_9EA4
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_9DFC

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9E2E:
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $03                           ; C-4      len 4 = 20 fr
        .byte $13                           ; C#4      len 4 = 20 fr

Sub_9E32:
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $03                           ; C-4      len 4 = 20 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_RETURN

Sub_9E37:
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte CMD_RETURN

Snd06_Tri:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_CALL
        .word Sub_9E81
        .byte CMD_CALL
        .word Sub_9E87

Loop_9E4C:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_9E81
        .byte CMD_CALL
        .word Sub_9E87
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_OCTAVE3
        .byte $93                           ; A-3      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $63                           ; F#4      len 4 = 20 fr
        .byte $93                           ; A-4      len 4 = 20 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_OCTAVE3
        .byte $93                           ; A-3      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $63                           ; F#4      len 4 = 20 fr
        .byte $73                           ; G-4      len 4 = 20 fr
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9E87
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_9E8F
        .byte CMD_CALL
        .word Sub_9EA4
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_9E8F
        .byte CMD_CALL
        .word Sub_9EA4
        .byte CMD_CALL
        .word Sub_9E98
        .byte CMD_JUMP
        .word Loop_9E4C

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9E81:
        .byte CMD_OCTAVE3
        .byte $73                           ; G-3      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $43                           ; E-4      len 4 = 20 fr
        .byte $53                           ; F-4      len 4 = 20 fr
        .byte CMD_RETURN

Sub_9E87:
        .byte CMD_OCTAVE3
        .byte $73                           ; G-3      len 4 = 20 fr
        .byte CMD_OCTAVE4
        .byte $43                           ; E-4      len 4 = 20 fr
        .byte CMD_CALL
        .word Sub_9E98
        .byte CMD_RETURN

Sub_9E8F:
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte CMD_RETURN

Sub_9E98:
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE6
        .byte $30                           ; D#6      len 1 = 1 fr
        .byte CMD_OCTAVE_DOWN
        .byte $40                           ; E-5      len 1 = 1 fr
        .byte $B0                           ; B-5      len 1 = 1 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_RETURN

Sub_9EA4:
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte CMD_RETURN

Snd06_Noise:
        .byte CMD_ENVELOPE,$00              ; volume envelope $00 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5

Loop_9EAF:
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$06            ; volume attenuation +6
        .byte CMD_LOOP,$05                  ; repeat 5x
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_VOLUME,$00                ; volume -0
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$0A            ; volume attenuation +10
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_VOLUME,$00                ; volume -0
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_9EAF

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;======================================================================
; Sound $07 (music)
;======================================================================
Sound_07:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd07_Sq1
        .word Snd07_Sq2
        .word Snd07_Tri
        .word Snd07_Noise

Snd07_Sq1:
        .byte CMD_VOLUME,$08                ; volume -8

Loop_9ED4:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones

Loop_9EDC:
        .byte CMD_CALL
        .word Sub_9F61
        .byte CMD_OCTAVE5
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $20                           ; D-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $45                           ; E-5      len 6 = 36 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_CALL
        .word Sub_9F61
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $20                           ; D-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $03                           ; C-5      len 4 = 24 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 6 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte $71                           ; G-4      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $22                           ; D-5      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 12 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 12 fr
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $13                           ; C#5      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $13                           ; C#5      len 4 = 4 fr
        .byte $C7                           ; rest     len 8 = 8 fr
        .byte $13                           ; C#5      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte $13                           ; C#5      len 4 = 4 fr
        .byte $C7                           ; rest     len 8 = 8 fr
        .byte CMD_SPEED,$06                 ; note length x6
        .byte $25                           ; D-5      len 6 = 36 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $90                           ; A-4      len 1 = 6 fr
        .byte CMD_OCTAVE5
        .byte $60                           ; F#5      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $42                           ; E-5      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $11                           ; C#5      len 2 = 12 fr
        .byte $21                           ; D-5      len 2 = 12 fr
        .byte $41                           ; E-5      len 2 = 12 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $43                           ; E-5      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $43                           ; E-5      len 4 = 4 fr
        .byte $C7                           ; rest     len 8 = 8 fr
        .byte $43                           ; E-5      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte $43                           ; E-5      len 4 = 4 fr
        .byte $C7                           ; rest     len 8 = 8 fr
        .byte CMD_SPEED,$06                 ; note length x6
        .byte $23                           ; D-5      len 4 = 24 fr
        .byte $C5                           ; rest     len 6 = 36 fr
        .byte CMD_CALL
        .word Sub_9F6B
        .byte CMD_OCTAVE5
        .byte $07                           ; C-5      len 8 = 48 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $41                           ; E-5      len 2 = 12 fr
        .byte $51                           ; F-5      len 2 = 12 fr
        .byte $71                           ; G-5      len 2 = 12 fr
        .byte CMD_CALL
        .word Sub_9F6B
        .byte $07                           ; C-5      len 8 = 48 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $A1                           ; A#4      len 2 = 12 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 12 fr
        .byte $41                           ; E-5      len 2 = 12 fr
        .byte $51                           ; F-5      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-5      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $52                           ; F-4      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-4      len 2 = 12 fr
        .byte $91                           ; A-4      len 2 = 12 fr
        .byte $A1                           ; A#4      len 2 = 12 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 12 fr
        .byte $53                           ; F-5      len 4 = 24 fr
        .byte $73                           ; G-5      len 4 = 24 fr
        .byte $51                           ; F-5      len 2 = 12 fr
        .byte $71                           ; G-5      len 2 = 12 fr
        .byte $A1                           ; A#5      len 2 = 12 fr
        .byte $93                           ; A-5      len 4 = 24 fr
        .byte $23                           ; D-5      len 4 = 24 fr
        .byte $43                           ; E-5      len 4 = 24 fr
        .byte $53                           ; F-5      len 4 = 24 fr
        .byte $71                           ; G-5      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $71                           ; G-5      len 2 = 12 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-5      len 1 = 6 fr
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte $20                           ; D-5      len 1 = 6 fr
        .byte CMD_JUMP
        .word Loop_9EDC

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9F61:
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $00                           ; C-5      len 1 = 6 fr
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $77                           ; G-5      len 8 = 48 fr
        .byte $50                           ; F-5      len 1 = 6 fr
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte CMD_RETURN

Sub_9F6B:
        .byte CMD_OCTAVE5
        .byte $47                           ; E-5      len 8 = 48 fr
        .byte $27                           ; D-5      len 8 = 48 fr
        .byte CMD_RETURN

Snd07_Sq2:
        .byte CMD_DETUNE,$FF                ; period -1
        .byte CMD_VOLUME,$0B                ; volume -11
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_JUMP
        .word Loop_9ED4

Snd07_Tri:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$06                 ; note length x6

Loop_9F7D:
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_9FE4
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 12 fr
        .byte $03                           ; C-4      len 4 = 24 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $B1                           ; B-3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 6 fr
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte CMD_CALL
        .word Sub_9FF2
        .byte CMD_CALL
        .word Sub_9FF2
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $95                           ; A-3      len 6 = 36 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $B0                           ; B-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $22                           ; D-4      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $B1                           ; B-3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $61                           ; F#3      len 2 = 12 fr
        .byte CMD_CALL
        .word Sub_A001
        .byte CMD_CALL
        .word Sub_A001
        .byte CMD_CALL
        .word Sub_A00F
        .byte CMD_CALL
        .word Sub_A00F
        .byte CMD_CALL
        .word Sub_A01C
        .byte CMD_CALL
        .word Sub_A01C
        .byte CMD_OCTAVE3
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $05                           ; C-4      len 6 = 36 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $B0                           ; B-3      len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $C5                           ; rest     len 6 = 36 fr
        .byte CMD_OCTAVE3
        .byte $B0                           ; B-3      len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte CMD_JUMP
        .word Loop_9F7D

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_9FE4:
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 12 fr
        .byte $02                           ; C-4      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $B1                           ; B-3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $21                           ; D-4      len 2 = 12 fr
        .byte CMD_RETURN

Sub_9FF2:
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $25                           ; D-4      len 6 = 36 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $B0                           ; B-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte CMD_RETURN

Sub_A001:
        .byte CMD_OCTAVE3
        .byte $51                           ; F-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $42                           ; E-4      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $B1                           ; B-3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte CMD_RETURN

Sub_A00F:
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $A1                           ; A#3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $42                           ; E-4      len 3 = 18 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $21                           ; D-4      len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A1                           ; A#3      len 2 = 12 fr
        .byte CMD_RETURN

Sub_A01C:
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $05                           ; C-4      len 6 = 36 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte CMD_RETURN

Snd07_Noise:
        .byte CMD_ENVELOPE,$00              ; volume envelope $00 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$02                ; volume -2

Loop_A033:
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $11                           ; drum 1   len 2 = 12 fr
        .byte CMD_JUMP
        .word Loop_A033

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;======================================================================
; Sound $08 (music)
;======================================================================
Sound_08:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd08_Sq1
        .word Snd08_Sq2
        .word Snd08_Tri
        .word Snd08_Noise

Snd08_Sq1:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$06                ; volume -6

Loop_A058:
        .byte CMD_CALL
        .word Sub_A0B6
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $11                           ; C#3      len 2 = 12 fr
        .byte $20                           ; D-3      len 1 = 6 fr
        .byte $C5                           ; rest     len 6 = 36 fr
        .byte CMD_CALL
        .word Sub_A0B6
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $00                           ; C-3      len 1 = 6 fr
        .byte $11                           ; C#3      len 2 = 12 fr
        .byte $20                           ; D-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $40                           ; E-3      len 1 = 6 fr
        .byte $51                           ; F-3      len 2 = 12 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_TIE
        .byte $A1                           ; A#3      len 2 = 12 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $91                           ; A-3      len 2 = 12 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $21                           ; D-3      len 2 = 12 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte CMD_TIE
        .byte $51                           ; F-3      len 2 = 12 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $21                           ; D-3      len 2 = 12 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_TIE
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $60                           ; F#3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $10                           ; C#4      len 1 = 6 fr
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 12 fr
        .byte $00                           ; C-4      len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $A1                           ; A#3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $20                           ; D-4      len 1 = 6 fr
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 6 fr
        .byte $71                           ; G-3      len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 12 fr
        .byte $C4                           ; rest     len 5 = 30 fr
        .byte CMD_JUMP
        .word Loop_A058

Sub_A0B6:
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $51                           ; F-3      len 2 = 12 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $81                           ; G#3      len 2 = 12 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte $81                           ; G#3      len 2 = 12 fr
        .byte $90                           ; A-3      len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $80                           ; G#3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $80                           ; G#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $43                           ; E-3      len 4 = 24 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 6 fr
        .byte $30                           ; D#3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $41                           ; E-3      len 2 = 12 fr
        .byte $C4                           ; rest     len 5 = 30 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $41                           ; E-3      len 2 = 12 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $61                           ; F#3      len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte $61                           ; F#3      len 2 = 12 fr
        .byte $70                           ; G-3      len 1 = 6 fr
        .byte CMD_OCTAVE3
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $50                           ; F-3      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $23                           ; D-3      len 4 = 24 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_RETURN

Snd08_Sq2:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_DETUNE,$01                ; period +1
        .byte CMD_VOLUME,$0A                ; volume -10
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_JUMP
        .word Loop_A058

Snd08_Tri:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_TRANSPOSE,$18             ; +24 semitones
        .byte CMD_VOLUME,$02                ; volume -2

Loop_A104:
        .byte CMD_CALL
        .word Sub_A129
        .byte CMD_OCTAVE1
        .byte $20                           ; D-1      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte CMD_CALL
        .word Sub_A129
        .byte CMD_OCTAVE1
        .byte $20                           ; D-1      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A16B
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_A104

Sub_A129:
        .byte CMD_OCTAVE1
        .byte $21                           ; D-1      len 2 = 12 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte $80                           ; G#1      len 1 = 6 fr
        .byte $91                           ; A-1      len 2 = 12 fr
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_OCTAVE1
        .byte $20                           ; D-1      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $40                           ; E-1      len 1 = 6 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $A0                           ; A#1      len 1 = 6 fr
        .byte $B1                           ; B-1      len 2 = 12 fr
        .byte CMD_OCTAVE2
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_OCTAVE1
        .byte $40                           ; E-1      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $31                           ; D#2      len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $31                           ; D#2      len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $40                           ; E-1      len 1 = 6 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $A0                           ; A#1      len 1 = 6 fr
        .byte $B1                           ; B-1      len 2 = 12 fr
        .byte CMD_OCTAVE2
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_OCTAVE1
        .byte $40                           ; E-1      len 1 = 6 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $31                           ; D#2      len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte $31                           ; D#2      len 2 = 12 fr
        .byte $40                           ; E-2      len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $20                           ; D-1      len 1 = 6 fr
        .byte $C3                           ; rest     len 4 = 24 fr
        .byte $80                           ; G#1      len 1 = 6 fr
        .byte $91                           ; A-1      len 2 = 12 fr
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 6 fr
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_RETURN

Sub_A16B:
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $A1                           ; A#1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $01                           ; C-2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $A1                           ; A#1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $71                           ; G-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $21                           ; D-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $51                           ; F-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $91                           ; A-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE2
        .byte $21                           ; D-2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $11                           ; C#2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte $01                           ; C-2      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_OCTAVE1
        .byte $91                           ; A-1      len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_RETURN

Snd08_Noise:
        .byte CMD_VOLUME,$02                ; volume -2
        .byte CMD_SPEED,$06                 ; note length x6

Loop_A198:
        .byte CMD_LOOP,$07                  ; repeat 7x
        .byte CMD_CALL
        .word Sub_A1C4
        .byte CMD_LOOP_END
        .byte $04                           ; drum 0   len 5 = 30 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $24                           ; drum 2   len 5 = 30 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $02                           ; drum 0   len 3 = 18 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $21                           ; drum 2   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $11                           ; drum 1   len 2 = 12 fr
        .byte $C0                           ; rest     len 1 = 6 fr
        .byte CMD_CALL
        .word Sub_A1CF
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte CMD_CALL
        .word Sub_A1CF
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte CMD_JUMP
        .word Loop_A198

Sub_A1C4:
        .byte $04                           ; drum 0   len 5 = 30 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $24                           ; drum 2   len 5 = 30 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $02                           ; drum 0   len 3 = 18 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $21                           ; drum 2   len 2 = 12 fr
        .byte $00                           ; drum 0   len 1 = 6 fr
        .byte $22                           ; drum 2   len 3 = 18 fr
        .byte CMD_RETURN

Sub_A1CF:
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $20                           ; drum 2   len 1 = 6 fr
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte $12                           ; drum 1   len 3 = 18 fr
        .byte $31                           ; drum 3   len 2 = 12 fr
        .byte $30                           ; drum 3   len 1 = 6 fr
        .byte CMD_RETURN

;======================================================================
; Sound $09 (music)
;======================================================================
Sound_09:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd09_Sq1
        .word Snd09_Sq2
        .word Snd09_Tri
        .word Snd09_Noise

Snd09_Sq1:
        .byte CMD_ENVELOPE,$07              ; volume envelope $07 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$05                ; volume -5
        .byte CMD_TRANSPOSE,$F2             ; -14 semitones
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A1FB:
        .byte CMD_CALL
        .word Sub_A483
        .byte CMD_CALL
        .word Sub_A48B
        .byte CMD_CALL
        .word Sub_A483
        .byte CMD_CALL
        .word Sub_A48B
        .byte CMD_CALL
        .word Sub_A483
        .byte CMD_CALL
        .word Sub_A48B
        .byte CMD_CALL
        .word Sub_A483
        .byte CMD_CALL
        .word Sub_A48B
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_CALL
        .word Sub_A2B9
        .byte CMD_CALL
        .word Sub_A2B9
        .byte CMD_CALL
        .word Sub_A2C2
        .byte CMD_OCTAVE4
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $80                           ; G#4      len 1 = 1 fr
        .byte $98                           ; A-4      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $92                           ; A-4      len 3 = 15 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_A2B9
        .byte CMD_CALL
        .word Sub_A2B9
        .byte CMD_CALL
        .word Sub_A2C2
        .byte CMD_OCTAVE5
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $10                           ; C#5      len 1 = 1 fr
        .byte $28                           ; D-5      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $A2                           ; A#4      len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_A2CE
        .byte CMD_CALL
        .word Sub_A2DA
        .byte CMD_CALL
        .word Sub_A2E3
        .byte CMD_CALL
        .word Sub_A2EC
        .byte CMD_CALL
        .word Sub_A2CE
        .byte CMD_CALL
        .word Sub_A2DA
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_A2CE
        .byte CMD_CALL
        .word Sub_A2DA
        .byte CMD_CALL
        .word Sub_A2E3
        .byte CMD_CALL
        .word Sub_A2EC
        .byte CMD_CALL
        .word Sub_A2CE
        .byte CMD_CALL
        .word Sub_A2DA
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $72                           ; G-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_ENVELOPE,$07              ; volume envelope $07 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$05                ; volume -5
        .byte CMD_JUMP
        .word Loop_A1FB

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_A29A:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $30                           ; D#4      len 1 = 1 fr
        .byte $48                           ; E-4      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_A2AD:
        .byte CMD_OCTAVE4
        .byte $62                           ; F#4      len 3 = 15 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C5                           ; rest     len 6 = 30 fr
        .byte CMD_RETURN

Sub_A2B3:
        .byte CMD_OCTAVE4
        .byte $67                           ; F#4      len 8 = 40 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A2B9:
        .byte CMD_OCTAVE4
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $A2                           ; A#4      len 3 = 15 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A2C2:
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_A2CE:
        .byte CMD_OCTAVE5
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $30                           ; D#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_A2DA:
        .byte CMD_OCTAVE5
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_RETURN

Sub_A2E3:
        .byte CMD_OCTAVE5
        .byte $72                           ; G-5      len 3 = 15 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $71                           ; G-5      len 2 = 10 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte CMD_RETURN

Sub_A2EC:
        .byte CMD_OCTAVE5
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $60                           ; F#5      len 1 = 1 fr
        .byte $78                           ; G-5      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE6
        .byte $00                           ; C-6      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $72                           ; G-5      len 3 = 15 fr
        .byte $52                           ; F-5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_RETURN

Snd09_Sq2:
        .byte CMD_ENVELOPE,$09              ; volume envelope $09 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$06                ; volume -6
        .byte CMD_TRANSPOSE,$F2             ; -14 semitones
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A30A:
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A3BE
        .byte CMD_CALL
        .word Sub_A3CD
        .byte CMD_CALL
        .word Sub_A3D0
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A3BE
        .byte CMD_CALL
        .word Sub_A3CD
        .byte CMD_CALL
        .word Sub_A3D0
        .byte CMD_CALL
        .word Sub_A3D9
        .byte CMD_CALL
        .word Sub_A3D9
        .byte CMD_CALL
        .word Sub_A3E1
        .byte CMD_OCTAVE4
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $52                           ; F-4      len 3 = 15 fr
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_A3D9
        .byte CMD_CALL
        .word Sub_A3D9
        .byte CMD_CALL
        .word Sub_A3E1
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_OCTAVE5
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $30                           ; D#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $72                           ; G-5      len 3 = 15 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $71                           ; G-5      len 2 = 10 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $60                           ; F#5      len 1 = 1 fr
        .byte $78                           ; G-5      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE6
        .byte $00                           ; C-6      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $72                           ; G-5      len 3 = 15 fr
        .byte $52                           ; F-5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $30                           ; D#5      len 1 = 5 fr
        .byte CMD_TIE
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte CMD_VOLUME_ADD,$FF            ; volume attenuation -1
        .byte CMD_CALL
        .word Sub_A3EB
        .byte CMD_CALL
        .word Sub_A3F9
        .byte CMD_OCTAVE5
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $30                           ; D#5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $32                           ; D#5      len 3 = 15 fr
        .byte $22                           ; D-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_A3EB
        .byte CMD_CALL
        .word Sub_A3F9
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $32                           ; D#4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $A0                           ; A#3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte CMD_OCTAVE5
        .byte $22                           ; D-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte CMD_JUMP
        .word Loop_A30A

Sub_A3BE:
        .byte CMD_OCTAVE4
        .byte $62                           ; F#4      len 3 = 15 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $10                           ; C#4      len 1 = 1 fr
        .byte $28                           ; D-4      len 9 = 9 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_A3CD:
        .byte CMD_OCTAVE4
        .byte $0B                           ; C-4      len 12 = 60 fr
        .byte CMD_RETURN

Sub_A3D0:
        .byte CMD_OCTAVE3
        .byte $61                           ; F#3      len 2 = 10 fr
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A3D9:
        .byte CMD_OCTAVE4
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $22                           ; D-4      len 3 = 15 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A3E1:
        .byte CMD_OCTAVE4
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_A3EB:
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_TIE
        .byte CMD_RETURN

Sub_A3F9:
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_RETURN

Snd09_Tri:
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$03                ; volume -3
        .byte CMD_TRANSPOSE,$FE             ; -2 semitones
        .byte CMD_TRANSPOSE_ADD,$03         ; transpose +3 more
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A416:
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A2AD
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A2B3
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A2AD
        .byte CMD_CALL
        .word Sub_A29A
        .byte CMD_CALL
        .word Sub_A2B3
        .byte CMD_TRANSPOSE,$FE             ; -2 semitones
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte CMD_TRANSPOSE_ADD,$04         ; transpose +4 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$FC         ; transpose -4 more
        .byte CMD_CALL
        .word Sub_A49B
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE,$0A             ; +10 semitones
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_TRANSPOSE_ADD,$F9         ; transpose -7 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$07         ; transpose +7 more
        .byte CMD_TRANSPOSE_ADD,$FB         ; transpose -5 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_CALL
        .word Sub_A4A6
        .byte CMD_CALL
        .word Sub_A4B1
        .byte CMD_LOOP_END
        .byte CMD_TRANSPOSE_ADD,$F9         ; transpose -7 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$07         ; transpose +7 more
        .byte CMD_TRANSPOSE_ADD,$FB         ; transpose -5 more
        .byte CMD_CALL
        .word Sub_A494
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE2
        .byte $A1                           ; A#2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $A1                           ; A#2      len 2 = 10 fr
        .byte $80                           ; G#2      len 1 = 5 fr
        .byte $C4                           ; rest     len 5 = 25 fr
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $70                           ; G-2      len 1 = 5 fr
        .byte CMD_TRANSPOSE,$FE             ; -2 semitones
        .byte CMD_JUMP
        .word Loop_A416

Sub_A483:
        .byte CMD_OCTAVE2
        .byte $90                           ; A-2      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_OCTAVE3
        .byte $03                           ; C-3      len 4 = 20 fr
        .byte $40                           ; E-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A48B:
        .byte CMD_OCTAVE3
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte CMD_OCTAVE2
        .byte $62                           ; F#2      len 3 = 15 fr
        .byte $70                           ; G-2      len 1 = 5 fr
        .byte $90                           ; A-2      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A494:
        .byte CMD_OCTAVE3
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $31                           ; D#3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

Sub_A49B:
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $70                           ; G-2      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $72                           ; G-3      len 3 = 15 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $50                           ; F-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Sub_A4A6:
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE2
        .byte $A1                           ; A#2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $A1                           ; A#2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_A4B1:
        .byte CMD_OCTAVE2
        .byte $81                           ; G#2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $81                           ; G#2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Snd09_Noise:
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$04                ; volume -4
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A4C2:
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte CMD_JUMP
        .word Loop_A4C2

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

;======================================================================
; Sound $0A (music)
;======================================================================
Sound_0A:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd0A_Sq1
        .word Snd0A_Sq2
        .word Snd0A_Tri
        .word Snd0A_Noise

Snd0A_Sq1:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A4E2:
        .byte CMD_CALL
        .word Sub_A4F7
        .byte CMD_CALL
        .word Sub_A4F7
        .byte CMD_CALL
        .word Sub_A523
        .byte CMD_CALL
        .word Sub_A523
        .byte CMD_CALL
        .word Sub_A53E
        .byte CMD_CALL
        .word Sub_A53E
        .byte CMD_JUMP
        .word Loop_A4E2

Sub_A4F7:
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $32                           ; D#4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte CMD_TIE
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $32                           ; D#4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A523:
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $62                           ; F#4      len 3 = 15 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte CMD_TIE
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $93                           ; A-4      len 4 = 20 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A53E:
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $A1                           ; A#4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $A1                           ; A#4      len 2 = 10 fr
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte CMD_TIE
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $B1                           ; B-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $B1                           ; B-2      len 2 = 10 fr
        .byte CMD_RETURN

Snd0A_Sq2:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A563:
        .byte CMD_CALL
        .word Sub_A578
        .byte CMD_CALL
        .word Sub_A578
        .byte CMD_CALL
        .word Sub_A590
        .byte CMD_CALL
        .word Sub_A590
        .byte CMD_CALL
        .word Sub_A5A5
        .byte CMD_CALL
        .word Sub_A5A5
        .byte CMD_JUMP
        .word Loop_A563

Sub_A578:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $A1                           ; A#3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $A0                           ; A#3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $03                           ; C-4      len 4 = 20 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A590:
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $33                           ; D#4      len 4 = 20 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A5A5:
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $33                           ; D#4      len 4 = 20 fr
        .byte CMD_TIE
        .byte $32                           ; D#4      len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $B1                           ; B-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte $B1                           ; B-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $B0                           ; B-2      len 1 = 5 fr
        .byte CMD_RETURN

Snd0A_Tri:
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$0C             ; +12 semitones
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A5CA:
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5EB
        .byte CMD_CALL
        .word Sub_A5F2
        .byte CMD_CALL
        .word Sub_A5F2
        .byte CMD_JUMP
        .word Loop_A5CA

Sub_A5EB:
        .byte CMD_OCTAVE3
        .byte $03                           ; C-3      len 4 = 20 fr
        .byte CMD_OCTAVE2
        .byte $A3                           ; A#2      len 4 = 20 fr
        .byte $93                           ; A-2      len 4 = 20 fr
        .byte $63                           ; F#2      len 4 = 20 fr
        .byte CMD_RETURN

Sub_A5F2:
        .byte CMD_OCTAVE2
        .byte $80                           ; G#2      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $80                           ; G#2      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $83                           ; G#2      len 4 = 20 fr
        .byte $81                           ; G#2      len 2 = 10 fr
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte $93                           ; A-2      len 4 = 20 fr
        .byte CMD_TIE
        .byte $9F                           ; A-2      len 16 = 80 fr
        .byte CMD_ENVELOPE,$19              ; volume envelope $19 (starts with the next note)
        .byte CMD_RETURN

Snd0A_Noise:
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$03                ; volume -3
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_SPEED,$05                 ; note length x5

Loop_A609:
        .byte CMD_CALL
        .word Sub_A61E
        .byte CMD_CALL
        .word Sub_A61E
        .byte CMD_CALL
        .word Sub_A61E
        .byte CMD_CALL
        .word Sub_A61E
        .byte CMD_CALL
        .word Sub_A62D
        .byte CMD_CALL
        .word Sub_A62D
        .byte CMD_JUMP
        .word Loop_A609

Sub_A61E:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte CMD_RETURN

Sub_A62D:
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $23                           ; drum 2   len 4 = 20 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $23                           ; drum 2   len 4 = 20 fr
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $33                           ; drum 3   len 4 = 20 fr
        .byte CMD_LOOP_END
        .byte CMD_RETURN

;======================================================================
; Sound $0B (music)
;======================================================================
Sound_0B:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd0B_Sq1
        .word Snd0B_Sq2
        .word Snd0B_Tri
        .word Snd0B_Noise

Snd0B_Sq1:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_DETUNE,$FF                ; period -1
        .byte CMD_VOLUME,$04                ; volume -4

Loop_A64D:
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A696
        .byte CMD_LOOP_END
        .byte CMD_VOLUME_ADD,$FE            ; volume attenuation -2
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A6B7
        .byte CMD_LOOP_END
        .byte CMD_VOLUME_ADD,$02            ; volume attenuation +2
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $61                           ; F#4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $31                           ; D#4      len 2 = 10 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_VOLUME_ADD,$01            ; volume attenuation +1
        .byte CMD_CALL
        .word Sub_A6C7
        .byte CMD_LOOP_END
        .byte CMD_VOLUME_ADD,$FA            ; volume attenuation -6
        .byte CMD_JUMP
        .word Loop_A64D

Sub_A696:
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $61                           ; F#2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $61                           ; F#3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $61                           ; F#2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $61                           ; F#3      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $31                           ; D#3      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A6B7:
        .byte CMD_OCTAVE3
        .byte $37                           ; D#3      len 8 = 40 fr
        .byte $31                           ; D#3      len 2 = 10 fr
        .byte $21                           ; D-3      len 2 = 10 fr
        .byte $11                           ; C#3      len 2 = 10 fr
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte CMD_TIE
        .byte $0F                           ; C-3      len 16 = 80 fr
        .byte $77                           ; G-3      len 8 = 40 fr
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte $61                           ; F#3      len 2 = 10 fr
        .byte $51                           ; F-3      len 2 = 10 fr
        .byte $31                           ; D#3      len 2 = 10 fr
        .byte CMD_TIE
        .byte $3F                           ; D#3      len 16 = 80 fr
        .byte CMD_RETURN

Sub_A6C7:
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $A0                           ; A#4      len 1 = 5 fr
        .byte CMD_RETURN

Snd0B_Sq2:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_DETUNE,$01                ; period +1
        .byte CMD_VOLUME,$08                ; volume -8
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_A64D

Snd0B_Tri:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_TRANSPOSE,$18             ; +24 semitones
        .byte CMD_VOLUME,$01                ; volume -1

Loop_A6F5:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_A721
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_CALL
        .word Sub_A742
        .byte CMD_CALL
        .word Sub_A721
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte $A1                           ; A#1      len 2 = 10 fr
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte $A1                           ; A#1      len 2 = 10 fr
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte $A1                           ; A#1      len 2 = 10 fr
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_A6F5

Sub_A721:
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $61                           ; F#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $61                           ; F#2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $71                           ; G-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $61                           ; F#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $61                           ; F#2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 10 fr
        .byte CMD_RETURN

Sub_A742:
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $31                           ; D#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $31                           ; D#2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $01                           ; C-1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $01                           ; C-2      len 2 = 10 fr
        .byte CMD_OCTAVE1
        .byte $61                           ; F#1      len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $61                           ; F#2      len 2 = 10 fr
        .byte CMD_RETURN

Snd0B_Noise:
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$02                ; volume -2

Loop_A757:
        .byte $03                           ; drum 0   len 4 = 20 fr
        .byte $23                           ; drum 2   len 4 = 20 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_A757

;======================================================================
; Sound $0C (music)
;======================================================================
Sound_0C:
        .byte $07                           ; channels: Sq1, Sq2, Tri
        .word Snd0C_Sq1
        .word Snd0C_Sq2
        .word Snd0C_Tri

Snd0C_Sq1:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_OCTAVE4
        .byte $23                           ; D-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $23                           ; D-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $24                           ; D-4      len 5 = 5 fr
        .byte $78                           ; G-4      len 9 = 9 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $74                           ; G-4      len 5 = 5 fr
        .byte $43                           ; E-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $43                           ; E-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $44                           ; E-4      len 5 = 5 fr
        .byte $98                           ; A-4      len 9 = 9 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $94                           ; A-4      len 5 = 5 fr
        .byte $63                           ; F#4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $63                           ; F#4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $64                           ; F#4      len 5 = 5 fr
        .byte $96                           ; A-4      len 7 = 7 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd0C_Sq2:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_OCTAVE3
        .byte $B3                           ; B-3      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $B3                           ; B-3      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $B4                           ; B-3      len 5 = 5 fr
        .byte CMD_OCTAVE4
        .byte $28                           ; D-4      len 9 = 9 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $24                           ; D-4      len 5 = 5 fr
        .byte $03                           ; C-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $03                           ; C-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $04                           ; C-4      len 5 = 5 fr
        .byte $48                           ; E-4      len 9 = 9 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $44                           ; E-4      len 5 = 5 fr
        .byte $23                           ; D-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $23                           ; D-4      len 4 = 4 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte $24                           ; D-4      len 5 = 5 fr
        .byte $26                           ; D-4      len 7 = 7 fr
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $23                           ; D-4      len 4 = 20 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd0C_Tri:
        .byte CMD_ENVELOPE,$1A              ; volume envelope $1A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_TRANSPOSE,$0C             ; +12 semitones
        .byte CMD_OCTAVE2
        .byte $75                           ; G-2      len 6 = 30 fr
        .byte CMD_OCTAVE3
        .byte $05                           ; C-3      len 6 = 30 fr
        .byte $22                           ; D-3      len 3 = 15 fr
        .byte $60                           ; F#3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $73                           ; G-3      len 4 = 20 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

;======================================================================
; Sound $0D (music)
;======================================================================
Sound_0D:
        .byte $07                           ; channels: Sq1, Sq2, Tri
        .word Snd0D_Sq1
        .word Snd0D_Sq2
        .word Snd0D_Tri

Snd0D_Sq1:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE6
        .byte $01                           ; C-6      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd0D_Sq2:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $C2                           ; rest     len 3 = 3 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $30                           ; D#4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_SPEED,$01                 ; note length x1
        .byte $C1                           ; rest     len 2 = 2 fr
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $71                           ; G-5      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd0D_Tri:
        .byte CMD_ENVELOPE,$1B              ; volume envelope $1B (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $51                           ; F-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-3      len 2 = 10 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE5
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

;======================================================================
; Sound $0E (music)
;======================================================================
Sound_0E:
        .byte $07                           ; channels: Sq1, Sq2, Tri
        .word Snd0E_Sq1
        .word Snd0E_Sq2
        .word Snd0E_Tri

Snd0E_Sq1:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_CALL
        .word Sub_A893
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte $21                           ; D-5      len 2 = 14 fr
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $90                           ; A-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $90                           ; A-4      len 1 = 7 fr
        .byte $B0                           ; B-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $B0                           ; B-4      len 1 = 7 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte CMD_CALL
        .word Sub_A893
        .byte $50                           ; F-5      len 1 = 7 fr
        .byte $41                           ; E-5      len 2 = 14 fr
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $90                           ; A-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $B0                           ; B-4      len 1 = 7 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte $C1                           ; rest     len 2 = 14 fr
        .byte CMD_DETUNE,$FE                ; period -2
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $91                           ; A-3      len 2 = 14 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_END

Sub_A893:
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $52                           ; F-5      len 3 = 21 fr
        .byte CMD_RETURN

Snd0E_Sq2:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_VOLUME,$02                ; volume -2
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_CALL
        .word Sub_A8D1
        .byte $02                           ; C-4      len 3 = 21 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte $91                           ; A-3      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $B0                           ; B-3      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $B0                           ; B-3      len 1 = 7 fr
        .byte $90                           ; A-3      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $90                           ; A-3      len 1 = 7 fr
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte CMD_CALL
        .word Sub_A8D1
        .byte $42                           ; E-4      len 3 = 21 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte $91                           ; A-3      len 2 = 14 fr
        .byte CMD_OCTAVE4
        .byte $40                           ; E-4      len 1 = 7 fr
        .byte $40                           ; E-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte $40                           ; E-4      len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte CMD_SWEEP,$8D                 ; sweep register $8D
        .byte $22                           ; D-3      len 3 = 21 fr
        .byte CMD_VOLUME,$01                ; volume -1
        .byte $42                           ; E-3      len 3 = 21 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_END

Sub_A8D1:
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_OCTAVE3
        .byte $90                           ; A-3      len 1 = 7 fr
        .byte $70                           ; G-3      len 1 = 7 fr
        .byte $C0                           ; rest     len 1 = 7 fr
        .byte CMD_OCTAVE4
        .byte CMD_RETURN

Snd0E_Tri:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$07                 ; note length x7
        .byte CMD_LOOP,$07                  ; repeat 7x
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 7 fr
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte $70                           ; G-5      len 1 = 7 fr
        .byte CMD_OCTAVE6
        .byte $00                           ; C-6      len 1 = 7 fr
        .byte CMD_OCTAVE5
        .byte $70                           ; G-5      len 1 = 7 fr
        .byte $40                           ; E-5      len 1 = 7 fr
        .byte CMD_LOOP_END
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_OCTAVE3
        .byte CMD_LOOP,$17                  ; repeat 23x
        .byte $60                           ; F#3      len 1 = 1 fr
        .byte CMD_TRANSPOSE_ADD,$01         ; transpose +1 more
        .byte CMD_LOOP_END
        .byte CMD_OCTAVE2
        .byte CMD_LOOP,$13                  ; repeat 19x
        .byte $10                           ; C#2      len 1 = 1 fr
        .byte CMD_TRANSPOSE_ADD,$01         ; transpose +1 more
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $0F (music)
;======================================================================
Sound_0F:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd0F_Sq1
        .word Snd0F_Sq2
        .word Snd0F_Tri
        .word Snd0F_Noise

Snd0F_Sq1:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_DETUNE,$FF                ; period -1
        .byte CMD_VOLUME,$05                ; volume -5

Loop_A911:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A941
        .byte $25                           ; D-4      len 6 = 48 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte $53                           ; F-4      len 4 = 32 fr
        .byte $79                           ; G-4      len 10 = 80 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte CMD_TIE
        .byte $4A                           ; E-4      len 11 = 88 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $59                           ; F-4      len 10 = 80 fr
        .byte $71                           ; G-4      len 2 = 16 fr
        .byte $51                           ; F-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $27                           ; D-4      len 8 = 64 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte $53                           ; F-4      len 4 = 32 fr
        .byte $79                           ; G-4      len 10 = 80 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte CMD_TIE
        .byte $4A                           ; E-4      len 11 = 88 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $58                           ; F-4      len 9 = 72 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $51                           ; F-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $51                           ; F-4      len 2 = 16 fr
        .byte $7B                           ; G-4      len 12 = 96 fr
        .byte $C3                           ; rest     len 4 = 32 fr
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_A941
        .byte $0B                           ; C-4      len 12 = 96 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_END

Sub_A941:
        .byte CMD_OCTAVE3
        .byte $41                           ; E-3      len 2 = 16 fr
        .byte $71                           ; G-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $45                           ; E-4      len 6 = 48 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte CMD_OCTAVE3
        .byte $96                           ; A-3      len 7 = 56 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte CMD_OCTAVE3
        .byte $95                           ; A-3      len 6 = 48 fr
        .byte CMD_OCTAVE4
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $71                           ; G-4      len 2 = 16 fr
        .byte $73                           ; G-4      len 4 = 32 fr
        .byte $51                           ; F-4      len 2 = 16 fr
        .byte $41                           ; E-4      len 2 = 16 fr
        .byte $25                           ; D-4      len 6 = 48 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $41                           ; E-3      len 2 = 16 fr
        .byte $71                           ; G-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $45                           ; E-4      len 6 = 48 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte CMD_OCTAVE3
        .byte $96                           ; A-3      len 7 = 56 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte $21                           ; D-4      len 2 = 16 fr
        .byte $43                           ; E-4      len 4 = 32 fr
        .byte CMD_OCTAVE3
        .byte $95                           ; A-3      len 6 = 48 fr
        .byte $B1                           ; B-3      len 2 = 16 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 16 fr
        .byte CMD_RETURN

Snd0F_Sq2:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_VOLUME,$09                ; volume -9
        .byte CMD_DETUNE,$01                ; period +1
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte CMD_JUMP
        .word Loop_A911

Snd0F_Tri:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_TRANSPOSE,$0C             ; +12 semitones
        .byte CMD_VOLUME,$02                ; volume -2
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_A9EB
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $72                           ; G-2      len 3 = 24 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $B1                           ; B-2      len 2 = 16 fr
        .byte $43                           ; E-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $40                           ; E-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $B1                           ; B-2      len 2 = 16 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte CMD_OCTAVE1
        .byte $93                           ; A-1      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $90                           ; A-1      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $91                           ; A-1      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $20                           ; D-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $21                           ; D-2      len 2 = 16 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $21                           ; D-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $53                           ; F-2      len 4 = 32 fr
        .byte $43                           ; E-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $40                           ; E-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $B1                           ; B-2      len 2 = 16 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE1
        .byte $93                           ; A-1      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $90                           ; A-1      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_OCTAVE2
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $51                           ; F-2      len 2 = 16 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $20                           ; D-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $21                           ; D-2      len 2 = 16 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $70                           ; G-2      len 1 = 8 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte $74                           ; G-2      len 5 = 40 fr
        .byte $C2                           ; rest     len 3 = 24 fr
        .byte CMD_LOOP_END
        .byte CMD_CALL
        .word Sub_A9EB
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $05                           ; C-2      len 6 = 48 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_END

Sub_A9EB:
        .byte CMD_OCTAVE2
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $53                           ; F-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $53                           ; F-2      len 4 = 32 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $73                           ; G-2      len 4 = 32 fr
        .byte $21                           ; D-2      len 2 = 16 fr
        .byte $41                           ; E-2      len 2 = 16 fr
        .byte $51                           ; F-2      len 2 = 16 fr
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $03                           ; C-2      len 4 = 32 fr
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $71                           ; G-2      len 2 = 16 fr
        .byte $53                           ; F-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $53                           ; F-2      len 4 = 32 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $C1                           ; rest     len 2 = 16 fr
        .byte $23                           ; D-2      len 4 = 32 fr
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_OCTAVE3
        .byte $01                           ; C-3      len 2 = 16 fr
        .byte CMD_OCTAVE2
        .byte $91                           ; A-2      len 2 = 16 fr
        .byte CMD_RETURN

Snd0F_Noise:
        .byte CMD_SPEED,$08                 ; note length x8
        .byte CMD_LOOP,$28                  ; repeat 40x
        .byte CMD_VOLUME,$01                ; volume -1
        .byte $05                           ; drum 0   len 6 = 48 fr
        .byte $01                           ; drum 0   len 2 = 16 fr
        .byte $03                           ; drum 0   len 4 = 32 fr
        .byte $20                           ; drum 2   len 1 = 8 fr
        .byte CMD_VOLUME,$06                ; volume -6
        .byte $20                           ; drum 2   len 1 = 8 fr
        .byte CMD_VOLUME,$09                ; volume -9
        .byte $20                           ; drum 2   len 1 = 8 fr
        .byte CMD_VOLUME,$0B                ; volume -11
        .byte $20                           ; drum 2   len 1 = 8 fr
        .byte CMD_LOOP_END
        .byte $C0                           ; rest     len 1 = 8 fr
        .byte CMD_END

;======================================================================
; Sound $11 (music)
;======================================================================
Sound_11:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd11_Sq1
        .word Snd11_Sq2
        .word Snd11_Tri
        .word Snd11_Noise

Snd11_Sq1:
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_DETUNE,$FF                ; period -1
        .byte CMD_VOLUME,$04                ; volume -4
        .byte $C5                           ; rest     len 6 = 30 fr

Loop_AA4D:
        .byte CMD_OCTAVE4
        .byte $05                           ; C-4      len 6 = 30 fr
        .byte CMD_OCTAVE3
        .byte $94                           ; A-3      len 5 = 25 fr
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_TIE
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-3      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $43                           ; E-4      len 4 = 20 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $24                           ; D-4      len 5 = 25 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $04                           ; C-4      len 5 = 25 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $22                           ; D-4      len 3 = 15 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $51                           ; F-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_TIE
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $06                           ; C-4      len 7 = 35 fr
        .byte CMD_TIE
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $01                           ; C-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $90                           ; A-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $70                           ; G-3      len 1 = 5 fr
        .byte $91                           ; A-3      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $73                           ; G-4      len 4 = 20 fr
        .byte CMD_TIE
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_JUMP
        .word Loop_AA4D

Snd11_Sq2:
        .byte CMD_ENVELOPE,$00              ; volume envelope $00 (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_ENVELOPE,$0C              ; volume envelope $0C (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_VOLUME,$09                ; volume -9
        .byte CMD_DETUNE,$01                ; period +1
        .byte $C5                           ; rest     len 6 = 30 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_AA4D

Snd11_Tri:
        .byte CMD_ENVELOPE,$0B              ; volume envelope $0B (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_TRANSPOSE,$18             ; +24 semitones
        .byte CMD_VOLUME,$03                ; volume -3
        .byte $C5                           ; rest     len 6 = 30 fr

Loop_AB58:
        .byte CMD_CALL
        .word Sub_AB6F
        .byte CMD_TRANSPOSE_ADD,$FD         ; transpose -3 more
        .byte CMD_CALL
        .word Sub_AB6F
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_CALL
        .word Sub_AB6F
        .byte CMD_TRANSPOSE_ADD,$F9         ; transpose -7 more
        .byte CMD_CALL
        .word Sub_AB6F
        .byte CMD_TRANSPOSE_ADD,$05         ; transpose +5 more
        .byte CMD_JUMP
        .word Loop_AB58

Sub_AB6F:
        .byte CMD_OCTAVE2
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE2
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE2
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE2
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte $00                           ; C-2      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_OCTAVE3
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_RETURN

Snd11_Noise:
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$01                ; volume -1
        .byte $50                           ; drum 5   len 1 = 5 fr
        .byte $50                           ; drum 5   len 1 = 5 fr
        .byte $40                           ; drum 4   len 1 = 5 fr
        .byte $40                           ; drum 4   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr

Loop_AB96:
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_JUMP
        .word Loop_AB96

;======================================================================
; Sound $12 (music)
;======================================================================
Sound_12:
        .byte $07                           ; channels: Sq1, Sq2, Tri
        .word Snd12_Sq1
        .word Snd12_Sq2
        .word Snd12_Tri

Snd12_Sq1:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_OCTAVE5
        .byte $30                           ; D#5      len 1 = 6 fr
        .byte $40                           ; E-5      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 6 fr
        .byte CMD_OCTAVE5
        .byte $03                           ; C-5      len 4 = 24 fr
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_TRANSPOSE,$FA             ; -6 semitones
        .byte CMD_DETUNE,$FB                ; period -5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 1 fr
        .byte $40                           ; E-2      len 1 = 1 fr
        .byte $50                           ; F-2      len 1 = 1 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 1 fr
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd12_Sq2:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C2                           ; rest     len 3 = 18 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 6 fr
        .byte $70                           ; G-4      len 1 = 6 fr
        .byte $C1                           ; rest     len 2 = 12 fr
        .byte $30                           ; D#4      len 1 = 6 fr
        .byte $43                           ; E-4      len 4 = 24 fr
        .byte CMD_OCTAVE3
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F5             ; -11 semitones
        .byte CMD_DETUNE,$FD                ; period -3
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 1 fr
        .byte $40                           ; E-2      len 1 = 1 fr
        .byte $50                           ; F-2      len 1 = 1 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 1 fr
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

Snd12_Tri:
        .byte CMD_ENVELOPE,$1A              ; volume envelope $1A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$06                 ; note length x6
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$0C             ; +12 semitones
        .byte CMD_OCTAVE3
        .byte $0B                           ; C-3      len 12 = 72 fr
        .byte CMD_ENVELOPE,$1C              ; volume envelope $1C (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$01                 ; note length x1
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_DETUNE,$01                ; period +1
        .byte CMD_OCTAVE2
        .byte $20                           ; D-2      len 1 = 1 fr
        .byte $40                           ; E-2      len 1 = 1 fr
        .byte $50                           ; F-2      len 1 = 1 fr
        .byte CMD_OCTAVE5
        .byte $40                           ; E-5      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $20                           ; D-4      len 1 = 1 fr
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 1 fr
        .byte CMD_OCTAVE4
        .byte $00                           ; C-4      len 1 = 1 fr
        .byte $C0                           ; rest     len 1 = 1 fr
        .byte CMD_END

;======================================================================
; Sound $13 (music)
;======================================================================
Sound_13:
        .byte $07                           ; channels: Sq1, Sq2, Tri
        .word Snd13_Sq1
        .word Snd13_Sq2
        .word Snd13_Tri

Snd13_Sq1:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$01                  ; duty 1
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte CMD_OCTAVE5
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte CMD_TIE
        .byte $22                           ; D-4      len 3 = 15 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $53                           ; F-4      len 4 = 20 fr
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte $20                           ; D-4      len 1 = 5 fr
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $B3                           ; B-4      len 4 = 20 fr
        .byte CMD_TIE
        .byte $BF                           ; B-4      len 16 = 80 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd13_Sq2:
        .byte CMD_ENVELOPE,$03              ; volume envelope $03 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$02                ; volume -2
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $30                           ; D#5      len 1 = 5 fr
        .byte $42                           ; E-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $02                           ; C-5      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $60                           ; F#4      len 1 = 5 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte $40                           ; E-4      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $43                           ; E-4      len 4 = 20 fr
        .byte CMD_TIE
        .byte $4F                           ; E-4      len 16 = 80 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

Snd13_Tri:
        .byte CMD_ENVELOPE,$1A              ; volume envelope $1A (starts with the next note)
        .byte CMD_DUTY,$00                  ; duty 0
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$00                ; volume -0
        .byte CMD_TRANSPOSE,$0C             ; +12 semitones
        .byte CMD_OCTAVE3
        .byte $0F                           ; C-3      len 16 = 80 fr
        .byte $42                           ; E-3      len 3 = 15 fr
        .byte $20                           ; D-3      len 1 = 5 fr
        .byte $42                           ; E-3      len 3 = 15 fr
        .byte $00                           ; C-3      len 1 = 5 fr
        .byte $C3                           ; rest     len 4 = 20 fr
        .byte $03                           ; C-3      len 4 = 20 fr
        .byte CMD_TIE
        .byte $0F                           ; C-3      len 16 = 80 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_END

;======================================================================
; Sound $14 (music)
;======================================================================
Sound_14:
        .byte $0F                           ; channels: Sq1, Sq2, Tri, Noise
        .word Snd14_Sq1
        .word Snd14_Sq2
        .word Snd14_Tri
        .word Snd14_Noise

Snd14_Sq1:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$01                ; volume -1
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr

Loop_ACAC:
        .byte CMD_CALL
        .word Sub_AD1E
        .byte CMD_OCTAVE4
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $70                           ; G-4      len 1 = 5 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $50                           ; F-4      len 1 = 5 fr
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $41                           ; E-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_LOOP_END
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $00                           ; C-4      len 1 = 5 fr
        .byte $21                           ; D-4      len 2 = 10 fr
        .byte $44                           ; E-4      len 5 = 25 fr
        .byte $C1                           ; rest     len 2 = 10 fr
        .byte CMD_CALL
        .word Sub_AD1E
        .byte $91                           ; A-4      len 2 = 10 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte CMD_OCTAVE4
        .byte $71                           ; G-4      len 2 = 10 fr
        .byte $90                           ; A-4      len 1 = 5 fr
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_LOOP_END
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $42                           ; E-5      len 3 = 15 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_AD30
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_AD30
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte CMD_CALL
        .word Sub_AD27
        .byte CMD_OCTAVE5
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $B1                           ; B-4      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_AD36
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $B0                           ; B-4      len 1 = 5 fr
        .byte CMD_OCTAVE5
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_AD36
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte $10                           ; C#5      len 1 = 5 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_CALL
        .word Sub_AD27
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $31                           ; D#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $40                           ; E-5      len 1 = 5 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $50                           ; F-5      len 1 = 5 fr
        .byte $60                           ; F#5      len 1 = 5 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte CMD_JUMP
        .word Loop_ACAC

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_AD1E:
        .byte CMD_OCTAVE5
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $70                           ; G-5      len 1 = 5 fr
        .byte $51                           ; F-5      len 2 = 10 fr
        .byte $42                           ; E-5      len 3 = 15 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte CMD_OCTAVE4
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte CMD_RETURN

Sub_AD27:
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte CMD_OCTAVE5
        .byte $71                           ; G-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $61                           ; F#5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte $41                           ; E-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_AD30:
        .byte CMD_CALL
        .word Sub_AD36
        .byte $01                           ; C-5      len 2 = 10 fr
        .byte $C0                           ; rest     len 1 = 5 fr
        .byte CMD_RETURN

Sub_AD36:
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $00                           ; C-5      len 1 = 5 fr
        .byte $21                           ; D-5      len 2 = 10 fr
        .byte $42                           ; E-5      len 3 = 15 fr
        .byte $20                           ; D-5      len 1 = 5 fr
        .byte CMD_RETURN

Snd14_Sq2:
        .byte CMD_ENVELOPE,$02              ; volume envelope $02 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_VOLUME,$01                ; volume -1
        .byte CMD_TRANSPOSE,$F4             ; -12 semitones
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr

Loop_AD48:
        .byte CMD_OCTAVE4
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_AD70
        .byte CMD_CALL
        .word Sub_AD75
        .byte CMD_CALL
        .word Sub_AD70
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $22                           ; D-4      len 3 = 15 fr
        .byte $C5                           ; rest     len 6 = 30 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_AD75
        .byte CMD_TRANSPOSE_ADD,$02         ; transpose +2 more
        .byte CMD_CALL
        .word Sub_AD75
        .byte CMD_CALL
        .word Sub_AD75
        .byte CMD_TRANSPOSE_ADD,$FE         ; transpose -2 more
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $22                           ; D-4      len 3 = 15 fr
        .byte $C5                           ; rest     len 6 = 30 fr
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_AD48

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_AD70:
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte CMD_RETURN

Sub_AD75:
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte $C2                           ; rest     len 3 = 15 fr
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte CMD_RETURN

Snd14_Tri:
        .byte CMD_ENVELOPE,$00              ; volume envelope $00 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte $CB                           ; rest     len 12 = 60 fr
        .byte $CB                           ; rest     len 12 = 60 fr

Loop_AD82:
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_CALL
        .word Sub_ADBE
        .byte CMD_OCTAVE4
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $72                           ; G-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $52                           ; F-4      len 3 = 15 fr
        .byte CMD_CALL
        .word Sub_ADBE
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte $52                           ; F-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $A2                           ; A#3      len 3 = 15 fr
        .byte $92                           ; A-3      len 3 = 15 fr
        .byte CMD_LOOP_END
        .byte CMD_LOOP,$02                  ; repeat 2x
        .byte CMD_OCTAVE3
        .byte $52                           ; F-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $52                           ; F-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $02                           ; C-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $52                           ; F-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $62                           ; F#3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $62                           ; F#4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $22                           ; D-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $62                           ; F#4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $72                           ; G-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $22                           ; D-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $72                           ; G-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $62                           ; F#3      len 3 = 15 fr
        .byte $42                           ; E-3      len 3 = 15 fr
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_AD82

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_ADBE:
        .byte CMD_OCTAVE4
        .byte $02                           ; C-4      len 3 = 15 fr
        .byte $72                           ; G-4      len 3 = 15 fr
        .byte CMD_OCTAVE3
        .byte $72                           ; G-3      len 3 = 15 fr
        .byte CMD_OCTAVE4
        .byte $42                           ; E-4      len 3 = 15 fr
        .byte CMD_RETURN

Snd14_Noise:
        .byte CMD_ENVELOPE,$00              ; volume envelope $00 (starts with the next note)
        .byte CMD_DUTY,$02                  ; duty 2
        .byte CMD_SPEED,$05                 ; note length x5
        .byte CMD_CALL
        .word Sub_ADE8
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $21                           ; drum 2   len 2 = 10 fr
        .byte $20                           ; drum 2   len 1 = 5 fr

Loop_ADD5:
        .byte CMD_LOOP,$04                  ; repeat 4x
        .byte CMD_LOOP,$03                  ; repeat 3x
        .byte CMD_CALL
        .word Sub_ADE8
        .byte CMD_LOOP_END
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $20                           ; drum 2   len 1 = 5 fr
        .byte CMD_LOOP_END
        .byte CMD_JUMP
        .word Loop_ADD5

; (never reached)
        .byte $C0                           ; rest     len 1
        .byte CMD_END

Sub_ADE8:
        .byte $02                           ; drum 0   len 3 = 15 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte $01                           ; drum 0   len 2 = 10 fr
        .byte $00                           ; drum 0   len 1 = 5 fr
        .byte $22                           ; drum 2   len 3 = 15 fr
        .byte CMD_RETURN
