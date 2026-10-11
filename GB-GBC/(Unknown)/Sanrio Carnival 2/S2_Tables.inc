; Sanrio Carnival 2 sound, bank $01: note table, SFX tables, $69EF-$6AD8

; 85 frequencies, C2-C9 (note 1 = entry 0); the last two are both $07F0. Note n reads entry n-1
; at NoteFreqTable+2n-2.
NoteFreqTable:
	dw $002d, $009d, $0107, $016b, $01ca, $0223, $0277, $02c7	; C_2-
	dw $0312, $0359, $039b, $03da, $0416, $044e, $0483, $04b5	; Gs2-
	dw $04e6, $0511, $053c, $0563, $0589, $05ac, $05ce, $05ed	; E_3-
	dw $0608, $0627, $0642, $065b, $0672, $0689, $069e, $06b2	; C_4-
	dw $06c4, $06d6, $06e7, $06f7, $0706, $0714, $0721, $072d	; Gs4-
	dw $0739, $0744, $074f, $0759, $0762, $076b, $0773, $077b	; E_5-
	dw $0783, $078a, $0790, $0797, $079d, $07a2, $07a7, $07ac	; C_6-
	dw $07b1, $07b6, $07ba, $07be, $07c1, $07c5, $07c8, $07cb	; Gs6-
	dw $07ce, $07d1, $07d4, $07d6, $07d9, $07db, $07dd, $07df	; E_7-
	dw $07e1, $07e3, $07e4, $07e5, $07e7, $07e9, $07ea, $07eb	; C_8-
	dw $07ec, $07ee, $07ef, $07f0, $07f0	; Gs8-
; SFX slot tables: 8 effects each (bit 7 of the request = effect 0). Unused entries -> Sfx_None.
SfxTable1:
	dw Sfx1_0, Sfx1_1, Sfx1_2, Sfx1_3
	dw Sfx1_4, Sfx1_5, Sfx1_6, Sfx1_7
SfxTable2:
	dw Sfx2_0, Sfx2_1, Sfx2_2, Sfx_None
	dw Sfx_None, Sfx_None, Sfx_None, Sfx_None
SfxTable3:
	dw Sfx3_0, Sfx3_1, Sfx3_2, Sfx3_3
	dw Sfx3_4, Sfx_None, Sfx_None, Sfx_None
SfxTable4:
	dw Sfx_None, Sfx_None, Sfx_None, Sfx_None
	dw Sfx_None, Sfx_None, Sfx_None, Sfx_None
