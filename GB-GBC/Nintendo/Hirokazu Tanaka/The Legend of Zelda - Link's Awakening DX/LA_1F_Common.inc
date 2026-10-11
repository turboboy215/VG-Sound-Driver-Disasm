; Link's Awakening DX SFX, bank $1F: shared routines, stop, volume, bank $1F $7A64-$7FFF

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
	ld [de], a
	ret

; Count down an effect's private counter; Z at 0.
Sfx1_DecCounter:
	push de
	ld de, wSfx1Counter
	jr Sfx_DecCounter

Sfx2_DecCounter_Unused:
	push de
	ld de, wSfxCounter2
	jr Sfx_DecCounter

Sfx3_DecCounter:
	push de
	ld de, wSfx3Counter
	jr Sfx_DecCounter

Sfx4_DecCounter:
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

Sfx4_40_Init:
	ld hl, Sfx4_40_Data_7B3E
	jp Sfx4_Start

Sfx4_40_Play:
	call Sfx_DecTimer
	ret nz
	call Sfx_IncStep
	cp $05
	jp z, Sfx4_StopWithRegs
	ld hl, Sfx4_40_Data_7B36
	call GetPointer
	jp SetRegs_Ch4

Sfx4_40_Data_7B36:
	dw Sfx4_40_Data_7B48, Sfx4_40_Data_7B4D, Sfx4_40_Data_7B52, Sfx4_40_Data_7B57
Sfx4_40_Data_7B3E:
	db $00, $f8, $1d, $80, $01
	db $00, $f8, $1d, $80, $01
Sfx4_40_Data_7B48:
	db $00, $f8, $01, $80, $01
Sfx4_40_Data_7B4D:
	db $00, $59, $11, $80, $03
Sfx4_40_Data_7B52:
	db $01, $c8, $17, $80, $01
Sfx4_40_Data_7B57:
	db $00, $f5, $11, $80, $01
; Stop everything: music, effects, panning; mute. The DX version ends with a write of 0
; to rP1 and then runs through $380 bytes of nop into Sound_Volume.
Sound_Stop:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
	xor a
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
	REPT $380	; nop slide from Sound_Stop into Sound_Volume
	nop
	ENDR
; DX addition, called by the game every frame (and reached from Sound_Stop): master volume
; fades (hVolumeFadeOut / hVolumeFadeIn step NR50 down / up every 4 / 2 frames), then
; copy the HRAM SFX requests into wSfx1Request / wSfx3Request / wSfx4Request.
Sound_Volume:
	ldh a, [hVolumeFadeOut]
	and a
	jr z, .fadeIn
	sub $01
	ldh [hVolumeFadeOut], a
	and $03
	jr nz, .fadeIn
	ldh a, [hVolumeLeft]
	and a
	jr z, .right
	dec a
	ldh [hVolumeLeft], a
.right:
	ldh a, [hVolumeRight]
	and a
	jr z, .fadeIn
	sub $10
	ldh [hVolumeRight], a
.fadeIn:
	ldh a, [hVolumeFadeIn]
	and a
	jr z, .write
	sub $01
	ldh [hVolumeFadeIn], a
	and $01
	jr nz, .write
	ldh a, [hVolumeLeft]
	cp $07
	jr nc, .fadeInRight
	inc a
	ldh [hVolumeLeft], a
.fadeInRight:
	ldh a, [hVolumeRight]
	cp $70
	jr nc, .write
	add a, $10
	ldh [hVolumeRight], a
.write:
	ld hl, hVolumeLeft
	ldh a, [rNR50]
	and $f8
	or [hl]
	inc hl
	and $8f
	or [hl]
	ldh [rNR50], a
	ldh a, [hSfx1Request]
	and a
	jr z, .req3
	ld [wSfx1Request], a
	xor a
	ldh [hSfx1Request], a
.req3:
	ldh a, [hSfx3Request]
	and a
	jr z, .req4
	ld [wSfx3Request], a
	xor a
	ldh [hSfx3Request], a
.req4:
	ldh a, [hSfx4Request]
	and a
	jr z, .done
	ld [wSfx4Request], a
	xor a
	ldh [hSfx4Request], a
.done:
	ret

	ds $8000 - $7FEE, 0	; unused
