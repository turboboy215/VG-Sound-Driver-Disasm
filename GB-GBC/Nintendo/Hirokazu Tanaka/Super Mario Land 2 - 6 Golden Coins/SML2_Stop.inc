; Super Mario Land 2 sound driver: stop routine, bank 4 $7F5E-$7FFF

; Stop everything: NR51 = $FF, clear the music, effects, pause and effect state, mute.
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
	ld [wPauseRequest], a
	ld [wCh3Fade], a
	ld [wCh3FadeTimer], a
	ld [wSfxVar2C], a
	ld [wBend], a
	ld [wBend+2], a
	ld [wBend+4], a
	ld [wBend+1], a
	ld [wBend+3], a
	ld [wCh3FadeTimer], a
	ld [wDrop], a
	ld [wDrop+1], a
	ld [wDrop+2], a
	ld [wDrop+3], a
	ld [wDrop+4], a
	ld [wDrop+5], a
	ld [wSfx1Step], a
	ld [wPauseStep], a
	ld [wSfx3Step], a
	ld [wSfx4Step], a
	ld [wSfx1Timer], a
	ld [wPauseTimer], a
	ld [wSfx3Timer], a
	ld [wSfx4Timer], a
	ld [wSfx3Pitch+1], a
	ld [wSfx1Priority], a
	ld [wSfxVar37], a
	ld [wSfx3Priority], a
	ld [wSfx4Priority], a
	ld [wVibrato], a
	ld [wVibrato+1], a
	ld [wVibrato+2], a
	ld [wVibrato+3], a
	ld [wQuietMusic], a
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

; unreferenced
Unused_7FFD:
	db $8b, $12, $aa
