; Link's Awakening DX SFX, bank $1F: ch3 effects, bank $1F $53ED-$63EB

; Request $14 always starts; others are refused while a priority effect plays. Nothing
; runs while the music has paused the ch3 SFX (wCh3SfxPaused, command $96).
Sfx3_Update:
	ld hl, wSfx3Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $14
	jr z, .start
	ld a, [wSfx3Priority]
	and a
	jp nz, Sfx3_Refuse
.start:
	ld a, [hl]
	ld hl, Sfx3_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx3_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx3Timer
	ld bc, wSfx3Step
	ld a, [wCh3SfxPaused]
	and a
	ret nz
	jp hl

Sfx3_InitTable:
	dw Sfx3_01_Init
	dw Sfx3_02_Init
	dw Sfx3_03_Init
	dw Sfx3_04_Init
	dw Sfx3_05_Init
	dw Sfx3_06_Init
	dw Sfx3_07_Init
	dw Sfx3_08_Init
	dw Sfx3_09_Init
	dw Sfx3_0A_Init
	dw Sfx3_0B_Init
	dw Sfx3_0C_Init
	dw Sfx3_0D_Init
	dw Sfx3_0E_Init
	dw Sfx3_0F_Init
	dw Sfx3_10_Init
	dw Sfx3_11_Init
	dw Sfx3_12_Init
	dw Sfx3_13_Init
	dw Sfx3_14_Init
	dw Sfx3_15_Init
	dw Sfx3_16_Init
	dw Sfx3_17_Init
	dw Sfx3_18_Init
	dw Sfx3_19_Init
	dw Sfx3_1A_Init
	dw Sfx3_1B_Init
	dw Sfx3_1C_Init
	dw Sfx3_1D_Init
	dw Sfx3_1E_Init
	dw Sfx3_1F_Init
	dw Sfx3_20_Init
	dw Sfx3_21_Init
	dw Sfx3_22_Init
	dw Sfx3_23_Init
Sfx3_PlayTable:
	dw Sfx3_01_Play
	dw Sfx3_02_Play
	dw Sfx3_03_Play
	dw Sfx3_04_Play
	dw Sfx3_05_Play
	dw Sfx3_06_Play
	dw Sfx3_07_Play
	dw Sfx3_08_Play
	dw Sfx3_09_Play
	dw Sfx3_0A_Play
	dw Sfx3_0B_Play
	dw Sfx3_0C_Play
	dw Sfx3_0D_Play
	dw Sfx3_0E_Play
	dw Sfx3_0F_Play
	dw Sfx3_10_Play
	dw Sfx3_11_Play
	dw Sfx3_12_Play
	dw Sfx3_13_Play
	dw Sfx3_14_Play
	dw Sfx3_15_Play
	dw Sfx3_16_Play
	dw Sfx3_17_Play
	dw Sfx3_18_Play
	dw Sfx3_19_Play
	dw Sfx3_1A_Play
	dw Sfx3_1B_Play
	dw Sfx3_1C_Play
	dw Sfx3_1D_Play
	dw Sfx3_1E_Play
	dw Sfx3_1F_Play
	dw Sfx3_20_Play
	dw Sfx3_21_Play
	dw Sfx3_22_Play
	dw Sfx3_23_Play
Sfx3_01_Init:
	call Sfx3_LoadWave639C
	ld hl, Sfx3_01_Data_54CF
	jp Sfx3_StartPriority

Sfx3_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_01_Data_54C5
	call GetPointer
	jp SetRegs_Ch3

Sfx3_01_Data_54C5:
	dw Sfx3_01_Data_54D5, Sfx3_01_Data_54DB, Sfx3_01_Data_54E1, Sfx3_01_Data_54E7, Sfx3_01_Data_54ED
Sfx3_01_Data_54CF:
	db $80, $ee, $20, $cb, $c7, $05
Sfx3_01_Data_54D5:
	db $80, $ee, $20, $d1, $c7, $05
Sfx3_01_Data_54DB:
	db $80, $ee, $20, $d6, $c7, $05
Sfx3_01_Data_54E1:
	db $80, $ee, $20, $dd, $c7, $07
Sfx3_01_Data_54E7:
	db $80, $ee, $40, $dd, $c7, $07
Sfx3_01_Data_54ED:
	db $80, $ee, $60, $dd, $c7, $07
Sfx3_02_Init:
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63CC
	ld hl, Sfx3_02_Data_5532
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_02_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
	cp $0a
	jp z, Sfx3_StopWithRegs
.l1:
	ld hl, Sfx3_02_Data_5520
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_02_Data_5520:
	db $00, $10
	db $00, $40
	db $00, $40
	db $00, $30
	db $00, $30
	db $00, $20
	db $00, $10
	db $ff, $f0
	db $ff, $e0
Sfx3_02_Data_5532:
	db $80, $00, $20, $80, $85, $02
Sfx3_03_Init:
	ld hl, SfxWave_63CC
	xor a
	ldh [rNR30], a
	call Sfx3_CopyWave
	ld hl, Sfx3_03_Data_555E
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_03_Play:
	call Sfx_IncStep
	cp $05
	jp z, Sfx3_Stop
	ld hl, Sfx3_03_Data_5558
	jp Sfx3_AddPitch

Sfx3_03_Data_5558:
	db $01, $80
	db $ff, $f0
	db $ff, $e0
Sfx3_03_Data_555E:
	db $80, $ef, $20, $00, $c6, $01
Sfx3_04_Init:
	ld a, [wSfx3Playing]
	and a
	jp nz, Sfx3_Refuse
	ld a, [wSfx1Playing]
	cp $01
	ret z
	ld a, [wSfx1Playing]
	cp $01
	ret z
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63CC
	ld hl, Sfx3_04_Data_55A4
	jp Sfx3_Start

Sfx3_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jr z, .l0
	ld hl, Sfx3_04_Data_55AA
	jp Sfx3_WritePeriod

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	xor a
	ld [bc], a
	ld hl, Sfx3_04_Data_55AD
	jp SetRegs_Ch3

Sfx3_04_Data_55A4:
	db $80, $fa, $40, $c0, $c7, $04
Sfx3_04_Data_55AA:
	db $e0, $c7, $04
Sfx3_04_Data_55AD:
	db $80, $fa, $60, $c0, $c7, $04
Sfx3_05_Init:
	call Sfx3_LoadWave639C
	ld hl, Sfx3_05_Data_55F0
	jp Sfx3_Start

Sfx3_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	cp $02
	jp z, .l0
	cp $04
	jp z, .l1
.l2:
	ld hl, Sfx3_05_Data_55E6
	call GetPointer
	jp Sfx3_WritePeriod

.l0:
	ld a, $40
.l3:
	ldh [rNR32], a
	ld a, [bc]
	jr .l2

.l1:
	ld a, $60
	jr .l3

Sfx3_05_Data_55E6:
	dw Sfx3_05_Data_55F6, Sfx3_05_Data_55F3, Sfx3_05_Data_55F6, Sfx3_05_Data_55F3, Sfx3_05_Data_55F6
Sfx3_05_Data_55F0:
	db $80, $fa, $20
Sfx3_05_Data_55F3:
	db $da, $c7, $02
Sfx3_05_Data_55F6:
	db $ea, $c7, $02
Sfx3_06_Init:
	ld a, [wSfx1Playing]
	cp $01
	ret z
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_06_Data_5639
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_06_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l2:
	ld hl, Sfx3_06_Data_5637
	jp Sfx3_AddPitch

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_06_Data_563F
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $07
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

Sfx3_06_Data_5637:
	db $00, $03
Sfx3_06_Data_5639:
	db $80, $d2, $40, $e0, $87, $01
Sfx3_06_Data_563F:
	db $80, $d2, $60, $e0, $87, $01
Sfx3_07_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_07_Data_56C5
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_07_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $01
	ld [de], a
	call Sfx_IncStep
	cp $1d
	jr z, .l0
	cp $15
	jr nc, .l1
.l2:
	ld hl, Sfx3_07_Data_568D
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $14
	ld [bc], a
	ld hl, Sfx3_07_Data_56CB
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld a, $02
	ld [de], a
	jr .l2

Sfx3_07_Data_568D:
	db $00, $40
	db $00, $40
	db $00, $40
	db $01, $00
	db $00, $20
	db $ff, $e0
	db $00, $40
	db $ff, $c0
	db $00, $60
	db $ff, $a0
	db $00, $80
	db $ff, $80
	db $00, $a0
	db $ff, $60
	db $00, $c0
	db $ff, $40
	db $01, $00
	db $ff, $00
	db $01, $00
	db $ff, $00
	db $ff, $e0
	db $ff, $c0
	db $ff, $a0
	db $ff, $80
	db $ff, $60
	db $ff, $40
	db $ff, $20
	db $ff, $00
Sfx3_07_Data_56C5:
	db $80, $00, $20, $40, $84, $02
Sfx3_07_Data_56CB:
	db $80, $00, $60, $00, $86, $02
Sfx3_08_Init:
	ld a, $08
	ld [wSfx3Counter], a
	call Sfx3_LoadWave638C
	ld hl, Sfx3_08_Data_5716
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_08_Play:
	call Sfx_IncStep
	cp $0f
	jr z, .l0
.l1:
	ld hl, Sfx3_08_Data_56FA
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_08_Data_56FA:
	db $00, $0a
	db $00, $06
	db $ff, $f0
	db $00, $20
	db $00, $0a
	db $00, $06
	db $ff, $fa
	db $ff, $f6
	db $00, $20
	db $00, $0a
	db $00, $06
	db $ff, $fa
	db $ff, $f6
	db $ff, $a8
Sfx3_08_Data_5716:
	db $80, $00, $20, $60, $87, $00
Sfx3_09_Data_571C:
	db $8a, $df, $fd, $a8, $87, $42, $24, $78, $8a, $df, $fd, $a8, $87, $42, $24, $78
Sfx3_09_Shared_572C:
	ld hl, Sfx3_09_Data_571C
	jp Sfx3_LoadWave

Sfx3_09_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	call Sfx3_09_Shared_572C
	ld hl, Sfx3_09_Data_5790
	jp Sfx3_StartPriority

Sfx3_09_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jr z, Sfx3_09_Shared_575C
	ld hl, Sfx3_09_Data_576A
	call GetPointer
Sfx3_0A_Shared_5751:
	ld a, [wSfx3Step]
	and $01
	jp nz, SetRegs_Ch2
	jp SetRegs_Ch3

Sfx3_09_Shared_575C:
	ld hl, Sfx1_01_Data_431D
	call SetRegs_Ch2
	ld hl, wCh2Flags
	res 7, [hl]
	jp Sfx3_StopWithRegs

Sfx3_09_Data_576A:
	dw Sfx3_09_Data_57CC, Sfx3_09_Data_5796, Sfx3_09_Data_57D1, Sfx3_09_Data_579C, Sfx3_09_Data_57D6, Sfx3_09_Data_57A2, Sfx3_09_Data_57DB, Sfx3_09_Data_57A8, Sfx3_09_Data_57E0, Sfx3_09_Data_57AE, Sfx3_09_Data_57E5, Sfx3_09_Data_57B4, Sfx3_09_Data_57EA, Sfx3_09_Data_57BA, Sfx3_09_Data_57EF, Sfx3_09_Data_57C0, Sfx3_09_Data_57F4, Sfx3_09_Data_57C6, Sfx3_09_Data_57F9
Sfx3_09_Data_5790:
	db $80, $e6, $20, $8a, $c7, $08
Sfx3_09_Data_5796:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_579C:
	db $80, $60, $20, $9c, $c7
	db $08
Sfx3_09_Data_57A2:
	db $80, $e6, $20, $8a, $c7
	db $08
Sfx3_09_Data_57A8:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_57AE:
	db $80, $e6, $20, $9c, $c7
	db $08
Sfx3_09_Data_57B4:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_57BA:
	db $80, $e6, $20, $8a, $c7
	db $08
Sfx3_09_Data_57C0:
	db $80, $e6, $20, $62, $c7
	db $08
Sfx3_09_Data_57C6:
	db $80, $00, $20, $79, $c7
	db $08
Sfx3_09_Data_57CC:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_57D1:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_57D6:
	db $80, $20, $9c, $87, $34
Sfx3_09_Data_57DB:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_57E0:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_57E5:
	db $80, $20, $9c, $87, $02
Sfx3_09_Data_57EA:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_57EF:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_57F4:
	db $80, $20, $62, $87, $02
Sfx3_09_Data_57F9:
	db $80, $20, $79, $87, $48
Sfx3_0A_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	call Sfx3_09_Shared_572C
	ld hl, Sfx3_0A_Data_584B
	jp Sfx3_StartPriority

Sfx3_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $16
	jp z, Sfx3_09_Shared_575C
	ld hl, Sfx3_0A_Data_5821
	call GetPointer
	jp Sfx3_0A_Shared_5751

Sfx3_0A_Data_5821:
	dw Sfx3_0A_Data_587B, Sfx3_0A_Data_5851, Sfx3_0A_Data_5880, Sfx3_0A_Data_5857, Sfx3_0A_Data_5885, Sfx3_0A_Data_585D, Sfx3_0A_Data_588A, Sfx3_0A_Data_5863, Sfx3_0A_Data_588F, Sfx3_0A_Data_5869, Sfx3_0A_Data_5894, Sfx3_0A_Data_586F, Sfx3_0A_Data_5899, Sfx3_0A_Data_585D, Sfx3_0A_Data_588A, Sfx3_0A_Data_5857, Sfx3_0A_Data_5885, Sfx3_0A_Data_5851, Sfx3_0A_Data_5880, Sfx3_0A_Data_5875, Sfx3_0A_Data_589E
Sfx3_0A_Data_584B:
	db $80, $e0, $20, $9d, $c7, $04
Sfx3_0A_Data_5851:
	db $80, $e0, $20, $a7, $c7
	db $04
Sfx3_0A_Data_5857:
	db $80, $e0, $20, $b0, $c7
	db $04
Sfx3_0A_Data_585D:
	db $80, $e0, $20, $b6, $c7
	db $04
Sfx3_0A_Data_5863:
	db $80, $90, $20, $bd, $c7
	db $04
Sfx3_0A_Data_5869:
	db $80, $e0, $20, $c4, $c7
	db $04
Sfx3_0A_Data_586F:
	db $80, $e0, $20, $bd, $c7
	db $04
Sfx3_0A_Data_5875:
	db $80, $80, $20, $9d, $c7
	db $04
Sfx3_0A_Data_587B:
	db $80, $20, $9d, $87, $07
Sfx3_0A_Data_5880:
	db $80, $20, $a7, $87, $07
Sfx3_0A_Data_5885:
	db $80, $20, $b0, $87, $07
Sfx3_0A_Data_588A:
	db $80, $20, $b6, $87, $07
Sfx3_0A_Data_588F:
	db $80, $20, $bd, $87, $23
Sfx3_0A_Data_5894:
	db $80, $20, $c4, $87, $07
Sfx3_0A_Data_5899:
	db $80, $20, $bd, $87, $07
Sfx3_0A_Data_589E:
	db $80, $20, $9d, $87, $35
Sfx3_0B_Init:
	call Sound_Stop
	call Sfx3_09_Shared_572C
	ld hl, Sfx3_0A_Data_584B
	jp Sfx3_StartPriority

Sfx3_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx3_09_Shared_575C
	ld hl, Sfx3_0B_Data_58C4
	call GetPointer
	jp Sfx3_0A_Shared_5751

Sfx3_0B_Data_58C4:
	db $1c, $59, $ec, $58, $21
	db $59, $f2, $58, $26, $59
	db $f8, $58, $2b, $59, $fe
	db $58, $30, $59, $04, $59
	db $35, $59, $0a, $59, $3a
	db $59, $10, $59, $3f, $59
	db $16, $59, $44, $59, $80
	db $c0, $20, $9d, $c7, $04
Sfx3_0B_Data_58EC:
	db $80, $f0, $20, $9d, $c7
	db $04
Sfx3_0B_Data_58F2:
	db $80, $f0, $20, $7b, $c7
	db $04
Sfx3_0B_Data_58F8:
	db $80, $f0, $20, $8e, $c7
	db $04
Sfx3_0B_Data_58FE:
	db $80, $c0, $20, $a6, $c7
	db $04
Sfx3_0B_Data_5904:
	db $80, $c0, $20, $9d, $c7
	db $04
Sfx3_0B_Data_590A:
	db $80, $c0, $20, $bd, $c7
	db $04
Sfx3_0B_Data_5910:
	db $80, $f0, $20, $bd, $c7
	db $04
Sfx3_0B_Data_5916:
	db $80, $80, $20, $bd, $c7
	db $04
Sfx3_0B_Data_591C:
	db $80, $20, $9d, $87, $14
Sfx3_0B_Data_5921:
	db $80, $20, $9d, $87, $08
Sfx3_0B_Data_5926:
	db $80, $20, $7b, $87, $08
Sfx3_0B_Data_592B:
	db $80, $20, $8e, $87, $08
Sfx3_0B_Data_5930:
	db $80, $20, $a6, $87, $14
Sfx3_0B_Data_5935:
	db $80, $20, $9d, $87, $14
Sfx3_0B_Data_593A:
	db $80, $20, $bd, $87, $14
Sfx3_0B_Data_593F:
	db $80, $20, $bd, $87, $08
Sfx3_0B_Data_5944:
	db $80, $20, $bd, $87, $2c
Sfx3_0C_Init:
	ld a, $08
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63CC
	ld hl, Sfx3_0C_Data_598D
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_0C_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l2:
	ld hl, Sfx3_0C_Data_597D
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld a, $60
	ldh [rNR32], a
	ret

Sfx3_0C_Data_597D:
	db $ff, $fe
	db $ff, $fc
	db $ff, $f8
	db $ff, $e8
	db $00, $14
	db $00, $02
	db $00, $04
	db $00, $06
Sfx3_0C_Data_598D:
	db $80, $00, $40, $c0, $87, $01
	db $80, $00, $60, $c0, $87, $01
Sfx3_0D_Init:
	ld a, $10
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63AC
	ld hl, Sfx3_0D_Data_59D5
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_0D_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_0D_Data_59D1
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $08
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_0D_Data_59DB
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_0D_Data_59D1:
	db $ff, $a0
	db $00, $c0
Sfx3_0D_Data_59D5:
	db $80, $00, $20, $70, $80, $02
Sfx3_0D_Data_59DB:
	db $80, $00, $60, $70, $80, $02
Sfx3_0E_Init:
	call Sfx3_LoadWave63AC
	ld hl, Sfx3_0E_Data_5A07
	jp Sfx3_Start

Sfx3_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx3_Stop
	ld hl, Sfx3_0E_Data_59FF
	call GetPointer
	jp SetRegs_Ch3

Sfx3_0E_Data_59FF:
	dw Sfx3_0E_Data_5A0D, Sfx3_0E_Data_5A13, Sfx3_0E_Data_5A0D, Sfx3_0E_Data_5A07
Sfx3_0E_Data_5A07:
	db $80, $fb, $20, $00, $c2, $03
Sfx3_0E_Data_5A0D:
	db $80, $fd, $40, $80, $c3, $04
Sfx3_0E_Data_5A13:
	db $80, $fd, $60, $00, $c4, $05
Sfx3_0F_Init:
	ld a, [wSfx3Playing]
	cp $0f
	jp z, Sfx3_Refuse
	call Sfx3_LoadWave63CC
	ld hl, Sfx3_0F_Data_5A38
	jp Sfx3_Start

Sfx3_0F_Play:
	call Sfx_IncStep
	cp $02
	jp z, Sfx3_Stop
	ld hl, Sfx3_0F_Data_5A3E
	jp SetRegs_Ch3

Sfx3_0F_Data_5A38:
	db $80, $fb, $60, $d2, $c7, $01
Sfx3_0F_Data_5A3E:
	db $80, $fb, $40, $d2, $c7, $02
Sfx3_10_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_10_Data_5B5B
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_10_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $01
	ld [de], a
	call Sfx_IncStep
	cp $71
	jr z, .l0
	ld hl, Sfx3_10_Data_5A7B
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $60
	ld [bc], a
	ld hl, Sfx3_10_Data_5B61
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_10_Data_5A7B:
	db $00, $b0
	db $00, $b0
	db $00, $b0
	db $00, $b0
	db $00, $60
	db $00, $60
	db $00, $60
	db $00, $60
	db $00, $20
	db $ff, $e0
	db $00, $40
	db $ff, $c0
	db $00, $60
	db $ff, $a0
	db $00, $80
	db $ff, $80
	db $00, $a0
	db $ff, $60
	db $00, $c0
	db $ff, $40
	db $00, $80
	db $ff, $88
	db $00, $80
	db $ff, $88
	db $00, $90
	db $ff, $78
	db $00, $a0
	db $ff, $68
	db $00, $b0
	db $ff, $56
	db $00, $c0
	db $ff, $46
	db $00, $c0
	db $ff, $44
	db $00, $c0
	db $ff, $44
	db $00, $c0
	db $ff, $43
	db $00, $c0
	db $ff, $43
	db $00, $c0
	db $ff, $42
	db $00, $a0
	db $ff, $62
	db $00, $80
	db $ff, $82
	db $00, $80
	db $ff, $82
	db $00, $80
	db $ff, $84
	db $00, $80
	db $ff, $84
	db $00, $80
	db $ff, $84
	db $00, $80
	db $ff, $84
	db $00, $80
	db $ff, $b0
	db $00, $80
	db $ff, $b0
	db $00, $80
	db $ff, $80
	db $00, $80
	db $ff, $80
	db $00, $80
	db $ff, $80
	db $00, $80
	db $ff, $80
	db $00, $80
	db $ff, $68
	db $00, $80
	db $ff, $68
	db $00, $80
	db $ff, $68
	db $00, $80
	db $ff, $68
	db $00, $80
	db $ff, $78
	db $00, $80
	db $ff, $78
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $40
	db $00, $a0
	db $ff, $00
	db $00, $a0
	db $ff, $00
	db $00, $80
	db $fe, $80
	db $00, $80
	db $fe, $80
	db $00, $80
	db $fe, $80
	db $00, $80
	db $fe, $80
Sfx3_10_Data_5B5B:
	db $80, $00, $20, $a0, $81, $02
Sfx3_10_Data_5B61:
	db $80, $00, $60, $22, $86, $02
Sfx3_11_Init:
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx3_LoadWave639C
	ld hl, Sfx3_11_Data_5BB2
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_11_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	ld hl, Sfx3_11_Data_5BAE
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $06
	jp z, .l1
	cp $03
	jp z, .l2
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_11_Data_5BAE
	jp Sfx3_AddPitch

.l1:
	ld hl, Sfx3_11_Data_5BB8
.l3:
	call Sfx3_LoadPitch
	xor a
	ld [bc], a
	jp SetRegs_Ch3

.l2:
	ld hl, Sfx3_11_Data_5BBE
	jr .l3

Sfx3_11_Data_5BAE:
	db $00, $e0
	db $ff, $a0
Sfx3_11_Data_5BB2:
	db $80, $00, $20, $00, $84, $01
Sfx3_11_Data_5BB8:
	db $80, $00, $40, $80, $85, $01
Sfx3_11_Data_5BBE:
	db $80, $00, $60, $80, $85, $01
Sfx3_12_Init:
	ld a, $12
	ld [wSfx3Counter], a
	call Sfx3_LoadWave639C
	ld hl, Sfx3_12_Data_5C00
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_12_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_12_Data_5BFC
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $06
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_12_Data_5C06
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_12_Data_5BFC:
	db $01, $00
	db $fe, $c0
Sfx3_12_Data_5C00:
	db $80, $00, $20, $40, $86, $02
Sfx3_12_Data_5C06:
	db $80, $00, $60, $c0, $84, $02
Sfx3_13_Init:
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63DC
	ld hl, Sfx3_13_Data_5C6E
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_13_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $01
	ld [de], a
	call Sfx_IncStep
	cp $06
	jr z, .l0
	cp $07
	jr z, .l1
	ld hl, Sfx3_13_Data_5C64
	jp Sfx3_AddPitch

.l1:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l2
	cp $01
	jr z, .l2
	ld hl, Sfx3_13_Data_5C74
.l3:
	xor a
	ld [bc], a
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l0:
	ld a, [wSfx3Counter]
	cp $01
	jr z, .l1
	cp $04
	ret z
	ld a, $06
	ld [de], a
	xor a
	ldh [rNR32], a
	ret

.l2:
	ld hl, Sfx3_13_Data_5C7A
	jr .l3

Sfx3_13_Data_5C64:
	db $02, $40
	db $01, $40
	db $ff, $f2
	db $00, $0e
	db $ff, $f2
Sfx3_13_Data_5C6E:
	db $80, $00, $20, $16, $84, $01
Sfx3_13_Data_5C74:
	db $80, $00, $20, $26, $84, $01
Sfx3_13_Data_5C7A:
	db $80, $00, $20, $08, $84, $01
Sfx3_14_Init:
	ld a, [wSfx3Playing]
	cp $14
	jp z, Sfx3_Refuse
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx3_LoadWave639C
	ld hl, Sfx3_14_Data_5CAA
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_14_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_14_Data_5CA8
	jp Sfx3_AddPitch

Sfx3_14_Data_5CA8:
	db $00, $0e
Sfx3_14_Data_5CAA:
	db $80, $00, $40, $80, $87, $01
Sfx3_15_Init:
	call Sfx3_LoadWave638C
	ld hl, Sfx3_15_Data_5CD8
	jp Sfx3_StartPriority

Sfx3_15_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_15_Data_5CCE
	call GetPointer
	jp SetRegs_Ch3

Sfx3_15_Data_5CCE:
	dw Sfx3_15_Data_5CDE, Sfx3_15_Data_5CE4, Sfx3_15_Data_5CEA, Sfx3_15_Data_5CF0, Sfx3_15_Data_5CF6
Sfx3_15_Data_5CD8:
	db $80, $d0, $20, $40, $c7, $14
Sfx3_15_Data_5CDE:
	db $80, $c0, $20, $64, $c7, $0c
Sfx3_15_Data_5CE4:
	db $80, $90, $40, $78, $c7, $40
Sfx3_15_Data_5CEA:
	db $80, $c0, $20, $54, $c7, $06
Sfx3_15_Data_5CF0:
	db $80, $c0, $40, $46, $c7, $0c
Sfx3_15_Data_5CF6:
	db $80, $a0, $20, $5e, $c7, $20
Sfx3_16_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	cp $07
	jp z, Sfx3_Refuse
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_16_Data_5D68
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_16_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $01
	ld [de], a
	ld a, [bc]
	cp $07
	jr nc, .l0
.l2:
	call Sfx_IncStep
	cp $10
	jr z, .l1
	ld hl, Sfx3_16_Data_5D4A
	jp Sfx3_AddPitch

.l0:
	ld a, $03
	ld [de], a
	jr .l2

.l1:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $03
	ld [bc], a
	ld hl, Sfx3_16_Data_5D6E
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_16_Data_5D4A:
	db $02, $00
	db $02, $00
	db $01, $00
	db $00, $c0
	db $ff, $40
	db $00, $c0
	db $ff, $40
	db $ff, $00
	db $ff, $00
	db $fe, $00
	db $ff, $c0
	db $ff, $c0
	db $ff, $c0
	db $ff, $c0
	db $ff, $c0
Sfx3_16_Data_5D68:
	db $80, $00, $20, $60, $80, $02
Sfx3_16_Data_5D6E:
	db $80, $00, $60, $60, $85, $02
Sfx3_17_Data_5D74:
	db $02, $46, $8a, $ce, $fc, $96, $04, $04, $02, $46, $8a, $ce, $fc, $96, $04, $04
Sfx3_17_Init:
	ld hl, wCh4Flags
	set 7, [hl]
	ld a, $03
	ld [wSfx3Counter], a
	ld hl, Sfx3_17_Data_5EB1
	call SetRegs_Ch4
	call Sfx3_LoadWave639C
	ld hl, Sfx3_17_Data_5D74
	call Sfx3_LoadWave
	ld hl, Sfx3_17_Data_5EC5
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_17_Play:
	call Sfx_IncStep
	cp $55
	jr z, .l0
	cp $03
	jr z, .l1
	cp $07
	jr z, .l2
.l3:
	ld hl, Sfx3_17_Data_5E09
	jp Sfx3_AddPitch

.l1:
	ld a, $40
.l4:
	ldh [rNR32], a
	ld bc, wSfx3Step
	jr .l3

.l2:
	ld hl, Sfx3_17_Data_5EB6
	call SetRegs_Ch4
	ld a, $20
	jr .l4

.l0:
	call Sfx3_DecCounter
	jr z, .l5
	cp $01
	jr z, .l6
	ld a, $40
	ld [bc], a
	ld hl, Sfx3_17_Data_5EBB
	call SetRegs_Ch4
	ld hl, Sfx3_17_Data_5ECB
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l6:
	ld a, $40
	ld [bc], a
	ld hl, Sfx3_17_Data_5EC0
	call SetRegs_Ch4
	ld hl, Sfx3_17_Data_5ED1
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l5:
	ld hl, wCh4Flags
	res 7, [hl]
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
	jp Sfx3_StopWithRegs

Sfx3_17_Data_5E09:
	db $00, $40
	db $ff, $e0
	db $00, $40
	db $ff, $e0
	db $00, $30
	db $ff, $e8
	db $00, $30
	db $ff, $e8
	db $00, $20
	db $ff, $f0
	db $00, $20
	db $ff, $f0
	db $00, $10
	db $ff, $f8
	db $00, $10
	db $ff, $f8
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f9
	db $00, $08
	db $ff, $f8
	db $00, $08
	db $ff, $f8
	db $00, $08
	db $ff, $f8
	db $00, $08
	db $ff, $f8
	db $00, $08
	db $ff, $f7
	db $00, $08
	db $ff, $f7
	db $00, $08
	db $ff, $f7
	db $00, $08
	db $ff, $f7
	db $00, $08
	db $ff, $f7
	db $00, $08
	db $ff, $f7
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ee
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
	db $00, $10
	db $ff, $ec
Sfx3_17_Data_5EB1:
	db $00, $19, $00, $80, $01
Sfx3_17_Data_5EB6:
	db $00, $a0, $00, $80, $01
Sfx3_17_Data_5EBB:
	db $00, $50, $00, $80, $01
Sfx3_17_Data_5EC0:
	db $00, $20, $00, $80, $01
Sfx3_17_Data_5EC5:
	db $80, $00, $60, $a0, $86, $02
Sfx3_17_Data_5ECB:
	db $80, $00, $40, $20, $87, $02
Sfx3_17_Data_5ED1:
	db $80, $00, $60, $20, $87, $02
Sfx3_18_Init:
	ld a, $0e
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_18_Data_5F13
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_18_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_18_Data_5F0F
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $07
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_18_Data_5F13
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_18_Data_5F0F:
	db $00, $60
	db $ff, $00
Sfx3_18_Data_5F13:
	db $80, $00, $20, $40, $86, $00
Sfx3_19_Init:
	call Sfx3_LoadWave638C
	ld hl, Sfx3_19_Data_5F72
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_19_Play:
	call Sfx_IncStep
	cp $13
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l0
	cp $0e
	jr z, .l1
	cp $10
	jr z, .l2
.l3:
	ld hl, Sfx3_19_Data_5F4E
	jp Sfx3_AddPitch

.l0:
	ld a, $20
.l4:
	ldh [rNR32], a
	ld a, [bc]
	jr .l3

.l1:
	ld a, $40
	jr .l4

.l2:
	ld a, $60
	jr .l4

Sfx3_19_Data_5F4E:
	db $ff, $f0
	db $00, $12
	db $ff, $f0
	db $00, $12
	db $ff, $f0
	db $00, $12
	db $ff, $e0
	db $00, $1e
	db $ff, $e0
	db $00, $1c
	db $ff, $e0
	db $00, $1a
	db $ff, $e0
	db $00, $18
	db $ff, $e0
	db $00, $12
	db $ff, $e0
	db $00, $14
Sfx3_19_Data_5F72:
	db $80, $00, $40, $30, $87, $01
Sfx3_1A_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	cp $06
	jp z, Sfx3_Refuse
	cp $07
	jp z, Sfx3_Refuse
	call Sfx3_LoadWave63AC
	ld hl, Sfx3_1A_Data_5FAE
	jp Sfx3_Start

Sfx3_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx3_Stop
	ld hl, Sfx3_1A_Data_5FA8
	call GetPointer
	jp SetRegs_Ch3

Sfx3_1A_Data_5FA8:
	dw Sfx3_1A_Data_5FB4, Sfx3_1A_Data_5FBA, Sfx3_1A_Data_5FB4
Sfx3_1A_Data_5FAE:
	db $80, $fd, $40, $20, $c0, $02
Sfx3_1A_Data_5FB4:
	db $80, $fd, $40, $80, $c1, $02
Sfx3_1A_Data_5FBA:
	db $80, $fd, $40, $00, $c2, $02
Sfx3_1B_Init:
	call Sfx3_LoadWave638C
	ld hl, Sfx3_1B_Data_5FEC
	jp Sfx3_StartPriority

Sfx3_1B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx3_Stop
	ld hl, Sfx3_1B_Data_5FDE
	call GetPointer
	jp SetRegs_Ch3

Sfx3_1B_Data_5FDE:
	dw Sfx3_1B_Data_6004, Sfx3_1B_Data_5FF2, Sfx3_1B_Data_600A, Sfx3_1B_Data_5FF8, Sfx3_1B_Data_6010, Sfx3_1B_Data_5FFE, Sfx3_1B_Data_6016
Sfx3_1B_Data_5FEC:
	db $80, $ea, $20, $62, $c7, $06
Sfx3_1B_Data_5FF2:
	db $80, $ea, $20, $74, $c7, $06
Sfx3_1B_Data_5FF8:
	db $80, $ea, $20, $7b, $c7, $06
Sfx3_1B_Data_5FFE:
	db $80, $ea, $20, $a7, $c7, $06
Sfx3_1B_Data_6004:
	db $80, $ea, $60, $62, $c7, $06
Sfx3_1B_Data_600A:
	db $80, $ea, $60, $74, $c7, $06
Sfx3_1B_Data_6010:
	db $80, $ea, $60, $7b, $c7, $06
Sfx3_1B_Data_6016:
	db $80, $ea, $60, $a7, $c7, $06
Sfx3_1C_Init:
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx3_LoadWave638C
	ld hl, Sfx3_1C_Data_6060
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_1C_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
	ld hl, Sfx3_1C_Data_6054
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l1
	ld hl, Sfx3_1C_Data_6066
.l2:
	xor a
	ld [bc], a
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_1C_Data_6060
	jr .l2

Sfx3_1C_Data_6054:
	db $00, $06
	db $00, $04
	db $00, $02
	db $ff, $f8
	db $ff, $f0
	db $ff, $e8
Sfx3_1C_Data_6060:
	db $80, $00, $20, $60, $87, $01
Sfx3_1C_Data_6066:
	db $80, $00, $60, $60, $87, $01
Sfx3_1D_Init:
	ret

Sfx3_1D_Play:
	ret

Sfx3_1E_Init:
	ld a, $07
	ld [wSfxVarDC], a
	ld a, $40
	ld [wSfx3Counter], a
	call Sfx3_LoadWave63AC
	ld hl, Sfx3_1E_Data_60BE
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_1E_Play:
	call Sfx3_DecCounter
	jp z, .l0
.l4:
	ld a, [wSfxVarDC]
	cp $07
	jr z, .l1
	cp $06
	jr z, .l2
	ld a, $03
.l3:
	ld [bc], a
	ld hl, Sfx3_1E_Data_60B8
	jp Sfx3_AddPitch

.l1:
	ld a, $01
	jr .l3

.l2:
	ld a, $02
	jr .l3

.l0:
	push de
	ld de, wSfxVarDC
	call Sfx_DecTimer
	pop de
	jp z, Sfx3_StopWithRegs
	ld a, $40
	ld [wSfx3Counter], a
	jr .l4

Sfx3_1E_Data_60B8:
	db $ff, $ff
	db $ff, $fe
	db $ff, $fb
Sfx3_1E_Data_60BE:
	db $80, $00, $20, $ff, $87, $01
Sfx3_1F_Data_60C4:
	db $06, $c6, $06, $c6, $06, $c6, $06, $c6, $89, $bd, $ed, $b9, $87, $53, $23, $57
Sfx3_1F_Init:
	call Sound_Stop
	ld hl, Sfx3_1F_Data_60C4
	call Sfx3_LoadWave
	ld a, $05
	ld [wSfx3Counter], a
	xor a
	ld [$d3dd], a
	ld hl, Sfx3_1F_Data_6147
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_1F_Play:
	call Sfx3_DecCounter
	cp $01
	jr z, .l0
	ld a, [$d3dd]
	cp $11
	jr z, .l1
	cp $0a
	jr nc, .l2
	ld a, $01
.l3:
	ld bc, wSfx3Step
	ld [bc], a
	ld hl, Sfx3_1F_Data_613D
	jp Sfx3_AddPitch

.l1:
	ld a, $05
	jr .l3

.l2:
	ld a, $03
	jr .l3

.l0:
	push bc
	ld bc, $d3dd
	call Sfx_IncStep
	pop bc
	cp $12
	jr z, .l4
	add a, $05
	ld [wSfx3Counter], a
	ld a, [$d3dd]
	cp $0b
	jr nc, .l5
	ld a, $02
	jr .l3

.l5:
	ld a, $04
	jr .l3

.l4:
	ld a, $59
	ld [wSongRequest], a
	jp Sfx3_StopWithRegs

Sfx3_1F_Data_613D:
	db $ff, $f4
	db $00, $32
	db $ff, $f0
	db $00, $70
	db $ff, $e8
Sfx3_1F_Data_6147:
	db $80, $00, $40, $a0, $87, $01
Sfx3_20_Init:
	call Sfx3_LoadWave63AC
	ld a, $03
	ld [$d3de], a
	ld a, $90
	ld [wSfx3Counter], a
	ld hl, Sfx3_20_Data_619C
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_20_Play:
	call Sfx3_DecCounter
	jr z, .l0
.l4:
	ld a, [$d3de]
	cp $03
	jr z, .l1
	cp $02
	jr z, .l2
	ld a, $01
.l3:
	ld [bc], a
	ld hl, Sfx3_20_Data_6196
	jp Sfx3_AddPitch

.l1:
	ld a, $03
	jr .l3

.l2:
	ld a, $02
	jr .l3

.l0:
	push de
	ld de, $d3de
	call Sfx_DecTimer
	pop de
	jp z, Sfx3_StopWithRegs
	ld a, $90
	ld [wSfx3Counter], a
	jr .l4

Sfx3_20_Data_6196:
	db $00, $01
	db $00, $02
	db $00, $03
Sfx3_20_Data_619C:
	db $80, $00, $60, $80, $84, $02
Sfx3_21_Init:
	ld a, $07
	ld [wSfx3Counter], a
	ld a, [wSfx3Request]
	ld [wSfx3Playing], a
	ld a, $01
	ld [wSfx3Priority], a
	ld hl, wCh2Flags
	set 7, [hl]
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ldh [rNR30], a
	ld hl, Sfx3_StopRegs
	call SetRegs_Ch3
	ld hl, Sfx3_21_Data_6217
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx3_21_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx3_21_Data_6205
	jp Sfx2_AddPitch

.l0:
	call Sfx3_DecCounter
	jr z, .l2
	ld a, [bc]
	jr .l3

.l1:
	ld a, $01
	ld [bc], a
	jr .l3

.l2:
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ld [wSfx3Playing], a
	ld [wSfx3Priority], a
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, wCh2Flags
	res 7, [hl]
	ret

Sfx3_21_Data_6205:
	db $ff, $ff
	db $ff, $fe
	db $ff, $fd
	db $ff, $fc
	db $ff, $fa
	db $ff, $f6
	db $ff, $f2
	db $ff, $ee
	db $00, $3a
Sfx3_21_Data_6217:
	db $00, $97, $80, $87, $01
Sfx3_22_Init:
	ld a, $2e
	ld [wSfx3Counter], a
	xor a
	ld [$d3e1], a
	call Sfx3_LoadWave63AC
	ld hl, Sfx3_22_Data_6276
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_22_Play:
	call Sfx3_DecCounter
	jr z, .l0
.l4:
	ld a, [$d3e1]
	cp $01
	jr z, .l1
	cp $02
	jr z, .l2
	cp $03
	jr z, .l3
	ld a, $01
.l5:
	ld [bc], a
	ld hl, Sfx3_22_Data_626E
	jp Sfx3_AddPitch

.l0:
	push bc
	ld bc, $d3e1
	call Sfx_IncStep
	pop bc
	cp $04
	jp z, Sfx3_StopWithRegs
	ld a, $2e
	ld [wSfx3Counter], a
	jr .l4

.l1:
	ld a, $02
	jr .l5

.l2:
	ld a, $03
	jr .l5

.l3:
	ld a, $04
	jr .l5

Sfx3_22_Data_626E:
	db $00, $08
	db $00, $06
	db $00, $04
	db $00, $02
Sfx3_22_Data_6276:
	db $80, $00, $40, $30, $84, $01
Sfx3_23_Init:
	call Sfx3_LoadWave63BC
	ld hl, Sfx3_23_Data_62C9
	jp Sfx3_StartPriority

Sfx3_23_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx3_StopWithRegs
	ld hl, Sfx3_23_Data_62B1
	call GetPointer
	ld a, [wSfx3Step]
	cp $01
	jp z, SetRegs_Ch3
	cp $02
	jp z, SetRegs_Ch3
	cp $07
	jp z, SetRegs_Ch3
	cp $0a
	jp z, SetRegs_Ch3
	jp Sfx3_WritePeriod

Sfx3_23_Data_62B1:
	dw Sfx3_23_Data_62CF, Sfx3_23_Data_62D5, Sfx3_23_Data_62E7, Sfx3_23_Data_62EA, Sfx3_23_Data_62ED, Sfx3_23_Data_62F0, Sfx3_23_Data_62DB, Sfx3_23_Data_62ED, Sfx3_23_Data_62F0, Sfx3_23_Data_62E1, Sfx3_23_Data_62ED, Sfx3_23_Data_62F0
Sfx3_23_Data_62C9:
	db $80, $f2, $60, $df, $87, $02
Sfx3_23_Data_62CF:
	db $80, $f2, $40, $df, $87, $02
Sfx3_23_Data_62D5:
	db $80, $f2, $20, $df, $87, $03
Sfx3_23_Data_62DB:
	db $80, $f2, $40, $a2, $87, $03
Sfx3_23_Data_62E1:
	db $80, $f2, $60, $a2, $87, $03
Sfx3_23_Data_62E7:
	db $be, $87, $03
Sfx3_23_Data_62EA:
	db $a2, $87, $03
Sfx3_23_Data_62ED:
	db $83, $87, $03
Sfx3_23_Data_62F0:
	db $a7, $c7, $03
Sfx3_StartPriority:
	ld a, $01
	ld [wSfx3Priority], a
; Start a ch3 effect: hl = NR30-NR34 + frames; the wave is loaded by the effect itself.
Sfx3_Start:
	ld a, [wSfx3Request]
	ld [wSfx3Playing], a
	push hl
	ld hl, wCh3Flags
	set 7, [hl]
	pop hl
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ldh [rNR30], a
	jp SetRegs_Ch3

; unreferenced
Unused_6311:
	db $80, $00, $00, $00, $01, $01, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00
	db $00, $00, $ff, $ff, $ff, $ff
Sfx3_StopWithRegs:
	ld hl, Sfx3_StopRegs
	call SetRegs_Ch3
; End a ch3 effect and tell the music to reload its wave (wReloadWave).
Sfx3_Stop:
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ld [wSfx3Playing], a
	ldh [rNR30], a
	ld [wSfx3Priority], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld a, $01
	ld [wReloadWave], a
	ret

Sfx3_CopyWave:
	push bc
	ld c, $30
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jr nz, .loop
	pop bc
	ret

Sfx3_StopRegs:
	db $80, $00, $00, $00, $81, $01
Sfx3_LoadWave:
	xor a
	ldh [rNR30], a
	jp Sfx3_CopyWave

Sfx3_LoadWave63AC:
	ld hl, SfxWave_63AC
	jr Sfx3_LoadWave

Sfx3_LoadWave63BC:
	ld hl, SfxWave_63BC
	jr Sfx3_LoadWave

Sfx3_LoadWave639C:
	ld hl, SfxWave_639C
	jr Sfx3_LoadWave

Sfx3_LoadWave63CC:
	ld hl, SfxWave_63CC
	jr Sfx3_LoadWave

Sfx3_LoadWave63DC:
	ld hl, SfxWave_63DC
	jr Sfx3_LoadWave

Sfx3_LoadWave638C:
	ld hl, SfxWave_638C
	jr Sfx3_LoadWave

Sfx3_WritePeriod:
	ld c, $1d
	ld b, $02
	jp SetRegs_Copy

Sfx3_Refuse:
	xor a
	ld [wSfx3Request], a
	jp Sfx3_Update

SfxWave_638C:
	db $8c, $ef, $fe, $c8, $84, $21, $12, $48, $8c, $ef, $fe, $c8, $84, $21, $12, $48
SfxWave_639C:
	db $00, $22, $44, $66, $88, $aa, $cc, $cc, $00, $22, $44, $66, $88, $aa, $cc, $cc
SfxWave_63AC:
	db $0f, $0f, $1f, $1f, $2f, $2f, $3f, $3f, $40, $40, $50, $50, $60, $60, $70, $70
SfxWave_63BC:
	db $0c, $0c, $00, $22, $44, $88, $aa, $cc, $ee, $00, $6c, $60, $00, $6c, $60, $00
SfxWave_63CC:
	db $ff, $ff, $ee, $dd, $ee, $dd, $ee, $ff, $ff, $c9, $63, $21, $00, $00, $04, $8c
SfxWave_63DC:
	db $01, $23, $45, $67, $89, $ac, $ee, $ee, $fe, $dc, $ba, $98, $76, $54, $32, $10
