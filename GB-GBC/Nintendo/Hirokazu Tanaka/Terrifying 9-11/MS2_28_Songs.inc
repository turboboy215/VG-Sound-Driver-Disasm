; Metal Slug 2 music: songs, bank $28 $4A28-$7FFF

SongTable:
	dw Song01_Header	; song 1
	dw Song02_Header	; song 2
	dw Song03_Header	; song 3
	dw Song04_Header	; song 4
	dw Song05_Header	; song 5
	dw Song06_Header	; song 6
	dw Song07_Header	; song 7
	dw Song08_Header	; song 8
	dw Song09_Header	; song 9
	dw Song10_Header	; song 10
Song01_Header:
	db 3 - 1	; channels
	STREAM 0, Song01_Ch1
	STREAM 1, Song01_Ch2
	STREAM 2, Song01_Ch3
Song01_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 3
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x8, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N0x4, N0x4, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x8
	OCTAVE 4
	db N5x6
	OCTAVE 3
	db N0x6
	OCTAVE 4
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 3
	db N0x6
	OCTAVE 4
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 3
	db N0x6
	OCTAVE 4
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 3
	db N0x6
	OCTAVE 4
	db N11x8, N10x6, N8x6, N10x6, N5x6, N4x8, N3x6, N1x6, N10x6, N5x6, N4x8, N3x6
	db N1x6, N10x6, N5x6, N4x8, N3x6, N1x6, N10x6, N5x6, N4x8, N3x6, N1x6
	JUMP Song01_Ch1
	db $00	; never read
Song01_Ch2:
	INSTR 4, $40, $21, $81
	TRANSPOSE 3
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x2, N4x2, N0x2, N4x2, N5x2, N4x8, N0x4, N0x2
	OCTAVE 3
	db N10x6
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4, N0x2, N1x2, N2x4, N2x4, R4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x2, N4x2, N0x2, N4x2, N5x2, N4x4, N4x2, N5x1, N4x1, N0x4, N0x2
	OCTAVE 3
	db N10x6
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4, N0x2, N1x2, N2x4, N2x4, N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x2, N4x2, N0x2, N4x2, N5x2, N4x8, N0x4, N0x2
	OCTAVE 3
	db N10x6
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4, N0x2, N1x2, N2x4, N2x4, R4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x2, N4x2, N0x2, N4x2, N5x2, N4x4, N4x2, N5x1, N4x1, N0x4, N0x2
	OCTAVE 3
	db N10x6
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N10x2
	OCTAVE 2
	db N0x4, N0x2, N1x2, N0x4, N0x4, R4
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x8, N5x6
	OCTAVE 2
	db N0x6
	OCTAVE 3
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 2
	db N0x6
	OCTAVE 3
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 2
	db N0x6
	OCTAVE 3
	db N11x8, N10x6, N8x6, N5x6
	OCTAVE 2
	db N0x6
	OCTAVE 3
	db N11x8, N10x6, N8x6, N10x6, N5x6, N4x8, N3x6, N1x6, N10x6, N5x6, N4x8, N3x6
	db N1x6, N10x6, N5x6, N4x8, N3x6, N1x6, N10x6, N5x6, N4x8, N3x6, N1x6
	JUMP Song01_Ch2
	db $00	; never read
Song01_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 3
	CH3_FADEOUT_ON
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x8, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N0x4, N0x4, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x2, N1x2, N1x2, N1x2, N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, R4, R2
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N10x2
	OCTAVE 3
	db N0x4, N0x4, N1x8
	OCTAVE 4
	db N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2
	db N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2
	db N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4
	db N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4
	db N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4
	db N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4, N0x4, N0x2
	db N0x4, N0x2, N0x4, N0x4, N0x2, N0x4, N0x2, N0x4
	JUMP Song01_Ch3
	db $00	; never read
Song02_Header:
	db 3 - 1	; channels
	STREAM 0, Song02_Ch1
	STREAM 1, Song02_Ch2
	STREAM 2, Song02_Ch3
Song02_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 2
	OCTAVE 4
	db N7x2, N9x2, R2, N9x2, R4, N7x2, N9x2, R2
	OCTAVE 3
	db N4x2, N7x2
	OCTAVE 2
	db N1x2
	OCTAVE 3
	db N7x2, N9x2, N11x2, N9x2
	OCTAVE 2
	db N2x2, R2, N2x2, R2, N7x2, R2
	OCTAVE 3
	db N7x2, R2, N0x2, N10x2, N2x2
	OCTAVE 2
	db N2x2, N4x2, N1x2, R2
	OCTAVE 3
	db N9x2, N9x2, N8x2, N7x2, N4x2
	OCTAVE 4
	db N7x2
	OCTAVE 3
	db N0x2, N1x2, N2x2, N0x2, N2x2, N0x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N2x2
	OCTAVE 4
	db N7x2, N11x2
	OCTAVE 3
	db N0x2, N5x2, N2x2, N7x2, N4x2, N7x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N5x2, N2x2, R2, N3x2, R2, N5x2, R2, N6x2, R2, N7x2, N0x4, N7x2
	db N1x2, N8x4, N1x2, N4x2, N5x4, N6x4, N7x4, N8x2, N4x2, R2, N4x2, N0x2
	db N4x2, N1x2, N7x4, N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N1x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N2x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N3x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N5x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N6x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N7x2, N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N1x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N2x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N3x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N5x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N6x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N7x2, N9x3, N3x1, N9x2, N11x2
	OCTAVE 2
	db N0x2, N4x4, N7x2
	OCTAVE 3
	db N0x1, N2x1, N4x1, N0x1, N4x2, N8x2, N0x2, N3x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N4x2, N7x6, N10x2, N9x2, N7x2, N3x2, N0x2
	JUMP Song02_Ch1
	db $00	; never read
Song02_Ch2:
	INSTR 4, $40, $21, $81
	TRANSPOSE 2
	OCTAVE 4
	db N7x2, N9x2, R2, N9x2, R4, N7x2, N9x2, R2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x2, N1x2, N2x2, N4x2, N7x2, N4x2, N2x2
	OCTAVE 3
	db N4x2, N5x2, N6x2
	OCTAVE 2
	db N7x2
	OCTAVE 3
	db N2x2, N3x2, N4x2, N0x2, N10x2, N2x2
	OCTAVE 2
	db N2x2, N4x2, N1x2, R2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N9x2, N8x2, N7x2, N4x2, N0x2
	OCTAVE 3
	db N0x2, N1x2, N2x2
	OCTAVE 2
	db N9x2
	OCTAVE 3
	db N2x2
	OCTAVE 2
	db N7x2
	OCTAVE 3
	db N4x2
	OCTAVE 2
	db N5x2
	OCTAVE 3
	db N2x2
	OCTAVE 2
	db N2x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N0x2
	OCTAVE 2
	db N9x2
	OCTAVE 3
	db N2x2
	OCTAVE 2
	db N7x2
	OCTAVE 3
	db N4x2
	OCTAVE 2
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 2
	db N5x2
	OCTAVE 3
	db N0x2, N2x2, N0x2, N3x2, N0x2, N5x2, N0x2, N6x2, N7x2, N0x4, N7x2, N1x2
	db N8x4, N1x2, N4x2, N5x4, N6x4, N7x4, N8x2, N9x1, N11x1
	OCTAVE 2
	db N0x1, N3x1, N7x2, N4x4, N1x2, N0x4
	OCTAVE 3
	db N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N1x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N2x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N3x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N5x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N6x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N7x2, N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N1x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N2x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N3x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N5x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N6x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N7x2, N9x8
	OCTAVE 2
	db N7x8
	OCTAVE 1
	db N0x1, N2x1, N4x1, N0x1
	OCTAVE 2
	db N9x2, N8x2, N4x2, N3x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N8x2, N7x16
	JUMP Song02_Ch2
	db $00	; never read
Song02_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 2
	CH3_FADEOUT_ON
	OCTAVE 4
	db N0x2, R2, N4x2, R2, N7x2, R2, N4x2, R2, N0x2, R2, N0x2, R2
	db N0x2, R2, R2, N4x1, N0x1, N7x2, R2, R2, N2x2, N4x2, R2, R2
	db N0x2, N4x2, R2, N2x2, R2, N0x2, R2, R2, N4x2, N4x2, R2, N0x2
	db R2, N4x2, R2, R2, N7x2, N2x2, R2, N4x2, R2, N9x2, R2, N2x2
	db R2, N5x2, R2, N7x2, R2, N0x2, R2, N5x2, R2, N7x2, R2, N7x2
	db R2, N5x2, R2, R2, N0x2, N4x2, R2, N4x2, R2, N5x2, R2, N5x2
	db R2, N0x2, R2, N5x2, R2, N6x2, R2, N7x2, R2, N0x2, N4x2, N7x2
	db N4x2, N0x2, N1x2, N7x2, N4x2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2
	db R2, N9x2, R2, N9x2, R2, N9x2, R2, N9x2, R2, N4x2, R2, N9x2
	db R2, N0x2, R2, R2, N4x2, N4x2, R2, N4x2, R2, N7x2, R2, N2x2
	db R2, N2x2, R2, N0x2, R2, N7x2, R2, N0x2, R2
	JUMP Song02_Ch3
	db $00	; never read
Song03_Header:
	db 3 - 1	; channels
	STREAM 0, Song03_Ch1
	STREAM 1, Song03_Ch2
	STREAM 2, Song03_Ch3
Song03_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 1
	OCTAVE 4
	db N9x2, R2, N4x2, R2, N0x2, R2, N7x2, R2, N4x2, R2, N0x2, R2
	db N4x2, R2, N7x2, R2
	OCTAVE 3
	db N2x2, N0x4
	OCTAVE 4
	db N9x4, N7x2, N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N7x2, N9x4, N10x2, N11x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N7x2, R2, N0x2, R2, N4x2, R2, N7x2, R2, N4x2, R2, N7x2, R2
	db N4x2, R2, N0x2, R2, N4x2, R2, R2
	OCTAVE 3
	db N0x4, N2x4, N3x4
	OCTAVE 4
	db N7x2, N4x2, R2, N4x2, R2, N3x2, R2, N3x2, R2, N7x2, R2, N4x2
	db R2, N0x2, R2, N4x2, R2, N7x2
	OCTAVE 3
	db N0x4, N2x4, N3x4, N4x2, N4x2, N2x2, N0x2
	OCTAVE 4
	db N11x2, N7x2, R2, N4x2, R2, N4x2, R2, N7x2, R2, N7x2, R2, N0x2
	db R2, R2
	OCTAVE 3
	db N2x4, N3x4, N4x4, N7x2, N8x2, N9x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N4x2, R2, N0x2, R2, N7x2, R2, N7x2, R2, N9x2
	OCTAVE 3
	db N0x4, N3x2, N7x2, N9x2
	OCTAVE 2
	db N0x2, N3x2, R4, R4, R4, R4
	OCTAVE 4
	db N7x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2, N7x2, R2, N7x2, R2
	OCTAVE 3
	db N7x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N4x2, R2, N9x2, N7x2, N4x2, N3x2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2, N4x2, R2, N0x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N2x2, R2, N4x2, R2, N2x2, R2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N2x2, N4x2
	OCTAVE 4
	db N0x2, R2, N7x2, R2, N0x2, R2, N7x2, R2, N4x2, R2, N7x2, R2
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2, N0x2, R2, N4x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N4x2, R2, N0x2, R2, N4x2, R2
	OCTAVE 4
	db N0x2, R2, N7x2, R2, N11x2, R2, N7x2, R2, N9x2, R2
	OCTAVE 3
	db N4x2, R2, N9x2, R2, N0x2, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N4x2, R2, N0x2, R2, N4x2, R2
	OCTAVE 4
	db N0x2
	OCTAVE 3
	db N0x2, N0x2, N0x2
	OCTAVE 4
	db N4x2
	OCTAVE 3
	db N0x2, N0x2, N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N4x2, N4x2, N9x2, N4x2, N4x2, N4x2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, R2, N4x2, R2, N0x2, R2
	OCTAVE 4
	db N9x2, N9x2, N9x2, N9x2
	OCTAVE 3
	db N0x2, N0x2, N0x2, N0x2, N4x2, N4x2, N4x2, N4x2
	OCTAVE 4
	db N7x2, R2, N2x2, R2, N4x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N7x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N4x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N4x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N2x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N4x2, R2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N4x2, R2
	OCTAVE 3
	db N0x2, R2, N0x2, R2, N0x2, R2
	OCTAVE 4
	db N7x2, R2
	OCTAVE 3
	db N4x2, R2, N0x2, R2, N4x2, R2
	JUMP Song03_Ch1
	db $00	; never read
Song03_Ch2:
	INSTR 4, $40, $21, $81
	TRANSPOSE 1
	OCTAVE 2
	db N9x2, N7x4, N4x4, N3x2, N2x4, N0x2
	OCTAVE 3
	db N9x4, N7x4, N9x2, N3x4, N2x2, N0x4
	OCTAVE 4
	db N9x4, N7x2, N9x2
	OCTAVE 3
	db N0x2, R4, R4, R2, N0x2, N2x2, N3x2, N4x2, N7x2, N9x2
	OCTAVE 2
	db N0x2, N2x2, N3x2, N0x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N2x2, N3x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N7x2, N9x2, R2
	OCTAVE 2
	db N0x4, N2x4, N3x4, N2x2, N0x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x2, R6
	OCTAVE 2
	db N3x2, N4x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N7x2, N9x2, R2
	OCTAVE 2
	db N0x4, N2x4, N3x4, N4x2, N9x2, N7x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N8x2, N9x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2, R2, N2x4, N3x4, N4x4, N7x2, N8x2, N9x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x4, N7x4, N4x2, N2x2, N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4, N3x2, N7x2, N9x2
	OCTAVE 2
	db N0x2, N3x2, R4, R4, R4, R4
	INSTR 4, $55, $00, $80
	OCTAVE 3
	db N0x2, N2x2, N3x2, N4x2, N7x2, N9x2
	OCTAVE 2
	db N0x2, N2x2, N3x2, N4x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N9x2
	OCTAVE 2
	db N0x8, R4
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x4, N9x2, N7x4, N4x4, N3x2, N2x4, N0x2
	OCTAVE 3
	db N9x4, N7x4, N4x2, N3x4, N2x2, N0x4
	OCTAVE 4
	db N9x4, N7x2, N9x2
	OCTAVE 3
	db N0x2, R4, R4, R2
	OCTAVE 2
	db N0x2, N2x2, N3x2, N4x2, N7x6, R2, N9x2, N7x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N7x2, N9x2
	OCTAVE 2
	db N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N7x2, N9x2, R2
	OCTAVE 2
	db N0x4, N2x4, N3x4, N2x2, N0x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x2, N0x12, N0x2, N2x2, N3x2, N4x2, N0x6, N5x2, N0x6, N7x2, N0x6, N9x2
	db N0x6
	OCTAVE 1
	db N0x2
	OCTAVE 2
	db N9x2, N7x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N9x6
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x6
	OCTAVE 2
	db N3x2
	OCTAVE 3
	db N9x6
	OCTAVE 2
	db N4x2
	OCTAVE 3
	db N9x6
	OCTAVE 2
	db N7x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N3x2, N2x2, N0x2, N9x2, N0x2
	OCTAVE 2
	db N9x2, N7x4, N4x4, N3x2, N2x4, N0x2
	OCTAVE 3
	db N9x4, N7x4, N4x2, N3x4, N2x2, N0x4
	OCTAVE 4
	db N9x4, N7x2, N9x2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 2
	db N9x2, N7x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N9x4
	OCTAVE 2
	db N0x4, N2x2, N3x2, N4x2, R2, N7x4, N9x4
	OCTAVE 1
	db N0x2
	OCTAVE 2
	db N9x2
	OCTAVE 3
	db N0x2
	JUMP Song03_Ch2
	db $00	; never read
Song03_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 1
	CH3_FADEOUT_ON
	OCTAVE 4
	db N0x2, R2, N4x2, R2, N0x2, R2, N9x2, R2, N0x2, R2, N4x2, R2
	db N0x2, R2
	OCTAVE 3
	db N0x2, R2
	OCTAVE 4
	db N0x2, R2, N4x2, R2, N0x2, R2, N9x2, R2, N0x2, R2, N4x2, R2
	db N0x2, R2, R2, N9x2
	JUMP Song03_Ch3
	db $00	; never read
Song05_Header:
	db 3 - 1	; channels
	STREAM 0, Song05_Ch1
	STREAM 1, Song05_Ch2
	STREAM 2, Song05_Ch3
Song05_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 2
	OCTAVE 2
	db N0x6, N0x4
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x2, N11x6, N11x4, N9x2, N11x2, N9x2
	OCTAVE 2
	db N0x6, N0x4
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x2, N11x6, N11x4, N9x2, N11x2, N9x2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 3
	db N0x2, N4x4
	OCTAVE 4
	db N9x2, N7x2, N4x2, N9x2, N7x2, N4x2, N0x2, N9x4, R4, R4, N4x4, R4
	db N4x4, R4, N4x4, R4, N4x4, N4x4, N9x4, N7x4, N4x4, N4x2, R2, N4x2
	db R2, N0x2, R2, N0x2, R2, N4x2, N0x2, N7x2, N4x2, N9x2, N4x2, N7x2
	db N4x2
	OCTAVE 3
	db N4x2, N0x2, N7x2, N4x2, N9x2, N4x2, N7x2, N4x2, N4x2, R2, N9x2, R2
	db N7x2, R2, N4x2, R2
	OCTAVE 4
	db N4x2, R2, N4x2, R2, N0x2, R2, N0x2, R2
	OCTAVE 2
	db N4x2, N4x2, N4x2, N4x2, N9x2, N4x2
	OCTAVE 1
	db N0x2
	OCTAVE 2
	db N4x2
	OCTAVE 3
	db N4x2, N4x2, N4x2, N4x2, N9x2, N4x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N4x2, N9x2, N9x2, N9x2, N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N4x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N9x2, N7x2, N4x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N0x2, N4x2, N4x2, N4x2, N4x2, N9x2, N4x2
	OCTAVE 2
	db N1x2
	OCTAVE 3
	db N4x2
	OCTAVE 2
	db N4x2
	OCTAVE 3
	db N4x2
	OCTAVE 2
	db N4x2
	OCTAVE 3
	db N4x2, N9x2, N4x2
	OCTAVE 2
	db N1x2
	OCTAVE 3
	db N4x2
	OCTAVE 2
	db N1x2, N1x2, N1x2, N1x2, N4x2, N1x2
	OCTAVE 3
	db N9x2, N4x2
	OCTAVE 4
	db N4x2, N9x2, N4x2, N9x4, N4x2, N9x4
	JUMP Song05_Ch1
	db $00	; never read
Song05_Ch2:
	INSTR 4, $55, $00, $80
	TRANSPOSE 2
	OCTAVE 4
	db N7x3, N9x1, N9x2, N9x2, N7x2, N4x2, R2, R2, N7x3, N9x1, N11x2, N9x2
	db N7x2, N4x2, R2, R2, N7x3, N9x1
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, N7x2, N4x2, R2, R2, N5x2, N4x2, N6x2, N4x2, N7x2, N4x2, N8x2
	db N4x2
	OCTAVE 3
	db N9x2
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N9x4, N7x4, N4x2, N2x2, N0x4
	OCTAVE 4
	db N9x4, N7x2, N9x4
	INSTR 4, $40, $21, $81
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N4x2, N11x2, N4x4, N9x4, N4x2, N11x2, N4x2, N9x2, N4x4, N7x4, N6x2
	OCTAVE 4
	db N9x2, N11x2
	OCTAVE 3
	db N0x2, N5x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N0x2, N4x2, N8x2, N9x1, N11x1, N9x1, N8x1, N4x1, N5x1, N4x1, N2x1, N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N4x1, N9x4
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N4x2, N11x2, N4x4, N9x4, N4x2, N11x2, N4x2, N9x2, N4x4, N7x4, N6x2
	OCTAVE 4
	db N9x2, N11x2
	OCTAVE 3
	db N0x2, N5x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N0x2, N4x2, N8x2, N9x1, N11x1, N9x1, N8x1, N4x1, N5x1, N4x1, N2x1, N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N4x1
	OCTAVE 4
	db N4x1, N9x4
	INSTR 4, $55, $00, $80
	db N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x4, N4x2, N9x2, N4x2, N9x4
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x4
	JUMP Song05_Ch2
	db $00	; never read
Song05_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 2
	CH3_FADEOUT_ON
	OCTAVE 4
	db N4x2, R2, N4x2, R2, N9x2, R2, N4x2, R2, N4x2, R2, N4x2, R2
	db N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2
	db N4x2, R2, N4x2, R2, N4x2, R2, R2, N4x2, N4x2, R2, N4x2, R2
	db N4x2, R2, N4x2, N4x2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2
	db N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N4x2, R2
	db N4x2, R2, R2, N4x2
	JUMP Song05_Ch3
	db $00	; never read
Song04_Header:
	db 3 - 1	; channels
	STREAM 0, Song04_Ch1
	STREAM 1, Song04_Ch2
	STREAM 2, Song04_Ch3
Song04_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 1
	OCTAVE 2
	db N7x2, N9x2, N9x2, N9x2, N9x2, N9x2, N9x2, N9x2, N7x2, N9x2, N9x2, N9x2
	db N9x2, N9x2, N9x2, N9x2, N7x2, N8x2, N9x2, N7x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N2x2, N0x2
	OCTAVE 4
	db N9x2, N7x2, N9x2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N7x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N7x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2, N2x2, R2, N2x2, R2, N0x2, R2, N0x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	OCTAVE 3
	db N0x4, N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N9x2, R2, N7x2, N9x2, R2
	JUMP Song04_Ch1
	db $00	; never read
Song04_Ch2:
	INSTR 4, $40, $21, $81
	TRANSPOSE 1
	OCTAVE 3
	db N0x2, N4x2, N4x2, N4x2, N4x2, N4x2, N4x2, N4x2, N4x2, N9x2, N9x2, N9x2
	db N9x2, N9x2, N9x2, N9x2, N7x2, N4x4, N0x4
	OCTAVE 4
	db N9x4, N9x1, N7x1, N4x2, N9x4
	OCTAVE 3
	db N0x4, N4x4, N9x2
	OCTAVE 2
	db N4x2, N0x4
	OCTAVE 3
	db N7x4, N4x4, N9x2
	OCTAVE 2
	db N0x6
	OCTAVE 4
	db N9x2, N7x2, N4x2, N9x2, N4x2
	OCTAVE 2
	db N4x2, N4x2, N4x2, N0x2, N0x2, N0x2
	OCTAVE 3
	db N9x2, N9x2, N9x2, N7x2, N7x2, N7x2, N4x2, N4x4, N4x2, N9x2, N11x2
	OCTAVE 2
	db N0x2, N3x2, N4x2, N7x2, N9x2, N7x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x4, N4x2, N0x2, N4x4, N9x2
	OCTAVE 2
	db N4x2
	OCTAVE 4
	db N4x2
	OCTAVE 2
	db N0x2
	OCTAVE 4
	db N4x2
	OCTAVE 2
	db N4x2
	OCTAVE 4
	db N4x2
	OCTAVE 2
	db N9x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N7x2
	OCTAVE 3
	db N0x2, N4x2, N7x2
	OCTAVE 2
	db N0x2, N4x2, N7x2
	OCTAVE 1
	db N0x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N11x2, N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N11x2, N9x4
	OCTAVE 2
	db N0x2, N4x2, N2x2, N0x2, N5x2, N4x2, N2x2, N4x2, N2x2, N0x2
	OCTAVE 3
	db N11x2, N9x2
	OCTAVE 2
	db N0x2
	OCTAVE 3
	db N11x2, N9x4
	OCTAVE 2
	db N0x2, N4x2, N2x2, N0x2, N5x2, N4x2, N2x2, N4x2, N2x2, N4x2, N0x4
	OCTAVE 3
	db N7x4, N4x4, N9x2
	OCTAVE 2
	db N0x6
	OCTAVE 4
	db N9x2, N7x2, N4x2, N9x2, N4x2
	OCTAVE 2
	db N4x2, N4x2, N4x2, N0x2, N0x2, N0x2
	OCTAVE 3
	db N9x2, N9x2, N9x2, N7x2, N7x2, N7x2, N4x2, N4x4, N4x2
	INSTR 4, $55, $00, $80
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N0x1
	OCTAVE 4
	db N9x1
	OCTAVE 3
	db N0x1, N4x1, N7x1, N4x1, N7x1, N9x4, N7x2, N4x2, N2x1, N4x1, N2x1, N4x1
	db N3x1, N4x1, N3x1, N4x1, N2x1, N4x1, N2x1, N4x1, N3x1, N4x1, N3x1, N4x1
	db N0x1, N4x1, N0x1, N4x1, N9x1
	OCTAVE 2
	db N0x1
	OCTAVE 3
	db N9x1
	OCTAVE 2
	db N0x1, N9x2, N7x2, N4x2, N2x2, N0x1
	OCTAVE 3
	db N9x1
	OCTAVE 2
	db N0x1
	OCTAVE 3
	db N9x1
	OCTAVE 2
	db N0x1
	OCTAVE 3
	db N9x1
	OCTAVE 2
	db N0x1
	OCTAVE 3
	db N9x1, N11x1, N9x1, N11x1, N9x1, N11x1, N9x1, N11x1, N9x1, R4, R4, R4
	db R4, R4, R4, R4, R4, R4, R4, R4, R4, R4, R4, R4
	db R4
	JUMP Song04_Ch2
	db $00	; never read
Song04_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 1
	CH3_FADEOUT_ON
	OCTAVE 4
	db N0x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N9x2, R2, N4x2, R2
	db N4x2, R2, N4x2, R2, N0x2, R2, N4x2, R2, N4x2, R2, N4x2, R2
	db N9x2, N9x2, N4x2, N9x2, N0x2, R2, N4x4, N0x2, R2, N4x2, R2, N4x2
	db R2, N4x2, R2, N9x2, R2, N4x2, R2, N4x2, R2, N4x2, R2, N0x2
	db R2, N4x2, R2, N4x2, R2, N4x2, R2, N9x2, R2, N4x2, R2, N4x2
	db R2, N4x2, R2
	JUMP Song04_Ch3
	db $00	; never read
Song06_Header:
	db 3 - 1	; channels
	STREAM 0, Song06_Ch1
	STREAM 1, Song06_Ch2
	STREAM 2, Song06_Ch3
Song06_Ch1:
	INSTR 4, $55, $00, $80
	TRANSPOSE 3
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, N2x2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, N2x2, R4, R4, R4, R4, R4, R4, R4, R4
	OCTAVE 3
	db N4x2, R2, N4x2, R2, N2x2, R2
	OCTAVE 4
	db N9x2, R2, N4x2, R2, N5x2, R2, N0x2, R2, N7x2, R2
	OCTAVE 3
	db N0x2, R2, N4x2, R2, N9x2, R2
	OCTAVE 2
	db N3x2, N0x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N4x2, R2
	OCTAVE 4
	db N9x2, R2
	JUMP Song06_Ch1
	db $00	; never read
Song06_Ch2:
	INSTR 4, $40, $21, $81
	TRANSPOSE 3
	OCTAVE 4
	db N9x6
	OCTAVE 3
	db N4x2, R4, R4, R4, R2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N3x2, N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, R2, N9x2, R4, R4, R2, N9x2
	OCTAVE 3
	db N1x4, N2x8
	OCTAVE 4
	db N9x6
	OCTAVE 3
	db N4x2, R4, R4, R4, R2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N7x2, N3x2, N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, R2, N9x2, R4, R4, R2, N9x2
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N6x6
	OCTAVE 4
	db N4x2, N9x6
	OCTAVE 3
	db N4x2, R4
	OCTAVE 1
	db N4x2, N0x4
	OCTAVE 2
	db N9x2, R2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N3x2, N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, R2, N9x2, R4, R4, R2, N9x2
	OCTAVE 3
	db N1x4, N2x8
	OCTAVE 4
	db N9x6
	OCTAVE 3
	db N4x2
	OCTAVE 1
	db N4x2, N0x4
	OCTAVE 2
	db N9x2, N7x4, R2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N3x2, N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, R2, N9x2, R4
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N4x2
	OCTAVE 3
	db N1x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N6x4
	OCTAVE 4
	db N4x2
	OCTAVE 3
	db N1x2
	INSTR 4, $55, $00, $80
	db R4, R4, R4, R4, R4, R4, R4, R4, R2, N9x2, N7x2, N3x2
	db N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N9x2, R2, N9x2
	OCTAVE 3
	db N2x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N6x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x4
	OCTAVE 2
	db N0x2, N4x2, N9x2, N7x2, N4x2, N0x2, N3x2, N0x2, N4x2, N3x2, N2x2, N0x2
	OCTAVE 3
	db N9x2, N7x2, N4x2, N9x2
	JUMP Song06_Ch2
	db $00	; never read
Song06_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 3
	CH3_FADEOUT_ON
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, N2x2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, R2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, R2
	OCTAVE 5
	db N9x4, R2
	OCTAVE 4
	db N9x2, R2
	OCTAVE 5
	db N9x2
	OCTAVE 4
	db N7x2, N9x2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N6x2, R2
	OCTAVE 5
	db N9x2, N9x2
	OCTAVE 4
	db N0x2, N2x2
	JUMP Song06_Ch3
	db $00	; never read
Song07_Header:
	db 3 - 1	; channels
	STREAM 0, Song07_Ch1
	STREAM 1, Song07_Ch2
	STREAM 2, Song07_Ch3
Song07_Ch1:
	INSTR 6, $55, $00, $80
	TRANSPOSE 2
	OCTAVE 4
	db N9x16, N5x16, N7x16, N9x16, N9x16, N5x16, N7x16, N9x16, N9x2, N11x2
	OCTAVE 3
	db N0x2, N4x2, N0x2
	OCTAVE 4
	db N11x2, N9x2, N4x2, N9x2
	OCTAVE 3
	db N2x2, N4x2, N5x2, N4x2, N2x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x4, N2x4
	OCTAVE 4
	db N9x4, N9x4, R4
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N11x4, N9x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N0x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N0x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N5x2, N2x2, N5x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N5x2, N2x2, N5x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N7x2, N4x2, N7x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N4x2, N7x2, N4x2
	OCTAVE 4
	db N9x2, N11x2
	OCTAVE 3
	db N0x2, N4x2, N0x2
	OCTAVE 4
	db N11x2, N9x2, N4x2
	JUMP Song07_Ch1
	db $00	; never read
Song07_Ch2:
	TRANSPOSE 2
	INSTR 6, $40, $21, $81
	OCTAVE 4
	db N9x4
	OCTAVE 3
	db N4x4, N4x6, N4x2, N4x4, N2x2, N2x8, N2x2, N7x4, N5x4, N4x2, N2x4, N4x2
	db N4x16, N0x4, N0x4, N0x6, N4x2, N4x4, N2x2, N2x8, N0x2, N0x4
	OCTAVE 4
	db N11x4
	OCTAVE 3
	db N2x2, N4x4, N0x2, N0x16
	OCTAVE 4
	db N9x4
	OCTAVE 3
	db N4x4, N4x6, N4x2, N4x4, N2x2, N2x8, N2x2, N7x4, N5x4, N4x2, N2x4, N4x2
	db N4x16, N0x4, N0x4, N0x6, N4x2, N4x4, N2x2, N2x8, N0x2
	OCTAVE 4
	db N11x4, N11x4
	OCTAVE 3
	db N2x2
	OCTAVE 4
	db N11x4, N9x16, R2
	JUMP Song07_Ch2
	db $00	; never read
Song07_Ch3:
	INSTR 6, $40, $6e, $20
	TRANSPOSE 2
	db R4
	CH3_FADEOUT_ON
	JUMP Song07_Ch3
	db $00	; never read
Song08_Header:
	db 3 - 1	; channels
	STREAM 0, Song08_Ch1
	STREAM 1, Song08_Ch2
	STREAM 2, Song08_Ch3
Song08_Ch1:
	TRANSPOSE 5
	INSTR 4, $40, $21, $81
	OCTAVE 4
	db N7x2, N7x2, N7x2
	OCTAVE 3
	db N0x2, N0x2, N0x2, N4x2, N4x2, N4x2, N7x6, N4x2, N4x2, N4x2, N7x2, N7x2
	db N7x2, N7x2, N7x2, N7x2
	OCTAVE 2
	db N0x6
	END_SONG
Song08_Ch2:
	INSTR 4, $55, $00, $80
	TRANSPOSE 5
	OCTAVE 3
	db N0x2, N0x2, N0x2
	OCTAVE 4
	db N7x2, N7x2, N7x2
	OCTAVE 3
	db N0x2, N0x2, N0x2, N4x6, N0x2, N0x2, N0x2, N4x2, N4x2, N4x2, N2x2, N2x2
	db N2x2, N0x6
	END_SONG
Song08_Ch3:
	INSTR 4, $40, $6e, $20
	TRANSPOSE 5
	CH3_FADEOUT_ON
	OCTAVE 4
	db N7x2, N7x2, N7x2
	OCTAVE 3
	db N0x2
	OCTAVE 4
	db N7x2, N7x2
	OCTAVE 3
	db N4x2
	OCTAVE 4
	db N7x2, N7x2, N0x2, N7x2, N7x2, N0x2, N4x2, N4x2, N0x2, N7x2, N7x2, N2x2
	db N11x2, N11x2, N0x2, R2, N0x2
	END_SONG
Song09_Header:
	db 3 - 1	; channels
	STREAM 0, Song09_Ch1
	STREAM 1, Song09_Ch2
	STREAM 2, Song09_Ch3
Song09_Ch1:
	INSTR 6, $55, $00, $80
	TRANSPOSE 2
	OCTAVE 4
	db N9x16, N5x16, N7x16, N9x16, N9x16, N5x16, N7x16, N9x16, N9x2, N11x2
	OCTAVE 3
	db N0x2, N4x2, N0x2
	OCTAVE 4
	db N11x2, N9x2, N4x2, N9x2
	OCTAVE 3
	db N2x2, N4x2, N5x2, N4x2, N2x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x4, N2x4
	OCTAVE 4
	db N9x4, N9x4, R4
	OCTAVE 2
	db N0x4
	OCTAVE 3
	db N11x4, N9x4
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N0x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N4x2, N0x2, N4x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N5x2, N2x2, N5x2
	OCTAVE 4
	db N9x2
	OCTAVE 3
	db N5x2, N2x2, N5x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N7x2, N4x2, N7x2
	OCTAVE 4
	db N11x2
	OCTAVE 3
	db N4x2, N7x2, N4x2
	OCTAVE 4
	db N9x2, N11x2
	OCTAVE 3
	db N0x2, N4x2, N0x2
	OCTAVE 4
	db N11x2, N9x2, N4x2
	JUMP Song09_Ch1
	db $00	; never read
Song09_Ch2:
	TRANSPOSE 2
	INSTR 6, $40, $21, $81
	OCTAVE 4
	db N9x4
	OCTAVE 3
	db N4x4, N4x6, N4x2, N4x4, N2x2, N2x8, N2x2, N7x4, N5x4, N4x2, N2x4, N4x2
	db N4x16, N0x4, N0x4, N0x6, N4x2, N4x4, N2x2, N2x8, N0x2, N0x4
	OCTAVE 4
	db N11x4
	OCTAVE 3
	db N2x2, N4x4, N0x2, N0x16
	OCTAVE 4
	db N9x4
	OCTAVE 3
	db N4x4, N4x6, N4x2, N4x4, N2x2, N2x8, N2x2, N7x4, N5x4, N4x2, N2x4, N4x2
	db N4x16, N0x4, N0x4, N0x6, N4x2, N4x4, N2x2, N2x8, N0x2
	OCTAVE 4
	db N11x4, N11x4
	OCTAVE 3
	db N2x2
	OCTAVE 4
	db N11x4, N9x16, R2
	JUMP Song09_Ch2
	db $00	; never read
Song09_Ch3:
	INSTR 6, $40, $6e, $20
	TRANSPOSE 2
	db R4
	CH3_FADEOUT_ON
	JUMP Song09_Ch3
	db $00	; never read
Song10_Header:
	db 3 - 1	; channels
	STREAM 0, Song10_Ch1
	STREAM 1, Song10_Ch2
	STREAM 2, Song10_Ch3
Song10_Ch1:
	TRANSPOSE 4
	INSTR 5, $40, $21, $81
	OCTAVE 3
	db N4x16, N4x16, N2x16, N4x16
	END_SONG
Song10_Ch2:
	TRANSPOSE 4
	INSTR 5, $40, $21, $81
	OCTAVE 3
	db N9x16, N8x16, N7x16
	OCTAVE 4
	db N7x16
	END_SONG
Song10_Ch3:
	INSTR 5, $40, $6e, $20
	TRANSPOSE 4
	CH3_FADEOUT_ON
	OCTAVE 4
	db N4x4, R4, R4, R2, N4x2, N4x4, R4, R4, R4, N2x4, R4, N2x4
	db R4, N4x2, N4x2, N4x2, N4x2, N4x2, R2, N4x2, R2
	END_SONG
	db $00	; never read
	ds 1143, 0	; $5B99-$600F unused
; not sound data: 2bpp tiles (a 1bpp font with $FF in every other byte),
; $6010-$775F
NotSound_Tiles:
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e7, $ff, $db, $ff, $bd, $ff, $81, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fc, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $38, $ff, $df, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $61, $ff, $ae, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $ff, $bd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fd, $ff, $3d, $ff, $d0, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $bf, $ff, $ff, $ff, $7f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $df, $ff, $df, $ff, $06, $ff, $dd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $1a, $ff, $e9, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $34, $ff, $d3, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $ff, $af, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $d1, $ff, $4e, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $ff, $ff, $b0, $ff, $af, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f7, $ff, $f7, $ff, $41, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $83, $ff, $7f, $ff
	db $bd, $ff, $bd, $ff, $bd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fb, $ff, $fc, $ff, $ff, $ff, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d8, $ff, $17, $ff, $d8, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $2e, $ff, $ae, $ff, $2e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $bd, $ff, $c1, $ff, $fd, $ff, $c3, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fb, $ff, $fb, $ff, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $dd, $ff, $dd, $ff, $3d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $dc, $ff, $dd, $ff, $de, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0b, $ff, $fb, $ff, $0b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f7, $ff, $f7, $ff, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ef, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $5f, $ff, $5f, $ff, $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $b0, $ff, $bf, $ff, $a0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f7, $ff, $77, $ff, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $87, $ff, $fb, $ff, $07, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7d, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fb, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $ff, $ff
	db $47, $ff, $3b, $ff, $7b, $ff, $7a, $ff, $7b, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0d, $ff, $f5, $ff, $05, $ff, $f6, $ff, $07, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ec, $ff, $eb, $ff, $e8, $ff, $db, $ff, $3c, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $3f, $ff, $df, $ff, $1f, $ff, $ff, $ff, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $a3, $ff, $9d, $ff, $bd, $ff, $bd, $ff, $bd, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7d, $ff, $7d, $ff, $7d, $ff, $7d, $ff, $5d, $ff, $e3, $ff, $ff, $ff, $ff, $ff
	db $87, $ff, $fa, $ff, $82, $ff, $7a, $ff, $83, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0b, $ff, $fb, $ff, $fa, $ff, $f9, $ff, $0b, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $b0, $ff, $6f, $ff, $e0, $ff, $6f, $ff, $b0, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e0, $ff, $5e, $ff, $5e, $ff, $de, $ff, $61, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fe, $ff, $ff, $ff, $fe, $ff, $fd, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $18, $ff, $eb, $ff, $0b, $ff, $eb, $ff, $0b, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7f, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $86, $ff, $fa, $ff, $82, $ff, $7a, $ff, $82, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $a3, $ff, $9d, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $03, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fe, $ff, $ff, $ff, $87, $ff, $7b, $ff, $7b, $ff, $07, $ff, $7f, $ff, $7f, $ff
	db $7f, $ff, $7f, $ff, $61, $ff, $7e, $ff, $60, $ff, $5e, $ff, $60, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $87, $ff, $ba, $ff, $ba, $ff, $ba, $ff, $bb, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $0f, $ff, $f7, $ff, $07, $ff, $ff, $ff, $07, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $f0, $ff, $ff, $ff, $f0, $ff, $ef, $ff, $f0, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $c3, $ff, $5d, $ff, $5d, $ff, $5d, $ff, $5d, $ff, $ff, $ff
	db $fb, $ff, $fb, $ff, $83, $ff, $7b, $ff, $7b, $ff, $7b, $ff, $87, $ff, $ff, $ff
	db $f7, $ff, $f7, $ff, $f4, $ff, $f3, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $ff, $ff
	db $ee, $ff, $fe, $ff, $68, $ff, $ae, $ff, $ae, $ff, $ae, $ff, $ae, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $86, $ff, $fb, $ff, $83, $ff, $7b, $ff, $83, $ff, $ff, $ff
	db $bf, $ff, $bf, $ff, $0f, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $ff, $ff
	db $f7, $ff, $f7, $ff, $c1, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $ff, $ff
	db $7f, $ff, $7f, $ff, $47, $ff, $3a, $ff, $7a, $ff, $7a, $ff, $7b, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7b, $ff, $7b, $ff, $7b, $ff, $4a, $ff, $4a, $ff, $32, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0d, $ff, $f4, $ff, $f5, $ff, $f5, $ff
	db $ff, $ff, $ff, $ff, $f9, $ff, $fd, $ff, $1d, $ff, $ed, $ff, $fd, $ff, $fd, $ff
	db $ff, $ff, $ff, $ff, $fb, $ff, $fb, $ff, $83, $ff, $7b, $ff, $7b, $ff, $7b, $ff
	db $ff, $ff, $ff, $ff, $f0, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $ff
	db $ff, $ff, $ff, $ff, $1f, $ff, $ff, $ff, $f4, $ff, $f3, $ff, $f7, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $70, $ff, $bf, $ff, $f0, $ff, $ef, $ff
	db $ff, $ff, $ff, $ff, $fe, $ff, $fe, $ff, $e0, $ff, $5e, $ff, $5e, $ff, $5e, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $ff, $bd, $ff, $81, $ff, $bf, $ff
	db $ff, $ff, $ff, $ff, $fc, $ff, $fb, $ff, $fb, $ff, $fb, $ff, $fb, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $3f, $ff, $df, $ff, $f8, $ff, $f7, $ff, $f0, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $61, $ff, $ae, $ff, $2e, $ff, $ee, $ff
	db $ff, $ff, $ff, $ff, $ef, $ff, $ef, $ff, $83, $ff, $ee, $ff, $ee, $ff, $ee, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0d, $ff, $f4, $ff, $05, $ff, $fd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $1f, $ff, $ef, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $df, $ff, $ff, $ff, $d0, $ff, $d7, $ff, $d7, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff, $7f, $ff
	db $7b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $87, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $61, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c1, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $2e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $05, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7b, $ff, $3b, $ff, $5b, $ff, $6a, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0d, $ff, $f5, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f7, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ef, $ff, $ef, $ff, $f7, $ff, $f8, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $70, $ff, $ef, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $bb, $ff, $b7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f8, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fc, $ff, $fb, $ff, $7b, $ff, $a0, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $fe, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bb, $ff, $bb, $ff, $0a, $ff, $b9, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $38, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $bf, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7b, $ff, $7b, $ff, $7a, $ff, $7a, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fb, $ff, $ff, $ff, $1a, $ff, $eb, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $0f, $ff, $b8, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $1f, $ff
	db $72, $ff, $7a, $ff, $7b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $05, $ff, $fd, $ff, $06, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $b7, $ff, $b7, $ff, $4f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fd, $ff, $fd, $ff, $fd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $af, $ff, $97, $ff, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f7, $ff, $f7, $ff, $f8, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $bb, $ff, $bb, $ff, $7b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $bb, $ff, $bb, $ff, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d0, $ff, $d7, $ff, $d8, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $3f, $ff, $ff, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7a, $ff, $7a, $ff, $86, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $eb, $ff, $eb, $ff, $eb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f0, $ff, $ef, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f7, $ff, $77, $ff
	db $87, $ff, $7a, $ff, $02, $ff, $7e, $ff, $83, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $07, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $0f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ef, $ff, $f0, $ff, $ff, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c1, $ff, $f7, $ff, $77, $ff, $77, $ff, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $86, $ff, $fb, $ff, $83, $ff, $7b, $ff, $83, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0c, $ff, $bb, $ff, $b8, $ff, $bb, $ff, $bc, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $ff, $d7, $ff, $18, $ff, $ff, $ff, $10, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $3f, $ff, $ff, $ff, $7f, $ff, $a7, $ff, $67, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $47, $ff, $3a, $ff, $7e, $ff, $7e, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0c, $ff, $f5, $ff, $f5, $ff, $f5, $ff, $0d, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $ff, $d7, $ff, $d7, $ff, $d8, $ff, $df, $ff, $f8, $ff, $ff, $ff, $ff, $ff
	db $7f, $ff, $bf, $ff, $bf, $ff, $3f, $ff, $bf, $ff, $7f, $ff, $ff, $ff, $ff, $ff
	db $86, $ff, $7b, $ff, $03, $ff, $7f, $ff, $82, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f7, $ff, $6c, $ff, $9f, $ff, $6f, $ff, $f7, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $0f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7f, $ff, $7f, $ff, $61, $ff, $5e, $ff, $5e, $ff, $5e, $ff, $61, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $c1, $ff, $bf, $ff, $c3, $ff, $fd, $ff, $83, $ff, $ff, $ff
	db $7f, $ff, $ff, $ff, $61, $ff, $5e, $ff, $5e, $ff, $5e, $ff, $61, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $87, $ff, $bb, $ff, $bb, $ff, $bb, $ff, $bb, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $70, $ff, $bf, $ff, $b0, $ff, $af, $ff, $b0, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $e0, $ff, $5f, $ff, $61, $ff, $7e, $ff, $41, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $fe, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $4e, $ff, $b7, $ff, $b6, $ff, $b5, $ff, $b6, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1c, $ff, $eb, $ff, $0b, $ff, $eb, $ff, $0c, $ff, $ff, $ff
	db $df, $ff, $df, $ff, $18, $ff, $d7, $ff, $d0, $ff, $d7, $ff, $38, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $bf, $ff, $3f, $ff, $ff, $ff, $3f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $0e, $ff, $f7, $ff, $06, $ff, $fd, $ff, $06, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1b, $ff, $eb, $ff, $0b, $ff, $ed, $ff, $0e, $ff, $ff, $ff
	db $f7, $ff, $ff, $ff, $d7, $ff, $d7, $ff, $d7, $ff, $b7, $ff, $77, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $03, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff, $5e, $ff, $5e, $ff, $5c, $ff, $62, $ff
	db $ff, $ff, $ff, $ff, $fd, $ff, $ff, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0f, $ff, $77, $ff, $77, $ff, $77, $ff
	db $ff, $ff, $ff, $ff, $df, $ff, $ff, $ff, $d7, $ff, $d7, $ff, $d7, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $a8, $ff, $a7, $ff, $af, $ff, $af, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e1, $ff, $5e, $ff, $c0, $ff, $df, $ff
	db $ff, $ff, $ff, $ff, $fd, $ff, $fd, $ff, $c1, $ff, $bd, $ff, $bd, $ff, $bd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $30, $ff, $d7, $ff, $17, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fd, $ff, $fd, $ff, $fd, $ff
	db $ff, $ff, $ff, $ff, $eb, $ff, $ef, $ff, $0b, $ff, $ea, $ff, $ea, $ff, $ea, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0e, $ff, $f5, $ff, $05, $ff, $fd, $ff
	db $ff, $ff, $ff, $ff, $ef, $ff, $ef, $ff, $0f, $ff, $ef, $ff, $ef, $ff, $ef, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e1, $ff, $fe, $ff, $e0, $ff, $de, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c1, $ff, $bf, $ff, $c3, $ff, $fd, $ff
	db $7e, $ff, $e1, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $75, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d8, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $6f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c3, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $17, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $06, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7d, $ff, $7d, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $ff, $ff, $87, $ff, $7b, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $4f, $ff, $6f, $ff, $6f, $ff, $6f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e1, $ff, $fe, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c1, $ff, $bf, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $61, $ff, $de, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $ba, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fd, $ff, $ff, $ff, $4d, $ff, $b5, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $3f, $ff, $bf, $ff, $b0, $ff, $af, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e0, $ff, $5f, $ff
	db $6d, $ff, $6d, $ff, $93, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $03, $ff, $7f, $ff, $83, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $6f, $ff, $6f, $ff, $6f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e0, $ff, $de, $ff, $e0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c3, $ff, $fd, $ff, $83, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f8, $ff, $fb, $ff, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $17, $ff, $f7, $ff, $18, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $de, $ff, $de, $ff, $61, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ba, $ff, $ba, $ff, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f5, $ff, $f5, $ff, $0d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $b5, $ff, $b5, $ff, $b5, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7f, $ff, $7f, $ff, $87, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $61, $ff, $7e, $ff, $c1, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $81, $ff, $bf, $ff, $c1, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $87, $ff, $fa, $ff, $06, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $7f, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $03, $ff, $df, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $df, $ff, $ff, $ff
	db $df, $ff, $de, $ff, $de, $ff, $de, $ff, $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0f, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $0f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f0, $ff, $ef, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $f0, $ff, $ff, $ff, $ff, $ff
	db $d7, $ff, $57, $ff, $57, $ff, $5b, $ff, $5c, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $b0, $ff, $af, $ff, $a0, $ff, $6f, $ff, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fe, $ff, $7e, $ff, $7e, $ff, $fe, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0e, $ff, $f7, $ff, $f6, $ff, $f5, $ff, $0e, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1c, $ff, $eb, $ff, $0b, $ff, $eb, $ff, $0c, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $2e, $ff, $ed, $ff, $eb, $ff, $e5, $ff, $2e, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $df, $ff, $df, $ff, $06, $ff, $dd, $ff, $dc, $ff, $dd, $ff, $de, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1a, $ff, $e9, $ff, $0b, $ff, $fb, $ff, $0b, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $34, $ff, $d3, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $70, $ff, $af, $ff, $ef, $ff, $ef, $ff, $f0, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $d1, $ff, $4e, $ff, $5f, $ff, $5f, $ff, $df, $ff, $ff, $ff
	db $bf, $ff, $ff, $ff, $b0, $ff, $af, $ff, $b0, $ff, $bf, $ff, $a0, $ff, $ff, $ff
	db $f7, $ff, $f7, $ff, $41, $ff, $f7, $ff, $f7, $ff, $77, $ff, $f7, $ff, $ff, $ff
	db $df, $ff, $bf, $ff, $78, $ff, $f7, $ff, $f8, $ff, $ff, $ff, $f0, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $3f, $ff, $ff, $ff, $7f, $ff, $bf, $ff, $7f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $87, $ff, $fa, $ff, $82, $ff, $7a, $ff, $83, $ff, $ff, $ff
	db $fe, $ff, $fe, $ff, $08, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $0e, $ff, $ff, $ff
	db $ef, $ff, $ff, $ff, $2b, $ff, $eb, $ff, $eb, $ff, $ed, $ff, $ee, $ff, $ff, $ff
	db $7f, $ff, $7f, $ff, $17, $ff, $77, $ff, $77, $ff, $78, $ff, $7f, $ff, $f8, $ff
	db $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $3f, $ff, $bf, $ff, $bf, $ff, $7f, $ff
	db $ff, $ff, $ff, $ff, $87, $ff, $fb, $ff, $83, $ff, $7b, $ff, $83, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $7a, $ff, $7a, $ff, $82, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0e, $ff, $f5, $ff, $f5, $ff, $f5, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $1c, $ff, $eb, $ff, $eb, $ff, $eb, $ff
	db $ff, $ff, $ff, $ff, $df, $ff, $df, $ff, $1f, $ff, $df, $ff, $df, $ff, $df, $ff
	db $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $a3, $ff, $9d, $ff, $bd, $ff, $bd, $ff
	db $ff, $ff, $ff, $ff, $77, $ff, $f7, $ff, $41, $ff, $77, $ff, $77, $ff, $77, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $9f, $ff
	db $ff, $ff, $ff, $ff, $ee, $ff, $ee, $ff, $82, $ff, $ee, $ff, $ee, $ff, $ee, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $8e, $ff, $75, $ff, $f4, $ff, $f5, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $1f, $ff, $ef, $ff, $0f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $de, $ff, $de, $ff, $de, $ff, $d2, $ff, $d2, $ff, $cc, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $7b, $ff, $03, $ff, $7f, $ff
	db $fb, $ff, $87, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $bd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $9f, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7b, $ff, $7b, $ff, $7b, $ff, $02, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ec, $ff, $eb, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $18, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7e, $ff, $bd, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bb, $ff, $7b, $ff, $e0, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $a3, $ff, $9d, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $7b, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f0, $ff, $f7, $ff, $f7, $ff, $f0, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff, $bf, $ff, $b0, $ff, $6f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $ff, $5d, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $df, $ff, $df, $ff, $06, $ff, $df, $ff
	db $7a, $ff, $7a, $ff, $7b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f5, $ff, $f5, $ff, $0e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ec, $ff, $ef, $ff, $18, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $30, $ff, $d7, $ff, $38, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $3b, $ff, $f7, $ff, $2f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fb, $ff, $fb, $ff, $fb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e0, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $5d, $ff, $dd, $ff, $5d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $de, $ff, $dd, $ff, $de, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0b, $ff, $ec, $ff, $0f, $ff, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d7, $ff, $17, $ff, $d8, $ff, $3f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ae, $ff, $ae, $ff, $6e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $06, $ff, $df, $ff, $de, $ff, $dd, $ff, $de, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1b, $ff, $eb, $ff, $0a, $ff, $e9, $ff, $0b, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e0, $ff, $5f, $ff, $61, $ff, $fe, $ff, $41, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1f, $ff, $ef, $ff, $0f, $ff, $ef, $ff, $0f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $d1, $ff, $ce, $ff, $df, $ff, $df, $ff, $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c3, $ff, $fd, $ff, $c1, $ff, $bd, $ff, $c1, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $86, $ff, $7a, $ff, $7a, $ff, $06, $ff, $7e, $ff, $7f, $ff, $ff, $ff, $ff, $ff
	db $c1, $ff, $bd, $ff, $bd, $ff, $bd, $ff, $c3, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fc, $ff, $ff, $ff, $fc, $ff, $fb, $ff, $fc, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $ff, $d7, $ff, $17, $ff, $d7, $ff, $18, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $41, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $61, $ff, $5e, $ff, $5e, $ff, $5e, $ff, $61, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $87, $ff, $bb, $ff, $bb, $ff, $bb, $ff, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $86, $ff, $fa, $ff, $82, $ff, $7a, $ff, $82, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1c, $ff, $eb, $ff, $eb, $ff, $eb, $ff, $ec, $ff, $ff, $ff
	db $df, $ff, $df, $ff, $1f, $ff, $df, $ff, $df, $ff, $df, $ff, $3f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $86, $ff, $7a, $ff, $02, $ff, $7e, $ff, $82, $ff, $ff, $ff
	db $df, $ff, $df, $ff, $18, $ff, $d7, $ff, $d8, $ff, $df, $ff, $30, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $86, $ff, $7a, $ff, $7a, $ff, $7a, $ff, $87, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $f4, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $0f, $ff, $ff, $ff
	db $7f, $ff, $7f, $ff, $1f, $ff, $7f, $ff, $7f, $ff, $7f, $ff, $7f, $ff, $ff, $ff
	db $ee, $ff, $ee, $ff, $82, $ff, $ee, $ff, $ee, $ff, $ee, $ff, $ee, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $8e, $ff, $75, $ff, $f4, $ff, $f5, $ff, $f6, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1f, $ff, $ef, $ff, $0f, $ff, $ff, $ff, $0f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $93, $ff, $6d, $ff, $6d, $ff, $6d, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $7a, $ff, $7b, $ff, $7b, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $04, $ff, $ff, $ff, $0f, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff, $1f, $ff, $7f, $ff, $7f, $ff, $7f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7b, $ff, $b6, $ff, $ce, $ff, $b6, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0c, $ff, $fb, $ff, $f8, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $f2, $ff, $fb, $ff, $3b, $ff, $db, $ff, $1b, $ff, $fb, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff, $61, $ff, $5e, $ff, $40, $ff, $5f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $86, $ff, $bb, $ff, $bb, $ff, $bb, $ff
	db $ff, $ff, $ff, $ff, $bf, $ff, $bf, $ff, $0f, $ff, $bf, $ff, $bf, $ff, $bf, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e0, $ff, $df, $ff, $e1, $ff, $fe, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $ff, $bd, $ff, $bd, $ff, $83, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $87, $ff, $7a, $ff, $02, $ff, $7e, $ff
	db $ff, $ff, $ff, $ff, $fb, $ff, $ff, $ff, $0b, $ff, $fb, $ff, $fb, $ff, $fa, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0f, $ff, $f4, $ff, $07, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0f, $ff, $ff, $ff, $ff, $ff
	db $6d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0c, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0b, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $27, $ff, $b7, $ff, $b5, $ff, $b5, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $f7, $ff, $f7, $ff, $c1, $ff, $f7, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $47, $ff, $3b, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0e, $ff, $75, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $df, $ff, $df, $ff, $1f, $ff, $df, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7e, $ff, $7e, $ff, $60, $ff, $5e, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fe, $ff, $f8, $ff, $fe, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $30, $ff, $ef, $ff
	db $b5, $ff, $b6, $ff, $b7, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $cf, $ff, $2f, $ff, $ef, $ff, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7f, $ff, $7e, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $05, $ff, $f5, $ff, $05, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $74, $ff, $75, $ff, $76, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0b, $ff, $fb, $ff, $0c, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7b, $ff, $7b, $ff, $87, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $a0, $ff, $af, $ff, $b0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $5f, $ff, $df, $ff, $5f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $ff, $ff
	db $87, $ff, $7a, $ff, $7a, $ff, $82, $ff, $fb, $ff, $87, $ff, $ff, $ff, $ff, $ff
	db $f0, $ff, $ff, $ff, $f0, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $c1, $ff, $77, $ff, $77, $ff, $77, $ff, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $f8, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $28, $ff, $e7, $ff, $ef, $ff, $ef, $ff, $ef, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $e1, $ff, $5e, $ff, $40, $ff, $5f, $ff, $60, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $4e, $ff, $b7, $ff, $b6, $ff, $b5, $ff, $b6, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1f, $ff, $ef, $ff, $0f, $ff, $ef, $ff, $0b, $ff, $fc, $ff, $ff, $ff, $ff, $ff
	db $b0, $ff, $af, $ff, $af, $ff, $af, $ff, $b0, $ff, $7f, $ff, $ff, $ff, $ff, $ff
	db $d1, $ff, $4e, $ff, $5f, $ff, $5f, $ff, $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fc, $ff, $fd, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1c, $ff, $ef, $ff, $ec, $ff, $eb, $ff, $1c, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $ff, $d7, $ff, $18, $ff, $df, $ff, $10, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $30, $ff, $ef, $ff, $60, $ff, $af, $ff, $70, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $7f, $ff, $7f, $ff, $ff, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $87, $ff, $7a, $ff, $7b, $ff, $7b, $ff, $87, $ff, $ff, $ff
	db $cf, $ff, $b7, $ff, $bf, $ff, $0f, $ff, $bf, $ff, $bf, $ff, $bf, $ff, $ff, $ff
	db $fb, $ff, $fb, $ff, $e0, $ff, $fb, $ff, $fb, $ff, $fb, $ff, $fb, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $c3, $ff, $bd, $ff, $81, $ff, $bf, $ff, $c1, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $46, $ff, $3a, $ff, $7e, $ff, $7e, $ff, $7e, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $8e, $ff, $75, $ff, $fd, $ff, $fd, $ff, $fe, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $1a, $ff, $e9, $ff, $eb, $ff, $eb, $ff, $1b, $ff, $ff, $ff
	db $f7, $ff, $ff, $ff, $36, $ff, $d5, $ff, $f6, $ff, $f7, $ff, $f4, $ff, $ff, $ff
	db $fe, $ff, $fe, $ff, $08, $ff, $fe, $ff, $1e, $ff, $ee, $ff, $1e, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $30, $ff, $ef, $ff, $f0, $ff, $ff, $ff, $e0, $ff, $ff, $ff
	db $fe, $ff, $ff, $ff, $7e, $ff, $fe, $ff, $fe, $ff, $7e, $ff, $fe, $ff, $ff, $ff
	db $fc, $ff, $fb, $ff, $f7, $ff, $f0, $ff, $f7, $ff, $f7, $ff, $f7, $ff, $ff, $ff
	db $fc, $ff, $7b, $ff, $bb, $ff, $20, $ff, $bb, $ff, $bb, $ff, $bb, $ff, $ff, $ff
	db $ff, $ff, $7f, $ff, $e1, $ff, $de, $ff, $de, $ff, $e0, $ff, $fe, $ff, $e1, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $81, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $7f, $ff, $47, $ff, $3b, $ff, $7b, $ff, $7a, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $0c, $ff, $f5, $ff, $05, $ff, $f5, $ff
	db $ff, $ff, $ff, $ff, $f7, $ff, $ff, $ff, $36, $ff, $d5, $ff, $d6, $ff, $d7, $ff
	db $ff, $ff, $ff, $ff, $fe, $ff, $fe, $ff, $08, $ff, $fe, $ff, $1e, $ff, $ee, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $30, $ff, $ff, $ff, $f0, $ff, $ef, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $ff, $5d, $ff, $5d, $ff, $5d, $ff
	db $d4, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $1e, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $5d, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	ds 2208, 0	; $7760-$7FFF unused
