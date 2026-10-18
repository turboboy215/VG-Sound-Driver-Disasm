; songs, SFX, envelopes, instrument/length/song/SFX tables ($54DF-$7ABF)

Song00:
	db 4  ; tracks
	track Song00_CH1, CH1
	track Song00_CH2, CH2
	track Song00_CH3, CH3
	track Song00_CH4, CH4
Song01:
	db 4  ; tracks
	track Song01_CH3, CH3
	track Song01_CH1, CH1
	track Song01_CH2, CH2
	track Song01_CH4, CH4
Song02:
	db 4  ; tracks
	track Song02_CH1, CH1
	track Song02_CH3, CH3
	track Song02_CH2, CH2
	track Song02_CH4, CH4
Song03:
	db 4  ; tracks
	track Song03_CH1, CH1
	track Song03_CH3, CH3
	track Song03_CH2, CH2
	track Song03_CH4, CH4
Song04:
	db 2  ; tracks
	track Song04_CH1, CH1
	track Song04_CH2, CH2
Song05:
	db 4  ; tracks
	track Song05_CH1, CH1
	track Song05_CH3, CH3
	track Song05_CH2, CH2
	track Song05_CH4, CH4
Song06:
	db 4  ; tracks
	track Song06_CH3, CH3
	track Song06_CH1, CH1
	track Song06_CH2, CH2
	track Song06_CH4, CH4
Song07:
	db 3  ; tracks
	track Song07_CH1, CH1
	track Song07_CH2, CH2
	track Song07_CH3, CH3
Song08:
	db 4  ; tracks
	track Song08_CH3, CH3
	track Song08_CH1, CH1
	track Song08_CH2, CH2
	track Song08_CH4, CH4
Song09:
	db 4  ; tracks
	track Song09_CH3, CH3
	track Song09_CH1, CH1
	track Song09_CH2, CH2
	track Song09_CH4, CH4
Song10:
	db 4  ; tracks
	track Song10_CH1, CH1
	track Song10_CH2, CH2
	track Song10_CH3, CH3
	track Song10_CH4, CH4
Song11:
	db 4  ; tracks
	track Song11_CH3, CH3
	track Song11_CH1, CH1
	track Song11_CH2, CH2
	track Song11_CH4, CH4
Song12:
	db 4  ; tracks
	track Song12_CH3, CH3
	track Song12_CH1, CH1
	track Song12_CH2, CH2
	track Song12_CH4, CH4
Song13:
	db 4  ; tracks
	track Song13_CH1, CH1
	track Song13_CH2, CH2
	track Song13_CH3, CH3
	track Song13_CH4, CH4
Song14:
	db 4  ; tracks
	track Song14_CH1, CH1
	track Song14_CH2, CH2
	track Song14_CH3, CH3
	track Song14_CH4, CH4
Song15:
	db 4  ; tracks
	track Song15_CH1, CH1
	track Song15_CH2, CH2
	track Song15_CH3, CH3
	track Song00_CH4, CH4
Song16:
	db 4  ; tracks
	track Song16_CH1, CH1
	track Song16_CH2, CH2
	track Song16_CH3, CH3
	track Song16_CH4, CH4
Song17:
	db 4  ; tracks
	track Song17_CH3, CH3
	track Song17_CH1, CH1
	track Song17_CH2, CH2
	track Song17_CH4, CH4
Song18:
	db 4  ; tracks
	track Song18_CH3, CH3
	track Song18_CH1, CH1
	track Song18_CH2, CH2
	track Song18_CH4, CH4
Song00_CH1:
	length_set 2
	pan PAN_LR
	base_note $33
	instrument 5
	volume 11
	gate 128
	snd_call Sub_5622
	snd_call Sub_562C
	snd_call Sub_5622
	snd_call Sub_5634
Seq_55E5:
	instrument 13
	volume 10
	gate 0
	snd_call Sub_5646
	snd_call Sub_5652
	snd_call Sub_5646
	snd_call Sub_5660
	instrument 15
	snd_call Sub_5669
	volume 9
	pan PAN_LR
	snd_call Sub_5681
	pan PAN_LR
	snd_call Sub_5615
	instrument 14
	volume 9
	snd_call Sub_5695
	snd_call Sub_5615
	snd_jump Seq_55E5
Sub_5615:
	gate 128
	instrument 5
	volume 8
	snd_loop 6
	note 7, 0
	volume_add 1
	snd_endloop
	snd_ret
Sub_5622:
	rest 1
	gate 128
	note -1, 0
	note -1, 0
	note -1, 0
	rest 2
	note -1, 1
	note -1, 1
	snd_ret
Sub_562C:
	rest 1
	note 0, 0
	note 0, 0
	note -3, 1
	rest 1
	note -3, 1
	note -1, 1
	snd_ret
Sub_5634:
	rest 1
	note 0, 0
	note 0, 0
	note -3, 1
	instrument 12
	gate 200
	snd_loop 3
	note 7, 0
	volume_add -1
	note 7, 0
	volume_add 2
	snd_endloop
	snd_ret
Sub_5646:
	note 4, 2
	note 5, 0
	note 4, 0
	note 5, 0
	note 7, 0
	rest 0
	note 12, 2
	rest 0
	note 11, 3
	note 9, 1
	note 9, 5
	snd_ret
Sub_5652:
	rest 1
	note 2, 0
	note 4, 0
	note 2, 0
	note 4, 0
	note 5, 0
	rest 0
	note 11, 2
	note 9, 0
	note_x 7, 54
	note_x 2, 54
	snd_ret
Sub_5660:
	note 12, 1
	note 10, 1
	note 8, 1
	note 12, 1
	note 10, 2
	note 12, 0
	note_x 7, 108
	snd_ret
Sub_5669:
	note 2, 3
	note 2, 0
	note 4, 0
	note 5, 1
	note 2, 1
	note 5, 1
	note 4, 3
	note 4, 0
	note 5, 0
	note 7, 1
	note 5, 1
	note 4, 1
	note 2, 1
	note 2, 1
	note 2, 0
	note 4, 0
	note 5, 1
	note 2, 1
	note 5, 1
	note 7, 1
	note 4, 1
	note 7, 1
	note 12, 5
	snd_ret
Sub_5681:
	note 14, 3
	note 12, 0
	note 10, 0
	note 9, 1
	note 10, 1
	note 12, 1
	note 7, 3
	note 4, 0
	note 5, 0
	note 7, 1
	note 4, 1
	note 5, 1
	note 4, 3
	note 2, 0
	note 4, 0
	note 2, 3
	note 0, 0
	note 2, 0
	note 2, 5
	snd_ret
Sub_5695:
	snd_loop 6
	gate 0
	note -1, 0
	note -5, 0
	snd_endloop
	snd_loop 6
	note 0, 0
	note -3, 0
	snd_endloop
	snd_loop 6
	note -1, 0
	note -5, 0
	snd_endloop
	snd_loop 3
	note 0, 0
	note -3, 0
	snd_endloop
	snd_ret
Song00_CH2:
	length_set 2
	pan PAN_LR
	instrument 5
	gate 128
	volume 11
	base_note $33
	snd_call Sub_5707
	snd_call Sub_5714
	snd_call Sub_5707
	snd_call Sub_5718
Seq_56C4:
	pan PAN_LR
	instrument 13
	volume 10
	gate 0
	snd_call Sub_573B
	snd_call Sub_5748
	snd_call Sub_573B
	snd_call Sub_5757
	instrument 5
	gate 140
	volume 8
	base_note $27
	snd_call Sub_5760
	snd_call Sub_5760
	instrument 14
	gate 255
	volume 10
	pan PAN_LR
	snd_call Sub_5681
	snd_call Sub_5718
	base_note $27
	pan PAN_LR
	instrument 14
	gate 0
	volume 9
	snd_call Sub_576B
	snd_call Sub_5718
	snd_jump Seq_56C4
Sub_5707:
	rest 1
	note -5, 0
	note -5, 0
	note -5, 0
	rest 2
	note -5, 1
	note -5, 1
	rest 1
	note -7, 0
	note -7, 0
	note -7, 0
	rest 0
	snd_ret
Sub_5714:
	rest 1
	note -8, 1
	note -10, 1
	snd_ret
Sub_5718:
	instrument 12
	base_note $33
	gate 200
	pan PAN_L
	note 7, 0
	volume_add -1
	pan PAN_R
	note 6, 0
	volume_add 2
	pan PAN_L
	note 5, 0
	volume_add -1
	pan PAN_R
	note 4, 0
	volume_add 2
	pan PAN_L
	note 3, 0
	volume_add -1
	pan PAN_R
	note 2, 0
	snd_ret
Sub_573B:
	note 0, 2
	note 2, 0
	note 0, 0
	note 2, 0
	note 4, 0
	rest 0
	note 4, 2
	rest 0
	note 2, 3
	note 0, 0
	rest 0
	note 0, 5
	snd_ret
Sub_5748:
	rest 1
	note -1, 0
	note 0, 0
	note -1, 0
	note 0, 0
	note 2, 0
	rest 0
	note 7, 2
	note 5, 0
	note_x 4, 54
	note -1, 1
	note -3, 1
	note -5, 1
	snd_ret
Sub_5757:
	note 8, 1
	note 7, 1
	note 5, 1
	note 8, 1
	note 7, 2
	note 8, 0
	note_x 4, 108
	snd_ret
Sub_5760:
	snd_loop 6
	note -7, 0
	note -10, 0
	snd_endloop
	snd_loop 6
	note -5, 0
	note -8, 0
	snd_endloop
	snd_ret
Sub_576B:
	snd_loop 6
	note -5, 0
	note -8, 0
	snd_endloop
	snd_loop 6
	note -3, 0
	note -7, 0
	snd_endloop
	snd_loop 6
	note -5, 0
	note -8, 0
	snd_endloop
	snd_loop 3
	note -3, 0
	note -7, 0
	snd_endloop
	snd_ret
Song00_CH3:
	length_set 2
	pan PAN_LR
	volume 15
	instrument 7
	base_note $27
	snd_call Sub_57D3
	snd_call Sub_57E8
	snd_call Sub_57D3
	snd_call Sub_57F5
Seq_5796:
	snd_call Sub_5803
	base_note $20
	snd_call Sub_5803
	base_note $22
	snd_call Sub_5803
	base_note $27
	snd_call Sub_580D
	snd_call Sub_5803
	base_note $20
	snd_call Sub_5803
	base_note $1B
	snd_call Sub_581A
	snd_call Sub_5803
	base_note $27
	instrument 11
	gate 140
	snd_call Sub_5827
	snd_call Sub_5827
	base_note $1B
	gate 200
	snd_call Sub_5827
	gate 0
	snd_call Sub_583A
	snd_jump Song00_CH3
Sub_57D3:
	gate 220
	base_note $27
	note -12, 0
	note -5, 0
	gate 200
	note 2, 0
	note 2, 0
	note 0, 0
	rest 0
	gate 220
	note -12, 0
	note -5, 0
	gate 200
	note 2, 1
	note 0, 1
	snd_ret
Sub_57E8:
	note -10, 0
	note -3, 0
	note 4, 0
	note 4, 0
	note 2, 0
	rest 0
	base_note $1B
	note -5, 0
	note 2, 0
	note 7, 1
	note 7, 1
	snd_ret
Sub_57F5:
	note -10, 0
	note -3, 0
	note 4, 0
	note 4, 0
	note 2, 1
	gate 160
	note -5, 0
	note -5, 0
	note -5, 0
	note -5, 0
	note -3, 0
	note -1, 0
	snd_ret
Sub_5803:
	snd_loop 2
	note -12, 0
	note -5, 0
	note 2, 0
	note 4, 0
	note 0, 0
	rest 0
	snd_endloop
	snd_ret
Sub_580D:
	note -12, 0
	note -5, 0
	note 2, 0
	note 4, 0
	note 0, 0
	rest 0
	note -5, 0
	note 7, 0
	note 7, 0
	note -5, 0
	note 7, 0
	note 7, 0
	snd_ret
Sub_581A:
	note -4, 0
	note -4, 0
	note 8, 0
	note -4, 0
	note 8, 0
	note -9, 0
	note -2, 0
	note -2, 0
	note 10, 0
	note -2, 0
	note 10, 0
	note -7, 0
	snd_ret
Sub_5827:
	snd_loop 2
	note -14, 0
	note -7, 0
	note 2, 0
	note -2, 0
	note 2, 0
	note -2, 0
	snd_endloop
	snd_loop 2
	note -12, 0
	note -5, 0
	note 4, 0
	note 0, 0
	note 4, 0
	note 0, 0
	snd_endloop
	snd_ret
Sub_583A:
	snd_loop 2
	note -10, 0
	note -3, 0
	note 5, 0
	note 2, 0
	note 9, 0
	note 5, 0
	snd_endloop
	note -5, 0
	note 2, 0
	note 11, 0
	note 7, 0
	note 11, 0
	note 5, 0
	gate 160
	note -5, 0
	note -5, 0
	note -5, 0
	note -5, 0
	note -3, 0
	note -1, 0
	snd_ret
Song00_CH4:
	length_set 2
	pan PAN_LR
	volume 10
	instrument 16
	gate 0
Seq_585C:
	drum 2, 0
	volume_add -5
	drum 4, 0
	volume_add 5
	drum 2, 0
	drum 2, 0
	drum 2, 0
	volume_add -5
	drum 4, 0
	volume_add 5
	drum 2, 0
	drum 2, 0
	drum 2, 0
	volume_add -5
	drum 4, 0
	volume_add 5
	drum 2, 0
	volume_add -5
	drum 4, 0
	volume_add 5
	snd_jump Seq_585C
Song01_CH3:
	length_set 1
	pan PAN_LR
	volume 15
	instrument 2
	gate 240
	base_note $1B
	note -5, 0
	note -5, 0
	rest 0
	note -5, 0
	gate 128
	note -5, 1
	note -5, 1
	note -5, 1
	base_note $33
	gate 180
	note 2, 0
	note 2, 0
	note 2, 0
	rest 0
	gate 0
	base_note $0F
	note_x -5, 3
	note_x -3, 4
	note_x -1, 3
	gate 50
	base_note $1B
	note -12, 5
	note -12, 5
	note -10, 5
	gate 130
	instrument 17
	rest 1
	note -5, 1
	note -5, 1
	note -5, 1
	note -5, 1
	rest 1
Seq_58B3:
	base_note $33
	volume 15
	instrument 17
	snd_call Sub_58DC
	snd_call Sub_58DC
	hold 20
	snd_call Sub_5900
	base_note $1B
	instrument 2
	gate 50
	note -12, 5
	note -12, 5
	base_note $0F
	gate 240
	snd_loop 3
	snd_call Sub_590C
	snd_endloop
	snd_call Sub_592D
	snd_jump Seq_58B3
Sub_58DC:
	gate 150
	note -5, 2
	gate 255
	note -5, 0
	note_x 0, 57
	rest_x 3
	note 0, 2
	note 4, 0
	note 7, 1
	gate 140
	note 12, 1
	note 11, 1
	note 9, 1
	gate 255
	note 7, 3
	note 4, 2
	note 7, 0
	gate 240
	note 5, 3
	note 2, 2
	note 4, 0
	note 2, 3
	note 4, 2
	note 2, 0
	gate 230
	note_x 0, 60
	snd_ret
Sub_5900:
	gate 230
	note 0, 2
	note 0, 0
	note 2, 0
	rest 0
	note 4, 3
	note 0, 0
	rest 0
	note 2, 1
	note 0, 1
	snd_ret
Sub_590C:
	note -7, 0
	note 0, 0
	note 8, 0
	note 5, 0
	note 8, 0
	note 5, 0
	note 8, 0
	note 5, 0
	note -2, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note -9, 0
	note -2, 0
	note 7, 0
	note 3, 0
	note 7, 0
	note 3, 0
	note 7, 0
	note 3, 0
	note -4, 0
	note 3, 0
	note 8, 0
	note 3, 0
	note 8, 0
	note 3, 0
	note 8, 0
	note 3, 0
	snd_ret
Sub_592D:
	note -7, 0
	note 0, 0
	note 5, 0
	note 0, 0
	note 5, 0
	note 0, 0
	note 5, 0
	note 0, 0
	note -2, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note 10, 0
	note 5, 0
	snd_loop 2
	gate 240
	note -5, 0
	rest 0
	note -5, 0
	note 2, 0
	snd_endloop
	note 7, 0
	rest 2
	snd_ret
Song01_CH1:
	length_set 1
	rest_x 50
	pan PAN_LR
	volume 10
	instrument 8
	base_note $27
	gate 240
	note 5, 0
	note 5, 0
	note 5, 0
	rest 2
	base_note $1B
	snd_call Sub_599B
	snd_call Sub_599B
	snd_call Sub_59A3
Seq_5966:
	instrument 8
	volume 10
	base_note $1B
	snd_call Sub_59B1
	snd_call Sub_59C6
	snd_call Sub_59B1
	snd_call Sub_59D8
	snd_call Sub_59F5
	snd_call Sub_599B
	snd_call Sub_599B
	base_note $27
	instrument 18
	volume 12
	gate 0
	snd_call Sub_59FE
	snd_call Sub_5A11
	volume 11
	snd_call Sub_59FE
	snd_call Sub_5A1E
	rest 3
	snd_jump Seq_5966
Sub_599B:
	rest 1
	gate 140
	snd_loop 7
	note -5, 1
	snd_endloop
	snd_ret
Sub_59A3:
	rest 1
	snd_loop 7
	note -3, 1
	snd_endloop
	rest 1
	instrument 4
	note 9, 1
	note 9, 1
	note 9, 1
	note 11, 1
	rest 4
	snd_ret
Sub_59B1:
	snd_loop 2
	gate 0
	note -12, 1
	gate 130
	snd_loop 7
	note -5, 1
	snd_endloop
	snd_endloop
	gate 0
	note -10, 1
	gate 140
	note -3, 1
	note -3, 1
	note -3, 1
	snd_ret
Sub_59C6:
	gate 0
	note -10, 1
	gate 140
	note -5, 1
	note -5, 1
	note -5, 1
	gate 0
	note -12, 1
	snd_loop 7
	gate 140
	note -5, 1
	snd_endloop
	snd_ret
Sub_59D8:
	gate 0
	note -8, 1
	gate 140
	note -1, 1
	note -1, 1
	note -1, 1
	gate 0
	pan PAN_L
	note -3, 1
	gate 140
	note 9, 1
	note 9, 1
	note 9, 1
	gate 0
	note -5, 1
	gate 140
	note 7, 1
	note 7, 1
	note 7, 1
	pan PAN_LR
	snd_ret
Sub_59F5:
	gate 150
	note -3, 2
	note -3, 1
	rest 2
	note -1, 1
	note -1, 1
	rest 3
	snd_ret
Sub_59FE:
	note 3, 3
	note 2, 2
	note 3, 0
	note 5, 3
	note 3, 2
	note 5, 0
	note 7, 3
	note 5, 2
	note 7, 0
	note 0, 3
	note 0, 2
	note 2, 0
	note 3, 3
	note 2, 2
	note 3, 0
	note 5, 3
	note 3, 2
	note 5, 0
	snd_ret
Sub_5A11:
	note_x 7, 40
	note 12, 1
	rest 1
	instrument 13
	base_note $33
	gate 230
	note 0, 2
	note 2, 0
	snd_ret
Sub_5A1E:
	note_x 2, 40
	note 7, 3
	snd_ret
Song01_CH2:
	length_set 1
	pan PAN_LR
	volume 10
	instrument 8
	base_note $0F
	gate 240
	note -5, 0
	note -5, 0
	rest 0
	note -5, 0
	gate 128
	note -5, 1
	note -5, 1
	note -5, 1
	gate 180
	base_note $27
	note 7, 0
	note 7, 0
	note 7, 0
	rest 0
	gate 0
	base_note $0F
	volume 13
	note_x -5, 3
	note_x -3, 4
	note_x -1, 3
	base_note $27
	volume 10
	gate 140
	snd_call Sub_5A8F
	snd_call Sub_5A8F
	snd_call Sub_5A95
Seq_5A5A:
	instrument 8
	volume 10
	base_note $1B
	snd_call Sub_5AA3
	snd_call Sub_5AB8
	snd_call Sub_5AA3
	snd_call Sub_5ACA
	snd_call Sub_5ADE
	snd_call Sub_5A8F
	snd_call Sub_5A8F
	base_note $27
	instrument 18
	volume 12
	gate 0
	snd_call Sub_5AE7
	snd_call Sub_5AFA
	volume 11
	snd_call Sub_5AE7
	snd_call Sub_5B07
	rest 3
	snd_jump Seq_5A5A
Sub_5A8F:
	rest 1
	snd_loop 7
	note -8, 1
	snd_endloop
	snd_ret
Sub_5A95:
	rest 1
	snd_loop 7
	note -7, 1
	snd_endloop
	instrument 4
	rest 1
	note 5, 1
	note 5, 1
	note 7, 1
	note 7, 1
	rest 4
	snd_ret
Sub_5AA3:
	snd_loop 2
	gate 0
	note -5, 1
	gate 140
	snd_loop 7
	note 4, 1
	snd_endloop
	snd_endloop
	gate 0
	note -3, 1
	gate 140
	note 0, 1
	note 0, 1
	note 0, 1
	snd_ret
Sub_5AB8:
	gate 0
	note -5, 1
	gate 140
	note -1, 1
	note -1, 1
	note -1, 1
	gate 0
	note -5, 1
	gate 140
	snd_loop 7
	note 4, 1
	snd_endloop
	snd_ret
Sub_5ACA:
	gate 0
	note -4, 1
	gate 140
	note 4, 1
	note 4, 1
	note 4, 1
	gate 255
	pan PAN_R
	snd_loop 8
	note 0, 0
	note 4, 0
	snd_endloop
	pan PAN_LR
	snd_ret
Sub_5ADE:
	gate 150
	note 5, 2
	note 5, 1
	rest 2
	note 7, 1
	note 7, 1
	rest 3
	snd_ret
Sub_5AE7:
	note -4, 3
	note -4, 2
	note -4, 0
	note 2, 3
	note 0, 2
	note 2, 0
	note 3, 3
	note 2, 2
	note 3, 0
	note -4, 3
	note -4, 2
	note -2, 0
	note -4, 3
	note -4, 2
	note -4, 0
	note 2, 3
	note 0, 2
	note 2, 0
	snd_ret
Sub_5AFA:
	note_x 3, 40
	note 7, 1
	rest 1
	gate 230
	base_note $33
	instrument 13
	note -4, 2
	note -2, 0
	snd_ret
Sub_5B07:
	note_x -1, 40
	note -1, 3
	snd_ret
Song01_CH4:
	length_set 1
	pan PAN_LR
	volume 10
	instrument 16
	gate 240
	drest 5
	drest_x 250
	drum 2, 1
	drum 2, 1
	drum 2, 1
	drum 2, 1
	drest 4
Seq_5B1D:
	snd_loop 8
	volume 8
	snd_call Sub_5B36
	snd_endloop
	snd_call Sub_5B41
	volume 7
	snd_loop 9
	snd_call Sub_5B36
	snd_endloop
	snd_call Sub_5B4F
	snd_jump Seq_5B1D
Sub_5B36:
	snd_loop 3
	drum 3, 1
	drum 4, 0
	drum 4, 0
	snd_endloop
	drum 3, 0
	drum 4, 0
	drum 4, 0
	drum 4, 0
	snd_ret
Sub_5B41:
	drum 3, 1
	drum 4, 0
	drum 4, 0
	drum 3, 1
	drum 4, 0
	drum 4, 0
	volume_add 1
	drum 4, 1
	drum 4, 1
	volume_add -1
	drest 3
	snd_ret
Sub_5B4F:
	drum 3, 1
	drum 4, 0
	drum 4, 0
	drum 3, 1
	drum 4, 0
	drum 4, 0
	drum 2, 1
	drest 1
	drest 3
	snd_ret
Song02_CH1:
	length_set 1
	pan PAN_LR
	volume 12
	instrument 19
	base_note $2C
	gate 255
	note_x 2, 25
	note 0, 1
	note 2, 0
	note 4, 3
	note -5, 3
	note 2, 0
	rest 0
	note 2, 2
	note 0, 1
	note 2, 0
	note 4, 3
	note -5, 3
	note 7, 0
	note 5, 0
	note 4, 0
	note 7, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note 2, 0
	note 4, 0
	note_x 0, 40
	volume_add -1
	gate 0
	note_x 11, 2
	gate 255
	note_x 12, 38
	snd_jump Song02_CH1
Song02_CH3:
	length_set 1
	pan PAN_LR
	instrument 7
	volume 15
	gate 200
	base_note $20
	note -7, 2
	note -7, 0
	note 5, 0
	note -7, 1
	note 5, 0
	note -12, 0
	rest 0
	note -12, 2
	note -5, 1
	note -12, 0
	note -14, 0
	rest 0
	note -14, 1
	note -2, 0
	note -14, 1
	note -2, 0
	note -12, 2
	note -12, 0
	note 0, 0
	note -12, 1
	note 0, 0
	snd_loop 2
	note -7, 1
	note 5, 1
	note -7, 0
	note 5, 1
	note -7, 0
	snd_endloop
	note -14, 0
	rest 0
	note -14, 1
	note -2, 0
	note -14, 1
	note -2, 0
	note -14, 0
	note -2, 0
	note -14, 1
	note -2, 0
	note -14, 1
	note -2, 0
	snd_jump Song02_CH3
Song02_CH2:
	length_set 1
	pan PAN_LR
	base_note $31
	volume 9
	instrument 5
	gate 255
	snd_loop 4
	note -12, 0
	note -8, 0
	snd_endloop
	snd_loop 4
	note -13, 0
	note -10, 0
	snd_endloop
	snd_loop 4
	note -12, 0
	note -7, 0
	snd_endloop
	snd_loop 4
	note -13, 0
	note -5, 0
	snd_endloop
	snd_loop 8
	note -12, 0
	note -8, 0
	snd_endloop
	snd_loop 8
	note -12, 0
	note -7, 0
	snd_endloop
	snd_jump Song02_CH2
Song02_CH4:
	length_set 1
	pan PAN_LR
	volume 10
	instrument 16
	gate 255
	drum 6, 0
	volume_add -4
	pan PAN_L
	drum 7, 0
	pan PAN_R
	drum 7, 0
	pan PAN_L
	drum 7, 0
	pan PAN_LR
	volume_add 4
	drum 5, 0
	volume_add -4
	pan PAN_R
	drum 7, 0
	pan PAN_L
	drum 7, 0
	pan PAN_R
	drum 7, 0
	snd_jump Song02_CH4
Song03_CH1:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 20
	gate 250
	base_note $27
	note -3, 1
	note -4, 0
	note -3, 0
	rest 0
	note 7, 2
	note 5, 0
	note 4, 1
	note 5, 0
	note 4, 2
	note 2, 2
	note 0, 2
	note 2, 1
	gate 0
	note_x 1, 3
	note_x 0, 4
	note_x -1, 75
	snd_loop 12
	volume_add -1
	hold 2
	snd_endloop
	snd_end
Song03_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	base_note $27
	gate 240
	note -10, 0
	rest 0
	note 2, 0
	note 0, 0
	rest 0
	note -10, 2
	note 2, 0
	note 0, 0
	rest 0
	note -3, 0
	note 5, 1
	note -5, 0
	note 5, 1
	note -5, 0
	note 2, 1
	note -5, 0
	note 5, 1
	note -5, 0
	volume_add -1
	gate 0
	instrument 0
	note_x -12, 75
	snd_loop 12
	volume_add -1
	hold 2
	snd_endloop
	snd_end
Song03_CH2:
	length_set 3
	pan PAN_LR
	instrument 20
	volume 10
	gate 250
	base_note $1B
	note 5, 1
	note 5, 0
	note 5, 0
	rest 0
	note 14, 2
	note 14, 0
	note 12, 1
	note 12, 0
	note 9, 2
	note 9, 2
	note 7, 2
	note 7, 2
	gate 0
	note_x 4, 75
	snd_loop 12
	volume_add -1
	hold 2
	snd_endloop
	snd_end
Song03_CH4:
	length_set 3
	pan PAN_LR
	volume 9
	gate 255
	instrument 16
	drum 5, 1
	drum 7, 0
	drum 7, 1
	drum 7, 0
	drum 5, 1
	drum 7, 0
	drum 6, 0
	drum 7, 0
	drum 7, 0
	drum 5, 1
	drum 7, 0
	drum 5, 1
	drum 7, 0
	drum 5, 0
	drum 7, 0
	drum 7, 0
	drum 5, 1
	drum 7, 0
	volume_add 2
	instrument 7
	drum_x 5, 70
	snd_end
Song04_CH1:
	length_set 4
	pan PAN_LR
	volume 11
	gate 0
	instrument 14
	base_note $38
Seq_5CC8:
	note 2, 1
	note 7, 1
	note 11, 1
	note 9, 1
	note 7, 1
	note 4, 1
	snd_jump Seq_5CC8
Song04_CH2:
	length_set 4
	pan PAN_LR
	volume 11
	rest 2
	gate 0
	instrument 14
	base_note $38
	snd_jump Seq_5CC8
Song05_CH1:
	length_set 4
	pan PAN_LR
	volume 12
	gate 255
	base_note $27
	snd_call Sub_5D11
	note 7, 0
	note 7, 0
	note 7, 0
	volume 12
	rest 0
	snd_call Sub_5D11
	rest 1
	gate 0
	note_x 7, 12
	snd_loop 6
	detune 2
	hold 2
	snd_endloop
	instrument 13
	base_note $33
	volume 11
	gate 200
	snd_call Sub_5D33
	snd_jump Song05_CH1
Sub_5D11:
	instrument 19
	note_x -8, 4
	note_x -5, 4
	note_x 0, 4
	gate 108
	note 4, 1
	note 2, 1
	note 0, 1
	note -1, 1
	note 0, 1
	gate 255
	note -3, 0
	note 0, 0
	note -5, 0
	rest 0
	note -5, 0
	note -4, 0
	note -3, 0
	rest 0
	note 5, 3
	note 4, 1
	note 2, 0
	volume 13
	instrument 7
	rest 0
	snd_ret
Sub_5D33:
	note 0, 2
	note 0, 0
	note 2, 0
	rest 0
	note 4, 3
	note 0, 0
	rest 0
	note 2, 0
	rest 0
	note_x 0, 108
	note 0, 2
	note 0, 0
	note 2, 0
	rest 0
	note 7, 3
	note 0, 0
	rest 0
	note 2, 0
	rest 0
	note_x 0, 60
	volume 13
	gate 200
	instrument 7
	note 2, 0
	note 2, 0
	rest 0
	note 4, 0
	note 2, 1
	snd_ret
Song05_CH3:
	length_set 4
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	rest 1
	snd_call Sub_5D93
	note 9, 0
	note 9, 0
	note 11, 1
	note -5, 1
	snd_call Sub_5D93
	rest 1
	instrument 0
	gate 0
	note_x 11, 12
	snd_loop 6
	detune 2
	hold 2
	volume_add -2
	snd_endloop
	instrument 7
	gate 250
	volume 15
	base_note $1B
	snd_call Sub_5DAB
	snd_call Sub_5DD3
	snd_call Sub_5DAB
	base_note $27
	snd_call Sub_5DDC
	snd_jump Song05_CH3
Sub_5D93:
	snd_loop 3
	base_note $1B
	note -12, 0
	rest 0
	note 0, 1
	snd_endloop
	note -12, 0
	rest 0
	note 0, 0
	note 0, 0
	snd_loop 2
	note -7, 0
	rest 0
	note 5, 0
	note 5, 0
	snd_endloop
	note -5, 0
	rest 0
	base_note $27
	snd_ret
Sub_5DAB:
	note -3, 0
	rest 0
	volume_add -5
	note 9, 0
	volume_add 5
	note 9, 0
	note -3, 0
	rest 0
	volume_add -5
	note 9, 0
	volume_add 5
	note 9, 0
	note -5, 0
	rest 0
	volume_add -5
	note 7, 0
	volume_add 5
	note 7, 0
	note -5, 0
	volume_add -6
	note -5, 0
	volume_add 6
	note 7, 0
	note 7, 0
	snd_loop 2
	note -7, 0
	rest 0
	note 5, 0
	note 0, 0
	snd_endloop
	snd_ret
Sub_5DD3:
	note -7, 0
	note -7, 0
	note 5, 0
	note -7, 0
	note -5, 0
	note -5, 0
	note 7, 0
	note -5, 0
	snd_ret
Sub_5DDC:
	note 2, 0
	note 7, 0
	rest 0
	note -5, 0
	note 7, 1
	snd_ret
Song05_CH2:
	length_set 4
	pan PAN_LR
	rest 1
	gate 150
	base_note $33
	snd_call Sub_5E26
	note -10, 0
	note -10, 0
	note -10, 1
	rest 1
	snd_call Sub_5E26
	rest 1
	gate 0
	note_x -10, 12
	snd_loop 6
	detune 2
	hold 2
	snd_endloop
	instrument 9
	gate 160
	volume 8
	snd_loop 7
	snd_call Sub_5E46
	snd_endloop
	snd_call Sub_5E4F
	snd_loop 6
	snd_call Sub_5E46
	snd_endloop
	volume 12
	instrument 7
	gate 180
	base_note $33
	pan PAN_LR
	snd_call Sub_5E58
	snd_jump Song05_CH2
Sub_5E26:
	snd_loop 4
	instrument 15
	volume 10
	rest 1
	pan PAN_L
	note -5, 0
	pan PAN_R
	note -5, 0
	snd_endloop
	snd_loop 2
	rest 1
	pan PAN_L
	note -3, 0
	pan PAN_R
	note -3, 0
	snd_endloop
	rest 1
	pan PAN_LR
	instrument 7
	volume 13
	snd_ret
Sub_5E46:
	pan PAN_L
	note -5, 0
	note -3, 0
	pan PAN_R
	note -5, 0
	note -3, 0
	snd_ret
Sub_5E4F:
	pan PAN_L
	note -1, 0
	note 0, 0
	pan PAN_R
	note -1, 0
	note -5, 0
	snd_ret
Sub_5E58:
	note -7, 0
	note -7, 0
	rest 0
	note -7, 0
	note -7, 1
	snd_ret
Song05_CH4:
	length_set 4
	pan PAN_LR
	gate 255
	instrument 16
	volume 9
	drest 1
Seq_5E69:
	snd_loop 2
	snd_loop 3
	drum 2, 1
	drum 4, 0
	drum 4, 0
	snd_endloop
	drum 1, 0
	drum 1, 0
	drum 4, 0
	drum 4, 0
	drum 0, 1
	drum 4, 0
	drum 4, 0
	drum 1, 0
	drum 1, 0
	drum 4, 0
	drum 4, 0
	volume_add 2
	drum_x 3, 48
	volume_add -2
	snd_endloop
	snd_loop 14
	drum 3, 0
	volume_add -3
	drum 4, 0
	volume_add 3
	drum 4, 0
	drum 2, 0
	snd_endloop
	drum_x 3, 48
	snd_jump Seq_5E69
Song06_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	base_note $20
	volume 15
	gate 255
	snd_call Sub_5EC4
	snd_call Sub_5EDC
	snd_call Sub_5EC4
	snd_call Sub_5EE5
Seq_5EAB:
	snd_loop 4
	snd_call Sub_5EEC
	snd_endloop
	snd_call Sub_5F06
	snd_call Sub_5F06
	base_note $23
	snd_call Sub_5F06
	base_note $20
	snd_call Sub_5F1D
	snd_jump Seq_5EAB
Sub_5EC4:
	note -12, 0
	note -5, 0
	note 0, 0
	rest 0
	note -12, 0
	note 0, 0
	rest 0
	note -10, 1
	note -3, 0
	note 2, 0
	rest 0
	note -10, 0
	note 2, 0
	rest 0
	note -3, 0
	note -8, 0
	note -1, 0
	note 4, 0
	rest 0
	note -8, 0
	note 4, 0
	rest 0
	note -1, 0
	snd_ret
Sub_5EDC:
	note -10, 0
	note -3, 0
	note 2, 0
	rest 0
	note -10, 0
	note 2, 0
	rest 0
	note -3, 0
	snd_ret
Sub_5EE5:
	note 2, 0
	note 2, 0
	rest 1
	note 7, 0
	note 7, 0
	rest 1
	snd_ret
Sub_5EEC:
	note -12, 0
	rest 0
	note -12, 0
	rest 0
	note -5, 2
	note -10, 0
	rest 0
	note -10, 0
	rest 0
	note -10, 0
	note -3, 1
	note -10, 0
	note -9, 0
	note -8, 0
	rest 0
	note -8, 0
	rest 0
	note -1, 2
	note -10, 0
	rest 0
	note -10, 0
	rest 0
	note -10, 0
	note -3, 1
	note -10, 1
	snd_ret
Sub_5F06:
	note -7, 0
	rest 0
	note -7, 2
	note 5, 1
	note -7, 0
	rest 0
	note -7, 0
	rest 0
	note 0, 0
	note 9, 1
	note 0, 1
	note -8, 0
	rest 0
	note -8, 2
	note 4, 1
	note -8, 0
	rest 0
	note -8, 0
	rest 0
	note -1, 0
	note 7, 1
	note -1, 1
	snd_ret
Sub_5F1D:
	note -4, 0
	rest 0
	note -4, 2
	note 3, 1
	note -4, 0
	rest 0
	note -4, 0
	rest 0
	note 3, 0
	note 8, 1
	note 3, 1
	note -5, 0
	rest 0
	note 7, 1
	note -5, 0
	note 7, 0
	rest 0
	note -5, 0
	rest 0
	note -5, 0
	rest 0
	note 5, 0
	note 7, 1
	note -5, 1
	snd_ret
Song06_CH1:
	length_set 3
	pan PAN_LR
	instrument 21
	gate 250
	volume 11
	base_note $2C
	snd_call Sub_5F76
	snd_call Sub_5F8C
	snd_call Sub_5F76
	snd_call Sub_5F96
Seq_5F4E:
	gate 0
	instrument 13
	volume 10
	base_note $2C
	snd_call Sub_5FA1
	volume 13
	instrument 21
	note 4, 2
	volume_add -6
	snd_call Sub_5FBE
	note 0, 0
	note 2, 0
	rest 0
	note 4, 1
	instrument 17
	volume_add -6
	note -3, 0
	note 4, 0
	snd_call Sub_5FBE
	snd_call Sub_5FDD
	snd_jump Seq_5F4E
Sub_5F76:
	rest 1
	note -1, 1
	rest 0
	volume_add 1
	note -1, 1
	volume_add -1
	rest 2
	note 0, 1
	rest 0
	volume_add 1
	note 0, 1
	rest 2
	note 2, 1
	rest 0
	volume_add -1
	note 2, 1
	rest 0
	snd_ret
Sub_5F8C:
	rest 1
	note 0, 1
	rest 0
	volume_add -1
	note 0, 1
	volume_add 1
	rest 0
	snd_ret
Sub_5F96:
	note 0, 0
	volume_add -2
	note 0, 0
	volume_add 2
	rest 1
	note 0, 0
	note 0, 0
	rest 1
	snd_ret
Sub_5FA1:
	note_x 6, 2
	note_x 7, 194
	note 5, 1
	note 4, 0
	note 7, 2
	note_x -1, 2
	note_x 0, 180
	note -5, 1
	note 0, 0
	note_x 6, 2
	note_x 7, 201
	note 4, 1
	note 5, 0
	note 7, 2
	note_x 12, 97
	note_x 5, 1
	note_x 6, 2
	note_x 7, 110
	snd_ret
Sub_5FBE:
	instrument 17
	snd_loop 4
	note -3, 0
	note 4, 0
	snd_endloop
	note -3, 0
	instrument 21
	volume_add 6
	note 2, 0
	rest 0
	note 0, 0
	note 2, 1
	volume_add -6
	instrument 17
	snd_loop 5
	note -5, 0
	note 2, 0
	snd_endloop
	note -5, 0
	instrument 21
	volume_add 6
	snd_ret
Sub_5FDD:
	note 4, 0
	rest 0
	note 5, 0
	note 7, 1
	volume_add -6
	instrument 17
	snd_loop 5
	note 0, 0
	note 7, 0
	snd_endloop
	note 0, 0
	volume_add 6
	instrument 21
	note 5, 0
	rest 0
	note 3, 0
	note 5, 1
	volume_add -6
	instrument 17
	snd_loop 5
	note -2, 0
	note 5, 0
	snd_endloop
	instrument 14
	volume_add 6
	note -2, 0
	note 3, 0
	note 5, 0
	rest 0
	note_x 7, 91
	note 12, 2
	note_x 6, 2
	note_x 7, 89
	note -5, 0
	note 0, 2
	snd_ret
Song06_CH2:
	length_set 3
	pan PAN_LR
	volume 11
	instrument 21
	gate 255
	base_note $2C
	snd_call Sub_6054
	snd_call Sub_606A
	snd_call Sub_6054
	snd_call Sub_6074
Seq_6026:
	instrument 11
	gate 190
	volume 10
	snd_loop 4
	snd_call Sub_607F
	snd_endloop
	volume 12
	pan PAN_LR
	instrument 21
	note 0, 2
	volume_add -6
	snd_call Sub_60AC
	note -3, 0
	note -1, 0
	rest 0
	note 0, 1
	instrument 17
	volume_add -6
	note -7, 0
	note 0, 0
	snd_call Sub_60AC
	note -1, 0
	rest 0
	note 2, 0
	snd_call Sub_60CB
	snd_jump Seq_6026
Sub_6054:
	rest 1
	note -8, 1
	rest 0
	volume_add 1
	note -8, 1
	volume_add -1
	rest 2
	note -7, 1
	rest 0
	volume_add 1
	note -7, 1
	rest 2
	note -5, 1
	volume_add -1
	rest 0
	note -5, 1
	rest 0
	snd_ret
Sub_606A:
	rest 1
	note -7, 1
	rest 0
	volume_add -1
	note -7, 1
	volume_add 1
	rest 0
	snd_ret
Sub_6074:
	note -7, 0
	volume_add -2
	note -7, 0
	volume_add 2
	rest 1
	note -7, 0
	note -7, 0
	rest 1
	snd_ret
Sub_607F:
	pan PAN_L
	note -8, 0
	note -5, 0
	note -1, 0
	note -5, 0
	note -8, 0
	note -5, 0
	note -1, 0
	note -5, 0
	pan PAN_R
	note -7, 0
	note -3, 0
	note 0, 0
	note -3, 0
	note -7, 0
	note -3, 0
	note 0, 0
	note -3, 0
	pan PAN_L
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	pan PAN_R
	note -7, 0
	note -3, 0
	note 0, 0
	pan PAN_L
	note -7, 0
	note -3, 0
	note 0, 0
	pan PAN_R
	note -7, 0
	note -3, 0
	snd_ret
Sub_60AC:
	snd_loop 4
	instrument 17
	note -7, 0
	note 0, 0
	snd_endloop
	note -7, 0
	instrument 21
	volume_add 6
	note -1, 0
	rest 0
	note -3, 0
	note -1, 1
	instrument 17
	volume_add -6
	note -8, 0
	snd_loop 5
	note -1, 0
	note -8, 0
	snd_endloop
	instrument 21
	volume_add 6
	snd_ret
Sub_60CB:
	note 3, 1
	volume_add -6
	instrument 17
	snd_loop 5
	note -4, 0
	note 3, 0
	snd_endloop
	note -4, 0
	volume_add 6
	instrument 21
	note 2, 0
	rest 0
	note 0, 0
	note 2, 1
	volume_add -6
	instrument 17
	snd_loop 7
	note -5, 0
	note 2, 0
	snd_endloop
	volume_add 1
	note -5, 0
	volume_add 1
	snd_loop 5
	note -4, 0
	note 0, 0
	note 3, 0
	snd_endloop
	note -4, 0
	note 5, 0
	note 2, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	note -5, 0
	snd_loop 4
	note -7, 0
	note -5, 0
	snd_endloop
	snd_ret
Song06_CH4:
	length_set 3
	pan PAN_LR
	volume 9
	gate 255
	instrument 16
	snd_loop 7
	snd_call Sub_613A
	snd_endloop
	snd_call Sub_6135
Seq_6114:
	snd_loop 2
	snd_loop 12
	snd_call Sub_612C
	snd_endloop
	snd_call Sub_614B
	snd_endloop
	snd_loop 14
	snd_call Sub_613A
	snd_endloop
	snd_call Sub_614B
	snd_jump Seq_6114
Sub_612C:
	drum 6, 0
	volume_add -3
	drum 6, 0
	volume_add 3
	drum 5, 0
	drum 6, 0
	snd_ret
Sub_6135:
	drum 5, 0
	drum 5, 2
	drum 5, 0
	drum 5, 2
	snd_ret
Sub_613A:
	drum 6, 0
	volume_add -2
	drum 7, 0
	drum 7, 0
	drum 7, 0
	volume_add 2
	drum 4, 0
	volume_add -2
	drum 7, 0
	drum 7, 0
	drum 7, 0
	volume_add 2
	snd_ret
Sub_614B:
	drum 5, 0
	drum 7, 0
	drum 5, 0
	drum 7, 0
	drum 5, 0
	drum 7, 0
	drum 7, 0
	volume_add 1
	drum 5, 0
	drum 7, 0
	drum 4, 0
	drum 4, 0
	drum 7, 0
	drum 4, 0
	drum 5, 0
	drum 6, 0
	drum 7, 0
	volume_add -1
	snd_ret
Song07_CH1:
	length_set 3
	pan PAN_L
	instrument 20
Seq_6166:
	gate 240
	base_note $33
	volume 11
	note 0, 0
	rest 0
	note -1, 0
	note -2, 0
	rest 0
	note -3, 0
	note -4, 0
	rest 0
	note -9, 2
	note -4, 0
	note -5, 0
	rest 4
	gate 0
	note_x 6, 2
	note_x 7, 6
	rest 0
	snd_end
Song07_CH2:
	length_set 3
	pan PAN_R
	instrument 22
	snd_jump Seq_6166
Song07_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $33
	note -12, 0
	rest 0
	note -5, 0
	note 4, 0
	rest 0
	note 0, 0
	note -4, 0
	note -9, 0
	note -4, 0
	note 0, 1
	note -4, 0
	note -5, 0
	rest 0
	snd_end
Song08_CH3:
	length_set 1
	pan PAN_LR
	instrument 0
	gate 0
	volume 0
	base_note $20
	note_x -1, 10
	snd_loop 14
	volume_add 1
	hold 5
	snd_endloop
	gate 250
	volume 15
	instrument 7
	note -5, 0
	note -5, 0
	rest 3
	note -5, 0
	note -5, 0
	rest 3
	note -5, 0
	note -5, 0
	rest 1
Seq_61C7:
	snd_loop 2
	instrument 7
	gate 255
	base_note $20
	note -3, 2
	note -3, 0
	note -3, 1
	note -3, 1
	rest 1
	note 9, 1
	rest 1
	note 7, 3
	note -5, 1
	note -5, 0
	note 7, 0
	note 7, 1
	note_x -5, 40
	note -6, 2
	note 6, 0
	note -6, 1
	note 6, 1
	rest 1
	note 6, 0
	rest 0
	note -6, 1
	note 6, 1
	note -7, 0
	note 5, 0
	note -7, 0
	note 5, 0
	note -7, 1
	note 5, 1
	rest 1
	note -7, 0
	rest 0
	note -5, 3
	snd_endloop
	snd_loop 4
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	snd_endloop
	snd_loop 4
	note -10, 0
	note -10, 0
	note 2, 0
	note -3, 0
	snd_endloop
	snd_loop 4
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	snd_endloop
	snd_loop 2
	note -10, 0
	note -10, 0
	note 2, 0
	note -3, 0
	snd_endloop
	note -8, 0
	note -8, 0
	note 4, 0
	note -8, 0
	note -8, 0
	note 4, 0
	note -8, 0
	note -5, 0
	snd_jump Seq_61C7
Song08_CH1:
	length_set 1
	pan PAN_LR
	gate 0
	instrument 20
	volume 1
	base_note $20
	note_x 7, 10
	snd_loop 14
	volume_add 1
	hold 5
	snd_endloop
	instrument 21
	gate 250
	note 11, 0
	note 11, 0
	rest 3
	note 11, 0
	note 11, 0
	rest 3
	note 11, 0
	note 11, 0
	rest 1
Seq_623A:
	snd_loop 2
	instrument 19
	gate 255
	volume 12
	base_note $2C
	snd_loop 8
	note 0, 0
	note -8, 0
	volume_add -3
	note 0, 0
	note -8, 0
	volume_add 3
	snd_endloop
	snd_loop 4
	note 0, 0
	note -6, 0
	volume_add -3
	note 0, 0
	note -6, 0
	volume_add 3
	snd_endloop
	instrument 25
	volume 13
	snd_loop 4
	note 0, 0
	note -7, 0
	snd_endloop
	rest 0
	volume 12
	gate 245
	instrument 19
	note -7, 0
	snd_loop 3
	note 0, 0
	note -7, 0
	snd_endloop
	volume_add -1
	snd_endloop
	snd_loop 4
	note 2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	snd_endloop
	snd_loop 4
	note 0, 0
	note -3, 0
	note -7, 0
	note -3, 0
	snd_endloop
	snd_loop 4
	note 2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	snd_endloop
	snd_loop 2
	note 2, 0
	note -3, 0
	note -7, 0
	note -3, 0
	snd_endloop
	volume_add 1
	instrument 24
	note -8, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note 0, 0
	note 2, 0
	volume_add -1
	snd_jump Seq_623A
Song08_CH2:
	length_set 1
	pan PAN_LR
	volume 1
	base_note $20
	gate 0
	instrument 20
	note_x 2, 10
	snd_loop 14
	volume_add 1
	hold 5
	snd_endloop
	gate 250
	instrument 21
	note 4, 0
	note 4, 0
	rest 3
	note 4, 0
	note 4, 0
	rest 3
	note 4, 0
	note 4, 0
	rest 1
Seq_62C2:
	snd_loop 2
	instrument 19
	volume 12
	gate 255
	base_note $2C
	snd_loop 8
	note -5, 0
	note -12, 0
	volume_add -3
	note -5, 0
	note -12, 0
	volume_add 3
	snd_endloop
	snd_loop 4
	note -3, 0
	note -10, 0
	volume_add -3
	note -3, 0
	note -10, 0
	volume_add 3
	snd_endloop
	instrument 25
	volume 13
	snd_loop 4
	note -3, 0
	note -12, 0
	snd_endloop
	volume 12
	rest 0
	instrument 19
	gate 245
	note -12, 0
	snd_loop 3
	note -3, 0
	note -12, 0
	snd_endloop
	volume_add -1
	snd_endloop
	snd_loop 4
	note -1, 0
	note -5, 0
	note -8, 0
	note -5, 0
	snd_endloop
	snd_loop 4
	note -3, 0
	note -7, 0
	note -10, 0
	note -7, 0
	snd_endloop
	snd_loop 4
	note -1, 0
	note -5, 0
	note -8, 0
	note -5, 0
	snd_endloop
	snd_loop 2
	note -3, 0
	note -7, 0
	note -10, 0
	note -7, 0
	snd_endloop
	note -13, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -1, 0
	note 0, 0
	note 2, 0
	snd_jump Seq_62C2
Song08_CH4:
	length_set 1
	pan PAN_LR
	volume 3
	instrument 16
	gate 170
	snd_loop 2
	drum 4, 0
	drum 6, 0
	drum 6, 0
	drum 6, 0
	snd_endloop
	volume 9
	snd_loop 4
	drum 6, 0
	drum 6, 0
	snd_endloop
	pan PAN_LR
	drum 4, 0
	drum 4, 0
	drest 3
	drum 4, 0
	drum 4, 0
	drest 3
	drum 4, 0
	drum 4, 0
	drest 1
Seq_6345:
	snd_loop 16
	gate 225
	volume 10
	instrument 16
	pan PAN_L
	volume 11
	drum 2, 0
	volume_add -3
	drum 2, 0
	volume_add 4
	drum 5, 0
	volume_add -2
	drum 2, 0
	pan PAN_R
	volume_add 1
	drum 2, 0
	volume_add -3
	drum 2, 0
	volume_add 4
	drum 5, 0
	volume_add -2
	drum 2, 0
	volume_add 1
	snd_endloop
	pan PAN_LR
	snd_loop 7
	instrument 26
	drum 2, 0
	volume_add -2
	drum 2, 0
	volume_add -2
	instrument 0
	drum 2, 1
	volume_add 6
	instrument 16
	drum 6, 0
	volume_add -4
	instrument 26
	drum 2, 0
	volume_add -2
	instrument 0
	drum 2, 1
	volume_add 4
	snd_endloop
	instrument 26
	snd_loop 6
	drum 7, 0
	snd_endloop
	instrument 16
	volume_add 4
	drum 10, 1
	volume_add -4
	snd_jump Seq_6345
Song09_CH3:
	length_set 1
	pan PAN_LR
	instrument 7
	volume 15
	gate 127
	base_note $17
	snd_loop 3
	snd_call Sub_63CB
	snd_endloop
	snd_call Sub_63D4
	snd_call Sub_63CB
	snd_call Sub_63E6
	snd_call Sub_63F5
	base_note $15
	snd_call Sub_63F5
	base_note $17
	snd_call Sub_63F5
	snd_call Sub_6407
	snd_jump Song09_CH3
Sub_63CB:
	note -3, 1
	note -3, 1
	note 4, 1
	note -3, 1
	note 6, 1
	note 7, 1
	note -5, 1
	note -8, 1
	snd_ret
Sub_63D4:
	note -3, 1
	gate 210
	note -3, 0
	volume_add -2
	note -3, 0
	volume_add 2
	gate 127
	note 4, 1
	note -3, 1
	note 6, 1
	note 7, 1
	note -5, 1
	note -8, 1
	snd_ret
Sub_63E6:
	note -7, 1
	note -7, 1
	note 5, 1
	note -7, 1
	gate 250
	note 4, 1
	note 5, 0
	rest 0
	note -1, 1
	note 0, 0
	rest 0
	gate 127
	snd_ret
Sub_63F5:
	note -8, 1
	note -8, 1
	note 4, 1
	note -8, 1
	gate 250
	note -8, 0
	volume_add -3
	note 4, 0
	volume_add 3
	gate 127
	note -8, 1
	note 4, 1
	note -8, 1
	snd_ret
Sub_6407:
	gate 90
	note -5, 1
	gate 250
	note 7, 1
	gate 120
	note 6, 1
	note 5, 1
	note 3, 1
	note 0, 1
	gate 240
	note -5, 1
	note -2, 1
	snd_ret
Song09_CH1:
	length_set 1
	pan PAN_LR
	volume 12
	instrument 23
	base_note $17
	gate 127
	snd_call Sub_63CB
	snd_call Sub_63CB
	base_note $23
	snd_call Sub_6455
	note_x -3, 7
	rest_x 43
	snd_call Sub_6455
	note_x 2, 7
	rest_x 43
	instrument 19
	volume 13
	snd_call Sub_6475
	base_note $21
	snd_call Sub_6475
	base_note $23
	snd_call Sub_6475
	instrument 23
	volume 12
	snd_call Sub_6407
	snd_jump Song09_CH1
Sub_6455:
	rest 1
	gate 0
	note_x 2, 3
	gate 230
	note_x 3, 7
	gate 127
	note 4, 1
	note 7, 1
	gate 244
	note 4, 1
	note 3, 0
	rest 0
	gate 127
	note 2, 1
	gate 250
	note -5, 1
	gate 120
	note -3, 1
	note -3, 1
	gate 250
	note 0, 1
	snd_ret
Sub_6475:
	gate 150
	note 2, 1
	note 7, 1
	rest 1
	note 2, 1
	note 7, 1
	rest 1
	gate 220
	note 2, 1
	gate 130
	note 7, 1
	snd_ret
Song09_CH2:
	length_set 1
	pan PAN_LR
	gate 120
	volume 5
	instrument 5
	base_note $3B
	snd_call Sub_64C1
	snd_call Sub_64C1
	instrument 23
	volume 10
	base_note $2F
	pan PAN_LR
	snd_call Sub_6455
	note_x -3, 7
	rest_x 43
	snd_call Sub_6455
	note_x 2, 7
	rest_x 43
	instrument 19
	volume 12
	base_note $23
	snd_call Sub_64D4
	base_note $3B
	instrument 23
	volume 10
	snd_call Sub_6407
	snd_jump Song09_CH2
Sub_64C1:
	rest 1
	pan PAN_L
	note 7, 1
	pan PAN_R
	note 7, 1
	rest 1
	pan PAN_L
	note 6, 1
	pan PAN_R
	note 7, 1
	rest 1
	pan PAN_LR
	note 7, 1
	snd_ret
Sub_64D4:
	gate 150
	note -1, 1
	note 2, 1
	rest 1
	note -1, 1
	note 2, 1
	rest 1
	gate 220
	note -1, 1
	gate 130
	note 2, 1
	gate 150
	note -3, 1
	note 0, 1
	rest 1
	note -3, 1
	note 0, 1
	rest 1
	gate 220
	note -3, 1
	gate 130
	note 0, 1
	gate 150
	note -4, 1
	note -4, 1
	rest 1
	note -4, 1
	note -4, 1
	rest 1
	gate 220
	note -4, 1
	gate 130
	note -4, 1
	snd_ret
Song09_CH4:
	length_set 1
	instrument 16
	volume 9
	gate 255
	snd_loop 4
	snd_loop 3
	pan PAN_L
	drum 3, 1
	volume_add -3
	drum 3, 1
	volume_add 6
	pan PAN_LR
	drum 6, 1
	pan PAN_L
	volume_add -4
	drum 3, 1
	volume_add 1
	snd_endloop
	pan PAN_L
	drum 3, 0
	volume_add -3
	drum 3, 0
	drum 3, 1
	volume_add 6
	pan PAN_LR
	drum 6, 1
	volume_add -4
	pan PAN_L
	drum 3, 1
	volume_add 1
	snd_endloop
	pan PAN_L
	drum 3, 1
	volume_add -3
	drum 3, 1
	volume_add 6
	pan PAN_LR
	drum 6, 1
	volume_add -4
	pan PAN_L
	drum 3, 1
	volume_add 1
	drum 3, 0
	volume_add -3
	drum 3, 0
	drum 3, 0
	drum 3, 0
	volume_add 6
	pan PAN_LR
	drum 6, 1
	volume_add -4
	pan PAN_L
	drum 3, 0
	drum 3, 0
	volume_add 4
	pan PAN_LR
	drest 1
	drum 6, 1
	drum 6, 1
	drum 6, 1
	volume_add -3
	snd_loop 4
	drum 6, 0
	drum 6, 0
	volume_add 1
	snd_endloop
	snd_jump Song09_CH4
Song10_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	snd_call Sub_6591
	note 0, 1
	note -5, 0
	note -8, 2
	snd_call Sub_6591
	note 0, 2
	note -8, 2
	snd_call Sub_6591
	note 0, 1
	note -5, 0
	note -8, 1
	note 7, 0
	note 5, 1
	note 4, 0
	note 2, 1
	note 4, 0
	note 0, 2
	note_x 12, 10
	rest_x 11
	snd_end
Sub_6591:
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -3, 0
	note -1, 0
	snd_ret
Song10_CH2:
	length_set 3
	instrument 10
	pan PAN_LR
	gate 255
	volume 11
	base_note $33
	snd_call Sub_65C2
	note -8, 2
	note -12, 1
	note -5, 0
	snd_call Sub_65C2
	note -8, 1
	note -7, 0
	note -5, 1
	note -12, 0
	snd_call Sub_65C2
	note -8, 2
	note -12, 1
	note 4, 0
	note 2, 1
	note -1, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -8, 2
	note_x 4, 10
	rest_x 11
	snd_end
Sub_65C2:
	note -12, 0
	note -10, 0
	note -7, 0
	note -7, 0
	note -7, 0
	note -7, 0
	snd_ret
Song10_CH3:
	length_set 3
	instrument 7
	pan PAN_LR
	volume 15
	gate 255
	base_note $27
	note 2, 1
	note 2, 0
	note 7, 1
	note 7, 0
	note 0, 2
	note 0, 1
	note 7, 0
	note 5, 1
	note 5, 0
	note 7, 1
	note 7, 0
	note 0, 1
	note 7, 0
	note 0, 2
	note 2, 1
	note 2, 0
	note 7, 1
	note 7, 0
	note 0, 1
	note -12, 0
	note -12, 1
	note 0, 0
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -3, 0
	note -1, 0
	note 0, 1
	base_note $1B
	note -5, 0
	note -12, 0
	rest 1
	snd_end
Song10_CH4:
	length_set 3
	volume 10
	instrument 16
	gate 235
	snd_loop 7
	drum 6, 1
	drum 6, 0
	drum 6, 0
	volume_add -4
	drum 3, 0
	volume_add 4
	drum 6, 0
	snd_endloop
	drum 3, 0
	drum 3, 0
	drum 3, 0
	drum 3, 0
	drest 1
	snd_end
Song11_CH3:
	length_set 4
	volume 15
	instrument 7
	pan PAN_LR
	gate 255
	base_note $1B
	snd_call Sub_6657
Seq_6621:
	snd_call Sub_6668
	snd_call Sub_6671
	snd_call Sub_6668
	snd_call Sub_667A
	snd_call Sub_6683
	snd_call Sub_6694
	snd_call Sub_6668
	snd_call Sub_6671
	snd_call Sub_6668
	snd_call Sub_667A
	snd_call Sub_6683
	snd_call Sub_66A6
	snd_call Sub_66B8
	snd_call Sub_6700
	snd_call Sub_6715
	snd_call Sub_6700
	snd_call Sub_671E
	snd_jump Seq_6621
Sub_6657:
	note -10, 1
	note -3, 1
	note -10, 1
	note 2, 1
	note -8, 1
	note -1, 1
	note -8, 1
	note 4, 1
	note -7, 1
	note 0, 1
	note -7, 1
	note 5, 1
	note -5, 0
	rest 2
	note -5, 0
	rest 2
	snd_ret
Sub_6668:
	note 0, 1
	note 12, 1
	note 0, 1
	note 12, 1
	note -1, 1
	note 11, 1
	note -1, 1
	note 11, 1
	snd_ret
Sub_6671:
	note -3, 1
	note 9, 1
	note -3, 1
	note 9, 1
	note -7, 1
	note 5, 1
	note -5, 1
	note 7, 1
	snd_ret
Sub_667A:
	note -2, 1
	note 10, 1
	note -2, 1
	note 10, 1
	note -3, 1
	note 9, 1
	note -3, 1
	note 9, 1
	snd_ret
Sub_6683:
	note -10, 1
	note 2, 1
	note -10, 1
	note 2, 1
	note -5, 1
	note 7, 1
	note -5, 1
	note 7, 1
	note -12, 1
	note 0, 1
	note -12, 1
	note 0, 1
	note -7, 1
	note 5, 1
	note -7, 1
	note 5, 1
	snd_ret
Sub_6694:
	snd_loop 4
	note -10, 1
	note 2, 1
	snd_endloop
	note -5, 1
	note 7, 1
	note -5, 1
	note 7, 1
	gate 120
	note 7, 1
	note 2, 1
	note -1, 1
	note -3, 1
	gate 255
	snd_ret
Sub_66A6:
	snd_loop 3
	note -4, 1
	note -4, 0
	note 8, 0
	snd_endloop
	note -4, 0
	note -4, 0
	note 8, 0
	note -4, 0
	snd_loop 4
	note -5, 0
	note -5, 0
	note 7, 0
	note -5, 0
	snd_endloop
	snd_ret
Sub_66B8:
	note -3, 1
	note 9, 0
	note 4, 0
	note -3, 0
	note -3, 0
	note 9, 0
	note 4, 0
	note -5, 1
	note 7, 0
	note 2, 0
	note -5, 0
	note -5, 0
	note 7, 0
	note 2, 0
	note -6, 1
	note 6, 0
	note -6, 0
	note -6, 0
	note -6, 0
	note 6, 0
	note -6, 0
	note -5, 1
	note 7, 0
	note 2, 0
	note -5, 0
	note 7, 0
	note 2, 0
	note 7, 0
	note -3, 0
	note -3, 0
	note 9, 0
	note 4, 0
	note -3, 0
	note -3, 0
	note 9, 0
	note 4, 0
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	snd_loop 4
	note -10, 0
	volume_add -3
	note -10, 0
	volume_add 3
	note 2, 0
	volume_add -2
	note -3, 0
	volume_add 2
	snd_endloop
	instrument 0
	note_x -3, 144
	instrument 7
	note 7, 0
	note 7, 0
	rest 1
	note 7, 0
	note 7, 0
	note 7, 1
	snd_ret
Sub_6700:
	note -10, 1
	note 2, 0
	note -3, 0
	note -10, 1
	note 2, 0
	note -3, 0
	note -8, 1
	note 4, 0
	note -1, 0
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	note -7, 1
	note 5, 0
	note 0, 0
	note -7, 0
	note -7, 0
	note 5, 0
	note 0, 0
	snd_ret
Sub_6715:
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	note -8, 0
	note -8, 0
	note 4, 0
	note -1, 0
	snd_ret
Sub_671E:
	gate 160
	note_x 7, 16
	note_x 7, 16
	note_x 7, 16
	gate 255
	snd_ret
Song11_CH1:
	length_set 4
	pan PAN_LR
	snd_call Sub_6765
	snd_call Sub_6777
Seq_6733:
	volume 12
	instrument 19
	base_note $27
	snd_call Sub_678D
	snd_call Sub_67B8
	note -3, 2
	rest 0
	snd_call Sub_67CA
	snd_call Sub_678D
	snd_call Sub_67B8
	note -3, 2
	note 0, 0
	snd_call Sub_67E9
	volume 13
	instrument 18
	snd_call Sub_67F9
	snd_call Sub_6765
	snd_call Sub_681A
	snd_call Sub_6765
	snd_call Sub_681E
	snd_jump Seq_6733
Sub_6765:
	gate 245
	base_note $1B
	volume 13
	instrument 25
	note 2, 3
	note 0, 2
	note 2, 0
	note 4, 3
	note 2, 2
	note 4, 0
	note 5, 3
	note 4, 2
	note 5, 0
	snd_ret
Sub_6777:
	gate 0
	note_x 7, 12
	volume_add -3
	snd_loop 6
	detune 3
	hold 1
	detune 4
	hold 1
	snd_endloop
	volume_add 3
	note -5, 0
	rest 2
	snd_ret
Sub_678D:
	gate 245
	note -5, 3
	note 0, 2
	note 2, 0
	gate 120
	note 4, 1
	note 2, 1
	note 4, 1
	note 5, 1
	gate 245
	note 7, 3
	note 4, 2
	note 7, 0
	gate 255
	note 0, 3
	note 2, 3
	gate 245
	note -5, 3
	note 0, 2
	note 2, 0
	gate 120
	note 4, 1
	note 2, 1
	note 4, 1
	note 5, 1
	gate 250
	note 7, 3
	note 9, 2
	note 7, 0
	gate 220
	note 5, 1
	note 4, 1
	note 2, 1
	note 4, 1
	snd_ret
Sub_67B8:
	gate 250
	note 5, 3
	note 4, 2
	note 5, 0
	gate 140
	note 7, 1
	note 5, 1
	note 4, 1
	note 7, 1
	gate 246
	note 4, 3
	note 0, 2
	note 2, 0
	note 4, 3
	snd_ret
Sub_67CA:
	note 2, 3
	note 4, 2
	note 2, 0
	gate 128
	note 2, 1
	note 0, 1
	note -1, 1
	note 0, 1
	gate 0
	note_x 2, 24
	volume_add -5
	snd_loop 12
	detune -2
	hold 2
	snd_endloop
	volume_add 5
	gate 128
	note 7, 1
	note 2, 1
	note -1, 1
	note -3, 1
	snd_ret
Sub_67E9:
	gate 253
	note 7, 3
	note 7, 2
	note 7, 0
	gate 130
	note 7, 1
	note 5, 1
	note 3, 1
	note 5, 1
	gate 0
	note_x 7, 96
	snd_ret
Sub_67F9:
	note 9, 3
	note 1, 2
	note 2, 0
	note 4, 5
	note 1, 0
	note 2, 0
	note 4, 3
	note 1, 2
	note 2, 0
	note 1, 3
	note -1, 1
	note -3, 0
	note -1, 0
	note 1, 3
	note 4, 2
	note 1, 0
	note 1, 3
	note -1, 3
	note_x -3, 96
	note_x -3, 144
	instrument 23
	volume 13
	note 2, 0
	note 2, 0
	rest 1
	note 2, 0
	note 2, 0
	note 2, 1
	snd_ret
Sub_681A:
	note 4, 3
	note 2, 2
	note 4, 0
	snd_ret
Sub_681E:
	gate 160
	note_x 7, 16
	note_x 7, 16
	note_x 7, 16
	snd_ret
Song11_CH2:
	length_set 4
	pan PAN_LR
	base_note $1B
	volume 11
	snd_call Sub_6893
	snd_call Sub_68A1
Seq_6835:
	instrument 10
	base_note $1B
	volume 9
	gate 255
	snd_loop 3
	snd_call Sub_68B7
	snd_endloop
	snd_call Sub_68C0
	snd_call Sub_68B7
	snd_call Sub_68B7
	snd_call Sub_68C9
	base_note $27
	instrument 6
	snd_call Sub_68DA
	snd_call Sub_68FB
	instrument 10
	base_note $1B
	snd_loop 3
	snd_call Sub_68B7
	snd_endloop
	snd_call Sub_68C0
	snd_call Sub_68B7
	snd_call Sub_68B7
	snd_call Sub_68C9
	base_note $27
	instrument 6
	snd_call Sub_68DA
	instrument 19
	snd_call Sub_6913
	instrument 18
	volume 11
	snd_call Sub_6926
	volume 11
	snd_call Sub_6893
	snd_call Sub_694B
	snd_call Sub_6893
	snd_call Sub_694F
	snd_jump Seq_6835
Sub_6893:
	gate 245
	instrument 25
	note -7, 3
	note -7, 2
	note -7, 0
	note -5, 3
	note -5, 2
	note -5, 0
	note -3, 3
	note -3, 2
	note -3, 0
	snd_ret
Sub_68A1:
	gate 0
	note_x -1, 12
	volume_add -3
	snd_loop 6
	detune 3
	hold 1
	detune 4
	hold 1
	snd_endloop
	volume_add 3
	note -13, 0
	rest 2
	snd_ret
Sub_68B7:
	note -5, 0
	note 0, 0
	note 4, 0
	note 0, 0
	note -5, 0
	note 0, 0
	note 4, 0
	note 0, 0
	snd_ret
Sub_68C0:
	note -7, 0
	note -3, 0
	note 0, 0
	note -3, 0
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	snd_ret
Sub_68C9:
	note -5, 0
	note 2, 0
	note 5, 0
	note 2, 0
	note -5, 0
	note 2, 0
	note 5, 0
	note 2, 0
	note -5, 0
	note 1, 0
	note 4, 0
	note 1, 0
	note -5, 0
	note 1, 0
	note 4, 0
	note 1, 0
	snd_ret
Sub_68DA:
	note -10, 0
	note -7, 0
	note 0, 0
	note -7, 0
	note -10, 0
	note -7, 0
	note 0, 0
	note -7, 0
	note -10, 0
	note -5, 0
	note -1, 0
	note -5, 0
	note -10, 0
	note -5, 0
	note -1, 0
	note -5, 0
	note -12, 0
	note -8, 0
	note -1, 0
	note -5, 0
	note -12, 0
	note -8, 0
	note -5, 0
	note -1, 0
	note -12, 0
	note -7, 0
	note -3, 0
	note -7, 0
	note -12, 0
	note -7, 0
	note -15, 0
	note -12, 0
	snd_ret
Sub_68FB:
	snd_loop 4
	note -10, 0
	note -7, 0
	note -3, 0
	note -7, 0
	snd_endloop
	note -10, 0
	note -7, 0
	note -1, 0
	note -7, 0
	note -10, 0
	note -7, 0
	note -1, 0
	note -7, 0
	gate 120
	note -5, 1
	note -10, 1
	note -13, 1
	note -15, 1
	gate 255
	snd_ret
Sub_6913:
	gate 253
	note 3, 3
	note 3, 2
	note 3, 0
	gate 130
	note 3, 1
	note 2, 1
	note 0, 1
	note 2, 1
	gate 250
	note 0, 3
	note 2, 2
	note 0, 0
	note -1, 3
	note -5, 3
	snd_ret
Sub_6926:
	note 1, 3
	note -3, 2
	note -1, 0
	note 1, 5
	note -3, 0
	note -1, 0
	note 1, 3
	note -3, 2
	note -1, 0
	note -7, 3
	note -7, 3
	note -3, 3
	note 1, 2
	note -3, 0
	note -8, 3
	note -8, 3
	note_x -6, 48
	note_x -7, 48
	note_x -10, 48
	note_x -13, 48
	note_x -11, 48
	instrument 23
	volume 13
	note -7, 0
	note -7, 0
	rest 1
	note -7, 0
	note -7, 0
	note -7, 1
	snd_ret
Sub_694B:
	note -5, 3
	note -5, 2
	note -5, 0
	snd_ret
Sub_694F:
	gate 160
	note_x -1, 16
	note_x -1, 16
	note_x -1, 16
	snd_ret
Song11_CH4:
	length_set 4
	volume 8
	gate 255
	pan PAN_LR
	snd_loop 6
	snd_call Sub_6990
	snd_endloop
	snd_call Sub_69A1
Seq_6969:
	snd_loop 30
	snd_call Sub_6990
	snd_endloop
	snd_call Sub_69A9
	snd_loop 30
	snd_call Sub_6990
	snd_endloop
	snd_call Sub_69C6
	snd_loop 16
	snd_call Sub_69B7
	snd_endloop
	snd_call Sub_69D6
	snd_loop 14
	snd_call Sub_6990
	snd_endloop
	snd_call Sub_69E7
	snd_jump Seq_6969
Sub_6990:
	instrument 26
	drum 3, 0
	volume_add -2
	drum 3, 0
	instrument 16
	volume_add 4
	drum 6, 0
	volume_add -2
	instrument 26
	drum 3, 0
	snd_ret
Sub_69A1:
	volume_add 2
	drum 6, 0
	drum 6, 2
	drum 6, 3
	volume_add -2
	snd_ret
Sub_69A9:
	volume_add 2
	drum 6, 1
	drum 6, 1
	drum 6, 0
	volume_add -5
	drum 6, 0
	volume_add 5
	drum 6, 1
	volume_add -2
	snd_ret
Sub_69B7:
	instrument 26
	drum 2, 0
	volume_add -2
	drum 2, 0
	volume_add 2
	drum 6, 0
	volume_add -2
	drum 2, 0
	volume_add 2
	snd_ret
Sub_69C6:
	instrument 26
	drum 3, 0
	volume_add -1
	drum 3, 0
	snd_loop 3
	volume_add 1
	drum 6, 0
	drum 6, 0
	snd_endloop
	volume_add -2
	snd_ret
Sub_69D6:
	instrument 4
	drum_x 4, 144
	volume_add 3
	instrument 16
	drum 5, 0
	drum 5, 2
	drum 5, 0
	drum 5, 0
	drum 5, 0
	volume_add -3
	drum 6, 0
	snd_ret
Sub_69E7:
	instrument 16
	volume_add 2
	drum_x 5, 16
	drum_x 5, 16
	drum_x 5, 16
	volume_add -2
	snd_ret
Song12_CH3:
	length_set 4
	volume 15
	instrument 7
	pan PAN_LR
	gate 255
	base_note $20
	snd_call Sub_6A2F
	base_note $1F
	snd_call Sub_6A2F
	base_note $20
	snd_call Sub_6A2F
	snd_call Sub_6A36
Seq_6A10:
	snd_loop 2
	base_note $20
	snd_call Sub_6A45
	base_note $21
	snd_call Sub_6A45
	snd_endloop
	base_note $1D
	snd_call Sub_6A45
	base_note $1C
	snd_call Sub_6A45
	base_note $14
	snd_call Sub_6A4C
	snd_jump Seq_6A10
Sub_6A2F:
	snd_loop 4
	note -12, 0
	rest 0
	note 0, 1
	snd_endloop
	snd_ret
Sub_6A36:
	note -13, 0
	rest 0
	note -1, 1
	note -13, 0
	rest 0
	note -1, 1
	note -1, 0
	rest 0
	note -1, 0
	rest 0
	note -1, 0
	note -1, 0
	note -1, 0
	rest 0
	snd_ret
Sub_6A45:
	snd_loop 8
	note -12, 1
	note 0, 0
	note -12, 0
	snd_endloop
	snd_ret
Sub_6A4C:
	snd_loop 2
	note -5, 1
	note 7, 0
	note -5, 0
	snd_endloop
	snd_loop 2
	note -7, 1
	note 5, 0
	note -7, 0
	snd_endloop
	snd_loop 2
	note -9, 1
	note 3, 0
	note -9, 0
	snd_endloop
	snd_loop 2
	note -4, 1
	note 8, 0
	note -4, 0
	snd_endloop
	snd_loop 6
	note -2, 1
	note 10, 0
	note -2, 0
	snd_endloop
	note -1, 0
	note -1, 0
	rest 1
	note -1, 0
	note -1, 0
	note -1, 1
	snd_ret
Song12_CH1:
	length_set 4
	instrument 4
	gate 222
	volume 9
	base_note $20
	snd_call Sub_6AC9
	base_note $1F
	snd_call Sub_6AC9
	base_note $20
	snd_call Sub_6AC9
	snd_call Sub_6AD3
Seq_6A8B:
	instrument 25
	volume 12
	base_note $2C
	pan PAN_LR
	snd_call Sub_6AEA
	snd_call Sub_6AFB
	snd_call Sub_6AEA
	snd_call Sub_6B12
Seq_6A9F:
	instrument 19
	volume 13
	gate 240
	snd_call Sub_6B2E
	base_note $2B
	snd_call Sub_6B2E
	base_note $20
	snd_call Sub_6B3F
	base_note $2C
	pan PAN_LR
	instrument 19
	volume 13
	snd_call Sub_6AEA
	snd_call Sub_6AFB
	snd_call Sub_6AEA
	snd_call Sub_6B12
	snd_jump Seq_6A9F
Sub_6AC9:
	snd_loop 8
	pan PAN_L
	note 4, 0
	pan PAN_R
	note 7, 0
	snd_endloop
	snd_ret
Sub_6AD3:
	snd_loop 4
	pan PAN_L
	note 3, 0
	pan PAN_R
	note 6, 0
	snd_endloop
	instrument 21
	volume 12
	pan PAN_L
	note 6, 0
	rest 0
	note 6, 0
	rest 0
	note 6, 0
	note 6, 0
	note 6, 1
	snd_ret
Sub_6AEA:
	rest 1
	note -5, 0
	note -3, 0
	note -1, 0
	rest 0
	note 2, 0
	rest 0
	note -1, 5
	note -5, 0
	note -3, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note 2, 0
	note_x -3, 60
	snd_ret
Sub_6AFB:
	note_x -5, 4
	note_x -3, 4
	note_x -1, 4
	note 0, 0
	rest 0
	note -2, 0
	rest 0
	note_x -4, 60
	note 0, 0
	note -2, 0
	note 0, 0
	rest 0
	note -2, 0
	rest 0
	note -4, 5
	note -2, 0
	rest 0
	note -4, 3
	snd_ret
Sub_6B12:
	note_x -5, 4
	note_x -3, 4
	note_x -1, 4
	note 0, 0
	rest 0
	note -2, 0
	rest 0
	note_x -4, 60
	note 0, 0
	note -2, 0
	note 0, 0
	rest 0
	note -2, 0
	rest 0
	note -4, 0
	note -2, 0
	note -4, 2
	rest 0
	note -2, 0
	rest 0
	note 0, 0
	note 1, 0
	note 3, 1
	snd_ret
Sub_6B2E:
	note 4, 0
	rest 0
	note 8, 0
	rest 0
	note_x 1, 60
	note 4, 0
	note 3, 0
	note 4, 0
	rest 0
	note 8, 0
	rest 0
	note 1, 5
	note 3, 0
	rest 0
	note 1, 3
	snd_ret
Sub_6B3F:
	rest 1
	note 7, 0
	note 9, 0
	note 10, 1
	note 14, 0
	rest 0
	note 15, 0
	rest 0
	note 14, 0
	rest 0
	note 12, 3
	rest 1
	note 10, 0
	note 12, 0
	note 14, 0
	rest 0
	note 10, 0
	rest 0
	note 7, 1
	note 5, 0
	rest 0
	note 7, 0
	rest 0
	note 5, 0
	note 7, 0
	note 9, 0
	rest 0
	note 7, 0
	note 9, 0
	note_x 2, 120
	instrument 23
	gate 222
	volume 13
	pan PAN_L
	note 6, 0
	note 6, 0
	rest 1
	note 6, 0
	note 6, 0
	note 6, 1
	snd_ret
	db $F0, $DE  ; unreachable (after snd_ret)
Song12_CH2:
	length_set 4
	instrument 2
	volume 6
	gate 150
	base_note $44
	pan PAN_LR
	snd_call Sub_6BD2
	base_note $43
	snd_call Sub_6BD2
	base_note $44
	snd_call Sub_6BD2
	snd_call Sub_6BD9
Seq_6B8B:
	base_note $2C
	gate 250
	volume 12
	instrument 22
	pan PAN_LR
	snd_call Sub_6AEA
	snd_call Sub_6AFB
	snd_call Sub_6AEA
	snd_call Sub_6B12
Seq_6BA1:
	base_note $2C
	instrument 19
	volume 12
	gate 240
	snd_call Sub_6BF1
	base_note $2B
	snd_call Sub_6BF1
	base_note $20
	gate 0
	instrument 6
	volume 7
	snd_call Sub_6C02
	instrument 24
	pan PAN_LR
	volume 11
	snd_loop 2
	base_note $20
	snd_call Sub_6C48
	base_note $21
	snd_call Sub_6C48
	snd_endloop
	snd_jump Seq_6BA1
Sub_6BD2:
	snd_loop 4
	rest 1
	note 4, 0
	note 4, 0
	snd_endloop
	snd_ret
Sub_6BD9:
	rest 1
	note 3, 0
	note 3, 0
	rest 1
	note 3, 0
	note 3, 0
	base_note $20
	pan PAN_R
	instrument 21
	gate 222
	volume 12
	note 3, 0
	rest 0
	note 3, 0
	rest 0
	note 3, 0
	note 3, 0
	note 3, 1
	snd_ret
Sub_6BF1:
	note 1, 0
	rest 0
	note 4, 0
	rest 0
	note_x -3, 60
	note 1, 0
	note -1, 0
	note 1, 0
	rest 0
	note 4, 0
	rest 0
	note -3, 5
	note -1, 0
	rest 0
	note -3, 3
	snd_ret
Sub_6C02:
	snd_loop 2
	pan PAN_L
	note 5, 0
	note 2, 0
	pan PAN_R
	note -2, 0
	note 2, 0
	snd_endloop
	snd_loop 2
	pan PAN_L
	note 5, 0
	note 0, 0
	pan PAN_R
	note -4, 0
	note 0, 0
	snd_endloop
	snd_loop 2
	pan PAN_L
	note 7, 0
	note 3, 0
	pan PAN_R
	note -2, 0
	note 3, 0
	snd_endloop
	snd_loop 2
	pan PAN_L
	note 3, 0
	note 0, 0
	pan PAN_R
	note -4, 0
	note 0, 0
	snd_endloop
	snd_loop 6
	pan PAN_L
	note 5, 0
	note 2, 0
	pan PAN_R
	note -2, 0
	note 2, 0
	snd_endloop
	instrument 23
	volume 13
	pan PAN_R
	gate 222
	note 3, 0
	note 3, 0
	rest 1
	note 3, 0
	note 3, 0
	note 3, 1
	snd_ret
Sub_6C48:
	snd_loop 8
	note -5, 1
	note 4, 0
	note 4, 0
	snd_endloop
	snd_ret
Song12_CH4:
	length_set 4
	gate 255
	volume 8
	pan PAN_LR
	snd_loop 14
	snd_call Sub_6C7E
	snd_endloop
	snd_call Sub_6CC3
Seq_6C60:
	snd_loop 2
	snd_loop 14
	snd_call Sub_6C7E
	snd_endloop
	snd_call Sub_6C91
	snd_endloop
	snd_loop 8
	snd_call Sub_6CA3
	snd_endloop
	snd_loop 14
	snd_call Sub_6C7E
	snd_endloop
	snd_call Sub_6CD5
	snd_jump Seq_6C60
Sub_6C7E:
	instrument 26
	drum 4, 0
	volume_add -3
	drum 4, 0
	volume_add 6
	instrument 16
	drum 6, 0
	instrument 26
	volume_add -2
	drum 5, 0
	volume_add -1
	snd_ret
Sub_6C91:
	instrument 26
	drum 4, 0
	volume_add -3
	drum 4, 0
	volume_add 6
	snd_loop 3
	drum 6, 0
	drum 6, 0
	volume_add 1
	snd_endloop
	volume_add -6
	snd_ret
Sub_6CA3:
	instrument 26
	drum 4, 0
	volume_add -3
	drum 4, 0
	volume_add 6
	instrument 16
	drum 6, 0
	volume_add -6
	instrument 0
	drum 2, 0
	volume_add 3
	snd_loop 2
	instrument 26
	drum 4, 0
	instrument 16
	volume_add 3
	drum 6, 0
	volume_add -3
	snd_endloop
	snd_ret
Sub_6CC3:
	instrument 16
	volume_add 5
	drum 7, 1
	drum 7, 1
	drum 7, 0
	volume_add -3
	drum 7, 0
	volume_add 3
	instrument 7
	drum 9, 1
	volume_add -5
	snd_ret
Sub_6CD5:
	volume_add 3
	instrument 16
	drum 6, 0
	drum 6, 2
	drum 6, 0
	volume_add -2
	drum 6, 0
	volume_add 2
	instrument 7
	drum 8, 1
	volume_add -3
	snd_ret
Song13_CH1:
	length_set 1
	rest 3
	pan PAN_LR
	snd_jump Seq_5966
Song13_CH2:
	length_set 1
	rest 3
	pan PAN_LR
	snd_jump Seq_5A5A
Song13_CH4:
	length_set 1
	drest 3
	pan PAN_LR
	instrument 16
	gate 240
	snd_jump Seq_5B1D
Song13_CH3:
	length_set 1
	pan PAN_LR
	snd_jump Seq_58B3
Song14_CH1:
	length_set 3
	pan PAN_LR
	snd_jump Seq_5F4E
Song14_CH2:
	length_set 3
	base_note $2C
	snd_jump Seq_6026
Song14_CH3:
	length_set 3
	pan PAN_LR
	base_note $20
	instrument 7
	volume 15
	gate 255
	snd_jump Seq_5EAB
Song14_CH4:
	length_set 3
	pan PAN_LR
	gate 255
	instrument 16
	volume 9
	snd_jump Seq_6114
Song15_CH1:
	length_set 2
	pan PAN_LR
	base_note $33
	snd_jump Seq_55E5
Song15_CH2:
	length_set 2
	base_note $33
	snd_jump Seq_56C4
Song15_CH3:
	length_set 2
	gate 160
	pan PAN_LR
	base_note $27
	instrument 7
	volume 15
	snd_jump Seq_5796
Song16_CH1:
	length_set 4
	gate 222
	snd_jump Seq_6A8B
Song16_CH2:
	length_set 4
	snd_jump Seq_6B8B
Song16_CH3:
	length_set 4
	volume 15
	instrument 7
	pan PAN_LR
	gate 255
	snd_jump Seq_6A10
Song16_CH4:
	length_set 4
	volume 8
	gate 255
	pan PAN_LR
	snd_jump Seq_6C60
Song17_CH3:
	length_set 1
	instrument 0
	volume 10
	pan PAN_LR
	gate 0
	base_note $12
	note_x -5, 40
	volume 15
	note_x -5, 40
	instrument 7
	base_note $2A
	gate 100
	note 2, 1
	note -1, 1
	rest 1
	note 2, 1
	note -1, 1
	rest 1
	note 2, 1
	note -1, 1
	base_note $1E
	volume 15
	gate 130
	snd_loop 3
	note 0, 1
	note 0, 1
	note -5, 1
	note -2, 1
	snd_endloop
	note 0, 1
	note 0, 1
	gate 230
	note -5, 0
	note -5, 0
	gate 130
	note -2, 1
Seq_6DAD:
	snd_call Sub_6DB4
	snd_jump Seq_6DAD
	snd_end  ; unreachable (after snd_jump)
Sub_6DB4:
	snd_loop 4
	note 0, 1
	note 0, 1
	note -5, 1
	note -2, 1
	snd_endloop
	snd_loop 4
	note -2, 1
	note -2, 1
	note -7, 1
	note -4, 1
	snd_endloop
	snd_loop 4
	note -4, 1
	note -4, 1
	note -9, 1
	note 3, 1
	snd_endloop
	note -5, 1
	note -5, 1
	note 2, 1
	note -5, 1
	note -5, 1
	note 2, 1
	note -5, 1
	note -5, 1
	note 2, 1
	note -5, 1
	note -5, 1
	note -10, 1
	note 7, 1
	note -5, 1
	note 7, 1
	note -5, 1
	snd_ret
Song17_CH1:
	length_set 1
	gate 0
	instrument 2
	pan PAN_LR
	base_note $12
	volume 7
	note_x -5, 40
	snd_loop 8
	volume_add 1
	hold 5
	snd_endloop
	base_note $1E
	gate 100
	note 10, 1
	note 7, 1
	rest 1
	note 10, 1
	note 7, 1
	rest 1
	note 10, 1
	note 7, 1
	volume 0
	rest_x 160
Seq_6DFF:
	instrument 19
	base_note $1E
	volume 12
	snd_call Sub_6E10
	base_note $2A
	snd_call Sub_6E10
	snd_jump Seq_6DFF
Sub_6E10:
	gate 255
	note 3, 1
	gate 200
	note 0, 1
	rest 4
	note -2, 1
	note 0, 1
	gate 255
	note 3, 3
	note 0, 1
	rest 4
	gate 200
	note 5, 1
	note 7, 1
	rest 1
	gate 0
	note 3, 0
	note 2, 0
	note 0, 1
	rest 4
	gate 140
	note -5, 1
	note 3, 1
	gate 255
	snd_loop 3
	note 0, 3
	note -2, 0
	rest 0
	snd_endloop
	note 5, 1
	note 3, 1
	rest 4
	note 5, 1
	note 3, 1
	rest 1
	note 0, 1
	note 3, 1
	rest 1
	note 0, 1
	note 3, 1
	note 5, 1
	note 6, 1
	note 7, 1
	note 10, 1
	note 7, 1
	rest_x 40
	note 10, 1
	note 7, 1
	rest_x 40
	note 10, 1
	note 7, 1
	rest 3
	snd_ret
Song17_CH2:
	length_set 1
	gate 0
	instrument 3
	volume 7
	base_note $12
	pan PAN_LR
	note_x -5, 40
	snd_loop 8
	volume_add 1
	hold 5
	snd_endloop
	base_note $1E
	gate 100
	instrument 2
	note 5, 1
	note 2, 1
	rest 1
	note 5, 1
	note 2, 1
	rest 1
	note 5, 1
	note 2, 1
	volume 12
	base_note $06
	gate 130
	snd_loop 4
	note 0, 1
	note 0, 1
	note 7, 1
	note -2, 1
	snd_endloop
Seq_6E7F:
	gate 255
	base_note $1E
	instrument 0
	volume 8
	snd_call Sub_6E92
	base_note $2A
	snd_call Sub_6E92
	snd_jump Seq_6E7F
Sub_6E92:
	snd_loop 8
	pan PAN_R
	note -9, 0
	note -5, 0
	pan PAN_L
	note 0, 0
	note -5, 0
	snd_endloop
	snd_loop 8
	pan PAN_R
	note -10, 0
	note -7, 0
	pan PAN_L
	note -2, 0
	note -7, 0
	snd_endloop
	snd_loop 8
	pan PAN_R
	note -9, 0
	note -4, 0
	pan PAN_L
	note 0, 0
	note -4, 0
	snd_endloop
	snd_loop 8
	pan PAN_R
	note -7, 0
	note -5, 0
	pan PAN_L
	note -1, 0
	note -5, 0
	snd_endloop
	snd_ret
Song17_CH4:
	length_set 1
	instrument 16
	gate 255
	pan PAN_LR
	volume 12
	drest_x 80
	drum 7, 1
	drum 7, 1
	drest 1
	drum 7, 1
	drum 7, 1
	drest 1
	drum 7, 1
	drum 7, 1
Seq_6ED3:
	instrument 16
	drum 3, 0
	volume_add -3
	drum 3, 0
	instrument 0
	drum 1, 1
	volume_add 3
	instrument 16
	drum 6, 0
	volume_add -3
	drum 3, 0
	instrument 0
	drum 1, 1
	volume_add 3
	snd_jump Seq_6ED3
Song18_CH3:
	length_set 3
	instrument 7
	pan PAN_LR
	volume 15
	gate 250
	base_note $20
	note -10, 2
	note -10, 2
	note -10, 0
	note -8, 0
	note -7, 0
	rest 0
	note -7, 0
	rest 0
	note -7, 0
	note -7, 0
	note -7, 1
	note -5, 2
	note -5, 2
	note -5, 1
	note 14, 0
	rest 0
	note 14, 0
	rest 0
	note 13, 0
	note 13, 0
	note 7, 1
	snd_jump Song18_CH3
Song18_CH1:
	length_set 3
	pan PAN_LR
	volume 11
	gate 245
	instrument 23
	base_note $2C
	note 0, 2
	note 0, 2
	note -3, 0
	note 2, 0
	note 0, 0
	rest 0
	note 0, 0
	rest 0
	note 0, 0
	note 0, 0
	note 0, 1
	note -1, 2
	note -1, 2
	note -1, 1
	note -3, 0
	rest 0
	note -3, 0
	rest 0
	note -3, 0
	note -3, 0
	note -3, 1
	snd_jump Song18_CH1
Song18_CH2:
	length_set 3
	instrument 24
	gate 245
	volume 11
	pan PAN_LR
	base_note $20
	snd_loop 8
	note 5, 0
	note 9, 0
	snd_endloop
	snd_loop 4
	note 2, 0
	note 5, 0
	snd_endloop
	note 4, 0
	rest 0
	note 4, 0
	rest 0
	note 4, 0
	note 4, 0
	note 1, 1
	snd_jump Song18_CH2
Song18_CH4:
	length_set 3
	instrument 16
	pan PAN_L
	volume 11
	gate 255
Seq_6F5E:
	drum 1, 0
	volume_add -1
	drum 2, 0
	volume_add 2
	drum 6, 0
	volume_add -2
	drum 8, 0
	volume_add 1
	snd_jump Seq_6F5E
Env_6F6D:
	env_timbre 0
	env_vol 15
	env_end
Env_6F70:
	env_timbre 1
	env_vol 15
	env_end
Env_6F73:
	env_timbre 2
	env_vol 15
	env_end
Env_6F76:
	env_timbre 3
	env_vol 15
	env_end
Env_6F79:
	env_vol 4
	env_wait 8
	env_vol 0
	env_end
Env_6F7D:
	env_timbre 1
Env_6F7E:
	env_vol 15
	env_loop 15
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
Env_6F85:
	env_timbre 2
Env_6F86:
	env_vol 15, WAIT
Env_6F87:
	env_loop 8
	env_wait 3
	env_vol_add -2
	env_endloop
	env_end
Env_6F8D:
	env_timbre 1
	env_jump Env_6F86
Env_6F91:
	env_timbre 0
	env_vol 15
	env_wait 2
	env_vol 13
	env_wait 2
	env_jump Env_6F87
Env_6F99:
	env_timbre 2
	env_jump Env_6F7E
Env_6F9D:
	env_timbre 2
Env_6F9E:
	env_vol 15
	env_wait 2
	env_vol 14
Env_6FA1:
	env_loop 12
	env_vol_add -1
	env_wait 3
	env_endloop
	env_end
Env_6FA7:
	env_timbre 1
	env_jump Env_6F9E
Env_6FAB:
	env_timbre 0
	env_call Env_6FB2
	env_jump Env_6FA1
Env_6FB2:
	env_vol 15, WAIT
	env_vol 11, WAIT
	env_ret
Env_6FB5:
	env_timbre 1
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_timbre 0
	env_loop 8
	env_vol_add 1, WAIT
	env_vol_add -2, WAIT
	env_endloop
Env_6FBE:
	env_vol_add 1, WAIT
	env_vol_add -1, WAIT
	env_jump Env_6FBE
Env_6FC3:
	env_timbre 2
Env_6FC4:
	env_vol 7, WAIT
Env_6FC5:
	env_vol 13, WAIT
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_vol 6
	env_wait 6
	env_loop 4
	env_vol_add 1
	env_wait 3
	env_vol_add 1
	env_wait 3
	env_endloop
Env_6FD1:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_6FD1
Env_6FD8:
	env_vol 8
	env_wait 5
	env_vol 7
	env_wait 2
	env_vol 6
	env_wait 2
	env_loop 5
	env_vol 5
	env_wait 4
	env_vol 4
	env_wait 3
	env_endloop
	env_vol 2
	env_wait 5
	env_vol 0
	env_end
Env_6FE9:
	env_timbre 1
	env_jump Env_6FC4
Env_6FED:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_timbre 1
	env_vol 13, WAIT
	env_timbre 0
	env_loop 6
	env_vol_add -1
	env_wait 2
	env_endloop
Env_6FF8:
	env_vol 6
	env_wait 3
	env_vol 7
	env_wait 3
	env_jump Env_6FF8
Env_6FFF:
	env_timbre 3
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 0
	env_end
Env_7008:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_vol 14
	env_wait 5
	env_vol 13
	env_wait 5
Env_700F:
	env_pitch -1
	env_wait 2
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 2
	env_pitch 1
	env_wait 3
	env_jump Env_700F
Env_701A:
	env_timbre 0
	env_jump Env_6FC5
Env_701E:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 2
	env_vol 12
	env_wait 2
Env_7023:
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 3
	env_jump Env_7023
Env_702A:
	env_vol 4
	env_wait 2
	env_vol 0
	env_end
Env_702E:
	env_timbre 2
	env_vol 11, WAIT
	env_vol 12
	env_wait 2
	env_vol 13
	env_wait 6
	env_vol 14
Env_7035:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_7035
Env_703C:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 0
	env_vol 14
	env_wait 2
	env_timbre 1
	env_vol 10
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_vol_add -1
	env_wait 3
Env_7049:
	env_pitch -1
	env_wait 4
	env_pitch 1
	env_wait 4
	env_jump Env_7049
Env_7050:
	env_pitch -1
	env_jump Env_702E
Env_7054:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 1
	env_vol 12
	env_wait 2
Env_7059:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_7059
Env_7060:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 3
	env_vol 13, WAIT
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_end
Env_7069:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 2
	env_vol 14, WAIT
	env_timbre 1
	env_vol 13, WAIT
	env_vol 12, WAIT
	env_vol 11, WAIT
	env_vol 10, WAIT
	env_vol 9, WAIT
	env_end
Env_7074:
	env_vol 15, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 3, WAIT
	env_vol 2, WAIT
	env_vol 1, WAIT
	env_vol 0, WAIT
	env_end
Sfx00:
	db 2  ; tracks
	track Sfx00_CH1, CH1
	track Sfx00_CH2, CH2
Sfx01:
	db 2  ; tracks
	track Sfx01_CH2, CH2
	track Sfx01_CH4, CH4
Sfx02:
	db 1  ; tracks
	track Sfx02_CH2, CH2
Sfx03:
	db 1  ; tracks
	track Sfx03_CH2, CH2
Sfx04:
	db 1  ; tracks
	track Sfx04_CH2, CH2
Sfx05:
	db 1  ; tracks
	track Sfx05_CH2, CH2
Sfx06:
	db 2  ; tracks
	track Sfx06_CH4, CH4
	track Sfx06_CH2, CH2
Sfx07:
	db 2  ; tracks
	track Sfx07_CH2, CH2
	track Sfx07_CH1, CH1
Sfx08:
	db 1  ; tracks
	track Sfx08_CH2, CH2
Sfx09:
	db 1  ; tracks
	track Sfx09_CH2, CH2
Sfx10:
	db 1  ; tracks
	track Sfx10_CH4, CH4
Sfx11:
	db 1  ; tracks
	track Sfx11_CH2, CH2
Sfx12:
	db 2  ; tracks
	track Sfx12_CH2, CH2
	track Sfx12_CH1, CH1
Sfx13:
	db 2  ; tracks
	track Sfx13_CH2, CH2
	track Sfx13_CH1, CH1
Sfx14:
	db 1  ; tracks
	track Sfx14_CH4, CH4
Sfx15:
	db 1  ; tracks
	track Sfx15_CH2, CH2
Sfx16:
	db 1  ; tracks
	track Sfx16_CH2, CH2
Sfx17:
	db 1  ; tracks
	track Sfx17_CH4, CH4
Sfx18:
	db 1  ; tracks
	track Sfx18_CH2, CH2
Sfx19:
	db 1  ; tracks
	track Sfx19_CH4, CH4
Sfx20:
	db 1  ; tracks
	track Sfx20_CH4, CH4
Sfx21:
	db 1  ; tracks
	track Sfx21_CH4, CH4
Sfx22:
	db 2  ; tracks
	track Sfx22_CH1, CH1
	track Sfx22_CH2, CH2
Sfx23:
	db 3  ; tracks
	track Sfx23_CH4, CH4
	track Sfx23_CH2, CH2
	track Sfx23_CH1, CH1
Sfx24:
	db 4  ; tracks
	track Sfx24_CH2, CH2
	track Sfx24_CH1, CH1
	track Sfx24_CH3, CH3
	track Sfx24_CH4, CH4
Sfx25:
	db 1  ; tracks
	track Sfx25_CH4, CH4
Sfx26:
	db 1  ; tracks
	track Sfx26_CH2, CH2
Sfx27:
	db 1  ; tracks
	track Sfx27_CH2, CH2
Sfx28:
	db 1  ; tracks
	track Sfx28_CH4, CH4
Sfx29:
	db 3  ; tracks
	track Sfx29_CH4, CH4
	track Sfx29_CH2, CH2
	track Sfx29_CH1, CH1
Sfx30:
	db 1  ; tracks
	track Sfx30_CH2, CH2
Sfx31:
	db 1  ; tracks
	track Sfx31_CH2, CH2
Sfx32:
	db 1  ; tracks
	track Sfx32_CH4, CH4
Sfx33:
	db 4  ; tracks
	track Sfx33_CH2, CH2
	track Sfx33_CH1, CH1
	track Sfx33_CH3, CH3
	track Sfx33_CH4, CH4
Sfx34:
	db 2  ; tracks
	track Sfx34_CH2, CH2
	track Sfx01_CH4, CH4
Sfx35:
	db 1  ; tracks
	track Sfx35_CH2, CH2
Sfx00_CH1:
	length_set 6
	pan PAN_LR
	volume 15
	instrument 27
	gate 0
	base_note $27
	note 5, 0
	snd_loop 6
	detune -15
	hold 1
	detune 11
	hold 1
	snd_endloop
	base_note $2C
	note 14, 0
	note 15, 0
	note 14, 0
	note 15, 0
	rest 3
	note_x 15, 0
	snd_loop 3
	detune -6
	hold 1
	detune 8
	hold 1
	detune -8
	hold 1
	detune 6
	hold 1
	snd_endloop
	rest_x 8
	note_x 15, 0
	snd_loop 3
	detune -7
	hold 1
	detune -5
	hold 1
	detune 7
	hold 1
	detune 5
	hold 1
	snd_endloop
	snd_loop 2
	note_x 15, 0
	snd_loop 3
	detune -6
	hold 1
	detune 5
	hold 1
	detune -5
	hold 1
	detune 6
	hold 1
	snd_endloop
	detune 6
	hold 1
	detune -5
	hold 1
	volume_add -1
	detune 9
	hold 1
	detune -7
	hold 1
	volume_add -1
	detune 8
	hold 1
	detune -9
	hold 1
	volume_add -1
	detune 7
	hold 1
	detune -5
	hold 1
	volume_add -1
	detune 9
	hold 1
	detune -7
	hold 1
	volume 4
	snd_endloop
	snd_end
Sfx00_CH2:
	length_set 6
	rest 1
	snd_jump Sfx00_CH1
Sfx01_CH2:
	base_note $27
Seq_71E2:
	length_set 6
	instrument 28
	gate 0
	pan PAN_LR
	volume 4
	note 4, 0
	snd_loop 5
	detune -7
	hold 1
	detune -8
	hold 1
	detune 4
	hold 1
	detune -7
	hold 1
	volume_add 1
	detune 5
	hold 1
	detune -8
	hold 1
	snd_endloop
	volume_add -2
	detune 1
	hold 1
Seq_7210:
	detune -2
	hold 1
	detune 2
	hold 1
	snd_jump Seq_7210
Sfx01_CH4:
	length_set 9
	pan PAN_LR
	instrument 27
	gate 0
	volume 3
	drum 6, 0
	volume_add 3
	drum 5, 0
	volume_add 3
	drum 4, 0
	volume_add 2
	drum 3, 0
	volume_add 2
	drum 2, 0
	volume_add 2
Seq_7234:
	drum_x 1, 1
	drum_x 0, 1
	snd_jump Seq_7234
Sfx02_CH2:
	base_note $16
	snd_call Sub_7246
	base_note $19
	snd_call Sub_7256
	snd_end
Sub_7246:
	length_set 6
	instrument 30
	pan PAN_LR
	volume 15
	gate 0
	base_note $18
	note 7, 0
	note 8, 0
	note -3, 0
	snd_ret
Sub_7256:
	volume 11
	note 10, 0
	note 11, 0
	note 15, 0
	snd_ret
Sfx03_CH2:
	length_set 6
	instrument 29
	gate 0
	base_note $18
	pan PAN_LR
	volume 9
	note 2, 0
	volume 15
	note_x -5, 0
	snd_loop 2
	detune 88
	hold 1
	detune -33
	hold 1
	snd_endloop
	base_note $2C
	volume 0
	rest 0
	volume 6
	instrument 29
	note_x 14, 0
	snd_loop 5
	detune -1
	hold 1
	volume_add 1
	snd_endloop
	snd_end
Sfx04_CH2:
	length_set 6
	instrument 29
	gate 0
	base_note $33
	pan PAN_LR
	volume 6
	note_x 0, 0
	snd_loop 3
	detune -8
	hold 1
	volume_add 3
	snd_endloop
	volume_add -6
	snd_loop 2
	detune -9
	hold 1
	volume_add -5
	snd_endloop
	snd_end
Sfx05_CH2:
	length_set 6
	gate 0
	pan PAN_LR
	instrument 28
	volume 14
	base_note $26
	note -12, 1
	volume_add -1
	note -13, 0
	volume_add -3
	note -6, 0
	volume_add -1
	note -5, 0
	volume_add -1
	note -4, 0
	volume_add -1
	note -2, 0
	snd_end
Sfx06_CH4:
	length_set 6
	gate 0
	instrument 27
	volume 15
	drum 9, 1
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 14, 0
	drest 1
	volume 3
	drum_x 6, 0
	snd_loop 3
	drum 1, 0
	volume_add 2
	drum 2, 0
	volume_add 2
	snd_endloop
	drum_x 0, 0
	snd_loop 6
	volume_add -1
	hold 2
	volume_add -1
	hold 1
	snd_endloop
	snd_end
Sfx06_CH2:
	length_set 6
	gate 0
	instrument 28
	volume 15
	pan PAN_LR
	base_note $0F
	note_x 7, 0
	snd_loop 6
	detune 85
	hold 2
	volume_add -1
	snd_endloop
	volume 8
	snd_loop 6
	note -15, 0
	note -14, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx07_CH2:
	length_set 6
	instrument 29
Seq_731B:
	volume 5
	gate 0
	base_note $37
	pan PAN_LR
	note 12, 1
	volume 8
	note 9, 1
	volume 15
	note 10, 1
	volume 14
	note 7, 1
	volume_add -1
	note 8, 1
	volume_add -2
	note 5, 1
	volume_add -2
	note 6, 1
	volume_add -2
	note 3, 1
	volume_add -2
	note 4, 1
	instrument 29
	volume 3
	note 1, 1
	volume_add -2
	note 2, 2
	volume 3
	note 12, 1
	note 9, 1
	note 10, 1
	volume 2
	note 7, 1
	note 8, 1
	note 5, 1
	note 6, 1
	volume 1
	note 3, 1
	note 4, 1
	note 1, 1
	note 2, 1
	snd_end
Sfx07_CH1:
	length_set 6
	rest_x 2
	instrument 27
	snd_jump Seq_731B
Sfx08_CH2:
	length_set 6
	instrument 27
	gate 0
	base_note $27
	volume 15
	pan PAN_LR
	note -3, 0
	note -2, 0
	note -4, 0
	volume 0
	rest 0
	volume 15
	note 5, 0
	note 7, 0
	note 6, 0
	note 8, 0
	snd_end
Sfx09_CH2:
	length_set 6
	instrument 29
	volume 4
	pan PAN_LR
	gate 120
	base_note $27
	note_x 7, 0
	snd_loop 6
	detune -18
	hold 1
	volume_add -4
	hold 1
	volume_add 6
	snd_endloop
	snd_end
Sfx10_CH4:
	length_set 6
	volume 15
	gate 0
	pan PAN_LR
	instrument 27
	drum 14, 0
	drum 12, 0
	drum 5, 0
	drum 14, 0
	drest 1
	drum 9, 1
	drum 10, 1
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 14, 0
	drum 14, 0
	snd_loop 3
	drum 11, 1
	volume_add -1
	drum 12, 1
	volume_add -1
	drum 13, 1
	volume_add -2
	drum 14, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx11_CH2:
	length_set 6
	instrument 28
	gate 0
	volume 14
	base_note $3F
	pan PAN_LR
	note 7, 1
	volume_add -8
	note -5, 1
	volume_add 8
	note 2, 1
	volume_add -8
	note 7, 1
	volume_add 8
	note 2, 1
	snd_end
Sfx12_CH2:
	length_set 6
	snd_call Sub_73DF
	pan PAN_L
	snd_call Sub_7402
	snd_end
Sub_73DF:
	volume 15
	base_note $38
	gate 0
	pan PAN_LR
	instrument 29
	note 0, 1
	note 4, 1
	note 7, 1
	note 9, 1
	note 12, 1
	rest 0
	volume 10
	snd_loop 4
	note 0, 1
	note 4, 1
	note 9, 1
	note 12, 1
	volume_add -2
	snd_endloop
	volume 2
	note 1, 1
	note 5, 1
	note 8, 1
	note 10, 1
	note 13, 1
	snd_ret
Sub_7402:
	note 2, 1
	note 6, 1
	note 9, 1
	note 11, 1
	note 14, 1
	snd_loop 4
	snd_loop 2
	note 3, 1
	note 7, 1
	note 10, 1
	note 12, 1
	note 15, 1
	snd_endloop
	volume_add 2
	snd_endloop
	volume 10
	snd_loop 10
	snd_loop 2
	note_x 3, 0
	detune -2
	hold 2
	note_x 7, 0
	detune -2
	hold 2
	note_x 10, 0
	detune -2
	hold 2
	note_x 12, 0
	detune -2
	hold 2
	note_x 15, 0
	detune -2
	hold 2
	snd_endloop
	volume_add -1
	snd_endloop
	snd_ret
Sfx12_CH1:
	rest_x 2
	length_set 6
	snd_call Sub_73DF
	pan PAN_R
	snd_call Sub_7402
	snd_end
Sfx13_CH2:
	length_set 6
	pan PAN_L
Seq_744E:
	volume 1
	instrument 29
	gate 0
	base_note $38
	snd_loop 6
	snd_call Sub_747A
	volume_add 1
	snd_endloop
	snd_call Sub_7499
	snd_loop 6
	snd_call Sub_74D6
	volume_add -1
	snd_endloop
	volume 2
	snd_call Sub_74D6
	snd_call Sub_74D6
	volume 1
	snd_loop 5
	snd_call Sub_74D6
	snd_endloop
	snd_end
Sub_747A:
	note_x 3, 0
	detune -3
	hold 2
	note_x 7, 0
	detune -3
	hold 2
	note_x 10, 0
	detune -3
	hold 2
	note_x 12, 0
	detune -3
	hold 2
	note_x 15, 0
	detune -3
	hold 2
	snd_ret
Sub_7499:
	note_x 3, 0
	detune -2
	hold 2
	note_x 7, 0
	detune -2
	hold 2
	note_x 10, 0
	detune -2
	hold 2
	note_x 12, 0
	detune -2
	hold 2
	note_x 15, 0
	detune -2
	hold 2
	note_x 3, 0
	detune -1
	hold 2
	note_x 7, 0
	detune -1
	hold 2
	note_x 10, 0
	detune -1
	hold 2
	note_x 12, 0
	detune -1
	hold 2
	note_x 15, 0
	detune -1
	hold 2
	snd_ret
Sub_74D6:
	note 3, 1
	note 7, 1
	note 10, 1
	note 12, 1
	note 15, 1
	snd_ret
Sfx13_CH1:
	length_set 6
	pan PAN_R
	rest 1
	snd_jump Seq_744E
Sfx14_CH4:
	length_set 6
	volume 15
	instrument 27
	gate 0
	drum 5, 0
	drum 9, 0
	drum 6, 0
	drest 0
	snd_loop 8
	drum 14, 0
	drum 10, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx15_CH2:
	length_set 6
	volume 15
	instrument 29
	gate 0
	pan PAN_LR
	base_note $24
	note_x 10, 0
	detune 20
	hold 1
	note 11, 0
	volume 7
	note 7, 0
	note 3, 0
	volume 5
	note 0, 0
	note -3, 0
	note -6, 0
	snd_end
Sfx16_CH2:
	length_set 6
	volume 15
	instrument 29
	gate 0
	base_note $34
	pan PAN_LR
	note 15, 0
	rest 0
	note 14, 0
	rest 0
	note 13, 0
	volume_add -2
	note 10, 0
	volume_add -2
	note 7, 0
	volume_add -2
	note 4, 0
	volume_add -2
	note 1, 0
	volume_add -2
	note -2, 0
	volume_add -1
	note -5, 0
	volume_add -1
	note -7, 0
	note -9, 0
	volume_add -1
	note -11, 0
	note -13, 0
	volume 1
	note -14, 0
	snd_end
Sfx17_CH4:
	length_set 6
	instrument 27
	gate 0
	volume 15
	pan PAN_LR
	drum 12, 0
	volume 15
	snd_loop 6
	drum 13, 0
	drum 14, 0
	volume_add -3
	snd_endloop
	snd_end
Sfx18_CH2:
	length_set 6
	instrument 30
	pan PAN_LR
	gate 0
	volume 15
	base_note $46
	note_x -2, 0
	snd_loop 5
	detune 29
	hold 1
	volume_add -2
	snd_endloop
	volume 15
	note_x 4, 0
	snd_loop 5
	detune 27
	hold 1
	volume_add -2
	snd_endloop
	snd_end
Sfx19_CH4:
	length_set 6
	volume 7
	pan PAN_LR
	instrument 27
	gate 0
	snd_loop 4
	drum 11, 0
	drum 10, 0
	volume_add 2
	snd_endloop
	snd_loop 8
	drum 11, 0
	drum 12, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx20_CH4:
	length_set 6
	instrument 27
	gate 0
	volume 13
	pan PAN_LR
	drum 9, 0
	drum 3, 0
	volume_add -5
	drum 6, 0
	volume_add 5
	drum 9, 0
	drum 6, 0
	drum 3, 0
	drest 0
	volume 10
	snd_loop 10
	drum 1, 0
	drum 0, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx21_CH4:
	length_set 6
	instrument 27
	gate 0
	volume 15
	pan PAN_LR
	base_note $27
	drum 4, 0
	drum 5, 0
	drum 6, 0
	drum 7, 0
	drum 8, 0
	drum 9, 0
	drum 10, 0
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 14, 0
	drest 1
	snd_end
Sfx22_CH1:
	length_set 6
	instrument 29
Seq_75D3:
	gate 0
	pan PAN_LR
	base_note $3A
	volume 15
	note -5, 4
	note 0, 4
	note 4, 4
	note 7, 5
	rest 5
	note 12, 5
	rest 5
	note 6, 0
	note_x 7, 12
	rest 5
	snd_end
Sfx22_CH2:
	length_set 6
	instrument 46
	snd_jump Seq_75D3
Sfx23_CH4:
	length_set 6
	instrument 27
	volume 15
	gate 0
	pan PAN_LR
	snd_loop 8
	drum 14, 0
	drum 13, 0
	drum 14, 0
	drum 13, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx23_CH2:
	length_set 6
	instrument 29
	volume 15
	gate 0
	pan PAN_LR
	base_note $16
	snd_loop 8
	note -15, 0
	note -13, 0
	note -14, 0
	note -12, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx23_CH1:
	length_set 6
	instrument 29
	volume 15
	gate 0
	pan PAN_LR
	base_note $16
	snd_loop 8
	note -14, 0
	note -12, 0
	note -13, 0
	note -11, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx24_CH2:
	snd_call Sub_7632
	snd_end
Sub_7632:
	length_set 6
	instrument 29
	volume 15
	gate 0
	pan PAN_LR
	base_note $3F
	snd_loop 2
	note -3, 3
	note 0, 1
	note 2, 1
	note 5, 3
	rest 1
	volume_add -12
	snd_endloop
	snd_ret
Sfx24_CH1:
	snd_call Sub_764D
	snd_end
Sub_764D:
	length_set 6
	instrument 29
	volume 14
	gate 0
	pan PAN_LR
	base_note $3F
	snd_loop 2
	note_x -3, 0
	detune 1
	hold 4
	note_x 0, 0
	detune 1
	hold 2
	note_x 2, 0
	detune 1
	hold 2
	note_x 5, 0
	detune 1
	hold 4
	rest 1
	volume_add -12
	snd_endloop
	snd_ret
Sfx24_CH3:
	rest_x 1
	snd_end
Sfx24_CH4:
	drest_x 1
	snd_end
Sfx25_CH4:
	length_set 6
	volume 15
	gate 0
	instrument 27
	pan PAN_LR
	drum 8, 0
	drum 7, 0
	drum 6, 0
	drum 5, 0
	drum 4, 0
	drum 3, 0
	drum 2, 0
	snd_loop 6
	drum 1, 0
	drum 0, 0
	drum 1, 0
	drum 0, 0
	drum 1, 0
	drum 2, 0
	drum 1, 0
	drum 0, 0
	snd_endloop
	snd_loop 15
	drum 1, 1
	drum 0, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx26_CH2:
	length_set 6
	volume 15
	instrument 29
	pan PAN_LR
	gate 0
	base_note $3F
	note 2, 1
	snd_end
Sfx27_CH2:
	length_set 6
	volume 15
	instrument 29
	pan PAN_LR
	gate 0
	base_note $3F
	note -5, 1
	note 0, 1
	note 4, 1
	note 7, 1
	snd_end
Sfx28_CH4:
	length_set 6
	volume 15
	instrument 27
	pan PAN_LR
	gate 0
	drum 5, 0
	drum 14, 0
	drum 8, 0
	snd_loop 3
	drum 2, 0
	drum 4, 0
	volume_add -4
	snd_endloop
	snd_end
Sfx29_CH4:
	length_set 6
	volume 15
	gate 0
	instrument 27
	pan PAN_LR
	drum 11, 0
	drum 12, 0
	drum 13, 0
	snd_loop 3
	drum 13, 0
	drum 14, 0
	snd_endloop
	drum 3, 0
	drum 4, 1
	snd_loop 6
	drum 5, 1
	drum 6, 1
	drum 7, 0
	drum 8, 0
	drum 9, 0
	drum 10, 0
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 14, 2
	volume_add -3
	snd_endloop
	snd_end
Sfx29_CH2:
	length_set 6
	volume 15
	gate 0
	instrument 29
	pan PAN_LR
	base_note $1B
	snd_loop 4
	note_x 0, 0
	snd_loop 13
	detune 90
	hold 1
	snd_endloop
	volume_add -3
	hold 2
	snd_endloop
	snd_end
Sfx29_CH1:
	length_set 6
	volume 15
	gate 0
	instrument 30
	pan PAN_LR
	base_note $1B
	snd_loop 4
	note_x 5, 0
	snd_loop 13
	detune 90
	hold 1
	snd_endloop
	volume_add -3
	hold 2
	snd_endloop
	snd_end
Sfx30_CH2:
	length_set 6
	pan PAN_LR
	volume 13
	gate 0
	instrument 29
	base_note $27
	note -12, 0
	note -13, 0
	rest 1
	note 11, 0
	note 12, 0
	note 14, 0
	snd_end
Sfx31_CH2:
	length_set 6
	volume 1
	instrument 29
	gate 0
	base_note $1B
	pan PAN_LR
	note_x 11, 0
	snd_loop 6
	detune -13
	hold 1
	volume_add 2
	snd_endloop
	snd_loop 12
	detune -6
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx32_CH4:
	length_set 6
	volume 15
	instrument 27
	gate 0
	pan PAN_LR
	drum 5, 0
	drum 3, 0
	drum 6, 0
	drum 4, 0
	drum 6, 0
	drest 1
	drum 5, 0
	drum 3, 0
	snd_call Sub_7788
	volume 6
	snd_loop 3
	snd_call Sub_7788
	volume_add -2
	snd_endloop
	snd_end
Sub_7788:
	drum 5, 0
	drum 6, 0
	drum 7, 0
	drum 8, 0
	drum 9, 0
	drum 10, 1
	drum 11, 0
	drum 12, 0
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 12, 0
	drum 13, 0
	drum 14, 0
	drum 13, 0
	snd_ret
Sfx33_CH2:
	snd_call Sub_7632
Seq_779B:
	rest_x 20
	snd_jump Seq_779B
Sfx33_CH1:
	snd_call Sub_764D
Seq_77A3:
	rest_x 20
	snd_jump Seq_77A3
Sfx33_CH3:
	rest_x 20
	snd_jump Sfx33_CH3
Sfx33_CH4:
	drest_x 20
	snd_jump Sfx33_CH4
Sfx34_CH2:
	base_note $22
	snd_jump Seq_71E2
Sfx35_CH2:
	base_note $1D
	snd_call Sub_7246
	base_note $12
	snd_call Sub_7256
	snd_end
Env_77C2:
	env_timbre 0
	env_vol 15
	env_end
Env_77C5:
	env_timbre 1
	env_vol 15
	env_end
Env_77C8:
	env_timbre 2
	env_vol 15
	env_end
Env_77CB:
	env_timbre 3
	env_vol 15
	env_end
Env_77CE:
	env_vol 4
	env_wait 8
	env_vol 0
	env_end
Env_77D2:
	env_timbre 1
Env_77D3:
	env_vol 15
	env_loop 15
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
Env_77DA:
	env_timbre 2
Env_77DB:
	env_vol 15, WAIT
Env_77DC:
	env_loop 8
	env_wait 3
	env_vol_add -2
	env_endloop
	env_end
Env_77E2:
	env_timbre 1
	env_jump Env_77DB
Env_77E6:
	env_timbre 0
	env_vol 15
	env_wait 2
	env_vol 13
	env_wait 2
	env_jump Env_77DC
Env_77EE:
	env_timbre 2
	env_jump Env_77D3
Env_77F2:
	env_timbre 2
Env_77F3:
	env_vol 15
	env_wait 2
	env_vol 14
Env_77F6:
	env_loop 12
	env_vol_add -1
	env_wait 3
	env_endloop
	env_end
Env_77FC:
	env_timbre 1
	env_jump Env_77F3
Env_7800:
	env_timbre 0
	env_call Env_7807
	env_jump Env_77F6
Env_7807:
	env_vol 15, WAIT
	env_vol 11, WAIT
	env_ret
Env_780A:
	env_timbre 1
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_timbre 0
	env_loop 8
	env_vol_add 1, WAIT
	env_vol_add -2, WAIT
	env_endloop
Env_7813:
	env_vol_add 1, WAIT
	env_vol_add -1, WAIT
	env_jump Env_7813
Env_7818:
	env_timbre 2
Env_7819:
	env_vol 7, WAIT
Env_781A:
	env_vol 13, WAIT
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_vol 6
	env_wait 6
	env_loop 4
	env_vol_add 1
	env_wait 3
	env_vol_add 1
	env_wait 3
	env_endloop
Env_7826:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_7826
Env_782D:
	env_vol 8
	env_wait 5
	env_vol 7
	env_wait 2
	env_vol 6
	env_wait 2
	env_loop 5
	env_vol 5
	env_wait 4
	env_vol 4
	env_wait 3
	env_endloop
	env_vol 2
	env_wait 5
	env_vol 0
	env_end
Env_783E:
	env_timbre 1
	env_jump Env_7819
Env_7842:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_timbre 1
	env_vol 13, WAIT
	env_timbre 0
	env_loop 6
	env_vol_add -1
	env_wait 2
	env_endloop
Env_784D:
	env_vol 6
	env_wait 3
	env_vol 7
	env_wait 3
	env_jump Env_784D
Env_7854:
	env_timbre 3
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 0
	env_end
Env_785D:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_vol 14
	env_wait 5
	env_vol 13
	env_wait 5
Env_7864:
	env_pitch -1
	env_wait 2
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 2
	env_pitch 1
	env_wait 3
	env_jump Env_7864
Env_786F:
	env_timbre 0
	env_jump Env_781A
Env_7873:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 2
	env_vol 12
	env_wait 2
Env_7878:
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 3
	env_jump Env_7878
Env_787F:
	env_vol 4
	env_wait 2
	env_vol 0
	env_end
Env_7883:
	env_timbre 2
	env_vol 11, WAIT
	env_vol 12
	env_wait 2
	env_vol 13
	env_wait 6
	env_vol 14
Env_788A:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_788A
Env_7891:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 0
	env_vol 14
	env_wait 2
	env_timbre 1
	env_vol 10
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_vol_add -1
	env_wait 3
Env_789E:
	env_pitch -1
	env_wait 4
	env_pitch 1
	env_wait 4
	env_jump Env_789E
Env_78A5:
	env_pitch -1
	env_jump Env_7883
Env_78A9:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 1
	env_vol 12
	env_wait 2
Env_78AE:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_78AE
Env_78B5:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 3
	env_vol 13, WAIT
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_end
Env_78BE:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 2
	env_vol 14, WAIT
	env_timbre 1
	env_vol 13, WAIT
	env_vol 12, WAIT
	env_vol 11, WAIT
	env_vol 10, WAIT
	env_vol 9, WAIT
	env_end
Env_78C9:
	env_vol 15, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 3, WAIT
	env_vol 2, WAIT
	env_vol 1, WAIT
	env_vol 0, WAIT
	env_end
InstrumentTable:
	instr Env_6F6D, Env_6F79  ; instrument 0
	instr Env_6F70, Env_6F79  ; instrument 1 (not used by any song or SFX)
	instr Env_6F73, Env_6F79  ; instrument 2
	instr Env_6F76, Env_6F79  ; instrument 3
	instr Env_6F7D, Env_6F79  ; instrument 4
	instr Env_6F85, Env_6F79  ; instrument 5
	instr Env_6F8D, Env_6F79  ; instrument 6
	instr Env_6F91, Env_6F79  ; instrument 7
	instr Env_6F99, Env_6F79  ; instrument 8
	instr Env_6F9D, Env_6F79  ; instrument 9
	instr Env_6FA7, Env_6F79  ; instrument 10
	instr Env_6FAB, Env_6F79  ; instrument 11
	instr Env_6FB5, Env_6F79  ; instrument 12
	instr Env_6FC3, Env_6FD8  ; instrument 13
	instr Env_6FE9, Env_6FD8  ; instrument 14
	instr Env_6FED, Env_6F79  ; instrument 15
	instr Env_6FFF, Env_6F79  ; instrument 16
	instr Env_7008, Env_702A  ; instrument 17
	instr Env_701A, Env_6FD8  ; instrument 18
	instr Env_701E, Env_702A  ; instrument 19
	instr Env_702E, Env_6F79  ; instrument 20
	instr Env_703C, Env_6F79  ; instrument 21
	instr Env_7050, Env_6F79  ; instrument 22
	instr Env_7054, Env_702A  ; instrument 23
	instr Env_7060, Env_702A  ; instrument 24
	instr Env_7069, Env_702A  ; instrument 25
	instr Env_7074, Env_702A  ; instrument 26
	instr Env_77C2, Env_77CE  ; instrument 27
	instr Env_77C5, Env_77CE  ; instrument 28
	instr Env_77C8, Env_77CE  ; instrument 29
	instr Env_77CB, Env_77CE  ; instrument 30
	instr Env_77D2, Env_77CE  ; instrument 31 (not used by any song or SFX)
	instr Env_77DA, Env_77CE  ; instrument 32 (not used by any song or SFX)
	instr Env_77E2, Env_77CE  ; instrument 33 (not used by any song or SFX)
	instr Env_77E6, Env_77CE  ; instrument 34 (not used by any song or SFX)
	instr Env_77EE, Env_77CE  ; instrument 35 (not used by any song or SFX)
	instr Env_77F2, Env_77CE  ; instrument 36 (not used by any song or SFX)
	instr Env_77FC, Env_77CE  ; instrument 37 (not used by any song or SFX)
	instr Env_7800, Env_77CE  ; instrument 38 (not used by any song or SFX)
	instr Env_780A, Env_77CE  ; instrument 39 (not used by any song or SFX)
	instr Env_7818, Env_782D  ; instrument 40 (not used by any song or SFX)
	instr Env_783E, Env_782D  ; instrument 41 (not used by any song or SFX)
	instr Env_7842, Env_77CE  ; instrument 42 (not used by any song or SFX)
	instr Env_7854, Env_77CE  ; instrument 43 (not used by any song or SFX)
	instr Env_785D, Env_787F  ; instrument 44 (not used by any song or SFX)
	instr Env_786F, Env_782D  ; instrument 45 (not used by any song or SFX)
	instr Env_7873, Env_787F  ; instrument 46
	instr Env_7883, Env_77CE  ; instrument 47 (not used by any song or SFX)
	instr Env_7891, Env_77CE  ; instrument 48 (not used by any song or SFX)
	instr Env_78A5, Env_77CE  ; instrument 49 (not used by any song or SFX)
	instr Env_78A9, Env_787F  ; instrument 50 (not used by any song or SFX)
	instr Env_78B5, Env_787F  ; instrument 51 (not used by any song or SFX)
	instr Env_78BE, Env_787F  ; instrument 52 (not used by any song or SFX)
	instr Env_78C9, Env_787F  ; instrument 53 (not used by any song or SFX)
LengthSets:
	db   1,   2,   3,   4,   5,   6  ; length set 0
	db   5,  10,  15,  20,  30,  80  ; length set 1
	db   9,  18,  27,  36,  45,  54  ; length set 2
	db   7,  14,  21,  28,  35,  42  ; length set 3
	db   6,  12,  18,  24,  30,  36  ; length set 4
	db   8,  16,  24,  32,  40,  48  ; length set 5
	db   1,   2,   3,   4,   5,   6  ; length set 6
	db   5,  10,  15,  20,  30,  80  ; length set 7
	db   9,  18,  27,  36,  45,  54  ; length set 8
	db   7,  14,  21,  28,  35,  42  ; length set 9
	db   6,  12,  18,  24,  30,  36  ; length set 10
	db   8,  16,  24,  32,  40,  48  ; length set 11
SongTable:
	dw Song00  ; song 0
	dw Song01  ; song 1
	dw Song02  ; song 2
	dw Song03  ; song 3
	dw Song04  ; song 4
	dw Song05  ; song 5
	dw Song06  ; song 6
	dw Song07  ; song 7
	dw Song08  ; song 8
	dw Song09  ; song 9
	dw Song10  ; song 10
	dw Song11  ; song 11
	dw Song12  ; song 12
	dw Song13  ; song 13
	dw Song14  ; song 14
	dw Song15  ; song 15
	dw Song16  ; song 16
	dw Song17  ; song 17
	dw Song18  ; song 18
SfxTable:
	dw Sfx00  ; sfx 0
	dw Sfx01  ; sfx 1
	dw Sfx02  ; sfx 2
	dw Sfx03  ; sfx 3
	dw Sfx04  ; sfx 4
	dw Sfx05  ; sfx 5
	dw Sfx06  ; sfx 6
	dw Sfx07  ; sfx 7
	dw Sfx08  ; sfx 8
	dw Sfx09  ; sfx 9
	dw Sfx10  ; sfx 10
	dw Sfx11  ; sfx 11
	dw Sfx12  ; sfx 12
	dw Sfx13  ; sfx 13
	dw Sfx14  ; sfx 14
	dw Sfx15  ; sfx 15
	dw Sfx16  ; sfx 16
	dw Sfx17  ; sfx 17
	dw Sfx18  ; sfx 18
	dw Sfx19  ; sfx 19
	dw Sfx20  ; sfx 20
	dw Sfx21  ; sfx 21
	dw Sfx22  ; sfx 22
	dw Sfx23  ; sfx 23
	dw Sfx24  ; sfx 24
	dw Sfx25  ; sfx 25
	dw Sfx26  ; sfx 26
	dw Sfx27  ; sfx 27
	dw Sfx28  ; sfx 28
	dw Sfx29  ; sfx 29
	dw Sfx30  ; sfx 30
	dw Sfx31  ; sfx 31
	dw Sfx32  ; sfx 32
	dw Sfx33  ; sfx 33
	dw Sfx34  ; sfx 34
	dw Sfx35  ; sfx 35
SfxChannelMasks:
	db %0011  ; sfx 0
	db %1010  ; sfx 1
	db %0010  ; sfx 2
	db %0010  ; sfx 3
	db %0010  ; sfx 4
	db %0010  ; sfx 5
	db %1010  ; sfx 6
	db %0011  ; sfx 7
	db %0010  ; sfx 8
	db %0010  ; sfx 9
	db %1000  ; sfx 10
	db %0010  ; sfx 11
	db %0011  ; sfx 12
	db %0011  ; sfx 13
	db %1000  ; sfx 14
	db %0010  ; sfx 15
	db %0010  ; sfx 16
	db %1000  ; sfx 17
	db %0010  ; sfx 18
	db %1000  ; sfx 19
	db %1000  ; sfx 20
	db %1000  ; sfx 21
	db %0011  ; sfx 22
	db %1011  ; sfx 23
	db %11011  ; sfx 24
	db %1000  ; sfx 25
	db %0010  ; sfx 26
	db %0010  ; sfx 27
	db %1000  ; sfx 28
	db %0011  ; sfx 29
	db %0010  ; sfx 30
	db %0010  ; sfx 31
	db %1000  ; sfx 32
	db %11011  ; sfx 33
	db %1010  ; sfx 34
	db %0010  ; sfx 35
SfxPriorities:
	db 10  ; sfx 0
	db 50  ; sfx 1
	db 50  ; sfx 2
	db 50  ; sfx 3
	db 50  ; sfx 4
	db 51  ; sfx 5
	db 40  ; sfx 6
	db 20  ; sfx 7
	db 40  ; sfx 8
	db 45  ; sfx 9
	db 35  ; sfx 10
	db 25  ; sfx 11
	db 0  ; sfx 12
	db 0  ; sfx 13
	db 50  ; sfx 14
	db 50  ; sfx 15
	db 50  ; sfx 16
	db 55  ; sfx 17
	db 55  ; sfx 18
	db 50  ; sfx 19
	db 30  ; sfx 20
	db 5  ; sfx 21
	db 0  ; sfx 22
	db 20  ; sfx 23
	db 0  ; sfx 24
	db 9  ; sfx 25
	db 50  ; sfx 26
	db 50  ; sfx 27
	db 49  ; sfx 28
	db 5  ; sfx 29
	db 50  ; sfx 30
	db 50  ; sfx 31
	db 35  ; sfx 32
	db 1  ; sfx 33
	db 49  ; sfx 34
	db 49  ; sfx 35
InitialWave:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $00, $00, $00, $00, $00, $00, $00  ; padding
