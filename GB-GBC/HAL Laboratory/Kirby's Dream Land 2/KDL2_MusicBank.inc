; bank $1F: instruments, envelopes, PlaySong, songs ($4000-$7E6B)

InstrumentTable:
	instr Env_40A8, Env_40B6  ; instrument 0
	instr Env_40AB, Env_40B4  ; instrument 1
	instr Env_40AE, Env_40B4  ; instrument 2
	instr Env_40B1, Env_40B4  ; instrument 3
	instr Env_40B8, Env_40B4  ; instrument 4 (not used in this bank)
	instr Env_40C0, Env_40B4  ; instrument 5
	instr Env_40C8, Env_40B4  ; instrument 6
	instr Env_40CC, Env_40B4  ; instrument 7
	instr Env_40D4, Env_40B4  ; instrument 8 (not used in this bank)
	instr Env_40D8, Env_40B4  ; instrument 9
	instr Env_40E2, Env_40B4  ; instrument 10
	instr Env_40E6, Env_40B4  ; instrument 11
	instr Env_40F0, Env_40B4  ; instrument 12
	instr Env_40FE, Env_4113  ; instrument 13
	instr Env_4124, Env_4113  ; instrument 14
	instr Env_4128, Env_40B4  ; instrument 15
	instr Env_413A, Env_40B4  ; instrument 16
	instr Env_4143, Env_4165  ; instrument 17
	instr Env_4155, Env_4113  ; instrument 18
	instr Env_4159, Env_4165  ; instrument 19
	instr Env_4169, Env_40B4  ; instrument 20
	instr Env_4177, Env_40B4  ; instrument 21
	instr Env_418B, Env_40B4  ; instrument 22
	instr Env_418F, Env_4165  ; instrument 23
	instr Env_419B, Env_4165  ; instrument 24
	instr Env_41A4, Env_4165  ; instrument 25
	instr Env_41AF, Env_4165  ; instrument 26
	instr Env_41B9, Env_41BE  ; instrument 27
	instr Env_41C4, Env_41C9  ; instrument 28
	instr Env_41C4, Env_4167  ; instrument 29 (not used in this bank)
	instr Env_41CE, Env_41DB  ; instrument 30 (not used in this bank)
	instr Env_41DF, Env_4167  ; instrument 31
	instr Env_41E7, Env_40B4  ; instrument 32
	instr Env_41EB, Env_40B6  ; instrument 33
	instr Env_41F1, Env_4113  ; instrument 34 (not used in this bank)
	instr Env_41F5, Env_40B4  ; instrument 35
	instr Env_40FE, Env_40B6  ; instrument 36
	instr Env_41FC, Env_40B6  ; instrument 37
	instr Env_4206, Env_40B6  ; instrument 38
	instr Env_4215, Env_41BE  ; instrument 39 (not used in this bank)
	instr Env_40CC, Env_4220  ; instrument 40 (not used in this bank)
	instr Env_4224, Env_40B6  ; instrument 41
Env_40A8:
	env_timbre 0
	env_vol 15
	env_end
Env_40AB:
	env_timbre 1
	env_vol 15
	env_end
Env_40AE:
	env_timbre 2
	env_vol 15
	env_end
Env_40B1:
	env_timbre 3
	env_vol 15
	env_end
Env_40B4:
	env_vol 4
	env_wait 8
Env_40B6:
	env_vol 0
	env_end
Env_40B8:
	env_timbre 1
Env_40B9:
	env_vol 15
	env_loop 15
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
Env_40C0:
	env_timbre 2
Env_40C1:
	env_vol 15, WAIT
Env_40C2:
	env_loop 8
	env_wait 3
	env_vol_add -2
	env_endloop
	env_end
Env_40C8:
	env_timbre 1
	env_jump Env_40C1
Env_40CC:
	env_timbre 0
Env_40CD:
	env_vol 15
	env_wait 2
	env_vol 13
	env_wait 2
	env_jump Env_40C2
Env_40D4:
	env_timbre 2
	env_jump Env_40B9
Env_40D8:
	env_timbre 2
Env_40D9:
	env_vol 15
	env_wait 2
	env_vol 14
Env_40DC:
	env_loop 12
	env_vol_add -1
	env_wait 3
	env_endloop
	env_end
Env_40E2:
	env_timbre 1
	env_jump Env_40D9
Env_40E6:
	env_timbre 0
	env_call Env_40ED
	env_jump Env_40DC
Env_40ED:
	env_vol 15, WAIT
	env_vol 11, WAIT
	env_ret
Env_40F0:
	env_timbre 1
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_timbre 0
	env_loop 8
	env_vol_add 1, WAIT
	env_vol_add -2, WAIT
	env_endloop
Env_40F9:
	env_vol_add 1, WAIT
	env_vol_add -1, WAIT
	env_jump Env_40F9
Env_40FE:
	env_timbre 2
Env_40FF:
	env_vol 9, WAIT
Env_4100:
	env_vol 13, WAIT
Env_4101:
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_vol 8
	env_wait 6
	env_loop 4
	env_vol_add 1
	env_wait 3
	env_vol_add 1
	env_wait 3
	env_endloop
Env_410C:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_410C
Env_4113:
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
Env_4124:
	env_timbre 1
	env_jump Env_40FF
Env_4128:
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
Env_4133:
	env_vol 6
	env_wait 3
	env_vol 7
	env_wait 3
	env_jump Env_4133
Env_413A:
	env_timbre 3
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 0
	env_end
Env_4143:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_vol 14
	env_wait 5
	env_vol 13
	env_wait 5
Env_414A:
	env_pitch -1
	env_wait 2
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 2
	env_pitch 1
	env_wait 3
	env_jump Env_414A
Env_4155:
	env_timbre 0
	env_jump Env_4100
Env_4159:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 2
	env_vol 12
	env_wait 2
Env_415E:
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 3
	env_jump Env_415E
Env_4165:
	env_vol 4
	env_wait 2
Env_4167:
	env_vol 0
	env_end
Env_4169:
	env_timbre 2
	env_vol 11, WAIT
	env_vol 12
	env_wait 2
	env_vol 13
	env_wait 6
	env_vol 14
Env_4170:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_4170
Env_4177:
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
Env_4184:
	env_pitch -1
	env_wait 4
	env_pitch 1
	env_wait 4
	env_jump Env_4184
Env_418B:
	env_pitch -1
	env_jump Env_4169
Env_418F:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 1
	env_vol 12
	env_wait 2
Env_4194:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump Env_4194
Env_419B:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 3
	env_vol 13, WAIT
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_end
Env_41A4:
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
Env_41AF:
	env_vol 15, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 3, WAIT
	env_vol 2, WAIT
	env_vol 1, WAIT
	env_vol 0, WAIT
	env_end
Env_41B9:
	env_timbre 2
	env_vol 15, WAIT
	env_vol_add -2
	env_wait 3
	env_end
Env_41BE:
	env_vol 12
	env_vol_add -6
	env_wait 2
	env_vol_add -5, WAIT
	env_vol 0
	env_end
Env_41C4:
	env_timbre 0
	env_vol 15, WAIT
	env_vol_add -1
	env_wait 2
	env_end
Env_41C9:
	env_vol 14
	env_vol_add -8
	env_wait 2
	env_vol 0
	env_end
Env_41CE:
	env_timbre 2
	env_vol 15, WAIT
	env_timbre 3
	env_loop 6
	env_vol_add -1, WAIT
	env_endloop
	env_loop 8
	env_vol_add -1
	env_wait 2
	env_endloop
	env_end
Env_41DB:
	env_vol 4
	env_wait 4
	env_vol 0
	env_end
Env_41DF:
	env_timbre 2
	env_vol 15, WAIT
	env_vol_add -4, WAIT
	env_loop 3
	env_vol_add -3, WAIT
	env_endloop
	env_end
Env_41E7:
	env_timbre 3
	env_jump Env_40CD
Env_41EB:
	env_timbre 2
	env_vol 15
	env_vol_add -1, WAIT
	env_vol_add -2
	env_wait 7
	env_end
Env_41F1:
	env_timbre 3
	env_jump Env_40FF
Env_41F5:
	env_timbre 3
	env_vol 10
	env_vol_add 5
	env_wait 2
	env_jump Env_4101
Env_41FC:
	env_timbre 2
	env_vol 14, WAIT
	env_timbre 3
	env_vol 15, WAIT
	env_loop 10
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
Env_4206:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 0
	env_vol 5, WAIT
	env_vol 2, WAIT
	env_vol 5, WAIT
	env_loop 3
	env_vol_add -2
	env_wait 2
	env_vol_add 1
	env_wait 2
	env_endloop
	env_vol 0
	env_end
Env_4215:
	env_timbre 1
	env_vol 15, WAIT
	env_timbre 3
	env_vol_add -4
	env_wait 3
	env_loop 10
	env_vol_add -1
	env_wait 18
	env_endloop
	env_end
Env_4220:
	env_vol 7
	env_vol_add -1
	env_wait 20
	env_end
Env_4224:
	env_vol 15
Env_4225:
	env_timbre 0
	env_wait 1
	env_timbre 2, WAIT
	env_vol_add -1, WAIT
	env_loop 3
	env_vol_add -3, WAIT
	env_endloop
	env_vol_add 6
	env_wait 1
	env_jump Env_4225

; Sound_PlaySong (bank $1F, far-called): e = song, $FF = stop. A request for the song already
; playing (wCurSong) is ignored. Resets the music image, starts tracks 7 downward.
Sound_PlaySong:
	ld a, [wCurSong]            ; 4232
	cp e                        ; 4235
	ret z                       ; 4236
	ld a, e                     ; 4237
	ld [wCurSong], a            ; 4238
	ld b, e                     ; 423B
	ld hl, wTrkWait + 4         ; 423C
	ld c, $04                   ; 423F
	xor a                       ; 4241
.l_4242:
	ld [hli], a                 ; 4242
	dec c                       ; 4243
	jr nz, .l_4242              ; 4244
	ld hl, MusicDefaultRegImage ; 4246
	ld de, wMusicRegs           ; 4249
	ld c, $14                   ; 424C
.l_424E:
	ld a, [hli]                 ; 424E
	ld [de], a                  ; 424F
	inc de                      ; 4250
	dec c                       ; 4251
	jr nz, .l_424E              ; 4252
	ld a, $FF                   ; 4254
	cp b                        ; 4256
	ret z                       ; 4257
	ld e, b                     ; 4258
	ld d, $00                   ; 4259
	ld hl, SongTable            ; 425B
	add hl, de                  ; 425E
	add hl, de                  ; 425F
	ld a, [hli]                 ; 4260
	ld e, a                     ; 4261
	ld d, [hl]                  ; 4262
	ld a, [de]                  ; 4263
	ld h, a                     ; 4264
	push hl                     ; 4265
	ld bc, $0007                ; 4266
.l_4269:
	ld hl, wTrkWait             ; 4269
	add hl, bc                  ; 426C
	ld a, [hl]                  ; 426D
	and a                       ; 426E
	jr nz, .l_4279              ; 426F
	call Sound_StartTrack       ; 4271
	pop hl                      ; 4274
	dec h                       ; 4275
	push hl                     ; 4276
	jr z, .l_427F               ; 4277
.l_4279:
	dec c                       ; 4279
	ld a, $03                   ; 427A
	cp c                        ; 427C
	jr nz, .l_4269              ; 427D
.l_427F:
	pop hl                      ; 427F
	ret                         ; 4280

MusicDefaultRegImage:
	db $08, $00, $08, $00, $80, $00, $00, $08, $00, $80, $80, $00, $00, $00, $80, $00
	db $00, $08, $00, $80
Song00:
	db 4  ; tracks
	track Song00_CH1, CH1
	track Song00_CH3, CH3
	track Song00_CH2, CH2
	track Song00_CH4, CH4
Song01:
	db 4  ; tracks
	track Song01_CH1, CH1
	track Song01_CH3, CH3
	track Song01_CH2, CH2
	track Song01_CH4, CH4
Song02:
	db 3  ; tracks
	track Song02_CH1, CH1
	track Song02_CH2, CH2
	track Song02_CH3, CH3
Song03:
	db 3  ; tracks
	track Song03_CH3, CH3
	track Song03_CH1, CH1
	track Song03_CH2, CH2
Song04:
	db 4  ; tracks
	track Song04_CH3, CH3
	track Song04_CH2, CH2
	track Song04_CH1, CH1
	track Song04_CH4, CH4
Song05:
	db 4  ; tracks
	track Song05_CH3, CH3
	track Song05_CH2, CH2
	track Song05_CH1, CH1
	track Song05_CH4, CH4
Song06:
	db 4  ; tracks
	track Song06_CH1, CH1
	track Song06_CH3, CH3
	track Song06_CH2, CH2
	track Song06_CH4, CH4
Song07:
	db 4  ; tracks
	track Song07_CH2, CH2
	track Song07_CH3, CH3
	track Song07_CH1, CH1
	track Song07_CH4, CH4
Song08:
	db 4  ; tracks
	track Song08_CH2, CH2
	track Song08_CH3, CH3
	track Song08_CH1, CH1
	track Song08_CH4, CH4
Song00_CH1:
	length_set 6
	pan PAN_LR
	snd_loop 2
	instrument 33
	volume 10
	gate 150
	base_note $1E
	snd_call Sub_452C
	rest 0
	note -7, 0
	gate 60
	rest 0
	note 7, 0
	gate 150
	note -9, 0
	gate 60
	note 7, 0
	gate 180
	note -8, 0
	snd_endloop
	base_note $2A
	volume_add -3
	snd_call Sub_452C
	rest 0
	note -7, 0
	gate 60
	rest 0
	note 7, 0
	gate 150
	note -9, 0
	gate 60
	note 7, 0
	gate 180
	note -8, 0
	snd_call Sub_452C
	note -7, 0
	gate 60
	note -5, 0
	gate 255
	note -8, 0
	gate 150
	note -7, 0
	base_note $36
	instrument 23
	gate 80
	note 2, 0
	gate 150
	note 7, 0
	note 12, 0
Song01_CH1:
	length_set 6
	pan PAN_LR
Seq_4357:
	instrument 35
	volume 11
	snd_call Sub_4521
	rest 0
	snd_call Sub_4509
	volume_add -1
	instrument 35
	note -5, 5
	base_note $36
	gate 150
	instrument 23
	volume 4
	note_x 7, 5
	volume 3
	note_x 7, 5
	note_x -10, 5
	note_x -10, 5
	volume 7
	note_x -5, 5
	note_x -5, 5
	instrument 35
	volume 11
	snd_call Sub_4521
	note -7, 0
	snd_call Sub_4509
	volume_add 3
	note -5, 0
	rest 2
	instrument 1
	base_note $2A
	volume 7
	gate 155
	note 7, 0
	rest_x 9
	base_note $12
	volume 7
	instrument 7
	note 0, 0
	note_x -1, 21
	volume 7
	base_note $1E
	snd_call Sub_44F1
	snd_call Sub_44C2
	base_note $1F
	volume 9
	snd_call Sub_44F1
	base_note $1E
	snd_call Sub_4481
	instrument 23
	volume 9
	snd_call Sub_4476
	rest 0
	snd_call Sub_445E
	volume_add -2
	instrument 35
	note -5, 5
	base_note $36
	volume 8
	instrument 23
	gate 140
	note 7, 0
	rest 1
	volume 9
	snd_call Sub_4476
	note -7, 0
	snd_call Sub_445E
	note -5, 0
	volume 5
	base_note $2A
	snd_call Sub_4448
	base_note $28
	snd_call Sub_4448
	base_note $2A
	snd_call Sub_4448
	snd_call Sub_4421
	base_note $12
	instrument 33
	volume 7
	gate 150
	rest 2
	note -5, 0
	base_note $1E
	volume 6
	gate 77
	note -5, 0
	gate 255
	note -6, 0
	gate 200
	note -5, 0
	rest 1
	volume 8
	base_note $2A
	gate 150
	note 0, 0
	rest 0
	note -1, 1
	base_note $06
	gate 110
	volume 8
	instrument 7
	note 2, 0
	rest 0
	gate 255
	note 1, 0
	snd_jump Seq_4357
Sub_4421:
	snd_loop 4
	note_x -2, 6
	note_x -9, 4
	snd_endloop
	snd_loop 4
	note_x -3, 6
	note_x -9, 4
	snd_endloop
	snd_loop 3
	note_x -2, 6
	note_x -9, 4
	snd_endloop
	instrument 23
	volume 7
	gate 130
	base_note $42
	note -6, 0
	note -5, 0
	gate 255
	note -2, 0
	gate 130
	note -1, 0
	note 0, 0
	snd_ret
Sub_4448:
	instrument 33
	gate 195
	snd_loop 2
	snd_loop 4
	note_x 0, 6
	note_x -7, 4
	snd_endloop
	snd_loop 4
	note_x -1, 6
	note_x -7, 4
	snd_endloop
	snd_endloop
	snd_ret
Sub_445E:
	note -8, 0
	note -10, 0
	rest 2
	gate 0
	note_x -12, 5
	note_x -10, 5
	note_x -8, 7
	rest_x 3
	gate 145
	rest 0
	note -7, 0
	note -5, 0
	rest 0
	note 0, 0
	rest 0
	gate 230
	snd_ret
Sub_4476:
	gate 155
	base_note $2A
	note -8, 0
	rest 0
	note -7, 0
	note -5, 0
	rest 3
	note -7, 0
	snd_ret
Sub_4481:
	rest 2
	gate 250
	note_x 9, 5
	note_x 11, 5
	note 12, 0
	gate 210
	note 6, 0
	rest 0
	base_note $2A
	gate 250
	note 4, 0
	rest 0
	gate 210
	note 2, 0
	gate 250
	note 0, 0
	gate 210
	note -1, 0
	volume 7
	gate 160
	instrument 33
	base_note $36
	rest 0
	note 0, 0
	rest 0
	note -1, 0
	rest 1
	volume 5
	gate 250
	base_note $36
	note_x 5, 5
	gate 180
	note_x -7, 5
	base_note $2A
	volume_add 2
	gate 250
	note_x 5, 5
	gate 180
	note_x -7, 5
	snd_ret
Sub_44C2:
	rest_x 11
	note 7, 0
	note 6, 0
	gate 250
	note 5, 1
	gate 210
	note -2, 0
	rest 0
	note 5, 0
	rest 0
	note 4, 0
	gate 250
	note 12, 0
	gate 210
	note_x 9, 9
	base_note $2A
	volume 5
	instrument 7
	rest 0
	gate 250
	note -3, 0
	gate 170
	note 0, 0
	gate 255
	note 7, 1
	gate 170
	note 4, 0
	gate 242
	note 0, 0
	gate 170
	note -3, 0
	snd_ret
Sub_44F1:
	instrument 9
	gate 250
	note_x 9, 11
	gate 210
	note 2, 0
	rest 0
	note 9, 0
	rest 0
	note 7, 0
	note 5, 1
	gate 250
	note 7, 0
	gate 210
	note 12, 0
	rest 0
	note_x 7, 9
	snd_ret
Sub_4509:
	note -8, 0
	note -10, 0
	rest 2
	gate 0
	note_x -12, 5
	note_x -10, 5
	note_x -8, 7
	rest_x 3
	gate 145
	rest 0
	note -7, 0
	note -5, 0
	rest 0
	note 0, 0
	rest 0
	gate 230
	snd_ret
Sub_4521:
	gate 155
	base_note $2A
	note -8, 0
	rest 0
	note -7, 0
	note -5, 0
	rest 3
	note -7, 0
	snd_ret
Sub_452C:
	gate 180
	note -7, 0
	gate 65
	rest 0
	note -5, 0
	gate 150
	note -7, 0
	rest 0
	note -7, 0
	note -7, 0
	gate 65
	rest 0
	note -5, 0
	gate 150
	snd_ret
Song01_CH3:
	length_set 6
	instrument 7
	volume 10
	pan PAN_LR
	gate 200
	base_note $12
	note 0, 0
	snd_jump Seq_4559
Song00_CH3:
	length_set 6
	pan PAN_LR
	base_note $12
	snd_call Sub_46FB
Seq_4559:
	volume 10
Seq_455B:
	gate 200
	snd_call Sub_46F3
	note 0, 0
	snd_call Sub_46F3
	snd_call Sub_46E4
	snd_call Sub_46D5
	volume 10
	note 0, 0
	snd_call Sub_46F3
	snd_call Sub_46C5
	snd_call Sub_469A
	base_note $12
	snd_call Sub_4691
	snd_call Sub_466A
	base_note $13
	snd_call Sub_4691
	base_note $12
	snd_call Sub_4629
	volume 10
	instrument 11
	base_note $12
	gate 196
	note 0, 0
	snd_call Sub_46F3
	note 0, 0
	snd_call Sub_46F3
	snd_call Sub_46E4
	snd_call Sub_46D5
	note 0, 0
	snd_call Sub_46F3
	snd_call Sub_46C5
	snd_call Sub_45D7
	snd_call Sub_45AE
	snd_jump Seq_455B
Sub_45AE:
	base_note $06
	volume 12
	rest 1
	note 12, 0
	note 0, 1
	gate 160
	note 7, 0
	gate 255
	note 12, 0
	gate 110
	volume_add -4
	note 0, 0
	volume_add 4
	base_note $12
	gate 130
	note -5, 0
	note 7, 1
	note_x -5, 15
	volume_add -4
	note_x 2, 5
	volume_add 4
	note 2, 0
	rest 0
	gate 200
	note 1, 0
	note 0, 0
	snd_ret
Sub_45D7:
	note -3, 0
	note 9, 0
	rest 0
	note 4, 0
	rest_x 15
	note_x 9, 5
	note 8, 0
	gate 196
	note 7, 1
	rest 0
	note -5, 0
	snd_loop 2
	note 7, 0
	rest 0
	note -5, 0
	rest 0
	snd_endloop
	note 7, 1
	note -5, 0
	note 7, 0
	note 6, 0
	note 5, 1
	note -7, 0
	snd_loop 2
	note 5, 0
	rest 0
	note -7, 0
	rest 0
	snd_endloop
	note 5, 0
	rest 0
	note -7, 0
	gate 240
	note 5, 0
	gate 196
	note 6, 0
	note 7, 1
	note -5, 0
	snd_loop 2
	note 7, 0
	rest 0
	note -5, 0
	rest 0
	snd_endloop
	note 7, 0
	rest 0
	note -5, 0
	note 7, 0
	note 6, 0
	note 5, 1
	note -7, 0
	snd_loop 2
	note 5, 0
	rest 0
	note -7, 0
	rest 0
	snd_endloop
	volume 15
	gate 133
	note -6, 0
	note -5, 0
	gate 253
	note -2, 0
	gate 140
	note -1, 0
	gate 133
	note 0, 0
	snd_ret
Sub_4629:
	gate 255
	note 10, 0
	gate 196
	note 5, 0
	note 4, 0
	note 3, 1
	volume_add -3
	note 15, 0
	volume_add 3
	note 10, 0
	note 3, 0
	note 2, 1
	volume_add -2
	note 14, 0
	volume_add 3
	note 2, 1
	note -3, 0
	note -4, 0
	note -5, 0
	volume_add -1
	base_note $12
	instrument 33
	rest 0
	gate 160
	note 7, 0
	rest 0
	note -5, 0
	rest 1
	volume 5
	instrument 33
	base_note $36
	gate 250
	note_x 7, 5
	gate 180
	note_x -5, 5
	base_note $2A
	volume_add 2
	gate 250
	note_x 7, 5
	gate 180
	note_x -5, 5
	snd_ret
Sub_466A:
	note -3, 0
	rest 0
	note 9, 1
	volume_add -3
	note -3, 0
	volume_add 3
	gate 240
	note 9, 0
	gate 170
	note 8, 0
	gate 196
	note 7, 2
	note -5, 1
	note 0, 0
	gate 210
	note 7, 0
	gate 196
	note 6, 0
	note 5, 1
	gate 170
	note 0, 0
	rest 0
	gate 255
	note -7, 1
	note -5, 0
	gate 196
	note -3, 0
	note -2, 0
	snd_ret
Sub_4691:
	note -2, 0
	volume 13
	rest 0
	note 10, 1
	note -2, 0
	note -2, 0
	note 10, 1
	snd_ret
Sub_469A:
	gate 190
	note 9, 0
	gate 140
	note -3, 0
	note 9, 0
	note 9, 1
	note 10, 0
	gate 222
	note 11, 0
	gate 140
	note 12, 1
	note -5, 0
	note -5, 0
	base_note $36
	volume_add -5
	instrument 1
	note -7, 0
	base_note $12
	volume 7
	rest 0
	instrument 11
	gate 196
	note 0, 0
	note -1, 0
	volume 5
	note -1, 0
	volume 11
	gate 196
	snd_ret
Sub_46C5:
	note 12, 0
	gate 0
	note 5, 0
	gate 150
	note 6, 0
	gate 0
	note 7, 1
	gate 190
	note 2, 0
	note 11, 0
	note 8, 0
	snd_ret
Sub_46D5:
	note 2, 0
	rest 0
	note 14, 0
	gate 100
	note 7, 1
	base_note $1E
	note 7, 1
	gate 200
	base_note $12
	note 7, 0
	snd_ret
Sub_46E4:
	note 0, 0
	rest 0
	note 12, 0
	note 0, 1
	note_x -10, 5
	note_x -5, 5
	note 0, 0
	volume_add -5
	note 1, 0
	volume_add 5
	snd_ret
Sub_46F3:
	rest 0
	note 12, 0
	rest 0
	note 0, 0
	note 0, 0
	note 12, 0
	rest 0
	snd_ret
Sub_46FB:
	volume 10
	instrument 7
	gate 150
	snd_loop 3
	note 7, 1
	note 7, 0
	snd_loop 4
	note 7, 1
	snd_endloop
	note 7, 0
	note 5, 0
	note 5, 0
	note 6, 0
	note 6, 0
	snd_endloop
	note 7, 2
	note 7, 1
	note_x 2, 5
	note_x -3, 5
	note -6, 0
	note -5, 1
	note 7, 1
	gate 0
	note 6, 0
	gate 130
	note 7, 1
	note -5, 0
	note 0, 1
	snd_ret
Song00_CH2:
	length_set 6
	pan PAN_LR
	volume 10
	instrument 33
	snd_loop 3
	snd_call Sub_489A
	rest 0
	note -1, 0
	rest 1
	note -3, 0
	rest 0
	gate 180
	note -2, 0
	snd_endloop
	snd_call Sub_489A
	note -1, 0
	rest 0
	gate 255
	note -2, 0
	gate 170
	note -1, 0
	rest 0
	base_note $12
	gate 150
	note -5, 0
	note 0, 0
Song01_CH2:
	length_set 6
	pan PAN_LR
	volume 6
	instrument 2
Seq_4751:
	snd_loop 2
	snd_call Sub_488D
	snd_call Sub_487D
	snd_endloop
	snd_call Sub_488D
	snd_call Sub_4874
	snd_call Sub_4864
	base_note $1E
	snd_call Sub_4849
	snd_call Sub_481E
	base_note $1F
	snd_call Sub_4849
	rest 2
	base_note $1E
	snd_call Sub_47F5
	snd_loop 2
	snd_call Sub_488D
	snd_call Sub_47E5
	snd_endloop
	snd_call Sub_488D
	snd_call Sub_4874
	snd_call Sub_47DC
	base_note $2A
	snd_call Sub_47D4
	base_note $28
	snd_call Sub_47D4
	base_note $2A
	snd_call Sub_47D4
	snd_call Sub_47BF
	base_note $2A
	gate 150
	rest 2
	note -8, 0
	gate 77
	note -8, 0
	gate 255
	note -9, 0
	gate 200
	note -8, 0
	rest 1
	base_note $2A
	gate 130
	note 2, 0
	rest 0
	note 7, 1
	rest 0
	base_note $2A
	note_x 7, 5
	note_x 0, 5
	note_x 2, 5
	note_x -5, 5
	snd_jump Seq_4751
Sub_47BF:
	snd_loop 4
	note 5, 0
	note -7, 0
	snd_endloop
	note 5, 0
	note -7, 0
	gate 160
	note_x 5, 5
	note_x 5, 5
	gate 99
	note 6, 0
	note 7, 0
	note 10, 0
	note 11, 0
	note 12, 0
	snd_ret
Sub_47D4:
	snd_loop 8
	gate 60
	note 7, 0
	note -5, 0
	snd_endloop
	snd_ret
Sub_47DC:
	snd_loop 2
	note 4, 0
	note -3, 0
	note 0, 0
	snd_endloop
	note 7, 0
	note -5, 0
	snd_ret
Sub_47E5:
	snd_loop 2
	note 2, 0
	note -1, 0
	note -5, 0
	snd_endloop
	gate 190
	note_x 7, 5
	note_x 7, 5
	gate 90
	note -5, 0
	snd_ret
Sub_47F5:
	note 7, 0
	gate 242
	note 6, 0
	gate 204
	note 0, 0
	rest 0
	note 12, 0
	rest 0
	note 7, 0
	gate 242
	note 6, 0
	gate 204
	note 5, 0
	gate 160
	rest 0
	base_note $2A
	note 5, 0
	rest 0
	note 5, 0
	rest 1
	gate 97
	base_note $36
	note_x 7, 5
	note_x -5, 5
	base_note $2A
	note_x 7, 5
	note_x -5, 5
	snd_ret
Sub_481E:
	rest_x 12
	note 0, 0
	note -1, 0
	gate 242
	note -2, 1
	gate 204
	note -7, 0
	rest 0
	note -2, 0
	rest 0
	note -2, 0
	gate 242
	note 4, 0
	gate 204
	note_x 0, 9
	base_note $2A
	rest_x 9
	instrument 7
	gate 150
	note -7, 0
	note -3, 0
	note_x 4, 15
	rest_x 5
	gate 130
	note 0, 0
	note -3, 0
	note -7, 0
	instrument 9
	snd_ret
Sub_4849:
	gate 242
	volume 7
	instrument 9
	rest_x 2
	note 5, 0
	gate 204
	note -3, 0
	rest 0
	note 5, 0
	rest 0
	note 4, 0
	note 2, 1
	gate 242
	note 0, 0
	gate 204
	note 4, 0
	rest 0
	note_x 0, 8
	snd_ret
Sub_4864:
	snd_loop 2
	note 4, 0
	note -3, 0
	note 0, 0
	snd_endloop
	note 7, 0
	note 4, 0
	rest 2
	gate 155
	base_note $2A
	note 12, 0
	rest 3
	snd_ret
Sub_4874:
	note -3, 0
	note 0, 0
	note 5, 0
	note -1, 0
	note 2, 0
	note -5, 0
	note 7, 0
	note -1, 0
	snd_ret
Sub_487D:
	snd_loop 2
	note 2, 0
	note -1, 0
	note -5, 0
	snd_endloop
	gate 190
	note_x 7, 5
	note_x 7, 5
	gate 90
	note -5, 0
	snd_ret
Sub_488D:
	gate 90
	base_note $2A
	snd_loop 2
	note 4, 0
	note 0, 0
	note -5, 0
	snd_endloop
	note 7, 0
	note -5, 0
	snd_ret
Sub_489A:
	gate 180
	base_note $1E
	note -1, 0
	rest 1
	gate 150
	note -1, 0
	rest 0
	note -1, 0
	note -1, 0
	rest 1
	snd_ret
Song00_CH4:
	length_set 6
	pan PAN_LR
	gate 110
	instrument 16
	snd_loop 15
	snd_call Sub_4939
	snd_endloop
	volume 10
	drum 2, 0
	drum_x 1, 5
	drum_x 1, 5
	drum 3, 1
Song01_CH4:
	length_set 6
	pan PAN_LR
	instrument 16
	gate 110
Seq_48C6:
	snd_loop 14
	snd_call Sub_4939
	snd_endloop
	drest 0
	volume 10
	instrument 26
	drum_x 3, 4
	drum_x 2, 3
	drum_x 1, 3
	volume 12
	drum 2, 0
	volume 10
	drum 3, 0
	drest 3
	instrument 16
	snd_loop 15
	snd_call Sub_4939
	snd_endloop
	drest 3
	snd_loop 13
	snd_call Sub_4939
	snd_endloop
	volume 10
	drum 3, 0
	drum_x 1, 5
	drum_x 3, 5
	drum 4, 0
	drum 1, 0
	snd_loop 4
	snd_call Sub_4910
	snd_endloop
	gate 110
	snd_call Sub_4939
	snd_call Sub_4939
	drest 0
	volume 12
	drum 3, 0
	drest 0
	volume 11
	drum 1, 0
	drest 3
	snd_jump Seq_48C6
Sub_4910:
	instrument 16
	gate 110
	volume 9
	drum 4, 1
	drum 1, 1
	drum 3, 0
	volume 5
	drum 3, 0
	volume 9
	drum 1, 2
	drum_x 0, 5
	drum_x 1, 5
	drum 3, 0
	drum 4, 1
	drum_x 2, 5
	drum_x 2, 5
	volume 11
	instrument 11
	gate 255
	drum_x 3, 0
	snd_loop 5
	hold 4
	volume_add -1
	snd_endloop
	snd_ret
Sub_4939:
	volume 7
	drum 10, 0
	drum 2, 0
	volume 10
	drum 4, 0
	volume 7
	drum 2, 0
	snd_ret
Song02_CH1:
	length_set 3
	pan PAN_L
	instrument 20
Seq_494A:
	gate 240
	base_note $33
	volume 9
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
Song02_CH2:
	length_set 3
	pan PAN_R
	instrument 22
	snd_jump Seq_494A
Song02_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 11
	gate 255
	base_note $33
	note -12, 0
	rest 0
	note -5, 0
	note 4, 0
	rest 0
	note -12, 0
	note -4, 0
	note -9, 0
	note -4, 0
	note 0, 1
	note -4, 0
	note -5, 0
	rest 0
	snd_end
Song03_CH3:
	length_set 3
	pan PAN_LR
	instrument 33
	base_note $15
	snd_call Sub_499A
	base_note $17
	snd_call Sub_499A
	snd_jump Song03_CH3
Sub_499A:
	snd_loop 2
	volume 11
	gate 108
	note -5, 1
	note -5, 1
	rest 1
	note 7, 1
	rest_x 56
	note -3, 1
	note -3, 1
	rest 1
	note 2, 1
	rest 1
	note -3, 1
	gate 130
	note -10, 0
	volume_add -3
	note -10, 0
	volume_add -3
	note -10, 1
	snd_endloop
	snd_ret
Song03_CH1:
	length_set 3
	pan PAN_LR
	instrument 35
	base_note $2D
	snd_call Sub_49D0
	snd_call Sub_49D0
	base_note $2F
	snd_call Sub_49D0
	snd_call Sub_49D0
	snd_jump Song03_CH1
Sub_49D0:
	gate 120
	volume 8
	note 6, 0
	rest 0
	note -1, 0
	volume_add -6
	note -1, 0
	volume_add 6
	gate 60
	note 2, 1
	note -3, 1
	rest 1
	instrument 33
	gate 120
	note -1, 0
	volume_add -4
	note -1, 0
	volume_add 4
	gate 120
	note 2, 0
	rest 2
	instrument 35
	note 7, 0
	rest 0
	note 0, 0
	volume_add -4
	note 0, 0
	volume_add 4
	gate 60
	note 4, 1
	note 7, 1
	instrument 33
	note 6, 1
	gate 120
	note 0, 0
	volume_add -4
	note 12, 0
	volume_add 4
	note 14, 0
	volume_add -3
	note 14, 0
	volume_add -3
	note 14, 0
	note 14, 0
	snd_ret
Song03_CH2:
	length_set 3
	pan PAN_LR
	instrument 35
	base_note $2B
	snd_call Sub_4A2A
	snd_call Sub_4A2A
	base_note $2D
	snd_call Sub_4A2A
	snd_call Sub_4A2A
	snd_jump Song03_CH2
Sub_4A2A:
	volume 8
	gate 120
	note -1, 0
	rest 0
	note -8, 0
	volume_add -4
	note -4, 0
	volume_add 4
	note 1, 0
	rest 0
	note -11, 0
	rest 2
	instrument 33
	note -15, 0
	volume_add -5
	note -15, 0
	volume_add 5
	gate 60
	note -13, 1
	note -15, 1
	instrument 35
	gate 120
	note 1, 0
	rest 0
	note -6, 0
	volume_add -4
	note -3, 0
	volume_add 4
	note 4, 0
	rest 0
	note -10, 0
	rest 0
	instrument 33
	note -1, 0
	note -1, 0
	note -8, 0
	volume_add -4
	note 13, 0
	volume_add 4
	note_x 8, 8
	volume_add -3
	note 8, 0
	volume_add -3
	note 8, 0
	note_x 8, 6
	snd_ret
Song04_CH3:
	length_set 3
	pan PAN_LR
	gate 90
	base_note $14
	snd_call Sub_4B2D
	snd_call Sub_4B2D
	base_note $16
	snd_call Sub_4B2D
	gate 120
	note -2, 0
	note -2, 1
	note 5, 1
	note -2, 0
	note -2, 1
	base_note $14
	snd_call Sub_4B2D
	snd_call Sub_4B2D
	base_note $16
	snd_call Sub_4B2D
	gate 200
	note 10, 0
	gate 90
	note -2, 1
	note -2, 1
	rest 2
Song05_CH3:
	length_set 3
	pan PAN_LR
	gate 90
	base_note $14
	snd_call Sub_4B2D
	snd_call Sub_4B2D
	base_note $16
	snd_loop 3
	snd_call Sub_4B2D
	snd_endloop
	base_note $1B
	snd_call Sub_4B2D
	base_note $14
	snd_call Sub_4B2D
	note 0, 2
	note 0, 0
	note 12, 0
	note 0, 0
	note 0, 1
	snd_call Sub_4B2D
	snd_call Sub_4B2D
	base_note $16
	snd_loop 3
	snd_call Sub_4B2D
	snd_endloop
	base_note $1B
	snd_call Sub_4B2D
	snd_call Sub_4B2D
	volume_add -5
	note -2, 0
	volume_add 5
	note -14, 1
	note -14, 2
	rest 1
	gate 118
	base_note $14
	snd_call Sub_4B23
	base_note $13
	snd_call Sub_4B23
	base_note $12
	note -3, 0
	note -3, 0
	rest 0
	volume_add -5
	note 2, 1
	volume_add 5
	note -3, 0
	note -10, 1
	note -5, 0
	note 7, 0
	note 2, 0
	note -5, 1
	note -3, 1
	note -1, 0
	base_note $15
	snd_call Sub_4B23
	base_note $14
	snd_call Sub_4B23
	note -4, 0
	note -4, 1
	volume_add -5
	note 3, 1
	volume_add 5
	note -9, 0
	note -4, 1
	note 1, 0
	note -11, 0
	note 1, 0
	note -14, 0
	rest 0
	volume 11
	gate 111
	note 11, 0
	volume 15
	note -13, 0
	volume 9
	gate 231
	note -13, 0
	snd_jump Song05_CH3
Sub_4B23:
	note -2, 0
	note -2, 1
	volume_add -5
	note 10, 1
	volume_add 5
	note -2, 0
	note -2, 1
	snd_ret
Sub_4B2D:
	volume 14
	gate 100
	note -7, 2
	volume_add -5
	gate 80
	note 5, 2
	volume_add 5
	gate 90
	note -7, 1
	snd_ret
Song04_CH2:
	length_set 3
	pan PAN_LR
	volume 7
	gate 133
	instrument 41
	base_note $20
	snd_call Sub_4C71
	snd_call Sub_4C71
	snd_call Sub_4C54
	base_note $20
	snd_call Sub_4C71
	snd_call Sub_4C71
	snd_call Sub_4C43
	base_note $2C
	note 4, 0
	note 7, 0
	note 14, 0
	note 12, 0
	volume_add -6
	note 12, 0
	volume_add 6
	note 10, 0
	volume_add -6
	note 10, 0
	volume_add 3
	note 0, 0
Song05_CH2:
	length_set 3
	pan PAN_LR
	volume 7
	gate 133
	instrument 41
	base_note $20
	snd_call Sub_4C71
	snd_call Sub_4C71
	snd_loop 2
	snd_call Sub_4C43
	snd_endloop
	snd_call Sub_4C32
	note 7, 0
	note -2, 0
	note 5, 0
	note 4, 0
	volume_add -6
	note 4, 0
	volume_add 6
	note 0, 0
	note 12, 0
	note 0, 0
	snd_call Sub_4C71
	snd_call Sub_4C21
	snd_call Sub_4C71
	snd_call Sub_4C71
	snd_loop 2
	snd_call Sub_4C43
	snd_endloop
	snd_call Sub_4C32
	note 7, 0
	note -2, 0
	note 5, 0
	note 7, 0
	volume_add -6
	note 7, 0
	volume_add 6
	note -2, 0
	note 5, 0
	volume_add -4
	note 2, 0
	volume_add 4
	snd_call Sub_4C21
	note 5, 0
	note -7, 0
	volume_add -5
	note -7, 0
	volume_add 5
	note -7, 0
	rest 3
	gate 111
	instrument 25
	base_note $25
	snd_call Sub_4C14
	base_note $24
	snd_call Sub_4C0B
	note 5, 0
	note 0, 0
	note 3, 0
	note 1, 0
	note 8, 0
	note 1, 0
	note 13, 0
	volume 2
	note 13, 0
	base_note $26
	snd_call Sub_4C14
	base_note $25
	note 5, 0
	note 3, 0
	note 1, 0
	note -2, 0
	note 7, 0
	note 3, 0
	note 13, 0
	volume 2
	note 13, 0
	volume 5
	note 12, 0
	volume 2
	note 12, 0
	rest 0
	instrument 33
	volume 9
	base_note $33
	note -14, 0
	note -9, 0
	volume_add -4
	note 3, 0
	volume_add 4
	note -9, 0
	volume 4
	note -9, 0
	snd_jump Song05_CH2
Sub_4C0B:
	note 1, 0
	note -6, 0
	note 1, 0
	note -6, 0
	note 0, 0
	note -6, 0
	note 0, 0
	note -6, 0
	snd_ret
Sub_4C14:
	volume 5
	snd_loop 4
	note 4, 0
	note -3, 0
	snd_endloop
	snd_loop 4
	note 2, 0
	note -5, 0
	snd_endloop
	snd_ret
Sub_4C21:
	note 4, 0
	note 5, 0
	note 6, 0
	note 7, 0
	volume_add -6
	note 7, 0
	volume_add 6
	note -2, 0
	note 12, 0
	volume_add -6
	note 12, 0
	volume_add 6
	snd_ret
Sub_4C32:
	note 9, 0
	note -2, 0
	note 2, 0
	note 9, 0
	volume_add -6
	note 9, 0
	volume_add 6
	note -2, 0
	note 5, 0
	volume_add -6
	note 5, 0
	volume_add 6
	snd_ret
Sub_4C43:
	note 9, 0
	note -1, 0
	note 7, 0
	note 9, 0
	volume_add -6
	note 9, 0
	volume_add 6
	note -1, 0
	note 5, 0
	volume_add -6
	note 5, 0
	volume_add 6
	snd_ret
Sub_4C54:
	note 10, 0
	note 2, 0
	note 5, 0
	note 10, 0
	volume_add -6
	note 10, 0
	volume_add 6
	note 7, 0
	volume_add -6
	note 7, 0
	volume_add 6
	note -2, 0
	note 10, 0
	note 0, 0
	note 4, 0
	note 14, 0
	volume_add -6
	note 14, 0
	volume_add 6
	note 12, 0
	note 0, 0
	rest 0
	snd_ret
Sub_4C71:
	note 9, 0
	note 0, 0
	note 7, 0
	note 9, 0
	volume_add -6
	note 9, 0
	volume_add 6
	note 0, 0
	note 5, 0
	volume_add -6
	note 5, 0
	volume_add 6
	snd_ret
Song04_CH1:
	length_set 3
	pan PAN_LR
	snd_loop 12
	rest 3
	snd_endloop
	gate 133
	base_note $2C
	volume 7
	instrument 41
	note 10, 0
	note 9, 0
	note 7, 0
	note 5, 0
	note 7, 0
	note 5, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note 4, 0
	note 10, 0
	note 7, 0
	volume_add -6
	note 7, 0
	volume_add 6
	note 4, 0
	volume_add -6
	note 4, 0
	volume_add 3
	note -2, 0
Song05_CH1:
	length_set 3
	pan PAN_LR
	snd_call Sub_4CF3
	snd_call Sub_4D16
	snd_call Sub_4CF3
	note 11, 0
	note 9, 0
	note 7, 1
	note -2, 1
	note -1, 0
	note 2, 2
	note 0, 0
	rest_x 49
	snd_call Sub_4CE4
	note 9, 2
	note_x 7, 56
	base_note $26
	snd_call Sub_4CE4
	note 6, 1
	note 7, 1
	rest 1
	instrument 33
	volume 9
	base_note $33
	gate 111
	note -12, 0
	note -7, 0
	volume_add -4
	note 5, 0
	volume_add 4
	note -7, 0
	volume 4
	note -7, 0
	snd_jump Song05_CH1
Sub_4CE4:
	volume 9
	instrument 41
	gate 220
	note 9, 2
	note 11, 2
	note 12, 1
	note 7, 2
	note 0, 4
	note 5, 1
	note 4, 1
	note 5, 0
	snd_ret
Sub_4CF3:
	base_note $25
	instrument 12
	gate 182
	volume 9
	note 7, 0
	note 7, 0
	note 6, 0
	rest 0
	note 7, 1
	note 6, 1
	note 7, 1
	note 9, 0
	note 11, 0
	rest 0
	note 12, 2
	note 9, 2
	note 2, 0
	rest 0
	note 1, 0
	note_x 2, 70
	note 5, 0
	note 5, 0
	note 4, 0
	rest 0
	note 5, 1
	note 4, 1
	note 5, 1
	note 7, 0
	note 9, 2
	snd_ret
Sub_4D16:
	note 11, 0
	note 9, 0
	note 7, 0
	note 7, 0
	note -5, 0
	rest 0
	note 4, 1
	note 4, 0
	note 2, 0
	rest 0
	instrument 16
	base_note $36
	note -15, 0
	note -12, 0
	note -5, 0
	note -6, 0
	note -10, 0
	note 14, 0
	volume 4
	note 14, 0
	snd_ret
Song04_CH4:
	length_set 3
	pan PAN_LR
	instrument 16
	volume 7
	snd_loop 14
	snd_call Sub_4D88
	snd_endloop
	gate 255
	drum 4, 0
	drest 1
	snd_call Sub_4D88
	drest 0
Song05_CH4:
	length_set 3
	pan PAN_LR
	instrument 16
	volume 7
	snd_loop 30
	snd_call Sub_4D88
	snd_endloop
	snd_call Sub_4D61
	snd_loop 7
	snd_call Sub_4D75
	snd_endloop
	snd_call Sub_4D61
	snd_jump Song05_CH4
Sub_4D61:
	drum 4, 0
	drum 1, 1
	gate 255
	drum 4, 0
	gate 100
	drum 2, 0
	drum 1, 0
	gate 255
	instrument 27
	drum 1, 0
	gate 100
	instrument 16
	drum 2, 0
	snd_ret
Sub_4D75:
	gate 200
	drum 3, 0
	gate 100
	drum 2, 0
	drum 1, 0
	gate 180
	drum 3, 0
	gate 250
	drum 4, 0
	gate 100
	drum 2, 0
	drum 1, 0
	drum 1, 0
	snd_ret
Sub_4D88:
	gate 100
	drum 10, 0
	drum 1, 0
	gate 255
	drum 4, 0
	gate 100
	drum 2, 0
	snd_ret
Song06_CH1:
	length_set 1
	pan PAN_LR
	volume 12
	base_note $26
	gate 255
	instrument 12
	note_x -5, 4
	note_x -3, 4
	note_x -1, 3
	note_x 0, 3
	note_x 2, 3
	note_x 4, 3
	note_x 5, 3
	snd_call Sub_4E64
	gate 255
	note 0, 1
	gate 150
	note -3, 1
	note 4, 1
	gate 255
	note_x 2, 22
	instrument 25
	volume 5
	gate 100
	base_note $3E
	note 7, 1
	note_x -5, 9
	volume 7
	base_note $26
	instrument 12
	gate 255
	note_x -5, 3
	note_x 0, 3
	note_x 4, 3
	snd_call Sub_4E64
	note 2, 1
	gate 218
	note_x -3, 3
	note_x -3, 3
	note_x -3, 4
	gate 124
	note -1, 1
	note 0, 1
	rest_x 40
	gate 111
	base_note $32
	snd_call Sub_4E51
	volume_add -4
	note -7, 1
	note -5, 1
	note -7, 1
	note -8, 2
	rest_x 35
	volume_add 4
	snd_call Sub_4E51
	note -6, 1
	note -7, 1
	note -6, 1
	note_x -5, 18
	instrument 24
	volume 6
	gate 255
	base_note $39
	note_x -12, 4
	note_x -2, 4
	note_x 2, 4
	volume 12
	note_x 7, 4
	volume 4
	note_x 7, 4
	note_x 7, 4
	rest_x 8
	snd_call Sub_4E64
	gate 255
	note 0, 1
	gate 150
	note -3, 1
	note 4, 1
	gate 255
	note_x 2, 22
	instrument 25
	volume 5
	gate 100
	base_note $3E
	note 7, 1
	note_x -5, 9
	volume 7
	base_note $26
	instrument 12
	gate 255
	note_x -5, 3
	note_x 0, 3
	note_x 4, 3
	snd_call Sub_4E64
	note 2, 1
	gate 218
	note_x -3, 3
	note_x -3, 3
	note_x -3, 4
	gate 124
	note -1, 1
	note 0, 1
	snd_end
Sub_4E51:
	instrument 25
	note -3, 1
	volume_add -6
	note -3, 1
	volume_add 6
	note -1, 1
	note 0, 1
	note -5, 1
	volume_add -6
	note -5, 1
	volume_add 6
	note -1, 1
	note 0, 1
	snd_ret
Sub_4E64:
	instrument 12
	base_note $26
	volume 12
	gate 150
	note 7, 1
	snd_loop 3
	note 7, 0
	note 6, 0
	snd_endloop
	gate 255
	note 7, 1
	gate 150
	note 4, 1
	note 0, 1
	note -5, 1
	gate 255
	note -3, 1
	gate 150
	note -1, 1
	note -3, 1
	gate 85
	note -5, 3
	gate 200
	note -5, 1
	note_x 0, 4
	volume_add -5
	note_x 0, 3
	note_x 0, 3
	volume_add 5
	note 4, 1
	gate 120
	note 5, 1
	note 5, 1
	rest 1
	note 5, 1
	note 4, 1
	note 4, 1
	rest 1
	note 4, 1
	snd_ret
Song06_CH3:
	length_set 1
	pan PAN_LR
	volume 15
	rest_x 23
	snd_call Sub_4F6A
	gate 126
	note 6, 1
	rest 1
	note 2, 1
	note 7, 2
	rest_x 6
	gate 224
	volume 12
	snd_loop 3
	note_x -10, 3
	snd_endloop
	base_note $0E
	note -5, 3
	base_note $1A
	snd_call Sub_4F6A
	gate 126
	note -6, 1
	rest 1
	note -5, 1
	note 0, 1
	rest 1
	base_note $0E
	gate 214
	volume 14
	snd_loop 3
	note_x 7, 3
	volume_add -1
	snd_endloop
	gate 146
	note_x 0, 21
	base_note $1A
	snd_call Sub_4F5D
	snd_call Sub_4F4E
	gate 191
	note -10, 1
	note 2, 0
	note -5, 0
	volume_add -4
	gate 131
	note 7, 1
	gate 255
	volume_add 4
	note -12, 3
	gate 124
	note -12, 1
	note -10, 1
	gate 231
	note -8, 1
	snd_call Sub_4F5D
	snd_call Sub_4F4E
	gate 112
	note 2, 1
	note -10, 1
	note 2, 1
	gate 252
	note -5, 1
	rest 1
	volume 13
	base_note $0E
	note_x 2, 4
	volume 11
	note_x 2, 3
	note_x 2, 3
	gate 153
	volume 14
	note -5, 3
	volume 11
	snd_call Sub_4F6A
	gate 126
	note 6, 1
	rest 1
	note 2, 1
	note 7, 2
	rest_x 6
	gate 224
	volume 12
	snd_loop 3
	note_x -10, 3
	snd_endloop
	base_note $0E
	note -5, 3
	base_note $1A
	snd_call Sub_4F6A
	gate 126
	note -6, 1
	rest 1
	note -5, 1
	note 0, 1
	rest 1
	base_note $0E
	gate 214
	volume 14
	snd_loop 3
	note_x 7, 3
	volume_add -1
	snd_endloop
	gate 146
	note_x 12, 21
	snd_end
Sub_4F4E:
	gate 189
	note -8, 1
	note 0, 0
	note 0, 0
	note 4, 1
	gate 231
	note_x -12, 3
	note_x -12, 3
	note_x -12, 4
	snd_ret
Sub_4F5D:
	gate 189
	volume 11
	note -7, 1
	note 0, 0
	note 0, 0
	gate 167
	note 5, 1
	note -7, 0
	note -7, 0
	snd_ret
Sub_4F6A:
	base_note $1A
	gate 192
	snd_loop 3
	snd_call Sub_4F8B
	snd_endloop
	instrument 12
	note 0, 1
	instrument 33
	gate 180
	note 4, 0
	note 4, 0
	gate 192
	instrument 12
	note -8, 0
	rest 0
	note 0, 1
	note 2, 1
	rest 3
	note 2, 1
	note 0, 1
	rest 3
	note 0, 1
	snd_ret
Sub_4F8B:
	instrument 12
	note 0, 1
	instrument 33
	gate 180
	note 4, 0
	note 4, 0
	gate 192
	instrument 12
	note -5, 1
	instrument 33
	gate 180
	note 4, 0
	note 4, 0
	gate 192
	snd_ret
Song06_CH2:
	length_set 1
	pan PAN_LR
	rest_x 23
	snd_call Sub_4FB2
	snd_call Sub_5017
	snd_call Sub_4FB2
	snd_end
Sub_4FB2:
	gate 192
	base_note $21
	volume 6
	instrument 33
	snd_loop 8
	rest 1
	note 0, 0
	note 0, 0
	snd_endloop
	instrument 15
	volume 7
	note 14, 1
	rest 3
	note 14, 1
	note 12, 1
	rest 3
	note 12, 1
	gate 160
	volume 9
	instrument 12
	note 2, 1
	note -7, 1
	note 5, 1
	note 4, 3
	volume 4
	gate 99
	instrument 25
	note 6, 1
	note -6, 1
	rest 1
	gate 160
	instrument 12
	base_note $26
	volume 7
	note 4, 1
	snd_loop 3
	note 4, 0
	note 3, 0
	snd_endloop
	note 4, 1
	note 0, 1
	note -5, 1
	note -8, 1
	note -7, 1
	note -5, 1
	note -7, 1
	note -8, 3
	rest 4
	note 2, 1
	rest 3
	note 2, 1
	note 0, 1
	rest 3
	gate 0
	note_x 0, 2
	note_x 2, 2
	note_x 4, 2
	note_x 5, 2
	note_x 7, 2
	gate 120
	note 9, 1
	gate 218
	note_x 7, 3
	note_x 7, 3
	note_x 7, 4
	gate 124
	note 5, 1
	note 4, 1
	rest_x 40
	snd_ret
Sub_5017:
	base_note $32
	volume 6
	instrument 2
	gate 151
	snd_loop 4
	note -3, 0
	note -10, 0
	snd_endloop
	snd_loop 4
	note -5, 0
	note -12, 0
	snd_endloop
	volume 11
	instrument 23
	base_note $3E
	gate 68
	note 5, 1
	note 7, 1
	note 5, 1
	note 4, 1
	rest 1
	instrument 33
	gate 124
	base_note $32
	note -5, 0
	volume_add -6
	note -5, 0
	volume_add 6
	note 4, 0
	rest 2
	gate 131
	instrument 25
	snd_call Sub_505C
	gate 203
	note_x -6, 3
	note_x -5, 3
	note_x -4, 3
	gate 121
	note -3, 1
	rest 1
	note -12, 1
	note -13, 1
	rest_x 40
	snd_ret
Sub_505C:
	note -7, 1
	rest 1
	note -5, 1
	note -3, 1
	note -8, 1
	rest 1
	note_x -12, 11
	snd_ret
Song06_CH4:
	length_set 1
	drest_x 23
	pan PAN_LR
	instrument 16
	snd_loop 2
	snd_loop 8
	snd_call Sub_50AD
	snd_endloop
	snd_loop 3
	snd_call Sub_50B6
	snd_endloop
	snd_call Sub_509E
	snd_endloop
	snd_loop 2
	snd_loop 6
	snd_call Sub_50AD
	snd_endloop
	snd_call Sub_509E
	snd_endloop
	snd_loop 2
	snd_loop 8
	snd_call Sub_50AD
	snd_endloop
	snd_loop 3
	snd_call Sub_50B6
	snd_endloop
	snd_call Sub_509E
	snd_endloop
	snd_end
Sub_509E:
	drest 1
	gate 136
	volume 9
	drum 3, 1
	gate 255
	instrument 6
	drum 1, 1
	instrument 16
	drest 1
	snd_ret
Sub_50AD:
	gate 136
	volume 9
	drum 3, 1
	gate 167
	drum 1, 1
	snd_ret
Sub_50B6:
	gate 136
	volume 9
	drum 3, 1
	gate 167
	drum 1, 1
	drest 3
	snd_ret
Song07_CH2:
	length_set 1
	pan PAN_LR
	base_note $27
	instrument 18
	volume 5
	gate 220
	snd_loop 4
	note 7, 0
	note 4, 0
	note 0, 0
	note -5, 0
	snd_endloop
	snd_loop 4
	note 7, 0
	note 5, 0
	note 0, 0
	note -3, 0
	snd_endloop
	snd_loop 2
	note 7, 0
	note 5, 0
	note 0, 0
	note -3, 0
	snd_endloop
	snd_loop 2
	note 9, 0
	note 6, 0
	note -12, 0
	note -3, 0
	snd_endloop
	snd_loop 2
	note 7, 0
	note 5, 0
	note 0, 0
	note -3, 0
	snd_endloop
	snd_loop 2
	note 7, 0
	note 5, 0
	note 2, 0
	note -1, 0
	snd_endloop
Song08_CH2:
	length_set 1
	pan PAN_LR
Seq_50FA:
	snd_loop 2
	base_note $27
	instrument 18
	volume 5
	gate 247
	snd_loop 4
	note 4, 0
	note 0, 0
	note 12, 0
	note 0, 0
	snd_endloop
	snd_loop 4
	note 5, 0
	note 2, 0
	note 12, 0
	note 2, 0
	snd_endloop
	snd_loop 4
	note 4, 0
	note 0, 0
	note 9, 0
	note 0, 0
	snd_endloop
	snd_loop 2
	note 6, 0
	note 2, 0
	note 12, 0
	note 2, 0
	snd_endloop
	note 9, 0
	note 2, 0
	note 12, 0
	note 2, 0
	note 11, 0
	note 7, 0
	note 14, 0
	note 7, 0
	snd_loop 4
	note 4, 0
	note 0, 0
	note 12, 0
	note 0, 0
	snd_endloop
	snd_loop 6
	note 5, 0
	note 0, 0
	note 12, 0
	note 0, 0
	snd_endloop
	base_note $27
	volume 7
	gate 200
	note 9, 0
	note 9, 0
	note 7, 1
	note 5, 1
	note 7, 1
	base_note $33
	instrument 41
	note -4, 0
	note -9, 0
	note -4, 0
	note 0, 0
	note -2, 0
	note -7, 0
	note -2, 0
	note 2, 0
	note 4, 0
	note -5, 0
	note 7, 0
	note 12, 0
	volume 0
	rest 3
	snd_endloop
	rest_x 3
	base_note $1B
	instrument 18
	volume 4
	gate 255
	snd_loop 8
	note 7, 0
	note 0, 0
	note 3, 0
	note 0, 0
	snd_endloop
	snd_loop 8
	note 5, 0
	note -2, 0
	note 2, 0
	note -2, 0
	snd_endloop
	snd_loop 8
	note 3, 0
	note -2, 0
	note 0, 0
	note -4, 0
	snd_endloop
	snd_loop 8
	note 5, 0
	note -2, 0
	note 2, 0
	note -5, 0
	snd_endloop
	snd_loop 8
	note 7, 0
	note 0, 0
	note 3, 0
	note -2, 0
	snd_endloop
	snd_loop 8
	note 7, 0
	note 2, 0
	note 10, 0
	note 5, 0
	snd_endloop
	base_note $27
	volume 6
	snd_loop 8
	note 3, 0
	note 0, 0
	note -4, 0
	note 0, 0
	snd_endloop
	snd_loop 4
	note 5, 0
	note 0, 0
	note -3, 0
	note 0, 0
	snd_endloop
	snd_loop 4
	note 5, 0
	note -1, 0
	note -5, 0
	note 2, 0
	snd_endloop
	snd_jump Seq_50FA
Song07_CH3:
	length_set 1
	pan PAN_LR
	gate 183
	base_note $1B
	volume 15
	instrument 28
	snd_loop 4
	note -12, 1
	volume_add -4
	note 0, 0
	note 0, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -10, 1
	volume_add -4
	note 2, 0
	note 2, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -8, 1
	volume_add -4
	note 4, 0
	note 4, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -7, 1
	volume_add -4
	note 5, 0
	note 5, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -6, 1
	volume_add -4
	note 6, 0
	note 6, 0
	volume_add 4
	snd_endloop
	snd_loop 3
	note -5, 1
	volume_add -4
	note 7, 0
	note 7, 0
	volume_add 4
	snd_endloop
	note -5, 1
	note 6, 0
	note 7, 0
Song08_CH3:
	length_set 1
	pan PAN_LR
Seq_51F4:
	snd_loop 2
	gate 183
	base_note $0F
	instrument 28
	volume 15
	snd_call Sub_5290
	snd_call Sub_52A5
	snd_call Sub_5290
	snd_loop 2
	note -5, 0
	note -5, 0
	note 7, 0
	note 7, 0
	snd_endloop
	note -3, 0
	note -3, 0
	note 9, 0
	volume_add -4
	note 9, 0
	volume_add 4
	note -1, 0
	note -1, 0
	note 7, 0
	note -5, 0
	note -4, 0
	note -4, 0
	note 8, 0
	note 8, 0
	note -2, 0
	note -2, 0
	note 10, 0
	note 10, 0
	note 0, 1
	note 12, 0
	note 12, 0
	rest 3
	snd_endloop
	rest_x 3
	base_note $1B
	snd_call Sub_5276
	base_note $16
	snd_call Sub_5276
	base_note $1B
	snd_call Sub_5276
	base_note $16
	snd_call Sub_5276
	base_note $1B
	snd_call Sub_5276
	snd_loop 2
	volume 11
	instrument 16
	note -5, 1
	volume 4
	instrument 6
	note -2, 1
	note 2, 1
	note 5, 1
	note 7, 1
	note 5, 1
	note 2, 1
	instrument 16
	volume 9
	note -5, 1
	snd_endloop
	gate 183
	instrument 28
	volume 15
	base_note $0F
	snd_loop 4
	note -4, 1
	note 8, 0
	note 8, 0
	snd_endloop
	snd_loop 4
	note -7, 1
	note 5, 0
	note 5, 0
	snd_endloop
	snd_loop 8
	note -5, 1
	note 7, 0
	note 7, 0
	snd_endloop
	snd_jump Seq_51F4
Sub_5276:
	snd_loop 2
	volume 11
	gate 199
	instrument 16
	note -4, 1
	volume 4
	instrument 6
	note 0, 1
	note 3, 1
	note 7, 1
	note 8, 1
	note 7, 1
	note 3, 1
	volume 9
	instrument 16
	note -4, 1
	snd_endloop
	snd_ret
Sub_5290:
	snd_loop 4
	note 0, 1
	volume_add -4
	note 12, 0
	note 12, 0
	volume_add 4
	snd_endloop
	snd_loop 4
	note 2, 1
	volume_add -4
	note 14, 0
	note 14, 0
	volume_add 4
	snd_endloop
	snd_ret
Sub_52A5:
	snd_loop 4
	note -3, 1
	volume_add -4
	note 9, 0
	note 9, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -10, 1
	volume_add -4
	note 2, 0
	note 2, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note -5, 1
	volume_add -4
	note 7, 0
	note 7, 0
	volume_add 4
	snd_endloop
	snd_ret
Song07_CH1:
	length_set 1
	instrument 2
	volume 4
	gate 183
	base_note $27
	snd_loop 4
	rest 1
	note 4, 0
	note 4, 0
	snd_endloop
	snd_loop 2
	rest 1
	note 5, 0
	note 5, 0
	snd_endloop
	snd_loop 2
	rest 1
	note 7, 0
	note 7, 0
	snd_endloop
	snd_loop 4
	rest 1
	note 9, 0
	note 9, 0
	snd_endloop
	snd_loop 2
	rest 1
	note 7, 0
	note 7, 0
	snd_endloop
	rest_x 40
Song08_CH1:
	length_set 1
	pan PAN_LR
Seq_52F2:
	snd_loop 2
	base_note $27
	volume 8
	instrument 9
	gate 150
	snd_call Sub_53C9
	snd_call Sub_53DC
	base_note $27
	volume 7
	gate 250
	instrument 19
	note 7, 2
	rest 1
	note 4, 0
	note 5, 0
	note 7, 0
	note 12, 1
	note 7, 0
	note 5, 1
	gate 144
	note 4, 0
	gate 250
	rest 1
	note 4, 1
	note 5, 0
	note -3, 0
	rest 0
	note -3, 0
	note -1, 0
	note 0, 0
	gate 0
	note 7, 1
	note 5, 0
	rest 0
	gate 230
	note 4, 0
	gate 255
	note_x 5, 16
	note_x 4, 19
	note 2, 3
	note 0, 3
	gate 0
	note_x 1, 4
	gate 250
	note_x 2, 11
	gate 0
	note_x 0, 19
	snd_loop 2
	volume_add -1
	hold 13
	snd_endloop
	gate 200
	volume 15
	note -12, 0
	note -12, 0
	rest 0
	note -12, 0
	rest 3
	snd_endloop
	rest_x 3
	instrument 14
	volume 9
	base_note $33
	gate 0
	note_x -4, 50
	note -4, 1
	note -2, 1
	note 0, 1
	note 3, 3
	note 2, 3
	note 0, 3
	gate 255
	note 2, 3
	gate 0
	note_x 2, 14
	note_x 5, 13
	note_x 3, 13
	note_x -2, 0
	snd_loop 6
	volume_add -1
	hold 20
	snd_endloop
	volume 9
	gate 255
	note_x -7, 50
	gate 0
	note -7, 1
	note -5, 1
	note -4, 1
	note 0, 3
	note -2, 3
	note -4, 3
	gate 255
	note -2, 3
	gate 0
	note_x -4, 14
	note_x -5, 13
	note_x -7, 13
	note_x -4, 20
	note_x -5, 0
	snd_loop 5
	volume_add -1
	hold 20
	snd_endloop
	volume 9
	gate 255
	note_x 0, 50
	rest 1
	note 2, 1
	note 3, 1
	note 7, 3
	note 5, 3
	note 3, 3
	note 5, 3
	note_x 7, 40
	note_x 2, 14
	note_x 7, 13
	note_x 2, 13
	note_x 5, 40
	note_x 3, 40
	note_x 0, 40
	note_x 0, 14
	note_x 2, 13
	note_x 3, 13
	note 7, 3
	note 5, 3
	note 3, 3
	note 5, 3
	gate 0
	note_x 7, 20
	snd_loop 7
	volume_add -1
	hold 20
	snd_endloop
	snd_jump Seq_52F2
Sub_53C9:
	note 7, 1
	note 4, 0
	note 0, 1
	note -5, 1
	note 7, 1
	note 7, 0
	note 4, 1
	note 0, 1
	note -5, 1
	note 7, 1
	note 5, 0
	note 2, 1
	note -3, 1
	note 7, 1
	note 7, 0
	note 5, 1
	note 2, 1
	note -3, 1
	snd_ret
Sub_53DC:
	note 5, 1
	note 4, 0
	note 0, 1
	note -5, 1
	note 5, 1
	note 5, 0
	note 4, 1
	gate 206
	note 0, 0
	note -8, 0
	note -3, 0
	note -5, 0
	note -6, 3
	gate 0
	note_x 3, 2
	gate 150
	note_x 4, 13
	note 2, 3
	rest 0
	note 2, 0
	note 4, 0
	gate 222
	note 5, 1
	snd_ret
Song07_CH4:
	length_set 1
	pan PAN_LR
	snd_loop 7
	snd_call Sub_549A
	snd_call Sub_54A9
	snd_endloop
	volume 11
	instrument 27
	gate 180
	drum 10, 0
	drest 0
	drum 10, 0
	drest 0
	drum 10, 0
	drum 10, 0
	volume 8
	instrument 0
	gate 0
	drum_x 7, 0
	snd_loop 10
	volume_add -1
	hold 1
	snd_endloop
Song08_CH4:
	length_set 1
	pan PAN_LR
Seq_5426:
	snd_loop 30
	snd_call Sub_549A
	snd_endloop
	snd_call Sub_5467
	volume 10
	drest 0
	gate 111
	instrument 27
	drum 1, 0
	instrument 0
	gate 0
	drum_x 1, 0
	snd_loop 10
	volume_add -1
	hold 1
	snd_endloop
	snd_loop 30
	snd_call Sub_549A
	snd_endloop
	snd_call Sub_5467
	drest_x 23
	snd_loop 3
	snd_loop 7
	snd_call Sub_547A
	snd_endloop
	snd_call Sub_5489
	snd_endloop
	snd_loop 15
	snd_call Sub_549A
	snd_endloop
	snd_call Sub_5467
	snd_jump Seq_5426
Sub_5467:
	gate 111
	instrument 27
	drum 4, 0
	volume 12
	drum 1, 0
	instrument 0
	gate 125
	drum 4, 0
	volume 7
	instrument 16
	drum 2, 0
	snd_ret
Sub_547A:
	volume 11
	instrument 27
	gate 111
	drum 4, 0
	drest 0
	drum 2, 0
	drum 1, 0
	drum 3, 0
	drest 0
	drum 2, 0
	drum 1, 0
	snd_ret
Sub_5489:
	drum 4, 0
	drest 0
	drum 2, 0
	drum 1, 0
	volume 13
	gate 255
	drum 1, 0
	gate 111
	volume 12
	drum 2, 0
	drum 2, 0
	drum 1, 0
	snd_ret
Sub_549A:
	volume 7
	instrument 27
	gate 111
	drum 6, 0
	drest 0
	drum 2, 0
	volume 4
	instrument 16
	drum 2, 0
	snd_ret
Sub_54A9:
	volume 13
	instrument 27
	gate 180
	drum 10, 0
	gate 111
	volume 8
	drum 1, 0
	drum 2, 0
	drum 1, 0
	snd_ret
Song09:
	db 4  ; tracks
	track Song09_CH1, CH1
	track Song09_CH4, CH4
	track Song09_CH3, CH3
	track Song09_CH2, CH2
Song10:
	db 3  ; tracks
	track Song10_CH1, CH1
	track Song10_CH3, CH3
	track Song10_CH2, CH2
Song11:
	db 4  ; tracks
	track Song11_CH3, CH3
	track Song11_CH2, CH2
	track Song11_CH1, CH1
	track Song11_CH4, CH4
Song12:
	db 4  ; tracks
	track Song12_CH1, CH1
	track Song12_CH2, CH2
	track Song12_CH3, CH3
	track Song12_CH4, CH4
Song13:
	db 4  ; tracks
	track Song13_CH3, CH3
	track Song13_CH1, CH1
	track Song13_CH2, CH2
	track Song13_CH4, CH4
Song14:
	db 4  ; tracks
	track Song14_CH2, CH2
	track Song14_CH1, CH1
	track Song14_CH3, CH3
	track Song14_CH4, CH4
Song15:
	db 4  ; tracks
	track Song15_CH3, CH3
	track Song15_CH1, CH1
	track Song15_CH2, CH2
	track Song15_CH4, CH4
Song16:
	db 4  ; tracks
	track Song16_CH3, CH3
	track Song16_CH1, CH1
	track Song16_CH2, CH2
	track Song15_CH4, CH4
Song17:
	db 4  ; tracks
	track Song17_CH4, CH4
	track Song17_CH1, CH1
	track Song17_CH3, CH3
	track Song17_CH2, CH2
Song18:
	db 2  ; tracks
	track Song18_CH1, CH1
	track Song18_CH2, CH2
Song09_CH3:
	length_set 21
	pan PAN_LR
	volume 13
	instrument 12
	gate 200
	base_note $17
	snd_loop 4
	snd_call Sub_55A6
	snd_endloop
Seq_5543:
	snd_loop 2
	volume 13
	snd_call Sub_55A6
	base_note $15
	snd_call Sub_55A6
	base_note $13
	snd_call Sub_55A6
	base_note $17
	snd_loop 2
	note -5, 1
	rest 1
	snd_endloop
	note -3, 1
	note -3, 1
	snd_loop 3
	rest 1
	note -2, 1
	snd_endloop
	note -1, 1
	rest 1
	note -5, 1
	rest 1
	snd_endloop
	snd_call Sub_5594
	snd_call Sub_55A6
	base_note $14
	snd_call Sub_5594
	base_note $17
	snd_call Sub_55A6
	snd_call Sub_5594
	snd_call Sub_55A6
	snd_call Sub_5594
	snd_loop 2
	note 7, 1
	rest 1
	snd_endloop
	note 5, 1
	note 5, 1
	snd_loop 3
	rest 1
	note 4, 1
	snd_endloop
	note 2, 1
	note -10, 1
	volume_add -5
	note -5, 3
	snd_jump Seq_5543
Sub_5594:
	note 5, 1
	rest 3
	note 5, 1
	note 0, 1
	rest 3
	note 5, 1
	rest 1
	note 5, 1
	rest 1
	note 5, 1
	note -7, 3
	volume_add -5
	note 5, 1
	note -7, 1
	volume_add 5
	snd_ret
Sub_55A6:
	note 0, 1
	rest 3
	note 0, 1
	note -5, 1
	rest 3
	note 0, 1
	rest 1
	note 0, 1
	rest 1
	note 0, 1
	note -5, 3
	note -12, 1
	rest 1
	snd_ret
Song09_CH4:
	length_set 21
	pan PAN_LR
	volume 7
	instrument 26
Seq_55BC:
	gate 100
	volume 10
	drum 14, 1
	drest 1
	volume 5
	drum 7, 1
	drum 6, 1
	volume 10
	drum 14, 1
	drest 1
	volume 5
	drum 6, 1
	volume 8
	drum 14, 1
	volume 10
	drum 14, 1
	drest 1
	volume 5
	drum 7, 1
	drum 6, 1
	volume 10
	drum 14, 1
	drest 1
	volume 5
	drum 7, 1
	drum 6, 1
	snd_jump Seq_55BC
Song09_CH1:
	length_set 21
	pan PAN_LR
	volume 7
	instrument 22
	gate 150
	base_note $2F
	snd_loop 2
	snd_call Sub_56DE
	snd_endloop
Seq_55F5:
	snd_loop 2
	pan PAN_LR
	volume 5
	base_note $2F
	instrument 22, STATIC
	gate 0
	note_x 5, 0
	snd_loop 13
	detune -1
	hold 2
	snd_endloop
	volume_add -1
	hold 6
	volume_add 1
	instrument 22
	gate 255
	note 4, 1
	rest 3
	note 0, 1
	rest_x 32
	note 0, 1
	note 2, 1
	note 4, 1
	rest 1
	instrument 22, STATIC
	gate 0
	note_x 3, 0
	snd_loop 13
	detune -1
	hold 2
	snd_endloop
	volume_add -1
	hold 6
	instrument 22
	volume_add 1
	gate 255
	note 2, 1
	rest 3
	note -2, 1
	rest 4
	note -7, 1
	note -7, 1
	rest 4
	instrument 22, STATIC
	gate 0
	note_x 1, 0
	snd_loop 15
	detune -1
	hold 2
	snd_endloop
	hold 2
	instrument 22
	gate 255
	note 0, 1
	rest 3
	note -4, 1
	rest_x 32
	note -4, 1
	note -2, 1
	note 0, 1
	rest 1
	note -1, 4
	instrument 20
	gate 0
	note_x 7, 44
	snd_loop 3
	volume_add -1
	hold 20
	snd_endloop
	snd_endloop
	volume 12
	instrument 11
	base_note $23
	snd_call Sub_56C3
	note_x 7, 72
	snd_call Sub_56A5
	snd_call Sub_56C3
	note_x 7, 40
	volume_add 2
	note_x 8, 32
	volume_add -2
	snd_call Sub_5685
	snd_jump Seq_55F5
Sub_5685:
	gate 255
	note_x 9, 40
	gate 150
	note 11, 3
	note 12, 1
	gate 255
	note_x 9, 32
	gate 150
	note 9, 1
	note 11, 3
	note 12, 1
	gate 255
	base_note $25
	note_x 14, 32
	base_note $23
	note_x 14, 32
	note_x 12, 32
	note_x 11, 32
	snd_ret
Sub_56A5:
	gate 255
	note_x 5, 40
	gate 150
	note 7, 3
	note 9, 1
	gate 255
	note 11, 3
	gate 150
	note 9, 1
	rest 1
	note 7, 1
	rest 1
	note 5, 1
	rest 1
	gate 255
	note_x 4, 32
	note_x 5, 32
	note 7, 3
	note 12, 3
	note 11, 3
	note 12, 3
	snd_ret
Sub_56C3:
	gate 255
	note_x 9, 40
	gate 150
	note 11, 3
	note 12, 1
	gate 255
	note 14, 3
	gate 150
	note 12, 1
	rest 1
	note 11, 1
	rest 1
	note 9, 1
	rest 1
	gate 255
	note_x 7, 32
	note 7, 1
	note 4, 1
	note 5, 1
	snd_ret
Sub_56DE:
	note 4, 1
	note 0, 1
	rest 1
	note 4, 1
	note 0, 1
	rest_x 32
	note -8, 1
	note -12, 1
	rest 1
	note -8, 3
	note -12, 1
	rest 1
	note 5, 1
	note 2, 1
	rest 1
	note 5, 1
	note 2, 1
	rest 1
	rest 3
	rest 1
	note -7, 1
	note -10, 1
	rest 1
	note -7, 3
	note -10, 1
	rest 1
	snd_ret
Song09_CH2:
	length_set 21
	pan PAN_LR
	volume 8
	instrument 15
	gate 150
	base_note $2F
	snd_loop 2
	snd_call Sub_57AE
	snd_call Sub_57C6
	snd_endloop
Seq_570F:
	snd_loop 2
	base_note $23
	gate 150
	instrument 41
	volume 8
	snd_call Sub_57BC
	snd_call Sub_57A3
	snd_call Sub_5799
	snd_loop 2
	note 2, 1
	note -1, 1
	rest 1
	snd_endloop
	note 2, 1
	note 5, 1
	note 7, 1
	rest 1
	note 5, 1
	rest 1
	note 4, 1
	rest 1
	note 2, 1
	rest 1
	snd_endloop
	instrument 11
	volume 11
	rest_x 1
	snd_call Sub_577C
	snd_call Sub_575E
	snd_call Sub_577C
	snd_call Sub_5748
	snd_jump Seq_570F
Sub_5748:
	snd_loop 2
	gate 255
	note_x 5, 40
	gate 150
	note 7, 3
	note 9, 1
	snd_endloop
	gate 255
	note_x 7, 32
	note_x 5, 32
	note_x 4, 32
	note_x 2, 31
	snd_ret
Sub_575E:
	gate 255
	note_x 0, 40
	gate 150
	note -1, 3
	note 0, 1
	gate 255
	note 2, 3
	gate 150
	note 5, 1
	rest 1
	note 4, 1
	rest 1
	note 2, 1
	rest 1
	gate 255
	note_x 0, 32
	note_x -1, 32
	note -2, 3
	note 4, 3
	note 2, 3
	note 4, 3
	snd_ret
Sub_577C:
	gate 255
	note_x 5, 40
	gate 150
	note 7, 3
	note 9, 1
	gate 255
	note 11, 3
	gate 150
	note 9, 1
	rest 1
	note 7, 1
	rest 1
	note 5, 1
	rest 1
	gate 255
	note_x 4, 32
	note -1, 1
	note -5, 1
	note -3, 1
	note_x -1, 72
	snd_ret
Sub_5799:
	snd_loop 4
	note 3, 1
	note 0, 1
	rest 1
	snd_endloop
	note 3, 3
	note 0, 1
	rest 1
	snd_ret
Sub_57A3:
	snd_loop 3
	note 5, 1
	note 2, 1
	rest 1
	snd_endloop
	rest 3
	note 10, 1
	note_x -2, 32
	snd_ret
Sub_57AE:
	note 7, 1
	note 4, 1
	rest 1
	note 7, 1
	note 4, 1
	rest_x 32
	note -5, 1
	note -8, 1
	rest 1
	note -5, 3
	note -8, 1
	rest 1
	snd_ret
Sub_57BC:
	snd_loop 4
	note 7, 1
	note 4, 1
	rest 1
	snd_endloop
	note 7, 3
	note 4, 1
	rest 1
	snd_ret
Sub_57C6:
	note 7, 1
	note 5, 1
	rest 1
	note 7, 1
	note 5, 1
	rest 1
	rest 3
	rest 1
	note -5, 1
	note -7, 1
	rest 1
	note -5, 3
	note -7, 1
	rest 1
	snd_ret
Song10_CH2:
	length_set 14
	gate 0
	instrument 16
	volume 4
	pan PAN_LR
	rest_x 2
Seq_57E1:
	base_note $33
	snd_call Sub_5822
	base_note $36
	snd_call Sub_5822
	snd_jump Seq_57E1
Song10_CH1:
	length_set 14
	gate 0
	instrument 16
	volume 5
	rest_x 1
	pan PAN_LR
Seq_57FA:
	base_note $27
	snd_call Sub_5807
	base_note $2A
	snd_call Sub_5807
	snd_jump Seq_57FA
Sub_5807:
	volume_add 2
	note 4, 1
	volume_add -2
	note -5, 1
	note 0, 1
	note 4, 1
	rest_x 56
	rest 1
	note 2, 0
	note 4, 0
	volume_add 3
	note 5, 1
	volume_add -3
	note 2, 1
	volume_add 3
	note 9, 1
	volume_add -3
	note 7, 1
	rest 3
	snd_ret
Sub_5822:
	volume_add 2
	note 0, 1
	volume_add -2
	note -8, 1
	note -5, 1
	note 0, 1
	rest_x 56
	rest 1
	note -1, 0
	note 0, 0
	volume_add 3
	note 2, 1
	volume_add -3
	note -5, 1
	volume_add 3
	note 5, 1
	volume_add -3
	note 4, 1
	rest 3
	snd_ret
Song10_CH3:
	length_set 14
	gate 100
	instrument 7
	pan PAN_LR
Seq_5845:
	volume 12
	base_note $1B
	snd_call Sub_5878
	base_note $33
	snd_call Sub_587F
	volume 12
	base_note $1B
	snd_call Sub_589A
	base_note $3F
	snd_call Sub_58A5
	volume 12
	base_note $1E
	snd_call Sub_5878
	base_note $36
	snd_call Sub_587F
	volume 12
	base_note $1E
	snd_call Sub_589A
	base_note $42
	snd_call Sub_58A5
	snd_jump Seq_5845
Sub_5878:
	gate 100
	note 0, 1
	note -12, 1
	note -12, 1
	note 0, 1
	snd_ret
Sub_587F:
	rest 1
	instrument 16
	gate 200
	volume 9
	note 12, 0
	volume 4
	note 12, 0
	volume 9
	note 7, 0
	volume 4
	note 7, 0
	volume 8
	note 0, 0
	volume 4
	note 0, 0
	rest 1
	instrument 7
	snd_ret
Sub_589A:
	gate 200
	note -5, 0
	note -3, 0
	gate 100
	note -1, 1
	note -5, 1
	note 7, 1
	note -5, 1
	snd_ret
Sub_58A5:
	volume 5
	instrument 16
	rest 1
	note 4, 0
	volume 4
	note 4, 0
	instrument 7
	snd_ret
Song11_CH3:
	length_set 12
	pan PAN_LR
	volume 15
	instrument 7
	base_note $1F
	snd_loop 14
	gate 130
	note -3, 1
	gate 180
	note -3, 0
	note -3, 0
	snd_endloop
	gate 130
	note 4, 1
	gate 180
	note 2, 0
	note 2, 0
	gate 130
	note 0, 1
	gate 180
	note -1, 0
	note -1, 0
Seq_58D3:
	base_note $1F
	gate 150
	snd_call Sub_596D
	snd_call Sub_5939
	snd_loop 2
	snd_call Sub_596D
	snd_endloop
	snd_call Sub_596D
	snd_call Sub_5939
	base_note $21
	snd_call Sub_5939
	snd_call Sub_5953
	base_note $21
	snd_call Sub_590B
	base_note $1C
	snd_call Sub_590B
	base_note $23
	snd_call Sub_5923
	base_note $21
	snd_loop 2
	snd_call Sub_5939
	snd_endloop
	snd_jump Seq_58D3
Sub_590B:
	instrument 7
	snd_loop 2
	snd_loop 3
	gate 150
	note -9, 1
	gate 180
	note 2, 0
	note 3, 0
	snd_endloop
	gate 200
	note -9, 0
	note -9, 0
	gate 180
	note 3, 0
	note -14, 0
	snd_endloop
	snd_ret
Sub_5923:
	snd_loop 2
	snd_loop 3
	gate 150
	note -14, 1
	gate 180
	note -4, 0
	note -2, 0
	snd_endloop
	gate 200
	note -14, 0
	note -14, 0
	gate 180
	note -2, 0
	note -7, 0
	snd_endloop
	snd_ret
Sub_5939:
	snd_loop 2
	gate 140
	instrument 7
	note -10, 1
	instrument 33
	gate 170
	note -10, 0
	note -10, 0
	gate 140
	instrument 7
	note -3, 1
	instrument 33
	gate 170
	note -10, 0
	note -10, 0
	snd_endloop
	snd_ret
Sub_5953:
	snd_loop 2
	gate 140
	instrument 7
	note -10, 1
	instrument 33
	gate 170
	note -10, 0
	note -10, 0
	gate 140
	instrument 7
	note 0, 1
	instrument 33
	gate 170
	note -10, 0
	note -10, 0
	snd_endloop
	snd_ret
Sub_596D:
	snd_loop 2
	gate 140
	instrument 7
	note -3, 1
	instrument 33
	gate 170
	note -3, 0
	note -3, 0
	instrument 7
	gate 140
	note -8, 1
	instrument 33
	gate 170
	note -3, 0
	note -3, 0
	snd_endloop
	snd_ret
Song11_CH2:
	length_set 12
	pan PAN_LR
	volume 0
	rest_x 161
	base_note $37
	instrument 16
	volume 7
	snd_call Sub_5A4C
	instrument 9
	base_note $2B
	volume 4
	gate 230
	note -8, 0
	volume_add 1
	note -4, 0
	volume_add 1
	note -1, 0
	volume_add 1
	note 2, 0
Seq_59AA:
	instrument 9
	base_note $2B
	volume 4
	gate 230
	snd_call Sub_5A1A
	base_note $32
	volume_add 1
	note 13, 0
	note 9, 0
	volume_add 1
	note 7, 0
	note 4, 0
	volume_add -1
	note 1, 0
	note -3, 0
	volume_add -1
	note -5, 0
	note -8, 0
	gate 255
	volume 8
	base_note $2B
	instrument 18
	note_x 5, 40
	note_x 5, 13
	note_x 7, 13
	note_x 9, 14
	note_x 5, 40
	note 7, 3
	note 5, 3
	note_x 4, 40
	note_x 0, 110
	base_note $37
	note 2, 0
	note 0, 0
	note_x 2, 40
	note_x 2, 13
	note_x 4, 13
	note_x 5, 14
	note_x 2, 40
	note 4, 3
	note 2, 3
	note_x -1, 80
	volume 3
	gate 230
	instrument 9
	base_note $2D
	note 14, 0
	note 12, 0
	volume_add 2
	note 9, 0
	note 6, 0
	volume_add 1
	note 12, 0
	note 9, 0
	volume_add 1
	note 6, 0
	note 2, 0
	volume_add 1
	note 9, 0
	note 6, 0
	volume_add 1
	note 2, 0
	note -3, 0
	volume_add -1
	note -6, 0
	note 2, 0
	volume_add -2
	note -3, 0
	note -6, 0
	snd_jump Seq_59AA
Sub_5A1A:
	snd_loop 4
	note 4, 0
	note 0, 0
	note -3, 0
	note -8, 0
	snd_endloop
	snd_loop 4
	note 2, 0
	note 0, 0
	note -3, 0
	note -6, 0
	snd_endloop
	snd_loop 8
	note 0, 0
	note -3, 0
	note -8, 0
	note -12, 0
	snd_endloop
	snd_loop 4
	note 4, 0
	note 0, 0
	note -3, 0
	note 0, 0
	snd_endloop
	snd_loop 4
	note 6, 0
	note 2, 0
	note -3, 0
	note -6, 0
	snd_endloop
	snd_loop 4
	note 8, 0
	note 4, 0
	note 2, 0
	note -1, 0
	snd_endloop
	snd_loop 2
	note 11, 0
	note 8, 0
	note 4, 0
	note 2, 0
	snd_endloop
	snd_ret
Sub_5A4C:
	gate 255
	note -3, 1
	note 0, 1
	note 4, 1
	note -5, 1
	note -1, 1
	note 4, 1
	note -7, 1
	note -3, 1
	note 2, 1
	note -7, 1
	note -3, 1
	note 0, 1
	note -8, 1
	note -5, 1
	snd_ret
Sub_5A5D:
	note 0, 1
	note -1, 1
	snd_ret
Song11_CH1:
	length_set 12
	pan PAN_LR
	volume 10
	instrument 16
	base_note $2B
	gate 200
	snd_call Sub_5A4C
	snd_call Sub_5A5D
	volume 8
	snd_call Sub_5A4C
Seq_5A77:
	instrument 13
	base_note $37
	gate 255
	volume 8
	snd_call Sub_5ACC
	instrument 18
	base_note $2B
	volume 9
	note 9, 0
	note 7, 0
	note_x 9, 40
	note_x 9, 13
	note_x 11, 13
	note_x 12, 14
	note_x 9, 40
	note 11, 3
	note 9, 3
	note_x 7, 40
	gate 0
	note_x 4, 35
	snd_loop 5
	volume_add -1
	hold 15
	snd_endloop
	volume 9
	gate 255
	note 5, 0
	note 4, 0
	note_x 5, 40
	note_x 5, 13
	note_x 7, 13
	note_x 9, 14
	note_x 5, 40
	note 7, 3
	note 5, 3
	note 4, 0
	note 5, 0
	note 4, 0
	note 2, 0
	gate 0
	note_x 4, 60
	volume_add -2
	note_x 2, 20
	volume_add -1
	hold 20
	volume_add -1
	hold 20
	snd_jump Seq_5A77
Sub_5ACC:
	note -3, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note_x 4, 60
	note -3, 1
	note 7, 1
	note_x 6, 60
	note 4, 1
	note 2, 1
	gate 0
	note_x 4, 30
	snd_loop 5
	volume_add -1
	hold 20
	snd_endloop
	gate 255
	rest_x 10
	volume 8
	note -3, 0
	note -1, 0
	note 0, 0
	note 2, 0
	note_x 4, 60
	note -3, 1
	note 7, 1
	note_x 9, 40
	note 2, 3
	note 6, 3
	gate 0
	note_x 8, 50
	snd_loop 5
	volume_add -1
	hold 20
	snd_endloop
	gate 255
	snd_ret
Song11_CH4:
	length_set 12
	pan PAN_LR
	instrument 31
Seq_5B09:
	volume 7
	gate 200
	drum 7, 0
	gate 100
	volume 4
	drum 3, 0
	gate 200
	volume 5
	drum 4, 0
	drum 3, 0
	volume 8
	gate 200
	drum 7, 0
	volume 4
	gate 100
	drum 3, 0
	volume 5
	gate 200
	drum 4, 0
	drum 3, 0
	snd_jump Seq_5B09
Song12_CH1:
	length_set 12
	gate 134
	pan PAN_LR
	instrument 22
	base_note $33
	volume 5
Seq_5B38:
	snd_loop 4
	note 12, 1
	note 9, 1
	note 5, 1
	note 2, 1
	snd_endloop
	snd_loop 4
	note 11, 1
	note 7, 1
	note 4, 1
	note 0, 1
	snd_endloop
	snd_jump Seq_5B38
Song12_CH2:
	length_set 12
	gate 0
	instrument 31
	base_note $27
	rest_x 1
Seq_5B53:
	snd_loop 4
	volume 7
	note 5, 3
	volume_add -2
	note 2, 1
	note -3, 1
	snd_endloop
	snd_loop 4
	volume 7
	note 4, 3
	volume_add -2
	note 0, 1
	note -5, 1
	snd_endloop
	snd_jump Seq_5B53
Song12_CH3:
	length_set 12
	pan PAN_LR
	gate 100
	instrument 3
	note_x -12, 1
	instrument 23
	volume 7
	base_note $0F
Seq_5B7A:
	note 2, 3
	note 12, 3
	note 11, 3
	rest_x 40
	note 9, 3
	note 5, 3
	note 2, 3
	note 0, 3
	rest_x 60
	note -5, 3
	rest 3
	note -3, 3
	note 0, 3
	snd_jump Seq_5B7A
Song12_CH4:
	length_set 12
	pan PAN_LR
	gate 120
	instrument 31
Seq_5B94:
	volume 3
	drum 4, 1
	volume 0
	drest 4
	snd_jump Seq_5B94
Song13_CH3:
	length_set 12
	instrument 0
	volume 10
	pan PAN_LR
	gate 0
	base_note $12
	note_x -5, 20
	volume 11
	hold 20
	volume 13
	hold 20
	volume 15
	hold 20
	instrument 7
	base_note $2A
	gate 100
	snd_loop 2
	note 2, 1
	note -1, 1
	rest 1
	snd_endloop
	note 2, 1
	note -1, 1
	base_note $1E
	volume 13
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
Seq_5BDB:
	snd_call Sub_5BE1
	snd_jump Seq_5BDB
Sub_5BE1:
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
	snd_loop 3
	note -5, 1
	note -5, 1
	note 2, 1
	snd_endloop
	note -5, 1
	note -5, 1
	note -10, 1
	snd_loop 2
	note 7, 1
	note -5, 1
	snd_endloop
	snd_ret
Song13_CH1:
	length_set 12
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
	snd_loop 2
	note 10, 1
	note 7, 1
	rest 1
	snd_endloop
	note 10, 1
	note 7, 1
	volume 0
	rest_x 160
Seq_5C2A:
	instrument 19
	base_note $1E
	volume 10
	snd_call Sub_5C3B
	base_note $2A
	snd_call Sub_5C3B
	snd_jump Seq_5C2A
Sub_5C3B:
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
Song13_CH2:
	length_set 12
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
	snd_loop 2
	note 5, 1
	note 2, 1
	rest 1
	snd_endloop
	note 5, 1
	note 2, 1
	volume 9
	base_note $06
	gate 130
	snd_loop 4
	note 0, 1
	note 0, 1
	note 7, 1
	note -2, 1
	snd_endloop
Seq_5CAA:
	gate 255
	base_note $1E
	instrument 0
	volume 6
	snd_call Sub_5CBD
	base_note $2A
	snd_call Sub_5CBD
	snd_jump Seq_5CAA
Sub_5CBD:
	snd_loop 8
	note -9, 0
	note -5, 0
	note 0, 0
	note -5, 0
	snd_endloop
	snd_loop 8
	note -10, 0
	note -7, 0
	note -2, 0
	note -7, 0
	snd_endloop
	snd_loop 8
	note -9, 0
	note -4, 0
	note 0, 0
	note -4, 0
	snd_endloop
	snd_loop 8
	note -7, 0
	note -5, 0
	note -1, 0
	note -5, 0
	snd_endloop
	snd_ret
Song13_CH4:
	length_set 12
	instrument 16
	gate 255
	pan PAN_LR
	volume 11
	drest_x 80
	drum 7, 1
	drum 7, 1
	snd_loop 2
	drest 1
	drum 7, 1
	drum 7, 1
	snd_endloop
	volume 8
Seq_5CF0:
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
	snd_jump Seq_5CF0
Song14_CH2:
	length_set 15
	pan PAN_LR
	instrument 17
	volume 4
	gate 0
	base_note $18
	note_x -3, 40
	note_x -5, 20
	volume_add 1
	note_x -7, 18
	volume_add 1
	note_x -9, 16
	volume_add 1
	note_x -11, 14
	volume_add 1
	note_x -13, 12
	gate 230
	note_x -15, 132
	gate 255
	instrument 7
	volume 15
Seq_5D33:
	base_note $13
	snd_loop 2
	snd_call Sub_5D46
	snd_endloop
	base_note $18
	snd_loop 2
	snd_call Sub_5D46
	snd_endloop
	snd_jump Seq_5D33
Sub_5D46:
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note -3, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note -5, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note -3, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note 0, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note 2, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note 4, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note 0, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note 2, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note -1, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	instrument 31
	volume_add -4
	note -5, 0
	volume_add 4
	instrument 7
	note -15, 0
	note -15, 0
	snd_ret
Song14_CH1:
	length_set 15
	volume 5
	instrument 17
	gate 0
	base_note $30
	pan PAN_LR
	note_x -10, 40
	volume_add 1
	note_x -7, 20
	volume_add 1
	note_x -3, 18
	volume_add 1
	note_x -4, 16
	volume_add 1
	note_x -9, 14
	volume_add 1
	note_x -8, 12
	volume_add 1
	note_x 4, 12
	gate 230
	note_x 3, 120
Seq_5DE3:
	base_note $2B
	volume 5
	snd_call Sub_5E13
	base_note $30
	volume 6
	snd_call Sub_5DF4
	snd_jump Seq_5DE3
Sub_5DF4:
	gate 0
	note_x -3, 72
	note -2, 2
	note_x -5, 102
	gate 0
	note_x -3, 72
	note -2, 2
	note_x -5, 78
	gate 0
	note_x -3, 5
	volume_add -1
	note_x -4, 5
	note_x -5, 5
	volume_add -1
	note_x -6, 5
	note_x -7, 4
	snd_ret
Sub_5E13:
	gate 0
	note_x -3, 72
	note -2, 2
	note_x -5, 102
	note_x -3, 72
	note -2, 2
	note_x -5, 78
	gate 0
	note_x -4, 5
	volume_add -1
	note_x -3, 5
	volume_add -1
	note_x -2, 5
	volume_add -1
	note_x -1, 5
	note_x 0, 4
	snd_ret
Song14_CH3:
	length_set 15
	volume 8
	gate 0
	pan PAN_LR
	instrument 19
	base_note $30
	note_x -10, 40
	volume_add 1
	note_x -7, 20
	volume_add 1
	note_x -3, 18
	volume_add 1
	note_x -4, 16
	volume_add 1
	note_x -9, 14
	volume_add 1
	note_x -8, 12
	note_x 4, 12
	gate 230
	note_x 3, 120
	rest_x 2
	instrument 19
Seq_5E5E:
	base_note $2B
	volume 10
	snd_call Sub_5E94
	base_note $30
	volume 11
	snd_call Sub_5E6F
	snd_jump Seq_5E5E
Sub_5E6F:
	gate 255
	note_x -8, 72
	gate 0
	note -7, 2
	gate 255
	note_x -10, 102
	note_x -8, 72
	gate 0
	note -7, 2
	note_x -10, 78
	note_x -8, 5
	volume_add -1
	note_x -9, 5
	volume_add -1
	note_x -10, 5
	volume_add -1
	note_x -11, 5
	volume_add -1
	note_x -13, 4
	snd_ret
Sub_5E94:
	gate 255
	note_x -8, 72
	gate 0
	note -7, 2
	gate 255
	note_x -10, 102
	note_x -8, 72
	gate 0
	note -7, 2
	note_x -10, 78
	note_x -9, 5
	volume_add -1
	note_x -8, 5
	volume_add -1
	note_x -7, 5
	volume_add -1
	note_x -6, 5
	volume_add -1
	note_x -4, 4
	snd_ret
Song14_CH4:
	length_set 15
	pan PAN_LR
	instrument 31
	drest_x 60
	volume 1
	gate 180
	snd_loop 12
	drum_x 3, 3
	drum_x 1, 3
	drum_x 3, 3
	drum_x 1, 3
	volume_add 1
	snd_endloop
	gate 150
	volume 13
	drum 7, 0
	drum 6, 0
	volume 6
	drum 3, 0
	drum 2, 0
	volume 13
	drum 6, 1
	gate 200
	volume 12
	drum 7, 0
	drum 6, 0
	gate 150
Seq_5EE7:
	volume 9
	gate 100
	drum 12, 1
	drest 1
	volume_add 2
	gate 150
	drum 7, 1
	gate 100
	volume_add -5
	drum 4, 0
	volume_add 3
	drum 3, 0
	drum 12, 1
	drest 1
	volume_add 2
	gate 150
	drum 7, 1
	gate 100
	volume_add -2
	drest 1
	snd_jump Seq_5EE7
Song15_CH3:
	length_set 12
	pan PAN_LR
	instrument 7
	volume 0
	rest_x 1
	volume 15
	base_note $1B
	snd_call Sub_5FC2
	snd_call Sub_5FC2
	base_note $17
	snd_call Sub_5FC2
	base_note $16
	snd_call Sub_5FC2
	base_note $14
	snd_loop 2
	snd_call Sub_5FC2
	snd_endloop
	base_note $16
	snd_loop 2
	snd_call Sub_5FC2
	volume_add -1
	snd_endloop
	snd_jump Seq_5F44
Song16_CH3:
	length_set 12
	pan PAN_LR
	rest_x 1
	instrument 7
Seq_5F44:
	volume 13
	snd_loop 2
	base_note $1B
	snd_loop 8
	snd_call Sub_5FC2
	snd_endloop
	base_note $19
	snd_loop 8
	snd_call Sub_5FC2
	snd_endloop
	base_note $1B
	snd_loop 8
	snd_call Sub_5FC2
	snd_endloop
	snd_loop 8
	snd_call Sub_5FBC
	snd_endloop
	base_note $1A
	snd_loop 8
	snd_call Sub_5FBC
	snd_endloop
	snd_endloop
	base_note $0F
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0E
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0F
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0E
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0F
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0E
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	base_note $0F
	snd_loop 8
	snd_call Sub_5FB6
	snd_endloop
	snd_loop 4
	note 0, 1
	note 7, 0
	note 4, 0
	snd_endloop
	snd_loop 4
	note -3, 1
	note 7, 0
	note 4, 0
	snd_endloop
	snd_jump Seq_5F44
Sub_5FB6:
	gate 255
	note -2, 1
	note 5, 0
	note 1, 0
	snd_ret
Sub_5FBC:
	gate 255
	note -14, 1
	note -2, 0
	note -11, 0
	snd_ret
Sub_5FC2:
	gate 230
	note -10, 1
	gate 255
	note 2, 0
	note -10, 0
	gate 230
	note -10, 1
	gate 255
	note 2, 0
	note -10, 0
	snd_ret
Song15_CH1:
	length_set 12
	pan PAN_LR
	volume 0
	instrument 2
	note_x -12, 2
	rest_x 220
	rest_x 100
	snd_jump Seq_5FEC
Song16_CH1:
	length_set 12
	pan PAN_LR
	volume 0
	instrument 2
	note_x -12, 2
Seq_5FEC:
	snd_loop 2
Seq_5FEE:
	instrument 26
	volume 8
	gate 0
	base_note $27
	snd_call Sub_60D4
	rest_x 40
	snd_call Sub_60E0
	rest_x 40
	base_note $25
	snd_call Sub_60D4
	rest_x 40
	snd_call Sub_60E0
	base_note $27
	snd_loop 2
	rest_x 40
	snd_call Sub_60D4
	snd_endloop
	volume 0
	rest 1
	instrument 18
	volume 7
	note 7, 1
	note 5, 1
	note 4, 1
	note 4, 3
	note 5, 1
	note_x 2, 90
	note 0, 3
	note 2, 3
	note 5, 3
	note 7, 1
	note_x 4, 129
	instrument 2
	note_x 4, 1
	snd_endloop
	instrument 35
	gate 255
	volume 6
	base_note $27
	snd_call Sub_6066
	snd_call Sub_607E
	snd_call Sub_6066
	note_x 0, 14
	note_x 2, 13
	note_x -2, 13
	note_x 2, 80
	note 0, 3
	note 2, 3
	note_x 2, 14
	note_x 4, 13
	note_x 0, 13
	gate 0
	note_x 4, 30
	note_x 3, 5
	note_x 2, 5
	note_x 1, 23
	snd_loop 8
	volume_add -1
	hold 7
	snd_endloop
	instrument 2
	note_x 1, 1
	snd_jump Seq_5FEC
Sub_6066:
	note_x -2, 14
	note_x 0, 13
	note_x 2, 13
	note -2, 3
	note 9, 3
	note 9, 3
	note 7, 3
	note 5, 3
	note 7, 3
	note 4, 4
	note 2, 0
	note 1, 0
	note_x 0, 80
	note_x -3, 14
	note_x -2, 13
	note_x 0, 13
	snd_ret
Sub_607E:
	note_x -2, 14
	note_x 0, 13
	note_x 2, 13
	note -2, 3
	note 9, 3
	note 9, 3
	note 7, 3
	note 5, 3
	note 7, 3
	note 4, 4
	note 9, 0
	note 11, 0
	note_x 12, 40
	note_x 9, 40
	note_x 4, 14
	note_x 2, 13
	note_x 0, 13
	snd_ret
	base_note $2F  ; unreferenced (stream)
	snd_call Sub_60D4
	rest 3
	snd_call Sub_60D4
	rest 0
	note 7, 0
	note 5, 0
	note 4, 0
	note 4, 1
	note 5, 0
	note 2, 0
	rest 1
	instrument 41
	gate 0
	base_note $23
	volume_add -4
	snd_loop 5
	note -5, 0
	note -2, 0
	snd_endloop
	instrument 7
	volume_add 4
	gate 255
	base_note $2F
	note 5, 1
	note 7, 0
	note 4, 0
	rest 1
	instrument 41
	gate 0
	base_note $23
	volume_add -4
	snd_loop 5
	note -3, 0
	note 1, 0
	snd_endloop
	volume_add 4
	snd_jump Seq_5FEE
Sub_60D4:
	rest 3
	note 2, 1
	note 4, 1
	note 5, 1
	note 9, 1
	note 12, 1
	note 11, 1
	rest 1
	note 7, 1
	rest 1
	note 9, 1
	snd_ret
Sub_60E0:
	rest 3
	note 2, 1
	note 4, 1
	note 5, 1
	note 9, 1
	note 12, 1
	note 11, 3
	note 14, 3
	note 9, 1
	snd_ret
Song15_CH2:
	length_set 12
	pan PAN_LR
	rest_x 1
	gate 255
	volume 8
	instrument 22
	base_note $27
	snd_loop 2
	note 5, 0
	note 0, 0
	note -3, 0
	note 0, 0
	snd_endloop
	snd_loop 2
	note 4, 0
	note 0, 0
	note -5, 0
	note 0, 0
	snd_endloop
	snd_loop 2
	note 2, 0
	note -2, 0
	note -7, 0
	note -2, 0
	snd_endloop
	snd_loop 2
	note 0, 0
	note -3, 0
	note -7, 0
	note -3, 0
	snd_endloop
	snd_loop 4
	note -2, 0
	note -5, 0
	note 2, 0
	note -5, 0
	snd_endloop
	snd_loop 2
	note -3, 0
	note -8, 0
	note 1, 0
	note -8, 0
	snd_endloop
	snd_loop 2
	volume_add -1
	note -3, 0
	note -8, 0
	note 1, 0
	note -8, 0
	snd_endloop
	snd_jump Seq_6134
Song16_CH2:
	length_set 12
	pan PAN_LR
	rest_x 1
Seq_6134:
	snd_loop 2
	base_note $27
	gate 255
	volume 5
	instrument 22
	snd_loop 16
	volume_add 3
	note 5, 0
	volume_add -3
	note 0, 0
	volume_add 3
	note 2, 0
	volume_add -3
	note -3, 0
	snd_endloop
	snd_loop 16
	volume_add 3
	note 3, 0
	volume_add -3
	note -2, 0
	volume_add 3
	note 0, 0
	volume_add -3
	note -5, 0
	snd_endloop
	snd_loop 16
	volume_add 3
	note 5, 0
	volume_add -3
	note 0, 0
	volume_add 3
	note 2, 0
	volume_add -3
	note -3, 0
	snd_endloop
	snd_loop 8
	volume_add 3
	note 2, 0
	volume_add -3
	note -2, 0
	volume_add 3
	note -7, 0
	volume_add -3
	note -2, 0
	snd_endloop
	snd_loop 4
	volume_add 3
	note 4, 0
	volume_add -3
	note 1, 0
	volume_add 3
	note -3, 0
	volume_add -3
	note 1, 0
	snd_endloop
	snd_loop 4
	volume_add 3
	note 4, 0
	volume_add -3
	note 1, 0
	volume_add 3
	note -5, 0
	volume_add -3
	note -3, 0
	snd_endloop
	snd_endloop
	base_note $27
	volume 5
	instrument 31
	snd_loop 8
	snd_call Sub_61E3
	snd_endloop
	snd_loop 8
	snd_call Sub_61DE
	snd_endloop
	snd_loop 8
	snd_call Sub_61E3
	snd_endloop
	snd_loop 8
	snd_call Sub_61DE
	snd_endloop
	snd_loop 8
	snd_call Sub_61E3
	snd_endloop
	snd_loop 8
	snd_call Sub_61DE
	snd_endloop
	snd_loop 8
	snd_call Sub_61E3
	snd_endloop
	base_note $29
	snd_loop 4
	snd_call Sub_61E3
	snd_endloop
	base_note $26
	snd_loop 4
	snd_call Sub_61E3
	volume_add -1
	snd_endloop
	snd_jump Seq_6134
Sub_61DE:
	note 9, 0
	note 4, 0
	note 0, 0
	note 4, 0
	snd_ret
Sub_61E3:
	note 10, 0
	note 5, 0
	note 2, 0
	note 5, 0
	snd_ret
Song15_CH4:
	length_set 12
	instrument 31
	drest_x 1
	pan PAN_LR
Seq_61F0:
	gate 100
	volume 5
	drum 11, 1
	gate 120
	volume 3
	drum 3, 0
	drum 2, 0
	gate 200
	volume 8
	drum 7, 1
	gate 120
	volume 3
	drum 3, 0
	drum 2, 0
	snd_jump Seq_61F0
Song17_CH4:
	length_set 14
	pan PAN_LR
	instrument 16
	gate 150
	volume 6
Seq_6213:
	drum 4, 1
	drest 3
	drum 4, 0
	drum 3, 0
	drum 4, 1
	drest 3
	drum 4, 0
	drum 3, 0
	drum 4, 1
	drum 3, 1
	drum 4, 0
	drum 3, 0
	drum 4, 0
	drum 3, 0
	drum 4, 1
	drest 5
	snd_jump Seq_6213
Song17_CH1:
	length_set 14
	pan PAN_LR
	instrument 7
	gate 255
	volume 14
Seq_6230:
	base_note $0F
	gate 100
	note -12, 1
	rest 3
	gate 200
	note -12, 0
	note -12, 0
	gate 100
	note -12, 1
	rest 3
	gate 200
	note -12, 0
	note -12, 0
	gate 100
	note -12, 1
	note -12, 1
	gate 200
	note -12, 0
	note -12, 0
	note -12, 0
	note -12, 0
	gate 100
	note -12, 1
	rest 5
	snd_jump Seq_6230
Song17_CH3:
	length_set 14
	pan PAN_LR
	instrument 16
	gate 0
	volume 8
	base_note $1B
	snd_jump Seq_6270
Song17_CH2:
	length_set 14
	pan PAN_LR
	instrument 13
	rest_x 5
	gate 0
	volume 6
	base_note $1B
Seq_6270:
	snd_loop 2
	snd_loop 4
	note 4, 0
	note 0, 0
	note 7, 0
	note 0, 0
	snd_endloop
	snd_loop 4
	note 6, 0
	note 2, 0
	note 9, 0
	note 2, 0
	snd_endloop
	snd_endloop
	snd_loop 2
	snd_loop 4
	note 7, 0
	note 3, 0
	note 10, 0
	note 3, 0
	snd_endloop
	snd_loop 4
	note 9, 0
	note 5, 0
	note 12, 0
	note 5, 0
	snd_endloop
	snd_endloop
	snd_jump Seq_6270
Song18_CH1:
	length_set 11
	pan PAN_LR
	volume 0
	gate 0
	instrument 2
	note_x 2, 1
	instrument 26
	volume 4
	gate 0
Seq_62A7:
	base_note $33
	snd_call Sub_62B4
	base_note $31
	snd_call Sub_62B4
	snd_jump Seq_62A7
Sub_62B4:
	snd_loop 5
	note_x 12, 8
	note_x 7, 7
	note_x 5, 8
	note_x 10, 7
	note_x 15, 8
	note_x 14, 7
	snd_endloop
	snd_ret
Song18_CH2:
	length_set 11
	pan PAN_LR
	gate 0
	volume 0
	instrument 1
	note_x 2, 15
	instrument 26
	volume 3
	gate 0
Seq_62D6:
	base_note $33
	snd_call Sub_62B4
	base_note $31
	snd_call Sub_62B4
	snd_jump Seq_62D6
Song19:
	db 4  ; tracks
	track Song19_CH2, CH2
	track Song19_CH4, CH4
	track Song19_CH1, CH1
	track Song19_CH3, CH3
Song20:
	db 4  ; tracks
	track Song20_CH2, CH2
	track Song20_CH1, CH1
	track Song20_CH3, CH3
	track Song20_CH4, CH4
Song21:
	db 2  ; tracks
	track Song21_CH1, CH1
	track Song21_CH2, CH2
Song22:
	db 4  ; tracks
	track Song22_CH1, CH1
	track Song22_CH2, CH2
	track Song22_CH3, CH3
	track Song22_CH4, CH4
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
	track Song24_CH4, CH4
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
	track Song26_CH3, CH3
	track Song26_CH4, CH4
Song27:
	db 4  ; tracks
	track Song27_CH1, CH1
	track Song27_CH2, CH2
	track Song27_CH3, CH3
	track Song27_CH4, CH4
Song28:
	db 4  ; tracks
	track Song28_CH1, CH1
	track Song28_CH3, CH3
	track Song28_CH2, CH2
	track Song28_CH4, CH4
Song29:
	db 3  ; tracks
	track Song29_CH2, CH2
	track Song29_CH1, CH1
	track Song29_CH3, CH3
Song30:
	db 4  ; tracks
	track Song30_CH3, CH3
	track Song30_CH1, CH1
	track Song30_CH2, CH2
	track Song30_CH4, CH4
Song31:
	db 4  ; tracks
	track Song31_CH3, CH3
	track Song31_CH1, CH1
	track Song31_CH2, CH2
	track Song31_CH4, CH4
Song32:
	db 4  ; tracks
	track Song32_CH1, CH1
	track Song32_CH2, CH2
	track Song32_CH3, CH3
	track Song32_CH4, CH4
Song33:
	db 4  ; tracks
	track Song33_CH1, CH1
	track Song33_CH2, CH2
	track Song33_CH3, CH3
	track Song33_CH4, CH4
Song34:
	db 3  ; tracks
	track Song34_CH2, CH2
	track Song34_CH1, CH1
	track Song34_CH3, CH3
Song35:
	db 4  ; tracks
	track Song35_CH3, CH3
	track Song35_CH1, CH1
	track Song35_CH2, CH2
	track Song35_CH4, CH4
Song36:
	db 3  ; tracks
	track Song36_CH3, CH3
	track Song36_CH2, CH2
	track Song36_CH1, CH1
Song19_CH2:
	length_set 4
	pan PAN_LR
	volume 3
	base_note $11
	instrument 0
	gate 0
	snd_loop 6
	note_x 1, 5
	note_x -4, 5
	note_x -11, 5
	volume_add 2
	snd_endloop
	gate 237
	note_x 1, 6
	gate 177
	note_x -4, 4
	note_x -11, 4
	volume 15
	gate 230
	snd_loop 2
	note 1, 0
	note 1, 0
	rest 1
	snd_endloop
Seq_63E9:
	instrument 27
	snd_loop 2
	base_note $12
	snd_call Sub_6432
	base_note $13
	snd_call Sub_6432
	snd_endloop
	gate 222
	base_note $12
	snd_call Sub_6447
	base_note $13
	snd_call Sub_6447
	base_note $12
	snd_call Sub_6447
	base_note $11
	snd_call Sub_6447
	base_note $12
	snd_call Sub_6447
	base_note $13
	snd_call Sub_6447
	base_note $12
	snd_call Sub_6447
	snd_loop 3
	note -1, 0
	note -13, 0
	note -13, 0
	snd_endloop
	note -5, 0
	snd_loop 4
	note_x -12, 3
	snd_endloop
	note 2, 0
	gate 184
	note -6, 0
	note -5, 0
	note -12, 0
	snd_jump Seq_63E9
Sub_6432:
	gate 149
	snd_loop 2
	note -7, 1
	note -12, 1
	note -9, 0
	note -8, 1
	note -7, 1
	note -4, 0
	gate 79
	note -3, 0
	gate 149
	note -7, 1
	note -12, 0
	note -9, 0
	note -8, 0
	snd_endloop
	snd_ret
Sub_6447:
	note 0, 0
	snd_loop 2
	rest 0
	note -12, 0
	note -12, 0
	snd_endloop
	note 0, 0
	rest 0
	note -12, 0
	rest 0
	note 0, 0
	note -5, 0
	rest 0
	note_x -14, 3
	note_x -13, 3
	note -12, 0
	snd_ret
Song19_CH4:
	length_set 4
	pan PAN_LR
	instrument 0
	gate 171
	volume 15
	drest_x 104
	drest 1
	snd_call Sub_64A1
	instrument 27
	snd_call Sub_6490
	drest 1
Seq_6471:
	snd_loop 7
	snd_call Sub_6483
	snd_call Sub_649C
	snd_endloop
	snd_call Sub_6483
	snd_call Sub_64A1
	snd_jump Seq_6471
Sub_6483:
	volume 9
	gate 222
	instrument 16
	drum 4, 1
	instrument 27
	gate 111
	drum 2, 0
	drum 1, 0
Sub_6490:
	volume 11
	drum_x 4, 1
	snd_loop 11
	volume_add -1
	hold 1
	snd_endloop
	snd_ret
Sub_649C:
	drest 0
	volume 13
	drum 1, 0
	snd_ret
Sub_64A1:
	gate 203
	instrument 16
	volume 15
	drum_x 3, 4
	drum_x 2, 4
	drum_x 1, 4
	snd_ret
Song19_CH1:
	length_set 4
	pan PAN_LR
	gate 188
	rest_x 104
	volume 10
	base_note $1D
	gate 187
	snd_loop 2
	note -4, 0
	note -4, 0
	rest 1
	snd_endloop
Seq_64C2:
	volume 10
	gate 178
	snd_loop 2
	base_note $23
	snd_call Sub_6501
	base_note $24
	snd_call Sub_6501
	snd_endloop
	snd_loop 2
	base_note $23
	instrument 37
	snd_call Sub_64EF
	base_note $24
	snd_call Sub_64EF
	base_note $23
	snd_call Sub_64EF
	base_note $21
	snd_call Sub_64EF
	snd_endloop
	snd_jump Seq_64C2
Sub_64EF:
	volume 8
	snd_loop 4
	gate 188
	note -1, 0
	gate 111
	note -1, 0
	gate 188
	note -2, 0
	gate 111
	note -2, 0
	snd_endloop
	snd_ret
Sub_6501:
	snd_loop 2
	instrument 38
	note 0, 0
	rest 0
	instrument 24
	note 3, 0
	instrument 38
	note -5, 0
	note 0, 0
	instrument 24
	note 5, 0
	instrument 38
	note 0, 0
	note -5, 0
	note -12, 0
	rest 0
	instrument 24
	note 7, 0
	instrument 38
	note 0, 0
	note -12, 0
	instrument 24
	note 5, 0
	rest 0
	instrument 38
	note -5, 0
	snd_endloop
	snd_ret
Song19_CH3:
	length_set 4
	pan PAN_LR
	volume 10
	gate 0
	instrument 0
	base_note $11
	rest_x 104
	instrument 38
	gate 178
	volume 12
	base_note $29
	snd_loop 2
	note 1, 0
	note 1, 0
	rest 1
	snd_endloop
Seq_6543:
	snd_loop 2
	gate 203
	volume 12
	base_note $23
	snd_call Sub_65B4
	base_note $24
	snd_call Sub_65B4
	snd_endloop
	base_note $23
	snd_call Sub_65A4
	base_note $24
	snd_call Sub_65A4
	base_note $23
	snd_call Sub_65A4
	base_note $22
	snd_call Sub_65A4
	base_note $23
	snd_call Sub_65A4
	base_note $24
	snd_call Sub_65A4
	base_note $23
	snd_call Sub_65A4
	snd_loop 2
	gate 188
	note 2, 0
	gate 111
	note 2, 0
	gate 188
	note 1, 0
	gate 111
	note 1, 0
	snd_endloop
	instrument 38
	base_note $2F
	gate 139
	note -5, 0
	note 5, 0
	note -11, 0
	note 1, 0
	volume 11
	base_note $17
	gate 255
	snd_loop 3
	note_x 2, 4
	volume_add -1
	note_x -5, 4
	volume_add -2
	snd_endloop
	snd_jump Seq_6543
Sub_65A4:
	snd_loop 4
	gate 188
	note 2, 0
	gate 111
	note 2, 0
	gate 188
	note 1, 0
	gate 111
	note 1, 0
	snd_endloop
	snd_ret
Sub_65B4:
	snd_loop 2
	instrument 38
	note -5, 0
	note -9, 0
	note 10, 0
	note -9, 0
	note -14, 0
	note 2, 0
	note -12, 0
	note -7, 0
	note -12, 0
	note 5, 0
	note 14, 0
	note -5, 0
	note -12, 0
	note 12, 0
	note -2, 0
	note -5, 0
	snd_endloop
	snd_ret
Song20_CH2:
	length_set 4
	pan PAN_LR
	gate 129
	instrument 7
	volume 15
	base_note $0C
	snd_loop 5
	note -7, 0
	note -7, 0
	note 5, 0
	snd_endloop
	rest 0
Seq_65DD:
	base_note $0C
	snd_call Sub_663C
	snd_call Sub_663C
	base_note $0E
	snd_call Sub_663C
	note -2, 1
	note 10, 0
	note -2, 0
	note -9, 1
	note 3, 0
	note -2, 1
	note -2, 0
	note 10, 0
	note -9, 1
	note -9, 0
	note 3, 1
	base_note $0C
	snd_call Sub_663C
	snd_call Sub_663C
	base_note $0E
	snd_call Sub_663C
	note -2, 1
	note 10, 0
	note -2, 0
	note -9, 0
	note 3, 0
	note -9, 0
	note -4, 1
	rest 1
	note -4, 0
	note 3, 0
	note -4, 0
	note -4, 1
	base_note $0F
	snd_call Sub_6649
	base_note $0E
	snd_call Sub_6649
	base_note $0C
	snd_call Sub_6649
	note -2, 1
	note 10, 0
	note -2, 1
	note -2, 0
	note 0, 0
	note 2, 0
	base_note $0F
	snd_call Sub_6649
	base_note $0E
	snd_call Sub_6649
	note -1, 1
	note 11, 0
	note 11, 0
	note 4, 0
	note -8, 0
	note 4, 0
	note 3, 1
	note -2, 1
	note 3, 1
	note -7, 0
	note -6, 0
	note -5, 0
	snd_jump Seq_65DD
Sub_663C:
	note -2, 1
	note 10, 0
	note -2, 0
	note -7, 1
	note 5, 0
	note -2, 1
	note 10, 0
	note -2, 0
	note -7, 1
	note 5, 0
	note -7, 0
	note 5, 0
	snd_ret
Sub_6649:
	snd_loop 2
	note 0, 1
	note 12, 0
	note 12, 0
	snd_endloop
	snd_ret
Song20_CH1:
	length_set 4
	pan PAN_LR
	volume 6
	gate 111
	instrument 2
	base_note $3F
	snd_loop 4
	note -6, 0
	note -5, 0
	note -3, 0
	snd_endloop
	note 2, 0
	note -10, 0
	note 2, 0
	rest 0
Seq_6666:
	volume 10
	snd_call Sub_66C8
	rest 0
	note 4, 0
	rest 1
	note 2, 0
	rest 4
	base_note $3F
	volume 6
	note -10, 0
	note -8, 0
	note -7, 0
	snd_loop 3
	note -6, 0
	volume_add -2
	snd_endloop
	rest 0
	volume 9
	snd_call Sub_66C8
	note -1, 0
	note 0, 1
	note -3, 0
	note -6, 1
	note -10, 1
	note -5, 0
	rest_x 48
	instrument 13
	volume 9
	gate 222
	base_note $27
	note 4, 0
	note 2, 1
	note 0, 1
	note -1, 0
	note -3, 1
	note 2, 3
	note -10, 3
	note -6, 0
	note -5, 1
	note -3, 1
	note 4, 0
	note 6, 0
	rest 0
	note 2, 2
	rest 4
	note 4, 0
	note 6, 1
	note 7, 1
	note 0, 0
	note 4, 1
	note 2, 3
	note -5, 3
	note 1, 0
	rest 0
	note 4, 0
	note 7, 1
	note 6, 0
	note 7, 0
	note 14, 0
	rest 1
	gate 125
	base_note $3F
	instrument 2
	volume 10
	note -10, 0
	volume 4
	note -10, 0
	volume 9
	snd_loop 4
	note 2, 0
	volume_add -1
	snd_endloop
	snd_jump Seq_6666
Sub_66C8:
	instrument 21
	gate 188
	base_note $27
	snd_loop 5
	note 2, 0
	rest 0
	note -1, 0
	snd_endloop
	note 0, 0
	note 2, 0
	rest 1
	note -5, 0
	gate 222
	rest 1
	base_note $3F
	instrument 20
	volume_add -4
	note_x 2, 4
	note_x 4, 4
	note_x 6, 4
	volume_add 2
	gate 188
	note 7, 0
	note -5, 0
	volume_add 2
	base_note $27
	instrument 21
	note -10, 0
	note -10, 0
	note 2, 0
	note 0, 0
	note -1, 1
	snd_loop 5
	note 0, 0
	rest 0
	note -3, 0
	snd_endloop
	snd_ret
Song20_CH4:
	length_set 4
	pan PAN_LR
	gate 111
	volume 9
	instrument 16
	snd_loop 3
	drum 2, 0
	drest 2
	snd_endloop
Seq_670E:
	gate 111
	volume 9
	instrument 27
	drum 3, 0
	drum 2, 0
	gate 0
	volume 13
	drum_x 1, 1
	snd_loop 11
	volume_add -1
	hold 1
	snd_endloop
	snd_jump Seq_670E
Song20_CH3:
	length_set 4
	pan PAN_LR
	snd_loop 4
	rest 3
	snd_endloop
Seq_672E:
	volume 9
	gate 111
	instrument 1
	base_note $33
	snd_loop 8
	snd_call Sub_6785
	snd_endloop
	base_note $35
	snd_loop 8
	snd_call Sub_6785
	snd_endloop
	base_note $33
	snd_loop 8
	snd_call Sub_6785
	snd_endloop
	base_note $35
	snd_loop 5
	snd_call Sub_6785
	snd_endloop
	note -8, 0
	note -14, 0
	note -2, 0
	note -3, 0
	rest_x 48
	base_note $33
	snd_call Sub_678A
	note -12, 0
	note -3, 0
	note -6, 0
	note -3, 0
	note 4, 0
	note 0, 0
	note -6, 0
	note 2, 0
	note -10, 0
	note -1, 0
	note -2, 0
	note -1, 0
	note 2, 0
	note -5, 0
	note 7, 0
	note -5, 0
	snd_call Sub_678A
	note -10, 0
	note -2, 0
	note -3, 0
	note -2, 0
	note -11, 0
	note -2, 0
	note -3, 0
	note -2, 0
	note -3, 0
	note -12, 0
	note -6, 0
	note -3, 0
	note 4, 0
	note 2, 0
	note 0, 0
	note -6, 0
	snd_jump Seq_672E
Sub_6785:
	note -10, 0
	note -5, 0
	note -8, 0
	note -5, 0
	snd_ret
Sub_678A:
	snd_loop 2
	note -8, 0
	note 0, 0
	note -1, 0
	note 0, 0
	snd_endloop
	snd_loop 2
	note -10, 0
	note -1, 0
	note -2, 0
	note -1, 0
	snd_endloop
	snd_ret
Song21_CH1:
	length_set 4
	pan PAN_LR
	volume 11
Seq_679F:
	gate 0
	instrument 14
	base_note $38
Seq_67A5:
	note 2, 1
	note 7, 1
	note 11, 1
	note 9, 1
	note 7, 1
	note 4, 1
	snd_jump Seq_67A5
Song21_CH2:
	length_set 4
	pan PAN_LR
	volume 11
	rest 2
	snd_jump Seq_679F
Song24_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	note 4, 0
	volume 4
	note 4, 0
	volume 12
	note 7, 0
	note 12, 0
	snd_end
Song23_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	snd_jump Seq_6834
Song25_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -3, 0
	note -1, 0
	snd_jump Seq_6833
Song26_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	note 0, 0
	note -5, 0
	note 0, 0
	note 4, 0
	note -8, 0
	snd_jump Seq_682E
Song22_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	snd_call Sub_6839
	note 0, 1
	note -5, 0
	note -8, 2
	snd_call Sub_6839
	note 0, 2
	note -8, 2
Song27_CH1:
	length_set 3
	pan PAN_LR
	instrument 10
	volume 12
	gate 255
	base_note $33
	snd_call Sub_6839
	note 0, 1
	note -5, 0
	note -8, 1
Seq_682E:
	note 7, 0
	note 5, 1
	note 4, 0
	note 2, 1
	note 4, 0
Seq_6833:
	note 0, 2
Seq_6834:
	note_x 12, 10
	rest_x 11
	snd_end
Sub_6839:
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -3, 0
	note -1, 0
	snd_ret
Song23_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	snd_jump Seq_68BF
Song24_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	note 0, 0
	volume 4
	note 0, 0
	volume 11
	note 5, 0
	note 4, 0
	snd_end
Song25_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	note -10, 0
	note -10, 0
	note -10, 0
	note -7, 0
	note -7, 0
	note -7, 0
	snd_jump Seq_68BE
Song26_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	note -8, 0
	note -12, 0
	note -5, 0
	note 0, 0
	rest 0
	note -8, 0
	snd_jump Seq_68B9
Song22_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	snd_call Sub_68C4
	note -8, 2
	note -12, 1
	note -5, 0
	snd_call Sub_68C4
	note -8, 1
	note -7, 0
	note -5, 1
	note -12, 0
Song27_CH2:
	length_set 3
	pan PAN_LR
	instrument 10
	gate 255
	volume 11
	base_note $33
	snd_call Sub_68C4
	note -8, 2
	note -12, 1
	note 4, 0
Seq_68B9:
	note 2, 1
	note -1, 0
	note -5, 0
	note -3, 0
	note -1, 0
Seq_68BE:
	note -8, 2
Seq_68BF:
	note_x 4, 10
	rest_x 11
	snd_end
Sub_68C4:
	note -12, 0
	note -10, 0
	note -7, 0
	note -7, 0
	note -7, 0
	note -7, 0
	snd_ret
Song23_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $1B
	snd_jump Seq_693F
Song24_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $27
	snd_jump Seq_693B
Song25_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $27
	snd_jump Seq_6935
Song26_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $27
	snd_jump Seq_6931
Song22_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
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
Song27_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	volume 15
	gate 255
	base_note $27
	note 2, 1
	note 2, 0
	note 7, 1
	note 7, 0
Seq_6931:
	note 0, 1
	note -12, 0
	note -12, 1
	note 0, 0
Seq_6935:
	note -7, 0
	note -5, 0
	note -3, 0
	note -1, 0
	note -3, 0
	note -1, 0
Seq_693B:
	note 0, 1
	base_note $1B
	note -5, 0
Seq_693F:
	note -12, 0
	rest 1
	snd_end
Song23_CH4:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 16
	gate 235
	snd_jump Seq_69C6
Song24_CH4:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 16
	gate 235
	snd_jump Seq_69C3
Song25_CH4:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 16
	gate 235
	drum 6, 1
	drum 6, 0
	drum 6, 0
	volume_add -4
	drum 3, 0
	volume_add 4
	drum 6, 0
	drum 3, 0
	drum 3, 0
	drum 3, 0
	drum 3, 0
	drest 1
	snd_end
Song26_CH4:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 16
	gate 235
	snd_loop 2
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
Song27_CH4:
	length_set 3
	pan PAN_LR
	volume 10
	instrument 16
	gate 235
	snd_loop 3
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
Song22_CH4:
	length_set 3
	pan PAN_LR
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
Seq_69C3:
	drum 3, 0
	drum 3, 0
	drum 3, 0
Seq_69C6:
	drum 3, 0
	drest 1
	snd_end
Song28_CH1:
	length_set 2
	pan PAN_LR
	instrument 41
	gate 150
Seq_69D1:
	snd_loop 2
	base_note $40
	snd_call Sub_69F1
	base_note $34
	snd_call Sub_69FE
	snd_endloop
	base_note $40
	snd_call Sub_69F1
	snd_call Sub_69FE
	snd_call Sub_69F1
	base_note $34
	snd_call Sub_69FE
	snd_jump Seq_69D1
Sub_69F1:
	volume 5
	note 2, 0
	volume 3
	note 2, 0
	volume 5
	note 0, 0
	volume 3
	note 0, 0
	snd_ret
Sub_69FE:
	volume 5
	note 7, 0
	volume 3
	note 7, 0
	snd_ret
Song28_CH3:
	length_set 2
	pan PAN_LR
	instrument 1
	gate 133
Seq_6A0D:
	base_note $10
	snd_call Sub_6A1A
	base_note $0F
	snd_call Sub_6A1A
	snd_jump Seq_6A0D
Sub_6A1A:
	volume 12
	snd_loop 5
	note 10, 0
	volume_add -2
	snd_endloop
	rest 0
	volume 14
	snd_loop 6
	note -2, 0
	volume_add -3
	snd_endloop
	rest 3
	volume 6
	note 10, 0
	rest 0
	volume 13
	snd_loop 6
	note 10, 0
	volume_add -2
	snd_endloop
	snd_ret
Song28_CH2:
	length_set 2
	pan PAN_LR
	volume 5
	instrument 41
	base_note $28
	gate 97
	note 5, 0
	gate 150
	note 5, 0
	snd_jump Song28_CH2
Song28_CH4:
	length_set 2
	pan PAN_LR
	volume 11
	instrument 16
	gate 72
	drum 1, 1
	snd_jump Song28_CH4
Song29_CH2:
	length_set 2
	pan PAN_LR
	volume 6
	instrument 31
Seq_6A62:
	base_note $3F
	gate 144
	snd_call Sub_6A71
	base_note $3D
	snd_call Sub_6A71
	snd_jump Seq_6A62
Sub_6A71:
	snd_loop 2
	note 7, 0
	rest 0
	note -5, 0
	note -5, 0
	rest 4
	note 7, 0
	note 7, 0
	note 7, 0
	snd_endloop
	snd_ret
Song29_CH1:
	length_set 2
	pan PAN_LR
	volume 8
	instrument 31
	base_note $27
	gate 200
	snd_call Sub_6AAD
	note 0, 1
	note 0, 0
	snd_call Sub_6AAD
	note -1, 1
	note -1, 0
	base_note $25
	snd_call Sub_6AAD
	note 0, 1
	note 0, 0
	note -1, 0
	base_note $3F
	rest 3
	volume 5
	gate 154
	note -12, 0
	snd_loop 3
	note -7, 0
	note 5, 0
	volume_add -2
	snd_endloop
	snd_jump Song29_CH1
Sub_6AAD:
	note -1, 1
	note -1, 0
	note 0, 1
	note 0, 0
	note 2, 1
	note 2, 0
	snd_ret
Song29_CH3:
	length_set 2
	pan PAN_LR
	gate 100
	volume 5
	instrument 1
	base_note $27
	snd_call Sub_6ADA
	note 9, 0
	rest 0
	note 2, 0
	snd_call Sub_6ADA
	note 7, 0
	note 14, 0
	note 7, 0
	base_note $25
	snd_call Sub_6ADA
	note 9, 0
	rest 0
	note 2, 0
	note 7, 0
	rest_x 99
	snd_jump Song29_CH3
Sub_6ADA:
	note 7, 0
	rest 0
	note 2, 0
	note 9, 0
	rest 0
	note 2, 0
	note 11, 0
	rest 0
	note 2, 0
	snd_ret
Song30_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	base_note $20
	volume 10
	gate 255
	snd_call Sub_6B7B
	snd_call Sub_6B72
	snd_call Sub_6B7B
	snd_call Sub_6B6B
Song31_CH3:
	length_set 3
	pan PAN_LR
	instrument 7
	base_note $20
	volume 10
	gate 255
Seq_6B08:
	snd_loop 4
	snd_call Sub_6B51
	snd_endloop
	snd_call Sub_6B3A
	snd_call Sub_6B3A
	base_note $23
	snd_call Sub_6B3A
	base_note $20
	snd_call Sub_6B21
	snd_jump Seq_6B08
Sub_6B21:
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
Sub_6B3A:
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
Sub_6B51:
	note -12, 0
	rest 0
	note -12, 0
	rest 0
	note -5, 1
	snd_loop 3
	rest 0
	note -10, 0
	snd_endloop
	note -3, 1
	note -10, 0
	note -9, 0
	note -8, 0
	rest 0
	note -8, 0
	rest 0
	note -1, 1
	snd_loop 3
	rest 0
	note -10, 0
	snd_endloop
	note -3, 1
	note -10, 1
	snd_ret
Sub_6B6B:
	note 2, 0
	note 2, 0
	rest 1
	note 7, 0
	note 7, 0
	rest 1
	snd_ret
Sub_6B72:
	note -10, 0
	note -3, 0
	note 2, 0
	rest 0
	note -10, 0
	note 2, 0
	rest 0
	note -3, 0
	snd_ret
Sub_6B7B:
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
Song30_CH1:
	length_set 3
	pan PAN_LR
	instrument 21
	gate 250
	volume 7
	base_note $2C
	snd_call Sub_6C59
	snd_call Sub_6C4F
	snd_call Sub_6C59
	snd_call Sub_6C44
Song31_CH1:
	length_set 3
	pan PAN_LR
Seq_6BAF:
	gate 0
	instrument 13
	volume 5
	base_note $2C
	snd_call Sub_6C27
	volume 10
	instrument 21
	note 4, 2
	volume_add -6
	snd_call Sub_6C08
	note 0, 0
	note 2, 0
	rest 0
	note 4, 1
	instrument 17
	volume_add -6
	note -3, 0
	note 4, 0
	snd_call Sub_6C08
	snd_call Sub_6BD7
	snd_jump Seq_6BAF
Sub_6BD7:
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
Sub_6C08:
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
Sub_6C27:
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
Sub_6C44:
	note 0, 0
	volume_add -2
	note 0, 0
	volume_add 2
	rest 1
	note 0, 0
	note 0, 0
	rest 1
	snd_ret
Sub_6C4F:
	rest 1
	note 0, 1
	rest 0
	volume_add -1
	note 0, 1
	volume_add 1
	rest 0
	snd_ret
Sub_6C59:
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
Song30_CH2:
	length_set 3
	pan PAN_LR
	volume 9
	instrument 21
	gate 255
	base_note $2C
	snd_call Sub_6D2F
	snd_call Sub_6D45
	snd_call Sub_6D2F
	snd_call Sub_6D4F
Song31_CH2:
	length_set 3
	pan PAN_LR
	base_note $2C
Seq_6C8D:
	instrument 11
	gate 190
	volume 8
	snd_loop 4
	snd_call Sub_6D0E
	snd_endloop
	volume 12
	instrument 21
	note 0, 2
	volume_add -6
	snd_call Sub_6CEF
	note -3, 0
	note -1, 0
	rest 0
	note 0, 1
	instrument 17
	volume_add -6
	note -7, 0
	note 0, 0
	snd_call Sub_6CEF
	note -1, 0
	rest 0
	note 2, 0
	snd_call Sub_6CB9
	snd_jump Seq_6C8D
Sub_6CB9:
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
Sub_6CEF:
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
Sub_6D0E:
	note -8, 0
	note -5, 0
	note -1, 0
	note -5, 0
	note -8, 0
	note -5, 0
	note -1, 0
	note -5, 0
	note -7, 0
	note -3, 0
	note 0, 0
	note -3, 0
	note -7, 0
	note -3, 0
	note 0, 0
	note -3, 0
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note -5, 0
	note -1, 0
	note 2, 0
	note -1, 0
	note -7, 0
	note -3, 0
	note 0, 0
	note -7, 0
	note -3, 0
	note 0, 0
	note -7, 0
	note -3, 0
	snd_ret
Sub_6D2F:
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
Sub_6D45:
	rest 1
	note -7, 1
	rest 0
	volume_add -1
	note -7, 1
	volume_add 1
	rest 0
	snd_ret
Sub_6D4F:
	note -7, 0
	volume_add -2
	note -7, 0
	volume_add 2
	rest 1
	note -7, 0
	note -7, 0
	rest 1
	snd_ret
Song30_CH4:
	length_set 3
	pan PAN_LR
	volume 9
	gate 255
	instrument 16
	snd_loop 7
	snd_call Sub_6D8F
	snd_endloop
	snd_call Sub_6DA0
Song31_CH4:
	length_set 3
	pan PAN_LR
	volume 7
	gate 255
	instrument 16
Seq_6D77:
	snd_loop 2
	snd_loop 12
	snd_call Sub_6DA5
	snd_endloop
	snd_call Sub_6DAE
	snd_endloop
	snd_loop 14
	snd_call Sub_6D8F
	snd_endloop
	snd_call Sub_6DAE
	snd_jump Seq_6D77
Sub_6D8F:
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
Sub_6DA0:
	drum 5, 0
	drum 5, 2
	drum 5, 0
	drum 5, 2
	snd_ret
Sub_6DA5:
	drum 6, 0
	volume_add -4
	drum 6, 0
	volume_add 4
	drum 5, 0
	drum 6, 0
	snd_ret
Sub_6DAE:
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
Song32_CH1:
	length_set 4
	pan PAN_LR
	gate 166
	volume 7
	instrument 22
	base_note $27
	snd_loop 14
	note 7, 0
	note 0, 0
	note 2, 0
	note 0, 0
	snd_endloop
	note 7, 0
	rest 2
	rest 3
Song33_CH1:
	length_set 4
	pan PAN_LR
	gate 166
	volume 7
	instrument 41
	base_note $27
	snd_call Sub_6E95
	snd_call Sub_6EB9
	snd_call Sub_6E95
	snd_call Sub_6E9F
	volume 4
	gate 160
	instrument 41
	base_note $32
	snd_call Sub_6E95
	snd_call Sub_6EB9
	snd_call Sub_6E95
	snd_call Sub_6EC1
	gate 187
	base_note $0F
	snd_call Sub_6E5E
	base_note $0E
	snd_call Sub_6E5E
	base_note $0F
	snd_call Sub_6E5E
	base_note $11
	snd_call Sub_6E5E
	gate 133
	base_note $1C
	snd_call Sub_6E5E
	base_note $20
	snd_call Sub_6E5E
	base_note $1D
	snd_call Sub_6E5E
	base_note $23
	snd_call Sub_6E5E
	base_note $22
	snd_call Sub_6E5E
	snd_call Sub_6E5E
	base_note $21
	snd_call Sub_6E5E
	snd_call Sub_6E7A
	volume 7
	instrument 27
	gate 251
	note 6, 0
	gate 133
	note -6, 0
	base_note $09
	note 13, 0
	note 6, 0
	gate 199
	instrument 7
	note 6, 0
	note -6, 0
	note_x 6, 4
	note_x 1, 4
	note_x -6, 4
	snd_jump Song33_CH1
Sub_6E5E:
	instrument 21
	volume 9
	note -6, 0
	instrument 2
	volume_add -5
	note 6, 0
	volume_add 2
	note 1, 0
	instrument 21
	note 1, 0
	note 4, 0
	volume_add -4
	note 4, 0
	volume_add 2
	instrument 23
	note 1, 0
	note -6, 0
	instrument 21
Sub_6E7A:
	note -6, 0
	volume_add 2
	instrument 3
	note 6, 0
	instrument 1
	note 1, 0
	instrument 2
	note 1, 0
	instrument 21
	note 4, 0
	volume_add -4
	note 4, 0
	volume_add 4
	instrument 2
	note 1, 0
	volume_add -4
	note 1, 0
	snd_ret
Sub_6E95:
	note 9, 1
	note 11, 1
	note 12, 1
	note 7, 1
	note 9, 1
	note 11, 0
	note 12, 0
	note 7, 1
	rest 1
	snd_ret
Sub_6E9F:
	note 5, 1
	note 4, 1
	note 0, 1
	note -3, 1
	note 2, 1
	gate 160
	instrument 15
	base_note $3F
	note_x 7, 4
	note_x -5, 4
	base_note $27
	note_x 7, 4
	volume 4
	note_x -5, 8
	rest_x 16
	snd_ret
Sub_6EB9:
	note 5, 1
	note 4, 1
	note 2, 1
	note 0, 1
	note 4, 1
	note 2, 1
	rest 3
	snd_ret
Sub_6EC1:
	note 6, 1
	note 5, 1
	note 1, 1
	note -2, 1
	note 3, 1
	instrument 14
	volume 4
	gate 0
	note_x 0, 4
	note_x 6, 4
	note_x 10, 4
	base_note $3E
	volume 6
	note_x 3, 4
	volume 4
	note_x 3, 4
	volume 2
	note_x 3, 4
	volume 5
	note 3, 0
	rest 0
	snd_ret
Song32_CH4:
	length_set 4
	pan PAN_LR
	volume 9
	instrument 16
	gate 100
	snd_loop 16
	snd_call Sub_6F44
	snd_endloop
Song33_CH4:
	length_set 4
	pan PAN_LR
	volume 9
	instrument 16
	gate 100
	snd_loop 31
	drest 1
	drum 1, 0
	drest 0
	snd_endloop
Seq_6F05:
	drest 0
	gate 154
	snd_loop 3
	drum 3, 0
	snd_endloop
	volume 7
	snd_loop 16
	drum 3, 0
	drum 1, 0
	drum 2, 0
	drum 1, 0
	snd_endloop
	snd_loop 8
	drum 3, 0
	drum 1, 0
	drum 2, 0
	drum 1, 0
	gate 255
	drum 2, 0
	gate 100
	drum 1, 0
	drum 2, 0
	drum 1, 0
	snd_endloop
	snd_loop 8
	drum 3, 0
	drum 1, 0
	gate 233
	drum 2, 0
	gate 142
	drum 1, 0
	gate 255
	drum 3, 0
	gate 100
	drum 1, 0
	gate 255
	drum 1, 0
	gate 100
	drum 1, 0
	snd_endloop
	snd_loop 31
	snd_call Sub_6F44
	snd_endloop
	snd_jump Seq_6F05
Sub_6F44:
	gate 200
	drum 3, 0
	drest 0
	gate 140
	drum 1, 0
	gate 100
	drum 1, 0
	snd_ret
Song32_CH3:
	length_set 4
	volume 0
	base_note $0F
	instrument 2
	note_x 0, 1
	pan PAN_LR
	volume 10
	gate 90
	instrument 27
	base_note $3F
	snd_call Sub_6F91
	snd_call Sub_6F91
	base_note $3E
	snd_call Sub_6F9A
	base_note $3C
	snd_call Sub_6F9A
	base_note $41
	snd_call Sub_6F91
	note 5, 0
	rest 0
	gate 180
	note_x -9, 3
	note_x -14, 3
	gate 90
	note -5, 0
	note 2, 0
	note 0, 0
	gate 180
	note_x 5, 3
	note_x 0, 3
	gate 90
	note -7, 0
	snd_jump Seq_6FB4
Sub_6F91:
	note 5, 0
	note 5, 0
	note 0, 0
	note -3, 0
	note 5, 0
	note 0, 0
	note 0, 0
	note -3, 0
	snd_ret
Sub_6F9A:
	snd_loop 2
	note 5, 0
	note 3, 0
	note -4, 0
	note -7, 0
	note 5, 0
	note -4, 0
	note -4, 0
	note -7, 0
	snd_endloop
	snd_ret
Song33_CH3:
	length_set 4
	volume 0
	pan PAN_LR
	gate 130
	base_note $1B
	instrument 13
	note_x 5, 1
Seq_6FB4:
	instrument 27
	base_note $33
	snd_call Sub_7071
	snd_call Sub_7050
	snd_call Sub_7061
	base_note $33
	snd_call Sub_7071
	base_note $33
	snd_call Sub_7050
	rest_x 42
	base_note $32
	volume 9
	snd_call Sub_7071
	snd_call Sub_7050
	rest_x 17
	note -1, 0
	note -5, 0
	note 7, 0
	volume_add -5
	note_x 7, 7
	volume_add 5
	snd_call Sub_7071
	base_note $33
	snd_call Sub_7050
	rest_x 42
	base_note $3F
	snd_call Sub_7042
	base_note $3E
	snd_call Sub_7042
	base_note $3F
	snd_call Sub_7042
	base_note $41
	snd_call Sub_7042
	gate 230
	base_note $40
	snd_call Sub_7034
	base_note $44
	snd_call Sub_7034
	base_note $41
	snd_call Sub_7034
	base_note $47
	snd_call Sub_7034
	base_note $46
	snd_loop 4
	snd_call Sub_702B
	snd_endloop
	base_note $45
	snd_loop 3
	snd_call Sub_702B
	snd_endloop
	rest_x 47
	snd_jump Song33_CH3
Sub_702B:
	note -2, 0
	note -9, 0
	note -8, 0
	note 1, 0
	note -14, 0
	note -4, 0
	note -8, 0
	note -6, 0
	snd_ret
Sub_7034:
	volume 7
	snd_loop 2
	note -4, 0
	note -14, 0
	note -8, 0
	note -11, 0
	note -1, 0
	note -11, 0
	note -4, 0
	note -11, 0
	snd_endloop
	snd_ret
Sub_7042:
	volume 7
	instrument 12
	snd_loop 2
	note -6, 1
	note -11, 0
	note 6, 0
	note -11, 0
	note -6, 1
	note -11, 0
	snd_endloop
	snd_ret
Sub_7050:
	snd_loop 2
	note 2, 0
	volume_add -5
	note 2, 0
	volume_add 5
	note -10, 0
	volume_add -5
	note -10, 0
	volume_add 5
	snd_endloop
	note 7, 0
	snd_ret
Sub_7061:
	gate 111
	rest 2
	note 14, 0
	note 7, 0
	volume 9
	base_note $3F
	note 7, 0
	volume_add -3
	note 7, 0
	volume_add 5
	snd_ret
Sub_7071:
	snd_loop 2
	volume 13
	note 5, 0
	volume_add -5
	note 5, 0
	volume_add 5
	note -3, 0
	volume_add -5
	note -3, 0
	volume_add 5
	note 4, 0
	volume_add -5
	note 4, 0
	volume_add 5
	note -5, 0
	volume_add -5
	note -5, 0
	volume_add 5
	snd_endloop
	snd_ret
Song32_CH2:
	length_set 4
	pan PAN_LR
	gate 136
	instrument 7
	volume 15
	base_note $13
	snd_loop 4
	snd_call Sub_714A
	snd_endloop
	base_note $12
	snd_loop 4
	snd_call Sub_714A
	snd_endloop
	base_note $10
	snd_loop 4
	snd_call Sub_714A
	snd_endloop
	base_note $15
	snd_call Sub_714A
	snd_call Sub_714A
	note -11, 0
	rest 2
	rest 3
Song33_CH2:
	length_set 4
	pan PAN_LR
	volume 12
	gate 136
	instrument 7
	base_note $12
	snd_loop 2
	snd_loop 2
	snd_call Sub_7143
	snd_endloop
	snd_call Sub_712D
	snd_endloop
	base_note $11
	snd_loop 2
	snd_call Sub_7143
	snd_endloop
	snd_call Sub_712D
	snd_loop 2
	snd_call Sub_7143
	snd_endloop
	base_note $12
	snd_call Sub_712D
	gate 121
	instrument 2
	volume 9
	base_note $20
	snd_call Sub_715A
	base_note $1F
	snd_call Sub_715A
	base_note $20
	snd_call Sub_715A
	base_note $22
	snd_call Sub_715A
	base_note $21
	snd_call Sub_715A
	base_note $25
	snd_call Sub_715A
	base_note $22
	snd_call Sub_715A
	base_note $1C
	snd_call Sub_715A
	base_note $27
	snd_call Sub_715A
	snd_call Sub_715A
	base_note $26
	snd_call Sub_7152
	note 13, 0
	note 5, 0
	note 11, 0
	note 13, 0
	rest 3
	snd_jump Song33_CH2
Sub_712D:
	note -13, 1
	volume_add -4
	note -1, 0
	volume_add 4
	note -13, 0
	note -13, 1
	volume_add -4
	note -1, 0
	volume_add 4
	note -13, 0
	note -8, 1
	volume_add -4
	note 4, 0
	volume_add 4
	rest 4
	snd_ret
Sub_7143:
	note -10, 1
	volume_add -4
	note 2, 0
	volume_add 4
	note -10, 0
Sub_714A:
	note -11, 1
	volume_add -4
	note 1, 0
	volume_add 4
	note -11, 0
	snd_ret
Sub_7152:
	snd_loop 6
	note -11, 0
	note 8, 0
	note 11, 0
	note 5, 0
	snd_endloop
	snd_ret
Sub_715A:
	snd_loop 4
	note -11, 0
	note 1, 0
	note 12, 0
	note 5, 0
	snd_endloop
	snd_ret
Song34_CH2:
	length_set 5
	pan PAN_LR
	gate 93
	instrument 22
	volume 10
	base_note $30
	snd_call Sub_7179
	base_note $32
	snd_call Sub_7179
	snd_jump Song34_CH2
Sub_7179:
	snd_loop 8
	note -12, 0
	volume_add -4
	note -12, 0
	volume_add 4
	note -5, 0
	volume_add -4
	note -5, 0
	volume_add 4
	snd_endloop
	snd_ret
Song34_CH1:
	length_set 5
	rest 0
Seq_718C:
	pan PAN_LR
	gate 99
	instrument 22
	volume 9
	base_note $30
	snd_call Sub_71C1
	snd_call Sub_719F
	snd_jump Seq_718C
Sub_719F:
	snd_loop 2
	snd_loop 2
	note 5, 0
	volume_add -4
	note 5, 0
	volume_add 4
	note 0, 0
	volume_add -4
	note 0, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note 5, 0
	volume_add -4
	note 5, 0
	volume_add 4
	note -1, 0
	volume_add -4
	note -1, 0
	volume_add 4
	snd_endloop
	snd_endloop
	snd_ret
Sub_71C1:
	snd_loop 2
	snd_loop 2
	note 4, 0
	volume_add -4
	note 4, 0
	volume_add 4
	note -1, 0
	volume_add -4
	note -1, 0
	volume_add 4
	snd_endloop
	snd_loop 2
	note 4, 0
	volume_add -4
	note 4, 0
	volume_add 4
	note -3, 0
	volume_add -4
	note -3, 0
	volume_add 4
	snd_endloop
	snd_endloop
	snd_ret
Song34_CH3:
	length_set 5
	pan PAN_LR
	gate 80
	instrument 7
Seq_71EB:
	volume 15
	base_note $1B
	snd_call Sub_7210
	note -8, 0
	rest 0
	snd_call Sub_7210
	note -8, 0
	volume_add -8
	note -15, 0
	volume_add 8
	base_note $1D
	snd_call Sub_7210
	note -8, 0
	rest 0
	snd_call Sub_7210
	note -10, 0
	base_note $11
	volume_add -8
	note -10, 0
	snd_jump Seq_71EB
Sub_7210:
	note -3, 0
	rest 0
	note -3, 0
	rest_x 56
	volume_add -8
	note -3, 0
	volume_add 8
	note -3, 0
	rest 1
	snd_ret
Song35_CH3:
	length_set 5
	pan PAN_LR
	volume 10
	gate 123
	instrument 3
	base_note $18
	snd_call Sub_7265
	base_note $16
	snd_call Sub_7265
	base_note $14
	snd_call Sub_7265
	gate 160
	rest_x 6
	note_x -10, 5
	note_x -5, 5
	gate 99
	note -8, 1
	note -7, 1
	note -6, 0
	note -6, 1
	instrument 32
	gate 230
	volume 6
	base_note $21
	note_x -15, 4
	note_x -9, 4
	gate 94
	note -7, 0
	note 0, 0
	note 12, 0
	note -7, 0
	gate 200
	note_x 5, 5
	volume 4
	note_x 5, 5
	volume 2
	note_x 5, 6
	snd_jump Song35_CH3
Sub_7265:
	note -5, 1
	note -5, 1
	note -3, 1
	note -3, 0
	note -3, 0
	note -2, 0
	note -1, 1
	note -5, 1
	note -5, 0
	note -10, 1
	snd_ret
Song35_CH1:
	length_set 5
	pan PAN_LR
	volume 5
	gate 111
	instrument 41
	base_note $24
	snd_call Sub_7296
	base_note $22
	snd_call Sub_7296
	base_note $20
	snd_call Sub_7296
	note 1, 0
	note 0, 0
	note 1, 0
	note -1, 0
	note -2, 0
	note 1, 0
	note 8, 0
	note 6, 0
	rest_x 64
	snd_jump Song35_CH1
Sub_7296:
	note 2, 0
	note 1, 0
	note 2, 0
	rest 0
	note 2, 0
	note 1, 0
	note 2, 0
	note 2, 0
	volume_add -4
	note -1, 0
	volume_add 4
	snd_loop 2
	note 2, 0
	note 1, 0
	note 2, 0
	snd_endloop
	rest 0
	snd_ret
Song35_CH2:
	length_set 5
	pan PAN_LR
	gate 90
	instrument 24
	base_note $30
	volume 6
	snd_loop 4
	snd_call Sub_72E5
	snd_endloop
	snd_call Sub_72C3
	snd_jump Song35_CH2
Sub_72C3:
	snd_loop 2
	note -7, 0
	rest 0
	note -5, 0
	note 0, 0
	note -2, 0
	rest 0
	note -3, 0
	note -5, 0
	snd_endloop
	note -5, 0
	rest 0
	note 0, 0
	note 4, 0
	note 2, 0
	rest 0
	note -5, 0
	note -6, 0
	rest 0
	note 4, 0
	note 0, 0
	note -5, 0
	note 6, 0
	note -3, 0
	gate 160
	note_x 2, 5
	note_x -3, 5
	note_x -10, 6
	snd_ret
Sub_72E5:
	note -5, 0
	rest 0
	note -3, 0
	note 2, 0
	note 1, 0
	rest 0
	note -1, 0
	note -3, 0
	snd_ret
Song35_CH4:
	length_set 5
	pan PAN_LR
	gate 90
	instrument 16
	volume 8
	drum 1, 0
	volume 4
	drum 1, 0
	gate 0
	volume 11
	drum 9, 0
	volume 0
	drum 1, 0
	snd_jump Song35_CH4
Song36_CH3:
	length_set 3
	pan PAN_LR
	instrument 13
	gate 0
	base_note $34
	volume 9
	snd_loop 10
	note 4, 0
	note -3, 0
	snd_endloop
	snd_loop 10
	note 2, 0
	note -5, 0
	snd_endloop
	snd_jump Song36_CH3
Song36_CH2:
	length_set 3
	pan PAN_LR
	gate 122
	instrument 25
	base_note $10
	snd_call Sub_733F
	base_note $0F
	snd_call Sub_733F
	base_note $0D
	snd_call Sub_733F
	base_note $0B
	snd_call Sub_733F
	snd_jump Song36_CH2
Sub_733F:
	snd_loop 2
	volume 12
	note -7, 2
	volume_add -4
	note 5, 1
	rest 0
	note -7, 1
	note -7, 1
	snd_endloop
	snd_ret
Song36_CH1:
	length_set 3
	pan PAN_LR
	volume 5
	instrument 14
	base_note $34
	gate 199
	note 7, 1
	note 4, 1
	note 0, 1
	note -3, 1
	note -10, 1
	note -15, 1
	note -8, 1
	note -7, 1
	note 0, 1
	note 9, 1
	note 7, 1
	note 2, 1
	note -6, 1
	note -10, 1
	note -15, 1
	note -13, 1
	note -5, 1
	note 4, 1
	note 6, 1
	note 14, 1
	note 4, 1
	note 2, 1
	note 0, 1
	note -7, 1
	note -15, 1
	base_note $28
	note -7, 1
	base_note $34
	note -12, 1
	note -3, 1
	note 4, 1
	note 14, 1
	note 11, 1
	note 7, 1
	note 2, 1
	note -3, 1
	note -8, 1
	base_note $28
	note -8, 1
	base_note $34
	note -10, 1
	note -5, 1
	note 2, 1
	note 14, 1
	snd_jump Song36_CH1
Song37:
	db 4  ; tracks
	track Song37_CH2, CH2
	track Song37_CH1, CH1
	track Song37_CH3, CH3
	track Song37_CH4, CH4
Song38:
	db 4  ; tracks
	track Song38_CH2, CH2
	track Song38_CH1, CH1
	track Song37_CH4, CH4
	track Song38_CH3, CH3
Song39:
	db 4  ; tracks
	track Song39_CH3, CH3
	track Song39_CH1, CH1
	track Song39_CH2, CH2
	track Song39_CH4, CH4
Song40:
	db 4  ; tracks
	track Song40_CH2, CH2
	track Song40_CH3, CH3
	track Song40_CH4, CH4
	track Song40_CH1, CH1
Song41:
	db 4  ; tracks
	track Song41_CH2, CH2
	track Song41_CH1, CH1
	track Song41_CH3, CH3
	track Song41_CH4, CH4
Song42:
	db 4  ; tracks
	track Song42_CH1, CH1
	track Song42_CH2, CH2
	track Song42_CH3, CH3
	track Song42_CH4, CH4
Song43:
	db 4  ; tracks
	track Song43_CH3, CH3
	track Song43_CH2, CH2
	track Song43_CH1, CH1
	track Song43_CH4, CH4
Song44:
	db 2  ; tracks
	track Song44_CH1, CH1
	track Song44_CH2, CH2
Song45:
	db 4  ; tracks
	track Song45_CH1, CH1
	track Song45_CH2, CH2
	track Song45_CH3, CH3
	track Song45_CH4, CH4
Song46:
	db 3  ; tracks
	track Song46_CH1, CH1
	track Song46_CH2, CH2
	track Song46_CH4, CH4
Song37_CH2:
	length_set 16
	pan PAN_LR
	gate 255
	volume 7
	instrument 41
	snd_jump Seq_7442
Song38_CH2:
	length_set 16
	pan PAN_LR
	base_note $2B
	gate 222
	instrument 36
	volume 6
	snd_call Sub_74AB
	snd_call Sub_7490
	snd_call Sub_74AB
	snd_call Sub_7490
	gate 255
	volume 14
	instrument 41
	snd_loop 2
	base_note $1E
	snd_call Sub_7478
	snd_call Sub_7484
	snd_endloop
	base_note $1B
	snd_call Sub_7458
	snd_call Sub_7464
Seq_7442:
	snd_loop 2
	base_note $20
	snd_call Sub_7478
	snd_call Sub_7484
	snd_endloop
	base_note $1D
	snd_call Sub_7458
	snd_call Sub_7464
	snd_jump Song38_CH2
Sub_7458:
	snd_loop 9
	note -14, 0
	volume_add -4
	note 14, 0
	note -7, 0
	note 8, 0
	volume_add 4
	snd_endloop
	snd_ret
Sub_7464:
	snd_loop 2
	note -9, 0
	volume_add -4
	note 13, 0
	note -2, 0
	note 8, 0
	volume_add 4
	snd_endloop
	note -9, 0
	volume_add -4
	note 13, 0
	note 7, 0
	volume_add 4
	note -9, 0
	snd_ret
Sub_7478:
	snd_loop 3
	note -14, 0
	volume_add -4
	note 14, 0
	note -7, 0
	note 7, 0
	volume_add 4
	snd_endloop
	snd_ret
Sub_7484:
	snd_loop 3
	note -15, 0
	volume_add -4
	note 12, 0
	note -7, 0
	note 7, 0
	volume_add 4
	snd_endloop
	snd_ret
Sub_7490:
	snd_loop 3
	note -1, 0
	volume_add 2
	note -7, 0
	volume_add -2
	note 2, 0
	volume_add 2
	note -7, 0
	volume_add -2
	snd_endloop
	snd_loop 2
	note -2, 0
	note -8, 0
	note 2, 0
	note -8, 0
	snd_endloop
	note 0, 0
	note -5, 0
	note 4, 0
	note 0, 0
	snd_ret
Sub_74AB:
	snd_loop 3
	snd_loop 3
	note 2, 0
	volume_add 2
	note -5, 0
	volume_add -2
	note 4, 0
	volume_add 2
	note -5, 0
	volume_add -2
	snd_endloop
	snd_loop 3
	note 0, 0
	note -7, 0
	note 2, 0
	note -7, 0
	snd_endloop
	snd_endloop
	snd_ret
Song37_CH1:
	length_set 16
	pan PAN_LR
	instrument 23
	gate 179
	volume 12
	snd_loop 2
	base_note $14
	snd_call Sub_758D
	base_note $13
	snd_call Sub_758D
	snd_endloop
	base_note $11
	snd_loop 3
	snd_call Sub_758D
	snd_endloop
	base_note $16
	snd_call Sub_758D
Song38_CH1:
	length_set 16
	pan PAN_LR
	instrument 23
	gate 179
	snd_loop 2
	snd_loop 3
	base_note $13
	snd_call Sub_758D
	base_note $12
	snd_call Sub_758D
	snd_endloop
	base_note $13
	snd_call Sub_756B
	snd_call Sub_757C
	snd_endloop
	instrument 20
	volume 13
	gate 70
	base_note $2A
	snd_call Sub_7526
	snd_call Sub_7564
	instrument 18
	volume 11
	base_note $2C
	snd_call Sub_7526
	snd_call Sub_7564
	snd_jump Song38_CH1
Sub_7526:
	gate 90
	note_x -2, 4
	note_x -7, 4
	note_x 2, 4
	note_x 2, 4
	gate 66
	note 9, 1
	note 7, 1
	note 5, 1
	note 4, 1
	note 2, 1
	note 0, 1
	note -7, 1
	note 0, 1
	rest 5
	rest 1
	note 2, 1
	note 4, 1
	note 5, 1
	note 7, 1
	note 14, 1
	note 12, 1
	note 5, 0
	note -7, 0
	note 0, 1
	rest 5
	note_x -15, 6
	note_x -10, 5
	note_x -7, 5
	note_x -5, 6
	note_x 2, 5
	note_x 5, 5
	note 9, 1
	note 2, 1
	note 12, 1
	note 5, 1
	note 14, 1
	rest 1
	note 9, 1
	rest 1
	note -1, 1
	rest 1
	rest 1
	note -5, 0
	note 2, 0
	note 9, 1
	note 5, 1
	note 2, 1
	note -5, 1
	snd_ret
Sub_7564:
	note 4, 1
	note -12, 1
	note 12, 1
	note -12, 0
	note -12, 0
	rest 3
	snd_ret
Sub_756B:
	volume 11
	note 7, 0
	note 2, 0
	rest 0
	note -5, 0
	rest 0
	note -10, 0
	note -5, 0
	note 7, 0
	rest 0
	volume_add -4
	note -5, 0
	note 7, 0
	rest 0
	snd_ret
Sub_757C:
	volume 11
	note 0, 0
	note -12, 0
	rest 0
	note -12, 0
	rest 0
	note -5, 0
	note 2, 0
	note 4, 0
	rest 0
	volume_add -4
	note 12, 0
	note 0, 0
	note -12, 0
	snd_ret
Sub_758D:
	volume 11
	note 10, 0
	note -2, 0
	rest 0
	note -2, 0
	rest 0
	note -14, 0
	note -2, 0
	note 10, 0
	rest 0
	volume_add -4
	note -2, 0
	note 10, 0
	rest 0
	snd_ret
Song37_CH3:
	length_set 16
	pan PAN_LR
	base_note $2B
	instrument 41
	gate 129
	volume 13
	snd_loop 2
	snd_loop 3
	note 15, 0
	note 10, 0
	note 8, 0
	note -1, 0
	snd_endloop
	snd_loop 3
	note 13, 0
	note 8, 0
	note 6, 0
	note -2, 0
	snd_endloop
	snd_endloop
	snd_loop 9
	note 15, 0
	note 10, 0
	note 8, 0
	note -1, 0
	snd_endloop
	snd_loop 2
	note 13, 0
	note 8, 0
	note 6, 0
	note -2, 0
	snd_endloop
	note 13, 0
	gate 255
	note_x 11, 4
	note_x 8, 4
	note 5, 0
	rest 0
Song38_CH3:
	length_set 16
	pan PAN_LR
	base_note $37
	instrument 18
	volume 13
	gate 0
	note_x 2, 24
	snd_loop 12
	volume_add -1
	hold 2
	snd_endloop
	volume 12
	gate 233
	snd_call Sub_76A5
	note 5, 0
	note 0, 3
	rest 3
	note 5, 3
	note -2, 0
	volume_add -6
	note -2, 0
	volume_add 6
	snd_call Sub_76A5
	note 0, 0
	gate 0
	instrument 18, STATIC
	volume 4
	note_x 11, 4
	volume 13
	note_x 12, 44
	snd_loop 11
	volume_add -1
	hold 1
	snd_endloop
	rest_x 5
	volume 13
	gate 233
	instrument 18
	volume 12
	snd_call Sub_7683
	snd_call Sub_769A
	volume 12
	note 2, 3
	volume_add -5
	note_x -7, 4
	note_x -5, 4
	note_x -3, 4
	note_x -2, 4
	volume_add 5
	gate 233
	snd_call Sub_76A5
	note 5, 0
	note -7, 0
	instrument 0
	gate 80
	volume 10
	note -7, 0
	note -12, 0
	note -3, 0
	volume 13
	instrument 18
	gate 233
	note 0, 1
	note 0, 0
	rest 0
	note 2, 3
	note -2, 1
	snd_call Sub_76A5
	gate 155
	note_x 0, 7
	gate 0
	volume_add -4
	note_x 9, 2
	note_x 10, 2
	note_x 11, 2
	volume_add 4
	note_x 12, 38
	snd_loop 11
	volume_add -1
	hold 2
	snd_endloop
	volume 12
	snd_call Sub_7683
	volume_add -4
	note -5, 1
	note -5, 0
	note -5, 0
	volume_add 4
	note 0, 3
	note -12, 0
	note -12, 0
	rest_x 47
	instrument 2
	gate 200
	base_note $32
	snd_loop 48
	rest 3
	snd_endloop
	snd_jump Song38_CH3
Sub_7683:
	note 9, 3
	note -2, 1
	note 10, 0
	note 12, 0
	note 9, 1
	note 7, 1
	note 7, 1
	note 5, 1
	note -3, 3
	gate 0
	note 9, 2
	volume_add -4
	note_x 10, 4
	note_x 9, 4
	volume_add 4
	note_x 7, 64
	snd_ret
Sub_769A:
	note 2, 3
	note_x 7, 66
	snd_loop 10
	volume_add -1
	hold 3
	snd_endloop
	snd_ret
Sub_76A5:
	note 4, 0
	note 5, 0
	note 7, 1
	note 5, 0
	note_x 4, 5
	volume_add -5
	gate 0
	note_x 4, 4
	volume_add 5
	note_x 2, 15
	gate 233
	note 4, 0
	snd_ret
Song37_CH4:
	length_set 16
	pan PAN_LR
	gate 141
	snd_loop 5
	volume 9
	instrument 27
	drum 14, 0
	volume 7
	instrument 16
	drum 2, 0
	volume 11
	drum 1, 0
	volume 9
	drum 1, 0
	snd_endloop
	volume 9
	instrument 27
	drum 2, 0
	instrument 16
	gate 220
	drum 1, 0
	gate 255
	drum 4, 0
	gate 120
	drum 2, 0
	snd_jump Song37_CH4
Song39_CH2:
	length_set 15
	rest_x 1
Song39_CH3:
	length_set 15
	pan PAN_LR
	volume 15
	instrument 0
	gate 166
	base_note $1F
	note -8, 0
	gate 199
	note_x -13, 3
	note_x -13, 3
	gate 155
	note -13, 0
	note -14, 0
	note -13, 0
	note -13, 0
	note_x -1, 4
	note_x -8, 4
	note_x -13, 4
Seq_7708:
	length_set 15
	volume 12
	pan PAN_LR
	instrument 0
	snd_loop 2
	base_note $1F
	snd_loop 2
	snd_call Sub_777E
	rest 2
	snd_endloop
	base_note $20
	snd_call Sub_777E
	rest 2
	snd_call Sub_777E
	gate 131
	note -3, 0
	gate 188
	note_x -15, 4
	note_x -15, 4
	note_x -15, 4
	snd_endloop
	volume 11
	gate 167
	base_note $23
	snd_call Sub_7798
	note -6, 0
	base_note $21
	snd_call Sub_7798
	note -4, 0
	base_note $23
	snd_call Sub_7798
	note -6, 0
	base_note $21
	snd_call Sub_7798
	note 0, 0
	base_note $1F
	gate 122
	snd_loop 3
	snd_call Sub_777E
	gate 123
	note -8, 0
	note -15, 0
	note -13, 0
	snd_endloop
	note -15, 1
	gate 222
	note -3, 0
	note -15, 0
	snd_loop 3
	gate 255
	note -5, 0
	volume_add -4
	gate 138
	note -4, 0
	note -3, 0
	volume_add 4
	snd_endloop
	gate 243
	note_x 4, 3
	note_x -13, 3
	snd_loop 2
	note_x -1, 3
	note_x -8, 3
	snd_endloop
	snd_jump Seq_7708
Sub_777E:
	gate 222
	note -15, 0
	gate 155
	note -14, 0
	note -13, 0
	note -12, 0
	note -3, 0
	note -10, 0
	gate 174
	volume_add -4
	note -8, 0
	volume_add 4
	note -15, 0
	rest 0
	note -13, 0
	note -14, 0
	note -15, 0
	gate 188
	note -3, 0
	snd_ret
Sub_7798:
	note -5, 0
	snd_loop 5
	note -12, 0
	volume_add -1
	snd_endloop
	volume 10
	note -5, 0
	note -12, 0
	gate 244
	note_x -12, 3
	note_x -12, 3
	gate 167
	snd_loop 2
	note -5, 0
	volume_add -4
	note -12, 0
	volume_add 4
	note -12, 0
	snd_endloop
	snd_ret
Song39_CH1:
	length_set 15
	pan PAN_LR
	rest_x 48
Seq_77BC:
	instrument 23
	gate 120
	volume 13
	base_note $1C
	snd_loop 4
	snd_call Sub_7854
	snd_endloop
	snd_loop 4
	snd_call Sub_784B
	snd_endloop
	base_note $1C
	snd_loop 4
	snd_call Sub_7854
	snd_endloop
	snd_loop 3
	snd_call Sub_784B
	snd_endloop
	note 5, 0
	note -2, 0
	note 5, 0
	note 4, 0
	note 12, 0
	note 0, 0
	note 7, 0
	note 12, 0
	volume 9
	instrument 0
	snd_loop 2
	base_note $28
	snd_call Sub_7833
	base_note $26
	snd_call Sub_7833
	snd_endloop
	base_note $28
	instrument 41
	gate 120
	snd_loop 6
	snd_call Sub_7854
	snd_endloop
	note -7, 0
	note -14, 0
	note -5, 0
	note 2, 0
	note 9, 0
	note 10, 0
	note 5, 0
	base_note $34
	volume 7
	snd_loop 2
	gate 255
	note -2, 0
	gate 166
	note -1, 0
	note 0, 0
	base_note $40
	snd_endloop
	gate 0
	base_note $40
	snd_call Sub_782E
	base_note $28
	snd_call Sub_782E
	base_note $10
	snd_call Sub_782E
	snd_jump Seq_77BC
Sub_782E:
	note_x 7, 3
	note_x -5, 3
	snd_ret
Sub_7833:
	gate 130
	note 7, 0
	note -7, 0
	note -6, 0
	note -5, 0
	note 1, 0
	note 2, 0
	note -3, 0
	note -2, 0
	note 11, 0
	note 7, 0
	note 14, 0
	note 2, 0
	note 5, 0
	note 6, 0
	note 12, 0
	gate 199
	note_x 2, 3
	note_x 2, 3
	snd_ret
Sub_784B:
	note 11, 0
	note 5, 0
	note 11, 0
	note 5, 0
	note 10, 0
	note 5, 0
	note 10, 0
	note 5, 0
	snd_ret
Sub_7854:
	note 10, 0
	note 3, 0
	note 10, 0
	note 3, 0
	note 9, 0
	note 3, 0
	note 9, 0
	note 3, 0
	snd_ret
Song39_CH4:
	length_set 15
	pan PAN_LR
	volume 15
	gate 141
	instrument 16
	drum 11, 0
	gate 222
	drum_x 4, 3
	drum_x 4, 3
	snd_loop 3
	volume 15
	drum_x 6, 3
	volume 0
	drest_x 3
	snd_endloop
	snd_loop 3
	volume 15
	drum_x 9, 3
	volume 6
	drum_x 1, 3
	snd_endloop
Song40_CH4:
	length_set 15
	pan PAN_LR
	gate 141
	instrument 16
	volume 13
	snd_loop 15
	drum 11, 0
	drum 1, 0
	drum 2, 0
	drum 1, 0
	drum 7, 1
	drum 1, 0
	drum 1, 0
	snd_endloop
	drum 12, 0
	drest 0
	gate 222
	drum_x 2, 3
	drum_x 2, 3
	gate 141
	drum 1, 0
	gate 222
	drum 4, 0
	gate 141
	drum 4, 1
	gate 199
	drum_x 2, 3
	drum_x 2, 3
	snd_jump Song40_CH4
Song40_CH2:
	length_set 15
	rest_x 1
Song40_CH3:
	length_set 15
	pan PAN_LR
	volume 11
	instrument 0
	base_note $19
	snd_call Sub_78D5
	base_note $1B
	snd_call Sub_78D5
	base_note $1C
	snd_call Sub_78D5
	base_note $1B
	snd_call Sub_78D5
	snd_jump Song40_CH3
Sub_78D5:
	snd_loop 4
	gate 255
	note -3, 0
	gate 130
	note -9, 0
	note -9, 0
	snd_endloop
	gate 255
	note -3, 0
	gate 138
	note -9, 0
	gate 166
	note 3, 0
	gate 132
	note -9, 0
	snd_ret
Song40_CH1:
	length_set 15
	pan PAN_LR
	gate 100
	instrument 41
	base_note $33
	volume 7
	note 2, 0
	note 3, 0
	note 0, 0
	note 1, 0
	snd_jump Song40_CH1
Song41_CH2:
	length_set 14
	pan PAN_LR
	gate 0
	instrument 5
	volume 15
	base_note $27
	note_x 11, 4
	snd_loop 14
	volume_add -1
	hold 2
	snd_endloop
Seq_7914:
	instrument 23
	base_note $17
	volume 15
	snd_loop 8
	snd_call Sub_797D
	snd_endloop
	base_note $15
	snd_loop 2
	snd_call Sub_797D
	snd_endloop
	base_note $17
	snd_call Sub_7973
	base_note $1C
	snd_call Sub_7973
	base_note $14
	snd_call Sub_7973
	base_note $19
	snd_call Sub_7973
	base_note $12
	snd_call Sub_7973
	base_note $17
	snd_call Sub_7973
	gate 212
	note -3, 0
	gate 133
	note -15, 0
	gate 144
	note -14, 0
	gate 233
	note -13, 1
	instrument 33
	gate 188
	base_note $44
	volume 7
	note_x 2, 3
	volume_add -2
	note_x -3, 3
	volume_add -2
	note_x -10, 3
	rest_x 12
	volume 12
	base_note $17
	snd_call Sub_797D
	snd_call Sub_797D
	snd_jump Seq_7914
Sub_7973:
	snd_loop 2
	gate 199
	note -12, 0
	gate 99
	note 0, 0
	snd_endloop
	snd_ret
Sub_797D:
	gate 222
	note -8, 0
	gate 111
	note 4, 0
	gate 199
	note -13, 0
	gate 99
	note -1, 0
	gate 200
	note -10, 0
	gate 99
	note 2, 0
	gate 199
	note -13, 0
	gate 99
	note -1, 0
	snd_ret
Song41_CH1:
	length_set 14
	pan PAN_LR
	gate 0
	instrument 5
	rest_x 2
	base_note $27
	volume 14
	note_x 11, 4
	snd_loop 13
	volume_add -1
	hold 2
	snd_endloop
Seq_79AD:
	gate 99
	base_note $38
	volume 9
	instrument 33
	snd_loop 2
	note 14, 0
	volume_add -4
	note 2, 0
	volume_add 4
	snd_loop 2
	note 2, 0
	note 11, 0
	volume_add -4
	note 11, 0
	volume_add 4
	snd_endloop
	snd_endloop
	snd_call Sub_7A69
	instrument 33
	base_note $44
	gate 99
	note -3, 0
	note 2, 0
	note -10, 0
	volume_add -4
	note -10, 0
	volume_add -2
	note -10, 0
	volume_add 6
	note 2, 0
	volume_add -4
	note 2, 0
	volume_add 4
	note -10, 0
	note 2, 0
	volume_add -4
	note 2, 0
	snd_call Sub_7A69
	instrument 33
	base_note $44
	gate 99
	note -5, 0
	note 0, 0
	note -12, 0
	instrument 0
	base_note $38
	note -3, 0
	note 3, 0
	note 7, 0
	note 12, 0
	volume_add -4
	note 12, 0
	note 12, 0
	rest 0
	instrument 20
	volume 10
	rest 0
	gate 0
	base_note $29
	note_x 3, 2
	note_x 4, 5
	gate 188
	note 3, 0
	note 1, 0
	note -1, 0
	gate 211
	note -2, 0
	gate 188
	note -1, 0
	note -9, 0
	gate 233
	note 1, 0
	gate 188
	note 0, 0
	note -2, 0
	note -9, 0
	note -4, 0
	note -2, 0
	gate 255
	note 0, 0
	note_x 0, 4
	note_x 0, 3
	instrument 15
	gate 0
	note_x -2, 2
	note_x -1, 5
	gate 188
	note -2, 0
	note -4, 0
	note -11, 0
	note -6, 0
	note -4, 0
	gate 222
	note_x -9, 4
	note_x -7, 3
	note_x -6, 4
	note_x -5, 3
	gate 244
	note -4, 0
	gate 155
	rest 0
	note -4, 0
	gate 0
	note_x -3, 0
	snd_loop 5
	volume_add -1
	hold 7
	snd_endloop
	instrument 33
	volume 8
	gate 99
	base_note $3A
	snd_loop 2
	note 12, 0
	rest 1
	note 9, 0
	rest 1
	note 9, 0
	rest 0
	snd_endloop
	snd_jump Seq_79AD
Sub_7A69:
	instrument 24
	gate 155
	volume 11
	base_note $20
	note 2, 0
	note 14, 0
	note 14, 1
	note 14, 0
	note 14, 0
	rest 0
	note 14, 0
	note 14, 0
	note 12, 0
	rest 0
	note 11, 0
	rest 0
	note 9, 0
	rest 0
	note 7, 0
	instrument 18
	note 5, 5
	snd_ret
Song41_CH3:
	length_set 14
	rest_x 32
Seq_7A88:
	instrument 2
	volume 5
	gate 99
	base_note $2C
	snd_loop 2
	note 11, 0
	note 7, 0
	note 2, 0
	note 14, 0
	note 7, 0
	note 2, 0
	note 14, 0
	note 2, 0
	snd_endloop
	instrument 24
	volume 11
	gate 155
	base_note $33
	snd_call Sub_7B00
	snd_call Sub_7B10
	snd_call Sub_7B00
	snd_loop 4
	note -10, 0
	note -7, 0
	note -2, 0
	snd_endloop
	note 5, 0
	gate 245
	note_x 4, 3
	note_x 5, 3
	note_x 9, 2
	note_x 10, 4
	snd_loop 3
	note_x 10, 3
	volume_add -2
	snd_endloop
	volume 10
	gate 111
	instrument 2
	base_note $2F
	snd_call Sub_7AFA
	base_note $2C
	snd_call Sub_7AFA
	base_note $2A
	snd_loop 2
	note 12, 0
	note 0, 0
	snd_endloop
	note 12, 0
	note 5, 0
	note 0, 0
	note -7, 0
	note 14, 0
	note 2, 0
	note 3, 0
	note 4, 1
	rest 2
	instrument 2
	gate 99
	base_note $2C
	volume 6
	snd_loop 2
	snd_loop 2
	note 11, 0
	note 7, 0
	note 2, 0
	snd_endloop
	note 14, 0
	rest 0
	snd_endloop
	snd_jump Seq_7A88
Sub_7AFA:
	snd_loop 4
	note 12, 0
	note 0, 0
	snd_endloop
	snd_ret
Sub_7B00:
	note -8, 0
	note 4, 0
	note 4, 1
	note 4, 0
	note 4, 0
	rest 0
	note 4, 0
	note 4, 0
	note 2, 0
	rest 0
	note 0, 0
	rest 0
	note -2, 0
	rest 0
	note -3, 0
	snd_ret
Sub_7B10:
	snd_loop 5
	gate 197
	note -5, 0
	gate 136
	note -10, 0
	note -12, 0
	snd_endloop
	gate 155
	rest 0
	snd_ret
Song41_CH4:
	length_set 14
	drest_x 32
Seq_7B22:
	pan PAN_LR
	snd_loop 26
	snd_call Sub_7B41
	snd_endloop
	volume 8
	drum 4, 0
	snd_loop 4
	drum 2, 0
	volume_add -2
	snd_endloop
	volume 8
	drum 4, 0
	drum 4, 0
	drum 4, 0
	snd_loop 4
	snd_call Sub_7B41
	snd_endloop
	snd_jump Seq_7B22
Sub_7B41:
	instrument 16
	volume 10
	gate 222
	drum 2, 0
	gate 78
	volume 7
	drum 3, 0
	volume 10
	gate 90
	drum 8, 0
	volume 7
	drum 1, 0
	snd_ret
Song42_CH1:
	length_set 16
	pan PAN_LR
	base_note $27
	instrument 25
	volume 5
	gate 0
	note_x -5, 3
	note_x -3, 3
	note_x -1, 3
	gate 160
	volume 9
	note 0, 0
	gate 234
	note_x -5, 4
	note_x -5, 4
	gate 155
	note 0, 0
	note_x 5, 12
	note_x 4, 12
	note_x 2, 13
	gate 0
	note_x 7, 80
	snd_end
Song42_CH2:
	length_set 16
	pan PAN_LR
	gate 160
	base_note $1B
	volume 15
	instrument 25
	rest_x 9
	note 0, 0
	rest 1
	note_x -5, 12
	note_x -5, 12
	note_x -5, 13
	gate 0
	note_x -12, 80
	snd_end
Song42_CH3:
	length_set 16
	pan PAN_LR
	volume 5
	base_note $27
	instrument 1
	gate 150
	rest_x 9
	note -8, 0
	rest 1
	gate 140
	note_x -3, 12
	note_x -5, 12
	note_x -7, 13
	gate 0
	note_x -8, 40
	volume_add -1
	hold 40
	snd_end
Song43_CH3:
	length_set 16
	rest_x 1
	pan PAN_LR
	gate 100
	instrument 1
	volume 8
	base_note $25
Seq_7BCB:
	snd_loop 4
	snd_loop 4
	note 1, 0
	note 12, 0
	note 5, 0
	note 10, 0
	snd_endloop
	snd_loop 4
	note 0, 0
	note 10, 0
	note 3, 0
	note 8, 0
	snd_endloop
	snd_loop 4
	note -1, 0
	note 8, 0
	note 1, 0
	note 6, 0
	snd_endloop
	snd_loop 4
	note -2, 0
	note 8, 0
	note 1, 0
	note 6, 0
	snd_endloop
	gate 133
	volume 8
	snd_endloop
	base_note $28
	snd_jump Seq_7BCB
Song43_CH2:
	length_set 16
	rest_x 1
	pan PAN_LR
	instrument 7
	snd_loop 4
	base_note $19
	snd_call Sub_7C54
	base_note $18
	snd_call Sub_7C54
	base_note $17
	snd_call Sub_7C54
	base_note $16
	snd_call Sub_7C54
	snd_endloop
Seq_7C12:
	base_note $1C
	snd_call Sub_7C29
	base_note $1B
	snd_call Sub_7C29
	base_note $1A
	snd_call Sub_7C29
	base_note $19
	snd_call Sub_7C29
	snd_jump Seq_7C12
Sub_7C29:
	gate 255
	volume 15
	note -11, 0
	gate 133
	note 1, 0
	note -11, 0
	volume 10
	note -11, 0
	volume 7
	note 8, 0
	note 13, 0
	note 1, 0
	note -11, 0
	gate 100
	note -11, 0
	gate 150
	note -11, 0
	volume 13
	note 1, 0
	volume_add -3
	note 1, 0
	volume 13
	note -4, 0
	volume_add -2
	note -4, 0
	volume 14
	note -11, 0
	volume 10
	note -11, 0
	snd_ret
Sub_7C54:
	gate 255
	volume 9
	note -11, 0
	gate 133
	note 1, 0
	note -11, 0
	rest_x 64
	note -11, 0
	volume_add -2
	note 1, 0
	volume_add -2
	note 1, 0
	volume_add 4
	note -11, 0
	volume_add -4
	note -11, 0
	snd_ret
Song43_CH1:
	length_set 16
	pan PAN_LR
	gate 255
	instrument 36
	volume 7
	snd_loop 8
	rest_x 127
	snd_endloop
	rest_x 8
	base_note $27
	snd_call Sub_7CBA
	note_x -1, 64
	note_x -8, 64
	snd_call Sub_7CBA
	gate 0
	instrument 36, STATIC
	note_x 10, 2
	note_x 11, 5
	snd_loop 6
	volume_add -1
	hold 20
	snd_endloop
	instrument 36
	gate 255
	volume 7
	instrument 14
	base_note $1E
	snd_call Sub_7CBA
	note_x 4, 64
	note_x 11, 56
	note_x 13, 4
	note_x 14, 4
	gate 0
	note_x 15, 8
	snd_loop 6
	volume_add -1
	hold 27
	snd_endloop
	snd_end
Sub_7CBA:
	note_x 3, 64
	note 5, 3
	note 6, 3
	note_x 1, 64
	note_x -6, 64
	note_x 1, 96
	note 3, 3
	snd_ret
Song43_CH4:
	length_set 16
	drest_x 1
	pan PAN_LR
	snd_loop 4
	drest_x 128
	snd_endloop
Seq_7CD1:
	gate 100
	instrument 16
	volume 9
	drum 2, 0
	snd_loop 3
	drum 3, 0
	volume_add -2
	snd_endloop
	volume 11
	gate 150
	drum 3, 0
	volume 9
	gate 100
	snd_loop 3
	drum 5, 0
	volume_add -2
	snd_endloop
	volume_add 8
	snd_loop 3
	drum 1, 0
	volume_add -2
	snd_endloop
	volume_add 7
	drum 3, 0
	drum 4, 0
	drum 1, 0
	drum 2, 0
	drum 1, 0
	snd_jump Seq_7CD1
Song44_CH2:
	rest_x 2
Song44_CH1:
	length_set 11
	pan PAN_LR
	gate 0
	instrument 5
	volume 15
	base_note $27
	note -1, 4
	volume 4
	note -1, 4
	snd_end
Song45_CH1:
	length_set 16
	pan PAN_LR
	instrument 25
	volume 9
	base_note $27
	gate 180
	note 3, 0
	note_x 3, 4
	note_x 3, 4
	gate 160
	note 3, 0
	gate 0
	note 4, 5
	snd_end
Song45_CH2:
	length_set 16
	pan PAN_LR
	instrument 25
	volume 15
	base_note $16
	gate 150
	note 0, 0
	note -12, 0
	note 0, 0
	gate 0
	note -7, 5
	snd_end
Song45_CH3:
	length_set 16
	pan PAN_LR
	volume 5
	instrument 1
	base_note $1B
	gate 150
	note 6, 0
	rest 0
	note 6, 0
	gate 255
	note 7, 5
	snd_end
Song42_CH4:
	length_set 16
	pan PAN_LR
	volume 12
	instrument 16
	drest_x 9
	gate 222
	drum 2, 0
	drest 1
	drum_x 2, 12
	drum_x 12, 12
	drum_x 13, 13
	snd_jump Seq_7D77
Song45_CH4:
	length_set 16
	pan PAN_LR
	volume 12
	instrument 16
	gate 222
	drum 2, 0
	drum_x 2, 4
	drum_x 1, 4
	drum 3, 0
Seq_7D77:
	snd_loop 3
	drum_x 3, 3
	volume_add -1
	snd_endloop
	snd_loop 10
	drum_x 2, 3
	snd_endloop
	snd_end
Song46_CH4:
	length_set 14
	pan PAN_LR
	instrument 16
	gate 80
	snd_loop 3
	snd_call Sub_7D9E
	volume_add -4
	drest 0
	drum 2, 0
	snd_endloop
	snd_call Sub_7D9E
	drum 1, 0
	drum 2, 0
	snd_jump Song46_CH4
Sub_7D9E:
	volume 12
	drum 3, 0
	drum 1, 0
	drum 2, 0
	drest 0
	gate 255
	drum 2, 0
	gate 80
	drum 1, 0
	snd_ret
Song46_CH1:
	length_set 14
	pan PAN_LR
	gate 108
	instrument 33
	volume 10
	base_note $37
	snd_loop 3
	snd_call Sub_7DCD
	note 12, 0
	note -12, 0
	snd_endloop
	snd_call Sub_7DCD
	gate 132
	note_x 14, 5
	note_x 7, 5
	note_x 11, 4
	snd_jump Song46_CH1
Sub_7DCD:
	note 12, 0
	note 0, 0
	note -12, 0
	note 12, 0
	note 4, 0
	note -12, 0
	snd_ret
Song46_CH2:
	length_set 14
	pan PAN_LR
	volume 12
	instrument 25
	base_note $16
	snd_call Sub_7DFB
	note -3, 0
	rest 0
	base_note $18
	snd_call Sub_7DFB
	note -3, 0
	rest 0
	base_note $1A
	snd_call Sub_7DFB
	note -3, 0
	rest 0
	base_note $18
	snd_call Sub_7DFB
	note -10, 0
	note -10, 0
	snd_jump Song46_CH2
Sub_7DFB:
	gate 195
	note -3, 0
	gate 60
	volume_add -5
	note -3, 1
	volume_add 5
	note 9, 1
	volume_add -5
	gate 155
	note -3, 0
	volume_add 5
	snd_ret
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
	dw Song19  ; song 19
	dw Song20  ; song 20
	dw Song21  ; song 21
	dw Song22  ; song 22
	dw Song23  ; song 23
	dw Song24  ; song 24
	dw Song25  ; song 25
	dw Song26  ; song 26
	dw Song27  ; song 27
	dw Song28  ; song 28
	dw Song29  ; song 29
	dw Song30  ; song 30
	dw Song31  ; song 31
	dw Song32  ; song 32
	dw Song33  ; song 33
	dw Song34  ; song 34
	dw Song35  ; song 35
	dw Song36  ; song 36
	dw Song37  ; song 37
	dw Song38  ; song 38
	dw Song39  ; song 39
	dw Song40  ; song 40
	dw Song41  ; song 41
	dw Song42  ; song 42
	dw Song43  ; song 43
	dw Song44  ; song 44
	dw Song45  ; song 45
	dw Song46  ; song 46
