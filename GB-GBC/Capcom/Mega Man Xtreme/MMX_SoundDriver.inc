;; Driver code and tables ($4000-$4B44).
;; INCLUDEd at $4000 in each of the three sound banks (2, 3, 4), which are
;; identical here. The bank's SndPointerTable follows at $4B45.

;; Entry points (the same in banks 2, 3 and 4)
SndJT_Update:
	jp SndUpdate
SndJT_Play:
	jp SndPlay

;; Multiply: HL = H * C
Multiply:
	ld l, $00
	ld b, $00
	ld a, $08
.loop:
	add hl, hl
	jr nc, .next
	add hl, bc
.next:
	dec a
	jr nz, .loop
	ret

;; JumpTable: call with A = index; the word table follows the call.
JumpTable:
	pop hl
	call GetTableWord
	jp hl

;; GetTableWord: HL = [HL + 2A]. GetWordAtOffset: HL = [HL + A].
GetTableWord:
	add a, a
GetWordAtOffset:
	push bc
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop bc
	ret

;; SndUpdate: once per frame from VBlank (skipped while an API call runs).
;; Per channel: SFX tick (if the SFX uses it), then music tick (unless paused).
;; Then NR50 (fade) and NR51 (panning of music/SFX).
SndUpdate:
	ld a, [wSndFlags]
	rrca
	ret c
	ld hl, wSfxPtr
	ld a, [hli]
	or a, [hl]
	call nz, SfxUpdate
	ld hl, wTempoFrac                       ; wTicks = hi(tempo) + carry of the fraction
	ld a, [wTempo]
	add a, [hl]
	ld [hli], a
	ld a, [wTempo+1]
	adc a, $00
	ld [hl], a
	ld de, wSfxChannel
	ld a, $40
	ld [wMusChanOfs], a
	xor a, a
.channel:
	ld [wSndChanReg], a
	ld hl, wSndFlags
	set 2, [hl]
	push hl
	ld hl, wSfxChannels
	rrc [hl]
	call c, SfxChannelTick
	pop hl
	res 2, [hl]
	bit 3, [hl]
	jr nz, .nextChannel
	push de
	ld a, [wMusChanOfs]
	ld d, $00
	ld e, a
	ld hl, wSfxChannel
	add hl, de
	ld d, h
	ld e, l
	ld hl, CHN_PTR
	add hl, de
	ld a, [hli]
	or a, [hl]
	call nz, MusicChannelTick
	pop de
.nextChannel:
	ld hl, CHN_PTR
	add hl, de
	ld d, h
	ld e, l
	ld a, [wMusChanOfs]
	add a, $1B
	ld [wMusChanOfs], a
	ld hl, wSfxPan
	rrc [hl]
	ld hl, wMusicPan
	rrc [hl]
	ld a, [wSndChanReg]
	add a, $05
	cp a, $14
	jr nz, .channel
	ld hl, wSfxPan
	swap [hl]
	ld hl, wMusicPan
	swap [hl]
	ld e, [hl]
	ld hl, wSfxChannels
	swap [hl]
	ld hl, wSndFlags
	res 0, [hl]
	jr nz, .fullVolume                      ; Z (from the swap above) = no SFX
	bit 3, [hl]
	ret nz
	ld hl, wFadeSpeed
	ld a, [hli]
	ld d, a
	and a, $7F
	jr nz, .fading
	rlc d
	jr nc, .fullVolume
	ld e, a                                 ; faded out completely: NR51 = 0
.fullVolume:
	ld a, $77                               ; SFX playing, no fade, or fade-in done: full volume
	jr .writeMaster
.fading:
	push af
	ld a, [hli]
	ld b, a
	ld c, [hl]
	pop af
	ld h, $00
	ld l, a
	add hl, hl
	add hl, hl
	add hl, bc
	ld a, l
	ld [wFadeLevel+1], a
	ld a, h
	jr nc, .setLevel
	ld a, [wFadeSpeed]
	and a, $80
	ld [wFadeSpeed], a
	ld a, $FF
.setLevel:
	ld [wFadeLevel], a
	rlc d
	jr nc, .level
	cpl
.level:
	srl a
	and a, $70
	ld b, a
	swap a
	or a, b
.writeMaster:
	ldh [rNR50], a
	ld a, e
	ldh [rNR51], a
	ret

;; SndPlay: A = sound id or command. Called through GamePlaySound.
SndPlay:
	ld hl, wSndFlags
	inc [hl]
	push hl
	call SndPlayID
	pop hl
	dec [hl]
	ret

;; Ids >= $F0 are commands. Other ids are taken modulo SndIDCount ($7E);
;; a zero pointer (sound not in this bank) is ignored.
SndPlayID:
	cp a, $F0
	jp nc, SndCommand
	ld hl, SndIDCount
.modulo:
	cp a, [hl]
	jr c, SndPlayIndex
	sub a, [hl]
	jr .modulo
SndPlayIndex:
	ld d, a
	ld hl, SndPointerTable
	call GetTableWord
	ld a, h
	ld h, l
	ld l, a
	or a, h
	ret z
	ld a, [hl]
	or a, a
	jr z, MusicStart
	inc hl
	ld b, h
	ld c, l
	ld e, a
	and a, $7F
	ld hl, wSfxPriority
	cp a, [hl]
	ret c                                   ; lower priority than the SFX playing: ignore
	ld [hl], a
	ld hl, wSndFlags
	jr nz, .loopFlag
	bit 7, [hl]                             ; equal priority replaces a looping SFX for good
	jr z, .loopFlag
	xor a, a
	ld [wSfxLoopID], a
.loopFlag:
	ld a, e
	and a, $80
	res 7, [hl]
	or a, [hl]
	ld [hl], a
	rlca
	jr nc, .start
	ld a, d                                 ; looping SFX: remember id+1
	inc a
	ld [wSfxLoopID], a
.start:
	ld hl, wSfxPtr
	ld a, c
	ld [hli], a
	ld [hl], b
	ld b, $07
	ld hl, wSfxFrames
	jr ClearSfxVars

;; MusicStart: HL = header (00, then 4 big-endian channel pointers).
;; A channel whose stream starts with END ($17) is left off.
MusicStart:
	push hl
	call SndCmdStopMusic
	pop hl
	ld de, wMusChannel
	ld a, $04
.channel:
	push af
	inc hl
	ld b, [hl]
	inc hl
	ld c, [hl]
	push hl
	ld a, [bc]
	cp a, $17
	jr z, .skip
	ld hl, CHN_PTR
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
.skip:
	ld hl, $001B
	add hl, de
	ld d, h
	ld e, l
	pop hl
	pop af
	dec a
	jr nz, .channel
	ret

;; Commands $F0-$F7: B (and C for fades) come from the caller.
SndCommand:
	and a, $07
	ld c, a
	call JumpTable

;; $F0 stop all, $F1 stop SFX, $F2 stop music, $F3 pause, $F4 resume,
;; $F5 fade in (B = speed), $F6 fade out (B = speed), $F7 pitch of a looping SFX (B)
SndCommandTable:
	dw SndCmdStopAll
	dw SndCmdStopSfx
	dw SndCmdStopMusic
	dw SndCmdPause
	dw SndCmdResume
	dw SndCmdFadeIn
	dw SndCmdFadeOut
	dw SndCmdSfxPitch
SndCmdStopAll:
	call SndCmdStopMusic
SndCmdStopSfx:
	ld hl, wSndFlags
	res 7, [hl]
	ld a, [wSfxChannels]
	or a, a
	call nz, SfxReleaseChannels
	ld b, $0D
	ld hl, wSfxChannels
ClearSfxVars:
	xor a, a
	ld [hli], a
	dec b
	jr nz, ClearSfxVars
	ld b, $40
	ld hl, wSfxChannel
.clearChannels:
	ld [hli], a
	dec b
	jr nz, .clearChannels
	ret

;; SfxReleaseChannels: A = channels the SFX gives back to the music.
SfxReleaseChannels:
	xor a, $0F
	ld [wSfxChannels], a
	jr SndResetChannels

;; SndCmdStopMusic: tempo $0199, no transpose/fade, clear the music channels.
SndCmdStopMusic:
	ld hl, wTempo
	ld a, $99
	ld [hli], a
	ld a, $01
	ld [hli], a
	xor a, a
	ld [hli], a
	inc hl
	dec a
	ld [hli], a
	xor a, a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld b, $6C
	ld hl, wMusChannel
.clear:
	ld [hli], a
	dec b
	jr nz, .clear
	jr SndResetChannels
SndCmdPause:
	ld hl, wSndFlags
	bit 3, [hl]
	ret nz
	set 3, [hl]
	jr SndResetChannels
SndCmdResume:
	ld hl, wSndFlags
	bit 3, [hl]
	ret z
	res 3, [hl]

;; SndResetChannels: first call turns the APU on. Then every channel
;; not used by the SFX is keyed off and its panning restored.
SndResetChannels:
	ld hl, wSndFlags
	bit 1, [hl]
	jr nz, .ready
	set 1, [hl]
	ld a, $80
	ldh [rNR52], a
	ld a, $08
	ldh [rNR10], a
	xor a, a
	ldh [rNR30], a
	ld a, $80
	ldh [rNR30], a
	ldh [rNR34], a
.ready:
	res 2, [hl]
	ld de, wMusChannel
	xor a, a
.channel:
	ld [wSndChanReg], a
	ld hl, wSfxChannels
	rrc [hl]
	call nc, ReleaseChannel
	ld hl, $001B
	add hl, de
	ld d, h
	ld e, l
	ld hl, wSfxPan
	rrc [hl]
	ld hl, wMusicPan
	rrc [hl]
	ld a, [wSndChanReg]
	add a, $05
	cp a, $14
	jr nz, .channel
	ld hl, wSfxChannels
	swap [hl]
	ld hl, wSfxPan
	swap [hl]
	ld hl, wMusicPan
	swap [hl]
	ret

;; ReleaseChannel: DE = music channel. Restore NRx1, panning and the CH3 wave,
;; then restart the music note at its current envelope level (silence if it has ended).
ReleaseChannel:
	ld a, [wSndChanReg]
	cp a, $0A
	jr nc, .pan
	ld hl, CHN_DUTY
	add hl, de
	ld b, [hl]
	call WriteNRx1
.pan:
	ld a, [wMusicPan]
	and a, $EE
	ld c, a
	ld a, [wSfxPan]
	and a, $11
	or a, c
	ld [wMusicPan], a
	ld hl, wSndFlags
	bit 3, [hl]
	jp nz, ChannelSilence
	ld hl, CHN_ENVPHASE
	add hl, de
	ld a, [hli]
	ld b, a
	ld a, [wSndChanReg]
	cp a, $0A
	jr z, .wave
	ld a, b
	or a, a
	jr z, .off
	ld a, [hli]
	ld [hli], a
	swap a
	or a, [hl]
	swap a
	dec b
	jr nz, .write
	set 3, a
.write:
	jp WriteEnvAndTrigger
.wave:
	push bc
	ld a, [wMusWaveInstr]
	or a, a
	call nz, LoadWave
	pop bc
	ld a, b
	or a, a
	jp nz, PlayNote.wave
.off:
	jp ChannelSilence
SndCmdFadeOut:
	set 7, b

;; Fades: B = speed (b7 set = fade out). A fade in the other direction
;; continues from the current level.
SndCmdFadeIn:
	ld hl, wFadeCmd
	ld a, b
	and a, $7F
	jr nz, .check
	ld b, a
	jr .set
.check:
	ld a, c
	cp a, [hl]
	ret z
.set:
	ld [hli], a
	ld c, [hl]
	ld a, b
	ld [hli], a
	ld a, c
	and a, $7F
	jr nz, .reverse
	ld [hli], a
	ld [hl], a
	ret
.reverse:
	ld a, [hl]
	xor a, $F0
	ld [hl], a
	ret

;; SndCmdSfxPitch: wSfxPitch = ~(B - 1)
SndCmdSfxPitch:
	ld a, b
	dec a
	cpl
	ld [wSfxPitch], a
	ret

;; SfxUpdate: count the segment down; at its end read the next segment.
;; Segment: pan (0 = end of SFX), flags (b0 loop, b1 hold, b2 transpose),
;; [count, hi, lo], [hold], [transpose], frames, channel mask, then
;; per channel: setting flags, settings, note.
SfxUpdate:
	ld a, [wSfxFrames]
	or a, a
	jr z, SfxReadSegment
	dec a
	ld [wSfxFrames], a
	ld hl, wSfxHoldTimer
	dec [hl]
	ret
SfxReadSegment:
	call SfxReadByte
	or a, a
	jr nz, .segment
	ld [wSfxPriority], a                    ; end of the SFX
	ld a, [wSfxLoopID]
	or a, a
	jp z, SndCmdStopSfx
	dec a                                   ; resume the looping SFX
	call SndPlayIndex
	jr SfxReadSegment
.segment:
	ld d, a
	call SfxReadByte
	ld e, a
	srl e
	jr nc, .hold
	call SfxReadByte
	or a, a
	jr z, .jump
	ld hl, wSfxLoopCount
	cp a, [hl]
	jr z, .loopDone
	inc [hl]
.jump:
	call SfxReadByte
	ld b, a
	call SfxReadByte
	ld hl, wSfxPtr
	ld [hli], a
	ld [hl], b
	jr SfxReadSegment
.loopDone:
	ld [hl], $00
	ld hl, wSfxPtr
	ld a, $02
	add a, [hl]
	ld [hli], a
	jr nc, .hold
	inc [hl]
.hold:
	srl e
	jr nc, .transpose
	call SfxReadByte
	ld [wSfxHold], a
.transpose:
	srl e
	jr nc, .duration
	call SfxReadByte
	ld [wSfxTranspose], a
.duration:
	call SfxReadByte
	ld [wSfxFrames], a
	ld h, a
	ld a, [wSfxHold]
	ld c, a
	call Multiply                           ; H = frames * hold / 256
	ld a, h
	inc a
	ld [wSfxHoldTimer], a
	ld hl, wSndFlags
	inc [hl]                                ; flag a new segment for the channel pass
	push de
	call SfxReadByte
	push af
	ld hl, wSfxChannels
	xor a, [hl]
	and a, [hl]
	call nz, SfxReleaseChannels             ; channels dropped by this segment go back to the music
	pop af
	ld [wSfxChannels], a
	pop de
	ld e, a
	swap a
	or a, e
	ld e, a
	ld a, d
	and a, e
	ld d, a
	ld a, e
	cpl
	ld hl, wMusicPan
	and a, [hl]
	or a, d
	ld [hl], a
	ret

;; SfxChannelTick: DE = SFX channel. On a new segment read its settings
;; and note; otherwise run envelope/vibrato and key off at the hold point.
SfxChannelTick:
	ld a, [de]
	or a, a
	call nz, SelectInstrument
	ld a, [wSndFlags]
	rrca
	jr c, SfxChannelSetup
	call EnvUpdate
	ld a, [wSfxFrames]
	or a, a
	ret z
	ld a, [wSndChanReg]
	cp a, $0A
	jr nz, .notWave
	ld hl, wSfxWaveHoldTimer
	dec [hl]
	jr .check
.notWave:
	ld a, [wSfxHoldTimer]
	or a, a
.check:
	ret nz
	ld hl, CHN_STATE
	add hl, de
	bit 0, [hl]
	ret nz
	jp KeyOff

;; SfxChannelSetup: setting flags b0 instrument, b1 duty, b2 volume,
;; b3 slide, b4 detune, then the note: 0 = key off, $FF = hold, else pitch.
SfxChannelSetup:
	ld c, $00
	call SfxReadByte
.flags:
	srl a
	jr nc, .nextFlag
	push af
	call SfxReadByte
	ld b, a
	push bc
	call SfxChannelSetting
	pop bc
	pop af
.nextFlag:
	jr z, SfxChannelNote
	inc c
	jr .flags
SfxChannelSetting:
	ld a, c
	call JumpTable
SfxSettingTable:
	dw ChCmdInstrument
	dw ChCmdDuty
	dw ChCmdVolume
	dw ChCmdSlide
	dw ChCmdDetune
SfxChannelNote:
	call SfxReadByte
	ld b, a
	ld hl, CHN_STATE
	add hl, de
	ld a, [hl]
	and a, $DE
	ld [hl], a
	push hl
	ld hl, CHN_SLIDE
	add hl, de
	ld a, [hli]
	sla a
	jr z, .note
	ld a, $55
	jr c, .slide
	ld a, $01
.slide:
	ld [hl], a
	ld hl, CHN_STATE
	add hl, de
	set 5, [hl]
.note:
	pop hl
	ld a, b
	dec a
	cp a, $FE
	jr c, .play
	set 0, [hl]
	jp nz, ChannelSilence
	bit 4, [hl]
	ret z
	jp ResetVibrato
.play:
	ld a, [wSndChanReg]
	cp a, $0A
	jr c, .transpose
	jr nz, .go
	push bc
	ld a, [wSfxFrames]
	ld h, a
	ld a, [wSfxWaveHold]
	ld c, a
	call Multiply
	ld a, h
	inc a
	ld [wSfxWaveHoldTimer], a
	pop bc
.transpose:
	ld a, [wSfxTranspose]
	add a, b
	cp a, $55
	jr c, .clamped
	ld a, $54
.clamped:
	ld b, a
.go:
	jp PlayNote

;; SfxReadByte: A = [wSfxPtr++]
SfxReadByte:
	ld hl, wSfxPtr
	jp ReadStreamByte

;; MusicChannelTick: DE = music channel (only when its stream pointer is set).
;; Envelope/vibrato, key-off at CHN_KEYOFF, next event when CHN_LENGTH runs out.
;; Both counters drop by wTicks per frame.
MusicChannelTick:
	ld hl, CHN_LENGTH
	add hl, de
	ld a, [hl]
	or a, a
	jr z, MusicReadEvent
	push hl
	ld a, [de]
	call SelectInstrument
	call EnvUpdate
	ld a, [wTicks]
	ld b, a
	ld hl, CHN_KEYOFF
	add hl, de
	ld a, [hl]
	sub a, b
	ld [hl], a
	jr z, .keyOff
	jr nc, .count
.keyOff:
	push bc
	ld hl, CHN_STATE
	add hl, de
	bit 0, [hl]
	call z, KeyOff
	pop bc
.count:
	pop hl
	ld a, [hl]
	sub a, b
	ld [hl], a
	jr z, MusicReadEvent
	jr c, MusicReadEvent
	cp a, $C1
	ret c

;; MusicReadEvent: $00-$19 commands, $20-$FF notes (b7-5 length, b4-0 pitch).
MusicReadEvent:
	call MusicReadByte
	cp a, $20
	jp c, MusicCommand
	push af
	swap a
	rrca
	and a, $07
	dec a
	push af
	ld hl, CHN_FLAGS
	add hl, de
	ld a, [hl]
	ld bc, NoteLengths                      ; normal lengths
	and a, $30
	jr z, .length
	ld bc, TripletLengths                   ; triplet
	bit 5, a
	jr nz, .length
	ld bc, DottedLengths                    ; dotted (one note only)
	res 4, [hl]
.length:
	pop af
	ld h, $00
	ld l, a
	add hl, bc
	ld a, [hl]
	ld hl, CHN_LENGTH
	add hl, de
	add a, [hl]
	ld [hl], a
	ld c, a
	pop af
	and a, $1F
	jr nz, .pitched
	ld hl, CHN_ENVPHASE                     ; rest: set the silent flag unless the envelope still runs
	add hl, de
	ld a, [hl]
	or a, a
	ret nz
	inc a
	jp SetSilentFlag
.pitched:
	push af
	ld hl, CHN_HOLD                         ; key-off point = length * HOLD / 256
	add hl, de
	ld h, [hl]
	call Multiply
	ld a, h
	ld hl, CHN_KEYOFF
	add hl, de
	ld [hl], a
	pop af
	ld b, a
	ld hl, CHN_FLAGS
	add hl, de
	ld a, [hl]
	and a, $0F
	ld c, a
	ld a, [wSndChanReg]
	cp a, $0F
	jr nz, .tone
	swap c                                  ; noise: pitch | octave << 4
	ld a, c
	or a, b
	ld b, a
	jr .play
.tone:
	ld a, c
	ld hl, OctaveOffsets
	call GetWordAtOffset                    ; pitch + OctaveOffsets[octave bits] + GTRANSP + TRANSP
	add a, b
	ld hl, wGlobalTranspose
	add a, [hl]
	ld hl, CHN_TRANSP
	add hl, de
	add a, [hl]
	cp a, $55
	jr c, .clamped
	ld a, $54
.clamped:
	ld b, a
	ld c, a
	ld hl, CHN_SLIDE
	add hl, de
	ld a, [hli]
	or a, a
	jr z, .storeNote
	ld a, [hl]
	or a, a
	jr z, .storeNote
	cp a, b
	jr nz, .slide
	xor a, a
	jr .storeNote
.slide:
	dec hl
	jr nc, .slideDown
	set 7, [hl]
	jr .slideOn
.slideDown:
	res 7, [hl]
.slideOn:
	ld a, $20
	inc hl
	ld b, [hl]
.storeNote:
	ld [hl], c
	ld hl, CHN_STATE
	add hl, de
	res 5, [hl]
	or a, [hl]
	ld [hl], a
.play:
	ld hl, CHN_FLAGS
	add hl, de
	push hl
	bit 7, [hl]                             ; connected note: no retrigger
	jr nz, .connected
	call PlayNote
	jr .flags
.connected:
	ld hl, CHN_STATE
	add hl, de
	bit 4, [hl]
	call nz, ResetVibrato
.flags:
	pop hl
	ld a, [hl]
	and a, $40
	rlca
	res 7, [hl]
	or a, [hl]
	ld [hl], a
	rlca
	and a, $01
SetSilentFlag:
	ld hl, CHN_STATE
	add hl, de
	res 0, [hl]
	or a, [hl]
	ld [hl], a
	ret

;; MusicCommand: commands $04+ read one argument into B first.
MusicCommand:
	ld hl, MusicReadEvent
	push hl
	cp a, $04
	jr c, .dispatch
	ld c, a
	call MusicReadByte
	ld b, a
	ld a, c
.dispatch:
	call JumpTable

;; Music commands $00-$19
MusicCmdTable:
	dw MusCmdTriplet
	dw MusCmdConnect
	dw MusCmdDotted
	dw MusCmdOctUp
	dw MusCmdFlags
	dw MusCmdTempo
	dw MusCmdHold
	dw ChCmdVolume
	dw ChCmdInstrument
	dw MusCmdOctave
	dw MusCmdGlobalTranspose
	dw MusCmdTranspose
	dw ChCmdDetune
	dw ChCmdSlide
	dw MusCmdLoop1
	dw MusCmdLoop2
	dw MusCmdLoop3
	dw MusCmdLoop4
	dw MusCmdLoop1
	dw MusCmdLoop2
	dw MusCmdLoop3
	dw MusCmdLoop4
	dw MusCmdJump
	dw MusCmdEnd
	dw ChCmdDuty
	dw MusCmdPan
MusCmdTriplet:
	ld a, $20
	jr ToggleFlag
MusCmdConnect:
	ld a, $40
	jr ToggleFlag
MusCmdOctUp:
	ld a, $08
ToggleFlag:
	ld hl, CHN_FLAGS
	add hl, de
	xor a, [hl]
	ld [hl], a
	ret
MusCmdDotted:
	ld hl, CHN_FLAGS
	add hl, de
	set 4, [hl]
	ret
MusCmdTempo:
	call MusicReadByte
	ld hl, wTempo
	ld [hli], a
	ld a, b
	ld [hli], a
	ld [hl], $00
	ret
MusCmdHold:
	ld hl, CHN_HOLD
	add hl, de
	ld [hl], b
	ret
MusCmdOctave:
	ld hl, CHN_FLAGS
	add hl, de
	ld a, [hl]
	and a, $F8
	or a, b
	ld [hl], a
	ret
MusCmdGlobalTranspose:
	ld hl, wGlobalTranspose
	ld [hl], b
	ret
MusCmdTranspose:
	ld hl, CHN_TRANSP
	add hl, de
	ld [hl], b
	ret
MusCmdLoop1:
	ld hl, $0017
	jr MusLoopCommon
MusCmdLoop2:
	ld hl, $0018
	jr MusLoopCommon
MusCmdLoop3:
	ld hl, $0017
	jr MusLoopCommon
MusCmdLoop4:
	ld hl, CHN_LOOP1

;; MusLoopCommon: C = command. LOOPn: count, hi, lo (count 0 = forever).
;; BREAKn: flags, hi, lo - jump and set CHN_FLAGS on the last pass.
;; LOOP3/LOOP4 and BREAK3/BREAK4 share LOOP1's counter (NES: separate).
MusLoopCommon:
	add hl, de
	ld a, c
	cp a, $12
	jr nc, .break
	ld a, [hl]
	or a, a
	jr nz, .count
	ld [hl], b
	jr .jump
.count:
	dec [hl]
	jr z, SkipAddress
	jr .jump
.break:
	ld a, [hl]
	dec a
	jr nz, SkipAddress
	ld [hl], a
	call MusCmdFlags
.jump:
	call MusicReadByte
	ld b, a
MusCmdJump:
	call MusicReadByte
	ld hl, CHN_PTR
	add hl, de
	ld [hli], a
	ld a, b
	ld [hl], b
	ret
SkipAddress:
	ld hl, CHN_PTR
	add hl, de
	ld a, $02
	add a, [hl]
	ld [hli], a
	ret nc
	inc [hl]
	ret
MusCmdFlags:
	ld hl, CHN_FLAGS
	add hl, de
	ld a, [hl]
	and a, $97
	or a, b
	ld [hl], a
	ret

;; MusCmdEnd: stop the channel (drops the return to MusicReadEvent).
MusCmdEnd:
	pop hl
	ld hl, CHN_PTR
	add hl, de
	xor a, a
	ld [hli], a
	ld [hl], a
	jp ChannelSilence

;; MusCmdPan: B = NR51 bits for this channel (b4 left, b0 right). GB addition.
MusCmdPan:
	ld a, [wSfxPan]
	and a, $EE
	or a, b
	ld [wSfxPan], a
	ld a, [wSfxChannels]
	rlca
	ret c
	ld a, [wMusicPan]
	and a, $EE
	or a, b
	ld [wMusicPan], a
	ret

;; MusicReadByte: A = [CHN_PTR++]
MusicReadByte:
	ld hl, CHN_PTR
	add hl, de
	jp ReadStreamByte

;; Note lengths in ticks, index = (byte >> 5) - 1
TripletLengths:
	db $02, $04, $08, $10, $20, $40, $80
NoteLengths:
	db $03, $06, $0C, $18, $30, $60, $C0
DottedLengths:
	db $00, $09, $12, $24, $48, $90, $00    ; index 0 and 6 give 0 (dotted 64th / whole do not work)

;; Pitch offset per octave (bits 3-0 of CHN_FLAGS; bit 3 = OCTUP adds 2 octaves)
OctaveOffsets:
	db $00, $0C, $18, $24, $30, $3C, $48, $54
	db $18, $24, $30, $3C, $48, $54, $60, $6C

;; PlayNote: B = pitch (1-84). Set the pitch, start the envelope
;; (attack from instrument byte 0) and trigger.
PlayNote:
	call CheckVibratoReset
	dec b
	ld a, [wSndChanReg]
	cp a, $0F
	jr nz, .tone
	xor a, a
	jr .setPitch
.tone:
	ld a, b
	ld hl, PitchTable
	call GetTableWord
	ld a, l
	ld b, h
.setPitch:
	ld hl, CHN_PITCH
	add hl, de
	ld [hli], a
	ld [hl], b
	ld c, a
	call PitchToPeriod
	ld a, [wSndChanReg]
	cp a, $0A
	jr nz, .attack
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], $03
.wave:
	ld hl, CHN_VOLUME
	add hl, de
	ld a, [hl]
	jp WriteEnvAndTrigger
.attack:
	ld a, $00
	call GetInstrumentByte
	ld hl, EnvRateTable
	call GetWordAtOffset                    ; attack rate -> NRx2 value
	or a, a
	jp z, ChannelSilence
	cp a, $FF
	jr nz, EnvStartAttack
	ld a, $01
	call GetInstrumentByte
	dec a
	cpl
	and a, $07
	jr nz, EnvStartDecay.decay
	ld a, $02
	call GetInstrumentByte
	ld hl, CHN_VOLUME
	add hl, de
	cp a, [hl]
	jr z, EnvStartSustain
	ld a, [hl]
	swap a

;; Envelope phases are made from the hardware envelope: each phase writes
;; NRx2 (and retriggers); CHN_ENVLEVEL tracks the volume in software so the
;; driver knows when to switch to the next phase.
EnvStartAttack:
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], $01
	inc hl
	ld b, a
	and a, $07
	ld [hli], a
	ld [hli], a
	ld a, b
	swap a
	and a, $0F
	ld [hl], a
	ld a, b
	jp WriteEnvAndTrigger
EnvStartDecay:
	ld a, $01
	call GetInstrumentByte
	dec a
	cpl
	and a, $07
	jr z, EnvStartSustain
.decay:
	ld b, a
	ld a, $02
	call GetInstrumentByte
	ld hl, CHN_VOLUME
	add hl, de
	cp a, [hl]
	jr z, EnvStartSustain
	ld a, b
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], $02
	inc hl
	ld [hli], a
	ld [hli], a
	ld b, a
	inc hl
	ld a, [hld]
	ld [hl], a
	swap a
	or a, b
	jr WriteEnvAndTrigger
EnvStartSustain:
	ld a, $02
	call GetInstrumentByte
	or a, a
	jp z, ChannelSilence
	ld hl, CHN_ENVLEVEL
	add hl, de
	ld [hl], a
EnvSetSustain:
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], $03
	inc hl
	ld [hl], $00
	swap a
	jr WriteEnvAndTrigger

;; KeyOff: start the release (instrument byte 3). CH3 is silenced.
KeyOff:
	ld a, [wSndChanReg]
	cp a, $0A
	jp z, ChannelSilence
	ld hl, CHN_ENVPHASE
	add hl, de
	ld a, [hl]
	or a, a
	ret z
	ld b, a
	ld a, $03
	call GetInstrumentByte
	bit 3, a
	jp nz, ChannelSilence
	or a, a
	jr nz, .release
	ld a, b
	cp a, $03
	ret z
	ld hl, CHN_ENVLEVEL
	add hl, de
	ld a, [hl]
	jr EnvSetSustain
.release:
	dec a
	cpl
	and a, $07
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], $04
	inc hl
	ld [hli], a
	ld [hli], a
	ld b, a
	ld a, [hl]
	swap a
	or a, b

;; WriteEnvAndTrigger: A = NRx2 (CH3: NR32). Skipped when the SFX owns the channel
;; or the music is faded out.
WriteEnvAndTrigger:
	ld b, a
	ld hl, wSndFlags
	bit 2, [hl]
	jr nz, .write
	ld hl, wSfxChannels
	bit 7, [hl]
	ret nz
	ld a, [wFadeSpeed]
	cp a, $80
	ret z
.write:
	ld a, [wSndChanReg]
	cp a, $0A
	jr z, .wave
	ld hl, CHN_FREQ
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld c, $12
	call WriteChannelReg
	inc c
	ld a, l
	ldh [c], a
	inc c
	set 7, h
	ld a, h
	ldh [c], a
	ret
.wave:
	ld a, b
	ldh [rNR32], a
	jp WriteFreqNoTrigger

;; CheckVibratoReset: instrument byte 4 bit 7 = reset the vibrato phase on each note
CheckVibratoReset:
	ld a, $04
	call GetInstrumentByte
	ld hl, CHN_STATE
	add hl, de
	rlca
	jr c, ResetVibrato
	bit 4, [hl]
	ret z
ResetVibrato:
	ld a, [hl]
	and a, $2F
	ld [hli], a
	ld [hl], $00
	ret

;; PitchToPeriod: BC = pitch (PitchTable units, +wSfxPitch for looping SFX).
;; High bits = octave, low bits = mantissa: shift right by octave and negate
;; to get the 11-bit period, then add CHN_DETUNE. CH4: NR43 from the pitch.
PitchToPeriod:
	ld a, [wSndFlags]
	bit 2, a
	jr z, .convert
	rlca
	jr nc, .convert
	ld a, [wSfxPitch]
	or a, a
	jr z, .convert
	push bc
	ld h, a
	ld c, b
	call Multiply
	pop bc
	ld b, $00
	add hl, bc
	ld b, h
	ld c, l
.convert:
	ld a, [wSndChanReg]
	cp a, $0F
	jr nz, .tone
	ld a, b
	and a, $7F
	xor a, $0F
	swap a
	ld hl, CHN_DUTY
	add hl, de
	or a, [hl]
	ld b, $00
	jr .store
.tone:
	ld a, b
	ld b, $24
	ld hl, OctaveThresholds
.findOctave:
	cp a, [hl]
	jr nc, .found
	inc hl
	dec b
	dec b
	dec b
	dec b
	jr .findOctave
.found:
	srl a
	rr c
	add a, b
	push af
	and a, $07
	ld b, a
	pop af
	and a, $38
	xor a, $38
	jr z, .negate
.shift:
	srl b
	rr c
	sub a, $08
	jr nz, .shift
.negate:
	sub a, c
	ld c, a
	ld a, $80
	sbc a, b
	and a, $07
	ld b, a
	ld hl, CHN_DETUNE
	add hl, de
	ld l, [hl]
	ld h, $00
	bit 7, l
	jr z, .detune
	dec h
.detune:
	add hl, bc
	ld a, l
	ld b, h
.store:
	ld hl, CHN_FREQ
	add hl, de
	ld [hli], a
	ld [hl], b
	ret

;; Commands shared by music and SFX: B = argument, DE = channel.
ChCmdVolume:
	ld a, [wSndChanReg]
	cp a, $0A
	jr nz, .store
	ld hl, wSndFlags
	bit 2, [hl]
	jr z, .waveVolume
	ld a, b
	ld [wSfxWaveHold], a
	ret
.waveVolume:
	ld a, b
	swap a
	rlca
	dec a
	cpl
	and a, $60
	ld b, a
.store:
	ld hl, CHN_VOLUME
	add hl, de
	ld [hl], b
	ret

;; ChCmdInstrument: store n+1. CH1/2/4: instrument byte 6 -> CHN_DUTY.
;; CH3: instrument byte 7 = wave number (0 = keep).
ChCmdInstrument:
	ld a, b
	inc a
	ld l, e
	ld h, d
	cp a, [hl]
	ret z
	ld [hli], a
	set 4, [hl]
	call SelectInstrument
	ld a, [wSndChanReg]
	cp a, $0A
	ret c
	jr z, .wave
	ld bc, $0006
	add hl, bc
	ld a, [hl]
	ld hl, CHN_DUTY
	add hl, de
	ld [hl], a
	ret
.wave:
	ld bc, $0007
	add hl, bc
	ld a, [hl]
	or a, a
	ret z
	ld hl, wSndFlags
	bit 2, [hl]
	jr nz, LoadWave
	ld [wMusWaveInstr], a
	ld hl, wSfxChannels
	bit 7, [hl]
	ret nz

;; LoadWave: A = wave number (1-based). Copies 16 bytes to wave RAM and retriggers CH3.
LoadWave:
	dec a
	ld h, $00
	ld l, a
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	push hl
	ld hl, $4B43
	ld a, [hli]
	ld c, [hl]
	ld b, a
	pop hl
	add hl, bc
	xor a, a
	ldh [rNR30], a
	ld b, $10
	ld c, $30
.copy:
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copy
	ld a, $80
	ldh [rNR30], a
	ld hl, CHN_FREQ_HI
	add hl, de
	or a, [hl]
	ldh [rNR34], a
	ret

;; SelectInstrument: A = instrument + 1 -> wSndInstPtr
SelectInstrument:
	dec a
	ld h, $00
	ld l, a
	add hl, hl
	add hl, hl
	add hl, hl
	push hl
	ld hl, $4B41
	ld a, [hli]
	ld c, [hl]
	ld b, a
	pop hl
	add hl, bc
	ld a, l
	ld [wSndInstPtr], a
	ld a, h
	ld [wSndInstPtr+1], a
	ret
ChCmdDetune:
	ld hl, CHN_DETUNE
	add hl, de
	ld [hl], b
	ret
ChCmdSlide:
	ld hl, CHN_SLIDE
	add hl, de
	ld [hl], b
	ret
ChCmdDuty:
	ld a, [wSndChanReg]
	cp a, $0A
	jr c, .tone
	ret nz
	ld hl, wSndFlags
	bit 2, [hl]
	ret z
	jp ChCmdVolume.waveVolume
.tone:
	ld hl, wSndFlags
	bit 2, [hl]
	jr nz, WriteNRx1
	ld hl, CHN_DUTY
	add hl, de
	ld [hl], b
	ld hl, wSfxChannels
	bit 7, [hl]
	ret nz
WriteNRx1:
	ld c, $11
WriteChannelReg:
	ld a, [wSndChanReg]
	add a, c
	ld c, a
	ld a, b
	ldh [c], a
	ret

;; GetInstrumentByte: A = byte A of the current instrument. Byte 2 (sustain)
;; is returned as sustain/16 - (15 - CHN_VOLUME), minimum 0.
GetInstrumentByte:
	push af
	ld hl, wSndInstPtr
	add a, [hl]
	inc hl
	ld h, [hl]
	jr nc, .got
	inc h
.got:
	ld l, a
	pop af
	cp a, $02
	jr z, .sustain
	ld a, [hl]
	ret
.sustain:
	ld a, [hl]
	swap a
	push af
	ld hl, CHN_VOLUME
	add hl, de
	ld a, $0F
	sub a, [hl]
	ld l, a
	pop af
	sub a, l
	ret nc
	xor a, a
	ret

;; ReadStreamByte: HL = pointer variable. A = [ptr], ptr++
ReadStreamByte:
	push hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hl]
	pop hl
	inc [hl]
	ret nz
	inc hl
	inc [hl]
	ret

;; Attack rate -> NRx2 (start volume/step); $FF = no attack
EnvRateTable:
	db $00, $0F, $0E, $0D, $0C, $0B, $1B, $1B, $0A, $1A, $2A, $2A, $2A, $09, $09, $09
	db $19, $19, $29, $29, $29, $39, $39, $49, $49, $49, $59, $59, $69, $69, $FF, $FF

;; Pitch thresholds for PitchToPeriod
OctaveThresholds:
	db $30, $28, $20, $18, $10, $08, $00

;; Pitch per note (84 notes, C2-B8), logarithmic: +$0800 per octave down
PitchTable:
	dw $37AA             ;  1 C_2
	dw $36C8             ;  2 C#2
	dw $35F4             ;  3 D_2
	dw $352C             ;  4 D#2
	dw $346E             ;  5 E_2
	dw $33BC             ;  6 F_2
	dw $3312             ;  7 F#2
	dw $3274             ;  8 G_2
	dw $31DE             ;  9 G#2
	dw $3150             ; 10 A_2
	dw $30CA             ; 11 A#2
	dw $304C             ; 12 B_2
	dw $2FAA             ; 13 C_3
	dw $2EC8             ; 14 C#3
	dw $2DF4             ; 15 D_3
	dw $2D2C             ; 16 D#3
	dw $2C6E             ; 17 E_3
	dw $2BBC             ; 18 F_3
	dw $2B12             ; 19 F#3
	dw $2A74             ; 20 G_3
	dw $29DE             ; 21 G#3
	dw $2950             ; 22 A_3
	dw $28CA             ; 23 A#3
	dw $284C             ; 24 B_3
	dw $27AA             ; 25 C_4
	dw $26C8             ; 26 C#4
	dw $25F4             ; 27 D_4
	dw $252C             ; 28 D#4
	dw $246E             ; 29 E_4
	dw $23BC             ; 30 F_4
	dw $2312             ; 31 F#4
	dw $2274             ; 32 G_4
	dw $21DE             ; 33 G#4
	dw $2150             ; 34 A_4
	dw $20CA             ; 35 A#4
	dw $204C             ; 36 B_4
	dw $1FAA             ; 37 C_5
	dw $1EC8             ; 38 C#5
	dw $1DF4             ; 39 D_5
	dw $1D2C             ; 40 D#5
	dw $1C6E             ; 41 E_5
	dw $1BBC             ; 42 F_5
	dw $1B12             ; 43 F#5
	dw $1A74             ; 44 G_5
	dw $19DE             ; 45 G#5
	dw $1950             ; 46 A_5
	dw $18CA             ; 47 A#5
	dw $184C             ; 48 B_5
	dw $17AA             ; 49 C_6
	dw $16C8             ; 50 C#6
	dw $15F4             ; 51 D_6
	dw $152C             ; 52 D#6
	dw $146E             ; 53 E_6
	dw $13BC             ; 54 F_6
	dw $1312             ; 55 F#6
	dw $1274             ; 56 G_6
	dw $11DE             ; 57 G#6
	dw $1150             ; 58 A_6
	dw $10CA             ; 59 A#6
	dw $104C             ; 60 B_6
	dw $0FAA             ; 61 C_7
	dw $0EC8             ; 62 C#7
	dw $0DF4             ; 63 D_7
	dw $0D2C             ; 64 D#7
	dw $0C6E             ; 65 E_7
	dw $0BBC             ; 66 F_7
	dw $0B12             ; 67 F#7
	dw $0A74             ; 68 G_7
	dw $09DE             ; 69 G#7
	dw $0950             ; 70 A_7
	dw $08CA             ; 71 A#7
	dw $084C             ; 72 B_7
	dw $07AA             ; 73 C_8
	dw $06C8             ; 74 C#8
	dw $05F4             ; 75 D_8
	dw $052C             ; 76 D#8
	dw $046E             ; 77 E_8
	dw $03BC             ; 78 F_8
	dw $0312             ; 79 F#8
	dw $0274             ; 80 G_8
	dw $01DE             ; 81 G#8
	dw $0150             ; 82 A_8
	dw $00CA             ; 83 A#8
	dw $004C             ; 84 B_8

;; EnvUpdate: run the envelope phase, then vibrato and slide.
EnvUpdate:
	ld hl, CHN_ENVPHASE
	add hl, de
	ld a, [hl]
	call JumpTable
EnvPhaseTable:
	dw VibratoStep
	dw EnvPhaseAttack
	dw EnvPhaseDecay
	dw VibratoAndSlide
	dw EnvPhaseRelease
EnvPhaseAttack:
	ld hl, CHN_ENVRATE
	add hl, de
	ld a, [hli]
	or a, a
	jr z, EnvPhaseDecay.sustain
	dec [hl]
	jr nz, VibratoAndSlide
	ld [hli], a
	inc [hl]
	inc hl
	ld a, [hld]
	cp a, [hl]
	jr nc, VibratoAndSlide
	call EnvStartDecay
	jr VibratoAndSlide
EnvPhaseDecay:
	ld hl, CHN_ENVRATE
	add hl, de
	ld a, [hli]
	dec [hl]
	jr nz, VibratoAndSlide
	ld [hli], a
	dec [hl]
	push hl
	ld a, $02
	call GetInstrumentByte
	pop hl
	cp a, [hl]
	jr nz, VibratoAndSlide
.sustain:
	call EnvStartSustain
	jr VibratoAndSlide
EnvPhaseRelease:
	ld hl, CHN_ENVRATE
	add hl, de
	ld a, [hli]
	dec [hl]
	jr nz, VibratoAndSlide
	ld [hli], a
	dec [hl]
	jr nz, VibratoAndSlide
	jr EnvOff

;; ChannelSilence: NRx2 = $08 (CH3: NR32 = 0), envelope off.
ChannelSilence:
	ld b, $08
	ld a, [wSndChanReg]
	cp a, $0A
	jr nz, .write
	ld b, $00
.write:
	ld a, b
	call WriteEnvAndTrigger
EnvOff:
	xor a, a
	ld hl, CHN_ENVPHASE
	add hl, de
	ld [hl], a
	ret

;; VibratoAndSlide: vibrato depth = instrument byte 5 (b7 = centered),
;; then the slide towards the note in CHN_SLIDENOTE.
VibratoAndSlide:
	call VibratoStep
	ld a, $05
	call GetInstrumentByte
	or a, a
	jr z, .noVibrato
	ld c, a
	ld hl, CHN_VIBPHASE
	add hl, de
	ld a, [hld]
	bit 6, [hl]
	jr z, .depth
	cpl
.depth:
	or a, a
	jr z, .noVibrato
	ld h, a
	call Multiply
	ld b, $05
.scale:
	ld a, h
	or a, l
	jr z, .noVibrato
	srl h
	rr l
	dec b
	jr nz, .scale
	ld b, h
	ld c, l
	ld hl, CHN_STATE
	add hl, de
	bit 7, [hl]
	jr z, .slide
	xor a, a
	sub a, c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
	jr .slide
.noVibrato:
	ld bc, $0000
	ld hl, CHN_STATE
	add hl, de
.slide:
	bit 5, [hl]
	jr nz, .doSlide
	ld a, b
	or a, c
	jr nz, .apply
	ld a, [wSndFlags]
	bit 2, a
	ret z
	rlca
	ret nc
	ld a, [wSfxPitch]
	or a, a
	ret z
	jr .apply
.doSlide:
	push bc
	push de
	ld hl, CHN_PITCH
	add hl, de
	ld a, [hli]
	ld b, [hl]
	ld c, a
	ld hl, CHN_SLIDE
	add hl, de
	ld a, [hl]
	sla a
	push af
	ld h, $00
	jr nc, .add
	dec h
	dec a
	cpl
.add:
	ld l, a
	add hl, bc
	ld a, [wSndChanReg]
	cp a, $0F
	jr nz, .checkTarget
	pop af
	pop de
	jr .keep
.checkTarget:
	push hl
	ld hl, CHN_SLIDENOTE
	add hl, de
	ld a, [hl]
	dec a
	ld hl, PitchTable
	call GetTableWord
	ld b, h
	ld c, l
	pop hl
	ld a, l
	sub a, c
	ld a, h
	sbc a, b
	ld a, $FF
	adc a, $00
	ld e, a
	pop af
	ld a, e
	adc a, $00
	pop de
	jr z, .keep
	ld hl, CHN_STATE
	add hl, de
	res 5, [hl]
	jr .store
.keep:
	ld b, h
	ld c, l
.store:
	ld hl, CHN_PITCH
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
.apply:
	ld hl, CHN_PITCH
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld b, h
	ld c, l
	call PitchToPeriod
	ld hl, wSndFlags
	bit 2, [hl]
	jr nz, WriteFreqNoTrigger
	ld a, [wSfxChannels]
	rlca
	ret c

;; WriteFreqNoTrigger: NRx3/NRx4 from CHN_FREQ, NRx1 length bits cleared.
WriteFreqNoTrigger:
	ld hl, CHN_FREQ
	add hl, de
	ld a, [hli]
	ld b, a
	ld c, $13
	call WriteChannelReg
	inc c
	ld a, [hl]
	ldh [c], a
	dec c
	dec c
	dec c
	ldh a, [c]
	and a, $C0
	ldh [c], a
	ret

;; VibratoStep: phase += speed (instrument byte 4, b6-0)
VibratoStep:
	ld a, $04
	call GetInstrumentByte
	and a, $7F
	ret z
	ld hl, CHN_VIBPHASE
	add hl, de
	add a, [hl]
	ld [hld], a
	ret nc
	ld a, $40
	add a, [hl]
	ld [hl], a
	ret

;; Seven bytes nothing reads
UnusedBytes:
	db $10, $83, $7E, $F6, $00, $74, $0A

;; Data header: id count, instrument and wave table pointers (big-endian)
SndIDCount:
	db NUM_SOUND_IDS
SndInstPtr:
	db HIGH(SoundInstruments), LOW(SoundInstruments)
SndWavePtr:
	db HIGH(SoundWaves), LOW(SoundWaves)
