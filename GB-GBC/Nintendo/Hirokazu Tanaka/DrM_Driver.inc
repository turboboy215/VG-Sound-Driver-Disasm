; Dr. Mario sound driver: code and SFX data, bank 1 $6000-$6A9E

; SFX on ch1 (request wSfx1Request = 1-14): init routine, then per-frame routine
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
Sfx1_PlayTable:
	dw Sfx1_01_Play
	dw Sfx1_02_Play
	dw Sfx1_PlayOneStep
	dw Sfx1_PlayOneStep
	dw Sfx1_05_Play
	dw Sfx1_06_Play
	dw Sfx1_PlayOneStep
	dw Sfx1_PlayTwoChannelSequence
	dw Sfx1_09_Play
	dw Sfx1_0A_Play
	dw Sfx1_PlayTwoChannelSequence
	dw Sfx1_0C_Play
	dw Sfx1_PlayTwoChannelSequence
	dw Sfx1_0E_Play
; SFX on ch4 (request wSfx4Request = 1-3)
Sfx4_InitTable:
	dw Sfx4_01_Init
	dw Sfx4_02_Init
	dw Sfx4_03_Init
Sfx4_PlayTable:
	dw Sfx4_01_Play
	dw Sfx4_02_Play
	dw Sound_Init.ret
; song number 1-10 -> header
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
; Priority checks on the SFX playing on ch1. Each returns Z (= do not start) when
; a protected effect is playing.
Sfx1_IsBusy_8ABD:
	ld a, [wSfx1Playing]
	jr Sfx1_IsBusy_C8ABD.check

Sfx1_IsBusy_C8ABD:
	ld a, [wSfx1Playing]
	cp $0c
	ret z
.check:
	cp $08
	ret z
	cp $0a
	ret z
	cp $0b
	ret z
	cp $0d
	ret z
	ret

Sfx1_IsBusy_456:
	ld a, [wSfx1Playing]
	cp $04
	ret z
Sfx1_IsBusy_56:
	ld a, [wSfx1Playing]
	cp $05
	ret z
	cp $06
	ret z
	ret

; NR10-NR14 image
Sfx1_03_Regs:
	db $48, $bc, $90, $27, $c7
Sfx1_03_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	call Sfx1_IsBusy_456
	ret z
	ld a, $02
	ld hl, Sfx1_03_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_0A_Regs:
	db $00, $2e, $e0, $f0, $c5
Sfx1_0A_Init:
	ld hl, wCh2Flags
	res 7, [hl]
	ld a, $08
	ld hl, Sfx1_0A_Regs
	jp Sfx_Start

Sfx1_0A_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $09
	jp z, Sfx1_Stop
	ld hl, Sfx1_0A_Regs
	jp SetRegs_Ch1

; NR10-NR14 image
Sfx1_07_Regs:
	db $00, $bd, $91, $89, $c7
Sfx1_07_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	call Sfx1_IsBusy_56
	ret z
	ld a, $01
	ld hl, Sfx1_07_Regs
	jp Sfx_Start

; NR10-NR14 image
Sfx1_0E_Regs1:
	db $3d, $80, $f0, $10, $c5
; NR10-NR14 image
Sfx1_0E_Regs2:
	db $3e, $80, $f0, $e0, $c5
Sfx1_0E_Init:
	ld a, $05
	ld hl, Sfx1_0E_Regs1
	jp Sfx_Start

Sfx1_0E_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $02
	jr z, Sfx1_Stop
	ld hl, Sfx1_0E_Regs2
	jp SetRegs_Ch1

; NR10-NR14 image
Sfx1_01_Regs1:
	db $00, $f5, $d0, $70, $c7
; NR10-NR14 image
Sfx1_01_Regs2:
	db $00, $f5, $20, $70, $c7
Sfx1_01_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	call Sfx1_IsBusy_456
	ret z
	ld a, $05
	ld hl, Sfx1_01_Regs1
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
	ld hl, Sfx1_01_Regs2
	jp SetRegs_Ch1

; NR10-NR14 image
Sfx1_02_Regs:
	db $00, $b8, $80, $63, $c7
Sfx1_02_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	call Sfx1_IsBusy_456
	ret z
	ld a, $04
	ld hl, Sfx1_02_Regs
	jp Sfx_Start

Sfx1_02_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld a, [hl]
	cp $01
	jr z, Sfx1_Stop
	inc [hl]
	ld hl, Sfx1_02_Regs
	jp SetRegs_Ch1

; Shared per-frame routine of one-image effects: stop when the period elapses.
Sfx1_PlayOneStep:
	call Sfx_Tick
	and a
	ret nz
; Stop the ch1 effect and give the channel back to the music.
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

; NR10-NR14 image
Sfx1_09_Regs1:
	db $00, $80, $91, $ac, $87
; NR10-NR14 image
Sfx1_09_Regs2:
	db $00, $80, $91, $9d, $87
Sfx1_09_Init:
	call Sfx1_IsBusy_8ABD
	ret z
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, Sfx1_09_Regs1
	jp Sfx_Start

Sfx1_09_Play:
	ld hl, wSfx1Step
	inc [hl]
	ld a, [hl]
	cp $04
	jr z, .l0
	cp $0b
	jr z, .l1
	cp $0f
	jr z, .l0
	cp $30
	jp z, .l2
	ret

.l2:
	jp Sfx1_Stop

.l0:
	ld hl, Sfx1_09_Regs2
	jp SetRegs_Ch1

.l1:
	ld hl, Sfx1_09_Regs1
	jp SetRegs_Ch1

; NR10-NR14 image (its NR14 byte is also read by Sfx1_PlayTwoChannelSequence)
Sfx1_08_Regs1:
	db $00, $b0, $f0, $ac, $c7
; ch1 NR13 per step, $FF = end
Sfx1_08_SeqA:
	db $ac, $ac, $00, $b6, $ac, $00, $a2, $00, $9d, $00, $00, $00, $83, $00, $00, $ff
; NR21-NR24 image
Sfx1_08_Regs2:
	db $b0, $f0, $ad, $c7
; ch2 NR23 per step (0 = both channels silent)
Sfx1_08_SeqB:
	db $ad, $ad, $00, $b7, $ad, $00, $a3, $00, $9e, $00, $00, $00, $84, $00, $00, $ff
; NR10-NR14 image (its NR13 byte is read as the NR24 value of every sequence step)
Sfx1_0B_Regs1:
	db $00, $80, $f0, $97, $c7
; ch1 NR13 per step, $FF = end
Sfx1_0B_SeqA:
	db $8a, $4f, $00, $a7, $00, $a7, $00, $ff
; NR21-NR24 image
Sfx1_0B_Regs2:
	db $80, $f0, $98, $c7
; ch2 NR23 per step
Sfx1_0B_SeqB:
	db $8b, $50, $00, $73, $00, $73, $00, $ff
; NR10-NR14 image
Sfx1_0D_Regs1:
	db $00, $80, $f0, $9d, $c7
; NR21-NR24 image
Sfx1_0D_Regs2:
	db $80, $f0, $9e, $c7
; ch1 NR13 per step, $FF = end
Sfx1_0D_SeqA:
	db $83, $9d, $83, $9d, $83, $9d, $83, $9d, $83, $9d, $83, $9d, $83, $9d, $83, $ff
; ch2 NR23 per step
Sfx1_0D_SeqB:
	db $84, $9e, $84, $9e, $84, $9e, $84, $9e, $84, $9e, $84, $9e, $84, $9e, $84, $ff
Sfx1_0D_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_0D_Regs2
	call SetRegs_Ch2
	ld a, $04
	ld hl, Sfx1_0D_Regs1
	call Sfx_Start
	ld a, LOW(Sfx1_0D_SeqA)
	ld [wSfx1PtrA], a
	ld a, HIGH(Sfx1_0D_SeqA)
	ld [wSfx1PtrA+1], a
	ld a, LOW(Sfx1_0D_SeqB)
	ld [wSfx1PtrB], a
	ld a, HIGH(Sfx1_0D_SeqB)
	jr Sfx1_SetSequencePtrB_hi

Sfx1_08_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_08_Regs2
	call SetRegs_Ch2
	ld a, $04
	ld hl, Sfx1_08_Regs1
	call Sfx_Start
	ld a, LOW(Sfx1_08_SeqA)
	ld [wSfx1PtrA], a
	ld a, HIGH(Sfx1_08_SeqA)
	ld [wSfx1PtrA+1], a
	ld a, LOW(Sfx1_08_SeqB)
	ld [wSfx1PtrB], a
	ld a, HIGH(Sfx1_08_SeqB)
Sfx1_SetSequencePtrB_hi:
	ld [wSfx1PtrB+1], a
	ret

Sfx1_0B_Init:
	ld hl, wCh2Flags
	set 7, [hl]
	ld hl, Sfx1_0B_Regs2
	call SetRegs_Ch2
	ld a, $06
	ld hl, Sfx1_0B_Regs1
	call Sfx_Start
	ld a, LOW(Sfx1_0B_SeqA)
	ld [wSfx1PtrA], a
	ld a, HIGH(Sfx1_0B_SeqA)
	ld [wSfx1PtrA+1], a
	ld a, LOW(Sfx1_0B_SeqB)
	ld [wSfx1PtrB], a
	ld a, HIGH(Sfx1_0B_SeqB)
	jr Sfx1_SetSequencePtrB_hi

; Effects 8, 11 and 13 play two square channels in step: each step sets NR13 from
; sequence A and NR23 from sequence B. Both envelopes are $F2, or $08 (off) where
; sequence B is 0. Sequence A $FF ends the effect; effect 13 then requests song 10.
Sfx1_PlayTwoChannelSequence:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld a, [wSfx1PtrA]
	ld l, a
	ld a, [wSfx1PtrA+1]
	ld h, a
	add hl, bc
	ld a, [hl]
	cp $ff
	jp z, .end
	ld d, a
	ld a, [wSfx1PtrB]
	ld l, a
	ld a, [wSfx1PtrB+1]
	ld h, a
	add hl, bc
	ld a, [hl]
	ld e, a
	ld c, $08
	cp $00
	jr z, .write
	ld c, $f2
.write:
	ld a, d
	ldh [rNR13], a
	ld a, c
	ldh [rNR12], a
	ld a, [Sfx1_08_Regs1+4]
	ldh [rNR14], a
	ld a, e
	ldh [rNR23], a
	ld a, c
	ldh [rNR22], a
	ld a, [Sfx1_0B_Regs1+3]
	ldh [rNR24], a
	ret

.end:
	ld a, [wSfx1Playing]
	cp $0d
	jr z, .requestSong0A
.stop:
	call Sfx_ReleaseCh2
	jp Sfx1_Stop

.requestSong0A:
	ld a, $0a
	ld [wSongRequest], a
	jr .stop

; NR10-NR14 image
Sfx1_06_Regs:
	db $34, $80, $e7, $80, $c6
; NR12 per step, 0 = end
Sfx1_06_Env:
	db $97, $87, $87, $77, $67, $57, $47, $37, $20, $10, $00
; NR13 per step
Sfx1_06_Freq:
	db $88, $90, $98, $a0, $a8, $b0, $b8, $c0, $c8, $d0
Sfx1_06_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	ld a, $05
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
	ld e, a
	ld hl, Sfx1_06_Freq
	add hl, bc
	ld a, [hl]
	ld d, a
	ld b, $86
; Effects 5, 6, 12: NR12 = e, NR13 = d, NR14 = b (no length, trigger).
Sfx1_WriteEnvFreq:
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

; NR10-NR14 image
Sfx1_05_Regs:
	db $2e, $80, $a4, $15, $87
; NR12 per step, 0 = end
Sfx1_05_Env:
	db $94, $84, $64, $44, $25, $20, $10, $10, $00
; NR13 per step
Sfx1_05_Freq:
	db $14, $13, $12, $11, $10, $10, $10, $10
Sfx1_05_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	ld a, $03
	ld hl, Sfx1_05_Regs
	jp Sfx_Start

Sfx1_05_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx1_05_Env
	add hl, bc
	ld a, [hl]
	and a
	jp z, Sfx1_Stop
	ld e, a
	ld hl, Sfx1_05_Freq
	add hl, bc
	ld a, [hl]
	ld d, a
	ld b, $87
	jr Sfx1_WriteEnvFreq

; NR10-NR14 image
Sfx1_0C_Regs:
	db $26, $80, $a4, $40, $87
; NR12 per step, 0 = end
Sfx1_0C_Env:
	db $94, $84, $64, $44, $25, $20, $10, $10, $00
; NR13 per step
Sfx1_0C_Freq:
	db $48, $50, $58, $60, $68, $70, $74, $78
Sfx1_0C_Init:
	call Sfx1_IsBusy_8ABD
	ret z
	ld a, $04
	ld hl, Sfx1_0C_Regs
	jp Sfx_Start

Sfx1_0C_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx1Step
	ld c, [hl]
	inc [hl]
	ld b, $00
	ld hl, Sfx1_0C_Env
	add hl, bc
	ld a, [hl]
	and a
	jp z, Sfx1_Stop
	ld e, a
	ld hl, Sfx1_0C_Freq
	add hl, bc
	ld a, [hl]
	ld d, a
	ld b, $87
	jp Sfx1_WriteEnvFreq

; NR10-NR14 image
Sfx1_04_Regs:
	db $9c, $b7, $e0, $34, $c4
Sfx1_04_Init:
	call Sfx1_IsBusy_C8ABD
	ret z
	call Sfx1_IsBusy_56
	ret z
	ld a, $03
	ld hl, Sfx1_04_Regs
	jp Sfx_Start

Sfx4_03_Init:
	jp Sfx4_Stop

; NR41-NR44 image
Sfx4_02_Regs:
	db $00, $60, $1a, $80
; NR43 per step, cycled
Sfx4_02_NR43:
	db $0d, $0e, $0f, $1c, $1d, $1e, $1d, $1c
Sfx4_02_Init:
	ld a, $03
	ld hl, Sfx4_02_Regs
	jp Sfx_Start

Sfx4_02_Play:
	call Sfx_Tick
	and a
	ret nz
	ld hl, wSfx4Step
	ld a, [hl]
	and $07
	ld c, a
	inc [hl]
	ld b, $00
	ld hl, Sfx4_02_NR43
	add hl, bc
	ld a, [hl]
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret

; NR41-NR44 image
Sfx4_01_Regs:
	db $00, $e1, $56, $80
; ch4 effects
Sfx4_01_Init:
	ld a, $18
	ld hl, Sfx4_01_Regs
	jp Sfx_Start

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

; Unreferenced: ch3 effect support. Sfx3_Start_Unused takes every channel (bit 7 of
; wChNFlags) and loads a wave; Sfx3_Stop_Unused releases them and reloads the wave of the
; song (song 5 uses a different one). Sound_Update never reads wSfx3Request.
Sfx3_Stop_Unused:
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
	ld hl, Wave_6BF3
	jr Sfx3_LoadWave_Unused

.song05:
	ld hl, Wave_6BD3
	jr Sfx3_LoadWave_Unused

Sfx3_Start_Unused:
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
Sfx3_LoadWave_Unused:
	call LoadWave
	ret

; Release ch2 after a two-channel effect.
Sfx_ReleaseCh2:
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
	ld hl, wCh2Flags
	res 7, [hl]
	ret

; Start an effect. a = frames per step, hl = register image, de = wSfxNRequest+2.
; Sets Playing = wSfxId, Period = a, clears Timer/Step/Var, marks the channel as taken
; (bit 7 of wChNFlags: the music stops writing it) and writes the image.
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
	push hl
	ld a, e
	cp $e5
	jr z, .ch1
	cp $f5
	jr z, .ch3
	cp $fd
	jr z, .ch4
	ret

.ch1:
	ld hl, wCh1Flags
	set 7, [hl]
	pop hl
	jr SetRegs_Ch1

.ch3:
	ld hl, wCh3Flags
	set 7, [hl]
	pop hl
	jr SetRegs_Ch3

.ch4:
	ld hl, wCh4Flags
	set 7, [hl]
	pop hl
	jr SetRegs_Ch4

; Write a register image: ch1 NR10-NR14, ch2 NR21-NR24, ch3 NR30-NR34, ch4 NR41-NR44.
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

; a = SFX number, hl = table: hl = table[a-1] (de advanced to the channel variables).
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

; Count frames: returns a = 0 once every wSfxNPeriod frames (de = wSfxNTimer).
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

; Copy 16 bytes from hl to wave RAM.
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

; Stop everything: sound RAM state, music, effects, pause; mute the channels.
Sound_Stop:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
Sound_ClearState:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld [wCh1Flags], a
	ld [wCh2Flags], a
	ld [wCh3Flags], a
	ld [wCh4Flags], a
	ld [wPauseTimer], a
	ld [wPauseRequest], a
	ld [wPitchUpLevel], a
	ld [wPitchUpTimer], a
	ld [wPitchUpTimer+1], a
	ld [wDangerBeep], a
	ld [wForceSfx0A], a
; Mute ch1, ch2, ch4 (envelope 0 + trigger), clear the sweep and turn ch3 off.
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

; Start a requested ch1 effect, or run the one playing.
Sfx1_Update:
	ld de, wSfx1Request
	ld a, [de]
	and a
	jr z, .playing
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

; Copied to wSongDanceSpeed when a song starts. The game reads it as the speed of
; the dancing viruses.
SongDanceSpeedTable:
	db $0d, $0b, $0d, $0a, $0a, $0a, $0a, $0f, $0a, $0a, $05	; frames per dance step, index = song (0 unused)
Music_StopSong:
	jp Sound_Stop

; a = wSongRequest ($FF = stop), hl = wSongPlaying.
Music_StartSong:
	cp $ff
	jr z, Music_StopSong
	cp $0b
	ret nc
	push af
	push hl
	ld hl, SongDanceSpeedTable
	ld c, a
	ld b, $00
	add hl, bc
	ld a, [hl]
	ld [wSongDanceSpeed], a
	pop hl
	pop af
	ld [hl], a
	ld b, a
	ld hl, SongTable
	and $1f
	call GetPointer
	call Music_LoadHeader
	call Music_InitPanning
	ret

; Called once per frame (stub at $7FF0).
; Order: pause request -> pause jingle -> song request -> SFX ch1 -> SFX ch4 -> music,
; then clear every request. Pause requests: wPauseRequest = 1 pause, 2 resume.
Sound_Update:
	ld a, [wPauseRequest]
	cp $01
	jr z, .pause
	cp $02
	jp z, .unpause
	ld a, [wPauseTimer]
	and a
	jp nz, .paused
.main:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	jr nz, .startSong
; wForceSfx0A: one-shot request of effect 10. wDangerBeep: keep requesting effect 9
; (as long as effects 8, 10, 11 are not requested or playing).
	ld a, [wForceSfx0A]
	and a
	jr z, .dangerBeep
	ld a, $0a
	ld [wSfx1Request], a
.dangerBeep:
	ld a, [wSfx1Request]
	cp $08
	jr z, .sfx
	cp $0a
	jr z, .sfx
	cp $0b
	jr z, .sfx
	ld a, [wSfx1Playing]
	cp $08
	jr z, .sfx
	cp $0a
	jr z, .sfx
	cp $0b
	jr z, .sfx
	ld a, [wDangerBeep]
	and a
	jr z, .sfx
	ld c, $09
	ld a, [wSfx1Playing]
	cp $09
	jr nz, .setBeep
	ld c, $00
.setBeep:
	ld a, c
	ld [wSfx1Request], a
.sfx:
	call Sfx1_Update
	ld a, [wSongRequest]
	cp $0a
	jr z, .main
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
	ld [wForceSfx0A], a
	ret

.startSong:
	call Music_StartSong
	jr .music

; Pause: mute, cancel the effects, load the default wave and play a 4-note jingle on
; ch2 (frames $30, $28, $20, $18), then hold the timer at $10 until resumed.
.pause:
	call Sound_MuteChannels
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld hl, wCh1Flags
	res 7, [hl]
	ld hl, wCh2Flags
	res 7, [hl]
	ld hl, wCh3Flags
	res 7, [hl]
	ld hl, wCh4Flags
	res 7, [hl]
	ld hl, Wave_6BF3
	call LoadWave
	ld a, $30
	ld [wPauseTimer], a
.jingleA:
	ld hl, PauseJingleA
.writeJingle:
	call SetRegs_Ch2
	jr .clearRequests

.jingleB:
	ld hl, PauseJingleB
	jr .writeJingle

.unpause:
	xor a
	ld [wPauseTimer], a
	ld [wForceSfx0A], a
	jp .main

.paused:
	ld hl, wPauseTimer
	dec [hl]
	ld a, [hl]
	cp $28
	jr z, .jingleB
	cp $20
	jr z, .jingleA
	cp $18
	jr z, .jingleB
	cp $10
	jr nz, .clearRequests
	inc [hl]
	jr .clearRequests

; NR21-NR24 image
PauseJingleA:
	db $b2, $e3, $83, $c7
; NR21-NR24 image
PauseJingleB:
	db $b2, $e3, $c1, $c7
; Called once at boot (stub at $7FF6). Its final ret doubles as the "no-op" entry of
; Sfx4_PlayTable.
Sound_Init:
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	ld hl, wSoundRAM
.clear:
	ld [hl], $00
	inc l
	jr nz, .clear
.ret:
	ret

; Song panning: mode 1 = fixed NR51; other modes alternate NR51 A/B every period frames.
Music_InitPanning:
	ld a, [wSongPlaying]
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
	ldh [rNR51], a
	ld a, [hl+]
	ld [wPanNR51B], a
	xor a
	ld [wPanTimer], a
	ld [wPanToggle], a
	ret

Music_UpdatePanning:
	ld hl, wPanMode
	ld a, [hl+]
	cp $01
	ret z
	inc [hl]
	ld a, [hl+]
	cp [hl]
	ret nz
	dec l
	ld [hl], $00
	inc l
	inc l
	inc [hl]
	inc l
	ld a, [hl-]
	bit 0, [hl]
	jp z, .write
	inc l
	inc l
	ld a, [hl]
.write:
	ldh [rNR51], a
	ret

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

; hl = song header. Copy transpose, length table and the four list pointers, then
; load each channel's first pattern pointer.
Music_LoadHeader:
	call Sound_ClearState
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

; $9D: three bytes to wChNInstrEnv/Flag/Duty. On ch3 the first two are a wave
; pointer, loaded now.
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

; Pointer helpers on the 16-bit pointer at hl.
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

; Frame without a new note: ch3 with level bit 7 drops to 50% 6 frames before the
; end; then vibrato, unless the channel is resting or taken by an effect.
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

; $00: next entry of the section list. $0000 ends the song (song 10 also sets
; wSong0AEnded); $FFxx loops the list to the address that follows.
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
	ld a, [hl]
	cp $0a
	jr nz, .stop
	ld a, $01
	ld [wSong0AEnded], a
.stop:
	ld [hl], $00
	call Sound_Stop
	ret

; $9E: length table pointer.
Cmd_Tempo:
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable], a
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable+1], a
	jr Cmd_SkipAndContinue

; $9F: transpose (in note-table bytes, 2 per semitone).
Cmd_Transpose:
	call IncPtr
	call ReadPtrByte
	ld [wTranspose], a
Cmd_SkipAndContinue:
	call IncPtr
	jr Music_ReadCommand

; $9B n: repeat from here n times. The count lives in bits 0-6 of wChNFlags.
Cmd_RepeatStart:
	call IncPtr
	call ReadPtrByte
	push hl
	ld a, l
	add a, $0b
	ld l, a
	ld c, [hl]
	ld a, b
	or c
	ld [hl], a
	ld b, h
	ld c, l
	dec c
	dec c
	pop hl
	ld a, [hl+]
	ld e, a
	ld a, [hl-]
	ld d, a
	inc de
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl-], a
	ld a, d
	ld [bc], a
	dec c
	ld a, e
	ld [bc], a
	jr Music_ReadCommand

; $9C: end of the repeated block.
Cmd_RepeatEnd:
	push hl
	ld a, l
	add a, $0b
	ld l, a
	ld a, [hl]
	dec [hl]
	ld a, [hl]
	and $7f
	jr z, .done
	ld b, h
	ld c, l
	dec c
	dec c
	dec c
	pop hl
	ld a, [bc]
	ld [hl+], a
	inc c
	ld a, [bc]
	ld [hl-], a
	jr Music_ReadCommand

.done:
	pop hl
	jr Cmd_SkipAndContinue

; Music: run the four channels (structure of 16 bytes at wCh1ListPtr + $10*n).
Music_Update:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld hl, wPitchUpTimer
	ld a, [wPitchUpLevel]
	cp $03
	jr nz, .notPitchUp3
	inc [hl]
	jr nz, .channels
	inc l
	inc [hl]
	jr .channels

.notPitchUp3:
	xor a
	ld [hl+], a
	ld [hl], a
.channels:
	call Music_UpdatePanning
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
; Read pattern bytes until a note or rest: commands, $A0-$AF lengths.
Music_ReadCommand:
	call ReadPtrByte
	cp $00
	jp z, Cmd_PatternEnd
	cp $9d
	jp z, Cmd_Instrument
	cp $9e
	jp z, Cmd_Tempo
	cp $9f
	jp z, Cmd_Transpose
	cp $9b
	jp z, Cmd_RepeatStart
	cp $9c
	jp z, Cmd_RepeatEnd
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
	inc e
	ld a, [de]
	ld h, a
	add hl, bc
	ld a, [hl]
	pop hl
	dec l
	ld [hl+], a
	call IncPtr
	call ReadPtrByte
; Note or rest (c = byte). Adds the transpose and the game's pitch-up level (+1, +2
; or +3 semitones, plus one more every 256 frames at level 3).
Music_Note:
	ld c, b
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
	ld a, [wTranspose]
	and a
	jr z, .pitchUp
	ld l, a
	ld h, $00
	bit 7, l
	jr z, .addTranspose
	ld h, $ff
.addTranspose:
	add hl, bc
	ld b, h
	ld c, l
.pitchUp:
	ld a, [wPitchUpLevel]
	and a
	jr z, .lookup
	inc bc
	inc bc
	cp $01
	jr z, .lookup
	inc bc
	inc bc
	cp $02
	jr z, .lookup
	cp $03
	jr c, .lookup
	inc bc
	inc bc
	ld a, [wPitchUpTimer+1]
	and a
	jr z, .lookup
	cp $1f
	jr c, .pitchUpLoop
	ld a, $1f
.pitchUpLoop:
	inc bc
	inc bc
	dec a
	jr nz, .pitchUpLoop
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

; ch4: copy 5 bytes of NoiseTable (env, flag, NR41, NR43, NR44) into the channel.
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

; Write the note: NRx1 = Duty (ch3: 0, or $EF when level bit 7), NRx2 = Env (ch3: NR32
; = level), period, NRx4 | $C0 (trigger + length enable). A rest writes envelope $08.
; Nothing is written while an effect owns the channel.
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
	ld a, [wCh3InstrDuty]
	bit 7, a
	jr z, .write
	ld d, $ef
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
	ld e, $08
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
	or $c0
	ldh [c], a
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
	ld a, $10
	add a, l
	ld l, a
	jp Music_ChannelLoop

.allDone:
	ld hl, wCh1NoteFrames
	inc [hl]
	ld hl, wCh2NoteFrames
	inc [hl]
	ld hl, wCh3NoteFrames
	inc [hl]
	ret

; Flag byte non-zero: the envelope register keeps whatever e holds (the low byte of the
; channel's Freq address, or $CB on ch4). No song uses it.
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

; Pitch effect from the low nibble of the Duty byte: 1 = wobble table, 2 = fall table
; (both indexed by NoteFrames / 2, one signed nibble per frame), 3-15 = period - 2.
; Writes NRx3/NRx4 without the length-enable bit.
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
	jr z, .type1
	cp $02
	jr z, .type2
	cp $03
	jr z, .detune
.detune:
	ld hl, -2
	jr .add

.type2:
	ld de, VibratoTable_Fall
	jr .readTable

.type1:
	ld de, VibratoTable_Wobble
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

