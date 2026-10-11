; Super Mario Bros. Deluxe SFX: init, update, tables, bank $1F $4000-$43A1

; Entry points: init, stop, update.
	jp Sfx_Init

	jp Sound_Stop

	jp Sfx_Update

; Clear $DE00-$DEFF, switch the APU on and write the register list Sfx_InitRegs
; (count, first register, values; 0 ends it).
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
	db $10, $30	; wave RAM ($FF30): 16 bytes
	ds 16, 0
	db $05, LOW(rNR10), $08, $c0, $00, $00, $80
	db $04, LOW(rNR21), $c0, $00, $00, $80
	db $05, LOW(rNR30), $00, $00, $00, $00, $00
	db $04, LOW(rNR41), $00, $00, $00, $80
	db $00
; Called once per frame after the music bank: the three effect slots, then clear the
; requests.
Sfx_Update:
	call Sfx1_Update
	call Sfx2_Update
	call Sfx4_Update
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx2Request], a
	ld [wSfx4Request], a
	ret

	ds 137, 0	; $4077-$40FF unused
; copy of the music note table; the ch1 "note" requests read it from entry 25 on
SfxNoteTable:
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
	dw $060a	; $82
	dw $0627	; $83
	dw $0642	; $84
	dw $065b	; $85
	dw $0672	; $86
	dw $0689	; $87
	dw $069e	; $88
	dw $06b2	; $89
	dw $06c4	; $8a
	dw $06d6	; $8b
	dw $06e7	; $8c
	dw $06f7	; $8d
	dw $0706	; $8e
	dw $0714	; $8f
	dw $0721	; $90
	dw $072d	; $91
	dw $0739	; $92
	dw $0744	; $93
	dw $074f	; $94
	dw $0759	; $95
	dw $0762	; $96
	dw $076b	; $97
	dw $0774	; $98
	dw $077b	; $99
	dw $0783	; $9a
	dw $078a	; $9b
	dw $0790	; $9c
	dw $0797	; $9d
	dw $079d	; $9e
	dw $07a2	; $9f
	dw $07a7	; $a0
	dw $07ac	; $a1
	dw $07b1	; $a2
	dw $07b6	; $a3
	dw $07ba	; $a4
	dw $07be	; $a5
	dw $07c1	; $a6
	dw $07c5	; $a7
	dw $07c8	; $a8
	dw $07cb	; $a9
	dw $07ce	; $aa
	dw $07d1	; $ab
	dw $07d4	; $ac
	dw $07d6	; $ad
	dw $07d9	; $ae
	dw $07db	; $af
	dw $07dd	; $b0
	dw $07df	; $b1
; Like SetRegs_ChN, but a zero byte leaves its register alone.
SetRegsSkip0_Ch1:
	ld b, $05
	ld c, $10
	ld de, wSfx1Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Ch2:
	ld b, $04
	ld c, $16
	ld de, wSfx2Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Ch3_Unused:
	ld b, $05
	ld c, $1a
	ld de, wSfx4Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Ch4_Unused:
	ld b, $04
	ld c, $20
	ld de, wSfx4Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Copy:
	ld a, [hl+]
	and a
	jr z, .next
	ldh [c], a
.next:
	inc c
	dec b
	jr nz, SetRegsSkip0_Copy
	ld a, [hl]
	ld [de], a
	ret

Sfx1_InitTable:
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
	dw Sfx1_Dummy_Init
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
	dw Sfx1_58_Init
	dw Sfx1_59_Init
	dw Sfx1_5A_Init
	dw Sfx1_5B_Init
	dw Sfx1_5C_Init
	dw Sfx1_5D_Init
	dw Sfx1_5E_Init
	dw Sfx1_5F_Init
	dw Sfx1_60_Init
	dw Sfx1_61_Init
	dw Sfx1_62_Init
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
	dw Sfx1_6F_Init
	dw Sfx1_70_Init
	dw Sfx1_71_Init
	dw Sfx1_72_Init
	dw Sfx1_73_Init
	dw Sfx1_74_Init
	dw Sfx1_75_Init
	dw Sfx1_76_Init
	dw Sfx1_77_Init
	dw Sfx1_78_Init
Sfx1_PlayTable:
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
	dw Sfx1_Dummy_Play
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
	dw Sfx1_4E_Play
	dw Sfx1_4F_Play
	dw Sfx1_50_Play
	dw Sfx1_51_Play
	dw Sfx1_52_Play
	dw Sfx1_53_Play
	dw Sfx1_54_Play
	dw Sfx1_55_Play
	dw Sfx1_56_Play
	dw Sfx1_57_Play
	dw Sfx1_58_Play
	dw Sfx1_59_Play
	dw Sfx1_5A_Play
	dw Sfx1_5B_Play
	dw Sfx1_5C_Play
	dw Sfx1_5D_Play
	dw Sfx1_5E_Play
	dw Sfx1_5F_Play
	dw Sfx1_60_Play
	dw Sfx1_61_Play
	dw Sfx1_62_Play
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
	dw Sfx1_6F_Play
	dw Sfx1_70_Play
	dw Sfx1_71_Play
	dw Sfx1_72_Play
	dw Sfx1_73_Play
	dw Sfx1_74_Play
	dw Sfx1_75_Play
	dw Sfx1_76_Play
	dw Sfx1_77_Play
	dw Sfx1_78_Play
