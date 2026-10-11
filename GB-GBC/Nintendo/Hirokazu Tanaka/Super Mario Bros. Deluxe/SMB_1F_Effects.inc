; Super Mario Bros. Deluxe SFX: effects, bank $1F $485A-$67F0

Sfx2_32_Init:
	ld hl, Sfx2_32_Data_48B0
	jp Sfx2_Start

Sfx2_32_Play:
	call Sfx_DecTimer
	jp z, Sfx2_StopWithRegs
	cpl
	add a, $27
	ld d, $00
	srl a
	ret c
	cp $07
	jr nz, .l0
	ld a, $73
	ldh [rNR22], a
	ld a, $07
	ld d, $80
.l0:
	ld hl, Sfx2_32_Data_488C
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	or d
	ldh [rNR24], a
	ld a, $80
	ldh [rNR21], a
	ret

Sfx2_32_Data_488C:
	db $42, $06, $06, $07, $9e, $06, $39, $07, $d6, $06, $59, $07, $b2, $06, $f7, $06
	db $59, $07, $b2, $06, $f7, $06, $59, $07, $b2, $06, $f7, $06, $59, $07, $b2, $06
	db $f7, $06, $59, $07
Sfx2_32_Data_48B0:
	db $80, $98, $39, $87, $26
Sfx2_33_Init:
	ld hl, Sfx2_33_Data_4903
	jp Sfx2_Start

Sfx2_33_Play:
	call Sfx_DecTimer
	jp z, Sfx2_Stop
	cpl
	add a, $1f
	ld d, $00
	srl a
	ret c
	cp $09
	jr nz, .l0
	ld a, $e1
	ldh [rNR22], a
	ld a, $09
	ld d, $80
.l0:
	ld hl, Sfx2_33_Data_48E7
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	or d
	ldh [rNR24], a
	ld a, $80
	ldh [rNR21], a
	ret

Sfx2_33_Data_48E7:
	db $42, $06, $0a, $06, $ed, $05, $ac, $05, $63, $05, $89, $05, $ac, $05, $ce, $05
	db $ac, $05, $89, $05, $63, $05, $89, $05, $ac, $05, $ce, $05
Sfx2_33_Data_4903:
	db $80, $a9, $72, $86, $1e
Sfx1_5F_Init:
	ld hl, Sfx1_5F_Data_492D
	jp Sfx1_Start

Sfx1_5F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_5F_Data_4923
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5F_Data_4923:
	dw Sfx1_5F_Data_4933, Sfx1_5F_Data_492D, Sfx1_5F_Data_4933, Sfx1_5F_Data_492D, Sfx1_5F_Data_4933
Sfx1_5F_Data_492D:
	db $17, $b8, $81, $39, $c7, $04
Sfx1_5F_Data_4933:
	db $17, $b8, $81, $06, $c7, $04
Sfx1_Dummy_Init:
	ld hl, Sfx1_Dummy_Data_4951
	jp Sfx1_Start

Sfx1_Dummy_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_Dummy_Data_4957
	jp SetRegs_Ch1

Sfx1_Dummy_Data_4951:
	db $37, $80, $e1, $d6, $86, $03
Sfx1_Dummy_Data_4957:
	db $67, $40, $e2, $e7, $86, $23
Sfx1_43_Init:
	ld hl, Sfx1_43_Data_498B
	jp Sfx1_Start

Sfx1_43_Play:
	call Sfx_DecTimer
	jp z, Sfx1_StopSilent
	cpl
	add a, $0b
	ld hl, Sfx1_43_Data_4979
	call GetPointer
	ld a, l
	ldh [rNR13], a
	ld a, h
	ldh [rNR14], a
	ret

Sfx1_43_Data_4979:
	db $11, $05, $b5, $04, $4e, $04, $da, $03, $56, $03, $9b, $03, $da, $03, $16, $04
	db $4e, $04
Sfx1_43_Data_498B:
	db $08, $80, $d8, $63, $85, $0a
Sfx1_44_Init:
	ld hl, Sfx1_44_Data_49B0
	jp Sfx1_Start

Sfx1_44_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_44_Data_49AC
	call GetPointer
	jp SetRegs_Ch1

Sfx1_44_Data_49AC:
	dw Sfx1_44_Data_49B6, Sfx1_44_Data_49BC
Sfx1_44_Data_49B0:
	db $27, $a8, $49, $d6, $c6, $05
Sfx1_44_Data_49B6:
	db $27, $a8, $11, $d6, $c6, $02
Sfx1_44_Data_49BC:
	db $27, $a8, $49, $21, $c7, $06
Sfx1_45_Init:
	ld hl, Sfx1_45_Data_49DA
	jp Sfx1_Start

Sfx1_45_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_45_Data_49E0
	jp SetRegs_Ch1

Sfx1_45_Data_49DA:
	db $44, $bb, $e8, $e7, $c6, $06
Sfx1_45_Data_49E0:
	db $44, $bb, $e8, $44, $c7, $04
Sfx1_46_Init:
	call Sound_Stop
	ld hl, Sfx1_46_Data_49F6
	jp Sfx1_Start

Sfx1_46_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_StopWithRegs

Sfx1_46_Data_49F6:
	db $37, $80, $98, $89, $85, $3d
Sfx1_47_Init:
	ld hl, Sfx1_47_Data_4A09
	jp Sfx1_Start

Sfx1_47_Play:
	call Sfx_DecTimer
	ret nz
	jp z, Sfx1_Stop
Sfx1_47_Data_4A09:
	db $08, $80, $91, $7b, $87, $10
Sfx1_48_Init:
	ld hl, Sfx1_48_Data_4A30
	jp Sfx1_Start

Sfx1_48_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_48_Data_4A2A
	call GetPointer
	jp SetRegs_Ch1

Sfx1_48_Data_4A2A:
	dw Sfx1_48_Data_4A36, Sfx1_48_Data_4A3C, Sfx1_48_Data_4A42
Sfx1_48_Data_4A30:
	db $08, $ba, $d8, $63, $c5, $01
Sfx1_48_Data_4A36:
	db $08, $ba, $d8, $b2, $c6, $01
Sfx1_48_Data_4A3C:
	db $08, $ba, $d8, $59, $c7, $01
Sfx1_48_Data_4A42:
	db $08, $ba, $d8, $ac, $c7, $01
Sfx1_49_Init:
	call Sound_Stop
	ld hl, Sfx1_49_Data_4A6C
	jp Sfx1_Start

Sfx1_49_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_49_Data_4A66
	call GetPointer
	jp SetRegs_Ch1

Sfx1_49_Data_4A66:
	dw Sfx1_49_Data_4A72, Sfx1_49_Data_4A78, Sfx1_49_Data_4A7E
Sfx1_49_Data_4A6C:
	db $1f, $b0, $f1, $d6, $c6, $03
Sfx1_49_Data_4A72:
	db $1f, $b0, $f1, $e7, $c6, $03
Sfx1_49_Data_4A78:
	db $1f, $b0, $f1, $f7, $c6, $03
Sfx1_49_Data_4A7E:
	db $1f, $b0, $f1, $c4, $c6, $03
Sfx1_4A_Init:
	ld hl, Sfx1_4A_Data_4A91
	jp Sfx1_Start

Sfx1_4A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_StopWithRegs

Sfx1_4A_Data_4A91:
	db $1f, $80, $f8, $27, $86, $3a
Sfx1_4B_Init:
	ld hl, Sfx1_4B_Data_4AD4
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_4B_Play:
	call Sfx_DecTimer
	jr nz, .l0
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_4B_Data_4ADA
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l0:
	ld hl, $ff9c
	jp Sfx1_4B_Shared_4ABC

Sfx1_4B_Shared_4ABC:
	ld a, [wSfx1Pitch]
	ld e, a
	ld a, [wSfx1Pitch+1]
	ld d, a
	add hl, de
	ld a, l
	ld [wSfx1Pitch], a
	ldh [rNR13], a
	ld a, h
	and $07
	ldh [rNR14], a
	ld [wSfx1Pitch+1], a
	ret

Sfx1_4B_Data_4AD4:
	db $08, $80, $f8, $83, $84, $08
Sfx1_4B_Data_4ADA:
	db $08, $80, $f8, $42, $86, $0e
Sfx1_4C_Init:
	ld hl, Sfx1_4C_Data_4AF8
	jp Sfx1_Start

Sfx1_4C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_4C_Data_4AFE
	jp SetRegs_Ch1

Sfx1_4C_Data_4AF8:
	db $37, $80, $e1, $42, $86, $03
Sfx1_4C_Data_4AFE:
	db $47, $40, $e2, $4b, $86, $23
Sfx1_4D_Init:
	call Sfx2_StopWithRegs
	call Sfx4_StopWithRegs
	ld a, [wSongPlaying]
	and a
	jr z, .l0
	ld [wPausedSong], a
.l0:
	xor a
	ld [wSongPlaying], a
	ld [wChannelsPlayed], a
	ldh [rNR32], a
	jp Sfx1_StopSilent

Sfx1_4D_Play:
	jp Sfx1_Stop

Sfx1_4E_Init:
	ld a, [wPausedSong]
	and a
	jr z, Sfx1_4E_Play
	ld [wSongPlaying], a
Sfx1_4E_Play:
	jp Sfx1_Stop

Sfx1_60_Init:
	ld hl, Sfx1_60_Data_4B57
	jp Sfx1_Start

Sfx1_60_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_60_Data_4B49
	call GetPointer
	jp SetRegs_Ch1

Sfx1_60_Data_4B49:
	dw Sfx1_60_Data_4B5D, Sfx1_60_Data_4B63, Sfx1_60_Data_4B69, Sfx1_60_Data_4B6F, Sfx1_60_Data_4B75, Sfx1_60_Data_4B7B, Sfx1_60_Data_4B81
Sfx1_60_Data_4B57:
	db $1c, $80, $f7, $ac, $85, $04
Sfx1_60_Data_4B5D:
	db $1c, $80, $11, $d6, $86, $01
Sfx1_60_Data_4B63:
	db $1c, $80, $f7, $ac, $85, $05
Sfx1_60_Data_4B69:
	db $17, $80, $c2, $06, $87, $03
Sfx1_60_Data_4B6F:
	db $17, $80, $a2, $06, $87, $03
Sfx1_60_Data_4B75:
	db $17, $80, $72, $06, $87, $03
Sfx1_60_Data_4B7B:
	db $17, $80, $42, $06, $87, $03
Sfx1_60_Data_4B81:
	db $17, $80, $22, $06, $87, $03
Sfx1_61_Init:
	call Sound_Stop
	xor a
	ld [wSfxStep2], a
	ld [wSfx2Step], a
	ld [wSfx4Step], a
	ld hl, Sfx1_61_Data_4BA6
	call Sfx1_StartPriority
	ld hl, Sfx1_61_Data_4BAC
	call SetRegs_Ch2
	ld hl, Sfx1_61_Data_4BB7
	jp SetRegs_Ch4

Sfx1_61_Data_4BA6:
	db $08, $40, $c2, $59, $87, $06
Sfx1_61_Data_4BAC:
	db $40, $c2, $2d, $87, $06
	db $00, $00, $20, $f8, $06
	db $3a
Sfx1_61_Data_4BB7:
	db $00, $08, $00, $00, $3a
	db $00, $11, $22, $33, $44
	db $55, $66, $77, $88, $99
	db $aa, $bb, $cc, $dd, $ee
	db $ff
Sfx1_61_Play:
	call Sfx_DecTimer
	jr nz, .l0
	call Sfx_IncStep
	cp $13
	jp z, Sfx1_Stop
	ld hl, Sfx1_61_Data_4C44
	call GetPointer
	call SetRegs_Ch1
.l0:
	ld de, wSfx2Timer
	call Sfx_DecTimer
	jr nz, .l1
	ld bc, wSfxStep2
	call Sfx_IncStep
	ld hl, Sfx1_61_Data_4C0F
	call GetPointer
	call SetRegs_Ch2
.l1:
	ld de, wSfx4Timer
	call Sfx_DecTimer
	ret nz
	ld bc, wSfx4Step
	call Sfx_IncStep
	ld hl, Sfx1_61_Data_4C36
	call GetPointer
	jp SetRegs_Ch4

Sfx1_61_Data_4C0F:
	dw Sfx1_61_Data_4C22, Sfx1_61_Data_4C1D, Sfx1_61_Data_4C27, Sfx1_61_Data_4C1D, Sfx1_61_Data_4C2C, Sfx1_61_Data_4C1D, Sfx1_61_Data_4C31
Sfx1_61_Data_4C1D:
	db $40, $11, $2d, $87, $06
Sfx1_61_Data_4C22:
	db $40, $c2, $39, $87, $06
Sfx1_61_Data_4C27:
	db $40, $c2, $44, $87, $06
Sfx1_61_Data_4C2C:
	db $40, $c2, $4f, $87, $06
Sfx1_61_Data_4C31:
	db $40, $c2, $59, $87, $ff
Sfx1_61_Data_4C36:
	dw Sfx1_61_Data_4C3A, Sfx1_61_Data_4C3F
Sfx1_61_Data_4C3A:
	db $00, $71, $51, $80, $10
Sfx1_61_Data_4C3F:
	db $00, $71, $51, $80, $ff
Sfx1_61_Data_4C44:
	dw Sfx1_61_Data_4C6E, Sfx1_61_Data_4C68, Sfx1_61_Data_4C74, Sfx1_61_Data_4C68, Sfx1_61_Data_4C7A, Sfx1_61_Data_4C68, Sfx1_61_Data_4C80, Sfx1_70_Data_4C86
Sfx1_70_Data_4C54:
	dw Sfx1_70_Data_4C8C, Sfx1_70_Data_4C92, Sfx1_70_Data_4C98, Sfx1_70_Data_4C9E, Sfx1_70_Data_4CA4, Sfx1_70_Data_4CAA, Sfx1_70_Data_4CB0, Sfx1_70_Data_4CB6, Sfx1_70_Data_4CBC, Sfx1_70_Data_4CC2
Sfx1_61_Data_4C68:
	db $08, $40, $11, $59, $87, $06
Sfx1_61_Data_4C6E:
	db $08, $40, $c2, $62, $87, $06
Sfx1_61_Data_4C74:
	db $08, $40, $c2, $6b, $87, $06
Sfx1_61_Data_4C7A:
	db $08, $40, $c2, $74, $87, $06
Sfx1_61_Data_4C80:
	db $08, $40, $c2, $7b, $87, $10
Sfx1_70_Data_4C86:
	db $17, $00, $f8, $44, $87, $07
Sfx1_70_Data_4C8C:
	db $08, $00, $08, $00, $8f, $09
Sfx1_70_Data_4C92:
	db $08, $00, $f8, $62, $87, $01
Sfx1_70_Data_4C98:
	db $08, $00, $e8, $5f, $87, $01
Sfx1_70_Data_4C9E:
	db $08, $00, $d8, $5c, $87, $01
Sfx1_70_Data_4CA4:
	db $08, $00, $c8, $59, $87, $01
Sfx1_70_Data_4CAA:
	db $08, $00, $b8, $56, $87, $01
Sfx1_70_Data_4CB0:
	db $08, $00, $a8, $53, $87, $01
Sfx1_70_Data_4CB6:
	db $08, $00, $98, $50, $87, $01
Sfx1_70_Data_4CBC:
	db $08, $00, $88, $4d, $87, $01
Sfx1_70_Data_4CC2:
	db $08, $00, $11, $4d, $87, $03
Sfx1_62_Init:
	ld a, $01
	ld [wSfx2Request], a
	ld hl, Sfx1_62_Data_4CFA
	jp Sfx1_StartPriority

Sfx1_62_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_62_Data_4CE8
	call GetPointer
	jp SetRegs_Ch1

Sfx1_62_Data_4CE8:
	dw Sfx1_62_Data_4D00, Sfx1_62_Data_4D06, Sfx1_62_Data_4D0C, Sfx1_62_Data_4CFA, Sfx1_62_Data_4D00, Sfx1_62_Data_4D06, Sfx1_62_Data_4D0C, Sfx1_62_Data_4CFA, Sfx1_62_Data_4D12
Sfx1_62_Data_4CFA:
	db $08, $80, $d1, $ac, $87, $01
Sfx1_62_Data_4D00:
	db $08, $80, $72, $ac, $87, $05
Sfx1_62_Data_4D06:
	db $08, $80, $c1, $a7, $87, $01
Sfx1_62_Data_4D0C:
	db $08, $80, $72, $a7, $87, $05
Sfx1_62_Data_4D12:
	db $08, $80, $72, $ac, $87, $0e
Sfx2_01_Init:
	ld hl, Sfx2_01_Data_4D45
	jp Sfx2_Start

Sfx2_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx2_Stop
	ld hl, Sfx2_01_Data_4D33
	call GetPointer
	jp SetRegs_Ch2

Sfx2_01_Data_4D33:
	dw Sfx2_01_Data_4D4A, Sfx2_01_Data_4D4F, Sfx2_01_Data_4D54, Sfx2_01_Data_4D45, Sfx2_01_Data_4D4A, Sfx2_01_Data_4D4F, Sfx2_01_Data_4D54, Sfx2_01_Data_4D45, Sfx2_01_Data_4D59
Sfx2_01_Data_4D45:
	db $80, $d1, $9d, $87, $01
Sfx2_01_Data_4D4A:
	db $80, $72, $9d, $87, $05
Sfx2_01_Data_4D4F:
	db $80, $f1, $97, $87, $01
Sfx2_01_Data_4D54:
	db $80, $72, $97, $87, $05
Sfx2_01_Data_4D59:
	db $80, $72, $9d, $87, $0e
Sfx1_63_Init:
	ld hl, Sfx1_63_Data_4D7D
	jp Sfx1_Start

Sfx1_63_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_63_Data_4D79
	call GetPointer
	jp SetRegs_Ch1

Sfx1_63_Data_4D79:
	dw Sfx1_63_Data_4D83, Sfx1_63_Data_4D89
Sfx1_63_Data_4D7D:
	db $2f, $a8, $49, $74, $c7, $05
Sfx1_63_Data_4D83:
	db $2f, $a8, $11, $74, $c7, $02
Sfx1_63_Data_4D89:
	db $2f, $a8, $49, $14, $c7, $06
Sfx1_64_Init:
	ld hl, Sfx1_64_Data_4DA7
	jp Sfx1_Start

Sfx1_64_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_64_Data_4DAD
	jp SetRegs_Ch1

Sfx1_64_Data_4DA7:
	db $08, $40, $c7, $d6, $86, $05
Sfx1_64_Data_4DAD:
	db $08, $40, $62, $d6, $86, $0e
Sfx1_65_Init:
	ld hl, Sfx1_65_Data_4DCB
	jp Sfx1_Start

Sfx1_65_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_65_Data_4DD1
	jp SetRegs_Ch1

Sfx1_65_Data_4DCB:
	db $08, $40, $e7, $6b, $87, $05
Sfx1_65_Data_4DD1:
	db $08, $40, $87, $6b, $87, $38
Sfx1_66_Init:
	ld a, $02
	ld [wSfx2Request], a
	ld hl, Sfx1_66_Data_4E09
	jp Sfx1_Start

Sfx1_66_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_66_Data_4DF7
	call GetPointer
	jp SetRegs_Ch1

Sfx1_66_Data_4DF7:
	dw Sfx1_66_Data_4E0F, Sfx1_66_Data_4E15, Sfx1_66_Data_4E1B, Sfx1_66_Data_4E09, Sfx1_66_Data_4E0F, Sfx1_66_Data_4E15, Sfx1_66_Data_4E1B, Sfx1_66_Data_4E21, Sfx1_66_Data_4E27
Sfx1_66_Data_4E09:
	db $08, $80, $b1, $a2, $87, $01
Sfx1_66_Data_4E0F:
	db $08, $80, $72, $a2, $87, $05
Sfx1_66_Data_4E15:
	db $08, $80, $b1, $ac, $87, $01
Sfx1_66_Data_4E1B:
	db $08, $80, $72, $ac, $87, $05
Sfx1_66_Data_4E21:
	db $08, $80, $b1, $c1, $87, $01
Sfx1_66_Data_4E27:
	db $08, $80, $72, $c1, $87, $0e
Sfx2_02_Init:
	ld hl, Sfx2_02_Data_4E5A
	jp Sfx2_Start

Sfx2_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx2_Stop
	ld hl, Sfx2_02_Data_4E48
	call GetPointer
	jp SetRegs_Ch2

Sfx2_02_Data_4E48:
	dw Sfx2_02_Data_4E5F, Sfx2_02_Data_4E64, Sfx2_02_Data_4E69, Sfx2_02_Data_4E5A, Sfx2_02_Data_4E5F, Sfx2_02_Data_4E64, Sfx2_02_Data_4E69, Sfx2_02_Data_4E6E, Sfx2_02_Data_4E73
Sfx2_02_Data_4E5A:
	db $80, $b1, $90, $87, $01
Sfx2_02_Data_4E5F:
	db $80, $72, $90, $87, $05
Sfx2_02_Data_4E64:
	db $80, $b1, $9d, $87, $01
Sfx2_02_Data_4E69:
	db $80, $72, $9d, $87, $05
Sfx2_02_Data_4E6E:
	db $80, $b1, $ac, $87, $01
Sfx2_02_Data_4E73:
	db $80, $72, $ac, $87, $0e
Sfx1_67_Init:
	ld hl, Sfx1_67_Data_4EB1
	jp Sfx1_Start

Sfx1_67_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx1_Stop
	ld hl, Sfx1_67_Data_4E93
	call GetPointer
	jp SetRegs_Ch1

Sfx1_67_Data_4E93:
	dw Sfx1_67_Data_4EB7, Sfx1_67_Data_4EBD, Sfx1_67_Data_4EC3, Sfx1_67_Data_4EC9, Sfx1_67_Data_4EB7, Sfx1_67_Data_4EBD, Sfx1_67_Data_4EC3, Sfx1_67_Data_4EC9, Sfx1_67_Data_4ECF, Sfx1_67_Data_4EBD, Sfx1_67_Data_4EC3, Sfx1_67_Data_4EC9, Sfx1_67_Data_4ECF, Sfx1_67_Data_4ED5, Sfx1_67_Data_4EDB
Sfx1_67_Data_4EB1:
	db $08, $bc, $c8, $59, $c7, $02
Sfx1_67_Data_4EB7:
	db $08, $bc, $c8, $6b, $c7, $02
Sfx1_67_Data_4EBD:
	db $08, $bc, $c8, $7b, $c7, $02
Sfx1_67_Data_4EC3:
	db $08, $bc, $c8, $83, $c7, $02
Sfx1_67_Data_4EC9:
	db $08, $bc, $c8, $90, $c7, $02
Sfx1_67_Data_4ECF:
	db $08, $bc, $c8, $9d, $c7, $02
Sfx1_67_Data_4ED5:
	db $08, $bc, $c8, $a2, $c7, $02
Sfx1_67_Data_4EDB:
	db $08, $80, $c1, $ac, $87, $0f
Sfx1_68_Init:
	ld hl, Sfx1_68_Data_4F0C
	jp Sfx1_Start

Sfx1_68_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_68_Data_4EFC
	call GetPointer
	jp SetRegs_Ch1

Sfx1_68_Data_4EFC:
	dw Sfx1_68_Data_4F12, Sfx1_68_Data_4F18, Sfx1_68_Data_4F1E, Sfx1_68_Data_4F24, Sfx1_68_Data_4F2A, Sfx1_68_Data_4F30, Sfx1_68_Data_4F36, Sfx1_68_Data_4F3C
Sfx1_68_Data_4F0C:
	db $37, $a8, $d8, $d6, $c6, $02
Sfx1_68_Data_4F12:
	db $37, $70, $d8, $d6, $c6, $06
Sfx1_68_Data_4F18:
	db $2f, $74, $c2, $44, $c7, $06
Sfx1_68_Data_4F1E:
	db $2f, $74, $a2, $44, $c7, $06
Sfx1_68_Data_4F24:
	db $2f, $74, $82, $44, $c7, $06
Sfx1_68_Data_4F2A:
	db $2f, $74, $62, $44, $c7, $06
Sfx1_68_Data_4F30:
	db $2f, $74, $52, $44, $c7, $06
Sfx1_68_Data_4F36:
	db $2f, $74, $42, $44, $c7, $06
Sfx1_68_Data_4F3C:
	db $2f, $74, $22, $44, $c7, $06
Sfx1_69_Init:
	ld hl, Sfx1_69_Data_4F67
	jp Sfx1_Start

Sfx1_69_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_69_Data_4F5D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_69_Data_4F5D:
	dw Sfx1_69_Data_4F6D, Sfx1_69_Data_4F73, Sfx1_69_Data_4F79, Sfx1_69_Data_4F7F, Sfx1_69_Data_4F85
Sfx1_69_Data_4F67:
	db $37, $a8, $98, $d6, $c6, $02
Sfx1_69_Data_4F6D:
	db $37, $74, $98, $d6, $c6, $05
Sfx1_69_Data_4F73:
	db $2f, $74, $82, $39, $c7, $06
Sfx1_69_Data_4F79:
	db $2f, $74, $62, $39, $c7, $06
Sfx1_69_Data_4F7F:
	db $2f, $74, $42, $39, $c7, $06
Sfx1_69_Data_4F85:
	db $2f, $74, $22, $39, $c7, $06
Sfx1_6A_Init:
	ld hl, Sfx1_6A_Data_4FB6
	jp Sfx1_Start

Sfx1_6A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_6A_Data_4FA6
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6A_Data_4FA6:
	dw Sfx1_6A_Data_4FBC, Sfx1_6A_Data_4FC2, Sfx1_6A_Data_4FC8, Sfx1_6A_Data_4FCE, Sfx1_6A_Data_4FD4, Sfx1_6A_Data_4FDA, Sfx1_6A_Data_4FE0, Sfx1_6A_Data_4FE6
Sfx1_6A_Data_4FB6:
	db $36, $a8, $f8, $42, $c6, $02
Sfx1_6A_Data_4FBC:
	db $36, $70, $f8, $42, $c6, $06
Sfx1_6A_Data_4FC2:
	db $2e, $74, $e2, $e7, $c6, $06
Sfx1_6A_Data_4FC8:
	db $2e, $74, $c2, $e7, $c6, $06
Sfx1_6A_Data_4FCE:
	db $2e, $74, $a2, $e7, $c6, $06
Sfx1_6A_Data_4FD4:
	db $2e, $74, $82, $e7, $c6, $06
Sfx1_6A_Data_4FDA:
	db $2e, $74, $62, $e7, $c6, $06
Sfx1_6A_Data_4FE0:
	db $2e, $74, $52, $e7, $c6, $06
Sfx1_6A_Data_4FE6:
	db $2e, $74, $22, $e7, $c6, $06
Sfx1_6B_Init:
	ld hl, Sfx1_6B_Data_5011
	jp Sfx1_Start

Sfx1_6B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_6B_Data_5007
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6B_Data_5007:
	dw Sfx1_6B_Data_5017, Sfx1_6B_Data_501D, Sfx1_6B_Data_5023, Sfx1_6B_Data_5029, Sfx1_6B_Data_502F
Sfx1_6B_Data_5011:
	db $36, $a8, $b8, $42, $c6, $02
Sfx1_6B_Data_5017:
	db $36, $74, $b8, $42, $c6, $05
Sfx1_6B_Data_501D:
	db $2e, $74, $a2, $d6, $c6, $06
Sfx1_6B_Data_5023:
	db $2e, $74, $82, $d6, $c6, $06
Sfx1_6B_Data_5029:
	db $2e, $74, $62, $d6, $c6, $06
Sfx1_6B_Data_502F:
	db $2e, $74, $42, $d6, $c6, $06
Sfx1_6C_Init:
	ld hl, Sfx1_6C_Data_5058
	jp Sfx1_Start

Sfx1_6C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_6C_Data_5050
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6C_Data_5050:
	dw Sfx1_6C_Data_505E, Sfx1_6C_Data_5064, Sfx1_6C_Data_506A, Sfx1_6C_Data_5070
Sfx1_6C_Data_5058:
	db $36, $a8, $f8, $63, $c4, $02
Sfx1_6C_Data_505E:
	db $36, $74, $c8, $42, $c6, $04
Sfx1_6C_Data_5064:
	db $2e, $74, $b2, $d6, $c6, $05
Sfx1_6C_Data_506A:
	db $2e, $74, $92, $d6, $c6, $05
Sfx1_6C_Data_5070:
	db $2e, $74, $72, $d6, $c6, $05
Sfx1_6D_Init:
	ld a, [wSongPlaying]
	cp $22
	ret z
	ld hl, Sfx1_6D_Data_5094
	jp Sfx1_Start

Sfx1_6D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_6D_Data_509A
	jp SetRegs_Ch1

Sfx1_6D_Data_5094:
	db $08, $b4, $78, $59, $c7, $02
Sfx1_6D_Data_509A:
	db $08, $80, $27, $59, $87, $0e
Sfx1_6E_Init:
	ld a, $03
	ld [wSfx2Request], a
	ld hl, Sfx1_6E_Data_50D2
	jp Sfx1_StartPriority

Sfx1_6E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_6E_Data_50C0
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6E_Data_50C0:
	dw Sfx1_6E_Data_50D8, Sfx1_6E_Data_50DE, Sfx1_6E_Data_50E4, Sfx1_6E_Data_50EA, Sfx1_6E_Data_50F0, Sfx1_6E_Data_50F6, Sfx1_6E_Data_50FC, Sfx1_6E_Data_5102, Sfx1_6E_Data_5108
Sfx1_6E_Data_50D2:
	db $08, $b8, $a1, $83, $c7, $03
Sfx1_6E_Data_50D8:
	db $08, $b8, $91, $ac, $c7, $03
Sfx1_6E_Data_50DE:
	db $08, $b8, $a1, $9d, $c7, $03
Sfx1_6E_Data_50E4:
	db $08, $b8, $b1, $be, $c7, $03
Sfx1_6E_Data_50EA:
	db $08, $b8, $c1, $ac, $c7, $03
Sfx1_6E_Data_50F0:
	db $08, $b8, $a1, $c8, $c7, $03
Sfx1_6E_Data_50F6:
	db $08, $b8, $91, $be, $c7, $03
Sfx1_6E_Data_50FC:
	db $08, $b8, $81, $d4, $c7, $03
Sfx1_6E_Data_5102:
	db $08, $b8, $61, $cb, $c7, $03
Sfx1_6E_Data_5108:
	db $08, $b8, $41, $db, $c7, $03
Sfx2_03_Init:
	ld hl, Sfx2_03_Data_513B
	jp Sfx2_Start

Sfx2_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx2_Stop
	ld hl, Sfx2_03_Data_5129
	call GetPointer
	jp SetRegs_Ch2

Sfx2_03_Data_5129:
	dw Sfx2_03_Data_5140, Sfx2_03_Data_5145, Sfx2_03_Data_514A, Sfx2_03_Data_514F, Sfx2_03_Data_5154, Sfx2_03_Data_5159, Sfx2_03_Data_515E, Sfx2_03_Data_5163, Sfx2_03_Data_5168
Sfx2_03_Data_513B:
	db $90, $47, $83, $c7, $08
Sfx2_03_Data_5140:
	db $a0, $38, $ac, $c7, $03
Sfx2_03_Data_5145:
	db $a0, $48, $9d, $c7, $03
Sfx2_03_Data_514A:
	db $a0, $58, $be, $c7, $03
Sfx2_03_Data_514F:
	db $a0, $68, $ac, $c7, $03
Sfx2_03_Data_5154:
	db $a0, $58, $c8, $c7, $03
Sfx2_03_Data_5159:
	db $a0, $48, $be, $c7, $03
Sfx2_03_Data_515E:
	db $a0, $38, $d4, $c7, $03
Sfx2_03_Data_5163:
	db $a0, $28, $c8, $c7, $03
Sfx2_03_Data_5168:
	db $a0, $18, $db, $c7, $03
Sfx1_6F_Init:
	ld a, $40
	ld [wSfx4Request], a
	ld hl, Sfx1_6F_Data_51A7
	jp Sfx1_Start

Sfx1_6F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0e
	jp z, Sfx1_Stop
	ld hl, Sfx1_6F_Data_518D
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_6F_Data_518D:
	dw Sfx1_6F_Data_51AD, Sfx1_6F_Data_51B3, Sfx1_6F_Data_51B9, Sfx1_6F_Data_51BF, Sfx1_6F_Data_51C5, Sfx1_6F_Data_51CB, Sfx1_6F_Data_51D1, Sfx1_6F_Data_51D7, Sfx1_6F_Data_51DD, Sfx1_6F_Data_51E3, Sfx1_6F_Data_51E9, Sfx1_6F_Data_51EF, Sfx1_6F_Data_51F5
Sfx1_6F_Data_51A7:
	db $08, $80, $08, $2c, $80, $04
Sfx1_6F_Data_51AD:
	db $1f, $a8, $a9, $59, $c7, $03
Sfx1_6F_Data_51B3:
	db $08, $80, $77, $06, $87, $02
Sfx1_6F_Data_51B9:
	db $00, $00, $00, $39, $07, $02
Sfx1_6F_Data_51BF:
	db $00, $00, $00, $7b, $07, $02
Sfx1_6F_Data_51C5:
	db $00, $00, $00, $59, $07, $02
Sfx1_6F_Data_51CB:
	db $00, $00, $00, $39, $07, $02
Sfx1_6F_Data_51D1:
	db $00, $00, $00, $59, $07, $02
Sfx1_6F_Data_51D7:
	db $00, $00, $00, $90, $07, $02
Sfx1_6F_Data_51DD:
	db $00, $00, $00, $7b, $07, $02
Sfx1_6F_Data_51E3:
	db $00, $00, $00, $59, $07, $02
Sfx1_6F_Data_51E9:
	db $00, $00, $00, $7b, $07, $02
Sfx1_6F_Data_51EF:
	db $00, $00, $00, $90, $07, $02
Sfx1_6F_Data_51F5:
	db $00, $00, $11, $90, $87, $01
Sfx4_40_Init:
	ld hl, Sfx4_40_Data_5208
	jp Sfx4_Start

Sfx4_40_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_40_Data_5208:
	db $38, $99, $27, $c0, $05
Sfx1_70_Init:
	ld a, $3e
	ld [wSfx4Request], a
	ld hl, Sfx1_70_Data_4C86
	jp Sfx1_Start

Sfx1_70_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx1_Stop
	ld hl, Sfx1_70_Data_4C54
	call GetPointer
	jp SetRegs_Ch1

Sfx4_3E_Init:
	ld hl, Sfx4_3E_Data_5245
	jp Sfx4_Start

Sfx4_3E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_3E_Data_524A
	jp SetRegs_Ch4

Sfx4_3E_Data_5245:
	db $00, $71, $51, $80, $10
Sfx4_3E_Data_524A:
	db $00, $71, $51, $80, $09
Sfx1_71_Init:
	call Sound_Stop
	ld hl, Sfx1_71_Data_5293
	jp Sfx1_Start

Sfx1_71_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx1_Stop
	ld hl, Sfx1_71_Data_526D
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_71_Data_526D:
	dw Sfx1_71_Data_5299, Sfx1_71_Data_529F, Sfx1_71_Data_52A5, Sfx1_71_Data_52AB, Sfx1_71_Data_52B1, Sfx1_71_Data_52B7, Sfx1_71_Data_52BD, Sfx1_71_Data_52C3, Sfx1_71_Data_52C9, Sfx1_71_Data_52CF, Sfx1_71_Data_52D5, Sfx1_71_Data_52DB, Sfx1_71_Data_52E1, Sfx1_71_Data_52E7, Sfx1_71_Data_52ED, Sfx1_71_Data_52F3, Sfx1_71_Data_52F9, Sfx1_71_Data_52FF, Sfx1_71_Data_5305
Sfx1_71_Data_5293:
	db $17, $a0, $d2, $ed, $c5, $0c
Sfx1_71_Data_5299:
	db $17, $a0, $d2, $ce, $c5, $0d
Sfx1_71_Data_529F:
	db $17, $a0, $d2, $ac, $c5, $0e
Sfx1_71_Data_52A5:
	db $17, $a0, $d2, $89, $c5, $0f
Sfx1_71_Data_52AB:
	db $57, $80, $d6, $63, $c5, $0e
Sfx1_71_Data_52B1:
	db $1f, $a4, $a6, $ac, $c5, $06
Sfx1_71_Data_52B7:
	db $16, $a4, $a6, $63, $c5, $06
Sfx1_71_Data_52BD:
	db $1e, $a4, $96, $0a, $c6, $06
Sfx1_71_Data_52C3:
	db $16, $a4, $96, $63, $c5, $06
Sfx1_71_Data_52C9:
	db $1e, $a4, $86, $0a, $c6, $06
Sfx1_71_Data_52CF:
	db $16, $a4, $86, $63, $c5, $06
Sfx1_71_Data_52D5:
	db $1e, $a4, $76, $0a, $c6, $06
Sfx1_71_Data_52DB:
	db $16, $a4, $76, $63, $c5, $06
Sfx1_71_Data_52E1:
	db $1e, $a4, $66, $0a, $c6, $06
Sfx1_71_Data_52E7:
	db $16, $a4, $66, $63, $c5, $06
Sfx1_71_Data_52ED:
	db $1e, $a4, $56, $0a, $c6, $06
Sfx1_71_Data_52F3:
	db $16, $a4, $46, $63, $c5, $06
Sfx1_71_Data_52F9:
	db $1e, $a4, $36, $0a, $c6, $06
Sfx1_71_Data_52FF:
	db $16, $a4, $26, $63, $c5, $06
Sfx1_71_Data_5305:
	db $1e, $a4, $16, $0a, $c6, $06
Sfx1_72_Init:
	ld hl, Sfx1_72_Data_532C
	jp Sfx1_Start

Sfx1_72_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx1_72_Data_5326
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_72_Data_5326:
	dw Sfx1_72_Data_5332, Sfx1_72_Data_5338, Sfx1_72_Data_533E
Sfx1_72_Data_532C:
	db $08, $bd, $a1, $83, $c7, $02
Sfx1_72_Data_5332:
	db $08, $80, $55, $83, $87, $01
Sfx1_72_Data_5338:
	db $00, $80, $00, $9d, $07, $01
Sfx1_72_Data_533E:
	db $00, $80, $00, $ac, $07, $1e
Sfx1_73_Init:
	ld hl, Sfx1_73_Data_537F
	jp Sfx1_Start

Sfx1_73_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $11
	jp z, Sfx1_Stop
	ld hl, Sfx1_73_Data_535F
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_73_Data_535F:
	dw Sfx1_73_Data_5385, Sfx1_73_Data_538B, Sfx1_73_Data_5391, Sfx1_73_Data_5397, Sfx1_73_Data_537F, Sfx1_73_Data_5385, Sfx1_73_Data_538B, Sfx1_73_Data_5391, Sfx1_73_Data_5397, Sfx1_73_Data_539D, Sfx1_73_Data_53A3, Sfx1_73_Data_53A9, Sfx1_73_Data_53AF, Sfx1_73_Data_53B5, Sfx1_73_Data_53BB, Sfx1_73_Data_53C1
Sfx1_73_Data_537F:
	db $1e, $38, $99, $a2, $c7, $04
Sfx1_73_Data_5385:
	db $1e, $38, $f9, $a4, $c7, $04
Sfx1_73_Data_538B:
	db $1e, $38, $d9, $a2, $c7, $04
Sfx1_73_Data_5391:
	db $1e, $38, $f9, $9d, $c7, $04
Sfx1_73_Data_5397:
	db $1e, $38, $99, $97, $c7, $04
Sfx1_73_Data_539D:
	db $1e, $38, $89, $90, $c7, $04
Sfx1_73_Data_53A3:
	db $1e, $38, $79, $59, $c7, $04
Sfx1_73_Data_53A9:
	db $1e, $38, $49, $59, $c7, $04
Sfx1_73_Data_53AF:
	db $1e, $38, $39, $59, $c7, $04
Sfx1_73_Data_53B5:
	db $1e, $38, $29, $59, $c7, $04
Sfx1_73_Data_53BB:
	db $1e, $38, $19, $59, $c7, $04
Sfx1_73_Data_53C1:
	db $1e, $3c, $19, $59, $c7, $04
Sfx1_74_Init:
	ld hl, Sfx1_74_Data_53EA
	jp Sfx1_Start

Sfx1_74_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_74_Data_53E2
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_74_Data_53E2:
	dw Sfx1_74_Data_53F0, Sfx1_74_Data_53F6, Sfx1_74_Data_53FC, Sfx1_74_Data_5402
Sfx1_74_Data_53EA:
	db $08, $80, $44, $83, $87, $01
Sfx1_74_Data_53F0:
	db $00, $00, $00, $74, $07, $01
Sfx1_74_Data_53F6:
	db $00, $00, $00, $6b, $07, $01
Sfx1_74_Data_53FC:
	db $00, $00, $00, $be, $07, $01
Sfx1_74_Data_5402:
	db $00, $00, $00, $8a, $07, $01
Sfx1_75_Init:
	ld hl, Sfx1_75_Data_542B
	jp Sfx1_Start

Sfx1_75_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_75_Data_5423
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_75_Data_5423:
	dw Sfx1_75_Data_5431, Sfx1_75_Data_5437, Sfx1_75_Data_543D, Sfx1_75_Data_5443
Sfx1_75_Data_542B:
	db $08, $80, $44, $44, $87, $01
Sfx1_75_Data_5431:
	db $00, $00, $00, $2d, $07, $01
Sfx1_75_Data_5437:
	db $00, $00, $00, $21, $07, $01
Sfx1_75_Data_543D:
	db $00, $00, $00, $39, $07, $01
Sfx1_75_Data_5443:
	db $00, $00, $00, $4f, $07, $01
Sfx1_76_Init:
	call Sound_Stop
	ld a, $04
	ld [wSfx2Request], a
	ld hl, Sfx1_76_Data_54A4
	jp Sfx1_StartPriority

Sfx1_76_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1d
	jp z, Sfx1_Stop
	ld hl, Sfx1_76_Data_546C
	call GetPointer
	jp SetRegs_Ch1

Sfx1_76_Data_546C:
	dw Sfx1_76_Data_54AA, Sfx1_76_Data_54B0, Sfx1_76_Data_54B6, Sfx1_76_Data_54BC, Sfx1_76_Data_54C2, Sfx1_76_Data_54C8, Sfx1_76_Data_54CE, Sfx1_76_Data_54D4, Sfx1_76_Data_54DA, Sfx1_76_Data_54E0, Sfx1_76_Data_54E6, Sfx1_76_Data_54EC, Sfx1_76_Data_54F2, Sfx1_76_Data_54F8, Sfx1_76_Data_54FE, Sfx1_76_Data_5504, Sfx1_76_Data_550A, Sfx1_76_Data_5510, Sfx1_76_Data_5516, Sfx1_76_Data_551C, Sfx1_76_Data_5522, Sfx1_76_Data_5528, Sfx1_76_Data_552E, Sfx1_76_Data_5534, Sfx1_76_Data_553A, Sfx1_76_Data_5540, Sfx1_76_Data_5546, Sfx1_76_Data_554C
Sfx1_76_Data_54A4:
	db $08, $b4, $b1, $59, $c7, $02
Sfx1_76_Data_54AA:
	db $08, $b4, $b1, $7b, $c7, $02
Sfx1_76_Data_54B0:
	db $08, $b4, $b1, $90, $c7, $02
Sfx1_76_Data_54B6:
	db $08, $b4, $b1, $a2, $c7, $02
Sfx1_76_Data_54BC:
	db $08, $b4, $b1, $7b, $c7, $02
Sfx1_76_Data_54C2:
	db $08, $b4, $b1, $90, $c7, $02
Sfx1_76_Data_54C8:
	db $08, $b4, $b1, $a2, $c7, $02
Sfx1_76_Data_54CE:
	db $08, $b4, $b1, $b6, $c7, $02
Sfx1_76_Data_54D4:
	db $08, $b4, $b1, $90, $c7, $02
Sfx1_76_Data_54DA:
	db $08, $b4, $b1, $a2, $c7, $02
Sfx1_76_Data_54E0:
	db $08, $b4, $b1, $b6, $c7, $02
Sfx1_76_Data_54E6:
	db $08, $b4, $b1, $c1, $c7, $02
Sfx1_76_Data_54EC:
	db $08, $b4, $b1, $ce, $c7, $02
Sfx1_76_Data_54F2:
	db $08, $b4, $81, $a2, $c7, $02
Sfx1_76_Data_54F8:
	db $08, $b4, $81, $b6, $c7, $02
Sfx1_76_Data_54FE:
	db $08, $b4, $81, $c1, $c7, $02
Sfx1_76_Data_5504:
	db $08, $b4, $81, $ce, $c7, $02
Sfx1_76_Data_550A:
	db $08, $b4, $61, $a2, $c7, $02
Sfx1_76_Data_5510:
	db $08, $b4, $61, $b6, $c7, $02
Sfx1_76_Data_5516:
	db $08, $b4, $61, $c1, $c7, $02
Sfx1_76_Data_551C:
	db $08, $b4, $61, $ce, $c7, $02
Sfx1_76_Data_5522:
	db $08, $b4, $41, $a2, $c7, $02
Sfx1_76_Data_5528:
	db $08, $b4, $41, $b6, $c7, $02
Sfx1_76_Data_552E:
	db $08, $b4, $41, $c1, $c7, $02
Sfx1_76_Data_5534:
	db $08, $b4, $41, $ce, $c7, $02
Sfx1_76_Data_553A:
	db $08, $b4, $21, $a2, $c7, $02
Sfx1_76_Data_5540:
	db $08, $b4, $21, $b6, $c7, $02
Sfx1_76_Data_5546:
	db $08, $b4, $21, $c1, $c7, $02
Sfx1_76_Data_554C:
	db $08, $b4, $21, $ce, $c7, $02
Sfx2_04_Init:
	ld hl, Sfx2_04_Data_55A5
	jp Sfx2_Start

Sfx2_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1d
	jp z, Sfx2_Stop
	ld hl, Sfx2_04_Data_556D
	call GetPointer
	jp SetRegs_Ch2

Sfx2_04_Data_556D:
	dw Sfx2_04_Data_55AA, Sfx2_04_Data_55AF, Sfx2_04_Data_55B4, Sfx2_04_Data_55B9, Sfx2_04_Data_55BE, Sfx2_04_Data_55C3, Sfx2_04_Data_55C8, Sfx2_04_Data_55CD, Sfx2_04_Data_55D2, Sfx2_04_Data_55D7, Sfx2_04_Data_55DC, Sfx2_04_Data_55E1, Sfx2_04_Data_55E6, Sfx2_04_Data_55EB, Sfx2_04_Data_55F0, Sfx2_04_Data_55F5, Sfx2_04_Data_55FA, Sfx2_04_Data_55FF, Sfx2_04_Data_5604, Sfx2_04_Data_5609, Sfx2_04_Data_560E, Sfx2_04_Data_5613, Sfx2_04_Data_5618, Sfx2_04_Data_561D, Sfx2_04_Data_5622, Sfx2_04_Data_5627, Sfx2_04_Data_562C, Sfx2_04_Data_5631
Sfx2_04_Data_55A5:
	db $b4, $59, $59, $c7, $03
Sfx2_04_Data_55AA:
	db $b4, $59, $7b, $c7, $02
Sfx2_04_Data_55AF:
	db $b4, $59, $90, $c7, $02
Sfx2_04_Data_55B4:
	db $b4, $59, $a2, $c7, $02
Sfx2_04_Data_55B9:
	db $b4, $59, $7b, $c7, $02
Sfx2_04_Data_55BE:
	db $b4, $59, $90, $c7, $02
Sfx2_04_Data_55C3:
	db $b4, $59, $a2, $c7, $02
Sfx2_04_Data_55C8:
	db $b4, $59, $b6, $c7, $02
Sfx2_04_Data_55CD:
	db $b4, $59, $90, $c7, $02
Sfx2_04_Data_55D2:
	db $b4, $59, $a2, $c7, $02
Sfx2_04_Data_55D7:
	db $b4, $59, $b6, $c7, $02
Sfx2_04_Data_55DC:
	db $b4, $59, $c1, $c7, $02
Sfx2_04_Data_55E1:
	db $b4, $59, $ce, $c7, $02
Sfx2_04_Data_55E6:
	db $b4, $39, $a2, $c7, $02
Sfx2_04_Data_55EB:
	db $b4, $39, $b6, $c7, $02
Sfx2_04_Data_55F0:
	db $b4, $39, $c1, $c7, $02
Sfx2_04_Data_55F5:
	db $b4, $39, $ce, $c7, $02
Sfx2_04_Data_55FA:
	db $b4, $29, $a2, $c7, $02
Sfx2_04_Data_55FF:
	db $b4, $29, $b6, $c7, $02
Sfx2_04_Data_5604:
	db $b4, $29, $c1, $c7, $02
Sfx2_04_Data_5609:
	db $b4, $29, $ce, $c7, $02
Sfx2_04_Data_560E:
	db $b4, $19, $a2, $c7, $02
Sfx2_04_Data_5613:
	db $b4, $19, $b6, $c7, $02
Sfx2_04_Data_5618:
	db $b4, $19, $c1, $c7, $02
Sfx2_04_Data_561D:
	db $b4, $19, $ce, $c7, $02
Sfx2_04_Data_5622:
	db $b4, $09, $a2, $c7, $02
Sfx2_04_Data_5627:
	db $b4, $09, $b6, $c7, $02
Sfx2_04_Data_562C:
	db $b4, $09, $c1, $c7, $02
Sfx2_04_Data_5631:
	db $b4, $09, $ce, $c7, $02
Sfx1_77_Init:
	ld a, [wSfx2Request]
	cp $25
	jp z, Sfx1_Stop
	ld hl, Sfx1_77_Data_566D
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_77_Play:
	call Sfx_DecTimer
	jr nz, Sfx1_77_Play_l0
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_77_Data_5660
	call GetPointer
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_77_Data_5660:
	dw Sfx1_77_Data_5673, Sfx1_77_Data_5679
Sfx1_77_Play_l0:
	ld a, [bc]
	and a
	ret z
	ld hl, $0007
	jp Sfx1_4B_Shared_4ABC

Sfx1_77_Data_566D:
	db $08, $a4, $59, $06, $c7, $05
Sfx1_77_Data_5673:
	db $08, $80, $92, $06, $87, $0c
Sfx1_77_Data_5679:
	db $08, $80, $27, $83, $87, $04
Sfx1_78_Init:
	ld hl, Sfx1_78_Data_56D2
	jp Sfx1_Start

Sfx1_78_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1d
	jp z, Sfx1_Stop
	ld hl, Sfx1_78_Data_569A
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_78_Data_569A:
	dw Sfx1_78_Data_56D8, Sfx1_78_Data_56DE, Sfx1_78_Data_56E4, Sfx1_78_Data_56EA, Sfx1_78_Data_56D2, Sfx1_78_Data_56D8, Sfx1_78_Data_56DE, Sfx1_78_Data_56E4, Sfx1_78_Data_56EA, Sfx1_78_Data_56F0, Sfx1_78_Data_56F6, Sfx1_78_Data_56FC, Sfx1_78_Data_5702, Sfx1_78_Data_5708, Sfx1_78_Data_570E, Sfx1_78_Data_5714, Sfx1_78_Data_571A, Sfx1_78_Data_5720, Sfx1_78_Data_5726, Sfx1_78_Data_572C, Sfx1_78_Data_5732, Sfx1_78_Data_5738, Sfx1_78_Data_573E, Sfx1_78_Data_5744, Sfx1_78_Data_574A, Sfx1_78_Data_5750, Sfx1_78_Data_5756, Sfx1_78_Data_575C
Sfx1_78_Data_56D2:
	db $08, $00, $1a, $9d, $87, $02
Sfx1_78_Data_56D8:
	db $00, $00, $00, $90, $07, $02
Sfx1_78_Data_56DE:
	db $00, $00, $00, $83, $07, $02
Sfx1_78_Data_56E4:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_56EA:
	db $00, $00, $00, $90, $07, $02
Sfx1_78_Data_56F0:
	db $00, $00, $00, $83, $07, $02
Sfx1_78_Data_56F6:
	db $00, $00, $00, $74, $07, $02
Sfx1_78_Data_56FC:
	db $00, $00, $00, $7b, $07, $02
Sfx1_78_Data_5702:
	db $00, $00, $82, $83, $87, $02
Sfx1_78_Data_5708:
	db $00, $00, $00, $74, $07, $02
Sfx1_78_Data_570E:
	db $00, $00, $00, $62, $07, $02
Sfx1_78_Data_5714:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_571A:
	db $00, $00, $00, $74, $07, $02
Sfx1_78_Data_5720:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_5726:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_572C:
	db $00, $00, $00, $14, $07, $02
Sfx1_78_Data_5732:
	db $00, $00, $42, $74, $87, $02
Sfx1_78_Data_5738:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_573E:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_5744:
	db $00, $00, $00, $14, $07, $02
Sfx1_78_Data_574A:
	db $00, $00, $22, $74, $87, $02
Sfx1_78_Data_5750:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_5756:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_575C:
	db $00, $00, $00, $14, $07, $02
Sfx2_Dummy_Init:
	ld hl, Sfx2_Dummy_Data_577A
	jp Sfx2_Start

Sfx2_Dummy_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx2_Stop
	ld hl, Sfx2_Dummy_Data_577F
	jp Sfx2_WritePeriod

Sfx2_Dummy_Data_577A:
	db $80, $b4, $7b, $87, $05
Sfx2_Dummy_Data_577F:
	db $9d, $07, $30
Sfx2_25_Init:
	ld a, [wSfx1Playing]
	cp $77
	call z, Sfx1_StopSilent
	ld hl, Sfx2_25_Data_57EF
	jp Sfx2_Start

Sfx2_25_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $26
	jp z, Sfx2_StopWithRegs
	ld hl, Sfx2_25_Data_57A5
	call GetPointer
	jp SetRegs_Ch2

Sfx2_25_Data_57A5:
	dw Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_57EF, Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_5803, Sfx2_25_Data_5808, Sfx2_25_Data_580D, Sfx2_25_Data_5812, Sfx2_25_Data_5817, Sfx2_25_Data_57EF, Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_57EF, Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_5803, Sfx2_25_Data_5808, Sfx2_25_Data_580D, Sfx2_25_Data_5812, Sfx2_25_Data_5817, Sfx2_25_Data_57EF, Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_57EF, Sfx2_25_Data_57F4, Sfx2_25_Data_57F9, Sfx2_25_Data_57FE, Sfx2_25_Data_5803, Sfx2_25_Data_5808, Sfx2_25_Data_580D, Sfx2_25_Data_5812
Sfx2_25_Data_57EF:
	db $80, $b8, $9d, $87, $01
Sfx2_25_Data_57F4:
	db $80, $b8, $6b, $87, $01
Sfx2_25_Data_57F9:
	db $80, $b8, $21, $87, $01
Sfx2_25_Data_57FE:
	db $80, $b8, $b2, $86, $01
Sfx2_25_Data_5803:
	db $80, $b8, $0a, $86, $01
Sfx2_25_Data_5808:
	db $80, $b8, $ac, $85, $01
Sfx2_25_Data_580D:
	db $80, $b8, $e5, $84, $01
Sfx2_25_Data_5812:
	db $80, $b8, $9b, $83, $01
Sfx2_25_Data_5817:
	db $80, $11, $9b, $83, $04
Sfx2_26_Init:
	ld hl, Sfx2_26_Data_585A
	jp Sfx2_Start

Sfx2_26_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx2_StopWithRegs
	ld hl, Sfx2_26_Data_5837
	call GetPointer
	jp SetRegs_Ch2

Sfx2_26_Data_5837:
	db $5a, $58, $6e, $58, $73
	db $58, $5f, $58, $5f, $58
	db $73, $58, $78, $58, $64
	db $58, $64, $58, $78, $58
	db $7d, $58, $69, $58, $69
	db $58, $7d, $58, $82, $58
	db $80, $08, $00, $86, $02
Sfx2_26_Data_585A:
	db $80, $c8, $0a, $86, $02
Sfx2_27_Data_585F:
	db $80, $c8, $27, $86, $02
Sfx2_27_Data_5864:
	db $80, $c8, $42, $86, $02
Sfx2_27_Data_5869:
	db $80, $c8, $5b, $86, $02
Sfx2_27_Data_586E:
	db $80, $c8, $b2, $86, $02
Sfx2_27_Data_5873:
	db $80, $c8, $c4, $86, $02
Sfx2_27_Data_5878:
	db $80, $c8, $d6, $86, $02
Sfx2_27_Data_587D:
	db $80, $c8, $e7, $86, $02
Sfx2_27_Data_5882:
	db $80, $c8, $f7, $86, $02
Sfx2_27_Data_5887:
	db $80, $c8, $72, $86, $02
Sfx2_27_Data_588C:
	db $80, $c8, $89, $86, $02
Sfx2_27_Data_5891:
	db $80, $c8, $9e, $86, $02
Sfx2_27_Data_5896:
	db $80, $c8, $b2, $86, $02
Sfx2_27_Data_589B:
	db $80, $c8, $06, $87, $02
Sfx2_27_Data_58A0:
	db $80, $c8, $14, $87, $02
Sfx2_27_Data_58A5:
	db $80, $c8, $21, $87, $02
Sfx2_27_Data_58AA:
	db $80, $c8, $2d, $87, $02
Sfx2_27_Init:
	ld hl, Sfx2_26_Data_585A
	jp Sfx2_Start

Sfx2_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $20
	jp z, Sfx2_StopWithRegs
	ld hl, Sfx2_27_Data_58CA
	call GetPointer
	jp SetRegs_Ch2

Sfx2_27_Data_58CA:
	dw Sfx2_26_Data_585A, Sfx2_27_Data_586E, Sfx2_27_Data_5873, Sfx2_27_Data_585F, Sfx2_27_Data_585F, Sfx2_27_Data_5873, Sfx2_27_Data_5878, Sfx2_27_Data_5864, Sfx2_27_Data_5864, Sfx2_27_Data_5878, Sfx2_27_Data_587D, Sfx2_27_Data_5869, Sfx2_27_Data_5869, Sfx2_27_Data_587D, Sfx2_27_Data_5882, Sfx2_27_Data_5887, Sfx2_27_Data_5887, Sfx2_27_Data_5882, Sfx2_27_Data_589B, Sfx2_27_Data_588C, Sfx2_27_Data_588C, Sfx2_27_Data_589B, Sfx2_27_Data_58A0, Sfx2_27_Data_5891, Sfx2_27_Data_5891, Sfx2_27_Data_58A0, Sfx2_27_Data_58A5, Sfx2_27_Data_5896, Sfx2_27_Data_5896, Sfx2_27_Data_58A5, Sfx2_27_Data_58AA
Sfx2_28_Init:
	ld hl, Sfx2_28_Data_595F
	jp Sfx2_Start

Sfx2_28_Play:
	call Sfx_DecTimer
	jp z, Sfx2_StopWithRegs
	cpl
	add a, $37
	srl a
	ret c
	ld hl, Sfx2_28_Data_592B
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	ldh [rNR24], a
	ld a, $40
	ldh [rNR21], a
	ret

Sfx2_28_Data_592B:
	db $b2, $06, $06, $07, $39, $07, $59, $07, $83, $07, $59, $07, $c4, $06, $06, $07
	db $2d, $07, $62, $07, $2d, $07, $62, $07, $83, $07, $97, $07, $b1, $07, $97, $07
	db $e7, $06, $21, $07, $44, $07, $74, $07, $44, $07, $74, $07, $90, $07, $a2, $07
	db $ba, $07, $a2, $07
Sfx2_28_Data_595F:
	db $40, $e8, $06, $87, $36
Sfx2_29_Init:
	ld hl, Sfx2_29_Data_5989
	jp Sfx2_StartPriority

Sfx2_29_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx2_Stop
	ld hl, Sfx2_29_Data_597F
	call GetPointer
	jp SetRegs_Ch2

Sfx2_29_Data_597F:
	dw Sfx2_29_Data_598E, Sfx2_29_Data_5993, Sfx2_29_Data_5998, Sfx2_29_Data_599D, Sfx2_29_Data_59A2
Sfx2_29_Data_5989:
	db $98, $f1, $9d, $c7, $08
Sfx2_29_Data_598E:
	db $98, $f1, $ac, $c7, $08
Sfx2_29_Data_5993:
	db $98, $f1, $ce, $c7, $08
Sfx2_29_Data_5998:
	db $98, $f1, $c1, $c7, $08
Sfx2_29_Data_599D:
	db $98, $f1, $c8, $c7, $08
Sfx2_29_Data_59A2:
	db $98, $f1, $d6, $c7, $08
Sfx2_2F_Init:
	ld hl, Sfx2_2F_Data_59CC
	jp Sfx2_Start

Sfx2_2F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx2_Stop
	ld hl, Sfx2_2F_Data_59C2
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2F_Data_59C2:
	dw Sfx2_2F_Data_59D1, Sfx2_2F_Data_59D6, Sfx2_2F_Data_59DB, Sfx2_2F_Data_59E0, Sfx2_2F_Data_59E5
Sfx2_2F_Data_59CC:
	db $80, $a3, $9d, $87, $05
Sfx2_2F_Data_59D1:
	db $80, $a3, $83, $87, $0c
Sfx2_2F_Data_59D6:
	db $80, $63, $9d, $87, $05
Sfx2_2F_Data_59DB:
	db $80, $63, $83, $87, $0c
Sfx2_2F_Data_59E0:
	db $80, $43, $9d, $87, $05
Sfx2_2F_Data_59E5:
	db $80, $43, $83, $87, $0c
Sfx2_30_Init:
	ld hl, Sfx2_30_Data_5A18
	jp Sfx2_Start

Sfx2_30_Play:
	call Sfx_DecTimer
	jr nz, .l0
	call Sfx_IncStep
	cp $03
	jp z, Sfx2_StopWithRegs
	ld hl, Sfx2_30_Data_5A14
	call GetPointer
	jp SetRegs_Ch2

.l0:
	and $01
	jr nz, .l1
	ld a, $12
	ldh [rNR23], a
	ret

.l1:
	ld a, $9b
	ldh [rNR23], a
	ret

Sfx2_30_Data_5A14:
	dw Sfx2_30_Data_5A1D, Sfx2_30_Data_5A22
Sfx2_30_Data_5A18:
	db $00, $ff, $12, $83, $06
Sfx2_30_Data_5A1D:
	db $00, $11, $12, $83, $03
Sfx2_30_Data_5A22:
	db $00, $ff, $12, $83, $14
Sfx2_31_Init:
	ld hl, Sfx2_31_Data_5A48
	jp Sfx2_Start

Sfx2_31_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx2_Stop
	ld hl, Sfx2_31_Data_5A42
	call GetPointer
	jp SetRegs_Ch2

Sfx2_31_Data_5A42:
	dw Sfx2_31_Data_5A4D, Sfx2_31_Data_5A52, Sfx2_31_Data_5A57
Sfx2_31_Data_5A48:
	db $80, $f1, $9d, $87, $06
Sfx2_31_Data_5A4D:
	db $80, $f1, $83, $87, $06
Sfx2_31_Data_5A52:
	db $80, $f1, $9d, $87, $06
Sfx2_31_Data_5A57:
	db $80, $f1, $83, $87, $18
Sfx4_41_Init:
	ld hl, Sfx4_41_Data_5A9A
	jp Sfx4_Start

Sfx4_41_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_41_Data_5A77
	call GetPointer
	jp SetRegs_Ch4

Sfx4_41_Data_5A77:
	db $9f, $5a, $a4, $5a, $a9
	db $5a, $ae, $5a, $b3, $5a
	db $b8, $5a, $bd, $5a, $c2
	db $5a, $c7, $5a, $cc, $5a
	db $d1, $5a, $d6, $5a, $db
	db $5a, $e0, $5a, $e5, $5a
	db $3b, $08, $00, $c0, $02
Sfx4_41_Data_5A9A:
	db $3b, $f8, $37, $c0, $02
Sfx4_41_Data_5A9F:
	db $3b, $f8, $15, $c0, $02
Sfx4_41_Data_5AA4:
	db $3b, $f8, $45, $c0, $02
Sfx4_41_Data_5AA9:
	db $3b, $f8, $24, $c0, $02
Sfx4_41_Data_5AAE:
	db $3b, $f8, $45, $c0, $02
Sfx4_41_Data_5AB3:
	db $3b, $e8, $01, $c0, $02
Sfx4_41_Data_5AB8:
	db $3b, $c8, $26, $c0, $02
Sfx4_41_Data_5ABD:
	db $3b, $c8, $27, $c0, $02
Sfx4_41_Data_5AC2:
	db $3b, $b8, $55, $c0, $02
Sfx4_41_Data_5AC7:
	db $3b, $b8, $37, $c0, $02
Sfx4_41_Data_5ACC:
	db $3b, $a8, $15, $c0, $02
Sfx4_41_Data_5AD1:
	db $3b, $98, $34, $c0, $02
Sfx4_41_Data_5AD6:
	db $3b, $98, $45, $c0, $02
Sfx4_41_Data_5ADB:
	db $3b, $88, $47, $c0, $02
Sfx4_41_Data_5AE0:
	db $3b, $78, $47, $c0, $02
Sfx4_41_Data_5AE5:
	db $3b, $78, $01, $c0, $02
Sfx4_42_Init:
	ld hl, Sfx4_42_Data_5B09
	jp Sfx4_Start

Sfx4_42_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_42_Data_5B05
	call GetPointer
	jp SetRegs_Ch4

Sfx4_42_Data_5B05:
	dw Sfx4_42_Data_5B0E, Sfx4_42_Data_5B13
Sfx4_42_Data_5B09:
	db $00, $ab, $65, $80, $12
Sfx4_42_Data_5B0E:
	db $00, $f8, $65, $80, $12
Sfx4_42_Data_5B13:
	db $00, $e4, $75, $80, $26
Sfx1_4F_Init:
	ld hl, Sfx1_4F_Data_5B25
	jp Sfx1_Start

Sfx1_4F_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_4F_Data_5B25:
	db $3f, $40, $b2, $d6, $86, $14
Sfx1_50_Init:
	ld hl, Sfx1_50_Data_5B58
	jp Sfx1_Start

Sfx1_50_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_50_Data_5B46
	call GetPointer
	jp SetRegs_Ch1

Sfx1_50_Data_5B46:
	dw Sfx1_50_Data_5B76, Sfx1_50_Data_5B5E, Sfx1_50_Data_5B7C, Sfx1_50_Data_5B64, Sfx1_50_Data_5B82, Sfx1_50_Data_5B6A, Sfx1_50_Data_5B88, Sfx1_50_Data_5B70, Sfx1_50_Data_5B8E
Sfx1_50_Data_5B58:
	db $08, $80, $91, $e5, $84, $02
Sfx1_50_Data_5B5E:
	db $08, $80, $91, $3b, $85, $02
Sfx1_50_Data_5B64:
	db $08, $80, $91, $89, $85, $02
Sfx1_50_Data_5B6A:
	db $08, $80, $91, $ce, $85, $02
Sfx1_50_Data_5B70:
	db $08, $80, $91, $0a, $86, $02
Sfx1_50_Data_5B76:
	db $08, $80, $21, $e5, $84, $02
Sfx1_50_Data_5B7C:
	db $08, $80, $21, $3b, $85, $02
Sfx1_50_Data_5B82:
	db $08, $80, $21, $89, $85, $02
Sfx1_50_Data_5B88:
	db $08, $80, $21, $ce, $85, $02
Sfx1_50_Data_5B8E:
	db $08, $80, $21, $0a, $86, $02
Sfx1_51_Init:
	ld hl, Sfx1_51_Data_5BF5
	jp Sfx1_Start

Sfx1_51_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $24
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_51_Data_5BAF
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_51_Data_5BAF:
	dw Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A, Sfx1_51_Data_5BFB, Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A, Sfx1_51_Data_5BFB, Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A, Sfx1_51_Data_5BFB, Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A, Sfx1_51_Data_5BFB, Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A, Sfx1_51_Data_5BFB, Sfx1_51_Data_5BFE, Sfx1_51_Data_5C01, Sfx1_51_Data_5C04, Sfx1_51_Data_5C07, Sfx1_51_Data_5C0A
Sfx1_51_Data_5BF5:
	db $08, $80, $88, $83, $87, $01
Sfx1_51_Data_5BFB:
	db $83, $07, $01
Sfx1_51_Data_5BFE:
	db $8a, $07, $01
Sfx1_51_Data_5C01:
	db $90, $07, $01
Sfx1_51_Data_5C04:
	db $97, $07, $01
Sfx1_51_Data_5C07:
	db $90, $07, $01
Sfx1_51_Data_5C0A:
	db $8a, $07, $01
Sfx1_52_Init:
	ld hl, Sfx1_52_Data_5C20
	jp Sfx1_Start

Sfx1_52_Play:
	call Sfx_DecTimer
	jp z, Sfx1_Stop
	cpl
	inc a
	add a, $64
	ldh [rNR13], a
	ret

Sfx1_52_Data_5C20:
	db $08, $40, $c2, $44, $87, $20
Sfx1_53_Init:
	ld hl, Sfx1_53_Data_5C80
	jp Sfx1_StartPriority

Sfx1_53_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0e
	jp z, Sfx1_Stop
	push af
	ld hl, Sfx1_53_Data_5C66
	call GetPointer
	ld a, l
	ldh [rNR11], a
	pop af
	ld hl, Sfx1_53_Data_5C4C
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_53_Data_5C4C:
	dw Sfx1_53_Data_5C86, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C, Sfx1_53_Data_5C89, Sfx1_53_Data_5C8C
Sfx1_53_Data_5C66:
	db $80, $00, $40, $00, $80, $00, $40, $00, $80, $00, $40, $00, $80, $00, $40, $00
	db $80, $00, $40, $00, $80, $00, $40, $00, $80, $00
Sfx1_53_Data_5C80:
	db $08, $80, $a3, $7b, $87, $03
Sfx1_53_Data_5C86:
	db $9d, $07, $04
Sfx1_53_Data_5C89:
	db $9d, $07, $01
Sfx1_53_Data_5C8C:
	db $9d, $07, $03
Sfx1_54_Init:
	ld hl, Sfx1_54_Data_5CC8
	jp Sfx1_StartPriority

Sfx1_54_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_54_Data_5CAA
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_54_Data_5CAA:
	dw Sfx1_54_Data_5CCE, Sfx1_54_Data_5CD1, Sfx1_54_Data_5CD4, Sfx1_54_Data_5CD7, Sfx1_54_Data_5CDA, Sfx1_54_Data_5CDD, Sfx1_54_Data_5CE0, Sfx1_54_Data_5CE3, Sfx1_54_Data_5CE6, Sfx1_54_Data_5CE9, Sfx1_54_Data_5CEC, Sfx1_54_Data_5CEF, Sfx1_54_Data_5CF2, Sfx1_54_Data_5CF5, Sfx1_54_Data_5CF8
Sfx1_54_Data_5CC8:
	db $08, $80, $a2, $72, $86, $01
Sfx1_54_Data_5CCE:
	db $b2, $06, $01
Sfx1_54_Data_5CD1:
	db $f7, $06, $01
Sfx1_54_Data_5CD4:
	db $d6, $06, $01
Sfx1_54_Data_5CD7:
	db $e7, $06, $01
Sfx1_54_Data_5CDA:
	db $f7, $06, $01
Sfx1_54_Data_5CDD:
	db $2d, $07, $01
Sfx1_54_Data_5CE0:
	db $14, $07, $01
Sfx1_54_Data_5CE3:
	db $21, $07, $01
Sfx1_54_Data_5CE6:
	db $2d, $07, $01
Sfx1_54_Data_5CE9:
	db $59, $07, $01
Sfx1_54_Data_5CEC:
	db $44, $07, $01
Sfx1_54_Data_5CEF:
	db $4f, $07, $01
Sfx1_54_Data_5CF2:
	db $59, $07, $01
Sfx1_54_Data_5CF5:
	db $7b, $07, $01
Sfx1_54_Data_5CF8:
	db $6b, $07, $01
Sfx1_55_Init:
	ld hl, Sfx1_55_Data_5D5E
	jp Sfx1_StartPriority

Sfx1_55_Play:
	call Sfx_DecTimer
	jp z, Sfx1_StopSilent
	cpl
	add a, $1e
	ld d, $00
	cp $0f
	jr nz, .l0
	ld a, $82
	ldh [rNR12], a
	ld a, $15
	ld d, $80
.l0:
	ld hl, Sfx1_55_Data_5D26
	call GetPointer
	ld a, l
	ldh [rNR13], a
	ld a, h
	or d
	ldh [rNR14], a
	ret

Sfx1_55_Data_5D26:
	db $f7, $06, $c4, $06, $d6, $06, $f7, $06, $d6, $06, $9e, $06, $b2, $06, $d6, $06
	db $b2, $06, $72, $06, $89, $06, $b2, $06, $89, $06, $42, $06, $5b, $06, $89, $06
	db $5b, $06, $0a, $06, $27, $06, $5b, $06, $27, $06, $ce, $05, $ed, $05, $27, $06
	db $ce, $05, $63, $05, $ac, $05, $ce, $05
Sfx1_55_Data_5D5E:
	db $08, $80, $a8, $06, $87, $1d
Sfx1_56_Init:
	ld hl, Sfx1_56_Data_5E5F
	jp Sfx1_StartPriority2

Sfx1_56_Play:
	call Sfx_DecTimer
	jp z, Sfx1_StopSilent
	cpl
	add a, $6a
	ld d, $00
	cp $61
	jr nz, .l0
	ld a, $82
	ldh [rNR12], a
	ld a, $61
	ld d, $80
.l0:
	ld hl, Sfx1_56_Data_5D8F
	call GetPointer
	ld a, l
	ldh [rNR13], a
	ld a, h
	or d
	ldh [rNR14], a
	ret

Sfx1_56_Data_5D8F:
	db $4f, $07, $2d, $07, $39, $07, $44, $07, $2d, $07, $06, $07, $14, $07, $21, $07
	db $06, $07, $d6, $06, $e7, $06, $f7, $06, $d6, $06, $9e, $06, $b2, $06, $c4, $06
	db $9e, $06, $5b, $06, $72, $06, $89, $06, $5b, $06, $0a, $06, $27, $06, $42, $06
	db $0a, $06, $ac, $05, $ce, $05, $ed, $05, $ac, $05, $3b, $05, $63, $05, $ac, $05
	db $89, $05, $ed, $05, $0a, $06, $42, $06, $0a, $06, $ce, $05, $ed, $05, $0a, $06
	db $ce, $05, $89, $05, $ac, $05, $ce, $05, $89, $05, $3b, $05, $63, $05, $89, $05
	db $3b, $05, $e5, $04, $11, $05, $3b, $05, $e5, $04, $83, $04, $b5, $04, $e5, $04
	db $83, $04, $16, $04, $4e, $04, $83, $04, $16, $04, $9b, $03, $da, $03, $83, $04
	db $4e, $04, $e5, $04, $11, $05, $63, $05, $3b, $05, $ac, $05, $ce, $05, $0a, $06
	db $ed, $05, $42, $06, $5b, $06, $89, $06, $72, $06, $b2, $06, $c4, $06, $e7, $06
	db $d6, $06, $06, $07, $14, $07, $2d, $07, $21, $07, $44, $07, $4f, $07, $62, $07
	db $59, $07, $74, $07, $7b, $07, $8a, $07, $83, $07, $97, $07, $9d, $07, $a7, $07
	db $a2, $07, $b1, $07, $b6, $07, $be, $07, $ba, $07, $c5, $07, $c8, $07, $ce, $07
Sfx1_56_Data_5E5F:
	db $08, $80, $a8, $59, $87, $69
Sfx1_57_Init:
	ld hl, Sfx1_57_Data_5E7D
	jp Sfx1_Start

Sfx1_57_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_57_Data_5E83
	jp SetRegs_Ch1

Sfx1_57_Data_5E7D:
	db $3f, $80, $58, $0a, $86, $05
Sfx1_57_Data_5E83:
	db $3f, $80, $83, $b2, $86, $17
Sfx1_58_Init:
	ld hl, Sfx1_58_Data_5EC6
	jp Sfx1_StartPriority

Sfx1_58_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_58_Data_5EA4
	call GetPointer
	jp SetRegs_Ch1

Sfx1_58_Data_5EA4:
	dw Sfx1_58_Data_5ECC, Sfx1_58_Data_5ED2, Sfx1_58_Data_5ED8, Sfx1_58_Data_5EDE, Sfx1_58_Data_5EE4, Sfx1_58_Data_5F0B, Sfx1_58_Data_5EEA, Sfx1_58_Data_5F11, Sfx1_58_Data_5EF0, Sfx1_58_Data_5F17, Sfx1_58_Data_5EF6, Sfx1_58_Data_5F17, Sfx1_58_Data_5EFC, Sfx1_58_Data_5F1D, Sfx1_58_Data_5F02, Sfx1_58_Data_5F1D, Sfx1_58_Data_5F08
Sfx1_58_Data_5EC6:
	db $2c, $80, $a8, $06, $87, $08
Sfx1_58_Data_5ECC:
	db $2c, $80, $a8, $e7, $86, $08
Sfx1_58_Data_5ED2:
	db $2c, $80, $a8, $9e, $86, $08
Sfx1_58_Data_5ED8:
	db $2c, $80, $a8, $5b, $86, $08
Sfx1_58_Data_5EDE:
	db $2b, $80, $a8, $5b, $86, $08
Sfx1_58_Data_5EE4:
	db $2b, $80, $a8, $0a, $86, $07
Sfx1_58_Data_5EEA:
	db $2b, $80, $a8, $89, $85, $06
Sfx1_58_Data_5EF0:
	db $2b, $80, $a8, $e5, $84, $05
Sfx1_58_Data_5EF6:
	db $2b, $80, $a8, $e5, $84, $05
Sfx1_58_Data_5EFC:
	db $2b, $80, $a4, $9b, $83, $04
Sfx1_58_Data_5F02:
	db $2b, $80, $82, $9b, $83, $04
Sfx1_58_Data_5F08:
	db $2b, $80, $42
Sfx1_58_Data_5F0B:
	db $2b, $80, $11, $0a, $85, $01
Sfx1_58_Data_5F11:
	db $2b, $80, $11, $0a, $85, $02
Sfx1_58_Data_5F17:
	db $2b, $80, $11, $0a, $85, $03
Sfx1_58_Data_5F1D:
	db $2b, $80, $11, $0a, $85, $04
Sfx1_59_Init:
	ld hl, Sfx1_59_Data_5F9E
	jp Sfx1_StartPriority

Sfx1_59_Play:
	call Sfx_DecTimer
	jp z, Sfx1_StopSilent
	cpl
	add a, $29
	ld d, $00
	cp $16
	call z, .l0
	ld hl, Sfx1_59_Data_5F50
	call GetPointer
	ld a, l
	ldh [rNR13], a
	ld a, h
	or d
	ldh [rNR14], a
	ret

.l0:
	ld a, $92
	ldh [rNR12], a
	ld d, $80
	ld a, $16
	ret

Sfx1_59_Data_5F50:
	db $83, $04, $42, $06, $42, $06, $83, $04, $63, $05, $b2, $06, $b2, $06, $63, $05
	db $0a, $06, $06, $07, $06, $07, $0a, $06, $89, $06, $44, $07, $44, $07, $89, $06
	db $e7, $06, $74, $07, $74, $07, $e7, $06, $2d, $07, $97, $07, $97, $07, $2d, $07
	db $62, $07, $b1, $07, $b1, $07, $62, $07, $8a, $07, $c5, $07, $c5, $07, $8a, $07
	db $a7, $07, $d4, $07, $d4, $07, $a7, $07, $be, $07, $df, $07, $df, $07
Sfx1_59_Data_5F9E:
	db $08, $80, $a8, $56, $82, $28
Sfx1_5A_Init:
	ld hl, Sfx1_5A_Data_5FB1
	jp Sfx1_StartPriority

Sfx1_5A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_5A_Data_5FB1:
	db $08, $80, $a3, $b2, $86, $1c
Sfx1_5B_Init:
	call Sfx2_StopWithRegs
	call Sfx4_StopWithRegs
	ld a, [wSongPlaying]
	ld [wPausedSong], a
	xor a
	ld [wSongPlaying], a
	ld [wChannelsPlayed], a
	ldh [rNR32], a
	jp Sfx1_StopSilent

Sfx1_5B_Play:
	jp Sfx1_Stop

; unreferenced
Unused_5FD2:
	db $08
Sfx2_2E_Data_5FD3:
	db $80, $b3, $83, $87, $05
	db $08
Sfx2_2E_Data_5FD9:
	db $80, $b3, $59, $87, $05
	db $08
Sfx2_2E_Data_5FDF:
	db $80, $b3, $59, $87, $0a
Sfx1_5C_Init:
	ld a, [wPausedSong]
	ld [wSongPlaying], a
	jp Sfx1_Stop

Sfx1_5C_Play:
	jp Sfx1_Stop

Sfx1_5D_Init:
	ld hl, Sfx1_5D_Data_604D
	jp Sfx1_StartPriority2

Sfx1_5D_Play:
	call Sfx_DecTimer
	jp z, Sfx1_StopWithRegs
	cpl
	add a, $0e
	ld d, a
	ld hl, Sfx1_5D_Data_6035
	call GetPointer
	ld a, l
	ldh [rNR12], a
	ld a, $27
	ldh [rNR10], a
	ld a, d
	ld hl, Sfx1_5D_Data_601D
	call GetPointer
	ld a, l
	ldh [rNR13], a
	ld a, h
	or $80
	ldh [rNR14], a
	ret

Sfx1_5D_Data_601D:
	db $59, $07, $59, $07, $a2, $07, $83, $07, $ba, $07, $a2, $07, $cb, $07, $b6, $07
	db $d9, $07, $c8, $07, $e0, $07, $d6, $07
Sfx1_5D_Data_6035:
	db $c8, $00, $b8, $00, $a8, $00, $98, $00, $88, $00, $78, $00, $68, $00, $58, $00
	db $48, $00, $38, $00, $28, $00, $18, $00
Sfx1_5D_Data_604D:
	db $27, $80, $d8, $21, $87, $0d
Sfx1_5E_Init:
	ld hl, Sfx1_5E_Data_6088
	jp Sfx1_StartPriority2

Sfx1_5E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0e
	jp z, Sfx1_Stop
	ld hl, Sfx1_5E_Data_606E
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5E_Data_606E:
	dw Sfx1_5E_Data_608E, Sfx1_5E_Data_6094, Sfx1_5E_Data_609A, Sfx1_5E_Data_60A0, Sfx1_5E_Data_60A6, Sfx1_5E_Data_60AC, Sfx1_5E_Data_60B2, Sfx1_5E_Data_60B8, Sfx1_5E_Data_60BE, Sfx1_5E_Data_60C4, Sfx1_5E_Data_60CA, Sfx1_5E_Data_60D0, Sfx1_5E_Data_60D6
Sfx1_5E_Data_6088:
	db $16, $80, $b3, $f7, $86, $04
Sfx1_5E_Data_608E:
	db $16, $80, $b3, $e7, $86, $04
Sfx1_5E_Data_6094:
	db $16, $80, $b3, $d6, $86, $04
Sfx1_5E_Data_609A:
	db $16, $80, $b3, $b2, $86, $04
Sfx1_5E_Data_60A0:
	db $16, $80, $b3, $9e, $86, $04
Sfx1_5E_Data_60A6:
	db $16, $80, $b3, $89, $86, $04
Sfx1_5E_Data_60AC:
	db $16, $80, $b3, $72, $86, $04
Sfx1_5E_Data_60B2:
	db $16, $80, $b2, $5b, $86, $04
Sfx1_5E_Data_60B8:
	db $16, $80, $a2, $27, $86, $04
Sfx1_5E_Data_60BE:
	db $16, $80, $82, $0a, $86, $04
Sfx1_5E_Data_60C4:
	db $16, $80, $62, $ed, $85, $04
Sfx1_5E_Data_60CA:
	db $16, $80, $42, $ce, $85, $04
Sfx1_5E_Data_60D0:
	db $16, $80, $22, $ac, $85, $04
Sfx1_5E_Data_60D6:
	db $16, $80, $12, $63, $85, $04
Sfx2_2A_Init:
	ld a, [wSfx2Playing]
	cp $2a
	ret z
	ld a, [wDED3]
	inc a
	and $07
	ld [wDED3], a
	inc a
	ld hl, Sfx2_2A_Data_60F5
	call GetPointer
	jp Sfx2_Start

Sfx2_2A_Data_60F5:
	dw Sfx2_2A_Data_610C, Sfx2_2A_Data_6111, Sfx2_2A_Data_610C, Sfx2_2A_Data_6111, Sfx2_2A_Data_610C, Sfx2_2A_Data_6111, Sfx2_2A_Data_6116, Sfx2_2A_Data_6111
Sfx2_2A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx2_Stop

Sfx2_2A_Data_610C:
	db $b8, $52, $b2, $c6, $03
Sfx2_2A_Data_6111:
	db $b8, $52, $72, $c6, $03
Sfx2_2A_Data_6116:
	db $b8, $52, $0a, $c6, $03
Sfx2_2B_Init:
	ld hl, Sfx2_2B_Data_613F
	jp Sfx2_StartPriority

Sfx2_2B_Play:
	call Sfx_DecTimer
	jp z, Sfx2_StopWithRegs
	cpl
	add a, $06
	ld hl, Sfx2_2B_Data_6137
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	ldh [rNR24], a
	ret

Sfx2_2B_Data_6137:
	db $74, $07, $6b, $07, $7b, $07, $8a, $07
Sfx2_2B_Data_613F:
	db $80, $91, $83, $87, $05
Sfx2_2C_Init:
	ld hl, Sfx2_2C_Data_619F
	jp Sfx2_StartPriority2

Sfx2_2C_Play:
	call Sfx_DecTimer
	jp z, Sfx2_StopWithRegs
	cpl
	add a, $11
	ld d, $00
	cp $0a
	jr z, .l0
	cp $02
	jr nz, .l1
	ld a, $88
	ldh [rNR22], a
	ld a, $02
	ld d, $80
	jr .l1

.l0:
	ld a, $80
	ldh [rNR21], a
	ld a, $71
	ldh [rNR22], a
	ld a, $0a
	ld d, $80
.l1:
	ld hl, Sfx2_2C_Data_6181
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	or d
	ldh [rNR24], a
	ret

Sfx2_2C_Data_6181:
	db $3b, $05, $89, $05, $ce, $05, $0a, $06, $42, $06, $72, $06, $b2, $06, $e7, $06
	db $06, $07, $21, $07, $39, $07, $59, $07, $6b, $07, $83, $07, $90, $07
Sfx2_2C_Data_619F:
	db $80, $88, $e5, $84, $10
Sfx2_2D_Init:
	ld hl, Sfx2_2D_Data_61E3
	jp Sfx2_StartPriority3

Sfx2_2D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $13
	jp z, Sfx2_StopWithRegs
	ld hl, Sfx2_2D_Data_61BF
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2D_Data_61BF:
	dw Sfx2_2D_Data_61E8, Sfx2_2D_Data_61ED, Sfx2_2D_Data_61F2, Sfx2_2D_Data_61F7, Sfx2_2D_Data_61FC, Sfx2_2D_Data_621F, Sfx2_2D_Data_61E3, Sfx2_2D_Data_61E8, Sfx2_2D_Data_61ED, Sfx2_2D_Data_61F2, Sfx2_2D_Data_61F7, Sfx2_2D_Data_61FC, Sfx2_2D_Data_6201, Sfx2_2D_Data_6206, Sfx2_2D_Data_620B, Sfx2_2D_Data_6210, Sfx2_2D_Data_6215, Sfx2_2D_Data_621A
Sfx2_2D_Data_61E3:
	db $80, $f8, $16, $84, $01
Sfx2_2D_Data_61E8:
	db $80, $f8, $da, $83, $01
Sfx2_2D_Data_61ED:
	db $80, $e8, $9b, $83, $01
Sfx2_2D_Data_61F2:
	db $80, $e8, $12, $83, $01
Sfx2_2D_Data_61F7:
	db $80, $d8, $c6, $82, $01
Sfx2_2D_Data_61FC:
	db $80, $d8, $92, $82, $01
Sfx2_2D_Data_6201:
	db $80, $c8, $77, $82, $01
Sfx2_2D_Data_6206:
	db $80, $b8, $c9, $81, $01
Sfx2_2D_Data_620B:
	db $80, $a8, $6b, $81, $01
Sfx2_2D_Data_6210:
	db $80, $98, $06, $81, $01
Sfx2_2D_Data_6215:
	db $80, $88, $bf, $80, $01
Sfx2_2D_Data_621A:
	db $80, $78, $9c, $80, $01
Sfx2_2D_Data_621F:
	db $80, $18, $77, $82, $01
Sfx2_2E_Init:
	ld hl, Sfx2_2E_Data_5FD3
	jp Sfx2_StartPriority4

Sfx2_2E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx2_Stop
	ld hl, Sfx2_2E_Data_623F
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2E_Data_623F:
	dw Sfx2_2E_Data_5FD9, Sfx2_2E_Data_5FD3, Sfx2_2E_Data_5FD9, Sfx2_2E_Data_5FD3, Sfx2_2E_Data_5FD9, Sfx2_2E_Data_5FD3, Sfx2_2E_Data_5FDF
Sfx2_34_Init:
	jp Sfx2_3B_Init

Sfx2_34_Play:
	jp Sfx2_3B_Play

Sfx2_35_Init:
	jp Sfx2_3C_Init

Sfx2_35_Play:
	jp Sfx2_3C_Play

; unreferenced
Unused_6259:
	ret

Sfx2_36_Init:
	ld hl, Sfx2_36_Data_6281
	jp Sfx2_Start

Sfx2_36_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx2_Stop
	ld hl, Sfx2_36_Data_6275
	call GetPointer
	jp SetRegs_Ch2

Sfx2_36_Data_6275:
	dw Sfx2_36_Data_6286, Sfx2_36_Data_628B, Sfx2_36_Data_6290, Sfx2_36_Data_6295, Sfx2_36_Data_629A, Sfx2_36_Data_629F
Sfx2_36_Data_6281:
	db $b4, $d1, $06, $c7, $04
Sfx2_36_Data_6286:
	db $b4, $b1, $39, $c7, $04
Sfx2_36_Data_628B:
	db $b4, $91, $59, $c7, $04
Sfx2_36_Data_6290:
	db $b4, $71, $7b, $c7, $05
Sfx2_36_Data_6295:
	db $b4, $61, $90, $c7, $05
Sfx2_36_Data_629A:
	db $b4, $51, $a7, $c7, $06
Sfx2_36_Data_629F:
	db $b4, $41, $b6, $c7, $05
Sfx2_37_Init:
	call Sound_Stop
	ld hl, Sfx2_37_Data_62F7
	jp Sfx2_Start

Sfx2_37_Play:
	call Sfx_DecTimer
	jp z, Sfx2_Stop
	ld d, $00
	cpl
	add a, $2d
	cp $04
	jr z, .l0
	cp $07
	jr z, .l1
	cp $24
	jr z, .l2
.l3:
	and $01
	inc a
	ld hl, Sfx2_37_Data_62F3
	call GetPointer
	ld a, l
	ldh [rNR23], a
	ld a, h
	or d
	ldh [rNR24], a
	ret

.l1:
	ld d, a
	ld a, $c8
	ldh [rNR22], a
	ld a, d
	ld d, $80
	jr .l3

.l0:
	ld d, a
	ld a, $11
	ldh [rNR22], a
	ld a, d
	ld d, $80
	jr .l3

.l2:
	ld d, a
	ld a, $17
	ldh [rNR22], a
	ld a, d
	ld d, $80
	jr .l3

Sfx2_37_Data_62F3:
	db $b6, $07, $be, $07
Sfx2_37_Data_62F7:
	db $40, $c8, $b6, $87, $2c
Sfx2_38_Init:
	ld hl, Sfx2_38_Data_6302
	jp Sfx2_34_Shared_643C

Sfx2_38_Data_6302:
	db $80, $f1, $f7, $86, $03
Sfx2_38_Play:
	ld hl, Sfx2_38_Data_630D
	jp Sfx2_34_Shared_643F

Sfx2_38_Data_630D:
	dw Sfx2_38_Data_631F, Sfx2_38_Data_6324, Sfx2_38_Data_6329, Sfx2_38_Data_632E, Sfx2_38_Data_6333, Sfx2_38_Data_6338, Sfx2_38_Data_633D, Sfx2_38_Data_6342, Sfx2_38_Data_6347
Sfx2_38_Data_631F:
	db $80, $51, $f7, $86, $02
Sfx2_38_Data_6324:
	db $80, $f1, $39, $87, $03
Sfx2_38_Data_6329:
	db $80, $51, $39, $87, $02
Sfx2_38_Data_632E:
	db $80, $f1, $62, $87, $03
Sfx2_38_Data_6333:
	db $80, $51, $62, $87, $02
Sfx2_38_Data_6338:
	db $80, $f1, $39, $87, $03
Sfx2_38_Data_633D:
	db $80, $51, $39, $87, $02
Sfx2_38_Data_6342:
	db $80, $f1, $4f, $87, $04
Sfx2_38_Data_6347:
	db $80, $84, $4f, $87, $20
Sfx2_39_Init:
	ld hl, Sfx2_39_Data_6352
	jp Sfx2_34_Shared_643C

Sfx2_39_Data_6352:
	db $80, $f1, $14, $87, $03
Sfx2_39_Play:
	ld hl, Sfx2_39_Data_635D
	jp Sfx2_34_Shared_643F

Sfx2_39_Data_635D:
	dw Sfx2_39_Data_636F, Sfx2_39_Data_6374, Sfx2_39_Data_6379, Sfx2_39_Data_637E, Sfx2_39_Data_6383, Sfx2_39_Data_6388, Sfx2_39_Data_638D, Sfx2_39_Data_6392, Sfx2_39_Data_6397
Sfx2_39_Data_636F:
	db $80, $51, $14, $87, $02
Sfx2_39_Data_6374:
	db $80, $f1, $4f, $87, $03
Sfx2_39_Data_6379:
	db $80, $51, $4f, $87, $02
Sfx2_39_Data_637E:
	db $80, $f1, $74, $87, $03
Sfx2_39_Data_6383:
	db $80, $51, $74, $87, $02
Sfx2_39_Data_6388:
	db $80, $f1, $4f, $87, $03
Sfx2_39_Data_638D:
	db $80, $51, $4f, $87, $02
Sfx2_39_Data_6392:
	db $80, $f1, $62, $87, $04
Sfx2_39_Data_6397:
	db $80, $84, $62, $87, $20
Sfx2_3A_Init:
	ld hl, Sfx2_3A_Data_63A2
	jp Sfx2_34_Shared_643C

Sfx2_3A_Data_63A2:
	db $80, $f1, $2d, $87, $03
Sfx2_3A_Play:
	ld hl, Sfx2_3A_Data_63AD
	jp Sfx2_34_Shared_643F

Sfx2_3A_Data_63AD:
	dw Sfx2_3A_Data_63BF, Sfx2_3A_Data_63C4, Sfx2_3A_Data_63C9, Sfx2_3A_Data_63CE, Sfx2_3A_Data_63D3, Sfx2_3A_Data_63D8, Sfx2_3A_Data_63DD, Sfx2_3A_Data_63E2, Sfx2_3A_Data_63E7
Sfx2_3A_Data_63BF:
	db $80, $51, $2d, $87, $02
Sfx2_3A_Data_63C4:
	db $80, $f1, $62, $87, $03
Sfx2_3A_Data_63C9:
	db $80, $51, $62, $87, $02
Sfx2_3A_Data_63CE:
	db $80, $f1, $83, $87, $03
Sfx2_3A_Data_63D3:
	db $80, $51, $83, $87, $02
Sfx2_3A_Data_63D8:
	db $80, $f1, $62, $87, $03
Sfx2_3A_Data_63DD:
	db $80, $51, $62, $87, $02
Sfx2_3A_Data_63E2:
	db $80, $f1, $74, $87, $04
Sfx2_3A_Data_63E7:
	db $80, $84, $74, $87, $20
Sfx2_3B_Init:
	ld hl, Sfx2_34_Data_63F2
	jp Sfx2_34_Shared_643C

Sfx2_34_Data_63F2:
	db $80, $f1, $44, $87, $03
Sfx2_3B_Play:
	ld hl, Sfx2_34_Data_63FD
	jp Sfx2_34_Shared_643F

Sfx2_34_Data_63FD:
	dw Sfx2_34_Data_640F, Sfx2_34_Data_6414, Sfx2_34_Data_6419, Sfx2_34_Data_641E, Sfx2_34_Data_6423, Sfx2_34_Data_6428, Sfx2_34_Data_642D, Sfx2_34_Data_6432, Sfx2_34_Data_6437
Sfx2_34_Data_640F:
	db $80, $51, $44, $87, $02
Sfx2_34_Data_6414:
	db $80, $f1, $74, $87, $03
Sfx2_34_Data_6419:
	db $80, $51, $74, $87, $02
Sfx2_34_Data_641E:
	db $80, $f1, $90, $87, $03
Sfx2_34_Data_6423:
	db $80, $51, $90, $87, $02
Sfx2_34_Data_6428:
	db $80, $f1, $74, $87, $03
Sfx2_34_Data_642D:
	db $80, $51, $74, $87, $02
Sfx2_34_Data_6432:
	db $80, $f1, $83, $87, $04
Sfx2_34_Data_6437:
	db $80, $84, $83, $87, $20
Sfx2_34_Shared_643C:
	jp Sfx2_Start

Sfx2_34_Shared_643F:
	call Sfx_DecTimer
	jr nz, Sfx2_34_Shared_6452
	call Sfx_IncStep
	cp $0a
	jp z, Sfx2_Stop
	call GetPointer
	jp SetRegs_Ch2

Sfx2_34_Shared_6452:
	ld a, [bc]
	cp $09
	ret nz
	ld a, [de]
	and $03
	cp $03
	jr z, Sfx2_34_Shared_6462
	ld a, $80
	ldh [rNR21], a
	ret

Sfx2_34_Shared_6462:
	ld a, $40
	ldh [rNR21], a
	ret

Sfx2_3C_Init:
	ld hl, Sfx2_35_Data_646D
	jp Sfx2_Start

Sfx2_35_Data_646D:
	db $80, $f1, $59, $87, $03
Sfx2_3C_Play:
	call Sfx_DecTimer
	jr nz, Sfx2_35_Shared_6488
	call Sfx_IncStep
	cp $10
	jp z, Sfx2_Stop
	ld hl, Sfx2_35_Data_649D
	call GetPointer
	jp SetRegs_Ch2

Sfx2_35_Shared_6488:
	ld a, [bc]
	cp $0f
	ret nz
	ld a, [de]
	and $03
	cp $03
	jr z, Sfx2_35_Shared_6498
	ld a, $80
	ldh [rNR21], a
	ret

Sfx2_35_Shared_6498:
	ld a, $40
	ldh [rNR21], a
	ret

Sfx2_35_Data_649D:
	dw Sfx2_35_Data_64BB, Sfx2_35_Data_64C0, Sfx2_35_Data_64C5, Sfx2_35_Data_64CA, Sfx2_35_Data_64CF, Sfx2_35_Data_64D4, Sfx2_35_Data_64D9, Sfx2_35_Data_64DE, Sfx2_35_Data_64E3, Sfx2_35_Data_64E8, Sfx2_35_Data_64ED, Sfx2_35_Data_64F2, Sfx2_35_Data_64F7, Sfx2_35_Data_64FC, Sfx2_35_Data_6501
Sfx2_35_Data_64BB:
	db $80, $51, $59, $87, $02
Sfx2_35_Data_64C0:
	db $80, $f1, $83, $87, $03
Sfx2_35_Data_64C5:
	db $80, $51, $83, $87, $02
Sfx2_35_Data_64CA:
	db $80, $f1, $9d, $87, $03
Sfx2_35_Data_64CF:
	db $80, $51, $9d, $87, $02
Sfx2_35_Data_64D4:
	db $80, $f1, $83, $87, $03
Sfx2_35_Data_64D9:
	db $80, $51, $83, $87, $02
Sfx2_35_Data_64DE:
	db $80, $f1, $90, $87, $04
Sfx2_35_Data_64E3:
	db $80, $51, $90, $87, $03
Sfx2_35_Data_64E8:
	db $80, $f1, $a7, $87, $04
Sfx2_35_Data_64ED:
	db $80, $51, $a7, $87, $03
Sfx2_35_Data_64F2:
	db $80, $f1, $b6, $87, $05
Sfx2_35_Data_64F7:
	db $80, $51, $b6, $87, $04
Sfx2_35_Data_64FC:
	db $80, $f2, $b1, $87, $04
Sfx2_35_Data_6501:
	db $80, $a5, $b1, $87, $20
Sfx2_3D_Init:
	ld a, $3f
	ld [wSfx4Request], a
	ld hl, Sfx2_3D_Data_6552
	jp Sfx2_Start

Sfx2_3D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $25
	jp z, Sfx2_Stop
	cp $10
	call nc, .l0
	ld hl, Sfx2_3D_Data_6530
	call GetPointer
	jp SetRegsSkip0_Ch2

.l0:
	and $01
	add a, $10
	ret

Sfx2_3D_Data_6530:
	dw Sfx2_3D_Data_6557, Sfx2_3D_Data_6561, Sfx2_3D_Data_655C, Sfx2_3D_Data_6561, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561, Sfx2_3D_Data_656B, Sfx2_3D_Data_6566, Sfx2_3D_Data_6561
Sfx2_3D_Data_6552:
	db $40, $08, $cb, $87, $05
Sfx2_3D_Data_6557:
	db $40, $d1, $cb, $87, $01
Sfx2_3D_Data_655C:
	db $40, $a2, $cb, $87, $01
Sfx2_3D_Data_6561:
	db $40, $00, $cc, $07, $01
Sfx2_3D_Data_6566:
	db $40, $00, $cb, $07, $01
Sfx2_3D_Data_656B:
	db $40, $37, $cb, $87, $01
Sfx4_3F_Init:
	ld hl, Sfx4_3F_Data_6588
	jp Sfx4_Start

Sfx4_3F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_3F_Data_6588
	jp SetRegs_Ch4

Sfx4_3F_Data_6588:
	db $34, $da, $37, $c0, $04
Sfx4_43_Init:
	ld a, [wSfx4Playing]
	cp $43
	jr z, .l0
	ld hl, Sfx4_43_Data_66D0
	call LoadWave
	ld hl, Sfx4_43_Data_660D
	jp Sfx4Wave_Start

.l0:
	ld hl, Sfx4_43_Data_660D
	ldh a, [rNR30]
	and a
	jp z, Sfx4Wave_Start
	call Sfx4Wave_Take
	ld a, $11
	ld [de], a
	ret

Sfx4_43_Play:
	xor a
	ldh [rNR31], a
	call Sfx_DecTimer
	jp z, Sfx4Wave_Stop
	cpl
	add a, $12
	ld d, a
	cp $01
	jr z, .l1
	cp $02
	jr z, .l2
	cp $03
	jr z, .l3
	cp $0f
	jr z, .l2
	cp $10
	jr z, .l1
.l5:
	ld a, d
	ld hl, Sfx4_43_Data_65ED
	call GetPointer
	ld a, l
	ldh [rNR33], a
	ld a, h
	ldh [rNR34], a
	ret

.l3:
	ld a, $20
	jr .l4

.l2:
	ld a, $40
	jr .l4

.l1:
	ld a, $60
.l4:
	ldh [rNR32], a
	jr .l5

Sfx4_43_Data_65ED:
	db $4e, $04, $9c, $00, $4e, $04, $9c, $00, $4e, $04, $4e, $04, $4e, $04, $2c, $00
	db $83, $04, $83, $04, $06, $01, $b5, $04, $b5, $04, $e5, $04, $11, $05, $3b, $05
Sfx4_43_Data_660D:
	db $80, $00, $00, $4e, $84, $0f
Sfx4_44_Init:
	ld hl, Sfx4_44_Data_66E0
	call LoadWave
	ld hl, Sfx4_44_Data_6626
	jp Sfx4Wave_Start

Sfx4_44_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4Wave_Stop

Sfx4_44_Data_6626:
	db $80, $00, $20, $c2, $c7, $02
	db $00, $00, $00, $00, $00, $03
	db $69, $cf, $ff, $ff, $ff, $ff
	db $ff, $fc, $96, $30
Sfx4_45_Init:
	ld hl, Sfx4_45_Data_66F0
	call LoadWave
	ld hl, Sfx4_45_Data_66CA
	jp Sfx4Wave_StartPriority

Sfx4_45_Play:
	xor a
	ldh [rNR31], a
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $16
	jp z, Sfx4Wave_Stop
	dec a
	sla a
	inc a
	push af
	ld hl, Sfx4_45_Data_6676
	call GetPointer
	ld a, l
	ldh [rNR33], a
	ld a, h
	ldh [rNR34], a
	pop af
	inc a
	ld hl, Sfx4_45_Data_6676
	call GetPointer
	ld a, h
	ldh [rNR32], a
	ld a, l
	ld [de], a
	ret

Sfx4_45_Data_6676:
	db $06, $07, $02, $60, $06, $07, $06, $20, $06, $07, $02, $60, $39, $07, $06, $20
	db $39, $07, $02, $60, $59, $07, $06, $20, $59, $07, $0a, $60, $39, $07, $06, $20
	db $39, $07, $02, $60, $59, $07, $02, $20, $59, $07, $02, $60, $62, $07, $02, $20
	db $62, $07, $02, $60, $6b, $07, $02, $20, $6b, $07, $02, $60, $74, $07, $02, $20
	db $74, $07, $02, $60, $7b, $07, $02, $20, $7b, $07, $02, $60, $83, $07, $0e, $20
	db $83, $07, $01, $60
Sfx4_45_Data_66CA:
	db $80, $00, $20, $06, $87, $06
Sfx4_43_Data_66D0:
	db $7e, $ee, $ee, $ee, $ee, $ee, $ee, $ee, $70, $00, $00, $00, $00, $00, $00, $00
Sfx4_44_Data_66E0:
	db $27, $99, $99, $99, $99, $99, $99, $99, $72, $00, $00, $00, $00, $00, $00, $00
Sfx4_45_Data_66F0:
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
Sfx4_46_Init:
	ld hl, Sfx4_46_Data_6747
	jp Sfx4_Start

Sfx4_46_Play:
	call Sfx_DecTimer
	jp z, Sfx4_StopWithRegs
	ld d, $00
	cpl
	add a, $19
	cp $05
	call z, .l0
	bit 0, a
	ret nz
	srl a
	ld hl, Sfx4_46_Data_6731
	call GetPointer
	ld a, l
	ldh [rNR43], a
	ld a, d
	ldh [rNR44], a
	ret

.l0:
	ld d, a
	ld a, $87
	ldh [rNR42], a
	ld a, d
	ld d, $80
	ret

Sfx4_46_Data_6731:
	db $34, $00, $24, $00, $27, $00, $55, $00, $45, $00, $34, $00, $45, $00, $37, $00
	db $47, $00, $45, $00, $55, $00
Sfx4_46_Data_6747:
	db $00, $49, $26, $80, $18
Sfx4_47_Init:
	ld a, [wDED3]
	inc a
	cp $14
	jr c, .l0
	ld a, $14
.l0:
	ld [wDED3], a
	ld hl, Sfx4_47_Data_6762
	call GetPointer
	jp Sfx4_Start

Sfx4_47_Data_6762:
	dw Sfx4_47_Data_678A, Sfx4_47_Data_678A, Sfx4_47_Data_678F, Sfx4_47_Data_678F, Sfx4_47_Data_6794, Sfx4_47_Data_6794, Sfx4_47_Data_6799, Sfx4_47_Data_6799, Sfx4_47_Data_679E, Sfx4_47_Data_679E, Sfx4_47_Data_67A8, Sfx4_47_Data_67A8, Sfx4_47_Data_67A3, Sfx4_47_Data_67A3, Sfx4_47_Data_67AD, Sfx4_47_Data_67AD, Sfx4_47_Data_67B2, Sfx4_47_Data_67B2, Sfx4_47_Data_67B7, Sfx4_47_Data_67B7
Sfx4_47_Data_678A:
	db $34, $f8, $55, $c0, $08
Sfx4_47_Data_678F:
	db $34, $f8, $47, $c0, $08
Sfx4_47_Data_6794:
	db $38, $f8, $45, $c0, $08
Sfx4_47_Data_6799:
	db $38, $f8, $37, $c0, $08
Sfx4_47_Data_679E:
	db $3c, $f8, $34, $c0, $08
Sfx4_47_Data_67A3:
	db $3c, $f8, $27, $c0, $08
Sfx4_47_Data_67A8:
	db $3c, $f8, $26, $c0, $08
Sfx4_47_Data_67AD:
	db $3c, $f8, $24, $c0, $08
Sfx4_47_Data_67B2:
	db $3c, $f8, $17, $c0, $08
Sfx4_47_Data_67B7:
	db $3c, $f8, $15, $c0, $08
Sfx4_47_Play:
	call Sfx_DecTimer
	jp z, Sfx4_Stop
	ret

Sfx4_48_Init:
	ld hl, Sfx4_48_Data_67E2
	jp Sfx4_Start

Sfx4_48_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_48_Data_67DE
	call GetPointer
	jp SetRegs_Ch4

Sfx4_48_Data_67DE:
	dw Sfx4_48_Data_67E7, Sfx4_48_Data_67EC
Sfx4_48_Data_67E2:
	db $3c, $a9, $02, $c0, $01
Sfx4_48_Data_67E7:
	db $3c, $f1, $27, $c0, $06
Sfx4_48_Data_67EC:
	db $3c, $a9, $02, $c0, $02
