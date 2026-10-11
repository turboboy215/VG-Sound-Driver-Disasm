; Metal Slug 2 SFX: shared routines, stop, bank $29 $799C-$7FFF

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

; Write a register image (b bytes from NRx0/NRx1) and store the following byte as the new
; timer ([de]).
SetRegs_Ch1:
	ld b, $05
	ld c, $10
	jp SetRegs_Copy

SetRegs_Ch2:
	ld b, $04
	ld c, $16
	jp SetRegs_Copy

SetRegs_Ch3:
	ld b, $05
	ld c, $1a
	jp SetRegs_Copy

SetRegs_Ch4:
	ld b, $04
	ld c, $20
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
	jp Sfx_DecCounter

Sfx2_DecCounter_Unused:
	push de
	ld de, wSfxCounter2
	jp Sfx_DecCounter

Sfx3_DecCounter:
	push de
	ld de, wSfx3Counter
	jp Sfx_DecCounter

Sfx4_DecCounter:
	push de
	ld de, wSfx4Counter
Sfx_DecCounter:
	call Sfx_DecTimer
	pop de
	ret

; Copy the period of a register image (hl) into the effect's pitch variable.
Sfx1_LoadPitch:
	push de
	ld de, wSfx1Pitch
	jp Sfx_LoadPitch

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
	jp Sfx_AddPitch

Sfx3_AddPitch:
	push de
	ld de, wSfx3Pitch+1
	ld a, [bc]
	ld c, $1d
	push bc
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
	jp Sfx_AddPitch

; Stop everything: music, effects, panning; mute. Ends with LA DX's write of 0 to rP1.
Sound_Stop:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
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
	ld [wSfxStep2], a
	ld [wSfx3Step], a
	ld [wSfx4Step], a
	ld [wSfx1Timer], a
	ld [wSfxTimer2], a
	ld [wSfx3Timer], a
	ld [wSfx4Timer], a
	ld [wSfx1Priority], a
	ld [wSfxPriority2], a
	ld [wSfx3Priority], a
	ld [wSfx4Priority], a
	ld [wSfx1Var], a
	ld [wSfxVar2], a
	ld [wSfx3Var], a
	ld [wSfx4Var], a
	ld [wCh3SfxPaused], a
	ld [wSfx1Var2], a
	ld [wSfx1Var3], a
	ld [wSfx1Var4], a
	ld [wSfxVarDC], a
	ld [wReloadWave], a
	ld [wSfx1Var5], a
	ld [wSfxVarE3], a
	ld [wSfxVarE4], a
	ld [wSfxVarE5], a
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
	ldh [rP1], a
	ret

	ds 1286, 0	; $7AFA-$7FFF unused
