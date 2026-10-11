; Super Mario Bros. Deluxe music: stop routines, bank $1D $4DA2-$4FFF

; Stop everything this bank controls: ch4 effect, panning, music, mute.
Sound_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [wSfx4Priority], a
	ld [wSfx4Var], a
	ld [wSfxVarE5], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
Sound_StopMusic:
	ld a, $ff
	ldh [rNR51], a
	ld a, $01
	ld [wPanMode], a
	xor a
	ld [wSongRequest], a
	ld [wSongPlaying], a
Music_ClearState:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx2Playing], a
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
	ld [wSfx2Step], a
	ld [wSfx1Timer], a
	ld [wSfxTimer2], a
	ld [wSfx2Timer], a
	ld [wSfx1Priority], a
	ld [wSfxPriority2], a
	ld [wSfx2Priority], a
	ld [wSfx1Var], a
	ld [wSfxVar2], a
	ld [wSfx2Var], a
	ld [wSfx2Paused], a
	ld [wSfx1Var2], a
	ld [wSfx1Var3], a
	ld [wSfx1Var4], a
	ld [wSfxVarDC], a
	ld [wReloadWave], a
	ld [wSfx1Var5], a
	ld [wSfxVarE3], a
	ld [wSfxVarE4], a
	xor a
	ld [wPausedSong], a
	ld [wDED3], a
	ld a, $11
	ld [wCh1RestEnv], a
	ld [wCh2RestEnv], a
	ld a, $77
	ldh [rNR50], a
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ld a, $08
	ldh [rNR10], a
	xor a
	ldh [rNR32], a
	ret

	ds 411, 0	; $4E64-$4FFE unused
; Called whenever any request is pending: empty.
Music_RequestHook:
	ret

