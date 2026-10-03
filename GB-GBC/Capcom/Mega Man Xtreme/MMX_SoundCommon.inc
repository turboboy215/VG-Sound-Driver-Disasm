;; Instruments and waves ($4C41-$4F48), identical in the three sound banks.


;; Instruments (8 bytes): attack, decay, sustain, release, vibrato speed
;; (b7 = reset per note), vibrato depth, duty/noise bits, wave (CH3, 1-based)
SoundInstruments:
	INSTRUMENT $1F, $07, $60, $05, $00, $00, $00, 1  ; 0
	INSTRUMENT $1F, $04, $90, $07, $5A, $05, $00, 0  ; 1
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 2  ; 2
	INSTRUMENT $1E, $00, $D0, $07, $80, $00, $08, 3  ; 3
	INSTRUMENT $1F, $08, $A0, $07, $00, $00, $00, 0  ; 4
	INSTRUMENT $0C, $00, $80, $05, $BC, $02, $00, 4  ; 5
	INSTRUMENT $0C, $00, $D0, $05, $00, $00, $00, 5  ; 6
	INSTRUMENT $1F, $08, $90, $05, $00, $00, $00, 0  ; 7
	INSTRUMENT $0C, $00, $D0, $05, $7F, $05, $00, 6  ; 8
	INSTRUMENT $03, $08, $F0, $06, $00, $00, $00, 0  ; 9
	INSTRUMENT $1D, $00, $A0, $06, $00, $00, $00, 0  ; 10
	INSTRUMENT $19, $00, $E0, $07, $FF, $04, $00, 0  ; 11
	INSTRUMENT $1F, $05, $D0, $05, $00, $00, $00, 0  ; 12
	INSTRUMENT $1F, $08, $A0, $07, $00, $00, $00, 0  ; 13
	INSTRUMENT $1F, $00, $C0, $05, $00, $00, $00, 0  ; 14
	INSTRUMENT $1F, $08, $F0, $08, $32, $7F, $00, 7  ; 15
	INSTRUMENT $1F, $00, $F0, $00, $00, $00, $00, 8  ; 16
	INSTRUMENT $1D, $06, $C0, $06, $00, $00, $00, 0  ; 17
	INSTRUMENT $1F, $07, $F0, $01, $00, $00, $00, 0  ; 18
	INSTRUMENT $1A, $08, $F0, $06, $00, $00, $00, 0  ; 19
	INSTRUMENT $0C, $08, $F0, $06, $00, $00, $00, 0  ; 20
	INSTRUMENT $1F, $05, $A0, $04, $80, $00, $00, 0  ; 21
	INSTRUMENT $1F, $07, $80, $07, $A8, $7F, $00, 0  ; 22
	INSTRUMENT $1F, $07, $A0, $05, $00, $00, $00, 0  ; 23
	INSTRUMENT $1C, $08, $F0, $08, $BF, $3C, $00, 0  ; 24
	INSTRUMENT $1F, $07, $A0, $07, $00, $00, $00, 0  ; 25
	INSTRUMENT $1F, $07, $50, $07, $00, $00, $00, 0  ; 26
	INSTRUMENT $1F, $07, $60, $05, $00, $00, $00, 0  ; 27
	INSTRUMENT $1F, $08, $F0, $08, $D4, $56, $00, 9  ; 28
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 10  ; 29
	INSTRUMENT $1F, $08, $F0, $05, $46, $43, $00, 11  ; 30
	INSTRUMENT $1F, $05, $D0, $04, $88, $51, $08, 0  ; 31
	INSTRUMENT $1F, $07, $80, $02, $00, $00, $00, 0  ; 32
	INSTRUMENT $1F, $07, $50, $07, $B8, $14, $00, 0  ; 33
	INSTRUMENT $16, $08, $F0, $01, $00, $00, $00, 0  ; 34
	INSTRUMENT $1F, $07, $D0, $04, $9C, $7D, $08, 0  ; 35
	INSTRUMENT $1F, $08, $F0, $04, $00, $00, $00, 0  ; 36
	INSTRUMENT $1F, $08, $F0, $08, $86, $28, $00, 12  ; 37
	INSTRUMENT $1F, $08, $F0, $01, $00, $00, $00, 0  ; 38
	INSTRUMENT $0A, $08, $F0, $08, $00, $00, $00, 0  ; 39
	INSTRUMENT $1D, $08, $F0, $06, $FF, $07, $00, 0  ; 40
	INSTRUMENT $1D, $08, $F0, $06, $FF, $7F, $08, 0  ; 41
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 13  ; 42
	INSTRUMENT $1F, $08, $F0, $07, $80, $00, $00, 0  ; 43
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 14  ; 44
	INSTRUMENT $1F, $08, $F0, $08, $92, $7F, $00, 0  ; 45
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 15  ; 46
	INSTRUMENT $1F, $08, $F0, $06, $FF, $7F, $08, 0  ; 47
	INSTRUMENT $1F, $08, $F0, $08, $80, $00, $00, 16  ; 48
	INSTRUMENT $1F, $08, $F0, $08, $FF, $7F, $00, 17  ; 49
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 18  ; 50
	INSTRUMENT $1F, $08, $A0, $07, $00, $00, $00, 0  ; 51
	INSTRUMENT $0C, $00, $D0, $05, $00, $00, $00, 0  ; 52
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 53
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 54
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 55
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 56
	INSTRUMENT $1F, $00, $F0, $04, $03, $74, $00, 19  ; 57
	INSTRUMENT $1F, $00, $F0, $00, $01, $0A, $00, 0  ; 58

;; CH3 waves (16 bytes each)
SoundWaves:
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00 ; wave 1
	db $BD, $EE, $CA, $A6, $57, $9B, $CC, $A8, $53, $35, $68, $99, $75, $31, $02, $44 ; wave 2
	db $8D, $B7, $9B, $80, $49, $85, $BE, $93, $67, $41, $7D, $B7, $9B, $60, $49, $73 ; wave 3
	db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 4
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 5
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 6
	db $8B, $DF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 7
	db $BD, $EE, $FE, $ED, $BA, $88, $78, $8A, $45, $67, $77, $65, $42, $10, $00, $12 ; wave 8
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 9
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 10
	db $9D, $D9, $99, $55, $8C, $C8, $88, $44, $7B, $B7, $77, $33, $6A, $A6, $66, $22 ; wave 11
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00 ; wave 12
	db $89, $BC, $DE, $EF, $FF, $EE, $DC, $BA, $87, $54, $32, $11, $01, $12, $34, $57 ; wave 13
	db $89, $BC, $DE, $EF, $FF, $EE, $DC, $BA, $87, $54, $32, $11, $01, $12, $34, $57 ; wave 14
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 15
	db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 16
	db $8C, $EC, $A7, $51, $38, $AA, $BB, $75, $55, $56, $79, $99, $AA, $83, $35, $55 ; wave 17
	db $8A, $CD, $EE, $DD, $BA, $87, $66, $67, $89, $99, $98, $76, $43, $11, $12, $36 ; wave 18
	db $8E, $81, $8E, $70, $7E, $81, $8E, $70, $7E, $81, $7D, $70, $8E, $80, $7D, $70 ; wave 19
