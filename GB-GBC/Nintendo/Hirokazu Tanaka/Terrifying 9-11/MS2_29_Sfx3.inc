; Metal Slug 2 SFX: ch3 effects, bank $29 $5338-$6432

; Request $14 always starts; others are refused while a priority effect plays. Nothing
; runs while the music has paused the ch3 SFX (wCh3SfxPaused, command $96).
Sfx3_Update:
	ld hl, wSfx3Request
	ld a, [hl]
	and a
	jp z, .playing
	cp $14
	jr z, .start
	ld a, [wSfx3Priority]
	and a
	jp nz, Sfx3_Refuse
.start:
	ld a, [hl]
	ld hl, Sfx3_InitTable
	jp .dispatch

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
; same number in LA
Sfx3_01_Init:
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_01_Data_541C
	jp Sfx3_StartPriority

Sfx3_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_01_Data_5412
	call GetPointer
	jp SetRegs_Ch3

Sfx3_01_Data_5412:
	dw Sfx3_01_Data_5422, Sfx3_01_Data_5428, Sfx3_01_Data_542E, Sfx3_01_Data_5434, Sfx3_01_Data_543A
Sfx3_01_Data_541C:
	db $80, $ee, $20, $cb, $c7, $05
Sfx3_01_Data_5422:
	db $80, $ee, $20, $d1, $c7, $05
Sfx3_01_Data_5428:
	db $80, $ee, $20, $d6, $c7, $05
Sfx3_01_Data_542E:
	db $80, $ee, $20, $dd, $c7, $07
Sfx3_01_Data_5434:
	db $80, $ee, $40, $dd, $c7, $07
Sfx3_01_Data_543A:
	db $80, $ee, $60, $dd, $c7, $07
; same number in LA
Sfx3_02_Init:
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx3_02_Shared_62C2
	ld hl, Sfx3_02_Data_547F
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_02_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
	cp $0a
	jp z, Sfx3_StopWithRegs
.l1:
	ld hl, Sfx3_02_Data_546D
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_02_Data_546D:
	db $00, $10
	db $00, $40
	db $00, $40
	db $00, $30
	db $00, $30
	db $00, $20
	db $00, $10
	db $ff, $f0
	db $ff, $e0
Sfx3_02_Data_547F:
	db $80, $00, $20, $80, $85, $02
; same number in LA
Sfx3_03_Init:
	ld hl, $63cc	; LA's SfxWave_63CC, not relocated: here $63CC is inside Sfx4_PlayTable
	xor a
	ldh [rNR30], a
	call Sfx3_CopyWave
	ld hl, Sfx3_03_Data_54AB
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_03_Play:
	call Sfx_IncStep
	cp $05
	jp z, Sfx3_Stop
	ld hl, Sfx3_03_Data_54A5
	jp Sfx3_AddPitch

Sfx3_03_Data_54A5:
	db $01, $80
	db $ff, $f0
	db $ff, $e0
Sfx3_03_Data_54AB:
	db $80, $ef, $20, $00, $c6, $01
; same number in LA
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
	call Sfx3_02_Shared_62C2
	ld hl, Sfx3_04_Data_54F1
	jp Sfx3_Start

Sfx3_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jr z, .l0
	ld hl, Sfx3_04_Data_54F7
	jp Sfx3_WritePeriod

.l0:
	call Sfx3_DecCounter
	jp z, Sfx1_Stop
	xor a
	ld [bc], a
	ld hl, Sfx3_04_Data_54FA
	jp SetRegs_Ch3

Sfx3_04_Data_54F1:
	db $80, $fa, $40, $c0, $c7, $04
Sfx3_04_Data_54F7:
	db $e0, $c7, $04
Sfx3_04_Data_54FA:
	db $80, $fa, $60, $c0, $c7, $04
; same number in LA
Sfx3_05_Init:
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_05_Data_553D
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
	ld hl, Sfx3_05_Data_5533
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

Sfx3_05_Data_5533:
	dw Sfx3_05_Data_5543, Sfx3_05_Data_5540, Sfx3_05_Data_5543, Sfx3_05_Data_5540, Sfx3_05_Data_5543
Sfx3_05_Data_553D:
	db $80, $fa, $20
Sfx3_05_Data_5540:
	db $da, $c7, $02
Sfx3_05_Data_5543:
	db $ea, $c7, $02
; same number in LA
Sfx3_06_Init:
	ld a, [wSfx1Playing]
	cp $01
	ret z
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_06_Data_5586
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_06_Play:
	call Sfx_IncStep
	cp $02
	jr z, .l0
.l2:
	ld hl, Sfx3_06_Data_5584
	jp Sfx3_AddPitch

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_06_Data_558C
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

Sfx3_06_Data_5584:
	db $00, $03
Sfx3_06_Data_5586:
	db $80, $d2, $40, $e0, $87, $01
Sfx3_06_Data_558C:
	db $80, $d2, $60, $e0, $87, $01
; same number in LA
Sfx3_07_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_07_Data_5612
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
	ld hl, Sfx3_07_Data_55DA
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $14
	ld [bc], a
	ld hl, Sfx3_07_Data_5618
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld a, $02
	ld [de], a
	jr .l2

Sfx3_07_Data_55DA:
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
Sfx3_07_Data_5612:
	db $80, $00, $20, $40, $84, $02
Sfx3_07_Data_5618:
	db $80, $00, $60, $00, $86, $02
; same number in LA
Sfx3_08_Init:
	ld a, $08
	ld [wSfx3Counter], a
	call Sfx3_08_Shared_62CC
	ld hl, Sfx3_08_Data_5663
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_08_Play:
	call Sfx_IncStep
	cp $0f
	jr z, .l0
.l1:
	ld hl, Sfx3_08_Data_5647
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_08_Data_5647:
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
Sfx3_08_Data_5663:
	db $80, $00, $20, $60, $87, $00
Sfx3_09_Data_5669:
	db $8a, $df, $fd, $a8, $87, $42, $24, $78, $8a, $df, $fd, $a8, $87, $42, $24, $78
Sfx3_09_Shared_5679:
	ld hl, Sfx3_09_Data_5669
	jp Sfx3_LoadWave

; same number in LA
Sfx3_09_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	call Sfx3_09_Shared_5679
	ld hl, Sfx3_09_Data_56DF
	jp Sfx3_StartPriority

Sfx3_09_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $14
	jr z, Sfx3_09_Shared_56A9
	ld hl, Sfx3_09_Data_56B7
	call GetPointer
Sfx3_0A_Shared_569E:
	ld a, [wSfx3Step]
	and $01
	jp nz, SetRegs_Ch2
	jp SetRegs_Ch3

Sfx3_09_Shared_56A9:
	ld hl, Sfx1_01_Data_4239
	call SetRegs_Ch2
	ld hl, wCh2Flags
	res 7, [hl]
	jp Sfx3_StopWithRegs

Sfx3_09_Data_56B7:
	dw Sfx3_09_Data_571B, Sfx3_09_Data_56DF, Sfx3_09_Data_5720, Sfx3_09_Data_56E5, Sfx3_09_Data_5725, Sfx3_09_Data_56EB, Sfx3_09_Data_572A, Sfx3_09_Data_56F1, Sfx3_09_Data_572F, Sfx3_09_Data_56F7, Sfx3_09_Data_5734, Sfx3_09_Data_56FD, Sfx3_09_Data_5739, Sfx3_09_Data_5703, Sfx3_09_Data_573E, Sfx3_09_Data_5709, Sfx3_09_Data_5743, Sfx3_09_Data_570F, Sfx3_09_Data_5748, Sfx3_09_Data_5715
Sfx3_09_Data_56DF:
	db $80, $e6, $20, $8a, $c7, $08
Sfx3_09_Data_56E5:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_56EB:
	db $80, $60, $20, $9c, $c7
	db $08
Sfx3_09_Data_56F1:
	db $80, $e6, $20, $8a, $c7
	db $08
Sfx3_09_Data_56F7:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_56FD:
	db $80, $e6, $20, $9c, $c7
	db $08
Sfx3_09_Data_5703:
	db $80, $e6, $20, $97, $c7
	db $08
Sfx3_09_Data_5709:
	db $80, $e6, $20, $8a, $c7
	db $08
Sfx3_09_Data_570F:
	db $80, $e6, $20, $62, $c7
	db $08
Sfx3_09_Data_5715:
	db $80, $00, $20, $79, $c7
	db $08
Sfx3_09_Data_571B:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_5720:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_5725:
	db $80, $20, $9c, $87, $34
Sfx3_09_Data_572A:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_572F:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_5734:
	db $80, $20, $9c, $87, $02
Sfx3_09_Data_5739:
	db $80, $20, $97, $87, $02
Sfx3_09_Data_573E:
	db $80, $20, $8a, $87, $02
Sfx3_09_Data_5743:
	db $80, $20, $62, $87, $02
Sfx3_09_Data_5748:
	db $80, $20, $79, $87, $48
; same number in LA
Sfx3_0A_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	call Sfx3_09_Shared_5679
	ld hl, Sfx3_0A_Data_579C
	jp Sfx3_StartPriority

Sfx3_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $16
	jp z, Sfx3_09_Shared_56A9
	ld hl, Sfx3_0A_Data_5770
	call GetPointer
	jp Sfx3_0A_Shared_569E

Sfx3_0A_Data_5770:
	dw Sfx3_0A_Data_57CC, Sfx3_0A_Data_57A2, Sfx3_0A_Data_57D1, Sfx3_0A_Data_57A8, Sfx3_0A_Data_57D6, Sfx3_0A_Data_57AE, Sfx3_0A_Data_57DB, Sfx3_0A_Data_57B4, Sfx3_0A_Data_57E0, Sfx3_0A_Data_57BA, Sfx3_0A_Data_57E5, Sfx3_0A_Data_57C0, Sfx3_0A_Data_57EA, Sfx3_0A_Data_57BA, Sfx3_0A_Data_57DB, Sfx3_0A_Data_57B4, Sfx3_0A_Data_57D6, Sfx3_0A_Data_57AE, Sfx3_0A_Data_57D1, Sfx3_0A_Data_57A8, Sfx3_0A_Data_57EF, Sfx3_0A_Data_57C6
Sfx3_0A_Data_579C:
	db $80, $e0, $20, $9d, $c7, $04
Sfx3_0A_Data_57A2:
	db $80, $e0, $20, $a7, $c7
	db $04
Sfx3_0A_Data_57A8:
	db $80, $e0, $20, $b0, $c7
	db $04
Sfx3_0A_Data_57AE:
	db $80, $e0, $20, $b6, $c7
	db $04
Sfx3_0A_Data_57B4:
	db $80, $90, $20, $bd, $c7
	db $04
Sfx3_0A_Data_57BA:
	db $80, $e0, $20, $c4, $c7
	db $04
Sfx3_0A_Data_57C0:
	db $80, $e0, $20, $bd, $c7
	db $04
Sfx3_0A_Data_57C6:
	db $80, $80, $20, $9d, $c7
	db $04
Sfx3_0A_Data_57CC:
	db $80, $20, $9d, $87, $07
Sfx3_0A_Data_57D1:
	db $80, $20, $a7, $87, $07
Sfx3_0A_Data_57D6:
	db $80, $20, $b0, $87, $07
Sfx3_0A_Data_57DB:
	db $80, $20, $b6, $87, $07
Sfx3_0A_Data_57E0:
	db $80, $20, $bd, $87, $23
Sfx3_0A_Data_57E5:
	db $80, $20, $c4, $87, $07
Sfx3_0A_Data_57EA:
	db $80, $20, $bd, $87, $07
Sfx3_0A_Data_57EF:
	db $80, $20, $9d, $87, $35
; same number in LA
Sfx3_0B_Init:
	call Sound_Stop
	call Sfx3_09_Shared_5679
	ld hl, Sfx3_0B_Data_5839
	jp Sfx3_StartPriority

Sfx3_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx3_09_Shared_56A9
	ld hl, Sfx3_0B_Data_5815
	call GetPointer
	jp Sfx3_0A_Shared_569E

Sfx3_0B_Data_5815:
	dw Sfx3_0B_Data_586F, Sfx3_0B_Data_583F, Sfx3_0B_Data_5874, Sfx3_0B_Data_5845, Sfx3_0B_Data_5879, Sfx3_0B_Data_584B, Sfx3_0B_Data_587E, Sfx3_0B_Data_5851, Sfx3_0B_Data_5883, Sfx3_0B_Data_5857, Sfx3_0B_Data_5888, Sfx3_0B_Data_585D, Sfx3_0B_Data_588D, Sfx3_0B_Data_5863, Sfx3_0B_Data_5892, Sfx3_0B_Data_5869, Sfx3_0B_Data_5897, Sfx3_0B_Data_586F
Sfx3_0B_Data_5839:
	db $80, $c0, $20, $9d, $c7, $04
Sfx3_0B_Data_583F:
	db $80, $f0, $20, $9d, $c7
	db $04
Sfx3_0B_Data_5845:
	db $80, $f0, $20, $7b, $c7
	db $04
Sfx3_0B_Data_584B:
	db $80, $f0, $20, $8e, $c7
	db $04
Sfx3_0B_Data_5851:
	db $80, $c0, $20, $a6, $c7
	db $04
Sfx3_0B_Data_5857:
	db $80, $c0, $20, $9d, $c7
	db $04
Sfx3_0B_Data_585D:
	db $80, $c0, $20, $bd, $c7
	db $04
Sfx3_0B_Data_5863:
	db $80, $f0, $20, $bd, $c7
	db $04
Sfx3_0B_Data_5869:
	db $80, $80, $20, $bd, $c7
	db $04
Sfx3_0B_Data_586F:
	db $80, $20, $9d, $87, $14
Sfx3_0B_Data_5874:
	db $80, $20, $9d, $87, $08
Sfx3_0B_Data_5879:
	db $80, $20, $7b, $87, $08
Sfx3_0B_Data_587E:
	db $80, $20, $8e, $87, $08
Sfx3_0B_Data_5883:
	db $80, $20, $a6, $87, $14
Sfx3_0B_Data_5888:
	db $80, $20, $9d, $87, $14
Sfx3_0B_Data_588D:
	db $80, $20, $bd, $87, $14
Sfx3_0B_Data_5892:
	db $80, $20, $bd, $87, $08
Sfx3_0B_Data_5897:
	db $80, $20, $bd, $87, $2c
; same number in LA
Sfx3_0C_Init:
	ld a, $08
	ld [wSfx3Counter], a
	call Sfx3_02_Shared_62C2
	ld hl, Sfx3_0C_Data_58E0
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_0C_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l2:
	ld hl, Sfx3_0C_Data_58D0
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

Sfx3_0C_Data_58D0:
	db $ff, $fe
	db $ff, $fc
	db $ff, $f8
	db $ff, $e8
	db $00, $14
	db $00, $02
	db $00, $04
	db $00, $06
Sfx3_0C_Data_58E0:
	db $80, $00, $40, $c0, $87, $01
	db $80, $00, $60, $c0, $87, $01
; same number in LA
Sfx3_0D_Init:
	ld a, $10
	ld [wSfx3Counter], a
	call Sfx3_0D_Shared_62B3
	ld hl, Sfx3_0D_Data_5928
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_0D_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_0D_Data_5924
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
	ld hl, Sfx3_0D_Data_592E
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_0D_Data_5924:
	db $ff, $a0
	db $00, $c0
Sfx3_0D_Data_5928:
	db $80, $00, $20, $70, $80, $02
Sfx3_0D_Data_592E:
	db $80, $00, $60, $70, $80, $02
; same number in LA
Sfx3_0E_Init:
	call Sfx3_0D_Shared_62B3
	ld hl, Sfx3_0E_Data_595A
	jp Sfx3_Start

Sfx3_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx3_Stop
	ld hl, Sfx3_0E_Data_5952
	call GetPointer
	jp SetRegs_Ch3

Sfx3_0E_Data_5952:
	dw Sfx3_0E_Data_5960, Sfx3_0E_Data_5966, Sfx3_0E_Data_5960, Sfx3_0E_Data_595A
Sfx3_0E_Data_595A:
	db $80, $fb, $20, $00, $c2, $03
Sfx3_0E_Data_5960:
	db $80, $fd, $40, $80, $c3, $04
Sfx3_0E_Data_5966:
	db $80, $fd, $60, $00, $c4, $05
; same number in LA
Sfx3_0F_Init:
	ld a, [wSfx3Playing]
	cp $0f
	jp z, Sfx3_Refuse
	call Sfx3_02_Shared_62C2
	ld hl, Sfx3_0F_Data_598B
	jp Sfx3_Start

Sfx3_0F_Play:
	call Sfx_IncStep
	cp $02
	jp z, Sfx3_Stop
	ld hl, Sfx3_0F_Data_5991
	jp SetRegs_Ch3

Sfx3_0F_Data_598B:
	db $80, $fb, $60, $d2, $c7, $01
Sfx3_0F_Data_5991:
	db $80, $fb, $40, $d2, $c7, $02
; same number in LA
Sfx3_10_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_10_Data_5AAE
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
	ld hl, Sfx3_10_Data_59CE
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $60
	ld [bc], a
	ld hl, Sfx3_10_Data_5AB4
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_10_Data_59CE:
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
Sfx3_10_Data_5AAE:
	db $80, $00, $20, $a0, $81, $02
Sfx3_10_Data_5AB4:
	db $80, $00, $60, $22, $86, $02
; same number in LA
Sfx3_11_Init:
	ld a, $0c
	ld [wSfx3Counter], a
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_11_Data_5B05
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_11_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
	ld hl, Sfx3_11_Data_5B01
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
	ld hl, Sfx3_11_Data_5B01
	jp Sfx3_AddPitch

.l1:
	ld hl, Sfx3_11_Data_5B0B
.l3:
	call Sfx3_LoadPitch
	xor a
	ld [bc], a
	jp SetRegs_Ch3

.l2:
	ld hl, Sfx3_11_Data_5B11
	jr .l3

Sfx3_11_Data_5B01:
	db $00, $e0
	db $ff, $a0
Sfx3_11_Data_5B05:
	db $80, $00, $20, $00, $84, $01
Sfx3_11_Data_5B0B:
	db $80, $00, $40, $80, $85, $01
Sfx3_11_Data_5B11:
	db $80, $00, $60, $80, $85, $01
; same number in LA
Sfx3_12_Init:
	ld a, $12
	ld [wSfx3Counter], a
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_12_Data_5B53
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_12_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_12_Data_5B4F
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
	ld hl, Sfx3_12_Data_5B59
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_12_Data_5B4F:
	db $01, $00
	db $fe, $c0
Sfx3_12_Data_5B53:
	db $80, $00, $20, $40, $86, $02
Sfx3_12_Data_5B59:
	db $80, $00, $60, $c0, $84, $02
; same number in LA
Sfx3_13_Init:
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx3_13_Play_l0
	ld hl, Sfx3_13_Data_5BC1
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_13_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $01
	ld [de], a
	call Sfx_IncStep
	cp $06
	jr z, .l1
	cp $07
	jr z, .l2
	ld hl, Sfx3_13_Data_5BB7
	jp Sfx3_AddPitch

.l2:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l3
	cp $01
	jr z, .l3
	ld hl, Sfx3_13_Data_5BC7
.l4:
	xor a
	ld [bc], a
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld a, [wSfx3Counter]
	cp $01
	jr z, .l2
	cp $04
	ret z
	ld a, $06
	ld [de], a
	xor a
	ldh [rNR32], a
	ret

.l3:
	ld hl, Sfx3_13_Data_5BCD
	jr .l4

Sfx3_13_Data_5BB7:
	db $02, $40
	db $01, $40
	db $ff, $f2
	db $00, $0e
	db $ff, $f2
Sfx3_13_Data_5BC1:
	db $80, $00, $20, $16, $84, $01
Sfx3_13_Data_5BC7:
	db $80, $00, $20, $26, $84, $01
Sfx3_13_Data_5BCD:
	db $80, $00, $20, $08, $84, $01
; same number in LA
Sfx3_14_Init:
	ld a, [wSfx3Playing]
	cp $14
	jp z, Sfx3_Refuse
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_14_Data_5BFD
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_14_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_14_Data_5BFB
	jp Sfx3_AddPitch

Sfx3_14_Data_5BFB:
	db $00, $0e
Sfx3_14_Data_5BFD:
	db $80, $00, $40, $80, $87, $01
; same number in LA
Sfx3_15_Init:
	call Sfx3_08_Shared_62CC
	ld hl, Sfx3_15_Data_5C2B
	jp Sfx3_StartPriority

Sfx3_15_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_15_Data_5C21
	call GetPointer
	jp SetRegs_Ch3

Sfx3_15_Data_5C21:
	dw Sfx3_15_Data_5C31, Sfx3_15_Data_5C37, Sfx3_15_Data_5C3D, Sfx3_15_Data_5C43, Sfx3_15_Data_5C49
Sfx3_15_Data_5C2B:
	db $80, $d0, $20, $40, $c7, $14
Sfx3_15_Data_5C31:
	db $80, $c0, $20, $64, $c7, $0c
Sfx3_15_Data_5C37:
	db $80, $90, $40, $78, $c7, $40
Sfx3_15_Data_5C3D:
	db $80, $c0, $20, $54, $c7, $06
Sfx3_15_Data_5C43:
	db $80, $c0, $40, $46, $c7, $0c
Sfx3_15_Data_5C49:
	db $80, $a0, $20, $5e, $c7, $20
; same number in LA
Sfx3_16_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	cp $07
	jp z, Sfx3_Refuse
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_16_Data_5CBB
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
	ld hl, Sfx3_16_Data_5C9D
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
	ld hl, Sfx3_16_Data_5CC1
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_16_Data_5C9D:
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
Sfx3_16_Data_5CBB:
	db $80, $00, $20, $60, $80, $02
Sfx3_16_Data_5CC1:
	db $80, $00, $60, $60, $85, $02
Sfx3_17_Data_5CC7:
	db $02, $46, $8a, $ce, $fc, $96, $04, $04, $02, $46, $8a, $ce, $fc, $96, $04, $04
; same number in LA
Sfx3_17_Init:
	ld hl, wCh4Flags
	set 7, [hl]
	ld a, $03
	ld [wSfx3Counter], a
	ld hl, Sfx3_17_Data_5E04
	call SetRegs_Ch4
	call Sfx1_01_Shared_62BD
	ld hl, Sfx3_17_Data_5CC7
	call Sfx3_LoadWave
	ld hl, Sfx3_17_Data_5E18
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
	ld hl, Sfx3_17_Data_5D5C
	jp Sfx3_AddPitch

.l1:
	ld a, $40
.l4:
	ldh [rNR32], a
	ld bc, wSfx3Step
	jr .l3

.l2:
	ld hl, Sfx3_17_Data_5E09
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
	ld hl, Sfx3_17_Data_5E0E
	call SetRegs_Ch4
	ld hl, Sfx3_17_Data_5E1E
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l6:
	ld a, $40
	ld [bc], a
	ld hl, Sfx3_17_Data_5E13
	call SetRegs_Ch4
	ld hl, Sfx3_17_Data_5E24
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l5:
	ld hl, wCh4Flags
	res 7, [hl]
	ld hl, $7a20	; LA's Sfx4_StopRegs, not relocated: here $7A20 is inside Sfx1_AddPitch
	call SetRegs_Ch4
	jp Sfx3_StopWithRegs

Sfx3_17_Data_5D5C:
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
Sfx3_17_Data_5E04:
	db $00, $19, $00, $80, $01
Sfx3_17_Data_5E09:
	db $00, $a0, $00, $80, $01
Sfx3_17_Data_5E0E:
	db $00, $50, $00, $80, $01
Sfx3_17_Data_5E13:
	db $00, $20, $00, $80, $01
Sfx3_17_Data_5E18:
	db $80, $00, $60, $a0, $86, $02
Sfx3_17_Data_5E1E:
	db $80, $00, $40, $20, $87, $02
Sfx3_17_Data_5E24:
	db $80, $00, $60, $20, $87, $02
; same number in LA
Sfx3_18_Init:
	ld a, $0e
	ld [wSfx3Counter], a
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_18_Data_5E66
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_18_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_18_Data_5E62
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
	ld hl, Sfx3_18_Data_5E66
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_18_Data_5E62:
	db $00, $60
	db $ff, $00
Sfx3_18_Data_5E66:
	db $80, $00, $20, $40, $86, $00
; same number in LA
Sfx3_19_Init:
	call Sfx3_08_Shared_62CC
	ld hl, Sfx3_19_Data_5EC5
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
	ld hl, Sfx3_19_Data_5EA1
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

Sfx3_19_Data_5EA1:
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
Sfx3_19_Data_5EC5:
	db $80, $00, $40, $30, $87, $01
; same number in LA
Sfx3_1A_Init:
	ld a, [wSfx3Playing]
	cp $03
	jp z, Sfx3_Refuse
	cp $06
	jp z, Sfx3_Refuse
	cp $07
	jp z, Sfx3_Refuse
	call Sfx3_0D_Shared_62B3
	ld hl, Sfx3_1A_Data_5F01
	jp Sfx3_Start

Sfx3_1A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx3_Stop
	ld hl, Sfx3_1A_Data_5EFB
	call GetPointer
	jp SetRegs_Ch3

Sfx3_1A_Data_5EFB:
	dw Sfx3_1A_Data_5F07, Sfx3_1A_Data_5F0D, Sfx3_1A_Data_5F07
Sfx3_1A_Data_5F01:
	db $80, $fd, $40, $20, $c0, $02
Sfx3_1A_Data_5F07:
	db $80, $fd, $40, $80, $c1, $02
Sfx3_1A_Data_5F0D:
	db $80, $fd, $40, $00, $c2, $02
; same number in LA
Sfx3_1B_Init:
	call Sfx3_08_Shared_62CC
	ld hl, Sfx3_1B_Data_5F3F
	jp Sfx3_StartPriority

Sfx3_1B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx3_Stop
	ld hl, Sfx3_1B_Data_5F31
	call GetPointer
	jp SetRegs_Ch3

Sfx3_1B_Data_5F31:
	dw Sfx3_1B_Data_5F57, Sfx3_1B_Data_5F45, Sfx3_1B_Data_5F5D, Sfx3_1B_Data_5F4B, Sfx3_1B_Data_5F63, Sfx3_1B_Data_5F51, Sfx3_1B_Data_5F69
Sfx3_1B_Data_5F3F:
	db $80, $ea, $20, $62, $c7, $06
Sfx3_1B_Data_5F45:
	db $80, $ea, $20, $74, $c7, $06
Sfx3_1B_Data_5F4B:
	db $80, $ea, $20, $7b, $c7, $06
Sfx3_1B_Data_5F51:
	db $80, $ea, $20, $a7, $c7, $06
Sfx3_1B_Data_5F57:
	db $80, $ea, $60, $62, $c7, $06
Sfx3_1B_Data_5F5D:
	db $80, $ea, $60, $74, $c7, $06
Sfx3_1B_Data_5F63:
	db $80, $ea, $60, $7b, $c7, $06
Sfx3_1B_Data_5F69:
	db $80, $ea, $60, $a7, $c7, $06
; same number in LA
Sfx3_1C_Init:
	ld a, $04
	ld [wSfx3Counter], a
	call Sfx3_08_Shared_62CC
	ld hl, Sfx3_1C_Data_5FB3
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_1C_Play:
	call Sfx_IncStep
	cp $07
	jr z, .l0
	ld hl, Sfx3_1C_Data_5FA7
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $02
	jr z, .l1
	ld hl, Sfx3_1C_Data_5FB9
.l2:
	xor a
	ld [bc], a
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_1C_Data_5FB3
	jr .l2

Sfx3_1C_Data_5FA7:
	db $00, $06
	db $00, $04
	db $00, $02
	db $ff, $f8
	db $ff, $f0
	db $ff, $e8
Sfx3_1C_Data_5FB3:
	db $80, $00, $20, $60, $87, $01
Sfx3_1C_Data_5FB9:
	db $80, $00, $60, $60, $87, $01
; same number in LA
Sfx3_1D_Init:
	ret

Sfx3_1D_Play:
	ret

; same number in LA
Sfx3_1E_Init:
	ld a, $07
	ld [wSfxVarDC], a
	ld a, $40
	ld [wSfx3Counter], a
	call Sfx3_0D_Shared_62B3
	ld hl, Sfx3_1E_Data_6011
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
	ld hl, Sfx3_1E_Data_600B
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

Sfx3_1E_Data_600B:
	db $ff, $ff
	db $ff, $fe
	db $ff, $fb
Sfx3_1E_Data_6011:
	db $80, $00, $20, $ff, $87, $01
Sfx3_1F_Data_6017:
	db $06, $c6, $06, $c6, $06, $c6, $06, $c6, $89, $bd, $ed, $b9, $87, $53, $23, $57
; same number in LA
Sfx3_1F_Init:
	call Sound_Stop
	ld hl, Sfx3_1F_Data_6017
	call Sfx3_LoadWave
	ld a, $05
	ld [wSfx3Counter], a
	xor a
	ld [$c8dd], a
	ld hl, Sfx3_1F_Data_609A
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_1F_Play:
	call Sfx3_DecCounter
	cp $01
	jr z, .l0
	ld a, [$c8dd]
	cp $11
	jr z, .l1
	cp $0a
	jr nc, .l2
	ld a, $01
.l3:
	ld bc, wSfx3Step
	ld [bc], a
	ld hl, Sfx3_1F_Data_6090
	jp Sfx3_AddPitch

.l1:
	ld a, $05
	jr .l3

.l2:
	ld a, $03
	jr .l3

.l0:
	push bc
	ld bc, $c8dd
	call Sfx_IncStep
	pop bc
	cp $12
	jr z, .l4
	add a, $05
	ld [wSfx3Counter], a
	ld a, [$c8dd]
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
	jp .l4

Sfx3_1F_Data_6090:
	db $ff, $f4
	db $00, $32
	db $ff, $f0
	db $00, $70
	db $ff, $e8
Sfx3_1F_Data_609A:
	db $80, $00, $40, $a0, $87, $01
; same number in LA
Sfx3_20_Init:
	call Sfx3_0D_Shared_62B3
	ld a, $03
	ld [$c8de], a
	ld a, $90
	ld [wSfx3Counter], a
	ld hl, Sfx3_20_Data_60EF
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_20_Play:
	call Sfx3_DecCounter
	jr z, .l0
.l4:
	ld a, [$c8de]
	cp $03
	jr z, .l1
	cp $02
	jr z, .l2
	ld a, $01
.l3:
	ld [bc], a
	ld hl, Sfx3_20_Data_60E9
	jp Sfx3_AddPitch

.l1:
	ld a, $03
	jr .l3

.l2:
	ld a, $02
	jr .l3

.l0:
	push de
	ld de, $c8de
	call Sfx_DecTimer
	pop de
	jp z, Sfx3_StopWithRegs
	ld a, $90
	ld [wSfx3Counter], a
	jr .l4

Sfx3_20_Data_60E9:
	db $00, $01
	db $00, $02
	db $00, $03
Sfx3_20_Data_60EF:
	db $80, $00, $60, $80, $84, $02
; same number in LA
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
	ld hl, Sfx3_21_Data_616A
	call Sfx2_LoadPitch
	jp SetRegs_Ch2

Sfx3_21_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
	cp $0a
	jr z, .l1
.l3:
	ld hl, Sfx3_21_Data_6158
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

Sfx3_21_Data_6158:
	db $ff, $ff
	db $ff, $fe
	db $ff, $fd
	db $ff, $fc
	db $ff, $fa
	db $ff, $f6
	db $ff, $f2
	db $ff, $ee
	db $00, $3a
Sfx3_21_Data_616A:
	db $00, $97, $80, $87, $01
; same number in LA
Sfx3_22_Init:
	ld a, $2e
	ld [wSfx3Counter], a
	xor a
	ld [$c8e1], a
	call Sfx3_0D_Shared_62B3
	ld hl, Sfx3_22_Data_61C9
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_22_Play:
	call Sfx3_DecCounter
	jr z, .l0
.l4:
	ld a, [$c8e1]
	cp $01
	jr z, .l1
	cp $02
	jr z, .l2
	cp $03
	jr z, .l3
	ld a, $01
.l5:
	ld [bc], a
	ld hl, Sfx3_22_Data_61C1
	jp Sfx3_AddPitch

.l0:
	push bc
	ld bc, $c8e1
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

Sfx3_22_Data_61C1:
	db $00, $08
	db $00, $06
	db $00, $04
	db $00, $02
Sfx3_22_Data_61C9:
	db $80, $00, $40, $30, $84, $01
; same number in LA
Sfx3_23_Init:
	call Sfx3_06_Shared_62B8
	ld hl, Sfx3_23_Data_621C
	jp Sfx3_StartPriority

Sfx3_23_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0d
	jp z, Sfx3_StopWithRegs
	ld hl, Sfx3_23_Data_6204
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

Sfx3_23_Data_6204:
	dw Sfx3_23_Data_6222, Sfx3_23_Data_6228, Sfx3_23_Data_623A, Sfx3_23_Data_623D, Sfx3_23_Data_6240, Sfx3_23_Data_6243, Sfx3_23_Data_622E, Sfx3_23_Data_6240, Sfx3_23_Data_6243, Sfx3_23_Data_6234, Sfx3_23_Data_6240, Sfx3_23_Data_6243
Sfx3_23_Data_621C:
	db $80, $f2, $60, $df, $87, $02
Sfx3_23_Data_6222:
	db $80, $f2, $40, $df, $87, $02
Sfx3_23_Data_6228:
	db $80, $f2, $20, $df, $87, $03
Sfx3_23_Data_622E:
	db $80, $f2, $40, $a2, $87, $03
Sfx3_23_Data_6234:
	db $80, $f2, $60, $a2, $87, $03
Sfx3_23_Data_623A:
	db $be, $87, $03
Sfx3_23_Data_623D:
	db $a2, $87, $03
Sfx3_23_Data_6240:
	db $83, $87, $03
Sfx3_23_Data_6243:
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

; unreferenced (also unreferenced in LA)
Unused_6264:
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

Sfx3_0D_Shared_62B3:
	ld hl, Sfx3_0D_Data_62FF
	jr Sfx3_LoadWave

Sfx3_06_Shared_62B8:
	ld hl, Sfx3_06_Data_630F
	jr Sfx3_LoadWave

Sfx1_01_Shared_62BD:
	ld hl, Sfx1_01_Data_62EF
	jr Sfx3_LoadWave

Sfx3_02_Shared_62C2:
	ld hl, Sfx3_02_Data_631F
	jr Sfx3_LoadWave

Sfx3_13_Play_l0:
	ld hl, Sfx3_13_Data_632F
	jr Sfx3_LoadWave

Sfx3_08_Shared_62CC:
	ld hl, Sfx3_08_Data_62DF
	jr Sfx3_LoadWave

Sfx3_WritePeriod:
	ld c, $1d
	ld b, $02
	jp SetRegs_Copy

Sfx3_Refuse:
	xor a
	ld [wSfx3Request], a
	jp Sfx3_Update

Sfx3_08_Data_62DF:
	db $8c, $ef, $fe, $c8, $84, $21, $12, $48, $8c, $ef, $fe, $c8, $84, $21, $12, $48
Sfx1_01_Data_62EF:
	db $00, $22, $44, $66, $88, $aa, $cc, $cc, $00, $22, $44, $66, $88, $aa, $cc, $cc
Sfx3_0D_Data_62FF:
	db $0f, $0f, $1f, $1f, $2f, $2f, $3f, $3f, $40, $40, $50, $50, $60, $60, $70, $70
Sfx3_06_Data_630F:
	db $0c, $0c, $00, $22, $44, $88, $aa, $cc, $ee, $00, $6c, $60, $00, $6c, $60, $00
Sfx3_02_Data_631F:
	db $ff, $ff, $ee, $dd, $ee, $dd, $ee, $ff, $ff, $c9, $63, $21, $00, $00, $04, $8c
Sfx3_13_Data_632F:
	db $01, $23, $45, $67, $89, $ac, $ee, $ee, $fe, $dc, $ba, $98, $76, $54, $32, $10
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
	dw Sfx4_21_Init
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
	dw Sfx4_21_Play
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
	dw Sfx4_3C_Play
	dw Sfx4_3D_Play
