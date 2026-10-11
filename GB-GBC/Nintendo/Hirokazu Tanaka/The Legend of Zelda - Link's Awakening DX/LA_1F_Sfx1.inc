; Link's Awakening DX SFX, bank $1F: ch1 effects, bank $1F $4204-$53EC

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
	jr .dispatch

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
	ld hl, Sfx1_01_Data_42EB
	call SetRegs_Ch2
	call Sfx3_LoadWave639C
	ld hl, Sfx1_01_Data_42FF
	call SetRegs_Ch3
	ld hl, Sfx1_01_Data_42D3
	jp Sfx1_StartPriority

Sfx1_01_Play:
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
	ld hl, Sfx1_01_Data_42D9
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_42F0
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4305
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx1_01_Data_42DF
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_42F5
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_430B
	jp SetRegs_Ch3

.l2:
	ld hl, Sfx1_01_Data_42E5
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_42FA
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4311
	jp SetRegs_Ch3

.l3:
	ld hl, Sfx1_01_Data_4317
	call SetRegs_Ch1
	ld hl, Sfx1_01_Data_431D
	call SetRegs_Ch2
	ld hl, Sfx1_01_Data_4317
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

Sfx1_01_Data_42D3:
	db $00, $80, $80, $89, $86, $0a
Sfx1_01_Data_42D9:
	db $00, $80, $80, $9e, $86, $0a
Sfx1_01_Data_42DF:
	db $00, $80, $80, $b2, $86, $0a
Sfx1_01_Data_42E5:
	db $00, $80, $80, $c4, $86, $30
Sfx1_01_Data_42EB:
	db $00, $c0, $06, $87, $0a
Sfx1_01_Data_42F0:
	db $00, $c0, $14, $87, $0a
Sfx1_01_Data_42F5:
	db $00, $c0, $21, $87, $0a
Sfx1_01_Data_42FA:
	db $00, $c0, $2d, $87, $30
Sfx1_01_Data_42FF:
	db $80, $00, $20, $6b, $87, $0a
Sfx1_01_Data_4305:
	db $80, $00, $20, $73, $87, $0a
Sfx1_01_Data_430B:
	db $80, $00, $20, $7b, $87, $0a
Sfx1_01_Data_4311:
	db $80, $00, $20, $83, $87, $30
Sfx1_01_Data_4317:
	db $00, $00, $00, $00, $c0, $20
Sfx1_01_Data_431D:
	db $3f, $00, $00, $c1, $20
Sfx1_02_Init:
	ld hl, Sfx1_02_Data_4353
	jp Sfx1_StartPriority

Sfx1_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_02_Data_4345
	call GetPointer
	ld a, $80
	ldh [rNR11], a
	ld a, $f1
	ldh [rNR12], a
	jp Sfx1_WritePeriod

Sfx1_02_Data_4345:
	dw Sfx1_02_Data_4359, Sfx1_02_Data_435C, Sfx1_02_Data_435F, Sfx1_02_Data_4362, Sfx1_02_Data_4365, Sfx1_02_Data_4368, Sfx1_02_Data_436B
Sfx1_02_Data_4353:
	db $00, $80, $f1, $a7, $c7, $08
Sfx1_02_Data_4359:
	db $a2, $c7, $08
Sfx1_02_Data_435C:
	db $90, $c7, $08
Sfx1_02_Data_435F:
	db $7b, $c7, $08
Sfx1_02_Data_4362:
	db $59, $c7, $08
Sfx1_02_Data_4365:
	db $97, $c7, $08
Sfx1_02_Data_4368:
	db $ac, $c7, $08
Sfx1_02_Data_436B:
	db $be, $c7, $20
Sfx1_03_Init:
	ld hl, Sfx1_03_Data_439D
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_03_Play:
	call Sfx_IncStep
	cp $0d
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_03_Data_4385
	jp Sfx1_AddPitch

Sfx1_03_Data_4385:
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
Sfx1_03_Data_439D:
	db $00, $00, $c0, $80, $86, $01
Sfx1_04_Init:
	ld a, $0e
	ld [wSfx1Counter], a
	ld hl, Sfx1_04_Data_43DC
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
	ld hl, Sfx1_04_Data_43D8
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_04_Data_43D8:
	db $00, $20
	db $ff, $f0
Sfx1_04_Data_43DC:
	db $00, $80, $87, $c0, $86, $02
Sfx1_05_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_05_Data_4417
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
	ld hl, Sfx1_05_Data_440F
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_05_Data_440F:
	db $00, $06
	db $00, $04
	db $00, $02
	db $ff, $f4
Sfx1_05_Data_4417:
	db $00, $00, $c5, $d8, $87, $04
Sfx1_06_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_06_Data_4453
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_06_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx1_06_Data_4443
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_06_Data_4443:
	db $00, $40
	db $00, $80
	db $00, $80
	db $00, $40
	db $ff, $d0
	db $ff, $a0
	db $ff, $a0
	db $ff, $d0
Sfx1_06_Data_4453:
	db $00, $80, $1b, $00, $82, $01
Sfx1_07_Init:
	ld hl, Sfx1_07_Data_4471
	jp Sfx1_Start

Sfx1_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_07_Data_4477
	jp SetRegs_Ch1

Sfx1_07_Data_4471:
	db $00, $3d, $f0, $d8, $c7, $03
Sfx1_07_Data_4477:
	db $00, $00, $81, $e0, $87, $08
Sfx1_08_Init:
	ld hl, Sfx1_08_Data_4495
	jp Sfx1_Start

Sfx1_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_08_Data_449B
	jp SetRegs_Ch1

Sfx1_08_Data_4495:
	db $3f, $9e, $29, $80, $c7, $08
Sfx1_08_Data_449B:
	db $1f, $9f, $81, $20, $87, $10
Sfx1_09_Init:
	ld hl, Sfx1_09_Data_44C8
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_09_Play:
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_09_Data_44B8
	jp Sfx1_AddPitch

Sfx1_09_Data_44B8:
	db $01, $00
	db $00, $c0
	db $00, $80
	db $00, $40
	db $ff, $c0
	db $ff, $80
	db $ff, $40
	db $ff, $00
Sfx1_09_Data_44C8:
	db $00, $9f, $a0, $00, $c2, $01
Sfx1_0A_Init:
	ld a, [wSfx1Playing]
	cp $13
	jp z, Sfx1_Refuse
	ldh a, [rNR50]
	cp $77
	jr nz, .l0
	ld hl, Sfx1_0A_Data_4509
.l1:
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_0A_Data_450F
	jr .l1

Sfx1_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ldh a, [rNR50]
	cp $77
	jr nz, .l2
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
	jr .l3

Sfx1_0A_Data_4509:
	db $00, $9f, $80, $a0, $c7, $02
Sfx1_0A_Data_450F:
	db $00, $9f, $f0, $a0, $c7, $02
Sfx1_0B_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_0B_Data_454E
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
	ld hl, Sfx1_0B_Data_4542
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_0B_Data_4542:
	db $ff, $c0
	db $ff, $80
	db $ff, $40
	db $00, $c0
	db $00, $80
	db $00, $40
Sfx1_0B_Data_454E:
	db $00, $80, $f4, $80, $83, $01
Sfx1_0C_Init:
	ld a, $16
	ld [wSfx1Counter], a
	ld hl, Sfx1_0C_Data_458F
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_0C_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l2:
	ld hl, Sfx1_0C_Data_4589
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
	ld hl, Sfx1_0C_Data_4595
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_0C_Data_4589:
	db $00, $28
	db $00, $00
	db $ff, $f0
Sfx1_0C_Data_458F:
	db $00, $83, $47, $c0, $86, $02
Sfx1_0C_Data_4595:
	db $00, $83, $47, $00, $87, $02
Sfx1_0D_Init:
	ld hl, Sfx1_0D_Data_45A8
	jp Sfx1_Start

Sfx1_0D_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_0D_Data_45A8:
	db $27, $80, $c2, $48, $86, $18
Sfx1_0E_Init:
	ld a, [wSfx1Playing]
	cp $08
	jr z, .l0
	and a
	jp nz, Sfx1_Refuse
.l0:
	ld hl, Sfx1_0E_Data_45C6
	jp Sfx1_Start

Sfx1_0E_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_0E_Data_45C6:
	db $16, $ab, $20, $80, $c6, $05
Sfx1_0F_Init:
	ld hl, Sfx1_0F_Data_45E4
	jp Sfx1_Start

Sfx1_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_0F_Data_45EA
	jp SetRegs_Ch1

Sfx1_0F_Data_45E4:
	db $17, $80, $0b, $00, $85, $10
Sfx1_0F_Data_45EA:
	db $17, $80, $0e, $00, $c5, $10
Sfx1_10_Init:
	jp Sound_Stop

Sfx1_11_Init:
	ld a, $17
	ld [wSfx1Counter], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_11_Data_4632
	call Sfx2_LoadPitch
	call SetRegs_Ch2
	ld hl, Sfx1_11_Data_4637
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_11_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l1:
	ld hl, Sfx1_11_Data_4630
	call Sfx2_AddPitch
	ld bc, wSfx1Step
	ld hl, Sfx1_11_Data_4630
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_11_Shared_463D
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_11_Data_4630:
	db $00, $21
Sfx1_11_Data_4632:
	db $45, $0c, $00, $84, $12
Sfx1_11_Data_4637:
	db $00, $85, $0b, $00, $81, $12
Sfx1_11_Shared_463D:
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, Sfx1_01_Data_431D
	call SetRegs_Ch2
	jp Sfx1_StopWithRegs

Sfx1_12_Init:
	ld a, [wSfx1Playing]
	cp $13
	jp z, Sfx1_Refuse
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_12_Data_4692
	call Sfx2_LoadPitch
	call SetRegs_Ch2
	ld hl, Sfx1_12_Data_4697
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_12_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l1:
	ld hl, Sfx1_12_Data_4690
	call Sfx2_AddPitch
	ld bc, wSfx1Step
	ld hl, Sfx1_12_Data_4690
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_11_Shared_463D
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_12_Data_4690:
	db $ff, $d0
Sfx1_12_Data_4692:
	db $40, $0a, $b0, $87, $12
Sfx1_12_Data_4697:
	db $00, $80, $09, $c0, $86, $12
Sfx1_13_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ldh a, [rNR50]
	cp $77
	jr nz, .l0
	ld hl, Sfx1_13_Data_46DB
.l1:
	call Sfx1_LoadPitch
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_13_Data_46E1
	jr .l1

Sfx1_13_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $03
	ld [de], a
	call Sfx_IncStep
	cp $04
	jr z, .l2
.l3:
	ld hl, Sfx1_13_Data_46D5
	jp Sfx1_AddPitch

.l2:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l3

Sfx1_13_Data_46D5:
	db $00, $22
	db $00, $19
	db $ff, $c5
Sfx1_13_Data_46DB:
	db $00, $80, $a4, $7b, $87, $03
Sfx1_13_Data_46E1:
	db $00, $80, $f3, $7b, $87, $03
Sfx1_14_Init:
	ld a, [wSfx1Playing]
	and a
	jp nz, Sfx1_Refuse
	ld hl, Sfx1_14_Data_46FB
	jp Sfx1_Start

Sfx1_14_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_14_Data_46FB:
	db $35, $b0, $60, $20, $c7, $04
Sfx1_15_Init:
	ld hl, Sfx1_15_Data_4720
	jp Sfx1_Start

Sfx1_15_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx1_15_Data_471C
	call GetPointer
	jp SetRegs_Ch1

Sfx1_15_Data_471C:
	dw Sfx1_15_Data_4726, Sfx1_15_Data_472C
Sfx1_15_Data_4720:
	db $00, $b0, $19, $4f, $c7, $06
Sfx1_15_Data_4726:
	db $00, $b0, $19, $7b, $c7, $06
Sfx1_15_Data_472C:
	db $00, $b0, $29, $9d, $c7, $03
Sfx1_16_Init:
	ld hl, Sfx1_16_Data_473F
	jp Sfx1_Start

Sfx1_16_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_16_Data_473F:
	db $00, $00, $81, $bb, $c7, $20
Sfx1_17_Init:
	ld a, $2a
	ld [wSfx1Counter], a
	ld hl, Sfx1_17_Data_4784
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_17_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_17_Data_477E
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
	ld hl, Sfx1_17_Data_477E
	call Sfx1_AddPitch
	xor a
	ld [wSfx1Step], a
	ret

Sfx1_17_Data_477E:
	db $00, $20
	db $ff, $e8
	db $ff, $90
Sfx1_17_Data_4784:
	db $00, $80, $d7, $68, $87, $01
Sfx1_18_Init:
	ld hl, Sfx1_18_Data_47A2
	jp Sfx1_Start

Sfx1_18_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_18_Data_47A8
	jp SetRegs_Ch1

Sfx1_18_Data_47A2:
	db $2f, $80, $60, $e0, $86, $14
Sfx1_18_Data_47A8:
	db $2f, $80, $10, $e0, $86, $14
Sfx1_19_Init:
	ld hl, Sfx1_19_Data_47D1
	jp Sfx1_StartPriority

Sfx1_19_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_19_Data_47C9
	call GetPointer
	jp SetRegs_Ch1

Sfx1_19_Data_47C9:
	dw Sfx1_19_Data_47D7, Sfx1_19_Data_47DD, Sfx1_19_Data_47E3, Sfx1_19_Data_47E9
Sfx1_19_Data_47D1:
	db $00, $80, $c1, $a7, $87, $06
Sfx1_19_Data_47D7:
	db $00, $80, $c1, $b1, $87, $06
Sfx1_19_Data_47DD:
	db $00, $80, $c1, $ba, $87, $06
Sfx1_19_Data_47E3:
	db $00, $80, $c1, $be, $87, $06
Sfx1_19_Data_47E9:
	db $00, $80, $a3, $c5, $87, $20
Sfx1_1A_Init:
	ld a, [wSfx1Playing]
	cp $1a
	jp z, Sfx1_Refuse
	ld hl, Sfx1_1A_Data_480F
	jp Sfx1_Start

Sfx1_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_1A_Data_4815
	jp Sfx1_WritePeriod

Sfx1_1A_Data_480F:
	db $00, $80, $34, $90, $87, $01
Sfx1_1A_Data_4815:
	db $c8, $07, $04
Sfx1_1B_Init:
	ld a, $03
	ld [wSfx1Counter], a
	ld hl, Sfx1_1B_Data_4863
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_1B_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $04
	ld [de], a
	call Sfx_IncStep
	cp $08
	jr z, .l0
	ld hl, Sfx1_1B_Data_4855
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	cp $02
	jr z, .l1
	ld hl, Sfx1_1B_Data_486F
.l2:
	call Sfx1_LoadPitch
	ld a, $04
	ld [bc], a
	jp SetRegs_Ch1

.l1:
	ld hl, Sfx1_1B_Data_4869
	jr .l2

Sfx1_1B_Data_4855:
	db $00, $2a
	db $00, $2e
	db $00, $25
	db $00, $07
	db $00, $15
	db $00, $17
	db $00, $13
Sfx1_1B_Data_4863:
	db $00, $00, $4c, $f7, $86, $04
Sfx1_1B_Data_4869:
	db $00, $40, $40, $7b, $87, $04
Sfx1_1B_Data_486F:
	db $00, $80, $10, $7b, $87, $04
Sfx1_1C_Init:
	ld a, $2c
	ld [wSfx1Counter], a
	ld hl, Sfx1_1C_Data_48C3
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_1C_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	cp $05
	jr z, .l1
.l3:
	ld hl, Sfx1_1C_Data_48BB
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
	ld hl, Sfx1_1C_Data_48C9
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l1:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $03
	ld [bc], a
	jr .l3

Sfx1_1C_Data_48BB:
	db $00, $ae
	db $ff, $60
	db $00, $aa
	db $ff, $60
Sfx1_1C_Data_48C3:
	db $00, $40, $0c, $00, $85, $01
Sfx1_1C_Data_48C9:
	db $00, $40, $a4, $40, $86, $01
Sfx1_1D_Init:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_1D_Data_4901
	jp Sfx1_Start

Sfx1_1D_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $79
	ldh [rNR11], a
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx1_1D_Data_48FD
	call GetPointer
	jp Sfx1_WritePeriod

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $02
	ld [bc], a
	jr .l1

Sfx1_1D_Data_48FD:
	dw Sfx1_1D_Data_4907, Sfx1_1D_Data_4904
Sfx1_1D_Data_4901:
	db $00, $79, $e0
Sfx1_1D_Data_4904:
	db $c0, $c4, $02
Sfx1_1D_Data_4907:
	db $c0, $c4, $0c
Sfx1_1E_Init:
	ld hl, Sfx1_1E_Data_492D
	jp Sfx1_StartPriority

Sfx1_1E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_1E_Data_4925
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_1E_Data_4925:
	dw Sfx1_1E_Data_4933, Sfx1_1E_Data_4933, Sfx1_1E_Data_4936, Sfx1_1E_Data_4936
Sfx1_1E_Data_492D:
	db $1f, $a6, $e1, $00, $c7, $10
Sfx1_1E_Data_4933:
	db $a0, $c6, $09
Sfx1_1E_Data_4936:
	db $00, $c6, $18
Sfx1_1F_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_1F_Data_496F
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_1F_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx1_1F_Data_495F
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_1F_Data_495F:
	db $00, $30
	db $00, $60
	db $00, $60
	db $00, $30
	db $ff, $c0
	db $ff, $80
	db $ff, $80
	db $ff, $c0
Sfx1_1F_Data_496F:
	db $00, $80, $0b, $20, $86, $01
Sfx1_20_Init:
	ld a, [wSfx1Playing]
	cp $20
	jr z, .l0
	and a
	jp nz, Sfx1_Refuse
.l0:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_20_Data_49AA
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_20_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l1
.l2:
	ld hl, Sfx1_20_Data_49A6
	jp Sfx1_AddPitch

.l1:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l2

Sfx1_20_Data_49A6:
	db $00, $c0
	db $ff, $a0
Sfx1_20_Data_49AA:
	db $00, $80, $f1, $80, $83, $01
Sfx1_21_Init:
	ld a, $1c
	ld [wSfx1Counter], a
	ld hl, Sfx1_21_Data_49F6
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_21_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l3:
	ld hl, Sfx1_21_Data_49F4
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
	ld hl, Sfx1_21_Data_49FC
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l2:
	xor a
	ld [bc], a
	ld hl, Sfx1_21_Data_4A02
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_21_Data_49F4:
	db $ff, $ff
Sfx1_21_Data_49F6:
	db $00, $00, $19, $b0, $87, $01
Sfx1_21_Data_49FC:
	db $00, $00, $62, $a7, $87, $01
Sfx1_21_Data_4A02:
	db $00, $00, $10, $a7, $87, $01
Sfx1_22_Init:
	ld a, [wSfx1Playing]
	cp $22
	jp z, Sfx1_Refuse
	ld bc, wSfx1Var3
	call Sfx_IncStep
	cp $04
	jr nc, .l0
.l8:
	ld hl, Sfx1_22_Data_4A52
	jp Sfx1_Start

.l0:
	cp $06
	jr nc, .l1
.l7:
	ld hl, Sfx1_22_Data_4A58
	jp Sfx1_Start

.l1:
	cp $08
	jr nc, .l2
.l5:
	ld hl, Sfx1_22_Data_4A5E
	jp Sfx1_Start

.l2:
	cp $09
	jr nc, .l3
	ld hl, Sfx1_22_Data_4A64
	jp Sfx1_Start

.l3:
	cp $0b
	jr nc, .l4
	jr .l5

.l4:
	cp $0d
	jr z, .l6
	jr .l7

.l6:
	ld a, $01
	ld [bc], a
	jr .l8

Sfx1_22_Play:
	jp Sfx1_Stop

Sfx1_22_Data_4A52:
	db $15, $38, $30, $40, $c6, $02
Sfx1_22_Data_4A58:
	db $15, $38, $40, $3c, $c6, $02
Sfx1_22_Data_4A5E:
	db $15, $38, $60, $38, $c6, $02
Sfx1_22_Data_4A64:
	db $15, $38, $90, $34, $c6, $02
	db $15, $38, $d0, $30, $c6, $02
Sfx1_23_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_23_Data_4AAD
	jp Sfx1_StartPriority

Sfx1_23_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jr z, .l0
	ld hl, Sfx1_23_Data_4A9F
	call GetPointer
	ld a, [wSfx1Step]
	and $01
	jp nz, SetRegs_Ch2
	jp SetRegs_Ch1

.l0:
	ld hl, wCh2Flags
	res 7, [hl]
	jp Sfx1_StopWithRegs

Sfx1_23_Data_4A9F:
	dw Sfx1_23_Data_4AB3, Sfx1_23_Data_4AB8, Sfx1_23_Data_4ABE, Sfx1_23_Data_4AC3, Sfx1_23_Data_4AC9, Sfx1_23_Data_4ACE, Sfx1_23_Data_4AD4
Sfx1_23_Data_4AAD:
	db $00, $80, $e2, $a7, $87, $09
Sfx1_23_Data_4AB3:
	db $80, $e2, $a2, $87, $08
Sfx1_23_Data_4AB8:
	db $00, $80, $e2, $90, $87
	db $08
Sfx1_23_Data_4ABE:
	db $80, $e2, $7b, $87, $08
Sfx1_23_Data_4AC3:
	db $00, $80, $b2, $59, $87
	db $09
Sfx1_23_Data_4AC9:
	db $80, $e2, $97, $87, $0a
Sfx1_23_Data_4ACE:
	db $00, $80, $e2, $ac, $87
	db $0b
Sfx1_23_Data_4AD4:
	db $80, $e2, $be, $87, $10
Sfx1_24_Init:
	ld hl, Sfx1_24_Data_4AE6
	jp Sfx1_Start

Sfx1_24_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_24_Data_4AE6:
	db $27, $80, $83, $00, $86, $18
Sfx1_25_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_25_Data_4B2B
	jp Sfx1_StartPriority

Sfx1_25_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jr z, .l0
	cp $07
	jr z, .l1
.l2:
	ld hl, Sfx1_25_Data_4B1F
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

Sfx1_25_Data_4B1F:
	dw Sfx1_25_Data_4B31, Sfx1_25_Data_4B34, Sfx1_25_Data_4B37, Sfx1_25_Data_4B3A, Sfx1_25_Data_4B3D, Sfx1_25_Data_4B40
Sfx1_25_Data_4B2B:
	db $00, $80, $a5, $06, $87, $02
Sfx1_25_Data_4B31:
	db $21, $07, $02
Sfx1_25_Data_4B34:
	db $39, $07, $02
Sfx1_25_Data_4B37:
	db $4f, $07, $02
Sfx1_25_Data_4B3A:
	db $62, $07, $02
Sfx1_25_Data_4B3D:
	db $74, $07, $02
Sfx1_25_Data_4B40:
	db $06, $07, $02
Sfx1_26_Init:
	ld a, $0e
	ld [wSfx1Counter], a
	ld hl, Sfx1_26_Data_4B85
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_26_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $03
	ld [de], a
	call Sfx_IncStep
	cp $04
	jr z, .l0
.l2:
	ld hl, Sfx1_26_Data_4B7F
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
	ld hl, Sfx1_26_Data_4B8B
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_26_Data_4B7F:
	db $ff, $e0
	db $00, $20
	db $ff, $fc
Sfx1_26_Data_4B85:
	db $00, $00, $0c, $f0, $87, $03
Sfx1_26_Data_4B8B:
	db $00, $00, $a7, $dc, $87, $03
Sfx1_27_Init:
	ld hl, Sfx1_27_Data_4BAB
	jp Sfx1_Start

Sfx1_27_Play:
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

Sfx1_27_Data_4BAB:
	db $14, $40, $c0, $00, $81, $0c
Sfx1_28_Init:
	ld hl, Sfx1_28_Data_4BDE
	jp Sfx1_Start

Sfx1_28_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_28_Data_4BD0
	call GetPointer
	ld a, $bd
	ldh [rNR11], a
	jp Sfx1_WritePeriod

Sfx1_28_Data_4BD0:
	dw Sfx1_28_Data_4BE4, Sfx1_28_Data_4BE7, Sfx1_28_Data_4BEA, Sfx1_28_Data_4BED, Sfx1_28_Data_4BF0, Sfx1_28_Data_4BF3, Sfx1_28_Data_4BF6
Sfx1_28_Data_4BDE:
	db $00, $bd, $f0, $e0, $c7, $0c
Sfx1_28_Data_4BE4:
	db $e0, $c7, $03
Sfx1_28_Data_4BE7:
	db $c0, $c7, $03
Sfx1_28_Data_4BEA:
	db $a0, $c7, $04
Sfx1_28_Data_4BED:
	db $80, $c7, $04
Sfx1_28_Data_4BF0:
	db $60, $c7, $05
Sfx1_28_Data_4BF3:
	db $40, $c7, $06
Sfx1_28_Data_4BF6:
	db $20, $c7, $03
Sfx1_29_Init:
	ld hl, Sfx1_29_Data_4C13
	jp Sfx1_Start

Sfx1_29_Play:
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

Sfx1_29_Data_4C13:
	db $17, $96, $49, $60, $c6, $04
Sfx1_2A_Init:
	ld hl, Sfx1_2A_Data_4C26
	jp Sfx1_Start

Sfx1_2A_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_StopWithRegs

Sfx1_2A_Data_4C26:
	db $16, $00, $f0, $00, $c2, $10
Sfx1_2B_Init:
	ld a, $2c
	ld [wSfx1Counter], a
	ld hl, Sfx1_2B_Data_4C75
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2B_Play:
	call Sfx_IncStep
	cp $0b
	jr z, .l0
.l2:
	ld hl, Sfx1_2B_Data_4C61
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
	ld hl, Sfx1_2B_Data_4C7B
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_2B_Data_4C61:
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
Sfx1_2B_Data_4C75:
	db $00, $00, $0f, $d0, $87, $02
Sfx1_2B_Data_4C7B:
	db $00, $00, $f7, $f0, $87, $04
Sfx1_2C_Init:
	ld a, $22
	ld [wSfx1Counter], a
	ld hl, Sfx1_2C_Data_4CCF
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_2C_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l3:
	ld hl, Sfx1_2C_Data_4CC3
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
	ld hl, Sfx1_2C_Data_4CD5
.l4:
	ld a, $01
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l2:
	ld hl, Sfx1_2C_Data_4CDB
	jr .l4

Sfx1_2C_Data_4CC3:
	db $00, $02
	db $00, $01
	db $ff, $f0
	db $ff, $e0
	db $ff, $c0
	db $00, $71
Sfx1_2C_Data_4CCF:
	db $00, $00, $0f, $00, $87, $01
Sfx1_2C_Data_4CD5:
	db $00, $00, $40, $10, $87, $01
Sfx1_2C_Data_4CDB:
	db $00, $00, $47, $70, $87, $01
Sfx1_2D_Init:
	ld a, $03
	ld [wSfx1Counter], a
	ld hl, Sfx1_2D_Data_4D20
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_2D_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $08
	ld [de], a
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l2:
	ld hl, Sfx1_2D_Data_4D18
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

Sfx1_2D_Data_4D18:
	db $00, $04
	db $ff, $dd
	db $00, $06
	db $00, $19
Sfx1_2D_Data_4D20:
	db $00, $80, $1f, $b6, $87, $08
Sfx1_2E_Init:
	ld a, $09
	ld [wSfx1Counter], a
	ld hl, Sfx1_2E_Data_4DAB
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2E_Play:
	call Sfx_IncStep
	cp $29
	jr z, .l0
.l2:
	ld hl, Sfx1_2E_Data_4D5B
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
	ld hl, Sfx1_2E_Data_4DB1
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_2E_Data_4D5B:
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
Sfx1_2E_Data_4DAB:
	db $00, $80, $1d, $00, $81, $10
Sfx1_2E_Data_4DB1:
	db $00, $80, $f7, $00, $81, $10
Sfx1_2F_Init:
	ld a, $07
	ld [wSfx1Counter], a
	ld hl, Sfx1_2F_Data_4DE9
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_2F_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_2F_Data_4DDD
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_2F_Data_4DDD:
	db $00, $80
	db $00, $60
	db $00, $40
	db $ff, $c0
	db $ff, $a0
	db $ff, $88
Sfx1_2F_Data_4DE9:
	db $00, $80, $f2, $00, $85, $01
Sfx1_30_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_30_Data_4E0A
	jp Sfx1_Start

Sfx1_30_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld hl, Sfx1_30_Data_4E0A
	jp SetRegs_Ch1

Sfx1_30_Data_4E0A:
	db $17, $bc, $64, $44, $c7, $02
Sfx1_31_Init:
	ld a, $14
	ld [wSfx1Counter], a
	ld hl, Sfx1_31_Data_4E4A
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_31_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_31_Data_4E46
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
	ld hl, Sfx1_31_Data_4E50
	ld a, $01
	ld [bc], a
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_31_Data_4E46:
	db $ff, $fc
	db $00, $02
Sfx1_31_Data_4E4A:
	db $00, $00, $19, $ea, $87, $01
Sfx1_31_Data_4E50:
	db $00, $00, $47, $e0, $87, $01
Sfx1_32_Init:
	ld hl, Sfx1_32_Data_4E75
	jp Sfx1_StartPriority

Sfx1_32_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_32_Data_4E71
	call GetPointer
	jp SetRegs_Ch1

Sfx1_32_Data_4E71:
	dw Sfx1_32_Data_4E7B, Sfx1_32_Data_4E81
Sfx1_32_Data_4E75:
	db $1f, $80, $85, $a0, $87, $0c
Sfx1_32_Data_4E7B:
	db $1f, $80, $47, $a0, $87, $0c
Sfx1_32_Data_4E81:
	db $1f, $8d, $20, $a0, $c7, $0c
Sfx1_33_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_33_Data_4EC4
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_33_Play:
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
	ld hl, Sfx1_33_Data_4EBC
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

Sfx1_33_Data_4EBC:
	db $00, $08
	db $ff, $fd
	db $00, $03
	db $ff, $f8
Sfx1_33_Data_4EC4:
	db $00, $00, $60, $d1, $87, $08
Sfx1_34_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_34_Data_4F17
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_34_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx1_34_Data_4F05
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
	ld hl, Sfx1_34_Data_4F1D
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

Sfx1_34_Data_4F05:
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
	db $ff, $fa
Sfx1_34_Data_4F17:
	db $00, $00, $1f, $d0, $87, $01
Sfx1_34_Data_4F1D:
	db $00, $00, $a7, $d8, $87, $01
Sfx1_35_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_35_Data_4F78
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_35_Play:
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
	ld hl, Sfx1_35_Data_4F66
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
	ld hl, Sfx1_35_Data_4F7E
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_35_Data_4F66:
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $0c
	db $00, $08
	db $00, $04
	db $00, $02
	db $ff, $a2
Sfx1_35_Data_4F78:
	db $00, $80, $1f, $a0, $86, $02
Sfx1_35_Data_4F7E:
	db $00, $80, $87, $a0, $86, $02
Sfx1_36_Init:
	ld a, $0b
	ld [wSfx1Counter], a
	ld hl, Sfx1_36_Data_4FEF
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_36_Play:
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
	ld hl, Sfx1_36_Data_4FE7
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

Sfx1_36_Data_4FE7:
	db $00, $20
	db $ff, $e8
	db $00, $1c
	db $ff, $f0
Sfx1_36_Data_4FEF:
	db $00, $40, $1f, $80, $83, $01
Sfx1_37_Init:
	ld a, $10
	ld [wSfx1Counter], a
	ld hl, Sfx1_37_Data_5036
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_37_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_37_Data_5024
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

Sfx1_37_Data_5024:
	db $00, $40
	db $00, $30
	db $00, $20
	db $ff, $e0
	db $ff, $d0
	db $ff, $c0
	db $ff, $a0
	db $ff, $80
	db $00, $d0
Sfx1_37_Data_5036:
	db $00, $80, $80, $00, $86, $01
Sfx1_38_Init:
	ld a, [wSfx1Playing]
	and a
	jp nz, Sfx1_Refuse
	ld a, [wSfx1Var2]
	and a
	jr nz, .l0
	ld hl, Sfx1_38_Data_5082
.l1:
	call Sfx1_LoadPitch
	jp Sfx1_Start

.l0:
	ld hl, Sfx1_38_Data_5088
	jr .l1

Sfx1_38_Play:
	call Sfx_IncStep
	cp $0b
	jr z, .l2
	ld hl, Sfx1_38_Data_506E
	jp Sfx1_AddPitch

.l2:
	ld hl, wSfx1Request
	ld a, $38
	ld [hl+], a
	xor a
	ld [hl], a
	jr Sfx1_38_Init

Sfx1_38_Data_506E:
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
Sfx1_38_Data_5082:
	db $00, $80, $a0, $00, $82, $01
Sfx1_38_Data_5088:
	db $00, $80, $c0, $00, $83, $01
Sfx1_39_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_39_Data_5114
	call Sfx1_LoadPitch
	jp Sfx1_StartPriority

Sfx1_39_Play:
	call Sfx_IncStep
	cp $0e
	jr z, .l0
	cp $0f
	jr z, .l1
.l3:
	ld a, [wSfx1Counter]
	cp $03
	jr c, .l2
	ld hl, Sfx1_39_Data_50DC
	jp Sfx1_AddPitch

.l2:
	ld hl, Sfx1_39_Data_50F8
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
	ld hl, Sfx1_39_Data_511A
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_39_Data_50DC:
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
Sfx1_39_Data_50F8:
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
Sfx1_39_Data_5114:
	db $00, $40, $4d, $80, $83, $01
Sfx1_39_Data_511A:
	db $00, $80, $20, $c0, $84, $01
Sfx1_3A_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_3A_Data_5161
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3A_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l2:
	ld hl, Sfx1_3A_Data_514F
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

Sfx1_3A_Data_514F:
	db $00, $12
	db $00, $0e
	db $00, $0a
	db $00, $08
	db $00, $06
	db $00, $04
	db $00, $02
	db $00, $01
	db $ff, $c1
Sfx1_3A_Data_5161:
	db $00, $00, $a4, $00, $87, $01
Sfx1_3B_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_3B_Data_51AE
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3B_Play:
	call Sfx_IncStep
	cp $0c
	jr z, .l0
	cp $0d
	jr z, .l1
.l2:
	ld hl, Sfx1_3B_Data_5196
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

Sfx1_3B_Data_5196:
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
Sfx1_3B_Data_51AE:
	db $00, $00, $87, $80, $87, $01
Sfx1_3C_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_3C_Data_51F0
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3C_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	ld hl, Sfx1_3C_Data_51E0
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx1_3C_Data_51F6
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3C_Data_51E0:
	db $00, $02
	db $00, $02
	db $00, $02
	db $00, $02
	db $00, $01
	db $00, $01
	db $00, $01
	db $00, $01
Sfx1_3C_Data_51F0:
	db $00, $00, $60, $d0, $87, $02
Sfx1_3C_Data_51F6:
	db $00, $40, $10, $d0, $87, $01
Sfx1_3D_Init:
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
	ld hl, Sfx1_3D_Data_5262
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3D_Play:
	call Sfx_IncStep
	cp $04
	jr z, .l0
	cp $05
	jr z, .l1
.l2:
	ld hl, Sfx1_3D_Data_525A
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
	ld hl, Sfx1_3D_Data_5268
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

.l3:
	ld a, $3d
	ld [wSfx1Request], a
	jr Sfx1_3D_Init

Sfx1_3D_Data_525A:
	db $00, $c0
	db $00, $80
	db $00, $40
	db $fe, $80
Sfx1_3D_Data_5262:
	db $00, $40, $19, $80, $83, $01
Sfx1_3D_Data_5268:
	db $00, $40, $86, $80, $83, $01
Sfx1_3E_Init:
	ld a, [wSfx1Playing]
	cp $3e
	jp z, Sfx1_Refuse
	ld hl, Sfx1_3E_Data_5283
	jp Sfx1_Start

Sfx1_3E_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_3E_Data_5283:
	db $27, $be, $60, $c0, $c7, $03
Sfx1_3F_Init:
	ld a, $09
	ld [wSfx1Counter], a
	ld hl, Sfx1_3F_Data_52CD
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_3F_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	cp $04
	jr z, .l1
.l3:
	ld hl, Sfx1_3F_Data_52C7
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
	ld hl, Sfx1_3F_Data_52D3
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_3F_Data_52C7:
	db $00, $60
	db $00, $40
	db $ff, $70
Sfx1_3F_Data_52CD:
	db $00, $80, $19, $00, $86, $01
Sfx1_3F_Data_52D3:
	db $00, $80, $d1, $10, $86, $01
Sfx1_40_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_40_Data_532B
	call Sfx1_LoadPitch
	jp Sfx1_Start

Sfx1_40_Play:
	call Sfx1_DecCounter
	jr z, .l0
.l4:
	ld a, [wSfx1Var5]
	cp $06
	jr nc, .l1
	ld a, $01
.l2:
	ld [bc], a
	ld hl, Sfx1_40_Data_5327
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
	ld hl, Sfx1_40_Data_5331
	call Sfx1_LoadPitch
	jp SetRegs_Ch1

Sfx1_40_Data_5327:
	db $00, $10
	db $ff, $f8
Sfx1_40_Data_532B:
	db $00, $80, $1a, $80, $82, $01
Sfx1_40_Data_5331:
	db $00, $80, $e5, $10, $84, $01
Sfx1_41_Init:
	ld hl, Sfx1_41_Data_5360
	jp Sfx1_StartPriority

Sfx1_41_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx1_Stop
	ld hl, Sfx1_41_Data_5352
	call GetPointer
	jp SetRegs_Ch1

Sfx1_41_Data_5352:
	dw Sfx1_41_Data_5378, Sfx1_41_Data_5366, Sfx1_41_Data_537E, Sfx1_41_Data_536C, Sfx1_41_Data_5384, Sfx1_41_Data_5372, Sfx1_41_Data_538A
Sfx1_41_Data_5360:
	db $00, $00, $c1, $7b, $87, $06
Sfx1_41_Data_5366:
	db $00, $00, $c1, $8a, $87, $06
Sfx1_41_Data_536C:
	db $00, $00, $c1, $90, $87, $07
Sfx1_41_Data_5372:
	db $00, $00, $c1, $b6, $87, $07
Sfx1_41_Data_5378:
	db $00, $00, $62, $7b, $87, $04
Sfx1_41_Data_537E:
	db $00, $00, $62, $8a, $87, $04
Sfx1_41_Data_5384:
	db $00, $00, $62, $90, $87, $04
Sfx1_41_Data_538A:
	db $00, $00, $62, $b6, $87, $04
	db $3e, $01, $ea, $a0, $d3
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
Sfx1_WritePeriod:
	ld b, $02
	ld c, $13
	jp SetRegs_Copy

; A refused request is dropped and the playing effect continues.
Sfx1_Refuse:
	xor a
	ld [wSfx1Request], a
	jp Sfx1_Update

