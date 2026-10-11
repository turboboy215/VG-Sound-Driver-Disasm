; Super Mario Land 2 sound driver: init, update, SFX code and data, bank 4 $4000-$5243

; Called once at boot. The game also calls $4003, inside the first clear loop: that
; clears from whatever hl holds to the end of its page, then $A500-$A5FF, and resets NR50-NR52.
Sound_Init:
	ld hl, wTranspose
.clearA4:
	ld [hl], $00
	inc l
	jr nz, .clearA4
	ld hl, wSfx1Timer
.clearA5:
	ld [hl], $00
	inc l
	jr nz, .clearA5
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	ret

; unreferenced
Unused_401D:
	db $2a, $20, $82, $aa, $ea, $aa, $ba, $3a, $22, $7e, $60, $a0, $21, $a2, $68, $02
; Stop entry: the stop routine itself sits after the song data, at $7F5E.
Sound_StopStub:
	jp Sound_Stop

; Called once per frame. Order: pause request (1 pause, 2 resume) -> pause jingle ->
; song request -> SFX ch1 -> SFX ch3 -> SFX ch4 -> music, then clear the requests.
; wQuietMusic non-zero sets NR50 = $33 instead of $77.
Sound_Update:
	ld a, [wPauseRequest]
	cp $01
	jp z, Sound_Pause
	cp $02
	jp z, Sound_Unpause
	ld a, [wPaused]
	and a
	jp nz, Sound_Paused
.main:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	jr nz, .startSong
	ld a, [wQuietMusic]
	and a
	jr z, .fullVolume
	ld a, $33
	ldh [rNR50], a
	jr .run

.fullVolume:
	ld a, $77
	ldh [rNR50], a
.run:
	call Sfx1_Update
	call Sfx3_Update
	call Sfx4_Update
.music:
	call Music_Update
.clearRequests:
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wPauseRequest], a
	ret

.startSong:
	ld [hl], a
	call Music_StartSong
	jr .music

; SFX on ch1 (wSfx1Request = 1-24): init routine and per-frame routine
Sfx1_InitTable:
	dw Sfx1_01_Init
	dw Sfx1_02_Init
	dw Sfx1_03_Init
	dw Sfx1_04_Init
	dw Sfx1_05_Init
	dw Sfx1_06_Init
	dw Sfx1_07_Init
	dw Sfx1_08_Init
	dw Sfx1_09_Init
	dw Sfx1_0A_Init
	dw Sfx1_0B_Init
	dw Sfx1_0C_Init
	dw Sfx1_0D_Init
	dw Sfx1_0E_Init
	dw Sfx1_0F_Init
	dw Sfx1_10_Init
	dw Sfx1_11_Init
	dw Sfx1_12_Init
	dw Sfx1_13_Init
	dw Sfx1_14_Init
	dw Sfx1_15_Init
	dw Sfx1_16_Init
	dw Sfx1_17_Init
	dw Sfx1_18_Init
Sfx1_PlayTable:
	dw Sfx1_01_Play
	dw Sfx1_02_Play
	dw Sfx1_03_Play
	dw Sfx1_04_Play
	dw Sfx1_05_Play
	dw Sfx1_06_Play
	dw Sfx1_07_Play
	dw Sfx1_08_Play
	dw Sfx1_09_Play
	dw Sfx1_0A_Play
	dw Sfx1_0B_Play
	dw Sfx1_0C_Play
	dw Sfx1_0D_Play
	dw Sfx1_0E_Play
	dw Sfx1_0F_Play
	dw Sfx1_10_Play
	dw Sfx1_11_Play
	dw Sfx1_12_Play
	dw Sfx1_11_Play
	dw Sfx1_14_Play
	dw Sfx1_15_Play
	dw Sfx1_16_Play
	dw Sfx1_17_Play
	dw Sfx1_18_Play
; Effects 9, 12, 15, 16, 17, 19, 20, 23 always start; the others are refused while a
; priority effect plays (wSfx1Priority), unless wVibrato is non-zero.
Sfx1_Update:
	ld hl, wSfx1Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $09
	jr z, .start
	cp $0c
	jr z, .start
	cp $0f
	jr z, .start
	cp $10
	jr z, .start
	cp $11
	jr z, .start
	cp $13
	jr z, .start
	cp $14
	jr z, .start
	cp $17
	jr z, .start
	ld a, [wVibrato]
	and a
	jr nz, .start
	ld a, [wSfx1Priority]
	and a
	ret nz
.start:
	ld a, [hl]
	ld hl, Sfx1_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx1_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx1Timer
	ld bc, wSfx1Step
	jp hl

Sfx1_01_Init:
	ld hl, Sfx1_01_Data_4134
	jp Sfx1_Start

Sfx1_01_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx1_Stop

Sfx1_01_Data_4134:
	db $37, $40, $d2, $27, $86, $30
Sfx1_02_Init:
	ld hl, Sfx1_02_Data_4152
	jp Sfx1_Start

Sfx1_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_02_Data_4158
	jp SetRegs_Ch1

Sfx1_02_Data_4152:
	db $1e, $a0, $d0, $ac, $c5, $04
Sfx1_02_Data_4158:
	db $14, $ad, $d0, $9b, $c3, $0c
Sfx1_03_Init:
	ld a, [wSfx1Playing]
	cp $03
	ret z
	ld hl, Sfx1_03_Data_417C
	jp Sfx1_Start

Sfx1_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_03_Data_4182
	jp SetRegs_Ch1

Sfx1_03_Data_417C:
	db $27, $a0, $39, $d6, $c6, $06
Sfx1_03_Data_4182:
	db $27, $a0, $39, $16, $c7, $12
Sfx1_04_Init:
	ld a, $05
	ld [wSfx1Counter], a
	ld hl, Sfx1_04_Data_41A3
	jp Sfx1_Start

Sfx1_04_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld hl, Sfx1_04_Data_41A3
	jp SetRegs_Ch1

Sfx1_04_Data_41A3:
	db $17, $bc, $64, $44, $c7, $02
Sfx1_05_Init:
	ld a, $02
	ld [wSfx1Counter], a
	ld hl, Sfx1_05_Data_46C6
	jp Sfx1_StartPriority

Sfx1_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l1:
	ld hl, Sfx1_05_Data_41D3
	call GetPointer
	jp SetRegs_Ch1

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_05_Data_41D3:
	db $db, $41, $e1, $41, $e7, $41
	db $ed, $41, $1d, $af, $c0, $90
	db $c7, $03, $1d, $af, $c0, $90
	db $c7, $04, $1d, $af, $40, $90
	db $c7, $03, $1d, $af, $40, $90
	db $c7, $06
Sfx1_06_Init:
	ld hl, Sfx1_06_Data_420B
	jp Sfx1_Start

Sfx1_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_06_Data_4211
	jp SetRegs_Ch1

Sfx1_06_Data_420B:
	db $00, $ba, $c0, $b6, $c6, $08
Sfx1_06_Data_4211:
	db $00, $ba, $c0, $39, $c7, $02
Sfx1_07_Init:
	ld hl, Sfx1_07_Data_422F
	jp Sfx1_Start

Sfx1_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld hl, Sfx1_07_Data_4235
	jp Sfx1_WritePeriod

Sfx1_07_Data_422F:
	db $00, $80, $a7, $83, $87, $04
Sfx1_07_Data_4235:
	db $9d, $07, $50
Sfx1_08_Init:
	ld hl, Sfx1_08_Data_4259
	jp Sfx1_StartPriority

Sfx1_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_Stop
	ld hl, Sfx1_08_Data_4253
	call GetPointer
	jp SetRegs_Ch1

Sfx1_08_Data_4253:
	dw Sfx1_08_Data_4259+6, Sfx1_08_Data_4259+12, Sfx1_08_Data_4259+18
Sfx1_08_Data_4259:
	db $25, $9f, $80, $32, $c5, $08
	db $25, $9f, $a0, $5a, $c5, $08
	db $25, $9f, $c0, $72, $c5, $08
	db $25, $9f, $e0, $8a, $c5, $08
Sfx1_09_Init:
	ld a, $03
	ld [wSfx1Counter], a
	ld hl, Sfx1_09_Data_42AA
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_09_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $05
	ld [de], a
	call Sfx_IncStep
	cp $07
	jr z, .l0
.l1:
	ld hl, Sfx1_09_Data_429E
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_09_Data_429E:
	db $00, $08
	db $00, $07
	db $00, $09
	db $00, $0d
	db $ff, $f9
	db $ff, $e2
Sfx1_09_Data_42AA:
	db $00, $80, $c7, $b5, $87, $05
Sfx1_0A_Init:
	ret

Sfx1_0A_Play:
	ret

Sfx1_0B_Init:
	ld hl, Sfx1_0B_Data_42D3
	jp Sfx1_Start

Sfx1_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $04
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_0B_Data_42CD
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_0B_Data_42CD:
	dw Sfx1_0B_Data_42D3+6, Sfx1_0B_Data_42D3+9, Sfx1_0B_Data_42D3+12
Sfx1_0B_Data_42D3:
	db $00, $af, $a0, $63, $c5, $01
	db $b2, $c6, $01, $59, $c7, $01
	db $ac, $c7, $02
Sfx1_0C_Init:
	call Sound_Stop
	ld a, $06
	ld [wSfx1Counter], a
	ld hl, Sfx1_0C_Data_4343
	jp Sfx1_StartPriority

Sfx1_0C_Play:
	call Sfx_DecTimer
	ret nz
	ld a, [wSfx3Pitch+1]
	inc a
	ld [wSfx3Pitch+1], a
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx1_0C_Data_433F
	call GetPointer
	ld a, [wSfx3Pitch+1]
	cp $01
	jr z, .l1
	call SetRegs_Ch1
.l3:
	ld bc, wSfx1Step
	call Sfx_IncStep
	dec a
	ld c, a
	ld b, $00
	ld hl, Sfx1_0C_Data_4333
	add hl, bc
	ld a, [hl]
	jp SetRegs_Copy.storeTimer

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [wSfx3Pitch+1], a
	jr .l2

.l1:
	call SetRegs_Ch2
	jr .l3

Sfx1_0C_Data_4333:
	db $04, $04, $05, $05, $07, $07
	db $09, $09, $0b, $0d, $10, $30
Sfx1_0C_Data_433F:
	dw Sfx1_0C_Data_4343+6, Sfx1_0C_Data_4343
Sfx1_0C_Data_4343:
	db $00, $80, $94, $c0, $87, $04
	db $80, $94, $cc, $87, $04
Sfx1_0D_Init:
	ld a, $0c
	ld [wSfx1Counter], a
	ld hl, Sfx1_0D_Data_4388
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_0D_Play:
	call Sfx_IncStep
	cp $0b
	jr z, .l0
.l1:
	ld hl, Sfx1_0D_Data_4374
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_0D_Data_4374:
	db $00, $02
	db $00, $04
	db $00, $08
	db $00, $04
	db $00, $02
	db $ff, $fc
	db $ff, $f8
	db $ff, $f0
	db $ff, $f8
	db $ff, $fc
Sfx1_0D_Data_4388:
	db $00, $80, $c7, $80, $87, $01
Sfx1_0E_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_0E_Data_43CA
	jp Sfx1_Start

Sfx1_0E_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jr z, .l0
	cp $06
	jp z, Sfx1_Stop
.l1:
	ld hl, Sfx1_0E_Data_43C0
	call GetPointer
	jp SetRegs_Ch1

.l0:
	call Sfx1_DecCounter
	ld a, $02
	jp z, .l1
	ld a, $01
	ld [bc], a
	jp .l1

Sfx1_0E_Data_43C0:
	dw Sfx1_0E_Data_43CA+6, Sfx1_0E_Data_43CA+12, Sfx1_0E_Data_43CA+12, Sfx1_0E_Data_43CA+12, Sfx1_0E_Data_43CA+12
Sfx1_0E_Data_43CA:
	db $2f, $b5, $59, $39, $c7, $03
	db $2f, $b5, $59, $70, $c7, $03
	db $2f, $b5, $29, $70, $c7, $03
Sfx1_0F_Init:
	call Sound_Stop
	ld hl, Sfx1_0F_Data_4402
	jp Sfx1_StartInterruptible

Sfx1_0F_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx1_Stop
	ld hl, Sfx1_0F_Data_43FA
	call GetPointer
	jp SetRegs_Ch1

Sfx1_0F_Data_43FA:
	dw Sfx1_0F_Data_4402, Sfx1_0F_Data_4402, Sfx1_0F_Data_4402, Sfx1_0F_Data_4402
Sfx1_0F_Data_4402:
	db $17, $bc, $b4, $54, $c7, $02
Sfx1_10_Init:
	ld a, [$a279]
	and a
	ret z
	cp $05
	ret nc
	ld hl, Sfx1_10_Data_4431
	call GetPointer
	jp Sfx1_StartInterruptible

Sfx1_10_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx1_Stop
	ld a, [$a279]
	ld hl, Sfx1_10_Data_4439
	call GetPointer
	jp Sfx1_WritePeriod

Sfx1_10_Data_4431:
	dw Sfx1_10_Data_4439+8, Sfx1_10_Data_4439+14, Sfx1_10_Data_4439+20, Sfx1_10_Data_4439+26
Sfx1_10_Data_4439:
	db $59, $44, $5c
	db $44, $5f, $44
	db $62, $44, $00
	db $af, $80, $06
	db $c7, $02, $00
	db $af, $80, $21
	db $c7, $02, $00
	db $af, $80, $39
	db $c7, $02, $00
	db $af, $80, $4f
	db $c7, $02, $44
	db $c7, $02, $59
	db $c7, $02, $6b
	db $c7, $02, $7b
	db $c7, $02
Sfx1_11_Init:
	call Sound_Stop
	jp Sfx1_13_Init

Sfx1_12_Init:
	ld hl, Sfx1_12_Data_448A
	jp Sfx1_Start

Sfx1_12_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx1_Stop
	ld hl, Sfx1_12_Data_4486
	call GetPointer
	jp SetRegs_Ch1

Sfx1_12_Data_4486:
	dw Sfx1_12_Data_448A+6, Sfx1_12_Data_448A+12
Sfx1_12_Data_448A:
	db $37, $a6, $49, $c0, $c6, $08
	db $37, $a6, $09, $c0, $c6, $08
	db $37, $a6, $0a, $c0, $c6, $08
Sfx1_13_Init:
	ld a, $0a
	ld [wSfx1Counter], a
	ld hl, Sfx1_11_Data_44D2
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_11_Play:
	call Sfx_IncStep
	cp $09
	jr z, .l0
.l1:
	ld hl, Sfx1_11_Data_44C2
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_11_Data_44C2:
	db $00, $50
	db $00, $30
	db $ff, $d0
	db $ff, $b0
	db $ff, $b0
	db $ff, $d0
	db $00, $30
	db $00, $60
Sfx1_11_Data_44D2:
	db $00, $00, $f5, $80, $84, $01
Sfx1_14_Init:
	ld hl, Sfx1_14_Data_4542
	jp Sfx1_StartPriority

Sfx1_14_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $18
	jp z, Sfx1_Stop
	cp $10
	jr nc, .l0
	cp $08
	jr nc, .l1
	ld a, $a0
	ldh [rNR12], a
.l2:
	ld a, $2f
	ldh [rNR10], a
	ld a, $bb
	ldh [rNR11], a
	ld a, [bc]
	ld hl, Sfx1_14_Data_4514
	call GetPointer
	jp Sfx1_WritePeriod

.l1:
	ld a, $40
	ldh [rNR12], a
	jr .l2

.l0:
	ld a, $20
	ldh [rNR12], a
	jr .l2

Sfx1_14_Data_4514:
	dw Sfx1_14_Data_4542+6, Sfx1_14_Data_4542+9, Sfx1_14_Data_4542+12, Sfx1_14_Data_4542+15, Sfx1_14_Data_4542+18, Sfx1_14_Data_4542+21, Sfx1_14_Data_4542+24, Sfx1_14_Data_4542+27, Sfx1_14_Data_4542+6, Sfx1_14_Data_4542+9, Sfx1_14_Data_4542+12, Sfx1_14_Data_4542+15, Sfx1_14_Data_4542+18, Sfx1_14_Data_4542+21, Sfx1_14_Data_4542+24, Sfx1_14_Data_4542+27, Sfx1_14_Data_4542+6, Sfx1_14_Data_4542+9, Sfx1_14_Data_4542+12, Sfx1_14_Data_4542+15, Sfx1_14_Data_4542+18, Sfx1_14_Data_4542+21, Sfx1_14_Data_4542+24
Sfx1_14_Data_4542:
	db $2f, $bb, $a0, $e0, $c7, $03
	db $c0, $c7, $03, $a0, $c7, $03
	db $80, $c7, $03, $60, $c7, $03
	db $40, $c7, $03, $20, $c7, $03
	db $00, $c7, $03, $e0, $c7, $03
Sfx1_15_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_15_Data_4595
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_15_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $04
	ld [de], a
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l1:
	ld hl, Sfx1_15_Data_458D
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_15_Data_458D:
	db $00, $0a
	db $00, $0b
	db $00, $0d
	db $ff, $de
Sfx1_15_Data_4595:
	db $00, $00, $87, $ac, $87, $04
Sfx1_16_Init:
	ld hl, Sfx1_16_Data_45DC
	jp Sfx1_Start

Sfx1_16_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $09
	jp z, Sfx1_StopWithRegs
	ld hl, Sfx1_16_Data_45CC
	call GetPointer
	ld a, [wSfx1Step]
	cp $08
	jp z, SetRegs_Ch1
	and $01
	jr z, .l0
	ld a, $30
	ldh [rNR12], a
.l1:
	jp Sfx1_WritePeriod

.l0:
	ld a, $b0
	ldh [rNR12], a
	jr .l1

Sfx1_16_Data_45CC:
	dw Sfx1_16_Data_45DC+6, Sfx1_16_Data_45DC+9, Sfx1_16_Data_45DC+9, Sfx1_16_Data_45DC+6, Sfx1_16_Data_45DC+6, Sfx1_16_Data_45DC+12, Sfx1_16_Data_45DC+12, Sfx1_16_Data_45DC+15
Sfx1_16_Data_45DC:
	db $00, $80, $b0, $9d, $c7, $03
	db $9d, $c7, $03, $97, $c7, $03
	db $be, $c7, $03, $00, $80, $b6
	db $b6, $87, $40
Sfx1_17_Init:
	ld a, $04
	ld [wSfx1Counter], a
	ld hl, Sfx1_17_Data_4626
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_17_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $04
	ld [de], a
	call Sfx_IncStep
	cp $05
	jr z, .l0
.l1:
	ld hl, Sfx1_17_Data_461E
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $01
	ld [bc], a
	jr .l1

Sfx1_17_Data_461E:
	db $00, $30
	db $ff, $a0
	db $00, $40
	db $ff, $a0
Sfx1_17_Data_4626:
	db $00, $80, $c5, $c0, $87, $04
Sfx1_18_Init:
	ld a, $08
	ld [wSfx1Counter], a
	ld hl, Sfx1_18_Data_467A
	call Sfx_LoadPitchA_Unused
	jp Sfx1_StartPriority

Sfx1_18_Play:
	call Sfx_IncStep
	cp $15
	jr z, .l0
.l1:
	ld hl, Sfx1_18_Data_4652
	jp Sfx1_AddPitch

.l0:
	call Sfx1_DecCounter
	jp z, Sfx1_Stop
	ld a, $09
	ld [bc], a
	jr .l1

Sfx1_18_Data_4652:
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $ff, $80
	db $01, $80
	db $ff, $40
	db $01, $80
	db $ff, $40
	db $01, $80
	db $ff, $40
	db $fe, $80
	db $00, $c0
	db $fe, $80
	db $00, $c0
	db $fe, $80
	db $00, $c0
Sfx1_18_Data_467A:
	db $00, $80, $f7, $00, $85, $01
; Start a ch1 effect: hl = 5 register bytes + frames. Priority: ordinary effects are
; refused until this one ends. Interruptible: priority, but sets wVibrato, which lets any
; effect through (wVibrato is also ch1's vibrato counter; a ch1 music note clears it).
Sfx1_StartInterruptible:
	ld a, $01
	ld [wVibrato], a
Sfx1_StartPriority:
	ld a, $01
	ld [wSfx1Priority], a
Sfx1_Start:
	ld a, [wSfx1Request]
	ld [wSfx1Playing], a
	xor a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	jp SetRegs_Ch1

Sfx1_StopWithRegs:
	ld hl, Sfx1_05_Data_46C6
	call SetRegs_Ch1
Sfx1_Stop:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx1Timer], a
	ldh [rNR10], a
	ld [wSfx1Step], a
	ld [wSfx1Counter], a
	ld [wVibrato], a
	ld [wSfx1Priority], a
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

Sfx1_05_Data_46C6:
	db $00, $3f, $00, $00, $c1, $01
Sfx1_WritePeriod:
	ld b, $02
	ld c, $13
	jp SetRegs_Copy

Sfx3_Update:
	ld hl, wSfx3Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $14
	jr z, .start
	ld a, [wSfx3Priority]
	and a
	ret nz
.start:
	ld a, [hl]
	ld hl, Sfx3_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx3_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx3Timer
	ld bc, wSfx3Step
	jp hl

; SFX on ch3 (wSfx3Request = 1-24)
Sfx3_InitTable:
	dw Sfx3_01_Init
	dw Sfx3_02_Init
	dw Sfx3_03_Init
	dw Sfx3_04_Init
	dw Sfx3_05_Init
	dw Sfx3_06_Init
	dw Sfx3_07_Init
	dw Sfx3_08_Init
	dw Sfx3_09_Init
	dw Sfx3_0A_Init
	dw Sfx3_0A_Init
	dw Sfx3_0C_Init
	dw Sfx3_0D_Init
	dw Sfx3_0E_Init
	dw Sfx3_0F_Init
	dw Sfx3_10_Init
	dw Sfx3_11_Init
	dw Sfx3_12_Init
	dw Sfx3_Nothing
	dw Sfx3_14_Init
	dw Sfx3_15_Init
	dw Sfx3_16_Init
	dw Sfx3_17_Init
	dw Sfx3_18_Init
Sfx3_PlayTable:
	dw Sfx3_01_Play
	dw Sfx3_02_Play
	dw Sfx3_03_Play
	dw Sfx3_04_Play
	dw Sfx3_05_Play
	dw Sfx3_06_Play
	dw Sfx3_07_Play
	dw Sfx3_08_Play
	dw Sfx3_09_Play
	dw Sfx3_0A_Play
	dw Sfx3_0A_Play
	dw Sfx3_0C_Play
	dw Sfx3_0D_Play
	dw Sfx3_0E_Play
	dw Sfx3_0F_Play
	dw Sfx3_10_Play
	dw Sfx3_11_Play
	dw Sfx3_12_Play
	dw Sfx3_Nothing
	dw Sfx3_14_Play
	dw Sfx3_15_Play
	dw Sfx3_16_Play
	dw Sfx3_17_Play
	dw Sfx3_15_Play
Sfx3_01_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BD6
	ld hl, Sfx3_01_Data_47D1
	jp Sfx3_Start

Sfx3_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $18
	jr z, .l0
.l1:
	ld hl, Sfx3_01_Data_47A3
	call GetPointer
	ld a, [wSfx3Step]
	cp $04
	jp z, SetRegs_Ch3
	cp $08
	jp z, SetRegs_Ch3
	cp $0c
	jp z, SetRegs_Ch3
	cp $10
	jp z, SetRegs_Ch3
	cp $14
	jp z, SetRegs_Ch3
	jp Sfx3_WritePeriod

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	ld a, $0c
	ld [bc], a
	jr .l1

Sfx3_01_Data_47A3:
	dw Sfx3_01_Data_47D1+6, Sfx3_01_Data_47D1+9, Sfx3_01_Data_47D1+12, Sfx3_01_Data_47D1+15, Sfx3_01_Data_47D1+6, Sfx3_01_Data_47D1+9, Sfx3_01_Data_47D1+12, Sfx3_01_Data_47D1+21, Sfx3_01_Data_47D1+6, Sfx3_01_Data_47D1+9, Sfx3_01_Data_47D1+27, Sfx3_01_Data_47D1+30, Sfx3_01_Data_47D1+36, Sfx3_01_Data_47D1+39, Sfx3_01_Data_47D1+42, Sfx3_01_Data_47D1+45, Sfx3_01_Data_47D1+36, Sfx3_01_Data_47D1+39, Sfx3_01_Data_47D1+42, Sfx3_01_Data_47D1+51, Sfx3_01_Data_47D1+36, Sfx3_01_Data_47D1+39, Sfx3_01_Data_47D1+42
Sfx3_01_Data_47D1:
	db $80, $e2, $20, $80, $c6, $02
	db $98, $86, $02, $b0, $86, $02
	db $c8, $86, $03, $80, $e2, $40
	db $80, $c6, $02, $80, $e2, $60
	db $80, $c6, $02, $c8, $86, $01
	db $80, $e2, $20, $c0, $c6, $02
	db $a0, $86, $02, $80, $86, $02
	db $60, $86, $03, $80, $e2, $40
	db $c0, $c6, $02, $80, $e2, $60
	db $c0, $c6, $02
Sfx3_02_Init:
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_02_Data_4866
	jp Sfx3_Start

Sfx3_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $12
	jp z, Sfx3_Stop
	ld hl, Sfx3_02_Data_4844
	call GetPointer
	ld a, [wSfx3Step]
	cp $03
	jp z, SetRegs_Ch3
	cp $06
	jp z, SetRegs_Ch3
	cp $09
	jp z, SetRegs_Ch3
	cp $0c
	jp z, SetRegs_Ch3
	cp $0f
	jp z, SetRegs_Ch3
	jp Sfx3_WritePeriod

Sfx3_02_Data_4844:
	dw Sfx3_02_Data_4866+6, Sfx3_02_Data_4866+9, Sfx3_02_Data_4866+12, Sfx3_02_Data_4866+6, Sfx3_02_Data_4866+9, Sfx3_02_Data_4866+18, Sfx3_02_Data_4866+24, Sfx3_02_Data_4866+27, Sfx3_02_Data_4866+30, Sfx3_02_Data_4866+24, Sfx3_02_Data_4866+27, Sfx3_02_Data_4866+36, Sfx3_02_Data_4866+42, Sfx3_02_Data_4866+45, Sfx3_02_Data_4866+48, Sfx3_02_Data_4866+42, Sfx3_02_Data_4866+45
Sfx3_02_Data_4866:
	db $80, $da, $20, $8a, $c7, $02
	db $8c, $c7, $02, $8e, $c7, $04
	db $80, $da, $60, $8a, $c7, $02
	db $80, $da, $20, $40, $c7, $02
	db $48, $c7, $02, $50, $c7, $06
	db $80, $da, $60, $40, $c7, $02
	db $80, $da, $20, $30, $c7, $02
	db $38, $c7, $02, $40, $c7, $06
	db $80, $da, $60, $30, $c7, $02
Sfx3_03_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_03_Data_48E2
	jp Sfx3_Start

Sfx3_03_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jr z, .l0
	ld hl, Sfx3_03_Data_48D4
	call GetPointer
	ld a, [wSfx3Step]
	cp $04
	jp z, SetRegs_Ch3
	jp Sfx3_WritePeriod

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	xor a
	ld [bc], a
	ld hl, Sfx3_03_Data_48E2
	jp SetRegs_Ch3

Sfx3_03_Data_48D4:
	dw Sfx3_03_Data_48E2+6, Sfx3_03_Data_48E2+9, Sfx3_03_Data_48E2+12, Sfx3_03_Data_48E2+15, Sfx3_03_Data_48E2+6, Sfx3_03_Data_48E2+9, Sfx3_03_Data_48E2+12
Sfx3_03_Data_48E2:
	db $80, $e2, $20, $df, $c7, $02
	db $de, $c7, $02, $dd, $c7, $02
	db $dc, $c7, $02, $80, $e2, $60
	db $df, $c7, $02
Sfx3_04_Init:
	ld a, $24
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BF6
	ld hl, Sfx3_04_Data_4926
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_04_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $12
	jr z, .l0
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_04_Data_4924
	jp Sfx3_AddPitch

.l0:
	ld hl, Sfx3_04_Data_492C
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_04_Data_4924:
	db $00, $50
Sfx3_04_Data_4926:
	db $80, $00, $20, $00, $81, $02
Sfx3_04_Data_492C:
	db $80, $00, $60, $00, $81, $02
Sfx3_05_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_05_Data_4988
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $11
	jr z, .l0
	ld a, $02
	ld [de], a
	ld hl, Sfx3_05_Data_4968
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx3_05_Data_498E
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_05_Data_4968:
	db $00, $10
	db $00, $10
	db $00, $10
	db $00, $10
	db $fd, $00
	db $00, $80
	db $ff, $80
	db $00, $80
	db $02, $90
	db $ff, $f8
	db $ff, $f8
	db $ff, $f8
	db $ff, $f8
	db $ff, $f8
	db $ff, $f8
	db $ff, $f8
Sfx3_05_Data_4988:
	db $80, $10, $20, $c0, $86, $02
Sfx3_05_Data_498E:
	db $80, $10, $60, $c0, $86, $02
Sfx3_06_Init:
	ld a, [wSfx3Playing]
	cp $06
	ret z
	call Sfx3_LoadWave5B96
	ld hl, wSfxVar3E
	ld a, [hl]
	and a
	jr z, .l0
	dec [hl]
	ld hl, Sfx3_06_Data_49E1
	jp Sfx3_Start

.l0:
	inc [hl]
	ld hl, Sfx3_06_Data_49ED
	jp Sfx3_Start

Sfx3_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $03
	jp z, Sfx3_Stop
	ld a, [wSfxVar3E]
	and a
	ld a, [wSfx3Step]
	jr z, .l1
	ld hl, Sfx3_06_Data_49DD
	call GetPointer
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_06_Data_49D9
	call GetPointer
	jp SetRegs_Ch3

Sfx3_06_Data_49D9:
	dw Sfx3_06_Data_49E1+6, Sfx3_06_Data_49E1
Sfx3_06_Data_49DD:
	dw Sfx3_06_Data_49ED+6, Sfx3_06_Data_49ED
Sfx3_06_Data_49E1:
	db $80, $fb, $20, $a0, $c7, $03
	db $80, $fb, $20, $a8, $c7, $03
Sfx3_06_Data_49ED:
	db $80, $fb, $40, $a0, $c7, $03
	db $80, $fb, $40, $a8, $c7, $03
Sfx3_07_Init:
	ld a, $30
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5B96
	ld hl, Sfx3_07_Data_4A28
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_07_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $18
	jr z, .l0
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_07_Data_4A26
	jp Sfx3_AddPitch

.l0:
	ld hl, Sfx3_07_Data_4A2E
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_07_Data_4A26:
	db $00, $10
Sfx3_07_Data_4A28:
	db $80, $00, $20, $00, $82, $02
Sfx3_07_Data_4A2E:
	db $80, $00, $40, $00, $82, $02
Sfx3_08_Init:
	ld a, $02
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_08_Data_4AA3
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $1d
	jr z, .l0
	ld a, $01
	ld [de], a
	ld a, [bc]
	ld hl, Sfx3_08_Data_4A6B
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx3_08_Data_4AA9
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_08_Data_4A6B:
	db $00, $10
	db $ff, $f0
	db $00, $10
	db $ff, $f0
	db $00, $10
	db $ff, $f0
	db $00, $20
	db $00, $20
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
	db $ff, $f6
	db $00, $05
Sfx3_08_Data_4AA3:
	db $80, $00, $20, $58, $87, $02
Sfx3_08_Data_4AA9:
	db $80, $00, $60, $58, $87, $02
Sfx3_09_Init:
	ld a, $14
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_09_Data_4ADE
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_09_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $10
	jr z, .l0
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_09_Data_4ADC
	jp Sfx3_AddPitch

.l0:
	ld hl, Sfx3_09_Data_4AE4
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_09_Data_4ADC:
	db $ff, $f4
Sfx3_09_Data_4ADE:
	db $80, $00, $20, $00, $86, $01
Sfx3_09_Data_4AE4:
	db $80, $00, $40, $00, $86, $01
Sfx3_0A_Init:
	call Sfx3_LoadWave5B96
	ld hl, Sfx3_0A_Data_4B14
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_0A_Play:
	call Sfx_IncStep
	cp $0b
	jp z, Sfx3_StopWithRegs
	ld hl, Sfx3_0A_Data_4B04
	jp Sfx3_AddPitch

Sfx3_0A_Data_4B04:
	db $ff, $00
	db $ff, $00
	db $ff, $00
	db $00, $c0
	db $00, $c0
	db $00, $c0
	db $00, $c0
	db $00, $c0
Sfx3_0A_Data_4B14:
	db $80, $00, $20, $00, $84, $01
Sfx3_0F_Init:
	ld a, $03
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5BF6
	ld hl, Sfx3_0F_Data_4B83
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_0F_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $15
	jr z, .l0
	ld hl, Sfx3_0F_Data_4B5B
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	cp $01
	jp z, .l1
	ld hl, Sfx3_0F_Data_4B89
.l2:
	ld a, $04
	ld [bc], a
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

.l1:
	ld hl, Sfx3_0F_Data_4B8F
	jr .l2

Sfx3_0F_Data_4B5B:
	db $00, $a0
	db $00, $a0
	db $00, $a0
	db $00, $a0
	db $fd, $00
	db $03, $00
	db $ff, $00
	db $00, $c0
	db $ff, $00
	db $00, $c0
	db $ff, $00
	db $00, $c0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
	db $ff, $e0
Sfx3_0F_Data_4B83:
	db $80, $00, $20, $80, $83, $02
Sfx3_0F_Data_4B89:
	db $80, $00, $40, $a0, $85, $02
Sfx3_0F_Data_4B8F:
	db $80, $00, $60, $a0, $85, $02
Sfx3_0C_Init:
	ld a, $02
	ld [wSfx3Counter], a
	jp Sfx3_0A_Init

Sfx3_0C_Play:
	call Sfx_IncStep
	cp $0b
	jp z, .l0
	ld hl, Sfx3_0A_Data_4B04
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx3_0C_Data_4BBC
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_0C_Data_4BBC:
	db $80, $00, $40, $00, $84, $01
Sfx3_0D_Init:
	ld a, $02
	ld [wSfx3Counter], a
	ld hl, Sfx3_0D_Data_5B86
	call Sfx3_LoadWave
	ld hl, Sfx3_0D_Data_4C13
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_0D_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $0b
	jr z, .l0
	ld hl, Sfx3_0D_Data_4BFB
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	xor a
	ld [bc], a
	ld hl, Sfx3_0D_Data_4C19
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_0D_Data_4BFB:
	db $01, $00
	db $01, $00
	db $01, $00
	db $01, $00
	db $00, $80
	db $ff, $b0
	db $00, $80
	db $ff, $b0
	db $00, $80
	db $ff, $b0
	db $00, $80
	db $ff, $b0
Sfx3_0D_Data_4C13:
	db $80, $00, $20, $00, $83, $02
Sfx3_0D_Data_4C19:
	db $80, $00, $60, $00, $83, $02
Sfx3_0E_Data_4C1F:
	db $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00
Sfx3_0E_Init:
	ld hl, Sfx3_0E_Data_4C1F
	call Sfx3_LoadWave
	ld hl, Sfx3_0E_Data_4C42
	jp Sfx3_Start

Sfx3_0E_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx3_Stop

Sfx3_0E_Data_4C42:
	db $80, $e6, $20, $44, $c7, $06
Sfx3_10_Init:
	ld hl, Sfx3_10_Data_4C6C
	push hl
Sfx3_11_Init_l0:
	ld a, $08
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5B96
	pop hl
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_10_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_10_Data_4C6A
	jp Sfx3_AddPitch

Sfx3_10_Data_4C6A:
	db $ff, $60
Sfx3_10_Data_4C6C:
	db $80, $d8, $20, $00, $c5, $01
Sfx3_11_Init:
	ld hl, Sfx3_11_Data_4C89
	push hl
	jr Sfx3_11_Init_l0

Sfx3_11_Play:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	ld a, $01
	ld [bc], a
	ld hl, Sfx3_11_Data_4C87
	jp Sfx3_AddPitch

Sfx3_11_Data_4C87:
	db $ff, $c0
Sfx3_11_Data_4C89:
	db $80, $d8, $20, $c0, $c6, $02
Sfx3_12_Init:
	call Sfx3_LoadWave5BE6
	ld hl, Sfx3_12_Data_4CB9
	jp Sfx3_Start

Sfx3_12_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx3_Stop
	ld hl, Sfx3_12_Data_4CAD
	call GetPointer
	jp SetRegs_Ch3

Sfx3_12_Data_4CAD:
	dw Sfx3_12_Data_4CB9+6, Sfx3_12_Data_4CB9+12, Sfx3_12_Data_4CB9+18, Sfx3_12_Data_4CB9+6, Sfx3_12_Data_4CB9+12, Sfx3_12_Data_4CB9+18
Sfx3_12_Data_4CB9:
	db $00, $00, $00, $00, $80, $10
	db $80, $d8, $40, $40, $87, $02
	db $80, $d8, $40, $48, $87, $02
	db $80, $f2, $40, $50, $c7, $08
Sfx3_14_Data_4CD1:
	db $77, $77, $77, $71, $66, $66, $66, $02, $00, $00, $00, $00, $00, $00, $00, $00
Sfx3_14_Init:
	ld a, $07
	ld [wSfx3Counter], a
	ld hl, Sfx3_14_Data_4CD1
	call Sfx3_LoadWave
	ld hl, Sfx3_14_Data_4D32
	call Sfx3_LoadPitch
	jp Sfx3_StartPriority

Sfx3_14_Play:
	call Sfx_IncStep
	cp $09
	jp z, .l0
	cp $11
	jp z, Sfx3_StopWithRegs
.l1:
	ld hl, Sfx3_14_Data_4D12
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_14_Data_4D12:
	db $00, $14
	db $00, $12
	db $00, $12
	db $00, $10
	db $00, $0c
	db $ff, $ec
	db $ff, $ec
	db $ff, $ec
	db $00, $06
	db $00, $08
	db $00, $0a
	db $00, $0c
	db $00, $0e
	db $00, $10
	db $00, $12
	db $00, $08
Sfx3_14_Data_4D32:
	db $80, $00, $20, $90, $86, $01
Sfx3_15_Init:
	call Sfx3_LoadWave5B96
	ld hl, Sfx3_15_Data_4D60
	jp Sfx3_Start

Sfx3_15_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx3_Stop
	ld hl, Sfx3_15_Data_4D56
	call GetPointer
	jp SetRegs_Ch3

Sfx3_15_Data_4D56:
	dw Sfx3_15_Data_4D60+6, Sfx3_15_Data_4D60, Sfx3_15_Data_4D60+6, Sfx3_15_Data_4D60, Sfx3_15_Data_4D60+6
Sfx3_15_Data_4D60:
	db $80, $fb, $40, $c0, $c7, $04
	db $80, $fb, $40, $c8, $c7, $04
Sfx3_16_Init:
	ld a, $0a
	ld [wSfx3Counter], a
	call Sfx3_LoadWave5B96
	ld hl, Sfx3_16_Data_4DA8
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_16_Play:
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l2:
	ld hl, Sfx3_16_Data_4DA4
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_Stop
	cp $05
	jr z, .l1
	ld a, $01
	ld [bc], a
	jr .l2

.l1:
	xor a
	ld [bc], a
	ld hl, Sfx3_16_Data_4DA8
	call Sfx3_LoadPitch
	jp SetRegs_Ch3

Sfx3_16_Data_4DA4:
	db $ff, $ea
	db $00, $11
Sfx3_16_Data_4DA8:
	db $80, $de, $40, $c0, $c6, $01
Sfx3_17_Init:
	ld a, $07
	ld [wSfx3Counter], a
	ld hl, Sfx3_17_Data_5BA6
	call Sfx3_LoadWave
	ld hl, Sfx3_17_Data_4DE5
	call Sfx3_LoadPitch
	jp Sfx3_Start

Sfx3_17_Play:
	call Sfx_DecTimer
	ret nz
	ld a, $02
	ld [de], a
	call Sfx_IncStep
	cp $03
	jr z, .l0
.l1:
	ld hl, Sfx3_17_Data_4DE1
	jp Sfx3_AddPitch

.l0:
	call Sfx3_DecCounter
	jp z, Sfx3_StopWithRegs
	ld a, $01
	ld [bc], a
	jr .l1

Sfx3_17_Data_4DE1:
	db $00, $20
	db $ff, $e8
Sfx3_17_Data_4DE5:
	db $80, $00, $40, $a0, $87, $02
Sfx3_18_Init:
	ld a, [wSfx3Playing]
	and a
	ret nz
	jp Sfx3_15_Init

Sfx3_StartPriority:
	ld a, $01
	ld [wSfx3Priority], a
Sfx3_Start:
	ld a, [wSfx3Request]
	ld [wSfx3Playing], a
	push hl
	ld hl, wCh3Flags
	set 7, [hl]
	pop hl
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ldh [rNR30], a
	jp SetRegs_Ch3

	db $80, $00, $00, $00, $01, $01
Sfx3_StopWithRegs:
	ld hl, Sfx3_StopRegs
	call SetRegs_Ch3
Sfx3_Stop:
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ld [wSfx3Playing], a
	ldh [rNR30], a
	ld [wSfx3Priority], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld a, [wCh3InstrEnv]
	ld l, a
	ld a, [wCh3InstrRelease]
	ld h, a
	jp LoadWave

Sfx3_StopRegs:
	db $80, $00, $00, $00, $81, $01
; Effect 19 on ch3: init and per-frame routine are both this ret.
Sfx3_Nothing:
	ret

Sfx3_LoadWave:
	xor a
	ldh [rNR30], a
	jp LoadWave

Sfx3_LoadWave5BD6:
	ld hl, Wave_5BD6
	jr Sfx3_LoadWave

Sfx3_LoadWave5BE6:
	ld hl, Wave_5BE6
	jr Sfx3_LoadWave

Sfx3_LoadWave5BF6:
	ld hl, Wave_5BF6
	jr Sfx3_LoadWave

Sfx3_LoadWave5B96:
	ld hl, Wave_5B96
	jr Sfx3_LoadWave

Sfx3_WritePeriod:
	ld c, $1d
	ld b, $02
	jp SetRegs_Copy

; SFX on ch4 (wSfx4Request = 1-11)
Sfx4_InitTable:
	dw Sfx4_01_Init
	dw Sfx4_02_Init
	dw Sfx4_03_Init
	dw Sfx4_04_Init
	dw Sfx4_05_Init
	dw Sfx4_06_Init
	dw Sfx4_07_Init
	dw Sfx4_08_Init
	dw Sfx4_09_Init
	dw Sfx4_0A_Init
	dw Sfx4_0B_Init
Sfx4_PlayTable:
	dw Sfx4_01_Play
	dw Sfx4_02_Play
	dw Sfx4_03_Play
	dw Sfx4_04_Play
	dw Sfx4_05_Play
	dw Sfx4_06_Play
	dw Sfx4_07_Play
	dw Sfx4_08_Play
	dw Sfx4_09_Play
	dw Sfx4_0A_Play
	dw Sfx4_0B_Play
Sfx4_Update:
	ld hl, wSfx4Request
	ld a, [hl]
	and a
	jr z, .playing
	ld a, [wSfx4Priority]
	and a
	ret nz
	ld a, [hl]
	ld hl, Sfx4_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx4_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx4Timer
	ld bc, wSfx4Step
	jp hl

Sfx4_01_Init:
	ld hl, Sfx4_01_Data_4EDC
	jp Sfx4_Start

Sfx4_01_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_01_Data_4ECE
	call GetPointer
	jp SetRegs_Ch4

Sfx4_01_Data_4ECE:
	dw Sfx4_01_Data_4EDC+5, Sfx4_01_Data_4EDC+10, Sfx4_01_Data_4EDC+10, Sfx4_01_Data_4EDC+5, Sfx4_01_Data_4EDC+5, Sfx4_01_Data_4EDC, Sfx4_01_Data_4EDC
Sfx4_01_Data_4EDC:
	db $3a, $40, $70, $c0, $02
	db $3a, $90, $50, $c0, $02
	db $3a, $e0, $30, $c0, $02
Sfx4_02_Init:
	ld a, $03
	ld [wSfx4Counter], a
	ld hl, Sfx4_02_Data_4F34
	jp Sfx4_Start

Sfx4_02_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx4_Stop
	and $01
	jr nz, .l0
	ld a, $49
	ldh [rNR42], a
.l1:
	ld a, $2f
	ldh [rNR41], a
	ld a, [bc]
	ld hl, Sfx4_02_Data_4F1E
	call GetPointer
	jp Sfx4_WriteNR43

.l0:
	ld a, $20
	ldh [rNR42], a
	jr .l1

Sfx4_02_Data_4F1E:
	dw Sfx4_02_Data_4F34+5, Sfx4_02_Data_4F34+8, Sfx4_02_Data_4F34+8, Sfx4_02_Data_4F34+11, Sfx4_02_Data_4F34+11, Sfx4_02_Data_4F34+14, Sfx4_02_Data_4F34+14, Sfx4_02_Data_4F34+17, Sfx4_02_Data_4F34+17, Sfx4_02_Data_4F34+20, Sfx4_02_Data_4F34+20
Sfx4_02_Data_4F34:
	db $2f, $49, $35, $c0, $04
	db $35, $c0, $04, $34, $c0
	db $04, $33, $c0, $04, $32
	db $c0, $04, $31, $c0, $04
	db $30, $c0, $04
Sfx4_03_Init:
	ld a, $03
	ld [wSfx4Playing], a
	ld hl, Sfx4_03_Data_4F60
	jp SetRegs_Ch4

Sfx4_03_Play:
	xor a
	ld [wSfx4Playing], a
	ld hl, Sfx4_03_Data_4F65
	jp SetRegs_Ch4

Sfx4_03_Data_4F60:
	db $3b, $80, $07, $c0, $01
Sfx4_03_Data_4F65:
	db $00, $42, $02, $c0, $04
Sfx4_04_Init:
	ld a, [wSfx4Playing]
	cp $04
	ret z
	ld hl, Sfx4_04_Data_4F7D
	jp Sfx4_Start

Sfx4_04_Play:
	call Sfx_DecTimer
	ret nz
	jp Sfx4_Stop

Sfx4_04_Data_4F7D:
	db $3c, $81, $00, $c0, $06
Sfx4_05_Init:
	ld hl, Sfx4_05_Data_4FAB
	jp Sfx4_Start

Sfx4_05_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_05_Data_4F9D
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_05_Data_4F9D:
	dw Sfx4_05_Data_4FAB+5, Sfx4_05_Data_4FAB+8, Sfx4_05_Data_4FAB+11, Sfx4_05_Data_4FAB+14, Sfx4_05_Data_4FAB+17, Sfx4_05_Data_4FAB+20, Sfx4_05_Data_4FAB+23
Sfx4_05_Data_4FAB:
	db $00, $86, $57, $80, $05
	db $55, $80, $05, $47, $80
	db $04, $45, $80, $04, $37
	db $80, $03, $35, $80, $03
	db $27, $80, $02, $25, $80
	db $40
Sfx4_06_Init:
	ld hl, Sfx4_06_Data_4FEA
	jp Sfx4_Start

Sfx4_06_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $06
	jp z, Sfx4_Stop
	ld hl, Sfx4_06_Data_4FE0
	call GetPointer
	jp SetRegs_Ch4

Sfx4_06_Data_4FE0:
	dw Sfx4_06_Data_4FEA+5, Sfx4_06_Data_4FEA+10, Sfx4_06_Data_4FEA+15, Sfx4_06_Data_4FEA+20, Sfx4_06_Data_4FEA+25
Sfx4_06_Data_4FEA:
	db $00, $20, $15, $80, $02
	db $00, $30, $17, $80, $02
	db $00, $50, $25, $80, $02
	db $00, $70, $27, $80, $03
	db $00, $a0, $35, $80, $03
	db $00, $d1, $37, $80, $0c
Sfx4_07_Init:
	ld a, [wSfx4Playing]
	cp $07
	ret z
	ld hl, Sfx4_07_Data_5026
	jp Sfx4_Start

Sfx4_07_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $02
	jp z, Sfx4_Stop
	ld hl, Sfx4_07_Data_502B
	jp SetRegs_Ch4

Sfx4_07_Data_5026:
	db $3b, $a0, $20, $c0, $02
Sfx4_07_Data_502B:
	db $39, $40, $20, $c0, $04
Sfx4_08_Init:
	ld hl, Sfx4_08_Data_506D
	jp Sfx4_Start

Sfx4_08_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0a
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_08_Data_505B
	call GetPointer
	ld a, [wSfx4Step]
	cp $05
	jr nc, .l0
	jp SetRegs_Ch4

.l0:
	inc hl
	inc hl
	ld a, $20
	ldh [rNR42], a
	jp Sfx4_WriteNR43

Sfx4_08_Data_505B:
	dw Sfx4_08_Data_506D+5, Sfx4_08_Data_506D+10, Sfx4_08_Data_506D+15, Sfx4_08_Data_506D+20, Sfx4_08_Data_506D, Sfx4_08_Data_506D+5, Sfx4_08_Data_506D+10, Sfx4_08_Data_506D+15, Sfx4_08_Data_506D+20
Sfx4_08_Data_506D:
	db $00, $80, $3c, $80, $03
	db $00, $70, $3d, $80, $03
	db $00, $60, $3e, $80, $03
	db $00, $50, $3f, $80, $03
	db $00, $40, $4c, $80, $03
Sfx4_09_Init:
	ld hl, Sfx4_09_Data_50C4
	jp Sfx4_Start

Sfx4_09_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $0c
	jp z, Sfx4_Stop
	ld hl, Sfx4_09_Data_50AE
	call GetPointer
	ld a, [wSfx4Step]
	cp $04
	jp z, SetRegs_Ch4
	cp $08
	jp z, SetRegs_Ch4
	jp Sfx4_WriteNR43

Sfx4_09_Data_50AE:
	dw Sfx4_09_Data_50C4+5, Sfx4_09_Data_50C4+8, Sfx4_09_Data_50C4+11, Sfx4_09_Data_50C4+14, Sfx4_09_Data_50C4+5, Sfx4_09_Data_50C4+8, Sfx4_09_Data_50C4+11, Sfx4_09_Data_50C4+19, Sfx4_09_Data_50C4+5, Sfx4_09_Data_50C4+8, Sfx4_09_Data_50C4+11
Sfx4_09_Data_50C4:
	db $00, $80, $24, $80, $04
	db $26, $80, $04, $34, $80
	db $04, $36, $c0, $04, $2f
	db $40, $24, $80, $04, $2f
	db $10, $24, $80, $04
Sfx4_0A_Init:
	ld a, $05
	ld [wSfx4Counter], a
	ld hl, Sfx4_0A_Data_5108
	jp Sfx4_Start

Sfx4_0A_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $07
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_0A_Data_50FC
	call GetPointer
	jp Sfx4_WriteNR43

Sfx4_0A_Data_50FC:
	dw Sfx4_0A_Data_5108+5, Sfx4_0A_Data_5108+8, Sfx4_0A_Data_5108+5, Sfx4_0A_Data_5108+11, Sfx4_0A_Data_5108+14, Sfx4_0A_Data_5108+17
Sfx4_0A_Data_5108:
	db $00, $80, $65, $80, $08
	db $64, $80, $08, $57, $80
	db $0a, $65, $80, $0c, $66
	db $80, $0e, $67, $80, $10
Sfx4_0B_Init:
	ld hl, Sfx4_0B_Data_5145
	jp Sfx4_Start

Sfx4_0B_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $08
	jp z, Sfx4_Stop
	ld hl, Sfx4_0B_Data_5137
	call GetPointer
	jp SetRegs_Ch4

Sfx4_0B_Data_5137:
	dw Sfx4_0B_Data_5145+20, Sfx4_0B_Data_5145+5, Sfx4_0B_Data_5145+20, Sfx4_0B_Data_5145+10, Sfx4_0B_Data_5145+20, Sfx4_0B_Data_5145+15, Sfx4_0B_Data_5145+20
Sfx4_0B_Data_5145:
	db $2f, $0a, $35, $c0, $04
	db $2f, $0a, $34, $c0, $04
	db $2f, $0a, $33, $c0, $04
	db $2f, $0a, $32, $c0, $04
	db $2f, $09, $45, $c0, $05
Sfx4_StartPriority_Unused:
	ld a, $01
	ld [wSfx4Priority], a
Sfx4_Start:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	jp SetRegs_Ch4

Sfx4_StopWithRegs:
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
Sfx4_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld [wSfx4Counter], a
	ld [wSfx4Priority], a
	ld a, [wCh4Flags]
	res 7, a
	ld [wCh4Flags], a
	ret

Sfx4_StopRegs:
	db $00, $00, $00, $00, $01
Sfx4_WriteNR43:
	ld b, $02
	ld c, $22
	jp SetRegs_Copy

; hl = table, a = 1-based index: hl = table[a-1]
GetPointer:
	dec a
	sla a
	ld c, a
	ld b, $00
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld h, b
	ld l, c
	ret

; de = timer: decrement, Z when it reaches 0. bc = step: increment.
Sfx_DecTimer:
	ld a, [de]
	dec a
	ld [de], a
	ret

Sfx_IncStep:
	ld a, [bc]
	inc a
	ld [bc], a
	ret

; Write a register image and store the following byte as the new timer ([de]).
SetRegs_Ch1:
	ld b, $05
	ld c, $10
	jr SetRegs_Copy

SetRegs_Ch2:
	ld b, $04
	ld c, $16
	jr SetRegs_Copy

SetRegs_Ch3:
	ld b, $05
	ld c, $1a
	jr SetRegs_Copy

SetRegs_Ch4:
	ld b, $04
	ld c, $20
	jr SetRegs_Copy

SetRegs_Copy:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, SetRegs_Copy
	ld a, [hl]
.storeTimer:
	ld [de], a
	ret

Sfx1_DecCounter:
	push de
	ld de, wSfx1Counter
	jr Sfx_DecCounter

Sfx_DecCounter2_Unused:
	push de
	ld de, wSfxCounter2
	jr Sfx_DecCounter

Sfx3_DecCounter:
	push de
	ld de, wSfx3Counter
	jr Sfx_DecCounter

Sfx4_DecCounter_Unused:
	push de
	ld de, wSfx4Counter
	jr Sfx_DecCounter

Sfx_DecCounter:
	call Sfx_DecTimer
	pop de
	ret

Sfx_LoadPitchA_Unused:
	push de
	ld de, wSfxCounter5
	jr Sfx_LoadPitch

Sfx3_LoadPitch:
	push de
	ld de, wSfx1Pitch+1
	jr Sfx_LoadPitch

Sfx_LoadPitch:
	inc hl
	inc hl
	inc hl
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl-]
	and $0f
	ld [de], a
	dec hl
	dec hl
	dec hl
	pop de
	ret

; Add a big-endian offset (table[step-1]) to the effect's period and write NRx3/NRx4.
Sfx1_AddPitch:
	push de
	ld de, wSfx1Pitch
	ld a, [bc]
	ld c, $13
	push bc
	jr Sfx_AddPitch

Sfx3_AddPitch:
	push de
	ld de, wSfx3Pitch
	ld a, [bc]
	ld c, $1d
	push bc
	jr Sfx_AddPitch

Sfx_AddPitch:
	dec a
	sla a
	ld c, a
	ld b, $00
	add hl, bc
	ld a, [hl+]
	ld b, a
	ld a, [hl]
	ld c, a
	ld a, [de]
	dec e
	ld h, a
	ld a, [de]
	ld l, a
	add hl, bc
	pop bc
	ld a, l
	ldh [c], a
	ld [de], a
	inc c
	inc e
	ld a, h
	ldh [c], a
	ld [de], a
	pop de
	ret

