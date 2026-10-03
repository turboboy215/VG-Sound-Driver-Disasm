; =============================================================================
; Keitai Keiba 8 Special (J) - C-lab sound engine disassembly
;
; Rebuilds the complete ROM byte-for-byte:
;     rgbasm -o keiba.o keiba_sound.asm
;     rgblink -o keiba.gb keiba.o
; Everything that is not part of the sound engine is INCBIN'd from the
; original ROM, which must be in the parent directory.
;
; Engine code, tables, SFX and music data: bank 0, $1D8C-$3C5E
; The VBlank handler calls Sound_Update every frame (unless hFF9C != 0); SFX
; are requested by writing an id to wSndSFXRequest.
; Function comments are shared with rampart_sound.asm; differences between
; the two versions are noted where they occur (KK8S = this game).
; See C-lab_Sound_Engine.md for the documentation of the engine and format.
; =============================================================================

DEF SND_RAM EQU $C500
INCLUDE "clab_sound.inc"

DEF BASEROM EQUS "\"../Keitai Keiba 8 Special (J).gb\""

SECTION "ROM0 before sound engine", ROM0[$0000]
	INCBIN BASEROM, $0000, $1D8C

SECTION "Sound engine", ROM0[$1D8C]

; -----------------------------------------------------------------------------
; Sound_Init
; Resets the whole engine: copies DefaultWave into wave RAM (inline - unlike
; Rampart there is no Sound_LoadWave and the ch3 DAC is not switched off
; while writing), clears the work RAM, copies the register-address table,
; sets tempo 64 (1 tick/frame), turns the APU on (NR52 = $8F, NR50 = $77) and
; mutes all outputs (NR51 = 0).  wSndStatus = 0 afterwards.
; Differences to Rampart: no wSndSavedNR51 default.
; -----------------------------------------------------------------------------
Sound_Init::
	ld hl, DefaultWave
	ld de, _AUD3WAVERAM
	ld b, $10
.copyWave
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, .copyWave
	xor a                                  ; clear SND_RAM+2 .. SND_RAM+$D1
	ld b, SND_RAM_CLEAR_SIZE
	ld hl, wSndSFXRequest
.clearRAM
	ld [hl+], a
	dec b
	jr nz, .clearRAM
	ld hl, SoundRegTable                   ; wSndRegNRx2/3/4 = low bytes of the
	ld de, wSndRegNRx2                     ; NRx2/NRx3/NRx4 register addresses
	ld b, $0C
.copyRegTable
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, .copyRegTable
	ld a, $40                              ; tempo 64 = exactly one tick per frame
	ld [wSndTempo], a
	call Sound_ClearTranspose              ; returns a = 0
	ld [wSndTempoAccum], a
	ld [wSndStoppedMask], a
	ld [wSndLoopWaitMask], a
	ld [wSndSyncWaitMask], a
	ld a, $77
	ldh [rNR50], a
	ld a, $8F                              ; APU on
	ldh [rNR52], a
	ld a, $80                              ; ch3 DAC on
	ldh [rNR30], a
	xor a
	ld [wSndStatus], a
	ld [wSndSFXActiveMask], a
	ld [wSndSFXRequest], a
	ld [wSndSFXPriority], a
	ld [wSndSFXUsedMask], a
	ldh [rNR51], a                         ; all channels muted until a song starts
	ret

; -----------------------------------------------------------------------------
; Sound_MusicFinished
; Reached from Sound_MusicTick when every music track has executed
; stop_track ($1C).  Clears bit 0 (music running) and bits 4-7 of wSndStatus;
; bits 1-3 stay set, so SFX processing continues.
; -----------------------------------------------------------------------------
Sound_MusicFinished::
	ld a, [wSndStatus]
	and $0E
	ld [wSndStatus], a
	ret

; -----------------------------------------------------------------------------
; Sound_PlaySong  (public entry point)
; In: a = song number * 2 (index into SongTable).
; All sound data is in bank 0, so there is no bank switching and (unlike
; Rampart) no "music off" option check.  Resets the engine (cuts SFX too)
; and starts the song.
; -----------------------------------------------------------------------------
Sound_PlaySong::
	ld hl, SongTable
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hl+]
	ld [wSndSongPtr], a
	ld a, [hl]
	ld [wSndSongPtr+1], a
	jp Sound_InitSong

; -----------------------------------------------------------------------------
; Sound_StopSFXPulse1  (KK8S only)
; Releases channel 1 from a running SFX and silences it (NR12 = $08: volume 0,
; DAC stays on; NR14 = $80 retrigger), then clears wSndSFXPriority.  Called
; once from bank 7.  Storing $30 in wSndTimbre+4 has no effect.
; -----------------------------------------------------------------------------
Sound_StopSFXPulse1::
	ld a, [wSndSFXActiveMask]
	and $EE                                ; channel 1 no longer owned by an SFX
	ld [wSndSFXActiveMask], a
	ld a, $30
	ld [wSndTimbre+4], a
	ld a, $08                              ; volume 0, DAC on
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	jr Sound_StopSFXNoise.clearPriority

; -----------------------------------------------------------------------------
; Sound_StopSFXNoise  (KK8S only, unused)
; Same for channel 4.  BUG: the $08 meant for NR42 is written to NR41 (length),
; so the noise channel is not actually silenced.
; -----------------------------------------------------------------------------
Sound_StopSFXNoise::
	ld a, [wSndSFXActiveMask]
	and $77                                ; channel 4 no longer owned by an SFX
	ld [wSndSFXActiveMask], a
	ld a, $30
	ld [wSndTimbre+7], a
	ld a, $08
	ldh [rNR41], a                         ; BUG: should be rNR42
	ld a, $80
	ldh [rNR44], a
.clearPriority
	xor a
	ld [wSndSFXPriority], a                ; no SFX running
	ret

; -----------------------------------------------------------------------------
; Sound_ResetAndResume  (unused)
; Sound_Init followed by Sound_Resume.  Not referenced anywhere.
; -----------------------------------------------------------------------------
Sound_ResetAndResume::
	call Sound_Init
	jp Sound_Resume

; -----------------------------------------------------------------------------
; Sound_InitSong
; Full engine reset, then per-channel defaults for the four music tracks,
; then loads the track pointers from the song header and starts playback.
; -----------------------------------------------------------------------------
Sound_InitSong::
	call Sound_Init
	ld a, $03                              ; music tracks 3..0
.channelLoop
	ld [wSndHWChan], a
	ld e, a
	ld d, $00
	ld a, $FF                              ; default envelope $FF
	ld hl, wSndEnvelope
	add hl, de
	ld [hl], a
	xor a                                  ; call/loop depth, loop counter,
	ld l, LOW(wSndStackDepth)
	add hl, de
	ld [hl], a
	ld l, LOW(wSndLoopCounter)
	add hl, de
	ld [hl], a
	ld l, LOW(wSndDurationTimer)           ; duration, gate and timbre = 0
	add hl, de
	ld [hl], a
	ld l, LOW(wSndGateInit)
	add hl, de
	ld [hl], a
	ld l, LOW(wSndTimbre)
	add hl, de
	xor a
	ld [hl], a
	ld a, [wSndHWChan]
	dec a
	bit 7, a                               ; until track -1
	jr z, .channelLoop
	xor a
	ld [wSndStoppedMask], a
	call Sound_LoadSongHeader              ; read song header

; -----------------------------------------------------------------------------
; Sound_Resume
; Music + SFX on and all channels routed to both speakers (NR51 = $FF).
; Only used as the tail of Sound_InitSong; KK8S has no pause handling.
; -----------------------------------------------------------------------------
Sound_Resume::
	ld a, $FF                              ; music running, SFX enabled
	ldh [rNR51], a
	ld [wSndStatus], a
.ret
	ret

; -----------------------------------------------------------------------------
; Sound_Update  (called once per frame from the VBlank handler)
; 1. Sound_UpdateSFX runs exactly once per frame.
; 2. If music is running, the tempo accumulator decides how many music ticks
;    (0-4) to run this frame:  ticks = (accum + tempo) >> 6,  accum = the low
;    6 bits of the sum.  Tempo 64 = 1 tick/frame (~59.7 ticks per second).
; -----------------------------------------------------------------------------
Sound_Update::
	ld a, [wSndStatus]
	and a                                  ; engine completely idle?
	jr z, Sound_Resume.ret
	call Sound_UpdateSFX
	ld a, [wSndStatus]
	srl a                                  ; bit 0: music running?
	jr nc, .done
	ld a, [wSndTempo]
	ld b, a
	ld a, [wSndTempoAccum]
	add b
	ld b, a
	and $3F                                ; keep the 6-bit fraction
	ld [wSndTempoAccum], a
	ld a, b                                ; bits 6-7 of the sum plus the carry
	rl a
	rl a
	rl a
	and $07                                ; = number of ticks this frame
	ld [wSndTicksThisFrame], a
	jr z, .done
.tickLoop
	call Sound_MusicTick
	ld hl, wSndTicksThisFrame
	dec [hl]
	jr nz, .tickLoop
.done
	ret

; -----------------------------------------------------------------------------
; Sound_UpdateSFX
; Part 1 - start a requested effect.  The game writes an SFX id (a multiple
; of 3) to wSndSFXRequest.  It is accepted only if id >= wSndSFXPriority (the
; id of the effect already playing), so higher ids have priority.  The SFX
; table entry gives the hardware channel*2 and the data pointer, which is
; stored as the read pointer of SFX track 4+channel.
; Part 2 - advance every active SFX track (7..4) by one tick.  An SFX ends when
; it executes $1A (sfx_end); its channel is then silenced and handed back to
; the music.  SFX tracks are not tempo-scaled; they always run one tick/frame.
; KK8S does not clear wSndSweep+4 when an effect starts.
; -----------------------------------------------------------------------------
Sound_UpdateSFX::
	ld a, [wSndSFXRequest]
	and a
	jr z, .process
	ld hl, wSndSFXPriority
	cp [hl]                                ; lower id than the running SFX?
	jr c, .clearRequest
	ld [hl], a                             ; new SFX becomes the running one
	add LOW(SFXTable - 3)
	ld l, a
	ld a, HIGH(SFXTable - 3)
	adc $00
	ld h, a
	ld a, [hl+]                            ; b = hw channel * 2
	ld b, a
	add LOW(SFXChannelMasks)
	ld e, a
	ld a, HIGH(SFXChannelMasks)
	adc $00
	ld d, a
	ld a, [de]                             ; c = channel mask ($11/$22/$44/$88)
	ld c, a
	ld a, [wSndSFXActiveMask]              ; channel now owned by the SFX
	or c
	ld [wSndSFXActiveMask], a
	ld a, [wSndSFXUsedMask]
	or c
	ld [wSndSFXUsedMask], a
	ld a, b                                ; de = &wSndTrackStack[(4+ch)*4]
	add a
	add a
	add LOW(wSndTrackStack+32)
	ld e, a
	ld d, HIGH(SND_RAM)
	ld a, [hl+]                            ; SFX read pointer (depth 0)
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	ld a, b
	cp $06                                 ; noise effect?
	jr z, .clearRequest
	xor a                                  ; else reset timers of track 4 - always
	ld [wSndDurationTimer+4], a            ; track 4, whatever channel the SFX uses
	ld [wSndGateInit+4], a
	ld [wSndGateTimer+4], a
.clearRequest
	xor a
	ld [wSndSFXRequest], a
.process
	ld a, [wSndSFXPriority]                ; any SFX playing?
	and a
	jp z, .ret
	xor a                                  ; SFX always write the hardware
	ld [wSndSFXOverride], a
	ld a, [wSndSyncWaitMask]               ; wSndSyncWaitMask is borrowed as the
	push af                                ; "SFX ended" flag; save music state
	ld a, $88
	ld [wSndCurMask], a
	ld a, $07                              ; tracks 7..4
	ld [wSndTrack], a
.trackLoop
	ld a, [wSndCurMask]
	ld c, a
	ld a, [wSndSFXActiveMask]
	and c                                  ; this channel playing an SFX?
	jr z, .nextTrack
	xor a
	ld [wSndSyncWaitMask], a
	ld a, [wSndTrack]
	ld e, a
	and $03                                ; hardware channel = track & 3
	ld [wSndHWChan], a
	add a
	add a
	ld [wSndChanX4], a
	ld d, $00
	ld hl, wSndDurationTimer
	add hl, de
	ld a, [hl]
	and a                                  ; still waiting for the current note?
	jr z, .readTrack
	dec [hl]
	jr nz, .nextTrack
.readTrack
	ld a, [wSndChanX4]                     ; hl = read pointer of track 4+ch
	add a
	add LOW(wSndTrackStack+32)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	call Sound_ParseTrack
	ld a, [wSndSyncWaitMask]               ; did the SFX execute sfx_end ($1A)?
	and a
	jr z, .nextTrack
	; The effect has ended: silence its channel.
	; BUG (as in Rampart): wSndChanX4 >> 1 = channel * 2 is used as the index into
	; wSndRegNRx2, so an effect ending on ch4 writes 0 to NR33 instead of NR42.
	ld a, [wSndChanX4]
	srl a
	add LOW(wSndRegNRx2)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld e, [hl]
	ld d, $FF
	xor a
	ld [de], a
	ld a, [wSndSyncWaitMask]               ; release the channel
	ld b, a
	ld a, [wSndSFXActiveMask]
	xor b
	ld [wSndSFXActiveMask], a
	jr nz, .nextTrack
	ld [wSndSFXPriority], a                ; no SFX left: priority = 0
	jp .restore

.nextTrack
	ld hl, wSndTrack
	dec [hl]
	ld l, LOW(wSndCurMask)                 ; wSndCurMask: next channel
	srl [hl]
	jr nc, .trackLoop
.restore
	pop af
	ld [wSndSyncWaitMask], a               ; restore music sync state
.ret
	ret

; -----------------------------------------------------------------------------
; SFXChannelMasks
; Indexed by the first byte of an SFX table entry (hardware channel * 2).
; -----------------------------------------------------------------------------
SFXChannelMasks::
	db $11, $00, $22, $00, $44, $00, $88

; -----------------------------------------------------------------------------
; SoundRegTable
; Copied to wSndRegNRx2/3/4 by Sound_Init.
; -----------------------------------------------------------------------------
SoundRegTable::
	db LOW(rNR12), LOW(rNR22), LOW(rNR32), LOW(rNR42); -> wSndRegNRx2
	db LOW(rNR13), LOW(rNR23), LOW(rNR33), LOW(rNR43); -> wSndRegNRx3
	db LOW(rNR14), LOW(rNR24), LOW(rNR34), LOW(rNR44); -> wSndRegNRx4

; -----------------------------------------------------------------------------
; Sound_MusicTick  (one music tick for tracks 3..0)
; For each channel not stopped/waiting: count down the gate timer (cut the
; note when it expires) and the duration timer; when the latter runs out, read
; the next event from the track.  Tracks covered by an SFX keep running, but
; wSndSFXOverride stops them from writing to the hardware.
; Afterwards the song-level state is evaluated:
;   all tracks stopped              -> music finished
;   all tracks stopped or looping   -> restart song from its header
;   all tracks stopped/looping/sync -> release the sync and rescan at once
; -----------------------------------------------------------------------------
Sound_MusicTick::
	ld a, [wSndSyncWaitMask]               ; entry: a = wSndSyncWaitMask
.rescan
	ld b, a
	ld a, [wSndLoopWaitMask]
	or b
	ld b, a
	ld a, [wSndStoppedMask]
	or b
	ld [wSndIdleMask], a                   ; tracks that must not be advanced
	ld a, $03
	ld [wSndHWChan], a
	ld [wSndTrack], a
	ld a, $88                              ; mask for ch4, then >>1 per channel
.channelLoop
	ld [wSndCurMask], a
	ld b, a
	ld a, [wSndIdleMask]
	and b
	jr nz, .nextChannel                    ; skip idle track
	ld a, [wSndSFXActiveMask]
	and b
	ld [wSndSFXOverride], a                ; nonzero = SFX owns this channel
	ld a, [wSndHWChan]
	add a
	add a
	ld [wSndChanX4], a
	; BUG (as in Rampart): Sound_NoteOff ends with "pop hl / ret".  When the
	; gate timer expires the rest of this tick is skipped for the remaining
	; channels.  KK8S never uses the gate command, so it has no effect here.
	ld a, [wSndHWChan]
	ld e, a
	ld d, $00
	ld hl, wSndGateTimer
	add hl, de
	ld a, [hl]
	and a                                  ; gate running?
	jr z, .checkDuration
	dec [hl]
	call z, Sound_NoteOff                  ; gate expired: cut the note (see BUG)
.checkDuration
	ld hl, wSndDurationTimer
	add hl, de
	ld a, [hl]
	and a
	jr z, .nextEvent                       ; waiting for the current note?
	dec [hl]
	jr nz, .nextChannel
.nextEvent
	ld a, [wSndSFXOverride]                ; time for the next event
	jr nz, .read                           ; unless covered by an SFX:
	ld a, [wSndCurMask]
	cpl                                    ; clear this channel in wSndSFXUsedMask
	ld b, a
	ld a, [wSndSFXUsedMask]
	and b
	ld [wSndSFXUsedMask], a
.read
	call Sound_ReadMusicTrack              ; read and execute events
.nextChannel
	ld a, [wSndCurMask]
	srl a
	ld hl, wSndTrack                       ; next track / next hw channel
	dec [hl]
	dec hl
	dec [hl]
	bit 7, [hl]                            ; until channel -1
	jr z, .channelLoop
	ld a, [wSndStoppedMask]
	cp $FF                                 ; everything stopped?
	jp z, Sound_MusicFinished
	ld b, a
	ld a, [wSndLoopWaitMask]
	or b
	cp $FF                                 ; everything stopped or at song_loop?
	jr z, Sound_LoadSongHeader
	ld b, a
	ld a, [wSndSyncWaitMask]
	or b
	cp $FF                                 ; everything also at a sync point?
	ret nz
	xor a                                  ; release all syncs and process the
	ld [wSndSyncWaitMask], a
	jp .rescan                             ; tracks again in the same tick

; -----------------------------------------------------------------------------
; Sound_LoadSongHeader
; Clears note lengths and duration timers of all tracks, resets the
; loop-wait mask and loads the header pointers of every track that has not
; executed stop_track (those stay silent when the song loops).
; -----------------------------------------------------------------------------
Sound_LoadSongHeader::
	ld b, $10                              ; wSndNoteLength + wSndDurationTimer
	ld hl, wSndNoteLength
	xor a
.clearLengths
	ld [hl+], a
	dec b
	jr nz, .clearLengths
	ld a, [wSndStoppedMask]
	ld c, a                                ; bit 0..3 = tracks 0..3
	xor a
	ld [wSndLoopWaitMask], a
	ld a, [wSndSongPtr]
	ld l, a
	ld a, [wSndSongPtr+1]
	ld h, a
	ld de, wSndTrackStack                  ; depth-0 slot of track 0
	ld b, $04
.channelLoop
	srl c                                  ; track stopped?
	jr c, Sound_ClearTranspose.skipChannel
	ld a, [hl+]
	ld [de], a
	inc de
	ld a, [hl+]
	ld [de], a
	ld a, e
	add $07                                ; next track: +8 bytes
	ld e, a
.next
	dec b
	jr nz, .channelLoop
Sound_ClearTranspose::
	xor a
	ld [wSndTranspose], a
	ld [wSndTranspose+1], a
	ld [wSndTranspose+2], a
	ret

.skipChannel
	inc hl
	inc hl
	ld a, e
	add $08
	ld e, a
	jr Sound_LoadSongHeader.next

; -----------------------------------------------------------------------------
; Sound_ReadMusicTrack
; hl = read pointer of music track wSndTrack, then fall into Sound_ParseTrack.
; -----------------------------------------------------------------------------
Sound_ReadMusicTrack::
	ld a, [wSndTrack]
	ld e, a
	ld d, $00
	ld hl, wSndStackDepth
	add hl, de
	ld a, [wSndChanX4]
	or [hl]                                ; track*4 + depth (track = hw channel here)
	add a
	ld e, a
	ld l, LOW(wSndTrackStack)
	add hl, de
	ld a, [hl+]
	ld h, [hl]
	ld l, a

; -----------------------------------------------------------------------------
; Sound_ParseTrack
; Executes commands until a note, rest or halting command is reached.
;   $00-$11 note   $12-$27 command   $28-$FF set note length (length = byte - $28)
; Commands return carry set to keep parsing, carry clear to stop.
; -----------------------------------------------------------------------------
Sound_ParseTrack::
	ld a, [hl+]
	cp $12
	jr c, Sound_PlayNote                   ; note
	call Sound_DoCommand
	jr c, Sound_ParseTrack                 ; command that continues parsing

; -----------------------------------------------------------------------------
; Sound_SaveTrackPtr
; Stores hl as the read pointer (current depth slot) of track wSndTrack.
; -----------------------------------------------------------------------------
Sound_SaveTrackPtr::
	push hl
	ld a, [wSndTrack]
	ld e, a
	ld d, $00
	ld hl, wSndStackDepth
	add hl, de
	add a
	add a
	or [hl]
	add a
	ld e, a
	ld l, LOW(wSndTrackStack)
	add hl, de
	pop bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret

; -----------------------------------------------------------------------------
; Sound_PlayNote
; In: a = note ($00-$11).  Starts the gate and duration timers, then (unless
; an SFX owns the channel) programs the hardware:
;   pulse: NRx3 = freq lo, NRx2 = envelope, [NR10 = sweep], NRx4 = hi | $80
;   wave : NR33, NR31 = timbre*2, NR32 = $20 (100%), NR34 = hi | $80
;   noise: NR43 = note << 4, NR42 = timbre, NR41 = 1, NR44 = $80
; Differences to Rampart: registers are written with ld [hl] instead of ldh [c];
; the NRx2 address comes from SoundRegTable in ROM; the wave channel is not
; switched off/on around the trigger; the noise trigger does not enable the
; length counter ($80 instead of $C0), so noise notes sustain.
; -----------------------------------------------------------------------------
Sound_PlayNote::
	push af
	call Sound_SaveTrackPtr                ; save read pointer
	ld d, $00
	ld a, [wSndTrack]
	ld e, a
	ld hl, wSndGateInit
	add hl, de
	ld a, [hl]                             ; gate timer = gate time
	ld l, LOW(wSndGateTimer)
	add hl, de
	ld [hl], a
	ld l, LOW(wSndNoteLength)
	add hl, de
	ld a, [hl]                             ; duration timer = note length
	ld l, LOW(wSndDurationTimer)
	add hl, de
	ld [hl], a
	ld [wSndLastLength], a
	pop bc                                 ; b = note
	ld a, [wSndSFXOverride]
	and a
	ret nz                                 ; SFX owns channel: no hardware writes
	ld a, [wSndCurMask]
	bit 7, a                               ; ch4 (mask $88)?
	jr nz, .noise
	ld a, e
	cp $04                                 ; music track?
	jr nc, .pitch
	ld hl, wSndTranspose                   ; note += transpose
	add hl, de
	ld a, b
	add [hl]
	ld b, a
.pitch
	ld a, b
	add a                                  ; c = note * 2
	ld c, a
	ld b, d
	ld hl, FrequencyTable
	add hl, bc
	push hl
	ld hl, wSndOctave                      ; + octave * 24
	add hl, de
	ld c, [hl]
	ld hl, OctaveOffsets
	add hl, bc
	ld c, [hl]
	pop hl
	add hl, bc
	ld a, [hl+]                            ; bc = frequency
	ld b, [hl]
	ld c, a
	ld a, [wSndCurMask]
	bit 6, a                               ; ch3 (mask $44)?
	jr nz, .wave
	ld a, [wSndHWChan]
	add LOW(wSndRegNRx3)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld l, [hl]
	ld h, $FF
	ld [hl], c                             ; NRx3 = frequency lo
	ld a, [wSndTrack]
	add LOW(wSndEnvelope)                  ; envelope of this track
	ld l, a
	ld h, HIGH(SND_RAM)
	ld c, [hl]
	ld a, [wSndHWChan]
	ld e, a
	ld hl, SoundRegTable                   ; NRx2 address straight from ROM
	add hl, de
	ld l, [hl]
	ld h, $FF
	ld [hl], c                             ; NRx2 = envelope
	ld a, [wSndHWChan]
	and a
	jr nz, .trigger                        ; only ch1 has a sweep unit
	ld hl, wSndSweep
	ld a, [wSndTrack]
	and a
	jp z, .writeSweep
	ld l, LOW(wSndSweep+4)                 ; SFX track 4 uses wSndSweep+4
.writeSweep
	ld a, [hl]
	ldh [rNR10], a
.trigger
	ld a, [wSndHWChan]
	add LOW(wSndRegNRx4)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld l, [hl]
	ld h, $FF
	set 7, b
	ld [hl], b                             ; NRx4 = frequency hi + trigger
	ret

.noise
	ld a, b                                ; clock shift = note
	add a
	add a
	add a
	add a
	ldh [rNR43], a
	ld a, [wSndTrack]
	add LOW(wSndTimbre)                    ; noise envelope from timbre
	ld l, a
	ld h, HIGH(SND_RAM)
	ld a, [hl]
	ldh [rNR42], a
	ld a, $01                              ; length 63
	ldh [rNR41], a
	ld a, $80                              ; trigger, length counter NOT enabled
	ldh [rNR44], a
	ret

.wave
	ld a, c
	ldh [rNR33], a
	ld hl, wSndTimbre
	add hl, de
	ld a, [hl]
	add a                                  ; NR31 = timbre * 2
	ldh [rNR31], a
	ld a, $20                              ; volume 100%
	ldh [rNR32], a
	ld a, b
	or $80
	ldh [rNR34], a
	ret

; -----------------------------------------------------------------------------
; Sound_SetNoteLength
; Byte $28-$FF: sets the length of the following notes; parsing continues.
; -----------------------------------------------------------------------------
Sound_SetNoteLength::
	sub $28
	ld c, a
	push hl
	ld hl, wSndNoteLength
	ld a, [wSndTrack]
	ld e, a
	ld d, $00
	add hl, de
	ld [hl], c
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; Sound_DoCommand
; In: a = byte >= $12.  Dispatches $12-$27 through SoundCommandTable with
; the read pointer pushed; the handler pops it, reads its parameters and
; returns carry set (continue parsing) or carry clear (stop for this tick).
; -----------------------------------------------------------------------------
Sound_DoCommand::
	cp $28
	jr nc, Sound_SetNoteLength
	push hl
	add a
	add LOW(SoundCommandTable - 2 * $12)
	ld l, a
	ld a, HIGH(SoundCommandTable - 2 * $12)
	adc $00
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

; -----------------------------------------------------------------------------
; SndCmd_Rest  ($12)
; Waits for the current note length and silences the channel (falls
; through into Sound_NoteOff).
; -----------------------------------------------------------------------------
SndCmd_Rest::
	ld a, [wSndTrack]
	ld e, a
	ld d, $00
	ld hl, wSndNoteLength
	add hl, de
	ld a, [hl]
	ld hl, wSndDurationTimer
	add hl, de
	ld [hl], a

; -----------------------------------------------------------------------------
; Sound_NoteOff
; Silences hardware channel wSndHWChan (unless an SFX owns it): NRx2 = 0,
; then NRx4 = $80.  For ch3: NR32 = 0, NR34 = $80 (Rampart uses NR52 instead).
; Pops one stack entry and returns carry clear, like a halting command.
; -----------------------------------------------------------------------------
Sound_NoteOff::
	ld d, $00
	ld a, [wSndSFXOverride]
	and a
	jr nz, .done
	ld a, [wSndHWChan]
	add LOW(wSndRegNRx2)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld c, [hl]
	ld b, $FF                              ; b = $FF: hardware register page
	ld a, $00
	ld [bc], a                             ; NRx2 = 0 (DAC off)
	ld a, [wSndHWChan]
	cp $02
	jr z, .wave
	ld e, a
	ld hl, wSndRegNRx4
	add hl, de
	ld c, [hl]
	ld a, $80
	ld [bc], a                             ; NRx4 = $80
	pop hl
	and a
	ret

.wave
	xor a
	ldh [rNR32], a                         ; ch3: output off
	ld a, $80
	ldh [rNR34], a                         ; retrigger
.done
	pop hl
	and a
	ret

; -----------------------------------------------------------------------------
; SndCmd_Tempo  ($20 x)
; Sets the global music tempo and clears the fraction accumulator.
; -----------------------------------------------------------------------------
SndCmd_Tempo::
	pop hl
	ld a, [hl+]
	ld [wSndTempo], a
	xor a
	ld [wSndTempoAccum], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Timbre  ($1D x)
; Tracks 0/1 (ch1/ch2 music): x is written straight to NR11 / NR21 (duty in
; bits 6-7).  Every other track stores x in wSndTimbre: ch3 wave length
; (NR31 = x*2) or ch4 envelope (NR42).  SFX on ch1 therefore cannot set duty.
; -----------------------------------------------------------------------------
SndCmd_Timbre::
	ld a, [wSndTrack]
	ld c, a
	add LOW(wSndTimbre)
	ld e, a
	ld d, HIGH(SND_RAM)
	ld a, c
	cp $02                                 ; track 0 or 1?
	pop hl
	ld a, [hl+]
	jr c, .pulse
	ld [de], a
	scf
	ret

.pulse
	push hl
	bit 0, c
	ld hl, rNR11
	jr z, .write                           ; track 1: NR21
	ld l, LOW(rNR21)
.write
	ld [hl], a
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Sweep  ($1E x)
; Stores the NR10 value used when a ch1 note is triggered.  KK8S only accepts
; it on channel 1 (bit 0 of wSndCurMask); on other channels the byte is read
; past without effect.  (Rampart stores it for every track.)
; NOTE: the parameter is only consumed on channel 1 - on any other channel the
; handler returns with hl still pointing AT the parameter, which is then
; executed as the next event.
; -----------------------------------------------------------------------------
SndCmd_Sweep::
	ld a, [wSndTrack]
	add LOW(wSndSweep)
	ld e, a
	ld d, HIGH(SND_RAM)
	ld a, [wSndCurMask]                    ; bit 0 set only for channel 1 ($11)
	bit 0, a
	jr z, .notCh1
	pop hl                                 ; channel 1: store the sweep
	ld a, [hl+]
	ld [de], a
	scf
	ret

.notCh1
	pop hl                                 ; other channels: parameter NOT skipped!
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Panning  ($26 x)
; NR51 = x (affects all channels).
; -----------------------------------------------------------------------------
SndCmd_Panning::
	pop hl
	ld a, [hl+]
	ldh [rNR51], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Octave  ($13 n)
; -----------------------------------------------------------------------------
SndCmd_Octave::
	ld a, [wSndTrack]
	add LOW(wSndOctave)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld a, [hl+]
	ld [de], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_OctaveUp  ($14)
; -----------------------------------------------------------------------------
SndCmd_OctaveUp::
	ld a, [wSndTrack]
	add LOW(wSndOctave)
	ld l, a
	ld h, HIGH(SND_RAM)
	inc [hl]
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_OctaveDown  ($15)
; -----------------------------------------------------------------------------
SndCmd_OctaveDown::
	ld a, [wSndTrack]
	add LOW(wSndOctave)
	ld l, a
	ld h, HIGH(SND_RAM)
	dec [hl]
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Envelope  ($1F x)
; NRx2 value for pulse notes of this track.
; -----------------------------------------------------------------------------
SndCmd_Envelope::
	pop hl
	ld a, [wSndTrack]
	add LOW(wSndEnvelope)
	ld e, a
	ld d, HIGH(SND_RAM)
	ld a, [hl+]
	ld [de], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Call  ($16 addr)
; Saves the address after the operand in the current stack slot, increments
; the depth and continues at addr.  Indexed by hardware channel, so it only
; works for music tracks.
; -----------------------------------------------------------------------------
SndCmd_Call::
	ld a, [wSndHWChan]
	add LOW(wSndStackDepth)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld b, [hl]                             ; b = old depth
	inc [hl]
	ld a, [wSndChanX4]
	add b
	add a
	add LOW(wSndTrackStack)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld c, [hl]                             ; bc = target
	inc hl
	ld b, [hl]
	inc hl
	ld a, l                                ; return address -> slot[depth]
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	ld l, c
	ld h, b
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Jump  ($25 addr)
; Continues at addr.  (Rampart additionally reloads the wave RAM here when
; on channel 3.)
; -----------------------------------------------------------------------------
SndCmd_Jump::
	pop hl
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Return  ($17)
; Decrements the depth and continues at the saved return address.
; -----------------------------------------------------------------------------
SndCmd_Return::
	pop hl
	ld a, [wSndHWChan]
	add LOW(wSndStackDepth)
	ld l, a
	ld h, HIGH(SND_RAM)
	dec [hl]
	ld a, [wSndChanX4]
	add [hl]
	add a
	ld e, a
	ld d, $00
	ld hl, wSndTrackStack
	add hl, de
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_LoopStart  ($18 n)
; Sets the loop counter of the hardware channel to n and pushes the address of
; the loop body.  Only ONE counter per channel: loops cannot be nested.
; -----------------------------------------------------------------------------
SndCmd_LoopStart::
	ld a, [wSndHWChan]
	add LOW(wSndLoopCounter)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld a, [hl+]
	ld [de], a
	push hl
	ld a, [wSndHWChan]
	add LOW(wSndStackDepth)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld b, [hl]
	inc [hl]
	ld a, [wSndChanX4]
	add b
	add a
	add LOW(wSndTrackStack)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_LoopEnd  ($19)
; Decrements the counter; while nonzero, jumps back to the loop body,
; otherwise pops the loop entry and continues after the $19.
; -----------------------------------------------------------------------------
SndCmd_LoopEnd::
	ld a, [wSndHWChan]
	add LOW(wSndLoopCounter)
	ld l, a
	ld h, HIGH(SND_RAM)
	dec [hl]
	jr z, .loopDone
	ld a, [wSndHWChan]
	add LOW(wSndStackDepth)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld b, [hl]
	dec b
	ld a, [wSndChanX4]
	add b
	add a
	add LOW(wSndTrackStack)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	pop bc                                 ; drop pushed pointer
	scf
	ret

.loopDone
	ld a, [wSndHWChan]
	add LOW(wSndStackDepth)
	ld l, a
	ld h, HIGH(SND_RAM)
	dec [hl]
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_StopTrack  ($1C)
; Silences the channel (without checking for an SFX) and marks the track
; as stopped.  Halts parsing.
; -----------------------------------------------------------------------------
SndCmd_StopTrack::
	ld a, [wSndHWChan]
	add LOW(wSndRegNRx2)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld c, [hl]
	ld b, $FF
	xor a
	ld [bc], a
	pop hl
	ld a, [wSndCurMask]
	ld b, a
	ld a, [wSndStoppedMask]
	or b
	ld [wSndStoppedMask], a
	and a
	ret

; -----------------------------------------------------------------------------
; SndCmd_SongLoop  ($1B)
; Marks the track as finished; the song restarts when all tracks are
; finished or stopped.  Halts parsing.
; -----------------------------------------------------------------------------
SndCmd_SongLoop::
	ld a, [wSndCurMask]
	ld b, a
	ld a, [wSndLoopWaitMask]
	or b
	ld [wSndLoopWaitMask], a
	pop hl
	and a
	ret

; -----------------------------------------------------------------------------
; SndCmd_Sync  ($1A)
; Music: the track waits here until all tracks wait/finished (bar sync).
; SFX: the effect ends (checked by Sound_UpdateSFX).  Halts parsing.
; -----------------------------------------------------------------------------
SndCmd_Sync::
	ld a, [wSndCurMask]
	ld b, a
	ld a, [wSndSyncWaitMask]
	or b
	ld [wSndSyncWaitMask], a
	pop hl
	and a
	ret

; -----------------------------------------------------------------------------
; SndCmd_Unused21  ($21 x)
; No effect, skips one parameter byte.  (The stray "ld [de], a" of Rampart
; has been removed.)
; -----------------------------------------------------------------------------
SndCmd_Unused21::
	pop hl
	ld a, [hl+]
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Gate  ($23 x)
; Notes of this track are cut after x ticks (0 = never).
; -----------------------------------------------------------------------------
SndCmd_Gate::
	ld a, [wSndTrack]
	add LOW(wSndGateInit)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld a, [hl+]
	ld [de], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Transpose  ($24 x)
; Signed transpose in semitones, per hardware channel (ch1-3 only).
; -----------------------------------------------------------------------------
SndCmd_Transpose::
	ld a, [wSndHWChan]
	add LOW(wSndTranspose)
	ld e, a
	ld d, HIGH(SND_RAM)
	pop hl
	ld a, [hl+]
	ld [de], a
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Unused27  ($27 x)
; No effect, skips ONE parameter byte (Rampart: two).
; -----------------------------------------------------------------------------
SndCmd_Unused27::
	pop hl
	inc hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Unused22  ($22)
; No effect and NO parameter byte (Rampart: one).
; -----------------------------------------------------------------------------
SndCmd_Unused22::
	pop hl
	scf
	ret

; -----------------------------------------------------------------------------
; Padding
; -----------------------------------------------------------------------------
	ds 11, $00

; -----------------------------------------------------------------------------
; SoundCommandTable
; Handlers for command bytes $12-$27.
; -----------------------------------------------------------------------------
SoundCommandTable::
	dw SndCmd_Rest                         ; $12  REST (note)
	dw SndCmd_Octave                       ; $13  octave
	dw SndCmd_OctaveUp                     ; $14  octave_up
	dw SndCmd_OctaveDown                   ; $15  octave_down
	dw SndCmd_Call                         ; $16  snd_call
	dw SndCmd_Return                       ; $17  snd_ret
	dw SndCmd_LoopStart                    ; $18  loop
	dw SndCmd_LoopEnd                      ; $19  endloop
	dw SndCmd_Sync                         ; $1A  sync / sfx_end
	dw SndCmd_SongLoop                     ; $1B  song_loop
	dw SndCmd_StopTrack                    ; $1C  stop_track
	dw SndCmd_Timbre                       ; $1D  timbre
	dw SndCmd_Sweep                        ; $1E  sweep
	dw SndCmd_Envelope                     ; $1F  envelope
	dw SndCmd_Tempo                        ; $20  tempo
	dw SndCmd_Unused21                     ; $21  unused21
	dw SndCmd_Unused22                     ; $22  unused22
	dw SndCmd_Gate                         ; $23  gate
	dw SndCmd_Transpose                    ; $24  transpose
	dw SndCmd_Jump                         ; $25  snd_jump
	dw SndCmd_Panning                      ; $26  panning
	dw SndCmd_Unused27                     ; $27  unused27

; -----------------------------------------------------------------------------
; OctaveOffsets
; Byte offset into FrequencyTable for octaves 0-7.
; -----------------------------------------------------------------------------
OctaveOffsets::
	db 0 * 24, 1 * 24, 2 * 24, 3 * 24, 4 * 24, 5 * 24, 6 * 24, 7 * 24

; -----------------------------------------------------------------------------
; FrequencyTable
; GB frequency values (131072 / (2048 - x) Hz), 83 semitones from C2.
; Octave 6 notes above A#8 and octave 7 read past the end of the table.
; -----------------------------------------------------------------------------
FrequencyTable::
	dw $02C, $09D, $107, $16B, $1C9, $223, $277, $2C7, $312, $358, $39B, $3DA          ; C2-B2
	dw $416, $44E, $483, $4B5, $4E5, $511, $53B, $563, $589, $5AC, $5CE, $5ED          ; C3-B3
	dw $60B, $627, $642, $65B, $672, $689, $69E, $6B2, $6C4, $6D6, $6E7, $6F7          ; C4-B4
	dw $706, $714, $721, $72D, $739, $744, $74F, $759, $762, $76B, $773, $77B          ; C5-B5
	dw $783, $78A, $790, $797, $79D, $7A2, $7A7, $7AC, $7B1, $7B6, $7BA, $7BE          ; C6-B6
	dw $7C1, $7C5, $7C8, $7CB, $7CE, $7D1, $7D4, $7D6, $7D9, $7DB, $7DD, $7DF          ; C7-B7
	dw $7E1, $7E2, $7E4, $7E6, $7E7, $7E9, $7EA, $7EB, $7EC, $7ED, $7EE                ; C8-A#8

; -----------------------------------------------------------------------------
; DefaultWave
; Triangle wave loaded into wave RAM.
; -----------------------------------------------------------------------------
DefaultWave::
	db $00, $11, $22, $33, $44, $55, $66, $77, $88, $88, $77, $66, $55, $44, $31, $10

; -----------------------------------------------------------------------------
; SongTable
; Song $08 at the end of the data is complete but not in this table.
; -----------------------------------------------------------------------------
SongTable::
	dw Song00                              ; song $00 (call Sound_PlaySong with a = $00)
	dw Song01                              ; song $01 (call Sound_PlaySong with a = $02)
	dw Song02                              ; song $02 (call Sound_PlaySong with a = $04)
	dw Song03                              ; song $03 (call Sound_PlaySong with a = $06)
	dw Song04                              ; song $04 (call Sound_PlaySong with a = $08)
	dw Song05                              ; song $05 (call Sound_PlaySong with a = $0A)
	dw Song06                              ; song $06 (call Sound_PlaySong with a = $0C)
	dw Song07                              ; song $07 (call Sound_PlaySong with a = $0E)

; -----------------------------------------------------------------------------
; Song $00: silence
; All four tracks point at a single stop_track.  SFXTable - 3 (the base used
; by Sound_UpdateSFX) lies inside this header; id 0 is never looked up.
; -----------------------------------------------------------------------------
Song00::
	song_header Song00_AllChannels, Song00_AllChannels, Song00_AllChannels, Song00_AllChannels
Song00_AllChannels::
	stop_track

; -----------------------------------------------------------------------------
; SFXTable
; Indexed directly by SFX id (a multiple of 3).  Entry = hw channel * 2 + pointer.
; -----------------------------------------------------------------------------
SFXTable::
	sfx_entry 0, SFX_03                    ; SFX id $03
	sfx_entry 0, SFX_06                    ; SFX id $06
	sfx_entry 0, SFX_09                    ; SFX id $09
	sfx_entry 0, SFX_0C                    ; SFX id $0C
	sfx_entry 3, SFX_0F                    ; SFX id $0F
	sfx_entry 0, SFX_12                    ; SFX id $12
	sfx_entry 3, SFX_15                    ; SFX id $15
	sfx_entry 0, SFX_18                    ; SFX id $18
	sfx_entry 0, SFX_1B                    ; SFX id $1B
	sfx_entry 0, SFX_1E                    ; SFX id $1E
	sfx_entry 0, SFX_21                    ; SFX id $21
	sfx_entry 0, SFX_24                    ; SFX id $24

; =============================================================================
; Sound effect data
; =============================================================================
SFX_03::
	envelope $FF
	timbre $C0
	sweep $00
	octave 0
	len 2
	note A_, REST
	len 20
	note A_
	sfx_end

SFX_06::
	envelope $FF
	timbre $80
	octave 4
	len 3
	note B_
	sfx_end

SFX_09::
	envelope $FF
	timbre $80
	octave 3
	len 2
	note C_
	sfx_end

SFX_0C::
	envelope $FF
	timbre $00
	sweep $AB
	octave 5
	len 2
	note G_
	len 1
	note B_, REST
	sfx_end

SFX_0F::
	timbre $F1
	len 2
	note $09, $02, REST
	sfx_end

SFX_12::
	envelope $FF
	timbre $80
	sweep $00
	octave 3
	len 1
	note D_, B_
	sfx_end

SFX_15::
	timbre $F1
	len 2
	note $03, $01, REST
	sfx_end

SFX_18::
	envelope $FF
	timbre $80
	sweep $AD
	octave 3
	len 10
	note B_
	sweep $00
	sfx_end

SFX_1B::
	envelope $FF
	timbre $80
	sweep $AA
	octave 3
	len 1
	note C_, B_, REST
	sfx_end

SFX_1E::
	envelope $FF
	timbre $80
	sweep $A5
	octave 1
	len 20
	note D_
	sfx_end

SFX_21::
	envelope $FF
	timbre $C0
	sweep $A3
	octave 1
	len 3
	note G_, C_
	sfx_end

SFX_24::
	envelope $FF
	timbre $80
	sweep $00
	octave 3
	len 4
	note C_
	octave_up
	note E_, G_, B_
	sfx_end

; =============================================================================
; Song $01
; =============================================================================
Song01::
	song_header Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
Song01_Ch1::
	tempo $88
	timbre $80
	envelope $76
	sweep $00
	transpose 12
	snd_call Song01_Sub1
	len 24
	note D_, F#, G_
	len 48
	note F#
	len 24
	note E_, D_
	len 192
	note C_
	len 12
	note C_, C_
	len 144
	octave_down
	note B_
	len 48
	note REST
	len 96
	octave_up
	note C_, D_, E_, F#
	snd_call Song01_Sub1
	len 24
	note E_, F_, G_
	len 48
	note F#
	len 24
	note E_, D_, D#
	octave_down
	note REST, G_, G_, F_, G_, D#, D#, G_
	note REST, G_, G_, F_, G_, D#, D#, REST
	note REST, A_, A_, REST, A_, A_, REST, REST
	note REST, A_, A_, REST, A_, A_, REST, REST
	note REST, G_, G_, F_, G_, D#, D#, G_
	note REST, G_, G_, F_, G_, D#, D#, REST
	note REST, A_, A_, REST, A_, A_, REST, REST
	note REST, A_, A_, REST, A_, A_, REST, REST
	loop 3
	octave 2
	len 48
	note D_, G_
	len 24
	note G_, F#
	len 48
	note D_
	endloop
	note C_, D_, G_, F#
	song_loop

Song01_Sub1::
	octave 2
	len 96
	note G_, F#
	len 72
	note D_
	len 24
	note F#
	len 96
	note D_
	len 96
	note C_, E_, E_, F#, G_, F#
	len 72
	note E_
	len 24
	note F#
	len 96
	note E_
	len 48
	note C_, E_
	len 96
	note D_
	len 192
	note C_
	len 96
	note C_, D_, E_
	len 24
	note REST, G_, F#, E_, F#
	octave_down
	note B_, B_, B_, REST
	octave_up
	note G_, F#, E_, F#
	octave_down
	note A_, A_, A_
	len 72
	note REST
	len 12
	octave_up
	note C_, D_
	len 72
	note E_
	len 12
	note C_, D_
	len 48
	note E_, G_
	len 24
	note D_
	len 12
	note D_, D_
	len 48
	octave_down
	note A_
	len 72
	note REST
	len 12
	octave_up
	note C_, D_
	len 72
	note E_
	len 12
	note D_, E_
	len 48
	note F#, C_
	octave_down
	note B_
	octave_up
	note D_, E_
	len 24
	note REST
	len 12
	note C_, D_
	len 24
	note C_, C_, C_, REST
	len 96
	note REST
	snd_ret

Song01_Ch2::
	timbre $80
	envelope $78
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	transpose 12
	snd_call Song01_Sub2
	len 24
	note G_, A_, B_
	len 48
	note A_
	len 24
	note G_, F#
	len 192
	note A_
	len 12
	note G_, F#
	len 144
	note G_
	len 48
	note REST
	len 96
	note E_, F#, G_, A_
	snd_call Song01_Sub2
	len 24
	note G_, A_, B_
	len 48
	note A_
	len 24
	note G_, F#
	len 192
	note G_
	len 72
	note A#
	len 48
	note A_, G_, D#
	len 36
	note C_, F_
	len 48
	note G_
	len 192
	note A_
	len 72
	note REST
	len 144
	note A#
	len 24
	note REST, A_, A#
	octave_up
	note C_, D_
	octave_down
	len 72
	note A#
	len 48
	note B_
	len 192
	octave_up
	note C_, C_
	loop 3
	len 24
	octave_down
	note B_, A_, B_
	octave_up
	note D_
	octave_down
	note B_, A_, B_
	octave_up
	note D_
	endloop
	len 48
	octave_down
	note E_, F#, B_, A_
	song_loop

Song01_Sub2::
	octave 2
	len 96
	note B_, A_
	len 72
	note G_
	len 24
	note A_
	len 96
	note B_
	len 96
	octave_up
	note C_
	octave_down
	note B_, G_, A_, B_, A_
	len 72
	note G_
	len 24
	note A_
	len 96
	note B_
	len 24
	octave_up
	note E_, C_
	octave_down
	note A_, G_
	len 48
	note F#, A_
	len 192
	note G_
	len 96
	note E_, F#, G_
	len 24
	note REST, B_, A_, G_, A_, D_, D_, D_
	note REST, B_, A_, G_, A_, D_, D_, D_
	len 72
	note REST
	len 12
	note E_, F#
	len 72
	note G_
	len 12
	note E_, F#
	len 48
	note G_, B_
	len 24
	note A_
	len 12
	note G_, F#
	len 48
	note D_
	len 72
	note REST
	len 12
	note E_, F#
	len 72
	note G_
	len 12
	note F#, G_
	len 48
	note A_, D_
	len 36
	note B_
	octave_up
	len 12
	note C_
	len 24
	octave_down
	note B_, A_
	len 48
	note G_
	len 12
	note REST, REST, D_, F#
	len 24
	note G_, G_
	len 48
	note E_
	len 72
	note REST
	len 12
	note D_, E_
	snd_ret

Song01_Ch3::
	transpose 12
	snd_call Song01_Sub3
	octave 1
	len 24
	note D_, D_, D_
	len 48
	note D_
	len 24
	note C_
	octave_down
	note B_, A_, F_, F_, A_
	octave_up
	note C_
	octave_down
	note F_, F_, A_
	octave_up
	note C_
	octave_down
	note G_, G_, B_
	octave_up
	note D_
	octave_down
	note G_, G_, B_
	octave_up
	note D_
	len 96
	note D_, D_
	len 12
	note C_, D_, REST, D_
	len 24
	note D_
	octave_down
	note A_
	octave_up
	len 12
	note C_, D_, REST, C_
	len 24
	note D_
	len 12
	note E_, F#
	snd_call Song01_Sub3
	len 24
	note D_, D_, D_
	len 48
	note D_
	len 24
	note C_
	octave_down
	note B_, A_
	len 36
	octave_up
	note D#
	len 12
	note D_
	len 24
	note REST
	octave_down
	note A#
	len 12
	note REST, G_
	len 24
	note REST, A#
	octave_up
	note D_
	len 36
	note D#
	len 12
	note D_
	len 24
	note REST
	octave_down
	note A#
	len 12
	octave_up
	note REST, D#
	len 24
	note D#
	len 12
	note REST
	len 36
	note E_
	octave_down
	len 36
	note F_
	len 12
	octave_up
	note F_
	len 24
	note REST, C_
	len 12
	note REST
	octave_down
	note A_
	len 24
	note REST
	octave_up
	note C_, D#
	octave_down
	len 36
	note F_
	octave_up
	len 12
	note F_
	len 24
	note REST, C_, REST, F_
	len 12
	note REST
	len 36
	note E_
	len 36
	note D#
	len 12
	note D_
	len 24
	note REST
	octave_down
	note A#
	len 12
	note REST, G_
	len 24
	note REST, A#
	octave_up
	note D#
	len 36
	note D#
	len 12
	note D_
	len 24
	note REST
	octave_down
	note A#
	len 12
	note REST
	octave_up
	note D#
	len 24
	note D_
	len 12
	note REST
	len 36
	note E_
	octave_down
	len 36
	note F_
	len 12
	octave_up
	note F_
	len 24
	note REST, C_
	len 12
	note REST
	octave_down
	note A_
	len 24
	note REST
	octave_up
	note C_, D#
	octave_down
	len 36
	note F_
	len 12
	octave_up
	note F_
	len 24
	note REST, C_, REST, F_
	len 12
	note REST
	len 36
	note F#
	loop 3
	len 36
	note G_
	len 12
	octave_down
	note G_
	len 24
	note REST, G_
	len 72
	note REST
	len 12
	note B_
	octave_up
	note C_
	endloop
	len 48
	note D_, D_
	len 12
	note C_, D_, REST, D_, D_
	octave_down
	note A_
	song_loop

Song01_Sub3::
	octave 0
	len 24
	note G_, G_, B_
	octave_up
	note D_
	octave_down
	note F#, F#, A_
	octave_up
	note D_, E_, E_, G_, B_
	octave_up
	note D_, D_
	octave_down
	note B_, G_, C_, C_, E_, G_, C_, C_
	note E_, G_, D_, D_, D_
	octave_down
	note A_
	len 12
	note F#, F#
	len 24
	note B_
	octave_up
	len 12
	note D_
	octave_up
	note D_, REST, D_
	octave 0
	len 24
	note G_, G_, B_
	octave_up
	note D_
	octave_down
	note F#, F#, A_
	octave_up
	note D_, E_, E_, G_, B_
	octave_up
	note D_, D_
	octave_down
	note B_, G_, C_, C_, E_, G_, D_, D_
	note F#, A_
	octave_down
	note F_, F_, A_
	octave_up
	note C_
	octave_down
	note F_, F_, A_
	octave_up
	note C_
	len 96
	note D_, D_
	len 12
	note C_, D_, REST, D_
	len 24
	note D_
	len 48
	note D_, E_
	len 24
	note F#, G_
	octave_down
	note G_, B_
	octave_up
	note D_, G_, G_, F#, D_
	octave_down
	note F#, F#, G_, A_
	octave_up
	note D_, D_, F#, A_, E_, E_, G_, B_
	note E_, E_
	octave_down
	note B_
	octave_up
	note E_, D_, D_, C_
	octave_down
	note B_, A_, A_, G_, A_
	octave_up
	note C_, C_, E_, G_, C_, C_, D_
	octave_down
	note A_, B_, B_
	octave_up
	note D_, F#, E_, E_
	octave_down
	note B_, G_, A_, A_, A_, REST
	len 72
	note REST
	len 12
	note A_
	octave_up
	note C_
	snd_ret

Song01_Ch4::
	timbre $51
	len 12
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	snd_call Song01_Sub4
	song_loop

Song01_Sub4::
	loop 3
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	endloop
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $05, REST, $05, REST, $05, REST
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $02
; =============================================================================
Song02::
	song_header Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
Song02_Ch1::
	tempo $77
	timbre $80
	envelope $55
	sweep $00
	octave 3
	len 12
	note C_, REST, REST, E_, REST, C_, C#, E_
	len 24
	note G_, G_
	len 12
	note F#
	len 24
	note G_
	len 12
	note F#
	len 24
	note E_, D_
	len 12
	note C_, C#, C#, C#
	octave_down
	note G_, A_, REST
	len 24
	note G_
	len 12
	note D_, E_, G_
	octave_up
	note C_, REST, REST, E_, REST, C_, C#, E_
	len 24
	note G_, G_
	len 12
	note F#
	len 24
	note G_
	len 12
	note F#, E_, F#, D_, C_
	octave_down
	note A_, G_, E_, D_
	octave_down
	note A_
	octave_up
	note A_, D_
	octave_up
	note D_
	octave_down
	note G_
	octave_up
	note G_
	len 24
	note C_
	len 12
	note F_, REST, REST, A_, REST, F_, F#, A_
	len 24
	octave_up
	note C_, C_
	len 12
	octave_down
	note B_
	len 24
	octave_up
	note C_
	len 12
	octave_down
	note B_
	len 24
	note A_, G_
	len 12
	note F_, F#, F#, F#, C_, D_, REST
	len 24
	note C_
	len 12
	octave_down
	note G_, A_
	octave_up
	note C_
	len 12
	note F_, REST, REST, A_, REST, F_, F#, A_
	len 24
	octave_up
	note C_, C_
	len 12
	octave_down
	note B_
	len 24
	octave_up
	note C_
	len 12
	octave_down
	note B_, A_
	len 24
	note G_
	len 12
	note G_, B_, F_
	len 24
	note F#
	len 12
	note F_, G_, G#, G_, F_
	octave_down
	note A_
	octave_up
	note F_, F_
	octave 3
	len 12
	note C_, REST, REST, E_, REST, C_, C#, E_
	len 24
	note G_, G_
	len 12
	note F#
	len 24
	note G_
	len 12
	note F#
	len 24
	note E_, D_
	len 12
	note C_, C#, C#, C#
	octave_down
	note G_, A_, REST
	len 24
	note G_
	len 12
	note D_, E_, G_
	octave_up
	note D_, D_, D_, D_, D_, D_, REST
	len 24
	note D#
	len 12
	note D#, D#, D#, D#
	len 24
	note D#
	len 12
	note D#, D_, D_, D_, D_, D_, D_, REST
	len 24
	note D#
	len 12
	note D#, D#, D#, D#
	len 24
	note D#
	len 12
	note D#, D_, D_, D#, D#, D_, D_, D#
	note D#, F#, F#, REST, REST, G#, G#, REST
	note REST
	len 48
	note REST
	len 12
	note G_, G_
	len 36
	note REST
	len 12
	note A_, G_, E_, D_
	len 36
	note C_
	song_loop

Song02_Ch2::
	timbre $80
	envelope $66
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 3
	len 12
	note REST
	len 24
	note C#
	len 12
	note A_, REST, E_, E_, A_
	octave_up
	len 24
	note C_, C_
	len 12
	octave_down
	note B_
	len 24
	octave_up
	note C_
	octave_down
	len 12
	note B_
	len 24
	note A_, F#
	len 12
	note E_, E_, E_, E_
	octave_down
	octave_down
	note G_, A_, REST
	len 24
	note G_
	len 12
	note D_, E_, G_
	octave 3
	len 12
	note REST
	len 24
	note C#
	len 12
	note A_, REST, E_, E_, A_
	octave_up
	len 24
	note C_, C_
	len 12
	octave_down
	note B_
	len 24
	octave_up
	note C_
	octave_down
	len 12
	note B_
	octave_down
	note E_, F#, D_, C_
	octave_down
	note A_, G_, E_, D_
	octave_down
	note A_
	octave_up
	note A_, D_
	octave_up
	note D_
	octave_down
	note G_
	octave_up
	note G_
	octave_up
	len 24
	note E_
	octave 3
	len 12
	note REST
	len 24
	note F#
	len 12
	octave_up
	note D_, REST
	octave_down
	note A_, A_
	octave_up
	note D_
	len 24
	note F_, F_
	len 12
	note E_
	len 24
	note F_
	len 12
	note E_
	len 24
	note D_
	octave_down
	note B_
	len 12
	note A_, A_, A_, A_
	octave_down
	note C_, D_, REST
	len 24
	note C_
	len 12
	octave_down
	note G_, A_
	octave_up
	note C_
	octave 3
	len 12
	note REST
	len 24
	note F#
	len 12
	octave_up
	note D_, REST
	octave_down
	note A_, A_
	octave_up
	note D_
	len 24
	note F_, F_
	len 12
	note E_
	len 24
	note F_
	len 12
	note E_, D_
	len 24
	octave_down
	note B_, REST
	len 12
	note A_
	len 24
	note A_
	len 12
	note A_
	octave_down
	note G_, G#, G_, F_
	octave_down
	note A_
	octave_up
	note F_
	octave_up
	note A_
	octave 3
	len 12
	note REST
	len 24
	note C#
	len 12
	note A_, REST, E_, E_, A_
	octave_up
	len 24
	note C_, C_
	len 12
	octave_down
	note B_
	octave_up
	len 24
	note C_
	octave_down
	len 12
	note B_
	len 24
	note A_, F#
	len 12
	note E_, E_, E_, E_
	octave_down
	octave_down
	note G_, A_, REST
	len 24
	note G_
	len 12
	note D_, E_, G_
	loop 2
	octave 3
	len 12
	note G#, G#, G#, G#, G#, G#, REST
	len 24
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_
	len 12
	note A_
	endloop
	note G#, G#, A_, A_, G#, G#, A_, A_
	octave_up
	note C_, C_, REST, REST, D_, D_, REST, REST
	len 48
	note REST
	len 12
	note C#, C#
	len 24
	note REST
	len 12
	note REST
	octave_down
	note A_, G_, E_, D_
	len 36
	note C_
	song_loop

Song02_Ch3::
	transpose 12
	octave 0
	len 24
	note A_
	octave_up
	note A_
	len 12
	note C#
	len 24
	note D_
	len 12
	note G_
	len 24
	note E_
	octave_up
	note E_
	octave_down
	note D_
	octave_up
	note D_
	octave_down
	note C#
	len 12
	octave_up
	note C#, C#
	octave_down
	octave_down
	len 24
	note A_
	octave_up
	note A_
	octave_down
	note G_
	octave_up
	note G_, E_, G_
	octave_down
	len 24
	note A_
	octave_up
	note A_
	len 12
	note C#
	len 24
	note D_
	len 12
	note G_
	len 24
	note E_
	octave_up
	note E_
	octave_down
	note D_
	octave_up
	note D_
	octave_down
	note C#
	len 12
	octave_up
	note C#, C#
	octave_down
	octave_down
	len 24
	note A_
	octave_up
	note A_
	octave_down
	note G_
	octave_up
	note G_, E_
	len 12
	octave_down
	note A_
	octave_up
	note C#
	octave 1
	len 24
	note D_
	octave_up
	note D_
	octave_down
	len 12
	note F#
	len 24
	note G_
	len 12
	octave_up
	note C_
	len 24
	octave_down
	note A_
	octave_up
	note A_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note F#
	len 12
	octave_up
	note F#, F#
	octave_down
	len 24
	note D_
	octave_up
	note D_
	octave_down
	note C_
	octave_up
	note C_
	octave_down
	octave_down
	note A_
	octave_up
	note C_
	octave 1
	len 24
	note D_
	octave_up
	note D_
	octave_down
	len 12
	note F#
	len 24
	note G_
	len 12
	octave_up
	note C_
	len 24
	octave_down
	note A_
	octave_up
	note A_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note F#
	len 12
	octave_up
	note F#, F#
	octave_down
	len 24
	note D_
	octave_up
	note D_
	octave_down
	note C_
	octave_up
	note C_
	octave_down
	octave_down
	note A_
	octave_up
	note C_
	octave 0
	len 24
	note A_
	octave_up
	note A_
	len 12
	note C#
	len 24
	note D_
	len 12
	note G_
	len 24
	note E_
	octave_up
	note E_
	octave_down
	note D_
	octave_up
	note D_
	octave_down
	note C#
	len 12
	octave_up
	note C#, C#
	octave_down
	octave_down
	len 24
	note A_
	octave_up
	note A_
	octave_down
	note G_
	octave_up
	note G_, E_, G_
	len 24
	note E_, E_
	len 12
	note D_, E_, REST
	len 24
	octave_down
	note F#
	len 12
	octave_up
	note F#
	len 24
	octave_down
	note F#
	len 12
	octave_up
	note D_, F#, REST, F#
	len 24
	note E_, E_
	len 12
	note D_, E_, REST
	len 24
	octave_down
	note F#
	len 12
	octave_up
	note F#
	len 24
	octave_down
	note F#
	len 12
	octave_up
	note D_, F#, REST, F#
	len 12
	note E_, E_, F_, F_, E_, E_, F_, F_
	note G#, G#, REST, REST, A_, A_, REST, REST
	len 48
	note REST
	len 12
	octave_down
	note A_, A_
	len 36
	note REST
	len 12
	octave_up
	note A_, G_, E_, D_
	len 36
	note C_
	song_loop

Song02_Ch4::
	timbre $51
	len 24
	snd_call Song02_Sub1
	len 48
	note REST
	len 12
	note $05, $05
	len 36
	note REST
	len 12
	note $05, $05, $05, $05
	len 36
	note $05
	song_loop

Song02_Sub1::
	loop 13
	note $02, $02, $05, $02, $02, $02, $05, $02
	endloop
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $03
; =============================================================================
Song03::
	song_header Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
Song03_Ch1::
	tempo $81
	timbre $80
	envelope $57
	sweep $00
	octave 3
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note C#
	len 72
	note D_
	octave_down
	note B_
	len 48
	note REST, A_
	len 24
	note A_
	len 72
	octave_up
	note C#
	len 48
	octave_down
	note A_
	octave_up
	len 96
	note D_
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note D_, F#
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note E_
	len 72
	note F#, D_
	octave_down
	len 48
	note B_
	octave_up
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note C#
	len 72
	note D_
	octave_down
	note B_
	len 48
	note REST, A_
	len 24
	note A_
	len 72
	octave_up
	note C#
	len 48
	octave_down
	note A_
	octave_up
	len 96
	note D_
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note D_, F#
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note E_
	len 72
	note F#, D_
	octave_down
	len 48
	note B_
	len 72
	note B_
	len 96
	octave_up
	note C#
	len 24
	note REST
	len 24
	note D_
	octave_down
	note B_
	len 72
	octave_up
	note D_
	len 24
	note D_
	len 48
	octave_down
	note B_
	len 24
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	len 192
	note A_
	len 48
	note A_, A_, G_, F#
	len 96
	octave_up
	note D_
	len 24
	note D_, C#
	len 48
	octave_down
	note B_
	len 96
	note A#
	len 48
	octave_up
	note D_, F_
	len 144
	note D_
	len 48
	octave_down
	note A_
	len 192
	octave_up
	note C#
	len 24
	note REST
	len 48
	octave_down
	note A_, G_
	octave_up
	note D_, D_
	octave_down
	note A_
	len 24
	octave_up
	note G_
	len 12
	note D_, E_
	len 24
	note D_
	len 48
	note D_
	len 24
	note REST
	octave_down
	len 48
	note A_, G_
	octave_up
	note D_, D_
	octave_down
	note A_
	octave_up
	len 24
	note G_
	len 12
	note D_, E_
	len 24
	note D_
	len 48
	note D_
	song_loop

Song03_Ch2::
	timbre $80
	envelope $68
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 3
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 48
	note G_
	len 24
	note F#
	len 72
	note D_
	len 48
	octave_down
	note B_
	len 72
	octave_up
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note E_, A_
	len 48
	octave_up
	note C#
	len 192
	octave_down
	note B_
	len 72
	note F_
	len 96
	note G_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 48
	note G_
	len 24
	note F#
	len 72
	note D_
	len 48
	octave_down
	note B_
	octave_up
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note E_, A_
	len 48
	octave_up
	note C#
	len 192
	octave_down
	note B_
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note F#
	len 24
	note REST
	len 72
	note F#
	len 96
	note F#
	len 24
	note REST
	len 24
	note E_, C#, D_
	len 48
	note E_
	len 24
	note G_, F#, E_
	len 96
	note D#
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note E_, F#
	len 96
	note G_
	len 72
	note G_
	len 24
	note G_
	len 144
	note G_
	len 48
	note A_
	len 12
	note F#, G_
	len 144
	note F#
	len 24
	note REST
	len 24
	note REST
	len 48
	octave_down
	note A_
	len 72
	note D_
	len 48
	octave_down
	note A_
	octave_up
	len 48
	note G_
	octave_up
	note D_
	octave_down
	note A_, A_
	octave_up
	note G_, D_
	len 12
	note F#, G_
	len 48
	note F#
	len 24
	octave_down
	note A_
	len 48
	note G_
	octave_up
	note D_
	octave_down
	note A_, A_
	octave_up
	note G_, D_
	len 12
	note F#, G_
	len 48
	note F#
	octave_down
	len 24
	note A_
	song_loop

Song03_Ch3::
	transpose 12
	octave 1
	len 24
	note D_, A_
	len 96
	octave_up
	note D_
	octave_down
	len 24
	note REST, D_, D#, A_
	len 96
	octave_up
	note D#
	len 24
	note REST
	octave_down
	note D#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	octave_down
	note REST, E_
	octave_down
	note A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST, A_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	octave_down
	note REST, G_, F#
	octave_up
	note C#
	len 96
	note F#
	octave_down
	len 24
	note REST, F#, E_, B_
	octave_up
	len 96
	note E_
	octave_down
	len 24
	note REST, E_
	len 72
	note A#
	len 96
	octave_up
	note C_
	octave_down
	len 12
	note C_, C#
	len 24
	note D_, A_
	len 96
	octave_up
	note D_
	len 24
	octave_down
	note REST, D_, D#, A_
	octave_up
	len 96
	note D#
	len 24
	octave_down
	note REST, D#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	octave_down
	note REST, E_
	octave_down
	note A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST, A_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	octave_down
	note REST, G_, F#
	octave_up
	note C#
	len 96
	note F#
	len 24
	octave_down
	note REST, F#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	note REST
	octave_down
	note E_
	len 48
	note A_
	len 24
	octave_up
	note E_
	len 48
	note A_
	octave_down
	len 24
	note A_
	octave_up
	note E_, A_
	octave_down
	note G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	note REST
	octave_down
	note G_, A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST
	octave_down
	note A_, F#
	octave_up
	note C#
	len 96
	note F#
	len 24
	octave_down
	note REST, F#
	octave_down
	note B_
	octave_up
	note F#
	len 96
	note B_
	len 24
	note REST, B_
	octave_up
	note E_
	octave_down
	note B_
	len 96
	octave_up
	note E_
	len 24
	note REST
	octave_down
	note E_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	note REST
	octave_down
	note G_, D_, A_
	octave_up
	note D_
	len 48
	note E_, F#
	len 192
	note E_
	len 24
	note REST
	len 192
	octave_down
	note A_
	len 72
	note REST
	octave_up
	len 96
	note A_
	len 192
	octave_down
	note A_
	len 24
	note REST
	len 72
	note REST
	len 48
	octave_up
	note A_
	len 72
	octave_down
	note A_
	song_loop

Song03_Ch4::
	timbre $51
	len 12
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	snd_call Song03_Sub1
	song_loop

Song03_Sub1::
	loop 3
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	endloop
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $05, REST, $05, REST, $05, REST
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $04
; =============================================================================
Song04::
	song_header Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
Song04_Ch1::
	tempo $7C
	timbre $80
	envelope $56
	sweep $00
	transpose 12
	octave 2
	len 96
	note REST
	len 24
	note C_, E_, B_
	len 144
	note G_
	snd_call Song04_Sub1
	len 72
	note A_
	len 96
	note G_
	len 24
	note REST
	len 24
	note G_, G_, F#, E_, C_, E_, B_
	len 144
	note G_
	snd_call Song04_Sub1
	len 72
	note A_
	len 96
	note G_
	len 24
	note REST
	len 72
	octave_up
	note C_
	len 12
	note C_, C_
	len 36
	note C_, C_
	len 24
	note C_
	len 96
	octave_down
	note B_
	len 48
	note A_
	octave_up
	note D_
	len 72
	note C_
	len 12
	note C_, C_
	len 36
	note C_, C_
	len 24
	note C_
	octave_down
	len 72
	note B_
	len 12
	note B_, A_
	len 36
	note B_
	octave_up
	note C_
	len 24
	note D_
	len 72
	note D_
	len 12
	note D_, D_
	len 36
	note D_, D_
	len 24
	note D_
	octave_down
	len 72
	note G_
	len 12
	note G_, G_
	len 36
	note G_, A_
	len 24
	note A#
	octave_up
	len 48
	note F_
	len 12
	note F_, E_
	len 24
	note F_
	len 48
	note G_
	len 12
	note G_, F_
	len 24
	note D_
	len 192
	note E_
	song_loop

Song04_Sub1::
	octave 2
	len 12
	note F#, G_
	len 24
	note A_, B_
	len 48
	octave_up
	note D_
	octave_down
	len 72
	note B_
	len 24
	note G_, B_
	len 72
	note D_
	len 24
	note D_
	len 12
	note D_, D_
	len 24
	note D_
	len 48
	note E_
	len 24
	note F#
	len 96
	note G_
	len 24
	note C_, E_, B_
	len 144
	note G_
	len 12
	note F#, G_
	len 24
	note F#, E_
	len 96
	note F_
	len 72
	note A_
	len 24
	note A_
	snd_ret

Song04_Ch2::
	transpose 12
	timbre $80
	envelope $57
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 2
	len 96
	note REST
	len 24
	note E_, G_
	octave_up
	note D_
	len 144
	octave_down
	note B_
	snd_call Song04_Sub2
	len 96
	octave_down
	note B_
	len 24
	note REST
	len 24
	note B_
	octave_up
	note D_
	octave_down
	note A_, G_, E_, G_
	octave_up
	note D_
	len 144
	octave_down
	note B_
	snd_call Song04_Sub2
	len 96
	note D_
	len 24
	note REST
	len 72
	note F_
	len 12
	note F_, E_
	len 36
	note F_, G_
	len 24
	note A_
	len 36
	note G_, D_
	len 72
	note D_
	len 48
	note REST
	len 72
	note F_
	len 12
	note F_, D#
	len 36
	note F_, G_
	len 24
	note G#
	len 144
	note G_
	len 24
	note REST
	len 12
	note F_, F#
	len 72
	note G_
	len 12
	note G_, G_
	len 36
	note G_, A_
	len 24
	note A#
	len 48
	octave_up
	note C_
	len 24
	octave_down
	note G_
	len 72
	note G_
	len 24
	note REST
	len 12
	note F_, G_
	len 48
	note A_
	len 12
	note A_, G_
	len 24
	note A_
	len 48
	note B_
	len 12
	note B_, A_
	len 24
	note G_
	len 192
	note A_
	song_loop

Song04_Sub2::
	octave 2
	len 12
	note A_, B_
	len 24
	octave_up
	note C_, D_
	len 48
	note F#
	len 72
	note D_
	len 24
	octave_down
	note B_
	octave_up
	note D_
	len 72
	octave_down
	note G_
	len 24
	note G_
	len 12
	note F#, E_
	len 24
	note F#
	len 48
	note G_
	len 24
	note A_
	len 96
	note B_
	len 24
	note E_, G_
	octave_up
	note D_
	len 144
	octave_down
	note B_
	len 12
	note A_, B_
	len 24
	note A_, G_
	len 96
	note A_
	len 72
	octave_up
	note D_
	len 96
	note C_
	snd_ret

Song04_Ch3::
	transpose 12
	octave 1
	len 24
	note C_
	octave_up
	note C_
	octave_down
	note C_, C_
	len 48
	note C_
	len 24
	note G_, C_
	snd_call Song04_Sub3
	note G_
	octave_up
	note G_, D_, G_, G_, D_
	octave_down
	note G_, B_
	octave_up
	note C_
	octave_up
	note C_
	octave_down
	note C_, C_
	len 48
	note C_
	len 24
	note G_, C_
	snd_call Song04_Sub3
	note G_
	octave_up
	note G_, D_, G_, G_, D_
	octave_down
	note G_, F#
	octave_up
	note F_, F_, F_, F_
	len 48
	note F_
	len 24
	note F_
	len 12
	note F_, F#
	octave_down
	len 24
	note G_
	octave_up
	note G_
	len 48
	octave_down
	note G_, G_
	len 24
	note G_
	len 12
	note G_, G_
	len 24
	note G#
	octave_up
	note G#
	octave_down
	note G#, G#
	len 48
	note G#
	len 24
	octave_up
	note G#
	octave_down
	note G#, G_
	octave_up
	note G_
	octave_down
	len 48
	note G_, G_
	len 24
	note G_
	len 12
	note G_, G_
	len 24
	note G_
	octave_up
	note D_, G_
	octave_down
	note G_
	len 48
	note G_
	len 24
	note G_
	len 12
	note G_, A#
	octave_up
	len 24
	note C_
	octave_up
	note C_
	octave_down
	len 48
	note C_, C_
	len 24
	note C_
	len 12
	note C_, C_
	octave_down
	len 24
	note F_
	octave_up
	note F_
	octave_down
	note F_, F_
	len 48
	note G_
	len 24
	octave_up
	note G_
	octave_down
	note G_, A_
	octave_up
	note A_
	octave_down
	note A_, A_
	len 48
	note A_, A_
	song_loop

Song04_Sub3::
	octave 1
	len 24
	note C_
	octave_up
	note C_
	octave_down
	note C_, C_, C_, C_, C_
	len 48
	note D_
	octave_up
	len 24
	note D_
	octave_down
	note D_, D_
	len 48
	note D_
	len 24
	note A_, D_, D_
	octave_up
	note D_
	octave_down
	note D_
	len 48
	note D_
	len 24
	note D_, C_
	octave_down
	note A_
	octave_up
	note E_
	octave_up
	note E_
	octave_down
	note E_, E_
	len 48
	note E_
	len 24
	note A_, E_, E_
	octave_up
	note E_
	octave_down
	note E_
	len 48
	note E_
	len 24
	note E_, E_
	len 48
	note F_
	len 24
	note F_
	octave_down
	note F_, F_
	len 48
	note F_
	octave_up
	len 24
	note F_
	octave_down
	note G_
	snd_ret

Song04_Ch4::
	timbre $51
	len 12
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	snd_call Song04_Sub4
	snd_call Song04_Sub4
	snd_call Song04_Sub4
	snd_call Song04_Sub4
	snd_call Song04_Sub4
	loop 2
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	endloop
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $05, REST, $05, REST, $05, REST
	song_loop

Song04_Sub4::
	loop 3
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	endloop
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $05, REST, $05, REST, $05, REST
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $05
; =============================================================================
Song05::
	song_header Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
Song05_Ch1::
	tempo $81
	timbre $80
	envelope $55
	sweep $00
	octave 2
	len 16
	note A#
	octave_up
	note D_, F_, A#, F_, D_
	octave_down
	note A_
	octave_up
	note C_, F_, A_, F_, C_
	octave_down
	note G_, A#
	octave_up
	note D_, G_, D_, A#
	octave_down
	note A_, A#
	octave_up
	note D#, G_, D#
	octave_down
	note A#, F_, A#
	octave_up
	note D_, F_, D_
	octave_down
	note A#, G_
	octave_up
	note C_, E_, G_, E_, C_
	octave_down
	note A#
	octave_up
	note D#, G_, D#, G_, A#, F_, A_
	octave_up
	note C_
	octave_down
	note A_
	octave_up
	note C_, F_
	octave_down
	octave_down
	note A#
	octave_up
	note D_, F_, A#, F_, D_
	octave_down
	note A_
	octave_up
	note C_, F_, A_, F_, C_
	octave_down
	note G_, A#
	octave_up
	note D_, G_, D_
	octave_down
	note A#, G_, A#
	octave_up
	note D#, G_, D#
	octave_down
	note A#, F_, A#
	octave_up
	note D_, F_, D_
	octave_down
	note B_, G_
	octave_up
	note C_, E_, G_, E_, C_
	octave_down
	note A#
	octave_up
	note D#, G_, D#, G_, A#, F_, A_
	octave_up
	note C_
	octave_down
	note A_
	octave_up
	note C_, F_, F#, F#, F#, C#, F#, C#
	note F#, F#, F#, C#, F#, C#, F_, D#
	note F_, D#, C_
	octave_down
	note A#, A_, G_, F_, D#, D_
	octave_down
	note A#
	len 48
	note A_
	octave_up
	len 32
	note C_
	len 16
	note F_
	len 96
	note F_
	len 16
	note F_, D#, C_
	len 32
	note D_
	len 48
	note C_
	len 16
	note REST
	len 48
	octave_down
	note B_
	len 32
	note A#
	len 16
	note A#, REST, REST, REST
	len 32
	note A#
	len 16
	note A#
	len 48
	note REST
	len 32
	note F_
	len 16
	note F_
	len 48
	note REST
	len 32
	note F_
	len 16
	note F_
	len 32
	note REST
	len 16
	note F_
	len 32
	note E_
	len 16
	note E_
	len 48
	note REST
	len 32
	note E_
	len 16
	note E_
	len 32
	note REST
	len 16
	note E_, F_, A_
	octave_up
	note C_, C_
	octave_down
	note A#, A_, A_, F_, A_
	octave_up
	note C_, D_, D#
	len 96
	note F_
	octave_down
	len 16
	note A_, REST, A_
	len 48
	note A_
	len 32
	note A#
	len 16
	note G_
	len 48
	note D#
	len 32
	note F_
	len 16
	note C_
	len 48
	octave_down
	note A_
	len 96
	note A#
	octave_up
	note C_
	len 16
	note C_, D_, D#
	len 48
	note F_
	len 16
	note D#, F_, A#
	octave_up
	note C_, D_, D#
	len 96
	note F_
	len 16
	octave_down
	note A_, REST, A_
	len 48
	note A_
	len 32
	note A#
	len 16
	note G_
	len 48
	note D#
	len 32
	note F_
	len 16
	note C_
	len 48
	octave_down
	note A_
	len 96
	note A#
	octave_up
	note C_
	len 16
	note C_, D_, D#
	len 48
	note F_
	len 16
	note D_, F_, A#
	octave_up
	note C_, D_, D#
	song_loop

Song05_Ch2::
	timbre $80
	envelope $67
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	transpose 12
	octave 2
	len 48
	note A#
	len 16
	note A#, A_, A#
	len 48
	octave_up
	note C_, F_, D_
	len 16
	octave_down
	note A#
	octave_up
	note C_, D_
	len 32
	note D#
	len 16
	note D_
	len 32
	note C_
	len 16
	octave_down
	note A#
	len 32
	note F_
	len 16
	note A#
	len 32
	octave_up
	note C_
	len 16
	note D_, E_, F_, E_
	len 32
	note C_
	len 16
	octave_down
	note G_
	len 32
	note G_
	len 16
	note A#
	len 32
	octave_up
	note D#
	len 16
	note D#
	len 48
	note D_, C_
	octave_down
	note A#
	len 16
	note A#, A_, A#
	len 48
	octave_up
	note C_, F_, D_
	len 16
	octave_down
	note A#
	octave_up
	note C_, D_
	len 32
	note D#
	len 16
	note D_
	len 32
	note C_
	len 16
	octave_down
	note A#
	len 32
	note F_
	len 16
	note A#
	octave_up
	len 32
	note C_
	len 16
	note D_, E_, F_, E_
	len 32
	note C_
	len 16
	octave_down
	note G_
	len 32
	note G_
	len 16
	note A#
	len 32
	octave_up
	note D#
	len 16
	note D#, F_, G_, F_
	len 32
	note D#
	len 16
	note C_
	len 192
	octave_down
	note A#, A#
	len 96
	note REST
	len 16
	note A_, A#, A_
	len 32
	octave_up
	note C_
	len 16
	octave_down
	note G_
	len 144
	note F_
	len 48
	note E_
	len 32
	note D#
	len 16
	note D#
	len 48
	note REST
	len 16
	note G_, G_, G_
	len 32
	note A#
	len 16
	octave_up
	note D#
	len 32
	note D_
	len 16
	note C_
	len 48
	octave_down
	note A#, REST
	len 32
	note REST
	len 16
	note A#
	len 48
	octave_up
	note C_
	len 16
	note C_, D_, C_
	len 48
	note C_
	len 16
	note C_, D_, C_, F_, F_, F_, D#, D_
	note C_
	len 96
	note C_
	octave_down
	len 16
	note F_, A#
	octave_up
	note C_
	len 48
	note D_
	len 16
	note C_
	octave_down
	note A#
	octave_up
	note C_
	len 48
	note F_
	len 32
	note G_
	len 16
	note D#
	len 48
	octave_down
	note A#, REST, REST
	octave_up
	len 16
	note D_, D_, D_, D_, D#, F_
	len 48
	note D#
	len 16
	note D#, D_, C_
	len 192
	note D_
	octave_down
	len 16
	note F_, A#
	octave_up
	note C_
	len 48
	note D_
	len 16
	note C_
	octave_down
	note A#
	octave_up
	note C_
	len 48
	note F_
	len 32
	note G_
	len 16
	note D#
	len 48
	octave_down
	note A#, REST
	len 16
	note A_, A#
	octave_up
	note C_
	len 48
	note D_
	len 16
	note D_, D#, F_
	len 48
	note D#
	len 16
	note D#, F_, G_
	len 192
	note F_
	song_loop

	db $17                                 ; unreachable (follows a halting command)
Song05_Ch3::
	transpose 12
	octave 0
	len 24
	note A#, REST, A#, REST, F_, REST, F_, REST
	note G_, REST
	octave_up
	note D_, REST, D#, REST, D#, REST, D_, REST
	note D_, REST, C_, REST, C_, REST
	octave_down
	note A#, REST
	octave_up
	note A#, REST, F_, REST
	octave_down
	note F_, REST, A#, REST, A#, REST, F_, REST
	note F_, REST, G_, REST
	octave_up
	note D_, REST, D#, REST, D#, REST, D_, REST
	note D_, REST, C_, REST, C_, REST
	octave_down
	note A#, REST, A#, REST
	len 16
	note F_, REST, F_, F_, REST, F_
	len 24
	note F#, REST, A#, REST
	octave_up
	note C#, REST, F#, REST, A#, REST, F_, REST
	note D_, REST
	octave_down
	note A#, REST, F_, REST
	octave_up
	note C_, REST, F_, REST, F_, REST
	octave_down
	note F_, REST
	octave_up
	note C_, REST, F_, REST, E_, REST, D#, REST
	note D#, REST
	octave_down
	note A#, REST
	octave_up
	note D#, REST, D_, REST
	octave_down
	note F_, REST, A#, REST
	octave_up
	note D_, REST, C_, REST
	octave_down
	note G_, REST, A#, REST
	octave_up
	note C_, REST
	octave_down
	note F_, REST, F_, REST
	len 16
	note F_, REST
	octave_up
	note C_, C_, REST, F_
	len 24
	octave_down
	note A#, REST, A#, REST, A_, REST, A_, REST
	note G_, REST, G_, REST, F_, REST, F_, REST
	note G_, REST, G_, REST, G#, REST, G#, REST
	note A#, REST, A#, REST
	len 16
	note F_, REST, A#, A#, REST
	octave_up
	note F_
	len 24
	octave_down
	note A#, REST, A#, REST, A_, REST, A_, REST
	note G_, REST, G_, REST, F_, REST, F_, REST
	note G_, REST, G_, REST, G#, REST, G#, REST
	len 16
	note A#, REST
	octave_up
	note A#
	octave_down
	note A#
	octave_up
	note D_, A#
	octave_down
	note A#
	octave_up
	note A#
	octave_down
	note A#, A#
	octave_up
	note A#, A#
	song_loop

Song05_Ch4::
	timbre $51
	len 16
	snd_call Song05_Sub1
	snd_call Song05_Sub1
	snd_call Song05_Sub1
	snd_call Song05_Sub1
	snd_call Song05_Sub1
	snd_call Song05_Sub1
	song_loop

Song05_Sub1::
	loop 3
	note $02, $02, $02, $05, REST, $02, $02, $02
	note $02, $05, REST, $02
	endloop
	note $02, $02, $02, $05, REST, $02, $05, $05
	note $05, $05, $05, $05
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $06
; =============================================================================
Song06::
	song_header Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song06_Ch1::
	tempo $82
	timbre $80
	envelope $57
	sweep $00
	octave 2
	len 36
	note A_
	len 12
	note F#
	len 24
	note REST
	len 96
	note A_
	len 24
	note REST
	len 36
	note G_
	len 12
	note G_
	len 24
	note REST, G_
	len 48
	note B_, B_
	len 36
	note F#, D_
	len 96
	note A_
	len 24
	note REST
	len 36
	octave_up
	note D_
	len 12
	note D_
	len 24
	note REST, D_
	len 48
	note C#, D_
	len 36
	note C#
	len 12
	note C#
	len 24
	note REST
	len 96
	note C#
	len 24
	note REST
	len 36
	note C_
	len 12
	note C_
	len 24
	note REST, C_
	len 48
	note E_, C_
	len 36
	note D_
	len 12
	note D_
	len 24
	note REST
	len 96
	note D_
	len 24
	note REST
	len 36
	note D_
	len 12
	note D_
	len 24
	note REST
	len 96
	note C#
	len 24
	note REST
	octave_down
	len 36
	note B_
	len 12
	note B_
	len 24
	note REST
	len 96
	note B_
	len 24
	note REST
	len 36
	note A#
	len 12
	note A#
	len 24
	note REST, A#
	len 48
	note A#, A#
	len 36
	note B_
	len 12
	note B_
	len 24
	note REST
	len 96
	note B_
	len 24
	note REST
	len 36
	note A#
	len 12
	note A#
	len 24
	note REST
	len 48
	note A#, A#
	len 24
	note A#
	len 36
	note B_
	len 12
	note B_
	len 24
	note REST
	len 96
	note B_
	len 24
	note REST
	len 36
	note A#
	len 12
	note A#
	len 24
	note REST, A#
	len 48
	note A#, A#
	len 36
	note B_
	len 12
	note B_
	len 24
	note REST
	len 96
	note B_
	len 72
	octave_up
	note D_
	len 48
	note C#
	octave_down
	len 24
	note A_
	len 72
	note A_
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST
	len 96
	note A_
	len 24
	note REST
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST, A_
	len 48
	note A_, A_
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST
	len 96
	note A_
	len 72
	note G_
	len 24
	note REST
	len 48
	note A#
	len 72
	note A#
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST
	len 96
	note A_
	len 24
	note REST
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST, A_
	len 48
	note A_, A_
	len 36
	note A_
	len 12
	note A_
	len 24
	note REST
	len 96
	note A_
	len 48
	note B_
	len 24
	note B_, B_
	len 96
	octave_up
	note C#
	len 24
	note C#
	song_loop

	db $17                                 ; unreachable (follows a halting command)
Song06_Ch2::
	timbre $80
	envelope $68
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 3
	len 36
	note C#
	octave_down
	len 12
	note A_
	len 48
	note REST, REST
	len 24
	note REST
	len 12
	note A_
	octave_up
	note C#
	len 24
	octave_down
	note B_
	len 12
	note B_
	len 36
	note B_
	len 12
	note B_
	octave_up
	note D_
	len 48
	note E_, D_
	len 24
	note C#
	len 12
	octave_down
	note A_
	len 72
	note F#
	len 12
	note REST, REST, REST
	len 48
	note REST, REST, REST, REST
	len 24
	note REST
	len 12
	note A_, B_
	len 24
	note G#
	len 12
	note A_
	len 36
	note G#
	len 12
	note E_
	len 72
	note C#
	len 12
	octave_down
	note A_
	octave_up
	note C#, E_
	len 24
	note G_
	len 12
	note A_
	len 36
	octave_up
	note C_
	len 24
	note E_
	len 12
	note F#, G_, F#, E_
	len 24
	note F#
	len 12
	note G_, F#
	len 72
	note F#, A_
	len 48
	note D_
	len 24
	note F#
	len 12
	note G_
	len 36
	note F#
	len 96
	note E_
	len 24
	note REST
	len 24
	note F#
	len 12
	note F#
	len 72
	note D_
	len 24
	note REST
	len 12
	note REST, REST, REST, D_, F#
	len 36
	note E_
	len 12
	note E_
	len 24
	note E_
	len 48
	note G_
	len 24
	note F#, E_, F#
	len 72
	note D_
	len 96
	note F#
	len 12
	note E_, F#
	len 48
	note E_
	len 144
	note REST
	len 96
	note REST
	len 12
	note F#, E_
	len 24
	note D_, D_, F#, G_
	len 12
	note D_
	len 48
	note G_
	len 12
	note REST
	len 48
	note G_, A_
	len 24
	note F#
	len 12
	note G_
	len 72
	note F#
	len 12
	note REST, REST, REST
	len 24
	note REST
	len 72
	note A_
	len 48
	note G_
	len 24
	note F#
	len 72
	note E_
	len 48
	note REST
	len 24
	note F#, REST
	len 36
	note E_
	len 12
	note F#
	len 24
	note REST
	len 48
	note G_
	len 24
	note G_, F#, REST, E_
	len 72
	note F#
	len 48
	note REST
	len 24
	note F#, REST
	len 36
	note E_
	len 12
	note F#
	len 24
	note REST
	len 96
	note E_
	len 48
	note G_
	len 24
	note F#, E_, F#
	len 48
	note REST
	len 24
	note F#, REST
	len 36
	note E_
	len 12
	note F#
	len 24
	note REST
	len 48
	note G_
	len 24
	note G_, F#, REST, E_
	len 72
	note F#
	len 48
	note REST
	len 24
	note F#, REST, E_, F#, REST
	len 96
	note G_
	len 96
	note A_
	len 12
	octave_down
	note F#, A_
	song_loop

	db $17                                 ; unreachable (follows a halting command)
Song06_Ch3::
	transpose 12
	octave 1
	len 36
	note D_
	len 12
	octave_up
	note D_, REST
	octave_down
	note D_
	len 24
	note D_
	len 12
	octave_down
	note F#
	octave_up
	note F#, REST, F#
	len 24
	octave_down
	note A_, B_
	len 36
	octave_up
	note C_
	octave_up
	len 12
	note C_
	octave_down
	len 24
	note E_
	octave_down
	note G_
	len 12
	note G_, G_
	len 24
	note A_
	octave_up
	note C_
	len 36
	octave_down
	note B_
	octave_up
	len 12
	note B_
	len 12
	note REST
	octave_down
	note B_
	len 24
	note B_
	len 48
	note F#, B_
	octave_up
	len 36
	note E_
	len 12
	note E_
	len 24
	note REST, D_, E_
	len 12
	note E_, E_
	len 24
	note F#, G_
	octave_down
	len 36
	note A_
	len 12
	octave_up
	note A_, REST
	octave_down
	note A_
	len 24
	note A_
	octave_up
	len 48
	note E_, F#
	octave_down
	len 36
	note A_
	octave_up
	len 12
	note A_
	len 24
	note REST, E_
	octave_down
	note A_
	len 12
	note A_, A_
	len 24
	note A_, G#
	len 36
	note G_
	len 12
	octave_up
	note G_
	octave_down
	len 12
	note REST, G_
	len 24
	note G_
	len 12
	note G_, A_
	len 24
	note G_
	len 24
	note B_, G_
	len 36
	note A_
	octave_up
	len 12
	note A_, REST, A_
	len 36
	octave_down
	note A_
	len 12
	octave_up
	note A_, REST, G_
	len 24
	note C#, E_
	loop 3
	octave 0
	len 36
	note G_
	len 12
	octave_up
	note G_, REST
	octave_down
	note G_
	len 24
	note G_
	len 12
	note G_
	octave_up
	note F#, REST, G_
	len 24
	octave_down
	note F#, G_
	len 36
	note G_
	octave_up
	len 12
	note G_
	len 24
	note REST, E_
	octave_down
	note G_
	len 12
	note G_, G_
	len 24
	note A_, A#
	endloop
	len 36
	note G_
	octave_up
	len 12
	note G_, REST
	octave_down
	note G_
	len 24
	note G_
	len 12
	note G_
	octave_up
	note F#, REST, G_
	len 24
	octave_down
	note G_
	len 36
	note A_
	len 12
	octave_up
	note A_
	octave_down
	len 24
	note A_, REST
	octave_up
	note E_
	octave_down
	note A_
	len 12
	note A_, A_
	len 24
	note G_, A_
	octave_up
	len 36
	note D_
	len 12
	octave_up
	note D_, REST
	octave_down
	note D_
	len 24
	note D_
	len 12
	octave_down
	note F#
	octave_up
	note F#, REST, F#
	len 24
	octave_down
	note A_, B_
	octave_up
	len 36
	note C_
	len 12
	octave_up
	note C_
	len 24
	note REST
	octave_down
	note E_
	octave_down
	note F#
	len 12
	note F#, F#
	len 24
	note A_
	octave_up
	note C_
	len 36
	octave_down
	note B_
	octave_up
	len 12
	note B_, REST
	octave_down
	note B_
	len 24
	note B_
	len 48
	note F#
	len 24
	note B_
	len 36
	note A#
	octave_up
	len 12
	note A#
	octave_down
	len 24
	note A#, REST
	len 48
	note F#
	len 12
	octave_up
	note F#, F#
	octave_down
	len 24
	note F#
	octave_up
	note F#
	len 36
	note D_
	len 12
	octave_up
	note D_, REST
	octave_down
	note D_
	len 24
	note D_
	len 12
	octave_down
	note F#
	octave_up
	note F#, REST, F#
	len 24
	octave_down
	note A_, B_
	octave_up
	len 36
	note C_
	len 12
	octave_up
	note C_
	len 24
	note REST
	octave_down
	note E_
	octave_down
	note F#
	len 12
	note F#, F#
	len 24
	note A_
	octave_up
	note C_
	octave_down
	len 36
	note B_
	len 12
	octave_up
	note B_, REST
	octave_down
	note B_
	len 24
	note B_
	len 48
	note F#
	len 24
	note B_, A_
	len 36
	note A_
	octave_up
	len 12
	note A_, REST
	octave_down
	note A_
	len 24
	note A_
	len 48
	note E_, F#
	song_loop

Song06_Ch4::
	timbre $51
	len 12
	snd_call Song06_Sub1
	snd_call Song06_Sub1
	snd_call Song06_Sub1
	snd_call Song06_Sub1
	snd_call Song06_Sub1
	snd_call Song06_Sub1
	song_loop

Song06_Sub1::
	loop 3
	note $02, REST, $02, $02, $05, REST, $02, $02
	note $02, REST, $02, $02, $05, REST, $02, $02
	endloop
	note $02, REST, $02, $02, $05, REST, $02, $02
	note $05, $05, REST, $05, $05, $05, $05, $05
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $07
; =============================================================================
Song07::
	song_header Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
Song07_Ch1::
	tempo $A2
	timbre $80
	envelope $57
	sweep $00
	octave 2
	len 48
	note REST
	len 32
	note G_
	len 16
	note B_
	len 48
	octave_up
	note C#
	len 32
	note C#
	len 96
	note D_
	stop_track

Song07_Ch2::
	timbre $80
	envelope $59
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 2
	len 16
	note A_
	octave_up
	note D_, E_, G_, F#, D_
	len 48
	note A_
	len 32
	note E_
	len 96
	note F#
	stop_track

Song07_Ch3::
	transpose 12
	octave 2
	len 48
	note D_
	octave_down
	note B_, A_
	len 32
	octave_up
	note C#
	len 96
	note D_
	stop_track

Song07_Ch4::
	timbre $51
	stop_track

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $08  (not referenced by SongTable - unused)
; An alternate mix of song $03: the data is identical except for the
; envelope values of channels 1 and 2 ($68/$78 instead of $57/$68).
; =============================================================================
Song08::
	song_header Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
Song08_Ch1::
	tempo $81
	timbre $80
	envelope $68
	sweep $00
	octave 3
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note C#
	len 72
	note D_
	octave_down
	note B_
	len 48
	note REST, A_
	len 24
	note A_
	len 72
	octave_up
	note C#
	len 48
	octave_down
	note A_
	octave_up
	len 96
	note D_
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note D_, F#
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note E_
	len 72
	note F#, D_
	octave_down
	len 48
	note B_
	octave_up
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note C#
	len 72
	note D_
	octave_down
	note B_
	len 48
	note REST, A_
	len 24
	note A_
	len 72
	octave_up
	note C#
	len 48
	octave_down
	note A_
	octave_up
	len 96
	note D_
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note D_, F#
	len 96
	note C#
	len 24
	note REST
	octave_down
	note A_
	len 48
	octave_up
	note E_
	len 72
	note F#, D_
	octave_down
	len 48
	note B_
	len 72
	note B_
	len 96
	octave_up
	note C#
	len 24
	note REST
	len 24
	note D_
	octave_down
	note B_
	len 72
	octave_up
	note D_
	len 24
	note D_
	len 48
	octave_down
	note B_
	len 24
	note A_
	len 144
	octave_up
	note C#
	len 24
	note REST
	octave_down
	len 192
	note A_
	len 48
	note A_, A_, G_, F#
	len 96
	octave_up
	note D_
	len 24
	note D_, C#
	len 48
	octave_down
	note B_
	len 96
	note A#
	len 48
	octave_up
	note D_, F_
	len 144
	note D_
	len 48
	octave_down
	note A_
	len 192
	octave_up
	note C#
	len 24
	note REST
	len 48
	octave_down
	note A_, G_
	octave_up
	note D_, D_
	octave_down
	note A_
	len 24
	octave_up
	note G_
	len 12
	note D_, E_
	len 24
	note D_
	len 48
	note D_
	len 24
	note REST
	octave_down
	len 48
	note A_, G_
	octave_up
	note D_, D_
	octave_down
	note A_
	octave_up
	len 24
	note G_
	len 12
	note D_, E_
	len 24
	note D_
	len 48
	note D_
	song_loop

Song08_Ch2::
	timbre $80
	envelope $78
	; sweep on channel 2: KK8S only consumes the parameter on channel 1, so
	; the following $00 is executed as a note (a 1-tick blip at the start of
	; the track).  Written as "sweep $00" in the source data.
	db $1E
	note C_
	octave 3
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 48
	note G_
	len 24
	note F#
	len 72
	note D_
	len 48
	octave_down
	note B_
	len 72
	octave_up
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note E_, A_
	len 48
	octave_up
	note C#
	len 192
	octave_down
	note B_
	len 72
	note F_
	len 96
	note G_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 48
	note G_
	len 24
	note F#
	len 72
	note D_
	len 48
	octave_down
	note B_
	octave_up
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note A_
	len 24
	note REST
	len 72
	note E_, A_
	len 48
	octave_up
	note C#
	len 192
	octave_down
	note B_
	len 72
	note D_
	len 96
	note E_
	len 24
	note REST
	len 72
	note F#
	len 96
	note F#
	len 24
	note REST
	len 72
	note F#
	len 96
	note F#
	len 24
	note REST
	len 24
	note E_, C#, D_
	len 48
	note E_
	len 24
	note G_, F#, E_
	len 96
	note D#
	len 24
	note REST
	octave_down
	note B_
	octave_up
	note E_, F#
	len 96
	note G_
	len 72
	note G_
	len 24
	note G_
	len 144
	note G_
	len 48
	note A_
	len 12
	note F#, G_
	len 144
	note F#
	len 24
	note REST
	len 24
	note REST
	len 48
	octave_down
	note A_
	len 72
	note D_
	len 48
	octave_down
	note A_
	octave_up
	len 48
	note G_
	octave_up
	note D_
	octave_down
	note A_, A_
	octave_up
	note G_, D_
	len 12
	note F#, G_
	len 48
	note F#
	len 24
	octave_down
	note A_
	len 48
	note G_
	octave_up
	note D_
	octave_down
	note A_, A_
	octave_up
	note G_, D_
	len 12
	note F#, G_
	len 48
	note F#
	octave_down
	len 24
	note A_
	song_loop

Song08_Ch3::
	transpose 12
	octave 1
	len 24
	note D_, A_
	len 96
	octave_up
	note D_
	octave_down
	len 24
	note REST, D_, D#, A_
	len 96
	octave_up
	note D#
	len 24
	note REST
	octave_down
	note D#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	octave_down
	note REST, E_
	octave_down
	note A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST, A_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	octave_down
	note REST, G_, F#
	octave_up
	note C#
	len 96
	note F#
	octave_down
	len 24
	note REST, F#, E_, B_
	octave_up
	len 96
	note E_
	octave_down
	len 24
	note REST, E_
	len 72
	note A#
	len 96
	octave_up
	note C_
	octave_down
	len 12
	note C_, C#
	len 24
	note D_, A_
	len 96
	octave_up
	note D_
	len 24
	octave_down
	note REST, D_, D#, A_
	octave_up
	len 96
	note D#
	len 24
	octave_down
	note REST, D#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	octave_down
	note REST, E_
	octave_down
	note A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST, A_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	octave_down
	note REST, G_, F#
	octave_up
	note C#
	len 96
	note F#
	len 24
	octave_down
	note REST, F#, E_, B_
	octave_up
	len 96
	note E_
	len 24
	note REST
	octave_down
	note E_
	len 48
	note A_
	len 24
	octave_up
	note E_
	len 48
	note A_
	octave_down
	len 24
	note A_
	octave_up
	note E_, A_
	octave_down
	note G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	note REST
	octave_down
	note G_, A_
	octave_up
	note E_
	len 96
	note A_
	len 24
	note REST
	octave_down
	note A_, F#
	octave_up
	note C#
	len 96
	note F#
	len 24
	octave_down
	note REST, F#
	octave_down
	note B_
	octave_up
	note F#
	len 96
	note B_
	len 24
	note REST, B_
	octave_up
	note E_
	octave_down
	note B_
	len 96
	octave_up
	note E_
	len 24
	note REST
	octave_down
	note E_, G_
	octave_up
	note D_
	len 96
	note G_
	len 24
	note REST
	octave_down
	note G_, D_, A_
	octave_up
	note D_
	len 48
	note E_, F#
	len 192
	note E_
	len 24
	note REST
	len 192
	octave_down
	note A_
	len 72
	note REST
	octave_up
	len 96
	note A_
	len 192
	octave_down
	note A_
	len 24
	note REST
	len 72
	note REST
	len 48
	octave_up
	note A_
	len 72
	octave_down
	note A_
	song_loop

Song08_Ch4::
	timbre $51
	len 12
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	snd_call Song08_Sub1
	song_loop

Song08_Sub1::
	loop 3
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $02, REST, $05, REST, $02, REST
	endloop
	note $02, REST, $02, REST, $05, REST, $02, REST
	note $02, REST, $05, REST, $05, REST, $05, REST
	snd_ret

	db $1C                                 ; end-of-song marker (never read)

SECTION "ROM0 after sound engine", ROM0[$3C5F]
	INCBIN BASEROM, $3C5F, $4000 - $3C5F

SECTION "Bank 1", ROMX[$4000], BANK[1]
	INCBIN BASEROM, $4000, $4000

SECTION "Bank 2", ROMX[$4000], BANK[2]
	INCBIN BASEROM, $8000, $4000

SECTION "Bank 3", ROMX[$4000], BANK[3]
	INCBIN BASEROM, $C000, $4000

SECTION "Bank 4", ROMX[$4000], BANK[4]
	INCBIN BASEROM, $10000, $4000

SECTION "Bank 5", ROMX[$4000], BANK[5]
	INCBIN BASEROM, $14000, $4000

SECTION "Bank 6", ROMX[$4000], BANK[6]
	INCBIN BASEROM, $18000, $4000

SECTION "Bank 7", ROMX[$4000], BANK[7]
	INCBIN BASEROM, $1C000, $4000

