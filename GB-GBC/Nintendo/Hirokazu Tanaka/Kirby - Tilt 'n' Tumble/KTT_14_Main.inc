; Kirby Tilt 'n' Tumble SFX: init, update, tables, bank $14 $4000-$4295

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
; Called once per frame after bank $11: the four slots for effects $80 and up, then clear
; the requests.
Sfx_Update:
	call Sfx1_Update
	call Sfx2_Update
	call Sfx3_Update
	call Sfx4_Update
	xor a
	ld [wSfx1Request], a
	ld [wSfx2Request], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ret

	ds $4100 - $407A, 0	; unused
; effects $80-$97 (indexed from 0: request & $7F)
Sfx1_InitTable:
	dw Sfx1_80_Init
	dw Sfx1_81_Init
	dw Sfx1_82_Init
	dw Sfx1_83_Init
	dw Sfx1_84_Init
	dw Sfx1_85_Init
	dw Sfx1_86_Init
	dw Sfx1_87_Init
	dw Sfx1_88_Init
	dw Sfx1_89_Init
	dw Sfx1_8A_Init
	dw Sfx1_8B_Init
	dw Sfx1_8C_Init
	dw Sfx1_8D_Init
	dw Sfx1_8E_Init
	dw Sfx1_8F_Init
	dw Sfx1_90_Init
	dw Sfx1_91_Init
	dw Sfx1_92_Init
	dw Sfx1_90_Init
	dw Sfx1_80_Init
	dw Sfx1_80_Init
	dw Sfx1_80_Init
	dw Sfx1_80_Init
Sfx1_PlayTable:
	dw Sfx1_80_Play
	dw Sfx1_81_Play
	dw Sfx1_82_Play
	dw Sfx1_83_Play
	dw Sfx1_83_Play
	dw Sfx1_83_Play
	dw Sfx1_86_Play
	dw Sfx1_87_Play
	dw Sfx1_88_Play
	dw Sfx1_89_Play
	dw Sfx1_8A_Play
	dw Sfx1_8B_Play
	dw Sfx1_8C_Play
	dw Sfx1_8D_Play
	dw Sfx1_8E_Play
	dw Sfx1_8F_Play
	dw Sfx1_90_Play
	dw Sfx1_91_Play
	dw Sfx1_92_Play
	dw Sfx1_90_Play
	dw Sfx1_80_Play
	dw Sfx1_80_Play
	dw Sfx1_80_Play
	dw Sfx1_80_Play
; effects $80-$8F
Sfx2_InitTable:
	dw Sfx2_80_Init
	dw Sfx2_81_Init
	dw Sfx2_82_Init
	dw Sfx2_80_Init
	dw Sfx2_84_Init
	dw Sfx2_85_Init
	dw Sfx2_86_Init
	dw Sfx2_87_Init
	dw Sfx2_88_Init
	dw Sfx2_89_Init
	dw Sfx2_8A_Init
	dw Sfx2_8B_Init
	dw Sfx2_80_Init
	dw Sfx2_80_Init
	dw Sfx2_80_Init
	dw Sfx2_80_Init
Sfx2_PlayTable:
	dw Sfx2_80_Play
	dw Sfx2_81_Play
	dw Sfx2_82_Play
	dw Sfx2_80_Play
	dw Sfx2_84_Play
	dw Sfx2_85_Play
	dw Sfx2_86_Play
	dw Sfx2_87_Play
	dw Sfx2_88_Play
	dw Sfx2_89_Play
	dw Sfx2_8A_Play
	dw Sfx2_8B_Play
	dw Sfx2_80_Play
	dw Sfx2_80_Play
	dw Sfx2_80_Play
	dw Sfx2_80_Play
; effects $80-$87
Sfx3_InitTable:
	dw Sfx3_80_Init
	dw Sfx3_81_Init
	dw Sfx3_82_Init
	dw Sfx3_83_Init
	dw Sfx3_84_Init
	dw Sfx3_85_Init
	dw Sfx3_86_Init
	dw Sfx3_80_Init
Sfx3_PlayTable:
	dw Sfx3_80_Play
	dw Sfx3_81_Play
	dw Sfx3_82_Play
	dw Sfx3_83_Play
	dw Sfx3_84_Play
	dw Sfx3_84_Play
	dw Sfx3_86_Play
	dw Sfx3_80_Play
; effects $80-$90
Sfx4_InitTable:
	dw Sfx4_80_Init
	dw Sfx4_81_Init
	dw Sfx4_82_Init
	dw Sfx4_83_Init
	dw Sfx4_84_Init
	dw Sfx4_85_Init
	dw Sfx4_86_Init
	dw Sfx4_87_Init
	dw Sfx4_88_Init
	dw Sfx4_89_Init
	dw Sfx4_8A_Init
	dw Sfx4_8B_Init
	dw Sfx4_8C_Init
	dw Sfx4_8D_Init
	dw Sfx4_8E_Init
	dw Sfx4_8F_Init
	dw Sfx4_90_Init
Sfx4_PlayTable:
	dw Sfx4_80_Play
	dw Sfx4_81_Play
	dw Sfx4_82_Play
	dw Sfx4_82_Play
	dw Sfx4_84_Play
	dw Sfx4_85_Play
	dw Sfx4_86_Play
	dw Sfx4_87_Play
	dw Sfx4_88_Play
	dw Sfx4_89_Play
	dw Sfx4_8A_Play
	dw Sfx4_8B_Play
	dw Sfx4_8C_Play
	dw Sfx4_8D_Play
	dw Sfx4_8E_Play
	dw Sfx4_8F_Play
	dw Sfx4_90_Play
; unreferenced: copy of the music note table
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
