; Link's Awakening DX music, bank $1B: songs, bank $1B $5000-$7FFF

Song38_Header:
	SONG $00, LengthTable_4AE6, Song04_Ch3, Song04_Ch3, Song38_Ch3, 0
Song38_Ch3:
	dw Pattern_500F
	LIST_END
Pattern_500F:
	INSTR_WAVE Wave_6F01, $01
	CH3_FADEIN_ON
	db L4, C5, L8, D5, L4, E5, L8, D5, L4D, C5, G5, E5, C6, L2D, G5, L4
	db G5, L8, Gs5, L4, G5, L8, Fs5, L2D, Ds5, L4D, D5, G5, L2D, C5
	CH3_FADEOUT_OFF
	db PAT_END
Song01_Header:
	SONG $00, LengthTable_4AC8, Song01_Ch1, Song01_Ch2, Song01_Ch3, 0
Song01_Ch1:
	dw Pattern_706B
Song01_Ch1_Loop:
	dw Pattern_505B
	LIST_LOOP Song01_Ch1_Loop
Song01_Ch2:
	dw Pattern_50AB
Song01_Ch2_Loop:
	dw Pattern_50D9
	LIST_LOOP Song01_Ch2_Loop
Song01_Ch3:
	dw Pattern_6F60
	dw Pattern_513C
Song01_Ch3_Loop:
	dw Pattern_6F41
	dw Pattern_517E
	LIST_LOOP Song01_Ch3_Loop
Pattern_505B:
	INSTR $66, $81, $80
	db L1, REST, L8, REST, As5, L16, As5, C6, D6, Ds6, L4, F6, REST, REST, L16, Cs6
	db Fs6, Gs6, As6, L4, Cs7, REST, L4D, REST, L16, Cs6, Ds6, L8, F6, Cs6, L4, Gs5
	db L4D, REST
	REPEAT $02
	db L16, Ds6, F6, L8, Fs6
	REPEAT_END
	db REST, L4D, REST
	REPEAT $02
	db L16, Cs6, Ds6, L8, F6
	REPEAT_END
	db REST, L4D, REST, L16, C6, D6, L8, E6, L16, E6, F6, G6, A6, As6, C7, L8
	db A6, REST, L2D, REST, L1, REST, PAT_END
Pattern_50AB:
	INSTR $a0, $84, $80
	db L2, As4, L8, REST, As4, As4, L16, As4, As4
	REPEAT $02
	db L8D, As4, L16, Gs4, L4, As4, L8, REST, As4, As4, L16, As4, As4
	REPEAT_END
	db L8, As4, L16, F4, F4
	REPEAT $02
	db L8, F4, L16, F4, F4
	REPEAT_END
	db L8, F4, F4, PAT_END
Pattern_50D9:
	INSTR $80, $21, $40
	db L8, As4, REST, L4D, F4, L16, REST, As4, As4, C5, D5, Ds5, L2, F5, L8, REST
	db F5, F5, L16, Fs5, Gs5, L2, As5, L8, REST, As5, As5, L16, Gs5, Fs5, L8D, Gs5
	db L16, Fs5, L2, F5, L4, F5, L8D, Ds5, L16, F5, L2, Fs5, L8, F5, Ds5, L8D
	db Cs5, L16, Ds5, L2, F5, L8, Ds5, Cs5, L8D, C5, L16, D5, L2, E5, L4, G5
	INSTR $60, $81, $80
	db L8, F5, L16, As4, As4, L8, As4, L16, As4, As4, L4, As4, REST, L8, REST, L16
	db A4, A4, L8, A4, L16, A4, A4, L4, A4, REST, PAT_END
Pattern_513C:
	CH3_FADEOUT_ON
	db L4, D5, L8, REST, L16, As3, As3, L8, As3, D5, D5, L16, D5, D5, L8D, C5
	db L16, C5, L8, C5, L16, Gs3, Gs3, L8, Gs3, C5, C5, L16, C5, C5, L8D, Cs5
	db L16, Cs5, L8, Cs5, L16, Fs3, Fs3, L8, Fs3, Cs5, Cs5, L16, Cs5, Cs5, L8, Cs5
	db L16, A4, A4
	REPEAT $02
	db L8, A4, L16, A4, A4
	REPEAT_END
	db L8, F3, L16, G3, A3, PAT_END
Pattern_517E:
	CH3_FADEOUT_ON
	REPEAT $02
	db L8, As3, L4, As4, L8, As4
	REPEAT_END
	REPEAT $02
	db L8, Gs3, L4, Gs4, L8, Gs4
	REPEAT_END
	REPEAT $02
	db L8, Fs3, L4, Fs4, L8, Fs4
	REPEAT_END
	REPEAT $02
	db L8, Cs4, L4, Cs5, L8, Cs5
	REPEAT_END
	REPEAT $02
	db L8, B3, L4, B4, L8, B4
	REPEAT_END
	REPEAT $02
	db L8, As3, L4, As4, L8, As4
	REPEAT_END
	db L8, C4, L4, C5, L8, C5, C4, C5, As5, C4, F4
	REPEAT $02
	db L16, Ds5, Ds5, L8, Ds5
	REPEAT_END
	db L16, C4, C4, L8, C4, L16, C4, C4, L8, F4
	REPEAT $02
	db L16, Ds5, Ds5, L8, Ds5
	REPEAT_END
	db L16, F3, F3, F3, Fs3, G3, A3, PAT_END
Song02_Header:
	SONG $00, LengthTable_4AAA, Song02_Ch1, Song02_Ch2, Song02_Ch3, 0
Song02_Ch1:
	dw Pattern_6F7A
	dw Pattern_7024
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_6F7F
	dw Pattern_702A
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_5241
	dw Pattern_524B
	LIST_LOOP Song02_Ch1
Song02_Ch2:
	dw Pattern_6F84
	dw Pattern_7024
	dw Pattern_5255
	dw Pattern_525D
	dw Pattern_6F89
	dw Pattern_702A
	dw Pattern_525D
	dw Pattern_527A
	LIST_LOOP Song02_Ch2
Song02_Ch3:
	dw Pattern_6F5B
	dw Pattern_7024
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_6F41
	dw Pattern_702A
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_527D
	dw Pattern_5288
	LIST_LOOP Song02_Ch3
Pattern_5241:
	db L4D, E3, L8, E3, L4, F3, E3, D3, B2, PAT_END
Pattern_524B:
	db L4D, E3, L8, E3, L4, F3, E3, D3, REST, PAT_END
Pattern_5255:
	REPEAT $03
	db L2D, REST
	REPEAT_END
	db L2, REST, PAT_END
Pattern_525D:
	REPEAT $02
	db L16, REST, G4, Gs4, A4, L4D, As4, L8, E4, L2, As4, L16, REST, A4, As4, A4
	db L8, G4, F4, L4D, G4, L8, C4, L2D, G4
	REPEAT_END
	db PAT_END
Pattern_527A:
	db L4, REST, PAT_END
Pattern_527D:
	CH3_FADEOUT_ON
	db L4D, C4, L8, C4, L4, Cs4, C4, As3, G3, PAT_END
Pattern_5288:
	CH3_FADEOUT_ON
	db L4D, C4, L8, C4, L4, Cs4, C4, As3, REST, PAT_END
Song03_Header:
	SONG $00, LengthTable_4AE6, Song03_Ch1, Song03_Ch2, Song03_Ch3, 0
Song03_Ch1:
	dw Pattern_52EB
	LIST_LOOP Song03_Ch1
Song03_Ch2:
	dw Pattern_52B6
	dw Pattern_52BB
	LIST_LOOP Song03_Ch2
Song03_Ch3:
	dw Pattern_707A
Song03_Ch3_Loop:
	dw Pattern_5327
	dw Pattern_52BB
	LIST_LOOP Song03_Ch3_Loop
Pattern_52B6:
	INSTR $57, $00, $80
	db PAT_END
Pattern_52BB:
	db L8, B6, Cs7, L4, D7, REST, REST, L8, B6, Cs7, L4, D7, REST, REST, L8, Cs7
	db B6, Fs6, L4D, A6, L4, B6, REST, L2D, REST, L8, B6, Cs7, L4, D7, REST, REST
	db L8, B6, D7, L4, G7, REST, REST, L8, Fs7, E7, L2, Fs7, REST, L2D, REST, PAT_END
Pattern_52EB:
	INSTR $37, $00, $80
	db L4D, REST
	REPEAT $02
	db L8, G4, D5, G5, A5, L4, B5, REST
	REPEAT_END
	db L8, B4, Fs5, A5, E6, L4, Fs6, REST, L8, B4, Fs5, A5, Fs5, A4, Fs5, A5
	db Fs5
	REPEAT $02
	db L8, G4, D5, G5, A5, L4, B5, REST
	REPEAT_END
	db L8, D4, A4, Cs5, E5, Fs5, A5, Cs6, E6, Fs6, E6, Fs6, A6, A7, PAT_END
Pattern_5327:
	INSTR_WAVE Wave_6F21, $20
	db PAT_END
Song04_Header:
	SONG $00, LengthTable_4AF5, Song04_Ch1, Song04_Ch2, Song04_Ch3, 0
Song04_Ch1:
	dw Pattern_5343
	LIST_LOOP Song04_Ch1
Song04_Ch2:
	dw Pattern_53A5
	LIST_LOOP Song04_Ch2
Pattern_5343:
	INSTR $52, $00, $80
	CH3_FADEOUT_ON
	REPEAT $02
	db L8, G4, D5
	REPEAT_END
	REPEAT $02
	db G4, E5
	REPEAT_END
	REPEAT $02
	db G4, Fs5
	REPEAT_END
	REPEAT $02
	db G4, E5
	REPEAT_END
	REPEAT $02
	db G4, D5
	REPEAT_END
	REPEAT $02
	db G4, Ds5
	REPEAT_END
	REPEAT $02
	db A4, E5
	REPEAT_END
	db D5, D4, E4, D4
	REPEAT $02
	db C4, G4
	REPEAT_END
	REPEAT $02
	db C4, A4
	REPEAT_END
	REPEAT $02
	db B3, A4
	REPEAT_END
	REPEAT $02
	db E4, B4
	REPEAT_END
	REPEAT $02
	db A3, E4
	REPEAT_END
	db A3, Ds4, D4, C4
	INSTR $40, $00, $80
	db L2, D4, C4
	TEMPO LengthTable_4B04
	db L2, B3, L4D, A3
	INSTR $52, $00, $80
	db L8, D4
	TEMPO LengthTable_4AF5
	db PAT_END
Pattern_53A5:
	INSTR $56, $00, $80
	db L4, D6, G5, L4D, A5, L16, B5, C6, L8, D6, D6, G5, G5, L4D, A5, L16
	db B5, C6, L8, B5, D6, L4D, A6, L8, G6, A6, G6, D6, L16, C6, B5, L4
	db A5
	INSTR $42, $00, $80
	db Fs5
	INSTR $56, $00, $80
	db L16, REST, B5, C6, D6, L4, E6, G5, L4D, Fs5, L16, A5, E6, L8, D6, D6
	db Fs5, Fs5, L4D, G5, L16, G5, Fs5, L8, E5, G5, L4D, B5, L8, A5, G5, Ds5
	REPEAT $04
	db D5, D6
	REPEAT_END
	TEMPO LengthTable_4B04
	REPEAT $04
	db L8, D6, D7
	REPEAT_END
	TEMPO LengthTable_4AF5
	db PAT_END
Song05_Header:
	SONG $00, LengthTable_4AC8, Song05_Ch1, Song05_Ch2, Song05_Ch3, 0
Song05_Ch1:
	dw Pattern_5446
Song05_Ch1_Loop:
	dw Pattern_5471
	dw Pattern_54BC
	dw Pattern_5471
	dw Pattern_54E9
	LIST_LOOP Song05_Ch1_Loop
Song05_Ch2:
	dw Pattern_5562
Song05_Ch2_Loop:
	dw Pattern_558F
	dw Pattern_55C4
	dw Pattern_558F
	dw Pattern_55E8
	LIST_LOOP Song05_Ch2_Loop
Song05_Ch3:
	dw Pattern_6F41
	dw Pattern_5664
Song05_Ch3_Loop:
	dw Pattern_6F41
	dw Pattern_568D
	dw Pattern_56AF
	dw Pattern_568D
	dw Pattern_56DD
	dw Pattern_6F46
	dw Pattern_56EA
	dw Pattern_6F41
	dw Pattern_56F7
	LIST_LOOP Song05_Ch3_Loop
Pattern_5446:
	INSTR $45, $00, $80
	db L4, B3, LEN10, B3, B3, B3, L4, A3, LEN10, A3, B3, C4, L4, Ds4, LEN10, Ds4
	db Ds4, Ds4, L4, F4, LEN10, F4, F4, F4
	INSTR $40, $21, $81
	db L2D, G4, LEN10, F4, F4, F4, L2D, G4, L4, REST, PAT_END
Pattern_5471:
	INSTR $45, $00, $80
	db L4, B3, LEN10, C4, B3, A3, L8D, B3, L16, B3, B3, C4, D4, E4, L8D, F4
	db L16, G4, G4, A4, B4, C5, L4, D5, LEN10, F4, G4, A4, L8D, As4, L16, Ds4
	db Ds4, F4, G4, A4, LEN10, As4, REST, As4, As4, A4, G4, As4, REST, F4, F4, F4
	db Ds4, F4, REST, F4, F4, Ds4, F4, L8, Ds4, L16, Ds4, D4, L8, Ds4, L16, Ds4
	db F4, L4, G4, L8, F4, Ds4, PAT_END
Pattern_54BC:
	db L8, D4, L16, D4, C4, L8, D4, L16, D4, Ds4, L4, F4, L8, Ds4, D4, L4
	db Cs4, L8, Cs4, L16, Cs4, D4, L8, E4, L16, E4, F4, G4, A4, As4, C5, L4
	db A4
	INSTR $40, $21, $41
	db LEN10, C4, C4, C4, L4, D4, REST, PAT_END
Pattern_54E9:
	INSTR $45, $00, $80
	db LEN10, D4, Cs4, D4, Fs4, G4, A4, As4, REST, As4, As4, A4, G4
	INSTR $70, $21, $80
	db L8D, D5, As4, L8, G4, L4, Fs4, LEN10, Fs4, E4, Fs4, LEN10, G4, A4, As4, C5
	db As4, A4, L4, As4, REST
	INSTR $50, $21, $81
	db L4, As4, L4D, G4, L16, REST, As4, As4, C5, D5, Ds5, LEN10, C5, REST, As4, L2
	db A4, L4, F4, LEN10, G4, REST, D4, L4, D4, C4, E4, L8, G4, L16, G4, Fs4
	db G4, A4, As4, C5, L2, D5, LEN10, D5, REST, C5, L2, As4, L4, REST, LEN10, C5
	db REST, Ds5, L2, Gs5, L4, REST, REST, LEN10, G4, G4, G4, L4, G4, REST
	INSTR $40, $21, $40
	db REST, LEN10, C5, C5, C5, L4, D5, REST, PAT_END
Pattern_5562:
	INSTR $55, $00, $80
	db L4, G4, LEN10, G4, D4, G4, L4, F4, LEN10, F4, G4, A4, L4, As4, LEN10, As4
	db G4, As4, L4, A4, LEN10, A4, As4, C5
	INSTR $50, $21, $81
	db L2D, D5, LEN10, C5, C5, C5, L2D, D5, LEN10, C5, B4, A4, PAT_END
Pattern_558F:
	INSTR $65, $00, $80
	db L4, G4, L4D, D4, L16, REST, G4, G4, A4, B4, C5, L2, D5, LEN10, REST, REST
	db D5, D5, Ds5, F5, L2, G5, LEN10, REST, REST, G5, G5, F5, Ds5, F5, REST, Ds5
	db L2, D5, LEN10, D5, Ds5, D5, L8, C5, L16, C5, D5, L2, Ds5, L8, D5, C5
	db PAT_END
Pattern_55C4:
	db L8, As4, L16, As4, C5, L2, D5, L8, C5, As4, A4, L16, A4, B4, L2, Cs5
	db L4, E5, L8, D5
	INSTR $60, $21, $01
	db LEN13, D4, D4, D4, LEN10, E4, E4, E4, L4, Fs4, REST, PAT_END
Pattern_55E8:
	INSTR $45, $00, $80
	db LEN10, As4, A4, As4, C5, As4, C5, D5, REST, D5, D5, C5, As4
	INSTR $40, $00, $81
	db L2, D5, D6, L2D, G5
	INSTR $70, $21, $41
	db LEN10, D5, Ds5, F5, L4, G5, L4D, D5, L16, REST, G5, G5, A5, As5, C6, LEN10
	db A5, REST, F5, L4D, C5, L16, C5, D5, F5, Ds5, D5, C5, LEN10, D5, REST, G4
	db L4D, G4, L16, G4, Fs4, G4, A4, As4, C5, L2, D5, L4, REST, LEN10, D5, C5
	db D5, LEN10, As5, REST, A5, L4, G5, LEN10, REST, D5, D5, D5, As4, G5, Gs5, REST
	db As5, L4, C6, LEN10, REST, C6, D6, Ds6, F6, Ds6, L1, D6
	INSTR $40, $21, $40
	db L8, REST, LEN13, D5, D5, D5, LEN10, E5, E5, E5, L4, Fs5, REST, PAT_END
Pattern_5664:
	CH3_FADEOUT_ON
	db L4, G4, LEN10, G4, G4, G4, L4, F4, LEN10, F4, F4, F4, L4, Ds4, LEN10, Ds4
	db Ds4, Ds4, F4, F4, F4, F4, Ds4, F4
	REPEAT $02
	db L4, G4, LEN10, G4, G4, G4, L4, G4, LEN10, D4, D4, D4
	REPEAT_END
	db PAT_END
Pattern_568D:
	db L4, G3, LEN10, G3, G3, F3, L4, G3, G3, F3, LEN10, F3, F3, Ds3, L4, F3
	db F3, Ds3, LEN10, Ds3, Ds3, D3, L4, Ds3, Ds3, As3, LEN10, As3, As3, Gs3, L4, As3
	db As3, PAT_END
Pattern_56AF:
	db Gs3, LEN10, Gs3, Gs3, G3, L4, Gs3, LEN10, Gs3, Gs3, Gs3, L4, G3, LEN10, G3, G3
	db F3, L4, G3, LEN10, G3, G3, G3
	REPEAT $02
	db L4, A3, LEN10, A3, A3, A3
	REPEAT_END
	db L4, D4, LEN10, G4, G4, G4
	CH3_FADEOUT_OFF
	db L4, A4
	CH3_FADEOUT_ON
	db L8, E3, Fs3, PAT_END
Pattern_56DD:
	db L4, Gs3, LEN10, Gs4, Gs4, G4, L4, Gs4, LEN10, Gs4, Gs4, Gs4, PAT_END
Pattern_56EA:
	CH3_FADEOUT_OFF
	db L4, G4, Fs4, L2, F4, L4, E4, C4
	CH3_FADEOUT_ON
	db L4, D4, PAT_END
Pattern_56F7:
	db LEN10, D4, D5, C5, As4, A4, G4, L4, A4, G4, REST, Ds3, LEN10, Ds4, G4, As4
	db L4, Ds5, LEN10, Ds3, Ds3, Ds3, L4, D3, LEN10, D4, F4, A4, L4, D5, LEN10, D4
	db D4, D4
	REPEAT $03
	db L4, G3, LEN10, G3, G3, G3
	REPEAT_END
	db L8D, G3, G3, L8, F3, L4, Ds3, LEN10, Ds3, G3, As3, L4, Ds4, LEN10, Ds3, Ds3
	db Ds3, L4, Gs3, LEN10, Gs3, C4, Ds4, L4, Gs4, LEN10, Gs3, Gs3, Gs3, L4, D3, LEN10
	db C5, C5, C5, L4, C5, LEN10, D3, D3, D3, L4, D3, LEN10, G5, G5, G5, A5
	db Ds4, D4, C4, As3, A3, PAT_END
Song06_Header:
	SONG $00, LengthTable_4AC8, Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song06_Ch1:
	dw Pattern_6F98
	dw Pattern_57D3
	dw Pattern_57D3
Song06_Ch1_Loop:
	dw Pattern_6F98
	dw Pattern_57F8
	dw Pattern_5816
	dw Pattern_6F98
	dw Pattern_57F8
	dw Pattern_7027
	dw Pattern_6F7A
	dw Pattern_57F8
	dw Pattern_6F9D
	dw Pattern_57F8
	dw Pattern_5816
	dw Pattern_7024
	dw Pattern_7061
	dw Pattern_6F98
	dw Pattern_57F8
	dw Pattern_57F8
	LIST_LOOP Song06_Ch1_Loop
Song06_Ch2:
	dw Pattern_706B
	dw Pattern_586F
Song06_Ch2_Loop:
	dw Pattern_6FA2
	dw Pattern_588E
	dw Pattern_706B
	dw Pattern_706B
	dw Pattern_6FA7
	dw Pattern_588E
	dw Pattern_7061
	dw Pattern_706B
	dw Pattern_591B
	LIST_LOOP Song06_Ch2_Loop
Song06_Ch3:
	dw Pattern_6F55
	dw Pattern_5926
Song06_Ch3_Loop:
	dw Pattern_6F6B
	dw Pattern_5933
	dw Pattern_597F
	dw Pattern_706B
	dw Pattern_7071
	dw Pattern_7061
	dw Pattern_597F
	dw Pattern_7061
	dw Pattern_706B
	dw Pattern_706B
	LIST_LOOP Song06_Ch3_Loop
Song06_Ch4:
	dw Pattern_5994
Song06_Ch4_Loop:
	dw Pattern_59A1
	dw Pattern_59B8
	dw Pattern_59C2
	dw Pattern_59B8
	dw Pattern_59D9
	LIST_LOOP Song06_Ch4_Loop
Pattern_57D3:
	INSTR $33, $00, $80
	REPEAT $04
	db L8, D5, L16, D5, D5
	REPEAT_END
	REPEAT $04
	db L8, E5, L16, E5, E5
	REPEAT_END
	REPEAT $04
	db L8, F5, L16, F5, F5
	REPEAT_END
	REPEAT $04
	db L8, E5, L16, E5, E5
	REPEAT_END
	db PAT_END
Pattern_57F8:
	REPEAT $04
	db L16, G3, D4, As3, D4
	REPEAT_END
	REPEAT $04
	db G3, E4, C4, E4
	REPEAT_END
	REPEAT $04
	db G3, F4, D4, F4
	REPEAT_END
	REPEAT $04
	db G3, E4, C4, E4
	REPEAT_END
	db PAT_END
Pattern_5816:
	REPEAT $04
	db Ds3, D4, As3, D4
	REPEAT_END
	REPEAT $04
	db F3, C4, A3, C4
	REPEAT_END
	REPEAT $02
	db F3, D4, As3, D4
	REPEAT_END
	REPEAT $02
	db G3, E4, C4, E4
	REPEAT_END
	REPEAT $04
	db A3, Fs4, D4, Fs4
	REPEAT_END
	REPEAT $04
	db G3, D4, As3, D4
	REPEAT_END
	REPEAT $04
	db Gs3, Ds4, C4, Ds4
	REPEAT_END
	REPEAT $04
	db G3, D4, As3, D4
	REPEAT_END
	REPEAT $04
	db E3, D4, As3, D4
	REPEAT_END
	REPEAT $04
	db Gs3, Ds4, C4, Ds4
	REPEAT_END
	db L16, D4, G4, A4, C5, L4, D5, L2, REST
	INSTR $50, $26, $01
	db L2, D5, C5, As4, C5, PAT_END
Pattern_586F:
	INSTR $40, $26, $41
	db L4, G4, L4D, D4, L8, G4, L16, G4, A4, As4, C5, L1, D5, L4, G5, L4D
	db D5, L8, G5, L16, G5, A5, As5, C6, L1, D6, PAT_END
Pattern_588E:
	db L8D, G4, L16, D4, L4D, D4, L8, G4, L16, G4, A4, As4, C5, L4D, D5, L16
	db E5, F5, L8D, E5, D5, L8, C5, L8D, D5, L16, G4, L1, G5, L8, REST, D5
	db As5, A5, As5, C6, D6, L16, G5, D6, L4, G6, L8, REST, D6, C6, As5, C6
	db L16, F5, C6, L4, F6, L8, REST, C6, As5, A5, L8D, As5, L16, D5, L4, D5
	db L8, REST, LEN13, C5, D5, C5, L8, As4, C5, L1, D5, L8D, G4, L16, D4, L4D
	db D4, L8, G4, L16, G4, A4, As4, C5, L4D, D5, L16, Ds5, F5, L8D, Ds5, D5
	db L8, C5, L8D, As4, L16, G4, L4D, D5, L8, As4, G5, D5, L4D, As5, L8, A5
	db G5, A5, As5, C6, L8, D6, L16, C6, D6, L4, Ds6, L8, REST, L8D, F6, Ds6
	db D6, A5, L8, As5, L8D, C6, As5, L8, A5, L1, G5, G6, PAT_END
Pattern_591B:
	INSTR $56, $00, $80
	REPEAT $04
	db L2, REST, A7
	REPEAT_END
	db PAT_END
Pattern_5926:
	REPEAT $1f
	db L8, G4, L16, G4, G4
	REPEAT_END
	db REST, C3, As2, A2, PAT_END
Pattern_5933:
	CH3_FADEOUT_ON
	REPEAT $02
	db L4, G3, L2, G3, L4, G3
	REPEAT_END
	db G3, L2, G3, L4, D4, C4, L2, C4, L8, C4, D4, L4, Ds4, L2, Ds4, L4
	db Ds4, F4, L2, F4, L4, F4, As3, As3, C4, C4, D4, L2, D4, L16, D4, C4
	db As3, A3, L4, G3, L2, G3, L4, G3, Gs3, L2, Gs3, L4, Gs3, G3, L2, G3
	db L4, F3, E3, L2, E3, L4, E3, Gs3, L2, Gs3, L4, Gs3, D4, REST, REST
	CH3_FADEOUT_OFF
	db D3, PAT_END
Pattern_597F:
	db L8D, G3, D4, L8, G3, L8D, F3, C4, L8, F3, L8D, Ds3, As3, L8, Ds3, L8D
	db F3, C4, L8, F3, PAT_END
Pattern_5994:
	REPEAT $1f
	db L8, NOISE_0B, L16, NOISE_0B, NOISE_0B
	REPEAT_END
	db NOISE_15, NOISE_15, NOISE_15, NOISE_15, PAT_END
Pattern_59A1:
	REPEAT $0d
	db L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, NOISE_15
	db NOISE_15, NOISE_15, NOISE_15
	REPEAT_END
	db PAT_END
Pattern_59B8:
	db L16, NOISE_15, NOISE_15, NOISE_15, NOISE_15, L4, NOISE_15, L2, REST, PAT_END
Pattern_59C2:
	REPEAT $17
	db L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, NOISE_15
	db NOISE_15, NOISE_15, NOISE_15
	REPEAT_END
	db PAT_END
Pattern_59D9:
	REPEAT $0c
	db L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, L8, NOISE_15, L16, NOISE_15, NOISE_15, NOISE_15
	db NOISE_15, NOISE_15, NOISE_15
	REPEAT_END
	db PAT_END
Song07_Header:
	SONG $00, LengthTable_4B04, Song07_Ch1, Song07_Ch2, Song07_Ch3, 0
Song07_Ch1:
	dw Pattern_5A0F
	LIST_LOOP Song07_Ch1
Song07_Ch2:
	dw Pattern_5A3F
	LIST_LOOP Song07_Ch2
Song07_Ch3:
	dw Pattern_6F46
	dw Pattern_5A7A
	LIST_LOOP Song07_Ch3
Pattern_5A0F:
	INSTR $44, $00, $80
	DROP_OFF
	REPEAT $02
	db L4, REST, L8, As4, L16, G7, G7, L4, REST, L8, A4, L16, G7, G7
	REPEAT_END
	INSTR $24, $00, $80
	db L4, REST, L8, Cs6, C6, B5, Cs6, As5, B5, A5, B5, Gs5, A5, G5, Fs5, L2
	db REST
	DROP_ON
	db L16, G7, G7, PAT_END
Pattern_5A3F:
	INSTR $50, $84, $00
	db L8D, G6, L16, D6, L8, B5, G5, L4, Gs5, L16, Ds6, C6, Gs5, Ds5, L8, D5
	db L16, D6, B5, L8, G5, D5, F5, L16, Ds5, F5, L4, D5
	INSTR $24, $00, $00
	db L8, Cs5, D5, Ds6, D6, Cs6, D6, C6, Cs6, B5, C6, As5, B5, L16, A5, As5
	db Gs5, A5, L4, REST, L4D, REST, PAT_END
Pattern_5A7A:
	REPEAT $02
	CH3_FADEOUT_ON
	db L8, G4, Cs5, Fs5, Cs5, D4, C5, F5, C5
	REPEAT_END
	db L1, REST, REST, L4D, REST, PAT_END
Song08_Header:
	SONG $00, LengthTable_4AD7, Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
Song08_Ch1:
	dw Pattern_702A
	dw Pattern_705E
	dw Pattern_6FB1
	dw Pattern_5AF9
	dw Pattern_6FAC
	dw Pattern_5AF9
	dw Pattern_7024
	dw Pattern_5AE0
	dw Pattern_702A
	dw Pattern_5AE0
	dw Pattern_7061
	LIST_LOOP Song08_Ch1
Song08_Ch2:
	dw Pattern_6FB1
	dw Pattern_5B21
	dw Pattern_6FAC
	dw Pattern_5B28
	dw Pattern_5B00
	dw Pattern_5B00
	dw Pattern_7061
	LIST_LOOP Song08_Ch2
Song08_Ch3:
	dw Pattern_6F41
	dw Pattern_7061
	dw Pattern_5B2F
	dw Pattern_5B45
	dw Pattern_5B2F
	dw Pattern_5B45
	dw Pattern_7061
	LIST_LOOP Song08_Ch3
Song08_Ch4:
	dw Pattern_5B68
	dw Pattern_5B5A
	dw Pattern_5B68
	LIST_LOOP Song08_Ch4
Pattern_5AE0:
	INSTR $33, $00, $80
	REPEAT $04
	db L16, G5, Fs5, F5, E5, Ds5, D5, Cs5, C5, B4, C5, Cs5, D5, Ds5, E5, F5
	db Fs5
	REPEAT_END
	db PAT_END
Pattern_5AF9:
	REPEAT $04
	db L16, As4, A4
	REPEAT_END
	db PAT_END
Pattern_5B00:
	INSTR $40, $81, $80
	db L4D, G5, L8, D5, G5, A5, B5, D6, L4D, Cs6, L8, D6, L2, Ds6, L4D, G5
	db L8, D5, G5, A5, B5, D6, L4D, Cs6, L8, D6, L2, Ds7, PAT_END
Pattern_5B21:
	REPEAT $0c
	db L16, G5, Fs5
	REPEAT_END
	db PAT_END
Pattern_5B28:
	REPEAT $04
	db L16, G5, Fs5
	REPEAT_END
	db PAT_END
Pattern_5B2F:
	CH3_FADEOUT_ON
	db L4, G3, L8, D4, L4, G3, L8, G3, Gs3, Ds4, L4, G3, L8, D4, L4, G3
	db L8, G3, F3, Fs3, PAT_END
Pattern_5B45:
	db L4, G3, L8, D4, L4, G3, L8, G3, Gs3, Ds4, L4, G3, L8, D4, L4, G3
	db L8, G3, D4, G4, PAT_END
Pattern_5B5A:
	REPEAT $08
	db L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L4, DRUM, L8, NOISE_29, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_5B68:
	db L4, NOISE_29, L8, NOISE_29, NOISE_29, L4, DRUM, L8, NOISE_29, NOISE_29, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L4
	db DRUM, L8, NOISE_29, NOISE_29, PAT_END
Song09_Header:
	SONG $00, LengthTable_4B04, Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
Song09_Ch1:
	dw Pattern_7061
Song09_Ch1_Loop:
	dw Pattern_5BAE
	dw Pattern_5BAE
	dw Pattern_5BBE
	LIST_LOOP Song09_Ch1_Loop
Song09_Ch2:
	dw Pattern_5BD3
Song09_Ch2_Loop:
	dw Pattern_5BF4
	LIST_LOOP Song09_Ch2_Loop
Song09_Ch3:
	dw Pattern_7061
Song09_Ch3_Loop:
	dw Pattern_6F6B
	dw Pattern_5C26
	dw Pattern_5C44
	LIST_LOOP Song09_Ch3_Loop
Song09_Ch4:
	dw Pattern_5C61
	LIST_LOOP Song09_Ch4
Pattern_5BAE:
	INSTR $23, $00, $80
	REPEAT $20
	db L32, As5, C6
	REPEAT_END
	REPEAT $20
	db C6, Cs6
	REPEAT_END
	db PAT_END
Pattern_5BBE:
	REPEAT $20
	db As5, F5
	REPEAT_END
	REPEAT $20
	db A5, E5
	REPEAT_END
	REPEAT $20
	db As5, Ds5
	REPEAT_END
	REPEAT $20
	db A5, E5
	REPEAT_END
	db PAT_END
Pattern_5BD3:
	INSTR $81, $82, $00
	db L8, G2, D3, L16, F3, L8, Fs3, L16, G3, L4D, REST, L16, F2, Fs2, L8, G2
	db L16, D3, L8, F3, Fs3, L16, G3, L4D, REST, L16, F2, Fs2, PAT_END
Pattern_5BF4:
	INSTR $40, $00, $81
	REPEAT $02
	db L2, G5, D5, L2D, D5, L32, G5, Fs5, G5, A5, As5, A5, As5, C6, L8D, D6
	db Ds6, L8, F6, L2D, G6, L8, G6, F6, L8D, Ds6, C6, L8, Gs5
	REPEAT_END
	INSTR $30, $00, $01
	db L1, G5, D5, Ds5, E5, F5, F5, Fs5, Fs5, PAT_END
Pattern_5C26:
	CH3_FADEOUT_ON
	db L8, G3, D4, L16, F4, L8, Fs4, L16, G4, L4D, REST, L16, F3, Fs3, L8, G3
	db L16, D4, L8, F4, Fs4, L16, G4, L4D, REST, L16, Fs3, G3, PAT_END
Pattern_5C44:
	db L8, Gs3, Ds4, L16, Fs4, L8, G4, L16, Gs4, L4D, REST, L16, Fs3, G3, L8, Gs3
	db L16, Ds4, L8, Fs4, G4, L16, Gs4, L4D, REST, L16, F3, Fs3, PAT_END
Pattern_5C61:
	REPEAT $04
	db L16, NOISE_29
	REPEAT_END
	db DRUM
	REPEAT $05
	db NOISE_29
	REPEAT_END
	db DRUM
	REPEAT $05
	db NOISE_29
	REPEAT_END
	db PAT_END
Song0A_Header:
	SONG $04, LengthTable_4AE6, Song0A_Ch1, Song0A_Ch2, Song04_Ch3, 0
Song0A_Ch1:
	dw Pattern_702D
	dw Pattern_707A
Song0A_Ch1_Loop:
	dw Pattern_5C8E
	LIST_LOOP Song0A_Ch1_Loop
Song0A_Ch2:
	dw Pattern_7032
	dw Pattern_5C8E
	LIST_LOOP Song0A_Ch2
Pattern_5C8E:
	db L8, A5, F4, C5, E5, G5, A5, As5, G4, D5, F5, A5, As5, C6, A4, E5
	db G5, G6, F6, C6, D4, A4, C5, As5, A5, A5, G4, D5, F5, G5, A5, As5
	db G4, Cs5, F5, A5, As5, G5, C4, G4, As4, Cs5, F5, E5, C5, D5, E5, F5
	db G5, A5, F4, C5, E5, G5, A5, As5, G4, D5, F5, A5, As5, C6, A4, E5
	db G5, A6, G6, G6, D4, A4, Fs6, Ds6, D6, C6, G4, D5, F5, As5, A5, A5
	db C4, G4, As4, G5, A5, F5, As4, F5, A5, As5, A6, G6, A4, E5, G5, A5
	db E6, D6, G4, D5, F5, G5, D6, Cs6, C4, G4, As4, Cs5, F5, C6, C4, E4
	db G4, C5, E5, L4, C6, L8, C6, L4D, C7, C4, PAT_END
Song0B_Header:
	SONG $00, LengthTable_4B04, Song0B_Ch1, Song0B_Ch2, Song0B_Ch3, Song0B_Ch4
Song0B_Ch1:
	dw Pattern_705E
Song0B_Ch1_Loop:
	dw Pattern_7024
	dw Pattern_5D3E
	dw Pattern_702A
	dw Pattern_5D3E
	LIST_LOOP Song0B_Ch1_Loop
Song0B_Ch2:
	dw Pattern_705E
Song0B_Ch2_Loop:
	dw Pattern_5D60
	dw Pattern_5D60
	LIST_LOOP Song0B_Ch2_Loop
Song0B_Ch3:
	dw Pattern_705E
Song0B_Ch3_Loop:
	dw Pattern_6F41
	dw Pattern_5D7B
	dw Pattern_5D7B
	LIST_LOOP Song0B_Ch3_Loop
Song0B_Ch4:
	dw Pattern_5DA5
	LIST_LOOP Song0B_Ch4
Pattern_5D3E:
	INSTR $44, $00, $80
	db L8, REST, L16, D4, D4, L8, Cs4, L4, REST, L16, D4, D4, L8, Ds4, L4, REST
	db L16, D4, D4, L8, Cs4, L4, REST, L16, D4, Cs4, L8, D4, REST, PAT_END
Pattern_5D60:
	INSTR $64, $00, $00
	REPEAT $02
	db L8, G4, D4, L16, G4, A4, B4, C5, L8, D5, L32, Fs5, L16, G5, L32, REST
	db L8, D5, REST
	REPEAT_END
	db PAT_END
Pattern_5D7B:
	CH3_FADEOUT_ON
	db L8, G3, L16, G4, G4, L8, Fs4, L16, D4, D4, L8, G3, L16, G4, G4, L8
	db Gs4, L16, Gs3, Gs3, L8, G3, L16, G4, G4, L8, Fs4, L16, D4, D4, L8, G3
	db L16, G4, Fs4, L8, G4, L16, G3, G3, PAT_END
Pattern_5DA5:
	db L8, NOISE_29, L16, NOISE_29, NOISE_29, L8, DRUM, L16, NOISE_29, NOISE_29, L16, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L8
	db DRUM, NOISE_1A, PAT_END
Song0C_Header:
	SONG $00, LengthTable_4AC8, Song0C_Ch1, Song0C_Ch2, Song0C_Ch3, 0
Song0C_Ch1:
	dw Pattern_5DF1
	dw Pattern_7080
Song0C_Ch1_Loop:
	dw Pattern_7024
	dw Pattern_5DF6
	dw Pattern_7021
	dw Pattern_5DF6
	LIST_LOOP Song0C_Ch1_Loop
Song0C_Ch2:
	dw Pattern_7037
	dw Pattern_7024
	dw Pattern_5DF6
	dw Pattern_7021
	dw Pattern_5DF6
	LIST_LOOP Song0C_Ch2
Song0C_Ch3:
	dw Pattern_707A
Song0C_Ch3_Loop:
	dw Pattern_6F65
	dw Pattern_7024
	dw Pattern_5DF6
	dw Pattern_7021
	dw Pattern_5DF6
	LIST_LOOP Song0C_Ch3_Loop
Pattern_5DF1:
	INSTR $44, $00, $80
	db PAT_END
Pattern_5DF6:
	db L8, B3, Cs4, E4, G4, B4, Cs5, E5, G5, B5, Cs6, E6, G6, B6, Cs7, E7
	db G7, PAT_END
Song0D_Header:
	SONG $00, LengthTable_4AC8, Song0D_Ch1, Song0D_Ch2, Song0D_Ch3, 0
Song0D_Ch1:
	dw Pattern_505B
	LIST_LOOP Song0D_Ch1
Song0D_Ch2:
	dw Pattern_50D9
	LIST_LOOP Song0D_Ch2
Song0D_Ch3:
	dw Pattern_6F41
	dw Pattern_517E
	LIST_LOOP Song0D_Ch3
Song0E_Header:
	SONG $00, LengthTable_4AB9, Song0E_Ch1, Song0E_Ch2, Song0E_Ch3, 0
Song0E_Ch1:
	dw Pattern_7024
	dw Pattern_6F8E
	dw Pattern_5E6E
	dw Pattern_5E6E
	dw Pattern_6F93
	dw Pattern_5E6E
	dw Pattern_5E6E
	dw Pattern_7021
	dw Pattern_6F8E
	dw Pattern_5E6E
	dw Pattern_5E6E
	dw Pattern_6F93
	dw Pattern_5E6E
	dw Pattern_5E6E
	LIST_LOOP Song0E_Ch1
Song0E_Ch2:
	dw Pattern_5E78
	dw Pattern_5E91
	dw Pattern_5E78
	dw Pattern_5E91
	LIST_LOOP Song0E_Ch2
Song0E_Ch3:
	dw Pattern_6F6B
	dw Pattern_5EA0
	dw Pattern_5EA0
	dw Pattern_6F75
	dw Pattern_5EA0
	dw Pattern_5EA0
	LIST_LOOP Song0E_Ch3
Pattern_5E6E:
	REPEAT $02
	db L8, Cs3, Ds3, Ds3
	REPEAT_END
	db Cs3, Ds3, PAT_END
Pattern_5E78:
	INSTR $70, $21, $40
	db L4D, B4, L16, A4, B4, L4D, C5, L16, B4, C5, L4D, Cs5, L16, A5, G5, L8
	db Cs5, Cs6, L4, Cs6, PAT_END
Pattern_5E91:
	INSTR $20, $21, $81
	db L8, Cs5, Cs6, L2D, Cs6, L8, Cs6, Cs7, L2D, Cs7, PAT_END
Pattern_5EA0:
	CH3_FADEOUT_ON
	db L4D, G3, G3, L4, G3, PAT_END
Song0F_Header:
	SONG $00, LengthTable_4AB9, Song0F_Ch1, Song0F_Ch2, Song0F_Ch3, 0
Song0F_Ch1:
	dw Pattern_5ECC
	dw Pattern_5ED1
	dw Pattern_5EDB
	LIST_END
Song0F_Ch2:
	dw Pattern_5ED6
	dw Pattern_5EDB
	dw Pattern_5ED1
	LIST_END
Song0F_Ch3:
	dw Pattern_6F55
	dw Pattern_7083
	dw Pattern_5EDB
	dw Pattern_707A
	LIST_END
Pattern_5ECC:
	INSTR $26, $00, $80
	db PAT_END
Pattern_5ED1:
	db L4, REST, L16, REST, PAT_END
Pattern_5ED6:
	INSTR $67, $00, $81
	db PAT_END
Pattern_5EDB:
	CH3_SFX_PAUSE
	db L16, G6, Fs6, D6, B5, G5, Fs5, D5, B4, A6, G6, E6, C6, A5, G5, E5
	db C5, B6, A6, Fs6, D6, B5, A5, Fs5, D5, C7, B6, G6, E6, C6, B5, G5
	db E5, L8, D4, A4, C5, D5, Fs5, A5, C6, D6, L2D, D7
	CH3_SFX_RESUME
	db PAT_END
Song31_Header:
	SONG $00, LengthTable_4AC8, Song31_Ch1, Song31_Ch2, Song31_Ch3, 0
Song31_Ch1:
	dw Pattern_5F29
	LIST_LOOP Song05_Ch1_Loop
Song31_Ch2:
	dw Pattern_5F5C
	LIST_LOOP Song05_Ch2_Loop
Song31_Ch3:
	dw Pattern_6F41
	dw Pattern_5F85
	LIST_LOOP Song05_Ch3_Loop
Pattern_5F29:
	INSTR $70, $21, $81
	db LEN10, REST, D4, G4, L4, B4, LEN10, B4, B4, A4, L4, B4, LEN10, REST, F4, As4
	db L4, D5, LEN10, D5, D5, C5, L4, D5, L4, REST
	REPEAT $02
	db L4, Cs5, L8, REST, L16, Cs5, Cs5
	REPEAT_END
	db L2D, C5
	INSTR $40, $21, $80
	db LEN10, C4, B3, A3, PAT_END
Pattern_5F5C:
	INSTR $90, $21, $81
	db LEN10, D4, G4, B4, L2D, D5, LEN10, F4, As4, D5, L2D, F5, LEN10, D5, F5, As5
	REPEAT $02
	db L4, Gs5, L8, REST, L16, Gs5, Gs5
	REPEAT_END
	db L2D, A5
	INSTR $60, $21, $80
	db LEN10, A4, G4, Fs4, PAT_END
Pattern_5F85:
	CH3_FADEOUT_ON
	db LEN10, REST, REST, D5
	CH3_FADEOUT_OFF
	db L4, G5
	CH3_FADEOUT_ON
	db LEN10, G4, G4, F4
	CH3_FADEOUT_OFF
	db L4, G4
	CH3_FADEOUT_ON
	db LEN10, REST, REST, F5
	CH3_FADEOUT_OFF
	db L4, As5
	CH3_FADEOUT_ON
	db LEN10, As4, As4, Gs4
	CH3_FADEOUT_OFF
	db L4, As4, REST
	CH3_FADEOUT_ON
	db LEN10, Gs3, G3, Gs3, Cs4, C4, Cs4, F4, E4, F4, Gs4, Cs5, F5, Fs5, E5, Fs5
	db G5, Fs5, E5, L4, D5, LEN10, D3, D3, D3, PAT_END
Song32_Header:
	SONG $00, LengthTable_4AE6, Song32_Ch1, Song32_Ch2, Song04_Ch3, 0
Song32_Ch1:
	dw Pattern_6FB6
	dw Pattern_5FDC
	LIST_LOOP Song32_Ch1
Song32_Ch2:
	dw Pattern_6FBB
	dw Pattern_5FFE
	LIST_LOOP Song32_Ch2
Pattern_5FDC:
	db L8, C4, E4, G4, E4, C4, D4, Fs4, A4, B3, D4, Fs4, A4, E3, G3, B3
	db G3, A3, C4, E4, C4, D3, Fs3, A3, Fs3, G3, A3, C4, D4, G3, B3, D4
	db F4, PAT_END
Pattern_5FFE:
	db L2, G6, L8, REST, Fs6, A6, L2, D6, L8, REST, G6, G5, A5, B5, C6, B5
	db C6, L4, Fs5, E6, L1, D6, L8, REST, PAT_END
Song33_Header:
	SONG $00, LengthTable_4AB9, Song33_Ch1, Song33_Ch2, Song04_Ch3, 0
Song33_Ch1:
	dw Pattern_6059
	dw Pattern_6065
	dw Pattern_604E
	dw Pattern_604E
	dw Pattern_6059
	dw Pattern_606A
	dw Pattern_604E
	dw Pattern_604E
	dw Pattern_604E
	LIST_LOOP Song33_Ch1
Song33_Ch2:
	dw Pattern_607E
	dw Pattern_608A
	dw Pattern_606F
	dw Pattern_606F
	dw Pattern_607E
	dw Pattern_6090
	dw Pattern_606F
	dw Pattern_606F
	dw Pattern_606F
	LIST_LOOP Song33_Ch2
Pattern_604E:
	REPEAT $0c
	db LEN13, REST, REST, REST, REST
	REPEAT_END
	db L1, REST, PAT_END
Pattern_6059:
	INSTR $40, $41, $80
	REPEAT $02
	db L4, G3, C4, C4
	REPEAT_END
	db PAT_END
Pattern_6065:
	db L4, B3, Fs3, REST, PAT_END
Pattern_606A:
	db L4, Cs4, Gs3, REST, PAT_END
Pattern_606F:
	INSTR $42, $00, $80
	REPEAT $0c
	db LEN13, As4, A4, As4, REST
	REPEAT_END
	db L1, REST, PAT_END
Pattern_607E:
	INSTR $40, $41, $80
	REPEAT $02
	db L4, B3, E4, E4
	REPEAT_END
	db PAT_END
Pattern_608A:
	db L4, Ds4, As3, L4, REST, PAT_END
Pattern_6090:
	db L4, F4, C4, L4, REST, PAT_END
Song34_Header:
	SONG $00, LengthTable_4AD7, Song04_Ch3, Song34_Ch2, Song34_Ch3, 0
Song34_Ch2:
	dw Pattern_60C1
	dw Pattern_60D9
	dw Pattern_60D9
	dw Pattern_60FA
	dw Pattern_7032
	dw Pattern_610F
	dw Pattern_7080
	LIST_END
Song34_Ch3:
	dw Pattern_6F4B
	dw Pattern_611D
	dw Pattern_6129
	dw Pattern_6F55
	dw Pattern_614C
	dw Pattern_6159
	dw Pattern_610F
	LIST_END
Pattern_60C1:
	INSTR $43, $00, $80
	db L2, REST, L8, REST, L16, B6, A6, L8, B6, L4, REST, L16, C7, B6, L8, C7
	db L4, REST, REST, PAT_END
Pattern_60D9:
	INSTR $55, $00, $00
	TEMPO LengthTable_4AB9
	REPEAT $02
	db L16, D6, Ds6, D6, Cs6, C6, Cs6, C6, Cs6
	REPEAT_END
	db L8, D6, D7, D6, L16, D6, Ds6, E6, F6, E6, Ds6, L4, D6, PAT_END
Pattern_60FA:
	INSTR $35, $00, $40
	REPEAT $02
	db L16, D6, Ds6, D6, Cs6, C6, Cs6, C6, Cs6
	REPEAT_END
	db L1, REST, L4, REST, PAT_END
Pattern_610F:
	TEMPO LengthTable_4AC8
	db L32, D7, C7, As6, Gs6, Fs6, E6, L4, D6, REST, PAT_END
Pattern_611D:
	db L2, REST, L8, REST
	CH3_FADEOUT_ON
	db L4, F6, REST, Fs6, REST, REST, PAT_END
Pattern_6129:
	TEMPO LengthTable_4AB9
	CH3_FADEOUT_ON
	REPEAT $02
	db L8, G4, D5, D4, D5
	REPEAT_END
	REPEAT $02
	db Gs4, Ds5, Ds4, Ds5
	REPEAT_END
	REPEAT $02
	db As4, F5, F4, F5
	REPEAT_END
	db C5, G5, G4, G5, C5, G5, B4, A4, PAT_END
Pattern_614C:
	REPEAT $02
	db L8, G4, D5, D4, D5
	REPEAT_END
	db L1, REST, L4, REST, PAT_END
Pattern_6159:
	TEMPO LengthTable_4AC8
	db L16, REST, PAT_END
Song35_Header:
	SONG $00, LengthTable_4AD7, Song35_Ch1, Song35_Ch2, Song35_Ch3, 0
Song35_Ch1:
	dw Pattern_6FC0
	dw Pattern_618C
	dw Pattern_6FC5
	dw Pattern_619A
	dw Pattern_619A
	LIST_END
Song35_Ch2:
	dw Pattern_6FC0
	dw Pattern_61C8
	dw Pattern_6FC5
	dw Pattern_61D6
	dw Pattern_61D6
	LIST_END
Song35_Ch3:
	dw Pattern_6F70
	dw Pattern_6204
	dw Pattern_6211
	dw Pattern_6211
	LIST_END
Pattern_618C:
	db L2, REST, L16, Fs3, Gs3, As3, B3, Cs4, REST, Cs4, REST, L1, D4, PAT_END
Pattern_619A:
	db L2, REST, L8, Cs4, Ds4, F4, Fs4, L4D, Gs4, L8, As4, Gs4, Fs4, F4, Ds4, L2
	db Cs4, L8, F4, Fs4, Gs4, Cs5, L4D, F5, L8, Fs5, F5, Ds5, Cs5, C5, L4D, Cs5
	db L16, Gs4, Gs4
	REPEAT $02
	db L8, Cs5, L16, Gs4, Gs4
	REPEAT_END
	db L1, Cs5, PAT_END
Pattern_61C8:
	db L1, REST, L16, G4, A4, B4, C5, D5, REST, D5, REST, L2, Ds5, PAT_END
Pattern_61D6:
	db L1, REST, L8, D5, E5, Fs5, G5, L4D, A5, L8, B5, A5, G5, Fs5, E5, L2
	db D5, L8, Fs5, G5, A5, D6, L4D, Fs6, L8, G6, Fs6, E6, D6, Cs6, L4D, D6
	db L16, A5, A5
	REPEAT $02
	db L8, D6, L16, A5, A5
	REPEAT_END
	db L2, D6, PAT_END
Pattern_6204:
	CH3_FADEOUT_OFF
	db L16, F3, G3, A3, As3, C4, REST, C4, REST, L1D, Cs4, PAT_END
Pattern_6211:
	db L8, C4, D4, E4, F4, L4D, G4, L8, A4, G4, F4, E4, D4, L2, C4, L8
	db E4, F4, G4, C5, L4D, E5, L8, F5, E5, D5, C5, B4, L4, C5, L8, REST
	CH3_FADEOUT_ON
	db L16, G4, G4
	REPEAT $02
	db L8, C5, L16, G4, G4
	REPEAT_END
	CH3_FADEOUT_OFF
	db L1D, C5, PAT_END
Song36_Header:
	SONG $00, LengthTable_4AD7, Song04_Ch3, Song36_Ch2, Song36_Ch3, 0
Song36_Ch2:
	dw Pattern_626C
	dw Pattern_6271
	dw Pattern_6FA2
	dw Pattern_6271
	dw Pattern_6282
	dw Pattern_6FB6
	dw Pattern_62BA
	LIST_END
Song36_Ch3:
	dw Pattern_6F55
	dw Pattern_62C7
	dw Pattern_6F4B
	dw Pattern_62C7
	dw Pattern_62D9
	dw Pattern_6F55
	dw Pattern_6300
	LIST_END
Pattern_626C:
	INSTR $40, $26, $01
	db PAT_END
Pattern_6271:
	db L16, B7, L8D, B7, L16, G7, L8D, G7, L16, D7, L8D, D7, L16, G7, L8D, G7
	db PAT_END
Pattern_6282:
	db L8D, D5, L16, D5, L4, B4, L8D, C5, L16, C5, L4, Gs4, L16, D5, L8, D5
	db L16, E5, D5, B4, G4, B4, L8, C5, B7, L4, B7, L8D, D5, L16, D5, L4
	db B4, L8D, G5, L16, G5, L4, Ds5, L16, D5, L8, D5, L16, E5, L8, D5, L16
	db G5, B5, L8, C6, B7, L4, B7, PAT_END
Pattern_62BA:
	db L8D, D5, L16, D5, L4, B4, L8D, C5, L16, C5, L4, Gs4, PAT_END
Pattern_62C7:
	CH3_FADEOUT_ON
	db L16, As7, L8D, As7, L16, Fs7, L8D, Fs7, L16, Cs7, L8D, Cs7, L16, Fs7, L8D, Fs7
	db PAT_END
Pattern_62D9:
	REPEAT $02
	db L8, G3, L16, B3, D4, L8, D3, L16, B3, D4, L8, Gs3, L16, C4, Ds4, L8
	db Ds3, L16, C4, Ds4, L8, G3, L16, B3, D4, L8, D3, L16, B3, D4, L8, Gs3
	db As7, As7, D3
	REPEAT_END
	db PAT_END
Pattern_6300:
	db L8, G3, L16, B3, D4, L8, D3, L16, B3, D4, L8, Gs3, L16, C4, Ds4, L8
	db Ds3, L16, C4, Ds4, PAT_END
Song39_Header:
	SONG $00, LengthTable_4AB9, Song39_Ch1, Song39_Ch2, Song39_Ch3, Song39_Ch4
Song39_Ch1:
	dw Pattern_706B
	dw Pattern_6FAC
	dw Pattern_636E
	dw Pattern_6FCA
	dw Pattern_637F
Song39_Ch1_Loop:
	dw Pattern_6F8E
	dw Pattern_7024
	dw Pattern_6394
	dw Pattern_6FD9
	dw Pattern_7027
	dw Pattern_6394
	LIST_LOOP Song39_Ch1_Loop
Song39_Ch2:
	dw Pattern_6FAC
	dw Pattern_63A3
	dw Pattern_63B2
	dw Pattern_6FCA
	dw Pattern_63C1
Song39_Ch2_Loop:
	dw Pattern_6FCF
	dw Pattern_63D6
	dw Pattern_6FD4
	dw Pattern_63D6
	LIST_LOOP Song39_Ch2_Loop
Song39_Ch3:
	dw Pattern_6F46
	dw Pattern_63E5
	dw Pattern_7061
	dw Pattern_6F41
	dw Pattern_63F4
Song39_Ch3_Loop:
	dw Pattern_6F41
	dw Pattern_6404
	dw Pattern_6404
	LIST_LOOP Song39_Ch3_Loop
Song39_Ch4:
	dw Pattern_6420
	dw Pattern_6428
Song39_Ch4_Loop:
	dw Pattern_642E
	LIST_LOOP Song39_Ch4_Loop
Pattern_636E:
	db L2D, REST, L16, As4, B4, As5, B5, L2D, REST, L16, B4, C5, B5, C6, L2D, REST
	db PAT_END
Pattern_637F:
	REPEAT $05
	db L16, G6, Gs6, G6, Fs6
	REPEAT_END
	db G6, Fs6, F6, E6, Ds6, D6, Cs6, C6, B5, As5, A5, Gs5, PAT_END
Pattern_6394:
	REPEAT $04
	db L8, Ds5, C5, C5, Ds5, C5, C5, Ds5, C5, Ds5, C5
	REPEAT_END
	db PAT_END
Pattern_63A3:
	db L1, REST
	REPEAT $08
	db L16, D3, Ds3
	REPEAT_END
	db L4, D3, L1D, REST, L1, REST, PAT_END
Pattern_63B2:
	db L16, E5, F5, E6, F6, L2D, REST, L16, F5, Fs5, F6, Fs6, L2D, REST, PAT_END
Pattern_63C1:
	REPEAT $05
	db L16, G5, Gs5, G5, Fs5
	REPEAT_END
	db G5, Fs5, F5, E5, Ds5, D5, Cs5, C5, B4, As4, A4, Gs4, PAT_END
Pattern_63D6:
	REPEAT $04
	db L8, G5, REST, REST, Fs5, REST, REST, G5, REST, Gs5, REST
	REPEAT_END
	db PAT_END
Pattern_63E5:
	CH3_FADEOUT_OFF
	REPEAT $10
	db L16, G3, Gs3
	REPEAT_END
	CH3_FADEOUT_ON
	db L4, A3, L1D, REST, L1, REST, PAT_END
Pattern_63F4:
	db L1, REST
	CH3_FADEOUT_ON
	REPEAT $04
	db L8, G4
	REPEAT_END
	db G3, G3, L16, G3, G3, Gs3, G3, PAT_END
Pattern_6404:
	CH3_FADEOUT_ON
	REPEAT $04
	db L16, C5, C5, C4, C4, L8, C4, L16, C5, C5, C4, C4, L8, C4, L16, C5
	db C5, C4, C4, C5, C5, C4, C4
	REPEAT_END
	db PAT_END
Pattern_6420:
	REPEAT $04
	db L1, REST
	REPEAT_END
	db L2D, REST, PAT_END
Pattern_6428:
	REPEAT $04
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_642E:
	REPEAT $02
	db L16, NOISE_15, NOISE_15, NOISE_15, NOISE_15, L8, REST
	REPEAT_END
	REPEAT $08
	db L16, NOISE_15
	REPEAT_END
	db PAT_END
Song3A_Header:
	SONG $00, LengthTable_4AF5, Song04_Ch3, Song3A_Ch2, Song3A_Ch3, Song3A_Ch4
Song3A_Ch2:
	dw Pattern_6FB6
	dw Pattern_6461
	dw Pattern_6480
	LIST_LOOP Song3A_Ch2
Song3A_Ch3:
	dw Pattern_6F6B
	dw Pattern_64B5
	LIST_LOOP Song3A_Ch3
Song3A_Ch4:
	dw Pattern_64D0
	LIST_LOOP Song3A_Ch4
Pattern_6461:
	db L2, REST, L4D, REST, LEN13, Gs5, As5, Gs5, L4, G5, REST, L4D, REST, L16, C5, F5
	db L4, D5, REST, L4D, REST, LEN13, Gs4, As4, Gs4, L4, G4, REST, L4D, REST, PAT_END
Pattern_6480:
	INSTR $40, $21, $01
	db LEN13, D5, Ds5, E5, L8D, F5, L16, B4, L4D, F5, LEN13, E5, F5, E5, L8, D5
	db C5, L8D, D5, L16, G4, L2, D5, L8, REST, LEN13, D5, Ds5, E5, L8D, F5, L16
	db B4, L4D, F5, LEN13, E5, F5, E5, L8, D5, C5, L8D, D5, L16, G4, L2D, D5
	db PAT_END
Pattern_64B5:
	CH3_FADEOUT_ON
	REPEAT $04
	db L8D, G3, L16, B3, L8, D4, G3, Gs3, C4, L4, Ds4, L8D, G3, L16, B3, L8
	db D4, G3, D3, Gs3, L4, C4
	REPEAT_END
	db PAT_END
Pattern_64D0:
	REPEAT $03
	db L8, NOISE_15, LEN13, NOISE_15, NOISE_15, NOISE_15
	REPEAT_END
	REPEAT $04
	db L16, NOISE_15
	REPEAT_END
	db PAT_END
Song3B_Header:
	SONG $00, LengthTable_4AB9, Song3B_Ch1, Song3B_Ch2, Song3B_Ch3, 0
Song3B_Ch1:
	dw Pattern_6FCF
	dw Pattern_64FC
	LIST_END
Song3B_Ch2:
	dw Pattern_6FCF
	dw Pattern_6503
	LIST_END
Song3B_Ch3:
	dw Pattern_6F6B
	dw Pattern_650A
	LIST_END
Pattern_64FC:
	db L8, E5, F5, Fs5, L2D, G5, PAT_END
Pattern_6503:
	db L8, A5, As5, B5, L2D, C6, PAT_END
Pattern_650A:
	CH3_FADEOUT_ON
	db L8, B3, C4, Cs4
	CH3_FADEOUT_OFF
	db L2D, D4, PAT_END
Song3D_Header:
	SONG $00, LengthTable_4AE6, Song3D_Ch1, Song3D_Ch2, Song3D_Ch3, Song3D_Ch4
Song3D_Ch1:
	dw Pattern_704A
	dw Pattern_703C
	dw Pattern_6656
	dw Pattern_665B
	dw Pattern_666D
	dw Pattern_668A
	dw Pattern_66BA
	dw Pattern_709F
	dw Pattern_66D8
	dw Pattern_6716
	dw Pattern_671B
	dw Pattern_7086
	dw Pattern_709B
	dw Pattern_7061
	dw Pattern_672F
	dw Pattern_676A
	dw Pattern_676A
	dw Pattern_67F2
	dw Pattern_676A
	dw Pattern_676A
	dw Pattern_67F2
	dw Pattern_676A
	dw Pattern_676A
	dw Pattern_67F2
	dw Pattern_67D1
	dw Pattern_6832
	dw Pattern_6852
	dw Pattern_709F
	dw Pattern_6863
	dw Pattern_70A3
	dw Pattern_6880
	LIST_END
Song3D_Ch2:
	dw Pattern_704A
	dw Pattern_6FE8
	dw Pattern_688F
	dw Pattern_6FE3
	dw Pattern_68A5
	dw Pattern_6FF2
	dw Pattern_688F
	dw Pattern_6FDE
	dw Pattern_68B9
	dw Pattern_68CC
	dw Pattern_6FED
	dw Pattern_68D1
	dw Pattern_709F
	dw Pattern_68E8
	dw Pattern_5ECC
	dw Pattern_7080
	dw Pattern_671B
	dw Pattern_707A
	dw Pattern_709B
	dw Pattern_7061
	dw Pattern_6904
	dw Pattern_693D
	dw Pattern_693D
	dw Pattern_69AE
	dw Pattern_693D
	dw Pattern_693D
	dw Pattern_69AE
	dw Pattern_693D
	dw Pattern_693D
	dw Pattern_69AE
	dw Pattern_698F
	dw Pattern_69EE
	dw Pattern_6A07
	dw Pattern_709F
	dw Pattern_6A18
	dw Pattern_70A3
	dw Pattern_6A2D
	LIST_END
Song3D_Ch3:
	dw Pattern_704A
	dw Pattern_707A
	dw Pattern_6A3C
	dw Pattern_688F
	dw Pattern_6A41
	dw Pattern_68A5
	dw Pattern_6A46
	dw Pattern_6F55
	dw Pattern_665B
	dw Pattern_666D
	dw Pattern_705E
	dw Pattern_6A50
	dw Pattern_6A55
	dw Pattern_709F
	dw Pattern_6A7C
	dw Pattern_6F55
	dw Pattern_7083
	dw Pattern_671B
	dw Pattern_707D
	dw Pattern_709B
	dw Pattern_7061
	dw Pattern_6AA3
	dw Pattern_6AB7
	dw Pattern_6AB7
	dw Pattern_6B30
	dw Pattern_6AB7
	dw Pattern_6AB7
	dw Pattern_6B30
	dw Pattern_6AB7
	dw Pattern_6AB7
	dw Pattern_6B30
	dw Pattern_6B15
	dw Pattern_6B7B
	dw Pattern_6B98
	dw Pattern_709F
	dw Pattern_6BA4
	dw Pattern_70A3
	dw Pattern_6BBA
	LIST_END
Song3D_Ch4:
	dw Pattern_7052
	dw Pattern_6BC5
	dw Pattern_709F
	dw Pattern_6BCD
	dw Pattern_709B
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BF7
	dw Pattern_6BF7
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BF7
	dw Pattern_6BF7
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BD5
	dw Pattern_6BF7
	dw Pattern_6BF7
	dw Pattern_6BE6
	dw Pattern_6BD5
	dw Pattern_6C02
	dw Pattern_709F
	dw Pattern_6C02
	dw Pattern_6C02
	dw Pattern_70A3
	dw Pattern_6C10
	LIST_END
Pattern_6656:
	INSTR $56, $00, $80
	db PAT_END
Pattern_665B:
	db L16, B3, Fs4, A4, Cs5, D5, Fs5, A5, Cs6, D6, Cs6, A5, Fs5, D5, Cs5, A4
	db Fs4, PAT_END
Pattern_666D:
	db L16, G4, A4, B4, D5, G5, A5, B5, D6, G6, D6, B5, A5, G5, D5, B4
	db A4, G4, A4, B4, D5, G5, A5, B5, D6, L4, G6, REST, PAT_END
Pattern_668A:
	INSTR $42, $00, $80
	db L16, D4, Cs4, D4, A3, B3, Cs4, D4, E4, Fs4, E4, Fs4, D4, E4, Fs4, G4
	db A4
	INSTR $52, $00, $80
	db D5, Cs5, D5, A4, Fs5, E5, Fs5, D5
	INSTR $62, $00, $80
	db A5, Fs5, D5, D6, Cs6, As5, Fs5, E5, L4, D5, PAT_END
Pattern_66BA:
	INSTR $60, $21, $80
	db L4, E5, D5, A5, L4D, A5, L4, B5, L8, A5, G5, E5, L4, Fs5, L8, REST
	db G5, Fs5, E5, D5, A5, L4, G5, L2, REST, PAT_END
Pattern_66D8:
	INSTR $52, $00, $80
	db L4, REST
	REPEAT $02
	db L16, A4, C5, E5, G5, B5, G5, E5, C5
	REPEAT_END
	REPEAT $02
	db D4, Fs4, A4, C5, E5, C5, A4, Fs4
	REPEAT_END
	db G4, A4, B4, D5, G5, D5, B4, A4, G4, A4, B4, D5, G5, D5, B4, G4
	db Fs4, Gs4, As4, Cs5, Fs5, Gs5, As5, Cs6, Fs6, Cs6, As5, Gs5, Fs5, Cs5, As4, Fs4
	db PAT_END
Pattern_6716:
	INSTR $47, $00, $80
	db PAT_END
Pattern_671B:
	db L16, D3, E3, Fs3, A3, C4, E4, Fs4, A4, C5, E5, Fs5, A5, C6, E6, Fs6
	db A6, L2, D7, PAT_END
Pattern_672F:
	INSTR $52, $00, $80
	db L2, REST, L4, D3, LEN10, D3, D3, D3
	INSTR $72, $00, $80
	db L4, E3
	REPEAT $06
	db LEN10, E3
	REPEAT_END
	db G3, G3, G3
	INSTR $92, $00, $80
	db L4, A3, LEN10, A3, A3, A3, L4, C4, LEN10, C4, C4, E4, L4, Fs4, LEN10, D4
	db D4, D4, L4, D4
	INSTR $92, $00, $40
	db LEN10, D4, E4, Fs4, PAT_END
Pattern_676A:
	INSTR $90, $21, $41
	db L4, B3, LEN10, C4, B3, A3, B3, REST, B3, C4, D4, E4, L4, F4, LEN10, A4
	db B4, A4, L4, Gs4, LEN10, E4, Fs4, Gs4, L4, A4, LEN10, A5, C6, E6, G6, Ds4
	db F4, G4, F4, Ds4, L4, D4, LEN10, D4, E4, D4, L4, C4, REST
	INSTR $77, $00, $80
	REPEAT $02
	db LEN10, E5, Fs5, G5
	REPEAT_END
	db Fs5, D5, B4, L4, D5, LEN10, E5, Fs5, G5, G5, A5, G5, Fs5, D5, B4, L4
	db D5
	INSTR $70, $21, $41
	db LEN10, C5, D5, E5, E5, E5, E5, L4, Ds5, LEN10, Ds5, F5, Ds5, L4, D5, LEN10
	db D5, E5, D5, L2, C5, PAT_END
Pattern_67D1:
	INSTR $90, $21, $41
	db L4, B3, LEN10, C4, B3, A3, B3, REST, B3, C4, D4, E4, L4, Fs4
	INSTR $70, $21, $41
	db LEN10, C3, D3, G3, A3, Fs3, A3, D4, Fs4, A4, PAT_END
Pattern_67F2:
	INSTR $70, $00, $81
	db L1, REST, REST, L2D, C5, LEN10, C5, D5, C5, L2, B4, L4, C5, D5
	INSTR $90, $26, $80
	db LEN10, Ds5, REST, F5, L2, G5, LEN10, Ds5, F5, G5, L2D, G5, LEN10, G5, G5, G5
	REPEAT $02
	db REST, Ds5, Ds5, Ds5, D5, Ds5
	REPEAT_END
	db L4, D5
	INSTR $70, $21, $40
	db LEN10, E4, REST, E4, D4, REST, D4, C4, REST, C4, PAT_END
Pattern_6832:
	INSTR $80, $21, $41
	db LEN10, As4, A4, As4, C5, As4, A4
	REPEAT $04
	db As4
	REPEAT_END
	db A4, As4, C5, As4, C5, Ds5, Gs5, C6, Ds6, Gs5, Gs5, C6, C6, C6, L4, B5
	db PAT_END
Pattern_6852:
	INSTR $70, $21, $41
	db L8, B4, L16, B4, B4, L4, A4, L8, A4, L16, As4, C5, PAT_END
Pattern_6863:
	INSTR $70, $21, $41
	db L4, Ds5, L8, Ds5, L16, Ds5, Ds5, L8, A5, G5, L4, F5, L4, B5, L8, B5
	db L16, A5, B5, L8, C6, D6, Ds6, C6, PAT_END
Pattern_6880:
	db L4, D6
	INSTR $a0, $21, $40
	db L8, G3, L16, G3, G3, L4, G3, REST, PAT_END
Pattern_688F:
	db L8, REST, B5, Cs6, L2D, D6, L8, B5, Cs6, L2D, D6, L8, Cs6, B5, Fs5, L4D
	db A5, L1, B5, L4, REST, PAT_END
Pattern_68A5:
	db L8, B5, Cs6, L2D, D6, L8, A5, D6, L2D, G6, L8, Fs6, E6, L1, Fs6, L2
	db REST, L8, REST, PAT_END
Pattern_68B9:
	db L8, B5, Cs6, L2D, D6, L8, A5, D6, L2D, G6, L8, Fs6, E6
	INSTR $50, $00, $80
	db Fs6, PAT_END
Pattern_68CC:
	db L1, Fs6, L2, REST, PAT_END
Pattern_68D1:
	db L2D, REST, L4, Cs7, B6, Fs6, L4D, Fs6, L1, G6, L8, E7, D7, Cs7, B6, Fs6
	db E6, Fs6, B6, G6, L4, REST, PAT_END
Pattern_68E8:
	db L8, G6, L2, A6, L8, REST, C6, E6, A6, L2D, Fs6, L8, REST, D6, L1, B6
	db L8, REST, L4D, As6, G7
	INSTR $60, $00, $80
	db L2, Fs7, PAT_END
Pattern_6904:
	INSTR $62, $21, $80
	db L4, REST, REST, Fs3, LEN10, Fs3, Fs3, Fs3
	INSTR $82, $21, $80
	db L4, G3, LEN10, G3, G3, G3, C4, C4, C4, E4, E4, E4
	INSTR $a2, $21, $80
	db L4, Fs4, LEN10, Fs4, Fs4, Fs4, L4, G4, LEN10, G4, G4, G4, L4, A4, LEN10, D5
	db D5, D5, L4, D5, LEN10, D5, D5, D5, PAT_END
Pattern_693D:
	INSTR $a0, $21, $41
	db L4, G4, D4, LEN10, D4, REST, G4, A4, B4, C5, L2, D5, LEN10, REST, D5, E5
	db F5, E5, D5, L2, C5, LEN10, REST, C5, D5, Ds5, D5, C5, L4, B4, LEN10, B4
	db C5, B4, L4, A4
	INSTR $57, $00, $80
	db LEN10, REST, G6, A6
	REPEAT $02
	db L4, B6, G6, L2, D7
	REPEAT_END
	INSTR $a0, $21, $41
	db LEN10, E5, Fs5, G5, G5, A5, B5, L4, C6, LEN10, C6, D6, C6, L4, B5, LEN10
	db B5, C6, B5, L2, A5, PAT_END
Pattern_698F:
	INSTR $a0, $21, $41
	db L4, G4, D4, LEN10, D4, REST, G4, A4, B4, C5, L4, D5
	INSTR $80, $21, $41
	db LEN10, G3, A3, D4, Fs4, D4, Fs4, A4, D5, Fs5, PAT_END
Pattern_69AE:
	INSTR $a0, $26, $81
	db LEN10, G5, REST, A5, L2, As5, LEN10, G5, REST, A5, L4, As5, LEN10, REST, REST, As5
	db L8D, A5, G5, L8, D5, L2, F5, L1D, G5, LEN10, G5, REST, A5, L2, As5, LEN10
	db G5, A5, As5, L2D, Ds6, LEN10, Ds6, D6, As5, L1, C6, L4, C6
	INSTR $a0, $21, $40
	db LEN10, C5, D5, C5, B4, C5, B4, A4, B4, A4, PAT_END
Pattern_69EE:
	INSTR $a0, $21, $41
	db L2, G5, LEN10, REST, G5, G5, G5, F5, G5, L2, Gs5, LEN10, REST, As5, C6, D6
	db Ds6, F6, L4, G6, PAT_END
Pattern_6A07:
	INSTR $a0, $21, $00
	db L8, G5, L16, D5, G5, L4, F5, L8, F5, L16, G5, A5, PAT_END
Pattern_6A18:
	db L4, As5, L8, As5, L16, G5, As5, L4, C6, L16, C6, D6, Ds6, F6
	INSTR $a0, $00, $01
	db L1, G6, PAT_END
Pattern_6A2D:
	INSTR $a0, $21, $00
	db L4, B6, L8, G4, L16, G4, G4, L4, G4, REST, PAT_END
Pattern_6A3C:
	INSTR_WAVE Wave_6F21, $20
	db PAT_END
Pattern_6A41:
	INSTR_WAVE Wave_6F11, $40
	db PAT_END
Pattern_6A46:
	REPEAT $03
	db L1, REST
	REPEAT_END
	db L4, REST, L8D, REST, PAT_END
Pattern_6A50:
	db L2D, REST, L8, REST, PAT_END
Pattern_6A55:
	INSTR_WAVE Wave_6EC1, $20
	CH3_FADEOUT_ON
	db L8, B4, Fs5, A5, D6, L2, REST, L8, E4, B4, D5, G5, REST, Fs5, L16, E5
	db D5, Cs5, Fs4, L8, B4, Fs5, A5, D6, L2, REST, L8, E4, B4, D5, G5, L4
	db REST, PAT_END
Pattern_6A7C:
	db L4, REST
	REPEAT $02
	db L8, A3, L4, A3, L8, A3
	REPEAT_END
	REPEAT $02
	db L8, D3, L4, D3, L8, D3
	REPEAT_END
	REPEAT $02
	db L8, G3, L4, G3, L8, G3
	REPEAT_END
	REPEAT $02
	db L8, Fs3, L4, Fs3, L8, Fs3
	REPEAT_END
	db PAT_END
Pattern_6AA3:
	INSTR_WAVE Wave_6EC1, $20
	CH3_FADEOUT_ON
	REPEAT $06
	db L4, D3, LEN10, D3, D3, D3
	REPEAT_END
	db L4, D3, D3, E3, Fs3, PAT_END
Pattern_6AB7:
	CH3_FADEOUT_ON
	db L4, G3, LEN10, G3, G3, F3, L4, G3, LEN10, G3, G3, G3, L4, F3, LEN10, F4
	db F4, F4
	CH3_FADEOUT_OFF
	db L4, E4, E3
	CH3_FADEOUT_ON
	REPEAT $02
	db L4, A3, LEN10, A3, A3, A3
	REPEAT_END
	db L4, D3, LEN10, D3, D3, D3
	CH3_FADEOUT_OFF
	db L4, D3, Ds3
	CH3_FADEOUT_ON
	db LEN10, E3, G4, B4, E5, B4, G4, B3, Fs4, A4, D5, A4, Fs4, E4, G4, B4
	db E5, B4, G4, B3, Fs4, A4, D5, A4, B3, L4, C4, LEN10, C4, C4, C4, L4
	db Gs3, LEN10, Gs3, Gs3, Gs3, D3, G3, A3, D4, G4, A4, D5, D4, E4, Fs4, E4
	db D4, PAT_END
Pattern_6B15:
	CH3_FADEOUT_ON
	db L4, G3, LEN10, G3, G3, F3, L4, G3, LEN10, G3, G3, G3, L4, D3, LEN10, D3
	db D3, D3, D3, LEN10, D4, E4, Fs4, E4, D4, PAT_END
Pattern_6B30:
	db LEN10, Ds4, G5, As5, Ds6, As5, G5, Ds5, G5, As5, Ds6, As5, G5
	REPEAT $02
	db Ds5, F5, A5, C6, A5, F5
	REPEAT_END
	REPEAT $02
	db D5, F5, A5, C6, A5, F5
	REPEAT_END
	db G4, B4, D5, F5, D5, B4, G4, B4, D5, F5, D5, G4
	REPEAT $02
	CH3_FADEOUT_ON
	db LEN10, C4, G4, As4, Ds5, G5, As5
	CH3_FADEOUT_OFF
	db L4, Ds6, REST
	REPEAT_END
	CH3_FADEOUT_ON
	REPEAT $02
	db LEN10, Gs3, Gs4, Gs4, Gs4, As4, C5
	REPEAT_END
	db L4, D5, D3, E3, Fs3, PAT_END
Pattern_6B7B:
	db Ds4, G4, As4, Ds5, G5, As5
	CH3_FADEOUT_OFF
	db L4, Ds6
	CH3_FADEOUT_ON
	db LEN10, Ds4, Ds4, Ds4, Gs3, C4, Ds4, Gs4, C5, Ds5
	CH3_FADEOUT_OFF
	db L4, Gs6
	CH3_FADEOUT_ON
	db LEN10, Gs3, Gs3, Gs3, PAT_END
Pattern_6B98:
	REPEAT $02
	db L8, G3, D3
	REPEAT_END
	REPEAT $02
	db F3, C3
	REPEAT_END
	db PAT_END
Pattern_6BA4:
	REPEAT $02
	db L8, Ds3, As3
	REPEAT_END
	REPEAT $02
	db F3, C4
	REPEAT_END
	REPEAT $02
	db G3, D3
	REPEAT_END
	REPEAT $02
	db Gs3, Ds3
	REPEAT_END
	db PAT_END
Pattern_6BBA:
	db L4, G3, L8, G3, L16, G3, G3, L4, G3, REST, PAT_END
Pattern_6BC5:
	REPEAT $14
	db L1, REST
	REPEAT_END
	db L4, REST, PAT_END
Pattern_6BCD:
	REPEAT $06
	db L1, REST
	REPEAT_END
	db L4, REST, PAT_END
Pattern_6BD5:
	REPEAT $03
	db L4, NOISE_15, LEN10, NOISE_1A, NOISE_1A, NOISE_1A
	REPEAT_END
	db LEN10, NOISE_15, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, PAT_END
Pattern_6BE6:
	REPEAT $03
	db L4, NOISE_15, LEN10, NOISE_1A, NOISE_1A, NOISE_1A
	REPEAT_END
	db LEN10, NOISE_15, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, PAT_END
Pattern_6BF7:
	REPEAT $08
	db LEN10, NOISE_29, NOISE_29, NOISE_29, NOISE_1A, NOISE_29, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_6C02:
	REPEAT $02
	db L16, NOISE_1A, NOISE_1A, L4, NOISE_1A
	REPEAT_END
	REPEAT $04
	db L16, NOISE_1A
	REPEAT_END
	db PAT_END
Pattern_6C10:
	db L4, NOISE_1A, L8, NOISE_1A, L16, NOISE_1A, NOISE_1A, L4, NOISE_1A, REST, PAT_END
Song3E_Header:
	SONG $00, LengthTable_4AB9, Song3E_Ch1, Song3E_Ch2, Song3E_Ch3, 0
Song3E_Ch1:
	dw Pattern_6C50
	dw Pattern_6C55
	dw Pattern_6C55
	dw Pattern_6FC0
	dw Pattern_6C55
	dw Pattern_6FF7
	dw Pattern_6C55
	LIST_LOOP Song0E_Ch1
Song3E_Ch2:
	dw Pattern_6C50
	dw Pattern_6C5F
	dw Pattern_6C5F
	dw Pattern_6FC0
	dw Pattern_6C5F
	dw Pattern_6FF7
	dw Pattern_6C5F
	LIST_LOOP Song0E_Ch2
Song3E_Ch3:
	dw Pattern_7061
	LIST_LOOP Song0E_Ch3
Pattern_6C50:
	INSTR $40, $00, $40
	db PAT_END
Pattern_6C55:
	db L16, Cs4, D4, Cs4, C4, B3, As3, B3, C4, PAT_END
Pattern_6C5F:
	db L16, B4, C5, B4, As4, A4, Gs4, A4, As4, PAT_END
Song3F_Header:
	SONG $00, LengthTable_4AD7, Song3F_Ch1, Song3F_Ch2, Song3F_Ch3, Song3F_Ch4
Song3F_Ch1:
	dw Pattern_7061
	dw Pattern_6CF6
	dw Pattern_6E00
	dw Pattern_7089
	dw Pattern_7006
	dw Pattern_6CFD
	dw Pattern_700B
	dw Pattern_6D03
	dw Pattern_7001
	dw Pattern_6D09
	dw Pattern_6D7A
	dw Pattern_6DE0
	dw Pattern_6DF3
	dw Pattern_6DF8
	LIST_LOOP UnusedList_708F
Song3F_Ch2:
	dw Pattern_7061
	dw Pattern_6D81
	dw Pattern_6E00
	dw Pattern_7089
	dw Pattern_6FFC
	dw Pattern_6D88
	dw Pattern_7010
	dw Pattern_6DA7
	dw Pattern_7083
	dw Pattern_6DFB
	dw Pattern_6DC7
	dw Pattern_6DD4
	dw Pattern_6DE0
	dw Pattern_7083
	dw Pattern_6DF3
	dw Pattern_6DF8
	LIST_LOOP UnusedList_708F
Song3F_Ch3:
	dw Pattern_7061
	dw Pattern_7015
	dw Pattern_6E00
	dw Pattern_7083
	dw Pattern_7089
	dw Pattern_701B
	dw Pattern_6E12
	dw Pattern_6E34
	dw Pattern_6F55
	dw Pattern_6DC7
	dw Pattern_6DD4
	dw Pattern_6DE0
	dw Pattern_7089
	dw Pattern_6DF8
	LIST_LOOP UnusedList_708F
Song3F_Ch4:
	dw Pattern_6E4A
	dw Pattern_6E56
	dw Pattern_6E56
	dw Pattern_6E56
	dw Pattern_6E56
	dw Pattern_6E6B
	dw Pattern_6E6B
	dw Pattern_6E6B
	dw Pattern_6E6B
	dw Pattern_6E6B
	dw Pattern_6E6B
	dw Pattern_6E95
	dw Pattern_6E99
	LIST_LOOP UnusedList_7095
Pattern_6CF6:
	INSTR $10, $00, $81
	db L8, REST, PAT_END
Pattern_6CFD:
	db L2, B7, E7, Fs7, B6, PAT_END
Pattern_6D03:
	db L2, B7, E7, Fs7, REST, PAT_END
Pattern_6D09:
	INSTR $b1, $82, $00
	db L8, G2, G2
	INSTR $71, $82, $80
	db L16, Fs6, B5, Fs6, B6, L4, REST
	INSTR $b1, $82, $00
	db L8, REST, D2, G2, G2
	INSTR $71, $82, $80
	db L16, Fs6, B5, Fs6, B6, L4, REST
	INSTR $b1, $82, $00
	db L8, REST, G2, B2, B2
	INSTR $71, $82, $80
	db L16, E6, A5, E6, Fs6, L4, REST
	INSTR $b1, $82, $00
	db L8, REST, Fs2, B2, B2
	INSTR $71, $82, $80
	db L16, E6, A5, E6, Fs6
	INSTR $80, $00, $00
	db L4, B2, A2
	INSTR $a1, $82, $00
	db L8, G2, G2, L2, REST, L8, REST, D2, G2, G2, L2, REST, L4, G2
	REPEAT $03
	db L8, D2, D2, L2, REST, L8, REST, A2
	REPEAT_END
	db PAT_END
Pattern_6D7A:
	INSTR $26, $00, $00
	db L4, REST, PAT_END
Pattern_6D81:
	INSTR $40, $00, $41
	db L8, REST, PAT_END
Pattern_6D88:
	REPEAT $03
	db L1, REST
	REPEAT_END
	db L2, REST, L8, REST, B4, Cs5, L2D, D5, L8, B4, Cs5, L2D, D5, L8, Cs5, B4
	db Fs4, L4D, A4, L2D, B4, L8, REST, L2D, REST, PAT_END
Pattern_6DA7:
	REPEAT $03
	db L16, B5, A5, G5, D5, B4, D5, G5, A5
	REPEAT_END
	db B5, A5, G5, D5, B4, D5, G5, B5
	REPEAT $02
	db A5, Fs5, E5, D5, A4, D5, E5, Fs5
	REPEAT_END
	db PAT_END
Pattern_6DC7:
	REPEAT $02
	db L16, Cs6, A5, Fs5, D5, Cs5, D5, Fs5, A5
	REPEAT_END
	db PAT_END
Pattern_6DD4:
	REPEAT $02
	db E6, Cs6, A5, Fs5, E5, Fs5, A5, Cs6
	REPEAT_END
	db PAT_END
Pattern_6DE0:
	db L16, D2, A2, Cs3, D3, Fs3, A3, Cs4, D4, Fs4, A4, Cs5, D5, Fs5, A5, L8
	db Cs6, D6, PAT_END
Pattern_6DF3:
	INSTR $77, $00, $80
	db PAT_END
Pattern_6DF8:
	db L1, A7, PAT_END
Pattern_6DFB:
	INSTR $40, $00, $80
	db PAT_END
Pattern_6E00:
	db L8, B4, Cs5, L2D, D5, L8, B4, Cs5, L2D, D5, L8, Cs5, B4, L8D, Fs4, L1
	db Fs5, PAT_END
Pattern_6E12:
	REPEAT $03
	db L1, REST
	REPEAT_END
	db L2, REST, L8, REST, L8, D4, E4, L2, Fs4, L4, REST, L8, D4, E4, L2, Fs4
	db L4, REST, L8, E4, L4, D4, L4D, Cs4, L2, D4, L2D, REST, PAT_END
Pattern_6E34:
	db L8, B4, Cs5, L2, D5, L4, REST, L8, B4, D5, L2, G5, L4, REST, L8, Fs5
	db E5, L1, Fs5, L8, REST, PAT_END
Pattern_6E4A:
	REPEAT $05
	db L1, REST
	REPEAT_END
	db L2, REST, L8, REST, L8D, REST, PAT_END
Pattern_6E56:
	REPEAT $03
	db L8, NOISE_15, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15
	REPEAT_END
	REPEAT $04
	db L16, NOISE_15
	REPEAT_END
	db PAT_END
Pattern_6E6B:
	db L8, NOISE_24, LEN9, NOISE_1A, LEN13, REST, LEN9, NOISE_1A, LEN13, REST, LEN9, NOISE_1A, L8, NOISE_1A, LEN9, NOISE_1A
	db LEN13, REST, LEN9, NOISE_1A, LEN13, REST, LEN9, NOISE_1A, L8, NOISE_24, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_1A
	db LEN13, REST, LEN9, NOISE_1A
	REPEAT $04
	db L16, NOISE_1A
	REPEAT_END
	db PAT_END
Pattern_6E95:
	db L2, NOISE_24, REST, PAT_END
Pattern_6E99:
	REPEAT $04
	db L1, REST
	REPEAT_END
	db L4D, REST, PAT_END
Wave_6EA1:
	db $66, $66, $66, $66, $66, $66, $66, $66, $00, $00, $00, $00, $00, $00, $00, $00
Wave_6EB1:
	db $88, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave_6EC1:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00
Wave_6ED1:
	db $88, $88, $88, $88, $00, $00, $00, $00, $88, $88, $88, $88, $00, $00, $00, $00
Wave_6EE1:
	db $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $00, $00, $00, $00, $00, $00, $00, $00
Wave_6EF1:
	db $06, $9b, $cd, $de, $ee, $ff, $ff, $fe, $06, $9b, $cd, $de, $ee, $ff, $ff, $fe
Wave_6F01:
	db $7f, $ff, $57, $73, $55, $34, $42, $21, $7f, $ff, $57, $73, $55, $34, $42, $21
Wave_6F11:
	db $33, $33, $33, $33, $00, $00, $00, $00, $33, $33, $33, $33, $00, $00, $00, $00
Wave_6F21:
	db $11, $11, $11, $11, $00, $00, $00, $00, $11, $11, $11, $11, $00, $00, $00, $00
Wave_6F31:
	db $44, $44, $44, $44, $00, $00, $00, $00, $44, $44, $44, $44, $00, $00, $00, $00
Pattern_6F41:
	INSTR_WAVE Wave_6EC1, $20
	db PAT_END
Pattern_6F46:
	INSTR_WAVE Wave_6EC1, $40
	db PAT_END
Pattern_6F4B:
	INSTR_WAVE Wave_6ED1, $21
	db PAT_END
; unreferenced
Pattern_6F50:
	INSTR_WAVE Wave_6ED1, $40
	db PAT_END
Pattern_6F55:
	INSTR_WAVE Wave_6ED1, $40
	CH3_FADEOUT_ON
	db PAT_END
Pattern_6F5B:
	INSTR_WAVE Wave_6EA1, $20
	db PAT_END
Pattern_6F60:
	INSTR_WAVE Wave_6EE1, $20
	db PAT_END
Pattern_6F65:
	INSTR_WAVE Wave_6F31, $40
	CH3_FADEOUT_ON
	db PAT_END
Pattern_6F6B:
	INSTR_WAVE Wave_6EB1, $21
	db PAT_END
Pattern_6F70:
	INSTR_WAVE Wave_6EB1, $25
	db PAT_END
Pattern_6F75:
	INSTR_WAVE Wave_6EB1, $40
	db PAT_END
Pattern_6F7A:
	INSTR $42, $00, $80
	db PAT_END
Pattern_6F7F:
	INSTR $53, $00, $80
	db PAT_END
Pattern_6F84:
	INSTR $50, $83, $40
	db PAT_END
Pattern_6F89:
	INSTR $60, $81, $80
	db PAT_END
Pattern_6F8E:
	INSTR $71, $00, $40
	db PAT_END
Pattern_6F93:
	INSTR $42, $00, $40
	db PAT_END
Pattern_6F98:
	INSTR $33, $00, $40
	db PAT_END
Pattern_6F9D:
	INSTR $62, $00, $80
	db PAT_END
Pattern_6FA2:
	INSTR $60, $26, $01
	db PAT_END
Pattern_6FA7:
	INSTR $60, $26, $81
	db PAT_END
Pattern_6FAC:
	INSTR $40, $00, $80
	db PAT_END
Pattern_6FB1:
	INSTR $20, $00, $80
	db PAT_END
Pattern_6FB6:
	INSTR $43, $00, $80
	db PAT_END
Pattern_6FBB:
	INSTR $40, $21, $80
	db PAT_END
Pattern_6FC0:
	INSTR $50, $00, $41
	db PAT_END
Pattern_6FC5:
	INSTR $60, $21, $41
	db PAT_END
Pattern_6FCA:
	INSTR $60, $00, $81
	db PAT_END
Pattern_6FCF:
	INSTR $90, $21, $41
	db PAT_END
Pattern_6FD4:
	INSTR $b0, $21, $41
	db PAT_END
Pattern_6FD9:
	INSTR $91, $00, $40
	db PAT_END
Pattern_6FDE:
	INSTR $50, $26, $80
	db PAT_END
Pattern_6FE3:
	INSTR $30, $21, $80
	db PAT_END
Pattern_6FE8:
	INSTR $20, $21, $80
	db PAT_END
Pattern_6FED:
	INSTR $60, $26, $80
	db PAT_END
Pattern_6FF2:
	INSTR $40, $26, $80
	db PAT_END
Pattern_6FF7:
	INSTR $60, $00, $40
	db PAT_END
Pattern_6FFC:
	INSTR $a0, $21, $41
	db PAT_END
Pattern_7001:
	INSTR $82, $82, $80
	db PAT_END
Pattern_7006:
	INSTR $77, $00, $80
	db PAT_END
Pattern_700B:
	INSTR $97, $00, $80
	db PAT_END
Pattern_7010:
	INSTR $51, $82, $80
	db PAT_END
Pattern_7015:
	INSTR_WAVE Wave_6F01, $01
	CH3_FADEIN_ON
	db PAT_END
Pattern_701B:
	INSTR_WAVE Wave_6EF1, $01
	CH3_FADEIN_ON
	db PAT_END
Pattern_7021:
	TRANSPOSE $fe
	db PAT_END
Pattern_7024:
	TRANSPOSE $00
	db PAT_END
Pattern_7027:
	TRANSPOSE $02
	db PAT_END
Pattern_702A:
	TRANSPOSE $0a
	db PAT_END
Pattern_702D:
	INSTR $10, $00, $80
	db PAT_END
Pattern_7032:
	INSTR $37, $00, $80
	db PAT_END
Pattern_7037:
	INSTR $43, $83, $80
	db PAT_END
Pattern_703C:
	REPEAT $0b
	db L1, REST
	REPEAT_END
	db L2, REST, PAT_END
; unreferenced
Pattern_7044:
	REPEAT $11
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_704A:
	REPEAT $09
	db L1, REST
	REPEAT_END
	db L2, REST, PAT_END
Pattern_7052:
	REPEAT $09
	db L1, REST
	REPEAT_END
	db L2, REST, PAT_END
; unreferenced
Pattern_705A:
	db L1, REST, REST, PAT_END
Pattern_705E:
	db L1, REST, PAT_END
Pattern_7061:
	db L1, REST, REST, PAT_END
; unreferenced
Pattern_7065:
	REPEAT $03
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_706B:
	REPEAT $04
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_7071:
	REPEAT $10
	db L1, REST
	REPEAT_END
	db PAT_END
; unreferenced
Pattern_7077:
	db L2D, REST, PAT_END
Pattern_707A:
	db L8D, REST, PAT_END
Pattern_707D:
	db L4D, REST, PAT_END
Pattern_7080:
	db L16, REST, PAT_END
Pattern_7083:
	db L8, REST, PAT_END
Pattern_7086:
	db L2, REST, PAT_END
Pattern_7089:
	db L4, REST, PAT_END
Pattern_708C:
	db L1, REST, PAT_END
UnusedList_708F:
	dw Pattern_705E
	LIST_LOOP UnusedList_708F
UnusedList_7095:
	dw Pattern_708C
	LIST_LOOP UnusedList_7095
Pattern_709B:
	TEMPO LengthTable_4AC8
	db PAT_END
Pattern_709F:
	TEMPO LengthTable_4AD7
	db PAT_END
Pattern_70A3:
	TEMPO LengthTable_4AF5
	db PAT_END
	ds 89, 0	; $70A7-$70FF unused
; songs $61, $62, $63, $64, $65, $66, $67, $68, $69, $6a, $6b, $6c, $6d, $6e, $6f; 1 unreachable table entry ($30)
Song61_Header:
	SONG $00, LengthTable_4AC8, Song61_Ch1, Song61_Ch2, Song61_Ch3, 0
Song61_Ch1:
	dw Pattern_712F
	LIST_LOOP Song61_Ch2_Loop
Song61_Ch2:
	dw Pattern_7137
Song61_Ch2_Loop:
	dw Pattern_713C
	dw Pattern_713C
	dw Pattern_71B2
	LIST_LOOP Song61_Ch2_Loop
Song61_Ch3:
	dw Pattern_7228
	dw Pattern_722D
	dw Pattern_722D
	dw Pattern_726A
	LIST_LOOP Song61_Ch3
UnusedList_7129:
	dw Pattern_7322
	LIST_LOOP UnusedList_7129
Pattern_712F:
	INSTR $37, $00, $80
	db LEN10, REST, REST, PAT_END
Pattern_7137:
	INSTR $47, $00, $80
	db PAT_END
Pattern_713C:
	db L8, G5, As5, D6, Ds6, G5, As5, D6, Ds6, G5, As5, D6, Ds6, G5, As5, D6
	db Ds6, Fs5, A5, D6, Ds6, Fs5, A5, D6, Ds6, Fs5, A5, D6, Ds6, Fs5, A5, D6
	db Ds6, F5, Gs5, D6, Ds6, F5, Gs5, D6, Ds6, F5, Gs5, D6, Ds6, F5, Gs5, D6
	db Ds6, E5, G5, D6, Ds6, E5, G5, D6, Ds6, E5, G5, D6, Ds6, E5, G5, D6
	db Ds6, Ds5, G5, C6, D6, Ds5, G5, C6, D6, Ds5, G5, C6, D6, Ds5, G5, C6
	db D6, D5, G5, C6, D6, D5, G5, C6, D6, D5, G5, C6, D6, D5, G5, C6
	db D6, C5, Fs5, A5, C6, Fs5, A5, C6, Ds6, A5, C6, Ds6, C6, Ds6, Fs6, Ds6
	db Fs6, A6, Fs6, A6, C7, PAT_END
Pattern_71B2:
	db L8, D6, As5, G5, As5, D6, As5, G5, As5, D6, As5, G5, As5, D6, As5, G5
	db As5, D6, A5, Fs5, A5, D6, A5, Fs5, A5, D6, A5, Fs5, A5, D6, A5, Fs5
	db A5, D6, Gs5, F5, Gs5, D6, Gs5, F5, Gs5, D6, Gs5, F5, Gs5, D6, Gs5, F5
	db Gs5, D6, G5, E5, G5, D6, G5, E5, G5, D6, G5, E5, G5, D6, G5, E5
	db G5, D6, G5, Ds5, G5, D6, G5, Ds5, G5, D6, G5, Ds5, G5, D6, G5, Ds5
	db G5, D6, G5, D5, G5, D6, G5, D5, G5, D6, G5, D5, G5, D6, G5, D5
	db G5, C5, Fs5, A5, C6, Fs5, A5, C6, Ds6, A5, C6, Ds6, C6, Ds6, Fs6, Ds6
	db Fs6, A6, Fs6, A6, C7, PAT_END
Pattern_7228:
	INSTR_WAVE Wave_7349, $21
	db PAT_END
Pattern_722D:
	db L1, G3, L2, As3, D4, Cs4, L1D, Fs3, L1, F3, L4D, F3, Gs3, L4, Cs4, L2
	db C4, L1D, E3, L8, Ds3, D3, L2D, Ds3, L4D, G3, Ds4, L4, D4, L8, D3, Cs3
	db L2D, D3, L4D, G3, D4, L4, Cs4, L8, D3, Fs3, A3, Fs3, A3, C4, A3, C4
	db Ds4, C4, Ds4, Fs4, A4, Fs4, Ds4, C4, Ds4, C4, A3, Fs3, PAT_END
Pattern_726A:
	INSTR_WAVE Wave_7359, $40
	CH3_FADEOUT_ON
	db L8, D4, D4, D4, D4
	INSTR_WAVE Wave_7369, $40
	db D4, D4, D4, D4
	INSTR_WAVE Wave_7359, $40
	db D4, D4, D4, D4
	INSTR_WAVE Wave_7369, $40
	db D4, D4, D4, D4
	INSTR_WAVE Wave_7359, $40
	db REST, REST, REST, REST, Cs4, Cs4, Cs4, Cs4, A3, A3, A3, A3
	INSTR_WAVE Wave_7369, $40
	db A3, A3, A3, A3
	INSTR_WAVE Wave_7359, $40
	db C4, C4, C4, C4
	INSTR_WAVE Wave_7369, $40
	db C4, C4, C4, C4
	INSTR_WAVE Wave_7359, $40
	db REST, REST, REST, REST, D4, D4, C4, C4, B3, B3, B3, B3
	INSTR_WAVE Wave_7369, $40
	db B3, B3, B3, B3
	INSTR_WAVE Wave_7359, $40
	db REST, REST, REST, REST, G3, G3, A3, A3, As3, As3, As3, As3
	INSTR_WAVE Wave_7369, $40
	db As3, As3, As3, As3
	INSTR_WAVE Wave_7359, $40
	db REST, REST, As3, As3, C4, C4, As3, As3, A3, A3, A3, A3
	INSTR_WAVE Wave_7369, $40
	db A3, A3, A3, A3
	INSTR_WAVE Wave_7359, $40
	db REST, REST, G3, G3, Fs3, Fs3, G3, G3, A3, A3, A3, A3
	INSTR_WAVE Wave_7369, $40
	db A3, A3, A3, A3, REST, REST, REST, REST, REST, REST, REST, REST, REST, REST, REST, REST
	CH3_FADEOUT_OFF
	db PAT_END
Pattern_7322:
	REPEAT $07
	db L4, NOISE_15, NOISE_15, NOISE_1F, L8, NOISE_06, L4, NOISE_15, NOISE_15, L8, NOISE_15, L4, NOISE_10
	REPEAT_END
	db L8, NOISE_15, NOISE_15, NOISE_15, NOISE_15, L4, REST, L8, NOISE_15, NOISE_15, NOISE_15, NOISE_15, L4, REST, L8, NOISE_15
	db NOISE_15, NOISE_15, NOISE_15, L4, NOISE_06, NOISE_06, PAT_END
Wave_7349:
	db $66, $66, $66, $66, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave_7359:
	db $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09
Wave_7369:
	db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
	ds 3207, 0	; $7379-$7FFF unused
