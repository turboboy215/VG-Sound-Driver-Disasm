; Link's Awakening DX SFX, bank $1F: ch4 effects, bank $1F $63EC-$7A63

Sfx4_InitTable:
	dw Sfx4_01_Init
	dw Sfx4_02_Init
	dw Sfx4_03_Init
	dw Sfx4_04_Init
	dw Sfx4_05_Init
	dw Sfx4_06_Init
	dw Sfx4_07_Init
	dw Sfx4_08_Init
	dw Sfx4_09_Init
	dw Sfx4_0A_Init
	dw Sfx4_0B_Init
	dw Sfx4_0C_Init
	dw Sfx4_0D_Init
	dw Sfx4_0E_Init
	dw Sfx4_0F_Init
	dw Sfx4_10_Init
	dw Sfx4_11_Init
	dw Sfx4_12_Init
	dw Sfx4_13_Init
	dw Sfx4_14_Init
	dw Sfx4_15_Init
	dw Sfx4_16_Init
	dw Sfx4_17_Init
	dw Sfx4_18_Init
	dw Sfx4_19_Init
	dw Sfx4_1A_Init
	dw Sfx4_1B_Init
	dw Sfx4_1C_Init
	dw Sfx4_1D_Init
	dw Sfx4_1E_Init
	dw Sfx4_1F_Init
	dw Sfx4_20_Init
	dw Sfx4_StopWithRegs
	dw Sfx4_22_Init
	dw Sfx4_23_Init
	dw Sfx4_24_Init
	dw Sfx4_25_Init
	dw Sfx4_26_Init
	dw Sfx4_27_Init
	dw Sfx4_28_Init
	dw Sfx4_29_Init
	dw Sfx4_2A_Init
	dw Sfx4_2B_Init
	dw Sfx4_2C_Init
	dw Sfx4_2D_Init
	dw Sfx4_2E_Init
	dw Sfx4_2F_Init
	dw Sfx4_30_Init
	dw Sfx4_31_Init
	dw Sfx4_32_Init
	dw Sfx4_33_Init
	dw Sfx4_34_Init
	dw Sfx4_35_Init
	dw Sfx4_36_Init
	dw Sfx4_37_Init
	dw Sfx4_38_Init
	dw Sfx4_39_Init
	dw Sfx4_3A_Init
	dw Sfx4_3B_Init
	dw Sfx4_3C_Init
	dw Sfx4_3D_Init
	dw Sfx4_3E_Init
	dw Sfx4_3F_Init
	dw Sfx4_40_Init
Sfx4_PlayTable:
	dw Sfx4_01_Play
	dw Sfx4_02_Play
	dw Sfx4_03_Play
	dw Sfx4_04_Play
	dw Sfx4_05_Play
	dw Sfx4_06_Play
	dw Sfx4_07_Play
	dw Sfx4_08_Play
	dw Sfx4_09_Play
	dw Sfx4_0A_Play
	dw Sfx4_0B_Play
	dw Sfx4_0C_Play
	dw Sfx4_0D_Play
	dw Sfx4_0E_Play
	dw Sfx4_0F_Play
	dw Sfx4_10_Play
	dw Sfx4_11_Play
	dw Sfx4_12_Play
	dw Sfx4_13_Play
	dw Sfx4_14_Play
	dw Sfx4_15_Play
	dw Sfx4_16_Play
	dw Sfx4_17_Play
	dw Sfx4_18_Play
	dw Sfx4_19_Play
	dw Sfx4_1A_Play
	dw Sfx4_1B_Play
	dw Sfx4_1C_Play
	dw Sfx4_1D_Play
	dw Sfx4_1E_Play
	dw Sfx4_1F_Play
	dw Sfx4_20_Play
	dw Sfx4_StopWithRegs
	dw Sfx4_22_Play
	dw Sfx4_23_Play
	dw Sfx4_24_Play
	dw Sfx4_25_Play
	dw Sfx4_26_Play
	dw Sfx4_27_Play
	dw Sfx4_28_Play
	dw Sfx4_29_Play
	dw Sfx4_2A_Play
	dw Sfx4_2B_Play
	dw Sfx4_2C_Play
	dw Sfx4_2D_Play
	dw Sfx4_2E_Play
	dw Sfx4_2F_Play
	dw Sfx4_30_Play
	dw Sfx4_31_Play
	dw Sfx4_32_Play
	dw Sfx4_33_Play
	dw Sfx4_34_Play
	dw Sfx4_35_Play
	dw Sfx4_36_Play
	dw Sfx4_37_Play
	dw Sfx4_38_Play
	dw Sfx4_39_Play
	dw Sfx4_3A_Play
	dw Sfx4_3B_Play
	dw Sfx4_Stop
	dw Sfx4_3D_Play
	dw Sfx4_3E_Play
	dw Sfx4_3F_Play
	dw Sfx4_40_Play
; With no ch4 effect playing, a non-zero wLowHealthBeep keeps requesting effect $1E.
Sfx4_Update:
	ld hl, wSfx4Request
	ld a, [hl]
	and a
	jr z, .playing
	ld a, [wSfx4Priority]
	and a
	jp nz, Sfx4_Refuse
	ld a, [hl]
	ld hl, Sfx4_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	jr z, .lowHealth
	ld hl, Sfx4_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx4Timer
	ld bc, wSfx4Step
	jp hl

.lowHealth:
	ld a, [wLowHealthBeep]
	and a
	ret z
	ld a, $1e
	ld [wSfx4Request], a
	jr Sfx4_Update

Sfx4_01_Init:
	ld a, $01
	ld [wSfx4Playing], a
	ld hl, Sfx4_01_Data_6533
	jp SetRegs_Ch4

Sfx4_01_Play:
	xor a
	ld [wSfx4Playing], a
	ld hl, Sfx4_01_Data_6538
	jp SetRegs_Ch4

Sfx4_01_Data_6533:
	db $3b, $80, $07, $c0, $01
Sfx4_01_Data_6538:
	db $00, $42, $02, $c0, $04
Sfx4_02_Init:
	ld hl, Sfx4_02_Data_6564
	jp Sfx4_Start

Sfx4_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_02_Data_6558
	call GetPointer
	jp SetRegs_Ch4

Sfx4_02_Data_6558:
	dw Sfx4_02_Data_6569, Sfx4_02_Data_656E, Sfx4_02_Data_6573, Sfx4_02_Data_6578, Sfx4_02_Data_657D, Sfx4_02_Data_6582
Sfx4_02_Data_6564:
	db $00, $40, $21, $80, $01
Sfx4_02_Data_6569:
	db $00, $50, $22, $80, $01
Sfx4_02_Data_656E:
	db $00, $60, $23, $80, $01
Sfx4_02_Data_6573:
	db $00, $70, $24, $80, $01
Sfx4_02_Data_6578:
	db $00, $80, $25, $80, $01
Sfx4_02_Data_657D:
	db $00, $90, $26, $80, $01
Sfx4_02_Data_6582:
	db $3c, $a0, $27, $c0, $01
Sfx4_03_Init:
	ld hl, Sfx4_03_Data_65C2
	jp Sfx4_Start

Sfx4_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $11
	jp z, Sfx4_Stop
	ld hl, Sfx4_03_Data_65A2
	call GetPointer
	jp SetRegs_Ch4

Sfx4_03_Data_65A2:
	dw Sfx4_03_Data_65C7, Sfx4_03_Data_65CC, Sfx4_03_Data_65D1, Sfx4_03_Data_65D6, Sfx4_03_Data_65DB, Sfx4_03_Data_65E0, Sfx4_03_Data_65E5, Sfx4_03_Data_65EA, Sfx4_03_Data_65E5, Sfx4_03_Data_65E0, Sfx4_03_Data_65DB, Sfx4_03_Data_65D6, Sfx4_03_Data_65D1, Sfx4_03_Data_65CC, Sfx4_03_Data_65C7, Sfx4_03_Data_65C2
Sfx4_03_Data_65C2:
	db $37, $10, $04, $c0, $02
Sfx4_03_Data_65C7:
	db $00, $20, $06, $80, $02
Sfx4_03_Data_65CC:
	db $00, $30, $14, $80, $02
Sfx4_03_Data_65D1:
	db $00, $40, $16, $80, $02
Sfx4_03_Data_65D6:
	db $00, $50, $24, $80, $02
Sfx4_03_Data_65DB:
	db $00, $60, $26, $80, $02
Sfx4_03_Data_65E0:
	db $00, $70, $34, $80, $02
Sfx4_03_Data_65E5:
	db $00, $80, $36, $80, $02
Sfx4_03_Data_65EA:
	db $00, $90, $44, $80, $02
Sfx4_04_Init:
	ld hl, Sfx4_04_Data_6610
	jp Sfx4_Start

Sfx4_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Stop
	ld hl, Sfx4_04_Data_660A
	call GetPointer
	jp SetRegs_Ch4

Sfx4_04_Data_660A:
	dw Sfx4_04_Data_6615, Sfx4_04_Data_6610, Sfx4_04_Data_661A
Sfx4_04_Data_6610:
	db $3b, $c0, $3e, $c0, $01
Sfx4_04_Data_6615:
	db $33, $f0, $6e, $c0, $06
Sfx4_04_Data_661A:
	db $36, $70, $4e, $c0, $03
Sfx4_05_Init:
	ld a, [wSfx4Playing]
	cp $02
	jp z, Sfx4_Refuse
	cp $03
	jp z, Sfx4_Refuse
	cp $0c
	jp z, Sfx4_Refuse
	cp $13
	jp z, Sfx4_Refuse
	ld hl, Sfx4_05_Data_6659
	jp Sfx4_Start

Sfx4_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_05_Data_6651
	call GetPointer
	jp SetRegs_Ch4

Sfx4_05_Data_6651:
	dw Sfx4_05_Data_665E, Sfx4_05_Data_6663, Sfx4_05_Data_6668, Sfx4_05_Data_6668
Sfx4_05_Data_6659:
	db $30, $49, $60, $c0, $06
Sfx4_05_Data_665E:
	db $30, $49, $40, $c0, $06
Sfx4_05_Data_6663:
	db $30, $49, $20, $c0, $06
Sfx4_05_Data_6668:
	db $30, $49, $00, $c0, $06
Sfx4_06_Init:
	ld hl, Sfx4_06_Data_668E
	jp Sfx4_Start

Sfx4_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Stop
	ld hl, Sfx4_06_Data_6688
	call GetPointer
	jp SetRegs_Ch4

Sfx4_06_Data_6688:
	dw Sfx4_06_Data_6693, Sfx4_06_Data_6698, Sfx4_06_Data_669D
Sfx4_06_Data_668E:
	db $00, $61, $24, $80, $0c
Sfx4_06_Data_6693:
	db $00, $51, $25, $80, $0c
Sfx4_06_Data_6698:
	db $00, $32, $27, $80, $0c
Sfx4_06_Data_669D:
	db $00, $22, $34, $80, $0c
Sfx4_07_Init:
	ld a, [wSfx4Playing]
	cp $05
	jp z, Sfx4_Refuse
	cp $08
	jp z, Sfx4_Refuse
	cp $0c
	jp z, Sfx4_Refuse
	cp $10
	jp z, Sfx4_Refuse
	cp $13
	jp z, Sfx4_Refuse
	ld hl, Sfx4_07_Data_66D6
	jp Sfx4_Start

Sfx4_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_07_Data_66DB
	jp SetRegs_Ch4

Sfx4_07_Data_66D6:
	db $3b, $f0, $20, $c0, $02
Sfx4_07_Data_66DB:
	db $39, $40, $20, $c0, $08
Sfx4_08_Init:
	ld a, [wSfx4Playing]
	cp $0c
	jp z, Sfx4_Refuse
	ld a, $03
	ld [wSfx4Counter], a
	ld hl, Sfx4_08_Data_6718
	jp Sfx4_Start

Sfx4_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l1:
	ld hl, Sfx4_08_Data_6712
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_08_Data_6712:
	dw Sfx4_08_Data_671D, Sfx4_08_Data_6720, Sfx4_08_Data_6723
Sfx4_08_Data_6718:
	db $00, $a3, $3c, $80, $03
Sfx4_08_Data_671D:
	db $3d, $00, $03
Sfx4_08_Data_6720:
	db $3e, $00, $03
Sfx4_08_Data_6723:
	db $3f, $00, $03
Sfx4_09_Init:
	ld hl, Sfx4_09_Data_674F
	jp Sfx4_Start

Sfx4_09_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $33
	ldh [rNR41], a
	call Sfx_IncStep
	cp $06
	jp z, Sfx4_Stop
	ld hl, Sfx4_09_Data_6745
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_09_Data_6745:
	dw Sfx4_09_Data_6754, Sfx4_09_Data_6757, Sfx4_09_Data_675A, Sfx4_09_Data_675D, Sfx4_09_Data_675D
Sfx4_09_Data_674F:
	db $33, $a0, $72, $c0, $04
Sfx4_09_Data_6754:
	db $52, $c0, $04
Sfx4_09_Data_6757:
	db $50, $c0, $04
Sfx4_09_Data_675A:
	db $30, $c0, $04
Sfx4_09_Data_675D:
	db $10, $c0, $04
Sfx4_0A_Init:
	ld hl, Sfx4_0A_Data_6783
	jp Sfx4_Start

Sfx4_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_0A_Data_677B
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0A_Data_677B:
	dw Sfx4_0A_Data_6788, Sfx4_0A_Data_678D, Sfx4_0A_Data_6788, Sfx4_0A_Data_6783
Sfx4_0A_Data_6783:
	db $37, $40, $47, $c0, $01
Sfx4_0A_Data_6788:
	db $00, $60, $27, $80, $02
Sfx4_0A_Data_678D:
	db $00, $a0, $15, $80, $02
Sfx4_0B_Init:
	ld hl, Sfx4_0B_Data_67AA
	jp Sfx4_Start

Sfx4_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_0B_Data_67AF
	jp SetRegs_Ch4

Sfx4_0B_Data_67AA:
	db $3c, $c0, $18, $c0, $01
Sfx4_0B_Data_67AF:
	db $3c, $60, $18, $c0, $02
Sfx4_0C_Init:
	ld a, [wSfx4Playing]
	cp $02
	jp z, Sfx4_Refuse
	cp $03
	jp z, Sfx4_Refuse
	ld hl, Sfx4_0C_Data_67E4
	jp Sfx4_Start

Sfx4_0C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_0C_Data_67DC
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_0C_Data_67DC:
	dw Sfx4_0C_Data_67E9, Sfx4_0C_Data_67EC, Sfx4_0C_Data_67EF, Sfx4_0C_Data_67F2
Sfx4_0C_Data_67E4:
	db $00, $c6, $6a, $80, $04
Sfx4_0C_Data_67E9:
	db $6b, $00, $05
Sfx4_0C_Data_67EC:
	db $6c, $00, $06
Sfx4_0C_Data_67EF:
	db $6d, $00, $07
Sfx4_0C_Data_67F2:
	db $6e, $00, $38
Sfx4_0D_Init:
	ld a, $0e
	ld [wSfx4Counter], a
	ld hl, Sfx4_0D_Data_6823
	jp Sfx4_Start

Sfx4_0D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_0D_Data_681F
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_0D_Data_681F:
	dw Sfx4_0D_Data_6828, Sfx4_0D_Data_682B
Sfx4_0D_Data_6823:
	db $00, $67, $0f, $80, $02
Sfx4_0D_Data_6828:
	db $60, $00, $02
Sfx4_0D_Data_682B:
	db $0f, $00, $02
Sfx4_0E_Init:
	ld hl, Sfx4_0E_Data_684D
	jp Sfx4_Start

Sfx4_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_0E_Data_6849
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0E_Data_6849:
	dw Sfx4_0E_Data_6852, Sfx4_0E_Data_6857
Sfx4_0E_Data_684D:
	db $1e, $29, $46, $c0, $10
Sfx4_0E_Data_6852:
	db $00, $29, $64, $80, $08
Sfx4_0E_Data_6857:
	db $00, $81, $64, $80, $06
Sfx4_0F_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld hl, Sfx4_0F_Data_6882
	jp Sfx4_Start

Sfx4_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_0F_Data_687E
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0F_Data_687E:
	dw Sfx4_0F_Data_6887, Sfx4_0F_Data_688C
Sfx4_0F_Data_6882:
	db $00, $0f, $30, $80, $20
Sfx4_0F_Data_6887:
	db $00, $60, $03, $80, $30
Sfx4_0F_Data_688C:
	db $00, $67, $03, $80, $20
Sfx4_10_Init:
	ld a, $03
	ld [wSfx4Counter], a
	ld hl, Sfx4_10_Data_68D2
	jp Sfx4_Start

Sfx4_10_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jr z, .l0
	ld hl, Sfx4_10_Data_68C8
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	cp $01
	jr z, .l1
	ld hl, Sfx4_10_Data_68E6
.l2:
	ld a, $01
	ld [bc], a
	jp SetRegs_Ch4

.l1:
	ld hl, Sfx4_10_Data_68EB
	jr .l2

Sfx4_10_Data_68C8:
	dw Sfx4_10_Data_68D7, Sfx4_10_Data_68DA, Sfx4_10_Data_68DD, Sfx4_10_Data_68E0, Sfx4_10_Data_68E3
Sfx4_10_Data_68D2:
	db $00, $e0, $48, $80, $01
Sfx4_10_Data_68D7:
	db $4b, $00, $01
Sfx4_10_Data_68DA:
	db $5e, $00, $01
Sfx4_10_Data_68DD:
	db $5d, $00, $02
Sfx4_10_Data_68E0:
	db $6c, $00, $02
Sfx4_10_Data_68E3:
	db $6f, $00, $02
Sfx4_10_Data_68E6:
	db $00, $70, $4b, $80, $01
Sfx4_10_Data_68EB:
	db $00, $20, $4b, $80, $01
Sfx4_11_Init:
	ld hl, Sfx4_11_Data_68FD
	jp Sfx4_Start

Sfx4_11_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_StopWithRegs

Sfx4_11_Data_68FD:
	db $00, $f0, $a0, $80, $20
Sfx4_12_Init:
	ld hl, Sfx4_12_Data_692B
	jp Sfx4_Start

Sfx4_12_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_12_Data_691D
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_12_Data_691D:
	dw Sfx4_12_Data_6930, Sfx4_12_Data_6933, Sfx4_12_Data_6936, Sfx4_12_Data_6933, Sfx4_12_Data_6930, Sfx4_12_Data_6939, Sfx4_12_Data_693C
Sfx4_12_Data_692B:
	db $00, $69, $b8, $80, $02
Sfx4_12_Data_6930:
	db $a8, $00, $02
Sfx4_12_Data_6933:
	db $98, $00, $02
Sfx4_12_Data_6936:
	db $88, $00, $02
Sfx4_12_Data_6939:
	db $b8, $00, $02
Sfx4_12_Data_693C:
	db $c8, $00, $02
Sfx4_13_Init:
	ld hl, Sfx4_13_Data_699C
	jp Sfx4_Start

Sfx4_13_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1a
	jp z, Sfx4_Stop
	ld hl, Sfx4_13_Data_696A
	call GetPointer
	ld a, [wSfx4Step]
	cp $11
	jr nc, .l0
	jp SetRegs_Ch4

.l0:
	inc hl
	inc hl
	ld a, $20
	ldh [rNR42], a
	jp Sfx4_WriteNR43

Sfx4_13_Data_696A:
	dw Sfx4_13_Data_69A1, Sfx4_13_Data_69A6, Sfx4_13_Data_69AB, Sfx4_13_Data_69B0, Sfx4_13_Data_69B5, Sfx4_13_Data_69BA, Sfx4_13_Data_69BF, Sfx4_13_Data_69C4, Sfx4_13_Data_69BF, Sfx4_13_Data_69BA, Sfx4_13_Data_69B5, Sfx4_13_Data_69B0, Sfx4_13_Data_69AB, Sfx4_13_Data_69A6, Sfx4_13_Data_69A1, Sfx4_13_Data_699C, Sfx4_13_Data_69C4, Sfx4_13_Data_69BF, Sfx4_13_Data_69BA, Sfx4_13_Data_69B5, Sfx4_13_Data_69B0, Sfx4_13_Data_69AB, Sfx4_13_Data_69A6, Sfx4_13_Data_69A1, Sfx4_13_Data_699C
Sfx4_13_Data_699C:
	db $37, $20, $25, $c0, $01
Sfx4_13_Data_69A1:
	db $00, $40, $27, $80, $01
Sfx4_13_Data_69A6:
	db $00, $60, $35, $80, $01
Sfx4_13_Data_69AB:
	db $00, $80, $37, $80, $01
Sfx4_13_Data_69B0:
	db $00, $a0, $4d, $80, $02
Sfx4_13_Data_69B5:
	db $00, $b0, $4f, $80, $02
Sfx4_13_Data_69BA:
	db $00, $c0, $5d, $80, $02
Sfx4_13_Data_69BF:
	db $00, $d0, $5f, $80, $02
Sfx4_13_Data_69C4:
	db $00, $e0, $6d, $80, $02
Sfx4_14_Init:
	ld hl, Sfx4_14_Data_69EC
	jp Sfx4_Start

Sfx4_14_Play:
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_14_Data_69E0
	call GetPointer
	jp SetRegs_Ch4

Sfx4_14_Data_69E0:
	dw Sfx4_14_Data_69F1, Sfx4_14_Data_69F6, Sfx4_14_Data_69FB, Sfx4_14_Data_6A00, Sfx4_14_Data_6A05, Sfx4_14_Data_6A0A
Sfx4_14_Data_69EC:
	db $00, $40, $5f, $80, $01
Sfx4_14_Data_69F1:
	db $00, $50, $5d, $80, $01
Sfx4_14_Data_69F6:
	db $00, $60, $4f, $80, $01
Sfx4_14_Data_69FB:
	db $00, $70, $4d, $80, $01
Sfx4_14_Data_6A00:
	db $00, $80, $3f, $80, $01
Sfx4_14_Data_6A05:
	db $00, $90, $3c, $80, $01
Sfx4_14_Data_6A0A:
	db $3c, $a0, $2e, $c0, $01
Sfx4_15_Init:
	ld hl, Sfx4_15_Data_6A30
	jp Sfx4_Start

Sfx4_15_Play:
	call Sfx_IncStep
	cp $06
	jp z, Sfx4_Stop
	ld hl, Sfx4_15_Data_6A26
	call GetPointer
	jp SetRegs_Ch4

Sfx4_15_Data_6A26:
	dw Sfx4_15_Data_6A35, Sfx4_15_Data_6A3A, Sfx4_15_Data_6A3F, Sfx4_15_Data_6A44, Sfx4_15_Data_6A49
Sfx4_15_Data_6A30:
	db $00, $20, $47, $80, $02
Sfx4_15_Data_6A35:
	db $00, $40, $37, $80, $01
Sfx4_15_Data_6A3A:
	db $00, $60, $27, $80, $01
Sfx4_15_Data_6A3F:
	db $00, $80, $17, $80, $01
Sfx4_15_Data_6A44:
	db $00, $a0, $07, $80, $01
Sfx4_15_Data_6A49:
	db $3c, $c0, $03, $c0, $01
Sfx4_16_Init:
	ld a, [wSfx4Playing]
	cp $03
	jp z, Sfx4_Refuse
	ld hl, Sfx4_16_Data_6A71
	jp Sfx4_Start

Sfx4_16_Play:
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_16_Data_6A6D
	call GetPointer
	jp SetRegs_Ch4

Sfx4_16_Data_6A6D:
	dw Sfx4_16_Data_6A76, Sfx4_16_Data_6A7B
Sfx4_16_Data_6A71:
	db $00, $29, $68, $80, $10
Sfx4_16_Data_6A76:
	db $3c, $c0, $50, $c0, $01
Sfx4_16_Data_6A7B:
	db $3c, $c1, $18, $c0, $01
Sfx4_17_Init:
	ld hl, Sfx4_17_Data_6A98
	jp Sfx4_Start

Sfx4_17_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_17_Data_6A9D
	jp SetRegs_Ch4

Sfx4_17_Data_6A98:
	db $00, $f1, $09, $80, $0e
Sfx4_17_Data_6A9D:
	db $00, $62, $09, $80, $10
Sfx4_18_Init:
	ld hl, Sfx4_18_Data_6AC9
	jp Sfx4_Start

Sfx4_18_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_18_Data_6ABD
	call GetPointer
	jp SetRegs_Ch4

Sfx4_18_Data_6ABD:
	dw Sfx4_18_Data_6ACE, Sfx4_18_Data_6AD3, Sfx4_18_Data_6AD8, Sfx4_18_Data_6ADD, Sfx4_18_Data_6AE2, Sfx4_18_Data_6AE7
Sfx4_18_Data_6AC9:
	db $00, $20, $11, $80, $01
Sfx4_18_Data_6ACE:
	db $00, $40, $21, $80, $01
Sfx4_18_Data_6AD3:
	db $00, $60, $39, $80, $01
Sfx4_18_Data_6AD8:
	db $00, $80, $49, $80, $01
Sfx4_18_Data_6ADD:
	db $00, $a0, $4b, $80, $01
Sfx4_18_Data_6AE2:
	db $00, $c0, $4d, $80, $01
Sfx4_18_Data_6AE7:
	db $3c, $e0, $4f, $c0, $01
Sfx4_19_Init:
	ld hl, Sfx4_19_Data_6B1B
	jp Sfx4_Start

Sfx4_19_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx4_Stop
	ld hl, Sfx4_19_Data_6B07
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_19_Data_6B07:
	dw Sfx4_19_Data_6B20, Sfx4_19_Data_6B23, Sfx4_19_Data_6B26, Sfx4_19_Data_6B29, Sfx4_19_Data_6B2C, Sfx4_19_Data_6B29, Sfx4_19_Data_6B26, Sfx4_19_Data_6B23, Sfx4_19_Data_6B20, Sfx4_19_Data_6B2F
Sfx4_19_Data_6B1B:
	db $00, $67, $2c, $80, $01
Sfx4_19_Data_6B20:
	db $3c, $00, $01
Sfx4_19_Data_6B23:
	db $4c, $00, $01
Sfx4_19_Data_6B26:
	db $5c, $00, $01
Sfx4_19_Data_6B29:
	db $6c, $00, $01
Sfx4_19_Data_6B2C:
	db $7c, $00, $01
Sfx4_19_Data_6B2F:
	db $09, $80, $30
Sfx4_1A_Init:
	ld hl, Sfx4_1A_Data_6B77
	jp Sfx4_StartPriority

Sfx4_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $16
	jp z, Sfx4_Stop
	ld hl, Sfx4_1A_Data_6B4D
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_1A_Data_6B4D:
	dw Sfx4_1A_Data_6B7C, Sfx4_1A_Data_6B7F, Sfx4_1A_Data_6B82, Sfx4_1A_Data_6B85, Sfx4_1A_Data_6B88, Sfx4_1A_Data_6B85, Sfx4_1A_Data_6B82, Sfx4_1A_Data_6B7F, Sfx4_1A_Data_6B82, Sfx4_1A_Data_6B85, Sfx4_1A_Data_6B88, Sfx4_1A_Data_6B8B, Sfx4_1A_Data_6B8E, Sfx4_1A_Data_6B8B, Sfx4_1A_Data_6B88, Sfx4_1A_Data_6B85, Sfx4_1A_Data_6B88, Sfx4_1A_Data_6B8B, Sfx4_1A_Data_6B8E, Sfx4_1A_Data_6B91, Sfx4_1A_Data_6B94
Sfx4_1A_Data_6B77:
	db $00, $f7, $3d, $80, $04
Sfx4_1A_Data_6B7C:
	db $60, $00, $04
Sfx4_1A_Data_6B7F:
	db $61, $00, $04
Sfx4_1A_Data_6B82:
	db $62, $00, $04
Sfx4_1A_Data_6B85:
	db $63, $00, $04
Sfx4_1A_Data_6B88:
	db $64, $00, $04
Sfx4_1A_Data_6B8B:
	db $65, $00, $04
Sfx4_1A_Data_6B8E:
	db $66, $00, $04
Sfx4_1A_Data_6B91:
	db $67, $00, $04
Sfx4_1A_Data_6B94:
	db $74, $00, $28
Sfx4_1B_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld a, [wSfx1Var2]
	and a
	jr nz, .l0
	ld hl, Sfx4_1B_Data_6BF5
.l1:
	jp Sfx4_Start

.l0:
	ld hl, Sfx4_1B_Data_6C09
	jr .l1

Sfx4_1B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l2
	cp $06
	jp z, .l3
	ld a, [wSfx1Var2]
	and a
	jr nz, .l4
.l6:
	ld hl, Sfx4_1B_Data_6BE7
.l5:
	ld a, [bc]
	call GetPointer
	jp SetRegs_Ch4

.l4:
	ld hl, Sfx4_1B_Data_6BF1
	jr .l5

.l2:
	ld a, [wSfx1Var2]
	and a
	jp nz, .l3
	jr .l6

.l3:
	ld hl, wSfx4Request
	ld a, $1b
	ld [hl+], a
	xor a
	ld [hl], a
	jr Sfx4_1B_Init

Sfx4_1B_Data_6BE7:
	dw Sfx4_1B_Data_6BFF, Sfx4_1B_Data_6BFA, Sfx4_1B_Data_6C04, Sfx4_1B_Data_6BFA, Sfx4_1B_Data_6C04
Sfx4_1B_Data_6BF1:
	dw Sfx4_1B_Data_6C0E, Sfx4_1B_Data_6C0E
Sfx4_1B_Data_6BF5:
	db $37, $61, $30, $80, $03
Sfx4_1B_Data_6BFA:
	db $37, $41, $14, $80, $03
Sfx4_1B_Data_6BFF:
	db $37, $20, $30, $c0, $02
Sfx4_1B_Data_6C04:
	db $37, $20, $14, $c0, $02
Sfx4_1B_Data_6C09:
	db $37, $a1, $30, $80, $04
Sfx4_1B_Data_6C0E:
	db $37, $51, $14, $80, $04
Sfx4_1C_Init:
	ld a, $06
	ld [wSfx4Counter], a
	ld hl, Sfx4_1C_Data_6C41
	jp Sfx4_Start

Sfx4_1C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_1C_Data_6C3D
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_1C_Data_6C3D:
	dw Sfx4_1C_Data_6C46, Sfx4_1C_Data_6C49
Sfx4_1C_Data_6C41:
	db $00, $c0, $58, $80, $02
Sfx4_1C_Data_6C46:
	db $68, $80, $02
Sfx4_1C_Data_6C49:
	db $58, $80, $02
Sfx4_1D_Init:
	ld a, $78
	ld [wSfx4Counter], a
	ld hl, Sfx4_1D_Data_6C87
	jp Sfx4_StartPriority

Sfx4_1D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx4_1D_Data_6C83
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	cp $18
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	ld hl, Sfx4_1D_Data_6C8C
	jp SetRegs_Ch4

Sfx4_1D_Data_6C83:
	dw Sfx4_1D_Data_6C91, Sfx4_1D_Data_6C94
Sfx4_1D_Data_6C87:
	db $00, $2c, $7c, $80, $02
Sfx4_1D_Data_6C8C:
	db $00, $f7, $7c, $80, $02
Sfx4_1D_Data_6C91:
	db $7d, $00, $02
Sfx4_1D_Data_6C94:
	db $7c, $00, $02
Sfx4_1E_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld hl, Sfx4_1E_Data_6CBA
	jp Sfx4_Start

Sfx4_1E_Play:
	ld a, [wLowHealthBeep]
	and a
	jr z, .l0
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

.l0:
	ld hl, Sfx4_1E_Data_6CBF
	call SetRegs_Ch4
	jp Sfx4_Stop

Sfx4_1E_Data_6CBA:
	db $08, $60, $00, $c0, $0c
Sfx4_1E_Data_6CBF:
	db $00, $67, $00, $00, $20
Sfx4_1F_Init:
	ld a, $14
	ld [wSfx4Counter], a
	ld hl, Sfx4_1F_Data_6CFB
	jp Sfx4_Start

Sfx4_1F_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx4_1F_Data_6CF7
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	cp $0e
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	ld hl, Sfx4_1F_Data_6D00
	jp SetRegs_Ch4

Sfx4_1F_Data_6CF7:
	dw Sfx4_1F_Data_6D05, Sfx4_1F_Data_6D08
Sfx4_1F_Data_6CFB:
	db $00, $1a, $06, $80, $01
Sfx4_1F_Data_6D00:
	db $00, $64, $06, $80, $01
Sfx4_1F_Data_6D05:
	db $06, $00, $01
Sfx4_1F_Data_6D08:
	db $48, $00, $01
Sfx4_20_Init:
	ld hl, Sfx4_20_Data_6D2A
	jp Sfx4_Start

Sfx4_20_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_20_Data_6D26
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_20_Data_6D26:
	dw Sfx4_20_Data_6D2F, Sfx4_20_Data_6D32
Sfx4_20_Data_6D2A:
	db $00, $50, $0b, $80, $01
Sfx4_20_Data_6D2F:
	db $0c, $00, $01
Sfx4_20_Data_6D32:
	db $0b, $00, $01
Sfx4_22_Init:
	ld hl, Sfx4_22_Data_6D60
	jp Sfx4_StartPriority

Sfx4_22_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_22_Data_6D58
	call GetPointer
	ld a, [wSfx4Step]
	cp $01
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_22_Data_6D58:
	dw Sfx4_22_Data_6D65, Sfx4_22_Data_6D6A, Sfx4_22_Data_6D6D, Sfx4_22_Data_6D70
Sfx4_22_Data_6D60:
	db $00, $0f, $60, $80, $38
Sfx4_22_Data_6D65:
	db $00, $f6, $60, $80, $0c
Sfx4_22_Data_6D6A:
	db $61, $00, $0c
Sfx4_22_Data_6D6D:
	db $62, $00, $0c
Sfx4_22_Data_6D70:
	db $63, $00, $38
Sfx4_23_Init:
	ld hl, Sfx4_23_Data_6D8B
	jp Sfx4_StartPriority

Sfx4_23_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_23_Data_6D90
	jp SetRegs_Ch4

Sfx4_23_Data_6D8B:
	db $00, $0f, $a8, $80, $a0
Sfx4_23_Data_6D90:
	db $00, $f7, $a8, $80, $60
Sfx4_24_Init:
	ld hl, Sfx4_24_Data_6DAD
	jp Sfx4_Start

Sfx4_24_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_24_Data_6DB2
	jp SetRegs_Ch4

Sfx4_24_Data_6DAD:
	db $00, $29, $07, $80, $08
Sfx4_24_Data_6DB2:
	db $00, $a7, $05, $80, $50
Sfx4_25_Init:
	ld hl, Sfx4_25_Data_6E20
	jp Sfx4_StartPriority

Sfx4_25_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $24
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_25_Data_6DDA
	call GetPointer
	ld a, [wSfx4Step]
	cp $1e
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_25_Data_6DDA:
	dw Sfx4_25_Data_6E2B, Sfx4_25_Data_6E2E, Sfx4_25_Data_6E31, Sfx4_25_Data_6E2E, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E28, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E2E, Sfx4_25_Data_6E31, Sfx4_25_Data_6E2E, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E28, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E31, Sfx4_25_Data_6E34, Sfx4_25_Data_6E31, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E28, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E31, Sfx4_25_Data_6E34, Sfx4_25_Data_6E31, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E25, Sfx4_25_Data_6E2B, Sfx4_25_Data_6E2E, Sfx4_25_Data_6E31, Sfx4_25_Data_6E34, Sfx4_25_Data_6E37, Sfx4_25_Data_6E3A, Sfx4_25_Data_6E3F, Sfx4_25_Data_6E42, Sfx4_25_Data_6E45, Sfx4_25_Data_6E48, Sfx4_25_Data_6E4B
Sfx4_25_Data_6E20:
	db $00, $f0, $8c, $80, $5c
Sfx4_25_Data_6E25:
	db $8c, $00, $08
Sfx4_25_Data_6E28:
	db $8c, $00, $0c
Sfx4_25_Data_6E2B:
	db $7e, $00, $04
Sfx4_25_Data_6E2E:
	db $7c, $00, $04
Sfx4_25_Data_6E31:
	db $6e, $00, $04
Sfx4_25_Data_6E34:
	db $6d, $00, $04
Sfx4_25_Data_6E37:
	db $6c, $00, $04
Sfx4_25_Data_6E3A:
	db $00, $f7, $6b, $80, $0c
Sfx4_25_Data_6E3F:
	db $6c, $00, $0c
Sfx4_25_Data_6E42:
	db $6d, $00, $0c
Sfx4_25_Data_6E45:
	db $6e, $00, $0c
Sfx4_25_Data_6E48:
	db $7c, $00, $0c
Sfx4_25_Data_6E4B:
	db $7e, $00, $34
Sfx4_26_Init:
	ld a, $40
	ld [wSfx4Counter], a
	ld hl, Sfx4_26_Data_6E7C
	jp Sfx4_Start

Sfx4_26_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_26_Data_6E78
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_26_Data_6E78:
	dw Sfx4_26_Data_6E81, Sfx4_26_Data_6E84
Sfx4_26_Data_6E7C:
	db $00, $80, $3a, $80, $01
Sfx4_26_Data_6E81:
	db $39, $80, $02
Sfx4_26_Data_6E84:
	db $3a, $80, $01
Sfx4_27_Init:
	ld hl, Sfx4_27_Data_6EBA
	jp Sfx4_Start

Sfx4_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx4_Stop
	ld hl, Sfx4_27_Data_6EA2
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_27_Data_6EA2:
	dw Sfx4_27_Data_6EBF, Sfx4_27_Data_6EC2, Sfx4_27_Data_6EC5, Sfx4_27_Data_6EC2, Sfx4_27_Data_6EBF, Sfx4_27_Data_6EC8, Sfx4_27_Data_6ECB, Sfx4_27_Data_6ECE, Sfx4_27_Data_6ED1, Sfx4_27_Data_6ED4, Sfx4_27_Data_6ED7, Sfx4_27_Data_6EDA
Sfx4_27_Data_6EBA:
	db $00, $c2, $5d, $80, $01
Sfx4_27_Data_6EBF:
	db $5c, $00, $01
Sfx4_27_Data_6EC2:
	db $4f, $00, $01
Sfx4_27_Data_6EC5:
	db $4e, $00, $01
Sfx4_27_Data_6EC8:
	db $5d, $00, $01
Sfx4_27_Data_6ECB:
	db $5e, $00, $01
Sfx4_27_Data_6ECE:
	db $5f, $00, $01
Sfx4_27_Data_6ED1:
	db $6c, $00, $01
Sfx4_27_Data_6ED4:
	db $6d, $00, $01
Sfx4_27_Data_6ED7:
	db $6e, $00, $01
Sfx4_27_Data_6EDA:
	db $6f, $00, $10
Sfx4_28_Init:
	ld a, $05
	ld [wSfx4Counter], a
	ld hl, Sfx4_28_Data_6F1D
	jp Sfx4_Start

Sfx4_28_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jr z, .l0
.l1:
	ld hl, Sfx4_28_Data_6F07
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $04
	ld [bc], a
	jr .l1

Sfx4_28_Data_6F07:
	dw Sfx4_28_Data_6F25, Sfx4_28_Data_6F28, Sfx4_28_Data_6F2B, Sfx4_28_Data_6F2E, Sfx4_28_Data_6F2B, Sfx4_28_Data_6F28, Sfx4_28_Data_6F25, Sfx4_28_Data_6F22, Sfx4_28_Data_6F25, Sfx4_28_Data_6F28, Sfx4_28_Data_6F2B
Sfx4_28_Data_6F1D:
	db $00, $67, $6c, $80, $01
Sfx4_28_Data_6F22:
	db $6c, $00, $01
Sfx4_28_Data_6F25:
	db $6b, $00, $01
Sfx4_28_Data_6F28:
	db $6a, $00, $01
Sfx4_28_Data_6F2B:
	db $69, $00, $01
Sfx4_28_Data_6F2E:
	db $68, $00, $02
Sfx4_29_Init:
	ld a, $05
	ld [wSfx4Counter], a
	ld hl, Sfx4_29_Data_6F67
	jp Sfx4_StartPriority

Sfx4_29_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx4_29_Data_6F5B
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_29_Data_6F5B:
	dw Sfx4_29_Data_6F6C, Sfx4_29_Data_6F6F, Sfx4_29_Data_6F6C, Sfx4_29_Data_6F72, Sfx4_29_Data_6F6C, Sfx4_29_Data_6F75
Sfx4_29_Data_6F67:
	db $00, $f4, $68, $80, $02
Sfx4_29_Data_6F6C:
	db $6f, $00, $02
Sfx4_29_Data_6F6F:
	db $69, $00, $02
Sfx4_29_Data_6F72:
	db $6a, $00, $02
Sfx4_29_Data_6F75:
	db $68, $00, $02
Sfx4_2A_Init:
	ld a, $08
	ld [wSfx4Counter], a
	ld hl, Sfx4_2A_Data_6FBE
	jp Sfx4_StartPriority

Sfx4_2A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jr z, .l0
.l1:
	ld hl, Sfx4_2A_Data_6FAA
	call GetPointer
	ld a, [wSfx4Step]
	cp $01
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $02
	ld [bc], a
	jr .l1

Sfx4_2A_Data_6FAA:
	dw Sfx4_2E_Data_6FC3, Sfx4_2E_Data_6FC8, Sfx4_2E_Data_6FCE, Sfx4_2E_Data_6FD4, Sfx4_2E_Data_6FDA, Sfx4_2E_Data_6FD7, Sfx4_2E_Data_6FD4, Sfx4_2E_Data_6FD1, Sfx4_2E_Data_6FCE, Sfx4_2E_Data_6FCB
Sfx4_2A_Data_6FBE:
	db $00, $c0, $7f, $80, $88
Sfx4_2E_Data_6FC3:
	db $00, $f4, $6d, $80, $01
Sfx4_2E_Data_6FC8:
	db $74, $00, $01
Sfx4_2E_Data_6FCB:
	db $5f, $00, $01
Sfx4_2E_Data_6FCE:
	db $66, $00, $01
Sfx4_2E_Data_6FD1:
	db $5d, $00, $01
Sfx4_2E_Data_6FD4:
	db $64, $00, $01
Sfx4_2E_Data_6FD7:
	db $4f, $00, $01
Sfx4_2E_Data_6FDA:
	db $62, $00, $01
Sfx4_2B_Init:
	ld hl, Sfx4_2B_Data_6FEA
	jp Sfx4_Start

Sfx4_2B_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_2B_Data_6FEA:
	db $00, $f4, $7d, $80, $40
Sfx4_2C_Init:
	ld hl, Sfx4_2C_Data_7038
	jp Sfx4_Start

Sfx4_2C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_2C_Data_7012
	call GetPointer
	ld a, [wSfx4Step]
	cp $13
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_2C_Data_7012:
	dw Sfx4_2C_Data_703D, Sfx4_2C_Data_7040, Sfx4_2C_Data_7043, Sfx4_2C_Data_7046, Sfx4_2C_Data_7049, Sfx4_2C_Data_704C, Sfx4_2C_Data_704F, Sfx4_2C_Data_7052, Sfx4_2C_Data_7055, Sfx4_2C_Data_7058, Sfx4_2C_Data_705B, Sfx4_2C_Data_705E, Sfx4_2C_Data_7061, Sfx4_2C_Data_7064, Sfx4_2C_Data_7067, Sfx4_2C_Data_706A, Sfx4_2C_Data_706D, Sfx4_2C_Data_7070, Sfx4_2C_Data_7073
Sfx4_2C_Data_7038:
	db $26, $40, $37, $80, $06
Sfx4_2C_Data_703D:
	db $36, $80, $06
Sfx4_2C_Data_7040:
	db $35, $80, $06
Sfx4_2C_Data_7043:
	db $34, $80, $06
Sfx4_2C_Data_7046:
	db $27, $80, $06
Sfx4_2C_Data_7049:
	db $26, $80, $06
Sfx4_2C_Data_704C:
	db $25, $80, $06
Sfx4_2C_Data_704F:
	db $24, $80, $06
Sfx4_2C_Data_7052:
	db $17, $80, $06
Sfx4_2C_Data_7055:
	db $16, $80, $06
Sfx4_2C_Data_7058:
	db $15, $80, $06
Sfx4_2C_Data_705B:
	db $14, $80, $06
Sfx4_2C_Data_705E:
	db $07, $80, $06
Sfx4_2C_Data_7061:
	db $06, $00, $06
Sfx4_2C_Data_7064:
	db $05, $00, $06
Sfx4_2C_Data_7067:
	db $04, $00, $06
Sfx4_2C_Data_706A:
	db $03, $00, $06
Sfx4_2C_Data_706D:
	db $02, $00, $06
Sfx4_2C_Data_7070:
	db $01, $00, $06
Sfx4_2C_Data_7073:
	db $00, $47, $00, $80, $20
Sfx4_2D_Init:
	ld hl, Sfx4_2D_Data_70A1
	jp Sfx4_Start

Sfx4_2D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_2D_Data_7093
	call GetPointer
	jp SetRegs_Ch4

Sfx4_2D_Data_7093:
	dw Sfx4_2D_Data_70A6, Sfx4_2D_Data_70AB, Sfx4_2D_Data_70B0, Sfx4_2D_Data_70B5, Sfx4_2D_Data_70BA, Sfx4_2D_Data_70AB, Sfx4_2D_Data_70BF
Sfx4_2D_Data_70A1:
	db $26, $29, $40, $c0, $04
Sfx4_2D_Data_70A6:
	db $26, $10, $40, $c0, $02
Sfx4_2D_Data_70AB:
	db $26, $29, $10, $c0, $04
Sfx4_2D_Data_70B0:
	db $26, $10, $10, $c0, $02
Sfx4_2D_Data_70B5:
	db $26, $19, $60, $c0, $04
Sfx4_2D_Data_70BA:
	db $26, $10, $60, $c0, $02
Sfx4_2D_Data_70BF:
	db $26, $10, $10, $c0, $03
Sfx4_2E_Init:
	ld a, $08
	ld [wSfx4Counter], a
	ld hl, Sfx4_2E_Data_710C
	jp Sfx4_StartPriority

Sfx4_2E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jr z, .l0
.l1:
	ld hl, Sfx4_2E_Data_70F6
	call GetPointer
	ld a, [wSfx4Step]
	cp $02
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $03
	ld [bc], a
	jr .l1

Sfx4_2E_Data_70F6:
	dw Sfx4_2E_Data_7111, Sfx4_2E_Data_6FC3, Sfx4_2E_Data_6FC8, Sfx4_2E_Data_6FCE, Sfx4_2E_Data_6FD4, Sfx4_2E_Data_6FDA, Sfx4_2E_Data_6FD7, Sfx4_2E_Data_6FD4, Sfx4_2E_Data_6FD1, Sfx4_2E_Data_6FCE, Sfx4_2E_Data_6FCB
Sfx4_2E_Data_710C:
	db $00, $c0, $7f, $80, $ff
Sfx4_2E_Data_7111:
	db $7f, $80, $34
Sfx4_2F_Init:
	ld hl, Sfx4_2F_Data_712C
	jp Sfx4_Start

Sfx4_2F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_2F_Data_7131
	jp SetRegs_Ch4

Sfx4_2F_Data_712C:
	db $00, $19, $50, $80, $06
Sfx4_2F_Data_7131:
	db $00, $65, $50, $80, $20
Sfx4_30_Init:
	ld hl, Sfx4_30_Data_7195
	jp Sfx4_Start

Sfx4_30_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $23
	jp z, Sfx4_Stop
	ld hl, Sfx4_30_Data_7151
	call GetPointer
	jp SetRegs_Ch4

Sfx4_30_Data_7151:
	dw Sfx4_30_Data_719A, Sfx4_31_Data_71BD, Sfx4_30_Data_719F, Sfx4_31_Data_71BD, Sfx4_30_Data_71A4, Sfx4_31_Data_71BD, Sfx4_30_Data_71A9, Sfx4_31_Data_71BD, Sfx4_30_Data_71A9, Sfx4_31_Data_71BD, Sfx4_30_Data_71AE, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2, Sfx4_30_Data_71B8, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2, Sfx4_30_Data_71AE, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2, Sfx4_30_Data_71B8, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2, Sfx4_30_Data_71AE, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2, Sfx4_30_Data_71B8, Sfx4_31_Data_71C2, Sfx4_30_Data_71B3, Sfx4_31_Data_71C2
Sfx4_30_Data_7195:
	db $00, $1c, $60, $80, $18
Sfx4_30_Data_719A:
	db $00, $19, $50, $80, $0a
Sfx4_30_Data_719F:
	db $00, $19, $30, $80, $09
Sfx4_30_Data_71A4:
	db $00, $19, $40, $80, $07
Sfx4_30_Data_71A9:
	db $00, $19, $50, $80, $06
Sfx4_30_Data_71AE:
	db $00, $19, $60, $80, $06
Sfx4_30_Data_71B3:
	db $00, $19, $60, $80, $04
Sfx4_30_Data_71B8:
	db $00, $19, $50, $80, $02
Sfx4_31_Data_71BD:
	db $37, $40, $20, $c0, $02
Sfx4_31_Data_71C2:
	db $37, $20, $20, $c0, $02
Sfx4_31_Init:
	ld hl, Sfx4_31_Data_7216
	jp Sfx4_StartPriority

Sfx4_31_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1b
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_31_Data_71E2
	call GetPointer
	jp SetRegs_Ch4

Sfx4_31_Data_71E2:
	dw Sfx4_31_Data_721B, Sfx4_31_Data_71BD, Sfx4_31_Data_7220, Sfx4_31_Data_71BD, Sfx4_31_Data_7225, Sfx4_31_Data_71BD, Sfx4_31_Data_722A, Sfx4_31_Data_71BD, Sfx4_31_Data_722A, Sfx4_31_Data_71BD, Sfx4_31_Data_722F, Sfx4_31_Data_71C2, Sfx4_31_Data_7234, Sfx4_31_Data_71C2, Sfx4_31_Data_7239, Sfx4_31_Data_71C2, Sfx4_31_Data_7234, Sfx4_31_Data_71C2, Sfx4_31_Data_722F, Sfx4_31_Data_71C2, Sfx4_31_Data_7234, Sfx4_31_Data_71C2, Sfx4_31_Data_7239, Sfx4_31_Data_71C2, Sfx4_31_Data_7234, Sfx4_31_Data_71C2
Sfx4_31_Data_7216:
	db $00, $00, $00, $80, $20
Sfx4_31_Data_721B:
	db $00, $19, $27, $80, $0a
Sfx4_31_Data_7220:
	db $00, $19, $26, $80, $09
Sfx4_31_Data_7225:
	db $00, $19, $24, $80, $08
Sfx4_31_Data_722A:
	db $00, $19, $23, $80, $07
Sfx4_31_Data_722F:
	db $00, $19, $17, $80, $06
Sfx4_31_Data_7234:
	db $00, $19, $17, $80, $04
Sfx4_31_Data_7239:
	db $00, $19, $16, $80, $02
Sfx4_32_Init:
	ld hl, Sfx4_32_Data_726D
	jp Sfx4_Start

Sfx4_32_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx4_Stop
	ld hl, Sfx4_32_Data_7259
	call GetPointer
	jp SetRegs_Ch4

Sfx4_32_Data_7259:
	dw Sfx4_32_Data_7272, Sfx4_32_Data_7277, Sfx4_32_Data_727C, Sfx4_32_Data_7277, Sfx4_32_Data_7272, Sfx4_32_Data_726D, Sfx4_32_Data_7290, Sfx4_32_Data_728B, Sfx4_32_Data_7286, Sfx4_32_Data_7281
Sfx4_32_Data_726D:
	db $00, $20, $30, $80, $02
Sfx4_32_Data_7272:
	db $00, $40, $40, $80, $03
Sfx4_32_Data_7277:
	db $00, $80, $50, $80, $04
Sfx4_32_Data_727C:
	db $00, $c0, $60, $80, $05
Sfx4_32_Data_7281:
	db $37, $10, $30, $c0, $02
Sfx4_32_Data_7286:
	db $00, $10, $40, $80, $03
Sfx4_32_Data_728B:
	db $00, $10, $50, $80, $04
Sfx4_32_Data_7290:
	db $00, $10, $60, $80, $05
Sfx4_33_Init:
	ld hl, Sfx4_33_Data_72CE
	jp Sfx4_Start

Sfx4_33_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_33_Data_72B8
	call GetPointer
	ld a, [wSfx4Step]
	cp $06
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_33_Data_72B8:
	dw Sfx4_33_Data_72D6, Sfx4_33_Data_72D3, Sfx4_33_Data_72D9, Sfx4_33_Data_72D6, Sfx4_33_Data_72DC, Sfx4_33_Data_72DF, Sfx4_33_Data_72D6, Sfx4_33_Data_72D3, Sfx4_33_Data_72D9, Sfx4_33_Data_72D6, Sfx4_33_Data_72DC
Sfx4_33_Data_72CE:
	db $00, $80, $48, $80, $02
Sfx4_33_Data_72D3:
	db $49, $80, $02
Sfx4_33_Data_72D6:
	db $4a, $80, $02
Sfx4_33_Data_72D9:
	db $4b, $80, $02
Sfx4_33_Data_72DC:
	db $4c, $80, $02
Sfx4_33_Data_72DF:
	db $00, $20, $48, $80, $02
Sfx4_34_Init:
	ld a, $2b
	ld [$d3df], a
	ld a, $15
	ld [$d3e0], a
	ld hl, Sfx4_34_Data_7415
	jp Sfx4_Start

Sfx4_34_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jr z, .l0
	cp $0d
	jr z, .l1
	cp $1a
	jr z, .l2
	cp $52
	jp z, Sfx4_StopWithRegs
.l4:
	ld hl, Sfx4_34_Data_7373
	call GetPointer
	ld a, [wSfx4Step]
	cp $1a
	jp z, SetRegs_Ch4
	cp $22
	jp z, SetRegs_Ch4
	cp $2a
	jp z, SetRegs_Ch4
	cp $32
	jp z, SetRegs_Ch4
	cp $3a
	jp z, SetRegs_Ch4
	cp $42
	jp z, SetRegs_Ch4
	cp $4a
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

.l0:
	push de
	ld de, $d3df
	call Sfx_DecTimer
	pop de
	jr z, .l3
	ld a, $01
	ld [bc], a
	jr .l4

.l2:
	push de
	ld de, $d3e0
	call Sfx_DecTimer
	pop de
	jr z, .l5
	ld a, $12
	ld [bc], a
	jr .l4

.l3:
	ld a, $05
	ld [bc], a
	jr .l4

.l5:
	ld a, $1a
	ld [bc], a
	jr .l4

.l1:
	ld a, $20
	ld [wSfx3Request], a
	call Sfx3_Update
	ld bc, wSfx4Step
	ld de, wSfx4Timer
	jr .l4

Sfx4_34_Data_7373:
	dw Sfx4_34_Data_741A, Sfx4_34_Data_741D, Sfx4_34_Data_7420, Sfx4_34_Data_7423, Sfx4_34_Data_7426, Sfx4_34_Data_7429, Sfx4_34_Data_742C, Sfx4_34_Data_742F, Sfx4_34_Data_7432, Sfx4_34_Data_7435, Sfx4_34_Data_7438, Sfx4_34_Data_743B, Sfx4_34_Data_743E, Sfx4_34_Data_7441, Sfx4_34_Data_7444, Sfx4_34_Data_7447, Sfx4_34_Data_744A, Sfx4_34_Data_744D, Sfx4_34_Data_7450, Sfx4_34_Data_7453, Sfx4_34_Data_7456, Sfx4_34_Data_7459, Sfx4_34_Data_7456, Sfx4_34_Data_7453, Sfx4_34_Data_7450, Sfx4_34_Data_745C, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D+5, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D+10, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D+15, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D+20, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461, Sfx4_34_Data_746D+25, Sfx4_34_Data_7461, Sfx4_34_Data_7464, Sfx4_34_Data_7467, Sfx4_34_Data_746A, Sfx4_34_Data_7467, Sfx4_34_Data_7464, Sfx4_34_Data_7461
Sfx4_34_Data_7415:
	db $00, $80, $9c, $80, $01
Sfx4_34_Data_741A:
	db $8e, $00, $01
Sfx4_34_Data_741D:
	db $7e, $00, $01
Sfx4_34_Data_7420:
	db $8c, $00, $01
Sfx4_34_Data_7423:
	db $7c, $00, $01
Sfx4_34_Data_7426:
	db $6f, $00, $01
Sfx4_34_Data_7429:
	db $6d, $00, $01
Sfx4_34_Data_742C:
	db $5f, $00, $01
Sfx4_34_Data_742F:
	db $5d, $00, $01
Sfx4_34_Data_7432:
	db $4f, $00, $01
Sfx4_34_Data_7435:
	db $4d, $00, $01
Sfx4_34_Data_7438:
	db $3f, $00, $01
Sfx4_34_Data_743B:
	db $3d, $00, $01
Sfx4_34_Data_743E:
	db $37, $80, $02
Sfx4_34_Data_7441:
	db $35, $80, $02
Sfx4_34_Data_7444:
	db $27, $80, $02
Sfx4_34_Data_7447:
	db $25, $80, $02
Sfx4_34_Data_744A:
	db $17, $80, $02
Sfx4_34_Data_744D:
	db $15, $80, $02
Sfx4_34_Data_7450:
	db $14, $80, $02
Sfx4_34_Data_7453:
	db $07, $80, $02
Sfx4_34_Data_7456:
	db $06, $80, $02
Sfx4_34_Data_7459:
	db $05, $80, $02
Sfx4_34_Data_745C:
	db $00, $70, $15, $80, $02
Sfx4_34_Data_7461:
	db $14, $80, $02
Sfx4_34_Data_7464:
	db $07, $80, $02
Sfx4_34_Data_7467:
	db $06, $80, $02
Sfx4_34_Data_746A:
	db $05, $80, $02
Sfx4_34_Data_746D:
	db $00, $60, $15, $80, $02
	db $00, $50, $15, $80, $02
	db $00, $40, $15, $80, $02
	db $00, $30, $15, $80, $02
	db $00, $20, $15, $80, $02
	db $00, $10, $15, $80, $02
Sfx4_35_Init:
	ld a, $40
	ld [wSfx4Counter], a
	ld hl, Sfx4_35_Data_74EB
	jp Sfx4_Start

Sfx4_35_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $21
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_35_Data_74AB
	call GetPointer
	jp SetRegs_Ch4

Sfx4_35_Data_74AB:
	dw Sfx4_35_Data_74F0, Sfx4_35_Data_74F5, Sfx4_35_Data_74FA, Sfx4_35_Data_74FF, Sfx4_35_Data_7504, Sfx4_35_Data_7509, Sfx4_35_Data_750E, Sfx4_35_Data_7513, Sfx4_35_Data_7518, Sfx4_35_Data_751D, Sfx4_35_Data_7522, Sfx4_35_Data_7527, Sfx4_35_Data_752C, Sfx4_35_Data_7531, Sfx4_35_Data_7536, Sfx4_35_Data_753B, Sfx4_35_Data_7540, Sfx4_35_Data_7545, Sfx4_35_Data_754A, Sfx4_35_Data_754F, Sfx4_35_Data_7554, Sfx4_35_Data_7559, Sfx4_35_Data_755E, Sfx4_35_Data_7563, Sfx4_35_Data_7568, Sfx4_35_Data_756D, Sfx4_35_Data_7572, Sfx4_35_Data_7577, Sfx4_35_Data_757C, Sfx4_35_Data_7581, Sfx4_35_Data_7586, Sfx4_35_Data_758B
Sfx4_35_Data_74EB:
	db $00, $20, $67, $80, $02
Sfx4_35_Data_74F0:
	db $00, $20, $66, $80, $02
Sfx4_35_Data_74F5:
	db $00, $20, $65, $80, $02
Sfx4_35_Data_74FA:
	db $00, $20, $64, $80, $03
Sfx4_35_Data_74FF:
	db $00, $20, $57, $80, $03
Sfx4_35_Data_7504:
	db $00, $20, $56, $80, $03
Sfx4_35_Data_7509:
	db $00, $20, $55, $80, $04
Sfx4_35_Data_750E:
	db $00, $20, $54, $80, $04
Sfx4_35_Data_7513:
	db $00, $20, $47, $80, $04
Sfx4_35_Data_7518:
	db $00, $20, $46, $80, $05
Sfx4_35_Data_751D:
	db $00, $20, $45, $80, $05
Sfx4_35_Data_7522:
	db $00, $20, $44, $80, $05
Sfx4_35_Data_7527:
	db $00, $20, $37, $80, $06
Sfx4_35_Data_752C:
	db $00, $20, $36, $80, $06
Sfx4_35_Data_7531:
	db $00, $20, $35, $80, $06
Sfx4_35_Data_7536:
	db $00, $20, $34, $80, $08
Sfx4_35_Data_753B:
	db $00, $20, $27, $80, $08
Sfx4_35_Data_7540:
	db $00, $20, $26, $80, $0a
Sfx4_35_Data_7545:
	db $00, $20, $25, $80, $0a
Sfx4_35_Data_754A:
	db $00, $20, $24, $80, $0c
Sfx4_35_Data_754F:
	db $00, $20, $17, $80, $0c
Sfx4_35_Data_7554:
	db $00, $20, $16, $80, $0e
Sfx4_35_Data_7559:
	db $00, $20, $15, $80, $0e
Sfx4_35_Data_755E:
	db $00, $20, $14, $80, $10
Sfx4_35_Data_7563:
	db $00, $20, $07, $80, $10
Sfx4_35_Data_7568:
	db $00, $20, $06, $80, $12
Sfx4_35_Data_756D:
	db $00, $20, $05, $80, $12
Sfx4_35_Data_7572:
	db $00, $20, $04, $80, $14
Sfx4_35_Data_7577:
	db $00, $20, $03, $80, $14
Sfx4_35_Data_757C:
	db $00, $20, $02, $80, $16
Sfx4_35_Data_7581:
	db $00, $20, $01, $80, $16
Sfx4_35_Data_7586:
	db $00, $20, $00, $80, $18
Sfx4_35_Data_758B:
	db $00, $10, $00, $80, $20
Sfx4_36_Init:
	ld a, $07
	ld [wSfx4Counter], a
	ld hl, Sfx4_36_Data_75C6
	jp Sfx4_StartPriority

Sfx4_36_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx4_36_Data_75B6
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_36_Data_75B6:
	dw Sfx4_36_Data_75CB, Sfx4_36_Data_75CE, Sfx4_36_Data_75D1, Sfx4_36_Data_75D4, Sfx4_36_Data_75D7, Sfx4_36_Data_75D4, Sfx4_36_Data_75D1, Sfx4_36_Data_75CE
Sfx4_36_Data_75C6:
	db $00, $f4, $0f, $80, $01
Sfx4_36_Data_75CB:
	db $0e, $00, $01
Sfx4_36_Data_75CE:
	db $0d, $00, $01
Sfx4_36_Data_75D1:
	db $0c, $00, $01
Sfx4_36_Data_75D4:
	db $0b, $00, $01
Sfx4_36_Data_75D7:
	db $0a, $00, $01
Sfx4_37_Init:
	ld a, $07
	ld [wSfx4Counter], a
	call Sfx4_StartWithCh2
	ld hl, Sfx3_21_Data_6217
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx4_37_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx3_21_Data_6205
	jp Sfx2_AddPitch

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithCh2
	ld a, [bc]
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

Sfx4_39_Init:
	ld hl, Sfx4_39_Data_7647
	jp Sfx4_Start

Sfx4_39_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx4_Stop
	ld hl, Sfx4_39_Data_7625
	call GetPointer
	jp SetRegs_Ch4

Sfx4_39_Data_7625:
	dw Sfx4_39_Data_764C, Sfx4_39_Data_7651, Sfx4_39_Data_7656, Sfx4_39_Data_765B, Sfx4_39_Data_7660, Sfx4_39_Data_7665, Sfx4_39_Data_766A, Sfx4_39_Data_766F, Sfx4_39_Data_7674, Sfx4_39_Data_7679, Sfx4_39_Data_767E, Sfx4_39_Data_7683, Sfx4_39_Data_7688, Sfx4_39_Data_768D, Sfx4_39_Data_7692, Sfx4_39_Data_7697, Sfx4_39_Data_769C
Sfx4_39_Data_7647:
	db $00, $20, $0c, $80, $01
Sfx4_39_Data_764C:
	db $00, $40, $0d, $80, $01
Sfx4_39_Data_7651:
	db $00, $60, $0e, $80, $01
Sfx4_39_Data_7656:
	db $00, $80, $0f, $80, $01
Sfx4_39_Data_765B:
	db $00, $a0, $1c, $80, $01
Sfx4_39_Data_7660:
	db $00, $e0, $1d, $80, $01
Sfx4_39_Data_7665:
	db $00, $c0, $1e, $80, $02
Sfx4_39_Data_766A:
	db $00, $b0, $1f, $80, $02
Sfx4_39_Data_766F:
	db $00, $a0, $2c, $80, $02
Sfx4_39_Data_7674:
	db $00, $90, $2d, $80, $02
Sfx4_39_Data_7679:
	db $00, $80, $2e, $80, $02
Sfx4_39_Data_767E:
	db $00, $70, $2f, $80, $02
Sfx4_39_Data_7683:
	db $00, $60, $3c, $80, $02
Sfx4_39_Data_7688:
	db $00, $50, $3d, $80, $02
Sfx4_39_Data_768D:
	db $00, $40, $3e, $80, $02
Sfx4_39_Data_7692:
	db $00, $30, $3f, $80, $02
Sfx4_39_Data_7697:
	db $00, $20, $4c, $80, $02
Sfx4_39_Data_769C:
	db $37, $10, $4d, $c0, $02
Sfx4_38_Init:
	ld hl, Sfx4_38_Data_76D6
	jp Sfx4_Start

Sfx4_38_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0e
	jp z, Sfx4_Stop
	ld hl, Sfx4_38_Data_76BC
	call GetPointer
	jp SetRegs_Ch4

Sfx4_38_Data_76BC:
	dw Sfx4_38_Data_76DB, Sfx4_38_Data_76E0, Sfx4_38_Data_76E5, Sfx4_38_Data_76EA, Sfx4_38_Data_76EF, Sfx4_38_Data_76F4, Sfx4_38_Data_76F9, Sfx4_38_Data_76FE, Sfx4_38_Data_7703, Sfx4_38_Data_7708, Sfx4_38_Data_770D, Sfx4_38_Data_7712, Sfx4_38_Data_7717
Sfx4_38_Data_76D6:
	db $00, $30, $3d, $80, $02
Sfx4_38_Data_76DB:
	db $00, $60, $3f, $80, $02
Sfx4_38_Data_76E0:
	db $00, $90, $3d, $80, $02
Sfx4_38_Data_76E5:
	db $00, $c0, $3f, $80, $02
Sfx4_38_Data_76EA:
	db $00, $f0, $3d, $80, $02
Sfx4_38_Data_76EF:
	db $00, $d0, $3f, $80, $02
Sfx4_38_Data_76F4:
	db $00, $b0, $3d, $80, $02
Sfx4_38_Data_76F9:
	db $00, $90, $3f, $80, $02
Sfx4_38_Data_76FE:
	db $00, $70, $3d, $80, $03
Sfx4_38_Data_7703:
	db $00, $50, $3f, $80, $03
Sfx4_38_Data_7708:
	db $00, $40, $3d, $80, $04
Sfx4_38_Data_770D:
	db $00, $30, $3f, $80, $04
Sfx4_38_Data_7712:
	db $00, $20, $3d, $80, $04
Sfx4_38_Data_7717:
	db $2f, $10, $3f, $c0, $04
Sfx4_3A_Init:
	xor a
	ld [wSfx1Playing], a
	ld hl, wCh1Flags
	set 7, [hl]
	ld a, $01
	ld [wSfx1Priority], a
	ld hl, Sfx4_3A_Data_775E
	jp Sfx4_StartPriority

Sfx4_3A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
	ld hl, Sfx4_3A_Data_775A
	call GetPointer
	ld a, [wSfx4Step]
	cp $01
	jp z, SetRegs_Ch1
	jp SetRegs_Ch4

.l0:
	xor a
	ldh [rNR10], a
	ld [wSfx1Priority], a
	ld hl, wCh1Flags
	res 7, [hl]
	jp Sfx4_Stop

Sfx4_3A_Data_775A:
	dw Sfx4_3A_Data_7763, Sfx4_3A_Data_7769
Sfx4_3A_Data_775E:
	db $00, $20, $70, $80, $01
Sfx4_3A_Data_7763:
	db $1d, $51, $82, $59, $c7, $03
Sfx4_3A_Data_7769:
	db $00, $42, $50, $80, $08
Sfx4_3B_Init:
	xor a
	ld [wSfx1Playing], a
	ld hl, wCh1Flags
	set 7, [hl]
	ld a, $01
	ld [wSfx1Priority], a
	ld hl, Sfx4_3B_Data_77D6
	call Sfx4_StartPriority
	ld a, $f0
	ld [wSfx4Counter], a
	ld hl, Sfx4_3B_Data_77E0
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx4_3B_Play:
	ld hl, $d3e6
	ld a, [hl]
	and a
	jr z, Sfx4_3C_Init
	xor a
	ld [hl], a
	call Sfx4_DecCounter
	jr z, Sfx4_3C_Init
	cp $e0
	jr z, .l0
	cp $d8
	jr nc, .l1
	ld a, $02
.l2:
	ld [bc], a
	ld hl, Sfx4_3B_Data_77D2
	jp Sfx1_AddPitch

.l1:
	ld a, $01
	jr .l2

.l0:
	ld hl, Sfx4_3B_Data_77DB
	call SetRegs_Ch4
	ld a, $01
	ld bc, wSfx4Step
	jr .l2

Sfx4_3C_Init:
	xor a
	ld [wSfx1Priority], a
	ld hl, wCh1Flags
	res 7, [hl]
	ld hl, Sfx1_StopRegs
	call SetRegs_Ch1
	jp Sfx4_StopWithRegs

Sfx4_3B_Data_77D2:
	db $00, $02
	db $00, $00
Sfx4_3B_Data_77D6:
	db $00, $1d, $20, $80, $01
Sfx4_3B_Data_77DB:
	db $00, $60, $20, $80, $01
Sfx4_3B_Data_77E0:
	db $00, $40, $10, $a0, $87, $01
Sfx4_3D_Init:
	ld hl, Sfx4_3D_Data_78A3
	jp Sfx4_StartPriority

Sfx4_3D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $51
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_3D_Data_7801
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_3D_Data_7801:
	dw Sfx4_3D_Data_78A8, Sfx4_3D_Data_78AB, Sfx4_3D_Data_78AE, Sfx4_3D_Data_78B1, Sfx4_3D_Data_78B4, Sfx4_3D_Data_78B7, Sfx4_3D_Data_78B4, Sfx4_3D_Data_78B1, Sfx4_3D_Data_78AE, Sfx4_3D_Data_78B1, Sfx4_3D_Data_78B4, Sfx4_3D_Data_78B7, Sfx4_3D_Data_78BA, Sfx4_3D_Data_78BD, Sfx4_3D_Data_78C0, Sfx4_3D_Data_78BD, Sfx4_3D_Data_78BA, Sfx4_3D_Data_78B7, Sfx4_3D_Data_78BA, Sfx4_3D_Data_78BD, Sfx4_3D_Data_78C0, Sfx4_3D_Data_78C3, Sfx4_3D_Data_78C6, Sfx4_3D_Data_78C9, Sfx4_3D_Data_78C6, Sfx4_3D_Data_78C3, Sfx4_3D_Data_78C0, Sfx4_3D_Data_78C3, Sfx4_3D_Data_78C6, Sfx4_3D_Data_78C9, Sfx4_3D_Data_78CC, Sfx4_3D_Data_78CF, Sfx4_3D_Data_78D2, Sfx4_3D_Data_78CF, Sfx4_3D_Data_78CC, Sfx4_3D_Data_78C9, Sfx4_3D_Data_78CC, Sfx4_3D_Data_78CF, Sfx4_3D_Data_78D2, Sfx4_3D_Data_78D5, Sfx4_3D_Data_78D8, Sfx4_3D_Data_78D8+3, Sfx4_3D_Data_78D8, Sfx4_3D_Data_78D5, Sfx4_3D_Data_78D2, Sfx4_3D_Data_78D5, Sfx4_3D_Data_78D8, Sfx4_3D_Data_78D8+3, Sfx4_3D_Data_78D8+6, Sfx4_3D_Data_78D8+9, Sfx4_3D_Data_78D8+12, Sfx4_3D_Data_78D8+9, Sfx4_3D_Data_78D8+6, Sfx4_3D_Data_78D8+3, Sfx4_3D_Data_78D8+6, Sfx4_3D_Data_78D8+9, Sfx4_3D_Data_78D8+12, Sfx4_3D_Data_78D8+15, Sfx4_3D_Data_78D8+18, Sfx4_3D_Data_78D8+21, Sfx4_3D_Data_78D8+18, Sfx4_3D_Data_78D8+15, Sfx4_3D_Data_78D8+12, Sfx4_3D_Data_78D8+15, Sfx4_3D_Data_78D8+18, Sfx4_3D_Data_78D8+21, Sfx4_3D_Data_78D8+24, Sfx4_3D_Data_78D8+27, Sfx4_3D_Data_78D8+30, Sfx4_3D_Data_78D8+27, Sfx4_3D_Data_78D8+24, Sfx4_3D_Data_78D8+21, Sfx4_3D_Data_78D8+24, Sfx4_3D_Data_78D8+27, Sfx4_3D_Data_78D8+30, Sfx4_3D_Data_78D8+33, Sfx4_3D_Data_78D8+36, Sfx4_3D_Data_78D8+39, Sfx4_3D_Data_78D8+42, Sfx4_3D_Data_78D8+39, Sfx4_3D_Data_78D8+42
Sfx4_3D_Data_78A3:
	db $38, $80, $24, $80, $02
Sfx4_3D_Data_78A8:
	db $25, $80, $02
Sfx4_3D_Data_78AB:
	db $26, $80, $02
Sfx4_3D_Data_78AE:
	db $27, $80, $02
Sfx4_3D_Data_78B1:
	db $34, $80, $02
Sfx4_3D_Data_78B4:
	db $35, $80, $02
Sfx4_3D_Data_78B7:
	db $36, $80, $02
Sfx4_3D_Data_78BA:
	db $37, $80, $02
Sfx4_3D_Data_78BD:
	db $44, $80, $02
Sfx4_3D_Data_78C0:
	db $45, $80, $02
Sfx4_3D_Data_78C3:
	db $46, $80, $02
Sfx4_3D_Data_78C6:
	db $47, $80, $02
Sfx4_3D_Data_78C9:
	db $3c, $80, $03
Sfx4_3D_Data_78CC:
	db $3d, $80, $03
Sfx4_3D_Data_78CF:
	db $3e, $80, $03
Sfx4_3D_Data_78D2:
	db $3f, $80, $03
Sfx4_3D_Data_78D5:
	db $4c, $80, $03
Sfx4_3D_Data_78D8:
	db $4d, $80, $03
	db $4e, $80, $03
	db $4f, $80, $03
	db $5c, $80, $03
	db $5d, $80, $03
	db $5e, $80, $03
	db $5f, $80, $03
	db $6c, $80, $03
	db $6d, $c0, $03
	db $6e, $c0, $03
	db $6f, $c0, $03
	db $7c, $c0, $03
	db $7d, $c0, $03
	db $7e, $c0, $03
	db $7f, $c0, $03
Sfx4_3E_Init:
	ld hl, Sfx4_3E_Data_7933
	jp Sfx4_StartPriority

Sfx4_3E_Play:
	ld a, [$d3e8]
	and a
	ret nz
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_3E_Data_7925
	call GetPointer
	jp SetRegs_Ch4

Sfx4_3E_Data_7925:
	dw Sfx4_3E_Data_7938, Sfx4_3E_Data_793D, Sfx4_3E_Data_7942, Sfx4_3E_Data_7947, Sfx4_3E_Data_794C, Sfx4_3E_Data_7951, Sfx4_3E_Data_7956
Sfx4_3E_Data_7933:
	db $00, $1f, $7f, $80, $01
Sfx4_3E_Data_7938:
	db $00, $e0, $44, $80, $06
Sfx4_3E_Data_793D:
	db $00, $c0, $45, $80, $06
Sfx4_3E_Data_7942:
	db $00, $a0, $46, $80, $06
Sfx4_3E_Data_7947:
	db $00, $80, $47, $80, $06
Sfx4_3E_Data_794C:
	db $00, $60, $54, $80, $06
Sfx4_3E_Data_7951:
	db $00, $40, $55, $80, $06
Sfx4_3E_Data_7956:
	db $38, $20, $56, $c0, $06
Sfx4_3F_Init:
	ld hl, Sfx4_3F_Data_7994
	jp Sfx4_StartPriority

Sfx4_3F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx4_Stop
	ld hl, Sfx4_3F_Data_7976
	call GetPointer
	jp SetRegs_Ch4

Sfx4_3F_Data_7976:
	dw Sfx4_3F_Data_7999, Sfx4_3F_Data_799E, Sfx4_3F_Data_79A3, Sfx4_3F_Data_79A8, Sfx4_3F_Data_79AD, Sfx4_3F_Data_79B2, Sfx4_3F_Data_79B7, Sfx4_3F_Data_79BC, Sfx4_3F_Data_79C1, Sfx4_3F_Data_79C6, Sfx4_3F_Data_79CB, Sfx4_3F_Data_79D0, Sfx4_3F_Data_79D5, Sfx4_3F_Data_79DA, Sfx4_3F_Data_79DF
Sfx4_3F_Data_7994:
	db $00, $20, $27, $80, $02
Sfx4_3F_Data_7999:
	db $00, $40, $25, $80, $02
Sfx4_3F_Data_799E:
	db $00, $60, $17, $80, $02
Sfx4_3F_Data_79A3:
	db $00, $80, $15, $80, $02
Sfx4_3F_Data_79A8:
	db $00, $a0, $17, $80, $02
Sfx4_3F_Data_79AD:
	db $00, $c0, $25, $80, $04
Sfx4_3F_Data_79B2:
	db $00, $b0, $27, $80, $04
Sfx4_3F_Data_79B7:
	db $00, $a0, $25, $80, $04
Sfx4_3F_Data_79BC:
	db $00, $90, $17, $80, $04
Sfx4_3F_Data_79C1:
	db $00, $80, $15, $c0, $04
Sfx4_3F_Data_79C6:
	db $00, $70, $17, $80, $04
Sfx4_3F_Data_79CB:
	db $00, $60, $25, $80, $04
Sfx4_3F_Data_79D0:
	db $00, $50, $27, $80, $04
Sfx4_3F_Data_79D5:
	db $00, $40, $25, $80, $04
Sfx4_3F_Data_79DA:
	db $00, $30, $17, $80, $04
Sfx4_3F_Data_79DF:
	db $2f, $20, $15, $c0, $04
Sfx4_StartPriority:
	ld a, $01
	ld [wSfx4Priority], a
; Start a ch4 effect: hl = NR41-NR44 + frames.
Sfx4_Start:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	jp SetRegs_Ch4

Sfx4_StopWithRegs:
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
Sfx4_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld [wSfx4Counter], a
	ld [wSfx4Priority], a
	ld a, [wCh4Flags]
	res 7, a
	ld [wCh4Flags], a
	ret

Sfx4_StopRegs:
	db $00, $00, $00, $00, $01
Sfx4_WriteNR43:
	ld b, $02
	ld c, $22
	jp SetRegs_Copy

Sfx4_Refuse:
	xor a
	ld [wSfx4Request], a
	jp Sfx4_Update

; Start a ch4 effect that also takes ch2 away from the music (wCh2Flags bit 7).
Sfx4_StartWithCh2:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld a, $01
	ld [wSfx4Priority], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
	ret

Sfx4_StopWithCh2:
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld [wSfx4Playing], a
	ld [wSfx4Priority], a
	ld hl, wCh2Flags
	res 7, [hl]
	ret

