; Metal Slug 2 SFX: ch1 effects, bank $29 $411C-$5337

; Request 1 always starts; any other request is refused while a priority effect plays
; (wSfx1Priority).
Sfx1_Update:
	ld hl, wSfx1Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $01
	jr z, .start
	ld a, [wSfx1Priority]
	and a
	jp nz, Sfx1_Refuse
.start:
	ld a, [hl]
	ld hl, Sfx1_InitTable
	jp .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx1_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx1Timer
	ld bc, wSfx1Step
	jp hl

; same number in LA
Sfx1_01_Init:
	xor a
	ld [wSfx3Request], a
	ld [wSfx3Playing], a
	ldh [rNR30], a
	ld a, $01
	ld [wSfx3Priority], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, wCh3Flags
	set 7, [hl]
	ld hl, Sfx1_01_Data_4207
	call SetRegs_Ch2
	call Sfx1_01_Shared_62BD
	ld hl, Sfx1_01_Data_421B
	call SetRegs_Ch3
	ld hl, Sfx1_01_Data_41EF
	jp Sfx1_StartPriority

Sfx1_01_Play:
	ld a, [$1000]
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $01
	jr z, .l0
	cp $02
	jr z, .l1
	cp $03
	jr z, .l2
	cp $04
	jr z, .l3
	jr .l4

.l0:
	ld hl, Sfx1_01_Data_41F5
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_420C
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4221
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx1_01_Data_41FB
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_4211
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4227
	jp SetRegs_Ch3

.l2:
	ld hl, Sfx1_01_Data_4201
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_4216
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_422D
	jp SetRegs_Ch3

.l3:
	ld hl, Sfx1_01_Data_4233
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_4239
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4233
	jp SetRegs_Ch3

.l4:
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, wCh3Flags
	res 7, [hl]
	xor a
	ldh [rNR30], a
	ld [wSfx3Priority], a
	ld a, $01
	ld [wReloadWave], a
	jp Sfx1_Stop

Sfx1_01_Data_41EF:
	db $00, $80, $80, $89, $86, $0a
Sfx1_01_Data_41F5:
	db $00, $80, $80, $9e, $86, $0a
Sfx1_01_Data_41FB:
	db $00, $80, $80, $b2, $86, $0a
Sfx1_01_Data_4201:
	db $00, $80, $80, $c4, $86, $30
Sfx1_01_Data_4207:
	db $00, $c0, $06, $87, $0a
Sfx1_01_Data_420C:
	db $00, $c0, $14, $87, $0a
Sfx1_01_Data_4211:
	db $00, $c0, $21, $87, $0a
Sfx1_01_Data_4216:
	db $00, $c0, $2d, $87, $30
Sfx1_01_Data_421B:
	db $80, $00, $20, $6b, $87, $0a
Sfx1_01_Data_4221:
	db $80, $00, $20, $73, $87, $0a
Sfx1_01_Data_4227:
	db $80, $00, $20, $7b, $87, $0a
Sfx1_01_Data_422D:
	db $80, $00, $20, $83, $87, $30
Sfx1_01_Data_4233:
	db $00, $00, $00, $00, $c0, $20
Sfx1_01_Data_4239:
	db $3f, $00, $00, $c1, $20
; same number in LA
Sfx1_02_Init:
	ld hl, Sfx1_02_Data_426F
	jp Sfx1_StartPriority

Sfx1_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_02_Data_4261
	call GetPointer
	ld a, $80
	ldh [rNR11], a
	ld a, $f1
	ldh [rNR12], a
	jp Sfx1_WritePeriod

Sfx1_02_Data_4261:
	dw Sfx1_02_Data_4275, Sfx1_02_Data_4278, Sfx1_02_Data_427B, Sfx1_02_Data_427E, Sfx1_02_Data_4281, Sfx1_02_Data_4284, Sfx1_02_Data_4287
Sfx1_02_Data_426F:
	db $00, $80, $f1, $a7, $c7, $08
Sfx1_02_Data_4275:
	db $a2, $c7, $08
Sfx1_02_Data_4278:
	db $90, $c7, $08
Sfx1_02_Data_427B:
	db $7b, $c7, $08
Sfx1_02_Data_427E:
	db $59, $c7, $08
Sfx1_02_Data_4281:
	db $97, $c7, $08
Sfx1_02_Data_4284:
	db $ac, $c7, $08
Sfx1_02_Data_4287:
	db $be, $c7, $20
; same number in LA
Sfx1_03_Init:
	ld hl, Sfx1_03_Data_42D0
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_03_Play:
	call Sfx_IncStep
	cp $0d
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_03_Data_42A1
	jp Sfx1_AddPitch

Sfx1_03_Data_42A1:
	db $21, $9d
	db $43, $cd
	db $b7, $7a
	db $c3, $9a
	db $53, $cd
	db $75, $7a
	db $fe, $0d
	db $ca, $b5
	db $53, $21
	db $85, $43
	db $c3, $e1
	db $7a, $ff
	db $c0, $ff
	db $80, $ff
	db $00, $fe
	db $00, $01
	db $00, $ff
	db $00, $01
	db $00, $ff
	db $00, $00
	db $c0, $00
	db $c0, $00
	db $c0, $00
	db $c0
Sfx1_03_Data_42D0:
	db $00, $00, $c0, $80, $86, $01
; same number in LA
Sfx1_04_Init:
	ld a, $0e
	ld [wSfx1Counter], a
	ld hl, Sfx1_04_Data_4310
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_04_Play:
	call Sfx_DecTimer
	ret nz
	ld a, [wSfx4Playing]
	cp $02
	jp z, Sfx1_StopWithRegs
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx1_04_Data_430C
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jp .l1

Sfx1_04_Data_430C:
	db $00, $20
	db $ff, $f0
Sfx1_04_Data_4310:
	db $00, $80, $87, $c0, $86, $02
; same number in LA
Sfx1_05_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_05_Data_434C
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_05_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $04
	ld [de], a
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l1:
	ld hl, Sfx1_05_Data_4344
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jp .l1

Sfx1_05_Data_4344:
	db $00, $06
	db $00, $04
	db $00, $02
	db $ff, $f4
Sfx1_05_Data_434C:
	db $00, $00, $c5, $d8, $87, $04
; same number in LA
Sfx1_06_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_06_Data_4389
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_06_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx1_06_Data_4379
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jp .l1

Sfx1_06_Data_4379:
	db $00, $40
	db $00, $80
	db $00, $80
	db $00, $40
	db $ff, $d0
	db $ff, $a0
	db $ff, $a0
	db $ff, $d0
Sfx1_06_Data_4389:
	db $00, $80, $1b, $00, $82, $01
; same number in LA
Sfx1_07_Init:
	ld hl, Sfx1_07_Data_43A7
	jp Sfx1_Start

Sfx1_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_07_Data_43AD
	jp SetRegs_Ch1

Sfx1_07_Data_43A7:
	db $00, $3d, $f0, $d8, $c7, $03
Sfx1_07_Data_43AD:
	db $00, $00, $81, $e0, $87, $08
	db $21
; same number in LA
Sfx1_08_Init:
	ld hl, Sfx1_08_Data_43CC
	jp Sfx1_Start

Sfx1_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_08_Data_43D2
	jp SetRegs_Ch1

Sfx1_08_Data_43CC:
	db $3f, $9e, $29, $80, $c7, $08
Sfx1_08_Data_43D2:
	db $1f, $9f, $81, $20, $87, $10
; same number in LA
Sfx1_09_Init:
	ld hl, Sfx1_09_Data_43FA
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_09_Play:
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_09_Data_43FA
	jp Sfx1_AddPitch

; unreferenced
Unused_43EF:
	db $01, $00, $00, $c0, $00, $80, $00, $40, $ff, $c0, $ff
Sfx1_09_Data_43FA:
	db $80, $ff, $40, $ff, $00, $00
	db $9f, $a0, $00, $c2, $01
; same number in LA
Sfx1_0A_Init:
	ld a, [wSfx1Playing]
	cp $13
	jp z, Sfx1_Refuse
	ldh a, [rNR50]
	cp $77
	jp nz, .l0
	ld hl, Sfx1_0A_Data_4444
.l1:
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_0A_Data_444A
	jp .l1

Sfx1_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ldh a, [rNR50]
	cp $77
	jp nz, .l2
	ld a, $10
.l3:
	ldh [rNR12], a
	ld a, $c7
	ldh [rNR14], a
	ld a, $08
	ld [de], a
	ret

.l2:
	ld a, $20
	jp .l3

Sfx1_0A_Data_4444:
	db $00, $9f, $80, $a0, $c7, $02
Sfx1_0A_Data_444A:
	db $00, $9f, $f0, $a0, $c7, $02
; same number in LA
Sfx1_0B_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_0B_Data_448A
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_0B_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_0B_Data_447E
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jp .l1

Sfx1_0B_Data_447E:
	db $ff, $c0
	db $ff, $80
	db $ff, $40
	db $00, $c0
	db $00, $80
	db $00, $40
Sfx1_0B_Data_448A:
	db $00, $80, $f4, $80, $83, $01
; same number in LA
Sfx1_0C_Init:
	ld a, $16
	ld [wSfx1Counter], a
	ld hl, Sfx1_0C_Data_44CB
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_0C_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l2:
	ld hl, Sfx1_0C_Data_44C5
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $08
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_0C_Data_44D1
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_0C_Data_44C5:
	db $00, $28
	db $00, $00
	db $ff, $f0
Sfx1_0C_Data_44CB:
	db $00, $83, $47, $c0, $86, $02
Sfx1_0C_Data_44D1:
	db $00, $83, $47, $00, $87, $02
; same number in LA
Sfx1_0D_Init:
	ld hl, Sfx1_0D_Data_44E4
	jp Sfx1_Start

Sfx1_0D_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_0D_Data_44E4:
	db $27, $80, $c2, $48, $86, $18
; same number in LA
Sfx1_0E_Init:
	ld a, [wSfx1Playing]
	cp $08
	jr z, .l0
	and a
	jp nz, Sfx1_Refuse
.l0:
	ld hl, Sfx1_0E_Data_4502
	jp Sfx1_Start

Sfx1_0E_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_0E_Data_4502:
	db $16, $ab, $20, $80, $c6, $05
; same number in LA
Sfx1_0F_Init:
	ld hl, Sfx1_0F_Data_4520
	jp Sfx1_Start

Sfx1_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_0F_Data_4526
	jp SetRegs_Ch1

Sfx1_0F_Data_4520:
	db $17, $80, $0b, $00, $85, $10
Sfx1_0F_Data_4526:
	db $17, $80, $0e, $00, $c5, $10
; not in LA
Sfx1_10_Init:
	ret

Sfx1_10_Play:
	ret

; same number in LA
Sfx1_11_Init:
	ld a, $17
	ld [wSfx1Counter], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_11_Data_456D
	call Sfx2_LoadPitch
	call SetRegs_Ch2
	ld hl, Sfx1_11_Data_4572
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_11_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l1:
	ld hl, Sfx1_11_Data_456B
	call Sfx2_AddPitch
	ld bc, wSfx1Step
	ld hl, Sfx1_11_Data_456B
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_11_Shared_4578
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_11_Data_456B:
	db $00, $21
Sfx1_11_Data_456D:
	db $45, $0c, $00, $84, $12
Sfx1_11_Data_4572:
	db $00, $85, $0b, $00, $81, $12
Sfx1_11_Shared_4578:
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, Sfx1_01_Data_4239
	call SetRegs_Ch2
	jp Sfx1_StopWithRegs

; same number in LA
Sfx1_12_Init:
	ld a, [wSfx1Playing]
	cp $13
	jp z, Sfx1_Refuse
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_12_Data_45CE
	call Sfx2_LoadPitch
	call SetRegs_Ch2
	ld hl, Sfx1_12_Data_45D3
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_12_Play:
	call Sfx_IncStep
	cp $02
	jr z, Sfx1_12_Shared_45C0
Sfx1_12_Shared_45B1:
	ld hl, Sfx1_12_Data_45CC
	call Sfx2_AddPitch
	ld bc, wSfx1Step
	ld hl, Sfx1_12_Data_45CC
	jp Sfx1_AddPitch

Sfx1_12_Shared_45C0:
	call Sfx1_DecCounter
	jp z, Sfx1_11_Shared_4578
	ld a, $01
	ld [bc], a
	jp Sfx1_12_Shared_45B1

Sfx1_12_Data_45CC:
	db $ff, $d0
Sfx1_12_Data_45CE:
	db $40, $0a, $b0, $87, $12
Sfx1_12_Data_45D3:
	db $00, $80, $09, $c0, $86, $12
; = LA Sfx1_13
Sfx1_14_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ldh a, [rNR50]
	cp $77
	jr nz, .l0
	ld hl, Sfx1_14_Data_4619
.l1:
	call Sfx1_LoadPitch
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_14_Data_461F
	jp .l1

Sfx1_14_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $03
	ld [de], a
	call Sfx_IncStep
	cp $04
	jr z, .l2
.l3:
	ld hl, Sfx1_14_Data_4613
	jp Sfx1_AddPitch

.l2:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jp .l3

Sfx1_14_Data_4613:
	db $00, $22
	db $00, $19
	db $ff, $c5
Sfx1_14_Data_4619:
	db $00, $80, $a4, $7b, $87, $03
Sfx1_14_Data_461F:
	db $00, $80, $f3, $7b, $87, $03
; = LA Sfx1_14
Sfx1_15_Init:
	ld a, [wSfx1Playing]
	and a
	jp nz, Sfx1_Refuse
	ld hl, Sfx1_15_Data_4639
	jp Sfx1_Start

Sfx1_15_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_15_Data_4639:
	db $35, $b0, $60, $20, $c7, $04
; = LA Sfx1_15
Sfx1_16_Init:
	ld hl, Sfx1_16_Data_465E
	jp Sfx1_Start

Sfx1_16_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx1_16_Data_465A
	call GetPointer
	jp SetRegs_Ch1

Sfx1_16_Data_465A:
	dw Sfx1_16_Data_4664, Sfx1_16_Data_466A
Sfx1_16_Data_465E:
	db $00, $b0, $19, $4f, $c7, $06
Sfx1_16_Data_4664:
	db $00, $b0, $19, $7b, $c7, $06
Sfx1_16_Data_466A:
	db $00, $b0, $29, $9d, $c7, $03
; = LA Sfx1_16
Sfx1_17_Init:
	ld hl, Sfx1_17_Data_467D
	jp Sfx1_Start

Sfx1_17_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_17_Data_467D:
	db $00, $00, $81, $bb, $c7, $20
; = LA Sfx1_17
Sfx1_18_Init:
	ld a, $2a
	ld [wSfx1Counter], a
	ld hl, Sfx1_18_Data_46C2
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_18_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_18_Data_46BC
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $0e
	jr z, .l1
	cp $1c
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld hl, Sfx1_18_Data_46BC
	call Sfx1_AddPitch
	xor a
	ld [wSfx1Step], a
	ret

Sfx1_18_Data_46BC:
	db $00, $20
	db $ff, $e8
	db $ff, $90
Sfx1_18_Data_46C2:
	db $00, $80, $d7, $68, $87, $01
; = LA Sfx1_18
Sfx1_19_Init:
	ld hl, Sfx1_19_Data_46E0
	jp Sfx1_Start

Sfx1_19_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_19_Data_46E6
	jp SetRegs_Ch1

Sfx1_19_Data_46E0:
	db $2f, $80, $60, $e0, $86, $14
Sfx1_19_Data_46E6:
	db $2f, $80, $10, $e0, $86, $14
; = LA Sfx1_19
Sfx1_1A_Init:
	ld hl, Sfx1_1A_Data_470F
	jp Sfx1_StartPriority

Sfx1_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_1A_Data_4707
	call GetPointer
	jp SetRegs_Ch1

Sfx1_1A_Data_4707:
	dw Sfx1_1A_Data_4715, Sfx1_1A_Data_471B, Sfx1_1A_Data_4721, Sfx1_1A_Data_4727
Sfx1_1A_Data_470F:
	db $00, $80, $c1, $a7, $87, $06
Sfx1_1A_Data_4715:
	db $00, $80, $c1, $b1, $87, $06
Sfx1_1A_Data_471B:
	db $00, $80, $c1, $ba, $87, $06
Sfx1_1A_Data_4721:
	db $00, $80, $c1, $be, $87, $06
Sfx1_1A_Data_4727:
	db $00, $80, $a3, $c5, $87, $20
; = LA Sfx1_1A
Sfx1_1B_Init:
	ld a, [wSfx1Playing]
	cp $1a
	jp z, Sfx1_Refuse
	ld hl, Sfx1_1B_Data_474D
	jp Sfx1_StartPriority

Sfx1_1B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_1B_Data_4753
	jp Sfx1_WritePeriod

Sfx1_1B_Data_474D:
	db $00, $80, $34, $90, $87, $01
Sfx1_1B_Data_4753:
	db $c8, $07, $04
; = LA Sfx1_1B
Sfx1_1C_Init:
	ld a, $03
	ld [wSfx1Counter], a
	ld hl, Sfx1_1C_Data_47A1
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_1C_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $04
	ld [de], a
	call Sfx_IncStep
	cp $08
	jr z, .l0
	ld hl, Sfx1_1C_Data_4793
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $02
	jr z, .l1
	ld hl, Sfx1_1C_Data_47AD
.l2:
	call Sfx1_LoadPitch
	ld a, $04
	ld [bc], a
	jp SetRegs_Ch1

.l1:
	ld hl, Sfx1_1C_Data_47A7
	jr .l2

Sfx1_1C_Data_4793:
	db $00, $2a
	db $00, $2e
	db $00, $25
	db $00, $07
	db $00, $15
	db $00, $17
	db $00, $13
Sfx1_1C_Data_47A1:
	db $00, $00, $4c, $f7, $86, $04
Sfx1_1C_Data_47A7:
	db $00, $40, $40, $7b, $87, $04
Sfx1_1C_Data_47AD:
	db $00, $80, $10, $7b, $87, $04
; = LA Sfx1_1C
Sfx1_1D_Init:
	ld a, $2c
	ld [wSfx1Counter], a
	ld hl, Sfx1_1D_Data_4801
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_1D_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	cp $05
	jr z, .l1
.l3:
	ld hl, Sfx1_1D_Data_47F9
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	cp $18
	jr z, .l2
	cp $17
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l3

.l2:
	ld a, $02
	ld [bc], a
	ld hl, Sfx1_1D_Data_4807
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l1:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $03
	ld [bc], a
	jr .l3

Sfx1_1D_Data_47F9:
	db $00, $ae
	db $ff, $60
	db $00, $aa
	db $ff, $60
Sfx1_1D_Data_4801:
	db $00, $40, $0c, $00, $85, $01
Sfx1_1D_Data_4807:
	db $00, $40, $a4, $40, $86, $01
; = LA Sfx1_1D
Sfx1_1E_Init:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_1E_Data_483F
	jp Sfx1_Start

Sfx1_1E_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $79
	ldh [rNR11], a
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx1_1E_Data_483B
	call GetPointer
	jp Sfx1_WritePeriod

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $02
	ld [bc], a
	jr .l1

Sfx1_1E_Data_483B:
	dw Sfx1_1E_Data_4845, Sfx1_1E_Data_4842
Sfx1_1E_Data_483F:
	db $00, $79, $e0
Sfx1_1E_Data_4842:
	db $c0, $c4, $02
Sfx1_1E_Data_4845:
	db $c0, $c4, $0c
; = LA Sfx1_1E
Sfx1_1F_Init:
	ld hl, Sfx1_1F_Data_486B
	jp Sfx1_StartPriority

Sfx1_1F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_1F_Data_4863
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_1F_Data_4863:
	dw Sfx1_1F_Data_4871, Sfx1_1F_Data_4871, Sfx1_1F_Data_4874, Sfx1_1F_Data_4874
Sfx1_1F_Data_486B:
	db $1f, $a6, $e1, $00, $c7, $10
Sfx1_1F_Data_4871:
	db $a0, $c6, $09
Sfx1_1F_Data_4874:
	db $00, $c6, $18
; = LA Sfx1_1F
Sfx1_20_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_20_Data_48AD
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_20_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx1_20_Data_489D
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_20_Data_489D:
	db $00, $30
	db $00, $60
	db $00, $60
	db $00, $30
	db $ff, $c0
	db $ff, $80
	db $ff, $80
	db $ff, $c0
Sfx1_20_Data_48AD:
	db $00, $80, $0b, $20, $86, $01
; = LA Sfx1_20
Sfx1_21_Init:
	ld a, [wSfx1Playing]
	cp $20
	jr z, .l0
	and a
	jp nz, Sfx1_Refuse
.l0:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_21_Data_48E8
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_21_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l1
.l2:
	ld hl, Sfx1_21_Data_48E4
	jp Sfx1_AddPitch

.l1:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_21_Data_48E4:
	db $00, $c0
	db $ff, $a0
Sfx1_21_Data_48E8:
	db $00, $80, $f1, $80, $83, $01
; = LA Sfx1_21
Sfx1_22_Init:
	ld a, $1c
	ld [wSfx1Counter], a
	ld hl, Sfx1_22_Data_4934
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_22_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l3:
	ld hl, Sfx1_22_Data_4932
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $14
	jr z, .l1
	cp $0a
	jr z, .l2
	ld a, $01
	ld [bc], a
	jr .l3

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_22_Data_493A
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_22_Data_4940
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_22_Data_4932:
	db $ff, $ff
Sfx1_22_Data_4934:
	db $00, $00, $19, $b0, $87, $01
Sfx1_22_Data_493A:
	db $00, $00, $62, $a7, $87, $01
Sfx1_22_Data_4940:
	db $00, $00, $10, $a7, $87, $01
; = LA Sfx1_22
Sfx1_23_Init:
	ld a, [wSfx1Playing]
	cp $22
	jp z, Sfx1_Refuse
	ld bc, wSfx1Var3
	call Sfx_IncStep
	cp $04
	jr nc, .l0
.l8:
	ld hl, Sfx1_23_Data_4992
	jp Sfx1_Start

.l0:
	cp $06
	jr nc, .l1
.l7:
	ld hl, Sfx1_23_Data_4998
	jp Sfx1_Start

.l1:
	cp $08
	jr nc, .l2
.l5:
	ld hl, Sfx1_23_Data_499E
	jp Sfx1_Start

.l2:
	cp $09
	jr nc, .l3
	ld hl, Sfx1_23_Data_49A4
	jp Sfx1_Start

.l3:
	cp $0b
	jr nc, .l4
	jr .l5

.l4:
	cp $0d
	jr z, .l6
	jp .l7

.l6:
	ld a, $01
	ld [bc], a
	jp .l8

Sfx1_23_Play:
	jp Sfx1_Stop

Sfx1_23_Data_4992:
	db $15, $38, $30, $40, $c6, $02
Sfx1_23_Data_4998:
	db $15, $38, $40, $3c, $c6, $02
Sfx1_23_Data_499E:
	db $15, $38, $60, $38, $c6, $02
Sfx1_23_Data_49A4:
	db $15, $38, $90, $34, $c6, $02
	db $15, $38, $d0, $30, $c6, $02
; = LA Sfx1_23
Sfx1_24_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_24_Data_49ED
	jp Sfx1_StartPriority

Sfx1_24_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jr z, .l0
	ld hl, Sfx1_24_Data_49DF
	call GetPointer
	ld a, [wSfx1Step]
	and $01
	jp nz, SetRegs_Ch2
	jp SetRegs_Ch1

.l0:
	ld hl, wCh2Flags
	res 7, [hl]
	jp Sfx1_StopWithRegs

Sfx1_24_Data_49DF:
	dw Sfx1_24_Data_49F3, Sfx1_24_Data_49F8, Sfx1_24_Data_49FE, Sfx1_24_Data_4A03, Sfx1_24_Data_4A09, Sfx1_24_Data_4A0E, Sfx1_24_Data_4A14
Sfx1_24_Data_49ED:
	db $00, $80, $e2, $a7, $87, $09
Sfx1_24_Data_49F3:
	db $80, $e2, $a2, $87, $08
Sfx1_24_Data_49F8:
	db $00, $80, $e2, $90, $87
	db $08
Sfx1_24_Data_49FE:
	db $80, $e2, $7b, $87, $08
Sfx1_24_Data_4A03:
	db $00, $80, $b2, $59, $87
	db $09
Sfx1_24_Data_4A09:
	db $80, $e2, $97, $87, $0a
Sfx1_24_Data_4A0E:
	db $00, $80, $e2, $ac, $87
	db $0b
Sfx1_24_Data_4A14:
	db $80, $e2, $be, $87, $10
; = LA Sfx1_24
Sfx1_25_Init:
	ld hl, Sfx1_25_Data_4A26
	jp Sfx1_Start

Sfx1_25_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_25_Data_4A26:
	db $27, $80, $83, $00, $86, $18
; = LA Sfx1_25
Sfx1_26_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_26_Data_4A6B
	jp Sfx1_StartPriority

Sfx1_26_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jr z, .l0
	cp $07
	jr z, .l1
.l2:
	ld hl, Sfx1_26_Data_4A5F
	call GetPointer
	jp Sfx1_WritePeriod

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $06
	ld [bc], a
	jr .l2

.l1:
	ld a, $03
	ld [bc], a
	jr .l2

Sfx1_26_Data_4A5F:
	dw Sfx1_26_Data_4A71, Sfx1_26_Data_4A74, Sfx1_26_Data_4A77, Sfx1_26_Data_4A7A, Sfx1_26_Data_4A7D, Sfx1_26_Data_4A80
Sfx1_26_Data_4A6B:
	db $00, $80, $a5, $06, $87, $02
Sfx1_26_Data_4A71:
	db $21, $07, $02
Sfx1_26_Data_4A74:
	db $39, $07, $02
Sfx1_26_Data_4A77:
	db $4f, $07, $02
Sfx1_26_Data_4A7A:
	db $62, $07, $02
Sfx1_26_Data_4A7D:
	db $74, $07, $02
Sfx1_26_Data_4A80:
	db $06, $07, $02
; = LA Sfx1_26
Sfx1_27_Init:
	ld a, $0e
	ld [wSfx1Counter], a
	ld hl, Sfx1_27_Data_4AC5
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_27_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $03
	ld [de], a
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l2:
	ld hl, Sfx1_27_Data_4ABF
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $09
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_27_Data_4ACB
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_27_Data_4ABF:
	db $ff, $e0
	db $00, $20
	db $ff, $fc
Sfx1_27_Data_4AC5:
	db $00, $00, $0c, $f0, $87, $03
Sfx1_27_Data_4ACB:
	db $00, $00, $a7, $dc, $87, $03
; = LA Sfx1_27
Sfx1_28_Init:
	ld hl, Sfx1_28_Data_4AEB
	jp Sfx1_Start

Sfx1_28_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld a, $1e
	ldh [rNR10], a
	ld a, $18
	ld [de], a
	ret

Sfx1_28_Data_4AEB:
	db $14, $40, $c0, $00, $81, $0c
; = LA Sfx1_28
Sfx1_29_Init:
	ld hl, Sfx1_29_Data_4B1E
	jp Sfx1_Start

Sfx1_29_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_29_Data_4B10
	call GetPointer
	ld a, $bd
	ldh [rNR11], a
	jp Sfx1_WritePeriod

Sfx1_29_Data_4B10:
	dw Sfx1_29_Data_4B24, Sfx1_29_Data_4B27, Sfx1_29_Data_4B2A, Sfx1_29_Data_4B2D, Sfx1_29_Data_4B30, Sfx1_29_Data_4B33, Sfx1_29_Data_4B36
Sfx1_29_Data_4B1E:
	db $00, $bd, $f0, $e0, $c7, $0c
Sfx1_29_Data_4B24:
	db $e0, $c7, $03
Sfx1_29_Data_4B27:
	db $c0, $c7, $03
Sfx1_29_Data_4B2A:
	db $a0, $c7, $04
Sfx1_29_Data_4B2D:
	db $80, $c7, $04
Sfx1_29_Data_4B30:
	db $60, $c7, $05
Sfx1_29_Data_4B33:
	db $40, $c7, $06
Sfx1_29_Data_4B36:
	db $20, $c7, $03
; = LA Sfx1_29
Sfx1_2A_Init:
	ld hl, Sfx1_2A_Data_4B53
	jp Sfx1_Start

Sfx1_2A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld a, $1e
	ldh [rNR10], a
	ld a, $06
	ld [de], a
	ret

Sfx1_2A_Data_4B53:
	db $17, $96, $49, $60, $c6, $04
; = LA Sfx1_2A
Sfx1_2B_Init:
	ld hl, Sfx1_2B_Data_4B66
	jp Sfx1_Start

Sfx1_2B_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_StopWithRegs

Sfx1_2B_Data_4B66:
	db $16, $00, $f0, $00, $c2, $10
; = LA Sfx1_2B
Sfx1_2C_Init:
	ld a, $2c
	ld [wSfx1Counter], a
	ld hl, Sfx1_2C_Data_4BB5
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2C_Play:
	call Sfx_IncStep
	cp $0b
	jr z, .l0
.l2:
	ld hl, Sfx1_2C_Data_4BA1
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $0c
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_2C_Data_4BBB
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_2C_Data_4BA1:
	db $00, $08
	db $ff, $f0
	db $00, $08
	db $ff, $fc
	db $00, $06
	db $ff, $f8
	db $00, $06
	db $ff, $fa
	db $00, $08
	db $ff, $ff
Sfx1_2C_Data_4BB5:
	db $00, $00, $0f, $d0, $87, $02
Sfx1_2C_Data_4BBB:
	db $00, $00, $f7, $f0, $87, $04
; = LA Sfx1_2C
Sfx1_2D_Init:
	ld a, $22
	ld [wSfx1Counter], a
	ld hl, Sfx1_2D_Data_4C0F
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_2D_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l3:
	ld hl, Sfx1_2D_Data_4C03
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $1e
	jr z, .l1
	cp $06
	jr z, .l2
	ld a, $01
	ld bc, wSfx1Step
	ld [bc], a
	jr .l3

.l1:
	ld hl, Sfx1_2D_Data_4C15
.l4:
	ld a, $01
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l2:
	ld hl, Sfx1_2D_Data_4C1B
	jr .l4

Sfx1_2D_Data_4C03:
	db $00, $02
	db $00, $01
	db $ff, $f0
	db $ff, $e0
	db $ff, $c0
	db $00, $71
Sfx1_2D_Data_4C0F:
	db $00, $00, $0f, $00, $87, $01
Sfx1_2D_Data_4C15:
	db $00, $00, $40, $10, $87, $01
Sfx1_2D_Data_4C1B:
	db $00, $00, $47, $70, $87, $01
; = LA Sfx1_2D
Sfx1_2E_Init:
	ld a, $03
	ld [wSfx1Counter], a
	ld hl, Sfx1_2E_Data_4C60
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_2E_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $08
	ld [de], a
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l2:
	ld hl, Sfx1_2E_Data_4C58
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $01
	jr z, .l1
.l3:
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld a, $65
	ldh [rNR12], a
	jr .l3

Sfx1_2E_Data_4C58:
	db $00, $04
	db $ff, $dd
	db $00, $06
	db $00, $19
Sfx1_2E_Data_4C60:
	db $00, $80, $1f, $b6, $87, $08
; = LA Sfx1_2E
Sfx1_2F_Init:
	ld a, $09
	ld [wSfx1Counter], a
	ld hl, Sfx1_2F_Data_4CEB
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2F_Play:
	call Sfx_IncStep
	cp $29
	jr z, .l0
.l2:
	ld hl, Sfx1_2F_Data_4C9B
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $03
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx1_2F_Data_4CF1
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_2F_Data_4C9B:
	db $00, $30
	db $00, $30
	db $00, $30
	db $00, $30
	db $00, $28
	db $00, $28
	db $00, $28
	db $00, $28
	db $00, $20
	db $00, $20
	db $00, $20
	db $00, $20
	db $00, $18
	db $00, $18
	db $00, $18
	db $00, $18
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $10
	db $ff, $f0
	db $ff, $f0
	db $ff, $f0
	db $ff, $f0
	db $ff, $e8
	db $ff, $e8
	db $ff, $e8
	db $ff, $e8
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $d8
	db $ff, $d8
	db $ff, $d8
	db $ff, $d8
	db $ff, $d0
	db $ff, $d0
	db $ff, $d0
	db $ff, $d0
Sfx1_2F_Data_4CEB:
	db $00, $80, $1d, $00, $81, $10
Sfx1_2F_Data_4CF1:
	db $00, $80, $f7, $00, $81, $10
; = LA Sfx1_2F
Sfx1_30_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_30_Data_4D29
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_30_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_30_Data_4D1D
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_30_Data_4D1D:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx1_30_Data_4D29:
	db $00, $80, $f2, $00, $85, $01
; = LA Sfx1_30
Sfx1_31_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_31_Data_4D4A
	jp Sfx1_Start

Sfx1_31_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld hl, Sfx1_31_Data_4D4A
	jp SetRegs_Ch1

Sfx1_31_Data_4D4A:
	db $17, $bc, $64, $44, $c7, $02
; = LA Sfx1_31
Sfx1_32_Init:
	ld a, $14
	ld [wSfx1Counter], a
	ld hl, Sfx1_32_Data_4D8A
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_32_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_32_Data_4D86
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	cp $10
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	ld hl, Sfx1_32_Data_4D90
	ld a, $01
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_32_Data_4D86:
	db $ff, $fc
	db $00, $02
Sfx1_32_Data_4D8A:
	db $00, $00, $19, $ea, $87, $01
Sfx1_32_Data_4D90:
	db $00, $00, $47, $e0, $87, $01
; = LA Sfx1_32
Sfx1_33_Init:
	ld hl, Sfx1_33_Data_4DB5
	jp Sfx1_StartPriority

Sfx1_33_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, $53b5	; LA's address of Sfx1_StopWithRegs, not relocated: here $53B5 is inside a jump table
	ld hl, Sfx1_33_Data_4DB1
	call GetPointer
	jp SetRegs_Ch1

Sfx1_33_Data_4DB1:
	dw Sfx1_33_Data_4DBB, Sfx1_33_Data_4DC1
Sfx1_33_Data_4DB5:
	db $1f, $80, $85, $a0, $87, $0c
Sfx1_33_Data_4DBB:
	db $1f, $80, $47, $a0, $87, $0c
Sfx1_33_Data_4DC1:
	db $1f, $8d, $20, $a0, $c7, $0c
; = LA Sfx1_33
Sfx1_34_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_34_Data_4E04
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_34_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $08
	ld [de], a
	call Sfx_IncStep
	cp $04
	jr z, .l0
	cp $05
	jr z, .l1
.l2:
	ld hl, Sfx1_34_Data_4DFC
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $04
.l3:
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	jr .l3

Sfx1_34_Data_4DFC:
	db $00, $08
	db $ff, $fd
	db $00, $03
	db $ff, $f8
Sfx1_34_Data_4E04:
	db $00, $00, $60, $d1, $87, $08
; = LA Sfx1_34
Sfx1_35_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_35_Data_4E57
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_35_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx1_35_Data_4E45
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $09
	jr z, .l2
	jr .l3

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_35_Data_4E5D
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

Sfx1_35_Data_4E45:
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $ff, $fa
Sfx1_35_Data_4E57:
	db $00, $00, $1f, $d0, $87, $01
Sfx1_35_Data_4E5D:
	db $00, $00, $a7, $d8, $87, $01
; = LA Sfx1_35
Sfx1_36_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_36_Data_4EB8
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_36_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx1_36_Data_4EA6
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $03
	jr z, .l2
	ld a, [bc]
	jr .l3

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_36_Data_4EBE
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_36_Data_4EA6:
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $0c
	db $00, $08
	db $00, $04
	db $00, $02
	db $ff, $a2
Sfx1_36_Data_4EB8:
	db $00, $80, $1f, $a0, $86, $02
Sfx1_36_Data_4EBE:
	db $00, $80, $87, $a0
; = LA Sfx1_36
Sfx1_37_Init:
	ld a, $0b
	ld [wSfx1Counter], a
	ld hl, Sfx1_37_Data_4F2D
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_37_Play:
	call Sfx1_DecCounter
	jr z, .l0
.l7:
	ld a, [wSfx1Var5]
	cp $0d
	jr nc, .l1
	and $01
	jr nz, .l2
	ld a, $01
.l3:
	ld [bc], a
	ld hl, Sfx1_37_Data_4F25
	jp Sfx1_AddPitch

.l2:
	ld a, $02
	jr .l3

.l1:
	and $01
	jr nz, .l4
	ld a, $03
	jr .l3

.l4:
	ld a, $04
	jr .l3

.l0:
	push bc
	ld bc, wSfx1Var5
	call Sfx_IncStep
	pop bc
	cp $05
	jr z, .l5
	cp $22
	jp z, Sfx1_StopWithRegs
	cp $11
	jr nc, .l6
.l8:
	sra a
	ld e, a
	ld a, $0b
	sub e
	ld [wSfx1Counter], a
	jr .l7

.l5:
	ld a, $a0
	ldh [rNR12], a
	ld a, $05
	jr .l8

.l6:
	ld a, $11
	jr .l8

Sfx1_37_Data_4F25:
	db $00, $20
	db $ff, $e8
	db $00, $1c
	db $ff, $f0
Sfx1_37_Data_4F2D:
	db $00, $40, $1f, $80, $83, $01
; = LA Sfx1_37
Sfx1_38_Init:
	ld a, $10
	ld [wSfx1Counter], a
	ld hl, Sfx1_38_Data_4F74
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_38_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_38_Data_4F62
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $09
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_38_Data_4F62:
	db $00, $40
	db $00, $30
	db $00, $20
	db $ff, $e0
	db $ff, $d0
	db $ff, $c0
	db $ff, $a0
	db $ff, $80
	db $00, $d0
Sfx1_38_Data_4F74:
	db $00, $80, $80, $00, $86, $01
; = LA Sfx1_38
Sfx1_39_Init:
	ld a, [wSfx1Playing]
	and a
	jp nz, Sfx1_Refuse
	ld a, [wSfx1Var2]
	and a
	jr nz, .l0
	ld hl, Sfx1_39_Data_4FC0
.l1:
	call Sfx1_LoadPitch
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_39_Data_4FC6
	jr .l1

Sfx1_39_Play:
	call Sfx_IncStep
	cp $0b
	jr z, .l2
	ld hl, Sfx1_39_Data_4FAC
	jp Sfx1_AddPitch

.l2:
	ld hl, wSfx1Request
	ld a, $38
	ld [hl+], a
	xor a
	ld [hl], a
	jr Sfx1_39_Init

Sfx1_39_Data_4FAC:
	db $00, $c0
	db $00, $90
	db $00, $60
	db $00, $30
	db $00, $18
	db $ff, $e8
	db $ff, $d0
	db $ff, $a0
	db $ff, $70
	db $ff, $40
Sfx1_39_Data_4FC0:
	db $00, $80, $a0, $00, $82, $01
Sfx1_39_Data_4FC6:
	db $00, $80, $c0, $00, $83, $01
; = LA Sfx1_39
Sfx1_3A_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_3A_Data_5052
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_3A_Play:
	call Sfx_IncStep
	cp $0e
	jr z, .l0
	cp $0f
	jr z, .l1
.l3:
	ld a, [wSfx1Counter]
	cp $03
	jr c, .l2
	ld hl, Sfx1_3A_Data_501A
	jp Sfx1_AddPitch

.l2:
	ld hl, Sfx1_3A_Data_5036
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $0e
	ld [bc], a
	jr .l3

.l1:
	ld a, [wSfx1Counter]
	cp $01
	jr z, .l4
	ld a, $01
	ld [bc], a
	jr .l3

.l4:
	xor a
	ld [bc], a
	ld hl, Sfx1_3A_Data_5058
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3A_Data_501A:
	db $00, $c0
	db $00, $a0
	db $00, $80
	db $00, $60
	db $00, $40
	db $00, $20
	db $ff, $e0
	db $ff, $e0
	db $ff, $d0
	db $ff, $d0
	db $ff, $c0
	db $ff, $c0
	db $ff, $b0
	db $ff, $b0
Sfx1_3A_Data_5036:
	db $00, $60
	db $00, $50
	db $00, $40
	db $00, $30
	db $00, $20
	db $00, $10
	db $ff, $f0
	db $ff, $f0
	db $ff, $f0
	db $ff, $f0
	db $ff, $e0
	db $ff, $e0
	db $ff, $d0
	db $ff, $d0
Sfx1_3A_Data_5052:
	db $00, $40, $4d, $80, $83, $01
Sfx1_3A_Data_5058:
	db $00, $80, $20, $c0, $84, $01
; = LA Sfx1_3A
Sfx1_3B_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_3B_Data_509F
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3B_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_3B_Data_508D
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $09
	ld [bc], a
	jr .l2

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_3B_Data_508D:
	db $00, $12
	db $00, $0e
	db $00, $0a
	db $00, $08
	db $00, $06
	db $00, $04
	db $00, $02
	db $00, $01
	db $ff, $c1
Sfx1_3B_Data_509F:
	db $00, $00, $a4, $00, $87, $01
; = LA Sfx1_3B
Sfx1_3C_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_3C_Data_50EC
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3C_Play:
	call Sfx_IncStep
	cp $0c
	jr z, .l0
	cp $0d
	jr z, .l1
.l2:
	ld hl, Sfx1_3C_Data_50D4
	jp Sfx1_AddPitch

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $0c
	ld [bc], a
	jr .l2

Sfx1_3C_Data_50D4:
	db $ff, $c0
	db $ff, $a0
	db $00, $80
	db $ff, $c0
	db $ff, $a0
	db $00, $80
	db $ff, $c0
	db $ff, $a0
	db $00, $80
	db $ff, $c0
	db $ff, $a0
	db $01, $00
Sfx1_3C_Data_50EC:
	db $00, $00, $87, $80, $87, $01
; = LA Sfx1_3C
Sfx1_3D_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_3D_Data_512E
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3D_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	ld hl, Sfx1_3D_Data_511E
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx1_3D_Data_5134
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3D_Data_511E:
	db $00, $02
	db $00, $02
	db $00, $02
	db $00, $02
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
Sfx1_3D_Data_512E:
	db $00, $00, $60, $d0, $87, $02
Sfx1_3D_Data_5134:
	db $00, $40, $10, $d0, $87, $01
; = LA Sfx1_3D
Sfx1_3E_Init:
	ld a, [wSfx1Playing]
	cp $04
	jp z, Sfx1_Refuse
	cp $05
	jp z, Sfx1_Refuse
	cp $07
	jp z, Sfx1_Refuse
	cp $03
	jp z, Sfx1_Refuse
	cp $0d
	jp z, Sfx1_Refuse
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_3E_Data_51A1
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3E_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
	cp $05
	jr z, .l1
.l2:
	ld hl, Sfx1_3E_Data_5199
	jp Sfx1_AddPitch

.l1:
	ld a, $01
	ld [bc], a
	jr .l2

.l0:
	call Sfx1_DecCounter
	jp z, .l3
	cp $07
	jr z, .l4
	jr .l2

.l4:
	xor a
	ld [bc], a
	ld hl, Sfx1_3E_Data_51A7
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l3:
	ld a, $3e
	ld [wSfx1Request], a
	jp Sfx1_3E_Init

Sfx1_3E_Data_5199:
	db $00, $c0
	db $00, $80
	db $00, $40
	db $fe, $80
Sfx1_3E_Data_51A1:
	db $00, $40, $19, $80, $83, $01
Sfx1_3E_Data_51A7:
	db $00, $40, $86, $80, $83, $01
; = LA Sfx1_3E
Sfx1_3F_Init:
	ld a, [wSfx1Playing]
	cp $3e
	jp z, Sfx1_Refuse
	ld hl, Sfx1_3F_Data_51C2
	jp Sfx1_Start

Sfx1_3F_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_3F_Data_51C2:
	db $27, $be, $60, $c0, $c7, $03
; = LA Sfx1_3F
Sfx1_40_Init:
	ld a, $09
	ld [wSfx1Counter], a
	ld hl, Sfx1_40_Data_520C
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_40_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	cp $04
	jr z, .l1
.l3:
	ld hl, Sfx1_40_Data_5206
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $06
	jr z, .l2
	ld a, $03
	ld [bc], a
	jr .l3

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_40_Data_5212
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_40_Data_5206:
	db $00, $60
	db $00, $40
	db $ff, $70
Sfx1_40_Data_520C:
	db $00, $80, $19, $00, $86, $01
Sfx1_40_Data_5212:
	db $00, $80, $d1, $10, $86, $01
; = LA Sfx1_40
Sfx1_41_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_41_Data_526A
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_41_Play:
	call Sfx1_DecCounter
	jr z, .l0
.l4:
	ld a, [wSfx1Var5]
	cp $06
	jr nc, .l1
	ld a, $01
.l2:
	ld [bc], a
	ld hl, Sfx1_41_Data_5266
	jp Sfx1_AddPitch

.l1:
	ld a, $02
	jr .l2

.l0:
	push bc
	ld bc, wSfx1Var5
	call Sfx_IncStep
	pop bc
	cp $14
	jp z, Sfx1_Stop
	cp $06
	jp z, .l3
	ld a, $04
	ld [wSfx1Counter], a
	jr .l4

.l3:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_41_Data_5270
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_41_Data_5266:
	db $00, $10
	db $ff, $f8
Sfx1_41_Data_526A:
	db $00, $80, $1a, $80, $82, $01
Sfx1_41_Data_5270:
	db $00, $80, $e5, $10, $84, $01
	db $21, $9f, $52, $c3, $d9, $52
	db $cd, $a9, $79, $c0, $cd, $ad
	db $79, $fe, $08, $ca, $ff, $52
	db $21, $91, $52, $cd, $9c, $79
	db $c3, $b1, $79, $b7, $52, $a5
	db $52, $bd, $52, $ab, $52, $c3
	db $52, $b1, $52, $c9, $52, $00
	db $00, $c1, $7b, $87, $06, $00
	db $00, $c1, $8a, $87, $06, $00
	db $00, $c1, $90, $87, $07, $00
	db $00, $c1, $b6, $87, $07, $00
	db $00, $62, $7b, $87, $04, $00
	db $00, $62, $8a, $87, $04, $00
	db $00, $62, $90, $87, $04, $00
	db $00, $62, $b6, $87, $04, $3e
	db $01, $ea, $a0, $d3, $3e, $01
	db $ea, $c6, $d3
; Start a ch1 effect: hl = 5 register bytes (NR10-NR14) + frames. The music channel is
; flagged as taken (wCh1Flags bit 7). Priority: later requests are refused until it ends.
Sfx1_StartPriority:
	ld a, $01
	ld [wSfx1Priority], a
Sfx1_Start:
	ld a, [wSfx1Request]
	ld [wSfx1Playing], a
	xor a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld [wSfx1Var5], a
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	jp SetRegs_Ch1

; End a ch1 effect: optionally write a register image first, then give ch1 back to the
; music.
Sfx1_StopWithRegs:
	ld hl, Sfx1_StopRegs
	call SetRegs_Ch1
Sfx1_Stop:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx1Timer], a
	ldh [rNR10], a
	ld [wSfx1Step], a
	ld [wSfx1Counter], a
	ld [wSfx1Var], a
	ld [wSfx1Priority], a
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

Sfx1_StopRegs:
	db $00, $3f, $00, $00, $c1, $01
	db $06, $02, $0e, $13, $c3, $91
	db $7a
Sfx1_WritePeriod:
	ld b, $02
	ld c, $13
	jp SetRegs_Copy

; A refused request is dropped and the playing effect continues.
Sfx1_Refuse:
	xor a
	ld [wSfx1Request], a
	jp Sfx1_Update

