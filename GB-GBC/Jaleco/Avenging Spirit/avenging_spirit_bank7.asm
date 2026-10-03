; =============================================================================
;  Avenging Spirit (UE) [!]  --  Jaleco Game Boy sound engine, ROM bank $7
; =============================================================================
;  Reverse-engineered disassembly. Reassembles byte-for-byte with RGBDS.
;
;  The same driver ships in Fortified Zone and Ikari no Yousai 2.
;
;  This is a LATER revision of the engine. The earliest known version is in
;  Hero Shuugou!! Pinball Party (1990); this 1992 build renumbered the whole
;  command set, cut the channel slots from 12 to 8, and swapped Pinball
;  Party's parametric envelopes for pointer-to-table envelopes.
;
;  Layout of this bank
;  -------------------
;    $4000-$40FF  Sound_Update           per-frame entry point
;    $4100-$42A3  note period table      (NoteTable proper starts at $411E)
;    $42A4-$4593  command interpreter and its handlers
;    $4594-$4747  public entry points, init, channel reset
;    $4748-$4ABA  channel processing, envelopes, register output
;    $4ABB-$4AE2  MusicHeaders, 20 songs
;    $4AE3-$4B08  SfxHeaders, 19 effects
;    $4B09-$4B28  two 16-byte wave patterns
;    $4B29-$4B57  five pitch-envelope tables
;    $4B58-$4B67  one volume-envelope table
;    $4B68-$7FFF  song / effect headers and sequence data
;
;  Channel slots
;  -------------
;    8 slots. Slots 0-3 are music, slots 4-7 are sound effects; slot n drives
;    hardware channel n & 3 (0 = pulse 1, 1 = pulse 2, 2 = wave, 3 = noise).
;    SFX outrank music for a given hardware channel.
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
DEF NOTE_C1 EQU $03
DEF NOTE_C2 EQU $04
DEF NOTE_C3 EQU $05
DEF NOTE_C4 EQU $06
DEF NOTE_C5 EQU $07
DEF NOTE_C6 EQU $08
DEF NOTE_C7 EQU $09
DEF NOTE_C8 EQU $0a
DEF NOTE_C9 EQU $0b
DEF NOTE_C12 EQU $0e
DEF NOTE_CSM1 EQU $10
DEF NOTE_CS0 EQU $11
DEF NOTE_CS1 EQU $12
DEF NOTE_CS2 EQU $13
DEF NOTE_CS3 EQU $14
DEF NOTE_CS4 EQU $15
DEF NOTE_CS5 EQU $16
DEF NOTE_CS6 EQU $17
DEF NOTE_CS7 EQU $18
DEF NOTE_CS9 EQU $1a
DEF NOTE_D1 EQU $21
DEF NOTE_D2 EQU $22
DEF NOTE_D3 EQU $23
DEF NOTE_D4 EQU $24
DEF NOTE_D5 EQU $25
DEF NOTE_D6 EQU $26
DEF NOTE_D7 EQU $27
DEF NOTE_D8 EQU $28
DEF NOTE_DSM1 EQU $2e
DEF NOTE_DS1 EQU $30
DEF NOTE_DS2 EQU $31
DEF NOTE_DS3 EQU $32
DEF NOTE_DS4 EQU $33
DEF NOTE_DS5 EQU $34
DEF NOTE_DS6 EQU $35
DEF NOTE_DS7 EQU $36
DEF NOTE_DS8 EQU $37
DEF NOTE_EM1 EQU $3d
DEF NOTE_E2 EQU $40
DEF NOTE_E3 EQU $41
DEF NOTE_E4 EQU $42
DEF NOTE_E5 EQU $43
DEF NOTE_E6 EQU $44
DEF NOTE_E7 EQU $45
DEF NOTE_E8 EQU $46
DEF NOTE_E9 EQU $47
DEF NOTE_E10 EQU $48
DEF NOTE_F2 EQU $4f
DEF NOTE_F3 EQU $50
DEF NOTE_F4 EQU $51
DEF NOTE_F5 EQU $52
DEF NOTE_F6 EQU $53
DEF NOTE_F7 EQU $54
DEF NOTE_F8 EQU $55
DEF NOTE_F12 EQU $59
DEF NOTE_FSM2 EQU $5a
DEF NOTE_FSM1 EQU $5b
DEF NOTE_FS3 EQU $5f
DEF NOTE_FS4 EQU $60
DEF NOTE_FS5 EQU $61
DEF NOTE_FS6 EQU $62
DEF NOTE_FS7 EQU $63
DEF NOTE_FS8 EQU $64
DEF NOTE_FS12 EQU $68
DEF NOTE_GM2 EQU $69
DEF NOTE_GM1 EQU $6a
DEF NOTE_G1 EQU $6c
DEF NOTE_G2 EQU $6d
DEF NOTE_G3 EQU $6e
DEF NOTE_G4 EQU $6f
DEF NOTE_G5 EQU $70
DEF NOTE_G6 EQU $71
DEF NOTE_G7 EQU $72
DEF NOTE_G8 EQU $73
DEF NOTE_G12 EQU $77
DEF NOTE_GS2 EQU $7c
DEF NOTE_GS3 EQU $7d
DEF NOTE_GS4 EQU $7e
DEF NOTE_GS5 EQU $7f
DEF NOTE_GS6 EQU $80
DEF NOTE_AM1 EQU $88
DEF NOTE_A0 EQU $89
DEF NOTE_A2 EQU $8b
DEF NOTE_A3 EQU $8c
DEF NOTE_A4 EQU $8d
DEF NOTE_A5 EQU $8e
DEF NOTE_A6 EQU $8f
DEF NOTE_A7 EQU $90
DEF NOTE_A8 EQU $91
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
DEF NOTE_CH2 EQU $b8

DEF SCMD_PANNING EQU $00
DEF SCMD_ENVELOPE EQU $01
DEF SCMD_VOLUME EQU $02
DEF SCMD_VOL_ENVELOPE EQU $03
DEF SCMD_PITCH_ENVELOPE EQU $04
DEF SCMD_GATE_FRAC EQU $05
DEF SCMD_GATE_ABS EQU $06
DEF SCMD_TRANSPOSE EQU $07
DEF SCMD_TEMPO EQU $08
DEF SCMD_GOTO EQU $09
DEF SCMD_SWEEP EQU $0a
DEF SCMD_TIMBRE EQU $0b
DEF SCMD_SET_LOOP EQU $0c
DEF SCMD_LOOP EQU $0d
DEF SCMD_STOP EQU $0e
DEF SCMD_CALL EQU $0f
DEF SCMD_RET EQU $10
DEF SCMD_DETUNE EQU $11
DEF SCMD_SWEEP_OFF EQU $12
DEF SCMD_VOL_MODE_OFF EQU $13

DEF wSfxRequest EQU $cc80
DEF wSfxIdCopy EQU $cc81
DEF wChanAdvanced EQU $cc82
DEF wChanGateMode EQU $cc8a
DEF wSweepDirty EQU $cc92
DEF wChanSeqPtr EQU $cc94
DEF wSfxSeqPtr EQU $cc9c
DEF wChanEnvVol EQU $cca4
DEF wSoundOnFlag EQU $cca6
DEF wChanEnvDir EQU $ccac
DEF wChanEnvPeriod EQU $ccb4
DEF wChanGateFrac EQU $ccbc
DEF wChanGateAbs EQU $ccc4
DEF wChanTranspose EQU $cccc
DEF wChanPanning EQU $ccd4
DEF wSweepParams EQU $ccdc
DEF wChanTempo EQU $cce2
DEF wChanVolume EQU $ccea
DEF wChanTimbre EQU $ccf2
DEF wChanLoopCtr EQU $cd02
DEF wChanCallStack EQU $cd32
DEF wChanCallDepth EQU $cd62
DEF wChanDetuneSign EQU $cd6a
DEF wChanDetune EQU $cd72
DEF wSavedNR51 EQU $cd7a
DEF wCurMusicId EQU $cd7b
DEF wChanVolEnvPtr EQU $cd91
DEF wChanVolEnvIdx EQU $cda1
DEF wChanVolEnvTimer EQU $cda9
DEF wChanPitchEnvPtr EQU $cdb1
DEF wChanPitchEnvIdx EQU $cdc1
DEF wChanPeriod EQU $cdc9
DEF wChanPitchEnvTimer EQU $cdd9
DEF wSndFlagE1 EQU $cde1
DEF wSndFlagE2 EQU $cde2
DEF hSndChan EQU $ff98
DEF hSndActiveMask EQU $ff99
DEF hSndMaskShift EQU $ff9a
DEF hSndHwChan EQU $ff9b
DEF hSndFreqReg EQU $ff9c
DEF hSndFrameBudget EQU $ff9d
DEF hChanNoteTimer EQU $ff9e
DEF hMusicMask EQU $ffa6
DEF hMusicMaskLatch EQU $ffa7
DEF hSfxMask EQU $ffa8
DEF hSfxMaskLatch EQU $ffa9
DEF hChanGateTimer EQU $ffaa
DEF hChanVolMode EQU $ffae

SECTION "Sound Engine Bank $7", ROMX[$4000], BANK[$7]

; Per-frame driver tick. Called from bank 0 every frame while
; ROM bank $7 is paged in ($05CF in bank 0).

Sound_Update:
	xor a
	ld e,a
	inc a
	inc a
	ldh [hSndFrameBudget],a
	ld hl,wChanSeqPtr

Loc_4009:
	push hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld a,e
	cp $08
	jp z,Sound_UpdateChannels
	xor a
	cp h
	jr z,Loc_4042
	ld d,a
	dec a
	cp [hl]
	jr z,Loc_4048
	ld hl,hChanNoteTimer
	add hl,de
	xor a
	cp [hl]
	jr nz,Loc_4042
	ld hl,wChanAdvanced
	add hl,de
	inc a
	cp [hl]
	jr z,Loc_4042
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
	jr z,Loc_4048
	ld b,h
	ld c,l
	ld hl,wChanSeqPtr
	add hl,de
	add hl,de
	ld a,c
	ld [hl+],a
	ld [hl],b

Loc_4042:
	inc e
	pop hl
	inc hl
	inc hl
	jr Loc_4009

Loc_4048:
	ld a,e
	ldh [hSndChan],a

Loc_404b:
	call Sound_ExecCommand
	ld a,[hl]
	inc a
	jr z,Loc_404b
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
	jp Loc_4009

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

Loc_407d:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_407d
	ldh a,[hMusicMaskLatch]
	and a
	jr z,Loc_40b8
	rra
	ldh [hSndMaskShift],a
	ldh a,[hMusicMask]
	ldh [hSndActiveMask],a
	jr nc,Loc_4096
	xor a
	call Sound_DoChannel1

Loc_4096:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40a2
	ld a,$01
	call Sound_DoChannel2

Loc_40a2:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40ae
	ld a,$02
	call Sound_DoChannel3

Loc_40ae:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_40b8
	ld a,$03
	call Sound_DoChannel4

Loc_40b8:
	ldh a,[hSfxMask]
	ld b,a
	ldh a,[hSfxMaskLatch]
	or b
	jr z,Loc_40ef
	rra
	ldh [hSndMaskShift],a
	ld a,b
	ldh [hSndActiveMask],a
	jr nc,Loc_40cd
	ld a,$04
	call Sound_DoChannel1

Loc_40cd:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40d9
	ld a,$05
	call Sound_DoChannel2

Loc_40d9:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40e5
	ld a,$06
	call Sound_DoChannel3

Loc_40e5:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_40ef
	ld a,$07
	call Sound_DoChannel4

Loc_40ef:
	ldh a,[hMusicMask]
	ld b,a
	ldh a,[hSfxMask]
	or b
	ld b,a
	swap a
	or b
	ld b,a
	ldh a,[rNR51]
	and b
	ldh [rNR51],a
	ret

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
;      [hSndChan] = channel slot (0-7)
; Out: hl = stream pointer just past the command

Sound_ExecCommand:
	inc hl
	ld a,[hl+]
	and a
	jr z,Cmd_Panning
	dec a
	jp z,Cmd_Envelope
	dec a
	jp z,Cmd_Volume
	ld b,a
	ldh a,[hSndFrameBudget]
	and a
	jr z,Loc_42ba
	dec a
	ldh [hSndFrameBudget],a

Loc_42ba:
	dec b
	jp z,Cmd_VolEnvelope
	dec b
	jp z,Cmd_PitchEnvelope
	dec b
	jr z,Cmd_GateFrac
	dec b
	jr z,Cmd_GateAbs
	dec b
	jr z,Cmd_Transpose
	dec b
	jr z,Cmd_Tempo
	dec b
	jp z,Cmd_Goto
	dec b
	jp z,Cmd_Sweep
	dec b
	jp z,Cmd_Timbre
	dec b
	jp z,Cmd_SetLoop
	dec b
	jp z,Cmd_Loop
	dec b
	jp z,Cmd_Stop
	dec b
	jp z,Cmd_Call
	dec b
	jp z,Cmd_Return
	dec b
	jr z,Cmd_Detune
	dec b
	jr z,Cmd_SweepOff
	jp Cmd_VolModeOff

Cmd_SweepOff:
	ldh a,[hSndChan]
	and $03
	ret nz
	ld bc,wSweepDirty
	ldh a,[hSndChan]
	and $04
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

Cmd_Panning:
	ld bc,wChanPanning
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

Cmd_GateFrac:
	ld d,b
	ld b,h
	ld c,l
	ld hl,wChanGateFrac
	call Sound_StoreGateValue
	ld a,$01
	jr Loc_433f

Cmd_GateAbs:
	ld d,b
	ld b,h
	ld c,l
	ld hl,wChanGateAbs
	call Sound_StoreGateValue
	xor a

Loc_433f:
	ld hl,wChanGateMode
	add hl,de
	ld [hl],a
	inc bc
	ld h,b
	ld l,c
	ret

Sound_StoreGateValue:
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[bc]
	ld [hl],a
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
	jr nc,Loc_4370
	xor a
	ld [de],a
	ld a,[hl+]
	cpl
	inc a
	ld [bc],a
	ret

Loc_4370:
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
	jr z,Loc_439b
	ld e,a
	xor a

Loc_4396:
	add a,$04
	dec e
	jr nz,Loc_4396

Loc_439b:
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
	jr z,Loc_43b7
	ld e,a
	xor a

Loc_43b2:
	add a,$04
	dec e
	jr nz,Loc_43b2

Loc_43b7:
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
	jr nz,Loc_43ca
	inc hl
	inc hl
	ret

Loc_43ca:
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

Cmd_VolEnvelope:
	ld d,b
	ld b,h
	ld c,l
	ldh a,[hSndChan]
	add a,a
	ld e,a
	ld hl,wChanVolEnvPtr
	add hl,de
	ld a,[bc]
	ld [hl+],a
	inc bc
	ld a,[bc]
	ld [hl],a
	ld hl,hChanVolMode
	srl e
	add hl,de
	ld [hl],$02
	inc bc
	ld h,b
	ld l,c
	ret

Cmd_Envelope:
	ld d,a
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
	inc bc
	ld h,b
	ld l,c
	ret

Cmd_Sweep:
	ldh a,[hSndChan]
	and $03
	jr nz,Loc_4474
	ld d,a
	ld b,h
	ld c,l
	ld hl,wSweepParams
	ldh a,[hSndChan]
	and $04
	rrca
	rrca
	ld e,a
	add hl,de
	ld a,[bc]
	ld [hl],a
	inc bc
	ld e,$02
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
	and $04
	rrca
	rrca
	ld e,a
	add hl,de
	ld [hl],$01
	ld h,b
	ld l,c
	ret

Loc_4474:
	inc hl
	inc hl
	inc hl
	ret

Cmd_PitchEnvelope:
	ld d,b
	ld b,h
	ld c,l
	ldh a,[hSndChan]
	add a,a
	ld e,a
	ld hl,wChanPitchEnvPtr
	add hl,de
	ld a,[bc]
	ld [hl+],a
	inc bc
	ld a,[bc]
	ld [hl],a
	ld hl,hChanVolMode
	srl e
	add hl,de
	ld [hl],$03
	inc bc
	ld h,b
	ld l,c
	ret

Cmd_VolModeOff:
	ldh a,[hSndChan]
	ld de,hChanVolMode
	add a,e
	ld e,a
	ld a,$00
	adc a,d
	ld d,a
	xor a
	ld [de],a
	ret

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
	jr nz,Loc_44bc
	ld a,[hl+]
	ld [bc],a
	inc bc
	ld a,[hl+]
	ld [bc],a
	ret

Loc_44bc:
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
	ld a,[hl+]
	swap a
	ld [bc],a
	ld c,$ae
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
	jr c,Loc_4527
	rlca
	jr c,Loc_4501
	ldh a,[hSndChan]
	and $03
	jr z,Loc_44f5

Loc_44f0:
	rlc b
	dec a
	jr nz,Loc_44f0

Loc_44f5:
	ldh a,[hMusicMask]
	and b
	ldh [hMusicMask],a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMaskLatch],a
	jr Loc_4527

Loc_4501:
	ldh a,[hSndChan]
	and $03
	jr z,Loc_450c

Loc_4507:
	rlc b
	dec a
	jr nz,Loc_4507

Loc_450c:
	ldh a,[hSfxMask]
	and b
	ldh [hSfxMask],a
	ldh a,[hSfxMaskLatch]
	and b
	ldh [hSfxMaskLatch],a
	ldh a,[hSfxMask]
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
	jr Loc_4527

Loc_4527:
	ldh a,[hSndChan]
	and $03
	jr z,Sound_SilenceCh1
	dec a
	jr z,Sound_SilenceCh2
	dec a
	jr z,Sound_SilenceCh3

Sound_SilenceCh4:
	xor a
	ldh [$ffad],a
	ld a,$08
	ldh [rNR42],a
	ld a,$80
	ldh [rNR44],a
	ret

Sound_SilenceCh1:
	xor a
	ldh [hChanGateTimer],a
	ldh [rNR10],a
	ld a,$08
	ldh [rNR12],a
	ld a,$80
	ldh [rNR14],a
	ret

Sound_SilenceCh2:
	xor a
	ldh [$ffab],a
	ld a,$08
	ldh [rNR22],a
	ld a,$80
	ldh [rNR24],a
	ret

Sound_SilenceCh3:
	xor a
	ldh [$ffac],a
	ldh [rNR32],a
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
	db $fa

; Save NR51 and silence all output.

Sound_Mute:
	and [hl]
	call z,$c8a7
	ldh a,[rNR51]
	ld [wSavedNR51],a
	xor a
	ldh [rNR51],a
	ld [wSoundOnFlag],a
	ret

; Silence and clear the four music slots (0-3).

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

; Silence and clear the four SFX slots (4-7); hand the
; hardware channels back to the music slots.

Sound_StopSfx:
	ldh a,[hSfxMask]
	call Sound_SilenceChannels
	ldh a,[hMusicMaskLatch]
	ldh [hMusicMask],a
	xor a
	ldh [hSfxMask],a
	ldh [hSfxMaskLatch],a
	ld hl,wSfxSeqPtr
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ret

; Cold-start the driver: clear all channel state, master
; volume to $77, sound enabled.

Sound_Init:
	ld hl,wSfxRequest
	ld b,$3e
	xor a

Loc_45ca:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45ca
	ld hl,hChanNoteTimer
	ld b,$0c

Loc_45d8:
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45d8
	dec a
	ld [wSoundOnFlag],a
	ld a,$77
	ldh [rNR50],a
	xor a
	ld [wSndFlagE2],a
	ld [wSndFlagE1],a
	ret

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

; In: a = song id (0-19). Loads MusicHeaders[a] into slots 0-3.

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
	jr z,Loc_4698
	xor a
	ldh [rNR10],a

Loc_4698:
	ld de,$cc96
	pop hl
	push hl
	ld a,$02
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$cc98
	pop hl
	push hl
	ld a,$04
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$cc9a
	pop hl
	ld a,$06
	ldh [hSndChan],a
	ld a,$08
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ldh a,[hMusicMask]
	ldh [hMusicMaskLatch],a
	ld b,a
	ldh a,[hSfxMask]
	cpl
	and b
	ldh [hMusicMask],a
	ret

; In: a = sfx id (0-18). Loads SfxHeaders[a] into slots 4-7.

Sound_PlaySfx:
	ld [wSfxRequest],a
	xor a
	ldh [hSfxMask],a
	ldh [hSfxMaskLatch],a
	ldh [$ffa2],a
	ldh [$ffa3],a
	ldh [$ffa4],a
	ldh [$ffa5],a
	ld bc,$0004
	ld de,$0001
	call Sound_ResetChannelGroup
	ld de,wSfxSeqPtr
	ld hl,SfxHeaders
	ld a,[wSfxRequest]
	ld [wSfxIdCopy],a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	push hl
	ld bc,hSfxMask
	ld a,$01
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	jr z,Loc_4709
	xor a
	ldh [rNR10],a

Loc_4709:
	ld de,$cc9e
	pop hl
	push hl
	ld a,$02
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$cca0
	pop hl
	push hl
	ld a,$04
	ldh [hSndChan],a
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	ld de,$cca2
	pop hl
	push hl
	ld a,$06
	ldh [hSndChan],a
	ld a,$08
	ldh [hSndActiveMask],a
	call Sound_LoadChannel
	pop hl
	xor a
	ldh [hSfxMaskLatch],a
	ld a,$01
	ld [wSfxRequest],a
	ldh a,[hSfxMask]
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
	jr z,Loc_4754

Loc_4750:
	inc hl
	dec a
	jr nz,Loc_4750

Loc_4754:
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
	ld a,$22
	ldh [hSndFreqReg],a
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
	jp nz,Sound_TickChannel
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
	jr nc,Loc_47ad
	ld a,b

Loc_47ad:
	sla b
	sra c
	jr nc,Loc_47b4
	add a,b

Loc_47b4:
	sla b
	sra c
	jr nc,Loc_47bb
	add a,b

Loc_47bb:
	pop bc
	cp d
	jr nz,Loc_47c0
	inc a

Loc_47c0:
	ldh [c],a
	ldh a,[hSndHwChan]
	ld b,a
	ldh a,[hSndActiveMask]

Loc_47c6:
	rra
	dec b
	jr nz,Loc_47c6
	jp nc,Sound_TickChannel
	dec hl
	push hl
	ld hl,wChanGateMode
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	xor a
	cp [hl]
	jr nz,Loc_47f8
	ld hl,wChanGateFrac
	add hl,bc
	ld a,[hl]
	ld hl,hChanNoteTimer
	add hl,bc
	ld e,[hl]
	ld h,b
	ld l,b
	ld d,b

Loc_47e7:
	add hl,de
	dec a
	jr nz,Loc_47e7
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	inc a
	jr Loc_4816

Loc_47f8:
	ld hl,wChanTempo
	add hl,bc
	ld e,[hl]
	ld hl,wChanGateAbs
	add hl,bc
	ld d,[hl]
	xor a
	sra e
	jr nc,Loc_4808
	ld a,d

Loc_4808:
	sla d
	sra e
	jr nc,Loc_480f
	add a,d

Loc_480f:
	sla d
	sra e
	jr nc,Loc_4816
	add a,d

Loc_4816:
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
	jr nz,Loc_4840
	ldh a,[hSndChan]
	and $04
	rrca
	rrca
	ld e,a
	ld hl,wSweepDirty
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_4840
	ld hl,wSweepParams
	add hl,de
	ld de,$0002
	ld c,$10
	call Sound_WriteEnvelopeReg

Loc_4840:
	ld hl,wChanTimbre
	ldh a,[hSndChan]
	ld e,a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	ld a,e
	and $03
	jr z,Loc_4875
	dec a
	jr z,Loc_487a
	dec a
	jr nz,Loc_487f
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld c,$30
	xor a
	ldh [rNR30],a
	ld d,$04

Loc_4860:
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
	jr nz,Loc_4860
	ld a,$80
	ldh [rNR30],a
	jr Loc_487f

Loc_4875:
	ld a,[hl]
	ldh [rNR11],a
	jr Loc_487f

Loc_487a:
	ld a,[hl]
	ldh [rNR21],a
	ld d,$00

Loc_487f:
	ld c,$ae
	ldh a,[hSndChan]
	ld e,a
	add a,c
	ld c,a
	ldh a,[c]
	dec a
	jr z,Loc_489c
	dec a
	jr z,Loc_48bb
	dec a
	jr z,Loc_48af

Loc_4890:
	ld hl,wChanVolume
	add hl,de
	ldh a,[hSndFreqReg]
	dec a
	ld c,a
	ld a,[hl]
	ldh [c],a
	jr Loc_48c5

Loc_489c:
	ld a,e
	and $03
	ldh a,[hSndFreqReg]
	dec a
	ld c,a
	ld hl,wChanEnvVol
	add hl,de
	ld de,$0008
	call Sound_WriteEnvelopeReg
	jr Loc_48c5

Loc_48af:
	ld hl,wChanPitchEnvIdx
	add hl,de
	ld [hl],d
	ld hl,wChanPitchEnvTimer
	add hl,de
	ld [hl],d
	jr Loc_4890

Loc_48bb:
	ld hl,wChanVolEnvIdx
	add hl,de
	ld [hl],d
	ld hl,wChanVolEnvTimer
	add hl,de
	ld [hl],d

Loc_48c5:
	pop hl
	ld b,[hl]
	ld a,$b8
	cp b
	jp z,Loc_4927
	ldh a,[hSndHwChan]
	cp $04
	jr z,Loc_4931
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
	jr z,Loc_493a
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
	jr z,Loc_491d
	ld h,b
	ld l,b
	ld d,b

Loc_490f:
	add hl,de
	dec c
	jr nz,Loc_490f
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra

Loc_491d:
	pop de
	ld b,a
	ld a,e
	sub b
	ld e,a
	ld a,d
	sbc a,c
	ld d,a
	jr Loc_4963

Loc_4927:
	ldh a,[hSndHwChan]
	ld c,$a9
	add a,c
	ld c,a
	xor a
	ldh [c],a
	jr Sound_TickChannel

Loc_4931:
	ld a,b
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	jr Loc_4978

Loc_493a:
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
	jr z,Loc_495f
	ld d,b

Loc_4950:
	add hl,de
	dec c
	jr nz,Loc_4950
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	ld l,a

Loc_495f:
	pop de
	add hl,de
	ld d,h
	ld e,l

Loc_4963:
	ldh a,[hSndFreqReg]
	ld c,a
	ld a,e
	ldh [c],a
	inc c
	ld a,d
	ldh [c],a
	ld hl,wChanPeriod
	ldh a,[hSndChan]
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	ld a,d
	ld [hl+],a
	ld [hl],e

Loc_4978:
	ld hl,wChanPanning
	ld d,$00
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[hl]
	dec a
	jr z,Loc_498c
	dec a
	jr z,Loc_4990
	ld d,$11
	jr Loc_4991

Loc_498c:
	ld d,$10
	jr Loc_4991

Loc_4990:
	inc d

Loc_4991:
	ld b,$ee
	ld a,e
	and $03
	jr z,Loc_499f

Loc_4998:
	rlc b
	rlc d
	dec a
	jr nz,Loc_4998

Loc_499f:
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

Loc_49b4:
	rra
	dec d
	jr nz,Loc_49b4
	ret nc
	ld hl,hChanGateTimer
	ld a,c
	and $03
	ld e,a
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_49d7
	dec a
	cp [hl]
	ret z
	dec [hl]
	ld a,$ae
	add a,c
	ld c,a
	ldh a,[c]
	dec a
	dec a
	jp z,Sound_VolEnvelopeStep
	dec a
	jr z,Sound_PitchEnvelopeStep
	ret

Loc_49d7:
	dec [hl]
	ld a,e
	cp d
	jr z,Loc_49eb
	dec a
	jr z,Loc_49f4
	dec a
	jr z,Loc_49fd
	ld a,$08
	ldh [rNR42],a
	ld a,$80
	ldh [rNR44],a
	ret

Loc_49eb:
	ld a,$08
	ldh [rNR12],a
	ld a,$80
	ldh [rNR14],a
	ret

Loc_49f4:
	ld a,$08
	ldh [rNR22],a
	ld a,$80
	ldh [rNR24],a
	ret

Loc_49fd:
	ldh [rNR32],a
	ret

Sound_PitchEnvelopeStep:
	ld b,a
	ld hl,wChanPitchEnvTimer
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	ld a,[hl]
	and a
	jr z,Loc_4a0e
	dec [hl]
	ret

Loc_4a0e:
	ld hl,wChanPeriod
	sla c
	add hl,bc
	ld a,[hl+]
	ld d,a
	ld e,[hl]
	push de
	ld hl,wChanPitchEnvPtr
	add hl,bc
	ld a,[hl+]
	ld e,a
	ld d,[hl]
	srl c
	ld hl,wChanPitchEnvIdx
	add hl,bc
	ld a,[hl]
	inc [hl]
	inc [hl]
	add a,e
	ld e,a
	ld a,$00
	adc a,d
	ld d,a
	ld a,[de]
	ld b,a
	inc de
	ld a,[de]
	ld c,a
	inc de
	ld a,[de]
	cp $80
	jr nz,Loc_4a3c
	inc de
	ld a,[de]
	ld [hl],a

Loc_4a3c:
	ld hl,wChanPitchEnvTimer
	ldh a,[hSndChan]
	ld e,a
	ld d,$00
	add hl,de
	ld [hl],c
	pop de
	ldh a,[hSndFreqReg]
	ld c,a
	bit 7,b
	jr z,Loc_4a5a
	ld a,b
	cpl
	ld b,a
	ld a,e
	sub b
	ldh [c],a
	ld a,d
	sbc a,$00
	inc c
	ldh [c],a
	ret

Loc_4a5a:
	ld a,e
	add a,b
	ldh [c],a
	ld a,d
	adc a,$00
	inc c
	ldh [c],a
	ret

Sound_VolEnvelopeStep:
	ld b,a
	ld hl,wChanVolEnvTimer
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	ld a,[hl]
	and a
	jr z,Loc_4a71
	dec [hl]
	ret

Loc_4a71:
	ld hl,wChanVolEnvPtr
	add hl,bc
	add hl,bc
	ld a,[hl+]
	ld e,a
	ld d,[hl]
	ld hl,wChanVolEnvIdx
	add hl,bc
	ld a,[hl]
	inc [hl]
	inc [hl]
	add a,e
	ld e,a
	ld a,$00
	adc a,d
	ld d,a
	ldh a,[hSndFreqReg]
	dec a
	ld c,a
	ld a,[de]
	swap a
	ldh [c],a
	inc de
	ld a,[de]
	ld b,a
	inc de
	ld a,[de]
	cp $f0
	jr nz,Loc_4a9a
	inc de
	ld a,[de]
	ld [hl],a

Loc_4a9a:
	ld hl,wChanVolEnvTimer
	ldh a,[hSndChan]
	ld e,a
	ld d,$00
	add hl,de
	ld [hl],b
	ld hl,wChanPeriod
	sla e
	add hl,de
	ld a,[hl+]
	inc c
	inc c
	ldh [c],a
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
	dw MusicHeader_13	; 13
	dw MusicHeader_14	; 14
	dw MusicHeader_15	; 15
	dw MusicHeader_16	; 16
	dw MusicHeader_17	; 17
	dw MusicHeader_18	; 18
	dw MusicHeader_19	; 19

SfxHeaders:
	dw SfxHeader_00	; 0
	dw SfxHeader_01	; 1
	dw SfxHeader_02	; 2
	dw SfxHeader_03	; 3
	dw SfxHeader_04	; 4
	dw SfxHeader_05	; 5
	dw SfxHeader_05	; 6
	dw SfxHeader_07	; 7
	dw SfxHeader_08	; 8
	dw SfxHeader_09	; 9
	dw SfxHeader_10	; 10
	dw SfxHeader_11	; 11
	dw SfxHeader_12	; 12
	dw SfxHeader_13	; 13
	dw SfxHeader_14	; 14
	dw SfxHeader_14	; 15
	dw SfxHeader_16	; 16
	dw SfxHeader_17	; 17
	dw SfxHeader_18	; 18

WavePattern0:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $ed, $cb, $a9, $87, $65, $43, $21, $00

WavePattern1:
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $22, $22, $21, $21, $21, $00, $00, $00

PitchEnv0:
	db $00
	db $05
	db $01
	db $03
	db $ff
	db $03
	db $80
	db $01

PitchEnv1:
	db $00
	db $03
	db $02
	db $07
	db $03
	db $02
	db $fd
	db $02
	db $80
	db $04

PitchEnv2:
	db $00
	db $02
	db $ff
	db $08
	db $02
	db $09
	db $80
	db $00

PitchEnv3:
	db $cd
	db $01
	db $00
	db $04
	db $ff
	db $07
	db $80
	db $02

PitchEnv4:
	db $ce
	db $01
	db $83
	db $01
	db $14
	db $01
	db $32
	db $01
	db $46
	db $01
	db $78
	db $01
	db $ff

VolEnv0:
	db $0f
	db $02
	db $00
	db $01
	db $08
	db $01
	db $00
	db $01
	db $05
	db $01
	db $00
	db $01
	db $03
	db $01
	db $00, $ff

MusicHeader_00:
	dw Music00_Ch1	; channel 1
	dw Music00_Ch2	; channel 2
	dw Music00_Ch3	; channel 3
	dw Music00_Ch4	; channel 4

Music00_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_4b77:
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TRANSPOSE, $02	; +2 octave slots
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_4b8a:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A3,    $02	; A3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A3,    $02	; A3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4b8a
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_CALL
	dw Seq_4cda
	db $ff, SCMD_CALL
	dw Seq_4cda
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $0c	; slot 0 = 12

Seq_4c8a:
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db REST,       $02	; rest, 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $06	; G5, len 6
	db REST,       $02	; rest, 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4c8a
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db NOTE_AS5,   $04	; A#5, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS6,   $04	; A#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS6,   $04	; A#6, len 4
	db REST,       $04	; rest, 4
	db NOTE_AS6,   $04	; A#6, len 4
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $02	; B4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_GOTO
	dw Seq_4b77

Seq_4cda:
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_4cde:
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4cde
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_4cf9:
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_G2,    $02	; G2, len 2
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4cf9
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E3,    $04	; E3, len 4
	db $ff, SCMD_SWEEP_OFF
	db REST,       $0c	; rest, 12
	db $ff, SCMD_RET

Music00_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_4d50:
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $09, $00, $05	; volume 9, down, period 5
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_4ed1
	db $ff, SCMD_CALL
	dw Seq_4ed1
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_4d6f:
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOLUME, $07	; volume 7
	db $ff, SCMD_PITCH_ENVELOPE, $3b, $4b
	db $ff, SCMD_CALL
	dw Seq_4f87
	db NOTE_A4,    $10	; A4, len 16
	db REST,       $04	; rest, 4
	db $ff, SCMD_CALL
	dw Seq_4f87
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $14	; G4, len 20
	db REST,       $0c	; rest, 12
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $14	; D4, len 20
	db REST,       $2c	; rest, 44
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4d6f
	db $ff, SCMD_VOLUME, $07	; volume 7
	db $ff, SCMD_PITCH_ENVELOPE, $31, $4b
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $08	; A#4, len 8
	db REST,       $04	; rest, 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_C4,    $08	; C4, len 8
	db REST,       $04	; rest, 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $00, $01, $02	; volume 0, up, period 2
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D6,    $06	; D6, len 6
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_CALL
	dw Seq_4f49
	db $ff, SCMD_ENVELOPE, $00, $01, $02	; volume 0, up, period 2
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_CALL
	dw Seq_4f7a
	db $ff, SCMD_CALL
	dw Seq_4f49
	db $ff, SCMD_ENVELOPE, $00, $01, $02	; volume 0, up, period 2
	db NOTE_F5,    $08	; F5, len 8
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db $ff, SCMD_CALL
	dw Seq_4f49
	db $ff, SCMD_ENVELOPE, $00, $01, $02	; volume 0, up, period 2
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_CALL
	dw Seq_4f7a
	db NOTE_AS4,   $08	; A#4, len 8
	db NOTE_AS5,   $08	; A#5, len 8
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS5,   $08	; A#5, len 8
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db $ff, SCMD_PANNING, $01	; left
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $02	; B4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_GOTO
	dw Seq_4d50

Seq_4ed1:
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $04	; A4, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_RET

Seq_4f49:
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_4f52:
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4f52
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_RET

Seq_4f7a:
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db $ff, SCMD_RET

Seq_4f87:
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_RET

Music00_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo

Seq_4fb2:
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_4fb9:
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_4fb9
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $04	; rest, 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $08	; C5, len 8
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_CALL
	dw Seq_50cb
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_CALL
	dw Seq_50cb
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db REST,       $08	; rest, 8
	db NOTE_D5,    $04	; D5, len 4
	db REST,       $04	; rest, 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_CALL
	dw Seq_5147
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_CALL
	dw Seq_5147
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_CALL
	dw Seq_5147
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db REST,       $18	; rest, 24
	db $ff, SCMD_GOTO
	dw Seq_4fb2

Seq_50cb:
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $04	; rest, 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $04	; rest, 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $04	; rest, 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $04	; rest, 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $04	; rest, 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db REST,       $04	; rest, 4
	db REST,       $08	; rest, 8
	db REST,       $04	; rest, 4
	db $ff, SCMD_RET

Seq_5147:
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_RET

Music00_Ch4:
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_515f:
	db $ff, SCMD_SET_LOOP, $00, $0f	; slot 0 = 15

Seq_5163:
	db $ff, SCMD_CALL
	dw Seq_51b9
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5163
	db REST,       $10	; rest, 16
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5172:
	db $ff, SCMD_SET_LOOP, $01, $0e	; slot 1 = 14

Seq_5176:
	db $ff, SCMD_CALL
	dw Seq_51b9
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_5176
	db $ff, SCMD_CALL
	dw Seq_51ce
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5172
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_518c:
	db $ff, SCMD_CALL
	dw Seq_51b9
	db $ff, SCMD_CALL
	dw Seq_51b9
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_518c
	db $ff, SCMD_CALL
	dw Seq_51b9
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS3,   $02	; D#3, len 2
	db $ff, SCMD_CALL
	dw Seq_51fc
	db NOTE_C5,    $06	; C5, len 6
	db REST,       $1a	; rest, 26
	db $ff, SCMD_GOTO
	dw Seq_515f

Seq_51b9:
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $03	; rest, 3
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db REST,       $02	; rest, 2
	db $ff, SCMD_RET

Seq_51ce:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS3,   $04	; C#3, len 4
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_RET

Seq_51fc:
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_5200:
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_5204:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D2,    $02	; D2, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS3,   $01	; D#3, len 1
	db REST,       $01	; rest, 1
	db NOTE_D2,    $01	; D2, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS3,   $02	; D#3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS3,   $01	; D#3, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_5204
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5200
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db REST,       $02	; rest, 2
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_RET

MusicHeader_01:
	dw Music01_Ch1	; channel 1
	dw Music01_Ch2	; channel 2
	dw Music01_Ch3	; channel 3
	dw Music01_Ch4	; channel 4

Music01_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_ENVELOPE, $0f, $00, $04	; volume 15, down, period 4
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $08	; rest, 8
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $01	; C4, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_SWEEP_OFF

Seq_529d:
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_52ad:
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_52c5:
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_52c5
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db REST,       $04	; rest, 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_52ad
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5303:
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5303
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5351:
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_CALL
	dw Seq_53a6
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_CALL
	dw Seq_53a6
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_CALL
	dw Seq_53a6
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_CALL
	dw Seq_53a6
	db $ff, SCMD_CALL
	dw Seq_53a6
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5351
	db REST,       $08	; rest, 8
	db $ff, SCMD_GOTO
	dw Seq_529d

Seq_53a6:
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_RET

Music01_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db REST,       $13	; rest, 19

Seq_53c8:
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $20	; slot 0 = 32

Seq_53de:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_53de
	db $ff, SCMD_GATE_FRAC, $08	; gate = 8/8 of note length
	db $ff, SCMD_GATE_ABS, $04	; gate = 4 x tempo
	db $ff, SCMD_ENVELOPE, $0d, $00, $03	; volume 13, down, period 3
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5410:
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_5414:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS4,   $02	; D#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_5414
	db $ff, SCMD_SET_LOOP, $02, $02	; slot 2 = 2

Seq_542e:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_542e
	db $ff, SCMD_SET_LOOP, $03, $02	; slot 3 = 2

Seq_5448:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C4,    $02	; C4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_LOOP, $03	; slot 3
	dw Seq_5448
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_5462:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS4,   $02	; G#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_5462
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_547c:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS4,   $02	; D#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_547c
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_5496:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_5496
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_54b0:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_54b0
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_54ca:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_54ca
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5410
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_54f9:
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_GATE_ABS, $08	; gate = 8 x tempo
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_54f9
	db $ff, SCMD_GOTO
	dw Seq_53c8

Music01_Ch3:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db REST,       $13	; rest, 19
	db $ff, SCMD_PANNING, $03	; both

Seq_553f:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5543:
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_FS4,   $02	; F#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5543
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_55cf:
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_55cf
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_55f8:
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_55f8
	db $ff, SCMD_GOTO
	dw Seq_553f

Music01_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $00, $01, $01	; volume 0, up, period 1
	db NOTE_DS6,   $08	; D#6, len 8
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D3,    $01	; D3, len 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_E9,    $02	; E8, len 2 (clamped from E9)
	db NOTE_D3,    $02	; D3, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1

Seq_564a:
	db $ff, SCMD_SET_LOOP, $00, $0f	; slot 0 = 15
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_5657:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5657
	db $ff, SCMD_ENVELOPE, $0a, $01, $01	; volume 10, up, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS5,   $04	; C#5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $04	; C#4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_SET_LOOP, $00, $0e	; slot 0 = 14

Seq_5691:
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5691
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $06	; slot 0 = 6

Seq_56cc:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_56cc
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS2,   $02	; D#2, len 2
	db NOTE_DS1,   $02	; D#2, len 2 (clamped from D#1)
	db $ff, SCMD_GOTO
	dw Seq_564a

MusicHeader_02:
	dw Music02_Ch1	; channel 1
	dw Music02_Ch2	; channel 2
	dw Music02_Ch3	; channel 3
	dw Music02_Ch4	; channel 4

Music02_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_ENVELOPE, $0b, $00, $07	; volume 11, down, period 7

Seq_571c:
	db $ff, SCMD_VOL_ENVELOPE, $58, $4b
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $10	; A4, len 16
	db NOTE_C4,    $10	; C4, len 16
	db $ff, SCMD_GOTO
	dw Seq_571c

Music02_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4

Seq_5739:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_G6,    $08	; G6, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_B6,    $08	; B6, len 8
	db NOTE_C7,    $08	; C7, len 8
	db NOTE_G6,    $08	; G6, len 8
	db $ff, SCMD_GOTO
	dw Seq_5739

Music02_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_5773:
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db NOTE_C2,    $08	; C2, len 8
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_C2,    $08	; C2, len 8
	db NOTE_C3,    $08	; C3, len 8
	db NOTE_F2,    $08	; F2, len 8
	db NOTE_F3,    $08	; F3, len 8
	db NOTE_F2,    $08	; F2, len 8
	db NOTE_F3,    $08	; F3, len 8
	db $ff, SCMD_GOTO
	dw Seq_5773

Music02_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_579c:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_GOTO
	dw Seq_579c

MusicHeader_03:
	dw Music03_Ch1	; channel 1
	dw Music03_Ch2	; channel 2
	dw Music03_Ch3	; channel 3
	dw Music03_Ch4	; channel 4

Music03_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_DS4,   $01	; D#4, len 1

Seq_57f0:
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_57fc:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E7,    $02	; E7, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_57fc
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_583d:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D7,    $02	; D7, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_583d
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G7,    $02	; G7, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db $ff, SCMD_GOTO
	dw Seq_57f0

Music03_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_DS4,   $01	; D#4, len 1

Seq_58ed:
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_GOTO
	dw Seq_58ed

Music03_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_DS4,   $01	; D#4, len 1
	db $ff, SCMD_PANNING, $03	; both

Seq_59e3:
	db $ff, SCMD_SET_LOOP, $00, $10	; slot 0 = 16

Seq_59e7:
	db NOTE_A3,    $04	; A3, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_59e7
	db $ff, SCMD_SET_LOOP, $00, $10	; slot 0 = 16

Seq_59f2:
	db NOTE_G3,    $04	; G3, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_59f2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db $ff, SCMD_GOTO
	dw Seq_59e3

Music03_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db REST,       $08	; rest, 8

Seq_5a25:
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A0,    $02	; A2, len 2 (clamped from A0)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A0,    $02	; A2, len 2 (clamped from A0)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A0,    $02	; A2, len 2 (clamped from A0)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A0,    $02	; A2, len 2 (clamped from A0)
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C4,    $01	; C4, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $05	; rest, 5
	db $ff, SCMD_GOTO
	dw Seq_5a25

MusicHeader_04:
	dw Music04_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Music04_Ch4	; channel 4
	db $01

Music04_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Music04_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A0,    $05	; A2, len 5 (clamped from A0)
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A0,    $05	; A2, len 5 (clamped from A0)
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $04, $00, $02	; volume 4, down, period 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A0,    $04	; A2, len 4 (clamped from A0)
	db $ff, SCMD_STOP

MusicHeader_05:
	dw Music05_Ch1	; channel 1
	dw Music05_Ch2	; channel 2
	dw Music05_Ch3	; channel 3
	dw 0	; channel 4

Music05_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2

Seq_5a9f:
	db $ff, SCMD_ENVELOPE, $00, $01, $03	; volume 0, up, period 3
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_ENVELOPE, $01, $01, $03	; volume 1, up, period 3
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db $ff, SCMD_ENVELOPE, $02, $01, $05	; volume 2, up, period 5
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_GOTO
	dw Seq_5a9f

Music05_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $05, $00, $02	; volume 5, down, period 2

Seq_5b02:
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_B3,    $02	; B3, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_GOTO
	dw Seq_5b02

Music05_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_5b46:
	db NOTE_FS4,   $0c	; F#4, len 12
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_CS4,   $0c	; C#4, len 12
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_DS4,   $10	; D#4, len 16
	db $ff, SCMD_GOTO
	dw Seq_5b46
	db $ff, $08, $05

MusicHeader_06:
	dw Music06_Ch1	; channel 1
	dw Music06_Ch2	; channel 2
	dw Music06_Ch3	; channel 3
	dw Music06_Ch4	; channel 4

Music06_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2

Seq_5b74:
	db $ff, SCMD_CALL
	dw Seq_5bc5
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5b7f:
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5b7f
	db $ff, SCMD_CALL
	dw Seq_5bc5
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5ba8:
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5ba8
	db $ff, SCMD_GOTO
	dw Seq_5b74

Seq_5bc5:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_5bd1:
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_FS6,   $04	; F#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_GS6,   $04	; G#6, len 4
	db NOTE_G6,    $04	; G6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5bd1
	db $ff, SCMD_RET

Music06_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone

Seq_5bff:
	db $ff, SCMD_CALL
	dw Seq_5c36
	db $ff, SCMD_CALL
	dw Seq_5c36
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5c0e:
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db REST,       $08	; rest, 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5c0e
	db $ff, SCMD_VOLUME, $0c	; volume 12
	db $ff, SCMD_CALL
	dw Seq_5c36
	db $ff, SCMD_CALL
	dw Seq_5c36
	db $ff, SCMD_VOLUME, $08	; volume 8
	db $ff, SCMD_CALL
	dw Seq_5c57
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_CALL
	dw Seq_5c57
	db $ff, SCMD_GOTO
	dw Seq_5bff

Seq_5c36:
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_RET

Seq_5c57:
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_RET

Music06_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $04	; gate = 4 x tempo

Seq_5c89:
	db $ff, SCMD_SET_LOOP, $00, $0c	; slot 0 = 12

Seq_5c8d:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C3,    $04	; C3, len 4
	db REST,       $08	; rest, 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5c8d
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_5ca2:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS3,   $04	; D#3, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS3,   $04	; D#3, len 4
	db REST,       $08	; rest, 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5ca2
	db $ff, SCMD_GOTO
	dw Seq_5c89

Music06_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_5cc9:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db $ff, SCMD_GOTO
	dw Seq_5cc9

MusicHeader_07:
	dw Music07_Ch1	; channel 1
	dw Music07_Ch2	; channel 2
	dw Music07_Ch3	; channel 3
	dw Music07_Ch4	; channel 4

Music07_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_G3,    $10	; G3, len 16
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_GS3,   $10	; G#3, len 16
	db $ff, SCMD_VOLUME, $08	; volume 8
	db NOTE_F3,    $10	; F3, len 16
	db $ff, SCMD_ENVELOPE, $00, $01, $03	; volume 0, up, period 3
	db NOTE_B2,    $20	; B2, len 32
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G3,    $01	; G3, len 1
	db NOTE_G3,    $01	; G3, len 1
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_E3,    $02	; E3, len 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_CALL
	dw Seq_5dbf
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_VOLUME, $08	; volume 8
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_CALL
	dw Seq_5dbf
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C3,    $08	; C3, len 8
	db $ff, SCMD_STOP

Seq_5dbf:
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_RET

Music07_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_VOLUME, $01	; volume 1
	db NOTE_DS2,   $10	; D#2, len 16
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_E2,    $10	; E2, len 16
	db $ff, SCMD_VOLUME, $08	; volume 8
	db NOTE_F2,    $10	; F2, len 16
	db $ff, SCMD_ENVELOPE, $00, $01, $03	; volume 0, up, period 3
	db NOTE_D2,    $20	; D2, len 32
	db REST,       $10	; rest, 16
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_CALL
	dw Seq_5ead
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_CALL
	dw Seq_5ead
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_STOP

Seq_5ead:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_RET

Music07_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db NOTE_C3,    $10	; C3, len 16
	db NOTE_CS3,   $10	; C#3, len 16
	db NOTE_D3,    $10	; D3, len 16
	db NOTE_B2,    $20	; B2, len 32
	db REST,       $10	; rest, 16
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_CALL
	dw Seq_5f3c
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db $ff, SCMD_CALL
	dw Seq_5f3c
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G2,    $04	; G2, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G2,    $02	; G2, len 2
	db NOTE_F2,    $02	; F2, len 2
	db NOTE_G2,    $02	; G2, len 2
	db NOTE_A2,    $02	; A2, len 2
	db NOTE_B2,    $02	; B2, len 2
	db NOTE_C3,    $02	; C3, len 2
	db $ff, SCMD_STOP

Seq_5f3c:
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS2,   $04	; A#2, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS2,   $04	; A#2, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS2,   $04	; A#2, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS2,   $04	; A#2, len 4
	db NOTE_A2,    $04	; A2, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A2,    $02	; A2, len 2
	db NOTE_A2,    $02	; A2, len 2
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A2,    $04	; A2, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A2,    $04	; A2, len 4
	db NOTE_A3,    $04	; A3, len 4
	db $ff, SCMD_RET

Music07_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db REST,       $50	; rest, 80
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS2,   $01	; C#2, len 1
	db NOTE_CS2,   $01	; C#2, len 1
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_5fa0:
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $03	; rest, 3
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C2,    $02	; C2, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C2,    $02	; C2, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_5fa0
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_CS6,   $08	; C#6, len 8
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_G1,    $08	; G2, len 8 (clamped from G1)
	db $ff, SCMD_STOP

MusicHeader_08:
	dw Music08_Ch1	; channel 1
	dw Music08_Ch2	; channel 2
	dw Music08_Ch3	; channel 3
	dw 0	; channel 4

Music08_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_STOP

Music08_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C6,    $10	; C6, len 16
	db $ff, SCMD_STOP

Music08_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_60b1:
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60b1
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_60bc:
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60bc
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_60c7:
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_60c7
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_STOP
	db $ff, $08, $03, $ff, $0e

MusicHeader_09:
	dw Music09_Ch1	; channel 1
	dw Music09_Ch2	; channel 2
	dw Music09_Ch3	; channel 3
	dw Music09_Ch4	; channel 4

Music09_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $03, $01, $05	; volume 3, up, period 5
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_ENVELOPE, $06, $01, $05	; volume 6, up, period 5
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_ENVELOPE, $05, $00, $05	; volume 5, down, period 5

Seq_6120:
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_A4,    $06	; A4, len 6
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_GOTO
	dw Seq_6120

Music09_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $04, $01, $05	; volume 4, up, period 5
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db $ff, SCMD_ENVELOPE, $05, $01, $05	; volume 5, up, period 5
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db $ff, SCMD_ENVELOPE, $06, $01, $05	; volume 6, up, period 5
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db $ff, SCMD_VOLUME, $07	; volume 7

Seq_61a7:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $02	; C6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $02	; A5, len 2
	db REST,       $08	; rest, 8
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db REST,       $08	; rest, 8
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $02	; C6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_GOTO
	dw Seq_61a7

Music09_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_FS4,   $04	; F#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_FS4,   $04	; F#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db REST,       $04	; rest, 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1

Seq_6262:
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_GOTO
	dw Seq_6262

Music09_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db REST,       $20	; rest, 32

Seq_62c5:
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_62ce:
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_62ce
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_GOTO
	dw Seq_62c5

MusicHeader_10:
	dw Music10_Ch1	; channel 1
	dw Music10_Ch2	; channel 2
	dw Music10_Ch3	; channel 3
	dw Music10_Ch4	; channel 4

Music10_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3

Seq_6303:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6312:
	db REST,       $20	; rest, 32
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6312
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_633a:
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_640f
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $02	; rest, 2
	db NOTE_F4,    $06	; F4, len 6
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_CALL
	dw Seq_640f
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $02	; rest, 2
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_CALL
	dw Seq_640f
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F4,    $04	; F4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F4,    $06	; F4, len 6
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_FS4,   $06	; F#4, len 6
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db REST,       $03	; rest, 3
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_63c8:
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_63c8
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_63ef:
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_63ef
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $09	; F5, len 9
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_633a
	db $ff, SCMD_GOTO
	dw Seq_6303

Seq_640f:
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $04	; rest, 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db REST,       $02	; rest, 2
	db REST,       $04	; rest, 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db REST,       $02	; rest, 2
	db REST,       $04	; rest, 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_RET

Music10_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone

Seq_643f:
	db $ff, SCMD_ENVELOPE, $0b, $00, $02	; volume 11, down, period 2
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_644c:
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_6453:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_6453
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS3,   $04	; F#3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS5,   $04	; F#5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS3,   $04	; F#3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS5,   $04	; F#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS3,   $04	; F#3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_644c
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_649b:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_VOLUME, $05	; volume 5
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PITCH_ENVELOPE, $43, $4b
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G5,    $0a	; G5, len 10
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $06	; D#5, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $18	; C5, len 24
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $0c	; C5, len 12
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $10	; rest, 16
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_6513:
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_6513
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_653a:
	db REST,       $04	; rest, 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_653a
	db NOTE_DS5,   $06	; D#5, len 6
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_F5,    $06	; F5, len 6
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F5,    $03	; F5, len 3
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F5,    $01	; F5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_649b
	db $ff, SCMD_GOTO
	dw Seq_643f

Music10_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1

Seq_6575:
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_6585:
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6585
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_65ae:
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_65b8:
	db $ff, SCMD_CALL
	dw Seq_65f9
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_65b8
	db $ff, SCMD_CALL
	dw Seq_65f9
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_FS4,   $06	; F#4, len 6
	db NOTE_F4,    $04	; F4, len 4
	db $ff, SCMD_SET_LOOP, $01, $07	; slot 1 = 7

Seq_65d5:
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db REST,       $02	; rest, 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_65d5
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_65ae
	db $ff, SCMD_GOTO
	dw Seq_6575

Seq_65f9:
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_RET

Music10_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_662a:
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6633:
	db REST,       $20	; rest, 32
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6633
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_CS2,   $04	; C#2, len 4
	db NOTE_CS2,   $04	; C#2, len 4
	db NOTE_CS2,   $04	; C#2, len 4
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $04	; C#2, len 4
	db NOTE_CS2,   $04	; C#2, len 4
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6659:
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_CALL
	dw Seq_66d3
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_CALL
	dw Seq_66d3
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_668f:
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_DS7,   $04	; D#7, len 4
	db NOTE_D1,    $04	; D2, len 4 (clamped from D1)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS4,   $04	; F#4, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_DS7,   $04	; D#7, len 4
	db NOTE_D2,    $04	; D2, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS5,   $04	; F#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_668f
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6659
	db $ff, SCMD_GOTO
	dw Seq_662a

Seq_66d3:
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $06	; C4, len 6
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $06	; C4, len 6
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C3,    $06	; C3, len 6
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_CM2,   $04	; C2, len 4 (clamped from C-2)
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_RET

MusicHeader_11:
	dw Music11_Ch1	; channel 1
	dw Music11_Ch2	; channel 2
	dw Music11_Ch3	; channel 3
	dw Music11_Ch4	; channel 4

Music11_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_6733:
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F6,    $01	; F6, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F6,    $01	; F6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F6,    $01	; F6, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_GOTO
	dw Seq_6733

Music11_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01

Seq_677e:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_678d:
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_678d
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_67a2:
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_CALL
	dw Seq_689f
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_CALL
	dw Seq_689f
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $03	; A#4, len 3
	db REST,       $01	; rest, 1
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_67a2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6820:
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6820
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_F6,    $01	; F6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_F6,    $01	; F6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_F6,    $01	; F6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_GOTO
	dw Seq_677e

Seq_689f:
	db REST,       $02	; rest, 2
	db NOTE_B3,    $01	; B3, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_RET

Music11_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1

Seq_68c5:
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_CALL
	dw Seq_694b
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_68d0:
	db $ff, SCMD_CALL
	dw Seq_694b
	db $ff, SCMD_SET_LOOP, $02, $02	; slot 2 = 2

Seq_68d8:
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_C5,    $01	; C5, len 1
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_68d8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_68d0
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_690a:
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_690a
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_GOTO
	dw Seq_68c5

Seq_694b:
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_694f:
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_694f
	db $ff, SCMD_RET

Music11_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $05	; note length x5
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1

Seq_6989:
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_698d:
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $02	; rest, 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_698d
	db $ff, SCMD_CALL
	dw Seq_69f4
	db $ff, SCMD_CALL
	dw Seq_6a1f
	db $ff, SCMD_CALL
	dw Seq_69f4
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_69aa:
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_69aa
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_GM1,   $02	; G2, len 2 (clamped from G-1)
	db $ff, SCMD_SET_LOOP, $00, $06	; slot 0 = 6

Seq_69c1:
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db REST,       $02	; rest, 2
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_69c1
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db NOTE_FS12,  $04	; F8, len 4 (clamped from F#12)
	db NOTE_FS12,  $02	; F8, len 2 (clamped from F#12)
	db NOTE_FS12,  $02	; F8, len 2 (clamped from F#12)
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_GM1,   $01	; G2, len 1 (clamped from G-1)
	db NOTE_GM1,   $01	; G2, len 1 (clamped from G-1)
	db NOTE_GM1,   $01	; G2, len 1 (clamped from G-1)
	db REST,       $01	; rest, 1
	db NOTE_GM1,   $01	; G2, len 1 (clamped from G-1)
	db NOTE_GM1,   $01	; G2, len 1 (clamped from G-1)
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db $ff, SCMD_GOTO
	dw Seq_6989

Seq_69f4:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_69f8:
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $03	; rest, 3
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_GM2,   $02	; G2, len 2 (clamped from G-2)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db NOTE_GM2,   $01	; G2, len 1 (clamped from G-2)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_69f8
	db $ff, SCMD_RET

Seq_6a1f:
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db REST,       $02	; rest, 2
	db NOTE_GM2,   $04	; G2, len 4 (clamped from G-2)
	db $ff, SCMD_RET

MusicHeader_12:
	dw Music12_Ch1	; channel 1
	dw Music12_Ch2	; channel 2
	dw Music12_Ch3	; channel 3
	dw Music12_Ch4	; channel 4

Music12_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_6a6f:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_GOTO
	dw Seq_6a6f

Music12_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3

Seq_6abf:
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_PITCH_ENVELOPE, $3b, $4b
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $00, $10	; slot 0 = 16

Seq_6acd:
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6acd
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_6aec:
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6aec
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6b1b:
	db REST,       $02	; rest, 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db REST,       $02	; rest, 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db REST,       $02	; rest, 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db REST,       $02	; rest, 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db REST,       $02	; rest, 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db REST,       $02	; rest, 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db REST,       $02	; rest, 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db REST,       $02	; rest, 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6b1b
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PITCH_ENVELOPE, $3b, $4b
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B2,    $02	; B2, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B2,    $02	; B2, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B2,    $02	; B2, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B2,    $02	; B2, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D3,    $02	; D3, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D3,    $02	; D3, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D3,    $02	; D3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D3,    $02	; D3, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_VOLUME, $0c	; volume 12
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E3,    $02	; E3, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_GOTO
	dw Seq_6abf

Music12_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots

Seq_6c08:
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6c0c:
	db $ff, SCMD_CALL
	dw Seq_6c3f
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6c0c
	db $ff, SCMD_CALL
	dw Seq_6c55
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6c1d:
	db $ff, SCMD_CALL
	dw Seq_6c3f
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6c1d
	db $ff, SCMD_CALL
	dw Seq_6c55
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_6c2e:
	db $ff, SCMD_CALL
	dw Seq_6c3f
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6c2e
	db $ff, SCMD_CALL
	dw Seq_6c55
	db $ff, SCMD_GOTO
	dw Seq_6c08

Seq_6c3f:
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_RET

Seq_6c55:
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_RET

Music12_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_6c7d:
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_6c81:
	db $ff, SCMD_CALL
	dw Seq_6c9f
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6c81
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_6c8e:
	db $ff, SCMD_CALL
	dw Seq_6cbd
	db $ff, SCMD_CALL
	dw Seq_6cdd
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6c8e
	db $ff, SCMD_GOTO
	dw Seq_6c7d

Seq_6c9f:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS8,   $04	; D#8, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS8,   $04	; D#8, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db $ff, SCMD_RET

Seq_6cbd:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS7,   $04	; D#7, len 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_RET

Seq_6cdd:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS8,   $04	; D#8, len 4
	db $ff, SCMD_RET

MusicHeader_13:
	dw Music13_Ch1	; channel 1
	dw Music13_Ch2	; channel 2
	dw Music13_Ch3	; channel 3
	dw Music13_Ch4	; channel 4

Music13_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length

Seq_6d10:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6d14:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_CALL
	dw Seq_6e64
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_CALL
	dw Seq_6e64
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_6ebb
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_CALL
	dw Seq_6ebb
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6d14
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E3,    $04	; E3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E3,    $04	; E3, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_GOTO
	dw Seq_6d10

Seq_6e64:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_RET
	db $6f, $10, $07, $0c, $b8, $02, $07, $02, $9c, $04, $8d, $04, $6f, $04, $8d, $04
	db $9c, $04, $9c, $04, $07, $04, $b8, $02, $07, $02, $ff, $10

Seq_6ebb:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_RET

Music13_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone

Seq_6ee6:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_6eea:
	db $ff, SCMD_TRANSPOSE, $02	; +2 octave slots
	db $ff, SCMD_CALL
	dw Seq_7004
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E5,    $04	; E5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_CALL
	dw Seq_7004
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $08	; rest, 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $07	; volume 7
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PITCH_ENVELOPE, $3b, $4b
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $02	; rest, 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_G4,    $10	; G4, len 16
	db NOTE_C5,    $0c	; C5, len 12
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $02	; rest, 2
	db NOTE_G4,    $01	; G4, len 1
	db REST,       $01	; rest, 1
	db NOTE_G4,    $10	; G4, len 16
	db NOTE_C5,    $0c	; C5, len 12
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_C4,    $08	; C4, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $08	; F4, len 8
	db REST,       $02	; rest, 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_6eea
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_GOTO
	dw Seq_6ee6

Seq_7004:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_C4,    $07	; C4, len 7
	db REST,       $01	; rest, 1
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_A3,    $08	; A3, len 8
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_B3,    $08	; B3, len 8
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_RET

Music13_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_7056:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_705a:
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_705e:
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C3,    $10	; C3, len 16
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_705e
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_70a7:
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $04	; D#3, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS3,   $02	; D#3, len 2
	db NOTE_DS3,   $02	; D#3, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_F3,    $02	; F3, len 2
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_70a7
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_705a
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_GOTO
	dw Seq_7056

Music13_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_7133:
	db $ff, SCMD_SET_LOOP, $00, $08	; slot 0 = 8

Seq_7137:
	db $ff, SCMD_SET_LOOP, $01, $07	; slot 1 = 7

Seq_713b:
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS6,   $04	; C#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_713b
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_D7,    $04	; D7, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_D7,    $02	; D7, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_7137
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db NOTE_C1,    $04	; C2, len 4 (clamped from C1)
	db NOTE_C1,    $04	; C2, len 4 (clamped from C1)
	db NOTE_C1,    $04	; C2, len 4 (clamped from C1)
	db NOTE_C1,    $04	; C2, len 4 (clamped from C1)
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_GOTO
	dw Seq_7133

MusicHeader_14:
	dw Music14_Ch1	; channel 1
	dw Music14_Ch2	; channel 2
	dw Music14_Ch3	; channel 3
	dw Music14_Ch4	; channel 4

Music14_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_71b8:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_71bc:
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_71bc
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_GOTO
	dw Seq_71b8

Music14_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_72b0:
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_PITCH_ENVELOPE, $3b, $4b
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_72c1:
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_AS5,   $10	; A#5, len 16
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_C6,    $10	; C6, len 16
	db NOTE_D6,    $10	; D6, len 16
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_AS5,   $10	; A#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_D5,    $10	; D5, len 16
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_F5,    $10	; F5, len 16
	db NOTE_AS5,   $10	; A#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_C6,    $10	; C6, len 16
	db NOTE_AS5,   $10	; A#5, len 16
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_72c1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $07	; slot 0 = 7

Seq_72f2:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D6,    $04	; D6, len 4
	db $ff, SCMD_SET_LOOP, $01, $03	; slot 1 = 3

Seq_7300:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_7300
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_72f2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_GOTO
	dw Seq_72b0

Music14_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1

Seq_734f:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_7356:
	db $ff, SCMD_SET_LOOP, $01, $10	; slot 1 = 16

Seq_735a:
	db NOTE_C3,    $04	; C3, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_735a
	db $ff, SCMD_SET_LOOP, $02, $10	; slot 2 = 16

Seq_7365:
	db NOTE_DS3,   $04	; D#3, len 4
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_7365
	db $ff, SCMD_SET_LOOP, $03, $10	; slot 3 = 16

Seq_7370:
	db NOTE_AS2,   $04	; A#2, len 4
	db $ff, SCMD_LOOP, $03	; slot 3
	dw Seq_7370
	db $ff, SCMD_SET_LOOP, $01, $08	; slot 1 = 8

Seq_737b:
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_737b
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G3,    $04	; G3, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_7356
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_739b:
	db $ff, SCMD_SET_LOOP, $01, $10	; slot 1 = 16

Seq_739f:
	db NOTE_GS3,   $04	; G#3, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_739f
	db $ff, SCMD_SET_LOOP, $02, $10	; slot 2 = 16

Seq_73aa:
	db NOTE_G3,    $04	; G3, len 4
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_73aa
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_739b
	db $ff, SCMD_GOTO
	dw Seq_734f

Music14_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1

Seq_73c2:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $04	; C2, len 4 (clamped from C-1)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS7,   $04	; D#7, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS0,   $04	; C#2, len 4 (clamped from C#0)
	db $ff, SCMD_GOTO
	dw Seq_73c2

MusicHeader_15:
	dw Music15_Ch1	; channel 1
	dw Music15_Ch2	; channel 2
	dw Music15_Ch3	; channel 3
	dw 0	; channel 4

Music15_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_STOP

Music15_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_DETUNE, $ff	; -127/8 semitone
	db $ff, SCMD_VOLUME, $0c	; volume 12
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_STOP

Music15_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_STOP
	db $ff, $0b, $09, $4b, $ff, $08, $03, $ff, $0e

MusicHeader_16:
	dw Music16_Ch1	; channel 1
	dw Music16_Ch2	; channel 2
	dw Music16_Ch3	; channel 3
	dw Music16_Ch4	; channel 4

Music16_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_SWEEP, $01, $01, $07	; NR10=$01, $01, $07
	db REST,       $02	; rest, 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_SWEEP, $01, $01, $06	; NR10=$01, $01, $06
	db $ff, SCMD_ENVELOPE, $04, $00, $01	; volume 4, down, period 1
	db NOTE_F8,    $02	; F8, len 2
	db NOTE_G8,    $02	; G8, len 2
	db NOTE_F8,    $02	; F8, len 2
	db NOTE_F8,    $01	; F8, len 1
	db NOTE_G8,    $01	; G8, len 1
	db NOTE_F8,    $02	; F8, len 2
	db NOTE_G8,    $02	; G8, len 2
	db NOTE_F8,    $02	; F8, len 2
	db NOTE_F8,    $01	; F8, len 1
	db NOTE_G8,    $01	; G8, len 1
	db NOTE_F8,    $01	; F8, len 1
	db NOTE_G8,    $01	; G8, len 1
	db REST,       $02	; rest, 2
	db REST,       $03	; rest, 3
	db NOTE_E8,    $02	; E8, len 2
	db REST,       $02	; rest, 2
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db REST,       $01	; rest, 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_E8,    $02	; E8, len 2
	db REST,       $02	; rest, 2
	db NOTE_E8,    $02	; E8, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E8,    $02	; E8, len 2
	db REST,       $02	; rest, 2
	db NOTE_E8,    $02	; E8, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db NOTE_E8,    $10	; E8, len 16
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Music16_Ch2:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db REST,       $04	; rest, 4
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_74ec:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS2,   $02	; D#2, len 2
	db NOTE_DS2,   $01	; D#2, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $01	; C#2, len 1
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_74ec
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db NOTE_CS2,   $08	; C#2, len 8
	db $ff, SCMD_STOP

Music16_Ch3:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db REST,       $04	; rest, 4
	db NOTE_D2,    $20	; D2, len 32
	db NOTE_CS2,   $08	; C#2, len 8
	db $ff, SCMD_STOP

Music16_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db REST,       $01	; rest, 1
	db NOTE_GS2,   $06	; G#2, len 6
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_EM1,   $02	; E2, len 2 (clamped from E-1)
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_EM1,   $02	; E2, len 2 (clamped from E-1)
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS3,   $01	; G#3, len 1
	db NOTE_EM1,   $02	; E2, len 2 (clamped from E-1)
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_EM1,   $02	; E2, len 2 (clamped from E-1)
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS3,   $01	; G#3, len 1
	db NOTE_EM1,   $03	; E2, len 3 (clamped from E-1)
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $04	; G#2, len 4
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $08	; G#2, len 8
	db $ff, SCMD_SET_LOOP, $00, $06	; slot 0 = 6

Seq_756a:
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS3,   $01	; G#3, len 1
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_756a
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $08	; G#2, len 8
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $02	; G#2, len 2
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $08	; G#2, len 8
	db NOTE_GS2,   $28	; G#2, len 40
	db $ff, SCMD_STOP

MusicHeader_17:
	dw Music17_Ch1	; channel 1
	dw Music17_Ch2	; channel 2
	dw Music17_Ch3	; channel 3
	dw Music17_Ch4	; channel 4

Music17_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length

Seq_7595:
	db REST,       $02	; rest, 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_75a2:
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_SET_LOOP, $01, $08	; slot 1 = 8

Seq_75ac:
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_75ac
	db $ff, SCMD_SET_LOOP, $02, $06	; slot 2 = 6

Seq_75bd:
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_75bd
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $03	; D#5, len 3
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_75a2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_75ec:
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_CALL
	dw Seq_7638
	db NOTE_E3,    $08	; E3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_CALL
	dw Seq_7638
	db NOTE_D3,    $08	; D3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_CALL
	dw Seq_7638
	db NOTE_G3,    $08	; G3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_75ec
	db $ff, SCMD_GOTO
	dw Seq_7595

Seq_7638:
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $01, $01, $02	; volume 1, up, period 2
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_RET

Music17_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone

Seq_7655:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_765f:
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_VOLUME, $05	; volume 5
	db $ff, SCMD_SET_LOOP, $01, $08	; slot 1 = 8

Seq_766a:
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_766a
	db $ff, SCMD_SET_LOOP, $02, $06	; slot 2 = 6

Seq_767b:
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_LOOP, $02	; slot 2
	dw Seq_767b
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_765f
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_76a5:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_CALL
	dw Seq_7715
	db NOTE_E3,    $08	; E3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_CALL
	dw Seq_7715
	db NOTE_D3,    $08	; D3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_F5,    $04	; F5, len 4
	db $ff, SCMD_CALL
	dw Seq_7715
	db NOTE_G3,    $08	; G3, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_E5,    $08	; E5, len 8
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db REST,       $02	; rest, 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db REST,       $02	; rest, 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db REST,       $02	; rest, 2
	db NOTE_E6,    $02	; E6, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_76a5
	db $ff, SCMD_GOTO
	dw Seq_7655

Seq_7715:
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $01, $01, $02	; volume 1, up, period 2
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_F3,    $04	; F3, len 4
	db $ff, SCMD_RET

Music17_Ch3:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots

Seq_773c:
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_7740:
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_SET_LOOP, $01, $04	; slot 1 = 4

Seq_7747:
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_7747
	db $ff, SCMD_SET_LOOP, $01, $04	; slot 1 = 4

Seq_7760:
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $02	; B4, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_7760
	db $ff, SCMD_SET_LOOP, $01, $04	; slot 1 = 4

Seq_7779:
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_7779
	db $ff, SCMD_SET_LOOP, $01, $02	; slot 1 = 2

Seq_7792:
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_LOOP, $01	; slot 1
	dw Seq_7792
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_7740
	db $ff, SCMD_SET_LOOP, $00, $04	; slot 0 = 4

Seq_77d7:
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_77d7
	db $ff, SCMD_GOTO
	dw Seq_773c

Music17_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_784c:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_GOTO
	dw Seq_784c

MusicHeader_18:
	dw Music18_Ch1	; channel 1
	dw Music18_Ch2	; channel 2
	dw Music18_Ch3	; channel 3
	dw 0	; channel 4

Music18_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3

Seq_7882:
	db $ff, SCMD_VOL_ENVELOPE, $58, $4b
	db $ff, SCMD_SET_LOOP, $00, $02	; slot 0 = 2

Seq_788a:
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $10	; A4, len 16
	db NOTE_C4,    $10	; C4, len 16
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_788a
	db NOTE_B4,    $10	; B4, len 16
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $10	; E5, len 16
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_F5,    $08	; F5, len 8
	db $ff, SCMD_GOTO
	dw Seq_7882

Music18_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $02, $01, $05	; volume 2, up, period 5
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots

Seq_78c4:
	db $ff, SCMD_CALL
	dw Seq_78f0
	db $ff, SCMD_CALL
	dw Seq_78f0
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db $ff, SCMD_GOTO
	dw Seq_78c4

Seq_78f0:
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_RET

Music18_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo

Seq_7926:
	db $ff, SCMD_CALL
	dw Seq_7958
	db $ff, SCMD_CALL
	dw Seq_7958
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS3,   $04	; F#3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db $ff, SCMD_GOTO
	dw Seq_7926

Seq_7958:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F3,    $04	; F3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_RET
	db $ff, $0e

MusicHeader_19:
	dw Music19_Ch1	; channel 1
	dw Music19_Ch2	; channel 2
	dw Music19_Ch3	; channel 3
	dw Music19_Ch4	; channel 4

Music19_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3

Seq_7999:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_CALL
	dw Seq_7a70
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_CALL
	dw Seq_7a70
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $08	; C5, len 8
	db REST,       $08	; rest, 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db $ff, SCMD_SET_LOOP, $00, $03	; slot 0 = 3

Seq_79f4:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A4,    $0c	; A4, len 12
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $0c	; E5, len 12
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_79f4
	db NOTE_A4,    $0c	; A4, len 12
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $08, $00, $03	; volume 8, down, period 3
	db $ff, SCMD_CALL
	dw Seq_7a70
	db NOTE_E6,    $08	; E6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_ENVELOPE, $08, $00, $04	; volume 8, down, period 4
	db $ff, SCMD_CALL
	dw Seq_7a70
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $08	; C5, len 8
	db REST,       $08	; rest, 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_GOTO
	dw Seq_7999

Seq_7a70:
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_F5,    $0c	; F5, len 12
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $10	; A4, len 16
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_RET

Music19_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length

Seq_7a9e:
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $07, $00, $05	; volume 7, down, period 5
	db $ff, SCMD_CALL
	dw Seq_7bbc
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_CALL
	dw Seq_7bbc
	db NOTE_E5,    $18	; E5, len 24
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $04	; rest, 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $03, $01, $03	; volume 3, up, period 3
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $04	; rest, 4
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $04	; rest, 4
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_E5,    $04	; E5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_A5,    $04	; A5, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $04	; rest, 4
	db NOTE_B5,    $04	; B5, len 4
	db $ff, SCMD_ENVELOPE, $07, $00, $05	; volume 7, down, period 5
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_ENVELOPE, $08, $00, $06	; volume 8, down, period 6
	db $ff, SCMD_CALL
	dw Seq_7bbc
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_ENVELOPE, $08, $00, $07	; volume 8, down, period 7
	db $ff, SCMD_CALL
	dw Seq_7bbc
	db NOTE_E5,    $18	; E5, len 24
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_GOTO
	dw Seq_7a9e

Seq_7bbc:
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_G4,    $10	; G4, len 16
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_C5,    $0c	; C5, len 12
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_G4,    $10	; G4, len 16
	db $ff, SCMD_RET

Music19_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo

Seq_7bef:
	db $ff, SCMD_CALL
	dw Seq_7c41
	db NOTE_G4,    $18	; G4, len 24
	db $ff, SCMD_CALL
	dw Seq_7c41
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db REST,       $08	; rest, 8
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_E4,    $08	; E4, len 8
	db REST,       $08	; rest, 8
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_D4,    $08	; D4, len 8
	db REST,       $08	; rest, 8
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_E4,    $08	; E4, len 8
	db REST,       $08	; rest, 8
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_F4,    $18	; F4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_F4,    $18	; F4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db $ff, SCMD_CALL
	dw Seq_7c41
	db NOTE_G4,    $18	; G4, len 24
	db $ff, SCMD_CALL
	dw Seq_7c41
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_F4,    $08	; F4, len 8
	db REST,       $08	; rest, 8
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_E4,    $08	; E4, len 8
	db REST,       $08	; rest, 8
	db NOTE_D4,    $08	; D4, len 8
	db NOTE_D4,    $08	; D4, len 8
	db REST,       $08	; rest, 8
	db $ff, SCMD_GOTO
	dw Seq_7bef

Seq_7c41:
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_F4,    $18	; F4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_A4,    $18	; A4, len 24
	db NOTE_G4,    $18	; G4, len 24
	db NOTE_F4,    $18	; F4, len 24
	db $ff, SCMD_RET

Music19_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_SET_LOOP, $00, $1b	; slot 0 = 27

Seq_7c67:
	db REST,       $18	; rest, 24
	db $ff, SCMD_LOOP, $00	; slot 0
	dw Seq_7c67

Seq_7c6e:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E9,    $08	; E8, len 8 (clamped from E9)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GM2,   $08	; G2, len 8 (clamped from G-2)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS3,   $08	; F#3, len 8
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $08	; C4, len 8
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C2,    $08	; C2, len 8
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM2,   $08	; C2, len 8 (clamped from C-2)
	db $ff, SCMD_GOTO
	dw Seq_7c6e

SfxHeader_00:
	dw Sfx00_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx00_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_E4,    $01	; E4, len 1
	db $ff, SCMD_SWEEP, $02, $00, $07	; NR10=$02, $00, $07
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db NOTE_E4,    $01	; E4, len 1
	db $ff, SCMD_STOP

SfxHeader_01:
	dw Sfx01_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx01_Ch4	; channel 4
	db $00

Sfx01_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx01_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G2,    $08	; G2, len 8
	db $ff, SCMD_STOP

SfxHeader_02:
	dw Sfx02_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx02_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_E6,    $01	; E6, len 1
	db $ff, SCMD_SWEEP, $01, $01, $07	; NR10=$01, $01, $07
	db NOTE_E6,    $01	; E6, len 1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_STOP

SfxHeader_03:
	dw Sfx03_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx03_Ch4	; channel 4
	db $00

Sfx03_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx03_Ch4:
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db NOTE_DSM1,  $01	; D#2, len 1 (clamped from D#-1)
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db NOTE_DS8,   $01	; D#8, len 1
	db NOTE_DS7,   $01	; D#7, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_DS1,   $01	; D#2, len 1 (clamped from D#1)
	db $ff, SCMD_STOP

SfxHeader_04:
	dw Sfx04_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx04_Ch4	; channel 4
	db $00, $ff, $0b, $02, $00, $ff, $0b, $00, $00, $ff, $08, $02, $ff, $11, $05

Sfx04_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4b
	db NOTE_C6,    $03	; C6, len 3
	db $ff, SCMD_STOP

Sfx04_Ch4:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db NOTE_CS9,   $03	; C#8, len 3 (clamped from C#9)
	db $ff, SCMD_STOP

SfxHeader_05:
	dw Sfx05_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx05_Ch4	; channel 4
	db $00

Sfx05_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx05_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_AM1,   $03	; A2, len 3 (clamped from A-1)
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_EM1,   $06	; E2, len 6 (clamped from E-1)
	db $ff, SCMD_STOP

SfxHeader_07:
	dw Sfx07_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx07_Ch4	; channel 4
	db $00

Sfx07_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx07_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_CS3,   $01	; C#3, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_CS4,   $01	; C#4, len 1
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_C12,   $01	; C8, len 1 (clamped from C12)
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_STOP

SfxHeader_08:
	dw Sfx08_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx08_Ch4	; channel 4
	db $00

Sfx08_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db $ff, SCMD_SWEEP, $01, $01, $07	; NR10=$01, $01, $07
	db NOTE_F8,    $02	; F8, len 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx08_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db REST,       $01	; rest, 1
	db NOTE_GS2,   $06	; G#2, len 6
	db $ff, SCMD_STOP

SfxHeader_09:
	dw Sfx09_Ch1	; channel 1
	dw 0	; channel 2
	dw Sfx09_Ch3	; channel 3
	dw 0	; channel 4
	db $00

Sfx09_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_D8,    $01	; D8, len 1
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_A8,    $01	; A8, len 1
	db $ff, SCMD_STOP

Sfx09_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TIMBRE, $00, $00	; duty 0
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $03, $00, $01	; volume 3, down, period 1
	db REST,       $01	; rest, 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_D7,    $01	; D7, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_FS8,   $01	; F8, len 1 (clamped from F#8)
	db $ff, SCMD_STOP

SfxHeader_10:
	dw Sfx10_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx10_Ch4	; channel 4
	db $00

Sfx10_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx10_Ch4:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_FSM1,  $01	; F#2, len 1 (clamped from F#-1)
	db NOTE_F12,   $01	; F8, len 1 (clamped from F12)
	db NOTE_FSM2,  $01	; F#2, len 1 (clamped from F#-2)
	db NOTE_G7,    $01	; G7, len 1
	db $ff, SCMD_STOP

SfxHeader_11:
	dw Sfx11_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx11_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_VOLUME, $0d	; volume 13
	db $ff, SCMD_PITCH_ENVELOPE, $4b, $4b
	db NOTE_E8,    $01	; E8, len 1
	db NOTE_G5,    $08	; G5, len 8
	db $ff, SCMD_STOP

SfxHeader_12:
	dw Sfx12_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx12_Ch4	; channel 4
	db $00

Sfx12_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx12_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_E10,   $01	; E8, len 1 (clamped from E10)
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_C2,    $03	; C2, len 3
	db $ff, SCMD_STOP

SfxHeader_13:
	dw Sfx13_Ch1	; channel 1
	dw Sfx13_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx13_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_ENVELOPE, $06, $00, $05	; volume 6, down, period 5
	db NOTE_E6,    $08	; E6, len 8
	db $ff, SCMD_STOP

Sfx13_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F6,    $02	; F6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $03	; volume 7, down, period 3
	db NOTE_F6,    $08	; F6, len 8
	db $ff, SCMD_STOP

SfxHeader_14:
	dw Sfx14_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx14_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_DETUNE, $05	; +5/8 semitone
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_E3,    $01	; E3, len 1
	db $ff, SCMD_STOP

SfxHeader_16:
	dw Sfx16_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx16_Ch4	; channel 4
	db $01

Sfx16_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx16_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_C9,    $01	; C8, len 1 (clamped from C9)
	db NOTE_D7,    $01	; D7, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_CS3,   $01	; C#3, len 1
	db NOTE_CS1,   $01	; C#2, len 1 (clamped from C#1)
	db NOTE_CSM1,  $01	; C#2, len 1 (clamped from C#-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C3,    $01	; C3, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_STOP

SfxHeader_17:
	dw Sfx17_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx17_Ch4	; channel 4
	db $00

Sfx17_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP, $05, $00, $07	; NR10=$05, $00, $07
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C3,    $04	; C3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx17_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_G12,   $04	; G8, len 4 (clamped from G12)
	db NOTE_E9,    $04	; E8, len 4 (clamped from E9)
	db $ff, SCMD_STOP

SfxHeader_18:
	dw Sfx18_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $01

Sfx18_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db $ff, SCMD_PITCH_ENVELOPE, $4b, $4b
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_SWEEP, $02, $00, $07	; NR10=$02, $00, $07
	db $ff, SCMD_ENVELOPE, $03, $01, $03	; volume 3, up, period 3
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $08	; D5, len 8
	db REST,       $04	; rest, 4
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db NOTE_C8,    $08	; C8, len 8
	db $ff, SCMD_STOP
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $07
