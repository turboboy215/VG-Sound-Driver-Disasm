; Super Mario Land 2 songs, bank 4 $5CB3-$7F5D

; songs 7, 10, 41, 42
Song07_Header:
	SONG $04, LengthTable_5C8E, LengthTable_5C8E, Song07_Ch1, Song07_Ch2, 0, 0
Song07_Ch1:
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5CEC
	dw Pattern_5D86
	LIST_LOOP Song07_Ch1
Song07_Ch2:
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D48
	dw Pattern_5D8E
	LIST_LOOP Song07_Ch2
Pattern_5CEC:
	INSTR $31, $81, $00
	REPEAT $02
	db L16, C6, E6, G6, E6
	REPEAT_END
	db E6, G6, C7, G6, Ds6, A6, C7, A6
	REPEAT $08
	db D6, G6, B6, G6
	REPEAT_END
	REPEAT $04
	db C6, E6, G6, E6
	REPEAT_END
	REPEAT $02
	db F6, A6, D7, A6
	REPEAT_END
	REPEAT $02
	db Fs6, A6, C7, A6
	REPEAT_END
	REPEAT $02
	db G6, C7, E7, C7
	REPEAT_END
	REPEAT $02
	db A6, Cs7, E7, Cs7
	REPEAT_END
	REPEAT $02
	db Fs6, A6, D7, A6
	REPEAT_END
	REPEAT $02
	db F6, B6, D7, B6
	REPEAT_END
	db E6, G6, C7, G6, D6, G6, B6, G6
	REPEAT $02
	db C6, G6, C7, G6
	REPEAT_END
	db PAT_END
Pattern_5D48:
	INSTR $46, $00, $80
	db L4, C7, E7, G7, Fs7, F7, L8, D7, L2D, B6, L8, G6, Fs6, G6, D7, L4
	db D7, L8, F7, E7, C7, A6, L2, G6, L8, REST, A6, Gs6, A6, L4, C7, L8
	db C7, L4, D7, L8, E7, Ds7, E7, L4, A7, L8, A7, L4, E7, L8, D7, Cs7
	db D7, L4, G7, L8, G7, L4, B6, L1, C7, PAT_END
Pattern_5D86:
	REPEAT $04
	db L1, REST
	REPEAT_END
	db L4D, REST, PAT_END
Pattern_5D8E:
	INSTR $61, $00, $80
	db LEN12, As3, LEN13, As3, C4, LEN12, D4, L4T, C4, L4, As3, F4, D4, As4, L2, F4
	db LEN12, F4, LEN13, F4, Fs4, LEN12, F4, L4T, E4, L2, Cs4, L4, C4, L4D, F4, L2D
	db As3, PAT_END
Song13_Header:
	SONG $00, LengthTable_5C34, LengthTable_5C34, Song08_Ch3, Song13_Ch2, 0, Song13_Ch4
Song13_Ch2:
	dw Pattern_5DD3
	dw Pattern_5DF9
	dw Pattern_5DD3
	dw Pattern_5E24
	LIST_LOOP Song13_Ch2
Song13_Ch4:
	dw Pattern_5E6F
	LIST_LOOP Song13_Ch4
Pattern_5DD3:
	INSTR $42, $00, $80
	db L4D, G5, B5, D6, Cs6, C6, L4, A5, L1, Fs5, L8, REST, D5, L4, Cs5, L8
	db D5, L4, A5, L4D, A5, L8, C6, L4, B5, L8, G5, L4, E5, L2D, D5, L8
	db REST, PAT_END
Pattern_5DF9:
	db L4, E4, L8, Ds4, L4, E4, L4D, G4, L8, G4, L4D, A4, L4, B4, L8, As4
	db L4, B4, L2, E5, L4, Ds5, L8, E5, L4D, Fs5, L4, Cs5, L2, D5, L4, Cs5
	db L8, D5, L4D, E5, L4, B4, L4D, C5, L2, A4, PAT_END
Pattern_5E24:
	db L4, E4, L8, Ds4, L4, E4, L4D, G4, L8, G4, L4D, A4, L4, B4, L8, As4
	db L4, B4, L4D, E5, L8, E5, L4D, B4, L4, A4, L8, Gs4, L4, A4, L4D, D5
	db L8, D5, L4D, Fs4, G4, B3, L2D, G3
	INSTR $81, $00, $80
	REPEAT $03
	db L4, REST, L4D, G2, L8, B2, L4D, A2, D2, G2, L4, B2, L2D, A2, L8, REST
	REPEAT_END
	db L4, REST, L4D, G2, L8, B2, L4D, A2, D2, LEN14, G2, PAT_END
Pattern_5E6F:
	REPEAT $1a
	db L4, NOISE1, L8, NOISE4, L4, NOISE2, L8, NOISE4
	REPEAT_END
	REPEAT $14
	db L4, NOISE1, L8, NOISE4, L4, NOISE2, L8, NOISE4
	REPEAT_END
	db LEN14, NOISE2, PAT_END
Song03_Header:
	SONG $00, LengthTable_5C43, LengthTable_5C43, Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
Song03_Ch1:
	dw Pattern_5EA5
	LIST_END
Song03_Ch2:
	dw Pattern_5EB8
	LIST_END
Song03_Ch3:
	dw Pattern_5ED1
	LIST_END
Song03_Ch4:
	dw Pattern_5EDD
	LIST_END
Pattern_5EA5:
	INSTR $81, $00, $40
	db L4D, A4, L4, REST, L2, Cs5, L4, E5, L8, F5, L2D, Fs5, LEN14, Fs5, PAT_END
Pattern_5EB8:
	INSTR $b1, $00, $80
	db L4, Cs5, L8, C5, L4, Cs5, L8, E5, L4, Ds5, L8, E5, L4, A5, L8, Cs5
	db L2D, D5, LEN14, D6, PAT_END
Pattern_5ED1:
	INSTR_WAVE Wave_5B96, $20
	CH3_FADE_ON
	db LEN14, A2, L2D, REST, LEN14, D3, PAT_END
Pattern_5EDD:
	db LEN14, SFX_DRUM, L2, REST, L8D, REST, L32, NOISE5, NOISE5, LEN14, SFX_DRUM, PAT_END
Song16_Header:
	SONG $04, LengthTable_5C70, LengthTable_5C70, Song16_Ch1, Song16_Ch2, 0, Song16_Ch4
Song16_Ch1:
	dw Pattern_5F08
	LIST_LOOP Song16_Ch1
Song16_Ch2:
	dw Pattern_5F3B
	LIST_LOOP Song16_Ch2
Song16_Ch4:
	dw Pattern_5F6E
	LIST_LOOP Song16_Ch4
Pattern_5F08:
	INSTR $30, $81, $00
	REPEAT $02
	db L8, REST, E4, G4, C5, L8D, E5, L16, Ds5, L8, D5, B4, L8D, G4, L16, B3
	db L8, A3, F4, E4, C4, L4D, G3, L8, E4, G4, C5, L8D, E5, L16, Ds5, L8
	db D5, B4, L8D, G4, L16, B3, L8, A3, F4, L2, E4
	REPEAT_END
	db PAT_END
Pattern_5F3B:
	INSTR $40, $81, $00
	REPEAT $02
	db L8, REST, G4, C5, E5, L8D, G5, L16, Fs5, L8, F5, D5, L8D, B4, L16, G4
	db L8, F4, D5, C5, G4, L4D, E4, L8, G4, C5, E5, L8D, G5, L16, Fs5, L8
	db F5, D5, L8D, B4, L16, G4, L8, F4, D5, L2, C5
	REPEAT_END
	db PAT_END
Pattern_5F6E:
	db L8, NOISE5, L16, NOISE4, NOISE4, PAT_END
Song06_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C61, Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song06_Ch1:
	dw Pattern_5F99
	LIST_LOOP Song06_Ch1
Song06_Ch2:
	dw Pattern_5FBF
	LIST_LOOP Song06_Ch2
Song06_Ch3:
	dw Pattern_5FE5
	LIST_LOOP Song06_Ch3
Song06_Ch4:
	dw Pattern_6012
	LIST_LOOP Song06_Ch4
Pattern_5F99:
	INSTR $52, $00, $80
	REPEAT $02
	db L4, G4, L8, Gs5, L4, F4, G5, Ds4, F5, L8, E4, L4, F4, G5
	REPEAT_END
	REPEAT $02
	db A4, L8, As5, L4, G4, A5, F4, G5, L8, Fs4, L4, G4, A5
	REPEAT_END
	db PAT_END
Pattern_5FBF:
	INSTR $62, $00, $80
	REPEAT $02
	db L4, Ds5, L8, C6, L4, D5, As5, C5, Gs5, L8, Cs5, L4, D5, As5
	REPEAT_END
	REPEAT $02
	db F5, L8, D6, L4, E5, C6, D5, As5, L8, Ds5, L4, E5, C6
	REPEAT_END
	db PAT_END
Pattern_5FE5:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	REPEAT $02
	db L8, F3, E3, F3, L4, As3, As3, L8, As3, F4, E4, F4, L4, As3, As3, L8
	db As3
	REPEAT_END
	REPEAT $02
	db G3, Fs3, G3, L4, C4, C4, L8, C4, G4, Fs4, G4, L4, C4, C4, L8, C4
	REPEAT_END
	db PAT_END
Pattern_6012:
	db L8, NOISE1, L16, NOISE1, NOISE1, L8, NOISE2, NOISE1, NOISE1, NOISE2, NOISE2, NOISE1, PAT_END
Song02_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C61, Song02_Ch1, Song02_Ch2, 0, 0
Song02_Ch1:
	dw Pattern_6034
	LIST_END
Song02_Ch2:
	dw Pattern_6048
	LIST_END
Pattern_6034:
	INSTR $61, $00, $80
	db L8, F4, L16, E4, L8, F4, L8D, D4, L16, D4, L8D, Ds4, E4, E3, C3, PAT_END
Pattern_6048:
	INSTR $71, $00, $80
	db L8, D5, L16, Cs5, L8, D5, L8D, G5, L16, G5, L8D, B4, C5, G3, E3, PAT_END
Song01_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C52, Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
Song01_Ch1:
	dw Pattern_60A7
Song01_Ch1_Loop:
	dw Pattern_60E6
	dw Pattern_6134
	dw Pattern_60E6
	dw Pattern_6155
	dw Pattern_6288
	dw Pattern_63A1
	LIST_LOOP Song01_Ch1_Loop
Song01_Ch2:
	dw Pattern_60AA
Song01_Ch2_Loop:
	dw Pattern_6170
	dw Pattern_6193
	dw Pattern_6170
	dw Pattern_61B8
	dw Pattern_62F6
	dw Pattern_640A
	LIST_LOOP Song01_Ch2_Loop
Song01_Ch3:
	dw Pattern_60BF
Song01_Ch3_Loop:
	dw Pattern_61DB
	dw Pattern_6222
	dw Pattern_61DB
	dw Pattern_6243
	dw Pattern_6343
	dw Pattern_644E
	LIST_LOOP Song01_Ch3_Loop
Song01_Ch4:
	dw Pattern_60D5
Song01_Ch4_Loop:
	dw Pattern_6260
	LIST_LOOP Song01_Ch4_Loop
Pattern_60A7:
	db L1, REST, PAT_END
Pattern_60AA:
	INSTR $a1, $00, $40
	db L16, G4, L8, G4, L16, G4, L8, A4, As4, L4, B4, L16, G4, A4, As4, B4
	db PAT_END
Pattern_60BF:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	db L16, B4, L8, B4, L16, B4, L8, C5, Cs5, L4, D5, L16, B3, C4, Cs4, D4
	db PAT_END
Pattern_60D5:
	db L16, SFX_DRUM, L8, SFX_DRUM, L16, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, L4, SFX_DRUM, L16, NOISE4, NOISE4, NOISE4, NOISE4
	db PAT_END
Pattern_60E6:
	INSTR $61, $00, $00
	REPEAT $04
	db L16, G3, A3, C4
	REPEAT_END
	db Fs3, A3, C4, Fs3
	REPEAT $04
	db F3, G3, B3
	REPEAT_END
	db F3, G3, B3, D3
	REPEAT $04
	db F3, G3, B3
	REPEAT_END
	db F3, G3, B3, A3
	REPEAT $04
	db G3, A3, C4
	REPEAT_END
	db G3, A3, C4, A3, A3, C4, D4, A3, C4, D4, A3, C4, A3, C4, Ds4, A3
	db C4, Ds4, A3, C4, G3, A3, C4, G3, A3, C4, G3, A3, G3, A3, Cs4, G3
	db A3, Cs4, G3, A3, PAT_END
Pattern_6134:
	db A3, C4, E4, A3, C4, E4, A3, C4, A3, B3, Ds4, A3, B3, Ds4, A3, B3
	db C4, F3, A3, C4, F3, A3, C4, Ds4, E4, F4, Cs4, D4, As3, B3, Fs3, G3
	db PAT_END
Pattern_6155:
	db F3, A3, C4, F3, A3, C4, A3, As3, B3, G4, B3, As3, A3, F4, A3, Gs3
	REPEAT $03
	db G3, A3, C4
	REPEAT_END
	db L8D, REST, L4, REST, PAT_END
Pattern_6170:
	INSTR $70, $86, $81
	db L4, C5, E5, G5, Fs5, F5, L8, D5, L2D, B4, L8, G3, Fs3, G3, D4, L4
	db D4, L8, F4, E4, C4, A3, L2, G3, L8, REST
	INSTR $70, $86, $41
	db PAT_END
Pattern_6193:
	db L8, A3, Gs3, A3, L4, C4, L8, C4, L4, D4, L8, E4, Ds4, E4, L4D, A4
	db L8, Gs4, A4, L4, B4, L8, Fs4, L4D, G4, L8, Fs4, G4, L4, A4, L8, E4
	db L4, F4, L4D, D4, PAT_END
Pattern_61B8:
	db L8, A3, Gs3, A3, L4, C4, L8, C4, L4, D4, L8, E4, Ds4, E4, L4, A4
	db L8, A4, L4, E4, L8, D4, Cs4, D4, L4, G4, L8, G4, L4, B3, L4, C4
	db L2, REST, PAT_END
Pattern_61DB:
	db L8D, C4, L8, C4, L16, G3, L8, A3, L8D, E4, L8, E4, L16, Ds4, L8, C4
	REPEAT $04
	db L8D, D4, L8, D4, L16, G3, L8, A3
	REPEAT_END
	REPEAT $02
	db L8D, C4, L8, C4, L16, G3, L8, A3
	REPEAT_END
	db L8D, F4, L8, F4, L16, C4, L8, F4, L8D, Fs4, L8, Fs4, L16, D4, L8, Fs4
	db L8D, G4, L8, G4, L16, E4, L8, G4, L8D, A4, L8, A4, L16, E4, L8, Cs4
	db PAT_END
Pattern_6222:
	db L8D, Fs4, L8, Fs4, L16, Cs4, L8, C4, L8D, B3, L8, B3, L16, B3, L8, Cs4
	db L8D, D4, L8, D4, L16, C4, L8, A3, L8D, G3, L8, G3, L16, A3, L8, B3
	db PAT_END
Pattern_6243:
	db L8D, D3, L8, D3, L16, C4, L8, A3, L8D, G3, L8, G3, L16, A3, L8, B3
	db L8D, C4, L8, C4, L16, G3, L8, A3, L8, C4, L4D, C3, PAT_END
Pattern_6260:
	REPEAT $20
	db L16, NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	REPEAT $1e
	db NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	db NOISE5, NOISE4, L4D, NOISE5
	REPEAT $20
	db L16, NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	REPEAT $1e
	db NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	db L8, REST, NOISE4, NOISE4, NOISE5, PAT_END
Pattern_6288:
	REPEAT $02
	db L16, G3, C4, G5, E4
	REPEAT_END
	REPEAT $02
	db Fs3, C4, Fs5, D4
	REPEAT_END
	REPEAT $02
	db Fs3, B3, Fs5, D4
	REPEAT_END
	REPEAT $02
	db E3, B3, E5, E4
	REPEAT_END
	REPEAT $02
	db A3, D4, A5, Fs4
	REPEAT_END
	REPEAT $02
	db Gs3, D4, Gs5, E4
	REPEAT_END
	REPEAT $02
	db Gs3, Cs4, Gs5, E4
	REPEAT_END
	REPEAT $02
	db Fs3, Cs4, Fs5, E4
	REPEAT_END
	REPEAT $02
	db L16, D4, G4, D5, B4, G4, D5, B4, G4, Cs4, G4, Cs5, A4, G4, Cs5, A4
	db G4
	REPEAT_END
	db Cs4, Fs4, A4, Fs4, Cs4, A4, Fs4, Cs4, F4, Gs4, B4, Gs4, F4, B4, Gs4, F4
	db E4, G4, B4, E4, G4, B4, E4, G4, E4, G4, Cs5, E4, G4, Cs5, E4, G4
	db PAT_END
Pattern_62F6:
	INSTR $60, $86, $40
	db L8, C5, D5, L4, E5, L8, C5, D5, L4, E5, L8, C5, E5, L4, D5, L8
	db B4, REST, REST, REST, B4, Cs5, L4, D5, L8, Fs5, L4, E5, L8, D5, Cs5, D5
	db L2D, E5
	INSTR $80, $00, $81
	db L8, E4, Fs4, L4, G4, L8, E4, Fs4, L4, G4, L8, E4, Fs4, L4, G4, L8
	db B4, L4, A4, L8, G4, Fs4, E4, D4, Fs4, A4, B4, L4, Cs5, B4, L2D, E4
	db L4, REST, PAT_END
Pattern_6343:
	db L8D, A3, L8, A3, L16, A3, L8, E3, L8D, D3, L8, D3, L16, D3, L8, Fs3
	REPEAT $02
	db L8D, G3, L8, G3, L16, G3, L8, D3
	REPEAT_END
	db L8D, B3, L8, B3, L16, B3, L8, Fs3, L8D, E3, L8, E3, L16, E3, L8, B3
	REPEAT $02
	db L8D, A3, L8, A3, L16, A3, L8, E3
	REPEAT_END
	REPEAT $02
	db L8D, E4, E4, L8, E4, L8D, A3, A3, L8, A3
	REPEAT_END
	db L8D, D4, D4, L8, D4, L8D, Cs4, Cs4, L8, Cs4, L8D, E4, L8, E4, L16, G3
	db L8, B3, L8D, A3, L8, A3, L16, Cs4, L8, E4, PAT_END
Pattern_63A1:
	INSTR $61, $00, $00
	REPEAT $04
	db L16, A3, B3, D4
	REPEAT_END
	db Gs3, B3, D4, Gs3
	REPEAT $04
	db G3, A3, Cs4
	REPEAT_END
	db G3, A3, Cs4, E3
	REPEAT $04
	db G3, A3, Cs4
	REPEAT_END
	db G3, A3, Cs4, B3
	REPEAT $04
	db A3, B3, D4
	REPEAT_END
	db A3, B3, D4, B3, B3, D4, E4, B3, D4, E4, B3, D4, B3, D4, F4, B3
	db D4, F4, B3, D4, A3, B3, D4, A3, B3, D4, A3, B3, A3, B3, Ds4, A3
	db B3, Ds4, A3, B3, G3, B3, D4, G3, B3, D4, B3, C4, Cs4, A4, Cs4, C4
	db B3, G4, B3, As3
	REPEAT $03
	db A3, B3, D4
	REPEAT_END
	db REST, L8, F5, L4, Fs5, PAT_END
Pattern_640A:
	INSTR $70, $86, $81
	db L4, D5, Fs5, A5, Gs5, G5, L8, E5, L2D, Cs5, L8, A3, Gs3, A3, E4, L4
	db E4, L8, G4, Fs4, D4, B3, L2, A3, L8, REST
	INSTR $70, $86, $41
	db L8, B3, As3, B3, L4, D4, L8, D4, L4, E4, L8, Fs4, F4, Fs4, L4, B4
	db L8, B4, L4, Fs4, L8, E4, Ds4, E4, L4, A4, L8, A4, L4, Cs4, L2, D4
	db REST, PAT_END
Pattern_644E:
	db L16, D4, REST, REST, D4, REST, A3, B3, REST, Fs4, REST, REST, Fs4, REST, F4, D4
	db REST
	REPEAT $04
	db E4, REST, REST, E4, REST, A3, B3, REST
	REPEAT_END
	REPEAT $02
	db D4, REST, REST, D4, REST, A3, B3, REST
	REPEAT_END
	db G4, REST, REST, G4, REST, D4, G4, REST, Gs4, REST, REST, Gs4, REST, E4, Gs4, REST
	db A4, REST, REST, A4, REST, Fs4, A4, REST, B4, REST, REST, B4, REST, Fs4, Ds4, REST
	db E3, REST, REST, E3, REST, D4, B3, REST, A3, REST, REST, A3, REST, B3, Cs4, REST
	db D4, REST, REST, D4, REST, A3, B3, REST, D4, REST, Cs5, REST, D5, REST, REST, REST
	db PAT_END
Song09_Header:
	SONG $10, LengthTable_5C34, LengthTable_5C34, Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
Song09_Ch1:
	dw Pattern_64D5
	dw Pattern_64E0
	LIST_END
Song09_Ch2:
	dw Pattern_64DC
	LIST_END
Song09_Ch3:
	dw Pattern_64F4
	LIST_END
Song09_Ch4:
	dw Pattern_650C
	LIST_END
Pattern_64D5:
	INSTR $61, $00, $80
	db L8, REST, PAT_END
Pattern_64DC:
	INSTR $e1, $86, $80
Pattern_64E0:
	db L8, Cs4, REST, D4, Ds4, L4D, REST, L8, E4, REST, F4, Fs4, REST, G4, REST, Gs4
	db A4, LEN14, REST, PAT_END
Pattern_64F4:
	INSTR_WAVE Wave_5B96, $23
	CH3_FADE_ON
	db L4, A4, L8, As4, L2, B4, L4, Cs5, L8, D5, L4, Ds5, E5, L8, F5, Fs5
	db LEN14, REST, PAT_END
Pattern_650C:
	db L4, SFX_DRUM, L8, SFX_DRUM, L2, SFX_DRUM, L4, SFX_DRUM, L8, SFX_DRUM, L4, SFX_DRUM, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM
	db LEN14, REST, PAT_END
Song11_Header:
	SONG $00, LengthTable_5C70, LengthTable_5C61, Song11_Ch1, Song11_Ch2, Song11_Ch3, Song11_Ch4
Song11_Ch1:
	dw Pattern_654C
	LIST_LOOP Song11_Ch1
Song11_Ch2:
	dw Pattern_65CA
	LIST_LOOP Song11_Ch2
Song11_Ch3:
	dw Pattern_6613
	dw Pattern_6634
	dw Pattern_6613
	dw Pattern_6656
	dw Pattern_6665
	LIST_LOOP Song11_Ch3
Song11_Ch4:
	dw Pattern_6691
	LIST_LOOP Song11_Ch4
Pattern_654C:
	INSTR $30, $00, $81
	REPEAT $02
	db L2, D4, LEN14, E4, L4, D4, L2D, REST, L1, REST
	REPEAT_END
	INSTR $10, $00, $81
	db L8, REST
	REPEAT $02
	db L4D, A5, L16, Gs5, A5, L4D, As5, L16, A5, Gs5
	REPEAT_END
	db L8D, A5, As5, L8, A5, LEN14, Gs5, L8, G5, E6, REST, L2, REST, L1, REST, REST
	db REST
	INSTR $30, $00, $81
	REPEAT $02
	db L2, D4, LEN14, E4, L4, D4, L2D, REST, L1, REST
	REPEAT_END
	INSTR $f1, $85, $40
	REPEAT $04
	db L4D, D2, D2, L4, D2
	REPEAT_END
	INSTR $30, $00, $01
	db L1, B5, L8D, REST, C6, L8, B5, L8D, A5, B5, L8, Fs5, L1, A5, L8D, REST
	db As5, L8, A5, L8D, G5, A5, L8, E5, L1, G5, L8D, REST, Gs5, L8, G5, L8D
	db F5, E5, L8, Ds5, L1, D5, REST, PAT_END
Pattern_65CA:
	INSTR $e1, $85, $40
	REPEAT $18
	db L4D, D2, D2, L4, D2
	REPEAT_END
	INSTR $61, $00, $80
	DROP_ON
	REPEAT $03
	db L8D, G4, C4, G4, C4, L8, G4, C4
	REPEAT_END
	db L16, A3, L32, F4, L8T, B4, L16, B4, B4, L16, A3, L32, D4, L8T, G4, L16
	db G4, G4, L16, A3, L32, A3, L8T, D4, L16, D4, D4, A3, F3, L8, F3
	DROP_OFF
	INSTR $e1, $85, $40
	REPEAT $08
	db L4D, D2, D2, L4, D2
	REPEAT_END
	db PAT_END
Pattern_6613:
	INSTR_WAVE Wave_5BC6, $41
	db L8D, G4, As4, L8, D5, LEN14, Cs5, L8, C5, As4, L2D, REST, L1, REST, L8D, G4
	db As4, L8, D5, LEN14, Cs5, L8, C5, Gs5, L2D, REST, L1, REST, PAT_END
Pattern_6634:
	INSTR_WAVE Wave_5B96, $61
	REPEAT $02
	db L4D, A5, L16, Gs5, A5, L4D, As5, L16, A5, Gs5
	REPEAT_END
	db L8D, A5, As5, L8, A5, LEN14, Gs5, L8, G5, E6, L2D, REST, L1, REST, REST, REST
	db PAT_END
Pattern_6656:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	REPEAT $04
	db L4D, D4, D4, L4, D4
	REPEAT_END
	CH3_FADE_OFF
	db PAT_END
Pattern_6665:
	INSTR_WAVE Wave_5BC6, $61
	db L1, F7, L8D, REST, Fs7, L8, F7, L8D, Ds7, F7, L8, C7, L1, Ds7, L8D, REST
	db E7, L8, Ds7, L8D, Cs7, Ds7, L8, As6, L1, Cs7, L8D, REST, D7, L8, Cs7, L8D
	db B6, As6, L8, A6, L1, Gs6, REST, PAT_END
Pattern_6691:
	REPEAT $20
	db L8, NOISE2, L16, NOISE4, NOISE4, L8, NOISE4, NOISE1, NOISE4, NOISE4, NOISE1, NOISE4
	REPEAT_END
	db PAT_END
Song36_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C52, Song36_Ch1, Song36_Ch2, Song36_Ch3, Song36_Ch4
Song32_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C52, Song32_Ch1, Song32_Ch2, Song32_Ch3, Song32_Ch4
Song32_Ch1:
	dw Pattern_66DB
Song36_Ch1:
	dw Pattern_673F
	LIST_LOOP Song36_Ch1
Song32_Ch2:
	dw Pattern_66F8
Song36_Ch2:
	dw Pattern_67C0
	LIST_LOOP Song36_Ch2
Song32_Ch3:
	dw Pattern_6715
Song36_Ch3:
	dw Pattern_684A
	LIST_LOOP Song36_Ch3
Song32_Ch4:
	dw Pattern_6737
Song36_Ch4:
	dw Pattern_6855
	LIST_LOOP Song36_Ch4
Pattern_66DB:
	INSTR $f0, $00, $43
	db L8, REST, L2, C3, L8, Ds3, G3, L8D, REST, L8, Fs3, L8D, REST, L8, F3, L8D
	db REST, L8, D3, L4, REST, L1, B2, REST, PAT_END
Pattern_66F8:
	INSTR $f0, $00, $00
	db L8, REST, L2, C3, L8, Ds3, G3, L8D, REST, L8, Fs3, L8D, REST, L8, F3, L8D
	db REST, L8, D3, L4, REST, L1, B2, REST, PAT_END
Pattern_6715:
	INSTR_WAVE Wave_5BC6, $20
	db L8, REST, L2, C3, L8, Ds3, G3, L8D, REST, L8, Fs3, L8D, REST, L8, F3, L8D
	db REST, L8, D3, L4, REST, L1, B2, REST
	INSTR_WAVE Wave_5B96, $40
	DROP_ON
	db PAT_END
Pattern_6737:
	db L1, REST, REST, REST, REST, L16, REST, PAT_END
Pattern_673F:
	INSTR $61, $00, $40
	REPEAT $02
	db L16, E4, G4, C5, L8, E5, Ds5, D5, B4, L16, G4, L4, D4, L16, B4, As4
	db B4, L8, F5, Fs5, L8, G5
	DROP_ON
	db C5, L16, C5, L8, F4, L16, As3, As3
	DROP_OFF
	db E4, G4, C5, L8, E5, Ds5, D5, B4, L16, G4, L4, D4, L16, B4, As4, B4
	db L8, F5, G5, L16, E5
	DROP_ON
	db G3, Ds3, Ds3, L8, C4, Ds3, L16, Ds3
	DROP_OFF
	REPEAT_END
	INSTR $41, $00, $40
	db L8D, D6, L4, Cs6, C6, B5, L16, REST, L8D, C6, L4, B5, As5, A5, L16, REST
	db L8D, D6, L4, Cs6, C6, B5, L16, REST
	INSTR $60, $21, $00
	REPEAT $02
	db L16, G3, A3, REST, B3, L4, REST
	REPEAT_END
	db L16, G3, A3, REST, B3, REST, C4, REST, D4, REST, E4, REST, F4, L8, REST, G4
	db PAT_END
Pattern_67C0:
	INSTR $61, $23, $40
	REPEAT $02
	db L16, G4, C5, E5, L8, G5, Fs5, F5, D5, L16, B4, L4, G4, L16, G4, Fs4
	db G4, L8, D5, Ds5, L2, E5, L16, REST, G4, C5, E5, L8, G5, Fs5, F5, D5
	db L16, B4, L4, G4, L16, G4, Fs4, G4, L8, D5, E5, L2, C5, L16, REST
	REPEAT_END
	INSTR $41, $00, $80
	db L16, D5, F5, A5, Cs5, REST, D5, A5, C5, REST, F5, A5, B4, REST, F5, A5
	db F5, C5, E5, G5, B4, REST, E5, G5, As4, REST, E5, G5, A4, REST, E5, G5
	db E5, D5, F5, A5, Cs5, REST, D5, A5, C5, REST, F5, A5, B4, REST, F5, A5
	db F5
	INSTR $60, $21, $00
	REPEAT $02
	db L16, B3, C4, REST, D4, L4, REST
	REPEAT_END
	db L16, B3, C4, REST, D4, REST, E4, REST, F4, REST, G4, REST, A4, L8, REST, G6
	db PAT_END
Pattern_684A:
	db L32, C3, L8T, REST, L8, REST, L32, G2, L8T, REST, PAT_END
Pattern_6855:
	REPEAT $18
	db L16, NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	REPEAT $1b
	db NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	db NOISE4, NOISE4, SFX_DRUM, NOISE4, PAT_END
Song12_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C61, Song12_Ch1, Song12_Ch2, Song12_Ch3, 0
Song12_Ch1:
	dw Pattern_6886
	dw Pattern_68B1
	LIST_END
Song12_Ch2:
	dw Pattern_689E
	LIST_END
Song12_Ch3:
	dw Pattern_68DE
	LIST_LOOP Song08_Ch3
Pattern_6886:
	INSTR $a0, $81, $40
	db L8D, C5, L16, C5, L8, C5, C5, Cs5, D5, LEN14, Ds5
	INSTR $21, $00, $40
	db L32, REST, L8, REST, PAT_END
Pattern_689E:
	INSTR $e0, $81, $01
	db L8D, A5, L16, A5, L8, A5, A5, As5, B5, LEN14, C6
	INSTR $31, $00, $00
Pattern_68B1:
	db L16, D4, F4, Gs4, C5, Gs4, F4, D4, F4, Gs4, C5, D5, F5, D5, C5, Gs4
	db F4, D4, F4, Gs4, C5, D5, F5, Gs5, C6, Gs5, F5
	REPEAT $20
	db D5, F5, Gs5, C6, D6, F6, Gs6, C7, Gs6, F6, D6, C6, Gs5, F5
	REPEAT_END
	db PAT_END
Pattern_68DE:
	INSTR_WAVE Wave_5BC6, $20
	db L8, F5
	CH3_FADE_ON
	db L16, REST, F5, L8, F5, F5, Fs5, G5
	CH3_FADE_OFF
	db L2D, Gs5, REST, PAT_END
Song15_Header:
	SONG $00, LengthTable_5C70, LengthTable_5C70, Song15_Ch1, Song15_Ch2, Song15_Ch3, 0
Song15_Ch1:
	dw Pattern_690B
	LIST_END
Song15_Ch2:
	dw Pattern_6938
	LIST_END
Song15_Ch3:
	dw Pattern_6958
	LIST_END
Pattern_690B:
	INSTR $c0, $00, $80
	db L32, G3, G4, G5, G6
	INSTR $d5, $00, $80
	db L1, G7
	INSTR $70, $00, $40
	REPEAT $04
	db L16, E4, G4
	REPEAT_END
	REPEAT $04
	db G4, As4
	REPEAT_END
	REPEAT $03
	db As4, D5
	REPEAT_END
	db As4, L8, D5
	INSTR $40, $00, $41
	db L1, E5, PAT_END
Pattern_6938:
	INSTR $c0, $00, $43
	db L32, G3, G4, G5, G6, L1, REST
	INSTR $70, $00, $81
	db L8, C5, E5, G5, F5, E5, G5, As5, A5, G5, As5, D6, L8D, Cs6, L1, C6
	db PAT_END
Pattern_6958:
	INSTR_WAVE Wave_5BB6, $20
	db L32, REST, REST, REST, REST, L1, REST, L1, C3, L4, C3, G3, L16, G3, L1, As3
	db PAT_END
Song25_Header:
	SONG $18, LengthTable_5C52, LengthTable_5C52, Song25_Ch1, Song25_Ch2, Song25_Ch3, 0
Song25_Ch1:
	dw Pattern_6986
	LIST_END
Song25_Ch2:
	dw Pattern_6993
	LIST_END
Song25_Ch3:
	dw Pattern_69A0
	LIST_END
Pattern_6986:
	INSTR $86, $00, $80
	db L8D, REST, L8, As2, E3, As3, LEN14, E4, PAT_END
Pattern_6993:
	INSTR $86, $00, $80
	db L8, REST, A2, Cs3, A3, Cs4, LEN14, A4, PAT_END
Pattern_69A0:
	INSTR_WAVE Wave_5B96, $60
	db L4, REST, L16, A2, As2, Cs3, E3, A3, As3, Cs4, E4, A4, LEN14, REST, PAT_END
Song18_Header:
	SONG $00, LengthTable_5C52, LengthTable_5C52, Song18_Ch1, Song18_Ch2, 0, 0
Song18_Ch1:
	dw Pattern_69CE
Song18_Ch1_Loop:
	dw Pattern_69D9
	LIST_LOOP Song18_Ch1_Loop
Song18_Ch2:
	dw Pattern_69D5
	LIST_LOOP Song18_Ch2
Pattern_69CE:
	INSTR $16, $00, $80
	db L8D, REST, PAT_END
Pattern_69D5:
	INSTR $42, $00, $80
Pattern_69D9:
	db L8, A6, D6, Fs6, A6, D7, Fs6, A6, D7, Cs7, F6, Gs6, Cs7, B6, E6, G6
	db B6, PAT_END
Song04_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
Song04_Ch1:
	dw Pattern_6A08
	LIST_END
Song04_Ch2:
	dw Pattern_6A1D
	LIST_END
Song04_Ch3:
	dw Pattern_6A79
	LIST_END
Song04_Ch4:
	dw Pattern_6AA1
	LIST_END
Pattern_6A08:
	INSTR $41, $00, $80
	REPEAT $07
	db L8D, Gs5, Gs5, L4, Gs5, L8, Gs5, L4, Gs5
	REPEAT_END
	db L2, REST, LEN14, REST, PAT_END
Pattern_6A1D:
	INSTR $32, $00, $40
	BEND_ON
	REPEAT $04
	db L8, C7, C7, F6, L16, F6, L8, C7, C7, L16, F7, L8, F6, F6
	REPEAT_END
	INSTR $71, $00, $40
	db L8, C7, L16, C7, L8, F6, F6, Cs7, Cs7, L16, Fs6, L8, Fs6, Fs6, L8, D7
	db L16, D7, L8, G6, G6, Ds7, Ds7, L16, Gs6, L8, Gs6, Gs6, L8, E7, L16, E7
	db L8, A6, A6, F7, F7, L16, As6, L8, As6, As6
	BEND_OFF
	INSTR $a0, $21, $40
	db L16, F5, E5, F5, As5, REST, D5, REST, Ds5, L8D, REST, L16, Ds6, Ds6, L8D, REST
	db LEN14, REST, PAT_END
Pattern_6A79:
	INSTR_WAVE Wave_5B96, $20
	DROP_ON
	REPEAT $1c
	db L32, A2, L8T, REST, L8, REST, L32, E2, L8T, REST
	REPEAT_END
	DROP_OFF
	INSTR_WAVE Wave_5BB6, $20
	CH3_FADE_ON
	db L16, Gs4, G4, Gs4, L8, D5, F4, L4, G4, L16, As5, L4, As5, LEN14, REST, PAT_END
Pattern_6AA1:
	REPEAT $07
	db L16, NOISE1, NOISE4, NOISE2, NOISE1, L8, SFX_DRUM, L16, NOISE2, NOISE4, NOISE1, NOISE4, NOISE2, NOISE1, L8, SFX_DRUM
	db L16, NOISE2, NOISE5
	REPEAT_END
	db L16, SFX_DRUM, SFX_DRUM, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, L4, SFX_DRUM, L16, SFX_DRUM, L4, SFX_DRUM, LEN14, REST, PAT_END
Song14_Header:
	SONG $00, LengthTable_5C43, LengthTable_5C43, Song14_Ch1, Song14_Ch2, Song14_Ch3, 0
Song14_Ch1:
	dw Pattern_6AE8
Song14_Ch1_Loop:
	dw Pattern_6AEF
	LIST_LOOP Song14_Ch1_Loop
Song14_Ch2:
	dw Pattern_6B11
	LIST_LOOP Song14_Ch2
Song14_Ch3:
	dw Pattern_6B37
	LIST_LOOP Song14_Ch3
Pattern_6AE8:
	INSTR $37, $00, $00
	db L8, REST, PAT_END
Pattern_6AEF:
	db L4, Gs5, Gs5, Gs5, Gs5, B5, B5, B5, B5, D6, D6, D6, D6, F6, F6, F6
	db F6, Gs6, Gs6, Gs6, Gs6, Fs6, Fs6, Fs6, Fs6, Cs6, Cs6, Cs6, Cs6, B5, B5, B5
	db B5, PAT_END
Pattern_6B11:
	INSTR $37, $00, $00
	db L4, Ds5, Ds5, Ds5, Ds5, Fs5, Fs5, Fs5, Fs5, A5, A5, A5, A5, C6, C6, C6
	db C6, Ds6, Ds6, Ds6, Ds6, Cs6, Cs6, Cs6, Cs6, Gs5, Gs5, Gs5, Gs5, Fs5, Fs5, Fs5
	db Fs5, PAT_END
Pattern_6B37:
	INSTR_WAVE Wave_5B96, $40
	db L1, E2, G2, As2, Cs3, E3, D3, A2, G2, PAT_END
Song17_Header:
	SONG $00, LengthTable_5C7F, LengthTable_5C52, Song17_Ch1, Song17_Ch2, Song17_Ch3, 0
Song17_Ch1:
	dw Pattern_6B6C
Song17_Ch1_Loop:
	dw Pattern_6B6F
	LIST_LOOP Song17_Ch1_Loop
Song17_Ch2:
	dw Pattern_6C0A
	LIST_LOOP Song17_Ch2
Song17_Ch3:
	dw Pattern_6CA5
	dw Pattern_6CA5
	dw Pattern_6CA5
	dw Pattern_6CC0
	LIST_LOOP Song17_Ch3
Pattern_6B6C:
	db L8, REST, PAT_END
Pattern_6B6F:
	INSTR $32, $00, $80
	db L4D, D3, L8, Fs3, L4D, A3, L8, Gs3, G3, E3, Cs3
	INSTR $11, $00, $80
	REPEAT $08
	db L32, D7, L8T, E7, L32, Cs7, L8T, Ds7
	REPEAT_END
	db L1, D7, L2, REST
	INSTR $32, $00, $80
	db L8, Gs2, L4, A2, Cs3, E3, L8, G3, F3, Fs3, L1, D3
	INSTR $23, $00, $80
	DROP_ON
	db L8, F4, L16, F4, F4, L8, D4, D4, A3, A3, L1, A3, L2, REST
	DROP_OFF
	INSTR $42, $00, $80
	db L8, Ds2, L4, E2, Gs2, B2, L8, D3, C3, Cs3, A2, REST
	INSTR $12, $00, $80
	db L16, A7, Gs7, L2D, G7, L8, REST, L16, A6, Gs6, L4D, G6, L1, REST
	INSTR $42, $00, $80
	db L8, Gs2, L4, A2, Cs3, L4D, E3, L8, Gs2, L4, A2, D3, L4D, F3, L8, Gs2
	db L4, A2, E3, L4D, G3, L8, Gs2, L4, A2, F3, L4D, Gs3, L8, Gs2, L4, A2
	INSTR $17, $00, $00
	BEND_ON
	db L8, A7, Ds7, Gs6, C6, L1, REST, REST
	BEND_OFF
	db PAT_END
Pattern_6C0A:
	INSTR $d1, $00, $40
	db L4D, D3, L8, Fs3, L4D, A3, L8, Gs3, G3, E3, Cs3
	INSTR $21, $00, $80
	REPEAT $08
	db L32, D7, L8T, E7, L32, Cs7, L8T, Ds7
	REPEAT_END
	db L1, D7, L2, REST
	INSTR $b1, $00, $40
	db L8, Gs2, L4, A2, Cs3, E3, L8, G3, F3, Fs3, L1, D3
	INSTR $61, $00, $80
	DROP_ON
	db L8, F4, L16, F4, F4, L8, D4, D4, A3, A3, L1, A3, L2, REST
	DROP_OFF
	INSTR $d1, $00, $40
	db L8, Ds2, L4, E2, Gs2, B2, L8, D3, C3, Cs3, A2, REST
	INSTR $51, $00, $80
	db L16, A7, Gs7, L2D, G7, L8, REST, L16, A6, Gs6, L4D, G6, L1, REST
	INSTR $f1, $00, $40
	db L8, Gs2, L4, A2, Cs3, L4D, E3, L8, Gs2, L4, A2, D3, L4D, F3, L8, Gs2
	db L4, A2, E3, L4D, G3, L8, Gs2, L4, A2, F3, L4D, Gs3, L8, Gs2, L4, A2
	INSTR $19, $42, $00
	BEND_ON
	db L8, A7, Ds7, Gs6, C6, L1, REST, REST
	BEND_OFF
	db PAT_END
Pattern_6CA5:
	INSTR_WAVE Wave_5BC6, $40
	BEND_ON
	db L1, REST, REST, REST
	REPEAT $03
	db L32, A7, L8T, REST, L16, REST, L32, F7, L8T, REST, L16, REST
	REPEAT_END
	db L4, REST, PAT_END
Pattern_6CC0:
	INSTR_WAVE Sfx3_0D_Data_5B86, $40
	BEND_OFF
	CH3_FADE_ON
	db L2, REST
	REPEAT $08
	db L16, G4, A4
	REPEAT_END
	REPEAT $10
	db A4, B4
	REPEAT_END
	REPEAT $08
	db B4, D5
	REPEAT_END
	CH3_FADE_OFF
	BEND_ON
	INSTR_WAVE Wave_5BB6, $40
	REPEAT $03
	db L32, A7, L8T, REST, L16, REST, L32, F7, L8T, REST, L16, REST
	REPEAT_END
	BEND_OFF
	db L1, REST, REST, PAT_END
Song19_Header:
	SONG $04, LengthTable_5C9D, LengthTable_5C7F, Song19_Ch1, Song19_Ch2, Song19_Ch3, 0
Song19_Ch1:
	dw Pattern_6D21
Song19_Ch1_Loop:
	dw Pattern_6D52
	dw Pattern_6D80
	dw Pattern_6D9A
	dw Pattern_6D9A
	LIST_LOOP Song19_Ch1_Loop
Song19_Ch2:
	dw Pattern_6D2F
Song19_Ch2_Loop:
	dw Pattern_6DB7
	dw Pattern_6DF3
	LIST_LOOP Song19_Ch2_Loop
Song19_Ch3:
	dw Pattern_6D43
Song19_Ch3_Loop:
	dw Pattern_6E3C
	dw Pattern_6E68
	LIST_LOOP Song19_Ch3_Loop
Pattern_6D21:
	INSTR $65, $00, $00
	db L16, D4, Cs4, D4, E4, F4, Fs4, L4D, G4, PAT_END
Pattern_6D2F:
	INSTR $84, $00, $40
	db L16, G4, Fs4, G4, Gs4, A4, As4, L8, B4, L32, Fs7, L8D, G7, L8T, REST, PAT_END
Pattern_6D43:
	INSTR_WAVE Wave_5BB6, $20
	CH3_FADE_ON
	db L16, B3, As3, B3, B3, C4, Cs4, L4D, D4, PAT_END
Pattern_6D52:
	INSTR $37, $00, $80
	db L4D, E5, B5, A5, D5, L8, B4, As4, B4, L4D, F5, L8, G5, E5, Ds5, L4D
	db E5, L8, C5, B4, C5, L4, Ds5, L8, Fs5, G5, Fs5, G5, L4, Cs6, L8, G5
	db F5, E5, F5, L4, B5, L8, D5, L2D, E5, PAT_END
Pattern_6D80:
	INSTR $46, $00, $80
	db L8, REST, L4D, B6, B6, B6, Cs7, B6, B6, A6, L4, A6
	INSTR $10, $00, $80
	db L4D, D5, Cs5, C5, B4, PAT_END
Pattern_6D9A:
	INSTR $0e, $00, $80
	db L8, REST, L4, B3
	INSTR $47, $00, $80
	db L4D, A3
	INSTR $0e, $00, $80
	db L8, REST, L4, C4
	INSTR $47, $00, $80
	db L4D, B3, PAT_END
Pattern_6DB7:
	INSTR $85, $00, $80
	db L4, C6, L8, E6, L4, G6, L8, Fs6, L4, F6, L8, D6, L4D, B5, L8, G5
	db Fs5, G5, L4, D6, L8, F6, E6, C6, A5, L4D, G5, L8, A5, Gs5, A5, L4
	db C6, L8, D6, L8, E6, Ds6, E6, L4, A6, L8, E6, L8, D6, Cs6, D6, L4
	db G6, L8, B5, L2, C6, L8, REST, PAT_END
Pattern_6DF3:
	INSTR $50, $21, $80
	REPEAT $02
	db L16, G5, A5, L4, B5
	REPEAT_END
	db L16, G5, A5, L8, B5, L8D, B5, L16, As5, L8, B5, Cs6, G5
	REPEAT $02
	db L4, B5, L16, REST, As5
	REPEAT_END
	db L2, A5, L8, REST
	REPEAT $02
	db L16, F5, G5, L4, A5
	REPEAT_END
	db L16, F5, G5, L8, A5, C6, E6, L4, G6, L16, B5, As5, L2D, A5
	INSTR $25, $00, $00
	BEND_ON
	REPEAT $06
	db L8, REST, A6, D7
	REPEAT_END
	BEND_OFF
	db PAT_END
Pattern_6E3C:
	db L8, C3, G3, G2, C3, G3, Ds3
	REPEAT $04
	db D3, G3, G2
	REPEAT_END
	REPEAT $02
	db C3, G3, G2
	REPEAT_END
	db F3, A3, F3, Fs3, A3, Fs3, G3, C4, G3, G3, Cs4, G3, F3, E3, D3, G3
	db F3, D3, C3, E3, G3, C3, L4, C2, PAT_END
Pattern_6E68:
	db L8, E3, G3, B3, Ds3, G3, B3, D3, G3, B3, Cs3, G3, B3
	REPEAT $02
	db D3, Fs3, A3, A2, Fs3, A3
	REPEAT_END
	db D3, F3, A3, Cs3, F3, A3, C3, F3, A3, B2, F3, G3
	REPEAT $02
	db L8, C3, G3, G2, C3, G3, G2, D3, G3, G2, D3, G3, G2
	REPEAT_END
	db PAT_END
Song20_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C43, Song20_Ch1, Song20_Ch2, Song20_Ch3, Song20_Ch4
Song20_Ch1:
	dw Pattern_6EC8
Song20_Ch1_Loop:
	dw Pattern_6F1D
	LIST_LOOP Song20_Ch1_Loop
Song20_Ch2:
	dw Pattern_6ED9
Song20_Ch2_Loop:
	dw Pattern_6F83
	LIST_LOOP Song20_Ch2_Loop
Song20_Ch3:
	dw Pattern_6EF4
Song20_Ch3_Loop:
	dw Pattern_701A
	LIST_LOOP Song20_Ch3_Loop
Song20_Ch4:
	dw Pattern_6F0C
Song20_Ch4_Loop:
	dw Pattern_7067
	LIST_LOOP Song20_Ch4_Loop
Pattern_6EC8:
	INSTR $60, $81, $00
	db L4, D5, Ds5, E5, F5, L8, REST, F5, F5, F5, L2, REST, PAT_END
Pattern_6ED9:
	INSTR $80, $81, $40
	db L4, G5, A5, As5, B5, L8, REST, B5, B5, B5, REST
	INSTR $81, $00, $80
	DROP_ON
	db L16, G4, G4, L4, C4
	DROP_OFF
	db PAT_END
Pattern_6EF4:
	INSTR_WAVE Sfx3_0D_Data_5B86, $20
	db L8, B3, REST, C4, REST, Cs4, REST, D4, REST, REST
	CH3_FADE_ON
	db L8, D4, D4, L4D, D4
	CH3_FADE_OFF
	db L4, G2, PAT_END
Pattern_6F0C:
	db L4, SFX_DRUM, SFX_DRUM, SFX_DRUM, L4D, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, SFX_DRUM, REST, L16, NOISE5, NOISE5, L4, SFX_DRUM
	db PAT_END
Pattern_6F1D:
	INSTR $61, $00, $40
	db L8, REST, L16, D4, C5, L8, E5, C5, G5, E5, C5, L4, G4, L16, A4, D5
	db L8, F5, D5, F6, F6, F6, L4, B4, L16, A4, D5, L8, F5, D5, A5, F5
	db D5, L4, B4, L16, G4, C5, L8, E5, C5, G5, E5, C5, L4, G4, L16, A4
	db D5, L8, F5, D5, A5, F5, D5, L4, B4, L16, G4, C5, L8, E5, C5, G5
	db E5, Cs5, G4, L1, F4, L8, REST, REST, A5, A5, L2, A5
	INSTR $20, $21, $41
	db L2, C5, B4, A4, B4, B4, A4, Gs4, A4, C5, B4, A4, B4, D5, Cs5, C5
	db B4, PAT_END
Pattern_6F83:
	INSTR $a1, $82, $40
	db L8, REST, L4, C5, L8, E5, G5, G5, L4, Fs5, L8, F5, D5, L4, B4, L8
	db G6, G6, G6, REST, REST, L4, D5, L8, F5, A5, A5, L4, Gs5, L8, G5, A5
	db G5, F5, E5
	INSTR $42, $00, $00
	BEND_ON
	db L8, D7, L4, G7
	BEND_OFF
	INSTR $a1, $82, $40
	db L8, D5, Cs5, D5, L4, A5, L8, REST, G5, F5, E5, Ds5, E5, L4, B5, REST
	db L8, G5, Gs5, A5, C6, E6, L4, G6, E6, C6
	INSTR $91, $00, $80
	db L8, C6, C6, L2, C6
	INSTR $71, $00, $80
	db L8, REST, A4, Gs4, A4, E5, L4, E5, L8, A4, Gs4, A4, L2D, E5, L8, REST
	db A4, Gs4, A4, E5, L4, E5, L8, G5, E5, C5, L2D, A4, L8, REST, A4, Gs4
	db A4, E5, L4, E5, L8, A4, Gs4, A4, L2D, E5, L8, REST, B4, As4, B4, Fs5
	db L2, Fs5, L8, A4, Gs4, A4, E5, G5, E5, C5, PAT_END
Pattern_701A:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	db L4D, C4, E4, L4, G4
	REPEAT $02
	db L4D, D4, F4, L4, G4
	REPEAT_END
	db L4D, C4, E4, L4, G4, L4D, D4, G4, L4, G3, L4D, C4, A3, L4, Cs4, L1
	db D4, L4, REST, L8, G5, G5, L2, G5
	REPEAT $02
	db L4D, D4, G4, L4, G3
	REPEAT_END
	REPEAT $02
	db L4D, C4, G4, L4, G3
	REPEAT_END
	REPEAT $02
	db L4D, D4, G4, L4, G3
	REPEAT_END
	db L4D, E4, A4, L4, A3, L4D, D4, G4, L4, G3, PAT_END
Pattern_7067:
	REPEAT $06
	db L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE1, NOISE5, NOISE1, NOISE1, NOISE5, NOISE1
	REPEAT_END
	db L1, NOISE5, L4, REST, L8, NOISE5, NOISE5, L2, NOISE5
	REPEAT $08
	db L8, NOISE2, L16, NOISE1, NOISE1, L8, NOISE1, NOISE5, NOISE1, NOISE1, NOISE5, NOISE1
	REPEAT_END
	db PAT_END
Song21_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song21_Ch1, Song21_Ch2, Song21_Ch3, Song21_Ch4
Song21_Ch1:
	dw Pattern_70B4
	LIST_LOOP Song21_Ch1
Song21_Ch2:
	dw Pattern_70C1
	LIST_LOOP Song21_Ch2
Song21_Ch3:
	dw Pattern_70E3
	LIST_LOOP Song21_Ch3
Song21_Ch4:
	dw Pattern_70F9
	LIST_LOOP Song21_Ch4
Pattern_70B4:
	INSTR $40, $21, $40
	db L8, REST, L4, A4, L8, REST, L2, REST, PAT_END
Pattern_70C1:
	INSTR $50, $21, $40
	db L8, REST, L4, Cs5, L16, B4, A4, REST, REST, A3, As3, B3, As3, A3, L8D, REST
	db L4, D5, L16, B4, A4, REST, REST, A3, As3, B3, As3, A3, REST, PAT_END
Pattern_70E3:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	REPEAT $02
	db L8D, E3, G3, L8, A3
	REPEAT_END
	REPEAT $02
	db L8D, D3, Fs3, L8, A3
	REPEAT_END
	db PAT_END
Pattern_70F9:
	db L16, NOISE4, NOISE4, NOISE5, NOISE4, NOISE4, NOISE4, SFX_DRUM, NOISE5, PAT_END
Song22_Header:
	SONG $0e, LengthTable_5C52, LengthTable_5C52, Song22_Ch1, Song22_Ch2, Song22_Ch3, Song22_Ch4
Song22_Ch1:
	dw Pattern_7120
	LIST_END
Song22_Ch2:
	dw Pattern_7135
	LIST_END
Song22_Ch3:
	dw Pattern_7154
	LIST_END
Song22_Ch4:
	dw Pattern_7167
	LIST_END
Pattern_7120:
	INSTR $40, $81, $00
	db L8, C5, B4, C5, L4, Fs5, L8, Fs5, L4, As4, B4
	REPEAT $20
	db LEN14, REST
	REPEAT_END
	db PAT_END
Pattern_7135:
	INSTR $a0, $81, $40
	db L8, A4, Gs4, A4, L4, D5, L8, D5, L4, Fs4, G4
	INSTR $a1, $22, $80
	db L8, D2, Ds2, E2, Ds2, D2
	REPEAT $20
	db LEN14, REST
	REPEAT_END
	db PAT_END
Pattern_7154:
	INSTR_WAVE Wave_5B96, $20
	DROP_ON
	REPEAT $05
	db L32, G2, L8T, REST, L8D, REST
	REPEAT_END
	REPEAT $20
	db REST
	REPEAT_END
	db PAT_END
Pattern_7167:
	REPEAT $04
	db L16, NOISE4, NOISE4, L8, SFX_DRUM
	REPEAT_END
	db L2D, SFX_DRUM, L1, REST
	REPEAT $20
	db REST
	REPEAT_END
	db PAT_END
Song08_Header:
	SONG $00, LengthTable_5C52, LengthTable_5C52, Song08_Ch1, Song08_Ch2, Song08_Ch3, 0
Song08_Ch1:
	dw Pattern_718F
	dw Pattern_719A
	LIST_END
Song08_Ch2:
	dw Pattern_7196
	LIST_END
Pattern_718F:
	INSTR $f1, $00, $83
	db L32, REST, PAT_END
Pattern_7196:
	INSTR $f1, $00, $80
Pattern_719A:
	db L8, A2, As2, B2, As2, LEN14, A2
	REPEAT $20
	db REST
	REPEAT_END
	db PAT_END
Song23_Header:
	SONG $04, LengthTable_5C7F, LengthTable_5C61, Song23_Ch1, Song23_Ch2, Song23_Ch3, Song23_Ch4
Song23_Ch1:
	dw Pattern_71EB
Song23_Ch1_Loop:
	dw Pattern_7224
	dw Pattern_7224
	dw Pattern_7242
	dw Pattern_7224
	dw Pattern_7280
	LIST_LOOP Song23_Ch1_Loop
Song23_Ch2:
	dw Pattern_71EE
Song23_Ch2_Loop:
	dw Pattern_72AE
	dw Pattern_72AE
	dw Pattern_72CC
	dw Pattern_72AE
	dw Pattern_7301
	LIST_LOOP Song23_Ch2_Loop
Song23_Ch3:
	dw Pattern_7200
Song23_Ch3_Loop:
	dw Pattern_7339
	dw Pattern_7339
	dw Pattern_734E
	dw Pattern_7339
	dw Pattern_7377
	LIST_LOOP Song23_Ch3_Loop
Song23_Ch4:
	dw Pattern_7211
Song23_Ch4_Loop:
	dw Pattern_73A0
	LIST_LOOP Song23_Ch4_Loop
Pattern_71EB:
	db L1, REST, PAT_END
Pattern_71EE:
	INSTR $b1, $00, $00
	db L16, B4, L8, C5, D5, E5, F5
	BEND_ON
	db L8D, REST, L4, G7
	BEND_OFF
	db PAT_END
Pattern_7200:
	INSTR_WAVE Wave_5B96, $20
	CH3_FADE_ON
	db L16, G3, L8, A3, B3, C4, D4, L8D, REST, L4, G2, PAT_END
Pattern_7211:
	db L16, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, SFX_DRUM, L4, SFX_DRUM, L16, REST, NOISE5, L32, NOISE5, L8T, NOISE5, L16
	db NOISE5, SFX_DRUM, PAT_END
Pattern_7224:
	INSTR $71, $00, $80
	db L8D, REST, L16, E4, G4, C5, E5, Ds5, L8D, D5, B4, L4, G4, L8, Gs6, L4
	db Fs6, L8D, Gs6, L8, Fs6, L16, Gs6, L8, Fs6, PAT_END
Pattern_7242:
	db L16, C4, B3, C4, L8, Ds4, Fs4, L16, Fs4, L16, G4, Fs4, G4, Cs5, L4, REST
	db L8D, D3, G2, L8, REST, L8D, C3, A2, L8, E3, L16, C4, B3, C4, L8, Ds4
	db Fs4, L16, Fs4, L16, G4, Fs4, G4, L8D, Cs5, L16, C5, Cs5, L8, E5, L16, Cs5
	db L8D, Ds5, L16, A4, B4, L8, C5, L16, G4, L8, A4, L8D, F4, PAT_END
Pattern_7280:
	db L8D, REST, L16, E4, G4, C5, E5, Ds5, L8D, D5, B4, L8, G4, L16, B3, As3
	db B3, L8, F4, Fs4, G4, REST, L16, E7, L4, E7
	INSTR $33, $00, $00
	BEND_ON
	REPEAT $02
	db L8, REST, F7, L4, F7, L8D, F7, F7, L8, F7
	REPEAT_END
	BEND_OFF
	db PAT_END
Pattern_72AE:
	INSTR $91, $00, $80
	db L8D, REST, L16, G5, C6, E6, G6, Fs6, L8D, F6, D6, L4, B5, L8, A6, L4
	db G6, L8D, A6, L8, G6, L16, A6, L8, G6, PAT_END
Pattern_72CC:
	db L16, A4, Gs4, A4, L8, C5, D5, L16, Ds5, E5, Ds5, E5, A5, L4, REST, L1
	db REST, L16, A4, Gs4, A4, L8, C5, D5, L16, Ds5, L16, E5, Ds5, E5, L8D, A5
	db L16, Gs5, A5, L8, B5, L16, Fs5, L8D, G5, L16, Fs5, G5, L8, A5, L16, E5
	db L8, F5, L8D, D5, PAT_END
Pattern_7301:
	db L8D, REST, L16, G5, C6, E6, G6, Fs6, L8D, F6, D6, L8, B5, L16, G4, Fs4
	db G4, L8, D5, Ds5, E5, REST, L16, C7, L4, C7
	INSTR $51, $00, $80
	DROP_ON
	REPEAT $02
	db L16, REST, L32, F4, L8T, F4, L16, F4, As3, As3, L8, G3, L16, A4, A4, Ds4
	db Ds4, As3, L4, REST
	REPEAT_END
	DROP_OFF
	db PAT_END
Pattern_7339:
	db L8D, C3, G2, L8, REST, L8D, D3, G2, L8, D2, L8D, D3, G2, L8, REST, L8D
	db C3, G2, L8, C2, PAT_END
Pattern_734E:
	db L8D, F3, Fs3, L8, REST, L8D, G3, A3, L8, Cs3, L8D, D3, G2, L8, REST, L8D
	db C3, A2, L8, E3, L8D, F3, Fs3, L8, REST, L8D, G3, A3, L8, G3, L8D, Fs3
	db B2, L8, REST, L8D, D3, G2, L8, D3, PAT_END
Pattern_7377:
	db L8D, C3, G2, L8, C2, L8D, D3, G2, L8, D2, L2, G3, L8D, REST
	CH3_FADE_OFF
	DROP_ON
	REPEAT $02
	db L32, G4, L8T, REST
	REPEAT_END
	db L8D, REST
	DROP_OFF
	CH3_FADE_ON
	REPEAT $02
	db L8D, C3, G2, L8, REST, L8D, D3, G2, L8, D2
	REPEAT_END
	db PAT_END
Pattern_73A0:
	REPEAT $0b
	db L16, NOISE1, NOISE4, NOISE2, NOISE4, NOISE1, NOISE4, NOISE5, NOISE2, NOISE1, NOISE4, NOISE2, NOISE4, NOISE1, NOISE4, NOISE2
	db NOISE5
	REPEAT_END
	db L8D, NOISE2, L8, NOISE5, NOISE5, L4, NOISE5, L16, SFX_DRUM, L4, SFX_DRUM
	REPEAT $02
	db L16, NOISE1, NOISE4, NOISE2, NOISE4, NOISE1, NOISE4, NOISE5, NOISE2, NOISE1, NOISE4, NOISE2, NOISE4, NOISE1, NOISE4, NOISE2
	db NOISE5
	REPEAT_END
	db PAT_END
Song37_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song37_Ch1, Song37_Ch2, Song37_Ch3, Song37_Ch4
Song33_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song33_Ch1, Song33_Ch2, Song33_Ch3, Song33_Ch4
Song33_Ch1:
	dw Pattern_7414
Song37_Ch1:
	dw Pattern_743F
	dw Pattern_744F
	LIST_LOOP Song37_Ch1
Song33_Ch2:
	dw Pattern_747C
Song37_Ch2:
	dw Pattern_74A7
	dw Pattern_74B8
	LIST_LOOP Song37_Ch2
Song33_Ch3:
	dw Pattern_74D9
Song37_Ch3:
	dw Pattern_74F6
	dw Pattern_7516
	LIST_LOOP Song37_Ch3
Song33_Ch4:
	dw Pattern_7540
Song37_Ch4:
	dw Pattern_755C
	LIST_LOOP Song37_Ch4
Pattern_7414:
	INSTR $90, $81, $00
	db L4D, REST, L8, C7, L16, Ds7, L8, REST, L16, G7, L8, Fs7, L16, REST, L8, C7
	db L16, Ds7, L8, REST, L16, G7, L8, Fs7
	INSTR $10, $00, $40
	db L2D, Fs7, L1, Fs7
	INSTR $19, $00, $40
	db L8, Fs7, PAT_END
Pattern_743F:
	INSTR $51, $00, $80
	DROP_ON
	REPEAT $18
	db L8, REST, G4, REST, L16, A3, A3
	REPEAT_END
	db PAT_END
Pattern_744F:
	INSTR $20, $00, $81
	DROP_OFF
	db L8, REST, L8D, F6, L2, F6, L16, E6, F6, Cs6, As5, Fs5, L8D, F5, L2, F5
	db L16, Ds5, F5, Fs5, As5, Cs6, L8D, F6, L16, Fs6, F6, L4D, F6, L16, E6, F6
	db Cs6, As5, Fs5, L8, F5, L2D, F5, PAT_END
Pattern_747C:
	INSTR $c0, $81, $40
	db L4D, REST, L8, C5, L16, Ds5, L8, REST, L16, G5, L8, Fs5, L16, REST, L8, C5
	db L16, Ds5, L8, REST, L16, G5, L8, Fs5
	INSTR $10, $00, $40
	db L2D, Fs5, L1, Fs5
	INSTR $19, $00, $40
	db L8, Fs5, PAT_END
Pattern_74A7:
	INSTR $b1, $21, $80
	REPEAT $0c
	db L8, C3, As2, A2, Gs2, G2, A2, As2, B2
	REPEAT_END
	db PAT_END
Pattern_74B8:
	db Ds3, F3, Fs3, Gs3, As3, Fs3, Gs3, F3, Ds3, Cs3, C3, B2, As2, C3, Cs3, D3
	db Ds3, F3, Fs3, As2, Gs2, Fs2, F2, E2, Ds2, F2, Fs2, Gs2, A2, A2, As2, As2
	db PAT_END
Pattern_74D9:
	INSTR_WAVE Wave_5BE6, $20
	CH3_FADE_ON
	db L4D, REST, L8, C4, L16, Ds4, L8, REST, L16, G4, L8D, Fs4, L8, C4, L16, Ds4
	db L8, REST, L16, G4, L1, Fs4, REST, PAT_END
Pattern_74F6:
	INSTR_WAVE Wave_5BB6, $20
	CH3_FADE_ON
	REPEAT $03
	db L1, REST, REST, L2D, REST, L8D, REST, L16, D7, B6, G6, Ds6, L4, D6, L16, D6
	db B5, G5, Ds5, L4, D5, L16, REST
	REPEAT_END
	db PAT_END
Pattern_7516:
	INSTR_WAVE Wave_5BB6, $41
	CH3_FADE_OFF
	db L8D, F6, L2, F6, L16, E6, F6, Cs6, As5, Fs5, L8D, F5, L2, F5, L16, Ds5
	db F5, Fs5, As5, Cs6, L8D, F6, L16, Fs6, F6, L4D, F6, L16, E6, F6, Cs6, As5
	db Fs5, L1, F5
	CH3_FADE_ON
	db PAT_END
Pattern_7540:
	db L4D, REST, L8, SFX_DRUM, L8D, SFX_DRUM, L16, SFX_DRUM, L8D, SFX_DRUM, L8, SFX_DRUM, L8D, SFX_DRUM, L16, SFX_DRUM
	db LEN14, SFX_DRUM, L4D, REST, L32, REST, L8T, SFX_DRUM, SFX_DRUM, L32, SFX_DRUM, PAT_END
Pattern_755C:
	REPEAT $10
	db L8, NOISE3, L16, NOISE5, NOISE4
	REPEAT_END
	db PAT_END
Song38_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C52, Song37_Ch1, Song37_Ch2, Song37_Ch3, Song37_Ch4
Song34_Header:
	SONG $04, LengthTable_5C61, LengthTable_5C52, Song34_Ch1, Song34_Ch2, Song34_Ch3, Song34_Ch4
Song34_Ch1:
	dw Pattern_7597
	LIST_LOOP Song37_Ch1
Song34_Ch2:
	dw Pattern_75A4
	LIST_LOOP Song37_Ch2
Song34_Ch3:
	dw Pattern_75B1
	LIST_LOOP Song37_Ch3
Song34_Ch4:
	dw Pattern_75BF
	LIST_LOOP Song37_Ch4
Pattern_7597:
	INSTR $a0, $81, $00
	db L4T, Cs7, E7, Gs7, G7, LEN14, REST, REST, PAT_END
Pattern_75A4:
	INSTR $80, $81, $40
	db L4T, Cs5, E5, Gs5, G5, LEN14, REST, REST, PAT_END
Pattern_75B1:
	INSTR_WAVE Wave_5BE6, $20
	CH3_FADE_ON
	db L4T, Cs4, E4, Gs4, G4, LEN14, REST, REST, PAT_END
Pattern_75BF:
	db L4T, SFX_DRUM, SFX_DRUM, SFX_DRUM, SFX_DRUM, LEN14, REST, REST, PAT_END
Song39_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song39_Ch1, Song39_Ch2, Song39_Ch3, Song39_Ch4
Song35_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C52, Song35_Ch1, Song35_Ch2, Song35_Ch3, Song35_Ch4
Song35_Ch1:
	dw Pattern_7602
Song39_Ch1:
	dw Pattern_7659
	LIST_LOOP Song39_Ch1
Song35_Ch2:
	dw Pattern_7617
Song39_Ch2:
	dw Pattern_7674
	LIST_LOOP Song39_Ch2
Song35_Ch3:
	dw Pattern_762C
Song39_Ch3:
	dw Pattern_768F
	LIST_LOOP Song39_Ch3
Song35_Ch4:
	dw Pattern_7648
Song39_Ch4:
	dw Pattern_76A7
	LIST_LOOP Song39_Ch4
Pattern_7602:
	INSTR $a0, $81, $00
	db L4D, F6, Gs6, Cs7, C7, L8, F6, Gs6, Cs7, C7, L4, REST, L1, REST, L16, REST
	db PAT_END
Pattern_7617:
	INSTR $80, $81, $40
	db L4D, F4, Gs4, Cs5, C5, L8, F4, Gs4, Cs5, C5, L4, REST, L1, REST, L16, REST
	db PAT_END
Pattern_762C:
	INSTR_WAVE Wave_5BF6, $20
	db L8D, F3, REST, Gs3, REST, Cs4, REST, C4, REST, L16, F3, REST, Gs3, REST, Cs4, REST
	db C4, REST, REST, L4, REST, L1, REST, PAT_END
Pattern_7648:
	db L4D, SFX_DRUM, SFX_DRUM, SFX_DRUM, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, SFX_DRUM, SFX_DRUM, L4, REST, L1, REST, L16, REST
	db PAT_END
Pattern_7659:
	INSTR $30, $81, $40
	REPEAT $04
	db L16, As5, As5, REST
	REPEAT_END
	db As5, REST, As5, REST
	REPEAT $04
	db L16, Cs6, Cs6, REST
	REPEAT_END
	db Cs6, REST, Cs6, REST, PAT_END
Pattern_7674:
	INSTR $50, $81, $40
	REPEAT $04
	db L16, Ds6, Ds6, REST
	REPEAT_END
	db Ds6, REST, Ds6, REST
	REPEAT $04
	db L16, Fs6, Fs6, REST
	REPEAT_END
	db Fs6, REST, Fs6, REST, PAT_END
Pattern_768F:
	INSTR_WAVE Sfx3_0D_Data_5B86, $40
	CH3_FADE_ON
	REPEAT $04
	db L16, E4, L8, E4
	REPEAT_END
	db E4, E4
	REPEAT $04
	db L16, G4, L8, G4
	REPEAT_END
	db G4, G4, PAT_END
Pattern_76A7:
	REPEAT $02
	db L8D, SFX_DRUM, NOISE5
	REPEAT_END
	db L8, SFX_DRUM, NOISE5, PAT_END
Song26_Header:
	SONG $00, LengthTable_5C70, LengthTable_5C70, Song26_Ch1, Song26_Ch2, Song26_Ch3, 0
Song26_Ch1:
	dw Pattern_690B
	dw Pattern_76D0
	LIST_END
Song26_Ch2:
	dw Pattern_6938
	dw Pattern_76E4
	LIST_END
Song26_Ch3:
	dw Pattern_6958
	dw Pattern_76F8
	LIST_END
Pattern_76D0:
	INSTR $47, $00, $00
	db L1, REST, REST, REST, LEN14, REST
	TEMPO LengthTable_5C52
	db L4, C2, Ds2, G2, LEN14, Fs2, PAT_END
Pattern_76E4:
	INSTR $c0, $00, $40
	db L1, REST, REST, REST, LEN14, REST
	TEMPO LengthTable_5C52
	db L4, F2, Gs2, C3, LEN14, B2, PAT_END
Pattern_76F8:
	INSTR_WAVE Wave_5BF6, $40
	db L1, REST, REST, REST, LEN14, REST
	TEMPO LengthTable_5C52
	db L4, F2, Gs2, C3, LEN14, B2, PAT_END
Song27_Header:
	SONG $00, LengthTable_5C7F, LengthTable_5C7F, Song27_Ch1, Song27_Ch2, Song08_Ch3, 0
Song27_Ch1:
	dw Pattern_7725
	LIST_LOOP Song27_Ch1
Song27_Ch2:
	dw Pattern_7750
	LIST_LOOP Song27_Ch2
Pattern_7725:
	INSTR $42, $00, $40
	REPEAT $02
	db L8, G4, L16, D5, D5, L8, D4, D5
	REPEAT_END
	REPEAT $02
	db As4, L16, F5, F5, L8, F4, F5
	REPEAT_END
	db L4D, Cs5, E5, L2, Gs5, L4, As3, B3, C4, L16, Gs5, As5, C6, D6, L8, E6
	db D5, PAT_END
Pattern_7750:
	INSTR $40, $81, $80
	db L8D, B5, L16, E5, L8D, Fs5, L16, Cs6, L8D, B5, L16, E5, L8D, Fs5, L16, B5
	db L8D, D6, L16, F5, L8D, G5, L16, E6, L8D, D6, L16, F5, L8D, G5, L16, D6
	db L8, F6, L16, Ds6, Cs6, L8, C6, As5, L16, Gs5, Fs5, L8, E5, D5, L16, C5
	db As4, L8, A4, L16, A3, A3, L8, B3, A3, C4, A3, Cs4, A3, L16, Gs3, As3
	db C4, D4, E4, REST, L8, Fs6, PAT_END
Song05_Header:
	SONG $00, LengthTable_5C34, LengthTable_5C34, Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
Song05_Ch1:
	dw Pattern_77C0
	LIST_LOOP Song05_Ch1
Song05_Ch2:
	dw Pattern_77DF
	LIST_LOOP Song05_Ch2
Song05_Ch3:
	dw Pattern_77FE
	LIST_LOOP Song05_Ch3
Song05_Ch4:
	dw Pattern_7824
	LIST_LOOP Song05_Ch4
Pattern_77C0:
	INSTR $42, $00, $40
	REPEAT $02
	db L2, REST, L8, REST, L2, A5, L2D, REST, L4D, Fs5
	REPEAT_END
	REPEAT $02
	db L2, REST, L8, REST, L2, A5, L2D, REST, L4D, E5
	REPEAT_END
	db PAT_END
Pattern_77DF:
	INSTR $42, $00, $40
	REPEAT $02
	db L2, REST, L8, REST, L2, Fs6, L2D, REST, L4D, Cs6
	REPEAT_END
	REPEAT $02
	db L2, REST, L8, REST, L2, E6, L2D, REST, L4D, C6
	REPEAT_END
	db PAT_END
Pattern_77FE:
	INSTR_WAVE Sfx3_0D_Data_5B86, $20
	CH3_FADE_ON
	REPEAT $02
	db L2, D3, L8, REST, L4D, Cs6, L8, D3, L4D, A2, A2, L4D, A5
	REPEAT_END
	REPEAT $02
	db L2, F3, L8, REST, L4D, C6, L8, F3, L4D, C3, C3, L4D, A5
	REPEAT_END
	db PAT_END
Pattern_7824:
	REPEAT $04
	db L4D, NOISE2, L4, NOISE2, L8, NOISE5, L4D, NOISE2, L4D, NOISE2, L4, NOISE2, L8, NOISE2, L4D, NOISE5
	REPEAT_END
	db PAT_END
Song28_Header:
	SONG $02, LengthTable_5C70, LengthTable_5C70, Song28_Ch1, Song28_Ch2, Song08_Ch3, 0
Song28_Ch1:
	dw Pattern_7851
	LIST_LOOP Song28_Ch1
Song28_Ch2:
	dw Pattern_7865
	LIST_LOOP Song28_Ch2
Pattern_7851:
	INSTR $30, $41, $40
	REPEAT $04
	db L8, A4, Cs5, E5, Cs5
	REPEAT_END
	REPEAT $04
	db E4, A4, D5, A4
	REPEAT_END
	db PAT_END
Pattern_7865:
	INSTR $51, $83, $80
	REPEAT $04
	db L8, Gs6, Fs6, E6, Fs6
	REPEAT_END
	REPEAT $04
	db A6, Fs6, E6, Fs6
	REPEAT_END
	db PAT_END
Song29_Header:
	SONG $00, LengthTable_5C70, LengthTable_5C70, Song29_Ch1, Song29_Ch2, Song29_Ch3, Song29_Ch4
Song29_Ch1:
	dw Pattern_789E
	LIST_LOOP Song29_Ch1
Song29_Ch2:
	dw Pattern_78C4
	LIST_LOOP Song29_Ch2
Song29_Ch3:
	dw Pattern_7933
	LIST_LOOP Song29_Ch3
Song29_Ch4:
	dw Pattern_7982
	LIST_LOOP Song29_Ch4
Pattern_789E:
	INSTR $a0, $00, $80
	DROP_ON
	REPEAT $28
	db L32, A2, L8T, REST, L8D, REST
	REPEAT_END
	REPEAT $28
	db L32, A2, L8T, REST, L8D, REST
	REPEAT_END
	db L1, REST, REST, LEN14, REST
	REPEAT $02
	db L32, A2, L8T, REST, L8D, REST
	REPEAT_END
	db PAT_END
Pattern_78C4:
	INSTR $71, $83, $00
	REPEAT $02
	db L8, Gs6, Fs6, E6, L16, Fs6, L8D, Gs6, L8, Fs6, E6, Fs6
	REPEAT_END
	REPEAT $02
	db A6, Fs6, E6, L16, Fs6, L8D, A6, L8, Fs6, E6, Fs6
	REPEAT_END
	REPEAT $02
	db Gs6, Fs6, E6, L16, Fs6, L8D, Gs6, L8, Fs6, E6, Fs6
	REPEAT_END
	db A6, Fs6, E6, L16, Fs6, L8D, A6, L8, Fs6, E6, Fs6, L16, E5, E5, E6, E6
	db E7, E7, REST, REST
	INSTR $60, $21, $81
	db L4, B4, B5, L4D, Gs5, L1, E5, L8, REST, L8D, Cs5, E5, L8, Fs5, L4D, B4
	db L1, A4, L8, REST, L4, B4, B5, L4D, Gs5, L2D, E5, L8, REST, L4, Cs5, E5
	db Fs5, L4D, B4, LEN14, A4, L8, REST, PAT_END
Pattern_7933:
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	REPEAT $05
	db L8D, A3, Fs3, L4, E3, L8, Fs3, A3, B3, L8D, A3, Fs3, L4, E3, L8, Fs3
	db A3, Fs3, L8D, E3, Cs3, L4, B2, L8, Cs3, E3, Fs3, L8D, E3, Cs3, L4, B2
	db L8, Cs3, E3, Fs3
	REPEAT_END
	CH3_FADE_OFF
	INSTR_WAVE Wave_5B96, $20
	DROP_ON
	REPEAT $0d
	db L32, A2, L8T, REST, L8D, REST
	REPEAT_END
	db L32, A2, L8T, REST, L8, REST
	DROP_OFF
	INSTR_WAVE Wave_5BC6, $20
	CH3_FADE_ON
	db L16, E3, L8, E3, Fs3, A3, B3, PAT_END
Pattern_7982:
	db L16, NOISE5, NOISE4, L8, NOISE3, PAT_END
Song30_Header:
	SONG $04, LengthTable_5C70, LengthTable_5C70, Song30_Ch1, Song30_Ch2, Song08_Ch3, 0
Song30_Ch1:
	dw Pattern_79A1
	LIST_LOOP Song30_Ch1
Song30_Ch2:
	dw Pattern_79EE
	LIST_LOOP Song30_Ch2
Pattern_79A1:
	INSTR $61, $00, $40
	db L8, C3, Ds3, G3, C4, B3, Ds3, G3, B3, As3, Ds3, G3, As3, L2, A3, L8
	db F3, Gs3, C4, F4, E4, Gs3, C4, E4, L4, Ds4, L2D, C4
	INSTR $20, $00, $40
	REPEAT $03
	db L16, D4, F4
	REPEAT_END
	db Ds4, Fs4
	REPEAT $04
	db F4, Gs4
	REPEAT_END
	REPEAT $03
	db Ds4, G4
	REPEAT_END
	db F4, Gs4
	REPEAT $03
	db Fs4, A4
	REPEAT_END
	db C5, A4
	INSTR $61, $00, $40
	db L1, B4, L8, G2, Gs2, G2, Gs2, L2, G2, PAT_END
Pattern_79EE:
	INSTR $61, $83, $40
	db L8, C5, Ds5, G5, C6, B5, Ds5, G5, B5, As5, Ds5, G5, As5, A5, L4D, REST
	db L8, F5, Gs5, C6, F6, E6, Gs5, C6, E6, Ds6, REST, C6, REST, L2, REST, L8
	db B4, REST, REST, C5, D5, L4D, REST, L8, C5, REST, REST, D5, Ds5, L4, REST, L16
	db D5, Ds5, L8D, D5
	INSTR $61, $00, $40
	db L32, REST, L8T, Fs6, L2D, G6, L8, G3, Gs3, G3, Gs3, L2, G3, PAT_END
Song31_Header:
	SONG $0a, LengthTable_5C61, LengthTable_5C34, Song31_Ch1, Song31_Ch2, Song08_Ch3, 0
Song31_Ch1:
	dw Pattern_7A7D
Song31_Ch1_Loop:
	dw Pattern_7A73
	dw Pattern_7A8A
	dw Pattern_7A78
	dw Pattern_7AA4
	dw Pattern_7A73
	dw Pattern_7AB3
	dw Pattern_7A78
	dw Pattern_7ABD
	dw Pattern_7ACD
	LIST_LOOP Song31_Ch1_Loop
Song31_Ch2:
	dw Pattern_7A80
	dw Pattern_7A8A
	dw Pattern_7A85
	dw Pattern_7AA4
	dw Pattern_7A80
	dw Pattern_7AB3
	dw Pattern_7A85
	dw Pattern_7ABD
	dw Pattern_7ACD
	LIST_LOOP Song31_Ch2
Pattern_7A73:
	INSTR $42, $00, $80
	db PAT_END
Pattern_7A78:
	INSTR $24, $00, $00
	db PAT_END
Pattern_7A7D:
	db L8, REST, PAT_END
Pattern_7A80:
	INSTR $c1, $00, $80
	db PAT_END
Pattern_7A85:
	INSTR $81, $00, $00
	db PAT_END
Pattern_7A8A:
	REPEAT $02
	db L4, A2, L8, Cs3, E2, Fs2, Gs2, L4, A2, L8, E3, L4D, Cs3, L4, A2, L8
	db Cs3, E2, Fs2, Gs2, L2D, A2
	REPEAT_END
	db PAT_END
Pattern_7AA4:
	db L4, A5, L8, Cs6, L4, E6, L8, Ds6, L4, D6, L8, B5, L4D, Gs5, PAT_END
Pattern_7AB3:
	db L4, A2, L8, Cs3, E2, Fs2, Gs2, L2D, A2, PAT_END
Pattern_7ABD:
	db L8, Fs5, F5, Fs5, L4, A5, L8, B5, Cs6, C6, Cs6, L4D, Fs6, LEN14, REST, PAT_END
Pattern_7ACD:
	db L4, A4, L8, Cs5, E4, Fs4, Gs4, L2D, A4, PAT_END
Song24_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C61, Song24_Ch1, Song24_Ch2, Song24_Ch3, Song24_Ch4
Song24_Ch1:
	dw Pattern_7B04
Song24_Ch1_Loop:
	dw Pattern_7CD4
	LIST_LOOP Song24_Ch1_Loop
Song24_Ch2:
	dw Pattern_7B89
Song24_Ch2_Loop:
	dw Pattern_7D64
	LIST_LOOP Song24_Ch2_Loop
Song24_Ch3:
	dw Pattern_7C33
Song24_Ch3_Loop:
	dw Pattern_7E0F
	LIST_LOOP Song24_Ch3_Loop
Song24_Ch4:
	dw Pattern_7C98
Song24_Ch4_Loop:
	dw Pattern_7E9D
	LIST_LOOP Song24_Ch4_Loop
Pattern_7B04:
	INSTR $80, $86, $40
	REPEAT $02
	db L8, Gs4, L16, C5, L8, REST, L16, Ds5, L8D, D5
	REPEAT_END
	db L1, REST, L4, REST
	INSTR $51, $00, $80
	db L4D, Fs6, Gs6, As6, Cs7, L4, B6, L4D, Cs7, L2, B6, L4D, As6, L4, Gs6, L4D
	db As6, L2, Gs6, L1, REST, L4D, Fs5, Fs6, Fs7, LEN14, REST
	INSTR $80, $21, $41
	db L2, REST, L8D, G4, L16, G4, L8, G4, G4, A4, B4, L8D, C5, L16, C5, L8
	db C5, C5, D5, E5, L8D, F5, L16, F5, L8, F5, F5, G5, C6, LEN14, B5
	REPEAT $09
	db REST
	REPEAT_END
	db L1, REST
	TEMPO LengthTable_5C52
	INSTR $42, $83, $80
	db L1, REST, REST
	REPEAT $05
	db L4, G5, B5, D6, B5
	REPEAT_END
	db Gs5, B5, D6, B5
	REPEAT $07
	db A5, C6, E6, C6
	REPEAT_END
	db Fs5, As5, C6, D6, D7, L2D, REST
	TEMPO LengthTable_5C61
	db PAT_END
Pattern_7B89:
	INSTR $c0, $86, $00
	REPEAT $02
	db L8, F5, L16, Gs5, L8, REST, L16, C6, L8D, As5
	REPEAT_END
	db L1, REST, L4, REST
	INSTR $81, $00, $80
	db L4D, G6, A6, B6, D7, L4, C7, L4D, D7, L2, C7, L4D, B6, L4, A6, L4D
	db B6, L2, A6, L1, REST, L4D, G5, G6, G7, LEN14, REST
	INSTR $a0, $21, $80
	db L2, REST, L8D, E5, L16, E5, L8, E5, E5, F5, G5, L8D, A5, L16, A5, L8
	db A5, A5, B5, C6, L8D, D6, L16, D6, L8, D6, D6, E6, F6, LEN14, G6
	REPEAT $09
	db REST
	REPEAT_END
	db L1, REST
	TEMPO LengthTable_5C52
	INSTR $67, $00, $80
	db L2, REST, D6, E6, Fs6, A6, L4, G6, L2, A6, L2D, G6, L2, Fs6, L4, E6
	db L2, Fs6, L2D, E6, L2, D6, L4, Ds6, L2, E6, L4, D6, C6, B5, L1, C6
	db L4, Gs5, A5, C6, E6, L2, B6, L4, A6, L2, B6, L2D, A6, L2, G6, L4
	db Fs6, L2, G6, L2D, Fs6, L4, E6, D6, Fs6, L2, E6, L4, D6, Fs6, L2D, E6
	db L2, REST
	TEMPO LengthTable_5C61
	db PAT_END
Pattern_7C33:
	INSTR_WAVE Wave_5B96, $40
	CH3_FADE_ON
	REPEAT $02
	db L8, C3, L8D, Ds3, L16, G3, L8D, F3
	REPEAT_END
	db L1, REST, REST
	INSTR_WAVE Sfx3_0D_Data_5B86, $40
	db L4D, REST
	REPEAT $04
	db L4, C5, L8, E5, L4, G5, L8, E5
	REPEAT_END
	db REST, LEN14, REST, REST
	INSTR_WAVE Wave_5BC6, $20
	db L1, REST, L8D, C4, L16, C4, L8, C4, C4, D4, E4, L8D, F4, L16, F4, L8
	db F4, F4, G4, A4, L8D, As4, L16, As4, L8, As4, As4, A4, Gs4
	CH3_FADE_OFF
	db L2D, G4, L4D, G4, REST
	REPEAT $09
	db LEN14, REST
	REPEAT_END
	db L1, REST
	CH3_FADE_ON
	TEMPO LengthTable_5C52
	REPEAT $11
	db L1, REST
	REPEAT_END
	TEMPO LengthTable_5C61
	db L2D, REST, PAT_END
Pattern_7C98:
	REPEAT $02
	db L8, SFX_DRUM, L8D, SFX_DRUM, L16, SFX_DRUM, L8D, SFX_DRUM
	REPEAT_END
	db L2, REST
	REPEAT $0c
	db L2D, REST
	REPEAT_END
	REPEAT $03
	db L8D, SFX_DRUM, L16, SFX_DRUM, L8, SFX_DRUM, SFX_DRUM, SFX_DRUM, SFX_DRUM
	REPEAT_END
	REPEAT $1b
	db LEN12, NOISE5
	REPEAT_END
	REPEAT $1b
	db NOISE5
	REPEAT_END
	db L4D, REST
	REPEAT $09
	db LEN14, REST
	REPEAT_END
	db L1, REST
	TEMPO LengthTable_5C52
	REPEAT $11
	db L1, REST
	REPEAT_END
	TEMPO LengthTable_5C61
	db PAT_END
Pattern_7CD4:
	INSTR $40, $21, $40
	db L4, D5, Cs5, C5
	INSTR $67, $00, $80
	db L2, A7, L8, REST, L4D, G7, L2, Fs7, L8, REST, L4D, E7
	INSTR $10, $00, $80
	db L2, B5, D6, C6, E6
	INSTR $67, $00, $80
	db L2, B7, L8, REST, L4D, A7, L2, G7, L8, REST, L4D, Fs7
	INSTR $20, $21, $80
	db L2, C6, As5, B5, As5
	INSTR $67, $00, $80
	db L2, A7, L8, REST, L4D, G7, L2, Fs7, L8, REST, L4D, E7
	INSTR $20, $21, $80
	db L2, B5, D6, C6, E6
	INSTR $57, $00, $80
	db L2, B7, L8, REST, L4D, A7, L4D, A7, L2, A7, L8, REST
	INSTR $20, $21, $80
	db L2, C6, As5, B5, Gs5
	INSTR $47, $00, $80
	db L8, Ds7, E7, G7, F7, L4, Fs7, B7, L1, G7
	INSTR $30, $26, $80
	db L2, A4, B4, C5, Cs5, D5, E5, Fs5, G5, A4, B4, C5, Cs5, D5, D5, L4
	db REST, PAT_END
Pattern_7D64:
	INSTR $90, $26, $40
	db L4, D5, E5, Fs5, A5, L8, G5, L4, A5, L4D, G5, L4, Fs5, L8, E5, L4
	db Fs5, L4D, E5, L4, D5, L8, Ds5, L4, E5, L8, D5, C5, B4, L2, C5, L8
	db Gs4, A4, C5, E5, L4, B5, L8, A5, L4, B5, L4D, A5, L4, G5, L8, Fs5
	db L4, G5, L4D, Fs5, L8, E5, D5, Fs5, L4, E5, L8, D5, Fs5, L2, E5, L8
	db REST, Cs5, D5, E5, Fs5, L4, A5, L8, G5, L4, A5, L4D, G5, L4, Fs5, L8
	db E5, L4, Fs5, L4D, E5, L4, D5, L8, Ds5, L4, E5, L8, E5, Gs5, B5, D6
	db C6, B5, L4D, C6, L4, REST, L4, B5, L8, A5, L4, B5, L4D, A5, L4, A5
	db L8, G5, L4D, A5, L8, E5, Fs5, L4, G5, L8, E5, F5, L4, Fs5, L8, E5
	db Fs5, E5, L2D, D5, L8, REST, Ds5, E5, G5, F5, L4, Fs5, B5, G5, REST
	INSTR $70, $81, $80
	REPEAT $03
	db L8, Fs6, F6, E6, Ds6, LEN14, D6
	REPEAT_END
	db L8, A5, B5, C6, Cs6, L1, D6, L4, REST, PAT_END
Pattern_7E0F:
	REPEAT $05
	db L8, G4, D5, D4, D5
	REPEAT_END
	db E4, E5, Gs4, E5
	REPEAT $07
	db A4, E5, E4, E5
	REPEAT_END
	db D4, D5, Fs4, D5, G4, D5, D4, D5, A4, D5, D4, D5
	REPEAT $05
	db G4, D5, D4, D5
	REPEAT_END
	db E4, E5, Gs4, E5
	REPEAT $03
	db A4, E5, E4, E5
	REPEAT_END
	db C5, G5, Ds5, G5, B4, G5, D5, G5, As4, E5, Cs5, E5, A4, E5, E4, E5
	db D4, D5, A4, D5, G4, D5, D4, D5, Gs4, D5, D4, D5, A4, E5, E4, E5
	db D4, D5, A4, D5, L4, G4, L2D, G3
	REPEAT $03
	db L8, A4, E5, E4, E5
	REPEAT_END
	db D4, D5, A4, D5
	REPEAT $02
	db G4, D5, D4, D5
	REPEAT_END
	db B4, D5, D4, D5, As4, Cs5, As4, Cs5
	REPEAT $03
	db L8, A4, E5, E4, E5
	REPEAT_END
	db D4, D5, A4, D5, B4, Fs5, D5, Fs5, As4, F5, D5, F5, L4, A4, D4, D4
	db D4, PAT_END
Pattern_7E9D:
	REPEAT $03
	db L8, SFX_DRUM, L16, NOISE4, NOISE4
	REPEAT_END
	REPEAT $20
	db L16, NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	REPEAT $24
	db NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	db L4, SFX_DRUM, L2D, SFX_DRUM
	REPEAT $1c
	db L16, NOISE4, NOISE4, NOISE5, NOISE4
	REPEAT_END
	db L8, SFX_DRUM, L16, NOISE4, NOISE4, PAT_END
Song40_Header:
	SONG $00, LengthTable_5C61, LengthTable_5C43, Song08_Ch3, Song40_Ch2, Song40_Ch3, Song40_Ch4
Song40_Ch2:
	dw Pattern_7EE5
	LIST_LOOP Song40_Ch2
Song40_Ch3:
	dw Pattern_7F25
	LIST_LOOP Song40_Ch3
Song40_Ch4:
	dw Pattern_7F42
	LIST_LOOP Song40_Ch4
Pattern_7EE5:
	INSTR $a1, $82, $80
	db L8D, D5, Fs5, A5, REST, L2D, REST, L8D, D5, Fs5, A5, Gs5, G5, L8, E5, L4
	db Cs5, L8D, REST, LEN14, REST, REST, L8D, D5, Fs5, A5, D6, C6, A5, F5, L8, G5
	db L4, A5, L8D, REST, L4D, REST, LEN14, REST, L2D, REST, L8D, A3, Cs4, E4, REST, L2D
	db REST, L8D, G3, B3, D4, REST, L2D, REST, LEN14, REST, REST, PAT_END
Pattern_7F25:
	INSTR_WAVE Wave_5B96, $20
	DROP_ON
	REPEAT $02
	db L32, E3, L8T, REST, L8, REST
	REPEAT_END
	db L2, REST, L32, E3, L8T, REST, L32, E3, L8T, REST, L8, REST, L4D, REST, PAT_END
Pattern_7F42:
	REPEAT $02
	db L8, NOISE4, L16, NOISE4
	REPEAT_END
	db L8, SFX_DRUM, L16, NOISE4, L8, NOISE4, L16, NOISE5, PAT_END
Song08_Ch3:
	dw Pattern_7F58
	LIST_LOOP Song08_Ch3
Pattern_7F58:
	REPEAT $20
	db L1, REST
	REPEAT_END
	db PAT_END
