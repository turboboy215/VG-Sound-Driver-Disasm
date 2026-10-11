; Super Mario Bros. Deluxe SFX: note requests, shared routines, stop, bank $1F $67F1-$7FFF

; Requests $80-$A6 on ch1: $80 ends the ch1 effect, $81 silences ch1, $82-$A6 play a note
; (NR10 = 8, NR11 = $80, NR12 = $D2, period = SfxNoteTable entry 25 + request - $82).
Sfx1_Note:
	cp $a7
	jr nc, .done
	ld a, [wSfx1Request]
	cp $80
	jr z, .stop
	cp $81
	jr z, .silence
	sub $81
	ld hl, SfxNoteTable+50
	call GetPointer
	ld c, l
	ld a, $80
	or h
	ld b, a
	ld hl, $ff10
	ld a, $08
	ld [hl+], a
	ld a, $80
	ld [hl+], a
	ld a, $d2
	ld [hl+], a
	ld a, c
	ld [hl+], a
	ld a, b
	ld [hl], a
	jr .done

.silence:
	ld hl, $ff12
	ld a, $08
	ld [hl+], a
	ld a, $00
	ld [hl+], a
	ld a, $80
	ld [hl], a
	jr .done

.stop:
	call Sfx1_StopWithRegs
.done:
	xor a
	ld [wSfx1Request], a
	ld [wSfx1Playing], a
	ret

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
	ld de, wSfx4Timer
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

; Count down an effect's private counter; Z at 0. Some of these helpers are unreferenced
; here (they come from LA).
Sfx1_DecCounter:
	push de
	ld de, wSfx1Counter
	jr Sfx_DecCounter

SfxB_DecCounter:
	push de
	ld de, wSfxCounter2
	jr Sfx_DecCounter

Sfx2_DecCounter:
	push de
	ld de, wSfx2Counter
	jr Sfx_DecCounter

Sfx4_DecCounter:
	push de
	ld de, wSfx4Counter
	jr Sfx_DecCounter

Sfx_DecCounter:
	call Sfx_DecTimer
	pop de
	ret

Sfx1_LoadPitch:
	push de
	ld de, wSfx1Pitch
	jr Sfx_LoadPitch

Sfx2_LoadPitch:
	push de
	ld de, wSfx2Pitch
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

SfxB_LoadPitch:
	push de
	ld de, wSfxPitchB
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

Sfx2_AddPitch:
	push de
	ld de, wSfx2Pitch+1
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

SfxB_AddPitch:
	push de
	ld de, wSfxPitchB+1
	ld a, [bc]
	ld c, $18
	push bc
	jr Sfx_AddPitch

; Stop everything: music, effects, panning; mute.
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
	ld [wSfxStep2], a
	ld [wSfx2Step], a
	ld [wSfx4Step], a
	ld [wSfx1Timer], a
	ld [wSfxTimer2], a
	ld [wSfx2Timer], a
	ld [wSfx4Timer], a
	ld [wSfx1Priority], a
	ld [wSfxPriority2], a
	ld [wSfx2Priority], a
	ld [wSfx4Priority], a
	ld [wSfx1Var], a
	ld [wSfxVar2], a
	ld [wSfx2Var], a
	ld [wSfx4Var], a
	ld [wSfx2Paused], a
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
	ldh [rNR10], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	xor a
	ldh [rNR30], a
	ret

	ds 5728, 0	; $69A0-$7FFF unused
