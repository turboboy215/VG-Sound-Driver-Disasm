; Super Mario Land 2 sound driver: tables, bank 4 $5ACC-$5CB2

; vibrato (effect type 1): 20 big-endian period offsets, from frame 25 of a note, cycled
VibratoTable:
	db $00, $00, $00, $00, $00, $01, $00, $01, $00, $02
	db $00, $02, $00, $00, $00, $00, $ff, $ff, $ff, $ff
	db $ff, $fe, $ff, $fe, $00, $00, $00, $01, $00, $02
	db $00, $01, $00, $00, $ff, $ff, $ff, $fe, $ff, $ff
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
	dw $07c5	; Cs7
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
Sfx3_0D_Data_5B86:
	db $88, $84, $00, $00, $00, $00, $00, $00, $88, $84, $00, $00, $00, $00, $00, $00
Wave_5B96:
	db $cc, $cc, $cc, $cc, $00, $00, $00, $00, $cc, $cc, $cc, $cc, $00, $00, $00, $00
Sfx3_17_Data_5BA6:
	db $88, $88, $88, $68, $00, $00, $00, $00, $88, $88, $88, $68, $00, $00, $00, $00
Wave_5BB6:
	db $01, $23, $45, $66, $77, $88, $99, $aa, $01, $23, $45, $66, $77, $88, $99, $aa
Wave_5BC6:
	db $02, $34, $56, $77, $88, $99, $aa, $bb, $cc, $00, $22, $44, $60, $02, $24, $46
Wave_5BD6:
	db $0f, $0f, $1f, $1f, $2f, $2f, $3f, $3f, $40, $40, $50, $50, $60, $60, $70, $70
Wave_5BE6:
	db $08, $08, $00, $22, $44, $88, $aa, $cc, $66, $00, $44, $00, $00, $44, $00, $00
Wave_5BF6:
	db $0c, $0c, $00, $22, $44, $88, $aa, $cc, $ee, $00, $6c, $60, $00, $6c, $60, $00
; ch4 drums. Pattern byte $1F is not looked up here: it plays ch4 effect 3.
NoiseTable:
	db $00, $00, $00, $00, $00, $c0	; (offsets 0-5)
	db $09, $00, $38, $34, $c0	; pattern byte $06: NR42, flag, NR41, NR43, NR44
	db $19, $00, $38, $33, $c0	; pattern byte $0b: NR42, flag, NR41, NR43, NR44
	db $46, $00, $13, $10, $c0	; pattern byte $10: NR42, flag, NR41, NR43, NR44
	db $13, $00, $20, $40, $80	; pattern byte $15: NR42, flag, NR41, NR43, NR44
	db $41, $00, $20, $07, $80	; pattern byte $1a: NR42, flag, NR41, NR43, NR44
LengthTables:
	db $01, $02, $04, $08, $10, $20, $06, $0c, $18, $01, $01, $01, $01, $01, $30
LengthTable_5C34:
	db $01, $03, $06, $0c, $18, $30, $09, $12, $24, $02, $04, $08, $01, $01, $48
LengthTable_5C43:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $02, $05, $03, $01, $01, $60
LengthTable_5C52:
	db $03, $05, $0a, $14, $28, $50, $0f, $1e, $3c, $02, $08, $10, $02, $01, $78
LengthTable_5C61:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $08, $10, $02, $01, $90
LengthTable_5C70:
	db $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $09, $12, $02, $01, $a8
LengthTable_5C7F:
	db $04, $08, $10, $20, $40, $80, $18, $30, $60, $04, $02, $01, $01, $00, $c0
LengthTable_5C8E:
	db $04, $09, $12, $24, $48, $90, $1b, $36, $6c, $05, $0c, $18, $18, $06, $d8
LengthTable_5C9D:
	db $05, $0a, $14, $28, $50, $a0, $1e, $3c, $78, $05, $01, $01, $01, $01, $f0
ReleaseEnvelopes:
	db $10, $32, $22, $47, $81, $20, $00	; NRx2 at the release point, index = low nibble of InstrRelease
