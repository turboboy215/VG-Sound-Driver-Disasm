; Link's Awakening DX music, bank $1E: songs, bank $1E $5000-$7FFF

Song1A_Header:
	SONG $00, LengthTable_4AE8, Song1A_Ch1, Song1A_Ch2, Song1A_Ch3, 0
Song1A_Ch1:
	dw Pattern_6E13
	dw Pattern_506F
	dw Pattern_6EAC
	dw Pattern_50A1
	dw Pattern_6EA8
	dw Pattern_6E22
	dw Pattern_50A8
	dw Pattern_6E09
	dw Pattern_6D2A
	dw Pattern_5147
	dw Pattern_5147
	dw Pattern_6D15
	dw Pattern_6EB0
	dw Pattern_6D10
	dw Pattern_6E09
	dw Pattern_5151
	dw Pattern_51E3
	LIST_END
Song1A_Ch2:
	dw Pattern_50B7
	dw Pattern_6EAC
	dw Pattern_6DFF
	dw Pattern_50ED
	dw Pattern_6EA8
	dw Pattern_50F2
	dw Pattern_6DCD
	dw Pattern_5147
	dw Pattern_6E09
	dw Pattern_5147
	dw Pattern_6D15
	dw Pattern_6EB0
	dw Pattern_6DBE
	dw Pattern_5151
	dw Pattern_6D2D
	dw Pattern_6E18
	dw Pattern_51E3
	LIST_END
Song1A_Ch3:
	dw Pattern_6E63
	dw Pattern_5100
	dw Pattern_6EAC
	dw Pattern_5131
	dw Pattern_6EA8
	dw Pattern_6E54
	dw Pattern_5138
	dw Pattern_6E72
	dw Pattern_6D27
	dw Pattern_5147
	dw Pattern_6E77
	dw Pattern_5147
	LIST_LOOP UnusedList_6D30
Pattern_506F:
	REPEAT $02
	db L8, Gs2, Gs3, Gs2, B2, B3
	REPEAT_END
	db As2, As3, As2, Cs3, Cs4, As2, As3, A2, A3
	REPEAT $02
	db L8, Gs2, Gs3, Gs2, B2, B3
	REPEAT_END
	db C3, C4, C3, Ds3, Ds4, C3, C4, B2, B3
	REPEAT $02
	db As2, As3, As2, Cs3, Cs4
	REPEAT_END
	db E3, E4, E3, G3, G4, PAT_END
Pattern_50A1:
	db L8, As2, As3, As2, Cs3, Cs4, PAT_END
Pattern_50A8:
	db L8, E3, E4, E3, G3, G4, L8, As3, As4, As3, Cs4, Cs5, L1, REST, PAT_END
Pattern_50B7:
	INSTR $97, $86, $80
	db L4D, Gs4, L2, Cs4, L8D, REST, L16, Ds4, E4, Fs4, L4, G4, L2, G5, L4D, REST
	db Gs4, L2, Cs4, L8D, REST, L16, Ds4, E4, Cs5, L4, C5, L2, B4, L4D, REST
	INSTR $b7, $86, $80
	db L4D, As4, L2, Ds4, L8D, REST, L16, Fs4, G4, Gs4, L4, A4, L4D, A5, PAT_END
Pattern_50ED:
	db L4, C4, L4D, C5, PAT_END
Pattern_50F2:
	INSTR $89, $86, $81
	db L4, B4, L4D, B5, L2D, Ds7, REST, L8, REST, PAT_END
Pattern_5100:
	REPEAT $02
	db L8, Cs2, Cs3, Cs2, E2, E3
	REPEAT_END
	db Ds2, Ds3, Ds2, Fs2, Fs3, Ds2, Ds3, D2, D3
	REPEAT $02
	db Cs2, Cs3, Cs2, E2, E3
	REPEAT_END
	db F2, F3, F2, Gs2, Gs3, F2, F3, E2, E3
	REPEAT $02
	db Ds2, Ds3, Ds2, Fs2, Fs3
	REPEAT_END
	db A2, A3, A2, C3, C4, PAT_END
Pattern_5131:
	db L8, Ds2, Ds3, Ds2, Fs2, Fs3, PAT_END
Pattern_5138:
	db L8, A2, A3, A2, C3, C4, L8, Ds3, Ds4, Ds3, Fs3, Fs4, L1, REST, PAT_END
Pattern_5147:
	db L16, B4, Ds5, F5, A5, B5, Ds6, F6, A6, PAT_END
Pattern_5151:
	db L4, F4, As3, REST, L16, As3, C4, D4, Ds4, L4, REST, Ds4, Gs3, L16, Gs3, As3
	db C4, D4, L8, REST, F6, As5, F3, As2, As5, L16, As5, C6, D6, L8D, Ds6, L8
	db Ds6, Gs5, Ds3, Gs2, Gs5, L16, Gs5, As5, C6, D6, L8, REST, F7, As6, F4, As3
	db As6, L16, As6, C7, D7, L8D, Ds7, L8, Ds7, Gs6, Ds4, Gs3, Gs6, L16, Gs6, As6
	db C7, D7, L8, Ds4, D6, G5, Ds4, Ds3, G5, L16, G5, A5, As5, C6, L8, D4
	db C6, F5, F6, L16, D4, F4, A4, C5, D5, F5, A5, C6, L8, C4, As5, Ds5
	db C4, C5, Ds5, L16, Ds5, F5, G5, A5, L8, As3, A5, D5, D6, L16, As3, D4
	db F4, A4, As4, D5, F5, A5, L8, Gs3, G5, L16, C5, Ds5, G5, C6, L8, Fs3
	db F5, L16, As4, L32, REST, L16, Cs5, L32, REST, L16, F5, L32, REST, L16, As5, L2
	db REST, PAT_END
Pattern_51E3:
	TEMPO LengthTable_4AD9
	db L16, C4, F4, As4
	REPEAT $02
	db F2, REST, REST
	REPEAT_END
	db F4, G4, A4, As4, C5, REST, F2, F4, As4, Ds5, F2, REST, REST, F2, REST, As4
	db Ds5, Gs5, REST, F2, F2, REST, F2, REST, PAT_END
Song11_Header:
	SONG $00, LengthTable_4AD9, Song11_Ch1, Song11_Ch2, Song11_Ch3, Song11_Ch4
Song11_Ch1:
	dw Pattern_6D15
Song11_Ch1_Loop:
	dw Pattern_6DE1
	dw Pattern_5253
	LIST_LOOP Song11_Ch1_Loop
Song11_Ch2:
	dw Pattern_6E31
	dw Pattern_5234
	LIST_LOOP Song11_Ch2
Song11_Ch3:
	dw Pattern_6E63
	dw Pattern_5274
	LIST_LOOP Song11_Ch3
Song11_Ch4:
	dw Pattern_5293
	LIST_LOOP Song11_Ch4
Pattern_5234:
	db L8, As4, REST, L4D, F4, L16, As4, REST, As4, C5, D5, Ds5, L2, F5, REST, L8
	db As5, REST, L4D, F5, L16, As5, REST, As5, C6, D6, Ds6, L2, F6, REST, PAT_END
Pattern_5253:
	db L8, Gs3, REST, L4D, Ds3, L16, Gs3, REST, Gs3, As3, C4, Ds4, Fs4, L8D, REST, L1
	db REST, L8, Gs4, REST, L4, Ds4, L16, Gs4, Ds4, C4, Gs3, As3, L8D, REST, L2D, REST
	db PAT_END
Pattern_5274:
	REPEAT $02
	CH3_FADEOUT_ON
	db L8, As2, As2, REST, As2
	REPEAT_END
	REPEAT $02
	db Gs2, Gs2, REST, Gs2
	REPEAT_END
	REPEAT $02
	db Fs2, Fs2, REST, Fs2
	REPEAT_END
	REPEAT $02
	db Gs2, Gs2, REST, Gs2
	REPEAT_END
	db PAT_END
Pattern_5293:
	REPEAT $07
	db L8, NOISE_1A, L16, NOISE_1A, NOISE_1A
	REPEAT_END
	REPEAT $04
	db NOISE_1A
	REPEAT_END
	REPEAT $06
	db L8, NOISE_1A, L16, NOISE_1A, NOISE_1A
	REPEAT_END
	REPEAT $08
	db NOISE_1A
	REPEAT_END
	db PAT_END
Song5D_Header:
	SONG $00, LengthTable_4AE8, Song14_Ch1, Song5D_Ch2, Song14_Ch1, 0
Song5D_Ch2:
	dw Pattern_6E2C
	dw Pattern_53DA
	LIST_LOOP Song5D_Ch2
Song23_Header:
	SONG $00, LengthTable_4AAC, Song23_Ch1, Song23_Ch2, Song23_Ch3, Song23_Ch4
Song23_Ch2:
	dw Pattern_6DE1
	dw Pattern_53CE
	dw Pattern_6EA0
	dw Pattern_6D15
	dw Pattern_6EAC
	dw Pattern_6D27
Song23_Ch2_Loop:
	dw Pattern_6DEB
	dw Pattern_5498
	dw Pattern_54D7
	dw Pattern_54D7
	dw Pattern_54D7
	dw Pattern_54DE
	dw Pattern_5498
	dw Pattern_54D7
	dw Pattern_54D7
	dw Pattern_54D7
	dw Pattern_54DE
	LIST_LOOP UnusedList_553B
Song23_Ch1:
	dw Pattern_6E7C
	dw Pattern_6DD2
	dw Pattern_5411
	dw Pattern_6EA0
	dw Pattern_6D15
	dw Pattern_6EAC
	dw Pattern_6D27
Song23_Ch1_Loop:
	dw Pattern_6E40
	dw Pattern_542A
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5450
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5461
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_542A
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5450
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5461
	dw Pattern_543B
	dw Pattern_6E91
	dw Pattern_6E40
	dw Pattern_5472
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6DF0
	dw Pattern_6E7C
	dw Pattern_54AB
	dw Pattern_6E94
	dw Pattern_54AB
	dw Pattern_6E8E
	dw Pattern_54BA
	dw Pattern_6E7C
	dw Pattern_6DF0
	dw Pattern_54C2
	dw Pattern_6E40
	dw Pattern_542A
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5450
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5461
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_542A
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5450
	dw Pattern_543B
	dw Pattern_6E40
	dw Pattern_5461
	dw Pattern_543B
	dw Pattern_6E91
	dw Pattern_6E40
	dw Pattern_5472
	dw Pattern_543B
	dw Pattern_6D2A
	dw Pattern_543B
	dw Pattern_6DF0
	dw Pattern_6E7C
	dw Pattern_54AB
	dw Pattern_6E94
	dw Pattern_54AB
	dw Pattern_6E8E
	dw Pattern_54BA
	dw Pattern_6E7C
	dw Pattern_6DE1
	dw Pattern_54C2
	LIST_LOOP UnusedList_5531
Song23_Ch3:
	dw Pattern_6E54
	dw Pattern_541D
	dw Pattern_6EA0
	dw Pattern_6D15
	dw Pattern_6EAC
	dw Pattern_6D27
Song23_Ch3_Loop:
	dw Pattern_6E59
	dw Pattern_5482
	dw Pattern_54F3
	dw Pattern_6E54
	dw Pattern_5508
	dw Pattern_6E59
	dw Pattern_5482
	dw Pattern_54F3
	dw Pattern_6E54
	dw Pattern_5508
	LIST_LOOP UnusedList_5545
Song23_Ch4:
	dw Pattern_5518
	dw Pattern_6EA0
	dw Pattern_602D
	dw Pattern_6EAC
	dw Pattern_551D
Song23_Ch4_Loop:
	dw Pattern_5520
	LIST_LOOP Song23_Ch4_Loop
Pattern_53CE:
	db L8, D5, Cs5, C5, B4, D5, Ds5, E5, F5, L4, REST, PAT_END
Pattern_53DA:
	REPEAT $06
	db L32, B4, As4
	REPEAT_END
	REPEAT $0a
	db As4, A4
	REPEAT_END
	INSTR $68, $00, $81
	REPEAT $06
	db A4, Gs4
	REPEAT_END
	REPEAT $0a
	db Gs4, G4
	REPEAT_END
	INSTR $a8, $00, $81
	REPEAT $06
	db L32, Cs5, C5
	REPEAT_END
	REPEAT $0a
	db C5, B4
	REPEAT_END
	INSTR $78, $00, $81
	REPEAT $06
	db B4, As4
	REPEAT_END
	REPEAT $0a
	db As4, A4
	REPEAT_END
	db PAT_END
Pattern_5411:
	db L8, F5, E5, Ds5, D5, F5, Fs5, G5, Gs5, L4, REST, PAT_END
Pattern_541D:
	CH3_FADEOUT_ON
	db L8, Gs5, G5, Fs5, F5, Gs5, A5, As5, B5, L4, REST, PAT_END
Pattern_542A:
	db L16, G4, A4, REST, L1, As4, L4D, REST, L16, G4, A4, REST, As4, L8, REST, Cs5
	db PAT_END
Pattern_543B:
	INSTR $92, $00, $c0
	db L16, G2, REST, G2, G3, REST, C3, Cs3, REST, G2, REST, Gs2, REST, Gs2, Cs2, REST
	db PAT_END
Pattern_5450:
	db L16, REST, L8, As5, L16, REST, As5, REST, LEN9, As5, L32, REST, L2, As5, L8, REST
	db PAT_END
Pattern_5461:
	db L16, REST, L8, Cs6, L16, REST, Cs6, REST, LEN9, Cs6, L32, REST, L2, Cs6, L8, REST
	db PAT_END
Pattern_5472:
	db L16, G4, A4, REST, L1, As4, L2, REST, L16, REST, G4, A4, As4, Ds5, D5, PAT_END
Pattern_5482:
	REPEAT $14
	CH3_FADEOUT_ON
	db L16, C4, C4, REST, C4, C5, REST, F4, Fs4, REST, C4, REST, Cs4, REST, Cs4, Fs3
	db REST
	REPEAT_END
	db PAT_END
Pattern_5498:
	db L16, Cs2
	REPEAT $7f
	db C2
	REPEAT_END
	db L16, Cs2
	REPEAT $7f
	db C2
	REPEAT_END
	db L16, Cs2
	REPEAT $3f
	db C2
	REPEAT_END
	db PAT_END
Pattern_54AB:
	db L16, E5, E5, E5, Ds5, L4, REST, L16, D5, REST, REST, Cs5, L4, REST, PAT_END
Pattern_54BA:
	db L16, E5, E5, E5, Ds5, L2D, REST, PAT_END
Pattern_54C2:
	db L16, As4, As4, REST, As4, REST, As4, REST, Ds5, REST, Ds5, L8, Ds5
	DROP_ON
	db L16, REST, D4, A3, F3
	DROP_OFF
	db PAT_END
Pattern_54D7:
	db L16, G2
	REPEAT $0f
	db Fs2
	REPEAT_END
	db PAT_END
Pattern_54DE:
	db L16, F4, F4, REST, F4, REST, F4, REST, F4, REST, As4, L8, As4
	DROP_ON
	db L16, REST, A3, F3, D3
	DROP_OFF
	db PAT_END
Pattern_54F3:
	REPEAT $03
	db L16, Fs4, Fs4, REST, Fs4, Fs5, REST, B4, C5, REST, Fs4, REST, G4, REST, G4, C4
	db REST
	REPEAT_END
	db PAT_END
Pattern_5508:
	db L16, C4, C4, REST, C4, REST, C4, REST, F4, REST, F4, F4, REST, L4, REST, PAT_END
Pattern_5518:
	db L1, REST, L4, REST, PAT_END
Pattern_551D:
	db L8D, REST, PAT_END
Pattern_5520:
	REPEAT $02
	db L16, NOISE_1A, NOISE_1A, NOISE_1A, NOISE_15
	REPEAT_END
	db NOISE_1A, NOISE_1A, NOISE_15, NOISE_1A, NOISE_1A, NOISE_1A, NOISE_1A, NOISE_1A, PAT_END
UnusedList_5531:
	dw Pattern_5551
	dw Pattern_5551
	dw Pattern_5561
	LIST_LOOP Song23_Ch1_Loop
UnusedList_553B:
	dw Pattern_557C
	dw Pattern_557C
	dw Pattern_55A8
	LIST_LOOP Song23_Ch2_Loop
UnusedList_5545:
	dw Pattern_6E59
	dw Pattern_55EC
	dw Pattern_55EC
	dw Pattern_5615
	LIST_LOOP Song23_Ch3_Loop
Pattern_5551:
	INSTR $c4, $83, $80
	db L16, Cs2
	REPEAT $1f
	db C2
	REPEAT_END
	db E2
	REPEAT $1f
	db Ds2
	REPEAT_END
	db PAT_END
Pattern_5561:
	db L16, G2
	REPEAT $0d
	db Fs2
	REPEAT_END
	db G2, Gs2
	REPEAT $0f
	db A2
	REPEAT_END
	db G2
	REPEAT $0e
	db Fs2
	REPEAT_END
	db G2, Gs2
	REPEAT $07
	db A2
	REPEAT_END
	db As2, L2, REST, PAT_END
Pattern_557C:
	INSTR $84, $86, $80
	REPEAT $02
	db L16, G2, G2, REST, G2, G3, REST, C3, Cs3, REST, G2, REST, Gs2, REST, Gs2, Cs2
	db REST
	REPEAT_END
	REPEAT $02
	db As2, As2, REST, As2, As3, REST, Ds3, E3, REST, As2, REST, B2, REST, B2, F2, REST
	REPEAT_END
	db PAT_END
Pattern_55A8:
	db L16, Cs3, Cs3, REST, Cs3, Cs4, REST, Fs3, Gs3, REST, Cs3
	REPEAT $02
	db REST, D3
	REPEAT_END
	db Gs2, REST, E3, E3, REST, E3, E4, REST, A3, As3, REST, E3
	REPEAT $02
	db REST, F3
	REPEAT_END
	db B2, REST, Cs3, Cs3, REST, Cs3, Cs4, REST, Fs3, Gs3, REST, Cs3
	REPEAT $02
	db REST, D3
	REPEAT_END
	db Gs2, REST, L8, E3, E3, E4, L16, F3, Fs3, REST, Fs3, L8D, Fs4, L16, Fs3, Fs2
	db Fs3, PAT_END
Pattern_55EC:
	REPEAT $02
	CH3_FADEOUT_ON
	db L16, C4, C4, REST, C4, C5, REST, F4, Fs4, REST, C4, REST, Cs4, REST, Cs4, Fs3
	db REST
	REPEAT_END
	REPEAT $02
	db Ds4, Ds4, REST, Ds4, Ds5, REST, Gs4, A4, REST, Ds4, REST, E4, REST, E4, As3, REST
	REPEAT_END
	db PAT_END
Pattern_5615:
	db L16, Fs4, Fs4, REST, Fs4, Fs5, REST, B4, Cs5, REST, Fs4, REST, G4, REST, G4, Cs4
	db REST, A4, A4, REST, A4, A5, REST, D5, Ds5, REST, A4, REST, As4, REST, As4, E4
	db REST, Fs4, Fs4, REST, Fs4, Fs5, REST, B4, Cs5, REST, Fs4, REST, G4, REST, G4, Cs4
	db REST, L8, A4, A4, A5, L16, As4, B4, REST, B4, L8D, B5, L16, B4, B3, B4
	db PAT_END
Song12_Header:
	SONG $00, LengthTable_4AF7, Song12_Ch1, Song12_Ch2, Song12_Ch3, 0
Song12_Ch1:
	dw Pattern_6DE1
	dw Pattern_56A7
	dw Pattern_6D20
	dw Pattern_6D20
	LIST_LOOP UnusedList_5745
Song12_Ch2:
	dw Pattern_6D9B
	dw Pattern_56BC
	dw Pattern_6E45
	dw Pattern_56C7
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_56BC
	dw Pattern_6E45
	dw Pattern_56C7
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_6E27
	dw Pattern_56E3
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_6D82
	dw Pattern_56ED
	LIST_LOOP UnusedList_575F
Song12_Ch3:
	dw Pattern_6E59
	dw Pattern_56F9
	dw Pattern_56F9
	dw Pattern_6E54
	dw Pattern_5735
	dw Pattern_6E59
	dw Pattern_5724
	dw Pattern_5724
	LIST_LOOP UnusedList_5791
Pattern_56A7:
	REPEAT $10
	db L1, REST
	REPEAT_END
	db L4, REST, L16, F2, B2, F3, B3, F4, B4, F5, B5, L1, REST, L4, REST, PAT_END
Pattern_56BC:
	REPEAT $02
	db L8, E6, G6, Fs6, A6, L1D, REST
	REPEAT_END
	db PAT_END
Pattern_56C7:
	db L16, E4, G4, Fs4, A4, L2, Ds5, REST, L2D, REST, PAT_END
Pattern_56D2:
	db L2D, REST, L8, REST, L16, B6, As6
	REPEAT $0d
	db L32, B6, As6
	REPEAT_END
	db B6, L4, REST, PAT_END
Pattern_56E3:
	db L16, E6, G6, B6, As6, L1, D7, L2D, REST, PAT_END
Pattern_56ED:
	db L4, REST
	REPEAT $0d
	db L32, B6, As6
	REPEAT_END
	db B6, L1, REST, PAT_END
Pattern_56F9:
	CH3_FADEOUT_ON
	db L8, E2, REST, L2, REST, L8D, REST, L16, E2, E2, L8D, REST, L2D, REST, L8, E2
	db E2, L2, REST, L8D, REST, L16, E2, L8, E2, REST, L2D, REST, L8, E2, REST, L2
	db REST, L8D, REST, L16, E2, L8, E2, REST, L2D, REST
Pattern_5724:
	CH3_FADEOUT_ON
	db L8, E2, E2, L2, REST, L8D, REST, L16, E2, E2, E2, L2D, REST, L8, E2, PAT_END
Pattern_5735:
	CH3_FADEOUT_OFF
	db L16, E2, G2, B2, As2, L1, D3, L2, REST, L16, Ds3, B2, G2, E2, PAT_END
UnusedList_5745:
	dw Pattern_6E36
	dw Pattern_57B1
	dw Pattern_6E40
	dw Pattern_57DB
	dw Pattern_6D9B
	dw Pattern_6EB4
	dw Pattern_5808
	dw Pattern_6DE1
	dw Pattern_56A7
	dw Pattern_6D20
	dw Pattern_6D20
	LIST_LOOP Song12_Ch1
UnusedList_575F:
	dw Pattern_6E36
	dw Pattern_5814
	dw Pattern_6E40
	dw Pattern_583E
	dw Pattern_6EB4
	dw Pattern_6D15
	dw Pattern_6D9B
	dw Pattern_56BC
	dw Pattern_6E45
	dw Pattern_56C7
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_56BC
	dw Pattern_6E45
	dw Pattern_56C7
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_6E27
	dw Pattern_56E3
	dw Pattern_6D9B
	dw Pattern_56D2
	dw Pattern_6D82
	dw Pattern_56ED
	LIST_LOOP Song12_Ch2
UnusedList_5791:
	dw Pattern_6E63
	dw Pattern_586B
	dw Pattern_6E54
	dw Pattern_589B
	dw Pattern_6EB4
	dw Pattern_6D15
	dw Pattern_6E59
	dw Pattern_56F9
	dw Pattern_56F9
	dw Pattern_6E54
	dw Pattern_5735
	dw Pattern_6E59
	dw Pattern_5724
	dw Pattern_5724
	LIST_LOOP Song12_Ch3
Pattern_57B1:
	db L8, B2, Cs3, L2, D3, L4, REST, L8, B2, Cs3, L4D, D3, L8, G3, Fs3, B2
	db L2, Cs3, L1D, REST, L8, B2, Cs3, L2, D3, L4, REST, L8, B2, Cs3, L4D, D3
	db L8, Fs3, B3, As3, L2, As3, REST, L1, REST, PAT_END
Pattern_57DB:
	db L16, B3, C4, L2, Cs4, L8, REST, L16, B3, C4, Cs4, L8D, REST, L4, G4, L16
	db Fs4, F4, B4, C5, L2, Cs5, L16, D5, REST, B4, C5, Cs5, D5, L8, REST, L4
	db G5, L16, Fs5, F5, E5, F5, Fs5, B4, C5, REST, L4D, REST, PAT_END
Pattern_5808:
	db L4D, REST, L16, B6, As6
	REPEAT $09
	db L32, B6, As6
	REPEAT_END
	db PAT_END
Pattern_5814:
	db L8, E3, Fs3, L2, G3, L4, REST, L8, E3, Fs3, L4D, G3, L8, C4, B3, E3
	db L2, F3, L1D, REST, L8, E3, Fs3, L2, G3, L4, REST, L8, E3, Fs3, L4D, G3
	db L8, B3, E4, Ds4, L2, D4, REST, L1, REST, PAT_END
Pattern_583E:
	db L16, E4, F4, L2, Fs4, L8, REST, L16, E4, F4, Fs4, L8D, REST, L4, C5, L16
	db B4, As4, E5, F5, L2, Fs5, L16, G5, REST, E5, F5, Fs5, G5, L8, REST, L4
	db C5, L16, B5, As5, E6, F6, Fs6, B5, C6, REST, L4D, REST, PAT_END
Pattern_586B:
	REPEAT $02
	CH3_FADEOUT_ON
	db L8, E2, E2, L2D, REST
	REPEAT_END
	REPEAT $02
	db L8, D2, D2, L2D, REST
	REPEAT_END
	REPEAT $02
	db L8, E2, E2, REST, E2, REST, E2, L16, E2, E2, E2, E2
	REPEAT_END
	REPEAT $02
	db L8, C3, C3, REST, C3, REST, C3, L16, C3, C3, C3, C3
	REPEAT_END
	db PAT_END
Pattern_589B:
	REPEAT $04
	db L16, E2
	REPEAT_END
	db E3
	REPEAT $07
	db E2
	REPEAT_END
	REPEAT $04
	db E2
	REPEAT_END
	db E3
	REPEAT $07
	db E2
	REPEAT_END
	REPEAT $04
	db E2
	REPEAT_END
	db E3
	REPEAT $07
	db E2
	REPEAT_END
	REPEAT $04
	db E2
	REPEAT_END
	db E3
	REPEAT $07
	db E2
	REPEAT_END
	db E3, F3, Fs3, B2, C3, REST, L4D, REST, PAT_END
Song5A_Header:
	SONG $00, LengthTable_4ACA, Song5A_Ch1, Song5A_Ch2, Song5A_Ch3, 0
Song5A_Ch1:
	dw Pattern_6D27
Song5A_Ch1_Loop:
	dw Pattern_6D78
	dw Pattern_5918
	dw Pattern_5921
	dw Pattern_5918
	dw Pattern_6E09
	dw Pattern_5929
	dw Pattern_5931
	dw Pattern_5931
	dw Pattern_5931
	dw Pattern_5931
	LIST_LOOP Song5A_Ch1_Loop
Song5A_Ch2:
	dw Pattern_6E09
	dw Pattern_5918
	dw Pattern_5921
	dw Pattern_6DC3
	dw Pattern_5918
	dw Pattern_5929
	dw Pattern_6DA5
	dw Pattern_5931
	dw Pattern_5931
	dw Pattern_6DC3
	dw Pattern_5931
	dw Pattern_6E09
	dw Pattern_5931
	LIST_LOOP Song5A_Ch2
Song5A_Ch3:
	dw Pattern_6E54
	dw Pattern_596E
	dw Pattern_5939
	dw Pattern_5961
	LIST_LOOP Song5A_Ch3
Pattern_5918:
	REPEAT $04
	db L8, B4, Cs5, F5, G5
	REPEAT_END
	db PAT_END
Pattern_5921:
	REPEAT $04
	db A4, B4, Ds5, F5
	REPEAT_END
	db PAT_END
Pattern_5929:
	REPEAT $04
	db C5, D5, Fs5, Gs5
	REPEAT_END
	db PAT_END
Pattern_5931:
	REPEAT $02
	db Cs5, Ds5, Fs5, A5
	REPEAT_END
	db PAT_END
Pattern_5939:
	CH3_FADEOUT_ON
	db L4D, B2, L8, B2, L1, REST, L4D, REST, L8, As2, L4D, A2, L8, A2, L1, REST
	db L4D, REST, L8, A2, L4D, E2, L8, E2, L1, REST, L4D, REST, L8, E2, C2, C2
	db REST, C2, L1, REST, L4D, REST, PAT_END
Pattern_5961:
	REPEAT $04
	db L8, Cs2
	REPEAT_END
	db L1D, REST, REST, L2, REST, L8, B2, PAT_END
Pattern_596E:
	REPEAT $0c
	db L1, REST
	REPEAT_END
	db PAT_END
; songs $14, $52
Song14_Header:
	SONG $00, LengthTable_4ABB, Song14_Ch1, Song14_Ch2, Song14_Ch3, 0
Song14_Ch2:
	dw Pattern_6E13
	dw Pattern_6E7C
	dw Pattern_5A47
	dw Pattern_5A51
	dw Pattern_6E1D
	dw Pattern_6E94
	dw Pattern_5A47
	dw Pattern_5A51
	dw Pattern_6DFA
	dw Pattern_6E8B
	dw Pattern_5A47
	dw Pattern_6E88
	dw Pattern_5A47
	dw Pattern_6DE6
	dw Pattern_6E85
	dw Pattern_5A47
	dw Pattern_6D20
	dw Pattern_6E7C
	dw Pattern_6E13
	dw Pattern_6E7C
	dw Pattern_5A47
	dw Pattern_5A51
	dw Pattern_6E1D
	dw Pattern_6E94
	dw Pattern_5A47
	dw Pattern_5A51
	dw Pattern_6DFA
	dw Pattern_6E8B
	dw Pattern_5A47
	dw Pattern_6E88
	dw Pattern_5A47
	dw Pattern_6DE6
	dw Pattern_6E85
	dw Pattern_5A47
	dw Pattern_6D20
	dw Pattern_6E7C
	dw Pattern_6D9B
	dw Pattern_5A77
	dw Pattern_6D8C
	dw Pattern_5A7E
	dw Pattern_6D91
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A84
	dw Pattern_5A84
	dw Pattern_6D82
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A8A
	dw Pattern_6D8C
	dw Pattern_5A90
	dw Pattern_6D91
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A84
	dw Pattern_5A84
	dw Pattern_6D82
	dw Pattern_5A84
	dw Pattern_6E94
	dw Pattern_6D9B
	dw Pattern_5A77
	dw Pattern_6D8C
	dw Pattern_5A7E
	dw Pattern_6D91
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A84
	dw Pattern_5A84
	dw Pattern_6D82
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A8A
	dw Pattern_6D8C
	dw Pattern_5A90
	dw Pattern_6D91
	dw Pattern_5A84
	dw Pattern_6D9B
	dw Pattern_5A84
	dw Pattern_5A84
	dw Pattern_6D82
	dw Pattern_5A84
	dw Pattern_6E7C
	dw Pattern_6DB9
	dw Pattern_5A3F
	dw Pattern_6E27
	dw Pattern_5A96
	LIST_LOOP Song14_Ch2
Song14_Ch3:
	dw Pattern_6E5E
	dw Pattern_5A6A
	dw Pattern_5A9F
	dw Pattern_6E59
	dw Pattern_5A3F
	dw Pattern_5A96
	LIST_LOOP Song14_Ch3
Pattern_5A3F:
	db L8, B2, Cs3, D3, A2, B2, C3, PAT_END
Pattern_5A47:
	db L4, B3, Cs4, D4, L2, A4, B2, L4, REST, PAT_END
Pattern_5A51:
	db B3, Cs4, D4, L2, Gs4, B2, L4, REST, B3, Cs4, D4, L2, G4, B2, L4, REST
	db B3, Cs4, D4, L2, Gs4, B2, L4, REST, PAT_END
Pattern_5A6A:
	REPEAT $18
	CH3_FADEOUT_ON
	db L4, B2, B2, L1, REST, L4, REST, B2
	REPEAT_END
	db PAT_END
Pattern_5A77:
	REPEAT $0c
	db L16, F3, A3
	REPEAT_END
	db PAT_END
Pattern_5A7E:
	REPEAT $04
	db F3, A3
	REPEAT_END
	db PAT_END
Pattern_5A84:
	REPEAT $04
	db E3, Gs3
	REPEAT_END
	db PAT_END
Pattern_5A8A:
	REPEAT $0c
	db Ds3, G3
	REPEAT_END
	db PAT_END
Pattern_5A90:
	REPEAT $04
	db Ds3, G3
	REPEAT_END
	db PAT_END
Pattern_5A96:
	db L8, REST, L1D, F2, L1, REST, L4D, REST, PAT_END
Pattern_5A9F:
	REPEAT $08
	CH3_FADEOUT_ON
	db L4, B2, B2, REST, B2, REST, L2, B3, L4, B2
	REPEAT_END
	db PAT_END
Song15_Header:
	SONG $00, LengthTable_4ABB, Song15_Ch1, Song15_Ch2, Song15_Ch3, 0
Song15_Ch1:
	dw Pattern_6D82
	dw Pattern_5BDF
	dw Pattern_6D9B
	dw Pattern_5BDF
	dw Pattern_5BDF
	dw Pattern_5C00
	dw Pattern_6D8C
	dw Pattern_5C0B
	dw Pattern_5C0B
	dw Pattern_5C0B
	dw Pattern_6E7C
	dw Pattern_5C0B
	LIST_LOOP Song15_Ch1
Song15_Ch2:
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_5C2F
	dw Pattern_6D9B
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_5C35
	dw Pattern_6D9B
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_5C3A
	dw Pattern_6D9B
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_5C3F
	dw Pattern_6D9B
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_6D9B
	dw Pattern_5C2F
	dw Pattern_6D8C
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_6D9B
	dw Pattern_5C35
	dw Pattern_6D8C
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_6D9B
	dw Pattern_5C3A
	dw Pattern_6D8C
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_6D9B
	dw Pattern_5C3F
	dw Pattern_6D8C
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_6D9B
	dw Pattern_5C2F
	dw Pattern_6D8C
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C2F
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_6D9B
	dw Pattern_5C35
	dw Pattern_6D8C
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C35
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_6D9B
	dw Pattern_5C3A
	dw Pattern_6D8C
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3A
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_6D9B
	dw Pattern_5C3F
	dw Pattern_6D8C
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C3F
	dw Pattern_6D82
	dw Pattern_5C44
	dw Pattern_6D8C
	dw Pattern_5C44
	dw Pattern_6D9B
	dw Pattern_5C49
	dw Pattern_6D8C
	dw Pattern_5C49
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D9B
	dw Pattern_5C4E
	dw Pattern_6E94
	dw Pattern_5C4E
	dw Pattern_6D20
	dw Pattern_6D20
	LIST_LOOP Song15_Ch2
Song15_Ch3:
	dw Pattern_5D67
	dw Pattern_6D15
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6E63
	dw Pattern_5C5E
	dw Pattern_6E72
	dw Pattern_5C8D
	dw Pattern_6E6D
	dw Pattern_5CA1
	dw Pattern_6E72
	dw Pattern_5C8D
	dw Pattern_6E6D
	dw Pattern_5CA1
	dw Pattern_6D18
	dw Pattern_6E6D
	dw Pattern_5C96
	dw Pattern_6E77
	dw Pattern_5CA1
	dw Pattern_6D18
	LIST_LOOP Song15_Ch3
Pattern_5BDF:
	db L1, REST, L4, REST
	REPEAT $04
	db L8, F5
	REPEAT_END
	db L1D, REST
	REPEAT $04
	db L8, E5
	REPEAT_END
	db L1D, REST
	REPEAT $04
	db L8, G5
	REPEAT_END
	db L1D, REST
	REPEAT $04
	db L8, Fs5
	REPEAT_END
	db L4, REST, PAT_END
Pattern_5C00:
	db L2D, REST, L8, REST, As5, L2D, REST, L8, REST, B5, PAT_END
Pattern_5C0B:
	REPEAT $03
	db L8, C2, Ds2, Cs2, F2
	REPEAT_END
	INSTR $a2, $83, $c0
	db C2, Ds2, Cs2, F2
	INSTR $c2, $83, $c0
	db C2, Ds2, Cs2, F2
	INSTR $81, $83, $c0
	REPEAT $03
	db C2, Ds2, Cs2, F2
	REPEAT_END
	db PAT_END
Pattern_5C2F:
	REPEAT $04
	db L8, B5
	REPEAT_END
	db PAT_END
Pattern_5C35:
	REPEAT $04
	db As5
	REPEAT_END
	db PAT_END
Pattern_5C3A:
	REPEAT $04
	db Cs6
	REPEAT_END
	db PAT_END
Pattern_5C3F:
	REPEAT $04
	db C6
	REPEAT_END
	db PAT_END
Pattern_5C44:
	REPEAT $04
	db E6
	REPEAT_END
	db PAT_END
Pattern_5C49:
	REPEAT $04
	db F6
	REPEAT_END
	db PAT_END
Pattern_5C4E:
	db L8, B3, Cs4, D4, A4, L1, REST, L8, REST, Gs4, Cs4, Gs4, L1, REST, REST, PAT_END
Pattern_5C5E:
	CH3_FADEOUT_ON
	db L8, B2, Cs3, D3, A3, L1D, REST, L8, B2, Cs3, D3, Gs3, L1D, REST, L8, Cs3
	db Ds3, E3, B3, L1D, REST, L8, Cs3, Ds3, E3, As3, L1D, REST, L8, Fs3, Gs3, A3
	db E4, L2, REST, L8, G3, A3, As3, F4
	REPEAT $09
	db L2, REST
	REPEAT_END
	db PAT_END
Pattern_5C8D:
	db L4, REST, L8, B5, Cs6, D6, A6, L4, REST
Pattern_5C96:
	db L1, REST
	REPEAT $03
	db L8, Gs5, B5, As5, C6
	REPEAT_END
	db PAT_END
Pattern_5CA1:
	db L8, Gs5, B5, As5, C6, PAT_END
Song16_Header:
	SONG $00, LengthTable_4AD9, Song16_Ch1, Song16_Ch2, Song16_Ch3, 0
Song16_Ch1:
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6DCD
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6D87
	dw Pattern_5D75
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_5D6D
	dw Pattern_6D18
	dw Pattern_6D24
	dw Pattern_6D24
	dw Pattern_6D2D
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6DCD
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6D87
	dw Pattern_5D86
	dw Pattern_6E0E
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6DCD
	dw Pattern_5D6D
	dw Pattern_6D24
	dw Pattern_6D24
	dw Pattern_6E0E
	dw Pattern_5D98
	LIST_LOOP Song16_Ch1
Song16_Ch2:
	dw Pattern_6E45
	dw Pattern_5D36
	dw Pattern_6E13
	dw Pattern_5D4D
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_6D2D
	dw Pattern_6D2D
	dw Pattern_6E09
	dw Pattern_5D6D
	dw Pattern_6E0E
	dw Pattern_5D6D
	dw Pattern_6E13
	dw Pattern_5D6D
	dw Pattern_6D2D
	dw Pattern_6D2D
	LIST_LOOP Song16_Ch2
Song16_Ch3:
	dw Pattern_6E5E
	dw Pattern_5D36
	dw Pattern_5D67
	LIST_LOOP Song16_Ch3
Pattern_5D36:
	db L2, B2, L4, Cs3, D3, L1, As2
	REPEAT $04
	db REST
	REPEAT_END
	db L2, B2, L4, Cs3, D3, L1, F3
	REPEAT $04
	db REST
	REPEAT_END
	db PAT_END
Pattern_5D4D:
	db L2, B5, L4, Cs6, D6, L2, A6, As5, L4, C6, Cs6, L2, Gs6, Fs6, L4, Gs6
	db A6, L2, E7, G6, L4, A6, As6, L2, F7, PAT_END
Pattern_5D67:
	REPEAT $09
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_5D6D:
	db LEN10, B4, F5, Fs5, B5, Fs5, F5, PAT_END
Pattern_5D75:
	db L16, REST, LEN13, REST, L4, REST, A6, Gs6, REST, A6, Gs6, L2, REST, L8, A6, Gs6
	db PAT_END
Pattern_5D86:
	db L16, REST, LEN13, REST, REST, L4, REST, C7, B6, REST, C7, B6, L2, REST, L8, C7
	db B6, PAT_END
Pattern_5D98:
	db L32, REST, REST
	REPEAT $03
	db L4, B4, F4
	REPEAT_END
	REPEAT $03
	db As4, E4
	REPEAT_END
	REPEAT $03
	db Fs4, C4
	REPEAT_END
	REPEAT $06
	db G4, Cs4
	REPEAT_END
	db L1D, REST, PAT_END
Song17_Header:
	SONG $00, LengthTable_4ABB, Song17_Ch1, Song17_Ch2, Song14_Ch1, 0
Song17_Ch1:
	dw Pattern_6E09
	dw Pattern_5DD6
	LIST_LOOP Song17_Ch1
Song17_Ch2:
	dw Pattern_6E0E
	dw Pattern_5E20
	dw Pattern_6E13
	dw Pattern_5E4D
	dw Pattern_6DCD
	dw Pattern_5E5F
	LIST_LOOP Song17_Ch2
Pattern_5DD6:
	db L4, REST, L8, B4, Cs5, D5, A5, REST, F6, F6, L2, REST, L8, REST, B4, Cs5
	db D5, Gs5, REST, E6, E6, L2, REST, L8, REST, Cs5, Ds5, E5, B5, REST, G6, G6
	db L2, REST, L8, REST, Cs5, Ds5, E5, As5, REST, Fs6, Fs6, L2, REST, L8, REST, Fs5
	db Gs5, A5, E6, REST, As6, L4, REST, L8, G5, A5, As5, F6, REST, B6, L4, REST
	db L8, B5, Cs6, F7, E7, Ds7, D7, L1D, REST, PAT_END
Pattern_5E20:
	db L8, B4, Cs5, D5, A5, L4D, REST, L8, B6, L2, B6, L8, B4, Cs5, D5, Gs5
	db L4D, REST, L8, As6, L2, As6, L8, Cs5, Ds5, E5, B5, L4D, REST, L8, Cs7, L2
	db Cs7, L8, Cs5, Ds5, E5, As5, L4D, REST, L8, C7, L2, C7, PAT_END
Pattern_5E4D:
	db L8, Fs5, Gs5, A5, E6, L4D, REST, L8, E7, G5, A5, As5, F6, L4D, REST, L8
	db F7, PAT_END
Pattern_5E5F:
	db B5, Cs6, D6, A7, Gs7, G7, Fs7, F7, L1D, REST, PAT_END
; songs $13, $51
Song13_Header:
	SONG $00, LengthTable_4AE8, Song13_Ch1, Song13_Ch2, Song13_Ch3, 0
Song13_Ch2:
	dw Pattern_6DAA
	dw Pattern_5E9B
	dw Pattern_6DAF
	dw Pattern_5EAD
	dw Pattern_6DB4
	dw Pattern_5EBE
	dw Pattern_6DAF
	dw Pattern_5ECF
	LIST_LOOP Song13_Ch2
Song13_Ch1:
	dw Pattern_6D10
Song13_Ch1_Loop:
	dw Pattern_6D7D
	dw Pattern_5E9B
	LIST_LOOP Song13_Ch1_Loop
Song13_Ch3:
	dw Pattern_6E54
	dw Pattern_5EE0
	LIST_LOOP Song13_Ch3
Pattern_5E9B:
	db L8, A3, Fs3, Ds3, C3, A2, Fs2, Ds2, Cs2, C2, Ds2, Fs2, A2, C3, Ds3, Fs3
	db A3, PAT_END
Pattern_5EAD:
	db As3, Fs3, Ds3, C3, As2, Fs2, Ds2, Cs2, C2, Ds2, Fs2, As2, C3, Ds3, Fs3, As3
	db PAT_END
Pattern_5EBE:
	db B3, Fs3, Ds3, C3, B2, Fs2, Ds2, Cs2, C2, Ds2, Fs2, B2, C3, Ds3, Fs3, B3
	db PAT_END
Pattern_5ECF:
	db As3, Fs3, Ds3, C3, As2, Fs2, Ds2, Cs2, C2, Ds2, Fs2, As2, C3, Ds3, Fs3, As3
	db PAT_END
Pattern_5EE0:
	CH3_FADEOUT_ON
	db L2D, REST, L8, REST, C2, C2, REST, L2D, REST, L1, REST, REST, PAT_END
Song18_Header:
	SONG $00, LengthTable_4AD9, Song18_Ch1, Song18_Ch2, 0, 0
Song18_Ch1:
	dw Pattern_6D10
Song18_Ch1_Loop:
	dw Pattern_6D7D
	dw Pattern_5F19
	dw Pattern_5F19
	LIST_LOOP Song18_Ch1_Loop
Song18_Ch2:
	dw Pattern_6E09
	dw Pattern_5F19
	dw Pattern_6E0E
	dw Pattern_5F2B
Song18_Ch2_Loop:
	dw Pattern_6E13
	dw Pattern_5F19
	dw Pattern_6E22
	dw Pattern_5F2B
	LIST_LOOP Song18_Ch2_Loop
Pattern_5F19:
	db L16, B4, A4, Fs4, Ds4, B3, A3, Fs3, Ds3, B2, Ds3, Fs3, A3, B3, Ds4, Fs4
	db A4, PAT_END
Pattern_5F2B:
	db Cs5, B4, A4, Fs4, Ds4, B3, A3, Fs3, Ds3, Fs3, A3, Cs4, Fs4, A4, Cs5, Ds5
	db PAT_END
Song19_Header:
	SONG $00, LengthTable_4A9D, Song19_Ch1, Song19_Ch2, Song19_Ch3, Song19_Ch4
Song19_Ch1:
	dw Pattern_6E4F
	dw Pattern_6003
	dw Pattern_6DC8
	dw Pattern_5F9D
	dw Pattern_6E27
	dw Pattern_5FBC
	dw Pattern_6DC8
	dw Pattern_5F9D
	dw Pattern_6D20
	LIST_LOOP Song19_Ch1
Song19_Ch2:
	dw Pattern_6E4F
	dw Pattern_5FF1
	dw Pattern_6DC8
	dw Pattern_5FC7
	dw Pattern_6E27
	dw Pattern_5FE6
	dw Pattern_6E8E
	dw Pattern_6DC8
	dw Pattern_5FC7
	dw Pattern_6D20
	dw Pattern_6E7C
	LIST_LOOP Song19_Ch2
Song19_Ch3:
	dw Pattern_6D15
	dw Pattern_6E5E
	dw Pattern_6015
	dw Pattern_6E59
	dw Pattern_6022
	dw Pattern_6E5E
	dw Pattern_6015
	dw Pattern_6D20
	LIST_LOOP Song19_Ch3
Song19_Ch4:
	dw Pattern_602D
	dw Pattern_6030
	dw Pattern_6030
	dw Pattern_6048
	dw Pattern_6030
	dw Pattern_6030
	dw Pattern_6053
	LIST_LOOP Song19_Ch4
Pattern_5F9D:
	REPEAT $02
	db L8, E3, E3, E3, Ds3, L2, REST, L4D, D3, Cs3, L4, REST
	REPEAT_END
	REPEAT $02
	db L8, Fs3, Fs3, Fs3, F3, L2, REST, L4D, E3, Ds3, L4, REST
	REPEAT_END
	db PAT_END
Pattern_5FBC:
	db L4D, B4, As4, L8, B4, C5, Cs5, L16, D5, REST, PAT_END
Pattern_5FC7:
	REPEAT $02
	db L8, B3, B3, B3, As3, L2, REST, L4D, A3, Gs3, L4, REST
	REPEAT_END
	REPEAT $02
	db L8, Cs4, Cs4, Cs4, C4, L2, REST, L4D, B3, As3, L4, REST
	REPEAT_END
	db PAT_END
Pattern_5FE6:
	db L4D, E5, Ds5, L8, E5, F5, Fs5, L16, G5, REST, PAT_END
Pattern_5FF1:
	db L16, F6, E6, Ds6, D6, Cs6, C6, B5, As5, A5, Gs5, G5, Fs5, F5, E5, Ds5
	db D5, PAT_END
Pattern_6003:
	db L16, D6, Cs6, C6, B5, As5, A5, Gs5, G5, Fs5, F5, E5, Ds5, D5, Cs5, C5
	db B4, PAT_END
Pattern_6015:
	REPEAT $10
	CH3_FADEOUT_ON
	db L8, B2, Fs2
	REPEAT_END
	REPEAT $10
	db Cs2, Cs3
	REPEAT_END
	db PAT_END
Pattern_6022:
	CH3_FADEOUT_OFF
	db L4D, C4, B3, L8, C4, Cs4, D4
	CH3_FADEOUT_ON
	db Ds4, PAT_END
Pattern_602D:
	db L1, REST, PAT_END
Pattern_6030:
	REPEAT $04
	db L8, NOISE_15, NOISE_15, DRUM, REST
	REPEAT_END
	REPEAT $02
	db NOISE_15, NOISE_15, DRUM, NOISE_15
	REPEAT_END
	db NOISE_1A, DRUM, NOISE_15, DRUM
	REPEAT $04
	db DRUM
	REPEAT_END
	db PAT_END
Pattern_6048:
	REPEAT $02
	db DRUM, NOISE_1A, NOISE_1A
	REPEAT_END
	REPEAT $04
	db DRUM
	REPEAT_END
	db PAT_END
Pattern_6053:
	db NOISE_1A, NOISE_1A, REST, NOISE_15, NOISE_15, REST, DRUM, DRUM
	REPEAT $04
	db NOISE_15
	REPEAT_END
	REPEAT $04
	db NOISE_1A
	REPEAT_END
	db PAT_END
Song1B_Header:
	SONG $00, LengthTable_4AAC, Song1B_Ch1, Song1B_Ch2, Song1B_Ch3, 0
Song1B_Ch1:
	dw Pattern_6E09
	dw Pattern_6D24
	dw Pattern_6D27
	dw Pattern_6087
	LIST_END
Song1B_Ch2:
	dw Pattern_6DCD
	dw Pattern_6087
	LIST_END
Song1B_Ch3:
	dw Pattern_6E77
	dw Pattern_6D27
	dw Pattern_6087
	LIST_END
Pattern_6087:
	REPEAT $02
	db L16, B7, Gs7, E7, Cs7, B6, Gs6, E6, Cs6, B5, Gs5, E5, Cs5, B4, Gs4, E4
	db Cs4, As7, G7, E7, C7, As6, G6, E6, C6, As5, G5, E5, C5, As4, G4, E4
	db C4
	REPEAT_END
	db As3, G3, E3, C3, As2, G2, E2, C2, L8D, B4, Fs5, A5, Cs6, REST, L8, B5
	db L16, Ds6, Fs6, L1, B6, REST, PAT_END
Song1C_Header:
	SONG $00, LengthTable_4ACA, Song1C_Ch1, Song1C_Ch2, Song14_Ch1, 0
Song1C_Ch1:
	dw Pattern_6E09
	dw Pattern_6003
	dw Pattern_6D10
Song1C_Ch1_Loop:
	dw Pattern_60E3
	LIST_LOOP Song1C_Ch1_Loop
Song1C_Ch2:
	dw Pattern_6E09
	dw Pattern_6E9D
	dw Pattern_5FF1
	LIST_LOOP Song1C_Ch1_Loop
Pattern_60E3:
	db L8, G3, B3, D4, Fs4, L4, Fs6, REST, L8, B5, G3, B3, D4, B5, Cs6, D6
	db E6, Fs3, Cs4, L4, E6, A5, A6, L8, E5, Cs5, A4, Fs4, E4, Cs4, A3, Fs3
	db E3, G3, B3, D4, L4, D6, REST, L8, G5, E3, G3, B3, G5, A5, B5, Cs6
	db D3, A3, L4, Cs6, Fs5, Fs6, L8, Cs5, A4, Fs4, D4, Cs4, A3, Fs3, D3, PAT_END
Song1D_Header:
	SONG $00, LengthTable_4AAC, Song1D_Ch1, Song1D_Ch2, Song1D_Ch3, 0
Song1D_Ch1:
	dw Pattern_6154
	LIST_LOOP Song1D_Ch1
Song1D_Ch2:
	dw Pattern_618F
	dw Pattern_60E3
	dw Pattern_6E7C
	dw Pattern_619D
	dw Pattern_6196
	dw Pattern_61E2
	dw Pattern_6E7C
	dw Pattern_6226
	LIST_LOOP Song1D_Ch2
Song1D_Ch3:
	dw Pattern_6E68
	dw Pattern_6267
	dw Pattern_6E6D
	dw Pattern_6267
	LIST_LOOP Song1D_Ch3
Pattern_6154:
	INSTR $32, $83, $80
	REPEAT $04
	db L8, B4, REST, B4, B4
	REPEAT_END
	REPEAT $04
	db A4, REST, A4, A4
	REPEAT_END
	REPEAT $04
	db G4, REST, G4, G4
	REPEAT_END
	REPEAT $04
	db Fs4, REST, Fs4, Fs4
	REPEAT_END
	REPEAT $04
	db B3, REST, B3, B3
	REPEAT_END
	REPEAT $04
	db A3, REST, A3, A3
	REPEAT_END
	REPEAT $07
	db As3, REST, As3, As3
	REPEAT_END
	db A3, REST, A3, A3, PAT_END
Pattern_618F:
	INSTR $67, $86, $80
	TRANSPOSE $e8
	db PAT_END
Pattern_6196:
	INSTR $47, $86, $80
	TRANSPOSE $e8
	db PAT_END
Pattern_619D:
	db L8, G2, B2, D3, Fs3, L4, Fs5, L8, G5, A5, L4, B5, L8, G2, D3, G3
	db B3, A5, G5, A5, D2, D3, G5, L4, Fs5, L8, E5, D5, D2, Fs2, A2, D3
	db L2, D5, L8, F2, As2, C3, D3, F5, As5, C6, L4, D6, L8, As2, F2, F3
	db As3, F4, C6, As5, L4D, C6, L8, G6, E2, As2, C3, G3, L4D, Fs6, L8, C7
	db Ds2, A2, C3, Fs3, PAT_END
Pattern_61E2:
	db L8, G3, B3, D4, Fs4, L4, Fs6, REST, L8, B5, G3, B3, D4, REST, Fs7, B6
	db B7, L8, A7, Cs5, D5, E5, L4, Fs5, L8, G5, L2, A5, L8, Fs4, E4, Cs4
	db Fs4, A4, E4, G4, B4, D5, L4, D5, REST, L8, G4, E3, G3, B3, G4, A4
	db B4, Cs5, B3, Cs4, D4, Fs4, L4, D5, L8, E5, L4D, Fs5, L8, REST, B4, D5
	db Fs5, G5, A5, PAT_END
Pattern_6226:
	db L2, B4, L8, G2, B2, D3, Fs3, G3, B3, D4, Fs4, B4, Cs5, D5, E5, L4D
	db A4, L8, A5, Fs3, A3, B3, Cs4, D4, Fs6, D6, A6, A7, Fs3, A3, D4, L4D
	db As6, L8, As7, F4, As4, C5, L4, D5, L8, As2, F2, F3, As3, F4, C5, As4
	db L4D, C5, L8, G5, E3, F3, G3, As3, L4D, Fs5, L8, C6, Ds4, Fs4, A4, C5
	db PAT_END
Pattern_6267:
	REPEAT $04
	CH3_FADEOUT_ON
	db L8, G4, REST, G4, G4
	REPEAT_END
	REPEAT $04
	db Fs4, REST, Fs4, Fs4
	REPEAT_END
	REPEAT $04
	db E4, REST, E4, E4
	REPEAT_END
	REPEAT $04
	db B3, REST, B3, B3
	REPEAT_END
	REPEAT $04
	db G3, REST, G3, G3
	REPEAT_END
	REPEAT $04
	db Fs3, REST, Fs3, Fs3
	REPEAT_END
	REPEAT $04
	db F3, REST, F3, F3
	REPEAT_END
	REPEAT $02
	db E3, REST, E3, E3
	REPEAT_END
	REPEAT $02
	db Ds3, REST, Ds3, Ds3
	REPEAT_END
	db PAT_END
Song1E_Header:
	SONG $00, LengthTable_4ABB, Song1E_Ch1, Song1E_Ch2, Song14_Ch1, 0
Song1E_Ch1:
	dw Pattern_6D7D
	dw Pattern_6D10
	dw Pattern_62F2
	dw Pattern_6E09
	dw Pattern_62F2
	dw Pattern_6304
	dw Pattern_6D2D
	dw Pattern_6EA8
	dw Pattern_6D7D
	dw Pattern_5147
	dw Pattern_5147
	dw Pattern_5147
	dw Pattern_6D20
	LIST_END
Song1E_Ch2:
	dw Pattern_6DF0
	dw Pattern_62F2
	dw Pattern_6DE1
	dw Pattern_6E94
	dw Pattern_62F2
	dw Pattern_6E13
	dw Pattern_6E7C
	dw Pattern_6304
	dw Pattern_6E22
	dw Pattern_6EA8
	dw Pattern_5147
	dw Pattern_6DCD
	dw Pattern_5147
	dw Pattern_6E0E
	dw Pattern_5147
	dw Pattern_6D20
	LIST_END
Pattern_62F2:
	db L16, As3, Cs4, F4, A4, As4, Cs5, F5, A5, A3, C4, E4, Gs4, A4, Gs4, E4
	db C4, PAT_END
Pattern_6304:
	db L16, Ds4, Fs4, As4, D5, Ds5, Fs5, As5, D6, PAT_END
Song4B_Header:
	SONG $00, LengthTable_4AD9, Song4B_Ch1, Song4B_Ch2, Song4B_Ch3, 0
Song4B_Ch1:
	dw Pattern_6DA0
	dw Pattern_63C7
	dw Pattern_6E3B
	dw Pattern_63E7
	dw Pattern_6DA0
	dw Pattern_6418
	LIST_LOOP Song4B_Ch1
Song4B_Ch2:
	dw Pattern_6DAA
	dw Pattern_6365
	dw Pattern_6DAA
	dw Pattern_6365
	dw Pattern_6DAA
	dw Pattern_638B
	dw Pattern_6DAA
	dw Pattern_6365
	dw Pattern_6DAA
	dw Pattern_6365
	dw Pattern_6DAA
	dw Pattern_6365
	dw Pattern_6DAA
	dw Pattern_638B
	dw Pattern_6DAF
	dw Pattern_63A9
	dw Pattern_6DAA
	dw Pattern_638B
	dw Pattern_6DAF
	dw Pattern_63A9
	LIST_LOOP Song4B_Ch2
Song4B_Ch3:
	dw Pattern_6E6D
	dw Pattern_6433
	dw Pattern_6E6D
	dw Pattern_6454
	dw Pattern_6E6D
	dw Pattern_645A
	LIST_LOOP Song4B_Ch3
Pattern_6365:
	db L8, C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $92, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $b2, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $92, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2, PAT_END
Pattern_638B:
	REPEAT $02
	db C2, Fs2, Cs2, F2, REST, Cs2
	REPEAT_END
	INSTR $92, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $b2, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2, PAT_END
Pattern_63A9:
	db C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $92, $00, $c0
	db C2, Fs2, Cs2, F2, REST, Cs2
	INSTR $62, $00, $c0
	REPEAT $02
	db C2, Fs2, Cs2, F2, REST, Cs2
	REPEAT_END
	db PAT_END
Pattern_63C7:
	db L1D, REST, REST
	REPEAT $02
	db L16, C4, C4, C4, C4, Cs4, C4, L8, C4, L1D, REST, L2D, REST, L8, REST, C5
	db L16, C4, C4, L4D, REST, L1, REST, L1D, REST
	REPEAT_END
	db PAT_END
Pattern_63E7:
	db L16, REST, Ds5, F5, Fs5, Cs6, L4, As5, L16, As5, C6, REST, L1D, REST, L2, REST
	db L16, Ds6, C6, As5, A5, L1D, REST, LEN9, A3, L32, REST, L16, A3, L4D, REST, L1
	db REST, L16, C6, As5, E5, Ds5, L1, REST, REST, L2, REST, L8, B3, L16, C4, REST
	db PAT_END
Pattern_6418:
	db L16, A3, A3, A3, A3, As3, A3, L8, A3, L1D, REST, L1, REST, L16, E3, E3
	db E3, E3, F3, E3, L8, E3, L1, REST, L1D, REST, PAT_END
Pattern_6433:
	CH3_FADEOUT_ON
	db L1D, REST, REST
	REPEAT $02
	db L16, As3, As3, As3, As3, B3, As3, L8, As3, L1D, REST, L2D, REST, L8, REST, As4
	db L16, As3, As3, L4D, REST, L1D, REST, L1, REST
	REPEAT_END
	db PAT_END
Pattern_6454:
	REPEAT $0c
	db L2D, REST
	REPEAT_END
	db PAT_END
Pattern_645A:
	db L16, F3, F3, F3, F3, Fs3, F3, F3, REST, L1, REST, L1D, REST, L16, C3, C3
	db C3, C3, Cs4, C3, C3, REST, L1, REST, L1D, REST, PAT_END
Song1F_Header:
	SONG $00, LengthTable_4ABB, Song1F_Ch1, Song1F_Ch2, Song14_Ch1, Song14_Ch1
Song1F_Ch1:
	dw Pattern_6E7F
	dw Pattern_6E0E
	dw Pattern_64C0
	dw Pattern_64C0
Song1F_Ch1_Loop:
	dw Pattern_6E13
	dw Pattern_64C0
	dw Pattern_64D7
	dw Pattern_64E0
	dw Pattern_64E9
	dw Pattern_6E0E
	dw Pattern_64F2
	dw Pattern_6E13
	dw Pattern_64FB
	dw Pattern_6E1D
	dw Pattern_6504
	dw Pattern_6E13
	dw Pattern_650D
	dw Pattern_6E0E
	dw Pattern_6516
	dw Pattern_6E13
	dw Pattern_651F
	dw Pattern_6E1D
	dw Pattern_6528
	dw Pattern_6542
	LIST_LOOP Song1F_Ch1_Loop
Song1F_Ch2:
	dw Pattern_6D20
	dw Pattern_6D20
Song1F_Ch2_Loop:
	dw Pattern_6E2C
	dw Pattern_654B
	LIST_LOOP Song1F_Ch2_Loop
Pattern_64C0:
	db L4, G3, C4, B3, C4, Ds4, C4, B3, C4, PAT_END
Pattern_64CA:
	REPEAT $02
	db L8, G3, C4, B3, C4, Ds4, C4, B3, C4
	REPEAT_END
	db PAT_END
Pattern_64D7:
	db Gs3, C4, B3, C4, Ds4, C4, B3, C4, PAT_END
Pattern_64E0:
	db Gs3, D4, C4, D4, F4, D4, C4, D4, PAT_END
Pattern_64E9:
	db G3, Ds4, D4, Ds4, G4, Ds4, D4, Ds4, PAT_END
Pattern_64F2:
	db C4, Ds4, D4, Ds4, Gs4, Ds4, D4, Ds4, PAT_END
Pattern_64FB:
	db Gs3, D4, C4, D4, F4, D4, C4, D4, PAT_END
Pattern_6504:
	db As3, D4, C4, D4, F4, D4, C4, D4, PAT_END
Pattern_650D:
	db As3, Ds4, D4, Ds4, G4, Ds4, D4, Ds4, PAT_END
Pattern_6516:
	db Gs3, Ds4, D4, Ds4, Gs4, Ds4, D4, Ds4, PAT_END
Pattern_651F:
	db A3, D4, C4, D4, Fs4, D4, C4, D4, PAT_END
Pattern_6528:
	db G3, D4, C4, D4, G4, D4, C4, D4, PAT_END
Pattern_6531:
	db B3, D4, F4, Gs4, B4, D5, F5, Gs5, G5, F5, D5, B4, G4, F4, D4, B3
	db PAT_END
Pattern_6542:
	db B3, D4, F4, Gs4, B4, D5, F5, Gs5, PAT_END
Pattern_654B:
	REPEAT $02
	db L4, C5, D5, L1D, Ds5
	REPEAT_END
	db L1, D5, B4, L1D, C5, L2, REST, L4, C5, D5, L1D, Ds5, L4, D5, Ds5, L1
	db F5, L2, REST, L4, As4, D5, L1, F5, L2, Gs5, L1D, G5, L2, REST, L1, F5
	db F5, Fs5, Fs5, G5, G5, REST, REST, PAT_END
Song58_Header:
	SONG $00, LengthTable_4AE8, Song58_Ch1, Song58_Ch2, Song14_Ch1, 0
Song58_Ch1:
	dw Pattern_6D24
Song58_Ch1_Loop:
	dw Pattern_6D7D
	dw Pattern_64CA
	dw Pattern_64D7
	dw Pattern_64D7
	dw Pattern_64E0
	dw Pattern_64E0
	dw Pattern_64E9
	dw Pattern_64E9
	dw Pattern_64F2
	dw Pattern_64F2
	dw Pattern_64FB
	dw Pattern_64FB
	dw Pattern_6504
	dw Pattern_6504
	dw Pattern_650D
	dw Pattern_650D
	dw Pattern_6516
	dw Pattern_6516
	dw Pattern_651F
	dw Pattern_651F
	dw Pattern_6528
	dw Pattern_6528
	dw Pattern_6531
	LIST_LOOP Song58_Ch1_Loop
Song58_Ch2:
	dw Pattern_6E0E
	dw Pattern_64CA
	dw Pattern_64D7
	dw Pattern_6E13
	dw Pattern_64D7
	dw Pattern_6DCD
	dw Pattern_64E0
	dw Pattern_6DFA
	dw Pattern_64E0
	dw Pattern_6E13
	dw Pattern_64E9
	dw Pattern_6E0E
	dw Pattern_64E9
	dw Pattern_64F2
	dw Pattern_6E13
	dw Pattern_64F2
	dw Pattern_6DCD
	dw Pattern_64FB
	dw Pattern_6E0E
	dw Pattern_64FB
	dw Pattern_6E09
	dw Pattern_6504
	dw Pattern_6E0E
	dw Pattern_6504
	dw Pattern_6E13
	dw Pattern_650D
	dw Pattern_6E09
	dw Pattern_650D
	dw Pattern_6E0E
	dw Pattern_6516
	dw Pattern_6E13
	dw Pattern_6516
	dw Pattern_6DCD
	dw Pattern_651F
	dw Pattern_6DFA
	dw Pattern_651F
	dw Pattern_6528
	dw Pattern_6DE6
	dw Pattern_6528
	dw Pattern_6DCD
	dw Pattern_6531
	LIST_LOOP Song58_Ch2
Song21_Header:
	SONG $00, LengthTable_4AE8, Song14_Ch1, Song21_Ch2, Song14_Ch1, 0
Song21_Ch2:
	dw Pattern_6DF5
	dw Pattern_6625
	dw Pattern_6D20
	LIST_LOOP Song21_Ch2
Pattern_6625:
	db L8, C2, Fs2, F2, L4D, REST, L8D, REST, L16, C2, L8, C2, Fs2, L16, F2, B2
	db PAT_END
Song22_Header:
	SONG $00, LengthTable_4ABB, Song22_Ch1, Song22_Ch2, Song14_Ch1, 0
Song22_Ch1:
	dw Pattern_6E09
	dw Pattern_6D24
	dw Pattern_6D10
Song22_Ch1_Loop:
	dw Pattern_6653
	LIST_LOOP Song22_Ch1_Loop
Song22_Ch2:
	dw Pattern_6DCD
	LIST_LOOP Song22_Ch1_Loop
Pattern_6653:
	db L4, C4, As4, G5, D6, G6, REST, L4, As3, Gs4, F5, C6, F6, REST, PAT_END
Song24_Header:
	SONG $00, LengthTable_4ACA, Song24_Ch1, Song24_Ch2, Song14_Ch1, 0
Song24_Ch1:
	dw Pattern_6E09
	dw Pattern_6D10
	dw Pattern_6685
	dw Pattern_669B
Song24_Ch1_Loop:
	dw Pattern_66AB
	LIST_LOOP Song24_Ch1_Loop
Song24_Ch2:
	dw Pattern_6E0E
	dw Pattern_6685
Song24_Ch2_Loop:
	dw Pattern_668F
	LIST_LOOP Song24_Ch2_Loop
Pattern_6685:
	db L16, As7, A7, F7, Cs7, As6, A6, F6, Cs6, PAT_END
Pattern_668F:
	REPEAT $03
	db L4D, A6, REST
	REPEAT_END
	db L8, A6, A6, L2, REST, PAT_END
Pattern_669B:
	db L2, REST, L8D, REST
	REPEAT $02
	db L4D, F5, REST
	REPEAT_END
	db L8, F5, F5, L2, REST, PAT_END
Pattern_66AB:
	REPEAT $03
	db L4D, F5, REST
	REPEAT_END
	db L8, F5, F5, L2, REST, PAT_END
Song53_Header:
	SONG $00, LengthTable_4ACA, Song53_Ch1, Song53_Ch2, Song53_Ch3, 0
Song53_Ch1:
	dw Pattern_6D7D
	dw Pattern_6D10
	dw Pattern_66F6
	dw Pattern_6EA4
	dw Pattern_6E09
	dw Pattern_6745
	dw Pattern_6EA8
	LIST_LOOP Song53_Ch1
Song53_Ch2:
	dw Pattern_6DA0
	dw Pattern_66F6
	dw Pattern_6D10
	dw Pattern_6EA4
	dw Pattern_6DBE
	dw Pattern_6719
	dw Pattern_6EA8
	LIST_LOOP Song53_Ch2
Song53_Ch3:
	dw Pattern_6D10
	dw Pattern_6D18
	dw Pattern_6EA4
	dw Pattern_6E68
	dw Pattern_6700
	dw Pattern_6EA8
	LIST_LOOP Song53_Ch3
Pattern_66F6:
	db L16, As7, A7, F7, Cs7, As6, A6, F6, Cs6, PAT_END
Pattern_6700:
	REPEAT $02
	db L4, REST, L8D, G7, L16, REST, L1D, REST, REST, REST, L1, REST
	REPEAT_END
	db L4, REST, L8D, G7, L16, REST, L1D, REST, REST, PAT_END
Pattern_6719:
	INSTR $61, $86, $80
	REPEAT $02
	db L4, Cs6, Ds6, E6, E7, L1, REST, L4, REST, Ds7, Cs7, E6, L1, REST
	REPEAT_END
	db L4, Cs6, Ds6, E6, REST, REST, Ds6, Cs6, G5, As5, Cs6, L2D, REST, L4, Ds6, E6
	db Fs6, G6, G7, L1D, REST, REST, PAT_END
Pattern_6745:
	REPEAT $04
	db L8, F5, A5, Cs5, E5, F5, E5, Cs5, A4
	REPEAT_END
	REPEAT $04
	db E5, G5, B4, Ds5, E5, G5, B5, Ds6
	REPEAT_END
	REPEAT $04
	db Ds5, G5, As4, Cs5, Ds5, Cs5, As4, G4
	REPEAT_END
	REPEAT $03
	db E5, G5, B4, Ds5, E5, G5, B5, Ds6
	REPEAT_END
	db E5, G5, B4, Ds5, PAT_END
Song26_Header:
	SONG $00, LengthTable_4ACA, Song26_Ch1, Song26_Ch2, Song14_Ch1, 0
Song26_Ch1:
	dw Pattern_6E09
	dw Pattern_5DD6
	LIST_LOOP Song26_Ch1
Song26_Ch2:
	dw Pattern_6E13
	dw Pattern_6E9A
	LIST_LOOP UnusedList_6792
UnusedList_6792:
	dw Pattern_5E20
	dw Pattern_5E4D
	dw Pattern_5E5F
	LIST_LOOP UnusedList_6792
Song5B_Header:
	SONG $00, LengthTable_4AD9, Song5B_Ch1, Song5B_Ch2, Song5B_Ch3, 0
Song5B_Ch1:
	dw Pattern_6D10
Song5B_Ch1_Loop:
	dw Pattern_6D78
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_6D78
	dw Pattern_68DB
	dw Pattern_68DB
	dw Pattern_6D7D
	dw Pattern_6897
	dw Pattern_6D78
	dw Pattern_68DB
	dw Pattern_68C4
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	LIST_LOOP Song5B_Ch1_Loop
Song5B_Ch3:
	dw Pattern_6973
	dw Pattern_6E68
	dw Pattern_6856
	dw Pattern_6E6D
	dw Pattern_6856
	dw Pattern_6E68
	dw Pattern_6825
	dw Pattern_6E77
	dw Pattern_6825
	dw Pattern_6E68
	dw Pattern_6839
	dw Pattern_6E6D
	dw Pattern_6866
	dw Pattern_6E68
	dw Pattern_6873
	dw Pattern_6E6D
	dw Pattern_687F
	dw Pattern_6E77
	dw Pattern_688B
	LIST_LOOP Song5B_Ch3
Song5B_Ch2:
	dw Pattern_6E09
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_6E09
	dw Pattern_68FC
	dw Pattern_68FC
	dw Pattern_6897
	dw Pattern_68FC
	dw Pattern_6E0E
	dw Pattern_68C4
	dw Pattern_6E09
	dw Pattern_6935
	dw Pattern_6D78
	dw Pattern_6965
	LIST_LOOP Song5B_Ch2
Pattern_6825:
	db L4, Ds5, Cs6, C6, Fs6, L2, REST, L8, REST, Cs6, C6, Ds5, L4, D5, B5, As5
	db F6, L1, REST, PAT_END
Pattern_6839:
	db L4, Cs5, A5, Gs5, E6, L1, REST, L4, C5, Gs5, G5, Ds6, L1, REST, L4, B4
	db G5, Fs5, D6, L1, REST, L4, C5, Gs5, G5, Ds6, L1, REST, PAT_END
Pattern_6856:
	CH3_FADEOUT_ON
	db L4, Cs5, A5, Gs5, E6, L1, REST, L4, C5, Gs5, G5, Ds6, L1, REST, PAT_END
Pattern_6866:
	CH3_FADEOUT_OFF
	db L8, B3, Cs4, D4, A4, B4, Cs5, D5, A5, L1, REST, PAT_END
Pattern_6873:
	db L8, B3, Cs4, D4, Gs4, B4, Cs5, D5, Gs5, L1, REST, PAT_END
Pattern_687F:
	db L8, Cs4, Ds4, E4, B4, Cs5, Ds5, E5, B5, L1, REST, PAT_END
Pattern_688B:
	db L8, Cs4, Ds4, E4, As4, Cs5, Ds5, E5, As5, L1, REST, PAT_END
Pattern_6897:
	REPEAT $02
	db L8, REST, Ds4, F4, Ds4, F4, L4D, REST
	REPEAT_END
	REPEAT $02
	db L8, REST, D4, F4, D4, F4, L4D, REST
	REPEAT_END
	REPEAT $02
	db L8, REST, Ds4, F4, Fs4, As4, L4D, REST
	REPEAT_END
	REPEAT $02
	db L8, REST, D4, F4, Fs4, D5, L4D, REST
	REPEAT_END
	db PAT_END
Pattern_68C4:
	REPEAT $02
	db Fs4, D4, Fs4, G4, As4, B4, As4, A4
	REPEAT_END
	REPEAT $02
	db C4, Ds4, G4, Gs4, B4, C5, B4, Gs4
	REPEAT_END
	db PAT_END
Pattern_68DB:
	db L8, A4, Cs5, C5, Cs5
	INSTR $20, $00, $80
	REPEAT $03
	db L8, A4, Cs5, C5, Cs5
	REPEAT_END
	REPEAT $03
	db Gs4, B4, C5, B4
	REPEAT_END
	INSTR $10, $00, $80
	db Gs4, B4, C5, B4, PAT_END
Pattern_68FC:
	db L8, A4, Cs5, C5, Cs5
	INSTR $37, $00, $80
	db A4, Cs5, C5, Cs5
	INSTR $53, $00, $80
	db A4, Cs5, C5, Cs5
	INSTR $64, $00, $80
	db A4, Cs5, C5, Cs5
	INSTR $53, $00, $80
	db Gs4, B4, C5, B4
	INSTR $37, $00, $80
	db Gs4, B4, C5, B4
	INSTR $27, $00, $80
	REPEAT $02
	db Gs4, B4, C5, B4
	REPEAT_END
	db PAT_END
Pattern_6935:
	db L8, REST, B3, Cs4, D4, A4, B4, Cs5, D5, B5, Cs6, D6, A6, L2, REST, L8
	db REST, B3, Cs4, D4, Gs4, B4, Cs5, D5, B5, Cs6, D6, Gs6, L2, REST, L8, REST
	db Cs4, Ds4, E4, B4, Cs5, Ds5, E5, Cs6, Ds6, E6, B6, L2, REST, L8, REST, PAT_END
Pattern_6965:
	db Cs4, Ds4, E4, As4, Cs5, Ds5, E5, Cs6, Ds6, E6, As6, L2, REST, PAT_END
Pattern_6973:
	REPEAT $18
	db L1, REST
	REPEAT_END
	db PAT_END
Song4C_Header:
	SONG $00, LengthTable_4AD9, Song4C_Ch1, Song4C_Ch2, Song4C_Ch3, 0
Song4C_Ch1:
	dw Pattern_6DFF
	dw Pattern_69A2
	dw Pattern_6E4A
	dw Pattern_69B4
	LIST_END
Song4C_Ch2:
	dw Pattern_6DFF
	dw Pattern_69B7
	dw Pattern_6E4A
	dw Pattern_69C9
	LIST_END
Song4C_Ch3:
	dw Pattern_6E54
	dw Pattern_69CC
	dw Pattern_6E59
	dw Pattern_69DA
	LIST_END
Pattern_69A2:
	db L16, REST, L2, REST, L4, Cs3, Ds3, L2D, E3, L4, REST, E3, Fs3, L4D, Gs3, L8
	db As3, PAT_END
Pattern_69B4:
	db L1D, C3, PAT_END
Pattern_69B7:
	db L16, REST, L2, REST, L4, As3, B3, L2D, Cs4, L4, REST, Cs4, Ds4, L4D, E4, L8
	db Fs4, PAT_END
Pattern_69C9:
	db L1D, Gs4, PAT_END
Pattern_69CC:
	REPEAT $02
	CH3_FADEOUT_ON
	db L16, Fs2
	CH3_FADEOUT_OFF
	db L1, Fs2, L4, Fs2, L8D, REST
	REPEAT_END
	db PAT_END
Pattern_69DA:
	db L16, REST, L1D, A2, PAT_END
Song4D_Header:
	SONG $00, LengthTable_4AE8, Song4D_Ch1, Song4D_Ch2, Song4D_Ch3, 0
Song4D_Ch1:
	dw Pattern_6D7D
	dw Pattern_6D10
	dw Pattern_6A08
	LIST_LOOP Song4D_Ch2_Loop
Song4D_Ch2:
	dw Pattern_6D87
	dw Pattern_6A08
Song4D_Ch2_Loop:
	dw Pattern_6A12
	LIST_LOOP UnusedList_6D30
Song4D_Ch3:
	dw Pattern_6D18
	dw Pattern_6E77
	dw Pattern_6A1C
	LIST_LOOP UnusedList_6D30
Pattern_6A08:
	db L16, Ds7, B6, Gs6, E6, Ds6, B5, Gs5, Ds5, PAT_END
Pattern_6A12:
	db L16, F5, A5, C6, E6, F6, A6, C7, E7, PAT_END
Pattern_6A1C:
	CH3_FADEOUT_ON
	db L8, F5, F5, PAT_END
Song4E_Header:
	SONG $00, LengthTable_4AD9, Song4E_Ch1, Song4E_Ch2, Song4E_Ch3, 0
Song4E_Ch2:
	dw Pattern_6DA0
	dw Pattern_6A9B
	dw Pattern_6AA5
Song4E_Ch2_Loop:
	dw Pattern_6EB0
	dw Pattern_6D96
	dw Pattern_6AA8
	dw Pattern_6D10
	dw Pattern_6D7D
	dw Pattern_6A08
	dw Pattern_6D24
	dw Pattern_6D2D
	dw Pattern_6A96
	dw Pattern_6B78
	dw Pattern_6DA0
	dw Pattern_6B28
	dw Pattern_6E09
	dw Pattern_6B40
	dw Pattern_6D27
	LIST_LOOP Song4E_Ch2_Loop
Song4E_Ch1:
	dw Pattern_6D7D
	dw Pattern_6D10
	dw Pattern_6A9B
	dw Pattern_6D2D
Song4E_Ch1_Loop:
	dw Pattern_6EB0
	dw Pattern_6B22
	dw Pattern_6D87
	dw Pattern_6A08
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D10
	dw Pattern_6D7D
	dw Pattern_6B28
	dw Pattern_6D27
	dw Pattern_6D2D
	dw Pattern_6D10
	LIST_LOOP Song4E_Ch1_Loop
Song4E_Ch3:
	dw Pattern_6D18
	dw Pattern_6D24
Song4E_Ch3_Loop:
	dw Pattern_6E6D
	dw Pattern_6EB0
	dw Pattern_6D10
	dw Pattern_5D67
	dw Pattern_6B46
	dw Pattern_6D15
	dw Pattern_6D2D
	dw Pattern_6D18
	dw Pattern_6D24
	LIST_LOOP Song4E_Ch3_Loop
Pattern_6A96:
	INSTR $c2, $83, $c0
	db PAT_END
Pattern_6A9B:
	db L16, A4, B4, Cs5, Ds5, Fs5, A5, B5, Cs6, PAT_END
Pattern_6AA5:
	db Ds6, Fs6, PAT_END
Pattern_6AA8:
	INSTR $b1, $83, $80
	db L8D, REST, Cs6, Ds6, E6
	INSTR $81, $83, $80
	db L8, Fs4, Gs4, A4, Cs5, E5, L16, REST
	INSTR $b1, $83, $80
	db L8D, Cs6, Ds6, E6
	INSTR $81, $83, $80
	db L8, B3, Fs4, A4, Cs5, Ds5
	INSTR $b1, $83, $80
	db Ds6, Cs6, Gs5, B5
	INSTR $81, $83, $80
	db E4, Gs4, Cs6, Ds5, L4D, REST, L8, Cs4, F4, Gs4, B4, Cs5
	INSTR $b1, $83, $80
	db Cs6, Ds6, E6
	INSTR $81, $83, $80
	db L8, Fs4, Gs4, A4, Cs5, E5
	INSTR $b1, $83, $80
	db B5, E6, A6
	INSTR $81, $83, $80
	db L8, B3, Fs4, A4, Cs5, Fs5
	INSTR $b1, $83, $80
	db Gs6, Fs6, Gs6
	INSTR $81, $83, $80
	db L8, E4, Gs4, B4, Ds5, E5, Gs5, B5, Ds6, B6, REST, B7, REST, PAT_END
Pattern_6B22:
	REPEAT $11
	db L2, REST
	REPEAT_END
	db PAT_END
Pattern_6B28:
	db L16, Cs3, E3, Gs3, B3, Ds4, E4, Gs4, B4, Ds5, B4, Gs4, E4, Ds4, B3, Gs3
	db E3, B2, Fs3, A3, Cs4, Fs4, A4, PAT_END
Pattern_6B40:
	db Cs5, Fs5, B5, LEN9, REST, PAT_END
Pattern_6B46:
	db LEN9, REST, L4, REST, L4, Ds7, Cs7, Gs6, L4D, Gs6, L2, A6, L4D, REST, L4, Fs7
	db E7, Gs6, L4D, Gs6, L4, A6, L8, REST, L4, A6, L4, B6, REST, L8, D6, F6
	db B6, L2, Gs6, L4D, REST, L8, E6, L2, Cs7, REST, L8, REST, L4D, C7, A7, L4
	db Gs7, PAT_END
; no PAT_END of its own: the $00 that ends it is the transpose byte of Song4F_Header
Pattern_6B78:
	INSTR $c2, $83, $c0
	db L4, Ds7, Cs7, Gs6, L8, Gs6
	INSTR $72, $00, $80
	db Fs3, Cs4
	INSTR $c2, $83, $c0
	db A6
	INSTR $72, $00, $80
	db L16, Fs4, Gs4, A4, Cs5, Fs5, Gs5, A5, E6, Cs4, Gs4, Ds5, B5
	INSTR $c2, $83, $c0
	db L4, Fs7, E7, Gs6, L8, Gs6
	INSTR $72, $00, $80
	db Fs4, Cs5
	INSTR $c2, $83, $c0
	db A6
	INSTR $72, $00, $80
	db L16, Fs5, Gs5, A5, Cs6
	INSTR $c2, $83, $c0
	db L4, A6, B6
	INSTR $72, $00, $80
	db L16, D5, F5, Gs5, B5
	INSTR $c2, $83, $c0
	db L8, D6, F6, B6, Gs6
	INSTR $72, $00, $80
	db L16, REST, E5, Gs5, B5, E6, Gs6, B6, D7, L4, E7
	INSTR $c2, $83, $c0
	db L8, E6, Cs7
	INSTR $72, $00, $80
	db L16, A3, Cs4, E4, Gs4, A4, Cs5, E5, Gs5, Cs5, E5, Gs5, A5, E5, Gs5, A5
	db Cs6
	INSTR $c2, $83, $c0
	db L4D, C7, A7, L4, Gs7
Song4F_Header:
	SONG $00, LengthTable_4ACA, Song4F_Ch1, Song4F_Ch2, Song4F_Ch3, 0
Song4F_Ch1:
	dw Pattern_6D9B
	dw Pattern_6C40
	dw Pattern_6D2A
	LIST_LOOP Song4F_Ch2_Loop
Song4F_Ch2:
	dw Pattern_6DB9
Song4F_Ch2_Loop2:
	dw Pattern_6C2E
Song4F_Ch2_Loop:
	dw Pattern_6C38
	LIST_END
Song4F_Ch3:
	dw Pattern_6E6D
	dw Pattern_6D10
	LIST_LOOP Song4F_Ch2_Loop2
Pattern_6C2E:
	db L16, E5, Gs5, B5, Ds6, E6, Gs6, B6, Ds7, PAT_END
Pattern_6C38:
	db L4, REST, L16, Gs7, B7, REST, REST, PAT_END
Pattern_6C40:
	REPEAT $02
	db L16, E4, Gs4, B4, Gs4
	REPEAT_END
	db PAT_END
Song5C_Header:
	SONG $00, LengthTable_4ABB, Song5C_Ch1, Song5C_Ch2, Song14_Ch1, 0
Song5C_Ch1:
	dw Pattern_6DE1
	dw Pattern_6D03
	dw Pattern_6DF0
	dw Pattern_6D03
	dw Pattern_6D03
	dw Pattern_6DE1
	dw Pattern_6D03
	LIST_LOOP Song5C_Ch1
Song5C_Ch2:
	dw Pattern_6D9B
	dw Pattern_6CE9
	dw Pattern_6D8C
	dw Pattern_6E9D
	dw Pattern_6CE9
	dw Pattern_6E94
	dw Pattern_6CE9
	dw Pattern_6D9B
	dw Pattern_6E97
	dw Pattern_6CE9
	dw Pattern_6E7C
	LIST_LOOP Song5C_Ch2
Song54_Header:
	SONG $00, LengthTable_4ABB, Song54_Ch1, Song54_Ch2, Song54_Ch3, Song54_Ch4
Song54_Ch1:
	dw Pattern_6DE1
	dw Pattern_6D03
	dw Pattern_6DF0
	dw Pattern_6D03
	dw Pattern_6DFF
	dw Pattern_6D03
	dw Pattern_6D03
	dw Pattern_6D03
	dw Pattern_6D03
	dw Pattern_6D03
	dw Pattern_6EA0
	LIST_LOOP Song19_Ch1
Song54_Ch2:
	dw Pattern_6D9B
	dw Pattern_6CE9
	dw Pattern_6D8C
	dw Pattern_6E9D
	dw Pattern_6CE9
	dw Pattern_6DEB
	dw Pattern_6E94
	dw Pattern_6CE9
	dw Pattern_6E97
	dw Pattern_6CE9
	dw Pattern_6D8C
	dw Pattern_6E7C
	dw Pattern_6CF6
	dw Pattern_6DB9
	dw Pattern_6E9D
	dw Pattern_6CF6
	dw Pattern_6DEB
	dw Pattern_6E94
	dw Pattern_6CF6
	dw Pattern_6E7C
	dw Pattern_6EA0
	LIST_LOOP Song19_Ch2
Song54_Ch3:
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D20
	dw Pattern_6D15
	dw Pattern_6EA0
	LIST_LOOP Song19_Ch3
Song54_Ch4:
	dw Pattern_6D0A
	dw Pattern_6EA0
	LIST_LOOP Song19_Ch4
Pattern_6CE9:
	REPEAT $02
	db L16, D2, F2, Gs2, C3, D3, F3, Gs3, C4
	REPEAT_END
	db PAT_END
Pattern_6CF6:
	REPEAT $02
	db L16, D3, F3, Gs3, C4, D4, F4, Gs4, C5
	REPEAT_END
	db PAT_END
Pattern_6D03:
	CH3_FADEOUT_ON
	db L8, D2, D2, L2D, REST, PAT_END
Pattern_6D0A:
	REPEAT $07
	db L1, REST
	REPEAT_END
	db PAT_END
Pattern_6D10:
	db L16, REST, LEN9, REST, PAT_END
Pattern_6D15:
	db L1, REST, PAT_END
Pattern_6D18:
	db L2, REST, PAT_END
; unreferenced
Pattern_6D1B:
	db L1, REST, L2D, REST, PAT_END
Pattern_6D20:
	db L1, REST, REST, PAT_END
Pattern_6D24:
	db L8, REST, PAT_END
Pattern_6D27:
	db L8D, REST, PAT_END
Pattern_6D2A:
	db L16, REST, PAT_END
Pattern_6D2D:
	db L32, REST, PAT_END
UnusedList_6D30:
	dw Pattern_6D15
	LIST_LOOP UnusedList_6D30
; unreferenced
Pattern_6D36:
	CH3_FADEOUT_ON
	db PAT_END
Wave_6D38:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
Wave_6D48:
	db $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave_6D58:
	db $99, $99, $99, $99, $00, $00, $00, $00, $99, $99, $99, $99, $00, $00, $00, $00
Wave_6D68:
	db $44, $44, $44, $44, $00, $00, $00, $00, $44, $44, $44, $44, $00, $00, $00, $00
Pattern_6D78:
	INSTR $10, $00, $80
	db PAT_END
Pattern_6D7D:
	INSTR $20, $00, $80
	db PAT_END
Pattern_6D82:
	INSTR $24, $83, $c0
	db PAT_END
Pattern_6D87:
	INSTR $46, $86, $80
	db PAT_END
Pattern_6D8C:
	INSTR $81, $83, $c0
	db PAT_END
Pattern_6D91:
	INSTR $a2, $83, $c0
	db PAT_END
Pattern_6D96:
	INSTR $91, $83, $80
	db PAT_END
Pattern_6D9B:
	INSTR $52, $83, $c0
	db PAT_END
Pattern_6DA0:
	INSTR $62, $00, $80
	db PAT_END
Pattern_6DA5:
	INSTR $82, $00, $80
	db PAT_END
Pattern_6DAA:
	INSTR $62, $00, $c0
	db PAT_END
Pattern_6DAF:
	INSTR $92, $00, $c0
	db PAT_END
Pattern_6DB4:
	INSTR $b2, $00, $c0
	db PAT_END
Pattern_6DB9:
	INSTR $c1, $83, $00
	db PAT_END
Pattern_6DBE:
	INSTR $45, $00, $80
	db PAT_END
Pattern_6DC3:
	INSTR $53, $00, $80
	db PAT_END
Pattern_6DC8:
	INSTR $93, $00, $00
	db PAT_END
Pattern_6DCD:
	INSTR $64, $00, $80
	db PAT_END
Pattern_6DD2:
	INSTR $84, $86, $80
	db PAT_END
; unreferenced
Pattern_6DD7:
	INSTR $b4, $86, $80
	db PAT_END
; unreferenced
Pattern_6DDC:
	INSTR $e4, $86, $80
	db PAT_END
Pattern_6DE1:
	INSTR $75, $86, $80
	db PAT_END
Pattern_6DE6:
	INSTR $a5, $00, $80
	db PAT_END
Pattern_6DEB:
	INSTR $f5, $86, $80
	db PAT_END
Pattern_6DF0:
	INSTR $a5, $86, $80
	db PAT_END
Pattern_6DF5:
	INSTR $a5, $46, $80
	db PAT_END
Pattern_6DFA:
	INSTR $85, $00, $80
	db PAT_END
Pattern_6DFF:
	INSTR $e7, $86, $80
	db PAT_END
; unreferenced
Pattern_6E04:
	INSTR $17, $00, $80
	db PAT_END
Pattern_6E09:
	INSTR $27, $00, $80
	db PAT_END
Pattern_6E0E:
	INSTR $37, $00, $80
	db PAT_END
Pattern_6E13:
	INSTR $47, $00, $80
	db PAT_END
Pattern_6E18:
	INSTR $86, $00, $c0
	db PAT_END
Pattern_6E1D:
	INSTR $66, $00, $80
	db PAT_END
Pattern_6E22:
	INSTR $87, $00, $80
	db PAT_END
Pattern_6E27:
	INSTR $48, $00, $80
	db PAT_END
Pattern_6E2C:
	INSTR $38, $00, $81
	db PAT_END
Pattern_6E31:
	INSTR $48, $86, $80
	db PAT_END
; unreferenced
Pattern_6E36:
	INSTR $48, $00, $00
	db PAT_END
Pattern_6E3B:
	INSTR $58, $00, $00
	db PAT_END
Pattern_6E40:
	INSTR $a8, $86, $c0
	db PAT_END
Pattern_6E45:
	INSTR $88, $00, $00
	db PAT_END
Pattern_6E4A:
	INSTR $1f, $00, $00
	db PAT_END
Pattern_6E4F:
	INSTR $5f, $00, $80
	db PAT_END
Pattern_6E54:
	INSTR_WAVE Wave_6D38, $20
	db PAT_END
Pattern_6E59:
	INSTR_WAVE Wave_6D48, $20
	db PAT_END
Pattern_6E5E:
	INSTR_WAVE Wave_6D48, $40
	db PAT_END
Pattern_6E63:
	INSTR_WAVE Wave_6D58, $20
	db PAT_END
Pattern_6E68:
	INSTR_WAVE Wave_6D58, $40
	db PAT_END
Pattern_6E6D:
	INSTR_WAVE Wave_6D58, $60
	db PAT_END
Pattern_6E72:
	INSTR_WAVE Wave_6D68, $40
	db PAT_END
Pattern_6E77:
	INSTR_WAVE Wave_6D68, $60
	db PAT_END
Pattern_6E7C:
	TRANSPOSE $00
	db PAT_END
Pattern_6E7F:
	TRANSPOSE $18
	db PAT_END
; unreferenced
Pattern_6E82:
	TRANSPOSE $16
	db PAT_END
Pattern_6E85:
	TRANSPOSE $0e
	db PAT_END
Pattern_6E88:
	TRANSPOSE $0c
	db PAT_END
Pattern_6E8B:
	TRANSPOSE $0a
	db PAT_END
Pattern_6E8E:
	TRANSPOSE $08
	db PAT_END
Pattern_6E91:
	TRANSPOSE $06
	db PAT_END
Pattern_6E94:
	TRANSPOSE $04
	db PAT_END
Pattern_6E97:
	TRANSPOSE $02
	db PAT_END
Pattern_6E9A:
	TRANSPOSE $d0
	db PAT_END
Pattern_6E9D:
	TRANSPOSE $fe
	db PAT_END
Pattern_6EA0:
	TEMPO LengthTable_4A9D
	db PAT_END
Pattern_6EA4:
	TEMPO LengthTable_4AAC
	db PAT_END
Pattern_6EA8:
	TEMPO LengthTable_4ACA
	db PAT_END
Pattern_6EAC:
	TEMPO LengthTable_4AD9
	db PAT_END
Pattern_6EB0:
	TEMPO LengthTable_4AE8
	db PAT_END
Pattern_6EB4:
	TEMPO LengthTable_4AF7
	db PAT_END
	ds 328, 0	; $6EB8-$6FFF unused
Song41_Header:
	SONG $00, LengthTable_4AD9, Song41_Ch1, Song14_Ch1, Song41_Ch3, 0
Song41_Ch1:
	dw Pattern_701D
	dw Pattern_7097
	dw Pattern_70C0
	LIST_END
Song41_Ch3:
	dw Pattern_7026
	dw Pattern_7097
	dw Pattern_7091
	dw Pattern_70C0
	LIST_END
Pattern_701D:
	INSTR $20, $00, $81
	db L8, REST, LEN9, REST, PAT_END
Pattern_7026:
	INSTR_WAVE Wave_730F, $01
	CH3_FADEIN_ON
	db PAT_END
Song42_Header:
	SONG $00, LengthTable_4AD9, Song42_Ch1, Song42_Ch2, Song42_Ch3, 0
Song42_Ch1:
	dw Pattern_704D
	dw Pattern_7097
	dw Pattern_70C0
	LIST_END
Song42_Ch2:
	dw Pattern_7058
	LIST_END
Song42_Ch3:
	dw Pattern_7089
	dw Pattern_7097
	dw Pattern_7091
	dw Pattern_70C0
	LIST_END
Pattern_704D:
	INSTR $20, $00, $81
	db L8, REST, LEN9, REST, L1D, REST, PAT_END
Pattern_7058:
	INSTR $47, $00, $80
	CH3_SFX_PAUSE
	REPEAT $0a
	db L4, A6, D6, E6, B6
	REPEAT_END
	REPEAT $02
	db Fs6, B5, D6, Fs6, G6, B5, E6, G6
	REPEAT_END
	db A6, C6, E6, A6, C7, Ds6, Fs6, A6, G6, B5, D6, G6, E6, As5, Cs6, As6
	REPEAT $02
	db A6, D6, E6, B6
	REPEAT_END
	CH3_SFX_RESUME
	db PAT_END
Pattern_7089:
	INSTR_WAVE Wave_730F, $01
	db L1D, REST
	CH3_FADEIN_ON
	db PAT_END
Pattern_7091:
	INSTR_WAVE Wave_72E1, $01
	CH3_FADEIN_ON
	db PAT_END
Pattern_7097:
	CH3_SFX_PAUSE
	db L8, REST, B3, Cs4, L2D, D4, L8, B3, Cs4, L2D, D4, L8, Cs4, B3, Fs3, L4D
	db A3, L1, B3, L4, REST, L8, B3, Cs4, L2D, D4, L8, A3, D4, L2D, G4, L8
	db Fs4, E4, L1, Fs4, REST, L8, REST, PAT_END
Pattern_70C0:
	db L4, REST, Cs6, B5, Fs5, L4D, Fs5, L1, G5, L8, E6, D6, Cs6, B5, Fs5, E5
	db Fs5, B5, L4D, G5, L8, G5, L2, A5, L8, REST, C5, E5, A5, L2D, Fs5, L8
	db REST, D5, L2D, B5, L4D, REST, As5, G6, Fs6, REST, L2, REST, L1, REST
	CH3_SFX_RESUME
	db PAT_END
Song43_Header:
	SONG $00, LengthTable_4AD9, Song42_Ch2, Song43_Ch2, Song42_Ch3, 0
Song43_Ch2:
	dw Pattern_7107
	dw Pattern_7114
	dw Pattern_7123
	dw Pattern_7123
	dw Pattern_7133
	LIST_END
Pattern_7107:
	INSTR $71, $82, $80
	CH3_SFX_PAUSE
	REPEAT $04
	db L8, D5, Fs5, Cs6, A5
	REPEAT_END
Pattern_7114:
	REPEAT $04
	db E5, G5, D6, B5
	REPEAT_END
	REPEAT $04
	db D5, Fs5, Cs6, B5
	REPEAT_END
	db PAT_END
Pattern_7123:
	REPEAT $02
	db L8, B4, D5, B5, Fs5
	REPEAT_END
	REPEAT $02
	db B4, E5, B5, G5
	REPEAT_END
	db PAT_END
Pattern_7133:
	REPEAT $02
	db A4, C5, G5, E5
	REPEAT_END
	REPEAT $02
	db A4, C5, Fs5, Ds5
	REPEAT_END
	REPEAT $02
	db G4, B4, Fs5, D5
	REPEAT_END
	REPEAT $02
	db G4, As4, E5, Cs5
	REPEAT_END
	REPEAT $04
	db D5, Fs5, Cs6, A5
	REPEAT_END
	CH3_SFX_RESUME
	db PAT_END
Song44_Header:
	SONG $00, LengthTable_4AD9, Song44_Ch1, Song43_Ch2, Song42_Ch3, 0
Song44_Ch1:
	dw Pattern_716D
	dw Pattern_7176
	dw Pattern_7176
	dw Pattern_718A
	LIST_END
Pattern_716D:
	INSTR $87, $00, $80
	CH3_SFX_PAUSE
	db L1, A7, A7, PAT_END
Pattern_7176:
	INSTR $87, $00, $80
	db L1, A7, A7
	INSTR $37, $00, $80
	REPEAT $02
	db L4, A6, D6, E6, B6
	REPEAT_END
	db PAT_END
Pattern_718A:
	INSTR $76, $00, $80
	REPEAT $02
	db L2, B7, Fs7, B7, G7
	REPEAT_END
	db A7, G7, Fs7, A7, B7, G7, As7, G7
	INSTR $87, $00, $80
	db L1, A7, A7, PAT_END
Song45_Header:
	SONG $00, LengthTable_4AD9, Song44_Ch1, Song43_Ch2, Song42_Ch3, Song45_Ch4
Song45_Ch4:
	dw Pattern_71B5
	LIST_END
Pattern_71B5:
	REPEAT $0a
	db L16, NOISE_1F, NOISE_1F, NOISE_1F, NOISE_1F, L8, NOISE_1F, L4, NOISE_24, L8, NOISE_1F, L4, NOISE_24, L16, NOISE_1F, NOISE_1F
	db NOISE_1F, NOISE_1F, L4, NOISE_24, L16, NOISE_1F, NOISE_1F, NOISE_1F, NOISE_1F, L4, NOISE_24
	REPEAT_END
	db PAT_END
Song46_Header:
	SONG $00, LengthTable_4AD9, Song46_Ch1, Song46_Ch2, Song42_Ch3, Song45_Ch4
Song46_Ch1:
	dw Pattern_716D
	dw Pattern_7176
	dw Pattern_7176
	dw Pattern_7237
	dw Pattern_7123
	dw Pattern_7123
	dw Pattern_7133
	LIST_END
Song46_Ch2:
	dw Pattern_71F7
	dw Pattern_7204
	dw Pattern_7213
	LIST_END
Pattern_71F7:
	INSTR $19, $45, $40
	CH3_SFX_PAUSE
	REPEAT $02
	db L4, D3, A3, Fs3, A3
	REPEAT_END
Pattern_7204:
	REPEAT $02
	db E3, B3, G3, B3
	REPEAT_END
	REPEAT $02
	db D3, A3, Fs3, A3
	REPEAT_END
	db PAT_END
Pattern_7213:
	REPEAT $02
	db L4, B2, Fs3, D3, Fs3, B2, G3, E3, G3
	REPEAT_END
	db A3, E3, C3, E3, A3, Ds3, C3, Ds3, G3, D3, B2, D3, G3, Cs3, As2, Cs3
	REPEAT $02
	db D3, A3, Fs3, A3
	REPEAT_END
	db PAT_END
Pattern_7237:
	INSTR $61, $82, $80
	db PAT_END
Song47_Header:
	SONG $00, LengthTable_4AD9, Song43_Ch2, Song47_Ch2, Song42_Ch3, Song47_Ch4
Song47_Ch2:
	dw Pattern_716D
	dw Pattern_7176
	dw Pattern_7176
	dw Pattern_727D
	dw Pattern_7213
	LIST_END
Song47_Ch4:
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7295
	dw Pattern_7282
	dw Pattern_7295
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	dw Pattern_7282
	LIST_END
Pattern_727D:
	INSTR $19, $45, $40
	db PAT_END
Pattern_7282:
	REPEAT $03
	db L8, NOISE_1A, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15
	REPEAT_END
	db L8, NOISE_1A, NOISE_1A, PAT_END
Pattern_7295:
	REPEAT $02
	db L16, NOISE_1F, NOISE_1F, NOISE_1F, NOISE_1F, L8, NOISE_1F, L4, NOISE_24, L8, NOISE_1F, L4, NOISE_24, PAT_END
Song20_Header:
	SONG $00, LengthTable_4AE8, Song14_Ch1, Song20_Ch2, Song20_Ch3, 0
Song20_Ch2:
	dw Pattern_72BA
	dw Pattern_72C8
	LIST_END
Song20_Ch3:
	dw Pattern_72C3
	LIST_END
Pattern_72BA:
	INSTR $20, $00, $41
	db L16, REST, L32, REST, PAT_END
Pattern_72C3:
	INSTR_WAVE Wave_72E1, $01
	CH3_FADEIN_ON
Pattern_72C8:
	db L8, B5, Cs6, L2D, D6, L8, B5, Cs6, L2, D6, L8, Cs6, L8D, B5, L4, Fs5
	db L1D, Fs6
	CH3_FADEOUT_OFF
	REPEAT $20
	db L1, REST
	REPEAT_END
	db PAT_END
Wave_72E1:
	db $01, $35, $66, $53, $10, $02, $46, $8a, $01, $35, $66, $53, $10, $02, $46, $8a
Song28_Header:
	SONG $00, LengthTable_4AF7, Song14_Ch1, Song28_Ch2, Song28_Ch3, 0
Song28_Ch2:
	dw Pattern_7306
	dw Pattern_7324
	LIST_END
Song28_Ch3:
	dw Pattern_731F
	LIST_END
Pattern_7306:
	INSTR $20, $00, $41
	db L16, REST, L32, REST, PAT_END
Wave_730F:
	db $06, $9b, $cd, $de, $ee, $ff, $ff, $fe, $06, $9b, $cd, $de, $ee, $ff, $ff, $fe
Pattern_731F:
	INSTR_WAVE Wave_730F, $01
	CH3_FADEIN_ON
Pattern_7324:
	db L16, B3, Cs4, L2, D4, L4, REST, L16, B3, Cs4, L8, D4, Cs4, L8D, B3, L4
	db Fs3, L8, REST, L1, Fs4
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song29_Header:
	SONG $00, LengthTable_4AD9, Song14_Ch1, Song29_Ch2, Song29_Ch3, 0
Song29_Ch2:
	dw Pattern_735A
	dw Pattern_735A
	dw Pattern_736A
	LIST_LOOP UnusedList_78BB
Song29_Ch3:
	dw Pattern_7380
	LIST_LOOP UnusedList_78BB
Pattern_735A:
	INSTR $81, $00, $80
	db L16, A6, D6, E6, B6
	INSTR $a6, $00, $80
	db L2, A6, PAT_END
Pattern_736A:
	INSTR $82, $00, $80
	db L8, A6, D6, L8D, E6
	INSTR $85, $00, $80
	db L4, B6
	INSTR $a6, $00, $80
	db L1D, A6, PAT_END
Pattern_7380:
	INSTR_WAVE Wave_750C, $23
	CH3_FADEOUT_ON
	REPEAT $02
	db L16, E6, A5, B5, Fs6, L2, E6
	REPEAT_END
	db L8, E6, A5, L8D, B5, L4, Fs6, L1D, E6
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song2A_Header:
	SONG $18, LengthTable_4A9D, Song14_Ch1, Song2A_Ch2, Song2A_Ch3, 0
Song2A_Ch2:
	dw Pattern_73B3
	dw Pattern_73D1
	LIST_END
Song2A_Ch3:
	dw Pattern_73CC
	LIST_END
Pattern_73B3:
	INSTR $10, $00, $80
	db L4, REST, L16, REST, PAT_END
Wave_73BC:
	db $46, $79, $98, $64, $43, $10, $01, $34, $46, $79, $98, $64, $43, $10, $01, $34
Pattern_73CC:
	INSTR_WAVE Wave_73BC, $20
	CH3_FADEOUT_ON
Pattern_73D1:
	db L4, C6, B5, G5, E5, L8D, C5, B4, C5, E5, G5, LEN11, B5, G5, E5, C5
	db L8, B4, C5, E5, G5, B5, G5, E5, C5, B4, C5, E5, G5
	REPEAT $02
	db As5, Fs5, Ds5, B4, As4, B4, Ds5, Fs5
	REPEAT_END
	db G5, Ds5, C5, Gs4, G4, Gs4, C5, Ds5, LEN11, F5, Cs5, As4, Fs4, L8D, F4, Fs4
	db L4, As4, Cs5, LEN10, REST, L8, Ds5
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song2B_Header:
	SONG $00, LengthTable_4ABB, Song2B_Ch1, Song2B_Ch2, Song2B_Ch3, 0
Song2B_Ch1:
	dw Pattern_7433
	LIST_LOOP UnusedList_78BB
Song2B_Ch2:
	dw Pattern_7458
	LIST_LOOP UnusedList_78BB
Song2B_Ch3:
	dw Pattern_748C
	LIST_LOOP UnusedList_78BB
Pattern_7433:
	INSTR $81, $00, $80
	db L16, REST, L8, Fs6
	INSTR $c1, $00, $80
	db L8, Fs6, L8D, REST, L2, REST
	INSTR $a2, $00, $80
	db L8, REST, L4, Cs6, E6, A6, E6, B6
	INSTR $a7, $00, $80
	db L1D, A7, PAT_END
Pattern_7458:
	INSTR $61, $00, $80
	db L8, Fs6
	INSTR $a1, $00, $80
	db L8, Fs6
	INSTR $e5, $00, $80
	db L2D, Fs6
	INSTR $a2, $00, $80
	db L4, B5, D6, Fs6, Gs6, Fs6, E7
	INSTR $a7, $00, $80
	db L1D, Fs7, PAT_END
Wave_747C:
	db $66, $00, $66, $00, $66, $00, $66, $00, $66, $00, $66, $00, $66, $00, $66, $00
Pattern_748C:
	INSTR_WAVE Wave_747C, $23
	CH3_FADEOUT_ON
	db L16, Cs6, Cs6, Cs6, Cs6, L2D, Cs6, L8, Fs5, Gs5, A5, B6, Cs6, E6, Ds6, B5
	db Cs6, Fs6, B6, E7, L1D, Cs7, PAT_END
Song2C_Header:
	SONG $00, LengthTable_4ACA, Song14_Ch1, Song2C_Ch2, Song2C_Ch3, 0
Song2C_Ch2:
	dw Pattern_74D3
	dw Pattern_74EC
	dw Pattern_74D3
	dw Pattern_74FE
	dw Pattern_74D3
	dw Pattern_74FE
	dw Pattern_74D3
	dw Pattern_74EC
	dw Pattern_74D3
	dw Pattern_74FE
	dw Pattern_74D3
	dw Pattern_7505
	dw Pattern_7540
	LIST_END
Song2C_Ch3:
	dw Pattern_751C
	LIST_END
Pattern_74D3:
	INSTR $21, $00, $80
	db L16, B6
	INSTR $41, $00, $80
	db L16, B6
	INSTR $71, $00, $80
	db L16, B6
	INSTR $a1, $00, $80
	db L16, B6, PAT_END
Pattern_74EC:
	INSTR $a1, $00, $80
	db L8, B6
	INSTR $c3, $00, $80
	db L4, B6
	INSTR $82, $00, $80
	db L8, B6
Pattern_74FE:
	INSTR $d2, $00, $80
	db L4, B6, PAT_END
Pattern_7505:
	INSTR $e3, $00, $80
	db L1D, B6, PAT_END
Wave_750C:
	db $00, $0c, $00, $0c, $00, $0c, $00, $0c, $06, $06, $06, $06, $06, $06, $06, $06
Pattern_751C:
	INSTR_WAVE Wave_750C, $20
	CH3_FADEOUT_ON
	REPEAT $02
	db L16, Fs7, Fs7, Fs7, Fs7, L8, Fs7, L4, Fs7, L8, Fs7, L4, Fs7, L16, Fs7, Fs7
	db Fs7, Fs7, L4, Fs7, L16, Fs7, Fs7, Fs7, Fs7, L4, Fs7
	REPEAT_END
	CH3_FADEOUT_OFF
Pattern_7540:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song2D_Header:
	SONG $00, LengthTable_4AE8, Song14_Ch1, Song2D_Ch2, Song2D_Ch3, 0
Song2D_Ch2:
	dw Pattern_755F
	dw Pattern_757D
	LIST_LOOP UnusedList_78BB
Song2D_Ch3:
	dw Pattern_7578
	LIST_LOOP UnusedList_78BB
Pattern_755F:
	INSTR $20, $00, $80
	db L8, REST, LEN9, REST, PAT_END
Wave_7568:
	db $88, $88, $88, $84, $00, $00, $00, $00, $88, $88, $88, $84, $00, $00, $00, $00
Pattern_7578:
	INSTR_WAVE Wave_7568, $00
	CH3_FADEIN_ON
Pattern_757D:
	db L8, B4, Cs5, L2D, D5, L8, B4, Cs5, L4, D5, Cs5, B4, L32, REST, L4, Fs4
	db L16, REST, L1, Fs5, PAT_END
Song2E_Header:
	SONG $00, LengthTable_4AD9, Song14_Ch1, Song2E_Ch2, Song14_Ch1, Song2E_Ch4
Song2E_Ch2:
	dw Pattern_75B5
	dw Pattern_75B5
	dw Pattern_75CB
	dw Pattern_75B5
	dw Pattern_75B5
	dw Pattern_75CB
	LIST_LOOP UnusedList_78BB
Song2E_Ch4:
	dw Pattern_75E2
	dw Pattern_75E2
	dw Pattern_75FA
	LIST_END
Pattern_75B5:
	INSTR $a1, $00, $80
	DROP_ON
	db L8, D4
	INSTR $61, $00, $80
	db LEN9, A3, LEN13, REST, LEN9, A3, LEN13, REST, LEN9, A3, PAT_END
Pattern_75CB:
	db L16, A3
	INSTR $a1, $00, $80
	db L16, D4
	INSTR $61, $00, $80
	db L16, A3, A3
	INSTR $a1, $00, $80
	db L8, D4, D4, PAT_END
Pattern_75E2:
	REPEAT $02
	db L8, DRUM, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15, LEN13, REST, LEN9, NOISE_15
	REPEAT_END
	db L16, NOISE_15, DRUM, NOISE_15, NOISE_15, L8, DRUM, DRUM, PAT_END
Pattern_75FA:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song2F_Header:
	SONG $00, LengthTable_4AD9, Song2F_Ch1, Song2F_Ch2, Song2F_Ch3, 0
Song2F_Ch1:
	dw Pattern_7627
Song2F_Ch1_Loop:
	dw Pattern_7634
	dw Pattern_764A
	dw Pattern_765D
	LIST_LOOP Song2F_Ch1_Loop
Song2F_Ch2:
	dw Pattern_7630
	dw Pattern_764A
	dw Pattern_765D
	LIST_LOOP Song2F_Ch2
Song2F_Ch3:
	dw Pattern_768A
	LIST_LOOP Song2F_Ch1_Loop
Pattern_7627:
	INSTR $20, $00, $80
	db L16, REST, LEN9, REST, PAT_END
Pattern_7630:
	INSTR $60, $21, $80
Pattern_7634:
	db L8, REST, B5, Cs6, L2D, D6, L8, B5, Cs6, L2D, D6, L8, Cs6, B5, Fs5, L4D
	db A5, L1, B5, L4, REST, PAT_END
Pattern_764A:
	db L8, B5, Cs6, L2D, D6, L8, A5, D6, L2D, G6, L8, Fs6, E6, L1, Fs6, REST
	db L4D, REST, PAT_END
Pattern_765D:
	db L4, Cs7, B6, Fs6, L4D, Fs6, L1, G6, L8, E7, D7, Cs7, B6, Fs6, E6, Fs6
	db B6, L4D, G6, L8, G6, L2, A6, L8, REST, C6, E6, A6, L2D, Fs6, L8, REST
	db D6, L1, B6, L8, REST, L4D, As6, G7, Fs7, REST, L1, REST, PAT_END
Pattern_768A:
	INSTR_WAVE Wave_6D68, $60
	db L4, REST, L16, REST, PAT_END
Song4A_Header:
	SONG $00, LengthTable_4AD9, Song4A_Ch1, Song4A_Ch2, Song4A_Ch3, 0
Song4A_Ch1:
	dw Pattern_76BE
Song4A_Ch1_Loop:
	dw Pattern_7114
	dw Pattern_7114
	dw Pattern_7123
	dw Pattern_7123
	dw Pattern_7133
	LIST_LOOP Song4A_Ch1_Loop
Song4A_Ch2:
	dw Pattern_7630
	dw Pattern_76C7
	dw Pattern_765D
	LIST_LOOP Song4A_Ch2
Song4A_Ch3:
	dw Pattern_76EB
	LIST_LOOP Song4A_Ch3
Pattern_76BE:
	INSTR $19, $42, $40
	db L4D, REST, L8, REST, PAT_END
Pattern_76C7:
	db L8, B3, Cs4, L2D, D4, L8, A3, D4, L2D, G4, L8, Fs4, E4, L1D, Fs4, L2
	db REST, L4D, REST, PAT_END
Wave_76DB:
	db $01, $37, $9a, $bb, $bb, $bb, $a6, $21, $01, $37, $9a, $bb, $bb, $bb, $a6, $21
Pattern_76EB:
	INSTR_WAVE Wave_76DB, $40
	REPEAT $08
	db L1, REST
	REPEAT_END
	db L2D, REST, L4, E6, D6, L8D, A5, L16, REST, L4D, A5, L2D, B5, L4, REST, L16
	db G6, REST, Fs6, REST, E6, REST, D6, REST, A5, REST, G5, REST, A5, REST, D6, REST
	db L8D, B5, REST, L8, B5, L4D, C6, L4, REST, L16, E5, REST, G5, REST, C6, REST
	db L2, A5, L4D, REST, L8, Fs5, L2D, D6, L4D, REST, L4, Cs6, L8, REST, L4, As5
	db L8, REST, L4, A5, L2, REST, L1, REST, PAT_END
Song30_Header:
	SONG $00, LengthTable_4B06, Song30_Ch1, Song30_Ch2, Song30_Ch3, Song30_Ch4
Song30_Ch1:
	dw Pattern_7758
	LIST_END
Song30_Ch2:
	dw Pattern_77A3
	LIST_END
Song30_Ch3:
	dw Pattern_7827
	LIST_END
Song30_Ch4:
	dw Pattern_788C
	LIST_END
Pattern_7758:
	INSTR $62, $00, $00
	db L16, D3, E3, F3, L8D, Fs3, L16, Fs3, G3, Gs3, L8D, A3, L16, A3, B3, C4
	db Cs4, L4, D4
	DROP_ON
	db F4
	DROP_OFF
	INSTR $41, $00, $80
	REPEAT $06
	db L8, B6, L16, D7, L8, A6, D7, B6, D7, L16, B6, L8, A6, D7
	REPEAT_END
	INSTR $61, $00, $40
	db L8D, G6, L16, G6, F6, L8, A6, G6, G6, L16, G6, L8, F6, A6, G7, G7
	db F7, L4D, G7
	DROP_ON
	db L4, A3
	DROP_OFF
	db PAT_END
Pattern_77A3:
	INSTR $81, $00, $40
	db L16, Fs4, G4, Gs4, L8D, A4, L16, A4, As4, B4, L8D, C5, L16, C5, D5, E5
	db F5, L2, Fs5, L1D, REST
	DROP_ON
	db L16, REST, L8, C5, L16, C5, L8, G4, L16, B3, B3
	DROP_OFF
	db L8D, B3, L16, B3, A3, L8, C4, B3, B3, L16, B3, L8, A3, C4, L8D, B3
	db L16, B3, A3, L8, C4, L8, B3
	DROP_ON
	db C5, L16, C5, L8, G4, L16, B3, B3
	DROP_OFF
	db L8D, D4, L16, D4, C4, L8, E4, D4, D4, L16, D4, L8, C4, E4, L8D, D4
	db L16, D4, C4, L8, E4, L8, D4
	DROP_ON
	db C5, L16, C5, L8, G4, L16, B3, B3
	DROP_OFF
	db L8D, G2, L16, G2, F2, L8, A2, G2, G2, L16, G2, L8, F2, A2, G2, G2
	db F2, L4D, G2
	INSTR $a1, $00, $80
	DROP_ON
	db L4, F4
	DROP_OFF
	db PAT_END
Pattern_7827:
	INSTR_WAVE Wave_730F, $20
	CH3_FADEOUT_ON
	db L16, D5, E5, F5, L8D, Fs5, L16, Fs5, G5, Gs5, L8D, A5, L16, A5, B5, C6
	db Cs6, L2, D6
	REPEAT $02
	db L8D, G3, L16, G3, F3, L8, A3, G3, G3, L16, G3, L8, F3, A3, L8D, G3
	db L16, G3, F3, L8, A3, G3, L8D, REST, L4, REST
	REPEAT_END
	db L8D, B3, L16, B3, A3, L8, C4, B3, B3, L16, B3, L8, A3, C4, L8D, B3
	db L16, B3, A3, L8, C4, B3, L8D, REST, L4, REST, L8D, G4, L16, G4, F4, L8
	db A4, G4, G4, L16, G4, L8, F4, A4, G4, G4, F4, L4D, G4, L4, REST, PAT_END
Pattern_788C:
	db L1, REST, L4, REST, DRUM
	REPEAT $06
	db L16, NOISE_1A, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, DRUM, NOISE_1A, NOISE_1A, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, DRUM
	db DRUM
	REPEAT_END
	db L8D, DRUM, L16, DRUM, DRUM, L8, DRUM, DRUM, DRUM, L16, DRUM, L8, DRUM, DRUM, DRUM, DRUM
	db DRUM, L4D, DRUM, L4, DRUM, PAT_END
UnusedList_78BB:
	dw Pattern_78C1
	LIST_LOOP UnusedList_78BB
Pattern_78C1:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
UnusedList_78C7:
	dw Pattern_78CD
	LIST_LOOP UnusedList_78C7
Pattern_78CD:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
Song48_Header:
	SONG $00, LengthTable_4AD9, Song48_Ch1, Song48_Ch2, Song48_Ch3, 0
Song48_Ch1:
	dw Pattern_78F2
	LIST_LOOP Song48_Ch1
Song48_Ch2:
	dw Pattern_7960
	LIST_LOOP Song48_Ch2
Song48_Ch3:
	dw Pattern_79B7
Song48_Ch3_Loop:
	dw Pattern_79BE
	LIST_LOOP Song48_Ch3_Loop
Pattern_78F2:
	INSTR $42, $82, $80
	REPEAT $02
	db L8, G4, D5, A5, B5, L2, REST, L8, G4, E5, B5, C6, L2, REST
	REPEAT_END
	db L8, G4, D5, A5, B5, L2, REST, L8, G4, Cs5, A5, As5, L2, REST, L8, A4
	db E5, B5, C6, L2, REST, L8, Gs4, B4, D5, F5, E5, L4D, REST, L8, A4, Cs5
	db E5, G5, L2, REST, L8, C5, Ds5, Fs5, A5, L2, REST, L8, B4, D5, Fs5, A5
	db L2, REST, L8, B4, D5, Fs5, G5, L2, REST, L8, A4, C5, E5, G5, L2, REST
	db L8, A4, Cs5, E5, G5, L2, REST, L8, B4, D5, Fs5, D5, As4, Cs5, E5, Cs5
	db A4, C5, E5, C5, A4, C5, Ds5, C5, PAT_END
Pattern_7960:
	INSTR $50, $44, $80
	REPEAT $02
	db L2, D6, G5, A5, L4, REST, L8, B5, C6
	REPEAT_END
	db L4, B5, D6, L2, A6, L4, REST, G6, A6, G6, D6, L8, C6, B5, L2, A5
	db REST, L8, REST, B5, C6, D6, L2, E6, G5, Fs5, L4, REST, L8, A5, E6, L2
	db D6, Fs5, G5, L4, REST, L8, G5, Fs5, L4, E5, G5, L2, B5, L4, REST, A5
	db G5, Ds5, L2, D5, L1D, REST, PAT_END
Wave_79A7:
	db $11, $11, $11, $10, $00, $00, $00, $00, $11, $11, $11, $10, $00, $00, $00, $00
Pattern_79B7:
	INSTR_WAVE Wave_79A7, $20
	db L8, REST, PAT_END
Pattern_79BE:
	REPEAT $02
	db L2, D6, G5, A5, L4, REST, L8, B5, C6
	REPEAT_END
	db L4, B5, D6, L4D, A6, REST, L4, G6, A6, G6, D6, L8, C6, B5, L4D, A5
	db L2, REST, L8, REST, REST, B5, C6, D6, L2, E6, G5, L4D, Fs5, REST, L8, A5
	db E6, L2, D6, Fs5, L4D, G5, REST, L8, G5, Fs5, L4, E5, G5, L4D, B5, REST
	db L4, A5, G5, Ds5, L4D, D5, L8, REST, L1D, REST, PAT_END
Song55_Header:
	SONG $00, LengthTable_4ACA, Song55_Ch1, Song55_Ch2, Song55_Ch3, 0
Song55_Ch1:
	dw Pattern_7A3E
	dw Pattern_7A32
	dw Pattern_7A43
	dw Pattern_7A32
	dw Pattern_7A48
	dw Pattern_7A32
	dw Pattern_7A43
	dw Pattern_7A32
	LIST_LOOP Song55_Ch1
Song55_Ch2:
	dw Pattern_7A4D
	LIST_LOOP Song55_Ch2
Song55_Ch3:
	dw Pattern_79B7
Song55_Ch3_Loop:
	dw Pattern_7A51
	LIST_LOOP Song55_Ch3_Loop
Pattern_7A32:
	REPEAT $02
	db LEN12, Cs7, D7
	REPEAT_END
	REPEAT $02
	db E7, F7
	REPEAT_END
	db PAT_END
Pattern_7A3E:
	INSTR $10, $00, $00
	db PAT_END
Pattern_7A43:
	INSTR $20, $00, $00
	db PAT_END
Pattern_7A48:
	INSTR $30, $00, $00
	db PAT_END
Pattern_7A4D:
	INSTR $1a, $81, $40
Pattern_7A51:
	REPEAT $20
	db L8, C6, F6, As6, B6
	REPEAT_END
	db PAT_END
Song56_Header:
	SONG $00, LengthTable_4AF7, Song56_Ch1, Song56_Ch2, Song14_Ch1, 0
Song56_Ch1:
	dw Pattern_7A7B
	dw Pattern_7A87
Song56_Ch1_Loop:
	dw Pattern_7B16
	dw Pattern_7B1F
	LIST_LOOP Song56_Ch1_Loop
Song56_Ch2:
	dw Pattern_7A82
	dw Pattern_7A87
Song56_Ch2_Loop:
	dw Pattern_7B1B
	LIST_LOOP Song56_Ch2_Loop
Pattern_7A7B:
	INSTR $42, $00, $80
	db L16, REST, PAT_END
Pattern_7A82:
	INSTR $81, $00, $80
	db PAT_END
Pattern_7A87:
	db L1, REST, L8, REST
	DROP_ON
	db L32, As3, B3, Fs4, G4, As4, G4, Ds4, B3, C4, Cs4, F4, A4, C5, A4, F4
	db Cs4, D4, Ds4, G4, B4, D5, B4, G4, Ds4, E4, F4, A4, Cs5, E5, Cs5, A4
	db F4, Fs4, G4, B4, Ds5, Fs5, Ds5, B4, G4, Gs4, A4, Cs5, F5, Gs5, F5, Cs5
	db A4, As4, B4, Ds5, G5, As5, G5, Ds5, B4, C5, Cs5, F5, A5, C6, A5, F5
	db Cs5, D5, Ds5, G5, B5, D6, B5, G5, Ds5, E5, F5, A5, Cs6, E6, Cs6, A5
	db F5
	REPEAT $02
	db Fs5, G5, B5, Ds6, Fs6, Ds6, B5, G5, Fs5, Ds5, B4, G4, B4, Ds5
	REPEAT_END
	db Fs5, G5, B5, Ds6, Fs6, Ds6, B5, G5, Ds6, B5, G5, Fs5, B5, G5, Fs5, Ds5
	db G5, Fs5, Ds5, B4, Fs5, Ds5, B4, G4, Ds5, B4, G4, Ds4, B4, G4, Fs4, Ds4
	db G4, Fs4, Ds4, B3, L1, G3
	DROP_OFF
	db PAT_END
Pattern_7B16:
	INSTR $10, $00, $80
	db PAT_END
Pattern_7B1B:
	INSTR $1a, $81, $40
Pattern_7B1F:
	REPEAT $20
	db LEN10, C6, F6, As6, B6
	REPEAT_END
	db PAT_END
Song57_Header:
	SONG $0e, LengthTable_4ABB, Song57_Ch1, Song57_Ch2, Song57_Ch3, 0
Song57_Ch1:
	dw Pattern_7B45
	LIST_LOOP Song57_Ch1
Song57_Ch2:
	dw Pattern_7B61
	LIST_LOOP Song57_Ch2
Song57_Ch3:
	dw Pattern_7B90
	LIST_LOOP Song57_Ch3
Pattern_7B45:
	INSTR $62, $00, $40
	REPEAT $20
	db L4, C4, L8, E4, L4, G4, L8, B4, L2D, A4, L4, A3, L8, D4, L4, F4
	db L8, A4, L2D, G4
	REPEAT_END
	db PAT_END
Pattern_7B61:
	INSTR $50, $21, $80
	db L1D, REST, REST, L2D, G5, L4, REST, L8, D5, L4, E5, L8, G4, L1, A4, L8
	db REST, L4, E5, L8, A5, L2D, G5, L4, REST, L8, D5, L4, E5, L8, G4, L1
	db A4, L8, REST, L4, G4, L8, E5, L1D, C5, REST, PAT_END
Pattern_7B90:
	INSTR_WAVE Wave_4BF9, $40
	REPEAT $20
	db L1, REST, L16, A5, REST, L4D, A6, L1, REST, L16, G5, REST, L4D, G6
	REPEAT_END
	db PAT_END
Song25_Header:
	SONG $00, LengthTable_4AE8, Song25_Ch1, Song25_Ch2, Song25_Ch3, Song25_Ch4
Song25_Ch1:
	dw Pattern_7BC9
	LIST_LOOP Song18_Ch1
Song25_Ch2:
	dw Pattern_7BE0
	LIST_LOOP Song18_Ch2
Song25_Ch3:
	dw Pattern_7C06
	LIST_LOOP UnusedList_78BB
Song25_Ch4:
	dw Pattern_7C1A
	LIST_LOOP UnusedList_78C7
Pattern_7BC9:
	INSTR $80, $81, $00
	CH3_SFX_PAUSE
	db L16, E5, A5, D6, B5, E6, A6
	INSTR $80, $00, $00
	db L2, Fs6, REST
	TEMPO LengthTable_4AD9
	db PAT_END
Pattern_7BE0:
	INSTR $40, $81, $40
	db L16, Gs4, Cs5, Fs5, Ds5, Gs5, Cs6
	INSTR $40, $00, $40
	db L2, As5, REST
	TEMPO LengthTable_4AD9
	db PAT_END
Wave_7BF6:
	db $aa, $aa, $aa, $a8, $00, $00, $00, $00, $aa, $aa, $aa, $a8, $00, $00, $00, $00
Pattern_7C06:
	INSTR_WAVE Wave_7BF6, $20
	CH3_FADEOUT_ON
	db L16, B3, E4, A4, Fs4, B4, E5
	CH3_FADEOUT_OFF
	db L2, Cs5, REST
	TEMPO LengthTable_4AD9
	db PAT_END
Pattern_7C1A:
	REPEAT $06
	db L16, NOISE_1A
	REPEAT_END
	REPEAT $10
	db L32, NOISE_15
	REPEAT_END
	TEMPO LengthTable_4AD9
	db PAT_END
Song59_Header:
	SONG $00, LengthTable_4ACA, Song59_Ch1, Song59_Ch2, Song14_Ch1, Song59_Ch4
Song59_Ch1:
	dw Pattern_7C47
Song59_Ch1_Loop:
	dw Pattern_7C4E
	LIST_LOOP Song59_Ch1_Loop
Song59_Ch2:
	dw Pattern_7C93
	LIST_LOOP Song59_Ch2
Song59_Ch4:
	dw Pattern_7CF9
	LIST_LOOP Song59_Ch4
Pattern_7C47:
	INSTR $10, $00, $80
	db L16, REST, PAT_END
Pattern_7C4E:
	db LEN12, B7, Fs7, As7, F7, A7, E7, Gs7, Ds7, G7, D7, Fs7, B6, F7, As6, E7
	db A6, Ds7, Gs6, LEN12, Fs7, B6, F7, As6, E7, A6, Ds7, Gs6, LEN13, Cs7, C7, Gs6
	db F6, Ds6, Cs6, C6, Gs5, F5, Ds5, LEN13, Cs6, C6, Gs5, F5, Ds5, L1D, REST, LEN13
	db C7, Gs6, LEN13, C7, Gs6, L1, REST, REST, LEN13, C6, Cs6, Gs6, F6, C6, Cs6, Gs6
	db F6, L1, REST, REST, PAT_END
Pattern_7C93:
	INSTR $39, $00, $00
	db LEN12, B7, Fs7, As7, F7, A7, E7, Gs7, Ds7, G7, D7, Fs7, B6, F7, As6, E7
	db A6, Ds7, Gs6
	INSTR $20, $00, $40
	db LEN12, Fs7, B6, F7, As6, E7, A6, Ds7, Gs6
	INSTR $29, $00, $00
	db LEN13, Cs7, C7, Gs6, F6, Ds6, Cs6, C6, Gs5, F5, Ds5
	INSTR $20, $00, $40
	db LEN13, Cs6, C6, Gs5, F5, Ds5, L1D, REST
	INSTR $29, $00, $00
	db LEN13, C7, Gs6
	INSTR $20, $00, $40
	db LEN13, C7, Gs6, L1, REST, REST
	INSTR $29, $00, $00
	db LEN13, C6, Cs6, Gs6, F6
	INSTR $20, $00, $40
	db LEN13, C6, Cs6, Gs6, F6, L1, REST, REST, PAT_END
Pattern_7CF9:
	REPEAT $20
	db L4, NOISE_38
	REPEAT_END
	db PAT_END
Song5E_Header:
	SONG $00, LengthTable_4ACA, Song5E_Ch1, Song5E_Ch2, Song14_Ch1, 0
Song5E_Ch1:
	dw Pattern_7D28
Song5E_Ch1_Loop:
	dw Pattern_7D36
	LIST_LOOP Song5E_Ch1_Loop
Song5E_Ch2:
	dw Pattern_7D33
Song5E_Ch2_Loop:
	dw Pattern_7D3C
	dw Pattern_7D36
	dw Pattern_7D41
	dw Pattern_7D36
	dw Pattern_7D46
	dw Pattern_7D36
	dw Pattern_7D41
	dw Pattern_7D36
	LIST_LOOP Song5E_Ch2_Loop
Pattern_7D28:
	INSTR $20, $00, $43
	db L4D, REST, L16, REST, L32, REST, PAT_END
Pattern_7D33:
	db L4D, REST, PAT_END
Pattern_7D36:
	db L16, Ds3, E3, Ds3, E3, PAT_END
Pattern_7D3C:
	INSTR $20, $00, $40
	db PAT_END
Pattern_7D41:
	INSTR $30, $00, $40
	db PAT_END
Pattern_7D46:
	INSTR $40, $00, $40
	db PAT_END
Song5F_Header:
	SONG $00, LengthTable_4AAC, Song5F_Ch1, Song5F_Ch2, Song5F_Ch3, 0
Song5F_Ch1:
	dw Pattern_7D6E
Song5F_Ch1_Loop:
	dw Pattern_7D84
	LIST_LOOP Song5F_Ch1_Loop
Song5F_Ch2:
	dw Pattern_7D7A
Song5F_Ch2_Loop:
	dw Pattern_7D84
	LIST_LOOP Song5F_Ch2_Loop
Song5F_Ch3:
	dw Pattern_7DF8
Song5F_Ch3_Loop:
	dw Pattern_7D84
	LIST_LOOP Song5F_Ch3_Loop
Pattern_7D6E:
	INSTR $10, $00, $40
	db L1, REST, REST, L2D, REST, LEN10, REST, PAT_END
Pattern_7D7A:
	INSTR $20, $00, $00
	db L1, REST, REST, L2D, REST, PAT_END
Pattern_7D84:
	db L16, As7, Gs7, G7, Ds7, C7, As6, Gs6, G6, Ds6, C6, As5, Gs5, G5, Ds5, C5
	db As4, Gs4, G4, Ds4, C4, As3, Gs3, As3, C4, Ds4, G4, Gs4, As4, C5, Ds5, G5
	db Gs5, As5, C6, Ds6, G6, Gs6, As6, C7, Ds7, G7, Gs7, As7, Gs7, Fs7, Ds7, B6
	db As6, Gs6, Fs6, Ds6, B5, As5, Gs5, Fs5, Ds5, B4, As4, Gs4, Fs4, Ds4, B3, Cs4
	db Ds4, Fs4, Gs4, As4, B4, Cs4, Ds5, Fs5, Gs5, As5, B5, Cs4, Ds6, Fs6, Gs6, As6
	db As6, Gs6, F6, Cs6, C6, As5, Gs5, F5, Cs5, C5, As4, Gs4, F4, Cs4, C4, As3
	db C4, Cs4, F4, Gs4, As4, C5, Cs5, F5, Gs5, As5, C6, Cs6, F6, Gs6, As6, C7
	db Cs7, F7, Gs7, PAT_END
Pattern_7DF8:
	INSTR_WAVE Wave_79A7, $20
	db L1, REST, REST, L2D, REST, L4, REST, PAT_END
Song60_Header:
	SONG $00, LengthTable_4AD9, Song60_Ch1, Song60_Ch2, Song60_Ch3, Song60_Ch4
Song60_Ch1:
	dw Pattern_7E2F
Song60_Ch1_Loop:
	dw Pattern_7E70
	LIST_LOOP Song60_Ch1_Loop
Song60_Ch2:
	dw Pattern_7E3A
Song60_Ch2_Loop:
	dw Pattern_7E96
	LIST_LOOP Song60_Ch2_Loop
Song60_Ch3:
	dw Pattern_7E55
Song60_Ch3_Loop:
	dw Pattern_7EFE
	LIST_LOOP Song60_Ch3_Loop
Song60_Ch4:
	dw Pattern_7E60
Song60_Ch4_Loop:
	dw Pattern_7F76
	LIST_LOOP Song60_Ch4_Loop
Pattern_7E2F:
	INSTR $60, $00, $41
	db L4D, REST, LEN10, D5, L1D, Ds5, PAT_END
Pattern_7E3A:
	INSTR $40, $00, $01
	db L4D, REST, LEN10, Cs6, L1D, D6, PAT_END
Wave_7E45:
	db $8a, $df, $da, $86, $31, $01, $36, $86, $8a, $df, $da, $86, $31, $01, $36, $86
Pattern_7E55:
	INSTR_WAVE Wave_7E45, $20
	db L4D, REST, LEN10, Gs5, L1D, A5, PAT_END
Pattern_7E60:
	db L4D, REST, LEN10, REST, L1, REST, L16, DRUM, L8, DRUM, DRUM, L16, DRUM, L8, DRUM, PAT_END
Pattern_7E70:
	INSTR $41, $00, $80
	REPEAT $07
	db L8D, E7, E7, L4, E7, L8, E7, L4, E7
	REPEAT_END
	INSTR $61, $00, $80
	DROP_ON
	db L8, A4, L8D, A4, L16, A4, A4, L4, A4, L8, A4, L16, A4, L8, A4
	DROP_OFF
	db PAT_END
Pattern_7E96:
	INSTR $60, $21, $41
	db L4, As4, L4D, F4, L16, REST, As4, As4, C5, Cs5, Ds5, L2D, F5, LEN10, F5, Fs5
	db Gs5, LEN13, REST, L2D, As5, LEN10, As5, Gs5, Fs5, LEN13, REST, L8D, Gs5, L16, Fs5, L2
	db F5, L4, F5, L8, Ds5, L16, Ds5, F5, L2, Fs5, L8, F5, Ds5, L8, Cs5, L16
	db Cs5, Ds5, L2, F5, L8, Ds5, Cs5, L8, C5, L16, C5, D5, L2, E5, L4, G5
	INSTR $62, $00, $40
	db L8, F5, L8D, F5, L16, F5, F5, L4, F5, L8, F5, L16, F5, L8, F5, PAT_END
Wave_7EEE:
	db $00, $11, $22, $33, $44, $55, $67, $89, $00, $00, $00, $05, $00, $00, $00, $05
Pattern_7EFE:
	INSTR_WAVE Wave_7EEE, $20
	CH3_FADEOUT_ON
	db L8, As5, L16, Cs5, L8, F5, As5, A5, Cs5, F5, A5, L16, Cs5, L8, Gs5, L16
	db Cs5, L8, F5, Gs5, G5, Cs5, F5, G5, L16, Cs5, L8, Fs5, L16, As4, L8, Cs5
	db Fs5, Gs5, C5, Ds5, Gs5, L16, C5, L8, Gs5, L16, Cs5, L8, F5, Gs5, Gs5, L16
	db Cs5, F5, L8, Gs5, L16, Cs5, F5, Gs5, L8, Fs5, L16, B4, L8, Ds5, Fs5, Ds5
	db Fs4, B4, Ds5, L16, E5, L8, F5, L16, As4, L8, Cs5, F5, As5, L16, Cs5, F5
	db L8, As5, L16, A5, As5, B5, L8, C6, L16, E5, L8, G5, C6, As5, E5, G5
	db As5, L16, G5, L8, A5, L8D, A5, L16, A5, A5, L4, A5, L8, A5, L16, A5
	db L8, A5, PAT_END
Pattern_7F76:
	REPEAT $07
	db L16, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, NOISE_15, DRUM, NOISE_15, NOISE_15, NOISE_15, NOISE_1A, NOISE_15, NOISE_15, NOISE_15, NOISE_1A
	db DRUM
	REPEAT_END
	db L8, DRUM, L8D, DRUM, L16, DRUM, DRUM, L4, DRUM, L8, DRUM, L16, DRUM, L8, DRUM, PAT_END
	ds 102, 0	; $7F9A-$7FFF unused
