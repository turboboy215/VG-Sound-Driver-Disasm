; Kirby Tilt 'n' Tumble music: music driver and tables, bank $0E $4000-$4FFF

; Entry points (same order as the SFX banks): init, stop, update.
	jp Music_Init

	jp Sound_Stop

	jp Music_Update

; Clear $DE00-$DEFF and switch the APU on. (The game only calls the init of SFX bank $11.)
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

; Called once per frame, before the other music bank and the two SFX banks. Any pending
; request calls the empty hook at $4FFF. NR31 is cleared every frame.
Music_Update:
	ld a, [wSfx1Request]
	ld hl, wSongRequest
	or [hl]
	ld hl, wSfx2Request
	or [hl]
	ld hl, wSfx4Request
	or [hl]
	call nz, Music_RequestHook
	ld hl, wSongRequest
	ld a, [hl]
	and a
	jr nz, .request
.play:
	xor a
	ldh [rNR31], a
	call Music_Play
	ret

.request:
	call Music_StartSong
	jr .play

; 127 entries ($01-$7F) in both music banks; each bank only accepts its own half.
SongTable:
	dw Song01_Header	; $01 = song $01
	dw Song02_Header	; $02 = song $02
	dw Song03_Header	; $03 = song $03
	dw Song04_Header	; $04 = song $04
	dw Song05_Header	; $05 = song $05
	dw Song06_Header	; $06 = song $06
	dw Song07_Header	; $07 = song $07
	dw Song08_Header	; $08 = song $08
	dw Song09_Header	; $09 = song $09
	dw Song0A_Header	; $0a = song $0a
	dw Song0B_Header	; $0b = song $0b
	dw Song0C_Header	; $0c = song $0c
	dw Song0D_Header	; $0d = song $0d
	dw Song0E_Header	; $0e = song $0e
	dw Song0F_Header	; $0f = song $0f
	dw Song10_Header	; $10 = song $10
	dw Song11_Header	; $11 = song $11
	dw Song12_Header	; $12 = song $12
	dw Song01_Header	; $13 = song $13
	dw Song08_Header	; $14 = song $14
	dw Song08_Header	; $15 = song $15
	dw Song08_Header	; $16 = song $16
	dw Song08_Header	; $17 = song $17
	dw Song08_Header	; $18 = song $18
	dw Song08_Header	; $19 = song $19
	dw Song08_Header	; $1a = song $1a
	dw Song08_Header	; $1b = song $1b
	dw Song08_Header	; $1c = song $1c
	dw Song08_Header	; $1d = song $1d
	dw Song08_Header	; $1e = song $1e
	dw Song08_Header	; $1f = song $1f
	dw Song08_Header	; $20 = song $20
	dw Song08_Header	; $21 = song $21
	dw Song08_Header	; $22 = song $22
	dw Song08_Header	; $23 = song $23
	dw Song08_Header	; $24 = song $24
	dw Song08_Header	; $25 = song $25
	dw Song08_Header	; $26 = song $26
	dw Song08_Header	; $27 = song $27
	dw Song08_Header	; $28 = song $28
	dw Song08_Header	; $29 = song $29
	dw Song08_Header	; $2a = song $2a
	dw Song08_Header	; $2b = song $2b
	dw Song08_Header	; $2c = song $2c
	dw Song08_Header	; $2d = song $2d
	dw Song08_Header	; $2e = song $2e
	dw Song08_Header	; $2f = song $2f
	dw Song08_Header	; $30 = song $30
	dw Song08_Header	; $31 = song $31
	dw Song08_Header	; $32 = song $32
	dw Song08_Header	; $33 = song $33
	dw Song08_Header	; $34 = song $34
	dw Song08_Header	; $35 = song $35
	dw Song08_Header	; $36 = song $36
	dw Song08_Header	; $37 = song $37
	dw Song08_Header	; $38 = song $38
	dw Song08_Header	; $39 = song $39
	dw Song08_Header	; $3a = song $3a
	dw Song08_Header	; $3b = song $3b
	dw Song08_Header	; $3c = song $3c
	dw Song08_Header	; $3d = song $3d
	dw Song08_Header	; $3e = song $3e
	dw Song08_Header	; $3f = song $3f
	dw Song08_Header	; $40: not reachable
	dw Song08_Header	; $41: not reachable
	dw Song08_Header	; $42: not reachable
	dw Song08_Header	; $43: not reachable
	dw Song08_Header	; $44: not reachable
	dw Song08_Header	; $45: not reachable
	dw Song08_Header	; $46: not reachable
	dw Song08_Header	; $47: not reachable
	dw Song08_Header	; $48: not reachable
	dw Song08_Header	; $49: not reachable
	dw Song08_Header	; $4a: not reachable
	dw Song08_Header	; $4b: not reachable
	dw Song08_Header	; $4c: not reachable
	dw Song08_Header	; $4d: not reachable
	dw Song08_Header	; $4e: not reachable
	dw Song08_Header	; $4f: not reachable
	dw Song08_Header	; $50: not reachable
	dw Song08_Header	; $51: not reachable
	dw Song08_Header	; $52: not reachable
	dw Song08_Header	; $53: not reachable
	dw Song08_Header	; $54: not reachable
	dw Song08_Header	; $55: not reachable
	dw Song08_Header	; $56: not reachable
	dw Song08_Header	; $57: not reachable
	dw Song08_Header	; $58: not reachable
	dw Song08_Header	; $59: not reachable
	dw Song08_Header	; $5a: not reachable
	dw Song08_Header	; $5b: not reachable
	dw Song08_Header	; $5c: not reachable
	dw Song08_Header	; $5d: not reachable
	dw Song08_Header	; $5e: not reachable
	dw Song08_Header	; $5f: not reachable
	dw Song08_Header	; $60: not reachable
	dw Song08_Header	; $61: not reachable
	dw Song08_Header	; $62: not reachable
	dw Song08_Header	; $63: not reachable
	dw Song08_Header	; $64: not reachable
	dw Song08_Header	; $65: not reachable
	dw Song08_Header	; $66: not reachable
	dw Song08_Header	; $67: not reachable
	dw Song08_Header	; $68: not reachable
	dw Song08_Header	; $69: not reachable
	dw Song08_Header	; $6a: not reachable
	dw Song08_Header	; $6b: not reachable
	dw Song08_Header	; $6c: not reachable
	dw Song08_Header	; $6d: not reachable
	dw Song08_Header	; $6e: not reachable
	dw Song08_Header	; $6f: not reachable
	dw Song08_Header	; $70: not reachable
	dw Song08_Header	; $71: not reachable
	dw Song08_Header	; $72: not reachable
	dw Song08_Header	; $73: not reachable
	dw Song08_Header	; $74: not reachable
	dw Song08_Header	; $75: not reachable
	dw Song08_Header	; $76: not reachable
	dw Song08_Header	; $77: not reachable
	dw Song08_Header	; $78: not reachable
	dw Song08_Header	; $79: not reachable
	dw Song08_Header	; $7a: not reachable
	dw Song08_Header	; $7b: not reachable
	dw Song08_Header	; $7c: not reachable
	dw Song08_Header	; $7d: not reachable
	dw Song08_Header	; $7e: not reachable
	dw Song08_Header	; $7f: not reachable
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

; unreferenced: cancel the ch4 effect
Unused_StopSfx4:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [wSfx4Priority], a
	ld [wSfx4Var], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; Request $FF: remember the song for request $80, then stop.
Music_Stop:
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
	ld a, $ff
	ld [wCurrentSong], a
	jp Sound_Stop

; Request $80 replays wPreviousSong. This bank takes songs $01-$3F (bank $0F: $40-$7F) and
; claims the music (wMusicBank = 0; bank $0F writes 1). A new song moves wCurrentSong to
; wPreviousSong.
Music_StartSong:
	cp $80
	jr nz, .notReplay
	ld a, [wPreviousSong]
.notReplay:
	cp $ff
	jr z, Music_Stop
	cp $01
	ret c
	cp $40
	ret nc
	ld b, a
	ld hl, wSongPlaying
	ld a, [hl]
	cp b
	jr z, .store
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
.store:
	ld a, b
	ld [hl], a
	ld [wCurrentSong], a
	ld a, $00
	ld [wMusicBank], a
	xor a
	ld [wChannelsPlayed], a
	ld [wSongRequest], a
	ld a, b
	ld hl, SongTable
	and $7f
	call GetPointer
	call Music_LoadHeader
	jp Music_InitPanning

; Panning: mode (1 = fixed), period, NR51 x4. 64 entries as in SMB DX, but Music_InitPanning
; now always reads the first one.
SongPanTable:
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
	ldh [rNR34], a
	pop bc
	pop hl
	jp Music_Trigger.write

Music_InitPanning:
	ld a, [wSongPlaying]
	ld hl, SongPanTable
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

; Reset the per-channel transposes and the drum kit, then load the 11-byte song header.
Music_LoadHeader:
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
	ld a, e
	ld [wCh3WavePtr], a
	ld a, d
	ld [wCh3WavePtr+1], a
	ld a, [wCh3Flags]
	bit 7, a
	jr nz, .done
	ldh a, [rNR30]
	bit 7, a
	jr z, .load
	xor a
	ldh [rNR30], a
.load:
	xor a
	ld l, e
	ld h, d
	call LoadWave
.done:
	pop hl
	jr Music_NextByte

; $9D: three bytes to Env/Release/Duty. Release non-zero: Env/Release are a pointer to a
; per-frame envelope table. ch3: wave pointer + level.
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

; ch3: the level counts up from 1 and mutes ch3 (NR32 = 0) when it reaches 3; then LA's
; 50% drop 6 frames before the end of a note.
Music_Sustain:
	ld a, [wMusicChannel]
	cp $03
	jr nz, .effects
	ld a, [wCh3Rest]
	and a
	jr z, .ch3Level
	cp $03
	jr z, .ch3Level
	inc a
	ld [wCh3Rest], a
	ld a, [wCh3Flags]
	bit 7, a
	jr nz, .ch3Level
	ld a, [wCh3Rest]
	cp $03
	jr nz, .ch3Level
	xor a
	ldh [rNR32], a
.ch3Level:
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
	call Music_Envelope
	pop hl
Music_ChannelDone:
	dec l
	dec l
	jp Music_NextChannel

; $00: next list entry. $0000 ends the song (no restart); $FFFF + address loops;
; $FF96 / $FF95 / $FF94 / $FF93 + a word: per-channel transpose set / add or envelope set /
; add (low byte of the word), then the next entry. Any other $FFxx ends the song.
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
	jr z, Music_SongEnd
	cp $ff
	jr z, .listCommand
	inc l
	jp Music_ReadPattern

.listCommand:
	dec bc
	ld a, [bc]
	cp $ff
	jr z, Cmd_PatternEnd_loop
	cp $96
	jr z, .transposeSet
	cp $95
	jr z, .transposeAdd
	cp $94
	jr z, .envSet
	cp $93
	jr z, .envAdd
	jr Music_SongEnd

.transposeAdd:
	ld c, $ff
	jr .transpose

.transposeSet:
	ld c, $00
.transpose:
	call ReadListOperand
	ld b, e
	call SetChannelTranspose
	jp .loadPattern

.envAdd:
	ld c, $ff
	jr .env

.envSet:
	ld c, $00
.env:
	call ReadListOperand
	push hl
	ld b, e
	ld a, $04
	add a, l
	ld l, a
	call SetChannelEnv
	pop hl
	jp .loadPattern

; Skip the command word and read the operand word of a list command into de.
ReadListOperand:
	push bc
	dec l
	call IncPtr2
	call ReadPtrByte
	ld e, a
	call IncPtr
	call ReadPtrByte
	ld d, a
	call IncPtr
	pop bc
	ret

Cmd_PatternEnd_loop:
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
	jr Cmd_PatternEnd.loadPattern

; The song is over: clear wSongPlaying, remember it for request $80 and stop.
Music_SongEnd:
	ld hl, wSongPlaying
	ld [hl], $00
	call Music_Stop
	ret

; $9E: select a length table (back from LA; SMB DX had removed it).
Cmd_Tempo:
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable], a
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable+1], a
	jr Music_SkipAndContinue

; unreferenced: tail of LA's $9F (transpose) command
Unused_CmdTranspose:
	call IncPtr
	call ReadPtrByte
	ld [wTranspose], a
Music_SkipAndContinue:
	call IncPtr
	jp Music_ReadCommand

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
	jp Music_ReadCommand

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
	jp Music_ReadCommand

.done:
	pop hl
	jr Music_SkipAndContinue

; $9A: master volume, NR50 = value & $77.
Cmd_Volume:
	call IncPtr
	call ReadPtrByte
	and $77
	ldh [rNR50], a
	call IncPtr
	jp Music_ReadCommand

; $99: NRx2 written for rests on ch1 (wCh1RestEnv) or ch2 (wCh2RestEnv), once the channel
; has played a note. Both default to $11 when a song starts.
Cmd_RestEnv:
	call IncPtr
	call ReadPtrByte
	ld b, a
	ld a, [wMusicChannel]
	cp $01
	jr z, .ch1
	cp $02
	jr z, .ch2
.next:
	call IncPtr
	jp Music_ReadCommand

.ch1:
	ld a, b
	ld [wCh1RestEnv], a
	jr .next

.ch2:
	ld a, b
	ld [wCh2RestEnv], a
	jr .next

; $95 / $96: add to / set this channel's transpose (wChTranspose + channel; ch1-ch3 only,
; in bytes: 2 per semitone). It is added to the header transpose in Music_Note.
Cmd_TransposeAdd:
	ld c, $ff
	jr Cmd_TransposeSet.apply

Cmd_TransposeSet:
	ld c, $00
.apply:
	push bc
	call IncPtr
	call ReadPtrByte
	pop bc
	ld b, a
	call SetChannelTranspose
	call IncPtr
	jp Music_ReadCommand

SetChannelTranspose:
	ld a, [wMusicChannel]
	and $03
	ret z
	ld de, wChTranspose
	add a, e
	ld e, a
	ld a, [de]
	and c
	add a, b
	ld [de], a
	ret

; $93 / $94: add to / set the instrument's NRx2 byte (ch1/ch2, and only when it isn't an
; envelope table pointer). The add is signed; an add that would wrap past $00 or $FF is ignored.
Cmd_EnvAdd:
	ld c, $ff
	jr Cmd_EnvSet.apply

Cmd_EnvSet:
	ld c, $00
.apply:
	push bc
	call IncPtr
	call ReadPtrByte
	pop bc
	ld b, a
	call SetChannelEnv
	call IncPtr
	jr Music_ReadCommand

SetChannelEnv:
	inc l
	inc l
	ld a, [wMusicChannel]
	cp $03
	jr nc, .done
	inc l
	ld a, [hl-]
	and a
	jr nz, .done
	ld a, [hl]
	and c
	add a, b
	bit 7, c
	jr z, .store
	bit 7, b
	jr nz, .negative
	jr nc, .store
	jr .done

.negative:
	jr nc, .done
.store:
	ld [hl], a
.done:
	dec l
	dec l
	ret

; $92: drum kit pointer for ch4 notes (default NoiseTable).
Cmd_DrumKit:
	call IncPtr
	call ReadPtrByte
	ld [wDrumKit], a
	call IncPtr
	call ReadPtrByte
	ld [wDrumKit+1], a
	call IncPtr
	jr Music_ReadCommand

; Nothing plays unless this bank owns the music (wMusicBank).
Music_Play:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, [wMusicBank]
	cp $00
	ret nz
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
; Commands $92-$9E, lengths $A0-$AF.
Music_ReadCommand:
	call ReadPtrByte
	cp $00
	jp z, Cmd_PatternEnd
	and $f0
	cp $90
	jr nz, Music_Length
	ld a, b
	cp $9d
	jp z, Cmd_Instrument
	cp $9e
	jp z, Cmd_Tempo
	cp $9b
	jp z, Cmd_RepeatStart
	cp $9c
	jp z, Cmd_RepeatEnd
	cp $97
	jp z, Cmd_DropOn
	cp $98
	jp z, Cmd_DropOff
	cp $9a
	jp z, Cmd_Volume
	cp $99
	jp z, Cmd_RestEnv
	cp $96
	jp z, Cmd_TransposeSet
	cp $95
	jp z, Cmd_TransposeAdd
	cp $94
	jp z, Cmd_EnvSet
	cp $93
	jp z, Cmd_EnvAdd
	cp $92
	jp z, Cmd_DrumKit
; In hurry mode (wHurryMode, set by the game) eight songs read their lengths from a table
; stored just before their header; the others keep the current table.
Music_Length:
	and $f0
	cp $a0
	jp nz, Music_Note
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
	ld a, [wHurryMode]
	and a
	jr z, .lookup
	ld a, [wCurrentSong]
	cp $08
	jr z, .hurry08
	cp $09
	jr z, .hurry09
	cp $0d
	jr z, .hurry0D
	cp $0c
	jr z, .hurry0C
	cp $06
	jr z, .hurry06
	cp $0b
	jr z, .hurry0B
	cp $0a
	jr z, .hurry0A
	cp $02
	jr z, .hurry02
	jr .lookup

.hurry08:
	ld hl, Song08_HurryLengths
	jr .lookup

.hurry09:
	ld hl, Song09_HurryLengths
	jr .lookup

.hurry0A:
	ld hl, Song0A_HurryLengths
	jr .lookup

.hurry0B:
	ld hl, Song0B_HurryLengths
	jr .lookup

.hurry0C:
	ld hl, Song0C_HurryLengths
	jr .lookup

.hurry0D:
	ld hl, Song0D_HurryLengths
	jr .lookup

.hurry06:
	ld hl, Song06_HurryLengths
	jr .lookup

.hurry02:
	ld hl, Song02_HurryLengths
.lookup:
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
	jr nz, .release
	ld a, d
	jr .done

.release:
	ld e, a
	ld a, d
	push af
	srl a
	sla e
	jr c, .store
	ld d, a
	srl a
	sla e
	jr c, .store
	add a, d
.store:
	ld c, a
	and a
	jr nz, .storeRelease
	ld c, $02
.storeRelease:
	ld de, wMusicChannel
	ld a, [de]
	dec a
	ld e, a
	ld d, $00
	ld hl, wReleaseFrame
	add hl, de
	ld [hl], c
	pop af
.done:
	pop hl
	dec l
	ld [hl+], a
	call IncPtr
	call ReadPtrByte
; Note: restart the vibrato / drop state of the channel and the ch3 fades, then add the
; header transpose and the channel transpose.
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
	jp z, Music_DrumNote
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
	ld a, [wMusicChannel]
	ld hl, wChTranspose
	add a, l
	ld l, a
	ld a, [wTranspose]
	add a, [hl]
	sla a
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
	ld a, [hl]
	and a
	jr nz, .restDone
	ld [hl], $01
.restDone:
	pop hl
	jr Music_Trigger

; ch4: copy 5 bytes (NR42, -, NR41, NR43, NR44) from drum kit + note byte. No music drum.
Music_DrumNote:
	push hl
	ld de, wCh4InstrEnv
	ld hl, wDrumKit
	ld a, [hl+]
	ld h, [hl]
	ld l, a
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
	ldh a, [c]
	bit 7, a
	jr z, .ch3On
	ldh a, [rNR52]
	bit 3, a
	jr z, .ch3Off
	jr .ch3

.ch3Off:
	xor a
	ldh [c], a
.ch3On:
	ld a, $80
	ldh [c], a
	ldh [rNR34], a
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
	ld a, [hl]
	and a
	jr z, .duty
	push hl
	ld a, [hl-]
	ld l, [hl]
	ld h, a
	ld e, [hl]
	pop hl
.duty:
	inc l
	ld a, [hl+]
	ld d, a
; Rest: the first rest of a run writes the rest envelope (ch1/ch2) or level $40 (ch3);
; later rests write nothing.
.checkRest:
	push hl
	inc l
	inc l
	ld a, [hl+]
	and a
	jr z, .notRest
	cp $01
	jr nz, .silent
	dec hl
	ld [hl], $02
	inc hl
	ld a, [wMusicChannel]
	cp $03
	jr z, .restCh3
	cp $02
	jr z, .restCh2
	ld a, [wChannelsPlayed]
	bit 0, a
	jr z, .silent
	ld a, [wCh1RestEnv]
	jr .restEnv

.restCh2:
	ld a, [wChannelsPlayed]
	bit 1, a
	jr z, .silent
	ld a, [wCh2RestEnv]
.restEnv:
	and a
	jr z, .silent
	ld e, a
	jr .notRest

.silent:
	pop hl
	jr .done

.restCh3:
	ld e, $40
	jr .notRest

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
	ld a, [wMusicChannel]
	cp $01
	jr z, .playedCh1
	cp $02
	jr z, .playedCh2
	cp $03
	jr nz, .nrx4
	inc c
	ld a, [hl]
	jr .writeNRx4

.playedCh2:
	ld a, [wChannelsPlayed]
	set 1, a
	ld [wChannelsPlayed], a
	jr .nrx4

.playedCh1:
	ld a, [wChannelsPlayed]
	set 0, a
	ld [wChannelsPlayed], a
.nrx4:
	inc c
	ld a, [hl]
	or $80
.writeNRx4:
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

; Pitch effect from the low nibble of Duty: 1 = vibrato after 24 frames, 2 = vibrato from
; frame 17, other non-zero = period - 1 per frame. Then drop and the ch3 fades.
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
	cp $02
	jp z, Music_Vibrato2
	ld hl, $ffff
	pop de
	add hl, de
	call WritePitch
	jp .drop

; Envelope tables: for the first 48 frames of a note, a non-zero byte of the table is
; written to NRx2 and the note retriggered (ch1/ch2).
Music_Envelope:
	ld a, [wCh1Rest]
	and a
	jr nz, .ch2
	ld a, [wCh1InstrRelease]
	and a
	jr z, .ch2
	ld a, [wChannelsPlayed]
	bit 0, a
	jr z, .ch2
	ld a, [wCh1Flags]
	bit 7, a
	jr nz, .ch2
	ld a, [wCh1InstrEnv]
	ld l, a
	ld a, [wCh1InstrRelease]
	ld h, a
	ld a, [wCh1NoteFrames]
	and a
	jr z, .ch2
	cp $30
	jr nc, .ch2
	ld e, a
	ld d, $00
	add hl, de
	ld a, [hl]
	and a
	jr z, .ch2
	ldh [rNR12], a
	ld a, [wCh1Freq]
	ldh [rNR13], a
	ld a, [wCh1Freq+1]
	or $80
	ldh [rNR14], a
	jr .ch2

.ch2:
	ld a, [wCh2Rest]
	and a
	ret nz
	ld a, [wCh2InstrRelease]
	and a
	ret z
	ld a, [wChannelsPlayed]
	bit 1, a
	ret z
	ld a, [wCh2Flags]
	bit 7, a
	ret nz
	ld a, [wCh2InstrEnv]
	ld l, a
	ld a, [wCh2InstrRelease]
	ld h, a
	ld a, [wCh2NoteFrames]
	and a
	ret z
	cp $30
	ret nc
	ld e, a
	ld d, $00
	add hl, de
	ld a, [hl]
	and a
	ret z
	ldh [rNR22], a
	ld a, [wCh2Freq]
	ldh [rNR23], a
	ld a, [wCh2Freq+1]
	or $80
	ldh [rNR24], a
	ret

; unreferenced: LA's $96 / $95 / $99 / $9A commands
Unused_CmdCh3SfxPause:
	ld a, $01
.store:
	ld [wCh3SfxPaused], a
	call IncPtr
	jp Music_ReadCommand

Unused_CmdCh3SfxResume:
	xor a
	jr Unused_CmdCh3SfxPause.store

Unused_CmdCh3FadeOutOn:
	ld a, $01
.store:
	ld [wCh3FadeOut], a
	call IncPtr
	jp Music_ReadCommand

Unused_CmdCh3FadeOutOff:
	xor a
	ld [wCh3FadeOut], a
	jr Unused_CmdCh3FadeOutOn.store

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

; Drop: the period falls by 32 every frame.
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
	ld hl, $ffe0
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

Music_Vibrato2:
	pop de
	ld de, wVibrato
	call IndexByChannel
	ld a, [de]
	and a
	jr nz, .count
	ld a, $10
.count:
	inc a
	ld [de], a
	inc e
	jr Music_Vibrato.check

Music_Vibrato:
	pop de
	ld de, wVibrato
	call IndexByChannel
	ld a, [de]
	inc a
	ld [de], a
	inc e
.check:
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

; vibrato: 20 big-endian period offsets, cycled
VibratoTable:
	db $00, $00, $00, $00, $00, $01, $00, $01
	db $00, $02, $00, $02, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fe
	db $00, $00, $00, $01, $00, $02, $00, $01
	db $00, $00, $ff, $ff, $ff, $fe, $ff, $ff
; unreferenced: LA's $94 command
Unused_CmdCh3FadeInOn:
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
; default drum kit: offset 0 unused, then 5 bytes per drum (NR42, -, NR41, NR43, NR44)
NoiseTable:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; NOISE_01: NR42, -, NR41, NR43, NR44
	db $82, $00, $40, $02, $c0	; NOISE_06: NR42, -, NR41, NR43, NR44
	db $58, $00, $2b, $05, $c0	; NOISE_0B: NR42, -, NR41, NR43, NR44
	db $86, $00, $13, $10, $c0	; NOISE_10: NR42, -, NR41, NR43, NR44
	db $43, $00, $20, $40, $80	; NOISE_15: NR42, -, NR41, NR43, NR44
	db $56, $00, $2b, $05, $c0	; NOISE_1A: NR42, -, NR41, NR43, NR44
	db $91, $00, $39, $05, $c0	; NOISE_1F: NR42, -, NR41, NR43, NR44
	db $f2, $00, $00, $18, $80	; NOISE_24: NR42, -, NR41, NR43, NR44
	db $61, $00, $3a, $05, $c0	; NOISE_29: NR42, -, NR41, NR43, NR44
	db $81, $00, $3a, $37, $c0	; NOISE_2E: NR42, -, NR41, NR43, NR44
	db $28, $00, $2b, $05, $c0	; NOISE_33: NR42, -, NR41, NR43, NR44
	db $43, $00, $20, $40, $80	; NOISE_38: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $20, $80	; NOISE_3D: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $30, $80	; NOISE_42: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $07, $80	; NOISE_47: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $23, $80	; NOISE_4C: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $50, $80	; NOISE_51: NR42, -, NR41, NR43, NR44
	db $81, $00, $00, $33, $80	; NOISE_56: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_5B: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_60: NR42, -, NR41, NR43, NR44
	db $94, $00, $00, $70, $80	; NOISE_65: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_6A: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_6F: NR42, -, NR41, NR43, NR44
	db $a1, $00, $00, $20, $80	; NOISE_74: NR42, -, NR41, NR43, NR44
	db $51, $00, $00, $07, $80	; NOISE_79: NR42, -, NR41, NR43, NR44
LengthTable_4CD7:
	db $02, $04, $08, $10, $20, $40, $01, $18, $30, $02, $06, $0e, $1e, $16, $0c
LengthTable_4CE6:
	db $01, $03, $06, $0c, $18, $30, $09, $12, $24, $02, $04, $08, $01, $01, $08
LengthTable_4CF5:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $02, $05, $03, $01, $01, $60
LengthTable_4D04:
	db $03, $05, $0a, $14, $28, $50, $0f, $1e, $3c, $02, $08, $0d, $0e, $01, $78
LengthTable_4D13:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $08, $10, $02, $04, $90
LengthTable_4D22:
	db $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $09, $12, $02, $01, $a8
LengthTable_4D31:
	db $04, $08, $10, $20, $40, $80, $18, $30, $60, $04, $02, $01, $01, $00, $c0
LengthTable_4D40:
	db $02, $04, $09, $12, $24, $48, $0c, $1b, $36, $02, $06, $0c, $01, $01, $6c
LengthTable_4D4F:
	db $04, $08, $0b, $16, $2c, $50, $0f, $21, $3c, $02, $09, $10, $02, $01, $78
LengthTable_4D5E:
	db $01, $02, $03, $06, $10, $20, $05, $09, $18, $01, $02, $04, $02, $02, $02
LengthTable_4D6D:
	db $02, $6f, $12, $6f, $6f, $6f, $6f, $6f, $6f, $6f, $06, $6f, $0c, $6f, $6f
	db $10, $32, $22, $47, $81, $20, $00
Song0E_Ch3:
	dw Pattern_4D89
	LIST_LOOP Song0E_Ch3
Pattern_4D89:
	REPEAT $20
	db L1D, REST
	REPEAT_END
	db PAT_END
; Stop: release the channels, fixed panning, clear the song, mute the channels no SFX is
; using.
Sound_Stop:
	call Music_ReleaseChannels
	ld a, $ff
	ldh [rNR51], a
	ld a, $01
	ld [wPanMode], a
	xor a
	ld [wSongRequest], a
	ld [wSongPlaying], a
	call Music_MuteChannels
	ret

Music_MuteChannels:
	ld a, [wSfx1Playing]
	and a
	jr nz, .ch2
	ld a, $08
	ldh [rNR12], a
	ldh [rNR10], a
	ld a, $80
	ldh [rNR14], a
.ch2:
	ld a, [wSfx2Playing]
	and a
	jr nz, .ch3
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
.ch3:
	ld a, [wSfx3Playing]
	and a
	jr nz, .ch4
	xor a
	ldh [rNR32], a
	ld a, $80
	ldh [rNR34], a
.ch4:
	ld a, [wSfx4Playing]
	and a
	jr nz, .done
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
.done:
	ret

Music_ReleaseChannels:
	ld a, [wCh1Flags]
	and $80
	ld [wCh1Flags], a
	ld a, [wCh2Flags]
	and $80
	ld [wCh2Flags], a
	ld a, [wCh3Flags]
	and $80
	ld [wCh3Flags], a
	ld a, [wCh4Flags]
	and $80
	ld [wCh4Flags], a
	ret

Music_ClearState:
	call Music_ReleaseChannels
	xor a
	push hl
	ld hl, wChTranspose+1
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld a, $59
	ld [hl+], a
	ld a, $4c
	ld [hl+], a
	xor a
	pop hl
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
	ld [wCh3SfxPaused], a
	ld [wReloadWave], a
	ld a, $11
	ld [wCh1RestEnv], a
	ld [wCh2RestEnv], a
	ld a, $77
	ldh [rNR50], a
	call Music_MuteChannels
	ret

	ds 439, 0	; $4E48-$4FFE unused
; Called whenever any request is pending: empty.
Music_RequestHook:
	ret

