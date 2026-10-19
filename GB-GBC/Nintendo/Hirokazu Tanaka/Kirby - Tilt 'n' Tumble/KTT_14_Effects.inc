; Kirby Tilt 'n' Tumble SFX: effects, bank $14 $4296-$5AFD

Sfx1_80_Init:
	jp Sfx1_Refuse

Sfx1_80_Play:
	ret

Sfx1_92_Init:
	ld a, $88
	ld [wSfx2Request], a
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_92_Data_42DF
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_92_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_92_Data_42CD
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Release
	ld a, $09
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_92_Data_42CD:
	db $00, $15
	db $00, $10
	db $00, $17
	db $00, $08
	db $00, $04
	db $00, $06
	db $00, $02
	db $00, $01
	db $ff, $c1
Sfx1_92_Data_42DF:
	db $08, $40, $f2, $d6, $86, $01
Sfx2_88_Init:
	ld a, $07
	ld [wSfx2Counter], a
	ld hl, Sfx2_88_Data_4317
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_88_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx2_88_Data_430B
	jp Sfx2_AddPitch

.l0:
	call Sfx2_DecCounter
	jp z, Sfx2_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx2_88_Data_430B:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx2_88_Data_4317:
	db $40, $f2, $00, $85, $01
Sfx1_91_Init:
	ld hl, Sfx1_91_Data_433B
	jp Sfx1_StartSweep

Sfx1_91_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_91_Data_4339
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_91_Data_4339:
	dw Sfx1_91_Data_4341
Sfx1_91_Data_433B:
	db $1c, $40, $98, $39, $87, $04
Sfx1_91_Data_4341:
	db $16, $00, $4a, $d6, $86, $07
Sfx1_8E_Init:
	ld hl, Sfx1_8E_Data_4378
	jp Sfx1_Start

Sfx1_8E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx1_Stop
	ld hl, Sfx1_8E_Data_4362
	call GetPointer
	jp SetRegs_Ch1

Sfx1_8E_Data_4362:
	dw Sfx1_8E_Data_437E, Sfx1_8E_Data_4384, Sfx1_8E_Data_438A, Sfx1_8E_Data_4390, Sfx1_8E_Data_4396, Sfx1_8E_Data_439C, Sfx1_8E_Data_43A2, Sfx1_8E_Data_43A8, Sfx1_8E_Data_43AE, Sfx1_8E_Data_43B4, Sfx1_8E_Data_43BA
Sfx1_8E_Data_4378:
	db $08, $80, $a3, $9d, $87, $04
Sfx1_8E_Data_437E:
	db $08, $80, $a3, $83, $87, $08
Sfx1_8E_Data_4384:
	db $08, $80, $83, $59, $87, $04
Sfx1_8E_Data_438A:
	db $08, $80, $83, $39, $87, $08
Sfx1_8E_Data_4390:
	db $08, $80, $63, $9d, $87, $04
Sfx1_8E_Data_4396:
	db $08, $80, $63, $83, $87, $08
Sfx1_8E_Data_439C:
	db $08, $80, $53, $59, $87, $04
Sfx1_8E_Data_43A2:
	db $08, $80, $53, $39, $87, $08
Sfx1_8E_Data_43A8:
	db $08, $80, $43, $9d, $87, $04
Sfx1_8E_Data_43AE:
	db $08, $80, $43, $83, $87, $08
Sfx1_8E_Data_43B4:
	db $08, $80, $33, $59, $87, $04
Sfx1_8E_Data_43BA:
	db $08, $80, $33, $39, $87, $08
Sfx1_8B_Init:
	ld a, [wSfx1Playing]
	cp $8b
	jr nz, .l0
	jp Sfx1_Continue

.l0:
	ld hl, Sfx1_8B_Data_440C
	jp Sfx1_Start

Sfx1_8B_Play:
	ld a, [wSfx1Request]
	cp $8b
	jp nz, Sfx1_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0f
	jp c, .l1
	ld a, $0c
	ld [bc], a
.l1:
	ld hl, Sfx1_8B_Data_43F0
	call GetPointer
	jp SetRegsPartial_Ch1

Sfx1_8B_Data_43F0:
	dw Sfx1_8B_Data_4412, Sfx1_8B_Data_4418, Sfx1_8B_Data_441E, Sfx1_8B_Data_4424, Sfx1_8B_Data_442A, Sfx1_8B_Data_4430, Sfx1_8B_Data_4436, Sfx1_8B_Data_443C, Sfx1_8B_Data_4442, Sfx1_8B_Data_4448, Sfx1_8B_Data_444E, Sfx1_8B_Data_4454, Sfx1_8B_Data_445A, Sfx1_8B_Data_4460
Sfx1_8B_Data_440C:
	db $08, $40, $28, $39, $87, $03
Sfx1_8B_Data_4412:
	db $00, $00, $00, $3e, $07, $03
Sfx1_8B_Data_4418:
	db $00, $00, $00, $48, $07, $03
Sfx1_8B_Data_441E:
	db $00, $00, $00, $43, $07, $03
Sfx1_8B_Data_4424:
	db $00, $00, $38, $44, $87, $03
Sfx1_8B_Data_442A:
	db $00, $00, $00, $49, $07, $03
Sfx1_8B_Data_4430:
	db $00, $00, $00, $53, $07, $03
Sfx1_8B_Data_4436:
	db $00, $00, $00, $4e, $07, $03
Sfx1_8B_Data_443C:
	db $00, $00, $48, $59, $87, $02
Sfx1_8B_Data_4442:
	db $00, $00, $00, $5e, $07, $02
Sfx1_8B_Data_4448:
	db $00, $00, $00, $68, $07, $02
Sfx1_8B_Data_444E:
	db $00, $00, $00, $63, $07, $02
Sfx1_8B_Data_4454:
	db $00, $00, $58, $70, $87, $01
Sfx1_8B_Data_445A:
	db $00, $00, $00, $7a, $07, $01
Sfx1_8B_Data_4460:
	db $00, $00, $00, $75, $07, $01
Sfx1_8C_Init:
	ld a, $86
	ld [wSfx2Request], a
	ld hl, Sfx1_8C_Data_449E
	jp Sfx1_Start

Sfx1_8C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx1_Stop
	ld hl, Sfx1_8C_Data_4488
	call GetPointer
	jp SetRegs_Ch1

Sfx2_86_Data_4486:
	dw Sfx1_8C_Data_449E
Sfx1_8C_Data_4488:
	dw Sfx1_8C_Data_44A4, Sfx1_8C_Data_44AA, Sfx1_8C_Data_44B0, Sfx1_8C_Data_44B6, Sfx1_8C_Data_44BC, Sfx1_8C_Data_44C2, Sfx1_8C_Data_44C8, Sfx1_8C_Data_44CE, Sfx1_8C_Data_44D4, Sfx1_8C_Data_44DA, Sfx1_8C_Data_44E0
Sfx1_8C_Data_449E:
	db $08, $80, $88, $06, $87, $02
Sfx1_8C_Data_44A4:
	db $08, $80, $88, $83, $87, $02
Sfx1_8C_Data_44AA:
	db $08, $80, $88, $14, $87, $02
Sfx1_8C_Data_44B0:
	db $08, $80, $88, $8a, $87, $02
Sfx1_8C_Data_44B6:
	db $08, $80, $78, $21, $87, $02
Sfx1_8C_Data_44BC:
	db $08, $80, $78, $90, $87, $02
Sfx1_8C_Data_44C2:
	db $08, $80, $78, $2d, $87, $02
Sfx1_8C_Data_44C8:
	db $08, $80, $78, $97, $87, $02
Sfx1_8C_Data_44CE:
	db $08, $80, $68, $39, $87, $02
Sfx1_8C_Data_44D4:
	db $08, $80, $68, $9d, $87, $02
Sfx1_8C_Data_44DA:
	db $08, $80, $68, $44, $87, $02
Sfx1_8C_Data_44E0:
	db $08, $80, $68, $a2, $87, $02
	db $08, $80, $68, $4f, $87, $02
	db $08, $80, $68, $a7, $87, $02
	db $08, $80, $68, $59, $87, $02
	db $08, $80, $68, $ac, $87, $02
Sfx2_86_Init:
	ld hl, Sfx2_86_Data_451A
	jp Sfx2_Start

Sfx2_86_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx2_Stop
	ld hl, Sfx2_86_Data_4486
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx2_86_Data_451A:
	db $80, $08, $b6, $87, $04
Sfx1_8D_Init:
	ld a, $87
	ld [wSfx2Request], a
	ld a, $83
	ld [wSfx3Request], a
	ld a, $89
	ld [wSfx4Request], a
	ld hl, Sfx1_8D_Data_4551
	jp Sfx1_Start

Sfx1_8D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_8D_Data_4549
	call GetPointer
	jp SetRegs_Ch1

Sfx1_8D_Data_4549:
	dw Sfx1_8D_Data_4557, Sfx1_8D_Data_455D, Sfx1_8D_Data_4563, Sfx1_8D_Data_4569
Sfx1_8D_Data_4551:
	db $08, $40, $71, $2d, $87, $08
Sfx1_8D_Data_4557:
	db $08, $40, $71, $2d, $87, $04
Sfx1_8D_Data_455D:
	db $08, $40, $71, $2d, $87, $04
Sfx1_8D_Data_4563:
	db $08, $40, $71, $2d, $87, $08
Sfx1_8D_Data_4569:
	db $08, $40, $78, $39, $87, $30
Sfx2_87_Init:
	ld hl, Sfx2_87_Data_4590
	jp Sfx2_Start

Sfx2_87_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx2_Stop
	ld hl, Sfx2_87_Data_458A
	call GetPointer
	jp SetRegs_Ch2

Sfx2_87_Data_458A:
	dw Sfx2_87_Data_4595, Sfx2_87_Data_459A, Sfx2_87_Data_459F
Sfx2_87_Data_4590:
	db $40, $81, $63, $85, $08
Sfx2_87_Data_4595:
	db $40, $81, $c6, $82, $08
Sfx2_87_Data_459A:
	db $40, $81, $63, $85, $08
Sfx2_87_Data_459F:
	db $40, $88, $16, $84, $30
Sfx3_83_Init:
	ld hl, Sfx3_83_Data_54AB
	call Sfx3_LoadWave
	ld hl, Sfx3_83_Data_45CF
	jp Sfx3_Start

Sfx3_83_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_83_Data_45C5
	call GetPointer
	jp SetRegs_Ch3

Sfx3_83_Data_45C5:
	dw Sfx3_83_Data_45D5, Sfx3_83_Data_45DB, Sfx3_83_Data_45E1, Sfx3_83_Data_45E7, Sfx3_83_Data_45ED
Sfx3_83_Data_45CF:
	db $80, $00, $40, $9e, $86, $05
Sfx3_83_Data_45D5:
	db $80, $00, $00, $9e, $86, $03
Sfx3_83_Data_45DB:
	db $80, $00, $00, $9e, $86, $08
Sfx3_83_Data_45E1:
	db $80, $00, $40, $9e, $86, $05
Sfx3_83_Data_45E7:
	db $80, $00, $00, $9e, $86, $03
Sfx3_83_Data_45ED:
	db $80, $00, $40, $b2, $86, $30
Sfx4_89_Init:
	ld hl, Sfx4_89_Data_462E
	jp Sfx4_Start

Sfx4_89_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $11
	jp z, Sfx4_Stop
	ld hl, Sfx4_89_Data_460E
	call GetPointer
	jp SetRegs_Ch4

Sfx4_89_Data_460E:
	dw Sfx4_89_Data_4633, Sfx4_89_Data_4638, Sfx4_89_Data_463D, Sfx4_89_Data_4642, Sfx4_89_Data_4647, Sfx4_89_Data_464C, Sfx4_89_Data_4651, Sfx4_89_Data_4656, Sfx4_89_Data_465B, Sfx4_89_Data_4660, Sfx4_89_Data_4665, Sfx4_89_Data_466A, Sfx4_89_Data_466F, Sfx4_89_Data_4674, Sfx4_89_Data_4679, Sfx4_89_Data_467E
Sfx4_89_Data_462E:
	db $00, $91, $20, $80, $08
Sfx4_89_Data_4633:
	db $00, $91, $20, $80, $04
Sfx4_89_Data_4638:
	db $00, $91, $10, $80, $04
Sfx4_89_Data_463D:
	db $00, $91, $30, $80, $08
Sfx4_89_Data_4642:
	db $00, $91, $30, $80, $03
Sfx4_89_Data_4647:
	db $00, $81, $30, $80, $03
Sfx4_89_Data_464C:
	db $00, $71, $30, $80, $03
Sfx4_89_Data_4651:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_4656:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_465B:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_4660:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_4665:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_466A:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_466F:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_4674:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_4679:
	db $00, $61, $20, $80, $03
Sfx4_89_Data_467E:
	db $00, $61, $20, $80, $03
Sfx1_8A_Init:
	ld a, $85
	ld [wSfx2Request], a
	ld hl, Sfx1_8A_Data_46FB
	jp Sfx1_Start

Sfx1_8A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $2c
	jp z, Sfx1_Stop
	ld hl, Sfx1_8A_Data_46A5
	call GetPointer
	jp SetRegs_Ch1

Sfx2_85_Data_46A3:
	dw Sfx1_8A_Data_46FB
Sfx1_8A_Data_46A5:
	dw Sfx1_8A_Data_4701, Sfx1_8A_Data_4707, Sfx1_8A_Data_470D, Sfx1_8A_Data_4713, Sfx1_8A_Data_4719, Sfx1_8A_Data_471F, Sfx1_8A_Data_4725, Sfx1_8A_Data_472B, Sfx1_8A_Data_4731, Sfx1_8A_Data_4737, Sfx1_8A_Data_473D, Sfx1_8A_Data_4743, Sfx1_8A_Data_4749, Sfx1_8A_Data_474F, Sfx1_8A_Data_4755, Sfx1_8A_Data_475B, Sfx1_8A_Data_4761, Sfx1_8A_Data_4767, Sfx1_8A_Data_476D, Sfx1_8A_Data_4773, Sfx1_8A_Data_4779, Sfx1_8A_Data_477F, Sfx1_8A_Data_4785, Sfx1_8A_Data_478B, Sfx1_8A_Data_4791, Sfx1_8A_Data_4797, Sfx1_8A_Data_479D, Sfx1_8A_Data_47A3, Sfx1_8A_Data_47A9, Sfx1_8A_Data_47AF, Sfx1_8A_Data_47B5, Sfx1_8A_Data_47BB, Sfx1_8A_Data_47C1, Sfx1_8A_Data_47C7, Sfx1_8A_Data_47CD, Sfx1_8A_Data_47D3, Sfx1_8A_Data_47D9, Sfx1_8A_Data_47DF, Sfx1_8A_Data_47E5, Sfx1_8A_Data_47EB, Sfx1_8A_Data_47F1, Sfx1_8A_Data_47F1+6, Sfx1_8A_Data_47F1+12
Sfx1_8A_Data_46FB:
	db $08, $40, $98, $06, $87, $02
Sfx1_8A_Data_4701:
	db $08, $40, $98, $21, $87, $02
Sfx1_8A_Data_4707:
	db $08, $40, $98, $2d, $87, $02
Sfx1_8A_Data_470D:
	db $08, $40, $98, $39, $87, $02
Sfx1_8A_Data_4713:
	db $08, $00, $88, $21, $87, $02
Sfx1_8A_Data_4719:
	db $08, $00, $88, $39, $87, $02
Sfx1_8A_Data_471F:
	db $08, $00, $88, $44, $87, $02
Sfx1_8A_Data_4725:
	db $08, $00, $88, $4f, $87, $02
Sfx1_8A_Data_472B:
	db $08, $40, $78, $39, $87, $02
Sfx1_8A_Data_4731:
	db $08, $40, $78, $4f, $87, $02
Sfx1_8A_Data_4737:
	db $08, $40, $78, $59, $87, $02
Sfx1_8A_Data_473D:
	db $08, $40, $78, $62, $87, $02
Sfx1_8A_Data_4743:
	db $08, $00, $68, $44, $87, $02
Sfx1_8A_Data_4749:
	db $08, $00, $68, $59, $87, $02
Sfx1_8A_Data_474F:
	db $08, $00, $68, $62, $87, $02
Sfx1_8A_Data_4755:
	db $08, $00, $68, $6b, $87, $02
Sfx1_8A_Data_475B:
	db $08, $40, $58, $59, $87, $02
Sfx1_8A_Data_4761:
	db $08, $40, $58, $6b, $87, $02
Sfx1_8A_Data_4767:
	db $08, $40, $58, $74, $87, $02
Sfx1_8A_Data_476D:
	db $08, $40, $58, $7b, $87, $02
Sfx1_8A_Data_4773:
	db $08, $00, $58, $6b, $87, $02
Sfx1_8A_Data_4779:
	db $08, $00, $58, $7b, $87, $02
Sfx1_8A_Data_477F:
	db $08, $00, $58, $83, $87, $02
Sfx1_8A_Data_4785:
	db $08, $00, $58, $8a, $87, $02
Sfx1_8A_Data_478B:
	db $08, $40, $58, $7b, $87, $02
Sfx1_8A_Data_4791:
	db $08, $40, $58, $8a, $87, $02
Sfx1_8A_Data_4797:
	db $08, $40, $58, $90, $87, $02
Sfx1_8A_Data_479D:
	db $08, $40, $58, $97, $87, $02
Sfx1_8A_Data_47A3:
	db $08, $00, $58, $83, $87, $02
Sfx1_8A_Data_47A9:
	db $08, $00, $58, $90, $87, $02
Sfx1_8A_Data_47AF:
	db $08, $00, $58, $97, $87, $02
Sfx1_8A_Data_47B5:
	db $08, $00, $58, $9d, $87, $02
Sfx1_8A_Data_47BB:
	db $08, $40, $48, $90, $87, $02
Sfx1_8A_Data_47C1:
	db $08, $40, $48, $9d, $87, $02
Sfx1_8A_Data_47C7:
	db $08, $40, $48, $a2, $87, $02
Sfx1_8A_Data_47CD:
	db $08, $40, $48, $a7, $87, $02
Sfx1_8A_Data_47D3:
	db $08, $00, $38, $9d, $87, $02
Sfx1_8A_Data_47D9:
	db $08, $00, $38, $a7, $87, $02
Sfx1_8A_Data_47DF:
	db $08, $00, $38, $ac, $87, $02
Sfx1_8A_Data_47E5:
	db $08, $00, $38, $b1, $87, $02
Sfx1_8A_Data_47EB:
	db $08, $40, $28, $a2, $87, $02
Sfx1_8A_Data_47F1:
	db $08, $40, $28, $ac, $87, $02
	db $08, $40, $28, $b1, $87, $02
	db $08, $40, $28, $b6, $87, $02
Sfx2_85_Init:
	ld hl, Sfx2_85_Data_481F
	jp Sfx2_Start

Sfx2_85_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $2d
	jp z, Sfx2_Stop
	ld hl, Sfx2_85_Data_46A3
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx2_85_Data_481F:
	db $00, $08, $b6, $87, $06
Sfx1_87_Init:
	ld a, [wSfx1Playing]
	cp $87
	jp z, Sfx1_Refuse
	ld a, $84
	ld [wSfx4Request], a
	ld hl, Sfx1_87_Data_48C8
	jp Sfx1_Start

Sfx1_87_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $3f
	jp z, Sfx1_Stop
	ld hl, Sfx1_87_Data_484C
	call GetPointer
	jp SetRegsPartial_Ch1

Sfx1_87_Data_484C:
	dw Sfx1_87_Data_48CE, Sfx1_87_Data_48D4, Sfx1_87_Data_48DA, Sfx1_87_Data_48E0, Sfx1_87_Data_48E6, Sfx1_87_Data_48EC, Sfx1_87_Data_48F2, Sfx1_87_Data_48F8, Sfx1_87_Data_48FE, Sfx1_87_Data_4904, Sfx1_87_Data_490A, Sfx1_87_Data_4910, Sfx1_87_Data_4916, Sfx1_87_Data_491C, Sfx1_87_Data_4922, Sfx1_87_Data_4928, Sfx1_87_Data_492E, Sfx1_87_Data_4934, Sfx1_87_Data_493A, Sfx1_87_Data_4940, Sfx1_87_Data_4946, Sfx1_87_Data_494C, Sfx1_87_Data_4952, Sfx1_87_Data_4958, Sfx1_87_Data_495E, Sfx1_87_Data_4964, Sfx1_87_Data_496A, Sfx1_87_Data_4970, Sfx1_87_Data_4976, Sfx1_87_Data_497C, Sfx1_87_Data_4982, Sfx1_87_Data_4988, Sfx1_87_Data_498E, Sfx1_87_Data_4994, Sfx1_87_Data_499A, Sfx1_87_Data_49A0, Sfx1_87_Data_49A6, Sfx1_87_Data_49AC, Sfx1_87_Data_49B2, Sfx1_87_Data_49B8, Sfx1_87_Data_49BE, Sfx1_87_Data_49BE+6, Sfx1_87_Data_49BE+12, Sfx1_87_Data_49BE+18, Sfx1_87_Data_49BE+24, Sfx1_87_Data_49BE+30, Sfx1_87_Data_49BE+36, Sfx1_87_Data_49BE+42, Sfx1_87_Data_49BE+48, Sfx1_87_Data_49BE+54, Sfx1_87_Data_49BE+60, Sfx1_87_Data_49BE+66, Sfx1_87_Data_49BE+72, Sfx1_87_Data_49BE+78, Sfx1_87_Data_49BE+84, Sfx1_87_Data_49BE+90, Sfx1_87_Data_49BE+96, Sfx1_87_Data_49BE+102, Sfx1_87_Data_49BE+108, Sfx1_87_Data_49BE+114, Sfx1_87_Data_49BE+120, Sfx1_87_Data_49BE+126
Sfx1_87_Data_48C8:
	db $08, $40, $48, $39, $87, $01
Sfx1_87_Data_48CE:
	db $00, $00, $00, $3f, $07, $01
Sfx1_87_Data_48D4:
	db $00, $00, $00, $46, $07, $01
Sfx1_87_Data_48DA:
	db $00, $00, $00, $42, $07, $01
Sfx1_87_Data_48E0:
	db $00, $00, $00, $48, $07, $01
Sfx1_87_Data_48E6:
	db $00, $00, $00, $43, $07, $01
Sfx1_87_Data_48EC:
	db $00, $00, $00, $4a, $07, $01
Sfx1_87_Data_48F2:
	db $00, $00, $00, $50, $07, $01
Sfx1_87_Data_48F8:
	db $00, $00, $00, $57, $07, $01
Sfx1_87_Data_48FE:
	db $00, $00, $00, $53, $07, $01
Sfx1_87_Data_4904:
	db $00, $00, $00, $59, $07, $01
Sfx1_87_Data_490A:
	db $00, $00, $00, $54, $07, $01
Sfx1_87_Data_4910:
	db $00, $00, $00, $5b, $07, $01
Sfx1_87_Data_4916:
	db $00, $00, $00, $61, $07, $01
Sfx1_87_Data_491C:
	db $00, $00, $00, $68, $07, $01
Sfx1_87_Data_4922:
	db $00, $00, $00, $64, $07, $01
Sfx1_87_Data_4928:
	db $00, $00, $00, $6a, $07, $01
Sfx1_87_Data_492E:
	db $00, $00, $00, $65, $07, $01
Sfx1_87_Data_4934:
	db $00, $00, $00, $6c, $07, $01
Sfx1_87_Data_493A:
	db $00, $00, $00, $72, $07, $01
Sfx1_87_Data_4940:
	db $00, $00, $00, $79, $07, $01
Sfx1_87_Data_4946:
	db $00, $00, $00, $75, $07, $01
Sfx1_87_Data_494C:
	db $00, $00, $00, $7b, $07, $01
Sfx1_87_Data_4952:
	db $00, $00, $00, $76, $07, $01
Sfx1_87_Data_4958:
	db $00, $00, $00, $7d, $07, $01
Sfx1_87_Data_495E:
	db $00, $00, $00, $83, $07, $01
Sfx1_87_Data_4964:
	db $00, $00, $00, $8a, $07, $01
Sfx1_87_Data_496A:
	db $00, $00, $00, $86, $07, $01
Sfx1_87_Data_4970:
	db $00, $00, $00, $8c, $07, $01
Sfx1_87_Data_4976:
	db $00, $00, $00, $87, $07, $01
Sfx1_87_Data_497C:
	db $00, $00, $00, $8e, $07, $01
Sfx1_87_Data_4982:
	db $00, $00, $00, $8b, $07, $01
Sfx1_87_Data_4988:
	db $00, $00, $00, $8e, $07, $01
Sfx1_87_Data_498E:
	db $00, $00, $08, $39, $87, $07
Sfx1_87_Data_4994:
	db $00, $00, $48, $59, $87, $01
Sfx1_87_Data_499A:
	db $00, $00, $00, $55, $07, $01
Sfx1_87_Data_49A0:
	db $00, $00, $00, $4e, $07, $02
Sfx1_87_Data_49A6:
	db $00, $00, $00, $52, $07, $01
Sfx1_87_Data_49AC:
	db $00, $00, $00, $4e, $07, $01
Sfx1_87_Data_49B2:
	db $00, $00, $00, $47, $07, $02
Sfx1_87_Data_49B8:
	db $00, $00, $00, $4b, $07, $01
Sfx1_87_Data_49BE:
	db $00, $00, $00, $47, $07, $01
	db $00, $00, $00, $40, $07, $02
	db $00, $00, $00, $44, $07, $01
	db $00, $00, $00, $40, $07, $01
	db $00, $00, $00, $39, $07, $02
	db $00, $00, $00, $3d, $07, $01
	db $00, $00, $38, $50, $87, $02
	db $00, $00, $00, $42, $07, $04
	db $00, $00, $00, $45, $07, $02
	db $00, $00, $00, $3c, $07, $02
	db $00, $00, $00, $2e, $07, $04
	db $00, $00, $00, $31, $07, $02
	db $00, $00, $00, $28, $07, $02
	db $00, $00, $00, $1a, $07, $04
	db $00, $00, $00, $1d, $07, $02
	db $00, $00, $00, $14, $07, $02
	db $00, $00, $00, $06, $07, $04
	db $00, $00, $00, $09, $07, $02
	db $00, $00, $00, $00, $07, $02
	db $00, $00, $00, $f2, $06, $04
	db $00, $00, $00, $f5, $06, $02
	db $00, $00, $08, $59, $87, $13
Sfx4_84_Init:
	ld hl, Sfx4_84_Data_4AF7
	jp Sfx4_Start

Sfx4_84_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $4e
	jp z, Sfx4_Stop
	ld hl, Sfx4_84_Data_4A5D
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_84_Data_4A5D:
	dw Sfx4_84_Data_4AFC, Sfx4_84_Data_4B01, Sfx4_84_Data_4B06, Sfx4_84_Data_4B0B, Sfx4_84_Data_4B10, Sfx4_84_Data_4B15, Sfx4_84_Data_4B1A, Sfx4_84_Data_4B1F, Sfx4_84_Data_4B24, Sfx4_84_Data_4B29, Sfx4_84_Data_4B2E, Sfx4_84_Data_4B33, Sfx4_84_Data_4B38, Sfx4_84_Data_4B3D, Sfx4_84_Data_4B42, Sfx4_84_Data_4B47, Sfx4_84_Data_4B4C, Sfx4_84_Data_4B51, Sfx4_84_Data_4B56, Sfx4_84_Data_4B5B, Sfx4_84_Data_4B60, Sfx4_84_Data_4B65, Sfx4_84_Data_4B6A, Sfx4_84_Data_4B6F, Sfx4_84_Data_4B74, Sfx4_84_Data_4B79, Sfx4_84_Data_4B7E, Sfx4_84_Data_4B83, Sfx4_84_Data_4B88, Sfx4_84_Data_4B8D, Sfx4_84_Data_4B92, Sfx4_84_Data_4B97, Sfx4_84_Data_4B9C, Sfx4_84_Data_4BA1, Sfx4_84_Data_4BA6, Sfx4_84_Data_4BAB, Sfx4_84_Data_4BB0, Sfx4_84_Data_4BB5, Sfx4_84_Data_4BBA, Sfx4_84_Data_4BBF, Sfx4_84_Data_4BC4, Sfx4_84_Data_4BC4+5, Sfx4_84_Data_4BC4+10, Sfx4_84_Data_4BC4+15, Sfx4_84_Data_4BC4+20, Sfx4_84_Data_4BC4+25, Sfx4_84_Data_4BC4+30, Sfx4_84_Data_4BC4+35, Sfx4_84_Data_4BC4+40, Sfx4_84_Data_4BC4+45, Sfx4_84_Data_4BC4+50, Sfx4_84_Data_4BC4+55, Sfx4_84_Data_4BC4+60, Sfx4_84_Data_4BC4+65, Sfx4_84_Data_4BC4+70, Sfx4_84_Data_4BC4+75, Sfx4_84_Data_4BC4+80, Sfx4_84_Data_4BC4+85, Sfx4_84_Data_4BC4+90, Sfx4_84_Data_4BC4+95, Sfx4_84_Data_4BC4+100, Sfx4_84_Data_4BC4+105, Sfx4_84_Data_4BC4+110, Sfx4_84_Data_4BC4+115, Sfx4_84_Data_4BC4+120, Sfx4_84_Data_4BC4+125, Sfx4_84_Data_4BC4+130, Sfx4_84_Data_4BC4+135, Sfx4_84_Data_4BC4+140, Sfx4_84_Data_4BC4+145, Sfx4_84_Data_4BC4+150, Sfx4_84_Data_4BC4+155, Sfx4_84_Data_4BC4+160, Sfx4_84_Data_4BC4+165, Sfx4_84_Data_4BC4+170, Sfx4_84_Data_4BC4+175, Sfx4_84_Data_4BC4+180
Sfx4_84_Data_4AF7:
	db $00, $18, $50, $80, $02
Sfx4_84_Data_4AFC:
	db $00, $38, $23, $80, $02
Sfx4_84_Data_4B01:
	db $00, $00, $07, $00, $03
Sfx4_84_Data_4B06:
	db $00, $58, $30, $80, $03
Sfx4_84_Data_4B0B:
	db $00, $00, $20, $00, $04
Sfx4_84_Data_4B10:
	db $00, $78, $10, $80, $04
Sfx4_84_Data_4B15:
	db $00, $a8, $00, $80, $04
Sfx4_84_Data_4B1A:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B1F:
	db $00, $00, $00, $00, $01
Sfx4_84_Data_4B24:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B29:
	db $00, $00, $00, $00, $01
Sfx4_84_Data_4B2E:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B33:
	db $00, $00, $00, $00, $01
Sfx4_84_Data_4B38:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B3D:
	db $00, $68, $00, $80, $01
Sfx4_84_Data_4B42:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B47:
	db $00, $58, $00, $80, $01
Sfx4_84_Data_4B4C:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B51:
	db $00, $48, $00, $80, $01
Sfx4_84_Data_4B56:
	db $00, $00, $10, $00, $01
Sfx4_84_Data_4B5B:
	db $00, $08, $00, $80, $09
Sfx4_84_Data_4B60:
	db $00, $08, $00, $80, $01
Sfx4_84_Data_4B65:
	db $00, $18, $30, $80, $01
Sfx4_84_Data_4B6A:
	db $00, $00, $07, $00, $02
Sfx4_84_Data_4B6F:
	db $00, $00, $23, $00, $02
Sfx4_84_Data_4B74:
	db $00, $38, $50, $80, $02
Sfx4_84_Data_4B79:
	db $00, $00, $33, $00, $02
Sfx4_84_Data_4B7E:
	db $00, $48, $60, $80, $02
Sfx4_84_Data_4B83:
	db $00, $00, $43, $00, $02
Sfx4_84_Data_4B88:
	db $00, $58, $70, $80, $01
Sfx4_84_Data_4B8D:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4B92:
	db $00, $00, $70, $00, $01
Sfx4_84_Data_4B97:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4B9C:
	db $00, $00, $70, $00, $01
Sfx4_84_Data_4BA1:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4BA6:
	db $00, $00, $70, $00, $01
Sfx4_84_Data_4BAB:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4BB0:
	db $00, $00, $70, $00, $01
Sfx4_84_Data_4BB5:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4BBA:
	db $00, $00, $70, $00, $01
Sfx4_84_Data_4BBF:
	db $00, $00, $43, $00, $01
Sfx4_84_Data_4BC4:
	db $00, $48, $70, $80, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $38, $70, $80, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $28, $70, $80, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $00, $70, $00, $01
	db $00, $00, $43, $00, $01
	db $00, $08, $00, $80, $0e
Sfx1_86_Init:
	ld a, $82
	ld [wSfx2Request], a
	ld a, $86
	ld [wSfx3Request], a
	ld a, $8f
	ld [wSfx4Request], a
	ld a, [wSongPlaying]
	ld [wSongRequest], a
	xor a
	ld [wHurryJingle], a
	ld hl, Sfx1_86_Data_4D5F
	jp Sfx1_Start

Sfx1_86_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $57
	jp z, Sfx1_Stop
	ld hl, Sfx1_86_Data_4CB3
	call GetPointer
	jp SetRegsPartial_Ch1

Sfx2_82_Data_4CB1:
	dw Sfx1_86_Data_4D5F
Sfx1_86_Data_4CB3:
	dw Sfx1_86_Data_4D65, Sfx1_86_Data_4D6B, Sfx1_86_Data_4D71, Sfx1_86_Data_4D77, Sfx1_86_Data_4D7D, Sfx1_86_Data_4D83, Sfx1_86_Data_4D89, Sfx1_86_Data_4D8F, Sfx1_86_Data_4D95, Sfx1_86_Data_4D9B, Sfx1_86_Data_4DA1, Sfx1_86_Data_4DA7, Sfx1_86_Data_4DAD, Sfx1_86_Data_4DB3, Sfx1_86_Data_4DB9, Sfx1_86_Data_4DBF, Sfx1_86_Data_4DC5, Sfx1_86_Data_4DCB, Sfx1_86_Data_4DD1, Sfx1_86_Data_4DD7, Sfx1_86_Data_4DDD, Sfx1_86_Data_4DE3, Sfx1_86_Data_4DE9, Sfx1_86_Data_4DEF, Sfx1_86_Data_4DF5, Sfx1_86_Data_4DFB, Sfx1_86_Data_4E01, Sfx1_86_Data_4E07, Sfx1_86_Data_4E0D, Sfx1_86_Data_4E13, Sfx1_86_Data_4E19, Sfx1_86_Data_4E1F, Sfx1_86_Data_4E25, Sfx1_86_Data_4E2B, Sfx1_86_Data_4E31, Sfx1_86_Data_4E37, Sfx1_86_Data_4E3D, Sfx1_86_Data_4E43, Sfx1_86_Data_4E49, Sfx1_86_Data_4E4F, Sfx1_86_Data_4E55, Sfx1_86_Data_4E55+6, Sfx1_86_Data_4E55+12, Sfx1_86_Data_4E55+18, Sfx1_86_Data_4E55+24, Sfx1_86_Data_4E55+30, Sfx1_86_Data_4E55+36, Sfx1_86_Data_4E55+42, Sfx1_86_Data_4E55+48, Sfx1_86_Data_4E55+54, Sfx1_86_Data_4E55+60, Sfx1_86_Data_4E55+66, Sfx1_86_Data_4E55+72, Sfx1_86_Data_4E55+78, Sfx1_86_Data_4E55+84, Sfx1_86_Data_4E55+90, Sfx1_86_Data_4E55+96, Sfx1_86_Data_4E55+102, Sfx1_86_Data_4E55+108, Sfx1_86_Data_4E55+114, Sfx1_86_Data_4E55+120, Sfx1_86_Data_4E55+126, Sfx1_86_Data_4E55+132, Sfx1_86_Data_4E55+138, Sfx1_86_Data_4E55+144, Sfx1_86_Data_4E55+150, Sfx1_86_Data_4E55+156, Sfx1_86_Data_4E55+162, Sfx1_86_Data_4E55+168, Sfx1_86_Data_4E55+174, Sfx1_86_Data_4E55+180, Sfx1_86_Data_4E55+186, Sfx1_86_Data_4E55+192, Sfx1_86_Data_4E55+198, Sfx1_86_Data_4E55+204, Sfx1_86_Data_4E55+210, Sfx1_86_Data_4E55+216, Sfx1_86_Data_4E55+222, Sfx1_86_Data_4E55+228, Sfx1_86_Data_4E55+234, Sfx1_86_Data_4E55+240, Sfx1_86_Data_4E55+246, Sfx1_86_Data_4E55+252, Sfx1_86_Data_4E55+258, Sfx1_86_Data_4E55+264, Sfx1_86_Data_4E55+270
Sfx1_86_Data_4D5F:
	db $08, $00, $e8, $44, $87, $01
Sfx1_86_Data_4D65:
	db $00, $00, $00, $53, $07, $01
Sfx1_86_Data_4D6B:
	db $00, $00, $00, $48, $07, $01
Sfx1_86_Data_4D71:
	db $00, $00, $00, $57, $07, $01
Sfx1_86_Data_4D77:
	db $00, $00, $00, $4c, $07, $01
Sfx1_86_Data_4D7D:
	db $00, $00, $00, $5b, $07, $01
Sfx1_86_Data_4D83:
	db $00, $00, $00, $50, $07, $01
Sfx1_86_Data_4D89:
	db $00, $00, $00, $5f, $07, $01
Sfx1_86_Data_4D8F:
	db $00, $00, $00, $54, $07, $01
Sfx1_86_Data_4D95:
	db $00, $00, $00, $63, $07, $01
Sfx1_86_Data_4D9B:
	db $00, $00, $00, $58, $07, $01
Sfx1_86_Data_4DA1:
	db $00, $00, $00, $67, $07, $01
Sfx1_86_Data_4DA7:
	db $00, $00, $00, $5c, $07, $01
Sfx1_86_Data_4DAD:
	db $00, $00, $00, $ac, $07, $01
Sfx1_86_Data_4DB3:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4DB9:
	db $00, $00, $00, $ac, $07, $01
Sfx1_86_Data_4DBF:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4DC5:
	db $00, $00, $08, $b1, $87, $04
Sfx1_86_Data_4DCB:
	db $00, $00, $e8, $b7, $87, $01
Sfx1_86_Data_4DD1:
	db $00, $00, $00, $af, $07, $01
Sfx1_86_Data_4DD7:
	db $00, $00, $00, $b7, $07, $01
Sfx1_86_Data_4DDD:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4DE3:
	db $00, $00, $00, $b7, $07, $01
Sfx1_86_Data_4DE9:
	db $00, $00, $00, $af, $07, $01
Sfx1_86_Data_4DEF:
	db $00, $00, $00, $b7, $07, $01
Sfx1_86_Data_4DF5:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4DFB:
	db $00, $00, $00, $b7, $07, $01
Sfx1_86_Data_4E01:
	db $00, $00, $00, $af, $07, $01
Sfx1_86_Data_4E07:
	db $00, $00, $00, $b7, $07, $01
Sfx1_86_Data_4E0D:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4E13:
	db $00, $00, $08, $b1, $87, $08
Sfx1_86_Data_4E19:
	db $00, $00, $e8, $b8, $87, $01
Sfx1_86_Data_4E1F:
	db $00, $00, $00, $bd, $07, $01
Sfx1_86_Data_4E25:
	db $00, $00, $00, $b6, $07, $01
Sfx1_86_Data_4E2B:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4E31:
	db $00, $00, $00, $b8, $07, $01
Sfx1_86_Data_4E37:
	db $00, $00, $00, $bd, $07, $01
Sfx1_86_Data_4E3D:
	db $00, $00, $00, $b6, $07, $01
Sfx1_86_Data_4E43:
	db $00, $00, $00, $b1, $07, $01
Sfx1_86_Data_4E49:
	db $00, $00, $00, $b8, $07, $01
Sfx1_86_Data_4E4F:
	db $00, $00, $00, $bd, $07, $01
Sfx1_86_Data_4E55:
	db $00, $00, $00, $b6, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $ab, $07, $01
	db $00, $00, $00, $b0, $07, $01
	db $00, $00, $d8, $a7, $87, $01
	db $00, $00, $00, $ae, $07, $01
	db $00, $00, $c8, $a6, $87, $01
	db $00, $00, $00, $af, $07, $01
	db $00, $00, $b8, $a8, $87, $01
	db $00, $00, $00, $ad, $07, $01
	db $00, $00, $a8, $a4, $87, $01
	db $00, $00, $00, $ab, $07, $01
	db $00, $00, $48, $b7, $87, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b2, $07, $01
	db $00, $00, $00, $b7, $07, $01
	db $00, $00, $00, $b1, $07, $01
	db $00, $00, $00, $ab, $07, $01
	db $00, $00, $00, $b0, $07, $01
	db $00, $00, $38, $a7, $87, $01
	db $00, $00, $00, $ae, $07, $01
	db $00, $00, $28, $a6, $87, $01
	db $00, $00, $00, $af, $07, $01
	db $00, $00, $18, $a8, $87, $01
	db $00, $00, $00, $ad, $07, $01
	db $00, $00, $08, $a4, $87, $01
	db $00, $00, $00, $ab, $07, $01
Sfx2_82_Init:
	ld hl, Sfx2_82_Data_4F85
	jp Sfx2_Start

Sfx2_82_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $58
	jp z, Sfx2_Stop
	ld hl, Sfx2_82_Data_4CB1
	call GetPointer
	inc hl
	jp SetRegsPartial_Ch2_Unused

Sfx2_82_Data_4F85:
	db $00, $08, $b6, $87, $02
Sfx3_86_Init:
	ld hl, Sfx3_86_Data_4F97
	jp Sfx3_Start

Sfx3_86_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx3_Stop

Sfx3_86_Data_4F97:
	db $80, $00, $00, $d6, $87, $64
Sfx4_8F_Init:
	ld hl, Sfx4_8F_Data_4FAA
	jp Sfx4_Start

Sfx4_8F_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_8F_Data_4FAA:
	db $00, $08, $05, $80, $64
Sfx1_8F_Init:
	ld hl, Sfx1_8F_Data_4FBE
	jp Sfx1_StartSweep

Sfx1_8F_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Release

Sfx1_8F_Data_4FBE:
	db $1a, $40, $92, $b2, $86, $08
Sfx1_90_Init:
	ld hl, Sfx1_90_Data_4FD3
	jp Sfx1_StartSweep

Sfx1_90_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Release

Sfx1_90_Data_4FD3:
	db $1a, $40, $b2, $72, $86, $08
Sfx1_88_Init:
	ld a, $85
	ld [wSfx4Request], a
	ld hl, Sfx1_88_Data_5005
	jp Sfx1_Start

Sfx1_88_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx1_Stop
	ld hl, Sfx1_88_Data_4FF9
	call GetPointer
	jp SetRegs_Ch1

Sfx1_88_Data_4FF9:
	dw Sfx1_88_Data_500B, Sfx1_88_Data_5011, Sfx1_88_Data_5017, Sfx1_88_Data_501D, Sfx1_88_Data_5023, Sfx1_88_Data_5029
Sfx1_88_Data_5005:
	db $08, $40, $c8, $57, $85, $01
Sfx1_88_Data_500B:
	db $08, $40, $b8, $25, $85, $01
Sfx1_88_Data_5011:
	db $08, $40, $a8, $f3, $84, $01
Sfx1_88_Data_5017:
	db $08, $40, $98, $c1, $84, $01
Sfx1_88_Data_501D:
	db $08, $40, $88, $8f, $84, $01
Sfx1_88_Data_5023:
	db $08, $40, $78, $5d, $84, $01
Sfx1_88_Data_5029:
	db $08, $40, $68, $2b, $84, $01
Sfx4_85_Init:
	ld hl, Sfx4_85_Data_505C
	jp Sfx4_Start

Sfx4_85_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx4_Stop
	ld hl, Sfx4_85_Data_504A
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_85_Data_504A:
	dw Sfx4_85_Data_5061, Sfx4_85_Data_5066, Sfx4_85_Data_506B, Sfx4_85_Data_5070, Sfx4_85_Data_5075, Sfx4_85_Data_507A, Sfx4_85_Data_507F, Sfx4_85_Data_5084, Sfx4_85_Data_5089
Sfx4_85_Data_505C:
	db $00, $b8, $30, $80, $01
Sfx4_85_Data_5061:
	db $00, $00, $43, $00, $01
Sfx4_85_Data_5066:
	db $00, $00, $47, $00, $01
Sfx4_85_Data_506B:
	db $00, $00, $55, $00, $01
Sfx4_85_Data_5070:
	db $00, $68, $65, $80, $01
Sfx4_85_Data_5075:
	db $00, $58, $47, $80, $01
Sfx4_85_Data_507A:
	db $00, $48, $65, $80, $01
Sfx4_85_Data_507F:
	db $00, $38, $47, $80, $01
Sfx4_85_Data_5084:
	db $00, $28, $65, $80, $01
Sfx4_85_Data_5089:
	db $00, $38, $47, $80, $01
Sfx2_80_Init:
	jp Sfx2_Refuse

Sfx2_80_Play:
	ret

Sfx2_8B_Init:
	ld a, [wSfx4Request]
	cp $8b
	jr z, .l0
	ld a, $90
	ld [wSfx4Request], a
.l0:
	ld a, [wSfx2Playing]
	cp $8b
	jr nz, .l1
	jp Sfx2_Continue

.l1:
	ld hl, Sfx2_8B_Data_5128
	jp Sfx2_Start

Sfx2_8B_Play:
	ld a, [wSfx2Request]
	cp $8b
	jp nz, Sfx2_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $2e
	jp c, .l2
	ld a, $2c
	ld [bc], a
.l2:
	ld hl, Sfx2_8B_Data_50CE
	call GetPointer
	jp SetRegs_Ch2

Sfx2_8B_Data_50CE:
	dw Sfx2_8B_Data_512D, Sfx2_8B_Data_5132, Sfx2_8B_Data_5137, Sfx2_8B_Data_513C, Sfx2_8B_Data_5141, Sfx2_8B_Data_5146, Sfx2_8B_Data_514B, Sfx2_8B_Data_5150, Sfx2_8B_Data_5155, Sfx2_8B_Data_515A, Sfx2_8B_Data_515F, Sfx2_8B_Data_5164, Sfx2_8B_Data_5169, Sfx2_8B_Data_516E, Sfx2_8B_Data_5173, Sfx2_8B_Data_5178, Sfx2_8B_Data_517D, Sfx2_8B_Data_5182, Sfx2_8B_Data_5187, Sfx2_8B_Data_518C, Sfx2_8B_Data_5191, Sfx2_8B_Data_5196, Sfx2_8B_Data_519B, Sfx2_8B_Data_51A0, Sfx2_8B_Data_51A5, Sfx2_8B_Data_51AA, Sfx2_8B_Data_51AF, Sfx2_8B_Data_51B4, Sfx2_8B_Data_51B9, Sfx2_8B_Data_51BE, Sfx2_8B_Data_51C3, Sfx2_8B_Data_51C8, Sfx2_8B_Data_51CD, Sfx2_8B_Data_51D2, Sfx2_8B_Data_51D7, Sfx2_8B_Data_51DC, Sfx2_8B_Data_51E1, Sfx2_8B_Data_51E6, Sfx2_8B_Data_51EB, Sfx2_8B_Data_51F0, Sfx2_8B_Data_51F5, Sfx2_8B_Data_51F5+5, Sfx2_8B_Data_51F5+10, Sfx2_8B_Data_51F5+15, Sfx2_8B_Data_51F5+20
Sfx2_8B_Data_5128:
	db $40, $48, $39, $87, $01
Sfx2_8B_Data_512D:
	db $40, $48, $3e, $87, $01
Sfx2_8B_Data_5132:
	db $40, $48, $45, $87, $01
Sfx2_8B_Data_5137:
	db $40, $48, $41, $87, $02
Sfx2_8B_Data_513C:
	db $40, $48, $46, $87, $01
Sfx2_8B_Data_5141:
	db $40, $58, $41, $87, $01
Sfx2_8B_Data_5146:
	db $40, $58, $48, $87, $02
Sfx2_8B_Data_514B:
	db $40, $58, $4d, $87, $01
Sfx2_8B_Data_5150:
	db $40, $58, $54, $87, $01
Sfx2_8B_Data_5155:
	db $40, $58, $50, $87, $02
Sfx2_8B_Data_515A:
	db $40, $58, $55, $87, $01
Sfx2_8B_Data_515F:
	db $40, $68, $46, $87, $01
Sfx2_8B_Data_5164:
	db $40, $68, $57, $87, $02
Sfx2_8B_Data_5169:
	db $40, $68, $5c, $87, $01
Sfx2_8B_Data_516E:
	db $40, $68, $63, $87, $01
Sfx2_8B_Data_5173:
	db $40, $68, $5f, $87, $02
Sfx2_8B_Data_5178:
	db $40, $68, $64, $87, $01
Sfx2_8B_Data_517D:
	db $40, $78, $55, $87, $01
Sfx2_8B_Data_5182:
	db $40, $78, $66, $87, $02
Sfx2_8B_Data_5187:
	db $40, $78, $6b, $87, $01
Sfx2_8B_Data_518C:
	db $40, $78, $72, $87, $01
Sfx2_8B_Data_5191:
	db $40, $78, $6e, $87, $02
Sfx2_8B_Data_5196:
	db $40, $78, $73, $87, $01
Sfx2_8B_Data_519B:
	db $40, $88, $64, $87, $01
Sfx2_8B_Data_51A0:
	db $40, $88, $75, $87, $02
Sfx2_8B_Data_51A5:
	db $40, $88, $7a, $87, $01
Sfx2_8B_Data_51AA:
	db $40, $88, $81, $87, $01
Sfx2_8B_Data_51AF:
	db $40, $88, $7d, $87, $02
Sfx2_8B_Data_51B4:
	db $40, $88, $82, $87, $01
Sfx2_8B_Data_51B9:
	db $40, $98, $73, $87, $01
Sfx2_8B_Data_51BE:
	db $40, $98, $84, $87, $02
Sfx2_8B_Data_51C3:
	db $40, $98, $89, $87, $01
Sfx2_8B_Data_51C8:
	db $40, $98, $90, $87, $01
Sfx2_8B_Data_51CD:
	db $40, $98, $8c, $87, $02
Sfx2_8B_Data_51D2:
	db $40, $98, $8e, $87, $01
Sfx2_8B_Data_51D7:
	db $40, $a8, $82, $87, $01
Sfx2_8B_Data_51DC:
	db $40, $a8, $93, $87, $02
Sfx2_8B_Data_51E1:
	db $40, $a8, $98, $87, $01
Sfx2_8B_Data_51E6:
	db $40, $a8, $9f, $87, $01
Sfx2_8B_Data_51EB:
	db $40, $a8, $9b, $87, $02
Sfx2_8B_Data_51F0:
	db $40, $a8, $9d, $87, $01
Sfx2_8B_Data_51F5:
	db $40, $b8, $91, $87, $01
	db $40, $b8, $a2, $87, $02
	db $40, $98, $a1, $87, $01
	db $40, $98, $a3, $87, $01
	db $40, $98, $a1, $87, $01
Sfx4_90_Init:
	ld a, [wSfx4Playing]
	cp $90
	jr nz, .l0
	jp Sfx4_Continue

.l0:
	ld hl, Sfx4_90_Data_524A
	jp Sfx4_Start

Sfx4_90_Play:
	ld a, [wSfx4Request]
	cp $90
	jp nz, Sfx4_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp c, .l1
	ld a, $05
	ld [bc], a
.l1:
	ld hl, Sfx4_90_Data_523E
	call GetPointer
	jp SetRegs_Ch4

Sfx4_90_Data_523E:
	dw Sfx4_90_Data_524F, Sfx4_90_Data_5254, Sfx4_90_Data_5259, Sfx4_90_Data_525E, Sfx4_90_Data_5263, Sfx4_90_Data_5268
Sfx4_90_Data_524A:
	db $00, $28, $50, $80, $08
Sfx4_90_Data_524F:
	db $00, $48, $23, $80, $08
Sfx4_90_Data_5254:
	db $00, $68, $07, $80, $08
Sfx4_90_Data_5259:
	db $00, $88, $30, $80, $08
Sfx4_90_Data_525E:
	db $00, $a8, $20, $80, $08
Sfx4_90_Data_5263:
	db $00, $c8, $10, $80, $01
Sfx4_90_Data_5268:
	db $00, $c8, $00, $80, $01
Sfx2_8A_Init:
	ld a, [wSfx2Playing]
	cp $8a
	jp z, Sfx2_Refuse
	ld hl, Sfx2_8A_Data_52C0
	jp Sfx2_Start

Sfx2_8A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $19
	jp z, Sfx2_Stop
	ld hl, Sfx2_8A_Data_5290
	call GetPointer
	jp SetRegsPartial_Ch2_Unused

Sfx2_8A_Data_5290:
	dw Sfx2_8A_Data_52C0, Sfx2_8A_Data_52C5, Sfx2_8A_Data_52CA, Sfx2_8A_Data_52CF, Sfx2_8A_Data_52D4, Sfx2_8A_Data_52D9, Sfx2_8A_Data_52DE, Sfx2_8A_Data_52E3, Sfx2_8A_Data_52E8, Sfx2_8A_Data_52ED, Sfx2_8A_Data_52F2, Sfx2_8A_Data_52F7, Sfx2_8A_Data_52FC, Sfx2_8A_Data_5301, Sfx2_8A_Data_5306, Sfx2_8A_Data_530B, Sfx2_8A_Data_5310, Sfx2_8A_Data_5315, Sfx2_8A_Data_531A, Sfx2_8A_Data_531F, Sfx2_8A_Data_5324, Sfx2_8A_Data_5329, Sfx2_8A_Data_532E, Sfx2_8A_Data_5333
Sfx2_8A_Data_52C0:
	db $40, $3a, $9d, $87, $02
Sfx2_8A_Data_52C5:
	db $00, $00, $90, $07, $02
Sfx2_8A_Data_52CA:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_52CF:
	db $00, $00, $83, $07, $02
Sfx2_8A_Data_52D4:
	db $00, $00, $9d, $07, $02
Sfx2_8A_Data_52D9:
	db $00, $00, $90, $07, $02
Sfx2_8A_Data_52DE:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_52E3:
	db $00, $00, $83, $07, $02
Sfx2_8A_Data_52E8:
	db $00, $b2, $8a, $87, $02
Sfx2_8A_Data_52ED:
	db $00, $00, $59, $07, $02
Sfx2_8A_Data_52F2:
	db $00, $00, $39, $07, $02
Sfx2_8A_Data_52F7:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_52FC:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_5301:
	db $00, $00, $59, $07, $02
Sfx2_8A_Data_5306:
	db $00, $00, $39, $07, $02
Sfx2_8A_Data_530B:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_5310:
	db $00, $62, $8a, $87, $02
Sfx2_8A_Data_5315:
	db $00, $00, $59, $07, $02
Sfx2_8A_Data_531A:
	db $00, $00, $39, $07, $02
Sfx2_8A_Data_531F:
	db $00, $00, $8a, $07, $02
Sfx2_8A_Data_5324:
	db $00, $32, $8a, $87, $02
Sfx2_8A_Data_5329:
	db $00, $00, $59, $07, $02
Sfx2_8A_Data_532E:
	db $00, $00, $39, $07, $02
Sfx2_8A_Data_5333:
	db $00, $00, $8a, $07, $02
Sfx2_89_Init:
	ld hl, Sfx2_89_Data_535D
	jp Sfx2_Start

Sfx2_89_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx2_Stop
	ld hl, Sfx2_89_Data_5353
	call GetPointer
	jp SetRegs_Ch2

Sfx2_89_Data_5353:
	dw Sfx2_89_Data_5362, Sfx2_89_Data_5367, Sfx2_89_Data_536C, Sfx2_89_Data_5371, Sfx2_89_Data_5376
Sfx2_89_Data_535D:
	db $40, $88, $ed, $85, $02
Sfx2_89_Data_5362:
	db $40, $78, $ce, $85, $01
Sfx2_89_Data_5367:
	db $40, $48, $89, $86, $01
Sfx2_89_Data_536C:
	db $40, $38, $9e, $86, $01
Sfx2_89_Data_5371:
	db $40, $28, $b2, $86, $01
Sfx2_89_Data_5376:
	db $40, $18, $d6, $86, $01
Sfx3_80_Init:
	jp Sfx3_Refuse

Sfx3_80_Play:
	ret

Sfx3_85_Init:
	ld a, $8a
	ld [wSfx4Request], a
Sfx3_84_Init:
	ld hl, Sfx3_84_Data_54EB
	call Sfx3_LoadWave
	ld hl, Sfx3_84_Data_5401
	jp Sfx3_Start

Sfx3_84_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx3_Stop
	cp $05
	jr nz, Sfx3_84_Shared_53AA
	ld hl, Sfx3_84_Data_54FB
	call Sfx3_LoadWave
	ld a, $05
	jr Sfx3_84_Shared_53D2

Sfx3_84_Shared_53AA:
	cp $09
	jr nz, Sfx3_84_Shared_53B8
	ld hl, Sfx3_84_Data_550B
	call Sfx3_LoadWave
	ld a, $09
	jr Sfx3_84_Shared_53D2

Sfx3_84_Shared_53B8:
	cp $0d
	jr nz, Sfx3_84_Shared_53C6
	ld hl, Sfx3_84_Data_551B
	call Sfx3_LoadWave
	ld a, $0d
	jr Sfx3_84_Shared_53D2

Sfx3_84_Shared_53C6:
	cp $11
	jr nz, Sfx3_84_Shared_53D2
	ld hl, Sfx3_84_Data_552B
	call Sfx3_LoadWave
	ld a, $11
Sfx3_84_Shared_53D2:
	ld hl, Sfx3_84_Data_53DB
	call GetPointer
	jp SetRegs_Ch3

Sfx3_84_Data_53DB:
	dw Sfx3_84_Data_5407, Sfx3_84_Data_540D, Sfx3_84_Data_5413, Sfx3_84_Data_5419, Sfx3_84_Data_541F, Sfx3_84_Data_5425, Sfx3_84_Data_542B, Sfx3_84_Data_5431, Sfx3_84_Data_5437, Sfx3_84_Data_543D, Sfx3_84_Data_5443, Sfx3_84_Data_5449, Sfx3_84_Data_544F, Sfx3_84_Data_5455, Sfx3_84_Data_545B, Sfx3_84_Data_5461, Sfx3_84_Data_5467, Sfx3_84_Data_546D, Sfx3_84_Data_5473
Sfx3_84_Data_5401:
	db $80, $00, $20, $a2, $87, $02
Sfx3_84_Data_5407:
	db $80, $00, $20, $b6, $87, $02
Sfx3_84_Data_540D:
	db $80, $00, $20, $c1, $87, $02
Sfx3_84_Data_5413:
	db $80, $00, $20, $d1, $87, $02
Sfx3_84_Data_5419:
	db $80, $00, $00, $83, $87, $01
Sfx3_84_Data_541F:
	db $80, $00, $20, $a2, $87, $02
Sfx3_84_Data_5425:
	db $80, $00, $20, $b6, $87, $02
Sfx3_84_Data_542B:
	db $80, $00, $20, $c8, $87, $02
Sfx3_84_Data_5431:
	db $80, $00, $20, $d1, $87, $02
Sfx3_84_Data_5437:
	db $80, $00, $20, $a2, $87, $02
Sfx3_84_Data_543D:
	db $80, $00, $20, $b6, $87, $02
Sfx3_84_Data_5443:
	db $80, $00, $20, $c8, $87, $02
Sfx3_84_Data_5449:
	db $80, $00, $20, $d1, $87, $02
Sfx3_84_Data_544F:
	db $80, $00, $20, $a2, $87, $02
Sfx3_84_Data_5455:
	db $80, $00, $20, $b6, $87, $02
Sfx3_84_Data_545B:
	db $80, $00, $20, $c8, $87, $02
Sfx3_84_Data_5461:
	db $80, $00, $20, $d1, $87, $02
Sfx3_84_Data_5467:
	db $80, $00, $20, $a2, $87, $02
Sfx3_84_Data_546D:
	db $80, $00, $20, $b6, $87, $02
Sfx3_84_Data_5473:
	db $80, $00, $20, $c8, $87, $02
Sfx4_8A_Init:
	ld hl, Sfx4_8A_Data_5491
	jp Sfx4_Start

Sfx4_8A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_8A_Data_5496
	jp SetRegs_Ch4

Sfx4_8A_Data_5491:
	db $00, $f1, $17, $80, $04
Sfx4_8A_Data_5496:
	db $00, $52, $17, $80, $14
	db $22, $66, $aa, $ee, $ff
	db $ff, $fe, $ea, $a6, $66
	db $8a, $cf, $fe, $ec, $a6
	db $33
Sfx3_83_Data_54AB:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
	db $13, $57, $9b, $df, $db, $97, $53, $10, $13, $57, $9b, $df, $db, $97, $53, $10
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
	db $f0, $e1, $d2, $c3, $b4, $a5, $96, $87, $78, $69, $5a, $4b, $3c, $2d, $1e, $0f
Sfx3_84_Data_54EB:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
Sfx3_84_Data_54FB:
	db $99, $99, $99, $99, $00, $00, $00, $00, $99, $99, $99, $99, $00, $00, $00, $00
Sfx3_84_Data_550B:
	db $77, $77, $77, $77, $00, $00, $00, $00, $77, $77, $77, $77, $00, $00, $00, $00
Sfx3_84_Data_551B:
	db $55, $55, $55, $55, $00, $00, $00, $00, $55, $55, $55, $55, $00, $00, $00, $00
Sfx3_84_Data_552B:
	db $33, $33, $33, $33, $00, $00, $00, $00, $33, $33, $33, $33, $00, $00, $00, $00
Sfx4_80_Init:
	jp Sfx4_Refuse

Sfx4_80_Play:
	ret

Sfx4_86_Init:
	ld hl, Sfx4_86_Data_5576
	jp Sfx4_Start

Sfx4_86_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0f
	jp z, Sfx4_Stop
	ld hl, Sfx4_86_Data_555A
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_86_Data_555A:
	dw Sfx4_86_Data_557B, Sfx4_86_Data_5580, Sfx4_86_Data_5585, Sfx4_86_Data_558A, Sfx4_86_Data_558F, Sfx4_86_Data_5594, Sfx4_86_Data_5599, Sfx4_86_Data_559E, Sfx4_86_Data_55A3, Sfx4_86_Data_55A8, Sfx4_86_Data_55AD, Sfx4_86_Data_55B2, Sfx4_86_Data_55B7, Sfx4_86_Data_55BC
Sfx4_86_Data_5576:
	db $00, $58, $24, $80, $04
Sfx4_86_Data_557B:
	db $00, $98, $17, $80, $06
Sfx4_86_Data_5580:
	db $00, $00, $24, $00, $03
Sfx4_86_Data_5585:
	db $00, $00, $26, $00, $03
Sfx4_86_Data_558A:
	db $00, $00, $25, $00, $03
Sfx4_86_Data_558F:
	db $00, $70, $26, $80, $03
Sfx4_86_Data_5594:
	db $00, $00, $27, $00, $03
Sfx4_86_Data_5599:
	db $00, $00, $34, $00, $03
Sfx4_86_Data_559E:
	db $00, $50, $35, $80, $03
Sfx4_86_Data_55A3:
	db $00, $00, $37, $00, $04
Sfx4_86_Data_55A8:
	db $00, $00, $34, $00, $04
Sfx4_86_Data_55AD:
	db $00, $30, $36, $80, $04
Sfx4_86_Data_55B2:
	db $00, $00, $44, $00, $04
Sfx4_86_Data_55B7:
	db $00, $10, $46, $80, $04
Sfx4_86_Data_55BC:
	db $00, $00, $47, $00, $04
Sfx4_88_Init:
	ld hl, Sfx4_88_Data_55EA
	jp Sfx4_Start

Sfx4_88_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_88_Data_55DC
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_88_Data_55DC:
	dw Sfx4_88_Data_560D, Sfx4_88_Data_5608, Sfx4_88_Data_5603, Sfx4_88_Data_55FE, Sfx4_88_Data_55F9, Sfx4_88_Data_55F4, Sfx4_88_Data_55EF
Sfx4_88_Data_55EA:
	db $00, $98, $03, $80, $01
Sfx4_88_Data_55EF:
	db $00, $00, $05, $80, $01
Sfx4_88_Data_55F4:
	db $00, $80, $07, $80, $01
Sfx4_88_Data_55F9:
	db $00, $00, $05, $80, $02
Sfx4_88_Data_55FE:
	db $00, $70, $07, $80, $02
Sfx4_88_Data_5603:
	db $00, $00, $24, $80, $01
Sfx4_88_Data_5608:
	db $00, $60, $14, $80, $01
Sfx4_88_Data_560D:
	db $00, $00, $25, $80, $01
Sfx4_8B_Init:
	ld hl, Sfx4_8B_Data_563B
	jp Sfx4_Start

Sfx4_8B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Release
	ld hl, Sfx4_8B_Data_562D
	call GetPointer
	jp SetRegs_Ch4

Sfx4_8B_Data_562D:
	dw Sfx4_8B_Data_563B, Sfx4_8B_Data_5640, Sfx4_8B_Data_5645, Sfx4_8B_Data_564A, Sfx4_8B_Data_564F, Sfx4_8B_Data_5654, Sfx4_8B_Data_5659
Sfx4_8B_Data_563B:
	db $00, $f1, $02, $80, $01
Sfx4_8B_Data_5640:
	db $00, $f1, $25, $80, $01
Sfx4_8B_Data_5645:
	db $00, $f1, $14, $80, $01
Sfx4_8B_Data_564A:
	db $00, $e1, $17, $80, $02
Sfx4_8B_Data_564F:
	db $00, $e2, $35, $80, $02
Sfx4_8B_Data_5654:
	db $00, $d1, $08, $80, $01
Sfx4_8B_Data_5659:
	db $00, $c2, $09, $80, $08
Sfx4_8C_Init:
	ld a, [wSfx4Playing]
	cp $8c
	jp z, Sfx4_Refuse
	ld hl, Sfx4_8C_Data_567E
	jp Sfx4_Start

Sfx4_8C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_8C_Data_5683
	jp SetRegs_Ch4

Sfx4_8C_Data_567E:
	db $38, $51, $49, $c0, $02
Sfx4_8C_Data_5683:
	db $00, $61, $4c, $80, $02
Sfx4_8D_Init:
	ld a, [wSfx4Playing]
	cp $8d
	jp z, Sfx4_Refuse
	ld hl, Sfx4_8D_Data_56A8
	jp Sfx4_Start

Sfx4_8D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_8D_Data_56AD
	jp SetRegs_Ch4

Sfx4_8D_Data_56A8:
	db $38, $41, $49, $c0, $03
Sfx4_8D_Data_56AD:
	db $00, $51, $4c, $80, $07
Sfx1_82_Code_56B2:
	ld a, [hl+]
	and $3f
	ld b, a
	sla a
	sla a
	and $c0
	or b
	ld [wSfx1Sweep], a
	ld a, $08
	ldh [rNR10], a
	ld a, [hl+]
	ldh [rNR11], a
	ld a, [hl+]
	ld b, $00
	and a
	jr z, Sfx1_82_Code_56D1
	ld b, $80
	ldh [rNR12], a
Sfx1_82_Code_56D1:
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	and $07
	ld d, a
	or e
	jr z, Sfx1_82_Code_56E6
	ld a, e
	ld [wSfx1Pitch], a
	ldh [rNR13], a
	ld a, d
	ld [wSfx1Pitch+1], a
	jr Sfx1_82_Code_56E9

Sfx1_82_Code_56E6:
	ld a, [wSfx1Pitch+1]
Sfx1_82_Code_56E9:
	or b
	ldh [rNR14], a
	ld a, [hl+]
	ld [wSfx1Timer], a
	ret

Sfx1_81_Init:
	ld a, $81
	ld [wSfx2Request], a
	ld hl, Sfx1_81_Data_574F
	jp Sfx1_StartSweep

Sfx1_81_Play:
	call Sfx_DecTimer
	jr z, .l0
	cp $02
	ret nz
	ldh a, [rNR12]
	cp $c2
	ret nz
	ld a, $28
	ldh [rNR12], a
	ld a, [wSfx1Pitch+1]
	or $80
	ldh [rNR14], a
	ret

.l0:
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_81_Data_573F
	call GetPointer
	ld a, h
	and a
	jr z, .l1
	ld a, $c2
	ldh [rNR12], a
	ld a, l
	ld [wSfx1Pitch], a
	ldh [rNR13], a
	ld a, h
	ld [wSfx1Pitch+1], a
	or $80
	ldh [rNR14], a
.l1:
	ld a, $05
	ld [wSfx1Timer], a
	ret

Sfx1_81_Data_573F:
	db $42, $06, $21, $07, $6b, $07, $90, $07, $00, $00, $a7, $07, $00, $00, $00, $00
Sfx1_81_Data_574F:
	db $08, $00, $c2, $90, $87, $05
Sfx2_81_Init:
	ld hl, Sfx2_81_Data_57AE
	jp Sfx2_StartSweep

Sfx2_81_Play:
	call Sfx_DecTimer
	jr z, .l0
	cp $02
	ret nz
	ldh a, [rNR22]
	cp $c2
	ret nz
	ld a, $28
	ldh [rNR22], a
	ld a, [wSfx2Pitch+1]
	or $80
	ldh [rNR24], a
	ret

.l0:
	call Sfx_IncStep
	cp $09
	jp z, Sfx2_Stop
	ld hl, Sfx2_81_Data_579E
	call GetPointer
	ld a, h
	and a
	jr z, .l1
	ld a, $c2
	ldh [rNR22], a
	ld a, l
	ld [wSfx2Pitch], a
	ldh [rNR23], a
	ld a, h
	ld [wSfx2Pitch+1], a
	or $80
	ldh [rNR24], a
.l1:
	ld a, $05
	ld [wSfx2Timer], a
	ret

Sfx2_81_Data_579E:
	db $00, $00, $9e, $06, $21, $07, $4f, $07, $00, $00, $6b, $07, $00, $00, $00, $00
Sfx2_81_Data_57AE:
	db $08, $00, $c2, $4f, $87, $05
Sfx1_82_Init:
	ld a, $81
	ld [wSfx4Request], a
	ld hl, Sfx1_82_Data_57E2
	jp Sfx1_StartSweep

Sfx1_82_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $07
	jp z, Sfx1_Stop
	ld hl, Sfx1_82_Data_57D6
	call GetPointer
	jp Sfx1_82_Code_56B2

Sfx1_82_Data_57D6:
	dw Sfx1_82_Data_57E8, Sfx1_82_Data_57EE, Sfx1_82_Data_57F4, Sfx1_82_Data_57E8, Sfx1_82_Data_57EE, Sfx1_82_Data_57FA
Sfx1_82_Data_57E2:
	db $08, $00, $08, $00, $80, $14
Sfx1_82_Data_57E8:
	db $1c, $80, $5a, $ce, $07, $08
Sfx1_82_Data_57EE:
	db $13, $80, $91, $00, $00, $08
Sfx1_82_Data_57F4:
	db $08, $00, $08, $00, $80, $12
Sfx1_82_Data_57FA:
	db $08, $00, $08, $00, $80, $32
Sfx4_81_Init:
	ld hl, Sfx4_81_Data_581F
	jp Sfx4_Start

Sfx4_81_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_81_Data_581B
	call GetPointer
	jp SetRegs_Ch4

Sfx4_81_Data_581B:
	dw Sfx4_81_Data_5824, Sfx4_81_Data_5829
Sfx4_81_Data_581F:
	db $00, $0c, $25, $80, $24
Sfx4_81_Data_5824:
	db $00, $98, $25, $80, $30
Sfx4_81_Data_5829:
	db $00, $84, $26, $80, $24
Sfx1_83_Init:
	ld a, $82
	ld [wSfx4Request], a
	ld hl, Sfx1_83_Data_5853
	jp Sfx1_StartSweep

Sfx1_84_Init:
	ld a, $83
	ld [wSfx4Request], a
	ld hl, Sfx1_84_Data_5859
	jp Sfx1_StartSweep

Sfx1_85_Init:
	ld hl, Sfx1_85_Data_585F
	jp Sfx1_StartSweep

Sfx1_83_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_83_Data_5853:
	db $1b, $80, $57, $ac, $87, $03
Sfx1_84_Data_5859:
	db $1b, $80, $57, $be, $87, $03
Sfx1_85_Data_585F:
	db $1b, $40, $47, $c8, $87, $01
Sfx4_82_Init:
	ld hl, Sfx4_82_Data_5878
	jp Sfx4_Start

Sfx4_83_Init:
	ld hl, Sfx4_83_Data_587D
	jp Sfx4_Start

Sfx4_82_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Release

Sfx4_82_Data_5878:
	db $3d, $a9, $17, $c0, $05
Sfx4_83_Data_587D:
	db $3d, $a9, $16, $c0, $05
Sfx1_89_Init:
	ld a, $04
	ld de, $0010
	ld hl, wCh1LenCounter
.l0:
	inc [hl]
	add hl, de
	dec a
	jr nz, .l0
	jp Sfx1_Refuse

Sfx1_89_Play:
	ret

Sfx2_84_Init:
	ld a, [wSfx2Playing]
	cp $84
	jr nz, .l0
	ld a, [wSfx2Timer]
	cp $68
	jr nz, .l0
	jp Sfx2_Refuse

.l0:
	call Sfx2_Take
	ld a, $00
	ldh [rNR21], a
	ld a, $f7
	ldh [rNR22], a
	ld hl, $de8d
	ld a, [hl+]
	ld l, [hl]
	ld h, a
	srl h
	rr l
	ld de, $0339
	add hl, de
	ld a, l
	ld [wSfx2Pitch], a
	ldh [rNR23], a
	ld a, h
	ld [wSfx2Pitch+1], a
	or $80
	ldh [rNR24], a
	ld a, $68
	ld [wSfx2Timer], a
	ret

Sfx2_84_Play:
	call Sfx_DecTimer
	jp z, Sfx2_Release
	ld de, $0058
	and $01
	jr z, .l1
	ld de, $ffa0
.l1:
	ld hl, wSfx2Pitch
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld a, h
	cp $08
	jp nc, Sfx2_Release
	ld a, l
	ld [wSfx2Pitch], a
	ldh [rNR23], a
	ld a, h
	ld [wSfx2Pitch+1], a
	ldh [rNR24], a
	ret

Sfx3_81_Init:
	ld hl, Sfx3_81_Data_5958
	call Sfx3_LoadWave
	ld hl, Sfx3_81_Data_5934
	jp Sfx3_Start

Sfx3_81_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx3_Stop
	ld hl, Sfx3_81_Data_591C
	call GetPointer
	jp SetRegs_Ch3

Sfx3_81_Data_591C:
	dw Sfx3_81_Data_593A, Sfx3_81_Data_5940, Sfx3_81_Data_593A, Sfx3_81_Data_5952, Sfx3_81_Data_5946, Sfx3_81_Data_5940, Sfx3_81_Data_594C, Sfx3_81_Data_5946, Sfx3_81_Data_5952, Sfx3_81_Data_5952, Sfx3_81_Data_5940, Sfx3_81_Data_593A
Sfx3_81_Data_5934:
	db $80, $00, $20, $97, $87, $01
Sfx3_81_Data_593A:
	db $80, $00, $20, $8a, $07, $01
Sfx3_81_Data_5940:
	db $80, $00, $20, $97, $07, $01
Sfx3_81_Data_5946:
	db $80, $00, $20, $a7, $07, $01
Sfx3_81_Data_594C:
	db $80, $00, $20, $b6, $07, $01
Sfx3_81_Data_5952:
	db $80, $00, $00, $00, $00, $02
Sfx3_81_Data_5958:
	db $01, $23, $45, $67, $89, $ac, $ee, $ee, $fe, $dc, $ba, $98, $76, $54, $32, $10
Sfx3_82_Data_5968:
	db $0a, $0a, $1a, $1a, $1a, $2a, $2a, $2a, $30, $30, $40, $40, $40, $50, $50, $50
Sfx3_82_Init:
	call Sfx3_Take
	ld hl, Sfx3_82_Data_5968
	call Sfx3_LoadWave
	ld a, $80
	ldh [rNR30], a
	ld a, $00
	ldh [rNR31], a
	ld a, $20
	ldh [rNR32], a
	ld hl, $de8d
	ld a, [hl+]
	ld l, [hl]
	ld h, a
	srl h
	rr l
	srl h
	rr l
	srl h
	rr l
	srl h
	rr l
	srl h
	rr l
	ld a, h
	and a
	jr nz, .l0
	ld a, l
	cp $3e
	jr c, .l1
.l0:
	ld a, $3e
.l1:
	ld l, a
	ld h, $00
	add hl, hl
	ld de, SfxNoteTable_Unused+20
	add hl, de
	ld a, [hl+]
	ld [wSfx3Pitch], a
	ldh [rNR33], a
	ld a, [hl]
	ld [wSfx3Pitch+1], a
	or $80
	ldh [rNR34], a
	ld a, $0c
	ld [wSfx3Timer], a
	ret

Sfx3_82_Play:
	call Sfx_DecTimer
	jp z, Sfx3_Stop
	cp $0a
	ret nz
	ld a, $40
	ldh [rNR32], a
	ret

Sfx4_87_Shared_59DC:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	ret

Sfx4_87_Init:
	ld a, [wSfx4Playing]
	cp $87
	jr nz, .l0
	ld a, [de]
	cp $2f
	jr c, .l0
.l1:
	jp Sfx4_Refuse

.l0:
	ld hl, $de8d
	ld a, [hl+]
	ld l, [hl]
	ld h, a
	ld bc, $0060
	add hl, bc
	bit 7, h
	jr nz, .l1
	ld a, $07
.l2:
	srl h
	rr l
	dec a
	jr nz, .l2
	ld a, h
	and a
	jr nz, .l3
	ld a, l
	cp $06
	jr c, .l4
.l3:
	ld l, $06
.l4:
	ld a, l
	cp $01
	jr c, .l1
	ld a, [wSfx4Playing]
	cp $87
	jr nz, .l5
	ldh a, [rNR42]
	and $0f
	cp $08
	jr nz, .l5
	ldh a, [rNR42]
	swap a
	and $0f
	cp l
	jr z, .l6
	jr c, .l7
	dec a
	ld l, a
	jr .l5

.l7:
	inc a
	ld l, a
.l5:
	call Sfx4_87_Shared_59DC
	ld c, $20
	xor a
	ldh [c], a
	ld a, l
	swap a
	or $08
	inc c
	ldh [c], a
	ld a, $14
	inc c
	ldh [c], a
	ld a, $80
	inc c
	ldh [c], a
.l6:
	ld a, $38
	ld [de], a
	ret

Sfx4_87_Play:
	call Sfx_DecTimer
	jp z, Sfx4_Release
	cp $2a
	ret nz
	ldh a, [rNR42]
	and $f0
	or $07
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

Sfx4_8E_Init:
	ld a, [wSfx4Playing]
	cp $8e
	jr nz, .l0
	ld a, [de]
	cp $0f
	jr c, .l0
.l1:
	jp Sfx4_Refuse

.l0:
	ld hl, $de8d
	ld a, [hl+]
	ld l, [hl]
	ld h, a
	ld bc, $0020
	add hl, bc
	bit 7, h
	jr nz, .l1
	ld a, $06
.l2:
	srl h
	rr l
	dec a
	jr nz, .l2
	ld a, h
	and a
	jr nz, .l3
	ld a, l
	cp $05
	jr c, .l4
.l3:
	ld l, $05
.l4:
	ld a, l
	cp $01
	jr c, .l1
	ld a, [wSfx4Playing]
	cp $8e
	jr nz, .l5
	ldh a, [rNR42]
	and $0f
	cp $08
	jr nz, .l5
	ldh a, [rNR42]
	swap a
	and $0f
	cp l
	jr z, .l6
	jr c, .l7
	dec a
	ld l, a
	jr .l5

.l7:
	inc a
	ld l, a
.l5:
	call Sfx4_87_Shared_59DC
	ld c, $20
	xor a
	ldh [c], a
	ld a, l
	swap a
	or $08
	inc c
	ldh [c], a
	ld a, $24
	inc c
	ldh [c], a
	ld a, $80
	inc c
	ldh [c], a
.l6:
	ld a, $10
	ld [de], a
	ret

Sfx4_8E_Play:
	call Sfx_DecTimer
	jp z, Sfx4_Release
	cp $0a
	ret nz
	ldh a, [rNR42]
	and $f0
	or $02
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

