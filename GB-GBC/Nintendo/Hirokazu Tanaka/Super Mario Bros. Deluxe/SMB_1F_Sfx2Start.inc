; Super Mario Bros. Deluxe SFX: slot 2 dispatch, bank $1F $448C-$4736

; Effects $01-$04 and $24-$3D. $01-$04 always start; the others depend on the priority of
; the playing effect (1: $25, $2B-$2E; 2: $2C-$2E; 3, 4: $2D, $2E). Effect $24 is refused
; while effect $38-$3C plays. Nothing runs while wSfx2Paused is set.
Sfx2_Update:
	ld hl, wSfx2Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $05
	jr c, .checkPriority
	cp $24
	jp c, Sfx2_Refuse
	cp $3e
	jp nc, Sfx2_Refuse
.checkPriority:
	ld a, [wSfx2Priority]
	and a
	jp z, .check24
	cp $01
	jr z, .priority1
	cp $02
	jr z, .priority2
	ld a, [hl]
	cp $2d
	jp c, Sfx2_Refuse
	cp $2f
	jp nc, Sfx2_Refuse
	jr .start

.priority2:
	ld a, [hl]
	cp $2c
	jp c, Sfx2_Refuse
	cp $2f
	jp nc, Sfx2_Refuse
	jr .start

.priority1:
	ld a, [hl]
	cp $25
	jp z, .start
	cp $2b
	jp c, Sfx2_Refuse
	cp $2f
	jp nc, Sfx2_Refuse
.check24:
	ld a, [hl]
	cp $24
	jr nz, .start
	ld a, [wSfx2Playing]
	cp $38
	jr c, .start
	cp $3d
	jr nc, .start
	jp Sfx2_Refuse

.start:
	ld a, [hl]
	ld hl, Sfx2_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx2_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx2Timer
	ld bc, wSfx2Step
	ld a, [wSfx2Paused]
	and a
	ret nz
	jp hl

Sfx2_InitTable:
	dw Sfx2_01_Init
	dw Sfx2_02_Init
	dw Sfx2_03_Init
	dw Sfx2_04_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_Dummy_Init
	dw Sfx2_25_Init
	dw Sfx2_26_Init
	dw Sfx2_27_Init
	dw Sfx2_28_Init
	dw Sfx2_29_Init
	dw Sfx2_2A_Init
	dw Sfx2_2B_Init
	dw Sfx2_2C_Init
	dw Sfx2_2D_Init
	dw Sfx2_2E_Init
	dw Sfx2_2F_Init
	dw Sfx2_30_Init
	dw Sfx2_31_Init
	dw Sfx2_32_Init
	dw Sfx2_33_Init
	dw Sfx2_34_Init
	dw Sfx2_35_Init
	dw Sfx2_36_Init
	dw Sfx2_37_Init
	dw Sfx2_38_Init
	dw Sfx2_39_Init
	dw Sfx2_3A_Init
	dw Sfx2_3B_Init
	dw Sfx2_3C_Init
	dw Sfx2_3D_Init
Sfx2_PlayTable:
	dw Sfx2_01_Play
	dw Sfx2_02_Play
	dw Sfx2_03_Play
	dw Sfx2_04_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_Dummy_Play
	dw Sfx2_25_Play
	dw Sfx2_26_Play
	dw Sfx2_27_Play
	dw Sfx2_28_Play
	dw Sfx2_29_Play
	dw Sfx2_2A_Play
	dw Sfx2_2B_Play
	dw Sfx2_2C_Play
	dw Sfx2_2D_Play
	dw Sfx2_2E_Play
	dw Sfx2_2F_Play
	dw Sfx2_30_Play
	dw Sfx2_31_Play
	dw Sfx2_32_Play
	dw Sfx2_33_Play
	dw Sfx2_34_Play
	dw Sfx2_35_Play
	dw Sfx2_36_Play
	dw Sfx2_37_Play
	dw Sfx2_38_Play
	dw Sfx2_39_Play
	dw Sfx2_3A_Play
	dw Sfx2_3B_Play
	dw Sfx2_3C_Play
	dw Sfx2_3D_Play
CopyWave:
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

LoadWave:
	xor a
	ldh [rNR30], a
	jp CopyWave

Sfx2_Refuse:
	xor a
	ld [wSfx2Request], a
	jp Sfx2_Update

Sfx4_InitTable:
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_Dummy_Init
	dw Sfx4_3E_Init
	dw Sfx4_3F_Init
	dw Sfx4_40_Init
	dw Sfx4_41_Init
	dw Sfx4_42_Init
	dw Sfx4_43_Init
	dw Sfx4_44_Init
	dw Sfx4_45_Init
	dw Sfx4_46_Init
	dw Sfx4_47_Init
	dw Sfx4_48_Init
Sfx4_PlayTable:
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_Dummy_Play
	dw Sfx4_3E_Play
	dw Sfx4_3F_Play
	dw Sfx4_40_Play
	dw Sfx4_41_Play
	dw Sfx4_42_Play
	dw Sfx4_43_Play
	dw Sfx4_44_Play
	dw Sfx4_45_Play
	dw Sfx4_46_Play
	dw Sfx4_47_Play
	dw Sfx4_48_Play
