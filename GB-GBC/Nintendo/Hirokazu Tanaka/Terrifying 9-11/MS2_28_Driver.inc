; Metal Slug 2 music: music driver and tables, bank $28 $4000-$4A27

; byte $1D: tag byte at the start of the bank (the SFX bank has $1E)
BankTag:
	db $1d
; Entry points: update, init, stop (LA: init, stop, update).
	jp Music_Update

	jp Music_Init

	jp Sound_Stop

; Called once per frame before the SFX bank. A new song request re-initialises the whole
; sound RAM and the APU first.
Music_Update:
	ld hl, wSongRequest
	ld a, [hl+]
	and a
	jp nz, Music_Update_start
	call MusicDrum_Update
.play:
	call Music_Play
	ret

; Clear all four request bytes.
Music_ClearRequests:
	xor a
	ld [wSfx1Request], a
	ld [wSongRequest], a
	ld [wSfx3Request], a
	ld [wSfx4Request], a
	ret

Music_Update_start:
	push hl
	push af
	call Music_Init
	pop af
	pop hl
	ld [hl], a
	call Music_StartSong
	call Music_ClearRequests
	jp Music_Update.play

Music_Init:
	ld hl, wTranspose
.clear:
	ld [hl], $00
	inc l
	jp nz, .clear
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	ret

; ch4 "drum" effect 1 from LA, kept although no MS2 song uses ch4.
MusicDrum_Update:
	ld de, wSfx4Timer
	ld hl, wSfx4Request
	ld a, [hl+]
	cp $01
	jp z, .start
	ld a, [hl]
	cp $01
	jp z, .playing
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
	jp MusicDrum_WriteRegs

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
	jp nz, .loop
	ld a, [hl]
	ld [de], a
	ret

GetPointer:
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
	ret

; unreferenced: LA's LoadWave
Unused_LoadWave:
	push bc
	ld c, $30
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jp nz, .loop
	pop bc
	ret

StopSfx4:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [$c8c9], a
	ld [wSfx4Var], a
	ld a, $08
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ret

; unreferenced: LA's Music_Stop (song request $FF)
Unused_MusicStop:
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

; Songs 1-10. Nothing starts while wMusicDisabled is set.
Music_StartSong:
	ld b, a
	ld a, [wMusicDisabled]
	and a
	jp nz, Music_ClearRequests
	ld a, [wCurrentSong]
	ld [wPreviousSong], a
	ld a, [hl]
	ld [wCurrentSong], a
	ld b, a
	ld hl, SongTable
	call GetPointer
	call Music_LoadHeader
	ret

; ch3 instrument: wave = WaveTable + InstrEnv (a byte offset), loaded unless a ch3 SFX
; plays.
Music_LoadWave:
	ld a, [wMusicChannel]
	cp $03
	jp nz, .done
	push hl
	xor a
	ldh [rNR30], a
	ld hl, WaveTable
	ld a, [wCh3WaveOffset]
	add a, l
	ld l, a
	ld a, $00
	adc a, h
	ld h, a
	ld c, $30
.loop:
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, c
	cp $40
	jp nz, .loop
	ld a, $80
	ldh [rNR30], a
	pop hl
.done:
	ret

; Counter += (speed + 1) * (length nibble + 1), then - 1. The release point is computed as
; in LA: InstrRelease bit 7 = half, bit 6 = a quarter, otherwise three quarters (at least
; 2).
Music_SetLength:
	push hl
	ld e, a
	inc l
	inc l
	ld a, [hl+]
	and $0f
	add a, $01
	ld d, a
.add:
	ld a, [hl]
	add a, d
	ld [hl], a
	ld a, e
	or a
	jp z, .release
	dec e
	jp .add

.release:
	dec [hl]
	ld de, wReleaseFrameBase
	ld a, [wMusicChannel]
	add a, e
	ld e, a
	ld b, [hl]
	push hl
	ld a, l
	add a, $04
	ld l, a
	ld c, [hl]
	pop hl
	ld a, b
	srl a
	sla c
	jr c, .store
	ld b, a
	srl a
	sla c
	jr c, .store
	add a, b
.store:
	ld c, a
	and a
	jr nz, .storeRelease
	ld c, $02
.storeRelease:
	ld a, c
	ld [de], a
	ld a, l
	add a, $0b
	ld l, a
	ld [hl], $00
	pop hl
	ret

; unreferenced: LA's CopyWordIndirect and CopyWord
Unused_CopyWordIndirect:
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

Unused_CopyWord:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl+]
	ld [de], a
	ret

; Header: count - 1, then (channel 0-3, stream pointer) per channel; bit 15 of the
; pointer is masked off. LA's ch4 effect exceptions are kept.
Music_LoadHeader:
	ld a, [wSfx4Playing]
	cp $05
	jp z, .load
	cp $0c
	jp z, .load
	cp $1a
	jp z, .load
	cp $24
	jp z, .load
	cp $2a
	jp z, .load
	cp $2e
	jp z, .load
	cp $3f
	jp z, .load
	call StopSfx4
.load:
	call Music_ClearState
	ld a, [hl+]
	ld b, a
.channel:
	ld a, [hl+]
	swap a
	ld e, a
	ld d, $00
	push hl
	ld hl, wCh1StreamPtr
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl+]
	and $7f
	ld [de], a
	dec b
	ld a, b
	cp $ff
	jp nz, .channel
	xor a
	ld [wCh1NoteFrames], a
	ld [wCh2NoteFrames], a
	ld [wCh3NoteFrames], a
	ret

; unreferenced: LA's $9D command
Unused_CmdInstrumentWave:
	ld a, [wSfx3Playing]
	and a
	jp nz, Music_ChannelDone
	xor a
	ldh [rNR30], a
	ld l, e
	ld h, d
	call Unused_LoadWave
	jp Music_ChannelDone

Unused_CmdInstrument:
	call ReadPtrByte
	ld e, a
	call IncPtr
	call ReadPtrByte
	ld d, a
	call IncPtr
	call ReadPtrByte
	call IncPtr
	ld c, a
	ld a, l
	add a, $06
	ld l, a
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], c
	push hl
	ld hl, wMusicChannel
	ld a, [hl]
	cp $03
	jp z, Unused_CmdInstrumentWave
Music_ChannelDone:
	pop hl
	jp Music_NextChannel

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

; unreferenced: LA's IncPtr2
Unused_IncPtr2:
	push de
	ld a, [hl+]
	ld e, a
	ld a, [hl-]
	ld d, a
	inc de
	inc de
	jp IncPtr.store

ReadPtrByte:
	ld a, [hl+]
	ld c, a
	ld a, [hl-]
	ld b, a
	ld a, [bc]
	ret

; Frame without a new event: count down, ch3 50% drop 6 frames before the end, effects,
; release envelope.
Music_Sustain:
	dec [hl]
	ld a, [wMusicChannel]
	cp $03
	jp nz, .effects
	ld a, [wCh3Level]
	bit 7, a
	jp z, .effects
	ld a, [hl]
	cp $06
	jp nz, .effects
	ld a, $40
	ldh [rNR32], a
.effects:
	dec l
	dec l
	dec l
	push hl
	ld a, l
	add a, $0f
	ld l, a
	bit 7, [hl]
	jp nz, Music_ChannelDone
	pop hl
	push hl
	call Music_Effects
	call Music_Release
	jp Music_ChannelDone

Music_Effects_ret:
	pop hl
	ret

; Pitch effect from the low nibble of InstrDuty: 1 = vibrato after 24 frames, other
; non-zero = period - 1 per frame. Then drop and the ch3 fades (LA bank $1B).
Music_Effects:
	push hl
	ld a, l
	add a, $08
	ld l, a
	ld a, [hl]
	and $0f
	jp z, .drop
	ld [wPitchEffect], a
	ld a, [wMusicChannel]
	ld c, $13
	cp $01
	jp z, .pitch
	ld c, $18
	cp $02
	jp z, .pitch
	ld c, $1d
	cp $03
	jp z, .pitch
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
	jp z, .first
	cp $2d
	jp z, .wrap
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
	jp .apply

.first:
	ld a, $01
	ld [de], a
	jp .apply

Music_Drop:
	inc e
	ld a, [de]
	and a
	jp nz, .next
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
	jp .apply

GetNoteFreq:
	ld a, $09
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

; As in LA, but nothing happens on a rest (wCh3Sounding = 0).
Music_Ch3FadeOut:
	cp $02
	jp z, Music_Effects_ret
	ld a, [wCh3Sounding]
	or a
	jp z, Music_Effects_ret
	ld bc, wCh3FadeOutTimer
	call IncByteBC
	ld c, $1c
	ld b, $40
	cp $03
	jp z, Music_Ch3Fade_write
	ld b, $60
	cp $05
	jp z, Music_Ch3Fade_write
	cp $0a
	jp z, Music_Ch3Fade_write
	ld b, $00
	cp $07
	jp z, Music_Ch3Fade_write
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

Music_Ch3FadeIn:
	cp $02
	jp z, Music_Effects_ret
	ld a, [wCh3Sounding]
	or a
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

Music_Release:
	ld a, [wCh1Sounding]
	and a
	jp z, .ch2
	ld a, [wCh1InstrRelease]
	and a
	jp z, .ch2
	and $0f
	ld b, a
	ld hl, wReleaseFrame
	ld a, [wCh1NoteFrames]
	cp [hl]
	jp nz, .ch2
	ld c, $12
	ld de, wCh1Freq+1
	ld a, [wCh1Flags]
	bit 7, a
	jp nz, .ch2
	call Music_ReleaseWrite
.ch2:
	ld a, [wCh2Sounding]
	and a
	ret z
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

; NRx2 at the release point, index = low nibble of InstrRelease
ReleaseEnvelopes:
	db $10, $32, $22, $47, $60, $20, $00
; $C0-$CF: rest, length nibble as for notes. ch4 is silenced directly.
Cmd_Rest:
	cp $d0
	jp nc, Cmd_Instrument
	and $0f
	call Music_SetLength
	ld a, [wMusicChannel]
	cp $04
	jp z, .noise
	push hl
	ld a, l
	add a, $0b
	ld l, a
	ld [hl], $00
	pop hl
	jp Music_Trigger

.noise:
	ld a, $00
	ldh [rNR41], a
	ldh [rNR42], a
	ldh [rNR43], a
	ld a, $c0
	ldh [rNR44], a
	jp Music_NextChannel

; $D0-$DF xx yy zz: speed = low nibble; InstrEnv, InstrRelease, InstrDuty = xx, yy, zz.
Cmd_Instrument:
	cp $e0
	jp nc, Music_Command
	push hl
	and $0f
	ld b, a
	ld a, l
	add a, $02
	ld e, a
	ld d, h
	ld a, [de]
	and $f0
	or b
	ld [de], a
	pop hl
	ld a, l
	add a, $06
	ld e, a
	ld d, h
	call ReadPtrByte
	ld [de], a
	inc e
	call IncPtr
	call ReadPtrByte
	ld [de], a
	inc e
	call IncPtr
	call ReadPtrByte
	ld [de], a
	call IncPtr
	call Music_LoadWave
	jp Music_ReadEvent

; $E0-$E5: octave = low nibble. $E6-$EF: see below. $F0 and above: Music_FlowCommand.
Music_Command:
	cp $f0
	jp nc, Music_FlowCommand
	cp $e6
	jp z, Cmd_Speed
	cp $e7
	jp z, Cmd_Ch3FadeOutOn
	cp $e8
	jp z, Cmd_Ch3FadesOff
	cp $e9
	jp z, Cmd_Ch3FadeInOn
	cp $ea
	jp z, Cmd_Transpose
	cp $eb
	jp z, Cmd_DropOn
	cp $ec
	jp z, Cmd_DropOff
	cp $ed
	jp z, Cmd_Ch3SfxPause
	cp $ee
	jp z, Cmd_Ch3SfxResume
	cp $ef
	jp z, Cmd_Poke
	push af
	ld a, l
	add a, $02
	ld e, a
	ld d, h
	pop af
	swap a
	and $f0
	ld b, a
	ld a, [de]
	and $0f
	or b
	ld [de], a
	jp Music_ReadEvent

; $E6 xx: speed = xx.
Cmd_Speed:
	ld a, l
	add a, $02
	ld e, a
	ld d, h
	call ReadPtrByte
	ld b, a
	ld a, [de]
	and $f0
	or b
	ld [de], a
	call IncPtr
	jp Music_ReadEvent

; $E7: ch3 fade-out on. $E8: both ch3 fades off. $E9: ch3 fade-in on.
Cmd_Ch3FadeOutOn:
	ld a, $01
	ld [wCh3FadeOut], a
	jp Music_ReadEvent

Cmd_Ch3FadesOff:
	ld a, $00
	ld [wCh3FadeOut], a
	ld [wCh3FadeIn], a
	ld [wCh3FadeInTimer], a
	jp Music_ReadEvent

Cmd_Ch3FadeInOn:
	ld a, $01
	ld [wCh3FadeIn], a
	jp Music_ReadEvent

; $EA xx: transpose = xx (signed, in semitones).
Cmd_Transpose:
	ld a, l
	add a, $04
	ld e, a
	ld d, h
	call ReadPtrByte
	ld [de], a
	call IncPtr
	jp Music_ReadEvent

; $EB / $EC: drop on / off. Unlike LA there is one flag (wDrop) for all channels.
Cmd_DropOn:
	ld a, $01
	ld [wDrop], a
	jp Music_ReadEvent

Cmd_DropOff:
	ld a, $00
	ld [wDrop], a
	jp Music_ReadEvent

; $ED / $EE: pause / resume the ch3 SFX.
Cmd_Ch3SfxPause:
	ld a, $01
	ld [wCh3SfxPaused], a
	jp Music_ReadEvent

Cmd_Ch3SfxResume:
	ld a, $00
	ld [wCh3SfxPaused], a
	jp Music_ReadEvent

; $EF xx yy: write xx to $C8yy.
Cmd_Poke:
	call ReadPtrByte
	push af
	call IncPtr
	call ReadPtrByte
	push af
	call IncPtr
	pop af
	ld e, a
	pop af
	ld d, h
	ld [de], a
	jp Music_ReadEvent

; $FB: mark. $FD xx yy: jump to yyxx. $FE xx: go back to the mark xx more times.
; Any other byte from $F0 up stops the music (Sound_Stop).
Music_FlowCommand:
	cp $fb
	jp z, Cmd_Mark
	cp $fd
	jp z, Cmd_Jump
	cp $fe
	jp z, Cmd_RepeatMark
	jp Sound_Stop

Cmd_Mark:
	ld a, l
	add a, $0c
	ld e, a
	ld d, h
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl]
	ld [de], a
	dec l
	jp Music_ReadEvent

; Only the low byte of the operand pointer is incremented (inc c): an operand straddling a
; 256-byte page would be read wrongly. None does.
Cmd_Jump:
	ld e, l
	ld d, h
	call ReadPtrByte
	ld [de], a
	inc e
	inc c
	ld a, [bc]
	and $7f
	ld [de], a
	jp Music_ReadEvent

Cmd_RepeatMark:
	ld a, l
	add a, $0f
	ld e, a
	ld d, h
	ld a, [de]
	and $7f
	jp z, .first
	dec a
	jp z, .done
	ld b, a
	ld a, [de]
	and $80
	or b
	ld [de], a
	jp .back

.done:
	call IncPtr
	jp Music_ReadEvent

.first:
	call ReadPtrByte
	ld b, a
	ld a, [de]
	or b
	ld [de], a
.back:
	dec e
	dec e
	dec e
	ld a, [de]
	ld [hl+], a
	inc e
	ld a, [de]
	ld [hl-], a
	jp Music_ReadEvent

; Music: four 16-byte channel structures at wCh1StreamPtr + $10*n.
Music_Play:
	ld hl, wSongPlaying
	ld a, [hl]
	and a
	ret z
	ld a, [wMusicDisabled]
	and a
	jp nz, Music_ClearRequests
	ld a, $01
	ld [wMusicChannel], a
	ld hl, wCh1StreamPtr
Music_ChannelLoop:
	inc hl
	ld a, [hl]
	and a
	jp z, Music_NextChannel
	inc l
	inc l
	ld a, [hl]
	or a
	jp nz, Music_Sustain
	dec l
	dec l
	dec l
; Note $00-$BF: high nibble = semitone, low nibble = length. NoteTable index =
; (5 - octave) * 12 + semitone + transpose (entry 1 = C2).
Music_ReadEvent:
	call ReadPtrByte
	push af
	call IncPtr
	pop af
	cp $c0
	jp nc, Cmd_Rest
	push hl
	push af
	and $0f
	call Music_SetLength
	ld a, l
	add a, $0b
	ld l, a
	ld [hl], $01
	pop af
	pop hl
	push hl
	and $f0
	swap a
	ld c, a
	ld b, $00
	ld a, l
	add a, $04
	ld l, a
	ld a, [hl]
	and a
	jp z, Music_Note_octave
	ld l, a
	ld h, $00
	bit 7, l
	jp z, Music_Note_addTranspose
	ld h, $ff
Music_Note_addTranspose:
	add hl, bc
	ld b, h
	ld c, l
Music_Note_octave:
	pop hl
	push hl
	ld a, l
	add a, $02
	ld l, a
	ld a, [hl]
	and $f0
	swap a
	ld e, a
	ld a, $05
	sub e
	ld e, a
	ld hl, $0000
Music_Note_octaveLoop:
	ld a, e
	or a
	jp z, Music_Note_lookup
	ld a, l
	add a, $0c
	ld l, a
	ld a, h
	adc a, $00
	ld h, a
	dec e
	jp Music_Note_octaveLoop

Music_Note_lookup:
	add hl, bc
	ld a, [wMusicChannel]
	cp $04
	jp z, Music_NoiseNote
	add hl, hl
	ld c, l
	ld b, h
	pop hl
	push hl
	ld a, l
	add a, $09
	ld e, a
	ld d, h
	ld hl, NoteTable
	add hl, bc
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, [hl]
	ld [de], a
	pop hl
; Write the note. A channel with Sounding = 0 (rest) gets NRx2 = $08.
Music_Trigger:
	ld a, [wMusicChannel]
	cp $01
	jp z, .ch1
	cp $02
	jp z, .ch2
	ld c, $1a
	ld a, [wCh3Flags]
	bit 7, a
	jp nz, .ch3
	ld a, [wCh3FadeOut]
	or a
	jp z, .fadeIn
	ld a, $01
	ld [wCh3FadeOut], a
	xor a
	ld [wCh3FadeOutTimer], a
.fadeIn:
	ld a, [wCh3FadeIn]
	or a
	jp z, .ch3Restart
	ld a, $01
	ld [wCh3FadeIn], a
	xor a
	ld [wCh3FadeInTimer], a
.ch3Restart:
	xor a
	ldh [c], a
	ld a, $80
	ldh [c], a
.ch3:
	inc c
	ld a, l
	add a, $08
	ld l, a
	ld a, [hl+]
	ld e, a
	ld d, $00
	push hl
	ld a, l
	add a, $02
	ld l, a
	ld a, [hl]
	pop hl
	or a
	jp nz, .write
	ld e, $08
	jp .write

.ch2:
	ld c, $16
	jp .readInstr

.ch1:
	ld c, $11
.readInstr:
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl+]
	ld e, a
	inc l
	push hl
	ld a, l
	add a, $03
	ld l, a
	ld a, [hl]
	pop hl
	or a
	jp nz, .duty
	ld e, $08
.duty:
	ld a, [hl+]
	ld d, a
	push hl
	ld a, l
	add a, $06
	ld l, a
	ld a, [hl]
	pop hl
	bit 7, a
	jp nz, .done
.write:
	ld a, d
	ldh [c], a
	inc c
	ld a, e
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	or $80
	ldh [c], a
.done:
	ld a, l
	and $f0
	ld l, a
Music_NextChannel:
	ld de, wMusicChannel
	ld a, [de]
	cp $04
	jp z, Music_NextChannel_allDone
	inc a
	ld [de], a
	ld a, l
	and $f0
	add a, $10
	ld l, a
	jp Music_ChannelLoop

; ch4: NoiseTable + 5 * index, 5 bytes: NR42, -, NR41, NR43, NR44.
Music_NoiseNote:
	ld de, wCh4InstrEnv
	ld b, h
	ld c, l
	add hl, hl
	add hl, hl
	add hl, bc
	ld b, h
	ld c, l
	ld hl, NoiseTable
	add hl, bc
.copy:
	ld a, [hl+]
	ld [de], a
	inc e
	ld a, e
	cp $4b
	jp nz, .copy
	ld c, $20
	pop hl
	jp Music_Trigger.readInstr

Music_NextChannel_allDone:
	ld hl, wCh1NoteFrames
	inc [hl]
	ld hl, wCh2NoteFrames
	inc [hl]
	ld hl, wCh3NoteFrames
	inc [hl]
	ret

; vibrato: 20 big-endian period offsets (LA's table)
VibratoTable:
	db $00, $00, $00, $00, $00, $01, $00, $01
	db $00, $02, $00, $02, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fe
	db $00, $00, $00, $01, $00, $02, $00, $01
	db $00, $00, $ff, $ff, $ff, $fe, $ff, $ff
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
	db $00, $00, $00, $00, $c0	; 0
	db $09, $00, $38, $34, $c0	; 1
	db $19, $00, $38, $33, $c0	; 2
	db $46, $00, $13, $10, $c0	; 3
	db $23, $00, $20, $40, $80	; 4
	db $51, $00, $20, $07, $80	; 5
	db $a1, $00, $00, $18, $80	; 6
	db $f2, $00, $00, $18, $80	; 7
	db $81, $00, $3a, $10, $c0	; 8
	db $80, $00, $00, $10, $c0	; 9
	db $57, $00, $00, $60, $80	; 10
	db $10, $00, $00, $10, $80	; 11
	db $01
; unreferenced: LA's length tables (the last one lacks its final byte)
Unused_LengthTables:
	db $02, $04, $08, $10, $20, $06, $0c, $18, $01, $01, $01, $01, $01, $30, $01
	db $03, $06, $0c, $18, $30, $09, $12, $24, $02, $04, $08, $01, $01, $48, $02
	db $04, $08, $10, $20, $40, $0c, $18, $30, $02, $05, $03, $01, $01, $60, $03
	db $05, $0a, $14, $28, $50, $0f, $1e, $3c, $02, $08, $10, $02, $01, $78, $03
	db $06, $0c, $18, $30, $60, $12, $24, $48, $03, $08, $10, $02, $04, $90, $03
	db $07, $0e, $1c, $38, $70, $15, $2a, $54, $04, $09, $12, $02, $01, $a8, $04
	db $08, $10, $20, $40, $80, $18, $30, $60, $04, $02, $01, $01, $00, $c0, $04
	db $09, $12, $24, $48, $90, $1b, $36, $6c, $05, $0c, $18, $18, $06, $d8, $05
	db $0a, $14, $28, $50, $a0, $1e, $3c, $78, $05, $01, $01, $01, $01, $f0
; Stop everything this bank controls (LA's Sound_Stop).
Sound_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wCh4Flags], a
	ld [wSfx4Step], a
	ld [wSfx4Timer], a
	ld [$c8c9], a
	ld [wSfx4Var], a
	ld [$c8e5], a
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
	ld [$c8c6], a
	ld [$c8c7], a
	ld [$c8c8], a
	ld [wSfx1Var], a
	ld [wSfxVar2], a
	ld [wSfx3Var], a
	ld [wCh3SfxPaused], a
	ld [$c8d6], a
	ld [$c8d7], a
	ld [$c8d8], a
	ld [$c8dc], a
	ld [wReloadWave], a
	ld [$c8e2], a
	ld [$c8e3], a
	ld [$c8e4], a
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

; 10 waves; INSTR on ch3 gives the byte offset ($00, $10, ... $90)
WaveTable:
	db $66, $66, $66, $66, $66, $66, $66, $66, $00, $00, $00, $00, $00, $00, $00, $00	; $00
	db $88, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; $10
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00	; $20
	db $88, $88, $88, $88, $00, $00, $00, $00, $88, $88, $88, $88, $00, $00, $00, $00	; $30
	db $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $00, $00, $00, $00, $00, $00, $00, $00	; $40
	db $06, $9b, $cd, $de, $ee, $ff, $ff, $fe, $06, $9b, $cd, $de, $ee, $ff, $ff, $fe	; $50
	db $7f, $ff, $57, $73, $55, $34, $42, $21, $7f, $ff, $57, $73, $55, $34, $42, $21	; $60
	db $33, $33, $33, $33, $00, $00, $00, $00, $33, $33, $33, $33, $00, $00, $00, $00	; $70
	db $11, $11, $11, $11, $00, $00, $00, $00, $11, $11, $11, $11, $00, $00, $00, $00	; $80
	db $44, $44, $44, $44, $00, $00, $00, $00, $44, $44, $44, $44, $00, $00, $00, $00	; $90
