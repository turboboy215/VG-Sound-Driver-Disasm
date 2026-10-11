; Dr. Mario sound driver: tables, bank 1 $6A9F-$6CA7

VibratoTable_Fall:
	db $00, $ff, $ff, $fe, $ee, $ed, $dd, $dc, $cc, $cc, $cc, $bb, $bb, $bb, $ba, $aa
	db $aa, $aa, $aa, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99
VibratoTable_Wobble:
	db $00, $00, $00, $00, $00, $00, $10, $00, $0f, $00, $00, $11, $00, $0f, $f0, $01
	db $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12
	db $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10
	db $ff, $ef, $01, $12, $10, $ff, $ef
.tail:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
NoteTable:
	dw $0f00	; index 0: never played ($00 ends a pattern)
	dw $002c	; C2
	dw $009c	; Cs2
	dw $0106	; D2
	dw $016b	; Ds2
	dw $01c9	; E2
	dw $0223	; F2
	dw $0277	; Fs2
	dw $02c6	; G2
	dw $0312	; Gs2
	dw $0356	; A2
	dw $039b	; As2
	dw $03da	; B2
	dw $0416	; C3
	dw $044e	; Cs3
	dw $0483	; D3
	dw $04b5	; Ds3
	dw $04e5	; E3
	dw $0511	; F3
	dw $053b	; Fs3
	dw $0563	; G3
	dw $0589	; Gs3
	dw $05ac	; A3
	dw $05ce	; As3
	dw $05ed	; B3
	dw $060a	; C4
	dw $0627	; Cs4
	dw $0642	; D4
	dw $065b	; Ds4
	dw $0672	; E4
	dw $0689	; F4
	dw $069e	; Fs4
	dw $06b2	; G4
	dw $06c4	; Gs4
	dw $06d6	; A4
	dw $06e7	; As4
	dw $06f7	; B4
	dw $0706	; C5
	dw $0714	; Cs5
	dw $0721	; D5
	dw $072d	; Ds5
	dw $0739	; E5
	dw $0744	; F5
	dw $074f	; Fs5
	dw $0759	; G5
	dw $0762	; Gs5
	dw $076b	; A5
	dw $0773	; As5
	dw $077b	; B5
	dw $0783	; C6
	dw $078a	; Cs6
	dw $0790	; D6
	dw $0797	; Ds6
	dw $079d	; E6
	dw $07a2	; F6
	dw $07a7	; Fs6
	dw $07ac	; G6
	dw $07b1	; Gs6
	dw $07b6	; A6
	dw $07ba	; As6
	dw $07be	; B6
	dw $07c1	; C7
	dw $07c4	; Cs7
	dw $07c8	; D7
	dw $07cb	; Ds7
	dw $07ce	; E7
	dw $07d1	; F7
	dw $07d4	; Fs7
	dw $07d6	; G7
	dw $07d9	; Gs7
	dw $07db	; A7
	dw $07dd	; As7
	dw $07df	; B7
NoiseTable:
	db $00, $00, $00, $00, $00, $c0	; (offsets 0-5: not a drum)
	db $61, $00, $3a, $00, $c0	; NOISE1 (pattern byte $06)
	db $b1, $00, $29, $01, $c0	; NOISE2 (pattern byte $0b)
	db $a1, $00, $20, $04, $c0	; NOISE3 (pattern byte $10)
	db $a1, $00, $f4, $5e, $c0	; NOISE4 (pattern byte $15)
	db $71, $00, $00, $3f, $c0	; NOISE5 (pattern byte $1a)
Wave_6BC3:
	db $23, $33, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $8a, $a8, $32, $10
Wave_6BD3:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10
Wave_6BE3:
	db $77, $23, $56, $78, $99, $98, $76, $67, $9a, $df, $fe, $c9, $85, $77, $77, $77
Wave_6BF3:
	db $11, $23, $56, $78, $99, $98, $76, $67, $9a, $df, $fe, $c9, $85, $42, $11, $31
Wave_6C03:
	db $11, $12, $22, $33, $34, $44, $55, $55, $66, $66, $66, $66, $66, $11, $22, $32
Wave_6C13:
	db $87, $66, $65, $55, $54, $44, $43, $32, $22, $11, $11, $66, $61, $11, $66, $66
LengthTables:
	db $01, $02, $04, $08, $10, $20, $06, $0c, $18
LengthTable_6C2C:
	db $00, $03, $06, $0c, $18, $30, $09, $12, $24, $04, $08, $02, $04, $08, $10, $20, $40, $0c, $18, $30, $05, $00, $01, $03, $05, $0a, $14, $28, $50, $0f, $1e, $3c
LengthTable_6C4C:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $08, $10, $01, $04, $02
LengthTable_6C5A:
	db $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $09, $12, $01, $02
LengthTable_6C67:
	db $04, $08, $10, $20, $40, $80, $18, $30, $60, $0a, $15, $01, $02, $c0, $04, $09, $12, $24, $48, $90, $1b, $36, $6c, $0c, $18
SongPanTable:
	db $01, $18, $ff, $fb	; song 01: mode, period, NR51 A, NR51 B
	db $01, $18, $ff, $eb	; song 02: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $b7	; song 03: mode, period, NR51 A, NR51 B
	db $01, $60, $de, $ed	; song 04: mode, period, NR51 A, NR51 B
	db $01, $ff, $de, $ff	; song 05: mode, period, NR51 A, NR51 B
	db $01, $18, $fe, $be	; song 06: mode, period, NR51 A, NR51 B
	db $01, $40, $ff, $f7	; song 07: mode, period, NR51 A, NR51 B
	db $01, $18, $ed, $e7	; song 08: mode, period, NR51 A, NR51 B
	db $01, $20, $ff, $f7	; song 09: mode, period, NR51 A, NR51 B
	db $01, $20, $ff, $f7	; song 10: mode, period, NR51 A, NR51 B
