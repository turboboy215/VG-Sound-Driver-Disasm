; =============================================================================
; Rampart (U) [M][!] - C-lab sound engine disassembly
;
; Rebuilds the complete ROM byte-for-byte:
;     rgbasm -o rampart.o rampart_sound.asm
;     rgblink -o rampart.gb rampart.o
; Everything that is not part of the sound engine is INCBIN'd from the
; original ROM, which must be in the parent directory.
;
; Engine code, tables and SFX data : bank 0, $2EBE-$379C
; Music data                       : bank 3, $6D10-$7B12
; The VBlank handler maps bank 3 and calls Sound_Update every frame; SFX are
; requested by writing an id to wSndSFXRequest.
; See C-lab_Sound_Engine.md for the documentation of the engine and format.
; =============================================================================

DEF SND_RAM EQU $CF00
INCLUDE "clab_sound.inc"

; Game variables / hardware used by the engine
DEF wMusicOff    EQU $C401   ; options: nonzero = music off
DEF wCurROMBank  EQU $C417   ; scratch copy of the mapped ROM bank
DEF ROMX_BANK_ID EQU $4000   ; every ROMX bank of Rampart stores its number here
DEF MBC1_ROMB    EQU $2000   ; MBC1 ROM bank select

DEF BASEROM EQUS "\"../Rampart (U) [M][!].gb\""

SECTION "ROM0 before sound engine", ROM0[$0000]
	INCBIN BASEROM, $0000, $2EBE

SECTION "Sound engine", ROM0[$2EBE]

; -----------------------------------------------------------------------------
; Sound_PlaySong  (public entry point)
; In:  a = song number * 2 (index into SongTable).
; Maps ROM bank 3 (music data) and starts the song from the beginning, unless
; the player turned music off in the options (wMusicOff != 0).  The caller's
; bank is identified by the bank-number byte that every ROMX bank of Rampart
; stores at $4000, and restored afterwards.
; NOTE: Sound_StartSong calls Sound_Init, so any playing SFX is cut as well.
; -----------------------------------------------------------------------------
Sound_PlaySong::
	push af
	ld a, [ROMX_BANK_ID]                   ; number of the bank currently mapped
	ld [wCurROMBank], a
	ld a, $03                              ; music data lives in bank 3
	ld [MBC1_ROMB], a
	ld a, [wMusicOff]                      ; music switched off in options?
	or a
	jr nz, .musicOff
	pop af
	call Sound_StartSong                   ; hl = SongTable + a, start song
	ld a, [wCurROMBank]
	ld [MBC1_ROMB], a
	ret

.musicOff
	ld a, [wCurROMBank]
	ld [MBC1_ROMB], a
	pop af
	ret

; -----------------------------------------------------------------------------
; Sound_Init
; Resets the whole engine: loads the default wave, clears the work RAM,
; copies the register-address table, sets tempo 64 (1 tick/frame), turns the
; APU on (NR52 = $8F, NR50 = $77) and mutes all outputs (NR51 = 0).
; wSndStatus = 0, i.e. neither music nor SFX are processed afterwards.
; -----------------------------------------------------------------------------
Sound_Init::
	call Sound_LoadWave
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
	dec a                                  ; a = $FF
	ld [wSndSavedNR51], a                  ; default NR51 used by Sound_Resume
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
; Sound_Pause  (called by the game when it is paused)
; Stops the music (wSndStatus = $10: nonzero, but bit 0 clear), cancels any SFX,
; queues SFX $09 (the pause jingle on channel 1) and routes only channel 1 to
; the speakers (NR51 = $11).  The previous NR51 value is kept in
; wSndSavedNR51; Sound_Resume restores it.  Music channels are not silenced,
; they are only disconnected through NR51.
; -----------------------------------------------------------------------------
Sound_Pause::
	ld a, $09                              ; SFX $09 = pause jingle
	ld [wSndSFXRequest], a
	ld a, $10                              ; engine active, music halted
	ld [wSndStatus], a
	ldh a, [rNR51]
	ld [wSndSavedNR51], a
	ld a, $11                              ; only ch1 (the jingle) audible
	ldh [rNR51], a
	xor a
	ld [wSndSFXActiveMask], a
	ld [wSndSFXPriority], a
	ld [wSndSFXUsedMask], a
	ret

; -----------------------------------------------------------------------------
; Sound_LoadWave
; Copies DefaultWave into wave RAM (with the ch3 DAC off while writing).
; Also called by snd_jump ($25) on the wave channel - see SndCmd_Jump.
; -----------------------------------------------------------------------------
Sound_LoadWave::
	xor a                                  ; ch3 DAC off to allow wave RAM access
	ldh [rNR30], a
	ld hl, DefaultWave
	ld c, LOW(_AUD3WAVERAM)
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl]
	ldh [c], a
	ld a, $80                              ; ch3 DAC back on
	ldh [rNR30], a
	ret

; -----------------------------------------------------------------------------
; Sound_StartSong
; In: a = song number * 2.  (Bank 3 must be mapped.)
; -----------------------------------------------------------------------------
Sound_StartSong::
	ld hl, SongTable
	add l                                  ; hl = SongTable + a
	ld l, a
	jr nc, .l_2FA0
	inc h
.l_2FA0
	ld a, [hl+]
	ld [wSndSongPtr], a
	ld a, [hl]
	ld [wSndSongPtr+1], a
	jp Sound_InitSong

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
; Sound_Resume  (called by the game when it is unpaused)
; Music and SFX on, restore NR51, reload the wave (the pause jingle does not
; touch it, but the reload is harmless).  Also the tail of Sound_InitSong.
; -----------------------------------------------------------------------------
Sound_Resume::
	ld a, $FF                              ; music running, SFX enabled
	ld [wSndStatus], a
	ld a, [wSndSavedNR51]
	ldh [rNR51], a
	call Sound_LoadWave
.ret
	ret

; -----------------------------------------------------------------------------
; Sound_MuteAll  (unused)
; Halts the music (wSndStatus = $F0) and silences all four channels.
; -----------------------------------------------------------------------------
Sound_MuteAll::
	ld a, $FF
	ldh [rNR51], a
	ld a, $F0
	ld [wSndStatus], a
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ret

; -----------------------------------------------------------------------------
; Sound_Update  (called once per frame from the VBlank handler, bank 3 mapped)
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
	ld [wSndSweep+4], a
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
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	call Sound_ParseTrack
	ld a, [wSndSyncWaitMask]               ; did the SFX execute sfx_end ($1A)?
	and a
	jr z, .nextTrack
	; The effect has ended: silence its channel.
	; BUG: wSndChanX4 >> 1 = channel * 2 is used as the index into wSndRegNRx2
	; (it should be the channel number).  Correct for ch1 (index 0), but an
	; effect ending on ch4 (index 6 -> wSndRegNRx3+2) writes 0 to NR33
	; instead of NR42, so the noise channel is not silenced.
	ld a, [wSndChanX4]
	srl a
	add LOW(wSndRegNRx2)
	ld l, a
	ld h, HIGH(SND_RAM)
	ld c, [hl]
	xor a
	ldh [c], a                             ; NRx2 = 0 (see BUG above)
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
	; BUG: if the gate timer expires, Sound_NoteOff ends with "pop hl / ret"
	; (it is written as a command handler).  Called from here, that pops the
	; return address and returns straight to Sound_Update, so the remaining
	; (lower-numbered) channels and the song-level checks are skipped for
	; this tick, and this channel's own duration countdown is skipped too.
	; Only matters for tracks that use the gate command ($23).
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
	ld l, LOW(wSndDurationTimer)
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
	add LOW(wSndTrackStack)
	ld l, a
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
	add LOW(wSndTrackStack)
	ld l, a
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
;   wave : DAC off, NR33, NR31 = timbre*2, NR32 = 0, NR34, DAC on, NR32 = $20
;          (100% volume), NR34 = hi | $80
;   noise: NR43 = note << 4, NR42 = timbre, NR41 = 1, NR44 = $C0 (length on)
; -----------------------------------------------------------------------------
Sound_PlayNote::
	push af
	call Sound_SaveTrackPtr                ; save read pointer
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
	ld a, c
	ld c, [hl]
	ldh [c], a                             ; NRx3 = frequency lo
	ld a, [wSndTrack]
	add LOW(wSndEnvelope)                  ; envelope of this track
	ld l, a
	ld a, [wSndHWChan]
	ld e, a
	ld a, [hl]
	ld l, LOW(wSndRegNRx2)
	add hl, de
	ld c, [hl]
	ldh [c], a                             ; NRx2 = envelope
	ld a, [wSndHWChan]
	and a
	jr nz, .trigger                        ; only ch1 has a sweep unit
	ld l, LOW(wSndSweep)                   ; music track 0 uses wSndSweep+0,
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
	ld c, [hl]
	ld a, b
	set 7, a
	ldh [c], a                             ; NRx4 = frequency hi + trigger
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
	ld a, $C0                              ; trigger + length enable
	ldh [rNR44], a
	ret

.wave
	xor a
	ldh [rNR30], a                         ; ch3 DAC off
	ld a, c
	ldh [rNR33], a
	ld hl, wSndTimbre
	add hl, de
	ld a, [hl]
	add a                                  ; NR31 = timbre * 2
	ldh [rNR31], a
	xor a
	ldh [rNR32], a
	ld a, b
	ldh [rNR34], a
	or $80                                 ; = DAC on value ($80)
	ld b, a
	ldh [rNR30], a
	ld a, $20                              ; volume 100%
	ldh [rNR32], a
	ld a, b
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
	ld l, LOW(wSndDurationTimer)
	add hl, de
	ld [hl], a

; -----------------------------------------------------------------------------
; Sound_NoteOff
; Silences hardware channel wSndHWChan (unless an SFX owns it): NRx2 = 0 turns
; the DAC off; ch1/2/4 are retriggered ($80) to latch it.  For ch3 NR32 is
; cleared (the NR52 writes around it only preserve NR52).  Pops one stack
; entry and returns carry clear, i.e. it behaves like a halting command.
; -----------------------------------------------------------------------------
Sound_NoteOff::
	ld a, [wSndSFXOverride]
	and a
	jr nz, .done
	ld a, [wSndHWChan]
	add LOW(wSndRegNRx2)
	ld l, a
	ld c, [hl]
	ld a, $00
	ldh [c], a                             ; NRx2 = 0 (DAC off)
	ld a, [wSndHWChan]
	cp $02
	jr z, .wave
	add LOW(wSndRegNRx4)
	ld l, a
	ld c, [hl]
	ld a, $80
	ldh [c], a                             ; NRx4 = $80
	pop hl
	and a
	ret

.wave
	ldh a, [rNR52]                         ; NR52 = NR52 & $8B (only bit 7 matters)
	ld b, a
	and $8B
	ldh [rNR52], a
	xor a
	ldh [rNR32], a
	ld a, b
	ldh [rNR52], a
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
; Stores the NR10 value used when a ch1 note is triggered.  The load of
; wSndCurMask is left over from a channel check that is missing here (Keitai
; Keiba 8 Special only accepts the command on channel 1).
; -----------------------------------------------------------------------------
SndCmd_Sweep::
	ld a, [wSndTrack]
	add LOW(wSndSweep)
	ld e, a
	ld d, HIGH(SND_RAM)
	ld a, [wSndCurMask]                    ; loaded but never used
	pop hl
	ld a, [hl+]
	ld [de], a
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
; Continues at addr.  On the wave channel the default wave is also reloaded
; (Rampart only).
; -----------------------------------------------------------------------------
SndCmd_Jump::
	pop hl
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, [wSndHWChan]
	cp $02
	jr nz, .done
	push hl
	call Sound_LoadWave
	pop hl
.done
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
	ld l, LOW(wSndTrackStack)
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
	ld b, [hl]
	dec b
	ld a, [wSndChanX4]
	add b
	add a
	add LOW(wSndTrackStack)
	ld l, a
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
	xor a
	ldh [c], a
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
; Skips one parameter byte - but also stores it to [de], which still holds
; whatever the previous code left there (e.g. the wSndTimbre slot after a
; $1D command, or $0000-$0003 = MBC RAM-enable after Sound_ReadMusicTrack).
; Keitai Keiba 8 Special removed the store.
; -----------------------------------------------------------------------------
SndCmd_Unused21::
	pop hl
	ld a, [hl+]
	ld [de], a                             ; stray write
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
; SndCmd_Unused27  ($27 x y)
; No effect, skips two parameter bytes.
; -----------------------------------------------------------------------------
SndCmd_Unused27::
	pop hl
	inc hl
	inc hl
	scf
	ret

; -----------------------------------------------------------------------------
; SndCmd_Unused22  ($22 x)
; No effect, skips one parameter byte.
; -----------------------------------------------------------------------------
SndCmd_Unused22::
	pop hl
	inc hl
	scf
	ret

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
	db $01, $23, $45, $67, $89, $AB, $CD, $EE, $ED, $CB, $A9, $87, $65, $43, $21, $00

; -----------------------------------------------------------------------------
; SongTable
; The options-screen sound test plays songs $00-$0B; $0C-$0E are never used.
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
	dw Song08                              ; song $08 (call Sound_PlaySong with a = $10)
	dw Song09                              ; song $09 (call Sound_PlaySong with a = $12)
	dw Song0A                              ; song $0A (call Sound_PlaySong with a = $14)
	dw Song0B                              ; song $0B (call Sound_PlaySong with a = $16)
	dw Song0C                              ; song $0C (call Sound_PlaySong with a = $18)
	dw Song0D                              ; song $0D (call Sound_PlaySong with a = $1A)
	dw Song0E                              ; song $0E (call Sound_PlaySong with a = $1C)

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
	sfx_entry 3, SFX_0C                    ; SFX id $0C
	sfx_entry 3, SFX_0F                    ; SFX id $0F
	sfx_entry 3, SFX_12                    ; SFX id $12
	sfx_entry 0, SFX_15                    ; SFX id $15
	sfx_entry 3, SFX_18                    ; SFX id $18
	sfx_entry 0, SFX_1B                    ; SFX id $1B
	sfx_entry 0, SFX_1E                    ; SFX id $1E
	sfx_entry 0, SFX_21                    ; SFX id $21
	sfx_entry 3, SFX_24                    ; SFX id $24
	sfx_entry 3, SFX_27                    ; SFX id $27
	sfx_entry 3, SFX_2A                    ; SFX id $2A
	sfx_entry 0, SFX_2D                    ; SFX id $2D
	sfx_entry 3, SFX_30                    ; SFX id $30
	sfx_entry 0, SFX_33                    ; SFX id $33
	sfx_entry 3, SFX_36                    ; SFX id $36
	sfx_entry 3, SFX_39                    ; SFX id $39
	sfx_entry 3, SFX_3C                    ; SFX id $3C
	sfx_entry 0, SFX_3F                    ; SFX id $3F
	sfx_entry 0, SFX_42                    ; SFX id $42
	sfx_entry 0, SFX_45                    ; SFX id $45
	sfx_entry 0, SFX_48                    ; SFX id $48

; =============================================================================
; Sound effect data (bank 0)
; =============================================================================
SFX_03::
	envelope $FF
	timbre $C0
	sweep $00
	octave 4
	len 5
	note G_
	sfx_end

SFX_06::
	envelope $FF
	timbre $80
	sweep $00
	octave 3
	len 3
	note G_
	octave_up
	note C_, E_, G_, B_
	sfx_end

SFX_09::
	envelope $FF
	timbre $80
	sweep $A9
	octave 3
	len 8
	note C_
	sweep $AB
	octave 2
	len 20
	note C_
	sfx_end

SFX_0C::
	timbre $F7
	len 1
	note $03, $04, $05, $06, $08, $01, $08, $01
	note $08, $06, $08, $07, $08, $06
	sfx_end

SFX_0F::
	timbre $F7
	len 1
	note $0A, $09, $05, $07, $04, $06, $04
	sfx_end

SFX_12::
	timbre $F7
	len 5
	note $05
	len 2
	note $08
	len 2
	note $09, $04, $08, $06, $08
	sfx_end

SFX_15::
	envelope $FF
	timbre $80
	unused21 $00
	sweep $AD
	octave 5
	len 54
	note G_
	sfx_end

SFX_18::
	timbre $F7
	len 3
	note $07, $08, $06, $08, $05, $08, $07, $08
	note $07, $08
	sfx_end

SFX_1B::
	envelope $FF
	timbre $80
	sweep $00
	octave 3
	len 3
	note G_
	octave_up
	len 4
	note G_
	len 1
	note REST
	len 4
	note G_
	len 1
	note REST
	len 4
	note G_
	len 1
	note REST
	octave_up
	note G_
	sfx_end

SFX_1E::
	envelope $FF
	timbre $40
	octave 3
	len 2
	note G_
	len 4
	note REST
	len 16
	note G_
	sfx_end

SFX_48::
	envelope $FF
	timbre $40
	octave 4
	len 2
	note G_
	len 4
	note REST
	len 16
	note G_
	sfx_end

SFX_21::
	envelope $FF
	timbre $C0
	octave 2
	len 30
	note G_
	sfx_end

SFX_24::
	timbre $F7
	len 4
	note $05, $07, $04
	sfx_end

SFX_27::
	timbre $F0
	len 5
	note $09
	len 2
	note $04
	len 5
	note $09
	len 2
	note $04
	len 5
	note $09
	len 2
	note $04
	len 8
	note $09
	sfx_end

SFX_2A::
	timbre $F7
	len 4
	note $08
	len 2
	note $05
	len 4
	note $08
	len 2
	note $04
	sfx_end

SFX_2D::
	envelope $FF
	timbre $80
	octave 4
	len 5
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	sfx_end

SFX_30::
	timbre $F7
	len 2
	note $06
	len 2
	note $05
	len 2
	note $06
	len 2
	note $08
	sfx_end

SFX_33::
	envelope $FF
	timbre $80
	octave 5
	len 3
	note C_, D_, E_, F_, D_, E_, F_, G_
	note E_, F_, G_, A_, F_, G_, A_, B_
	sfx_end

SFX_36::
	timbre $F7
	len 1
	note $08, $09, $08, $04, $08, $07, $06, $06
	note $08, $07, $09, $06, $07, $05, $08, $09
	note $06, $07, $08, $09, $05, $07
	len 2
	note $08, $09, $08, $05, $08, $06, $07, $08
	note $09, $08
	sfx_end

SFX_39::
	timbre $F7
	len 2
	note $0A, $07, $0B, $0A, $0B, $08
	sfx_end

SFX_3C::
	timbre $F7
	len 2
	note $07, $08, $07
	sfx_end

SFX_45::
	sweep $00
	envelope $FF
	timbre $80
	octave 3
	len 6
	note G_
	sfx_end

SFX_3F::
	sweep $00
	envelope $FF
	timbre $80
	octave 3
	len 6
	note E_
	sfx_end

SFX_42::
	sweep $00
	envelope $FF
	timbre $C0
	octave 2
	len 6
	note E_, C_, E_, G_, E_, G_
	octave_up
	note C_, REST, C_
	len 20
	note G_
	sfx_end


SECTION "ROM0 after sound engine", ROM0[$379D]
	INCBIN BASEROM, $379D, $4000 - $379D

SECTION "Bank 1", ROMX[$4000], BANK[1]
	INCBIN BASEROM, $4000, $4000

SECTION "Bank 2", ROMX[$4000], BANK[2]
	INCBIN BASEROM, $8000, $4000

SECTION "Bank 3 before music", ROMX[$4000], BANK[3]
	INCBIN BASEROM, $C000, $2D10

SECTION "Music data", ROMX[$6D10], BANK[3]

; =============================================================================
; Song $01
; =============================================================================
Song01::
	song_header Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
Song01_Ch1::
	tempo $80
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
Song01_Ch1_Loop::
	panning $FF
	octave 2
	len 36
	note E_
	len 12
	note C_
	len 72
	note C_
	len 24
	note C_, C_, E_
	len 36
	note F_
	len 12
	note D_
	len 48
	note D_
	len 12
	note REST
	octave_down
	note F_, G_, A_, A#
	octave_up
	note C_, D_, E_
	len 36
	note E_
	len 12
	note C_
	len 72
	note C_
	len 24
	note C_, C_, E_
	len 36
	note F_
	len 12
	note D_
	len 72
	note D_
	len 24
	note D_, D_, F_
	len 48
	note G_
	len 16
	note G_, E_, G_
	len 48
	note A_
	len 16
	note A_, F#, A_
	len 96
	note G#
	octave 3
	len 6
	note REST
	len 12
	note E_, D_, C_
	octave_down
	note B_, A_, G#, E_
	octave_down
	len 6
	note B_
	loop 2
	octave 2
	len 24
	note A_, E_, E_, A_
	len 48
	note G#, E_
	len 24
	note F#, D_, F#, D_, E_, E_, E_, E_
	len 24
	note A_, E_, E_, A_
	len 48
	note G#, E_
	len 24
	note F#, D_, E_, E_
	len 96
	note G#
	endloop
	loop 2
	octave 3
	len 24
	note C_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_
	len 48
	note B_, G_
	len 24
	note A_, F_, A_, F_, G#, A_, B_, G#
	octave_up
	len 24
	note C_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_
	len 48
	note B_, G_
	len 24
	note G#, E_, G#, B_
	len 96
	note A_
	endloop
	snd_jump Song01_Ch1_Loop

Song01_Ch2::
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
Song01_Ch2_Loop::
	octave 2
	len 36
	note A_
	len 12
	note E_
	len 72
	note E_
	len 24
	note E_, E_, A_
	len 36
	note A#
	len 12
	note F_
	len 48
	note F_
	len 12
	note REST
	octave_down
	note A#
	octave_up
	note C_, D_, E_, F_, G_, G#
	len 36
	note A_
	len 12
	note E_
	len 72
	note E_
	len 24
	note E_, E_, A_
	len 36
	note A#
	len 12
	note F_
	len 72
	note F_
	len 24
	note F_, F_, A#
	len 48
	octave_up
	note C_
	len 16
	note C_
	octave_down
	note G_
	octave_up
	note C_
	len 48
	note D_
	len 16
	note D_
	octave_down
	note A_
	octave_up
	note D_
	len 96
	octave_down
	note B_
	octave 3
	len 12
	note E_, D_, C_
	octave_down
	note B_, A_, G#, E_
	octave_down
	note B_
	loop 2
	octave 3
	len 24
	note C#
	octave_down
	note A_, A_
	octave_up
	note C#
	len 48
	octave_down
	note B_, G#
	len 24
	note A_, F#, F#, A_, G#, A_, B_, G#
	octave_up
	len 24
	note C#
	octave_down
	note A_, A_
	octave_up
	note C#
	len 48
	octave_down
	note B_, G#
	len 24
	note A_, F#, G#, A_
	len 96
	note B_
	endloop
	loop 2
	octave 3
	len 12
	note REST
	panning $DF
	len 24
	note C_
	panning $FF
	octave_down
	note A_
	panning $FD
	octave_up
	note C_
	panning $FF
	octave_down
	note A_
	panning $DF
	len 48
	note B_
	panning $FF
	note G_
	panning $FD
	len 24
	note A_
	panning $FF
	note F_
	panning $DF
	note A_
	panning $FF
	note F_
	panning $FD
	note G#
	panning $FF
	note A_
	panning $DF
	note B_
	panning $FF
	note G#
	panning $FD
	octave_up
	len 24
	note C_
	panning $FF
	octave_down
	note A_
	panning $DF
	octave_up
	note C_
	panning $FF
	octave_down
	note A_
	panning $FD
	len 48
	note B_
	panning $FF
	note G_
	panning $DF
	len 24
	note G#
	panning $FF
	note E_
	panning $FD
	note G#
	panning $FF
	note B_
	panning $DF
	len 48
	note A_
	panning $FF
	len 36
	note REST
	endloop
	snd_jump Song01_Ch2_Loop

Song01_Ch3::
	timbre $A7
	transpose 12
	unused22 $FF
Song01_Ch3_Loop::
	octave 0
	len 48
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, REST, A_
	len 48
	note A#
	len 12
	note A#, A#, A#, A#
	len 24
	note A#, A#
	len 12
	note A#, A#, REST, A#
	len 48
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, REST, A_
	len 48
	note A#
	len 12
	note A#, A#, A#, A#
	len 24
	note A#, A#
	len 12
	note A#, A#, REST, A#
	len 48
	octave_up
	note C_
	len 16
	note C_, C_, C_
	len 48
	note D_
	len 16
	note D_, D_, D_
	len 192
	note E_
	octave 0
	loop 2
	len 48
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note E_, E_
	len 12
	note E_, E_, REST, E_
	len 48
	note D_
	len 12
	note D_, D_, D_, D_
	len 24
	note E_, E_
	len 12
	note E_, E_, REST, E_
	len 48
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note E_, E_
	len 12
	note E_, E_, REST, E_
	len 48
	note D_
	len 12
	note D_, D_, D_, D_
	len 24
	note E_, E_
	len 12
	note E_, E_, REST, E_
	endloop
	loop 2
	octave 3
	len 96
	note E_
	len 24
	note E_, D_, C_
	octave_down
	note B_
	len 144
	octave_up
	note C_
	octave_down
	len 48
	note B_
	len 96
	note A_
	len 24
	note A_, B_
	octave_up
	note C_, D_
	len 96
	octave_down
	note B_, A_
	endloop
	snd_jump Song01_Ch3_Loop

Song01_Ch4::
	timbre $51
Song01_Ch4_Loop::
	loop 5
	len 48
	note $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, REST, $03
	endloop
	len 12
	note $06, $06, $06, $06, $05, $05, REST, $05
	note $04, $04, REST, $04, $03, $03, $02, $02
	loop 8
	len 48
	note $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, REST, $03
	endloop
	loop 16
	len 12
	note $02, REST, $02, REST, $06, REST, $02, REST
	endloop
	snd_jump Song01_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $02
; =============================================================================
Song02::
	song_header Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
Song02_Ch1::
	tempo $80
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
Song02_Ch1_Loop::
	octave 1
	len 16
	note F_, D_, C_, G_, D_, C_, A_, F_
	note E_, A#, F_, E_, A_, F_, E_, A#
	note F_, E_, A_, F_, E_, A#, F_, E_
	note A_, F_, E_, A#, F_, E_, A_, F_
	note E_, A#, F_, E_, F_, D_, C_, G_
	note D_, C_, F_, D_, C_, G_, D_, C_
	note F_, C_, F_, G_, F_, G_
	len 48
	octave_up
	note C_
	len 16
	octave_down
	note F_, G_, E_
	len 48
	note C_
	len 32
	note F_
	len 16
	note F_
	len 32
	note F_
	len 16
	note C_
	len 32
	note G_
	len 16
	note F_
	len 32
	note F_
	len 16
	note C_
	len 32
	note C_
	len 16
	note C_
	len 96
	note F_
	snd_jump Song02_Ch1_Loop

Song02_Ch2::
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
Song02_Ch2_Loop::
	octave 3
	len 144
	note REST
	len 16
	note REST, REST, C_, C_
	octave_down
	note A_
	octave_up
	note C_, C_
	octave_down
	note A_
	octave_up
	note C_
	len 48
	note A_
	len 16
	note REST, F_, C_
	len 32
	note C_
	len 16
	note C_
	len 48
	note C_, C_, C_
	len 32
	note C_
	len 16
	octave_down
	note A_, G_, A#, A_
	len 48
	note A#
	len 32
	note G_
	len 16
	note A#
	len 48
	note A#
	len 32
	note A#
	len 48
	octave_up
	note C_
	len 16
	note REST, REST, REST, E_, E_, C_, E_, C_
	octave_up
	note C_
	octave_down
	note A#, A_, F_, A_, E_, G_, E_
	len 8
	note F_, D_, F_, D_, F_, D_
	len 16
	note G_, F_
	octave_up
	note C_, C_
	octave_down
	note A_, G_, A_, F_, C_
	snd_jump Song02_Ch2_Loop

Song02_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	gate $28
Song02_Ch3_Loop::
	len 24
	loop 28
	octave 0
	note C_
	octave_up
	note C_
	endloop
	snd_jump Song02_Ch3_Loop

Song02_Ch4::
	timbre $51
Song02_Ch4_Loop::
	len 48
	loop 28
	len 32
	note $03
	len 16
	note $05
	endloop
	snd_jump Song02_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $03
; =============================================================================
Song03::
	song_header Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
Song03_Ch1::
	tempo $80
	timbre $80
	envelope $51
	unused22 $FF
	sweep $00
Song03_Ch1_Loop::
	octave 0
	len 24
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_
	len 12
	note A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, A_, A_
	len 24
	note A_
	len 12
	note A_, A_
	len 24
	note A_, A_
	len 12
	note A_, A_, A_, A_
	len 48
	note A_
	snd_jump Song03_Ch1_Loop

; The real channel 2 part of song $03.  The header points at the song's
; trailing stop_track byte instead, so this track is never played.
Song03_Ch2_Unused::
	timbre $80
	envelope $51
	unused22 $FF
	sweep $00
Song03_Ch2_Unused_Loop::
	octave 0
	len 24
	note E_
	len 12
	note E_, E_, E_, E_
	len 24
	note E_, E_
	len 12
	note E_, E_, E_, E_
	len 24
	note E_
	len 12
	note E_, E_
	len 24
	note E_, E_
	len 12
	note E_, E_, E_, E_
	len 24
	note E_
	len 12
	note E_, E_, E_, E_
	len 24
	note E_, E_
	len 12
	note E_, E_, E_, E_
	len 24
	note E_
	len 12
	note E_, E_
	len 24
	note E_, E_
	len 12
	note E_, E_, E_, E_
	len 48
	note E_
	snd_jump Song03_Ch2_Unused_Loop

Song03_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	stop_track

Song03_Ch4::
	timbre $71
Song03_Ch4_Loop::
	len 24
	note $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03
	len 12
	note $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, $03, $03
	len 24
	note $03
	len 12
	note $03, $03
	len 24
	note $03, $03
	len 12
	note $03, $03, $03, $03
	len 48
	note $03
	snd_jump Song03_Ch4_Loop

; Song $03 channel 2 pointer lands on the terminator below: the channel stays silent.
Song03_Ch2::
	stop_track

; =============================================================================
; Song $04
; =============================================================================
Song04::
	song_header Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
Song04_Ch1::
	tempo $66
	timbre $80
	envelope $62
	unused22 $FF
	sweep $00
Song04_Ch1_Loop::
	octave 1
	len 24
	note D_
	octave_down
	note A_
	snd_jump Song04_Ch1_Loop

Song04_Ch2::
	timbre $80
	envelope $67
	unused22 $FF
	sweep $00
Song04_Ch2_Loop::
	octave 1
	len 24
	note D_
	octave_down
	note A_
	snd_jump Song04_Ch2_Loop

Song04_Ch3::
	timbre $A7
	transpose 12
	unused22 $FF
Song04_Ch3_Loop::
	octave 0
	len 12
	note D_, REST
	octave_down
	note A_, REST
	snd_jump Song04_Ch3_Loop

Song04_Ch4::
	timbre $51
Song04_Ch4_Loop::
	len 24
	note $02
	len 12
	note $02, $02
	snd_jump Song04_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $05
; =============================================================================
Song05::
	song_header Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
Song05_Ch1::
	tempo $99
	timbre $80
	envelope $44
	unused22 $FF
	sweep $A3
	panning $BD
Song05_Ch1_Loop::
	loop 9
	octave 1
	len 24
	note F_, F_, F_, F_, C_, C_
	endloop
	loop 9
	note C_, C_, C_, C#
	octave_down
	note A#
	octave_up
	note C_
	endloop
	note C_
	snd_jump Song05_Ch1_Loop

Song05_Ch2::
	timbre $00
	envelope $75
	unused22 $FF
	sweep $00
Song05_Ch2_Loop::
	loop 2
	octave 1
	len 24
	note REST, F_, G#, F_, G#, G#, F_
	len 12
	note G#, REST
	len 24
	note F_, D#, D#, F_
	len 12
	note D#, REST
	len 24
	note G#, F_, G#, G#, D#, F_, G#
	len 12
	note G#, REST
	len 24
	note F_, F_, G#, F_, G#, F_
	endloop
	octave 1
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, D#, REST, REST
	octave_down
	note A#
	octave_up
	note C_, REST, REST
	octave_down
	note F_, REST
	octave_up
	note C#, REST
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, REST, C#, D#
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, D#, REST, REST
	octave_down
	note A#
	octave_up
	note C_, REST, REST
	octave_down
	note F_, REST
	octave_up
	note C#, REST
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, C#, D#
	snd_jump Song05_Ch2_Loop

Song05_Ch3::
	timbre $A7
	transpose 12
	unused22 $FF
Song05_Ch3_Loop::
	loop 2
	octave 0
	len 24
	note REST, F_, G#, F_, G#, G#, F_
	len 12
	note G#, REST
	len 24
	note F_, D#, D#, F_
	len 12
	note D#, REST
	len 24
	note G#, F_, G#, G#, D#, F_, G#
	len 12
	note G#, REST
	len 24
	note F_, F_, G#, F_, G#, F_
	endloop
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, D#, REST, REST
	octave_down
	note A#
	octave_up
	note C_, REST, REST
	octave_down
	note F_, REST
	octave_up
	note C#, REST
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, REST, C#, D#
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, D#, REST, REST
	octave_down
	note A#
	octave_up
	note C_, REST, REST
	octave_down
	note F_, REST
	octave_up
	note C#, REST
	octave_down
	note A#, REST
	octave_up
	note C_, REST, REST, C#, REST, C#, D#
	snd_jump Song05_Ch3_Loop

Song05_Ch4::
	timbre $71
Song05_Ch4_Loop::
	loop 2
	len 24
	note $04, REST, $04, REST, REST, $04, $04, $04
	note REST, REST
	len 12
	note $04, $04
	len 24
	note $04, $04, REST, $04, $04, $04, REST, $04
	note REST, REST, $04, $04, REST
	len 12
	note $04, $04
	len 24
	note $04, $04
	endloop
	note $04, REST, $04, REST, REST, $04, REST, $04
	note REST
	len 12
	note $04, $04
	len 24
	note $04, $04, REST, REST, $04, REST, $04, REST
	note $04, REST, $04, REST, REST, $04, REST
	len 12
	note $04, $04
	len 24
	note $04, $04, $04, REST, $04, REST, REST, $04
	note REST, $04, REST, REST, $04, $04, REST, REST
	note $04, REST, $04, REST, $04, REST, $04, REST
	note REST, $04
	len 12
	note $04, $04
	len 24
	note $04, $04
	snd_jump Song05_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $06
; =============================================================================
Song06::
	song_header Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
Song06_Ch1::
	tempo $80
	timbre $80
	envelope $67
	unused22 $FF
	sweep $00
Song06_Ch1_Loop::
	octave 3
	len 64
	loop 6
	note C_, D#
	endloop
	snd_jump Song06_Ch1_Loop

Song06_Ch2::
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
	gate $06
Song06_Ch2_Loop::
	octave 2
	len 48
	loop 4
	note E_, G#, E_, G#
	endloop
	snd_jump Song06_Ch2_Loop

Song06_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	stop_track

Song06_Ch4::
	timbre $00
	stop_track

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $07
; =============================================================================
Song07::
	song_header Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
Song07_Ch1::
	tempo $80
	timbre $80
	envelope $62
	unused22 $FF
	sweep $00
	len 48
	note REST
Song07_Ch1_Loop::
	len 12
	loop 4
	octave 2
	note F_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_
	endloop
	loop 2
	octave 2
	note E_
	octave_down
	note G_
	octave_up
	note C_
	octave_down
	note G_
	endloop
	loop 2
	octave 2
	note F_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_
	endloop
	loop 4
	octave 2
	note F_
	octave_down
	note A#
	octave_up
	note D_
	octave_down
	note A#
	endloop
	loop 4
	octave 2
	note E_
	octave_down
	note G_
	octave_up
	note C_
	octave_down
	note G_
	endloop
	loop 2
	octave 2
	note E_
	octave_down
	note A_
	octave_up
	note C#
	octave_down
	note A_
	endloop
	loop 2
	octave 2
	note F_
	octave_down
	note A_
	octave_up
	note D_
	octave_down
	note A_
	endloop
	loop 2
	octave 2
	note G_
	octave_down
	note B_
	octave_up
	note D_
	octave_down
	note B_
	endloop
	loop 2
	octave 2
	note E_
	octave_down
	note G_
	octave_up
	note C_
	octave_down
	note G_
	endloop
	loop 2
	octave 2
	note F_
	octave_down
	note A#
	octave_up
	note D_
	octave_down
	note A#
	endloop
	loop 2
	octave 2
	note E_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_
	endloop
	loop 2
	octave 2
	note D_
	octave_down
	note G_, A#, G_
	endloop
	loop 2
	octave 2
	note E_
	octave_down
	note G_
	octave_up
	note C_
	octave_down
	note G_
	endloop
	snd_jump Song07_Ch1_Loop

Song07_Ch2::
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
	octave 3
	len 36
	note C_
	len 12
	note C_
Song07_Ch2_Loop::
	envelope $75
	panning $FF
	len 72
	note F_
	len 12
	note F_, F_, F_, REST, G_, REST, A_, REST
	note F_, REST
	envelope $85
	panning $DF
	note E_, F_, E_, D_, C_, D_, C_
	octave_down
	note A#, A_, REST, A#, REST
	octave_up
	note C_, REST
	octave_down
	note F_, REST
	envelope $75
	panning $FF
	len 48
	octave_up
	note D_
	len 12
	note D_, C#, D_, E_
	len 48
	note F_, D_
	envelope $85
	panning $FD
	note G_
	len 12
	note A#, A_, G_, F_
	len 48
	note E_, C_
	envelope $75
	panning $FF
	note A_
	len 12
	note A_, A#, A_, G_, F_, REST, E_, REST
	note D_, REST, F_, REST
	envelope $85
	panning $DF
	len 48
	note G_
	len 12
	note G_, A_, G_, F_, E_, REST, D_, REST
	note C_, REST, E_, REST
	envelope $75
	panning $FF
	len 24
	note D_, F_, A#, F_, C_, E_, A_, E_
	envelope $85
	panning $FD
	len 12
	note D_, C#, D_, E_
	len 24
	note F_, G_
	len 48
	note E_, C_
	snd_jump Song07_Ch2_Loop

Song07_Ch3::
	timbre $A7
	transpose 12
	unused22 $FF
	len 48
	note REST
Song07_Ch3_Loop::
	octave 1
	len 48
	note F_, E_, D_, C_, C_
	octave_down
	note G_, F_
	octave_up
	note C_
	octave_down
	note A#, F_, A#, F_
	octave_up
	note C_
	octave_down
	note A#, A_, G_, A_
	octave_up
	note E_, D_, C_
	octave_down
	note G_
	octave_up
	note D_, C_
	octave_down
	note A#, A#, F_, A_, E_, G_
	octave_up
	note D_, C_
	octave_down
	note G_
	snd_jump Song07_Ch3_Loop

Song07_Ch4::
	timbre $61
	len 48
	note REST
Song07_Ch4_Loop::
	len 12
	loop 8
	note $04, REST, $03, REST, $03, $03, $03, $03
	note $04, $03, REST, $03, REST, $03, $03, $03
	endloop
	snd_jump Song07_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $08
; =============================================================================
Song08::
	song_header Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
Song08_Ch1::
	tempo $80
	timbre $80
	envelope $67
	unused22 $FF
	sweep $A3
Song08_Ch1_Loop::
	loop 3
	octave 1
	len 12
	note G_, G#
	len 48
	note F_
	len 12
	note F_, E_
	len 48
	note D#
	len 12
	note D#, D_
	len 24
	note C#
	endloop
	loop 2
	octave 1
	len 24
	note G_
	len 48
	note A#
	len 24
	note G_
	len 96
	note A#
	endloop
	snd_jump Song08_Ch1_Loop

Song08_Ch2::
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
Song08_Ch2_Loop::
	loop 3
	octave 3
	len 12
	note C_
	octave_down
	note B_, A#, REST
	len 24
	note REST
	len 12
	note A#, A_, G#, REST
	len 24
	note REST
	len 12
	note G#, G_, F#, REST
	endloop
	loop 2
	octave 3
	len 24
	note C_
	len 48
	note D#
	len 24
	note C_
	len 96
	note D#
	endloop
	snd_jump Song08_Ch2_Loop

Song08_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
Song08_Ch3_Loop::
	len 24
	loop 3
	octave 0
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	octave_down
	note G_
	octave_up
	note G_
	endloop
	loop 2
	octave 3
	len 24
	note C_
	len 48
	note D#
	len 24
	note C_
	len 96
	note D#
	endloop
	snd_jump Song08_Ch3_Loop

Song08_Ch4::
	timbre $51
Song08_Ch4_Loop::
	len 12
	loop 3
	note $03, $03, $03, REST, REST, REST, $03, $03
	note $03, REST, REST, REST, $03, $03, $03, REST
	endloop
	loop 2
	len 24
	note $06
	len 48
	note $02
	len 24
	note $04
	len 48
	note $02
	len 12
	note $04, $04, $04, $04
	endloop
	snd_jump Song08_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $09
; =============================================================================
Song09::
	song_header Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
Song09_Ch1::
	tempo $80
	timbre $C0
	envelope $65
	unused22 $FF
	sweep $00
	octave 2
	len 72
	note G_
	len 12
	note G_, G_, G_, REST, A#, REST, A#, REST
	note A_, REST, G_, REST, REST, F_
	len 144
	note G_
	stop_track

Song09_Ch2::
	timbre $C0
	envelope $65
	unused22 $FF
	unused27 $07, $80
	sweep $00
	octave 3
	len 72
	note C_
	len 12
	note C_, C_, C_, REST, D#, REST, D#, REST
	note D_, REST, C_, REST, REST
	octave_down
	note A#
	len 144
	octave_up
	note C_
	stop_track

Song09_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	gate $C8
	octave 1
	len 72
	note C_
	len 12
	note C_, C_, C_, REST, D#, REST, D#, REST
	note D_, REST, C_, REST, REST
	octave_down
	note A#
	len 96
	octave_up
	note C_, REST
	stop_track

Song09_Ch4::
	timbre $51
	len 72
	note $03
	len 12
	note $03, $03, $02, REST, $05, REST, $04, REST
	note $03, REST, $04, REST, REST, $05
	len 6
	note $05, $05, $05, $05, $04, $04, $04, $04
	note $03, $03, $03, $03, $02, $02, $02, $02
	loop 6
	note $01
	endloop
	stop_track

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $0A
; =============================================================================
Song0A::
	song_header Song0A_Ch1, Song0A_Ch2, Song0A_Ch3, Song0A_Ch4
Song0A_Ch1::
	tempo $80
	timbre $C0
	envelope $65
	unused22 $FF
	sweep $00
	octave 2
	len 16
	note G_, G_, G_
	len 24
	note F#, REST
	len 16
	note F_, F_, F_
	len 24
	note E_, REST
	len 16
	note D#, D#, D#, D_, REST, C_
	len 96
	note D_
	stop_track

Song0A_Ch2::
	timbre $C0
	envelope $65
	unused22 $FF
	sweep $00
	octave 3
	len 16
	note C_, C_, C_
	len 24
	octave_down
	note B_, REST
	len 16
	note A#, A#, A#
	len 24
	note A_, REST
	len 16
	note G#, G#, G#, G_, REST, F_
	len 96
	note G_
	stop_track

Song0A_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	gate $C8
	octave 1
	len 16
	note C_, C_, C_
	len 24
	octave_down
	note B_, REST
	len 16
	note A#, A#, A#
	len 24
	note A_, REST
	len 16
	note G#, G#, G#, G_, REST, F_
	len 96
	note G_
	stop_track

Song0A_Ch4::
	timbre $51
	len 16
	note $02, $02, $02
	len 24
	note $03, REST
	len 16
	note $04, $04, $04
	len 24
	note $05, REST
	len 16
	note $06, $06, $06, $07, REST, $08
	len 6
	note $05, $05, $05, $05, $04, $04, $04, $04
	note $03, $03, $03, $03, $02, $02, $02, $02
	loop 6
	note $01
	endloop
	stop_track

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $0B
; =============================================================================
Song0B::
	song_header Song0B_Ch1, Song0B_Ch2, Song0B_Ch3, Song0B_Ch4
Song0B_Ch1::
	tempo $55
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
	len 48
	note REST
Song0B_Ch1_Loop::
	panning $FF
	loop 2
	octave 2
	len 24
	note C_, E_, G_, E_, C_, E_, G_, E_
	note C_, F_, G#, F_, C_, F_, G#, F_
	note C_, E_, G_, E_, C_, E_, G_, E_
	octave_down
	note B_
	octave_up
	note D#, G#, D#
	octave_down
	note B_
	octave_up
	note D#, G#, D#
	octave_down
	note A#
	octave_up
	note D_, G_, D_
	octave_down
	note A#
	octave_up
	note D_, G_, D_
	octave_down
	note A_
	octave_up
	note D_, F_, D_
	octave_down
	note A_
	octave_up
	note D_, F_, D_
	octave_down
	note G#, B_
	octave_up
	note D#
	octave_down
	note B_, G#, B_
	octave_up
	note D#
	octave_down
	note B_, B_
	octave_up
	note D_, G_, D_
	octave_down
	note B_
	octave_up
	note D_, G_, D_
	endloop
	octave 3
	len 24
	note C_, E_, G_, B_, C_, E_, G_, B_
	note C_, E_, G_, B_
	octave_up
	note D_, C_
	octave_down
	note B_, G_
	octave_down
	note A_
	octave_up
	note C_, F#, A_
	octave_down
	note A_
	octave_up
	note C_, F#, A_
	octave_down
	note B_
	octave_up
	note D#, F#, B_
	octave_up
	note C_
	octave_down
	note B_, A_, F#
	octave_down
	note B_
	octave_up
	note E_, G_, B_
	octave_down
	note B_
	octave_up
	note E_, G_, B_, C_, E_, A_
	octave_up
	note C_
	octave_down
	note C_, E_, A_
	octave_up
	note C_
	octave_down
	note C#, E_, A#
	octave_up
	note C#
	octave_down
	note C#, E_, A#
	octave_up
	note C#, D#
	octave_down
	note B_, A_, B_, F#, A_, D#, F#
	snd_jump Song0B_Ch1_Loop

Song0B_Ch2::
	timbre $80
	envelope $75
	unused22 $FF
	sweep $00
	octave 3
	len 12
	note D_, E_, F_, F#
Song0B_Ch2_Loop::
	snd_call Song0B_Sub1
	len 96
	note G_
	len 48
	octave_down
	note G_
	octave_up
	len 12
	note D_, E_, F_, F#
	snd_call Song0B_Sub1
	len 96
	note G_
	len 96
	octave_down
	note G_
	len 12
	note REST
	panning $DF
	octave 3
	len 24
	note C_
	panning $FF
	note E_
	panning $FD
	note G_
	panning $FF
	note B_
	panning $DF
	note C_
	panning $FF
	note E_
	panning $FD
	note G_
	panning $FF
	note B_
	panning $DF
	note C_
	panning $FF
	note E_
	panning $FD
	note G_
	panning $FF
	note B_
	panning $DF
	octave_up
	note D_
	panning $FF
	note C_
	panning $FD
	octave_down
	note B_
	panning $FF
	note G_
	panning $DF
	octave_down
	note A_
	panning $FF
	octave_up
	note C_
	panning $FD
	note F#
	panning $FF
	note A_
	panning $DF
	octave_down
	note A_
	panning $FF
	octave_up
	note C_
	panning $FD
	note F#
	panning $FF
	note A_
	panning $DF
	octave_down
	note B_
	panning $FF
	octave_up
	note D#
	panning $FD
	note F#
	panning $FF
	note B_
	octave_up
	panning $DF
	note C_
	octave_down
	panning $FF
	note B_
	panning $FD
	note A_
	panning $FF
	note F#
	panning $DF
	octave_down
	note B_
	panning $FF
	octave_up
	note E_
	panning $FD
	note G_
	panning $FF
	note B_
	panning $DF
	octave_down
	note B_
	panning $FF
	octave_up
	note E_
	panning $FD
	note G_
	panning $FF
	note B_
	panning $DF
	note C_
	panning $FF
	note E_
	panning $FD
	note A_
	panning $FF
	octave_up
	note C_
	panning $DF
	octave_down
	note C_
	panning $FF
	note E_
	panning $FD
	note A_
	panning $FF
	octave_up
	note C_
	panning $DF
	octave_down
	note C#
	panning $FF
	note E_
	panning $FD
	note A#
	panning $FF
	octave_up
	note C#
	panning $DF
	octave_down
	note C#
	panning $FF
	note E_
	panning $DF
	note A#
	panning $FF
	octave_up
	note C#
	panning $FD
	note D#
	panning $FF
	octave_down
	note B_
	panning $DF
	note A_
	panning $FF
	note B_
	panning $FD
	note F#
	panning $FF
	note A_
	panning $DF
	note D#
	panning $FF
	len 12
	note F#
	snd_jump Song0B_Ch2_Loop

Song0B_Sub1::
	octave 3
	len 96
	note G_
	len 24
	note REST, F_, E_, F_
	len 144
	note G#
	len 48
	note A#
	len 96
	note G_
	len 24
	note REST, F_, E_, F_
	len 96
	note G#
	len 48
	note D#, F_
	len 96
	note G_
	len 24
	note REST
	len 48
	note G#
	len 24
	note G_
	len 96
	note F_
	len 24
	note REST
	len 48
	note G_
	len 24
	note F_
	len 96
	note D#
	len 24
	note REST, F_, D#, F_
	snd_ret

Song0B_Ch3::
	timbre $A7
	transpose 12
	unused22 $FF
	len 48
	note REST
Song0B_Ch3_Loop::
	loop 2
	octave 1
	len 192
	note C_
	octave_down
	note F_
	octave_up
	note C_
	octave_down
	note G#
	octave_up
	note D#, D_
	octave_down
	note G#
	len 96
	note G_
	len 48
	note A_, B_
	endloop
	octave 1
	len 24
	loop 2
	note C_, REST, REST, C_, C_, REST, REST, C_
	endloop
	octave_down
	note F#, REST, REST, F#, F#, REST, REST, F#
	note B_, REST, REST, B_, B_, REST, REST, B_
	note E_, REST, REST, E_, E_, REST, REST, E_
	note G#, REST, REST, G#, G#, REST, REST, G#
	note F#, REST, REST, F#, F#, REST, REST, F#
	note G_, REST, REST, G_
	len 96
	note G_
	snd_jump Song0B_Ch3_Loop

Song0B_Ch4::
	timbre $51
	len 48
	note REST
Song0B_Ch4_Loop::
	len 24
	loop 16
	note $01, $01, $04, $01, $01, $01, $04, $01
	endloop
	loop 8
	note $01, $01, $04, $01, $01, $04, $04, $01
	endloop
	snd_jump Song0B_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $0C  (unused: never requested by the game or its sound test)
; =============================================================================
Song0C::
	song_header Song0C_Ch1, Song0C_Ch2, Song0C_Ch3, Song0C_Ch4
Song0C_Ch1::
	tempo $80
	timbre $80
	envelope $66
	unused22 $FF
	sweep $00
	octave 2
	len 24
	note A_
	len 12
	note A_, A_
	len 24
	note E_, A_
	len 96
	octave_up
	note C#
	stop_track

Song0C_Ch2::
	timbre $80
	envelope $66
	unused22 $FF
	sweep $00
	octave 2
	len 24
	note C#
	len 12
	octave_down
	note A_
	octave_up
	note C#
	len 24
	note E_, E_
	len 96
	note A_
	stop_track

Song0C_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
	octave 0
	len 24
	note A_
	len 12
	note A_, A_
	len 24
	note E_, A_
	len 96
	note REST
	stop_track

Song0C_Ch4::
	timbre $51
	len 12
	note $03, REST, $03, $03, $03, REST, $03, REST
	len 96
	note $01
	stop_track

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $0D  (unused: never requested by the game or its sound test)
; =============================================================================
Song0D::
	song_header Song0D_Ch1, Song0D_Ch2, Song0D_Ch3, Song0D_Ch4
Song0D_Ch1::
	tempo $80
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
Song0D_Ch1_Loop::
	loop 3
	octave 2
	len 48
	note C_, A_
	endloop
	len 48
	note C_, A_
	loop 3
	octave 2
	len 48
	note C_, A_
	endloop
	note C_, A_
	snd_jump Song0D_Ch1_Loop

Song0D_Ch2::
	timbre $C0
	envelope $65
	unused22 $FF
	sweep $00
Song0D_Ch2_Loop::
	loop 3
	octave 2
	len 24
	note F_
	len 3
	note F_, F#, G_, G#, A_, A#, B_
	octave_up
	note C_
	len 48
	note C_
	endloop
	len 16
	note F_, C_
	octave_down
	note A_
	octave_up
	note C_
	octave_down
	note A_, F_
	loop 3
	octave 2
	len 48
	note F_
	len 3
	note F_, F#, G_, G#, A_, A#, B_
	octave_up
	note C_
	len 24
	note C_
	endloop
	len 16
	note F_, C_
	octave_down
	note A_, F_, C_
	octave_down
	note A_
	snd_jump Song0D_Ch2_Loop

Song0D_Ch3::
	timbre $A6
	transpose 12
	unused22 $FF
Song0D_Ch3_Loop::
	octave 2
	len 48
	note F_, C_
	octave_down
	note A_, F_, G_, F_, A_, G_
	octave_up
	note F_, C_
	octave_down
	note A_, F_, A_, F_, G_, F_
	snd_jump Song0D_Ch3_Loop

Song0D_Ch4::
	timbre $51
Song0D_Ch4_Loop::
	loop 4
	len 16
	note $08, REST, $08
	len 3
	note $01, $01, $01, $01, $02, $02, $02, $02
	note $03, $03, $03, $03, $04, $04, $04, $04
	len 16
	note $05, $03, $05, $05, $03, $05
	endloop
	snd_jump Song0D_Ch4_Loop

	db $1C                                 ; end-of-song marker (never read)

; =============================================================================
; Song $0E  (unused: never requested by the game or its sound test)
; =============================================================================
Song0E::
	song_header Song0E_Ch1, Song0E_Ch2, Song0E_Ch3, Song0E_Ch4
Song0E_Ch1::
	tempo $C0
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
	octave 0
	len 48
	note A#
	len 24
	octave_up
	note C#, C#
	octave_down
	note A#
	octave_up
	note C#
	len 72
	octave_down
	note A#
	stop_track

Song0E_Ch2::
	timbre $80
	envelope $65
	unused22 $FF
	sweep $00
	octave 0
	len 48
	note A#
	len 24
	octave_up
	note C#, C#
	octave_down
	note A#
	octave_up
	note C#
	len 72
	octave_down
	note A#
	stop_track

Song0E_Ch3::
	timbre $AA
	transpose 12
	unused22 $FF
	octave 0
	len 48
	note A#
	len 24
	octave_up
	note C#, C#
	octave_down
	note A#
	octave_up
	note C#
	len 72
	octave_down
	note A#
	stop_track

Song0E_Ch4::
	timbre $51
	len 48
	note $05
	len 24
	note $05, $05, $05, $05
	len 72
	note $05
	stop_track

	db $1C                                 ; end-of-song marker (never read)

SECTION "Bank 3 after music", ROMX[$7B13], BANK[3]
	INCBIN BASEROM, $FB13, $8000 - $7B13

SECTION "Bank 4", ROMX[$4000], BANK[4]
	INCBIN BASEROM, $10000, $4000

SECTION "Bank 5", ROMX[$4000], BANK[5]
	INCBIN BASEROM, $14000, $4000

SECTION "Bank 6", ROMX[$4000], BANK[6]
	INCBIN BASEROM, $18000, $4000

SECTION "Bank 7", ROMX[$4000], BANK[7]
	INCBIN BASEROM, $1C000, $4000

