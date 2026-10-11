; Sanrio Carnival 2 sound, bank $01: macros, drums, waves, length tables, song table, $6D00-$6E31

; envelope macros (frames, NRx2; NRx2 0 = no change). Rows of $FF frames
; run on into the next macro, but they last 255 frames per note. ch1/ch2
EnvMacro_00:
	mrow $02, $f1
	mrow $0a, $a4
	mrow $1c, $77
	mrow $ff, $30
; ch1/ch2
EnvMacro_08:
	mrow $02, $d1
	mrow $0e, $84
	mrow $ff, $30
; ch1/ch2
EnvMacro_0E:
	mrow $02, $b1
	mrow $10, $64
	mrow $ff, $20
; ch2
EnvMacro_14:
	mrow $07, $6c
	mrow $ff, $c0
; ch3: frames, NR32
EnvMacro_18:
	mrow $ff, $20
; ch3
EnvMacro_1A:
	mrow $ff, $40
	mrow $ff, $40
; ch3
EnvMacro_1E:
	mrow $01, $20
	mrow $04, $40
	mrow $ff, $60
; ch4
EnvMacro_24:
	mrow $01, $e1
	mrow $ff, $24
; ch4
EnvMacro_28:
	mrow $01, $71
	mrow $ff, $24
; pitch macro (frames, offset), the only one: 510 frames flat, then alternates $80 / $90
PitchMacro_2C:
	mrow $ff, $00
	mrow $ff, $00
	mrow $0a, $00
.vibrato:
	mrow $0a, $80
	mrow $0a, $90
	mloop PitchMacro_2C.vibrato
; drums 1-2: macro low byte, page (the code reads DrumTable-2 + 2*drum)
DrumTable:
	db LOW(DrumMacro1), HIGH(DrumMacro1)
	db LOW(DrumMacro2), HIGH(DrumMacro2)
; drum macros: frames, NR43
DrumMacro1:
	mrow $01, $5e
.hold:
	mrow $ff, $6e
	mloop DrumMacro1.hold
DrumMacro2:
	mrow $04, $3f
.hold:
	mrow $ff, $20
	mloop DrumMacro2.hold
; not in DrumTable
DrumMacro3_Unused:
	mrow $ff, $42
	mrow $ff, $42
	mloop DrumMacro3_Unused
; waves (Cmd_Wave)
Wave1:
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
Wave2:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave3:
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10
; length tables, frames (Cmd_LengthTable); packed length bytes use index 0-12
LengthTable1:
	db 5, 10, 20, 40, 80, 0, 120, 60, 100, 50, 30, 0, 0
LengthTable2:
	db 4, 8, 16, 32, 64, 128, 96, 48, 80, 40, 24, 0, 0
LengthTable3:
	db 3, 6, 12, 24, 48, 96, 72, 36, 60, 30, 18, 8, 16
LengthTable4:
	db 2, 4, 8, 16, 32, 64, 48, 24, 40, 20, 12, 0, 0
; songs $00-$0F: ch1-ch4 streams (0 = channel unused); $00, $0E, $0F are silence.
; $0A, $0B, $0D start songs $02, $03, $01 at their loop (no intro; $0A and $0B with a faster
; length table), $0C = jingle $04 followed by song $05
SongTable:
	dw 0, 0, 0, 0	; $00
	dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4	; $01
	dw Song02_Ch1, Song02_Ch2, Song02_Ch3, 0	; $02
	dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4	; $03
	dw Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4	; $04
	dw Song05_Ch1, Song05_Ch2, Song05_Ch3, 0	; $05
	dw Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4	; $06
	dw Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4	; $07
	dw Song08_Ch1, Song08_Ch2, Song08_Ch3, 0	; $08
	dw Song09_Ch1, Song09_Ch2, Song09_Ch3, 0	; $09
	dw Song0A_Ch1, Song0A_Ch2, Song0A_Ch3, 0	; $0A
	dw Song0B_Ch1, Song0B_Ch2, Song0B_Ch3, Song0B_Ch4	; $0B
	dw Song0C_Ch1, Song0C_Ch2, Song0C_Ch3, Song04_Ch4	; $0C
	dw Song0D_Ch1, Song0D_Ch2, Song0D_Ch3, Song0D_Ch4	; $0D
	dw 0, 0, 0, 0	; $0E
	dw 0, 0, 0, 0	; $0F
