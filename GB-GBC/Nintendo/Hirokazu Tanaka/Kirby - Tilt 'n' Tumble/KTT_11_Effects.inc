; Kirby Tilt 'n' Tumble SFX: effects, bank $11 $454A-$788C

Sfx1_1C_Init:
	ld a, $06
	ld [wSfx2Request], a
	jp Sfx1_Stop

Sfx1_1C_Play:
	ret

Sfx1_5B_Init:
	ld a, $05
	ld [wSfx4Request], a
	jp Sfx1_Stop

Sfx1_5B_Play:
	ret

Sfx1_6E_Init:
	ld a, $27
	ld [wSfx4Request], a
	ld hl, Sfx1_6E_Data_4570
	jp Sfx1_StartSweep

Sfx1_6E_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_6E_Data_4570:
	db $1a, $80, $f1, $72, $86, $05
Sfx1_67_Init:
	ld hl, Sfx1_67_Data_459F
	jp Sfx1_Start

Sfx1_67_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_67_Data_4591
	call GetPointer
	jp SetRegs_Ch1

Sfx1_67_Data_4591:
	dw Sfx1_67_Data_45A5, Sfx1_67_Data_45AB, Sfx1_67_Data_45B1, Sfx1_67_Data_45B7, Sfx1_67_Data_45BD, Sfx1_67_Data_45C3, Sfx1_67_Data_45C9
Sfx1_67_Data_459F:
	db $08, $00, $f8, $d6, $86, $01
Sfx1_67_Data_45A5:
	db $08, $00, $f8, $e7, $86, $01
Sfx1_67_Data_45AB:
	db $08, $00, $f8, $c4, $86, $01
Sfx1_67_Data_45B1:
	db $08, $00, $08, $ce, $87, $01
Sfx1_67_Data_45B7:
	db $08, $00, $f8, $44, $87, $01
Sfx1_67_Data_45BD:
	db $08, $00, $f8, $59, $87, $01
Sfx1_67_Data_45C3:
	db $08, $00, $f8, $4f, $87, $01
Sfx1_67_Data_45C9:
	db $08, $00, $f8, $62, $87, $01
Sfx1_38_Init:
	jp Sfx1_Stop

Sfx1_38_Play:
	ret

Sfx1_53_Init:
	ld a, $06
	ld [wSfx2Request], a
	ld a, $03
	ld [wSfx3Request], a
	ld a, $05
	ld [wSfx4Request], a
	jp Sfx1_Stop

Sfx1_53_Play:
	ret

Sfx1_0D_Init:
	ld hl, Sfx1_0D_Data_461F
	jp Sfx1_Start

Sfx1_0D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_0D_Data_4601
	call GetPointer
	jp SetRegs_Ch1

Sfx1_0D_Data_4601:
	dw Sfx1_0D_Data_4619, Sfx1_0D_Data_4613, Sfx1_0D_Data_4619, Sfx1_0D_Data_461F, Sfx1_0D_Data_4625, Sfx1_0D_Data_462B, Sfx1_0D_Data_4631, Sfx1_0D_Data_4637, Sfx1_0D_Data_463D
Sfx1_0D_Data_4613:
	db $08, $00, $a1, $ac, $87, $02
Sfx1_0D_Data_4619:
	db $08, $00, $a1, $be, $87, $02
Sfx1_0D_Data_461F:
	db $08, $00, $a1, $c8, $87, $02
Sfx1_0D_Data_4625:
	db $08, $00, $a1, $d1, $87, $02
Sfx1_0D_Data_462B:
	db $08, $00, $a1, $d6, $87, $02
Sfx1_0D_Data_4631:
	db $08, $00, $a1, $df, $87, $02
Sfx1_0D_Data_4637:
	db $08, $00, $a1, $c8, $87, $02
Sfx1_0D_Data_463D:
	db $08, $00, $a2, $d6, $87, $0f
Sfx1_33_Init:
	ld hl, Sfx1_33_Data_4657
	jp Sfx1_Start

Sfx1_33_Play:
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_33_Data_465D
	jp SetRegs_Ch1

Sfx1_33_Data_4657:
	db $08, $80, $d8, $50, $87, $01
Sfx1_33_Data_465D:
	db $08, $80, $d8, $80, $87, $01
Sfx1_16_Init:
	ld a, [$ded3]
	inc a
	and $07
	ld [$ded3], a
	inc a
	ld hl, Sfx1_16_Data_4676
	call GetPointer
	jp Sfx1_Start

Sfx1_16_Data_4676:
	dw Sfx1_16_Data_46A4, Sfx1_16_Data_46AA, Sfx1_16_Data_46A4, Sfx1_16_Data_469E, Sfx1_16_Data_46A4, Sfx1_16_Data_46AA, Sfx1_16_Data_46A4, Sfx1_16_Data_469E
Sfx1_16_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Release
	ld hl, Sfx1_16_Data_4698
	jp SetRegs_Ch1

Sfx1_16_Data_4698:
	db $08, $00, $08, $ac, $87, $04
Sfx1_16_Data_469E:
	db $08, $00, $c1, $83, $87, $03
Sfx1_16_Data_46A4:
	db $08, $00, $c1, $9d, $87, $03
Sfx1_16_Data_46AA:
	db $08, $00, $c1, $ac, $87, $03
Sfx1_6C_Init:
	ld hl, Sfx1_6C_Data_46DB
	jp Sfx1_Start

Sfx1_6C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_6C_Data_46CB
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6C_Data_46CB:
	dw Sfx1_6C_Data_46E1, Sfx1_6C_Data_46E7, Sfx1_6C_Data_46ED, Sfx1_6C_Data_46F3, Sfx1_6C_Data_46F9, Sfx1_6C_Data_46FF, Sfx1_6C_Data_4705, Sfx1_6C_Data_470B
Sfx1_6C_Data_46DB:
	db $08, $80, $98, $d6, $87, $03
Sfx1_6C_Data_46E1:
	db $08, $40, $88, $83, $87, $03
Sfx1_6C_Data_46E7:
	db $08, $40, $78, $d6, $87, $03
Sfx1_6C_Data_46ED:
	db $08, $40, $68, $83, $87, $03
Sfx1_6C_Data_46F3:
	db $08, $40, $58, $d6, $87, $03
Sfx1_6C_Data_46F9:
	db $08, $40, $48, $83, $87, $03
Sfx1_6C_Data_46FF:
	db $08, $40, $38, $d6, $87, $03
Sfx1_6C_Data_4705:
	db $08, $40, $28, $83, $87, $03
Sfx1_6C_Data_470B:
	db $08, $40, $18, $d6, $87, $03
Sfx1_02_Init:
	ld hl, Sfx1_02_Data_4736
	jp Sfx1_Start

Sfx1_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_02_Data_472C
	call GetPointer
	jp SetRegs_Ch1

Sfx1_02_Data_472C:
	dw Sfx1_02_Data_473C, Sfx1_02_Data_4742, Sfx1_02_Data_4748, Sfx1_02_Data_474E, Sfx1_02_Data_4754
Sfx1_02_Data_4736:
	db $08, $40, $b8, $c1, $87, $01
Sfx1_02_Data_473C:
	db $08, $00, $b8, $a7, $87, $02
Sfx1_02_Data_4742:
	db $08, $80, $b8, $9d, $87, $02
Sfx1_02_Data_4748:
	db $08, $00, $b8, $90, $87, $02
Sfx1_02_Data_474E:
	db $08, $40, $b8, $8a, $87, $02
Sfx1_02_Data_4754:
	db $08, $80, $b8, $6b, $87, $02
Sfx1_5E_Init:
	ld a, [wSfx1Playing]
	cp $5e
	jp z, Sfx1_Refuse
	ld hl, Sfx1_5E_Data_4791
	jp Sfx1_Start

Sfx1_5E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx1_Stop
	ld hl, Sfx1_5E_Data_477D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5E_Data_477D:
	dw Sfx1_5E_Data_4797, Sfx1_5E_Data_479D, Sfx1_5E_Data_47A3, Sfx1_5E_Data_47A9, Sfx1_5E_Data_47AF, Sfx1_5E_Data_47B5, Sfx1_5E_Data_47BB, Sfx1_5E_Data_47C1, Sfx1_5E_Data_47C7, Sfx1_5E_Data_47CD
Sfx1_5E_Data_4791:
	db $08, $80, $58, $77, $82, $07
Sfx1_5E_Data_4797:
	db $08, $80, $68, $4b, $82, $07
Sfx1_5E_Data_479D:
	db $08, $80, $78, $2a, $82, $07
Sfx1_5E_Data_47A3:
	db $08, $80, $88, $fe, $81, $07
Sfx1_5E_Data_47A9:
	db $08, $80, $98, $dd, $81, $07
Sfx1_5E_Data_47AF:
	db $08, $80, $08, $dd, $81, $0b
Sfx1_5E_Data_47B5:
	db $08, $80, $38, $ad, $87, $07
Sfx1_5E_Data_47BB:
	db $08, $80, $48, $ae, $87, $07
Sfx1_5E_Data_47C1:
	db $08, $80, $58, $af, $87, $07
Sfx1_5E_Data_47C7:
	db $08, $80, $68, $b0, $87, $07
Sfx1_5E_Data_47CD:
	db $08, $80, $78, $b1, $87, $07
Sfx1_60_Init:
	ld hl, Sfx1_60_Data_4802
	jp Sfx1_Start

Sfx1_60_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx1_Stop
	ld hl, Sfx1_60_Data_47EE
	call GetPointer
	jp SetRegs_Ch1

Sfx1_60_Data_47EE:
	dw Sfx1_60_Data_4808, Sfx1_60_Data_480E, Sfx1_60_Data_4814, Sfx1_60_Data_481A, Sfx1_60_Data_4820, Sfx1_60_Data_4826, Sfx1_60_Data_482C, Sfx1_60_Data_4832, Sfx1_60_Data_4838, Sfx1_60_Data_483E
Sfx1_60_Data_4802:
	db $08, $80, $78, $77, $82, $01
Sfx1_60_Data_4808:
	db $08, $80, $a8, $4b, $82, $01
Sfx1_60_Data_480E:
	db $08, $80, $b8, $2a, $82, $01
Sfx1_60_Data_4814:
	db $08, $80, $c8, $fe, $81, $01
Sfx1_60_Data_481A:
	db $08, $80, $d8, $dd, $81, $01
Sfx1_60_Data_4820:
	db $08, $80, $08, $dd, $81, $03
Sfx1_60_Data_4826:
	db $08, $80, $38, $ad, $87, $01
Sfx1_60_Data_482C:
	db $08, $80, $48, $ae, $87, $01
Sfx1_60_Data_4832:
	db $08, $80, $58, $af, $87, $01
Sfx1_60_Data_4838:
	db $08, $80, $68, $b0, $87, $01
Sfx1_60_Data_483E:
	db $08, $80, $78, $b1, $87, $01
Sfx1_5F_Init:
	ld a, $15
	ld [wSfx4Request], a
	ld hl, Sfx1_5F_Data_487A
	jp Sfx1_Start

Sfx1_5F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx1_Stop
	ld hl, Sfx1_5F_Data_4864
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5F_Data_4864:
	dw Sfx1_5F_Data_4880, Sfx1_5F_Data_4886, Sfx1_5F_Data_488C, Sfx1_5F_Data_4892, Sfx1_5F_Data_4898, Sfx1_5F_Data_489E, Sfx1_5F_Data_48A4, Sfx1_5F_Data_48AA, Sfx1_5F_Data_48B0, Sfx1_5F_Data_48B6, Sfx1_5F_Data_48BC
Sfx1_5F_Data_487A:
	db $08, $00, $88, $89, $86, $02
Sfx1_5F_Data_4880:
	db $08, $40, $88, $6b, $87, $01
Sfx1_5F_Data_4886:
	db $08, $80, $88, $06, $87, $02
Sfx1_5F_Data_488C:
	db $08, $00, $78, $b2, $86, $02
Sfx1_5F_Data_4892:
	db $08, $40, $78, $7b, $87, $01
Sfx1_5F_Data_4898:
	db $08, $80, $78, $21, $87, $02
Sfx1_5F_Data_489E:
	db $08, $00, $68, $d6, $86, $01
Sfx1_5F_Data_48A4:
	db $08, $40, $68, $8a, $87, $02
Sfx1_5F_Data_48AA:
	db $08, $80, $68, $39, $87, $01
Sfx1_5F_Data_48B0:
	db $08, $40, $48, $f7, $86, $02
Sfx1_5F_Data_48B6:
	db $08, $40, $48, $97, $87, $01
Sfx1_5F_Data_48BC:
	db $08, $40, $48, $4f, $87, $02
Sfx1_4A_Init:
	ld a, [wSfx1Playing]
	cp $4a
	jp z, Sfx1_Refuse
	ld hl, Sfx1_4A_Data_48F5
	jp Sfx1_Start

Sfx1_4A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_4A_Data_48E5
	call GetPointer
	jp SetRegs_Ch1

Sfx1_4A_Data_48E5:
	dw Sfx1_4A_Data_48FB, Sfx1_4A_Data_4901, Sfx1_4A_Data_4907, Sfx1_4A_Data_490D, Sfx1_4A_Data_4913, Sfx1_4A_Data_4919, Sfx1_4A_Data_491F, Sfx1_4A_Data_4925
Sfx1_4A_Data_48F5:
	db $08, $c0, $88, $b4, $87, $01
Sfx1_4A_Data_48FB:
	db $08, $c0, $68, $97, $87, $01
Sfx1_4A_Data_4901:
	db $08, $c0, $48, $7a, $87, $01
Sfx1_4A_Data_4907:
	db $08, $c0, $28, $5d, $87, $01
Sfx1_4A_Data_490D:
	db $08, $c0, $88, $c4, $87, $01
Sfx1_4A_Data_4913:
	db $08, $c0, $68, $a9, $87, $01
Sfx1_4A_Data_4919:
	db $08, $c0, $48, $8e, $87, $01
Sfx1_4A_Data_491F:
	db $08, $c0, $28, $73, $87, $01
Sfx1_4A_Data_4925:
	db $08, $c0, $18, $58, $87, $01
Sfx1_49_Init:
	ld hl, Sfx1_49_Data_494E
	jp Sfx1_Start

Sfx1_49_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_49_Data_4946
	call GetPointer
	jp SetRegs_Ch1

Sfx1_49_Data_4946:
	dw Sfx1_49_Data_4954, Sfx1_49_Data_495A, Sfx1_49_Data_4960, Sfx1_49_Data_4966
Sfx1_49_Data_494E:
	db $08, $80, $68, $8b, $87, $01
Sfx1_49_Data_4954:
	db $08, $80, $98, $93, $87, $01
Sfx1_49_Data_495A:
	db $08, $80, $c8, $9b, $87, $01
Sfx1_49_Data_4960:
	db $08, $80, $98, $a4, $87, $01
Sfx1_49_Data_4966:
	db $08, $80, $48, $ad, $87, $01
Sfx1_39_Init:
	ld a, [wSfx1Playing]
	cp $39
	jr nz, .l0
	ld a, [wSfx2Playing]
	cp $05
	jr nz, .l0
	jp Sfx1_Refuse

.l0:
	ld a, $05
	ld [wSfx2Request], a
	ld hl, Sfx1_39_Data_49EA
	jp Sfx1_Start

Sfx1_39_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $25
	jp c, .l1
	ld a, $01
	ld [bc], a
.l1:
	ld hl, Sfx1_39_Data_49A2
	call GetPointer
	jp SetRegs_Ch1

Sfx2_05_Data_49A0:
	dw Sfx1_39_Data_49EA
Sfx1_39_Data_49A2:
	dw Sfx1_39_Data_49F0, Sfx1_39_Data_49F6, Sfx1_39_Data_49FC, Sfx1_39_Data_4A02, Sfx1_39_Data_4A08, Sfx1_39_Data_4A0E, Sfx1_39_Data_4A14, Sfx1_39_Data_4A1A, Sfx1_39_Data_4A20, Sfx1_39_Data_4A26, Sfx1_39_Data_4A2C, Sfx1_39_Data_4A32, Sfx1_39_Data_4A38, Sfx1_39_Data_4A3E, Sfx1_39_Data_4A44, Sfx1_39_Data_4A4A, Sfx1_39_Data_4A50, Sfx1_39_Data_4A56, Sfx1_39_Data_4A5C, Sfx1_39_Data_4A62, Sfx1_39_Data_4A68, Sfx1_39_Data_4A6E, Sfx1_39_Data_4A74, Sfx1_39_Data_4A7A, Sfx1_39_Data_4A80, Sfx1_39_Data_4A86, Sfx1_39_Data_4A8C, Sfx1_39_Data_4A92, Sfx1_39_Data_4A98, Sfx1_39_Data_4A9E, Sfx1_39_Data_4AA4, Sfx1_39_Data_4AAA, Sfx1_39_Data_4AB0, Sfx1_39_Data_4AB6, Sfx1_39_Data_4ABC, Sfx1_39_Data_49EA
Sfx1_39_Data_49EA:
	db $08, $40, $48, $ac, $87, $01
Sfx1_39_Data_49F0:
	db $08, $40, $88, $ac, $87, $01
Sfx1_39_Data_49F6:
	db $08, $40, $a8, $ac, $87, $01
Sfx1_39_Data_49FC:
	db $08, $40, $88, $ac, $87, $01
Sfx1_39_Data_4A02:
	db $08, $40, $48, $ac, $87, $06
Sfx1_39_Data_4A08:
	db $08, $40, $58, $ac, $87, $02
Sfx1_39_Data_4A0E:
	db $08, $40, $48, $c1, $87, $01
Sfx1_39_Data_4A14:
	db $08, $40, $88, $c1, $87, $01
Sfx1_39_Data_4A1A:
	db $08, $40, $a8, $c1, $87, $01
Sfx1_39_Data_4A20:
	db $08, $40, $88, $c1, $87, $01
Sfx1_39_Data_4A26:
	db $08, $40, $48, $c1, $87, $06
Sfx1_39_Data_4A2C:
	db $08, $40, $58, $c1, $87, $02
Sfx1_39_Data_4A32:
	db $08, $40, $48, $ce, $87, $01
Sfx1_39_Data_4A38:
	db $08, $40, $88, $ce, $87, $01
Sfx1_39_Data_4A3E:
	db $08, $40, $a8, $ce, $87, $01
Sfx1_39_Data_4A44:
	db $08, $40, $88, $ce, $87, $01
Sfx1_39_Data_4A4A:
	db $08, $40, $48, $ce, $87, $06
Sfx1_39_Data_4A50:
	db $08, $40, $58, $ce, $87, $02
Sfx1_39_Data_4A56:
	db $08, $40, $48, $c8, $87, $01
Sfx1_39_Data_4A5C:
	db $08, $40, $88, $c8, $87, $01
Sfx1_39_Data_4A62:
	db $08, $40, $a8, $c8, $87, $01
Sfx1_39_Data_4A68:
	db $08, $40, $88, $c8, $87, $01
Sfx1_39_Data_4A6E:
	db $08, $40, $48, $c8, $87, $06
Sfx1_39_Data_4A74:
	db $08, $40, $58, $c8, $87, $02
Sfx1_39_Data_4A7A:
	db $08, $40, $48, $c1, $87, $01
Sfx1_39_Data_4A80:
	db $08, $40, $88, $c1, $87, $01
Sfx1_39_Data_4A86:
	db $08, $40, $a8, $c1, $87, $01
Sfx1_39_Data_4A8C:
	db $08, $40, $88, $c1, $87, $01
Sfx1_39_Data_4A92:
	db $08, $40, $48, $c1, $87, $06
Sfx1_39_Data_4A98:
	db $08, $40, $58, $c1, $87, $02
Sfx1_39_Data_4A9E:
	db $08, $40, $48, $b6, $87, $01
Sfx1_39_Data_4AA4:
	db $08, $40, $88, $b6, $87, $01
Sfx1_39_Data_4AAA:
	db $08, $40, $a8, $b6, $87, $01
Sfx1_39_Data_4AB0:
	db $08, $40, $88, $b6, $87, $01
Sfx1_39_Data_4AB6:
	db $08, $40, $48, $b6, $87, $06
Sfx1_39_Data_4ABC:
	db $08, $40, $58, $b6, $87, $02
Sfx2_05_Init:
	ld hl, Sfx2_05_Data_4AE1
	jp Sfx2_Start

Sfx2_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $25
	jp c, .l0
	ld a, $01
	ld [bc], a
.l0:
	ld hl, Sfx2_05_Data_49A0
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx2_05_Data_4AE1:
	db $80, $08, $b6, $87, $12
Sfx1_61_Init:
	ld a, [wSfx1Playing]
	cp $61
	jp nz, .l0
	jp Sfx1_Continue

.l0:
	ld hl, Sfx1_61_Data_4B20
	jp Sfx1_Start

Sfx1_61_Play:
	ld a, [wSfx1Request]
	cp $61
	jp nz, Sfx1_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp nz, .l1
	xor a
	ld [bc], a
	ld hl, Sfx1_61_Data_4B20
	jp SetRegs_Ch1

.l1:
	ld hl, Sfx1_61_Data_4B1C
	call GetPointer
	jp SetRegs_Ch1

Sfx1_61_Data_4B1C:
	dw Sfx1_61_Data_4B26, Sfx1_61_Data_4B2C
Sfx1_61_Data_4B20:
	db $08, $40, $b8, $d6, $87, $02
Sfx1_61_Data_4B26:
	db $08, $40, $48, $ac, $87, $02
Sfx1_61_Data_4B2C:
	db $08, $40, $b8, $c8, $87, $02
Sfx1_4B_Init:
	ld hl, Sfx1_4B_Data_4B63
	jp Sfx1_Start

Sfx1_4B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx1_Stop
	ld hl, Sfx1_4B_Data_4B4D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_4B_Data_4B4D:
	dw Sfx1_4B_Data_4B69, Sfx1_4B_Data_4B6F, Sfx1_4B_Data_4B75, Sfx1_4B_Data_4B7B, Sfx1_4B_Data_4B81, Sfx1_4B_Data_4B87, Sfx1_4B_Data_4B8D, Sfx1_4B_Data_4B93, Sfx1_4B_Data_4B99, Sfx1_4B_Data_4B9F, Sfx1_4B_Data_4BA5
Sfx1_4B_Data_4B63:
	db $08, $80, $48, $6b, $87, $01
Sfx1_4B_Data_4B69:
	db $08, $80, $08, $6b, $87, $01
Sfx1_4B_Data_4B6F:
	db $08, $80, $68, $7d, $87, $01
Sfx1_4B_Data_4B75:
	db $08, $80, $28, $7d, $87, $01
Sfx1_4B_Data_4B7B:
	db $08, $80, $88, $8f, $87, $01
Sfx1_4B_Data_4B81:
	db $08, $80, $48, $8f, $87, $01
Sfx1_4B_Data_4B87:
	db $08, $80, $a8, $a1, $87, $01
Sfx1_4B_Data_4B8D:
	db $08, $80, $68, $a1, $87, $01
Sfx1_4B_Data_4B93:
	db $08, $80, $c8, $b3, $87, $01
Sfx1_4B_Data_4B99:
	db $08, $80, $88, $b3, $87, $01
Sfx1_4B_Data_4B9F:
	db $08, $80, $e8, $c5, $87, $01
Sfx1_4B_Data_4BA5:
	db $08, $80, $a8, $c5, $87, $01
Sfx1_0A_Init:
	xor a
	ld [$ded3], a
	ld [wHurryJingle], a
	ld a, [wSongPlaying]
	ld [wSongRequest], a
	ld hl, Sfx1_0A_Data_4BE9
	jp Sfx1_Start

Sfx1_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx1_Stop
	ld hl, Sfx1_0A_Data_4BD3
	call GetPointer
	jp SetRegs_Ch1

Sfx1_0A_Data_4BD3:
	dw Sfx1_0A_Data_4BEF, Sfx1_0A_Data_4BF5, Sfx1_0A_Data_4BFB, Sfx1_0A_Data_4C01, Sfx1_0A_Data_4C07, Sfx1_0A_Data_4C0D, Sfx1_0A_Data_4C13, Sfx1_0A_Data_4C19, Sfx1_0A_Data_4C1F, Sfx1_0A_Data_4C25, Sfx1_0A_Data_4C2B
Sfx1_0A_Data_4BE9:
	db $08, $40, $e8, $44, $87, $03
Sfx1_0A_Data_4BEF:
	db $08, $40, $e8, $06, $87, $03
Sfx1_0A_Data_4BF5:
	db $08, $40, $e8, $b2, $86, $03
Sfx1_0A_Data_4BFB:
	db $08, $40, $e8, $06, $87, $03
Sfx1_0A_Data_4C01:
	db $08, $40, $d8, $44, $87, $03
Sfx1_0A_Data_4C07:
	db $08, $40, $d8, $59, $87, $03
Sfx1_0A_Data_4C0D:
	db $08, $40, $d8, $6b, $87, $03
Sfx1_0A_Data_4C13:
	db $08, $40, $a8, $83, $87, $02
Sfx1_0A_Data_4C19:
	db $08, $40, $98, $6b, $87, $02
Sfx1_0A_Data_4C1F:
	db $08, $40, $88, $83, $87, $02
Sfx1_0A_Data_4C25:
	db $08, $40, $78, $6b, $87, $02
Sfx1_0A_Data_4C2B:
	db $08, $40, $58, $83, $87, $02
Sfx1_2A_Init:
	ld hl, Sfx1_2A_Data_4C3E
	jp Sfx1_Start

Sfx1_2A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_2A_Data_4C3E:
	db $08, $80, $f8, $c8, $87, $02
Sfx1_26_Init:
	ld a, $06
	ld [wSfx2Request], a
	ld a, $03
	ld [wSfx3Request], a
	ld a, $05
	ld [wSfx4Request], a
	ld a, $ff
	ld [wSongRequest], a
	xor a
	ld [wSfx1Priority], a
	ld hl, Sfx1_26_Data_4C69
	jp Sfx1_Start

Sfx1_26_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_26_Data_4C69:
	db $08, $80, $f8, $c8, $87, $02
Sfx1_2C_Init:
	ld hl, Sfx1_2C_Data_4C90
	jp Sfx1_Start

Sfx1_2C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx1_2C_Data_4C8A
	call GetPointer
	jp SetRegs_Ch1

Sfx1_2C_Data_4C8A:
	dw Sfx1_2C_Data_4C96, Sfx1_2C_Data_4C9C, Sfx1_2C_Data_4CA2
Sfx1_2C_Data_4C90:
	db $08, $80, $f8, $ac, $87, $02
Sfx1_2C_Data_4C96:
	db $08, $80, $f8, $c1, $87, $02
Sfx1_2C_Data_4C9C:
	db $08, $80, $f8, $ce, $87, $02
Sfx1_2C_Data_4CA2:
	db $08, $80, $f8, $d6, $87, $02
Sfx1_63_Init:
	ld a, [wSfx1Playing]
	cp $63
	jp z, Sfx1_Refuse
	ld hl, Sfx1_63_Data_4CD1
	jp Sfx1_Start

Sfx1_63_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx1_63_Data_4CCB
	call GetPointer
	jp SetRegs_Ch1

Sfx1_63_Data_4CCB:
	dw Sfx1_63_Data_4CD7, Sfx1_63_Data_4CDD, Sfx1_63_Data_4CE3
Sfx1_63_Data_4CD1:
	db $08, $40, $75, $ac, $87, $02
Sfx1_63_Data_4CD7:
	db $08, $00, $45, $c8, $87, $03
Sfx1_63_Data_4CDD:
	db $08, $40, $75, $d6, $87, $02
Sfx1_63_Data_4CE3:
	db $08, $00, $45, $df, $87, $03
Sfx1_55_Init:
	ld hl, Sfx1_4C_Data_4E3F
	jp Sfx1_Start

Sfx1_55_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1a
	jp z, Sfx1_Stop
	ld hl, Sfx1_4C_Data_4D4D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6B_Init:
	ld hl, Sfx1_4C_Data_4E3F
	jp Sfx1_Start

Sfx1_6B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $79
	jp z, Sfx1_Stop
	ld hl, Sfx1_4C_Data_4D4D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_4C_Init:
	ld a, $03
	ld [wSfx2Request], a
	xor a
	ld [wHurryJingle], a
	ld hl, Sfx1_4C_Data_4E3F
	jp Sfx1_Start

Sfx1_4C_Play:
	call Sfx_DecTimer
	ret nz
	ld a, [bc]
	cp $7a
	ret z
	inc a
	ld [bc], a
	cp $7a
	jr nz, .l0
	ld a, $10
	ld [wSfx1Priority], a
	ret

.l0:
	ld hl, Sfx1_4C_Data_4D4D
	call GetPointer
	jp SetRegs_Ch1

Sfx2_03_Data_4D4B:
	dw Sfx1_4C_Data_4E3F
Sfx1_4C_Data_4D4D:
	dw Sfx1_4C_Data_4E45, Sfx1_4C_Data_4E4B, Sfx1_4C_Data_4E51, Sfx1_4C_Data_4E57
Sfx2_08_Data_4D55:
	dw Sfx2_08_Data_4E5D, Sfx2_08_Data_4E63, Sfx2_08_Data_4E69, Sfx2_08_Data_4E6F, Sfx2_08_Data_4E75, Sfx2_08_Data_4E7B, Sfx2_08_Data_4E81, Sfx2_08_Data_4E87, Sfx2_08_Data_4E8D, Sfx2_08_Data_4E93, Sfx2_08_Data_4E99, Sfx2_08_Data_4E9F, Sfx2_08_Data_4EA5, Sfx2_08_Data_4EAB, Sfx2_08_Data_4EB1, Sfx2_08_Data_4EB7, Sfx2_08_Data_4EBD, Sfx2_08_Data_4EC3, Sfx2_08_Data_4EC9, Sfx2_08_Data_4ECF, Sfx2_08_Data_4ED5, Sfx2_08_Data_4EDB, Sfx2_08_Data_4EE1, Sfx2_08_Data_4EE7, Sfx2_08_Data_4EED, Sfx2_08_Data_4EF3, Sfx2_08_Data_4EF9, Sfx2_08_Data_4EFF, Sfx2_08_Data_4F05, Sfx2_08_Data_4F0B, Sfx2_08_Data_4F11, Sfx2_08_Data_4F17, Sfx2_08_Data_4F1D, Sfx2_08_Data_4F23, Sfx2_08_Data_4F29, Sfx2_08_Data_4F2F, Sfx2_08_Data_4F35, Sfx2_08_Data_4F3B, Sfx2_08_Data_4F41, Sfx2_08_Data_4F47, Sfx2_08_Data_4F4D, Sfx2_08_Data_4F4D+6, Sfx2_08_Data_4F4D+12, Sfx2_08_Data_4F4D+18, Sfx2_08_Data_4F4D+24, Sfx2_08_Data_4F4D+30, Sfx2_08_Data_4F4D+36, Sfx2_08_Data_4F4D+42, Sfx2_08_Data_4F4D+48, Sfx2_08_Data_4F4D+54, Sfx2_08_Data_4F4D+60, Sfx2_08_Data_4F4D+66, Sfx2_08_Data_4F4D+72, Sfx2_08_Data_4F4D+78, Sfx2_08_Data_4F4D+84, Sfx2_08_Data_4F4D+90, Sfx2_08_Data_4F4D+96, Sfx2_08_Data_4F4D+102, Sfx2_08_Data_4F4D+108, Sfx2_08_Data_4F4D+114, Sfx2_08_Data_4F4D+120, Sfx2_08_Data_4F4D+126, Sfx2_08_Data_4F4D+132, Sfx2_08_Data_4F4D+138, Sfx2_08_Data_4F4D+144, Sfx2_08_Data_4F4D+150, Sfx2_08_Data_4F4D+156, Sfx2_08_Data_4F4D+162, Sfx2_08_Data_4F4D+168, Sfx2_08_Data_4F4D+174, Sfx2_08_Data_4F4D+180, Sfx2_08_Data_4F4D+186, Sfx2_08_Data_4F4D+192, Sfx2_08_Data_4F4D+198, Sfx2_08_Data_4F4D+204, Sfx2_08_Data_4F4D+210, Sfx2_08_Data_4F4D+216, Sfx2_08_Data_4F4D+222, Sfx2_08_Data_4F4D+228, Sfx2_08_Data_4F4D+234, Sfx2_08_Data_4F4D+240, Sfx2_08_Data_4F4D+246, Sfx2_08_Data_4F4D+252, Sfx2_08_Data_4F4D+258, Sfx2_08_Data_4F4D+264, Sfx2_08_Data_4F4D+270, Sfx2_08_Data_4F4D+276, Sfx2_08_Data_4F4D+282, Sfx2_08_Data_4F4D+288, Sfx2_08_Data_4F4D+294, Sfx2_08_Data_4F4D+300, Sfx2_08_Data_4F4D+306, Sfx2_08_Data_4F4D+312, Sfx2_08_Data_4F4D+318, Sfx2_08_Data_4F4D+324, Sfx2_08_Data_4F4D+330, Sfx2_08_Data_4F4D+336, Sfx2_08_Data_4F4D+342, Sfx2_08_Data_4F4D+348, Sfx2_08_Data_4F4D+354, Sfx2_08_Data_4F4D+360, Sfx2_08_Data_4F4D+366, Sfx2_08_Data_4F4D+372, Sfx2_08_Data_4F4D+378, Sfx2_08_Data_4F4D+384, Sfx2_08_Data_4F4D+390, Sfx2_08_Data_4F4D+396, Sfx2_08_Data_4F4D+402, Sfx2_08_Data_4F4D+408, Sfx2_08_Data_4F4D+414, Sfx2_08_Data_4F4D+420, Sfx2_08_Data_4F4D+426, Sfx2_08_Data_4F4D+432, Sfx2_08_Data_4F4D+438, Sfx2_08_Data_4F4D+444, Sfx2_08_Data_4F4D+450, Sfx2_08_Data_4F4D+456
Sfx1_4C_Data_4E3F:
	db $08
Sfx2_07_Data_4E40:
	db $80, $f8, $a2
Sfx2_10_Data_4E43:
	db $87, $02
Sfx1_4C_Data_4E45:
	db $08, $80, $f8, $b6, $87, $02
Sfx1_4C_Data_4E4B:
	db $08, $80, $f8, $c1, $87, $02
Sfx1_4C_Data_4E51:
	db $08, $80, $f8, $d1, $87, $02
Sfx1_4C_Data_4E57:
	db $08, $80, $08, $83, $87, $01
Sfx2_08_Data_4E5D:
	db $08, $80, $98, $a2, $87, $02
Sfx2_08_Data_4E63:
	db $08, $80, $98, $b6, $87, $02
Sfx2_08_Data_4E69:
	db $08, $80, $98, $c8, $87, $02
Sfx2_08_Data_4E6F:
	db $08, $80, $98, $d1, $87, $02
Sfx2_08_Data_4E75:
	db $08, $80, $78, $a2, $87, $02
Sfx2_08_Data_4E7B:
	db $08, $80, $78, $b6, $87, $02
Sfx2_08_Data_4E81:
	db $08, $80, $78, $c8, $87, $02
Sfx2_08_Data_4E87:
	db $08, $80, $78, $d1, $87, $02
Sfx2_08_Data_4E8D:
	db $08, $80, $58, $a2, $87, $02
Sfx2_08_Data_4E93:
	db $08, $80, $58, $b6, $87, $02
Sfx2_08_Data_4E99:
	db $08, $80, $58, $c8, $87, $02
Sfx2_08_Data_4E9F:
	db $08, $80, $58, $d1, $87, $02
Sfx2_08_Data_4EA5:
	db $08, $80, $38, $a2, $87, $02
Sfx2_08_Data_4EAB:
	db $08, $80, $38, $b6, $87, $02
Sfx2_08_Data_4EB1:
	db $08, $80, $38, $c8, $87, $02
Sfx2_08_Data_4EB7:
	db $08, $80, $38, $d1, $87, $02
Sfx2_08_Data_4EBD:
	db $08, $80, $18, $a7, $87, $02
Sfx2_08_Data_4EC3:
	db $08, $80, $18, $ba, $87, $02
Sfx2_08_Data_4EC9:
	db $08, $80, $18, $c5, $87, $02
Sfx2_08_Data_4ECF:
	db $08, $80, $18, $cb, $87, $02
Sfx2_08_Data_4ED5:
	db $08, $80, $18, $d4, $87, $02
Sfx2_08_Data_4EDB:
	db $08, $80, $18, $ac, $87, $02
Sfx2_08_Data_4EE1:
	db $08, $80, $18, $be, $87, $02
Sfx2_08_Data_4EE7:
	db $08, $80, $18, $c8, $87, $02
Sfx2_08_Data_4EED:
	db $08, $80, $18, $ce, $87, $02
Sfx2_08_Data_4EF3:
	db $08, $80, $18, $d6, $87, $02
Sfx2_08_Data_4EF9:
	db $08, $80, $18, $b1, $87, $02
Sfx2_08_Data_4EFF:
	db $08, $80, $18, $c1, $87, $02
Sfx2_08_Data_4F05:
	db $08, $80, $18, $cb, $87, $02
Sfx2_08_Data_4F0B:
	db $08, $80, $18, $d1, $87, $02
Sfx2_08_Data_4F11:
	db $08, $80, $18, $d9, $87, $02
Sfx2_08_Data_4F17:
	db $08, $80, $18, $b1, $87, $02
Sfx2_08_Data_4F1D:
	db $08, $80, $18, $c1, $87, $02
Sfx2_08_Data_4F23:
	db $08, $80, $18, $cb, $87, $02
Sfx2_08_Data_4F29:
	db $08, $80, $18, $d1, $87, $02
Sfx2_08_Data_4F2F:
	db $08, $80, $18, $d9, $87, $02
Sfx2_08_Data_4F35:
	db $08, $80, $28, $b1, $87, $02
Sfx2_08_Data_4F3B:
	db $08, $80, $28, $c1, $87, $02
Sfx2_08_Data_4F41:
	db $08, $80, $28, $cb, $87, $02
Sfx2_08_Data_4F47:
	db $08, $80, $28, $d1, $87, $02
Sfx2_08_Data_4F4D:
	db $08, $80, $28, $d9, $87, $02, $08, $80, $28, $b1, $87, $02, $08, $80, $28, $c1
	db $87, $02, $08, $80, $28, $cb, $87, $02, $08, $80, $28, $d1, $87, $02, $08, $80
	db $28, $d9, $87, $02, $08, $80, $38, $b1, $87, $02, $08, $80, $38, $c1, $87, $02
	db $08, $80, $38, $cb, $87, $02, $08, $80, $38, $d1, $87, $02, $08, $80, $38, $d9
	db $87, $02, $08, $80, $38, $b1, $87, $02, $08, $80, $38, $c1, $87, $02, $08, $80
	db $38, $cb, $87, $02, $08, $80, $38, $d1, $87, $02, $08, $80, $38, $d9, $87, $02
	db $08, $80, $48, $b1, $87, $02, $08, $80, $48, $c1, $87, $02, $08, $80, $48, $cb
	db $87, $02, $08, $80, $48, $d1, $87, $02, $08, $80, $48, $d9, $87, $02, $08, $80
	db $48, $b1, $87, $02, $08, $80, $48, $c1, $87, $02, $08, $80, $48, $cb, $87, $02
	db $08, $80, $48, $d1, $87, $02, $08, $80, $48, $d9, $87, $02, $08, $80, $58, $b3
	db $87, $02, $08, $80, $58, $c3, $87, $02, $08, $80, $58, $cd, $87, $02, $08, $80
	db $58, $d3, $87, $02, $08, $80, $58, $db, $87, $02, $08, $80, $58, $b3, $87, $02
	db $08, $80, $58, $c3, $87, $02, $08, $80, $58, $cd, $87, $02, $08, $80, $58, $d3
	db $87, $02, $08, $80, $58, $db, $87, $02, $08, $80, $48, $b3, $87, $02, $08, $80
	db $48, $c3, $87, $02, $08, $80, $48, $cd, $87, $02, $08, $80, $48, $d3, $87, $02
	db $08, $80, $48, $db, $87, $02, $08, $80, $48, $b3, $87, $02, $08, $80, $48, $c3
	db $87, $02, $08, $80, $48, $cd, $87, $02, $08, $80, $48, $d3, $87, $02, $08, $80
	db $48, $db, $87, $02, $08, $80, $38, $b3, $87, $02, $08, $80, $38, $c3, $87, $02
	db $08, $80, $38, $cd, $87, $02, $08, $80, $38, $d3, $87, $02, $08, $80, $38, $db
	db $87, $02, $08, $80, $38, $b3, $87, $02, $08, $80, $38, $c3, $87, $02, $08, $80
	db $38, $cd, $87, $02, $08, $80, $38, $d3, $87, $02, $08, $80, $38, $db, $87, $02
	db $08, $80, $28, $b3, $87, $02, $08, $80, $28, $c3, $87, $02, $08, $80, $28, $cd
	db $87, $02, $08, $80, $28, $d3, $87, $02, $08, $80, $28, $db, $87, $02, $08, $80
	db $28, $b3, $87, $02, $08, $80, $28, $c3, $87, $02, $08, $80, $28, $cd, $87, $02
	db $08, $80, $28, $d3, $87, $02, $08, $80, $28, $db, $87, $02, $08, $80, $18, $b3
	db $87, $02, $08, $80, $18, $c3, $87, $02, $08, $80, $18, $cd, $87, $02, $08, $80
	db $18, $d3, $87, $02, $08, $80, $18, $db, $87, $02, $08, $80, $18, $b3, $87, $02
	db $08, $80, $18, $c3, $87, $02, $08, $80, $18, $cd, $87, $02, $08, $80, $18, $d3
	db $87, $02, $08, $80, $18, $db, $87, $02, $08, $80, $08, $db, $87, $01
Sfx2_03_Init:
	ld hl, Sfx2_03_Data_513F
	jp Sfx2_Start

Sfx2_03_Play:
	call Sfx_DecTimer
	ret nz
	ld a, [bc]
	cp $7b
	ret z
	inc a
	ld [bc], a
	cp $7b
	jr nz, .l0
	ld a, $10
	ld [wSfx2Priority], a
	ret

.l0:
	ld hl, Sfx2_03_Data_4D4B
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx2_03_Data_513F:
	db $80, $08, $db, $87, $02
Sfx1_54_Init:
	ld hl, Sfx1_54_Data_516B
	jp Sfx1_Start

Sfx1_54_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx1_Stop
	ld hl, Sfx1_54_Data_515F
	call GetPointer
	jp SetRegs_Ch1

Sfx1_54_Data_515F:
	dw Sfx1_54_Data_5171, Sfx1_54_Data_5177, Sfx1_54_Data_517D, Sfx1_54_Data_5183, Sfx1_54_Data_5189, Sfx1_54_Data_518F
Sfx1_54_Data_516B:
	db $08, $80, $f8, $45, $87, $01
Sfx1_54_Data_5171:
	db $08, $80, $f8, $62, $87, $01
Sfx1_54_Data_5177:
	db $08, $80, $78, $39, $87, $01
Sfx1_54_Data_517D:
	db $08, $80, $78, $06, $87, $01
Sfx1_54_Data_5183:
	db $08, $80, $58, $d6, $86, $01
Sfx1_54_Data_5189:
	db $08, $80, $58, $9e, $86, $01
Sfx1_54_Data_518F:
	db $08, $80, $58, $5b, $86, $01
Sfx1_5D_Init:
	ld a, $07
	ld [wSfx4Request], a
	ld hl, Sfx1_5D_Data_51C1
	jp Sfx1_Start

Sfx1_5D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx1_Stop
	ld hl, Sfx1_5D_Data_51B5
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5D_Data_51B5:
	dw Sfx1_5D_Data_51C7, Sfx1_5D_Data_51CD, Sfx1_5D_Data_51D3, Sfx1_5D_Data_51D9, Sfx1_5D_Data_51DF, Sfx1_5D_Data_51E5
Sfx1_5D_Data_51C1:
	db $08, $40, $b8, $90, $87, $02
Sfx1_5D_Data_51C7:
	db $08, $40, $b8, $a7, $87, $02
Sfx1_5D_Data_51CD:
	db $08, $40, $b8, $b6, $87, $02
Sfx1_5D_Data_51D3:
	db $08, $40, $b8, $c1, $87, $02
Sfx1_5D_Data_51D9:
	db $08, $40, $b8, $c8, $87, $02
Sfx1_5D_Data_51DF:
	db $08, $40, $b8, $d4, $87, $02
Sfx1_5D_Data_51E5:
	db $08, $40, $b8, $db, $87, $02
Sfx1_4F_Init:
	ld a, $02
	ld [wSfx2Request], a
	ld hl, Sfx1_4F_Data_521B
	jp Sfx1_Start

Sfx1_4F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_4F_Data_520B
	call GetPointer
	jp SetRegs_Ch1

Sfx1_4F_Data_520B:
	dw Sfx1_4F_Data_5221, Sfx1_4F_Data_5227, Sfx1_4F_Data_522D, Sfx1_4F_Data_5233, Sfx1_4F_Data_5239, Sfx1_4F_Data_523F, Sfx1_4F_Data_5245, Sfx1_4F_Data_524B
Sfx1_4F_Data_521B:
	db $08, $80, $88, $90, $87, $05
Sfx1_4F_Data_5221:
	db $08, $80, $88, $ac, $87, $05
Sfx1_4F_Data_5227:
	db $08, $80, $88, $be, $87, $05
Sfx1_4F_Data_522D:
	db $08, $80, $88, $c8, $87, $06
Sfx1_4F_Data_5233:
	db $08, $80, $08, $83, $87, $06
Sfx1_4F_Data_5239:
	db $08, $80, $88, $d6, $87, $06
Sfx1_4F_Data_523F:
	db $08, $80, $08, $c1, $87, $06
Sfx1_4F_Data_5245:
	db $08, $80, $88, $c5, $87, $01
Sfx1_4F_Data_524B:
	db $08, $80, $88, $c8, $87, $12
Sfx2_02_Init:
	ld hl, Sfx2_02_Data_527C
	jp Sfx2_Start

Sfx2_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx2_Stop
	ld hl, Sfx2_02_Data_526C
	call GetPointer
	jp SetRegs_Ch2

Sfx2_02_Data_526C:
	dw Sfx2_02_Data_5281, Sfx2_02_Data_5286, Sfx2_02_Data_528B, Sfx2_02_Data_5290, Sfx2_02_Data_5295, Sfx2_02_Data_529A, Sfx2_02_Data_529F, Sfx2_02_Data_52A4
Sfx2_02_Data_527C:
	db $80, $88, $8f, $87, $05
Sfx2_02_Data_5281:
	db $80, $88, $ab, $87, $05
Sfx2_02_Data_5286:
	db $80, $88, $bd, $87, $05
Sfx2_02_Data_528B:
	db $80, $88, $c7, $87, $06
Sfx2_02_Data_5290:
	db $80, $08, $82, $87, $06
Sfx2_02_Data_5295:
	db $80, $88, $d5, $87, $06
Sfx2_02_Data_529A:
	db $80, $08, $c0, $87, $06
Sfx2_02_Data_529F:
	db $80, $88, $c4, $87, $01
Sfx2_02_Data_52A4:
	db $80, $88, $c7, $87, $12
Sfx1_5A_Init:
	ld a, $04
	ld [wSfx4Request], a
	ld a, [wSfx1Playing]
	cp $5a
	jr nz, .l0
	jp Sfx1_Continue

.l0:
	ld hl, Sfx1_5A_Data_5338
	jp Sfx1_Start

Sfx1_5A_Play:
	ld a, [wSfx1Request]
	cp $5a
	jp nz, Sfx1_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $2e
	jp c, .l1
	ld a, $2c
	ld [bc], a
.l1:
	ld hl, Sfx1_5A_Data_52DE
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5A_Data_52DE:
	dw Sfx1_5A_Data_533E, Sfx1_5A_Data_5344, Sfx1_5A_Data_534A, Sfx1_5A_Data_5350, Sfx1_5A_Data_5356, Sfx1_5A_Data_535C, Sfx1_5A_Data_5362, Sfx1_5A_Data_5368, Sfx1_5A_Data_536E, Sfx1_5A_Data_5374, Sfx1_5A_Data_537A, Sfx1_5A_Data_5380, Sfx1_5A_Data_5386, Sfx1_5A_Data_538C, Sfx1_5A_Data_5392, Sfx1_5A_Data_5398, Sfx1_5A_Data_539E, Sfx1_5A_Data_53A4, Sfx1_5A_Data_53AA, Sfx1_5A_Data_53B0, Sfx1_5A_Data_53B6, Sfx1_5A_Data_53BC, Sfx1_5A_Data_53C2, Sfx1_5A_Data_53C8, Sfx1_5A_Data_53CE, Sfx1_5A_Data_53D4, Sfx1_5A_Data_53DA, Sfx1_5A_Data_53E0, Sfx1_5A_Data_53E6, Sfx1_5A_Data_53EC, Sfx1_5A_Data_53F2, Sfx1_5A_Data_53F8, Sfx1_5A_Data_53FE, Sfx1_5A_Data_5404, Sfx1_5A_Data_540A, Sfx1_5A_Data_5410, Sfx1_5A_Data_5416, Sfx1_5A_Data_541C, Sfx1_5A_Data_5422, Sfx1_5A_Data_5428, Sfx1_5A_Data_542E, Sfx1_5A_Data_542E+6, Sfx1_5A_Data_542E+12, Sfx1_5A_Data_542E+18, Sfx1_5A_Data_542E+24
Sfx1_5A_Data_5338:
	db $08, $40, $48, $39, $87, $01
Sfx1_5A_Data_533E:
	db $08, $40, $48, $3e, $87, $01
Sfx1_5A_Data_5344:
	db $08, $40, $48, $45, $87, $01
Sfx1_5A_Data_534A:
	db $08, $40, $48, $41, $87, $02
Sfx1_5A_Data_5350:
	db $08, $40, $48, $46, $87, $01
Sfx1_5A_Data_5356:
	db $08, $40, $58, $41, $87, $01
Sfx1_5A_Data_535C:
	db $08, $40, $58, $48, $87, $02
Sfx1_5A_Data_5362:
	db $08, $40, $58, $4d, $87, $01
Sfx1_5A_Data_5368:
	db $08, $40, $58, $54, $87, $01
Sfx1_5A_Data_536E:
	db $08, $40, $58, $50, $87, $02
Sfx1_5A_Data_5374:
	db $08, $40, $58, $55, $87, $01
Sfx1_5A_Data_537A:
	db $08, $40, $68, $46, $87, $01
Sfx1_5A_Data_5380:
	db $08, $40, $68, $57, $87, $02
Sfx1_5A_Data_5386:
	db $08, $40, $68, $5c, $87, $01
Sfx1_5A_Data_538C:
	db $08, $40, $68, $63, $87, $01
Sfx1_5A_Data_5392:
	db $08, $40, $68, $5f, $87, $02
Sfx1_5A_Data_5398:
	db $08, $40, $68, $64, $87, $01
Sfx1_5A_Data_539E:
	db $08, $40, $78, $55, $87, $01
Sfx1_5A_Data_53A4:
	db $08, $40, $78, $66, $87, $02
Sfx1_5A_Data_53AA:
	db $08, $40, $78, $6b, $87, $01
Sfx1_5A_Data_53B0:
	db $08, $40, $78, $72, $87, $01
Sfx1_5A_Data_53B6:
	db $08, $40, $78, $6e, $87, $02
Sfx1_5A_Data_53BC:
	db $08, $40, $78, $73, $87, $01
Sfx1_5A_Data_53C2:
	db $08, $40, $88, $64, $87, $01
Sfx1_5A_Data_53C8:
	db $08, $40, $88, $75, $87, $02
Sfx1_5A_Data_53CE:
	db $08, $40, $88, $7a, $87, $01
Sfx1_5A_Data_53D4:
	db $08, $40, $88, $81, $87, $01
Sfx1_5A_Data_53DA:
	db $08, $40, $88, $7d, $87, $02
Sfx1_5A_Data_53E0:
	db $08, $40, $88, $82, $87, $01
Sfx1_5A_Data_53E6:
	db $08, $40, $98, $73, $87, $01
Sfx1_5A_Data_53EC:
	db $08, $40, $98, $84, $87, $02
Sfx1_5A_Data_53F2:
	db $08, $40, $98, $89, $87, $01
Sfx1_5A_Data_53F8:
	db $08, $40, $98, $90, $87, $01
Sfx1_5A_Data_53FE:
	db $08, $40, $98, $8c, $87, $02
Sfx1_5A_Data_5404:
	db $08, $40, $98, $8e, $87, $01
Sfx1_5A_Data_540A:
	db $08, $40, $a8, $82, $87, $01
Sfx1_5A_Data_5410:
	db $08, $40, $a8, $93, $87, $02
Sfx1_5A_Data_5416:
	db $08, $40, $a8, $98, $87, $01
Sfx1_5A_Data_541C:
	db $08, $40, $a8, $9f, $87, $01
Sfx1_5A_Data_5422:
	db $08, $40, $a8, $9b, $87, $02
Sfx1_5A_Data_5428:
	db $08, $40, $a8, $9d, $87, $01
Sfx1_5A_Data_542E:
	db $08, $40, $b8, $91, $87, $01
	db $08, $40, $b8, $a2, $87, $02
	db $08, $40, $98, $a1, $87, $01
	db $08, $40, $98, $a3, $87, $01
	db $08, $40, $98, $a1, $87, $01
Sfx4_04_Init:
	ld a, [wSfx4Playing]
	cp $04
	jr nz, .l0
	jp Sfx4_Continue

.l0:
	ld hl, Sfx4_04_Data_5488
	jp Sfx4_Start

Sfx4_04_Play:
	ld a, [wSfx4Request]
	cp $04
	jp nz, Sfx4_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp c, .l1
	ld a, $05
	ld [bc], a
.l1:
	ld hl, Sfx4_04_Data_547C
	call GetPointer
	jp SetRegs_Ch4

Sfx4_04_Data_547C:
	dw Sfx4_04_Data_548D, Sfx4_04_Data_5492, Sfx4_04_Data_5497, Sfx4_04_Data_549C, Sfx4_04_Data_54A1, Sfx4_04_Data_54A6
Sfx4_04_Data_5488:
	db $00, $28, $50, $80, $08
Sfx4_04_Data_548D:
	db $00, $48, $23, $80, $08
Sfx4_04_Data_5492:
	db $00, $68, $07, $80, $08
Sfx4_04_Data_5497:
	db $00, $88, $30, $80, $08
Sfx4_04_Data_549C:
	db $00, $a8, $20, $80, $08
Sfx4_04_Data_54A1:
	db $00, $c8, $10, $80, $01
Sfx4_04_Data_54A6:
	db $00, $c8, $00, $80, $01
Sfx1_59_Init:
	ld a, $04
	ld [wSfx2Request], a
	ld hl, Sfx1_59_Data_54D7
	jp Sfx1_Start

Sfx1_59_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx1_Stop
	ld hl, Sfx1_59_Data_54CB
	call GetPointer
	jp SetRegs_Ch1

Sfx1_59_Data_54CB:
	dw Sfx1_59_Data_54DD, Sfx1_59_Data_54E3, Sfx1_59_Data_54E9, Sfx1_59_Data_54EF, Sfx1_59_Data_54F5, Sfx1_59_Data_54FB
Sfx1_59_Data_54D7:
	db $08, $80, $f8, $83, $87, $02
Sfx1_59_Data_54DD:
	db $08, $80, $f8, $9d, $87, $02
Sfx1_59_Data_54E3:
	db $08, $80, $f8, $ac, $87, $02
Sfx1_59_Data_54E9:
	db $08, $80, $e8, $c1, $87, $02
Sfx1_59_Data_54EF:
	db $08, $80, $d8, $c8, $87, $02
Sfx1_59_Data_54F5:
	db $08, $80, $c8, $ce, $87, $02
Sfx1_59_Data_54FB:
	db $08, $80, $b8, $e0, $87, $03
Sfx2_04_Init:
	ld hl, Sfx2_04_Data_5528
	jp Sfx2_Start

Sfx2_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx2_Stop
	ld hl, Sfx2_04_Data_551C
	call GetPointer
	jp SetRegs_Ch2

Sfx2_04_Data_551C:
	dw Sfx2_04_Data_552D, Sfx2_04_Data_5532, Sfx2_04_Data_5537, Sfx2_04_Data_553C, Sfx2_04_Data_5541, Sfx2_04_Data_5546
Sfx2_04_Data_5528:
	db $80, $e8, $82, $87, $02
Sfx2_04_Data_552D:
	db $80, $e8, $ab, $87, $02
Sfx2_04_Data_5532:
	db $80, $e8, $c0, $87, $02
Sfx2_04_Data_5537:
	db $80, $d8, $c7, $87, $02
Sfx2_04_Data_553C:
	db $80, $c8, $cd, $87, $02
Sfx2_04_Data_5541:
	db $80, $b8, $ab, $87, $02
Sfx2_04_Data_5546:
	db $80, $a8, $82, $87, $03
Sfx1_50_Init:
	xor a
	ld [wSfxDE8A], a
.l1:
	ld a, $02
	ld [wSfx2Request], a
	ld hl, Sfx1_4F_Data_521B
	jp Sfx1_Start

Sfx1_50_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, .l0
	ld hl, Sfx1_4F_Data_520B
	call GetPointer
	jp SetRegs_Ch1

.l0:
	ld a, [wSfxDE8A]
	cp $02
	jp z, Sfx1_Stop
	inc a
	ld [wSfxDE8A], a
	ld a, $50
	ld [wSfx1Request], a
	jp Sfx1_50_Init.l1

Sfx1_5C_Init:
	ld hl, Sfx1_5C_Data_55BC
	jp Sfx1_Start

Sfx1_5C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx1_Stop
	ld hl, Sfx1_5C_Data_559E
	call GetPointer
	jp SetRegs_Ch1

Sfx1_5C_Data_559E:
	dw Sfx1_5C_Data_55C2, Sfx1_5C_Data_55C8, Sfx1_5C_Data_55CE, Sfx1_5C_Data_55D4, Sfx1_5C_Data_55DA, Sfx1_5C_Data_55E0, Sfx1_5C_Data_55E6, Sfx1_5C_Data_55EC, Sfx1_5C_Data_55F2, Sfx1_5C_Data_55F8, Sfx1_5C_Data_55FE, Sfx1_5C_Data_5604, Sfx1_5C_Data_560A, Sfx1_5C_Data_5610, Sfx1_5C_Data_5616
Sfx1_5C_Data_55BC:
	db $08, $80, $f8, $ce, $87, $01
Sfx1_5C_Data_55C2:
	db $08, $80, $08, $ce, $87, $01
Sfx1_5C_Data_55C8:
	db $08, $80, $f8, $cb, $87, $01
Sfx1_5C_Data_55CE:
	db $08, $80, $08, $ce, $87, $01
Sfx1_5C_Data_55D4:
	db $08, $80, $f8, $c8, $87, $01
Sfx1_5C_Data_55DA:
	db $08, $80, $d8, $be, $87, $01
Sfx1_5C_Data_55E0:
	db $08, $80, $b8, $b1, $87, $01
Sfx1_5C_Data_55E6:
	db $08, $80, $98, $a2, $87, $01
Sfx1_5C_Data_55EC:
	db $08, $80, $78, $90, $87, $01
Sfx1_5C_Data_55F2:
	db $08, $80, $58, $7b, $87, $01
Sfx1_5C_Data_55F8:
	db $08, $80, $48, $62, $87, $01
Sfx1_5C_Data_55FE:
	db $08, $80, $38, $4f, $87, $01
Sfx1_5C_Data_5604:
	db $08, $80, $38, $39, $87, $01
Sfx1_5C_Data_560A:
	db $08, $80, $28, $21, $87, $01
Sfx1_5C_Data_5610:
	db $08, $80, $28, $06, $87, $01
Sfx1_5C_Data_5616:
	db $08, $80, $18, $f7, $86, $01
Sfx1_03_Init:
	ld hl, Sfx1_03_Data_563F
	jp Sfx1_Start

Sfx1_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Release
	ld hl, Sfx1_03_Data_5637
	call GetPointer
	jp SetRegs_Ch1

Sfx1_03_Data_5637:
	dw Sfx1_03_Data_5645, Sfx1_03_Data_564B, Sfx1_03_Data_5651, Sfx1_03_Data_5657
Sfx1_03_Data_563F:
	db $08, $40, $a1, $44, $87, $04
Sfx1_03_Data_5645:
	db $08, $80, $a1, $6b, $87, $04
Sfx1_03_Data_564B:
	db $08, $80, $a1, $a2, $87, $04
Sfx1_03_Data_5651:
	db $08, $80, $a1, $83, $87, $04
Sfx1_03_Data_5657:
	db $08, $80, $a1, $ac, $87, $04
Sfx1_04_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_04_Data_568F
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_04_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_04_Data_5683
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_04_Data_5683:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx1_04_Data_568F:
	db $08, $80, $f2, $89, $86, $01
Sfx1_05_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_05_Data_56C3
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_05_Play:
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l1:
	ld hl, Sfx1_05_Data_56BB
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_05_Data_56BB:
	db $00, $a0
	db $ff, $58
	db $00, $a0
	db $ff, $58
Sfx1_05_Data_56C3:
	db $08, $c0, $f2, $44, $87, $01
Sfx1_06_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_06_Data_56F3
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_06_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx1_06_Data_56EF
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_06_Data_56EF:
	db $00, $c0
	db $ff, $a0
Sfx1_06_Data_56F3:
	db $08, $80, $f2, $23, $82, $01
Sfx1_07_Init:
	ld a, $12
	ld [wSfx1Counter], a
	ld hl, Sfx1_07_Data_573D
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_07_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l3:
	ld hl, Sfx1_07_Data_5F88
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $0c
	jr z, .l1
	cp $06
	jr z, .l2
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_07_Data_5743
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_07_Data_5749
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_07_Data_573D:
	db $08, $80, $f2, $11, $85, $01
Sfx1_07_Data_5743:
	db $08, $80, $82, $11, $85, $01
Sfx1_07_Data_5749:
	db $08, $80, $32, $11, $85, $01
Sfx1_08_Init:
	ld hl, Sfx1_08_Data_5786
	jp Sfx1_Start

Sfx1_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0f
	jp z, Sfx1_Stop
	ld hl, Sfx1_08_Data_576A
	call GetPointer
	jp SetRegs_Ch1

Sfx1_08_Data_576A:
	dw Sfx1_08_Data_57B6, Sfx1_08_Data_578C, Sfx1_08_Data_57B6, Sfx1_08_Data_5792, Sfx1_08_Data_57BC, Sfx1_08_Data_5798, Sfx1_08_Data_57C2, Sfx1_08_Data_579E, Sfx1_08_Data_57C2, Sfx1_08_Data_57A4, Sfx1_08_Data_57B6, Sfx1_08_Data_57AA, Sfx1_08_Data_57B6, Sfx1_08_Data_57B0
Sfx1_08_Data_5786:
	db $08, $80, $98, $c0, $87, $01
Sfx1_08_Data_578C:
	db $08, $80, $98, $c0, $87, $01
Sfx1_08_Data_5792:
	db $08, $80, $98, $e0, $87, $01
Sfx1_08_Data_5798:
	db $08, $80, $98, $60, $87, $01
Sfx1_08_Data_579E:
	db $08, $80, $98, $80, $87, $01
Sfx1_08_Data_57A4:
	db $08, $80, $98, $a0, $87, $01
Sfx1_08_Data_57AA:
	db $08, $80, $98, $c0, $87, $01
Sfx1_08_Data_57B0:
	db $08, $80, $98, $e0, $87, $01
Sfx1_08_Data_57B6:
	db $08, $80, $08, $e0, $80, $02
Sfx1_08_Data_57BC:
	db $08, $80, $08, $e0, $80, $0b
Sfx1_08_Data_57C2:
	db $08, $80, $08, $e0, $80, $03
Sfx1_09_Init:
	ld a, $1c
	ld [wSfx1Counter], a
	ld hl, Sfx1_09_Data_5808
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_09_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l3:
	ld hl, Sfx1_09_Data_5806
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $14
	jr z, .l1
	cp $0a
	jr z, .l2
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	ld hl, Sfx1_09_Data_580E
	jr .l4

.l2:
	ld hl, Sfx1_09_Data_5814
.l4:
	xor a
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_09_Data_5806:
	db $00, $60
Sfx1_09_Data_5808:
	db $08, $00, $59, $06, $81, $01
Sfx1_09_Data_580E:
	db $08, $00, $b7, $9c, $80, $01
Sfx1_09_Data_5814:
	db $08, $00, $47, $2c, $80, $01
Sfx1_68_Init:
	ld a, $28
	ld [wSfx1Counter], a
	ld hl, Sfx1_68_Data_5877
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_68_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l6:
	ld hl, Sfx1_68_Data_5873
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $22
	jr z, .l1
	cp $1c
	jr z, .l2
	cp $16
	jr z, .l3
	cp $10
	jr z, .l4
	cp $08
	jr z, .l5
	ld a, $01
	ld [bc], a
	jr .l6

.l1:
	ld hl, Sfx1_68_Data_587D
	jr .l7

.l2:
	ld hl, Sfx1_68_Data_5883
	jr .l7

.l3:
	ld hl, Sfx1_68_Data_5889
	jr .l7

.l4:
	ld hl, Sfx1_68_Data_588F
	jr .l7

.l5:
	ld hl, Sfx1_68_Data_5895
.l7:
	xor a
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_68_Data_5873:
	db $00, $40
	db $00, $25
Sfx1_68_Data_5877:
	db $08, $00, $57, $06, $81, $01
Sfx1_68_Data_587D:
	db $08, $00, $77, $6b, $81, $01
Sfx1_68_Data_5883:
	db $08, $00, $97, $c9, $81, $01
Sfx1_68_Data_5889:
	db $08, $00, $a7, $23, $82, $01
Sfx1_68_Data_588F:
	db $08, $00, $b7, $77, $82, $01
Sfx1_68_Data_5895:
	db $08, $00, $c7, $c6, $82, $01
Sfx1_0B_Init:
	ld a, $0d
	ld [wSfx4Request], a
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_0B_Data_58D9
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_0B_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_0B_Data_58CD
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Release
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_0B_Data_58CD:
	db $ff, $c0
	db $ff, $80
	db $ff, $40
	db $00, $c0
	db $00, $80
	db $00, $40
Sfx1_0B_Data_58D9:
	db $08, $80, $f4, $83, $84, $01
Sfx4_0D_Init:
	ld hl, Sfx4_0D_Data_5900
	jp Sfx4_Start

Sfx4_0D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Release
	ld hl, Sfx4_0D_Data_58FA
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0D_Data_58FA:
	dw Sfx4_0D_Data_5905, Sfx4_0D_Data_590A, Sfx4_0D_Data_590F
Sfx4_0D_Data_5900:
	db $00, $92, $05, $80, $03
Sfx4_0D_Data_5905:
	db $00, $01, $17, $80, $02
Sfx4_0D_Data_590A:
	db $00, $72, $15, $80, $01
Sfx4_0D_Data_590F:
	db $00, $67, $37, $80, $10
Sfx1_0E_Init:
	ld a, $14
	ld [wSfx1Counter], a
	ld hl, Sfx1_0E_Data_594E
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_0E_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_0E_Data_594A
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Release
	cp $10
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	ld hl, Sfx1_0E_Data_5954
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_0E_Data_594A:
	db $ff, $fc
	db $00, $02
Sfx1_0E_Data_594E:
	db $08, $00, $19, $d9, $87, $01
Sfx1_0E_Data_5954:
	db $08, $00, $47, $d1, $87, $01
Sfx1_10_Init:
	ld a, $1c
	ld [wSfx1Counter], a
	ld hl, Sfx1_10_Data_599C
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_10_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l3:
	ld hl, Sfx1_10_Data_5998
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $14
	jr z, .l1
	cp $0a
	jr z, .l2
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	ld hl, Sfx1_10_Data_59A2
	jr .l4

.l2:
	ld hl, Sfx1_10_Data_59A8
.l4:
	xor a
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_10_Data_5998:
	db $00, $15
	db $ff, $f0
Sfx1_10_Data_599C:
	db $08, $00, $38, $b2, $87, $01
Sfx1_10_Data_59A2:
	db $08, $00, $58, $b2, $87, $01
Sfx1_10_Data_59A8:
	db $08, $00, $18, $b2, $87, $01
Sfx1_11_Init:
	ld hl, Sfx1_11_Data_59D5
	jp Sfx1_StartSweep

Sfx1_11_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_11_Data_59CB
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_11_Data_59CB:
	dw Sfx1_11_Data_59DB, Sfx1_11_Data_59E1, Sfx1_11_Data_59E7, Sfx1_11_Data_59ED, Sfx1_11_Data_59F3
Sfx1_11_Data_59D5:
	db $00, $00, $b8, $ce, $85, $04
Sfx1_11_Data_59DB:
	db $15, $00, $f2, $42, $86, $0a
Sfx1_11_Data_59E1:
	db $15, $00, $b2, $42, $86, $09
Sfx1_11_Data_59E7:
	db $15, $00, $92, $42, $86, $08
Sfx1_11_Data_59ED:
	db $15, $00, $72, $42, $86, $08
Sfx1_11_Data_59F3:
	db $15, $00, $42, $42, $86, $07
Sfx1_12_Init:
	ld hl, Sfx1_12_Data_5A18
	jp Sfx1_StartSweep

Sfx1_12_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_12_Data_5A16
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_12_Data_5A16:
	dw Sfx1_12_Data_5A1E
Sfx1_12_Data_5A18:
	db $14, $40, $4a, $ed, $85, $02
Sfx1_12_Data_5A1E:
	db $12, $40, $b2, $f7, $86, $03
Sfx1_13_Init:
	ld hl, Sfx1_13_Data_5A31
	jp Sfx1_Start

Sfx1_13_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_13_Data_5A31:
	db $08, $80, $a3, $59, $87, $1c
Sfx1_6D_Init:
	ld hl, Sfx1_6D_Data_5A58
	jp Sfx1_Start

Sfx1_6D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx1_6D_Data_5A52
	call GetPointer
	jp SetRegs_Ch1

Sfx1_6D_Data_5A52:
	dw Sfx1_6D_Data_5A5E, Sfx1_6D_Data_5A64, Sfx1_6D_Data_5A6A
Sfx1_6D_Data_5A58:
	db $08, $80, $83, $6b, $87, $07
Sfx1_6D_Data_5A5E:
	db $08, $40, $53, $b6, $87, $07
Sfx1_6D_Data_5A64:
	db $08, $80, $83, $6b, $87, $07
Sfx1_6D_Data_5A6A:
	db $08, $40, $53, $b6, $87, $07
Sfx1_17_Init:
	ld hl, Sfx1_17_Data_5A9F
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_17_Play:
	call Sfx_IncStep
	cp $0d
	jp z, Sfx1_Stop
	ld hl, Sfx1_17_Data_5A87
	jp Sfx1_AddPitch

Sfx1_17_Data_5A87:
	db $ff, $c0
	db $ff, $80
	db $ff, $00
	db $fe, $00
	db $01, $00
	db $ff, $00
	db $01, $00
	db $ff, $00
	db $00, $c0
	db $00, $c0
	db $00, $c0
	db $00, $c0
Sfx1_17_Data_5A9F:
	db $08, $80, $c8, $ac, $87, $01
Sfx1_56_Init:
	ld hl, Sfx1_56_Data_5ACA
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_56_Play:
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_56_Data_5ABC
	jp Sfx1_AddPitch

Sfx1_56_Data_5ABC:
	db $ff, $e0
	db $00, $e0
	db $00, $20
	db $00, $20
	db $00, $20
	db $00, $20
	db $00, $20
Sfx1_56_Data_5ACA:
	db $08, $80, $e8, $0a, $86, $01
Sfx1_57_Init:
	ld hl, Sfx1_57_Data_5AF5
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_57_Play:
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_57_Data_5AE7
	jp Sfx1_AddPitch

Sfx1_57_Data_5AE7:
	db $00, $20
	db $ff, $20
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
Sfx1_57_Data_5AF5:
	db $08, $80, $e8, $06, $87, $01
Sfx1_1B_Init:
	ld hl, Sfx1_1B_Data_5B20
	jp Sfx1_Start

Sfx1_1B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_1B_Data_5B16
	call GetPointer
	jp SetRegs_Ch1

Sfx1_1B_Data_5B16:
	dw Sfx1_1B_Data_5B26, Sfx1_1B_Data_5B2C, Sfx1_1B_Data_5B32, Sfx1_1B_Data_5B38, Sfx1_1B_Data_5B3E
Sfx1_1B_Data_5B20:
	db $08, $80, $e8, $0a, $86, $01
Sfx1_1B_Data_5B26:
	db $08, $80, $48, $ed, $85, $01
Sfx1_1B_Data_5B2C:
	db $08, $80, $18, $ed, $85, $02
Sfx1_1B_Data_5B32:
	db $08, $80, $98, $83, $87, $01
Sfx1_1B_Data_5B38:
	db $08, $80, $58, $8a, $87, $01
Sfx1_1B_Data_5B3E:
	db $08, $80, $58, $90, $87, $01
Sfx1_1D_Init:
	ld hl, Sfx1_1D_Data_5B65
	jp Sfx1_StartSweep

Sfx1_1D_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx1_1D_Data_5B61
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_1D_Data_5B61:
	dw Sfx1_1D_Data_5B6B, Sfx1_1D_Data_5B71
Sfx1_1D_Data_5B65:
	db $16, $00, $68, $72, $86, $05
Sfx1_1D_Data_5B6B:
	db $16, $40, $48, $72, $86, $05
Sfx1_1D_Data_5B71:
	db $16, $40, $28, $72, $86, $05
Sfx1_1E_Init:
	ld hl, Sfx1_1E_Data_5B8F
	jp Sfx1_Start

Sfx1_1E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_1E_Data_5B95
	jp SetRegs_Ch1

Sfx1_1E_Data_5B8F:
	db $08, $80, $a8, $06, $87, $02
Sfx1_1E_Data_5B95:
	db $08, $80, $78, $83, $87, $04
Sfx1_69_Init:
	ld a, [wSfx1Playing]
	cp $69
	jp z, Sfx1_Refuse
	ld hl, Sfx1_69_Data_5BBB
	jp Sfx1_Start

Sfx1_69_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_69_Data_5BC1
	jp SetRegs_Ch1

Sfx1_69_Data_5BBB:
	db $08, $40, $a7, $06, $87, $02
Sfx1_69_Data_5BC1:
	db $08, $40, $78, $83, $87, $04
Sfx1_20_Init:
	ld a, $21
	ld [wSfx2Request], a
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_20_Data_5C0C
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_20_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_20_Data_5BFA
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

Sfx1_20_Data_5BFA:
	db $00, $12
	db $00, $0e
	db $00, $0a
	db $00, $08
	db $00, $06
	db $00, $04
	db $00, $02
	db $00, $01
	db $ff, $c1
Sfx1_20_Data_5C0C:
	db $08, $00, $e2, $00, $87, $01
Sfx2_21_Init:
	ld a, $07
	ld [wSfx2Counter], a
	ld hl, Sfx2_21_Data_5C44
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_21_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx2_21_Data_5C38
	jp Sfx2_AddPitch

.l0:
	call Sfx2_DecCounter
	jp z, Sfx2_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx2_21_Data_5C38:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx2_21_Data_5C44:
	db $40, $f2, $00, $85, $01
Sfx1_21_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_21_Data_5C7B
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_21_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_21_Data_5C6F
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_21_Data_5C6F:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx1_21_Data_5C7B:
	db $08, $00, $f2, $00, $85, $01
Sfx1_23_Init:
	ld hl, Sfx1_23_Data_5C9B
	jp Sfx1_StartSweep

Sfx1_23_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_23_Data_5CA1
	jp Sfx1_SweepStart

Sfx1_23_Data_5C9B:
	db $1c, $80, $96, $06, $87, $06
Sfx1_23_Data_5CA1:
	db $13, $80, $97, $f7, $86, $05
Sfx1_27_Init:
	ld hl, Sfx1_27_Data_5CBF
	jp Sfx1_Start

Sfx1_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_27_Data_5CC5
	jp SetRegs_Ch1

Sfx1_27_Data_5CBF:
	db $08, $80, $a1, $90, $87, $03
Sfx1_27_Data_5CC5:
	db $08, $40, $88, $21, $87, $05
Sfx1_29_Init:
	ld hl, Sfx1_29_Data_5CF6
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_29_Play:
	call Sfx_IncStep
	cp $0b
	jp z, Sfx1_Stop
	ld hl, Sfx1_29_Data_5CE2
	jp Sfx1_AddPitch

Sfx1_29_Data_5CE2:
	db $00, $c0
	db $ff, $00
	db $ff, $00
	db $ff, $00
	db $ff, $00
	db $00, $c0
	db $00, $c0
	db $00, $c0
	db $00, $c0
	db $00, $c0
Sfx1_29_Data_5CF6:
	db $08, $80, $f8, $0a, $86, $01
Sfx1_2B_Init:
	ld a, [wSfx1Playing]
	cp $2b
	jr nz, .l0
	jp Sfx1_Continue

.l0:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_2B_Data_5D64
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2B_Play:
	ld a, [wSfx1Request]
	cp $2b
	jp nz, Sfx1_Stop
	call Sfx_IncStep
	cp $05
	jr z, .l1
	cp $06
	jr z, .l2
.l5:
	ld hl, Sfx1_2B_Data_5D5A
	jp Sfx1_AddPitch

.l1:
	call Sfx1_DecCounter
	jp z, .l3
	cp $04
	jr z, .l4
	ld a, [bc]
	jr .l5

.l2:
	ld a, $01
	ld [bc], a
	jr .l5

.l4:
	xor a
	ld [bc], a
	ld hl, Sfx1_2B_Data_5D6A
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l3:
	ld a, $08
	ld [wSfx1Counter], a
	xor a
	ld [bc], a
	ld hl, Sfx1_2B_Data_5D64
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_2B_Data_5D5A:
	db $00, $10
	db $00, $10
	db $00, $08
	db $00, $04
	db $ff, $d4
Sfx1_2B_Data_5D64:
	db $08, $40, $5e, $4f, $87, $01
Sfx1_2B_Data_5D6A:
	db $08, $00, $c6, $4f, $87, $01
Sfx1_0C_Init:
	ld a, [wSfx1Playing]
	cp $0c
	jr nz, .l0
	jp Sfx1_Continue

.l0:
	ld hl, Sfx1_0C_Data_5D89
	jp Sfx1_Start

Sfx1_0C_Play:
	ld a, [wSfx1Request]
	cp $0c
	jp nz, Sfx1_Stop
	ret

Sfx1_0C_Data_5D89:
	db $08, $40, $08, $4f, $87, $01
Sfx1_2E_Init:
	ld hl, Sfx1_2E_Data_5D9E
	jp Sfx1_StartSweep

Sfx1_2E_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_2E_Data_5D9E:
	db $1c, $80, $e4, $6b, $87, $28
Sfx1_28_Init:
	ld hl, Sfx1_28_Data_5DB3
	jp Sfx1_StartSweep

Sfx1_28_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Release

Sfx1_28_Data_5DB3:
	db $1d, $80, $d5, $90, $87, $3c
Sfx1_2D_Init:
	ld hl, Sfx1_2D_Data_5DC8
	jp Sfx1_StartSweep

Sfx1_2D_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Release

Sfx1_2D_Data_5DC8:
	db $1b, $40, $e2, $6b, $87, $14
Sfx1_66_Init:
	ld hl, Sfx1_66_Data_5DDD
	jp Sfx1_StartSweep

Sfx1_66_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Release

Sfx1_66_Data_5DDD:
	db $1c, $80, $f2, $9d, $87, $19
Sfx1_1F_Init:
	ld hl, Sfx1_1F_Data_5DF2
	jp Sfx1_StartSweep

Sfx1_1F_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_1F_Data_5DF2:
	db $13, $40, $a2, $ed, $85, $05
Sfx1_31_Init:
	ld a, $06
	ld [wSfx1Counter], a
	ld hl, Sfx1_31_Data_5E2E
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_31_Play:
	call Sfx_IncStep
	cp $05
	jr z, .l0
	cp $06
	jr z, .l1
.l2:
	ld hl, Sfx1_31_Data_5E24
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_31_Data_5E24:
	db $00, $01
	db $00, $02
	db $00, $03
	db $00, $04
	db $ff, $fa
Sfx1_31_Data_5E2E:
	db $08, $00, $87, $c0, $87, $01
Sfx1_32_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_32_Data_5E6A
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_32_Play:
	call Sfx_IncStep
	cp $06
	jr z, .l0
	ld hl, Sfx1_32_Data_5E60
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	xor a
	ld [bc], a
	ld hl, Sfx1_32_Data_5E70
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_32_Data_5E60:
	db $00, $02
	db $00, $02
	db $00, $02
	db $00, $01
	db $00, $01
Sfx1_32_Data_5E6A:
	db $08, $80, $d8, $c0, $87, $02
Sfx1_32_Data_5E70:
	db $08, $80, $38, $c0, $87, $01
Sfx1_01_Init:
	jp Sfx1_Refuse

Sfx1_01_Play:
	ret

Sfx1_37_Init:
	ld a, [wSfx1Playing]
	cp $37
	jp z, Sfx1_Refuse
	ld hl, Sfx1_37_Data_5EA7
	jp Sfx1_Start

Sfx1_37_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx1_Stop
	ld hl, Sfx1_37_Data_5E9D
	call GetPointer
	jp SetRegs_Ch1

Sfx1_37_Data_5E9D:
	dw Sfx1_37_Data_5EB9, Sfx1_37_Data_5EAD, Sfx1_37_Data_5EBF, Sfx1_37_Data_5EB3, Sfx1_37_Data_5EC5
Sfx1_37_Data_5EA7:
	db $08, $80, $53, $90, $87, $04
Sfx1_37_Data_5EAD:
	db $08, $80, $53, $74, $87, $05
Sfx1_37_Data_5EB3:
	db $08, $80, $52, $d1, $87, $04
Sfx1_37_Data_5EB9:
	db $08, $80, $08, $d1, $87, $04
Sfx1_37_Data_5EBF:
	db $08, $80, $08, $d1, $87, $02
Sfx1_37_Data_5EC5:
	db $08, $80, $08, $d1, $87, $06
Sfx1_3A_Init:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_3A_Data_5EF7
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3A_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l1:
	ld hl, Sfx1_3A_Data_5EF1
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_3A_Data_5EF1:
	db $00, $10
	db $00, $18
	db $ff, $f0
Sfx1_3A_Data_5EF7:
	db $08, $00, $87, $0a, $86, $02
Sfx1_3B_Init:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_3B_Data_5F29
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3B_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l1:
	ld hl, Sfx1_3B_Data_5F23
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_3B_Data_5F23:
	db $ff, $f8
	db $ff, $ee
	db $00, $10
Sfx1_3B_Data_5F29:
	db $08, $00, $a7, $b2, $86, $02
Sfx1_3C_Init:
	ld hl, Sfx1_3C_Data_5F47
	jp Sfx1_Start

Sfx1_3C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Release
	ld hl, Sfx1_3C_Data_5F4D
	jp SetRegs_Ch1

Sfx1_3C_Data_5F47:
	db $08, $00, $7b, $a2, $87, $02
Sfx1_3C_Data_5F4D:
	db $08, $00, $a3, $d1, $87, $07
Sfx1_3D_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_3D_Data_5F8C
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3D_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_07_Data_5F88
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $06
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_3D_Data_5F92
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_07_Data_5F88:
	db $00, $c0
	db $ff, $a0
Sfx1_3D_Data_5F8C:
	db $08, $80, $f2, $83, $84, $01
Sfx1_3D_Data_5F92:
	db $08, $80, $42, $83, $84, $01
Sfx1_3E_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_3E_Data_5FCD
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3E_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_07_Data_5F88
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $06
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_3E_Data_5FD3
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3E_Data_5FCD:
	db $08, $80, $f2, $b5, $84, $01
Sfx1_3E_Data_5FD3:
	db $08, $80, $62, $b5, $84, $01
Sfx1_3F_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_3F_Data_600E
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3F_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_07_Data_5F88
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $06
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_3F_Data_6014
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3F_Data_600E:
	db $08, $80, $f2, $e5, $84, $01
Sfx1_3F_Data_6014:
	db $08, $80, $72, $e5, $84, $01
Sfx1_40_Init:
	ld a, $12
	ld [wSfx1Counter], a
	ld hl, Sfx1_40_Data_6058
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_40_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l3:
	ld hl, Sfx1_07_Data_5F88
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $0c
	jr z, .l1
	cp $06
	jr z, .l2
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	ld hl, Sfx1_40_Data_605E
	jr .l4

.l2:
	ld hl, Sfx1_40_Data_6064
.l4:
	xor a
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_40_Data_6058:
	db $08, $80, $f2, $11, $85, $01
Sfx1_40_Data_605E:
	db $08, $80, $82, $11, $85, $01
Sfx1_40_Data_6064:
	db $08, $80, $42, $11, $85, $01
Sfx1_25_Init:
	ld a, $06
	ld [wSfx2Request], a
	ld a, $03
	ld [wSfx3Request], a
	ld a, $05
	ld [wSfx4Request], a
	xor a
	ld [wSfx1Priority], a
	ld hl, Sfx1_25_Data_608C
	jp Sfx1_StartSweep

Sfx1_25_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_25_Data_608C:
	db $14, $80, $a8, $89, $86, $0f
Sfx1_41_Init:
	ld hl, Sfx1_41_Data_60A1
	jp Sfx1_StartSweep

Sfx1_41_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_41_Data_60A1:
	db $14, $80, $a8, $89, $86, $0f
Sfx1_42_Init:
	ld hl, Sfx1_42_Data_60B6
	jp Sfx1_StartSweep

Sfx1_42_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_42_Data_60B6:
	db $14, $80, $a8, $9e, $86, $0f
Sfx1_43_Init:
	ld hl, Sfx1_43_Data_60CB
	jp Sfx1_StartSweep

Sfx1_43_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_43_Data_60CB:
	db $14, $80, $a8, $b2, $86, $0f
Sfx1_44_Init:
	ld hl, Sfx1_44_Data_60E0
	jp Sfx1_StartSweep

Sfx1_44_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_44_Data_60E0:
	db $14, $80, $a8, $c4, $86, $0f
Sfx1_45_Init:
	ld hl, Sfx1_45_Data_60F5
	jp Sfx1_StartSweep

Sfx1_45_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_45_Data_60F5:
	db $14, $80, $a8, $d6, $86, $0f
Sfx1_46_Init:
	ld hl, Sfx1_46_Data_610A
	jp Sfx1_StartSweep

Sfx1_46_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_46_Data_610A:
	db $14, $80, $a8, $e7, $86, $0f
Sfx1_47_Init:
	ld hl, Sfx1_47_Data_611F
	jp Sfx1_StartSweep

Sfx1_47_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_47_Data_611F:
	db $14, $80, $a8, $f7, $86, $0f
Sfx1_48_Init:
	ld hl, Sfx1_48_Data_6134
	jp Sfx1_StartSweep

Sfx1_48_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_48_Data_6134:
	db $14, $80, $c8, $06, $87, $0f
Sfx1_18_Init:
	ld hl, Sfx1_18_Data_6149
	jp Sfx1_StartSweep

Sfx1_18_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	jp Sfx1_Stop

Sfx1_18_Data_6149:
	db $13, $80, $98, $b2, $86, $0a
Sfx1_4D_Init:
	call Sfx3_Stop
	call Sfx4_Stop
	xor a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld a, [wSongPlaying]
	ld [$ded1], a
	xor a
	ld [wSongPlaying], a
	ld [wChannelsPlayed], a
	ld a, $01
	ld [wSfx2Request], a
	ld hl, Sfx1_4D_Data_619B
	jp Sfx1_Start

Sfx1_4D_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_4D_Data_6189
	call GetPointer
	jp SetRegs_Ch1

Sfx1_4D_Data_6189:
	dw Sfx1_4D_Data_61A1, Sfx1_4D_Data_61A7, Sfx1_4D_Data_61AD, Sfx1_4D_Data_61B3, Sfx1_4D_Data_61B9, Sfx1_4D_Data_61BF, Sfx1_4D_Data_61C5, Sfx1_4D_Data_61CB, Sfx1_4D_Data_61D1
Sfx1_4D_Data_619B:
	db $08, $80, $f8, $b6, $87, $04
Sfx1_4D_Data_61A1:
	db $08, $80, $f8, $c1, $87, $02
Sfx1_4D_Data_61A7:
	db $08, $80, $f8, $c8, $87, $02
Sfx1_4D_Data_61AD:
	db $08, $80, $f8, $d1, $87, $04
Sfx1_4D_Data_61B3:
	db $08, $80, $08, $83, $87, $02
Sfx1_4D_Data_61B9:
	db $08, $80, $38, $b6, $87, $04
Sfx1_4D_Data_61BF:
	db $08, $80, $38, $c1, $87, $02
Sfx1_4D_Data_61C5:
	db $08, $80, $38, $c8, $87, $02
Sfx1_4D_Data_61CB:
	db $08, $80, $38, $d1, $87, $04
Sfx1_4D_Data_61D1:
	db $08, $80, $08, $d1, $87, $2a
Sfx2_01_Init:
	ld hl, Sfx2_01_Data_6204
	jp Sfx2_Start

Sfx2_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx2_Stop
	ld hl, Sfx2_01_Data_61F2
	call GetPointer
	jp SetRegs_Ch2

Sfx2_01_Data_61F2:
	dw Sfx2_01_Data_6209, Sfx2_01_Data_620E, Sfx2_01_Data_6213, Sfx2_01_Data_6218, Sfx2_01_Data_621D, Sfx2_01_Data_6222, Sfx2_01_Data_6227, Sfx2_01_Data_622C, Sfx2_01_Data_6231
Sfx2_01_Data_6204:
	db $80, $e8, $b5, $87, $04
Sfx2_01_Data_6209:
	db $80, $e8, $c0, $87, $02
Sfx2_01_Data_620E:
	db $80, $e8, $c7, $87, $02
Sfx2_01_Data_6213:
	db $80, $e8, $d0, $87, $04
Sfx2_01_Data_6218:
	db $80, $08, $83, $87, $02
Sfx2_01_Data_621D:
	db $80, $28, $b5, $87, $04
Sfx2_01_Data_6222:
	db $80, $28, $c0, $87, $02
Sfx2_01_Data_6227:
	db $80, $28, $c7, $87, $02
Sfx2_01_Data_622C:
	db $80, $28, $d0, $87, $04
Sfx2_01_Data_6231:
	db $80, $08, $d0, $87, $2a
Sfx1_4E_Init:
	ld a, [$ded1]
	ld [wSongPlaying], a
	ld a, $01
	ld [wSfx2Request], a
	ld hl, Sfx1_4D_Data_619B
	jp Sfx1_Start

Sfx1_51_Init:
	ld a, [$ded1]
	ld [wSongPlaying], a
	ld a, $31
	ld [wSfx2Request], a
	ld a, $05
	ld [wSfx3Request], a
	ld a, $28
	ld [wSfx4Request], a
	ld hl, Sfx1_4D_Data_619B
	jp Sfx1_Start

Sfx1_51_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx1_Stop
	ld hl, Sfx1_4D_Data_6189
	call GetPointer
	jp SetRegs_Ch1

Sfx1_22_Init:
	ld hl, Sfx1_22_Data_62B6
	jp Sfx1_StartSweep

Sfx1_22_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $0f
	jp z, Sfx1_StopSilent
	ld hl, Sfx1_22_Data_6294
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_22_Data_6294:
	dw Sfx1_22_Data_62BC, Sfx1_22_Data_62C2, Sfx1_22_Data_62C8, Sfx1_22_Data_62CE, Sfx1_22_Data_62D4, Sfx1_22_Data_62FE, Sfx1_22_Data_62DA, Sfx1_22_Data_6304, Sfx1_22_Data_62E0, Sfx1_22_Data_630A, Sfx1_22_Data_62E6, Sfx1_22_Data_630A, Sfx1_22_Data_62EC, Sfx1_22_Data_6310, Sfx1_22_Data_62F2, Sfx1_22_Data_6310, Sfx1_22_Data_62F8
Sfx1_22_Data_62B6:
	db $1c, $80, $a8, $06, $87, $08
Sfx1_22_Data_62BC:
	db $1c, $80, $a8, $e7, $86, $08
Sfx1_22_Data_62C2:
	db $1c, $80, $a8, $9e, $86, $08
Sfx1_22_Data_62C8:
	db $1c, $80, $a8, $5b, $86, $08
Sfx1_22_Data_62CE:
	db $1b, $80, $a8, $5b, $86, $08
Sfx1_22_Data_62D4:
	db $1b, $80, $a8, $0a, $86, $07
Sfx1_22_Data_62DA:
	db $1b, $80, $a8, $89, $85, $06
Sfx1_22_Data_62E0:
	db $1b, $80, $a8, $e5, $84, $05
Sfx1_22_Data_62E6:
	db $1b, $80, $a8, $e5, $84, $05
Sfx1_22_Data_62EC:
	db $1b, $80, $a4, $9b, $83, $04
Sfx1_22_Data_62F2:
	db $1b, $80, $82, $9b, $83, $04
Sfx1_22_Data_62F8:
	db $1b, $80, $42, $c6, $82, $03
Sfx1_22_Data_62FE:
	db $1b, $80, $11, $0a, $85, $01
Sfx1_22_Data_6304:
	db $1b, $80, $11, $0a, $85, $02
Sfx1_22_Data_630A:
	db $1b, $80, $11, $0a, $85, $03
Sfx1_22_Data_6310:
	db $1b, $80, $11, $0a, $85, $04
Sfx1_64_Init:
	ld hl, Sfx1_64_Data_632E
	jp Sfx1_Start

Sfx1_64_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Release
	ld hl, Sfx1_64_Data_6334
	jp SetRegs_Ch1

Sfx1_64_Data_632E:
	db $08, $40, $c7, $d6, $86, $05
Sfx1_64_Data_6334:
	db $08, $40, $62, $d6, $86, $0e
Sfx1_65_Init:
	ld hl, Sfx1_65_Data_6352
	jp Sfx1_Start

Sfx1_65_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Release
	ld hl, Sfx1_65_Data_6358
	jp SetRegs_Ch1

Sfx1_65_Data_6352:
	db $08, $40, $e7, $6b, $87, $05
Sfx1_65_Data_6358:
	db $08, $40, $87, $6b, $87, $38
Sfx1_73_Init:
	ld hl, Sfx1_73_Data_63BB
	jp Sfx1_StartSweep

Sfx1_73_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $21
	jp z, Sfx1_Release
	ld hl, Sfx1_73_Data_637B
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_73_Data_637B:
	dw Sfx1_73_Data_6403, Sfx1_73_Data_63C1, Sfx1_73_Data_6403, Sfx1_73_Data_63C7, Sfx1_73_Data_6403, Sfx1_73_Data_63CD, Sfx1_73_Data_6403, Sfx1_73_Data_63D3, Sfx1_73_Data_6403, Sfx1_73_Data_63BB, Sfx1_73_Data_6403, Sfx1_73_Data_63C1, Sfx1_73_Data_6403, Sfx1_73_Data_63C7, Sfx1_73_Data_6403, Sfx1_73_Data_63CD, Sfx1_73_Data_6403, Sfx1_73_Data_63D3, Sfx1_73_Data_6403, Sfx1_73_Data_63D9, Sfx1_73_Data_6403, Sfx1_73_Data_63DF, Sfx1_73_Data_6403, Sfx1_73_Data_63E5, Sfx1_73_Data_6403, Sfx1_73_Data_63EB, Sfx1_73_Data_6403, Sfx1_73_Data_63F1, Sfx1_73_Data_6403, Sfx1_73_Data_63F7, Sfx1_73_Data_6403, Sfx1_73_Data_63FD
Sfx1_73_Data_63BB:
	db $1b, $00, $99, $a2, $87, $02
Sfx1_73_Data_63C1:
	db $1b, $00, $f9, $a4, $87, $02
Sfx1_73_Data_63C7:
	db $1b, $00, $d9, $a2, $87, $02
Sfx1_73_Data_63CD:
	db $1b, $00, $f9, $9d, $87, $02
Sfx1_73_Data_63D3:
	db $1b, $00, $99, $97, $87, $02
Sfx1_73_Data_63D9:
	db $1b, $00, $89, $90, $87, $02
Sfx1_73_Data_63DF:
	db $1b, $00, $79, $59, $87, $02
Sfx1_73_Data_63E5:
	db $1b, $00, $49, $59, $87, $02
Sfx1_73_Data_63EB:
	db $1b, $00, $39, $59, $87, $02
Sfx1_73_Data_63F1:
	db $1b, $00, $29, $59, $87, $02
Sfx1_73_Data_63F7:
	db $1b, $00, $19, $59, $87, $02
Sfx1_73_Data_63FD:
	db $1b, $00, $12, $59, $87, $02
Sfx1_73_Data_6403:
	db $1b, $00, $08, $59, $87, $02
Sfx1_77_Init:
	xor a
	ld [$ded3], a
	ld hl, Sfx1_77_Data_6447
	jp Sfx1_Start

Sfx1_77_Play:
	call Sfx_DecTimer
	jr nz, .l0
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_77_Data_644D
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l0:
	ld a, [bc]
	and a
	ret z
	ld hl, $0007
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

Sfx1_77_Data_6447:
	db $08, $80, $59, $06, $87, $05
Sfx1_77_Data_644D:
	db $08, $80, $92, $06, $87, $0c
Sfx1_78_Init:
	ld hl, Sfx1_78_Data_649E
	jp Sfx1_Start

Sfx1_78_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $19
	jp z, Sfx1_Stop
	ld hl, Sfx1_78_Data_646E
	call GetPointer
	jp SetRegsPartial_Ch1

Sfx1_78_Data_646E:
	dw Sfx1_78_Data_649E, Sfx1_78_Data_64A4, Sfx1_78_Data_64AA, Sfx1_78_Data_64B0, Sfx1_78_Data_64B6, Sfx1_78_Data_64BC, Sfx1_78_Data_64C2, Sfx1_78_Data_64C8, Sfx1_78_Data_64CE, Sfx1_78_Data_64D4, Sfx1_78_Data_64DA, Sfx1_78_Data_64E0, Sfx1_78_Data_64E6, Sfx1_78_Data_64EC, Sfx1_78_Data_64F2, Sfx1_78_Data_64F8, Sfx1_78_Data_64FE, Sfx1_78_Data_6504, Sfx1_78_Data_650A, Sfx1_78_Data_6510, Sfx1_78_Data_6516, Sfx1_78_Data_651C, Sfx1_78_Data_6522, Sfx1_78_Data_6528
Sfx1_78_Data_649E:
	db $08, $40, $3a, $9d, $87, $02
Sfx1_78_Data_64A4:
	db $00, $00, $00, $90, $07, $02
Sfx1_78_Data_64AA:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_64B0:
	db $00, $00, $00, $83, $07, $02
Sfx1_78_Data_64B6:
	db $00, $00, $00, $9d, $07, $02
Sfx1_78_Data_64BC:
	db $00, $00, $00, $90, $07, $02
Sfx1_78_Data_64C2:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_64C8:
	db $00, $00, $00, $83, $07, $02
Sfx1_78_Data_64CE:
	db $08, $00, $b2, $8a, $87, $02
Sfx1_78_Data_64D4:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_64DA:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_64E0:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_64E6:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_64EC:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_64F2:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_64F8:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_64FE:
	db $08, $00, $62, $8a, $87, $02
Sfx1_78_Data_6504:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_650A:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_6510:
	db $00, $00, $00, $8a, $07, $02
Sfx1_78_Data_6516:
	db $08, $00, $32, $8a, $87, $02
Sfx1_78_Data_651C:
	db $00, $00, $00, $59, $07, $02
Sfx1_78_Data_6522:
	db $00, $00, $00, $39, $07, $02
Sfx1_78_Data_6528:
	db $00, $00, $00, $8a, $07, $02
Sfx2_06_Init:
	jp Sfx2_Stop

Sfx2_06_Play:
	ret

Sfx2_17_Init:
	jp Sfx2_Refuse

Sfx2_17_Play:
	ret

Sfx2_38_Init:
	ld hl, Sfx2_38_Data_6545
	jp Sfx2_StartSweep

Sfx2_38_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	jp Sfx2_Stop

Sfx2_38_Data_6545:
	db $1c, $80, $e4, $6b, $87, $28
Sfx2_36_Init:
	ld a, $0d
	ld [wSfx4Request], a
	ld a, $05
	ld [wSfx2Counter], a
	ld hl, Sfx2_36_Data_6589
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_36_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx2_36_Data_657D
	jp Sfx2_AddPitch

.l0:
	call Sfx2_DecCounter
	jp z, Sfx2_Release
	ld a, $01
	ld [bc], a
	jr .l1

Sfx2_36_Data_657D:
	db $ff, $c0
	db $ff, $80
	db $ff, $40
	db $00, $c0
	db $00, $80
	db $00, $40
Sfx2_36_Data_6589:
	db $80, $f4, $83, $84, $01
Sfx2_32_Init:
	ld hl, Sfx2_32_Data_659D
	jp Sfx2_StartSweep

Sfx2_32_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	jp Sfx2_Stop

Sfx2_32_Data_659D:
	db $1a, $80, $f1, $11, $85, $05
Sfx2_33_Init:
	ld hl, Sfx2_33_Data_65B2
	jp Sfx2_StartSweep

Sfx2_33_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	jp Sfx2_Stop

Sfx2_33_Data_65B2:
	db $1a, $80, $f1, $89, $85, $05
Sfx2_34_Init:
	ld a, $27
	ld [wSfx4Request], a
	ld hl, Sfx2_34_Data_65CC
	jp Sfx2_StartSweep

Sfx2_34_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	jp Sfx2_Stop

Sfx2_34_Data_65CC:
	db $1a, $80, $f1, $72, $86, $05
Sfx2_35_Init:
	ld a, $27
	ld [wSfx4Request], a
	ld hl, Sfx2_35_Data_65E6
	jp Sfx2_StartSweep

Sfx2_35_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	jp Sfx2_Stop

Sfx2_35_Data_65E6:
	db $1a, $80, $f1, $d6, $86, $05
Sfx2_31_Init:
	ld hl, Sfx2_01_Data_6204
	jp Sfx2_Start

Sfx2_31_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx2_Stop
	ld hl, Sfx2_01_Data_61F2
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2F_Init:
	ld hl, Sfx2_2F_Data_662C
	jp Sfx2_Start

Sfx2_2F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx2_Release
	ld hl, Sfx2_2F_Data_6622
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2F_Data_6622:
	dw Sfx2_2F_Data_6631, Sfx2_2F_Data_6636, Sfx2_2F_Data_663B, Sfx2_2F_Data_6640, Sfx2_2F_Data_6645
Sfx2_2F_Data_662C:
	db $80, $a3, $9d, $87, $05
Sfx2_2F_Data_6631:
	db $80, $a3, $83, $87, $0c
Sfx2_2F_Data_6636:
	db $80, $63, $9d, $87, $05
Sfx2_2F_Data_663B:
	db $80, $63, $83, $87, $0c
Sfx2_2F_Data_6640:
	db $80, $43, $9d, $87, $05
Sfx2_2F_Data_6645:
	db $80, $43, $83, $87, $0c
Sfx1_2F_Init:
	ld a, [wSfx1Playing]
	cp $2f
	jp z, Sfx1_Refuse
	ld hl, Sfx1_2F_Data_666C
	jp Sfx1_StartSweep

Sfx1_2F_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_2F_Data_6672
	jp Sfx1_SweepStart

Sfx1_2F_Data_666C:
	db $1c, $00, $98, $0a, $86, $04
Sfx1_2F_Data_6672:
	db $14, $00, $98, $0a, $86, $04
Sfx1_30_Init:
	ld a, [wSfx1Playing]
	cp $30
	jp z, Sfx1_Refuse
	ld hl, Sfx1_30_Data_669A
	jp Sfx1_StartSweep

Sfx1_30_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_30_Data_66A0
	jp Sfx1_SweepStart

Sfx1_30_Data_669A:
	db $1c, $00, $98, $0a, $86, $04
Sfx1_30_Data_66A0:
	db $14, $00, $98, $0a, $86, $04
Sfx2_2B_Init:
	ld hl, Sfx2_2B_Data_66CB
	jp Sfx2_Start

Sfx2_2B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx2_Stop
	ld hl, Sfx2_2B_Data_66C1
	call GetPointer
	jp SetRegs_Ch2

Sfx2_2B_Data_66C1:
	dw Sfx2_2B_Data_66D0, Sfx2_2B_Data_66D5, Sfx2_2B_Data_66DA, Sfx2_2B_Data_66DF, Sfx2_2B_Data_66E4
Sfx2_2B_Data_66CB:
	db $00, $98, $83, $87, $03
Sfx2_2B_Data_66D0:
	db $40, $88, $9d, $87, $03
Sfx2_2B_Data_66D5:
	db $80, $78, $ac, $87, $03
Sfx2_2B_Data_66DA:
	db $80, $68, $9d, $87, $03
Sfx2_2B_Data_66DF:
	db $80, $48, $ac, $87, $03
Sfx2_2B_Data_66E4:
	db $80, $38, $c1, $87, $03
Sfx2_2A_Init:
	ld a, [wSfx2Playing]
	cp $2a
	jr nz, .l0
	jp Sfx2_Continue

.l0:
	ld hl, Sfx2_2A_Data_6702
	jp Sfx2_Start

Sfx2_2A_Play:
	ld a, [wSfx2Request]
	cp $2a
	jp nz, Sfx2_Stop
	ret

Sfx2_2A_Data_6702:
	db $40, $08, $4f, $87, $01
Sfx2_28_Init:
	ld a, [wSfx2Playing]
	cp $28
	jp z, Sfx2_Refuse
	ld a, $0a
	ld [wSfx2Counter], a
	ld hl, Sfx2_28_Data_675C
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_28_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx2_28_Data_674A
	jp Sfx2_AddPitch

.l0:
	call Sfx2_DecCounter
	jp z, Sfx2_Stop
	cp $07
	jr z, .l2
	jr .l3

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx2_28_Data_6761
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

Sfx2_28_Data_674A:
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $ff, $ff
	db $00, $06
Sfx2_28_Data_675C:
	db $00, $1f, $d8, $87, $01
Sfx2_28_Data_6761:
	db $00, $a7, $d0, $87, $01
Sfx2_27_Init:
	ld hl, Sfx2_27_Data_6797
	jp Sfx2_Start

Sfx2_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx2_Stop
	ld hl, Sfx2_27_Data_6781
	call GetPointer
	jp SetRegs_Ch2

Sfx2_27_Data_6781:
	dw Sfx2_27_Data_679C, Sfx2_27_Data_67A1, Sfx2_27_Data_67A6, Sfx2_27_Data_67AB, Sfx2_27_Data_67B0, Sfx2_27_Data_67B5, Sfx2_27_Data_67BA, Sfx2_27_Data_67BF, Sfx2_27_Data_67C4, Sfx2_27_Data_67C9, Sfx2_27_Data_67CE
Sfx2_27_Data_6797:
	db $80, $18, $3f, $87, $01
Sfx2_27_Data_679C:
	db $80, $08, $48, $87, $01
Sfx2_27_Data_67A1:
	db $80, $28, $51, $87, $01
Sfx2_27_Data_67A6:
	db $80, $08, $5a, $87, $01
Sfx2_27_Data_67AB:
	db $80, $38, $68, $87, $01
Sfx2_27_Data_67B0:
	db $80, $18, $76, $87, $01
Sfx2_27_Data_67B5:
	db $80, $58, $84, $87, $01
Sfx2_27_Data_67BA:
	db $80, $28, $92, $87, $01
Sfx2_27_Data_67BF:
	db $80, $68, $a4, $87, $01
Sfx2_27_Data_67C4:
	db $80, $38, $ac, $87, $01
Sfx2_27_Data_67C9:
	db $80, $88, $b4, $87, $01
Sfx2_27_Data_67CE:
	db $80, $58, $c6, $87, $01
Sfx2_22_Init:
	ld a, [wSfx2Playing]
	cp $22
	jp z, Sfx2_Refuse
	ld hl, Sfx2_22_Data_67FE
	jp Sfx2_Start

Sfx2_22_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx2_Stop
	ld hl, Sfx2_22_Data_67F6
	call GetPointer
	jp SetRegs_Ch2

Sfx2_22_Data_67F6:
	dw Sfx2_22_Data_6803, Sfx2_22_Data_6808, Sfx2_22_Data_680D, Sfx2_22_Data_6812
Sfx2_22_Data_67FE:
	db $80, $44, $83, $87, $01
Sfx2_22_Data_6803:
	db $80, $44, $6b, $87, $01
Sfx2_22_Data_6808:
	db $80, $44, $74, $87, $01
Sfx2_22_Data_680D:
	db $80, $44, $ac, $87, $01
Sfx2_22_Data_6812:
	db $80, $44, $b6, $87, $01
Sfx2_23_Init:
	ld a, [wSfx2Playing]
	cp $23
	jr nz, .l0
	jp Sfx2_Continue

.l0:
	ld a, $0a
	ld [wSfx2Counter], a
	ld hl, Sfx2_23_Data_687A
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_23_Play:
	ld a, [wSfx2Request]
	cp $23
	jp nz, Sfx2_Stop
	call Sfx_IncStep
	cp $03
	jr z, .l1
	cp $04
	jr z, .l2
.l3:
	ld hl, Sfx2_23_Data_6874
	jp Sfx2_AddPitch

.l2:
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	call Sfx2_DecCounter
	jp z, .l4
	cp $06
	jr z, .l5
	jr .l3

.l5:
	xor a
	ld [bc], a
	ld hl, Sfx2_23_Data_687F
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

.l4:
	ld a, $0a
	ld [wSfx2Counter], a
	xor a
	ld [bc], a
	ld hl, Sfx2_23_Data_687A
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx2_23_Data_6874:
	db $00, $c0
	db $00, $60
	db $fe, $e0
Sfx2_23_Data_687A:
	db $80, $39, $00, $85, $01
Sfx2_23_Data_687F:
	db $80, $a6, $00, $85, $01
Sfx2_25_Init:
	ld a, [wSfx2Playing]
	cp $25
	jr nz, .l0
	jp Sfx2_Continue

.l0:
	ld a, $0a
	ld [wSfx2Counter], a
	ld hl, Sfx2_25_Data_68EB
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_25_Play:
	ld a, [wSfx2Request]
	cp $25
	jp nz, Sfx2_Stop
	call Sfx_IncStep
	cp $05
	jr z, .l1
	cp $06
	jr z, .l2
.l3:
	ld hl, Sfx2_25_Data_68E1
	jp Sfx2_AddPitch

.l2:
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	call Sfx2_DecCounter
	jp z, .l4
	cp $03
	jr z, .l5
	jr .l3

.l5:
	xor a
	ld [bc], a
	ld hl, Sfx2_25_Data_68F0
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

.l4:
	ld a, $0a
	ld [wSfx2Counter], a
	xor a
	ld [bc], a
	ld hl, Sfx2_25_Data_68EB
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx2_25_Data_68E1:
	db $00, $10
	db $00, $30
	db $00, $50
	db $ff, $80
	db $ff, $f0
Sfx2_25_Data_68EB:
	db $80, $2f, $00, $86, $01
Sfx2_25_Data_68F0:
	db $80, $76, $00, $86, $01
Sfx2_10_Init:
	ld a, $0c
	ld [wSfx4Request], a
	ld hl, Sfx2_10_Data_4E43
	ld a, [hl-]
	and $07
	ld de, wSfx2Pitch+1
	ld [de], a
	ld a, [hl-]
	dec e
	ld [de], a
	dec hl
	jp Sfx2_Start

Sfx2_10_Play:
	call Sfx_DecTimer
	jr z, Sfx2_10_Shared_6936
	ld a, [wSfx2Playing]
	cp $18
	ret c
	ld hl, wSfx2Pitch
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, $ff
	sub l
	ld e, a
	ld a, $07
	sbc a, h
	ld d, a
	srl d
	rr e
	add hl, de
	ld de, wSfx2Pitch+1
	ld a, h
	ld [de], a
	ldh [rNR24], a
	dec e
	ld a, l
	ld [de], a
	ldh [rNR23], a
	ret

Sfx2_10_Shared_6936:
	call Sfx_IncStep
	cp $14
	jp z, Sfx2_Stop
	ld hl, Sfx2_08_Data_4D55
	call GetPointer
	ld a, [wSfx2Playing]
	cp $18
	jr nc, Sfx2_10_Shared_6956
	ld a, $80
	ld b, $00
	ld de, $ffe8
	ld c, $04
	jr Sfx2_10_Shared_695F

Sfx2_10_Shared_6956:
	ld a, $40
	ld b, $20
	ld de, $ffde
	ld c, $03
Sfx2_10_Shared_695F:
	ldh [rNR21], a
	inc hl
	inc hl
	ld a, [hl+]
	add a, b
	jr nc, Sfx2_10_Shared_6969
	ld a, $f8
Sfx2_10_Shared_6969:
	ldh [rNR22], a
	ld a, [wSfx2Playing]
	add a, e
	ld e, a
	ld a, $00
	adc a, d
	ld d, a
Sfx2_10_Shared_6974:
	sla e
	rl d
	dec c
	jr nz, Sfx2_10_Shared_6974
	ld a, e
	add a, [hl]
	ld e, a
	inc hl
	ld a, d
	adc a, [hl]
	and $07
	ld d, a
	inc hl
	ld a, [hl]
	ld [wSfx2Timer], a
	ld hl, wSfx2Pitch
	ld a, e
	ld [hl+], a
	ldh [rNR23], a
	ld a, d
	ld [hl], a
	or $80
	ldh [rNR24], a
	ret

Sfx2_20_Init:
	ld hl, Sfx2_20_Data_69C2
	jp Sfx2_Start

Sfx2_20_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx2_Stop
	ld hl, Sfx2_20_Data_69B2
	call GetPointer
	jp SetRegs_Ch2

Sfx2_20_Data_69B2:
	dw Sfx2_20_Data_69C7, Sfx2_20_Data_69CC, Sfx2_20_Data_69D1, Sfx2_20_Data_69C7, Sfx2_20_Data_69CC, Sfx2_20_Data_69D1, Sfx2_20_Data_69D6, Sfx2_20_Data_69DB
Sfx2_20_Data_69C2:
	db $80, $71, $ac, $87, $02
Sfx2_20_Data_69C7:
	db $80, $81, $be, $87, $03
Sfx2_20_Data_69CC:
	db $80, $91, $c8, $87, $03
Sfx2_20_Data_69D1:
	db $80, $b1, $d1, $87, $04
Sfx2_20_Data_69D6:
	db $80, $d1, $db, $87, $08
Sfx2_20_Data_69DB:
	db $80, $c1, $d6, $87, $0a
Sfx2_0D_Init:
	ld hl, Sfx2_0D_Data_69FA
	jp Sfx2_StartSweep

Sfx2_0D_Play:
	call Sfx_DecTimer
	jp nz, Sfx2_Sweep
	call Sfx_IncStep
	cp $02
	jp z, Sfx2_Stop
	ld hl, Sfx2_0D_Data_6A00
	jp Sfx2_SweepStart

Sfx2_0D_Data_69FA:
	db $1c, $80, $c0, $7b, $87, $1e
Sfx2_0D_Data_6A00:
	db $1c, $80, $30, $7b, $87, $14
Sfx2_0E_Init:
	ld a, [wSfx2Playing]
	cp $0e
	jr nz, .l0
	jp Sfx2_Continue

.l0:
	ld hl, $ded6
	ld a, $07
	ld [hl+], a
	ld a, $06
	ld [hl+], a
	xor a
	ld [hl], a
	ld hl, Sfx2_0E_Data_6A21
	jp Sfx2_Start

Sfx2_0E_Data_6A21:
	db $40, $08, $06, $87, $01
Sfx2_0E_Play:
	ld a, [wSfx2Request]
	cp $0e
	jp nz, Sfx2_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp nz, .l1
	xor a
	ld [bc], a
.l1:
	ld hl, $de8d
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, b
	cp $fd
	jr nz, .l2
	ld b, $07
	ld d, $d0
	jp .l3

.l2:
	cp $fe
	jr nz, .l4
	ld b, $05
	ld d, $a2
	jp .l3

.l4:
	cp $ff
	jr nz, .l5
	ld b, $03
	ld d, $59
	jr .l3

.l5:
	cp $02
	jr nz, .l6
	ld b, $07
	ld de, $070a
	jr .l7

.l6:
	cp $01
	jr nz, .l8
	ld b, $05
	ld de, $0789
	jr .l7

.l8:
	cp $00
	jr nz, .l9
	ld a, c
	cp $00
	jr z, .l9
	ld b, $03
	ld de, $07d6
	jr .l7

.l9:
	ld a, $08
	ld c, $17
	ldh [c], a
	ld hl, $ded6
	ld a, $07
	ld [hl+], a
	ld a, $06
	ld [hl+], a
	xor a
	ld [hl], a
	jr .l10

.l7:
	ld hl, $ded8
	ld a, [hl]
	cp b
	jr nc, .l11
	inc a
	jr .l12

.l11:
	ld a, b
.l12:
	ld [hl], a
	swap a
	or $05
	ld c, $17
	ldh [c], a
	ld hl, $ded6
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, b
	cp d
	jr nc, .l13
	ld a, c
	cp e
	jr nc, .l13
	dec d
	ld h, d
	ld l, e
	jr .l10

.l13:
	dec bc
	dec bc
	ld hl, $ded6
	ld [hl], b
	inc hl
	ld [hl], c
	ld h, b
	ld l, c
	jr .l10

.l3:
	ld hl, $ded8
	ld a, [hl]
	cp b
	jr nc, .l14
	inc a
	jr .l15

.l14:
	ld a, b
.l15:
	ld [hl], a
	swap a
	or $05
	ld c, $17
	ldh [c], a
	ld hl, $ded6
	ld b, [hl]
	inc hl
	ld c, [hl]
	ld a, b
	cp $07
	jr c, .l16
	ld a, c
	cp d
	jr c, .l16
	ld h, b
	ld l, d
	jr .l10

.l16:
	inc bc
	inc bc
	ld hl, $ded6
	ld [hl], b
	inc hl
	ld [hl], c
	ld h, b
	ld l, c
.l10:
	ld de, wSfx2Step
	ld a, [de]
	and $03
	jr nz, .l17
	ld bc, $0000
	jr .l18

.l17:
	cp $01
	jr nz, .l19
	ld bc, $001b
	jr .l18

.l19:
	cp $02
	jr nz, .l20
	ld bc, $0033
	jr .l18

.l20:
	ld bc, $001b
.l18:
	add hl, bc
	ld c, $18
	ld a, l
	ldh [c], a
	inc c
	ld a, h
	or $80
	ldh [c], a
	ld a, $02
	ld hl, wSfx2Timer
	ld [hl], a
	ret

Sfx2_0C_Init:
	ld hl, Sfx2_0C_Data_6B59
	jp Sfx2_Start

Sfx2_0C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx2_Stop
	ld hl, Sfx2_0C_Data_6B4B
	call GetPointer
	jp SetRegs_Ch2

Sfx2_0C_Data_6B4B:
	dw Sfx2_0C_Data_6B5E, Sfx2_0C_Data_6B63, Sfx2_0C_Data_6B68, Sfx2_0C_Data_6B6D, Sfx2_0C_Data_6B72, Sfx2_0C_Data_6B77, Sfx2_0C_Data_6B7C
Sfx2_0C_Data_6B59:
	db $00, $f8, $d6, $86, $01
Sfx2_0C_Data_6B5E:
	db $00, $f8, $e7, $86, $01
Sfx2_0C_Data_6B63:
	db $00, $f8, $c4, $86, $01
Sfx2_0C_Data_6B68:
	db $00, $08, $ce, $87, $01
Sfx2_0C_Data_6B6D:
	db $00, $f8, $44, $87, $01
Sfx2_0C_Data_6B72:
	db $00, $f8, $59, $87, $01
Sfx2_0C_Data_6B77:
	db $00, $f8, $4f, $87, $01
Sfx2_0C_Data_6B7C:
	db $00, $f8, $62, $87, $01
Sfx2_0F_Init:
	ld a, [wSfx2Playing]
	cp $0f
	jr nz, .l0
	jp Sfx2_Continue

.l0:
	ld hl, Sfx2_0F_Data_6BB9
	jp Sfx2_Start

Sfx2_0F_Play:
	ld a, [wSfx2Request]
	cp $0f
	jp nz, Sfx2_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp c, .l1
	ld a, $01
	ld [bc], a
.l1:
	ld hl, Sfx2_0F_Data_6BB1
	call GetPointer
	jp SetRegs_Ch2

Sfx2_0F_Data_6BB1:
	dw Sfx2_0F_Data_6BBE, Sfx2_0F_Data_6BC3, Sfx2_0F_Data_6BC8, Sfx2_0F_Data_6BB9
Sfx2_0F_Data_6BB9:
	db $40, $48, $06, $87, $02
Sfx2_0F_Data_6BBE:
	db $40, $48, $21, $87, $02
Sfx2_0F_Data_6BC3:
	db $40, $48, $39, $87, $02
Sfx2_0F_Data_6BC8:
	db $40, $48, $21, $87, $02
Sfx2_0B_Init:
	ld hl, Sfx2_0B_Data_6BE5
	jp Sfx2_Start

Sfx2_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx2_Stop
	ld hl, Sfx2_0B_Data_6BEA
	jp SetRegs_Ch2

Sfx2_0B_Data_6BE5:
	db $80, $a0, $e5, $84, $03
Sfx2_0B_Data_6BEA:
	db $80, $50, $e5, $84, $03
Sfx2_0A_Init:
	ld a, [wSfx2Playing]
	cp $0a
	jp nz, .l0
	jp Sfx2_Continue

.l0:
	ld a, $04
	ld [wSfx2Counter], a
	ld hl, Sfx2_0A_Data_6C57
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_0A_Play:
	ld a, [wSfx2Request]
	cp $0a
	jp nz, Sfx2_Stop
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $09
	jr z, .l1
	cp $0a
	jr z, .l2
.l4:
	ld hl, Sfx2_0A_Data_6C45
	jp Sfx2_AddPitch

.l1:
	call Sfx2_DecCounter
	jp z, Sfx2_Stop
	cp $02
	jr z, .l3
	ld a, [bc]
	jr .l4

.l2:
	ld a, $01
	ld [bc], a
	jr .l4

.l3:
	xor a
	ld [bc], a
	ld hl, Sfx2_0A_Data_6C5C
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx2_0A_Data_6C45:
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $08
	db $00, $08
	db $00, $04
	db $00, $02
	db $ff, $aa
Sfx2_0A_Data_6C57:
	db $80, $5e, $89, $86, $02
Sfx2_0A_Data_6C5C:
	db $80, $c6, $89, $86, $02
Sfx2_07_Init:
	ld hl, Sfx2_07_Data_4E40
	jp Sfx2_Start

Sfx2_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx2_Stop
	ld hl, Sfx1_4C_Data_4D4D
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx2_08_Init:
	ld a, $0c
	ld [wSfx4Request], a
	ld hl, Sfx2_07_Data_4E40
	jp Sfx2_Start

Sfx2_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jp z, Sfx2_Stop
	ld hl, Sfx2_08_Data_4D55
	call GetPointer
	inc hl
	jp SetRegs_Ch2

Sfx4_0C_Init:
	ld hl, Sfx4_0C_Data_6CB6
	jp Sfx4_Start

Sfx4_0C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_0C_Data_6CBB
	jp SetRegs_Ch4

Sfx4_0C_Data_6CB6:
	db $00, $f1, $17, $80, $04
Sfx4_0C_Data_6CBB:
	db $00, $52, $17, $80, $14
Sfx2_30_Init:
	ld hl, Sfx2_30_Data_6CEE
	jp Sfx2_Start

Sfx2_30_Play:
	call Sfx_DecTimer
	jr nz, .l0
	call Sfx_IncStep
	cp $03
	jp z, Sfx2_Stop
	ld hl, Sfx2_30_Data_6CEA
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

Sfx2_30_Data_6CEA:
	dw Sfx2_30_Data_6CF3, Sfx2_30_Data_6CF8
Sfx2_30_Data_6CEE:
	db $00, $ff, $12, $83, $06
Sfx2_30_Data_6CF3:
	db $00, $11, $12, $83, $03
Sfx2_30_Data_6CF8:
	db $00, $ff, $12, $83, $14
Sfx2_37_Init:
	ld hl, Sfx2_37_Data_6D4D
	jp Sfx2_Start

Sfx2_37_Play:
	call Sfx_DecTimer
	jp z, Sfx2_Release
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
	ld hl, Sfx2_37_Data_6D49
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

Sfx2_37_Data_6D49:
	db $b6, $07, $be, $07
Sfx2_37_Data_6D4D:
	db $40, $c8, $b6, $87, $2c
Sfx3_03_Init:
	jp Sfx3_Stop

Sfx3_03_Play:
	ret

Sfx3_06_Init:
	jp Sfx3_Refuse

Sfx3_06_Play:
	ret

Sfx3_08_Init:
	ld a, [wSfx3Playing]
	cp $08
	jr nz, .l0
	jp Sfx3_Continue

.l0:
	ld hl, Sfx3_08_Data_6D73
	jp Sfx3_Start

Sfx3_08_Play:
	ld a, [wSfx3Request]
	cp $08
	jp nz, Sfx3_Stop
	ret

Sfx3_08_Data_6D73:
	db $80, $00, $00, $d6, $87, $01
Sfx3_07_Init:
	ld a, $0a
	ld [wSfx3Counter], a
	ld hl, Sfx3_07_Data_6F2D
	call Sfx3_LoadWave
	ld hl, Sfx3_07_Data_6DC2
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_07_Play:
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l2:
	ld a, [wSfx3Counter]
	cp $03
	jr nc, .l1
	ld hl, Sfx3_07_Data_6DBA
	jp Sfx3_AddPitch

.l1:
	ld hl, Sfx3_07_Data_6DB2
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	ld a, $01
	ld [bc], a
	jr .l2

Sfx3_07_Data_6DB2:
	db $00, $30
	db $ff, $d4
	db $00, $30
	db $ff, $d4
Sfx3_07_Data_6DBA:
	db $00, $20
	db $ff, $e4
	db $00, $20
	db $ff, $e4
Sfx3_07_Data_6DC2:
	db $80, $00, $20, $7b, $87, $01
Sfx3_01_Init:
	ld a, [wSfx3Playing]
	cp $01
	jr nz, .l0
	jp Sfx3_Continue

.l0:
	ld hl, Sfx3_01_Data_6EDD
	call Sfx3_LoadWave
	ld hl, Sfx3_01_Data_6E11
	jp Sfx3_Start

Sfx3_01_Play:
	ld a, [wSfx3Request]
	cp $01
	jp nz, Sfx3_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp nz, .l1
	xor a
	ld [bc], a
	ld hl, Sfx3_01_Data_6E11
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_01_Data_6E03
	call GetPointer
	jp SetRegs_Ch3

Sfx3_01_Data_6E03:
	dw Sfx3_01_Data_6E17, Sfx3_01_Data_6E1D, Sfx3_01_Data_6E23, Sfx3_01_Data_6E29, Sfx3_01_Data_6E2F, Sfx3_01_Data_6E35, Sfx3_01_Data_6E3B
Sfx3_01_Data_6E11:
	db $80, $00, $40, $d6, $87, $05
Sfx3_01_Data_6E17:
	db $80, $00, $40, $c8, $87, $0a
Sfx3_01_Data_6E1D:
	db $80, $00, $40, $c1, $87, $05
Sfx3_01_Data_6E23:
	db $80, $00, $40, $ac, $87, $0a
Sfx3_01_Data_6E29:
	db $80, $00, $40, $d6, $87, $05
Sfx3_01_Data_6E2F:
	db $80, $00, $40, $c8, $87, $0a
Sfx3_01_Data_6E35:
	db $80, $00, $40, $be, $87, $05
Sfx3_01_Data_6E3B:
	db $80, $00, $40, $ac, $87, $0a
Sfx3_02_Init:
	ld a, [wSfx3Playing]
	cp $02
	jr nz, .l0
	jp Sfx3_Continue

.l0:
	ld hl, Sfx3_01_Data_6EDD
	call Sfx3_LoadWave
	ld hl, Sfx3_02_Data_6E8A
	jp Sfx3_Start

Sfx3_02_Play:
	ld a, [wSfx3Request]
	cp $02
	jp nz, Sfx3_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp nz, .l1
	xor a
	ld [bc], a
	ld hl, Sfx3_02_Data_6E8A
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_02_Data_6E7C
	call GetPointer
	jp SetRegs_Ch3

Sfx3_02_Data_6E7C:
	dw Sfx3_02_Data_6E90, Sfx3_02_Data_6E96, Sfx3_02_Data_6E9C, Sfx3_02_Data_6EA2, Sfx3_02_Data_6EA8, Sfx3_02_Data_6EAE, Sfx3_02_Data_6EB4
Sfx3_02_Data_6E8A:
	db $80, $00, $40, $d6, $87, $04
Sfx3_02_Data_6E90:
	db $80, $00, $40, $c8, $87, $02
Sfx3_02_Data_6E96:
	db $80, $00, $40, $c1, $87, $04
Sfx3_02_Data_6E9C:
	db $80, $00, $40, $ac, $87, $02
Sfx3_02_Data_6EA2:
	db $80, $00, $40, $d6, $87, $04
Sfx3_02_Data_6EA8:
	db $80, $00, $40, $c8, $87, $02
Sfx3_02_Data_6EAE:
	db $80, $00, $40, $be, $87, $04
Sfx3_02_Data_6EB4:
	db $80, $00, $40, $ac, $87, $02
Sfx3_05_Init:
	ld hl, Sfx3_05_Data_6EC7
	jp Sfx3_Start

Sfx3_05_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx3_Stop

Sfx3_05_Data_6EC7:
	db $80, $00, $00, $d6, $87, $44
	db $22, $66, $aa, $ee, $ff, $ff
	db $fe, $ea, $a6, $66, $8a, $cf
	db $fe, $ec, $a6, $33
Sfx3_01_Data_6EDD:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
	db $13, $57, $9b, $df, $db, $97, $53, $10, $13, $57, $9b, $df, $db, $97, $53, $10
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
	db $f0, $e1, $d2, $c3, $b4, $a5, $96, $87, $78, $69, $5a, $4b, $3c, $2d, $1e, $0f
	db $bb, $bb, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Sfx3_07_Data_6F2D:
	db $99, $99, $99, $99, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Sfx4_05_Init:
	jp Sfx4_Stop

Sfx4_05_Play:
	ret

Sfx4_20_Init:
	jp Sfx4_Refuse

Sfx4_20_Play:
	ret

Sfx4_24_Init:
	ld a, [wSfx4Playing]
	cp $24
	jr nz, .l0
	jp Sfx4_Continue

.l0:
	ld hl, Sfx4_24_Data_6F5E
	jp Sfx4_Start

Sfx4_24_Play:
	ld a, [wSfx4Request]
	cp $24
	jp nz, Sfx4_Stop
	ret

Sfx4_24_Data_6F5E:
	db $00, $08, $15, $80, $01
Sfx4_28_Init:
	ld hl, Sfx4_28_Data_6F70
	jp Sfx4_Start

Sfx4_28_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_28_Data_6F70:
	db $00, $08, $05, $80, $44
Sfx4_21_Init:
	ld hl, Sfx4_21_Data_6F96
	jp Sfx4_Start

Sfx4_21_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Release
	ld hl, Sfx4_21_Data_6F90
	call GetPointer
	jp SetRegs_Ch4

Sfx4_21_Data_6F90:
	dw Sfx4_21_Data_6F9B, Sfx4_21_Data_6FA0, Sfx4_21_Data_6FA5
Sfx4_21_Data_6F96:
	db $00, $92, $05, $80, $03
Sfx4_21_Data_6F9B:
	db $00, $01, $17, $80, $02
Sfx4_21_Data_6FA0:
	db $00, $82, $15, $80, $01
Sfx4_21_Data_6FA5:
	db $00, $75, $34, $80, $10
Sfx4_1E_Init:
	ld hl, Sfx4_1E_Data_6FD7
	jp Sfx4_Start

Sfx4_1E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx4_Stop
	ld hl, Sfx4_1E_Data_6FC5
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_1E_Data_6FC5:
	dw Sfx4_1E_Data_6FDC, Sfx4_1E_Data_6FD7, Sfx4_1E_Data_6FDC, Sfx4_1E_Data_6FE1, Sfx4_1E_Data_6FE6, Sfx4_1E_Data_6FEB, Sfx4_1E_Data_6FF0, Sfx4_1E_Data_6FEB, Sfx4_1E_Data_6FF0
Sfx4_1E_Data_6FD7:
	db $00, $e1, $34, $80, $02
Sfx4_1E_Data_6FDC:
	db $00, $e1, $24, $80, $02
Sfx4_1E_Data_6FE1:
	db $00, $d1, $08, $80, $02
Sfx4_1E_Data_6FE6:
	db $00, $d1, $08, $80, $02
Sfx4_1E_Data_6FEB:
	db $00, $00, $09, $00, $02
Sfx4_1E_Data_6FF0:
	db $00, $00, $08, $00, $02
Sfx4_1A_Init:
	ld a, [wSfx4Playing]
	cp $1a
	jp nz, .l0
	jp Sfx4_Continue

.l0:
	ld hl, Sfx4_1A_Data_702A
	jp Sfx4_Start

Sfx4_1A_Play:
	ld a, [wSfx4Request]
	cp $1a
	jp nz, Sfx4_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp nz, .l1
	ld a, $01
	ld [bc], a
.l1:
	ld hl, Sfx4_1A_Data_7026
	call GetPointer
	jp SetRegs_Ch4

Sfx4_1A_Data_7026:
	dw Sfx4_1A_Data_702F, Sfx4_1A_Data_7034
Sfx4_1A_Data_702A:
	db $00, $28, $26, $80, $05
Sfx4_1A_Data_702F:
	db $00, $48, $34, $80, $06
Sfx4_1A_Data_7034:
	db $00, $38, $36, $80, $06
Sfx4_1B_Init:
	ld a, [wSfx4Playing]
	cp $1b
	jp nz, .l0
	jp Sfx4_Continue

.l0:
	ld hl, Sfx4_1B_Data_706E
	jp Sfx4_Start

Sfx4_1B_Play:
	ld a, [wSfx4Request]
	cp $1b
	jp nz, Sfx4_Stop
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp nz, .l1
	ld a, $01
	ld [bc], a
.l1:
	ld hl, Sfx4_1B_Data_706A
	call GetPointer
	jp SetRegs_Ch4

Sfx4_1B_Data_706A:
	dw Sfx4_1B_Data_7073, Sfx4_1B_Data_7078
Sfx4_1B_Data_706E:
	db $00, $28, $24, $80, $05
Sfx4_1B_Data_7073:
	db $00, $48, $34, $80, $03
Sfx4_1B_Data_7078:
	db $00, $38, $25, $80, $03
Sfx4_0A_Init:
	ld hl, Sfx4_0A_Data_70DA
	jp Sfx4_Start

Sfx4_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jr z, Sfx4_0A_Shared_7096
	cp $1b
	jp nz, Sfx4_0A_Shared_709D
	jp Sfx4_Stop

Sfx4_0A_Shared_7096:
	ld b, a
	ld a, $30
	ld [wSfx4Priority], a
	ld a, b
Sfx4_0A_Shared_709D:
	ld hl, Sfx4_0A_Data_70A6
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_0A_Data_70A6:
	dw Sfx4_0A_Data_70DF, Sfx4_0A_Data_70E4, Sfx4_0A_Data_70E9, Sfx4_0A_Data_70EE, Sfx4_0A_Data_70F3, Sfx4_0A_Data_70F8, Sfx4_0A_Data_70FD, Sfx4_0A_Data_7102, Sfx4_0A_Data_7107, Sfx4_0A_Data_710C, Sfx4_0A_Data_7111, Sfx4_0A_Data_7116, Sfx4_0A_Data_711B, Sfx4_0A_Data_7120, Sfx4_0A_Data_7125, Sfx4_0A_Data_712A, Sfx4_0A_Data_712F, Sfx4_0A_Data_7134, Sfx4_0A_Data_7139, Sfx4_0A_Data_713E, Sfx4_0A_Data_7143, Sfx4_0A_Data_7148, Sfx4_0A_Data_714D, Sfx4_0A_Data_7152, Sfx4_0A_Data_7157, Sfx4_0A_Data_715C
Sfx4_0A_Data_70DA:
	db $00, $d8, $43, $80, $01
Sfx4_0A_Data_70DF:
	db $00, $00, $30, $00, $01
Sfx4_0A_Data_70E4:
	db $00, $88, $50, $80, $01
Sfx4_0A_Data_70E9:
	db $00, $d8, $43, $80, $01
Sfx4_0A_Data_70EE:
	db $00, $00, $50, $00, $01
Sfx4_0A_Data_70F3:
	db $00, $00, $30, $00, $01
Sfx4_0A_Data_70F8:
	db $00, $08, $43, $80, $01
Sfx4_0A_Data_70FD:
	db $00, $a8, $10, $80, $01
Sfx4_0A_Data_7102:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7107:
	db $00, $98, $10, $80, $01
Sfx4_0A_Data_710C:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7111:
	db $00, $88, $10, $80, $01
Sfx4_0A_Data_7116:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_711B:
	db $00, $78, $10, $80, $01
Sfx4_0A_Data_7120:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7125:
	db $00, $68, $10, $80, $01
Sfx4_0A_Data_712A:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_712F:
	db $00, $58, $10, $80, $01
Sfx4_0A_Data_7134:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7139:
	db $00, $48, $10, $80, $01
Sfx4_0A_Data_713E:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7143:
	db $00, $38, $10, $80, $01
Sfx4_0A_Data_7148:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_714D:
	db $00, $28, $10, $80, $01
Sfx4_0A_Data_7152:
	db $00, $00, $00, $00, $02
Sfx4_0A_Data_7157:
	db $00, $18, $10, $80, $01
Sfx4_0A_Data_715C:
	db $00, $00, $00, $00, $02
Sfx4_09_Init:
	ld hl, Sfx4_09_Data_7192
	jp Sfx4_Start

Sfx4_09_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx4_Stop
	ld hl, Sfx4_09_Data_717C
	call GetPointer
	jp SetRegsPartial_Ch4

Sfx4_09_Data_717C:
	dw Sfx4_09_Data_7197, Sfx4_09_Data_719C, Sfx4_09_Data_71A1, Sfx4_09_Data_71A6, Sfx4_09_Data_71AB, Sfx4_09_Data_71B0, Sfx4_09_Data_71B5, Sfx4_09_Data_71BA, Sfx4_09_Data_71BF, Sfx4_09_Data_71C4, Sfx4_09_Data_71C9
Sfx4_09_Data_7192:
	db $00, $b8, $07, $80, $01
Sfx4_09_Data_7197:
	db $00, $00, $23, $00, $01
Sfx4_09_Data_719C:
	db $00, $00, $50, $00, $01
Sfx4_09_Data_71A1:
	db $00, $00, $33, $00, $01
Sfx4_09_Data_71A6:
	db $00, $00, $60, $00, $01
Sfx4_09_Data_71AB:
	db $00, $00, $43, $00, $01
Sfx4_09_Data_71B0:
	db $00, $00, $70, $00, $01
Sfx4_09_Data_71B5:
	db $00, $00, $45, $00, $01
Sfx4_09_Data_71BA:
	db $00, $00, $47, $00, $01
Sfx4_09_Data_71BF:
	db $00, $00, $55, $00, $01
Sfx4_09_Data_71C4:
	db $00, $00, $65, $00, $01
Sfx4_09_Data_71C9:
	db $00, $08, $65, $80, $02
Sfx4_01_Init:
	ld hl, Sfx4_01_Data_71EF
	jp Sfx4_Start

Sfx4_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Release
	ld hl, Sfx4_01_Data_71E9
	call GetPointer
	jp SetRegs_Ch4

Sfx4_01_Data_71E9:
	dw Sfx4_01_Data_71F4, Sfx4_01_Data_71F9, Sfx4_01_Data_71FE
Sfx4_01_Data_71EF:
	db $00, $b1, $05, $80, $01
Sfx4_01_Data_71F4:
	db $00, $01, $27, $80, $02
Sfx4_01_Data_71F9:
	db $00, $d1, $27, $80, $01
Sfx4_01_Data_71FE:
	db $00, $d7, $37, $80, $25
Sfx4_22_Init:
	ld hl, Sfx4_22_Data_7210
	jp Sfx4_Start

Sfx4_22_Play:
	call Sfx_DecTimer
	ret nz
	jp z, Sfx4_Release
Sfx4_22_Data_7210:
	db $00, $93, $34, $80, $15
Sfx4_07_Init:
	ld hl, Sfx4_07_Data_7238
	jp Sfx4_Start

Sfx4_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_07_Data_7230
	call GetPointer
	jp SetRegs_Ch4

Sfx4_07_Data_7230:
	dw Sfx4_07_Data_723D, Sfx4_07_Data_7242, Sfx4_07_Data_7247, Sfx4_07_Data_724C
Sfx4_07_Data_7238:
	db $00, $f8, $47, $80, $03
Sfx4_07_Data_723D:
	db $00, $f8, $45, $80, $02
Sfx4_07_Data_7242:
	db $00, $08, $45, $80, $02
Sfx4_07_Data_7247:
	db $00, $f8, $37, $80, $02
Sfx4_07_Data_724C:
	db $00, $f8, $36, $80, $01
Sfx4_06_Init:
	ld hl, Sfx4_06_Data_7270
	jp Sfx4_Start

Sfx4_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_06_Data_726C
	call GetPointer
	jp SetRegs_Ch4

Sfx4_06_Data_726C:
	dw Sfx4_06_Data_7275, Sfx4_06_Data_727A
Sfx4_06_Data_7270:
	db $00, $f8, $36, $80, $03
Sfx4_06_Data_7275:
	db $00, $08, $27, $80, $02
Sfx4_06_Data_727A:
	db $00, $d8, $01, $80, $03
Sfx4_02_Init:
	ld hl, Sfx4_02_Data_7297
	jp Sfx4_Start

Sfx4_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_02_Data_729C
	jp SetRegs_Ch4

Sfx4_02_Data_7297:
	db $3c, $f9, $2e, $c0, $05
Sfx4_02_Data_729C:
	db $3c, $b9, $34, $c0, $08
Sfx4_1F_Init:
	ld hl, Sfx4_1F_Data_72B9
	jp Sfx4_Start

Sfx4_1F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_1F_Data_72BE
	jp SetRegs_Ch4

Sfx4_1F_Data_72B9:
	db $3c, $f9, $34, $c0, $05
Sfx4_1F_Data_72BE:
	db $3c, $b9, $17, $c0, $08
Sfx4_03_Init:
	ld a, [wSfx4Playing]
	cp $03
	jp z, Sfx4_Refuse
	ld hl, Sfx4_03_Data_72E3
	jp Sfx4_Start

Sfx4_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_03_Data_72E8
	jp SetRegs_Ch4

Sfx4_03_Data_72E3:
	db $01, $b7, $02, $c0, $10
Sfx4_03_Data_72E8:
	db $01, $67, $02, $c0, $08
Sfx4_0E_Init:
	ld hl, Sfx4_0E_Data_730C
	jp Sfx4_Start

Sfx4_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Release
	ld hl, Sfx4_0E_Data_7308
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0E_Data_7308:
	dw Sfx4_0E_Data_7311, Sfx4_0E_Data_7316
Sfx4_0E_Data_730C:
	db $00, $79, $35, $80, $04
Sfx4_0E_Data_7311:
	db $00, $66, $20, $80, $06
Sfx4_0E_Data_7316:
	db $00, $56, $25, $80, $0a
Sfx4_0F_Init:
	ld a, [wSfx4Playing]
	cp $0f
	jp z, Sfx4_Refuse
	ld hl, Sfx4_0F_Data_735C
	jp Sfx4_Start

Sfx4_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx4_Release
	ld hl, Sfx4_0F_Data_733E
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0F_Data_733E:
	dw Sfx4_0F_Data_7361, Sfx4_0F_Data_7366, Sfx4_0F_Data_736B, Sfx4_0F_Data_7370, Sfx4_0F_Data_7375, Sfx4_0F_Data_737A, Sfx4_0F_Data_737F, Sfx4_0F_Data_7384, Sfx4_0F_Data_7389, Sfx4_0F_Data_738E, Sfx4_0F_Data_7393, Sfx4_0F_Data_7398, Sfx4_0F_Data_739D, Sfx4_0F_Data_73A2, Sfx4_0F_Data_73A7
Sfx4_0F_Data_735C:
	db $00, $20, $25, $80, $02
Sfx4_0F_Data_7361:
	db $00, $40, $21, $80, $02
Sfx4_0F_Data_7366:
	db $00, $60, $17, $80, $02
Sfx4_0F_Data_736B:
	db $00, $80, $15, $80, $02
Sfx4_0F_Data_7370:
	db $00, $a0, $17, $80, $02
Sfx4_0F_Data_7375:
	db $00, $c0, $21, $80, $02
Sfx4_0F_Data_737A:
	db $00, $b0, $25, $80, $04
Sfx4_0F_Data_737F:
	db $00, $a0, $21, $80, $04
Sfx4_0F_Data_7384:
	db $00, $90, $17, $80, $04
Sfx4_0F_Data_7389:
	db $00, $80, $15, $c0, $04
Sfx4_0F_Data_738E:
	db $00, $70, $17, $80, $04
Sfx4_0F_Data_7393:
	db $00, $60, $21, $80, $04
Sfx4_0F_Data_7398:
	db $00, $50, $25, $80, $04
Sfx4_0F_Data_739D:
	db $00, $40, $21, $80, $04
Sfx4_0F_Data_73A2:
	db $00, $30, $17, $80, $04
Sfx4_0F_Data_73A7:
	db $2f, $20, $21, $c0, $04
Sfx4_25_Init:
	ld hl, Sfx4_25_Data_73E5
	jp Sfx4_Start

Sfx4_25_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $10
	jp z, Sfx4_Release
	ld hl, Sfx4_25_Data_73C7
	call GetPointer
	jp SetRegs_Ch4

Sfx4_25_Data_73C7:
	dw Sfx4_25_Data_73EA, Sfx4_25_Data_73EF, Sfx4_25_Data_73F4, Sfx4_25_Data_73F9, Sfx4_25_Data_73FE, Sfx4_25_Data_7403, Sfx4_25_Data_7408, Sfx4_25_Data_740D, Sfx4_25_Data_7412, Sfx4_25_Data_7417, Sfx4_25_Data_741C, Sfx4_25_Data_7421, Sfx4_25_Data_7426, Sfx4_25_Data_742B, Sfx4_25_Data_7430
Sfx4_25_Data_73E5:
	db $00, $20, $25, $80, $02
Sfx4_25_Data_73EA:
	db $00, $40, $21, $80, $02
Sfx4_25_Data_73EF:
	db $00, $60, $17, $80, $02
Sfx4_25_Data_73F4:
	db $00, $80, $15, $80, $02
Sfx4_25_Data_73F9:
	db $00, $a0, $17, $80, $02
Sfx4_25_Data_73FE:
	db $00, $c0, $21, $80, $02
Sfx4_25_Data_7403:
	db $00, $b0, $25, $80, $04
Sfx4_25_Data_7408:
	db $00, $a0, $21, $80, $04
Sfx4_25_Data_740D:
	db $00, $90, $17, $80, $04
Sfx4_25_Data_7412:
	db $00, $80, $15, $c0, $04
Sfx4_25_Data_7417:
	db $00, $70, $17, $80, $04
Sfx4_25_Data_741C:
	db $00, $60, $21, $80, $04
Sfx4_25_Data_7421:
	db $00, $50, $25, $80, $04
Sfx4_25_Data_7426:
	db $00, $40, $21, $80, $04
Sfx4_25_Data_742B:
	db $00, $30, $17, $80, $04
Sfx4_25_Data_7430:
	db $2f, $20, $21, $c0, $04
Sfx4_11_Init:
	ld hl, Sfx4_11_Data_7454
	jp Sfx4_Start

Sfx4_11_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Release
	ld hl, Sfx4_11_Data_7450
	call GetPointer
	jp SetRegs_Ch4

Sfx4_11_Data_7450:
	dw Sfx4_11_Data_7459, Sfx4_11_Data_745E
Sfx4_11_Data_7454:
	db $00, $0f, $30, $80, $20
Sfx4_11_Data_7459:
	db $00, $60, $03, $80, $28
Sfx4_11_Data_745E:
	db $00, $67, $03, $80, $20
Sfx4_27_Init:
	ld hl, Sfx4_27_Data_747B
	jp Sfx4_Start

Sfx4_27_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_27_Data_7480
	jp SetRegs_Ch4

Sfx4_27_Data_747B:
	db $00, $d8, $56, $80, $03
Sfx4_27_Data_7480:
	db $00, $d1, $44, $80, $04
Sfx4_13_Init:
	ld hl, Sfx4_13_Data_74A6
	jp Sfx4_Start

Sfx4_13_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Stop
	ld hl, Sfx4_13_Data_74A0
	call GetPointer
	jp SetRegs_Ch4

Sfx4_13_Data_74A0:
	dw Sfx4_13_Data_74AB, Sfx4_13_Data_74A6, Sfx4_13_Data_74B0
Sfx4_13_Data_74A6:
	db $00, $78, $3e, $80, $01
Sfx4_13_Data_74AB:
	db $00, $88, $6e, $80, $04
Sfx4_13_Data_74B0:
	db $00, $28, $4e, $80, $03
Sfx4_0B_Init:
	ld hl, Sfx4_0B_Data_74D6
	jp Sfx4_Start

Sfx4_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Stop
	ld hl, Sfx4_0B_Data_74D0
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0B_Data_74D0:
	dw Sfx4_0B_Data_74DB, Sfx4_0B_Data_74D6, Sfx4_0B_Data_74E0
Sfx4_0B_Data_74D6:
	db $00, $c8, $3e, $80, $01
Sfx4_0B_Data_74DB:
	db $00, $d8, $6e, $80, $04
Sfx4_0B_Data_74E0:
	db $00, $78, $4e, $80, $03
Sfx4_12_Init:
	ld hl, Sfx4_12_Data_7506
	jp Sfx4_Start

Sfx4_12_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx4_Stop
	ld hl, Sfx4_12_Data_7500
	call GetPointer
	jp SetRegs_Ch4

Sfx4_12_Data_7500:
	dw Sfx4_12_Data_750B, Sfx4_12_Data_7506, Sfx4_12_Data_7510
Sfx4_12_Data_7506:
	db $00, $c8, $3e, $80, $01
Sfx4_12_Data_750B:
	db $00, $d8, $6e, $80, $04
Sfx4_12_Data_7510:
	db $00, $78, $4e, $80, $03
Sfx4_14_Init:
	ld hl, Sfx4_14_Data_752D
	jp Sfx4_Start

Sfx4_14_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_14_Data_7532
	jp SetRegs_Ch4

Sfx4_14_Data_752D:
	db $30, $89, $40, $c0, $05
Sfx4_14_Data_7532:
	db $00, $88, $20, $80, $10
Sfx4_15_Init:
	ld hl, Sfx4_15_Data_755A
	jp Sfx4_Start

Sfx4_15_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_Stop
	ld hl, Sfx4_15_Data_7552
	call GetPointer
	jp SetRegs_Ch4

Sfx4_15_Data_7552:
	dw Sfx4_15_Data_755F, Sfx4_15_Data_7564, Sfx4_15_Data_7569, Sfx4_15_Data_756E
Sfx4_15_Data_755A:
	db $00, $1c, $50, $80, $14
Sfx4_15_Data_755F:
	db $00, $f8, $01, $80, $01
Sfx4_15_Data_7564:
	db $00, $59, $11, $80, $03
Sfx4_15_Data_7569:
	db $01, $c8, $17, $80, $01
Sfx4_15_Data_756E:
	db $00, $f5, $11, $80, $01
Sfx4_16_Init:
	ld a, [wSfx4Playing]
	cp $16
	jp z, Sfx4_Refuse
	ld hl, Sfx4_16_Data_7593
	jp Sfx4_Start

Sfx4_16_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_16_Data_7598
	jp SetRegs_Ch4

Sfx4_16_Data_7593:
	db $00, $2f, $07, $80, $50
Sfx4_16_Data_7598:
	db $00, $a3, $07, $80, $08
Sfx4_17_Init:
	ld a, [wSfx4Playing]
	cp $17
	jp z, Sfx4_Refuse
	ld hl, Sfx4_17_Data_75BD
	jp Sfx4_Start

Sfx4_17_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_17_Data_75C2
	jp SetRegs_Ch4

Sfx4_17_Data_75BD:
	db $00, $4d, $15, $80, $14
Sfx4_17_Data_75C2:
	db $00, $77, $04, $80, $40
Sfx4_26_Init:
	ld hl, Sfx4_26_Data_75DF
	jp Sfx4_Start

Sfx4_26_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Release
	ld hl, Sfx4_26_Data_75E4
	jp SetRegs_Ch4

Sfx4_26_Data_75DF:
	db $00, $1f, $25, $80, $30
Sfx4_26_Data_75E4:
	db $00, $83, $25, $80, $08
Sfx4_19_Init:
	ld hl, Sfx4_19_Data_7618
	jp Sfx4_Start

Sfx4_19_Play:
	call Sfx_DecTimer
	jp z, Sfx4_Release
	ld b, $14
	cp $0a
	jr nc, .l0
	ld b, $02
	cp $07
	jr nc, .l0
	ld b, $01
	ld a, $41
	ldh [rNR42], a
	ld hl, $ff23
	set 7, [hl]
.l0:
	ld c, $22
	ldh a, [c]
	add a, b
	bit 3, a
	jr z, .l1
	add a, $08
.l1:
	ldh [c], a
	ret

Sfx4_19_Data_7618:
	db $00, $78, $00, $80, $0c
Sfx4_18_Init:
	ld hl, Sfx4_18_Data_764C
	jp Sfx4_Start

Sfx4_18_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0b
	jp z, Sfx4_Stop
	ld hl, Sfx4_18_Data_7638
	call GetPointer
	jp SetRegsSkip0_Ch4

Sfx4_18_Data_7638:
	dw Sfx4_18_Data_7651, Sfx4_18_Data_7656, Sfx4_18_Data_765B, Sfx4_18_Data_7660, Sfx4_18_Data_7665, Sfx4_18_Data_766A, Sfx4_18_Data_766F, Sfx4_18_Data_7674, Sfx4_18_Data_766F, Sfx4_18_Data_7674
Sfx4_18_Data_764C:
	db $3b, $91, $2f, $c0, $01
Sfx4_18_Data_7651:
	db $3b, $b1, $35, $c0, $02
Sfx4_18_Data_7656:
	db $38, $c1, $2e, $c0, $02
Sfx4_18_Data_765B:
	db $38, $f1, $34, $c0, $03
Sfx4_18_Data_7660:
	db $38, $f1, $2d, $c0, $04
Sfx4_18_Data_7665:
	db $00, $f1, $08, $80, $02
Sfx4_18_Data_766A:
	db $00, $81, $08, $80, $02
Sfx4_18_Data_766F:
	db $00, $00, $09, $00, $02
Sfx4_18_Data_7674:
	db $00, $00, $08, $00, $02
Sfx4_1C_Init:
	ld hl, Sfx4_1C_Data_7691
	jp Sfx4_Start

Sfx4_1C_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_1C_Data_7696
	jp SetRegs_Ch4

Sfx4_1C_Data_7691:
	db $38, $81, $4c, $c0, $03
Sfx4_1C_Data_7696:
	db $00, $a1, $4c, $80, $04
Sfx4_10_Init:
	ld hl, Sfx4_10_Data_76BA
	jp Sfx4_Start

Sfx4_10_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx4_Stop
	ld hl, Sfx4_10_Data_76B6
	call GetPointer
	jp SetRegs_Ch4

Sfx4_10_Data_76B6:
	dw Sfx4_10_Data_76BF, Sfx4_10_Data_76C4
Sfx4_10_Data_76BA:
	db $00, $58, $24, $80, $03
Sfx4_10_Data_76BF:
	db $00, $48, $35, $80, $02
Sfx4_10_Data_76C4:
	db $00, $38, $37, $80, $01
Sfx1_52_Init:
	ld a, $09
	ld [wSfx2Request], a
	ld a, $04
	ld [wSfx3Request], a
	ld a, $08
	ld [wSfx4Request], a
	ld a, $01
	ld [wHurryMode], a
	ld a, $02
	ld [wHurryJingle], a
	ld hl, Sfx1_52_Data_7738
	jp Sfx1_Start

Sfx1_52_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $18
	jp nz, .l0
	xor a
	ld [wHurryJingle], a
	ld a, [wSongPlaying]
	ld [wSongRequest], a
	jp Sfx1_Release

.l0:
	ld hl, Sfx1_52_Data_770A
	call GetPointer
	jp SetRegsSkip0_Ch1

Sfx1_52_Data_770A:
	dw Sfx1_52_Data_7744, Sfx1_52_Data_773E, Sfx1_52_Data_7744, Sfx1_52_Data_774A, Sfx1_52_Data_7750, Sfx1_52_Data_774A, Sfx1_52_Data_7750, Sfx1_52_Data_773E, Sfx1_52_Data_7744, Sfx1_52_Data_773E, Sfx1_52_Data_7744, Sfx1_52_Data_774A, Sfx1_52_Data_7750, Sfx1_52_Data_774A, Sfx1_52_Data_7750, Sfx1_52_Data_773E, Sfx1_52_Data_7744, Sfx1_52_Data_773E, Sfx1_52_Data_7744, Sfx1_52_Data_774A, Sfx1_52_Data_7750, Sfx1_52_Data_774A, Sfx1_52_Data_7756
Sfx1_52_Data_7738:
	db $08, $80, $98, $ac, $87, $05
Sfx1_52_Data_773E:
	db $00, $00, $00, $ac, $07, $05
Sfx1_52_Data_7744:
	db $00, $00, $00, $b1, $07, $05
Sfx1_52_Data_774A:
	db $00, $00, $00, $b6, $07, $05
Sfx1_52_Data_7750:
	db $00, $00, $00, $ba, $07, $05
Sfx1_52_Data_7756:
	db $00, $00, $91, $ba, $87, $23
Sfx2_09_Init:
	ld hl, Sfx2_09_Data_77A5
	jp Sfx2_Start

Sfx2_09_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $18
	jp z, Sfx2_Release
	ld hl, Sfx2_09_Data_7777
	call GetPointer
	jp SetRegsSkip0_Ch2

Sfx2_09_Data_7777:
	dw Sfx2_09_Data_77AF, Sfx2_09_Data_77AA, Sfx2_09_Data_77AF, Sfx2_09_Data_77B4, Sfx2_09_Data_77B9, Sfx2_09_Data_77B4, Sfx2_09_Data_77B9, Sfx2_09_Data_77AA, Sfx2_09_Data_77AF, Sfx2_09_Data_77AA, Sfx2_09_Data_77AF, Sfx2_09_Data_77B4, Sfx2_09_Data_77B9, Sfx2_09_Data_77B4, Sfx2_09_Data_77B9, Sfx2_09_Data_77AA, Sfx2_09_Data_77AF, Sfx2_09_Data_77AA, Sfx2_09_Data_77AF, Sfx2_09_Data_77B4, Sfx2_09_Data_77B9, Sfx2_09_Data_77B4, Sfx2_09_Data_77BE
Sfx2_09_Data_77A5:
	db $80, $88, $ab, $87, $05
Sfx2_09_Data_77AA:
	db $00, $00, $ab, $07, $05
Sfx2_09_Data_77AF:
	db $00, $00, $b0, $07, $05
Sfx2_09_Data_77B4:
	db $00, $00, $b5, $07, $05
Sfx2_09_Data_77B9:
	db $00, $00, $b9, $07, $05
Sfx2_09_Data_77BE:
	db $00, $81, $b9, $87, $23
Sfx3_04_Init:
	ld hl, Sfx3_04_Data_77D0
	jp Sfx3_Start

Sfx3_04_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx3_Stop

Sfx3_04_Data_77D0:
	db $80, $00, $00, $d6, $87, $95
Sfx4_08_Init:
	ld hl, Sfx4_08_Data_77E3
	jp Sfx4_Start

Sfx4_08_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_08_Data_77E3:
	db $00, $08, $47, $80, $95
Sfx1_6A_Init:
	ld hl, Sfx1_6A_Data_7809
	jp Sfx1_StartSweep

Sfx1_6A_Play:
	call Sfx_DecTimer
	jp nz, Sfx1_Sweep
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx1_6A_Data_7805
	call GetPointer
	jp Sfx1_SweepStart

Sfx1_6A_Data_7805:
	dw Sfx1_6A_Data_780F, Sfx1_6A_Data_7815
Sfx1_6A_Data_7809:
	db $13, $80, $3a, $d6, $86, $05
Sfx1_6A_Data_780F:
	db $13, $80, $2a, $d6, $86, $05
Sfx1_6A_Data_7815:
	db $13, $80, $2a, $d6, $86, $05
Sfx2_3F_Init:
	ld a, [wSfx2Playing]
	cp $3f
	jp nz, .l0
	jp Sfx2_Continue

.l0:
	ld a, $04
	ld [wSfx2Counter], a
	ld hl, Sfx2_3F_Data_7883
	call Sfx2_LoadPitch
	jp Sfx2_Start

Sfx2_3F_Play:
	ld a, [wSfx2Request]
	cp $3f
	jp nz, Sfx2_Stop
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $02
	jr z, .l1
	cp $03
	jr z, .l2
.l4:
	ld hl, Sfx2_3F_Data_7871
	jp Sfx2_AddPitch

.l1:
	call Sfx2_DecCounter
	jp z, Sfx2_Stop
	cp $02
	jr z, .l3
	ld a, [bc]
	jr .l4

.l2:
	ld a, $01
	ld [bc], a
	jr .l4

.l3:
	xor a
	ld [bc], a
	ld hl, Sfx2_3F_Data_7888
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx2_3F_Data_7871:
	db $00, $40
	db $00, $40
	db $00, $40
	db $00, $40
	db $00, $20
	db $00, $20
	db $00, $10
	db $00, $08
	db $ff, $a8
Sfx2_3F_Data_7883:
	db $00, $ce, $83, $84, $02
Sfx2_3F_Data_7888:
	db $00, $f7, $83, $84, $02
