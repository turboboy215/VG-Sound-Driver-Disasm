; Super Mario Land songs: headers, section lists, patterns, bank 3 $7094-$7FEC

Song01_Header:
	SONG $00, LengthTable_7057, Song01_Ch1, Song01_Ch2, Song01_Ch3, 0
Song02_Header:
	SONG $00, LengthTable_7077, Song02_Ch1, Song02_Ch2, Song02_Ch3, 0
Song03_Header:
	SONG $00, LengthTable_7062, Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
Song04_Header:
	SONG $00, LengthTable_7077, Song04_Ch1, Song04_Ch2, 0, Song04_Ch4
Song05_Header:
	SONG $00, LengthTable_7057, Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
Song06_Header:
	SONG $00, LengthTable_7062, Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song07_Header:
	SONG $00, LengthTable_7062, Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
Song08_Header:
	SONG $00, LengthTable_7077, Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
Song08_Ch1:
	dw Pattern_7118
Song08_Ch1_Loop:
	dw Pattern_7140
	dw Pattern_7140
	dw Pattern_715D
	LIST_LOOP Song08_Ch1_Loop
Song08_Ch2:
	dw Pattern_7120
Song08_Ch2_Loop:
	dw Pattern_7190
	dw Pattern_7190
	dw Pattern_71AD
	LIST_LOOP Song08_Ch2_Loop
Song08_Ch3:
	dw Pattern_7130
Song08_Ch3_Loop:
	dw Pattern_71E2
	dw Pattern_71E2
	dw Pattern_7213
	LIST_LOOP Song08_Ch3_Loop
Song08_Ch4:
	dw Pattern_7265
Song08_Ch4_Loop:
	dw Pattern_7274
	LIST_LOOP Song08_Ch4_Loop
Pattern_7118:
	INSTR $66, $00, $80
	db L1, REST, REST, PAT_END
Pattern_7120:
	INSTR $76, $00, $81
	db L2, Gs4, Fs4, E4, L8T, D4, D4, D4, D4, D4, D4, PAT_END
Pattern_7130:
	INSTR_WAVE Wave_7037, $a0
	db L2, E5, D5, Cs5, L8T, B4, B4, B4, B4, B4, B4, PAT_END
Pattern_7140:
	db L2, REST, L8T, E4, REST, L4, Fs4, L8, Cs5, L4D, REST, L8T, Cs4, Cs5, REST, B4
	db L4, A4, Fs4, L8T, A4, REST, L2, Fs4, L8T, REST, L1, REST, PAT_END
Pattern_715D:
	db L2, REST, L8T, Fs4, REST, Fs4, REST, REST, Fs4, REST, REST, REST, REST, REST, E4, L4
	db D4, Cs4, L8T, B3, REST, Cs4, REST, REST, Gs4, L2, REST, L1, REST, L2, REST, L8T
	db Fs4, REST, Fs4, REST, REST, Fs4, REST, REST, REST, REST, REST, E4, L4, D4, Cs4, L1
	db REST, REST, PAT_END
Pattern_7190:
	db L2, REST, L8T, Cs5, REST, L4, D5, L8, E5, L4D, REST, L8T, A4, E5, REST, D5
	db L4, Cs5, B4, L8T, Cs5, REST, L2, A4, L8T, REST, L1, REST, PAT_END
Pattern_71AD:
	db L2, REST, L8T, D5, REST, D5, REST, REST, D5, REST, REST, REST, REST, REST, Cs5, L4
	db B4, A4, L8T, Gs4, REST, A4, REST, REST, B4, L2, REST, L1, REST, L2, REST, L8T
	db D5, REST, D5, REST, REST, D5, REST, REST, REST, REST, REST, Cs5, L4, B4, A4, L2
	db Gs4, Fs4, E4, D4, PAT_END
Pattern_71E2:
	db L4, A4, L8T, A4, REST, E4, L4, A4, L8T, A4, REST, E4, L4, A4, L8T, A4
	db REST, E4, L4, A4, L8T, A4, REST, E4, L4, D4, L8T, D4, REST, A4, L4, D4
	db L8T, D4, REST, A4, L4, D4, L8T, D4, REST, A4, L4, D4, L8T, D4, REST, A4
	db PAT_END
Pattern_7213:
	db L4, B4, L8T, B4, REST, Fs4, L4, B4, L8T, B4, REST, Fs4, L4, B4, L8T, B4
	db REST, Fs4, L4, B4, L8T, B4, REST, Fs4, L4, E4, L8T, E4, REST, B4, L4, E4
	db L8T, E4, REST, B4, L4, E4, L8T, E4, REST, B4, L4, E4, L8T, E4, REST, B4
	db L4, B4, L8T, B4, REST, Fs4, L4, B4, L8T, B4, REST, Fs4, L4, B4, L8T, B4
	db REST, Fs4, L4, B4, L8T, B4, REST, Fs4, L4, E5, E5, D5, D5, Cs5, Cs5, B4
	db B4, PAT_END
Pattern_7265:
	db L4, NOISE1, NOISE1, NOISE1, NOISE1, NOISE2, NOISE2, L8T, NOISE2, NOISE2, NOISE2, NOISE2, NOISE2, NOISE2, PAT_END
Pattern_7274:
	db L8T, NOISE1, REST, REST, NOISE3, REST, NOISE1, REST, NOISE1, REST, NOISE3, REST, NOISE1, PAT_END
Song04_Ch1:
	dw Pattern_7294
	LIST_LOOP Song04_Ch1
Song04_Ch2:
	dw Pattern_72B5
	LIST_LOOP Song04_Ch2
Song04_Ch4:
	dw Pattern_72D1
	LIST_LOOP Song04_Ch4
Pattern_7294:
	INSTR $73, $00, $80
	db L8T, REST, L8, C3, REST, E3, G2, A2, B2, C3, REST, G3, E3, REST, REST, C3
	db REST, E3, G2, A2, B2, C3, REST, L4, REST, L8T, REST, REST, PAT_END
Pattern_72B5:
	INSTR $93, $00, $80
	db L8, C3, REST, E3, G2, A2, B2, C3, REST, G3, E3, REST, REST, C3, REST, E3
	db G2, A2, B2, C3, REST, L2, REST, PAT_END
Pattern_72D1:
	db L8, NOISE1, REST, REST, NOISE1, REST, NOISE1, NOISE1, REST, NOISE1, NOISE1, REST, REST, NOISE1, REST, REST
	db NOISE1, REST, NOISE1, NOISE1, REST, L2, REST, PAT_END
Song03_Ch1:
	dw Pattern_7320
Song03_Ch1_Loop:
	dw Pattern_7327
	dw Pattern_7327
	dw Pattern_735A
	LIST_LOOP Song03_Ch1_Loop
Song03_Ch2:
	dw Pattern_731B
Song03_Ch2_Loop:
	dw Pattern_7327
	dw Pattern_7327
	dw Pattern_735A
	LIST_LOOP Song03_Ch2_Loop
Song03_Ch3:
	dw Pattern_736E
Song03_Ch3_Loop:
	dw Pattern_7373
	dw Pattern_7373
	dw Pattern_7373
	dw Pattern_7373
	dw Pattern_7385
	dw Pattern_7385
	dw Pattern_7373
	LIST_LOOP Song03_Ch3_Loop
Song03_Ch4:
	dw Pattern_738E
	LIST_LOOP Song03_Ch4
Pattern_731B:
	INSTR $80, $00, $81
	db PAT_END
Pattern_7320:
	INSTR $30, $00, $80
	db L4D, REST, PAT_END
Pattern_7327:
	db L2, G4, L4, Fs4, L8T, Ds4, Fs4, Ds4, LEN11, REST, L2D, D4, L4, G3, Gs3, L8
	db Gs3, As3, L4, Gs3, As3, L1, G3, L2, G4, L4, Fs4, L8T, Ds4, Fs4, Ds4, LEN11
	db REST, L2D, D4, L4, G3, Gs3, L8, Gs3, As3, L4, C4, L16, As3, C4, As3, Gs3
	db L1, G3, PAT_END
Pattern_735A:
	db L1, Gs3, L2, REST, C4, L1, F4, L2, Ds4, L4, Ds4, L8, F4, Ds4, L1, D4
	db REST, REST, REST, PAT_END
Pattern_736E:
	INSTR_WAVE Wave_7037, $a0
	db PAT_END
Pattern_7373:
	db L4, G4, Gs4, G4, Gs4, G4, Gs4, G4, D5, G4, Gs4, G4, Gs4, G4, Gs4, G4
	db F4, PAT_END
Pattern_7385:
	db Gs4, Ds5, Gs4, Ds5, Gs4, Ds5, Gs4, Ds5, PAT_END
Pattern_738E:
	db L4, NOISE1, L8, NOISE1, NOISE1, L4, NOISE1, L8, NOISE1, NOISE1, L4, NOISE1, L8, NOISE1, NOISE1, L4
	db NOISE2, L8, NOISE1, NOISE1, PAT_END
Song02_Ch1:
	dw Pattern_73BE
	LIST_END
Song02_Ch2:
	dw Pattern_73AB
Song02_Ch3:
	dw Pattern_73D4
Pattern_73AB:
	INSTR $a1, $00, $80
	db L32, REST, L16, G5, F5, E5, D5, C5, L8D, REST, L8, G4, REST, C4, REST
Pattern_73BE:
	INSTR $30, $00, $80
	db L16, G5, F5, E5, D5, C5, L8D, REST
	INSTR $a1, $00, $80
	db L8, D5, REST, E5, REST, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_73D4:
	INSTR_WAVE Wave_7037, $20
	db L16, G5, F5, E5, D5, C5, L8D, REST, L8, B5, REST, C6, REST
Song01_Ch1:
	dw Pattern_73ED
	LIST_END
Song01_Ch2:
	dw Pattern_73FF
Song01_Ch3:
	dw Pattern_7411
Pattern_73ED:
	INSTR $60, $00, $80
	db L2D, E5, L8, E5, REST, E5, REST, E5, REST, L2D, Fs5, G5, Gs5, PAT_END
Pattern_73FF:
	INSTR $83, $00, $80
	db L2D, C5, L8, C5, REST, C5, REST, C5, REST, L2D, D5, Ds5, E5, PAT_END
Pattern_7411:
	INSTR_WAVE Wave_7017, $21
	db L2D, G6, L8, G6, REST, G6, REST, G6, REST, L2D, A6, As6, B6, PAT_END
Song05_Ch1:
	dw Pattern_745F
Song05_Ch1_Loop:
	dw Pattern_7491
	dw Pattern_7491
	dw Pattern_7518
	LIST_LOOP Song05_Ch1_Loop
Song05_Ch2:
	dw Pattern_744F
Song05_Ch2_Loop:
	dw Pattern_74B9
	dw Pattern_74B9
	dw Pattern_7548
	LIST_LOOP Song05_Ch2_Loop
Song05_Ch3:
	dw Pattern_746F
Song05_Ch3_Loop:
	dw Pattern_74EF
	dw Pattern_74EF
	dw Pattern_7578
	LIST_LOOP Song05_Ch3_Loop
Song05_Ch4:
	dw Pattern_7485
Song05_Ch4_Loop:
	dw Pattern_75A3
	LIST_LOOP Song05_Ch4_Loop
Pattern_744F:
	INSTR $a2, $00, $80
	db L8, G4, A4, REST, B4, REST, A4, REST, G4, L1, F4, PAT_END
Pattern_745F:
	INSTR $82, $00, $80
	db L8, C5, C5, REST, C5, REST, C5, REST, C5, L1, A4, PAT_END
Pattern_746F:
	INSTR_WAVE Wave_7037, $a0
	db L8, E5, F5, REST, G5, REST, F5, REST, E5, G4, D4, REST, B3, G3, REST, REST
	db REST, PAT_END
Pattern_7485:
	db L8, NOISE1, NOISE1, REST, NOISE1, REST, NOISE1, REST, NOISE1, L1, NOISE1, PAT_END
Pattern_7491:
	db L8, E4, REST, REST, L4D, G4, L4, E4, L2, REST, C4, L4T, D4, A4, A4, A4
	db B4, C5, L1, REST, L8, E4, E4, REST, L4D, G4, L4, E4, L1, REST, L4T, B4
	db REST, REST, D4, E4, F4, L1, E4, PAT_END
Pattern_74B9:
	db L8, C5, REST, REST, L4D, E5, L4, C5, L8, A4, D5, REST, F5, L2, A4, L4T
	db B4, F5, F5, F5, G5, A5, L8, G5, E5, REST, C5, L2, G4, L8, C5, C5
	db REST, L4D, E5, L4, C5, L8, A4, D5, REST, F5, L2, A4, L4T, B4, REST, REST
	db B4, C5, D5, L1, C5, PAT_END
Pattern_74EF:
	db L4D, C4, E4, L4, G4, L4D, F4, A4, L4, C5, L4D, G4, B4, L4, D4, L4D
	db C4, E4, L4, G4, L4D, C4, E4, L4, G4, L4D, F4, A4, L4, C5, L4D, G4
	db B4, L4, D4, L4D, C4, E4, L4, G4, PAT_END
Pattern_7518:
	db L4T, A4, A4, A4, A4, G4, F4, L4D, G4, C4, L4, REST, L8, D4, REST, REST
	db D4, D4, E4, REST, F4, L1, G4, L4T, A4, REST, A4, A4, B4, C5, L4D, B4
	db G4, L4, REST, L4D, A4, G4, L4, F4, L8, REST, F4, REST, REST, L2, G4, PAT_END
Pattern_7548:
	db L4T, F5, F5, F5, F5, E5, D5, L4D, E5, C5, L4, REST, L8, B4, REST, REST
	db B4, B4, C5, REST, D5, L1, E5, L4T, F5, REST, F5, F5, G5, A5, L4D, G5
	db E5, L4, REST, L4D, F5, E5, L4, D5, L8, REST, A4, REST, REST, L2, B4, PAT_END
Pattern_7578:
	db L4D, F4, A4, L4, C5, L4D, C4, E4, L4, G4, L4D, G4, B4, L4, D4, L4D
	db C4, E4, L4, G4, L4D, F4, A4, L4, C5, L4D, E4, G4, L4, B4, L4D, F4
	db A4, L4, C5, L8, REST, G4, REST, REST, L2, G4, PAT_END
Pattern_75A3:
	db L4, NOISE1, L8T, NOISE1, REST, NOISE1, L4, NOISE2, L8T, NOISE1, REST, NOISE1, L4, NOISE1, L8T, NOISE1
	db REST, NOISE1, L4, NOISE2, L8T, NOISE1, REST, NOISE1, PAT_END
Song06_Ch1:
	dw Pattern_7608
Song06_Ch1_Loop:
	dw Pattern_7628
	dw Pattern_7628
	dw Pattern_76F7
	LIST_LOOP Song06_Ch1_Loop
Song06_Ch2:
	dw Pattern_75F4
Song06_Ch2_Loop:
	dw Pattern_7677
	dw Pattern_7677
	dw Pattern_7735
	LIST_LOOP Song06_Ch2_Loop
Song06_Ch3:
	dw Pattern_761C
Song06_Ch3_Loop:
	dw Pattern_76B5
	dw Pattern_76B5
	dw Pattern_76B5
	dw Pattern_76D6
	dw Pattern_76B5
	dw Pattern_76B5
	dw Pattern_76B5
	dw Pattern_76D6
	dw Pattern_7773
	LIST_LOOP Song06_Ch3_Loop
Song06_Ch4:
	dw Pattern_7624
Song06_Ch4_Loop:
	dw Pattern_77BD
	LIST_LOOP Song06_Ch4_Loop
Pattern_75F4:
	INSTR $84, $00, $00
	db L8, G6, G6, G6, REST, E6, REST, E6, REST, D6, REST, D6, REST, L2, E6, PAT_END
Pattern_7608:
	INSTR $74, $00, $00
	db L8, D6, D6, D6, REST, B5, REST, B5, REST, A5, REST, A5, REST, L2, B5, PAT_END
Pattern_761C:
	INSTR_WAVE Wave_7037, $20
	db L1, REST, REST, PAT_END
Pattern_7624:
	db L1, REST, REST, PAT_END
Pattern_7628:
	INSTR $82, $00, $00
	db L2D, A4, L4, B4, L2, D5, B4, L2, A4, L4, B4, A4, L2, G4, L4, E4
	db D4, L2D, A4, L4, B4, L2, D5, L4, B4, A4, L8, G5, A5, L4, G5, L8
	db E5, G5, L4, E5, L8, D5, E5, L4, D5, L8, B4, A4, L4, G4, L2D, A4
	db L4, B4, L2, D5, B4, L2, A4, L4, B4, A4, L2, G4, L4, E4, D4, L2D
	db E4, L4, Fs4, E4, D4, B3, A3, L1, B3, REST, PAT_END
Pattern_7677:
	INSTR $70, $00, $81
	db L2D, D5, L4, E5, L2, G5, E5, L2, D5, L4, E5, D5, L2, B4, L4, A4
	db G4, L2D, D5, L4, E5, L2, G5, L4, E5, D5, L1, E5, REST, L2D, D5, L4
	db E5, L2, G5, E5, L2, D5, L4, E5, D5, L2, B4, L4, A4, G4, L2D, A4
	db L4, B4, A4, G4, E4, D4, L1, E4, REST, PAT_END
Pattern_76B5:
	db L4, G3, L8, G4, D4, L4, G3, G4, L4, G3, L8, G4, D4, L4, G3, G4
	db L4, C3, L8, C4, G3, L4, C3, C4, L4, C3, L8, C4, G3, L4, C3, C4
	db PAT_END
Pattern_76D6:
	db L4, D3, L8, D4, A3, L4, D3, D4, L4, D3, L8, D4, A3, L4, D3, D4
	db L4, E3, L8, E4, B3, L4, E3, E4, L4, E3, L8, E4, B3, L4, E3, E4
	db PAT_END
Pattern_76F7:
	db L2D, A5, L4, B5, L2, D6, L4, D6, L8, E6, D6, L2, B5, L4, D6, B5
	db L4, A5, L8, B5, A5, L4, G5, L8, E5, D5, L1, D6, L2D, D6, L4, B5
	db L1, D6, REST, L2D, E5, L4, G5, L2, A5, G5, L2D, E5, L4, D5, L2, B4
	db L4, A4, G4, L2D, A4, L4, B4, L2, D5, E5, L1, G5, REST, PAT_END
Pattern_7735:
	db L2D, A4, L4, B4, L2, D5, L4, D5, L8, E5, D5, L2, B4, L4, D5, B4
	db L4, A4, L8, B4, A4, L4, G4, L8, E4, D4, L1, D5, L2D, D5, L4, B4
	db L1, D5, REST, L2D, E5, L4, G5, L2, A5, G5, L2D, E5, L4, D5, L2, B4
	db L4, A4, G4, L2D, A4, L4, B4, L2, D5, E5, L1, G5, REST, PAT_END
Pattern_7773:
	db L4, D3, L8, D4, A3, L4, D3, D4, L4, D3, L8, D4, A3, L4, D3, D4
	db L4, C3, L8, C4, G3, L4, C3, C4, L4, C3, L8, C4, G3, L4, C3, C4
	db L4, B3, L8, B4, Fs3, L4, B3, B4, L4, B3, L8, B4, Fs3, L4, B3, B4
	db L4, D3, L8, D4, A3, L4, D3, D4, L4, D3, L8, D4, A3, L4, D3, D4
	db L1, E3, E3, C3, C3, D3, D3, E3, E3, PAT_END
Pattern_77BD:
	db L4, NOISE1, L8, NOISE1, NOISE1, L4, NOISE2, L8, NOISE1, NOISE1, L4, NOISE1, L8, NOISE1, NOISE1, L4
	db NOISE2, L8, NOISE1, NOISE1, PAT_END
Song07_Ch1:
	dw Pattern_780D
Song07_Ch1_Loop:
	dw Pattern_7843
	dw Pattern_794B
	LIST_LOOP Song07_Ch1_Loop
Song07_Ch2:
	dw Pattern_77FA
Song07_Ch2_Loop:
	dw Pattern_7887
	dw Pattern_7917
	LIST_LOOP Song07_Ch2_Loop
Song07_Ch3:
	dw Pattern_781A
Song07_Ch3_Loop:
	dw Pattern_78F3
	dw Pattern_78F3
	dw Pattern_7978
	LIST_LOOP Song07_Ch3_Loop
Song07_Ch4:
	dw Pattern_782B
Song07_Ch4_Loop:
	dw Pattern_79A8
	LIST_LOOP Song07_Ch4_Loop
Pattern_77FA:
	INSTR $92, $00, $80
	db L8, E5, REST, Ds5, REST, D5, C5, REST, REST, REST, L4D, G4, L2, G3, PAT_END
Pattern_780D:
	INSTR $62, $00, $80
	db L1, REST, L8, REST, L4D, G3, L2, G2, PAT_END
Pattern_781A:
	INSTR_WAVE Wave_7037, $20
	db L8, G6, REST, Fs6, REST, F6, E6, REST, REST, L2, REST, G4, PAT_END
Pattern_782B:
	db L8D, NOISE1, L16, NOISE1, L4, NOISE2, L8D, NOISE1, L16, NOISE1, L4, NOISE2, L8, REST, NOISE1, REST
	db REST, L8D, NOISE2, L16, NOISE1, L4, NOISE1, PAT_END
Pattern_7843:
	db L4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST
	db E4, REST, C5, REST, C5, REST, C5, REST, C5, L1, REST, L4, REST, Fs6, L2, Fs6
	db L4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST
	db E4, REST, C5, REST, C5, REST, C5, REST, C5, L1, REST, L8D, REST, L16, Fs6, L4
	db REST, L2, Fs5, PAT_END
Pattern_7887:
	db L4, E5, REST, L8D, D5, L16, C5, L8D, REST, L16, E5, L2D, REST, L8D, C5, L16
	db D5, L8, E5, REST, E5, REST, L4, D5, C5, E5, F5, G5, A5, REST, C5, C5
	db A4, G4, L8D, REST, L16, C5, L2, REST, L4, F4, G4, A4, B4, L4, REST, G6
	db L2, G6, L4, E5, REST, L8D, D5, L16, C5, L8D, REST, L16, E5, L2D, REST, L8D
	db C5, L16, D5, L8, E5, REST, E5, REST, L4, D5, C5, A5, G5, C6, L8D, E5
	db L16, D5, L4, REST, C5, C5, D5, E5, L8D, REST, L16, C5, L2, REST, L4, F5
	db E5, C5, D5, L8D, REST, L16, G6, L4, REST, L2, G5, PAT_END
Pattern_78F3:
	db L4, C4, L8D, G5, L16, G3, L4, C4, G5, C4, Gs5, C4, Gs5, C4, A5, C4
	db A5, C4, As5, A4, As5, F4, A5, F4, A5, E4, G5, E4, G5, D5, E5, F5
	db Fs5, L1, REST, PAT_END
Pattern_7917:
	db L4, REST, A5, B5, C6, L4, B5, L8D, REST, L16, G5, L2, REST, L4, F5, REST
	db L8D, G5, L16, F5, L4, REST, L8, E5, REST, F5, REST, Fs5, REST, G5, REST, L4
	db REST, A5, B5, C6, L4, B5, L8D, REST, L16, G5, L2, REST, L4, Ds6, D6, REST
	db C6, L1, REST, PAT_END
Pattern_794B:
	db L4, REST, C5, D5, A4, D5, L8D, G4, L16, B4, L4, REST, G4, A4, F4, L8D
	db B4, L16, A4, L4, D4, L1, REST, L4, REST, C5, D5, A4, D5, L8D, G4, L16
	db B4, L4, REST, G4, C4, C4, REST, C4, REST, REST, REST, REST, PAT_END
Pattern_7978:
	db L4, F4, C5, F4, C5, E4, C5, E4, C5, D4, A5, D4, A5, L8, C5, REST
	db D5, REST, Ds5, REST, E5, REST, L4, F4, C5, F4, C5, E4, C5, E4, C5, Gs4
	db Ds5, Gs4, Ds5, L16, G5, REST, G5, REST, L8, F5, REST, E5, REST, D5, REST, PAT_END
Pattern_79A8:
	db L4, NOISE1, L8D, NOISE1, L16, NOISE1, L4, NOISE2, L8D, NOISE1, L16, NOISE1, L4, NOISE1, L8D, NOISE1
	db L16, NOISE1, L4, NOISE2, L8D, NOISE1, L16, NOISE1, PAT_END
Song09_Header:
	SONG $00, LengthTable_706E, Song09_Ch1, Song09_Ch2, 0, Song09_Ch4
Song10_Header:
	SONG $00, LengthTable_7077, Song10_Ch1, Song10_Ch2, Song10_Ch3, 0
Song11_Header:
	SONG $00, LengthTable_7062, Song11_Ch1, Song11_Ch2, Song11_Ch3, Song11_Ch4
Song12_Header:
	SONG $00, LengthTable_7062, Song12_Ch1, Song12_Ch2, Song12_Ch3, Song12_Ch4
Song13_Header:
	SONG $00, LengthTable_7057, Song13_Ch1, 0, Song13_Ch3, 0
Song14_Header:
	SONG $00, LengthTable_7062, Song14_Ch1, Song14_Ch2, 0, 0
Song15_Header:
	SONG $00, LengthTable_7082, Song15_Ch1, Song15_Ch2, 0, 0
Song16_Header:
	SONG $00, LengthTable_7082, Song16_Ch1, Song16_Ch2, Song16_Ch3, 0
Song18_Header:
	SONG $00, LengthTable_7077, Song18_Ch1, Song18_Ch2, 0, 0
Song19_Header:
	SONG $00, LengthTable_7077, Song19_Ch1, Song19_Ch2, Song19_Ch3, Song19_Ch4
Song19_Ch1:
	dw Pattern_7A4D
Song19_Ch1_Loop:
	dw Pattern_7A92
	LIST_LOOP Song19_Ch1_Loop
Song19_Ch2:
	dw Pattern_7A5E
Song19_Ch2_Loop:
	dw Pattern_7AA7
	LIST_LOOP Song19_Ch2_Loop
Song19_Ch3:
	dw Pattern_7A6F
Song19_Ch3_Loop:
	dw Pattern_7AB5
	LIST_LOOP Song19_Ch3_Loop
Song19_Ch4:
	dw Pattern_7A80
	LIST_LOOP Song19_Ch4
Pattern_7A4D:
	INSTR $90, $00, $00
	db L1, REST, D3, Ds3, L2, E3, F3, L4, Fs3, G3, Gs3, A3, PAT_END
Pattern_7A5E:
	INSTR $a0, $00, $00
	db L1, REST, G2, Gs2, L2, A2, As2, L4, B2, C3, Cs3, D3, PAT_END
Pattern_7A6F:
	INSTR_WAVE Wave_7037, $20
	db L1, REST, G3, Gs3, L2, A3, As3, L4, B3, C4, Cs4, D4, PAT_END
Pattern_7A80:
	db L16, NOISE1, NOISE1, NOISE1, NOISE1, NOISE2, NOISE1, NOISE1, NOISE1, NOISE1, NOISE1, NOISE1, NOISE1, NOISE2, NOISE1, NOISE1
	db NOISE1, PAT_END
Pattern_7A92:
	INSTR $60, $00, $c1
	db L2, D3, Gs3, G3, Cs4, L1, C4, REST, L2, D3, Gs3, G3, Cs4, L1, D4, REST
	db PAT_END
Pattern_7AA7:
	INSTR $83, $00, $00
	db L8, G2, Fs2, F2, E2, Ds2, D2, Cs2, C2, PAT_END
Pattern_7AB5:
	db L16, G3, G4, Fs3, Fs4, F3, F4, E3, E4, Ds3, Ds4, D3, D4, Cs3, Cs4, C3
	db C4, PAT_END
Song18_Ch1:
	dw Pattern_7AD3
	LIST_LOOP Song18_Ch1
Song18_Ch2:
	dw Pattern_7AE9
	LIST_LOOP Song18_Ch2
Pattern_7AD3:
	INSTR $84, $00, $80
	db L8, G4, Gs4, G4, Gs4, G4, Gs4, G4, Gs4, G4, As4, Cs5, E5, G5, E5, Cs5
	db As4, PAT_END
Pattern_7AE9:
	INSTR $74, $00, $80
	db L8, G2, Gs2, G2, Gs2, G2, Gs2, G2, Gs2, E3, G3, As3, Cs4, E4, Cs4, As3
	db G3, PAT_END
Song16_Ch1:
	dw Pattern_7B07
	LIST_END
Song16_Ch2:
	dw Pattern_7B21
Song16_Ch3:
	dw Pattern_7B34
Pattern_7B07:
	INSTR $60, $00, $81
	db L4, F4, C5, F5, C5, G4, C5, F4, E4, Gs3
	INSTR $30, $00, $81
	db L16, E4, F4, E4, D4, L2, E4, PAT_END
Pattern_7B21:
	INSTR $80, $00, $81
	db L4, A4, C5, A5, L2, G5, L4, E5, L2, C5, L4, D5, L1, C5, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7B34:
	INSTR_WAVE Wave_7037, $21
	db L2D, F5, E5, L2, Gs4, L4, F4, L1, C4
Song15_Ch1:
	dw Pattern_7B53
	dw Pattern_7B71
	dw Pattern_7B53
	dw Pattern_7B7A
	LIST_END
Song15_Ch2:
	dw Pattern_7B82
	dw Pattern_7BA1
	dw Pattern_7B82
	dw Pattern_7BAA
Pattern_7B53:
	INSTR $66, $00, $81
	db L4, G5, B5, D6, B5, Fs5, B5, D6, B5, F5, B5, D6, B5, E5, G5, C6
	db G5, Ds5, G5, C6, G5, D5, G5, B5, G5, PAT_END
Pattern_7B71:
	db Cs5, E5, G5, A5, G5, C5, Fs5, D5, PAT_END
Pattern_7B7A:
	db E5, G5, A5, Fs5, L2, B5, G4, PAT_END
Pattern_7B82:
	INSTR $66, $00, $81
	db L2, B6, L4, A6, G6, L2D, B6, L8, G6, A6, L4, B6, B6, A6, G6, B6
	db C7, D7, E7, REST, G6, G6, Ds6, L2, D6, B6, PAT_END
Pattern_7BA1:
	db L4, E6, G6, A6, B6, L2, A6, D6, PAT_END
Pattern_7BAA:
	db L4, C7, E6, Fs6, D6, L1, G6, PAT_END
Song13_Ch1:
	dw Pattern_7BB8
	LIST_END
Song13_Ch3:
	dw Pattern_7BCA
Pattern_7BB8:
	INSTR $50, $00, $80
	db L16, G4, REST, G4, REST, G4, REST, L4, Gs4, L8, As4, L2, C5, PAT_END
Pattern_7BCA:
	INSTR_WAVE Wave_7017, $a0
	db L8, B6, B6, B6, L4, C7, L8, D7, L16, E7, G6, E7, G6, E7, G6, E7
	db G6, E7, G6, E7, G6, E7, G6, E7, G6, PAT_END
Song14_Ch1:
	dw Pattern_7BEE
	LIST_END
Song14_Ch2:
	dw Pattern_7C03
Pattern_7BEE:
	INSTR $73, $00, $80
	db L4, D3, L16, REST, L4, D3, L16, REST, L4, D3, L16, REST, L4, D3, L16, REST
	db PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7C03:
	INSTR $d3, $00, $c0
	db L4, Cs3, L16, REST, L4, Cs3, L16, REST, L4, Cs3, L16, REST, L4, Cs3, L16, REST
Song12_Ch1:
	dw Pattern_7C4B
	dw Pattern_7C52
	dw Pattern_7C6C
	dw Pattern_7C52
	dw Pattern_7C6F
	dw Pattern_7C4B
	dw Pattern_7C52
	dw Pattern_7C6C
	dw Pattern_7C52
	dw Pattern_7C6F
	LIST_END
Song12_Ch2:
	dw Pattern_7C76
	dw Pattern_7C7D
	dw Pattern_7C95
	dw Pattern_7C7D
	dw Pattern_7C9E
	dw Pattern_7C76
	dw Pattern_7C7D
	dw Pattern_7C95
	dw Pattern_7C7D
	dw Pattern_7C9E
Song12_Ch3:
	dw Pattern_7CA5
	dw Pattern_7CA5
Song12_Ch4:
	dw Pattern_7CEB
	LIST_LOOP Song12_Ch4
Pattern_7C4B:
	INSTR $93, $00, $80
	db L4, REST, PAT_END
Pattern_7C52:
	db L8, REST, C5, REST, C5, REST, C5, REST, C5, REST, C5, REST, C5, REST, C5, REST
	db C5, REST, G4, REST, G4, REST, G4, REST, G4, PAT_END
Pattern_7C6C:
	db L1, REST, PAT_END
Pattern_7C6F:
	db REST, C5, REST, C5, C5, REST, PAT_END
Pattern_7C76:
	INSTR $c3, $00, $c0
	db L4, Ds4, PAT_END
Pattern_7C7D:
	db L2, Gs4, L8, As4, Cs5, C5, As4, L4, Ds5, Ds5, L8, Ds5, F5, C5, Cs5, L4
	db As4, As4, L8, As4, Cs5, C5, As4, PAT_END
Pattern_7C95:
	db Gs4, Gs5, G5, F5, Ds5, Cs5, C5, As4, PAT_END
Pattern_7C9E:
	db Gs4, Ds5, As4, C5, Gs4, REST, PAT_END
Pattern_7CA5:
	INSTR_WAVE Wave_7017, $20
	db L4, REST, L8, Gs4, Ds5, Ds4, Ds5, Gs4, Ds5, Ds4, Ds5, Gs4, Ds5, Ds4, Ds5, Gs4
	db Ds5, Ds4, Ds5, Ds4, As5, As4, As5, Ds4, As5, As4, As5, Gs4, Gs5, G5, F5, Ds5
	db Cs5, C5, As4, Gs4, Ds5, Ds4, Ds5, Gs4, Ds5, Ds4, Ds5, Gs4, Ds5, Ds4, Ds5, Gs4
	db Ds5, Ds4, Ds5, Ds4, As5, As4, As5, Ds4, As5, As4, As5, Gs4, Ds5, Ds4, Ds5, Gs4
	db REST, PAT_END
Pattern_7CEB:
	db L4, REST, L8, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE2, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1
	db L16, NOISE2, NOISE2, L8, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE2, NOISE2, NOISE2, NOISE1
	db NOISE2, NOISE1, NOISE2, REST, PAT_END
Song11_Ch1:
	dw Pattern_7D34
	LIST_LOOP Song11_Ch1
Song11_Ch2:
	dw Pattern_7D28
	LIST_LOOP Song11_Ch2
Song11_Ch3:
	dw Pattern_7D40
	LIST_LOOP Song11_Ch3
Song11_Ch4:
	dw Pattern_7D55
	LIST_LOOP Song11_Ch4
Pattern_7D28:
	INSTR $54, $00, $80
	db L8, Ds5, D5, Cs5, C5, B4, As4, PAT_END
Pattern_7D34:
	INSTR $34, $00, $80
	db L8, E4, Ds4, D4, Cs4, C4, B3, PAT_END
Pattern_7D40:
	INSTR_WAVE Wave_7017, $20
	db L2D, A4, L4D, A4, C5, L2D, Ds5, Ds5, L2D, A4, L4D, A4, C5, L2D, Ds5, Ds5
	db PAT_END
Pattern_7D55:
	db L8, NOISE1, NOISE1, NOISE1, L4D, NOISE2, L8, NOISE1, NOISE1, NOISE1, L4D, NOISE2, PAT_END
Song10_Ch1:
	dw Pattern_7D7D
	LIST_END
Song10_Ch2:
	dw Pattern_7D6A
Song10_Ch3:
	dw Pattern_7D92
Pattern_7D6A:
	INSTR $d1, $00, $80
	db L4D, C4, D4, E4, F4, G4, A4, B4, C5, D5, E5, F5, G5, A5, PAT_END
Pattern_7D7D:
	INSTR $41, $00, $80
	db L4T, REST, L4D, C4, D4, E4, F4, G4, A4, B4, C5, D5, E5, F5, G5, A5
	db PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7D92:
	INSTR_WAVE Wave_7037, $20
	db L8, C5, REST, E5, D5, REST, F5, E5, REST, G5, F5, REST, A5, G5, REST, B5
	db A5, REST, C6, B5, REST, D6, C6, REST, E6, D6, REST, F6, E6, REST, G6, F6
	db REST, A6, G6, REST, B6, A6, REST, C7, B6, REST, D7
Song09_Ch1:
	dw Pattern_7DD3
	LIST_LOOP Song09_Ch1
Song09_Ch2:
	dw Pattern_7DF9
	LIST_LOOP Song09_Ch2
Song09_Ch4:
	dw Pattern_7E3F
	LIST_LOOP Song09_Ch4
Pattern_7DD3:
	INSTR $91, $00, $80
	db L8, G4, D5, G4, D5, G4, D5, G4, D5, A4, E5, A4, D5, A4, E5, A4
	db D5, C5, G5, C5, G5, C5, G5, C5, G5, D5, D5, C5, C5, B4, B4, A4
	db A4, PAT_END
Pattern_7DF9:
	INSTR $91, $00, $80
	db L16, B5, D6, G6, B5, D6, G6, B5, D6, G6, B5, D6, G6, B5, D6, G6
	db REST, A5, Cs6, G6, A5, Cs6, G6, A5, Cs6, G6, A5, Cs6, G6, A5, Cs6, G6
	db REST, C6, E6, G6, C6, E6, G6, C6, E6, G6, C6, E6, G6, C6, E6, G6
	db REST, Fs6, A5, Fs6, A5, E6, G6, E6, G5, D6, Fs5, D6, Fs5, C6, E6, C6
	db E5, PAT_END
Pattern_7E3F:
	db L8, NOISE1, L16, NOISE1, NOISE1, L8, NOISE1, L16, NOISE1, NOISE1, L8, NOISE1, L16, NOISE1, NOISE1, PAT_END
Song17_Header:
	SONG $00, LengthTable_7077, Song17_Ch1, Song17_Ch2, Song17_Ch3, Song17_Ch4
Song17_Ch1:
	dw Pattern_7E9E
	dw Pattern_7EAA
Song17_Ch1_Loop:
	dw Pattern_7ECC
	dw Pattern_7ECC
	dw Pattern_7EF9
	LIST_LOOP Song17_Ch1_Loop
Song17_Ch2:
	dw Pattern_7EA5
	dw Pattern_7EAA
Song17_Ch2_Loop:
	dw Pattern_7ECC
	dw Pattern_7ECC
	dw Pattern_7EF9
	LIST_LOOP Song17_Ch2_Loop
Song17_Ch3:
	dw Pattern_7F24
	dw Pattern_7F29
	dw Pattern_7F29
	dw Pattern_7F3B
	dw Pattern_7F3B
Song17_Ch3_Loop:
	dw Pattern_7F4C
	dw Pattern_7F4C
	dw Pattern_7F6E
	dw Pattern_7F88
	dw Pattern_7F6E
	dw Pattern_7F91
	LIST_LOOP Song17_Ch3_Loop
Song17_Ch4:
	dw Pattern_7FB2
	dw Pattern_7FB2
	dw Pattern_7FB2
	dw Pattern_7FB2
Song17_Ch4_Loop:
	dw Pattern_7FDB
	LIST_LOOP Song17_Ch4_Loop
Pattern_7E9E:
	INSTR $30, $00, $81
	db L4T, REST, PAT_END
Pattern_7EA5:
	INSTR $90, $00, $81
	db PAT_END
Pattern_7EAA:
	db L4, Cs5, E4, A4, Cs5, Ds5, Fs4, B4, Ds5, E5, G4, C5, E5, Fs5, A4, D5
	db Fs5, Gs5, B4, E5, Gs5, A5, C5, E5, A5, Gs5, B4, E5, Gs5, A5, C5, E5
	db A5, PAT_END
Pattern_7ECC:
	db L8, Gs5, REST, REST, E5, REST, REST, B4, REST, REST, Fs5, REST, A5, REST, Gs5, Fs5
	db L1, E5, REST, L8, REST, L8, Gs5, REST, REST, E5, REST, REST, B4, REST, L2, E5
	db L8, REST, Ds5, E5, L2, Fs5, L8, REST, L2, Cs5, Ds5, REST, PAT_END
Pattern_7EF9:
	db L2D, E5, L8, Ds5, E5, L2, Fs5, B4, L2D, Gs5, L8, Fs5, Gs5, L4, A5, Cs5
	db E5, Ds5, L2D, E5, L8, Ds5, E5, L2, Fs5, B4, L2D, Gs5, L8, Fs5, Gs5, L4
	db B5, C5, E5, G5, L2, A5, C6, L1, Gs5, Fs5, PAT_END
Pattern_7F24:
	INSTR_WAVE Wave_7037, $a0
	db PAT_END
Pattern_7F29:
	db L8, A4, A4, A5, A5, A4, A4, A5, A5, A4, A4, A5, A5, A4, A4, A5
	db A5, PAT_END
Pattern_7F3B:
	db E4, E4, E5, E5, E4, E4, E5, E5, E4, E4, E5, E5, E4, E4, E5, E5
	db PAT_END
Pattern_7F4C:
	db L4, E5, E5, E5, E5, Ds5, Ds5, Ds5, Ds5, D5, D5, D5, D5, Cs5, Cs5, Cs5
	db Cs5, A4, A4, A4, A4, Gs4, Gs4, Gs4, Gs4, Fs4, Fs4, Fs4, Fs4, B4, B4, B4
	db B4, PAT_END
Pattern_7F6E:
	db L8, A3, A3, A4, A4, A3, A3, A4, A4, A3, A3, A4, A4, A3, A3, A4
	db A4, Gs3, Gs3, Gs4, Gs4, Gs3, Gs3, Gs4, Gs4, PAT_END
Pattern_7F88:
	db Fs3, Fs3, Fs4, Fs4, B3, B3, B4, B4, PAT_END
Pattern_7F91:
	db G3, G3, G4, G4, G3, G3, G4, G4, G3, G3, G4, G4, G3, G3, G4, G4
	db B3, B3, E4, Gs4, B3, B3, E4, Gs4, B3, B3, Ds4, Fs4, B3, B3, Ds4, Fs4
	db PAT_END
Pattern_7FB2:
	db L16, NOISE1, NOISE1, L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE2, L16
	db NOISE1, NOISE1, L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE2, L16, NOISE1
	db NOISE1, L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE2, PAT_END
Pattern_7FDB:
	db L8, NOISE1, NOISE1, NOISE3, NOISE1, NOISE1, NOISE1, NOISE3, NOISE1, NOISE1, NOISE1, NOISE3, NOISE1, NOISE1, NOISE1, NOISE3
	db NOISE1, PAT_END
