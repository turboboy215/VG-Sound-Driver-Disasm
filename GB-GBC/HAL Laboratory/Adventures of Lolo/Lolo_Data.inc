; bank $0F: waves, songs, SFX, envelopes, instruments, length sets ($4000-$7DD4)

Wave0:
	db $22, $66, $AA, $EE, $FF, $FF, $FE, $EA, $A6, $66, $8A, $CF, $FE, $EC, $A6, $33
Wave1:
	db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00
Wave2:
	db $13, $57, $9B, $DF, $DB, $97, $53, $10, $13, $57, $9B, $DF, $DB, $97, $53, $10
Sfx00:
	db 1  ; tracks
	track Sfx00_CH2, CH2
Sfx01:
	db 1  ; tracks
	track Sfx01_CH2, CH2
Sfx02:
	db 1  ; tracks
	track Sfx02_CH2, CH2
Sfx03:
	db 2  ; tracks
	track Sfx03_CH1, CH1
	track Sfx03_CH2, CH2
Sfx04:
	db 1  ; tracks
	track Sfx04_CH2, CH2
Sfx05:
	db 2  ; tracks
	track Sfx05_CH4, CH4
	track Sfx05_CH2, CH2
Sfx07:
	db 1  ; tracks
	track Sfx07_CH4, CH4
Sfx08:
	db 2  ; tracks
	track Sfx08_CH4, CH4
	track Sfx08_CH2, CH2
Sfx09:
	db 1  ; tracks
	track Sfx09_CH2, CH2
Sfx10:
	db 2  ; tracks
	track Sfx10_CH1, CH1
	track Sfx10_CH2, CH2
Sfx12:
	db 1  ; tracks
	track Sfx12_CH2, CH2
Sfx13:
	db 1  ; tracks
	track Sfx13_CH2, CH2
Sfx14:
	db 3  ; tracks
	track Sfx14_CH1, CH1
	track Sfx14_CH2, CH2
	track Sfx14_CH1_2, CH1
Sfx15:
	db 1  ; tracks
	track Sfx15_CH2, CH2
Sfx16:
	db 2  ; tracks
	track Sfx16_CH1, CH1
	track Sfx16_CH2, CH2
Sfx17:
	db 2  ; tracks
	track Sfx17_CH1, CH1
	track Sfx17_CH2, CH2
Sfx18:
	db 1  ; tracks
	track Sfx18_CH2, CH2
Sfx19:
	db 2  ; tracks
	track Sfx19_CH4, CH4
	track Sfx19_CH2, CH2
Sfx20:
	db 1  ; tracks
	track Sfx20_CH4, CH4
Sfx21:
	db 1  ; tracks
	track Sfx21_CH2, CH2
Sfx22:
	db 1  ; tracks
	track Sfx22_CH2, CH2
Sfx23:
	db 1  ; tracks
	track Sfx23_CH2, CH2
Sfx24:
	db 2  ; tracks
	track Sfx24_CH1, CH1
	track Sfx24_CH2, CH2
Song00:
	db 2  ; tracks
	track Song00_CH1, CH1
	track Song00_CH2, CH2
Sfx25:
	db 1  ; tracks
	track Sfx25_CH2, CH2
Sfx26:
	db 1  ; tracks
	track Sfx26_CH2, CH2
Song01:
	db 4  ; tracks
	track Song01_CH1, CH1
	track Song01_CH2, CH2
	track Song01_CH3, CH3
	track Song01_CH4, CH4
Song02:
	db 4  ; tracks
	track Song02_CH1, CH1
	track Song02_CH2, CH2
	track Song02_CH3, CH3
	track Song02_CH4, CH4
Song03:
	db 2  ; tracks
	track Song03_CH3, CH3
	track Song03_CH4, CH4
Song04:
	db 4  ; tracks
	track Song04_CH1, CH1
	track Song04_CH2, CH2
	track Song04_CH3, CH3
	track Song04_CH4, CH4
Song05:
	db 4  ; tracks
	track Song05_CH1, CH1
	track Song05_CH2, CH2
	track Song05_CH3, CH3
	track Song05_CH4, CH4
Song06:
	db 4  ; tracks
	track Song06_CH1, CH1
	track Song06_CH2, CH2
	track Song06_CH3, CH3
	track Song06_CH4, CH4
Song07:
	db 4  ; tracks
	track Song07_CH1, CH1
	track Song07_CH2, CH2
	track Song07_CH3, CH3
	track Song07_CH4, CH4
Song08:
	db 4  ; tracks
	track Song08_CH1, CH1
	track Song08_CH2, CH2
	track Song08_CH3, CH3
	track Song08_CH4, CH4
Song09:
	db 3  ; tracks
	track Song09_CH1, CH1
	track Song09_CH2, CH2
	track Song09_CH3, CH3
Song10:
	db 1  ; tracks
	track Song10_CH1, CH1
Song11:
	db 1  ; tracks
	track Song11_CH1, CH1
Song12:
	db 1  ; tracks
	track Song12_CH1, CH1
Song13:
	db 1  ; tracks
	track Song13_CH1, CH1
Song14:
	db 1  ; tracks
	track Song14_CH1, CH1
Song15:
	db 4  ; tracks
	track Song15_CH1, CH1
	track Song15_CH2, CH2
	track Song15_CH3, CH3
	track Song15_CH4, CH4
Song16:
	db 4  ; tracks
	track Song16_CH1, CH1
	track Song16_CH2, CH2
	track Song16_CH3, CH3
	track Song16_CH4, CH4
Song17:
	db 3  ; tracks
	track Song17_CH1, CH1
	track Song17_CH2, CH2
	track Song17_CH3, CH3
Song18:
	db 4  ; tracks
	track Song18_CH1, CH1
	track Song18_CH2, CH2
	track Song18_CH3, CH3
	track Song18_CH4, CH4
Song19:
	db 3  ; tracks
	track Song19_CH1, CH1
	track Song19_CH2, CH2
	track Song19_CH3, CH3
Song20:
	db 4  ; tracks
	track Song20_CH1, CH1
	track Song20_CH2, CH2
	track Song20_CH3, CH3
	track Song20_CH4, CH4
Song21:
	db 3  ; tracks
	track Song21_CH1, CH1
	track Song21_CH2, CH2
	track Song21_CH3, CH3
Song22:
	db 3  ; tracks
	track Song22_CH1, CH1
	track Song22_CH2, CH2
	track Song22_CH3, CH3
Sfx00_CH2:
	pan PAN_LR
	base_note $29
	length_set 0
	volume 15
	instrument 2
	note -1, 0
	note 3, 0
	note 1, 0
	note 5, 0
	volume 12
	note 3, 0
	note 7, 0
	volume 8
	note 5, 0
	note 9, 0
	snd_end
Sfx01_CH2:
	pan PAN_LR
	length_set 0
	instrument 2
	gate 0
	volume 15
	base_note $2B
	snd_call Sub_41CD
	base_note $27
	snd_call Sub_41CD
	base_note $23
	snd_call Sub_41CD
	base_note $0F
	instrument 5
	note -2, 2
	note -2, 2
	note -2, 2
	snd_end
Sub_41CD:
	note -10, 0
	snd_loop 2
	detune 10
	hold 1
	snd_endloop
	rest 1
	note -1, 0
	snd_loop 6
	detune -11
	hold 1
	snd_endloop
	rest 0
	snd_ret
Sfx02_CH2:
	base_note $14
	instrument 2
	pan PAN_LR
	gate 0
	length_set 0
	volume 15
	note 5, 0
	snd_loop 2
	note -1, 0
	note -7, 0
	note -12, 0
	note -7, 0
	note -1, 0
	snd_endloop
	note 2, 0
	note 10, 0
	snd_end
Sfx03_CH1:
	pan PAN_LR
	base_note $1B
	length_set 0
	instrument 2
	volume 12
	gate 0
	note -10, 0
	note -5, 0
	note 2, 0
	note 7, 0
	note 11, 1
	base_note $2C
	note -3, 1
	note 2, 1
	snd_loop 7
	note 6, 0
	note 9, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx03_CH2:
	pan PAN_LR
	base_note $1B
	length_set 0
	instrument 2
	volume 12
	gate 0
	note_x -10, 0
	detune -3
	hold 1
	note_x -5, 0
	detune -3
	hold 1
	note_x 2, 0
	detune -3
	hold 1
	note_x 7, 0
	detune -2
	hold 1
	note_x 11, 0
	detune -2
	hold 2
	base_note $2C
	note_x -3, 0
	detune -2
	hold 2
	note_x 2, 0
	detune -1
	hold 2
	snd_loop 7
	note_x 2, 1
	note_x 9, 0
	detune -1
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx04_CH2:
	pan PAN_LR
	base_note $0F
	length_set 0
	instrument 2
	gate 0
	volume 15
	note -11, 0
	note -10, 1
	note -11, 0
	note -12, 0
	note 2, 1
	note 10, 0
	volume 13
	note 9, 0
	volume 11
	note -1, 0
	note 0, 1
	volume 10
	note -1, 0
	note -2, 0
	snd_end
Sfx05_CH4:
	pan PAN_LR
	length_set 0
	instrument 2
	gate 0
	volume 9
	drum 2, 2
	drum 3, 0
	volume 10
	drum 5, 1
	volume 9
	drum 7, 1
	volume 12
	drum 8, 1
	volume 13
	drum 11, 0
	drum 10, 0
	volume 15
	drum 12, 0
	drum 13, 0
	drest 0
	snd_end
Sfx05_CH2:
	pan PAN_LR
	base_note $14
	length_set 0
	instrument 2
	gate 0
	volume 1
	hold 2
	note 15, 0
	volume 6
	note 14, 0
	volume 10
	note 11, 0
	note 10, 0
	volume 12
	note 2, 0
	note -2, 0
	volume 14
	note -6, 0
	volume 15
	note -10, 0
	note -11, 0
	note -15, 0
	note -14, 0
	snd_end
Sfx07_CH4:
	pan PAN_LR
	base_note $27
	length_set 0
	volume 15
	gate 0
	instrument 8
	drum 10, 2
	instrument 5
	drum 3, 0
	instrument 6
	drum 11, 1
	instrument 5
	drum 5, 0
	instrument 6
	drum 10, 1
	instrument 5
	drum 4, 0
	instrument 6
	drum 13, 1
	instrument 7
	drum 8, 2
	instrument 6
	drum 11, 1
	instrument 7
	drum 9, 2
	volume 13
	instrument 2
	snd_loop 6
	drum_x 4, 2
	volume_add -1
	hold 1
	drum_x 3, 2
	volume_add -1
	hold 2
	snd_endloop
	drest 0
	snd_end
Sfx08_CH4:
	pan PAN_LR
	base_note $27
	length_set 0
	gate 0
	instrument 2
	volume 15
	hold 1
	drum 14, 1
	drum 13, 1
	drum 12, 1
	drum 11, 0
	drum 10, 0
	drum 9, 0
	drum 8, 0
	drest 0
	snd_end
Sfx08_CH2:
	pan PAN_LR
	base_note $0F
	instrument 0
	gate 0
	length_set 0
	volume 8
	note -12, 5
	note -11, 0
	note -10, 0
	note -9, 0
	note -8, 0
	note -7, 0
	note -6, 0
	note -5, 0
	note -4, 0
	note -3, 0
	note -2, 0
	snd_end
Sfx09_CH2:
	pan PAN_LR
	base_note $27
	length_set 0
	volume 15
	gate 0
	instrument 2
	note -7, 0
	note 1, 0
	note 6, 0
	note 3, 0
	volume 13
	note -3, 0
	note 5, 0
	note 10, 0
	note 7, 0
	volume 10
	note 0, 0
	note 8, 0
	note 13, 0
	note 10, 0
	volume 7
	note 2, 0
	note 10, 0
	note 15, 0
	note 12, 0
	base_note $33
	volume 4
	note -9, 0
	note -1, 0
	note 4, 0
	note 1, 0
	volume 3
	note -8, 0
	note 0, 0
	note 5, 0
	note 2, 0
	volume 1
	note -7, 0
	note 1, 0
	note 6, 0
	note 3, 0
	snd_end
Sfx10_CH1:
	pan PAN_LR
	base_note $22
	length_set 0
	volume 12
	instrument 2
	gate 0
	note 12, 1
	note 13, 1
	note 14, 1
	note 15, 2
	rest 3
	note 10, 0
	rest 0
	note 10, 0
	rest 0
	note 8, 0
	rest 0
	note 8, 0
	rest 0
	note 6, 0
	rest 0
	note 6, 0
	rest 0
	note 4, 0
	rest 0
	note 4, 0
	rest 0
	note 2, 0
	rest 0
	note 2, 0
	rest 0
	note -2, 0
	rest 0
	note -2, 0
	rest 0
	note -6, 0
	rest 0
	note -6, 0
	rest 0
	note -10, 0
	rest 0
	note -10, 0
	rest 0
	note -14, 0
	rest 0
	note -14, 0
	rest 0
	hold 12
	snd_end
Sfx10_CH2:
	pan PAN_LR
	base_note $2E
	length_set 0
	instrument 0
	volume 11
	gate 0
	note -1, 0
	detune 10
	note 0, 1
	note 1, 1
	note 2, 1
	note 3, 1
	base_note $1D
	rest 4
	instrument 2
	note 14, 0
	rest 0
	note 14, 0
	rest 0
	note 12, 0
	rest 0
	note 12, 0
	rest 0
	note 10, 0
	rest 0
	note 10, 0
	rest 0
	note 8, 0
	rest 0
	note 8, 0
	rest 0
	note 5, 0
	rest 0
	note 5, 0
	rest 0
	note 1, 0
	rest 0
	note 1, 0
	rest 0
	note -3, 0
	rest 0
	note -3, 0
	rest 0
	note -7, 0
	rest 0
	note -7, 0
	rest 0
	note -11, 0
	rest 0
	note -11, 0
	rest 2
	note -7, 0
	base_note $0F
	note 7, 0
	snd_loop 2
	detune -50
	hold 1
	snd_endloop
	note_x 12, 1
	snd_loop 6
	detune -60
	hold 1
	snd_endloop
	snd_end
	pan PAN_LR  ; unreferenced (stream)
	instrument 16
	gate 0
	length_set 0
	volume 15
	note -15, 2
	note -11, 2
	note -10, 1
	note -8, 2
	note -3, 2
	note 1, 2
	note 2, 1
	note 4, 2
	note 9, 1
	volume 14
	snd_loop 4
	note 13, 1
	note 9, 1
	snd_endloop
	snd_end
	pan PAN_LR  ; unreferenced (stream)
	instrument 16
	gate 0
	base_note $35
	length_set 0
	volume 15
	note -12, 2
	note -8, 2
	note -7, 1
	note -5, 2
	note 0, 2
	note 4, 2
	note 5, 1
	note 7, 2
	note 12, 1
	note 12, 3
	note 12, 3
	note 12, 3
	note 12, 3
	snd_end
Sfx12_CH2:
	pan PAN_LR
	base_note $33
	volume 15
	instrument 2
	gate 0
	length_set 0
	note -6, 0
	note -3, 0
	note -2, 0
	instrument 16
	base_note $2A
	snd_loop 2
	note 3, 0
	note 4, 0
	snd_endloop
	note 2, 0
	note 1, 0
	instrument 2
	volume 10
	note -4, 0
	note -2, 0
	note -5, 0
	note -7, 0
	volume 7
	note -11, 0
	note -9, 0
	note -12, 0
	note -13, 0
	volume 4
	base_note $15
	note 3, 0
	note 5, 0
	volume 1
	note 2, 0
	note 1, 0
	snd_end
Sfx13_CH2:
	pan PAN_LR
	base_note $33
	instrument 2
	gate 0
	length_set 0
	volume 15
	note -3, 0
	note 1, 0
	note -2, 0
	note 2, 0
	note -1, 0
	note 3, 0
	volume 12
	note 0, 0
	note 4, 0
	volume 8
	note 1, 0
	note 6, 0
	snd_end
Sfx14_CH1:
	volume 12
Seq_446D:
	pan PAN_LR
	base_note $2B
	instrument 6
	gate 0
	length_set 0
	volume 15
	note -14, 2
	note -15, 0
	note -14, 2
	note -9, 2
	note -2, 3
	note -3, 0
	note -2, 3
	note 3, 3
	note -2, 3
	instrument 7
	note 3, 4
	note 7, 4
	note 9, 0
	note 10, 5
	note 14, 1
	note_x 15, 7
	instrument 5
	note 10, 1
	rest 0
	instrument 8
	note_x 10, 20
	snd_end
Sfx14_CH2:
	pan PAN_LR
	base_note $2B
	instrument 7
	gate 0
	length_set 0
	volume 12
	note_x -14, 0
	detune -5
	hold 3
	note_x -3, 0
	detune -5
	hold 1
	note_x -14, 0
	detune -5
	hold 3
	note_x -9, 0
	detune -4
	hold 3
	note_x -2, 0
	detune -4
	hold 4
	note_x -3, 0
	detune -4
	hold 1
	note_x -2, 0
	detune -4
	hold 4
	note_x 3, 0
	detune -4
	hold 4
	note_x -2, 0
	detune -4
	hold 4
	note_x 3, 0
	detune -3
	hold 5
	note_x 7, 0
	detune -3
	hold 5
	note_x 9, 0
	detune -3
	hold 1
	note_x 10, 0
	detune -2
	hold 6
	instrument 8
	note_x 14, 0
	detune -1
	hold 2
	note_x 15, 0
	detune -1
	hold 7
	instrument 6
	note 10, 1
	rest 0
	instrument 9
	note_x 10, 0
	detune -1
	hold 20
	snd_end
Sfx14_CH1_2:
	volume 0
	snd_jump Seq_446D
Sfx15_CH2:
	pan PAN_LR
	base_note $3A
	instrument 2
	gate 0
	volume 15
	length_set 0
	note -12, 1
	note -8, 1
	snd_end
Sfx16_CH1:
	snd_call Sub_4539
	note 4, 1
	instrument 7
	note 5, 5
	hold 1
	snd_end
Sfx16_CH2:
	snd_call Sub_4539
	note_x 3, 0
	detune -1
	hold 2
	instrument 7
	note_x 5, 0
	detune -1
	hold 7
	snd_end
Sub_4539:
	pan PAN_LR
	base_note $30
	instrument 16
	gate 0
	volume 15
	length_set 0
	snd_ret
Sfx17_CH1:
	base_note $1D
	pan PAN_LR
	instrument 2
	gate 0
	length_set 0
	volume 15
	note 4, 3
	rest 1
	snd_loop 15
	note 6, 0
	note 5, 0
	snd_endloop
	snd_end
Sfx17_CH2:
	pan PAN_LR
	base_note $1D
	instrument 2
	gate 0
	length_set 0
	volume 15
	note 5, 3
	rest 1
	snd_loop 15
	note 5, 0
	note 4, 0
	snd_endloop
	snd_end
Sfx18_CH2:
	pan PAN_LR
	instrument 2
	gate 0
	length_set 0
	volume 13
	base_note $0F
	note 12, 0
	note 8, 0
	note 4, 0
	note -1, 0
	note -4, 0
	note -8, 0
	rest 2
	note 6, 0
	note 1, 0
	note -2, 0
	note -5, 0
	note -8, 0
	note -12, 0
	rest 1
	note 1, 0
	note -4, 0
	note -7, 0
	note -10, 0
	note -13, 0
	note -15, 0
	base_note $1B
	note -7, 0
	rest 0
	note 9, 0
	note 4, 0
	note 1, 0
	note -2, 0
	note -5, 0
	note -9, 0
	rest 0
	snd_loop 4
	base_note $1B
	note -14, 0
	note -11, 0
	note -4, 0
	note -1, 0
	note 4, 0
	base_note $27
	note -5, 0
	note 1, 0
	note 9, 0
	snd_endloop
	snd_end
Sfx19_CH4:
	pan PAN_LR
	length_set 0
	instrument 1
	volume 12
	gate 0
	drum 6, 0
	drum 14, 0
	drest 0
	drum 10, 0
	volume 15
	drum 7, 0
	drest 0
	drum 5, 0
	drum 10, 0
	volume 8
	snd_loop 3
	drum 14, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx19_CH2:
	pan PAN_LR
	length_set 0
	gate 0
	instrument 3
	volume 6
	base_note $0E
	note 15, 0
	volume_add 1
	note 12, 0
	rest 0
	volume_add 2
	note 8, 0
	volume_add 2
	note 4, 0
	volume_add -2
	rest 0
	note 3, 0
	volume_add -1
	note -4, 0
	volume_add -3
	snd_loop 3
	note -11, 0
	note -12, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx20_CH4:
	pan PAN_LR
	length_set 0
	instrument 1
	gate 0
	volume 13
	drum 1, 2
	drum_x 14, 3
	drum_x 13, 3
	drum_x 12, 3
	drum_x 11, 3
	drum_x 10, 3
	drum_x 9, 3
	snd_end
	pan PAN_LR  ; unreferenced (stream)
Sfx21_CH2:
	length_set 0
	gate 200
	volume 15
	instrument 2
	base_note $33
	note_x 7, 1
	snd_loop 5
	detune 1
	hold 2
	detune 1
	hold 2
	snd_endloop
	snd_loop 5
	detune 1
	hold 1
	volume_add -2
	hold 1
	detune 1
	hold 2
	volume_add -2
	snd_endloop
	snd_end
Sfx22_CH2:
	pan PAN_LR
	length_set 0
	volume 15
	instrument 26, STATIC
	gate 0
	base_note $33
	note -3, 5
	note 2, 3
	note 0, 5
	note 7, 3
	note 5, 5
	note 10, 3
	note 9, 5
	note 14, 3
	note_x 12, 12
	snd_loop 4
	volume_add -3
	hold 3
	snd_endloop
	snd_end
Sfx23_CH2:
	instrument 2
	gate 0
	volume 15
	pan PAN_LR
	length_set 0
	base_note $2E
	snd_call Sub_4671
	base_note $2F
	snd_call Sub_4671
	base_note $30
	snd_call Sub_4671
	snd_loop 5
	snd_call Sub_4674
	volume_add -5
	snd_endloop
	snd_end
Sub_4671:
	note -12, 1
	note -5, 1
	note 0, 1
Sub_4674:
	note 2, 1
	note 4, 1
	note 0, 1
	note 12, 1
	snd_ret
	snd_end  ; unreferenced (stream)
Sfx24_CH1:
	length_set 0
	base_note $27
Seq_467E:
	instrument 2
	pan PAN_LR
	gate 0
	volume 15
	snd_loop 3
	note 8, 1
	volume_add -4
	snd_endloop
	snd_end
Sfx24_CH2:
	length_set 0
	base_note $1F
	snd_jump Seq_467E
	snd_end  ; unreferenced (stream)
Song00_CH1:
	length_set 2
	base_note $2B
	pan PAN_LR
	volume 11
	instrument 31
	gate 0
	note_x -8, 1
	note_x -7, 1
	note_x -6, 1
	gate 200
	note -5, 2
	note_x -5, 4
	note_x -5, 4
	note_x -5, 4
	note -5, 0
	note_x -5, 12
	note_x -5, 13
	note_x -5, 14
	note_x -3, 18
	note_x -3, 6
	note -1, 2
	note_x 2, 13
	note_x 4, 15
	note_x 6, 17
	note 7, 5
	snd_end
Song00_CH2:
	length_set 2
	base_note $1F
	pan PAN_LR
	volume 11
	instrument 31
	gate 0
	note_x -4, 1
	note_x -3, 1
	note_x -2, 1
	gate 200
	note -1, 2
	note_x -1, 4
	note_x -1, 4
	note_x -1, 4
	note 0, 0
	note_x 0, 12
	note_x 4, 13
	note_x 4, 14
	note_x 2, 18
	note_x 2, 6
	note 7, 2
	rest_x 13
	note_x 13, 15
	note_x 12, 17
	note 11, 5
	snd_end
Sfx25_CH2:
	length_set 0
	base_note $35
Seq_46F7:
	volume 15
	pan PAN_LR
	instrument 2
	gate 0
	snd_loop 6
	note 7, 0
	note 14, 2
	volume_add -4
	snd_endloop
	snd_end
Sfx26_CH2:
	length_set 0
	base_note $29
	snd_jump Seq_46F7
Song01_CH1:
	length_set 1
	volume 12
	instrument 24
	pan PAN_LR
	base_note $33
	gate 0
Seq_471A:
	snd_call Sub_4720
	snd_jump Seq_471A
Sub_4720:
	note_x -15, 2
	note_x -14, 2
	note_x -13, 2
	note_x -12, 48
	rest 0
	note -3, 0
	rest 0
	note -5, 0
	note -7, 0
	rest 1
	note -8, 3
	note 2, 0
	rest 1
	note 0, 5
	note_x -5, 2
	note_x -4, 2
	note_x -3, 2
	note_x -2, 48
	rest 0
	note -2, 1
	note -3, 0
	note -5, 0
	rest 1
	note -7, 3
	note -10, 0
	rest 1
	note -12, 5
	note -10, 2
	note -7, 1
	note -2, 2
	rest 1
	note 0, 0
	note -2, 3
	note -3, 3
	note -7, 0
	rest 0
	note -10, 0
	note -12, 5
	note -13, 3
	note -10, 3
	note -7, 1
	note -3, 3
	note -7, 3
	note -3, 1
	note -5, 1
	rest 0
	note -5, 1
	rest 0
	note -5, 1
	note 0, 1
	rest 1
	note_x 0, 10
	note_x -1, 2
	note_x -2, 2
	note_x -3, 2
	note_x -5, 2
	note_x -7, 2
	note_x -8, 2
	note_x -10, 2
	snd_ret
	snd_end  ; unreferenced (stream)
Song01_CH2:
	length_set 1
	instrument 7
	gate 180
	volume 12
Seq_4775:
	pan PAN_L
	base_note $33
	snd_call Sub_47DF
	snd_call Sub_47E2
	snd_call Sub_47DF
	snd_call Sub_47E9
	pan PAN_R
	base_note $34
	snd_call Sub_47DF
	snd_call Sub_47E2
	snd_call Sub_47DF
	snd_call Sub_47E9
	pan PAN_L
	base_note $2E
	snd_call Sub_47DF
	snd_call Sub_47E2
	snd_call Sub_47DF
	snd_call Sub_47E9
	pan PAN_R
	base_note $33
	snd_call Sub_47DF
	snd_call Sub_47E2
	snd_call Sub_47DF
	snd_call Sub_47E9
	pan PAN_LR
	volume 8
	snd_call Sub_47ED
	base_note $32
	snd_call Sub_47ED
	snd_loop 2
	base_note $31
	snd_call Sub_47ED
	snd_endloop
	base_note $2C
	snd_call Sub_47ED
	base_note $30
	snd_call Sub_47ED
	base_note $29
	snd_call Sub_47ED
	snd_call Sub_47F6
	snd_jump Seq_4775
	snd_end  ; unreferenced (stream)
Sub_47DF:
	rest 0
	note -3, 0
	snd_ret
Sub_47E2:
	snd_loop 3
	rest 0
	note -3, 0
	note -3, 0
	snd_endloop
	snd_ret
Sub_47E9:
	rest 0
	note -3, 0
	note -3, 0
	snd_ret
Sub_47ED:
	rest 0
	note 2, 0
	rest 0
	note 2, 0
	note 2, 0
	rest 0
	note 2, 0
	note 2, 0
	snd_ret
Sub_47F6:
	note 2, 2
	note_x 2, 10
	note_x 0, 2
	note_x -2, 2
	note_x -3, 2
	note_x -4, 2
	note_x -5, 2
	note_x -7, 2
	note_x -9, 2
	snd_ret
Song01_CH3:
	length_set 1
	instrument 2
	volume 15
	gate 180
	base_note $1B
	pan PAN_LR
Seq_4814:
	snd_call Sub_482F
	snd_loop 2
	snd_call Sub_4839
	snd_endloop
	snd_call Sub_482F
	snd_call Sub_4843
	snd_call Sub_484D
	snd_call Sub_4857
	snd_call Sub_4861
	snd_jump Seq_4814
Sub_482F:
	note 5, 3
	note 5, 0
	note 0, 3
	note 5, 0
	rest 0
	note 5, 1
	note 0, 0
	note 0, 1
	note 0, 1
	snd_ret
Sub_4839:
	note 7, 3
	note 0, 0
	note 0, 3
	note 7, 0
	rest 0
	note 7, 1
	note 0, 0
	note 0, 1
	note 0, 1
	snd_ret
Sub_4843:
	note -2, 3
	note 5, 0
	note 5, 3
	note -2, 0
	rest 0
	note -2, 1
	note 5, 0
	note 5, 1
	note -2, 1
	snd_ret
Sub_484D:
	note -3, 3
	note 5, 0
	note 5, 3
	note -3, 0
	rest 0
	note -3, 1
	note 5, 0
	note 5, 1
	note -3, 1
	snd_ret
Sub_4857:
	note -5, 3
	note 2, 0
	note 2, 3
	note -5, 0
	rest 0
	note -5, 1
	note 2, 0
	note 2, 1
	note -5, 1
	snd_ret
Sub_4861:
	note 0, 3
	note 0, 3
	note 0, 1
	note 0, 2
	note 0, 2
	snd_ret
Song01_CH4:
	length_set 1
	pan PAN_LR
	volume 12
	gate 0
Seq_486F:
	snd_loop 7
	snd_call Sub_487B
	snd_endloop
	snd_call Sub_48A8
	snd_jump Seq_486F
Sub_487B:
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 29
	drum 4, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 29
	drum 4, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	snd_ret
Sub_48A8:
	instrument 29
	drum 4, 3
	drum 4, 3
	drum 4, 1
	instrument 28
	drum 14, 0
	instrument 29
	drum 3, 1
	drum 2, 0
	instrument 28
	drum 14, 0
	instrument 29
	snd_loop 3
	drum 2, 0
	snd_endloop
	snd_ret
Song02_CH1:
	length_set 3
	volume 10
	pan PAN_LR
Seq_48C4:
	instrument 4
	gate 0
	base_note $27
Seq_48CA:
	snd_call Sub_48D9
	snd_call Sub_48E2
	snd_call Sub_48D9
	snd_call Sub_48E9
	snd_jump Seq_48CA
Sub_48D9:
	note -3, 4
	note -2, 4
	note -1, 1
	note 2, 0
	note 6, 2
	note 9, 0
	rest 2
	note 7, 0
	snd_ret
Sub_48E2:
	note 6, 2
	note 1, 0
	rest 2
	note -3, 0
	note -1, 2
	note -3, 0
	snd_ret
Sub_48E9:
	note 6, 2
	note 13, 0
	note 9, 3
	note -3, 2
	note -2, 0
	snd_ret
Song02_CH2:
	length_set 3
	volume 8
	pan PAN_LR
	rest_x 6
	snd_jump Seq_48C4
Song02_CH3:
	length_set 3
	instrument 2
	gate 200
	pan PAN_LR
	volume 15
	base_note $1B
Seq_4906:
	snd_call Sub_490F
	snd_call Sub_4915
	snd_jump Seq_4906
Sub_490F:
	note -5, 2
	note 7, 0
	rest 2
	note -5, 0
	note 7, 3
	snd_ret
Sub_4915:
	note -3, 2
	note 9, 0
	rest 2
	note -3, 0
	note 9, 3
	snd_ret
Song02_CH4:
	length_set 3
	gate 0
	pan PAN_LR
	volume 12
Seq_4923:
	snd_call Sub_4929
	snd_jump Seq_4923
Sub_4929:
	instrument 28
	drum 9, 0
	instrument 5
	drum 0, 0
	instrument 29
	drum 3, 3
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 3
	snd_ret
Song03_CH3:
	length_set 3
	instrument 2
	pan PAN_LR
	base_note $1B
	gate 150
	volume 15
Seq_4945:
	snd_loop 3
	snd_call Sub_4957
	snd_call Sub_495E
	snd_endloop
	snd_call Sub_4957
	snd_call Sub_4966
	snd_jump Seq_4945
Sub_4957:
	note -9, 2
	note -5, 0
	note -2, 2
	note 1, 3
	note -2, 3
	note -5, 0
	snd_ret
Sub_495E:
	note -4, 2
	note 0, 0
	note 3, 2
	note 6, 3
	note 5, 0
	note 3, 2
	note 0, 0
	snd_ret
Sub_4966:
	note -4, 2
	note -4, 0
	note -2, 2
	note -4, 3
	note -6, 0
	note -7, 2
	note -2, 0
	snd_ret
Song03_CH4:
	length_set 3
	gate 180
	pan PAN_LR
	volume 12
Seq_4976:
	snd_loop 7
	snd_call Sub_4982
	snd_endloop
	snd_call Sub_4991
	snd_jump Seq_4976
Sub_4982:
	instrument 28
	drum 9, 3
	instrument 29
	drum 3, 2
	instrument 28
	drum 9, 0
	drest 2
	drum 9, 0
	instrument 29
	drum 3, 3
	snd_ret
Sub_4991:
	instrument 28
	drum 9, 3
	instrument 29
	drum 3, 2
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 2
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 0
	snd_ret
	length_set 3  ; unreferenced (stream)
	instrument 2
	gate 150
	base_note $1B
	pan PAN_LR
	volume 10
	snd_jump Seq_4945
Song04_CH1:
	length_set 4
	volume 12
	pan PAN_LR
	base_note $24
Seq_49BD:
	snd_call Sub_49CF
	snd_call Sub_49F4
	snd_call Sub_49D3
	snd_call Sub_49FB
	snd_call Sub_49FD
	snd_jump Seq_49BD
Sub_49CF:
	instrument 14
	gate 170
Sub_49D3:
	note 3, 3
	note 3, 3
	note 3, 4
	note 2, 1
	note 0, 1
	note -2, 2
	note -2, 1
	note 0, 1
	note -2, 2
	note -4, 2
	note -5, 2
	note -4, 2
	note -2, 2
	note -4, 1
	note -5, 1
	note -7, 2
	note -7, 1
	note -5, 1
	note -7, 2
	note -2, 2
	note -7, 2
	note -7, 1
	note -5, 1
	note -7, 2
	note 2, 2
	note -7, 2
	note -3, 1
	note 0, 1
	note 5, 1
	note 3, 1
	note 2, 1
	note 0, 1
	snd_ret
Sub_49F4:
	note -2, 2
	note 2, 2
	note -2, 2
	note -2, 0
	note 0, 0
	note 2, 0
	snd_ret
Sub_49FB:
	note -2, 5
	snd_ret
Sub_49FD:
	instrument 15
	volume 9
	gate 0
	note -5, 5
	note -4, 3
	note -3, 3
	note -2, 2
	instrument 10
	volume_add 4
	base_note $30
	pan PAN_L
	note 10, 1
	note 12, 1
	snd_loop 3
	note 10, 0
	note 12, 0
	snd_endloop
	snd_loop 4
	note 10, 2
	volume_add -2
	snd_endloop
	base_note $24
	volume 9
	instrument 15
	pan PAN_LR
	note -7, 5
	note -6, 3
	note -5, 3
	note -4, 2
	base_note $30
	volume_add 4
	instrument 10
	pan PAN_L
	note 8, 1
	note 10, 1
	snd_loop 3
	note 8, 0
	note 10, 0
	snd_endloop
	snd_loop 4
	note 8, 2
	volume_add -2
	snd_endloop
	base_note $24
	volume 12
	instrument 14
	gate 170
	pan PAN_LR
	note -5, 2
	note -2, 2
	note 3, 2
	note 7, 3
	note 3, 2
	note 2, 2
	note 1, 2
	note 0, 2
	note 3, 2
	note 8, 2
	note 12, 4
	note 9, 3
	snd_loop 2
	rest 2
	note 10, 1
	note 10, 1
	note 10, 3
	snd_endloop
	rest 2
	snd_loop 3
	note 10, 1
	note 10, 1
	note 10, 2
	snd_endloop
	note -2, 0
	note 0, 0
	note 2, 0
	snd_ret
Song04_CH2:
	length_set 4
	volume 11
	pan PAN_LR
	base_note $1B
Seq_4A6D:
	snd_call Sub_4A9E
	snd_call Sub_4AB2
	snd_call Sub_4AB7
	snd_call Sub_4AB2
	snd_call Sub_4AB9
	snd_call Sub_4ABB
	snd_call Sub_4AC3
	snd_call Sub_4A9E
	snd_call Sub_4AB2
	snd_call Sub_4AB7
	snd_call Sub_4AB2
	snd_call Sub_4AB9
	snd_call Sub_4ABB
	snd_call Sub_4ACA
	snd_call Sub_4ACC
	snd_jump Seq_4A6D
	snd_end  ; unreferenced (stream)
Sub_4A9E:
	instrument 14
	gate 170
	note 4, 3
	note 5, 3
	note 4, 4
	note 7, 1
	note 5, 1
	note 4, 2
	note 4, 1
	note 5, 1
	note 4, 2
	note 2, 2
	note 0, 2
	note 2, 2
	note 4, 2
	note 2, 1
	note 0, 1
	snd_ret
Sub_4AB2:
	note -1, 2
	note -1, 1
	note 0, 1
	note -1, 2
	snd_ret
Sub_4AB7:
	note 2, 2
	snd_ret
Sub_4AB9:
	note 7, 2
	snd_ret
Sub_4ABB:
	note -6, 2
	note -3, 1
	note 2, 1
	note 6, 1
	note 4, 1
	note 2, 1
	note 0, 1
	snd_ret
Sub_4AC3:
	note -1, 2
	note 2, 2
	note -1, 2
	rest 0
	note 6, 0
	note 5, 0
	snd_ret
Sub_4ACA:
	note -1, 5
	snd_ret
Sub_4ACC:
	instrument 15
	volume 7
	gate 0
	note 0, 5
	note 2, 3
	note 3, 3
	note 4, 2
	instrument 10
	pan PAN_R
	volume_add 4
	base_note $33
	note 4, 1
	note 5, 1
	snd_loop 3
	note 4, 0
	note 5, 0
	snd_endloop
	snd_loop 4
	note 4, 2
	volume_add -2
	snd_endloop
	instrument 15
	volume 7
	pan PAN_LR
	base_note $1B
	note -1, 5
	note 0, 3
	note 1, 3
	note 2, 2
	pan PAN_R
	instrument 10
	volume_add 4
	base_note $33
	note 2, 1
	note 4, 1
	snd_loop 3
	note 2, 0
	note 4, 0
	snd_endloop
	snd_loop 4
	note 2, 2
	volume_add -2
	snd_endloop
	instrument 14
	gate 170
	volume 11
	pan PAN_LR
	base_note $1B
	note 0, 2
	note 4, 2
	note 4, 2
	note 7, 3
	note 4, 2
	note 7, 2
	note 4, 2
	note 5, 2
	note 9, 2
	note 9, 2
	note 12, 4
	note 9, 3
	snd_loop 2
	rest 2
	note 7, 1
	note 7, 1
	note 7, 3
	snd_endloop
	rest 2
	snd_loop 3
	note 7, 1
	note 7, 1
	note 7, 2
	snd_endloop
	rest 2
	snd_ret
Song04_CH3:
	length_set 4
	instrument 2
	base_note $1B
	pan PAN_LR
	gate 150
	volume 15
Seq_4B3E:
	snd_loop 2
	snd_call Sub_4B62
	snd_call Sub_4B67
	snd_call Sub_4B6C
	snd_call Sub_4B71
	snd_endloop
	snd_loop 2
	snd_call Sub_4B67
	snd_endloop
	snd_loop 2
	snd_call Sub_4B6C
	snd_endloop
	snd_call Sub_4B67
	snd_call Sub_4B76
	snd_jump Seq_4B3E
Sub_4B62:
	note 0, 3
	note 0, 3
	note 0, 3
	rest 3
	snd_ret
Sub_4B67:
	note 0, 3
	note -5, 3
	note 0, 3
	note -5, 3
	snd_ret
Sub_4B6C:
	note -1, 3
	note -5, 3
	note -1, 3
	note -5, 3
	snd_ret
Sub_4B71:
	note 2, 3
	note -10, 3
	note -5, 3
	note -5, 3
	snd_ret
Sub_4B76:
	note -3, 3
	note -7, 3
	note -6, 3
	note -10, 3
	note -5, 5
	note -5, 5
	snd_loop 4
	note -5, 3
	snd_endloop
	snd_ret
Song04_CH4:
	length_set 4
	gate 0
	pan PAN_LR
	volume 12
Seq_4B89:
	snd_loop 2
	snd_call Sub_4BA4
	snd_loop 11
	snd_call Sub_4BAB
	snd_endloop
	snd_call Sub_4BB2
	snd_endloop
	snd_loop 24
	snd_call Sub_4BAB
	snd_endloop
	snd_call Sub_4BBA
	snd_jump Seq_4B89
Sub_4BA4:
	instrument 29
	drum 4, 3
	drum 4, 3
	drum 4, 3
	drest 3
	snd_ret
Sub_4BAB:
	instrument 28
	drum 9, 2
	instrument 29
	drum 3, 2
	snd_ret
Sub_4BB2:
	instrument 28
	drum 9, 2
	instrument 29
	drum 3, 1
	drum 3, 1
	snd_ret
Sub_4BBA:
	instrument 29
	drum 3, 5
	drum 3, 5
	drum 3, 3
	drum 3, 3
	instrument 28
	drum 9, 2
	instrument 29
	drum 3, 1
	drum 3, 1
	drum 4, 2
	drum 4, 2
	snd_ret
Song05_CH1:
	length_set 5
	base_note $27
	volume 12
	instrument 17
	gate 0
Seq_4BD4:
	pan PAN_LR
	snd_call Sub_4BE3
	snd_call Sub_4BE9
	snd_call Sub_4BE3
	snd_call Sub_4BEC
	snd_end
Sub_4BE3:
	note -12, 1
	note -12, 1
	note -9, 3
	note -7, 1
	note -7, 1
	snd_ret
Sub_4BE9:
	note -6, 0
	note -5, 2
	snd_ret
Sub_4BEC:
	note -14, 0
	note -14, 1
	note -13, 1
	note -12, 0
	note -12, 0
	rest 0
	note -12, 0
	snd_ret
Song05_CH2:
	length_set 5
	base_note $27
	gate 0
	instrument 17
	volume 9
	rest_x 8
	snd_jump Seq_4BD4
Song05_CH3:
	length_set 5
	instrument 2
	gate 180
	volume 15
	base_note $1B
	snd_jump Seq_4BD4
Song05_CH4:
	length_set 5
	pan PAN_LR
	volume 12
	gate 0
	snd_loop 3
	snd_call Sub_4C22
	snd_endloop
	snd_call Sub_4C31
	snd_end
Sub_4C22:
	instrument 28
	drum 9, 0
	instrument 5
	drum 3, 0
	drum 5, 1
	instrument 29
	drum 3, 0
	instrument 5
	drum 3, 0
	drum 5, 1
	snd_ret
Sub_4C31:
	gate 180
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 0
	drum 3, 1
	drum 3, 0
	instrument 28
	drum 9, 0
	snd_loop 4
	instrument 29
	drum 3, 0
	snd_endloop
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 0
	snd_ret
Song06_CH1:
	length_set 5
	pan PAN_LR
	volume 9
	instrument 12
	base_note $27
	gate 0
	rest 2
	note_x -5, 10
	note -6, 4
	note -7, 4
	note -8, 2
	snd_loop 10
	detune -9
	hold 1
	snd_endloop
	note_x -3, 18
	note -5, 3
	note -6, 0
	note -5, 3
	note 0, 0
	snd_loop 8
	detune -6
	hold 1
	snd_endloop
	note_x 4, 40
	snd_loop 10
	detune -3
	hold 1
	snd_endloop
	note_x 7, 90
	snd_end
Song06_CH2:
	length_set 5
	instrument 12
	volume 9
	pan PAN_LR
	gate 0
	base_note $27
	rest 2
	note_x -8, 10
	note -9, 4
	note -10, 4
	note -12, 2
	snd_loop 10
	detune -5
	hold 1
	snd_endloop
	note_x -9, 18
	note -8, 3
	note -9, 0
	note -8, 3
	note -6, 0
	snd_loop 8
	detune -9
	hold 1
	snd_endloop
	note_x 0, 40
	snd_loop 10
	detune -3
	hold 1
	snd_endloop
	note_x 4, 90
	snd_end
Song06_CH3:
	length_set 5
	instrument 2
	gate 0
	pan PAN_LR
	base_note $1B
	volume 15
	note 0, 5
	note -5, 5
	note 0, 5
	note 0, 3
	note_x -5, 3
	note_x -1, 4
	note -3, 3
	note -1, 0
	note_x 0, 80
	snd_end
Song06_CH4:
	length_set 5
	pan PAN_LR
	volume 12
	gate 0
	snd_loop 2
	snd_call Sub_4CE3
	snd_call Sub_4CE8
	snd_call Sub_4CF1
	snd_call Sub_4CE8
	snd_endloop
	snd_call Sub_4CF6
	snd_end
Sub_4CE3:
	instrument 28
	drum_x 9, 10
	snd_ret
Sub_4CE8:
	instrument 5
	drum 5, 4
	drum 5, 4
	drum_x 5, 10
	drum 5, 4
	drum 5, 4
	snd_ret
Sub_4CF1:
	instrument 29
	drum_x 3, 10
	snd_ret
Sub_4CF6:
	instrument 29
	drum 3, 4
	snd_ret
	snd_end  ; unreferenced (stream)
Song07_CH1:
	length_set 5
	instrument 19
	base_note $33
	volume 12
	pan PAN_LR
	gate 0
Seq_4D07:
	snd_call Sub_4D17
	snd_call Sub_4D1C
	snd_call Sub_4D17
	snd_call Sub_4D23
	snd_call Sub_4D2A
	snd_end
Sub_4D17:
	note 12, 1
	note 10, 1
	note 7, 1
	note 5, 1
	snd_ret
Sub_4D1C:
	note 3, 0
	note 5, 0
	note 3, 0
	note -2, 0
	note 0, 1
	rest 1
	snd_ret
Sub_4D23:
	note 3, 0
	note 5, 0
	note 7, 0
	note 10, 0
	note 12, 1
	rest 1
	snd_ret
Sub_4D2A:
	note 12, 1
	note 5, 0
	note 7, 0
	note 10, 0
	note 7, 0
	note 10, 0
	note 15, 0
	note 12, 1
	rest 1
	snd_ret
Song07_CH2:
	length_set 5
	volume 12
	instrument 19
	gate 0
	pan PAN_LR
	base_note $33
	snd_call Sub_4D50
	snd_call Sub_4D55
	snd_call Sub_4D50
	snd_call Sub_4D5C
	snd_call Sub_4D63
	snd_end
Sub_4D50:
	note 7, 1
	note 5, 1
	note 3, 1
	note 0, 1
	snd_ret
Sub_4D55:
	note -2, 0
	note 0, 0
	note -2, 0
	note -7, 0
	note -5, 1
	rest 1
	snd_ret
Sub_4D5C:
	note -2, 0
	note 0, 0
	note 2, 0
	note 5, 0
	note 7, 1
	rest 1
	snd_ret
Sub_4D63:
	note 7, 1
	note 0, 0
	note 3, 0
	note 5, 0
	note 3, 0
	note 5, 0
	note 7, 0
	note 7, 1
	rest 1
	snd_ret
Song07_CH3:
	length_set 5
	pan PAN_LR
	instrument 2
	gate 220
	base_note $0F
	volume 15
	snd_jump Seq_4D07
Song07_CH4:
	length_set 5
	pan PAN_LR
	gate 0
	volume 12
	snd_loop 5
	snd_call Sub_4D97
	snd_call Sub_4D9B
	snd_call Sub_4DA0
	snd_call Sub_4D9B
	snd_endloop
	snd_call Sub_4D9B
	snd_end
Sub_4D97:
	instrument 28
	drum 9, 0
	snd_ret
Sub_4D9B:
	instrument 5
	drum 5, 0
	drum 5, 1
	snd_ret
Sub_4DA0:
	instrument 29
	drum 3, 0
	snd_ret
Song08_CH1:
	length_set 5
	volume 12
	gate 0
	base_note $27
	pan PAN_LR
	instrument 20
	note_x 0, 3
	note_x 1, 3
	note_x 0, 8
	note -1, 1
	note -4, 1
	note -5, 1
	note -7, 1
	note -8, 1
	note -11, 1
	note -13, 1
	note -12, 1
	rest 2
	note 0, 0
	note 0, 0
	note 0, 1
	rest 2
	note_x 0, 5
	note_x 2, 5
	note_x 4, 4
	note 5, 1
	rest 2
	note 0, 1
	note -7, 1
	snd_end
Song08_CH2:
	length_set 5
	instrument 20
	gate 0
	pan PAN_LR
	base_note $1B
	volume 10
	rest_x 2
	note_x 0, 3
	note_x 1, 3
	note_x 0, 8
	note -1, 1
	note -4, 1
	note -5, 1
	note -7, 1
	note -8, 1
	note -11, 1
	note_x -13, 12
	note -12, 1
	rest 2
	volume 13
	note 4, 0
	note 4, 0
	note 4, 1
	rest 2
	note_x 4, 5
	note_x 5, 5
	note_x 7, 4
	note 8, 1
	rest 2
	note 7, 1
	note_x 8, 2
	snd_end
Song08_CH3:
	length_set 5
	volume 15
	instrument 2
	pan PAN_LR
	base_note $1B
	gate 0
	note_x 0, 112
	gate 190
	note 0, 1
	rest 2
	note 0, 1
	note 0, 1
	rest 2
	rest 1
	note 5, 1
	rest 2
	note 0, 1
	note -7, 1
	snd_end
Song08_CH4:
	length_set 5
	gate 0
	volume 12
	pan PAN_LR
	snd_loop 5
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	drum 2, 1
	snd_endloop
	instrument 28
	drum 9, 1
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 2
	drum 3, 0
	drest 0
	drum 3, 0
	drum 3, 0
	drum 3, 1
	drest 2
	drum 3, 1
	drum 3, 1
	snd_end
Song09_CH1:
	length_set 5
	instrument 18
	pan PAN_LR
	gate 0
	volume 12
	base_note $27
	note_x -12, 42
	note -12, 1
	note_x -9, 56
	note_x -10, 42
	note -4, 1
	note -5, 1
	note 0, 1
	note -1, 1
	note 0, 1
	note_x 6, 112
	snd_end
Song09_CH2:
	length_set 5
	instrument 18
	volume 12
	gate 0
	base_note $1B
	pan PAN_LR
	note_x -12, 42
	note -12, 1
	note_x -9, 56
	note_x -10, 42
	note -4, 1
	note -5, 1
	note 0, 1
	note -1, 1
	note 0, 1
	note_x 8, 112
	snd_end
Song09_CH3:
	length_set 5
	gate 0
	pan PAN_LR
	base_note $0F
	instrument 2
	volume 15
	note_x 0, 42
	note 0, 1
	note_x 3, 56
	note_x 2, 42
	note 8, 1
	note 7, 1
	note 12, 1
	note 11, 1
	note 12, 1
	snd_loop 4
	note 12, 2
	volume_add -2
	snd_endloop
	snd_end
Song10_CH1:
	length_set 5
	instrument 32
	volume 12
	pan PAN_LR
	gate 180
	base_note $27
	sync $00
	note 0, 1
	rest_x 6
	sync $01
	rest_x 1
	note 0, 1
	rest_x 6
	sync $02
	rest_x 1
	note_x 0, 13
	sync $03
	rest_x 1
	rest_x 13
	sync $04
	rest_x 1
	note_x 3, 13
	sync $05
	rest_x 1
	note_x 3, 6
	sync $06
	rest_x 1
	note 3, 1
	rest_x 6
	sync $07
	rest_x 1
	note 5, 1
	rest_x 6
	sync $08
	rest_x 1
	note 5, 1
	rest_x 6
	sync $09
	rest_x 1
	note_x 5, 13
	sync $0A
	rest_x 1
	rest_x 13
	sync $0B
	rest_x 1
	note_x -2, 13
	sync $0C
	rest_x 1
	note_x -2, 6
	sync $0D
	rest_x 1
	note -2, 3
	sync $0E
	snd_end
Song11_CH1:
	length_set 6
	instrument 12
	gate 0
	base_note $1E
	pan PAN_LR
	volume 10
	sync $00
	rest_x 15
	sync $01
	rest_x 1
	rest_x 15
	sync $02
	rest_x 1
	note_x -1, 31
	sync $03
	rest_x 1
	note_x 0, 15
	sync $04
	rest_x 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x 1, 25
	sync $05
	rest_x 1
	note_x 2, 15
	sync $06
	rest_x 1
	note_x 7, 31
	sync $07
	rest_x 1
	note_x 7, 63
	sync $08
	rest_x 1
	note_x 4, 31
	sync $09
	rest_x 1
	note_x 5, 15
	sync $0A
	rest_x 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x 6, 25
	sync $0B
	rest_x 1
	note_x 7, 15
	sync $0C
	rest_x 1
	note_x 14, 31
	sync $0D
	rest_x 1
	note 12, 2
	sync $0E
	snd_end
Song12_CH1:
	length_set 5
	instrument 19
	volume 14
	pan PAN_LR
	gate 0
	pan PAN_LR
	base_note $33
	sync $00
	note_x 7, 13
	sync $01
	rest_x 1
	note_x 4, 13
	sync $02
	rest_x 1
	note_x 2, 13
	sync $03
	rest_x 1
	note_x -1, 13
	sync $04
	rest_x 1
	note_x 4, 13
	sync $05
	rest_x 1
	note_x 2, 13
	sync $06
	rest_x 1
	note_x -1, 13
	sync $07
	rest_x 1
	note_x -3, 13
	sync $08
	rest_x 1
	note_x -1, 13
	sync $09
	rest_x 1
	note_x -3, 13
	sync $0A
	rest_x 1
	note_x -5, 13
	sync $0B
	rest_x 1
	note_x -8, 13
	sync $0C
	rest_x 1
	note -10, 1
	note_x -13, 13
	sync $0D
	rest_x 1
	note -8, 1
	sync $0E
	snd_end
Song13_CH1:
	length_set 5
	pan PAN_LR
	volume 13
	instrument 13
	base_note $27
	gate 0
	sync $00
	note_x 6, 27
	sync $01
	rest_x 1
	rest_x 13
	sync $02
	rest_x 1
	note_x 6, 5
	note_x 6, 4
	note_x 6, 4
	sync $03
	rest_x 1
	note_x 6, 13
	sync $04
	rest_x 1
	note_x 6, 13
	sync $05
	rest_x 1
	note_x 6, 13
	sync $06
	rest_x 1
	note_x 7, 13
	sync $07
	rest_x 1
	note_x 7, 27
	sync $08
	rest_x 1
	rest_x 13
	sync $09
	rest_x 1
	note_x 7, 5
	note_x 7, 4
	note_x 7, 4
	sync $0A
	rest_x 1
	note_x 7, 13
	sync $0B
	rest_x 1
	note_x 7, 13
	sync $0C
	rest_x 1
	note_x 9, 13
	sync $0D
	rest_x 1
	note_x 7, 13
	sync $0E
	snd_end
Song14_CH1:
	length_set 3
	instrument 14
	base_note $27
	gate 0
	pan PAN_LR
	volume 13
	sync $00
	rest_x 15
	sync $01
	rest_x 1
	rest_x 15
	sync $02
	rest_x 1
	note 6, 2
	rest_x 15
	sync $03
	rest_x 1
	note_x 5, 15
	sync $04
	rest_x 1
	note 6, 2
	rest_x 15
	sync $05
	rest_x 1
	note_x 2, 15
	sync $06
	rest_x 1
	note_x 4, 47
	sync $07
	rest_x 1
	note_x -1, 47
	sync $08
	rest_x 1
	note 4, 2
	rest_x 15
	sync $09
	rest_x 1
	note_x 3, 15
	sync $0A
	rest_x 1
	note 4, 2
	rest_x 15
	sync $0B
	rest_x 1
	note_x 1, 15
	sync $0C
	rest_x 1
	note_x 2, 47
	sync $0D
	rest_x 1
	note_x -3, 48
	sync $0E
	snd_end
Song15_CH1:
	length_set 5
	instrument 32
	volume 12
	pan PAN_LR
	gate 180
	base_note $27
	snd_call Sub_50C2
	snd_call Sub_50CC
	snd_call Sub_50C2
	snd_call Sub_50D6
Seq_50AD:
	snd_loop 4
	snd_call Sub_50E0
	snd_endloop
	snd_call Sub_50C2
	snd_call Sub_50CC
	snd_call Sub_50C2
	snd_call Sub_50D6
	snd_jump Seq_50AD
Sub_50C2:
	note 0, 1
	rest 0
	note 0, 1
	rest 0
	note 0, 1
	rest 1
	note 3, 1
	note 3, 0
	note 3, 3
	snd_ret
Sub_50CC:
	note 5, 1
	rest 0
	note 5, 1
	rest 0
	note 5, 1
	rest 1
	note -2, 1
	note -2, 0
	note -2, 3
	snd_ret
Sub_50D6:
	note 5, 1
	rest 0
	note 5, 1
	rest 0
	note 5, 1
	rest 1
	note 5, 1
	note 5, 0
	note 5, 3
	snd_ret
Sub_50E0:
	note -7, 0
	rest 0
	note -7, 1
	rest 0
	note -7, 1
	note -4, 0
	note -2, 1
	note -4, 0
	note -2, 1
	note -4, 0
	note -2, 1
	snd_ret
Song15_CH2:
	length_set 5
	pan PAN_LR
	volume 11
	base_note $27
	snd_call Sub_5113
	snd_call Sub_5121
	snd_call Sub_5113
	snd_call Sub_512B
Seq_5100:
	snd_call Sub_5135
	pan PAN_R
	snd_call Sub_5137
	snd_call Sub_5135
	pan PAN_L
	snd_call Sub_5137
	snd_jump Seq_5100
Sub_5113:
	instrument 32
	gate 180
	note -7, 1
	rest 0
	note -7, 1
	rest 0
	note -7, 1
	rest 1
	note -4, 1
	note -4, 0
	note -4, 3
	snd_ret
Sub_5121:
	note -2, 1
	rest 0
	note -2, 1
	rest 0
	note -2, 1
	rest 1
	note -9, 1
	note -9, 0
	note -9, 3
	snd_ret
Sub_512B:
	note -2, 1
	rest 0
	note -2, 1
	rest 0
	note -2, 1
	rest 1
	note -2, 1
	note -2, 0
	note -2, 3
	snd_ret
Sub_5135:
	rest 1
	snd_ret
Sub_5137:
	instrument 2
	gate 100
	volume 15
	note -7, 0
	note 5, 0
	rest 0
	note 5, 0
	rest 0
	note -7, 0
	note 5, 0
	note -7, 0
	rest 0
	note 5, 0
	rest 0
	note -7, 0
	note 5, 0
	note 5, 0
	snd_ret
Song15_CH3:
	length_set 5
	instrument 2
	volume 15
	gate 0
	base_note $1B
	pan PAN_LR
	snd_call Sub_516C
Seq_515B:
	snd_loop 4
	snd_call Sub_5172
	snd_endloop
	snd_loop 2
	snd_call Sub_5181
	snd_endloop
	snd_jump Seq_515B
	instrument 10, STATIC  ; unreferenced (stream)
Sub_516C:
	snd_loop 4
	note_x -7, 112
	snd_endloop
	snd_ret
Sub_5172:
	gate 180
	instrument 10
	note -7, 1
	note -7, 1
	rest 0
	note -7, 1
	note -4, 0
	note -2, 1
	note -4, 0
	note -2, 1
	note -4, 0
	note -2, 1
	snd_ret
Sub_5181:
	gate 0
	note_x -7, 84
	note -4, 2
	note_x -2, 112
	snd_ret
Song15_CH4:
	length_set 5
	gate 0
	volume 12
	pan PAN_LR
Seq_5191:
	snd_call Sub_519D
	snd_loop 4
	snd_call Sub_51B3
	snd_endloop
	snd_jump Seq_5191
Sub_519D:
	snd_loop 12
	instrument 28
	drum 9, 2
	snd_endloop
	snd_loop 2
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 1
	snd_endloop
	drum 3, 1
	drest 0
	drum 3, 0
	drest 0
	drum 3, 0
	drum 3, 0
	drum 3, 0
	snd_ret
Sub_51B3:
	instrument 28
	drum 9, 1
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 29
	drum 3, 1
	drest 0
	drum 3, 0
	snd_ret
Song16_CH1:
	length_set 7
	instrument 12
	gate 0
	base_note $1E
	pan PAN_LR
	volume 10
Seq_51E0:
	snd_call Sub_51F2
	snd_call Sub_525E
	snd_call Sub_5272
	snd_call Sub_525E
	snd_call Sub_5286
	snd_jump Seq_51E0
Sub_51F2:
	note -1, 1
	note 0, 0
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x 1, 20
	note 2, 0
	note 7, 1
	note 7, 2
	note 4, 1
	note 5, 0
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x 6, 20
	note 7, 0
	note 14, 1
	note 12, 0
	note 7, 1
	snd_loop 3
	detune -12
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 11, 2
	note_x 11, 125
	rest_x 1
	instrument 12
	note 7, 0
	note 9, 0
	note 7, 0
	note 6, 0
	note 7, 0
	note 6, 0
	note 5, 0
	note 7, 0
	note 5, 0
	note 2, 0
	note 5, 0
	note 2, 0
	note -1, 0
	note -3, 0
	note -5, 0
	note 4, 1
	note 4, 0
	note 7, 1
	note 4, 2
	rest 0
	note 9, 0
	note 7, 0
	note 9, 1
	note 7, 0
	note 9, 1
	note 7, 2
	note 3, 1
	note_x 0, 1
	snd_loop 4
	detune -9
	hold 3
	snd_endloop
	instrument 12, STATIC
	note_x 2, 1
	note_x 2, 125
	rest_x 1
	instrument 12
	note -5, 0
	note -1, 0
	note 2, 0
	note 7, 0
	note 9, 0
	note 7, 0
	note 6, 0
	note 7, 0
	note 6, 0
	note 5, 0
	note 2, 0
	note -1, 0
	note -3, 0
	note -4, 0
	note -5, 0
	snd_ret
Sub_525E:
	instrument 12
	note 2, 3
	note 6, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 9, 6
	note_x 9, 83
	rest_x 1
	snd_ret
Sub_5272:
	instrument 12
	note 0, 3
	note 4, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 7, 6
	note_x 7, 83
	rest_x 1
	snd_ret
Sub_5286:
	instrument 12
	note 0, 3
	note 3, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 7, 6
	note_x 7, 55
	rest_x 1
	instrument 10
	note -3, 0
	note -2, 0
	snd_ret
Song16_CH2:
	length_set 7
	instrument 12
	volume 9
	gate 0
	pan PAN_LR
	base_note $1E
Seq_52AA:
	snd_call Sub_52BC
	snd_call Sub_533C
	snd_call Sub_5354
	snd_call Sub_533C
	snd_call Sub_536C
	snd_jump Seq_52AA
Sub_52BC:
	note -5, 1
	note -3, 0
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x -2, 20
	note -1, 0
	note 2, 1
	note 2, 2
	note 0, 1
	note 2, 0
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	note_x 3, 20
	note 4, 0
	note 7, 1
	note 4, 0
	note 4, 1
	snd_loop 3
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 7, 2
	note_x 7, 125
	rest_x 1
	instrument 12
	volume 8
	rest_x 10
	pan PAN_L
	note 7, 0
	note 9, 0
	note 7, 0
	note 6, 0
	note 7, 0
	note 6, 0
	note 5, 0
	note 7, 0
	note 5, 0
	note 2, 0
	note 5, 0
	note 2, 0
	note -1, 0
	note -3, 0
	note_x -5, 4
	volume 9
	pan PAN_LR
	note 0, 1
	note 0, 0
	note 4, 1
	note 0, 2
	rest 0
	note 4, 0
	note 4, 0
	note 3, 1
	note 3, 0
	note 3, 1
	note 3, 2
	note 0, 1
	note_x -2, 1
	snd_loop 4
	detune -9
	hold 3
	snd_endloop
	instrument 12, STATIC
	note_x -1, 1
	note_x -1, 125
	rest_x 1
	instrument 12
	volume 8
	rest_x 10
	pan PAN_R
	note -5, 0
	note -1, 0
	note 2, 0
	note 7, 0
	note 9, 0
	note 7, 0
	note 6, 0
	note 7, 0
	note 6, 0
	note 5, 0
	note 2, 0
	note -1, 0
	note -3, 0
	note -4, 0
	note_x -5, 4
	pan PAN_LR
	snd_ret
Sub_533C:
	instrument 12
	volume 9
	pan PAN_R
	note -3, 3
	note 2, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 6, 6
	note_x 6, 83
	rest_x 1
	snd_ret
Sub_5354:
	instrument 12
	volume 10
	pan PAN_L
	note -5, 3
	note 0, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 4, 6
	note_x 4, 83
	rest_x 1
	snd_ret
Sub_536C:
	instrument 12
	pan PAN_L
	note -5, 3
	note 0, 1
	snd_loop 2
	detune -9
	hold 4
	snd_endloop
	instrument 12, STATIC
	note_x 3, 6
	note_x 3, 55
	rest_x 1
	instrument 12
	pan PAN_LR
	note -7, 0
	note -6, 0
	snd_ret
Song16_CH3:
	length_set 7
	instrument 2
	gate 170
	volume 15
	base_note $1E
	pan PAN_LR
Seq_5394:
	snd_call Sub_53C7
	snd_call Sub_53CA
	snd_loop 2
	snd_call Sub_53CD
	snd_endloop
	snd_loop 2
	snd_call Sub_53C7
	snd_endloop
	snd_call Sub_53D0
	snd_loop 4
	snd_call Sub_53CD
	snd_endloop
	snd_loop 4
	snd_call Sub_53C7
	snd_endloop
	snd_loop 2
	snd_loop 2
	snd_call Sub_53D5
	snd_endloop
	snd_loop 2
	snd_call Sub_53CD
	snd_endloop
	snd_endloop
	snd_jump Seq_5394
Sub_53C7:
	note -5, 3
	note 7, 3
	snd_ret
Sub_53CA:
	note -1, 3
	note 11, 3
	snd_ret
Sub_53CD:
	note 0, 3
	note 12, 3
	snd_ret
Sub_53D0:
	note -5, 3
	note -5, 3
	note -3, 3
	note -1, 3
	snd_ret
Sub_53D5:
	note 2, 3
	note 14, 3
	snd_ret
Song16_CH4:
	length_set 7
	gate 0
	volume 12
	pan PAN_LR
Seq_53E0:
	snd_call Sub_53E6
	snd_jump Seq_53E0
Sub_53E6:
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	snd_ret
	snd_end  ; unreferenced (stream)
Song17_CH1:
	length_set 5
	instrument 19
	volume 12
	gate 0
	pan PAN_LR
	base_note $33
	snd_loop 2
	snd_call Sub_5421
	snd_endloop
Seq_5408:
	snd_call Sub_5441
	snd_loop 2
	snd_call Sub_5446
	snd_endloop
	snd_call Sub_545B
	snd_call Sub_5463
	snd_call Sub_545B
	snd_call Sub_546F
	snd_jump Seq_5408
	snd_end  ; unreferenced (stream)
Sub_5421:
	note 7, 1
	note 4, 1
	note_x 2, 5
	note_x 4, 5
	note_x 2, 4
	note -1, 1
	note 4, 1
	note 2, 1
	note_x -1, 5
	note_x 2, 5
	note_x -1, 4
	note -3, 1
	note -1, 1
	note -3, 1
	note_x -5, 5
	note_x -3, 5
	note_x -5, 4
	note -8, 1
	note -10, 1
	note -13, 1
	note -8, 1
	rest 1
	snd_ret
Sub_5441:
	rest_x 84
	rest_x 112
	snd_ret
Sub_5446:
	note -1, 1
	rest 1
	note -1, 3
	note -3, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note -3, 0
	note -1, 1
	note -3, 1
	note -5, 0
	note -3, 0
	note -5, 0
	note -8, 0
	note -5, 1
	note -8, 1
	note -10, 1
	note -13, 1
	note -8, 1
	rest 1
	snd_ret
Sub_545B:
	note -15, 1
	note -13, 1
	note -10, 1
	note -8, 1
	note -3, 1
	note -5, 1
	note -8, 1
	snd_ret
Sub_5463:
	note -10, 1
	note -5, 1
	note -8, 1
	note -10, 1
	note -13, 1
	note -15, 0
	note -13, 0
	note -10, 0
	note -13, 0
	note -8, 1
	rest 1
	snd_ret
Sub_546F:
	note -5, 1
	note 7, 1
	note 4, 1
	note 2, 1
	note -1, 1
	note -3, 1
	note -5, 1
	note -8, 1
	note -10, 1
	note -8, 1
	rest 1
	snd_ret
Song17_CH2:
	length_set 5
	pan PAN_LR
	instrument 19
	volume 12
	gate 0
	snd_call Sub_54A6
	snd_call Sub_54CB
	snd_call Sub_54A6
Seq_548E:
	snd_loop 6
	snd_call Sub_54CD
	snd_endloop
	snd_call Sub_54DB
	snd_call Sub_54E4
	snd_call Sub_54CD
	snd_call Sub_54DB
	snd_call Sub_54E6
	snd_jump Seq_548E
Sub_54A6:
	base_note $33
	note 4, 1
	base_note $27
	note 11, 1
	note_x 9, 5
	note_x 11, 5
	note_x 9, 4
	note 7, 1
	note 11, 1
	note 9, 1
	note_x 7, 5
	note_x 9, 5
	note_x 7, 4
	note 4, 1
	note 7, 1
	note 4, 1
	note_x 2, 5
	note_x 4, 5
	note_x 2, 4
	note -1, 1
	note -3, 1
	base_note $1B
	note 9, 1
	note 11, 1
	snd_ret
Sub_54CB:
	rest 1
	snd_ret
Sub_54CD:
	gate 200
	base_note $1B
	note -8, 1
	rest 1
	note -8, 1
	rest 1
	note -8, 0
	note -8, 0
	rest 1
	note -8, 1
	rest 1
	snd_ret
Sub_54DB:
	note -5, 1
	rest 1
	note -5, 1
	rest 1
	note -5, 0
	note -5, 0
	rest 1
	note -5, 1
	snd_ret
Sub_54E4:
	rest 1
	snd_ret
Sub_54E6:
	base_note $33
	note 4, 1
	note -1, 1
	note -3, 1
	note -5, 1
	note -8, 1
	note -10, 1
	note -13, 1
	note -15, 1
	note -13, 1
	snd_ret
Song17_CH3:
	length_set 5
	instrument 2
	base_note $1B
	gate 200
	pan PAN_LR
	volume 15
	snd_call Sub_551F
Seq_5501:
	snd_loop 24
	snd_call Sub_5527
	snd_endloop
	snd_loop 4
	snd_call Sub_552A
	snd_endloop
	snd_loop 4
	snd_call Sub_5527
	snd_endloop
	snd_loop 4
	snd_call Sub_552A
	snd_endloop
	snd_call Sub_552D
	snd_jump Seq_5501
Sub_551F:
	snd_loop 3
	rest_x 112
	snd_endloop
	rest_x 84
	snd_ret
Sub_5527:
	note -8, 1
	note -1, 1
	snd_ret
Sub_552A:
	note -5, 1
	note 2, 1
	snd_ret
Sub_552D:
	note -1, 5
	note -13, 5
	snd_ret
Song18_CH1:
	length_set 5
	instrument 13
	gate 0
	base_note $27
	pan PAN_LR
	volume 12
	snd_loop 2
	snd_call Sub_5555
	snd_endloop
	snd_call Sub_556E
Seq_5545:
	snd_call Sub_5589
	snd_call Sub_55A6
	snd_call Sub_5587
	snd_call Sub_55BA
	snd_jump Seq_5545
	snd_end  ; unreferenced (stream)
Sub_5555:
	note 6, 2
	rest 1
	note_x 6, 5
	note_x 6, 5
	note_x 6, 4
	note 6, 1
	note 6, 1
	note 6, 1
	note 7, 1
	note 7, 2
	rest 1
	note_x 7, 5
	note_x 7, 5
	note_x 7, 4
	note 7, 1
	note 7, 1
	note 9, 1
	note 7, 1
	snd_ret
Sub_556E:
	note 6, 1
	rest 2
	note 2, 0
	note 3, 0
	note 2, 1
	note 0, 1
	note -2, 1
	note 0, 1
	note_x 1, 3
	note_x 2, 11
	rest 1
	note_x -4, 3
	note_x -3, 11
	rest 1
	note_x -11, 3
	note_x -10, 11
	rest 1
	rest 2
	snd_ret
Sub_5587:
	instrument 13
Sub_5589:
	note_x 5, 3
	note_x 6, 3
	note_x 7, 8
	instrument 13, STATIC
	note 2, 1
	snd_loop 4
	note_x 2, 24
	volume_add -1
	snd_endloop
	volume_add 4
	rest_x 16
	instrument 13
	note 0, 1
	note 2, 1
	note 5, 1
	note 3, 1
	note 2, 1
	note 0, 1
	snd_ret
Sub_55A6:
	note_x 2, 3
	note_x 3, 3
	instrument 13, STATIC
	snd_loop 5
	note_x 2, 21
	volume_add -1
	snd_endloop
	instrument 13
	volume_add 5
	rest_x 113
	snd_ret
Sub_55BA:
	note_x 0, 3
	note_x 1, 3
	note_x 2, 8
	instrument 13, STATIC
	note -5, 2
	volume_add -1
	note -5, 5
	volume_add -1
	note_x -5, 111
	rest_x 1
	volume_add 2
	instrument 13
	rest_x 7
	note_x 3, 3
	note_x 4, 4
	snd_ret
Song18_CH2:
	length_set 5
	instrument 13
	volume 12
	gate 0
	pan PAN_LR
	base_note $1B
	snd_loop 2
	snd_call Sub_55FB
	snd_endloop
	snd_call Sub_5614
Seq_55EC:
	snd_call Sub_562D
	snd_call Sub_5638
	snd_call Sub_562D
	snd_call Sub_563F
	snd_jump Seq_55EC
Sub_55FB:
	note 9, 2
	rest 1
	note_x 9, 5
	note_x 9, 5
	note_x 9, 4
	note 9, 1
	note 9, 1
	note 9, 1
	note 10, 1
	note 10, 2
	rest 1
	note_x 10, 5
	note_x 10, 5
	note_x 10, 4
	note 10, 1
	note 10, 1
	note 12, 1
	note 10, 1
	snd_ret
Sub_5614:
	note 9, 1
	rest 2
	note 2, 0
	note 3, 0
	note 2, 1
	note 0, 1
	note -2, 1
	note 0, 1
	note_x 1, 3
	note_x 2, 11
	rest 1
	note_x -4, 3
	note_x -3, 11
	rest 1
	note_x -11, 3
	note_x -10, 11
	rest 1
	rest 2
	snd_ret
Sub_562D:
	instrument 10
	gate 150
	snd_loop 4
	note -10, 1
	note -10, 0
	note -10, 0
	snd_endloop
	snd_ret
Sub_5638:
	snd_loop 4
	note -9, 1
	note -9, 0
	note -9, 0
	snd_endloop
	snd_ret
Sub_563F:
	snd_loop 4
	note -6, 1
	note -6, 0
	note -6, 0
	snd_endloop
	snd_ret
Song18_CH3:
	length_set 5
	instrument 2
	gate 180
	volume 15
	base_note $1B
	pan PAN_LR
	snd_loop 2
	snd_call Sub_5665
	snd_endloop
	snd_call Sub_567E
Seq_565B:
	snd_call Sub_5689
	snd_call Sub_5690
	snd_jump Seq_565B
	snd_end  ; unreferenced (stream)
Sub_5665:
	note -10, 2
	rest 1
	note_x -10, 5
	note_x -10, 5
	note_x -10, 4
	note -10, 1
	note -10, 1
	note -10, 1
	note -9, 1
	note -9, 2
	rest 1
	note_x -9, 5
	note_x -9, 5
	note_x -9, 4
	note -9, 1
	note -9, 1
	note -7, 1
	note -9, 1
	snd_ret
Sub_567E:
	note -10, 2
	rest_x 84
	note 2, 1
	rest 1
	note -3, 1
	rest 1
	note -10, 1
	rest 1
	rest 2
	snd_ret
Sub_5689:
	snd_loop 4
	note -5, 1
	note -5, 0
	note -5, 0
	snd_endloop
	snd_ret
Sub_5690:
	snd_loop 4
	note -4, 1
	note -4, 0
	note -4, 0
	snd_endloop
	snd_ret
Song18_CH4:
	length_set 5
	gate 180
	volume 12
	pan PAN_LR
Seq_569F:
	snd_call Sub_56AB
	snd_call Sub_56B6
	snd_call Sub_56C0
	snd_jump Seq_569F
Sub_56AB:
	snd_loop 2
	instrument 28
	drum 9, 1
	instrument 5
	drum 2, 0
	drum 2, 0
	snd_endloop
	snd_ret
Sub_56B6:
	instrument 5
	snd_loop 4
	drum_x 2, 3
	drum_x 2, 4
	snd_endloop
	snd_ret
Sub_56C0:
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	drum 2, 0
	snd_ret
Song19_CH1:
	length_set 8
	instrument 14
	volume 12
	gate 0
	pan PAN_LR
	base_note $27
Seq_56D5:
	snd_call Sub_56E4
	snd_call Sub_56EE
	snd_call Sub_56E4
	snd_call Sub_56FB
	snd_jump Seq_56D5
Sub_56E4:
	note -3, 2
	note 6, 2
	rest 2
	note 5, 3
	note 6, 0
	note 9, 2
	rest 3
	note 6, 0
	note 2, 2
	snd_ret
Sub_56EE:
	note 4, 4
	note -1, 4
	note 4, 2
	rest 2
	note 3, 3
	note 4, 0
	note 7, 2
	rest 3
	note 4, 0
	note 1, 2
	note 2, 4
	note -3, 5
	snd_ret
Sub_56FB:
	note 4, 2
	rest 3
	note 3, 0
	note 4, 2
	note 7, 2
	rest 3
	note 6, 0
	note 7, 2
	note 6, 2
	rest 3
	note 2, 0
	note -3, 2
	note -1, 2
	rest 3
	note 0, 0
	note 1, 2
	note 2, 2
	note -3, 2
	note -6, 2
	note -10, 5
	snd_ret
Song19_CH2:
	length_set 8
	instrument 14
	volume 10
	gate 200
	pan PAN_LR
Seq_571A:
	snd_call Sub_572F
	snd_call Sub_5733
	snd_call Sub_573B
	snd_loop 2
	snd_call Sub_5733
	snd_endloop
	snd_call Sub_574A
	snd_jump Seq_571A
Sub_572F:
	base_note $27
	note -11, 2
	snd_ret
Sub_5733:
	note -10, 2
	rest_x 36
	note_x 5, 4
	note 6, 2
	rest 5
	snd_ret
Sub_573B:
	note -13, 2
	rest_x 36
	note_x 6, 4
	note 7, 2
	rest 5
	note -11, 2
	rest_x 36
	note_x 3, 4
	note 4, 2
	rest 5
	snd_ret
Sub_574A:
	note -13, 2
	rest_x 36
	note_x 3, 4
	note 4, 2
	rest 5
	base_note $1B
	note -3, 2
	rest 5
	note 9, 2
	note 8, 2
	note 7, 2
	note 6, 2
	note 2, 2
	note -3, 2
	note -6, 5
	snd_ret
	snd_end  ; unreferenced (stream)
Song19_CH3:
	length_set 8
	instrument 2
	volume 15
	pan PAN_LR
	base_note $1B
	gate 150
Seq_576A:
	snd_call Sub_5788
	snd_call Sub_578A
	snd_call Sub_578F
	snd_call Sub_5794
	snd_loop 2
	snd_call Sub_578A
	snd_endloop
	snd_call Sub_578F
	snd_call Sub_5794
	snd_call Sub_5799
	snd_jump Seq_576A
Sub_5788:
	note -3, 2
	snd_ret
Sub_578A:
	note -10, 2
	rest 5
	note 2, 2
	rest 5
	snd_ret
Sub_578F:
	note -5, 2
	rest 5
	note 7, 2
	rest 5
	snd_ret
Sub_5794:
	note -3, 2
	rest 5
	note 9, 2
	rest 5
	snd_ret
Sub_5799:
	note 2, 2
	note -3, 2
	note -6, 2
	note -10, 5
	snd_ret
Song20_CH1:
	length_set 3
	volume 14
Seq_57A2:
	instrument 30
	gate 140
	pan PAN_LR
	base_note $27
Seq_57AA:
	snd_call Sub_57B9
	snd_call Sub_57C0
	snd_call Sub_57B9
	snd_call Sub_57CB
	snd_jump Seq_57AA
Sub_57B9:
	note -1, 2
	note -1, 0
	note 0, 2
	note 0, 0
	note 1, 2
	note 1, 0
	snd_ret
Sub_57C0:
	note 2, 3
	note 4, 2
	note 4, 0
	note 2, 2
	note 2, 0
	note 0, 0
	note -1, 0
	note 0, 0
	note -3, 2
	note 2, 0
	snd_ret
Sub_57CB:
	note 2, 0
	note 7, 0
	note 5, 0
	note 4, 2
	note 4, 0
	note 9, 2
	note 7, 0
	note 6, 0
	note 4, 0
	note 6, 0
	note 7, 3
	snd_ret
Song20_CH2:
	length_set 3
	volume 12
	rest_x 6
	snd_jump Seq_57A2
Song20_CH3:
	length_set 3
	volume 15
	gate 180
	instrument 2
	base_note $1B
	pan PAN_LR
Seq_57EC:
	snd_call Sub_57FB
	snd_call Sub_5807
	snd_call Sub_57FB
	snd_call Sub_580F
	snd_jump Seq_57EC
Sub_57FB:
	note -5, 2
	note -5, 0
	note -3, 2
	note -3, 0
	note -2, 2
	note -2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	note 0, 2
	note 0, 0
	snd_ret
Sub_5807:
	note -1, 2
	note -1, 0
	note -3, 2
	note -3, 0
	note -10, 0
	note -8, 0
	note -6, 0
	snd_ret
Sub_580F:
	note 1, 2
	note 1, 0
	note 2, 2
	note 2, 0
	note -5, 3
	snd_ret
Song20_CH4:
	length_set 3
	pan PAN_LR
	volume 12
	gate 0
Seq_581D:
	snd_call Sub_582C
	snd_call Sub_5832
	snd_call Sub_582C
	snd_call Sub_5839
	snd_jump Seq_581D
Sub_582C:
	instrument 28
	drum 9, 0
	drest 0
	drum 9, 0
	snd_ret
Sub_5832:
	instrument 29
	drum 4, 2
	instrument 28
	drum 9, 0
	snd_ret
Sub_5839:
	instrument 29
	drum 4, 3
	snd_ret
Song21_CH1:
	length_set 3
	gate 0
	base_note $2C
	instrument 14
	pan PAN_LR
	volume 12
	note -3, 2
	note -3, 0
	note -2, 3
	note 0, 2
	note 0, 0
	rest 2
	note 5, 0
	rest 2
	note 2, 0
	note 4, 2
	note 5, 0
	snd_end
Song21_CH2:
	length_set 3
	instrument 14
	gate 0
	pan PAN_LR
	volume 11
	base_note $2C
	note -12, 2
	note -12, 0
	note -7, 3
	note -5, 2
	note -5, 0
	rest 2
	note -3, 0
	rest 2
	note -7, 0
	note -12, 2
	note -3, 0
	snd_end
Song21_CH3:
	length_set 3
	instrument 2
	gate 180
	pan PAN_LR
	base_note $20
	volume 15
	note 5, 2
	note 5, 0
	note 2, 3
	note 4, 2
	note 4, 0
	rest 2
	note 5, 0
	rest 2
	note -2, 0
	note 0, 2
	note 5, 0
	snd_end
Song22_CH1:
	length_set 1
	volume 12
	gate 180
	instrument 32
	base_note $24
	pan PAN_LR
	snd_call Sub_58A0
	snd_call Sub_58A9
	base_note $25
	snd_call Sub_58A0
	snd_call Sub_58AC
	snd_end
Sub_58A0:
	note_x -2, 36
	note -2, 0
	note -2, 0
	note -2, 1
	note -7, 1
	note -2, 1
	note 2, 1
	snd_ret
Sub_58A9:
	note_x 5, 96
	snd_ret
Sub_58AC:
	note_x 5, 36
	note 2, 0
	note 2, 0
	note_x 5, 16
	note_x 2, 20
	note_x 5, 24
	note_x 7, 100
	snd_ret
Song22_CH2:
	length_set 1
	instrument 32
	gate 180
	base_note $18
	pan PAN_LR
	volume 12
	snd_call Sub_58D4
	snd_call Sub_58DD
	base_note $19
	snd_call Sub_58D4
	snd_call Sub_58E0
	snd_end
Sub_58D4:
	note_x 2, 36
	note 2, 0
	note 2, 0
	note 2, 1
	note -2, 1
	note 2, 1
	note 5, 1
	snd_ret
Sub_58DD:
	note_x 10, 96
	snd_ret
Sub_58E0:
	note_x 10, 36
	note 5, 0
	note 5, 0
	note_x 10, 16
	note_x 5, 20
	note_x 10, 24
	note_x 12, 100
	snd_ret
Song22_CH3:
	length_set 1
	instrument 2
	gate 180
	pan PAN_LR
	base_note $24
	volume 15
	snd_call Sub_5908
	snd_call Sub_5911
	base_note $25
	snd_call Sub_5908
	snd_call Sub_5914
	snd_end
Sub_5908:
	note_x -7, 36
	note -7, 0
	note -7, 0
	note -7, 1
	note -10, 1
	note -7, 1
	note -2, 1
	snd_ret
Sub_5911:
	note_x 2, 96
	snd_ret
Sub_5914:
	note_x 2, 36
	note -2, 0
	note -2, 0
	note_x 2, 16
	note_x -2, 20
	note_x 2, 24
	note_x 4, 96
	snd_ret
Env_5921:
	env_timbre 0
	env_vol 15
	env_end
Env_5924:
	env_timbre 1
	env_vol 12
	env_loop 5
	env_vol_add -1
	env_wait 4
	env_vol_add -1
	env_wait 4
	env_endloop
	env_end
Env_592E:
	env_timbre 2
	env_vol 15
	env_end
Env_5931:
	env_timbre 3
	env_vol 15
	env_end
Env_5934:
	env_timbre 1
Env_5935:
	env_vol 12
Env_5936:
	env_vol_add 1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -2
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_pitch 1, WAIT
	env_pitch -1, WAIT
	env_pitch 1, WAIT
	env_pitch -1, WAIT
	env_jump Env_5936
Env_5945:
	env_timbre 2
	env_vol 15
	env_loop 3
	env_vol_add -5
	env_wait 2
	env_endloop
	env_end
Env_594D:
	env_timbre 0
	env_vol 15
	env_vol 13
	env_wait 2
	env_loop 5
	env_vol_add -3
	env_wait 2
	env_endloop
	env_end
Env_5957:
	env_timbre 2
	env_vol 15
	env_loop 5
	env_vol_add -2
	env_wait 2
	env_endloop
	env_end
Env_595F:
	env_timbre 2
Env_5960:
	env_vol 15
	env_loop 7
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_endloop
	env_end
Env_5969:
	env_timbre 2
	env_vol 15
	env_loop 8
	env_vol_add -1
	env_wait 3
	env_vol_add -1
	env_wait 3
	env_endloop
	env_end
Env_5973:
	env_vol 0
	env_end
Env_5975:
	env_vol_add -3, WAIT
	env_vol_add -2, WAIT
	env_vol_add -1, WAIT
	env_end
Env_5979:
	env_vol_add 1
	env_loop 3
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_endloop
	env_end
Env_5987:
	env_timbre 2
	env_vol 12
	env_end
Env_598A:
	env_timbre 0
	env_vol 12
	env_loop 10
	env_vol_add 2
	env_wait 5
	env_vol_add -2
	env_wait 5
	env_endloop
	env_end
Env_5994:
	env_timbre 2
	env_vol 11
	env_vol 9, WAIT
	env_loop 4
	env_vol_add 3, WAIT
	env_loop 4
	env_pitch -1
	env_wait 2
	env_pitch 1
	env_wait 2
	env_vol_add 1
	env_endloop
Env_59A2:
	env_pitch -3
	env_wait 4
	env_pitch 3
	env_wait 4
	env_pitch 3
	env_wait 4
	env_pitch -3
	env_wait 4
	env_vol_add -3
	env_jump Env_59A2
Env_59AE:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 0
	env_vol 10
	env_wait 5
	env_loop 3
	env_vol_add -1, WAIT
	env_endloop
Env_59B7:
	env_vol_add 1
	env_wait 4
	env_vol_add -2
	env_wait 4
	env_jump Env_59B7
Env_59BE:
	env_timbre 2
	env_vol 15, WAIT
	env_timbre 1
	env_loop 7
	env_vol_add -1, WAIT
	env_endloop
Env_59C5:
	env_vol_add 1
	env_wait 4
	env_vol_add -1
	env_wait 4
	env_vol_add 1
	env_wait 4
	env_vol_add -2
	env_wait 4
	env_jump Env_59C5
Env_59D0:
	env_pitch -1
	env_jump Env_598A
Env_59D4:
	env_timbre 2
	env_vol 15
	env_loop 4
	env_vol_add -4, WAIT
	env_endloop
	env_end
Env_59DB:
	env_vol 3
	env_wait 6
	env_vol 0
	env_end
Env_59DF:
	env_timbre 1
	env_vol 12
	env_loop 10
	env_vol_add -2
	env_wait 5
	env_pitch 2
	env_wait 3
	env_vol_add 1
	env_wait 5
	env_pitch -2
	env_wait 3
	env_endloop
	env_end
Env_59ED:
	env_timbre 2
Env_59EE:
	env_vol 14, WAIT
	env_loop 3
	env_vol_add -4
	env_wait 3
	env_endloop
Env_59F4:
	env_vol 5
	env_wait 4
	env_vol 3
	env_wait 4
	env_vol_add -1
	env_jump Env_59F4
	env_vol 1  ; unreferenced (envelope)
	env_wait 2
	env_vol 0
	env_end
	env_timbre 2  ; unreferenced (envelope)
	env_vol 15
	env_wait 12
	env_loop 12
	env_vol_add -1
	env_wait 2
	env_endloop
	env_end
Env_5A09:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_loop 4
	env_vol_add -1, WAIT
	env_endloop
	env_vol 10
	env_loop 4
	env_end
Env_5A14:
	env_timbre 0
	env_vol 12
	env_loop 10
	env_vol_add 3
	env_wait 5
	env_vol_add -3
	env_wait 5
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_endloop
	env_vol 1
	env_end
Env_5A23:
	env_timbre 0
	env_jump Env_5960
Env_5A27:
	env_timbre 1
	env_jump Env_5A2C
Env_5A2B:
	env_timbre 2
Env_5A2C:
	env_vol 12
	env_loop 2
	env_vol_add -1
	env_wait 3
	env_endloop
	env_loop 5
	env_pitch 1
	env_wait 2
	env_pitch -1
	env_wait 2
	env_pitch 1
	env_wait 2
	env_pitch -1
	env_wait 2
	env_endloop
	env_end
Env_5A3E:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_vol 14, WAIT
	env_jump Env_5A3E
	env_end  ; unreferenced (envelope)
Env_5A46:
	env_timbre 2
	env_vol 12
	env_wait 2
	env_timbre 3, WAIT
	env_vol 10
	env_loop 3
	env_vol_add -1, WAIT
	env_endloop
Env_5A4F:
	env_vol_add 1
	env_wait 4
	env_vol_add -1
	env_wait 5
	env_vol_add 1
	env_wait 5
	env_vol_add -1
	env_wait 4
	env_jump Env_5A4F
	env_vol 1  ; unreferenced (envelope)
	env_wait 2
	env_vol 0
	env_end
Env_5A5E:
	env_vol 15, WAIT
	env_loop 3
	env_vol_add -5, WAIT
	env_endloop
	env_end
Env_5A64:
	env_vol 15
	env_loop 5
	env_wait 3
	env_vol_add -3
	env_endloop
	env_end
Env_5A6B:
	env_vol 12
Env_5A6C:
	env_vol_add 1
	env_wait 3
	env_vol_add -1
	env_wait 3
	env_jump Env_5A6C
Env_5A73:
	env_timbre 2
	env_jump Env_5A6B
Env_5A77:
	env_timbre 1
	env_jump Env_5A6B
Env_5A7B:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_timbre 0
	env_vol 12
	env_loop 3
	env_vol_add -3, WAIT
	env_endloop
Env_5A84:
	env_vol 6
	env_wait 3
	env_vol 3
	env_wait 3
	env_jump Env_5A84
Env_5A8B:
	env_timbre 0
	env_jump Env_5935
Env_5A8F:
	env_timbre 3
	env_jump Env_59EE
Song23:
	db 4  ; tracks
	track Song23_CH1, CH1
	track Song23_CH2, CH2
	track Song23_CH3, CH3
	track Song23_CH4, CH4
Song24:
	db 4  ; tracks
	track Song24_CH1, CH1
	track Song24_CH2, CH2
	track Song24_CH3, CH3
	track Song23_CH4, CH4
Song25:
	db 4  ; tracks
	track Song25_CH1, CH1
	track Song25_CH2, CH2
	track Song25_CH3, CH3
	track Song25_CH4, CH4
Song26:
	db 4  ; tracks
	track Song26_CH1, CH1
	track Song26_CH2, CH2
	track Song25_CH3, CH3
	track Song25_CH4, CH4
Song27:
	db 4  ; tracks
	track Song27_CH1, CH1
	track Song27_CH2, CH2
	track Song27_CH3, CH3
	track Song27_CH4, CH4
Song28:
	db 4  ; tracks
	track Song28_CH1, CH1
	track Song28_CH2, CH2
	track Song28_CH3, CH3
	track Song28_CH4, CH4
Song29:
	db 4  ; tracks
	track Song29_CH1, CH1
	track Song29_CH2, CH2
	track Song29_CH3, CH3
	track Song29_CH4, CH4
Song30:
	db 4  ; tracks
	track Song30_CH1, CH1
	track Song30_CH2, CH2
	track Song30_CH3, CH3
	track Song28_CH4, CH4
Song31:
	db 4  ; tracks
	track Song31_CH1, CH1
	track Song31_CH2, CH2
	track Song31_CH3, CH3
	track Song28_CH4, CH4
Song32:
	db 4  ; tracks
	track Song32_CH1, CH1
	track Song32_CH2, CH2
	track Song32_CH3, CH3
	track Song32_CH4, CH4
Song33:
	db 3  ; tracks
	track Song33_CH1, CH1
	track Song33_CH2, CH2
	track Song33_CH3, CH3
Song34:
	db 4  ; tracks
	track Song34_CH1, CH1
	track Song34_CH2, CH2
	track Song34_CH3, CH3
	track Song34_CH4, CH4
Sub_5B2C:
	length_set 3
	instrument 24
	gate 150
	volume 13
	pan PAN_LR
	base_note $27
	snd_ret
Song23_CH1:
	snd_call Sub_5B2C
	note -2, 2
	note -7, 0
	note -5, 2
	note -5, 0
Pat_G0V0R1_CH1:
	snd_call Sub_5B2C
	note -3, 0
	note -5, 0
	note -3, 0
	note -2, 3
Pat_G0V0R2_CH1:
	snd_call Sub_5B2C
	note 0, 2
	note -2, 0
	note -3, 3
Pat_G0V0R3_CH1:
	snd_call Sub_5B2C
	note 2, 2
	note 0, 0
	note -2, 3
Pat_G0V0R6_CH1:
	snd_call Sub_5B2C
	note -5, 0
	note 0, 0
	note 3, 0
	note 2, 0
	note 3, 0
	note 0, 0
Pat_G0V0R7_CH1:
	snd_call Sub_5B2C
	note -3, 0
	note -5, 0
	note -3, 0
	note -2, 3
Sub_5B63:
	length_set 3
	instrument 24
	gate 150
	pan PAN_LR
	volume 12
	base_note $27
	snd_ret
Song23_CH2:
	snd_call Sub_5B63
	note -10, 2
	note -10, 0
	note -9, 2
	note -9, 0
Pat_G0V0R1_CH2:
	snd_call Sub_5B63
	note -12, 2
	note -12, 0
	note -10, 3
Pat_G0V0R2_CH2:
	snd_call Sub_5B63
	note -9, 2
	note -10, 0
	note -12, 3
Pat_G0V0R3_CH2:
	snd_call Sub_5B63
	note -7, 2
	note -9, 0
	note -10, 3
Pat_G0V0R6_CH2:
	snd_call Sub_5B63
	note -9, 3
	note 0, 3
Pat_G0V0R7_CH2:
	snd_call Sub_5B63
	note 5, 0
	note 4, 0
	note 3, 0
	note 2, 3
Sub_5B95:
	length_set 3
	instrument 2
	volume 15
	gate 200
	pan PAN_LR
	base_note $0F
	snd_ret
Song23_CH3:
	snd_call Sub_5B95
	note 10, 2
	note 10, 0
Pat_G0V0R4_CH3:
	snd_call Sub_5B95
	note 10, 2
	note 10, 0
	note 3, 2
	note 3, 0
Pat_G0V0R5_CH3:
	snd_call Sub_5B95
	note 5, 2
	note 5, 0
	note 7, 2
	note 7, 0
Pat_G0V0R6_CH3:
	snd_call Sub_5B95
	note 3, 2
	note 3, 0
	note 4, 2
	note 4, 0
Pat_G0V0R7_CH3:
	snd_call Sub_5B95
	note 5, 2
	note 5, 0
	note 10, 2
	rest 0
Sub_5BC3:
	length_set 3
	gate 0
	pan PAN_LR
	volume 12
	snd_ret
Song23_CH4:
	snd_call Sub_5BC3
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 9, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 9, 0
Pat_G0V0R1_CH4:
	drum 9, 0
	snd_call Sub_5BC3
	instrument 5
	drum 2, 0
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	drum 2, 0
Sub_5BF0:
	length_set 3
	instrument 25
	gate 180
	pan PAN_LR
	base_note $33
	volume 11
	snd_ret
Song25_CH1:
	snd_call Sub_5BF0
	note -10, 0
	note -9, 0
	note -7, 0
	note -5, 0
	note -3, 0
	note -2, 0
Pat_G0V2R1_CH1:
	snd_call Sub_5BF0
	note 0, 0
	note -2, 0
	note 0, 0
	note 2, 2
	rest 0
Pat_G0V2R4_CH1:
	snd_call Sub_5BF0
	note -2, 0
	note 0, 0
	note 2, 0
	note 0, 0
	note 2, 0
	note 3, 0
Pat_G0V2R5_CH1:
	snd_call Sub_5BF0
	note 2, 0
	note 3, 0
	note 5, 0
	note 7, 2
	rest 0
Pat_G0V2R6_CH1:
	snd_call Sub_5BF0
	note 3, 0
	note 5, 0
	note 7, 0
	note 0, 0
	note 2, 0
	note 3, 0
Pat_G0V2R7_CH1:
	snd_call Sub_5BF0
	note 5, 0
	note 7, 0
	note 9, 0
	note 10, 2
	rest 0
Sub_5C30:
	length_set 3
	instrument 25
	gate 180
	pan PAN_LR
	base_note $27
	volume 11
	snd_ret
Song25_CH2:
	snd_call Sub_5C30
	note -2, 0
	note 0, 0
	note 2, 0
	note 3, 0
	note 5, 0
	note 7, 0
Pat_G0V2R1_CH2:
	snd_call Sub_5C30
	note 9, 0
	note 7, 0
	note 9, 0
	note 10, 2
	rest 0
Pat_G0V2R4_CH2:
	snd_call Sub_5C30
	note 5, 0
	note 7, 0
	note 10, 0
	note 7, 0
	note 10, 0
	note 12, 0
Pat_G0V2R5_CH2:
	snd_call Sub_5C30
	note 10, 0
	note 12, 0
	note 14, 0
	note 15, 2
	rest 0
Pat_G0V2R6_CH2:
	snd_call Sub_5C30
	note 12, 0
	note 14, 0
	note 15, 0
	note 7, 0
	note 10, 0
	note 12, 0
Pat_G0V2R7_CH2:
	snd_call Sub_5C30
	note 15, 0
	note 15, 0
	note 15, 0
	note 14, 2
	rest 0
Sub_5C70:
	length_set 3
	instrument 2
	gate 180
	pan PAN_LR
	volume 15
	base_note $1B
	snd_ret
Song25_CH3:
	snd_call Sub_5C70
	note -2, 0
	rest 0
	note 10, 0
Pat_G0V2R1_CH3:
	snd_call Sub_5C70
	note -2, 0
	rest 0
	note 10, 0
	note -2, 2
	rest 0
Pat_G0V2R4_CH3:
	snd_call Sub_5C70
	note -2, 0
	rest 0
	note 10, 0
	note -9, 0
	rest 0
	note 3, 0
Pat_G0V2R5_CH3:
	snd_call Sub_5C70
	note -7, 0
	rest 0
	note 5, 0
	note -5, 2
	rest 0
Pat_G0V2R6_CH3:
	snd_call Sub_5C70
	note -9, 0
	rest 0
	note 3, 0
	note -8, 0
	rest 0
	note 4, 0
Pat_G0V2R7_CH3:
	snd_call Sub_5C70
	note -7, 0
	rest 0
	note 5, 0
	note -2, 2
	rest 0
Sub_5CAD:
	length_set 3
	pan PAN_LR
	volume 12
	gate 180
	snd_ret
Song25_CH4:
	snd_call Sub_5CAD
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum_x 3, 7
	volume 0
	drum_x 3, 1
Pat_G0V2R1_CH4:
	snd_call Sub_5CAD
	instrument 28
	drum 9, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	drum 3, 2
	drest 0
Sub_5CDE:
	length_set 3
	instrument 11
	gate 150
	volume 11
	pan PAN_LR
	base_note $1B
	snd_ret
Song26_CH1:
	snd_call Sub_5CDE
	note 14, 0
	note 12, 0
	note 10, 0
	note 9, 0
	note 7, 0
	note 5, 0
Pat_G0V3R1_CH1:
	snd_call Sub_5CDE
	note 7, 0
	note 5, 0
	note 3, 0
	note 2, 2
	rest 0
Pat_G0V3R6_CH1:
	snd_call Sub_5CDE
	note 10, 0
	note 9, 0
	note 7, 0
	note 12, 0
	note 10, 0
	note 7, 0
Pat_G0V3R7_CH1:
	snd_call Sub_5CDE
	note 5, 0
	note 3, 0
	note 0, 0
	note -2, 2
	rest 0
Sub_5D0D:
	length_set 3
	instrument 11
	gate 150
	volume 11
	base_note $1B
	pan PAN_LR
	snd_ret
Song26_CH2:
	snd_call Sub_5D0D
	note 10, 0
	note 9, 0
	note 7, 0
	note 5, 0
	note 3, 0
	note 2, 0
Pat_G0V3R1_CH2:
	snd_call Sub_5D0D
	note 3, 0
	note 2, 0
	note 0, 0
	note -2, 2
	rest 0
Pat_G0V3R6_CH2:
	snd_call Sub_5D0D
	note 7, 0
	note 5, 0
	note 3, 0
	note 7, 0
	note 4, 0
	note 0, 0
Pat_G0V3R7_CH2:
	snd_call Sub_5D0D
	note 3, 0
	note 0, 0
	note -3, 0
	note 2, 2
	rest 0
Sub_5D3C:
	length_set 3
	instrument 30
	gate 0
	volume 10
	pan PAN_LR
	base_note $27
	snd_ret
Song24_CH1:
	snd_call Sub_5D3C
	note -2, 2
	note -7, 0
	note -5, 2
	note -5, 0
Pat_G0V1R1_CH1:
	snd_call Sub_5D3C
	note -3, 0
	note -5, 0
	note -3, 0
	note -2, 3
Pat_G0V1R2_CH1:
	snd_call Sub_5D3C
	note 0, 2
	note -2, 0
	note -3, 3
Pat_G0V1R3_CH1:
	snd_call Sub_5D3C
	note 2, 2
	note 0, 0
	note -2, 3
Pat_G0V1R6_CH1:
	snd_call Sub_5D3C
	note -5, 0
	note 0, 0
	note 3, 0
	note 2, 0
	note 3, 0
	note 0, 0
Pat_G0V1R7_CH1:
	snd_call Sub_5D3C
	note -3, 0
	note -5, 0
	note -3, 0
	note -2, 3
Sub_5D73:
	length_set 3
	instrument 30
	gate 0
	volume 9
	pan PAN_LR
	base_note $27
	snd_ret
Song24_CH2:
	snd_call Sub_5D73
	note -10, 2
	note -10, 0
	note -9, 2
	note -9, 0
Pat_G0V1R1_CH2:
	snd_call Sub_5D73
	note -12, 2
	note -12, 0
	note -10, 3
Pat_G0V1R2_CH2:
	snd_call Sub_5D73
	note -9, 2
	note -10, 0
	note -12, 3
Pat_G0V1R3_CH2:
	snd_call Sub_5D73
	note -7, 2
	note -9, 0
	note -10, 3
Pat_G0V1R6_CH2:
	snd_call Sub_5D73
	note -9, 3
	note 0, 3
Pat_G0V1R7_CH2:
	snd_call Sub_5D73
	note 5, 0
	note 4, 0
	note 3, 0
	note 2, 3
Sub_5DA5:
	length_set 3
	gate 0
	instrument 2
	volume 14
	base_note $1B
	pan PAN_LR
	snd_ret
Song24_CH3:
	snd_call Sub_5DA5
	note -2, 0
	note 5, 0
	note 10, 0
Pat_G0V1R4_CH3:
	snd_call Sub_5DA5
	note -2, 0
	note 5, 0
	note 10, 0
	note -9, 0
	note -2, 0
	note 3, 0
Pat_G0V1R5_CH3:
	snd_call Sub_5DA5
	note -7, 0
	note 0, 0
	note 5, 0
	note -5, 0
	note 2, 0
	note 7, 0
Pat_G0V1R6_CH3:
	snd_call Sub_5DA5
	note -9, 0
	note -2, 0
	note 3, 0
	note -8, 0
	note -2, 0
	note 4, 0
Pat_G0V1R7_CH3:
	snd_call Sub_5DA5
	note -7, 0
	note 0, 0
	note 5, 0
	note -2, 0
	note 5, 0
	note 10, 0
Sub_5DDC:
	length_set 3
	instrument 31
	gate 160
	volume 13
	pan PAN_LR
	base_note $23
	snd_ret
Song27_CH1:
	snd_call Sub_5DDC
	note_x -3, 48
Pat_G0V4R1_CH1:
	snd_call Sub_5DDC
	note_x 6, 32
	note 6, 2
Pat_G0V4R2_CH1:
	snd_call Sub_5DDC
	note_x -1, 48
Pat_G0V4R3_CH1:
	snd_call Sub_5DDC
	note_x 7, 32
	note 7, 2
Pat_G0V4R4_CH1:
	snd_call Sub_5DDC
	note_x 6, 32
	note 4, 2
Pat_G0V4R5_CH1:
	snd_call Sub_5DDC
	note_x 2, 32
	note 4, 2
Pat_G0V4R6_CH1:
	snd_call Sub_5DDC
	note 7, 2
	note 6, 2
	note 4, 2
Pat_G0V4R7_CH1:
	snd_call Sub_5DDC
	note_x 2, 48
Sub_5E16:
	length_set 3
	instrument 31
	volume 15
	base_note $1B
	snd_ret
Song27_CH2:
	snd_call Sub_5E16
	gate 100
	pan PAN_L
	note 5, 0
	note -7, 0
	note -2, 0
	note 2, 0
	note 5, 0
	note 10, 0
Pat_G0V4R1_CH2:
	snd_call Sub_5E16
	gate 160
	note_x 10, 32
	note 10, 2
Pat_G0V4R2_CH2:
	snd_call Sub_5E16
	gate 100
	pan PAN_R
	note 7, 0
	note -5, 0
	note -2, 0
	note 3, 0
	note 7, 0
	note 10, 0
Pat_G0V4R3_CH2:
	snd_call Sub_5E16
	gate 160
	pan PAN_LR
	volume 12
	note_x 7, 32
	note 7, 2
Pat_G0V4R4_CH2:
	snd_call Sub_5E16
	note_x 5, 32
	note 3, 2
Pat_G0V4R5_CH2:
	snd_call Sub_5E16
	note_x 2, 32
	note 3, 2
Pat_G0V4R6_CH2:
	snd_call Sub_5E16
	note 7, 2
	note 5, 2
	note 3, 2
Pat_G0V4R7_CH2:
	snd_call Sub_5E16
	note_x 2, 48
Sub_5E64:
	length_set 3
	instrument 2
	gate 230
	volume 14
	pan PAN_LR
	base_note $0F
	snd_ret
Song27_CH3:
	snd_call Sub_5E64
	note_x 10, 32
	note 10, 2
Pat_G0V4R4_CH3:
	snd_call Sub_5E64
	note_x 10, 32
	note 3, 2
Pat_G0V4R5_CH3:
	snd_call Sub_5E64
	note_x 5, 32
	note 7, 2
Pat_G0V4R6_CH3:
	snd_call Sub_5E64
	note_x 3, 32
	note 5, 2
Pat_G0V4R7_CH3:
	snd_call Sub_5E64
	note_x 10, 48
Sub_5E8E:
	length_set 3
	gate 0
	volume 12
	pan PAN_LR
	snd_ret
Song27_CH4:
	snd_call Sub_5E8E
	instrument 28
	drum 9, 2
	instrument 5
	drum 2, 2
	drum 2, 2
Pat_G0V4R1_CH4:
	snd_call Sub_5E8E
	instrument 29
	drum 3, 2
	instrument 5
	drum 2, 2
	drum 2, 2
Sub_5EAB:
	length_set 5
	instrument 19
	gate 0
	volume 14
	pan PAN_LR
	base_note $27
	snd_ret
Song28_CH1:
	snd_call Sub_5EAB
	note 2, 1
	rest 1
	note 2, 1
	note 5, 1
Pat_G1V0R1_CH1:
	snd_call Sub_5EAB
	note 7, 1
	note 5, 1
	note 3, 1
	rest 1
Pat_G1V0R2_CH1:
	snd_call Sub_5EAB
	note 0, 1
	rest 1
	note 0, 1
	note 3, 1
Pat_G1V0R3_CH1:
	snd_call Sub_5EAB
	note 5, 1
	note 3, 1
	note 2, 1
	rest 1
Pat_G1V0R4_CH1:
	snd_call Sub_5EAB
	note 10, 1
	note 10, 1
	note 9, 1
	note 7, 1
Pat_G1V0R5_CH1:
	snd_call Sub_5EAB
	note 5, 1
	rest 1
	note 10, 1
	note 2, 1
Pat_G1V0R6_CH1:
	snd_call Sub_5EAB
	note 3, 1
	note 5, 1
	note 7, 1
	note 9, 1
Pat_G1V0R7_CH1:
	snd_call Sub_5EAB
	note 10, 1
	rest_x 42
Sub_5EEF:
	length_set 5
	instrument 19
	gate 0
	volume 13
	base_note $27
	pan PAN_LR
	snd_ret
Song28_CH2:
	snd_call Sub_5EEF
	note -7, 1
	rest 1
	note -7, 1
	note -2, 1
Pat_G1V0R1_CH2:
	snd_call Sub_5EEF
	note -2, 1
	note -2, 1
	note -2, 1
	rest 1
Pat_G1V0R2_CH2:
	snd_call Sub_5EEF
	note -3, 1
	rest 1
	note -3, 1
	note -3, 1
Pat_G1V0R3_CH2:
	snd_call Sub_5EEF
	note -2, 1
	note -3, 1
	note -7, 1
	rest 1
Pat_G1V0R4_CH2:
	snd_call Sub_5EEF
	note 7, 1
	note 7, 1
	note 5, 1
	note 3, 1
Pat_G1V0R5_CH2:
	snd_call Sub_5EEF
	note 2, 1
	rest 1
	note 2, 1
	note -2, 1
Pat_G1V0R6_CH2:
	snd_call Sub_5EEF
	note 0, 1
	rest 1
	note -3, 1
	note 3, 1
Pat_G1V0R7_CH2:
	snd_call Sub_5EEF
	note 2, 1
	rest_x 42
Sub_5F33:
	length_set 5
	instrument 2
	gate 180
	volume 15
	pan PAN_LR
	base_note $1B
	snd_ret
Song28_CH3:
	snd_call Sub_5F33
	note -2, 1
	rest 1
	note -2, 1
	note 2, 1
Pat_G1V0R1_CH3:
	snd_call Sub_5F33
	note 3, 1
	note 2, 1
	note 0, 1
	rest 1
Pat_G1V0R2_CH3:
	snd_call Sub_5F33
	note -7, 1
	rest 1
	note -7, 1
	note -3, 1
Pat_G1V0R3_CH3:
	snd_call Sub_5F33
	note 2, 1
	note 0, 1
	note -2, 1
	rest 1
Pat_G1V0R4_CH3:
	snd_call Sub_5F33
	note 3, 1
	note 3, 1
	note 3, 1
	note 3, 1
Pat_G1V0R5_CH3:
	snd_call Sub_5F33
	note 2, 1
	note 2, 1
	note -5, 1
	note -5, 1
Pat_G1V0R6_CH3:
	snd_call Sub_5F33
	note 0, 1
	note 0, 1
	note -7, 1
	note -7, 1
Pat_G1V0R7_CH3:
	snd_call Sub_5F33
	note -2, 1
	rest 1
	note -14, 1
	rest 1
Sub_5F78:
	length_set 5
	pan PAN_LR
	volume 12
	gate 0
	snd_ret
Song28_CH4:
	snd_call Sub_5F78
	instrument 28
	drum 9, 1
	instrument 5
	drum 2, 1
	instrument 29
	drum 3, 1
	instrument 28
	drum 9, 1
Pat_G1V0R1_CH4:
	snd_call Sub_5F78
	instrument 5
	drum 2, 1
	instrument 28
	drum 9, 1
	instrument 29
	drum 3, 1
	drest 1
Sub_5F9D:
	length_set 5
	instrument 33
	gate 180
	volume 13
	pan PAN_LR
	base_note $27
	snd_ret
Song29_CH1:
	snd_call Sub_5F9D
	note 2, 0
	note 2, 0
	note 2, 0
	note 2, 0
	note 2, 1
	note 5, 1
Pat_G1V1R1_CH1:
	snd_call Sub_5F9D
	note 7, 0
	note 7, 0
	note 5, 0
	note 5, 0
	note 3, 1
	rest 1
Pat_G1V1R2_CH1:
	snd_call Sub_5F9D
	note 0, 0
	note 0, 0
	note 0, 0
	note 0, 0
	note 0, 1
	note 3, 1
Pat_G1V1R3_CH1:
	snd_call Sub_5F9D
	note 5, 0
	note 5, 0
	note 3, 0
	note 3, 0
	note 2, 1
	rest 1
Pat_G1V1R4_CH1:
	snd_call Sub_5F9D
	note 10, 0
	note 10, 0
	note 10, 0
	note 10, 0
	note 9, 1
	note 7, 0
	note 7, 0
Pat_G1V1R5_CH1:
	snd_call Sub_5F9D
	note 5, 0
	note 5, 0
	note 2, 0
	note 2, 0
	note 10, 0
	note 10, 0
	note 2, 0
	note 2, 0
Pat_G1V1R6_CH1:
	snd_call Sub_5F9D
	note 3, 0
	note 3, 0
	note 5, 0
	note 5, 0
	note 7, 0
	note 7, 0
	note 9, 0
	note 9, 0
Pat_G1V1R7_CH1:
	snd_call Sub_5F9D
	note 10, 0
	note 10, 0
	note 5, 0
	note 2, 0
	note -2, 1
	rest 1
Sub_5FF7:
	length_set 5
	instrument 33
	gate 180
	volume 13
	pan PAN_LR
	base_note $27
	snd_ret
Song29_CH2:
	snd_call Sub_5FF7
	note -2, 0
	note -2, 0
	note -2, 0
	note -2, 0
	note -2, 1
	note 2, 1
Pat_G1V1R1_CH2:
	snd_call Sub_5FF7
	note 3, 0
	note 3, 0
	note 2, 0
	note 2, 0
	note 0, 1
	rest 1
Pat_G1V1R2_CH2:
	snd_call Sub_5FF7
	note -3, 0
	note -3, 0
	note -3, 0
	note -3, 0
	note -3, 1
	note 0, 1
Pat_G1V1R3_CH2:
	snd_call Sub_5FF7
	note 2, 0
	note 2, 0
	note 0, 0
	note 0, 0
	note -2, 1
	rest 1
Pat_G1V1R4_CH2:
	snd_call Sub_5FF7
	note 7, 0
	note 7, 0
	note 7, 0
	note 7, 0
	note 5, 1
	note 3, 0
	note 3, 0
Pat_G1V1R5_CH2:
	snd_call Sub_5FF7
	note 2, 0
	note 2, 0
	note -2, 0
	note -2, 0
	note 7, 0
	note 7, 0
	note -2, 0
	note -2, 0
Pat_G1V1R6_CH2:
	snd_call Sub_5FF7
	note 0, 0
	note 0, 0
	note 2, 0
	note 2, 0
	note 3, 0
	note 3, 0
	note 5, 0
	note 5, 0
Pat_G1V1R7_CH2:
	snd_call Sub_5FF7
	note 2, 0
	note 5, 0
	note 2, 0
	note -2, 0
	note -7, 1
	rest 1
Sub_6051:
	length_set 5
	instrument 2
	gate 200
	volume 15
	pan PAN_LR
	base_note $0F
	snd_ret
Song29_CH3:
	snd_call Sub_6051
	note 10, 1
	note 10, 0
	note 10, 0
	note 14, 0
	note 14, 0
	note 14, 1
Pat_G1V1R1_CH3:
	snd_call Sub_6051
	note 15, 0
	note 15, 0
	note 14, 1
	note 12, 1
	rest 1
Pat_G1V1R2_CH3:
	snd_call Sub_6051
	note 5, 1
	note 5, 0
	note 5, 0
	note 9, 0
	note 9, 0
	note 9, 1
Pat_G1V1R3_CH3:
	snd_call Sub_6051
	note 14, 0
	note 14, 0
	note 12, 1
	note 10, 1
	rest 1
Pat_G1V1R4_CH3:
	snd_call Sub_6051
	note 15, 0
	note 15, 0
	note 15, 0
	note 15, 0
	note 15, 1
	note 15, 0
	note 15, 0
Pat_G1V1R5_CH3:
	snd_call Sub_6051
	note 14, 0
	note 14, 0
	note 14, 0
	note 14, 0
	note 7, 0
	note 7, 0
	note 7, 1
Pat_G1V1R6_CH3:
	snd_call Sub_6051
	note 12, 0
	note 12, 0
	note 12, 1
	note 5, 0
	note 5, 0
	note 5, 1
Pat_G1V1R7_CH3:
	snd_call Sub_6051
	note 10, 0
	note 10, 0
	note 5, 0
	note 5, 0
	note -2, 1
	rest 1
Sub_60A6:
	length_set 5
	gate 0
	volume 12
	pan PAN_LR
	snd_ret
Song29_CH4:
	snd_call Sub_60A6
	instrument 28
	drum 9, 1
	instrument 5
	drum 2, 1
Pat_G1V1R1_CH4:
	snd_call Sub_60A6
	instrument 28
	drum 9, 1
	instrument 5
	drum 2, 1
	instrument 29
	drum 3, 1
	drest 1
Sub_60C5:
	length_set 5
	instrument 14
	gate 160
	volume 15
	pan PAN_L
	base_note $27
	snd_ret
Song30_CH1:
	snd_call Sub_60C5
	note 10, 1
	note 9, 1
	note 7, 1
	note 5, 1
Pat_G1V3R1_CH1:
	snd_call Sub_60C5
	note 7, 1
	note 5, 1
	note 3, 1
	rest 1
Pat_G1V3R2_CH1:
	snd_call Sub_60C5
	note 9, 1
	note 7, 1
	note 5, 1
	note 3, 1
Pat_G1V3R3_CH1:
	snd_call Sub_60C5
	note 5, 1
	note 3, 1
	note 2, 1
	rest 1
Pat_G1V3R4_CH1:
	snd_call Sub_60C5
	note 10, 1
	note 9, 1
	note 7, 1
	note 5, 1
Pat_G1V3R5_CH1:
	snd_call Sub_60C5
	note 7, 1
	note 5, 1
	note 3, 1
	note 2, 1
Pat_G1V3R6_CH1:
	snd_call Sub_60C5
	note 3, 1
	note 2, 1
	note 0, 1
	note -3, 1
Pat_G1V3R7_CH1:
	snd_call Sub_60C5
	note -2, 1
	note -3, 1
	note -2, 1
	rest 1
Sub_610A:
	length_set 5
	instrument 14
	gate 160
	volume 15
	pan PAN_R
	base_note $27
	snd_ret
Song30_CH2:
	snd_call Sub_610A
	note 2, 1
	note 0, 1
	note -2, 1
	note -3, 1
Pat_G1V3R1_CH2:
	snd_call Sub_610A
	note -2, 1
	note -3, 1
	note -5, 1
	rest 1
Pat_G1V3R2_CH2:
	snd_call Sub_610A
	note 0, 1
	note -2, 1
	note -3, 1
	note 0, 1
Pat_G1V3R3_CH2:
	snd_call Sub_610A
	note 2, 1
	note 0, 1
	note -2, 1
	rest 1
Pat_G1V3R4_CH2:
	snd_call Sub_610A
	note 7, 1
	note 5, 1
	note 3, 1
	note 2, 1
Pat_G1V3R5_CH2:
	snd_call Sub_610A
	note 3, 1
	note 2, 1
	note 0, 1
	note -2, 1
Pat_G1V3R6_CH2:
	snd_call Sub_610A
	note 0, 1
	note -2, 1
	note -3, 1
	note -9, 1
Pat_G1V3R7_CH2:
	snd_call Sub_610A
	note -10, 1
	note -12, 1
	note -10, 1
	rest 1
Sub_614F:
	length_set 5
	instrument 2
	gate 180
	volume 15
	pan PAN_LR
	base_note $1B
	snd_ret
Song30_CH3:
	snd_call Sub_614F
	note -2, 1
	note -2, 1
	note -2, 1
	note 2, 1
Pat_G1V3R1_CH3:
	snd_call Sub_614F
	note 3, 1
	note 2, 1
	note 0, 1
	rest 1
Pat_G1V3R2_CH3:
	snd_call Sub_614F
	note -7, 1
	note -7, 1
	note -7, 1
	note -3, 1
Pat_G1V3R3_CH3:
	snd_call Sub_614F
	note 2, 1
	note 0, 1
	note -2, 1
	rest 1
Pat_G1V3R4_CH3:
	snd_call Sub_614F
	note 3, 1
	note 3, 1
	note 3, 1
	note 3, 1
Pat_G1V3R5_CH3:
	snd_call Sub_614F
	note 2, 1
	note 2, 1
	note -5, 1
	note -5, 1
Pat_G1V3R6_CH3:
	snd_call Sub_614F
	note 0, 1
	note 0, 1
	note -7, 1
	note -7, 1
Pat_G1V3R7_CH3:
	snd_call Sub_614F
	note -2, 1
	rest 1
	note -14, 1
	rest 1
Sub_6194:
	length_set 5
	instrument 20
	gate 180
	volume 13
	pan PAN_LR
	base_note $27
	snd_ret
Song31_CH1:
	snd_call Sub_6194
	note -7, 1
	note -2, 1
	note 2, 1
	note -2, 1
Pat_G1V2R1_CH1:
	snd_call Sub_6194
	note 3, 1
	note 5, 1
	note 9, 1
	rest 1
Pat_G1V2R2_CH1:
	snd_call Sub_6194
	note -3, 1
	note 0, 1
	note 3, 1
	note 0, 1
Pat_G1V2R3_CH1:
	snd_call Sub_6194
	note 2, 1
	note 3, 1
	note 5, 1
	rest 1
Pat_G1V2R4_CH1:
	snd_call Sub_6194
	note -2, 1
	note 3, 1
	note 7, 1
	note 10, 1
Pat_G1V2R5_CH1:
	snd_call Sub_6194
	note 5, 1
	note 7, 1
	note 5, 1
	rest 1
Pat_G1V2R6_CH1:
	snd_call Sub_6194
	note 0, 1
	note 3, 1
	note 5, 1
	note 9, 1
Pat_G1V2R7_CH1:
	snd_call Sub_6194
	note 10, 1
	note 14, 1
	note 10, 1
	rest 1
Sub_61D9:
	length_set 5
	instrument 20
	gate 180
	volume 13
	pan PAN_LR
	base_note $27
	snd_ret
Song31_CH2:
	snd_call Sub_61D9
	note -10, 1
	note -7, 1
	note -2, 1
	note -7, 1
Pat_G1V2R1_CH2:
	snd_call Sub_61D9
	note 0, 1
	note 2, 1
	note 3, 1
	rest 1
Pat_G1V2R2_CH2:
	snd_call Sub_61D9
	note -7, 1
	note -3, 1
	note 0, 1
	note -3, 1
Pat_G1V2R3_CH2:
	snd_call Sub_61D9
	note -7, 1
	note -2, 1
	note 2, 1
	rest 1
Pat_G1V2R4_CH2:
	snd_call Sub_61D9
	note -5, 1
	note -2, 1
	note 3, 1
	note 7, 1
Pat_G1V2R5_CH2:
	snd_call Sub_61D9
	note 2, 1
	note 3, 1
	note 2, 1
	rest 1
Pat_G1V2R6_CH2:
	snd_call Sub_61D9
	note -3, 1
	note 0, 1
	note 3, 1
	note 5, 1
Pat_G1V2R7_CH2:
	snd_call Sub_61D9
	note 2, 1
	note 10, 1
	note 2, 1
	rest 1
Sub_621E:
	length_set 5
	instrument 2
	gate 200
	volume 15
	pan PAN_LR
	base_note $1B
	snd_ret
Song31_CH3:
	snd_call Sub_621E
	note -2, 1
	note -2, 1
	note -2, 1
	note 2, 1
Pat_G1V2R1_CH3:
	snd_call Sub_621E
	note 0, 1
	note 3, 1
	note 5, 1
	rest 1
Pat_G1V2R2_CH3:
	snd_call Sub_621E
	note -7, 1
	note -7, 1
	note -7, 1
	note -3, 1
Pat_G1V2R3_CH3:
	snd_call Sub_621E
	note -2, 1
	note 2, 1
	note 5, 1
	rest 1
Pat_G1V2R4_CH3:
	snd_call Sub_621E
	note 3, 1
	note 3, 1
	note 3, 1
	note 3, 1
Pat_G1V2R5_CH3:
	snd_call Sub_621E
	note 2, 1
	note 5, 1
	note 10, 1
	note -2, 1
Pat_G1V2R6_CH3:
	snd_call Sub_621E
	note 0, 1
	note 0, 1
	note 5, 1
	note -7, 1
Pat_G1V2R7_CH3:
	snd_call Sub_621E
	note -2, 1
	note 5, 1
	note 10, 1
	rest 1
Sub_6263:
	length_set 5
	instrument 12
	gate 0
	volume 9
	pan PAN_LR
	base_note $27
	snd_ret
Song32_CH1:
	snd_call Sub_6263
	note_x 2, 37
	note_x -2, 19
Pat_G1V4R1_CH1:
	snd_call Sub_6263
	note 0, 5
Pat_G1V4R2_CH1:
	snd_call Sub_6263
	note_x 3, 18
	note_x 2, 19
	note_x 3, 19
Pat_G1V4R3_CH1:
	snd_call Sub_6263
	note 5, 5
Pat_G1V4R4_CH1:
	snd_call Sub_6263
	note 10, 5
Pat_G1V4R5_CH1:
	snd_call Sub_6263
	note_x 5, 37
	note_x 10, 19
Pat_G1V4R6_CH1:
	snd_call Sub_6263
	note_x 9, 18
	note_x 7, 19
	note_x 9, 19
Pat_G1V4R7_CH1:
	snd_call Sub_6263
	note 10, 5
Sub_62A0:
	length_set 5
	instrument 32
	gate 0
	volume 9
	pan PAN_LR
	base_note $27
	snd_ret
Song32_CH2:
	snd_call Sub_62A0
	note -7, 5
Pat_G1V4R1_CH2:
	snd_call Sub_62A0
	note -5, 5
Pat_G1V4R2_CH2:
	snd_call Sub_62A0
	note -3, 5
Pat_G1V4R3_CH2:
	snd_call Sub_62A0
	note 2, 5
Pat_G1V4R4_CH2:
	snd_call Sub_62A0
	note_x 7, 18
	note_x 5, 19
	note_x 3, 19
Pat_G1V4R5_CH2:
	snd_call Sub_62A0
	note 2, 5
Pat_G1V4R6_CH2:
	snd_call Sub_62A0
	note_x 0, 37
	note_x 3, 19
Pat_G1V4R7_CH2:
	snd_call Sub_62A0
	note 2, 5
Sub_62D5:
	length_set 5
	instrument 2
	gate 180
	volume 15
	pan PAN_LR
	base_note $1B
	snd_ret
Song32_CH3:
	snd_call Sub_62D5
	note_x -2, 18
	note_x 10, 19
	note_x 10, 19
Pat_G1V4R1_CH3:
	snd_call Sub_62D5
	note_x -9, 18
	note_x 3, 19
	note_x 3, 19
Pat_G1V4R2_CH3:
	snd_call Sub_62D5
	note_x -12, 18
	note_x 0, 19
	note_x 0, 19
Pat_G1V4R3_CH3:
	snd_call Sub_62D5
	note_x -2, 18
	note_x 10, 19
	note_x 10, 19
Pat_G1V4R4_CH3:
	snd_call Sub_62D5
	note_x -9, 18
	note_x 3, 19
	note_x 3, 19
Pat_G1V4R5_CH3:
	snd_call Sub_62D5
	note_x -10, 18
	note_x 2, 19
	note_x 2, 19
Pat_G1V4R6_CH3:
	snd_call Sub_62D5
	note_x -12, 18
	note_x 0, 19
	note_x 0, 19
Pat_G1V4R7_CH3:
	snd_call Sub_62D5
	note_x -2, 18
	note_x 10, 19
	note_x 10, 19
Sub_632A:
	length_set 5
	gate 0
	volume 12
	pan PAN_LR
	snd_ret
Song32_CH4:
	snd_call Sub_632A
	instrument 28
	drum_x 9, 18
	instrument 5
	drum_x 2, 19
	drum_x 2, 19
Song33_CH1:
	length_set 3
	instrument 21
	gate 0
	base_note $27
	volume 11
	pan PAN_LR
	drum 25, 0
	drum 16, 0
	drum 5, 0
	drum 5, 0
	drum 5, 0
	drum 5, 0
	drum 10, 0
	drum_x 9, 2
	drum_x 8, 2
	drum_x 7, 2
	drum_x 6, 2
	drum_x 5, 2
	drum_x 4, 2
	drum_x 3, 2
	drum_x 2, 2
	drum_x 1, 2
	drum_x 0, 2
	drum 30, 0
	snd_end
Song33_CH2:
	length_set 3
	instrument 21
	gate 0
	pan PAN_LR
	volume 10
	base_note $27
	note -9, 0
	rest 0
	rest 0
	note 4, 0
	note 3, 0
	note 0, 0
	note 2, 0
	note_x 1, 2
	note_x 0, 2
	note_x -1, 2
	note_x -2, 2
	note_x -3, 2
	note_x -4, 2
	note_x -5, 2
	note_x -6, 2
	note_x -8, 2
	note -10, 0
	snd_end
Song33_CH3:
	length_set 3
	instrument 2
	gate 180
	pan PAN_LR
	base_note $0F
	volume 12
	note 5, 0
	rest 0
	note 5, 0
	note 5, 0
	note 7, 0
	note 9, 0
	note 10, 0
	rest 0
	rest 0
	note -2, 0
	snd_end
Song34_CH1:
	length_set 9
	instrument 19
	base_note $33
	gate 0
	pan PAN_LR
	volume 13
	snd_call Sub_63CC
	snd_call Sub_63EB
	snd_call Sub_63CC
	snd_call Sub_63EE
	snd_call Sub_642F
	snd_call Sub_644A
	snd_call Sub_642F
	snd_call Sub_6456
	snd_end
Sub_63CC:
	note -4, 2
	note 3, 1
	note 8, 1
	note 10, 1
	note 8, 1
	note 10, 1
	note 15, 2
	note 10, 1
	note 8, 1
	note 3, 1
	note 10, 1
	note 8, 1
	note 3, 1
	note -4, 1
	note -4, 2
	note 4, 1
	note 8, 1
	note 10, 1
	note 8, 1
	note 10, 1
	base_note $3F
	note 4, 2
	base_note $33
	note 10, 1
	note 8, 1
	note 4, 1
	note 10, 1
	note 8, 1
	snd_ret
Sub_63EB:
	note 4, 1
	note -4, 1
	snd_ret
Sub_63EE:
	instrument 24
	gate 180
	base_note $27
	note 0, 1
	note 1, 1
	note 3, 5
	note 3, 2
	note 3, 1
	note 3, 3
	note 1, 2
	note 0, 2
	note -2, 2
	note -4, 4
	note -4, 1
	note -4, 1
	note -2, 2
	note -4, 2
	note 0, 2
	note 3, 2
	note 5, 4
	note 5, 2
	rest 2
	note 3, 2
	note 3, 2
	note 1, 2
	note 3, 0
	note_x 3, 12
	note_x 1, 12
	note_x 0, 12
	note 1, 3
	note_x 8, 72
	rest 1
	note_x 1, 12
	note_x 0, 12
	note_x -2, 12
	note 0, 5
	note 7, 5
	note 8, 4
	note 5, 1
	note 7, 1
	note 8, 5
	note 8, 2
	note 8, 1
	note 8, 3
	note 7, 2
	note 7, 1
	note 8, 3
	note 10, 0
	instrument 21
	base_note $33
	rest 1
	note -9, 3
	snd_ret
Sub_642F:
	note 0, 5
	note 0, 2
	note 0, 1
	note 0, 3
	note -4, 2
	note -2, 1
	note -4, 3
	note 1, 2
	note -7, 2
	note -4, 1
	note 1, 3
	gate 0
	note_x 1, 2
	note_x 3, 2
	note_x 4, 14
	gate 180
	note 3, 2
	note 3, 1
	note 1, 3
	note 0, 5
	note 0, 2
	snd_ret
Sub_644A:
	note 0, 1
	note 0, 3
	note -4, 2
	note -7, 1
	note -4, 3
	note_x -2, 72
	rest 2
	note -9, 2
	note -7, 1
	note -9, 3
	snd_ret
Sub_6456:
	note 0, 2
	note 7, 5
	note 5, 5
	note_x 8, 72
	rest 2
	note 8, 2
	note 7, 1
	note 5, 3
	note 3, 5
	note 0, 5
	note -4, 5
	note 7, 2
	note 5, 2
	note 3, 5
	note 0, 5
	note 8, 5
	note -7, 1
	note -4, 3
	note 3, 2
	note 1, 2
	note -7, 1
	note -2, 3
	note -4, 5
	note -5, 5
	note_x -4, 144
	rest_x 156
	gate 0
	note_x -4, 144
	snd_end
Song34_CH2:
	length_set 9
	instrument 19
	volume 11
	base_note $33
	gate 0
	snd_call Sub_649A
	snd_call Sub_64BE
	snd_call Sub_649E
	snd_call Sub_64C2
	snd_call Sub_64FE
	snd_call Sub_6519
	snd_call Sub_64FE
	snd_call Sub_6524
Sub_649A:
	rest_x 6
	pan PAN_R
Sub_649E:
	note -4, 2
	note 3, 1
	note 8, 1
	note 10, 1
	note 8, 1
	note 10, 1
	note 15, 2
	note 10, 1
	note 8, 1
	note 3, 1
	note 10, 1
	note 8, 1
	note 3, 1
	note -4, 1
	pan PAN_L
	note -4, 2
	note 4, 1
	note 8, 1
	note 10, 1
	note 8, 1
	note 10, 1
	base_note $3F
	note 4, 2
	base_note $33
	note 10, 1
	note 8, 1
	note 4, 1
	note 10, 1
	snd_ret
Sub_64BE:
	note 8, 1
	note 4, 1
	note -4, 1
	snd_ret
Sub_64C2:
	note_x 8, 3
	volume 12
	instrument 25
	pan PAN_LR
	base_note $27
	note -4, 1
	note -2, 1
	note_x 0, 72
	note 4, 5
	note 7, 5
	note_x 5, 72
	note 6, 5
	note 3, 5
	note_x 1, 72
	note_x 10, 72
	note 7, 5
	note 10, 5
	note_x 9, 72
	gate 200
	note -2, 5
	note 5, 5
	note 3, 2
	note -2, 2
	note_x -2, 12
	note_x -5, 12
	note_x -9, 12
	gate 0
	note -4, 5
	note 0, 5
	note 5, 5
	note 3, 5
	note 2, 5
	note -2, 5
	note 2, 5
	note 5, 5
	note 7, 5
	note 5, 5
	note 4, 5
	rest 1
	gate 180
	instrument 21
	note 1, 3
	snd_ret
Sub_64FE:
	note 8, 5
	note 8, 2
	note 8, 1
	note 6, 3
	note 6, 2
	note 6, 1
	note 6, 3
	note 5, 2
	note -4, 2
	note 1, 1
	note 5, 3
	gate 0
	note_x 6, 2
	note_x 7, 2
	note_x 8, 14
	gate 180
	note 6, 2
	note 6, 1
	note 4, 3
	note 3, 5
	note 3, 2
	snd_ret
Sub_6519:
	note 3, 1
	note 2, 3
	note 2, 2
	note 2, 1
	note 2, 3
	note 1, 5
	note 8, 5
	note 7, 5
	note 2, 1
	note 1, 3
	snd_ret
Sub_6524:
	note 3, 2
	note 12, 5
	note 8, 5
	gate 180
	note_x 11, 72
	rest 2
	note 11, 2
	note 15, 1
	note 13, 3
	note 12, 5
	note 7, 5
	note 5, 5
	note 15, 2
	note 13, 2
	note 12, 5
	note 10, 5
	note 12, 5
	rest 1
	note 3, 3
	note 1, 5
	note 8, 5
	note 5, 5
	note 3, 2
	note 1, 2
	instrument 19
	gate 0
	base_note $33
	note -4, 2
	note 4, 1
	note 8, 1
	note 10, 1
	note 8, 1
	note 10, 1
	base_note $3F
	note 4, 2
	base_note $33
	note 10, 1
	note 8, 1
	note 4, 1
	note 10, 1
	note 8, 1
	note 4, 1
	note -4, 1
	note -3, 2
	note 1, 1
	note 4, 1
	note 8, 1
	note 4, 1
	note 8, 1
	base_note $3F
	note 4, 2
	base_note $33
	note 8, 1
	note 4, 1
	note 1, 1
	note_x 8, 13
	note_x 4, 16
	note_x 1, 19
	instrument 21
	note_x -12, 144
	snd_end
Song34_CH3:
	length_set 9
	instrument 2
	gate 180
	volume 15
	pan PAN_LR
	base_note $1B
	snd_call Sub_658B
	snd_call Sub_65D2
	snd_call Sub_65E8
	snd_call Sub_65D2
	snd_call Sub_65F0
	snd_end
Sub_658B:
	snd_loop 8
	rest 5
	snd_endloop
	snd_loop 2
	note -4, 3
	note -4, 1
	rest 1
	note -4, 2
	note -4, 1
	note -4, 5
	rest 5
	snd_endloop
	note -4, 3
	note -4, 1
	rest 1
	note -4, 2
	note -4, 1
	note 0, 5
	note -8, 5
	note -7, 3
	note -7, 1
	rest 1
	note -7, 2
	note -7, 1
	note -4, 5
	rest 5
	note 1, 3
	note 1, 1
	rest 1
	note 1, 2
	note 1, 1
	note 1, 5
	rest 5
	note 0, 3
	note 0, 1
	rest 1
	note 0, 2
	note 0, 1
	note -7, 5
	rest 5
	note -2, 3
	note -2, 1
	rest 1
	note -2, 2
	note -2, 1
	note 3, 5
	rest 5
	note -4, 3
	note -4, 1
	rest 1
	note -4, 2
	note -5, 1
	note -7, 5
	rest 5
	note -2, 3
	note -2, 1
	rest 1
	note -2, 2
	note -2, 1
	note -2, 5
	rest 5
	note 3, 3
	note 3, 1
	rest 1
	note 3, 2
	note 3, 1
	note -9, 5
	rest 5
	snd_ret
Sub_65D2:
	note -4, 3
	note -4, 1
	rest 1
	note -4, 2
	note -4, 1
	note -6, 5
	rest 5
	note -7, 3
	note -7, 1
	rest 1
	note -7, 2
	note -7, 1
	note -8, 5
	rest 5
	note -9, 3
	note -9, 1
	rest 1
	note -9, 2
	note -9, 1
	note -10, 5
	rest 5
	snd_ret
Sub_65E8:
	note -2, 3
	note -2, 1
	rest 1
	note -2, 2
	note -2, 1
	note -9, 5
	rest 5
	snd_ret
Sub_65F0:
	note -5, 3
	note -5, 1
	rest 1
	note -5, 2
	note -5, 1
	note -5, 5
	rest 5
	snd_loop 2
	note 0, 3
	note 0, 1
	rest 1
	note 0, 2
	note 0, 1
	note -7, 5
	rest 5
	snd_endloop
	note -2, 3
	note -2, 1
	rest 1
	note -2, 2
	note -2, 1
	note 3, 5
	rest 5
	note 1, 3
	note 1, 1
	rest 1
	note 1, 2
	note 1, 1
	note 1, 5
	rest 5
	note -3, 3
	note -3, 1
	rest 1
	note -3, 2
	note -3, 1
	note -3, 5
	note_x -3, 13
	note_x -3, 16
	note_x -3, 19
	gate 0
	note_x -4, 144
	snd_end
Song34_CH4:
	length_set 9
	pan PAN_LR
	gate 0
	volume 12
	snd_loop 2
	drest_x 144
	snd_endloop
	snd_loop 22
	instrument 28
	drum 9, 3
	drum 9, 1
	drest 1
	drum 9, 2
	drum 9, 1
	drum 9, 5
	instrument 29
	drum 3, 5
	snd_endloop
	instrument 28
	drum 9, 3
	drum 9, 1
	drest 1
	drum 9, 2
	drum 9, 1
	drum 9, 5
	instrument 29
	drum_x 3, 13
	drum_x 3, 16
	drum_x 3, 19
	drum 3, 5
	snd_end
	snd_end  ; unreferenced (stream)
	snd_end  ; unreferenced (stream)
	snd_end  ; unreferenced (stream)
	length_set 1  ; unreferenced (stream)
	pan PAN_LR
	volume 13
	base_note $27
	gate 0
	instrument 1
	note -12, 0
	snd_end
Song35:
	db 3  ; tracks
	track Song35_CH1, CH1
	track Song35_CH2, CH2
	track Song35_CH3, CH3
Song36:
	db 4  ; tracks
	track Song36_CH1, CH1
	track Song36_CH2, CH2
	track Song36_CH3, CH3
	track Song36_CH4, CH4
Song37:
	db 4  ; tracks
	track Song37_CH1, CH1
	track Song37_CH2, CH2
	track Song37_CH3, CH3
	track Song37_CH4, CH4
Song35_CH1:
	length_set 5
	instrument 12
	gate 0
	volume 12
	base_note $29
	pan PAN_LR
	snd_loop 2
	note -3, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note -3, 0
	note -5, 0
	note -6, 0
	note -5, 0
	snd_endloop
	note -3, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note 5, 0
	note 6, 0
	note 7, 0
	note 8, 0
	note 9, 0
	note 10, 0
	note 11, 0
	note 12, 1
	snd_end
Song35_CH2:
	length_set 5
	instrument 12
	volume 10
	gate 0
	base_note $29
	pan PAN_LR
	snd_loop 2
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note 0, 0
	note -1, 0
	note -3, 0
	note -5, 0
	note -7, 0
	note -8, 0
	note -9, 0
	note -8, 0
	snd_endloop
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note 0, 0
	note -1, 0
	note -8, 0
	note -9, 0
	note -8, 0
	note -7, 0
	note -5, 0
	note 0, 0
	note 7, 1
	note 7, 0
	note 6, 0
	note 5, 1
	note 4, 1
	snd_end
Song35_CH3:
	length_set 5
	instrument 2
	gate 180
	pan PAN_LR
	base_note $11
	volume 15
	snd_loop 2
	note 5, 1
	note 12, 2
	note 4, 1
	note 12, 2
	snd_endloop
	note 5, 1
	note 12, 2
	note 7, 1
	note 12, 2
	note 7, 1
	note 11, 2
	note 12, 1
	snd_end
Song36_CH1:
	length_set 3
	instrument 21
	volume 12
	gate 0
	base_note $27
	pan PAN_LR
Seq_6705:
	snd_call Sub_6715
	snd_call Sub_671D
	snd_call Sub_6715
	snd_call Sub_6726
	snd_jump Seq_6705
	snd_end  ; unreferenced (stream)
Sub_6715:
	rest 2
	note 5, 0
	rest 3
	note 0, 1
	rest 1
	note 0, 1
	rest 1
	snd_ret
Sub_671D:
	note 2, 1
	rest 1
	note 2, 2
	note 4, 0
	rest 2
	note 0, 0
	note 2, 2
	note 0, 0
	snd_ret
Sub_6726:
	note 2, 2
	note 2, 0
	rest 2
	note 4, 0
	rest 2
	note 9, 3
	note 7, 0
	rest 2
	note 5, 0
	rest 3
	note 4, 1
	rest 1
	note 2, 1
	rest 1
	note 0, 2
	note -1, 0
	note 0, 2
	note 5, 0
	rest 2
	note -7, 0
	note -5, 2
	note -3, 0
	note -2, 2
	note 0, 0
	rest 2
	note 2, 0
	rest 2
	note 2, 0
	note 4, 2
	note 5, 0
	note 9, 3
	note 7, 2
	note 5, 0
	rest_x 48
	note -5, 2
	note -3, 0
	note -2, 2
	note -8, 0
	rest 2
	note -3, 0
	note -5, 2
	note -7, 0
	rest 2
	note -8, 0
	note -7, 2
	note -10, 0
	rest_x 48
	note -8, 2
	note -7, 0
	note -5, 2
	note -11, 0
	rest 2
	note -10, 0
	note -8, 2
	note -7, 0
	rest 2
	note -8, 0
	note -7, 2
	note -3, 0
	rest 3
	note -10, 3
	note -2, 2
	note 0, 0
	note 2, 2
	note -5, 0
	rest 2
	note 0, 0
	note -2, 2
	note -3, 0
	rest 2
	note -5, 0
	note -3, 2
	note 0, 0
	rest_x 48
	note -1, 2
	note 0, 0
	note 2, 2
	note -5, 0
	rest 2
	note -5, 0
	note -3, 2
	note -1, 0
	note 0, 2
	note 0, 0
	rest 2
	note 0, 0
	rest 2
	note 0, 0
	note 0, 0
	note 2, 0
	note 4, 0
	snd_ret
Song36_CH2:
	length_set 3
	instrument 21
	gate 0
	pan PAN_LR
	base_note $27
	volume 12
Seq_6791:
	snd_call Sub_67A0
	snd_call Sub_67A8
	snd_call Sub_67A0
	snd_call Sub_67B0
	snd_jump Seq_6791
Sub_67A0:
	rest 2
	note -3, 0
	rest 3
	note -7, 1
	rest 1
	note -7, 1
	rest 1
	snd_ret
Sub_67A8:
	note -7, 1
	rest 1
	note -7, 2
	note -5, 0
	rest 3
	note -1, 2
	note -2, 0
	snd_ret
Sub_67B0:
	note -7, 2
	note -7, 0
	rest 2
	note -5, 0
	rest 2
	note 4, 3
	note 1, 0
	rest 2
	note -3, 0
	rest 3
	note -5, 1
	rest 1
	note -7, 1
	rest 1
	note -8, 2
	note -9, 0
	note -8, 2
	note -3, 0
	rest 2
	note -15, 0
	note -14, 2
	note -12, 0
	note -10, 2
	note -10, 0
	rest 2
	note -7, 0
	rest 2
	note -7, 0
	note -7, 2
	note -7, 0
	note 0, 0
	rest 0
	note -1, 0
	note -2, 2
	note -3, 0
	rest_x 48
	note -14, 2
	note -8, 0
	note -10, 2
	note -11, 0
	rest 2
	note -13, 0
	note -11, 2
	note -10, 0
	base_note $1B
	rest 2
	note -3, 0
	note -3, 2
	note -7, 0
	rest_x 48
	note -5, 2
	note -2, 0
	note -2, 2
	note -3, 0
	rest 2
	note -1, 0
	note 1, 2
	note 2, 0
	rest 2
	note 1, 0
	note 2, 2
	note 5, 0
	rest 3
	note -7, 3
	base_note $27
	note -10, 2
	note -5, 0
	note -7, 2
	note -8, 0
	rest 2
	note -10, 0
	note -8, 2
	note -7, 0
	rest 2
	note -8, 0
	note -7, 2
	note -3, 0
	rest_x 48
	note -5, 2
	note -6, 0
	note -7, 2
	note -10, 0
	rest 2
	note -13, 0
	note -12, 2
	note -10, 0
	note -8, 2
	note -1, 0
	rest 2
	note -2, 0
	rest 2
	note -3, 0
	rest 0
	note -1, 0
	note -2, 0
	snd_ret
Song36_CH3:
	length_set 3
	instrument 2
	volume 15
	gate 180
	pan PAN_LR
	base_note $0F
Seq_6821:
	snd_call Sub_6830
	snd_call Sub_683A
	snd_call Sub_6830
	snd_call Sub_683E
	snd_jump Seq_6821
Sub_6830:
	note 5, 3
	rest 2
	note 5, 0
	note 9, 3
	rest 2
	note 9, 0
	note 10, 3
	rest 2
	note 10, 0
	snd_ret
Sub_683A:
	note 12, 3
	rest 2
	note 0, 0
	snd_ret
Sub_683E:
	note 12, 0
	rest 0
	note 13, 3
	note 9, 0
	note 14, 3
	rest 2
	note 14, 0
	note 12, 3
	note 10, 3
	note 9, 3
	rest 2
	note 9, 0
	note 14, 3
	rest 2
	note 14, 0
	note 7, 3
	rest 2
	note 7, 0
	note 11, 3
	rest 2
	note 11, 0
	note 12, 3
	rest 2
	note 12, 0
	base_note $27
	note -7, 2
	note -8, 0
	note -10, 2
	note -12, 0
	note -8, 3
	rest 2
	note -8, 0
	note -15, 3
	rest 2
	note -15, 0
	note -10, 3
	rest 2
	note -10, 0
	note -10, 2
	note -8, 0
	note -7, 2
	note -10, 0
	note -14, 3
	rest 2
	note -14, 0
	note -15, 3
	rest 2
	note -15, 0
	note -10, 3
	rest 2
	note -10, 0
	note -12, 3
	rest 2
	note -12, 0
	base_note $0F
	note 7, 3
	rest 2
	note 7, 0
	note 12, 3
	rest 2
	note 12, 0
	note 5, 3
	rest 2
	note 5, 0
	note 5, 2
	note 7, 0
	note 9, 2
	note 5, 0
	note 7, 3
	rest 2
	note 7, 0
	note 11, 3
	rest 2
	note 11, 0
	note 12, 3
	rest 2
	note 12, 0
	note 12, 2
	note 12, 0
	note 12, 0
	note 12, 0
	note 12, 0
	snd_ret
Song36_CH4:
	length_set 3
	volume 12
	pan PAN_LR
	gate 0
Seq_689B:
	snd_loop 15
	snd_call Sub_68A8
	snd_endloop
	snd_call Sub_68B5
	snd_jump Seq_689B
	snd_end  ; unreferenced (stream)
Sub_68A8:
	instrument 28
	drum 9, 0
	drest 0
	drum 9, 0
	instrument 29
	drum 3, 0
	instrument 28
	drest 0
	drum 9, 0
	snd_ret
Sub_68B5:
	instrument 28
	drum 9, 0
	drest 0
	drum 9, 0
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 0
	snd_ret
	snd_end  ; unreferenced (stream)
Song37_CH1:
	length_set 1
	instrument 34
	gate 180
	pan PAN_R
	base_note $27
	volume 15
Seq_68CD:
	snd_call Sub_68E8
	snd_call Sub_68EE
	snd_call Sub_68E8
	snd_call Sub_68F3
	snd_call Sub_68E8
	snd_call Sub_68EE
	snd_call Sub_68E8
	snd_call Sub_68F8
	snd_jump Seq_68CD
Sub_68E8:
	note 4, 0
	note 4, 1
	note 4, 0
	note -1, 1
	note -1, 1
	snd_ret
Sub_68EE:
	note 9, 1
	note 8, 1
	note 7, 1
	rest 1
	snd_ret
Sub_68F3:
	note 2, 1
	note 3, 1
	note 4, 1
	rest 1
	snd_ret
Sub_68F8:
	note -4, 1
	note -5, 1
	note -6, 1
	rest 1
	snd_ret
	snd_end  ; unreferenced (stream)
Song37_CH2:
	length_set 1
	instrument 34
	volume 15
	pan PAN_L
	gate 180
	base_note $27
Seq_690A:
	snd_call Sub_6925
	snd_call Sub_692C
	snd_call Sub_6925
	snd_call Sub_6931
	snd_call Sub_6925
	snd_call Sub_692C
	snd_call Sub_6925
	snd_call Sub_6936
	snd_jump Seq_690A
Sub_6925:
	note -12, 0
	note -11, 0
	note -11, 0
	note -11, 0
	note -10, 1
	rest 1
	snd_ret
Sub_692C:
	note -2, 1
	note -3, 1
	note -4, 1
	rest 1
	snd_ret
Sub_6931:
	note -4, 1
	note -5, 1
	note -6, 1
	rest 1
	snd_ret
Sub_6936:
	note -6, 1
	note -7, 1
	note -8, 1
	rest 1
	snd_ret
Song37_CH3:
	length_set 1
	pan PAN_LR
	volume 15
	instrument 2
	pan PAN_LR
	gate 180
	base_note $1B
Seq_6949:
	note -3, 3
	note -8, 0
	note -5, 1
	note -8, 1
	note -5, 1
	note -4, 1
	note -3, 1
	rest 1
	snd_jump Seq_6949
Song37_CH4:
	length_set 1
	pan PAN_LR
	volume 12
	gate 0
Seq_695C:
	instrument 28
	drum 9, 1
	drum 9, 0
	drum 9, 0
	instrument 29
	drum 3, 1
	instrument 28
	drum 9, 0
	drum 9, 0
	drum 9, 1
	drum 9, 1
	instrument 29
	drum 3, 1
	drest 1
	snd_jump Seq_695C
	snd_end  ; unreferenced (stream)
Env_6972:
	env_timbre 0
	env_vol 12
	env_end
Sfx06:
	db 2  ; tracks
	track Sfx06_CH1, CH1
	track Sfx06_CH2, CH2
Sfx11:
	db 2  ; tracks
	track Sfx11_CH1, CH1
	track Sfx11_CH2, CH2
Song38:
	db 4  ; tracks
	track Song38_CH1, CH1
	track Song38_CH2, CH2
	track Song38_CH3, CH3
	track Song38_CH4, CH4
Song39:
	db 4  ; tracks
	track Song39_CH1, CH1
	track Song39_CH2, CH2
	track Song39_CH3, CH3
	track Song39_CH4, CH4
Song40:
	db 3  ; tracks
	track Song40_CH1, CH1
	track Song40_CH2, CH2
	track Song40_CH3, CH3
Song41:
	db 3  ; tracks
	track Song41_CH1, CH1
	track Song41_CH2, CH2
	track Song41_CH3, CH3
Song42:
	db 3  ; tracks
	track Song42_CH1, CH1
	track Song42_CH2, CH2
	track Song42_CH3, CH3
Song43:
	db 3  ; tracks
	track Song43_CH1, CH1
	track Song43_CH2, CH2
	track Song43_CH3, CH3
Song44:
	db 4  ; tracks
	track Song44_CH1, CH1
	track Song44_CH2, CH2
	track Song44_CH3, CH3
	track Song44_CH4, CH4
Song45:
	db 4  ; tracks
	track Song45_CH1, CH1
	track Song45_CH2, CH2
	track Song45_CH3, CH3
	track Song45_CH4, CH4
Song46:
	db 4  ; tracks
	track Song46_CH1, CH1
	track Song46_CH2, CH2
	track Song46_CH3, CH3
	track Song46_CH4, CH4
Song47:
	db 4  ; tracks
	track Song47_CH1, CH1
	track Song47_CH2, CH2
	track Song47_CH3, CH3
	track Song47_CH4, CH4
Song48:
	db 3  ; tracks
	track Song48_CH1, CH1
	track Song48_CH2, CH2
	track Song48_CH3, CH3
Song49:
	db 4  ; tracks
	track Song49_CH1, CH1
	track Song49_CH2, CH2
	track Song49_CH3, CH3
	track Song49_CH4, CH4
Song50:
	db 4  ; tracks
	track Song50_CH1, CH1
	track Song50_CH2, CH2
	track Song50_CH3, CH3
	track Song50_CH4, CH4
Song51:
	db 4  ; tracks
	track Song51_CH1, CH1
	track Song51_CH2, CH2
	track Song51_CH3, CH3
	track Song51_CH4, CH4
Song52:
	db 4  ; tracks
	track Song52_CH1, CH1
	track Song52_CH2, CH2
	track Song52_CH3, CH3
	track Song52_CH4, CH4
Song53:
	db 4  ; tracks
	track Song53_CH1, CH1
	track Song53_CH2, CH2
	track Song53_CH3, CH3
	track Song53_CH4, CH4
Song54:
	db 4  ; tracks
	track Song54_CH1, CH1
	track Song54_CH2, CH2
	track Song54_CH3, CH3
	track Song54_CH4, CH4
Song55:
	db 4  ; tracks
	track Song55_CH1, CH1
	track Song55_CH2, CH2
	track Song55_CH3, CH3
	track Song55_CH4, CH4
Sfx06_CH1:
	pan PAN_LR
	base_note $13
	volume 15
	length_set 10
	instrument 2
	gate 0
	note -12, 2
	note -1, 0
	note -10, 0
	note -4, 0
	note 4, 0
	note 8, 0
	note -6, 0
	note 13, 0
	note 7, 0
	note -7, 0
	note -1, 0
	note 4, 0
	note -9, 0
	note -3, 0
	snd_loop 3
	volume 15
	note -11, 0
	note 2, 0
	note 8, 0
	base_note $2B
	volume 7
	note 12, 0
	base_note $13
	snd_endloop
	snd_end
Sfx06_CH2:
	pan PAN_LR
	instrument 35
	length_set 10
	base_note $14
	gate 0
	volume 11
	note -14, 2
	note -10, 0
	note -3, 0
	note -2, 0
	note -4, 0
	note -1, 0
	note 2, 0
	note 5, 0
	note 11, 0
	note 12, 0
	note 5, 0
	note 8, 0
	note 9, 0
	note 15, 0
	instrument 2
	volume 12
	snd_loop 3
	note -1, 0
	note -10, 0
	note 5, 0
	note 12, 0
	snd_endloop
	snd_end
Sfx11_CH1:
	pan PAN_LR
	base_note $2C
	instrument 41
	gate 0
	length_set 10
	volume 15
	note -15, 2
	note -11, 2
	note -10, 1
	note -8, 2
	note -3, 2
	note 1, 2
	note 2, 1
	note 4, 2
	note 9, 1
	volume 14
	snd_loop 4
	note 13, 1
	note 9, 1
	snd_endloop
	snd_end
Sfx11_CH2:
	pan PAN_LR
	instrument 41
	gate 0
	base_note $35
	length_set 10
	volume 15
	note -12, 2
	note -8, 2
	note -7, 1
	note -5, 2
	note 0, 2
	note 4, 2
	note 5, 1
	note 7, 2
	note 12, 1
	note 12, 3
	note 12, 3
	note 12, 3
	note 12, 3
	snd_end
Song38_CH1:
	instrument 47
	length_set 11
	pan PAN_LR
	gate 220
	volume 10
	base_note $28
	snd_call Sub_6B00
	snd_call Sub_6B10
	snd_call Sub_6B00
	snd_call Sub_6B1A
	snd_jump Song38_CH1
Sub_6B00:
	note -5, 0
	rest 0
	note 4, 0
	note 0, 0
	rest 0
	note -5, 0
	note -3, 0
	rest 0
	note 5, 0
	note 0, 0
	rest 0
	note -3, 0
	note -1, 0
	rest 0
	note 7, 0
	snd_ret
Sub_6B10:
	note 2, 0
	rest 0
	note -1, 0
	note -3, 0
	rest 0
	note 5, 0
	note 5, 0
	note 4, 0
	note 2, 0
	snd_ret
Sub_6B1A:
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	rest 0
	note -5, 0
	note -12, 2
	snd_ret
Song38_CH2:
	instrument 36
	length_set 11
	gate 0
	volume 10
	base_note $34
	snd_call Sub_6B32
	snd_jump Song38_CH2
Sub_6B32:
	pan PAN_L
	rest 1
	note 0, 0
	note 12, 0
	note 0, 0
	note 12, 0
	pan PAN_R
	rest 1
	note 0, 0
	note 12, 0
	note 0, 0
	note 12, 0
	snd_ret
Song38_CH3:
	instrument 2
	pan PAN_LR
	length_set 11
	gate 200
	base_note $10
	volume 15
	snd_loop 14
	snd_call Sub_6B59
	snd_endloop
	snd_call Sub_6B5D
	snd_jump Song38_CH3
Sub_6B59:
	note 0, 0
	rest 0
	note 12, 0
	snd_ret
Sub_6B5D:
	note 12, 0
	rest 0
	note 7, 0
	note 12, 2
	snd_ret
Song38_CH4:
	pan PAN_LR
	length_set 11
	gate 0
	volume 10
	snd_loop 7
	snd_call Sub_6B76
	snd_endloop
	snd_call Sub_6B87
	snd_jump Song38_CH4
Sub_6B76:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 1, 0
	drum 1, 0
	snd_ret
Sub_6B87:
	instrument 28
	drum 11, 0
	instrument 5
	drum 1, 0
	instrument 28
	drum 11, 0
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 0
	snd_ret
Song39_CH1:
	volume 10
Seq_6B98:
	instrument 47
	base_note $1B
Seq_6B9C:
	length_set 11
	pan PAN_LR
	gate 200
Seq_6BA2:
	snd_call Sub_6BBA
	snd_call Sub_6BC0
	snd_call Sub_6BBA
	snd_call Sub_6BC8
	snd_call Sub_6BBA
	snd_call Sub_6BC0
	snd_call Sub_6BCE
	snd_jump Seq_6BA2
Sub_6BBA:
	note -5, 0
	rest 0
	note -1, 0
	note 2, 0
	note -1, 0
	snd_ret
Sub_6BC0:
	note 2, 0
	note 4, 0
	rest 0
	note 0, 0
	note -3, 0
	rest 0
	note -6, 0
	snd_ret
Sub_6BC8:
	note 7, 0
	note 4, 0
	rest 0
	note 0, 0
	note -3, 2
	snd_ret
Sub_6BCE:
	note -5, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note 6, 0
	note 7, 0
	rest 0
	note 11, 0
	note 7, 2
	snd_ret
Song39_CH2:
	volume 6
	rest_x 6
	snd_jump Seq_6B98
Song39_CH3:
	instrument 2
	volume 15
	base_note $1B
	snd_jump Seq_6B9C
Song39_CH4:
	length_set 11
	gate 0
	pan PAN_LR
	volume 10
Seq_6BF1:
	snd_call Sub_6BF7
	snd_jump Seq_6BF1
Sub_6BF7:
	instrument 28
	drum 11, 1
	drum 11, 0
	instrument 29
	drum 3, 2
	instrument 28
	drum 11, 1
	drum 11, 0
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 0
	snd_ret
Song40_CH1:
	length_set 12
	instrument 37
	pan PAN_LR
	gate 200
	base_note $27
	volume 10
Seq_6C14:
	snd_call Sub_6C29
	snd_call Sub_6C48
	snd_call Sub_6C50
	snd_call Sub_6C55
	snd_call Sub_6C48
	snd_call Sub_6C64
	snd_jump Seq_6C14
Sub_6C29:
	note 9, 5
	note 7, 0
	note 5, 0
	note 4, 2
	note 2, 4
	note 12, 4
	note 10, 0
	note 9, 0
	note 10, 0
	note 9, 2
	note 7, 1
	note 0, 0
	note -1, 0
	note 0, 0
	note 2, 1
	note 2, 1
	note 4, 1
	note 4, 1
	note 5, 0
	note 7, 0
	rest 0
	note 9, 0
	rest 0
	note 9, 0
	note 10, 0
	note 12, 0
	note 14, 2
	note 7, 2
	note 5, 4
	note 4, 4
	snd_ret
Sub_6C48:
	note 2, 0
	note 4, 0
	note 5, 0
	note 7, 1
	note 5, 0
	note 4, 0
	note 2, 0
	snd_ret
Sub_6C50:
	note 0, 0
	note 0, 0
	note 5, 0
	note 0, 4
	snd_ret
Sub_6C55:
	note -2, 0
	note -3, 0
	note -2, 0
	note 4, 1
	note 2, 0
	note 0, 0
	note -2, 0
	note -3, 0
	note -4, 0
	note -3, 0
	note 0, 1
	note -7, 0
	note -8, 0
	note -7, 0
	snd_ret
Sub_6C64:
	note 0, 0
	note 5, 0
	note 9, 0
	note 12, 4
	note 11, 0
	note 7, 0
	note 8, 0
	note 9, 1
	note 7, 0
	note 5, 0
	note 2, 0
	note 4, 0
	note 2, 0
	note 4, 0
	note 0, 1
	note 12, 0
	note 12, 0
	rest 0
	snd_ret
Song40_CH2:
	length_set 12
	instrument 36
	volume 9
	pan PAN_LR
	gate 0
	base_note $27
Seq_6C83:
	snd_call Sub_6CB0
	snd_call Sub_6CBC
	snd_call Sub_6CC8
	snd_call Sub_6CD4
	snd_call Sub_6CE0
	snd_call Sub_6CC8
	snd_call Sub_6CD4
	snd_call Sub_6CF3
	snd_call Sub_6CB0
	snd_call Sub_6CFF
	snd_call Sub_6CF3
	snd_call Sub_6CB0
	snd_call Sub_6D19
	snd_call Sub_6CD4
	snd_jump Seq_6C83
Sub_6CB0:
	rest 0
	note_x -7, 6
	note_x -3, 6
	note 0, 0
	note -3, 0
	note 5, 0
	note 0, 0
	note -3, 0
	note -7, 0
	snd_ret
Sub_6CBC:
	rest 0
	note_x -10, 6
	note_x -7, 6
	note -3, 0
	note -7, 0
	note 2, 0
	note -3, 0
	note -7, 0
	note -10, 0
	snd_ret
Sub_6CC8:
	rest 0
	note_x -5, 6
	note_x -2, 6
	note 2, 0
	note -2, 0
	note 7, 0
	note 2, 0
	note -2, 0
	note -5, 0
	snd_ret
Sub_6CD4:
	rest 0
	note_x -8, 6
	note_x -5, 6
	note -2, 0
	note -5, 0
	note 0, 0
	note -2, 0
	note -5, 0
	note -8, 0
	snd_ret
Sub_6CE0:
	rest 0
	note_x -14, 6
	note_x -10, 6
	note -7, 0
	note -10, 0
	rest 0
	note_x -15, 6
	note_x -11, 6
	note -8, 0
	note -11, 0
	note -3, 0
	note -3, 0
	rest 0
	note 2, 4
	snd_ret
Sub_6CF3:
	rest 0
	note_x -7, 6
	note_x -2, 6
	note 2, 0
	note -2, 0
	note 5, 0
	note 2, 0
	note -2, 0
	note -7, 0
	snd_ret
Sub_6CFF:
	rest 0
	note_x -8, 6
	note_x -5, 6
	note -2, 0
	note -5, 0
	note 0, 0
	note -2, 0
	note -5, 0
	note -8, 0
	rest 0
	note_x -7, 6
	note_x -3, 6
	note 0, 0
	note -3, 0
	rest 0
	note_x -9, 6
	note_x -3, 6
	note 0, 0
	note -3, 0
	snd_ret
Sub_6D19:
	rest 0
	note_x -7, 6
	note_x -5, 6
	note -1, 0
	note -5, 0
	note 2, 0
	note -1, 0
	note -5, 0
	note -7, 0
	snd_ret
Song40_CH3:
	instrument 2
	length_set 12
	gate 100
	volume 15
	pan PAN_LR
	base_note $1B
Seq_6D31:
	snd_call Sub_6D43
	snd_call Sub_6D61
	snd_call Sub_6D68
	snd_call Sub_6D61
	snd_call Sub_6D6F
	snd_jump Seq_6D31
Sub_6D43:
	note -7, 2
	note -3, 2
	note 0, 1
	note -10, 2
	note -7, 2
	note -3, 1
	note -5, 2
	note -2, 2
	note 2, 1
	note -12, 2
	note -8, 2
	note -5, 1
	note -2, 2
	note -3, 2
	note -15, 1
	gate 200
	note 2, 0
	note 0, 0
	rest 0
	note -1, 4
	gate 100
	note -5, 2
	note -2, 2
	note 2, 1
	note -12, 2
	note -8, 2
	note -5, 1
	snd_ret
Sub_6D61:
	note -2, 2
	note 2, 2
	note 5, 1
	note -3, 2
	note 0, 2
	note 5, 1
	snd_ret
Sub_6D68:
	note -5, 2
	note -2, 2
	note 0, 1
	note -7, 2
	note -9, 2
	note -12, 1
	snd_ret
Sub_6D6F:
	note -5, 2
	note -1, 2
	note 5, 1
	note 0, 2
	note 4, 2
	note 7, 1
	snd_ret
Song41_CH1:
	instrument 50
	length_set 13
	pan PAN_LR
	volume 11
	gate 170
	base_note $27
Seq_6D82:
	snd_call Sub_6D94
	snd_call Sub_6D96
	snd_call Sub_6D9A
	snd_call Sub_6D96
	snd_call Sub_6DA4
	snd_jump Seq_6D82
Sub_6D94:
	note 2, 1
	snd_ret
Sub_6D96:
	note 7, 1
	note 2, 1
	note 5, 1
	snd_ret
Sub_6D9A:
	note 5, 1
	note 4, 3
	note 9, 1
	note 4, 1
	note 7, 1
	note 7, 1
	note 6, 0
	note 4, 0
	note 2, 1
	snd_ret
Sub_6DA4:
	note 4, 1
	note 9, 1
	note 7, 1
	note 6, 2
	note 2, 0
	note 4, 0
	note 6, 0
	note 7, 3
	snd_ret
Song41_CH2:
	length_set 13
	volume 10
	instrument 50
	pan PAN_LR
	gate 170
	base_note $27
Seq_6DB9:
	snd_call Sub_6DCB
	snd_call Sub_6DCD
	snd_call Sub_6DD1
	snd_call Sub_6DCD
	snd_call Sub_6DDB
	snd_jump Seq_6DB9
Sub_6DCB:
	note 0, 1
	snd_ret
Sub_6DCD:
	note -1, 1
	note -5, 1
	note -1, 1
	snd_ret
Sub_6DD1:
	note 0, 1
	note -5, 1
	note 0, 1
	note 1, 1
	note -3, 1
	note 1, 1
	note 2, 1
	note 0, 1
	note 0, 1
	snd_ret
Sub_6DDB:
	note 0, 1
	note 1, 1
	note 1, 1
	note 2, 1
	note 0, 1
	note -3, 1
	note -5, 1
	note -5, 1
	snd_ret
Song41_CH3:
	instrument 2
	length_set 13
	gate 100
	pan PAN_LR
	base_note $1B
	volume 15
Seq_6DF0:
	snd_call Sub_6E02
	snd_call Sub_6E04
	snd_call Sub_6E09
	snd_call Sub_6E04
	snd_call Sub_6E12
	snd_jump Seq_6DF0
Sub_6E02:
	note -10, 1
	snd_ret
Sub_6E04:
	note -5, 1
	note 7, 1
	note 7, 1
	note 0, 1
	snd_ret
Sub_6E09:
	note 12, 1
	note 12, 1
	note -3, 1
	note 9, 1
	note 9, 1
	note 2, 1
	note 14, 1
	note 14, 1
	snd_ret
Sub_6E12:
	note -3, 1
	note 9, 1
	note 2, 1
	note 14, 1
	note 14, 1
	note -5, 1
	note 7, 1
	snd_ret
Song42_CH1:
	pan PAN_LR
	volume 12
	length_set 11
	instrument 40
	gate 0
	base_note $28
Seq_6E26:
	snd_loop 2
	snd_call Sub_6E4D
	snd_endloop
	snd_loop 2
	snd_call Sub_6E55
	snd_endloop
	snd_loop 4
	snd_call Sub_6E5B
	snd_endloop
Seq_6E38:
	snd_call Sub_6E5B
	snd_call Sub_6E60
	snd_call Sub_6E73
	snd_call Sub_6E5B
	snd_call Sub_6E60
	snd_call Sub_6E83
	snd_jump Seq_6E38
Sub_6E4D:
	note_x 6, 1
	note_x 7, 15
	rest 1
	note -5, 1
	rest 1
	snd_ret
Sub_6E55:
	note_x 6, 1
	note_x 7, 15
	note -5, 1
	snd_ret
Sub_6E5B:
	note_x 6, 1
	note_x 7, 15
	snd_ret
Sub_6E60:
	note 4, 3
	note 7, 1
	note 4, 1
	note 0, 5
	note_x 8, 1
	note_x 9, 15
	note 5, 3
	note 9, 1
	note 5, 1
	note 2, 3
	note 9, 1
	note_x 10, 1
	note_x 11, 15
	note 9, 3
	snd_ret
Sub_6E73:
	note 7, 1
	note 5, 1
	note 4, 3
	note 2, 1
	note 4, 1
	note 7, 3
	note 4, 1
	note 2, 1
	snd_loop 3
	note_x -6, 1
	note_x -5, 15
	snd_endloop
	snd_ret
Sub_6E83:
	note 11, 1
	note 12, 1
	note 14, 3
	note 11, 1
	note 12, 1
	note 11, 3
	note 14, 1
	note 12, 1
	note_x 6, 1
	note_x 7, 15
	note_x -1, 1
	note_x 0, 15
	rest 1
	snd_ret
Song42_CH2:
	length_set 11
	gate 0
	instrument 37
	pan PAN_LR
	volume 9
	base_note $28
	rest_x 7
	snd_jump Seq_6E26
Song42_CH3:
	instrument 2
	length_set 11
	gate 150
	pan PAN_LR
	volume 15
	base_note $1C
	snd_call Sub_6EE8
Seq_6EB5:
	snd_loop 2
	snd_call Sub_6EF5
	snd_endloop
	snd_loop 2
	snd_call Sub_6EFA
	snd_endloop
	snd_loop 2
	snd_call Sub_6EFF
	snd_endloop
	snd_call Sub_6EF5
	snd_call Sub_6EFF
	snd_loop 2
	snd_call Sub_6EF5
	snd_endloop
	snd_loop 2
	snd_call Sub_6EFA
	snd_endloop
	snd_loop 2
	snd_call Sub_6EFF
	snd_endloop
	snd_call Sub_6EF5
	snd_call Sub_6F04
	snd_jump Seq_6EB5
Sub_6EE8:
	snd_loop 2
	note 7, 1
	rest 1
	note -5, 3
	snd_endloop
	snd_loop 6
	note -5, 1
	snd_endloop
	note -3, 1
	note -1, 1
	snd_ret
Sub_6EF5:
	note 0, 1
	note 7, 1
	note -5, 1
	note 7, 1
	snd_ret
Sub_6EFA:
	note 2, 1
	note 9, 1
	note -3, 1
	note 9, 1
	snd_ret
Sub_6EFF:
	note 2, 1
	note 7, 1
	note -5, 1
	note 7, 1
	snd_ret
Sub_6F04:
	note 0, 1
	note 7, 1
	note 0, 1
	rest 1
	snd_ret
	snd_end  ; unreferenced (stream)
Song43_CH1:
	length_set 14
	instrument 45
	volume 15
	gate 0
	base_note $2F
	pan PAN_LR
	note 0, 0
	rest 0
	note -5, 0
	note 0, 0
	note 1, 2
	rest 1
	note -4, 0
	note 1, 0
	note 3, 3
	note 1, 3
	note 3, 3
	note 4, 4
	snd_end
Song43_CH2:
	length_set 14
	instrument 45
	volume 15
	pan PAN_LR
	gate 0
	base_note $2F
	note -8, 0
	rest 0
	note -12, 0
	note -8, 0
	note -7, 2
	rest 1
	note -11, 0
	note -7, 0
	note -5, 3
	note -7, 3
	note -5, 3
	note -5, 4
	snd_end
Song43_CH3:
	length_set 14
	instrument 2
	gate 0
	base_note $17
	volume 15
	pan PAN_LR
	note 7, 0
	rest 0
	note 4, 0
	note 7, 0
	note 8, 2
	rest 1
	note 5, 0
	note 8, 0
	note 10, 3
	note 8, 3
	note 10, 3
	note 12, 4
	snd_end
Song44_CH1:
	length_set 13
	instrument 46
	gate 0
	pan PAN_LR
	volume 10
	base_note $2B
Seq_6F61:
	snd_call Sub_6F70
	snd_call Sub_6F79
	snd_call Sub_6F70
	snd_call Sub_6F8C
	snd_jump Seq_6F61
Sub_6F70:
	note -2, 1
	note -2, 0
	note -1, 0
	note 1, 1
	note -6, 1
	note 3, 0
	note 5, 0
	note 6, 0
	snd_ret
Sub_6F79:
	note 3, 0
	note 1, 3
	note -1, 0
	note 1, 0
	note 3, 0
	note -1, 0
	note -2, 0
	note -1, 0
	note 1, 0
	note -2, 0
	note -4, 0
	note -2, 0
	note 0, 0
	note 3, 0
	note 1, 0
	note -1, 0
	note -2, 0
	note -4, 0
	snd_ret
Sub_6F8C:
	note 8, 0
	note 10, 3
	note 11, 0
	note 10, 0
	note 8, 0
	note 10, 0
	note 8, 0
	note 6, 0
	note 5, 0
	note 3, 0
	note 5, 0
	note 6, 0
	note 8, 0
	note 5, 0
	note 6, 3
	snd_ret
Song44_CH2:
	length_set 13
	volume 10
	instrument 46
	gate 0
	base_note $2B
Seq_6FA6:
	snd_call Sub_6FB5
	snd_call Sub_6FC2
	snd_call Sub_6FB7
	snd_call Sub_6FD6
	snd_jump Seq_6FA6
Sub_6FB5:
	pan PAN_L
Sub_6FB7:
	note -6, 0
	note -14, 0
	note -11, 0
	note -4, 0
	note -2, 1
	note -14, 1
	note -1, 0
	note 1, 0
	note 3, 0
	note -1, 0
	snd_ret
Sub_6FC2:
	note -2, 3
	note -9, 0
	note -9, 0
	note -7, 0
	note -7, 0
	note -11, 0
	note -11, 0
	note -6, 0
	note -6, 0
	note -7, 0
	note -6, 0
	note -7, 0
	note -9, 0
	note -7, 0
	note -9, 0
	note -11, 0
	note -13, 0
	pan PAN_R
	snd_ret
Sub_6FD6:
	note 2, 3
	note 3, 1
	note 3, 1
	note 0, 1
	note 0, 1
	note 1, 0
	note 1, 0
	note 1, 0
	note -1, 0
	note -2, 3
	snd_ret
Song44_CH3:
	length_set 13
	instrument 2
	pan PAN_LR
	volume 15
	gate 100
	base_note $1F
Seq_6FED:
	snd_loop 4
	snd_call Sub_7002
	snd_endloop
	snd_call Sub_7005
	snd_loop 2
	snd_call Sub_7002
	snd_endloop
	snd_call Sub_700E
	snd_jump Seq_6FED
Sub_7002:
	note -6, 1
	note 6, 1
	snd_ret
Sub_7005:
	note -4, 1
	note -7, 1
	note -6, 1
	note -9, 1
	note -4, 1
	note 8, 1
	note -11, 1
	note 1, 1
	snd_ret
Sub_700E:
	note -6, 1
	note -9, 1
	note -10, 1
	note -2, 1
	note -4, 1
	note 8, 1
	note -4, 1
	note 8, 1
	note -11, 1
	note 1, 1
	note -6, 1
	note 6, 1
	snd_ret
Song44_CH4:
	length_set 13
	gate 0
	volume 10
	pan PAN_LR
Seq_7023:
	snd_call Sub_7029
	snd_jump Seq_7023
Sub_7029:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	snd_ret
Song45_CH1:
	length_set 11
	instrument 49
	pan PAN_LR
	gate 200
	volume 10
	base_note $2A
Seq_7042:
	snd_call Sub_705D
	snd_call Sub_7078
	snd_call Sub_705D
	snd_call Sub_7087
	snd_call Sub_7094
	snd_call Sub_709F
	snd_call Sub_7094
	snd_call Sub_70AC
	snd_jump Seq_7042
Sub_705D:
	note -1, 0
	note -1, 0
	note -1, 0
	note -3, 0
	rest 0
	note -5, 0
	note -6, 2
	note -8, 2
	note 0, 0
	note 0, 0
	note 0, 0
	note -1, 0
	rest 0
	note -3, 0
	note -3, 2
	note -5, 2
	note 2, 0
	note -1, 0
	note 2, 0
	note 7, 0
	rest 0
	note 5, 0
	note 4, 0
	note 0, 0
	note 4, 0
	note 9, 0
	snd_ret
Sub_7078:
	rest 0
	note 7, 0
	note 6, 0
	note 7, 0
	note 6, 0
	note 4, 0
	note 6, 0
	note 4, 0
	note 2, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note 2, 0
	note 0, 0
	snd_ret
Sub_7087:
	note 11, 0
	note 12, 0
	note 6, 0
	note 2, 0
	note 6, 0
	note 9, 0
	note 11, 0
	note 9, 0
	note 7, 0
	rest 0
	note 6, 0
	note 7, 2
	snd_ret
Sub_7094:
	note 4, 0
	note 4, 0
	note 4, 0
	note 4, 0
	note 6, 0
	note 7, 0
	note 2, 0
	rest 0
	note 4, 0
	note 2, 2
	snd_ret
Sub_709F:
	note 0, 0
	note 0, 0
	note 0, 0
	note 0, 0
	note 2, 0
	note 0, 0
	note -1, 0
	rest 0
	note -3, 0
	note -1, 0
	rest 0
	note -5, 0
	snd_ret
Sub_70AC:
	note 1, 0
	note 2, 0
	note 4, 0
	note 6, 0
	note 7, 0
	note 4, 0
	note 2, 0
	rest 0
	note 1, 0
	note 2, 0
	rest 0
	note 0, 0
	snd_ret
Song45_CH2:
	instrument 48
	length_set 11
	gate 200
	volume 10
	pan PAN_LR
	base_note $1E
Seq_70C5:
	snd_call Sub_70CB
	snd_jump Seq_70C5
Sub_70CB:
	note 7, 0
	note 7, 0
	note 7, 0
	note 2, 0
	rest 0
	note -1, 0
	note 0, 2
	note 0, 2
	note 6, 0
	note 6, 0
	note 6, 0
	note 2, 0
	rest 0
	note 0, 0
	note 0, 2
	note -1, 2
	note 11, 0
	note 7, 0
	note 11, 0
	note 11, 0
	rest 0
	note 11, 0
	note 12, 0
	note 7, 0
	note 12, 0
	note 13, 0
	rest 0
	note 13, 0
	snd_loop 9
	note 9, 0
	snd_endloop
	note 6, 0
	note 6, 0
	note 6, 0
	note 7, 0
	note 2, 0
	note 7, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note 4, 0
	note 0, 0
	note 4, 0
	note -5, 0
	note 0, 0
	note 4, 0
	note 9, 0
	note 6, 0
	note 9, 0
	note 2, 0
	note 4, 0
	note 6, 0
	note 4, 0
	note -1, 0
	note 4, 0
	note -5, 0
	note -1, 0
	note 4, 0
	note -1, 0
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note 2, 0
	note 0, 0
	note -5, 0
	note 0, 0
	note 1, 0
	note 4, 0
	note 7, 0
	note 14, 0
	note 13, 0
	note 12, 0
	note 12, 0
	note 14, 0
	note 12, 0
	note 11, 0
	rest 0
	note 9, 0
	note 11, 2
	note 12, 0
	note 12, 0
	note 12, 0
	note 12, 0
	note 14, 0
	note 12, 0
	note 11, 0
	rest 0
	note 9, 0
	note 11, 2
	note 9, 0
	note 9, 0
	note 9, 0
	note 6, 0
	note 6, 0
	note 9, 0
	note 7, 0
	rest 0
	note 6, 0
	note 7, 2
	note 7, 0
	note 7, 0
	note 7, 0
	note 7, 0
	note 12, 0
	note 7, 0
	note 11, 0
	rest 0
	note 12, 0
	note 11, 2
	note 9, 0
	note 8, 0
	note 7, 0
	note 9, 0
	note 11, 0
	note 7, 0
	note 6, 0
	rest 0
	note 4, 0
	note 6, 0
	rest 0
	note 9, 0
	snd_ret
Song45_CH3:
	length_set 11
	instrument 2
	gate 100
	pan PAN_LR
	volume 15
	base_note $1E
Seq_7153:
	snd_call Sub_716E
	snd_call Sub_7174
	snd_call Sub_716E
	snd_call Sub_7180
	snd_call Sub_718C
	snd_call Sub_7192
	snd_call Sub_718C
	snd_call Sub_7196
	snd_jump Seq_7153
Sub_716E:
	note -5, 2
	note -5, 2
	note -12, 2
	note -12, 2
	note -10, 2
	snd_ret
Sub_7174:
	note -10, 2
	note -5, 2
	note -5, 2
	note -13, 2
	note -13, 2
	note -12, 2
	note -11, 2
	note -10, 2
	note -11, 2
	note -12, 2
	note -15, 2
	snd_ret
Sub_7180:
	note -9, 2
	note -8, 2
	note -8, 2
	note -13, 2
	note -13, 2
	note -12, 2
	note -11, 2
	note -10, 2
	note -10, 2
	note -5, 2
	note -5, 2
	snd_ret
Sub_718C:
	note -12, 2
	note -12, 2
	note -13, 2
	note -13, 2
	note -15, 2
	snd_ret
Sub_7192:
	note -10, 2
	note -5, 2
	note -7, 2
	snd_ret
Sub_7196:
	note -15, 2
	note -10, 2
	note -10, 2
	snd_ret
Song45_CH4:
	length_set 11
	volume 10
	gate 0
	pan PAN_LR
Seq_71A2:
	snd_call Sub_71A8
	snd_jump Seq_71A2
Sub_71A8:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 28
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	drum 2, 0
	snd_ret
Song46_CH1:
	length_set 11
	pan PAN_LR
	volume 10
	gate 150
	instrument 49
	base_note $27
Seq_71C5:
	snd_call Sub_71E0
	snd_call Sub_71EC
	snd_call Sub_71E0
	snd_call Sub_71FA
	snd_call Sub_720A
	snd_call Sub_7218
	snd_call Sub_720A
	snd_call Sub_7225
	snd_jump Seq_71C5
Sub_71E0:
	note -2, 2
	rest 1
	note -7, 0
	note -2, 1
	note -7, 0
	note -2, 1
	note 2, 0
	note 3, 1
	note 2, 0
	note 0, 1
	note -1, 0
	snd_ret
Sub_71EC:
	note 0, 5
	snd_loop 2
	note -3, 1
	note 5, 0
	note 5, 2
	snd_endloop
	note 2, 1
	note 3, 0
	note 2, 1
	note 0, 0
	note -2, 2
	note -7, 2
	snd_ret
Sub_71FA:
	note 0, 2
	note -2, 2
	note -3, 1
	note 0, 0
	note 5, 1
	note 9, 0
	note 7, 1
	note 5, 0
	note 4, 1
	note 7, 0
	note 5, 1
	note 4, 0
	note 5, 1
	note 4, 0
	note 5, 5
	snd_ret
Sub_720A:
	note 6, 1
	note 5, 0
	note 3, 1
	note 1, 0
	note 0, 1
	note 10, 0
	note 8, 1
	note 6, 0
	note 5, 1
	note 3, 0
	note 5, 1
	note 1, 0
	note -4, 5
	snd_ret
Sub_7218:
	note 3, 1
	note 1, 0
	note 0, 1
	note -2, 0
	note -3, 1
	note 6, 0
	note 5, 1
	note 3, 0
	note 1, 2
	note 0, 2
	note 1, 2
	note 5, 2
	snd_ret
Sub_7225:
	note 3, 1
	note 1, 0
	note 3, 2
	note 4, 1
	note 2, 0
	note 4, 2
	note 5, 0
	note 4, 0
	note 5, 0
	note 7, 0
	note 5, 0
	note 4, 0
	note 5, 2
	note -7, 0
	note -5, 0
	note -3, 0
	snd_ret
Song46_CH2:
	instrument 49
	length_set 11
	pan PAN_LR
	volume 10
	gate 150
	base_note $27
Seq_7242:
	snd_call Sub_725D
	snd_call Sub_7269
	snd_call Sub_725D
	snd_call Sub_7277
	snd_call Sub_7287
	snd_call Sub_7293
	snd_call Sub_7287
	snd_call Sub_729E
	snd_jump Seq_7242
Sub_725D:
	note -10, 2
	rest 1
	note -9, 0
	note -10, 1
	note -9, 0
	note -10, 1
	note -7, 0
	note -5, 1
	note -7, 0
	note -9, 1
	note -10, 0
	snd_ret
Sub_7269:
	note -9, 5
	snd_loop 2
	note -9, 1
	note 3, 0
	note 3, 2
	snd_endloop
	note -2, 1
	note 0, 0
	note -2, 1
	note -7, 0
	note -10, 2
	note -9, 2
	snd_ret
Sub_7277:
	note -9, 2
	note -8, 2
	note -12, 1
	note -7, 0
	note -3, 1
	note 0, 0
	note 4, 1
	note 0, 0
	note -2, 1
	note -2, 0
	note -3, 1
	note -2, 0
	note -3, 1
	note -2, 0
	note -3, 5
	snd_ret
Sub_7287:
	note 3, 1
	note 1, 0
	note 0, 1
	note -2, 0
	note -4, 2
	note 0, 2
	note 1, 1
	note 0, 0
	note 1, 1
	note -4, 0
	note -7, 5
	snd_ret
Sub_7293:
	note 0, 1
	note -2, 0
	note -3, 1
	note -5, 0
	note -7, 2
	note -3, 2
	note -2, 2
	note -2, 2
	note -4, 2
	note -4, 2
	snd_ret
Sub_729E:
	snd_loop 2
	note 0, 1
	note -2, 0
	note 0, 2
	snd_endloop
	note -3, 0
	note -5, 0
	note -3, 0
	note -2, 0
	note -3, 0
	note -5, 0
	note -3, 2
	rest 0
	note -8, 0
	note -9, 0
	snd_ret
Song46_CH3:
	length_set 11
	instrument 2
	pan PAN_LR
	volume 15
	gate 150
	base_note $1B
Seq_72BB:
	snd_call Sub_72D6
	snd_call Sub_72EA
	snd_call Sub_72D6
	snd_call Sub_72F8
	snd_call Sub_7306
	snd_call Sub_7318
	snd_call Sub_7306
	snd_call Sub_7325
	snd_jump Seq_72BB
Sub_72D6:
	note -2, 2
	note -2, 1
	note 5, 0
	note 10, 1
	note 5, 0
	note 2, 1
	note -2, 0
	note 12, 0
	rest 0
	note 12, 0
	note 7, 0
	note 3, 0
	note 7, 0
	note 0, 2
	note 0, 2
	note 5, 2
	note 5, 0
	note 0, 0
	note 5, 0
	snd_ret
Sub_72EA:
	note -7, 1
	note -7, 0
	note -5, 1
	note -3, 0
	note -2, 1
	note -2, 0
	note 5, 0
	note 2, 0
	note 5, 0
	note -2, 1
	note -7, 0
	note -5, 1
	note -3, 0
	snd_ret
Sub_72F8:
	note 0, 2
	note 0, 0
	note 2, 0
	note 4, 0
	snd_loop 2
	note 5, 1
	note 0, 0
	snd_endloop
	note 5, 1
	note 0, 0
	note 0, 1
	note 0, 0
	snd_ret
Sub_7306:
	note 3, 2
	note 3, 0
	note -2, 0
	note 3, 0
	note -4, 1
	note -4, 0
	note -2, 1
	note 0, 0
	note 1, 2
	note 1, 0
	note 1, 0
	note 1, 0
	note 1, 1
	note -4, 0
	note 1, 0
	note -4, 0
	note 8, 0
	snd_ret
Sub_7318:
	note 0, 2
	note 0, 0
	note -5, 0
	note 0, 0
	note -7, 1
	note -7, 0
	note -5, 1
	note -3, 0
	note -2, 2
	note -2, 2
	note -4, 2
	note -4, 2
	snd_ret
Sub_7325:
	snd_loop 2
	note 0, 1
	note -5, 0
	note 0, 2
	snd_endloop
	note 5, 1
	note 5, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note 5, 1
	note -7, 0
	note -5, 1
	note -3, 0
	snd_ret
Song46_CH4:
	length_set 11
	pan PAN_LR
	gate 0
	volume 10
Seq_733D:
	snd_call Sub_7343
	snd_jump Seq_733D
Sub_7343:
	instrument 28
	drum 10, 2
	instrument 29
	drum 3, 2
	snd_ret
Song47_CH1:
	length_set 12
	instrument 46
	pan PAN_LR
	gate 0
	volume 11
	base_note $26
Seq_7356:
	snd_call Sub_7386
	snd_call Sub_7390
	snd_call Sub_7386
	snd_call Sub_7392
	snd_loop 2
	snd_call Sub_7397
	snd_call Sub_73A0
	snd_endloop
	snd_call Sub_7386
	snd_call Sub_7390
	snd_call Sub_7386
	snd_call Sub_7392
	snd_call Sub_7397
	snd_call Sub_73A0
	snd_call Sub_7397
	snd_call Sub_73A7
	snd_jump Seq_7356
Sub_7386:
	rest 1
	note 11, 0
	rest 0
	note 6, 0
	rest 2
	note 3, 0
	rest 0
	note 1, 0
	note -1, 0
	snd_ret
Sub_7390:
	rest 3
	snd_ret
Sub_7392:
	rest 0
	note 11, 0
	note 11, 0
	note 11, 0
	snd_ret
Sub_7397:
	note 11, 0
	rest 0
	note 14, 0
	rest 0
	note 11, 0
	note 6, 0
	note 7, 0
	note 8, 0
	snd_ret
Sub_73A0:
	rest 0
	note 11, 0
	note 14, 0
	rest 0
	note 11, 0
	rest 2
	snd_ret
Sub_73A7:
	rest 0
	note 10, 0
	note 10, 0
	note 10, 0
	note 10, 0
	note 6, 0
	note 8, 0
	note 6, 0
	snd_ret
Song47_CH2:
	length_set 12
	gate 0
	volume 12
	instrument 5
	base_note $32
Seq_73BA:
	snd_call Sub_73E1
	snd_call Sub_73EC
	snd_call Sub_73E1
	snd_call Sub_73F7
	snd_loop 2
	snd_call Sub_7402
	snd_endloop
	snd_call Sub_73E1
	snd_call Sub_73EC
	snd_call Sub_73E1
	snd_call Sub_73F7
	snd_call Sub_7402
	snd_call Sub_7413
	snd_jump Seq_73BA
Sub_73E1:
	pan PAN_R
	note -13, 0
	note -1, 0
	rest 0
	note -1, 0
	note -6, 0
	note 11, 0
	note -1, 0
	note -13, 0
	snd_ret
Sub_73EC:
	pan PAN_L
	note -13, 0
	note -1, 0
	rest 0
	note -1, 0
	note 11, 0
	note 11, 0
	note -1, 0
	note -13, 0
	snd_ret
Sub_73F7:
	pan PAN_L
	note -13, 0
	note -1, 0
	rest 0
	note -1, 0
	note 11, 0
	note 6, 0
	note 3, 0
	note -1, 0
	snd_ret
Sub_7402:
	pan PAN_LR
	note -8, 0
	note 4, 0
	rest 0
	note 4, 0
	note -8, 0
	rest 0
	note -8, 0
	note 4, 0
	note 4, 0
	note -8, 0
	rest 0
	note -8, 0
	note 4, 0
	rest 2
	snd_ret
Sub_7413:
	pan PAN_LR
	note -8, 0
	note 4, 0
	rest 0
	note 4, 0
	note -8, 0
	rest 0
	note -8, 0
	note 4, 0
	rest 0
	note 1, 0
	note 1, 0
	note 1, 0
	note 4, 0
	note 4, 0
	note -2, 0
	note -2, 0
	snd_ret
Song47_CH3:
	length_set 12
	instrument 2
	pan PAN_LR
	volume 15
	gate 150
	base_note $1A
Seq_7432:
	snd_loop 3
	snd_call Sub_745C
	snd_endloop
	snd_call Sub_7465
	snd_loop 2
	snd_call Sub_746E
	snd_call Sub_7477
	snd_endloop
	snd_loop 3
	snd_call Sub_745C
	snd_endloop
	snd_call Sub_7465
	snd_call Sub_746E
	snd_call Sub_7477
	snd_call Sub_746E
	snd_call Sub_747E
	snd_jump Seq_7432
Sub_745C:
	note -1, 0
	note -1, 0
	note 3, 0
	note 3, 0
	note 4, 0
	note 4, 0
	note 5, 0
	note 6, 0
	snd_ret
Sub_7465:
	note 9, 0
	note 9, 0
	note 8, 0
	note 8, 0
	note 6, 0
	note -1, 0
	note 1, 0
	note -1, 0
	snd_ret
Sub_746E:
	note 4, 0
	note 4, 0
	note 2, 0
	note 1, 0
	note -1, 0
	note -1, 0
	note 1, 0
	note 2, 0
	snd_ret
Sub_7477:
	note 4, 0
	note 4, 0
	note 2, 0
	note 1, 0
	note -1, 0
	rest 2
	snd_ret
Sub_747E:
	rest 0
	snd_loop 7
	note 6, 0
	snd_endloop
	snd_ret
Song47_CH4:
	length_set 12
	gate 0
	volume 11
	pan PAN_LR
Seq_748C:
	snd_call Sub_7495
	snd_call Sub_74A6
	snd_jump Seq_748C
Sub_7495:
	instrument 28
	drum 11, 1
	instrument 29
	drum 3, 1
	instrument 28
	drum 11, 0
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	snd_ret
Sub_74A6:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 1
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	snd_ret
	snd_end  ; unreferenced (stream)
Song48_CH1:
	length_set 15
	instrument 39
	pan PAN_LR
	gate 200
	base_note $27
	volume 10
	snd_call Sub_74F1
	snd_call Sub_74F8
Seq_74CD:
	snd_loop 2
	snd_call Sub_7500
	snd_call Sub_7502
	snd_call Sub_7507
	snd_call Sub_751D
	snd_call Sub_7502
	snd_call Sub_751F
	snd_endloop
	snd_call Sub_7534
	snd_call Sub_7542
	snd_call Sub_7534
	snd_call Sub_7553
	snd_jump Seq_74CD
Sub_74F1:
	note -12, 3
	note -11, 3
	note -10, 3
	note -9, 3
	note -4, 3
	rest 1
	snd_ret
Sub_74F8:
	instrument 44
	gate 0
	note -4, 1
	note -2, 1
	note 0, 1
	snd_ret
Sub_7500:
	note 1, 1
	snd_ret
Sub_7502:
	note -7, 0
	note -4, 0
	note 1, 1
	note 5, 1
	snd_ret
Sub_7507:
	note 6, 0
	note 5, 0
	note 3, 0
	note 1, 0
	note 0, 2
	note 1, 0
	note 3, 0
	note 5, 0
	note 1, 0
	note -2, 0
	note 0, 0
	note 1, 0
	note 2, 0
	note 3, 0
	note 5, 0
	note 3, 0
	note 1, 0
	note 0, 0
	note -2, 0
	note -4, 0
	note -6, 0
	snd_ret
Sub_751D:
	rest 1
	snd_ret
Sub_751F:
	note 2, 0
	note 3, 0
	note 5, 0
	note 6, 0
	note 10, 1
	note 10, 0
	note 12, 0
	note 13, 0
	note 8, 0
	note 10, 0
	note 6, 0
	note 5, 0
	note 8, 0
	note 6, 0
	note 3, 0
	note 0, 0
	note -4, 0
	note -2, 0
	note 0, 0
	note 1, 2
	snd_ret
Sub_7534:
	note 6, 0
	note 5, 0
	note 6, 0
	note 5, 0
	note 6, 0
	note 10, 0
	note 8, 0
	note 6, 0
	note 5, 0
	note 3, 0
	note 5, 0
	note 3, 0
	note 5, 2
	snd_ret
Sub_7542:
	note 6, 0
	note 5, 0
	note 3, 0
	note 5, 0
	note 6, 0
	note 8, 0
	note 10, 0
	note 12, 0
	note 13, 0
	note 8, 0
	note 5, 0
	note 8, 0
	note 1, 0
	note -4, 0
	note -7, 0
	note -4, 0
	snd_ret
Sub_7553:
	note 3, 0
	note 2, 0
	note 3, 0
	note 5, 0
	note 7, 0
	note 3, 0
	note 5, 0
	note 7, 0
	note 8, 0
	note 7, 0
	note 8, 0
	note 7, 0
	note 8, 0
	note -4, 0
	note -2, 0
	note 0, 0
	snd_ret
Song48_CH2:
	length_set 15
	instrument 39
	gate 180
	volume 14
	base_note $27
	snd_call Sub_758F
	snd_call Sub_75C6
Seq_7574:
	snd_loop 2
	snd_call Sub_75D2
	snd_call Sub_75D4
	snd_call Sub_75DB
	snd_call Sub_75E5
	snd_call Sub_75D4
	snd_call Sub_75E7
	snd_endloop
	snd_call Sub_75F2
	snd_jump Seq_7574
Sub_758F:
	pan PAN_L
	note -9, 1
	note -12, 0
	note -9, 0
	note -4, 0
	note -9, 0
	note -4, 0
	note 0, 0
	pan PAN_R
	note -8, 1
	note -11, 0
	note -8, 0
	note -3, 0
	note -8, 0
	note -3, 0
	note 1, 0
	pan PAN_L
	note -7, 1
	note -10, 0
	note -7, 0
	note -2, 0
	note -7, 0
	note -2, 0
	note 2, 0
	pan PAN_R
	note -6, 1
	note -9, 0
	note -6, 0
	note 0, 0
	note -6, 0
	note 0, 0
	note 3, 0
	note -6, 4
	note -4, 5
	note 0, 4
	note 3, 5
	note -4, 4
	note 0, 5
	note 3, 4
	note 6, 5
	note 0, 4
	note 3, 5
	note 6, 4
	note 8, 5
	note 3, 4
	note 6, 5
	note 8, 4
	note 12, 5
	note 15, 0
	rest 0
	snd_ret
Sub_75C6:
	gate 0
	instrument 44
	volume 9
	pan PAN_LR
	rest 1
	note -5, 1
	note -6, 1
	snd_ret
Sub_75D2:
	note -7, 1
	snd_ret
Sub_75D4:
	note -11, 0
	note -7, 0
	note -4, 1
	note 1, 1
	note -2, 1
	note -2, 1
	snd_ret
Sub_75DB:
	note -4, 1
	note -6, 1
	note -4, 1
	note 1, 1
	note -4, 1
	note -4, 1
	note -9, 1
	note -11, 2
	note -12, 1
	snd_ret
Sub_75E5:
	rest 1
	snd_ret
Sub_75E7:
	note -9, 1
	note -9, 0
	note -9, 0
	note 8, 1
	note 1, 1
	note 1, 1
	note 0, 2
	note -4, 0
	note -6, 0
	note -7, 2
	snd_ret
Sub_75F2:
	note 3, 1
	note 1, 1
	note 0, 0
	note -4, 0
	note -2, 0
	note 0, 0
	note 1, 1
	note -4, 1
	note 1, 0
	note -4, 0
	note -7, 0
	note -4, 0
	note -2, 1
	note -5, 1
	note -4, 1
	note -6, 2
	note -7, 0
	note -9, 0
	note -11, 1
	note -13, 1
	note -2, 0
	note -4, 0
	note -2, 0
	note -4, 0
	note -2, 0
	note 1, 0
	note 0, 0
	note -2, 0
	note -4, 0
	note -6, 0
	note -4, 0
	note -6, 0
	note -4, 0
	note 1, 0
	note 3, 0
	note 5, 0
	note 7, 1
	note 1, 2
	note 1, 1
	note 0, 0
	note -2, 0
	note 0, 0
	note -2, 0
	note 0, 0
	note -4, 0
	note -5, 0
	note -6, 0
	snd_ret
Song48_CH3:
	length_set 15
	instrument 2
	gate 0
	pan PAN_LR
	base_note $1B
	volume 15
	snd_call Sub_764C
Seq_7631:
	snd_loop 2
	snd_call Sub_7657
	snd_call Sub_765E
	snd_call Sub_7657
	snd_call Sub_7669
	snd_endloop
	snd_loop 3
	snd_call Sub_7674
	snd_endloop
	snd_call Sub_767E
	snd_jump Seq_7631
Sub_764C:
	snd_loop 5
	note -4, 3
	snd_endloop
	gate 100
	note -4, 1
	note -4, 1
	note -2, 1
	note 0, 1
	snd_ret
Sub_7657:
	note -11, 1
	note 1, 1
	note -7, 1
	note 5, 1
	note -6, 1
	note 6, 1
	snd_ret
Sub_765E:
	note -4, 1
	note 8, 1
	note -2, 1
	note 10, 1
	note -7, 1
	note 5, 1
	note -5, 1
	note 7, 1
	note 8, 1
	note -4, 1
	snd_ret
Sub_7669:
	note -5, 1
	note 7, 1
	note -7, 1
	note -6, 1
	note -4, 1
	note -4, 1
	note -9, 1
	note -4, 1
	note -11, 1
	note 1, 1
	snd_ret
Sub_7674:
	note -9, 1
	note 3, 1
	note -4, 1
	note 8, 1
	snd_loop 2
	note -11, 1
	note 1, 1
	snd_endloop
	snd_ret
Sub_767E:
	snd_loop 2
	note -9, 1
	note 3, 1
	snd_endloop
	snd_loop 2
	note -4, 1
	note 8, 1
	snd_endloop
	snd_ret
	snd_end  ; unreferenced (stream)
Song49_CH1:
	pan PAN_LR
	volume 8
Seq_768E:
	length_set 13
	instrument 42
	gate 220
	base_note $27
Seq_7696:
	snd_call Sub_76AE
	snd_call Sub_76B5
	snd_call Sub_76AE
	snd_call Sub_76BB
	snd_call Sub_76AE
	snd_call Sub_76B5
	snd_call Sub_76C2
	snd_jump Seq_7696
Sub_76AE:
	note -12, 0
	note -9, 0
	note -5, 0
	note -2, 1
	note -3, 1
	note -7, 1
	snd_ret
Sub_76B5:
	note -4, 1
	note -5, 1
	note -9, 0
	note -7, 0
	note -10, 0
	snd_ret
Sub_76BB:
	note -4, 0
	note -5, 0
	rest 0
	note 7, 0
	note 7, 0
	rest 1
	snd_ret
Sub_76C2:
	note -12, 0
	note -9, 0
	note -7, 0
	note -5, 1
	note -3, 0
	note -1, 0
	note 0, 0
	rest_x 80
	snd_ret
Song49_CH2:
	pan PAN_LR
	volume 6
	rest_x 8
	snd_jump Seq_768E
Song49_CH3:
	pan PAN_LR
	length_set 13
	volume 13
	instrument 2
	base_note $1B
	gate 220
	snd_jump Seq_7696
Song49_CH4:
	length_set 13
	pan PAN_LR
	volume 10
	gate 0
Seq_76EC:
	snd_call Sub_76F2
	snd_jump Seq_76EC
Sub_76F2:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 0
	snd_loop 2
	instrument 5
	drum 2, 0
	instrument 28
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 0
	snd_endloop
	instrument 29
	drum 3, 0
	instrument 28
	drum_x 11, 5
	drum_x 11, 5
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 0
	snd_ret
Song50_CH1:
	volume 13
Seq_771F:
	pan PAN_LR
	instrument 12
	length_set 13
	gate 0
	base_note $27
Seq_7729:
	snd_loop 2
	snd_call Sub_775F
	snd_endloop
	snd_call Sub_7763
	snd_loop 2
	snd_call Sub_7766
	snd_endloop
	snd_call Sub_776A
	snd_loop 2
	snd_call Sub_776D
	snd_endloop
	snd_call Sub_7771
	snd_call Sub_7774
	snd_loop 2
	snd_call Sub_775F
	snd_endloop
	snd_call Sub_7763
	snd_loop 2
	snd_call Sub_7766
	snd_endloop
	snd_call Sub_776A
	snd_call Sub_777D
	snd_jump Seq_7729
Sub_775F:
	note -8, 0
	note -5, 0
	note -1, 0
	snd_ret
Sub_7763:
	note -8, 0
	note -5, 0
	snd_ret
Sub_7766:
	note -2, 0
	note -8, 0
	note -5, 0
	snd_ret
Sub_776A:
	note -2, 0
	note -8, 0
	snd_ret
Sub_776D:
	note -6, 0
	note -3, 0
	note -8, 0
	snd_ret
Sub_7771:
	note -6, 0
	note -3, 0
	snd_ret
Sub_7774:
	note -5, 0
	note -6, 0
	note -8, 0
	note -9, 0
	note -8, 0
	note -13, 0
	note -11, 0
	note -9, 0
	snd_ret
Sub_777D:
	note -6, 0
	note -3, 0
	note -8, 0
	note -6, 0
	note -3, 0
	note 1, 0
	note 2, 0
	snd_loop 3
	note 3, 0
	note 4, 0
	snd_endloop
	note -13, 0
	note -11, 0
	note -9, 0
	snd_ret
Song50_CH2:
	volume 8
	rest_x 5
	snd_jump Seq_771F
Song50_CH3:
	length_set 13
	volume 15
	instrument 2
	gate 0
	pan PAN_LR
	base_note $1B
Seq_77A0:
	snd_call Sub_77A6
	snd_jump Seq_77A0
Sub_77A6:
	note -8, 0
	rest 1
	note -8, 0
	rest 1
	note -8, 0
	rest 0
	snd_ret
Song50_CH4:
	length_set 13
	pan PAN_LR
	gate 0
	volume 13
Seq_77B5:
	snd_call Sub_77BB
	snd_jump Seq_77B5
Sub_77BB:
	instrument 28
	drum 11, 0
	instrument 5
	drum 2, 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 0
	drest 0
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	snd_ret
	snd_end  ; unreferenced (stream)
Song51_CH1:
	length_set 16
	pan PAN_LR
	volume 10
	gate 180
	instrument 38
	base_note $27
Seq_77DD:
	snd_call Sub_77EC
	snd_call Sub_77F9
	snd_call Sub_77EC
	snd_call Sub_780E
	snd_jump Seq_77DD
Sub_77EC:
	rest 1
	note -6, 1
	note -2, 1
	note -6, 1
	note 1, 3
	rest 1
	note -4, 1
	note -1, 1
	note -4, 1
	note 3, 2
	note 3, 0
	note 4, 0
	snd_ret
Sub_77F9:
	note 5, 1
	note 5, 0
	note 6, 0
	note 8, 1
	note 5, 1
	note 3, 1
	note 3, 0
	note 5, 0
	note 6, 1
	note 3, 1
	snd_loop 3
	note 1, 1
	note 1, 0
	note 3, 0
	snd_endloop
	note 1, 0
	note -1, 0
	note -2, 0
	note -4, 0
	snd_ret
Sub_780E:
	note 5, 1
	note 5, 0
	note 6, 0
	note 8, 1
	note 10, 1
	note 11, 1
	note 11, 0
	note 8, 0
	note 5, 0
	note 1, 0
	note 3, 0
	note 5, 0
	snd_loop 2
	note 6, 1
	note 6, 0
	note 5, 0
	snd_endloop
	note 6, 1
	rest 2
	snd_ret
Song51_CH2:
	length_set 16
	instrument 38
	volume 10
	base_note $27
	gate 150
Seq_782D:
	snd_call Sub_783C
	snd_call Sub_784F
	snd_call Sub_783C
	snd_call Sub_785E
	snd_jump Seq_782D
Sub_783C:
	pan PAN_R
	note_x -2, 60
	note -2, 1
	note -4, 1
	note -6, 1
	pan PAN_L
	note_x -1, 60
	note -1, 1
	note -2, 1
	note -4, 1
	pan PAN_LR
	note_x 1, 24
	snd_ret
Sub_784F:
	note_x -4, 24
	note 0, 1
	note -2, 1
	note -4, 1
	note -6, 1
	snd_loop 3
	note -7, 1
	note -7, 0
	note -6, 0
	snd_endloop
	note -7, 1
	note -7, 1
	snd_ret
Sub_785E:
	note_x 0, 24
	note 1, 1
	note 1, 1
	note 0, 1
	note -1, 1
	snd_loop 2
	note -2, 1
	note -2, 0
	note -4, 0
	snd_endloop
	note -2, 1
	rest 2
	snd_ret
Song51_CH3:
	length_set 16
	pan PAN_LR
	volume 15
	gate 150
	instrument 2
	base_note $1B
Seq_7879:
	snd_loop 8
	snd_call Sub_78A9
	snd_endloop
	snd_loop 8
	snd_call Sub_78AB
	snd_endloop
	snd_loop 4
	snd_call Sub_78AD
	snd_endloop
	snd_loop 4
	snd_call Sub_78AB
	snd_endloop
	snd_loop 8
	snd_call Sub_78AD
	snd_endloop
	snd_loop 8
	snd_call Sub_78A9
	snd_endloop
	snd_loop 8
	snd_call Sub_78AB
	snd_endloop
	snd_call Sub_78AF
	snd_jump Seq_7879
Sub_78A9:
	note -6, 1
	snd_ret
Sub_78AB:
	note -4, 1
	snd_ret
Sub_78AD:
	note 1, 1
	snd_ret
Sub_78AF:
	note 1, 1
	note 1, 1
	note 3, 1
	note 3, 1
	note 5, 1
	note 5, 1
	note 1, 1
	note 1, 1
	snd_loop 3
	note 6, 1
	note 1, 1
	snd_endloop
	note 3, 1
	note 5, 1
	snd_ret
Song51_CH4:
	length_set 16
	pan PAN_LR
	volume 10
	gate 0
Seq_78C7:
	snd_call Sub_78CD
	snd_jump Seq_78C7
Sub_78CD:
	instrument 28
	drum 11, 1
	instrument 5
	drum 2, 1
	instrument 29
	drum 3, 1
	instrument 5
	drum 2, 1
	snd_ret
Song52_CH1:
	volume 10
Seq_78DC:
	length_set 15
	pan PAN_LR
	gate 160
	instrument 38
	base_note $2F
Seq_78E6:
	snd_call Sub_78EC
	snd_jump Seq_78E6
Sub_78EC:
	rest 0
	note_x 4, 27
	note 0, 1
	note -5, 1
	note 5, 1
	note 4, 0
	note 5, 2
	rest 0
	rest 0
	note_x 2, 27
	note -1, 1
	note -5, 1
	note 4, 1
	note 2, 0
	note 4, 2
	rest 0
	rest 0
	note_x 4, 27
	note 1, 1
	note -3, 1
	note 5, 1
	note 4, 0
	note 5, 0
	rest 0
	note 2, 0
	note 4, 0
	note 5, 0
	note 7, 1
	note 5, 1
	note 4, 1
	note 2, 1
	note 0, 0
	rest 0
	note 4, 0
	note 0, 0
	rest 2
	snd_ret
Song52_CH2:
	volume 8
	rest_x 8
	snd_jump Seq_78DC
Song52_CH3:
	length_set 15
	volume 15
	instrument 2
	gate 150
	pan PAN_LR
	base_note $17
Seq_7927:
	snd_call Sub_793C
	snd_call Sub_7942
	snd_call Sub_793C
	snd_call Sub_794D
	snd_call Sub_7942
	snd_call Sub_7953
	snd_jump Seq_7927
Sub_793C:
	note_x 0, 27
	note_x 4, 27
	note 7, 1
	snd_ret
Sub_7942:
	note_x 2, 27
	note_x 5, 27
	note 9, 1
	note_x -5, 27
	note_x -1, 27
	note 2, 1
	snd_ret
Sub_794D:
	note_x -3, 27
	note_x 1, 27
	note 4, 1
	snd_ret
Sub_7953:
	note_x 0, 27
	note 0, 1
	note -5, 0
	note -3, 0
	note -1, 0
	snd_ret
Song52_CH4:
	length_set 15
	gate 0
	volume 10
	pan PAN_LR
Seq_7962:
	snd_call Sub_7968
	snd_jump Seq_7962
Sub_7968:
	instrument 28
	drum 11, 0
	drest 0
	instrument 29
	drum 3, 0
	instrument 28
	drum 11, 0
	drest 0
	drum 11, 0
	instrument 29
	drum 3, 0
	instrument 5
	drum 2, 0
	snd_ret
Song53_CH1:
	length_set 13
	instrument 49
	gate 0
	volume 8
	pan PAN_LR
	base_note $30
Seq_7987:
	snd_call Sub_7996
	snd_call Sub_799D
	snd_call Sub_7996
	snd_call Sub_79A2
	snd_jump Seq_7987
Sub_7996:
	note 6, 0
	note 5, 0
	note 6, 1
	note 1, 1
	note -2, 1
	note -1, 1
	snd_ret
Sub_799D:
	note 1, 1
	note 3, 1
	note_x 1, 100
	snd_ret
Sub_79A2:
	note -2, 1
	note -4, 1
	note_x -6, 100
	snd_ret
Song53_CH2:
	length_set 13
	pan PAN_LR
	instrument 46
	gate 200
	volume 8
	base_note $30
	snd_call Sub_79C8
Seq_79B6:
	snd_loop 2
	snd_call Sub_79CB
	snd_call Sub_79D8
	snd_call Sub_79E5
	snd_call Sub_79D8
	snd_endloop
	snd_jump Seq_79B6
Sub_79C8:
	note 6, 0
	note 1, 0
	snd_ret
Sub_79CB:
	pan PAN_R
	note -6, 0
	note 1, 0
	pan PAN_LR
	note -2, 0
	note 1, 0
	pan PAN_L
	note -6, 0
	note 1, 0
	snd_ret
Sub_79D8:
	pan PAN_R
	note -6, 0
	note 3, 0
	pan PAN_LR
	note -1, 0
	note 3, 0
	pan PAN_L
	note -6, 0
	note 3, 0
	snd_ret
Sub_79E5:
	pan PAN_R
	note -6, 0
	note 5, 0
	pan PAN_LR
	note 1, 0
	note 5, 0
	pan PAN_L
	note -6, 0
	note 5, 0
	snd_ret
Song53_CH3:
	length_set 13
	instrument 2
	volume 15
	gate 180
	pan PAN_LR
	base_note $18
Seq_79FE:
	snd_call Sub_7A0D
	snd_loop 7
	snd_call Sub_7A0F
	snd_endloop
	snd_call Sub_7A13
	snd_jump Seq_79FE
Sub_7A0D:
	note 1, 1
	snd_ret
Sub_7A0F:
	note -6, 1
	note 6, 1
	note 6, 1
	snd_ret
Sub_7A13:
	note -6, 1
	note 6, 1
	snd_ret
Song53_CH4:
	length_set 13
	volume 10
	gate 0
	pan PAN_LR
	snd_call Sub_7A27
Seq_7A21:
	snd_call Sub_7A2B
	snd_jump Seq_7A21
Sub_7A27:
	instrument 29
	drum 3, 1
	snd_ret
Sub_7A2B:
	instrument 28
	drum 11, 1
	instrument 29
	drum 3, 1
	drum 3, 1
	instrument 28
	drum 11, 1
	instrument 29
	drum 3, 0
	drum 3, 0
	drum 3, 1
	snd_ret
Song54_CH1:
	length_set 12
	pan PAN_LR
	volume 8
	instrument 43
	gate 0
	base_note $36
Seq_7A47:
	snd_call Sub_7A4D
	snd_jump Seq_7A47
Sub_7A4D:
	note 0, 2
	note -5, 0
	note -8, 0
	note -8, 0
	note -5, 0
	note 0, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note -3, 0
	note -5, 0
	note -5, 0
	note -6, 0
	note -5, 0
	note -3, 2
	note_x -7, 6
	note_x -3, 6
	note -1, 2
	note_x -5, 6
	note_x -1, 6
	note 0, 2
	note 4, 0
	note 2, 3
	snd_ret
Song54_CH2:
	length_set 12
	pan PAN_LR
	instrument 43
	volume 8
	gate 0
	base_note $2A
Seq_7A75:
	snd_call Sub_7A7B
	snd_jump Seq_7A75
Sub_7A7B:
	note 4, 2
	note 0, 0
	note -5, 0
	note -5, 0
	note 0, 0
	note 4, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note -1, 0
	note -2, 0
	note -1, 0
	rest 0
	note_x -3, 6
	note_x 0, 6
	snd_loop 3
	note_x 5, 4
	note_x 7, 4
	snd_endloop
	rest 0
	note_x -1, 6
	note_x 2, 6
	snd_loop 3
	note_x 7, 4
	note_x 9, 4
	snd_endloop
	note 4, 0
	note -5, 0
	note 0, 0
	note 0, 0
	note -1, 0
	note 2, 0
	note 5, 0
	note 7, 0
	snd_ret
Song54_CH3:
	length_set 12
	volume 15
	pan PAN_LR
	gate 190
	instrument 2
	base_note $1E
Seq_7AB6:
	snd_call Sub_7ABC
	snd_jump Seq_7AB6
Sub_7ABC:
	note 0, 1
	note -5, 1
	note 0, 1
	note -5, 1
	note -1, 1
	note -5, 1
	note -1, 1
	note -5, 1
	note -7, 1
	note 0, 1
	note -5, 1
	note 2, 1
	note 0, 1
	note -5, 1
	note -1, 1
	note -5, 1
	snd_ret
Song54_CH4:
	length_set 12
	volume 10
	gate 0
	pan PAN_LR
Seq_7AD5:
	snd_call Sub_7ADB
	snd_jump Seq_7AD5
Sub_7ADB:
	instrument 28
	drum 11, 0
	instrument 5
	drum_x 3, 6
	drum_x 3, 6
	snd_ret
Song55_CH1:
	length_set 17
	volume 8
	instrument 37
	gate 180
	pan PAN_LR
Seq_7AEF:
	base_note $1B
	snd_call Sub_7AFF
	base_note $1C
	snd_call Sub_7AFF
	snd_call Sub_7B08
	snd_jump Seq_7AEF
Sub_7AFF:
	note 4, 1
	note -5, 0
	note 0, 0
	note 4, 0
	note 0, 0
	note 4, 0
	note 7, 0
	note 12, 3
	snd_ret
Sub_7B08:
	note 14, 2
	note 12, 0
	note 12, 0
	note 14, 5
	note 12, 5
	note 14, 5
	note 15, 3
	note 13, 3
	snd_ret
Song55_CH2:
	length_set 17
	gate 180
	volume 8
	pan PAN_LR
	instrument 37
Seq_7B1B:
	base_note $1B
	snd_call Sub_7B2B
	base_note $1C
	snd_call Sub_7B2B
	snd_call Sub_7B34
	snd_jump Seq_7B1B
Sub_7B2B:
	note 0, 1
	note -8, 0
	note -5, 0
	note 0, 0
	note -5, 0
	note 0, 0
	note 4, 0
	note 7, 3
	snd_ret
Sub_7B34:
	note 6, 2
	note 4, 0
	note 4, 0
	note 6, 5
	note 4, 5
	note 6, 5
	note 6, 1
	note 11, 1
	note 10, 1
	note 8, 1
	note 6, 1
	note 4, 1
	note 3, 1
	note 1, 1
	snd_ret
Song55_CH3:
	length_set 17
	volume 15
	instrument 37
	gate 180
	pan PAN_LR
Seq_7B4D:
	base_note $1B
	snd_loop 2
	snd_call Sub_7B69
	snd_endloop
	base_note $1C
	snd_loop 2
	snd_call Sub_7B69
	snd_endloop
	snd_loop 2
	snd_call Sub_7B6C
	snd_endloop
	snd_call Sub_7B6F
	snd_jump Seq_7B4D
Sub_7B69:
	note 0, 4
	note -5, 4
	snd_ret
Sub_7B6C:
	note 2, 4
	note -3, 4
	snd_ret
Sub_7B6F:
	note -6, 4
	note -6, 4
	note -4, 4
	note -2, 4
	snd_ret
Song55_CH4:
	length_set 17
	gate 0
	volume 8
	pan PAN_LR
Seq_7B7C:
	snd_call Sub_7B82
	snd_jump Seq_7B7C
Sub_7B82:
	instrument 28
	drum 11, 1
	instrument 5
	drum 2, 0
	drum 2, 0
	snd_ret
Env_7B8A:
	env_timbre 0
	env_vol 15
	env_end
Env_7B8D:
	env_timbre 1
	env_vol 15
	env_end
Env_7B90:
	env_vol_add 2  ; unreferenced (envelope)
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -2
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_pitch 1, WAIT
	env_pitch -1, WAIT
	env_jump Env_7B90
Env_7B9D:
	env_timbre 0
	env_vol 15
	env_vol 13
	env_wait 2
	env_loop 5
	env_vol_add -3
	env_wait 2
	env_endloop
	env_end
Env_7BA7:
	env_timbre 0
	env_vol 15
	env_loop 7
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_endloop
	env_end
Env_7BB1:
	env_vol 0
	env_end
Env_7BB3:
	env_vol 2
	env_wait 6
	env_vol 1
	env_wait 6
	env_end
Env_7BB8:
	env_vol_add 1
	env_loop 3
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_endloop
	env_end
Env_7BC6:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 0, WAIT
	env_timbre 1
	env_loop 3
	env_vol_add -2
	env_wait 3
	env_pitch -1
	env_wait 2
	env_pitch 1
	env_wait 2
	env_pitch -1, WAIT
	env_pitch 1, WAIT
	env_endloop
	env_end
Env_7BD6:
	env_timbre 2
	env_vol 12
	env_loop 4
	env_vol_add 1, WAIT
	env_endloop
	env_loop 3
	env_vol_add -2, WAIT
	env_endloop
	env_end
Env_7BE1:
	env_timbre 2
	env_vol 15
	env_vol 6, WAIT
	env_loop 4
	env_vol_add 3, WAIT
	env_loop 4
	env_pitch -2
	env_wait 2
	env_pitch 2
	env_wait 2
	env_pitch 2
	env_wait 2
	env_pitch -2
	env_wait 2
	env_vol_add 1
	env_endloop
Env_7BF3:
	env_pitch -2
	env_wait 2
	env_pitch 2
	env_wait 2
	env_pitch 2
	env_wait 2
	env_pitch -2
	env_wait 2
	env_jump Env_7BF3
Env_7BFE:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 2
	env_vol 8
	env_wait 4
	env_loop 4
	env_vol_add -1, WAIT
	env_endloop
	env_vol_add -1
Env_7C08:
	env_vol_add 1
	env_wait 4
	env_vol_add -1
	env_wait 4
	env_jump Env_7C08
Env_7C0F:
	env_timbre 2
	env_vol 15
	env_loop 4
	env_vol_add -4, WAIT
	env_endloop
	env_end
Env_7C16:
	env_vol 3
	env_wait 6
	env_vol 0
	env_end
Env_7C1A:
	env_timbre 2
	env_vol 15
	env_wait 6
	env_loop 6
	env_vol_add -2
	env_wait 3
	env_endloop
	env_vol 1
	env_end
Env_7C24:
	env_vol 1
	env_wait 2
	env_vol 0
	env_end
	env_timbre 2  ; unreferenced (envelope)
	env_vol 15
	env_wait 12
	env_loop 12
	env_vol_add -1
	env_wait 2
	env_endloop
	env_end
Env_7C31:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_loop 4
	env_vol_add -1, WAIT
	env_endloop
	env_vol 10
	env_loop 4
	env_end
Env_7C3C:
	env_timbre 1
	env_vol 15
	env_wait 7
	env_loop 3
	env_vol_add -5
	env_wait 2
	env_endloop
	env_vol 1
	env_end
Env_7C46:
	env_timbre 0
	env_jump Env_7C4B
Env_7C4A:
	env_timbre 1
Env_7C4B:
	env_vol 14
	env_loop 7
	env_vol_add -1
	env_wait 5
	env_endloop
	env_end
	env_end  ; unreferenced (envelope)
Env_7C53:
	env_timbre 2
	env_vol 12
	env_wait 2
	env_timbre 3, WAIT
	env_vol 10
	env_loop 3
	env_vol_add -1, WAIT
	env_endloop
Env_7C5C:
	env_vol_add 1
	env_wait 4
	env_vol_add -1
	env_wait 5
	env_vol_add 1
	env_wait 5
	env_vol_add -1
	env_wait 4
	env_jump Env_7C5C
	env_vol 1  ; unreferenced (envelope)
	env_wait 2
	env_vol 0
	env_end
Env_7C6B:
	env_vol 13  ; unreferenced (envelope)
Env_7C6C:
	env_vol_add 2
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -2
	env_wait 2
	env_vol_add -2
	env_wait 2
	env_jump Env_7C6C
	env_timbre 1  ; unreferenced (envelope)
	env_jump Env_7C6B
Env_7C7B:
	env_timbre 2
	env_vol 14
	env_wait 2
	env_timbre 3
	env_vol 10
	env_loop 3
	env_vol_add -1, WAIT
	env_endloop
Env_7C84:
	env_vol_add 1
	env_wait 5
	env_vol_add -1
	env_wait 4
	env_vol_add 1
	env_wait 5
	env_vol_add -1
	env_wait 4
	env_jump Env_7C84
Env_7C8F:
	env_vol_add 1
	env_loop 3
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_vol_add -1
	env_endloop
	env_end
InstrumentTable:
	instr Env_5921, Env_5973  ; instrument 0
	instr Env_5924, Env_5973  ; instrument 1
	instr Env_592E, Env_5973  ; instrument 2
	instr Env_5931, Env_5973  ; instrument 3
	instr Env_5934, Env_59DB  ; instrument 4
	instr Env_5945, Env_5973  ; instrument 5
	instr Env_594D, Env_5973  ; instrument 6
	instr Env_5957, Env_5973  ; instrument 7
	instr Env_595F, Env_5973  ; instrument 8
	instr Env_5969, Env_5973  ; instrument 9
	instr Env_5987, Env_59DB  ; instrument 10
	instr Env_598A, Env_5975  ; instrument 11
	instr Env_5994, Env_5979  ; instrument 12
	instr Env_59AE, Env_5975  ; instrument 13
	instr Env_59BE, Env_5975  ; instrument 14
	instr Env_59D0, Env_5975  ; instrument 15
	instr Env_59D4, Env_5973  ; instrument 16
	instr Env_5924, Env_5975  ; instrument 17
	instr Env_59DF, Env_5979  ; instrument 18
	instr Env_59ED, Env_59DB  ; instrument 19
	instr Env_5A7B, Env_59DB  ; instrument 20
	instr Env_5A09, Env_5975  ; instrument 21
	instr Env_5A14, Env_5979  ; instrument 22 (not used by any song or SFX)
	instr Env_5A23, Env_5975  ; instrument 23 (not used by any song or SFX)
	instr Env_5A27, Env_5975  ; instrument 24
	instr Env_5A2B, Env_5975  ; instrument 25
	instr Env_5A3E, Env_5973  ; instrument 26
	instr Env_5A46, Env_5975  ; instrument 27 (not used by any song or SFX)
	instr Env_5A5E, Env_5973  ; instrument 28
	instr Env_5A64, Env_5973  ; instrument 29
	instr Env_5A73, Env_5975  ; instrument 30
	instr Env_5A77, Env_5975  ; instrument 31
	instr Env_5A8B, Env_5975  ; instrument 32
	instr Env_5A8F, Env_59DB  ; instrument 33
	instr Env_6972, Env_59DB  ; instrument 34
	instr Env_7B8A, Env_7BB1  ; instrument 35
	instr Env_7B9D, Env_7BB1  ; instrument 36
	instr Env_7BC6, Env_7BB3  ; instrument 37
	instr Env_7BD6, Env_7BB3  ; instrument 38
	instr Env_7BE1, Env_7BB8  ; instrument 39
	instr Env_7BFE, Env_7BB3  ; instrument 40
	instr Env_7C0F, Env_7BB1  ; instrument 41
	instr Env_7B8D, Env_7C16  ; instrument 42
	instr Env_7C1A, Env_7C24  ; instrument 43
	instr Env_7C7B, Env_7C8F  ; instrument 44
	instr Env_7C31, Env_7BB3  ; instrument 45
	instr Env_7C3C, Env_7BB3  ; instrument 46
	instr Env_7BA7, Env_7BB3  ; instrument 47
	instr Env_7C46, Env_7BB3  ; instrument 48
	instr Env_7C4A, Env_7BB3  ; instrument 49
	instr Env_7C53, Env_7BB3  ; instrument 50
LengthSets:
	db   1,   2,   3,   4,   5,   6  ; length set 0
	db   6,  12,  24,  18,  38,  60  ; length set 1
	db  12,  24,  36,  48,  60,  72  ; length set 2
	db   8,  12,  16,  24,   2,  60  ; length set 3
	db   4,   6,  12,  24,  36,  48  ; length set 4
	db   7,  14,  28,  21,   9,  56  ; length set 5
	db  16,  32,  64,  48,  72,  96  ; length set 6
	db  14,  28,  56,  42,  24,  16  ; length set 7
	db   5,  10,  20,  15,  60,  40  ; length set 8
	db 108,   9,  18,  27,  54,  36  ; length set 9
	db   1,   2,   3,   4,   5,   6  ; length set 10
	db   8,  16,  24,  32,  40,  48  ; length set 11
	db  12,  24,  36,  48,  60,  72  ; length set 12
	db  10,  20,  30,  40,  50,  60  ; length set 13
	db   7,  14,  28,  20,  96,  50  ; length set 14
	db   9,  18,  36,  72,   4,   5  ; length set 15
	db   6,  12,  36,  48,  72,  96  ; length set 16
	db   6,  12,  36,  48,  24,  16  ; length set 17
