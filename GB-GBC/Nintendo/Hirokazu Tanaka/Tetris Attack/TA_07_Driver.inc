; Tetris Attack SFX and music, bank $07: music driver copy B and tables, $67A3-$7030

; unreferenced: start the fade-out (wFadeStep = 1). The game sets wFadeStep itself (home $0545).
Music_StartFadeOut:
	ld a, $01
	ld [wFadeStep], a
	ret

; Song fade-out (wFadeStep non-zero; the game sets it at home $0545): mute ch3 and ch4, then every 6 frames
; lower the ch1/ch2 envelopes (FadeOutEnvelopes); at the end stop and request song $22.
Music_FadeOut:
	ld a, [wFadeStep]
	and a
	ret z
	ld c, a
	cp $01
	jr z, .start
	jr .step

.start:
	xor a
	ldh [rNR30], a
	ld hl, wCh3Flags
	set 7, [hl]
	ld hl, wCh4Flags
	set 7, [hl]
.step:
	ld hl, wFadeTimer
	inc [hl]
	ld a, [hl]
	cp $04
	ret nz
	ld [hl], $00
	ld hl, wFadeStep
	inc [hl]
	ld b, $00
	ld hl, FadeOutEnvelopes
	add hl, bc
	ld a, [hl]
	and a
	jr z, .end
	ld [wCh1InstrEnv], a
	ld bc, $0010
	add hl, bc
	ld a, [hl]
	ld [wCh2InstrEnv], a
	ret

.end:
	ld [wSongPlaying], a
	ld [wFadeStep], a
	ld [wFadeTimer], a
	ld a, $1c
	ld [wSongRequest], a
	jp Sound_StopMusic

; ch1 envelope per fade step (0 = end), ch2 envelope 16 bytes later
FadeOutEnvelopes:
	db $54, $54, $54, $44, $44, $44, $34, $34, $34, $24, $24, $24, $14, $14, $14, $00
	db $54, $54, $54, $44, $44, $44, $34, $34, $34, $24, $24, $24, $14, $14, $14
; songs $01-$23; this bank plays $1D-$23, the others point at a dummy header
SongTable:
	dw DummySongHeader	; $01: other bank
	dw DummySongHeader	; $02: other bank
	dw DummySongHeader	; $03: other bank
	dw DummySongHeader	; $04: other bank
	dw DummySongHeader	; $05: other bank
	dw DummySongHeader	; $06: other bank
	dw DummySongHeader	; $07: other bank
	dw DummySongHeader	; $08: other bank
	dw DummySongHeader	; $09: other bank
	dw DummySongHeader	; $0a: other bank
	dw DummySongHeader	; $0b: other bank
	dw DummySongHeader	; $0c: other bank
	dw DummySongHeader	; $0d: other bank
	dw DummySongHeader	; $0e: other bank
	dw DummySongHeader	; $0f: other bank
	dw DummySongHeader	; $10: other bank
	dw DummySongHeader	; $11: other bank
	dw DummySongHeader	; $12: other bank
	dw DummySongHeader	; $13: other bank
	dw DummySongHeader	; $14: other bank
	dw DummySongHeader	; $15: other bank
	dw DummySongHeader	; $16: other bank
	dw DummySongHeader	; $17: other bank
	dw DummySongHeader	; $18: other bank
	dw DummySongHeader	; $19: other bank
	dw DummySongHeader	; $1a: other bank
	dw DummySongHeader	; $1b: other bank
	dw DummySongHeader	; $1c: other bank
	dw Song1D_Header	; $1d
	dw Song1E_Header	; $1e
	dw Song1F_Header	; $1f
	dw Song20_Header	; $20
	dw Song21_Header	; $21
	dw Song22_Header	; $22
	dw DummySongHeader	; $23
; unreferenced: the SFX register writers and Sfx_GetInitPointer of the LA-style SFX code
Unused_SetRegs:
	push bc
	ld c, $10
	ld b, $05
	jr .l0

	push bc
	ld c, $16
	ld b, $04
	jr .l0

	push bc
	ld c, $1a
	ld b, $05
	jr .l0

	push bc
	ld c, $20
	ld b, $04
.l0:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .l0
	pop bc
	ret

	inc e
	ld [wPitchEffect], a
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

; Load the ch3 wave and keep a copy at wWaveCopy ($D400) for the SFX engine.
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
	ld bc, wWaveCopy
	ld l, e
	ld h, d
.copy:
	ld a, [hl+]
	ld [bc], a
	inc c
	ld a, c
	cp $10
	jr nz, .copy
	pop bc
	ret

; unreferenced: save / restore the music state (as bank $08)
Music_SaveState_Unused:
	ld hl, wCh1ListPtr
	ld de, wSfx1Timer
.l0:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, e
	cp $4a
	jr nz, .l0
	ld a, $05
	ld [wSavedSong], a
	ret

Music_RestoreState_Unused:
	ld de, wCh1ListPtr
	ld hl, wSfx1Timer
.l0:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, l
	cp $4a
	jr nz, .l0
	ld a, [wSavedSong]
	ld [wSongPlaying], a
	ret

Music_Stop:
	jp Sound_StopMusic

; Song request: $FF = stop, $24 and above ignored.
Music_StartSong:
	ld hl, wSongRequest
	ld a, [hl+]
	cp $ff
	jr z, Music_Stop
	cp $24
	ret nc
	ld [hl], a
	ld b, a
	ld hl, SongTable
	and $3f
	call GetPointer
	call Music_LoadHeader
	jp Music_InitPanning

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

; Panning: mode (1 = fixed), period, NR51 x4
SongPanTable:
	db $01, $00, $ff, $56, $00, $00	; $01
	db $01, $ff, $ff, $eb, $00, $00	; $02
	db $01, $ff, $ff, $b7, $00, $00	; $03
	db $01, $ff, $ff, $ed, $00, $00	; $04
	db $01, $ff, $ff, $ff, $00, $00	; $05
	db $01, $ff, $ff, $be, $00, $00	; $06
	db $01, $ff, $ff, $f7, $00, $00	; $07
	db $01, $ff, $ff, $e7, $00, $00	; $08
	db $01, $ff, $ff, $e7, $00, $00	; $09
	db $01, $00, $ff, $56, $00, $00	; $0a
	db $01, $ff, $ff, $eb, $00, $00	; $0b
	db $01, $ff, $ff, $b7, $00, $00	; $0c
	db $01, $ff, $ff, $ed, $00, $00	; $0d
	db $01, $ff, $ff, $ff, $00, $00	; $0e
	db $01, $ff, $ff, $be, $00, $00	; $0f
	db $01, $ff, $ff, $f7, $00, $00	; $10
	db $01, $ff, $ff, $e7, $00, $00	; $11
	db $01, $00, $ff, $56, $00, $00	; $12
	db $01, $ff, $ff, $eb, $00, $00	; $13
	db $01, $ff, $ff, $b7, $00, $00	; $14
	db $01, $ff, $ff, $ed, $00, $00	; $15
	db $01, $ff, $ff, $ff, $00, $00	; $16
	db $01, $ff, $ff, $be, $00, $00	; $17
	db $01, $ff, $ff, $f7, $00, $00	; $18
	db $01, $ff, $ff, $f7, $00, $00	; $19
	db $01, $ff, $ff, $f7, $00, $00	; $1a
	db $01, $ff, $ff, $f7, $00, $00	; $1b
	db $01, $ff, $ff, $f7, $00, $00	; $1c
	db $01, $ff, $ff, $f7, $00, $00	; $1d
	db $01, $ff, $ff, $f7, $00, $00	; $1e
	db $01, $ff, $ff, $f7, $00, $00	; $1f
	db $01, $ff, $ff, $f7, $00, $00	; $20
	db $01, $ff, $ff, $f7, $00, $00	; $21
	db $01, $ff, $ff, $f7, $00, $00	; $22
	db $01, $ff, $ff, $f7, $00, $00	; $23
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

Cmd_Instrument_wave:
	push hl
	xor a
	ldh [rNR30], a
	ld l, e
	ld h, d
	call LoadWave
.done:
	pop hl
	jr Music_NextByte

; $9D: ignored (operands skipped) while the song fades out.
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
	ld a, [wFadeStep]
	and a
	jr nz, .check3
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
.check3:
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
	call Sound_StopMusic
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

Music_Play:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	call Music_UpdatePanning
	call Music_FadeOut
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
; Commands $9B-$9F, lengths $A0-$AF (release point as in SML2 / LA).
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
Music_Note:
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
	jr .ch1b

; unreachable: ld b, $33 / ld a, $1D / write NR10
.unused:
	ld b, $33
	ld a, $1d
	ldh [c], a
	jr .l0

.ch1b:
	ld a, $00
.l0:
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

Vibrato_GetStep:
	ld a, b
	srl a
	ld l, a
	ld h, $00
	add hl, de
	ld e, [hl]
	ret

; Pitch effect from the low nibble of InstrDuty: 1 = vibrato (VibratoTable, Dr. Mario / Tetris
; style: one signed nibble per frame), other = period - 1.
Music_Effects:
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	and $0f
	jr z, .done
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
.done:
	pop hl
	ret

.pitch:
	inc l
	ld a, [hl+]
	ld e, a
	ld a, [hl]
	ld d, a
	push de
	ld a, l
	add a, $04
	ld l, a
	ld b, [hl]
	ld a, [wPitchEffect]
	cp $01
	jr z, .vibrato
	cp $03
	jr z, .detune
.detune:
	ld hl, $ffff
	jr .add

.vibrato:
	ld de, VibratoTable
	call Vibrato_GetStep
	bit 0, b
	jr nz, .nibble
	swap e
.nibble:
	ld a, e
	and $0f
	bit 3, a
	jr z, .positive
	ld h, $ff
	or $f0
	jr .signed

.positive:
	ld h, $00
.signed:
	ld l, a
.add:
	pop de
	add hl, de
	ld a, l
	ldh [c], a
	inc c
	ld a, h
	ldh [c], a
	jr .done

; vibrato: signed nibbles, two per byte, read by NoteFrames (same table as Tetris)
VibratoTable:
	db $00, $00, $00, $00, $00, $00, $10, $00, $0f, $00, $00, $11, $00, $0f, $f0, $01
	db $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12
	db $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10
	db $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff
	db $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef
	db $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01
	db $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12
	db $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10, $ff, $ef, $01, $12, $10
	db $ff, $ef, $01, $12, $10, $ff, $ef
; the 30 zero bytes that follow Dr. Mario's wobble table. Here NoteFrames / 2 never exceeds
; 127 and VibratoTable has 135 bytes, so they are never read
VibratoTable_Pad:
	ds 30, $00
; Release: at NoteFrames = wReleaseFrame, write ReleaseEnvelopes[low nibble - 1] (ch1, ch2).
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

NoteTable:
	dw $0f00	; index 0
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
	dw $0773	; As5
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
	dw $07c4	; Cs7
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
; ch4: offsets 1 + 5n: NR42, unused, NR41, NR43, NR44
NoiseTable:
	db $00
	db $00, $00, $00, $00, $c0	; NOISE_01
	db $71, $00, $3a, $00, $c0	; NOISE_06
	db $b1, $00, $29, $01, $c0	; NOISE_0B
	db $a2, $00, $00, $04, $c0	; NOISE_10
	db $a1, $00, $f4, $5e, $c0	; NOISE_15
	db $71, $00, $00, $3f, $c0	; NOISE_1A
	db $1b, $00, $00, $13, $80	; NOISE_1F
	db $c1, $00, $29, $04, $c0	; NOISE_24
	db $81, $00, $3a, $00, $c0	; NOISE_29
	db $c1, $00, $f4, $5e, $c0	; NOISE_2E
	db $91, $00, $00, $3f, $c0	; NOISE_33
; unreferenced: Dr. Mario's six waves (its $6BC3-$6C22), in Dr. Mario's order, then the first
; bytes of a Dr. Mario-style length-table area
Unused_DrMarioWaves:
	db $23, $33, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $8a, $a8, $32, $10
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10
	db $77, $23, $56, $78, $99, $98, $76, $67, $9a, $df, $fe, $c9, $85, $77, $77, $77
	db $11, $23, $56, $78, $99, $98, $76, $67, $9a, $df, $fe, $c9, $85, $42, $11, $31
	db $11, $12, $22, $33, $34, $44, $55, $55, $66, $66, $66, $66, $66, $11, $22, $32
	db $87, $66, $65, $55, $54, $44, $43, $32, $22, $11, $11, $66, $61, $11, $66, $66
	db $00, $01, $02, $04, $08, $10, $03, $06, $0c, $01, $02, $04, $08, $10, $20, $06
	db $0c, $18, $02, $03, $06, $0c, $18, $30, $09, $12, $24, $04, $08
; length tables (they overlap: a table starts wherever a header or TEMPO points)
LengthTable_6FE0:
	db $02, $04, $08, $10, $20, $40, $0c, $18, $30, $05, $03, $01, $03, $05, $0a
	db $14, $28, $50, $0f, $1e, $3c
LengthTable_6FF5:
	db $03, $06, $0c, $18, $30, $60, $12, $24, $48, $12, $2a, $02, $c0, $a8, $00
	db $00, $03, $07, $0e, $1c, $38, $70, $15, $2a, $54, $09, $12, $02, $01, $0a
	db $05, $04, $08, $10, $20, $40, $80, $18, $30, $60, $18, $38
LengthTable_701F:
	db $04, $09, $12, $24, $48, $90, $1b, $36, $6c, $0c, $18
ReleaseEnvelopes:
	db $52, $31, $21, $00, $00, $00, $00
