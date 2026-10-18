; bank $1E: instruments, envelopes, init/SFX/output code, waves, SFX, length sets ($4000-$5DBC)

SfxInstrumentTable:
	instr SEnv_40A8, SEnv_40B6  ; instrument 0
	instr SEnv_40AB, SEnv_40B4  ; instrument 1
	instr SEnv_40AE, SEnv_40B4  ; instrument 2
	instr SEnv_40B1, SEnv_40B4  ; instrument 3
	instr SEnv_40B8, SEnv_40B4  ; instrument 4
	instr SEnv_40C0, SEnv_40B4  ; instrument 5 (not used in this bank)
	instr SEnv_40C8, SEnv_40B4  ; instrument 6 (not used in this bank)
	instr SEnv_40CC, SEnv_40B4  ; instrument 7
	instr SEnv_40D4, SEnv_40B4  ; instrument 8
	instr SEnv_40D8, SEnv_40B4  ; instrument 9 (not used in this bank)
	instr SEnv_40E2, SEnv_40B4  ; instrument 10 (not used in this bank)
	instr SEnv_40E6, SEnv_40B4  ; instrument 11 (not used in this bank)
	instr SEnv_40F0, SEnv_40B4  ; instrument 12 (not used in this bank)
	instr SEnv_40FE, SEnv_4113  ; instrument 13
	instr SEnv_4124, SEnv_4113  ; instrument 14
	instr SEnv_4128, SEnv_40B4  ; instrument 15
	instr SEnv_413A, SEnv_40B4  ; instrument 16
	instr SEnv_4143, SEnv_4165  ; instrument 17 (not used in this bank)
	instr SEnv_4155, SEnv_4113  ; instrument 18 (not used in this bank)
	instr SEnv_4159, SEnv_4165  ; instrument 19
	instr SEnv_4169, SEnv_40B4  ; instrument 20
	instr SEnv_4177, SEnv_40B4  ; instrument 21
	instr SEnv_418B, SEnv_40B4  ; instrument 22 (not used in this bank)
	instr SEnv_418F, SEnv_4165  ; instrument 23
	instr SEnv_419B, SEnv_4165  ; instrument 24 (not used in this bank)
	instr SEnv_41A4, SEnv_4165  ; instrument 25 (not used in this bank)
	instr SEnv_41AF, SEnv_4165  ; instrument 26 (not used in this bank)
	instr SEnv_41B9, SEnv_41BE  ; instrument 27
	instr SEnv_41C4, SEnv_41C9  ; instrument 28 (not used in this bank)
	instr SEnv_41C4, SEnv_4167  ; instrument 29 (not used in this bank)
	instr SEnv_41CE, SEnv_41DB  ; instrument 30
	instr SEnv_41DF, SEnv_4167  ; instrument 31
	instr SEnv_41E7, SEnv_40B4  ; instrument 32 (not used in this bank)
	instr SEnv_41EB, SEnv_40B6  ; instrument 33
	instr SEnv_41F1, SEnv_4113  ; instrument 34 (not used in this bank)
	instr SEnv_41F5, SEnv_40B4  ; instrument 35
	instr SEnv_40FE, SEnv_40B6  ; instrument 36 (not used in this bank)
	instr SEnv_41FC, SEnv_40B6  ; instrument 37
	instr SEnv_4206, SEnv_40B6  ; instrument 38 (not used in this bank)
	instr SEnv_4215, SEnv_41BE  ; instrument 39 (not used in this bank)
	instr SEnv_40CC, SEnv_4220  ; instrument 40 (not used in this bank)
	instr SEnv_4224, SEnv_40B6  ; instrument 41
SEnv_40A8:
	env_timbre 0
	env_vol 15
	env_end
SEnv_40AB:
	env_timbre 1
	env_vol 15
	env_end
SEnv_40AE:
	env_timbre 2
	env_vol 15
	env_end
SEnv_40B1:
	env_timbre 3
	env_vol 15
	env_end
SEnv_40B4:
	env_vol 4
	env_wait 8
SEnv_40B6:
	env_vol 0
	env_end
SEnv_40B8:
	env_timbre 1
SEnv_40B9:
	env_vol 15
	env_loop 15
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
SEnv_40C0:
	env_timbre 2
SEnv_40C1:
	env_vol 15, WAIT
SEnv_40C2:
	env_loop 8
	env_wait 3
	env_vol_add -2
	env_endloop
	env_end
SEnv_40C8:
	env_timbre 1
	env_jump SEnv_40C1
SEnv_40CC:
	env_timbre 0
SEnv_40CD:
	env_vol 15
	env_wait 2
	env_vol 13
	env_wait 2
	env_jump SEnv_40C2
SEnv_40D4:
	env_timbre 2
	env_jump SEnv_40B9
SEnv_40D8:
	env_timbre 2
SEnv_40D9:
	env_vol 15
	env_wait 2
	env_vol 14
SEnv_40DC:
	env_loop 12
	env_vol_add -1
	env_wait 3
	env_endloop
	env_end
SEnv_40E2:
	env_timbre 1
	env_jump SEnv_40D9
SEnv_40E6:
	env_timbre 0
	env_call SEnv_40ED
	env_jump SEnv_40DC
SEnv_40ED:
	env_vol 15, WAIT
	env_vol 11, WAIT
	env_ret
SEnv_40F0:
	env_timbre 1
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_timbre 0
	env_loop 8
	env_vol_add 1, WAIT
	env_vol_add -2, WAIT
	env_endloop
SEnv_40F9:
	env_vol_add 1, WAIT
	env_vol_add -1, WAIT
	env_jump SEnv_40F9
SEnv_40FE:
	env_timbre 2
SEnv_40FF:
	env_vol 9, WAIT
SEnv_4100:
	env_vol 13, WAIT
SEnv_4101:
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
SEnv_410C:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump SEnv_410C
SEnv_4113:
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
SEnv_4124:
	env_timbre 1
	env_jump SEnv_40FF
SEnv_4128:
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
SEnv_4133:
	env_vol 6
	env_wait 3
	env_vol 7
	env_wait 3
	env_jump SEnv_4133
SEnv_413A:
	env_timbre 3
	env_vol 15, WAIT
	env_vol 12, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 0
	env_end
SEnv_4143:
	env_timbre 2
	env_vol 15
	env_wait 2
	env_vol 14
	env_wait 5
	env_vol 13
	env_wait 5
SEnv_414A:
	env_pitch -1
	env_wait 2
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 2
	env_pitch 1
	env_wait 3
	env_jump SEnv_414A
SEnv_4155:
	env_timbre 0
	env_jump SEnv_4100
SEnv_4159:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 2
	env_vol 12
	env_wait 2
SEnv_415E:
	env_pitch -1
	env_wait 3
	env_pitch 1
	env_wait 3
	env_jump SEnv_415E
SEnv_4165:
	env_vol 4
	env_wait 2
SEnv_4167:
	env_vol 0
	env_end
SEnv_4169:
	env_timbre 2
	env_vol 11, WAIT
	env_vol 12
	env_wait 2
	env_vol 13
	env_wait 6
	env_vol 14
SEnv_4170:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump SEnv_4170
SEnv_4177:
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
SEnv_4184:
	env_pitch -1
	env_wait 4
	env_pitch 1
	env_wait 4
	env_jump SEnv_4184
SEnv_418B:
	env_pitch -1
	env_jump SEnv_4169
SEnv_418F:
	env_timbre 3
	env_vol 15, WAIT
	env_timbre 1
	env_vol 12
	env_wait 2
SEnv_4194:
	env_pitch 1
	env_wait 3
	env_pitch -1
	env_wait 3
	env_jump SEnv_4194
SEnv_419B:
	env_timbre 0
	env_vol 15, WAIT
	env_timbre 3
	env_vol 13, WAIT
	env_loop 5
	env_vol_add -1, WAIT
	env_endloop
	env_end
SEnv_41A4:
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
SEnv_41AF:
	env_vol 15, WAIT
	env_loop 5
	env_vol_add -2, WAIT
	env_endloop
	env_vol 3, WAIT
	env_vol 2, WAIT
	env_vol 1, WAIT
	env_vol 0, WAIT
	env_end
SEnv_41B9:
	env_timbre 2
	env_vol 15, WAIT
	env_vol_add -2
	env_wait 3
	env_end
SEnv_41BE:
	env_vol 12
	env_vol_add -6
	env_wait 2
	env_vol_add -5, WAIT
	env_vol 0
	env_end
SEnv_41C4:
	env_timbre 0
	env_vol 15, WAIT
	env_vol_add -1
	env_wait 2
	env_end
SEnv_41C9:
	env_vol 14
	env_vol_add -8
	env_wait 2
	env_vol 0
	env_end
SEnv_41CE:
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
SEnv_41DB:
	env_vol 4
	env_wait 4
	env_vol 0
	env_end
SEnv_41DF:
	env_timbre 2
	env_vol 15, WAIT
	env_vol_add -4, WAIT
	env_loop 3
	env_vol_add -3, WAIT
	env_endloop
	env_end
SEnv_41E7:
	env_timbre 3
	env_jump SEnv_40CD
SEnv_41EB:
	env_timbre 2
	env_vol 15
	env_vol_add -1, WAIT
	env_vol_add -2
	env_wait 7
	env_end
SEnv_41F1:
	env_timbre 3
	env_jump SEnv_40FF
SEnv_41F5:
	env_timbre 3
	env_vol 10
	env_vol_add 5
	env_wait 2
	env_jump SEnv_4101
SEnv_41FC:
	env_timbre 2
	env_vol 14, WAIT
	env_timbre 3
	env_vol 15, WAIT
	env_loop 10
	env_vol_add -1
	env_wait 8
	env_endloop
	env_end
SEnv_4206:
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
SEnv_4215:
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
SEnv_4220:
	env_vol 7
	env_vol_add -1
	env_wait 20
	env_end
SEnv_4224:
	env_vol 15
SEnv_4225:
	env_timbre 0
	env_wait 1
	env_timbre 2, WAIT
	env_vol_add -1, WAIT
	env_loop 3
	env_vol_add -3, WAIT
	env_endloop
	env_vol_add 6
	env_wait 1
	env_jump SEnv_4225

; Sound_Init (bank $1E, far-called): copy the 3 waves to wWaves and the 33 length sets to
; wLengthSets (the bank-0 interpreter reads them from RAM whichever bank is mapped), then reset.
Sound_Init:
	ld hl, InitialWaves         ; 4232
	ld de, wWaves               ; 4235
	ld bc, $0030                ; 4238
	call CopyBytes              ; 423B
	ld hl, InitialLengthSets    ; 423E
	ld de, wLengthSets          ; 4241
	ld bc, $00C6                ; 4244
	call CopyBytes              ; 4247

; reset as in KDL; stopping the music goes through a far call to Sound_PlaySong ($FF).
Sound_Reset:
	ld a, $80                   ; 424A
	ldh [rNR52], a              ; 424C
	ld a, $77                   ; 424E
	ldh [rNR50], a              ; 4250
	ld a, $FF                   ; 4252
	ldh [rNR51], a              ; 4254
	ld a, $FF                   ; 4256
	ld [wSfxAttenuation], a     ; 4258
	ld [wMusicAttenuation], a   ; 425B
	ld [wCurWave], a            ; 425E
	ld hl, wHwRegs              ; 4261
	ld b, $14                   ; 4264
	ld a, $AA                   ; 4266
.l_4268:
	ld [hli], a                 ; 4268
	dec b                       ; 4269
	jr nz, .l_4268              ; 426A
	ld hl, $30E0                ; 426C
	call LoadWave               ; 426F
	ld e, $FF                   ; 4272
	ld a, BANK(Sound_PlaySong)  ; 4274
	ld hl, Sound_PlaySong       ; 4276
	call FarCall_E              ; 4279
	ld e, $FF                   ; 427C
	call Sound_PlaySfx          ; 427E
	call Sound_WriteRegs        ; 4281
	ld hl, rNR14                ; 4284
	set 7, [hl]                 ; 4287
	ld hl, rNR24                ; 4289
	set 7, [hl]                 ; 428C
	ld hl, rNR34                ; 428E
	set 7, [hl]                 ; 4291
	ld hl, rNR44                ; 4293
	set 7, [hl]                 ; 4296
	ret                         ; 4298


; Sound_PlaySfx (bank $1E, far-called): e = SFX, $FF = stop all SFX. Priority rules as in KDL.
Sound_PlaySfx:
	ld a, e                     ; 4299
	cp $FF                      ; 429A
	jp z, Sound_StopSfx         ; 429C
	ld d, $00                   ; 429F
	ld a, [wSfxChannels]        ; 42A1
	and a                       ; 42A4
	jr z, .l_42D5               ; 42A5
	ld hl, SfxChannelMasks      ; 42A7
	add hl, de                  ; 42AA
	and [hl]                    ; 42AB
	jr z, .l_42D5               ; 42AC
	ld bc, $0003                ; 42AE
.l_42B1:
	ld hl, SfxChannelMasks      ; 42B1
	add hl, de                  ; 42B4
	ld a, [hl]                  ; 42B5
	ld hl, wSfxMask             ; 42B6
	add hl, bc                  ; 42B9
	and [hl]                    ; 42BA
	jr z, .l_42D0               ; 42BB
	ld hl, wSfxPriority         ; 42BD
	add hl, bc                  ; 42C0
	ld a, [hl]                  ; 42C1
	ld hl, SfxPriorities        ; 42C2
	add hl, de                  ; 42C5
	cp [hl]                     ; 42C6
	jp c, .l_431B               ; 42C7
	ld hl, wTrkWait             ; 42CA
	add hl, bc                  ; 42CD
	ld [hl], $00                ; 42CE
.l_42D0:
	dec c                       ; 42D0
	bit 7, c                    ; 42D1
	jr z, .l_42B1               ; 42D3
.l_42D5:
	ld hl, SfxChannelMasks      ; 42D5
	add hl, de                  ; 42D8
	ld a, [hl]                  ; 42D9
	ld [wSfxNewMask], a         ; 42DA
	ld hl, SfxPriorities        ; 42DD
	add hl, de                  ; 42E0
	ld a, [hl]                  ; 42E1
	ld c, a                     ; 42E2
	ld hl, SfxTable             ; 42E3
	add hl, de                  ; 42E6
	add hl, de                  ; 42E7
	ld a, [hli]                 ; 42E8
	ld e, a                     ; 42E9
	ld d, [hl]                  ; 42EA
	ld a, [de]                  ; 42EB
	ld h, a                     ; 42EC
	ld l, c                     ; 42ED
	push hl                     ; 42EE
	ld bc, $0003                ; 42EF
.l_42F2:
	ld hl, wTrkWait             ; 42F2
	add hl, bc                  ; 42F5
	ld a, [hl]                  ; 42F6
	and a                       ; 42F7
	jr nz, .l_4312              ; 42F8
	call Sound_StartTrack       ; 42FA
	ld hl, sp+0                 ; 42FD
	ld a, [hl]                  ; 42FF
	ld hl, wSfxPriority         ; 4300
	add hl, bc                  ; 4303
	ld [hl], a                  ; 4304
	ld a, [wSfxNewMask]         ; 4305
	ld hl, wSfxMask             ; 4308
	add hl, bc                  ; 430B
	ld [hl], a                  ; 430C
	pop hl                      ; 430D
	dec h                       ; 430E
	push hl                     ; 430F
	jr z, .l_4317               ; 4310
.l_4312:
	dec c                       ; 4312
	bit 7, c                    ; 4313
	jr z, .l_42F2               ; 4315
.l_4317:
	pop hl                      ; 4317
	jp Sound_UpdateSfxChannels  ; 4318

.l_431B:
	ret                         ; 431B


; stop SFX tracks 0-3 and reset the SFX register image.
Sound_StopSfx:
	ld bc, $0003                ; 431C
.l_431F:
	ld hl, wTrkWait             ; 431F
	add hl, bc                  ; 4322
	ld [hl], b                  ; 4323
	ld hl, wSfxMask             ; 4324
	add hl, bc                  ; 4327
	ld [hl], b                  ; 4328
	ld hl, wSfxPriority         ; 4329
	add hl, bc                  ; 432C
	ld [hl], $FF                ; 432D
	dec c                       ; 432F
	bit 7, c                    ; 4330
	jr z, .l_431F               ; 4332
	ld hl, DefaultRegImage      ; 4334
	ld de, wSfxRegs             ; 4337
	ld c, $14                   ; 433A
.l_433C:
	ld a, [hli]                 ; 433C
	ld [de], a                  ; 433D
	inc de                      ; 433E
	dec c                       ; 433F
	jr nz, .l_433C              ; 4340
	ret                         ; 4342

DefaultRegImage:
	db $08, $00, $08, $00, $80, $00, $00, $08, $00, $80, $80, $00, $00, $00, $80, $00
	db $00, $08, $00, $80

; wSfxChannels = OR of the channel masks of the SFX tracks still running.
Sound_UpdateSfxChannels:
	ld a, [wSfxMask]            ; 4357
	ld hl, wSfxMask + 1         ; 435A
	ld c, $03                   ; 435D
.l_435F:
	or [hl]                     ; 435F
	inc hl                      ; 4360
	dec c                       ; 4361
	jr nz, .l_435F              ; 4362
	ld [wSfxChannels], a        ; 4364
	ret                         ; 4367


; free finished SFX channels, recompute wSfxChannels, write the register images.
Sound_UpdateSfxAndOutput:
	ld b, $03                   ; 4368
.l_436A:
	ld h, HIGH(wSoundRAM)       ; 436A
	ld a, LOW(wTrkWait)         ; 436C
	add a, b                    ; 436E
	ld l, a                     ; 436F
	ld a, [hl]                  ; 4370
	and a                       ; 4371
	jr nz, .l_437F              ; 4372
	ld a, LOW(wSfxPriority)     ; 4374
	add a, b                    ; 4376
	ld l, a                     ; 4377
	ld [hl], $FF                ; 4378
	add a, LOW(wSfxMask - wSfxPriority); 437A
	ld l, a                     ; 437C
	ld [hl], $00                ; 437D
.l_437F:
	dec b                       ; 437F
	bit 7, b                    ; 4380
	jr z, .l_436A               ; 4382
	call Sound_UpdateSfxChannels; 4384

; compare the chosen image with wHwRegs and write the changed registers.
Sound_WriteRegs:
	ld de, wMusicRegs           ; 4387
	ld a, [wSfxChannels]        ; 438A
	bit 0, a                    ; 438D
	jr z, .l_4393               ; 438F
	ld e, $1A                   ; 4391
.l_4393:
	ld b, $00                   ; 4393
	ld hl, wHwRegs              ; 4395
	ld c, $10                   ; 4398
.l_439A:
	ld a, [de]                  ; 439A
	cp [hl]                     ; 439B
	jr z, .l_43A6               ; 439C
	ld [hl], a                  ; 439E
	ldh [c], a                  ; 439F
	ld a, c                     ; 43A0
	cp $12                      ; 43A1
	jr nz, .l_43A6              ; 43A3
	inc b                       ; 43A5
.l_43A6:
	inc l                       ; 43A6
	inc e                       ; 43A7
	inc c                       ; 43A8
	ld a, c                     ; 43A9
	cp $15                      ; 43AA
	jr nz, .l_439A              ; 43AC
	dec b                       ; 43AE
	jr nz, .l_43B8              ; 43AF
	ld a, [wHwRegs + 4]         ; 43B1
	set 7, a                    ; 43B4
	ldh [rNR14], a              ; 43B6
.l_43B8:
	ld de, wMusicRegs + 6       ; 43B8
	ld a, [wSfxChannels]        ; 43BB
	bit 1, a                    ; 43BE
	jr z, .l_43C4               ; 43C0
	ld e, $20                   ; 43C2
.l_43C4:
	ld b, $00                   ; 43C4
	ld hl, wHwRegs + 6          ; 43C6
	ld c, $16                   ; 43C9
.l_43CB:
	ld a, [de]                  ; 43CB
	cp [hl]                     ; 43CC
	jr z, .l_43D7               ; 43CD
	ld [hl], a                  ; 43CF
	ldh [c], a                  ; 43D0
	ld a, c                     ; 43D1
	cp $17                      ; 43D2
	jr nz, .l_43D7              ; 43D4
	inc b                       ; 43D6
.l_43D7:
	inc l                       ; 43D7
	inc e                       ; 43D8
	inc c                       ; 43D9
	ld a, c                     ; 43DA
	cp $1A                      ; 43DB
	jr nz, .l_43CB              ; 43DD
	dec b                       ; 43DF
	jr nz, .l_43E9              ; 43E0
	ld a, [$CE0F]               ; 43E2
	set 7, a                    ; 43E5
	ldh [rNR24], a              ; 43E7
.l_43E9:
	ld de, $CE38                ; 43E9
	ld a, [wSfxChannels]        ; 43EC
	bit 4, a                    ; 43EF
	jr z, .l_43F5               ; 43F1
	ld e, $24                   ; 43F3
.l_43F5:
	ld hl, $CE10                ; 43F5
	ld c, $1A                   ; 43F8
.l_43FA:
	ld a, [de]                  ; 43FA
	cp [hl]                     ; 43FB
	jr z, .l_4400               ; 43FC
	ld [hl], a                  ; 43FE
	ldh [c], a                  ; 43FF
.l_4400:
	inc l                       ; 4400
	inc e                       ; 4401
	inc c                       ; 4402
	ld a, c                     ; 4403
	cp $1F                      ; 4404
	jr nz, .l_43FA              ; 4406
	ld de, $CE3E                ; 4408
	ld a, [wSfxChannels]        ; 440B
	bit 3, a                    ; 440E
	jr z, .l_4414               ; 4410
	ld e, $2A                   ; 4412
.l_4414:
	ld b, $00                   ; 4414
	ld hl, $CE16                ; 4416
	ld c, $20                   ; 4419
.l_441B:
	ld a, [de]                  ; 441B
	cp [hl]                     ; 441C
	jr z, .l_4427               ; 441D
	ld [hl], a                  ; 441F
	ldh [c], a                  ; 4420
	ld a, c                     ; 4421
	cp $21                      ; 4422
	jr nz, .l_4427              ; 4424
	inc b                       ; 4426
.l_4427:
	inc l                       ; 4427
	inc e                       ; 4428
	inc c                       ; 4429
	ld a, c                     ; 442A
	cp $24                      ; 442B
	jr nz, .l_441B              ; 442D
	dec b                       ; 442F
	jr nz, .l_4439              ; 4430
	ld a, [$CE19]               ; 4432
	set 7, a                    ; 4435
	ldh [rNR44], a              ; 4437
.l_4439:
	ld a, [wSfxChannels]        ; 4439
	ld c, a                     ; 443C
	ld a, [wTrkPan + 4]         ; 443D
	bit 0, c                    ; 4440
	jr z, .l_4447               ; 4442
	ld a, [wTrkPan]             ; 4444
.l_4447:
	ld b, a                     ; 4447
	ld a, [wTrkPan + 5]         ; 4448
	bit 1, c                    ; 444B
	jr z, .l_4452               ; 444D
	ld a, [wTrkPan + 1]         ; 444F
.l_4452:
	or b                        ; 4452
	ld b, a                     ; 4453
	ld a, [wTrkPan + 6]         ; 4454
	bit 4, c                    ; 4457
	jr z, .l_445E               ; 4459
	ld a, [wTrkPan + 2]         ; 445B
.l_445E:
	or b                        ; 445E
	ld b, a                     ; 445F
	ld a, [wTrkPan + 7]         ; 4460
	bit 3, c                    ; 4463
	jr z, .l_446A               ; 4465
	ld a, [wTrkPan + 3]         ; 4467
.l_446A:
	or b                        ; 446A
	ldh [rNR51], a              ; 446B
	ret                         ; 446D

InitialWaves:
	db $22, $66, $AA, $EE, $FF, $FF, $FE, $EA, $A6, $66, $8A, $CF, $FE, $EC, $A6, $33  ; wave 0
	db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00  ; wave 1
	db $13, $57, $9B, $DF, $DB, $97, $53, $10, $13, $57, $9B, $DF, $DB, $97, $53, $10  ; wave 2
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
	db 2  ; tracks
	track Sfx10_CH4, CH4
	track Sfx10_CH2, CH2
Sfx11:
	db 1  ; tracks
	track Sfx11_CH2, CH2
Sfx12:
	db 2  ; tracks
	track Sfx12_CH4, CH4
	track Sfx12_CH2, CH2
Sfx13:
	db 1  ; tracks
	track Sfx13_CH2, CH2
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
	track Sfx19_CH1, CH1
Sfx20:
	db 1  ; tracks
	track Sfx20_CH1, CH1
Sfx21:
	db 1  ; tracks
	track Sfx21_CH4, CH4
Sfx22:
	db 2  ; tracks
	track Sfx22_CH2, CH2
	track Sfx22_CH4, CH4
Sfx23:
	db 2  ; tracks
	track Sfx23_CH2, CH2
	track Sfx23_CH4, CH4
Sfx24:
	db 2  ; tracks
	track Sfx01_CH4, CH4
	track Sfx24_CH2, CH2
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
	db 1  ; tracks
	track Sfx29_CH2, CH2
Sfx30:
	db 1  ; tracks
	track Sfx30_CH4, CH4
Sfx31:
	db 1  ; tracks
	track Sfx31_CH4, CH4
Sfx32:
	db 1  ; tracks
	track Sfx32_CH4, CH4
Sfx33:
	db 2  ; tracks
	track Sfx33_CH1, CH1
	track Sfx33_CH2, CH2
Sfx34:
	db 2  ; tracks
	track Sfx34_CH2, CH2
	track Sfx34_CH4, CH4
Sfx35:
	db 1  ; tracks
	track Sfx23_CH4, CH4
Sfx36:
	db 1  ; tracks
	track Sfx36_CH4, CH4
Sfx37:
	db 1  ; tracks
	track Sfx37_CH2, CH2
Sfx38:
	db 4  ; tracks
	track Sfx38_CH1, CH1
	track Sfx38_CH2, CH2
	track Sfx38_CH3, CH3
	track Sfx38_CH4, CH4
Sfx39:
	db 4  ; tracks
	track Sfx39_CH2, CH2
	track Sfx39_CH1, CH1
	track Sfx39_CH3, CH3
	track Sfx39_CH4, CH4
Sfx40:
	db 3  ; tracks
	track Sfx39_CH3, CH3
	track Sfx39_CH1, CH1
	track Sfx39_CH1, CH2
Sfx41:
	db 4  ; tracks
	track Sfx41_CH1, CH1
	track Sfx41_CH2, CH2
	track Sfx41_CH3, CH3
	track Sfx41_CH4, CH4
Sfx42:
	db 3  ; tracks
	track Sfx42_CH1, CH1
	track Sfx42_CH2, CH2
	track Sfx42_CH3, CH3
Sfx43:
	db 1  ; tracks
	track Sfx43_CH4, CH4
Sfx44:
	db 1  ; tracks
	track Sfx44_CH2, CH2
Sfx45:
	db 1  ; tracks
	track Sfx45_CH2, CH2
Sfx46:
	db 2  ; tracks
	track Sfx46_CH4, CH4
	track Sfx46_CH2, CH2
Sfx47:
	db 4  ; tracks
	track Sfx47_CH4, CH4
	track Sfx47_CH2, CH2
	track Sfx47_CH1, CH1
	track Sfx47_CH3, CH3
Sfx48:
	db 1  ; tracks
	track Sfx48_CH2, CH2
Sfx49:
	db 2  ; tracks
	track Sfx49_CH2, CH2
	track Sfx49_CH4, CH4
Sfx50:
	db 2  ; tracks
	track Sfx50_CH2, CH2
	track Sfx50_CH4, CH4
Sfx51:
	db 1  ; tracks
	track Sfx51_CH4, CH4
Sfx52:
	db 1  ; tracks
	track Sfx52_CH4, CH4
Sfx53:
	db 2  ; tracks
	track Sfx53_CH2, CH2
	track Sfx53_CH4, CH4
Sfx54:
	db 1  ; tracks
	track Sfx54_CH4, CH4
Sfx55:
	db 1  ; tracks
	track Sfx55_CH4, CH4
Sfx56:
	db 1  ; tracks
	track Sfx56_CH2, CH2
Sfx57:
	db 2  ; tracks
	track Sfx57_CH4, CH4
	track Sfx57_CH2, CH2
Sfx58:
	db 2  ; tracks
	track Sfx22_CH4, CH4
	track Sfx58_CH2, CH2
Sfx59:
	db 1  ; tracks
	track Sfx59_CH1, CH1
Sfx60:
	db 1  ; tracks
	track Sfx60_CH2, CH2
Sfx61:
	db 1  ; tracks
	track Sfx61_CH4, CH4
Sfx62:
	db 1  ; tracks
	track Sfx54_CH4, CH4
Sfx63:
	db 2  ; tracks
	track Sfx63_CH4, CH4
	track Sfx63_CH2, CH2
Sfx64:
	db 2  ; tracks
	track Sfx64_CH4, CH4
	track Sfx64_CH3, CH3
Sfx65:
	db 2  ; tracks
	track Sfx65_CH2, CH2
	track Sfx65_CH1, CH1
Sfx66:
	db 1  ; tracks
	track Sfx66_CH2, CH2
Sfx67:
	db 3  ; tracks
	track Sfx67_CH1, CH1
	track Sfx67_CH4, CH4
	track Sfx67_CH1, CH2
Sfx68:
	db 2  ; tracks
	track Sfx68_CH1, CH1
	track Sfx68_CH2, CH2
Sfx69:
	db 1  ; tracks
	track Sfx69_CH4, CH4
Sfx70:
	db 2  ; tracks
	track Sfx70_CH4, CH4
	track Sfx70_CH2, CH2
Sfx71:
	db 1  ; tracks
	track Sfx71_CH2, CH2
Sfx72:
	db 1  ; tracks
	track Sfx72_CH2, CH2
Sfx73:
	db 2  ; tracks
	track Sfx73_CH1, CH1
	track Sfx73_CH2, CH2
Sfx74:
	db 2  ; tracks
	track Sfx74_CH4, CH4
	track Sfx74_CH2, CH2
Sfx75:
	db 1  ; tracks
	track Sfx75_CH2, CH2
Sfx76:
	db 2  ; tracks
	track Sfx76_CH2, CH2
	track Sfx76_CH4, CH4
Sfx77:
	db 1  ; tracks
	track Sfx77_CH4, CH4
Sfx78:
	db 2  ; tracks
	track Sfx78_CH4, CH4
	track Sfx78_CH2, CH2
Sfx79:
	db 3  ; tracks
	track Sfx79_CH2, CH2
	track Sfx79_CH3, CH3
	track Sfx79_CH4, CH4
Sfx80:
	db 2  ; tracks
	track Sfx80_CH4, CH4
	track Sfx80_CH2, CH2
Sfx81:
	db 1  ; tracks
	track Sfx81_CH4, CH4
Sfx82:
	db 2  ; tracks
	track Sfx82_CH4, CH4
	track Sfx82_CH2, CH2
Sfx83:
	db 2  ; tracks
	track Sfx83_CH2, CH2
	track Sfx83_CH4, CH4
Sfx84:
	db 1  ; tracks
	track Sfx84_CH4, CH4
Sfx85:
	db 1  ; tracks
	track Sfx85_CH2, CH2
Sfx86:
	db 1  ; tracks
	track Sfx86_CH2, CH2
Sfx87:
	db 1  ; tracks
	track Sfx87_CH4, CH4
Sfx88:
	db 2  ; tracks
	track Sfx88_CH1, CH1
	track Sfx88_CH2, CH2
Sfx89:
	db 4  ; tracks
	track Sfx89_CH1, CH1
	track Sfx89_CH1, CH2
	track Sfx89_CH1, CH3
	track Sfx89_CH4, CH4
Sfx90:
	db 4  ; tracks
	track Sfx90_CH1, CH1
	track Sfx90_CH1, CH2
	track Sfx90_CH1, CH3
	track Sfx90_CH1, CH4
Sfx91:
	db 2  ; tracks
	track Sfx91_CH1, CH1
	track Sfx91_CH2, CH2
Sfx92:
	db 2  ; tracks
	track Sfx92_CH4, CH4
	track Sfx92_CH2, CH2
Sfx93:
	db 3  ; tracks
	track Sfx93_CH1, CH1
	track Sfx93_CH2, CH2
	track Sfx93_CH3, CH3
Sfx94:
	db 4  ; tracks
	track Sfx94_CH2, CH2
	track Sfx94_CH1, CH1
	track Sfx94_CH3, CH3
	track Sfx94_CH4, CH4
Sfx95:
	db 1  ; tracks
	track Sfx95_CH2, CH2
Sfx96:
	db 1  ; tracks
	track Sfx96_CH2, CH2
Sfx97:
	db 3  ; tracks
	track Sfx97_CH1, CH1
	track Sfx97_CH2, CH2
	track Sfx97_CH3, CH3
Sfx00_CH1:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 0
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
	length_set 22
	pan PAN_LR
	rest 1
	snd_jump Sfx00_CH1
Sfx01_CH2:
	length_set 22
	pan PAN_LR
	instrument 1
	base_note $27
	gate 0
	volume 4
	note 4, 0
	snd_loop 7
	detune -6
	hold 1
	detune -7
	hold 1
	detune 4
	hold 2
	detune -5
	hold 1
	volume_add 1
	detune 5
	hold 1
	detune -7
	hold 2
	snd_endloop
	volume_add -2
	detune 1
	hold 1
SSeq_47B7:
	detune -2
	hold 1
	detune 2
	hold 1
	snd_jump SSeq_47B7
Sfx01_CH4:
	length_set 27
	pan PAN_LR
	instrument 0
	gate 0
	volume 2
	drum 6, 0
	volume_add 2
	drum 5, 0
	volume_add 2
	drum 4, 0
	volume_add 2
	drum 3, 0
	drum 2, 0
	volume_add 2
SSeq_47D9:
	drum_x 1, 1
	drum_x 1, 1
	snd_jump SSeq_47D9
Sfx02_CH2:
	length_set 22
	pan PAN_LR
	instrument 3
	volume 15
	gate 0
	base_note $16
	note 7, 0
	note 1, 0
	note -4, 0
	volume 6
	base_note $19
	note 12, 0
	note 13, 0
	note 15, 0
	snd_end
Sfx03_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	base_note $16
	volume 15
	instrument 3
	note 0, 0
	note -6, 0
	note -11, 0
	volume 9
	note 12, 0
	note 13, 0
	note 15, 0
	instrument 2
	snd_loop 4
	note -15, 0
	note -9, 0
	volume_add -1
	snd_endloop
	base_note $2C
	volume 7
	instrument 2
	note_x 8, 0
	snd_loop 7
	detune -3
	hold 1
	snd_endloop
	snd_end
Sfx04_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 0
	base_note $33
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
	length_set 22
	pan PAN_LR
	gate 0
	instrument 1
	volume 11
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
	length_set 22
	gate 0
	instrument 0
	pan PAN_LR
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
	drum_x 1, 0
	snd_loop 6
	volume_add -1
	hold 2
	volume_add -1
	hold 1
	snd_endloop
	snd_end
Sfx06_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 1
	volume 15
	base_note $0F
	note_x 7, 0
	snd_loop 6
	detune 85
	hold 2
	volume_add -1
	snd_endloop
	volume 8
	snd_loop 6
	note -12, 0
	note -11, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx07_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
SSeq_48B6:
	volume 5
	gate 0
	base_note $37
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
	instrument 2
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
	length_set 22
	pan PAN_LR
	rest_x 2
	instrument 0
	snd_jump SSeq_48B6
Sfx08_CH2:
	length_set 22
	pan PAN_LR
	volume 2
	instrument 2
	base_note $3F
	gate 0
	note 10, 0
	note -2, 1
	volume 5
	note 1, 1
	note 3, 1
	note 6, 1
	note 10, 1
	note 6, 0
	volume 5
	snd_call SSub_4922
	snd_loop 5
	snd_call SSub_4922
	volume_add -1
	snd_endloop
	volume 1
	snd_call SSub_4922
	snd_end
SSub_4922:
	note -2, 1
	note 1, 1
	note 3, 1
	note 6, 1
	note 10, 1
	note 8, 1
	note -6, 0
	snd_ret
Sfx09_CH2:
	length_set 22
	pan PAN_LR
	instrument 33, STATIC
	gate 0
	base_note $33
	volume 12
	note_x 10, 1
	snd_loop 12
	detune 50
	hold 1
	detune -50
	hold 1
	detune -17
	hold 1
	detune 30
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx10_CH2:
	length_set 22
	pan PAN_LR
	volume 2
	instrument 0
	gate 0
	base_note $29
	snd_call SSub_4970
	base_note $2E
	snd_call SSub_4970
	base_note $32
	snd_call SSub_4970
	base_note $37
	snd_loop 5
	snd_call SSub_4970
	snd_endloop
	snd_end
SSub_4970:
	note 2, 0
	note 7, 0
	rest 0
	note 9, 0
	note 0, 0
	volume_add 1
	snd_ret
Sfx10_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	drum 9, 0
	volume 2
	snd_loop 13
	drum 14, 0
	drum 8, 0
	drum 13, 0
	volume_add 1
	snd_endloop
	snd_end
Sfx11_CH2:
	length_set 22
	pan PAN_LR
	instrument 23
	volume 12
	base_note $46
	note 2, 0
	volume 4
	snd_loop 4
	note 1, 0
	note 0, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx12_CH2:
	length_set 22
	pan PAN_LR
	base_note $0F
	gate 100
	instrument 0
	volume 15
	snd_loop 14
	note -12, 0
	note -11, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx12_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	drum 7, 1
	snd_loop 9
	drum 8, 0
	drum 10, 0
	drum 12, 0
	drum 10, 0
	volume_add -1
	snd_endloop
	volume 5
	snd_loop 4
	drum 13, 0
	drum 11, 0
	drum 12, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx13_CH2:
	length_set 22
	pan PAN_LR
	instrument 7
	gate 0
	base_note $30
	volume 5
	note_x -7, 0
	snd_loop 4
	detune -16
	hold 1
	snd_endloop
	snd_end
Sfx14_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	drum 11, 0
	snd_end
Sfx15_CH2:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	base_note $27
	volume 14
	note -3, 0
	note -2, 0
	note -4, 0
	volume 0
	rest 0
	volume 13
	note 5, 0
	note 7, 0
	note 6, 0
	note 8, 0
	snd_end
Sfx16_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	volume 11
	gate 120
	base_note $27
	note_x 7, 0
	snd_loop 6
	detune -18
	hold 1
	volume_add -6
	hold 1
	volume_add 6
	snd_endloop
	snd_end
Sfx17_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	gate 0
	instrument 0
	snd_call SSub_4A41
	snd_loop 3
	snd_call SSub_4A4E
	snd_endloop
	snd_end
SSub_4A41:
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
	snd_ret
SSub_4A4E:
	drum 11, 1
	volume_add -1
	drum 12, 1
	volume_add -1
	drum 13, 1
	volume_add -2
	drum 14, 1
	volume_add -1
	snd_ret
Sfx18_CH2:
	length_set 22
	pan PAN_LR
	instrument 1
	gate 0
	volume 14
	base_note $3F
	note 7, 1
	volume_add -8
	note -5, 1
	volume_add 8
	note 2, 1
	snd_end
Sfx19_CH1:
	length_set 22
	pan PAN_LR
	snd_call SSub_4A7A
	snd_call SSub_4A9C
	snd_end
SSub_4A7A:
	volume 15
	base_note $38
	gate 0
	instrument 2, STATIC
SSub_4A82:
	note 0, 0
	note 11, 0
	note 4, 1
	note 7, 1
	note 9, 1
	note 12, 1
	note 7, 0
	volume 9
	snd_loop 4
	note 0, 1
	note 4, 1
	note 9, 1
	note 12, 1
	volume_add -2
	snd_endloop
	volume 1
	note 1, 1
	note 5, 1
	note 8, 1
	note 10, 1
	note 13, 1
	snd_ret
SSub_4A9C:
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
	volume_add 1
	snd_endloop
	snd_loop 5
	snd_loop 4
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
	rest_x 2  ; unreferenced (stream)
	length_set 22
	snd_call SSub_4A7A
	snd_end
Sfx20_CH1:
	length_set 22
	pan PAN_LR
	volume 1
	instrument 2
	gate 0
	base_note $38
	snd_loop 11
	snd_call SSub_4B12
	volume_add 1
	snd_endloop
	snd_call SSub_4B31
	snd_loop 7
	snd_call SSub_4B6E
	volume_add -1
	snd_endloop
	volume 4
	snd_loop 4
	snd_call SSub_4B6E
	snd_call SSub_4B6E
	snd_call SSub_4B6E
	volume_add -1
	snd_endloop
	volume 1
	snd_call SSub_4B6E
	snd_end
SSub_4B12:
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
SSub_4B31:
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
SSub_4B6E:
	snd_loop 2
	note 3, 1
	note 7, 1
	note 10, 1
	note 12, 1
	note 15, 1
	snd_endloop
	snd_ret
Sfx21_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0, STATIC
	volume 7
	drum 1, 0
	drum_x 1, 0
	snd_loop 4
	volume_add 2
	hold 2
	snd_endloop
	snd_loop 6
	drum 1, 2
	volume_add -2
	snd_endloop
	snd_end
Sfx22_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 41
	gate 244
	base_note $3F
	note_x -1, 4
	note_x 11, 0
	snd_loop 10
	volume_add -1
	hold 2
	snd_endloop
	snd_end
Sfx23_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 0
	base_note $29
	volume 6
	note -1, 0
	note 1, 0
	note 3, 0
	note 4, 0
	volume 4
	note 5, 0
	note 6, 0
	snd_end
Sfx24_CH2:
	length_set 22
	pan PAN_LR
	instrument 1
	base_note $1F
	gate 0
	volume 2
	note 4, 0
	snd_loop 7
	detune -10
	hold 1
	detune 3
	hold 1
	detune -13
	hold 1
	detune 2
	hold 1
	detune -14
	hold 1
	volume_add 1
	detune 9
	hold 1
	detune -6
	hold 2
	snd_endloop
	volume_add -7
	detune 1
	hold 1
SSeq_4BF3:
	detune -4
	hold 1
	detune 4
	hold 1
	snd_jump SSeq_4BF3
Sfx25_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 0
	gate 0
	drum 3, 0
	drum 14, 0
	drum 7, 0
	drum 10, 0
	snd_loop 7
	drum 14, 0
	drum 12, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx26_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	base_note $24
	note 8, 0
	note 11, 0
	volume 6
	note 7, 0
	note 3, 0
	note 0, 0
	note -3, 0
	note -6, 0
	snd_end
Sfx27_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	base_note $34
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
Sfx28_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	drum 12, 0
	volume 15
	snd_loop 3
	drum 13, 0
	drum 14, 1
	volume_add -4
	snd_endloop
	snd_end
Sfx29_CH2:
	length_set 22
	pan PAN_LR
	instrument 3
	gate 0
	volume 11
	base_note $46
	note_x -2, 0
	snd_loop 4
	detune 29
	hold 1
	volume_add -2
	snd_endloop
	volume 11
	note_x 4, 0
	snd_loop 5
	detune 27
	hold 1
	volume_add -2
	snd_endloop
	snd_end
Sfx30_CH4:
	length_set 22
	pan PAN_LR
	volume 6
	instrument 0
	gate 0
	snd_loop 4
	drum 11, 0
	drum 10, 0
	volume_add 2
	snd_endloop
	snd_loop 7
	drum 11, 0
	drum 12, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx31_CH4:
	length_set 22
	pan PAN_LR
	instrument 33, STATIC
	gate 0
	volume 7
	drum 5, 2
	volume 11
	drum 4, 3
	volume 7
	drum 1, 1
	drum 2, 2
	volume 4
	drum 1, 1
	snd_end
Sfx32_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	drum 4, 0
	drum 6, 0
	drum 7, 0
	drum 9, 0
	drum 10, 0
	drum 11, 0
	drum 12, 0
	drum 13, 0
	drum 14, 0
	drest 0
	snd_end
Sfx33_CH1:
	length_set 22
	pan PAN_LR
	instrument 2
SSeq_4CDD:
	gate 0
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
	rest 3
	snd_end
Sfx34_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 37
	snd_loop 2
	volume 15
	drum 14, 0
	volume 0
	drest 0
	snd_endloop
	volume 15
	snd_loop 5
	drum 14, 0
	volume_add -2
	drum 12, 0
	volume_add 1
	drum 13, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx34_CH2:
	length_set 22
	pan PAN_LR
	base_note $03
	volume 11
	instrument 7
	gate 0
	note 0, 1
	snd_end
Sfx33_CH2:
	length_set 22
	pan PAN_LR
	instrument 19
	snd_jump SSeq_4CDD
Sfx23_CH4:
	length_set 22
	pan PAN_LR
	instrument 33, STATIC
	gate 0
	volume 15
	drum_x 1, 1
	snd_loop 4
	detune 3
	hold 1
	volume_add -3
	snd_endloop
	snd_end
Sfx36_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	snd_loop 3
	snd_call SSub_4A4E
	snd_endloop
	snd_end
Sfx37_CH2:
	length_set 22
	pan PAN_LR
	instrument 7
	gate 0
	base_note $3C
	volume 10
	note 14, 0
	note -15, 0
	note 3, 0
	snd_end
Sfx38_CH1:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 2
	base_note $3B
	volume 7
SSeq_4D69:
	note_x 11, 1
	volume 10
	snd_loop 5
	detune -17
	hold 1
	volume_add -1
	detune -4
	hold 1
	volume_add -1
	detune -2
	hold 1
	detune 30
	hold 1
	snd_endloop
	note 11, 0
	snd_end
Sfx38_CH2:
	length_set 22
	pan PAN_LR
	base_note $38
	instrument 2
	gate 0
	volume 15
	snd_jump SSeq_4D69
Sfx38_CH4:
	length_set 22
	pan PAN_LR
	instrument 0, STATIC
	gate 0
	volume 15
	drum 11, 0
	drum 7, 0
	drum 4, 0
	drum 2, 1
	drum 1, 5
	snd_end
Sfx39_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	drum 7, 0
	drum 8, 0
	drum 9, 0
	drum 10, 0
	drum 11, 0
	volume_add 2
	drum 11, 0
	volume 8
	snd_loop 4
	drum 12, 0
	drum 11, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx39_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 1
	volume 15
	base_note $1B
	note_x 7, 0
	snd_loop 4
	detune 85
	hold 2
	snd_endloop
	snd_loop 5
	detune 50
	hold 1
	detune 50
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx38_CH3:
	length_set 22
	pan PAN_LR
	base_note $33
	instrument 2
	volume 15
	gate 255
	note 13, 0
	snd_end
Sfx41_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 255
	volume 15
	snd_loop 2
	drum 11, 0
	drum 14, 0
	volume_add -8
	snd_endloop
	drest_x 10
	volume 10
	drum_x 13, 10
	drum_x 10, 0
	volume 5
	snd_loop 9
	detune -1
	hold 1
	volume_add -1
	snd_endloop
	snd_end
	note_x 14, 1  ; unreferenced (stream)
	snd_loop 10
	detune -1
	hold 2
	snd_endloop
	hold 6
	snd_end
Sfx39_CH1:
	length_set 22
	pan PAN_LR
	volume 13
	instrument 2
	gate 255
	base_note $43
	snd_jump SSeq_4E3E
Sfx39_CH3:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 255
	base_note $41
SSeq_4E3E:
	note 7, 1
	volume_add -1
	note 9, 0
	volume_add -1
	note 0, 1
	volume_add -1
	note -3, 0
	volume_add -1
	note -6, 1
	volume_add -1
	note -8, 0
	volume_add -1
	note -11, 1
	volume_add -1
	note -14, 0
	snd_end
Sfx41_CH1:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 1, STATIC
	volume 15
	base_note $18
	note 15, 1
	note 10, 1
	note 0, 1
	gate 255
	instrument 1
	note 7, 2
	note 0, 2
	volume 12
	note 5, 2
	base_note $0F
	volume 10
	note 15, 2
	note -2, 1
	volume 13
	instrument 16
	base_note $05
	note -5, 3
	base_note $1D
	gate 0
	note -7, 0
	note -1, 0
	note 2, 0
	note 6, 0
	note 9, 0
	note 11, 0
	note 14, 0
	volume 7
	snd_loop 2
	instrument 2
	gate 0
	note_x 13, 0
	snd_loop 8
	detune -15
	hold 1
	snd_endloop
	volume_add -3
	detune -20
	hold 4
	rest_x 4
	volume 4
	snd_endloop
	snd_end
Sfx41_CH3:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 255
	base_note $33
	note 11, 1
	note 0, 1
	note -10, 1
	volume 0
	rest_x 15
	volume 10
	note -1, 2
	note 6, 1
	note 9, 2
	note 14, 1
	note 15, 2
	snd_end
Sfx41_CH2:
	length_set 22
	pan PAN_LR
	instrument 3, STATIC
	volume 15
	gate 0
	base_note $18
	note 11, 0
	note -9, 0
	note -2, 0
	volume 12
	note -9, 0
	note 10, 0
	volume 8
	instrument 2
	note -5, 0
	note -9, 0
	volume 6
	base_note $0F
	snd_loop 6
	note -12, 0
	rest 0
	snd_endloop
	volume 10
	base_note $18
	note -14, 0
	note_x -15, 0
	snd_loop 2
	detune 44
	hold 1
	detune 33
	hold 1
	snd_endloop
	base_note $27
	volume 13
	gate 255
	note -15, 0
	note -12, 0
	note -6, 0
	note 2, 0
	note 5, 0
	note 14, 0
	volume 5
	snd_loop 2
	gate 0
	note_x 12, 0
	snd_loop 8
	detune -9
	hold 1
	snd_endloop
	volume 1
	detune -8
	hold 5
	rest_x 2
	snd_endloop
	snd_end
Sfx88_CH1:
	length_set 23
	pan PAN_LR
	instrument 15
	volume 15
	base_note $2F
	gate 255
	note -4, 0
	note 4, 0
	note 11, 0
	snd_loop 3
	note_x 6, 4
	note 11, 0
	volume_add -4
	snd_endloop
	snd_end
Sfx88_CH2:
	length_set 23
	rest_x 1
	pan PAN_LR
	volume 12
	base_note $2F
	gate 255
	note -8, 0
	note -1, 0
	note 8, 0
	snd_loop 3
	note -4, 0
	note_x 4, 6
	volume_add -3
	snd_endloop
	snd_end
Sfx42_CH1:
	length_set 23
	pan PAN_LR
	instrument 15
	volume 15
	base_note $2F
SSeq_4F50:
	gate 255
SSeq_4F52:
	note -11, 0
	note -4, 0
	volume_add -1
	note 5, 0
	note 3, 0
	volume_add -1
	note 8, 1
	rest 1
	snd_end
Sfx42_CH3:
	length_set 23
	pan PAN_LR
	instrument 2
	volume 15
	base_note $3B
	gate 110
	snd_jump SSeq_4F52
Sfx42_CH2:
	length_set 23
	pan PAN_LR
	instrument 33
	volume 6
	rest 1
	base_note $2F
	gate 255
	snd_jump SSeq_4F50
Sfx43_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	gate 0
	instrument 0
	drum 8, 0
	drum 4, 0
	drum 2, 0
	drum 7, 0
	drest 1
	drum 8, 1
	drum 9, 1
	drum 10, 0
	drum 11, 0
	drum 12, 1
	drum 13, 0
	snd_loop 2
	drum 8, 1
	drum 9, 2
	volume_add -2
	drum 10, 1
	drum 11, 2
	volume_add -1
	drum 12, 1
	volume_add -2
	drum 13, 2
	drum 1, 1
	volume_add -1
	snd_endloop
	snd_end
Sfx44_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	base_note $3F
	note 2, 1
	volume 3
	note 2, 1
	snd_end
Sfx45_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	base_note $3F
	note -5, 1
	note 0, 1
	note 4, 1
	note 7, 1
	snd_end
Sfx46_CH2:
	length_set 22
	pan PAN_LR
	volume 6
	instrument 2
	gate 255
	base_note $3B
	note 15, 0
	volume_add -1
	note 2, 0
	volume_add -1
	note 4, 0
	snd_end
Sfx46_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 30
	gate 0
	drum 2, 0
	drum 9, 0
	drum_x 4, 0
	snd_loop 5
	volume_add -3
	detune 2
	hold 1
	detune -1
	hold 1
	snd_endloop
	volume 7
	snd_end
Sfx47_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	gate 0
	instrument 0
	snd_loop 5
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
	volume_add -2
	snd_endloop
	snd_end
Sfx47_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	gate 0
	instrument 2
	base_note $1B
	snd_loop 5
	note_x 0, 0
	snd_loop 13
	detune 90
	hold 1
	snd_endloop
	volume_add -2
	hold 2
	snd_endloop
	snd_end
Sfx47_CH3:
	length_set 27
	pan PAN_LR
	rest 5
	snd_end
Sfx47_CH1:
	length_set 22
	pan PAN_LR
	volume 15
	gate 0
	instrument 3
	base_note $1B
	snd_loop 5
	note_x 5, 0
	snd_loop 13
	detune 90
	hold 1
	snd_endloop
	volume_add -2
	hold 2
	snd_endloop
	snd_end
Sfx48_CH2:
	length_set 22
	pan PAN_LR
	instrument 2, STATIC
	gate 0
	base_note $18
	volume 5
	note_x 11, 0
	detune -3
	hold 1
	snd_loop 3
	detune 20
	hold 1
	snd_endloop
	snd_loop 4
	volume_add -1
	detune 4
	hold 1
	snd_endloop
	volume 6
	snd_loop 3
	snd_loop 4
	detune -29
	hold 1
	snd_endloop
	volume_add -2
	detune 100
	snd_endloop
	snd_end
Sfx49_CH4:
	length_set 22
	pan PAN_LR
	instrument 30, STATIC
	gate 0
	volume 15
	drum 4, 1
	drum 11, 0
	drum 1, 0
	drum 6, 1
	drum 13, 0
	drum 1, 5
	snd_end
Sfx49_CH2:
	length_set 22
	pan PAN_LR
	gate 100
	instrument 4
	snd_loop 2
	base_note $3C
	volume 2
	note 9, 0
	note 8, 0
	volume 4
	note 9, 0
	volume 1
	note 7, 0
	volume 0
	snd_endloop
	snd_end
Sfx56_CH2:
	length_set 22
	pan PAN_LR
	instrument 8
	gate 0
	base_note $16
	volume 15
	snd_call SSub_50D8
	rest 0
	base_note $1B
	volume 10
	snd_call SSub_50D8
	rest 2
	base_note $1D
	volume 7
	snd_call SSub_50D8
	rest 2
	base_note $1E
	volume 5
	snd_call SSub_50D8
	snd_end
SSub_50D8:
	note_x -9, 0
	detune -56
	hold 1
	snd_loop 6
	detune -73
	hold 1
	snd_endloop
	snd_ret
Sfx51_CH4:
	length_set 22
	pan PAN_LR
	volume 10
	instrument 16
	gate 0
	drum 7, 0
	volume 0
	drest 0
	snd_end
Sfx50_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 0
	gate 255
	drum 1, 1
	gate 0
	drum_x 10, 0
	snd_loop 9
	detune -1
	hold 1
	volume_add -1
	snd_endloop
	volume_add -1
	hold 5
	snd_end
Sfx50_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 2
	gate 0
	base_note $3A
	note_x 15, 0
	detune -20
	hold 1
	detune 5
	hold 1
	detune 10
	hold 1
	detune -12
	hold 1
	note 12, 0
	note -15, 0
	volume_add -1
	note 7, 0
	note 5, 0
	volume_add -1
	note 4, 0
	note 1, 0
	volume_add -1
	note -2, 0
	volume_add -1
	note -3, 0
	note -6, 0
	volume_add -1
	note -7, 0
	volume_add -1
	note -10, 0
	note -12, 0
	volume_add -1
	note -14, 0
	base_note $32
	note -9, 0
	volume_add -1
	note_x -11, 0
	snd_loop 6
	hold 1
	detune 57
	hold 1
	volume_add -1
	snd_endloop
	note -14, 0
	snd_end
Sfx53_CH4:
	length_set 22
	pan PAN_LR
	volume 10
	instrument 7
	gate 0
	drum 1, 3
	snd_end
Sfx53_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 0
	base_note $3A
	volume 6
	note 7, 0
	volume 8
	note 0, 0
	note -7, 0
	note -14, 0
	snd_end
Sfx52_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	snd_loop 3
	drum 14, 0
	drum 12, 0
	drest 0
	volume_add -2
	drum 14, 0
	drum 12, 0
	drest 0
	snd_endloop
	volume_add -2
	drum 14, 0
	drum 12, 0
	snd_end
	length_set 22  ; unreferenced (stream)
	pan PAN_LR
	instrument 2
	volume 15
	gate 0
	base_note $34
	note -13, 0
	note -11, 0
	note -15, 0
	note -5, 0
	snd_end
Sfx57_CH2:
	length_set 22
	pan PAN_LR
	instrument 35
	gate 255
	base_note $22
	volume 8
	note -13, 0
	volume 6
	note -13, 0
	note -13, 0
	volume 4
	note -13, 0
	snd_end
Sfx57_CH4:
	length_set 22
	pan PAN_LR
	instrument 27
	gate 100
	volume 11
	drum 12, 0
	volume 15
	drum 2, 0
	volume_add 7
	drum 11, 0
	volume 10
	drum 1, 0
	snd_end
Sfx58_CH2:
	length_set 22
	pan PAN_LR
	rest 1
	instrument 2
	gate 0
	volume 0
	base_note $3F
	note_x 11, 0
	volume_add 2
	hold 2
	snd_loop 2
	volume_add -1
	hold 2
	snd_endloop
	snd_end
Sfx22_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 13
	drum 12, 0
	drum 7, 0
	volume 15
	drum 4, 0
	drum 1, 1
	drum 2, 0
	volume 11
	drum 4, 0
	drum 6, 0
	volume 7
	drum 9, 0
	snd_end
Sfx59_CH1:
	length_set 22
	gate 0
	instrument 14, STATIC
	pan PAN_LR
	base_note $32
	volume 15
	snd_call SSub_4A82
	base_note $30
	snd_call SSub_4A9C
	snd_end
Sfx61_CH4:
	length_set 22
	pan PAN_LR
	volume 13
	instrument 0
	gate 0
	drum 5, 0
	drum 1, 0
	drum 7, 0
	volume 13
	snd_loop 6
	drum 3, 0
	drum 4, 0
	drum 3, 0
	drum 4, 0
	drum 3, 0
	drum 4, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx60_CH2:
	length_set 22
	pan PAN_LR
	rest_x 20
	gate 0
	instrument 2
	base_note $3F
	snd_loop 8
	volume 15
	note 0, 1
	volume 0
	rest 3
	snd_endloop
	snd_end
Sfx54_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	snd_loop 3
	drum 1, 0
	drum 2, 0
	drum 3, 0
	drum 4, 0
	snd_endloop
	drum 5, 0
	drum 6, 0
	drum 8, 0
	drum 12, 0
	drum 14, 0
	drum 11, 0
	drum 14, 0
	snd_loop 5
	drum 12, 0
	drum 14, 0
	snd_endloop
	snd_loop 14
	drum 12, 0
	volume_add -1
	drum 14, 0
	snd_endloop
	snd_end
Sfx63_CH2:
	length_set 22
	pan PAN_LR
	volume 5
	instrument 0
	gate 255
	base_note $0F
	rest 5
	note -12, 0
	snd_loop 5
	volume 0
	rest 2
	volume 10
	note -12, 0
	snd_endloop
	snd_end
Sfx63_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 2
	drum 13, 1
	volume 4
	drum 1, 1
	drum 5, 0
	drum 14, 1
	volume 15
	drum 14, 0
	drum 4, 0
	drum 1, 0
	volume_add -1
	drum 2, 0
	drum 1, 1
	snd_loop 3
	drum 1, 0
	volume_add -1
	drum 4, 0
	drum 3, 1
	volume_add -1
	drum 1, 0
	drum 4, 0
	volume_add 1
	drum 3, 0
	snd_endloop
	volume_add -1
	drum 2, 1
	volume_add -1
	drum 5, 0
	drum 4, 0
	volume_add 1
	drum 2, 1
	volume_add -1
	drum 5, 0
	volume_add -1
	drum 4, 0
	volume_add -2
	drum 3, 1
	volume_add -1
	drum 6, 0
	volume_add -1
	drum 5, 0
	volume_add -2
	drum 4, 1
	drum 7, 0
	volume_add -1
	drum 5, 1
	snd_end
Sfx83_CH2:
	length_set 22
	pan PAN_LR
	base_note $3F
	gate 255
	instrument 2
	volume 10
	note 8, 0
	volume 0
	rest 0
	snd_end
	length_set 22  ; unreferenced (stream)
	volume 15
	base_note $03
	gate 200
	instrument 15
	note -3, 0
	snd_end
	length_set 22  ; unreferenced (stream)
	pan PAN_LR
	volume 0
	rest_x 200
	rest_x 160
	snd_end
Sfx83_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 16
	volume 15
	drum 9, 1
	drum 2, 2
	snd_end
Sfx64_CH3:
	length_set 22
	pan PAN_LR
	gate 255
	instrument 3
	base_note $0F
	volume 15
	snd_loop 7
	note_x -12, 4
	volume_add -2
	snd_endloop
	snd_end
Sfx64_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	snd_loop 14
	drum 14, 0
	drest 0
	drum 13, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx65_CH1:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 255
	volume 6
	base_note $3F
	note 11, 0
	snd_end
Sfx65_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 255
	volume 15
	base_note $33
	note 5, 1
	snd_end
	length_set 22  ; unreferenced (stream)
	pan PAN_LR
	gate 150
	instrument 38
	volume 15
	note 4, 0
	note 1, 0
	snd_end
Sfx66_CH2:
	length_set 22
	pan PAN_LR
	volume 13
	gate 0
	instrument 33, STATIC
	base_note $35
	note 9, 0
	note 7, 0
	volume 10
	snd_loop 5
	note 5, 0
	note 6, 0
	volume_add -1
	note 7, 0
	note 6, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx94_CH4:
	length_set 26
	pan PAN_LR
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
	snd_jump Sfx94_CH4
Sfx94_CH3:
	length_set 26
	pan PAN_LR
	volume 10
	gate 111
	base_note $41
	instrument 7
	snd_loop 2
	note 4, 0
	rest 0
	note -5, 0
	note -5, 0
	rest 1
	note 7, 0
	rest 2
	note 8, 0
	rest 0
	note -11, 0
	note -11, 0
	note 6, 0
	rest 0
	snd_endloop
SSeq_53AC:
	volume 11
	instrument 1
	gate 111
	base_note $1D
	snd_call SSub_53E6
	base_note $1B
	snd_call SSub_53E6
	base_note $1E
	snd_call SSub_53D0
	base_note $1C
	snd_call SSub_53D0
	gate 111
	base_note $1D
	snd_call SSub_53E6
	snd_jump SSeq_53AC
SSub_53D0:
	gate 140
	snd_loop 4
	note 4, 0
	note -5, 0
	note 4, 0
	note -5, 0
	note 6, 0
	note -2, 0
	note 6, 0
	note -2, 0
	note 2, 0
	note -6, 0
	note 2, 0
	note -6, 0
	note 8, 0
	note 0, 0
	note 8, 0
	note 0, 0
	snd_endloop
	snd_ret
SSub_53E6:
	snd_loop 4
	note 0, 1
	note 7, 1
	note 6, 0
	note -2, 1
	note 4, 1
	note 10, 1
	note 4, 0
	note 2, 1
	note -4, 1
	snd_endloop
	snd_ret
Sfx94_CH1:
	length_set 26
	pan PAN_LR
	volume 9
	instrument 21
	gate 130
	base_note $29
	snd_call SSub_54B9
SSeq_5402:
	volume 8
	snd_loop 2
	base_note $29
	snd_call SSub_5492
	snd_endloop
	snd_loop 2
	base_note $27
	snd_call SSub_546B
	snd_endloop
	volume 11
	gate 255
	instrument 15
	base_note $1E
	snd_loop 2
	note_x 7, 54
	note 4, 0
	note -5, 0
	note -3, 1
	note -1, 0
	note 0, 1
	snd_loop 4
	note 6, 1
	note 7, 0
	note 9, 0
	snd_endloop
	note_x 7, 66
	note 4, 1
	note -3, 0
	note 2, 0
	note 11, 1
	snd_loop 2
	note 9, 0
	note 7, 0
	note 6, 0
	snd_endloop
	note 4, 0
	snd_loop 8
	note 7, 0
	volume_add -1
	snd_endloop
	volume 11
	base_note $25
	snd_endloop
	volume 10
	snd_loop 4
	snd_call SSub_544E
	snd_endloop
	snd_jump SSeq_5402
SSub_544E:
	instrument 33
	base_note $3A
	gate 50
	note 14, 1
	note 7, 1
	note 14, 1
	gate 100
	note 7, 0
	note 14, 0
	rest 0
	note 7, 0
	rest 0
	note 14, 0
	rest 0
	gate 178
	note_x 7, 3
	note_x 7, 3
	note_x 14, 3
	rest_x 9
	snd_ret
SSub_546B:
	gate 200
	instrument 41
	note 8, 1
	note 0, 2
	note 8, 0
	note 0, 1
	note 8, 0
	note 10, 0
	note 12, 0
	note 10, 1
	note 8, 0
	note 6, 0
	note 4, 0
	note 2, 5
	rest 1
	instrument 33
	gate 100
	base_note $3A
	rest 0
	note 14, 0
	note 7, 0
	note 14, 0
	rest 0
	note 7, 0
	gate 200
	snd_loop 2
	note_x 14, 3
	note_x 7, 3
	snd_endloop
	snd_ret
SSub_5492:
	gate 200
	instrument 41
	note 4, 1
	note -5, 2
	note 4, 0
	note -5, 1
	note 4, 0
	note 6, 0
	note 8, 0
	note 6, 1
	note 4, 0
	note 2, 0
	note 0, 0
	note -2, 5
	rest 1
	instrument 33
	gate 100
	base_note $3A
	rest 0
	note 14, 0
	note 7, 0
	note 14, 0
	rest 0
	note 7, 0
	gate 200
	snd_loop 2
	note_x 14, 3
	note_x 7, 3
	snd_endloop
	snd_ret
SSub_54B9:
	snd_loop 2
	note 4, 0
	rest 0
	note 7, 0
	note 2, 0
	rest 0
	note 5, 0
	rest 0
	note 4, 0
	rest 0
	note 7, 0
	rest 0
	note 1, 0
	note 2, 0
	rest 0
	note 7, 0
	rest 0
	snd_endloop
	snd_ret
Sfx94_CH2:
	length_set 26
	pan PAN_LR
	gate 133
	instrument 7
	volume 15
	base_note $0C
	snd_loop 2
	snd_call SSub_5517
	snd_endloop
SSeq_54DF:
	base_note $0C
	snd_loop 4
	snd_call SSub_550A
	snd_endloop
	base_note $0A
	snd_loop 4
	snd_call SSub_550A
	snd_endloop
	base_note $0D
	snd_loop 4
	snd_call SSub_550A
	snd_endloop
	base_note $0B
	snd_loop 4
	snd_call SSub_550A
	snd_endloop
	base_note $0C
	snd_loop 4
	snd_call SSub_550A
	snd_endloop
	snd_jump SSeq_54DF
SSub_550A:
	note -7, 1
	note 5, 0
	note -7, 0
	note -1, 1
	note 11, 0
	note -5, 1
	note 7, 0
	note -5, 0
	note 1, 1
	note 1, 0
	note 1, 0
	note 13, 0
	snd_ret
SSub_5517:
	note -7, 1
	note 5, 0
	note -7, 0
	note 0, 1
	note 12, 0
	note -6, 1
	note 6, 0
	note -6, 0
	note -5, 1
	note 3, 0
	note 0, 0
	note 12, 0
	snd_ret
Sfx95_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 2, STATIC
	base_note $3F
	volume 11
	snd_call SSub_556D
	snd_end
Sfx68_CH1:
	length_set 22
	pan PAN_LR
	gate 100
	instrument 2
	base_note $3F
	volume 9
	snd_call SSub_5544
	snd_end
SSub_5544:
	rest 0
SSub_5545:
	volume_add -1
	note 9, 1
	volume_add 1
	rest 0
	volume_add -1
	note 1, 1
	volume_add -1
	note 11, 1
	volume_add 1
	note 4, 1
	rest 0
	volume_add -1
	note 6, 1
	snd_ret
	note_x 0, 1  ; unreferenced (stream)
	note_x 9, 0
	snd_loop 5
	volume_add 2
	detune -4
	hold 2
	volume_add -4
	detune 5
	hold 1
	snd_endloop
	snd_ret
SSub_556D:
	note_x 5, 1
	note_x 9, 0
	snd_loop 5
	volume_add -4
	hold 2
	volume_add 2
	hold 2
	snd_endloop
	snd_ret
Sfx68_CH2:
	length_set 22
	pan PAN_LR
	gate 100
	instrument 2
	base_note $3F
	rest 3
	volume 7
	snd_loop 4
	snd_call SSub_5545
	snd_endloop
	snd_end
	length_set 22  ; unreferenced (stream)
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	snd_loop 5
	note 14, 0
	volume_add -1
	note 8, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx69_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 13
	drum 5, 0
	drum 3, 0
	snd_loop 3
	drum 14, 0
	drum 11, 0
	volume_add -5
	snd_endloop
	snd_end
Sfx70_CH2:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 23
	gate 0
	base_note $18
	note_x -1, 0
	snd_loop 7
	detune 30
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx70_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	drum 3, 0
	drum 9, 0
	drum 12, 0
	instrument 31
	drum 13, 0
	volume 11
	snd_loop 3
	drum 14, 0
	volume_add -1
	drum 12, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx71_CH2:
	length_set 22
	pan PAN_LR
	base_note $2E
	instrument 2
	gate 0
	volume 0
	note_x 11, 0
	volume 3
	hold 1
	volume 7
	hold 1
	snd_loop 7
	detune 7
	hold 1
	detune 8
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx72_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	volume 1
	gate 0
	base_note $1D
	note -2, 0
	snd_loop 2
	detune -16
	hold 1
	volume_add 2
	snd_endloop
	snd_loop 3
	detune -25
	hold 1
	volume_add 1
	snd_endloop
	snd_loop 4
	detune -24
	hold 1
	volume_add -2
	snd_endloop
	snd_end
Sfx73_CH1:
	length_set 22
	pan PAN_LR
	volume 11
	gate 0
	instrument 2
	base_note $3F
	note -1, 0
	volume_add -6
	note 6, 0
	volume_add 5
	note -1, 0
	volume_add -8
	note -1, 0
	rest 1
	note -13, 0
	rest 0
	note -6, 0
	snd_loop 2
	volume_add 4
	note 3, 0
	volume_add -1
	note 11, 0
	volume 0
	rest 1
	gate 100
	snd_endloop
Sfx67_CH1:
	volume 0
	pan PAN_LR
	rest_x 1
	snd_end
Sfx73_CH2:
	length_set 22
	pan PAN_LR
	volume 10
	gate 0
	instrument 2
	base_note $2C
	note 0, 0
	volume_add -4
	note 0, 0
	rest 2
	volume 4
	base_note $38
	snd_loop 2
	note 1, 0
	rest 0
	note 6, 0
	volume_add -1
	rest 0
	snd_endloop
	base_note $2C
	instrument 2
	note 12, 0
	volume_add -2
	note 12, 0
	snd_end
Sfx74_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	drum 1, 0
	drum 11, 0
	drum 14, 0
	drum 12, 0
	snd_loop 7
	volume_add -1
	drum 11, 0
	drum 10, 0
	drum 14, 0
	volume_add -1
	drum 13, 0
	drum 12, 0
	drum 14, 0
	snd_endloop
	snd_end
Sfx74_CH2:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 0
	base_note $0F
	volume 9
	note -1, 0
	snd_loop 3
	note -12, 0
	volume_add 2
	note -11, 0
	snd_endloop
	snd_loop 7
	volume_add -1
	rest 0
	note -12, 0
	rest 0
	volume_add -1
	note -11, 0
	snd_endloop
	snd_end
Sfx75_CH2:
	length_set 22
	pan PAN_LR
	instrument 3
	gate 0
	base_note $3C
	volume 10
	snd_loop 5
	note 8, 0
	volume_add 4
	note_x 1, 0
	detune -1
	hold 1
	volume_add -5
	note -15, 0
	base_note $30
	volume_add 2
	note -6, 0
	volume_add -3
	note 15, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx76_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 2
	base_note $0F
	volume 15
	note_x -12, 0
	snd_loop 3
	detune -61
	hold 1
	detune -50
	hold 1
	detune 10
	hold 1
	volume_add -5
	snd_endloop
	snd_end
Sfx76_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	drum 13, 0
	drum 14, 0
	volume_add -1
	drum 12, 0
	drum 13, 0
	volume_add -2
	drum 11, 0
	drum 12, 0
	volume_add -1
	drum 10, 0
	drum 11, 0
	volume_add -2
	drum 9, 0
	drum 10, 0
	volume_add -1
	drum 8, 0
	drum 9, 0
	volume_add -3
	drum 7, 0
	drum 8, 0
	volume_add -2
	drum 6, 0
	volume_add -1
	drum 7, 2
	volume 1
	drum 5, 5
	snd_end
Sfx67_CH4:
	length_set 22
	pan PAN_LR
	volume 15
	instrument 16
	gate 255
	drum 10, 3
	volume 10
	drum 8, 5
	snd_end
Sfx87_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 15
	snd_loop 2
	drum 13, 0
	drum 12, 0
	snd_endloop
	drest 2
	volume 5
	drum 12, 0
	drum 11, 0
	drum 14, 5
	snd_end
Sfx84_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	drum 13, 0
	drum 14, 0
	drum 13, 0
	drum 10, 0
	drum 8, 0
	drum 6, 0
	drum 4, 0
	snd_end
Sfx77_CH4:
	length_set 22
	pan PAN_LR
	instrument 2
	gate 0
	volume 15
	drum 1, 0
	snd_loop 4
	volume 15
	drum 6, 0
	drum 1, 0
	snd_endloop
	snd_loop 2
	drum 1, 0
	volume_add -3
	drum 6, 0
	snd_endloop
	snd_end
Sfx78_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 13
	drum 1, 0
	drum 1, 0
	drum 3, 0
	drum 5, 0
	volume 10
	drum 7, 0
	drum 8, 0
	drum 10, 0
	volume 9
	drum 11, 0
	drum 12, 0
	snd_loop 7
	drum 13, 0
	volume_add -1
	drum 14, 0
	snd_endloop
	snd_end
Sfx78_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 33
	base_note $13
	volume 14
	snd_loop 2
	note 12, 0
	rest 0
	note -11, 0
	snd_endloop
	snd_loop 13
	volume_add -1
	note 12, 0
	rest 0
	note -11, 0
	snd_endloop
	snd_end
Sfx79_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 3
	base_note $38
SSeq_57D5:
	volume 15
	note_x 12, 3
	volume 10
	snd_loop 10
	hold 4
	volume_add -1
	snd_endloop
	snd_end
Sfx79_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 1
	volume 1
	snd_loop 5
	snd_loop 3
	drum 2, 0
	drum 1, 0
	snd_endloop
	volume_add 1
	snd_endloop
	snd_loop 6
	snd_loop 3
	drum 2, 0
	drum 1, 0
	snd_endloop
	volume_add -1
	snd_endloop
	snd_end
Sfx79_CH3:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	base_note $37
	rest_x 1
	snd_jump SSeq_57D5
Sfx80_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0, STATIC
	volume 15
	drum_x 11, 0
	snd_loop 10
	detune -1
	hold 1
	snd_endloop
	snd_end
Sfx80_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 3, STATIC
	base_note $3A
	volume 15
	note 14, 1
	note 5, 1
	note -2, 1
	note -8, 0
	note 15, 0
	note 2, 0
	note -9, 0
	snd_end
Sfx55_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
	volume 2
	snd_loop 8
	drum 8, 0
	drum 12, 0
	drum 9, 0
	drum 11, 0
	volume_add 1
	snd_endloop
	snd_jump SSeq_5859
Sfx81_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0
SSeq_5859:
	volume 7
	snd_loop 8
	drum 8, 0
	drum 12, 0
	drum 9, 0
	drum 11, 0
	volume_add 1
	snd_endloop
	volume 15
	snd_loop 6
	drum 7, 0
	drum 9, 0
	drum 7, 0
	drum 11, 0
	snd_endloop
	snd_loop 7
	volume_add -1
	drum 7, 0
	drum 11, 0
	volume_add 1
	drum 7, 0
	drum 11, 0
	volume_add -2
	snd_endloop
	snd_end
Sfx82_CH2:
	length_set 22
	pan PAN_LR
	instrument 1
	base_note $27
	gate 0
	snd_jump SSeq_58AE
SSeq_5888:
	volume 4
	note 7, 0
	snd_loop 4
	detune 4
	hold 1
	detune 7
	hold 2
	detune -4
	hold 1
	snd_endloop
	volume_add -1
	snd_loop 5
	detune 9
	hold 2
	detune 14
	hold 4
	detune -3
	hold 2
	snd_endloop
	rest_x 19
	snd_end
SSeq_58AE:
	volume 4
	note 4, 0
	snd_loop 5
	detune -6
	hold 1
	detune -7
	hold 1
	detune 4
	hold 1
	detune -6
	hold 1
	detune 5
	hold 1
	detune -7
	hold 1
	snd_endloop
	detune 3
	hold 1
	detune -3
	hold 1
	rest_x 7
	snd_jump SSeq_5888
Sfx82_CH4:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 0, STATIC
	snd_jump SSeq_590B
SSeq_58E4:
	volume 1
	instrument 0
	gate 255
	drest 0
	instrument 0, STATIC
	gate 0
	drum 3, 0
	drum 4, 1
	drum 5, 1
	volume 3
	drum 6, 1
	drum 7, 1
	volume 4
	drum 8, 1
	drum 9, 1
	volume 5
	snd_loop 4
	snd_loop 6
	drum_x 10, 1
	drum_x 9, 1
	snd_endloop
	volume_add -1
	snd_endloop
	drest_x 14
	snd_end
SSeq_590B:
	volume 1
	drum 6, 1
	volume 3
	drum 5, 1
	drum 4, 2
	volume 5
	drum 3, 2
	drum 2, 3
	volume 7
	drum 1, 3
	volume 10
	drum 1, 3
	drum 1, 0
	snd_loop 3
	drum 1, 0
	drum 1, 0
	snd_endloop
	volume 6
	snd_loop 3
	drum 1, 0
	drum 1, 0
	volume_add -1
	snd_endloop
	drest_x 9
	snd_jump SSeq_58E4
Sfx85_CH2:
	length_set 22
	pan PAN_LR
	instrument 2, STATIC
	gate 0
	base_note $26
	volume 14
	note -11, 0
	volume 4
	note -12, 0
	instrument 2, STATIC
	gate 0
	volume 1
	note -12, 1
	volume 9
	note 13, 0
	volume 5
	note 14, 0
	note 15, 0
Sfx90_CH1:
	snd_end
	length_set 30  ; unreferenced (stream)
	snd_end
Sfx86_CH2:
	length_set 22
	pan PAN_LR
	snd_call SSub_4A7A
	snd_end
Sfx89_CH1:
	volume 0
	rest 5
	snd_jump Sfx89_CH1
Sfx89_CH4:
	volume 0
	drest 5
	snd_jump Sfx89_CH4
Sfx91_CH2:
	volume 13
	rest_x 9
	snd_jump SSeq_596F
Sfx91_CH1:
	volume 15
SSeq_596F:
	length_set 22
	pan PAN_LR
	base_note $42
	instrument 2
	gate 186
	snd_loop 2
	snd_call SSub_5982
	volume_add -9
	snd_endloop
	snd_end
SSub_5982:
	note 0, 3
	note 5, 3
	note 2, 3
	note -2, 3
	snd_ret
Sfx92_CH4:
	length_set 22
	pan PAN_LR
	instrument 0
	gate 0
	volume 15
	drum 1, 0
	drum 1, 0
	drum 3, 0
	drum 5, 0
	drum 7, 0
	drum 8, 0
	drum 10, 0
	volume 14
	drum 11, 0
	drum 12, 0
	snd_loop 7
	drum 13, 0
	volume_add -1
	drum 14, 0
	volume_add -1
	snd_endloop
	snd_end
Sfx92_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	instrument 33
	base_note $3C
	volume 5
	note 0, 0
	volume 6
	note -2, 0
	note -4, 0
	volume 9
	note -5, 0
	volume 13
	note -6, 0
	note -7, 0
	volume 14
	note_x -8, 1
	snd_loop 12
	detune 12
	hold 1
	volume_add -1
	snd_endloop
	snd_end
Sfx93_CH2:
	base_note $27
	rest_x 2
	snd_jump SSeq_59D5
Sfx93_CH1:
	base_note $2B
SSeq_59D5:
	length_set 22
	pan PAN_LR
	gate 222
	volume 15
	instrument 41
	note -14, 3
	note -9, 3
	note -4, 2
	note 1, 3
	note 0, 2
	note -1, 2
	snd_end
Sfx93_CH3:
	volume 0
	rest_x 21
	snd_end
Sfx96_CH2:
	length_set 22
	pan PAN_LR
	gate 0
	base_note $3F
	instrument 2
	volume 4
	note 9, 0
	volume 8
	note 10, 0
	volume 15
	note_x 11, 0
	snd_loop 7
	detune 2
	hold 1
	volume_add -2
	snd_endloop
	snd_end
Sfx97_CH1:
	length_set 24
	pan PAN_LR
	gate 151
	base_note $33
	instrument 13
	volume 7
	snd_loop 15
	snd_call SSub_5A25
	snd_endloop
	note 12, 0
	rest 4
	base_note $27
SSeq_5A1F:
	snd_call SSub_5A25
	snd_jump SSeq_5A1F
SSub_5A25:
	note 7, 0
	note 0, 0
	note 5, 0
	note 0, 0
	note 12, 0
	note 0, 0
	snd_ret
Sfx97_CH2:
	length_set 24
	pan PAN_LR
	gate 151
	base_note $1B
	instrument 20
	snd_loop 8
	rest_x 54
	snd_endloop
	volume 11
	snd_call SSub_5AB7
	snd_loop 2
	snd_call SSub_5ACD
	snd_endloop
	snd_call SSub_5AB7
	snd_call SSub_5ACD
	note 12, 0
	note 0, 0
	volume_add -4
	note 0, 0
	volume_add 4
	note -5, 0
	instrument 41
	gate 222
	note_x -12, 6
	volume_add -4
	note_x -12, 6
	note_x -12, 6
SSeq_5A60:
	instrument 20
	snd_loop 2
	base_note $1B
	snd_call SSub_5AA1
	base_note $20
	snd_call SSub_5AA1
	snd_endloop
	base_note $1F
	snd_loop 4
	snd_call SSub_5A92
	snd_endloop
	base_note $1D
	snd_loop 3
	snd_call SSub_5A92
	snd_endloop
	base_note $16
	volume 12
	gate 166
	note -7, 0
	volume 8
	gate 132
	note 0, 0
	note 7, 0
	note 15, 0
	note 9, 0
	note -7, 0
	snd_jump SSeq_5A60
SSub_5A92:
	volume 12
	gate 166
	note -7, 0
	volume 10
	gate 132
	note 0, 0
	note 3, 0
	note -4, 0
	note 8, 0
	note 0, 0
	snd_ret
SSub_5AA1:
	snd_loop 2
	volume 10
	gate 166
	note -7, 0
	volume 7
	gate 132
	note 0, 0
	note 7, 0
	note -3, 0
	note 5, 0
	volume_add -3
	note 12, 0
	volume_add 3
	snd_endloop
	snd_ret
SSub_5AB7:
	snd_loop 2
	note -3, 0
	volume_add -2
	note 7, 0
	volume_add 2
	note 12, 0
	volume_add -4
	note 9, 0
	volume_add 4
	note 5, 0
	volume_add -4
	note 0, 0
	volume_add 4
	snd_endloop
	snd_ret
SSub_5ACD:
	note -2, 0
	volume_add -2
	note 7, 0
	volume_add 2
	note 14, 0
	volume_add -4
	note 9, 0
	volume_add 4
	note 7, 0
	volume_add -4
	note 0, 0
	volume_add 4
	snd_ret
Sfx97_CH3:
	length_set 24
	pan PAN_LR
	volume 0
	base_note $33
	instrument 13
	snd_loop 15
	rest_x 54
	snd_endloop
	rest 2
	volume 11
	gate 0
	note_x -12, 4
	note_x -10, 4
	note_x -8, 3
	note_x -7, 4
	note_x -5, 4
	note_x -3, 4
	note_x -2, 4
	snd_call SSub_5B53
	gate 0
	note_x 4, 0
	snd_loop 3
	volume_add -2
	hold 6
	snd_endloop
	volume_add 6
	note_x 0, 0
	snd_loop 6
	volume_add -1
	hold 18
	snd_endloop
	volume_add 6
	note_x -12, 0
	snd_loop 6
	volume_add -1
	hold 18
	snd_endloop
	instrument 14
	volume 9
	snd_call SSub_5B53
	note 4, 0
	note 5, 0
	note_x 0, 0
	snd_loop 3
	volume_add -1
	hold 36
	snd_endloop
	volume_add 6
	snd_loop 3
	rest_x 36
	snd_endloop
	snd_loop 16
	rest_x 54
	snd_endloop
	volume 11
	instrument 2
	gate 40
SSeq_5B4A:
	note 9, 1
	note 7, 1
	note 12, 1
	note 9, 1
	note 5, 1
	note 7, 1
	snd_jump SSeq_5B4A
SSub_5B53:
	note 0, 3
	note -3, 0
	note -7, 0
	note -12, 1
	note -7, 1
	note 2, 1
	note 0, 1
	note -2, 1
	note -10, 3
	rest 1
	note -8, 0
	note -7, 0
	note -5, 3
	note -7, 1
	note -8, 3
	note -7, 1
	note_x -12, 72
	rest 3
	note -12, 3
	note -10, 0
	note -12, 0
	note -12, 1
	note -7, 1
	note -5, 1
	note -3, 5
	note 2, 3
	snd_ret
InitialLengthSets:
	db   1,   2,   3,   4,   5,   6  ; length set 0
	db   5,  10,  15,  20,  30,  80  ; length set 1
	db   9,  18,  27,  36,  45,  54  ; length set 2
	db   7,  14,  21,  28,  35,  42  ; length set 3
	db   6,  12,  18,  24,  30,  36  ; length set 4
	db   8,  16,  24,  32,  40,  48  ; length set 5
	db  10,  20,  30,  40,  50,  60  ; length set 6
	db  11,  22,  33,  44,  55,  66  ; length set 7
	db   4,   4,   8,  16,  40,  32  ; length set 8
	db   3,   4,   9,  12,  27,  63  ; length set 9
	db   4,   8,  12,  16,  24,  64  ; length set 10
	db   1,   2,   3,   4,   5,   6  ; length set 11
	db   5,  10,  15,  20,  30,  80  ; length set 12
	db   9,  18,  27,  36,  45,  54  ; length set 13
	db   7,  14,  21,  28,  35,  42  ; length set 14
	db   6,  12,  18,  24,  30,  36  ; length set 15
	db   8,  16,  24,  32,  40,  48  ; length set 16
	db  10,  20,  30,  40,  50,  60  ; length set 17
	db  11,  22,  33,  44,  55,  66  ; length set 18
	db   4,   4,   8,  16,  40,  32  ; length set 19
	db   3,   4,   9,  12,  27,  63  ; length set 20
	db   4,   8,  12,  16,  24,  64  ; length set 21
	db   1,   2,   3,   4,   5,   6  ; length set 22
	db   5,  10,  15,  20,  30,  80  ; length set 23
	db   9,  18,  27,  36,  45,  54  ; length set 24
	db   7,  14,  21,  28,  35,  42  ; length set 25
	db   6,  12,  18,  24,  30,  36  ; length set 26
	db   8,  16,  24,  32,  40,  48  ; length set 27
	db  10,  20,  30,  40,  50,  60  ; length set 28
	db  11,  22,  33,  44,  55,  66  ; length set 29
	db   4,   4,   8,  16,  40,  32  ; length set 30
	db   3,   4,   9,  12,  27,  63  ; length set 31
	db   4,   8,  12,  16,  24,  64  ; length set 32
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
	dw Sfx36  ; sfx 36
	dw Sfx37  ; sfx 37
	dw Sfx38  ; sfx 38
	dw Sfx39  ; sfx 39
	dw Sfx40  ; sfx 40
	dw Sfx41  ; sfx 41
	dw Sfx42  ; sfx 42
	dw Sfx43  ; sfx 43
	dw Sfx44  ; sfx 44
	dw Sfx45  ; sfx 45
	dw Sfx46  ; sfx 46
	dw Sfx47  ; sfx 47
	dw Sfx48  ; sfx 48
	dw Sfx49  ; sfx 49
	dw Sfx50  ; sfx 50
	dw Sfx51  ; sfx 51
	dw Sfx52  ; sfx 52
	dw Sfx53  ; sfx 53
	dw Sfx54  ; sfx 54
	dw Sfx55  ; sfx 55
	dw Sfx56  ; sfx 56
	dw Sfx57  ; sfx 57
	dw Sfx58  ; sfx 58
	dw Sfx59  ; sfx 59
	dw Sfx60  ; sfx 60
	dw Sfx61  ; sfx 61
	dw Sfx62  ; sfx 62
	dw Sfx63  ; sfx 63
	dw Sfx64  ; sfx 64
	dw Sfx65  ; sfx 65
	dw Sfx66  ; sfx 66
	dw Sfx67  ; sfx 67
	dw Sfx68  ; sfx 68
	dw Sfx69  ; sfx 69
	dw Sfx70  ; sfx 70
	dw Sfx71  ; sfx 71
	dw Sfx72  ; sfx 72
	dw Sfx73  ; sfx 73
	dw Sfx74  ; sfx 74
	dw Sfx75  ; sfx 75
	dw Sfx76  ; sfx 76
	dw Sfx77  ; sfx 77
	dw Sfx78  ; sfx 78
	dw Sfx79  ; sfx 79
	dw Sfx80  ; sfx 80
	dw Sfx81  ; sfx 81
	dw Sfx82  ; sfx 82
	dw Sfx83  ; sfx 83
	dw Sfx84  ; sfx 84
	dw Sfx85  ; sfx 85
	dw Sfx86  ; sfx 86
	dw Sfx87  ; sfx 87
	dw Sfx88  ; sfx 88
	dw Sfx89  ; sfx 89
	dw Sfx90  ; sfx 90
	dw Sfx91  ; sfx 91
	dw Sfx92  ; sfx 92
	dw Sfx93  ; sfx 93
	dw Sfx94  ; sfx 94
	dw Sfx95  ; sfx 95
	dw Sfx96  ; sfx 96
	dw Sfx97  ; sfx 97
SfxChannelMasks:
	db %00011  ; sfx 0
	db %01010  ; sfx 1
	db %00010  ; sfx 2
	db %00010  ; sfx 3
	db %00010  ; sfx 4
	db %00010  ; sfx 5
	db %01010  ; sfx 6
	db %00011  ; sfx 7
	db %00010  ; sfx 8
	db %00010  ; sfx 9
	db %01010  ; sfx 10
	db %00010  ; sfx 11
	db %01010  ; sfx 12
	db %00010  ; sfx 13
	db %01000  ; sfx 14
	db %00010  ; sfx 15
	db %00010  ; sfx 16
	db %01000  ; sfx 17
	db %00010  ; sfx 18
	db %00001  ; sfx 19
	db %00001  ; sfx 20
	db %01000  ; sfx 21
	db %01010  ; sfx 22
	db %01010  ; sfx 23
	db %01010  ; sfx 24
	db %01000  ; sfx 25
	db %00010  ; sfx 26
	db %00010  ; sfx 27
	db %01000  ; sfx 28
	db %00010  ; sfx 29
	db %01000  ; sfx 30
	db %01000  ; sfx 31
	db %01000  ; sfx 32
	db %00011  ; sfx 33
	db %01010  ; sfx 34
	db %01000  ; sfx 35
	db %01000  ; sfx 36
	db %00010  ; sfx 37
	db %11011  ; sfx 38
	db %11011  ; sfx 39
	db %10011  ; sfx 40
	db %11011  ; sfx 41
	db %10011  ; sfx 42
	db %01000  ; sfx 43
	db %00010  ; sfx 44
	db %00010  ; sfx 45
	db %01010  ; sfx 46
	db %11011  ; sfx 47
	db %00010  ; sfx 48
	db %01010  ; sfx 49
	db %01010  ; sfx 50
	db %01000  ; sfx 51
	db %01000  ; sfx 52
	db %01010  ; sfx 53
	db %01000  ; sfx 54
	db %01000  ; sfx 55
	db %00010  ; sfx 56
	db %01010  ; sfx 57
	db %01010  ; sfx 58
	db %00001  ; sfx 59
	db %00010  ; sfx 60
	db %01000  ; sfx 61
	db %01000  ; sfx 62
	db %01010  ; sfx 63
	db %11000  ; sfx 64
	db %00011  ; sfx 65
	db %00010  ; sfx 66
	db %01011  ; sfx 67
	db %00011  ; sfx 68
	db %01000  ; sfx 69
	db %01010  ; sfx 70
	db %00010  ; sfx 71
	db %00010  ; sfx 72
	db %00011  ; sfx 73
	db %01010  ; sfx 74
	db %00010  ; sfx 75
	db %01010  ; sfx 76
	db %01000  ; sfx 77
	db %01010  ; sfx 78
	db %11010  ; sfx 79
	db %01010  ; sfx 80
	db %01000  ; sfx 81
	db %01010  ; sfx 82
	db %01010  ; sfx 83
	db %01000  ; sfx 84
	db %00010  ; sfx 85
	db %00010  ; sfx 86
	db %01000  ; sfx 87
	db %00011  ; sfx 88
	db %11011  ; sfx 89
	db %11011  ; sfx 90
	db %00011  ; sfx 91
	db %01010  ; sfx 92
	db %10011  ; sfx 93
	db %11011  ; sfx 94
	db %00010  ; sfx 95
	db %00010  ; sfx 96
	db %10011  ; sfx 97
SfxPriorities:
	db 15  ; sfx 0
	db 30  ; sfx 1
	db 30  ; sfx 2
	db 30  ; sfx 3
	db 30  ; sfx 4
	db 30  ; sfx 5
	db 20  ; sfx 6
	db 15  ; sfx 7
	db 33  ; sfx 8
	db 35  ; sfx 9
	db 30  ; sfx 10
	db 30  ; sfx 11
	db 20  ; sfx 12
	db 32  ; sfx 13
	db 31  ; sfx 14
	db 15  ; sfx 15
	db 15  ; sfx 16
	db 20  ; sfx 17
	db 10  ; sfx 18
	db 9  ; sfx 19
	db 9  ; sfx 20
	db 30  ; sfx 21
	db 30  ; sfx 22
	db 30  ; sfx 23
	db 30  ; sfx 24
	db 30  ; sfx 25
	db 30  ; sfx 26
	db 30  ; sfx 27
	db 30  ; sfx 28
	db 30  ; sfx 29
	db 30  ; sfx 30
	db 30  ; sfx 31
	db 5  ; sfx 32
	db 5  ; sfx 33
	db 30  ; sfx 34
	db 30  ; sfx 35
	db 30  ; sfx 36
	db 30  ; sfx 37
	db 9  ; sfx 38
	db 10  ; sfx 39
	db 15  ; sfx 40
	db 20  ; sfx 41
	db 3  ; sfx 42
	db 15  ; sfx 43
	db 3  ; sfx 44
	db 3  ; sfx 45
	db 25  ; sfx 46
	db 5  ; sfx 47
	db 30  ; sfx 48
	db 30  ; sfx 49
	db 25  ; sfx 50
	db 30  ; sfx 51
	db 20  ; sfx 52
	db 30  ; sfx 53
	db 20  ; sfx 54
	db 30  ; sfx 55
	db 30  ; sfx 56
	db 30  ; sfx 57
	db 29  ; sfx 58
	db 30  ; sfx 59
	db 15  ; sfx 60
	db 25  ; sfx 61
	db 30  ; sfx 62
	db 30  ; sfx 63
	db 20  ; sfx 64
	db 30  ; sfx 65
	db 30  ; sfx 66
	db 10  ; sfx 67
	db 29  ; sfx 68
	db 30  ; sfx 69
	db 30  ; sfx 70
	db 28  ; sfx 71
	db 31  ; sfx 72
	db 30  ; sfx 73
	db 15  ; sfx 74
	db 15  ; sfx 75
	db 30  ; sfx 76
	db 30  ; sfx 77
	db 30  ; sfx 78
	db 30  ; sfx 79
	db 6  ; sfx 80
	db 28  ; sfx 81
	db 30  ; sfx 82
	db 15  ; sfx 83
	db 25  ; sfx 84
	db 30  ; sfx 85
	db 20  ; sfx 86
	db 25  ; sfx 87
	db 0  ; sfx 88
	db 6  ; sfx 89
	db 6  ; sfx 90
	db 6  ; sfx 91
	db 30  ; sfx 92
	db 20  ; sfx 93
	db 50  ; sfx 94
	db 20  ; sfx 95
	db 11  ; sfx 96
	db 0  ; sfx 97
