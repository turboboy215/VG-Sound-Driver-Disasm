; Metal Slug 2 SFX: update and effect tables, bank $29 $4000-$411B

; byte $1E: tag byte at the start of the bank (the music bank has $1D)
BankTag:
	db $1e
	jp Sfx_Update

; Called once per frame before the music banks: ch1, ch3 and ch4 effects, then clear
; the SFX requests.
Sfx_Update:
	call Sfx1_Update
	call Sfx3_Update
	call Sfx4_Update
	xor a
	ld [wSfx1Request], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ret

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
	dw Sfx1_0F_Init
	dw Sfx1_10_Init
	dw Sfx1_11_Init
	dw Sfx1_12_Init
	dw Sfx1_12_Init
	dw Sfx1_14_Init
	dw Sfx1_15_Init
	dw Sfx1_16_Init
	dw Sfx1_17_Init
	dw Sfx1_18_Init
	dw Sfx1_19_Init
	dw Sfx1_1A_Init
	dw Sfx1_1B_Init
	dw Sfx1_1C_Init
	dw Sfx1_1D_Init
	dw Sfx1_1E_Init
	dw Sfx1_1F_Init
	dw Sfx1_20_Init
	dw Sfx1_21_Init
	dw Sfx1_22_Init
	dw Sfx1_23_Init
	dw Sfx1_24_Init
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
	dw Sfx1_34_Init
	dw Sfx1_35_Init
	dw Sfx1_36_Init
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
	dw Sfx1_0F_Play
	dw Sfx1_10_Play
	dw Sfx1_11_Play
	dw Sfx1_12_Play
	dw Sfx1_12_Play
	dw Sfx1_14_Play
	dw Sfx1_15_Play
	dw Sfx1_16_Play
	dw Sfx1_17_Play
	dw Sfx1_18_Play
	dw Sfx1_19_Play
	dw Sfx1_1A_Play
	dw Sfx1_1B_Play
	dw Sfx1_1C_Play
	dw Sfx1_1D_Play
	dw Sfx1_1E_Play
	dw Sfx1_1F_Play
	dw Sfx1_20_Play
	dw Sfx1_21_Play
	dw Sfx1_22_Play
	dw Sfx1_23_Play
	dw Sfx1_24_Play
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
	dw Sfx1_34_Play
	dw Sfx1_35_Play
	dw Sfx1_36_Play
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
