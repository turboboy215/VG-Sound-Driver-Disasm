; Kirby Tilt 'n' Tumble SFX: init, update, tables, bank $11 $4000-$4549

; Entry points (same order as the music banks): init, stop, update.
	jp Sfx_Init

	jp Sound_Stop

	jp Sfx_Update

; Clear $DE00-$DEFF, switch the APU on and write the register list Sfx_InitRegs (count,
; first register, values; 0 ends it). The only sound init the game calls (at boot).
Sfx_Init:
	ld hl, wTranspose
.clear:
	ld [hl], $00
	inc l
	jr nz, .clear
	ld a, $80
	ldh [rNR52], a
	xor a
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a
	ld hl, Sfx_InitRegs
.regs:
	ld a, [hl+]
	and a
	jr z, .done
	ld b, a
	ld a, [hl+]
	ld c, a
.copy:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .copy
	jr .regs

.done:
	ld a, $ff
	ldh [rNR51], a
	ret

Sfx_InitRegs:
	db $10, LOW(_AUD3WAVERAM)	; wave RAM: 16 bytes
	ds 16, 0
	db $05, LOW(rNR10), $08, $c0, $00, $00, $80
	db $04, LOW(rNR21), $c0, $00, $00, $80
	db $05, LOW(rNR30), $00, $00, $00, $00, $00
	db $04, LOW(rNR41), $00, $00, $00, $80
	db $00
; Called once per frame after both music banks, before bank $14. wPcmDone is set by the
; home-bank PCM player when a sample ends (and by the game in a few other places): request
; slot-1 effect $53, and if a hurry jingle had been started (wHurryJingle) restart the song
; that was playing, in hurry mode when wHurryJingle = 1. While wHurryJingle = 1 and no
; sample has just ended, effect $52 is requested every frame.
Sfx_Update:
	ld a, [wPcmDone]
	and a
	jr z, .noPcm
	ld a, $53
	ld [wSfx1Request], a
	ld a, [wHurryJingle]
	and a
	jr z, .slots
	cp $01
	jr nz, .restartSong
	ld a, $01
	ld [wHurryMode], a
.restartSong:
	ld a, [wSongPlaying]
	ld [wSongRequest], a
	xor a
	ld [wHurryJingle], a
	jr .slots

.noPcm:
	ld a, [wHurryJingle]
	cp $01
	jr nz, .slots
	ld a, $52
	ld [wSfx1Request], a
.slots:
	call Sfx1_Update
	call Sfx2_Update
	call Sfx3_Update
	call Sfx4_Update
	xor a
	ld [wPcmDone], a
	ret

	ds $4100 - $40A3, 0	; unused
; effects $01-$7F
Sfx1_InitTable:
	dw Sfx1_01_Init
	dw Sfx1_02_Init
	dw Sfx1_03_Init
	dw Sfx1_04_Init
	dw Sfx1_05_Init
	dw Sfx1_06_Init
	dw Sfx1_07_Init
	dw Sfx1_08_Init
	dw Sfx1_09_Init
	dw Sfx1_0A_Init
	dw Sfx1_0B_Init
	dw Sfx1_0C_Init
	dw Sfx1_0D_Init
	dw Sfx1_0E_Init
	dw Sfx1_01_Init
	dw Sfx1_10_Init
	dw Sfx1_11_Init
	dw Sfx1_12_Init
	dw Sfx1_13_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_16_Init
	dw Sfx1_17_Init
	dw Sfx1_18_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_1B_Init
	dw Sfx1_1C_Init
	dw Sfx1_1D_Init
	dw Sfx1_1E_Init
	dw Sfx1_1F_Init
	dw Sfx1_20_Init
	dw Sfx1_21_Init
	dw Sfx1_22_Init
	dw Sfx1_23_Init
	dw Sfx1_01_Init
	dw Sfx1_25_Init
	dw Sfx1_26_Init
	dw Sfx1_27_Init
	dw Sfx1_28_Init
	dw Sfx1_29_Init
	dw Sfx1_2A_Init
	dw Sfx1_2B_Init
	dw Sfx1_2C_Init
	dw Sfx1_2D_Init
	dw Sfx1_2E_Init
	dw Sfx1_2F_Init
	dw Sfx1_30_Init
	dw Sfx1_31_Init
	dw Sfx1_32_Init
	dw Sfx1_33_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_37_Init
	dw Sfx1_38_Init
	dw Sfx1_39_Init
	dw Sfx1_3A_Init
	dw Sfx1_3B_Init
	dw Sfx1_3C_Init
	dw Sfx1_3D_Init
	dw Sfx1_3E_Init
	dw Sfx1_3F_Init
	dw Sfx1_40_Init
	dw Sfx1_41_Init
	dw Sfx1_42_Init
	dw Sfx1_43_Init
	dw Sfx1_44_Init
	dw Sfx1_45_Init
	dw Sfx1_46_Init
	dw Sfx1_47_Init
	dw Sfx1_48_Init
	dw Sfx1_49_Init
	dw Sfx1_4A_Init
	dw Sfx1_4B_Init
	dw Sfx1_4C_Init
	dw Sfx1_4D_Init
	dw Sfx1_4E_Init
	dw Sfx1_4F_Init
	dw Sfx1_50_Init
	dw Sfx1_51_Init
	dw Sfx1_52_Init
	dw Sfx1_53_Init
	dw Sfx1_54_Init
	dw Sfx1_55_Init
	dw Sfx1_56_Init
	dw Sfx1_57_Init
	dw Sfx1_22_Init
	dw Sfx1_59_Init
	dw Sfx1_5A_Init
	dw Sfx1_5B_Init
	dw Sfx1_5C_Init
	dw Sfx1_5D_Init
	dw Sfx1_5E_Init
	dw Sfx1_5F_Init
	dw Sfx1_60_Init
	dw Sfx1_61_Init
	dw Sfx1_01_Init
	dw Sfx1_63_Init
	dw Sfx1_64_Init
	dw Sfx1_65_Init
	dw Sfx1_66_Init
	dw Sfx1_67_Init
	dw Sfx1_68_Init
	dw Sfx1_69_Init
	dw Sfx1_6A_Init
	dw Sfx1_6B_Init
	dw Sfx1_6C_Init
	dw Sfx1_6D_Init
	dw Sfx1_6E_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_73_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_77_Init
	dw Sfx1_78_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
	dw Sfx1_01_Init
Sfx1_PlayTable:
	dw Sfx1_01_Play
	dw Sfx1_02_Play
	dw Sfx1_03_Play
	dw Sfx1_04_Play
	dw Sfx1_05_Play
	dw Sfx1_06_Play
	dw Sfx1_07_Play
	dw Sfx1_08_Play
	dw Sfx1_09_Play
	dw Sfx1_0A_Play
	dw Sfx1_0B_Play
	dw Sfx1_0C_Play
	dw Sfx1_0D_Play
	dw Sfx1_0E_Play
	dw Sfx1_01_Play
	dw Sfx1_10_Play
	dw Sfx1_11_Play
	dw Sfx1_12_Play
	dw Sfx1_13_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_16_Play
	dw Sfx1_17_Play
	dw Sfx1_18_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_1B_Play
	dw Sfx1_1C_Play
	dw Sfx1_1D_Play
	dw Sfx1_1E_Play
	dw Sfx1_1F_Play
	dw Sfx1_20_Play
	dw Sfx1_21_Play
	dw Sfx1_22_Play
	dw Sfx1_23_Play
	dw Sfx1_01_Play
	dw Sfx1_25_Play
	dw Sfx1_26_Play
	dw Sfx1_27_Play
	dw Sfx1_28_Play
	dw Sfx1_29_Play
	dw Sfx1_2A_Play
	dw Sfx1_2B_Play
	dw Sfx1_2C_Play
	dw Sfx1_2D_Play
	dw Sfx1_2E_Play
	dw Sfx1_2F_Play
	dw Sfx1_30_Play
	dw Sfx1_31_Play
	dw Sfx1_32_Play
	dw Sfx1_33_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_37_Play
	dw Sfx1_38_Play
	dw Sfx1_39_Play
	dw Sfx1_3A_Play
	dw Sfx1_3B_Play
	dw Sfx1_3C_Play
	dw Sfx1_3D_Play
	dw Sfx1_3E_Play
	dw Sfx1_3F_Play
	dw Sfx1_40_Play
	dw Sfx1_41_Play
	dw Sfx1_42_Play
	dw Sfx1_43_Play
	dw Sfx1_44_Play
	dw Sfx1_45_Play
	dw Sfx1_46_Play
	dw Sfx1_47_Play
	dw Sfx1_48_Play
	dw Sfx1_49_Play
	dw Sfx1_4A_Play
	dw Sfx1_4B_Play
	dw Sfx1_4C_Play
	dw Sfx1_4D_Play
	dw Sfx1_4D_Play
	dw Sfx1_4F_Play
	dw Sfx1_50_Play
	dw Sfx1_51_Play
	dw Sfx1_52_Play
	dw Sfx1_53_Play
	dw Sfx1_54_Play
	dw Sfx1_55_Play
	dw Sfx1_56_Play
	dw Sfx1_57_Play
	dw Sfx1_22_Play
	dw Sfx1_59_Play
	dw Sfx1_5A_Play
	dw Sfx1_5B_Play
	dw Sfx1_5C_Play
	dw Sfx1_5D_Play
	dw Sfx1_5E_Play
	dw Sfx1_5F_Play
	dw Sfx1_60_Play
	dw Sfx1_61_Play
	dw Sfx1_01_Play
	dw Sfx1_63_Play
	dw Sfx1_64_Play
	dw Sfx1_65_Play
	dw Sfx1_66_Play
	dw Sfx1_67_Play
	dw Sfx1_68_Play
	dw Sfx1_69_Play
	dw Sfx1_6A_Play
	dw Sfx1_6B_Play
	dw Sfx1_6C_Play
	dw Sfx1_6D_Play
	dw Sfx1_6E_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_73_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_77_Play
	dw Sfx1_78_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
	dw Sfx1_01_Play
; effects $01-$3F
Sfx2_InitTable:
	dw Sfx2_01_Init
	dw Sfx2_02_Init
	dw Sfx2_03_Init
	dw Sfx2_04_Init
	dw Sfx2_05_Init
	dw Sfx2_06_Init
	dw Sfx2_07_Init
	dw Sfx2_08_Init
	dw Sfx2_09_Init
	dw Sfx2_0A_Init
	dw Sfx2_0B_Init
	dw Sfx2_0C_Init
	dw Sfx2_0D_Init
	dw Sfx2_0E_Init
	dw Sfx2_0F_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_17_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_10_Init
	dw Sfx2_17_Init
	dw Sfx2_20_Init
	dw Sfx2_21_Init
	dw Sfx2_22_Init
	dw Sfx2_23_Init
	dw Sfx2_17_Init
	dw Sfx2_25_Init
	dw Sfx2_17_Init
	dw Sfx2_27_Init
	dw Sfx2_28_Init
	dw Sfx2_17_Init
	dw Sfx2_2A_Init
	dw Sfx2_2B_Init
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_01_Init
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
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_17_Init
	dw Sfx2_3F_Init
Sfx2_PlayTable:
	dw Sfx2_01_Play
	dw Sfx2_02_Play
	dw Sfx2_03_Play
	dw Sfx2_04_Play
	dw Sfx2_05_Play
	dw Sfx2_06_Play
	dw Sfx2_07_Play
	dw Sfx2_08_Play
	dw Sfx2_09_Play
	dw Sfx2_0A_Play
	dw Sfx2_0B_Play
	dw Sfx2_0C_Play
	dw Sfx2_0D_Play
	dw Sfx2_0E_Play
	dw Sfx2_0F_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_17_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_10_Play
	dw Sfx2_17_Play
	dw Sfx2_20_Play
	dw Sfx2_21_Play
	dw Sfx2_22_Play
	dw Sfx2_23_Play
	dw Sfx2_17_Play
	dw Sfx2_25_Play
	dw Sfx2_17_Play
	dw Sfx2_27_Play
	dw Sfx2_28_Play
	dw Sfx2_17_Play
	dw Sfx2_2A_Play
	dw Sfx2_2B_Play
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_01_Play
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
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_17_Play
	dw Sfx2_3F_Play
; effects $01-$08
Sfx3_InitTable:
	dw Sfx3_01_Init
	dw Sfx3_02_Init
	dw Sfx3_03_Init
	dw Sfx3_04_Init
	dw Sfx3_05_Init
	dw Sfx3_06_Init
	dw Sfx3_07_Init
	dw Sfx3_08_Init
Sfx3_PlayTable:
	dw Sfx3_01_Play
	dw Sfx3_02_Play
	dw Sfx3_03_Play
	dw Sfx3_04_Play
	dw Sfx3_05_Play
	dw Sfx3_06_Play
	dw Sfx3_07_Play
	dw Sfx3_08_Play
; effects $01-$28
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
	dw Sfx4_0A_Init
	dw Sfx4_1E_Init
	dw Sfx4_1F_Init
	dw Sfx4_20_Init
	dw Sfx4_21_Init
	dw Sfx4_22_Init
	dw Sfx4_0D_Init
	dw Sfx4_24_Init
	dw Sfx4_25_Init
	dw Sfx4_26_Init
	dw Sfx4_27_Init
	dw Sfx4_28_Init
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
	dw Sfx4_0A_Play
	dw Sfx4_1E_Play
	dw Sfx4_1F_Play
	dw Sfx4_20_Play
	dw Sfx4_21_Play
	dw Sfx4_22_Play
	dw Sfx4_0D_Play
	dw Sfx4_24_Play
	dw Sfx4_25_Play
	dw Sfx4_26_Play
	dw Sfx4_27_Play
	dw Sfx4_28_Play
; unreferenced: copy of the music note table (SMB DX used it for its "note" requests)
SfxNoteTable_Unused:
	dw $0f00
	dw $002c
	dw $009c
	dw $0106
	dw $016b
	dw $01c9
	dw $0223
	dw $0277
	dw $02c6
	dw $0312
	dw $0356
	dw $039b
	dw $03da
	dw $0416
	dw $044e
	dw $0483
	dw $04b5
	dw $04e5
	dw $0511
	dw $053b
	dw $0563
	dw $0589
	dw $05ac
	dw $05ce
	dw $05ed
	dw $060a
	dw $0627
	dw $0642
	dw $065b
	dw $0672
	dw $0689
	dw $069e
	dw $06b2
	dw $06c4
	dw $06d6
	dw $06e7
	dw $06f7
	dw $0706
	dw $0714
	dw $0721
	dw $072d
	dw $0739
	dw $0744
	dw $074f
	dw $0759
	dw $0762
	dw $076b
	dw $0774
	dw $077b
	dw $0783
	dw $078a
	dw $0790
	dw $0797
	dw $079d
	dw $07a2
	dw $07a7
	dw $07ac
	dw $07b1
	dw $07b6
	dw $07ba
	dw $07be
	dw $07c1
	dw $07c5
	dw $07c8
	dw $07cb
	dw $07ce
	dw $07d1
	dw $07d4
	dw $07d6
	dw $07d9
	dw $07db
	dw $07dd
	dw $07df
