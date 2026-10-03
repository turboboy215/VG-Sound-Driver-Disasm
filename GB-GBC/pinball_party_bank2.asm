; =============================================================================
;  Hero Shuugou!! Pinball Party (J) [!]  --  Jaleco GB sound engine, bank $2
; =============================================================================
;  Reverse-engineered disassembly. Reassembles byte-for-byte with RGBDS.
;
;  This is the EARLIEST known version of the engine (released January 1990).
;  Avenging Spirit / Fortified Zone / Ikari no Yousai 2 carry a later 1992
;  revision of the same driver, which renumbered the whole command set,
;  replaced the parametric envelope and tremolo commands below with
;  pointer-to-table envelopes, and cut the twelve channel slots down to eight.
;
;  Layout of this bank
;  -------------------
;    $4000-$41A3  note period table      (NoteTable proper starts at $401E)
;    $41A4-$4526  command interpreter and its handlers
;    $4527-$4884  public entry points, init, channel reset, group arbitration
;    $4890-$4DB4  channel processing, envelopes, register output
;    $4DB5-$4DCE  MusicHeaders, 13 songs
;    $4DCF-$4DF2  SfxHeaders, 18 effects
;    $4DF3-$4E22  three 16-byte wave patterns
;    $4E23-$6E9D  song / effect headers and sequence data
;    $6E9E-$7EF2  leftover sound-test program (unreachable from the game)
;    $7EF3-$7FFF  padding
;
;  Channel slots
;  -------------
;    12 slots. Slots 0-3 are music, 4-7 are SFX group A, 8-11 are SFX group B;
;    slot n drives hardware channel n & 3. Both SFX groups outrank music for a
;    given hardware channel, and the two SFX groups are arbitrated against each
;    other by effect id, so two effects can sound at once and a third displaces
;    the lower-priority one.
;
;  Sequence format
;  ---------------
;    <note> <length>            a note or rest, always two bytes
;    $FF <command> <operands>   a command; see the SCMD_* equates below
;
;    note byte = semitone * 15 + octave + 2, semitone 0-12 starting at C.
;    REST ($B8) keys the channel off. The length byte is multiplied by the
;    tempo multiplier set with SCMD_TEMPO (default 3).
;
;  See jaleco_gb_sound_commands.md for the full command reference.
; =============================================================================

INCLUDE "hardware.inc"

DEF REST EQU $b8
DEF NOTE_CM2 EQU $00
DEF NOTE_CM1 EQU $01
DEF NOTE_C0 EQU $02
DEF NOTE_C3 EQU $05
DEF NOTE_C4 EQU $06
DEF NOTE_C5 EQU $07
DEF NOTE_C6 EQU $08
DEF NOTE_C7 EQU $09
DEF NOTE_C8 EQU $0a
DEF NOTE_CS3 EQU $14
DEF NOTE_CS4 EQU $15
DEF NOTE_CS5 EQU $16
DEF NOTE_CS6 EQU $17
DEF NOTE_CS7 EQU $18
DEF NOTE_D3 EQU $23
DEF NOTE_D4 EQU $24
DEF NOTE_D5 EQU $25
DEF NOTE_D6 EQU $26
DEF NOTE_D7 EQU $27
DEF NOTE_D8 EQU $28
DEF NOTE_DS3 EQU $32
DEF NOTE_DS4 EQU $33
DEF NOTE_DS5 EQU $34
DEF NOTE_DS6 EQU $35
DEF NOTE_DS7 EQU $36
DEF NOTE_EM1 EQU $3d
DEF NOTE_E3 EQU $41
DEF NOTE_E4 EQU $42
DEF NOTE_E5 EQU $43
DEF NOTE_E6 EQU $44
DEF NOTE_E7 EQU $45
DEF NOTE_E8 EQU $46
DEF NOTE_E9 EQU $47
DEF NOTE_F3 EQU $50
DEF NOTE_F4 EQU $51
DEF NOTE_F5 EQU $52
DEF NOTE_F6 EQU $53
DEF NOTE_F7 EQU $54
DEF NOTE_F8 EQU $55
DEF NOTE_F9 EQU $56
DEF NOTE_FS2 EQU $5e
DEF NOTE_FS3 EQU $5f
DEF NOTE_FS4 EQU $60
DEF NOTE_FS5 EQU $61
DEF NOTE_FS6 EQU $62
DEF NOTE_FS7 EQU $63
DEF NOTE_GM2 EQU $69
DEF NOTE_G3 EQU $6e
DEF NOTE_G4 EQU $6f
DEF NOTE_G5 EQU $70
DEF NOTE_G6 EQU $71
DEF NOTE_G7 EQU $72
DEF NOTE_G8 EQU $73
DEF NOTE_GS3 EQU $7d
DEF NOTE_GS4 EQU $7e
DEF NOTE_GS5 EQU $7f
DEF NOTE_GS6 EQU $80
DEF NOTE_GS7 EQU $81
DEF NOTE_A2 EQU $8b
DEF NOTE_A3 EQU $8c
DEF NOTE_A4 EQU $8d
DEF NOTE_A5 EQU $8e
DEF NOTE_A6 EQU $8f
DEF NOTE_A7 EQU $90
DEF NOTE_AS2 EQU $9a
DEF NOTE_AS3 EQU $9b
DEF NOTE_AS4 EQU $9c
DEF NOTE_AS5 EQU $9d
DEF NOTE_AS6 EQU $9e
DEF NOTE_B2 EQU $a9
DEF NOTE_B3 EQU $aa
DEF NOTE_B4 EQU $ab
DEF NOTE_B5 EQU $ac
DEF NOTE_B6 EQU $ad
DEF NOTE_B7 EQU $ae
DEF NOTE_CH2 EQU $b8

DEF SCMD_GATE_FRAC EQU $01
DEF SCMD_GATE_ABS EQU $02
DEF SCMD_TRANSPOSE EQU $03
DEF SCMD_PANNING EQU $04
DEF SCMD_TEMPO EQU $05
DEF SCMD_GOTO EQU $06
DEF SCMD_SW_ENVELOPE EQU $07
DEF SCMD_ENVELOPE EQU $08
DEF SCMD_SWEEP EQU $09
DEF SCMD_TREMOLO EQU $0a
DEF SCMD_TIMBRE EQU $0b
DEF SCMD_VOLUME EQU $0c
DEF SCMD_SET_LOOP EQU $0d
DEF SCMD_LOOP EQU $0e
DEF SCMD_STOP EQU $0f
DEF SCMD_CALL EQU $10
DEF SCMD_RET EQU $11
DEF SCMD_DETUNE EQU $12
DEF SCMD_SWEEP_OFF EQU $13

DEF wSndRequestId EQU $d000
DEF wSfxAId EQU $d001
DEF wSfxBId EQU $d002
DEF wChanAdvanced EQU $d003
DEF wChanGateMode EQU $d00f
DEF wSweepDirty EQU $d01b
DEF wChanSeqPtr EQU $d01e
DEF wSfxASeqPtr EQU $d026
DEF wSfxBSeqPtr EQU $d02e
DEF wChanSwEnvVol EQU $d036
DEF wChanSwEnvStep EQU $d042
DEF wChanSwEnvRate EQU $d04e
DEF wChanSwEnvTarget EQU $d05a
DEF wChanEnvVol EQU $d066
DEF wSoundOnFlag EQU $d068
DEF wChanEnvDir EQU $d072
DEF wChanEnvPeriod EQU $d07e
DEF wChanGateFrac EQU $d08a
DEF wChanGateAbs EQU $d096
DEF wChanTranspose EQU $d0a2
DEF wChanPanning EQU $d0ae
DEF wSweepParams EQU $d0ba
DEF wChanTempo EQU $d0c3
DEF wChanTremDelay EQU $d0cf
DEF wChanTremDepth EQU $d0db
DEF wChanTremRate EQU $d0e7
DEF wChanVolume EQU $d0f3
DEF wChanTimbre EQU $d0ff
DEF wChanLoopCtr EQU $d115
DEF wChanCallStack EQU $d145
DEF wChanCallDepth EQU $d18d
DEF wSwEnvTimer EQU $d199
DEF wSwEnvReload EQU $d19d
DEF wSwEnvStepCur EQU $d1a1
DEF wSwEnvTargetCur EQU $d1a5
DEF wChanDetuneSign EQU $d1a9
DEF wChanDetune EQU $d1b5
DEF wSavedNR51 EQU $d1c1
DEF wChanPeriodHi EQU $d1c2
DEF wTremPhase EQU $d1ce
DEF wTremTimer EQU $d1d2
DEF wCurMusicId EQU $d1d6
DEF wMusicBackupMask EQU $d1d7
DEF wMusicBackupPtrs EQU $d1d8
DEF wChanRetrigger EQU $d1e0
DEF hSndChan EQU $ff96
DEF hSndActiveMask EQU $ff97
DEF hSndMaskShift EQU $ff98
DEF hSndHwChan EQU $ff99
DEF hSndFreqReg EQU $ff9a
DEF hSndFrameBudget EQU $ff9b
DEF hChanNoteTimer EQU $ff9e
DEF hMusicMask EQU $ffaa
DEF hMusicMaskLatch EQU $ffab
DEF hSfxAMask EQU $ffac
DEF hSfxAMaskLatch EQU $ffad
DEF hSfxBMask EQU $ffae
DEF hSfxBMaskLatch EQU $ffaf
DEF hChanGateTimer EQU $ffb0
DEF hChanVolMode EQU $ffb4

SECTION "Sound Engine Bank $2", ROMX[$4000], BANK[$2]
NoteTableClampLow:
	dw $8000, $8000, $8000, $8000, $8000, $83da, $85ed, $86f6	; ---- ---- ---- ---- ---- B2   B3   B4  
	dw $877b, $87bd, $87de, $87de, $87de, $87de, $87de	; B5   B6   B7   B7   B7   B7   B7  

NoteTable:
	dw $802c, $802c, $802c, $802c, $802c, $8415, $8608, $8705	; C2   C2   C2   C2   C2   C3   C4   C5  
	dw $8782, $87c1, $87e0, $87e0, $87e0, $87e0, $87e0, $809c	; C6   C7   C8   C8   C8   C8   C8   C#2 
	dw $809c, $809c, $809c, $809c, $844e, $8627, $8713, $8789	; C#2  C#2  C#2  C#2  C#3  C#4  C#5  C#6 
	dw $87c4, $87e2, $87e2, $87e2, $87e2, $87e2, $8106, $8106	; C#7  C#8  C#8  C#8  C#8  C#8  D2   D2  
	dw $8106, $8106, $8106, $8483, $8641, $8720, $8790, $87c8	; D2   D2   D2   D3   D4   D5   D6   D7  
	dw $87e4, $87e4, $87e4, $87e4, $87e4, $816a, $816a, $816a	; D8   D8   D8   D8   D8   D#2  D#2  D#2 
	dw $816a, $816a, $84b5, $865a, $872d, $8796, $87cb, $87e5	; D#2  D#2  D#3  D#4  D#5  D#6  D#7  D#8 
	dw $87e5, $87e5, $87e5, $87e5, $81c9, $81c9, $81c9, $81c9	; D#8  D#8  D#8  D#8  E2   E2   E2   E2  
	dw $81c9, $84e4, $8672, $8739, $879c, $87ce, $87e7, $87e7	; E2   E3   E4   E5   E6   E7   E8   E8  
	dw $87e7, $87e7, $87e7, $8222, $8222, $8222, $8222, $8222	; E8   E8   E8   F2   F2   F2   F2   F2  
	dw $8511, $8688, $8744, $87a2, $87d1, $87e8, $87e8, $87e8	; F3   F4   F5   F6   F7   F8   F8   F8  
	dw $87e8, $87e8, $8276, $8276, $8276, $8276, $8276, $853b	; F8   F8   F#2  F#2  F#2  F#2  F#2  F#3 
	dw $869d, $874e, $87a7, $87d3, $87e9, $87e9, $87e9, $87e9	; F#4  F#5  F#6  F#7  F8   F8   F8   F8  
	dw $87e9, $82c6, $82c6, $82c6, $82c6, $82c6, $8563, $86b1	; F8   G2   G2   G2   G2   G2   G3   G4  
	dw $8758, $87ac, $87d6, $87eb, $87eb, $87eb, $87eb, $87eb	; G5   G6   G7   G8   G8   G8   G8   G8  
	dw $8311, $8311, $8311, $8311, $8311, $8588, $86c4, $8762	; G#2  G#2  G#2  G#2  G#2  G#3  G#4  G#5 
	dw $87b1, $87d8, $87ec, $87ec, $87ec, $87ec, $87ec, $8358	; G#6  G#7  G#8  G#8  G#8  G#8  G#8  A2  
	dw $8358, $8358, $8358, $8358, $85ac, $86d6, $876b, $87b5	; A2   A2   A2   A2   A3   A4   A5   A6  
	dw $87da, $87ed, $87ed, $87ed, $87ed, $87ed, $839b, $839b	; A7   A8   A8   A8   A8   A8   A#2  A#2 
	dw $839b, $839b, $839b, $85cd, $86e6, $8773, $87b9, $87dc	; A#2  A#2  A#2  A#3  A#4  A#5  A#6  A#7 
	dw $87ee, $87ee, $87ee, $87ee, $87ee, $83da, $83da, $83da	; A#8  A#8  A#8  A#8  A#8  B2   B2   B2  
	dw $83da, $83da, $85ed, $86f6, $877b, $87bd, $87de, $87ef	; B2   B2   B3   B4   B5   B6   B7   B8  
	dw $87ef, $87ef, $87ef, $87ef, $8415, $8415, $8415, $8415	; B8   B8   B8   B8   C3   C3   C3   C3  
	dw $8415, $8608, $8705, $8782, $87c1, $87e0, $87ff, $87ff	; C3   C4   C5   C6   C7   C8   C13  C13 
	dw $87ff, $87ff, $87ff	; C13  C13  C13 

; Execute one $FF-escaped sequence command.
; In:  hl = stream pointer, pointing at the $FF escape byte
;      [hSndChan] = channel slot (0-11)
; Out: hl = stream pointer just past the command

Sound_ExecCommand:
	inc hl
	ld a,[hl+]
	dec a
	jr z,Cmd_GateFrac
	dec a
	jr z,Cmd_GateAbs
	dec a
	jr z,Cmd_Transpose
	dec a
	jr z,Cmd_Panning
	dec a
	jr z,Cmd_Tempo
	dec a
	jp z,Cmd_Goto
	ld b,a
	ldh a,[hSndFrameBudget]
	and a
	jr z,Loc_41c2
	dec a
	ldh [hSndFrameBudget],a

Loc_41c2:
	dec b
	jp z,Cmd_SwEnvelope
	dec b
	jp z,Cmd_Envelope
	dec b
	jp z,Cmd_Sweep
	dec b
	jp z,Cmd_Tremolo
	dec b
	jp z,Cmd_Timbre
	dec b
	jp z,Cmd_Volume
	dec b
	jr z,Cmd_SetLoop
	dec b
	jp z,Cmd_Loop
	dec b
	jp z,Cmd_Stop
	dec b
	jp z,Cmd_Call
	dec b
	jr z,Cmd_Return
	dec b
	jr z,Cmd_Detune
	jp Cmd_SweepOff

Cmd_Panning:
	ld bc,wChanPanning
	jr Cmd_StoreByteIndexed

Cmd_GateFrac:
	ld bc,wChanGateFrac
	jr Cmd_StoreByteIndexed

Cmd_GateAbs:
	ld bc,wChanGateAbs
	jr Cmd_StoreByteIndexed

Cmd_Transpose:
	ld bc,wChanTranspose
	jr Cmd_StoreByteIndexed

Cmd_Tempo:
	ld bc,wChanTempo

Cmd_StoreByteIndexed:
	ldh a,[hSndChan]
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld a,[hl+]
	ld [bc],a
	ret

Cmd_Detune:
	ld bc,wChanDetune
	ldh a,[hSndChan]
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld de,wChanDetuneSign
	ldh a,[hSndChan]
	add a,e
	ld e,a
	ld a,$00
	adc a,d
	ld d,a
	ld a,[hl]
	rlca
	jr nc,Loc_4235
	xor a
	ld [de],a
	ld a,[hl+]
	cpl
	inc a
	ld [bc],a
	ret

Loc_4235:
	ld a,$01
	ld [de],a
	ld a,[hl+]
	ld [bc],a
	ret

Cmd_Return:
	ld hl,wChanCallDepth
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	ld a,[hl]
	dec a
	ld [hl],a
	ld d,a
	ld a,c
	add a,a
	add a,d
	add a,c
	add a,a
	ld c,a
	ld hl,wChanCallStack
	add hl,bc
	ld a,[hl+]
	ld l,[hl]
	ld h,a
	ret

Cmd_SetLoop:
	ldh a,[hSndChan]
	and a
	jr z,Loc_4260
	ld e,a
	xor a

Loc_425b:
	add a,$04
	dec e
	jr nz,Loc_425b

Loc_4260:
	ld b,a
	ld a,[hl+]
	add a,b
	ld bc,wChanLoopCtr
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld a,[hl+]
	dec a
	ld [bc],a
	ret

Cmd_Loop:
	ldh a,[hSndChan]
	and a
	jr z,Loc_427c
	ld e,a
	xor a

Loc_4277:
	add a,$04
	dec e
	jr nz,Loc_4277

Loc_427c:
	ld b,a
	ld a,[hl+]
	add a,b
	ld bc,wChanLoopCtr
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld a,[bc]
	and a
	jr nz,Loc_428f
	inc hl
	inc hl
	ret

Loc_428f:
	dec a
	ld [bc],a

Cmd_Goto:
	ld bc,wChanSeqPtr
	ldh a,[hSndChan]
	ld e,a
	add a,a
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld a,[hl+]
	ld [bc],a
	ld d,a
	inc bc
	ld a,[hl]
	ld [bc],a
	ld h,a
	ld l,d
	ret

Cmd_Call:
	push hl
	ld hl,wChanCallDepth
	ldh a,[hSndChan]
	ld e,a
	ld d,b
	add hl,de
	ld a,[hl]
	ld b,a
	inc a
	ld [hl],a
	ld a,e
	add a,a
	add a,e
	add a,b
	add a,a
	ld e,a
	ld hl,wChanCallStack
	add hl,de
	pop de
	push de
	inc de
	inc de
	ld a,d
	ld [hl+],a
	ld [hl],e
	pop hl
	jr Cmd_Goto

Cmd_SwEnvelope:
	ld d,b
	ld b,h
	ld c,l
	ldh a,[hSndChan]
	ld e,a
	ld hl,wChanSwEnvVol
	add hl,de
	ld a,e
	ld de,$000c
	and $03
	cp $02
	jr z,Loc_4305
	ld a,[bc]
	ld [hl],a
	inc bc
	add hl,de
	ld a,[bc]
	ld [hl],a

Loc_42e2:
	inc bc
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ldh a,[hSndChan]
	and $03
	cp $02
	jr z,Loc_4316
	add hl,de
	ld a,[bc]
	ld [hl],a

Loc_42f2:
	ld hl,hChanVolMode
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld [hl],$02
	ld hl,wChanGateMode
	add hl,de
	ld [hl],$01
	inc bc
	ld h,b
	ld l,c
	ret

Loc_4305:
	ld a,[bc]
	rlca
	cpl
	inc a
	inc a
	and $06
	ld [hl],a
	inc bc
	add hl,de
	ld a,[bc]
	add a,a
	cpl
	inc a
	ld [hl],a
	jr Loc_42e2

Loc_4316:
	add hl,de
	ld a,[bc]
	rlca
	cpl
	inc a
	inc a
	and $06
	add a,$f9
	ld [hl],a
	jr Loc_42f2

Cmd_Envelope:
	ld d,b
	ld b,h
	ld c,l
	ld hl,wChanEnvVol
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld hl,wChanEnvDir
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld hl,wChanEnvPeriod
	add hl,de
	ld a,[bc]
	ld [hl],a
	ld hl,hChanVolMode
	add hl,de
	ld [hl],$01
	ld hl,wChanGateMode
	add hl,de
	ld [hl],$01
	inc bc
	ld h,b
	ld l,c
	ret

Cmd_Sweep:
	ldh a,[hSndChan]
	and $03
	jr nz,Loc_437e
	ld d,a
	ld b,h
	ld c,l
	ld hl,wSweepParams
	ldh a,[hSndChan]
	and $0c
	rrca
	rrca
	ld e,a
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld e,$03
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld hl,wSweepDirty
	ldh a,[hSndChan]
	and $0c
	rrca
	rrca
	ld e,a
	add hl,de
	ld [hl],$01
	ld h,b
	ld l,c
	ret

Loc_437e:
	inc hl
	inc hl
	inc hl
	ret

Cmd_SweepOff:
	ldh a,[hSndChan]
	and $03
	ret nz
	ld bc,wSweepDirty
	ldh a,[hSndChan]
	and $0c
	rrca
	rrca
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	xor a
	ld [bc],a
	ldh [rNR10],a
	ret

Cmd_Tremolo:
	ld d,b
	ld b,h
	ld c,l
	ld hl,wChanTremDelay
	ldh a,[hSndChan]
	ld e,a
	ld d,$00
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld hl,wChanTremDepth
	add hl,de
	ld a,e
	and $03
	cp $02
	jr z,Loc_43d4
	ld a,[bc]
	ld [hl],a

Loc_43b7:
	inc bc
	ld hl,wChanTremRate
	add hl,de
	ld a,[bc]
	dec a
	ld [hl],a
	ld hl,hChanVolMode
	add hl,de
	ld [hl],$03
	ld hl,wChanGateMode
	add hl,de
	ld [hl],d
	inc bc
	ld hl,wTremPhase
	add hl,de
	ld [hl],$aa
	ld h,b
	ld l,c
	ret

Loc_43d4:
	ld a,[bc]
	add a,a
	ld [hl],a
	jr Loc_43b7

Cmd_Timbre:
	ld bc,wChanTimbre
	ldh a,[hSndChan]
	add a,a
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ldh a,[hSndChan]
	and $03
	cp $02
	jr nz,Loc_43f3
	ld a,[hl+]
	ld [bc],a
	inc bc
	ld a,[hl+]
	ld [bc],a
	ret

Loc_43f3:
	ld a,[hl+]
	rrca
	rrca
	ld [bc],a
	inc bc
	ld a,[hl+]
	ld [bc],a
	ret

Cmd_Volume:
	ld bc,wChanVolume
	ldh a,[hSndChan]
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ldh a,[hSndChan]
	and $03
	cp $02
	jr z,Loc_4414
	ld a,[hl+]
	swap a
	ld [bc],a
	jr Loc_442e

Loc_4414:
	ld a,[hl+]
	dec a
	jr z,Loc_4421
	dec a
	jr z,Loc_4426
	dec a
	jr z,Loc_442b
	ld [bc],a
	jr Loc_442e

Loc_4421:
	ld a,$60
	ld [bc],a
	jr Loc_442e

Loc_4426:
	ld a,$40
	ld [bc],a
	jr Loc_442e

Loc_442b:
	ld a,$20
	ld [bc],a

Loc_442e:
	ld bc,wChanGateMode
	ldh a,[hSndChan]
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	xor a
	ld [bc],a
	ld c,$b4
	ldh a,[hSndChan]
	add a,c
	ld c,a
	xor a
	ldh [c],a
	ret

Cmd_Stop:
	ld h,b
	ld l,b
	ldh a,[hSndChan]
	ld b,$fe
	swap a
	rlca
	jr c,Loc_44a7
	rlca
	jr c,Loc_4469
	ldh a,[hSndChan]
	and $03
	jr z,Loc_445d

Loc_4458:
	rlc b
	dec a
	jr nz,Loc_4458

Loc_445d:
	ldh a,[hMusicMask]
	and b
	ldh [hMusicMask],a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMaskLatch],a
	jr Loc_44e3

Loc_4469:
	ldh a,[hSndChan]
	and $03
	jr z,Loc_4474

Loc_446f:
	rlc b
	dec a
	jr nz,Loc_446f

Loc_4474:
	ldh a,[hSfxAMask]
	and b
	ldh [hSfxAMask],a
	ldh a,[hSfxAMaskLatch]
	and b
	ldh [hSfxAMaskLatch],a
	ld c,a
	ldh a,[hSfxBMaskLatch]
	and c
	jr z,Loc_4489
	ldh a,[hSfxBMask]
	ld b,a
	jr Loc_4495

Loc_4489:
	cpl
	ld b,a
	ldh a,[hSfxBMaskLatch]
	and b
	ld b,a
	ldh a,[hSfxBMask]
	or b
	ldh [hSfxBMask],a
	ld b,a

Loc_4495:
	ldh a,[hSfxAMask]
	or b
	cpl
	ld c,a
	ld b,a
	ldh a,[hMusicMask]
	or b
	ld b,a
	ldh a,[hMusicMaskLatch]
	and b
	and c
	ldh [hMusicMask],a
	jr Loc_44e3

Loc_44a7:
	ldh a,[hSndChan]
	and $03
	jr z,Loc_44b2

Loc_44ad:
	rlc b
	dec a
	jr nz,Loc_44ad

Loc_44b2:
	ldh a,[hSfxBMask]
	and b
	ldh [hSfxBMask],a
	ldh a,[hSfxBMaskLatch]
	and b
	ldh [hSfxBMaskLatch],a
	ld c,a
	ldh a,[hSfxAMaskLatch]
	and c
	jr z,Loc_44c7
	ldh a,[hSfxAMask]
	ld b,a
	jr Loc_44d3

Loc_44c7:
	cpl
	ld b,a
	ldh a,[hSfxAMaskLatch]
	and b
	ld b,a
	ldh a,[hSfxAMask]
	or b
	ldh [hSfxAMask],a
	ld b,a

Loc_44d3:
	ldh a,[hSfxBMask]
	or b
	cpl
	ld c,a
	ld b,a
	ldh a,[hMusicMask]
	or b
	ld b,a
	ldh a,[hMusicMaskLatch]
	and b
	and c
	ldh [hMusicMask],a

Loc_44e3:
	ldh a,[hSndChan]
	and $03
	jr z,Sound_SilenceCh1
	dec a
	jr z,Sound_SilenceCh2
	dec a
	jr z,Sound_SilenceCh3

Sound_SilenceCh4:
	xor a
	ldh [$ffb3],a
	dec a
	ldh [rNR43],a
	ldh [rNR44],a
	ld [$d1e3],a
	ret

Sound_SilenceCh1:
	ld a,$08
	ldh [rNR12],a
	xor a
	ldh [hChanGateTimer],a
	ldh [rNR10],a
	dec a
	ldh [rNR13],a
	ldh [rNR14],a
	ld [wChanRetrigger],a
	ret

Sound_SilenceCh2:
	ld a,$08
	ldh [rNR22],a
	xor a
	ldh [$ffb1],a
	dec a
	ldh [rNR23],a
	ldh [rNR24],a
	ld [$d1e1],a
	ret

Sound_SilenceCh3:
	xor a
	ldh [$ffb2],a
	ldh [rNR30],a
	dec a
	ld [$d1e2],a
	ret

Sound_SilenceChannels:
	ld h,a
	rrc h
	call c,Sound_SilenceCh1
	rrc h
	call c,Sound_SilenceCh2
	rrc h
	call c,Sound_SilenceCh3
	rrc h
	jr c,Sound_SilenceCh4
	ret

; Restore NR51 saved by Sound_Mute.

Sound_Unmute:
	ld a,[wSoundOnFlag]
	and a
	ret nz
	dec a
	ld [wSoundOnFlag],a
	ld a,[wSavedNR51]
	ldh [rNR51],a
	ret

; Save NR51 and silence all output.

Sound_Mute:
	ld a,[wSoundOnFlag]
	and a
	ret z
	ldh a,[rNR51]
	ld [wSavedNR51],a
	xor a
	ldh [rNR51],a
	ld [wSoundOnFlag],a
	ret

; Restore the music slots from the backup area (unused in bank $2).

Sound_RestoreMusic:
	ld a,[wMusicBackupMask]
	ldh [hMusicMask],a
	ldh [hMusicMaskLatch],a
	ld de,wChanSeqPtr
	ld hl,wMusicBackupPtrs
	ld b,$08

Loc_456b:
	ld a,[hl+]
	ld [de],a
	inc de
	dec b
	jr nz,Loc_456b
	ld de,hChanNoteTimer
	ld b,$04

Loc_4576:
	ld a,[hl+]
	ld [de],a
	inc de
	dec b
	jr nz,Loc_4576
	ret
	db $f0, $ab, $ea, $d7

; Back up and clear the music slots (unused in bank $2).

Sound_BackupMusic:
	pop de
	ld hl,wChanSeqPtr
	ld de,wMusicBackupPtrs
	ld b,$08

Loc_458a:
	ld a,[hl]
	ld [de],a
	xor a
	ld [hl+],a
	inc de
	dec b
	jr nz,Loc_458a
	ld hl,hChanNoteTimer
	ld b,$04

Loc_4597:
	ld a,[hl]
	ld [de],a
	xor a
	ld [hl+],a
	inc de
	dec b
	jr nz,Loc_4597
	xor a
	ldh [hMusicMask],a
	ldh [hMusicMaskLatch],a
	ret

; Silence and clear the music slots (0-3).

Sound_StopMusic:
	ldh a,[hMusicMask]
	call Sound_SilenceChannels
	xor a
	ldh [hMusicMask],a
	ldh [hMusicMaskLatch],a
	ld hl,wChanSeqPtr
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ret

; Silence and clear both SFX slot groups (4-11).

Sound_StopSfx:
	ldh a,[hSfxAMask]
	ld b,a
	ldh a,[hSfxBMask]
	or b
	call Sound_SilenceChannels
	ldh a,[hMusicMaskLatch]
	ldh [hMusicMask],a
	xor a
	ldh [hSfxAMask],a
	ldh [hSfxAMaskLatch],a
	ldh [hSfxBMask],a
	ldh [hSfxBMaskLatch],a
	ld hl,wSfxASeqPtr
	ld d,$08

Loc_45d6:
	ld [hl+],a
	ld [hl+],a
	dec d
	jr nz,Loc_45d6
	ret

; Cold-start the driver.

Sound_Init:
	ld hl,wSndRequestId
	ld b,$80
	xor a

Loc_45e2:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45e2
	ld hl,hChanNoteTimer
	ld b,$11

Loc_45ee:
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45ee
	dec a
	ld [wSoundOnFlag],a
	ld [$d1c5],a
	ld [$d1c9],a
	ld [$d1cd],a
	ld a,$77
	ldh [rNR50],a
	call Sound_SilenceCh1
	call Sound_SilenceCh2
	call Sound_SilenceCh3
	jp Sound_SilenceCh4

Sound_ResetChannelGroup:
	xor a
	ld hl,wChanAdvanced
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanCallDepth
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld hl,wSweepDirty
	add hl,de
	ld [hl],a
	ld hl,wChanGateMode
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ldh [hSndChan],a
	ld hl,wChanTranspose
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanDetune
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanDetuneSign
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,hChanVolMode
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanGateFrac
	add hl,bc
	ld a,$08
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanGateAbs
	add hl,bc
	ld a,$20
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanPanning
	add hl,bc
	ld a,$03
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanTempo
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
	ld hl,wChanVolume
	add hl,bc
	ld a,$f0
	ld [hl+],a
	ld [hl+],a
	ld a,$20
	ld [hl+],a
	ld a,$f0
	ld [hl],a
	ret

; In: a = song id (0-12). Loads MusicHeaders[a] into slots 0-3.

Sound_PlayMusic:
	ldh [hSndActiveMask],a
	ld [wCurMusicId],a
	xor a
	ldh [hMusicMask],a
	ldh [hMusicMaskLatch],a
	ldh [hChanNoteTimer],a
	ldh [$ff9f],a
	ldh [$ffa0],a
	ldh [$ffa1],a
	ld b,a
	ld c,a
	ld d,a
	ld e,a
	call Sound_ResetChannelGroup
	ld de,wChanSeqPtr
	ld hl,MusicHeaders
	ldh a,[hSndActiveMask]
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	push hl
	ld bc,hMusicMask
	ld a,$01
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	jr z,Loc_46bb
	xor a
	ldh [rNR10],a

Loc_46bb:
	ld de,$d020
	pop hl
	push hl
	ld a,$02
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d022
	pop hl
	push hl
	ld a,$04
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d024
	pop hl
	ld a,$06
	ldh [hSndChan],a
	ld a,$08
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ldh a,[hMusicMask]
	ldh [hMusicMaskLatch],a
	ld b,a
	ldh a,[hSfxAMask]
	ld c,a
	ldh a,[hSfxBMask]
	or c
	cpl
	and b
	ldh [hMusicMask],a
	ret

; In: a = sfx id (0-17). Picks SFX group A (slots 4-7) or
; group B (slots 8-11) by priority and loads SfxHeaders[a].
; Two effects can sound at once; a third displaces one by id.

Sound_PlaySfx:
	ld [wSndRequestId],a
	ld b,a
	ld a,[wSfxAId]
	sub b
	jr z,Sound_PlaySfxGroupA
	ld a,[wSfxBId]
	sub b
	jp z,Sound_PlaySfxGroupB
	ldh a,[hSfxAMaskLatch]
	ld b,a
	ldh a,[hSfxAMask]
	or b
	jr z,Sound_PlaySfxGroupA
	ldh a,[hSfxBMaskLatch]
	ld b,a
	ldh a,[hSfxBMask]
	or b
	jp z,Sound_PlaySfxGroupB
	ld a,[wSfxAId]
	ld b,a
	ld a,[wSfxBId]
	sub b
	jp nc,Loc_47ab
	sub b
	ret nc

Sound_PlaySfxGroupA:
	xor a
	ldh [hSfxAMask],a
	ldh [hSfxAMaskLatch],a
	ldh [$ffa2],a
	ldh [$ffa3],a
	ldh [$ffa4],a
	ldh [$ffa5],a
	ld bc,$0004
	ld de,$0001
	call Sound_ResetChannelGroup
	ld de,wSfxASeqPtr
	ld hl,SfxHeaders
	ld a,[wSndRequestId]
	ld [wSfxAId],a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	push hl
	ldh a,[hSfxBMaskLatch]
	ld b,a
	ldh a,[hSfxBMask]
	or b
	ldh [hSfxBMask],a
	ld bc,hSfxAMask
	ld a,$01
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	jr z,Loc_4764
	xor a
	ldh [rNR10],a

Loc_4764:
	ld de,$d028
	pop hl
	push hl
	ld a,$02
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d02a
	pop hl
	push hl
	ld a,$04
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d02c
	pop hl
	push hl
	ld a,$06
	ldh [hSndChan],a
	ld a,$08
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	pop hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld bc,$0008
	add hl,bc
	ld a,[hl]
	dec a
	jr z,Loc_479f
	xor a
	jr Loc_47a1

Loc_479f:
	ldh a,[hSfxAMask]

Loc_47a1:
	ldh [hSfxAMaskLatch],a
	ld a,$01
	ld [wSndRequestId],a
	jp Sound_ArbitrateGroups

Loc_47ab:
	ld a,[wSfxBId]
	ld b,a
	ld a,[wSndRequestId]
	sub b
	ret nc

Sound_PlaySfxGroupB:
	xor a
	ldh [hSfxBMask],a
	ldh [hSfxBMaskLatch],a
	ldh [$ffa6],a
	ldh [$ffa7],a
	ldh [$ffa8],a
	ldh [$ffa9],a
	ld bc,$0008
	ld de,$0002
	call Sound_ResetChannelGroup
	ld de,wSfxBSeqPtr
	ld hl,SfxHeaders
	ld a,[wSndRequestId]
	ld [wSfxBId],a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	push hl
	ldh a,[hSfxAMaskLatch]
	ld b,a
	ldh a,[hSfxAMask]
	or b
	ldh [hSfxAMask],a
	ld bc,hSfxBMask
	ld a,$01
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	jr z,Loc_47f3
	xor a
	ldh [rNR10],a

Loc_47f3:
	ld de,$d030
	pop hl
	push hl
	ld a,$02
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d032
	pop hl
	push hl
	ld a,$04
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$d034
	pop hl
	push hl
	ld a,$06
	ldh [hSndChan],a
	ld a,$08
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	pop hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld bc,$0008
	add hl,bc
	ld a,[hl]
	dec a
	jr z,Loc_482e
	xor a
	jr Loc_4830

Loc_482e:
	ldh a,[hSfxBMask]

Loc_4830:
	ldh [hSfxBMaskLatch],a
	ld a,$02
	ld [wSndRequestId],a

Sound_ArbitrateGroups:
	ldh a,[hSfxAMask]
	ld b,a
	ldh a,[hSfxBMask]
	and b
	jr nz,Loc_484a
	ldh a,[hSfxBMask]
	or b
	cpl
	ld b,a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMask],a
	ret

Loc_484a:
	ld a,[wSfxAId]
	ld b,a
	ld a,[wSfxBId]
	sub b
	jr c,Loc_4869
	jr z,Loc_4863

Loc_4856:
	xor a
	ldh [hSfxBMask],a
	ldh a,[hSfxAMask]
	cpl
	ld b,a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMask],a
	ret

Loc_4863:
	ld a,[wSndRequestId]
	dec a
	jr z,Loc_4856

Loc_4869:
	xor a
	ldh [hSfxAMask],a
	ldh a,[hSfxBMask]
	cpl
	ld b,a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMask],a
	ret

Sound_LoadChannel:
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ldh a,[hSndChan]
	and a
	jr z,Loc_4882

Loc_487e:
	inc hl
	dec a
	jr nz,Loc_487e

Loc_4882:
	ld a,[hl+]
	ld [de],a
	inc de
	ld a,[hl]
	ld [de],a
	and a
	ret z
	ldh a,[hSndActiveMask]
	ld h,b
	ld l,c
	or [hl]
	ld [hl],a
	ret

; Per-frame driver tick. Called from bank 0 via the $05AF thunk.

Sound_Update:
	xor a
	ld e,a
	inc a
	inc a
	ldh [hSndFrameBudget],a
	ld hl,wChanSeqPtr

Loc_4899:
	push hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld a,e
	cp $0c
	jp z,Sound_UpdateChannels
	xor a
	cp h
	jr z,Loc_48d2
	ld d,a
	dec a
	cp [hl]
	jr z,Loc_48d8
	ld hl,hChanNoteTimer
	add hl,de
	xor a
	cp [hl]
	jr nz,Loc_48d2
	ld hl,wChanAdvanced
	add hl,de
	inc a
	cp [hl]
	jr z,Loc_48d2
	ld [hl],a
	pop hl
	push hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	inc hl
	inc hl
	ld a,[hl]
	inc a
	jr z,Loc_48d8
	ld b,h
	ld c,l
	ld hl,wChanSeqPtr
	add hl,de
	add hl,de
	ld a,c
	ld [hl+],a
	ld [hl],b

Loc_48d2:
	inc e
	pop hl
	inc hl
	inc hl
	jr Loc_4899

Loc_48d8:
	ld a,e
	ldh [hSndChan],a

Loc_48db:
	call Sound_ExecCommand
	ld a,[hl]
	inc a
	jr z,Loc_48db
	ld b,h
	ld c,l
	pop hl
	ld d,h
	ld e,l
	inc de
	inc de
	ld a,c
	ld [hl+],a
	ld [hl],b
	ld hl,wChanAdvanced
	ldh a,[hSndChan]
	ld c,a
	ld b,$00
	add hl,bc
	ld [hl],$01
	ld h,d
	ld l,e
	inc c
	ld e,c
	jp Loc_4899

Sound_UpdateChannels:
	pop bc
	ldh a,[hSndFrameBudget]
	ld b,a
	ld a,[wSoundOnFlag]
	and b
	ret z
	ld hl,wChanAdvanced
	xor a
	ld b,$02

Loc_490d:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_490d
	ldh a,[hMusicMaskLatch]
	and a
	jr z,Loc_494a
	rra
	ldh [hSndMaskShift],a
	ldh a,[hMusicMask]
	ldh [hSndActiveMask],a
	jr nc,Loc_4928
	xor a
	call Sound_DoChannel1

Loc_4928:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_4934
	ld a,$01
	call Sound_DoChannel2

Loc_4934:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_4940
	ld a,$02
	call Sound_DoChannel3

Loc_4940:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_494a
	ld a,$03
	call Sound_DoChannel4

Loc_494a:
	ldh a,[hSfxAMask]
	ld b,a
	ldh a,[hSfxAMaskLatch]
	or b
	jr z,Loc_4981
	rra
	ldh [hSndMaskShift],a
	ld a,b
	ldh [hSndActiveMask],a
	jr nc,Loc_495f
	ld a,$04
	call Sound_DoChannel1

Loc_495f:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_496b
	ld a,$05
	call Sound_DoChannel2

Loc_496b:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_4977
	ld a,$06
	call Sound_DoChannel3

Loc_4977:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_4981
	ld a,$07
	call Sound_DoChannel4

Loc_4981:
	ldh a,[hSfxBMask]
	ld b,a
	ldh a,[hSfxBMaskLatch]
	or b
	jr z,Loc_49b8
	rra
	ldh [hSndMaskShift],a
	ld a,b
	ldh [hSndActiveMask],a
	jr nc,Loc_4996
	ld a,$08
	call Sound_DoChannel1

Loc_4996:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_49a2
	ld a,$09
	call Sound_DoChannel2

Loc_49a2:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_49ae
	ld a,$0a
	call Sound_DoChannel3

Loc_49ae:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_49b8
	ld a,$0b
	call Sound_DoChannel4

Loc_49b8:
	ldh a,[hMusicMask]
	ld b,a
	ldh a,[hSfxAMask]
	or b
	ld b,a
	ldh a,[hSfxBMask]
	or b
	ld b,a
	swap a
	or b
	ld b,a
	ldh a,[rNR51]
	and b
	ldh [rNR51],a
	ret

Sound_DoChannel1:
	ldh [hSndChan],a
	ld a,$13
	ldh [hSndFreqReg],a
	ld a,$01
	jr Sound_DoChannel

Sound_DoChannel2:
	ldh [hSndChan],a
	ld a,$18
	ldh [hSndFreqReg],a
	ld a,$02
	jr Sound_DoChannel

Sound_DoChannel3:
	ldh [hSndChan],a
	ld a,$1d
	ldh [hSndFreqReg],a
	ld a,$03
	jr Sound_DoChannel

Sound_DoChannel4:
	ldh [hSndChan],a
	ld a,$04

Sound_DoChannel:
	ldh [hSndHwChan],a
	ld c,$9e
	ldh a,[hSndChan]
	ld e,a
	add a,c
	ld c,a
	ldh a,[c]
	and a
	jr z,Loc_4a23
	ldh a,[hSndChan]
	ld e,a
	ld d,e
	sub $04
	jp nc,Sound_TickChannel
	ldh a,[hSndActiveMask]

Loc_4a07:
	rra
	dec d
	jr nz,Loc_4a07
	jp nc,Sound_TickChannel
	ld hl,wChanRetrigger
	add hl,de
	ld a,[hl]
	inc a
	jp nz,Sound_TickChannel
	ld [hl],a
	ld hl,wChanSeqPtr
	add hl,de
	add hl,de
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	jp Loc_4a5b

Loc_4a23:
	ld d,a
	push bc
	ld hl,wChanTempo
	add hl,de
	ld c,[hl]
	ld hl,wChanSeqPtr
	add hl,de
	add hl,de
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	inc hl
	ld b,[hl]
	xor a
	sra c
	jr nc,Loc_4a3a
	ld a,b

Loc_4a3a:
	sla b
	sra c
	jr nc,Loc_4a41
	add a,b

Loc_4a41:
	sla b
	sra c
	jr nc,Loc_4a48
	add a,b

Loc_4a48:
	pop bc
	cp d
	jr nz,Loc_4a4d
	inc a

Loc_4a4d:
	ldh [c],a
	ldh a,[hSndHwChan]
	ld b,a
	ldh a,[hSndActiveMask]

Loc_4a53:
	rra
	dec b
	jr nz,Loc_4a53
	jp nc,Sound_TickChannel
	dec hl

Loc_4a5b:
	push hl
	ld hl,wChanGateMode
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	xor a
	cp [hl]
	jr nz,Loc_4a85
	ld hl,wChanGateFrac
	add hl,bc
	ld a,[hl]
	ld hl,hChanNoteTimer
	add hl,bc
	ld e,[hl]
	ld h,b
	ld l,b
	ld d,b

Loc_4a74:
	add hl,de
	dec a
	jr nz,Loc_4a74
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	inc a
	jr Loc_4aa3

Loc_4a85:
	ld hl,wChanTempo
	add hl,bc
	ld e,[hl]
	ld hl,wChanGateAbs
	add hl,bc
	ld d,[hl]
	xor a
	sra e
	jr nc,Loc_4a95
	ld a,d

Loc_4a95:
	sla d
	sra e
	jr nc,Loc_4a9c
	add a,d

Loc_4a9c:
	sla d
	sra e
	jr nc,Loc_4aa3
	add a,d

Loc_4aa3:
	ld d,a
	ld hl,hChanGateTimer
	ld a,c
	and $03
	ld c,a
	add hl,bc
	ld [hl],d
	ld a,c
	ld d,b
	cp b
	jr nz,Loc_4acd
	ldh a,[hSndChan]
	and $0c
	rrca
	rrca
	ld e,a
	ld hl,wSweepDirty
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_4acd
	ld hl,wSweepParams
	add hl,de
	ld de,$0003
	ld c,$10
	call Sound_WriteEnvelopeReg

Loc_4acd:
	ld hl,wChanTimbre
	ldh a,[hSndChan]
	ld e,a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	ld a,e
	and $03
	jr z,Loc_4b02
	dec a
	jr z,Loc_4b07
	dec a
	jr nz,Loc_4b0a
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld c,$30
	xor a
	ldh [rNR30],a
	ld d,$04

Loc_4aed:
	ld a,[hl+]
	ldh [c],a
	inc c
	ld a,[hl+]
	ldh [c],a
	inc c
	ld a,[hl+]
	ldh [c],a
	inc c
	ld a,[hl+]
	ldh [c],a
	inc c
	dec d
	jr nz,Loc_4aed
	ld a,$80
	ldh [rNR30],a
	jr Loc_4b0a

Loc_4b02:
	ld a,[hl]
	ldh [rNR11],a
	jr Loc_4b0a

Loc_4b07:
	ld a,[hl]
	ldh [rNR21],a

Loc_4b0a:
	ld c,$b4
	ldh a,[hSndChan]
	ld e,a
	add a,c
	ld c,a
	ldh a,[c]
	dec a
	jr z,Loc_4b46
	dec a
	jp z,Loc_4b66
	dec a
	jp z,Loc_4bb4
	ld hl,wChanVolume
	add hl,de
	ld a,[hl]
	add a,b
	jr nc,Loc_4b27
	ld a,$f0

Loc_4b27:
	ld b,a
	ld a,e
	and $03
	jr z,Loc_4b37
	dec a
	jr z,Loc_4b3b
	dec a
	jr z,Loc_4b3f
	ld c,$21
	jr Loc_4b41

Loc_4b37:
	ld c,$12
	jr Loc_4b41

Loc_4b3b:
	ld c,$17
	jr Loc_4b41

Loc_4b3f:
	ld c,$1c

Loc_4b41:
	ld a,b
	ldh [c],a
	jp Loc_4bcc

Loc_4b46:
	ldh a,[hSndChan]
	and $03
	cp d
	jr z,Loc_4b54
	dec a
	jr z,Loc_4b58
	ld c,$21
	jr Loc_4b5a

Loc_4b54:
	ld c,$12
	jr Loc_4b5a

Loc_4b58:
	ld c,$17

Loc_4b5a:
	ld hl,wChanEnvVol
	add hl,de
	ld de,$000c
	call Sound_WriteEnvelopeReg
	jr Loc_4bcc

Loc_4b66:
	ldh a,[hSndChan]
	ld e,a
	and $03
	ld c,a
	ld hl,wChanSwEnvStep
	add hl,de
	ld a,[hl]
	ld hl,wSwEnvStepCur
	add hl,bc
	ld [hl],a
	ld hl,wChanSwEnvRate
	add hl,de
	ld a,[hl]
	ld hl,wSwEnvTimer
	add hl,bc
	ld [hl],a
	ld hl,wSwEnvReload
	add hl,bc
	dec a
	ld [hl],a
	ld hl,wChanSwEnvTarget
	add hl,de
	ld a,[hl]
	ld hl,wSwEnvTargetCur
	add hl,bc
	ld [hl],a
	ld hl,wChanSwEnvVol
	add hl,de
	ld a,[hl]
	swap a
	ld b,a
	ld a,c
	cp d
	jr z,Loc_4ba6
	dec a
	jr z,Loc_4baa
	dec a
	jr z,Loc_4bae
	ld c,$21
	jr Loc_4bb0

Loc_4ba6:
	ld c,$12
	jr Loc_4bb0

Loc_4baa:
	ld c,$17
	jr Loc_4bb0

Loc_4bae:
	ld c,$1c

Loc_4bb0:
	ld a,b
	ldh [c],a
	jr Loc_4bcc

Loc_4bb4:
	ld a,e
	and $03
	ld c,a
	ld b,d
	ld hl,wTremPhase
	add hl,bc
	ld a,$aa
	ld [hl],a
	ld hl,wTremTimer
	add hl,bc
	ld b,h
	ld c,l
	ld hl,wChanTremDelay
	add hl,de
	ld a,[hl]
	ld [bc],a

Loc_4bcc:
	pop hl
	ld b,[hl]
	ld a,$b8
	cp b
	jp z,Loc_4c2e
	ldh a,[hSndHwChan]
	cp $04
	jr z,Loc_4c38
	ld hl,wChanTranspose
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[hl]
	add a,b
	add a,a
	ld e,a
	rl d
	ld hl,NoteTable
	add hl,de
	ld a,[hl+]
	ld e,a
	ld d,[hl]
	push de
	ld bc,wChanDetuneSign
	ldh a,[hSndChan]
	add a,c
	ld c,a
	ld a,$00
	adc a,b
	ld b,a
	ld a,[bc]
	dec a
	jr z,Loc_4c41
	ld bc,$ffe1
	add hl,bc
	ld c,[hl]
	ld a,e
	sub c
	ld e,a
	ld hl,wChanDetune
	ldh a,[hSndChan]
	ld c,a
	xor a
	ld b,a
	add hl,bc
	ld c,[hl]
	cp c
	jr z,Loc_4c24
	ld h,b
	ld l,b
	ld d,b

Loc_4c16:
	add hl,de
	dec c
	jr nz,Loc_4c16
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra

Loc_4c24:
	pop de
	ld b,a
	ld a,e
	sub b
	ld e,a
	ld a,d
	sbc a,c
	ld d,a
	jr Loc_4c6a

Loc_4c2e:
	ldh a,[hSndHwChan]
	ld c,$af
	add a,c
	ld c,a
	xor a
	ldh [c],a
	jr Sound_TickChannel

Loc_4c38:
	ld a,b
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	jr Loc_4c7c

Loc_4c41:
	ld bc,$001d
	add hl,bc
	ld a,[hl]
	sub e
	ld e,a
	ld hl,wChanDetune
	ldh a,[hSndChan]
	ld c,a
	xor a
	add hl,bc
	ld c,[hl]
	ld h,b
	ld l,b
	cp c
	jr z,Loc_4c66
	ld d,b

Loc_4c57:
	add hl,de
	dec c
	jr nz,Loc_4c57
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	ld l,a

Loc_4c66:
	pop de
	add hl,de
	ld d,h
	ld e,l

Loc_4c6a:
	ldh a,[hSndFreqReg]
	ld c,a
	ld a,e
	ldh [c],a
	inc c
	ld hl,wChanPeriodHi
	ldh a,[hSndChan]
	ld e,a
	ld a,d
	ldh [c],a
	ld d,$00
	add hl,de
	ld [hl],a

Loc_4c7c:
	ld hl,wChanPanning
	ld d,$00
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[hl]
	dec a
	jr z,Loc_4c90
	dec a
	jr z,Loc_4c94
	ld d,$11
	jr Loc_4c95

Loc_4c90:
	ld d,$10
	jr Loc_4c95

Loc_4c94:
	inc d

Loc_4c95:
	ld b,$ee
	ld a,e
	and $03
	jr z,Loc_4ca3

Loc_4c9c:
	rlc b
	rlc d
	dec a
	jr nz,Loc_4c9c

Loc_4ca3:
	ldh a,[rNR51]
	and b
	or d
	ldh [rNR51],a

Sound_TickChannel:
	ld hl,hChanNoteTimer
	ldh a,[hSndChan]
	ld c,a
	ld b,$00
	add hl,bc
	dec [hl]
	ldh a,[hSndHwChan]
	ld d,a
	ldh a,[hSndActiveMask]

Loc_4cb8:
	rra
	dec d
	jr nz,Loc_4cb8
	ret nc
	ld hl,hChanGateTimer
	ld a,c
	and $03
	ld e,a
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_4cdb
	dec a
	cp [hl]
	ret z
	dec [hl]
	ld a,$b4
	add a,c
	ld c,a
	ldh a,[c]
	dec a
	dec a
	jp z,Sound_SwEnvelopeStep
	dec a
	jr z,Sound_TremoloStep
	ret

Loc_4cdb:
	dec [hl]
	ld a,e
	cp d
	jr z,Loc_4ced
	dec a
	jr z,Loc_4cf8
	dec a
	jr z,Loc_4d03
	ld a,$ff
	ldh [rNR43],a
	ldh [rNR44],a
	ret

Loc_4ced:
	ld a,$08
	ldh [rNR12],a
	ld a,$ff
	ldh [rNR13],a
	ldh [rNR14],a
	ret

Loc_4cf8:
	ld a,$08
	ldh [rNR22],a
	ld a,$ff
	ldh [rNR23],a
	ldh [rNR24],a
	ret

Loc_4d03:
	ldh [rNR30],a
	ret

Sound_TremoloStep:
	ldh a,[hSndChan]
	ld e,a
	ld hl,wTremTimer
	xor a
	ld d,a
	add hl,de
	cp [hl]
	jr z,Loc_4d14
	dec [hl]
	ret

Loc_4d14:
	ld b,h
	ld c,l
	ld hl,wChanTremRate
	add hl,de
	ld a,[hl]
	ld [bc],a
	ld a,e
	and $03
	jr z,Loc_4d2b
	dec a
	jr z,Loc_4d2f
	dec a
	jr z,Loc_4d33
	ld c,$21
	jr Loc_4d35

Loc_4d2b:
	ld c,$12
	jr Loc_4d35

Loc_4d2f:
	ld c,$17
	jr Loc_4d35

Loc_4d33:
	ld c,$1c

Loc_4d35:
	ld hl,wTremPhase
	ld a,e
	and $03
	add a,l
	ld l,a
	ld a,d
	adc a,h
	ld h,a
	ld a,[hl]
	rrca
	ld [hl],a
	jr c,Loc_4d59
	ld b,$00

Loc_4d47:
	ld hl,wChanVolume
	add hl,de
	ld a,[hl]
	add a,b
	and $f0
	ldh [c],a
	inc c
	inc c
	ld hl,wChanPeriodHi
	add hl,de
	ld a,[hl]
	ldh [c],a
	ret

Loc_4d59:
	ld hl,wChanTremDepth
	add hl,de
	ld b,[hl]
	swap b
	jr Loc_4d47

Sound_SwEnvelopeStep:
	ldh a,[hSndChan]
	and $03
	ld e,a
	ld hl,wSwEnvTimer
	xor a
	ld d,a
	add hl,de
	cp [hl]
	jr z,Loc_4d72
	dec [hl]
	ret

Loc_4d72:
	push hl
	ld a,e
	cp d
	jr z,Loc_4d81
	dec a
	jr z,Loc_4d85
	dec a
	jr z,Loc_4d89
	ld c,$21
	jr Loc_4d8b

Loc_4d81:
	ld c,$12
	jr Loc_4d8b

Loc_4d85:
	ld c,$17
	jr Loc_4d8b

Loc_4d89:
	ld c,$1c

Loc_4d8b:
	ldh a,[c]
	swap a
	ld hl,wSwEnvTargetCur
	add hl,de
	cp [hl]
	jr z,Loc_4da5
	ld hl,wSwEnvStepCur
	add hl,de
	add a,[hl]
	swap a
	ldh [c],a
	ld hl,wSwEnvReload
	add hl,de
	ld a,[hl]
	pop hl
	ld [hl],a
	ret

Loc_4da5:
	pop hl
	ld [hl],$ff
	ret

Sound_WriteEnvelopeReg:
	ld b,[hl]
	add hl,de
	ld a,[hl]
	rrca
	or b
	swap a
	add hl,de
	ld b,[hl]
	or b
	ldh [c],a
	ret

MusicHeaders:
	dw MusicHeader_00	; 0
	dw MusicHeader_01	; 1
	dw MusicHeader_02	; 2
	dw MusicHeader_03	; 3
	dw MusicHeader_04	; 4
	dw MusicHeader_05	; 5
	dw MusicHeader_06	; 6
	dw MusicHeader_07	; 7
	dw MusicHeader_08	; 8
	dw MusicHeader_09	; 9
	dw MusicHeader_10	; 10
	dw MusicHeader_11	; 11
	dw MusicHeader_12	; 12

SfxHeaders:
	dw SfxHeader_00	; 0
	dw SfxHeader_01	; 1
	dw SfxHeader_02	; 2
	dw SfxHeader_03	; 3
	dw SfxHeader_04	; 4
	dw SfxHeader_05	; 5
	dw SfxHeader_06	; 6
	dw SfxHeader_07	; 7
	dw SfxHeader_08	; 8
	dw SfxHeader_09	; 9
	dw SfxHeader_10	; 10
	dw SfxHeader_11	; 11
	dw SfxHeader_12	; 12
	dw SfxHeader_13	; 13
	dw SfxHeader_14	; 14
	dw SfxHeader_15	; 15
	dw SfxHeader_16	; 16
	dw SfxHeader_17	; 17

WavePattern0:
	db $ff, $ee, $dd, $cc, $bb, $aa, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00

WavePattern1:
	db $ff, $dd, $bb, $99, $33, $33, $33, $22, $22, $22, $11, $11, $11, $00, $00, $00

WavePattern2:
	db $ff, $ff, $00, $00, $ff, $ff, $00, $00, $ff, $ff, $00, $00, $ff, $ff, $00, $00

MusicHeader_00:
	dw Music00_Ch1	; channel 1
	dw Music00_Ch2	; channel 2
	dw Music00_Ch3	; channel 3
	dw Music00_Ch4	; channel 4

Music00_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0d, $00, $05	; volume 13, down, period 5
	db REST,       $04	; rest, 4

Seq_4e3d:
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_F6,    $12	; F6, len 18
	db REST,       $04	; rest, 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_GS5,   $12	; G#5, len 18
	db REST,       $04	; rest, 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_F6,    $12	; F6, len 18
	db REST,       $04	; rest, 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_GS5,   $1a	; G#5, len 26
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_GS6,   $06	; G#6, len 6
	db NOTE_AS6,   $0c	; A#6, len 12
	db NOTE_DS6,   $04	; D#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_FS6,   $06	; F#6, len 6
	db NOTE_GS6,   $0c	; G#6, len 12
	db NOTE_CS6,   $04	; C#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_F6,    $06	; F6, len 6
	db NOTE_FS6,   $0c	; F#6, len 12
	db NOTE_FS6,   $04	; F#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_AS6,   $03	; A#6, len 3
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_FS6,   $06	; F#6, len 6
	db NOTE_FS6,   $04	; F#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_GS6,   $08	; G#6, len 8
	db $ff, SCMD_GOTO
	dw Seq_4e3d

Music00_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0d, $00, $05	; volume 13, down, period 5
	db REST,       $04	; rest, 4

Seq_4eab:
	db REST,       $08	; rest, 8
	db REST,       $02	; rest, 2
	db NOTE_GS5,   $12	; G#5, len 18
	db REST,       $04	; rest, 4
	db NOTE_GS5,   $04	; G#5, len 4
	db REST,       $06	; rest, 6
	db NOTE_DS5,   $12	; D#5, len 18
	db REST,       $08	; rest, 8
	db REST,       $06	; rest, 6
	db NOTE_GS5,   $12	; G#5, len 18
	db REST,       $04	; rest, 4
	db NOTE_GS5,   $04	; G#5, len 4
	db REST,       $06	; rest, 6
	db NOTE_DS5,   $1a	; D#5, len 26
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_CS6,   $04	; C#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_GOTO
	dw Seq_4eab

Music00_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $0c, $00	; start 3, step -1, rate 12, target 0
	db REST,       $10	; rest, 16

Seq_4f0b:
	db NOTE_FS3,   $06	; F#3, len 6
	db NOTE_CS4,   $02	; C#4, len 2
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_F3,    $06	; F3, len 6
	db NOTE_DS4,   $02	; D#4, len 2
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_FS3,   $06	; F#3, len 6
	db NOTE_CS4,   $02	; C#4, len 2
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_F3,    $06	; F3, len 6
	db NOTE_DS4,   $02	; D#4, len 2
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_FS3,   $06	; F#3, len 6
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_CS5,   $08	; C#5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_F3,    $06	; F3, len 6
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS4,   $06	; C#4, len 6
	db NOTE_GS3,   $06	; G#3, len 6
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_GS4,   $08	; G#4, len 8
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_GS4,   $06	; G#4, len 6
	db NOTE_CS4,   $06	; C#4, len 6
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_CS3,   $04	; C#3, len 4
	db NOTE_DS4,   $14	; D#4, len 20
	db $ff, SCMD_GOTO
	dw Seq_4f0b

Music00_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db REST,       $10	; rest, 16

Seq_4f8c:
	db NOTE_C0,    $06	; C2, len 6 (clamped from C0)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_GOTO
	dw Seq_4f8c

MusicHeader_01:
	dw Music01_Ch1	; channel 1
	dw Music01_Ch2	; channel 2
	dw Music01_Ch3	; channel 3
	dw Music01_Ch4	; channel 4

Music01_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5

Seq_4fba:
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_G5,    $0c	; G5, len 12
	db NOTE_E5,    $0c	; E5, len 12
	db NOTE_E5,    $0c	; E5, len 12
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $18	; C5, len 24
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $08	; rest, 8
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_E5,    $10	; E5, len 16
	db NOTE_A5,    $05	; A5, len 5
	db NOTE_B5,    $06	; B5, len 6
	db NOTE_C6,    $05	; C6, len 5
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $08	; F5, len 8
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_G5,    $0c	; G5, len 12
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $08	; E6, len 8
	db REST,       $04	; rest, 4
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $08	; rest, 8
	db NOTE_G6,    $18	; G6, len 24
	db $ff, SCMD_ENVELOPE, $00, $01, $01	; volume 0, up, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B6,    $06	; B6, len 6
	db NOTE_D7,    $04	; D7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_G6,    $06	; G6, len 6
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $08	; E6, len 8
	db REST,       $04	; rest, 4
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $08	; rest, 8
	db NOTE_C6,    $18	; C6, len 24
	db $ff, SCMD_ENVELOPE, $00, $01, $01	; volume 0, up, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E7,    $04	; E7, len 4
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_E7,    $06	; E7, len 6
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_D7,    $06	; D7, len 6
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $20	; F5, len 32
	db NOTE_F5,    $20	; F5, len 32
	db NOTE_F5,    $18	; F5, len 24
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $24	; E5, len 36
	db $ff, SCMD_GOTO
	dw Seq_4fba

Music01_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5

Seq_5090:
	db NOTE_E5,    $14	; E5, len 20
	db NOTE_E5,    $0c	; E5, len 12
	db NOTE_D5,    $0c	; D5, len 12
	db NOTE_D5,    $14	; D5, len 20
	db NOTE_C5,    $20	; C5, len 32
	db NOTE_A4,    $04	; A4, len 4
	db REST,       $08	; rest, 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_E5,    $10	; E5, len 16
	db NOTE_F5,    $0c	; F5, len 12
	db REST,       $08	; rest, 8
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_G5,    $0c	; G5, len 12
	db NOTE_E5,    $0c	; E5, len 12
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_F5,    $0c	; F5, len 12
	db NOTE_F5,    $08	; F5, len 8
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $08	; C6, len 8
	db REST,       $04	; rest, 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $08	; rest, 8
	db NOTE_B5,    $18	; B5, len 24
	db $ff, SCMD_ENVELOPE, $00, $01, $01	; volume 0, up, period 1
	db $ff, SCMD_PANNING, $02	; right
	db REST,       $02	; rest, 2
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B6,    $06	; B6, len 6
	db NOTE_D7,    $04	; D7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_G6,    $04	; G6, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $08	; C6, len 8
	db REST,       $04	; rest, 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $08	; rest, 8
	db NOTE_A5,    $18	; A5, len 24
	db $ff, SCMD_ENVELOPE, $00, $01, $01	; volume 0, up, period 1
	db $ff, SCMD_PANNING, $02	; right
	db REST,       $02	; rest, 2
	db NOTE_E7,    $04	; E7, len 4
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_E7,    $06	; E7, len 6
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_D7,    $04	; D7, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $24	; G4, len 36
	db $ff, SCMD_GOTO
	dw Seq_5090

Music01_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $0a, $00	; start 3, step -1, rate 10, target 0

Seq_5162:
	db NOTE_A3,    $08	; A3, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_A3,    $08	; A3, len 8
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_D3,    $04	; D3, len 4
	db REST,       $04	; rest, 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_GOTO
	dw Seq_5162

Music01_Ch4:
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1

Seq_526d:
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db REST,       $04	; rest, 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_GOTO
	dw Seq_526d

MusicHeader_02:
	dw Music02_Ch1	; channel 1
	dw Music02_Ch2	; channel 2
	dw Music02_Ch3	; channel 3
	dw 0	; channel 4

Music02_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6

Seq_529c:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E5,    $20	; E5, len 32
	db NOTE_D5,    $20	; D5, len 32
	db NOTE_C5,    $20	; C5, len 32
	db NOTE_B4,    $20	; B4, len 32
	db NOTE_A4,    $20	; A4, len 32
	db NOTE_G4,    $20	; G4, len 32
	db NOTE_A4,    $20	; A4, len 32
	db NOTE_B4,    $20	; B4, len 32
	db NOTE_G5,    $30	; G5, len 48
	db NOTE_F5,    $10	; F5, len 16
	db NOTE_E5,    $10	; E5, len 16
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_G5,    $20	; G5, len 32
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_F5,    $08	; F5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_F5,    $10	; F5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_G6,    $08	; G6, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_D6,    $10	; D6, len 16
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_C6,    $20	; C6, len 32
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_G6,    $0c	; G6, len 12
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_E6,    $08	; E6, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_B5,    $20	; B5, len 32
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_B5,    $20	; B5, len 32
	db $ff, SCMD_GOTO
	dw Seq_529c

Music02_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots

Seq_53bc:
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $08	; E5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D4,    $08	; D4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E5,    $08	; E5, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $08	; E5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $08	; F4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $08	; A4, len 8
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D4,    $08	; D4, len 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_F5,    $14	; F5, len 20
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $08	; F5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $20	; C6, len 32
	db NOTE_B5,    $20	; B5, len 32
	db NOTE_E5,    $24	; E5, len 36
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_TREMOLO, $00, $fd, $06	; delay 0, depth 253, rate 6
	db NOTE_F5,    $20	; F5, len 32
	db NOTE_E5,    $20	; E5, len 32
	db NOTE_F5,    $20	; F5, len 32
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_GOTO
	dw Seq_53bc

Music02_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1

Seq_5643:
	db NOTE_C4,    $20	; C4, len 32
	db NOTE_G3,    $20	; G3, len 32
	db NOTE_A3,    $20	; A3, len 32
	db NOTE_E3,    $20	; E3, len 32
	db NOTE_F3,    $20	; F3, len 32
	db NOTE_C3,    $20	; C3, len 32
	db NOTE_F3,    $20	; F3, len 32
	db NOTE_G3,    $20	; G3, len 32
	db $ff, SCMD_GOTO
	dw Seq_5643

MusicHeader_03:
	dw Music03_Ch1	; channel 1
	dw Music03_Ch2	; channel 2
	dw Music03_Ch3	; channel 3
	dw Music03_Ch4	; channel 4

Music03_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $07	; G6, len 7
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G5,    $10	; G5, len 16

Seq_5695:
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_E6,    $03	; E6, len 3
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_G6,    $08	; G6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G6,    $10	; G6, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G6,    $08	; G6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_C7,    $08	; C7, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G6,    $10	; G6, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_E6,    $03	; E6, len 3
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_C7,    $08	; C7, len 8
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_C7,    $08	; C7, len 8
	db REST,       $08	; rest, 8
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_A6,    $04	; A6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_C7,    $08	; C7, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_D7,    $04	; D7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G6,    $0c	; G6, len 12
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_A6,    $04	; A6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_C7,    $08	; C7, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_B6,    $08	; B6, len 8
	db NOTE_C7,    $08	; C7, len 8
	db NOTE_CS7,   $08	; C#7, len 8
	db NOTE_D7,    $08	; D7, len 8
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_A6,    $04	; A6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_C7,    $08	; C7, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_D7,    $04	; D7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G6,    $0c	; G6, len 12
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_G7,    $03	; G7, len 3
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_DS7,   $01	; D#7, len 1
	db NOTE_D7,    $03	; D7, len 3
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $03	; G6, len 3
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $07	; G6, len 7
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_GOTO
	dw Seq_5695

Music03_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db REST,       $40	; rest, 64

Seq_580b:
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_D6,    $08	; D6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_B5,    $10	; B5, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_E6,    $08	; E6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_E6,    $08	; E6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_E6,    $10	; E6, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_D6,    $08	; D6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_B5,    $10	; B5, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $04	; volume 13, down, period 4
	db NOTE_B5,    $10	; B5, len 16
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $08	; E6, len 8
	db REST,       $08	; rest, 8
	db NOTE_E6,    $08	; E6, len 8
	db REST,       $08	; rest, 8
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $08	; rest, 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_E6,    $0c	; E6, len 12
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_A6,    $08	; A6, len 8
	db NOTE_AS6,   $08	; A#6, len 8
	db NOTE_B6,    $08	; B6, len 8
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $08	; rest, 8
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db NOTE_E6,    $0c	; E6, len 12
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db REST,       $18	; rest, 24
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $08	; rest, 8
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_G7,    $07	; G7, len 7
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_GOTO
	dw Seq_580b

Music03_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0
	db REST,       $40	; rest, 64

Seq_595b:
	db $ff, SCMD_CALL
	dw Seq_59a3
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_CALL
	dw Seq_59a3
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_C3,    $08	; C3, len 8
	db REST,       $08	; rest, 8
	db $ff, SCMD_CALL
	dw Seq_59bd
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_CALL
	dw Seq_59bd
	db NOTE_G3,    $08	; G3, len 8
	db REST,       $18	; rest, 24
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_G4,    $07	; G4, len 7
	db NOTE_G3,    $10	; G3, len 16
	db $ff, SCMD_GOTO
	dw Seq_595b

Seq_59a3:
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_RET

Seq_59bd:
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_E3,    $08	; E3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_RET

Music03_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_59e2:
	db REST,       $40	; rest, 64
	db $ff, SCMD_CALL
	dw Seq_5a0c
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_CALL
	dw Seq_5a0c
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db REST,       $20	; rest, 32
	db $ff, SCMD_GOTO
	dw Seq_59e2

Seq_5a0c:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5a10:
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_DS6,   $08	; D#6, len 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5a10
	db $ff, SCMD_RET

MusicHeader_04:
	dw Music04_Ch1	; channel 1
	dw Music04_Ch2	; channel 2
	dw Music04_Ch3	; channel 3
	dw Music04_Ch4	; channel 4

Music04_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo

Seq_5a3f:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $06	; rest, 6
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $11	; G5, len 17
	db REST,       $06	; rest, 6
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_AS4,   $0a	; A#4, len 10
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_AS4,   $08	; A#4, len 8
	db NOTE_C5,    $12	; C5, len 18
	db $ff, SCMD_ENVELOPE, $0d, $00, $07	; volume 13, down, period 7
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $06	; rest, 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_AS4,   $08	; A#4, len 8
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $06	; rest, 6
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $11	; G5, len 17
	db REST,       $06	; rest, 6
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $07	; A#5, len 7
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_F6,    $02	; F6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $18	; rest, 24
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_ENVELOPE, $0d, $00, $04	; volume 13, down, period 4
	db NOTE_C5,    $14	; C5, len 20
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $06	; rest, 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_D6,    $05	; D6, len 5
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_DS6,   $07	; D#6, len 7
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_D6,    $02	; D6, len 2
	db REST,       $06	; rest, 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_F5,    $10	; F5, len 16
	db $ff, SCMD_ENVELOPE, $00, $01, $07	; volume 0, up, period 7
	db NOTE_GS5,   $42	; G#5, len 66
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $06	; rest, 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_D6,    $05	; D6, len 5
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_DS6,   $07	; D#6, len 7
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_DS6,   $06	; D#6, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_DS6,   $06	; D#6, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_DS6,   $06	; D#6, len 6
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_GS5,   $06	; G#5, len 6
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_D5,    $10	; D5, len 16
	db $ff, SCMD_GOTO
	dw Seq_5a3f

Music04_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo

Seq_5b3f:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $08	; rest, 8
	db REST,       $06	; rest, 6
	db NOTE_E5,    $12	; E5, len 18
	db REST,       $06	; rest, 6
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $06	; rest, 6
	db NOTE_G4,    $0a	; G4, len 10
	db REST,       $08	; rest, 8
	db REST,       $06	; rest, 6
	db NOTE_G4,    $12	; G4, len 18
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $06	; volume 7, down, period 6
	db REST,       $02	; rest, 2
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $06	; rest, 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_AS4,   $08	; A#4, len 8
	db NOTE_D5,    $06	; D5, len 6
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $08	; rest, 8
	db REST,       $06	; rest, 6
	db NOTE_E5,    $12	; E5, len 18
	db REST,       $06	; rest, 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db REST,       $01	; rest, 1
	db REST,       $18	; rest, 24
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $06	; volume 7, down, period 6
	db NOTE_C5,    $13	; C5, len 19
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $06	; rest, 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_AS5,   $02	; A#5, len 2
	db REST,       $06	; rest, 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $0a	; D#5, len 10
	db NOTE_CS5,   $06	; C#5, len 6
	db $ff, SCMD_ENVELOPE, $00, $01, $07	; volume 0, up, period 7
	db NOTE_D5,    $42	; D5, len 66
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db REST,       $06	; rest, 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_B4,    $06	; B4, len 6
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_AS4,   $06	; A#4, len 6
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $06	; A4, len 6
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_GS4,   $06	; G#4, len 6
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_FS4,   $10	; F#4, len 16
	db NOTE_B4,    $10	; B4, len 16
	db $ff, SCMD_GOTO
	dw Seq_5b3f

Music04_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0

Seq_5c32:
	db $ff, SCMD_CALL
	dw Seq_5cb4
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_C4,    $02	; C4, len 2
	db REST,       $06	; rest, 6
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_CALL
	dw Seq_5cb4
	db $ff, SCMD_CALL
	dw Seq_5cb4
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_DS4,   $08	; D#4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_DS4,   $08	; D#4, len 8
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_AS3,   $02	; A#3, len 2
	db REST,       $06	; rest, 6
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_AS3,   $02	; A#3, len 2
	db REST,       $06	; rest, 6
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_GS3,   $08	; G#3, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_DS4,   $08	; D#4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_DS4,   $08	; D#4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_AS3,   $06	; A#3, len 6
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_A3,    $06	; A3, len 6
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_GS3,   $06	; G#3, len 6
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $06	; G3, len 6
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_FS3,   $06	; F#3, len 6
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_F3,    $06	; F3, len 6
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_E3,    $06	; E3, len 6
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_DS3,   $06	; D#3, len 6
	db NOTE_DS3,   $02	; D#3, len 2
	db NOTE_GS3,   $10	; G#3, len 16
	db NOTE_G3,    $10	; G3, len 16
	db $ff, SCMD_GOTO
	dw Seq_5c32

Seq_5cb4:
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_B3,    $08	; B3, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G3,    $08	; G3, len 8
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_B3,    $08	; B3, len 8
	db $ff, SCMD_RET

Music04_Ch4:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_5ccb:
	db $ff, SCMD_SET_LOOP, $00, $06	; slot 0 = 6

Seq_5ccf:
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5ccf
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_FS5,   $08	; F#5, len 8
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5ce4:
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5ce4
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5cf9:
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5cf9
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5d12:
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5d12
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db REST,       $06	; rest, 6
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5d37:
	db NOTE_CM1,   $08	; C2, len 8 (clamped from C-1)
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5d37
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_5d46:
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5d46
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db REST,       $20	; rest, 32
	db $ff, SCMD_GOTO
	dw Seq_5ccb

MusicHeader_05:
	dw Music05_Ch1	; channel 1
	dw Music05_Ch2	; channel 2
	dw Music05_Ch3	; channel 3
	dw Music05_Ch4	; channel 4

Music05_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5d82:
	db REST,       $04	; rest, 4
	db NOTE_G6,    $04	; G6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5d82

Seq_5d97:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5d9b:
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5d9b
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_GS6,   $08	; G#6, len 8
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db NOTE_A6,    $08	; A6, len 8
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $08	; A5, len 8
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_G6,    $04	; G6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5e04:
	db REST,       $04	; rest, 4
	db NOTE_G6,    $04	; G6, len 4
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5e04
	db $ff, SCMD_GOTO
	dw Seq_5d97

Music05_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5e3a:
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5e3a

Seq_5e4f:
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $08	; D#6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5e8d:
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5e8d
	db $ff, SCMD_ENVELOPE, $0c, $00, $05	; volume 12, down, period 5
	db NOTE_F6,    $08	; F6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $08	; F5, len 8
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5eca:
	db REST,       $04	; rest, 4
	db NOTE_E6,    $04	; E6, len 4
	db REST,       $04	; rest, 4
	db NOTE_C6,    $04	; C6, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5eca
	db $ff, SCMD_GOTO
	dw Seq_5e4f

Music05_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0

Seq_5efb:
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_5eff:
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5eff
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5f18:
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5f18
	db $ff, SCMD_GOTO
	dw Seq_5efb

Music05_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1

Seq_5f3c:
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_EM1,   $04	; E2, len 4 (clamped from E-1)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db REST,       $04	; rest, 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_EM1,   $04	; E2, len 4 (clamped from E-1)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db $ff, SCMD_GOTO
	dw Seq_5f3c

MusicHeader_06:
	dw Music06_Ch1	; channel 1
	dw Music06_Ch2	; channel 2
	dw Music06_Ch3	; channel 3
	dw Music06_Ch4	; channel 4

Music06_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_ENVELOPE, $0d, $00, $07	; volume 13, down, period 7
	db REST,       $10	; rest, 16
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4

Seq_5f78:
	db NOTE_B5,    $14	; B5, len 20
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_AS5,   $14	; A#5, len 20
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_A5,    $14	; A5, len 20
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_GS5,   $0c	; G#5, len 12
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_F6,    $14	; F6, len 20
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_E6,    $14	; E6, len 20
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_DS6,   $14	; D#6, len 20
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_D6,    $08	; D6, len 8
	db $ff, SCMD_GOTO
	dw Seq_5f78

Music06_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_ENVELOPE, $0d, $00, $07	; volume 13, down, period 7
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db REST,       $20	; rest, 32

Seq_5fd7:
	db NOTE_B5,    $20	; B5, len 32
	db NOTE_AS5,   $20	; A#5, len 32
	db NOTE_A5,    $20	; A5, len 32
	db NOTE_GS5,   $0c	; G#5, len 12
	db NOTE_G5,    $14	; G5, len 20
	db NOTE_F6,    $20	; F6, len 32
	db NOTE_E6,    $20	; E6, len 32
	db NOTE_DS6,   $20	; D#6, len 32
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_D6,    $08	; D6, len 8
	db $ff, SCMD_GOTO
	dw Seq_5fd7

Music06_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $03, $00	; start 3, step -1, rate 3, target 0
	db REST,       $20	; rest, 32

Seq_6004:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6008:
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6008
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6031:
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6031
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_GOTO
	dw Seq_6004

Music06_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db REST,       $0c	; rest, 12

Seq_606e:
	db $ff, SCMD_SET_LOOP, $00, $0e	; slot 0 = 14

Seq_6072:
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6072
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_GOTO
	dw Seq_606e

MusicHeader_07:
	dw Music07_Ch1	; channel 1
	dw Music07_Ch2	; channel 2
	dw Music07_Ch3	; channel 3
	dw Music07_Ch4	; channel 4

Music07_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1

Seq_60b1:
	db $ff, SCMD_CALL
	dw Seq_60da
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_60b9:
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60b9
	db $ff, SCMD_CALL
	dw Seq_60da
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_GOTO
	dw Seq_60b1

Seq_60da:
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_60de:
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60de
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_60eb:
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60eb
	db $ff, SCMD_RET

Music07_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_610c:
	db $ff, SCMD_CALL
	dw Seq_6135
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_6114:
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6114
	db $ff, SCMD_CALL
	dw Seq_6135
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_GOTO
	dw Seq_610c

Seq_6135:
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_6139:
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6139
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_6146:
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6146
	db $ff, SCMD_RET

Music07_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0

Seq_6162:
	db NOTE_C6,    $05	; C6, len 5
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_E6,    $06	; E6, len 6
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $0e	; A6, len 14
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A6,    $05	; A6, len 5
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $10	; D6, len 16
	db NOTE_C6,    $05	; C6, len 5
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_G6,    $08	; G6, len 8
	db NOTE_G6,    $06	; G6, len 6
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_C7,    $0e	; C7, len 14
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C7,    $05	; C7, len 5
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_D7,    $01	; D7, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_A6,    $06	; A6, len 6
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $06	; E6, len 6
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $06	; E6, len 6
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_GOTO
	dw Seq_6162

Music07_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1

Seq_61ea:
	db $ff, SCMD_CALL
	dw Seq_61fc
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_GOTO
	dw Seq_61ea

Seq_61fc:
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6200:
	db REST,       $08	; rest, 8
	db NOTE_EM1,   $08	; E2, len 8 (clamped from E-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6200
	db $ff, SCMD_RET

MusicHeader_08:
	dw Music08_Ch1	; channel 1
	dw Music08_Ch2	; channel 2
	dw Music08_Ch3	; channel 3
	dw Music08_Ch4	; channel 4

Music08_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo

Seq_6220:
	db $ff, SCMD_CALL
	dw Seq_6337
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_6231:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6235:
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $08	; rest, 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_AS4,   $08	; A#4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6235
	db NOTE_E4,    $04	; E4, len 4
	db REST,       $08	; rest, 8
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_6231
	db $ff, SCMD_CALL
	dw Seq_6337
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_ENVELOPE, $00, $01, $07	; volume 0, up, period 7
	db NOTE_DS6,   $10	; D#6, len 16
	db $ff, SCMD_ENVELOPE, $07, $00, $07	; volume 7, down, period 7
	db NOTE_DS6,   $28	; D#6, len 40
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $07	; volume 13, down, period 7
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $24	; C5, len 36
	db REST,       $04	; rest, 4
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $03	; G5, len 3
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS4,   $04	; A#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_C5,    $14	; C5, len 20
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_C6,    $03	; C6, len 3
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_AS5,   $24	; A#5, len 36
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_F5,    $03	; F5, len 3
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $03	; G5, len 3
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $34	; C5, len 52
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_CALL
	dw Seq_6337
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_G5,    $03	; G5, len 3
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $30	; F6, len 48
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $3c	; D6, len 60
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_G5,    $03	; G5, len 3
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $30	; F6, len 48
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $14	; D6, len 20
	db REST,       $04	; rest, 4
	db NOTE_G7,    $04	; G7, len 4
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_B7,    $01	; B7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_B7,    $01	; B7, len 1
	db NOTE_E8,    $01	; E8, len 1
	db $ff, SCMD_GOTO
	dw Seq_6220

Seq_6337:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6342:
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $06	; volume 13, down, period 6
	db NOTE_AS5,   $10	; A#5, len 16
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6342
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_RET

Music08_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo

Seq_636d:
	db $ff, SCMD_CALL
	dw Seq_646b
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_637e:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6382:
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $08	; rest, 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6382
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $08	; rest, 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_637e
	db $ff, SCMD_CALL
	dw Seq_646b
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_ENVELOPE, $00, $01, $07	; volume 0, up, period 7
	db NOTE_A5,    $10	; A5, len 16
	db $ff, SCMD_ENVELOPE, $07, $00, $07	; volume 7, down, period 7
	db NOTE_A5,    $28	; A5, len 40
	db REST,       $08	; rest, 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_ENVELOPE, $09, $00, $07	; volume 9, down, period 7
	db NOTE_F5,    $24	; F5, len 36
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_ENVELOPE, $09, $00, $07	; volume 9, down, period 7
	db NOTE_A4,    $34	; A4, len 52
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_CALL
	dw Seq_646b
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db REST,       $10	; rest, 16
	db NOTE_G4,    $03	; G4, len 3
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $20	; C6, len 32
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $3c	; G5, len 60
	db REST,       $10	; rest, 16
	db NOTE_G4,    $03	; G4, len 3
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $20	; C6, len 32
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $14	; G5, len 20
	db REST,       $04	; rest, 4
	db NOTE_D7,    $04	; D7, len 4
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db REST,       $02	; rest, 2
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_B7,    $01	; B7, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_GOTO
	dw Seq_636d

Seq_646b:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6476:
	db $ff, SCMD_ENVELOPE, $0d, $00, $06	; volume 13, down, period 6
	db NOTE_G6,    $10	; G6, len 16
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_E6,    $04	; E6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6476
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_RET

Music08_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_ABS, $40	; gate = 64 x tempo

Seq_649f:
	db $ff, SCMD_CALL
	dw Seq_6544
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $04, $00	; start 3, step -1, rate 4, target 0
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_64ad:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_64b1:
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_64b1
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_AS6,   $01	; A#6, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_AS6,   $06	; A#6, len 6
	db NOTE_A6,    $04	; A6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_64ad
	db $ff, SCMD_CALL
	dw Seq_6544
	db $ff, SCMD_SET_LOOP, $00, $05	; slot 0 = 5

Seq_6501:
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $03, $00	; start 3, step -1, rate 3, target 0
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $04	; rest, 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_DS4,   $04	; D#4, len 4
	db $ff, SCMD_VOLUME, $01	; volume 1
	db NOTE_F4,    $14	; F4, len 20
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6501
	db $ff, SCMD_CALL
	dw Seq_6544
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0
	db $ff, SCMD_SET_LOOP, $00, $1c	; slot 0 = 28

Seq_6535:
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6535
	db REST,       $18	; rest, 24
	db $ff, SCMD_GOTO
	dw Seq_649f

Seq_6544:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6551:
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6551
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_RET

Music08_Ch4:
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_6573:
	db $ff, SCMD_CALL
	dw Seq_65d5
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db $ff, SCMD_CALL
	dw Seq_65d5
	db $ff, SCMD_SET_LOOP, $00, $05	; slot 0 = 5

Seq_658f:
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db REST,       $04	; rest, 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $08	; C2, len 8 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db REST,       $04	; rest, 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_658f
	db $ff, SCMD_CALL
	dw Seq_65d5
	db $ff, SCMD_SET_LOOP, $00, $0d	; slot 0 = 13

Seq_65ba:
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_65ba
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db REST,       $18	; rest, 24
	db $ff, SCMD_GOTO
	dw Seq_6573

Seq_65d5:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_SET_LOOP, $00, $06	; slot 0 = 6

Seq_65dc:
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_65dc
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_RET

MusicHeader_09:
	dw Music09_Ch1	; channel 1
	dw Music09_Ch2	; channel 2
	dw Music09_Ch3	; channel 3
	dw 0	; channel 4

Music09_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_ENVELOPE, $0d, $00, $04	; volume 13, down, period 4

Seq_660f:
	db $ff, SCMD_CALL
	dw Seq_6834
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6617:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS6,   $04	; G#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F6,    $04	; F6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS6,   $04	; F#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS6,   $04	; A#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6617
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6680:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F7,    $04	; F7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS6,   $04	; A#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS6,   $04	; F#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS6,   $04	; G#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B6,    $04	; B6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E7,    $04	; E7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS7,   $04	; G#7, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6680
	db $ff, SCMD_GOTO
	dw Seq_660f

Music09_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_VOLUME, $05	; volume 5
	db REST,       $05	; rest, 5

Seq_6702:
	db $ff, SCMD_CALL
	dw Seq_6834
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_670a:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS6,   $04	; G#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F6,    $04	; F6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS6,   $04	; F#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS6,   $04	; A#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_670a
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6773:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F7,    $04	; F7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS6,   $04	; A#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS6,   $04	; F#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS6,   $04	; G#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B6,    $04	; B6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E7,    $04	; E7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS7,   $04	; G#7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6773
	db $ff, SCMD_GOTO
	dw Seq_6702

Music09_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $0d, $00	; start 3, step -1, rate 13, target 0

Seq_67f3:
	db $ff, SCMD_SET_LOOP, $00, $2c	; slot 0 = 44

Seq_67f7:
	db NOTE_GS3,   $0c	; G#3, len 12
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_67f7
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6802:
	db NOTE_CS3,   $0c	; C#3, len 12
	db NOTE_CS3,   $0c	; C#3, len 12
	db NOTE_CS3,   $0c	; C#3, len 12
	db NOTE_CS3,   $0c	; C#3, len 12
	db NOTE_B2,    $0c	; B2, len 12
	db NOTE_B2,    $0c	; B2, len 12
	db NOTE_B2,    $0c	; B2, len 12
	db NOTE_B2,    $0c	; B2, len 12
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6802
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_681b:
	db NOTE_FS2,   $0c	; F#2, len 12
	db NOTE_FS2,   $0c	; F#2, len 12
	db NOTE_FS2,   $0c	; F#2, len 12
	db NOTE_FS2,   $0c	; F#2, len 12
	db NOTE_A2,    $0c	; A2, len 12
	db NOTE_A2,    $0c	; A2, len 12
	db NOTE_A2,    $0c	; A2, len 12
	db NOTE_A2,    $0c	; A2, len 12
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_681b
	db $ff, SCMD_GOTO
	dw Seq_67f3

Seq_6834:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6838:
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6838
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6865:
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6865
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6892:
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6892
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_CS7,   $04	; C#7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db NOTE_CS7,   $04	; C#7, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_691f:
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_691f
	db $ff, SCMD_RET

MusicHeader_10:
	dw Music10_Ch1	; channel 1
	dw Music10_Ch2	; channel 2
	dw Music10_Ch3	; channel 3
	dw 0	; channel 4

Music10_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_ENVELOPE, $07, $01, $02	; volume 7, up, period 2
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_ENVELOPE, $03, $01, $03	; volume 3, up, period 3
	db NOTE_E4,    $10	; E4, len 16
	db $ff, SCMD_STOP

Music10_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_ENVELOPE, $03, $01, $03	; volume 3, up, period 3
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_B4,    $10	; B4, len 16
	db NOTE_E4,    $10	; E4, len 16
	db $ff, SCMD_STOP

Music10_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_GATE_ABS, $10	; gate = 16 x tempo
	db $ff, SCMD_SW_ENVELOPE, $00, $01, $01, $03	; start 0, step +1, rate 1, target 3
	db NOTE_C3,    $0c	; C3, len 12
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_F3,    $0c	; F3, len 12
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_G3,    $0c	; G3, len 12
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C3,    $10	; C3, len 16
	db $ff, SCMD_STOP

MusicHeader_11:
	dw Music11_Ch1	; channel 1
	dw Music11_Ch2	; channel 2
	dw Music11_Ch3	; channel 3
	dw 0	; channel 4

Music11_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_69da:
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_CS5,   $04	; C#5, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_69da
	db $ff, SCMD_STOP

Music11_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0b, $00, $05	; volume 11, down, period 5
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6a12:
	db NOTE_FS4,   $08	; F#4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_ENVELOPE, $0b, $00, $05	; volume 11, down, period 5
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $08	; F#4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6a12
	db $ff, SCMD_STOP

Music11_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $05, $00	; start 3, step -1, rate 5, target 0
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6a4c:
	db NOTE_GS3,   $08	; G#3, len 8
	db NOTE_CS3,   $04	; C#3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $01, $00	; start 3, step -1, rate 1, target 0
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $05, $00	; start 3, step -1, rate 5, target 0
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS3,   $08	; G#3, len 8
	db NOTE_CS3,   $04	; C#3, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6a4c
	db $ff, SCMD_STOP

MusicHeader_12:
	dw Music12_Ch1	; channel 1
	dw Music12_Ch2	; channel 2
	dw Music12_Ch3	; channel 3
	dw 0	; channel 4

Music12_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_STOP

Music12_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_STOP

Music12_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern2
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $01, $00	; start 3, step -1, rate 1, target 0
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_STOP

SfxHeader_00:
	dw Sfx00_Ch1	; channel 1
	dw Sfx00_Ch2	; channel 2
	dw Sfx00_Ch3	; channel 3
	dw 0	; channel 4

Sfx00_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db $ff, SCMD_STOP

Sfx00_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_STOP

Sfx00_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern2
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $01, $00	; start 3, step -1, rate 1, target 0
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_STOP

SfxHeader_01:
	dw 0	; channel 1
	dw Sfx01_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx01_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G6,    $18	; G6, len 24
	db $ff, SCMD_STOP

SfxHeader_02:
	dw 0	; channel 1
	dw Sfx02_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx02_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db $ff, SCMD_CALL
	dw Seq_6bb4
	db $ff, SCMD_VOLUME, $08	; volume 8
	db $ff, SCMD_CALL
	dw Seq_6bb4
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_CALL
	dw Seq_6bb4
	db $ff, SCMD_STOP

Seq_6bb4:
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_E7,    $01	; E7, len 1
	db NOTE_G7,    $01	; G7, len 1
	db NOTE_C8,    $01	; C8, len 1
	db NOTE_E8,    $01	; E8, len 1
	db NOTE_G8,    $01	; G8, len 1
	db $ff, SCMD_RET

SfxHeader_03:
	dw 0	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx03_Ch4	; channel 4

Sfx03_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db NOTE_F9,    $02	; F8, len 2 (clamped from F9)
	db NOTE_F8,    $02	; F8, len 2
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_E9,    $02	; E8, len 2 (clamped from E9)
	db $ff, SCMD_STOP

SfxHeader_04:
	dw 0	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx04_Ch4	; channel 4

Sfx04_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_E4,    $20	; E4, len 32
	db $ff, SCMD_STOP

SfxHeader_06:
	dw Sfx06_Ch1	; channel 1
	dw Sfx06_Ch2	; channel 2
	dw Sfx06_Ch3	; channel 3
	dw Sfx06_Ch4	; channel 4

Sfx06_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_VOLUME, $07	; volume 7
	db REST,       $02	; rest, 2
	db $ff, SCMD_CALL
	dw Seq_6c58
	db $ff, SCMD_STOP

Sfx06_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_VOLUME, $04	; volume 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_CALL
	dw Seq_6c58
	db $ff, SCMD_STOP

Sfx06_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_CALL
	dw Seq_6c58
	db $ff, SCMD_STOP

Seq_6c58:
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_E7,    $01	; E7, len 1
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_E7,    $01	; E7, len 1
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_E7,    $01	; E7, len 1
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_D8,    $01	; D8, len 1
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_D8,    $01	; D8, len 1
	db NOTE_G8,    $01	; G8, len 1
	db $ff, SCMD_RET

Sfx06_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db REST,       $10	; rest, 16
	db REST,       $0c	; rest, 12
	db REST,       $06	; rest, 6
	db $ff, SCMD_STOP

SfxHeader_17:
	dw Sfx17_Ch1	; channel 1
	dw Sfx17_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx17_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length

Seq_6cbf:
	db NOTE_G8,    $02	; G8, len 2
	db $ff, SCMD_GOTO
	dw Seq_6cbf

Sfx17_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length

Seq_6cdb:
	db NOTE_G8,    $02	; G8, len 2
	db $ff, SCMD_GOTO
	dw Seq_6cdb

SfxHeader_09:
	dw 0	; channel 1
	dw Sfx09_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx09_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length
	db $ff, SCMD_GOTO
	dw Seq_6cdb

SfxHeader_07:
	dw Sfx07_Ch1	; channel 1
	dw Sfx07_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx07_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_C7,    $04	; C7, len 4
	db $ff, SCMD_STOP

Sfx07_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db REST,       $01	; rest, 1
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_C7,    $04	; C7, len 4
	db $ff, SCMD_STOP

SfxHeader_08:
	dw Sfx08_Ch1	; channel 1
	dw Sfx08_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx08_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_VOLUME, $0e	; volume 14
	db $ff, SCMD_SET_LOOP, $00, $14	; slot 0 = 20

Seq_6d5a:
	db NOTE_A2,    $01	; A2, len 1
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6d5a
	db $ff, SCMD_STOP

Sfx08_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_VOLUME, $0e	; volume 14
	db $ff, SCMD_SET_LOOP, $00, $14	; slot 0 = 20

Seq_6d75:
	db NOTE_AS2,   $01	; A#2, len 1
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6d75
	db $ff, SCMD_STOP

SfxHeader_16:
	dw 0	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx16_Ch4	; channel 4

Sfx16_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db NOTE_E4,    $20	; E4, len 32
	db $ff, SCMD_STOP

SfxHeader_10:
	dw 0	; channel 1
	dw 0	; channel 2
	dw Sfx10_Ch3	; channel 3
	dw 0	; channel 4

Sfx10_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern2
	db $ff, SCMD_SW_ENVELOPE, $03, $ff, $02, $00	; start 3, step -1, rate 2, target 0
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G6,    $20	; G6, len 32
	db $ff, SCMD_STOP

SfxHeader_11:
	dw Sfx11_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx11_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G7,    $01	; G7, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G7,    $10	; G7, len 16
	db $ff, SCMD_STOP

SfxHeader_12:
	dw 0	; channel 1
	dw Sfx12_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx12_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G7,    $01	; G7, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G7,    $10	; G7, len 16
	db $ff, SCMD_STOP

SfxHeader_05:
	dw 0	; channel 1
	dw Sfx05_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx05_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_6e19:
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db $ff, SCMD_CALL
	dw Seq_6e35
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_CALL
	dw Seq_6e35
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_CALL
	dw Seq_6e35
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6e19
	db $ff, SCMD_STOP

Seq_6e35:
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_G7,    $01	; G7, len 1
	db NOTE_E7,    $01	; E7, len 1
	db $ff, SCMD_RET

SfxHeader_13:
	dw Sfx13_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx13_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db $ff, SCMD_GOTO
	dw Seq_6e8e

SfxHeader_15:
	dw Sfx15_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx15_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db $ff, SCMD_GOTO
	dw Seq_6e8e

SfxHeader_14:
	dw Sfx14_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4

Sfx14_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db $ff, SCMD_GOTO
	dw Seq_6e8e

Seq_6e8e:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_SWEEP, $02, $01, $02	; NR10=$02, $01, $02
	db NOTE_G7,    $06	; G7, len 6
	db $ff, SCMD_STOP

; Leftover sound-test / debug program ($6E9E-$7EF2).
; Not part of the driver: it drives the routines above from a
; simple on-screen menu. Left in the shipped ROM.

SoundTest_Intro:
	call Sound_Init
	call Sound_Unmute
	ld a,$07
	call Sound_PlayMusic
	call $0159
	ld de,$6f07
	call $02a6
	call Sound_Update
	call $0159
	ld de,$6f1e
	call $02a6
	call Sound_Update
	ld e,$88

Loc_6ec3:
	ld hl,$ff42
	inc [hl]
	push bc
	push de
	push hl
	call Sound_Update
	pop hl
	pop de
	pop bc
	call $0159
	dec e
	jr nz,Loc_6ec3
	ld a,$88
	ldh [$ff42],a
	call $0159
	ld de,$6f35
	call $02a6
	ld b,$32

Loc_6ee5:
	push bc
	push de
	push hl
	call Sound_Update
	pop hl
	pop de
	pop bc
	dec b
	jr nz,Loc_6ee5
	call Sound_StopMusic
	ld a,$02
	call Sound_PlaySfx
	ld a,$64

Loc_6efb:
	push af
	call $0159
	call Sound_Update
	pop af
	dec a
	jr nz,Loc_6efb
	ret

; Sound-test text strings (VRAM address, length, tile ids, $00).
	db $9b, $24, $04, $40, $41, $42, $43, $9b, $44, $0c, $50, $51, $52, $53, $48, $49
	db $4a, $4b, $4c, $4d, $4e, $4f, $00, $9b, $64, $0c, $44, $45, $46, $47, $58, $59
	db $5a, $5b, $5c, $5d, $5e, $5f, $9b, $84, $04, $54, $55, $56, $57, $00, $9a, $e4
	db $0c, $99, $9b, $8e, $9c, $8e, $97, $9d, $8e, $8d, $a4, $8b, $a2, $00

SoundTest_Main:
	db $cd, $e8, $7e, $cd, $dc, $45, $cd, $83, $01, $af, $ea, $79, $c2, $e0, $8c, $f8
	db $00, $f5, $7d, $ea, $7c, $c2, $7c, $ea, $7d, $c2, $f1, $cd, $94, $6f, $cd, $e7
	db $6f, $fa, $7b, $c2, $a7, $28, $d9, $fe, $03, $28, $0b, $3e, $ff, $e0, $e8, $fa
	db $79, $c2, $e6, $09, $28, $ca, $cd, $bb, $45, $3e, $02, $cd, $f6, $46, $3e, $30
	db $f5, $cd, $59, $01, $cd, $90, $48, $f1, $3d, $20, $f5, $cd, $bb, $45, $c9, $cd
	db $4e, $02, $af, $e0, $fe, $e0, $e9, $ea, $14, $c1, $3e, $01, $21, $00, $70, $11
	db $00, $90, $cd, $f6, $04, $cd, $f6, $04, $21, $38, $7c, $11, $00, $98, $cd, $7f
	db $05, $3e, $83, $e0, $40, $3e, $01, $e0, $ff, $fb, $cd, $d6, $70, $f0, $e8, $fe
	db $ff, $28, $11, $3e, $c1, $e0, $01, $cd, $6c, $03, $f0, $01, $fe, $c1, $c2, $13
	db $71, $af, $e0, $01, $cd, $97, $70, $e6, $09, $c0, $cd, $ae, $70, $cd, $90, $48
	db $18, $f2, $cd, $4e, $02, $cd, $75, $02, $11, $46, $71, $cd, $a6, $02, $21, $c0
	db $71, $11, $14, $c1, $01, $0e, $00, $cd, $93, $02, $3e, $01, $e0, $e9, $3e, $83
	db $e0, $40, $fb, $3e, $01, $e0, $ff, $e0, $fe, $ea, $7b, $c2, $cd, $dc, $45, $cd
	db $3c, $45, $cd, $d6, $70, $cd, $90, $48, $fa, $7b, $c2, $3d, $47, $80, $80, $21
	db $17, $c1, $85, $6f, $3e, $00, $8c, $67, $36, $a4, $cd, $97, $70, $21, $7b, $c2
	db $57, $3e, $84, $a2, $28, $15, $34, $7e, $fe, $05, $20, $02, $36, $01, $f0, $e8
	db $fe, $ff, $20, $07, $7e, $fe, $03, $20, $02, $36, $04, $cb, $72, $28, $12, $35
	db $20, $02, $36, $04, $f0, $e8, $fe, $ff, $20, $07, $7e, $fe, $03, $20, $02, $36
	db $02, $7e, $3d, $21, $17, $c1, $47, $80, $80, $85, $6f, $3e, $00, $8c, $67, $36
	db $ab, $3e, $09, $a2, $c0, $3e, $c4, $a2, $28, $08, $af, $e0, $fe, $3e, $01, $cd
	db $f6, $46, $21, $fe, $ff, $34, $28, $05, $cd, $ae, $70, $18, $88, $af, $ea, $7b
	db $c2, $c9, $f0, $8c, $ea, $79, $c2, $cd, $8e, $01, $f0, $e8, $fe, $ff, $fa, $79
	db $c2, $c8, $e5, $21, $01, $ff, $b6, $e1, $c9, $f0, $e8, $fe, $ff, $28, $08, $f0
	db $8c, $e0, $01, $cd, $6c, $03, $c9, $cd, $e7, $02, $f0, $e8, $fe, $ff, $20, $07
	db $cd, $59, $01, $cd, $5e, $0e, $c9, $e1, $e1, $3e, $07, $cd, $f6, $46, $c3, $4b
	db $6f, $f0, $e8, $fe, $ff, $c8, $af, $e0, $e9, $3e, $c0, $e0, $ea, $af, $e0, $45
	db $3e, $40, $e0, $41, $21, $ff, $ff, $cb, $ce, $cd, $2f, $03, $21, $ff, $ff, $cb
	db $8e, $3e, $01, $e0, $e9, $3e, $09, $e0, $8b, $f0, $e8, $a7, $c8, $cd, $59, $01
	db $cd, $59, $01, $c9, $fb, $e5, $21, $ea, $ff, $34, $28, $02, $e1, $c9, $3e, $ff
	db $e0, $e8, $af, $e0, $01, $e0, $e9, $00, $cd, $4e, $02, $cd, $75, $02, $11, $ce
	db $71, $cd, $a6, $02, $3e, $83, $e0, $40, $3e, $01, $e0, $ff, $fb, $06, $40, $cd
	db $59, $01, $05, $20, $fa, $f5, $21, $7c, $c2, $2a, $66, $6f, $f1, $f9, $c3, $45
	db $6f

; Sound-test text and tilemap data.
	db $98, $21, $12, $b2, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0
	db $b0, $b0, $b0, $b0, $b3, $98, $41, $12, $b1, $90, $8a, $96, $8e, $a4, $96, $80
	db $8d, $8e, $a4, $9c, $8e, $95, $8e, $8c, $9d, $b1, $98, $61, $12, $b4, $b0, $b0
	db $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b5, $98
	db $c4, $0e, $81, $99, $a4, $97, $80, $9b, $96, $8a, $95, $a4, $90, $8a, $96, $8e
	db $99, $24, $0d, $81, $99, $a4, $8e, $a1, $9d, $9b, $8a, $a4, $90, $8a, $96, $8e
	db $99, $84, $07, $82, $99, $a4, $90, $8a, $96, $8e, $99, $e4, $0c, $96, $9e, $9c
	db $92, $8c, $a4, $9c, $8e, $95, $8e, $8c, $9d, $00, $98, $c2, $8a, $ab, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $a4, $00, $99, $01, $0f, $8c, $80, $96, $92, $97
	db $8c, $8a, $9d, $8e, $a4, $8e, $9b, $9b, $80, $9b, $99, $41, $0d, $99, $95, $8a
	db $9c, $8e, $a4, $9b, $8e, $9c, $9d, $8a, $9b, $9d, $00, $cd, $55, $75, $cd, $42
	db $02, $fd, $71, $fe, $71, $ee, $72, $c9, $cd, $a5, $45, $cd, $bb, $45, $cd, $4e
	db $02, $cd, $75, $02, $cd, $83, $01, $21, $2a, $78, $11, $14, $c1, $01, $24, $00
	db $cd, $93, $02, $af, $ea, $7e, $c2, $ea, $7f, $c2, $11, $4e, $78, $cd, $a6, $02
	db $11, $94, $78, $cd, $a6, $02, $3e, $83, $e0, $40, $fb, $cd, $59, $01, $11, $14
	db $c1, $cd, $a6, $02, $cd, $90, $48, $cd, $8e, $01, $fa, $7f, $c2, $a7, $28, $06
	db $cd, $b7, $76, $cd, $1d, $76, $f0, $8c, $47, $fa, $7e, $c2, $cb, $48, $20, $58
	db $cb, $40, $20, $0b, $cb, $78, $20, $27, $cb, $70, $20, $43, $c3, $31, $72, $cd
	db $59, $01, $11, $b4, $78, $cd, $a6, $02, $cd, $59, $01, $11, $d6, $78, $cd, $a6
	db $02, $3e, $01, $ea, $7f, $c2, $fa, $7e, $c2, $cd, $85, $46, $c3, $31, $72, $3c
	db $fe, $1e, $38, $01, $af, $ea, $7e, $c2, $21, $17, $c1, $3c, $cd, $04, $77, $fa
	db $7f, $c2, $a7, $ca, $31, $72, $fa, $7e, $c2, $cd, $85, $46, $c3, $31, $72, $3d
	db $fe, $1e, $38, $e1, $3e, $1d, $18, $dd, $fa, $7f, $c2, $a7, $28, $31, $af, $ea
	db $7f, $c2, $cd, $a5, $45, $cd, $83, $01, $cd, $59, $01, $11, $72, $78, $cd, $a6
	db $02, $cd, $59, $01, $11, $94, $78, $cd, $a6, $02, $c3, $31, $72, $cd, $59, $01
	db $11, $b4, $78, $cd, $a6, $02, $cd, $59, $01, $11, $d6, $78, $c3, $65, $72, $cd
	db $dc, $45, $cd, $3c, $45, $c3, $f1, $71, $cd, $a5, $45, $cd, $bb, $45, $cd, $4e
	db $02, $21, $00, $58, $11, $00, $84, $cd, $f6, $04, $cd, $75, $02, $cd, $83, $01
	db $11, $46, $79, $cd, $a6, $02, $21, $7a, $79, $11, $14, $c1, $01, $0a, $00, $cd
	db $93, $02, $3e, $83, $e0, $40, $fb, $21, $80, $c2, $3e, $ff, $06, $08, $22, $05
	db $20, $fc, $af, $ea, $7f, $c2, $ea, $7e, $c2, $af, $cd, $85, $46, $3e, $83, $e0
	db $40, $fb, $cd, $59, $01, $11, $14, $c1, $cd, $a6, $02, $cd, $90, $48, $cd, $8e
	db $01, $f0, $8c, $47, $cb, $40, $20, $54, $cb, $48, $20, $37, $cb, $78, $20, $0b
	db $cb, $70, $20, $23, $cb, $58, $20, $6a, $c3, $38, $73, $fa, $7e, $c2, $3c, $fe
	db $0d, $38, $01, $af, $ea, $7e, $c2, $cd, $85, $46, $fa, $7e, $c2, $21, $1b, $c1
	db $3c, $cd, $04, $77, $c3, $38, $73, $fa, $7e, $c2, $3d, $fe, $ff, $38, $e5, $3e
	db $0c, $18, $e1, $fa, $7f, $c2, $fe, $00, $ca, $f1, $71, $3d, $ea, $7f, $c2, $c6
	db $80, $ea, $17, $c1, $3e, $01, $cd, $f6, $46, $c3, $38, $73, $21, $80, $c2, $fa
	db $7f, $c2, $85, $6f, $3e, $00, $8c, $67, $fa, $7e, $c2, $77, $3e, $01, $cd, $f6
	db $46, $fa, $7f, $c2, $3c, $ea, $7f, $c2, $c6, $80, $ea, $17, $c1, $fe, $88, $c2
	db $38, $73, $fa, $7f, $c2, $a7, $ca, $ee, $72, $cd, $59, $01, $11, $14, $c1, $cd
	db $a6, $02, $cd, $f6, $76, $cd, $a5, $45, $cd, $bb, $45, $21, $00, $c0, $36, $58
	db $23, $36, $20, $23, $36, $ab, $23, $36, $00, $af, $ea, $8c, $c2, $cd, $59, $01
	db $cd, $90, $48, $cd, $8e, $01, $f0, $8c, $47, $e6, $c4, $20, $0c, $cb, $48, $c2
	db $ee, $72, $3e, $09, $a0, $20, $1c, $18, $e4, $fa, $8c, $c2, $ee, $01, $ea, $8c
	db $c2, $87, $87, $87, $4f, $87, $81, $c6, $58, $ea, $00, $c0, $3e, $01, $cd, $f6
	db $46, $18, $ca, $cd, $f6, $76, $cd, $bb, $45, $cd, $4e, $02, $cd, $75, $02, $cd
	db $83, $01, $11, $84, $79, $cd, $a6, $02, $21, $d9, $79, $11, $14, $c1, $01, $3d
	db $00, $cd, $93, $02, $cd, $09, $7b, $3e, $83, $e0, $40, $fb, $af, $ea, $7f, $c2
	db $fa, $7f, $c2, $fe, $08, $ca, $08, $75, $21, $80, $c2, $85, $6f, $3e, $00, $8c
	db $67, $7e, $ea, $7e, $c2, $fe, $ff, $ca, $08, $75, $4f, $af, $e0, $21, $e0, $1c
	db $79, $cd, $85, $46, $fa, $7f, $c2, $c6, $81, $ea, $4c, $c1, $fa, $7e, $c2, $3c
	db $21, $4e, $c1, $cd, $04, $77, $fa, $7e, $c2, $87, $21, $c1, $77, $85, $6f, $3e
	db $00, $8c, $67, $4e, $23, $46, $21, $88, $c2, $af, $22, $22, $22, $22, $c5, $cd
	db $59, $01, $11, $49, $c1, $cd, $a6, $02, $c1, $c5, $cd, $59, $01, $11, $14, $c1
	db $cd, $a6, $02, $cd, $90, $48, $cd, $8e, $01, $f0, $8c, $cb, $5f, $20, $4d, $f0
	db $8c, $cb, $57, $c2, $51, $75, $cd, $e7, $75, $cd, $1a, $77, $fa, $9b, $c2, $a7
	db $20, $0f, $21, $20, $d0, $2a, $66, $6f, $7e, $21, $8d, $c2, $86, $77, $cd, $09
	db $7b, $cd, $16, $7a, $c1, $0b, $78, $b1, $20, $bf, $fa, $7f, $c2, $3c, $ea, $7f
	db $c2, $cd, $a5, $45, $cd, $1a, $77, $06, $06, $cd, $59, $01, $05, $20, $fa, $c3
	db $56, $74, $fa, $8c, $c2, $a7, $ca, $f1, $71, $c3, $52, $74, $cd, $59, $01, $11
	db $b8, $79, $cd, $a6, $02, $f0, $8b, $cb, $47, $28, $0d, $fa, $02, $c0, $fe, $45
	db $20, $06, $11, $d1, $79, $cd, $a6, $02, $cd, $4b, $45, $cd, $59, $01, $cd, $8e
	db $01, $f0, $8c, $cb, $57, $c2, $51, $75, $cb, $5f, $28, $ef, $cd, $59, $01, $11
	db $c1, $79, $cd, $a6, $02, $cd, $3c, $45, $c3, $c5, $74, $c1, $c3, $f1, $71, $cd
	db $dc, $45, $cd, $4e, $02, $21, $00, $44, $11, $00, $84, $cd, $f6, $04, $cd, $75
	db $02, $cd, $83, $01, $11, $db, $77, $cd, $a6, $02, $af, $ea, $7e, $c2, $21, $00
	db $c0, $36, $48, $23, $36, $20, $23, $36, $ab, $23, $36, $00, $3e, $83, $e0, $40
	db $fb, $cd, $59, $01, $cd, $8e, $01, $cd, $90, $48, $f0, $8c, $47, $cb, $4f, $20
	db $25, $e6, $09, $20, $37, $78, $e6, $c4, $28, $0d, $fa, $7e, $c2, $ee, $01, $ea
	db $7e, $c2, $3e, $01, $cd, $f6, $46, $fa, $7e, $c2, $a7, $3e, $48, $28, $02, $3e
	db $68, $ea, $00, $c0, $18, $cb, $3e, $02, $cd, $f6, $46, $cd, $f6, $76, $cd, $83
	db $01, $cd, $a5, $45, $cd, $bb, $45, $af, $ea, $7e, $c2, $c9, $3e, $02, $cd, $f6
	db $46, $cd, $f6, $76, $cd, $f6, $76, $fa, $7e, $c2, $e6, $01, $3c, $ea, $7e, $c2
	db $c9, $21, $8a, $c2, $34, $7e, $fe, $3c, $30, $0e, $23, $34, $7e, $fe, $c8, $38
	db $05, $2b, $34, $23, $36, $00, $18, $0d, $36, $00, $2b, $34, $7e, $fe, $3c, $38
	db $04, $36, $00, $2b, $34, $21, $17, $c1, $fa, $88, $c2, $cd, $04, $77, $21, $1a
	db $c1, $fa, $89, $c2, $c3, $04, $77, $01, $00, $00, $f0, $25, $57, $f0, $22, $3c
	db $28, $11, $f0, $21, $e6, $f0, $cb, $37, $5f, $cb, $7a, $28, $01, $43, $cb, $5a
	db $28, $01, $4b, $f0, $1a, $cb, $7f, $28, $1b, $f0, $1c, $e6, $60, $28, $15, $cb
	db $37, $87, $5f, $af, $93, $5f, $cb, $72, $28, $03, $78, $83, $47, $cb, $52, $28
	db $03, $79, $83, $4f, $f0, $17, $e6, $f0, $cb, $37, $5f, $cb, $6a, $28, $03, $78
	db $83, $47, $cb, $4a, $28, $03, $79, $83, $4f, $f0, $12, $e6, $f0, $cb, $37, $5f
	db $cb, $62, $28, $03, $78, $83, $47, $cb, $42, $28, $03, $79, $83, $4f, $21, $27
	db $c1, $16, $0c, $3e, $4e, $cb, $38, $04, $05, $28, $06, $32, $15, $28, $08, $18
	db $f7, $3e, $4f, $32, $15, $20, $fc, $21, $36, $c1, $16, $0c, $3e, $4e, $cb, $39
	db $0c, $0d, $28, $06, $32, $15, $28, $08, $18, $f7, $3e, $4f, $32, $15, $20, $fc
	db $c9, $f5, $21, $1e, $d0, $2a, $66, $6f, $f1, $7e, $cb, $3f, $c6, $1e, $e0, $f0
	db $f5, $21, $20, $d0, $2a, $66, $6f, $f1, $7e, $cb, $3f, $c6, $18, $e0, $f1, $f0
	db $fa, $3c, $e0, $fa, $0f, $0f, $0f, $e6, $01, $f5, $21, $f6, $78, $cd, $b5, $04
	db $21, $f1, $ff, $3e, $a0, $96, $77, $f1, $c6, $02, $21, $f6, $78, $c3, $b5, $04
	db $3e, $14, $f5, $cd, $59, $01, $cd, $90, $48, $f1, $3d, $20, $f5, $c9, $c5, $0e
	db $00, $d6, $0a, $0c, $30, $fb, $c6, $0a, $47, $0d, $3e, $80, $81, $22, $3e, $80
	db $80, $22, $c1, $c9, $f0, $25, $4f, $3e, $11, $a1, $28, $1f, $fa, $1e, $d0, $21
	db $8e, $c2, $be, $77, $20, $0c, $fa, $8f, $c2, $a7, $28, $0f, $3d, $ea, $8f, $c2
	db $18, $09, $f0, $12, $e6, $f0, $cb, $37, $ea, $8f, $c2, $21, $26, $c1, $cd, $ad
	db $77, $3e, $22, $a1, $28, $25, $f0, $17, $e6, $f0, $cb, $37, $fa, $20, $d0, $21
	db $90, $c2, $be, $77, $20, $0c, $fa, $91, $c2, $a7, $28, $0f, $3d, $ea, $91, $c2
	db $18, $09, $f0, $17, $e6, $f0, $cb, $37, $ea, $91, $c2, $21, $31, $c1, $cd, $ad
	db $77, $3e, $44, $a1, $28, $14, $f0, $1a, $e6, $80, $28, $0e, $f0, $1c, $e6, $60
	db $28, $08, $47, $cb, $30, $cb, $38, $3e, $09, $90, $21, $3c, $c1, $cd, $ad, $77
	db $3e, $88, $a1, $28, $0c, $f0, $22, $d6, $ff, $28, $06, $f0, $21, $e6, $f0, $cb
	db $37, $21, $47, $c1, $c3, $ad, $77, $06, $08, $a7, $28, $08, $36, $4e, $2b, $3d
	db $05, $20, $f6, $c9, $36, $4f, $2b, $05, $20, $fa, $c9, $66, $06, $0c, $0f, $16
	db $18, $3a, $0a, $d4, $0c, $a0, $07, $94, $04, $3c, $04, $30, $18, $7c, $0e, $c2
	db $00, $c7, $00, $56, $00, $98, $23, $0d, $b2, $b0, $b0, $b0, $b0, $b0, $b0, $b0
	db $b0, $b0, $b0, $b0, $b3, $98, $43, $0d, $b1, $a4, $9c, $80, $9e, $97, $8d, $a4
	db $8b, $80, $a2, $a4, $b1, $98, $63, $0d, $b4, $b0, $b0, $b0, $b0, $b0, $b0, $b0
	db $b0, $b0, $b0, $b0, $b5, $98, $e5, $0b, $97, $80, $9b, $96, $8a, $95, $a4, $99
	db $95, $8a, $a2, $99, $65, $0c, $99, $9b, $80, $90, $9b, $8a, $96, $a4, $99, $95
	db $8a, $a2, $00, $00, $9a, $0d, $02, $80, $81, $98, $61, $8c, $4f, $4f, $4f, $4f
	db $4f, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $98, $72, $8c, $4f, $4f, $4f, $4f, $4f
	db $4f, $4f, $4f, $4f, $4f, $4f, $4f, $00, $9a, $04, $09, $9c, $80, $9e, $97, $8d
	db $a4, $97, $80, $a8, $98, $23, $0d, $b6, $a4, $9c, $80, $9e, $97, $8d, $a4, $8b
	db $80, $a2, $a4, $b6, $9a, $01, $01, $95, $9a, $12, $01, $9b, $99, $05, $09, $a9
	db $8a, $aa, $a4, $9c, $9d, $8a, $9b, $9d, $98, $01, $12, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $00, $98, $21
	db $12, $a4, $a4, $6d, $a4, $9c, $80, $9e, $97, $8d, $a4, $8b, $80, $a2, $a4, $6d
	db $a4, $a4, $a4, $99, $65, $07, $a9, $8b, $aa, $a4, $8e, $97, $8d, $00, $99, $05
	db $09, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $98, $01, $12, $6e, $5e, $5f
	db $5e, $5d, $6e, $5d, $6e, $5e, $5f, $5e, $5d, $6e, $5d, $6e, $5e, $5f, $6f, $00
	db $99, $65, $07, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $98, $21, $12, $7d, $7d, $7d
	db $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7d, $7e, $00
	db $fe, $78, $0f, $79, $20, $79, $31, $79, $02, $00, $12, $00, $00, $79, $42, $00
	db $00, $00, $12, $08, $00, $79, $44, $02, $00, $02, $20, $12, $00, $00, $79, $42
	db $00, $00, $00, $12, $08, $00, $79, $44, $02, $00, $02, $00, $12, $00, $00, $79
	db $42, $04, $00, $00, $12, $08, $00, $79, $44, $06, $00, $02, $20, $12, $00, $00
	db $79, $42, $04, $00, $00, $12, $08, $00, $79, $44, $06, $00, $68, $69, $78, $79
	db $98, $43, $0a, $99, $9b, $80, $90, $9b, $8a, $96, $a4, $97, $80, $98, $a3, $08
	db $9c, $80, $9e, $97, $8d, $a4, $97, $80, $99, $24, $0b, $9d, $91, $9b, $80, $90
	db $91, $a4, $99, $95, $8a, $a2, $99, $84, $0b, $9b, $8e, $99, $8e, $8a, $9d, $a4
	db $99, $95, $8a, $a2, $98, $4e, $01, $80, $98, $ad, $02, $80, $81, $00, $98, $22
	db $10, $a9, $9c, $9d, $8a, $9b, $9d, $aa, $a4, $9d, $80, $a4, $99, $8a, $9e, $9c
	db $8e, $98, $62, $0f, $a9, $9c, $8e, $95, $8e, $8c, $9d, $aa, $a4, $9d, $80, $a4
	db $8e, $97, $8d, $99, $0a, $01, $99, $99, $e1, $07, $8a, $a4, $8b, $a4, $8c, $a4
	db $8d, $00, $98, $2d, $05, $8c, $80, $97, $9d, $a4, $00, $98, $2d, $05, $99, $8a
	db $9e, $9c, $8e, $99, $ac, $04, $a4, $a4, $a4, $a4, $00, $99, $ac, $04, $8b, $9e
	db $a4, $a6, $00, $98, $ca, $05, $80, $80, $a8, $80, $80, $98, $c1, $88, $4f, $4f
	db $4f, $4f, $4f, $4f, $4f, $4f, $98, $c3, $88, $4f, $4f, $4f, $4f, $4f, $4f, $4f
	db $4f, $98, $c5, $88, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $4f, $98, $c7, $88, $4f
	db $4f, $4f, $4f, $4f, $4f, $4f, $4f, $00, $99, $0b, $04, $80, $a4, $80, $80, $00
	db $f0, $8b, $a7, $21, $93, $c2, $20, $02, $35, $c0, $fa, $c5, $d0, $87, $77, $23
	db $35, $28, $5e, $fa, $95, $c2, $3d, $cd, $42, $02, $36, $7a, $56, $7a, $64, $7a
	db $21, $99, $c2, $7e, $3d, $3d, $fe, $50, $30, $02, $3e, $90, $32, $e0, $f1, $2a
	db $e0, $f0, $23, $fa, $94, $c2, $e6, $01, $86, $21, $31, $7b, $cd, $b5, $04, $c9
	db $21, $99, $c2, $7e, $3c, $3c, $fe, $91, $38, $e2, $3e, $50, $18, $de, $fa, $98
	db $c2, $e0, $f0, $fa, $99, $c2, $e0, $f1, $fa, $94, $c2, $fe, $07, $30, $08, $fe
	db $03, $38, $04, $3e, $01, $18, $01, $af, $c6, $08, $21, $31, $7b, $cd, $b5, $04
	db $c9, $3e, $01, $ea, $9b, $c2, $f5, $21, $96, $c2, $2a, $66, $6f, $f1, $7e, $ea
	db $95, $c2, $cd, $42, $02, $a5, $7a, $b2, $7a, $b2, $7a, $cc, $7a, $e7, $7a, $21
	db $96, $c2, $3e, $01, $ea, $94, $c2, $af, $ea, $9b, $c2, $c9, $f5, $21, $96, $c2
	db $2a, $66, $6f, $f1, $23, $2a, $ea, $94, $c2, $f5, $7d, $ea, $96, $c2, $7c, $ea
	db $97, $c2, $f1, $c3, $29, $7a, $f5, $21, $96, $c2, $2a, $66, $6f, $f1, $23, $f5
	db $7d, $ea, $96, $c2, $7c, $ea, $97, $c2, $f1, $3e, $0a, $ea, $94, $c2, $c3, $29
	db $7a, $f5, $21, $96, $c2, $2a, $66, $6f, $f1, $23, $2a, $ea, $98, $c2, $2a, $ea
	db $99, $c2, $2a, $ea, $9a, $c2, $f5, $7d, $ea, $96, $c2, $7c, $ea, $97, $c2, $f1
	db $c3, $87, $7a, $e6, $07, $07, $21, $cd, $7b, $85, $6f, $3e, $00, $8c, $67, $2a
	db $66, $6f, $f5, $7d, $ea, $96, $c2, $7c, $ea, $97, $c2, $f1, $3e, $01, $ea, $94
	db $c2, $3e, $01, $ea, $93, $c2, $af, $ea, $9b, $c2, $c9, $67, $7b, $70, $7b, $79
	db $7b, $82, $7b, $8b, $7b, $94, $7b, $a6, $7b, $af, $7b, $45, $7b, $56, $7b, $02
	db $00, $21, $00, $00, $7b, $c1, $00, $00, $20, $21, $00, $08, $7b, $c1, $02, $00
	db $02, $00, $21, $00, $00, $7b, $c3, $00, $00, $20, $21, $00, $08, $7b, $c3, $02
	db $00, $01, $00, $22, $00, $00, $7b, $c5, $00, $00, $01, $00, $22, $00, $00, $7b
	db $c5, $00, $01, $01, $20, $22, $00, $00, $7b, $c5, $00, $00, $01, $20, $22, $00
	db $00, $7b, $c5, $00, $01, $01, $40, $22, $00, $00, $7b, $c5, $00, $00, $01, $40
	db $22, $00, $00, $7b, $c5, $00, $01, $01, $40, $22, $00, $00, $7b, $c5, $00, $02
	db $01, $60, $22, $00, $00, $7b, $c5, $00, $00, $01, $60, $22, $00, $00, $7b, $c5
	db $00, $01, $01, $60, $22, $00, $00, $7b, $c5, $00, $02, $44, $54, $45, $55, $46
	db $47, $56, $57, $46, $47, $48, $49, $dd, $7b, $e4, $7b, $eb, $7b, $f2, $7b, $f9
	db $7b, $0c, $7c, $1f, $7c, $25, $7c, $04, $88, $70, $00, $01, $20, $00, $04, $88
	db $70, $02, $02, $20, $00, $04, $88, $70, $02, $01, $20, $00, $04, $88, $70, $00
	db $02, $20, $00, $04, $88, $70, $00, $01, $10, $04, $60, $50, $06, $02, $20, $04
	db $88, $90, $00, $01, $10, $00, $04, $88, $70, $02, $02, $10, $04, $60, $90, $04
	db $01, $20, $04, $88, $50, $02, $02, $10, $00, $04, $88, $70, $10, $03, $00, $04
	db $88, $70, $00, $01, $10, $04, $88, $50, $02, $02, $20, $04, $88, $90, $00, $01
	db $10, $00, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $00, $00, $a4, $a4, $11, $12, $13, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $1b, $1c, $1d, $a4, $a4, $0d, $a4, $a4, $00, $00, $a4, $a4
	db $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $a4, $08, $09
	db $0a, $a4, $00, $00, $a4, $a4, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a
	db $3b, $3c, $3d, $a4, $18, $19, $1a, $a4, $00, $00, $a4, $40, $41, $42, $a4, $a4
	db $45, $46, $a4, $a4, $a4, $a4, $4b, $4c, $4d, $a4, $4f, $4e, $0b, $0c, $00, $00
	db $a4, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $a4, $5b, $5c, $5d, $5e
	db $5f, $1e, $1f, $a4, $00, $00, $a4, $60, $61, $62, $63, $64, $65, $66, $67, $68
	db $69, $6a, $6b, $6c, $6d, $6e, $6f, $2e, $2f, $a4, $00, $00, $a4, $70, $71, $72
	db $73, $74, $75, $76, $77, $78, $79, $7a, $7b, $7c, $7d, $7e, $7f, $3e, $3f, $a4
	db $00, $00, $a4, $a4, $10, $4a, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $01, $02, $a4, $00, $00, $a4, $a4, $20, $49, $a4, $99, $9e, $9c
	db $91, $a4, $9c, $9d, $8a, $9b, $9d, $a4, $03, $0e, $0f, $a4, $00, $00, $a4, $5a
	db $30, $48, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $04, $05, $06
	db $07, $a4, $00, $00, $00, $00, $44, $47, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $14, $15, $16, $17, $00, $00, $00, $a4, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $00, $00
	db $a4, $43, $81, $89, $88, $89, $a4, $93, $8a, $95, $8e, $8c, $80, $a4, $95, $9d
	db $8d, $a5, $a4, $a4, $00, $00, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $00, $00, $8a, $95, $95, $a4
	db $9b, $92, $90, $91, $9d, $9c, $a4, $9b, $8e, $9c, $8e, $9b, $9f, $8e, $8d, $a4
	db $00, $00, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4, $a4
	db $a4, $a4, $a4, $a4, $a4, $a4, $00, $00, $95, $92, $8c, $8e, $97, $9c, $8e, $8d
	db $a4, $8b, $a2, $a4, $97, $92, $97, $9d, $8e, $97, $8d, $80, $00, $00, $3e, $20
	db $ea, $28, $ce, $ea, $29, $ce, $ea, $2a, $ce, $ea, $2b, $ce, $ea, $2c, $ce, $3e
	db $10, $ea, $2e, $ce, $af, $ea, $21, $ce, $ea, $22, $ce, $ea, $23, $ce, $ea, $24
	db $ce, $ea, $26, $ce, $ea, $2d, $ce, $ea, $2f, $ce, $06, $48, $21, $4c, $c0, $36
	db $40, $23, $36, $34, $23, $70, $23, $22, $36, $48, $23, $36, $44, $23, $70, $23
	db $22, $36, $48, $23, $36, $64, $23, $70, $23, $22, $36, $40, $23, $36, $74, $23
	db $70, $23, $22, $06, $08, $3e, $38, $ea, $5c, $c0, $ea, $60, $c0, $ea, $8c, $c0
	db $ea, $90, $c0, $80, $ea, $64, $c0, $ea, $68, $c0, $ea, $6c, $c0, $ea, $70, $c0
	db $ea, $7c, $c0, $ea, $80, $c0, $ea, $94, $c0, $ea, $98, $c0, $80, $ea, $74, $c0
	db $ea, $78, $c0, $ea, $84, $c0, $ea, $88, $c0, $3e, $30, $ea, $5d, $c0, $ea, $65
	db $c0, $80, $ea, $61, $c0, $ea, $69, $c0, $80, $ea, $6d, $c0, $ea, $75, $c0, $80
	db $ea, $71, $c0, $ea, $79, $c0, $3e, $60, $ea, $7d, $c0, $ea, $85, $c0, $80, $ea
	db $81, $c0, $ea, $89, $c0, $80, $ea, $8d, $c0, $ea, $95, $c0, $80, $ea, $91, $c0
	db $ea, $99, $c0, $c9, $fa, $b4, $c2, $fe, $03, $38, $02, $d6, $03, $cb, $37, $11
	db $0b, $c4, $83, $5f, $26, $c0, $fa, $07, $c4, $6f, $2c, $2c, $c9, $fa, $b4, $c2
	db $3c, $c8, $fa, $00, $c4, $a7, $c8, $47, $cd, $8a, $7e, $2a, $4f, $2c, $2c, $2c
	db $e6, $0f, $fe, $0a, $30, $04, $79, $e6, $10, $12, $1c, $05, $20, $ed, $c9, $fa
	db $00, $c4, $a7, $c8, $47, $cd, $8a, $7e, $1a, $4f, $1c, $b6, $22, $2a, $2c, $2c
	db $e6, $03, $cb, $61, $28, $08, $e5, $21, $04, $c4, $85, $6f, $35, $e1, $05, $20
	db $e7, $c9, $21, $0b, $c4, $af, $06, $30, $22, $05, $20, $fc, $c9

; Unused padding to the end of the bank.
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
