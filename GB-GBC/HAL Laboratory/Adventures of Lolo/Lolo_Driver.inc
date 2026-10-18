; bank 0: far wrappers, driver code and tables ($32AE-$3C16)


; Far wrappers: switch to the music bank ($0F) with rst $30, call, restore the bank.
Sound_PlaySfxFar:
	push af                     ; 32AE
	push bc                     ; 32AF
	push de                     ; 32B0
	push hl                     ; 32B1
	ld b, a                     ; 32B2
	ld a, [wCurBank]            ; 32B3
	push af                     ; 32B6
	ld a, $0F                   ; 32B7
	rst $30                     ; 32B9
	ld a, b                     ; 32BA
	call Sound_PlaySfx          ; 32BB
	pop af                      ; 32BE
	rst $30                     ; 32BF
	pop hl                      ; 32C0
	pop de                      ; 32C1
	pop bc                      ; 32C2
	pop af                      ; 32C3
	ret                         ; 32C4

Sound_PlaySongFar:
	push af                     ; 32C5
	push bc                     ; 32C6
	push de                     ; 32C7
	push hl                     ; 32C8
	ld b, a                     ; 32C9
	ld a, [wCurBank]            ; 32CA
	push af                     ; 32CD
	ld a, $0F                   ; 32CE
	rst $30                     ; 32D0
	ld a, b                     ; 32D1
	call Sound_PlaySong         ; 32D2
	pop af                      ; 32D5
	rst $30                     ; 32D6
	pop hl                      ; 32D7
	pop de                      ; 32D8
	pop bc                      ; 32D9
	pop af                      ; 32DA
	ret                         ; 32DB

Sound_InitFar:
	ld a, [wCurBank]            ; 32DC
	push af                     ; 32DF
	ld a, $0F                   ; 32E0
	rst $30                     ; 32E2
	call Sound_Init             ; 32E3
	pop af                      ; 32E6
	rst $30                     ; 32E7
	ret                         ; 32E8


; Sound_Init: master on, NR50=$77, NR51=$FF, full volume, shadow registers invalidated ($AA),
; load the initial wave, stop music and SFX, write the registers and retrigger all channels.
Sound_Init:
	ld a, $80                   ; 32E9
	ldh [rNR52], a              ; 32EB
	ld a, $77                   ; 32ED
	ldh [rNR50], a              ; 32EF
	ld a, $FF                   ; 32F1
	ldh [rNR51], a              ; 32F3
	ld a, $FF                   ; 32F5
	ld [wSfxAttenuation], a     ; 32F7
	ld [wMusicAttenuation], a   ; 32FA
	ld [wCurWave], a            ; 32FD
	ld hl, wHwRegs              ; 3300
	ld b, $14                   ; 3303
	ld a, $AA                   ; 3305
.l_3307:
	ld [hli], a                 ; 3307
	dec b                       ; 3308
	jr nz, .l_3307              ; 3309
	ld hl, InitialWave          ; 330B
	call LoadWave               ; 330E
	ld a, $FF                   ; 3311
	call Sound_PlaySong         ; 3313
	ld a, $FF                   ; 3316
	call Sound_PlaySfx          ; 3318
	call Sound_WriteRegs        ; 331B
	ld hl, rNR14                ; 331E
	set 7, [hl]                 ; 3321
	ld hl, rNR24                ; 3323
	set 7, [hl]                 ; 3326
	ld hl, rNR34                ; 3328
	set 7, [hl]                 ; 332B
	ld hl, rNR44                ; 332D
	set 7, [hl]                 ; 3330
	ld a, $38                   ; 3332
	ld [wSoundUnused53], a      ; 3334
	ld a, $1B                   ; 3337
	ld [wSoundUnused54], a      ; 3339
	xor a                       ; 333C
	ld [wPatternVariant], a     ; 333D
	ld [wSfxTranspose], a       ; 3340
	ld [wSfxTranspose + 1], a   ; 3343
	ld [wSfxTranspose + 2], a   ; 3346
	ret                         ; 3349


; Sound_PlaySfx: a = SFX number ($FF = stop all SFX).
; If an SFX already owns one of the new SFX's channels, the new one is refused when its
; priority number is higher than the playing one's (lower number = more important);
; otherwise the old SFX track is stopped. Tracks are then taken from track 3 downward.
Sound_PlaySfx:
	ld e, a                     ; 334A
	cp $FF                      ; 334B
	jp z, Sound_StopSfx         ; 334D
	ld d, $00                   ; 3350
	ld a, [wSfxChannels]        ; 3352
	and a                       ; 3355
	jr z, .l_3384               ; 3356
	ld hl, SfxChannelMasks      ; 3358
	add hl, de                  ; 335B
	and [hl]                    ; 335C
	jr z, .l_3384               ; 335D
	ld bc, $0003                ; 335F
.l_3362:
	ld hl, SfxChannelMasks      ; 3362
	add hl, de                  ; 3365
	ld a, [hl]                  ; 3366
	ld hl, wSfxMask             ; 3367
	add hl, bc                  ; 336A
	and [hl]                    ; 336B
	jr z, .l_337F               ; 336C
	ld hl, wSfxPriority         ; 336E
	add hl, bc                  ; 3371
	ld a, [hl]                  ; 3372
	ld hl, SfxPriorities        ; 3373
	add hl, de                  ; 3376
	cp [hl]                     ; 3377
	ret c                       ; 3378
	ld hl, wTrkWait             ; 3379
	add hl, bc                  ; 337C
	ld [hl], $00                ; 337D
.l_337F:
	dec c                       ; 337F
	bit 7, c                    ; 3380
	jr z, .l_3362               ; 3382
.l_3384:
	ld hl, SfxChannelMasks      ; 3384
	add hl, de                  ; 3387
	ld a, [hl]                  ; 3388
	ld [wSfxNewMask], a         ; 3389
	ld hl, SfxPriorities        ; 338C
	add hl, de                  ; 338F
	ld a, [hl]                  ; 3390
	ld c, a                     ; 3391
	ld hl, SfxTable             ; 3392
	add hl, de                  ; 3395
	add hl, de                  ; 3396
	ld a, [hli]                 ; 3397
	ld e, a                     ; 3398
	ld d, [hl]                  ; 3399
	ld a, [de]                  ; 339A
	ld h, a                     ; 339B
	ld l, c                     ; 339C
	push hl                     ; 339D
	ld bc, $0003                ; 339E
.l_33A1:
	ld hl, wTrkWait             ; 33A1
	add hl, bc                  ; 33A4
	ld a, [hl]                  ; 33A5
	and a                       ; 33A6
	jr nz, .l_33C1              ; 33A7
	call Sound_StartTrack       ; 33A9
	ld hl, sp+0                 ; 33AC
	ld a, [hl]                  ; 33AE
	ld hl, wSfxPriority         ; 33AF
	add hl, bc                  ; 33B2
	ld [hl], a                  ; 33B3
	ld a, [wSfxNewMask]         ; 33B4
	ld hl, wSfxMask             ; 33B7
	add hl, bc                  ; 33BA
	ld [hl], a                  ; 33BB
	pop hl                      ; 33BC
	dec h                       ; 33BD
	push hl                     ; 33BE
	jr z, .l_33C6               ; 33BF
.l_33C1:
	dec c                       ; 33C1
	bit 7, c                    ; 33C2
	jr z, .l_33A1               ; 33C4
.l_33C6:
	pop hl                      ; 33C6

; wSfxChannels = OR of the channel masks of the SFX tracks still running.
Sound_UpdateSfxChannels:
	ld a, [wSfxMask]            ; 33C7
	ld hl, wSfxMask + 1         ; 33CA
	ld c, $03                   ; 33CD
.l_33CF:
	or [hl]                     ; 33CF
	inc hl                      ; 33D0
	dec c                       ; 33D1
	jr nz, .l_33CF              ; 33D2
	ld [wSfxChannels], a        ; 33D4
	ret                         ; 33D7


; stop SFX tracks 0-3 and reset the SFX register image.
Sound_StopSfx:
	ld bc, $0003                ; 33D8
.l_33DB:
	ld hl, wTrkWait             ; 33DB
	add hl, bc                  ; 33DE
	ld [hl], b                  ; 33DF
	ld hl, wSfxMask             ; 33E0
	add hl, bc                  ; 33E3
	ld [hl], b                  ; 33E4
	ld hl, wSfxPriority         ; 33E5
	add hl, bc                  ; 33E8
	ld [hl], $FF                ; 33E9
	dec c                       ; 33EB
	bit 7, c                    ; 33EC
	jr z, .l_33DB               ; 33EE
	ld hl, DefaultRegImage      ; 33F0
	ld de, wSfxRegs             ; 33F3
	ld c, $14                   ; 33F6
.l_33F8:
	ld a, [hli]                 ; 33F8
	ld [de], a                  ; 33F9
	inc de                      ; 33FA
	dec c                       ; 33FB
	jr nz, .l_33F8              ; 33FC
	ret                         ; 33FE

DefaultRegImage:
	db $08, $00, $08, $00, $80, $00, $00, $08, $00, $80, $80, $00, $00, $00, $80, $00
	db $00, $08, $00, $80

; Sound_StartTrack: c = track, de -> header entry - 1. Reads pointer + channel byte,
; resets the per-track state (base note $24, volume, instrument, length set, tuning, stacks).
Sound_StartTrack:
	ld hl, wTrkBaseNote         ; 3413
	add hl, bc                  ; 3416
	ld [hl], $24                ; 3417
	xor a                       ; 3419
	ld hl, wTrkGate             ; 341A
	add hl, bc                  ; 341D
	ld [hl], a                  ; 341E
	ld hl, wTrkVolume           ; 341F
	add hl, bc                  ; 3422
	ld [hl], a                  ; 3423
	ld hl, wTrkInstrument       ; 3424
	add hl, bc                  ; 3427
	ld [hl], a                  ; 3428
	ld hl, wTrkLengthSet        ; 3429
	add hl, bc                  ; 342C
	ld [hl], a                  ; 342D
	ld hl, wTrkTuning           ; 342E
	add hl, bc                  ; 3431
	ld [hl], a                  ; 3432
	ld hl, TrackStackTable      ; 3433
	add hl, bc                  ; 3436
	ld a, [hl]                  ; 3437
	ld hl, wTrkStack            ; 3438
	add hl, bc                  ; 343B
	ld [hl], a                  ; 343C
	inc de                      ; 343D
	ld a, [de]                  ; 343E
	ld hl, wTrkPtrLo            ; 343F
	add hl, bc                  ; 3442
	ld [hl], a                  ; 3443
	inc de                      ; 3444
	ld a, [de]                  ; 3445
	ld hl, wTrkPtrHi            ; 3446
	add hl, bc                  ; 3449
	ld [hl], a                  ; 344A
	inc de                      ; 344B
	ld a, [de]                  ; 344C
	sra a                       ; 344D
	sra a                       ; 344F
	add a, LOW(HwOffsetTable)   ; 3451
	ld l, a                     ; 3453
	ld h, HIGH(HwOffsetTable)   ; 3454
	jr nc, .l_3459              ; 3456
	inc h                       ; 3458
.l_3459:
	ld a, [hl]                  ; 3459
	ld hl, wTrkHwOffset         ; 345A
	add hl, bc                  ; 345D
	ld [hl], a                  ; 345E
	ld hl, wTrkWait             ; 345F
	add hl, bc                  ; 3462
	ld [hl], $01                ; 3463
	ld hl, wTrkRelease          ; 3465
	add hl, bc                  ; 3468
	ld [hl], $01                ; 3469
	ret                         ; 346B

HwOffsetTable:
	db $00, $05, $FF, $0F, $0A

; Sound_PlaySong: a = song ($FF = stop). Also sets up the pattern sequencer: wPatternGroup =
; SongPatternGroups[song] ($FF = none), wPatternPeriod = SongPatternPeriods[song], 8 rows.
; Then starts the header's tracks from track 7 downward.
Sound_PlaySong:
	ld b, a                     ; 3471
	ld hl, wTrkWait + 4         ; 3472
	ld c, $04                   ; 3475
	xor a                       ; 3477
.l_3478:
	ld [hli], a                 ; 3478
	dec c                       ; 3479
	jr nz, .l_3478              ; 347A
	ld hl, DefaultRegImage      ; 347C
	ld de, wMusicRegs           ; 347F
	ld c, $14                   ; 3482
.l_3484:
	ld a, [hli]                 ; 3484
	ld [de], a                  ; 3485
	inc de                      ; 3486
	dec c                       ; 3487
	jr nz, .l_3484              ; 3488
	xor a                       ; 348A
	ld [wPatternTimer], a       ; 348B
	ld [wPatternRow], a         ; 348E
	dec a                       ; 3491
	ld [wPatternGroup], a       ; 3492
	cp b                        ; 3495
	ret z                       ; 3496
	ld e, b                     ; 3497
	ld d, $00                   ; 3498
	ld hl, SongPatternGroups    ; 349A
	add hl, de                  ; 349D
	ld a, [hl]                  ; 349E
	ld [wPatternGroup], a       ; 349F
	ld hl, SongPatternPeriods   ; 34A2
	add hl, de                  ; 34A5
	ld a, [hl]                  ; 34A6
	ld [wPatternPeriod], a      ; 34A7
	ld a, $08                   ; 34AA
	ld [wPatternRows], a        ; 34AC
	ld e, b                     ; 34AF
	ld d, $00                   ; 34B0
	ld hl, SongTable            ; 34B2
	add hl, de                  ; 34B5
	add hl, de                  ; 34B6
	ld a, [hli]                 ; 34B7
	ld e, a                     ; 34B8
	ld d, [hl]                  ; 34B9
	ld a, [de]                  ; 34BA
	ld h, a                     ; 34BB
	push hl                     ; 34BC
	ld bc, $0007                ; 34BD
.l_34C0:
	ld hl, wTrkWait             ; 34C0
	add hl, bc                  ; 34C3
	ld a, [hl]                  ; 34C4
	and a                       ; 34C5
	jr nz, .l_34D0              ; 34C6
	call Sound_StartTrack       ; 34C8
	pop hl                      ; 34CB
	dec h                       ; 34CC
	push hl                     ; 34CD
	jr z, .l_34D6               ; 34CE
.l_34D0:
	dec c                       ; 34D0
	ld a, $03                   ; 34D1
	cp c                        ; 34D3
	jr nz, .l_34C0              ; 34D4
.l_34D6:
	pop hl                      ; 34D6
	ret                         ; 34D7


; Sound_Update (timer interrupt): pattern sequencer first. If the song has a pattern group,
; every wPatternPeriod ticks the row advances (mod 8) and tracks 7..4 are re-pointed to
; PatternTables[group*5 + wPatternVariant] row entries 0..3, with wait = 1 and their
; call/loop stacks reset. The game changes wPatternVariant to switch arrangements.
Sound_Update:
	ld a, [wPatternGroup]       ; 34D8
	cp $FF                      ; 34DB
	jp z, Sound_UpdateTracks    ; 34DD
	ld hl, wPatternTimer        ; 34E0
	inc [hl]                    ; 34E3
	ld a, [wPatternPeriod]      ; 34E4
	cp [hl]                     ; 34E7
	jp nz, Sound_UpdateTracks   ; 34E8
	ld [hl], $00                ; 34EB
	ld hl, wPatternRow          ; 34ED
	inc [hl]                    ; 34F0
	ld a, [wPatternRows]        ; 34F1
	cp [hl]                     ; 34F4
	jr nz, .l_34F9              ; 34F5
	ld [hl], $00                ; 34F7
.l_34F9:
	ld a, [wPatternGroup]       ; 34F9
	ld e, a                     ; 34FC
	add a, a                    ; 34FD
	add a, a                    ; 34FE
	add a, e                    ; 34FF
	ld hl, wPatternVariant      ; 3500
	add a, [hl]                 ; 3503
	ld e, a                     ; 3504
	ld d, $00                   ; 3505
	ld hl, PatternTables        ; 3507
	add hl, de                  ; 350A
	add hl, de                  ; 350B
	ld a, [hli]                 ; 350C
	ld e, a                     ; 350D
	ld d, [hl]                  ; 350E
	ld a, [wPatternRow]         ; 350F
	ld l, a                     ; 3512
	ld h, $00                   ; 3513
	add hl, hl                  ; 3515
	add hl, hl                  ; 3516
	add hl, hl                  ; 3517
	add hl, de                  ; 3518
	ld a, [hli]                 ; 3519
	ld [wTrkPtrLo + 7], a       ; 351A
	ld a, [hli]                 ; 351D
	ld [wTrkPtrHi + 7], a       ; 351E
	ld a, [hli]                 ; 3521
	ld [wTrkPtrLo + 6], a       ; 3522
	ld a, [hli]                 ; 3525
	ld [wTrkPtrHi + 6], a       ; 3526
	ld a, [hli]                 ; 3529
	ld [wTrkPtrLo + 5], a       ; 352A
	ld a, [hli]                 ; 352D
	ld [wTrkPtrHi + 5], a       ; 352E
	ld a, [hli]                 ; 3531
	ld [wTrkPtrLo + 4], a       ; 3532
	ld a, [hli]                 ; 3535
	ld [wTrkPtrHi + 4], a       ; 3536
	ld a, $01                   ; 3539
	ld hl, wTrkWait + 4         ; 353B
	ld [hli], a                 ; 353E
	ld [hli], a                 ; 353F
	ld [hli], a                 ; 3540
	ld [hli], a                 ; 3541
	ld a, [TrackStackTable + 4] ; 3542
	ld [wTrkStack + 4], a       ; 3545
	ld a, [TrackStackTable + 5] ; 3548
	ld [wTrkStack + 5], a       ; 354B
	ld a, [TrackStackTable + 6] ; 354E
	ld [wTrkStack + 6], a       ; 3551
	ld a, [TrackStackTable + 7] ; 3554
	ld [wTrkStack + 7], a       ; 3557
Sound_UpdateTracks:
	ld b, $07                   ; 355A
.l_355C:
	ld h, HIGH(wSoundRAM)       ; 355C
	ld a, LOW(wTrkWait)         ; 355E
	add a, b                    ; 3560
	ld l, a                     ; 3561
	ld a, [hl]                  ; 3562
	and a                       ; 3563
	jr z, .l_35A1               ; 3564
	ld a, b                     ; 3566
	cp $04                      ; 3567
	ld a, $1A                   ; 3569
	jr c, .l_356F               ; 356B
	ld a, $2E                   ; 356D
.l_356F:
	ld [hRegImage], a           ; 356F
	ld h, HIGH(wSoundRAM)       ; 3572
	ld a, LOW(wTrkPtrLo)        ; 3574
	add a, b                    ; 3576
	ld l, a                     ; 3577
	push hl                     ; 3578
	ld e, [hl]                  ; 3579
	add a, LOW(wTrkPtrHi - wTrkPtrLo); 357A
	ld l, a                     ; 357C
	push hl                     ; 357D
	ld d, [hl]                  ; 357E
	push bc                     ; 357F
	call Track_Main             ; 3580
	pop bc                      ; 3583
	pop hl                      ; 3584
	ld [hl], d                  ; 3585
	pop hl                      ; 3586
	ld [hl], e                  ; 3587
	call Track_Release          ; 3588
	ld h, HIGH(wSoundRAM)       ; 358B
	ld a, LOW(wTrkEnvPtrLo)     ; 358D
	add a, b                    ; 358F
	ld l, a                     ; 3590
	push hl                     ; 3591
	ld e, [hl]                  ; 3592
	add a, LOW(wTrkEnvPtrHi - wTrkEnvPtrLo); 3593
	ld l, a                     ; 3595
	push hl                     ; 3596
	ld d, [hl]                  ; 3597
	push bc                     ; 3598
	call Track_Env              ; 3599
	pop bc                      ; 359C
	pop hl                      ; 359D
	ld [hl], d                  ; 359E
	pop hl                      ; 359F
	ld [hl], e                  ; 35A0
.l_35A1:
	dec b                       ; 35A1
	bit 7, b                    ; 35A2
	jr z, .l_355C               ; 35A4
	ld b, $03                   ; 35A6
.l_35A8:
	ld h, HIGH(wSoundRAM)       ; 35A8
	ld a, LOW(wTrkWait)         ; 35AA
	add a, b                    ; 35AC
	ld l, a                     ; 35AD
	ld a, [hl]                  ; 35AE
	and a                       ; 35AF
	jr nz, .l_35BD              ; 35B0
	ld a, LOW(wSfxPriority)     ; 35B2
	add a, b                    ; 35B4
	ld l, a                     ; 35B5
	ld [hl], $FF                ; 35B6
	add a, LOW(wSfxMask - wSfxPriority); 35B8
	ld l, a                     ; 35BA
	ld [hl], $00                ; 35BB
.l_35BD:
	dec b                       ; 35BD
	bit 7, b                    ; 35BE
	jr z, .l_35A8               ; 35C0
	call Sound_UpdateSfxChannels; 35C2

; compare the chosen image with wHwRegs and write the changed registers.
Sound_WriteRegs:
	ld de, wMusicRegs           ; 35C5
	ld a, [wSfxChannels]        ; 35C8
	bit 0, a                    ; 35CB
	jr z, .l_35D1               ; 35CD
	ld e, $1A                   ; 35CF
.l_35D1:
	ld b, $00                   ; 35D1
	ld hl, wHwRegs              ; 35D3
	ld c, $10                   ; 35D6
.l_35D8:
	ld a, [de]                  ; 35D8
	cp [hl]                     ; 35D9
	jr z, .l_35E4               ; 35DA
	ld [hl], a                  ; 35DC
	ldh [c], a                  ; 35DD
	ld a, c                     ; 35DE
	cp $12                      ; 35DF
	jr nz, .l_35E4              ; 35E1
	inc b                       ; 35E3
.l_35E4:
	inc l                       ; 35E4
	inc e                       ; 35E5
	inc c                       ; 35E6
	ld a, c                     ; 35E7
	cp $15                      ; 35E8
	jr nz, .l_35D8              ; 35EA
	dec b                       ; 35EC
	jr nz, .l_35F6              ; 35ED
	ld a, [wHwRegs + 4]         ; 35EF
	set 7, a                    ; 35F2
	ldh [rNR14], a              ; 35F4
.l_35F6:
	ld de, wMusicRegs + 6       ; 35F6
	ld a, [wSfxChannels]        ; 35F9
	bit 1, a                    ; 35FC
	jr z, .l_3602               ; 35FE
	ld e, $20                   ; 3600
.l_3602:
	ld b, $00                   ; 3602
	ld hl, wHwRegs + 6          ; 3604
	ld c, $16                   ; 3607
.l_3609:
	ld a, [de]                  ; 3609
	cp [hl]                     ; 360A
	jr z, .l_3615               ; 360B
	ld [hl], a                  ; 360D
	ldh [c], a                  ; 360E
	ld a, c                     ; 360F
	cp $17                      ; 3610
	jr nz, .l_3615              ; 3612
	inc b                       ; 3614
.l_3615:
	inc l                       ; 3615
	inc e                       ; 3616
	inc c                       ; 3617
	ld a, c                     ; 3618
	cp $1A                      ; 3619
	jr nz, .l_3609              ; 361B
	dec b                       ; 361D
	jr nz, .l_3627              ; 361E
	ld a, [$C80F]               ; 3620
	set 7, a                    ; 3623
	ldh [rNR24], a              ; 3625
.l_3627:
	ld de, $C838                ; 3627
	ld a, [wSfxChannels]        ; 362A
	bit 4, a                    ; 362D
	jr z, .l_3633               ; 362F
	ld e, $24                   ; 3631
.l_3633:
	ld hl, $C810                ; 3633
	ld c, $1A                   ; 3636
.l_3638:
	ld a, [de]                  ; 3638
	cp [hl]                     ; 3639
	jr z, .l_363E               ; 363A
	ld [hl], a                  ; 363C
	ldh [c], a                  ; 363D
.l_363E:
	inc l                       ; 363E
	inc e                       ; 363F
	inc c                       ; 3640
	ld a, c                     ; 3641
	cp $1F                      ; 3642
	jr nz, .l_3638              ; 3644
	ld de, $C83E                ; 3646
	ld a, [wSfxChannels]        ; 3649
	bit 3, a                    ; 364C
	jr z, .l_3652               ; 364E
	ld e, $2A                   ; 3650
.l_3652:
	ld b, $00                   ; 3652
	ld hl, $C816                ; 3654
	ld c, $20                   ; 3657
.l_3659:
	ld a, [de]                  ; 3659
	cp [hl]                     ; 365A
	jr z, .l_3665               ; 365B
	ld [hl], a                  ; 365D
	ldh [c], a                  ; 365E
	ld a, c                     ; 365F
	cp $21                      ; 3660
	jr nz, .l_3665              ; 3662
	inc b                       ; 3664
.l_3665:
	inc l                       ; 3665
	inc e                       ; 3666
	inc c                       ; 3667
	ld a, c                     ; 3668
	cp $24                      ; 3669
	jr nz, .l_3659              ; 366B
	dec b                       ; 366D
	jr nz, .l_3677              ; 366E
	ld a, [$C819]               ; 3670
	set 7, a                    ; 3673
	ldh [rNR44], a              ; 3675
.l_3677:
	ld a, [wSfxChannels]        ; 3677
	ld c, a                     ; 367A
	ld a, [wTrkPan + 4]         ; 367B
	bit 0, c                    ; 367E
	jr z, .l_3685               ; 3680
	ld a, [wTrkPan]             ; 3682
.l_3685:
	ld b, a                     ; 3685
	ld a, [wTrkPan + 5]         ; 3686
	bit 1, c                    ; 3689
	jr z, .l_3690               ; 368B
	ld a, [wTrkPan + 1]         ; 368D
.l_3690:
	or b                        ; 3690
	ld b, a                     ; 3691
	ld a, [wTrkPan + 6]         ; 3692
	bit 4, c                    ; 3695
	jr z, .l_369C               ; 3697
	ld a, [wTrkPan + 2]         ; 3699
.l_369C:
	or b                        ; 369C
	ld b, a                     ; 369D
	ld a, [wTrkPan + 7]         ; 369E
	bit 3, c                    ; 36A1
	jr z, .l_36A8               ; 36A3
	ld a, [wTrkPan + 3]         ; 36A5
.l_36A8:
	or b                        ; 36A8
	ldh [rNR51], a              ; 36A9
	ret                         ; 36AB


; Track_Main: b = track, de = stream pointer. Counts wTrkWait down; at 0 reads bytes until
; a note, rest or hold sets a new wait.
Track_Main:
	ld h, HIGH(wSoundRAM)       ; 36AC
	ld a, LOW(wTrkWait)         ; 36AE
	add a, b                    ; 36B0
	ld l, a                     ; 36B1
	dec [hl]                    ; 36B2
	jr z, Track_MainRead        ; 36B3
	ret                         ; 36B5

Track_MainNextByte:
	inc de                      ; 36B6
Track_MainRead:
	ld h, HIGH(wSoundRAM)       ; 36B7
	ld a, [de]                  ; 36B9
	ld c, a                     ; 36BA
	and $E0                     ; 36BB
	cp $E0                      ; 36BD
	jp z, Track_Command         ; 36BF
	ld a, LOW(wTrkHwOffset)     ; 36C2
	add a, b                    ; 36C4
	ld l, a                     ; 36C5
	ld a, [hl]                  ; 36C6
	cp $0F                      ; 36C7
	jr nz, .l_36E9              ; 36C9
	bit 4, c                    ; 36CB
	jp nz, Track_NoteOn         ; 36CD
	ld a, c                     ; 36D0
	and $0F                     ; 36D1
	cp $0F                      ; 36D3
	jr z, Track_Rest            ; 36D5
	add a, LOW(NoiseTable)      ; 36D7
	ld l, a                     ; 36D9
	ld h, HIGH(NoiseTable)      ; 36DA
	jr nc, .l_36DF              ; 36DC
	inc h                       ; 36DE
.l_36DF:
	ld c, [hl]                  ; 36DF
	ld a, $12                   ; 36E0
	call Track_RegAddrAbs       ; 36E2
	ld [hl], c                  ; 36E5
	jp Track_NoteOn             ; 36E6

.l_36E9:
	ld a, c                     ; 36E9
	and $1F                     ; 36EA
	cp $10                      ; 36EC
	jr z, Track_Rest            ; 36EE
	bit 4, a                    ; 36F0
	jr z, .l_36F6               ; 36F2
	or $E0                      ; 36F4
.l_36F6:
	ld c, a                     ; 36F6
	ld a, LOW(wTrkBaseNote)     ; 36F7
	add a, b                    ; 36F9
	ld l, a                     ; 36FA
	ld a, [hl]                  ; 36FB
	add a, c                    ; 36FC
	push de                     ; 36FD
	call Track_SetNote          ; 36FE
	pop de                      ; 3701
	jp Track_NoteOn             ; 3702

Track_Rest:
	call Track_ReadLength       ; 3705
	ld c, a                     ; 3708
	ld h, HIGH(wSoundRAM)       ; 3709
	ld a, LOW(wTrkRelease)      ; 370B
	add a, b                    ; 370D
	ld l, a                     ; 370E
	ld a, [hl]                  ; 370F
	and a                       ; 3710
	jr z, Track_NoteDone        ; 3711
	ld [hl], $01                ; 3713
Track_NoteDone:
	ld a, c                     ; 3715
	and a                       ; 3716
	jp z, Track_MainNextByte    ; 3717
	inc de                      ; 371A
	ret                         ; 371B


; note: wait = length; release counter = $FF or length*gate/256; start the instrument envelope.
Track_NoteOn:
	call Track_ReadLength       ; 371C
	ld c, a                     ; 371F
	ld h, HIGH(wSoundRAM)       ; 3720
	ld a, LOW(wTrkRelease)      ; 3722
	add a, b                    ; 3724
	ld l, a                     ; 3725
	ld [hl], $FF                ; 3726
	add a, LOW(wTrkGate - wTrkRelease); 3728
	ld l, a                     ; 372A
	ld a, [hl]                  ; 372B
	and a                       ; 372C
	jr z, .l_3741               ; 372D
	push bc                     ; 372F
	push de                     ; 3730
	ld e, a                     ; 3731
	ld h, HIGH(wSoundRAM)       ; 3732
	ld a, LOW(wTrkRelease)      ; 3734
	add a, b                    ; 3736
	ld l, a                     ; 3737
	push hl                     ; 3738
	ld b, e                     ; 3739
	call Multiply_BxE           ; 373A
	pop hl                      ; 373D
	ld [hl], b                  ; 373E
	pop de                      ; 373F
	pop bc                      ; 3740
.l_3741:
	push bc                     ; 3741
	call Track_StartEnvelope    ; 3742
	pop bc                      ; 3745
	jp Track_NoteDone           ; 3746


; point the envelope stream at the instrument's attack envelope (unless STATIC).
Track_StartEnvelope:
	ld h, HIGH(wSoundRAM)       ; 3749
	ld a, LOW(wTrkInstrument)   ; 374B
	add a, b                    ; 374D
	ld l, a                     ; 374E
	ld a, [hl]                  ; 374F
	bit 7, a                    ; 3750
	jr nz, Track_LoadEnvelopeA.l_3785; 3752
Track_LoadEnvelope:
	add a, a                    ; 3754
	add a, a                    ; 3755
Track_LoadEnvelopeA:
	push de                     ; 3756
	add a, LOW(InstrumentTable) ; 3757
	ld e, a                     ; 3759
	ld d, HIGH(InstrumentTable) ; 375A
	jr nc, .l_375F              ; 375C
	inc d                       ; 375E
.l_375F:
	ld h, HIGH(wSoundRAM)       ; 375F
	ld a, LOW(wTrkEnvPtrLo)     ; 3761
	add a, b                    ; 3763
	ld l, a                     ; 3764
	ld a, [de]                  ; 3765
	ld [hl], a                  ; 3766
	ld a, LOW(wTrkEnvPtrHi)     ; 3767
	add a, b                    ; 3769
	ld l, a                     ; 376A
	inc de                      ; 376B
	ld a, [de]                  ; 376C
	ld [hl], a                  ; 376D
	ld h, HIGH(EnvStackTable)   ; 376E
	ld a, LOW(EnvStackTable)    ; 3770
	add a, b                    ; 3772
	ld l, a                     ; 3773
	jr nc, .l_3777              ; 3774
	inc h                       ; 3776
.l_3777:
	ld c, [hl]                  ; 3777
	ld h, HIGH(wSoundRAM)       ; 3778
	ld a, LOW(wTrkEnvStack)     ; 377A
	add a, b                    ; 377C
	ld l, a                     ; 377D
	ld [hl], c                  ; 377E
	add a, LOW(wTrkEnvWait - wTrkEnvStack); 377F
	ld l, a                     ; 3781
	ld [hl], $01                ; 3782
	pop de                      ; 3784
.l_3785:
	ret                         ; 3785


; length: LLL = 6 -> next byte, else LengthSets[wTrkLengthSet + LLL].
Track_ReadLength:
	ld a, [de]                  ; 3786
	and $E0                     ; 3787
	cp $C0                      ; 3789
	jr nz, .l_3791              ; 378B
	inc de                      ; 378D
	ld a, [de]                  ; 378E
	jr .l_37A8                  ; 378F

.l_3791:
	ld h, HIGH(wSoundRAM)       ; 3791
	ld a, LOW(wTrkLengthSet)    ; 3793
	add a, b                    ; 3795
	ld l, a                     ; 3796
	ld a, [de]                  ; 3797
	and $E0                     ; 3798
	swap a                      ; 379A
	srl a                       ; 379C
	add a, [hl]                 ; 379E
	add a, LOW(LengthSets)      ; 379F
	ld l, a                     ; 37A1
	ld a, $00                   ; 37A2
	adc a, HIGH(LengthSets)     ; 37A4
	ld h, a                     ; 37A6
	ld a, [hl]                  ; 37A7
.l_37A8:
	ld c, a                     ; 37A8
	ld h, HIGH(wSoundRAM)       ; 37A9
	ld a, LOW(wTrkWait)         ; 37AB
	add a, b                    ; 37AD
	ld l, a                     ; 37AE
	ld a, c                     ; 37AF
	ld [hl], a                  ; 37B0
	ret                         ; 37B1


; $E0-$FF commands. Unlisted values fall through to the flow-control handler, which ignores
; them: the same byte is then read again forever.
Track_Command:
	ld a, c                     ; 37B2
	cp $F0                      ; 37B3
	jr nz, .l_37CF              ; 37B5
	inc de                      ; 37B7
	ld h, HIGH(wSoundRAM)       ; 37B8
	ld a, LOW(wTrkVolume)       ; 37BA
	add a, b                    ; 37BC
	ld l, a                     ; 37BD
	ld a, [de]                  ; 37BE
.l_37BF:
	swap a                      ; 37BF
	and $F0                     ; 37C1
	ld c, a                     ; 37C3
	ld a, [hl]                  ; 37C4
	and $0F                     ; 37C5
	or c                        ; 37C7
	ld [hl], a                  ; 37C8
	call Track_ApplyVolume      ; 37C9
	jp Track_MainNextByte       ; 37CC

.l_37CF:
	cp $F1                      ; 37CF
	jr nz, .l_37F3              ; 37D1
	inc de                      ; 37D3
	ld a, [de]                  ; 37D4
	ld c, a                     ; 37D5
	ld h, HIGH(wSoundRAM)       ; 37D6
	ld a, LOW(wTrkVolume)       ; 37D8
	add a, b                    ; 37DA
	ld l, a                     ; 37DB
	ld a, [hl]                  ; 37DC
	swap a                      ; 37DD
	and $0F                     ; 37DF
	add a, c                    ; 37E1
	bit 7, c                    ; 37E2
	jr nz, .l_37EE              ; 37E4
	cp $10                      ; 37E6
	jr c, .l_37F1               ; 37E8
	ld a, $0F                   ; 37EA
	jr .l_37F1                  ; 37EC

.l_37EE:
	jr c, .l_37F1               ; 37EE
	xor a                       ; 37F0
.l_37F1:
	jr .l_37BF                  ; 37F1

.l_37F3:
	cp $F2                      ; 37F3
	jr nz, .l_3808              ; 37F5
	inc de                      ; 37F7
	ld a, [de]                  ; 37F8
	add a, a                    ; 37F9
	ld c, a                     ; 37FA
	add a, a                    ; 37FB
	add a, c                    ; 37FC
	ld hl, wTrkLengthSet        ; 37FD
.l_3800:
	ld c, a                     ; 3800
	ld a, l                     ; 3801
	add a, b                    ; 3802
	ld l, a                     ; 3803
	ld [hl], c                  ; 3804
	jp Track_MainNextByte       ; 3805

.l_3808:
	cp $F3                      ; 3808
	jr nz, .l_381D              ; 380A
	inc de                      ; 380C
	ld h, HIGH(wSoundRAM)       ; 380D
	ld a, LOW(wTrkWait)         ; 380F
	add a, b                    ; 3811
	ld l, a                     ; 3812
	ld a, [de]                  ; 3813
	ld [hl], a                  ; 3814
	ld a, LOW(wTrkRelease)      ; 3815
	add a, b                    ; 3817
	ld l, a                     ; 3818
	ld [hl], $FF                ; 3819
	inc de                      ; 381B
	ret                         ; 381C

.l_381D:
	cp $F4                      ; 381D
	jr nz, .l_3829              ; 381F
	inc de                      ; 3821
	ld a, [de]                  ; 3822
	ld hl, wTrkGate             ; 3823
	jp .l_3800                  ; 3826

.l_3829:
	cp $F5                      ; 3829
	jr nz, Cmd_BaseNote.l_3850  ; 382B

; $F5: SFX tracks (0-3) add wSfxTranspose[channel] to the argument (game-set pitch offset).
Cmd_BaseNote:
	inc de                      ; 382D
	ld a, [de]                  ; 382E
	ld c, a                     ; 382F
	ld a, b                     ; 3830
	cp $04                      ; 3831
	jr nc, .l_3849              ; 3833
	ld a, LOW(wTrkHwOffset)     ; 3835
	add a, b                    ; 3837
	ld l, a                     ; 3838
	ld h, HIGH(wSoundRAM)       ; 3839
	ld a, [hl]                  ; 383B
	rrca                        ; 383C
	rrca                        ; 383D
	and $03                     ; 383E
	add a, LOW(wSfxTranspose)   ; 3840
	ld l, a                     ; 3842
	ld h, HIGH(wSfxTranspose)   ; 3843
	ld a, [hl]                  ; 3845
	add a, c                    ; 3846
	jr .l_384A                  ; 3847

.l_3849:
	ld a, c                     ; 3849
.l_384A:
	ld hl, wTrkBaseNote         ; 384A
	jp Track_Command.l_3800     ; 384D

.l_3850:
	cp $F6                      ; 3850
	jr nz, .l_3865              ; 3852
	inc de                      ; 3854
	ld h, HIGH(wSoundRAM)       ; 3855
	ld a, LOW(wTrkInstrument)   ; 3857
	add a, b                    ; 3859
	ld l, a                     ; 385A
	ld a, [de]                  ; 385B
	ld [hl], a                  ; 385C
	bit 7, a                    ; 385D
	call nz, Track_LoadEnvelope ; 385F
	jp Track_MainNextByte       ; 3862

.l_3865:
	cp $F7                      ; 3865
	jr nz, .l_3871              ; 3867
	inc de                      ; 3869
	ld a, [de]                  ; 386A
	ld hl, wTrkTuning           ; 386B
	jp Track_Command.l_3800     ; 386E

.l_3871:
	cp $E2                      ; 3871
	jr nz, .l_3887              ; 3873
	inc de                      ; 3875
	ld a, [de]                  ; 3876
	ld c, a                     ; 3877
	inc de                      ; 3878
	ld a, [de]                  ; 3879
	push de                     ; 387A
	ld d, a                     ; 387B
	ld e, c                     ; 387C
	call Track_SetPeriod        ; 387D
	call Track_StartEnvelope    ; 3880
	pop de                      ; 3883
	jp Track_MainNextByte       ; 3884

.l_3887:
	cp $E3                      ; 3887
	jr nz, .l_389E              ; 3889
	inc de                      ; 388B
	ld a, [de]                  ; 388C
	push de                     ; 388D
	cpl                         ; 388E
	inc a                       ; 388F
	ld e, a                     ; 3890
	ld d, $00                   ; 3891
	rla                         ; 3893
	jr nc, .l_3897              ; 3894
	dec d                       ; 3896
.l_3897:
	call Track_AddPeriod        ; 3897
	pop de                      ; 389A
	jp Track_MainNextByte       ; 389B

.l_389E:
	cp $FE                      ; 389E
	jr nz, .l_38D8              ; 38A0
	inc de                      ; 38A2
	ld a, [de]                  ; 38A3
	ld c, a                     ; 38A4
	push de                     ; 38A5
	ld h, HIGH(wSoundRAM)       ; 38A6
	ld a, LOW(wTrkHwOffset)     ; 38A8
	add a, b                    ; 38AA
	ld l, a                     ; 38AB
	ld e, [hl]                  ; 38AC
	srl e                       ; 38AD
	srl e                       ; 38AF
	ld d, $00                   ; 38B1
	ld hl, wTrkPan              ; 38B3
	add hl, de                  ; 38B6
	ld a, c                     ; 38B7
	rra                         ; 38B8
	jr nc, .l_38BD              ; 38B9
	set 4, d                    ; 38BB
.l_38BD:
	rra                         ; 38BD
	jr nc, .l_38C1              ; 38BE
	inc d                       ; 38C0
.l_38C1:
	inc e                       ; 38C1
	dec e                       ; 38C2
	jr z, .l_38CA               ; 38C3
.l_38C5:
	rlc d                       ; 38C5
	dec e                       ; 38C7
	jr nz, .l_38C5              ; 38C8
.l_38CA:
	ld a, b                     ; 38CA
	cp $04                      ; 38CB
	jr c, .l_38D3               ; 38CD
	inc l                       ; 38CF
	inc l                       ; 38D0
	inc l                       ; 38D1
	inc l                       ; 38D2
.l_38D3:
	ld [hl], d                  ; 38D3
	pop de                      ; 38D4
	jp Track_MainNextByte       ; 38D5

.l_38D8:
	cp $E1                      ; 38D8
	jr nz, .l_38E4              ; 38DA
	inc de                      ; 38DC
	ld a, [de]                  ; 38DD
	ld [wSoundSync], a          ; 38DE
	jp Track_MainNextByte       ; 38E1

.l_38E4:
	cp $FF                      ; 38E4
	jr nz, .l_38F8              ; 38E6
	ld h, HIGH(wSoundRAM)       ; 38E8
	ld a, LOW(wTrkWait)         ; 38EA
	add a, b                    ; 38EC
	ld l, a                     ; 38ED
	ld [hl], $00                ; 38EE
	add a, LOW(wTrkEnvWait - wTrkWait); 38F0
	ld l, a                     ; 38F2
	xor a                       ; 38F3
	ld [hl], a                  ; 38F4
	jp Track_SetVolume          ; 38F5

.l_38F8:
	ld hl, wTrkStack            ; 38F8
	call Track_Flow             ; 38FB
	jp Track_MainRead           ; 38FE


; flow control for the main stream: stack pointer = wSoundStacks + wTrkStack[b].
Track_Flow:
	ld a, l                     ; 3901
	add a, b                    ; 3902
	ld l, a                     ; 3903
	push hl                     ; 3904
	ld a, LOW(wSoundStacks)     ; 3905
	add a, [hl]                 ; 3907
	ld l, a                     ; 3908
	ld a, HIGH(wSoundStacks)    ; 3909
	adc a, $00                  ; 390B
	ld h, a                     ; 390D
	call Stream_Flow            ; 390E
	ld a, l                     ; 3911
	sub LOW(wSoundStacks)       ; 3912
	pop hl                      ; 3914
	ld [hl], a                  ; 3915
	ret                         ; 3916


; $F8 jump, $FA call (push return), $FB return, $FC loop start (push count+address),
; $FD loop end (count down, jump back or pop). hl = stack pointer, de = stream.
Stream_Flow:
	ld a, [de]                  ; 3917
	cp $F8                      ; 3918
	jr nz, .l_3924              ; 391A
	inc de                      ; 391C
	ld a, [de]                  ; 391D
	ld c, a                     ; 391E
	inc de                      ; 391F
	ld a, [de]                  ; 3920
	ld d, a                     ; 3921
	ld e, c                     ; 3922
	ret                         ; 3923

.l_3924:
	cp $FA                      ; 3924
	jr nz, .l_3937              ; 3926
	inc de                      ; 3928
	inc de                      ; 3929
	inc de                      ; 392A
	dec hl                      ; 392B
	ld [hl], d                  ; 392C
	dec hl                      ; 392D
	ld [hl], e                  ; 392E
	dec de                      ; 392F
	ld a, [de]                  ; 3930
	ld c, a                     ; 3931
	dec de                      ; 3932
	ld a, [de]                  ; 3933
	ld e, a                     ; 3934
	ld d, c                     ; 3935
	ret                         ; 3936

.l_3937:
	cp $FB                      ; 3937
	jr nz, .l_3940              ; 3939
	ld e, [hl]                  ; 393B
	inc hl                      ; 393C
	ld d, [hl]                  ; 393D
	inc hl                      ; 393E
	ret                         ; 393F

.l_3940:
	cp $FC                      ; 3940
	jr nz, .l_394F              ; 3942
	inc de                      ; 3944
	ld a, [de]                  ; 3945
	ld c, a                     ; 3946
	inc de                      ; 3947
	dec hl                      ; 3948
	ld [hl], d                  ; 3949
	dec hl                      ; 394A
	ld [hl], e                  ; 394B
	dec hl                      ; 394C
	ld [hl], c                  ; 394D
	ret                         ; 394E

.l_394F:
	cp $FD                      ; 394F
	jr nz, .l_3961              ; 3951
	dec [hl]                    ; 3953
	jr z, .l_395D               ; 3954
	inc hl                      ; 3956
	ld e, [hl]                  ; 3957
	inc hl                      ; 3958
	ld d, [hl]                  ; 3959
	dec hl                      ; 395A
	dec hl                      ; 395B
	ret                         ; 395C

.l_395D:
	inc hl                      ; 395D
	inc hl                      ; 395E
	inc hl                      ; 395F
	inc de                      ; 3960
.l_3961:
	ret                         ; 3961


; a = note index -> period from the tuning table (big-endian words; index*2 via rlc).
Track_SetNote:
	ld e, a                     ; 3962
	ld a, LOW(wTrkTuning)       ; 3963
	add a, b                    ; 3965
	ld l, a                     ; 3966
	ld a, [hl]                  ; 3967
	add a, a                    ; 3968
	add a, LOW(TuningTable)     ; 3969
	ld l, a                     ; 396B
	ld a, $00                   ; 396C
	adc a, HIGH(TuningTable)    ; 396E
	ld h, a                     ; 3970
	ld a, [hli]                 ; 3971
	rlc e                       ; 3972
	add a, e                    ; 3974
	ld e, a                     ; 3975
	ld a, [hl]                  ; 3976
	adc a, $00                  ; 3977
	ld h, a                     ; 3979
	ld l, e                     ; 397A
	ld a, [hli]                 ; 397B
	ld d, a                     ; 397C
	ld e, [hl]                  ; 397D

; de = period -> image NRx3/NRx4 (ch3: also NR30 = $80).
Track_SetPeriod:
	ld h, HIGH(wSoundRAM)       ; 397E
	ld a, LOW(wTrkHwOffset)     ; 3980
	add a, b                    ; 3982
	ld l, a                     ; 3983
	ld a, [hl]                  ; 3984
	cp $0A                      ; 3985
	jr z, .l_3990               ; 3987
	ld a, $03                   ; 3989
	call Track_RegAddrA         ; 398B
	jr .l_399A                  ; 398E

.l_3990:
	ld a, $00                   ; 3990
	call Track_RegAddrA         ; 3992
	ld [hl], $80                ; 3995
	inc l                       ; 3997
	inc l                       ; 3998
	inc l                       ; 3999
.l_399A:
	ld a, e                     ; 399A
	ld [hli], a                 ; 399B
	ld [hl], d                  ; 399C
	ret                         ; 399D


; release counter: when it reaches 0, switch the envelope to the instrument's release envelope.
Track_Release:
	ld h, HIGH(wSoundRAM)       ; 399E
	ld a, LOW(wTrkRelease)      ; 39A0
	add a, b                    ; 39A2
	ld l, a                     ; 39A3
	ld a, [hl]                  ; 39A4
	and a                       ; 39A5
	ret z                       ; 39A6
	cp $FF                      ; 39A7
	ret z                       ; 39A9
	dec [hl]                    ; 39AA
	ret nz                      ; 39AB
	ld a, LOW(wTrkInstrument)   ; 39AC
	add a, b                    ; 39AE
	ld l, a                     ; 39AF
	ld a, [hl]                  ; 39B0
	add a, a                    ; 39B1
	add a, a                    ; 39B2
	add a, $02                  ; 39B3
	jp Track_LoadEnvelopeA      ; 39B5


; Track_Env: envelope (instrument macro) stream, own wait counter and stack.
Track_Env:
	ld h, HIGH(wSoundRAM)       ; 39B8
	ld a, LOW(wTrkEnvWait)      ; 39BA
	add a, b                    ; 39BC
	ld l, a                     ; 39BD
	dec [hl]                    ; 39BE
	jr z, Track_EnvRead         ; 39BF
	ret                         ; 39C1

Track_EnvNextByte:
	inc de                      ; 39C2
Track_EnvRead:
	ld h, HIGH(wSoundRAM)       ; 39C3
	ld a, [de]                  ; 39C5
	ld c, a                     ; 39C6
	and $E0                     ; 39C7
	jr nz, .l_39D6              ; 39C9
	ld a, c                     ; 39CB
	and $1F                     ; 39CC
	ld c, a                     ; 39CE
	ld a, LOW(wTrkEnvWait)      ; 39CF
	add a, b                    ; 39D1
	ld l, a                     ; 39D2
	ld [hl], c                  ; 39D3
	inc de                      ; 39D4
	ret                         ; 39D5

.l_39D6:
	cp $20                      ; 39D6
	jr nz, Track_EnvWaitFlag.l_39F3; 39D8
	push bc                     ; 39DA
	push de                     ; 39DB
	call SignExtendNibble       ; 39DC
	call Track_AddPeriod        ; 39DF
	pop de                      ; 39E2
	pop bc                      ; 39E3
Track_EnvWaitFlag:
	ld a, [de]                  ; 39E4
	and $10                     ; 39E5
	jr z, Track_EnvNextByte     ; 39E7
	ld h, HIGH(wSoundRAM)       ; 39E9
	ld a, LOW(wTrkEnvWait)      ; 39EB
	add a, b                    ; 39ED
	ld l, a                     ; 39EE
	ld [hl], $01                ; 39EF
	inc de                      ; 39F1
	ret                         ; 39F2

.l_39F3:
	cp $40                      ; 39F3
	jr nz, .l_39FD              ; 39F5
	ld a, c                     ; 39F7
	and $0F                     ; 39F8
	jp .l_3A1B                  ; 39FA

.l_39FD:
	cp $60                      ; 39FD
	jr nz, .l_3A23              ; 39FF
	push de                     ; 3A01
	call SignExtendNibble       ; 3A02
	ld h, HIGH(wSoundRAM)       ; 3A05
	ld a, LOW(wTrkVolume)       ; 3A07
	add a, b                    ; 3A09
	ld l, a                     ; 3A0A
	ld a, [hl]                  ; 3A0B
	and $0F                     ; 3A0C
	add a, e                    ; 3A0E
	bit 7, a                    ; 3A0F
	jr z, .l_3A14               ; 3A11
	xor a                       ; 3A13
.l_3A14:
	cp $10                      ; 3A14
	jr c, .l_3A1A               ; 3A16
	ld a, $0F                   ; 3A18
.l_3A1A:
	pop de                      ; 3A1A
.l_3A1B:
	push de                     ; 3A1B
	call Track_SetVolume        ; 3A1C
	pop de                      ; 3A1F
	jp Track_EnvWaitFlag        ; 3A20

.l_3A23:
	cp $80                      ; 3A23
	jr nz, LoadWave.l_3A7A      ; 3A25
	ld h, HIGH(wSoundRAM)       ; 3A27
	ld a, LOW(wTrkHwOffset)     ; 3A29
	add a, b                    ; 3A2B
	ld l, a                     ; 3A2C
	ld a, [hl]                  ; 3A2D
	cp $0A                      ; 3A2E
	jr z, .l_3A45               ; 3A30
	ld a, $01                   ; 3A32
	call Track_RegAddrA         ; 3A34
	ld a, c                     ; 3A37
	rrca                        ; 3A38
	rrca                        ; 3A39
	and $C0                     ; 3A3A
	ld c, a                     ; 3A3C
	ld a, [hl]                  ; 3A3D
	and $3F                     ; 3A3E
	or c                        ; 3A40
	ld [hl], a                  ; 3A41
	jp Track_EnvWaitFlag        ; 3A42

.l_3A45:
	ld a, c                     ; 3A45
	and $0F                     ; 3A46
	ld hl, wCurWave             ; 3A48
	cp [hl]                     ; 3A4B
	jr z, .l_3A6B               ; 3A4C
	push de                     ; 3A4E
	ld [hl], a                  ; 3A4F
	swap a                      ; 3A50
	ld e, a                     ; 3A52
	ld d, $00                   ; 3A53
	ld hl, Wave0                ; 3A55
	add hl, de                  ; 3A58
	xor a                       ; 3A59
	ldh [rNR30], a              ; 3A5A
	call LoadWave               ; 3A5C
	ld a, $80                   ; 3A5F
	ldh [rNR30], a              ; 3A61
	ld a, [$C814]               ; 3A63
	set 7, a                    ; 3A66
	ldh [rNR34], a              ; 3A68
	pop de                      ; 3A6A
.l_3A6B:
	jp Track_EnvWaitFlag        ; 3A6B


; copy 16 bytes from hl to wave RAM.
LoadWave:
	ld de, _AUD3WAVERAM         ; 3A6E
	ld c, $10                   ; 3A71
.l_3A73:
	ld a, [hli]                 ; 3A73
	ld [de], a                  ; 3A74
	inc de                      ; 3A75
	dec c                       ; 3A76
	jr nz, .l_3A73              ; 3A77
	ret                         ; 3A79

.l_3A7A:
	cp $E0                      ; 3A7A
	jr nz, .l_3AA3              ; 3A7C
	ld a, c                     ; 3A7E
	cp $F0                      ; 3A7F
	jr nz, .l_3A8F              ; 3A81
	inc de                      ; 3A83
	ld a, [de]                  ; 3A84
	ld c, a                     ; 3A85
	ld a, $00                   ; 3A86
	call Track_RegAddr          ; 3A88
	ld [hl], c                  ; 3A8B
	jp Track_EnvNextByte        ; 3A8C

.l_3A8F:
	cp $FF                      ; 3A8F
	jr nz, .l_3A9A              ; 3A91
	ld a, LOW(wTrkEnvWait)      ; 3A93
	add a, b                    ; 3A95
	ld l, a                     ; 3A96
	ld [hl], $00                ; 3A97
	ret                         ; 3A99

.l_3A9A:
	ld hl, wTrkEnvStack         ; 3A9A
	call Track_Flow             ; 3A9D
	jp Track_EnvRead            ; 3AA0

.l_3AA3:
	ret                         ; 3AA3


; a = envelope volume (low nibble of wTrkVolume); falls into Track_ApplyVolume.
Track_SetVolume:
	ld c, a                     ; 3AA4
	ld h, HIGH(wSoundRAM)       ; 3AA5
	ld a, LOW(wTrkVolume)       ; 3AA7
	add a, b                    ; 3AA9
	ld l, a                     ; 3AAA
	ld a, [hl]                  ; 3AAB
	and $F0                     ; 3AAC
	or c                        ; 3AAE
	ld [hl], a                  ; 3AAF

; output volume = env volume - (15 - channel volume) - (15 - master), clamped at 0;
; NRx2 high nibble, or NR32 through Ch3VolumeTable.
Track_ApplyVolume:
	push de                     ; 3AB0
	ld a, $FF                   ; 3AB1
	sub [hl]                    ; 3AB3
	swap a                      ; 3AB4
	and $0F                     ; 3AB6
	ld e, a                     ; 3AB8
	ld a, [hl]                  ; 3AB9
	and $0F                     ; 3ABA
	sub e                       ; 3ABC
	ld e, a                     ; 3ABD
	jr nc, .l_3AC2              ; 3ABE
	ld e, $00                   ; 3AC0
.l_3AC2:
	push hl                     ; 3AC2
	ld hl, wSfxAttenuation      ; 3AC3
	ld a, b                     ; 3AC6
	cp $04                      ; 3AC7
	jr c, .l_3ACC               ; 3AC9
	inc l                       ; 3ACB
.l_3ACC:
	ld a, $FF                   ; 3ACC
	sub [hl]                    ; 3ACE
	swap a                      ; 3ACF
	and $0F                     ; 3AD1
	ld d, a                     ; 3AD3
	pop hl                      ; 3AD4
	ld a, e                     ; 3AD5
	sub d                       ; 3AD6
	jr nc, .l_3ADA              ; 3AD7
	xor a                       ; 3AD9
.l_3ADA:
	ld e, a                     ; 3ADA
	ld a, LOW(wTrkHwOffset)     ; 3ADB
	add a, b                    ; 3ADD
	ld l, a                     ; 3ADE
	ld a, [hl]                  ; 3ADF
	cp $0A                      ; 3AE0
	jr z, .l_3AF2               ; 3AE2
	ld a, $02                   ; 3AE4
	call Track_RegAddrA         ; 3AE6
	swap e                      ; 3AE9
	ld a, [hl]                  ; 3AEB
	and $0F                     ; 3AEC
	or e                        ; 3AEE
	ld [hl], a                  ; 3AEF
	pop de                      ; 3AF0
	ret                         ; 3AF1

.l_3AF2:
	srl e                       ; 3AF2
	srl e                       ; 3AF4
	ld d, $00                   ; 3AF6
	ld hl, Ch3VolumeTable       ; 3AF8
	add hl, de                  ; 3AFB
	ld e, [hl]                  ; 3AFC
	ld a, $02                   ; 3AFD
	call Track_RegAddr          ; 3AFF
	ld [hl], e                  ; 3B02
	pop de                      ; 3B03
	ret                         ; 3B04

Ch3VolumeTable:
	db $00, $60, $40, $20
SignExtendNibble:
	ld a, c                     ; 3B09
	and $0F                     ; 3B0A
	ld d, $00                   ; 3B0C
	bit 3, a                    ; 3B0E
	jr z, .l_3B15               ; 3B10
	or $F0                      ; 3B12
	dec d                       ; 3B14
.l_3B15:
	ld e, a                     ; 3B15
	ret                         ; 3B16

Track_AddPeriod:
	ld a, $03                   ; 3B17
	call Track_RegAddr          ; 3B19
	ld a, e                     ; 3B1C
	add a, [hl]                 ; 3B1D
	ld [hli], a                 ; 3B1E
	ld a, d                     ; 3B1F
	adc a, [hl]                 ; 3B20
	ld [hl], a                  ; 3B21
	ret                         ; 3B22

Track_RegAddr:
	push af                     ; 3B23
	ld h, HIGH(wSoundRAM)       ; 3B24
	ld a, LOW(wTrkHwOffset)     ; 3B26
	add a, b                    ; 3B28
	ld l, a                     ; 3B29
	pop af                      ; 3B2A
Track_RegAddrA:
	add a, [hl]                 ; 3B2B
Track_RegAddrAbs:
	ld hl, hRegImage            ; 3B2C
	add a, [hl]                 ; 3B2F
	ld l, a                     ; 3B30
	ld h, HIGH(wSoundRAM)       ; 3B31
	ret                         ; 3B33

PeriodTable:
	dwbe $003B  ; C2
	dwbe $00AA
	dwbe $0112
	dwbe $0175
	dwbe $01D3
	dwbe $022B
	dwbe $027E
	dwbe $02CD
	dwbe $0317
	dwbe $035D
	dwbe $03A0
	dwbe $03DE
	dwbe $0419  ; C3
	dwbe $0451
	dwbe $0486
	dwbe $04B8
	dwbe $04E7
	dwbe $0513
	dwbe $053D
	dwbe $0564
	dwbe $058A
	dwbe $05AD
	dwbe $05CE
	dwbe $05EE
	dwbe $060B  ; C4
	dwbe $0627
	dwbe $0642
	dwbe $065B
	dwbe $0672
	dwbe $0689
	dwbe $069E
	dwbe $06B2
	dwbe $06C4
	dwbe $06D6
	dwbe $06E7
	dwbe $06F6
	dwbe $0705  ; C5
	dwbe $0713
	dwbe $0721
	dwbe $072D
	dwbe $0739
	dwbe $0744
	dwbe $074E
	dwbe $0758
	dwbe $0762
	dwbe $076B
	dwbe $0773
	dwbe $077B
	dwbe $0782  ; C6
	dwbe $0789
	dwbe $0790
	dwbe $0796
	dwbe $079C
	dwbe $07A2
	dwbe $07A7
	dwbe $07AC
	dwbe $07B1
	dwbe $07B5
	dwbe $07B9
	dwbe $07BD
	dwbe $07C1  ; C7
	dwbe $07C4
	dwbe $07C8
	dwbe $07CB
	dwbe $07CE
	dwbe $07D1
	dwbe $07D3
	dwbe $07D6
	dwbe $07D8
	dwbe $07DA
	dwbe $07DC
	dwbe $07DE
UnusedImageBaseTable:
	db $1A, $1A, $1A, $1A, $2E, $2E, $2E, $2E
TrackStackTable:
	db $10, $20, $30, $40, $50, $60, $70, $80
EnvStackTable:
	db $06, $16, $26, $36, $46, $56, $66, $76
TuningTable:
	dw PeriodTable - 6  ; tuning 0: entry 3 of this table is PeriodTable
NoiseTable:
	db $00, $10, $20, $30, $07, $23, $50, $33, $60, $43, $70, $45, $47, $55, $65
InitialWave:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

; b = b*e/256 (shift-and-add), used for the gate release time.
Multiply_BxE:
	push hl                     ; 3BFD
	push de                     ; 3BFE
	ld a, b                     ; 3BFF
	ld hl, $0000                ; 3C00
	ld b, h                     ; 3C03
	ld e, $08                   ; 3C04
.l_3C06:
	rlca                        ; 3C06
	jr nc, .l_3C0A              ; 3C07
	add hl, bc                  ; 3C09
.l_3C0A:
	add hl, hl                  ; 3C0A
	dec e                       ; 3C0B
	jr nz, .l_3C06              ; 3C0C
	rr h                        ; 3C0E
	rr l                        ; 3C10
	ld b, h                     ; 3C12
	ld c, l                     ; 3C13
	pop de                      ; 3C14
	pop hl                      ; 3C15
	ret                         ; 3C16

