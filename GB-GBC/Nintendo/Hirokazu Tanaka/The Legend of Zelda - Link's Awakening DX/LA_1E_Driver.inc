; Link's Awakening DX music, bank $1E: music driver and tables, bank $1E $4000-$4B1B

; Entry points: init, stop, update.
	jp Music_Init

	jp Sound_Stop

	jp Music_Update

; Clear $D300-$D3FF and switch the APU on.
Music_Init:
	ld hl, wTranspose
.clear:
	ld [hl], $00
	inc l
	jr nz, .clear
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	ret

; Called once per frame after bank $1B's update. Starts a song from this bank, plays
; the music, then clears all four request bytes for the next frame.
Music_Update:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	jr nz, Music_Update_start
	call MusicDrum_Update
.play:
	call Music_Play
; Clear the song and SFX requests. Also where requests for bank $1B's songs end up.
Music_ClearRequests:
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ret

Music_Update_start:
	ld [hl], a
	call Music_StartSong
	jr Music_Update.play

; Pattern byte $FF on ch4 plays this two-step noise drum (wSfx4Request = 1) unless an SFX
; owns ch4.
MusicDrum_Update:
	ld de, wSfx4Timer
	ld hl, wSfx4Request
	ld a, [hl+]
	cp $01
	jr z, .start
	ld a, [hl]
	cp $01
	jr z, .playing
	ret

.start:
	ld a, $01
	ld [wSfx4Playing], a
	ld hl, MusicDrum_StartRegs
	jp MusicDrum_WriteRegs

.playing:
	ld a, [de]
	dec a
	ld [de], a
	ret nz
	xor a
	ld [wSfx4Playing], a
	ld hl, MusicDrum_EndRegs
	jr MusicDrum_WriteRegs

MusicDrum_StartRegs:
	db $3b, $80, $07, $c0, $02	; NR41-NR44, frames
MusicDrum_EndRegs:
	db $00, $42, $02, $c0, $04	; NR41-NR44, frames
MusicDrum_WriteRegs:
	ld b, $04
	ld c, $20
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .loop
	ld a, [hl]
	ld [de], a
	ret

Data_407F:
	dw Song11_Header	; $01 = song $11
	dw Song12_Header	; $02 = song $12
	dw Song13_Header	; $03 = song $13
	dw Song14_Header	; $04 = song $14
	dw Song15_Header	; $05 = song $15
	dw Song16_Header	; $06 = song $16
	dw Song17_Header	; $07 = song $17
	dw Song18_Header	; $08 = song $18
	dw Song19_Header	; $09 = song $19
	dw Song1A_Header	; $0a = song $1a
	dw Song1B_Header	; $0b = song $1b
	dw Song1C_Header	; $0c = song $1c
	dw Song1D_Header	; $0d = song $1d
	dw Song1E_Header	; $0e = song $1e
	dw Song1F_Header	; $0f = song $1f
	dw Song20_Header	; $10 = song $20
	dw Song21_Header	; $11 = song $21
	dw Song22_Header	; $12 = song $22
	dw Song23_Header	; $13 = song $23
	dw Song24_Header	; $14 = song $24
	dw Song25_Header	; $15 = song $25
	dw Song26_Header	; $16 = song $26
	dw Song27_Header	; $17 = song $27
	dw Song28_Header	; $18 = song $28
	dw Song29_Header	; $19 = song $29
	dw Song2A_Header	; $1a = song $2a
	dw Song2B_Header	; $1b = song $2b
	dw Song2C_Header	; $1c = song $2c
	dw Song2D_Header	; $1d = song $2d
	dw Song2E_Header	; $1e = song $2e
	dw Song2F_Header	; $1f = song $2f
	dw Song30_Header	; $20 = song $30
	dw Song41_Header	; $21 = song $41
	dw Song42_Header	; $22 = song $42
	dw Song43_Header	; $23 = song $43
	dw Song44_Header	; $24 = song $44
	dw Song45_Header	; $25 = song $45
	dw Song46_Header	; $26 = song $46
	dw Song47_Header	; $27 = song $47
	dw Song48_Header	; $28 = song $48
	dw Song49_Header	; $29 = song $49
	dw Song4A_Header	; $2a = song $4a
	dw Song4B_Header	; $2b = song $4b
	dw Song4C_Header	; $2c = song $4c
	dw Song4D_Header	; $2d = song $4d
	dw Song4E_Header	; $2e = song $4e
	dw Song4F_Header	; $2f = song $4f
	dw Song50_Header	; $30 = song $50
	dw Song13_Header	; $31 = song $51
	dw Song14_Header	; $32 = song $52
	dw Song53_Header	; $33 = song $53
	dw Song54_Header	; $34 = song $54
	dw Song55_Header	; $35 = song $55
	dw Song56_Header	; $36 = song $56
	dw Song57_Header	; $37 = song $57
	dw Song58_Header	; $38 = song $58
	dw Song59_Header	; $39 = song $59
	dw Song5A_Header	; $3a = song $5a
	dw Song5B_Header	; $3b = song $5b
	dw Song5C_Header	; $3c = song $5c
	dw Song5D_Header	; $3d = song $5d
	dw Song5E_Header	; $3e = song $5e
	dw Song5F_Header	; $3f = song $5f
	dw Song60_Header	; $40 = song $60
; hl = table, a = 1-based index: hl = table[a-1] (and e = e+1, a = h).
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

; Cancel the ch4 SFX and mute ch4.
StopSfx4:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [$d3c9], a
	ld [wSfx4Var], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; Song request $FF. Ch4 effects $05, $0C, $1A, $24, $2A, $2E and $3F keep playing; any
; other ch4 effect is cancelled.
Music_Stop:
	ld a, [wSfx4Playing]
	cp $05
	jp z, Sound_StopMusic
	cp $0c
	jp z, Sound_StopMusic
	cp $1a
	jp z, Sound_StopMusic
	cp $24
	jp z, Sound_StopMusic
	cp $2a
	jp z, Sound_StopMusic
	cp $2e
	jp z, Sound_StopMusic
	cp $3f
	jp z, Sound_StopMusic
	call StopSfx4
	jp Sound_StopMusic

; Ignored while bank $1B plays (wMusicIn1B). Map the song number onto this bank:
; $11-$30 -> $01-$20, $41-$60 -> $21-$40.
Music_StartSong:
	ld b, a
	ld a, [wMusicIn1B]
	and a
	jp nz, Music_ClearRequests
	ld a, b
	cp $ff
	jr z, Music_Stop
	cp $11
	jr nc, .not1x
	jp Music_ClearRequests

.not1x:
	cp $21
	jr nc, .not2x
	add a, $f0
	jr .inBank

.not2x:
	cp $31
	jr nc, .not3x
	add a, $f0
	jr .inBank

.not3x:
	cp $41
	jp c, Music_ClearRequests
	cp $61
	jp nc, Music_ClearRequests
	add a, $e0
.inBank:
	dec hl
	ld [hl+], a
	ld [hl-], a
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
	ld a, [hl+]
	ld [wCurrentSong], a
	ld b, a
	ld hl, Data_407F
	and $7f
	call GetPointer
	call Music_LoadHeader
	jp Music_InitPanning

; Panning: mode (1 = fixed), period, NR51 x4 for each table entry. All entries are fixed $FF.
Data_41AF:
	db $01, $00, $ff, $ff, $00, $00	; $01
	db $01, $00, $ff, $ff, $00, $00	; $02
	db $01, $00, $ff, $ff, $00, $00	; $03
	db $01, $00, $ff, $ff, $00, $00	; $04
	db $01, $00, $ff, $ff, $00, $00	; $05
	db $01, $00, $ff, $ff, $00, $00	; $06
	db $01, $00, $ff, $ff, $00, $00	; $07
	db $01, $00, $ff, $ff, $00, $00	; $08
	db $01, $00, $ff, $ff, $00, $00	; $09
	db $01, $00, $ff, $ff, $00, $00	; $0a
	db $01, $00, $ff, $ff, $00, $00	; $0b
	db $01, $00, $ff, $ff, $00, $00	; $0c
	db $01, $00, $ff, $ff, $00, $00	; $0d
	db $01, $00, $ff, $ff, $00, $00	; $0e
	db $01, $00, $ff, $ff, $00, $00	; $0f
	db $01, $00, $ff, $ff, $00, $00	; $10
	db $01, $00, $ff, $ff, $00, $00	; $11
	db $01, $00, $ff, $ff, $00, $00	; $12
	db $01, $00, $ff, $ff, $00, $00	; $13
	db $01, $00, $ff, $ff, $00, $00	; $14
	db $01, $00, $ff, $ff, $00, $00	; $15
	db $01, $00, $ff, $ff, $00, $00	; $16
	db $01, $00, $ff, $ff, $00, $00	; $17
	db $01, $00, $ff, $ff, $00, $00	; $18
	db $01, $00, $ff, $ff, $00, $00	; $19
	db $01, $00, $ff, $ff, $00, $00	; $1a
	db $01, $00, $ff, $ff, $00, $00	; $1b
	db $01, $00, $ff, $ff, $00, $00	; $1c
	db $01, $00, $ff, $ff, $00, $00	; $1d
	db $01, $00, $ff, $ff, $00, $00	; $1e
	db $01, $00, $ff, $ff, $00, $00	; $1f
	db $01, $00, $ff, $ff, $00, $00	; $20
	db $01, $00, $ff, $ff, $00, $00	; $21
	db $01, $00, $ff, $ff, $00, $00	; $22
	db $01, $00, $ff, $ff, $00, $00	; $23
	db $01, $00, $ff, $ff, $00, $00	; $24
	db $01, $00, $ff, $ff, $00, $00	; $25
	db $01, $00, $ff, $ff, $00, $00	; $26
	db $01, $00, $ff, $ff, $00, $00	; $27
	db $01, $00, $ff, $ff, $00, $00	; $28
	db $01, $00, $ff, $ff, $00, $00	; $29
	db $01, $00, $ff, $ff, $00, $00	; $2a
	db $01, $00, $ff, $ff, $00, $00	; $2b
	db $01, $00, $ff, $ff, $00, $00	; $2c
	db $01, $00, $ff, $ff, $00, $00	; $2d
	db $01, $00, $ff, $ff, $00, $00	; $2e
	db $01, $00, $ff, $ff, $00, $00	; $2f
	db $01, $00, $ff, $ff, $00, $00	; $30
	db $01, $00, $ff, $ff, $00, $00	; $31
	db $01, $00, $ff, $ff, $00, $00	; $32
	db $01, $00, $ff, $ff, $00, $00	; $33
	db $01, $00, $ff, $ff, $00, $00	; $34
	db $01, $00, $ff, $ff, $00, $00	; $35
	db $01, $00, $ff, $ff, $00, $00	; $36
	db $01, $00, $ff, $ff, $00, $00	; $37
	db $01, $00, $ff, $ff, $00, $00	; $38
	db $01, $00, $ff, $ff, $00, $00	; $39
	db $01, $00, $ff, $ff, $00, $00	; $3a
	db $01, $00, $ff, $ff, $00, $00	; $3b
	db $01, $00, $ff, $ff, $00, $00	; $3c
	db $01, $00, $ff, $ff, $00, $00	; $3d
	db $01, $00, $ff, $ff, $00, $00	; $3e
	db $01, $00, $ff, $ff, $00, $00	; $3f
	db $01, $00, $ff, $ff, $00, $00	; $40
; Ch3 trigger: reload the music wave first if an SFX overwrote wave RAM (wReloadWave).
Music_ReloadWave:
	ld a, [wReloadWave]
	and a
	jp z, Music_Trigger.write
	xor a
	ldh [rNR30], a
	ld [wReloadWave], a
	push hl
	ld a, [wCh3WavePtr]
	ld l, a
	ld a, [wCh3WavePtr+1]
	ld h, a
	push bc
	ld c, $30
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jr nz, .loop
	ld a, $80
	ldh [rNR30], a
	pop bc
	pop hl
	jp Music_Trigger.write

Music_InitPanning:
	ld a, [wSongPlaying]
	ld hl, Data_41AF
.find:
	dec a
	jr z, .found
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	jr .find

.found:
	ld bc, wPanMode
	ld a, [hl+]
	ld [bc], a
	inc c
	xor a
	ld [bc], a
	inc c
	ld a, [hl+]
	ld [bc], a
	inc c
	xor a
	ld [bc], a
	inc c
	ld a, [hl+]
	ld [bc], a
	ldh [rNR51], a
	inc c
	ld a, [hl+]
	ld [bc], a
	inc c
	ld a, [hl+]
	ld [bc], a
	inc c
	ld a, [hl+]
	ld [bc], a
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
	ld a, [hl+]
	and $03
	ld c, l
	ld b, h
	and a
	jr z, .write
	inc c
	cp $01
	jr z, .write
	inc c
	cp $02
	jr z, .write
	inc c
.write:
	ld a, [bc]
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

; Same ch4 effect exceptions as Music_Stop, then load the 11-byte song header.
Music_LoadHeader:
	ld a, [wSfx4Playing]
	cp $05
	jr z, .load
	cp $0c
	jr z, .load
	cp $1a
	jr z, .load
	cp $24
	jr z, .load
	cp $2a
	jr z, .load
	cp $2e
	jr z, .load
	cp $3f
	jr z, .load
	call StopSfx4
.load:
	call Music_ClearState
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
	ld a, [wSfx3Playing]
	and a
	jr nz, .done
	xor a
	ldh [rNR30], a
	ld l, e
	ld h, d
	call LoadWave
.done:
	pop hl
	jr Music_NextByte

; $9D: three bytes to Env/Release/Duty. ch3: wave pointer + level; the wave is loaded
; unless a ch3 SFX plays.
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

; Frame without a new note: ch3 drops to 50% (NR32 = $40) 6 frames before the end of a
; note when bit 7 of the level is set; then pitch effects and the release envelope.
Music_Sustain:
	ld a, [wMusicChannel]
	cp $03
	jr nz, .effects
	ld a, [wCh3Level]
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
	call Music_Effects
	push hl
	call Music_Release
	pop hl
Music_ChannelDone:
	dec l
	dec l
	jp Music_NextChannel

; $00: next list entry; $0000 ends the song, $FFFF + address loops.
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

; Song end. Jingles $0F, $10 and $25 then restart the song saved in hResumeSong.
.songEnd:
	ld a, [wCurrentSong]
	cp $15
	jp z, Music_ResumeSong
	ld hl, wSongPlaying
	ld [hl], $00
	call Music_Stop
	ret

Cmd_Tempo:
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable], a
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable+1], a
	jr Cmd_SkipAndContinue

Cmd_Transpose:
	call IncPtr
	call ReadPtrByte
	ld [wTranspose], a
Cmd_SkipAndContinue:
	call IncPtr
	jr Music_ReadCommand

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

; Music: four 16-byte channel structures at wCh1ListPtr + $10*n.
Music_Play:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, [wMusicIn1B]
	and a
	jp nz, Music_ClearRequests
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
; Commands $94-$9F, lengths $A0-$AF. A length also sets the release point when the
; instrument's Release byte has a high nibble: bit 7 = half the length, bit 6 = a quarter,
; otherwise three quarters (at least 2), stored in wReleaseFrame (ch1/ch2).
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
	cp $99
	jp z, Cmd_Ch3FadeOutOn
	cp $9a
	jp z, Cmd_Ch3FadeOutOff
	cp $94
	jp z, Cmd_Ch3FadeInOn
	cp $97
	jp z, Cmd_DropOn
	cp $98
	jp z, Cmd_DropOff
	cp $96
	jp z, Cmd_Ch3SfxPause
	cp $95
	jp z, Cmd_Ch3SfxResume
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
	push hl
	ld d, a
	inc l
	inc l
	inc l
	ld a, [hl]
	and $f0
	jr nz, Music_Length_release
	ld a, d
	jr Music_Length_done

Music_Length_release:
	ld e, a
	ld a, d
	push af
	srl a
	sla e
	jr c, Music_Length_store
	ld d, a
	srl a
	sla e
	jr c, Music_Length_store
	add a, d
Music_Length_store:
	ld c, a
	and a
	jr nz, Music_Length_storeRelease
	ld c, $02
Music_Length_storeRelease:
	ld de, wMusicChannel
	ld a, [de]
	dec a
	ld e, a
	ld d, $00
	ld hl, wReleaseFrame
	add hl, de
	ld [hl], c
	pop af
Music_Length_done:
	pop hl
	dec l
	ld [hl+], a
	call IncPtr
	call ReadPtrByte
; Note: restart the vibrato / drop state of the channel and the ch3 fades.
Music_Note:
	ld a, [wMusicChannel]
	cp $04
	jr z, .lookup
	push de
	ld de, wVibrato
	call IndexByChannel
	xor a
	ld [de], a
	inc e
	ld [de], a
	ld de, wDrop
	call IndexByChannel
	inc e
	xor a
	ld [de], a
	ld a, [wMusicChannel]
	cp $03
	jr nz, .effectsDone
	ld de, wCh3FadeOut
	ld a, [de]
	and a
	jr z, .fadeIn
	ld a, $01
	ld [de], a
	xor a
	ld [wCh3FadeOutTimer], a
.fadeIn:
	ld de, wCh3FadeIn
	ld a, [de]
	and a
	jr z, .effectsDone
	ld a, $01
	ld [de], a
	xor a
	ld [wCh3FadeInTimer], a
.effectsDone:
	pop de
.lookup:
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
	jr z, .table
	ld l, a
	ld h, $00
	bit 7, l
	jr z, .addTranspose
	ld h, $ff
.addTranspose:
	add hl, bc
	ld b, h
	ld c, l
.table:
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

; ch4: the pattern byte is an offset into NoiseTable (5 bytes: NR42, unused, NR41, NR43,
; NR44); $FF plays the music drum instead.
Music_NoiseNote:
	push hl
	ld a, c
	cp $ff
	jr z, .drum
	ld de, wCh4InstrEnv
	ld hl, NoiseTable
	add hl, bc
.copy:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, e
	cp $4b
	jr nz, .copy
	ld c, $20
	ld hl, wCh4PatPtr
	ld b, $00
	jr Music_Trigger.readInstr

.drum:
	ld a, [wCh4Flags]
	bit 7, a
	jp nz, Music_Trigger.done
	ld a, $01
	ld [wSfx4Request], a
	call MusicDrum_Update
	jp Music_Trigger.done

; Write the note: NRx1 = Duty, NRx2 = Env (rest: $08), period, NRx4 | $80. Nothing is
; written while an SFX owns the channel (Flags bit 7).
Music_Trigger:
	push hl
	ld b, $00
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
	jr .checkRest

.ch2:
	ld c, $16
	jr .readInstr

.ch1:
	ld c, $10
	inc c
.readInstr:
	inc l
	inc l
	ld a, [hl+]
	ld e, a
	inc l
	ld a, [hl+]
	ld d, a
.checkRest:
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
	ld a, [wMusicChannel]
	cp $03
	jp z, Music_ReloadWave
.write:
	ld a, d
	or b
	ldh [c], a
	inc c
	ld a, e
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl]
	or $80
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

Music_Effects_ret:
	pop hl
	ret

Music_Effects:
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	and $0f
	jr z, .drop
	ld [wPitchEffect], a
	ld a, [wMusicChannel]
	ld c, $13
	cp $01
	jr z, .pitch
	ld c, $18
	cp $02
	jr z, .pitch
	ld c, $1d
	cp $03
	jr z, .pitch
.drop:
	ld a, [wMusicChannel]
	cp $04
	jp z, Music_Effects_ret
	ld de, wDrop
	call IndexByChannel
	ld a, [de]
	and a
	jp z, .ch3
	ld a, [wMusicChannel]
	ld c, $13
	cp $01
	jp z, Music_Drop
	ld c, $18
	cp $02
	jp z, Music_Drop
	ld c, $1d
	jp Music_Drop

.ch3:
	ld a, [wMusicChannel]
	cp $03
	jp nz, Music_Effects_ret
	ld a, [wCh3FadeOut]
	and a
	jp nz, Music_Ch3FadeOut
	ld a, [wCh3FadeIn]
	and a
	jp nz, Music_Ch3FadeIn
	jp Music_Effects_ret

.pitch:
	inc l
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	and $0f
	ld d, a
	push de
	ld a, l
	add a, $04
	ld l, a
	ld b, [hl]
	ld a, [wPitchEffect]
	cp $01
	jp z, Music_Vibrato
	ld hl, $ffff
	pop de
	add hl, de
	call WritePitch
	jp .drop

; Release: at NoteFrames = wReleaseFrame, write ReleaseEnvelopes[low nibble - 1] to
; NRx2 and retrigger (ch1, ch2 only).
Music_Release:
	ld a, [wCh1Rest]
	and a
	jr nz, .ch2
	ld a, [wCh1InstrRelease]
	and a
	jr z, .ch2
	and $0f
	ld b, a
	ld hl, wReleaseFrame
	ld a, [wCh1NoteFrames]
	cp [hl]
	jr nz, .ch2
	ld c, $12
	ld de, wCh1Freq+1
	ld a, [wCh1Flags]
	bit 7, a
	jr nz, .ch2
	call Music_ReleaseWrite
.ch2:
	ld a, [wCh2Rest]
	and a
	ret nz
	ld a, [wCh2InstrRelease]
	and a
	ret z
	and $0f
	ld b, a
	ld hl, wReleaseFrame+1
	ld a, [wCh2NoteFrames]
	cp [hl]
	ret nz
	ld a, [wCh2Flags]
	bit 7, a
	ret nz
	ld c, $17
	ld de, wCh2Freq+1
	call Music_ReleaseWrite
	ret

Music_ReleaseWrite:
	push bc
	dec b
	ld c, b
	ld b, $00
	ld hl, ReleaseEnvelopes
	add hl, bc
	ld a, [hl]
	pop bc
	ldh [c], a
	inc c
	inc c
	ld a, [de]
	or $80
	ldh [c], a
	ret

Music_ResumeSong:
	xor a
	ld [wMusicIn1B], a
	ldh a, [hResumeSong]
	ld [wSongRequest], a
	jp Music_Update

; $96 / $95: pause / resume the ch3 SFX (the SFX bank skips its ch3 update).
Cmd_Ch3SfxPause:
	ld a, $01
Cmd_Ch3Sfx_store:
	ld [wCh3SfxPaused], a
	call IncPtr
	jp Music_ReadCommand

Cmd_Ch3SfxResume:
	xor a
	jr Cmd_Ch3Sfx_store

; $99 / $9A: ch3 fade-out on/off. NR32: 50% on frame 3, 25% on 5, mute on 7, 25% on 10,
; mute on 13, then stop.
Cmd_Ch3FadeOutOn:
	ld a, $01
Cmd_Ch3FadeOut_store:
	ld [wCh3FadeOut], a
	call IncPtr
	jp Music_ReadCommand

Cmd_Ch3FadeOutOff:
	xor a
	ld [wCh3FadeIn], a
	ld [wCh3FadeInTimer], a
	jr Cmd_Ch3FadeOut_store

Music_Ch3FadeOut:
	cp $02
	jp z, Music_Effects_ret
	ld bc, wCh3FadeOutTimer
	call IncByteBC
	ld c, $1c
	ld b, $40
	cp $03
	jr z, Music_Ch3Fade_write
	ld b, $60
	cp $05
	jr z, Music_Ch3Fade_write
	cp $0a
	jr z, Music_Ch3Fade_write
	ld b, $00
	cp $07
	jr z, Music_Ch3Fade_write
	cp $0d
	jp nz, Music_Effects_ret
	ld a, $02
	ld [wCh3FadeOut], a
Music_Ch3Fade_write:
	ld a, b
	ldh [c], a
	jp Music_Effects_ret

IncByteBC:
	ld a, [bc]
	inc a
	ld [bc], a
	ret

; $94: ch3 fade-in: NR32 25% on frame 3, 50% on 5, 100% on 6, then stop.
Cmd_Ch3FadeInOn:
	ld a, $01
	ld [wCh3FadeIn], a
	call IncPtr
	jp Music_ReadCommand

Music_Ch3FadeIn:
	cp $02
	jp z, Music_Effects_ret
	ld bc, wCh3FadeInTimer
	call IncByteBC
	ld c, $1c
	ld b, $60
	cp $03
	jp z, Music_Ch3Fade_write
	ld b, $40
	cp $05
	jp z, Music_Ch3Fade_write
	ld b, $20
	cp $06
	jp nz, Music_Effects_ret
	ld a, $02
	ld [wCh3FadeIn], a
	jp Music_Ch3Fade_write

; $97 / $98: drop on/off: the period falls by 100 every frame.
Cmd_DropOn:
	ld de, wDrop
	call IndexByChannel
	ld a, $01
Cmd_Drop_store:
	ld [de], a
	call IncPtr
	jp Music_ReadCommand

Cmd_DropOff:
	ld de, wDrop
	call IndexByChannel
	xor a
	jr Cmd_Drop_store

Music_Drop:
	inc e
	ld a, [de]
	and a
	jr nz, .next
	inc a
	ld [de], a
	pop hl
	push hl
	call GetNoteFreq
.apply:
	ld hl, $ff9c
	add hl, de
	call WritePitch
	jp Music_Effects_ret

.next:
	call ReadPitch
	jr .apply

GetNoteFreq:
	ld a, $07
	add a, l
	ld l, a
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	and $0f
	ld d, a
	ret

WritePitch:
	ld de, wPitch
	call IndexByChannel
	ld a, l
	ldh [c], a
	ld [de], a
	inc c
	inc e
	ld a, h
	and $0f
	ldh [c], a
	ld [de], a
	ret

IndexByChannel:
	ld a, [wMusicChannel]
	dec a
	sla a
	add a, e
	ld e, a
	ret

ReadPitch:
	ld de, wPitch
	call IndexByChannel
	ld a, [de]
	ld l, a
	inc e
	ld a, [de]
	ld d, a
	ld e, l
	ret

Music_Vibrato:
	pop de
	ld de, wVibrato
	call IndexByChannel
	ld a, [de]
	inc a
	ld [de], a
	inc e
	cp $19
	jr z, .first
	cp $2d
	jr z, .wrap
	ld a, [de]
	and a
	jp z, Music_Effects.drop
.apply:
	dec e
	ld a, [de]
	sub $19
	sla a
	ld l, a
	ld h, $00
	ld de, VibratoTable
	add hl, de
	ld a, [hl+]
	ld d, a
	ld a, [hl]
	ld e, a
	pop hl
	push hl
	push de
	call GetNoteFreq
	ld h, d
	ld l, e
	pop de
	add hl, de
	call WritePitch
	jp Music_Effects.drop

.wrap:
	dec e
	ld a, $19
	ld [de], a
	inc e
	jr .apply

.first:
	ld a, $01
	ld [de], a
	jr .apply

; vibrato (effect 1): 20 big-endian period offsets, from frame 25 of a note, cycled
VibratoTable:
	db $00, $00, $00, $00, $00, $01, $00, $01
	db $00, $02, $00, $02, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fe
	db $00, $00, $00, $01, $00, $02, $00, $01
	db $00, $00, $ff, $ff, $ff, $fe, $ff, $ff
NoteTable:
	dw $0f00	; index 0: never played
	dw $002c	; C2
	dw $009c	; Cs2
	dw $0106	; D2
	dw $016b	; Ds2
	dw $01c9	; E2
	dw $0223	; F2
	dw $0277	; Fs2
	dw $02c6	; G2
	dw $0312	; Gs2
	dw $0356	; A2
	dw $039b	; As2
	dw $03da	; B2
	dw $0416	; C3
	dw $044e	; Cs3
	dw $0483	; D3
	dw $04b5	; Ds3
	dw $04e5	; E3
	dw $0511	; F3
	dw $053b	; Fs3
	dw $0563	; G3
	dw $0589	; Gs3
	dw $05ac	; A3
	dw $05ce	; As3
	dw $05ed	; B3
	dw $060a	; C4
	dw $0627	; Cs4
	dw $0642	; D4
	dw $065b	; Ds4
	dw $0672	; E4
	dw $0689	; F4
	dw $069e	; Fs4
	dw $06b2	; G4
	dw $06c4	; Gs4
	dw $06d6	; A4
	dw $06e7	; As4
	dw $06f7	; B4
	dw $0706	; C5
	dw $0714	; Cs5
	dw $0721	; D5
	dw $072d	; Ds5
	dw $0739	; E5
	dw $0744	; F5
	dw $074f	; Fs5
	dw $0759	; G5
	dw $0762	; Gs5
	dw $076b	; A5
	dw $0774	; As5
	dw $077b	; B5
	dw $0783	; C6
	dw $078a	; Cs6
	dw $0790	; D6
	dw $0797	; Ds6
	dw $079d	; E6
	dw $07a2	; F6
	dw $07a7	; Fs6
	dw $07ac	; G6
	dw $07b1	; Gs6
	dw $07b6	; A6
	dw $07ba	; As6
	dw $07be	; B6
	dw $07c1	; C7
	dw $07c5	; Cs7
	dw $07c8	; D7
	dw $07cb	; Ds7
	dw $07ce	; E7
	dw $07d1	; F7
	dw $07d4	; Fs7
	dw $07d6	; G7
	dw $07d9	; Gs7
	dw $07db	; A7
	dw $07dd	; As7
	dw $07df	; B7
NoiseTable:
	db $00	; offset 0
	db $00, $00, $00, $00, $c0	; NOISE_01: NR42, -, NR41, NR43, NR44
	db $09, $00, $38, $34, $c0	; NOISE_06: NR42, -, NR41, NR43, NR44
	db $19, $00, $38, $33, $c0	; NOISE_0B: NR42, -, NR41, NR43, NR44
	db $46, $00, $13, $10, $c0	; NOISE_10: NR42, -, NR41, NR43, NR44
	db $23, $00, $20, $40, $80	; NOISE_15: NR42, -, NR41, NR43, NR44
	db $51, $00, $20, $07, $80	; NOISE_1A: NR42, -, NR41, NR43, NR44
	db $a1, $00, $00, $18, $80	; NOISE_1F: NR42, -, NR41, NR43, NR44
	db $f2, $00, $00, $18, $80	; NOISE_24: NR42, -, NR41, NR43, NR44
	db $81, $00, $3a, $10, $c0	; NOISE_29: NR42, -, NR41, NR43, NR44
	db $80, $00, $00, $10, $c0	; NOISE_2E: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_33: NR42, -, NR41, NR43, NR44
	db $10, $00, $00, $10, $80	; NOISE_38: NR42, -, NR41, NR43, NR44
LengthTable_4A8E:
	db $01, $02, $04, $08, $10, $20, $06, $0c, $18, $01, $01, $01, $01, $01, $30
LengthTable_4A9D:
	db $01, $03, $06, $0c, $18, $30, $09, $12, $24, $02, $04, $08, $01, $01, $48
LengthTable_4AAC:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $02, $05, $03, $01, $01, $60
LengthTable_4ABB:
	db $03, $05, $0a, $14, $28, $50, $0f, $1e, $3c, $02, $08, $10, $02, $01, $78
LengthTable_4ACA:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $08, $10, $02, $04, $90
LengthTable_4AD9:
	db $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $09, $12, $02, $01, $a8
LengthTable_4AE8:
	db $04, $08, $10, $20, $40, $80, $18, $30, $60, $04, $02, $01, $01, $00, $c0
LengthTable_4AF7:
	db $04, $09, $12, $24, $48, $90, $1b, $36, $6c, $05, $0c, $18, $18, $06, $d8
LengthTable_4B06:
	db $05, $0a, $14, $28, $50, $a0, $1e, $3c, $78, $05, $01, $01, $01, $01, $f0
; NRx2 at the release point, index = low nibble of InstrRelease
ReleaseEnvelopes:
	db $10, $32, $22, $47, $60, $20, $00
