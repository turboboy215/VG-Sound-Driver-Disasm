; Link's Awakening DX music, bank $1B: songs, bank $1B $4B1A-$4E2B

Song04_Ch3:
	dw Pattern_4B20
	LIST_LOOP Song04_Ch3
Pattern_4B20:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
; unreferenced
Wave_4B26:
	db $00, $22, $44, $55, $66, $66, $88, $88, $aa, $aa, $cc, $cc, $04, $84, $04, $84
Song10_Header:
	SONG $00, LengthTable_4AB9, Song10_Ch1, Song10_Ch2, Song10_Ch3, Song10_Ch4
Song10_Ch1:
	dw Pattern_4B51
	LIST_END
Song10_Ch2:
	dw Pattern_4B61
	LIST_END
Song10_Ch3:
	dw Pattern_4B6F
	LIST_END
Song10_Ch4:
	dw Pattern_4B81
	LIST_END
Pattern_4B51:
	INSTR $60, $21, $00
	CH3_SFX_PAUSE
	db L8, A5, As5, LEN10, B5, C6, Cs6, L1D, D6
	CH3_SFX_RESUME
	db PAT_END
Pattern_4B61:
	INSTR $80, $21, $41
	db L8, C5, Cs5, LEN10, D5, Ds5, E5, L1D, F5, PAT_END
Pattern_4B6F:
	INSTR_WAVE Wave_6EC1, $20
	CH3_FADEOUT_ON
	db L8, F4, Fs4, LEN10, G4, Gs4, A4
	CH3_FADEOUT_OFF
	db L1, As4, L2, REST, PAT_END
Pattern_4B81:
	db L4, REST, LEN10, NOISE_15, NOISE_1A, NOISE_1A
	REPEAT $1e
	db L32, NOISE_15
	REPEAT_END
	db L4D, REST, PAT_END
Song40_Header:
	SONG $04, LengthTable_4AF5, Song40_Ch1, Song40_Ch2, Song40_Ch3, 0
Song40_Ch1:
	dw Pattern_4BD0
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C0A
	dw Pattern_4C74
	LIST_LOOP Song40_Ch1
Song40_Ch2:
	dw Pattern_4BD5
	dw Pattern_4C3F
	LIST_LOOP Song40_Ch2
Song40_Ch3:
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C05
	dw Pattern_4C74
	LIST_LOOP Song40_Ch3
Pattern_4BD0:
	INSTR $31, $00, $40
	db PAT_END
Pattern_4BD5:
	INSTR $30, $81, $80
	REPEAT $08
	db L4, REST, L8, A4, As4, L4, C5, L8, F5, A5, L4D, A5, L16, G5, Fs5, L2
	db G5, L8, REST, G5, A5, As5, L4, A5, G5, L1, C5, L2, C7, L4D, F6, L16
	db E6, F6, L2, G6, C6, D6, L1D, A6
	REPEAT_END
	db PAT_END
Pattern_4C05:
	INSTR_WAVE Wave_6ED1, $40
	CH3_FADEOUT_ON
Pattern_4C0A:
	REPEAT $02
	db L8, F3, A3, C4, A3
	REPEAT_END
	REPEAT $02
	db F3, B3, D4, B3
	REPEAT_END
	db F3, As3, D4, As3, E3, As3, Cs4, As3, A3, C4, G4, E4, F4, D4, C4, A3
	REPEAT $02
	db G3, As3, D4, As3
	REPEAT_END
	REPEAT $02
	db G3, As3, Cs4, As3
	REPEAT_END
	REPEAT $04
	db F3, A3, C4, A3
	REPEAT_END
	db PAT_END
Pattern_4C3F:
	INSTR $61, $00, $80
	db L2, REST
	DROP_ON
	db LEN12, REST, LEN13, A3, A3, LEN12, A3, LEN10, A3
	DROP_OFF
	db LEN12, C4, LEN13, C4, D4, LEN12, E4, LEN10, D4, L4, C4, G4, E4, C5, L2, G4
	db LEN12, G4, LEN13, G4, Gs4, LEN12, G4, LEN10, Fs4, L2, Ds4, L4, D4, L4D, G4, L2
	db G4, L4D, REST, PAT_END
Pattern_4C74:
	REPEAT $0b
	db L2, REST
	REPEAT_END
	db PAT_END
Song3C_Header:
	SONG $00, LengthTable_4AE6, Song3C_Ch1, Song3C_Ch2, Song3C_Ch3, Song3C_Ch4
Song3C_Ch1:
	dw Pattern_4CA5
Song3C_Ch1_Loop:
	dw Pattern_4CDE
	LIST_LOOP Song3C_Ch1_Loop
Song3C_Ch2:
	dw Pattern_4CB2
Song3C_Ch2_Loop:
	dw Pattern_4CEF
	LIST_LOOP Song3C_Ch2_Loop
Song3C_Ch3:
	dw Pattern_4CBF
Song3C_Ch3_Loop:
	dw Pattern_4D3F
	LIST_LOOP Song3C_Ch3_Loop
Song3C_Ch4:
	dw Pattern_4CCC
Song3C_Ch4_Loop:
	dw Pattern_4D88
	LIST_LOOP Song3C_Ch4_Loop
Pattern_4CA5:
	INSTR $60, $00, $41
	db L4D, REST, L16, D5, LEN10, REST, L1D, Ds5, PAT_END
Pattern_4CB2:
	INSTR $40, $00, $01
	db L4D, REST, L16, Cs6, LEN10, REST, L1D, D6, PAT_END
Pattern_4CBF:
	INSTR_WAVE Wave_4D2F, $20
	db L4D, REST, L16, Gs5, LEN10, REST, L1D, A5, PAT_END
Pattern_4CCC:
	db L4D, REST, L16, REST, LEN10, REST, L1, REST, L16, DRUM, L8, DRUM, DRUM, L16, DRUM, L8
	db DRUM, PAT_END
Pattern_4CDE:
	INSTR $22, $00, $80
	DROP_ON
	REPEAT $20
	db L16, F5, E6, C6, A5, B6, G6, E6
	REPEAT_END
	db PAT_END
Pattern_4CEF:
	INSTR $81, $00, $40
	db L8D, As4, L32, As4, C5, L8D, D5, L16, C5, L4, As4, F5, D5, As5, L2, F5
	db L8D, F5, L32, F5, Fs5, L8D, F5, L16, E5, L2, Cs5, L4, C5, F5, L2, As4
	db L1, REST, REST, REST
	INSTR $61, $00, $80
	DROP_ON
	db L16, D4, L8D, D4, L16, D4, L8D, D4, L16, D4, L8, D4, D4, L16, D4, L8
	db D4
	DROP_OFF
	db PAT_END
Wave_4D2F:
	db $8a, $df, $da, $86, $31, $01, $36, $86, $8a, $df, $da, $86, $31, $01, $36, $86
Pattern_4D3F:
	INSTR_WAVE Wave_4D2F, $20
	DROP_ON
	REPEAT $02
	db LEN10, B3, REST, L32, REST, L16, REST
	REPEAT_END
	db L8D, REST, LEN10, B3, REST, L32, REST, L16, REST
	REPEAT $02
	db LEN10, B3, REST, L32, REST
	REPEAT_END
	db L16, REST, L4, REST
	REPEAT $02
	db LEN10, B3, REST, L32, REST, L16, REST
	REPEAT_END
	db L8D, REST, LEN10, B3, REST, L32, REST, L16, REST
	REPEAT $02
	db LEN10, B3, REST, L32, REST
	REPEAT_END
	db L16, REST, L8D, REST, LEN10, B3, REST, L32, REST, PAT_END
Pattern_4D88:
	REPEAT $07
	db L16, NOISE_15, NOISE_15, NOISE_15, NOISE_15, DRUM, NOISE_15, NOISE_15, NOISE_15, NOISE_15, NOISE_15, NOISE_15, NOISE_15, DRUM, NOISE_15, NOISE_15
	db NOISE_1A
	REPEAT_END
	REPEAT $02
	db DRUM, DRUM, NOISE_15, NOISE_15
	REPEAT_END
	db DRUM, DRUM, NOISE_15, DRUM, NOISE_15, DRUM, DRUM, NOISE_15, PAT_END
Song37_Header:
	SONG $00, LengthTable_4AB9, Song37_Ch1, Song37_Ch2, Song37_Ch3, 0
Song37_Ch1:
	dw Pattern_4DC9
	LIST_LOOP Song37_Ch1
Song37_Ch2:
	dw Pattern_4DDF
	LIST_LOOP Song37_Ch2
Song37_Ch3:
	dw Pattern_4E15
	LIST_LOOP Song37_Ch3
Pattern_4DC9:
	INSTR $43, $00, $80
	db L4D, Cs5, Cs5, Cs5, Cs5, C5, C5, C5, C5, As4, As4, As4, As4, Gs4, As4, C5
	db Ds5, PAT_END
Pattern_4DDF:
	INSTR $40, $21, $80
	db L2D, Gs5, L4, REST, L8, G5, L4, As5, L2D, Ds5, L8, REST, L4, Gs5, L8, Gs4
	db L4, As4, L8, C5, L4, Cs5, L8, C5, L4, Cs5, L4D, G4, F5, L1D, Ds5, L8
	db REST, PAT_END
Wave_4E05:
	db $44, $44, $44, $42, $00, $00, $00, $00, $44, $44, $44, $42, $00, $00, $00, $00
Pattern_4E15:
	INSTR_WAVE Wave_4E05, $20
	CH3_FADEOUT_ON
	db L4D, C5, C5, As4, As4, As4, As4, Gs4, Gs4, Gs4, Gs4, G4, G4, Fs4, Fs4, A4
	db C5, PAT_END
