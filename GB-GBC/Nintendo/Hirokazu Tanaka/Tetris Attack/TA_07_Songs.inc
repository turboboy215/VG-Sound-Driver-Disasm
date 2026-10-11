; Tetris Attack SFX and music, bank $07: songs $1D-$23, $7031-$7FFF

; songs $01-$1C point here: never started in this bank
DummySongHeader:
	SONG $00, LengthTable_6FF5, Song23_Ch1, Song23_Ch2, Song23_Ch3, Song23_Ch4
Song23_Ch2:
	dw Pattern_7054
	LIST_LOOP Song23_Ch2
Song23_Ch1:
	dw Pattern_7113
	LIST_LOOP Song23_Ch1
Song23_Ch3:
	dw Pattern_71A8
	LIST_LOOP Song23_Ch3
Song23_Ch4:
	dw Pattern_72F4
	LIST_LOOP Song23_Ch4
Pattern_7054:
	INSTR $90, $00, $81
	db L1, F4, L2D, F4, L8, REST, L16, Ds4, E4, L1, F4, L2D, F4, L4, REST, L1
	db F4, L2D, F4, L8, REST, L16, Ds4, E4, L1, F4, L2D, F4, L8, REST, L16, Fs4
	db F4, L1, Fs4, L2, Gs4, L4D, As4, L16, As4, B4, L1, As4, L2D, F4, L8, REST
	db L16, As4, A4, L1, As4, L2, B4, L4D, Cs5, L16, As4, B4, L1, As4, L2D, Ds4
	db L8, REST, L16, Ds5, D5, L1, Ds5, L2, F5, L4D, Fs5, L16, Fs5, F5, L1, Fs5
	db L2D, Fs4, L4, REST, L2, Ds5, L4, Cs5, B4, L2, As4, Gs4, L4D, As4, L16, A4
	db As4, L4D, B4, L16, As4, B4, L4D, Cs5, L16, C5, Cs5, L4D, D5, L16, Fs4, F4
	db L1, Fs4, L2, Gs4, L4D, As4, L16, As4, B4, L1, As4, L2D, F4, L8, REST, L16
	db As4, A4, L1, As4, L2, B4, L4D, Cs5, L16, As4, B4, L1, As4, L2D, Ds4, L8
	db REST, L16, Ds5, D5, L1, Ds5, L2, F5, L4D, Fs5, L16, Fs5, F5, L1, Fs5, L4
	db REST, Fs5, F5, E5, L2, Ds5, L4, Cs5, B4, L2, As4, Gs4, L1, Cs5, L2D, Cs5
	db L4, REST, L2, Ds5, L4, Cs5, B4, L2, As4, Gs4, PAT_END
Pattern_7113:
	INSTR $c1, $00, $80
	REPEAT $02
	db L8, Fs3, Cs4, Gs3, Cs4, Fs3, Cs4, Gs3, Cs4, Fs3, Cs4, Gs3, Cs4, Fs3, Cs4, Gs3
	db Cs4, G3, D4, As3, D4, G3, D4, As3, D4, G3, D4, As3, D4, G3, D4, As3
	db D4
	REPEAT_END
	INSTR $90, $00, $81
	db L1, As3, L2, F4, Fs4, L1, F4, L2D, As3, L4, REST, L1, E4, E4, Ds4, L2D
	db Gs3, L4, REST, L1, Gs4, L2, Gs4, D5, L1, Cs5, L2D, C4, L4, REST, L2, B4
	db L4, Ds4, Fs4, L1, D4, L8, D4, G4, D4, As3, Cs4, Fs4, Cs4, A3, Ds4, As4
	db Ds4, B3, Fs4, B4, Fs4, B3, L1, As3, L2, F4, Fs4, L1, F4, L2D, As3, L4
	db REST, L1, E4, E4, Ds4, L2D, Gs3, L4, REST, L1, Gs4, L2, Gs4, D5, L1, Cs5
	db C5, L2, B4, L4, B3, Ds4, L1, D4, L4, E4, Cs4, L2D, Gs4, L4, G4, Gs4
	db As4, L2, B4, L4, Ds4, Fs4, L1, D4, PAT_END
Pattern_71A8:
	INSTR_WAVE Wave_7F21, $20
	db L8, Ds3, L16, Ds4, REST, REST, REST, Ds4, REST
	REPEAT $13
	db L8, Ds3, L16, Ds4, REST, REST, REST, Ds4, REST
	REPEAT_END
	REPEAT $04
	db L8, D3, L16, D4, REST, REST, REST, D4, REST
	REPEAT_END
	REPEAT $04
	db L8, Cs3, L16, Cs4, REST, REST, REST, Cs4, REST
	REPEAT_END
	REPEAT $04
	db L8, C3, L16, C4, REST, REST, REST, C4, REST
	REPEAT_END
	REPEAT $04
	db L8, B2, L16, B3, REST, REST, REST, B3, REST
	REPEAT_END
	REPEAT $02
	db L8, As2, L16, As3, REST, REST, REST, As3, REST
	REPEAT_END
	REPEAT $02
	db L8, A2, L16, A3, REST, REST, REST, A3, REST
	REPEAT_END
	REPEAT $02
	db L8, Gs2, L16, Gs3, REST, REST, REST, Gs3, REST
	REPEAT_END
	db L8, B2, L16, B3, REST, REST, REST, B3, REST, L8, E3, L16, E4, REST, REST, REST
	db E4, REST, L8, Gs4, L16, Gs4, REST, REST, REST, Gs4, REST, L8, G4, L16, G4, REST
	db REST, REST, G4, REST, L8, Fs4, L16, Fs4, REST, REST, REST, Fs4, REST, L8, Gs4, L16
	db Gs4, REST, REST, REST, Gs4, REST
	REPEAT $04
	db L8, Ds3, L16, Ds4, REST, REST, REST, Ds4, REST
	REPEAT_END
	REPEAT $04
	db L8, D3, L16, D4, REST, REST, REST, D4, REST
	REPEAT_END
	REPEAT $04
	db L8, Cs3, L16, Cs4, REST, REST, REST, Cs4, REST
	REPEAT_END
	REPEAT $04
	db L8, C3, L16, C4, REST, REST, REST, C4, REST
	REPEAT_END
	REPEAT $04
	db L8, B2, L16, B3, REST, REST, REST, B3, REST
	REPEAT_END
	REPEAT $02
	db L8, As2, L16, As3, REST, REST, REST, As3, REST
	REPEAT_END
	REPEAT $02
	db L8, A2, L16, A3, REST, REST, REST, A3, REST
	REPEAT_END
	REPEAT $02
	db L8, Gs2, L16, Gs3, REST, REST, REST, Gs3, REST
	REPEAT_END
	db L8, B2, L16, B3, REST, REST, REST, B3, REST, L8, E3, L16, E4, REST, REST, REST
	db E4, REST
	REPEAT $02
	db L8, As2, L16, As3, REST, REST, REST, As3, REST
	REPEAT_END
	REPEAT $02
	db L8, Ds3, L16, Ds4, REST, REST, REST, Ds4, REST
	REPEAT_END
	REPEAT $02
	db L8, Gs2, L16, Gs3, REST, REST, REST, Gs3, REST
	REPEAT_END
	db L8, B2, L16, B3, REST, REST, REST, B3, REST, L8, E3, L16, E4, REST, REST, REST
	db E4, REST, PAT_END
Pattern_72F4:
	db L8, NOISE_2E, REST, NOISE_33, REST, PAT_END
Song1D_Header:
	SONG $00, LengthTable_6FF5, Song1D_Ch1, Song1D_Ch2, Song1D_Ch3, 0
Song1D_Ch2:
	dw Pattern_7317
	LIST_LOOP Song1D_Ch2
Song1D_Ch1:
	dw Pattern_733A
	LIST_LOOP Song1D_Ch1
Song1D_Ch3:
	dw Pattern_7324
	LIST_LOOP Song1D_Ch3
Pattern_7317:
	INSTR $1f, $00, $81
	db L1, E4, F4, G4, C5, LEN12, A4, G4, PAT_END
Pattern_7324:
	INSTR_WAVE Wave_7F21, $61
	db L16, C3, REST, C3, REST, G3, REST, C4, REST, REST, REST, C4, REST, G3, REST, G4
	db REST, PAT_END
Pattern_733A:
	INSTR $40, $00, $81
	db L1, G3, A3, B3, As3, LEN12, F4, B3, PAT_END
Song1E_Header:
	SONG $00, LengthTable_6FF5, Song1E_Ch1, Song1E_Ch2, 0, 0
Song1E_Ch2:
	dw Pattern_735E
	LIST_LOOP Song1E_Ch2
Song1E_Ch1:
	dw Pattern_7368
	LIST_LOOP Song1E_Ch1
Pattern_735E:
	INSTR $1d, $00, $81
	db L1, As4, Cs5, As4, G4, PAT_END
Pattern_7368:
	INSTR $1d, $00, $81
	db L1, E4, G4, E4, Cs4, PAT_END
Song1F_Header:
	SONG $00, LengthTable_6FF5, Song1F_Ch1, Song1F_Ch2, Song1F_Ch3, Song1F_Ch4
Song1F_Ch2:
	dw Pattern_73C5
	dw Pattern_74BB
	dw Pattern_752E
	dw Pattern_74BB
	dw Pattern_75A3
	dw Pattern_7613
Song1F_Ch2_Loop:
	dw Pattern_743C
	LIST_LOOP Song1F_Ch2_Loop
Song1F_Ch1:
	dw Pattern_76E7
	dw Pattern_7792
	dw Pattern_7820
	dw Pattern_7792
	dw Pattern_7820
	dw Pattern_78A6
Song1F_Ch1_Loop:
	dw Pattern_773F
	LIST_LOOP Song1F_Ch1_Loop
Song1F_Ch3:
	dw Pattern_7A28
	dw Pattern_7A56
	dw Pattern_7A88
	dw Pattern_7A56
	dw Pattern_7A88
	dw Pattern_7AED
Song1F_Ch3_Loop:
	dw Pattern_7A3F
	LIST_LOOP Song1F_Ch3_Loop
Song1F_Ch4:
	dw Pattern_7BD4
	dw Pattern_7BE7
	dw Pattern_7BFA
	dw Pattern_7BE7
	dw Pattern_7BFA
	dw Pattern_7C0D
Song1F_Ch4_Loop:
	dw Pattern_7BD4
	LIST_LOOP Song1F_Ch4_Loop
Pattern_73C5:
	INSTR $71, $83, $80
	db L8, C6, D6, B6, C6, D6, G6, C6, D6, B6, C6, D6, G6, C7, B6, G6
	db D6
	REPEAT $02
	db B5, D6, A6, B5, D6, Fs6
	REPEAT_END
	db G6, Fs6, D6, B5
	REPEAT $02
	db C6, D6, B6, C6, D6, G6
	REPEAT_END
	db C7, B6, G6, D6, B5, D6, A6, B5, D6, Fs6, B5, D6, G6, Fs6, D6, B5
	db G5, Fs5, D5, B4
	INSTR $81, $83, $80
	REPEAT $02
	db C5, D5, B5, C5, D5, G5
	REPEAT_END
	db C6, B5, G5, D5
	REPEAT $02
	db B4, D5, A5, B4, D5, Fs5
	REPEAT_END
	db G5, Fs5, D5, B4
	REPEAT $02
	db C5, D5, B5, C5, D5, G5
	REPEAT_END
	db C6, B5, G5, D5, B4, D5, A5, B4, D5, Fs5, G5, A5, L4, D6, L2D, REST
	db PAT_END
Pattern_743C:
	INSTR $71, $83, $80
	db L8, C6, D6, B6, C6, D6, G6, C6, D6, B6, C6, D6, G6, C7, B6, G6
	db D6
	REPEAT $02
	db B5, D6, A6, B5, D6, Fs6
	REPEAT_END
	db G6, Fs6, D6, B5
	REPEAT $02
	db C6, D6, B6, C6, D6, G6
	REPEAT_END
	db C7, B6, G6, D6, B5, D6, A6, B5, D6, Fs6, B5, D6, G6, Fs6, D6, B5
	db G5, Fs5, D5, B4
	INSTR $81, $83, $80
	db L8, C5, D5, B5, C5, D5, G5, C5, D5, B5, C5, D5, G5, C6, B5, G5
	db D5
	REPEAT $02
	db B4, D5, A5, B4, D5, Fs5
	REPEAT_END
	db G5, Fs5, D5, B4
	REPEAT $02
	db C5, D5, B5, C5, D5, G5
	REPEAT_END
	db C6, B5, G5, D5, B4, D5, A5, B4, D5, Fs5, B4, D5, Fs5, G5, A5, D6
	db Fs6, G6, A6, D7, PAT_END
Pattern_74BB:
	INSTR $92, $00, $80
	db L8, C4, D4, B4, C4, D4, G4, C4, D4, B4, C4, D4, G4, C5, B4, G4
	db D4
	REPEAT $02
	db B3, Fs4, D5, B3, Fs4, G4
	REPEAT_END
	db D5, B4, G4, D4
	REPEAT $02
	db A3, C4, B4, A3, C4, G4
	REPEAT_END
	db C5, B4, G4, D4, E3, B3, Fs4, G4, D5, A4, B4, Fs5, G5, Fs5, D5, A4
	db G4, Fs4, D4, A3
	REPEAT $02
	db C4, D4, B4, C4, D4, G4
	REPEAT_END
	db C5, B4, G4, D4
	REPEAT $02
	db B3, Fs4, D5, B3, Fs4, G4
	REPEAT_END
	db D5, B4, G4, D4
	REPEAT $02
	db A3, C4, B4, A3, C4, G4
	REPEAT_END
	db C5, B4, G4, D4, G3, D4, A4, B4, D5, A4, B4, Fs5, L4, G5, L2D, REST
	db PAT_END
Pattern_752E:
	INSTR $70, $00, $81
	db L2, B4, L8, B4, A4, G4, Fs4, L2, G4, L4, REST, E4, L2, B4, L8, B4
	db A4, G4, Fs4, L2, G4, L4, REST, E4, L2, B4, L8, B4, A4, G4, Fs4, L2
	db G4, L4, REST, G4, L1, As4, L8, G4, E4, Fs4, G4, Fs4, REST, REST, REST
	INSTR $70, $00, $81
	db L8, G5, E5, Fs5, G5, L4, Gs5, A5, L8, Fs5, D5, E5, Fs5, L4, E5, REST
	db L8, G5, E5, Fs5, G5, L4, A5, L8, B5, C6, L2D, D6, L4, REST, L8, G5
	db E5, Fs5, G5, L2, Fs5, L8, Fs5, D5, E5, Fs5, L4, E5, REST, L1, As4, L8
	db G4, E4, G4, B4, A4
	INSTR $84, $00, $81
	db L8, G5, G5, Fs5, PAT_END
Pattern_75A3:
	INSTR $70, $00, $81
	db L2, B4, L8, B4, A4, G4, Fs4, L2, G4, L4, REST, E4, L2, B4, L8, B4
	db A4, G4, Fs4, L2, G4, L4, REST, E4, L2, B4, L8, B4, A4, G4, Fs4, L2
	db G4, L4, REST, G4, L1, As4, L8, G4, E4, Fs4, G4, Fs4, REST, REST, REST
	INSTR $70, $00, $81
	db L8, G5, E5, Fs5, G5, L4, Gs5, A5, L8, Fs5, D5, E5, Fs5, L4, E5, REST
	db L8, G5, E5, Fs5, G5, L4, A5, L8, B5, C6, L2D, D6, L4, REST, L8, G5
	db E5, Fs5, G5, L2, Fs5, L8, Fs5, D5, E5, Fs5, L4, E5, REST, L1, As4, L8
	db G4, E4, G4, B4, A4, REST, REST, REST, PAT_END
Pattern_7613:
	INSTR $a0, $00, $81
	db L2, B4, L4, A4, B4, L2, A4, Fs4, L2, G4, L4, Fs4, G4, L2, Fs4, L4D
	db B3, L8, REST, L2, E4, L4, D4, E4, L2, D4, D4, L2, E4, E4, E4, D4
	db L2, B4, L4, A4, B4, L2, A4, Fs4, L2, G4, L4, Fs4, G4, L2, Fs4, L4D
	db B3, L8, REST, L4, E4, D4, C4, D4, E4, D4, C4, A3, L1, Ds4, L2, C4
	db L4, A3, REST
	INSTR $b0, $00, $81
	db L2, B4, L4, A4, B4, L2, A4, Fs4, L2, G4, L4, Fs4, G4, L2, Fs4, L4D
	db B3, L8, REST, L2, E4, L4, D4, E4, L2, D4, D4, L2, E4, E4, Ds4, Ds4
	INSTR $c0, $00, $81
	db L2, G6, L4, Fs6, E6, L2, Fs6, G6, L2, A6, L4, G6, Fs6, L2, G6, L4D
	db B6, L8, REST, L2, B6, L4, G6, A6, L2, B6, L4, G6, A6, L1, B6, L2D
	db B6, L4, REST
	INSTR $f0, $00, $81
	db L2, As6, L4, A6, As6, L2, A6, F6, L2, G6, L4, F6, G6, L2, F6, As5
	db L2, Ds6, L4, D6, Ds6, L2, D6, As5, L4, C6, As5, A5, As5, L2D, A5, L4
	db REST, L2, G6, L4, Fs6, G6, L2, Fs6, D6, L2, E6, L4, D6, E6, L2, D6
	db L4D, G5, L8, REST, L4, C6, B5, A5, B5, C6, B5, A5, Fs5, PAT_END
Pattern_76E7:
	INSTR $62, $00, $80
	db L8, A4, A4, REST, A4, A4, REST, A4, A4, REST, A4, A4, REST, A4, A4, REST
	db A4
	REPEAT $05
	db E4, E4, REST
	REPEAT_END
	db E4
	REPEAT $05
	db A4, A4, REST
	REPEAT_END
	db A4
	REPEAT $05
	db G4, G4, REST
	REPEAT_END
	db G4
	INSTR $62, $00, $80
	REPEAT $05
	db A3, A3, REST
	REPEAT_END
	db A3
	REPEAT $05
	db E3, E3, REST
	REPEAT_END
	db E3
	REPEAT $05
	db A3, A3, REST
	REPEAT_END
	db A3
	REPEAT $02
	db G3, G3, REST
	REPEAT_END
	db B3, D4, L4, Fs4
	INSTR $64, $00, $80
	db REST, L8, REST, G5, G5, Fs5, PAT_END
Pattern_773F:
	INSTR $62, $00, $80
	db L8, A4, A4, REST, A4, A4, REST, A4, A4, REST, A4, A4, REST, A4, A4, REST
	db A4
	REPEAT $05
	db E4, E4, REST
	REPEAT_END
	db E4
	REPEAT $05
	db A4, A4, REST
	REPEAT_END
	db A4
	REPEAT $05
	db E4, E4, REST
	REPEAT_END
	db E4, A3, A3, REST
	REPEAT $04
	db A3, A3, REST
	REPEAT_END
	db A3
	REPEAT $05
	db E3, E3, REST
	REPEAT_END
	db E3
	REPEAT $05
	db A3, A3, REST
	REPEAT_END
	db A3
	REPEAT $02
	db E3, E3, REST
	REPEAT_END
	db E3, E3, A4, B4, D5, Fs5, A5, B5, D6, Fs6, PAT_END
Pattern_7792:
	INSTR $80, $00, $81
	db L4D, G5, L8, A5, REST, REST, L2D, G5
	INSTR $94, $00, $81
	db L8, REST, G5, G5, Fs5
	INSTR $80, $00, $81
	db L4D, G5, L8, D6, REST, REST, L2D, G5
	INSTR $94, $00, $81
	db L8, REST, G5, G5, Fs5
	INSTR $80, $00, $81
	db L4D, G5, L8, A5, REST, REST, L1, G5, L8, REST, L16, G5, A5, L4D, B5, L8
	db C6, REST, REST, L2D, D6
	INSTR $94, $00, $81
	db L8, REST, G5, G5, Fs5
	INSTR $80, $00, $81
	db L4D, G5, L8, A5, REST, REST, L2D, G5
	INSTR $94, $00, $81
	db L8, REST, G5, G5, Fs5
	INSTR $80, $00, $81
	db L4D, G5, L8, D6, REST, REST, L2D, G5
	INSTR $94, $00, $81
	db L8, REST, G5, G5, Fs5
	INSTR $80, $00, $81
	db L4D, G5, L8, A5, REST, REST, L2D, B5, L8, C6, B5, A5, Fs5, L1, G5, L2D
	db REST, L4, REST, PAT_END
Pattern_7820:
	INSTR $a3, $00, $80
	db L8, A3, C4, E4, G4, D3, C4, E4, Fs4, G3, B3, D4, Fs4, E3, B3, E4
	db G4, C3, G3, E4, G4, C3, A4, Ds4, Fs4, G3, B3, D4, Fs4, E3, B3, E4
	db G4, A3, C4, E4, G4, D3, C4, E4, Fs4, G3, B3, D4, Fs4, G3, Fs4, D4
	db B3, C3, G3, D4, Ds4, G4, Ds4, C4, G3, A2, G3, C4, E4, D3, A3, C4
	db E4, A2, C4, E4, G4, D3, C4, E4, Fs4, G2, B3, D4, Fs4, E2, B3, E4
	db G4, C3, G3, E4, G4, C3, A3, Ds4, Fs4, G2, B3, D4, Fs4, E2, B3, E4
	db G4, A2, C4, E4, G4, D3, C4, E4, Fs4, G2, B3, D4, Fs4, G3, Fs4, D4
	db B3, C3, G3, D4, Ds4, G4, Ds4, C4, G3, A2, G3, C4, E4, D3, A3, C4
	db Fs4, PAT_END
Pattern_78A6:
	INSTR $a3, $00, $80
	db L8, G2, D3, A3, B3, D4, B3, G3, D3, B2, Fs3, A3, D4, Fs4, D4, A3
	db Fs3, C3, G3, C4, E4, G4, E4, C4, G3, B2, A3, D4, Fs4, E3, G3, D4
	db Fs4, A2, E3, G3, C4, G4, C4, G3, E3, B2, G3, A3, D4, Fs4, D4, A3
	db G3, Cs3, G3, B3, E4, E3, G3, B3, Cs4, D3, G3, C4, E4, Fs4, D4, C4
	db A3, G2, D3, A3, B3, D4, B3, G3, D3, B2, Fs3, A3, D4, Fs4, D4, A3
	db Fs3, C3, G3, C4, E4, G4, E4, C4, G3, B2, A3, D4, Fs4, E3, G3, D4
	db Fs4, A2, E3, G3, C4, G4, C4, G3, E3, D3, G3, C4, E4, Fs4, D4, C4
	db A3, F2, C3, G3, As3, Ds4, As3, G3, Ds3, D2, A2, E3, G3, C4, A3, Fs3
	db D3, G2, D3, A3, B3, D4, B3, G3, D3, B2, Fs3, A3, D4, Fs4, D4, A3
	db Fs3, C3, G3, C4, E4, G4, E4, C4, G3, B2, A3, D4, Fs4, E3, G3, D4
	db Fs4, A2, E3, G3, C4, G4, C4, G3, E3, B2, G3, A3, D4, Fs4, D4, A3
	db G3, Cs3, G3, B3, E4, E3, G3, B3, Cs4, C3, G3, A3, Ds4, B2, Fs3, A3
	db Ds4
	INSTR $b3, $00, $80
	db E3, G3, B3, E4, G4, E4, B3, G3, E3, A3, C4, E4, A4, E4, C4, A3
	db Ds3, A3, C4, Fs4, A4, Fs4, Ds4, C4, D3, G3, B3, D4, G4, D4, B3, G3
	db Cs3, G3, B3, E4, G4, E4, B3, G3, E3, A3, Cs4, G4, B4, G4, Cs4, A3
	db B2, Fs3, A3, Cs4, E4, Cs4, A3, Fs3, B2, Fs3, A3, B3, Fs4, G4, A4, B4
	INSTR $c3, $00, $80
	db G2, D3, A3, As3, F4, As3, A3, D3, F2, D3, A3, D4, F4, D4, A3, D3
	db Ds2, As2, G3, As3, Ds4, As3, G3, As2, D2, D3, F3, As3, D4, As3, F3, D3
	db C2, C3, G3, C4, Ds4, C4, G3, Ds3, D2, D3, F3, As3, D4, As3, F3, D3
	db G2, G3, C4, E4, As4, E4, C4, G3, D2, A3, C4, E4, A4, Fs4, C4, D4
	INSTR $b3, $00, $80
	db G2, D3, A3, B3, D4, B3, G3, D3, B2, Fs3, A3, D4, Fs4, D4, A3, Fs3
	db C3, G3, C4, E4, G4, E4, C4, G3, B2, A3, D4, Fs4, E3, G3, D4, Fs4
	db A2, E3, G3, C4, G4, C4, G3, E3, D3, G3, C4, E4, Fs4, D4, C4, A3
	db PAT_END
Pattern_7A28:
	INSTR_WAVE Wave_7F51, $21
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, L1, REST, REST, REST, REST, REST, REST
	db REST, REST, PAT_END
Pattern_7A3F:
	INSTR_WAVE Wave_7F51, $61
	db L2D, REST, L1, REST, REST, REST, REST, REST, REST, L1, REST, REST, REST, REST, REST, REST
	db REST, REST, PAT_END
Pattern_7A56:
	INSTR_WAVE Wave_7F51, $41
	db L1, E6, E6, D6, D6, C6, C6, L4D, D6, L8, E6, REST, REST, L2D, Fs6, L2
	db REST, L1, E6, E6, D6, D6, L4D, C6, L8, C6, REST, REST, L2D, D6, L8, E6
	db D6, C6, A5, L1, B5, L2D, REST
	INSTR_WAVE Wave_7F41, $41
	db L4, G5, PAT_END
Pattern_7A88:
	INSTR_WAVE Wave_7F41, $41
	db L2, D6, L8, D6, C6, B5, A5, L2, B5, L4, REST, G5, L2, D6, L8, D6
	db C6, B5, A5, L2, B5, L4, REST, G5, L2, D6, L8, D6, C6, B5, A5, L2
	db B5, L4, REST, G5, L2, F6, L8, F6, Ds6, D6, C6, L2, D6, L4, REST, L4
	db G5, L2, D6, L8, D6, C6, B5, A5, L2, B5, L4, REST, G5, L2, D6, L8
	db D6, C6, B5, A5, L2, B5, L4, REST, G5, L2, D6, L8, D6, C6, B5, A5
	db L2, B5, L4, REST, G5, L2, F6, L8, F6, Ds6, D6, C6, L2D, D6, L4, REST
	db PAT_END
Pattern_7AED:
	INSTR_WAVE Wave_7F41, $21
	db L2, G6, L4, Fs6, G6, L2, Fs6, D6, L2, E6, L4, D6, E6, L2, D6, L4D
	db G5, L8, REST, L2, C6, L4, B5, C6, L2, B5, G5, L4, A5, G5, Fs5, G5
	db L2D, A5, L4, REST, L2, G6, L4, Fs6, G6, L2, Fs6, D6, L2, E6, L4, D6
	db E6, L2, D6, L4D, G5, L8, REST, L4, C6, B5, A5, B5, C6, B5, A5, Fs5
	db L1, G5, L2D, G5, L4, REST, L2, G6, L4, Fs6, G6, L2, Fs6, D6, L2, E6
	db L4, D6, E6, L2, D6, L4D, G5, L8, REST, L2, C6, L4, B5, C6, L2, B5
	db G5, L4, B5, A5, Gs5, A5, L2, G6, L4D, Fs6, L8, REST
	INSTR_WAVE Wave_7F41, $41
	db L2, B5, L4, A5, G5, L2, A5, L4, A5, B5, L2, C6, L4, B5, A5, L2
	db B5, L4D, D6, L8, REST, L4, REST, B5, L2, E6, L8, E6, REST, L4, Cs6, L2
	db E6, L8, E6, REST, L4, A5, Cs6, E6, L2D, Ds6, L4, REST, L2, D7, L4, C7
	db D7, L2, C7, A6, L2, As6, L4, A6, As6, L2, A6, D6, L2, G6, L4, F6
	db G6, L2, F6, F6, L1, E6
	INSTR_WAVE Wave_7F51, $21
	db L4, G6, Fs6, E6, Fs6
	INSTR_WAVE Wave_7F41, $41
	db L2, B6, L4, A6, B6, L2, A6, Fs6, L2, G6, L4, Fs6, G6, L2, Fs6, L4
	db B5, REST, L4, E6, D6, C6, D6, E6, D6, C6, A5, L1, G6, L4, REST, PAT_END
Pattern_7BD4:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, L1, REST, REST, REST, REST, REST, REST
	db REST, REST, PAT_END
Pattern_7BE7:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, L1, REST, REST, REST, REST, REST, REST
	db REST, REST, PAT_END
Pattern_7BFA:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, L1, REST, REST, REST, REST, REST, REST
	db REST, REST, PAT_END
Pattern_7C0D:
	REPEAT $17
	db L8, NOISE_2E, NOISE_29, NOISE_29, NOISE_29, NOISE_33, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_0B, NOISE_29, NOISE_33, NOISE_29, NOISE_29
	db NOISE_2E
	REPEAT_END
	db PAT_END
Song20_Header:
	SONG $00, LengthTable_6FF5, Song20_Ch1, Song20_Ch2, Song20_Ch3, Song20_Ch4
Song20_Ch2:
	dw Pattern_7C4D
Song20_Ch2_Loop:
	dw Pattern_7C62
	LIST_LOOP Song20_Ch2_Loop
Song20_Ch1:
	dw Pattern_7CE5
Song20_Ch1_Loop:
	dw Pattern_7D0E
	LIST_LOOP Song20_Ch1_Loop
Song20_Ch3:
	dw Pattern_7DB2
Song20_Ch3_Loop:
	dw Pattern_7DCA
	LIST_LOOP Song20_Ch3_Loop
Song20_Ch4:
	dw Pattern_7E4D
Song20_Ch4_Loop:
	dw Pattern_7E76
	LIST_LOOP Song20_Ch4_Loop
Pattern_7C4D:
	INSTR $60, $00, $81
	db L1, Fs5, F5, B4, LEN12, As4
	INSTR $a1, $00, $80
	REPEAT $10
	db L16, As3, Ds4
	REPEAT_END
	db PAT_END
Pattern_7C62:
	INSTR $73, $00, $80
	REPEAT $0e
	db L16, As3, Ds4
	REPEAT_END
	REPEAT $02
	db As3, F4
	REPEAT_END
	REPEAT $10
	db As3, Fs4
	REPEAT_END
	REPEAT $20
	db As3, F4
	REPEAT_END
	REPEAT $08
	db Gs3, E4
	REPEAT_END
	REPEAT $08
	db A3, E4
	REPEAT_END
	REPEAT $08
	db As3, E4
	REPEAT_END
	REPEAT $08
	db B3, E4
	REPEAT_END
	REPEAT $04
	db Gs3, Ds4
	REPEAT_END
	REPEAT $0c
	db Gs3, C4
	REPEAT_END
	REPEAT $10
	db C4, Ds4
	REPEAT_END
	REPEAT $08
	db D4, Fs4
	REPEAT_END
	REPEAT $08
	db Cs4, F4
	REPEAT_END
	REPEAT $08
	db D4, Fs4
	REPEAT_END
	REPEAT $08
	db Cs4, F4
	REPEAT_END
	REPEAT $06
	db Cs4, As4
	REPEAT_END
	REPEAT $02
	db Cs4, Gs4
	REPEAT_END
	REPEAT $18
	db Cs4, Fs4
	REPEAT_END
	REPEAT $08
	db Ds4, Gs4
	REPEAT_END
	REPEAT $08
	db C4, Gs4
	REPEAT_END
	REPEAT $08
	db Ds4, C5
	REPEAT_END
	REPEAT $04
	db C4, Gs4
	REPEAT_END
	REPEAT $04
	db Ds4, Gs4
	REPEAT_END
	REPEAT $10
	db B3, Gs4
	REPEAT_END
	REPEAT $10
	db As3, Gs4
	REPEAT_END
	db PAT_END
Pattern_7CE5:
	INSTR $e1, $00, $40
	db L16, Ds3, REST, REST, Ds3, REST, REST, Ds3, REST, REST, REST, Ds3, REST, Ds3, REST, REST
	db REST
	REPEAT $06
	db Ds3, REST, REST, Ds3, REST, REST, Ds3, REST, REST, REST, Ds3, REST, Ds3, REST, REST, REST
	REPEAT_END
	db PAT_END
Pattern_7D0E:
	INSTR $e1, $00, $40
	db Ds3, REST, REST, Ds3, REST, REST, Ds3, REST, REST, REST, Ds3, REST, Ds3, REST, REST, REST
	REPEAT $03
	db Ds3, REST, REST, Ds3, REST, REST, Ds3, REST, REST, REST, Ds3, REST, Ds3, REST, REST, REST
	REPEAT_END
	REPEAT $04
	db D3, REST, REST, D3, REST, REST, D3, REST, REST, REST, D3, REST, D3, REST, REST, REST
	REPEAT_END
	REPEAT $04
	db Cs3, REST, REST, Cs3, REST, REST, Cs3, REST, REST, REST, Cs3, REST, Cs3, REST, REST, REST
	REPEAT_END
	REPEAT $08
	db Gs3, REST, REST, Gs3, REST, REST, Gs3, REST, REST, REST, Gs3, REST, Gs3, REST, REST, REST
	REPEAT_END
	REPEAT $09
	db Fs3, REST, REST, Fs3, REST, REST, Fs3, REST, REST, REST, Fs3, REST, Fs3, REST, REST, REST
	REPEAT_END
	db F3, REST, REST, F3, REST, REST, F3, REST, REST, REST, F3, REST, Ds3, REST, REST, REST
	db D3, REST, REST, D3, REST, REST, D3, REST, REST, REST, D3, REST, D3, REST, REST, REST
	db D3, REST, REST, D3, REST, REST, D3, REST, REST, REST, D3, REST, D3, REST, REST, REST
	db PAT_END
Pattern_7DB2:
	INSTR_WAVE Wave_7F51, $21
	db L1, As6, Gs6, F6, LEN12, Fs6, L1, REST, L2D, REST
	INSTR_WAVE Wave_7F41, $41
	db L8, REST, L16, Fs5, F5, PAT_END
Pattern_7DCA:
	INSTR_WAVE Wave_7F41, $41
	db L1, Fs5, L2D, Fs5, L4, Gs5, L1, As5, L2D, As5, L8, REST, L16, As5, B5, L1
	db As5, L2D, As5, L4, B5, L1, As5, L2D, As5, L4, B5, L1, Cs6, Ds6, Gs6, L2D
	db Cs6, L8, REST, L16, Ds6, Cs6, L2, C6, Ds6, L16, C7, Gs6, Ds6, C6, Gs6, Ds6
	db C6, Gs5, Ds6, C6, Gs5, Ds5, C6, Gs5, Ds5, C5, L1, Gs5, L2D, Gs5, L4, As5
	db L1, B5, L2D, B5, L8, REST, L16, Gs5, As5
	REPEAT $04
	db L8, B5, L16, Gs5, As5
	REPEAT_END
	db L2, B5, L4, Cs6, B5, L2D, Cs6, L4, B5, L2D, As5, L8, REST, L16, A5, As5
	db L2, B5, As5, L4, B5, As5, Gs5, As5, L1, C6, Ds6, Gs6, L2, Ds6, C6, L1
	db D6, L2, D6, Fs6, L1, F6, L2D, As5, L8, REST, L16, Fs5, F5, PAT_END
Pattern_7E4D:
	db L1, REST, REST, REST, REST, REST, L16, NOISE_33, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_33, NOISE_29, NOISE_29
	db NOISE_29, NOISE_2E, NOISE_29, NOISE_33, NOISE_29, NOISE_29, NOISE_29, L16, NOISE_33, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_33, NOISE_29
	db NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_33, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_7E76:
	db L16, NOISE_33, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_1A, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_33, NOISE_29, NOISE_29
	db NOISE_29, PAT_END
Song21_Header:
	SONG $00, LengthTable_6FE0, Song21_Ch1, Song21_Ch2, Song21_Ch3, Song21_Ch4
Song21_Ch1:
	dw Pattern_7EAD
Song21_Ch1_Loop:
	dw Pattern_7ECE
	LIST_LOOP Song21_Ch1_Loop
Song21_Ch2:
	dw Pattern_7ED1
	LIST_LOOP Song21_Ch2
Song21_Ch3:
	dw Pattern_7ED4
	LIST_LOOP Song21_Ch3
Song21_Ch4:
	dw Pattern_7ED7
	LIST_LOOP Song21_Ch4
Pattern_7EAD:
	INSTR $40, $00, $40
	REPEAT $03
	db L32, Gs5
	INSTR $a0, $00, $40
	db L16, A5, REST, L4, REST, L2, REST
	INSTR $40, $00, $40
	REPEAT_END
	db L32, Gs6
	INSTR $e5, $00, $40
	db L2, A6, PAT_END
Pattern_7ECE:
	db L32, REST, PAT_END
Pattern_7ED1:
	db L32, REST, PAT_END
Pattern_7ED4:
	db L32, REST, PAT_END
Pattern_7ED7:
	db L32, REST, PAT_END
Song22_Header:
	SONG $00, LengthTable_701F, Song22_Ch1, Song22_Ch2, Song22_Ch3, Song22_Ch4
Song22_Ch1:
	dw Pattern_7EFD
	LIST_LOOP Song22_Ch1
Song22_Ch2:
	dw Pattern_7F07
	LIST_LOOP Song22_Ch2
Song22_Ch3:
	dw Pattern_7F11
	LIST_LOOP Song22_Ch3
Song22_Ch4:
	dw Pattern_7F1B
	LIST_LOOP Song22_Ch4
Pattern_7EFD:
	INSTR $08, $00, $00
	db L1, REST, REST, REST, REST, PAT_END
Pattern_7F07:
	INSTR $08, $00, $00
	db L1, REST, REST, REST, REST, PAT_END
Pattern_7F11:
	INSTR_WAVE Wave_7F61, $00
	db L1, REST, REST, REST, REST, PAT_END
Pattern_7F1B:
	db L1, REST, REST, REST, REST, PAT_END
Wave_7F21:
	db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $aa, $bb, $cc, $dd, $ee, $ff
; unreferenced: the same 16 bytes as bank $08's Wave_7C80
Unused_7F31:
	db $9a, $bc, $de, $00, $00, $00, $00, $00, $00, $00, $00, $00, $12, $34, $56, $78
Wave_7F41:
	db $00, $00, $00, $00, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
Wave_7F51:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10
Wave_7F61:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	ds 143, $ff
