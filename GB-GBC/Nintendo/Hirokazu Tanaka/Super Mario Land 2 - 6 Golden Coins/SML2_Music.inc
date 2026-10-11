; Super Mario Land 2 sound driver: song table, music code, bank 4 $5244-$5ACB

SongTable:
	dw Song01_Header
	dw Song02_Header
	dw Song03_Header
	dw Song04_Header
	dw Song05_Header
	dw Song06_Header
	dw Song07_Header
	dw Song08_Header
	dw Song09_Header
	dw Song07_Header
	dw Song11_Header
	dw Song12_Header
	dw Song13_Header
	dw Song14_Header
	dw Song15_Header
	dw Song16_Header
	dw Song17_Header
	dw Song18_Header
	dw Song19_Header
	dw Song20_Header
	dw Song21_Header
	dw Song22_Header
	dw Song23_Header
	dw Song24_Header
	dw Song25_Header
	dw Song26_Header
	dw Song27_Header
	dw Song28_Header
	dw Song29_Header
	dw Song30_Header
	dw Song31_Header
	dw Song32_Header
	dw Song33_Header
	dw Song34_Header
	dw Song35_Header
	dw Song36_Header
	dw Song37_Header
	dw Song38_Header
	dw Song39_Header
	dw Song40_Header
	dw Song07_Header
	dw Song07_Header
GetSongPointer:
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

; Unreferenced: save $A410-$A449 to $A490 and restore it. Both loops test the wrong
; register's low byte (e in the save, l in the restore) against $4A, so each copies
; 186 bytes instead of 58.
Music_SaveState_Unused:
	ld hl, wCh1ListPtr
	ld de, wSavedChannels
.loop:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, e
	cp $4a
	jr nz, .loop
	ld a, $05
	ld [wSavedSong], a
	ret

Music_RestoreState_Unused:
	ld de, wCh1ListPtr
	ld hl, wSavedChannels
.loop:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, l
	cp $4a
	jr nz, .loop
	ld a, [wSavedSong]
	ld [wSongPlaying], a
	ret

Music_StopSong:
	jp Sound_Stop

; a = wSongRequest (1-42, $FF = stop), hl = wSongPlaying.
Music_StartSong:
	cp $ff
	jr z, Music_StopSong
	cp $2b
	ret nc
	ld [hl], a
	ld b, a
	ld hl, SongTable
	and $3f
	call GetSongPointer
	call Music_LoadHeader
	jp Music_InitPanning

SongPanTable:
	db $01, $00, $ff, $ff, $00, $00	; song 01: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 02: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 03: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 04: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 05: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 06: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 07: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 08: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 09: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 10: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 11: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 12: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 13: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 14: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 15: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 16: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 17: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 18: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 19: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 20: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 21: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 22: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 23: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 24: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 25: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 26: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 27: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 28: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 29: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 30: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 31: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 32: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 33: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 34: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 35: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 36: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 37: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 38: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 39: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 40: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 41: mode, period, NR51 x4
	db $01, $00, $ff, $ff, $00, $00	; song 42: mode, period, NR51 x4
Music_InitPanning:
	ld a, [wSongPlaying]
	ld hl, SongPanTable
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

; Panning: mode 1 = fixed; otherwise cycle through the four NR51 values every period
; frames. All 42 songs use mode 1, NR51 = $FF.
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

; Songs 2, 3, 12, 15, 24 clear wFastMusic, song 9 sets it, every other song keeps it.
; With wFastMusic the header's transpose gets +4 (2 semitones) and the second length
; table is used.
Music_LoadHeader:
	call Sound_ClearState
	ld a, [wSongRequest]
	cp $02
	jr z, .normal
	cp $03
	jr z, .normal
	cp $0c
	jr z, .normal
	cp $0f
	jr z, .normal
	cp $18
	jr z, .normal
	cp $09
	jr nz, .copy
	ld a, $01
	ld [wFastMusic], a
	jr .copy

.normal:
	xor a
	ld [wFastMusic], a
.copy:
	ld de, wTranspose
	ld b, $00
	ld a, [hl+]
	ld [de], a
	ld a, [wFastMusic]
	and a
	jr z, .lengthTable
	ld b, $04
	ld a, [de]
	add a, b
	ld [de], a
	ld b, $00
.lengthTable:
	inc e
	call CopyWord
	ld a, [wFastMusic]
	and a
	jr z, .skipFast
	dec e
	call CopyWord
	jr .lists

.skipFast:
	inc hl
	inc hl
.lists:
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

; $9D: three bytes to Env/Release/Duty (ignored while wInstrumentLock is set).
; ch3: wave pointer, loaded unless a ch3 effect plays.
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
	ld a, [wInstrumentLock]
	and a
	jr nz, .locked
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
.locked:
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

; Frame without a new note: ch3 level-bit-7 release, pitch effects, release envelope.
Music_Sustain:
	ld a, [wMusicChannel]
	cp $03
	jr nz, .effects
	ld a, [wCh3InstrDuty]
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

; $00: next list entry; $00xx ends the song (Sound_Stop), $FFxx loops.
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

.songEnd:
	ld hl, wSongPlaying
	ld [hl], $00
	call Sound_Stop
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
Music_Update:
	ld hl, wSongPlaying
	ld a, [hl]
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
; Commands $95-$9F, lengths $A0-$AF. A length also sets the release point when the
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
	jp z, Cmd_Ch3FadeOn
	cp $9a
	jp z, Cmd_Ch3FadeOff
	cp $97
	jp z, Cmd_DropOn
	cp $98
	jp z, Cmd_DropOff
	cp $95
	jp z, Cmd_BendOn
	cp $96
	jp z, Cmd_BendOff
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
; Note: restart the bend / vibrato / drop / ch3-fade state of the channel.
Music_Note:
	ld a, [wMusicChannel]
	cp $04
	jr z, .lookup
	push de
	ld de, wBend
	call IndexByChannel
	ld a, [de]
	and a
	jr z, .resetEffects
	ld a, $01
	ld [de], a
	inc e
	xor a
	ld [de], a
.resetEffects:
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
	ld de, wCh3Fade
	ld a, [de]
	and a
	jr z, .effectsDone
	ld a, $01
	ld [de], a
	xor a
	ld [wCh3FadeTimer], a
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

Music_NoiseNote:
	push hl
	ld a, c
	cp $1f
	jr z, .sfxDrum
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

; Noise byte $1F: start ch4 effect 3 instead of a drum (unless an effect owns ch4).
.sfxDrum:
	ld a, [wCh4Flags]
	bit 7, a
	jp nz, Music_Trigger.done
	ld a, $03
	ld [wSfx4Request], a
	call Sfx4_Update
	jp Music_Trigger.done

; Write the note: NRx1 = Duty, NRx2 = Env (rest: $08), period, NRx4 | $80 (trigger, no length).
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
	jr .write

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
.write:
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

; Pitch effect from the low nibble of Duty: 1 = vibrato table after 24 frames,
; 2-15 = period - 1. Then bend, drop and ch3 fade.
Music_Effects:
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	and $0f
	jr z, .slides
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
.slides:
	ld a, [wMusicChannel]
	cp $04
	jp z, Music_Effects_ret
	ld c, $13
	cp $01
	jp z, .channel
	ld c, $18
	cp $02
	jp z, .channel
	ld c, $1d
.channel:
	ld de, wBend
	call IndexByChannel
	ld a, [de]
	and a
	jp nz, Music_Bend
	ld de, wDrop
	call IndexByChannel
	ld a, [de]
	and a
	jp nz, Music_Drop
	ld a, [wMusicChannel]
	cp $03
	jp nz, Music_Effects_ret
	ld a, [wCh3Fade]
	and a
	jp nz, Music_Ch3Fade
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
	jp .slides

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

; Pause: mute, cancel the effects and play a 5-step jingle on ch2.
Sound_Pause:
	call Sound_MuteChannels
	xor a
	ld [wSfx1Playing], a
	ld [wSfx3Playing], a
	ld [wSfx4Playing], a
	ld [wPauseStep], a
	ld a, $01
	ld [wPaused], a
	ld b, $04
	ld hl, wCh1Flags
	ld de, $0010
.release:
	res 7, [hl]
	add hl, de
	dec b
	jr nz, .release
	ld hl, PauseJingle
	ld de, wPauseTimer
	call SetRegs_Ch2
	jp Sound_Update.clearRequests

Sound_Unpause:
	xor a
	ld [wPaused], a
	ld [wSfx1Priority], a
	ld [wSfx3Priority], a
	ld [wSfx4Priority], a
	jp Sound_Update.main

Sound_Paused:
	ld de, wPauseTimer
	call Sfx_DecTimer
	jp nz, Sound_Update.clearRequests
	ld bc, wPauseStep
	call Sfx_IncStep
	cp $06
	jp z, .hold
	ld hl, PauseJingleTable
	call GetPointer
	ld de, wPauseTimer
	call SetRegs_Ch2
	jp Sound_Update.clearRequests

.hold:
	ld a, $f0
	ld [wPauseTimer], a
	ld a, $05
	ld [wPauseStep], a
	jp Sound_Update.clearRequests

; pause jingle: 5 steps on ch2 (NR21-NR24, frames)
PauseJingleTable:
	dw PauseJingle+5, PauseJingle, PauseJingle+10, PauseJingle+15, PauseJingle+20
PauseJingle:
	db $80, $a1, $c1, $c7, $05
	db $80, $a1, $be, $c7, $05
	db $80, $a1, $d1, $c7, $0c
	db $80, $a1, $b6, $c7, $07
	db $80, $a1, $ba, $c7, $0f
; $99/$9A: ch3 fade on/off. NR32: 50% on frame 3, 25% on 5, mute on 7, 25% on 10,
; mute on 13, then the fade stops.
Cmd_Ch3FadeOn:
	ld a, $01
Cmd_Ch3Fade_store:
	ld [wCh3Fade], a
	call IncPtr
	jp Music_ReadCommand

Cmd_Ch3FadeOff:
	xor a
	ld [wCh3Fade], a
	jr Cmd_Ch3Fade_store

Music_Ch3Fade:
	cp $02
	jp z, Music_Effects_ret
	ld bc, wCh3FadeTimer
	call Sfx_IncStep
	ld c, $1c
	ld b, $40
	cp $03
	jr z, .write
	ld b, $60
	cp $05
	jr z, .write
	cp $0a
	jr z, .write
	ld b, $00
	cp $07
	jr z, .write
	cp $0d
	jp nz, Music_Effects_ret
	ld a, $02
	ld [wCh3Fade], a
.write:
	ld a, b
	ldh [c], a
	jp Music_Effects_ret

; $97/$98: drop on/off: the period falls by 100 every frame.
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

; $95/$96: bend on/off: start 4 below the note and rise 1 per frame.
Cmd_BendOn:
	ld de, wBend
	call IndexByChannel
	ld a, $01
Cmd_Bend_store:
	ld [de], a
	call IncPtr
	jp Music_ReadCommand

Cmd_BendOff:
	ld de, wBend
	call IndexByChannel
	xor a
	jp Cmd_Bend_store

Music_Bend:
	cp $02
	jp z, Music_Effects_ret
	inc e
	ld a, [de]
	and a
	jr z, .start
	cp $05
	jr z, .done
	inc a
	ld [de], a
	call ReadPitch
	ld hl, $0001
	add hl, de
	call WritePitch
	jp Music_Effects_ret

.done:
	ld de, wBend
	call IndexByChannel
	ld a, $02
	ld [de], a
	inc e
	xor a
	ld [de], a
	jp Music_Effects_ret

.start:
	inc a
	ld [de], a
	pop hl
	push hl
	call GetNoteFreq
	ld hl, $fffc
	add hl, de
	call WritePitch
	jp Music_Effects_ret

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
	jp z, Music_Effects.slides
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
	jp Music_Effects.slides

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

