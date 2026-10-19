; Kirby Tilt 'n' Tumble SFX: slot dispatch, shared routines, priorities, stop, bank $14 $5AFE-$7FFF

; Like SetRegs_ChN, but a zero byte leaves its register alone (SMB DX's SetRegsSkip0).
SetRegsSkip0_Ch1:
	ld b, $05
	ld c, $10
	ld de, wSfx1Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Ch2:
	ld b, $04
	ld c, $16
	ld de, wSfx2Timer
	jr SetRegsSkip0_Copy

; unreferenced
SetRegsSkip0_Ch3_Unused:
	ld b, $05
	ld c, $1a
	ld de, wSfx3Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Ch4:
	ld b, $04
	ld c, $20
	ld de, wSfx4Timer
	jr SetRegsSkip0_Copy

SetRegsSkip0_Copy:
	ld a, [hl+]
	and a
	jr z, .next
	ldh [c], a
.next:
	inc c
	dec b
	jr nz, SetRegsSkip0_Copy
	ld a, [hl]
	ld [de], a
	ret

; Slot 1: requests $80-$97 (bank $11 handles the ones below $80).
Sfx1_Update:
	ld hl, wSfx1Request
	ld a, [hl]
	and a
	jp z, Sfx1_Continue.playing
	bit 7, a
	jr z, Sfx1_Continue.playing
	cp $98
	jr nc, Sfx1_Continue.playing
	and $7f
	ld d, a
	ld c, a
	ld b, $00
	ld hl, SfxPriorityTable+127
	add hl, bc
	ld b, [hl]
	ld a, [wSfx1Priority]
	cp b
	jp c, .start
	jp z, .start
	jr Sfx1_Continue

.start:
	ld a, b
	ld [wSfx1Priority], a
	ld a, d
	ld hl, Sfx1_InitTable
	jr Sfx1_Dispatch

Sfx1_Refuse:
	xor a
	ld [wSfx1Request], a
Sfx1_Continue:
	ld hl, wSfx1Request
.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	bit 7, a
	ret z
	and $7f
	ld hl, Sfx1_PlayTable
Sfx1_Dispatch:
	call GetPointer0
	ld de, wSfx1Timer
	ld bc, wSfx1Step
	jp hl

; unreferenced
Sfx1_StartVar_Unused:
	ld a, $01
	ld [wSfx1Var], a
; Start a ch1 effect: take ch1 from the music (wCh1Flags bit 7), write hl = NR10-NR14 +
; frames.
Sfx1_Start:
	call Sfx1_Take
	jp SetRegs_Ch1

; Same, with the software sweep (Sfx1_SweepStart) instead of the hardware NR10.
Sfx1_StartSweep:
	call Sfx1_Take
	jp Sfx1_SweepStart

Sfx1_Take:
	ld a, [wSfx1Request]
	ld [wSfx1Playing], a
	xor a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	ld a, [wChannelsPlayed]
	res 0, a
	ld [wChannelsPlayed], a
	ret

; NR12 = $11, retrigger, then release ch1.
Sfx1_StopSilent:
	ld a, $11
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	jr Sfx1_Release

; End a ch1 effect: write Sfx1_StopRegs, clear the slot (priority too) and the ch1 transpose
; byte wChTranspose+0, NR10 = 8, give ch1 back to the music.
Sfx1_Stop:
	ld hl, Sfx1_StopRegs
	call SetRegs_Ch1
Sfx1_Release:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld [wSfx1Counter], a
	ld [wSfx1Var], a
	ld [wSfx1Priority], a
	ld [wChTranspose], a
	ld a, $08
	ldh [rNR10], a
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

; NR10-NR14 + frames written by Sfx1_Stop
Sfx1_StopRegs:
	db $08, $3f, $08, $00, $c1, $01
; unreferenced: write NR13/NR14 + frames (LA's Sfx1_WritePeriod)
Sfx1_WritePeriod_Unused:
	ld b, $02
	ld c, $13
	ld de, wSfx1Timer
	jp SetRegs_Copy

Sfx2_WritePeriod_Unused:
	ld b, $02
	ld c, $18
	ld de, wSfx2Timer
	jp SetRegs_Copy

; Like SetRegs_Ch1, but a zero NR10/NR11/NR12 byte leaves its register alone (NR13/NR14
; are always written). The ch2 / ch4 versions skip zeros in NR21/NR22 and NR41/NR42/NR44.
SetRegsPartial_Ch1:
	ld c, $10
	ld de, wSfx1Timer
	ld a, [hl+]
	and a
	jr z, .nr11
	ldh [c], a
.nr11:
	inc c
	ld a, [hl+]
	and a
	jr z, .nr12
	ldh [c], a
.nr12:
	inc c
	ld a, [hl+]
	and a
	jr z, .nr13
	ldh [c], a
.nr13:
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	ld a, [hl]
	ld [de], a
	ret

; Slot 2: requests $80-$8F (bank $11 handles the ones below $80).
Sfx2_Update:
	ld hl, wSfx2Request
	ld a, [hl]
	and a
	jp z, Sfx2_Continue.playing
	bit 7, a
	jr z, Sfx2_Continue.playing
	cp $90
	jr nc, Sfx2_Continue.playing
	and $7f
	ld d, a
	ld c, a
	ld b, $00
	ld hl, SfxPriorityTable_Slot2+63
	add hl, bc
	ld b, [hl]
	ld a, [wSfx2Priority]
	cp b
	jp c, .start
	jp z, .start
	jr Sfx2_Continue

.start:
	ld a, b
	ld [wSfx2Priority], a
	ld a, d
	ld hl, Sfx2_InitTable
	jr Sfx2_Dispatch

Sfx2_Refuse:
	xor a
	ld [wSfx2Request], a
Sfx2_Continue:
	ld hl, wSfx2Request
.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	bit 7, a
	ret z
	and $7f
	ld hl, Sfx2_PlayTable
Sfx2_Dispatch:
	call GetPointer0
	ld de, wSfx2Timer
	ld bc, wSfx2Step
	jp hl

Sfx2_Start:
	call Sfx2_Take
	jp SetRegs_Ch2

Sfx2_StartSweep:
	call Sfx2_Take
	jp Sfx2_SweepStart

Sfx2_Take:
	ld a, [wSfx2Request]
	ld [wSfx2Playing], a
	ld a, [wCh2Flags]
	set 7, a
	ld [wCh2Flags], a
	xor a
	ld [wSfx2Timer], a
	ld [wSfx2Step], a
	ld a, [wChannelsPlayed]
	res 1, a
	ld [wChannelsPlayed], a
	ret

Sfx2_Stop:
	ld hl, Sfx2_StopRegs
	call SetRegs_Ch2
Sfx2_Release:
	xor a
	ld [wSfx2Timer], a
	ld [wSfx2Step], a
	ld [wSfx2Playing], a
	ld [wSfx2Priority], a
	ld hl, wCh2Flags
	res 7, [hl]
	ret

Sfx2_StopRegs:
	db $3f, $08, $00, $c1, $01
; unreferenced: SetRegsPartial for ch2
SetRegsPartial_Ch2_Unused:
	ld c, $16
	ld de, wSfx2Timer
	ld a, [hl+]
	and a
	jr z, .nr22
	ldh [c], a
.nr22:
	inc c
	ld a, [hl+]
	and a
	jr z, .nr23
	ldh [c], a
.nr23:
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	ld a, [hl]
	ld [de], a
	ret

; Slot 3: requests $80-$87 (bank $11 handles the ones below $80).
Sfx3_Update:
	ld hl, wSfx3Request
	ld a, [hl]
	and a
	jp z, Sfx3_Continue.playing
	bit 7, a
	jr z, Sfx3_Continue.playing
	cp $88
	jr nc, Sfx3_Continue.playing
	and $7f
	ld d, a
	ld c, a
	ld b, $00
	ld hl, SfxPriorityTable_Slot3+8
	add hl, bc
	ld b, [hl]
	ld a, [wSfx3Priority]
	cp b
	jp c, .start
	jp z, .start
	jr Sfx3_Continue

.start:
	ld a, b
	ld [wSfx3Priority], a
	ld a, d
	ld hl, Sfx3_InitTable
	jr Sfx3_Dispatch

Sfx3_Refuse:
	xor a
	ld [wSfx3Request], a
Sfx3_Continue:
	ld hl, wSfx3Request
.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	bit 7, a
	ret z
	and $7f
	ld hl, Sfx3_PlayTable
Sfx3_Dispatch:
	call GetPointer0
	ld de, wSfx3Timer
	ld bc, wSfx3Step
	jp hl

Sfx3_Start:
	call Sfx3_Take
	jp SetRegs_Ch3

; unreferenced in this bank
Sfx3_StartSweep_Unused:
	call Sfx3_Take
	jp Sfx3_SweepStart_Unused

Sfx3_Take:
	ld a, [wSfx3Request]
	ld [wSfx3Playing], a
	xor a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ld a, [wCh3Flags]
	set 7, a
	ld [wCh3Flags], a
	ret

; End a ch3 effect and tell the music to reload its wave (wReloadWave).
Sfx3_Stop:
	ld hl, Sfx3_StopRegs
	call SetRegs_Ch3
Sfx3_Release:
	xor a
	ld [wSfx3Playing], a
	ld [wSfx3Timer], a
	ld [wSfx3Step], a
	ld [wSfx3Counter], a
	ld [wSfx3Priority], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld a, $01
	ld [wReloadWave], a
	ret

Sfx3_StopRegs:
	db $00, $00, $00, $00, $00, $01
; Copy 16 bytes at hl to wave RAM (ch3 off first).
Sfx3_LoadWave:
	xor a
	ldh [rNR30], a
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

; Slot 4: requests $80-$90 (bank $11 handles the ones below $80).
Sfx4_Update:
	ld hl, wSfx4Request
	ld a, [hl]
	and a
	jp z, Sfx4_Continue.playing
	bit 7, a
	jr z, Sfx4_Continue.playing
	cp $91
	jr nc, Sfx4_Continue.playing
	and $7f
	ld d, a
	ld c, a
	ld b, $00
	ld hl, SfxPriorityTable_Slot4+40
	add hl, bc
	ld b, [hl]
	ld a, [wSfx4Priority]
	cp b
	jp c, .start
	jp z, .start
	jr Sfx4_Continue

.start:
	ld a, b
	ld [wSfx4Priority], a
	ld a, d
	ld hl, Sfx4_InitTable
	jr Sfx4_Dispatch

Sfx4_Refuse:
	xor a
	ld [wSfx4Request], a
Sfx4_Continue:
	ld hl, wSfx4Request
.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	bit 7, a
	ret z
	and $7f
	ld hl, Sfx4_PlayTable
Sfx4_Dispatch:
	call GetPointer0
	ld de, wSfx4Timer
	ld bc, wSfx4Step
	jp hl

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

Sfx4_Stop:
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
Sfx4_Release:
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
	db $00, $08, $00, $80, $01
; unreferenced: write NR43/NR44 + frames
Sfx4_WriteNR43_Unused:
	ld b, $02
	ld c, $22
	ld de, wSfx4Timer
	jp SetRegs_Copy

SetRegsPartial_Ch4:
	ld c, $20
	ld de, wSfx4Timer
	ld a, [hl+]
	and a
	jr z, .nr42
	ldh [c], a
.nr42:
	inc c
	ld a, [hl+]
	and a
	jr z, .nr43
	ldh [c], a
.nr43:
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	and a
	jr z, .frames
	ldh [c], a
.frames:
	ld a, [hl]
	ld [de], a
	ret

; hl = table, a = 1-based index: hl = table[a-1]. GetPointer0 (the dispatchers): a = 0-based.
GetPointer:
	dec a
GetPointer0:
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

; de = timer: decrement (Z when it reaches 0). bc = step: increment, a = new step.
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

; Write a register image (b bytes from NRx0/NRx1) and store the following byte as the
; slot's timer.
SetRegs_Ch1:
	ld b, $05
	ld c, $10
	ld de, wSfx1Timer
	jr SetRegs_Copy

SetRegs_Ch2:
	ld b, $04
	ld c, $16
	ld de, wSfx2Timer
	jr SetRegs_Copy

SetRegs_Ch3:
	ld b, $05
	ld c, $1a
	ld de, wSfx3Timer
	jr SetRegs_Copy

SetRegs_Ch4:
	ld b, $04
	ld c, $20
	ld de, wSfx4Timer
	jr SetRegs_Copy

SetRegs_Copy:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, SetRegs_Copy
	ld a, [hl]
	ld [de], a
	ret

; Count down an effect's private counter; Z at 0.
Sfx1_DecCounter:
	push de
	ld de, wSfx1Counter
	jr Sfx_DecCounter

Sfx2_DecCounter:
	push de
	ld de, wSfx2Counter
	jr Sfx_DecCounter

; unreferenced in this bank
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

; Copy the period of a register image (hl) into the effect's pitch variable.
Sfx1_LoadPitch:
	push de
	ld de, wSfx1Pitch
	jr Sfx_LoadPitch

; unreferenced in this bank
Sfx3_LoadPitch:
	push de
	ld de, wSfx3Pitch
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

Sfx2_LoadPitch:
	push de
	ld de, wSfx2Pitch
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
	pop de
	ret

; Add a big-endian offset (table[step-1]) to the effect's period and write NRx3/NRx4.
Sfx1_AddPitch:
	push de
	ld de, wSfx1Pitch+1
	ld a, [bc]
	ld c, $13
	push bc
	jr Sfx_AddPitch

; unreferenced in this bank
Sfx3_AddPitch:
	push de
	ld de, wSfx3Pitch+1
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

Sfx2_AddPitch:
	push de
	ld de, wSfx2Pitch+1
	ld a, [bc]
	ld c, $18
	push bc
	jr Sfx_AddPitch

; Software sweep, ch1. hl = image: byte 0 is an NR10-style sweep byte (bits 5-4 period in
; frames, bit 3 down, bits 2-0 shift); bytes 1-4 go to NR11-NR14 (NR10 = 8), byte 5 = frames.
Sfx1_SweepStart:
	ld a, [hl]
	and $3f
	ld b, a
	sla a
	sla a
	and $c0
	or b
	ld [wSfx1Sweep], a
	inc hl
	inc hl
	inc hl
	ld a, [hl+]
	ld de, wSfx1Pitch
	ld [de], a
	inc e
	ld a, [hl-]
	ld [de], a
	dec hl
	dec hl
	ld c, $10
	ld a, $08
	ldh [c], a
	inc c
	ld b, $04
	ld de, wSfx1Timer
	jp SetRegs_Copy

; Every <period> frames: period += (($7FF - period) >> shift), negated when bit 3 is set.
; The step is a fraction of 2048 - period, i.e. of the wave length, so the glide is even in
; pitch like the hardware sweep but computed the other way round.
Sfx1_Sweep:
	ld a, [wSfx1Sweep]
	ld b, a
	and $c0
	ret z
	cp $40
	jr z, .step
	ld a, b
	sub $40
	ld [wSfx1Sweep], a
	ret

.step:
	ld a, b
	sla a
	sla a
	and $c0
	or b
	ld [wSfx1Sweep], a
	ld hl, wSfx1Pitch
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	ld a, d
	cpl
	ld d, a
	ld a, e
	cpl
	ld e, a
	inc de
	ld hl, $07ff
	add hl, de
	ld a, h
	and $07
	ld h, a
	ld a, b
	and $07
	jr z, .sign
.shift:
	srl h
	rr l
	dec a
	jr nz, .shift
.sign:
	ld a, b
	and $08
	jr z, .add
	ld a, h
	cpl
	ld h, a
	ld a, l
	cpl
	ld l, a
	inc hl
.add:
	pop de
	add hl, de
	ld de, wSfx1Pitch
	ld c, $13
	ld a, l
	ldh [c], a
	ld [de], a
	inc c
	inc e
	ld a, h
	and $07
	ldh [c], a
	ld [de], a
	ret

Sfx2_SweepStart:
	ld a, [hl]
	and $3f
	ld b, a
	sla a
	sla a
	and $c0
	or b
	ld [wSfx2Sweep], a
	inc hl
	inc hl
	inc hl
	ld a, [hl+]
	ld de, wSfx2Pitch
	ld [de], a
	inc e
	ld a, [hl-]
	ld [de], a
	dec hl
	dec hl
	jp SetRegs_Ch2

; unreferenced in this bank
Sfx2_Sweep:
	ld a, [wSfx2Sweep]
	ld b, a
	and $c0
	ret z
	cp $40
	jr z, .step
	ld a, b
	sub $40
	ld [wSfx2Sweep], a
	ret

.step:
	ld a, b
	sla a
	sla a
	and $c0
	or b
	ld [wSfx2Sweep], a
	ld hl, wSfx2Pitch
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	ld a, d
	cpl
	ld d, a
	ld a, e
	cpl
	ld e, a
	inc de
	ld hl, $07ff
	add hl, de
	ld a, h
	and $07
	ld h, a
	ld a, b
	and $07
	jr z, .sign
.shift:
	srl h
	rr l
	dec a
	jr nz, .shift
.sign:
	ld a, b
	and $08
	jr z, .add
	ld a, h
	cpl
	ld h, a
	ld a, l
	cpl
	ld l, a
	inc hl
.add:
	pop de
	add hl, de
	ld de, wSfx2Pitch
	ld c, $18
	ld a, l
	ldh [c], a
	ld [de], a
	inc c
	inc e
	ld a, h
	and $07
	ldh [c], a
	ld [de], a
	ret

; unreferenced: the same sweep for ch3
Sfx3_SweepStart_Unused:
	ld a, [hl]
	and $3f
	ld b, a
	sla a
	sla a
	and $c0
	or b
	ld [wSfx3Sweep], a
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hl+]
	ld de, wSfx3Pitch
	ld [de], a
	inc e
	ld a, [hl-]
	ld [de], a
	dec hl
	dec hl
	dec hl
	jp SetRegs_Ch3

Sfx3_Sweep_Unused:
	ld a, [wSfx3Sweep]
	ld b, a
	and $c0
	ret z
	cp $40
	jr z, .step
	ld a, b
	sub $40
	ld [wSfx3Sweep], a
	ret

.step:
	ld a, b
	sla a
	sla a
	and $c0
	or b
	ld [wSfx3Sweep], a
	ld hl, wSfx3Pitch
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	ld a, d
	cpl
	ld d, a
	ld a, e
	cpl
	ld e, a
	inc de
	ld hl, $07ff
	add hl, de
	ld a, h
	and $07
	ld h, a
	ld a, b
	and $07
	jr z, .sign
.shift:
	srl h
	rr l
	dec a
	jr nz, .shift
.sign:
	ld a, b
	and $08
	jr z, .add
	ld a, h
	cpl
	ld h, a
	ld a, l
	cpl
	ld l, a
	inc hl
.add:
	pop de
	add hl, de
	ld de, wSfx3Pitch
	ld c, $1d
	ld a, l
	ldh [c], a
	ld [de], a
	inc c
	inc e
	ld a, h
	and $07
	ldh [c], a
	ld [de], a
	ret

; Priority of every effect, one table for both SFX banks: slot 1 $01-$97, slot 2 $01-$8F,
; slot 3 $01-$87, slot 4 $01-$90. Bank $11 reads the entries up to $7F, bank $14 the rest.
SfxPriorityTable:
	db $00, $84, $b0, $80, $80, $80, $98, $82, $80, $be, $9c, $20, $80, $80, $00, $80	; slot 1: $01-$10
	db $80, $80, $a6, $00, $00, $a4, $83, $80, $00, $00, $9c, $d0, $80, $a7, $80, $a8	; slot 1: $11-$20
	db $84, $80, $80, $00, $d0, $d0, $80, $9a, $80, $90, $a4, $a0, $82, $9a, $80, $40	; slot 1: $21-$30
	db $80, $80, $80, $80, $00, $00, $50, $d0, $be, $80, $70, $80, $98, $98, $98, $98	; slot 1: $31-$40
	db $98, $98, $98, $98, $98, $98, $98, $98, $80, $80, $a0, $be, $c8, $c8, $ac, $ac	; slot 1: $41-$50
	db $c8, $bc, $d0, $80, $80, $80, $80, $80, $80, $88, $d0, $80, $b0, $80, $80, $80	; slot 1: $51-$60
	db $80, $00, $88, $80, $80, $84, $80, $9a, $80, $80, $80, $80, $80, $83, $00, $00	; slot 1: $61-$70
	db $00, $00, $80, $00, $00, $00, $98, $80, $00, $00, $00, $00, $00, $00, $00, $80	; slot 1: $71-$80
	db $90, $80, $80, $80, $80, $be, $80, $80, $80, $80, $80, $80, $b0, $b0, $80, $80	; slot 1: $81-$90
	db $30, $a0, $70, $00, $00, $00, $00	; slot 1: $91-$97
SfxPriorityTable_Slot2:
	db $c0, $a4, $b8, $80, $ad, $d0, $a0, $a0, $b0, $90, $98, $a8, $ab, $80, $80, $80	; slot 2: $01-$10
	db $80, $80, $80, $80, $80, $80, $00, $80, $80, $80, $80, $80, $80, $80, $00, $aa	; slot 2: $11-$20
	db $98, $70, $80, $00, $80, $80, $60, $78, $00, $20, $80, $00, $00, $80, $80, $84	; slot 2: $21-$30
	db $c0, $80, $80, $80, $80, $88, $b8, $80, $00, $00, $00, $00, $00, $00, $90, $80	; slot 2: $31-$40
	db $80, $b8, $00, $80, $80, $80, $aa, $80, $50, $88, $88, $00, $00, $00, $00	; slot 2: $41-$4f
SfxPriorityTable_Slot3:
	db $70, $70, $d0, $b0, $c0, $80, $80, $20, $80, $80, $80, $a0, $a8, $a8, $b8, $00	; slot 3: $01-$10
SfxPriorityTable_Slot4:
	db $b8, $c0, $70, $80, $d0, $b0, $b0, $c8, $c4, $88, $80, $a0, $80, $88, $90, $70	; slot 4: $01-$10
	db $80, $b0, $b0, $80, $80, $80, $60, $a0, $a0, $70, $70, $a8, $80, $90, $80, $80	; slot 4: $11-$20
	db $98, $90, $80, $20, $90, $c4, $80, $cc, $80, $80, $80, $80, $80, $80, $80, $40	; slot 4: $21-$30
	db $80, $c0, $a0, $b4, $78, $78, $40, $ca, $80	; slot 4: $31-$39
; Stop everything: music and effects, panning, fades; mute.
Sound_Stop:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
	xor a
	ld [wSfx1Playing], a
	ld [wSfx2Playing], a
	ld [wSfx4Playing], a
	ld [wCh1Flags], a
	ld [wCh2Flags], a
	ld [wCh3Flags], a
	ld [wCh4Flags], a
	ld [wCh3FadeOut], a
	ld [wCh3FadeOutTimer], a
	ld [wCh3FadeIn], a
	ld [wCh3FadeInTimer], a
	ld [wDrop], a
	ld [wDrop+1], a
	ld [wDrop+2], a
	ld [wDrop+3], a
	ld [wDrop+4], a
	ld [wDrop+5], a
	ld [wSfx1Step], a
	ld [wSfx2Step], a
	ld [wSfx3Step], a
	ld [wSfx4Step], a
	ld [wSfx1Timer], a
	ld [wSfx2Timer], a
	ld [wSfx3Timer], a
	ld [wSfx4Timer], a
	ld [wSfx1Priority], a
	ld [wSfx2Priority], a
	ld [wSfx3Priority], a
	ld [wSfx4Priority], a
	ld [wSfx1Var], a
	ld [wSfx2Var], a
	ld [wSfx3Var], a
	ld [wSfx4Var], a
	ld [wCh3SfxPaused], a
	ld [wReloadWave], a
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR10], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	xor a
	ldh [rNR30], a
	ret

	ds $8000 - $621D, 0	; unused
