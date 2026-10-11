; Tetris sound driver: code and SFX data, $6480-$6DCA

; ch1 effects 1-8: init routine and per-frame routine
Sfx1_InitTable:
	dw Sfx1_01_Init
	dw Sfx1_02_Init
	dw Sfx1_03_Init
	dw Sfx1_04_Init
	dw Sfx1_05_Init
	dw Sfx1_06_Init
	dw Sfx1_07_Init
	dw Sfx1_08_Init
Sfx1_PlayTable:
	dw Sfx1_01_Play
	dw Sfx1_02_Play
	dw Sfx1_03_Play
	dw Sfx1_02_Play
	dw Sfx1_02_Play
	dw Sfx1_06_Play
	dw Sfx1_07_Play
	dw Sfx1_08_Play
; ch4 effects 1-4
Sfx4_InitTable:
	dw Sfx4_01_Init
	dw Sfx4_02_Init
	dw Sfx4_03_Init
	dw Sfx4_04_Init
Sfx4_PlayTable:
	dw Sfx4_01_Play
	dw Sfx4_01_Play
	dw Sfx4_01_Play
	dw Sfx4_04_Play
; songs 1-17 (wSongRequest & $1F)
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
	dw Song11_Header	; song 11
	dw Song12_Header	; song 12
	dw Song13_Header	; song 13
	dw Song14_Header	; song 14
	dw Song15_Header	; song 15
	dw Song16_Header	; song 16
	dw Song17_Header	; song 17
; Called first in every update: empty.
Sound_Hook:
	ret

; Called once per frame from the game's main loop ($02CA); saves all registers. wPauseRequest
; 1 = pause, 2 = resume. While hDemoMode (game flag $FFE4, apparently the attract-mode demo)
; is set every request is dropped. Order: ch1 SFX, ch4 SFX, ch3 SFX, song request, music,
; panning; then clear the requests.
Sound_Update:
	push af
	push bc
	push de
	push hl
	ld a, [wPauseRequest]
	cp $01
	jr z, Sound_Pause
	cp $02
	jr z, Sound_Unpause
	ld a, [wPauseTimer]
	and a
	jr nz, Sound_Paused
.requests:
	ldh a, [hDemoMode]
	and a
	jr z, .run
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
.run:
	call Sound_Hook
	call Sfx1_Update
	call Sfx4_Update
	call Sfx3_Update
	call Music_StartSong
	call Music_Update
	call Music_UpdatePanning
.clearRequests:
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wPauseRequest], a
	pop hl
	pop de
	pop bc
	pop af
	ret

; Pause: mute, cancel effects, reload wave $6EE9, then a 4-frame jingle on ch2 at timer
; $28/$20/$18 (two alternating register images); hold at $10 until resumed.
Sound_Pause:
	call Sound_MuteChannels
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld hl, wCh1Flags
	res 7, [hl]
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, wCh4Flags
	res 7, [hl]
	ld hl, Wave_6EE9
	call LoadWave
	ld a, $30
	ld [wPauseTimer], a
.jingleA:
	ld hl, PauseJingleA
.writeJingle:
	call SetRegs_Ch2
	jr Sound_Update.clearRequests

.jingleB:
	ld hl, PauseJingleB
	jr .writeJingle

Sound_Unpause:
	xor a
	ld [wPauseTimer], a
	jr Sound_Update.requests

Sound_Paused:
	ld hl, wPauseTimer
	dec [hl]
	ld a, [hl]
	cp $28
	jr z, Sound_Pause.jingleB
	cp $20
	jr z, Sound_Pause.jingleA
	cp $18
	jr z, Sound_Pause.jingleB
	cp $10
	jr nz, Sound_Update.clearRequests
	inc [hl]
	jr Sound_Update.clearRequests

PauseJingleA:
	db $b2, $e3, $83, $c7
PauseJingleB:
	db $b2, $e3, $c1, $c7
; Z if the named effect is playing (used by effects that must not interrupt it).
Sfx3_Is01:
	ld a, [wSfx3Playing]
	cp $01
	ret

Sfx1_Is05:
	ld a, [wSfx1Playing]
	cp $05
	ret

Sfx1_Is07:
	ld a, [wSfx1Playing]
	cp $07
	ret

Sfx1_Is08:
	ld a, [wSfx1Playing]
	cp $08
	ret

Sfx1_01_Data_659B:
	db $00, $b5, $d0, $40, $c7
Sfx1_01_Data_65A0:
	db $00, $b5, $20, $40, $c7
Sfx1_02_Data_65A5:
	db $00, $b6, $a1, $80, $c7
Sfx1_01_Init:
	ld a, $05
	ld hl, Sfx1_01_Data_659B
	jp Sfx_Start

Sfx1_01_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $02
	jr z, Sfx1_Stop
	ld hl, Sfx1_01_Data_65A0
	jp SetRegs_Ch1

Sfx1_02_Init:
	ld a, $03
	ld hl, Sfx1_02_Data_65A5
	jp Sfx_Start

; also the per-frame routine of Sfx1_04
; also the per-frame routine of Sfx1_05
Sfx1_02_Play:
	call Sfx_Tick
	and a
	ret nz
; End a ch1 effect and give ch1 back to the music.
Sfx1_Stop:
	xor a
	ld [wSfx1Playing], a
	ldh [rNR10], a
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ld hl, wCh1Flags
	res 7, [hl]
	ret

Sfx1_07_Data_65E7:
	db $00, $80, $e1, $c1, $87
Sfx1_07_Data_65EC:
	db $00, $80, $e1, $ac, $87
Sfx1_07_Init:
	ld hl, Sfx1_07_Data_65E7
	jp Sfx_Start

Sfx1_07_Play:
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $04
	jr z, .l0
	cp $0b
	jr z, .l1
	cp $0f
	jr z, .l0
	cp $18
	jp z, .requestSfx3
	ret

; Effect 7 requests ch3 effect 1 on its last step.
.requestSfx3:
	ld a, $01
	ld hl, wSfx3Request
	ld [hl], a
	jp Sfx1_Stop

.l0:
	ld hl, Sfx1_07_Data_65EC
	jp SetRegs_Ch1

.l1:
	ld hl, Sfx1_07_Data_65E7
	jp SetRegs_Ch1

Sfx1_04_Data_6623:
	db $48, $bc, $42, $66, $87
Sfx1_04_Init:
	call Sfx3_Is01
	ret z
	call Sfx1_Is08
	ret z
	call Sfx1_Is07
	ret z
	call Sfx1_Is05
	ret z
	ld a, $02
	ld hl, Sfx1_04_Data_6623
	jp Sfx_Start

Sfx1_08_Data_6640:
	db $00, $b0, $f1, $b6, $c7
Sfx1_08_Data_6645:
	db $00, $b0, $f1, $c4, $c7
Sfx1_08_Data_664A:
	db $00, $b0, $f1, $ce, $c7
Sfx1_08_Data_664F:
	db $00, $b0, $f1, $db, $c7
Sfx1_08_Init:
	call Sfx1_Is07
	ret z
	ld a, $07
	ld hl, Sfx1_08_Data_6640
	jp Sfx_Start

Sfx1_08_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $01
	jr z, .l0
	cp $02
	jr z, .l1
	cp $03
	jr z, .l2
	cp $04
	jr z, .l3
	cp $05
	jp z, Sfx1_Stop
	ret

.l0:
	ld hl, Sfx1_08_Data_6645
	jr .l4

.l1:
	ld hl, Sfx1_08_Data_664A
	jr .l4

.l2:
	ld hl, Sfx1_08_Data_664F
	jr .l4

.l3:
	ld hl, Sfx1_08_Data_6640
.l4:
	jp SetRegs_Ch1

Sfx1_06_Data_6695:
	db $3e, $80, $e3, $00, $c4
Sfx1_06_Data_669A:
	db $93, $83, $83, $73, $63
	db $53, $43, $33, $23, $13
	db $00
Sfx1_06_Data_66A5:
	db $00, $23, $43, $63, $83
	db $a3, $c3, $d3, $e3, $ff
Sfx1_06_Init:
	call Sfx3_Is01
	ret z
	call Sfx1_Is08
	ret z
	call Sfx1_Is07
	ret z
	ld a, $06
	ld hl, Sfx1_06_Data_6695
	jp Sfx_Start

Sfx1_06_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx1_06_Data_669A
	add hl, bc
	ld a, [hl]
	and a
	jp z, Sfx1_Stop
	ld e, a
	ld hl, Sfx1_06_Data_66A5
	add hl, bc
	ld a, [hl]
	ld d, a
	ld b, $86
Sfx1_WriteEnvPeriod:
	ld c, $12
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	ldh [c], a
	inc c
	ld a, b
	ldh [c], a
	ret

Sfx1_03_Data_66EC:
	db $3b, $80, $b2, $87, $87
Sfx1_03_Data_66F1:
	db $a2, $93, $62, $43, $23
	db $00
Sfx1_03_Data_66F7:
	db $80, $40, $80, $40, $80
Sfx1_03_Init:
	call Sfx3_Is01
	ret z
	call Sfx1_Is08
	ret z
	call Sfx1_Is07
	ret z
	call Sfx1_Is05
	ret z
	ld a, $03
	ld hl, Sfx1_03_Data_66EC
	jp Sfx_Start

Sfx1_03_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx1_03_Data_66F1
	add hl, bc
	ld a, [hl]
	and a
	jp z, Sfx1_Stop
	ld e, a
	ld hl, Sfx1_03_Data_66F7
	add hl, bc
	ld a, [hl]
	ld d, a
	ld b, $87
	jr Sfx1_WriteEnvPeriod

Sfx1_05_Init:
	call Sfx1_Is07
	ret z
	ld a, $28
	ld hl, Sfx1_05_Data_6740
	jp Sfx_Start

Sfx1_05_Data_6740:
	db $b7, $80, $90, $ff, $83
Sfx4_02_Data_6745:
	db $00, $d1, $45, $80
Sfx4_01_Data_6749:
	db $00, $f1, $54, $80
Sfx4_03_Data_674D:
	db $00, $d5, $65, $80
Sfx4_04_Data_6751:
	db $00, $70, $66, $80
Sfx4_04_Data_6755:
	db $65, $65, $65, $64, $57
	db $56, $55, $54, $54, $54
	db $54, $54, $47, $46, $46
	db $45, $45, $45, $44, $44
	db $44, $34, $34, $34, $34
	db $34, $34, $34, $34, $34
	db $34, $34, $34, $34, $34
	db $34
Sfx4_04_Data_6779:
	db $70, $60, $70, $70, $70
	db $80, $90, $a0, $d0, $f0
	db $e0, $d0, $c0, $b0, $a0
	db $90, $80, $70, $60, $50
	db $40, $30, $30, $20, $20
	db $20, $20, $20, $20, $20
	db $20, $20, $20, $20, $10
	db $10
Sfx4_03_Init:
	ld a, $30
	ld hl, Sfx4_03_Data_674D
	jp Sfx_Start

Sfx4_04_Init:
	ld a, $30
	ld hl, Sfx4_04_Data_6751
	jp Sfx_Start

Sfx4_04_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx4Step
	ld a, [hl]
	ld c, a
	cp $24
	jp z, Sfx4_Stop
	inc [hl]
	ld b, $00
	push bc
	ld hl, Sfx4_04_Data_6755
	add hl, bc
	ld a, [hl]
	ldh [rNR43], a
	pop bc
	ld hl, Sfx4_04_Data_6779
	add hl, bc
	ld a, [hl]
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

Sfx4_01_Init:
	ld a, $20
	ld hl, Sfx4_01_Data_6749
	jp Sfx_Start

Sfx4_02_Init:
	ld a, $12
	ld hl, Sfx4_02_Data_6745
	jp Sfx_Start

; also the per-frame routine of Sfx4_02
; also the per-frame routine of Sfx4_03
Sfx4_01_Play:
	call Sfx_Tick
	and a
	ret nz
Sfx4_Stop:
	xor a
	ld [wSfx4Playing], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld hl, wCh4Flags
	res 7, [hl]
	ret

Sfx3_02_Data_67FB:
	db $80, $3a, $20, $60, $c6
Sfx3_02_Init:
	ld hl, Wave_6ED9
	call Sfx3_Start
	ldh a, [rDIV]
	and $1f
	ld b, a
	ld a, $d0
	add a, b
	ld [wSfx3Var], a
	ld hl, Sfx3_02_Data_67FB
	jp SetRegs_Ch3

Sfx3_02_Play:
	ldh a, [rDIV]
	and $0f
	ld b, a
	ld hl, wSfx3Step
	inc [hl]
	ld a, [hl]
	ld hl, wSfx3Var
	cp $0e
	jr nc, .fall
	inc [hl]
	inc [hl]
.write:
	ld a, [hl]
	and $f0
	or b
	ld c, $1d
	ldh [c], a
	ret

.fall:
	cp $1e
	jp z, Sfx3_Stop
	dec [hl]
	dec [hl]
	dec [hl]
	jr .write

; ch3 effects (wSfx3Request 1-2) are code here, not a table: 1 and 2 use their own wave.
Sfx3_Update:
	ld a, [wSfx3Request]
	cp $01
	jp z, Sfx3_01_Init
	cp $02
	jp z, Sfx3_02_Init
	ld a, [wSfx3Playing]
	cp $01
	jp z, Sfx3_01_Play
	cp $02
	jp z, Sfx3_02_Play
	ret

Sfx3_01_Data_6857:
	db $80, $80, $20
Sfx3_01_Data_685A:
	db $9d, $87
Sfx3_01_Data_685C:
	db $80, $f8, $20
Sfx3_01_Data_685F:
	db $98, $87
Sfx3_01_Data_6861:
	db $80, $fb, $20
Sfx3_01_Data_6864:
	db $96, $87
Sfx3_01_Data_6866:
	db $80, $f6, $20
Sfx3_01_Data_6869:
	db $95, $87
Sfx3_01_Init:
	ld hl, Wave_6EA9
	call Sfx3_Start
	ld hl, Sfx3_01_Data_685A
	ld a, [hl]
	ld [wSfx3Var2], a
	ld a, $01
	ld [wSfx3Var], a
	ld hl, Sfx3_01_Data_6857
.write:
	jp SetRegs_Ch3

Sfx3_01_Play_step9:
	ld a, $00
	ld [wSfx3Var], a
	ld hl, Sfx3_01_Data_685F
	ld a, [hl]
	ld [wSfx3Var2], a
	ld hl, Sfx3_01_Data_685C
	jr Sfx3_01_Init.write

Sfx3_01_Play_step13:
	ld a, $01
	ld [wSfx3Var], a
	ld hl, Sfx3_01_Data_6864
	ld a, [hl]
	ld [wSfx3Var2], a
	ld hl, Sfx3_01_Data_6861
	jr Sfx3_01_Init.write

Sfx3_01_Play_step17:
	ld a, $02
	ld [wSfx3Var], a
	ld hl, Sfx3_01_Data_6869
	ld a, [hl]
	ld [wSfx3Var2], a
	ld hl, Sfx3_01_Data_6866
	jr Sfx3_01_Init.write

Sfx3_01_Play:
	ld hl, wSfx3Step
	inc [hl]
	ld a, [hl+]
	cp $09
	jr z, Sfx3_01_Play_step9
	cp $13
	jr z, Sfx3_01_Play_step13
	cp $17
	jr z, Sfx3_01_Play_step17
	cp $20
	jr z, Sfx3_Stop
	ld a, [hl+]
	cp $00
	ret z
	cp $01
	jr z, .up
	cp $02
	jr z, .down
	ret

.up:
	inc [hl]
	inc [hl]
	jr .write

.down:
	dec [hl]
	dec [hl]
.write:
	ld a, [hl]
	ldh [rNR33], a
	ret

; End a ch3 effect: the music gets ch1-ch4 back; reload the song's wave (song 5 uses
; $6EC9, others $6EE9).
Sfx3_Stop:
	xor a
	ld [wSfx3Playing], a
	ldh [rNR30], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld hl, wCh1Flags
	res 7, [hl]
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, wCh4Flags
	res 7, [hl]
	ld a, [wSongPlaying]
	cp $05
	jr z, .song05
	ld hl, Wave_6EE9
	jr Sfx3_LoadWave

.song05:
	ld hl, Wave_6EC9
	jr Sfx3_LoadWave

; Start a ch3 effect: take ch1, ch2, ch3 and ch4 from the music and load the effect's wave.
Sfx3_Start:
	push hl
	ld [wSfx3Playing], a
	ld hl, wCh3Flags
	set 7, [hl]
	xor a
	ld [wSfx3Step], a
	ld [wSfx3Var], a
	ld [wSfx3Var2], a
	ldh [rNR30], a
	ld hl, wCh1Flags
	set 7, [hl]
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, wCh4Flags
	set 7, [hl]
	pop hl
Sfx3_LoadWave:
	call LoadWave
	ret

; Start an effect: a = frames per step, hl = first register image, de = &request.
; Stores the effect id as playing, the frame count, clears the timer and step, and writes
; the image to ch1 / ch3 / ch4 (chosen by e).
Sfx_Start:
	push af
	dec e
	ld a, [wSfxId]
	ld [de], a
	inc e
	pop af
	inc e
	ld [de], a
	dec e
	xor a
	ld [de], a
	inc e
	inc e
	ld [de], a
	inc e
	ld [de], a
	ld a, e
	cp $e5
	jr z, SetRegs_Ch1
	cp $f5
	jr z, SetRegs_Ch3
	cp $fd
	jr z, SetRegs_Ch4
	ret

SetRegs_Ch1:
	push bc
	ld c, $10
	ld b, $05
	jr SetRegs_Copy

SetRegs_Ch2:
	push bc
	ld c, $16
	ld b, $04
	jr SetRegs_Copy

SetRegs_Ch3:
	push bc
	ld c, $1a
	ld b, $05
	jr SetRegs_Copy

SetRegs_Ch4:
	push bc
	ld c, $20
	ld b, $04
SetRegs_Copy:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, SetRegs_Copy
	pop bc
	ret

Sfx_GetInitPointer:
	inc e
	ld [wSfxId], a
GetPointer:
	inc e
	dec a
	sla a
	ld c, a
	ld b, $00
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld l, c
	ld h, b
	ld a, h
	ret

; Count the frame timer up to the step length; a = 0 when a step ends.
Sfx_Tick:
	push de
	ld l, e
	ld h, d
	inc [hl]
	ld a, [hl+]
	cp [hl]
	jr nz, .done
	dec l
	xor a
	ld [hl], a
.done:
	pop de
	ret

LoadWave:
	push bc
	ld c, $30
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jr nz, .loop
	pop bc
	ret

; Stop everything: effects, music, panning; mute.
Sound_Stop:
	xor a
	ld [wSfx1Playing], a
	ld [wSongPlaying], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld [wCh1Flags], a
	ld [wCh2Flags], a
	ld [wCh3Flags], a
	ld [wCh4Flags], a
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
Sound_MuteChannels:
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	xor a
	ldh [rNR10], a
	ldh [rNR30], a
	ret

Sfx1_Update:
	ld de, wSfx1Request
	ld a, [de]
	and a
	jr z, .playing
	ld hl, wCh1Flags
	set 7, [hl]
	ld hl, Sfx1_InitTable
	call Sfx_GetInitPointer
	jp hl

.playing:
	inc e
	ld a, [de]
	and a
	jr z, .done
	ld hl, Sfx1_PlayTable
	call GetPointer
	jp hl

.done:
	ret

Sfx4_Update:
	ld de, wSfx4Request
	ld a, [de]
	and a
	jr z, .playing
	ld hl, wCh4Flags
	set 7, [hl]
	ld hl, Sfx4_InitTable
	call Sfx_GetInitPointer
	jp hl

.playing:
	inc e
	ld a, [de]
	and a
	jr z, .done
	ld hl, Sfx4_PlayTable
	call GetPointer
	jp hl

.done:
	ret

Music_Stop:
	call Sound_Stop
	ret

; a = song 1-17, $FF = stop. Loads the header and the panning.
Music_StartSong:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	ret z
	cp $ff
	jr z, Music_Stop
	ld [hl], a
	ld b, a
	ld hl, SongTable
	and $1f
	call GetPointer
	call Music_LoadHeader
	call Music_InitPanning
	ret

; Panning per song: mode (1 fixed A, 2 alternate A/B every period frames, 3 = $FF), period,
; NR51 A, NR51 B. While an SFX plays on ch3 or ch4 those channels stay on both sides.
Music_InitPanning:
	ld a, [wSongPlaying]
	and a
	ret z
	ld hl, SongPanTable
.find:
	dec a
	jr z, .found
	inc hl
	inc hl
	inc hl
	inc hl
	jr .find

.found:
	ld a, [hl+]
	ld [wPanMode], a
	ld a, [hl+]
	ld [wPanPeriod], a
	ld a, [hl+]
	ld [wPanNR51A], a
	ld a, [hl+]
	ld [wPanNR51B], a
	xor a
	ld [wPanTimer], a
	ld [wPanToggle], a
	ret

Music_UpdatePanning:
	ld a, [wSongPlaying]
	and a
	jr z, .all
	ld hl, wPanTimer
	ld a, [wPanMode]
	cp $01
	jr z, .fixed
	cp $03
	jr z, .all
	inc [hl]
	ld a, [hl+]
	cp [hl]
	jr nz, .idle
	dec l
	ld [hl], $00
	inc l
	inc l
	inc [hl]
	ld a, [wPanNR51A]
	bit 0, [hl]
	jp z, .addSfx
	ld a, [wPanNR51B]
.addSfx:
	ld b, a
	ld a, [wSfx3Playing]
	and a
	jr z, .ch4
	set 2, b
	set 6, b
.ch4:
	ld a, [wSfx4Playing]
	and a
	jr z, .write
	set 3, b
	set 7, b
.write:
	ld a, b
.store:
	ldh [rNR51], a
	ret

.all:
	ld a, $ff
	jr .store

.fixed:
	ld a, [wPanNR51A]
	jr .addSfx

.idle:
	ld a, [wSfx4Playing]
	and a
	jr nz, .all
	ld a, [wSfx3Playing]
	and a
	jr nz, .all
	ret

SongPanTable:
	db $01, $24, $ef, $56	; song 1: mode, period, NR51 A, NR51 B
	db $01, $00, $e5, $00	; song 2: mode, period, NR51 A, NR51 B
	db $01, $20, $fd, $00	; song 3: mode, period, NR51 A, NR51 B
	db $01, $20, $de, $f7	; song 4: mode, period, NR51 A, NR51 B
	db $03, $18, $7f, $f7	; song 5: mode, period, NR51 A, NR51 B
	db $03, $18, $f7, $7f	; song 6: mode, period, NR51 A, NR51 B
	db $03, $48, $df, $5b	; song 7: mode, period, NR51 A, NR51 B
	db $01, $18, $db, $e7	; song 8: mode, period, NR51 A, NR51 B
	db $01, $00, $fd, $f7	; song 9: mode, period, NR51 A, NR51 B
	db $03, $20, $7f, $f7	; song 10: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $f7	; song 11: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $f7	; song 12: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $f7	; song 13: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $f7	; song 14: mode, period, NR51 A, NR51 B
	db $01, $20, $ed, $f7	; song 15: mode, period, NR51 A, NR51 B
	db $01, $20, $ef, $f7	; song 16: mode, period, NR51 A, NR51 B
	db $01, $20, $ef, $f7	; song 17: mode, period, NR51 A, NR51 B
CopyWordIndirect:
	ld a, [hl+]
	ld c, a
	ld a, [hl]
	ld b, a
	ld a, [bc]
	ld [de], a
	inc e
	inc bc
	ld a, [bc]
	ld [de], a
	ret

CopyWord:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl+]
	ld [de], a
	ret

Music_LoadHeader:
	call Sound_MuteChannels
	xor a
	ld [wPanTimer], a
	ld [wPanToggle], a
	ld de, wTranspose
	ld b, $00
	ld a, [hl+]
	ld [de], a
	inc e
	call CopyWord
	ld de, wCh1ListPtr
	call CopyWord
	ld de, wCh2ListPtr
	call CopyWord
	ld de, wCh3ListPtr
	call CopyWord
	ld de, wCh4ListPtr
	call CopyWord
	ld hl, wCh1ListPtr
	ld de, wCh1PatPtr
	call CopyWordIndirect
	ld hl, wCh2ListPtr
	ld de, wCh2PatPtr
	call CopyWordIndirect
	ld hl, wCh3ListPtr
	ld de, wCh3PatPtr
	call CopyWordIndirect
	ld hl, wCh4ListPtr
	ld de, wCh4PatPtr
	call CopyWordIndirect
	ld bc, $0410
	ld hl, wCh1LenCounter
.initCounters:
	ld [hl], $01
	ld a, c
	add a, l
	ld l, a
	dec b
	jr nz, .initCounters
	xor a
	ld [wCh1NoteFrames], a
	ld [wCh2NoteFrames], a
	ld [wCh3NoteFrames], a
	ret

Cmd_Instrument_wave:
	push hl
	xor a
	ldh [rNR30], a
	ld l, e
	ld h, d
	call LoadWave
	pop hl
	jr Music_NextByte

Cmd_Instrument:
	call IncPtr
	call ReadPtrByte
	ld e, a
	call IncPtr
	call ReadPtrByte
	ld d, a
	call IncPtr
	call ReadPtrByte
	ld c, a
	inc l
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], c
	dec l
	dec l
	dec l
	dec l
	push hl
	ld hl, wMusicChannel
	ld a, [hl]
	pop hl
	cp $03
	jr z, Cmd_Instrument_wave
Music_NextByte:
	call IncPtr
	jp Music_ReadCommand

IncPtr:
	push de
	ld a, [hl+]
	ld e, a
	ld a, [hl-]
	ld d, a
	inc de
.store:
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl-], a
	pop de
	ret

IncPtr2:
	push de
	ld a, [hl+]
	ld e, a
	ld a, [hl-]
	ld d, a
	inc de
	inc de
	jr IncPtr.store

ReadPtrByte:
	ld a, [hl+]
	ld c, a
	ld a, [hl-]
	ld b, a
	ld a, [bc]
	ld b, a
	ret

Music_Sustain_skip:
	pop hl
	jr Music_ChannelDone

Music_Sustain:
	ld a, [wMusicChannel]
	cp $03
	jr nz, .effects
	ld a, [wCh3InstrDuty]
	bit 7, a
	jr z, .effects
	ld a, [hl]
	cp $06
	jr nz, .effects
	ld a, $40
	ldh [rNR32], a
.effects:
	push hl
	ld a, l
	add a, $09
	ld l, a
	ld a, [hl]
	and a
	jr nz, Music_Sustain_skip
	ld a, l
	add a, $04
	ld l, a
	bit 7, [hl]
	jr nz, Music_Sustain_skip
	pop hl
	call Music_Vibrato
Music_ChannelDone:
	dec l
	dec l
	jp Music_NextChannel

Cmd_PatternEnd:
	dec l
	dec l
	dec l
	dec l
	call IncPtr2
.loadPattern:
	ld a, l
	add a, $04
	ld e, a
	ld d, h
	call CopyWordIndirect
	cp $00
	jr z, .songEnd
	cp $ff
	jr z, .loop
	inc l
	jp Music_ReadPattern

.loop:
	dec l
	push hl
	call IncPtr2
	call ReadPtrByte
	ld e, a
	call IncPtr
	call ReadPtrByte
	ld d, a
	pop hl
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl-], a
	jr .loadPattern

.songEnd:
	ld hl, wSongPlaying
.stop:
	ld [hl], $00
	call Sound_Stop
	ret

Music_Update:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, $01
	ld [wMusicChannel], a
	ld hl, wCh1ListPtr
Music_ChannelLoop:
	inc l
	ld a, [hl+]
	and a
	jp z, Music_ChannelDone
	dec [hl]
	jp nz, Music_Sustain
Music_ReadPattern:
	inc l
	inc l
; Commands: only $9D. Lengths $A0-$AF, notes, rest $01, $00 = next list entry.
Music_ReadCommand:
	call ReadPtrByte
	cp $00
	jp z, Cmd_PatternEnd
	cp $9d
	jp z, Cmd_Instrument
	and $f0
	cp $a0
	jr nz, Music_Note
	ld a, b
	and $0f
	ld c, a
	ld b, $00
	push hl
	ld de, wLengthTable
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	add hl, bc
	ld a, [hl]
	pop hl
	dec l
	ld [hl+], a
	call IncPtr
	call ReadPtrByte
; No transpose: the header's first byte is stored in wTranspose but never read.
Music_Note:
	ld a, b
	ld c, a
	ld b, $00
	call IncPtr
	ld a, [wMusicChannel]
	cp $04
	jp z, Music_NoiseNote
	push hl
	ld a, l
	add a, $05
	ld l, a
	ld e, l
	ld d, h
	inc l
	inc l
	ld a, c
	cp $01
	jr z, .rest
	ld [hl], $00
.lookup:
	ld hl, NoteTable
	add hl, bc
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl]
	ld [de], a
	pop hl
	jp Music_Trigger

.rest:
	ld [hl], $01
	pop hl
	jr Music_Trigger

Music_NoiseNote:
	push hl
	ld de, wCh4InstrEnv
	ld hl, NoiseTable
	add hl, bc
.copy:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, e
	cp $cb
	jr nz, .copy
	ld c, $20
	ld hl, wCh4PatPtr
	jr Music_Trigger.readInstr

Music_Trigger:
	push hl
	ld a, [wMusicChannel]
	cp $01
	jr z, .ch1
	cp $02
	jr z, .ch2
	ld c, $1a
	ld a, [wCh3Flags]
	bit 7, a
	jr nz, .ch3
	xor a
	ldh [c], a
	ld a, $80
	ldh [c], a
.ch3:
	inc c
	inc l
	inc l
	inc l
	inc l
	ld a, [hl+]
	ld e, a
	ld d, $00
	jr .write

.ch2:
	ld c, $16
	jr .readInstr

.ch1:
	ld c, $10
	ld a, $00
	inc c
.readInstr:
	inc l
	inc l
	inc l
	ld a, [hl-]
	and a
	jr nz, Music_Trigger_flagSet
	ld a, [hl+]
	ld e, a
.readDuty:
	inc l
	ld a, [hl+]
	ld d, a
.write:
	push hl
	inc l
	inc l
	ld a, [hl+]
	and a
	jr z, .notRest
	ld e, $01
.notRest:
	inc l
	inc l
	ld [hl], $00
	inc l
	ld a, [hl]
	pop hl
	bit 7, a
	jr nz, .done
	ld a, d
	ldh [c], a
	inc c
	ld a, e
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl]
	or $80
	ldh [c], a
	ld a, l
	or $05
	ld l, a
	res 0, [hl]
.done:
	pop hl
	dec l
	ld a, [hl-]
	ld [hl-], a
	dec l
Music_NextChannel:
	ld de, wMusicChannel
	ld a, [de]
	cp $04
	jr z, .allDone
	inc a
	ld [de], a
	ld de, $0010
	add hl, de
	jp Music_ChannelLoop

.allDone:
	ld hl, wCh1NoteFrames
	inc [hl]
	ld hl, wCh2NoteFrames
	inc [hl]
	ld hl, wCh3NoteFrames
	inc [hl]
	ret

Music_Trigger_flagSet:
	ld b, $00
	push hl
	pop hl
	inc l
	jr Music_Trigger.readDuty

Vibrato_GetStep:
	ld a, b
	srl a
	ld l, a
	ld h, $00
	add hl, de
	ld e, [hl]
	ret

; Pitch effect from the low nibble of InstrDuty (third INSTR byte). Any non-zero value gives
; the vibrato: VibratoTable, one signed nibble per frame, indexed by NoteFrames / 2 (the type
; test is followed by an unconditional jr). wSfxId is borrowed as scratch for the type.
Music_Vibrato:
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	and $0f
	jr z, .done
	ld [wSfxId], a
	ld a, [wMusicChannel]
	ld c, $13
	cp $01
	jr z, .apply
	ld c, $18
	cp $02
	jr z, .apply
	ld c, $1d
	cp $03
	jr z, .apply
.done:
	pop hl
	ret

.apply:
	inc l
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	ld a, l
	add a, $04
	ld l, a
	ld b, [hl]
	ld a, [wSfxId]
	cp $01
	jr .type1

; unreachable (the jr above always jumps): a fixed offset of -1 for type 3
; (Dr. Mario has the same code with -2 and makes it reachable)
.unusedType3:
	cp $03
	jr .unusedFixed

.unusedFixed:
	ld hl, $ffff
	jr .add

.type1:
	ld de, VibratoTable
.readTable:
	call Vibrato_GetStep
	bit 0, b
	jr nz, .nibble
	swap e
.nibble:
	ld a, e
	and $0f
	bit 3, a
	jr z, .positive
	ld h, $ff
	or $f0
	jr .signed

.positive:
	ld h, $00
.signed:
	ld l, a
.add:
	pop de
	add hl, de
	ld a, l
	ldh [c], a
	inc c
	ld a, h
	ldh [c], a
	jr .done

