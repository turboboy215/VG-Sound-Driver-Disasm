; Kirby Tilt 'n' Tumble music: songs, bank $0E $5000-$7FFF

Pattern_5000:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
Pattern_500A:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
; songs $01, $13
Song01_Header:
	SONG $00, LengthTable_501F, Song01_Ch1, Song01_Ch2, Song01_Ch3, 0
LengthTable_501F:
	db $00, $06, $0c, $18, $00, $00, $00, $00, $48, $00, $08, $00, $00, $00, $00
Song01_Ch3:
	dw Pattern_5050
Song01_Ch3_Loop:
	dw Pattern_5055
	LIST_LOOP Song01_Ch3_Loop
Song01_Ch1:
	dw Pattern_5046
Song01_Ch1_Loop:
	dw Pattern_507C
	LIST_LOOP Song01_Ch1_Loop
Song01_Ch2:
	dw Pattern_504B
Song01_Ch2_Loop:
	dw Pattern_5105
	LIST_LOOP Song01_Ch2_Loop
Pattern_5046:
	INSTR $62, $00, $40
	db PAT_END
Pattern_504B:
	INSTR $62, $00, $40
	db PAT_END
Pattern_5050:
	INSTR_WAVE Wave_6D56, $21
	db PAT_END
Pattern_5055:
	db LEN10, Fs5, G5, Gs5, L2D, A5, L4, Fs5, L2D, G5, LEN10, E5, F5, Fs5, L2D, G5
	db L4, E5, L2D, Fs5, L4, E5, L2D, Ds5, L4, Fs5, L2D, G5, LEN10, A4, B4, C5
	db L2D, Cs5, L4, Fs5, L2D, D5, PAT_END
Pattern_507C:
	db LEN10, Fs4, G4, Gs4, L16, A4, REST, A4, A4, REST, A4, REST, A4, REST, A4, REST
	db A4, L16, Fs4, Fs4, Fs4, REST, G4, REST, G4, G4, REST, G4, REST, G4, REST, G4
	db REST, G4, LEN10, E4, F4, Fs4, L16, G4, REST, G4, G4, REST, G4, REST, G4, REST
	db G4, REST, G4, L16, E4, E4, E4, REST, Fs4, REST, Fs4, Fs4, REST, Fs4, REST, Fs4
	db REST, Fs4, REST, Fs4, L16, E4, E4, E4, REST, Ds4, REST, Ds4, Ds4, REST, Ds4, REST
	db Ds4, REST, Ds4, REST, Ds4, L16, Fs4, Fs4, Fs4, REST, G4, REST, G4, G4, REST, G4
	db REST, G4, REST, G4, REST, G4, LEN10, A3, B3, C4, L16, Cs4, REST, Cs4, Cs4, REST
	db Cs4, REST, Cs4, REST, Cs4, REST, Cs4, L16, Fs4, Fs4, Fs4, REST, D4, REST, D4, D4
	db REST, D4, REST, D4, REST, REST, REST, REST, PAT_END
Pattern_5105:
	db LEN10, D4, E4, F4, L16, Fs4, REST, Fs4, Fs4, REST, Fs4, REST, Fs4, REST, Fs4, REST
	db Fs4, L16, D4, D4, D4, REST, E4, REST, E4, E4, REST, E4, REST, E4, REST, E4
	db REST, E4, LEN10, C4, D4, D4, L16, E4, REST, E4, E4, REST, E4, REST, E4, REST
	db E4, REST, E4, L16, Cs4, Cs4, Cs4, REST, D4, REST, D4, D4, REST, D4, REST, D4
	db REST, D4, REST, D4, L16, C4, C4, C4, REST, B3, REST, B3, B3, REST, B3, REST
	db B3, REST, B3, REST, B3, L16, Ds4, Ds4, Ds4, REST, E4, REST, E4, E4, REST, E4
	db REST, E4, REST, E4, REST, E4, LEN10, Fs3, G3, A3, L16, A3, REST, A3, A3, REST
	db A3, REST, A3, REST, A3, REST, A3, L16, Cs4, Cs4, Cs4, REST, A3, REST, A3, A3
	db REST, A3, REST, A3, REST, REST, REST, REST, PAT_END
Song12_Header:
	SONG $00, LengthTable_5199, Song12_Ch1, Song12_Ch2, Song0E_Ch3, Song12_Ch4
LengthTable_5199:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $00
Song12_Ch4:
	dw Pattern_520A
Song12_Ch4_Loop:
	dw Pattern_5225
	LIST_LOOP Song12_Ch4_Loop
Song12_Ch1:
	dw Pattern_51FC
Song12_Ch1_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_520E
	dw Pattern_5214
	LIST_TRANSPOSE_ADD 2
	dw Pattern_520E
	dw Pattern_5214
	LIST_TRANSPOSE_ADD -4
	dw Pattern_520E
	dw Pattern_5214
	LIST_TRANSPOSE_ADD 2
	dw Pattern_520E
	dw Pattern_5214
	LIST_LOOP Song12_Ch1_Loop
Song12_Ch2:
	dw Pattern_5203
Song12_Ch2_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_521A
	dw Pattern_521A
	LIST_TRANSPOSE_ADD 2
	dw Pattern_521A
	dw Pattern_521A
	LIST_TRANSPOSE_ADD -4
	dw Pattern_521A
	dw Pattern_521A
	LIST_TRANSPOSE_ADD 2
	dw Pattern_521A
	dw Pattern_521A
	LIST_LOOP Song12_Ch2_Loop
Pattern_51FC:
	INSTR $52, $00, $00
	REST_ENV $32
	db PAT_END
Pattern_5203:
	INSTR $43, $00, $40
	REST_ENV $22
	db PAT_END
Pattern_520A:
	DRUMKIT DrumKit_523A
	db PAT_END
Pattern_520E:
	db L8, C5, E5, F5, G5, PAT_END
Pattern_5214:
	db L8, F5, E5, F5, D5, PAT_END
Pattern_521A:
	db L16, C4, G4, C5, G5, L16, G4, C5, G5, C6, PAT_END
Pattern_5225:
	db L8, NOISE_06, NOISE_06, NOISE_06, NOISE_0B, L8, NOISE_0B, NOISE_0B, NOISE_10, NOISE_10, L8, NOISE_10, NOISE_15, NOISE_15, NOISE_15, L8
	db NOISE_15, NOISE_15, NOISE_15, NOISE_15, PAT_END
DrumKit_523A:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $66, $00, $2b, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $56, $00, $2b, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $46, $00, $2b, $05, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $36, $00, $2b, $05, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $26, $00, $2b, $05, $c0	; $1a: NR42, -, NR41, NR43, NR44
Song0E_Header:
	SONG $00, LengthTable_5264, Song0E_Ch1, Song0E_Ch2, Song0E_Ch3, 0
LengthTable_5264:
	db $00, $00, $00, $1c, $38, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Song0E_Ch1:
	dw Pattern_528F
Song0E_Ch1_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_5299
	dw Pattern_52BA
	LIST_LOOP Song0E_Ch1_Loop
Song0E_Ch2:
	dw Pattern_5294
Song0E_Ch2_Loop:
	LIST_TRANSPOSE -12
	dw Pattern_52DB
	dw Pattern_52F6
	LIST_LOOP Song0E_Ch2_Loop
Pattern_528F:
	INSTR $67, $00, $81
	db PAT_END
Pattern_5294:
	INSTR $67, $00, $80
	db PAT_END
Pattern_5299:
	db L4, G4, L2, E5, L4, G5, F5, E5, L4, D5, L2, E5, L4, B4, L2, C5
	db L4, G4, A4, B4, L4, C5, C5, D5, L4, E5, E5, F5, L4, E5, E5, D5
	db PAT_END
Pattern_52BA:
	db L4, G4, L2, E5, L4, G5, F5, E5, L4, D5, L2, E5, L4, B4, L2, C5
	db L4, G4, A4, B4, L4, C5, C5, F5, L4, E5, G5, F5, L4, B4, L2, C5
	db PAT_END
Pattern_52DB:
	db L4, REST, C4, G4, C5, D5, G4, D4, G4, B4, D5, L2, E5, L4, REST, F4
	db A4, C5, G4, C5, E5, C5, E5, G5, E5, D5, PAT_END
Pattern_52F6:
	db L4, REST, C4, G4, C5, D5, G4, D4, G4, B4, D5, L2, E5, L4, REST, F4
	db A4, C5, G4, D5, C5, D5, B4, G4, L2, C5, PAT_END
; unreferenced length table
Unused_5311:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $00
Song10_Header:
	SONG $00, LengthTable_532B, Song10_Ch1, Song10_Ch2, Song10_Ch3, Song10_Ch4
LengthTable_532B:
	db $00, $04, $00, $18, $30, $60, $00, $00, $48, $00, $08, $00, $10, $00, $00
Song10_Ch4:
	dw Pattern_5393
Song10_Ch4_Loop:
	dw Pattern_5435
	LIST_LOOP Song10_Ch4_Loop
Song10_Ch2:
	dw Pattern_5380
Song10_Ch2_Loop:
	dw Pattern_53D6
	LIST_TRANSPOSE_ADD 2
	dw Pattern_53D6
	LIST_TRANSPOSE 0
	LIST_LOOP Song10_Ch2_Loop
Song10_Ch1:
	dw Pattern_5387
Song10_Ch1_Loop:
	dw Pattern_540C
	dw Pattern_540C
	LIST_TRANSPOSE_ADD 2
	dw Pattern_540C
	dw Pattern_540C
	LIST_TRANSPOSE 0
	LIST_LOOP Song10_Ch1_Loop
Song10_Ch3:
	dw Pattern_538E
Song10_Ch3_Loop:
	dw Pattern_5397
	dw Pattern_5397
	LIST_TRANSPOSE_ADD 2
	dw Pattern_5397
	dw Pattern_5397
	LIST_TRANSPOSE 0
	LIST_LOOP Song10_Ch3_Loop
Pattern_5380:
	INSTR $56, $00, $80
	REST_ENV $32
	db PAT_END
Pattern_5387:
	INSTR $53, $00, $40
	REST_ENV $22
	db PAT_END
Pattern_538E:
	INSTR_WAVE Wave_6D96, $20
	db PAT_END
Pattern_5393:
	DRUMKIT DrumKit_546A
	db PAT_END
Pattern_5397:
	db LEN10, C4, REST, C4, L4, REST, LEN10, REST, REST, G3, L16, C4, REST, C4, REST, REST
	db REST, PAT_END
; unreferenced
Pattern_53A9:
	db LEN10, D4, REST, D4, REST, REST, D4, REST, REST, A3, C4, D4, REST, LEN10, D4, REST
	db D4, REST, REST, REST, A4, REST, G4, F4, D4, REST, PAT_END
; unreferenced
Pattern_53C4:
	db LEN10, D4, REST, D4, REST, REST, REST, C5, REST, L16, A4, REST, A4, REST, LEN10, F4
	db REST, PAT_END
Pattern_53D6:
	db LEN10, G5, REST, REST, C6, REST, REST, L4, B5, LEN10, C6, REST, G5, LEN10, REST, REST
	db G5, C6, REST, REST, L4, B5, LEN10, C6, REST, REST, PAT_END
; unreferenced
Pattern_53F1:
	db LEN10, G6, REST, REST, G6, REST, REST, F6, REST, E6, REST, REST, D6, LEN10, REST, REST
	db L4, C6, LEN10, REST, B5, REST, REST, A5, REST, REST, PAT_END
Pattern_540C:
	db LEN10, C5, C5, C5, REST, REST, C5, REST, REST, C5, REST, C5, REST, PAT_END
; unreferenced
Pattern_541A:
	db LEN10, G5, G5, G5, G5, REST, REST, F5, REST, E5, REST, REST, D5, LEN10, REST, REST
	db C5, REST, REST, REST, B4, REST, REST, A4, REST, REST, PAT_END
Pattern_5435:
	db LEN10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, LEN10, NOISE_0B, NOISE_10
	db NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, LEN10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10
	db NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_15, LEN10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_10
	db NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, PAT_END
DrumKit_546A:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $82, $00, $40, $02, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $51, $00, $39, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $31, $00, $39, $05, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $66, $00, $13, $10, $c0	; $15: NR42, -, NR41, NR43, NR44
; unreferenced length table
Unused_5484:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $00
Song0F_Header:
	SONG $00, LengthTable_54A3, Song0F_Ch1, Song0F_Ch2, Song0E_Ch3, Song0F_Ch4
; unreferenced
Unused_549E:
	db $00, $00, $00, $00, $00
LengthTable_54A3:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $00
Song0F_Ch4:
	dw Pattern_5504
Song0F_Ch4_Loop:
	dw Pattern_551F
	LIST_LOOP Song0F_Ch4_Loop
Song0F_Ch1:
	dw Pattern_54F6
Song0F_Ch1_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_5508
	dw Pattern_5508
	dw Pattern_5508
	dw Pattern_550E
	LIST_TRANSPOSE_ADD 2
	dw Pattern_5508
	dw Pattern_5508
	dw Pattern_5508
	dw Pattern_550E
	LIST_LOOP Song0F_Ch1_Loop
Song0F_Ch2:
	dw Pattern_54FD
Song0F_Ch2_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_5514
	dw Pattern_5514
	dw Pattern_5514
	dw Pattern_5514
	LIST_TRANSPOSE_ADD 2
	dw Pattern_5514
	dw Pattern_5514
	dw Pattern_5514
	dw Pattern_5514
	LIST_LOOP Song0F_Ch2_Loop
Pattern_54F6:
	INSTR $52, $00, $00
	REST_ENV $32
	db PAT_END
Pattern_54FD:
	INSTR $43, $00, $40
	REST_ENV $22
	db PAT_END
Pattern_5504:
	DRUMKIT DrumKit_5534
	db PAT_END
Pattern_5508:
	db L8, C5, E5, F5, G5, PAT_END
Pattern_550E:
	db L8, F5, E5, F5, G5, PAT_END
Pattern_5514:
	db L16, C4, G4, C5, G5, L16, G4, C5, G5, C6, PAT_END
Pattern_551F:
	db L8, NOISE_06, NOISE_06, NOISE_06, NOISE_0B, L8, NOISE_0B, NOISE_0B, NOISE_10, NOISE_10, L8, NOISE_10, NOISE_15, NOISE_15, NOISE_15, L8
	db NOISE_15, NOISE_15, NOISE_15, NOISE_15, PAT_END
DrumKit_5534:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $66, $00, $2b, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $56, $00, $2b, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $46, $00, $2b, $05, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $36, $00, $2b, $05, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $26, $00, $2b, $05, $c0	; $1a: NR42, -, NR41, NR43, NR44
; hurry-mode length table of song $0d
Song0D_HurryLengths:
	db $00, $03, $07, $0e, $1c, $00, $00, $15, $2a, $54, $00, $00, $00, $01, $2a
Song0D_Header:
	SONG $00, LengthTable_556D, Song0D_Ch1, Song0D_Ch2, Song0D_Ch3, Song0D_Ch4
LengthTable_556D:
	db $00, $04, $09, $12, $24, $00, $00, $1b, $36, $6c, $00, $00, $00, $01, $36
Song0D_Ch3:
	dw Pattern_562B
Song0D_Ch3_Loop:
	dw Pattern_5882
	dw Pattern_588F
	dw Pattern_5882
	dw Pattern_589C
	dw Pattern_58AB
	dw Pattern_58B6
	dw Pattern_58C1
	dw Pattern_58CC
	dw Pattern_58AB
	dw Pattern_58B6
	dw Pattern_58DB
	dw Pattern_58EA
	dw Pattern_58F5
	dw Pattern_58F5
	dw Pattern_590A
	dw Pattern_591F
	LIST_LOOP Song0D_Ch3_Loop
Song0D_Ch4:
	dw Pattern_5938
	LIST_LOOP Song0D_Ch4
Song0D_Ch1:
	dw Pattern_55FA
	dw Pattern_5630
	dw Pattern_5649
	dw Pattern_5630
	dw Pattern_565F
Song0D_Ch1_Loop:
	dw Pattern_5608
	dw Pattern_5699
	dw Pattern_56AC
	dw Pattern_5699
	dw Pattern_56BD
	dw Pattern_560F
	dw Pattern_56C9
	dw Pattern_5616
	dw Pattern_56EB
	dw Pattern_570A
	dw Pattern_561D
	dw Pattern_5747
	dw Pattern_570A
	LIST_LOOP Song0D_Ch1_Loop
Song0D_Ch2:
	dw Pattern_55FA
	dw Pattern_5760
	dw Pattern_578C
	dw Pattern_5760
	dw Pattern_5794
Song0D_Ch2_Loop:
	dw Pattern_5608
	dw Pattern_57BB
	dw Pattern_57CF
	dw Pattern_57BB
	dw Pattern_57E3
	dw Pattern_5601
	dw Pattern_57EF
	dw Pattern_57EF
	dw Pattern_5624
	dw Pattern_57FC
	dw Pattern_581B
	dw Pattern_561D
	dw Pattern_5842
	dw Pattern_585B
	LIST_LOOP Song0D_Ch2_Loop
Pattern_55FA:
	INSTR $63, $00, $80
	REST_ENV $17
	db PAT_END
Pattern_5601:
	INSTR $53, $00, $80
	REST_ENV $27
	db PAT_END
Pattern_5608:
	INSTR_ENV Envelope_5947, $81
	REST_ENV $37
	db PAT_END
Pattern_560F:
	INSTR $63, $00, $00
	REST_ENV $27
	db PAT_END
Pattern_5616:
	INSTR $53, $00, $00
	REST_ENV $27
	db PAT_END
Pattern_561D:
	INSTR $56, $00, $40
	REST_ENV $27
	db PAT_END
Pattern_5624:
	INSTR $66, $00, $40
	REST_ENV $27
	db PAT_END
Pattern_562B:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_5630:
	db L4, REST, L16, B5, REST, LEN13, REST, L16, B5, REST, LEN13, REST, L16, B5, REST, LEN13
	db REST, L4D, REST, L8, B5, REST, B5, REST, PAT_END
Pattern_5649:
	db L4, REST, L16, C6, REST, LEN13, REST, L16, C6, REST, LEN13, REST, L8, A5, REST, REST
	db REST, A5, REST, B5, REST, PAT_END
Pattern_565F:
	db L4, REST, L16, C6, REST, LEN13, REST, L16, C6, REST, LEN13, REST, L8, A5, REST
	INSTR $52, $00, $00
	REST_ENV $17
	db L8, G6
	INSTR $42, $00, $00
	db L8, G6
	INSTR $62, $00, $00
	db L8, G6
	INSTR $52, $00, $00
	db L8, G6
	INSTR $72, $00, $00
	db L8, G6
	INSTR $62, $00, $00
	db L8, G6
	INSTR $82, $00, $00
	db PAT_END
Pattern_5699:
	db L4D, E6, L8, F6, E6, F6, G6, REST, L4D, C7, L8, REST, L2, B6, L4, A6
	db L2D, A6, PAT_END
Pattern_56AC:
	db L4, REST, L8, D6, E6, D6, E6, F6, REST, L4D, B6, L8, A6, L1D, G6, D6
	db PAT_END
Pattern_56BD:
	db L4, C7, As6, Gs6, C7, L4D, As6, L8, C7, LEN9, G6, PAT_END
Pattern_56C9:
	db L2, D6, L8, D6, E6, L4, F6, D6, F6, L2, E6, L8, E6, F6, L4, G6
	db F6, E6, L4, D6, D6, L8, D6, E6, L4, F6, D6, F6, G6, E6, G6, L2D
	db C7, PAT_END
Pattern_56EB:
	db L2, D7, L8, C7, As6, L4, A6, As6, C7, L2, G6, L8, E6, F6, L4, G6
	db E6, F6, L2, E6, L8, D6, E6, L2, D6, L8, C6, D6, L2D, D6, PAT_END
Pattern_570A:
	INSTR $33, $00, $80
	REST_ENV $17
	db L16, G6, REST, LEN13, REST
	INSTR $43, $00, $80
	db L16, G6, REST, LEN13, REST
	INSTR $53, $00, $80
	db L16, G6, REST, LEN13, REST
	INSTR $63, $00, $80
	db L16, G6, REST, LEN13, REST
	INSTR $73, $00, $80
	db L16, G6, REST, LEN13, REST
	INSTR $83, $00, $80
	db L16, G6, REST, LEN13, REST
	INSTR $93, $00, $80
	db PAT_END
Pattern_5747:
	REPEAT $06
	db L8, B5, G5
	REPEAT_END
	REPEAT $06
	db L8, C6, A5
	REPEAT_END
	REPEAT $06
	db L8, B5, G5
	REPEAT_END
	REPEAT $03
	db L8, C6, A5
	REPEAT_END
	db PAT_END
Pattern_5760:
	db L4, REST, L16, G5, REST, LEN13, REST, L16, G5, REST, LEN13, REST, L16, G5, REST, LEN13
	db REST, L4D, REST, L8, G5, REST, G5, REST, REST, REST, L16, F5, REST, LEN13, REST, L16
	db F5, REST, LEN13, REST, L16, F5, REST, LEN13, REST, L8, REST, PAT_END
Pattern_578C:
	db L4, REST, L8, E5, REST, D5, REST, PAT_END
Pattern_5794:
	INSTR $62, $00, $00
	REST_ENV $17
	db L8, G6
	INSTR $52, $00, $00
	db L8, Fs6
	INSTR $72, $00, $00
	db L8, F6
	INSTR $62, $00, $00
	db L8, E6
	INSTR $82, $00, $00
	db L8, Ds6
	INSTR $72, $00, $00
	db L8, D6, PAT_END
Pattern_57BB:
	db L4D, C6, L8, D6, C6, D6, E6, REST, L4D, E6, L8, REST, L2, D6, L8, C6
	db REST, L2D, C6, PAT_END
Pattern_57CF:
	db L4, REST, L8, B5, C6, B5, C6, D6, REST, L4D, G6, L8, F6, L1D, E6, L4
	db B5, A5, G5, PAT_END
Pattern_57E3:
	db L4, Gs6, G6, F6, Gs6, L4D, G6, L8, Gs6, LEN9, E6, PAT_END
Pattern_57EF:
	REPEAT $06
	db L8, F4, D4
	REPEAT_END
	REPEAT $06
	db L8, G4, E4
	REPEAT_END
	db PAT_END
Pattern_57FC:
	db L2, D6, L8, C6, As5, L4, A5, As5, C6, L2, G5, L8, E5, F5, L4, G5
	db E5, F5, L2, E5, L8, D5, E5, L2, D5, L8, C5, D5, L2D, D5, PAT_END
Pattern_581B:
	INSTR $52, $00, $00
	REST_ENV $17
	db L8, G5
	INSTR $42, $00, $00
	db L8, Fs5
	INSTR $62, $00, $00
	db L8, F5
	INSTR $52, $00, $00
	db L8, E5
	INSTR $72, $00, $00
	db L8, Ds5
	INSTR $62, $00, $00
	db L8, D5, PAT_END
Pattern_5842:
	REPEAT $06
	db L8, G4, E4
	REPEAT_END
	REPEAT $06
	db L8, A4, F4
	REPEAT_END
	REPEAT $06
	db L8, G4, E4
	REPEAT_END
	REPEAT $03
	db L8, A4, F4
	REPEAT_END
	db PAT_END
Pattern_585B:
	INSTR $42, $00, $00
	REST_ENV $17
	db L8, G5
	INSTR $32, $00, $00
	db L8, Fs5
	INSTR $52, $00, $00
	db L8, F5
	INSTR $42, $00, $00
	db L8, E5
	INSTR $62, $00, $00
	db L8, Ds5
	INSTR $52, $00, $00
	db L8, D5, PAT_END
Pattern_5882:
	db L8, C4, G4, D5, D5, C5, REST, C4, G4, L4, D5, C5, PAT_END
Pattern_588F:
	db L8, D4, A4, E5, E5, D5, REST, G3, D4, L4, G4, G4, PAT_END
Pattern_589C:
	db L8, D4, A4, E5, E5, L4, D5, L8, G4, G4, G4, G4, A4, B4, PAT_END
Pattern_58AB:
	REPEAT $02
	db L8, C4, G4, D5, E5, C5, REST
	REPEAT_END
	db PAT_END
Pattern_58B6:
	REPEAT $02
	db L8, F3, C4, G4, A4, F4, REST
	REPEAT_END
	db PAT_END
Pattern_58C1:
	REPEAT $02
	db L8, G3, D4, A4, B4, G4, REST
	REPEAT_END
	db PAT_END
Pattern_58CC:
	db L8, C4, G4, D5, E5, C5, REST, L8, G4, G5, G5, G4, G5, G5, PAT_END
Pattern_58DB:
	db L8, Gs3, Gs3, Gs4, Gs3, Gs4, Ds3, L8, As3, As3, As4, As3, As4, F3, PAT_END
Pattern_58EA:
	REPEAT $02
	db L8, C3, G3, D4, E4, C4, REST
	REPEAT_END
	db PAT_END
Pattern_58F5:
	REPEAT $02
	db L8, As3, F4, D5, As4, D5, As4
	REPEAT_END
	REPEAT $02
	db L8, C4, G4, E5, C5, E5, C5
	REPEAT_END
	db PAT_END
Pattern_590A:
	REPEAT $02
	db L8, As2, F3, D4, As3, D4, As3
	REPEAT_END
	REPEAT $02
	db L8, C3, G3, E4, C4, E4, C4
	REPEAT_END
	db PAT_END
Pattern_591F:
	REPEAT $02
	db L8, D3, A3, F4, D4, A4, F4
	REPEAT_END
	db L8, G3, D4, B4, G4, B4, F4, L8, G3, G3, G3, G3, A3, B3, PAT_END
Pattern_5938:
	db L8, NOISE_3D, NOISE_79, NOISE_3D, NOISE_3D, NOISE_3D, NOISE_79, L8, NOISE_3D, NOISE_3D, NOISE_3D, NOISE_79, NOISE_3D, NOISE_79, PAT_END
Envelope_5947:
	db $49, $00, $00, $58, $28, $00, $00, $00, $00, $00, $28, $00, $00, $38, $00, $00
	db $38, $00, $00, $48, $00, $00, $58, $00, $00, $68, $00, $00, $68, $00, $00, $78
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
; unreferenced length table
Unused_5977:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $28
; hurry-mode length table of song $0c
Song0C_HurryLengths:
	db $02, $04, $08, $10, $20, $40, $00, $18, $30, $00, $00, $00, $00, $00, $28
Song0C_Header:
	SONG $00, LengthTable_59A0, Song0C_Ch1, Song0C_Ch2, Song0C_Ch3, Song0C_Ch4
LengthTable_59A0:
	db $03, $06, $0c, $18, $30, $60, $00, $24, $48, $00, $00, $00, $00, $00, $3c
Song0C_Ch3:
	dw Pattern_5A09
Song0C_Ch3_Loop:
	dw Pattern_5B2D
	dw Pattern_5BB4
	LIST_LOOP Song0C_Ch3_Loop
Song0C_Ch4:
	dw Pattern_5C59
Song0C_Ch4_Loop:
	dw Pattern_5C47
	LIST_LOOP Song0C_Ch4_Loop
Song0C_Ch1:
	dw Pattern_59FD
Song0C_Ch1_Loop:
	dw Pattern_5A0E
	dw Pattern_5A20
	dw Pattern_5A31
	dw Pattern_5A3C
	dw Pattern_5A0E
	dw Pattern_5A20
	dw Pattern_5A31
	dw Pattern_5A43
	dw Pattern_5A4A
	dw Pattern_5A61
	dw Pattern_5A4A
	dw Pattern_5A7A
	LIST_LOOP Song0C_Ch1_Loop
Song0C_Ch2:
	dw Pattern_5A02
Song0C_Ch2_Loop:
	dw Pattern_5AAA
	dw Pattern_5ABC
	dw Pattern_5A31
	dw Pattern_5A3C
	dw Pattern_5AAA
	dw Pattern_5ABC
	dw Pattern_5A31
	dw Pattern_5A43
	dw Pattern_5ACD
	dw Pattern_5AE4
	dw Pattern_5ACD
	dw Pattern_5AFD
	LIST_LOOP Song0C_Ch2_Loop
Pattern_59FD:
	INSTR $65, $00, $80
	db PAT_END
Pattern_5A02:
	INSTR $46, $00, $83
	db L32, REST, PAT_END
Pattern_5A09:
	INSTR_WAVE Wave_6D56, $20
	db PAT_END
Pattern_5A0E:
	INSTR $65, $00, $40
	db L8, REST, L16, Fs5, G5, L4, A5, L8, Fs5, L4, A5, L8, Cs6, PAT_END
Pattern_5A20:
	db L8, REST
	INSTR $68, $00, $40
	db L4, D6
	INSTR $65, $00, $40
	db L2, D6, L8, Fs5, PAT_END
Pattern_5A31:
	db L8, G5, A5, L4, G5, L8, Fs5, L4, G5, A5, PAT_END
Pattern_5A3C:
	db L4, B5, L8, A5, L2, A5, PAT_END
Pattern_5A43:
	db L4, B5, L8, Cs6, L2, Cs6, PAT_END
Pattern_5A4A:
	INSTR $65, $00, $80
	db L8, B5, Cs6, D6, Cs6, D6, L4, A5, L8, G6, L8, Fs6, L4, E6, L8, D6
	db L2, D6, PAT_END
Pattern_5A61:
	db L8, B5, Cs6, D6, Cs6, D6, L4, E6, L8, D6, L8, E6
	INSTR $68, $00, $80
	db L4, Fs6
	INSTR $65, $00, $80
	db L1D, Fs6, PAT_END
Pattern_5A7A:
	db L8, B5, Cs6, D6, Cs6, D6, L4, E6, L8, D6, L8, E6, L4, F6, L8, E6
	db F6, G6, A6, G6, L8, F6, E6
	INSTR $68, $00, $80
	db L4D, D6
	INSTR $65, $00, $80
	db L1D, D6
	INSTR $68, $00, $80
	db L4, Cs6
	INSTR $65, $00, $80
	db L2, Cs6, PAT_END
Pattern_5AAA:
	INSTR $46, $00, $43
	db L8, REST, L16, Fs5, G5, L4, A5, L8, Fs5, L4, A5, L8, Cs6, PAT_END
Pattern_5ABC:
	db L8, REST
	INSTR $48, $00, $43
	db L4, D6
	INSTR $46, $00, $43
	db L2, D6, L8, Fs5, PAT_END
Pattern_5ACD:
	INSTR $46, $00, $83
	db L8, B5, Cs6, D6, Cs6, D6, L4, A5, L8, G6, L8, Fs6, L4, E6, L8, D6
	db L2, D6, PAT_END
Pattern_5AE4:
	db L8, B5, Cs6, D6, Cs6, D6, L4, E6, L8, D6, L8, E6
	INSTR $48, $00, $83
	db L4, Fs6
	INSTR $46, $00, $83
	db L1D, Fs6, PAT_END
Pattern_5AFD:
	db L8, B5, Cs6, D6, Cs6, D6, L4, E6, L8, D6, L8, E6, L4, F6, L8, E6
	db F6, G6, A6, G6, L8, F6, E6
	INSTR $48, $00, $83
	db L4D, D6
	INSTR $46, $00, $83
	db L1D, D6
	INSTR $48, $00, $83
	db L4, Cs6
	INSTR $46, $00, $83
	db L2, Cs6, PAT_END
Pattern_5B2D:
	db L4, REST, L16, D3, REST, D3, REST, L8, D4, D3, L16, Cs3, REST, Cs3, REST, L8
	db A3, D4, L16, D3, REST, D3, REST, L8, D4, A2, L16, D3, REST, L8, D4, L16
	db Fs3, REST, L8, Fs4, L16, G3, REST, G3, REST, L8, G4, D3, L16, G3, REST, G3
	db REST, L8, G4, D3, L16, G3, REST, L8, D4, L16, Fs3, REST, L8, Fs4, L16, A3
	db REST, L8, A4, L4, REST, L16, D3, REST, D3, REST, L8, D4, D3, L16, Cs3, REST
	db Cs3, REST, L8, A3, D4, L16, D3, REST, D3, REST, L8, D4, A2, L16, D3, REST
	db L8, D4, L16, Fs3, REST, L8, Fs4, L16, G3, REST, G3, REST, L8, G4, D3, L16
	db G3, REST, G3, REST, L8, G4, D3, L16, G3, REST, L8, D4, L16, E3, REST, L8
	db Cs4, L16, A2, REST, L8, A3, PAT_END
Pattern_5BB4:
	db L4, REST, L16, D3, REST, D3, REST, L8, A3, D3, L16, Cs3, REST, Cs3, REST, L8
	db Cs4, Cs3, L16, D3, REST, D3, REST, L8, A3, L16, D3, REST, D3, REST, L8, A3
	db L16, B2, REST, L8, B3, D3, Fs3, A3, D4, E3, A3, L8, Cs4, L16, D3, REST
	db D3, REST, D3, REST, D3, REST, D3, REST, D3, REST, D3, REST, L4, REST, L16, D3
	db REST, D3, REST, L8, A3, D3, L16, Cs3, REST, Cs3, REST, L8, Cs4, Cs3, L16, D3
	db REST, D3, REST, L8, D4, L16, D3, REST, D3, REST, L8, A3, L16, B2, REST, L8
	db B3, D3, Fs3, A3, D4, E3, A3, L8, E4, F3, A3, C4, F4, A4, C5, A4
	db L8, F4, A3, L16, D4, REST, D4, REST, D4, REST, D4, REST, D4, REST, D4, REST
	db L16, D4, REST, D4, REST, L16, A4, REST, A4, REST, Cs5, REST, Cs5, REST, E5, REST
	db E5, REST, PAT_END
Pattern_5C47:
	db L16, NOISE_2E, REST, REST, REST, NOISE_06, REST, REST, REST, NOISE_2E, REST, NOISE_2E, REST, NOISE_06, REST, REST
	db REST, PAT_END
Pattern_5C59:
	db L8, REST, REST, PAT_END
; hurry-mode length table of song $0b
Song0B_HurryLengths:
	db $02, $04, $08, $10, $20, $40, $00, $00, $30, $00, $00, $00, $00, $00, $00
Song0B_Header:
	SONG $00, LengthTable_5C77, Song0B_Ch1, Song0B_Ch2, Song0B_Ch3, Song0B_Ch4
LengthTable_5C77:
	db $03, $06, $0c, $18, $30, $60, $00, $00, $48, $00, $00, $00, $00, $00, $00
Song0B_Ch3:
	dw Pattern_5CB5
Song0B_Ch3_Loop:
	dw Pattern_5CF3
	LIST_LOOP Song0B_Ch3_Loop
Song0B_Ch4:
	dw Pattern_5CBA
	LIST_LOOP Song0B_Ch4
Song0B_Ch1:
	dw Pattern_5CA4
Song0B_Ch1_Loop:
	dw Pattern_5CCC
	LIST_LOOP Song0B_Ch1_Loop
Song0B_Ch2:
	dw Pattern_5CAB
Song0B_Ch2_Loop:
	dw Pattern_5CCC
	LIST_LOOP Song0B_Ch2_Loop
Pattern_5CA4:
	INSTR $66, $00, $40
	REST_ENV $32
	db PAT_END
Pattern_5CAB:
	INSTR $47, $00, $43
	REST_ENV $32
	db L32, REST, REST, PAT_END
Pattern_5CB5:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_5CBA:
	db L16, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_06, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_06, NOISE_29, NOISE_29
	db NOISE_29, PAT_END
Pattern_5CCC:
	db L8, E5, E5, G5, L4, F5, L8, F5, A5, L4, G5, L8, G5, B5, L4, C6
	db L8, G5, E5, G5, L8, F5, E5, F5, L4, G5, L8, F5, G5, L4, A5, L8
	db G5, F5, E5, L4, E5, D5, PAT_END
Pattern_5CF3:
	db L16, C3, C3, C4, C3, G3, C4, F3, F3, F4, F3, C4, F4, F3, F4, G3
	db G4, L16, G3, G4, D4, G3, G4, G3, C4, G4, C4, G3, G4, C3, E3, E4
	db G3, G4, L16, F3, F3, F4, F3, C4, F4, G3, G3, G4, G3, D4, G4, G3
	db G4, A3, A3, L16, A4, A3, D4, A4, A3, A4, A3, A4, C4, G4, C5, E3
	db G3, B3, D4, G4, PAT_END
; hurry-mode length table of song $0a
Song0A_HurryLengths:
	db $03, $06, $0c, $18, $30, $60, $00, $00, $48, $00, $00, $00, $00, $00, $00
Song0A_Header:
	SONG $00, LengthTable_5D52, Song0A_Ch1, Song0A_Ch2, Song0A_Ch3, Song0A_Ch4
LengthTable_5D52:
	db $04, $08, $10, $20, $40, $80, $00, $00, $60, $00, $00, $00, $00, $00, $00
Song0A_Ch3:
	dw Pattern_5D90
Song0A_Ch3_Loop:
	dw Pattern_5DEC
	LIST_LOOP Song0A_Ch3_Loop
Song0A_Ch4:
	dw Pattern_5D95
	LIST_LOOP Song0A_Ch4
Song0A_Ch1:
	dw Pattern_5D7F
Song0A_Ch1_Loop:
	dw Pattern_5DA7
	LIST_LOOP Song0A_Ch1_Loop
Song0A_Ch2:
	dw Pattern_5D86
Song0A_Ch2_Loop:
	dw Pattern_5DA7
	LIST_LOOP Song0A_Ch2_Loop
Pattern_5D7F:
	INSTR $66, $00, $40
	REST_ENV $32
	db PAT_END
Pattern_5D86:
	INSTR $47, $00, $43
	REST_ENV $32
	db L32, REST, REST, PAT_END
Pattern_5D90:
	INSTR_WAVE Wave_6D56, $60
	db PAT_END
Pattern_5D95:
	db L16, NOISE_0B, REST, REST, NOISE_0B, NOISE_06, REST, NOISE_0B, NOISE_0B, REST, NOISE_0B, REST, NOISE_0B, NOISE_06, REST, NOISE_0B
	db NOISE_0B, PAT_END
Pattern_5DA7:
	db L16, E6, REST, REST, C6, REST, REST, G5, REST, REST, E6, REST, C6, G5, E5, C5
	db REST, L16, F6, REST, REST, C6, REST, REST, A5, REST, REST, B5, REST, B5, C6, C6
	db D6, REST, L16, D6, REST, REST, B5, REST, REST, G5, REST, REST, D6, REST, B5, G5
	db D5, B4, REST, L16, C6, REST, REST, E6, REST, REST, REST, REST, REST, G6, REST, G6
	db A6, A6, B6, REST, PAT_END
Pattern_5DEC:
	db L32, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6, E7
	db E6, L32, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6, E7, E6
	db E7, E6, L32, F7, F6, F7, F6, F7, F6, F7, F6, F7, F6, F7, F6, F7
	db F6, F7, F6, L32, F7, F6, F7, F6, F7, F6, F7, F6, F7, F6, F7, F6
	db F7, F6, F7, F6, L32, G7, G6, G7, G6, G7, G6, G7, G6, G7, G6, G7
	db G6, G7, G6, G7, G6, L32, G7, G6, G7, G6, G7, G6, G7, G6, G7, G6
	db G7, G6, G7, G6, G7, G6, L32, C7, C6, C7, C6, C7, C6, C7, C6, C7
	db C6, C7, C6, C7, C6, C7, C6, L32, D7, D6, D7, D6, D7, D6, D7, D6
	db D7, D6, D7, D6, D7, D6, D7, D6, PAT_END
; hurry-mode length table of song $09
Song09_HurryLengths:
	db $03, $06, $0c, $18, $30, $60, $00, $00, $48, $00, $00, $00, $00, $00, $00
Song09_Header:
	SONG $00, LengthTable_5E8F, Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
LengthTable_5E8F:
	db $04, $08, $10, $20, $40, $80, $00, $00, $60, $00, $00, $00, $00, $00, $00
Song09_Ch3:
	dw Pattern_5EEA
Song09_Ch3_Loop:
	dw Pattern_6022
	LIST_LOOP Song09_Ch3_Loop
Song09_Ch4:
	dw Pattern_5F9D
	dw Pattern_5F9D
	dw Pattern_5F9D
	dw Pattern_5FAF
	dw Pattern_5F9D
	dw Pattern_5F9D
	dw Pattern_5FC2
	dw Pattern_5FD4
	dw Pattern_5FE9
	dw Pattern_5FE9
	dw Pattern_5F9D
	dw Pattern_5F9D
	dw Pattern_5FE9
	dw Pattern_5FE9
	dw Pattern_5FFD
	dw Pattern_600F
	LIST_LOOP Song09_Ch4
Song09_Ch2:
	dw Pattern_5EEF
Song09_Ch2_Loop:
	dw Pattern_5EFD
	dw Pattern_5EFD
	dw Pattern_5F0C
	dw Pattern_5F1E
	dw Pattern_5F3B
	LIST_LOOP Song09_Ch2_Loop
Song09_Ch1:
	dw Pattern_5EF6
Song09_Ch1_Loop:
	dw Pattern_5F4D
	dw Pattern_5F4D
	dw Pattern_5F5C
	dw Pattern_5F6E
	dw Pattern_5F8B
	LIST_LOOP Song09_Ch1_Loop
Pattern_5EEA:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_5EEF:
	INSTR $a1, $00, $40
	REST_ENV $32
	db PAT_END
Pattern_5EF6:
	INSTR $a1, $00, $40
	REST_ENV $32
	db PAT_END
Pattern_5EFD:
	db L2D, REST, L16, As5, REST, REST, As5, L2D, REST, L16, As5, As5, REST, As5, PAT_END
Pattern_5F0C:
	db L2D, REST, L16, F5, A5, REST, REST, L2D, REST, L16, REST, REST, Ds6, Ds6, L1, REST
	db REST, PAT_END
Pattern_5F1E:
	db L2D, REST, L16, REST, REST, Ds6, Ds6, L2D, REST, L16, REST, REST, F6, F6, L2D, REST
	db L16, REST, REST, As5, As5, L2D, REST, L16, As5, As5, REST, As5, PAT_END
Pattern_5F3B:
	db L2D, REST, L16, F5, A5, REST, REST, L2D, REST, L16, REST, REST, F6, F6, L1, REST
	db REST, PAT_END
Pattern_5F4D:
	db L2D, REST, L16, C5, REST, REST, C5, L2D, REST, L16, C5, C5, REST, C5, PAT_END
Pattern_5F5C:
	db L2D, REST, L16, REST, REST, F4, Fs4, L2D, REST, L16, REST, REST, F5, F5, L1, REST
	db REST, PAT_END
Pattern_5F6E:
	db L2D, REST, L16, REST, REST, F5, F5, L2D, REST, L16, REST, REST, G5, G5, L2D, REST
	db L16, REST, REST, C5, C5, L2D, REST, L16, C5, C5, REST, C5, PAT_END
Pattern_5F8B:
	db L2D, REST, L16, REST, REST, F4, Fs4, L2D, REST, L16, REST, REST, G5, G5, L1, REST
	db REST, PAT_END
Pattern_5F9D:
	db L16, NOISE_29, NOISE_29, REST, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, L8
	db NOISE_10, PAT_END
Pattern_5FAF:
	db L16, NOISE_29, NOISE_29, REST, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29, NOISE_29
	db L8, NOISE_10, PAT_END
Pattern_5FC2:
	db L16, NOISE_29, NOISE_29, REST, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_47, REST, NOISE_47
	db NOISE_47, PAT_END
Pattern_5FD4:
	db L16, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29, NOISE_29, L8, NOISE_10, L16
	db NOISE_29, NOISE_29, L8, NOISE_10, PAT_END
Pattern_5FE9:
	db L16, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29
	db NOISE_29, L8, NOISE_10, PAT_END
Pattern_5FFD:
	db L16, NOISE_29, NOISE_29, REST, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_47, NOISE_47, REST
	db NOISE_47, PAT_END
Pattern_600F:
	db L16, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L8, NOISE_10, L16, NOISE_29, NOISE_29, REST, NOISE_29, REST, REST
	db NOISE_29, NOISE_29, PAT_END
Pattern_6022:
	db L16, C4, REST, REST, L32, C4, REST, L8, C5, G4, A4, As4, G4, E4, L16, C4
	db REST, L32, C4, REST, C4, REST, L8, C5, G4, A4, As4, G4, E4, L16, C4, REST
	db REST, L32, C4, REST, L8, C5, G4, A4, As4, G4, E4, L16, C4, REST, L32, C4
	db REST, C4, REST, L8, C5, G4, A4, As4, G4, E4, L8, F4, L16, REST, L32, F4
	db REST, L8, F5, C5, D5, Ds5, C5, A4, L16, F4, REST, L32, F4, REST, F4, REST
	db L8, F5, C5, D5, Ds5, C5, A4, L16, C4, REST, REST, L32, C4, REST, L8, C5
	db G4, A4, As4, G4, E4, L32, C4, REST, C5, REST, REST, REST, C3, REST, E4, REST
	db E5, REST, REST, REST, E3, REST, F4, REST, F5, REST, REST, REST, F3, REST, G4, REST
	db G5, REST, REST, REST, G3, REST, L8, F4, L16, REST, L32, F4, REST, L8, F5, C5
	db D5, Ds5, C5, A4, L16, G4, REST, L32, G4, REST, G4, REST, L8, G5, D5, E5
	db F5, D5, B4, L16, C4, REST, REST, L32, C4, REST, L8, C5, G4, A4, As4, G4
	db E4, L16, C4, REST, L32, C4, REST, C4, REST, L8, C5, G4, A4, As4, G4, E4
	db L8, F4, L16, REST, L32, F4, REST, L8, F5, C5, D5, Ds5, C5, A4, L16, G4
	db REST, L32, G4, REST, G4, REST, L8, G5, D5, E5, F5, D5, B4, L16, C4, REST
	db REST, L32, C4, REST, L8, C5, G4, A4, As4, G4, E4, L16, C3, REST, L32, C5
	db REST, C3, REST, C3, REST, C5, REST, REST, REST, C3, REST, C5, REST, L16, REST, REST
	db REST, L4, REST, PAT_END
; hurry-mode length table of song $08
Song08_HurryLengths:
	db $00, $03, $00, $12, $24, $48, $00, $00, $36, $00, $06, $00, $0c, $00, $00
; songs $08, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f; 64 unreachable table entries ($40, $41, $42, $43, ...)
Song08_Header:
	SONG $00, LengthTable_6140, Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
LengthTable_6140:
	db $00, $04, $00, $18, $30, $60, $00, $00, $48, $00, $08, $00, $10, $00, $00
Song08_Ch1:
	dw Pattern_61D9
Song08_Ch1_Loop:
	dw Pattern_6289
	dw Pattern_62BB
	dw Pattern_6289
	dw Pattern_62D7
	dw Pattern_62EC
	dw Pattern_633B
	dw Pattern_62EC
	dw Pattern_6356
	LIST_LOOP Song08_Ch1_Loop
Song08_Ch2:
	dw Pattern_61E0
Song08_Ch2_Loop:
	dw Pattern_6371
	dw Pattern_63A3
	dw Pattern_6371
	dw Pattern_63C3
	dw Pattern_63E7
	dw Pattern_643C
	dw Pattern_63E7
	dw Pattern_61E0
	dw Pattern_6356
	LIST_LOOP Song08_Ch2_Loop
Song08_Ch3:
	dw Pattern_61E7
Song08_Ch3_Loop:
	dw Pattern_6457
	dw Pattern_64A1
	dw Pattern_6457
	dw Pattern_64B6
	dw Pattern_64CF
	dw Pattern_64F0
	dw Pattern_64CF
	dw Pattern_61E7
	dw Pattern_6503
	LIST_LOOP Song08_Ch3_Loop
Song08_Ch4:
	dw Pattern_61EC
	dw Pattern_61EC
	dw Pattern_61EC
	dw Pattern_61FA
	dw Pattern_61EC
	dw Pattern_6208
	dw Pattern_61FA
	dw Pattern_6216
	dw Pattern_61EC
	dw Pattern_61EC
	dw Pattern_61EC
	dw Pattern_61FA
	dw Pattern_61EC
	dw Pattern_6208
	dw Pattern_61FA
	dw Pattern_6224
	dw Pattern_6232
	dw Pattern_6240
	dw Pattern_6232
	dw Pattern_6240
	dw Pattern_624E
	dw Pattern_624E
	dw Pattern_625C
	dw Pattern_6224
	dw Pattern_6232
	dw Pattern_6240
	dw Pattern_6232
	dw Pattern_6240
	dw Pattern_624E
	dw Pattern_626A
	dw Pattern_624E
	dw Pattern_627B
	LIST_LOOP Song08_Ch4
Pattern_61D9:
	INSTR $76, $00, $81
	REST_ENV $34
	db PAT_END
Pattern_61E0:
	INSTR $57, $00, $83
	REST_ENV $34
	db PAT_END
Pattern_61E7:
	INSTR_WAVE Wave_6D66, $40
	db PAT_END
Pattern_61EC:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, REST, PAT_END
Pattern_61FA:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_29, PAT_END
Pattern_6208:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_6216:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, REST, REST, NOISE_29, NOISE_29, NOISE_29, REST, PAT_END
Pattern_6224:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_6232:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, REST, PAT_END
Pattern_6240:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_624E:
	db LEN10, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_625C:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_29, REST, NOISE_29, PAT_END
Pattern_626A:
	db LEN10, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L16, NOISE_29, NOISE_29, LEN10, NOISE_29, NOISE_29
	db PAT_END
Pattern_627B:
	db LEN10, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_29, PAT_END
Pattern_6289:
	db L4, REST, L2, D6, L4, G6, LEN10, D6, REST, REST, L4, REST, LEN10, REST, REST, D6
	db L4, REST, L4, REST, E6, LEN12, E6, LEN10, C6, L4, D6, LEN10, E6, REST, REST, L4
	db REST, LEN10, REST, REST, A6, L4, REST, L4, REST, Fs6, LEN10, REST, REST, Fs6, G6, REST
	db Fs6, PAT_END
Pattern_62BB:
	db LEN10, Fs6, REST, Fs6, L4, D6, E6, Fs6, L4, REST, G6, LEN10, G6, REST, G6, LEN12
	db A6, LEN10, B6, L2, REST, LEN10, REST, REST, D6, L4, REST, PAT_END
Pattern_62D7:
	db LEN10, Fs6, REST, Fs6, L4, D6, Fs6, A6, L4, REST, G6, LEN10, G6, REST, G6, Fs6
	db REST, F6, L1, F6, PAT_END
Pattern_62EC:
	db LEN10, E6, REST, E6, G6, REST, G6, C7, G6, C7, G6, C7, G6, LEN10, E6, REST
	db E6, G6, REST, G6, C7, G6, C7, G6, C7, E7, LEN10, D6, REST, D6, G6, REST
	db G6, B6, G6, B6, G6, B6, G6, LEN10, D6, REST, D6, G6, REST, G6, B6, G6
	db B6, G6, B6, D7, LEN10, C7, A6, C7, A6, Fs6, A6, Fs6, D6, Fs6, D6, A5
	db D6, LEN10, Fs6, D6, Fs6, A6, Fs6, A6, C7, A6, C7, E7, Fs7, E7, PAT_END
Pattern_633B:
	db LEN10, D7, REST, D7, Cs7, REST, Cs7, C7, REST, C7, B6, REST, B6, LEN10, A6, Gs6
	db A6, D6, Cs6, D6, E6, Ds6, E6, Fs6, E6, Fs6, PAT_END
Pattern_6356:
	db LEN10, D7, Cs7, C7, B6, As6, A6, Gs6, G6, Fs6, F6, E6, Ds6, LEN10, D6, Ds6
	db E6, F6, E6, Ds6, D6, A5, Fs5, D5, REST, REST, PAT_END
Pattern_6371:
	db L4, REST, L2, D6, L4, G6, LEN10, D6, REST, REST, B5, C6, Cs6, REST, REST, D6
	db L4, REST, L4, REST, E6, LEN12, E6, LEN10, C6, L4, D6, LEN10, E6, REST, REST, L4
	db REST, LEN10, REST, REST, A6, L4, REST, L4, REST, Fs6, LEN10, REST, REST, Fs6, G6, REST
	db Fs6, PAT_END
Pattern_63A3:
	db LEN10, Fs6, REST, Fs6, D5, Fs5, A5, Fs5, A5, D6, A5, D6, Fs6, L4, REST, G6
	db LEN10, G5, B5, D6, G6, REST, B6, L2, REST, LEN10, REST, REST, B5, L4, REST, PAT_END
Pattern_63C3:
	db LEN10, Fs6, REST, Fs6, Fs5, A5, D6, A5, D6, Fs6, D6, Fs6, A6, L4, REST, G6
	db LEN10, G5, B5, D6, Fs6, REST, REST, L4, REST, LEN10, D6, G6, D6, G6, B6, G6
	db B6, D7, B6, PAT_END
Pattern_63E7:
	INSTR $75, $00, $80
	REST_ENV $31
	db LEN10, E3, REST, E3, G3, REST, G3, C4, REST, C4, G3, G3, REST, LEN10, E3, REST
	db E3, G3, REST, G3, C4, REST, C4, G3, C4, E4, LEN10, D3, REST, D3, G3, REST
	db G3, B3, REST, B3, G3, G3, REST, LEN10, D3, REST, D3, G3, REST, G3, B3, REST
	db B3, G3, B3, D4, LEN10, C4, A3, C4, A3, Fs3, A3, Fs3, D3, Fs3, D3, A2
	db D3, LEN10, Fs3, D3, Fs3, A3, Fs3, A3, C4, A3, C4, A3, D4, E4, PAT_END
Pattern_643C:
	db LEN10, D4, REST, D4, Cs4, REST, Cs4, C4, REST, C4, B3, REST, B3, LEN10, A3, Fs3
	db A3, D3, Cs3, D3, E3, Ds3, E3, Fs3, E3, Fs3, PAT_END
Pattern_6457:
	db L4, REST, LEN10, D4, REST, REST, REST, REST, G4, D5, G4, D5, LEN10, D4, REST, REST
	db B4, C5, Cs5, REST, REST, D4, L4, REST, L4, REST, LEN10, E4, REST, REST, REST, REST
	db E4, C5, G4, E5, LEN10, E4, REST, REST, L4, REST, LEN10, REST, REST, A4, L4, REST
	db L4, REST, LEN10, Fs4, REST, REST, REST, REST, Fs4, G4, REST, Fs4, LEN10, Fs4, REST, Fs4
	db D4, REST, REST, E4, REST, REST, Fs4, REST, REST, PAT_END
Pattern_64A1:
	db L4, REST, LEN10, G4, REST, REST, G4, D5, D4, G4, REST, B4, L2, REST, LEN10, REST
	db REST, D4, L4, REST, PAT_END
Pattern_64B6:
	db L4, REST, LEN10, G4, REST, REST, D4, G4, D5, Fs4, REST, F4, L4, REST, LEN10, D4
	db G4, D4, G4, B4, G4, B4, D5, B4, PAT_END
Pattern_64CF:
	INSTR_WAVE Wave_6D56, $41
	db L2D, E5, L4, G5, L2D, C6, L4, E5, L2D, D5, L4, G5, L2D, B5, L4, D6
	db L2D, C6, L4, A5, L4, Fs5, A5, C6, LEN10, E6, Fs6, E6, PAT_END
Pattern_64F0:
	db LEN10, D6, REST, D6, Cs6, REST, Cs6, C6, REST, C6, B5, REST, B5, L4, A5, B5
	db C6, D6, PAT_END
Pattern_6503:
	db LEN10, Ds5, D5, Cs5, C5, B4, As4, A4, Gs4, G4, Fs4, F4, E4, LEN10, D4, Ds4
	db E4, F4, E4, Ds4, D4, A3, Fs3, D3, REST, REST, PAT_END
Song07_Header:
	SONG $00, LengthTable_6529, Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
LengthTable_6529:
	db $00, $00, $00, $15, $00, $00, $00, $00, $00, $00, $07, $03, $0e, $06, $23
Song07_Ch2:
	dw Pattern_654E
	dw Pattern_655D
	LIST_END
Song07_Ch1:
	dw Pattern_6553
	dw Pattern_6576
	LIST_END
Song07_Ch3:
	dw Pattern_6558
	dw Pattern_658F
	LIST_END
Song07_Ch4:
	dw Pattern_65A6
	LIST_END
Pattern_654E:
	INSTR $96, $00, $80
	db PAT_END
Pattern_6553:
	INSTR $76, $00, $83
	db PAT_END
Pattern_6558:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_655D:
	REST_ENV $27
	db LEN10, D6, REST, REST, A5, REST, Fs5, REST, REST, Fs5, A5, REST, D5, L4, REST, LEN10
	db REST, REST, D6, L4, D6, REST, PAT_END
Pattern_6576:
	REST_ENV $27
	db LEN10, Fs5, REST, A4, D5, REST, D5, Cs5, D5, Ds5, E5, REST, A4, REST, REST, REST
	db REST, REST, Fs5, L4, Fs5, REST, PAT_END
Pattern_658F:
	db LEN10, D5, REST, D5, Fs4, REST, Fs4, G4, REST, G4, Gs4, REST, Gs4, A4, A5, A4
	db A5, REST, D5, LEN12, D5, REST, PAT_END
Pattern_65A6:
	REPEAT $02
	db LEN10, NOISE_42, NOISE_42, NOISE_51, NOISE_42, NOISE_42, NOISE_42
	REPEAT_END
	db NOISE_51, NOISE_51, NOISE_42, NOISE_51, REST, LEN11, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42, NOISE_42
	db NOISE_42, NOISE_42, REST, PAT_END
; hurry-mode length table of song $06
Song06_HurryLengths:
	db $00, $04, $08, $10, $20, $00, $0c, $00, $1c, $04, $00, $05, $03, $02, $02
Song06_Header:
	SONG $00, LengthTable_65DE, Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
LengthTable_65DE:
	db $00, $05, $0a, $14, $28, $00, $0f, $00, $23, $05, $00, $07, $03, $03, $02
Song06_Ch2:
	dw Pattern_67CC
Song06_Ch2_Loop:
	dw Pattern_67EF
	dw Pattern_67EF
	dw Pattern_6826
	LIST_LOOP Song06_Ch2_Loop
Song06_Ch1:
	dw Pattern_6730
Song06_Ch1_Loop:
	dw Pattern_6753
	dw Pattern_6753
	dw Pattern_678A
	LIST_LOOP Song06_Ch1_Loop
Song06_Ch3:
	dw Pattern_661D
Song06_Ch3_Loop:
	dw Pattern_664E
	dw Pattern_664E
	dw Pattern_66C3
	LIST_LOOP Song06_Ch3_Loop
Song06_Ch4:
	dw Pattern_686C
Song06_Ch4_Loop:
	dw Pattern_688D
	dw Pattern_689A
	dw Pattern_68A8
	LIST_LOOP Song06_Ch4_Loop
Pattern_661D:
	INSTR_WAVE Wave_6D36, $60
	db L2, E4
	INSTR_WAVE Wave_6D36, $40
	db L4, E4
	INSTR_WAVE Wave_6D36, $20
	db L4, E4, LEN13, C4, L1D, REST, LEN13, C4, L1D, REST, L4, REST, LEN13, C4, L1D, REST
	db LEN13, C4, L1D, REST, L4, REST, LEN13, C4, L1D, REST, LEN13, C4, L1D, REST, L8, REST
	db PAT_END
Pattern_664E:
	db L8, D4, L16, REST, LEN13, D4, L1D, REST, LEN11, D4, LEN12, REST, LEN11, D4, LEN12, REST
	db L8, REST, LEN11, D5, LEN12, REST, L8, REST, L8D, C5, L16, REST, LEN11, C4, LEN12, REST
	db LEN13, C4, L1D, REST, LEN13, C5, L1D, REST, LEN11, C5, LEN12, REST, L2D, C4, LEN9, REST
	db L8, B3, L16, REST, LEN13, B4, L1D, REST, LEN11, B3, LEN12, REST, LEN11, B4, LEN12, REST
	db L8, REST, LEN13, B4, L1D, REST, L16, REST, LEN11, B3, LEN12, REST, LEN11, B4, LEN12, REST
	db LEN13, As3, L1D, REST, LEN13, As4, L1D, REST, LEN13, As3, L1D, REST, LEN13, As4, L1D, REST
	db LEN11, As3, LEN12, REST, LEN11, As4, LEN12, REST, L8, REST, LEN13, As3, L1D, REST, L16, REST
	db L8D, C4, L16, REST, PAT_END
Pattern_66C3:
	REPEAT $04
	db LEN13, A3, L1D, REST, LEN13, A3, L1D, REST, LEN13, A4, L1D, REST, LEN13, E4, L1D, REST
	REPEAT_END
	REPEAT $04
	db LEN13, G3, L1D, REST, LEN13, G3, L1D, REST, LEN13, G4, L1D, REST, LEN13, D4, L1D, REST
	REPEAT_END
	REPEAT $04
	db LEN13, A3, L1D, REST, LEN13, A3, L1D, REST, LEN13, A4, L1D, REST, LEN13, E4, L1D, REST
	REPEAT_END
	REPEAT $02
	db LEN13, G3, L1D, REST, LEN13, G3, L1D, REST, LEN13, G4, L1D, REST, LEN13, D4, L1D, REST
	REPEAT_END
	db LEN13, A3, L1D, REST, LEN13, A3, L1D, REST, LEN13, A4, L1D, REST, LEN13, A3, L1D, REST
	db LEN13, A3, L1D, REST, LEN13, A4, L1D, REST, LEN13, A3, L1D, REST, LEN13, C4, L1D, REST
	db PAT_END
Pattern_6730:
	REST_ENV $26
	INSTR $28, $00, $81
	db L8, G4
	REPEAT $07
	ENV_ADD $10
	db L8, G4
	REPEAT_END
	INSTR $81, $00, $41
	db L16, A4, A4, L4, REST, L16, A4, A4, L4, REST, L16, A4, A4, L8, REST, PAT_END
Pattern_6753:
	INSTR $82, $00, $81
	REPEAT $08
	db L16, C5, F4
	ENV_ADD $e0
	db C5, F4
	ENV_ADD $20
	REPEAT_END
	REPEAT $04
	db L16, D5, G4
	ENV_ADD $e0
	db D5, G4
	ENV_ADD $20
	REPEAT_END
	INSTR $82, $00, $40
	db D5, F4, D5, F4, D5, F4, D5, F4, REST
	INSTR $82, $00, $81
	db F4, D5, F4, D5, F4, D5, F4
	ENV_ADD $f0
	db PAT_END
Pattern_678A:
	db L16, E5, C5, A4, C5, E5, C5, A4, C5, E5, C5, A4, C5, E5, C5, A4
	db C5, D5, As4, G4, As4, D5, As4, G4, As4, D5, As4, G4, As4, D5, As4, G4
	db As4, E5, C5, A4, C5, E5, C5, A4, C5, E5, C5, A4, C5, E5, C5, A4
	db C5, D5, As4, G4, As4, D5, As4, G4, As4, E4, As5, A5, G5, F5, E5, F5
	db G5, PAT_END
Pattern_67CC:
	REST_ENV $26
	INSTR $28, $00, $81
	db L8, C5
	REPEAT $07
	ENV_ADD $10
	db L8, C5
	REPEAT_END
	INSTR $81, $00, $41
	db L16, E5, E5, L4, REST, L16, E5, E5, L4, REST, L16, E5, E5, L8, REST, PAT_END
Pattern_67EF:
	INSTR $82, $00, $81
	REPEAT $08
	db L16, F5, A4
	ENV_ADD $e0
	db F5, A4
	ENV_ADD $20
	REPEAT_END
	REPEAT $04
	db L16, F5, B4
	ENV_ADD $e0
	db F5, B4
	ENV_ADD $20
	REPEAT_END
	INSTR $82, $00, $40
	db F5, As4, F5, As4, F5, As4, F5, As4, REST
	INSTR $82, $00, $81
	db As4, F5, As4, F5, As4, F5, As4
	ENV_ADD $f0
	db PAT_END
Pattern_6826:
	db L16, G5, E5, C5, E5, G5, E5, C5, E5, G5, E5, C5, E5, G5, E5, C5
	db E5, F5, D5, As4, D5, F5, D5, As4, D5, F5, D5, As4, D5, F5, D5, As4
	db D5, G5, E5, C5, E5, G5, E5, C5, E5, G5, E5, C5, E5, G5, E5, C5
	db E5, G5, D5, As4, D5, G5, D5, As4, D5
	INSTR $82, $00, $c0
	db A4, As5, A5, G5, F5, E5, F5, G5, PAT_END
Pattern_686C:
	DRUMKIT DrumKit_68B0
	REPEAT $02
	db L16, NOISE_06, NOISE_0B, NOISE_0B, NOISE_0B
	REPEAT_END
	REPEAT $04
	db L16, NOISE_10, NOISE_10
	REPEAT_END
	db L16, NOISE_15, NOISE_15, L4, REST, L16, NOISE_15, NOISE_15, L4, REST, L16, NOISE_15, NOISE_15, L8, REST, PAT_END
Pattern_688D:
	REPEAT $10
	db L16, NOISE_1A, NOISE_1F, NOISE_24, NOISE_29, NOISE_1A, NOISE_1F, NOISE_24, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_689A:
	REPEAT $07
	db L16, NOISE_1A, NOISE_1F, L8, NOISE_2E, L16, NOISE_33, NOISE_1F, L8, NOISE_2E
	REPEAT_END
	db PAT_END
Pattern_68A8:
	REPEAT $06
	db L16, NOISE_38
	REPEAT_END
	db L8, NOISE_3D, PAT_END
DrumKit_68B0:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $16, $00, $37, $07, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $16, $00, $37, $50, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $66, $00, $37, $50, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $66, $00, $37, $07, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $76, $00, $37, $20, $c0	; $1a: NR42, -, NR41, NR43, NR44
	db $56, $00, $37, $20, $c0	; $1f: NR42, -, NR41, NR43, NR44
	db $76, $00, $37, $23, $c0	; $24: NR42, -, NR41, NR43, NR44
	db $66, $00, $37, $20, $c0	; $29: NR42, -, NR41, NR43, NR44
	db $38, $00, $37, $20, $80	; $2e: NR42, -, NR41, NR43, NR44
	db $76, $00, $37, $50, $c0	; $33: NR42, -, NR41, NR43, NR44
	db $66, $00, $37, $33, $c0	; $38: NR42, -, NR41, NR43, NR44
	db $77, $00, $37, $70, $80	; $3d: NR42, -, NR41, NR43, NR44
; hurry-mode length table of song $02
Song02_HurryLengths:
	db $00, $04, $08, $10, $20, $00, $0c, $05, $03, $00, $02, $1e, $02, $02, $14
Song02_Header:
	SONG $00, LengthTable_690C, Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
LengthTable_690C:
	db $00, $05, $0a, $14, $28, $00, $0f, $06, $04, $00, $03, $26, $02, $02, $19
Song02_Ch1:
	dw Pattern_693B
Song02_Ch1_Loop:
	dw Pattern_6A45
	LIST_LOOP Song02_Ch1_Loop
Song02_Ch2:
	dw Pattern_6940
Song02_Ch2_Loop:
	dw Pattern_6A03
	LIST_LOOP Song02_Ch2_Loop
Song02_Ch3:
	dw Pattern_6945
Song02_Ch3_Loop:
	dw Pattern_696D
	LIST_LOOP Song02_Ch3_Loop
Song02_Ch4:
	dw Pattern_694A
Song02_Ch4_Loop:
	dw Pattern_694E
	LIST_LOOP Song02_Ch4_Loop
Pattern_693B:
	INSTR $77, $00, $81
	db PAT_END
Pattern_6940:
	INSTR $53, $00, $80
	db PAT_END
Pattern_6945:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_694A:
	DRUMKIT DrumKit_6958
	db PAT_END
Pattern_694E:
	db L16, NOISE_06, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, NOISE_0B, PAT_END
DrumKit_6958:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $61, $00, $38, $50, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $41, $00, $38, $33, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $38, $23, $c0	; $10: NR42, -, NR41, NR43, NR44
Pattern_696D:
	db L8, As3, L16, REST, LEN10, As3, LEN13, REST, LEN10, As4, LEN13, REST, L4D, As3, L2D, REST
	db LEN10, As4, LEN13, REST, LEN10, F3, LEN13, REST, L16, REST, L8, F3, L16, REST, L4D, C4
	db L2D, REST, LEN10, F3, LEN13, REST, LEN10, Ds3, LEN13, REST, L16, REST, L4D, Ds3, L2D, REST
	db LEN10, Ds4, LEN13, REST, L4D, Ds3, L2D, REST, LEN10, Ds4, LEN13, REST, L8, F3, L16, REST
	db LEN10, F3, LEN13, REST, LEN10, F4, LEN13, REST, L4D, F3, L2D, REST, LEN10, F4, LEN13, REST
	REPEAT $02
	db L4D, As3, L2D, REST, L4D, As4, L2D, REST, LEN10, As3, LEN13, REST, L4D, As4, L2D, REST
	db LEN10, As3, LEN13, REST
	REPEAT_END
	db LEN10, Ds3, LEN13, REST, L16, REST, L4D, Ds3, L2D, REST, LEN10, Ds4, LEN13, REST, L4D, Ds3
	db L2D, REST, LEN10, Ds4, LEN13, REST, LEN10, Ds3, LEN13, REST, LEN10, Ds4, LEN13, REST, L4D, Ds3
	db L2D, REST, LEN10, Ds4, LEN13, REST, L4D, Ds3, L2D, REST, LEN10, Ds4, LEN13, REST, PAT_END
Pattern_6A03:
	db L16, As4, D5, As4, D5, As4, D5, As4, D5, A4, C5, A4, C5, A4, C5, A4
	db C5, As4, Ds5, As4, Ds5, As4, Ds5, As4, Ds5, A4, F5, A4, F5, A4, F5, A4
	db F5, As4, D5, As4, D5, As4, D5, As4, D5, As4, D5, As4, D5, As4, D5, As4
	db D5, As4, Ds5, As4, Ds5, As4, Ds5, As4, Ds5, As4, Ds5, As4, Ds5, As4, Ds5, As4
	db Ds5, PAT_END
Pattern_6A45:
	db L1D, G5, L8, F5, L16, G5, L4, A5, C5, L16, G5, REST, L8D, G5, L8, F5
	db L16, G5, L4, A5, C5, L16, C6, As5, A5, C6, As5, A5, G5, As5, A5, G5
	db F5, A5, G5, F5, G5, A5, L2, F5, LEN12, E6, LEN11, F6, PAT_END
Song03_Header:
	SONG $00, LengthTable_6A7D, Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
LengthTable_6A7D:
	db $05, $02, $00, $15, $00, $0c, $02, $13, $02, $00, $07, $0a, $0e, $0b, $00
Song03_Ch2:
	dw Pattern_6AA2
	dw Pattern_6B5A
	LIST_END
Song03_Ch1:
	dw Pattern_6AA7
	dw Pattern_6B91
	LIST_END
Song03_Ch3:
	dw Pattern_6AAC
	dw Pattern_6ADB
	LIST_END
Song03_Ch4:
	dw Pattern_6AB1
	LIST_END
Pattern_6AA2:
	INSTR $83, $00, $40
	db PAT_END
Pattern_6AA7:
	INSTR $73, $00, $40
	db PAT_END
Pattern_6AAC:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_6AB1:
	DRUMKIT DrumKit_6AC6
	REPEAT $07
	db LEN12, NOISE_06, LEN10, NOISE_06, NOISE_06, NOISE_0B, NOISE_06
	REPEAT_END
	db LEN10, NOISE_10, NOISE_10, NOISE_10, NOISE_10, LEN12, REST, PAT_END
DrumKit_6AC6:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $61, $00, $34, $50, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $31, $00, $34, $30, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $34, $30, $c0	; $10: NR42, -, NR41, NR43, NR44
Pattern_6ADB:
	db L1, D5, L8D, REST, L32, D5, L16, REST, L1, G5, L8D, REST, L32, G5, L16, REST
	db L4D, C5, L2D, REST, L1, C5, L8D, REST, L32, G5, L16, REST, L1, F5, L8D, REST
	db L32, F5, L16, REST, L1, G5, L8D, REST, L32, G5, L16, REST, L1, C5, L8D, REST
	db L32, G5, L16, REST, L4D, C5, L2D, REST, L1, D5, L8D, REST, L32, D5, L16, REST
	db L1, G5, L8D, REST, L32, G5, L16, REST, L1, C5, L8D, REST, L32, C4, L16, REST
	db L1, C4, L8D, REST, L32, C5, L16, REST, L32, F4, L16, REST, L32, G4, L16, REST
	db L32, A4, L16, REST, L32, B4, L16, REST, L32, A4, L16, REST, L32, B4, L16, REST
	db L1, C5, L8D, REST, L32, G3, L16, REST, L32, C3, L16, REST, LEN12, REST, PAT_END
Pattern_6B5A:
	REST_ENV $27
	db LEN10, F5, G5, A5, B5, A5, B5, LEN12, C6, LEN10, G5, L4, E5, LEN10, F5, G5
	db A5, B5, A5, B5, L4, C6, E5, LEN10, F5, G5, A5, B5, A5, B5, LEN12, C6
	db LEN10, G5, LEN12, E5, LEN10, G6, LEN12, F6, LEN10, E6, LEN12, D6, LEN10, E6, L4, C6
	db LEN11, C7, LEN13, REST, PAT_END
Pattern_6B91:
	REST_ENV $27
	db LEN10, C5, D5, F5, F5, F5, F5, L4, E5, LEN12, C5, LEN10, G5, LEN10, C5, D5
	db F5, F5, F5, F5, LEN12, E5, LEN10, F5, LEN12, G5, LEN10, C5, LEN10, C5, D5, F5
	db F5, F5, F5, L4, E5, LEN12, C5, LEN10, E6, LEN12, D6, LEN10, B5, G5, A5, B5
	db L4, E5, LEN11, E6, LEN13, REST, PAT_END
Song04_Header:
	SONG $00, LengthTable_6BD5, Song04_Ch1, Song04_Ch2, Song04_Ch3, 0
LengthTable_6BD5:
	db $00, $00, $00, $15, $00, $00, $00, $00, $00, $00, $07, $02, $0e, $06, $23
Song04_Ch2:
	dw Pattern_6C02
	dw Pattern_6C22
Song04_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song04_Ch2_Loop
Song04_Ch1:
	dw Pattern_6C07
	dw Pattern_6C22
Song04_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song04_Ch1_Loop
Song04_Ch3:
	dw Pattern_6C0C
	dw Pattern_6C11
Song04_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song04_Ch3_Loop
Pattern_6C02:
	INSTR $73, $00, $81
	db PAT_END
Pattern_6C07:
	INSTR $73, $00, $83
	db PAT_END
Pattern_6C0C:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_6C11:
	db LEN10, C5, REST, G5, E6, REST, C6, Gs5, Ds5, Gs5, LEN12, C6, LEN10, Gs5, G5, REST
	db PAT_END
Pattern_6C22:
	REST_ENV $27
	db LEN10, C6, REST, B5, As5, REST, A5, Gs5, REST, L4, Ds5, LEN10, Gs5, G5, L1D, REST
	db LEN11, Fs6, LEN13, G6, LEN10, REST, PAT_END
Song05_Header:
	SONG $00, LengthTable_6C46, Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
LengthTable_6C46:
	db $00, $00, $00, $15, $00, $00, $00, $0a, $37, $46, $07, $03, $0e, $04, $4b
Song05_Ch2:
	dw Pattern_6C7B
	dw Pattern_6CC9
Song05_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song05_Ch2_Loop
Song05_Ch1:
	dw Pattern_6C80
	dw Pattern_6CEC
Song05_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song05_Ch1_Loop
Song05_Ch3:
	dw Pattern_6C85
	dw Pattern_6D0A
Song05_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song05_Ch3_Loop
Song05_Ch4:
	dw Pattern_6C8A
Song05_Ch4_Loop:
	dw Pattern_500A
	LIST_LOOP Song05_Ch4_Loop
Pattern_6C7B:
	INSTR $65, $00, $80
	db PAT_END
Pattern_6C80:
	INSTR $65, $00, $80
	db PAT_END
Pattern_6C85:
	INSTR_WAVE Wave_6D36, $20
	db PAT_END
Pattern_6C8A:
	DRUMKIT DrumKit_6CAF
	db LEN12, NOISE_06, LEN10, NOISE_0B, LEN12, NOISE_0B, LEN10, NOISE_0B, LEN12, NOISE_06, LEN10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_0B, LEN12
	db NOISE_06, LEN10, NOISE_0B, LEN12, NOISE_06, LEN10, NOISE_0B, LEN10, NOISE_06, NOISE_0B, NOISE_0B, LEN12, NOISE_06, LEN10, NOISE_0B, LEN9
	db NOISE_15, PAT_END
DrumKit_6CAF:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $61, $00, $31, $23, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $61, $00, $31, $33, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $31, $50, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $56, $00, $00, $23, $80	; $15: NR42, -, NR41, NR43, NR44
Pattern_6CC9:
	REST_ENV $27
	db LEN12, A4, LEN10, Gs4, A4, REST, L4, G5, LEN10, F5, LEN12, E5, LEN10, F5, L4, E5
	db D5, C5, LEN12, D5, LEN11, Cs5, LEN13, C5
	REST_ENV $55
	INSTR $78, $00, $80
	db L1D, B4, PAT_END
Pattern_6CEC:
	REST_ENV $27
	db LEN12, F4, LEN10, F4, F4, REST, L4, D5, LEN10, D5, LEN12, C5, LEN10, C5, L4, A4
	db A4, G4, G4
	REST_ENV $55
	INSTR $78, $00, $80
	db L1D, E4, PAT_END
Pattern_6D0A:
	db LEN10, D4, REST, D5, C5, REST, L4, D4, LEN10, D5, C5, REST, A4, LEN12, F5, LEN10
	db G4, LEN12, F5, LEN10, G4, LEN12, D5, LEN10, G4, LEN12, F5, LEN10, G4, L2D, C4
	INSTR_WAVE Wave_6D36, $40
	db L4D, C4
	INSTR_WAVE Wave_6D36, $60
	db L4D, C4, PAT_END
Wave_6D36:
	db $22, $66, $aa, $ee, $ff, $ff, $fe, $ea, $a6, $66, $8a, $cf, $fe, $ec, $a6, $33
; unreferenced
Wave_6D46:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
Wave_6D56:
	db $13, $57, $9b, $df, $db, $97, $53, $10, $13, $57, $9b, $df, $db, $97, $53, $10
Wave_6D66:
	db $bb, $bb, $bb, $bb, $bb, $bb, $bb, $bb, $00, $00, $00, $00, $00, $00, $00, $00
; unreferenced
Wave_6D76:
	db $48, $cd, $e9, $88, $53, $78, $9b, $ee, $e6, $44, $35, $aa, $b7, $53, $76, $9e
; unreferenced
Wave_6D86:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $ed, $cb, $a9, $87, $65, $43, $21, $00
Wave_6D96:
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
; unreferenced
Unused_6DA6:
	db $99, $64, $7c, $c8, $45, $9b, $a6, $6a, $ee, $b8, $ad, $d8, $21, $46, $40, $04
	db $72, $00, $00, $00, $00, $00, $00, $22, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $72, $00, $00, $00, $00, $00, $00, $25, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $5f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $66, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $18
	db $c1, $00, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Song11_Header:
	SONG $00, LengthTable_6E81, Song11_Ch1, Song11_Ch2, Song0E_Ch3, 0
LengthTable_6E81:
	db $08, $07, $07, $06, $06, $05, $05, $05, $04, $04, $05, $00, $00, $00, $00
; unreferenced
Unused_6E90:
	db $00
Song11_Ch1:
	dw Pattern_6EA5
	dw Pattern_6EB5
Song11_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song11_Ch1_Loop
Song11_Ch2:
	dw Pattern_6EAC
	dw Pattern_6EB5
Song11_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song11_Ch2_Loop
Pattern_6EA5:
	INSTR $41, $00, $41
	REST_ENV $00
	db PAT_END
Pattern_6EAC:
	INSTR $12, $00, $41
	REST_ENV $00
	db LEN10, REST, PAT_END
Pattern_6EB5:
	REPEAT $04
	db L32, C7, As6, F6, G6
	REPEAT_END
	ENV_ADD $10
	REPEAT $04
	db L16, As6, Gs6, Ds6, F6
	REPEAT_END
	ENV_ADD $10
	REPEAT $04
	db L8, C7, As6, F6, G6
	REPEAT_END
	ENV_ADD $10
	REPEAT $04
	db L4, As6, Gs6, Ds6, F6
	REPEAT_END
	ENV_ADD $10
	REPEAT $02
	db L2, Gs6, Fs6, Cs6, Ds6
	REPEAT_END
	ENV_ADD $10
	REPEAT $02
	db L1, Fs6, E6, B5, Cs6
	REPEAT_END
	ENV_ADD $10
	REPEAT $02
	db L8D, E6, D6, A5, B5
	REPEAT_END
	ENV_ADD $10
	REPEAT $02
	db L4D, D6, C6, G5, A5
	REPEAT_END
	db PAT_END
	ds 4348, 0	; $6F04-$7FFF unused
