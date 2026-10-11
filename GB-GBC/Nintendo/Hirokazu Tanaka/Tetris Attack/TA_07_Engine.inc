; Tetris Attack SFX and music, bank $07: SFX engine entry, tables, $4000-$4254

; Stop the music (same routine as bank $08's, without the SFX channel checks).
Sound_StopMusic:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
Music_ClearState:
	xor a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld [wD35D], a
	ld [wD35E], a
	ld [wFadeTimer], a
	ld [wFadeStep], a
	xor a
	ld [wCh1Flags], a
	xor a
	ldh [rNR10], a
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
	xor a
	ld [wCh2Flags], a
	xor a
	ldh [rNR30], a
	ldh [rNR31], a
	ld [wCh3Flags], a
	ld a, $80
	ldh [rNR34], a
	xor a
	ld [wCh4Flags], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; Silence all four channels (registers only; called by effects that take every channel).
Sfx_MuteAll:
	xor a
	ldh [rNR10], a
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
	xor a
	ldh [rNR30], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; Jump through the table that follows the call: a = 0-based index.
JumpTable:
	sla a
	ld d, $00
	ld e, a
	pop hl
	add hl, de
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Sfx_00:
	ret

; Write b bytes from hl to the registers from c.
WriteRegs:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, WriteRegs
	ret

FillBytes:
	ld [hl+], a
	dec b
	jr nz, FillBytes
	ret

SetStreamCh1:
	ld a, h
	ld [wSfxPtrCh1], a
	ld a, l
	ld [wSfxPtrCh1+1], a
	ret

SetStreamCh2:
	ld a, b
	ld [wSfxPtrCh2], a
	ld a, c
	ld [wSfxPtrCh2+1], a
	ret

SetStreamCh4:
	ld a, d
	ld [wSfxPtrCh4], a
	ld a, e
	ld [wSfxPtrCh4+1], a
	ret

SetNoiseStream:
	ld a, d
	ld [wNoisePtr], a
	ld a, e
	ld [wNoisePtr+1], a
	ret

; unreferenced: reload the music's wave from the copy at wWaveCopy.
RestoreWave:
	ld c, $30
	ld hl, wWaveCopy
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jr nz, .loop
	ret

; Give a channel back to the music (Flags bit 7) / take it (and silence it).
ReleaseCh1:
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

TakeCh1:
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	ld a, $00
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ret

ReleaseCh2:
	ld a, [wCh2Flags]
	res 7, a
	ld [wCh2Flags], a
	ret

TakeCh2:
	ld a, [wCh2Flags]
	set 7, a
	ld [wCh2Flags], a
	xor a
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
	ret

ReleaseCh3:
	ld a, [wCh3Flags]
	res 7, a
	ld [wCh3Flags], a
	ret

TakeCh3:
	ld a, [wCh3Flags]
	set 7, a
	ld [wCh3Flags], a
	xor a
	ldh [rNR30], a
	ldh [rNR32], a
	ret

ReleaseCh4:
	ld a, [wCh4Flags]
	res 7, a
	ld [wCh4Flags], a
	ret

TakeCh4:
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	xor a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; one byte per effect $00-$50: an effect starts only if its value is <= the priority of the
; one playing (wSfxPriority, $FF = none). Then $FF padding.
SfxPriorityTable:
	db $ff, $00, $00, $00, $03, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02	; $00-
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02	; $10-
	db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $01, $01, $01	; $20-
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $04, $03, $00, $00, $04, $00, $00	; $30-
	db $01, $01, $01, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; $40-
	db $00	; $50-
	ds 7, $ff
; Called once per frame (from the home routine $1500). wSfx1Request = effect $01-$50.
Sfx_Update:
	ld a, [wSfx1Request]
	cp $00
	jr nz, .request
.play:
	ld a, [wSfx1Playing]
	and a
	jp nz, Sfx_PlayStreams
	ret

.request:
	ld hl, SfxPriorityTable
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [wSfxPriority]
	cp [hl]
	jp c, Sfx_PlayStreams
	ld a, c
	ld [wSfx1Playing], a
	push af
	ld a, [wSfxActive]
	cp $00
	jr nz, .dispatch
	ld a, $01
	ld b, $04
	ld hl, wSfxFramesCh1
	call FillBytes
	xor a
	ld [wSfxActive], a
.dispatch:
	pop af
	call JumpTable
; effect init routines, $00-$50 (dw table read by JumpTable)
SfxInitTable:
	dw Sfx_00
	dw Sfx_01
	dw Sfx_02
	dw Sfx_03
	dw Sfx_04
	dw Sfx_05
	dw Sfx_06
	dw Sfx_07
	dw Sfx_08
	dw Sfx_09
	dw Sfx_0A
	dw Sfx_0B
	dw Sfx_0C
	dw Sfx_0D
	dw Sfx_0E
	dw Sfx_0F
	dw Sfx_10
	dw Sfx_11
	dw Sfx_12
	dw Sfx_13
	dw Sfx_14
	dw Sfx_15
	dw Sfx_16
	dw Sfx_17
	dw Sfx_18
	dw Sfx_19
	dw Sfx_1A
	dw Sfx_1B
	dw Sfx_1C
	dw Sfx_1D
	dw Sfx_1E
	dw Sfx_1F
	dw Sfx_20
	dw Sfx_21
	dw Sfx_22
	dw Sfx_23
	dw Sfx_24
	dw Sfx_25
	dw Sfx_26
	dw Sfx_27
	dw Sfx_28
	dw Sfx_29
	dw Sfx_2A
	dw Sfx_2B
	dw Sfx_2C
	dw Sfx_2D
	dw Sfx_2E
	dw Sfx_2F
	dw Sfx_30
	dw Sfx_31
	dw Sfx_32
	dw Sfx_33
	dw Sfx_34
	dw Sfx_35
	dw Sfx_36
	dw Sfx_37
	dw Sfx_38
	dw Sfx_39
	dw Sfx_3A
	dw Sfx_3B
	dw Sfx_3C
	dw Sfx_3D
	dw Sfx_3E
	dw Sfx_3F
	dw Sfx_40
	dw Sfx_41
	dw Sfx_42
	dw Sfx_43
	dw Sfx_44
	dw Sfx_45
	dw Sfx_46
	dw Sfx_46
	dw Sfx_48
	dw Sfx_49
	dw Sfx_4A
	dw Sfx_4B
	dw Sfx_4C
	dw Sfx_4D
	dw Sfx_4E
	dw Sfx_4F
	dw Sfx_50
