; Kirby Tilt 'n' Tumble music: songs, bank $0F $5000-$7FFF

Pattern_5000:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
; unreferenced
Pattern_500A:
	db L1, REST, REST, REST, REST, REST, REST, REST, REST, PAT_END
; hurry-mode length table of song $41
Song41_HurryLengths:
	db $02, $04, $08, $10, $20, $00, $0c, $18, $00, $02, $00, $00, $00, $40, $80
Song41_Header:
	SONG $00, LengthTable_502E, Song41_Ch1, Song41_Ch2, Song41_Ch3, Song41_Ch4
LengthTable_502E:
	db $03, $05, $0a, $14, $28, $00, $0f, $1e, $00, $02, $00, $00, $00, $50, $a0
Song41_Ch1:
	dw Pattern_508D
	dw Pattern_50B0
	dw Pattern_5094
	dw Pattern_50BA
	dw Pattern_50A2
Song41_Ch1_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_50C8
	LIST_TRANSPOSE_ADD 12
	dw Pattern_50C8
	LIST_LOOP Song41_Ch1_Loop
Song41_Ch2:
	dw Pattern_509B
	dw Pattern_50B0
	dw Pattern_5094
	dw Pattern_510D
	LIST_ENV_SET $0084
	dw Pattern_5117
	dw Pattern_50A9
Song41_Ch2_Loop:
	LIST_TRANSPOSE 0
	dw Pattern_5120
	LIST_TRANSPOSE_ADD 12
	dw Pattern_5120
	LIST_LOOP Song41_Ch2_Loop
Song41_Ch3:
	dw Pattern_5141
Song41_Ch3_Loop:
	dw Pattern_517B
	LIST_LOOP Song41_Ch3_Loop
Song41_Ch4:
	dw Pattern_5089
	dw Pattern_51C2
Song41_Ch4_Loop:
	dw Pattern_51CE
	LIST_LOOP Song41_Ch4_Loop
Pattern_5089:
	DRUMKIT DrumKit_51D9
	db PAT_END
Pattern_508D:
	INSTR $18, $00, $80
	REST_ENV $35
	db PAT_END
Pattern_5094:
	INSTR $94, $00, $80
	REST_ENV $35
	db PAT_END
Pattern_509B:
	INSTR $18, $00, $c0
	REST_ENV $35
	db PAT_END
Pattern_50A2:
	INSTR $94, $00, $81
	REST_ENV $35
	db PAT_END
Pattern_50A9:
	INSTR $85, $00, $00
	REST_ENV $35
	db PAT_END
Pattern_50B0:
	db L2, As2
	REPEAT $08
	ENV_ADD $10
	db L16, As2
	REPEAT_END
	db PAT_END
Pattern_50BA:
	db L8, Cs5, As4, REST, Cs5, As4, REST, Cs5, As4
	ENV_SET $00
	db L1D, REST, PAT_END
Pattern_50C8:
	db L8, Fs4, Ds4, L4D, REST, L8, Cs4, Ds4, L4, Fs4, L8, Ds4, L4D, REST, L8, Gs4
	db As4, REST, L16, Fs4, F4, L8, Ds4, L4D, REST, L8, As3, Fs4
	REPEAT $03
	db L4, Ds4, L16, Cs4, REST
	REPEAT_END
	db L8, Gs4, Fs4, L4D, REST, L8, Gs4, Fs4, REST, Ds4, Fs4, REST, Ds4, Fs4, Gs4, A4
	db As4, L8, Cs5, As4, L2, REST, L8, Cs5, As4, L2, REST, L8, Cs5, As4, L4, REST
	db PAT_END
Pattern_510D:
	db L8, Gs4, F4, REST, Gs4, F4, REST, Gs4, F4, PAT_END
Pattern_5117:
	REPEAT $04
	db L8, Ds2, Ds2, As2, Cs2
	REPEAT_END
	db PAT_END
Pattern_5120:
	REPEAT $08
	db L16, Fs3, As3, Ds4, As3
	REPEAT_END
	REPEAT $08
	db L16, F3, Gs3, Cs4, Gs3
	REPEAT_END
	REPEAT $08
	db L16, Fs3, B3, Ds4, B3
	REPEAT_END
	REPEAT $08
	db L16, Gs3, As3, D4, As3
	REPEAT_END
	db PAT_END
Pattern_5141:
	INSTR_WAVE Wave_5B02, $40
	db L2, As2
	INSTR_WAVE Wave_5B02, $20
	db L2, As2, L16, F5, REST, D5, REST, REST, REST, F5, REST, D5, REST, REST, REST, F5
	db REST, D5, REST
	REPEAT $03
	db L16, Ds4, REST, Ds4, REST, As3, REST, Cs4, REST
	REPEAT_END
	db L16, Ds4, REST, Ds4, REST, L32, As3, LEN9, REST, L32, As3, LEN9, REST, L16, Cs4, REST
	db PAT_END
Pattern_517B:
	REPEAT $04
	db L16, Ds4, REST, Ds4, REST, As3, REST, Cs4, REST
	REPEAT_END
	REPEAT $04
	db L16, Cs4, REST, Cs4, REST, Gs3, REST, B3, REST
	REPEAT_END
	REPEAT $04
	db L16, B3, REST, B3, REST, Fs3, REST, Fs4, REST
	REPEAT_END
	db L16, As3, REST, As3, REST, F4, REST, As3, REST, As3, REST, F4, REST, L16, As3, REST
	db As3, REST, F4, REST, As3, REST, As3, REST, F3, REST, As4, REST, As3, REST, As4, REST
	db As3, REST, PAT_END
Pattern_51C2:
	db LEN13, REST, L8, NOISE_06, NOISE_06, REST, NOISE_06, NOISE_06, REST, NOISE_06, NOISE_06, PAT_END
Pattern_51CE:
	db L16, NOISE_0B, NOISE_10, L8, NOISE_15, L16, NOISE_1A, NOISE_10, L8, NOISE_15, PAT_END
DrumKit_51D9:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $33, $80	; $06: NR42, -, NR41, NR43, NR44
	db $71, $00, $00, $30, $80	; $0b: NR42, -, NR41, NR43, NR44
	db $41, $00, $00, $30, $80	; $10: NR42, -, NR41, NR43, NR44
	db $48, $00, $00, $10, $80	; $15: NR42, -, NR41, NR43, NR44
	db $71, $00, $00, $50, $80	; $1a: NR42, -, NR41, NR43, NR44
; unreferenced song header (no song table entry)
Unused_51F8_Header:
	SONG $00, LengthTable_4CB0, Unused_51F8_Ch1, Unused_51F8_Ch2, Unused_51F8_Ch3, 0
Unused_51F8_Ch2:
	dw Pattern_5215
	dw Pattern_5224
	LIST_END
Unused_51F8_Ch1:
	dw Pattern_521A
	dw Pattern_523F
	LIST_END
Unused_51F8_Ch3:
	dw Pattern_521F
	dw Pattern_525D
	LIST_END
Pattern_5215:
	INSTR $67, $00, $80
	db PAT_END
Pattern_521A:
	INSTR $67, $00, $80
	db PAT_END
Pattern_521F:
	INSTR_WAVE Wave_52F6, $21
	db PAT_END
Pattern_5224:
	db L8, E4, D5, REST, D5, D5, REST, L8, F4, Ds5, REST, Ds5, Ds5, REST, L8, Fs4
	db E5, REST, E5, E5, REST, L8, F5, REST, L1, F5, PAT_END
Pattern_523F:
	db L8, E3, L4, Gs4, L8, Gs4, L4, Gs4, L8, F3, L4, A4, L8, A4, L4, A4
	db L8, Fs3, L4, As4, L8, As4, L4, As4, L8, B4, REST, L1, B4, PAT_END
Pattern_525D:
	db L8, B4, B5, REST, B5, B5, REST, L8, C5, C6, REST, C6, C6, REST, L8, Cs5
	db Cs6, REST, Cs6, Cs6, REST, L8, G4, REST, L1, G4, PAT_END
; unreferenced song header (no song table entry)
Unused_5278_Header:
	SONG $06, LengthTable_5283, Unused_5278_Ch1, Unused_5278_Ch2, Unused_5278_Ch3, Unused_5278_Ch4
LengthTable_5283:
	db $03, $06, $1b, $18, $6c, $d8, $1b, $36, $6c, $0d, $09, $01, $12, $18, $90
Unused_5278_Ch2:
	dw Pattern_52B8
	dw Pattern_52C7
Song41_Ch4_Loop3:
	dw Pattern_5000
	LIST_LOOP Song41_Ch4_Loop3
Unused_5278_Ch1:
	dw Pattern_52BD
	dw Pattern_52D3
Song41_Ch4_Loop2:
	dw Pattern_5000
	LIST_LOOP Song41_Ch4_Loop2
Unused_5278_Ch3:
	dw Pattern_52C2
	dw Pattern_52DF
Song41_Ch4_Loop4:
	dw Pattern_5000
	LIST_LOOP Song41_Ch4_Loop4
Unused_5278_Ch4:
	dw Pattern_52EB
Song41_Ch4_Loop5:
	dw Pattern_500A
	LIST_LOOP Song41_Ch4_Loop5
Pattern_52B8:
	INSTR $a7, $00, $80
	db PAT_END
Pattern_52BD:
	INSTR $a7, $00, $80
	db PAT_END
Pattern_52C2:
	INSTR_WAVE Wave_52F6, $21
	db PAT_END
Pattern_52C7:
	db L16, E6, E6, REST, F6, REST, F6, REST, Fs6, L4, G6, PAT_END
Pattern_52D3:
	db L16, C6, C6, REST, C6, REST, C6, REST, Cs6, L4, D6, PAT_END
Pattern_52DF:
	db L16, C5, C5, REST, C5, REST, C5, REST, C5, L4, D5, PAT_END
Pattern_52EB:
	db L4, NOISE_1A, NOISE_1A, L16, NOISE_1A, NOISE_29, NOISE_29, NOISE_29, L4, NOISE_2E, PAT_END
Wave_52F6:
	db $48, $cc, $cc, $cc, $cc, $cc, $cc, $cc, $84, $00, $00, $00, $00, $00, $00, $00
; songs $4d, $4e, $4f, $52, $53, $54, $56, $57, $58, $59, $5a, $5b, $5c, $5d, $5e, $5f, $60, $61, $62, $63, $68, $69, $6a, $6b, $6c, $6d, $6e, $6f, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7a, $7b, $7c, $7d, $7e, $7f; 63 unreachable table entries ($01, $02, $03, $04, ...)
Song4D_Header:
	SONG $00, LengthTable_5311, Song4D_Ch1, Song4D_Ch2, Song4D_Ch3, Song4D_Ch4
LengthTable_5311:
	db $03, $6f, $1b, $6f, $6f, $6f, $6f, $6f, $6f, $6f, $09, $6f, $12, $6f, $6f
Song4D_Ch1:
	dw Pattern_5340
Song4D_Ch1_Loop:
	dw Pattern_5359
	LIST_LOOP Song4D_Ch1_Loop
Song4D_Ch2:
	dw Pattern_542F
Song4D_Ch2_Loop:
	dw Pattern_5448
	LIST_LOOP Song4D_Ch2_Loop
Song4D_Ch3:
	dw Pattern_551E
Song4D_Ch3_Loop:
	dw Pattern_5530
	LIST_LOOP Song4D_Ch3_Loop
Song4D_Ch4:
	dw Pattern_5631
Song4D_Ch4_Loop:
	dw Pattern_5647
	LIST_LOOP Song4D_Ch4_Loop
Pattern_5340:
	INSTR $71, $00, $40
	db LEN10, A3, REST, A3, A3, REST, A3, L8, REST, LEN10, A3, REST, REST, Fs3, REST, REST
	db L8, REST, C4, REST, PAT_END
Pattern_5359:
	db L8, REST, B4, REST, B4, REST, As4, REST, As4, L8, REST, B4, REST, B4, REST, As4
	db REST, As4, L8, REST, B4, REST, B4, REST, As4, As4, REST, L8, REST, B4, REST, B4
	db REST, B4, REST, B4, L8, REST, B4, REST, B4, REST, As4, REST, As4, L8, REST, B4
	db REST, B4, REST, As4, REST, As4, L8, REST, B4, REST, B4, REST, As4, As4, REST, L8
	db B4, B4, B4, REST, REST, LEN10, B4, REST, B4, L8, B4, REST, L8, REST, LEN10, B4
	db REST, B4, L8, REST, LEN10, B4, REST, B4, L8, REST, L8, As4, B4, REST, L8, REST
	db LEN10, B4, REST, B4, L8, REST, LEN10, B4, REST, B4, L8, REST, L8, Fs4, Fs4, REST
	db L8, REST, LEN10, E4, REST, E4, L8, REST, LEN10, E4, REST, E4, L8, REST, L8, E4
	db E4, REST, L8, REST, LEN10, Fs4, REST, Fs4, L8, REST, Fs4, Fs4, Fs4, Fs4, Fs4, L8
	db REST, LEN10, B4, REST, B4, L8, REST, LEN10, B4, REST, B4, L8, REST, L8, As4, B4
	db REST, L8, REST, LEN10, B4, REST, B4, L8, REST, LEN10, B4, REST, B4, L8, REST, L8
	db Fs4, Fs4, REST, L8, REST, LEN10, E4, REST, E4, L8, REST, LEN10, E4, REST, E4, L8
	db REST, L8, E4, E4, REST, L8, Fs4, Fs4, Fs4, Fs4, D4, LEN10, REST, REST, L32, REST
	db D5, D5, L8, D6, REST, PAT_END
Pattern_542F:
	INSTR $71, $00, $40
	db LEN10, D4, REST, D4, D4, REST, D4, L8, REST, LEN10, D4, REST, REST, D4, REST, REST
	db L8, REST, Fs4, REST, PAT_END
Pattern_5448:
	db L8, REST, D5, REST, D5, REST, Cs5, REST, Cs5, L8, REST, D5, REST, D5, REST, Cs5
	db REST, Cs5, L8, REST, D5, REST, D5, REST, Cs5, E5, REST, L8, REST, D5, REST, D5
	db REST, D5, REST, D5, L8, REST, D5, REST, D5, REST, Cs5, REST, Cs5, L8, REST, D5
	db REST, D5, REST, Cs5, REST, Cs5, L8, REST, D5, REST, D5, REST, Cs5, E5, REST, L8
	db D5, D5, D5, REST, REST, LEN10, D5, REST, D5, L8, D5, REST, L8, REST, LEN10, D5
	db REST, D5, L8, REST, LEN10, D5, REST, D5, L8, REST, L8, Cs5, D5, REST, L8, REST
	db LEN10, D5, REST, D5, L8, REST, LEN10, D5, REST, D5, L8, REST, L8, A5, C6, REST
	db L8, REST, LEN10, G5, REST, G5, L8, REST, LEN10, G5, REST, G5, L8, REST, L8, G5
	db G5, REST, L8, REST, LEN10, A5, REST, A5, L8, REST, A5, A5, A5, C6, C6, L8
	db REST, LEN10, D5, REST, D5, L8, REST, LEN10, D5, REST, D5, L8, REST, L8, Cs5, D5
	db REST, L8, REST, LEN10, D5, REST, D5, L8, REST, LEN10, D5, REST, D5, L8, REST, L8
	db A5, C6, REST, L8, REST, LEN10, G5, REST, G5, L8, REST, LEN10, G5, REST, G5, L8
	db REST, L8, G5, G5, REST, L8, A5, A5, A5, A5, A5, LEN10, REST, REST, L32, REST
	db Fs5, Fs5, L8, Fs6, REST, PAT_END
Pattern_551E:
	INSTR_WAVE Wave_56D7, $40
	db L8, D4, C4, B3, A3, LEN10, D3, REST, REST, L8, REST, Fs3, REST, PAT_END
Pattern_5530:
	REPEAT $02
	db LEN10, G3, REST, REST, REST, REST, D3, G3, REST, A3, L8, B3, As3, LEN10, REST, REST
	db B3, G3, REST, D3, E3, REST, REST, LEN10, G3, REST, REST, REST, REST, D3, G3, REST
	db B3, L8, D4, Cs4, LEN10, REST, REST, D4, As3, REST, B3, G3, REST, D3, LEN10, G3
	db REST, REST, REST, REST, D3, G3, REST, A3, L8, B3, As3, LEN10, REST, REST, B3, L8
	db E4, REST, LEN10, D4, REST, Cs4, D4, REST, Cs4, D4, REST, REST, D3, REST, Fs3, L8
	db G3, REST, LEN10, REST, REST, D3, E3, REST, D3
	REPEAT_END
	db LEN10, G3, REST, G3, A3, REST, A3, B3, REST, B3, D4, REST, D4, L8, Cs4, REST
	db LEN10, D4, REST, REST, L8, REST, LEN10, G3, B3, D4, Cs4, REST, D4, Cs4, REST, D4
	db Cs4, REST, D4, REST, REST, F4, F4, E4, Ds4, L8, D4, REST, LEN10, REST, REST, REST
	db E4, REST, G4, L8, C4, E4, G3, LEN10, E4, REST, E4, L8, G4, REST, LEN10, D3
	db REST, D3, Fs3, REST, Fs3, D4, REST, D4, L8, A3, D4, LEN10, D3, REST, REST, L8
	db E3, Fs3, LEN10, G3, B3, D4, Cs4, REST, D4, Cs4, REST, D4, Cs4, REST, D4, L8
	db As3, REST, LEN10, B3, REST, REST, L8, REST, LEN10, G3, B3, D4, Cs4, REST, D4, Cs4
	db REST, D4, Cs4, REST, D4, REST, REST, F4, F4, E4, Ds4, L8, D4, REST, LEN10, REST
	db REST, REST, E4, REST, G4, L8, C4, E4, G3, LEN10, E4, REST, E4, L8, G4, REST
	db LEN10, D3, REST, D3, Fs3, REST, Fs3, D4, REST, D4, L8, A3, LEN10, D4, REST, REST
	db L8, D3, E3, Fs3, PAT_END
Pattern_5631:
	db LEN12, NOISE_29, LEN10, NOISE_29, LEN12, REST, LEN10, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29
	db L8, REST, NOISE_2E, NOISE_29, NOISE_2E, PAT_END
Pattern_5647:
	REPEAT $03
	db L8, NOISE_29, LEN10, NOISE_29, REST, NOISE_29, L8, NOISE_2E, LEN12, NOISE_2E, LEN10, NOISE_29, L8, NOISE_29, REST, NOISE_2E
	db LEN12, NOISE_29, LEN10, NOISE_29, LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_29, REST, NOISE_29, L8, NOISE_29, NOISE_2E, NOISE_29
	db NOISE_2E
	REPEAT_END
	db L8, REST, NOISE_29, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29, L8, NOISE_29, REST, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29
	db LEN12, NOISE_29, LEN10, NOISE_29, L8, NOISE_29, REST, NOISE_29, LEN10, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, NOISE_2E, NOISE_29
	db NOISE_29, NOISE_29, NOISE_2E, NOISE_2E, NOISE_2E
	REPEAT $03
	db L8, NOISE_29, NOISE_2E, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_2E, L8, NOISE_29, NOISE_2E, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29
	db LEN12, NOISE_2E, LEN10, NOISE_2E, NOISE_29, NOISE_29, NOISE_29, L8, NOISE_29, NOISE_2E, NOISE_2E, NOISE_2E, NOISE_29, NOISE_2E
	REPEAT_END
	db L8, NOISE_29, NOISE_2E, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_2E, L8, NOISE_29, NOISE_2E, NOISE_2E, LEN12, NOISE_29, LEN10, NOISE_29
	db LEN12, NOISE_2E, LEN10, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29, LEN12, NOISE_2E, LEN10, NOISE_29
	db L8, REST, NOISE_2E, NOISE_29, NOISE_2E, PAT_END
Wave_56D7:
	db $8f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $00, $00, $00, $00, $00, $00, $00
; hurry-mode length table of song $64
Song64_HurryLengths:
	db $00, $05, $0a, $14, $28, $50, $00, $00, $00, $00, $00, $00, $00, $00, $00
Song64_Header:
	SONG $00, LengthTable_5703, Song64_Ch1, Song64_Ch2, Song64_Ch3, Song64_Ch4
; unreferenced: pointer to Song64_HurryLengths
Unused_5701:
	db $e7, $56
LengthTable_5703:
	db $00, $06, $0c, $18, $30, $60, $00, $00, $00, $00, $00, $00, $00, $00, $00
Song64_Ch1:
	dw Pattern_5732
Song64_Ch1_Loop:
	dw Pattern_5758
	LIST_LOOP Song64_Ch1_Loop
Song64_Ch2:
	dw Pattern_573C
Song64_Ch2_Loop:
	dw Pattern_57C8
	LIST_LOOP Song64_Ch2_Loop
Song64_Ch3:
	dw Pattern_574A
Song64_Ch3_Loop:
	dw Pattern_5826
	LIST_LOOP Song64_Ch3_Loop
Song64_Ch4:
	dw Pattern_588F
Song64_Ch4_Loop:
	dw Pattern_5897
	LIST_LOOP Song64_Ch4_Loop
Pattern_5732:
	INSTR $63, $00, $80
	db L4, REST, REST, REST, D3, PAT_END
Pattern_573C:
	INSTR $63, $00, $80
	db L8, D6, Ds6, A5, As5, F5, Fs5, D5, Ds5, PAT_END
Pattern_574A:
	INSTR_WAVE Wave_52F6, $41
	db L8, F6, Fs6, D6, Ds6, A5, As5, F5, Fs5, PAT_END
Pattern_5758:
	REST_ENV $17
	db L8, REST, D5, D5, REST, D5, D5, REST, L16, Fs5, G5, L8, REST, Ds5, Ds5, REST
	db Ds5, Ds5, REST, L16, As4, REST, L8, REST, D5, D5, REST, D5, D5, REST, REST, L8
	db REST, Ds5, Ds5, REST, Ds5, Ds5, REST, REST, L8, REST, D5, REST, REST, G5, REST, REST
	db REST, L8, REST, Ds5, REST, Ds5, Fs5, Fs5, Fs5, REST, L8, REST, D5, REST, REST, G5
	db REST, REST, REST, L8, REST, Ds5, REST, Ds5, Gs5, G5, Fs5, F5, L8, REST, D5, REST
	db REST, D5, REST, REST, REST, L8, REST, Ds5, REST, Ds5, Fs5, Fs5, Fs5, REST, L8, REST
	db D5, REST, REST, G5, REST, REST, REST, L4, REST, L2, Ds5, L4, E5, PAT_END
Pattern_57C8:
	REST_ENV $17
	REPEAT $02
	db L8, G3, C5, C5, G3, C5, C5, REST, REST, L8, Gs3, Cs5, Cs5, Gs3, Cs5, Cs5
	db REST, Gs3
	REPEAT_END
	db L8, G3, C5, REST, G3, C5, REST, REST, D3, L8, Gs3, Cs5, REST, Cs5, Ds5, Ds5
	db Ds5, Gs3, L8, G3, C5, REST, G3, C5, REST, L4, D3, L8, Gs3, Cs5, REST, Cs5
	db Ds5, Ds5, Ds5, Gs3, L8, G3, C5, REST, G3, C5, REST, REST, D3, L8, Gs3, Cs5
	db REST, Cs5, Ds5, Ds5, Ds5, Gs3, L8, G3, C5, REST, G3, C5, REST, L4, D3, L8
	db Gs3, REST, L2, Cs5, L4, Gs4, PAT_END
Pattern_5826:
	db L4, REST, REST, REST, L16, REST, REST, As6, B6, L4, REST, REST, REST, L16, REST, REST
	db Ds6, REST, L4, REST, L16, REST, REST, As6, B6, As6, B6, As6, D6, L2, F6, L4
	db REST, REST, REST, L4, REST, REST, L8, D6, REST, REST, REST, L4, REST, REST, L16, Gs6
	db A6, Gs6, A6, Gs6, REST, REST, REST, L4, REST, REST, L8, D6, REST, REST, REST, L2
	db REST, L16, Gs6, G6, Fs6, F6, E6, Ds6, D6, Cs6, L4, REST, REST, REST, L16, C6
	db Cs6, E6, G5, L1, Ds6, L4, REST, REST, L8, D6, REST, REST, REST, L2, REST, L16
	db Gs6, G6, Fs6, F6, E6, Ds6, D6, Cs6, PAT_END
Pattern_588F:
	db L4, REST, REST, REST, L8, NOISE_2E, REST, PAT_END
Pattern_5897:
	db L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST, REST, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29
	db REST, REST
	REPEAT $02
	db L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, REST, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29
	db REST, NOISE_29
	REPEAT_END
	db L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, REST, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, L16, NOISE_29
	db NOISE_29, REST, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, REST
	db L8, NOISE_29, NOISE_29, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, REST, NOISE_29, L8, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29
	db NOISE_2E, REST, L8, NOISE_29, REST, NOISE_29, REST, NOISE_29, REST, L16, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Song65_Header:
	SONG $00, LengthTable_5908, Song65_Ch1, Song65_Ch2, Song65_Ch3, Song65_Ch4
LengthTable_5908:
	db $00, $00, $00, $15, $2a, $54, $00, $00, $00, $01, $07, $00, $03, $00, $00
Song65_Ch2:
	dw Pattern_5947
Song65_Ch2_Loop:
	dw Pattern_595F
	dw Pattern_5988
	LIST_LOOP Song65_Ch2_Loop
Song65_Ch1:
	dw Pattern_5951
Song65_Ch1_Loop:
	dw Pattern_59C9
	dw Pattern_5A1E
	LIST_LOOP Song65_Ch1_Loop
Song65_Ch3:
	dw Pattern_5958
Song65_Ch3_Loop:
	dw Pattern_5A5F
	dw Pattern_5A6A
	dw Pattern_5A78
	dw Pattern_5A83
	dw Pattern_5A91
	dw Pattern_5AA3
	LIST_LOOP Song65_Ch3_Loop
Song65_Ch4:
	dw Pattern_5ABE
Song65_Ch4_Loop:
	dw Pattern_5AC1
	dw Pattern_5AE1
	LIST_LOOP Song65_Ch4_Loop
Pattern_5947:
	INSTR $75, $00, $80
	db LEN9, REST, LEN12, A5, B5, PAT_END
Pattern_5951:
	INSTR $52, $00, $80
	db LEN10, REST, PAT_END
Pattern_5958:
	INSTR_WAVE Wave_52F6, $21
	db LEN10, REST, PAT_END
Pattern_595F:
	REST_ENV $27
	db L4, C6, LEN10, B5, REST, REST, C6, REST, REST, L2, G5, LEN10, G5, REST, REST, A5
	db REST, REST, C6, REST, LEN9, REST, LEN12, C6, Cs6, L4, D6, LEN10, E6, REST, REST, D6
	db REST, REST, L1, A5, L4, REST, PAT_END
Pattern_5988:
	db L4, D6, LEN10, E6, REST, REST, D6, REST, REST, L4, B5, LEN10, REST, REST, G5, B5
	db REST, G5, B5, REST, C6, D6, REST, REST, LEN10, C6, REST, REST, C6, REST, REST, C6
	db REST, A5, REST, REST, L2, G5, LEN10, REST, LEN12, B6, REST, LEN9, REST, LEN10, REST, LEN12
	db C7, REST, LEN9, REST, LEN12, D7, REST, LEN9, REST, LEN10, REST, LEN9, REST, LEN12, A5, B5
	db PAT_END
Pattern_59C9:
	REST_ENV $17
	INSTR $35, $00, $80
	db LEN12, G6, A6, G6, A6, G6, A6, G6
	INSTR $55, $00, $80
	db LEN10, G4, REST, C5, L4, C5, LEN10, C5, REST, E5, LEN10, G5, REST, REST, L4, C5
	db LEN10, E5, REST, C5, G5, REST, REST, LEN10, A5, REST, D5, D5, REST, F5, D5, REST
	db A4, D5, REST, F5, LEN10, REST, REST, D5, A5, F5, D5
	INSTR $35, $00, $80
	db LEN12, D6, E6, D6, E6, D6, E6, D6, E6, D6, E6, D6, E6, D6, E6
	INSTR $55, $00, $80
	db PAT_END
Pattern_5A1E:
	db L4, D5, LEN10, G4, REST, D5, L4, D5, LEN10, B4, REST, D5, LEN10, G5, REST, REST
	db L4, B4, LEN10, D5, REST, G4, D5, REST, REST, LEN10, REST, REST, C5, C5, C5, E5
	db C5, REST, G4, C5, REST, L4, D5, LEN10, D5, D5, G5, D5, LEN12, G6, REST, LEN9
	db REST, LEN10, REST, LEN12, A6, REST, LEN9, REST, LEN12, B6, REST, LEN9, REST, LEN10, REST, REST
	db PAT_END
Pattern_5A5F:
	REPEAT $02
	db LEN10, C4, REST, REST, G3, REST, REST
	REPEAT_END
	db PAT_END
Pattern_5A6A:
	db LEN10, C4, REST, REST, G3, REST, REST, C4, REST, REST, C3, D3, E3, PAT_END
Pattern_5A78:
	REPEAT $02
	db LEN10, F3, REST, REST, C4, REST, REST
	REPEAT_END
	db PAT_END
Pattern_5A83:
	db LEN10, F3, REST, REST, C4, REST, REST, F3, REST, C3, A3, F3, D3, PAT_END
Pattern_5A91:
	REPEAT $03
	db LEN10, G3, REST, REST, D4, REST, REST
	REPEAT_END
	db LEN10, G3, REST, D4, E4, F4, Fs4, PAT_END
Pattern_5AA3:
	db LEN10, G4, REST, REST, G4, REST, REST, Fs4, REST, REST, Fs4, REST, REST, LEN10, F4, REST
	db REST, F4, REST, REST, E4, REST, REST, D4, REST, REST, PAT_END
Pattern_5ABE:
	db LEN10, REST, PAT_END
Pattern_5AC1:
	db LEN12, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, LEN10, NOISE_2E, REST, NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_2E
	db REST, NOISE_29, LEN10, NOISE_2E, REST, NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_5AE1:
	db LEN10, NOISE_2E, REST, NOISE_29, NOISE_2E, NOISE_29, NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_2E, REST, NOISE_29, LEN10, NOISE_2E, REST
	db NOISE_29, NOISE_2E, REST, NOISE_29, LEN12, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, LEN10, NOISE_29, NOISE_29, NOISE_29
	db PAT_END
Wave_5B02:
	db $22, $66, $aa, $ee, $ff, $ff, $fe, $ea, $a6, $66, $8a, $cf, $fe, $ec, $a6, $33
; unreferenced
Wave_5B12:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
Wave_5B22:
	db $13, $57, $9b, $df, $db, $97, $53, $10, $13, $57, $9b, $df, $db, $97, $53, $10
; unreferenced
Wave_5B32:
	db $dd, $dd, $dd, $dd, $dd, $dd, $dd, $dd, $00, $00, $00, $00, $00, $00, $00, $00
; unreferenced
Wave_5B42:
	db $48, $cd, $e9, $88, $53, $78, $9b, $ee, $e6, $44, $35, $aa, $b7, $53, $76, $9e
; unreferenced
Wave_5B52:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $ed, $cb, $a9, $87, $65, $43, $21, $00
; unreferenced
Unused_5B62:
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
Song40_Header:
	SONG $07, LengthTable_5C3D, Song40_Ch1, Song40_Ch2, Song40_Ch3, Song40_Ch4
LengthTable_5C3D:
	db $02, $00, $09, $12, $24, $00, $00, $1b, $36, $18, $03, $00, $00, $00, $10
; unreferenced
Unused_5C4C:
	db $00, $00, $00, $00, $10
Song40_Ch1:
	dw Pattern_5CAB
	dw Pattern_5CAE
	dw Pattern_5CB9
	dw Pattern_5CF1
	dw Pattern_5D21
	LIST_LOOP UnusedList_5C6B
Song40_Ch2:
	dw Pattern_5CAB
	dw Pattern_5D2C
	dw Pattern_5D37
	dw Pattern_5D5D
	dw Pattern_5D6A
	dw Pattern_5D9A
UnusedList_5C6B:
	dw Pattern_5DA3
	dw Pattern_5DA3
	dw Pattern_5DA3
	dw Pattern_5DA3
	dw Pattern_5DAB
	dw Pattern_5DAB
	dw Pattern_5DAB
	dw Pattern_5DAB
	LIST_LOOP UnusedList_5C6B
Song40_Ch3:
	dw Pattern_5CAB
	dw Pattern_5DE3
	dw Pattern_5DEC
	dw Pattern_5E2B
	dw Pattern_5E60
	LIST_TRANSPOSE 5
Song40_Ch3_Loop:
	dw Pattern_5E65
	dw Pattern_5E65
	dw Pattern_5E73
	dw Pattern_5E73
	LIST_LOOP Song40_Ch3_Loop
Song40_Ch4:
	dw Pattern_5CAB
	dw Pattern_5E9B
	dw Pattern_5EA1
	dw Pattern_5EA1
	dw Pattern_5EA1
	dw Pattern_5EBE
Song40_Ch4_Loop:
	dw Pattern_5ED9
	LIST_LOOP Song40_Ch4_Loop
Pattern_5CAB:
	db LEN9, REST, PAT_END
Pattern_5CAE:
	INSTR $82, $00, $41
	REST_ENV $27
	db LEN10, D4, F4, G4, PAT_END
Pattern_5CB9:
	db L8, G4, REST, E3, C5, B4, C5, D5, B4, F3, REST, F3, REST, B3, REST, F3
	db B4, As4, B4, C5, G4, E3, REST, E3, REST, E4, REST, E3, C5, B4, C5, D5
	db E5, F3, REST, F3, REST, G4, D5, F3, E5, F3, F4, E3
	INSTR $77, $00, $80
	REST_ENV $33
	db G3, A3, B3, C4, D4, PAT_END
Pattern_5CF1:
	db L8, E4, F4, Fs4, G4, Fs4, G4, D4, E4, F4, E4, D4, C4, B3, C4, D4
	db F4, E4, F4, C4, D4, E4, D4, C4, B3, G3, A3, B3, C4, B3, C4, D4
	db E4, F4, A4, G4, F4, E4, F4, D4, E4, B3, REST, G3, REST, C4, REST, PAT_END
Pattern_5D21:
	INSTR $18, $00, $40
	TRANSPOSE $f9
	REST_ENV $27
	db L1D, REST, PAT_END
Pattern_5D2C:
	INSTR $a2, $00, $41
	REST_ENV $45
	db LEN10, F4, G4, B4, PAT_END
Pattern_5D37:
	db L8, C5, REST, REST, E5, Ds5, E5, F5, D5, REST, REST, REST, REST, G4, REST, REST
	db D5, Cs5, D5, E5, C5, REST, REST, REST, REST, G4, REST, REST, E5, Ds5, E5, F5
	db G5, A5, REST, D5, C5, PAT_END
Pattern_5D5D:
	db B4, REST, A5, G5, REST, B4, C5, REST, REST, REST, REST, REST, PAT_END
Pattern_5D6A:
	db L8, G4, REST, REST, E5, Ds5, E5, F5, G5, A5, REST, REST, REST, B4, REST, REST
	db D5, Cs5, D5, E5, F5, G5, REST, REST, REST, C5, REST, REST, E5, Ds5, E5, F5
	db G5, A5, C6, B5, A5, G5, A5, F5, G5, D5, E5, C5, REST, C6, REST, PAT_END
Pattern_5D9A:
	INSTR $28, $00, $40
	TRANSPOSE $f9
	REST_ENV $37
	db PAT_END
Pattern_5DA3:
	db L8, G5, A5, C6, E6, D6, A5, PAT_END
Pattern_5DAB:
	db L8, A5, B5, D6, Fs6, E6, B5, PAT_END
Wave_5DB3:
	db $7c, $de, $dc, $de, $dc, $de, $dc, $de, $60, $12, $10, $12, $10, $12, $10, $12
Wave_5DC3:
	db $8f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $00, $00, $00, $00, $00, $00, $00
Wave_5DD3:
	db $67, $89, $ab, $cb, $bc, $ba, $98, $76, $65, $43, $21, $01, $10, $12, $34, $56
Pattern_5DE3:
	INSTR_WAVE Wave_5DC3, $21
	TRANSPOSE $00
	db L8, REST, PAT_END
Pattern_5DEC:
	INSTR_WAVE Wave_5DB3, $21
	TRANSPOSE $00
	db L4, C4, L8, G4, REST, G4, REST, L4, G3, L8, G4, REST, G4, REST, L4, B3
	db L8, G4, REST, G4, REST, L4, C4, L8, G4, REST, G4, REST, L4, C4, L8, G4
	db REST, G4, REST, L4, F3, L8, A4, REST, A4, REST, L4, G3, L8, G4, REST, G4
	db REST, L4, C4, L8, REST, G3, A3, B3, PAT_END
Pattern_5E2B:
	db L4, C4, L8, G4, REST, G4, REST, L4, G3, L8, G4, REST, G4, REST, L4, B3
	db L8, G4, REST, G4, REST, L4, C4, L8, G4, REST, G4, REST, L4, C4, L8, G4
	db REST, G4, REST, L4, F3, L8, A4, REST, A4, REST, G3, G4, G3, REST, G3, B3
	db C4, G3, C3, REST, PAT_END
Pattern_5E60:
	INSTR_WAVE Wave_5DD3, $40
	db PAT_END
Pattern_5E65:
	db L8, C3, G3, D4, A4, E5, REST, REST, REST, REST, REST, REST, G3, PAT_END
Pattern_5E73:
	db L8, D3, A3, E4, B4, Fs5, REST, REST, REST, REST, REST, REST, A3, PAT_END
DrumKit_5E81:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $71, $00, $00, $14, $80	; $06: NR42, -, NR41, NR43, NR44
	db $49, $00, $38, $02, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $00, $34, $80	; $10: NR42, -, NR41, NR43, NR44
	db $1f, $00, $40, $02, $c0	; $15: NR42, -, NR41, NR43, NR44
Pattern_5E9B:
	DRUMKIT DrumKit_5E81
	db L8, REST, PAT_END
Pattern_5EA1:
	db L8, NOISE_10, REST, NOISE_06, REST, NOISE_06, REST, L8, NOISE_10, REST, NOISE_06, NOISE_0B, NOISE_06, REST, L8, NOISE_10
	db REST, NOISE_06, REST, NOISE_06, REST, L8, NOISE_10, REST, NOISE_06, NOISE_0B, NOISE_06, NOISE_0B, PAT_END
Pattern_5EBE:
	db L8, NOISE_10, REST, NOISE_06, REST, NOISE_06, REST, L8, NOISE_10, REST, NOISE_06, NOISE_0B, NOISE_06, REST, L8, NOISE_10
	db NOISE_0B, NOISE_06, NOISE_0B, NOISE_06, NOISE_0B, L8, NOISE_06, REST, NOISE_06, REST, PAT_END
Pattern_5ED9:
	REPEAT $08
	db NOISE_15, REST, REST
	REPEAT_END
	REPEAT $02
	db NOISE_15, NOISE_15, REST, REST, NOISE_15, REST, REST, REST, NOISE_15, REST, NOISE_15, REST
	REPEAT_END
	db PAT_END
Song44_Header:
	SONG $fd, LengthTable_5EFA, Song44_Ch1, Song44_Ch2, Song44_Ch3, Song44_Ch4
LengthTable_5EFA:
	db $02, $00, $00, $18, $30, $00, $00, $00, $00, $00, $04, $08, $06, $10, $00
Song44_Ch1:
	dw Pattern_5F41
Song44_Ch1_Loop:
	dw Pattern_5F46
	dw Pattern_5F65
	dw Pattern_5F46
	dw Pattern_5F87
	LIST_LOOP Song44_Ch1_Loop
Song44_Ch2:
	dw Pattern_5F41
Song44_Ch2_Loop:
	dw Pattern_5FA6
	dw Pattern_5FC5
	dw Pattern_5FA6
	dw Pattern_5FE7
	LIST_LOOP Song44_Ch2_Loop
Song44_Ch3:
	dw Pattern_6021
Song44_Ch3_Loop:
	dw Pattern_602D
	dw Pattern_6049
	dw Pattern_602D
	dw Pattern_6064
	LIST_LOOP Song44_Ch3_Loop
Song44_Ch4:
	dw Pattern_60B0
Song44_Ch4_Loop:
	dw Pattern_60B6
	dw Pattern_60C5
	dw Pattern_60B6
	dw Pattern_60C5
	LIST_LOOP Song44_Ch4_Loop
Pattern_5F41:
	REST_ENV $00
	db LEN13, REST, PAT_END
Pattern_5F46:
	INSTR $71, $00, $80
	TRANSPOSE $00
	REST_ENV $14
	db LEN13, REST, LEN10, G4, C5, LEN11, E5, REST, E5, L2, REST, LEN13, REST, LEN10, Cs4, E5
	db LEN11, G5, REST, G5, L2, REST, PAT_END
Pattern_5F65:
	INSTR $6b, $00, $80
	TRANSPOSE $f4
	REST_ENV $27
	db LEN11, REST, REST, F5, REST, REST, REST, Fs5, REST, REST, A5, REST, REST, C6, REST, REST
	db REST, REST, A5, REST, REST, F5, REST, REST, REST, PAT_END
Pattern_5F87:
	INSTR $6b, $00, $80
	TRANSPOSE $f4
	REST_ENV $27
	db LEN11, REST, REST, F5, REST, REST, REST, Fs5, REST, REST, Fs5, REST, REST, F5, A5, As5
	db B5, REST, D5, L4, REST, REST, PAT_END
Pattern_5FA6:
	INSTR $71, $00, $80
	TRANSPOSE $00
	REST_ENV $14
	db LEN13, REST, LEN10, C5, E5, LEN11, G5, REST, G5, L2, REST, LEN13, REST, LEN10, E5, G5
	db LEN11, As5, REST, As5, L2, REST, PAT_END
Pattern_5FC5:
	INSTR $7b, $00, $80
	TRANSPOSE $f4
	REST_ENV $27
	db LEN11, REST, REST, A5, REST, REST, Gs5, A5, REST, REST, C6, REST, REST, Ds6, REST, REST
	db D6, REST, C6, REST, REST, A5, REST, REST, REST, PAT_END
Pattern_5FE7:
	INSTR $7b, $00, $80
	TRANSPOSE $f4
	REST_ENV $27
	db LEN11, REST, REST, A5, REST, REST, Gs5, A5, REST, REST, C6, REST, REST, B5, C6, Cs6
	db D6, REST, G6
	INSTR $09, $00, $00
	TRANSPOSE $00
	REST_ENV $14
	db F5, REST, As4, Ds5, REST, Gs4, PAT_END
Wave_6011:
	db $22, $66, $aa, $ee, $ff, $ff, $fe, $ea, $a6, $66, $8a, $cf, $fe, $ec, $a6, $33
Pattern_6021:
	INSTR_WAVE Wave_6011, $23
	TRANSPOSE $0c
	db LEN11, REST, LEN10, G3, A3, PAT_END
Pattern_602D:
	db LEN11, C4, REST, REST, G3, REST, C4, REST, REST, G3, LEN13, A3, LEN11, G3, Cs4, REST
	db REST, A3, REST, Cs4, REST, REST, A3, LEN13, As3, LEN11, A3, PAT_END
Pattern_6049:
	db D4, REST, REST, L4, D4, LEN11, Ds4, REST, REST, L4, Ds4, LEN11, Gs3, REST, REST, LEN13
	db Gs3, LEN11, G3, REST, REST, G3, LEN13, A3, LEN11, G3, PAT_END
Pattern_6064:
	db D4, REST, REST, L4, D4, LEN11, Ds4, REST, REST, L4, Ds4, LEN11, G3, REST, REST, L32
	db Fs4, LEN12, G4, LEN11, REST, G3, REST, REST, G3, LEN13, A3, LEN11, G3, PAT_END
DrumKit_6082:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $41, $00, $38, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $31, $00, $38, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $87, $00, $10, $03, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $91, $00, $30, $80, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $51, $00, $00, $22, $c0	; $1a: NR42, -, NR41, NR43, NR44
	db $41, $00, $00, $23, $c0	; $1f: NR42, -, NR41, NR43, NR44
	db $92, $00, $00, $01, $80	; $24: NR42, -, NR41, NR43, NR44
	db $92, $00, $00, $01, $80	; $29: NR42, -, NR41, NR43, NR44
Pattern_60B0:
	DRUMKIT DrumKit_6082
	db LEN13, REST, PAT_END
Pattern_60B6:
	REPEAT $02
	db L4, NOISE_29, LEN13, NOISE_1A, L4, NOISE_1F, LEN11, NOISE_0B, NOISE_06, NOISE_0B, NOISE_0B
	REPEAT_END
	db PAT_END
Pattern_60C5:
	REPEAT $02
	db L4, NOISE_24, LEN11, NOISE_06, REST, NOISE_0B
	REPEAT_END
	db L4, NOISE_24, LEN13, NOISE_1F, L4, NOISE_1F, LEN11, NOISE_0B, NOISE_06, NOISE_0B, NOISE_0B, PAT_END
Song43_Header:
	SONG $fd, LengthTable_60E5, Song43_Ch1, Song43_Ch2, Song43_Ch3, Song43_Ch4
LengthTable_60E5:
	db $03, $06, $0c, $30, $6c, $d8, $1b, $36, $6c, $02, $04, $01, $12, $18, $90
Pattern_60F4:
	db L1, REST, PAT_END
Song43_Ch2:
	dw Pattern_611D
	dw Pattern_614A
Song43_Ch2_Loop:
	dw Pattern_60F4
	LIST_LOOP Song43_Ch2_Loop
Song43_Ch1:
	dw Pattern_6128
	dw Pattern_6156
Song43_Ch1_Loop:
	dw Pattern_60F4
	LIST_LOOP Song43_Ch1_Loop
Song43_Ch3:
	dw Pattern_6133
	dw Pattern_6162
Song43_Ch3_Loop:
	dw Pattern_60F4
	LIST_LOOP Song43_Ch3_Loop
Song43_Ch4:
	dw Pattern_6192
Song43_Ch4_Loop:
	dw Pattern_60F4
	LIST_LOOP Song43_Ch4_Loop
Pattern_611D:
	INSTR $58, $00, $41
	REST_ENV $00
	db L8, REST
	REST_ENV $17
	db PAT_END
Pattern_6128:
	INSTR $58, $00, $40
	REST_ENV $00
	db L8, REST
	REST_ENV $17
	db PAT_END
Pattern_6133:
	INSTR_WAVE Wave_613A, $21
	db L8, REST, PAT_END
Wave_613A:
	db $22, $66, $aa, $ee, $ff, $ff, $fe, $ea, $a6, $66, $8a, $cf, $fe, $ec, $a6, $33
Pattern_614A:
	db L16, E6, E6, REST, F6, REST, F6, REST, Fs6, L4, G6, PAT_END
Pattern_6156:
	db L16, C6, C6, REST, C6, REST, C6, REST, Cs6, L4, D6, PAT_END
Pattern_6162:
	db L16, C5, C5, REST, C5, REST, C5, REST, C5, L4, D5, PAT_END
DrumKit_616E:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $86, $00, $2b, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $41, $00, $3a, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $3a, $05, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $81, $00, $3a, $24, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $a2, $00, $3a, $24, $c0	; $1a: NR42, -, NR41, NR43, NR44
	db $26, $00, $00, $24, $80	; $1f: NR42, -, NR41, NR43, NR44
Pattern_6192:
	DRUMKIT DrumKit_616E
	db L16, NOISE_10, L32, NOISE_10, NOISE_0B, L8, NOISE_06, L16, NOISE_10, NOISE_10, L8, NOISE_06, L16, NOISE_10, NOISE_10, L32
	db NOISE_06, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_0B, NOISE_10, NOISE_10, NOISE_10, NOISE_10, NOISE_15, NOISE_15, NOISE_15, NOISE_15
	db LEN9, NOISE_1A, L2, NOISE_1F, PAT_END
Song45_Header:
	SONG $00, LengthTable_61C5, Song45_Ch1, Song45_Ch2, Song45_Ch3, Song45_Ch4
LengthTable_61C5:
	db $02, $00, $0d, $1a, $34, $68, $0b, $27, $4e, $00, $06, $00, $07, $00, $00
Song45_Ch2:
	dw Pattern_621E
Song45_Ch2_Loop:
	dw Pattern_621F
	LIST_LOOP Song45_Ch2_Loop
Song45_Ch3:
	dw Pattern_62C6
Song45_Ch3_Loop:
	dw Pattern_62CD
	LIST_LOOP Song45_Ch3_Loop
Song45_Ch4:
	dw Pattern_62F5
Song45_Ch4_Loop:
	dw Pattern_62F9
	dw Pattern_62F9
	LIST_LOOP Song45_Ch4_Loop
Envelope_61EE:
	db $e1, $00, $00, $00, $28, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_621E:
	db PAT_END
Pattern_621F:
	INSTR_ENV Envelope_61EE, $00
	TRANSPOSE $00
	REST_ENV $17
	db L8, REST, REST, C3, G3, C4, F3, REST, G3, REST, As3, REST, REST
	INSTR $58, $00, $80
	TRANSPOSE $00
	REST_ENV $17
	db L8, As4, REST, As4, REST
	INSTR $91, $00, $80
	TRANSPOSE $00
	REST_ENV $16
	db L32, D5, L8D, Ds5, L8, E5, C5, G4, REST, L32, A4, L8D, As4, L8, A4, G4
	REST_ENV $17
	db L2, REST
	INSTR $58, $00, $80
	TRANSPOSE $00
	REST_ENV $17
	db L8, As4, REST, As4, REST
	INSTR_ENV Envelope_61EE, $00
	TRANSPOSE $00
	REST_ENV $17
	db L8, REST, REST, C3, G3, C4, F3, REST, G3, REST, C4, REST, REST
	INSTR $58, $00, $80
	TRANSPOSE $00
	REST_ENV $17
	db L8, As4, REST, As4, REST
	INSTR $91, $00, $80
	TRANSPOSE $00
	REST_ENV $16
	db L32, D5, L8D, Ds5, L8, E5, C5, G4, REST, L32, A4, L8D, As4, L8, B4, C5
	REST_ENV $17
	db L2, REST
	INSTR $58, $00, $80
	TRANSPOSE $00
	REST_ENV $17
	db L8, As4, REST, As4, REST, PAT_END
Wave_62B6:
	db $13, $57, $9b, $df, $db, $97, $53, $10, $13, $57, $9b, $df, $db, $97, $53, $10
Pattern_62C6:
	INSTR_WAVE Wave_62B6, $21
	TRANSPOSE $0c
	db PAT_END
Pattern_62CD:
	REPEAT $04
	db L1, REST, L4D, REST, L8, G3, E5, G3, E5, G3
	REPEAT_END
	db PAT_END
DrumKit_62DB:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $89, $00, $39, $20, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $49, $00, $39, $20, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $c1, $00, $3c, $00, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $a1, $00, $28, $00, $80	; $15: NR42, -, NR41, NR43, NR44
Pattern_62F5:
	DRUMKIT DrumKit_62DB
	db PAT_END
Pattern_62F9:
	REPEAT $05
	db LEN10, NOISE_10, REST, LEN12, NOISE_15, REST
	REPEAT_END
	db LEN12, NOISE_10, LEN10, NOISE_10, LEN12, NOISE_06, LEN10, NOISE_0B, L8, NOISE_06, NOISE_06, NOISE_06, NOISE_0B, PAT_END
Song46_Header:
	SONG $00, LengthTable_4CFB, Song46_Ch1, Song46_Ch2, Song46_Ch3, Song46_Ch4
Song47_Header:
	SONG $02, LengthTable_4CEC, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song48_Header:
	SONG $04, LengthTable_4CDD, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song49_Header:
	SONG $05, LengthTable_4CCE, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song4A_Header:
	SONG $06, LengthTable_4CBF, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song4B_Header:
	SONG $07, LengthTable_4CB0, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song4C_Header:
	SONG $08, LengthTable_4CB0, Song47_Ch1, Song47_Ch2, Song47_Ch3, Song47_Ch4
Song47_Ch1:
	dw Pattern_639B
	dw Pattern_63A4
Song46_Ch1:
	dw Pattern_63AE
Song46_Ch1_Loop:
	dw Pattern_63D9
	dw Pattern_63D9
	LIST_LOOP Song46_Ch1_Loop
Song47_Ch2:
	dw Pattern_63ED
	dw Pattern_63A4
Song46_Ch2:
	dw Pattern_63F6
	dw Pattern_6414
Song46_Ch2_Loop:
	dw Pattern_63FF
	dw Pattern_6414
	LIST_LOOP Song46_Ch2_Loop
Song47_Ch3:
	dw Pattern_6439
Song46_Ch3:
	dw Pattern_643C
Song46_Ch3_Loop:
	dw Pattern_6457
	dw Pattern_6470
	dw Pattern_6491
	dw Pattern_6457
	dw Pattern_6470
	dw Pattern_649E
	LIST_LOOP Song46_Ch3_Loop
Song47_Ch4:
	dw Pattern_6439
Song46_Ch4:
	dw Pattern_64CE
Song46_Ch4_Loop:
	dw Pattern_64EE
	dw Pattern_64EE
	LIST_LOOP Song46_Ch4_Loop
Pattern_639B:
	INSTR $b8, $00, $83
	TRANSPOSE $00
	REST_ENV $26
	db PAT_END
Pattern_63A4:
	REPEAT $06
	db L32, G6, LEN9, A6
	REPEAT_END
	db L8, REST, PAT_END
Pattern_63AE:
	INSTR $91, $00, $80
	TRANSPOSE $00
	REST_ENV $22
	db L8, REST, A6, A6, REST, L8, A6, L16, REST, L8, A6, L16, REST, L16, A6, REST
	db L8, REST, A6, A6, REST, L8, A6, L16, REST, L32, C6, LEN9, E6, L16, G6, E6
	db C6, G5, PAT_END
Pattern_63D9:
	REPEAT $02
	db L8, REST, A6, A6, REST, L8, A6, L16, REST, L8, A6, L16, REST, L16, A6, REST
	REPEAT_END
	db PAT_END
Pattern_63ED:
	INSTR $c8, $00, $80
	TRANSPOSE $00
	REST_ENV $47
	db PAT_END
Pattern_63F6:
	INSTR $a1, $00, $40
	TRANSPOSE $00
	REST_ENV $26
	db PAT_END
Pattern_63FF:
	REPEAT $02
	db L16, D5, A4, F4, REST, Cs5, A4, F4, REST, C5, A4, F4, Cs5, F4, Cs5, A4
	db F4
	REPEAT_END
	db PAT_END
Pattern_6414:
	REPEAT $02
	db L16, C5, G4, E4, REST, B4, G4, E4, REST, A4, G4, E4, B4, E4, B4, G4
	db E4
	REPEAT_END
	db PAT_END
Wave_6429:
	db $cf, $ff, $ff, $ff, $ff, $ff, $ff, $fc, $40, $00, $00, $00, $00, $00, $00, $04
Pattern_6439:
	db L2, REST, PAT_END
Pattern_643C:
	INSTR_WAVE Wave_6429, $23
	TRANSPOSE $0c
	db L1, REST, L2, REST, L8, REST, L32, G3, LEN9, Gs3, L8D, A3, L32, G3, LEN9, G3
	db L32, E3, LEN9, Cs3, PAT_END
Pattern_6457:
	REPEAT $02
	db L8D, D3, L32, A2, LEN9, REST, L8, A2, L16, REST, D3, REST, D3, REST, L32, A2
	db LEN9, REST, L8, A2, REST
	REPEAT_END
	db PAT_END
Pattern_6470:
	db L8D, C3, L32, G2, LEN9, REST, L8, G2, L16, REST, C3, REST, C3, REST, L32, G2
	db LEN9, REST, L8, G2, REST, L8D, C3, L32, G2, LEN9, REST, L8, G2, L16, REST, C3
	db PAT_END
Pattern_6491:
	db REST, C3, REST, L32, G2, LEN9, REST, L16, G2, REST, L8, Cs3, PAT_END
Pattern_649E:
	db REST, C3, L32, G3, LEN9, Gs3, L8D, A3, L32, G3, LEN9, G3, L32, E3, LEN9, Cs3
	db PAT_END
DrumKit_64AF:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $81, $00, $3a, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $a1, $00, $3a, $37, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $91, $00, $20, $06, $80	; $10: NR42, -, NR41, NR43, NR44
	db $61, $00, $20, $06, $80	; $15: NR42, -, NR41, NR43, NR44
	db $a1, $00, $20, $06, $80	; $1a: NR42, -, NR41, NR43, NR44
Pattern_64CE:
	DRUMKIT DrumKit_64AF
	db L2D, REST, L8D, REST, L32, NOISE_15, LEN9, NOISE_15, L4, NOISE_1A, L8D, REST, L32, NOISE_15, LEN9, NOISE_15
	db L16, NOISE_1A, L8, NOISE_1A, NOISE_1A, L16, NOISE_1A, NOISE_1A, L32, NOISE_06, LEN9, NOISE_06, PAT_END
Pattern_64EE:
	REPEAT $07
	db L16, NOISE_0B, NOISE_06, NOISE_0B, NOISE_06, NOISE_06, NOISE_0B, NOISE_06, NOISE_06
	REPEAT_END
	db NOISE_0B, NOISE_06, L32, NOISE_0B, NOISE_06, LEN9, NOISE_06, NOISE_06, L16, NOISE_0B, NOISE_10, NOISE_0B, NOISE_10
	REPEAT $07
	db L16, NOISE_0B, NOISE_06, NOISE_0B, NOISE_06, NOISE_06, NOISE_0B, NOISE_06, NOISE_06
	REPEAT_END
	db L32, NOISE_15, LEN9, NOISE_15, L16, NOISE_10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_10, NOISE_10, NOISE_06, PAT_END
Wave_6520:
	db $02, $34, $67, $9a, $97, $64, $32, $00, $02, $34, $67, $9a, $97, $64, $32, $00
Song50_Header:
	SONG $00, LengthTable_4CCE, Song50_Ch1, Song50_Ch2, Song50_Ch3, Song50_Ch4
Song50_Ch2:
	dw Pattern_65E6
Song50_Ch2_Loop:
	dw Pattern_65E7
	LIST_TRANSPOSE_ADD 2
	dw Pattern_65E7
	LIST_TRANSPOSE_ADD -2
	LIST_LOOP Song50_Ch2_Loop
Song50_Ch1:
	dw Pattern_657B
Song50_Ch1_Loop:
	dw Pattern_6582
	LIST_TRANSPOSE_ADD 2
	dw Pattern_6582
	LIST_TRANSPOSE_ADD -2
	LIST_LOOP Song50_Ch1_Loop
Song50_Ch3:
	dw Pattern_65C1
Song50_Ch3_Loop:
	dw Pattern_65C8
	LIST_TRANSPOSE_ADD 2
	dw Pattern_65C8
	LIST_TRANSPOSE_ADD -2
	LIST_LOOP Song50_Ch3_Loop
Song50_Ch4:
	dw Pattern_65AB
Song50_Ch4_Loop:
	dw Pattern_65AF
	dw Pattern_65AF
	LIST_LOOP Song50_Ch4_Loop
Pattern_657B:
	INSTR $c1, $00, $01
	REST_ENV $27
	db PAT_END
Pattern_6582:
	REPEAT $04
	ENV_SET $f1
	db L16, C3, REST
	ENV_SET $b1
	db C4
	ENV_SET $f1
	db C3, L8, G2, L16, A2, REST
	REPEAT_END
	db PAT_END
DrumKit_6596:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $e1, $00, $38, $44, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $91, $00, $00, $21, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $34, $23, $c0	; $10: NR42, -, NR41, NR43, NR44
Pattern_65AB:
	DRUMKIT DrumKit_6596
	db PAT_END
Pattern_65AF:
	REPEAT $06
	db L8, NOISE_06, L16, NOISE_10, NOISE_10
	REPEAT_END
	db L16, NOISE_06, NOISE_10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_10, NOISE_0B, NOISE_1A, PAT_END
Pattern_65C1:
	INSTR_WAVE Wave_6520, $21
	TRANSPOSE $18
	db PAT_END
Pattern_65C8:
	REPEAT $02
	db L16, C4, Cs4, D4, Ds4, E4, Ds4, D4, Cs4
	REPEAT_END
	db C4, Cs4, D4, Ds4, E4, Ds4, E4, F4, G4, F4, E4, F4, L16, D4, E4, D4
	db C4, PAT_END
Pattern_65E6:
	db PAT_END
Pattern_65E7:
	INSTR $a1, $00, $01
	REST_ENV $25
	REPEAT $06
	db L16, REST, REST, E4, REST
	REPEAT_END
	INSTR $28, $00, $81
	TRANSPOSE_ADD $0c
	db B4
	ENV_ADD $10
	db C5
	ENV_ADD $10
	db B4
	ENV_ADD $10
	db C5, B4
	ENV_ADD $f0
	db C5
	ENV_ADD $f0
	db B4
	ENV_ADD $f0
	db G4
	TRANSPOSE_ADD $f4
	db PAT_END
Song51_Header:
	SONG $00, LengthTable_4CFB, Song51_Ch1, Song51_Ch2, Song51_Ch3, Song51_Ch4
Song51_Ch1:
	dw Pattern_664D
	dw Pattern_665D
Song51_Ch1_Loop:
	dw Pattern_6679
	dw Pattern_6679
	LIST_LOOP Song51_Ch1_Loop
Song51_Ch2:
	dw Pattern_668C
	dw Pattern_669E
Song51_Ch2_Loop:
	dw Pattern_66C6
	dw Pattern_66EE
	LIST_LOOP Song51_Ch2_Loop
Song51_Ch3:
	dw Pattern_66F1
	dw Pattern_66FF
Song51_Ch3_Loop:
	dw Pattern_670F
	dw Pattern_6723
	LIST_LOOP Song51_Ch3_Loop
Song51_Ch4:
	dw Pattern_6754
Song51_Ch4_Loop:
	dw Pattern_675B
	dw Pattern_675B
	dw Pattern_676D
	LIST_LOOP Song51_Ch4_Loop
Pattern_664D:
	INSTR $d2, $00, $41
	REST_ENV $26
	db L32, REST, F3, G3, A3, As3, C4, D4, Ds4, PAT_END
Pattern_665D:
	db L32, F3
	ENV_ADD $f0
	db E3
	ENV_ADD $f0
	db Ds3
	ENV_ADD $f0
	db D3
	ENV_ADD $20
	db L8, F2, REST, L16, C3, Ds3, REST, REST, G3, REST, REST, F3, REST, REST, PAT_END
Pattern_6679:
	db L16, F2, REST, L8, F2, L16, REST, REST, C3, Ds3, REST, REST, G3, REST, REST, F3
	db REST, REST, PAT_END
Pattern_668C:
	INSTR $97, $00, $41
	TRANSPOSE $f4
	REST_ENV $00
	db L32, REST, F5, G5, A5, As5, C6, D6, Ds6, PAT_END
Pattern_669E:
	db L16, F6
	ENV_ADD $c0
	db L32, Ds6
	ENV_ADD $e0
	db C6
	ENV_ADD $f0
	db As5
	ENV_ADD $f0
	db F5
	ENV_ADD $f0
	db As4
	ENV_ADD $f0
	db F4
	ENV_ADD $f0
	db As3
	ENV_ADD $f0
	db F3, L8D, REST, L2, REST
	INSTR $81, $00, $01
	TRANSPOSE $00
	REST_ENV $14
	db PAT_END
Pattern_66C6:
	db L32, F3, REST, C4, REST, F4, REST, As4, REST, C4, REST, As4, REST, C4, REST, F4
	db REST
	ENV_ADD $02
	db L8, C5
	ENV_ADD $fe
	db L32, Ds4, REST
	ENV_ADD $02
	db L8, As4
	ENV_ADD $fe
	db L32, REST, REST, As3, REST, C4, REST, PAT_END
Pattern_66EE:
	db L1, REST, PAT_END
Pattern_66F1:
	INSTR_WAVE Wave_5B02, $41
	db L32, REST, F4, G4, A4, As4, C5, D5, Ds5, PAT_END
Pattern_66FF:
	db L16, Ds5, L32, Cs5, As4, F4, As3, L16, REST, L2D, REST
	INSTR_WAVE Wave_5B22, $41
	db PAT_END
Pattern_670F:
	db L8D, REST, L32, Ds5, REST, REST, REST, Ds5, REST, L8, REST, L8, F5, L16, REST, L8
	db Ds5, L8D, REST, PAT_END
Pattern_6723:
	db L1, REST, PAT_END
DrumKit_6726:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $81, $00, $18, $24, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $71, $00, $20, $25, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $51, $00, $20, $25, $c0	; $10: NR42, -, NR41, NR43, NR44
	db $b1, $00, $34, $57, $c0	; $15: NR42, -, NR41, NR43, NR44
	db $81, $00, $34, $57, $c0	; $1a: NR42, -, NR41, NR43, NR44
	db $a1, $00, $30, $05, $c0	; $1f: NR42, -, NR41, NR43, NR44
	db $61, $00, $30, $05, $c0	; $24: NR42, -, NR41, NR43, NR44
	db $53, $00, $00, $05, $80	; $29: NR42, -, NR41, NR43, NR44
Pattern_6754:
	DRUMKIT DrumKit_6726
	db L8, NOISE_06, NOISE_1A, PAT_END
Pattern_675B:
	db L16, NOISE_15, REST, NOISE_06, NOISE_15, NOISE_1F, NOISE_10, NOISE_15, NOISE_06, NOISE_24, NOISE_10, NOISE_0B, NOISE_15, NOISE_06, NOISE_0B, NOISE_1F
	db NOISE_0B, PAT_END
Pattern_676D:
	db L32, NOISE_29, NOISE_29, NOISE_29, NOISE_29, L16, NOISE_06, NOISE_15, NOISE_1F, NOISE_10, NOISE_15, NOISE_06, NOISE_24, NOISE_10, NOISE_0B, NOISE_15
	db NOISE_06, NOISE_0B, NOISE_1F, NOISE_0B, PAT_END
Song55_Header:
	SONG $00, LengthTable_678D, Song55_Ch1, Song55_Ch2, Song55_Ch3, Song55_Ch4
LengthTable_678D:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $04, $08, $08, $10, $c0
; unreferenced
Unused_679C:
	db $00
Wave_679D:
	db $58, $ab, $98, $ab, $98, $ab, $98, $ab, $50, $23, $10, $23, $10, $23, $10, $23
DrumKit_67AD:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $51, $00, $30, $05, $c0	; $06: NR42, -, NR41, NR43, NR44
	db $31, $00, $30, $05, $c0	; $0b: NR42, -, NR41, NR43, NR44
	db $43, $00, $00, $05, $80	; $10: NR42, -, NR41, NR43, NR44
	db $51, $00, $38, $36, $c0	; $15: NR42, -, NR41, NR43, NR44
Song55_Ch1:
	dw Pattern_67EB
	dw Pattern_6805
Song55_Ch1_Loop:
	dw Pattern_67F4
	dw Pattern_6830
	LIST_LOOP Song55_Ch1_Loop
Song55_Ch2:
	dw Pattern_67FD
Song55_Ch2_Loop:
	dw Pattern_6828
	LIST_LOOP Song55_Ch2_Loop
Song55_Ch3:
	dw Pattern_6882
Song55_Ch3_Loop:
	dw Pattern_68AD
	LIST_LOOP Song55_Ch3_Loop
Song55_Ch4:
	dw Pattern_68F6
Song55_Ch4_Loop:
	dw Pattern_68FD
	LIST_LOOP Song55_Ch4_Loop
Pattern_67EB:
	INSTR $74, $00, $83
	TRANSPOSE $18
	REST_ENV $00
	db PAT_END
Pattern_67F4:
	INSTR $36, $00, $83
	TRANSPOSE $0c
	REST_ENV $00
	db PAT_END
Pattern_67FD:
	INSTR $83, $00, $80
	TRANSPOSE $18
	REST_ENV $00
Pattern_6805:
	db LEN11, G4, A4, As4, B4, LEN13, REST, L2, REST
	REST_ENV $24
	ENV_ADD $e0
	TRANSPOSE_ADD $e8
	db LEN11, G2, A2, As2, B2, A2, G2, L8, REST, LEN12, REST
	ENV_ADD $f0
	TRANSPOSE_ADD $18
	db LEN10, Fs4, L4, G4, PAT_END
Pattern_6828:
	INSTR $46, $00, $80
	TRANSPOSE $0c
	REST_ENV $00
Pattern_6830:
	db LEN13, E5, LEN11, Ds5, LEN13, E5, L4, G5, LEN11, E5, LEN13, Ds5, LEN11, E5, L4, G4
	db LEN13, E5, LEN11, Ds5, LEN13, E5, L4, G5, LEN11, REST, LEN13, D5, LEN11, Cs5, LEN13, D5
	db L4, F5, LEN11, D5, LEN13, Cs5, LEN11, D5, L4, G4, L2D, REST, LEN13, D5, LEN11, Cs5
	db LEN13, D5, L4, F5, LEN11, D5, LEN13, Cs5, LEN11, D5, L4, B4, B4, C5, D5, LEN13
	db E5, LEN11, Ds5, LEN13, E5, L4, G5, LEN11, Ds5, LEN13, D5, L4, C5, LEN11, REST, L2D
	db REST, PAT_END
Pattern_6882:
	INSTR_WAVE Wave_679D, $23
	TRANSPOSE $0c
	INSTR_WAVE Wave_6520, $21
	TRANSPOSE $18
	db L2, REST, LEN11, G3, A3, As3, LEN13, B3, LEN11, REST
	TRANSPOSE_ADD $f4
	db LEN11, G2, A2, As2, B2, A2, G2, L8, REST, LEN12, REST
	TRANSPOSE_ADD $0c
	db LEN10, Fs3, L8, G3, REST, PAT_END
Pattern_68AD:
	INSTR_WAVE Wave_679D, $23
	TRANSPOSE $0c
	REPEAT $02
	db L8, C3, REST, REST, REST, G2, REST, REST, REST
	REPEAT_END
	db B2, REST, REST, REST, G2, REST, REST, REST, B2, REST, LEN11, G2, REST, G2, L4, Gs2
	db L8, G2, REST, B2, REST, REST, REST, G2, REST, REST, REST, G2, REST, G2, REST, A2
	db REST, B2, REST, C3, REST, REST, REST, G2, REST, REST, REST, LEN11, C3, REST, C3, L8
	db G3, REST, F3, REST, D3, REST, PAT_END
Pattern_68F6:
	DRUMKIT DrumKit_67AD
	db L1, REST, REST, PAT_END
Pattern_68FD:
	REPEAT $03
	db L4, NOISE_06, LEN13, NOISE_10, LEN11, NOISE_06, L4, NOISE_06, NOISE_10
	REPEAT_END
	db L4, NOISE_06, NOISE_15, NOISE_15, LEN11, NOISE_06, NOISE_0B, NOISE_0B, L4, NOISE_06, LEN13, NOISE_10, LEN11, NOISE_06, L4, NOISE_06
	db NOISE_10, L4, NOISE_06, NOISE_10, NOISE_10, NOISE_10, L4, NOISE_06, LEN13, NOISE_10, LEN11, NOISE_06, L4, NOISE_06, NOISE_10, L4
	db NOISE_06, NOISE_15, NOISE_15, LEN11, NOISE_06, NOISE_0B, NOISE_0B, PAT_END
; unreferenced length table
Unused_6931:
	db $02, $04, $08, $10, $20, $00, $0c, $18, $00, $02, $00, $00, $00, $40, $80
Song42_Header:
	SONG $00, LengthTable_694B, Song42_Ch1, Song42_Ch2, Song42_Ch3, Song42_Ch4
LengthTable_694B:
	db $06, $05, $0a, $14, $28, $50, $0f, $1e, $32, $39, $02, $3c, $03, $08, $07
Song42_Ch4:
	dw Pattern_69DF
	dw Pattern_6C88
Song42_Ch4_Loop:
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C99
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CB7
	LIST_LOOP Song42_Ch4_Loop
Song42_Ch3:
	dw Pattern_69DA
Song42_Ch3_Loop:
	dw Pattern_6BEB
	dw Pattern_6BEB
	dw Pattern_6C2B
	dw Pattern_6C2E
	dw Pattern_6C3D
	dw Pattern_6C45
	dw Pattern_6C45
	dw Pattern_6C6A
	LIST_LOOP Song42_Ch3_Loop
Song42_Ch2:
	dw Pattern_6B26
Song42_Ch2_Loop:
	dw Pattern_6B29
	dw Pattern_6B49
	dw Pattern_6B2F
	dw Pattern_6B5B
	dw Pattern_6B6B
	dw Pattern_6B7C
	dw Pattern_6B7C
	dw Pattern_6B85
	dw Pattern_6BD7
	dw Pattern_6BB0
	dw Pattern_6BE6
	dw Pattern_6B26
	LIST_LOOP Song42_Ch2_Loop
Song42_Ch1:
	dw Pattern_6B26
Song42_Ch1_Loop:
	dw Pattern_6A4A
	dw Pattern_6A6A
	dw Pattern_6A50
	dw Pattern_6A7C
	dw Pattern_6A98
	dw Pattern_6AA9
	dw Pattern_6AB2
	dw Pattern_6ABE
	dw Pattern_6B12
	dw Pattern_6AEB
	dw Pattern_6B21
	dw Pattern_6B26
	LIST_LOOP Song42_Ch1_Loop
Pattern_69DA:
	INSTR_WAVE Wave_5B22, $20
	db PAT_END
Pattern_69DF:
	DRUMKIT DrumKit_6CC7
	db PAT_END
Pattern_69E3:
	INSTR $76, $00, $80
	REST_ENV $26
	db PAT_END
Envelope_69EA:
	db $69, $00, $00, $3f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $78, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Envelope_6A1A:
	db $8a, $00, $00, $3e, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $88, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_6A4A:
	INSTR $76, $00, $80
	REST_ENV $26
Pattern_6A50:
	db L8, C3
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db L8, C3
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db L8, D3, L16, A3, REST, A3, REST, A3, REST, PAT_END
Pattern_6A6A:
	db L8, D3, L16, G3, REST, G3, REST, G3, REST, L8, C3
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db PAT_END
Pattern_6A7C:
	db L8, E3, L16, B3, REST, B3, REST, B3, REST, L8, A3, L16, A4, REST, A4, REST
	db A4, REST, L8, G3, L16, G4, REST, G4, REST, G4, REST, PAT_END
Pattern_6A98:
	db LEN13, A3, L1D, REST, L16, A3, REST, L8D, REST, L16, B3, REST, B3, REST, L4, REST
	db PAT_END
Pattern_6AA9:
	db L8, REST
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db PAT_END
Pattern_6AB2:
	db L8, REST
	REPEAT $06
	db L16, G3, REST
	REPEAT_END
	db G3, LEN12, REST, PAT_END
Pattern_6ABE:
	INSTR_ENV Envelope_6A1A, $01
	REST_ENV $47
	db LEN10, REST, L4, Ds5, L8D, D5, L16, Ds5, L4, F5, L8D, Ds5, L16, F5, L4, G5
	db L8D, F5, L16, G5, L4, C5, L8D, C5, L16, D5, L4, Ds5, L8D, D5, L16, Ds5
	db L4, F5, L8D, Ds5, L16, F5, PAT_END
Pattern_6AEB:
	ENV_SET $66
	db L4, Ds6, L8D, D6, L16, Ds6, L4, F6, L8D, Ds6, L16, F6, L4, G6, L8D, F6
	db L16, G6, L4, C6, L8D, C6, L16, D6, L4, Ds6, L8D, D6, L16, Ds6, L4, F6
	db L8D, Ds6, L16, F6, PAT_END
Pattern_6B12:
	db L2, G5, L4, C6
	INSTR_ENV Envelope_69EA, $81
	REST_ENV $26
	db L8D, C6, L16, D6, PAT_END
Pattern_6B21:
	db L2, D6, L4, G6, PAT_END
Pattern_6B26:
	db L4, REST, PAT_END
Pattern_6B29:
	INSTR $76, $00, $80
	REST_ENV $26
Pattern_6B2F:
	db L8, G3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, G3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, A3, L16, C4, REST, C4, REST, C4, REST, PAT_END
Pattern_6B49:
	db L8, G3, L16, B3, REST, B3, REST, B3, REST, L8, G3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db PAT_END
Pattern_6B5B:
	db L8, Gs3, L16, E4, REST, E4, REST, E4, REST
	REPEAT $08
	db L16, C4, E4
	REPEAT_END
	db PAT_END
Pattern_6B6B:
	db LEN13, F4, L1D, REST, L16, F4, REST, L8D, REST, L16, G4, REST, G4, REST, L4, REST
	db PAT_END
Pattern_6B7C:
	db L8, REST
	REPEAT $07
	db L16, E3, REST
	REPEAT_END
	db PAT_END
Pattern_6B85:
	INSTR_ENV Envelope_6A1A, $01
	REST_ENV $47
	db L4, Gs4, L8D, Gs4, L16, Gs4, L4, D5, L8D, C5, L16, D5, L4, Ds5, L8D, D5
	db L16, Ds5, L4, Gs4, L8D, Gs4, L16, As4, L4, Gs4, L8D, Gs4, L16, Gs4, L4, D5
	db L8D, C5, L16, D5, PAT_END
Pattern_6BB0:
	ENV_SET $66
	db L4, Gs5, L8D, Gs5, L16, Gs5, L4, D6, L8D, C6, L16, D6, L4, Ds6, L8D, D6
	db L16, Ds6, L4, Gs5, L8D, Gs5, L16, As5, L4, Gs5, L8D, Gs5, L16, Gs5, L4, D6
	db L8D, C6, L16, D6, PAT_END
Pattern_6BD7:
	db L2, Ds5, L4, G5
	INSTR_ENV Envelope_69EA, $81
	REST_ENV $26
	db L8D, Gs5, L16, As5, PAT_END
Pattern_6BE6:
	db L2, B5, L4, B5, PAT_END
Pattern_6BEB:
	db LEN13, G5, L1D, REST, L16, G5, LEN9, C6, LEN12, REST, L8D, C6, L16, E6, L8, G6
	db L16, C7, REST, B6, REST, A6, REST, L8D, G6, L16, REST, L8, E6, L16, REST, LEN12
	db G6, LEN10, REST, L8D, F6, L16, REST, L8, D6, L16, REST, LEN12, E6, LEN10, REST, L8D
	db D6, L16, REST, L8, E6, L16, REST, LEN12, D6, LEN10, REST, L2D, C6, L8, REST, PAT_END
Pattern_6C2B:
	db L4, REST, PAT_END
Pattern_6C2E:
	db L8D, C6, L16, C6, D6, REST, L4, E6, L16, C6, REST, L8, D6, C6, PAT_END
Pattern_6C3D:
	db L4, C3, LEN11, REST, L4, C3, LEN11, REST
Pattern_6C45:
	db L16, F2, C3, Gs3, F3, Gs3, F3, Gs3, F3, L16, As2, F3, As3, F3, As3, F3
	db As3, F3, L16, Ds2, As2, G3, Ds3, G3, Ds3, G3, Ds3, L16, Gs2, Ds3, Gs3, Ds3
	db Gs3, Ds3, Gs3, Ds3, PAT_END
Pattern_6C6A:
	db L16, F2, C3, F3, C3, F3, C3, F3, C3, As2, F3, As3, F3, As3, F3, As3
	db F3
	REPEAT $02
	db L16, G2, REST, G2, D3
	REPEAT_END
	db L16, G3, L8D, REST, PAT_END
Pattern_6C88:
	db L4, REST, PAT_END
Pattern_6C8B:
	REPEAT $03
	db L8, NOISE_06, L16, NOISE_0B, NOISE_0B
	REPEAT_END
	db L16, NOISE_06, NOISE_0B, NOISE_0B, NOISE_0B, PAT_END
Pattern_6C99:
	db L8, NOISE_06, L16, NOISE_0B, NOISE_0B, L8, NOISE_06, L16, NOISE_0B, NOISE_0B, L8, NOISE_10, NOISE_10, L4, REST, PAT_END
Pattern_6CA9:
	REPEAT $03
	db L8, NOISE_15, L16, NOISE_1A, NOISE_1A
	REPEAT_END
	db L16, NOISE_15, NOISE_1A, NOISE_1A, NOISE_1A, PAT_END
Pattern_6CB7:
	db L8, NOISE_15, L16, NOISE_1A, NOISE_1A, L8, NOISE_15, L16, NOISE_1A, NOISE_1A, L8, NOISE_1F, REST, L4, REST, PAT_END
DrumKit_6CC7:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; $01: NR42, -, NR41, NR43, NR44
	db $51, $00, $00, $30, $80	; $06: NR42, -, NR41, NR43, NR44
	db $51, $00, $00, $07, $80	; $0b: NR42, -, NR41, NR43, NR44
	db $61, $00, $00, $07, $80	; $10: NR42, -, NR41, NR43, NR44
	db $41, $00, $00, $30, $80	; $15: NR42, -, NR41, NR43, NR44
	db $41, $00, $00, $07, $80	; $1a: NR42, -, NR41, NR43, NR44
	db $41, $00, $00, $20, $80	; $1f: NR42, -, NR41, NR43, NR44
Song67_Header:
	SONG $00, LengthTable_694B, Song67_Ch1, Song67_Ch2, Song67_Ch3, Song67_Ch4
Song67_Ch1:
	dw Pattern_6B26
	dw Pattern_6A4A
	dw Pattern_6A6A
	dw Pattern_6A50
	dw Pattern_6A7C
	dw Pattern_6A98
	dw Pattern_6AA9
	dw Pattern_6AB2
	dw Pattern_6ABE
	dw Pattern_6B12
	dw Pattern_6AEB
	dw Pattern_6B21
	dw Pattern_6B26
	dw Pattern_69E3
	dw Pattern_6A50
	dw Pattern_6A6A
	LIST_LOOP UnusedList_6DB2
Song67_Ch2:
	dw Pattern_6B26
	dw Pattern_6B29
	dw Pattern_6B49
	dw Pattern_6B2F
	dw Pattern_6B5B
	dw Pattern_6B6B
	dw Pattern_6B7C
	dw Pattern_6B7C
	dw Pattern_6B85
	dw Pattern_6BD7
	dw Pattern_6BB0
	dw Pattern_6BE6
	dw Pattern_6B26
	dw Pattern_69E3
	dw Pattern_6B2F
	dw Pattern_6D3E
	LIST_LOOP UnusedList_6E86
Pattern_6D3E:
	db L8, G3, L16, B3, REST, B3, REST, B3, REST, L8, G3
	REPEAT $06
	db L16, E4, REST
	REPEAT_END
	db E4, PAT_END
Song67_Ch3:
	dw Pattern_69DA
	dw Pattern_6BEB
	dw Pattern_6BEB
	dw Pattern_6C2B
	dw Pattern_6C2E
	dw Pattern_6C3D
	dw Pattern_6C45
	dw Pattern_6C45
	dw Pattern_6C6A
	dw Pattern_6D69
	LIST_LOOP UnusedList_6FBF
Pattern_6D69:
	db L1, REST, REST, REST, L2, REST, L4, REST, L16, REST, D5, E5, Fs5, G5, A5, B5
	db LEN12, C6, PAT_END
Song67_Ch4:
	dw Pattern_69DF
	dw Pattern_6C88
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C99
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6CA9
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	LIST_LOOP UnusedList_70CD
UnusedList_6DB2:
	dw Pattern_6DC6
	dw Pattern_6DFD
	dw Pattern_6DCE
	dw Pattern_6E18
	dw Pattern_6E3E
	dw Pattern_6E5F
	dw Pattern_6E46
	dw Pattern_6E66
	LIST_LOOP UnusedList_7111
Pattern_6DC6:
	INSTR $67, $00, $80
	REST_ENV $27
	TRANSPOSE $00
Pattern_6DCE:
	db L2, D6, L4, G6, L8, D6, REST, L16, B5, C6, Cs6, REST, L8, REST, D6, L2
	db REST, L4, E6, L8, E6, C6, L4, D6, L8, E6, REST, L16, C5, D5, E5, REST
	db L8, REST, A6, L2, REST, L4D, Fs6, L8, Fs6, G6, L4, Fs6, L8, REST, PAT_END
Pattern_6DFD:
	db L4, D6, E6, L8, Fs6, L4D, REST, L4, G6, L8, G6, G6, A6, B6, REST, REST
	db L16, B4, C5, D5, REST, L8, REST, D6, L2, REST, PAT_END
Pattern_6E18:
	db L4, D6, Fs6, L8, A6, L4D, REST, L4, G6, L8, G6, G6, Fs6, F6
	ENV_ADD $10
	db L16, G3, REST, D4, REST, G4, REST, D5, REST, B4, REST, G4, REST, F4, REST, D4
	db REST, B3, REST, G3, REST, PAT_END
Pattern_6E3E:
	INSTR $72, $00, $81
	REST_ENV $27
	TRANSPOSE $00
Pattern_6E46:
	REPEAT $10
	db L16, E4, G4
	REPEAT_END
	REPEAT $10
	db L16, D4, G4
	REPEAT_END
	REPEAT $08
	db L16, D4, Fs4
	REPEAT_END
	REPEAT $08
	db L16, C4, Fs4
	REPEAT_END
	db PAT_END
Pattern_6E5F:
	REPEAT $10
	db L16, D4, G4
	REPEAT_END
	db PAT_END
Pattern_6E66:
	db L16, E5, REST, E5, REST, Ds5, REST, Ds5, REST, D5, REST, D5, REST, Cs5, REST, Cs5
	db LEN10, REST, LEN12, B4, L16, C5, REST, L8, REST, C5, L16, B4, REST, L4D, REST, PAT_END
UnusedList_6E86:
	dw Pattern_6E9A
	dw Pattern_6ED3
	dw Pattern_6EA4
	dw Pattern_6EF8
	dw Pattern_6F27
	dw Pattern_6F81
	dw Pattern_6F30
	dw Pattern_6F9D
	LIST_LOOP UnusedList_7194
Pattern_6E9A:
	INSTR $47, $00, $83
	REST_ENV $27
	TRANSPOSE $00
	db L16, REST
Pattern_6EA4:
	db L2, D6, L4, G6, L8, D6, REST, L16, G5, A5, As5, REST, L8, REST, B5, L2
	db REST, L4, E6, L8, E6, C6, L4, D6, L8, E6, REST, L16, A4, B4, C5, REST
	db L8, REST, E6, L2, REST, L4D, Fs6, L8, Fs6, G6, L4, Fs6, L8, REST, PAT_END
Pattern_6ED3:
	db L16, A5, REST, Fs5, REST, C6, REST, A5, REST, D6, REST, A5, REST, Fs5, REST, D5
	db REST, L4, G6, L8, G6, G6, A6, B6, REST, REST, L16, G4, A4, B4, REST, L8
	db REST, B5, L2, REST, PAT_END
Pattern_6EF8:
	db L16, A5, REST, Fs5, REST, D6, REST, A5, REST, Fs6, REST, A5, REST, Fs5, REST, D5
	db REST, L4, G6, L8, G6, G6, Fs6, F6
	ENV_ADD $10
	db L16, D3, REST, B3, REST, D4, REST, B4, REST, G4, REST, F4, REST, D4, REST, B3
	db REST, G3, REST, F3, PAT_END
Pattern_6F27:
	INSTR $72, $00, $81
	REST_ENV $27
	TRANSPOSE $00
	db REST
Pattern_6F30:
	REPEAT $08
	db L16, C4, E4
	REPEAT_END
	ENV_ADD $03
	db L16, C5, B4, L8, C5, REST, L4, C5, L8, B4, L16, C5, B4, G4, E4
	ENV_ADD $fd
	REPEAT $08
	db L16, B3, D4
	REPEAT_END
	ENV_ADD $03
	db L16, B4, As4, L8, B4, REST, L4, B4, L8, As4, L16, B4, A4, G4, D4
	ENV_ADD $fd
	REPEAT $08
	db L16, A3, D4
	REPEAT_END
	ENV_ADD $03
	db L16, A4, Gs4, L8, A4, L16, C5, B4, L8, C5, L16, D5, Cs5, L8, D5, L16
	db Cs5, D5, E5, Fs5
	ENV_ADD $fd
	db PAT_END
Pattern_6F81:
	REPEAT $08
	db L16, B3, D4
	REPEAT_END
	ENV_ADD $03
	db L16, G4, A4, B4, C5, D5, C5, B4, A4, G4, A4, G4, F4, E4, F4, E4
	db D4
	ENV_ADD $fd
	db PAT_END
Pattern_6F9D:
	db L16, E5, REST, E5, REST, Ds5, REST, Ds5, REST, D5, REST, D5, REST, Cs5, REST, Cs5
	db LEN10, REST, LEN12, B4, L16, C5, REST, L8, REST, C5, L16, B4, REST, L4, REST, L16
	db REST, PAT_END
UnusedList_6FBF:
	dw Pattern_6FE3
	dw Pattern_7027
	dw Pattern_6FEB
	dw Pattern_7038
	dw Pattern_7051
	dw Pattern_708C
	dw Pattern_7059
	dw Pattern_70AE
	LIST_LOOP UnusedList_7222
Wave_6FD3:
	db $77, $77, $77, $77, $77, $77, $77, $77, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_6FE3:
	INSTR_WAVE Wave_6FD3, $23
	TRANSPOSE $0c
	db LEN10, REST
Pattern_6FEB:
	db L8, G3
	REPEAT $07
	db L16, D4, REST
	REPEAT_END
	db L8, G3
	REPEAT $07
	db L16, D4, REST
	REPEAT_END
	db L8, A3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, A3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, B3
	REPEAT $07
	db L16, Fs4, REST
	REPEAT_END
	db L8, D4, L16, Fs4, REST, L8, C4, L16, Fs4, REST, L8, A3, L16, Fs4, REST, Fs4
	db REST, Fs4, REST, PAT_END
Pattern_7027:
	db L8, G3
	REPEAT $07
	db L16, D4, REST
	REPEAT_END
	db L8, G3
	REPEAT $07
	db L16, D4, REST
	REPEAT_END
	db PAT_END
Pattern_7038:
	db L8, G3
	REPEAT $07
	db L16, D4, REST
	REPEAT_END
	db L8, F3
	REPEAT $03
	db L16, D4, REST
	REPEAT_END
	REPEAT $03
	db D4, REST
	REPEAT_END
	db D4, LEN12, REST, PAT_END
Pattern_7051:
	INSTR_WAVE Wave_5B22, $21
	db LEN10, REST
	TRANSPOSE $00
Pattern_7059:
	db L2D, E5, L8, REST, L8D, G5, L16, REST, L2D, C6, L8, REST, L8D, E5, L16, REST
	db L2D, D5, L8, REST, L8D, B5, L16, REST, LEN9, G5, L4, REST, LEN12, REST, L2D, A5
	db L8, REST, L8D, Fs5, L16, REST, L8D, D5, L16, REST, L8D, E5, L16, REST, L4D, Fs5
	db L8, REST, PAT_END
Pattern_708C:
	db L8D, G5, L16, REST, G5, REST, G5, REST, L8, A5, L16, B5, L16, REST, L4, REST
	db L16, E4, F4, G4, A4, B4, A4, G4, F4, E4, F4, E4, D4, C4, D4, C4
	db B3, PAT_END
Pattern_70AE:
	db L16, G5, REST, G5, REST, Fs5, REST, Fs5, REST, F5, REST, F5, REST, E5, REST, E5
	db LEN10, REST, LEN12, D5, L16, Ds5, REST, L8, REST, Ds5, L16, D5, L8D, REST, PAT_END
UnusedList_70CD:
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	LIST_LOOP UnusedList_72ED
UnusedList_7111:
	dw Pattern_7125
	dw Pattern_7148
	dw Pattern_712D
	dw Pattern_714D
	dw Pattern_7152
	dw Pattern_717C
	dw Pattern_7156
	dw Pattern_7187
	LIST_LOOP UnusedList_7315
Pattern_7125:
	INSTR $84, $00, $80
	REST_ENV $00
	TRANSPOSE $00
Pattern_712D:
	db L16, Fs4, G4, L4, A4, L8, Fs4, L4, A4, Cs5, L2, D5, L4, REST, L8, Fs4
	db G4, A4, L4, G4, L8, Fs4, L4, G4, A4, B4, PAT_END
Pattern_7148:
	db L2, A4, L4, REST, PAT_END
Pattern_714D:
	db L8, Cs5, L4, Cs5, PAT_END
Pattern_7152:
	ENV_ADD $d3
	db L16, REST
Pattern_7156:
	db L16, D5, E5, Fs5, G5, A5, B5, Cs6, L8, D6, Cs6, D6, L4, A5, L8, G6
	db Fs6, L4, E6, L8, D6, L2, D6, L16, G5, A5, B5, Cs6, L8, D6, Cs6, D6
	db L4, E6, L8, D6, E6, PAT_END
Pattern_717C:
	db L4, Fs6, L16, A4, B4, Cs5, D5, Cs5, B4, A4, PAT_END
Pattern_7187:
	db L4, F6, L8, E6, F6, G6, A6, G6, F6, E6, L2, D6, PAT_END
UnusedList_7194:
	dw Pattern_71A8
	dw Pattern_71CC
	dw Pattern_71B2
	dw Pattern_71D2
	dw Pattern_71DA
	dw Pattern_7202
	dw Pattern_71DE
	dw Pattern_720F
	LIST_LOOP UnusedList_73CC
Pattern_71A8:
	INSTR $84, $00, $80
	REST_ENV $00
	TRANSPOSE $00
	db L16, REST
Pattern_71B2:
	db L16, D4, E4, L4, Fs4, L8, D4, L4, Fs4, A4, L2, B4, L4, REST, L8, D4
	db E4, Fs4, L4, E4, L8, D4, L4, E4, Fs4, PAT_END
Pattern_71CC:
	db G4, L2, Fs4, L4, REST, PAT_END
Pattern_71D2:
	db Fs4, L8, As4, L4, As4, LEN12, REST, PAT_END
Pattern_71DA:
	ENV_ADD $d3
	db LEN10, REST
Pattern_71DE:
	db L16, B4, Cs5, D5, E5, Fs5, G5, A5, L4D, A5, L4, Fs5, L8, E6, D6, L4
	db Cs6, L8, B5, L2, B5, L16, E5, Fs5, G5, A5, L8, B5, A5, B5, L4, Cs6
	db L8, B5, Cs6, PAT_END
Pattern_7202:
	db L8, D6, L16, Fs4, G4, Fs4, G4, A4, B4, A4, G4, Fs4, PAT_END
Pattern_720F:
	db L4, D6, L8, C6, D6, E6, F6, E6, D6, C6
	REPEAT $04
	db L16, G4, A4, D5, A4
	REPEAT_END
	db PAT_END
UnusedList_7222:
	dw Pattern_7248
	dw Pattern_7258
	dw Pattern_727B
	dw Pattern_7258
	dw Pattern_7287
	dw Pattern_7293
	dw Pattern_72B7
	dw Pattern_7293
	dw Pattern_72CA
	LIST_LOOP UnusedList_747F
Wave_7238:
	db $99, $99, $99, $99, $99, $99, $99, $99, $00, $00, $00, $00, $00, $00, $00, $00
Pattern_7248:
	INSTR_WAVE Wave_7238, $21
	TRANSPOSE $00
	db L16, G3, G4, G5, G4, G3, REST
	TRANSPOSE $0c
	db PAT_END
Pattern_7258:
	REPEAT $03
	db L16, D3, REST, D3, D3
	REPEAT_END
	db D3, D3, D3, D3
	REPEAT $03
	db B2, REST, B2, B2
	REPEAT_END
	db B2, B2, B2, B2
	REPEAT $03
	db G2, REST, G2, G2
	REPEAT_END
	db G2, G2, G2, G2, PAT_END
Pattern_727B:
	REPEAT $03
	db A2, REST, A2, A2
	REPEAT_END
	db A2, A2, A2, A2, PAT_END
Pattern_7287:
	REPEAT $03
	db Fs2, REST, Fs2, Fs2
	REPEAT_END
	db Fs2, Fs2, Fs2, Fs2, PAT_END
Pattern_7293:
	REPEAT $02
	db D3, REST, D3, D3
	REPEAT_END
	REPEAT $02
	db Cs3, REST, Cs3, Cs3
	REPEAT_END
	REPEAT $02
	db B2, REST, B2, B2
	REPEAT_END
	REPEAT $02
	db A2, REST, A2, A2
	REPEAT_END
	REPEAT $02
	db G2, REST, G2, G2
	REPEAT_END
	db PAT_END
Pattern_72B7:
	REPEAT $02
	db G2, REST, G2, G2
	REPEAT_END
	REPEAT $03
	db A2, REST, A2, A2
	REPEAT_END
	db A2, A2, A2, A2, PAT_END
Pattern_72CA:
	REPEAT $02
	db G2, REST, G2, G2
	REPEAT_END
	REPEAT $02
	db As2, REST, As2, As2
	REPEAT_END
	REPEAT $02
	db C3, REST, C3, C3
	REPEAT_END
	REPEAT $04
	db D3, REST, D3, D3
	REPEAT_END
	db D3, L8D, REST, L4, REST, REST, PAT_END
UnusedList_72ED:
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	LIST_LOOP UnusedList_753E
UnusedList_7315:
	dw Pattern_731B
	LIST_LOOP UnusedList_754C
Pattern_731B:
	INSTR $53, $00, $80
	TRANSPOSE $0c
	db L2, REST
	REST_ENV $25
	db L8D, A4, L16, REST, D5, REST, C5, REST, B4, REST, A4, REST, G4, REST, F4, REST
	TEMPO LengthTable_4CBF
	db L4D, E4, L8, F4, E4, F4, L4, G4, L2, C5, L2, B4, L4, A4, L2D, A4
	db L4, REST, L8, D4, E4, D4, E4, L4, F4, B4, A4, L8, A4, B4, L2D, G4
	db L8, B3, A3, G3, F3, L4D, E4, L8, F4, E4, F4, L4, G4, L2, C5, L2
	db B4, L4, A4, L2D, A4, L4, C5, As4, Gs4, C5, L8, As4, A4, As4, C5
	ENV_ADD $f4
	db L4D, D5, L8, E5, D5, E5, L4, F5, D5, F5, L2, E5, L8, E5, F5, L4
	db G5, F5, E5, L4D, D5, L8, E5, D5, E5, L4, F5, D5, F5, L4, G5, E5
	db G5, L8, C6
	ENV_ADD $0f
	db F5, G5, A5, As5, C6, L4D, D6, L8, C6, L4, As5, A5, As5, C6, L2, G5
	db L8, E5, F5, L4, G5, E5, F5, L4D, E5, L8, Ds5, L4, E5, L4D, Ds5, L8
	db D5, L4, Ds5, L4D, D5, L8, Cs5, L4, D5, L4D, Cs5, L8, C5, PAT_END
UnusedList_73CC:
	dw Pattern_73D2
	LIST_LOOP UnusedList_7615
Pattern_73D2:
	INSTR $53, $00, $83
	REST_ENV $25
	TRANSPOSE $0c
	db L8D, Fs4, L16, REST, B4, REST, A4, REST, G4, REST, F4, REST, E4, REST, D4, REST
	db L4D, C4, L8, D4, C4, D4, L4, E4, L2, G4, L2, G4, L4, F4, L2D, F4
	db L4, REST, L8, B3, C4, B3, C4, L4, D4, G4, F4, L8, F4, G4, L2D, E4
	db L8, G3, F3, E3, D3, L4D, C4, L8, D4, C4, D4, L4, E4, L2, G4, L2
	db G4, L4, F4, L2D, F4, L4, Gs4, L2, Ds4, L4, Gs4, L8, As4, A4, As4, C5
	ENV_ADD $f4
	db L4D, D5, L8, E5, D5, E5, L4, F5, D5, F5, L2, E5, L8, E5, F5, L4
	db G5, F5, E5, L4D, D5, L8, E5, D5, E5, L4, F5, D5, F5, L4, G5, E5
	db G5, L8, C6
	ENV_ADD $0f
	db D5, E5, F5, G5, A5, L4D, As5, L8, A5, L4, G5, F5, G5, A5, L2, E5
	db L8, C5, D5, L4, E5, C5, D5, L2D, Gs4, G4, L2D, Fs4, F4, PAT_END
Wave_746F:
	db $7a, $bc, $ba, $bc, $ba, $bc, $ba, $bc, $50, $12, $10, $12, $10, $12, $10, $12
UnusedList_747F:
	dw Pattern_7485
	LIST_LOOP UnusedList_76DE
Pattern_7485:
	INSTR_WAVE Wave_746F, $21
	TRANSPOSE $0c
	db L4, REST
	REPEAT $02
	db L4, C3, L8, G3, REST, G3, REST
	REPEAT_END
	REPEAT $02
	db L4, F2, L8, A3, REST, A3, REST
	REPEAT_END
	REPEAT $02
	db L4, G2, L8, G3, REST, G3, REST
	REPEAT_END
	db L4, C3, L8, G3, REST, G3, REST, L4, G2, L8, F3, REST, F3, REST
	REPEAT $02
	db L4, C3, L8, G3, REST, G3, REST
	REPEAT_END
	REPEAT $02
	db L4, F2, L8, A3, REST, A3, REST
	REPEAT_END
	db L4, Gs2, L8, Gs3, REST, Gs3, REST, L4, As2, L8, As3, REST, As3, REST
	INSTR_WAVE Wave_5B22, $41
	REPEAT $02
	db L8, D4, F4, A4, C5, A4, F4
	REPEAT_END
	REPEAT $02
	db L8, E4, G4, B4, D5, B4, G4
	REPEAT_END
	REPEAT $02
	db L8, D4, F4, A4, C5, A4, F4
	REPEAT_END
	db L8, E4, G4, E5, C5, E5, G5, L8, C6, REST, L2, REST
	INSTR_WAVE Wave_746F, $21
	REPEAT $02
	db L4, F3, L8, C4, REST, C4, REST
	REPEAT_END
	REPEAT $02
	db L4, E3, L8, C4, REST, C4, REST
	REPEAT_END
	db L4, E3, L8, B3, REST, B3, REST, L4, Ds3, L8, As3, REST, As3, REST, L4, D3
	db L8, A3, REST, A3, REST, L4, Cs3, L8, Gs3, REST, Gs3, REST, PAT_END
UnusedList_753E:
	dw Pattern_7544
	LIST_LOOP UnusedList_7774
Pattern_7544:
	REPEAT $1e
	db L4, REST, NOISE_06, NOISE_06
	REPEAT_END
	db PAT_END
UnusedList_754C:
	dw Pattern_755A
	dw Pattern_6A4A
	dw Pattern_6A6A
	dw Pattern_756C
Song67_Ch4_Loop4:
	dw Pattern_5000
	LIST_LOOP Song67_Ch4_Loop4
Pattern_755A:
	db L4, Cs5
	TEMPO LengthTable_694B
	db L16, C5, L8D, REST, L4, REST, REST, REST
	TRANSPOSE $00
	db L1, REST, PAT_END
Pattern_756C:
	db L8, C3
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db L8, C3
	REPEAT $07
	db L16, G3, REST
	REPEAT_END
	db L8, D3
	REPEAT $03
	db L16, A3, REST
	REPEAT_END
	db L8, D3, L16, G3, REST
	INSTR $94, $00, $80
	TRANSPOSE $f0
	REST_ENV $27
	db F5, G5, A5, B5, L8, C6, L16, REST, C6, D6, REST, L8, E6, REST, L16, C6
	db REST, D6, REST, C6, REST
	TRANSPOSE_ADD $f4
	db L8, C6, L16, REST, C6, D6, REST, L8, E6, REST, L16, C6, REST
	TRANSPOSE_ADD $0e
	db F5, G5, A5, B5, L8, C6, L16, REST, C6, D6, REST, L8, E6, REST, L16, C6
	db REST, D6, REST, C6, REST
	TRANSPOSE_ADD $f4
	db L8, C6, L16, REST, C6, D6, REST, L8, E6, REST, L16, C6, REST
	TRANSPOSE_ADD $1a
	ENV_ADD $e0
	db F5, G5, A5, B5
	ENV_ADD $20
	REPEAT $03
	ENV_ADD $e0
	db LEN10, C6, D6, C6, D6
	REPEAT_END
	REPEAT $0e
	db C6, D6
	REPEAT_END
	REPEAT $0a
	ENV_ADD $10
	db C6, D6, C6, D6
	REPEAT_END
	db L8, C6, L4D, REST, L16, C4, REST, L4, C4, L4D, REST
	ENV_SET $68
	REST_ENV $37
	db L16, G3, REST
	TEMPO LengthTable_4CEC
	db L1, G3, PAT_END
UnusedList_7615:
	dw Pattern_7623
	dw Pattern_6B29
	dw Pattern_6B49
	dw Pattern_7630
Song67_Ch4_Loop3:
	dw Pattern_5000
	LIST_LOOP Song67_Ch4_Loop3
Pattern_7623:
	db L16, E4, L8D, REST, L4, REST, REST, REST
	TRANSPOSE $00
	db L1, REST, PAT_END
Pattern_7630:
	db L8, G3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, G3
	REPEAT $07
	db L16, E4, REST
	REPEAT_END
	db L8, A3
	REPEAT $03
	db L16, C4, REST
	REPEAT_END
	db L8, G3
	REPEAT $03
	db L16, B3, REST
	REPEAT_END
	INSTR $94, $00, $80
	TRANSPOSE $f0
	REST_ENV $27
	db L8, C5, L16, REST, C5, G5, REST, L8, C6, REST, L16, C5, REST, G5, REST, C5
	db REST
	TRANSPOSE_ADD $f4
	db L8, C5, L16, REST, C5, D5, REST, L8, E5, REST, L16, C5, REST, D5, REST, C5
	db REST
	TRANSPOSE_ADD $0e
	db L8, C5, L16, REST, C5, G5, REST, L8, C6, REST, L16, C5, REST, G5, REST, C5
	db REST
	TRANSPOSE_ADD $f4
	db L8, C5, L16, REST, C5, D5, REST, L8, E5, REST, L16, C5, REST, D5, REST, C5
	db REST
	TRANSPOSE_ADD $0e
	ENV_SET $a7
	db L1, G5, L16, C4, C3, D3, E3, F3, G3, A3, B3, C5, C5, D5, E5, F5
	db G5, A5, B5, L8, C6, L4D, REST, L16, G4, REST, L4, G4, L4D, REST
	ENV_SET $68
	REST_ENV $37
	db L16, G3, REST, L1, G3, PAT_END
Wave_76CE:
	db $ff, $ff, $88, $88, $00, $00, $00, $00, $77, $77, $00, $00, $00, $00, $00, $00
UnusedList_76DE:
	dw Pattern_76EC
	dw Pattern_69DA
	dw Pattern_6BEB
	dw Pattern_76F7
Song67_Ch4_Loop2:
	dw Pattern_5000
	LIST_LOOP Song67_Ch4_Loop2
Pattern_76EC:
	db L16, C3, L8D, REST
	TRANSPOSE $00
	db L2, REST, REST, REST, PAT_END
Pattern_76F7:
	db LEN13, G5, L1D, REST, L16, G5, LEN9, C6, LEN12, REST, L8D, C6, L16, E6, L8, G6
	db L16, C7, REST, B6, REST, A6, REST, L8D, G6, L16, REST, L8, E6, L16, REST, LEN12
	db G6, LEN10, REST, L8D, F6, L16, REST, L8, D6, L16, REST, LEN12, E6, LEN10, REST, L8D
	db D6, L16, REST, L8, E6, L16, REST, LEN12, D6, LEN10, REST, L1, REST, REST, REST
	INSTR_WAVE Wave_76CE, $20
	db L1, REST, L16, C4, REST, C5, REST, B4, REST, A4, REST, G4, REST, F4, REST, E4
	db REST, D4, REST, C3, REST, C4, REST, B3, REST, A3, REST, G3, REST, F3, REST, E3
	db REST, D3, REST, L8, C3, L4D, REST, L16, E4, REST, L4, E4, L4D, REST, L16, C3
	db REST, L1, C3
	INSTR_WAVE Wave_76CE, $60
	db L4, C3, PAT_END
UnusedList_7774:
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
	dw Pattern_6C8B
Song67_Ch4_Loop:
	dw Pattern_5000
	LIST_LOOP Song67_Ch4_Loop
Song66_Header:
	SONG $03, LengthTable_77A3, Song66_Ch1, Song66_Ch2, Song66_Ch3, Song66_Ch4
LengthTable_77A3:
	db $03, $00, $09, $12, $24, $48, $00, $1b, $36, $0d, $06, $01, $03, $18, $90
Song66_Ch2:
	dw Pattern_780A
	dw Pattern_7868
	dw Pattern_789A
	dw Pattern_7868
	dw Pattern_78C7
	dw Pattern_7868
	dw Pattern_795C
	dw Pattern_7987
Song66_Ch2_Loop:
	dw Pattern_5000
	LIST_LOOP Song66_Ch2_Loop
Song66_Ch1:
	dw Pattern_782B
	dw Pattern_79A5
	dw Pattern_79A5
	dw Pattern_79A5
	dw Pattern_79ED
	dw Pattern_79A5
	dw Pattern_7AA0
Song66_Ch1_Loop:
	dw Pattern_5000
	LIST_LOOP Song66_Ch1_Loop
Song66_Ch3:
	dw Pattern_7851
	dw Pattern_7B2F
	dw Pattern_7B2F
	dw Pattern_7B2F
	dw Pattern_7B60
	dw Pattern_7B2F
	dw Pattern_7BF7
Song66_Ch3_Loop:
	dw Pattern_5000
	LIST_LOOP Song66_Ch3_Loop
Song66_Ch4:
	dw Pattern_7859
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C52
	dw Pattern_7C63
Song66_Ch4_Loop:
	dw Pattern_5000
	LIST_LOOP Song66_Ch4_Loop
Pattern_780A:
	INSTR $d1, $00, $80
	REST_ENV $37
	db LEN10, G6, REST, G6, Fs6, REST, Fs6, F6, REST, F6, E6, REST, E6, D6, REST, L2D
	db REST
	INSTR $67, $00, $40
	REST_ENV $25
	db LEN12, C5, E5, PAT_END
Pattern_782B:
	INSTR $c1, $00, $83
	REST_ENV $37
	db L8, REST, REST, G6, REST, G6, REST, G6, REST, LEN10, F6, REST
	ENV_SET $e2
	db LEN10, G2, REST, REST, G2, LEN10, A2, REST, REST, L4, B2
	INSTR $57, $00, $80
	REST_ENV $25
	db PAT_END
Pattern_7851:
	INSTR_WAVE Wave_52F6, $21
	db L1, REST, REST, PAT_END
Pattern_7859:
	db L1, REST, L4, NOISE_29, LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, REST, NOISE_29, NOISE_29, NOISE_29, PAT_END
Pattern_7868:
	REST_ENV $25
	db LEN10, G5, REST, REST, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, G5, REST
	db C5, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, D5, REST, C5, D5, REST
	db C5, D5, REST, C5, D5, REST, F5, L2, F5, LEN10, B4, REST, C5, L4, D5, PAT_END
Pattern_789A:
	db LEN10, G5, REST, REST, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, G5, REST
	db C5, G5, REST, E5, REST, REST, G5, C6, REST, REST, LEN10, As5, REST, A5, As5, REST
	db A5, As5, REST, A5, REST, REST, G5, L4, G5, G6, G6, REST, PAT_END
Pattern_78C7:
	db LEN10, G5, REST, REST, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, G5, REST
	db C5, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, D5, REST, C5, D5, REST
	db C5, D5, REST, C5, D5, REST, D5, L4, D5, G6, D6, LEN10, B4, REST, LEN12, G4
	db A4
	REST_ENV $37
	db LEN10, As4, REST, REST, As4, REST, A4, REST, REST, As4, A4, REST, REST, LEN10, G4, REST
	db REST, C4, REST, REST, C4, REST, REST, REST, REST, LEN12, G4, A4, LEN10, As4, REST, REST
	db As4, REST, A4, REST, REST, As4, A4, REST, REST, LEN10, C5, REST, REST, C4, REST, REST
	db C4, REST, REST, REST, REST, LEN12, G5, A5, LEN10, As5, REST, REST, As5, REST, A5, REST
	db REST, As5, A5, REST, REST, LEN10, G5, REST, REST, C5, REST, REST, D5, REST, REST, E5
	db REST, REST, LEN10, F5, REST, REST, F5, REST, REST, Fs5, REST, REST, Fs5, REST, REST, L1
	db G5, PAT_END
Pattern_795C:
	db LEN10, G5, REST, REST, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, G5, REST
	db C5, G5, REST, E5, REST, REST, D5, C5, REST, REST, LEN10, D5, REST, C5, D5, REST
	db C5, D5, REST, C5, D5, REST, F5, L2, F5, D5, PAT_END
Pattern_7987:
	db L1, C5, D5, LEN10, F5, REST, C5, F5, REST, REST, G5, REST, D5, G5, REST, REST
	db LEN10, C5, REST, REST, REST, REST, REST, C6, REST, REST, REST, REST, REST, PAT_END
Pattern_79A5:
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, E4, REST, G4
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, LEN12, Gs3, A3
	db As3, B3, C4, Cs4, LEN10, D4, REST, LEN12, D4, F4, LEN10, As4, REST, As4, REST, REST
	db LEN12, D4, F4, LEN10, As4, REST, As4, LEN10, REST, REST, LEN12, F4, A4, LEN10, C5, REST
	db C5, G4, REST, A4, G4, REST, F4, PAT_END
Pattern_79ED:
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, E4, REST, G4
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, LEN12, Gs3, A3
	db As3, B3, C4, Cs4, LEN10, D4, REST, LEN12, D4, F4, LEN10, As4, REST, As4, REST, REST
	db LEN12, D4, F4, LEN10, As4, REST, As4, LEN10, REST, REST, LEN12, D4, F4, LEN10, As4, REST
	db As4, G4, REST, REST, G3, REST, REST, LEN10, REST, REST, REST, F4, REST, REST, REST, REST
	db REST, F4, REST, REST, LEN10, REST, REST, REST, E4, REST, REST, E4, REST, REST, REST, REST
	db REST, LEN10, REST, REST, REST, F4, REST, REST, REST, REST, REST, F4, REST, REST, LEN10, REST
	db REST, REST, E4, REST, REST, E4, REST, REST, REST, REST, REST, LEN10, REST, REST, REST, F4
	db REST, REST, REST, REST, REST, F4, REST, REST, LEN10, E4, REST, REST, E4, REST, E4, E4
	db REST, REST, E4, REST, E4, LEN10, A4, REST, REST, A4, REST, A4, A4, REST, LEN12, F4
	db G4, LEN10, A4, REST, A4, LEN10, B4, REST, REST, G4, REST, REST, D4, REST, REST, B3
	db REST, REST, PAT_END
Pattern_7AA0:
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, E4, REST, G4
	db LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST, C5, C5, REST, G4, LEN12, Gs3, A3
	db As3, B3, C4, Cs4, LEN10, D4, REST, LEN12, D4, F4, LEN10, As4, REST, As4, REST, REST
	db LEN12, D4, F4, LEN10, As4, REST, As4, LEN10, REST, REST, LEN12, D4, F4, LEN10, As4, REST
	db As4, As4, REST, F4, D4, REST, F4, LEN10, REST, REST, LEN12, E4, G4, LEN10, C5, REST
	db C5, C5, REST, G4, LEN12, Gs3, A3, As3, B3, C4, Cs4, LEN10, D4, REST, LEN12, D4
	db F4, LEN10, As4, REST, As4, REST, REST, LEN12, D4, F4, LEN10, As4, REST, As4, LEN10, A4
	db REST, LEN12, A4, C5, LEN10, A4, REST, A4, B4, REST, LEN12, B4, D5, LEN10, B4, REST
	db B4, LEN10, E4, REST, REST, REST, REST, REST, G4, REST, REST, REST, REST, REST, PAT_END
Pattern_7B2F:
	db LEN10, C4, REST, REST, REST, REST, E4, REST, REST, REST, L4, G4, LEN10, C4, REST, REST
	db REST, REST, E4, REST, REST, REST, L4, G4, LEN10, As3, REST, REST, REST, REST, D4, REST
	db REST, REST, L4, F4, LEN10, As4, REST, REST, REST, REST, F4, REST, REST, REST, L4, D4
	db PAT_END
Pattern_7B60:
	db LEN10, C4, REST, REST, REST, REST, E4, REST, REST, REST, L4, G4, LEN10, C4, REST, REST
	db REST, REST, E4, REST, REST, REST, L4, G4, LEN10, As3, REST, REST, REST, REST, D4, REST
	db REST, REST, L4, F4, LEN10, G4, REST, REST, G3, REST, REST, B3, REST, REST, D4, REST
	db REST, LEN10, As3, REST, REST, REST, REST, D4, REST, REST, REST, L4, F4, LEN10, C5, REST
	db REST, C4, REST, REST, C4, REST, REST, REST, REST, REST, LEN10, As3, REST, REST, REST, REST
	db D4, REST, REST, REST, L4, F4, LEN10, C4, REST, REST, G3, REST, REST, C4, REST, REST
	db REST, REST, REST, LEN10, As3, REST, REST, REST, REST, D4, REST, REST, REST, L4, F4, LEN10
	db C5, REST, REST, C4, REST, REST, G3, REST, REST, E3, REST, REST, LEN10, F3, REST, REST
	db F4, REST, REST, Fs3, REST, REST, Fs4, REST, REST, LEN10, G4, REST, REST, G3, REST, REST
	db A3, REST, REST, B3, REST, REST, PAT_END
Pattern_7BF7:
	db LEN10, C4, REST, REST, REST, REST, E4, REST, REST, REST, L4, G4, LEN10, C4, REST, REST
	db REST, REST, E4, REST, REST, REST, L4, G4, LEN10, As3, REST, REST, REST, REST, D4, REST
	db REST, REST, L4, F4, LEN10, As4, REST, REST, REST, REST, F4, REST, REST, REST, L4, D4
	db LEN10, C4, REST, REST, REST, REST, E4, REST, REST, REST, L4, G4, LEN10, As3, REST, REST
	db REST, REST, D4, REST, REST, REST, L4, F4, L4, F3, F3, G3, G3, LEN10, C4, REST
	db REST, G3, REST, REST, C3, REST, REST, REST, REST, REST, PAT_END
Pattern_7C52:
	REPEAT $04
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_29, REST, REST, NOISE_29, REST, NOISE_29, NOISE_2E, REST, NOISE_29
	REPEAT_END
	db PAT_END
Pattern_7C63:
	db LEN10, NOISE_29, REST, NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_29, REST, NOISE_29, NOISE_2E, REST, NOISE_29, LEN10, NOISE_29, REST
	db NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_29, NOISE_2E, NOISE_2E, NOISE_2E, REST, NOISE_29, LEN10, NOISE_2E, REST, NOISE_29, NOISE_2E, REST
	db NOISE_29, NOISE_2E, REST, NOISE_29, NOISE_2E, REST, NOISE_29, LEN10, NOISE_29, REST, NOISE_29, NOISE_29, NOISE_29, NOISE_29, NOISE_29, REST
	db REST, NOISE_2E, REST, REST, PAT_END
	ds 872, 0	; $7C98-$7FFF unused
