; =============================================================================
;  Soldam (J)  --  Jaleco Game Boy sound engine, ROM bank $7
; =============================================================================
;  Reverse-engineered disassembly. Reassembles byte-for-byte with RGBDS.
;
;  The last known game to use this engine. It is Avenging Spirit's driver with
;  two deliberate changes, and is 95% instruction-for-instruction identical to
;  it; the note table is the same 195-entry table as every other version.
;
;    1. The per-frame command budget is 5 instead of 2 (the three extra
;       "inc a" at $4002 are the reason everything below shifts by three
;       bytes relative to Avenging Spirit).
;    2. The loop commands were replaced. $0C/$0D are no longer
;       "set counter slot" / "jump back if slot nonzero" with an explicit
;       target; they are now a nestable LOOP_START / LOOP_END pair that
;       records the loop address itself, four levels deep per channel.
;
;  Every other command keeps its Avenging Spirit id, operand count and
;  behaviour.
;
;  Layout of this bank
;  -------------------
;    $4000-$4102  Sound_Update           per-frame entry point
;    $4103-$42A6  note period table      (NoteTable proper starts at $4121)
;    $42A7-$45AF  command interpreter and its handlers
;    $45B0-$476B  public entry points, init, channel reset
;    $476C-$4ADE  channel processing, envelopes, register output
;    $4ADF-$4AF0  MusicHeaders, 9 songs
;    $4AF1-$4B16  SfxHeaders, 19 effects
;    $4B17-$4B46  three 16-byte wave patterns
;    $4B47-$7FFF  song / effect headers and sequence data
;
;  Channel slots
;  -------------
;    8 slots. Slots 0-3 are music, slots 4-7 are sound effects; slot n drives
;    hardware channel n & 3. SFX outrank music for a given hardware channel.
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
DEF NOTE_CSM1 EQU $10
DEF NOTE_CS0 EQU $11
DEF NOTE_CS1 EQU $12
DEF NOTE_CS2 EQU $13
DEF NOTE_CS3 EQU $14
DEF NOTE_CS4 EQU $15
DEF NOTE_CS5 EQU $16
DEF NOTE_CS6 EQU $17
DEF NOTE_CS7 EQU $18
DEF NOTE_CS8 EQU $19
DEF NOTE_D2 EQU $22
DEF NOTE_D3 EQU $23
DEF NOTE_D4 EQU $24
DEF NOTE_D5 EQU $25
DEF NOTE_D6 EQU $26
DEF NOTE_D7 EQU $27
DEF NOTE_D8 EQU $28
DEF NOTE_DS2 EQU $31
DEF NOTE_DS3 EQU $32
DEF NOTE_DS4 EQU $33
DEF NOTE_DS5 EQU $34
DEF NOTE_DS6 EQU $35
DEF NOTE_DS7 EQU $36
DEF NOTE_DS8 EQU $37
DEF NOTE_EM1 EQU $3d
DEF NOTE_E0 EQU $3e
DEF NOTE_E1 EQU $3f
DEF NOTE_E3 EQU $41
DEF NOTE_E4 EQU $42
DEF NOTE_E5 EQU $43
DEF NOTE_E6 EQU $44
DEF NOTE_E7 EQU $45
DEF NOTE_E9 EQU $47
DEF NOTE_E10 EQU $48
DEF NOTE_E12 EQU $4a
DEF NOTE_F3 EQU $50
DEF NOTE_F4 EQU $51
DEF NOTE_F5 EQU $52
DEF NOTE_F6 EQU $53
DEF NOTE_F7 EQU $54
DEF NOTE_F10 EQU $57
DEF NOTE_FS2 EQU $5e
DEF NOTE_FS3 EQU $5f
DEF NOTE_FS4 EQU $60
DEF NOTE_FS5 EQU $61
DEF NOTE_FS6 EQU $62
DEF NOTE_FS7 EQU $63
DEF NOTE_FS11 EQU $67
DEF NOTE_G3 EQU $6e
DEF NOTE_G4 EQU $6f
DEF NOTE_G5 EQU $70
DEF NOTE_G6 EQU $71
DEF NOTE_G7 EQU $72
DEF NOTE_G12 EQU $77
DEF NOTE_GS1 EQU $7b
DEF NOTE_GS2 EQU $7c
DEF NOTE_GS3 EQU $7d
DEF NOTE_GS4 EQU $7e
DEF NOTE_GS5 EQU $7f
DEF NOTE_GS6 EQU $80
DEF NOTE_GS7 EQU $81
DEF NOTE_GS8 EQU $82
DEF NOTE_GS9 EQU $83
DEF NOTE_GS10 EQU $84
DEF NOTE_GS11 EQU $85
DEF NOTE_AM1 EQU $88
DEF NOTE_A1 EQU $8a
DEF NOTE_A3 EQU $8c
DEF NOTE_A4 EQU $8d
DEF NOTE_A5 EQU $8e
DEF NOTE_A6 EQU $8f
DEF NOTE_A7 EQU $90
DEF NOTE_AS3 EQU $9b
DEF NOTE_AS4 EQU $9c
DEF NOTE_AS5 EQU $9d
DEF NOTE_AS6 EQU $9e
DEF NOTE_AS7 EQU $9f
DEF NOTE_B2 EQU $a9
DEF NOTE_B3 EQU $aa
DEF NOTE_B4 EQU $ab
DEF NOTE_B5 EQU $ac
DEF NOTE_B6 EQU $ad
DEF NOTE_B7 EQU $ae
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
DEF SCMD_LOOP_START EQU $0c
DEF SCMD_LOOP_END EQU $0d
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
DEF wChanLoopStart EQU $cd02
DEF wChanLoopCtr EQU $cd62
DEF wChanLoopDepth EQU $cd92
DEF wChanCallStack EQU $cdaa
DEF wChanCallDepth EQU $cdda
DEF wChanDetuneSign EQU $cdee
DEF wChanDetune EQU $cdf6
DEF wSavedNR51 EQU $cdfe
DEF wCurMusicId EQU $cdff
DEF wChanVolEnvPtr EQU $ce15
DEF wChanVolEnvIdx EQU $ce25
DEF wChanVolEnvTimer EQU $ce2d
DEF wChanPitchEnvPtr EQU $ce35
DEF wChanPitchEnvIdx EQU $ce45
DEF wChanPeriod EQU $ce4d
DEF wChanPitchEnvTimer EQU $ce5d
DEF wSndFlagE1 EQU $ce65
DEF wSndFlagE2 EQU $ce66
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

; Per-frame driver tick. Called from bank 0 at $04B2.

Sound_Update:
	xor a
	ld e,a
	inc a
	inc a
	inc a
	inc a
	inc a
	ldh [hSndFrameBudget],a
	ld hl,wChanSeqPtr

Loc_400c:
	push hl
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld a,e
	cp $08
	jp z,Sound_UpdateChannels
	xor a
	cp h
	jr z,Loc_4045
	ld d,a
	dec a
	cp [hl]
	jr z,Loc_404b
	ld hl,hChanNoteTimer
	add hl,de
	xor a
	cp [hl]
	jr nz,Loc_4045
	ld hl,wChanAdvanced
	add hl,de
	inc a
	cp [hl]
	jr z,Loc_4045
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
	jr z,Loc_404b
	ld b,h
	ld c,l
	ld hl,wChanSeqPtr
	add hl,de
	add hl,de
	ld a,c
	ld [hl+],a
	ld [hl],b

Loc_4045:
	inc e
	pop hl
	inc hl
	inc hl
	jr Loc_400c

Loc_404b:
	ld a,e
	ldh [hSndChan],a

Loc_404e:
	call Sound_ExecCommand
	ld a,[hl]
	inc a
	jr z,Loc_404e
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
	jp Loc_400c

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

Loc_4080:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_4080
	ldh a,[hMusicMaskLatch]
	and a
	jr z,Loc_40bb
	rra
	ldh [hSndMaskShift],a
	ldh a,[hMusicMask]
	ldh [hSndActiveMask],a
	jr nc,Loc_4099
	xor a
	call Sound_DoChannel1

Loc_4099:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40a5
	ld a,$01
	call Sound_DoChannel2

Loc_40a5:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40b1
	ld a,$02
	call Sound_DoChannel3

Loc_40b1:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_40bb
	ld a,$03
	call Sound_DoChannel4

Loc_40bb:
	ldh a,[hSfxMask]
	ld b,a
	ldh a,[hSfxMaskLatch]
	or b
	jr z,Loc_40f2
	rra
	ldh [hSndMaskShift],a
	ld a,b
	ldh [hSndActiveMask],a
	jr nc,Loc_40d0
	ld a,$04
	call Sound_DoChannel1

Loc_40d0:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40dc
	ld a,$05
	call Sound_DoChannel2

Loc_40dc:
	ldh a,[hSndMaskShift]
	rra
	ldh [hSndMaskShift],a
	jr nc,Loc_40e8
	ld a,$06
	call Sound_DoChannel3

Loc_40e8:
	ldh a,[hSndMaskShift]
	rra
	jr nc,Loc_40f2
	ld a,$07
	call Sound_DoChannel4

Loc_40f2:
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
; In:  hl = stream pointer at the $FF escape byte
;      [hSndChan] = channel slot (0-7)

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
	jr z,Loc_42bd
	dec a
	ldh [hSndFrameBudget],a

Loc_42bd:
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
	jp z,Cmd_LoopStart
	dec b
	jp z,Cmd_LoopEnd
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
	jr Loc_4342

Cmd_GateAbs:
	ld d,b
	ld b,h
	ld c,l
	ld hl,wChanGateAbs
	call Sound_StoreGateValue
	xor a

Loc_4342:
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
	jr nc,Loc_4373
	xor a
	ld [de],a
	ld a,[hl+]
	cpl
	inc a
	ld [bc],a
	ret

Loc_4373:
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

Cmd_LoopStart:
	push hl
	ld hl,wChanLoopDepth
	ldh a,[hSndChan]
	ld e,a
	ld d,b
	add hl,de
	ld a,[hl]
	ld b,a
	inc a
	ld [hl],a
	pop hl
	push hl
	ld a,e
	add a,a
	add a,a
	add a,b
	ld e,a
	ld a,[hl]
	ld hl,wChanLoopCtr
	add hl,de
	ld [hl],a
	ld a,e
	add a,a
	ld e,a
	ld hl,wChanLoopStart
	add hl,de
	pop de
	inc de
	push de
	ld a,d
	ld [hl+],a
	ld [hl],e
	pop hl
	ret

Cmd_LoopEnd:
	push hl
	ld hl,wChanLoopDepth
	ldh a,[hSndChan]
	ld e,a
	ld d,b
	add hl,de
	ld c,[hl]
	dec c
	ld a,e
	add a,a
	add a,a
	add a,c
	ld e,a
	ld hl,wChanLoopCtr
	add hl,de
	dec [hl]
	jr z,Loc_43de
	pop hl
	ld a,e
	add a,a
	ld c,a
	ld hl,wChanLoopStart
	add hl,bc
	ld a,[hl+]
	ld l,[hl]
	ld h,a
	ret

Loc_43de:
	ld hl,wChanLoopDepth
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	dec [hl]
	pop hl
	ret

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
	jr nz,Loc_4490
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

Loc_4490:
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
	jr nz,Loc_44d8
	ld a,[hl+]
	ld [bc],a
	inc bc
	ld a,[hl+]
	ld [bc],a
	ret

Loc_44d8:
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
	jr c,Loc_4543
	rlca
	jr c,Loc_451d
	ldh a,[hSndChan]
	and $03
	jr z,Loc_4511

Loc_450c:
	rlc b
	dec a
	jr nz,Loc_450c

Loc_4511:
	ldh a,[hMusicMask]
	and b
	ldh [hMusicMask],a
	ldh a,[hMusicMaskLatch]
	and b
	ldh [hMusicMaskLatch],a
	jr Loc_4543

Loc_451d:
	ldh a,[hSndChan]
	and $03
	jr z,Loc_4528

Loc_4523:
	rlc b
	dec a
	jr nz,Loc_4523

Loc_4528:
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
	jr Loc_4543

Loc_4543:
	ldh a,[hSndChan]
	and $03
	jr z,Loc_455b
	dec a
	jr z,Loc_4569
	dec a
	jr z,Loc_4575

Loc_454f:
	xor a
	ldh [$ffad],a
	ld a,$08
	ldh [rNR42],a
	ld a,$80
	ldh [rNR44],a
	ret

Loc_455b:
	xor a
	ldh [hChanGateTimer],a
	ldh [rNR10],a
	ld a,$08
	ldh [rNR12],a
	ld a,$80
	ldh [rNR14],a
	ret

Loc_4569:
	xor a
	ldh [$ffab],a
	ld a,$08
	ldh [rNR22],a
	ld a,$80
	ldh [rNR24],a
	ret

Loc_4575:
	xor a
	ldh [$ffac],a
	ldh [rNR32],a
	ret

Sound_SilenceChannels:
	ld h,a
	rrc h
	call c,Loc_455b
	rrc h
	call c,Loc_4569
	rrc h
	call c,Loc_4575
	rrc h
	jr c,Loc_454f
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

; Silence and clear the four SFX slots (4-7).

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

; Cold-start the driver.

Sound_Init:
	ld hl,wSfxRequest
	ld b,$3e
	xor a

Loc_45e6:
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45e6
	ld hl,hChanNoteTimer
	ld b,$0c

Loc_45f4:
	ld [hl+],a
	ld [hl+],a
	dec b
	jr nz,Loc_45f4
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
	ld hl,wChanLoopDepth
	add hl,bc
	ld [hl+],a
	ld [hl+],a
	ld [hl+],a
	ld [hl],a
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

; In: a = song id (0-8).

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
	jr z,Loc_46bc
	xor a
	ldh [rNR10],a

Loc_46bc:
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

; In: a = sfx id (0-18).

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
	jr z,Loc_472d
	xor a
	ldh [rNR10],a

Loc_472d:
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
	jr z,Loc_4778

Loc_4774:
	inc hl
	dec a
	jr nz,Loc_4774

Loc_4778:
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
	jp nz,Loc_49c9
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
	jr nc,Loc_47d1
	ld a,b

Loc_47d1:
	sla b
	sra c
	jr nc,Loc_47d8
	add a,b

Loc_47d8:
	sla b
	sra c
	jr nc,Loc_47df
	add a,b

Loc_47df:
	pop bc
	cp d
	jr nz,Loc_47e4
	inc a

Loc_47e4:
	ldh [c],a
	ldh a,[hSndHwChan]
	ld b,a
	ldh a,[hSndActiveMask]

Loc_47ea:
	rra
	dec b
	jr nz,Loc_47ea
	jp nc,Loc_49c9
	dec hl
	push hl
	ld hl,wChanGateMode
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	xor a
	cp [hl]
	jr nz,Loc_481c
	ld hl,wChanGateFrac
	add hl,bc
	ld a,[hl]
	ld hl,hChanNoteTimer
	add hl,bc
	ld e,[hl]
	ld h,b
	ld l,b
	ld d,b

Loc_480b:
	add hl,de
	dec a
	jr nz,Loc_480b
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	inc a
	jr Loc_483a

Loc_481c:
	ld hl,wChanTempo
	add hl,bc
	ld e,[hl]
	ld hl,wChanGateAbs
	add hl,bc
	ld d,[hl]
	xor a
	sra e
	jr nc,Loc_482c
	ld a,d

Loc_482c:
	sla d
	sra e
	jr nc,Loc_4833
	add a,d

Loc_4833:
	sla d
	sra e
	jr nc,Loc_483a
	add a,d

Loc_483a:
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
	jr nz,Loc_4864
	ldh a,[hSndChan]
	and $04
	rrca
	rrca
	ld e,a
	ld hl,wSweepDirty
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_4864
	ld hl,wSweepParams
	add hl,de
	ld de,$0002
	ld c,$10
	call Sub_4ad3

Loc_4864:
	ld hl,wChanTimbre
	ldh a,[hSndChan]
	ld e,a
	add a,a
	ld c,a
	ld b,$00
	add hl,bc
	ld a,e
	and $03
	jr z,Loc_4899
	dec a
	jr z,Loc_489e
	dec a
	jr nz,Loc_48a3
	ld a,[hl+]
	ld h,[hl]
	ld l,a
	ld c,$30
	xor a
	ldh [rNR30],a
	ld d,$04

Loc_4884:
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
	jr nz,Loc_4884
	ld a,$80
	ldh [rNR30],a
	jr Loc_48a3

Loc_4899:
	ld a,[hl]
	ldh [rNR11],a
	jr Loc_48a3

Loc_489e:
	ld a,[hl]
	ldh [rNR21],a
	ld d,$00

Loc_48a3:
	ld c,$ae
	ldh a,[hSndChan]
	ld e,a
	add a,c
	ld c,a
	ldh a,[c]
	dec a
	jr z,Loc_48c0
	dec a
	jr z,Loc_48df
	dec a
	jr z,Loc_48d3

Loc_48b4:
	ld hl,wChanVolume
	add hl,de
	ldh a,[hSndFreqReg]
	dec a
	ld c,a
	ld a,[hl]
	ldh [c],a
	jr Loc_48e9

Loc_48c0:
	ld a,e
	and $03
	ldh a,[hSndFreqReg]
	dec a
	ld c,a
	ld hl,wChanEnvVol
	add hl,de
	ld de,$0008
	call Sub_4ad3
	jr Loc_48e9

Loc_48d3:
	ld hl,wChanPitchEnvIdx
	add hl,de
	ld [hl],d
	ld hl,wChanPitchEnvTimer
	add hl,de
	ld [hl],d
	jr Loc_48b4

Loc_48df:
	ld hl,wChanVolEnvIdx
	add hl,de
	ld [hl],d
	ld hl,wChanVolEnvTimer
	add hl,de
	ld [hl],d

Loc_48e9:
	pop hl
	ld b,[hl]
	ld a,$b8
	cp b
	jp z,Loc_494b
	ldh a,[hSndHwChan]
	cp $04
	jr z,Loc_4955
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
	jr z,Loc_495e
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
	jr z,Loc_4941
	ld h,b
	ld l,b
	ld d,b

Loc_4933:
	add hl,de
	dec c
	jr nz,Loc_4933
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra

Loc_4941:
	pop de
	ld b,a
	ld a,e
	sub b
	ld e,a
	ld a,d
	sbc a,c
	ld d,a
	jr Loc_4987

Loc_494b:
	ldh a,[hSndHwChan]
	ld c,$a9
	add a,c
	ld c,a
	xor a
	ldh [c],a
	jr Loc_49c9

Loc_4955:
	ld a,b
	ldh [rNR43],a
	ld a,$80
	ldh [rNR44],a
	jr Loc_499c

Loc_495e:
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
	jr z,Loc_4983
	ld d,b

Loc_4974:
	add hl,de
	dec c
	jr nz,Loc_4974
	ld a,l
	srl h
	rra
	srl h
	rra
	srl h
	rra
	ld l,a

Loc_4983:
	pop de
	add hl,de
	ld d,h
	ld e,l

Loc_4987:
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

Loc_499c:
	ld hl,wChanPanning
	ld d,$00
	ldh a,[hSndChan]
	ld e,a
	add hl,de
	ld a,[hl]
	dec a
	jr z,Loc_49b0
	dec a
	jr z,Loc_49b4
	ld d,$11
	jr Loc_49b5

Loc_49b0:
	ld d,$10
	jr Loc_49b5

Loc_49b4:
	inc d

Loc_49b5:
	ld b,$ee
	ld a,e
	and $03
	jr z,Loc_49c3

Loc_49bc:
	rlc b
	rlc d
	dec a
	jr nz,Loc_49bc

Loc_49c3:
	ldh a,[rNR51]
	and b
	or d
	ldh [rNR51],a

Loc_49c9:
	ld hl,hChanNoteTimer
	ldh a,[hSndChan]
	ld c,a
	ld b,$00
	add hl,bc
	dec [hl]
	ldh a,[hSndHwChan]
	ld d,a
	ldh a,[hSndActiveMask]

Loc_49d8:
	rra
	dec d
	jr nz,Loc_49d8
	ret nc
	ld hl,hChanGateTimer
	ld a,c
	and $03
	ld e,a
	add hl,de
	xor a
	cp [hl]
	jr z,Loc_49fb
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
	jp z,Loc_4a87
	dec a
	jr z,Loc_4a24
	ret

Loc_49fb:
	dec [hl]
	ld a,e
	cp d
	jr z,Loc_4a0f
	dec a
	jr z,Loc_4a18
	dec a
	jr z,Loc_4a21
	ld a,$08
	ldh [rNR42],a
	ld a,$80
	ldh [rNR44],a
	ret

Loc_4a0f:
	ld a,$08
	ldh [rNR12],a
	ld a,$80
	ldh [rNR14],a
	ret

Loc_4a18:
	ld a,$08
	ldh [rNR22],a
	ld a,$80
	ldh [rNR24],a
	ret

Loc_4a21:
	ldh [rNR32],a
	ret

Loc_4a24:
	ld b,a
	ld hl,wChanPitchEnvTimer
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	ld a,[hl]
	and a
	jr z,Loc_4a32
	dec [hl]
	ret

Loc_4a32:
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
	jr nz,Loc_4a60
	inc de
	ld a,[de]
	ld [hl],a

Loc_4a60:
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
	jr z,Loc_4a7e
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

Loc_4a7e:
	ld a,e
	add a,b
	ldh [c],a
	ld a,d
	adc a,$00
	inc c
	ldh [c],a
	ret

Loc_4a87:
	ld b,a
	ld hl,wChanVolEnvTimer
	ldh a,[hSndChan]
	ld c,a
	add hl,bc
	ld a,[hl]
	and a
	jr z,Loc_4a95
	dec [hl]
	ret

Loc_4a95:
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
	jr nz,Loc_4abe
	inc de
	ld a,[de]
	ld [hl],a

Loc_4abe:
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

Sub_4ad3:
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
	dw SfxHeader_18	; 18

WavePattern0:
	db $04, $27, $46, $72, $93, $04, $27, $24, $73, $94, $04, $70, $55, $16, $36, $00

WavePattern1:
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $22, $22, $21, $21, $21, $00, $00, $00

WavePattern2:
	db $00, $22, $44, $46, $68, $6a, $6c, $ee, $47, $46, $45, $44, $33, $22, $21, $00
	db $02, $01, $04, $01, $06, $01, $00, $ff, $02, $01, $04, $01, $06, $0a, $06, $0a
	db $00, $ff, $02, $02, $04, $02, $06, $02, $00, $ff, $04, $02, $06, $03, $00, $ff
	db $04, $01, $06, $05, $00, $ff, $04, $02, $06, $0a, $ff, $02, $01, $05, $01, $07
	db $01, $04, $01, $06, $01, $07, $02, $08, $02, $07, $02, $08, $02, $f0, $0a, $04
	db $02, $06, $0a, $06, $07, $00, $ff, $09, $01, $06, $01, $02, $01, $01, $01, $02
	db $01, $01, $02, $02, $02, $03, $02, $03, $02, $03, $02, $03, $01, $02, $f0, $0a
	db $09, $01, $05, $01, $03, $01, $02, $01, $02, $01, $01, $02, $02, $01, $01, $05
	db $f0, $0a, $02, $01, $05, $01, $03, $0a, $02, $0a, $03, $05, $02, $03, $01, $01
	db $01, $01, $01, $05, $f0, $0a, $0f, $03, $08, $01, $06, $01, $07, $03, $f0, $03
	db $03, $01, $02, $01, $01, $01, $02, $01, $01, $01, $02, $01, $01, $01, $02, $01
	db $01, $01, $01, $f0, $0a, $05, $01, $03, $01, $02, $01, $03, $01, $02, $01, $03
	db $01, $02, $01, $03, $01, $02, $01, $01, $f0, $0a, $05, $01, $07, $01, $05, $03
	db $04, $07, $03, $01, $04, $07, $05, $07, $04, $05, $03, $01, $01, $05, $f0, $0a
	db $04, $02, $06, $03, $f0, $03, $00, $0c, $06, $01, $02, $01, $fa, $01, $fe, $01
	db $80, $02, $00, $11, $01, $03, $01, $03, $fe, $01, $fe, $01, $80, $02, $00, $0c
	db $02, $02, $02, $02, $fe, $02, $fe, $02, $80, $02, $00, $02, $ff, $08, $02, $09
	db $80, $00

MusicHeader_00:
	dw Music00_Ch1	; channel 1
	dw Music00_Ch2	; channel 2
	dw Music00_Ch3	; channel 3
	dw Music00_Ch4	; channel 4

Music00_Ch1:
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_4c54:
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_VOL_ENVELOPE, $cd, $4b
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db NOTE_E4,    $0c	; E4, len 12
	db NOTE_FS4,   $10	; F#4, len 16
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G4,    $0c	; G4, len 12
	db NOTE_A4,    $10	; A4, len 16
	db NOTE_A4,    $04	; A4, len 4
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $05, $00, $02	; volume 5, down, period 2
	db $ff, SCMD_LOOP_START, $04
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db REST,       $03	; rest, 3
	db $ff, SCMD_VOLUME, $05	; volume 5
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B3,    $02	; B3, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS4,   $02	; C#4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $01	; D5, len 1
	db $ff, SCMD_GOTO
	dw Seq_4c54

Music00_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TEMPO, $03	; note length x3

Seq_4cf2:
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS4,   $02	; C#4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db REST,       $02	; rest, 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_ENVELOPE, $0e, $00, $01	; volume 14, down, period 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db REST,       $02	; rest, 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db REST,       $02	; rest, 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_ENVELOPE, $09, $00, $02	; volume 9, down, period 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_VOLUME, $08	; volume 8
	db $ff, SCMD_PITCH_ENVELOPE, $1d, $4c
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_PITCH_ENVELOPE, $1d, $4c
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_GOTO
	dw Seq_4cf2

Music00_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_ABS, $03	; gate = 3 x tempo
	db $ff, SCMD_VOL_ENVELOPE, $17, $4c

Seq_4dff:
	db $ff, SCMD_VOL_ENVELOPE, $17, $4c
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOL_ENVELOPE, $61, $4b
	db NOTE_B2,    $08	; B2, len 8
	db NOTE_CS3,   $08	; C#3, len 8
	db NOTE_D3,    $08	; D3, len 8
	db NOTE_E3,    $08	; E3, len 8
	db $ff, SCMD_GOTO
	dw Seq_4dff

Music00_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_GATE_ABS, $02	; gate = 2 x tempo
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1

Seq_4e96:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_4ef9
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_CALL
	dw Seq_4ef9
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db $ff, SCMD_LOOP_START, $03
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_LOOP_START, $03
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_LOOP_END
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_GOTO
	dw Seq_4e96

Seq_4ef9:
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_RET

MusicHeader_01:
	dw Music01_Ch1	; channel 1
	dw Music01_Ch2	; channel 2
	dw Music01_Ch3	; channel 3
	dw Music01_Ch4	; channel 4

Music01_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db REST,       $06	; rest, 6

Seq_4f23:
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_FS4,   $02	; F#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F4,    $02	; F4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_LOOP_END
	db NOTE_C6,    $02	; C6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $06, $00, $05	; volume 6, down, period 5
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_A4,    $06	; A4, len 6
	db NOTE_B4,    $06	; B4, len 6
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_VOL_ENVELOPE, $8e, $4b
	db $ff, SCMD_CALL
	dw Seq_522e
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_AS5,   $0c	; A#5, len 12
	db $ff, SCMD_CALL
	dw Seq_522e
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_F6,    $06	; F6, len 6
	db NOTE_F6,    $18	; F6, len 24
	db NOTE_F6,    $12	; F6, len 18
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db REST,       $01	; rest, 1
	db $ff, SCMD_CALL
	dw Seq_524c
	db NOTE_F4,    $05	; F4, len 5
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_B4,    $06	; B4, len 6
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $06	; G4, len 6
	db REST,       $01	; rest, 1
	db $ff, SCMD_CALL
	dw Seq_524c
	db NOTE_F4,    $05	; F4, len 5
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db $ff, SCMD_CALL
	dw Seq_5260
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_CALL
	dw Seq_5260
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_GOTO
	dw Seq_4f23

Seq_522e:
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $0c	; G5, len 12
	db $ff, SCMD_RET

Seq_524c:
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_F4,    $0c	; F4, len 12
	db $ff, SCMD_RET

Seq_5260:
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db $ff, SCMD_RET

Music01_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_PANNING, $03	; both

Seq_5286:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOL_ENVELOPE, $8e, $4b
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $02	; rest, 2
	db NOTE_B5,    $04	; B5, len 4
	db REST,       $02	; rest, 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $02	; rest, 2
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $02	; rest, 2
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $06	; E6, len 6
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_D6,    $03	; D6, len 3
	db NOTE_E6,    $04	; E6, len 4
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_B5,    $06	; B5, len 6
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_F5,    $03	; F5, len 3
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_E5,    $03	; E5, len 3
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP_END
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $07, $00, $05	; volume 7, down, period 5
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_E5,    $06	; E5, len 6
	db $ff, SCMD_VOL_ENVELOPE, $8e, $4b
	db $ff, SCMD_CALL
	dw Seq_53e7
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_B5,    $02	; B5, len 2
	db REST,       $02	; rest, 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $06	; B5, len 6
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_CS6,   $0c	; C#6, len 12
	db $ff, SCMD_CALL
	dw Seq_53e7
	db $ff, SCMD_ENVELOPE, $04, $00, $08	; volume 4, down, period 8
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_F6,    $06	; F6, len 6
	db NOTE_A6,    $06	; A6, len 6
	db NOTE_C7,    $06	; C7, len 6
	db NOTE_C7,    $10	; C7, len 16
	db NOTE_C7,    $08	; C7, len 8
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_D7,    $12	; D7, len 18
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOLUME, $05	; volume 5
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_CALL
	dw Seq_5405
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_B4,    $06	; B4, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $06	; D5, len 6
	db $ff, SCMD_CALL
	dw Seq_5405
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_CALL
	dw Seq_5419
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $05, $00, $02	; volume 5, down, period 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_CALL
	dw Seq_5419
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_GOTO
	dw Seq_5286

Seq_53e7:
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db REST,       $02	; rest, 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $0c	; C6, len 12
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $0c	; C6, len 12
	db $ff, SCMD_RET

Seq_5405:
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_A4,    $0c	; A4, len 12
	db NOTE_A4,    $06	; A4, len 6
	db $ff, SCMD_RET

Seq_5419:
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_RET

Music01_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_VOL_ENVELOPE, $61, $4b
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db REST,       $04	; rest, 4
	db NOTE_B4,    $01	; B4, len 1
	db REST,       $01	; rest, 1

Seq_5449:
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_VOL_ENVELOPE, $61, $4b
	db $ff, SCMD_LOOP_START, $02
	db NOTE_C5,    $03	; C5, len 3
	db REST,       $0c	; rest, 12
	db REST,       $03	; rest, 3
	db REST,       $04	; rest, 4
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db NOTE_C5,    $03	; C5, len 3
	db REST,       $02	; rest, 2
	db REST,       $03	; rest, 3
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db NOTE_D5,    $03	; D5, len 3
	db REST,       $0c	; rest, 12
	db REST,       $03	; rest, 3
	db REST,       $04	; rest, 4
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db NOTE_C5,    $03	; C5, len 3
	db REST,       $02	; rest, 2
	db REST,       $03	; rest, 3
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_A4,    $03	; A4, len 3
	db REST,       $03	; rest, 3
	db NOTE_A5,    $06	; A5, len 6
	db NOTE_GS4,   $03	; G#4, len 3
	db REST,       $03	; rest, 3
	db NOTE_GS5,   $06	; G#5, len 6
	db NOTE_G4,    $03	; G4, len 3
	db REST,       $03	; rest, 3
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_FS4,   $03	; F#4, len 3
	db REST,       $03	; rest, 3
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_F4,    $03	; F4, len 3
	db REST,       $03	; rest, 3
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_G4,    $03	; G4, len 3
	db REST,       $03	; rest, 3
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_C5,    $03	; C5, len 3
	db REST,       $0c	; rest, 12
	db REST,       $07	; rest, 7
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_VOL_ENVELOPE, $61, $4b
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_LOOP_END
	db NOTE_C5,    $06	; C5, len 6
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db $ff, SCMD_GATE_FRAC, $04	; gate = 4/8 of note length
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_E5,    $06	; E5, len 6
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_F5,    $06	; F5, len 6
	db REST,       $10	; rest, 16
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db REST,       $10	; rest, 16
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $06	; D5, len 6
	db REST,       $10	; rest, 16
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_F5,    $06	; F5, len 6
	db REST,       $10	; rest, 16
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db REST,       $10	; rest, 16
	db NOTE_E5,    $01	; E5, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_LOOP_START, $04
	db NOTE_D5,    $03	; D5, len 3
	db REST,       $03	; rest, 3
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $08
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $04	; rest, 4
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_LOOP_START, $05
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOL_ENVELOPE, $67, $4b
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_C5,    $04	; C5, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOL_ENVELOPE, $67, $4b
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $0c	; rest, 12
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $04	; G4, len 4
	db REST,       $02	; rest, 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_GOTO
	dw Seq_5449

Music01_Ch4:
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db REST,       $04	; rest, 4
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)

Seq_55b6:
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $07
	db $ff, SCMD_CALL
	dw Seq_56db
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E0,    $01	; E2, len 1 (clamped from E0)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_56db
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E0,    $01	; E2, len 1 (clamped from E0)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP_END
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C2,    $01	; C2, len 1
	db REST,       $01	; rest, 1
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_56c1
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E0,    $01	; E2, len 1 (clamped from E0)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM2,   $02	; C2, len 2 (clamped from C-2)
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_56c1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_56c1
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E0,    $01	; E2, len 1 (clamped from E0)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP_START, $09
	db $ff, SCMD_CALL
	dw Seq_56a5
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db NOTE_CS3,   $02	; C#3, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_CALL
	dw Seq_56b9
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E0,    $04	; E2, len 4 (clamped from E0)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_GOTO
	dw Seq_55b6

Seq_56a5:
	db NOTE_FS7,   $02	; F#7, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_RET

Seq_56b9:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_RET

Seq_56c1:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_RET

Seq_56db:
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_RET

MusicHeader_02:
	dw Music02_Ch1	; channel 1
	dw Music02_Ch2	; channel 2
	dw Music02_Ch3	; channel 3
	dw Music02_Ch4	; channel 4

Music02_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_VOLUME, $07	; volume 7
	db $ff, SCMD_ENVELOPE, $01, $01, $07	; volume 1, up, period 7
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS5,   $0c	; F#5, len 12
	db NOTE_A5,    $0c	; A5, len 12
	db NOTE_AS5,   $0c	; A#5, len 12
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_C6,    $18	; C6, len 24
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_SWEEP, $01, $01, $07	; NR10=$01, $01, $07
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db $ff, SCMD_SWEEP_OFF

Seq_5736:
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $03, $00, $07	; volume 3, down, period 7
	db REST,       $06	; rest, 6
	db REST,       $04	; rest, 4
	db $ff, SCMD_CALL
	dw Seq_58ee
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $06	; D4, len 6
	db REST,       $06	; rest, 6
	db $ff, SCMD_CALL
	dw Seq_58ee
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $01, $01, $03	; volume 1, up, period 3
	db $ff, SCMD_LOOP_START, $0a
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_ENVELOPE, $01, $01, $02	; volume 1, up, period 2
	db $ff, SCMD_LOOP_START, $02
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_CALL
	dw Seq_58b7
	db NOTE_F7,    $02	; F7, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $03, $00, $03	; volume 3, down, period 3
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $02	; volume 2, down, period 2
	db $ff, SCMD_CALL
	dw Seq_58a3
	db $ff, SCMD_ENVELOPE, $01, $00, $03	; volume 1, down, period 3
	db $ff, SCMD_CALL
	dw Seq_58a3
	db $ff, SCMD_ENVELOPE, $01, $00, $01	; volume 1, down, period 1
	db $ff, SCMD_CALL
	dw Seq_58a3
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $03, $00, $03	; volume 3, down, period 3
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $02	; volume 2, down, period 2
	db $ff, SCMD_CALL
	dw Seq_58ad
	db $ff, SCMD_ENVELOPE, $01, $00, $03	; volume 1, down, period 3
	db $ff, SCMD_CALL
	dw Seq_58ad
	db $ff, SCMD_ENVELOPE, $01, $00, $01	; volume 1, down, period 1
	db $ff, SCMD_CALL
	dw Seq_58ad
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db $ff, SCMD_CALL
	dw Seq_5b5d
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db REST,       $0c	; rest, 12
	db NOTE_DS5,   $0c	; D#5, len 12
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_D6,    $04	; D6, len 4
	db $ff, SCMD_ENVELOPE, $05, $00, $05	; volume 5, down, period 5
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_F6,    $04	; F6, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $07	; G6, len 7
	db NOTE_C6,    $18	; C6, len 24
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_ENVELOPE, $05, $00, $05	; volume 5, down, period 5
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_D6,    $07	; D6, len 7
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_B5,    $0c	; B5, len 12
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_B5,    $04	; B5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db REST,       $02	; rest, 2
	db $ff, SCMD_CALL
	dw Seq_58b7
	db $ff, SCMD_GOTO
	dw Seq_5736

Seq_5889:
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db $ff, SCMD_RET

Seq_58a3:
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db $ff, SCMD_RET

Seq_58ad:
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_RET

Seq_58b7:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db $ff, SCMD_RET

Seq_58ee:
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_D5,    $0a	; D5, len 10
	db REST,       $08	; rest, 8
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $0a	; G5, len 10
	db REST,       $08	; rest, 8
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_RET

Music02_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $01, $01, $07	; volume 1, up, period 7
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_C6,    $0c	; C6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_F6,    $18	; F6, len 24
	db NOTE_DS6,   $18	; D#6, len 24

Seq_5933:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_VOL_ENVELOPE, $a7, $4b
	db REST,       $06	; rest, 6
	db REST,       $04	; rest, 4
	db $ff, SCMD_CALL
	dw Seq_5bb7
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $06	; D5, len 6
	db REST,       $06	; rest, 6
	db $ff, SCMD_CALL
	dw Seq_5bb7
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db REST,       $18	; rest, 24
	db REST,       $08	; rest, 8
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_B5,    $06	; B5, len 6
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D5,    $10	; D5, len 16
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_D5,    $10	; D5, len 16
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_D5,    $08	; D5, len 8
	db $ff, SCMD_VOLUME, $01	; volume 1
	db NOTE_D5,    $06	; D5, len 6
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_CALL
	dw Seq_5a7f
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db REST,       $0c	; rest, 12
	db $ff, SCMD_CALL
	dw Seq_5af8
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_G5,    $06	; G5, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_A5,    $05	; A5, len 5
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_C6,    $06	; C6, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $02	; volume 6, down, period 2
	db NOTE_D6,    $0c	; D6, len 12
	db REST,       $02	; rest, 2
	db $ff, SCMD_CALL
	dw Seq_5af8
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_G5,    $06	; G5, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_ENVELOPE, $05, $00, $07	; volume 5, down, period 7
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_DS6,   $06	; D#6, len 6
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $03, $00, $05	; volume 3, down, period 5
	db NOTE_DS6,   $04	; D#6, len 4
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_CALL
	dw Seq_5b5d
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $08	; rest, 8
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_C5,    $0c	; C5, len 12
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_ENVELOPE, $05, $00, $05	; volume 5, down, period 5
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_D6,    $04	; D6, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db REST,       $01	; rest, 1
	db NOTE_DS6,   $07	; D#6, len 7
	db NOTE_A5,    $18	; A5, len 24
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_DS5,   $01	; D#5, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $05, $00, $05	; volume 5, down, period 5
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $07	; A#5, len 7
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_G5,    $10	; G5, len 16
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_G5,    $0c	; G5, len 12
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_CALL
	dw Seq_5a7f
	db $ff, SCMD_GOTO
	dw Seq_5933

Seq_5a7f:
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db NOTE_F7,    $02	; F7, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_G7,    $02	; G7, len 2
	db $ff, SCMD_RET
	db $70, $06, $8e, $06, $8e, $01, $9d, $05, $08, $04, $26, $06, $70, $06, $9d, $0c
	db $b8, $02, $70, $06, $8e, $06, $8e, $01, $9d, $05, $08, $04, $26, $06, $70, $06
	db $9d, $06, $8e, $06, $b8, $02, $52, $06, $70, $06, $7f, $01, $8e, $05, $9d, $04
	db $08, $06, $70, $06, $52, $0c, $b8, $02, $ff, $10

Seq_5af8:
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_A5,    $06	; A5, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $05	; A#5, len 5
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_AS5,   $0c	; A#5, len 12
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_A5,    $06	; A5, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_AS5,   $05	; A#5, len 5
	db NOTE_C6,    $04	; C6, len 4
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_D6,    $06	; D6, len 6
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_AS5,   $06	; A#5, len 6
	db NOTE_A5,    $06	; A5, len 6
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_F5,    $06	; F5, len 6
	db NOTE_G5,    $06	; G5, len 6
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_A5,    $05	; A5, len 5
	db NOTE_AS5,   $04	; A#5, len 4
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C6,    $06	; C6, len 6
	db NOTE_G5,    $06	; G5, len 6
	db NOTE_F5,    $0e	; F5, len 14
	db $ff, SCMD_RET

Seq_5b5d:
	db NOTE_AS5,   $10	; A#5, len 16
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_FS5,   $0e	; F#5, len 14
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $0c	; C#5, len 12
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E5,    $06	; E5, len 6
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_AS4,   $18	; A#4, len 24
	db $ff, SCMD_RET

Seq_5bb7:
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_B5,    $03	; B5, len 3
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_F5,    $0a	; F5, len 10
	db REST,       $08	; rest, 8
	db NOTE_E6,    $05	; E6, len 5
	db REST,       $01	; rest, 1
	db NOTE_D6,    $08	; D6, len 8
	db REST,       $0a	; rest, 10
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $08	; C6, len 8
	db NOTE_B5,    $06	; B5, len 6
	db NOTE_G5,    $06	; G5, len 6
	db $ff, SCMD_RET

Music02_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_G4,    $0c	; G4, len 12
	db NOTE_B4,    $0c	; B4, len 12
	db NOTE_C5,    $0c	; C5, len 12
	db NOTE_CS5,   $0c	; C#5, len 12
	db NOTE_D5,    $18	; D5, len 24
	db NOTE_D5,    $18	; D5, len 24

Seq_5bf9:
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_B4,    $06	; B4, len 6
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_B4,    $02	; B4, len 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_A4,    $06	; A4, len 6
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_C5,    $06	; C5, len 6
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_FS4,   $06	; F#4, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_D5,    $06	; D5, len 6
	db NOTE_FS4,   $06	; F#4, len 6
	db NOTE_G4,    $06	; G4, len 6
	db NOTE_A4,    $06	; A4, len 6
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_5cdf
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_5889
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_5cfb
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_5d19
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_5cfb
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_5d19
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_F4,    $08	; F4, len 8
	db REST,       $02	; rest, 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_GS4,   $06	; G#4, len 6
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_GS4,   $08	; G#4, len 8
	db NOTE_GS4,   $04	; G#4, len 4
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db NOTE_B4,    $0c	; B4, len 12
	db NOTE_GS4,   $0c	; G#4, len 12
	db NOTE_FS5,   $0c	; F#5, len 12
	db NOTE_CS4,   $0c	; C#4, len 12
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_CS4,   $0c	; C#4, len 12
	db NOTE_B4,    $0c	; B4, len 12
	db NOTE_FS4,   $0c	; F#4, len 12
	db NOTE_AS4,   $0c	; A#4, len 12
	db NOTE_FS4,   $0c	; F#4, len 12
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_E4,    $0c	; E4, len 12
	db NOTE_AS4,   $0c	; A#4, len 12
	db NOTE_E4,    $0c	; E4, len 12
	db NOTE_CS5,   $0c	; C#5, len 12
	db NOTE_C4,    $0c	; C4, len 12
	db NOTE_DS4,   $0c	; D#4, len 12
	db NOTE_C4,    $0c	; C4, len 12
	db NOTE_AS4,   $0c	; A#4, len 12
	db NOTE_F3,    $0c	; F3, len 12
	db NOTE_A3,    $0c	; A3, len 12
	db NOTE_F3,    $0c	; F3, len 12
	db NOTE_DS4,   $0c	; D#4, len 12
	db NOTE_G3,    $0c	; G3, len 12
	db NOTE_D4,    $0c	; D4, len 12
	db NOTE_G3,    $0c	; G3, len 12
	db NOTE_G4,    $0c	; G4, len 12
	db NOTE_DS4,   $0c	; D#4, len 12
	db NOTE_DS5,   $0c	; D#5, len 12
	db NOTE_F4,    $0c	; F4, len 12
	db NOTE_F5,    $0c	; F5, len 12
	db $ff, SCMD_GOTO
	dw Seq_5bf9

Seq_5cdf:
	db NOTE_G4,    $0a	; G4, len 10
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $04	; rest, 4
	db NOTE_E4,    $02	; E4, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_RET

Seq_5cfb:
	db NOTE_C5,    $09	; C5, len 9
	db REST,       $01	; rest, 1
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $06	; A#4, len 6
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $04	; rest, 4
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $04	; rest, 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_RET

Seq_5d19:
	db NOTE_F4,    $09	; F4, len 9
	db REST,       $01	; rest, 1
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $04	; rest, 4
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_DS4,   $06	; D#4, len 6
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $04	; rest, 4
	db NOTE_A3,    $02	; A3, len 2
	db REST,       $04	; rest, 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_RET

Music02_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $07	; +7/8 semitone
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db $ff, SCMD_CALL
	dw Seq_5dba
	db $ff, SCMD_CALL
	dw Seq_5df3
	db $ff, SCMD_CALL
	dw Seq_5dba
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_CS2,   $02	; C#2, len 2
	db REST,       $04	; rest, 4
	db NOTE_CS2,   $02	; C#2, len 2
	db REST,       $04	; rest, 4
	db NOTE_CS2,   $02	; C#2, len 2
	db REST,       $04	; rest, 4
	db NOTE_CS2,   $02	; C#2, len 2
	db REST,       $02	; rest, 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1

Seq_5d6a:
	db $ff, SCMD_LOOP_START, $07
	db $ff, SCMD_CALL
	dw Seq_5dba
	db $ff, SCMD_CALL
	dw Seq_5df3
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_5dba
	db $ff, SCMD_CALL
	dw Seq_5e2c
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_5e58
	db $ff, SCMD_CALL
	dw Seq_5e8d
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_5e58
	db $ff, SCMD_CALL
	dw Seq_5e2c
	db $ff, SCMD_LOOP_START, $04
	db $ff, SCMD_CALL
	dw Seq_5e58
	db $ff, SCMD_CALL
	dw Seq_5e8d
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $07
	db $ff, SCMD_CALL
	dw Seq_5e58
	db $ff, SCMD_CALL
	dw Seq_5e8d
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_5e58
	db $ff, SCMD_CALL
	dw Seq_5e2c
	db $ff, SCMD_GOTO
	dw Seq_5d6a

Seq_5dba:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $03	; C4, len 3
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $02	; rest, 2
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $03, $00, $02	; volume 3, down, period 2
	db NOTE_C4,    $03	; C4, len 3
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_RET

Seq_5df3:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $03	; C4, len 3
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $02	; rest, 2
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $03, $00, $02	; volume 3, down, period 2
	db NOTE_C4,    $03	; C4, len 3
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db $ff, SCMD_RET

Seq_5e2c:
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $03	; rest, 3
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $03, $00, $07	; volume 3, down, period 7
	db NOTE_C2,    $05	; C2, len 5
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $02	; rest, 2
	db NOTE_C2,    $06	; C2, len 6
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_RET

Seq_5e58:
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $02	; rest, 2
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $05	; C4, len 5
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_RET

Seq_5e8d:
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $03	; rest, 3
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $02	; rest, 2
	db NOTE_CM2,   $01	; C2, len 1 (clamped from C-2)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_C4,    $04	; C4, len 4
	db REST,       $02	; rest, 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_RET

MusicHeader_03:
	dw Music03_Ch1	; channel 1
	dw Music03_Ch2	; channel 2
	dw Music03_Ch3	; channel 3
	dw Music03_Ch4	; channel 4

Music03_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOL_ENVELOPE, $a7, $4b

Seq_5edf:
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $0c	; C5, len 12
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_G4,    $10	; G4, len 16
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $10	; C5, len 16
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_G4,    $10	; G4, len 16
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $03	; D5, len 3
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_E4,    $08	; E4, len 8
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_G4,    $08	; G4, len 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_B4,    $08	; B4, len 8
	db $ff, SCMD_GOTO
	dw Seq_5edf

Music03_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $41, $4c
	db $ff, SCMD_GOTO
	dw Seq_5edf

Music03_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_VOL_ENVELOPE, $59, $4b

Seq_5f67:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $08	; G4, len 8
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_C5,    $04	; C5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G3,    $02	; G3, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_GOTO
	dw Seq_5f67

Music03_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1

Seq_5fd6:
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_LOOP_START, $07
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $04	; C4, len 4
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_GOTO
	dw Seq_5fd6

MusicHeader_04:
	dw Music04_Ch1	; channel 1
	dw Music04_Ch2	; channel 2
	dw Music04_Ch3	; channel 3
	dw Music04_Ch4	; channel 4

Music04_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $06	; note length x6

Seq_6010:
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_VOL_ENVELOPE, $d7, $4b
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_CALL
	dw Seq_60af
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOL_ENVELOPE, $d7, $4b
	db $ff, SCMD_CALL
	dw Seq_6160
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOL_ENVELOPE, $d7, $4b
	db NOTE_D6,    $03	; D6, len 3
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db NOTE_G3,    $01	; G3, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_D4,    $01	; D4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_D4,    $01	; D4, len 1
	db NOTE_A3,    $01	; A3, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B3,    $01	; B3, len 1
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db $ff, SCMD_GOTO
	dw Seq_6010

Seq_60af:
	db $ff, SCMD_PANNING, $03	; both
	db REST,       $02	; rest, 2
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_VOL_ENVELOPE, $d7, $4b
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_RET

Seq_6160:
	db REST,       $02	; rest, 2
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_A4,    $06	; A4, len 6
	db NOTE_A4,    $02	; A4, len 2
	db REST,       $01	; rest, 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_GS5,   $03	; G#5, len 3
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_AS4,   $04	; A#4, len 4
	db $ff, SCMD_ENVELOPE, $00, $01, $07	; volume 0, up, period 7
	db NOTE_G5,    $06	; G5, len 6
	db $ff, SCMD_RET

Music04_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_621e
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_6304
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_PITCH_ENVELOPE, $41, $4c
	db $ff, SCMD_CALL
	dw Seq_6342
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_D5,    $01	; D5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_F4,    $01	; F4, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G4,    $01	; G4, len 1
	db NOTE_D4,    $01	; D4, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $01	; E4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_GOTO
	dw Music04_Ch2

Seq_621e:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_ENVELOPE, $08, $00, $02	; volume 8, down, period 2
	db REST,       $02	; rest, 2
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_ENVELOPE, $07, $00, $03	; volume 7, down, period 3
	db NOTE_F5,    $01	; F5, len 1
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_F5,    $02	; F5, len 2
	db REST,       $02	; rest, 2
	db NOTE_E5,    $02	; E5, len 2
	db REST,       $02	; rest, 2
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $03	; volume 3
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_C5,    $02	; C5, len 2
	db REST,       $02	; rest, 2
	db $ff, SCMD_VOLUME, $04	; volume 4
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_RET

Seq_6304:
	db $ff, SCMD_VOL_ENVELOPE, $b9, $4b
	db REST,       $02	; rest, 2
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C5,    $08	; C5, len 8
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_C6,    $03	; C6, len 3
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_AS5,   $06	; A#5, len 6
	db $ff, SCMD_RET

Seq_6342:
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db NOTE_FS5,   $06	; F#5, len 6
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_RET

Music04_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b

Seq_637f:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_AS3,   $01	; A#3, len 1
	db REST,       $01	; rest, 1
	db NOTE_AS3,   $01	; A#3, len 1
	db REST,       $01	; rest, 1
	db NOTE_AS3,   $04	; A#3, len 4
	db REST,       $02	; rest, 2
	db NOTE_F4,    $02	; F4, len 2
	db REST,       $02	; rest, 2
	db NOTE_AS3,   $08	; A#3, len 8
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_A3,    $01	; A3, len 1
	db REST,       $01	; rest, 1
	db NOTE_A3,    $01	; A3, len 1
	db REST,       $01	; rest, 1
	db NOTE_A3,    $04	; A3, len 4
	db REST,       $02	; rest, 2
	db NOTE_A3,    $02	; A3, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_AS3,   $01	; A#3, len 1
	db REST,       $01	; rest, 1
	db NOTE_AS3,   $01	; A#3, len 1
	db REST,       $01	; rest, 1
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_F4,    $04	; F4, len 4
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_AS3,   $04	; A#3, len 4
	db NOTE_A3,    $01	; A3, len 1
	db REST,       $01	; rest, 1
	db NOTE_A3,    $01	; A3, len 1
	db REST,       $01	; rest, 1
	db NOTE_A3,    $06	; A3, len 6
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_GS3,   $04	; G#3, len 4
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db REST,       $02	; rest, 2
	db NOTE_G4,    $02	; G4, len 2
	db REST,       $02	; rest, 2
	db NOTE_F4,    $08	; F4, len 8
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_F5,    $01	; F5, len 1
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_F4,    $02	; F4, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_CS4,   $02	; C#4, len 2
	db REST,       $02	; rest, 2
	db REST,       $02	; rest, 2
	db NOTE_CS4,   $02	; C#4, len 2
	db REST,       $02	; rest, 2
	db NOTE_DS4,   $08	; D#4, len 8
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_DS4,   $02	; D#4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_AS4,   $02	; A#4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_C4,    $06	; C4, len 6
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_E4,    $04	; E4, len 4
	db $ff, SCMD_GOTO
	dw Seq_637f

Music04_Ch4:
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1

Seq_64d0:
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $06	; C2, len 6 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db REST,       $02	; rest, 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db NOTE_CSM1,  $02	; C#2, len 2 (clamped from C#-1)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db $ff, SCMD_CALL
	dw Seq_65fa
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_CALL
	dw Seq_65fa
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db $ff, SCMD_CALL
	dw Seq_65da
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_CALL
	dw Seq_65da
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_CALL
	dw Seq_65da
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_CALL
	dw Seq_65da
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $04	; C2, len 4
	db NOTE_CS1,   $02	; C#2, len 2 (clamped from C#1)
	db NOTE_CS0,   $02	; C#2, len 2 (clamped from C#0)
	db NOTE_C1,    $02	; C2, len 2 (clamped from C1)
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db $ff, SCMD_LOOP_START, $02
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_LOOP_END
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db $ff, SCMD_GOTO
	dw Seq_64d0

Seq_65da:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

Seq_65fa:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

MusicHeader_05:
	dw Music05_Ch1	; channel 1
	dw Music05_Ch2	; channel 2
	dw Music05_Ch3	; channel 3
	dw Music05_Ch4	; channel 4

Music05_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $01	; D6, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D6,    $01	; D6, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $01	; C6, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $01	; C6, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B4,    $01	; B4, len 1
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $01	; B4, len 1
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $04, $00, $07	; volume 4, down, period 7
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $03, $00, $07	; volume 3, down, period 7
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $02, $00, $07	; volume 2, down, period 7
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $01, $00, $07	; volume 1, down, period 7
	db NOTE_GS4,   $02	; G#4, len 2
	db $ff, SCMD_STOP

Music05_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOL_ENVELOPE, $01, $4c
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_D5,    $04	; D5, len 4
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_B4,    $04	; B4, len 4
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_GS5,   $04	; G#5, len 4
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_E4,    $08	; E4, len 8
	db $ff, SCMD_STOP

Music05_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $06	; note length x6
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOL_ENVELOPE, $86, $4b
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db NOTE_C4,    $06	; C4, len 6
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db NOTE_AS4,   $01	; A#4, len 1
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db NOTE_B3,    $04	; B3, len 4
	db NOTE_FS4,   $04	; F#4, len 4
	db NOTE_B3,    $04	; B3, len 4
	db $ff, SCMD_GATE_FRAC, $05	; gate = 5/8 of note length
	db NOTE_D5,    $01	; D5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_GS4,   $02	; G#4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db NOTE_E3,    $08	; E3, len 8
	db $ff, SCMD_STOP

Music05_Ch4:
	db $ff, SCMD_TEMPO, $06	; note length x6
	db REST,       $04	; rest, 4
	db $ff, SCMD_STOP

MusicHeader_06:
	dw Music06_Ch1	; channel 1
	dw Music06_Ch2	; channel 2
	dw Music06_Ch3	; channel 3
	dw Music06_Ch4	; channel 4

Music06_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1

Seq_6859:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $04	; A5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $04	; G5, len 4
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_GOTO
	dw Seq_6859

Music06_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c

Seq_68d9:
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_A5,    $18	; A5, len 24
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_D6,    $10	; D6, len 16
	db NOTE_CS6,   $18	; C#6, len 24
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_B5,    $10	; B5, len 16
	db NOTE_FS6,   $10	; F#6, len 16
	db NOTE_E6,    $18	; E6, len 24
	db NOTE_CS6,   $08	; C#6, len 8
	db NOTE_D6,    $10	; D6, len 16
	db NOTE_B6,    $10	; B6, len 16
	db NOTE_A6,    $10	; A6, len 16
	db NOTE_A6,    $10	; A6, len 16
	db NOTE_A6,    $08	; A6, len 8
	db NOTE_A6,    $0c	; A6, len 12
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_A6,    $04	; A6, len 4
	db NOTE_A6,    $06	; A6, len 6
	db NOTE_A6,    $01	; A6, len 1
	db $ff, SCMD_GOTO
	dw Seq_68d9

Music06_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOL_ENVELOPE, $67, $4b

Seq_691e:
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_D4,    $06	; D4, len 6
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_E4,    $06	; E4, len 6
	db NOTE_CS5,   $06	; C#5, len 6
	db NOTE_G4,    $04	; G4, len 4
	db $ff, SCMD_GOTO
	dw Seq_691e

Music06_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_GATE_FRAC, $02	; gate = 2/8 of note length

Seq_6940:
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db REST,       $01	; rest, 1
	db NOTE_CM1,   $01	; C2, len 1 (clamped from C-1)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_EM1,   $04	; E2, len 4 (clamped from E-1)
	db $ff, SCMD_GOTO
	dw Seq_6940

MusicHeader_07:
	dw Music07_Ch1	; channel 1
	dw Music07_Ch2	; channel 2
	dw Music07_Ch3	; channel 3
	dw Music07_Ch4	; channel 4

Music07_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db REST,       $18	; rest, 24

Seq_697d:
	db $ff, SCMD_ENVELOPE, $05, $00, $02	; volume 5, down, period 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $01	; D5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B4,    $01	; B4, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D5,    $01	; D5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A4,    $01	; A4, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_GS4,   $01	; G#4, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $01	; E4, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS4,   $01	; G#4, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $01	; E4, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_D4,    $01	; D4, len 1
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS5,   $01	; C#5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A4,    $01	; A4, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS5,   $01	; C#5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A4,    $01	; A4, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G4,    $01	; G4, len 1
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_ENVELOPE, $06, $00, $02	; volume 6, down, period 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_AS5,   $02	; A#5, len 2
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_F5,    $02	; F5, len 2
	db $ff, SCMD_ENVELOPE, $06, $00, $03	; volume 6, down, period 3
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS5,   $02	; G#5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS4,   $02	; A#4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_VOLUME, $01	; volume 1
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_VOLUME, $05	; volume 5
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_CALL
	dw Seq_6c85
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_CALL
	dw Seq_6c2a
	db $ff, SCMD_CALL
	dw Seq_6c2a
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_VOL_ENVELOPE, $ec, $4b
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D6,    $06	; D6, len 6
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A5,    $06	; A5, len 6
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $0c	; C6, len 12
	db NOTE_B5,    $0c	; B5, len 12
	db NOTE_B5,    $0c	; B5, len 12
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_C5,    $02	; C5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D6,    $0c	; D6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_C6,    $0c	; C6, len 12
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_D6,    $0c	; D6, len 12
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_FS5,   $02	; F#5, len 2
	db NOTE_DS5,   $02	; D#5, len 2
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_ENVELOPE, $03, $00, $01	; volume 3, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $03, $00, $02	; volume 3, down, period 2
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $04, $00, $01	; volume 4, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $06, $00, $02	; volume 6, down, period 2
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_CALL
	dw Seq_6c93
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_GOTO
	dw Seq_6cc0

Seq_6c2a:
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_E5,    $02	; E5, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_RET

Seq_6c85:
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_A4,    $01	; A4, len 1
	db $ff, SCMD_RET

Seq_6c93:
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $01	; E4, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E4,    $01	; E4, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_E4,    $02	; E4, len 2
	db $ff, SCMD_RET

Music07_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db REST,       $18	; rest, 24

Seq_6cc0:
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_GATE_FRAC, $03	; gate = 3/8 of note length
	db $ff, SCMD_VOLUME, $09	; volume 9
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP_START, $02
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS3,   $03	; G#3, len 3
	db REST,       $01	; rest, 1
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_D5,    $02	; D5, len 2
	db REST,       $02	; rest, 2
	db NOTE_GS3,   $03	; G#3, len 3
	db REST,       $01	; rest, 1
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_CS4,   $03	; C#4, len 3
	db REST,       $01	; rest, 1
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_G5,    $02	; G5, len 2
	db REST,       $02	; rest, 2
	db NOTE_A3,    $04	; A3, len 4
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_GS4,   $04	; G#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_F5,    $04	; F5, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_DS6,   $04	; D#6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_VOLUME, $02	; volume 2
	db NOTE_G5,    $10	; G5, len 16
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_VOLUME, $07	; volume 7
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_G6,    $0c	; G6, len 12
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_CS6,   $0c	; C#6, len 12
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_G6,    $0c	; G6, len 12
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_CS6,   $02	; C#6, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_B5,    $02	; B5, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db $ff, SCMD_TRANSPOSE, $fe	; -2 octave slots
	db NOTE_FS7,   $04	; F#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_FS7,   $04	; F#7, len 4
	db NOTE_G7,    $04	; G7, len 4
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_FS7,   $04	; F#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_FS7,   $02	; F#7, len 2
	db NOTE_G7,    $02	; G7, len 2
	db NOTE_A7,    $02	; A7, len 2
	db NOTE_B7,    $02	; B7, len 2
	db NOTE_D8,    $02	; D8, len 2
	db NOTE_CS8,   $04	; C#8, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db NOTE_A7,    $02	; A7, len 2
	db NOTE_FS7,   $02	; F#7, len 2
	db NOTE_A7,    $08	; A7, len 8
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_FS7,   $04	; F#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_B6,    $04	; B6, len 4
	db NOTE_FS7,   $04	; F#7, len 4
	db NOTE_G7,    $04	; G7, len 4
	db NOTE_CS7,   $04	; C#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $01	; C#7, len 1
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_CS7,   $02	; C#7, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_F7,    $02	; F7, len 2
	db NOTE_A7,    $04	; A7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_E7,    $02	; E7, len 2
	db NOTE_GS7,   $02	; G#7, len 2
	db NOTE_B7,    $02	; B7, len 2
	db NOTE_GS7,   $04	; G#7, len 4
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_G7,    $02	; G7, len 2
	db NOTE_E7,    $08	; E7, len 8
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_E7,    $01	; E7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E7,    $01	; E7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_E7,    $01	; E7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_E7,    $01	; E7, len 1
	db NOTE_G7,    $04	; G7, len 4
	db NOTE_A7,    $04	; A7, len 4
	db NOTE_B7,    $04	; B7, len 4
	db NOTE_AS7,   $04	; A#7, len 4
	db NOTE_B7,    $04	; B7, len 4
	db NOTE_CS8,   $04	; C#8, len 4
	db NOTE_CS8,   $04	; C#8, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS8,   $01	; C#8, len 1
	db NOTE_GS7,   $01	; G#7, len 1
	db NOTE_A7,    $03	; A7, len 3
	db NOTE_FS7,   $04	; F#7, len 4
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_FS7,   $01	; F#7, len 1
	db NOTE_A7,    $04	; A7, len 4
	db NOTE_G7,    $04	; G7, len 4
	db NOTE_E7,    $04	; E7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_E7,    $04	; E7, len 4
	db NOTE_G7,    $04	; G7, len 4
	db NOTE_AS7,   $02	; A#7, len 2
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_AS7,   $01	; A#7, len 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_AS7,   $01	; A#7, len 1
	db NOTE_D8,    $02	; D8, len 2
	db NOTE_C8,    $02	; C8, len 2
	db NOTE_B7,    $02	; B7, len 2
	db NOTE_A7,    $02	; A7, len 2
	db NOTE_FS7,   $02	; F#7, len 2
	db NOTE_DS7,   $02	; D#7, len 2
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_FS6,   $02	; F#6, len 2
	db NOTE_DS6,   $02	; D#6, len 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_TRANSPOSE, $03	; +3 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_VOL_ENVELOPE, $72, $4b
	db $ff, SCMD_LOOP_START, $08
	db NOTE_E3,    $01	; E3, len 1
	db REST,       $01	; rest, 1
	db NOTE_E3,    $01	; E3, len 1
	db REST,       $01	; rest, 1
	db NOTE_E4,    $01	; E4, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_ENVELOPE, $02, $01, $03	; volume 2, up, period 3
	db $ff, SCMD_LOOP_START, $08
	db NOTE_E3,    $01	; E3, len 1
	db REST,       $01	; rest, 1
	db NOTE_E3,    $01	; E3, len 1
	db REST,       $01	; rest, 1
	db NOTE_E4,    $01	; E4, len 1
	db REST,       $01	; rest, 1
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_GOTO
	dw Seq_697d

Music07_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern2
	db REST,       $18	; rest, 24

Seq_7051:
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db NOTE_E4,    $03	; E4, len 3
	db REST,       $01	; rest, 1
	db NOTE_E4,    $03	; E4, len 3
	db REST,       $01	; rest, 1
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E4,    $03	; E4, len 3
	db REST,       $01	; rest, 1
	db NOTE_E4,    $03	; E4, len 3
	db REST,       $01	; rest, 1
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_A4,    $03	; A4, len 3
	db REST,       $01	; rest, 1
	db NOTE_A4,    $03	; A4, len 3
	db REST,       $01	; rest, 1
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_VOL_ENVELOPE, $6d, $4b
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_DS5,   $02	; D#5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db NOTE_CS4,   $02	; C#4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_B3,    $02	; B3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_AS3,   $02	; A#3, len 2
	db NOTE_A3,    $02	; A3, len 2
	db NOTE_GS3,   $02	; G#3, len 2
	db NOTE_G3,    $02	; G3, len 2
	db NOTE_FS3,   $02	; F#3, len 2
	db NOTE_F3,    $02	; F3, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_E3,    $10	; E3, len 16
	db REST,       $10	; rest, 16
	db $ff, SCMD_VOL_ENVELOPE, $47, $4b
	db NOTE_D4,    $01	; D4, len 1
	db NOTE_A4,    $01	; A4, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_B5,    $02	; B5, len 2
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_D5,    $02	; D5, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_D4,    $02	; D4, len 2
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_LOOP_START, $04
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A5,    $02	; A5, len 2
	db $ff, SCMD_VOL_ENVELOPE, $6d, $4b
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db $ff, SCMD_LOOP_START, $02
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G4,    $04	; G4, len 4
	db NOTE_G3,    $04	; G3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D3,    $04	; D3, len 4
	db $ff, SCMD_LOOP_END
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_CS4,   $04	; C#4, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C4,    $04	; C4, len 4
	db NOTE_C5,    $04	; C5, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS4,   $04	; D#4, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D4,    $04	; D4, len 4
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS4,   $04	; A#4, len 4
	db NOTE_AS5,   $04	; A#5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_B5,    $04	; B5, len 4
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_VOL_ENVELOPE, $4f, $4b
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E4,    $04	; E4, len 4
	db NOTE_E3,    $04	; E3, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A4,    $04	; A4, len 4
	db NOTE_A3,    $04	; A3, len 4
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_FS6,   $01	; F#6, len 1
	db $ff, SCMD_VOL_ENVELOPE, $6d, $4b
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A5,    $02	; A5, len 2
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_DS6,   $02	; D#6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_GOTO
	dw Seq_7051

Music07_Ch4:
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C0,    $02	; C2, len 2 (clamped from C0)
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C3,    $01	; C3, len 1
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_GS1,   $01	; G#2, len 1 (clamped from G#1)
	db REST,       $01	; rest, 1
	db NOTE_EM1,   $02	; E2, len 2 (clamped from E-1)
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1

Seq_7210:
	db $ff, SCMD_LOOP_START, $06
	db $ff, SCMD_CALL
	dw Seq_72c9
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_728f
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_CALL
	dw Seq_72ab
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_72c9
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_72c9
	db $ff, SCMD_CALL
	dw Seq_72d9
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_728f
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_728f
	db $ff, SCMD_CALL
	dw Seq_72e5
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_728f
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_728f
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_CALL
	dw Seq_72ab
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_CALL
	dw Seq_72c9
	db $ff, SCMD_CALL
	dw Seq_729f
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_72c9
	db $ff, SCMD_CALL
	dw Seq_72d9
	db $ff, SCMD_GOTO
	dw Seq_7210

Seq_728f:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

Seq_729f:
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db $ff, SCMD_RET

Seq_72ab:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

Seq_72c9:
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

Seq_72d9:
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C2,    $02	; C2, len 2
	db NOTE_C2,    $02	; C2, len 2
	db $ff, SCMD_RET

Seq_72e5:
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_CM1,   $02	; C2, len 2 (clamped from C-1)
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $02	; C4, len 2
	db NOTE_C4,    $01	; C4, len 1
	db NOTE_C4,    $01	; C4, len 1
	db $ff, SCMD_RET

MusicHeader_08:
	dw Music08_Ch1	; channel 1
	dw Music08_Ch2	; channel 2
	dw Music08_Ch3	; channel 3
	dw 0	; channel 4

Music08_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_PANNING, $02	; right
	db REST,       $01	; rest, 1
	db $ff, SCMD_VOLUME, $01	; volume 1
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_B5,    $0c	; B5, len 12
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_B5,    $06	; B5, len 6
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_B5,    $06	; B5, len 6
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db NOTE_B5,    $0c	; B5, len 12
	db $ff, SCMD_VOLUME, $03	; volume 3
	db $ff, SCMD_PITCH_ENVELOPE, $35, $4c
	db NOTE_B5,    $07	; B5, len 7
	db NOTE_B5,    $04	; B5, len 4
	db $ff, SCMD_VOLUME, $02	; volume 2
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_VOLUME, $01	; volume 1
	db NOTE_B5,    $08	; B5, len 8
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_VOL_ENVELOPE, $8e, $4b

Seq_7360:
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_736f
	db $ff, SCMD_CALL
	dw Seq_7496
	db $ff, SCMD_GOTO
	dw Seq_7360

Seq_736f:
	db $ff, SCMD_LOOP_START, $02
	db NOTE_FS4,   $08	; F#4, len 8
	db NOTE_DS5,   $08	; D#5, len 8
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_GS5,   $04	; G#5, len 4
	db NOTE_FS5,   $10	; F#5, len 16
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_DS5,   $08	; D#5, len 8
	db NOTE_FS4,   $08	; F#4, len 8
	db NOTE_DS5,   $04	; D#5, len 4
	db NOTE_E5,    $04	; E5, len 4
	db NOTE_CS5,   $04	; C#5, len 4
	db NOTE_B4,    $04	; B4, len 4
	db NOTE_A4,    $20	; A4, len 32
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_G5,    $04	; G5, len 4
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_A4,    $08	; A4, len 8
	db NOTE_D5,    $04	; D5, len 4
	db NOTE_FS5,   $04	; F#5, len 4
	db NOTE_A5,    $04	; A5, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $10	; C6, len 16
	db NOTE_D6,    $04	; D6, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $04	; B5, len 4
	db NOTE_C6,    $04	; C6, len 4
	db NOTE_B5,    $20	; B5, len 32
	db NOTE_B5,    $20	; B5, len 32
	db NOTE_B5,    $20	; B5, len 32
	db NOTE_B5,    $20	; B5, len 32
	db $ff, SCMD_LOOP_END
	db NOTE_CS5,   $10	; C#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_DS5,   $10	; D#5, len 16
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_B5,    $10	; B5, len 16
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_CS5,   $10	; C#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_DS5,   $20	; D#5, len 32
	db NOTE_DS5,   $20	; D#5, len 32
	db NOTE_CS5,   $10	; C#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_DS5,   $10	; D#5, len 16
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_B5,    $10	; B5, len 16
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_CS5,   $10	; C#5, len 16
	db NOTE_A5,    $10	; A5, len 16
	db NOTE_GS5,   $08	; G#5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_E5,    $08	; E5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_D5,    $10	; D5, len 16
	db NOTE_B5,    $10	; B5, len 16
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_FS5,   $08	; F#5, len 8
	db NOTE_G5,    $08	; G5, len 8
	db NOTE_A5,    $20	; A5, len 32
	db NOTE_A5,    $08	; A5, len 8
	db NOTE_B5,    $08	; B5, len 8
	db NOTE_CS6,   $08	; C#6, len 8
	db NOTE_D6,    $08	; D6, len 8
	db NOTE_D5,    $20	; D5, len 32
	db NOTE_D5,    $08	; D5, len 8
	db NOTE_CS5,   $08	; C#5, len 8
	db NOTE_B4,    $08	; B4, len 8
	db NOTE_CS5,   $08	; C#5, len 8
	db NOTE_D5,    $20	; D5, len 32
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_E4,    $02	; E4, len 2
	db NOTE_FS4,   $02	; F#4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_A4,    $02	; A4, len 2
	db NOTE_B4,    $02	; B4, len 2
	db NOTE_CS5,   $02	; C#5, len 2
	db $ff, SCMD_RET

Music08_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db REST,       $06	; rest, 6
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $04	; note length x4
	db REST,       $20	; rest, 32
	db REST,       $20	; rest, 32
	db REST,       $01	; rest, 1
	db REST,       $0c	; rest, 12
	db REST,       $06	; rest, 6
	db REST,       $06	; rest, 6
	db REST,       $0c	; rest, 12
	db REST,       $07	; rest, 7
	db REST,       $04	; rest, 4
	db REST,       $08	; rest, 8
	db REST,       $08	; rest, 8
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_VOLUME, $01	; volume 1
	db $ff, SCMD_PITCH_ENVELOPE, $29, $4c

Seq_7487:
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_CALL
	dw Seq_736f
	db $ff, SCMD_CALL
	dw Seq_7496
	db $ff, SCMD_GOTO
	dw Seq_7487

Seq_7496:
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D5,    $01	; D5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS5,   $01	; D#5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F5,    $01	; F5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_AS5,   $01	; A#5, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_C6,    $01	; C6, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_CS6,   $01	; C#6, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_D6,    $01	; D6, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS6,   $01	; D#6, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_E6,    $01	; E6, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_F6,    $01	; F6, len 1
	db $ff, SCMD_RET

Music08_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $04	; note length x4
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_VOLUME, $04	; volume 4
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_LOOP_START, $10
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_LOOP_END

Seq_7508:
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_7682
	db $ff, SCMD_CALL
	dw Seq_7682
	db $ff, SCMD_CALL
	dw Seq_7682
	db $ff, SCMD_CALL
	dw Seq_7682
	db $ff, SCMD_CALL
	dw Seq_7694
	db $ff, SCMD_CALL
	dw Seq_7694
	db $ff, SCMD_CALL
	dw Seq_7694
	db $ff, SCMD_CALL
	dw Seq_7694
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $02
	db $ff, SCMD_CALL
	dw Seq_75ec
	db $ff, SCMD_CALL
	dw Seq_762e
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $03
	db $ff, SCMD_LOOP_START, $08
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $08
	db $ff, SCMD_CALL
	dw Seq_75da
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $08
	db $ff, SCMD_CALL
	dw Seq_7670
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_LOOP_START, $08
	db $ff, SCMD_CALL
	dw Seq_76a6
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_CALL
	dw Seq_76b8
	db $ff, SCMD_CALL
	dw Seq_76b8
	db $ff, SCMD_CALL
	dw Seq_76b8
	db $ff, SCMD_CALL
	dw Seq_76b8
	db $ff, SCMD_CALL
	dw Seq_76ca
	db $ff, SCMD_CALL
	dw Seq_76ca
	db $ff, SCMD_CALL
	dw Seq_76ca
	db $ff, SCMD_CALL
	dw Seq_76ca
	db $ff, SCMD_CALL
	dw Seq_76dc
	db $ff, SCMD_CALL
	dw Seq_76dc
	db $ff, SCMD_CALL
	dw Seq_76dc
	db $ff, SCMD_CALL
	dw Seq_76dc
	db $ff, SCMD_CALL
	dw Seq_76ee
	db $ff, SCMD_CALL
	dw Seq_76ee
	db $ff, SCMD_CALL
	dw Seq_76ee
	db $ff, SCMD_CALL
	dw Seq_76ee
	db $ff, SCMD_LOOP_START, $08
	db $ff, SCMD_CALL
	dw Seq_7700
	db $ff, SCMD_LOOP_END
	db $ff, SCMD_GOTO
	dw Seq_7508

Seq_75da:
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_RET

Seq_75ec:
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_GS5,   $01	; G#5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_RET

Seq_762e:
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_CS5,   $01	; C#5, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_GS4,   $01	; G#4, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_B4,    $01	; B4, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_GS4,   $01	; G#4, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_DS4,   $01	; D#4, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_FS4,   $01	; F#4, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_CS4,   $01	; C#4, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_DS4,   $01	; D#4, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_B3,    $01	; B3, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_CS4,   $01	; C#4, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_GS3,   $01	; G#3, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_B3,    $01	; B3, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_FS3,   $01	; F#3, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_GS3,   $01	; G#3, len 1
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_RET

Seq_7670:
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db $ff, SCMD_RET

Seq_7682:
	db NOTE_D7,    $01	; D7, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db $ff, SCMD_RET

Seq_7694:
	db NOTE_C7,    $01	; C7, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_C6,    $01	; C6, len 1
	db $ff, SCMD_RET

Seq_76a6:
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_RET

Seq_76b8:
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db $ff, SCMD_RET

Seq_76ca:
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_C6,    $01	; C6, len 1
	db NOTE_FS5,   $01	; F#5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_DS5,   $01	; D#5, len 1
	db $ff, SCMD_RET

Seq_76dc:
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_B5,    $01	; B5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_A5,    $01	; A5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db $ff, SCMD_RET

Seq_76ee:
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_CS6,   $01	; C#6, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_AS5,   $01	; A#5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db NOTE_CS5,   $01	; C#5, len 1
	db $ff, SCMD_RET

Seq_7700:
	db NOTE_B6,    $01	; B6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_B5,    $01	; B5, len 1
	db $ff, SCMD_RET
	db $ff, $08, $04, $ff, $05, $01, $ff, $0e

SfxHeader_00:
	dw Sfx00_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx00_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_A7,    $01	; A7, len 1
	db NOTE_AS7,   $02	; A#7, len 2
	db $ff, SCMD_STOP

SfxHeader_01:
	dw Sfx01_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx01_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_C6,    $02	; C6, len 2
	db NOTE_D6,    $02	; D6, len 2
	db NOTE_E6,    $02	; E6, len 2
	db $ff, SCMD_ENVELOPE, $08, $00, $01	; volume 8, down, period 1
	db NOTE_FS6,   $02	; F#6, len 2
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db NOTE_AS6,   $02	; A#6, len 2
	db $ff, SCMD_ENVELOPE, $04, $00, $01	; volume 4, down, period 1
	db NOTE_B6,    $02	; B6, len 2
	db $ff, SCMD_ENVELOPE, $03, $00, $01	; volume 3, down, period 1
	db NOTE_C7,    $02	; C7, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $02	; volume 2, down, period 2
	db NOTE_C7,    $02	; C7, len 2
	db $ff, SCMD_ENVELOPE, $01, $00, $03	; volume 1, down, period 3
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_C7,    $04	; C7, len 4
	db NOTE_C7,    $04	; C7, len 4
	db $ff, SCMD_STOP

SfxHeader_02:
	dw Sfx02_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx02_Ch4	; channel 4
	db $00

Sfx02_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx02_Ch4:
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_FS2,   $01	; F#2, len 1
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_DS8,   $01	; D#8, len 1
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
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_AM1,   $02	; A2, len 2 (clamped from A-1)
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_E12,   $01	; E8, len 1 (clamped from E12)
	db $ff, SCMD_STOP

SfxHeader_04:
	dw Sfx04_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx04_Ch4	; channel 4
	db $00

Sfx04_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_B5,    $03	; B5, len 3
	db NOTE_B4,    $03	; B4, len 3
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_B4,    $02	; B4, len 2
	db $ff, SCMD_STOP

Sfx04_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0b, $00, $01	; volume 11, down, period 1
	db NOTE_C9,    $02	; C8, len 2 (clamped from C9)
	db NOTE_DS3,   $03	; D#3, len 3
	db $ff, SCMD_STOP

SfxHeader_05:
	dw Sfx05_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx05_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_DETUNE, $05	; +5/8 semitone
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_CALL
	dw Seq_7856
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_CALL
	dw Seq_7856
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_CALL
	dw Seq_7856
	db $ff, SCMD_STOP

Seq_7856:
	db NOTE_D6,    $01	; D6, len 1
	db NOTE_DS6,   $01	; D#6, len 1
	db NOTE_E6,    $01	; E6, len 1
	db NOTE_F6,    $01	; F6, len 1
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $01	; G6, len 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_A6,    $01	; A6, len 1
	db NOTE_AS6,   $06	; A#6, len 6
	db $ff, SCMD_RET

SfxHeader_06:
	dw Sfx06_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx06_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0d, $00, $01	; volume 13, down, period 1
	db NOTE_E6,    $01	; E6, len 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_F6,    $02	; F6, len 2
	db NOTE_FS6,   $01	; F#6, len 1
	db NOTE_G6,    $02	; G6, len 2
	db NOTE_A6,    $02	; A6, len 2
	db NOTE_B6,    $02	; B6, len 2
	db NOTE_C7,    $02	; C7, len 2
	db NOTE_CS7,   $08	; C#7, len 8
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_ENVELOPE, $05, $00, $01	; volume 5, down, period 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db $ff, SCMD_ENVELOPE, $03, $00, $01	; volume 3, down, period 1
	db NOTE_CS7,   $02	; C#7, len 2
	db $ff, SCMD_STOP

SfxHeader_07:
	dw Sfx07_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx07_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TIMBRE, $04, $00	; NR11 = $01
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_DETUNE, $05	; +5/8 semitone
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db $ff, SCMD_PITCH_ENVELOPE, $1d, $4c
	db NOTE_FS5,   $02	; F#5, len 2
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db NOTE_FS4,   $01	; F#4, len 1
	db $ff, SCMD_STOP

SfxHeader_08:
	dw Sfx08_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx08_Ch4	; channel 4
	db $00

Sfx08_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx08_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_C3,    $01	; C3, len 1
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db NOTE_E1,    $01	; E2, len 1 (clamped from E1)
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_FS11,  $01	; F8, len 1 (clamped from F#11)
	db NOTE_FS3,   $03	; F#3, len 3
	db $ff, SCMD_STOP

SfxHeader_09:
	dw Sfx09_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx09_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_DETUNE, $04	; +4/8 semitone
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $09, $00, $01	; volume 9, down, period 1
	db NOTE_GS6,   $01	; G#6, len 1
	db NOTE_G7,    $01	; G7, len 1
	db $ff, SCMD_STOP

SfxHeader_10:
	dw Sfx10_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx10_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_DETUNE, $01	; +1/8 semitone
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_GATE_FRAC, $01	; gate = 1/8 of note length
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_GATE_ABS, $01	; gate = 1 x tempo
	db $ff, SCMD_TRANSPOSE, $ff	; -1 octave slots
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C8,    $02	; C8, len 2
	db NOTE_B7,    $02	; B7, len 2
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_GS5,   $02	; G#5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_ENVELOPE, $07, $00, $01	; volume 7, down, period 1
	db $ff, SCMD_DETUNE, $00	; +0/8 semitone
	db NOTE_C8,    $02	; C8, len 2
	db NOTE_B7,    $02	; B7, len 2
	db $ff, SCMD_ENVELOPE, $02, $00, $01	; volume 2, down, period 1
	db NOTE_AS6,   $02	; A#6, len 2
	db NOTE_GS5,   $01	; G#5, len 1
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_STOP

SfxHeader_11:
	dw Sfx11_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx11_Ch4	; channel 4
	db $00

Sfx11_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx11_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_A1,    $04	; A2, len 4 (clamped from A1)
	db NOTE_DS8,   $07	; D#8, len 7
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS11,  $01	; G#8, len 1 (clamped from G#11)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_A1,    $01	; A2, len 1 (clamped from A1)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS9,   $01	; G#8, len 1 (clamped from G#9)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_G12,   $01	; G8, len 1 (clamped from G12)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS7,   $01	; G#7, len 1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_A1,    $04	; A2, len 4 (clamped from A1)
	db NOTE_DS8,   $07	; D#8, len 7
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS11,  $01	; G#8, len 1 (clamped from G#11)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS10,  $01	; G#8, len 1 (clamped from G#10)
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS9,   $01	; G#8, len 1 (clamped from G#9)
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_GS6,   $01	; G#6, len 1
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_GS7,   $01	; G#7, len 1
	db $ff, SCMD_STOP

SfxHeader_12:
	dw Sfx12_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx12_Ch4	; channel 4
	db $00

Sfx12_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db NOTE_G6,    $01	; G6, len 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_GS6,   $02	; G#6, len 2
	db $ff, SCMD_STOP

Sfx12_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db NOTE_E10,   $04	; E8, len 4 (clamped from E10)
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $06, $00, $01	; volume 6, down, period 1
	db NOTE_E10,   $02	; E8, len 2 (clamped from E10)
	db $ff, SCMD_STOP

SfxHeader_13:
	dw Sfx13_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx13_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_DETUNE, $07	; +7/8 semitone
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_ENVELOPE, $0f, $00, $02	; volume 15, down, period 2
	db $ff, SCMD_PANNING, $01	; left
	db NOTE_A6,    $03	; A6, len 3
	db NOTE_G6,    $03	; G6, len 3
	db NOTE_F6,    $03	; F6, len 3
	db NOTE_D6,    $03	; D6, len 3
	db NOTE_C6,    $03	; C6, len 3
	db $ff, SCMD_ENVELOPE, $07, $00, $02	; volume 7, down, period 2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_CALL
	dw Seq_7a8a
	db $ff, SCMD_ENVELOPE, $0a, $00, $02	; volume 10, down, period 2
	db $ff, SCMD_PANNING, $03	; both
	db $ff, SCMD_CALL
	dw Seq_7a8a
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $0c, $00, $02	; volume 12, down, period 2
	db $ff, SCMD_CALL
	dw Seq_7a8a
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $03, $00, $0a	; volume 3, down, period 10
	db NOTE_A6,    $03	; A6, len 3
	db NOTE_G6,    $03	; G6, len 3
	db NOTE_F6,    $03	; F6, len 3
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_ENVELOPE, $02, $00, $05	; volume 2, down, period 5
	db NOTE_D6,    $03	; D6, len 3
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_STOP

Seq_7a8a:
	db NOTE_A6,    $03	; A6, len 3
	db NOTE_G6,    $03	; G6, len 3
	db NOTE_F6,    $03	; F6, len 3
	db NOTE_D6,    $03	; D6, len 3
	db NOTE_C6,    $03	; C6, len 3
	db $ff, SCMD_RET

SfxHeader_14:
	dw Sfx14_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx14_Ch4	; channel 4
	db $00

Sfx14_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx14_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_ENVELOPE, $0a, $01, $02	; volume 10, up, period 2
	db NOTE_CSM1,  $01	; C#2, len 1 (clamped from C#-1)
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C3,    $02	; C3, len 2
	db NOTE_C3,    $08	; C3, len 8
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $05	; volume 15, down, period 5
	db NOTE_C3,    $01	; C3, len 1
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C4,    $01	; C4, len 1
	db $ff, SCMD_ENVELOPE, $0a, $00, $07	; volume 10, down, period 7
	db NOTE_C5,    $06	; C5, len 6
	db REST,       $01	; rest, 1
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db REST,       $01	; rest, 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C0,    $01	; C2, len 1 (clamped from C0)
	db NOTE_C1,    $01	; C2, len 1 (clamped from C1)
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_VOLUME, $05	; volume 5
	db NOTE_C1,    $04	; C2, len 4 (clamped from C1)
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_VOLUME, $09	; volume 9
	db NOTE_C0,    $04	; C2, len 4 (clamped from C0)
	db $ff, SCMD_STOP

SfxHeader_15:
	dw Sfx15_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw Sfx15_Ch4	; channel 4
	db $00

Sfx15_Ch1:
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx15_Ch4:
	db $ff, SCMD_TEMPO, $03	; note length x3
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_CS6,   $04	; C#6, len 4
	db NOTE_D7,    $02	; D7, len 2
	db NOTE_DS8,   $02	; D#8, len 2
	db NOTE_E9,    $04	; E8, len 4 (clamped from E9)
	db NOTE_F10,   $01	; F8, len 1 (clamped from F10)
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_FS11,  $01	; F8, len 1 (clamped from F#11)
	db $ff, SCMD_VOLUME, $0a	; volume 10
	db NOTE_G12,   $01	; G8, len 1 (clamped from G12)
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db NOTE_GS8,   $01	; G#8, len 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db NOTE_GS11,  $01	; G#8, len 1 (clamped from G#11)
	db $ff, SCMD_STOP

SfxHeader_16:
	dw Sfx16_Ch1	; channel 1
	dw Sfx16_Ch2	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx16_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $03, $00	; duty 3
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_PANNING, $01	; left
	db $ff, SCMD_ENVELOPE, $0f, $00, $01	; volume 15, down, period 1
	db $ff, SCMD_GATE_FRAC, $07	; gate = 7/8 of note length
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_VOLUME, $07	; volume 7
	db NOTE_C6,    $02	; C6, len 2
	db $ff, SCMD_VOLUME, $0c	; volume 12
	db NOTE_G5,    $02	; G5, len 2
	db NOTE_E6,    $08	; E6, len 8
	db $ff, SCMD_ENVELOPE, $07, $00, $05	; volume 7, down, period 5
	db NOTE_E6,    $03	; E6, len 3
	db $ff, SCMD_STOP

Sfx16_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $01, $00	; duty 1
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_PANNING, $02	; right
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_GATE_FRAC, $06	; gate = 6/8 of note length
	db $ff, SCMD_DETUNE, $03	; +3/8 semitone
	db NOTE_G4,    $02	; G4, len 2
	db NOTE_C5,    $02	; C5, len 2
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_VOLUME, $06	; volume 6
	db NOTE_G5,    $02	; G5, len 2
	db $ff, SCMD_VOLUME, $0b	; volume 11
	db NOTE_E5,    $02	; E5, len 2
	db NOTE_C6,    $08	; C6, len 8
	db $ff, SCMD_ENVELOPE, $05, $00, $03	; volume 5, down, period 3
	db NOTE_C6,    $03	; C6, len 3
	db $ff, SCMD_STOP

SfxHeader_17:
	dw Sfx17_Ch1	; channel 1
	dw 0	; channel 2
	dw 0	; channel 3
	dw 0	; channel 4
	db $00

Sfx17_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_TRANSPOSE, $00	; +0 octave slots
	db $ff, SCMD_GATE_FRAC, $08	; gate = 8/8 of note length
	db $ff, SCMD_ENVELOPE, $0a, $00, $01	; volume 10, down, period 1
	db $ff, SCMD_CALL
	dw Seq_7bdf
	db $ff, SCMD_TRANSPOSE, $01	; +1 octave slots
	db $ff, SCMD_ENVELOPE, $0c, $00, $01	; volume 12, down, period 1
	db $ff, SCMD_CALL
	dw Seq_7bdf
	db $ff, SCMD_STOP

Seq_7bdf:
	db NOTE_C5,    $01	; C5, len 1
	db NOTE_E5,    $01	; E5, len 1
	db NOTE_G5,    $01	; G5, len 1
	db $ff, SCMD_RET

SfxHeader_18:
	dw Sfx18_Ch1	; channel 1
	dw Sfx18_Ch2	; channel 2
	dw Sfx18_Ch3	; channel 3
	dw Sfx18_Ch4	; channel 4
	db $00

Sfx18_Ch1:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_STOP

Sfx18_Ch2:
	db $ff, SCMD_TIMBRE, $02, $00	; duty 2
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_SWEEP_OFF
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db REST,       $04	; rest, 4
	db $ff, SCMD_TEMPO, $02	; note length x2
	db NOTE_C2,    $01	; C2, len 1
	db NOTE_C2,    $01	; C2, len 1
	db $ff, SCMD_PANNING, $03	; both
	db NOTE_DS2,   $01	; D#2, len 1
	db NOTE_DS2,   $01	; D#2, len 1
	db $ff, SCMD_PANNING, $02	; right
	db NOTE_CS2,   $02	; C#2, len 2
	db NOTE_CS2,   $01	; C#2, len 1
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_STOP

Sfx18_Ch3:
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern0
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_TIMBRE	; wave pattern
	dw WavePattern1
	db $ff, SCMD_VOLUME, $03	; volume 3
	db REST,       $04	; rest, 4
	db NOTE_D2,    $02	; D2, len 2
	db NOTE_CS2,   $02	; C#2, len 2
	db $ff, SCMD_STOP

Sfx18_Ch4:
	db $ff, SCMD_TEMPO, $01	; note length x1
	db $ff, SCMD_VOLUME, $0f	; volume 15
	db REST,       $01	; rest, 1
	db NOTE_GS2,   $06	; G#2, len 6
	db $ff, SCMD_TEMPO, $02	; note length x2
	db $ff, SCMD_ENVELOPE, $0f, $00, $03	; volume 15, down, period 3
	db $ff, SCMD_DETUNE, $02	; +2/8 semitone
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db NOTE_GS2,   $04	; G#2, len 4
	db NOTE_EM1,   $01	; E2, len 1 (clamped from E-1)
	db $ff, SCMD_STOP
	db $00, $34, $41, $19, $00, $34, $49, $14, $00, $34, $51, $0e, $00, $34, $59, $02
	db $00, $11, $06, $37, $22, $05, $13, $02, $17, $39, $09, $29, $31, $11, $00, $29
	db $39, $06, $00, $29, $41, $37, $00, $29, $49, $22, $00, $34, $34, $05, $00, $34
	db $3c, $13, $00, $34, $44, $02, $00, $34, $4c, $17, $00, $34, $54, $39, $00, $09
	db $29, $31, $05, $00, $29, $39, $33, $00, $29, $41, $12, $00, $34, $31, $14, $00
	db $34, $39, $1f, $00, $34, $41, $15, $00, $34, $49, $18, $00, $34, $51, $2a, $00
	db $34, $59, $02, $00, $0a, $29, $31, $1d, $00, $29, $39, $2d, $00, $29, $41, $06
	db $00, $29, $49, $2c, $00, $34, $31, $0f, $00, $34, $39, $37, $00, $34, $3f, $0b
	db $00, $34, $47, $10, $00, $34, $4f, $34, $00, $34, $57, $03, $00, $0b, $29, $31
	db $14, $00, $29, $39, $05, $00, $29, $3f, $37, $00, $29, $47, $29, $00, $29, $4f
	db $19, $00, $34, $31, $09, $00, $34, $39, $33, $00, $34, $40, $10, $00, $34, $48
	db $15, $00, $34, $50, $00, $00, $34, $58, $28, $00, $0b, $29, $31, $00, $00, $29
	db $39, $0e, $00, $29, $41, $1a, $00, $29, $49, $37, $00, $29, $50, $19, $00, $34
	db $31, $09, $00, $34, $39, $09, $00, $34, $41, $1e, $00, $34, $49, $12, $00, $34
	db $51, $37, $00, $34, $59, $39, $00, $0b, $29, $31, $09, $00, $29, $39, $29, $00
	db $29, $41, $05, $00, $29, $49, $26, $00, $29, $51, $19, $00, $34, $31, $05, $00
	db $34, $39, $10, $00, $34, $41, $1e, $00, $34, $49, $07, $00, $34, $51, $27, $00
	db $34, $59, $39, $00, $0a, $29, $31, $14, $00, $29, $39, $0a, $00, $29, $41, $08
	db $00, $29, $49, $19, $00, $34, $31, $20, $00, $34, $39, $25, $00, $34, $41, $02
	db $00, $34, $49, $0f, $00, $34, $51, $37, $00, $34, $59, $25, $00, $0c, $29, $31
	db $1e, $00, $29, $39, $0f, $00, $29, $41, $37, $00, $29, $48, $1e, $00, $29, $50
	db $0f, $00, $29, $58, $37, $00, $34, $31, $26, $00, $34, $39, $07, $00, $34, $41
	db $0b, $00, $34, $49, $36, $00, $34, $51, $02, $00, $34, $59, $39, $00, $0b, $29
	db $31, $09, $00, $29, $39, $2d, $00, $29, $41, $13, $00, $29, $49, $37, $00, $29
	db $50, $19, $00, $34, $31, $05, $00, $34, $39, $10, $00, $34, $41, $15, $00, $34
	db $49, $01, $00, $34, $51, $09, $00, $34, $59, $02, $00, $0a, $29, $31, $24, $00
	db $29, $39, $0f, $00, $29, $41, $37, $00, $29, $49, $2d, $00, $34, $31, $0b, $00
	db $34, $39, $10, $00, $34, $40, $34, $00, $34, $47, $33, $00, $34, $4f, $0f, $00
	db $34, $57, $17, $00, $09, $29, $31, $04, $00, $29, $39, $10, $00, $29, $41, $11
	db $00, $29, $49, $01, $00, $29, $51, $12, $00, $34, $40, $01, $00, $34, $48, $09
	db $00, $34, $50, $02, $00, $34, $58, $39, $00, $0a, $29, $31, $25, $00, $29, $39
	db $07, $00, $29, $41, $1f, $00, $29, $49, $12, $00, $34, $31, $0f, $00, $34, $39
	db $0f, $00, $34, $41, $05, $00, $34, $49, $04, $00, $34, $51, $02, $00, $34, $59
	db $39, $00, $0a, $29, $31, $01, $00, $29, $39, $1e, $00, $29, $41, $18, $00, $29
	db $49, $19, $00, $34, $31, $04, $00, $34, $39, $0b, $00, $34, $41, $05, $00, $34
	db $49, $33, $00, $34, $50, $0f, $00, $34, $58, $17, $00, $0a, $29, $31, $11, $00
	db $29, $39, $06, $00, $29, $40, $37, $00, $29, $48, $19, $00, $34, $31, $05, $00
	db $34, $39, $37, $00, $34, $40, $2d, $00, $34, $48, $19, $00, $34, $50, $37, $00
	db $34, $57, $29, $00, $0a, $29, $31, $09, $00, $29, $39, $2d, $00, $29, $41, $13
	db $00, $29, $49, $37, $00, $29, $50, $19, $00, $34, $31, $05, $00, $34, $39, $13
	db $00, $34, $41, $02, $00, $34, $49, $17, $00, $34, $51, $39, $00, $08, $29, $31
	db $22, $00, $29, $39, $02, $00, $34, $31, $1e, $00, $34, $39, $08, $00, $34, $41
	db $26, $00, $34, $49, $29, $00, $34, $51, $14, $00, $34, $59, $01, $00, $07, $29
	db $31, $01, $00, $29, $39, $33, $00, $29, $43, $06, $00, $29, $4b, $15, $00, $34
	db $38, $01, $00, $34, $41, $09, $00, $34, $4a, $02, $00, $00, $00, $00, $77, $40
	db $40, $40, $77, $90, $90, $90, $77, $e4, $e4, $e4, $77, $00, $08, $40, $80, $00
	db $08, $40, $00, $14, $08, $00, $44, $01, $02, $00, $06, $00, $50, $00, $01, $40
	db $80, $01, $c8, $00, $02, $00, $80, $41, $00, $04, $00, $10, $02, $00, $54, $04
	db $01, $40, $02, $01, $40, $00, $80, $00, $30, $01, $84, $10, $48, $40, $04, $01
	db $00, $40, $24, $00, $00, $44, $00, $04, $00, $00, $10, $00, $08, $00, $00, $01
	db $20, $04, $00, $01, $08, $40, $04, $50, $80, $01, $a1, $00, $04, $00, $00, $01
	db $00, $00, $49, $45, $01, $00, $10, $00, $02, $00, $25, $00, $10, $14, $00, $01
	db $00, $40, $00, $45, $00, $04, $00, $00, $14, $40, $05, $00, $94, $01, $68, $00
	db $00, $00, $20, $00, $02, $04, $00, $00, $00, $10, $00, $00, $22, $00, $00, $00
	db $00, $00, $20, $00, $08, $00, $80, $00, $82, $04, $00, $01, $20, $04, $46, $00
	db $40, $00, $04, $00, $89, $00, $80, $00, $88, $40, $20, $04, $03, $40, $0c, $45
	db $01, $00, $40, $00, $40, $00, $69, $10, $21, $45, $25, $04, $11, $00, $00, $01
	db $0b, $11, $a4, $40, $52, $40, $36, $04, $38, $01, $58, $44, $50, $44, $23, $01
	db $84, $04, $42, $11, $81, $07
