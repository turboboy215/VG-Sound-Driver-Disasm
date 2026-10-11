; Tetris songs, $6F3F-$7FEF

Song01_Header:
	SONG $00, LengthTable_6F0E, Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
Song02_Header:
	SONG $00, LengthTable_6F05, Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
Song03_Header:
	SONG $00, LengthTable_6F0E, Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
Song04_Header:
	SONG $00, LengthTables, Song04_Ch1, Song04_Ch2, Song04_Ch3, 0
Song05_Header:
	SONG $00, LengthTable_6F0E, Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
Song06_Header:
	SONG $00, LengthTable_6F0E, Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song07_Header:
	SONG $00, LengthTable_6F0E, Song07_Ch1, Song07_Ch2, 0, 0
Song08_Header:
	SONG $00, LengthTable_6F05, Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
Song09_Header:
	SONG $00, LengthTable_6F0E, Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
Song10_Header:
	SONG $00, LengthTable_6F0E, 0, Song10_Ch2, 0, 0
Song11_Header:
	SONG $00, LengthTable_6F0E, 0, Song11_Ch2, Song11_Ch3, 0
Song12_Header:
	SONG $00, LengthTable_6F0E, Song12_Ch1, Song12_Ch2, Song12_Ch3, 0
Song13_Header:
	SONG $00, LengthTable_6F0E, Song13_Ch1, Song13_Ch2, Song13_Ch3, Song13_Ch4
Song14_Header:
	SONG $00, LengthTable_6F0E, Song14_Ch1, Song14_Ch2, Song14_Ch3, Song14_Ch4
Song15_Header:
	SONG $00, LengthTable_6F0E, Song15_Ch1, Song15_Ch2, Song15_Ch3, Song15_Ch4
Song16_Header:
	SONG $00, LengthTable_6F2B, Song16_Ch1, Song16_Ch2, Song16_Ch3, 0
Song17_Header:
	SONG $00, LengthTable_6F0E, Song17_Ch1, Song17_Ch2, Song17_Ch3, 0
Song07_Ch2:
	dw Pattern_7016
	dw Pattern_7034
	dw Pattern_7016
	dw Pattern_704D
	dw Pattern_7093
	LIST_LOOP Song07_Ch2
Song07_Ch1:
	dw Pattern_7062
	dw Pattern_7074
	dw Pattern_7062
	dw Pattern_7085
	dw Pattern_70F4
	LIST_LOOP Song07_Ch1
Pattern_7016:
	INSTR $74, $00, $41
	db L8, A4, Cs5, Fs5, Cs5, Gs4, Cs5, A4, Cs5, Fs4, Cs5, F4, Cs5, A4, Cs5, Fs5
	db Cs5, Gs4, Cs5, A4, Cs5, Fs4, Cs5, F4, Cs5, PAT_END
Pattern_7034:
	db A4, Cs5, A4, Fs4, D5, B4, Gs4, B4, Gs4, E4, Cs5, A4, Fs4, Cs5, B4, A4
	db Gs4, Fs4, F4, Cs4, F4, Gs4, Cs5, B4, PAT_END
Pattern_704D:
	db A4, Cs5, A4, Fs4, D5, B4, Gs4, B4, Gs4, E4, E5, B4, Cs5, E5, Cs5, A4
	db E4, Gs4, L2D, A4, PAT_END
Pattern_7062:
	INSTR $64, $00, $41
	db L4, Fs3, Fs4, F4, Fs3, A3, Cs4, Fs4, D4, Cs4, Fs4, A3, Cs4, PAT_END
Pattern_7074:
	db Fs3, Fs4, B3, E3, E4, A3, D3, D4, B3, L8, Cs4, D4, Cs4, B3, A3, Gs3
	db PAT_END
Pattern_7085:
	db L4, Fs3, Fs4, B3, E3, E4, Gs3, A3, Cs4, Cs4, A3, E3, A2, PAT_END
Pattern_7093:
	db L8, E5, D5, Cs5, B4, A4, Gs4, A4, B4, Cs5, A4, B4, D5, Cs5, D5, L4
	db E5, Gs4, L8, A4, B4, L4, Cs5, B4, Cs5, Fs5, Ds5, L8, Fs5, Gs5, L4, A5
	db Gs5, L8, Fs5, E5, Ds5, Cs5, Ds5, C5, L2D, Cs5, L4D, E5, L16, Fs5, G5, L4
	db Fs5, L8, E5, D5, E5, Cs5, D5, B4, L4D, Fs5, L16, Gs5, A5, L4, Gs5, L8
	db Fs5, F5, Fs5, Ds5, F5, Cs5, Gs5, F5, Cs5, F5, Gs5, B5, D6, F5, Cs6, F5
	db B5, F5, L4, A5, L8, B5, A5, Gs5, A5, L16, Fs5, Gs5, L2, Fs5, L8, REST
	db PAT_END
Pattern_70F4:
	db L8, Cs4, E4, A4, E4, B3, E4, Cs4, E4, A3, E4, Gs3, E4, A3, E4, A4
	db E4, B3, E4, Cs4, E4, A3, E4, Gs3, E4, A3, Cs4, A3, Fs3, Fs4, Ds4, C4
	db Ds4, Gs3, Ds4, C4, Ds4, L4, Cs4, Gs4, Gs3, L8, Cs4, E4, Gs4, E4, B3, E4
	db As3, Cs4, Fs3, Cs4, As3, Cs4, L2D, B3, L8, C4, Ds4, Gs3, Ds4, C4, Ds4, L2D
	db Cs4, L4, Cs4, Gs3, F3, Cs3, Ds3, F3, A3, B3, Cs4, L2D, Fs3, PAT_END
Song05_Ch2:
	dw Pattern_7168
	dw Pattern_7168
	dw Pattern_71AE
	LIST_LOOP Song05_Ch2
Song05_Ch1:
	dw Pattern_71CB
	dw Pattern_71CB
	dw Pattern_721D
	LIST_LOOP Song05_Ch1
Song05_Ch3:
	dw Pattern_723A
	dw Pattern_723A
	dw Pattern_727F
	dw Pattern_727F
	LIST_LOOP Song05_Ch3
Song05_Ch4:
	dw Pattern_72A3
	LIST_LOOP Song05_Ch4
Pattern_7168:
	INSTR $84, $00, $81
	db L4, E5, L8, B4, C5, L4, D5, L8, C5, B4, L4, A4, L8, A4, C5, L4
	db E5, L8, D5, C5, L4D, B4, L8, C5, L4, D5, E5, L4, C5, A4, A4, REST
	db L8, REST, L4, D5, L8, F5, L4, A5, L8, G5, F5, L4D, E5, L8, C5, L4
	db E5, L8, D5, C5, L4, B4, L8, B4, C5, L4, D5, E5, L4, C5, A4, A4
	db REST, PAT_END
Pattern_71AE:
	INSTR $50, $00, $81
	db L2, E4, C4, D4, B3, L2, C4, A3, L2D, Gs3, L4, REST, L2, E4, C4, D4
	db B3, L4, C4, E4, L2, A4, Gs4, REST, PAT_END
Pattern_71CB:
	INSTR $43, $00, $81
	db L4, B4, L8, Gs4, A4, B4, L16, E5, D5, L8, A4, Gs4, L4D, E4, L8, A4
	db C5, REST, L8, B4, A4, L16, Gs4, Gs4, L8, E4, Gs4, A4, L4, B4, C5, L4
	db A4, E4, E4, REST, L8, D3, L4, F4, L8, A4, C5, L16, C5, C5, L8, B4
	db A4, L4D, G4, L8, E4, G4, L16, A4, G4, L8, F4, E4, Gs4, E4, Gs4, A4
	db B4, Gs4, C5, Gs4, L16, A4, C5, E4, REST, L4, E4, E4, REST, PAT_END
Pattern_721D:
	INSTR $30, $00, $81
	db L2, C4, A3, B3, Gs3, A3, E3, L2, E3, L4, B3, REST, L2, C4, A3, B3
	db Gs3, L4, A3, C4, L2, E4, D4, REST, PAT_END
Pattern_723A:
	INSTR_WAVE Wave_6EC9, $20
	db L8, E3, E4, E3, E4, E3, E4, E3, E4, A3, A4, A3, A4, A3, A4, A3
	db A4, Gs3, Gs4, Gs3, Gs4, E3, E4, E3, E4, A3, A4, A3, A4, A3, A4, B3
	db C4, D4, D3, REST, D3, REST, D3, A3, F3, C3, C4, REST, C4, C3, G3, G3
	db REST, B3, B4, REST, B4, REST, E4, REST, Gs4, A3, E4, A3, E4, L4, A3, REST
	db PAT_END
Pattern_727F:
	INSTR_WAVE Wave_6EC9, $20
	db L8, A4, E5, A4, E5, A4, E5, A4, E5, Gs4, E5, Gs4, E5, Gs4, E5, Gs4
	db E5, A4, E5, A4, E5, A4, E5, A4, E5, Gs4, E5, Gs4, E5, L2, REST, PAT_END
Pattern_72A3:
	db L8, REST, NOISE1, REST, NOISE1, REST, L16, NOISE1, NOISE1, L8, REST, NOISE1, REST, NOISE1, REST, NOISE1
	db REST, NOISE1, NOISE1, NOISE1, PAT_END
Song06_Ch2:
	dw Pattern_730B
	dw Pattern_733F
	dw Pattern_7367
	dw Pattern_7367
	dw Pattern_73C9
	LIST_LOOP Song06_Ch2
Song06_Ch1:
	dw Pattern_7308
	dw Pattern_733C
	dw Pattern_738E
	dw Pattern_738E
	dw Pattern_744B
	LIST_LOOP Song06_Ch1
Song06_Ch3:
	dw Pattern_731F
	dw Pattern_7353
	dw Pattern_73B5
	dw Pattern_73B5
	dw Pattern_73B5
	dw Pattern_73B5
	dw Pattern_73B5
	dw Pattern_73B5
	dw Pattern_74C0
	dw Pattern_74DE
	dw Pattern_74DE
	dw Pattern_74DE
	dw Pattern_74EE
	dw Pattern_74FE
	dw Pattern_74FE
	dw Pattern_750E
	dw Pattern_750E
	dw Pattern_751E
	dw Pattern_751E
	dw Pattern_750E
	dw Pattern_752E
	LIST_LOOP Song06_Ch3
Song06_Ch4:
	dw Pattern_7333
	LIST_LOOP Song06_Ch4
Pattern_7308:
	db L1, REST, PAT_END
Pattern_730B:
	INSTR $62, $00, $80
	db L8, E4, L16, E4, E4, L8, B3, B3, E4, L16, E4, E4, L8, B3, B3, PAT_END
Pattern_731F:
	INSTR_WAVE Wave_6EE9, $a0
	db L8, E4, L16, E4, E4, L8, B3, B3, E4, L16, E4, E4, L8, B3, B3, PAT_END
Pattern_7333:
	db L8, NOISE1, L16, NOISE1, NOISE1, L8, NOISE1, NOISE1, PAT_END
Pattern_733C:
	db L1, REST, PAT_END
Pattern_733F:
	INSTR $32, $00, $80
	db L8, E4, L16, E4, E4, L8, B3, B3, E4, L16, E4, E4, L8, B3, B3, PAT_END
Pattern_7353:
	INSTR_WAVE Wave_6EE9, $a0
	db L8, E4, L16, E4, E4, L8, B3, B3, E4, L16, E4, E4, L8, B3, B3, PAT_END
Pattern_7367:
	INSTR $82, $00, $80
	db L8, E4, B4, E5, Ds5, E5, L16, B4, B4, L8, C5, A4, B4, L16, G4, G4
	db L8, A4, Fs4, G4, L16, E4, E4, L8, Fs4, Ds4, E4, B3, C4, Ds4, E4, B3
	db C4, Fs4, PAT_END
Pattern_738E:
	INSTR $53, $00, $40
	db L8, B3, G4, G4, A4, G4, L16, Fs4, G4, L8, A4, Fs4, G4, L16, Ds4, E4
	db L8, Fs4, Ds4, E4, L16, As3, B3, L8, Ds4, B3, B3, G3, A3, A3, B3, G3
	db A3, Ds4, PAT_END
Pattern_73B5:
	INSTR_WAVE Wave_6EE9, $a0
	db L8, E4, L16, E4, E4, L8, B3, B3, E4, L16, E4, E4, L8, B3, B3, PAT_END
Pattern_73C9:
	db L2D, E4, L8, Fs4, Ds4, L2D, E4, L4, Fs4, L8, G4, L16, G4, G4, L8, A4
	db Fs4, G4, L16, G4, G4, L8, A4, Fs4, L2D, G4, L4, A4, L8, B4, L16, B4
	db B4, L8, C5, A4, B4, L16, B4, B4, L8, C5, A4, L2D, B4, L4, Cs5, L8
	db D5, L16, D5, D5, L8, D5, D5, E5, D5, D5, Cs5, D5, L16, D5, D5, L8
	db D5, D5, E5, D5, D5, Cs5, D5, L16, D5, D5, L8, D5, D5, Cs5, L16, Cs5
	db Cs5, L8, Cs5, Cs5, C5, L16, C5, C5, L8, C5, A4, Fs4, G4, A4, D4, A4
	db L16, G4, G4, L8, D4, L4, G4, L16, D4, E4, L8, D4, B3, A4, L16, G4
	db G4, L8, D4, L4, G4, L16, D4, E4, L8, D4, As3, L1, D4, L2D, REST, L4
	db Ds4, PAT_END
Pattern_744B:
	db L2D, B3, L8, B3, B3, L2D, B3, L4, D4, L1, REST, L2D, REST, L4, Fs4, L8
	db G4, L16, G4, G4, L8, A4, Fs4, G4, L16, G4, G4, L8, A4, Fs4, L2D, D4
	db L4, E4, L8, Fs4, L16, G4, A4, L8, Fs4, A4, B4, B4, B4, E4, Fs4, L16
	db G4, A4, L8, Fs4, A4, As4, As4, As4, E4, Fs4, L16, G4, A4, L8, Fs4, A4
	db E4, L16, Fs4, G4, L8, E4, G4, E4, L16, Fs4, G4, L8, Fs4, Fs4, A3, E4
	db Fs4, Fs3, B3, L16, B3, B3, L8, B3, L4, B3, L16, B3, Cs4, L8, B3, G3
	db As3, L16, As3, As3, L8, As3, L4, As3, L16, As3, C4, L8, As3, G3, L1, Fs3
	db L2D, REST, L4, A3, PAT_END
Pattern_74C0:
	db L8, E4, L16, E4, E4, L8, C4, A3, E4, L16, E4, E4, L8, Ds4, B3, E4
	db L16, E4, E4, L8, C4, A3, E4, L16, E4, E4, L8, A3, D3, PAT_END
Pattern_74DE:
	db L8, G3, L16, G4, G3, L8, D3, D4, G3, L16, G4, G3, L8, D3, D4, PAT_END
Pattern_74EE:
	db L8, G3, L16, G4, G3, L8, D3, D4, G3, L16, G4, G3, L8, A3, A4, PAT_END
Pattern_74FE:
	db L8, D3, L16, D4, D3, L8, D3, D4, G3, L16, G4, G3, L8, G3, G4, PAT_END
Pattern_750E:
	db L8, D3, L16, D4, D3, L8, D3, D4, D3, L16, D4, D3, L8, D3, D4, PAT_END
Pattern_751E:
	db L8, E3, L16, E4, E3, L8, E3, E4, E3, L16, E4, E3, L8, E3, E4, PAT_END
Pattern_752E:
	db L8, D3, L16, D4, D3, L8, D3, D4, D3, L16, D4, D3, L8, L2, Fs4, PAT_END
; unreferenced
Unused_753E:
	db $36, $3e, $44, $a4, $44
Song16_Ch1:
	dw Pattern_7557
Song16_Ch1_Loop:
	dw Pattern_7562
	LIST_LOOP Song16_Ch1_Loop
Song16_Ch2:
	dw Pattern_755E
	LIST_LOOP Song16_Ch2
Song16_Ch3:
	dw Pattern_757C
	LIST_LOOP Song16_Ch3
Pattern_7557:
	INSTR $20, $00, $81
	db L4T, REST, PAT_END
Pattern_755E:
	INSTR $70, $00, $81
Pattern_7562:
	db L8, Gs4, C4, Ds4, Gs4, As4, Cs4, F4, As4, C5, Ds4, Gs4, C5, Cs5, F4, Gs4
	db Cs5, As4, Cs4, F4, As4, G4, As3, Cs4, G4, PAT_END
Pattern_757C:
	INSTR_WAVE Wave_6EE9, $21
	db L2D, Gs4, L4, Gs3, L2D, Gs4, L4, Gs3, L2D, Gs4, L4, Gs3, PAT_END
Song17_Ch1:
	dw Pattern_75A1
Song17_Ch1_Loop:
	dw Pattern_75AC
	LIST_LOOP Song17_Ch1_Loop
Song17_Ch2:
	dw Pattern_75A8
	LIST_LOOP Song17_Ch2
Song17_Ch3:
	dw Pattern_75EE
	LIST_LOOP Song17_Ch3
Pattern_75A1:
	INSTR $20, $00, $81
	db L4T, REST, PAT_END
Pattern_75A8:
	INSTR $70, $00, $81
Pattern_75AC:
	db L8, Cs5, Gs4, Ds5, Gs4, F5, Gs4, Ds5, Gs4, Fs5, Gs4, F5, Gs4, Ds5, Gs4, F5
	db Gs4, Cs5, Gs4, Ds5, Gs4, F5, Gs4, Ds5, Gs4, Fs5, Gs4, F5, Gs4, Ds5, Gs4, F5
	db Gs4, Gs5, As4, Fs5, As4, F5, As4, Ds5, As4, D5, As4, Ds5, As4, F5, As4, Ds5
	db As4, Ds5, Fs4, Cs5, Fs4, Cs5, Fs4, C5, Fs4, C5, Fs4, As4, Fs4, C5, Fs4, Ds5
	db Fs4, PAT_END
Pattern_75EE:
	INSTR_WAVE Wave_6EE9, $21
	db L1, Cs5, C5, As4, Gs4, Ds4, Fs4, Gs4, Gs4, PAT_END
Song04_Ch2:
	dw Pattern_7604
	LIST_END
Song04_Ch1:
	dw Pattern_7614
Song04_Ch3:
	dw Pattern_7623
Pattern_7604:
	INSTR $b2, $00, $80
	db L8, B5, A5, B5, A5, B5, C6, B5, A5, L2, B5, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7614:
	INSTR $92, $00, $80
	db L8, E5, D5, E5, D5, E5, F5, E5, D5, L2, E5
Pattern_7623:
	INSTR $e9, $6e, $20
	db L8, C6, B5, C6, B5, C6, D6, C6, B5, L4, C6, REST
Song03_Ch2:
	dw Pattern_766F
	dw Pattern_7769
	dw Pattern_7769
	LIST_END
Song03_Ch1:
	dw Pattern_76BF
	dw Pattern_77AA
	dw Pattern_783C
Song03_Ch3:
	dw Pattern_770C
	dw Pattern_77EB
	dw Pattern_77EB
	dw Pattern_77F5
	dw Pattern_77EB
	dw Pattern_77EB
	dw Pattern_77FE
	dw Pattern_77F5
	dw Pattern_77EB
	dw Pattern_77EB
	dw Pattern_77FE
	dw Pattern_77F5
	dw Pattern_7807
	dw Pattern_7811
	dw Pattern_77FE
	dw Pattern_77F5
	dw Pattern_77EB
Song03_Ch4:
	dw Pattern_775B
	dw Pattern_775B
	dw Pattern_781A
	dw Pattern_781A
	dw Pattern_781A
	dw Pattern_781A
Pattern_766F:
	INSTR $c3, $00, $80
	db L8, F4, Fs4, F4, Fs4, Ds4, Ds5, L4, REST, L8, F4, Fs4, F4, Fs4, Ds4, Ds5
	db L4, REST, L8, REST, B4, REST, As4, REST, Gs4, REST, As4, L16, Gs4, As4, L8, Gs4
	db Gs4, Ds4, L4, F4, REST, L8, Fs4, Gs4, Fs4, Gs4, F4, F5, L4, REST, L8, Fs4
	db Gs4, Fs4, Gs4, F4, F5, L4, REST, L8, REST, Fs5, REST, F5, REST, F5, REST, Ds5
	db L8, REST, L16, Ds5, F5, L8, Ds5, D5, L4, Ds5, REST, PAT_END
Pattern_76BF:
	INSTR $74, $00, $80
	db L8, D4, Ds4, D4, Ds4, As3, Fs4, L4, REST, L8, D4, Ds4, D4, Ds4, As3, Fs4
	db L4, REST, L8, REST, D4, REST, D4, REST, C4, REST, D4, D4, C4, C4, B3, L4
	db D4, REST, L8, Ds4, F4, Ds4, F4, D4, D5, L4, REST, L8, Ds4, F4, Ds4, F4
	db D4, D5, L4, REST, L8, REST, Ds5, REST, D5, REST, As4, REST, As4, L8, REST, L16
	db B4, D5, L8, B4, As4, L4, G4, REST, PAT_END
Pattern_770C:
	INSTR_WAVE Wave_6EE9, $20
	db L8, B4, As4, B4, As4, Fs4, Ds3, L4, REST, L8, B4, As4, B4, As4, Fs4, Ds3
	db L4, REST, L8, As3, F4, As3, F3, F3, F3, F3, F4, Gs3, Fs4, Gs3, Fs4, L8D
	db As3, L4, REST, L16, REST, L8, B4, As4, B4, As4, As3, As3, L4, REST, L8, B4
	db As4, B4, As4, As3, As3, L4, REST, L8, Gs3, F4, Gs3, F4, As3, Fs4, As3, Fs4
	db As3, Gs4, As3, Gs4, L8D, Ds4, L4, REST, L16, REST, PAT_END
Pattern_775B:
	db L2D, REST, L8, NOISE1, NOISE2, L2D, REST, L8, NOISE1, NOISE2, L1, REST, REST, PAT_END
Pattern_7769:
	INSTR $c5, $00, $80
	db L16, As4, C5, L2, As4, L8, REST, L4, Ds5, L2D, C5, L4, REST, L16, Gs4, As4
	db L2, Gs4, L8, REST, L4, D5, L16, D5, Ds5, L2, As4, L4D, REST, L16, G4, As4
	db L2, G4, L8, REST, L4, As4, L16, As4, C5, L2, Gs4, L4D, REST, L16, D4, Ds4
	db L2, D4, L8, REST, L4, F4, L4D, Gs4, L2, G4, L8, REST, PAT_END
Pattern_77AA:
	INSTR $84, $00, $41
	db L16, G4, Gs4, L2, G4, L8, REST, L4, G4, L2D, Gs4, L4, REST, L16, F4, G4
	db L2, F4, L8, REST, L4, F4, L16, F4, G4, L2, G4, L4D, REST, L16, D4, C4
	db L2, As3, L8, REST, L4, G4, L16, D4, Ds4, L2, C4, L4D, REST, L16, As3, C4
	db L2, As3, L8, REST, L4, Gs3, L4D, B3, L2, As3, L8, REST, PAT_END
Pattern_77EB:
	db L8, Ds4, Ds4, REST, Ds4, Ds4, Ds4, REST, Ds4, PAT_END
Pattern_77F5:
	db As3, As3, REST, As3, As3, As3, REST, As3, PAT_END
Pattern_77FE:
	db Gs3, Gs3, REST, Gs3, Gs3, Gs3, REST, Gs3, PAT_END
Pattern_7807:
	db L8, Ds4, Ds4, REST, Ds4, D4, D4, REST, D4, PAT_END
Pattern_7811:
	db C4, C4, REST, C4, As3, As3, REST, As3, PAT_END
Pattern_781A:
	db L8, NOISE1, NOISE2, REST, NOISE1, NOISE1, NOISE2, REST, NOISE1, NOISE1, NOISE2, REST, NOISE1, NOISE1, NOISE2, REST
	db NOISE1, NOISE1, NOISE2, REST, NOISE1, NOISE1, NOISE2, REST, NOISE1, NOISE1, NOISE2, REST, NOISE1, REST, NOISE2, REST
	db NOISE2, PAT_END
Pattern_783C:
	INSTR $66, $00, $81
	db L4D, G5, Gs5, L4, G5, L4D, As5, L2, Gs5, L8, REST, L4D, Ds5, F5, L4, G5
	db L4D, Gs5, L2, G5, L8, REST, L4D, Ds5, L4, D5, L4D, D5, G5, F5, L4, C5
	db L4D, Gs5, As5, L4, Gs5, L4D, F5, L2, Ds5, L8, REST, PAT_END
Song15_Ch1:
	dw Pattern_788E
	dw Pattern_7911
	dw Pattern_788E
	dw Pattern_7996
	LIST_END
Song15_Ch2:
	dw Pattern_78AD
	dw Pattern_7938
	dw Pattern_78AD
	dw Pattern_79BA
Song15_Ch3:
	dw Pattern_78D5
	dw Pattern_795E
	dw Pattern_78D5
	dw Pattern_79DD
Song15_Ch4:
	dw Pattern_78FE
	dw Pattern_7984
	dw Pattern_78FE
	dw Pattern_7984
Pattern_788E:
	INSTR $d1, $00, $80
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, E5, Cs5, B4, A4, L16, Cs5, E5, PAT_END
Pattern_78AD:
	INSTR $b2, $00, $80
	db L8, E5, L16, E5, E5, L8, E5, L16, E5, E5, L8, A4, L16, A4, A4, L8
	db A4, REST, Cs5, L16, Cs5, Cs5, L8, Cs5, L16, Cs5, Cs5, L8, E4, L16, E4, E4
	db L8, E4, REST, PAT_END
Pattern_78D5:
	INSTR_WAVE Wave_6EE9, $20
	db L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, D5, L16, E5, E5, L8
	db Fs5, REST, L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, A4, L16, B4
	db B4, L8, Cs5, REST, PAT_END
Pattern_78FE:
	db L8, NOISE1, L4D, REST, L8, NOISE2, NOISE2, NOISE2, REST, L8, NOISE1, L4D, REST, L8, NOISE2, NOISE2
	db NOISE2, REST, PAT_END
Pattern_7911:
	db L8, B4, L16, B4, E5, L8, A4, L16, A4, E5, L8, Gs4, L16, Gs4, E5, L8
	db B4, L16, B4, E5, L8, Cs5, L16, Cs5, E5, L8, A4, L16, A4, E5, L8, B4
	db A4, L16, B4, E5, Fs5, Gs5, PAT_END
Pattern_7938:
	db E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, E4
	db L16, E4, E4, L8, E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, D4, L16
	db D4, D4, L8, D4, REST, PAT_END
Pattern_795E:
	db B4, L16, B4, B4, L8, B4, L16, B4, B4, L8, B4, L16, B4, B4, L8, B4
	db L16, B4, B4, L8, A4, L16, A4, A4, L8, A4, L16, A4, A4, L8, Gs4, L16
	db Gs4, Gs4, L8, Gs4, REST, PAT_END
Pattern_7984:
	db L8, REST, NOISE2, REST, NOISE2, REST, NOISE2, REST, NOISE2, REST, NOISE2, REST, NOISE2, REST, NOISE2, NOISE2
	db REST, PAT_END
Pattern_7996:
	db L8, B4, L16, B4, E5, L8, A4, L16, A4, E5, L8, Gs4, L16, Gs4, E5, L8
	db B4, L16, B4, E5, L8, Cs5, L16, Cs5, E5, L8, B4, L16, B4, E5, L8, A4
	db E5, L4, A5, PAT_END
Pattern_79BA:
	db E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, E4
	db L16, E4, E4, L8, E4, L16, E4, E4, L8, E4, L16, E4, E4, L8, REST, E4
	db L4, Cs5, PAT_END
Pattern_79DD:
	db B4, L16, B4, B4, L8, B4, L16, B4, B4, L8, B4, L16, B4, B4, L8, B4
	db L16, B4, B4, L8, A4, L16, A4, A4, L8, A4, L16, A4, A4, L8, REST, Cs5
	db L4, A4, PAT_END
Song10_Ch2:
	dw Pattern_7A04
	LIST_END
Pattern_7A04:
	INSTR $c2, $00, $40
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, E5, Cs5, B4, L16, A4, Gs4, L8, A4, L2, REST, PAT_END
Song11_Ch2:
	dw Pattern_7A2C
	LIST_END
Song11_Ch3:
	dw Pattern_7A4B
Pattern_7A2C:
	INSTR $c2, $00, $80
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, Cs5, A4, E5, L4, A5, L2, REST, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7A4B:
	INSTR_WAVE Wave_6EE9, $20
	db L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, D5, E5, Fs5, REST, L8
	db A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, E5, Cs5, A4, REST, L1, REST
Song12_Ch2:
	dw Pattern_7A77
	LIST_END
Song12_Ch1:
	dw Pattern_7A96
Song12_Ch3:
	dw Pattern_7AB4
Pattern_7A77:
	INSTR $c2, $00, $80
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, Cs5, A4, E5, L4, A5, L2, REST, PAT_END
Pattern_7A96:
	INSTR $c2, $00, $40
	db L8, D5, L16, D5, E5, L8, Fs5, D5, L4, B4, B4, L8, Cs5, L16, Cs5, C5
	db L8, Cs5, A4, Cs4, Cs5, L4, Cs5, L1, REST, PAT_END
Pattern_7AB4:
	INSTR_WAVE Wave_6EE9, $20
	db L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, D5, E5, L16, Fs5, Fs5
	db L8, Fs5, L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, L8, E5, Cs5, L16
	db A4, A4, L8, REST, L1, REST, PAT_END
Song13_Ch1:
	dw Pattern_7AE9
	LIST_END
Song13_Ch2:
	dw Pattern_7B08
Song13_Ch3:
	dw Pattern_7B25
Song13_Ch4:
	dw Pattern_7B4F
Pattern_7AE9:
	INSTR $c2, $00, $80
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, Cs5, A4, E5, L4, A5, L2, REST, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7B08:
	INSTR $b2, $00, $80
	db L8, D5, L16, D5, E5, L8, Fs5, D5, L4, B4, B4, L8, Cs5, L16, Cs5, C5
	db L8, Cs5, A4, Cs4, Cs5, L4, Cs5, L1, REST
Pattern_7B25:
	INSTR $e9, $6e, $20
	db L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, D5, Fs5, A5, Fs5, D5, A4
	db Fs4, A4, L8, A5, L16, A5, A5, L8, A5, L16, A5, A5, E5, Cs5, A4, Cs5
	db A5, REST, L8, REST, L1, REST
Pattern_7B4F:
	db L8, $0b, $0b, $0b, $0b, L8, $0b, $0b, $0b, REST, L8, $0b, $0b, $0b, $0b, L8
	db $0b, $0b, $0b, REST, L1, REST
Song14_Ch1:
	dw Pattern_7B77
	dw Pattern_7BCE
	LIST_END
Song14_Ch2:
	dw Pattern_7B96
	dw Pattern_7BF2
Song14_Ch3:
	dw Pattern_7BA8
	dw Pattern_7C02
Song14_Ch4:
	dw Pattern_7BBB
	dw Pattern_7C12
Pattern_7B77:
	INSTR $d1, $00, $80
	db L8, A5, L16, A5, Gs5, L8, A5, A5, Fs5, E5, D5, Fs5, L8, E5, L16, E5
	db Ds5, L8, E5, E5, Cs5, B4, A4, L16, Cs5, E5, PAT_END
Pattern_7B96:
	db L8, E5, L4D, REST, L8, A4, A4, A4, REST, Cs5, L4D, REST, L8, E4, E4, E4
	db REST, PAT_END
Pattern_7BA8:
	db L8, A5, L4D, REST, L8, D5, E5, Fs5, REST, L8, A5, L4D, REST, L8, A4, B4
	db Cs5, REST, PAT_END
Pattern_7BBB:
	db L8, NOISE1, L4D, REST, L8, NOISE2, NOISE2, NOISE2, REST, L8, NOISE1, L4D, REST, L8, NOISE2, NOISE2
	db NOISE2, REST, PAT_END
Pattern_7BCE:
	db L8, B4, L16, B4, E5, L8, A4, L16, A4, E5, L8, Gs4, L16, Gs4, E5, L8
	db B4, L16, B4, E5, L8, Cs5, L16, Cs5, E5, L8, B4, L16, B4, E5, L8, A5
	db E5, L4, A5, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7BF2:
	db REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, REST, E4, L4, Cs4
Pattern_7C02:
	db REST, B4, REST, B4, REST, B4, REST, B4, REST, A4, REST, A4, REST, Cs5, L4, A4
Pattern_7C12:
	db L8, REST, $0b, REST, $0b, REST, $0b, REST, $0b, REST, $0b, REST, $0b, L8, REST, $0b
	db $0b, REST
Song09_Ch2:
	dw Pattern_7C2E
	LIST_END
Song09_Ch1:
	dw Pattern_7C63
Song09_Ch3:
	dw Pattern_7C97
Song09_Ch4:
	dw Pattern_7CCB
Pattern_7C2E:
	INSTR $b3, $00, $80
	db L8D, E5, L16, Ds5, L8D, E5, L16, Ds5, L8D, E5, L16, B4, L4, REST, L8D, Cs5
	db L16, C5, L8D, Cs5, L16, C5, L8D, Cs5, L16, Gs4, L4, REST, L8D, Fs4, L16, Gs4
	db L8D, A4, L16, B4, L8D, Cs5, L16, Ds5, L8D, E5, L16, Fs5, L8D, E5, L16, E6
	db PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7C63:
	INSTR $93, $00, $c0
	db L8D, Gs4, L16, G4, L8D, Gs4, L16, G4, L8D, Gs4, L16, Gs4, L4, REST, L8D, E4
	db L16, Ds4, L8D, E4, L16, Ds4, L8D, E4, L16, E4, L4, REST, L8D, Ds4, L16, Ds4
	db L8D, E4, L16, Fs4, L8D, Gs4, L16, A4, L8D, B4, L16, Cs5, L8D, Gs4, L16, Gs4
Pattern_7C97:
	INSTR $e9, $6e, $a0
	db L8D, B4, L16, As4, L8D, B4, L16, As4, L8D, B4, L16, E5, L4, REST, L8D, A4
	db L16, Gs4, L8D, A4, L16, Gs4, L8D, A4, L16, Cs5, L4, REST, L8D, B4, L16, E4
	db L8D, Fs4, L16, Gs4, L8D, A4, L16, B4, L8D, Cs5, L16, Ds5, L8D, E5, L16, E4
Pattern_7CCB:
	db L8D, $0b, L16, D2, L8D, $0b, L16, D2, L8D, $0b, L16, D2, L4, REST, L8D, $0b
	db L16, D2, L8D, $0b, L16, D2, L8D, $0b, L16, D2, L4, REST, L8D, $0b, L16, D2
	db L8D, $0b, L16, D2, L8D, $0b, L16, D2, L4, REST, L8D, $0b, L16, D2
Song01_Ch1:
	dw Pattern_7D2E
	LIST_LOOP Song01_Ch2_Loop
Song01_Ch2:
	dw Pattern_7D29
Song01_Ch2_Loop:
	dw Pattern_7D35
Song01_Ch2_Loop2:
	dw Pattern_7D5B
	dw Pattern_7D82
	dw Pattern_7D5B
	dw Pattern_7DA4
	dw Pattern_7DC6
	LIST_LOOP Song01_Ch2_Loop2
Song01_Ch3:
	dw Pattern_7D3B
Song01_Ch3_Loop:
	dw Pattern_7D6C
	dw Pattern_7D93
	dw Pattern_7D6C
	dw Pattern_7DB5
	dw Pattern_7E07
	LIST_LOOP Song01_Ch3_Loop
Song01_Ch4:
	dw Pattern_7D3E
Song01_Ch4_Loop:
	dw Pattern_7D41
	LIST_LOOP Song01_Ch4_Loop
Pattern_7D29:
	INSTR $60, $00, $81
	db PAT_END
Pattern_7D2E:
	INSTR $20, $00, $81
	db L4T, REST, PAT_END
Pattern_7D35:
	db L4, REST, Ds5, F5, G5, PAT_END
Pattern_7D3B:
	db L1, REST, PAT_END
Pattern_7D3E:
	db L1, REST, PAT_END
Pattern_7D41:
	db L4, REST, NOISE1, REST, NOISE1, REST, L8, NOISE1, NOISE1, L4, REST, NOISE1, L4, REST, NOISE1, REST
	db NOISE1, REST, L8, NOISE1, NOISE1, REST, REST, NOISE1, NOISE1, PAT_END
Pattern_7D5B:
	db L4D, Gs5, L8, As5, L4D, Gs5, L8, G5, L4D, G5, L8, F5, L4D, G5, L8, F5
	db PAT_END
Pattern_7D6C:
	INSTR_WAVE Wave_6EC9, $20
	db L8, Gs5, C6, Ds6, G6, Gs5, C6, Ds6, G6, Gs5, Cs6, D6, F6, Gs5, Cs6, D6
	db F6, PAT_END
Pattern_7D82:
	db L4D, F5, L8, Ds5, L4D, F5, L8, Ds5, L4D, Ds5, L8, Cs5, L4D, C5, L8, Ds5
	db PAT_END
Pattern_7D93:
	db G5, As5, Cs6, F6, G5, As5, Cs6, F6, Ds5, F5, G5, As5, Ds5, G5, As5, Cs6
	db PAT_END
Pattern_7DA4:
	db L4D, F5, L8, Ds5, L4D, F5, L8, Ds5, L4D, Ds5, L8, Cs5, L4D, C5, L8, As4
	db PAT_END
Pattern_7DB5:
	db G5, As5, Cs6, F6, G5, As5, Cs6, F6, Ds5, F5, G5, As5, Ds5, G5, As5, Cs6
	db PAT_END
Pattern_7DC6:
	db L4D, C5, L8, Cs5, L4D, C5, L8, As4, L4D, As4, L8, A4, L4D, As4, L8, C5
	db L4D, Cs5, L8, Ds5, L4D, Cs5, L8, C5, L4D, C5, L8, As4, L4D, C5, L8, Cs5
	db L4D, Ds5, L8, D5, L4D, Ds5, L8, E5, L4D, G5, L8, F5, L4D, Gs5, L8, F5
	db L4D, E5, L8, Ds5, L4D, Cs5, L8, C5, L8, Gs4, Ds4, F4, C5, L4, Gs4, REST
	db PAT_END
Pattern_7E07:
	db C5, E5, G5, As5, C5, G5, As5, C6, F5, C6, Ds6, F6, F5, C6, Ds6, F6
	db As4, Cs5, F5, As5, As4, Cs5, F5, Gs5, Ds5, G5, As5, Cs6, Ds5, As5, Cs6, F6
	db C5, Ds5, G5, As5, C5, G5, As5, C6, D5, F5, Gs5, C6, D5, F5, Gs5, D6
	db Ds5, G5, As5, Cs6, Ds5, As5, Cs6, Ds6, L2D, Gs5, L4, REST, PAT_END
Song02_Ch2:
	dw Pattern_7E4E
	LIST_END
Song02_Ch1:
	dw Pattern_7E5E
Song02_Ch3:
	dw Pattern_7E6D
Song02_Ch4:
	dw Pattern_7E7D
Pattern_7E4E:
	INSTR $b1, $00, $80
	db L4D, REST, L16, As5, As5, L8D, Ds6, L16, As5, L2, Ds6, PAT_END
; no PAT_END: the channel never gets this far (ch1 ends the song first)
Pattern_7E5E:
	INSTR $91, $00, $80
	db L4D, REST, L16, F5, F5, L8D, As5, L16, G5, L2, As5
Pattern_7E6D:
	INSTR $e9, $6e, $20
	db L4D, REST, L16, D5, D5, L8D, G5, L16, Ds5, L4, G5, REST
Pattern_7E7D:
	db L4D, REST, L16, D2, D2, L8D, $0b, L16, D2, L32, D2, D2, D2, D2, D2, D2
	db D2, D2, L4, REST
Song08_Ch2:
	dw Pattern_7EBB
	dw Pattern_7F28
	dw Pattern_7EBB
	dw Pattern_7F73
	LIST_LOOP Song08_Ch2
Song08_Ch1:
	dw Pattern_7EE5
	dw Pattern_7F4F
	dw Pattern_7EE5
	dw Pattern_7F96
	LIST_LOOP Song08_Ch1
Song08_Ch3:
	dw Pattern_7EFB
	dw Pattern_7F61
	dw Pattern_7EFB
	dw Pattern_7FAE
	LIST_LOOP Song08_Ch3
Song08_Ch4:
	dw Pattern_7F11
	LIST_LOOP Song08_Ch4
Pattern_7EBB:
	INSTR $82, $00, $80
	db L8, F5, L16, F5, F5, F5, C5, As4, C5, L8, F5, L16, F5, F5, F5, G5
	db A5, G5, L8, F5, L16, F5, F5, G5, F5, E5, F5, L16, G5, A5, G5, A5
	db L8, G5, L16, Fs5, G5, PAT_END
Pattern_7EE5:
	INSTR $62, $00, $80
	db L8, REST, A4, REST, G4, REST, A4, REST, As4, REST, A4, REST, A4, REST, G4, REST
	db G4, PAT_END
Pattern_7EFB:
	INSTR_WAVE Wave_6EE9, $20
	db L8, F5, F5, C5, E5, F5, F5, C5, G5, F5, F5, E5, F5, D5, F5, C5
	db E5, PAT_END
Pattern_7F11:
	db L8, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, NOISE2, NOISE1, L16, NOISE2
	db NOISE2, NOISE1, L8, NOISE2, L16, NOISE1, PAT_END
Pattern_7F28:
	db L8, As5, L16, As5, As5, As5, F5, Ds5, F5, L8, As5, L16, As5, As5, As5, C6
	db D6, C6, L8, As5, L16, As5, A5, L8, G5, L16, G5, F5, L16, E5, F5, E5
	db F5, L8, E5, L16, D5, E5, PAT_END
Pattern_7F4F:
	db L8, REST, As4, REST, C5, REST, As4, REST, C5, REST, As4, REST, As4, REST, As4, REST
	db As4, PAT_END
Pattern_7F61:
	db L8, As4, F5, F5, F5, As4, F5, F5, F5, As4, F5, E5, G5, A4, E5, C5
	db G5, PAT_END
Pattern_7F73:
	db L8, C6, L16, C6, C6, C6, As5, Gs5, As5, L8, C6, L16, C6, C6, C6, As5
	db Gs5, As5, L8, C6, L16, C5, D5, L8, E5, L16, C5, A5, L4, G5, L16, F5
	db L8D, F6, PAT_END
Pattern_7F96:
	db L8, REST, C5, REST, C5, REST, C5, REST, C5, REST, L16, As4, As4, L8, As4, L16
	db As4, As4, L4, As4, L8, A4, REST, PAT_END
Pattern_7FAE:
	db L8, Gs4, Gs5, Ds5, Gs5, Gs4, Gs5, Ds5, Gs5, C5, L16, E5, E5, L8, E5, L16
	db E5, E5, L4, E5, L8, F5, REST, PAT_END
	ds 42, 0	; unused
