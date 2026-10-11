; Super Mario Land sound driver: tables, code and SFX data, bank 3 $6700-$6F38

; SFX on ch1 (wSfx1Request = 1-11): init routine, then per-frame routine
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
Sfx1_PlayTable:
	dw Sfx1_01_Play
	dw Sfx1_PlayOneStep
	dw Sfx1_03_Play
	dw Sfx1_04_Play
	dw Sfx1_05_Play
	dw Sfx1_06_Play
	dw Sfx1_PlayOneStep
	dw Sfx1_08_Play
	dw Sfx1_PlayOneStep
	dw Sfx1_PlayOneStep
	dw Sfx1_04_Play
; SFX on ch4 (wSfx4Request = 1-4)
Sfx4_InitTable:
	dw Sfx4_01_Init
	dw Sfx4_02_Init
	dw Sfx4_03_Init
	dw Sfx4_04_Init
Sfx4_PlayTable:
	dw Sfx4_PlayOneStep
	dw Sfx4_PlayOneStep
	dw Sfx4_03_Play
	dw Sfx4_PlayOneStep
; song number 1-19 -> header
SongTable:
	dw Song01_Header
	dw Song02_Header
	dw Song03_Header
	dw Song04_Header
	dw Song05_Header
	dw Song06_Header
	dw Song07_Header
	dw Song08_Header
	dw Song09_Header
	dw Song10_Header
	dw Song11_Header
	dw Song12_Header
	dw Song13_Header
	dw Song14_Header
	dw Song15_Header
	dw Song16_Header
	dw Song17_Header
	dw Song18_Header
	dw Song19_Header
; Stub at $7FF0. Called from the timer interrupt: it enables VBlank/STAT interrupts
; only (IE = 3) while it runs and returns with IE = 7, reti.
; Order: pause request -> pause jingle -> hSfx08Request -> SFX ch1 -> SFX ch4 -> SFX ch3
; -> song request -> music -> panning, then clear every request.
Sound_Update:
	push af
	push bc
	push de
	push hl
	ld a, $03
	ldh [rIE], a
	ei
	ldh a, [hPauseRequest]
	cp $01
	jr z, .pause
	cp $02
	jr z, .unpause
	ldh a, [hPauseTimer]
	and a
	jr nz, .paused
	ld c, $d3
	ldh a, [c]
	and a
	jr z, .main
	xor a
	ldh [c], a
	ld a, $08
	ld [wSfx1Request], a
.main:
	call Sfx1_Update
	call Sfx4_Update
	call Sfx3_Update
	call Music_CheckRequest
	call Music_Update
	call Music_UpdatePanning
.done:
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ldh [hPauseRequest], a
	ld a, $07
	ldh [rIE], a
	pop hl
	pop de
	pop bc
	pop af
	reti

; Pause: mute, cancel the effects and play a 4-note jingle on ch2 (frames $30, $28,
; $20, $18), then hold the timer at $10 until resumed.
.pause:
	call Sound_MuteChannels
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld a, $30
	ldh [hPauseTimer], a
.jingleA:
	ld hl, PauseJingleA
.writeJingle:
	call SetRegs_Ch2
	jr .done

.jingleB:
	ld hl, PauseJingleB
	jr .writeJingle

.unpause:
	xor a
	ldh [hPauseTimer], a
	jr .main

.paused:
	ld hl, hPauseTimer
	dec [hl]
	ld a, [hl]
	cp $28
	jr z, .jingleB
	cp $20
	jr z, .jingleA
	cp $18
	jr z, .jingleB
	cp $10
	jr nz, .done
	inc [hl]
	jr .done

; NR21-NR24 image
PauseJingleA:
	db $b2, $e3, $83, $c7
; NR21-NR24 image
PauseJingleB:
	db $b2, $e3, $c1, $c7
; The only ch3 effect: random start pitch (DIV), rises 14 steps, falls until step 30;
; then the song's wave is reloaded (pointer kept in wCh3InstrEnv/Flag).
Sfx3_Update:
	ld a, [wSfx3Request]
	cp $01
	jr z, Sfx3_01_Init
	ld a, [wSfx3Playing]
	cp $01
	jr z, Sfx3_01_Play
	ret

; NR30-NR34 image
Sfx3_01_Regs:
	db $80, $3a, $20, $b0, $c6
Sfx3_01_Init:
	ld [wSfx3Playing], a
	ld hl, wCh3Flags
	set 7, [hl]
	xor a
	ld [wSfx3Step], a
	ldh [rNR30], a
	ld hl, Wave_7047
	call LoadWave
	ldh a, [rDIV]
	and $1f
	ld b, a
	ld a, $d0
	add a, b
	ld [wSfx3Pitch], a
	ld hl, Sfx3_01_Regs
	jp SetRegs_Ch3

Sfx3_01_Play:
	ldh a, [rDIV]
	and $07
	ld b, a
	ld hl, wSfx3Step
	inc [hl]
	ld a, [hl]
	ld hl, wSfx3Pitch
	cp $0e
	jr nc, .down
	inc [hl]
	inc [hl]
.write:
	ld a, [hl]
	and $f8
	or b
	ld c, $1d
	ldh [c], a
	ret

.down:
	cp $1e
	jr z, .stop
	dec [hl]
	dec [hl]
	dec [hl]
	jr .write

.stop:
	xor a
	ld [wSfx3Playing], a
	ldh [rNR30], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld bc, wCh3InstrEnv
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld h, a
	call LoadWave
	ret

; NR10-NR14 image
Sfx1_0A_Regs:
	db $00, $b0, $53, $80, $c7
Sfx1_0A_Init:
	ld a, $03
	ld hl, Sfx1_0A_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_09_Regs:
	db $3c, $80, $a0, $50, $84
Sfx1_09_Init:
	call Sfx1_IsBusy_4568B
	ret z
	ld a, $0e
	ld hl, Sfx1_09_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_01_Regs:
	db $00, $80, $d2, $0a, $86
; NR10-NR14 image
Sfx1_02_Regs:
	db $3d, $80, $a3, $09, $87
; Priority checks on the ch1 effect playing: Z = do not start.
Sfx1_IsBusy_468B:
	ld a, [wSfx1Playing]
	jr Sfx1_IsBusy_Check

Sfx1_IsBusy_34568B:
	ld a, [wSfx1Playing]
	cp $03
	ret z
Sfx1_IsBusy_4568B:
	ld a, [wSfx1Playing]
	cp $05
	ret z
Sfx1_IsBusy_Check:
	cp $04
	ret z
	cp $06
	ret z
	cp $08
	ret z
	cp $0b
	ret z
	ret

; Effect 1: the period word in wSfx1Step/Var starts at $860A and rises by 15 every frame
; for 16 frames.
Sfx1_01_Init:
	call Sfx1_IsBusy_34568B
	ret z
	ld a, $10
	ld hl, Sfx1_01_Regs
	call Sfx_Start
	ld hl, wSfx1Step
	ld [hl], $0a
	inc l
	ld [hl], $86
	ret

Sfx1_01_Play:
	call Sfx_Tick
	and a
	jp z, Sfx1_Stop
	ld hl, wSfx1Step
	ld e, [hl]
	inc l
	ld d, [hl]
	push hl
	ld hl, $000f
	add hl, de
	ld c, $13
	ld a, l
	ldh [c], a
	ld b, a
	inc c
	ld a, h
	and $3f
	ldh [c], a
	pop hl
	ld [hl-], a
	ld [hl], b
	ret

Sfx1_02_Init:
	call Sfx1_IsBusy_34568B
	ret z
	ld a, $03
	ld hl, Sfx1_02_Regs
	jp Sfx_Start

; Shared per-frame routine of one-image effects (2, 7, 9, 10): stop when the period elapses.
Sfx1_PlayOneStep:
	call Sfx_Tick
	and a
	ret nz
Sfx1_Stop:
	xor a
	ld [wSfx1Playing], a
	ldh [rNR10], a
	ldh [rNR12], a
	ld hl, wCh1Flags
	res 7, [hl]
	ret

; NR10-NR14 image
Sfx1_05_Regs1:
	db $00, $80, $e2, $06, $87
; NR10-NR14 image
Sfx1_05_Regs2:
	db $00, $80, $e2, $83, $87
Sfx1_05_Init:
	call Sfx1_IsBusy_468B
	ret z
	ld hl, Sfx1_05_Regs1
	jp Sfx_Start

; Effect 5: counts frames itself (no period): image 2 at frame 4, stop at 24.
Sfx1_05_Play:
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $04
	jr z, .l0
	cp $18
	jp z, Sfx1_Stop
	ret

.l0:
	ld hl, Sfx1_05_Regs2
	call SetRegs_Ch1
	ret

; NR10-NR14 image
Sfx1_03_Regs1:
	db $57, $96, $8c, $30, $c7
; NR10-NR14 image
Sfx1_03_Regs2:
	db $57, $96, $8c, $35, $c7
Sfx1_03_Init:
	call Sfx1_IsBusy_4568B
	ret z
	ld a, $08
	ld hl, Sfx1_03_Regs1
	jp Sfx_Start

Sfx1_03_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld a, [hl]
	inc [hl]
	cp $00
	jr z, .l0
	cp $01
	jp z, Sfx1_Stop
	ret

.l0:
	ld hl, Sfx1_03_Regs2
	jp SetRegs_Ch1

; NR10-NR14 image
Sfx1_0B_Regs:
	db $54, $00, $9a, $20, $87
Sfx1_0B_Init:
	ld a, $60
	ld [wSfx1Var2], a
	ld a, $05
	ld hl, Sfx1_0B_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_04_Regs:
	db $27, $80, $8a, $10, $86
Sfx1_04_Init:
	ld a, $10
	ld [wSfx1Var2], a
	ld a, $05
	ld hl, Sfx1_04_Regs
	jp Sfx_Start

; Effects 4 and 11: NR13 = wSfx1Var2 + $10 every 5 frames, until $E0.
Sfx1_04_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Var2
	ld a, $10
	add a, [hl]
	ld [hl], a
	cp $e0
	jp z, Sfx1_Stop
	ld c, $13
	ldh [c], a
	inc c
	ld a, $86
	ldh [c], a
	ret

; NR10-NR14 image
Sfx1_07_Regs:
	db $2c, $80, $d3, $40, $84
Sfx1_07_Init:
	call Sfx1_IsBusy_4568B
	ret z
	ld a, $08
	ld hl, Sfx1_07_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_06_Regs:
	db $3a, $80, $e3, $20, $86
; NR12 per step, 0 = end
Sfx1_06_Env:
	db $f3, $b3, $a3, $93, $83, $73, $63, $53, $43, $33, $23, $23, $13, $00
Sfx1_06_Init:
	ld a, [wSfx1Playing]
	cp $08
	ret z
	ld a, $06
	ld hl, Sfx1_06_Regs
	jp Sfx_Start

Sfx1_06_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx1_06_Env
	add hl, bc
	ld a, [hl]
	and a
	jp z, Sfx1_Stop
	ld c, $12
	ldh [c], a
	inc c
	inc c
	ld a, $87
	ldh [c], a
	ret

Sfx1_08_Init:
	ld a, $06
	ld hl, Sfx1_08_Regs1
	jp Sfx_Start

; NR10-NR14 image
Sfx1_08_Regs1:
	db $00, $30, $f0, $a7, $c7
; NR10-NR14 image
Sfx1_08_Regs2:
	db $00, $30, $f0, $b1, $c7
; NR10-NR14 image
Sfx1_08_Regs3:
	db $00, $30, $f0, $ba, $c7
; NR10-NR14 image
Sfx1_08_Regs4:
	db $00, $30, $f0, $c4, $c7
; NR10-NR14 image
Sfx1_08_Regs5:
	db $00, $30, $f0, $d4, $c7
; NR10-NR14 image
Sfx1_08_Regs6:
	db $00, $30, $f0, $cb, $c7
Sfx1_08_Play:
	call Sfx_Tick
	and a
	ret nz
	ld a, [wSfx1Step]
	inc a
	ld [wSfx1Step], a
	cp $01
	jr z, .l0
	cp $02
	jr z, .l1
	cp $03
	jr z, .l2
	cp $04
	jr z, .l3
	cp $05
	jr z, .l4
	jp Sfx1_Stop

.l0:
	ld hl, Sfx1_08_Regs2
	jr .l5

.l1:
	ld hl, Sfx1_08_Regs3
	jr .l5

.l2:
	ld hl, Sfx1_08_Regs4
	jr .l5

.l3:
	ld hl, Sfx1_08_Regs5
	jr .l5

.l4:
	ld hl, Sfx1_08_Regs6
.l5:
	jp SetRegs_Ch1

; NR41-NR44 image
Sfx4_01_Regs:
	db $00, $f4, $57, $80
Sfx4_01_Init:
	ld a, $30
	ld hl, Sfx4_01_Regs
	jp Sfx_Start

; Z while ch4 effect 1 plays.
Sfx4_IsBusy_1:
	ld a, [wSfx4Playing]
	cp $01
	ret z
	ret

; NR41-NR44 image
Sfx4_03_Regs:
	db $00, $2c, $1e, $80
; NR43 per step, 0 = end
Sfx4_03_NR43:
	db $1f, $2d, $2f, $3d, $3f, $00
Sfx4_03_Init:
	call Sfx4_IsBusy_1
	ret z
	ld a, $06
	ld hl, Sfx4_03_Regs
	jp Sfx_Start

Sfx4_03_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx4Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx4_03_NR43
	add hl, bc
	ld a, [hl]
	and a
	jr z, Sfx4_Stop
	ldh [rNR43], a
	ret

; NR41-NR44 image
Sfx4_04_Regs:
	db $00, $6d, $54, $80
Sfx4_04_Init:
	ld a, $16
	ld hl, Sfx4_04_Regs
	jp Sfx_Start

; NR41-NR44 image
Sfx4_02_Regs:
	db $00, $f2, $55, $80
Sfx4_02_Init:
	call Sfx4_IsBusy_1
	ret z
	ld a, $15
	ld hl, Sfx4_02_Regs
	jp Sfx_Start

; Shared per-frame routine of ch4 effects 1, 2, 4.
Sfx4_PlayOneStep:
	call Sfx_Tick
	and a
	ret nz
Sfx4_Stop:
	xor a
	ld [wSfx4Playing], a
	ldh [rNR42], a
	ld hl, wCh4Flags
	res 7, [hl]
	ret

; Start an effect: a = frames per step, hl = register image, de = wSfxNRequest+2.
Sfx_Start:
	push af
	dec e
	ldh a, [hSfxId]
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
	ldh [hSfxId], a
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

; Count frames: a = 0 once every wSfxNPeriod frames.
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

; Stub at $7FF3. Stop everything; NR51 = $FF, panning mode 3.
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
	ldh [hPauseRequest], a
	ldh [hPauseTimer], a
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ldh [hPanMode], a
; Envelope $01 on ch1/ch2/ch4 (no retrigger), sweep off, ch3 off.
Sound_MuteChannels:
	ld a, $01
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
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

Music_StopSong:
	call Sound_Stop
	ret

; Start a requested song ($FF = stop). No range check.
Music_CheckRequest:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	ret z
	ld [hl], a
	cp $ff
	jr z, Music_StopSong
	ld b, a
	ld hl, SongTable
	ld a, b
	and $1f
	call GetPointer
	call Music_LoadHeader
	call Music_InitPanning
	ret

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
	ldh [hPanMode], a
	ld a, [hl+]
	ldh [hPanPeriod], a
	ld a, [hl+]
	ldh [hPanNR51A], a
	ld a, [hl+]
	ldh [hPanNR51B], a
	xor a
	ldh [hPanTimer], a
	ldh [hPanToggle], a
	ret

; While ch4 effect 1 plays, NR51 alternates $F7 / $7F every 2 frames (noise
; bounces left/right).
Music_Sfx4Panning:
	ld a, [wSfx4Playing]
	cp $01
	ret nz
	ld a, [hl]
	bit 1, a
	ld a, $f7
	jr z, .write
	ld a, $7f
.write:
	call WriteNR51
	ret

; Panning per song: mode 1 = fixed, 3 = all channels both sides, else alternate A/B
; every period frames. hGameState 5 forces NR51 = $FF.
Music_UpdatePanning:
	ld a, [wSongPlaying]
	and a
	jr z, WriteNR51_All
	ld hl, hPanTimer
	call Music_Sfx4Panning
	ld a, [hGameState]
	cp $05
	jr z, WriteNR51_All
	ldh a, [hPanMode]
	cp $01
	jr z, WriteNR51_A
	cp $03
	jr z, WriteNR51_All
	inc [hl]
	ld a, [hl+]
	cp [hl]
	ret nz
	dec l
	ld [hl], $00
	inc l
	inc l
	inc [hl]
	ldh a, [hPanNR51A]
	bit 0, [hl]
	jp z, WriteNR51
	ldh a, [hPanNR51B]
WriteNR51:
	ld c, $25
	ldh [c], a
	ret

WriteNR51_All:
	ld a, $ff
	jr WriteNR51

WriteNR51_A:
	ldh a, [hPanNR51A]
	jr WriteNR51

SongPanTable:
	db $02, $24, $65, $56	; song 01: mode, period, NR51 A, NR51 B
	db $01, $00, $bd, $00	; song 02: mode, period, NR51 A, NR51 B
	db $02, $20, $7f, $b7	; song 03: mode, period, NR51 A, NR51 B
	db $01, $00, $ed, $00	; song 04: mode, period, NR51 A, NR51 B
	db $02, $18, $7f, $f7	; song 05: mode, period, NR51 A, NR51 B
	db $02, $40, $7f, $f7	; song 06: mode, period, NR51 A, NR51 B
	db $02, $40, $7f, $f7	; song 07: mode, period, NR51 A, NR51 B
	db $03, $18, $7f, $f7	; song 08: mode, period, NR51 A, NR51 B
	db $03, $10, $5a, $a5	; song 09: mode, period, NR51 A, NR51 B
	db $01, $00, $65, $00	; song 10: mode, period, NR51 A, NR51 B
	db $03, $00, $00, $00	; song 11: mode, period, NR51 A, NR51 B
	db $02, $08, $7f, $b5	; song 12: mode, period, NR51 A, NR51 B
	db $01, $00, $ed, $00	; song 13: mode, period, NR51 A, NR51 B
	db $01, $00, $ed, $00	; song 14: mode, period, NR51 A, NR51 B
	db $03, $00, $00, $00	; song 15: mode, period, NR51 A, NR51 B
	db $01, $00, $ed, $00	; song 16: mode, period, NR51 A, NR51 B
	db $02, $18, $7e, $e7	; song 17: mode, period, NR51 A, NR51 B
	db $01, $18, $ed, $e7	; song 18: mode, period, NR51 A, NR51 B
	db $01, $00, $de, $00	; song 19: mode, period, NR51 A, NR51 B
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

; hl = song header: transpose (stored, never used), length table, four lists.
Music_LoadHeader:
	call Sound_MuteChannels
	xor a
	ld [hPanTimer], a
	ld [hPanToggle], a
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

; $9D: the only command. Three bytes to wChNInstrEnv/Flag/Duty; on ch3 the first two
; are a wave pointer, loaded now.
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
	ld hl, hMusicChannel
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

; Frame without a new note: ch3 with level bit 7 drops to 50% 6 frames before the end;
; then the pitch effect, unless resting or taken by an effect.
Music_Sustain:
	ldh a, [hMusicChannel]
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

; $00: next entry of the section list. $00xx ends the song (music stops, channels are
; muted with envelope $01); $FFxx loops to the address that follows.
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
	ld [hl], $00
	call Sound_MuteChannels
	ret

; Music: four 16-byte channel structures at wCh1ListPtr + $10*n.
Music_Update:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, $01
	ldh [hMusicChannel], a
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
; Commands: $00, $9D, $A0-$AF lengths; everything else is a note (rest = $01).
; The header transpose is not applied.
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
Music_Note:
	ld a, b
	ld c, a
	ld b, $00
	call IncPtr
	ldh a, [hMusicChannel]
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
	cp $4b
	jr nz, .copy
	ld c, $20
	ld hl, wCh4PatPtr
	jr Music_Trigger.readInstr

; Write the note: NRx1 = Duty (ch3: 0), NRx2 = Env (ch3: NR32 = level), period, NRx4 |
; $80 (trigger only, no length). A rest writes envelope $01. Clears bit 0 of Flags.
Music_Trigger:
	push hl
	ldh a, [hMusicChannel]
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
	ld de, hMusicChannel
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

; Flag byte non-zero: NRx2 gets whatever e holds (unused by the songs).
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

; Pitch effect: any non-zero low nibble of the Duty byte selects the wobble table (the
; type test jumps unconditionally; the detune path is unreachable).
Music_Vibrato:
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	and $0f
	jr z, .done
	ldh [hSfxId], a
	ldh a, [hMusicChannel]
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
	ldh a, [hSfxId]
	cp $01
	jr .table

.unreachable:
	cp $03
	jr .detune

.detune:
	ld hl, -1
	jr .add

.table:
	ld de, VibratoTable_Wobble
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

