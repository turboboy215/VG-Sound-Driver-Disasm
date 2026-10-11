; Super Mario Land sound driver: tables, bank 3 $6F39-$7093

; Signed nibbles, indexed by NoteFrames / 2 (high nibble on even frames).
; Not bounded: after 110 frames it reads NoteTable.
VibratoTable_Wobble:
	db $00, $00, $00, $00, $00, $00, $10, $00, $0f, $00, $00, $11, $00, $0f, $f0, $01
	db $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12
	db $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10
	db $ff, $ef, $01, $12, $10, $ff, $ef
NoteTable:
	dw $0f00	; index 0: never played
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
	db $a1, $00, $3a, $00, $c0	; NOISE1 (pattern byte $06): NR42, flag, NR41, NR43, NR44
	db $b1, $00, $29, $01, $c0	; NOISE2 (pattern byte $0b): NR42, flag, NR41, NR43, NR44
	db $81, $00, $29, $04, $c0	; NOISE3 (pattern byte $10): NR42, flag, NR41, NR43, NR44
Wave_7017:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10
Wave_7027:
	db $01, $12, $23, $34, $45, $56, $67, $78, $89, $9a, $ab, $bc, $cd, $dd, $ee, $ff
Wave_7037:
	db $01, $23, $56, $78, $99, $98, $76, $67, $9a, $df, $fe, $c9, $85, $42, $11, $00
; used by the ch3 effect
Wave_7047:
	db $01, $23, $45, $67, $89, $ab, $cc, $cd, $00, $0c, $b0, $bb, $00, $fb, $bb, $bb
LengthTable_7057:
	db $00, $03, $06, $0c, $18, $30, $09, $12, $24, $04, $08
LengthTable_7062:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $05, $0a, $01
LengthTable_706E:
	db $00, $05, $0a, $14, $28, $50, $0f, $1e, $3c
LengthTable_7077:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $08, $10
LengthTable_7082:
	db $00, $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $08, $10, $20, $40, $80, $18, $30, $60
