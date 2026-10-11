; Link's Awakening DX music, bank $1E: songs, bank $1E $4B1C-$4CFE

Song14_Ch1:
	dw Pattern_4B22
	LIST_LOOP Song14_Ch1
Pattern_4B22:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song49_Header:
	SONG $00, LengthTable_4ACA, Song49_Ch1, Song49_Ch2, Song49_Ch3, Song49_Ch4
Song27_Header:
	SONG $00, LengthTable_4ACA, Song27_Ch1, Song27_Ch2, Song27_Ch3, Song27_Ch4
Song27_Ch1:
	dw Pattern_4B5E
Song49_Ch1:
	dw Pattern_4B65
	LIST_LOOP Song49_Ch1
Song27_Ch2:
	dw Pattern_4B87
Song49_Ch2:
	dw Pattern_4B97
	LIST_LOOP Song49_Ch2
Song27_Ch3:
	dw Pattern_4C19
Song49_Ch3:
	dw Pattern_4C1E
	LIST_LOOP Song49_Ch3
Song27_Ch4:
	dw Pattern_4C2A
Song49_Ch4:
	dw Pattern_4C2F
	LIST_LOOP Song49_Ch4
Pattern_4B5E:
	db L1, REST, L2D, REST, LEN10, REST, PAT_END
Pattern_4B65:
	INSTR $10, $00, $80
	REPEAT $04
	db L16, Cs7, As6, Fs6, Cs6
	REPEAT_END
	REPEAT $04
	db D7, B6, G6, D6
	REPEAT_END
	REPEAT $04
	db Cs7, As6, Fs6, Cs6
	REPEAT_END
	REPEAT $04
	db B6, Gs6, E6, B5
	REPEAT_END
	db PAT_END
Pattern_4B87:
	INSTR $60, $81, $41
	db LEN10, REST, Fs5, B5, E6, B5, D6, L1, Cs6, L4, REST, PAT_END
Pattern_4B97:
	INSTR $34, $00, $00
	REPEAT $03
	db L16, Cs7, As6, Fs6, Cs6
	REPEAT_END
	INSTR $43, $00, $00
	db Cs7, As6, Fs6, Cs6
	INSTR $62, $00, $00
	db D7, B6, G6, D6
	INSTR $43, $00, $00
	db D7, B6, G6, D6
	INSTR $34, $00, $00
	REPEAT $02
	db D7, B6, G6, D6
	REPEAT_END
	REPEAT $02
	db Cs7, As6, Fs6, Cs6
	REPEAT_END
	INSTR $43, $00, $00
	db Cs7, As6, Fs6, Cs6
	INSTR $62, $00, $00
	db Cs7, As6, Fs6, Cs6
	INSTR $82, $00, $00
	db B6, Gs6, E6, B5
	INSTR $62, $00, $00
	db B6, Gs6, E6, B5
	INSTR $43, $00, $00
	REPEAT $02
	db B6, Gs6, E6, B5
	REPEAT_END
	db PAT_END
Wave_4BF9:
	db $66, $66, $66, $66, $00, $00, $00, $00, $66, $66, $66, $66, $00, $00, $00, $00
Wave_4C09:
	db $00, $22, $44, $55, $66, $66, $88, $88, $aa, $aa, $cc, $cc, $04, $84, $04, $84
Pattern_4C19:
	db L1, REST, L2D, REST, PAT_END
Pattern_4C1E:
	INSTR_WAVE Wave_4BF9, $20
	CH3_FADEOUT_ON
	REPEAT $20
	db L8, Cs2, Cs3
	REPEAT_END
	db PAT_END
Pattern_4C2A:
	db L1, REST, L2D, REST, PAT_END
Pattern_4C2F:
	REPEAT $20
	db L8, NOISE_1A, L16, NOISE_1A, NOISE_1A
	REPEAT_END
	db PAT_END
Song50_Header:
	SONG $02, LengthTable_4ABB, Song50_Ch1, Song50_Ch2, Song50_Ch3, Song50_Ch4
Song50_Ch1:
	dw Pattern_4C71
Song50_Ch1_Loop:
	dw Pattern_4C87
	dw Pattern_4C99
	dw Pattern_4CAB
	dw Pattern_4C99
	LIST_LOOP Song50_Ch1_Loop
Song50_Ch2:
	dw Pattern_4C78
	dw Pattern_4C87
	dw Pattern_4C7D
	dw Pattern_4C99
	dw Pattern_4C82
	dw Pattern_4CAB
	dw Pattern_4C7D
	dw Pattern_4C99
	LIST_LOOP Song50_Ch2
Song50_Ch3:
	dw Pattern_4CBD
	LIST_LOOP Song50_Ch3
Song50_Ch4:
	dw Pattern_4CF0
	LIST_LOOP Song50_Ch4
Pattern_4C71:
	INSTR $43, $00, $03
	db L32, REST, PAT_END
Pattern_4C78:
	INSTR $43, $00, $00
	db PAT_END
Pattern_4C7D:
	INSTR $71, $00, $00
	db PAT_END
Pattern_4C82:
	INSTR $91, $00, $00
	db PAT_END
Pattern_4C87:
	REPEAT $02
	db L16, B4, Cs5, D5, L8D, A5, L16, B4, Cs5, D5, L8D, Gs5, L4, REST
	REPEAT_END
	db PAT_END
Pattern_4C99:
	REPEAT $02
	db L16, Cs5, Ds5, E5, L8D, B5, L16, Cs5, Ds5, E5, L8D, As5, L4, REST
	REPEAT_END
	db PAT_END
Pattern_4CAB:
	REPEAT $02
	db L16, Ds5, F5, Fs5, L8D, Cs6, L16, Ds5, F5, Fs5, L8D, C6, L4, REST
	REPEAT_END
	db PAT_END
Pattern_4CBD:
	INSTR_WAVE Wave_4C09, $20
	CH3_FADEOUT_ON
	REPEAT $02
	db L8, B3, B2, B2, B3, B2, B2, B3, B2
	REPEAT_END
	REPEAT $02
	db Cs4, Cs3, Cs3, Cs4, Cs3, Cs3, Cs4, Cs3
	REPEAT_END
	REPEAT $02
	db Ds4, Ds3, Ds3, Ds4, Ds3, Ds3, Ds4, Ds3
	REPEAT_END
	REPEAT $02
	db Cs4, Cs3, Cs3, Cs4, Cs3, Cs3, Cs4, Cs3
	REPEAT_END
	db PAT_END
Pattern_4CF0:
	REPEAT $02
	db L16, NOISE_1A, NOISE_1A, NOISE_1A, L8D, NOISE_1A
	REPEAT_END
	db L16, NOISE_1A, NOISE_15, NOISE_15, NOISE_15, PAT_END
