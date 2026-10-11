; Metal Slug 2 SFX: ch4 effects, bank $29 $6433-$799B

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
	jp .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	jr z, .none
	ld hl, Sfx4_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx4Timer
	ld bc, wSfx4Step
	jp hl

; MS2 replaced LA's low-health check (wLowHealthBeep, $C50E) with this ret; the
; request code after it is unreferenced.
.none:
	ret

Unused_LowHealthBeep:
	ld a, $1e
	ld [wSfx4Request], a
	jr Sfx4_Update

; same number in LA
Sfx4_01_Init:
	ld a, $01
	ld [wSfx4Playing], a
	ld hl, Sfx4_01_Data_6477
	jp SetRegs_Ch4

Sfx4_01_Play:
	xor a
	ld [wSfx4Playing], a
	ld hl, Sfx4_01_Data_647C
	jp SetRegs_Ch4

Sfx4_01_Data_6477:
	db $3b, $80, $07, $c0, $01
Sfx4_01_Data_647C:
	db $00, $42, $02, $c0, $04
; same number in LA
Sfx4_02_Init:
	ld hl, Sfx4_02_Data_64A8
	jp Sfx4_Start

Sfx4_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_02_Data_649C
	call GetPointer
	jp SetRegs_Ch4

Sfx4_02_Data_649C:
	dw Sfx4_02_Data_64AD, Sfx4_02_Data_64B2, Sfx4_02_Data_64B7, Sfx4_02_Data_64BC, Sfx4_02_Data_64C1, Sfx4_02_Data_64C6
Sfx4_02_Data_64A8:
	db $00, $40, $21, $80, $01
Sfx4_02_Data_64AD:
	db $00, $50, $22, $80, $01
Sfx4_02_Data_64B2:
	db $00, $60, $23, $80, $01
Sfx4_02_Data_64B7:
	db $00, $70, $24, $80, $01
Sfx4_02_Data_64BC:
	db $00, $80, $25, $80, $01
Sfx4_02_Data_64C1:
	db $00, $90, $26, $80, $01
Sfx4_02_Data_64C6:
	db $3c, $a0, $27, $c0, $01
; same number in LA
Sfx4_03_Init:
	ld hl, Sfx4_03_Data_6506
	jp Sfx4_Start

Sfx4_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $11
	jp z, Sfx1_Stop
	ld hl, Sfx4_03_Data_64E6
	call GetPointer
	jp SetRegs_Ch4

Sfx4_03_Data_64E6:
	dw Sfx4_03_Data_650B, Sfx4_03_Data_6510, Sfx4_03_Data_6515, Sfx4_03_Data_651A, Sfx4_03_Data_651F, Sfx4_03_Data_6524, Sfx4_03_Data_6529, Sfx4_03_Data_652E, Sfx4_03_Data_6529, Sfx4_03_Data_6524, Sfx4_03_Data_651F, Sfx4_03_Data_651A, Sfx4_03_Data_6515, Sfx4_03_Data_6510, Sfx4_03_Data_650B, Sfx4_03_Data_6506
Sfx4_03_Data_6506:
	db $37, $10, $04, $c0, $02
Sfx4_03_Data_650B:
	db $00, $20, $06, $80, $02
Sfx4_03_Data_6510:
	db $00, $30, $14, $80, $02
Sfx4_03_Data_6515:
	db $00, $40, $16, $80, $02
Sfx4_03_Data_651A:
	db $00, $50, $24, $80, $02
Sfx4_03_Data_651F:
	db $00, $60, $26, $80, $02
Sfx4_03_Data_6524:
	db $00, $70, $34, $80, $02
Sfx4_03_Data_6529:
	db $00, $80, $36, $80, $02
Sfx4_03_Data_652E:
	db $00, $90, $44, $80, $02
; same number in LA
Sfx4_04_Init:
	ld hl, Sfx4_04_Data_6554
	jp Sfx4_Start

Sfx4_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_StopWithCh2
	ld hl, Sfx4_04_Data_654E
	call GetPointer
	jp SetRegs_Ch4

Sfx4_04_Data_654E:
	dw Sfx4_04_Data_6559, Sfx4_04_Data_6554, Sfx4_04_Data_655E
Sfx4_04_Data_6554:
	db $3b, $c0, $3e, $c0, $01
Sfx4_04_Data_6559:
	db $33, $f0, $6e, $c0, $06
Sfx4_04_Data_655E:
	db $36, $70, $4e, $c0, $03
; same number in LA
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
	ld hl, Sfx4_05_Data_659D
	jp Sfx4_Start

Sfx4_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx4_05_Data_6595
	call GetPointer
	jp SetRegs_Ch4

Sfx4_05_Data_6595:
	dw Sfx4_05_Data_65A2, Sfx4_05_Data_65A7, Sfx4_05_Data_65AC, Sfx4_05_Data_65AC
Sfx4_05_Data_659D:
	db $30, $49, $60, $c0, $06
Sfx4_05_Data_65A2:
	db $30, $49, $40, $c0, $06
Sfx4_05_Data_65A7:
	db $30, $49, $20, $c0, $06
Sfx4_05_Data_65AC:
	db $30, $49, $00, $c0, $06
; same number in LA
Sfx4_06_Init:
	ld hl, Sfx4_06_Data_65D2
	jp Sfx4_Start

Sfx4_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx4_06_Data_65CC
	call GetPointer
	jp SetRegs_Ch4

Sfx4_06_Data_65CC:
	dw Sfx4_06_Data_65D7, Sfx4_06_Data_65DC, Sfx4_06_Data_65E1
Sfx4_06_Data_65D2:
	db $00, $61, $24, $80, $0c
Sfx4_06_Data_65D7:
	db $00, $51, $25, $80, $0c
Sfx4_06_Data_65DC:
	db $00, $32, $27, $80, $0c
Sfx4_06_Data_65E1:
	db $00, $22, $34, $80, $0c
; same number in LA
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
	ld hl, Sfx4_07_Data_661A
	jp Sfx4_Start

Sfx4_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx4_07_Data_661F
	jp SetRegs_Ch4

Sfx4_07_Data_661A:
	db $3b, $f0, $20, $c0, $02
Sfx4_07_Data_661F:
	db $39, $40, $20, $c0, $08
; same number in LA
Sfx4_08_Init:
	ld a, [wSfx4Playing]
	cp $0c
	jp z, Sfx4_Refuse
	ld a, $03
	ld [wSfx4Counter], a
	ld hl, Sfx4_08_Data_665C
	jp Sfx4_Start

Sfx4_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l1:
	ld hl, Sfx4_08_Data_6656
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_08_Data_6656:
	dw Sfx4_08_Data_6661, Sfx4_08_Data_6664, Sfx4_08_Data_6667
Sfx4_08_Data_665C:
	db $00, $a3, $3c, $80, $03
Sfx4_08_Data_6661:
	db $3d, $00, $03
Sfx4_08_Data_6664:
	db $3e, $00, $03
Sfx4_08_Data_6667:
	db $3f, $00, $03
; same number in LA
Sfx4_09_Init:
	ld hl, Sfx4_09_Data_6693
	jp Sfx4_Start

Sfx4_09_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $33
	ldh [rNR41], a
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx4_09_Data_6689
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_09_Data_6689:
	dw Sfx4_09_Data_6698, Sfx4_09_Data_669B, Sfx4_09_Data_669E, Sfx4_09_Data_66A1, Sfx4_09_Data_66A1
Sfx4_09_Data_6693:
	db $33, $a0, $72, $c0, $04
Sfx4_09_Data_6698:
	db $52, $c0, $04
Sfx4_09_Data_669B:
	db $50, $c0, $04
Sfx4_09_Data_669E:
	db $30, $c0, $04
Sfx4_09_Data_66A1:
	db $10, $c0, $04
; same number in LA
Sfx4_0A_Init:
	ld hl, Sfx4_0A_Data_66C7
	jp Sfx4_Start

Sfx4_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx4_0A_Data_66BF
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0A_Data_66BF:
	dw Sfx4_0A_Data_66CC, Sfx4_0A_Data_66D1, Sfx4_0A_Data_66CC, Sfx4_0A_Data_66C7
Sfx4_0A_Data_66C7:
	db $37, $40, $47, $c0, $01
Sfx4_0A_Data_66CC:
	db $00, $60, $27, $80, $02
Sfx4_0A_Data_66D1:
	db $00, $a0, $15, $80, $02
; same number in LA
Sfx4_0B_Init:
	ld hl, Sfx4_0B_Data_66EE
	jp Sfx4_Start

Sfx4_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx4_0B_Data_66F3
	jp SetRegs_Ch3

Sfx4_0B_Data_66EE:
	db $3c, $c0, $18, $c0, $01
Sfx4_0B_Data_66F3:
	db $3c, $60, $18, $c0, $02
; same number in LA
Sfx4_0C_Init:
	ld a, [wSfx4Playing]
	cp $02
	jp z, Sfx4_Refuse
	cp $03
	jp z, Sfx4_Refuse
	ld hl, Sfx4_0C_Data_6720
	jp Sfx4_Start

Sfx4_0C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx4_0C_Data_6728
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_0C_Data_6720:
	db $2d, $67, $30, $67, $33
	db $67, $36, $67
Sfx4_0C_Data_6728:
	db $00, $c6, $6a
	db $80, $04, $6b
	db $00, $05, $6c
	db $00, $06, $6d
	db $00, $07, $6e
	db $00, $38
; same number in LA
Sfx4_0D_Init:
	ld a, $0e
	ld [wSfx4Counter], a
	ld hl, Sfx4_0D_Data_6767
	jp Sfx4_Start

Sfx4_0D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_0D_Data_6763
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_0D_Data_6763:
	dw Sfx4_0D_Data_676C, Sfx4_0D_Data_676F
Sfx4_0D_Data_6767:
	db $00, $67, $0f, $80, $02
Sfx4_0D_Data_676C:
	db $60, $00, $02
Sfx4_0D_Data_676F:
	db $0f, $00, $02
; same number in LA
Sfx4_0E_Init:
	ld hl, Sfx4_0E_Data_6791
	jp Sfx4_Start

Sfx4_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx4_0E_Data_678D
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0E_Data_678D:
	dw Sfx4_0E_Data_6796, Sfx4_0E_Data_679B
Sfx4_0E_Data_6791:
	db $1e, $29, $46, $c0, $10
Sfx4_0E_Data_6796:
	db $00, $29, $64, $80, $08
Sfx4_0E_Data_679B:
	db $00, $81, $64, $80, $06
; same number in LA
Sfx4_0F_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld hl, Sfx4_0F_Data_67C6
	jp Sfx4_Start

Sfx4_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx4_0F_Data_67C2
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0F_Data_67C2:
	dw Sfx4_0F_Data_67CB, Sfx4_0F_Data_67D0
Sfx4_0F_Data_67C6:
	db $00, $0f, $30, $80, $20
Sfx4_0F_Data_67CB:
	db $00, $60, $03, $80, $30
Sfx4_0F_Data_67D0:
	db $00, $67, $03, $80, $20
; same number in LA
Sfx4_10_Init:
	ld a, $03
	ld [wSfx4Counter], a
	ld hl, Sfx4_10_Data_6816
	jp Sfx4_Start

Sfx4_10_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jr z, .l0
	ld hl, Sfx4_10_Data_680C
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	cp $01
	jr z, .l1
	ld hl, Sfx4_10_Data_682A
.l2:
	ld a, $01
	ld [bc], a
	jp SetRegs_Ch4

.l1:
	ld hl, Sfx4_10_Data_682F
	jr .l2

Sfx4_10_Data_680C:
	dw Sfx4_10_Data_681B, Sfx4_10_Data_681E, Sfx4_10_Data_6821, Sfx4_10_Data_6824, Sfx4_10_Data_6827
Sfx4_10_Data_6816:
	db $00, $e0, $48, $80, $01
Sfx4_10_Data_681B:
	db $4b, $00, $01
Sfx4_10_Data_681E:
	db $5e, $00, $01
Sfx4_10_Data_6821:
	db $5d, $00, $02
Sfx4_10_Data_6824:
	db $6c, $00, $02
Sfx4_10_Data_6827:
	db $6f, $00, $02
Sfx4_10_Data_682A:
	db $00, $70, $4b, $80, $01
Sfx4_10_Data_682F:
	db $00, $20, $4b, $80, $01
; same number in LA
Sfx4_11_Init:
	ld hl, Sfx4_11_Data_6841
	jp Sfx4_Start

Sfx4_11_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_StopWithRegs

Sfx4_11_Data_6841:
	db $00, $f0, $a0, $80, $20
; same number in LA
Sfx4_12_Init:
	ld hl, Sfx4_12_Data_686F
	jp Sfx4_Start

Sfx4_12_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_12_Data_6861
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_12_Data_6861:
	dw Sfx4_12_Data_6874, Sfx4_12_Data_6877, Sfx4_12_Data_687A, Sfx4_12_Data_6877, Sfx4_12_Data_6874, Sfx4_12_Data_687D, Sfx4_12_Data_6880
Sfx4_12_Data_686F:
	db $00, $69, $b8, $80, $02
Sfx4_12_Data_6874:
	db $a8, $00, $02
Sfx4_12_Data_6877:
	db $98, $00, $02
Sfx4_12_Data_687A:
	db $88, $00, $02
Sfx4_12_Data_687D:
	db $b8, $00, $02
Sfx4_12_Data_6880:
	db $c8, $00, $02
; same number in LA
Sfx4_13_Init:
	ld hl, Sfx4_13_Data_68E0
	jp Sfx4_Start

Sfx4_13_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1a
	jp z, Sfx1_Stop
	ld hl, Sfx4_13_Data_68AE
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

Sfx4_13_Data_68AE:
	dw Sfx4_13_Data_68E5, Sfx4_13_Data_68EA, Sfx4_13_Data_68EF, Sfx4_13_Data_68F4, Sfx4_13_Data_68F9, Sfx4_13_Data_68FE, Sfx4_13_Data_6903, Sfx4_13_Data_6908, Sfx4_13_Data_6903, Sfx4_13_Data_68FE, Sfx4_13_Data_68F9, Sfx4_13_Data_68F4, Sfx4_13_Data_68EF, Sfx4_13_Data_68EA, Sfx4_13_Data_68E5, Sfx4_13_Data_68E0, Sfx4_13_Data_6908, Sfx4_13_Data_6903, Sfx4_13_Data_68FE, Sfx4_13_Data_68F9, Sfx4_13_Data_68F4, Sfx4_13_Data_68EF, Sfx4_13_Data_68EA, Sfx4_13_Data_68E5, Sfx4_13_Data_68E0
Sfx4_13_Data_68E0:
	db $37, $20, $25, $c0, $01
Sfx4_13_Data_68E5:
	db $00, $40, $27, $80, $01
Sfx4_13_Data_68EA:
	db $00, $60, $35, $80, $01
Sfx4_13_Data_68EF:
	db $00, $80, $37, $80, $01
Sfx4_13_Data_68F4:
	db $00, $a0, $4d, $80, $02
Sfx4_13_Data_68F9:
	db $00, $b0, $4f, $80, $02
Sfx4_13_Data_68FE:
	db $00, $c0, $5d, $80, $02
Sfx4_13_Data_6903:
	db $00, $d0, $5f, $80, $02
Sfx4_13_Data_6908:
	db $00, $e0, $6d, $80, $02
; same number in LA
Sfx4_14_Init:
	ld hl, Sfx4_14_Data_6930
	jp Sfx4_Start

Sfx4_14_Play:
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_14_Data_6924
	call GetPointer
	jp SetRegs_Ch4

Sfx4_14_Data_6924:
	dw Sfx4_14_Data_6935, Sfx4_14_Data_693A, Sfx4_14_Data_693F, Sfx4_14_Data_6944, Sfx4_14_Data_6949, Sfx4_14_Data_694E
Sfx4_14_Data_6930:
	db $00, $40, $5f, $80, $01
Sfx4_14_Data_6935:
	db $00, $50, $5d, $80, $01
Sfx4_14_Data_693A:
	db $00, $60, $4f, $80, $01
Sfx4_14_Data_693F:
	db $00, $70, $4d, $80, $01
Sfx4_14_Data_6944:
	db $00, $80, $3f, $80, $01
Sfx4_14_Data_6949:
	db $00, $90, $3c, $80, $01
Sfx4_14_Data_694E:
	db $3c, $a0, $2e, $c0, $01
; same number in LA
Sfx4_15_Init:
	ld hl, Sfx4_15_Data_6974
	jp Sfx4_Start

Sfx4_15_Play:
	call Sfx_IncStep
	cp $06
	jp z, Sfx4_Stop
	ld hl, Sfx4_15_Data_696A
	call GetPointer
	jp SetRegs_Ch4

Sfx4_15_Data_696A:
	dw Sfx4_15_Data_6979, Sfx4_15_Data_697E, Sfx4_15_Data_6983, Sfx4_15_Data_6988, Sfx4_15_Data_698D
Sfx4_15_Data_6974:
	db $00, $20, $47, $80, $02
Sfx4_15_Data_6979:
	db $00, $40, $37, $80, $01
Sfx4_15_Data_697E:
	db $00, $60, $27, $80, $01
Sfx4_15_Data_6983:
	db $00, $80, $17, $80, $01
Sfx4_15_Data_6988:
	db $00, $a0, $07, $80, $01
Sfx4_15_Data_698D:
	db $3c, $c0, $03, $c0, $01
; same number in LA
Sfx4_16_Init:
	ld a, [wSfx4Playing]
	cp $03
	jp z, Sfx4_Refuse
	ld hl, Sfx4_16_Data_69B5
	jp Sfx4_Start

Sfx4_16_Play:
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_16_Data_69B1
	call GetPointer
	jp SetRegs_Ch4

Sfx4_16_Data_69B1:
	dw Sfx4_16_Data_69BA, Sfx4_16_Data_69BF
Sfx4_16_Data_69B5:
	db $00, $29, $68, $80, $10
Sfx4_16_Data_69BA:
	db $3c, $c0, $50, $c0, $01
Sfx4_16_Data_69BF:
	db $3c, $c1, $18, $c0, $01
; same number in LA
Sfx4_17_Init:
	ld hl, Sfx4_17_Data_69DC
	jp Sfx4_Start

Sfx4_17_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_17_Data_69E1
	jp SetRegs_Ch3

Sfx4_17_Data_69DC:
	db $00, $f1, $09, $80, $0e
Sfx4_17_Data_69E1:
	db $00, $62, $09, $80, $10
; same number in LA
Sfx4_18_Init:
	ld hl, Sfx4_18_Data_6A0D
	jp Sfx4_Start

Sfx4_18_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_Stop
	ld hl, Sfx4_18_Data_6A01
	call GetPointer
	jp SetRegs_Ch4

Sfx4_18_Data_6A01:
	dw Sfx4_18_Data_6A12, Sfx4_18_Data_6A17, Sfx4_18_Data_6A1C, Sfx4_18_Data_6A21, Sfx4_18_Data_6A26, Sfx4_18_Data_6A2B
Sfx4_18_Data_6A0D:
	db $00, $20, $11, $80, $01
Sfx4_18_Data_6A12:
	db $00, $40, $21, $80, $01
Sfx4_18_Data_6A17:
	db $00, $60, $39, $80, $01
Sfx4_18_Data_6A1C:
	db $00, $80, $49, $80, $01
Sfx4_18_Data_6A21:
	db $00, $a0, $4b, $80, $01
Sfx4_18_Data_6A26:
	db $00, $c0, $4d, $80, $01
Sfx4_18_Data_6A2B:
	db $3c, $e0, $4f, $c0, $01
; same number in LA
Sfx4_19_Init:
	ld hl, Sfx4_19_Data_6A5F
	jp Sfx4_Start

Sfx4_19_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx4_Stop
	ld hl, Sfx4_19_Data_6A4B
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_19_Data_6A4B:
	dw Sfx4_19_Data_6A64, Sfx4_19_Data_6A67, Sfx4_19_Data_6A6A, Sfx4_19_Data_6A6D, Sfx4_19_Data_6A70, Sfx4_19_Data_6A6D, Sfx4_19_Data_6A6A, Sfx4_19_Data_6A67, Sfx4_19_Data_6A64, Sfx4_19_Data_6A73
Sfx4_19_Data_6A5F:
	db $00, $67, $2c, $80, $01
Sfx4_19_Data_6A64:
	db $3c, $00, $01
Sfx4_19_Data_6A67:
	db $4c, $00, $01
Sfx4_19_Data_6A6A:
	db $5c, $00, $01
Sfx4_19_Data_6A6D:
	db $6c, $00, $01
Sfx4_19_Data_6A70:
	db $7c, $00, $01
Sfx4_19_Data_6A73:
	db $09, $80, $30
; same number in LA
Sfx4_1A_Init:
	ld hl, Sfx4_1A_Data_6ABB
	jp Sfx4_StartPriority

Sfx4_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $16
	jp z, Sfx4_Stop
	ld hl, Sfx4_1A_Data_6A91
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_1A_Data_6A91:
	dw Sfx4_1A_Data_6AC0, Sfx4_1A_Data_6AC3, Sfx4_1A_Data_6AC6, Sfx4_1A_Data_6AC9, Sfx4_1A_Data_6ACC, Sfx4_1A_Data_6AC9, Sfx4_1A_Data_6AC6, Sfx4_1A_Data_6AC3, Sfx4_1A_Data_6AC6, Sfx4_1A_Data_6AC9, Sfx4_1A_Data_6ACC, Sfx4_1A_Data_6ACF, Sfx4_1A_Data_6AD2, Sfx4_1A_Data_6ACF, Sfx4_1A_Data_6ACC, Sfx4_1A_Data_6AC9, Sfx4_1A_Data_6ACC, Sfx4_1A_Data_6ACF, Sfx4_1A_Data_6AD2, Sfx4_1A_Data_6AD5, Sfx4_1A_Data_6AD8
Sfx4_1A_Data_6ABB:
	db $00, $f7, $3d, $80, $04
Sfx4_1A_Data_6AC0:
	db $60, $00, $04
Sfx4_1A_Data_6AC3:
	db $61, $00, $04
Sfx4_1A_Data_6AC6:
	db $62, $00, $04
Sfx4_1A_Data_6AC9:
	db $63, $00, $04
Sfx4_1A_Data_6ACC:
	db $64, $00, $04
Sfx4_1A_Data_6ACF:
	db $65, $00, $04
Sfx4_1A_Data_6AD2:
	db $66, $00, $04
Sfx4_1A_Data_6AD5:
	db $67, $00, $04
Sfx4_1A_Data_6AD8:
	db $74, $00, $28
; same number in LA
Sfx4_1B_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld a, [wSfx1Var2]
	and a
	jr nz, .l0
	ld hl, Sfx4_1B_Data_6B39
.l1:
	jp Sfx4_Start

.l0:
	ld hl, Sfx4_1B_Data_6B4D
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
	ld hl, Sfx4_1B_Data_6B2B
.l5:
	ld a, [bc]
	call GetPointer
	jp SetRegs_Ch4

.l4:
	ld hl, Sfx4_1B_Data_6B35
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

Sfx4_1B_Data_6B2B:
	dw Sfx4_1B_Data_6B43, Sfx4_1B_Data_6B3E, Sfx4_1B_Data_6B48, Sfx4_1B_Data_6B3E, Sfx4_1B_Data_6B48
Sfx4_1B_Data_6B35:
	dw Sfx4_1B_Data_6B52, Sfx4_1B_Data_6B52
Sfx4_1B_Data_6B39:
	db $37, $61, $30, $80, $03
Sfx4_1B_Data_6B3E:
	db $37, $41, $14, $80, $03
Sfx4_1B_Data_6B43:
	db $37, $20, $30, $c0, $02
Sfx4_1B_Data_6B48:
	db $37, $20, $14, $c0, $02
Sfx4_1B_Data_6B4D:
	db $37, $a1, $30, $80, $04
Sfx4_1B_Data_6B52:
	db $37, $51, $14, $80, $04
; same number in LA
Sfx4_1C_Init:
	ld a, $06
	ld [wSfx4Counter], a
	ld hl, Sfx4_1C_Data_6B85
	jp Sfx4_Start

Sfx4_1C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_1C_Data_6B81
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_1C_Data_6B81:
	dw Sfx4_1C_Data_6B8A, Sfx4_1C_Data_6B8D
Sfx4_1C_Data_6B85:
	db $00, $c0, $58, $80, $02
Sfx4_1C_Data_6B8A:
	db $68, $80, $02
Sfx4_1C_Data_6B8D:
	db $58, $80, $02
; same number in LA
Sfx4_1D_Init:
	ld a, $78
	ld [wSfx4Counter], a
	ld hl, Sfx4_1D_Data_6BCB
	jp Sfx4_StartPriority

Sfx4_1D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx4_1D_Data_6BC7
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
	ld hl, Sfx4_1D_Data_6BD0
	jp SetRegs_Ch4

Sfx4_1D_Data_6BC7:
	dw Sfx4_1D_Data_6BD5, Sfx4_1D_Data_6BD8
Sfx4_1D_Data_6BCB:
	db $00, $2c, $7c, $80, $02
Sfx4_1D_Data_6BD0:
	db $00, $f7, $7c, $80, $02
Sfx4_1D_Data_6BD5:
	db $7d, $00, $02
Sfx4_1D_Data_6BD8:
	db $7c, $00, $02
; same number in LA
Sfx4_1E_Init:
	ld a, [wSfx4Playing]
	and a
	jp nz, Sfx4_Refuse
	ld hl, Sfx4_1E_Data_6BF1
	jp Sfx4_Start

Sfx4_1E_Play:
	ld hl, Sfx4_1E_Data_6BF6
	call SetRegs_Ch4
	jp Sfx4_Stop

Sfx4_1E_Data_6BF1:
	db $08, $60, $00, $c0, $0c
Sfx4_1E_Data_6BF6:
	db $00, $67, $00, $00, $20
; same number in LA
Sfx4_1F_Init:
	ld a, $14
	ld [wSfx4Counter], a
	ld hl, Sfx4_1F_Data_6C32
	jp Sfx4_Start

Sfx4_1F_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx4_1F_Data_6C2E
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
	ld hl, Sfx4_1F_Data_6C37
	jp SetRegs_Ch4

Sfx4_1F_Data_6C2E:
	dw Sfx4_1F_Data_6C3C, Sfx4_1F_Data_6C3F
Sfx4_1F_Data_6C32:
	db $00, $1a, $06, $80, $01
Sfx4_1F_Data_6C37:
	db $00, $64, $06, $80, $01
Sfx4_1F_Data_6C3C:
	db $06, $00, $01
Sfx4_1F_Data_6C3F:
	db $48, $00, $01
; same number in LA
Sfx4_20_Init:
	ld hl, Sfx4_20_Data_6C61
	jp Sfx4_Start

Sfx4_20_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_20_Data_6C5D
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_20_Data_6C5D:
	dw Sfx4_20_Data_6C66, Sfx4_20_Data_6C69
Sfx4_20_Data_6C61:
	db $00, $50, $0b, $80, $01
Sfx4_20_Data_6C66:
	db $0c, $00, $01
Sfx4_20_Data_6C69:
	db $0b, $00, $01
; = LA Sfx4_22
Sfx4_21_Init:
	ld hl, Sfx4_21_Data_6C97
	jp Sfx4_StartPriority

Sfx4_21_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_21_Data_6C8F
	call GetPointer
	ld a, [wSfx4Step]
	cp $01
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_21_Data_6C8F:
	dw Sfx4_21_Data_6C9C, Sfx4_21_Data_6CA1, Sfx4_21_Data_6CA4, Sfx4_21_Data_6CA7
Sfx4_21_Data_6C97:
	db $00, $0f, $60, $80, $38
Sfx4_21_Data_6C9C:
	db $00, $f6, $60, $80, $0c
Sfx4_21_Data_6CA1:
	db $61, $00, $0c
Sfx4_21_Data_6CA4:
	db $62, $00, $0c
Sfx4_21_Data_6CA7:
	db $63, $00, $38
; = LA Sfx4_23
Sfx4_22_Init:
	ld hl, Sfx4_22_Data_6CC2
	jp Sfx4_StartPriority

Sfx4_22_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_22_Data_6CC7
	jp SetRegs_Ch4

Sfx4_22_Data_6CC2:
	db $00, $0f, $a8, $80, $a0
Sfx4_22_Data_6CC7:
	db $00, $f7, $a8, $80, $60
; = LA Sfx4_24
Sfx4_23_Init:
	ld hl, Sfx4_23_Data_6CE4
	jp Sfx4_Start

Sfx4_23_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_23_Data_6CE9
	jp SetRegs_Ch4

Sfx4_23_Data_6CE4:
	db $00, $29, $07, $80, $08
Sfx4_23_Data_6CE9:
	db $00, $a7, $05, $80, $50
; = LA Sfx4_25
Sfx4_24_Init:
	ld hl, Sfx4_24_Data_6D57
	jp Sfx4_StartPriority

Sfx4_24_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $24
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_24_Data_6D11
	call GetPointer
	ld a, [wSfx4Step]
	cp $1e
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_24_Data_6D11:
	dw Sfx4_24_Data_6D62, Sfx4_24_Data_6D65, Sfx4_24_Data_6D68, Sfx4_24_Data_6D65, Sfx4_24_Data_6D62, Sfx4_24_Data_6D5F, Sfx4_24_Data_6D62, Sfx4_24_Data_6D65, Sfx4_24_Data_6D68, Sfx4_24_Data_6D65, Sfx4_24_Data_6D62, Sfx4_24_Data_6D5F, Sfx4_24_Data_6D62, Sfx4_24_Data_6D68, Sfx4_24_Data_6D6B, Sfx4_24_Data_6D68, Sfx4_24_Data_6D62, Sfx4_24_Data_6D5F, Sfx4_24_Data_6D62, Sfx4_24_Data_6D68, Sfx4_24_Data_6D6B, Sfx4_24_Data_6D68, Sfx4_24_Data_6D62, Sfx4_24_Data_6D5C, Sfx4_24_Data_6D62, Sfx4_24_Data_6D65, Sfx4_24_Data_6D68, Sfx4_24_Data_6D6B, Sfx4_24_Data_6D6E, Sfx4_24_Data_6D71, Sfx4_24_Data_6D76, Sfx4_24_Data_6D79, Sfx4_24_Data_6D7C, Sfx4_24_Data_6D7F, Sfx4_24_Data_6D82
Sfx4_24_Data_6D57:
	db $00, $f0, $8c, $80, $5c
Sfx4_24_Data_6D5C:
	db $8c, $00, $08
Sfx4_24_Data_6D5F:
	db $8c, $00, $0c
Sfx4_24_Data_6D62:
	db $7e, $00, $04
Sfx4_24_Data_6D65:
	db $7c, $00, $04
Sfx4_24_Data_6D68:
	db $6e, $00, $04
Sfx4_24_Data_6D6B:
	db $6d, $00, $04
Sfx4_24_Data_6D6E:
	db $6c, $00, $04
Sfx4_24_Data_6D71:
	db $00, $f7, $6b, $80, $0c
Sfx4_24_Data_6D76:
	db $6c, $00, $0c
Sfx4_24_Data_6D79:
	db $6d, $00, $0c
Sfx4_24_Data_6D7C:
	db $6e, $00, $0c
Sfx4_24_Data_6D7F:
	db $7c, $00, $0c
Sfx4_24_Data_6D82:
	db $7e, $00, $34
; = LA Sfx4_26
Sfx4_25_Init:
	ld a, $40
	ld [wSfx4Counter], a
	ld hl, Sfx4_25_Data_6DB3
	jp Sfx4_Start

Sfx4_25_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx4_25_Data_6DAF
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_25_Data_6DAF:
	dw Sfx4_25_Data_6DB8, Sfx4_25_Data_6DBB
Sfx4_25_Data_6DB3:
	db $00, $80, $3a, $80, $01
Sfx4_25_Data_6DB8:
	db $39, $80, $02
Sfx4_25_Data_6DBB:
	db $3a, $80, $01
; = LA Sfx4_27
Sfx4_26_Init:
	ld hl, Sfx4_26_Data_6DD9
	jp Sfx4_Start

Sfx4_26_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx4_Stop
	ld hl, Sfx4_26_Data_6DF1
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_26_Data_6DD9:
	db $f6, $6d, $f9, $6d, $fc
	db $6d, $f9, $6d, $f6, $6d
	db $ff, $6d, $02, $6e, $05
	db $6e, $08, $6e, $0b, $6e
	db $0e, $6e, $11, $6e
Sfx4_26_Data_6DF1:
	db $00, $c2, $5d
	db $80, $01, $5c
	db $00, $01, $4f
	db $00, $01, $4e
	db $00, $01, $5d
	db $00, $01, $5e
	db $00, $01, $5f
	db $00, $01, $6c
	db $00, $01, $6d
	db $00, $01, $6e
	db $00, $01, $6f
	db $00, $10
; = LA Sfx4_28
Sfx4_27_Init:
	ld a, $05
	ld [wSfx4Counter], a
	ld hl, Sfx4_27_Data_6E54
	jp Sfx4_Start

Sfx4_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jr z, .l0
.l1:
	ld hl, Sfx4_27_Data_6E3E
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $04
	ld [bc], a
	jr .l1

Sfx4_27_Data_6E3E:
	dw Sfx4_27_Data_6E5C, Sfx4_27_Data_6E5F, Sfx4_27_Data_6E62, Sfx4_27_Data_6E65, Sfx4_27_Data_6E62, Sfx4_27_Data_6E5F, Sfx4_27_Data_6E5C, Sfx4_27_Data_6E59, Sfx4_27_Data_6E5C, Sfx4_27_Data_6E5F, Sfx4_27_Data_6E62
Sfx4_27_Data_6E54:
	db $00, $67, $6c, $80, $01
Sfx4_27_Data_6E59:
	db $6c, $00, $01
Sfx4_27_Data_6E5C:
	db $6b, $00, $01
Sfx4_27_Data_6E5F:
	db $6a, $00, $01
Sfx4_27_Data_6E62:
	db $69, $00, $01
Sfx4_27_Data_6E65:
	db $68, $00, $02
; = LA Sfx4_29
Sfx4_28_Init:
	ld a, $05
	ld [wSfx4Counter], a
	ld hl, Sfx4_28_Data_6E9E
	jp Sfx4_StartPriority

Sfx4_28_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx4_28_Data_6E92
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_28_Data_6E92:
	dw Sfx4_28_Data_6EA3, Sfx4_28_Data_6EA6, Sfx4_28_Data_6EA3, Sfx4_28_Data_6EA9, Sfx4_28_Data_6EA3, Sfx4_28_Data_6EAC
Sfx4_28_Data_6E9E:
	db $00, $f4, $68, $80, $02
Sfx4_28_Data_6EA3:
	db $6f, $00, $02
Sfx4_28_Data_6EA6:
	db $69, $00, $02
Sfx4_28_Data_6EA9:
	db $6a, $00, $02
Sfx4_28_Data_6EAC:
	db $68, $00, $02
; = LA Sfx4_2A
Sfx4_29_Init:
	ld a, $08
	ld [wSfx4Counter], a
	ld hl, Sfx4_29_Data_6EF5
	jp Sfx4_StartPriority

Sfx4_29_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jr z, .l0
.l1:
	ld hl, Sfx4_29_Data_6EE1
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

Sfx4_29_Data_6EE1:
	dw Sfx4_29_Data_6EFA, Sfx4_29_Data_6EFF, Sfx4_29_Data_6F05, Sfx4_29_Data_6F0B, Sfx4_29_Data_6F11, Sfx4_29_Data_6F0E, Sfx4_29_Data_6F0B, Sfx4_29_Data_6F08, Sfx4_29_Data_6F05, Sfx4_29_Data_6F02
Sfx4_29_Data_6EF5:
	db $00, $c0, $7f, $80, $88
Sfx4_29_Data_6EFA:
	db $00, $f4, $6d, $80, $01
Sfx4_29_Data_6EFF:
	db $74, $00, $01
Sfx4_29_Data_6F02:
	db $5f, $00, $01
Sfx4_29_Data_6F05:
	db $66, $00, $01
Sfx4_29_Data_6F08:
	db $5d, $00, $01
Sfx4_29_Data_6F0B:
	db $64, $00, $01
Sfx4_29_Data_6F0E:
	db $4f, $00, $01
Sfx4_29_Data_6F11:
	db $62, $00, $01
; = LA Sfx4_2B
Sfx4_2A_Init:
	ld hl, Sfx4_2A_Data_6F21
	jp Sfx4_Start

Sfx4_2A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_2A_Data_6F21:
	db $00, $f4, $7d, $80, $40
; = LA Sfx4_2C
Sfx4_2B_Init:
	ld hl, Sfx4_2B_Data_6F6F
	jp Sfx4_Start

Sfx4_2B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_2B_Data_6F49
	call GetPointer
	ld a, [wSfx4Step]
	cp $13
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_2B_Data_6F49:
	dw Sfx4_2B_Data_6F74, Sfx4_2B_Data_6F77, Sfx4_2B_Data_6F7A, Sfx4_2B_Data_6F7D, Sfx4_2B_Data_6F80, Sfx4_2B_Data_6F83, Sfx4_2B_Data_6F86, Sfx4_2B_Data_6F89, Sfx4_2B_Data_6F8C, Sfx4_2B_Data_6F8F, Sfx4_2B_Data_6F92, Sfx4_2B_Data_6F95, Sfx4_2B_Data_6F98, Sfx4_2B_Data_6F9B, Sfx4_2B_Data_6F9E, Sfx4_2B_Data_6FA1, Sfx4_2B_Data_6FA4, Sfx4_2B_Data_6FA7, Sfx4_2B_Data_6FAA
Sfx4_2B_Data_6F6F:
	db $26, $40, $37, $80, $06
Sfx4_2B_Data_6F74:
	db $36, $80, $06
Sfx4_2B_Data_6F77:
	db $35, $80, $06
Sfx4_2B_Data_6F7A:
	db $34, $80, $06
Sfx4_2B_Data_6F7D:
	db $27, $80, $06
Sfx4_2B_Data_6F80:
	db $26, $80, $06
Sfx4_2B_Data_6F83:
	db $25, $80, $06
Sfx4_2B_Data_6F86:
	db $24, $80, $06
Sfx4_2B_Data_6F89:
	db $17, $80, $06
Sfx4_2B_Data_6F8C:
	db $16, $80, $06
Sfx4_2B_Data_6F8F:
	db $15, $80, $06
Sfx4_2B_Data_6F92:
	db $14, $80, $06
Sfx4_2B_Data_6F95:
	db $07, $80, $06
Sfx4_2B_Data_6F98:
	db $06, $00, $06
Sfx4_2B_Data_6F9B:
	db $05, $00, $06
Sfx4_2B_Data_6F9E:
	db $04, $00, $06
Sfx4_2B_Data_6FA1:
	db $03, $00, $06
Sfx4_2B_Data_6FA4:
	db $02, $00, $06
Sfx4_2B_Data_6FA7:
	db $01, $00, $06
Sfx4_2B_Data_6FAA:
	db $00, $47, $00, $80, $20
; = LA Sfx4_2D
Sfx4_2C_Init:
	ld hl, Sfx4_2C_Data_6FD8
	jp Sfx4_Start

Sfx4_2C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_2C_Data_6FCA
	call GetPointer
	jp SetRegs_Ch4

Sfx4_2C_Data_6FCA:
	dw Sfx4_2C_Data_6FDD, Sfx4_2C_Data_6FE2, Sfx4_2C_Data_6FE2+5, Sfx4_2C_Data_6FE2+10, Sfx4_2C_Data_6FE2+15, Sfx4_2C_Data_6FE2, Sfx4_2C_Data_6FE2+20
Sfx4_2C_Data_6FD8:
	db $26, $29, $40, $c0, $04
Sfx4_2C_Data_6FDD:
	db $26, $10, $40, $c0, $02
Sfx4_2C_Data_6FE2:
	db $26, $29, $10, $c0, $04
	db $26, $10, $10, $c0, $02
	db $26, $19, $60, $c0, $04
	db $26, $10, $60, $c0, $02
	db $26, $10, $10, $c0, $03
; = LA Sfx4_2E
Sfx4_2D_Init:
	ld a, $08
	ld [wSfx4Counter], a
	ld hl, Sfx4_2D_Data_7043
	jp Sfx4_StartPriority

Sfx4_2D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jr z, .l0
.l1:
	ld hl, Sfx4_2D_Data_702D
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

; LA's table for this effect (LA Sfx4_2E), not relocated: the entries are LA addresses
; and point at unrelated bytes here
Sfx4_2D_Data_702D:
	dw $7111, $6fc3, $6fc8, $6fce, $6fd4, $6fda, $6fd7, $6fd4, $6fd1, $6fce, $6fcb
Sfx4_2D_Data_7043:
	db $00, $c0, $7f, $80, $ff
	db $7f, $80, $34
; = LA Sfx4_2F
Sfx4_2E_Init:
	ld hl, Sfx4_2E_Data_7063
	jp Sfx4_Start

Sfx4_2E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_2E_Data_7068
	jp SetRegs_Ch4

Sfx4_2E_Data_7063:
	db $00, $19, $50, $80, $06
Sfx4_2E_Data_7068:
	db $00, $65, $50, $80, $20
; = LA Sfx4_30
Sfx4_2F_Init:
	ld hl, Sfx4_2F_Data_70CC
	jp Sfx4_Start

Sfx4_2F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $23
	jp z, Sfx4_Stop
	ld hl, Sfx4_2F_Data_7088
	call GetPointer
	jp SetRegs_Ch4

Sfx4_2F_Data_7088:
	dw Sfx4_2F_Data_70D1, Sfx4_30_Data_70F4, Sfx4_2F_Data_70D6, Sfx4_30_Data_70F4, Sfx4_2F_Data_70DB, Sfx4_30_Data_70F4, Sfx4_2F_Data_70E0, Sfx4_30_Data_70F4, Sfx4_2F_Data_70E0, Sfx4_30_Data_70F4, Sfx4_2F_Data_70E5, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EF, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9, Sfx4_2F_Data_70E5, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EF, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9, Sfx4_2F_Data_70E5, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EF, Sfx4_30_Data_70F9, Sfx4_2F_Data_70EA, Sfx4_30_Data_70F9
Sfx4_2F_Data_70CC:
	db $00, $1c, $60, $80, $18
Sfx4_2F_Data_70D1:
	db $00, $19, $50, $80, $0a
Sfx4_2F_Data_70D6:
	db $00, $19, $30, $80, $09
Sfx4_2F_Data_70DB:
	db $00, $19, $40, $80, $07
Sfx4_2F_Data_70E0:
	db $00, $19, $50, $80, $06
Sfx4_2F_Data_70E5:
	db $00, $19, $60, $80, $06
Sfx4_2F_Data_70EA:
	db $00, $19, $60, $80, $04
Sfx4_2F_Data_70EF:
	db $00, $19, $50, $80, $02
Sfx4_30_Data_70F4:
	db $37, $40, $20, $c0, $02
Sfx4_30_Data_70F9:
	db $37, $20, $20, $c0, $02
; = LA Sfx4_31
Sfx4_30_Init:
	ld hl, Sfx4_30_Data_714D
	jp Sfx4_StartPriority

Sfx4_30_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1b
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_30_Data_7119
	call GetPointer
	jp SetRegs_Ch4

Sfx4_30_Data_7119:
	dw Sfx4_30_Data_7152, Sfx4_30_Data_70F4, Sfx4_30_Data_7157, Sfx4_30_Data_70F4, Sfx4_30_Data_715C, Sfx4_30_Data_70F4, Sfx4_30_Data_7161, Sfx4_30_Data_70F4, Sfx4_30_Data_7161, Sfx4_30_Data_70F4, Sfx4_30_Data_7166, Sfx4_30_Data_70F9, Sfx4_30_Data_716B, Sfx4_30_Data_70F9, Sfx4_30_Data_7170, Sfx4_30_Data_70F9, Sfx4_30_Data_716B, Sfx4_30_Data_70F9, Sfx4_30_Data_7166, Sfx4_30_Data_70F9, Sfx4_30_Data_716B, Sfx4_30_Data_70F9, Sfx4_30_Data_7170, Sfx4_30_Data_70F9, Sfx4_30_Data_716B, Sfx4_30_Data_70F9
Sfx4_30_Data_714D:
	db $00, $00, $00, $80, $20
Sfx4_30_Data_7152:
	db $00, $19, $27, $80, $0a
Sfx4_30_Data_7157:
	db $00, $19, $26, $80, $09
Sfx4_30_Data_715C:
	db $00, $19, $24, $80, $08
Sfx4_30_Data_7161:
	db $00, $19, $23, $80, $07
Sfx4_30_Data_7166:
	db $00, $19, $17, $80, $06
Sfx4_30_Data_716B:
	db $00, $19, $17, $80, $04
Sfx4_30_Data_7170:
	db $00, $19, $16, $80, $02
; = LA Sfx4_32
Sfx4_31_Init:
	ld hl, Sfx4_31_Data_71A4
	jp Sfx4_Start

Sfx4_31_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx4_Stop
	ld hl, Sfx4_31_Data_7190
	call GetPointer
	jp SetRegs_Ch4

Sfx4_31_Data_7190:
	dw Sfx4_31_Data_71A9, Sfx4_31_Data_71AE, Sfx4_31_Data_71B3, Sfx4_31_Data_71AE, Sfx4_31_Data_71A9, Sfx4_31_Data_71A4, Sfx4_31_Data_71C7, Sfx4_31_Data_71C2, Sfx4_31_Data_71BD, Sfx4_31_Data_71B8
Sfx4_31_Data_71A4:
	db $00, $20, $30, $80, $02
Sfx4_31_Data_71A9:
	db $00, $40, $40, $80, $03
Sfx4_31_Data_71AE:
	db $00, $80, $50, $80, $04
Sfx4_31_Data_71B3:
	db $00, $c0, $60, $80, $05
Sfx4_31_Data_71B8:
	db $37, $10, $30, $c0, $02
Sfx4_31_Data_71BD:
	db $00, $10, $40, $80, $03
Sfx4_31_Data_71C2:
	db $00, $10, $50, $80, $04
Sfx4_31_Data_71C7:
	db $00, $10, $60, $80, $05
; = LA Sfx4_33
Sfx4_32_Init:
	ld hl, Sfx4_32_Data_7205
	jp Sfx4_Start

Sfx4_32_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_32_Data_71EF
	call GetPointer
	ld a, [wSfx4Step]
	cp $06
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_32_Data_71EF:
	dw Sfx4_32_Data_720D, Sfx4_32_Data_720A, Sfx4_32_Data_7210, Sfx4_32_Data_720D, Sfx4_32_Data_7213, Sfx4_32_Data_7216, Sfx4_32_Data_720D, Sfx4_32_Data_720A, Sfx4_32_Data_7210, Sfx4_32_Data_720D, Sfx4_32_Data_7213
Sfx4_32_Data_7205:
	db $00, $80, $48, $80, $02
Sfx4_32_Data_720A:
	db $49, $80, $02
Sfx4_32_Data_720D:
	db $4a, $80, $02
Sfx4_32_Data_7210:
	db $4b, $80, $02
Sfx4_32_Data_7213:
	db $4c, $80, $02
Sfx4_32_Data_7216:
	db $00, $20, $48, $80, $02
; = LA Sfx4_34
Sfx4_33_Init:
	ld a, $2b
	ld [$c8df], a
	ld a, $15
	ld [$c8e0], a
	ld hl, Sfx4_33_Data_734C
	jp Sfx4_Start

Sfx4_33_Play:
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
	ld hl, Sfx4_33_Data_72AA
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
	ld de, $c8df
	call Sfx_DecTimer
	pop de
	jr z, .l3
	ld a, $01
	ld [bc], a
	jr .l4

.l2:
	push de
	ld de, $c8e0
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
	jr .l1

.l1:
	ld a, $20
	ld [wSfx3Request], a
	call Sfx3_Update
	ld bc, wSfx4Step
	ld de, wSfx4Timer
	jr .l4

Sfx4_33_Data_72AA:
	dw Sfx4_33_Data_7351, Sfx4_33_Data_7354, Sfx4_33_Data_7357, Sfx4_33_Data_735A, Sfx4_33_Data_735D, Sfx4_33_Data_7360, Sfx4_33_Data_7363, Sfx4_33_Data_7366, Sfx4_33_Data_7369, Sfx4_33_Data_736C, Sfx4_33_Data_736F, Sfx4_33_Data_7372, Sfx4_33_Data_7375, Sfx4_33_Data_7378, Sfx4_33_Data_737B, Sfx4_33_Data_737E, Sfx4_33_Data_7381, Sfx4_33_Data_7384, Sfx4_33_Data_7387, Sfx4_33_Data_738A, Sfx4_33_Data_738D, Sfx4_33_Data_7390, Sfx4_33_Data_738D, Sfx4_33_Data_738A, Sfx4_33_Data_7387, Sfx4_33_Data_7393, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5+5, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5+10, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5+15, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5+20, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398, Sfx4_33_Data_73A5+20, Sfx4_33_Data_7398, Sfx4_33_Data_739C, Sfx4_33_Data_739F, Sfx4_33_Data_73A2, Sfx4_33_Data_739F, Sfx4_33_Data_739C, Sfx4_33_Data_7398
Sfx4_33_Data_734C:
	db $00, $80, $9c, $80, $01
Sfx4_33_Data_7351:
	db $8e, $00, $01
Sfx4_33_Data_7354:
	db $7e, $00, $01
Sfx4_33_Data_7357:
	db $8c, $00, $01
Sfx4_33_Data_735A:
	db $7c, $00, $01
Sfx4_33_Data_735D:
	db $6f, $00, $01
Sfx4_33_Data_7360:
	db $6d, $00, $01
Sfx4_33_Data_7363:
	db $5f, $00, $01
Sfx4_33_Data_7366:
	db $5d, $00, $01
Sfx4_33_Data_7369:
	db $4f, $00, $01
Sfx4_33_Data_736C:
	db $4d, $00, $01
Sfx4_33_Data_736F:
	db $3f, $00, $01
Sfx4_33_Data_7372:
	db $3d, $00, $01
Sfx4_33_Data_7375:
	db $37, $80, $02
Sfx4_33_Data_7378:
	db $35, $80, $02
Sfx4_33_Data_737B:
	db $27, $80, $02
Sfx4_33_Data_737E:
	db $25, $80, $02
Sfx4_33_Data_7381:
	db $17, $80, $02
Sfx4_33_Data_7384:
	db $15, $80, $02
Sfx4_33_Data_7387:
	db $14, $80, $02
Sfx4_33_Data_738A:
	db $07, $80, $02
Sfx4_33_Data_738D:
	db $06, $80, $02
Sfx4_33_Data_7390:
	db $05, $80, $02
Sfx4_33_Data_7393:
	db $00, $70, $15, $80, $02
Sfx4_33_Data_7398:
	db $14, $80, $02, $07
Sfx4_33_Data_739C:
	db $07, $80, $02
Sfx4_33_Data_739F:
	db $06, $80, $02
Sfx4_33_Data_73A2:
	db $05, $80, $02
Sfx4_33_Data_73A5:
	db $00, $60, $15, $80, $02
	db $00, $50, $15, $80, $02
	db $00, $40, $15, $80, $02
	db $00, $30, $15, $80, $02
	db $00, $20, $15, $80, $02
	db $00, $10, $15, $80, $02
; = LA Sfx4_35
Sfx4_34_Init:
	ld a, $40
	ld [wSfx4Counter], a
	ld hl, Sfx4_34_Data_7423
	jp Sfx4_Start

Sfx4_34_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $21
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_34_Data_73E3
	call GetPointer
	jp SetRegs_Ch4

Sfx4_34_Data_73E3:
	dw Sfx4_34_Data_7428, Sfx4_34_Data_742D, Sfx4_34_Data_7432, Sfx4_34_Data_7437, Sfx4_34_Data_743C, Sfx4_34_Data_7441, Sfx4_34_Data_7446, Sfx4_34_Data_744B, Sfx4_34_Data_7450, Sfx4_34_Data_7455, Sfx4_34_Data_745A, Sfx4_34_Data_745F, Sfx4_34_Data_7464, Sfx4_34_Data_7469, Sfx4_34_Data_746E, Sfx4_34_Data_7473, Sfx4_34_Data_7478, Sfx4_34_Data_747D, Sfx4_34_Data_7482, Sfx4_34_Data_7487, Sfx4_34_Data_748C, Sfx4_34_Data_7491, Sfx4_34_Data_7496, Sfx4_34_Data_749B, Sfx4_34_Data_74A0, Sfx4_34_Data_74A5, Sfx4_34_Data_74AA, Sfx4_34_Data_74AF, Sfx4_34_Data_74B4, Sfx4_34_Data_74B9, Sfx4_34_Data_74BE, Sfx4_34_Data_74C3
Sfx4_34_Data_7423:
	db $00, $20, $67, $80, $02
Sfx4_34_Data_7428:
	db $00, $20, $66, $80, $02
Sfx4_34_Data_742D:
	db $00, $20, $65, $80, $02
Sfx4_34_Data_7432:
	db $00, $20, $64, $80, $03
Sfx4_34_Data_7437:
	db $00, $20, $57, $80, $03
Sfx4_34_Data_743C:
	db $00, $20, $56, $80, $03
Sfx4_34_Data_7441:
	db $00, $20, $55, $80, $04
Sfx4_34_Data_7446:
	db $00, $20, $54, $80, $04
Sfx4_34_Data_744B:
	db $00, $20, $47, $80, $04
Sfx4_34_Data_7450:
	db $00, $20, $46, $80, $05
Sfx4_34_Data_7455:
	db $00, $20, $45, $80, $05
Sfx4_34_Data_745A:
	db $00, $20, $44, $80, $05
Sfx4_34_Data_745F:
	db $00, $20, $37, $80, $06
Sfx4_34_Data_7464:
	db $00, $20, $36, $80, $06
Sfx4_34_Data_7469:
	db $00, $20, $35, $80, $06
Sfx4_34_Data_746E:
	db $00, $20, $34, $80, $08
Sfx4_34_Data_7473:
	db $00, $20, $27, $80, $08
Sfx4_34_Data_7478:
	db $00, $20, $26, $80, $0a
Sfx4_34_Data_747D:
	db $00, $20, $25, $80, $0a
Sfx4_34_Data_7482:
	db $00, $20, $24, $80, $0c
Sfx4_34_Data_7487:
	db $00, $20, $17, $80, $0c
Sfx4_34_Data_748C:
	db $00, $20, $16, $80, $0e
Sfx4_34_Data_7491:
	db $00, $20, $15, $80, $0e
Sfx4_34_Data_7496:
	db $00, $20, $14, $80, $10
Sfx4_34_Data_749B:
	db $00, $20, $07, $80, $10
Sfx4_34_Data_74A0:
	db $00, $20, $06, $80, $12
Sfx4_34_Data_74A5:
	db $00, $20, $05, $80, $12
Sfx4_34_Data_74AA:
	db $00, $20, $04, $80, $14
Sfx4_34_Data_74AF:
	db $00, $20, $03, $80, $14
Sfx4_34_Data_74B4:
	db $00, $20, $02, $80, $16
Sfx4_34_Data_74B9:
	db $00, $20, $01, $80, $16
Sfx4_34_Data_74BE:
	db $00, $20, $00, $80, $18
Sfx4_34_Data_74C3:
	db $00, $10, $00, $80, $20
; = LA Sfx4_36
Sfx4_35_Init:
	ld a, $07
	ld [wSfx4Counter], a
	ld hl, Sfx4_35_Data_74FE
	jp Sfx4_StartPriority

Sfx4_35_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx4_35_Data_74EE
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	call Sfx4_DecCounter
	jp z, Sfx4_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx4_35_Data_74EE:
	dw Sfx4_35_Data_7503, Sfx4_35_Data_7506, Sfx4_35_Data_7509, Sfx4_35_Data_750C, Sfx4_35_Data_750F, Sfx4_35_Data_750C, Sfx4_35_Data_7509, Sfx4_35_Data_7506
Sfx4_35_Data_74FE:
	db $00, $f4, $0f, $80, $01
Sfx4_35_Data_7503:
	db $0e, $00, $01
Sfx4_35_Data_7506:
	db $0d, $00, $01
Sfx4_35_Data_7509:
	db $0c, $00, $01
Sfx4_35_Data_750C:
	db $0b, $00, $01
Sfx4_35_Data_750F:
	db $0a, $00, $01
; = LA Sfx4_37
Sfx4_36_Init:
	ld a, $07
	ld [wSfx4Counter], a
	call Sfx4_StartWithCh2
	ld hl, Sfx3_21_Data_616A
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx4_36_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx3_21_Data_6158
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

; = LA Sfx4_39
Sfx4_37_Init:
	ld hl, Sfx4_37_Data_757F
	jp Sfx4_Start

Sfx4_37_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx4_Stop
	ld hl, Sfx4_37_Data_755D
	call GetPointer
	jp SetRegs_Ch4

Sfx4_37_Data_755D:
	dw Sfx4_37_Data_7584, Sfx4_37_Data_7589, Sfx4_37_Data_758E, Sfx4_37_Data_7593, Sfx4_37_Data_7598, Sfx4_37_Data_759D, Sfx4_37_Data_75A2, Sfx4_37_Data_75A7, Sfx4_37_Data_75AC, Sfx4_37_Data_75B1, Sfx4_37_Data_75B6, Sfx4_37_Data_75BB, Sfx4_37_Data_75C0, Sfx4_37_Data_75C5, Sfx4_37_Data_75CA, Sfx4_37_Data_75CF, Sfx4_37_Data_75D4
Sfx4_37_Data_757F:
	db $00, $20, $0c, $80, $01
Sfx4_37_Data_7584:
	db $00, $40, $0d, $80, $01
Sfx4_37_Data_7589:
	db $00, $60, $0e, $80, $01
Sfx4_37_Data_758E:
	db $00, $80, $0f, $80, $01
Sfx4_37_Data_7593:
	db $00, $a0, $1c, $80, $01
Sfx4_37_Data_7598:
	db $00, $e0, $1d, $80, $01
Sfx4_37_Data_759D:
	db $00, $c0, $1e, $80, $02
Sfx4_37_Data_75A2:
	db $00, $b0, $1f, $80, $02
Sfx4_37_Data_75A7:
	db $00, $a0, $2c, $80, $02
Sfx4_37_Data_75AC:
	db $00, $90, $2d, $80, $02
Sfx4_37_Data_75B1:
	db $00, $80, $2e, $80, $02
Sfx4_37_Data_75B6:
	db $00, $70, $2f, $80, $02
Sfx4_37_Data_75BB:
	db $00, $60, $3c, $80, $02
Sfx4_37_Data_75C0:
	db $00, $50, $3d, $80, $02
Sfx4_37_Data_75C5:
	db $00, $40, $3e, $80, $02
Sfx4_37_Data_75CA:
	db $00, $30, $3f, $80, $02
Sfx4_37_Data_75CF:
	db $00, $20, $4c, $80, $02
Sfx4_37_Data_75D4:
	db $37, $10, $4d, $c0, $02
; same number in LA
Sfx4_38_Init:
	ld hl, Sfx4_38_Data_760E
	jp Sfx4_Start

Sfx4_38_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0e
	jp z, Sfx4_Stop
	ld hl, Sfx4_38_Data_75F4
	call GetPointer
	jp SetRegs_Ch4

Sfx4_38_Data_75F4:
	dw Sfx4_38_Data_7613, Sfx4_38_Data_7618, Sfx4_38_Data_761D, Sfx4_38_Data_7622, Sfx4_38_Data_7627, Sfx4_38_Data_762C, Sfx4_38_Data_7631, Sfx4_38_Data_7636, Sfx4_38_Data_763B, Sfx4_38_Data_7640, Sfx4_38_Data_7645, Sfx4_38_Data_764A, Sfx4_38_Data_764F
Sfx4_38_Data_760E:
	db $00, $30, $3d, $80, $02
Sfx4_38_Data_7613:
	db $00, $60, $3f, $80, $02
Sfx4_38_Data_7618:
	db $00, $90, $3d, $80, $02
Sfx4_38_Data_761D:
	db $00, $c0, $3f, $80, $02
Sfx4_38_Data_7622:
	db $00, $f0, $3d, $80, $02
Sfx4_38_Data_7627:
	db $00, $d0, $3f, $80, $02
Sfx4_38_Data_762C:
	db $00, $b0, $3d, $80, $02
Sfx4_38_Data_7631:
	db $00, $90, $3f, $80, $02
Sfx4_38_Data_7636:
	db $00, $70, $3d, $80, $03
Sfx4_38_Data_763B:
	db $00, $50, $3f, $80, $03
Sfx4_38_Data_7640:
	db $00, $40, $3d, $80, $04
Sfx4_38_Data_7645:
	db $00, $30, $3f, $80, $04
Sfx4_38_Data_764A:
	db $00, $20, $3d, $80, $04
Sfx4_38_Data_764F:
	db $2f, $10, $3f, $c0, $04
; = LA Sfx4_3A
Sfx4_39_Init:
	xor a
	ld [wSfx1Playing], a
	ld hl, wCh1Flags
	set 7, [hl]
	ld a, $01
	ld [wSfx1Priority], a
	ld hl, Sfx4_39_Data_7696
	jp Sfx4_StartPriority

Sfx4_39_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jr z, .l0
	ld hl, Sfx4_39_Data_7692
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

Sfx4_39_Data_7692:
	dw Sfx4_39_Data_769B, Sfx4_39_Data_76A1
Sfx4_39_Data_7696:
	db $00, $20, $70, $80, $01
Sfx4_39_Data_769B:
	db $1d, $51, $82, $59, $c7, $03
Sfx4_39_Data_76A1:
	db $00, $42, $50, $80, $08
; = LA Sfx4_3B
Sfx4_3A_Init:
	xor a
	ld [wSfx1Playing], a
	ld hl, wCh1Flags
	set 7, [hl]
	ld a, $01
	ld [wSfx1Priority], a
	ld hl, Sfx4_3A_Data_770E
	call Sfx4_StartPriority
	ld a, $f0
	ld [wSfx4Counter], a
	ld hl, Sfx4_3A_Data_7718
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx4_3A_Play:
	ld hl, $c8e6
	ld a, [hl]
	and a
	jr z, .l0
	xor a
	ld [hl], a
	call Sfx4_DecCounter
	jr z, .l0
	cp $e0
	jr z, .l1
	cp $d8
	jr nc, .l2
	ld a, $02
.l3:
	ld [bc], a
	ld hl, Sfx4_3A_Data_770A
	jp Sfx1_AddPitch

.l2:
	ld a, $01
	jr .l3

.l1:
	ld hl, Sfx4_3A_Data_7713
	call SetRegs_Ch4
	ld a, $01
	ld bc, wSfx4Step
	jr .l3

.l0:
	xor a
	ld [wSfx1Priority], a
	ld hl, wCh1Flags
	res 7, [hl]
	ld hl, Sfx1_StopRegs
	call SetRegs_Ch1
	jp Sfx1_StopWithRegs

Sfx4_3A_Data_770A:
	db $00, $02
	db $00, $00
Sfx4_3A_Data_770E:
	db $00, $1d, $20, $80, $01
Sfx4_3A_Data_7713:
	db $00, $60, $20, $80, $01
Sfx4_3A_Data_7718:
	db $00, $40, $10, $a0, $87, $01
; = LA Sfx4_3D
Sfx4_3B_Init:
	ld hl, Sfx4_3B_Data_77DB
	jp Sfx4_StartPriority

Sfx4_3B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $51
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_3B_Data_7739
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_3B_Data_7739:
	dw Sfx4_3B_Data_77E0, Sfx4_3B_Data_77E3, Sfx4_3B_Data_77E6, Sfx4_3B_Data_77E9, Sfx4_3B_Data_77EC, Sfx4_3B_Data_77EF, Sfx4_3B_Data_77EC, Sfx4_3B_Data_77E9, Sfx4_3B_Data_77E6, Sfx4_3B_Data_77E9, Sfx4_3B_Data_77EC, Sfx4_3B_Data_77EF, Sfx4_3B_Data_77F2, Sfx4_3B_Data_77F5, Sfx4_3B_Data_77F8, Sfx4_3B_Data_77F5, Sfx4_3B_Data_77F2, Sfx4_3B_Data_77EF, Sfx4_3B_Data_77F2, Sfx4_3B_Data_77F5, Sfx4_3B_Data_77F8, Sfx4_3B_Data_77FB, Sfx4_3B_Data_77FE, Sfx4_3B_Data_7801, Sfx4_3B_Data_77FE, Sfx4_3B_Data_77FB, Sfx4_3B_Data_77F8, Sfx4_3B_Data_77FB, Sfx4_3B_Data_77FE, Sfx4_3B_Data_7801, Sfx4_3B_Data_7804, Sfx4_3B_Data_7807, Sfx4_3B_Data_780A, Sfx4_3B_Data_7807, Sfx4_3B_Data_7804, Sfx4_3B_Data_7801, Sfx4_3B_Data_7804, Sfx4_3B_Data_7807, Sfx4_3B_Data_780A, Sfx4_3B_Data_780D, Sfx4_3B_Data_7810, Sfx4_3B_Data_7810+3, Sfx4_3B_Data_7810, Sfx4_3B_Data_780D, Sfx4_3B_Data_780A, Sfx4_3B_Data_780D, Sfx4_3B_Data_7810, Sfx4_3B_Data_7810+3, Sfx4_3B_Data_7810+6, Sfx4_3B_Data_7810+9, Sfx4_3B_Data_7810+12, Sfx4_3B_Data_7810+9, Sfx4_3B_Data_7810+6, Sfx4_3B_Data_7810+3, Sfx4_3B_Data_7810+6, Sfx4_3B_Data_7810+9, Sfx4_3B_Data_7810+12, Sfx4_3B_Data_7810+15, Sfx4_3B_Data_7810+18, Sfx4_3B_Data_7810+21, Sfx4_3B_Data_7810+18, Sfx4_3B_Data_7810+15, Sfx4_3B_Data_7810+12, Sfx4_3B_Data_7810+15, Sfx4_3B_Data_7810+18, Sfx4_3B_Data_7810+21, Sfx4_3B_Data_7810+24, Sfx4_3B_Data_7810+27, Sfx4_3B_Data_7810+30, Sfx4_3B_Data_7810+27, Sfx4_3B_Data_7810+24, Sfx4_3B_Data_7810+21, Sfx4_3B_Data_7810+24, Sfx4_3B_Data_7810+27, Sfx4_3B_Data_7810+30, Sfx4_3B_Data_7810+33, Sfx4_3B_Data_7810+36, Sfx4_3B_Data_7810+39, Sfx4_3B_Data_7810+42, Sfx4_3B_Data_7810+39, Sfx4_3B_Data_7810+42
Sfx4_3B_Data_77DB:
	db $38, $80, $24, $80, $02
Sfx4_3B_Data_77E0:
	db $25, $80, $02
Sfx4_3B_Data_77E3:
	db $26, $80, $02
Sfx4_3B_Data_77E6:
	db $27, $80, $02
Sfx4_3B_Data_77E9:
	db $34, $80, $02
Sfx4_3B_Data_77EC:
	db $35, $80, $02
Sfx4_3B_Data_77EF:
	db $36, $80, $02
Sfx4_3B_Data_77F2:
	db $37, $80, $02
Sfx4_3B_Data_77F5:
	db $44, $80, $02
Sfx4_3B_Data_77F8:
	db $45, $80, $02
Sfx4_3B_Data_77FB:
	db $46, $80, $02
Sfx4_3B_Data_77FE:
	db $47, $80, $02
Sfx4_3B_Data_7801:
	db $3c, $80, $03
Sfx4_3B_Data_7804:
	db $3d, $80, $03
Sfx4_3B_Data_7807:
	db $3e, $80, $03
Sfx4_3B_Data_780A:
	db $3f, $80, $03
Sfx4_3B_Data_780D:
	db $4c, $80, $03
Sfx4_3B_Data_7810:
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
; = LA Sfx4_3E
Sfx4_3C_Init:
	ld hl, Sfx4_3C_Data_786B
	jp Sfx4_StartPriority

Sfx4_3C_Play:
	ld a, [$c8e8]
	and a
	ret nz
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_3C_Data_785D
	call GetPointer
	jp SetRegs_Ch4

Sfx4_3C_Data_785D:
	dw Sfx4_3C_Data_7870, Sfx4_3C_Data_7875, Sfx4_3C_Data_787A, Sfx4_3C_Data_787F, Sfx4_3C_Data_7884, Sfx4_3C_Data_7889, Sfx4_3C_Data_788E
Sfx4_3C_Data_786B:
	db $00, $1f, $7f, $80, $01
Sfx4_3C_Data_7870:
	db $00, $e0, $44, $80, $06
Sfx4_3C_Data_7875:
	db $00, $c0, $45, $80, $06
Sfx4_3C_Data_787A:
	db $00, $a0, $46, $80, $06
Sfx4_3C_Data_787F:
	db $00, $80, $47, $80, $06
Sfx4_3C_Data_7884:
	db $00, $60, $54, $80, $06
Sfx4_3C_Data_7889:
	db $00, $40, $55, $80, $06
Sfx4_3C_Data_788E:
	db $38, $20, $56, $c0, $06
; = LA Sfx4_3F
Sfx4_3D_Init:
	ld hl, Sfx4_3D_Data_78CC
	jp Sfx4_StartPriority

Sfx4_3D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx4_Stop
	ld hl, Sfx4_3D_Data_78AE
	call GetPointer
	jp SetRegs_Ch4

Sfx4_3D_Data_78AE:
	dw Sfx4_3D_Data_78D1, Sfx4_3D_Data_78D6, Sfx4_3D_Data_78DB, Sfx4_3D_Data_78E0, Sfx4_3D_Data_78E5, Sfx4_3D_Data_78EA, Sfx4_3D_Data_78EF, Sfx4_3D_Data_78F4, Sfx4_3D_Data_78F9, Sfx4_3D_Data_78FE, Sfx4_3D_Data_7903, Sfx4_3D_Data_7908, Sfx4_3D_Data_790D, Sfx4_3D_Data_7912, Sfx4_3D_Data_7917
Sfx4_3D_Data_78CC:
	db $00, $20, $27, $80, $02
Sfx4_3D_Data_78D1:
	db $00, $40, $25, $80, $02
Sfx4_3D_Data_78D6:
	db $00, $60, $17, $80, $02
Sfx4_3D_Data_78DB:
	db $00, $80, $15, $80, $02
Sfx4_3D_Data_78E0:
	db $00, $a0, $17, $80, $02
Sfx4_3D_Data_78E5:
	db $00, $c0, $25, $80, $04
Sfx4_3D_Data_78EA:
	db $00, $b0, $27, $80, $04
Sfx4_3D_Data_78EF:
	db $00, $a0, $25, $80, $04
Sfx4_3D_Data_78F4:
	db $00, $90, $17, $80, $04
Sfx4_3D_Data_78F9:
	db $00, $80, $15, $c0, $04
Sfx4_3D_Data_78FE:
	db $00, $70, $17, $80, $04
Sfx4_3D_Data_7903:
	db $00, $60, $25, $80, $04
Sfx4_3D_Data_7908:
	db $00, $50, $27, $80, $04
Sfx4_3D_Data_790D:
	db $00, $40, $25, $80, $04
Sfx4_3D_Data_7912:
	db $00, $30, $17, $80, $04
Sfx4_3D_Data_7917:
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

