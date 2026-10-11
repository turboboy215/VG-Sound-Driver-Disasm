; Super Mario Bros. Deluxe music: songs, bank $1D $5000-$7FFF

Pattern_5000:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
Pattern_500A:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
Song71_Header:
	SONG $00, LengthTable_4D08, Song71_Ch1, Song71_Ch2, Song71_Ch3, 0
Song71_Ch2:
	dw Pattern_5031
	dw Pattern_5040
	LIST_END
Song71_Ch1:
	dw Pattern_5036
	dw Pattern_505B
	LIST_END
Song71_Ch3:
	dw Pattern_503B
	dw Pattern_5079
	LIST_END
Pattern_5031:
	INSTR $67, $00, $80
	db PAT_END
Pattern_5036:
	INSTR $67, $00, $80
	db PAT_END
Pattern_503B:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5040:
	db L8, E4, D5, REST, D5, D5, REST, L8, F4, Ds5, REST, Ds5, Ds5, REST, L8, Fs4
	db E5, REST, E5, E5, REST, L8, F5, REST, L1, F5, PAT_END
Pattern_505B:
	db L8, E3, L4, Gs4, L8, Gs4, L4, Gs4, L8, F3, L4, A4, L8, A4, L4, A4
	db L8, Fs3, L4, As4, L8, As4, L4, As4, L8, B4, REST, L1, B4, PAT_END
Pattern_5079:
	db L8, B4, B5, REST, B5, B5, REST, L8, C5, C6, REST, C6, C6, REST, L8, Cs5
	db Cs6, REST, Cs6, Cs6, REST, L8, G4, REST, L1, G4, PAT_END
Song72_Header:
	SONG $00, LengthTable_4D62, Song72_Ch1, Song72_Ch2, Song72_Ch3, Song72_Ch4
Song72_Ch2:
	dw Pattern_50C5
	dw Pattern_50DA
Song72_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song72_Ch2_Loop
Song72_Ch1:
	dw Pattern_50CC
	dw Pattern_50EB
Song72_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song72_Ch1_Loop
Song72_Ch3:
	dw Pattern_50D3
	dw Pattern_50FF
Song72_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song72_Ch3_Loop
Song72_Ch4:
	dw Pattern_5112
Song72_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song72_Ch4_Loop
Pattern_50C5:
	INSTR_ENV Envelope_5C7E, $80
	db LEN12, REST, PAT_END
Pattern_50CC:
	INSTR_ENV Envelope_5C7E, $80
	db LEN12, REST, PAT_END
Pattern_50D3:
	INSTR_WAVE Wave_557F, $21
	db LEN12, REST, PAT_END
Pattern_50DA:
	db L8, E5, E5, REST, E5, REST, C5, E5, REST, L8, G5, REST, L4, REST, REST, REST
	db PAT_END
Pattern_50EB:
	db L8, Fs4, Fs4, REST, Fs4, REST, Fs4, Fs4, REST, L8, B4, REST, L4, REST, L8, G4
	db REST, REST, REST, PAT_END
Pattern_50FF:
	db L8, D4, D4, REST, D4, REST, D4, D4, REST, L8, G5, REST, REST, REST, G4, REST
	db REST, REST, PAT_END
Pattern_5112:
	db L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L4D, NOISE_1A, L4, NOISE_1A, L8, NOISE_29
	db NOISE_29, NOISE_29, PAT_END
; song $62; 33 unreachable table entries ($01, $02, $03, $04, ...)
Song62_Header:
	SONG $00, LengthTable_4D62, Song62_Ch1, Song62_Ch2, Song62_Ch3, Song62_Ch4
Song62_Ch2:
	dw Pattern_51B6
; Music_ResumeLevelSong indexes the lists of song $62 from here (ch2 entry 2;
; ch1, ch3, ch4 at +$22, +$44, +$64)
Song62_ResumeLists:
	dw Pattern_51CF
Song62_Ch2_Loop:
	dw Pattern_51E0
	dw Pattern_51E0
	dw Pattern_5213
	dw Pattern_5213
	dw Pattern_525A
	dw Pattern_51CF
	dw Pattern_51E0
	dw Pattern_51E0
	dw Pattern_528A
	dw Pattern_528A
	dw Pattern_525A
	dw Pattern_51CF
	dw Pattern_528A
	LIST_LOOP Song62_Ch2_Loop
Song62_Ch1:
	dw Pattern_51BF
	dw Pattern_52FA
Song62_Ch1_Loop:
	dw Pattern_530E
	dw Pattern_530E
	dw Pattern_5341
	dw Pattern_5341
	dw Pattern_5388
	dw Pattern_52FA
	dw Pattern_530E
	dw Pattern_530E
	dw Pattern_53B8
	dw Pattern_53B8
	dw Pattern_5388
	dw Pattern_52FA
	dw Pattern_53B8
	LIST_LOOP Song62_Ch1_Loop
Song62_Ch3:
	dw Pattern_51C8
	dw Pattern_542A
Song62_Ch3_Loop:
	dw Pattern_543D
	dw Pattern_543D
	dw Pattern_5462
	dw Pattern_5462
	dw Pattern_54AB
	dw Pattern_542A
	dw Pattern_543D
	dw Pattern_543D
	dw Pattern_54E2
	dw Pattern_54E2
	dw Pattern_54AB
	dw Pattern_542A
	dw Pattern_54E2
	LIST_LOOP Song62_Ch3_Loop
Song62_Ch4:
	dw Pattern_552B
Song62_Ch4_Loop:
	dw Pattern_553E
	dw Pattern_553E
	dw Pattern_554E
	dw Pattern_554E
	dw Pattern_555E
	dw Pattern_552B
	dw Pattern_553E
	dw Pattern_553E
	dw Pattern_5574
	dw Pattern_5574
	dw Pattern_555E
	dw Pattern_552B
	dw Pattern_5574
	LIST_LOOP Song62_Ch4_Loop
Pattern_51B6:
	INSTR_ENV Envelope_5C7E, $80
	REST_ENV $00
	db LEN12, REST, PAT_END
Pattern_51BF:
	INSTR_ENV Envelope_5C7E, $80
	REST_ENV $00
	db LEN12, REST, PAT_END
Pattern_51C8:
	INSTR_WAVE Wave_557F, $21
	db LEN12, REST, PAT_END
Pattern_51CF:
	db L8, E5, E5, REST, E5, REST, C5, E5, REST, L8, G5, REST, L4, REST, REST, REST
	db PAT_END
Pattern_51E0:
	db L8, C5, REST, REST, G4, REST, REST, E4, REST, L8, REST, A4, REST, B4, REST, As4
	db A4, REST, L8, G4, L32, REST, LEN13, REST, L8, E5, L32, REST, LEN13, REST, L8, G5
	db L32, REST, LEN13, REST, L8, A5, REST, F5, G5, L8, REST, E5, REST, C5, D5, B4
	db REST, REST, PAT_END
Pattern_5213:
	db L8, REST, REST, G5, Fs5, F5, Ds5, REST, E5, L8, REST, Gs4, A4, C5, REST, A4
	db C5, D5, L8, REST, REST, G5, Fs5, F5, Ds5, REST, E5, L8, REST, C6, REST, C6
	db C6, REST, REST, REST, L8, REST, REST, G5, Fs5, F5, Ds5, REST, E5, L8, REST, Gs4
	db A4, C5, REST, A4, C5, D5, L8, REST, REST, Ds5, REST, REST, D5, REST, REST, L8
	db C5, REST, L4, REST, REST, REST, PAT_END
Pattern_525A:
	db L8, C5, C5, REST, C5, REST, C5, D5, REST, L8, E5, C5, REST, A4, G4, REST
	db REST, REST, L8, C5, C5, REST, C5, REST, C5, D5, E5, L1, REST, L8, C5, C5
	db REST, C5, REST, C5, D5, REST, L8, E5, C5, REST, A4, G4, REST, REST, REST, PAT_END
Pattern_528A:
	db L8, E5, C5, REST, G4, REST, REST, Gs4, REST, L8, A4, F5, REST, F5, A4, REST
	db REST, REST, L8, B4, L32, REST, LEN13, REST, L8, A5, L32, REST, LEN13, REST, L8, A5
	db L32, REST, LEN13, REST, L8, A5, L32, REST, LEN13, REST, L8, G5, L32, REST, LEN13, REST
	db L8, F5, L32, REST, LEN13, REST, L8, E5, C5, REST, A4, G4, REST, REST, REST, L8
	db E5, C5, REST, G4, REST, REST, Gs4, REST, L8, A4, F5, REST, F5, A4, REST, REST
	db REST, L8, B4, F5, REST, F5, L8, F5, L32, REST, LEN13, REST, L8, E5, L32, REST
	db LEN13, REST, L8, D5, L32, REST, LEN13, REST, L8, C5, REST, L4, REST, REST, REST, PAT_END
Pattern_52FA:
	db L8, Fs4, Fs4, REST, Fs4, REST, Fs4, Fs4, REST, L8, B4, REST, L4, REST, L8, G4
	db REST, REST, REST, PAT_END
Pattern_530E:
	db L8, E4, REST, REST, C4, REST, REST, G3, REST, L8, REST, C4, REST, D4, REST, Cs4
	db C4, REST, L8, C4, L32, REST, LEN13, REST, L8, G4, L32, REST, LEN13, REST, L8, B4
	db L32, REST, LEN13, REST, L8, C5, REST, A4, B4, L8, REST, A4, REST, E4, F4, D4
	db REST, REST, PAT_END
Pattern_5341:
	db L8, REST, REST, E5, Ds5, D5, B4, REST, C5, L8, REST, E4, F4, G4, REST, C4
	db E4, F4, L8, REST, REST, E5, Ds5, D5, B4, REST, C5, L8, REST, F5, REST, F5
	db F5, REST, REST, REST, L8, REST, REST, E5, Ds5, D5, B4, REST, C5, L8, REST, E4
	db F4, G4, REST, C4, E4, F4, L8, REST, REST, Gs4, REST, REST, F4, REST, REST, L8
	db E4, REST, L4, REST, REST, REST, PAT_END
Pattern_5388:
	db L8, Gs4, Gs4, REST, Gs4, REST, Gs4, As4, REST, L8, G4, E4, REST, E4, C4, REST
	db REST, REST, L8, Gs4, Gs4, REST, Gs4, REST, Gs4, As4, G4, L1, REST, L8, Gs4, Gs4
	db REST, Gs4, REST, Gs4, As4, REST, L8, C5, G4, REST, E4, C4, REST, REST, REST, PAT_END
Pattern_53B8:
	db L8, C5, A4, REST, E4, REST, REST, E4, REST, L8, F4, C5, REST, C5, F4, REST
	db REST, REST, L8, G4, L32, REST, LEN13, REST, L8, F5, L32, REST, LEN13, REST, L8, F5
	db L32, REST, LEN13, REST, L8, F5, L32, REST, LEN13, REST, L8, E5, L32, REST, LEN13, REST
	db L8, D5, L32, REST, LEN13, REST, L8, C5, A4, REST, F4, E4, REST, REST, REST, L8
	db C5, A4, REST, E4, REST, REST, E4, REST, L8, F4, C5, REST, C5, F4, REST, REST
	db REST, L8, G4, D5, REST, D5, L8, D5, L32, REST, LEN13, REST, L8, C5, L32, REST
	db LEN13, REST, L8, B4, L32, REST, LEN13, REST, L8, G4, E4, REST, E4, C4, REST, REST
	db REST, PAT_END
Pattern_542A:
	db L8, D4, D4, REST, D4, REST, D4, D4, REST, L8, G5, REST, REST, REST, G4, REST
	db REST, REST, PAT_END
Pattern_543D:
	db L8, G4, REST, REST, E4, REST, REST, C4, REST, L8, REST, F4, REST, G4, REST, Fs4
	db F4, REST, LEN11, E4, C5, E5, L8, F5, REST, D5, E5, L8, REST, C5, REST, A4
	db B4, G4, REST, REST, PAT_END
Pattern_5462:
	db L8, C4, REST, REST, G4, REST, REST, C5, REST, L8, F4, REST, REST, C5, C5, REST
	db F4, REST, L8, C4, REST, REST, E4, REST, REST, G4, C5, L8, REST, G6, REST, G6
	db G6, REST, G4, REST, L8, C4, REST, REST, G4, REST, REST, C5, REST, L8, F4, REST
	db REST, C5, C5, REST, F4, REST, L8, C4, REST, Gs4, REST, REST, As4, REST, REST, L8
	db C5, REST, REST, G4, G4, REST, C4, REST, PAT_END
Pattern_54AB:
	db L8, Gs3, REST, REST, Ds4, REST, REST, Gs4, REST, L8, G4, REST, REST, C4, REST, REST
	db G3, REST, L8, Gs3, REST, REST, Ds4, REST, REST, Gs4, REST, L8, G4, REST, REST, C4
	db REST, REST, G3, REST, L8, Gs3, REST, REST, Ds4, REST, REST, Gs4, REST, L8, G4, REST
	db REST, C4, REST, REST, G3, REST, PAT_END
Pattern_54E2:
	db L8, C4, REST, REST, Fs4, G4, REST, C5, REST, L8, F4, REST, F4, REST, C5, C5
	db F4, REST, L8, D4, REST, REST, F4, G4, REST, B4, REST, L8, G4, REST, G4, REST
	db C5, C5, G4, REST, L8, C4, REST, REST, Fs4, G4, REST, C5, REST, L8, F4, REST
	db F4, REST, C5, C5, F4, REST, L8, G4, REST, REST, G4, LEN11, G4, A4, B4, L8
	db C5, REST, G4, REST, C4, REST, REST, REST, PAT_END
Pattern_552B:
	db L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L4D, NOISE_1A, L4, NOISE_1A, L8, NOISE_29
	db NOISE_29, NOISE_29, PAT_END
Pattern_553E:
	REPEAT $04
	db L4, NOISE_2E, LEN11, NOISE_29, LEN10, NOISE_29, L4, NOISE_1A, LEN11, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_554E:
	REPEAT $08
	db L4, NOISE_2E, LEN11, NOISE_29, LEN10, NOISE_29, L4, NOISE_1A, LEN11, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_555E:
	REPEAT $03
	db L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L8, NOISE_29, L4, NOISE_1A, L4D, NOISE_1A, L4, NOISE_1A, L8, NOISE_29
	db NOISE_29, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_5574:
	REPEAT $08
	db L4D, NOISE_29, L8, NOISE_29, L4, NOISE_1A, NOISE_29
	REPEAT_END
	db PAT_END
Wave_557F:
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
Song63_Header:
	SONG $00, LengthTable_4D62, Song63_Ch1, Song63_Ch2, Song63_Ch3, 0
UnusedList_559A:
	dw Pattern_55B4
	LIST_LOOP Song63_Ch2_Loop
Song63_Ch2:
	dw Pattern_55B7
Song63_Ch2_Loop:
	dw Pattern_55C3
	dw Pattern_55FA
	LIST_LOOP Song63_Ch3_Loop
Song63_Ch3:
	dw Pattern_55BE
Song63_Ch3_Loop:
	dw Pattern_55C3
	dw Pattern_5629
	LIST_LOOP Song63_Ch3_Loop
Pattern_55B4:
	db $9d, $83, $00	; INSTR (operands continue into the next pattern)
Pattern_55B7:
	INSTR_ENV Envelope_5CAE, $80
	REST_ENV $00
	db PAT_END
Pattern_55BE:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_55C3:
	db L8, C4, C5, A3, A4, As3, As4, L2D, REST, L8, C4, C5, A3, A4, As3, As4
	db L2D, REST, L8, F3, F4, D3, D4, Ds3, Ds4, L2D, REST, L8, F3, F4, D3, D4
	db Ds3, Ds4, L2, REST, LEN10, Ds4, D4, Cs4, L8, C4, REST, Ds4, REST, D4, REST, Gs3
	db REST, L8, G3, REST, Cs4, REST, PAT_END
Pattern_55FA:
	db LEN10, C4, Fs4, F4, E4, As4, A4, L8, Gs4, L32, REST, LEN13, REST, L8, Ds4, L32
	db REST, LEN13, REST, L8, B3, L32, REST, LEN13, REST, L8, As3, L32, REST, LEN13, REST, L8
	db A3, L32, REST, LEN13, REST, L8, Gs3, L32, REST, LEN13, REST, L2D, REST, REST, PAT_END
Pattern_5629:
	db LEN10, C4, Fs4, F4, E4, As4, A4, LEN11, Gs4, Ds4, B3, LEN11, As3, A3, Gs3, L2D
	db REST, REST, PAT_END
Song64_Header:
	SONG $00, LengthTable_4D17, Song64_Ch1, Song64_Ch2, Song64_Ch3, 0
Song64_Ch1:
	dw Pattern_5665
	dw Pattern_5674
Song64_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song64_Ch1_Loop
Song64_Ch2:
	dw Pattern_566A
	dw Pattern_5695
Song64_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song64_Ch2_Loop
Song64_Ch3:
	dw Pattern_566F
	dw Pattern_56B9
Song64_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song64_Ch3_Loop
Pattern_5665:
	INSTR $77, $00, $80
	db PAT_END
Pattern_566A:
	INSTR $77, $00, $80
	db PAT_END
Pattern_566F:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5674:
	db L8, REST, E3, G3, C4, E4, G4, L4D, C5, G4, L8, REST, Ds3, Gs3, C4, Ds4
	db Gs4, L4D, C5, Gs4, L8, REST, F3, As3, D4, F4, As4, L4D, D5, D5, L2, C6
	db PAT_END
Pattern_5695:
	db L8, G3, C4, E4, G4, C5, E5, L4D, G5, E5, L8, Gs3, C4, Ds4, Gs4, C5
	db Ds5, L4D, Gs5, Ds5, L8, As3, D4, F4, As4, D5, F5, L4D, As5, L8, As5, As5
	db As5, L2, E5, PAT_END
Pattern_56B9:
	db L8, REST, REST, REST, C4, E4, G4, L4D, E5, L8D, C5, REST, L8D, REST, REST, L8
	db C4, Ds4, Gs4, L4D, Ds5, L8D, C5, REST, L8, REST, REST, REST, D4, F4, As4, L4D
	db F5, L8, D5, D5, D5, L2, C5, PAT_END
Song65_Header:
	SONG $00, LengthTable_4D08, Song65_Ch1, Song65_Ch2, Song65_Ch3, Song65_Ch4
Song65_Ch2:
	dw Pattern_570A
Song65_Ch2_Loop:
	dw Pattern_5719
	LIST_LOOP Song65_Ch2_Loop
Song65_Ch1:
	dw Pattern_570F
Song65_Ch1_Loop:
	dw Pattern_5734
	LIST_LOOP Song65_Ch1_Loop
Song65_Ch3:
	dw Pattern_5714
Song65_Ch3_Loop:
	dw Pattern_5753
	LIST_LOOP Song65_Ch3_Loop
Song65_Ch4:
	dw Pattern_5780
	LIST_LOOP Song65_Ch4
Pattern_570A:
	INSTR $72, $00, $80
	db PAT_END
Pattern_570F:
	INSTR $72, $00, $80
	db PAT_END
Pattern_5714:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5719:
	db L4, C5, C5, C5, L8, REST, C5, REST, L4D, C5, L4, C5, C5, L4, B4, B4
	db B4, L8, REST, B4, REST, L4D, B4, L4, B4, B4, PAT_END
Pattern_5734:
	db L4, F4, F4, F4, L8, D4, L4, F4, F4, L8, D4, F4, D4, L4, F4, L4
	db E4, E4, E4, L8, C4, L4, E4, E4, L8, C4, E4, C4, L4, E4, PAT_END
Pattern_5753:
	db L4, D4, REST, L8D, A4, L1D, REST, LEN12, REST, L8D, D5, L1D, REST, LEN12, REST, L8
	db REST, REST, A4, REST, D5, REST, L4, C4, REST, L8D, G4, L1D, REST, LEN12, REST, L8D
	db C5, L1D, REST, LEN12, REST, L8, REST, REST, G4, REST, C5, REST, PAT_END
Pattern_5780:
	db L4, NOISE_2E, LEN11, NOISE_29, LEN10, NOISE_29, L4, NOISE_1A, LEN11, NOISE_29, LEN10, NOISE_29, PAT_END
Song6C_Header:
	SONG $18, LengthTable_4D17, Song6C_Ch1, Song6C_Ch2, Song6C_Ch3, Song6C_Ch4
Song6C_Ch2:
	dw Pattern_57B6
Song6C_Ch2_Loop:
	dw Pattern_5801
	LIST_LOOP Song6C_Ch2_Loop
Song6C_Ch1:
	dw Pattern_57BD
Song6C_Ch1_Loop:
	dw Pattern_5870
	LIST_LOOP Song6C_Ch1_Loop
Song6C_Ch3:
	dw Pattern_57C4
Song6C_Ch3_Loop:
	dw Pattern_58C5
	LIST_LOOP Song6C_Ch3_Loop
Song6C_Ch4:
	dw Pattern_593E
	LIST_LOOP Song6C_Ch4
Pattern_57B6:
	INSTR_ENV Envelope_5EC4, $80
	REST_ENV $27
	db PAT_END
Pattern_57BD:
	INSTR_ENV Envelope_5EC4, $80
	REST_ENV $27
	db PAT_END
Pattern_57C4:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Song66_Header:
	SONG $00, LengthTable_4D17, Song66_Ch1, Song66_Ch2, Song66_Ch3, Song66_Ch4
Song66_Ch2:
	dw Pattern_57F2
Song66_Ch2_Loop:
	dw Pattern_5801
	LIST_LOOP Song66_Ch2_Loop
Song66_Ch1:
	dw Pattern_57F7
Song66_Ch1_Loop:
	dw Pattern_5870
	LIST_LOOP Song66_Ch1_Loop
Song66_Ch3:
	dw Pattern_57FC
Song66_Ch3_Loop:
	dw Pattern_58C5
	LIST_LOOP Song66_Ch3_Loop
Song66_Ch4:
	dw Pattern_593E
	LIST_LOOP Song66_Ch4
Pattern_57F2:
	INSTR_ENV Envelope_5CDE, $80
	db PAT_END
Pattern_57F7:
	INSTR_ENV Envelope_5CDE, $80
	db PAT_END
Pattern_57FC:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5801:
	db L4, D4, E4, Fs4, L4, G4, A4, As4, L8, B4, B4, B4, REST, B4, REST, L2
	db B4, L4, G4, L2D, E5, L2D, Ds5, L2D, E5, L8, REST, G4, A4, B4, C5, D5
	db L2D, E5, L2, Ds5, L4, F5, L1, E5, L4D, REST, L8, G4, L2D, D5, L2D, Cs5
	db L2D, D5, L8, REST, G4, A4, B4, C5, Cs5, L2D, D5, L2, G4, L4, F5, L1
	db E5, L4D, REST, L8, G4, L2D, G5, L2D, G5, L2D, G5, L4, G5, L8, A5, REST
	db REST, G5, L2D, F5, L2D, F5, L2D, F5, L4, F5, L8, G5, REST, REST, F5, L2D
	db E5, L4, A4, B4, F5, L8, E5, E5, L4D, E5, L8, B4, L2D, C5, PAT_END
Pattern_5870:
	db L4, REST, Cs4, C4, L4, B3, C4, Cs4, L8, D4, D4, D4, REST, E4, REST, L2D
	db F4, L2D, G4, L2D, Fs4, L2D, G4, L2D, REST, L2D, G4, L2, Fs4, L4, A4, L1
	db G4, L2, REST, L2D, F4, L2D, E4, L2D, F4, L2D, REST, L2D, F4, L2, B3, L4
	db A4, L1, G4, L2, REST, L2D, E5, L2D, D5, L2D, Cs5, L2D, REST, L2D, D5, L2D
	db Cs5, L2D, C5, L2D, REST, L2D, C5, L4, F4, G4, B4, L8, B4, B4, L4D, B4
	db L8, F4, L2D, E4, PAT_END
Pattern_58C5:
	db L1, REST, REST, L4, G4, L2D, G4, L4, C4, G4, C5, L4, B3, G4, B4, L4
	db C4, G4, C5, L4, E4, G4, C5, L4, C4, G4, C5, L4, B3, G4, B4, L4
	db C4, G4, C5, L4, E4, G4, C5, L4, D4, G4, B4, L4, Cs4, Fs4, As4, L4
	db D4, G4, B4, L4, B3, G4, B4, L4, D4, G4, B4, L4, B3, G4, B4, L4
	db C4, G4, C5, L4, G3, G4, C5, L4, C4, G4, E5, L4, B3, G4, D5, L4
	db As3, G4, Cs5, L4, Cs4, G4, E5, L4, D4, A4, F5, L4, Cs4, A4, F5, L4
	db C4, A4, F5, L4, B3, G4, F5, L4, C4, G4, E5, L4, G3, G4, G4, L8
	db F4, F4, L4D, F4, L8, B3, L2D, C4, PAT_END
Pattern_593E:
	db L4, REST, NOISE_29, NOISE_1A, L4, REST, L8, NOISE_29, NOISE_29, L4, NOISE_1A, PAT_END
Song67_Header:
	SONG $00, LengthTable_4D17, Song67_Ch1, Song67_Ch2, Song67_Ch3, 0
Song67_Ch2:
	dw Pattern_597B
	dw Pattern_598A
Song67_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song67_Ch2_Loop
Song67_Ch1:
	dw Pattern_5980
	dw Pattern_59A1
Song67_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song67_Ch1_Loop
Song67_Ch3:
	dw Pattern_5985
	dw Pattern_59BA
Song67_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song67_Ch3_Loop
UnusedList_5973:
	dw Pattern_59D5
Song67_Ch3_Loop2:
	dw Pattern_5000
	LIST_LOOP Song67_Ch3_Loop2
Pattern_597B:
	INSTR $92, $00, $80
	db PAT_END
Pattern_5980:
	INSTR $a2, $00, $80
	db PAT_END
Pattern_5985:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_598A:
	db L8, B4, F5, REST, F5, L8, F5, LEN11, REST, L8, E5, LEN11, REST, L8, D5, L32
	db REST, L8, C5, REST, L2D, REST, PAT_END
Pattern_59A1:
	DROP_ON
	db L8, G4, D5, REST, D5, L8, D5, LEN11, REST, L8, C5, LEN11, REST, L8, B4, L32
	db REST, L8, G4, E4, REST, E4, C4, PAT_END
Pattern_59BA:
	db L8, G4, REST, REST, G4, L8, G4, LEN11, REST, L8, A4, LEN11, REST, L8, B4, L32
	db REST, L8, C5, REST, G4, REST, C4, REST, REST, REST, PAT_END
Pattern_59D5:
	db L4D, $29, L8, $29, L4, C3, $29, PAT_END
Song68_Header:
	SONG $00, LengthTable_4D26, Song68_Ch1, Song68_Ch2, Song68_Ch3, 0
Song68_Ch2:
	dw Pattern_5A00
Song68_Ch2_Loop:
	dw Pattern_5A11
	LIST_LOOP Song68_Ch2_Loop
Song68_Ch1:
	dw Pattern_5A05
Song68_Ch1_Loop:
	dw Pattern_5A7E
	LIST_LOOP Song68_Ch1_Loop
Song68_Ch3:
	dw Pattern_5A0C
Song68_Ch3_Loop:
	dw Pattern_5AB5
	LIST_LOOP Song68_Ch3_Loop
Pattern_5A00:
	INSTR $71, $00, $80
	db PAT_END
Pattern_5A05:
	INSTR $71, $00, $80
	db L16, REST, PAT_END
Pattern_5A0C:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5A11:
	db L16, G4, As4, G4, A4, G4, Gs4, G4, A4, L16, G4, As4, G4, B4, G4, As4
	db G4, A4, L16, G4, As4, G4, A4, G4, Gs4, G4, A4, L16, G4, As4, G4, B4
	db G4, As4, G4, A4, L16, Fs4, A4, Fs4, Gs4, Fs4, A4, Fs4, As4, L16, Fs4, A4
	db Fs4, As4, Fs4, A4, Fs4, Gs4, L16, Fs4, A4, Fs4, Gs4, Fs4, A4, Fs4, As4, L16
	db Fs4, A4, Fs4, As4, Fs4, A4, Fs4, Gs4, L16, As4, D5, As4, Ds5, As4, D5, As4
	db Cs5, L16, As4, D5, As4, Cs5, As4, C5, As4, Cs5, L16, As4, D5, As4, Ds5, As4
	db D5, As4, Cs5, L16, As4, D5, As4, Cs5, As4, C5, As4, Cs5, PAT_END
Pattern_5A7E:
	db L8, D5, Cs5, C5, Cs5, D5, Ds5, D5, Cs5, L8, D5, Cs5, C5, Cs5, D5, Ds5
	db D5, Cs5, L8, Cs5, C5, Cs5, D5, Cs5, D5, Cs5, C5, L8, Cs5, C5, Cs5, D5
	db Cs5, D5, Cs5, C5, L8, F5, Fs5, F5, E5, F5, E5, Ds5, E5, L8, F5, Fs5
	db F5, E5, F5, E5, Ds5, E5, PAT_END
Pattern_5AB5:
	db L1, Ds4, L2, D4, Fs4, L1, F4, L2, E4, As4, L2, A4, E4, L2, Ds4, E4
	db PAT_END
Song69_Header:
	SONG $00, LengthTable_4D26, Song69_Ch1, Song69_Ch2, Song69_Ch3, 0
Song69_Ch2:
	dw Pattern_5AEF
	dw Pattern_5AFE
Song69_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song69_Ch2_Loop
Song69_Ch1:
	dw Pattern_5AF4
	dw Pattern_5B13
Song69_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song69_Ch1_Loop
Song69_Ch3:
	dw Pattern_5AF9
	dw Pattern_5B25
Song69_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song69_Ch3_Loop
Pattern_5AEF:
	INSTR_ENV Envelope_5CDE, $80
	db PAT_END
Pattern_5AF4:
	INSTR_ENV Envelope_5CDE, $80
	db PAT_END
Pattern_5AF9:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5AFE:
	db L8, C5, REST, REST, G4, REST, REST, L4, E4, LEN11, A4, B4, LEN12, A4, L4, Gs4
	db As4, Gs4, L2D, G4, PAT_END
Pattern_5B13:
	db L8, E4, REST, REST, C4, L4, REST, G3, L2, F4, L2D, F4, L8, E4, D4, L2
	db E4, PAT_END
Pattern_5B25:
	db L8, G4, REST, REST, E4, REST, REST, L4, C4, L2, F4, L2D, Cs4, L2D, C4, PAT_END
Song6A_Header:
	SONG $00, LengthTable_4D35, Song6A_Ch1, Song6A_Ch2, Song6A_Ch3, 0
Song6A_Ch2:
	dw Pattern_5B5E
	dw Pattern_5B6D
Song6A_Ch2_Loop:
	dw Pattern_5B72
	LIST_LOOP Song6A_Ch2_Loop
Song6A_Ch1:
	dw Pattern_5B63
	dw Pattern_5B8D
Song6A_Ch1_Loop:
	dw Pattern_5B90
	LIST_LOOP Song6A_Ch1_Loop
Song6A_Ch3:
	dw Pattern_5B68
	dw Pattern_5BA8
Song6A_Ch3_Loop:
	dw Pattern_5BAB
	LIST_LOOP Song6A_Ch3_Loop
Pattern_5B5E:
	INSTR $77, $00, $80
	db PAT_END
Pattern_5B63:
	INSTR $77, $00, $80
	db PAT_END
Pattern_5B68:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5B6D:
	db LEN10, G4, Fs4, G4, PAT_END
Pattern_5B72:
	db L2, E4, L4, F4, Fs4, L2, G4, L4, C5, LEN11, E5, LEN10, E5, L4, D5, E5
	db F5, B4, L2, D5, L4, C5, LEN10, G4, Fs4, G4, PAT_END
Pattern_5B8D:
	db L4, REST, PAT_END
Pattern_5B90:
	db L2, G3, L4, A3, As3, L2, B3, L4, E4, LEN11, G4, LEN10, G4, L4, F4, G4
	db A4, D4, L2, F4, L4, E4, REST, PAT_END
Pattern_5BA8:
	db L4, B3, PAT_END
Pattern_5BAB:
	db L2, C4, L4, D4, Ds4, L4, E4, C4, A4, G4, L4, F4, E4, D4, F4, L4
	db G4, G3, C4, B3, PAT_END
Song6B_Header:
	SONG $00, LengthTable_4D17, Song6B_Ch1, Song6B_Ch2, Song6B_Ch3, 0
Song6B_Ch2:
	dw Pattern_5BE9
	dw Pattern_5BF8
Song6B_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song6B_Ch2_Loop
Song6B_Ch1:
	dw Pattern_5BEE
	dw Pattern_5C1A
Song6B_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song6B_Ch1_Loop
Song6B_Ch3:
	dw Pattern_5BF3
	dw Pattern_5C51
Song6B_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song6B_Ch3_Loop
Pattern_5BE9:
	INSTR_ENV Envelope_5D0E, $80
	db PAT_END
Pattern_5BEE:
	INSTR_ENV Envelope_5D0E, $80
	db PAT_END
Pattern_5BF3:
	INSTR_WAVE Wave_557F, $21
	db PAT_END
Pattern_5BF8:
	db L8, C5, G4, E4, C5, G4, E4, L2D, C5, L8, Cs5, Gs4, F4, Cs5, Gs4, F4
	db L2D, Cs5, L8, Ds5, As4, G4, Ds5, As4, G4, L4D, Ds5, L8D, F5, F5, F5, L1
	db G5, PAT_END
Pattern_5C1A:
	db L8, E4, C4, G3, E4, C4, G3, L8, E4, L16, E4, E4, L8, E4, E4, E4
	db E4, L8, F4, Cs4, Gs3, F4, Cs4, Gs3, L8, F4, L16, F4, F4, L8, F4, F4
	db F4, F4, L8, G4, Ds4, As3, G4, Ds4, As3, L8, G4, L16, G4, G4, L8, G4
	db L8D, A4, A4, A4, L1, B4, PAT_END
Pattern_5C51:
	db L2D, C4, L8, C4, L16, C4, C4, L8, C4, C4, C4, C4, L2D, Cs4, L8, Cs4
	db L16, Cs4, Cs4, L8, Cs4, Cs4, Cs4, Cs4, L8, As4, G4, Ds4, As4, G4, Ds4, L8
	db As4, L16, As4, As4, L8, As4, L8D, C5, C5, C5, L1, D5, PAT_END
Envelope_5C7E:
	db $72, $00, $00, $00, $00, $00, $00, $22, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_5CAE:
	db $72, $00, $00, $00, $00, $00, $00, $25, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_5CDE:
	db $5f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $66, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $18
Envelope_5D0E:
	db $c1, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
; unreferenced song header: no length table, three silent channels
Unused_SongHeader:
	SONG $00, $0000, Song63_Ch1, Song63_Ch1, Song63_Ch1, 0
Song6D_Header:
	SONG $00, LengthTable_6690, Song6D_Ch1, Song6D_Ch2, Song6D_Ch3, Song6D_Ch4
Song6D_Ch1:
	dw Pattern_5D90
	dw Pattern_5D97
	dw Pattern_5D97
	dw Pattern_5DA8
	dw Pattern_5D97
	dw Pattern_5DB9
	dw Pattern_5DC5
	LIST_LOOP Song6D_Ch1
Song6D_Ch2:
	dw Pattern_5DCD
	dw Pattern_5DD4
	dw Pattern_5DD4
	dw Pattern_5DE9
	dw Pattern_5DD4
	dw Pattern_5DFE
	dw Pattern_5E20
	LIST_LOOP Song6D_Ch2
Song6D_Ch3:
	dw Pattern_5E3A
Song6D_Ch3_Loop:
	dw Pattern_5E3F
	dw Pattern_5E3F
	dw Pattern_5E59
	dw Pattern_5E3F
	dw Pattern_5E73
	dw Pattern_5E90
	LIST_LOOP Song6D_Ch3_Loop
Song6D_Ch4:
	dw Pattern_5EAA
	LIST_LOOP Song6D_Ch4
Pattern_5D90:
	INSTR $74, $00, $00
	REST_ENV $17
	db PAT_END
Pattern_5D97:
	REPEAT $03
	db LEN11, REST, REST, REST, E4, REST, REST
	REPEAT_END
	db REST, REST, E4, REST, REST, REST, PAT_END
Pattern_5DA8:
	REPEAT $03
	db LEN11, REST, REST, REST, Ds4, REST, REST
	REPEAT_END
	db REST, REST, Ds4, REST, REST, REST, PAT_END
Pattern_5DB9:
	INSTR $a1, $00, $00
	db L4, REST, F4, L2, F4, L1, REST, PAT_END
Pattern_5DC5:
	REPEAT $08
	db LEN11, G3, G3, G3
	REPEAT_END
	db PAT_END
Pattern_5DCD:
	INSTR $74, $00, $00
	REST_ENV $17
	db PAT_END
Pattern_5DD4:
	REPEAT $03
	db LEN11, REST, REST, REST, As4, REST, REST
	REPEAT_END
	db REST, REST, As4, LEN10, A4, REST, As4, REST, G4, REST, PAT_END
Pattern_5DE9:
	REPEAT $03
	db LEN11, REST, REST, REST, A4, REST, REST
	REPEAT_END
	db REST, REST, A4, LEN10, G4, REST, A4, REST, F4, REST, PAT_END
Pattern_5DFE:
	INSTR $83, $00, $00
	db LEN13, REST, LEN11, G4, LEN13, B4, LEN11, G4, LEN13, B4, L8, G4, REST, LEN11, G4, As4
	db A4, G4, F4, E4, L4, F4, LEN10, G4, F4, LEN11, E4, LEN13, REST, PAT_END
Pattern_5E20:
	db LEN11, REST, REST, C4, E4, REST, C4, F4, REST, C4, Fs4, REST, C4, G4, As4, G4
	db As4, G4, As4, G4, F4, Fs4, G4, Ds4, E4, PAT_END
Pattern_5E3A:
	INSTR_WAVE Wave_7AAD, $21
	db PAT_END
Pattern_5E3F:
	db LEN11, C4, REST, REST, REST, REST, C4, E4, REST, REST, REST, REST, E4, F4, REST, REST
	db REST, REST, Fs4, REST, REST, Fs4, G4, REST, REST, PAT_END
Pattern_5E59:
	db LEN11, F4, REST, REST, REST, REST, F4, A4, REST, REST, REST, REST, A4, As4, REST, REST
	db REST, REST, B4, REST, REST, B4, C5, REST, REST, PAT_END
Pattern_5E73:
	db LEN11, G4, REST, REST, D5, REST, REST, G4, REST, Fs4, REST, REST, F4, REST, REST, F4
	db REST, REST, C5, LEN13, F4, LEN10, G4, F4, LEN11, E4, REST, REST, PAT_END
Pattern_5E90:
	db LEN11, REST, REST, C4, E4, REST, C4, F4, REST, C4, Fs4, REST, C4, G4, As4, G4
	db As4, G4, As4, G4, F4, Fs4, G4, Ds4, E4, PAT_END
Pattern_5EAA:
	REPEAT $0b
	db L4, NOISE_2E, LEN13, NOISE_29, LEN11, NOISE_29, L4, NOISE_1A, LEN13, NOISE_29, LEN11, NOISE_29
	REPEAT_END
	REPEAT $02
	db LEN11, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A
	REPEAT_END
	db PAT_END
Envelope_5EC4:
	db $81, $00, $00, $00, $00, $00, $00, $00, $61, $00, $00, $00, $00, $00, $00, $00
	db $51, $00, $00, $00, $00, $00, $00, $00, $41, $00, $00, $00, $00, $00, $00, $00
	db $31, $00, $00, $00, $00, $00, $00, $00, $31, $00, $00, $00, $00, $00, $00, $28
Song6E_Header:
	SONG $00, LengthTable_5EFF, Song6E_Ch1, Song6E_Ch2, Song6E_Ch3, Song6E_Ch4
LengthTable_5EFF:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $6f, $04, $08, $08, $10, $6f
Song6E_Ch1:
	dw Pattern_5F2E
Song6E_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song6E_Ch1_Loop
Song6E_Ch2:
	dw Pattern_6164
Song6E_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song6E_Ch2_Loop
Song6E_Ch3:
	dw Pattern_642B
Song6E_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song6E_Ch3_Loop
Song6E_Ch4:
	dw Pattern_6644
Song6E_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song6E_Ch4_Loop
Pattern_5F2E:
	INSTR $72, $00, $83
	REPEAT $04
	db L8, C5, C5, C5, L16, D4, L8, C5, C5, L16, D4, C5, D4, L8, C5, L8
	db B4, B4, B4, L16, C4, L8, B4, B4, L16, C4, B4, C4, L8, B4
	REPEAT_END
	db L8, C5, C5, C5, L16, D4, L8, B4, B4, L16, D4, B4, D4, L8, B4, L8
	db D5, D5, D5, L16, E4, L8, C5, C5, L16, E4, C5, E4, L8, C5, L8, C5
	db C5, C5, L16, D4, L8, B4, B4, L16, D4, B4, D4, L8, B4, L8, B4, B4
	db B4, L16, C4, L8, As4, As4, L16, Cs4, As4, Cs4, L8, As4, L8, C5, C5, C5
	db L16, D4, L8, B4, B4, L16, D4, B4, D4, L8, B4, L8, D5, D5, D5, L16
	db E4, L8, C5, C5, L16, E4, C5, E4, L8, C5, L8, C5, C5, C5, L16, D4
	db L8, B4, B4, L16, D4, B4, D4, L8, B4, L8, B4, B4, B4, L16, D4, L8
	db As4, As4, L16, C4, As4, C4, L8, As4, L8, C5, C5, C5, L16, D4, L8, B4
	db B4, L16, D4, B4, D4, L8, B4, L8, B4, B4, B4, L16, C4, L8, A4, A4
	db L16, C4, A4, C4, L8, A4, L8, A4, A4, A4, L16, B3, L8, Gs4, Gs4, L16
	db B3, Gs4, B3, L8, Gs4, L8, G4, G4, G4, L16, A3, L8, G4, G4, L16, Cs4
	db G4, Cs4, L8, G4, L8, C5, C5, C5, L16, D4, L8, B4, B4, L16, D4, B4
	db D4, L8, B4, L8, D5, D5, D5, L16, E4, L8, Cs5, Cs5, L16, E4, Cs5, E4
	db L8, Cs5, L8, C5, C5, C5, L16, D4, L8, B4, B4, L16, D4, B4, D4, L8
	db B4
	REPEAT $02
	db L8, B4, B4, B4, L16, C4, L8, B4, B4, L16, C4, B4, C4, L8, B4, L8
	db As4, As4, As4, L16, C4, L8, As4, As4, L16, C4, As4, Cs4, L8, As4
	REPEAT_END
	db L8, E5, E5, E5, L16, F4, L8, E5, E5, L16, F4, E5, F4, L8, E5, L8
	db D5, D5, D5, L16, F4, L8, D5, D5, L16, F4, D5, F4, L8, D5, L8, D5
	db D5, D5, L16, E4, L8, D5, D5, L16, E4, D5, E4, L8, D5, L8, Cs5, Cs5
	db Cs5, L16, E4, L8, Cs5, Cs5, L16, E4, Cs5, E4, L8, Cs5
	REPEAT $02
	db L8, C5, C5, C5, L16, D4, L8, C5, C5, L16, D4, C5, D4, L8, C5, L8
	db B4, B4, B4, L16, D4, L8, B4, B4, L16, D4, B4, D4, L8, B4
	REPEAT_END
	REPEAT $0c
	db L8, C5, C5, C5, L16, D4, L8, C5, C5, L16, D4, C5, D4, L8, C5, L8
	db B4, B4, B4, L16, C4, L8, B4, B4, L16, C4, B4, C4, L8, B4
	REPEAT_END
	db PAT_END
Envelope_60D4:
	db $81, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $28, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_6104:
	db $c1, $00, $00, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $28
Envelope_6134:
	db $49, $00, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $38, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $28
Pattern_6164:
	INSTR $72, $00, $80
	db L8, F4, F4, L8D, F4, L8, F4, L8D, F4, L8, F4, F4, L8, E4, E4, L8D
	db E4, L8, E4, L8D, E4, L8, E4, E4, L8, F4, F4, L8D, F4, L8, F4, L8D
	db F4, L8, F4, F4, L8, E4, E4, L8D, E4, L8, E4, L8D, E4
	INSTR_ENV Envelope_60D4, $40
	REST_ENV $27
	db LEN10, E5, F5, G5, L32, A5, B5, C6, D6, LEN13, REST, LEN10, E6, E6, E6, E6
	db LEN11, E6, E6, LEN13, E6, D6, C6, L16, B5, REST, C6, B5, REST, G5, REST, L2
	db E5, L16, REST, L16, REST, B5, A5, REST, L32, B5, B5, L16, A5, REST, B5, A5
	db REST, L32, B5, B5, L16, A5, REST, B5, A5, REST, D6, REST, A5, LEN10, B5, B5
	db B5, L4, B5, L16, A5, B5, A5, LEN10, B5, A5, G5, F5, E5, D5
	INSTR_ENV Envelope_6104, $00
	db L8D, A4, B4, L8, C5, L8D, D5, E5, L8, F5, L8D, G5, E5, L8, D5, L4
	db C5, LEN11, REST, D5, E5, L8D, F5, D5, L8, C5, L8D, B4, A4, L8, B4, L2D
	db G4, L4, REST, L8D, A4, B4, L8, C5, L8D, D5, E5, L8, F5, L4, G5, L16
	db E5, REST, L8D, As5, L16, REST, A5, REST, G5, L8D, F5, L8D, E5, D5, L8, C5
	db L8D, B4, A4, L8, B4, L2, C5, L4, REST
	INSTR_ENV Envelope_6134, $80
	db LEN10, B4, C5, D5, E5, F5, G5, LEN13, A5, G5, LEN11, F5, E5, L4, D5, L8
	db E5, F5, LEN13, G5, F5, LEN11, E5, D5, L4, C5, L8, D5, E5, LEN13, F5, E5
	db LEN11, D5, C5, L8, B4, Gs4, A4, B4, L8D, C5, D5, L4, E5, L8, REST, F5
	db G5, LEN13, A5, G5, LEN11, F5, E5, L4, D5, L8, E5, F5, L8, REST, G5, L16
	db REST, E5, REST, L8, As5, L16, REST, A5, REST, G5, L16, F5, REST, L32, F5, G5
	db L8D, Gs5, G5, L8, F5, L8D, E5, Gs4, L8, A4, L1, D5, L4D, REST, L4, REST
	db L8D, G4, A4, L1, D5, L4D, REST, L4, REST, L8D, G4, A4
	INSTR_ENV Envelope_5EC4, $80
	db LEN13, REST, F5, A5, E6, D6, C6, L4D, As5, C6, L4, D6, L2, G5, LEN13, REST
	db A5, As5, L8, REST, L16, Cs6, L8, REST, L8D, As5, A5, G5, L8, F5, L8, REST
	db E5, L16, REST, E5, L8, REST, L8D, E5, D5, L8, C5, L8, REST, E5, L16, REST
	db E5, L8, REST, L8D, E5, L16, E5, L4, REST, L8, REST, E5, L16, REST, E5, L8
	db REST, L8D, E5, F5, L8, G5, L8, REST, E5, L16, REST, E5, L8, REST, L4, E5
	INSTR_ENV Envelope_60D4, $40
	db LEN10, E5, F5, G5, L32, A5, B5, C6, D6, LEN13, REST, LEN10, E6, E6, E6, E6
	db LEN11, E6, E6, LEN13, E6, D6, C6, L16, B5, REST, C6, B5, REST, G5, REST, L2
	db E5, L16, REST, L16, REST, B5, A5, REST, L32, B5, B5, L16, A5, REST, B5, A5
	db REST, L32, B5, B5, L16, A5, REST, B5, A5, REST, D6, REST, A5, LEN10, B5, B5
	db B5, L4, B5, L16, A5, B5, A5, LEN10, B5, A5, G5, F5, E5, D5
	INSTR_ENV Envelope_60D4, $40
	db L16, REST, REST, D5, E5, REST, G5, REST, D5, E5, REST, A5, REST, D5, E5, REST
	db B5, REST, D5, E5, REST, C6, REST, D5, E5, REST, D6, REST, D5, E5, REST, E6
	db REST, LEN13, E5, E6, E6, L16, E5, E6, E6, E5, E6, E6, E5, E6, L8, E6
	db L16, F6, L2, G6, L16, REST, L4, REST, L32, REST, LEN10, REST, L32, E6, G6, B6
	db LEN13, D7, D7, L8D, D7, C7, B6, L16, REST, C7, REST, B6, G6, REST, L2, E6
	db L16, REST, L32, REST, REST, E6, G6, L16, B6, L8, A6, L16, B6, L8, A6, L16
	db B6, L8, A6, L16, B6, L8, A6, L16, B6, L8, A6, L16, D6, L2, E6, L4D
	db REST
	VOLUME $66
	db L16, REST, REST, D6, E6, REST, B6, A6, REST, D6, E6, REST, B6, A6, REST, D6
	db E6
	VOLUME $55
	db REST, B6, A6, REST, D6, E6, REST, B6, A6, REST, D6, E6, REST, B6, A6, REST
	VOLUME $44
	db D6, E6, REST, B6, A6, REST, D6, E6, REST, B6, A6, REST, D6, E6, REST, B6
	VOLUME $33
	db L16, A6, REST, L8, B6, L16, REST, L8, C7, L16, REST, L8, D7, L16, REST, L8
	db E7, L16, REST, L8, F7, L16, REST, L8, G7, L16, REST, L8, A7, L16, REST, L2
	db B7, L16, REST
	VOLUME $22
	db L1, REST, REST
	VOLUME $11
	db REST, REST
	VOLUME $00
	db REST, REST, PAT_END
Pattern_642B:
	INSTR_WAVE Wave_557F, $21
	REPEAT $04
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, D5, LEN10, REST, L8D, REST, L16
	db A4, REST, D5, REST, L8, C4, REST, LEN12, G4, LEN10, REST, L16, REST, LEN12, C5, LEN10
	db REST, L8D, REST, L16, G4, REST, C5, REST
	REPEAT_END
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, G4, LEN10, REST, L8D, REST, L16
	db B4, REST, G4, REST, L8, E4, REST, LEN12, B4, LEN10, REST, L16, REST, LEN12, A4, LEN10
	db REST, L8D, REST, L16, C5, REST, A4, REST, L8, D4, REST, LEN12, A4, LEN10, REST, L16
	db REST, LEN12, G4, LEN10, REST, L8D, REST, L16, B4, REST, G4, REST, L8, C4, REST, LEN12
	db G4, LEN10, REST, L16, REST, LEN12, Cs4, LEN10, REST, L8D, REST, L16, As4, REST, Cs4, REST
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, G4, LEN10, REST, L8D, REST, L16
	db B4, REST, G4, REST, L8, E4, REST, LEN12, B4, LEN10, REST, L16, REST, LEN12, A4, LEN10
	db REST, L8D, REST, L16, C5, REST, A4, REST, L8, D4, REST, LEN12, A4, LEN10, REST, L16
	db REST, LEN12, G4, LEN10, REST, L8D, REST, L16, B4, REST, G4, REST, L8, C4, REST, LEN12
	db C5, LEN10, REST, L16, REST, LEN12, G4, LEN10, REST, L8D, REST, L16, As4, REST, C4, REST
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, G4, LEN10, REST, L8D, REST, L16
	db B4, REST, G4, REST, L8, C4, REST, LEN12, G4, LEN10, REST, L16, REST, LEN12, F4, LEN10
	db REST, L8D, REST, L16, A4, REST, F4, REST, L8, B3, REST, LEN12, F4, LEN10, REST, L16
	db REST, LEN12, E4, LEN10, REST, L8D, REST, L16, Gs4, REST, E4, REST, L8, A3, REST, LEN12
	db E4, LEN10, REST, L16, REST, LEN12, Cs4, LEN10, REST, L8D, REST, L16, A4, REST, Cs4, REST
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, G4, LEN10, REST, L8D, REST, L16
	db B4, REST, G4, REST, L8, E4, REST, LEN12, B4, LEN10, REST, L16, REST, LEN12, A4, LEN10
	db REST, L8D, REST, L16, Cs5, REST, A4, REST, L8, D4, REST, LEN12, A4, LEN10, REST, L16
	db REST, LEN12, G4, LEN10, REST, L8D, REST, L16, B4, REST, G4, REST
	REPEAT $04
	db L8, C4, REST, LEN12, G4, LEN10, REST, L16, REST, LEN12, C5, LEN10, REST, L8D, REST, L16
	db G4, REST, C5, REST
	REPEAT_END
	db L8, F4, REST, LEN12, C5, LEN10, REST, L16, REST, LEN12, F5, LEN10, REST, L8D, REST, L16
	db C5, REST, F5, REST, L8, As4, REST, LEN12, F5, LEN10, REST, L16, REST, LEN12, As4, LEN10
	db REST, L8D, REST, L16, F4, REST, As4, REST, L8, E4, REST, LEN12, B4, LEN10, REST, L16
	db REST, LEN12, E4, LEN10, REST, L8D, REST, L16, B4, REST, E5, REST, L8, A4, REST, LEN12
	db E5, LEN10, REST, L16, REST, LEN12, A4, LEN10, REST, L8D, REST, L16, E4, REST, A4, REST
	REPEAT $02
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, D5, LEN10, REST, L8D, REST, L16
	db A4, REST, D5, REST, L8, G4, REST, LEN12, D5, LEN10, REST, L16, REST, LEN12, G4, LEN10
	db REST, L8D, REST, L16, D4, REST, G4, REST
	REPEAT_END
	REPEAT $0c
	db L8, D4, REST, LEN12, A4, LEN10, REST, L16, REST, LEN12, D5, LEN10, REST, L8D, REST, L16
	db A4, REST, D5, REST, L8, C4, REST, LEN12, G4, LEN10, REST, L16, REST, LEN12, C5, LEN10
	db REST, L8D, REST, L16, G4, REST, C5, REST
	REPEAT_END
	db PAT_END
Pattern_6644:
	REPEAT $10
	db L8, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_1A, LEN12, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	REPEAT $10
	db L8, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_1A, LEN12, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	REPEAT $16
	db L8, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_1A, LEN12, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	REPEAT $10
	db L8, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_1A, LEN12, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	REPEAT $2c
	db L8, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_1A, LEN12, NOISE_29, LEN10, NOISE_29
	REPEAT_END
	db PAT_END
LengthTable_6690:
	db $03, $6f, $0f, $1e, $3c, $78, $6f, $6f, $5a, $6f, $05, $0a, $0a, $14, $f0
Song6F_Header:
	SONG $00, LengthTable_6690, Song6F_Ch1, Song6F_Ch2, Song6F_Ch3, Song6F_Ch4
Song6F_Ch1:
	dw Pattern_6761
Song6F_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song6F_Ch1_Loop
Song6F_Ch2:
	dw Pattern_66FA
Song6F_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song6F_Ch2_Loop
Song6F_Ch3:
	dw Pattern_67DD
Song6F_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song6F_Ch3_Loop
Song6F_Ch4:
	dw Pattern_6802
Song6F_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song6F_Ch4_Loop
Envelope_66CA:
	db $c1, $00, $00, $00, $58, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_66FA:
	INSTR_ENV Envelope_66CA, $80
	db LEN13, C5, LEN10, C5, C5, LEN11, C5, C5, C5, C5, G4, C5, E5, C5, G4, LEN13
	db E5, LEN10, E5, E5, LEN11, E5, E5, E5, E5, C5, E5, G5, E5, C5, LEN13, F5
	db LEN10, F5, F5, LEN11, F5, F5, F5, LEN13, G5, LEN10, G5, G5, LEN11, G5, G5, G5
	db LEN13, A5, LEN10, A5, A5, LEN11, A5, A5, A5, LEN13, B5, C6, D6, L2, REST, L1
	db E6
	INSTR $78, $00, $80
	REPEAT $04
	db L32, Fs6, E6, Fs6, E6, Fs6, E6, Fs6, E6, Fs6, E6
	REPEAT_END
	INSTR $a3, $00, $80
	db LEN11, E6, LEN13, REST, LEN13, A4, LEN11, A4, A4, LEN13, A4, PAT_END
Pattern_6761:
	INSTR_ENV Envelope_66CA, $80
	db L2, E4, LEN13, REST, LEN10, E4, E4, LEN11, G4, E4, C4, L2, G4, LEN13, REST, LEN10
	db G4, G4, LEN11, C5, G4, E4, LEN11, F4, F4, F4, LEN13, F4, LEN10, F4, F4, LEN11
	db E4, E4, E4, LEN13, E4, LEN10, E4, E4, LEN11, F4, F4, F4, LEN13, F4, LEN10, F4
	db F4, LEN13, G4, A4, B4, L2, REST
	INSTR $b2, $00, $80
	db LEN11, A4, E5, D5, Cs5, A4, E4, A4, E4, D4, Cs4, A3, E3, L4, A3
	INSTR $c8, $00, $80
	REPEAT $03
	db LEN10, E3, A3, E3, A3, E3, A3
	REPEAT_END
	INSTR $c3, $00, $80
	db LEN11, A3, LEN13, REST, LEN13, A3, LEN11, A3, A3, LEN13, A3, PAT_END
Wave_67CD:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_67DD:
	INSTR_WAVE Wave_67CD, $21
	db L2, G5, LEN11, REST, E5, G5, C6, G5, E5, L2, C6, LEN11, REST, G5, C6, E6
	db C6, G5, L2, D6, E6, F6, LEN13, G6, A6, B6, L2, REST, L1D, Cs7, LEN11, Cs7
	db PAT_END
Pattern_6802:
	REPEAT $02
	db L4, NOISE_1A, LEN11, NOISE_29, NOISE_29, NOISE_29, LEN13, NOISE_2E, LEN10, NOISE_29, NOISE_29, LEN11, NOISE_29, NOISE_29, NOISE_29
	REPEAT_END
	REPEAT $03
	db LEN13, NOISE_1A, LEN10, NOISE_29, NOISE_29, LEN11, NOISE_2E, NOISE_29, NOISE_29
	REPEAT_END
	REPEAT $03
	db LEN11, NOISE_1A, LEN10, NOISE_29, NOISE_29
	REPEAT_END
	REPEAT $0a
	db L32, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29
	REPEAT_END
	db L4, NOISE_1A, LEN13, NOISE_29, LEN11, NOISE_29, NOISE_29, LEN13, NOISE_29, PAT_END
Song70_Header:
	SONG $0e, LengthTable_684B, Song70_Ch1, Song70_Ch2, Song70_Ch3, 0
LengthTable_684B:
	db $04, $07, $0e, $18, $50, $5c, $6f, $6f, $6f, $03, $6f, $6f, $6f, $6f, $6f
Song70_Ch1:
	dw Pattern_6872
Song70_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song70_Ch1_Loop
Song70_Ch2:
	dw Pattern_687F
Song70_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song70_Ch2_Loop
Song70_Ch3:
	dw Pattern_68B5
Song70_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song70_Ch3_Loop
Pattern_6872:
	INSTR $58, $00, $80
	db L1, C4
	INSTR $47, $00, $80
	db L4, C4, PAT_END
Pattern_687F:
	INSTR $83, $00, $80
	db L16, C4, E4, G4, A4
	INSTR $68, $00, $80
	db L32, D5, A4, D5, A4, D5, A4, D5
	INSTR $58, $00, $80
	db A4, D5, A4, D5
	INSTR $48, $00, $80
	db A4, D5, A4, D5
	INSTR $38, $00, $80
	db A4, D5, A4, D5
	INSTR $28, $00, $80
	db A4, D5, A4, D5, PAT_END
Pattern_68B5:
	INSTR_WAVE Wave_68BE, $20
	db L16, REST, L1, E5, PAT_END
Wave_68BE:
	db $55, $55, $55, $55, $55, $55, $55, $55, $00, $00, $00, $00, $00, $00, $00, $00
Song73_Header:
	SONG $00, LengthTable_68D9, Song73_Ch1, Song73_Ch2, Song73_Ch3, Song73_Ch4
LengthTable_68D9:
	db $6f, $08, $0d, $1a, $6f, $6f, $05, $12, $6f, $6f, $6f, $6f, $6f, $6f, $6f
Song73_Ch1:
	dw Pattern_6908
Song73_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song73_Ch1_Loop
Song73_Ch2:
	dw Pattern_694A
Song73_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song73_Ch2_Loop
Song73_Ch3:
	dw Pattern_696C
Song73_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song73_Ch3_Loop
Song73_Ch4:
	dw Pattern_6985
Song73_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song73_Ch4_Loop
Pattern_6908:
	INSTR_ENV Envelope_691A, $40
	REST_ENV $00
	db L4, G4, Gs4, L8, A4, As4, L16, B4, C5, L4, Cs5, PAT_END
Envelope_691A:
	db $b7, $00, $00, $27, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_694A:
	INSTR_ENV Envelope_691A, $40
	REST_ENV $00
	db L4, C5, Cs5, L8, D5, Ds5, L16, E5, F5, L4, Fs5, PAT_END
Wave_695C:
	db $ee, $ee, $ee, $ee, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_696C:
	INSTR_WAVE Wave_695C, $20
	db L16, C3, L4D, REST, L16, Cs3, L4D, REST, L16, D3, L8D, REST, L16, Ds3, L8D, REST
	db L16, E3, F3, Fs3, PAT_END
Pattern_6985:
	db L4, NOISE_29, NOISE_29, L8, NOISE_29, NOISE_29, L16, NOISE_29, NOISE_29, NOISE_29, PAT_END
Song74_Header:
	SONG $00, LengthTable_699B, Song74_Ch1, Song74_Ch2, Song74_Ch3, Song74_Ch4
LengthTable_699B:
	db $6f, $6f, $6f, $15, $2a, $6f, $6f, $6f, $6f, $6f, $6f, $07, $6f, $0e, $6f
Song74_Ch1:
	dw Pattern_69CA
Song74_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song74_Ch1_Loop
Song74_Ch2:
	dw Pattern_6A15
Song74_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song74_Ch2_Loop
Song74_Ch3:
	dw Pattern_6A4E
Song74_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song74_Ch3_Loop
Song74_Ch4:
	dw Pattern_6A6A
Song74_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song74_Ch4_Loop
Pattern_69CA:
	INSTR $b1, $00, $40
	db LEN11, Fs4, REST, REST, Fs4, REST, REST, G4, REST, REST, F4, LEN11, E4, LEN13, REST, L2
	db REST, LEN13, C4, REST, LEN11, REST, PAT_END
Envelope_69E5:
	db $b1, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_6A15:
	INSTR_ENV Envelope_69E5, $40
	db LEN11, A5, LEN13, Gs5, LEN11, A5, LEN13, B5, LEN11, A5, LEN13, B5, LEN11, G5, LEN11, C6
	db REST
	INSTR $d1, $00, $80
	db E3, F3, Fs3, G3, C3, REST, REST
	INSTR_ENV Envelope_69E5, $40
	db LEN13, C6, LEN11, REST, PAT_END
Wave_6A3E:
	db $7e, $ee, $ee, $ee, $ee, $ee, $ee, $ee, $70, $00, $00, $00, $00, $00, $00, $00
Pattern_6A4E:
	INSTR_WAVE Wave_6A3E, $20
	db LEN11, C4, D3, REST, C4, G3, REST, F4, G3, REST, D4, C4, REST, REST, REST, REST
	db REST, REST, REST, REST, C3, REST, REST, PAT_END
Pattern_6A6A:
	db LEN11, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, L4, NOISE_1A, LEN11, NOISE_29, NOISE_29
	db NOISE_29, L4, NOISE_2E, NOISE_1A, PAT_END
Song75_Header:
	SONG $e8, LengthTable_6A8A, Song75_Ch1, Song75_Ch2, Song75_Ch3, Song75_Ch4
LengthTable_6A8A:
	db $01, $6f, $6f, $15, $2a, $6f, $6f, $6f, $6f, $6f, $6f, $07, $6f, $0e, $6f
Song75_Ch1:
	dw Pattern_6B2F
Song75_Ch1_Loop:
	dw Pattern_6B34
	LIST_LOOP Song75_Ch1_Loop
Song75_Ch2:
	dw Pattern_6AB7
Song75_Ch2_Loop:
	dw Pattern_6ABE
	LIST_LOOP Song75_Ch2_Loop
Song75_Ch3:
	dw Pattern_6B85
Song75_Ch3_Loop:
	dw Pattern_6B9A
	LIST_LOOP Song75_Ch3_Loop
Song75_Ch4:
	dw Pattern_6BA2
	LIST_LOOP Song75_Ch4
Pattern_6AB7:
	INSTR $71, $00, $80
	db L32, REST, PAT_END
Pattern_6ABE:
	db LEN13, C5, LEN11, E5, LEN13, G6, LEN11, C5, LEN13, E5, LEN11, G6, LEN13, C5, LEN11, E5
	db LEN13, Fs6, LEN11, C5, LEN13, Ds5, L2, Fs6, LEN11, REST, LEN13, C5, LEN11, D5, LEN13, F6
	db LEN11, C5, LEN13, D5, LEN11, F6, LEN13, C5, LEN11, D5, LEN13, E6, LEN11, G4, LEN13, C5
	db L4, E6, LEN11, G5, LEN13, REST, LEN11, G5, LEN13, C5, LEN11, E5, LEN13, G6, LEN11, C5
	db LEN13, E5, LEN11, G6, LEN13, C5, LEN11, E5, LEN13, Fs6, LEN11, C5, LEN13, Ds5, L2, Fs6
	db LEN11, REST, LEN13, C5, LEN11, D5, LEN13, F6, LEN11, C5, LEN13, D5, LEN11, F6, LEN13, C5
	db LEN11, D5, LEN13, E6, LEN11, C5, LEN13, D5, L4, C5, LEN11, C6, LEN13, REST, LEN11, C6
	db PAT_END
Pattern_6B2F:
	INSTR $71, $00, $80
	db PAT_END
Pattern_6B34:
	db L4, REST, LEN13, E6, L4, REST, LEN11, E6, L4, REST, LEN13, Ds6, L4, REST, L2, Ds6
	db LEN11, REST, L4, REST, LEN13, D6, L4, REST, LEN11, D6, L4, REST, LEN13, C6, L4, REST
	db L4, C6, LEN11, E5, LEN13, REST, LEN11, E5, L4, REST, LEN13, E6, L4, REST, LEN11, E6
	db L4, REST, LEN13, Ds6, L4, REST, L2, Ds6, LEN11, REST, L4, REST, LEN13, D6, L4, REST
	db LEN11, D6, L4, REST, LEN13, C6, L4, REST, L4, G4, LEN11, G5, LEN13, REST, LEN11, G5
	db PAT_END
Pattern_6B85:
	INSTR_WAVE Wave_6B8A, $21
	db PAT_END
Wave_6B8A:
	db $38, $bb, $bb, $bb, $bb, $bb, $bb, $bb, $83, $00, $00, $00, $00, $00, $00, $00
Pattern_6B9A:
	REPEAT $20
	db LEN13, C5, LEN11, REST
	REPEAT_END
	db PAT_END
Pattern_6BA2:
	REPEAT $07
	db L4, NOISE_2E, LEN13, NOISE_29, LEN11, NOISE_29
	REPEAT_END
	db LEN13, NOISE_2E, LEN11, NOISE_29, LEN13, NOISE_29, LEN11, NOISE_29, PAT_END
Song76_Header:
	SONG $00, LengthTable_6BBF, Song76_Ch1, Song76_Ch2, Song76_Ch3, Song76_Ch4
LengthTable_6BBF:
	db $6f, $05, $0a, $12, $24, $48, $4d, $18, $22, $17, $03, $06, $06, $0c, $90
Song76_Ch1:
	dw Pattern_6CC3
Song76_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song76_Ch1_Loop
Song76_Ch2:
	dw Pattern_6C7E
Song76_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song76_Ch2_Loop
Song76_Ch3:
	dw Pattern_6D3D
Song76_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song76_Ch3_Loop
Song76_Ch4:
	dw Pattern_6D7B
Song76_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song76_Ch4_Loop
Envelope_6BEE:
	db $d1, $00, $00, $00, $00, $00, $00, $00, $48, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_6C1E:
	db $91, $00, $00, $00, $00, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_6C4E:
	db $29, $00, $00, $00, $00, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $28
Pattern_6C7E:
	INSTR $91, $00, $80
	db L16, G5, A5, B5, D6, F6, G6, B6, D7
	INSTR_ENV Envelope_6BEE, $40
	db LEN11, C6, LEN13, REST, REST, L4D, G5, LEN11, E5, LEN13, REST, REST, LEN11, A5, REST, REST
	db L4, B5, LEN11, As5, LEN11, A5, REST, REST, L1D, G5, LEN11, REST, LEN13, REST, L4, REST
	db LEN13, As5, LEN11, B5, LEN13, REST, LEN11, C6, L2, REST
	INSTR_ENV Envelope_6C4E, $80
	db L8, REST, G5, L1, D6, PAT_END
Pattern_6CC3:
	INSTR $44, $00, $80
	db LEN13, REST, L16, G5, A5, B5, D6, F5, G6, B6, LEN9, REST
	INSTR_ENV Envelope_6C1E, $40
	db L4D, C5, LEN11, G4, LEN13, REST, REST, LEN11, C5, REST, REST, L4, D5, LEN11, Cs5, LEN11
	db C5, REST, REST, L4, REST, LEN11, E5, F5, Fs5, LEN13, G5, LEN11, E5, LEN13, C5, LEN11
	db G4, LEN11, As4, A4, As4, A4, As4, A4, As4, A4, As4, A4, As4, A4, As4, LEN13
	db REST, L4, REST, L4, F5, LEN13, REST, LEN11, E5, L2, REST
	INSTR_ENV Envelope_6C4E, $80
	db L16, REST, L8, E5, L8D, A5, PAT_END
Wave_6D1D:
	db $6c, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $60, $00, $00, $00, $00, $00, $00, $00
Wave_6D2D:
	db $24, $66, $66, $66, $66, $66, $66, $66, $42, $00, $00, $00, $00, $00, $00, $00
Pattern_6D3D:
	INSTR_WAVE Wave_6D2D, $21
	db L2D, G6, LEN11, REST
	INSTR_WAVE Wave_6D1D, $21
	db LEN11, G4, LEN13, REST, REST, L4D, E4, LEN11, C4, LEN13, REST, LEN13, F4, LEN11, REST, G3
	db REST, L4, G4, LEN11, Fs4, LEN11, F4, REST, REST, L1D, E4, LEN11, E4, LEN13, REST, L4
	db REST, LEN13, D4, LEN11, Cs4, LEN13, REST, LEN11, C4, L2, REST
	INSTR_WAVE Wave_6D2D, $21
	db L8D, C5, PAT_END
Pattern_6D7B:
	db L2D, REST, LEN10, NOISE_29, NOISE_29
	REPEAT $08
	db L4, NOISE_2E, LEN13, NOISE_29, LEN11, NOISE_29
	REPEAT_END
	db L4, NOISE_1A, LEN11, NOISE_29, NOISE_29, NOISE_29, LEN13, NOISE_2E, LEN11, NOISE_29, LEN13, NOISE_29, LEN11, NOISE_1A, L2, REST
	db L8D, REST, L16, NOISE_29, NOISE_29, L4, NOISE_2E, PAT_END
Song77_Header:
	SONG $f6, LengthTable_6DAC, Song77_Ch1, Song77_Ch2, Song77_Ch3, Song77_Ch4
LengthTable_6DAC:
	db $6f, $6f, $6f, $1e, $3c, $78, $6f, $6f, $5a, $6f, $05, $0a, $0a, $14, $6f
Song77_Ch1:
	dw Pattern_6DD9
Song77_Ch1_Loop:
	dw Pattern_6DDE
	LIST_LOOP Song77_Ch1_Loop
Song77_Ch2:
	dw Pattern_6E9C
Song77_Ch2_Loop:
	dw Pattern_6EA1
	LIST_LOOP Song77_Ch2_Loop
Song77_Ch3:
	dw Pattern_6F5A
Song77_Ch3_Loop:
	dw Pattern_6F6F
	LIST_LOOP Song77_Ch3_Loop
Song77_Ch4:
	dw Pattern_7032
	LIST_LOOP Song77_Ch4
Pattern_6DD9:
	INSTR $74, $00, $80
	db PAT_END
Pattern_6DDE:
	db L4, REST, REST, REST, LEN11, C5, REST, REST, G4, REST, REST, C5, REST, REST, G4, REST
	db REST, B4, REST, REST, G4, REST, REST, B4, REST, REST, F4, REST, REST, A4, REST, REST
	db E4, REST, REST, A4, REST, REST, E4, REST, G4, LEN13, REST, L4, F4, LEN11, F4, L4
	db E4, D4, LEN11, F4, REST, REST, C4, REST, REST, A4, REST, REST, C4, REST, REST, E4
	db REST, REST, E4, REST, REST, A4, REST, REST, E4, REST, REST, C5, REST, REST, Fs4, REST
	db REST, A4, REST, REST, LEN13, Fs4, LEN11, F4, LEN13, REST, LEN11, G3, LEN13, REST, LEN11, G3
	db L4, A3, B3, LEN11, C5, REST, REST, G4, REST, REST, C5, REST, REST, G4, REST, REST
	db B4, REST, REST, G4, REST, REST, B4, REST, LEN11, E5, LEN13, F5, LEN11, Gs5, LEN11, A4
	db REST, A5, E4, REST, L4, A5, LEN11, E5, LEN13, A5, L4, G5, L4, F4, LEN11, F4
	db L4, E4, D4, LEN11, F5, REST, REST, C4, REST, REST, A5, REST, REST, C4, REST, REST
	db C5, REST, REST, E4, REST, REST, A4, REST, LEN11, G4, LEN13, A4, LEN11, As4, L4, Fs4
	db REST, LEN13, REST, LEN11, D4, LEN13, F4, LEN11, E4, L1, REST, L4, REST, PAT_END
Pattern_6E9C:
	INSTR $94, $00, $80
	db PAT_END
Pattern_6EA1:
	db L4, B4, C5, D5, LEN13, E5, LEN11, Ds5, LEN13, E5, LEN11, Ds5, LEN13, E5, LEN11, G5
	db REST, REST, L4, D5, LEN11, Cs5, LEN13, D5, LEN11, Cs5, LEN13, D5, LEN11, G5, L4, REST
	db LEN13, REST, LEN11, C5, LEN13, REST, LEN11, C5, L4, E5, LEN13, C5, L1, As4, LEN11, REST
	db L4, A4, B4, C5, A4, G4, LEN13, E5, C5, REST, L4, REST, LEN13, D5, LEN11, Cs5
	db LEN13, D5, LEN11, Cs5, L4, D5, LEN13, A4, L4, B4, LEN11, B3, REST, REST, B3, L4
	db C4, D4, LEN13, E5, LEN11, Ds5, LEN13, E5, LEN11, Ds5, LEN13, E5, LEN11, G5, REST, REST
	db L4, D5, LEN11, Cs5, LEN13, D5, LEN11, Cs5, LEN13, D5, LEN11, Gs5, LEN13, A5, LEN11, B5
	db LEN13, REST, LEN11, C6, LEN13, REST, LEN11, C6, LEN13, C6, LEN11, G5, LEN13, C6, L1, As5
	db LEN11, REST, L4, A5, B5, C6, A5, LEN13, G5, LEN11, Ds5, LEN13, D5, L4, C5, LEN11
	db B3, LEN13, C4, LEN11, Cs4, LEN13, D5, LEN11, Cs5, LEN13, D5, LEN11, Cs5, LEN13, D5, LEN11
	db A4, LEN13, B4, LEN13, C5, LEN11, REST, C4, LEN13, A3, LEN11, REST, LEN13, G3, LEN11, Ds3
	db LEN13, D3, LEN11, REST, LEN11, C3, LEN13, REST, PAT_END
Pattern_6F5A:
	INSTR_WAVE Wave_6F5F, $21
	db PAT_END
Wave_6F5F:
	db $37, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $73, $00, $00, $00, $00, $00, $00, $00
Pattern_6F6F:
	db LEN13, G4, LEN11, REST, LEN13, A4, LEN11, REST, LEN13, B4, LEN11, REST, LEN13, C5, LEN11, REST
	db E5, LEN13, REST, G4, LEN11, REST, E5, LEN13, REST, D5, LEN11, REST, F5, LEN13, REST, G4
	db LEN11, REST, L4, Gs4, LEN11, A4, REST, REST, C5, LEN13, REST, E4, LEN11, REST, C5, REST
	db C5, G4, REST, D5, REST, REST, D5, C5, REST, As4, A4, REST, G4, LEN13, F4, LEN11
	db REST, A4, LEN13, REST, C4, LEN11, REST, A4, LEN13, REST, E4, LEN11, REST, C5, LEN13, REST
	db L4, C4, LEN11, D4, REST, E4, LEN13, D4, LEN11, REST, D5, LEN13, REST, A4, LEN11, REST
	db D5, REST, G4, L1, REST, LEN13, C5, LEN11, REST, E5, LEN13, REST, G4, LEN11, REST, E5
	db LEN13, REST, D5, LEN11, REST, F5, LEN13, REST, G4, LEN11, D5, LEN11, C5, REST, B4, LEN13
	db A4, LEN11, REST, C5, LEN13, REST, E4, LEN11, REST, C5, LEN13, REST, LEN11, G4, REST, D5
	db REST, REST, D5, C5, REST, As4, A4, REST, G4, LEN13, F4, LEN11, REST, A4, LEN13, REST
	db C4, LEN11, REST, A4, LEN13, REST, E4, LEN11, REST, C5, LEN13, REST, C4, LEN11, REST, L4
	db Ds5, LEN11, D5, LEN13, REST, REST, L4, REST, LEN11, Fs4, LEN13, G4, LEN11, C5, L1, REST
	db L4, REST, PAT_END
Pattern_7032:
	db L4, REST, LEN13, REST, LEN11, NOISE_29, L4, NOISE_29
	REPEAT $03
	db L4, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29
	REPEAT_END
	db LEN13, NOISE_2E, L4, NOISE_29, LEN11, NOISE_2E, LEN13, NOISE_29, LEN11, NOISE_2E, L4, NOISE_29
	REPEAT $03
	db L4, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29
	REPEAT_END
	db LEN13, NOISE_2E, L4, NOISE_29, LEN11, NOISE_2E, L4, NOISE_29, LEN11, NOISE_29, NOISE_29, NOISE_29, L4, NOISE_2E, NOISE_29, NOISE_2E
	db NOISE_29, L4, NOISE_2E, NOISE_29, LEN13, NOISE_2E, LEN11, NOISE_29, NOISE_29, REST, NOISE_29, L4, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29
	db LEN13, NOISE_2E, L4, NOISE_29, LEN11, NOISE_2E, LEN13, NOISE_29, LEN11, NOISE_2E, L4, NOISE_29, L4, NOISE_2E, NOISE_29, NOISE_2E
	db NOISE_29, NOISE_2E, LEN13, NOISE_29, L4, NOISE_2E, LEN11, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L4, NOISE_1A, REST, LEN13, REST
	db LEN11, NOISE_29, LEN11, NOISE_29, REST, NOISE_29, L4, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, L4, NOISE_29, PAT_END
Song78_Header:
	SONG $00, LengthTable_70AF, Song78_Ch1, Song78_Ch2, Song78_Ch3, Song78_Ch4
LengthTable_70AF:
	db $6f, $6f, $6f, $15, $2a, $6f, $6f, $6f, $6f, $6f, $6f, $07, $6f, $0e, $6f
Song78_Ch1:
	dw Pattern_70DC
Song78_Ch1_Loop:
	dw Pattern_70E1
	LIST_LOOP Song78_Ch1_Loop
Song78_Ch2:
	dw Pattern_7103
Song78_Ch2_Loop:
	dw Pattern_7138
	LIST_LOOP Song78_Ch2_Loop
Song78_Ch3:
	dw Pattern_71A3
Song78_Ch3_Loop:
	dw Pattern_71B8
	LIST_LOOP Song78_Ch3_Loop
Song78_Ch4:
	dw Pattern_71FC
	LIST_LOOP Song78_Ch4
Pattern_70DC:
	INSTR $91, $00, $40
	db PAT_END
Pattern_70E1:
	REPEAT $10
	db LEN11, REST, REST, G4
	REPEAT_END
	REPEAT $04
	db REST, REST, A4
	REPEAT_END
	REPEAT $04
	db REST, REST, G4
	REPEAT_END
	REPEAT $04
	db REST, REST, A4
	REPEAT_END
	db LEN11, B4, REST, REST, L4, G4, L2, F4, PAT_END
Pattern_7103:
	INSTR_ENV Envelope_7108, $40
	db PAT_END
Envelope_7108:
	db $91, $00, $00, $00, $28, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_7138:
	db LEN13, REST, LEN11, E5, LEN13, Ds5, LEN11, E5, LEN13, G5, LEN11, E5, LEN13, C5, LEN11, G4
	db LEN13, REST, LEN11, G4, LEN13, A4, L4, G4, REST, LEN11, REST, LEN13, REST, LEN11, E5, LEN13
	db Ds5, LEN11, E5, LEN13, G5, LEN11, E5, LEN13, C5, LEN13, G5, LEN11, REST, LEN11, G5, LEN13
	db A5, L4, G5, REST, LEN11, REST, LEN13, REST, LEN11, A5, LEN13, Gs5, LEN11, A5, LEN13, C6
	db L4, A5, LEN11, REST, LEN13, REST, LEN11, G5, LEN13, Fs5, LEN11, G5, LEN13, C6, L4, G5
	db LEN11, REST, LEN13, REST, LEN11, A5, LEN13, Gs5, LEN11, A5, LEN13, B5, LEN11, A5, LEN13, B5
	db LEN11, C6, LEN11, D6, LEN13, REST, L4, B5, A5, G5, PAT_END
Pattern_71A3:
	INSTR_WAVE Wave_71A8, $20
	db PAT_END
Wave_71A8:
	db $4a, $ee, $ee, $ee, $ee, $ee, $ee, $ee, $a4, $00, $00, $00, $00, $00, $00, $00
Pattern_71B8:
	REPEAT $06
	db LEN11, C4, REST, E4, G3, REST, E4
	REPEAT_END
	db C4, REST, E4, C4, REST, E4, As3, REST, E4, G3, REST, E4
	REPEAT $02
	db F3, REST, F4, C4, REST, F4
	REPEAT_END
	REPEAT $02
	db G3, REST, E4, C3, REST, E3
	REPEAT_END
	db D3, REST, Fs4, D3, REST, Fs4, Fs3, REST, Fs4, Fs3, REST, Fs4, G3, REST, REST, LEN13
	db G3, LEN11, REST, LEN13, A3, LEN11, REST, LEN13, B3, LEN11, REST, PAT_END
Pattern_71FC:
	REPEAT $02
	db LEN11, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A
	db NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, LEN13, NOISE_1A, LEN11, NOISE_2E
	REPEAT_END
	REPEAT $02
	db NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, LEN13, NOISE_1A, LEN11, NOISE_2E
	REPEAT_END
	db LEN11, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, NOISE_2E, REST, NOISE_1A, L4, NOISE_1A, NOISE_2E
	db REST, REST, PAT_END
Song79_Header:
	SONG $00, LengthTable_7247, Song79_Ch1, Song79_Ch2, Song79_Ch3, 0
LengthTable_7247:
	db $05, $6f, $6f, $18, $6f, $6c, $6f, $2e, $6f, $6f, $07, $08, $0e, $10, $6f
Song79_Ch1:
	dw Pattern_726E
Song79_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song79_Ch1_Loop
Song79_Ch2:
	dw Pattern_729F
Song79_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song79_Ch2_Loop
Song79_Ch3:
	dw Pattern_72F3
Song79_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song79_Ch3_Loop
Pattern_726E:
	INSTR_ENV Envelope_72C3, $80
	db LEN10, D4, Ds4, E4, F4, Fs4, G4, LEN12, Gs4, LEN10, REST, LEN12, G4, LEN10, REST, LEN12
	db Fs4, LEN10, REST, LEN12, F4, LEN10, REST, LEN11, E4, REST, REST, LEN13, B3, LEN11, REST, LEN11
	db REST, LEN13, G3, L32, As3, G3, As3, G3, As3, G3, L4D, As3, PAT_END
Pattern_729F:
	INSTR_ENV Envelope_72C3, $80
	db LEN10, F4, Fs4, G4, Gs4, A4, As4, LEN10, B4, LEN12, REST, LEN10, As4, LEN12, REST, LEN10
	db A4, LEN12, REST, LEN10, Gs4, LEN12, REST, LEN11, G4, REST, REST, LEN13, F4, L1, E4, PAT_END
Envelope_72C3:
	db $69, $00, $00, $87, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $27, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_72F3:
	INSTR_WAVE Wave_7318, $21
	db LEN10, D4, Cs4, C4, B3, As3, A3, LEN10, Gs3, REST, LEN10, G4, LEN12, REST, LEN10, Fs4
	db LEN12, REST, LEN10, F4, LEN12, REST, LEN10, E4, LEN11, Ds4, REST, REST, LEN13, Cs4, L1, C4
	db PAT_END
Wave_7318:
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
Song7A_Header:
	SONG $00, LengthTable_7333, Song7A_Ch1, Song7A_Ch2, Song7A_Ch3, 0
LengthTable_7333:
	db $00, $00, $0f, $1e, $3c, $1e, $00, $00, $32, $00, $05, $0a, $0a, $14, $1e
Song7A_Ch1:
	dw Pattern_73B0
Song7A_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song7A_Ch1_Loop
Song7A_Ch2:
	dw Pattern_7362
Song7A_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song7A_Ch2_Loop
Song7A_Ch3:
	dw Pattern_73CE
Song7A_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song7A_Ch3_Loop
UnusedList_735A:
	dw Pattern_73FE
Song7A_Ch3_Loop2:
	dw Pattern_5000
	LIST_LOOP Song7A_Ch3_Loop2
Pattern_7362:
	INSTR $61, $00, $80
	db L4, REST, G5, LEN13, REST, LEN11, Fs5, L4, G5, LEN13, REST, LEN11, G5, LEN13, REST, LEN11
	db G5, LEN13, REST
	INSTR_ENV Envelope_7380, $80
	db L1D, G5, PAT_END
Envelope_7380:
	db $81, $00, $00, $00, $47, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_73B0:
	INSTR $61, $00, $80
	db L4, REST, E5, LEN13, REST, LEN11, Ds5, L4, E5, LEN13, REST, LEN11, F5, LEN13, REST, LEN11
	db F5, L4, REST
	INSTR_ENV Envelope_7380, $80
	db L1, E5, PAT_END
Pattern_73CE:
	INSTR_WAVE Wave_73EE, $20
	db LEN11, C5, REST, LEN13, G4, LEN11, REST, B4, G4, REST, REST, REST, REST, REST, F4, REST
	db F4, LEN11, G4, REST, G4, C5, REST, REST, REST, REST, REST, PAT_END
Wave_73EE:
	db $8f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $00, $00, $00, $00, $00, $00, $00
Pattern_73FE:
	db L4, As3, LEN13, $29, LEN11, As3, L2, As3, LEN13, As3, LEN11, $29, LEN13, As3, LEN11, $29
	db L2, As3, PAT_END
Song7B_Header:
	SONG $00, LengthTable_741C, Song7B_Ch1, Song7B_Ch2, Song7B_Ch3, Song7B_Ch4
LengthTable_741C:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $01, $04, $08, $08, $10, $90
Song7B_Ch1:
	dw Pattern_74C9
Song7B_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song7B_Ch1_Loop
Song7B_Ch2:
	dw Pattern_744B
Song7B_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song7B_Ch2_Loop
Song7B_Ch3:
	dw Pattern_7509
Song7B_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song7B_Ch3_Loop
Song7B_Ch4:
	dw Pattern_7559
Song7B_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song7B_Ch4_Loop
Pattern_744B:
	INSTR $68, $00, $80
	db L16, REST, G4, A4, B4, C5, D5, E5, F5
	INSTR $48, $00, $80
	db LEN9, D7, C7, D7, C7, D7, C7, L16, REST, LEN9, D7, C7, D7, C7, D7, C7
	db LEN9, D7, C7, D7, C7, D7, C7, LEN9, A6, G6, A6, G6, A6, G6, LEN9, A6
	db G6, A6, G6, A6, G6, L16, REST, LEN9, D7, C7, D7, C7, D7, C7, L16, REST
	db LEN9, D7, C7, D7, C7, D7, C7, L16, REST, LEN9, D7, C7, D7, C7, D7, C7
	db LEN9, A6, G6, A6, G6, A6, G6, L16, REST, LEN9, A6, G6, A6, G6, A6, G6
	db L16, REST
	INSTR $72, $00, $40
	db L16, G5, Gs5, REST, A5, REST, As5, REST, B5, LEN11, C6, LEN10, REST, LEN9, REST, L32
	db C5, REST, C5, REST, LEN11, C5, PAT_END
Pattern_74C9:
	INSTR $68, $00, $80
	db L16, REST, E4, F4, G4, A4, B4, C5, D5
	INSTR $81, $00, $40
	db L16, A6, C4, E4, G3, L16, A6, E4, G3, C4, L16, A6, G3, C4, A6, L16
	db A6, E4, A6, A6
	INSTR $72, $00, $40
	db L16, E5, F5, REST, Fs5, REST, G5, REST, F5, LEN11, E5, LEN10, REST, LEN9, REST, L32
	db C4, REST, C4, REST, LEN11, C4, PAT_END
Pattern_7509:
	INSTR_WAVE Wave_7549, $20
	db L16, G3, G4, F4, D4, C4, B3, A3, G3, L8, C3, L16, REST, L32, G3, REST
	db L8, G3, L16, REST, L32, C3, REST, L8, C3, L16, REST, L32, G3, REST, L16, G3
	db REST, C3, REST, L32, G3, REST, L16, G3, REST, F3, REST, E3, REST, D3, LEN11, C3
	db LEN10, REST, LEN9, REST, L32, C4, REST, C4, REST, LEN11, C4, PAT_END
Wave_7549:
	db $4a, $ee, $ee, $ee, $ee, $ee, $ee, $ee, $a4, $00, $00, $00, $00, $00, $00, $00
Pattern_7559:
	db L16, NOISE_2E, REST, REST, REST, NOISE_2E, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_1A, NOISE_29, NOISE_29, NOISE_1A, NOISE_29
	db NOISE_29, NOISE_29, NOISE_29, NOISE_1A, NOISE_29, NOISE_29, NOISE_1A, NOISE_1A, NOISE_29, L16, NOISE_2E, NOISE_1A, REST, NOISE_1A, REST, NOISE_1A
	db REST, NOISE_1A, LEN11, NOISE_1A, LEN10, REST, LEN9, REST, L16, NOISE_29, NOISE_29, LEN11, NOISE_2E, PAT_END
Song7C_Header:
	SONG $00, LengthTable_7592, Song7C_Ch1, Song7C_Ch2, Song7C_Ch3, Song7C_Ch4
LengthTable_7592:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $40, $05, $04, $08, $08, $10, $90
Song7C_Ch1:
	dw Pattern_762F
Song7C_Ch1_Loop:
	dw Pattern_7645
	LIST_LOOP Song7C_Ch1_Loop
Song7C_Ch2:
	dw Pattern_75C1
Song7C_Ch2_Loop:
	dw Pattern_75E4
	LIST_LOOP Song7C_Ch2_Loop
Song7C_Ch3:
	dw Pattern_7698
Song7C_Ch3_Loop:
	dw Pattern_76BE
	LIST_LOOP Song7C_Ch3_Loop
Song7C_Ch4:
	dw Pattern_775F
Song7C_Ch4_Loop:
	dw Pattern_7772
	LIST_LOOP Song7C_Ch4_Loop
Pattern_75C1:
	INSTR $72, $00, $40
	db L16, F5, G5, C6, As5, REST, G5, REST, F5, REST, E5, F5, E5, As4, C5, REST
	INSTR_ENV Envelope_75FF, $80
	db L32, E5, F5, L1, G5, REST, L2, C6, L1, G5, PAT_END
Pattern_75E4:
	db L8D, G5, Gs5, L1, A5, L8, REST, L2, REST, REST, D6, L1, A5, L8D, A5, Gs5
	db L1, G5, L8, REST, L2, REST, REST, C6, L1, G5, PAT_END
Envelope_75FF:
	db $34, $00, $00, $00, $3c, $00, $00, $00, $00, $00, $00, $00, $44, $00, $00, $00
	db $00, $00, $00, $00, $2c, $00, $00, $00, $00, $00, $00, $00, $34, $00, $00, $00
	db $00, $00, $00, $00, $1c, $00, $00, $00, $00, $00, $00, $00, $24, $00, $00, $17
Pattern_762F:
	INSTR $92, $00, $40
	db L16, F4, G4, C5, As4, REST, G4, REST, F4, REST, E4, F4, E4, As3, C4, REST
	db REST, PAT_END
Pattern_7645:
	INSTR $81, $00, $40
	REPEAT $03
	db L16, F4, C4, F4, C4, E4, G3, C4, F4, C4, F4, C4, E4, G3, C4, E4
	db C4
	REPEAT_END
	db F4, C4, F4, C4, E4, G3, C4, F4
	INSTR $92, $00, $40
	db L8D, F4, Fs4, L8, G4
	INSTR $81, $00, $40
	REPEAT $03
	db L16, G4, D4, G4, D4, Fs4, A3, D4, G4, D4, G4, D4, Fs4, A3, D4, Fs4
	db D4
	REPEAT_END
	db G4, D4, G4, D4, Fs4, A3, D4, G4
	INSTR $92, $00, $40
	db L8D, G4, Fs4, L8, F4, PAT_END
Pattern_7698:
	INSTR_WAVE Wave_76AE, $20
	db L16, C4, As3, G3, F3, REST, E3, REST, C4, REST, As3, C4, As3, F4, E4, REST
	db REST, PAT_END
Wave_76AE:
	db $fe, $dc, $ba, $98, $76, $54, $32, $10, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_76BE:
	db L8, C3, L16, C4, REST, L8, C3, L16, C4, REST, L8, C3, L16, C4, REST, L8
	db C3, L16, C4, REST, L8, C3, L16, C4, REST, L8, C3, L16, C4, REST, L8, C3
	db L16, C4, REST, L16, C3, C4, C3, REST, L8, C3, L16, C4, REST, L8, C3, L16
	db C4, REST, L8, C3, L16, C4, REST, L8, C3, L16, C4, REST, L8, C3, L16, C4
	db REST, L8, C3, L16, C4, REST, L8, C3, L16, C4, L8, Cs3, L16, Cs4, L8, D3
	db L8, D3, L16, D4, REST, L8, D3, L16, D4, REST, L8, D3, L16, D4, REST, L8
	db D3, L16, D4, REST, L8, D3, L16, D4, REST, L8, D3, L16, D4, REST, L8, D3
	db L16, D4, REST, L16, D3, D4, D3, REST, L8, D3, L16, D4, REST, L8, D3, L16
	db D4, REST, L8, D3, L16, D4, REST, L8, D3, L16, D4, REST, L8, D3, L16, D4
	db REST, L8, D3, L16, D4, REST, L8, D3, L16, D4, L8, Cs3, L16, Cs4, L8, C3
	db PAT_END
Pattern_775F:
	db L8, NOISE_1A, L16, NOISE_2E, NOISE_29, REST, NOISE_29, REST, NOISE_29, REST, NOISE_29, REST, L8D, NOISE_1A, L16, REST
	db L32, NOISE_2E, NOISE_2E
Pattern_7772:
	db L8, NOISE_29, NOISE_29, L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, REST, L16, NOISE_1A, L8D, REST, L8
	db NOISE_29, NOISE_29, L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, NOISE_29, L8D, NOISE_1A, L32, NOISE_2E, NOISE_2E, L8
	db NOISE_29, NOISE_29, L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, REST, L16, NOISE_1A, L8D, REST, L8, NOISE_29
	db NOISE_29, L16, NOISE_1A, L8D, REST, L16, NOISE_1A, NOISE_1A, REST, NOISE_1A, NOISE_1A, REST, L8, NOISE_1A, L8, NOISE_29
	db NOISE_29, L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, REST, L16, NOISE_1A, L8D, REST, L8, NOISE_29, NOISE_29
	db L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, NOISE_29, L8D, NOISE_1A, L32, NOISE_2E, NOISE_2E, L8, NOISE_29, NOISE_29
	db L16, NOISE_1A, L8, REST, NOISE_2E, NOISE_2E, L16, REST, L16, NOISE_1A, L8D, REST, L8, NOISE_29, NOISE_29, L16
	db NOISE_1A, L8D, REST, L16, NOISE_1A, NOISE_1A, REST, NOISE_1A, NOISE_1A, REST, L8, NOISE_1A, PAT_END
Song7D_Header:
	SONG $00, LengthTable_77FA, Song7D_Ch1, Song7D_Ch2, Song7D_Ch3, Song7D_Ch4
LengthTable_77FA:
	db $03, $09, $12, $24, $48, $90, $1b, $36, $6c, $05, $06, $0c, $0c, $18, $90
Song7D_Ch1:
	dw Pattern_7829
Song7D_Ch1_Loop:
	dw Pattern_7838
	LIST_LOOP Song7D_Ch1_Loop
Song7D_Ch2:
	dw Pattern_78B1
Song7D_Ch2_Loop:
	dw Pattern_78C0
	LIST_LOOP Song7D_Ch2_Loop
Song7D_Ch3:
	dw Pattern_7939
Song7D_Ch3_Loop:
	dw Pattern_7969
	LIST_LOOP Song7D_Ch3_Loop
Song7D_Ch4:
	dw Pattern_7A35
Song7D_Ch4_Loop:
	dw Pattern_7A4B
	LIST_LOOP Song7D_Ch4_Loop
Pattern_7829:
	INSTR $91, $00, $40
	db L4, G4, G4, A4, A4, G4, G4, G4, L8, G4, PAT_END
Pattern_7838:
	REPEAT $02
	db L8, REST, G4, LEN12, REST, L32, C4, E4, LEN12, G4, LEN10, E4, L8, REST, A4, REST
	db A4, L8, REST, G4, LEN12, REST, L32, B3, D4, LEN12, G4, LEN10, D4, L8, REST, G4
	db REST, G4
	REPEAT_END
	db L8, REST, G4, LEN12, REST, L32, C4, E4, LEN12, G4, LEN10, E4, L8, REST, A4, REST
	db A4, L8, REST, G4, LEN12, REST, L32, B3, D4, LEN12, G4, LEN10, D4, L8, G4, G4
	db B4, B4
	REPEAT $03
	db LEN11, A4, A4, A4, A4, B4, REST
	REPEAT_END
	db L8, G4, E4, REST, E4, L8, REST, G4, LEN12, REST, L32, C4, E4, LEN12, G4, LEN10
	db E4, L8, REST, A4, REST, A4, L8, REST, G4, LEN12, REST, L32, B3, D4, LEN12, G4
	db LEN10, D4, L8, REST, G4, REST, G4, PAT_END
Pattern_78B1:
	INSTR $91, $00, $40
	db L4, C5, C5, C5, C5, B4, B4, C5, L8, C5, PAT_END
Pattern_78C0:
	REPEAT $02
	db L8, REST, C5, LEN12, REST, L32, E4, G4, LEN12, C5, LEN10, G4, L8, REST, C5, REST
	db C5, L8, REST, B4, LEN12, REST, L32, D4, G4, LEN12, B4, LEN10, G4, L8, REST, C5
	db REST, C5
	REPEAT_END
	db L8, REST, C5, LEN12, REST, L32, E4, G4, LEN12, C5, LEN10, G4, L8, REST, C5, REST
	db C5, L8, REST, B4, LEN12, REST, L32, D4, G4, LEN12, B4, LEN10, G4, L8, B4, B4
	db D5, D5
	REPEAT $03
	db LEN11, C5, C5, C5, C5, D4, REST
	REPEAT_END
	db L8, C5, G4, REST, G4, L8, REST, C5, LEN12, REST, L32, E4, G4, LEN12, C5, LEN10
	db G4, L8, REST, C5, REST, C5, L8, REST, B4, LEN12, REST, L32, D4, G4, LEN12, B4
	db LEN10, G4, L8, REST, C5, REST, C5, PAT_END
Pattern_7939:
	INSTR_WAVE Wave_7AAD, $20
	db LEN10, C4, REST, C4, REST, REST, G3, A3, REST, REST, L16, F4, REST, E4, REST, F4
	db L8D, REST, L8, REST, LEN10, G4, REST, G4, REST, REST, G4, F4, REST, REST, L16, E4
	db REST, C4, REST, LEN10, G3, REST, G3, LEN12, A3, LEN10, G3, PAT_END
Pattern_7969:
	db L8, REST, LEN10, C4, REST, C4, REST, REST, G3, A3, REST, REST, L16, F4, REST, E4
	db REST, F4, L8D, REST, L8, REST, LEN10, G4, REST, G4, REST, REST, G4, F4, REST, REST
	db L16, E4, REST, C4, REST, LEN10, C4, REST, G4, LEN12, A4, LEN10, B4, L8, REST, LEN10
	db C5, LEN12, REST, REST, L8, G4, LEN10, E4, L16, F4, REST, E4, REST, F4, L8D, REST
	db L8, REST, LEN10, G4, REST, G4, REST, REST, G4, F4, REST, REST, L16, E4, REST, LEN10
	db C4, REST, G3, LEN12, REST, LEN10, G3, LEN12, A3, LEN10, G3, L8, REST, LEN10, C4, REST
	db C4, REST, REST, G3, A3, REST, REST, L16, F4, REST, E4, REST, F4, L8D, REST, L8
	db REST, LEN10, G4, REST, G4, REST, REST, G4, A4, REST, REST, L16, G4, REST, G4, REST
	db F4, REST, D4, REST
	REPEAT $03
	db LEN10, F3, REST, F4, REST, F4, REST, F4, REST, G4, REST, REST, REST
	REPEAT_END
	db L16, C4, REST, REST, G3, L8, A3, L16, G3, REST, L8, REST, LEN10, C4, REST, C4
	db REST, REST, G3, A3, REST, REST, L16, F4, REST, E4, REST, F4, L8D, REST, L8, REST
	db LEN10, G4, REST, G4, REST, REST, G4, F4, REST, REST, L16, E4, REST, C4, REST, LEN10
	db G3, REST, G3, LEN12, A3, LEN10, G3, PAT_END
Pattern_7A35:
	db L8, REST, L4, REST, REST, REST, L2, REST, L8, REST, LEN12, REST, L32, NOISE_29, NOISE_29, LEN12
	db NOISE_1A, L8, NOISE_1A, LEN10, NOISE_1A, PAT_END
Pattern_7A4B:
	db L8, NOISE_29, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_2E, L8, NOISE_29, NOISE_2E, L8, NOISE_29, NOISE_2E
	db NOISE_29, NOISE_2E, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_1A, L8, NOISE_1A, NOISE_1A
	REPEAT $03
	db L8, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_2E, L8, NOISE_29, NOISE_1A
	REPEAT_END
	db L8, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29
	REPEAT $02
	db LEN11, NOISE_2E, NOISE_1A, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E
	REPEAT_END
	db NOISE_2E, NOISE_1A, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E, L8, NOISE_2E, LEN12, REST, L32, NOISE_29, NOISE_29, LEN12, NOISE_1A, L8
	db NOISE_1A, LEN10, NOISE_1A
	REPEAT $02
	db L8, NOISE_29, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_2E, L8, NOISE_29, NOISE_2E
	REPEAT_END
	db PAT_END
Wave_7AAD:
	db $8f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $00, $00, $00, $00, $00, $00, $00
Song7E_Header:
	SONG $00, LengthTable_7AC8, Song7E_Ch1, Song7E_Ch2, Song7E_Ch3, Song7E_Ch4
LengthTable_7AC8:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $04, $08, $0c, $18, $90
; unreferenced byte after the length table
	db $10
Song7E_Ch1:
	dw Pattern_7AF8
Song7E_Ch1_Loop:
	dw Pattern_7B20
	LIST_LOOP Song7E_Ch1_Loop
Song7E_Ch2:
	dw Pattern_7B55
Song7E_Ch2_Loop:
	dw Pattern_7B81
	LIST_LOOP Song7E_Ch2_Loop
Song7E_Ch3:
	dw Pattern_7C4E
Song7E_Ch3_Loop:
	dw Pattern_7C84
	LIST_LOOP Song7E_Ch3_Loop
Song7E_Ch4:
	dw Pattern_7D0B
Song7E_Ch4_Loop:
	dw Pattern_7D23
	LIST_LOOP Song7E_Ch4_Loop
Pattern_7AF8:
	INSTR $b2, $00, $80
	db L16, E4, REST, REST, REST, REST, REST, Ds4, REST, D4, REST, REST, REST, REST, REST, Cs4
	db REST, C4, REST, REST, REST, L8, C4, L16, B3, REST
	INSTR $82, $00, $80
	db L4, REST, L8, C4, B3, PAT_END
Pattern_7B20:
	REPEAT $08
	db REST, C4, REST, C4, REST, C4, REST, C4
	REPEAT_END
	REPEAT $03
	db REST, G4, REST, G4, REST, G4, REST, G4, REST, L16, F4, E4, L8, F4, REST, L16
	db F4, E4, L8, F4, REST, REST
	REPEAT_END
	db G4, G4, D4, D4, F4, F4, C4, C4, REST, C4, REST, C4, REST, C4, REST, B3
	db PAT_END
Pattern_7B55:
	INSTR $b1, $00, $40
	db L16, B4, C4, As4, C4, A4, C4, Gs4, C4, G4, C4, Fs4, C4, F4, C4, E4
	db C4, Ds4, REST, Gs3, REST, L8, Ds4, L16, D4, REST
	INSTR $91, $00, $40
	db L16, REST, G3, B3, D3, F3, F4, D4, G3, PAT_END
Pattern_7B81:
	db L8, E4, E4, L16, C4, E4, G3, C4, E4, G3, L8, C4, E4, L16, C4, G3
	db L8, E4, E4, L16, C4, E4, G3, C4, E4, G3, C4, G4, E4, G3, D4, G3
	db L8, F4, F4, L16, C4, F4, A3, C4, F4, A3, L8, C4, F4, L16, C4, F4
	db L16, Gs4, A4, A4, A4, L8, C5, L16, C4, F4, A4, C4, F4, A3, C4, F4
	db A3, C4, L8, E4, E4, L16, C4, E4, G3, C4, E4, G3, L8, C4, E4, L16
	db C4, G3, L8, E4, E4, L16, C4, E4, G3, C4, E4, G3, C4, G4, E4, G3
	db D4, G3, L8, F4, F4, L16, C4, F4, A3, C4, F4, A3, L8, C4, F4, L16
	db C4, F4, L16, Gs4, A4, A4, A4, L8, C5, L16, C4, F4, A4, C4, F4, A3
	db C4, F4, A4, C5
	REPEAT $03
	db L16, As4, B4, B4, As4, B4, B4, As4, B4, B4, As4, B4, B4, D5, B4, G4
	db D4, L16, F4, A4, L8, C4, F4, L16, C4, F4, L8, A4, L16, C4, F4, A4
	db C5, A4, F4
	REPEAT_END
	db L16, As4, B4, B4, B4, Fs4, G4, G4, G4, Gs4, A4, A4, A4, E4, F4, F4
	db F4, L8, E4, E4, L16, C4, E4, A3, C4, L8, G4, L16, D4, G4, As4, B4
	db G4, D4, PAT_END
Pattern_7C4E:
	INSTR_WAVE Wave_7C74, $20
	db L16, C4, REST, REST, REST, REST, REST, B3, REST, As3, REST, REST, REST, REST, REST, A3
	db REST, Gs3, REST, REST, REST, Gs3, Gs3, G3, REST, REST, REST, G3, REST, A3, REST, B3
	db REST, PAT_END
Wave_7C74:
	db $49, $dd, $dd, $dd, $dd, $dd, $dd, $dd, $94, $00, $00, $00, $00, $00, $00, $00
Pattern_7C84:
	db L8, C4, REST, G3, REST, C4, REST, G3, REST, C4, REST, G3, REST, L16, C4, REST
	db C4, REST, D4, REST, E4, REST, L8, F4, REST, C4, REST, F4, REST, C4, REST, F4
	db REST, C4, REST, L16, F4, REST, E4, REST, Ds4, REST, D4, REST, L8, C4, REST, G3
	db REST, C4, REST, G3, REST, C4, REST, G3, REST, L16, C4, REST, C4, REST, D4, REST
	db E4, REST, L8, F4, REST, C4, REST, F4, REST, C4, REST, F4, REST, C4, REST, L16
	db F4, REST, E4, REST, F4, REST, Fs4, REST
	REPEAT $03
	db L8, G4, REST, D4, REST, G4, REST, L4, G4, L16, F4, REST, C4, REST, C4, REST
	db F4, REST, C4, REST, C4, REST, F4, REST, C4, REST
	REPEAT_END
	db L8, G4, REST, G4, REST, F4, REST, F4, REST, C4, REST, A3, REST, D4, REST, G3
	db REST, PAT_END
Pattern_7D0B:
	db L8, NOISE_29, REST, REST, NOISE_29, NOISE_29, REST, REST, NOISE_29, NOISE_29, REST, NOISE_1A, NOISE_29, L16, NOISE_29, NOISE_29
	db NOISE_1A, REST, L8, NOISE_2E, L16, NOISE_29, NOISE_29, PAT_END
Pattern_7D23:
	REPEAT $03
	db L8, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29
	REPEAT_END
	db NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, L16, NOISE_2E, NOISE_2E, L8, NOISE_1A
	REPEAT $03
	db L8, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29
	REPEAT_END
	db NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, L16, NOISE_2E, NOISE_2E, L8, NOISE_1A, L16, NOISE_2E, NOISE_2E, NOISE_29, NOISE_29
	REPEAT $03
	db L8, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_1A, NOISE_2E, NOISE_1A, NOISE_1A, NOISE_2E
	db NOISE_1A
	REPEAT_END
	db NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, NOISE_1A, NOISE_29, NOISE_2E, NOISE_29, L16, NOISE_2E
	db NOISE_2E, L8, NOISE_1A, PAT_END
Song7F_Header:
	SONG $0a, LengthTable_7D87, Song7F_Ch1, Song7F_Ch2, Song7F_Ch3, Song7F_Ch4
LengthTable_7D87:
	db $04, $09, $12, $24, $6f, $6f, $1b, $6f, $6f, $6f, $6f, $6f, $6f, $6f, $6f
; unreferenced byte after the length table
	db $6f
Song7F_Ch1:
	dw Pattern_7DB7
Song7F_Ch1_Loop:
	dw Pattern_7DD2
	LIST_LOOP Song7F_Ch1_Loop
Song7F_Ch2:
	dw Pattern_7ED0
Song7F_Ch2_Loop:
	dw Pattern_7EF0
	LIST_LOOP Song7F_Ch2_Loop
Song7F_Ch3:
	dw Pattern_7F2D
Song7F_Ch3_Loop:
	dw Pattern_7F4E
	LIST_LOOP Song7F_Ch3_Loop
Song7F_Ch4:
	dw Pattern_7F7C
Song7F_Ch4_Loop:
	dw Pattern_7F89
	LIST_LOOP Song7F_Ch4_Loop
Pattern_7DB7:
	INSTR $71, $00, $80
	db L32, E4, Gs4
	INSTR $81, $00, $80
	db L16, B4
	INSTR $71, $00, $80
	db E4, Gs4, B4
	INSTR $81, $00, $80
	db D5, L8D, D5
Pattern_7DD2:
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db D4, Ds4, E4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, REST, C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db B3, Ds4, D4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db C4, Cs4, D4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, REST
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db REST, B3
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db C4
	INSTR $51, $00, $80
	db L16, A6
	INSTR $62, $00, $80
	db E4, PAT_END
Pattern_7ED0:
	INSTR $71, $00, $80
	db L32, B4, D5
	INSTR $81, $00, $80
	db L16, E5
	INSTR $71, $00, $80
	db B4, D5, E5
	INSTR $81, $00, $80
	db Gs5, L8D, Gs5
	INSTR $62, $00, $80
	db PAT_END
Pattern_7EF0:
	db L8, A4, L16, C5, L8, G4, C5, Fs4, C5, L8, E4, L16, Fs4, G4, Gs4, L8
	db A4, L16, C5, L8, G4, C5, Fs4, C5, L8, E4, L16, Ds4, E4, Fs4, L8, G4
	db L16, B4, L8, Fs4, B4, E4, B4, L8, D4, L16, E4, F4, Fs4, L8, G4, L16
	db B4, L8, Fs4, B4, E4, B4, L8, D4, L16, E4, Fs4, Gs4, PAT_END
Pattern_7F2D:
	INSTR_WAVE Wave_7F3E, $21
	db L32, REST, REST, L16, B4, L8D, REST, L8, E4, L16, REST, E4, PAT_END
Wave_7F3E:
	db $12, $47, $9a, $bb, $bb, $bb, $bb, $bb, $a9, $74, $21, $00, $00, $00, $00, $00
Pattern_7F4E:
	db L8D, A3, E4, L4, A4, L16, A4, L8D, E4, L8, A4, L8D, A3, E4, L4, A4
	db L16, A4, L8D, E4, L8, A4, L8D, G3, D4, L4, G4, L16, G4, L8D, D4, L8
	db G4, L8D, G3, D4, G4, L16, G3, REST, D4, G4, REST, D4, REST, PAT_END
Pattern_7F7C:
	db L32, NOISE_29, NOISE_29, L16, NOISE_1A, REST, REST, NOISE_29, NOISE_1A, NOISE_1A, L8, REST, PAT_END
Pattern_7F89:
	REPEAT $07
	db L16, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29
	REPEAT_END
	db NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_2E, PAT_END
; unreferenced: 30 words
Unused_7F9E:
	dw $046a, $00ad, $00a5, $00ac, $0181, $0093, $00e9, $006f, $008b, $00be
	dw $003c, $017b, $079c, $01a1, $008e, $0080, $0091, $00c2, $00ef, $0135
	dw $01ed, $0303, $0198, $00ec, $00e9, $0176, $0268, $02ce, $02bf, $0222
	ds 38, 0	; $7FDA-$7FFF unused
