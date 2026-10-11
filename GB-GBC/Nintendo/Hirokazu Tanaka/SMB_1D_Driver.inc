; Super Mario Bros. Deluxe music: music driver and tables, bank $1D $4000-$4D95

; Entry points (same order as LA): init, stop, update.
	jp Music_Init

	jp Sound_Stop

	jp Music_Update

; Clear $DE00-$DEFF and switch the APU on.
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

; Called once per frame, before the SFX bank. Any pending request calls the empty hook at
; $4FFF. Ch1 effect $6E during song $37 stops the music unless the previous song was $7D.
; Every frame NR31 is cleared.
Music_Update:
	ld a, [wSfx1Request]
	ld hl, wSongRequest
	or [hl]
	ld hl, wSfx2Request
	or [hl]
	ld hl, wSfx4Request
	or [hl]
	call nz, Music_RequestHook
	ld a, [wSfx1Request]
	cp $6e
	jr nz, .checkRequest
	ld a, [wSongPlaying]
	cp $37
	jr nz, .checkRequest
	ld a, [wPreviousSong]
	cp $7d
	jr z, .storeRequest
	ld a, $ff
.storeRequest:
	ld [wSongRequest], a
.checkRequest:
	ld hl, wSongRequest
	ld a, [hl]
	and a
	jr nz, Music_Update_start
.play:
	xor a
	ldh [rNR31], a
	call Music_Play
	ret

; unreferenced: LA's "song not in this bank" exit
Unused_4058:
	xor a
	ld [wMusicActive], a
	ret

Music_Update_start:
	call Music_StartSong
	jr Music_Update.play

; Pattern byte $FF on ch4 plays this two-step noise drum (wSfx4Request = 1) unless an SFX
; owns ch4. Unchanged from LA.
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

SongTable:
	dw Song62_Header	; $01: not reachable
	dw Song62_Header	; $02: not reachable
	dw Song62_Header	; $03: not reachable
	dw Song62_Header	; $04: not reachable
	dw Song62_Header	; $05: not reachable
	dw Song62_Header	; $06: not reachable
	dw Song62_Header	; $07: not reachable
	dw Song62_Header	; $08: not reachable
	dw Song62_Header	; $09: not reachable
	dw Song62_Header	; $0a: not reachable
	dw Song62_Header	; $0b: not reachable
	dw Song62_Header	; $0c: not reachable
	dw Song62_Header	; $0d: not reachable
	dw Song62_Header	; $0e: not reachable
	dw Song62_Header	; $0f: not reachable
	dw Song62_Header	; $10: not reachable
	dw Song62_Header	; $11: not reachable
	dw Song62_Header	; $12: not reachable
	dw Song62_Header	; $13: not reachable
	dw Song62_Header	; $14: not reachable
	dw Song62_Header	; $15: not reachable
	dw Song62_Header	; $16: not reachable
	dw Song62_Header	; $17: not reachable
	dw Song62_Header	; $18: not reachable
	dw Song62_Header	; $19: not reachable
	dw Song62_Header	; $1a: not reachable
	dw Song62_Header	; $1b: not reachable
	dw Song62_Header	; $1c: not reachable
	dw Song62_Header	; $1d: not reachable
	dw Song62_Header	; $1e: not reachable
	dw Song62_Header	; $1f: not reachable
	dw Song62_Header	; $20: not reachable
	dw Song62_Header	; $21: not reachable
	dw Song62_Header	; $22 = song $62
	dw Song63_Header	; $23 = song $63
	dw Song64_Header	; $24 = song $64
	dw Song65_Header	; $25 = song $65
	dw Song66_Header	; $26 = song $66
	dw Song67_Header	; $27 = song $67
	dw Song68_Header	; $28 = song $68
	dw Song69_Header	; $29 = song $69
	dw Song6A_Header	; $2a = song $6a
	dw Song6B_Header	; $2b = song $6b
	dw Song6C_Header	; $2c = song $6c
	dw Song6D_Header	; $2d = song $6d
	dw Song6E_Header	; $2e = song $6e
	dw Song6F_Header	; $2f = song $6f
	dw Song70_Header	; $30 = song $70
	dw Song71_Header	; $31 = song $71
	dw Song72_Header	; $32 = song $72
	dw Song73_Header	; $33 = song $73
	dw Song74_Header	; $34 = song $74
	dw Song75_Header	; $35 = song $75
	dw Song76_Header	; $36 = song $76
	dw Song77_Header	; $37 = song $77
	dw Song78_Header	; $38 = song $78
	dw Song79_Header	; $39 = song $79
	dw Song7A_Header	; $3a = song $7a
	dw Song7B_Header	; $3b = song $7b
	dw Song7C_Header	; $3c = song $7c
	dw Song7D_Header	; $3d = song $7d
	dw Song7E_Header	; $3e = song $7e
	dw Song7F_Header	; $3f = song $7f
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

StopSfx4:
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

; Song request $FF. Stopping song $2D pauses it instead (wPausedSong); song $6D later
; restores it.
Music_Stop:
	ld a, [wSongPlaying]
	and a
	ret z
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
	ld a, $ff
	ld [wCurrentSong], a
	ld a, [wSongPlaying]
	cp $2d
	jr z, .pause
	jp Sound_Stop

.pause:
	ld [wPausedSong], a
	xor a
	ld [wSongPlaying], a
	ld [wChannelsPlayed], a
	ldh [rNR32], a
	ld a, $11
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR24], a
	ldh [rNR44], a
	ret

Music_RestorePausedSong:
	ld a, [wPausedSong]
	ld [wSongPlaying], a
	ret

; Songs $62-$7F (table entries $22-$3F). The song already playing is not restarted, except
; $63, $65 and $68.
Music_StartSong:
	cp $ff
	jr z, Music_Stop
	jr Music_StartSong_checkRange

; unreferenced: LA's bank range checks
Unused_4198:
	cp $11
	jr nc, .not1x
	jp Music_StartSong_load

.not1x:
	cp $21
	jr nc, .not2x
	jp Unused_4058

.not2x:
	cp $31
	jr nc, .not3x
	jp Unused_4058

.not3x:
	cp $41
	jp nc, Music_StartSong_checkRange
	add a, $e0
	jp Music_StartSong_load

Music_StartSong_checkRange:
	cp $62
	jp c, Music_StartSong_refuse
	cp $80
	jp c, Music_StartSong_inRange
Music_StartSong_refuse:
	xor a
	ld [wSongRequest], a
	ret

Music_StartSong_inRange:
	ld b, a
	ld a, [wSongPlaying]
	add a, $40
	cp [hl]
	jr nz, Music_StartSong_start
	cp $63
	jr z, Music_StartSong_start
	cp $65
	jr z, Music_StartSong_start
	cp $68
	jr z, Music_StartSong_start
	jr Music_StartSong_refuse

Music_StartSong_start:
	ld a, [hl]
	cp $6d
	jr nz, Music_StartSong_notResume
	ld a, [wPausedSong]
	cp $2d
	jp z, Music_RestorePausedSong
; Song $71 (hurry up) sets wHurryMode and remembers the interrupted song in wResumeSong. Any
; other song clears wHurryMode unless HurryKeepTable says otherwise.
Music_StartSong_notResume:
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
	ld a, [hl+]
	ld [wCurrentSong], a
	ld [hl], a
	xor a
	ld [wChannelsPlayed], a
	ld a, b
	add a, $c0
	cp $31
	jr nz, Music_StartSong_normal
	ld b, a
	ld a, $01
	ld [wHurryMode], a
	ld a, [wPreviousSong]
	cp $62
	call z, Music_StartSong_resumePoint
	ld [wResumeSong], a
	ld a, b
	jr Music_StartSong_load

Music_StartSong_resumePoint:
	ld a, [wCh2ListPtr]
	sub $30
	ret

; one byte per song $62-$7F: 1 = keep hurry mode
HurryKeepTable:
	db $01, $01, $00, $01, $01, $00, $01, $00, $00, $00	; songs $62-$6b
	db $00, $00, $00, $00, $00, $01, $01, $00, $00, $00	; songs $6c-$75
	db $00, $00, $00, $00, $00, $00, $00, $00, $01, $00	; songs $76-$7f
Music_StartSong_normal:
	ld b, a
	sub $22
	ld hl, HurryKeepTable
	ld e, a
	ld d, $00
	add hl, de
	ld a, [hl]
	and a
	jr nz, Music_StartSong_keepHurry
	xor a
	ld [wHurryMode], a
Music_StartSong_keepHurry:
	ld a, b
	ld hl, wSongPlaying
Music_StartSong_load:
	dec hl
	ld [hl+], a
	ld b, a
	ld a, $01
	ld [wMusicActive], a
	ld a, b
	ld [hl], a
	ld b, a
	ld hl, SongTable
	and $7f
	call GetPointer
	call Music_LoadHeader
	jp Music_InitPanning

; Panning: mode (1 = fixed), period, NR51 x4 for each table entry. All entries are fixed $FF.
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
	ld hl, SongPanTable
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
Music_LoadPatterns:
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

; ch3 wave: not loaded while a ch3 SFX plays; ch3 is switched off first if it is on.
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

; Song end. After song $31 (index; song $71, hurry up) the interrupted song restarts: songs
; $62 and above are requested again, the level song (below $62) resumes at its section via
; Music_ResumeLevelSong.
.songEnd:
	ld a, [wSongPlaying]
	cp $31
	jp nz, Music_SongEnd
	ld a, [wResumeSong]
	cp $62
	jr c, Music_ResumeLevelSong
	ld [wSongRequest], a
	xor a
	ld [wMusicActive], a
	jp Music_Update

; Rebuild the music state of song $62 (the overworld theme, played as $22) at the section
; saved in wResumeSong, without restarting it from the top.
Music_ResumeLevelSong:
	push af
	call Music_Stop
	pop af
	cp $1c
	jr nz, .lists
	ld a, $02
.lists:
	ld hl, Song62_ResumeLists
	ld e, a
	ld d, $00
	add hl, de
	ld de, wCh2ListPtr
	call StoreHL
	ld de, $0022
	add hl, de
	ld de, wCh1ListPtr
	call StoreHL
	ld de, $0022
	add hl, de
	ld de, wCh3ListPtr
	call StoreHL
	ld de, $0020
	add hl, de
	ld de, wCh4ListPtr
	call StoreHL
	xor a
	ld [wTranspose], a
	ld hl, LengthTable_4D62
	ld de, wLengthTable
	call StoreHL
	call Music_LoadPatterns
	ld hl, $0067
	ld de, wCh1InstrEnv
	call StoreHL
	ld de, wCh2InstrEnv
	call StoreHL
	ld hl, Wave_557F
	ld de, wCh3WavePtr
	call StoreHL
	ld a, $80
	ld [wCh1InstrDuty], a
	ld [wCh2InstrDuty], a
	ld a, $21
	ld [wCh3Level], a
	ld hl, $0000
	ld de, wCh1RepeatPtr
	call StoreHL
	ld de, wCh2RepeatPtr
	call StoreHL
	ld de, wCh3RepeatPtr
	call StoreHL
	ld de, wCh4RepeatPtr
	call StoreHL
	xor a
	ld [wCh1Rest], a
	ld [wCh2Rest], a
	ld [wCh3Rest], a
	ld [wCh4Rest], a
	ld a, $22
	ld [wSongPlaying], a
	ld a, $62
	ld [wCurrentSong], a
	ret

StoreHL:
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	ret

Music_SongEnd:
	ld hl, wSongPlaying
	ld [hl], $00
	call Music_Stop
	ret

; unreferenced: LA's $9E (tempo) and $9F (transpose) commands
Unused_CmdTempo:
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable], a
	call IncPtr
	call ReadPtrByte
	ld [wLengthTable+1], a
	jr Music_SkipAndContinue

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
	jr Music_SkipAndContinue

; $9A: master volume, NR50 = value & $77.
Cmd_Volume:
	call IncPtr
	call ReadPtrByte
	and $77
	ldh [rNR50], a
	call IncPtr
	jr Music_ReadCommand

; $99: NRx2 written for rests on ch1 (wCh1RestEnv) or ch2 (wCh2RestEnv), once the channel
; has played a note.
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
	jr Music_ReadCommand

.ch1:
	ld a, b
	ld [wCh1RestEnv], a
	jr .next

.ch2:
	ld a, b
	ld [wCh2RestEnv], a
	jr .next

Music_Play:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, [wMusicActive]
	and a
	ret z
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
; Commands $97-$9D, lengths $A0-$AF. In hurry mode songs use faster length tables:
; $68 and $7E LengthTable_4D17, $65 LengthTable_4D80, every other song LengthTable_4D08.
Music_ReadCommand:
	call ReadPtrByte
	cp $00
	jp z, Cmd_PatternEnd
	cp $9d
	jp z, Cmd_Instrument
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
	ld a, [wHurryMode]
	and a
	jr z, Music_Length_lookup
	ld a, [wCurrentSong]
	cp $68
	jr z, Music_Length_hurry68
	cp $65
	jr z, Music_Length_hurry65
	cp $7e
	jr z, Music_Length_hurry7E
	ld hl, LengthTable_4D08
	jr Music_Length_lookup

Music_Length_hurry68:
	ld hl, LengthTable_4D17
	jr Music_Length_lookup

Music_Length_hurry7E:
	ld hl, LengthTable_4D17
	jr Music_Length_lookup

Music_Length_hurry65:
	ld hl, LengthTable_4D80
Music_Length_lookup:
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
	ld a, [hl]
	and a
	jr nz, .restDone
.firstRest:
	ld [hl], $01
.restDone:
	pop hl
	jr Music_Trigger

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
	ld [wSfx2Paused], a
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
NoiseTable:
	db $00	; offset 0
	db $08, $00, $00, $00, $c0	; NOISE_01: NR42, -, NR41, NR43, NR44
	db $09, $00, $38, $34, $c0	; NOISE_06: NR42, -, NR41, NR43, NR44
	db $88, $00, $2b, $05, $c0	; NOISE_0B: NR42, -, NR41, NR43, NR44
	db $86, $00, $13, $10, $c0	; NOISE_10: NR42, -, NR41, NR43, NR44
	db $43, $00, $20, $40, $80	; NOISE_15: NR42, -, NR41, NR43, NR44
	db $56, $00, $2b, $05, $c0	; NOISE_1A: NR42, -, NR41, NR43, NR44
	db $91, $00, $39, $05, $c0	; NOISE_1F: NR42, -, NR41, NR43, NR44
	db $f2, $00, $00, $18, $80	; NOISE_24: NR42, -, NR41, NR43, NR44
	db $61, $00, $3a, $05, $c0	; NOISE_29: NR42, -, NR41, NR43, NR44
	db $81, $00, $3a, $37, $c0	; NOISE_2E: NR42, -, NR41, NR43, NR44
	db $57, $00, $00, $60, $80	; NOISE_33: NR42, -, NR41, NR43, NR44
	db $02, $04, $08, $10, $20	; NOISE_38: NR42, -, NR41, NR43, NR44
	db $40, $01, $18, $30, $02	; NOISE_3D: NR42, -, NR41, NR43, NR44
	db $06, $0e, $1e, $16, $0c	; NOISE_42: NR42, -, NR41, NR43, NR44
LengthTable_4D08:
	db $01, $03, $06, $0c, $18, $30, $09, $12, $24, $02, $04, $08, $01, $01, $08
LengthTable_4D17:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $02, $05, $03, $01, $01, $60
LengthTable_4D26:
	db $03, $05, $0a, $14, $28, $50, $0f, $1e, $3c, $02, $08, $0d, $0e, $01, $78
LengthTable_4D35:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $03, $08, $10, $02, $04, $90
LengthTable_4D44:
	db $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $09, $12, $02, $01, $a8
LengthTable_4D53:
	db $04, $08, $10, $20, $40, $80, $18, $30, $60, $04, $02, $01, $01, $00, $c0
LengthTable_4D62:
	db $02, $04, $09, $12, $24, $48, $0c, $1b, $36, $02, $06, $0c, $01, $01, $6c
LengthTable_4D71:
	db $04, $08, $0b, $16, $2c, $50, $0f, $21, $3c, $02, $09, $10, $02, $01, $78
LengthTable_4D80:
	db $01, $02, $03, $06, $10, $20, $05, $09, $18, $01, $02, $04, $02, $02, $02
; unreferenced: LA's release envelopes
Unused_ReleaseEnvelopes:
	db $10, $32, $22, $47, $81, $20, $00
