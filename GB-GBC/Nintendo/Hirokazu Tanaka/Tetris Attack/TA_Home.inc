; Tetris Attack: sound routine in the home bank, $1500-$1644

; Called once per frame by the game (home $0253 / $0291). wPauseRequest 1 = pause (take and
; silence all channels), 2 = resume. Then: SFX (bank $07: Sfx_Update, Noise_Update), a new
; song request (songs below $1D start in bank $08, others in bank $07; the song already
; playing is not restarted), the music of the bank that owns the playing song, and the
; requests are cleared, except a song request $1C or $22 which stays set.
Sound_Frame:
	ld a, [wPauseRequest]
	cp $01
	jp z, Sound_Pause
	cp $02
	jp z, Sound_Unpause
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	jp nz, Sound_Frame_newSong
.update:
	ldh a, [hRomBank]
	push af
	ld a, $07
	ldh [hRomBank], a
	ld [rROMB0], a
	call $4178
	call $4d8e
	pop af
	ldh [hRomBank], a
	ld [rROMB0], a
	ld hl, wSongPlaying
	ld a, [hl]
	cp $1d
	jp c, .bank08
	jp .bank07

; unreachable: jr $1561
	jr .clearRequests

.bank08:
	ldh a, [hRomBank]
	push af
	ld a, $08
	ldh [hRomBank], a
	ld [rROMB0], a
	call $44ed
	pop af
	ldh [hRomBank], a
	ld [rROMB0], a
	jr .clearRequests

.bank07:
	ldh a, [hRomBank]
	push af
	ld a, $07
	ldh [hRomBank], a
	ld [rROMB0], a
	call $6bc2
	pop af
	ldh [hRomBank], a
	ld [rROMB0], a
.clearRequests:
	ld a, [wSongRequest]
	cp $1c
	ret z
	cp $22
	ret z
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ld [wSfxChannels], a
	ret

Sound_Pause:
	ld [wPaused], a
	call Home_TakeCh1
	call Home_TakeCh2
	call Home_TakeCh3
	call Home_TakeCh4
	xor a
	ld [wPauseRequest], a
	jp Sound_Frame.update

Sound_Unpause:
	call Home_ReleaseCh1
	call Home_ReleaseCh2
	call Home_ReleaseCh3
	call Home_ReleaseCh4
	xor a
	ld [wPauseRequest], a
	ld [wPaused], a
	jp Sound_Frame.update

Sound_Frame_newSong:
	cp [hl]
	jp z, Sound_Frame.update
	cp $1d
	jp c, Sound_Frame_start08
	jp Sound_Frame_start07

; unreachable
	jp Sound_Frame.update

Sound_Frame_start08:
	ldh a, [hRomBank]
	push af
	ld a, $08
	ldh [hRomBank], a
	ld [rROMB0], a
	call $4214
	pop af
	ldh [hRomBank], a
	ld [rROMB0], a
	jp Sound_Frame.update

Sound_Frame_start07:
	ldh a, [hRomBank]
	push af
	ld a, $07
	ldh [hRomBank], a
	ld [rROMB0], a
	call $68d7
	pop af
	ldh [hRomBank], a
	ld [rROMB0], a
	jp Sound_Frame.update

Home_ReleaseCh1:
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

Home_TakeCh1:
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	ld a, $00
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ret

Home_ReleaseCh2:
	ld a, [wCh2Flags]
	res 7, a
	ld [wCh2Flags], a
	ret

Home_TakeCh2:
	ld a, [wCh2Flags]
	set 7, a
	ld [wCh2Flags], a
	xor a
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
	ret

Home_ReleaseCh3:
	ld a, [wCh3Flags]
	res 7, a
	ld [wCh3Flags], a
	ret

Home_TakeCh3:
	ld a, [wCh3Flags]
	set 7, a
	ld [wCh3Flags], a
	xor a
	ldh [rNR30], a
	ldh [rNR32], a
	ret

Home_ReleaseCh4:
	ld a, [wCh4Flags]
	res 7, a
	ld [wCh4Flags], a
	ret

Home_TakeCh4:
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	xor a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

