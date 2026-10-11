; Link's Awakening DX music, bank $1B: stop routines, bank $1B $4E2C-$4FFF

; Stop everything this bank controls: ch4 effect, panning, music, mute.
Sound_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [$d3c9], a
	ld [wSfx4Var], a
	ld [$d3e5], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
Sound_StopMusic:
	ld a, $ff
	ldh [rNR51], a
	ld a, $03
	ld [wPanMode], a
	xor a
	ld [wSongPlaying], a
; Clear the music effect state and mute ch1-ch3.
Music_ClearState:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wCh1Flags], a
	ld [wCh2Flags], a
	ld [wCh3Flags], a
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
	ld [wSfx1Timer], a
	ld [wSfxTimer2], a
	ld [wSfx3Timer], a
	ld [$d3c6], a
	ld [$d3c7], a
	ld [$d3c8], a
	ld [wSfx1Var], a
	ld [wSfxVar2], a
	ld [wSfx3Var], a
	ld [wCh3SfxPaused], a
	ld [$d3d6], a
	ld [$d3d7], a
	ld [$d3d8], a
	ld [$d3dc], a
	ld [wReloadWave], a
	ld [$d3e2], a
	ld [$d3e3], a
	ld [$d3e4], a
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	xor a
	ldh [rNR10], a
	ldh [rNR30], a
	ret

	ds 298, 0	; $4ED6-$4FFF unused
