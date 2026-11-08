; ==========================================================================
; Batman - The Animated Series (U) - Konami sound driver (ROM0 + bank 7)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: PlaySoundFar ($0307-$0330), the bank helpers BankSwitch/MapBank7/SetBank,
;         SndUpdate, pause, tempo, fade, SndInit ($0B18-$0D19)
;   bank 7: the track code ($4000-$49BA), tables and headers ($49BB-$4FDE), PlaySound ($4FDF-$50B6),
;           drum hits, SFX and songs ($50B7-$7A97); $7A98-$7FFF is other game data
; Build: rgbasm -Wall -o bm.o BM_SoundDriver.asm && rgblink -o bm.gb bm.o
; ==========================================================================

; ---------------------------------------------------------------- hardware
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF _AUD3WAVERAM EQU $FF30
DEF rIE EQU $FFFF

; ---------------------------------------------------------------- RAM
DEF wTrkSfx1 EQU $C180 ; 67 bytes
DEF wTrkSfx2 EQU $C280 ; 67 bytes
DEF wTrkSfxN EQU $C380 ; 67 bytes
DEF wTrkCh1 EQU $C480 ; 67 bytes
DEF wTrkCh2 EQU $C580 ; 67 bytes
DEF wTrkCh3 EQU $C680 ; 67 bytes
DEF wTrkDrm EQU $C780 ; 67 bytes
DEF wTrackDesc EQU $C1C3
DEF wC1C4 EQU $C1C4
DEF wTempo EQU $C1C5
DEF wTempoAcc EQU $C1C6
DEF wReqPrio EQU $C1C7
DEF wReqId EQU $C1C8
DEF wPauseLast EQU $C1C9
DEF wFadeRate EQU $C1CA
DEF wFadeTimer EQU $C1CB
DEF wFadeStep EQU $C1CC
DEF wWaveId EQU $C1CD
DEF wC1CE EQU $C1CE
DEF wSndMute EQU $C8C6
DEF wPauseFlags EQU $DB04
DEF wSndBusy EQU $DB22
DEF hRomBank EQU $FFA3 ; the game's copy of the mapped ROM bank
DEF hKey EQU $FFDF ; set by the game; KEY_TRANSPOSE adds hKey mod 3 semitones
DEF rROMB EQU $2000

; per-track fields: track n lives at $C180 + n*$100, so H = $C1 + n and L = field
DEF TRK_PRIO EQU $80
DEF TRK_ID EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_PANFLAGS EQU $86
DEF TRK_FLOW EQU $87
DEF TRK_VIB EQU $88
DEF TRK_DETUNE EQU $89
DEF TRK_ATTEN EQU $8B
DEF TRK_TRANSP EQU $8C
DEF TRK_JUMPCNT EQU $8D
DEF TRK_DUTYTICKS EQU $8E
DEF TRK_DUTYCNT EQU $8F
DEF TRK_DUTYSTART EQU $90
DEF TRK_UNIT EQU $91
DEF TRK_OCTAVE EQU $92
DEF TRK_PERIOD EQU $93
DEF TRK_LASTPERIOD EQU $95
DEF TRK_VOL EQU $97
DEF TRK_LASTVOL EQU $98
DEF TRK_DUTY EQU $99
DEF TRK_LASTDUTY EQU $9A
DEF TRK_GATE EQU $9B
DEF TRK_RELTICK EQU $9C
DEF TRK_ENV EQU $9D
DEF TRK_CH3CNT EQU $9E
DEF TRK_PAN EQU $9F
DEF TRK_VIBPTR EQU $A0
DEF TRK_VIBCUR EQU $A2
DEF TRK_VIBTIMER EQU $A4
DEF TRK_VIBDELAY EQU $A5
DEF TRK_VIBDELAYCNT EQU $A6
DEF TRK_VIBDEPTH EQU $A7
DEF TRK_VIBLOOP EQU $A8
DEF TRK_VIBLOOPCNT EQU $AA
DEF TRK_VIBMARK EQU $AB
DEF TRK_LOOP1 EQU $AD
DEF TRK_LOOP1CNT EQU $AF
DEF TRK_LOOP2 EQU $B0
DEF TRK_LOOP2CNT EQU $B2
DEF TRK_MARK EQU $B3
DEF TRK_RET EQU $B5
DEF TRK_REG_NRX1 EQU $B7
DEF TRK_REG_NRX2 EQU $B8
DEF TRK_REG_NRX3 EQU $B9
DEF TRK_REG_NRX4 EQU $BA
DEF TRK_LASTPITCH EQU $BB
DEF TRK_FLAGS3 EQU $BC
DEF TRK_RELVOL EQU $BD
DEF TRK_PITCHIDX EQU $BE
DEF TRK_PANATTEN EQU $BF
DEF TRK_RAMPSTEP EQU $C1
DEF TRK_RAMPCNT EQU $C2

; wTrackDesc: Sfx1 $40, Sfx2 $52, SfxN $63, Ch1 $00, Ch2 $11, Ch3 $22, Drm $34 (low nibble = channel)
; TRK_FLAGS: 0 rest, 1 (cleared at the end of Sfx1/Sfx2, never tested), 2 retrigger a long note,
;   4 tempo skip, 5 reload the duty/wave
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, 5 volume ramp
;   louder, 6 volume ramp quieter, 7 autopan with both sides
; TRK_FLOW: 0/1 loops open, 2 in a call, 3 mark set, 4 vibrato loop, 5 vibrato mark
; TRK_FLAGS3: 0 Sfx1/Sfx2 high nibble next, 2 noise retrigger pending

; ---------------------------------------------------------------- sound data macros
DEF C_ EQU 1
DEF C# EQU 2
DEF D_ EQU 3
DEF D# EQU 4
DEF E_ EQU 5
DEF F_ EQU 6
DEF F# EQU 7
DEF G_ EQU 8
DEF G# EQU 9
DEF A_ EQU 10
DEF A# EQU 11
DEF B_ EQU 12
DEF C_HI EQU 13 ; pitch 13: the previous note's pitch one octave up

; sound header: priority, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; music tracks: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0: (unit & 15) x 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = sound id (drum hit) 1-12, lo = length multiplier (hi 0 = rest)
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; Sfx1/Sfx2: two notes per byte (high nibble, then low nibble), one unit each; pitch 0 = rest
MACRO NOTES
	db (\1 << 4) | \2
ENDM
; a byte only read for its low nibble (the first byte of a stream before any voice)
MACRO NOTE_LO
	db (\1 << 4) | \2
ENDM
; Sfx1/Sfx2: note \1, then a new unit
MACRO NOTE_UNIT
	db (\1 << 4) | $0E, \2
ENDM
; Sfx1/Sfx2: note \1, then the next byte is a command
MACRO NOTE_CMD
	db (\1 << 4) | $0F
ENDM
; SfxN: NR43 value (no retrigger unless marked), length = unit
MACRO NOISE
	db \1
ENDM
; SfxN: mark a retrigger for the next noise note
MACRO NOISE_TRIG
	db $C0
ENDM
; SfxN: volume \1 (NR42 high nibble), retrigger at the next noise note
MACRO NOISE_VOL
	db $C0 | \1
ENDM
; SfxN: volume \1 and a retrigger now, length = unit (0: NR42 = 8)
MACRO NOISE_VOLNOTE
	db $D0 | \1
ENDM
; $E0: unit (7 bits), duty<<4|vol, gate<<4|env (CH3: duty = wave)
MACRO VOICE
	db $E0, \1, (\2 << 4) | \3, (\4 << 4) | \5
ENDM
; $E0 unit, NR42 nibble-swapped (noise SFX: retriggered at the next noise note)
MACRO NVOICE
	db $E0, \1, \2
ENDM
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release tick = length * gate / 16), env (NRx2 low nibble at the release)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9: NR10, written at once (never blocked)
MACRO SWEEP
	db $E9, \1
ENDM
; $EA xy
MACRO DUTY
	db $EA, $00 | \1
ENDM
MACRO WAVE
	db $EA, $00 | \1
ENDM
; pan (both sides / NR51 high nibble / low nibble) + attenuation y
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $20 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $30 | \1
ENDM
; autopan: every note alternates low / high nibble side (y kept in TRK_PANATTEN, unused)
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; autopan: every note alternates low nibble side at attenuation y / both sides at attenuation 0
MACRO AUTOPAN_BOTH
	db $EA, $50 | \1
ENDM
MACRO EXT_6
	db $EA, $60 | \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \1
ENDM
; release volume: at the release tick NRx2 = y << 4 instead of the envelope
MACRO RELEASE_VOL
	db $EA, $90 | \1
ENDM
MACRO EXT_A
	db $EA, $A0 | \1
ENDM
MACRO EXT_B
	db $EA, $B0 | \1
ENDM
MACRO EXT_C
	db $EA, $C0 | \1
ENDM
; $EA Ay: clear fields: bit 3 vibrato, bit 2 duty step, bit 1 detune, bit 0 attenuation
MACRO CLEAR
	db $EA, $A0 | \1
ENDM
; $EA Dy: transpose by (hKey mod 3) + y semitones (hKey = HRAM $FFDF, set by the game)
MACRO KEY_TRANSPOSE
	db $EA, $D0 | \1
ENDM
; $EA Ey: wTempo -= 3 (y unused)
MACRO TEMPO_DOWN
	db $EA, $E0 | \1
ENDM
; $EA Fy: volume ramp: every (y & 7) + 1 notes the attenuation goes up by one level (y & 8: louder:
; down by one level); attenuation, pan and voice commands stop it
MACRO VOL_RAMP
	db $EA, $F0 | \1
ENDM
; $EB n, xy: vibrato table n, delay x * unit, depth y; $EB n | $80: semitone table n (no delay byte)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_SEMI
	db $EB, $80 | \1
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $EC x: NR50 = x (master volume, written at once)
MACRO MASTER_VOL
	db $EC, \1
ENDM
; $ED xy: notes start with duty x << 4, the voice duty comes back after y ticks (y = 0: off)
MACRO DUTY_STEP
	db $ED, (\1 << 4) | \2
ENDM
MACRO TEMPO
	db $EE, \1
ENDM
MACRO DETUNE
	db $EF, \1
ENDM
; $F0-$F7: attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
; $F8 x: volume = swap(x), attenuation 0
MACRO VOLUME
	db $F8, \1
ENDM
; $F9 n addr: jump on the n-th pass
MACRO SND_JUMP_N
	db $F9, \1
	dw \2
ENDM
MACRO SND_JUMP
	db $FA
	dw \1
ENDM
; $FB / $FC: the first one met marks a loop start, the next one (with a count) loops
MACRO LOOP_START
	db $FB
ENDM
MACRO LOOP_END
	db $FB, \1
ENDM
MACRO LOOP2_START
	db $FC
ENDM
MACRO LOOP2_END
	db $FC, \1
ENDM
; $FD addr call, a bare $FD returns
MACRO SND_CALL
	db $FD
	dw \1
ENDM
MACRO SND_RET
	db $FD
ENDM
; $FE: the first one marks, the next one jumps back to the mark (forever)
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; vibrato tables: time << 4 | negative << 3 | offset (x depth); semitone tables: time << 4 | code
; (1-12 semitones, 13 = 19, 14 = 24, 15 = 36); $FB / $FB n loop, $FE mark/jump, $FF end
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
ENDM
MACRO VIB_SEMI_STEP
	db (\1 << 4) | \2
ENDM
MACRO VIB_LOOP_START
	db $FB
ENDM
MACRO VIB_LOOP_END
	db $FB, \1
ENDM
MACRO VIB_MARK
	db $FE
ENDM
MACRO VIB_END
	db $FF
ENDM

SECTION "PlaySoundFar", ROM0[$0307]

; PlaySoundFar: A = sound id (0 = stop all). Dropped while wSndMute bit 0 is set. Sets
; wSndBusy bit 1, wReqId = A, maps bank 7, PlaySound, maps the game's bank again.
PlaySoundFar:
	push hl
	ld hl, wSndMute
	bit 0, [hl]
	jr nz, .l032F
	ld hl, wSndBusy
	set 1, [hl]
	push de
	push bc
	push af
	ld [wReqId], a
	ldh a, [hRomBank]
	push af
	call MapBank7
	call PlaySound
	pop af
	call SetBank
	pop af
	pop bc
	pop de
	ld hl, wSndBusy
	res 1, [hl]
.l032F:
	pop hl
	ret

SECTION "BankSwitch", ROM0[$07C7]

; BankSwitch (game code): map bank A and keep it in hRomBank. MapBank7 maps bank 7,
; SetBank the bank in A (the callers push af first).
BankSwitch:
	di
	ld [rROMB], a
	ldh [hRomBank], a
	ei
	pop af
	ret

SECTION "MapBank7", ROM0[$07E9]

MapBank7:
	push af
	ld a, $07
	jr BankSwitch

SetBank:
	push af
	jr BankSwitch

SECTION "Sound ROM0", ROM0[$0B18]

; SndUpdate (from the VBlank handler, unless wSndBusy bit 0/1 is set): on a change of
; wPauseFlags pause or unpause. Not paused: FadeTick, TempoTick, Ch1, Ch2, Ch3, Drm. Then SfxN,
; Sfx2, Sfx1 (also while paused). Every track runs through RunTrack, which maps bank 7 and
; jumps to TrackTick; the game's bank is mapped again at the end.
SndUpdate:
	ld a, [wPauseFlags]
	ld hl, wPauseLast
	cp [hl]
	jp z, UpdateTracks
	ld [hl], a
	cp $00
	call PauseEdge

UpdateTracks:
	ld a, [wPauseFlags]
	or a
	jp nz, UpdateSfx
	ld h, HIGH(wTrkCh1)
	call FadeTick
	call TempoTick
	ld h, HIGH(wTrkCh1)
	xor a
	call RunTrack
	ld h, HIGH(wTrkCh2)
	ld a, $11
	call RunTrack
	ld h, HIGH(wTrkCh3)
	ld a, $22
	call RunTrack
	ld h, HIGH(wTrkDrm)
	ld a, $34
	call RunTrack

UpdateSfx:
	ld h, HIGH(wTrkSfxN)
	ld a, $63
	call RunTrack
	ld h, HIGH(wTrkSfx2)
	ld a, $52
	call RunTrack
	ld h, HIGH(wTrkSfx1)
	ld a, $40
	call RunTrack
	ldh a, [hRomBank]
	ld [rROMB], a
	ret

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, $07
	ld [rROMB], a
	jp TrackTick

; PauseEdge (Z = unpaused). Pause: stop SfxN, mute CH4 and CH2. Unpause: stop Sfx1 and
; Sfx2, mute CH1, NR32 = 0, give CH1 and CH3 back to the music (NR51 bits and period, no
; trigger) and mark Ch1-Ch3 for a retrigger of a long note (Ch1/Ch3 also reload the duty).
PauseEdge:
	jp z, Unpause
	xor a
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ld a, $08
	ld c, $21
	ldh [c], a
	ld a, $80
	ld c, $23
	ldh [c], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ret

Unpause:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $10
	ldh [c], a
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
	inc h
	xor a
	ld [hl-], a
	ld [hl], a
	ld c, $1C
	ldh [c], a
	ld h, HIGH(wTrkCh1)
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $EE
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	inc h
	set 2, [hl]
	inc h
	set 2, [hl]
	set 5, [hl]
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $BB
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

; TempoTick: wTempoAcc += wTempo; the carry sets (else clears) the skip flag of all four
; music tracks, which then skip this update.
TempoTick:
	ld hl, wTempo
	ld a, [hl]
	ld b, a
	or a
	ld h, HIGH(wTrkCh1)
	ret z
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld l, TRK_FLAGS
	jp c, .l0C18
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l0C18:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: wFadeRate 0: NR50 back to $77. Else, while music Ch2 plays: if the last request
; was $12 all music stops at once; else CH4 is muted (NR42 = 8 + trigger) on every update,
; and every wFadeRate updates NR50 goes down by $11. From $11 on the rate is 1 and wFadeStep
; counts: 4 stops Drm, 8 Ch3, 12 Ch1, 18 Ch2 (the fade ends, NR50 = $77).
FadeTick:
	ld a, [wFadeRate]
	ld b, a
	or a
	jr nz, .l0C35
	ld c, $24
	ldh a, [c]
	cp $77
	ret z
	ld a, $77
	ldh [c], a
	ret
.l0C35:
	ld h, HIGH(wTrkCh2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, [wReqId]
	cp $12
	jr nz, .l0C50
	call FadeStopDrm
	call FadeStopCh3
	call FadeStopCh1
	call FadeStopCh2
	ret
.l0C50:
	ld a, $08
	ld c, $21
	ldh [c], a
	swap a
	set 1, c
	ldh [c], a
	ld a, b
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld c, $24
	ldh a, [c]
	cp $11
	jr z, .l0C6E
	sub $11
	ldh [c], a
	ret
.l0C6E:
	ld a, $01
	ld [wFadeRate], a
	ld a, [wFadeStep]
	add a, $01
	ld [wFadeStep], a
	cp $04
	jr z, FadeStopDrm
	cp $08
	jr z, FadeStopCh3
	cp $0C
	jr z, FadeStopCh1
	cp $12
	ret nz

FadeStopCh2:
	ld h, HIGH(wTrkCh2)
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	xor a
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld c, $24
	ld a, $77
	ldh [c], a
	ret

FadeStopCh1:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr nz, .l0CBD
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l0CBD:
	ld h, HIGH(wTrkCh1)
	xor a
	ld [hl-], a
	ld [hl+], a
	ret

FadeStopDrm:
	ld h, HIGH(wTrkDrm)
	xor a
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ret

FadeStopCh3:
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ld a, $00
	jr nz, .l0CDB
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l0CDB:
	xor a
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ret

; SndInit: NR50 = $77, NR51 = $FF, NR52 = $80, and the register addresses TRK_REG_NRX1-4
; of tracks 0-5. The drum track keeps 0 (its writes would go to $FF00).
SndInit:
	ld c, $24
	ld a, $77
	ldh [c], a
	inc c
	ld a, $FF
	ldh [c], a
	inc c
	ld a, $80
	ldh [c], a
	ld h, HIGH(wTrkSfx1)
	ld a, $11
	ld l, TRK_REG_NRX1
	call SetRegAddrs
	ld a, $1B
	call SetRegAddrs
	ld a, $20
	call SetRegAddrs
	ld a, $11
	call SetRegAddrs
	ld a, $16
	call SetRegAddrs
	ld a, $1B

SetRegAddrs:
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc h
	ld l, TRK_REG_NRX1
	ret

SECTION "Sound bank 7", ROMX[$4000], BANK[7]

; TrackTick: tempo skip; a pending reload of the duty; LEN - 1; at 0 read commands, else
; Sustain.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, .l4012
	res 5, [hl]
	ld l, TRK_LASTDUTY
	ld a, [hl]
	call WriteDuty
.l4012:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

ReReadCmds:
	dec de

NextByte:
	inc de

; ReadCmds: $E0-$FF commands. SfxN: NoiseNote. Sfx1/Sfx2: two notes per byte (as Tiny
; Toon 2). Music: hi = pitch, lo x unit (0: (unit & 15) x 16).
ReadCmds:
	ld a, [de]
	cp $E0
	jp nc, Command
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote
	bit 6, a
	jr z, MusicNote
	ld l, TRK_FLAGS3
	bit 0, [hl]
	jr z, .l4043
	res 0, [hl]
	dec de
	call NextCmd
.l403D:
	ld l, TRK_UNIT
	ld a, [hl]
	jp NoteLen
.l4043:
	set 0, [hl]
	ld a, [de]
	and $0F
	cp $0E
	jr c, .l4059
	inc de
	ld a, [de]
	jr z, .l4053
	jp Command
.l4053:
	ld l, TRK_UNIT
	ld [hl], a
	jp NextByte
.l4059:
	call NextCmd
	dec de
	jr .l403D

MusicNote:
	ld l, TRK_FLAGS
	res 2, [hl]
	call NextCmd
	dec de
	ld a, [de]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l4082
	ld b, a
	xor a
	bit 0, b
	jp nz, .l408A
	rrc b
.l4079:
	add a, c
	dec b
	jp nz, .l4079
	add a, a
	jp NoteLen
.l4082:
	swap c
	ld a, c
	and $F0
	jp NoteLen
.l408A:
	add a, c
	dec b
	jp nz, .l408A

; NoteLen: LEN = A. A rest mutes (NRx2 = 8); a drum-track rest goes to DrumNote, which
; ignores id 0.
NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l409C
	swap a
.l409C:
	ld l, TRK_FLAGS
	and $F0
	jp nz, Note
	set 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, DrumNote
	ld a, $08
	jp WriteVolume

; Note: release tick = length x gate / 16. A duty step writes its start duty. Autopan.
; Pitch 13 = the last pitch + an octave. Period from PeriodTable - 26 + 2 x pitch + octave +
; transpose, + detune (always added). Vibrato restarts. Volume ramp step. NRx2 = TRK_VOL -
; TRK_ATTEN (no borrow test) through WriteVolume.
Note:
	res 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jp z, .l40D6
	ld e, a
	ld b, $00
	ld hl, $0000
.l40CB:
	add hl, bc
	dec e
	jp nz, .l40CB
	ld a, l
	and $F0
	or h
	swap a
.l40D6:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l40E7
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l40E7:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l40F7
	swap a
.l40F7:
	and $F0
	cp $D0
	jp nz, .l4109
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, TRK_LASTPITCH
	ld a, [hl]
	jr .l4112
.l4109:
	swap a
	rlca
	ld l, TRK_LASTPITCH
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l4112:
	add a, c
	ld l, TRK_TRANSP
	ld c, [hl]
	add a, c
	ld c, a
	ld b, $00
	ld l, TRK_PITCHIDX
	ld [hl], a
	push hl
	ld hl, PeriodTable - 26
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l4164
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jp nc, .l414E
	set 4, [hl]
	jp .l4150
.l414E:
	res 4, [hl]
.l4150:
	set 2, [hl]
	ld l, TRK_VIBPTR
	ld a, [hl+]
	ld b, [hl]
	inc l
	ld [hl+], a
	ld [hl], b
	ld c, a
	inc l
	ld [hl], $01
	inc l
	ld a, [hl+]
	or a
	ld [hl], a
	call z, VibratoStep
.l4164:
	call WritePeriod

VolRampStep:
	ld l, TRK_PANFLAGS
	ld a, [hl]
	and $60
	jr z, .l4189
	ld l, TRK_RAMPCNT
	dec [hl]
	jr nz, .l4189
	ld l, TRK_RAMPSTEP
	ld a, [hl]
	ld l, TRK_RAMPCNT
	ld [hl], a
	ld l, TRK_PANFLAGS
	bit 6, [hl]
	ld l, TRK_ATTEN
	ld a, [hl]
	jr nz, .l4186
	sub $10
	jr .l4188
.l4186:
	add a, $10
.l4188:
	ld [hl], a
.l4189:
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	jp WriteVolume

; Sustain (not SfxN, Drm, rests): duty step countdown, vibrato (after its delay), then
; the release: NRx2 = TRK_RELVOL, or env | level + trigger (env 0: 8); CH3 steps NR32
; down every env ticks (with a release volume: once, then nothing). A pending long-note
; retrigger rewrites NRx2 at any tick but the release tick.
Sustain:
	ld a, [wTrackDesc]
	cp $63
	ret z
	cp $34
	ret z
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret nz
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l41B1
	dec [hl]
	jp nz, .l41B1
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l41B1:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, ReleaseTick
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, ReleaseTick
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	or a
	jp z, .l41CA
	dec [hl]
	jp ReleaseTick
.l41CA:
	ld l, TRK_VIBTIMER
	dec [hl]
	jp nz, ReleaseTick
	ld l, TRK_VIBCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	call WritePeriod
	jp ReleaseTick

; VibratoStep: one-byte steps, time << 4 | negative << 3 | offset x depth (semitone
; tables: time << 4 | code), $FB loop marker / $FB n, $FE mark / jump, $FF ends.
VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, .l423A
	cp $FE
	jp z, .l4274
	cp $FB
	jp z, .l4246
	ld l, TRK_VIBTIMER
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, TRK_VIBCUR
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	jp z, .l4234
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jp nz, VibratoSemitone
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l421C
	and $07
	jp z, .l4234
	cpl
	inc a
	ld e, a
	ld d, $FF
.l421C:
	ld a, [hl]
	or a
	jp z, .l4229
	ld b, a
	xor a
.l4223:
	add a, e
	dec b
	jp nz, .l4223
	ld e, a
.l4229:
	ld l, TRK_PERIOD + 1
	ld a, [hl-]
	ld l, [hl]
	push hl
	ld h, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ret
.l4234:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l423A:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	res 4, [hl]
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4246:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l425B
	set 4, [hl]
	ld l, TRK_VIBLOOP
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l425B:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l426A
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l426A:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l4274:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l4286
	set 5, [hl]
	inc bc
	ld l, TRK_VIBMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l4286:
	ld l, TRK_VIBMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l429F
	sub $0D
	jr z, .l429D
	dec a
	jr z, .l429B
	add a, $0B
.l429B:
	add a, $05
.l429D:
	add a, $13
.l429F:
	rlca
	ld c, a
	ld l, TRK_PITCHIDX
	ld a, [hl]
	add a, c
	ld e, a
	ld d, $00
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld b, a
	ld c, [hl]
	push hl
	ld hl, PeriodTable - 26
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, c
	ld l, b
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ret

ReleaseTick:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, ReleaseCh3
	cp [hl]
	jp z, .l42DA
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l42DA:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, WriteVolume8
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

ReleaseCh3:
	cp [hl]
	inc hl
	jp c, .l4321
	jp z, .l4315
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4315:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl+]
	ld [hl], a
	ret
.l4321:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	ret nz
	ld l, TRK_ENV
	ld a, [hl+]
	or a
	jp z, WriteVolume
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $7F
	or a
	ret z
	add a, $20
	cp $A0
	ret nc
	jp WriteVolume

; DrumNote: the drum hit id = the note's high nibble (0: nothing), started on the SFX
; tracks of its header, each with its own priority test.
DrumNote:
	ld a, [de]
	and $F0
	swap a
	ret z
	ld [wReqId], a
	ld hl, SoundTable - 2
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, StartDrumHit
	srl b
	ld hl, wTrkSfx2
	call c, StartDrumHit
	srl b
	ld hl, wTrkSfxN
	ret nc

StartDrumHit:
	ld a, [wReqPrio]
	cp [hl]
	jp c, .l43B1
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, $01
	ld [hl+], a
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [wWaveId], a
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ldh [c], a
	ld a, $C1
	cp h
	jp nz, .l43A0
	ld a, $08
	ld c, $10
	ldh [c], a
.l43A0:
	ld a, $C3
	cp h
	ret nz
	push bc
	ld b, $88
	ld l, TRK_PAN
	ld [hl], b
	ld c, $25
	ldh a, [c]
	or b
	ldh [c], a
	pop bc
	ret
.l43B1:
	inc de
	inc de
	ret

; NoiseNote: < $C0 NR43 = byte, NR44 = 0 (checked), retrigger if marked; $C0 marks a
; retrigger; $C1-$CF set the volume nibble and mark; $D0-$DF set it and retrigger now
; ($D0: NR42 = 8). Length = unit.
NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	call NextCmd
	cp $C0
	jr c, NoiseFreq
	jr nz, .l43CB
	ld l, TRK_FLAGS3
	set 2, [hl]
	jp ReadCmds
.l43CB:
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $0F
	ld [hl], a
	ld a, b
	and $0F
	swap a
	or [hl]
	ld [hl], a
	bit 4, b
	jr nz, .l43E3
	ld a, [hl]
	ld l, TRK_FLAGS3
	jp VoiceNoise.l44A8
.l43E3:
	ld a, b
	and $0F
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp nz, NoiseTrigger
	ld a, $08
	jp NoiseTrigger

NoiseFreq:
	ld e, a
	ld d, $00
	call WritePeriod
	ld l, TRK_FLAGS3
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]

NoiseTrigger:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld a, $80
	ldh [c], a
	ret

; Command: $E0 voice, $E1-$E6 octave (OctaveCodes), $E7-$FF through CommandTable (which
; the code indexes from CommandTable - 14).
Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
	cp $07
	jp c, Cmd_Octave
	push hl
	ld hl, CommandTable - 14
	call LoadPtrIndexed
	ld a, [de]
	jp hl
CommandTable:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_MasterVol
	dw Cmd_DutyStep
	dw Cmd_Tempo
	dw Cmd_Detune
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Volume
	dw Cmd_JumpN
	dw Cmd_Jump
	dw Cmd_Loop1
	dw Cmd_Loop2
	dw Cmd_CallRet
	dw Cmd_Mark
	dw Cmd_End

; Cmd_Voice: unit = u & $7F. Tone/wave: duty, vol, gate, env, autopan off, volume ramp
; off, attenuation 0, release volume 0, both sides; Sfx1/Sfx2 also set TRK_FLAGS3 bit 0
; (high nibble next). SfxN: NR42 = swap(v) at the next noise note.
Cmd_Voice:
	ld a, [de]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld l, TRK_FLAGS3
	ld a, [wTrackDesc]
	cp $63
	ld a, [de]
	inc de
	jr z, VoiceNoise
	ld a, [wTrackDesc]
	bit 6, a
	jr z, .l446F
	set 0, [hl]
.l446F:
	ld a, [de]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [de]
	and $0F
	swap a
	ld l, TRK_VOL
	ld [hl], a
	inc de
	ld a, [de]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld l, TRK_PANFLAGS
	res 0, [hl]
	res 5, [hl]
	res 6, [hl]
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_RELVOL
	ld [hl], a
	call PanBoth
	jp NextByte

VoiceNoise:
	ld a, [de]
	swap a
	inc de
.l44A8:
	set 2, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	jp ReadCmds

Cmd_Octave:
	ld c, a
	ld b, $00
	push hl
	ld hl, OctaveCodes - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	jp ReadCmds
OctaveCodes:
	db $18, $30, $48, $60, $78, $90

Cmd_LenUnit:
	pop hl
	ld l, TRK_UNIT
	ld [hl], a
	jp NextByte

Cmd_Release:
	pop hl
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	jp NextByte

Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	jp NextByte

; Cmd_Ext: $EA xy through ExtTable (16 entries).
Cmd_Ext:
	swap a
	and $0F
	ld hl, ExtTable
	call LoadPtrIndexed
	ld a, [de]
	jp hl
ExtTable:
	dw Ext_Duty
	dw Ext_PanBoth
	dw Ext_PanLeft
	dw Ext_PanRight
	dw Ext_Autopan
	dw Ext_AutopanBoth
	dw Ext_Nop
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_ReleaseVol
	dw Ext_Clear
	dw Ext_Nop
	dw Ext_Nop
	dw Ext_KeyTranspose
	dw Ext_TempoDown
	dw Ext_VolRamp

Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp NextByte

Ext_PanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	jp StopRampSetAtten

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l453F
.l4539:
	sla b
	dec a
	jp nz, .l4539
.l453F:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp WriteRegChecked

Ext_PanLeft:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanLeft
	jp StopRampSetAtten

Ext_PanRight:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanRight
	jp StopRampSetAtten

AutoPan:
	bit 7, [hl]
	jp nz, .l456E
	bit 1, [hl]
	jp nz, PanRight.l45A5
	set 1, [hl]
	jp PanRight
.l456E:
	bit 1, [hl]
	jp z, .l457C
	res 1, [hl]
	xor a
	call SetAtten
	jp PanBoth
.l457C:
	set 1, [hl]
	ld l, TRK_PANATTEN
	ld a, [hl]
	call SetAtten

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4599
.l4591:
	rlc b
	rlc l
	dec a
	jp nz, .l4591
.l4599:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l45A5:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l45BC
.l45B4:
	rlc b
	rlc l
	dec a
	jp nz, .l45B4
.l45BC:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked

Ext_Autopan:
	pop hl
	call AutopanSetup
	res 1, [hl]
	res 2, [hl]
	jp NextByte

AutopanSetup:
	ld a, [de]
	and $0F
	ld l, TRK_PANATTEN
	ld [hl], a
	ld l, TRK_PANFLAGS
	set 0, [hl]
	ret

Ext_AutopanBoth:
	pop hl
	call AutopanSetup
	set 7, [hl]
	set 1, [hl]
	jp NextByte

Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	jr SetTranspose

; Ext_KeyTranspose: TRK_TRANSP = 2 x ((hKey mod 3) + y).
Ext_KeyTranspose:
	pop hl
	and $0F
	ld b, a
	ldh a, [hKey]
.l45F5:
	cp $03
	jr nc, .l45FD
	add a, b
	rlca
	jr SetTranspose
.l45FD:
	sub $03
	jr .l45F5

; Ext_TempoDown: wTempo -= 3.
Ext_TempoDown:
	pop hl
	ld a, [wTempo]
	sub $03
	ld [wTempo], a
	jp NextByte

Ext_TransposeDown:
	pop hl
	and $0F
	jr z, SetTranspose
	rlca
	cpl
	inc a

SetTranspose:
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextByte

Ext_ReleaseVol:
	pop hl
	inc de
	and $0F
	swap a
	ld l, TRK_RELVOL
	ld [hl], a
	jp ReadCmds

; Ext_Clear: y bit 3 TRK_VIB = 0, bit 2 duty step off, bit 1 detune 0, bit 0 attenuation 0.
Ext_Clear:
	pop hl
	and $0F
	ld b, a
	xor a
	inc de
	bit 3, b
	jr z, .l4634
	ld l, TRK_VIB
	ld [hl], a
.l4634:
	bit 2, b
	jr z, .l463D
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld [hl-], a
	ld [hl], a
.l463D:
	bit 1, b
	jr z, .l4645
	ld l, TRK_DETUNE
	ld [hl+], a
	ld [hl], a
.l4645:
	bit 0, b
	jp z, ReadCmds
	ld l, TRK_ATTEN
	ld [hl], a
	jp ReadCmds

; Ext_VolRamp: y & 8: TRK_PANFLAGS bit 6 (quieter), y & 7 + 1 notes per step; else bit 5
; (louder), y + 1 notes per step. TRK_RAMPSTEP = TRK_RAMPCNT = the step.
Ext_VolRamp:
	pop hl
	and $0F
	ld l, TRK_PANFLAGS
	bit 3, a
	jr z, .l4661
	and $07
	set 6, [hl]
	res 5, [hl]
	jr .l4665
.l4661:
	set 5, [hl]
	res 6, [hl]
.l4665:
	inc a
	ld l, TRK_RAMPSTEP
	ld [hl], a
	ld l, TRK_RAMPCNT
	ld [hl], a
	jp NextByte

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l46B3
	bit 7, [hl]
	jp nz, .l46B6
	and $7F
	push hl
	ld hl, VibratoTable - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jr z, .l46AB
	ld b, a
	xor a
	bit 0, b
	jr nz, .l46A7
	rrc b
.l46A0:
	add a, c
	dec b
	jr nz, .l46A0
	add a, a
	jr .l46AB
.l46A7:
	add a, c
	dec b
	jr nz, .l46A7
.l46AB:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [de]
	and $0F
	inc l
	ld [hl], a
.l46B3:
	jp NextByte
.l46B6:
	and $7F
	push hl
	ld hl, Vibrato2Table - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_VIBDELAY
	ld [hl], $00
	jp NextByte

; Cmd_MasterVol: NR50 = x.
Cmd_MasterVol:
	pop hl
	ld c, $24
	ldh [c], a
	jp NextByte

Ext_Nop:
	pop hl
	jp NextByte

Cmd_DutyStep:
	pop hl
	and $F0
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld a, [de]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, WriteDuty
	jp NextByte

Cmd_Tempo:
	pop hl
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	jp NextByte

Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l4706
	ld a, $FF
.l4706:
	ld [hl], a
	jp NextByte

Cmd_Atten:
	pop hl
	dec de

StopRampSetAtten:
	ld l, TRK_PANFLAGS
	res 5, [hl]
	res 6, [hl]
	ld a, [de]
	call SetAtten
	jp NextByte

; SetAtten: TRK_ATTEN = y << 4 (CH3: cpl(rlc(y << 4))).
SetAtten:
	and $0F
	swap a
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l472A
	rlca
	cpl
.l472A:
	ld l, TRK_ATTEN
	ld [hl], a
	ret

; Cmd_Volume: TRK_VOL = swap(x), TRK_ATTEN = 0.
Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	ld b, a
	ld a, [wTrackDesc]
	cp $63
	jp nz, .l473E
	ld a, b ; dead: both paths clear A
.l473E:
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	jp NextByte

Cmd_JumpN:
	pop hl
	ld l, TRK_JUMPCNT
	inc [hl]
	cp [hl]
	inc de
	jp z, .l4752
	inc de
	jp NextByte
.l4752:
	xor a
	ld [hl], a
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Loop1:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l477B
	set 0, [hl]
	ld l, TRK_LOOP1
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l477B:
	ld l, TRK_LOOP1CNT
	inc [hl]
	cp [hl]
	jp z, .l4789
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l4789:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jp NextByte

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l47A7
	set 1, [hl]
	ld l, TRK_LOOP2
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l47A7:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l47B5
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l47B5:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jp NextByte

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l47D6
	set 2, [hl]
	inc de
	ld c, a
	ld a, [de]
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, a
	jp ReadCmds
.l47D6:
	res 2, [hl]
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

Cmd_Mark:
	pop hl
	ld l, TRK_FLOW
	bit 3, [hl]
	jp nz, .l47F2
	set 3, [hl]
	ld l, TRK_MARK
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l47F2:
	ld l, TRK_MARK
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; Cmd_End: clear priority and id. Drm: nothing else. Sfx1 (NR10 = 8) and Sfx2 give CH1 /
; CH3 back to a playing music track (NR51 bits, period, retrigger and reload marks). Then
; the channel is muted (CH3: NR32 = 0, else NRx2 = 8 + trigger).
Cmd_End:
	pop hl
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, .l482A
	cp $40
	jp z, .l4813
	jp MuteChannel
.l4813:
	ld l, TRK_FLAGS
	res 1, [hl]
	ld a, $08
	ld c, $10
	ldh [c], a
	push hl
	ld h, HIGH(wTrkCh1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, GiveBack
	pop hl
	jp MuteChannel
.l482A:
	ld l, TRK_FLAGS
	res 1, [hl]
	push hl
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, GiveBack
	pop hl
	jp MuteChannel

NextCmd:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

GiveBack:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l4859
.l4853:
	rlc b
	dec a
	jp nz, .l4853
.l4859:
	ld c, $25
	ldh a, [c]
	and b
	ld l, TRK_PAN
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	jp WritePeriod

LoadPtrIndexed:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

WritePeriod:
	ld l, TRK_LASTPERIOD
	ld [hl], e
	inc l
	ld a, d
	and $07
	ld [hl], a
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	call WriteRegChecked
	ret nc
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

MuteChannel:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l48A5
	ld a, $08
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG_NRX4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ret
.l48A5:
	xor a
	ld c, $1C
	jp WriteRegChecked

; WriteVolume: TRK_LASTVOL = A; NRx2 is only written (and triggered, not on CH3) when it
; reads back differently - on CH1 also while NR10 does not read 8.
WriteVolume:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, .l48C9
	ld a, [wTrackDesc]
	and $0F
	ret nz
	ld c, $10
	ldh a, [c]
	and $7F
	cp $08
	ret z
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
.l48C9:
	ld a, [hl]
	call WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

DeadSavePtr:
	call NextCmd ; unreachable

WriteVolume8:
	ld a, $08
	jr WriteVolume

; WriteDuty: NRx1 = A. CH3: the wave (high nibble) if it is not the one loaded (wWaveId);
; music Ch3 only keeps it while Sfx2 plays.
WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l48FC
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jp WriteRegChecked
.l48FC:
	ld a, [wTrackDesc]
	cp $22
	jp nz, .l4910
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_LASTDUTY
	ld [hl], b
	ret nz
.l4910:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld [wWaveId], a

LoadWave:
	push hl
	ld c, $1A
	xor a
	ldh [c], a
	ld a, b
	swap a
	ld hl, WaveTable - 2
	call LoadPtrIndexed
	ld c, $30
	ld b, $10
.l492E:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l492E
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteRegChecked: [C] = A unless music Ch1 while Sfx1 plays or music Ch3 while Sfx2 plays.
; Carry = written.
WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l4964
	cp $22
	jp nz, .l4970
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l4964:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l4970:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: priority and id of all tracks cleared; NRx2 = 8 on CH1, CH2, CH4, NR30 = 8 and
; NR32 = 8; triggers on CH1, CH2, CH4; NR51 = $FF.
StopAll:
	xor a
	ld hl, wTrkSfx1
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 1, [hl]
	ld hl, wTrkSfx2
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 1, [hl]
	ld hl, wTrkSfxN
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	ld c, $12
	ld a, $08
	ldh [c], a
	ld c, $17
	ldh [c], a
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
	ld c, $21
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
	ld c, $19
	ldh [c], a
	ld c, $23
	ldh [c], a
	ld a, $FF
	ld c, $25
	ldh [c], a
	ret

; SoundTable: ids $01-$63 (the code adds 2 * id to SoundTable - 2, the last two code bytes).
SoundTable:
	dw SndHdr01 ; $01
	dw SndHdr02 ; $02
	dw SndHdr03 ; $03
	dw SndHdr04 ; $04
	dw SndHdr05 ; $05
	dw SndHdr06 ; $06
	dw SndHdr07 ; $07
	dw SndHdr08 ; $08
	dw SndHdr09 ; $09
	dw SndHdr0A ; $0A
	dw SndHdr0B ; $0B
	dw SndHdr0C ; $0C
	dw SndHdr0D ; $0D
	dw SndHdr0E ; $0E
	dw SndHdr0F ; $0F
	dw SndHdr10 ; $10
	dw SndHdr11 ; $11
	dw SndHdr12 ; $12
	dw SndHdr13 ; $13
	dw SndHdr14 ; $14
	dw SndHdr15 ; $15
	dw SndHdr16 ; $16
	dw SndHdr17 ; $17
	dw SndHdr18 ; $18
	dw SndHdr19 ; $19
	dw SndHdr1A ; $1A
	dw SndHdr1B ; $1B
	dw SndHdr1C ; $1C
	dw SndHdr1D ; $1D
	dw SndHdr1E ; $1E
	dw SndHdr1F ; $1F
	dw SndHdr20 ; $20
	dw SndHdr21 ; $21
	dw SndHdr22 ; $22
	dw SndHdr23 ; $23
	dw SndHdr24 ; $24
	dw SndHdr25 ; $25
	dw SndHdr26 ; $26
	dw SndHdr27 ; $27
	dw SndHdr28 ; $28
	dw SndHdr29 ; $29
	dw SndHdr2A ; $2A
	dw SndHdr2B ; $2B
	dw SndHdr2C ; $2C
	dw SndHdr2D ; $2D
	dw SndHdr2E ; $2E
	dw SndHdr2F ; $2F
	dw SndHdr30 ; $30
	dw SndHdr31 ; $31
	dw SndHdr32 ; $32
	dw SndHdr33 ; $33
	dw SndHdr34 ; $34
	dw SndHdr35 ; $35
	dw SndHdr36 ; $36
	dw SndHdr37 ; $37
	dw SndHdr38 ; $38
	dw SndHdr39 ; $39
	dw SndHdr3A ; $3A
	dw SndHdr3B ; $3B
	dw SndHdr3C ; $3C
	dw SndHdr3D ; $3D
	dw SndHdr3E ; $3E
	dw SndHdr3F ; $3F
	dw SndHdr40 ; $40
	dw SndHdr41 ; $41
	dw SndHdr42 ; $42
	dw SndHdr43 ; $43
	dw SndHdr44 ; $44
	dw SndHdr45 ; $45
	dw SndHdr46 ; $46
	dw SndHdr47 ; $47
	dw SndHdr48 ; $48
	dw SndHdr49 ; $49
	dw SndHdr4A ; $4A
	dw SndHdr4B ; $4B
	dw SndHdr4C ; $4C
	dw SndHdr4D ; $4D
	dw SndHdr4E ; $4E
	dw SndHdr4F ; $4F
	dw SndHdr50 ; $50
	dw SndHdr51 ; $51
	dw SndHdr52 ; $52
	dw SndHdr53 ; $53
	dw SndHdr54 ; $54
	dw SndHdr55 ; $55
	dw SndHdr56 ; $56
	dw SndHdr57 ; $57
	dw SndHdr58 ; $58
	dw SndHdr59 ; $59
	dw SndHdr5A ; $5A
	dw SndHdr5B ; $5B
	dw SndHdr5C ; $5C
	dw SndHdr5D ; $5D
	dw SndHdr5E ; $5E
	dw SndHdr5F ; $5F
	dw SndHdr60 ; $60
	dw SndHdr61 ; $61
	dw SndHdr62 ; $62
	dw SndHdr63 ; $63

SndHdr01:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd07_Sfx1
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd08_Sfx1
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0D_SfxN

SndHdr0E:
	SND_HEADER $FF, $03 ; tracks: Sfx1, Sfx2
	dw Snd0E_Sfx1
	dw Snd0E_Sfx2

SndHdr0F:
	SND_HEADER $FF, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0F_Sfx1
	dw Snd0F_Sfx2
	dw Snd0F_SfxN

SndHdr10:
	SND_HEADER $20, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd10_SfxN
	dw Snd10_Ch1
	dw Snd10_Ch2
	dw Snd10_Ch3
	dw Snd0F_SfxN

SndHdr11:
	SND_HEADER $10, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd11_Ch1
	dw Snd11_Ch2
	dw Snd11_Ch3
	dw Snd11_Drm

SndHdr12:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd15_SfxN

SndHdr16:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd16_Sfx1
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd19_Sfx1
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd1A_Sfx1
	dw Snd19_SfxN

SndHdr1B:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd1B_Sfx1
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $71, $05 ; tracks: Sfx1, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $71, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $71, $05 ; tracks: Sfx1, SfxN
	dw Snd1E_Sfx1
	dw Snd1E_SfxN

SndHdr1F:
	SND_HEADER $71, $05 ; tracks: Sfx1, SfxN
	dw Snd1F_Sfx1
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd20_Sfx1
	dw Snd20_SfxN

SndHdr21:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd21_Sfx1
	dw Snd20_SfxN

SndHdr22:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd22_Sfx1
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $FF, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd23_Sfx1
	dw Snd23_Sfx2
	dw Snd23_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN

SndHdr24:
	SND_HEADER $FF, $7A ; tracks: Sfx2, Ch1, Ch2, Ch3, Drm
	dw Snd24_Sfx2
	dw Snd24_Ch1
	dw Snd24_Ch2
	dw Snd0F_SfxN
	dw Snd24_Drm

SndHdr25:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $91, $05 ; tracks: Sfx1, SfxN
	dw Snd27_Sfx1
	dw Snd26_SfxN

SndHdr28:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd28_Sfx1
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $81, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $FF, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd2A_Sfx1
	dw Snd0F_SfxN
	dw Snd2A_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN

SndHdr2B:
	SND_HEADER $FF, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd2B_Sfx1
	dw Snd0F_SfxN
	dw Snd2A_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN

SndHdr2C:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2D_Sfx1

SndHdr2E:
	SND_HEADER $7A, $05 ; tracks: Sfx1, SfxN
	dw Snd2E_Sfx1
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $7A, $05 ; tracks: Sfx1, SfxN
	dw Snd2F_Sfx1
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd30_SfxN

SndHdr31:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd31_SfxN

SndHdr32:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd32_SfxN

SndHdr33:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $80, $03 ; tracks: Sfx1, Sfx2
	dw Snd35_Sfx1
	dw Snd35_Sfx2

SndHdr36:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd2E_SfxN

SndHdr37:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd38_Sfx1
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd39_Sfx1
	dw Snd25_SfxN

SndHdr3A:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd3A_Sfx1
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd3C_Sfx1

SndHdr3D:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $7F, $01 ; tracks: Sfx1
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $81, $04 ; tracks: SfxN
	dw Snd3F_SfxN

SndHdr40:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd40_SfxN

SndHdr41:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $FF, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd42_Sfx1
	dw Snd42_Sfx2
	dw Snd0F_SfxN
	dw Snd42_Ch1
	dw Snd42_Ch2
	dw Snd42_Ch3
	dw Snd42_Drm

SndHdr43:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd43_Sfx1
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $FF, $05 ; tracks: Sfx1, SfxN
	dw Snd44_Sfx1
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd45_Sfx1
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd46_Sfx1
	dw Snd46_SfxN

SndHdr47:
	SND_HEADER $FF, $05 ; tracks: Sfx1, SfxN
	dw Snd47_Sfx1
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $FF, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd4B_SfxN

SndHdr4C:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd4C_SfxN

SndHdr4D:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd4D_Sfx1
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $FF, $05 ; tracks: Sfx1, SfxN
	dw Snd4E_Sfx1
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd4F_Sfx1

SndHdr50:
	SND_HEADER $40, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd50_Sfx1
	dw Snd0F_SfxN
	dw Snd50_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN
	dw Snd0F_SfxN

SndHdr51:
	SND_HEADER $40, $3D ; tracks: Sfx1, SfxN, Ch1, Ch2, Ch3
	dw Snd51_Sfx1
	dw Snd51_SfxN
	dw Snd51_Ch1
	dw Snd51_Ch2
	dw Snd51_Ch3

SndHdr52:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd52_Ch1
	dw Snd52_Ch2
	dw Snd52_Ch3
	dw Snd52_Drm

SndHdr53:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd53_Ch1
	dw Snd53_Ch2
	dw Snd53_Ch3
	dw Snd53_Drm

SndHdr54:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd54_Ch1
	dw Snd54_Ch2
	dw Snd54_Ch3
	dw Snd54_Drm

SndHdr55:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd55_Ch1
	dw Snd55_Ch2
	dw Snd55_Ch3
	dw Snd55_Drm

SndHdr56:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd56_Ch1
	dw Snd56_Ch2
	dw Snd56_Ch3
	dw Snd56_Drm

SndHdr57:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd57_Ch1
	dw Snd57_Ch2
	dw Snd57_Ch3
	dw Snd57_Drm

SndHdr58:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd58_Ch1
	dw Snd58_Ch2
	dw Snd58_Ch3
	dw Snd58_Drm

SndHdr59:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd59_Ch1
	dw Snd59_Ch2
	dw Snd59_Ch3
	dw Snd59_Drm

SndHdr5A:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5A_Ch1
	dw Snd5A_Ch2
	dw Snd5A_Ch3
	dw Snd5A_Drm

SndHdr5B:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5B_Ch1
	dw Snd5B_Ch2
	dw Snd5B_Ch3
	dw Snd5B_Drm

SndHdr5C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5C_Ch1
	dw Snd5C_Ch2
	dw Snd5C_Ch3
	dw Snd5C_Drm

SndHdr5D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5D_Ch1
	dw Snd5D_Ch2
	dw Snd5D_Ch3
	dw Snd5D_Drm

SndHdr5E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5E_Ch1
	dw Snd5E_Ch2
	dw Snd5E_Ch3
	dw Snd5E_Drm

SndHdr5F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5F_Ch1
	dw Snd5F_Ch2
	dw Snd5F_Ch3
	dw Snd5F_Drm

SndHdr60:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd60_Ch1
	dw Snd60_Ch2
	dw Snd60_Ch3
	dw Snd60_Drm

SndHdr61:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd61_Ch1
	dw Snd61_Ch2
	dw Snd61_Ch3
	dw Snd61_Drm

SndHdr62:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd62_Ch1
	dw Snd62_Ch2
	dw Snd62_Ch3
	dw Snd62_Drm

SndHdr63:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd63_Ch1
	dw Snd63_Ch2
	dw Snd63_Ch3
	dw Snd63_Drm

; WaveTable: 15 pointers (wave n = the high nibble of the duty byte; from WaveTable - 2),
; 9 distinct waves.
WaveTable:
	dw Wave_4D45 ; wave 1
	dw Wave_4D45 ; wave 2
	dw Wave_4D55 ; wave 3
	dw Wave_4D55 ; wave 4
	dw Wave_4D65 ; wave 5
	dw Wave_4D75 ; wave 6
	dw Wave_4D85 ; wave 7
	dw Wave_4D95 ; wave 8
	dw Wave_4DA5 ; wave 9
	dw Wave_4DA5 ; wave 10
	dw Wave_4DA5 ; wave 11
	dw Wave_4DB5 ; wave 12
	dw Wave_4DB5 ; wave 13
	dw Wave_4DB5 ; wave 14
	dw Wave_4DC5 ; wave 15
Wave_4D45:
	db $14, $7A, $DF, $DB, $A7, $41, $00, $00, $08, $00, $05, $37, $33, $33, $33, $33
Wave_4D55:
	db $56, $33, $00, $33, $66, $33, $00, $33, $66, $77, $88, $99, $AA, $BB, $CC, $FF
Wave_4D65:
	db $00, $00, $00, $00, $00, $00, $00, $00, $88, $88, $88, $88, $88, $88, $88, $88
Wave_4D75:
	db $00, $00, $17, $94, $00, $00, $00, $00, $88, $88, $88, $88, $88, $88, $88, $88
Wave_4D85:
	db $12, $34, $56, $78, $9A, $98, $76, $54, $56, $78, $9A, $BC, $DE, $FF, $00, $00
Wave_4D95:
	db $FF, $EE, $DD, $BB, $AA, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00, $00
Wave_4DA5:
	db $11, $88, $22, $77, $33, $66, $44, $55, $66, $79, $AC, $EE, $FF, $EF, $DC, $B7
Wave_4DB5:
	db $01, $23, $45, $67, $89, $AB, $CC, $CC, $01, $23, $45, $67, $89, $AB, $CC, $CC
Wave_4DC5:
	db $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; PeriodTable: 85 periods. Notes index it from PeriodTable - 26 by 2 * pitch +
; TRK_OCTAVE + TRK_TRANSP, so pitch 1 of OctaveCodes entry 1 is its first entry.
PeriodTable:
	dw $032, $0A2, $10C, $16F, $1CE, $226, $27A, $2CA, $315, $35B, $39E, $3DD ; octave index 0
	dw $419, $451, $486, $4B8, $4E7, $513, $53E, $565, $58B, $5AE, $5CF, $5EF ; octave index 1
	dw $60C, $628, $643, $65C, $674, $68A, $69F, $6B3, $6C5, $6D7, $6E8, $6F7 ; octave index 2
	dw $706, $714, $722, $72E, $73A, $745, $74F, $759, $763, $76B, $774, $77C ; octave index 3
	dw $783, $78A, $791, $797, $79D, $7A2, $7A8, $7AD, $7B1, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C5, $7C8, $7CB, $7CE, $7D1, $7D4, $7D6, $7D9, $7DB, $7DD, $7DF ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; VibratoTable: 11 pointers (EB n uses entry n; the code adds from VibratoTable - 2).
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib03 ; 3
	dw Vib04 ; 4
	dw Vib05 ; 5
	dw Vib05 ; 6
	dw Vib07 ; 7
	dw Vib08 ; 8
	dw Vib05 ; 9
	dw Vib0A ; 10
	dw Vib0B ; 11

Vib01:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib02:
	VIB_STEP 1, 1, 4
	VIB_STEP 15, 0, 0
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 1
	VIB_MARK

Vib03:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib04:
	VIB_STEP 3, 0, 6
	VIB_STEP 3, 0, 5
	VIB_STEP 3, 0, 4
	VIB_STEP 3, 0, 3
	VIB_STEP 3, 0, 2
	VIB_STEP 3, 0, 1
	VIB_STEP 7, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib07:
	VIB_STEP 4, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 7
	VIB_END

Vib08:
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib05:
	VIB_STEP 3, 1, 7
	VIB_STEP 3, 1, 6
	VIB_STEP 3, 1, 5
	VIB_STEP 3, 1, 4
	VIB_STEP 4, 1, 3
	VIB_STEP 4, 1, 2
	VIB_STEP 4, 1, 1
	VIB_STEP 4, 0, 0
	VIB_STEP 5, 0, 1
	VIB_STEP 5, 0, 2
	VIB_STEP 5, 0, 3
	VIB_STEP 6, 0, 4
	VIB_STEP 6, 0, 5
	VIB_STEP 6, 0, 6
	VIB_STEP 7, 0, 7
	VIB_END

Vib0A:
	VIB_STEP 1, 0, 7
	VIB_END

Vib0B:
	VIB_STEP 3, 0, 7
	VIB_STEP 3, 0, 6
	VIB_STEP 3, 0, 5
	VIB_STEP 3, 0, 4
	VIB_STEP 3, 0, 3
	VIB_STEP 3, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 7
	VIB_END

; Vibrato2Table: 16 semitone-step tables (EB n | $80; from Vibrato2Table - 2).
Vibrato2Table:
	dw VibSemi01 ; 1 (EB 1 | $80)
	dw VibSemi02 ; 2 (EB 2 | $80)
	dw VibSemi03 ; 3 (EB 3 | $80)
	dw VibSemi03 ; 4 (EB 4 | $80)
	dw VibSemi05 ; 5 (EB 5 | $80)
	dw VibSemi06 ; 6 (EB 6 | $80)
	dw VibSemi07 ; 7 (EB 7 | $80)
	dw VibSemi07 ; 8 (EB 8 | $80)
	dw VibSemi07 ; 9 (EB 9 | $80)
	dw VibSemi07 ; 10 (EB 10 | $80)
	dw VibSemi07 ; 11 (EB 11 | $80)
	dw VibSemi07 ; 12 (EB 12 | $80)
	dw VibSemi07 ; 13 (EB 13 | $80)
	dw VibSemi0E ; 14 (EB 14 | $80)
	dw VibSemi0F ; 15 (EB 15 | $80)
	dw VibSemi10 ; 16 (EB 16 | $80)
VibSemi01:
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi02:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi03:
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi05:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, $0C
	VIB_MARK
VibSemi06:
	VIB_LOOP_START
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_LOOP_END 3
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi07:
	VIB_MARK
	VIB_SEMI_STEP 1, $0B
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, 0
	VIB_MARK
VibSemi0E:
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi0F:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 8
	VIB_MARK
VibSemi10:
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 7
	VIB_MARK
	db $FF ; unreachable byte after an end

Snd01_SfxN:
	NVOICE $81, $04
	NOISE $1F
	NOISE_VOL 5
	NOISE $21
	NOISE_VOL 2
	NOISE $20
	SND_END

Snd02_SfxN:
	NVOICE $81, $04
	NOISE $14
	NOISE_VOL 1
	NOISE $20
	NOISE $10
	SND_END

Snd03_SfxN:
	NVOICE $82, $17
	NOISE $15
	NVOICE $90, $53
	NOISE $14
	SND_END

Snd04_SfxN:
	NVOICE $81, $06
	NOISE $4E
	NOISE_TRIG
	NOISE $27
	NVOICE $86, $12
	NOISE $32
	SND_END

Snd05_SfxN:
	NVOICE $81, $08
	NOISE $4E
	NOISE_TRIG
	NOISE $27
	NVOICE $86, $33
	NOISE $34
	SND_END

Snd06_SfxN:
	NVOICE $81, $0A
	NOISE $3D
	NVOICE $B0, $39
	NOISE $17
	SND_END

Snd0A_SfxN:
	NVOICE $81, $0F
	NOISE $5C
	NOISE_VOLNOTE 6
	SND_END

Snd0C_SfxN:
	NVOICE $81, $0A
	NOISE $5E
	NOISE_VOLNOTE 3
	SND_END

Snd0B_SfxN:
	NVOICE $90, $C1
	NOISE $16
	NVOICE $81, $02
	LOOP2_START
	LOOP_START
	NOISE $7F
	NOISE $19
	NOISE $24
	NOISE $37
	NOISE $57
	NOISE $6C
	NOISE $6E
	NOISE_TRIG
	LOOP_END 71
	LEN_UNIT $02
	LOOP2_END 2
	SND_END

Snd07_SfxN:
	NVOICE $81, $0F
	PAN_LEFT 0
	NOISE $4A
	NOISE $34
	LEN_UNIT $03
	NOISE_VOL 2
	NOISE $22
	NOISE_VOLNOTE 1
	SND_END

Snd07_Sfx1:
	VOICE $05, 8, 7, 15, 1
	PAN_LEFT 0
	SWEEP $2D
	OCTAVE 3
	NOTE_CMD $0C
	SND_END

Snd08_SfxN:
	NVOICE $81, $07
	NOISE $4A
	NOISE $34
	LEN_UNIT $03
	NOISE_VOL 2
	NOISE $22
	NOISE_VOLNOTE 1
	SND_END

Snd08_Sfx1:
	VOICE $05, 8, 7, 15, 1
	SWEEP $2D
	OCTAVE 3
	NOTE_CMD 3
	SND_END

Snd09_SfxN:
	NVOICE $81, $0D
	NOISE $4E
	NOISE_TRIG
	NOISE $27
	NVOICE $88, $16
	NOISE $34
	SND_END

; PlaySound: wReqId = id (0: StopAll). Header: priority, mask, pointers. If any SFX track
; of the mask holds a higher priority the mask is cleared and nothing starts. SFX tracks
; start without tests (SfxN also NR51 |= $88). Music needs the Ch1 bit and a priority >=
; Ch1's: it resets tempo and fade, NR10 = 8, and starts Ch1-Ch3/Drm. A started track: LEN 1,
; $85-$8F = 0, wWaveId = 0, TRK_FLAGS3/TRK_RELVOL = 0, NRx2 = 0.
PlaySound:
	ld a, [wReqId]
	or a
	jp z, StopAll
	ld hl, SoundTable - 2
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld e, l
	ld d, h
	rrc b
	ld hl, wTrkSfx1
	call c, CheckSfxPrio
	rrc b
	inc h
	call c, CheckSfxPrio
	rrc b
	inc h
	call c, CheckSfxPrio
	ld a, b
	rlca
	rlca
	rlca
	ld b, a
	srl b
	ld hl, wTrkSfx1
	call c, StartSfxTrack
	srl b
	ld hl, wTrkSfx2
	call c, StartSfxTrack
	srl b
	ld hl, wTrkSfxN
	call c, StartSfxTrack
	xor a
	ld [wC1CE], a
	srl b
	ret nc
	ld hl, wTrkCh1
	ld a, [wReqPrio]
	cp [hl]
	ret c
	xor a
	ld [wTempo], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld [wFadeStep], a
	ld [wC1C4], a
	ld a, $08
	ld c, $10
	ldh [c], a
	call StartMusicTrack
	srl b
	ld hl, wTrkCh2
	call c, StartMusicTrack
	srl b
	ld hl, wTrkCh3
	call c, StartMusicTrack
	srl b
	ld hl, wTrkDrm
	ret nc

StartMusicTrack:
	ld a, [wReqPrio]
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a

StartTrackCommon:
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, $01
	ld [hl+], a
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld [wWaveId], a
	ld l, TRK_FLAGS3
	ld [hl+], a
	ld [hl], a
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ldh [c], a
	ret

CheckSfxPrio:
	cp [hl]
	ret nc
	ld b, $00
	ret

StartSfxTrack:
	ld a, [wReqPrio]
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a
	call StartTrackCommon
	ld a, $C1
	cp h
	jp nz, .l50A6
	ld a, $08
	ld c, $10
	ldh [c], a
.l50A6:
	ld a, $C3
	cp h
	ret nz
	push bc
	ld b, $88
	ld l, TRK_PAN
	ld [hl], b
	ld c, $25
	ldh a, [c]
	or b
	ldh [c], a
	pop bc
	ret

; Orphan SfxN streams (no header points here; decoded as noise streams).
Data_50B7:
	NVOICE $81, $05
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE 1
	NOISE $46
	NOISE $27
	SND_END
Data_50C0:
	NVOICE $81, $0C
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE 3
	NOISE $44
	NOISE $25
	NOISE $17
	SND_END

Snd12_SfxN:
	NVOICE $81, $0F
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE 5
	NOISE $44
	NOISE $25
	NOISE $17
	NVOICE $86, $18
	NOISE $14

Snd0F_SfxN:
	SND_END

Snd13_SfxN:
	NVOICE $81, $0F
	NOISE $1F
	NOISE $6C
	NOISE_VOLNOTE 5
	NOISE $36
	NOISE $17
	NOISE $15
	NVOICE $86, $16
	NOISE $06
	SND_END

Snd14_SfxN:
	NVOICE $83, $93
	NOISE $07
	NVOICE $85, $19
	NOISE $15
	SND_END

Snd15_SfxN:
	NVOICE $81, $93
	NOISE $4F
	NVOICE $87, $1B
	NOISE $07
	SND_END

Snd16_Sfx1:
	VOICE $01, 8, 8, 0, 0
	SWEEP $1D
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTES 1, 8
	OCTAVE 3
	NOTES 1, 5
	NOTES $0A, 8
	OCTAVE 4
	NOTES 1, 5
	NOTES $0A, 8
	SND_END

; Orphan Sfx1 stream (no header points here).
Data_5109:
	VOICE $01, 4, 10, 0, 0
	SWEEP $14
	OCTAVE 4
	NOTES 8, 1
	NOTE_CMD 3
	OCTAVE 5
	NOTES 1, 8
	NOTES 3, 5
	OCTAVE 4
	NOTE_CMD 8
	OCTAVE 3
	NOTE_CMD 3
	SND_END

Snd16_SfxN:
	NVOICE $81, $0F
	NOISE $55
	NOISE $45
	NOISE $34
	NOISE $36
	NOISE $27
	NOISE $34
	NVOICE $84, $18
	NOISE $35
	SND_END

; Orphan SfxN stream (no header points here).
Data_5128:
	NVOICE $83, $39
	NOISE $14
	NVOICE $81, $09
	NOISE $24
	NOISE_VOL 6
	NOISE $26
	NOISE_VOL 4
	NOISE $34
	NOISE $36
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 1
	NOISE $46
	SND_END

Snd17_SfxN:
	NVOICE $81, $0F
	NOISE $6C
	NOISE $4E
	NOISE_TRIG
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $45
	NOISE $54
	SND_CALL Snd17_SfxN_5153
	NOISE_VOL 3
	SND_CALL Snd17_SfxN_5153
	NOISE_VOL 2
	SND_CALL Snd17_SfxN_5153
	SND_END
Snd17_SfxN_5153:
	LOOP_START
	NOISE $27
	NOISE $55
	NOISE $7F
	NOISE_TRIG
	NOISE $36
	NOISE $54
	NOISE $74
	NOISE $4F
	NOISE_VOL 5
	LOOP_END 2
	SND_RET

Snd18_SfxN:
	NVOICE $81, $0F
	SND_CALL Snd17_SfxN_5153
	SND_END

Snd19_Sfx1:
	VOICE $01, 4, 15, 0, 0
	SWEEP $1C
	VOLUME $0F
	DUTY 8
	LOOP2_START
	OCTAVE 4
	NOTES 4, 4
	NOTES 4, 4
	VOLUME $04
	LOOP_START
	NOTES 4, 4
	LOOP_END 5
	VOLUME $06
	LOOP2_END 2
	SND_END

Snd1A_Sfx1:
	VOICE $02, 4, 10, 0, 0
	OCTAVE 1
	LOOP_START
	NOTES 6, 3
	NOTE_CMD 1
	ATTEN 7
	LOOP_END 2
	SND_END

Snd19_SfxN:
	NVOICE $82, $0A
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 5
	NOISE $7F
	NOISE_VOL 3
	NOISE $54
	NOISE $1F
	NOISE_VOL 3
	LEN_UNIT $02
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 1
	NOISE $7F
	NOISE $54
	NOISE $1F
	SND_END

Snd1B_Sfx1:
	VOICE $02, 8, 10, 0, 0
	SWEEP $16
	OCTAVE 5
	NOTE_CMD 8
	ATTEN 2
	NOTE_CMD 8
	ATTEN 5
	NOTE_CMD 8
	ATTEN 6
	NOTE_CMD 8
	ATTEN 7
	NOTE_CMD 8
	VOLUME $02
	NOTE_CMD 8
	ATTEN 1
	NOTE_CMD 8
	SND_END

Snd1B_SfxN:
	NVOICE $81, $0F
	NOISE $49
	NOISE_VOL $0E
	NOISE $45
	NOISE_VOL $0A
	NOISE $49
	NOISE_VOL $0C
	NOISE $45
	NOISE_VOL 8
	NOISE $49
	NOISE_VOL 7
	NOISE $45
	NOISE_VOL 6
	NOISE $49
	NOISE_VOL 5
	NOISE $45
	NOISE_VOL 4
	NOISE $49
	NOISE_VOL 3
	NOISE $45
	LOOP_START
	NOISE_VOL 1
	NOISE $49
	NOISE_VOL 2
	NOISE $45
	LOOP_END 2
	SND_END

Snd1C_Sfx1:
	VOICE $01, 4, 15, 0, 0
	SWEEP $1D
	OCTAVE 4
	NOTES 3, 5
	NOTE_CMD $0A
	OCTAVE 3
	NOTES 8, 3
	OCTAVE 2
	NOTES 5, 8
	NOTE_CMD $0A
	SND_END

Snd1C_SfxN:
	NVOICE $81, $0F
	NOISE $3F
	LEN_UNIT $02
	NOISE_VOL 8
	NOISE $35
	NOISE_VOL 3
	NOISE $37
	LEN_UNIT $06
	NOISE $04
	SND_END

Snd1D_Sfx1:
	VOICE $02, 4, 4, 0, 0
	SWEEP $15
	LOOP_START
	OCTAVE 3
	NOTES 1, 4
	NOTE_CMD 7
	LOOP_END 3
	SND_END

Snd1D_SfxN:
	NVOICE $82, $06
	LOOP_START
	NOISE $1E
	NOISE_VOL $0F
	NOISE $55
	NOISE_VOL $0F
	NOISE $4E
	NOISE_VOL 6
	LOOP_END 3
	SND_END

Snd1E_Sfx1:
	VOICE $0A, 4, 10, 0, 0
	SWEEP $1C
	OCTAVE 3
	NOTE_CMD $0C
	SND_END

Snd1E_SfxN:
	NVOICE $81, $0F
	LOOP_START
	NOISE $4E
	NOISE $14
	NOISE $6C
	NOISE_VOL 2
	LOOP_END 3
	SND_END

Snd1F_Sfx1:
	VOICE $01, 4, 10, 0, 0
	SWEEP $14
	OCTAVE 3
	NOTES 1, 4
	ATTEN 7
	NOTES 2, 3
	NOTES 5, 3
	NOTE_CMD 4
	SND_END

Snd1F_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $35
	NOISE_VOLNOTE 4
	NOISE $6C
	NOISE $7C
	NOISE_VOL $0C
	NOISE $55
	LEN_UNIT $03
	NOISE_VOLNOTE 0
	NVOICE $82, $C8
	NOISE $55
	NOISE_VOL $0A
	NOISE $45
	NOISE_VOL $0C
	NOISE $35
	NVOICE $88, $1F
	NOISE $26
	NVOICE $81, $0F
	LOOP_START
	NOISE $2F
	NOISE $7F
	NOISE_VOL 3
	LOOP_END 2
	SND_END

Snd20_Sfx1:
	VOICE $01, 12, 15, 0, 0
	SWEEP $1E
	TRANSPOSE_UP 2
	SND_CALL Snd20_Sfx1_526F
	SND_END

Snd20_SfxN:
	NVOICE $85, $04
	NOISE $3E

Snd28_SfxN:
	NVOICE $81, $0F
	NOISE $4F
	NOISE $24
	NOISE_VOL 3
	NOISE $2F
	NOISE_VOL 1
	NOISE $1F
	NOISE_VOL 7
	NOISE $07
	SND_END
Snd20_Sfx1_526F:
	OCTAVE 3
	LOOP_START
	NOTES 4, 5
	NOTES 3, 4
	NOTES 1, 2
	OCTAVE 2
	NOTES $0C, $0B
	NOTES 9, $0A
	VOLUME $05
	OCTAVE 3
	LOOP_END 3
	VOLUME $02
	NOTES 0, 3
	OCTAVE 3
	NOTES 4, 5
	NOTES 3, 4
	NOTES 2, 1
	OCTAVE 2
	NOTES $0C, $0B
	NOTES 9, $0A
	SND_RET

Snd21_Sfx1:
	VOICE $01, 12, 15, 0, 0
	SWEEP $1E
	TRANSPOSE_UP 9
	SND_CALL Snd20_Sfx1_526F
	SND_END

Snd22_Sfx1:
	VOICE $03, 8, 10, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	NOTES 3, $0C
	VOLUME $06
	NOTES 2, $0B
	ATTEN 2
	NOTES 8, $0C
	NOTES 9, $0C
	NOTES 1, 9
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_UP 0
	OCTAVE 1
	NOTES $0A, 1
	NOTES 2, 1
	NOTES 2, 9
	NOTES 1, 2
	NOTES 6, $0C
	NOTES 7, $0C
	LEN_UNIT $07
	NOTE_UNIT 0, $01
	SND_END

Snd22_SfxN:
	NVOICE $85, $B3
	NOISE $18
	NOISE $19
	NOISE_TRIG
	NOISE $14
	NOISE $16
	NOISE $24
	NOISE $26
	NVOICE $82, $0F
	NOISE $57
	NOISE $4E
	NOISE_TRIG
	NOISE $6C
	NOISE $3E
	NOISE_TRIG
	NOISE $14
	NOISE $34
	NOISE $47
	NOISE $56
	NOISE $57
	NOISE $6D
	NOISE $7E
	NOISE $30
	NOISE $0F
	SND_END

Snd23_Sfx1:
	VOICE $01, 8, 15, 0, 0
	OCTAVE 3
	NOTES $0C, $0A
	NOTES 8, 6
	NOTES 3, 1
	RELEASE $0F, 4
	LEN_UNIT $30
	SWEEP $1E
	OCTAVE 5
	NOTE_CMD 5
	SND_END

Snd23_Sfx2:
	VOICE $01, 5, 2, 0, 0
	OCTAVE 6
	LOOP_START
	NOTES 8, 5
	NOTES 1, 8
	NOTES 5, 1
	TRANSPOSE_DOWN 1
	LOOP_END 2
	TRANSPOSE_DOWN 2
	LOOP_START
	NOTES 8, 5
	NOTES 1, 8
	NOTES 5, 1
	TRANSPOSE_DOWN 3
	VOLUME $04
	LOOP_END 2
	TRANSPOSE_DOWN 5
	LOOP_START
	NOTES 8, 5
	NOTES 1, 8
	NOTES 5, 1
	TRANSPOSE_DOWN 6
	VOLUME $06
	LOOP_END 2
	SND_END

Snd23_SfxN:
	NVOICE $82, $0F
	NOISE $6C
	NOISE $7F
	LEN_UNIT $01
	SND_CALL Snd23_SfxN_5344
	NVOICE $81, $0F
	NOISE $4F
	NOISE $6C
	NOISE_VOL 7
	NOISE $36
	NOISE $6C
	NOISE_TRIG
	SND_CALL Snd23_SfxN_5344
	NVOICE $82, $0F
	NOISE $24
	NOISE $55
	NOISE $4E
	NOISE $6D
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	NOISE $6C
	NVOICE $82, $90
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NVOICE $83, $0F
	LOOP_START
	NOISE $6D
	NOISE $6C
	NOISE $67
	NOISE $56
	SND_CALL Snd23_SfxN_5344
	NOISE $15
	NOISE $14
	NOISE_VOL 2
	LOOP_END 2
	SND_END
Snd23_SfxN_5344:
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $17
	NOISE $15
	NOISE $14
	SND_RET
	db $FF ; unreachable byte after an end

Snd24_Ch1:
	VOICE $06, 4, 10, 10, 3
	VIBRATO_SEMI 2
	DUTY_STEP 0, 2
	SND_CALL Snd24_Ch1_5399
	TRANSPOSE_UP 7
	SND_CALL Snd24_Ch1_5399
	TRANSPOSE_UP 5
	SND_JUMP Snd24_Ch1_537A

Snd24_Ch2:
	VOICE $06, 4, 8, 10, 3
	VIBRATO_SEMI 1
	DUTY_STEP 0, 2
	TRANSPOSE_DOWN 5
	SND_CALL Snd24_Ch1_5399
	TRANSPOSE_UP 2
	SND_CALL Snd24_Ch1_5399
	TRANSPOSE_UP 0
Snd24_Ch1_537A:
	LEN_UNIT $10
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 6
	DUTY_STEP 0, 0
	VIBRATO_OFF
	NOTE A_, 1
	LEN_UNIT $01
	NOTE A_, 3
	NOTE G#, 3
	NOTE G_, 3
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	SND_END
Snd24_Ch1_5399:
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_RET

Snd24_Sfx2:
	VOICE $06, 9, 2, 0, 0
	VIBRATO 2, 0, 7
	VIBRATO_SEMI 4
	OCTAVE 2
	NOTES 1, $0D
	NOTES 1, 3
	NOTES $0D, 3
	NOTES 4, $0D
	NOTES 4, 7
	NOTES $0D, 7
	RELEASE $0A, 0
	RELEASE_VOL 6
	LEN_UNIT $40
	OCTAVE 3
	NOTE_CMD 8
	SND_END

Snd24_Drm:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 4, 1
	LOOP_END 4
	DRUM 6, 0
	SND_END

Snd25_Sfx1:
	VOICE $03, 4, 10, 0, 0
	SWEEP $14
	OCTAVE 3
	NOTES 1, 2
	RELEASE $0F, 5
	SWEEP $1E
	LEN_UNIT $18
	OCTAVE 3
	NOTE_CMD $0A
	SND_END

Snd25_SfxN:
	NVOICE $82, $0F
	NOISE $4F
	NOISE $37
	NOISE_VOL 7
	NOISE $45
	NOISE_VOL 3
	NOISE $36
	NOISE_VOL 9
	LOOP_START
	NOISE $14
	NOISE $16
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd26_Sfx1:
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_DOWN 1
	OCTAVE 2
	NOTES 3, $0C
	NOTE_CMD 9
	ATTEN 5
	OCTAVE 2
	NOTES 3, $0C
	NOTES 9, 3
	NOTES $0C, 9
	SND_END

Snd26_SfxN:
	NVOICE $81, $0F
	NOISE $2E
	NOISE $35
	NOISE $37
	NOISE_VOLNOTE $0E
	NOISE_VOLNOTE $0A
	NOISE $44
	NOISE_VOLNOTE 8
	NOISE_VOLNOTE $0C
	NOISE $36
	NOISE $34
	NOISE $26
	SND_END

Snd27_Sfx1:
	VOICE $01, 12, 15, 0, 0
	SWEEP $25
	ATTEN 3
	NOTES 0, 0
	TRANSPOSE_UP 7
	OCTAVE 3
	NOTES 1, 2
	NOTES 1, 2
	NOTES 1, 2
	ATTEN 2
	NOTES 2, 3
	NOTES 3, 4
	ATTEN 1
	NOTES 4, 5
	NOTES 4, 5
	NOTES 4, 5
	NOTES 4, 5
	ATTEN 0
	ATTEN 2
	NOTES 5, 6
	ATTEN 3
	NOTES 4, 5
	NOTES 3, 4
	ATTEN 5
	NOTES 2, 3
	ATTEN 6
	NOTES 1, 2
	SND_END

Snd28_Sfx1:
	VOICE $01, 8, 8, 0, 0
	OCTAVE 4
	LOOP_START
	NOTES 1, 2
	NOTES 3, 5
	NOTES 7, 9
	NOTES $0A, $0B
	NOTE_CMD $0C
	VOLUME $02
	LOOP_END 2
	SND_END

Snd29_Sfx1:
	VOICE $01, 4, 10, 0, 0
	SWEEP $00
	OCTAVE 2
	NOTES 2, 4
	NOTES 5, 3
	OCTAVE 3
	LOOP_START
	NOTES 1, 3
	NOTES 2, 4
	NOTES 3, 5
	NOTES 4, 6
	NOTES 5, 7
	VOLUME $03
	LOOP_END 2
	SND_END

Snd29_SfxN:
	NVOICE $83, $0F
	NOISE $24
	SND_END
	db $FF ; unreachable byte after an end

Snd2C_Sfx1:
	VOICE $04, 8, 15, 15, 1
	TRANSPOSE_DOWN $0C
	LOOP_START
	OCTAVE 4
	NOTES 1, 6
	NOTES $0B, 6
	NOTE_CMD $0B
	OCTAVE 5
	NOTES 4, 9
	VOICE $04, 8, 4, 15, 11
	VIBRATO_OFF
	LOOP_END 2
	SND_END

Snd2D_Sfx1:
	VOICE $01, 8, 9, 0, 0
	OCTAVE 3
	LOOP_START
	NOTES 1, 5
	NOTES 2, 6
	NOTES 3, 7
	NOTES 5, 9
	NOTES 7, $0B
	NOTES 8, $0C
	VOLUME $0D
	TRANSPOSE_UP 2
	LOOP_END 2
	VOLUME $0F
	TRANSPOSE_UP 5
	LOOP_START
	NOTES 1, 5
	NOTES 2, 6
	NOTES 3, 7
	NOTES 5, 9
	NOTES 7, $0B
	NOTES 8, $0C
	TRANSPOSE_UP 9
	LOOP_END 2
	SND_END

Snd2A_Sfx1:
	TRANSPOSE_UP 2
	SWEEP $15
	VOICE $04, 12, 15, 0, 0
	ATTEN 3
	OCTAVE 4
	NOTES 3, 4
	NOTES 0, 0
	LEN_UNIT $02
	SWEEP $1D
	LOOP_START
	SND_CALL Snd2A_Sfx1_54AE
	VOLUME $03
	LOOP_END 2
	VOLUME $01
	SND_CALL Snd2A_Sfx1_54AE
	SND_END
Snd2A_Sfx1_54AE:
	OCTAVE 2
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	SND_RET

Snd2A_SfxN:
	NVOICE $82, $0F
	NOISE $3E
	NOISE $24
	NOISE $37
	NOISE $44
	NOISE_VOL 5
	NOISE $14
	NOISE $6C
	NVOICE $83, $0F
	LOOP_START
	SND_CALL Snd2A_SfxN_54D6
	NOISE_VOL 5
	LOOP_END 2
	NOISE_VOL 2
	SND_CALL Snd2A_SfxN_54D6
	SND_END
Snd2A_SfxN_54D6:
	NOISE $4F
	NOISE $7C
	NOISE $6E
	NOISE $6C
	NOISE $57
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $36
	NOISE $34
	NOISE $25
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $07
	NOISE $05
	NOISE $02
	SND_RET
	db $FF ; unreachable byte after an end

Snd2B_Sfx1:
	VOICE $01, 4, 3, 0, 0
	TRANSPOSE_DOWN 3
	LOOP2_START
	OCTAVE 6
	LOOP_START
	NOTES $0A, 9
	LOOP_END 5
	LOOP_START
	NOTES 8, 7
	LOOP_END 4
	NOTES 7, 6
	NOTES 7, 6
	NOTES 7, 6
	NOTES 6, 5
	NOTES 6, 5
	NOTES 5, 4
	VOLUME $01
	LOOP2_END 2
	SND_END

Snd2E_Sfx1:
	VOICE $02, 0, 11, 3, 2
	OCTAVE 2
	SWEEP $B3
	DUTY_STEP $0C, 2
	NOTE_CMD 8
	ATTEN 3
	NOTE_CMD 8
	LEN_UNIT $0A
	DUTY 8
	SWEEP $2E
	OCTAVE 4
	ATTEN 0
	NOTE_CMD 4
	ATTEN 3
	NOTE_CMD 4
	ATTEN 5
	NOTE_CMD 4
	SND_END

Snd2E_SfxN:
	NVOICE $82, $0B
	NOISE $8A
	NOISE $3A
	NOISE $6A
	LEN_UNIT $01
	NOISE_VOL 3
	NOISE $24
	SND_END

Snd2F_Sfx1:
	VOICE $09, 8, 15, 0, 0
	SWEEP $16
	OCTAVE 2
	NOTE_CMD 6
	VOLUME $02
	NOTE_CMD 6
	SND_END

Snd2F_SfxN:
	NVOICE $81, $0A
	LOOP_START
	NOISE $57
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd30_SfxN:
	NVOICE $82, $0F
	NOISE $14
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $35
	NVOICE $83, $48
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $47
	NOISE $6D
	NOISE $6E
	SND_END

Snd31_SfxN:
	NVOICE $83, $A2
	NOISE $6E
	NOISE $6D
	NOISE $57
	NOISE $47
	NOISE $46
	NOISE $44
	NOISE $36
	NVOICE $82, $0F
	NOISE $35
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $14
	SND_END

Snd32_SfxN:
	NVOICE $81, $2F
	LOOP_START
	SND_CALL Snd32_SfxN_5585
	NVOICE $81, $58
	LOOP_END 3
	NVOICE $81, $54
	LOOP_START
	SND_CALL Snd32_SfxN_5585
	LOOP_END 3
	SND_END
Snd32_SfxN_5585:
	NOISE $57
	NOISE $55
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $24
	NOISE $17
	NOISE $14
	NOISE_VOLNOTE 0
	SND_RET

Snd38_Sfx1:
	VOICE $09, 0, 15, 15, 2
	SWEEP $1D
	OCTAVE 3
	NOTE_CMD 3
	LEN_UNIT $1A
	SWEEP $3D
	OCTAVE 3
	NOTE_CMD 8
	SND_END

Snd38_SfxN:
	NVOICE $81, $CF
	NOISE $3E
	NOISE $4E
	NOISE $6C
	NOISE $37
	LEN_UNIT $06
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	LEN_UNIT $01
	LOOP_START
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd37_SfxN:
	NVOICE $84, $92
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NVOICE $95, $08
	NOISE $14
	NOISE_VOLNOTE $0A
	NOISE_VOLNOTE $0F
	NOISE_VOL $0A
	NVOICE $82, $91
	LOOP_START
	NOISE $6D
	NOISE $6C
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE_TRIG
	NVOICE $82, $02
	LOOP_END 2
	SND_END

Snd33_Sfx1:
	LOOP2_START
	VOICE $02, 8, 9, 0, 0
	TRANSPOSE_UP 7
	OCTAVE 5
	LOOP_START
	NOTES $0A, $0C
	NOTES $0B, $0A
	NOTES $0C, $0B
	VOLUME $02
	LOOP_END 2
	LOOP2_END 4
	SND_END

Snd34_Sfx1:
	VOICE $04, 8, 15, 0, 0
	SWEEP $1D
	DUTY_STEP 4, 2
	OCTAVE 2
	NOTE_UNIT 7, $07
	SWEEP $24
	OCTAVE 3
	NOTE_CMD 2
	VOLUME $02
	NOTE_CMD 2
	SND_END

Snd35_Sfx1:
	VOICE $01, 8, 7, 15, 11
	SWEEP $15
	OCTAVE 3
	NOTES 6, 3
	SWEEP $25
	LEN_UNIT $20
	OCTAVE 4
	NOTE_CMD 5
	SND_END

Snd35_Sfx2:
	VOICE $07, 8, 6, 0, 0
	NOTE_UNIT 0, $05
	VIBRATO 1, 0, 4
	OCTAVE 5
	NOTES 9, 9
	SND_END

Snd3A_Sfx1:
	VOICE $01, 8, 15, 0, 0
	OCTAVE 2
	NOTES 2, 3
	NOTES 4, 5
	NOTES 6, 7
	OCTAVE 1
	LOOP_START
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 2
	LOOP_END 2
	VOLUME $02
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	SND_END

Snd3A_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $55
	NOISE $6C
	NOISE_TRIG
	LOOP_START
	NOISE $14
	NOISE $16
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE $6C
	NOISE $6D
	NOISE_VOL 2
	LOOP_END 3
	SND_END

Snd36_Sfx1:
	VOICE $01, 4, 12, 0, 0
	TRANSPOSE_UP 3
	OCTAVE 2
	NOTES 2, 3
	NOTES 4, 5
	NOTES 6, 7
	OCTAVE 1
	LOOP_START
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 2
	LOOP_END 2
	SND_END

Snd3B_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $55
	NOISE $6C
	NOISE_TRIG
	LOOP_START
	NOISE $14
	NOISE $24
	NOISE $36
	NOISE $44
	NOISE $54
	NOISE $56
	NOISE $6C
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd3C_Sfx1:
	VOICE $01, 0, 8, 0, 0
	SWEEP $27
	ATTEN 7
	SND_CALL Snd3C_Sfx1_5698
	ATTEN 3
	SND_CALL Snd3C_Sfx1_5698
	ATTEN 0
	SND_CALL Snd3C_Sfx1_5698
	VOLUME $0A
	SND_CALL Snd3C_Sfx1_5698
	VOLUME $0C
	SND_CALL Snd3C_Sfx1_5698
	SND_END
Snd3C_Sfx1_5698:
	OCTAVE 5
	LOOP_START
	NOTES 1, 4
	LOOP_END 5
	SND_RET

Snd3D_Sfx1:
	VOICE $01, 4, 8, 0, 0
	SWEEP $27
	ATTEN 4
	OCTAVE 5
	NOTES 1, 4
	ATTEN 2
	NOTES 1, 4
	NOTES 1, 4
	ATTEN 0
	LOOP_START
	NOTES 1, 4
	NOTES 1, 4
	NOTES 1, 4
	NOTES 1, 4
	NOTES 1, 4
	VOLUME $02
	LOOP_END 2
	SND_END

Snd3E_Sfx1:
	VOICE $08, 8, 15, 14, 0
	RELEASE_VOL 3
	DUTY_STEP 4, 3
	DETUNE $02
	OCTAVE 6
	NOTE_CMD 8
	VOLUME $06
	RELEASE_VOL 2
	NOTE_CMD 8
	SND_END

Snd3F_SfxN:
	NVOICE $81, $0B
	SND_CALL Snd3F_SfxN_56D6
	NOISE_VOL 6
	LOOP_START
	SND_CALL Snd3F_SfxN_56D6
	LOOP_END 18
	SND_END
Snd3F_SfxN_56D6:
	NOISE $03
	NOISE_VOL 6
	NOISE $2A
	NOISE_VOL 6
	NOISE $3A
	NOISE $1A
	NOISE_VOL 6
	NOISE $4A
	NOISE $0A
	NOISE_VOL 6
	NOISE $3A
	NOISE $1A
	SND_RET

Snd40_SfxN:
	NVOICE $81, $3B
	NOISE $05
	NOISE $06
	NOISE $6D
	NOISE $17
	LEN_UNIT $02
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $34
	NOISE_VOL 5
	NVOICE $85, $0F
	NOISE $36
	NOISE_VOLNOTE $0D
	NOISE $37
	NOISE $44
	NOISE_VOLNOTE $0C
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd41_Sfx1:
	VOICE $02, 8, 4, 8, 7
	OCTAVE 4
	NOTES 8, 7
	NOTES 6, 5
	ATTEN 2
	NOTES 8, 7
	NOTES 6, 5
	ATTEN 3
	NOTES 8, 7
	NOTES 6, 5
	SND_END

Snd42_Sfx1:
	VOICE $01, 12, 15, 0, 0
	LOOP_START
	SND_CALL Snd42_Sfx1_571A
	VOLUME $0F
	LOOP_END 3
	SND_END
Snd42_Sfx1_571A:
	TRANSPOSE_UP 4
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	LEN_UNIT $10
	OCTAVE 4
	NOTE_CMD 1
	VOLUME $06
	NOTE_CMD 1
	LEN_UNIT $01
	SND_RET

Snd42_Sfx2:
	VOICE $01, 5, 2, 0, 0
	LOOP_START
	SND_CALL Snd42_Sfx1_571A
	VOLUME $04
	LOOP_END 3
	SND_END

Snd43_Sfx1:
	VOICE $02, 4, 10, 3, 7
	VIBRATO_SEMI $0D
	DUTY_STEP $0C, 1
	OCTAVE 4
	NOTES 1, 2
	NOTES 3, 4
	LOOP2_START
	LOOP_START
	NOTES 5, 5
	LOOP_END 5
	VOLUME $03
	LOOP2_END 2
	SND_END

Snd43_SfxN:
	NVOICE $82, $08
	NOISE_VOL $0C
	NOISE $4E
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	NOISE $3E
	NVOICE $88, $1A
	NOISE $24
	NVOICE $90, $B1
	NOISE $14
	LEN_UNIT $01
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $6C
	SND_END

Snd4B_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NVOICE $81, $17
	LOOP_START
	NOISE $15
	NOISE $35
	NOISE_VOL 2
	LOOP_END 3
	NVOICE $81, $4A
	NOISE_VOL $0C
	NOISE $15
	NOISE $35
	NOISE $15
	NOISE_VOL 8
	NOISE $15
	NOISE $35
	NOISE $15
	NOISE_VOL 4
	NOISE $15
	NOISE $35
	NOISE $15
	NOISE_VOL 2
	NOISE $15
	NOISE $35
	NOISE $15
	SND_END

Snd4A_Sfx1:
	VOICE $04, 8, 9, 15, 9
	SWEEP $26
	OCTAVE 3
	NOTES 1, 5
	NOTE_UNIT 3, $08
	NOTE_CMD 6
	ATTEN 4
	RELEASE 0, 0
	NOTE_CMD 6
	SND_END

Snd4C_SfxN:
	NVOICE $81, $95
	NOISE $4E
	NOISE $6C
	NOISE_TRIG
	NOISE $6E
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NVOICE $07, $0F
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	NOISE_VOLNOTE 2
	SND_END

Snd4D_Sfx1:
	MASTER_VOL $77
	VOICE $02, 4, 15, 0, 0
	SWEEP $19
	OCTAVE 3
	LOOP2_START
	LOOP_START
	NOTES 4, 4
	LOOP_END 3
	VOLUME $02
	LOOP2_END 2
	SND_END

Snd4D_SfxN:
	NVOICE $82, $0F
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 8
	NOISE $7F
	NOISE_VOL 3
	NOISE $54
	NOISE $1F
	NOISE_VOL 4
	LEN_UNIT $02
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 2
	NOISE $7F
	NOISE_VOL 1
	NOISE $54
	NOISE $1F
	NOISE_VOL 2
	LEN_UNIT $04
	NOISE_VOLNOTE 0
	NVOICE $8C, $1F
	NOISE $34
	SND_END

Snd4E_Sfx1:
	VOICE $01, 0, 15, 0, 0
	ATTEN 7
	SWEEP $1F
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 6
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	ATTEN 4
	NOTE_CMD 5
	ATTEN 4
	NOTE_CMD 5
	ATTEN 3
	NOTE_CMD 5
	ATTEN 2
	NOTE_CMD 5
	ATTEN 1
	NOTE_CMD 5
	ATTEN 0
	NOTE_CMD 5
	SND_END

Snd4E_SfxN:
	NVOICE $81, $93
	NOISE $36
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $16
	NOISE $14
	NOISE $07
	NOISE_TRIG
	NOISE $04
	SND_END

Snd39_Sfx1:
	VOICE $09, 8, 10, 0, 0
	SWEEP $1F
	OCTAVE 4
	NOTE_CMD 3
	VOLUME $02
	NOTE_CMD 3
	SND_END

Snd4F_Sfx1:
	VOICE $03, 8, 10, 0, 0
	DUTY_STEP 4, 1
	TEMPO_DOWN 0
	OCTAVE 5
	NOTES 3, $0D
	VOLUME $02
	NOTES 3, $0D
	NOTES 3, $0D
	SND_END

Snd44_Sfx1:
	VOICE $1C, 4, 7, 0, 0
	SWEEP $1F
	NOTE_UNIT 0, $01
	OCTAVE 5
	TRANSPOSE_UP 7
	NOTES 1, 1
	NOTES 1, 1
	NOTES 1, 1
	NOTES 2, 2
	NOTES 2, 2
	NOTES 2, 2
	NOTES 3, 3
	NOTES 3, 3
	NOTES 3, 3
	NOTES 4, 4
	NOTES 4, 4
	NOTES 4, 4
	NOTES 5, 5
	NOTES 5, 5
	NOTES 5, 5
	NOTES 6, 6
	NOTES 6, 6
	NOTES 6, 6
	NOTES 7, 7
	NOTES 7, 7
	NOTES 7, 7
	LOOP_START
	NOTES 8, 8
	NOTES 8, 8
	NOTES 8, 8
	NOTES 9, 9
	NOTES 9, 9
	NOTES 9, 9
	NOTES $0A, $0A
	NOTES $0A, $0A
	NOTES $0A, $0A
	NOTES $0B, $0B
	NOTES $0B, $0B
	NOTES $0B, $0B
	NOTES $0C, $0C
	NOTES $0C, $0C
	NOTES $0C, $0C
	ATTEN 6
	LOOP_END 2
	ATTEN 6
	SND_END

Snd44_SfxN:
	NVOICE $82, $0F
	NOISE $7F
	NOISE $6D
	NOISE $4F
	NOISE $24
	NVOICE $88, $1F
	NOISE $14
	NOISE $15
	NVOICE $85, $04
	NOISE $4F
	NOISE $4E
	NOISE $4C
	NOISE $4A
	NOISE $3F
	LOOP_START
	NOISE $3D
	NOISE $3A
	NOISE $2F
	NOISE $2D
	NOISE $2B
	NVOICE $85, $02
	LOOP_END 2
	SND_END

Snd45_Sfx1:
	VOICE $01, 4, 10, 0, 0
	SWEEP $2D
	TRANSPOSE_DOWN 3
	OCTAVE 4
	NOTES 9, $0B
	NOTES 8, $0A
	NOTES 7, 9
	NOTES 7, 9
	NOTES 6, 8
	NOTES 5, 7
	NOTES 5, 7
	LOOP_START
	NOTES 4, 6
	LOOP_END 3
	LOOP_START
	NOTES 3, 5
	LOOP_END 4
	NOTES 2, 4
	NOTES 2, 4
	NOTES 1, 3
	NOTES 1, 3
	NOTES 1, 3
	SND_END

Snd45_SfxN:
	NVOICE $84, $A3
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $6D
	NVOICE $81, $0F
	NOISE $6D
	NOISE $7F
	NOISE $4F
	NOISE $35
	NVOICE $81, $3F
	LOOP_START
	SND_CALL Snd45_SfxN_58BF
	LOOP_END 2
	NOISE_VOL 2
	SND_CALL Snd45_SfxN_58BF
	SND_END
Snd45_SfxN_58BF:
	NOISE $37
	NOISE $34
	NOISE $44
	NOISE $54
	NOISE $64
	NOISE $75
	NOISE $45
	NOISE $55
	NOISE $56
	NOISE $57
	SND_RET

Snd46_Sfx1:
	VOICE $7F, 0, 4, 0, 0
	NOTE_CMD 0
Snd46_Sfx1_58CF:
	VOICE $01, 4, 10, 0, 0
	SWEEP $2D
	ATTEN 7
	SND_CALL Snd46_Sfx1_58F3
	ATTEN 4
	SND_CALL Snd46_Sfx1_58F3
	ATTEN 3
	SND_CALL Snd46_Sfx1_58F3
	ATTEN 2
	SND_CALL Snd46_Sfx1_58F3
	ATTEN 1
	SND_CALL Snd46_Sfx1_58F3
	ATTEN 0
	SND_CALL Snd46_Sfx1_58F3
	VOLUME $02
	SND_CALL Snd46_Sfx1_58F3
	SND_END
Snd46_Sfx1_58F3:
	OCTAVE 3
	NOTES $0A, $0D
	NOTES 9, $0D
	NOTES 8, $0D
	NOTES 7, $0D
	NOTES 6, $0D
	NOTES 5, $0D
	NOTES 4, $0D
	NOTES 3, $0D
	NOTES 2, $0D
	NOTES 1, $0D
	NOTES 1, $0D
	SND_RET

Snd46_SfxN:
	LEN_UNIT $7F
	NOISE_VOLNOTE 0
Snd46_SfxN_5903:
	NVOICE $82, $03
	SND_CALL Snd46_SfxN_591D
	NOISE_VOL 5
	SND_CALL Snd46_SfxN_591D
	NOISE_VOL 8
	SND_CALL Snd46_SfxN_591D
	NOISE_VOL $0A
	LOOP_START
	SND_CALL Snd46_SfxN_591D
	LOOP_END 3
	NOISE_VOL 1
	SND_CALL Snd46_SfxN_591D
	SND_END
Snd46_SfxN_591D:
	NOISE $7F
	NOISE $6D
	NOISE $57
	NOISE $47
	NOISE $45
	NOISE_TRIG
	NOISE $37
	NOISE $35
	NOISE $37
	NOISE $46
	NOISE $56
	NOISE $6D
	SND_RET

Snd47_Sfx1:
	VOICE $06, 8, 2, 0, 0
	SWEEP $16
	LOOP_START
	OCTAVE 4
	NOTES $0C, 9
	NOTES 5, 2
	SWEEP $14
	OCTAVE 3
	NOTES $0C, 9
	NOTES 6, 2
	VOLUME $02
	LOOP_END 2
	SND_JUMP Snd46_Sfx1_58CF

Snd47_SfxN:
	SND_CALL Snd0D_SfxN_5994
	SND_JUMP Snd46_SfxN_5903

Snd49_SfxN:
	NVOICE $82, $09
	NOISE $4D
	NOISE $6D
	NVOICE $81, $93
	LOOP_START
	NOISE $46
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $16
	NOISE $14
	NOISE_VOLNOTE 0
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd48_Sfx1:
	VOICE $01, 0, 6, 0, 0
	LOOP_START
	OCTAVE 6
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	OCTAVE 5
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	ATTEN 4
	LOOP_END 3
	SND_END

Snd48_SfxN:
	NVOICE $85, $08
	LOOP_START
	NOISE $14
	NOISE $16
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE $6D
	NOISE $7F
	NOISE_VOL 1
	LOOP_END 2
	SND_END

Snd0D_SfxN:
	SND_CALL Snd0D_SfxN_5994
	NVOICE $88, $01
	SND_SEGNO
	NOISE $6D
	SND_LOOP
Snd0D_SfxN_5994:
	NVOICE $81, $0F
	NOISE $2E
	NOISE $6C
	NOISE $2F
	NOISE $55
	LEN_UNIT $02
	NOISE $34
	NOISE $45
	NOISE $55
	NOISE $4F
	NVOICE $81, $0F
	NOISE $05
	NOISE $06
	NOISE $07
	NVOICE $82, $3F
	NOISE $16
	NOISE $17
	NOISE $34
	NOISE $35
	NOISE $36
	LOOP_START
	NOISE $37
	NOISE $45
	NOISE $46
	NOISE $47
	NVOICE $83, $03
	LOOP_END 3
	LOOP_START
	NOISE $37
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE_VOL 1
	LOOP_END 3
	SND_RET

Snd0F_Sfx1:
	VOICE $04, 8, 5, 15, 2
	DUTY_STEP $0C, 1
	DETUNE $FF
	LOOP_START
	OCTAVE 6
	NOTES 7, 0
	VOLUME $0A
	LOOP_END 2
	SND_END

Snd0F_Sfx2:
	VOICE $04, 5, 6, 15, 1
	TRANSPOSE_UP $0C
	LOOP_START
	OCTAVE 6
	NOTES 7, 0
	VOLUME $04
	LOOP_END 2
	SND_END

Snd10_Ch1:
	VOICE $0D, 8, 3, 0, 0
	REST 4
	LEN_UNIT $02
	REST 2
	ATTEN 1
Snd10_Ch1_59E9:
	LOOP2_START
	TRANSPOSE_UP 2
	SND_CALL Snd10_Ch1_5A01
	VOLUME $01
	SND_CALL Snd10_Ch1_5A1C
	SND_CALL Snd10_Ch1_5A31
	SND_JUMP_N 3, Snd10_Ch1_59FE
	SND_CALL Snd10_Ch1_5A36
Snd10_Ch1_59FE:
	LOOP2_END 3
	SND_END
Snd10_Ch1_5A01:
	VIBRATO 9, 0, 0
	LEN_UNIT $03
	OCTAVE 4
	NOTE A#, 2
	LEN_UNIT $28
	NOTE B_, 2
	VIBRATO 10, 0, 0
	NOTE B_, 1
	VIBRATO 11, 0, 0
	LEN_UNIT $14
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_RET
Snd10_Ch1_5A1C:
	VIBRATO 11, 0, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	VIBRATO 11, 0, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO_OFF
	SND_RET
Snd10_Ch1_5A31:
	TRANSPOSE_DOWN 1
	LEN_UNIT $02
	SND_RET
Snd10_Ch1_5A36:
	OCTAVE 3
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	LOOP_END 2
	SND_RET

Snd10_Ch2:
	VOICE $27, 8, 2, 0, 0
	REST 2
	LEN_UNIT $01
Snd10_Ch2_5A4F:
	PAN_LEFT 0
	LOOP2_START
	LOOP_START
	OCTAVE 5
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 47
	PAN_RIGHT 0
	LOOP2_END 2
	SND_END

Snd10_Ch3:
	VOICE $0D, 7, 6, 0, 0
	REST 4
	LEN_UNIT $02
Snd10_Ch3_5A72:
	LOOP2_START
	TRANSPOSE_UP 2
	SND_CALL Snd10_Ch1_5A01
	SND_CALL Snd10_Ch1_5A1C
	SND_CALL Snd10_Ch1_5A31
	SND_JUMP_N 3, Snd10_Ch3_5A85
	SND_CALL Snd10_Ch1_5A36
Snd10_Ch3_5A85:
	LOOP2_END 3
	SND_END

Snd10_SfxN:
	NVOICE $88, $92
	NOISE $44
	NOISE $44
	NVOICE $81, $0F
	NOISE $4E
	NOISE $7F
	NOISE $6D
	NVOICE $85, $1F
	NOISE $24
	NOISE $24
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NVOICE $93, $01
	LOOP_START
	NOISE $6C
	NOISE_TRIG
	LOOP_END 56
	SND_END

Snd11_Ch1:
	VOICE $02, 8, 3, 0, 0
	OCTAVE 1
	SND_JUMP Snd10_Ch1_59E9

Snd11_Ch3:
	VOICE $02, 7, 6, 0, 0
	REST 1
	SND_JUMP Snd10_Ch3_5A72

Snd11_Ch2:
	VOICE $01, 8, 4, 0, 0
	SND_JUMP Snd10_Ch2_5A4F

Snd11_Drm:
	DRUM $0B, 3
	SND_END

Snd50_Sfx1:
	VOICE $02, 8, 8, 0, 0
	SWEEP $14
	OCTAVE 3
	NOTES 1, 2
	NOTE_UNIT 3, $12
	SWEEP $1C
	OCTAVE 3
	NOTE_CMD 1
	VOLUME $01
	NOTE_CMD 1
	SND_END

Snd50_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $6D
	NOISE $7F
	NOISE $26
	NVOICE $83, $2A
	LOOP_START
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $55
	NOISE $57
	NOISE $6C
	NOISE $6E
	NVOICE $83, $02
	LOOP_END 2
	SND_END

Snd51_Sfx1:
	VOICE $02, 4, 5, 0, 0
	SWEEP $14
	LOOP_START
	OCTAVE 2
	NOTES 1, 2
	NOTES 8, 6
	NOTES 4, 6
	LOOP_END 7
	VOLUME $02
	LOOP_START
	OCTAVE 2
	NOTES 1, 2
	NOTES 8, 6
	NOTES 4, 6
	LOOP_END 4
	SND_END

Snd51_SfxN:
	NVOICE $81, $0F
	NOISE $3F
	NOISE_TRIG
	NOISE $55
	NOISE $7F
	NOISE $6D
	NOISE $25
	NOISE_VOLNOTE $0A
	LEN_UNIT $0A
	NOISE $35
	NOISE $5D
	NOISE $6E
	NOISE $7F
	NOISE $6D
	NOISE_VOLNOTE 8
	NOISE_VOLNOTE 6
	NOISE_VOLNOTE 4
	NOISE_VOLNOTE 2
	NOISE_VOL 2
	NOISE $7F
	NOISE $6D
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd51_Ch2:
	VOICE $56, 12, 3, 0, 0
	REST 2
	LEN_UNIT $01
	SND_SEGNO
	SND_CALL Snd51_Ch2_5B29
	SND_LOOP
Snd51_Ch2_5B29:
	TRANSPOSE_UP 4
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT $10
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 1
	LEN_UNIT $01
	SND_RET

Snd51_Ch3:
	VOICE $58, 7, 4, 0, 0
	REST 2
	LEN_UNIT $01
	DETUNE $FC
	SND_SEGNO
	SND_CALL Snd51_Ch2_5B29
	SND_LOOP

Snd51_Ch1:
	VOICE $56, 4, 1, 0, 0
	SWEEP $17
	OCTAVE 5
	REST 2
	LEN_UNIT $01
	SND_SEGNO
	NOTE C_, 1
	NOTE C#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 6
	NOTE F_, 1
	NOTE D_, 1
	SND_LOOP

Snd0E_Sfx1:
	VOICE $02, 8, 4, 15, 1
	NOTES 0, 1
	LEN_UNIT $04
	DETUNE $FE
	LOOP_START
	SND_CALL Snd0E_Sfx1_5B7A
	ATTEN 3
	LOOP_END 2
	ATTEN 3
	SND_END
Snd0E_Sfx1_5B7A:
	OCTAVE 3
	NOTES 5, 9
	NOTES $0C, 9
	NOTE_CMD $0C
	OCTAVE 4
	NOTE_CMD 5
	SND_RET

Snd0E_Sfx2:
	VOICE $04, 5, 2, 15, 2
	VIBRATO_SEMI 2
	LOOP_START
	TRANSPOSE_UP $0C
	SND_CALL Snd0E_Sfx1_5B7A
	VOLUME $06
	LOOP_END 2
	SND_END
	db $FF ; unreachable byte after an end

Snd61_Ch2:
	TEMPO $20
	TRANSPOSE_UP $0C
	SND_CALL Snd61_Ch1_5D73
	LEN_UNIT $03
	REST 8
	TRANSPOSE_DOWN 0
	SND_SEGNO
	VOICE $03, 8, 8, 10, 1
	DUTY_STEP 0, 1
	VIBRATO_SEMI 2
	DETUNE $FD
	AUTOPAN 0
	SND_CALL Snd61_Ch1_5C12
	SND_CALL Snd61_Ch1_5C63
	DETUNE $00
	LOOP2_START
	VOICE $03, 4, 8, 9, 7
	VIBRATO 1, 6, 4
	DUTY_STEP 0, 1
	SND_CALL Snd61_Ch2_5C24
	NOTE D#, 8
	SND_CALL Snd61_Ch2_5C55
	RELEASE_VOL 3
	NOTE F#, 8
	SND_CALL Snd61_Ch2_5C24
	NOTE D#, 4
	SND_CALL Snd61_Ch2_5C55
	NOTE F#, 2
	ATTEN 1
	NOTE G_, 2
	RELEASE 8, 7
	RELEASE_VOL 3
	ATTEN 0
	NOTE A_, 0
	REST 2
	VIBRATO 8, 0, 0
	DUTY 0
	RELEASE 2, 2
	RELEASE_VOL 3
	ATTEN 3
	OCTAVE 4
	NOTE A#, 0
	ATTEN 1
	SND_JUMP_N 2, Snd61_Ch2_5BEF
	NOTE A_, 0
	ATTEN 0
	NOTE G_, 0
	ATTEN 2
	NOTE A_, 6
Snd61_Ch2_5BEF:
	LOOP2_END 2
	NOTE B_, 0
	ATTEN 0
	OCTAVE 5
	NOTE D_, 0
	ATTEN 1
	OCTAVE 4
	NOTE G_, $0A
	ATTEN 3
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G#, 1
	LOOP2_START
	SND_CALL Snd61_Ch2_5C34
	SND_CALL Snd61_Ch1_5C72
	SND_CALL Snd61_Ch2_5C34
	SND_CALL Snd61_Ch1_5C80
	LOOP2_END 2
	SND_LOOP
Snd61_Ch1_5C12:
	TRANSPOSE_DOWN $0C
Snd61_Ch1_5C14:
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	NOTE D#, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	SND_RET
Snd61_Ch2_5C24:
	RELEASE_VOL 0
	ATTEN 2
	OCTAVE 2
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE_VOL 3
	SND_RET
Snd61_Ch2_5C34:
	VOICE $03, 0, 8, 9, 7
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	NOTE A_, 2
	AUTOPAN_BOTH 5
	OCTAVE 3
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	PAN_BOTH 0
	LOOP_END 2
	RELEASE 0, 0
	DUTY_STEP 0, 0
	DUTY 8
	VIBRATO_OFF
	ATTEN 2
	SND_RET
Snd61_Ch2_5C55:
	RELEASE_VOL 0
	ATTEN 2
	OCTAVE 2
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	SND_RET
Snd61_Ch1_5C63:
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	TRANSPOSE_DOWN 0
	SND_RET
Snd61_Ch1_5C72:
	OCTAVE 3
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE F#, 1
	SND_RET
Snd61_Ch1_5C80:
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	ATTEN 1
	NOTE A#, 1
	ATTEN 2
	NOTE A_, 1
	SND_RET

Snd61_Ch1:
	DETUNE $01
	SND_CALL Snd61_Ch1_5D73
	LEN_UNIT $03
	REST 8
	SND_SEGNO
	VOICE $03, 4, 5, 10, 2
	DUTY_STEP 8, 1
	RELEASE_VOL 2
	DETUNE $05
	SND_CALL Snd61_Ch1_5C12
	SND_CALL Snd61_Ch1_5C63
	LOOP2_START
	VOICE $03, 4, 7, 5, 7
	DUTY_STEP 0, 0
	VIBRATO 1, 0, 2
	DETUNE $01
	PAN_LEFT 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 2
	NOTE C_, 2
	NOTE D#, 4
	ATTEN 0
	SND_CALL Snd61_Ch1_5D44
	ATTEN 2
	NOTE C_, 2
	NOTE F#, 4
	PAN_LEFT 2
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 4
	SND_CALL Snd61_Ch1_5D44
	NOTE G_, 2
	NOTE A_, 2
	PAN_LEFT 3
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	AUTOPAN 0
	ATTEN 0
	DETUNE $05
	OCTAVE 1
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	VOICE $03, 8, 6, 4, 7
	DETUNE $01
	VIBRATO_SEMI $10
	RELEASE_VOL 2
	ATTEN 4
	OCTAVE 4
	NOTE D#, 0
	ATTEN 1
	SND_JUMP_N 2, Snd61_Ch1_5CFF
	NOTE D_, 0
	NOTE C_, 0
	ATTEN 2
	NOTE D_, 6
Snd61_Ch1_5CFF:
	LOOP2_END 2
	NOTE E_, 0
	NOTE G_, 0
	ATTEN 0
	NOTE C_, 0
	LOOP2_START
	SND_CALL Snd61_Ch1_5D50
	NOTE F_, 2
	NOTE C_, 2
	PAN_RIGHT 3
	OCTAVE 5
	NOTE A_, 2
	PAN_BOTH 0
	OCTAVE 4
	NOTE F_, 2
	NOTE C_, 2
	PAN_LEFT 3
	NOTE F_, 2
	VOICE $03, 8, 6, 0, 0
	ATTEN 2
	DUTY_STEP 0, 0
	SND_CALL Snd61_Ch1_5C72
	SND_CALL Snd61_Ch1_5D50
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	PAN_RIGHT 3
	OCTAVE 5
	NOTE A_, 2
	PAN_BOTH 0
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	PAN_LEFT 3
	OCTAVE 4
	NOTE D_, 2
	VOICE $03, 8, 6, 0, 0
	ATTEN 2
	DUTY_STEP 0, 0
	SND_CALL Snd61_Ch1_5C80
	LOOP2_END 2
	TRANSPOSE_DOWN 0
	SND_LOOP
Snd61_Ch1_5D44:
	PAN_RIGHT 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F#, 2
	SND_RET
Snd61_Ch1_5D50:
	VOICE $03, 4, 6, 13, 5
	DUTY_STEP 0, 2
	DETUNE $02
	VIBRATO_OFF
	TRANSPOSE_DOWN $0C
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	PAN_RIGHT 3
	OCTAVE 5
	NOTE A_, 2
	DUTY_STEP 0, 2
	PAN_BOTH 0
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	PAN_LEFT 3
	OCTAVE 4
	NOTE D#, 2
	PAN_BOTH 0
	SND_RET
Snd61_Ch1_5D73:
	VOICE $05, 0, 8, 10, 7
	DUTY_STEP 8, 1
	VIBRATO 1, 3, 2
Snd61_Ch1_5D7C:
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE D_, 1
	RELEASE_VOL 4
	NOTE G_, 0
	SND_RET

Snd61_Ch3:
	VOICE $05, 2, 2, 6, 7
	DETUNE $01
	VIBRATO 2, 4, 4
	SND_CALL Snd61_Ch1_5D7C
	LEN_UNIT $03
	REST 8
	SND_SEGNO
	VOICE $03, 11, 2, 6, 7
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	LOOP2_START
	SND_CALL Snd61_Ch1_5C14
	LOOP2_END 10
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	LOOP2_END 4
	SND_LOOP

Snd61_Drm:
	LEN_UNIT $05
	OCTAVE 3
	DRUM $0A, 6
	DRUM 6, 0
	LEN_UNIT $03
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	SND_SEGNO
	SND_CALL Snd61_Drm_5DF3
	SND_CALL Snd61_Drm_5E11
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	LOOP_START
	SND_CALL Snd61_Drm_5DF3
	LOOP_END 7
	SND_CALL Snd61_Drm_5E11
	DRUM 7, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 9, 2
	LOOP_START
	SND_CALL Snd61_Drm_5E04
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	LOOP_END 3
	SND_CALL Snd61_Drm_5E04
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	SND_LOOP
Snd61_Drm_5DF3:
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 1, 2
	SND_RET
Snd61_Drm_5E04:
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	SND_RET
Snd61_Drm_5E11:
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	SND_RET

Snd42_Ch2:
	LEN_UNIT $10
	REST $0A

Snd52_Ch2:
	SND_SEGNO
	VOICE $06, 8, 6, 5, 4
	RELEASE_VOL 2
	DETUNE $03
	VOL_RAMP 4
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP_END 4
	DETUNE $00
	LOOP2_START
	SND_CALL Snd42_Ch2_5F12
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	ATTEN 2
	NOTE D#, 2
	ATTEN 1
	NOTE F#, 2
	NOTE F_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 3
	OCTAVE 4
	NOTE A#, 2
	SND_CALL Snd42_Ch2_5F12
	OCTAVE 5
	NOTE D#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 1
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 2
	NOTE F_, 2
	ATTEN 3
	NOTE D_, 2
	LOOP2_END 2
	VOICE $06, 4, 7, 13, 4
	DETUNE $FF
	SND_CALL Snd42_Ch1_5EC3
	DUTY 8
	SND_CALL Snd42_Ch1_5ECD
	NOTE F#, 2
	VOICE $06, 4, 7, 13, 4
	SND_CALL Snd42_Ch1_5ED6
	DUTY 8
	SND_CALL Snd42_Ch1_5EE0
	NOTE A#, 2
	VOICE $06, 4, 7, 13, 4
	SND_CALL Snd42_Ch1_5EE8
	DUTY 8
	SND_CALL Snd42_Ch1_5EF4
	NOTE C_, 2
	VOICE $06, 4, 7, 13, 4
	SND_CALL Snd42_Ch1_5EFD
	DUTY 8
	SND_CALL Snd42_Ch1_5F07
	NOTE G_, 2
	DETUNE $01
	LOOP2_START
	VOICE $06, 4, 7, 10, 7
	VIBRATO 2, 0, 2
	OCTAVE 3
	NOTE A_, 8
	NOTE G#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE G#, 4
	NOTE G_, 8
	NOTE F#, 4
	NOTE C_, 4
	NOTE C#, 4
	NOTE F#, 4
	NOTE F_, 8
	NOTE E_, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 3
	NOTE D#, 8
	VOICE $06, 8, 7, 0, 0
	ATTEN 2
	NOTE A_, 4
	ATTEN 1
	OCTAVE 4
	NOTE D#, 4
	ATTEN 0
	RELEASE $0F, 3
	NOTE A_, 2
	VIBRATO 1, 0, 1
	ATTEN 4
	RELEASE 7, $0A
	NOTE A_, 6
	LOOP2_END 2
	SND_LOOP
Snd42_Ch1_5EC3:
	OCTAVE 1
	NOTE E_, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE F_, 2
	SND_RET
Snd42_Ch1_5ECD:
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE A_, 2
	SND_RET
Snd42_Ch1_5ED6:
	OCTAVE 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE E_, 2
	SND_RET
Snd42_Ch1_5EE0:
	ATTEN 1
	OCTAVE 3
	NOTE E_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F#, 2
	SND_RET
Snd42_Ch1_5EE8:
	OCTAVE 1
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F#, 2
	SND_RET
Snd42_Ch1_5EF4:
	ATTEN 1
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE G#, 2
	OCTAVE 4
	SND_RET
Snd42_Ch1_5EFD:
	OCTAVE 1
	NOTE C#, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE E_, 2
	NOTE F_, 2
	SND_RET
Snd42_Ch1_5F07:
	ATTEN 1
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	SND_RET
Snd42_Ch2_5F12:
	VOICE $06, 4, 7, 10, 7
	VIBRATO 1, 2, 1
	ATTEN 2
	VOL_RAMP 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	RELEASE_VOL 2
	DUTY 0
	ATTEN 3
	SND_RET

Snd42_Ch1:
	LEN_UNIT $10
	REST $0A

Snd52_Ch1:
	SND_SEGNO
	VOICE $06, 0, 6, 10, 4
	RELEASE_VOL 2
	VIBRATO_OFF
	VOL_RAMP 4
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	LOOP_END 4
	LOOP2_START
	LOOP_START
	VOICE $06, 8, 7, 10, 7
	VIBRATO 3, 1, 3
	OCTAVE 2
	ATTEN 2
	NOTE E_, 8
	NOTE A_, 2
	ATTEN 1
	NOTE E_, 8
	NOTE A_, 2
	ATTEN 0
	NOTE E_, 8
	NOTE A_, 2
	RELEASE_VOL 2
	DUTY 0
	VIBRATO_SEMI 5
	ATTEN 3
	SND_JUMP_N 2, Snd42_Ch1_5F6A
	OCTAVE 5
	NOTE B_, 2
	OCTAVE 6
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE A#, 2
Snd42_Ch1_5F6A:
	LOOP_END 2
	OCTAVE 6
	NOTE D#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE D_, 2
	LOOP2_END 2
	SND_CALL Snd42_Ch1_5FD7
	SND_CALL Snd42_Ch1_5EC3
	SND_CALL Snd42_Ch1_5FE2
	SND_CALL Snd42_Ch1_5ECD
	NOTE F#, 1
	SND_CALL Snd42_Ch1_5FD7
	SND_CALL Snd42_Ch1_5ED6
	SND_CALL Snd42_Ch1_5FE2
	SND_CALL Snd42_Ch1_5EE0
	NOTE A#, 1
	SND_CALL Snd42_Ch1_5FD7
	SND_CALL Snd42_Ch1_5EE8
	SND_CALL Snd42_Ch1_5FE2
	SND_CALL Snd42_Ch1_5EF4
	NOTE C_, 1
	SND_CALL Snd42_Ch1_5FD7
	SND_CALL Snd42_Ch1_5EFD
	SND_CALL Snd42_Ch1_5FE2
	SND_CALL Snd42_Ch1_5F07
	NOTE G_, 1
	LOOP_START
	VOICE $06, 0, 7, 9, 7
	VIBRATO_SEMI 5
	OCTAVE 3
	NOTE C_, $0C
	OCTAVE 2
	NOTE B_, $0C
	NOTE A#, $0C
	NOTE A_, $0C
	NOTE G#, $0C
	NOTE G_, $0C
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 8
	VOICE $06, 8, 7, 0, 0
	VIBRATO 2, 0, 0
	ATTEN 2
	OCTAVE 3
	NOTE D#, 4
	ATTEN 1
	NOTE A_, 4
	ATTEN 0
	OCTAVE 4
	RELEASE $0F, 3
	NOTE D#, 2
	VIBRATO 3, 0, 1
	ATTEN 4
	RELEASE 7, $0A
	NOTE D#, 6
	LOOP_END 2
	SND_LOOP
Snd42_Ch1_5FD7:
	VOICE $06, 4, 4, 5, 4
	RELEASE_VOL 2
	VIBRATO_SEMI 5
	DETUNE $03
	SND_RET
Snd42_Ch1_5FE2:
	VOICE $06, 8, 5, 0, 0
	REST 1
	VIBRATO 3, 0, 0
	AUTOPAN 0
	SND_RET

Snd42_Ch3:
	LEN_UNIT $10
	REST $0A

Snd52_Ch3:
	SND_SEGNO
	VOICE $06, 2, 2, 7, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP_END 4
	VOICE $06, 2, 2, 7, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP_END 4
	NOTE C_, 2
	LOOP2_END 4
	SND_CALL Snd42_Ch3_608A
	SND_CALL Snd42_Ch1_5EC3
	SND_CALL Snd42_Ch3_6093
	SND_CALL Snd42_Ch1_5ECD
	NOTE F#, 2
	SND_CALL Snd42_Ch3_608A
	SND_CALL Snd42_Ch1_5ED6
	SND_CALL Snd42_Ch3_6093
	SND_CALL Snd42_Ch1_5EE0
	NOTE A#, 2
	SND_CALL Snd42_Ch3_608A
	SND_CALL Snd42_Ch1_5EE8
	SND_CALL Snd42_Ch3_6093
	SND_CALL Snd42_Ch1_5EF4
	NOTE C_, 2
	SND_CALL Snd42_Ch3_608A
	SND_CALL Snd42_Ch1_5EFD
	SND_CALL Snd42_Ch3_6093
	SND_CALL Snd42_Ch1_5F07
	NOTE G_, 2
	LOOP2_START
	VOICE $06, 2, 2, 0, 0
	OCTAVE 2
	LOOP_START
	NOTE A_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	TRANSPOSE_DOWN 1
	LOOP_END 2
	TRANSPOSE_DOWN 2
	LOOP_START
	NOTE A_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	TRANSPOSE_DOWN 3
	LOOP_END 2
	TRANSPOSE_DOWN 4
	LOOP_START
	NOTE A_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	TRANSPOSE_DOWN 5
	LOOP_END 2
	TRANSPOSE_DOWN 0
	LOOP_START
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 1
	RELEASE $0A, 3
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END 3
	LOOP2_END 2
	SND_LOOP
Snd42_Ch3_608A:
	VOICE $06, 2, 2, 5, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	SND_RET
Snd42_Ch3_6093:
	VOICE $06, 14, 4, 0, 0
	VIBRATO 2, 0, 2
	SND_RET

Snd42_Drm:
	LEN_UNIT $10
	REST $0A

Snd52_Drm:
	LEN_UNIT $06
	SND_SEGNO
	LOOP_START
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 2
	LOOP_END 4
	LEN_UNIT $06
	LOOP2_START
	LOOP_START
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 2
	LOOP_END 3
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	LOOP2_END 4
	LEN_UNIT $06
	LOOP_START
	DRUM 1, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM 3, 4
	LOOP_END 4
	DRUM 3, 4
	LEN_UNIT $06
	LOOP2_START
	LOOP_START
	DRUM 3, 4
	DRUM $0C, 4
	DRUM $0C, 4
	LOOP_END 7
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	LOOP2_END 2
	SND_LOOP

Snd62_Ch2:
	KEY_TRANSPOSE 0
	DETUNE $F9
	SND_CALL Snd62_Ch1_61A1
	SND_SEGNO
	KEY_TRANSPOSE 0
	LEN_UNIT $09
	DETUNE $01
	DUTY 8
	LOOP_START
	VOICE $09, 8, 8, 4, 7
	DETUNE $01
	VIBRATO 1, 5, 2
	OCTAVE 2
	NOTE C_, 8
	NOTE D_, 4
	NOTE D#, 4
	NOTE G#, 0
	OCTAVE 1
	NOTE C_, 0
	ATTEN 5
	RELEASE 6, $0D
	VIBRATO 1, 12, 6
	OCTAVE 3
	NOTE C#, 0
	VIBRATO 1, 5, 2
	RELEASE 4, 7
	ATTEN 0
	OCTAVE 2
	NOTE C_, 8
	NOTE D_, 4
	NOTE D#, 4
	NOTE G#, 0
	NOTE G_, 0
	ATTEN 5
	RELEASE 6, $0D
	VIBRATO 1, 12, 6
	NOTE F#, 0
	LOOP_END 2
	TRANSPOSE_UP 2
	LOOP_START
	VOICE $09, 4, 7, 2, 7
	VIBRATO 1, 3, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 8
	ATTEN 1
	NOTE D#, 8
	ATTEN 0
	NOTE D_, 8
	ATTEN 1
	NOTE F_, 8
	OCTAVE 1
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	DUTY 8
	ATTEN 0
	LEN_UNIT $01
	OCTAVE 2
	NOTE C_, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	LEN_UNIT $09
	NOTE G#, 8
	DUTY 4
	ATTEN 2
	OCTAVE 1
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	DUTY 8
	ATTEN 0
	LEN_UNIT $01
	OCTAVE 2
	NOTE C_, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	LEN_UNIT $09
	NOTE G#, 4
	NOTE G_, 4
	TRANSPOSE_UP 1
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE $09, 8, 7, 2, 7
	VIBRATO 1, 1, 8
	DETUNE $01
	OCTAVE 2
	ATTEN 2
	NOTE G_, 8
	ATTEN 1
	NOTE C_, 8
	ATTEN 0
	NOTE D#, 8
	ATTEN 1
	NOTE C_, 8
	OCTAVE 2
	ATTEN 2
	NOTE G_, 8
	ATTEN 1
	NOTE G#, 8
	ATTEN 0
	NOTE D#, 8
	ATTEN 1
	NOTE C_, 8
	LOOP_START
	VOICE $09, 4, 7, 0, 0
	DUTY_STEP 0, 0
	VIBRATO 2, 0, 3
	DUTY_STEP 0, 1
	OCTAVE 2
	ATTEN 3
	NOTE F#, 4
	ATTEN 2
	NOTE G_, 4
	ATTEN 1
	NOTE D#, 4
	NOTE C_, 4
	ATTEN 2
	VIBRATO 1, 1, 1
	VOICE $09, 0, 7, 10, 2
	RELEASE_VOL 2
	ATTEN 4
	OCTAVE 4
	NOTE F#, 4
	ATTEN 2
	NOTE G_, 4
	ATTEN 1
	NOTE D#, 4
	ATTEN 3
	NOTE C_, 4
	LOOP_END 2
	VOICE $0F, 8, 4, 12, 4
	RELEASE_VOL 2
	VIBRATO 1, 8, 2
	OCTAVE 3
	NOTE C#, 0
	SND_LOOP
	db $FF ; unreachable byte after an end
Snd62_Ch1_61A1:
	VOICE $09, 0, 7, 12, 2
	RELEASE_VOL 2
	ATTEN 4
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 6
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 6
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 6
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 6
	NOTE C_, 2
	SND_RET

Snd62_Ch1:
	KEY_TRANSPOSE 0
	DETUNE $05
	SND_CALL Snd62_Ch1_61A1
	SND_SEGNO
	KEY_TRANSPOSE 0
	LOOP_START
	VOICE $09, 0, 7, 0, 0
	VIBRATO 3, 3, 1
	DUTY_STEP 0, 1
	OCTAVE 2
	ATTEN 4
	NOTE C_, $0B
	NOTE D_, 4
	NOTE D#, 4
	NOTE G#, $0D
	DETUNE $FF
	ATTEN 2
	NOTE G_, 0
	ATTEN 5
	RELEASE 6, $0D
	DUTY 8
	NOTE G#, 0
	RELEASE 0, 0
	DETUNE $FD
	DUTY 0
	OCTAVE 2
	ATTEN 4
	NOTE C_, $0B
	NOTE D_, 4
	NOTE D#, 4
	NOTE G#, $0D
	DETUNE $FF
	ATTEN 2
	NOTE C_, 0
	ATTEN 5
	RELEASE 6, $0D
	DUTY 8
	NOTE D_, 0
	LOOP_END 2
	TRANSPOSE_UP 2
	LOOP_START
	VOICE $09, 0, 6, 2, 7
	VIBRATO_SEMI 5
	DETUNE $FF
	ATTEN 2
	OCTAVE 2
	NOTE G_, 8
	ATTEN 1
	NOTE A#, 8
	ATTEN 0
	NOTE A_, 8
	ATTEN 1
	OCTAVE 3
	NOTE C_, 8
	VIBRATO 3, 1, 1
	OCTAVE 1
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	DUTY 8
	OCTAVE 2
	ATTEN 3
	NOTE C_, 2
	LEN_UNIT $01
	NOTE C_, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	DETUNE $FE
	LEN_UNIT $09
	NOTE G#, 6
	DUTY 4
	ATTEN 2
	OCTAVE 1
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE C_, 2
	LEN_UNIT $01
	NOTE C_, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	LEN_UNIT $09
	NOTE G#, 4
	NOTE G_, 2
	TRANSPOSE_UP 1
	LOOP_END 2
	TRANSPOSE_UP 0
	LOOP_START
	VOICE $09, 4, 6, 13, 7
	VIBRATO_SEMI 1
	DUTY_STEP 0, 1
	RELEASE_VOL 1
	OCTAVE 4
	ATTEN 4
	VOL_RAMP 0
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	VOL_RAMP 8
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	LOOP_END 2
	LOOP_START
	VOICE $09, 0, 7, 8, 7
	DUTY_STEP 0, 1
	VIBRATO_SEMI 5
	DETUNE $FD
	ATTEN 4
	OCTAVE 2
	NOTE F#, 4
	NOTE G_, 4
	NOTE D#, 4
	ATTEN 1
	NOTE C_, 4
	VIBRATO 2, 0, 0
	CLEAR 2
	RELEASE_VOL 2
	OCTAVE 4
	ATTEN 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 4
	LOOP_END 2
	VOICE $0F, 8, 4, 12, 4
	RELEASE_VOL 2
	VIBRATO 3, 5, 1
	OCTAVE 2
	NOTE G#, 0
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd62_Ch3:
	KEY_TRANSPOSE 0
	VOICE $09, 4, 2, 12, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	DETUNE $FF
	OCTAVE 2
	NOTE C_, 2
	LOOP_START
	NOTE C_, 6
	NOTE C_, 2
	LOOP_END 4
	SND_SEGNO
	KEY_TRANSPOSE 0
	VOICE $09, 4, 2, 12, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	LOOP_START
	OCTAVE 2
	NOTE C_, 6
	NOTE C_, 2
	LOOP_END 32
	TRANSPOSE_UP 2
	VOICE $09, 4, 2, 12, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C_, 6
	NOTE C_, 2
	LOOP_END 8
	TRANSPOSE_UP 1
	LOOP2_END 2
	TRANSPOSE_UP 0
	VOICE $09, 4, 2, 0, 0
	RELEASE_VOL 4
	VIBRATO 1, 4, 4
	OCTAVE 2
	NOTE C_, 0
	NOTE C_, 0
	OCTAVE 2
	NOTE C_, 0
	NOTE C_, 0
	VOICE $09, 4, 2, 12, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	LOOP_START
	OCTAVE 2
	NOTE C_, 6
	NOTE C_, 2
	LOOP_END 8
	LEN_UNIT $0F
	RELEASE $0C, 4
	RELEASE_VOL 4
	VIBRATO 2, 0, 3
	NOTE C#, 0
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd62_Drm:
	LEN_UNIT $09
	DRUM $0C, 2
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	LOOP_END 4
	SND_SEGNO
	LEN_UNIT $09
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	LOOP_END 32
	LEN_UNIT $09
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	LOOP_END 16
	LEN_UNIT $09
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	LOOP_END 8
	LEN_UNIT $09
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	LOOP_END 8
	LEN_UNIT $0F
	DRUM $0C, 0
	SND_LOOP

Snd63_Ch2:
	TEMPO $00
	TRANSPOSE_UP 2
	SND_SEGNO
	LOOP2_START
	VOICE $08, 4, 8, 11, 4
	DUTY_STEP 4, 1
	VIBRATO_OFF
	OCTAVE 2
	SND_CALL Snd63_Ch2_63DC
	ATTEN 2
	LOOP_START
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 0
	LOOP_END 2
	DUTY 0
	OCTAVE 3
	SND_CALL Snd63_Ch2_63DC
	ATTEN 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 0
	NOTE C_, 2
	NOTE C#, 2
	SND_JUMP_N 2, Snd63_Ch2_633F
	NOTE D_, 2
	NOTE C#, 2
Snd63_Ch2_633F:
	LOOP2_END 2
	TRANSPOSE_UP 2
	LOOP2_START
	LOOP_START
	VOICE $08, 8, 7, 10, 5
	DUTY_STEP 4, 1
	VIBRATO 2, 0, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C#, 2
	LEN_UNIT $02
	NOTE E_, 1
	NOTE F_, $0F
	LEN_UNIT $08
	NOTE F_, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	LEN_UNIT $02
	NOTE F#, 1
	NOTE G#, 7
	LEN_UNIT $08
	NOTE F#, 2
	SND_JUMP_N 2, Snd63_Ch2_636B
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 4
Snd63_Ch2_636B:
	LOOP_END 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 4
	LOOP_START
	VIBRATO 1, 1, 3
	VOICE $01, 4, 7, 2, 7
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 3
	NOTE F_, $0B
	ATTEN 1
	NOTE C#, $0A
	ATTEN 0
	OCTAVE 2
	NOTE A_, $0B
	LEN_UNIT $08
	OCTAVE 2
	NOTE F#, 4
	ATTEN 3
	NOTE G#, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 1
	NOTE G#, 4
	ATTEN 0
	NOTE F#, 4
	ATTEN 1
	NOTE G#, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	LOOP_END 2
	LOOP2_END 2
	NOTE B_, 4
	TRANSPOSE_UP 2
	VOICE $08, 4, 7, 10, 4
	VIBRATO 2, 0, 2
	DETUNE $01
	OCTAVE 2
	NOTE F#, 4
	VOICE $01, 8, 7, 4, 7
	NOTE F#, $0B
	NOTE G#, $0A
	NOTE A_, $0B
	LEN_UNIT $08
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 4
	DETUNE $00
	LOOP2_START
	LOOP_START
	VOICE $08, 8, 7, 10, 7
	DUTY_STEP 0, 0
	VIBRATO_SEMI 5
	RELEASE_VOL 2
	OCTAVE 2
	ATTEN 4
	NOTE C_, 4
	ATTEN 3
	NOTE E_, 4
	ATTEN 2
	NOTE G_, 4
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	NOTE D_, 4
	ATTEN 1
	NOTE C_, 4
	ATTEN 2
	NOTE E_, 4
	ATTEN 3
	NOTE E_, 4
	DUTY 4
	TRANSPOSE_DOWN 1
	LOOP_END 2
	TRANSPOSE_UP 2
	LOOP2_END 2
	SND_LOOP
	db $FF ; unreachable byte after an end
Snd63_Ch2_63DC:
	ATTEN 4
	LOOP_START
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 3
	LOOP_END 2
	SND_RET

Snd63_Ch1:
	TRANSPOSE_UP 2
	SND_SEGNO
	LOOP2_START
	VOICE $08, 0, 7, 5, 7
	DETUNE $02
	REST 1
	ATTEN 4
	VIBRATO_OFF
	AUTOPAN 0
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	LOOP_END 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 1
	VOICE $08, 0, 7, 10, 4
	VIBRATO_SEMI 5
	RELEASE_VOL 2
	DETUNE $FF
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 2
	LOOP_END 2
	ATTEN 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	SND_JUMP_N 2, Snd63_Ch1_6424
	NOTE A_, 2
	NOTE A_, 2
Snd63_Ch1_6424:
	LOOP2_END 2
	TRANSPOSE_UP 2
	LOOP2_START
	LOOP_START
	VOICE $08, 8, 7, 2, 7
	VIBRATO 2, 0, 2
	DUTY_STEP 4, 1
	DETUNE $03
	ATTEN 5
	OCTAVE 1
	NOTE A_, 3
	OCTAVE 2
	NOTE C#, 2
	LEN_UNIT $02
	NOTE E_, 1
	NOTE F_, $0F
	LEN_UNIT $08
	NOTE F_, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	LEN_UNIT $02
	NOTE F#, 1
	NOTE G#, 7
	LEN_UNIT $08
	NOTE F#, 2
	SND_JUMP_N 2, Snd63_Ch1_6453
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 3
Snd63_Ch1_6453:
	LOOP_END 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 3
	LOOP_START
	VOICE $01, 0, 8, 10, 4
	DUTY_STEP 0, 0
	DETUNE $FC
	ATTEN 4
	OCTAVE 3
	NOTE F_, $0B
	ATTEN 3
	NOTE C#, $0A
	ATTEN 2
	OCTAVE 2
	NOTE A_, $0B
	LEN_UNIT $08
	DETUNE $00
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE C#, 2
	ATTEN 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, 2
	LOOP_END 2
	LOOP2_END 2
	NOTE C#, 2
	NOTE C_, 2
	TRANSPOSE_UP 2
	VOICE $08, 4, 7, 10, 4
	DETUNE $FE
	VIBRATO 2, 0, 1
	OCTAVE 2
	NOTE C#, 4
	ATTEN 4
	REST 1
	LEN_UNIT $01
	RELEASE 4, 7
	OCTAVE 2
	NOTE F#, $0B
	NOTE G#, $0A
	NOTE A_, $0B
	LEN_UNIT $08
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 3
	VOICE $08, 8, 5, 10, 4
	RELEASE_VOL 1
	AUTOPAN 0
	DETUNE $00
	LOOP_START
	ATTEN 4
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 3
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 1
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 4
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	NOTE E_, 2
	SND_JUMP_N 2, Snd63_Ch1_64EC
	ATTEN 2
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 2
Snd63_Ch1_64EC:
	LOOP_END 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd63_Ch3:
	TRANSPOSE_UP 2
	SND_SEGNO
	LOOP2_START
	VOICE $08, 4, 2, 10, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 4
	NOTE F#, 2
	LOOP_END 3
	NOTE F#, 2
	SND_JUMP_N 4, Snd63_Ch3_650E
	NOTE F#, 4
	NOTE C#, 2
Snd63_Ch3_650E:
	LOOP2_END 4
	NOTE C#, 2
	TRANSPOSE_UP 2
	VOICE $08, 4, 2, 10, 4
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	NOTE C#, 2
	LOOP_END 65
	TRANSPOSE_UP 2
	VOICE $08, 4, 2, 10, 4
	OCTAVE 2
	NOTE F#, 4
	RELEASE 2, 7
	LEN_UNIT $01
	NOTE F#, $0B
	NOTE G#, $0A
	NOTE A_, $0B
	LEN_UNIT $08
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 4
	VOICE $08, 4, 2, 10, 4
	RELEASE_VOL 4
	OCTAVE 2
	LOOP_START
	NOTE A_, 2
	NOTE E_, 2
	LOOP_END 8
	LOOP_START
	NOTE F#, 2
	NOTE C#, 2
	LOOP_END 8
	LOOP_START
	NOTE A_, 2
	NOTE E_, 2
	LOOP_END 8
	LOOP_START
	NOTE F#, 2
	NOTE C#, 2
	LOOP_END 6
	NOTE F_, 2
	NOTE F_, 4
	NOTE C#, 2
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd63_Drm:
	LEN_UNIT $08
	SND_SEGNO
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, $0C
	DRUM $0C, 2
	LOOP_END 7
	DRUM $0C, 2
	DRUM $0C, $0A
	LEN_UNIT $08
	REST 2
	DRUM $0C, 2
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, $0C
	DRUM $0C, 2
	LOOP_END 16
	LEN_UNIT $08
	DRUM $0C, 8
	DRUM $0C, 4
	DRUM $0C, 4
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 8
	LOOP_END 8
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd53_Ch2:
	SND_SEGNO
	VOICE $0A, 0, 7, 10, 3
	RELEASE_VOL 1
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	SND_CALL Snd53_Ch1_65E0
	LOOP_END 2
	ATTEN 0
	RELEASE $0A, 3
	AUTOPAN_BOTH 4
	LOOP_START
	NOTE A_, 2
	LOOP_END 32
	LOOP2_START
	LOOP_START
	NOTE G#, 2
	LOOP_END 20
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	TRANSPOSE_DOWN 0
	LOOP_START
	VOICE $0A, 8, 7, 10, 7
	DUTY_STEP 4, 1
	VIBRATO 2, 0, 6
	OCTAVE 3
	NOTE C#, 4
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 3
	ATTEN 0
	NOTE C_, 4
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 3
	ATTEN 0
	NOTE C#, 4
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 3
	ATTEN 0
	NOTE E_, 4
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 3
	LOOP_END 2
	ATTEN 0
	VOICE $0A, 8, 1, 0, 0
	VIBRATO 1, 0, 0
	LOOP_START
	TRANSPOSE_UP $0C
	OCTAVE 6
	NOTE C_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE C_, 2
	LOOP_END 2
	VOICE $0A, 0, 6, 2, 7
	VIBRATO 1, 3, 4
	OCTAVE 1
	NOTE G#, $0C
	NOTE A_, 0
	TRANSPOSE_DOWN 0
	SND_LOOP
Snd53_Ch1_65E0:
	ATTEN 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	ATTEN 3
	VOL_RAMP 0
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	SND_RET

Snd53_Ch1:
	SND_SEGNO
	VOICE $05, 0, 7, 10, 3
	REST 1
	DETUNE $01
	AUTOPAN 0
	LEN_UNIT $0A
	RELEASE_VOL 1
	DUTY_STEP 8, 1
	VIBRATO_SEMI 1
	ATTEN 5
	OCTAVE 4
	LOOP_START
	NOTE A_, 4
	LOOP_END 7
	LEN_UNIT $05
	NOTE A_, 7
	LEN_UNIT $0A
	DETUNE $00
	VIBRATO_SEMI 5
	OCTAVE 3
	SND_CALL Snd53_Ch1_65E0
	VOICE $0A, 8, 7, 0, 0
	DETUNE $06
	PAN_LEFT 0
	VIBRATO 3, 0, 2
	OCTAVE 1
	NOTE A#, $0A
	NOTE A#, 0
	NOTE E_, $0C
	OCTAVE 2
	NOTE D#, $0C
	NOTE D_, 8
	OCTAVE 1
	NOTE F#, 6
	LOOP_START
	VOICE $0A, 4, 6, 0, 0
	DETUNE $FF
	VIBRATO_SEMI 5
	OCTAVE 2
	NOTE C_, 0
	DUTY 0
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 4
	RELEASE 3, 7
	NOTE D_, 0
	TRANSPOSE_DOWN 1
	LOOP_END 2
	TRANSPOSE_DOWN 0
	LOOP_START
	VOICE $0A, 0, 6, 10, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI 5
	OCTAVE 2
	NOTE C#, 4
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 3
	ATTEN 0
	NOTE D_, 4
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 3
	ATTEN 0
	NOTE C#, 4
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 3
	ATTEN 0
	NOTE G#, 4
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 3
	LOOP_END 2
	VOICE $0A, 4, 5, 2, 7
	DETUNE $02
	VIBRATO 2, 0, 8
	TRANSPOSE_DOWN 5
	SND_CALL Snd53_Ch1_6672
	TRANSPOSE_DOWN 0
	OCTAVE 1
	NOTE D#, $0C
	NOTE E_, 0
	SND_LOOP
Snd53_Ch1_6672:
	LOOP_START
	OCTAVE 1
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	LOOP_END 2
	SND_RET

Snd53_Ch3:
	SND_SEGNO
	VOICE $0A, 2, 2, 0, 0
	VIBRATO 1, 0, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 0
	NOTE A_, 0
	LOOP_END 2
	WAVE $0E
	OCTAVE 1
	NOTE A#, 8
	VIBRATO 1, 4, 4
	NOTE A#, 0
	NOTE E_, $0C
	OCTAVE 2
	NOTE D#, $0C
	NOTE D_, 8
	OCTAVE 1
	NOTE F#, 8
	LOOP_START
	OCTAVE 1
	NOTE F_, 0
	OCTAVE 2
	NOTE D#, 4
	NOTE D_, 0
	NOTE D_, 4
	TRANSPOSE_DOWN 1
	LOOP_END 2
	TRANSPOSE_DOWN 0
	LOOP_START
	VOICE $0A, 4, 2, 2, 7
	OCTAVE 2
	NOTE C#, 8
	NOTE C_, 8
	NOTE C#, 8
	NOTE D_, 8
	LOOP_END 2
	VOICE $0A, 14, 2, 0, 0
	SND_CALL Snd53_Ch1_6672
	WAVE 4
	NOTE G#, $0C
	NOTE A_, 0
	SND_LOOP

Snd53_Drm:
	SND_SEGNO
	LEN_UNIT $0A
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 8
	LOOP_END 8
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 8
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 8
	DRUM $0C, 4
	DRUM $0C, 4
	LOOP_END 2
	LOOP_START
	REST 4
	DRUM $0C, 4
	LOOP_END 8
	LOOP_START
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 4
	LOOP_END 5
	DRUM $0C, 6
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM $0C, 4
	SND_LOOP

Snd54_Ch2:
	TEMPO $1A
	VOICE $06, 4, 10, 5, 8
	VIBRATO 2, 0, 4
	SND_CALL Snd54_Ch1_673C
	VOICE $06, 0, 8, 7, 1
	DETUNE $FD
	TRANSPOSE_DOWN $0C
	DETUNE $F9
	LOOP_START
	SND_CALL Snd54_Ch2_685E
	LOOP_END 4
	LOOP_START
	VOL_RAMP $0F
	SND_CALL Snd54_Ch2_685E
	LOOP_END 3
	ATTEN 0
	DUTY 0
	DETUNE $00
	TRANSPOSE_UP $0C
	SND_CALL Snd54_Ch1_686B
	SND_SEGNO
	TRANSPOSE_DOWN 0
	LOOP2_START
	VOICE $06, 8, 9, 9, 2
	DETUNE $00
	SND_CALL Snd54_Ch1_675C
	NOTE F_, 1
	TRANSPOSE_UP 7
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP2_START
	SND_CALL Snd54_Ch1_6789
	TRANSPOSE_DOWN 2
	SND_CALL Snd54_Ch1_6789
	TRANSPOSE_UP 0
	LOOP2_END 2
	SND_LOOP
Snd54_Ch1_673C:
	VIBRATO 2, 0, 4
	RELEASE_VOL 6
	OCTAVE 4
	NOTE A#, 2
	NOTE A#, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE E_, 2
	NOTE E_, 1
	RELEASE $0A, 7
	NOTE C#, 3
	VOLUME $02
	VIBRATO 1, 7, 4
	RELEASE 8, $0A
	NOTE C#, 9
	TEMPO $00
	RELEASE 0, 0
	VIBRATO 1, 2, 2
	NOTE C#, 4
	SND_RET
Snd54_Ch1_675C:
	VIBRATO_SEMI 2
	DUTY_STEP 0, 1
	OCTAVE 3
	LOOP_START
	ATTEN 0
	NOTE D_, 1
	NOTE F_, 1
	RELEASE_VOL 2
	ATTEN 5
	NOTE F#, 1
	NOTE G_, 1
	NOTE D_, 1
	VOL_RAMP 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	RELEASE_VOL 0
	SND_JUMP_N 2, Snd54_Ch1_677E
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
Snd54_Ch1_677E:
	LOOP_END 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	SND_RET
Snd54_Ch1_6789:
	VOICE $06, 0, 8, 10, 7
	DETUNE $00
	VIBRATO_SEMI 4
	DUTY_STEP 8, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A#, 1
	ATTEN 5
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE E_, 1
	DUTY 8
	VIBRATO 2, 0, 1
	NOTE F#, 1
	NOTE G_, 1
	VOL_RAMP 0
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_RET

Snd54_Ch1:
	TRANSPOSE_DOWN 4
	VOICE $06, 4, 8, 5, 8
	VIBRATO 2, 0, 4
	SND_CALL Snd54_Ch1_673C
	VOICE $06, 4, 7, 7, 1
	RELEASE_VOL 1
	AUTOPAN 0
	VIBRATO_SEMI 2
	ATTEN 3
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	LOOP_END 5
	NOTE F#, 1
	LOOP2_END 3
	LOOP_START
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	LOOP_END 2
	NOTE F#, 1
	NOTE F#, 1
	PAN_BOTH 0
	TRANSPOSE_UP 7
	DUTY 0
	DETUNE $00
	VIBRATO_OFF
	ATTEN 0
	SND_CALL Snd54_Ch1_686B
	SND_SEGNO
	VOICE $06, 8, 5, 0, 0
	TRANSPOSE_UP 0
	DETUNE $02
	AUTOPAN 0
	SND_CALL Snd54_Ch1_675C
	REST 2
	TRANSPOSE_UP 7
	SND_CALL Snd54_Ch1_675C
	LOOP2_START
	TRANSPOSE_DOWN 5
	LOOP_START
	SND_CALL Snd54_Ch1_6789
	TRANSPOSE_DOWN 7
	LOOP_END 2
	LOOP2_END 2
	SND_LOOP

Snd54_Ch3:
	VOICE $06, 4, 2, 2, 7
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE A#, 3
	NOTE G_, 3
	RELEASE 0, 0
	NOTE E_, 4
	ATTEN 2
	NOTE E_, 8
	VOICE $01, 10, 2, 0, 0
	OCTAVE 3
	NOTE E_, 4
	NOTE D#, 3
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_START
	SND_CALL Snd54_Ch3_6858
	LOOP_END 7
	SND_CALL Snd54_Ch1_686B
	SND_SEGNO
	LOOP_START
	SND_CALL Snd54_Ch3_6858
	LOOP_END 4
	TRANSPOSE_UP 7
	LOOP_START
	SND_CALL Snd54_Ch3_6858
	LOOP_END 3
	SND_CALL Snd54_Ch1_686B
	TRANSPOSE_UP 0
	LOOP2_START
	LOOP_START
	SND_CALL Snd54_Ch3_6876
	TRANSPOSE_DOWN 3
	LOOP_END 2
	TRANSPOSE_UP 0
	LOOP2_END 2
	SND_LOOP
Snd54_Ch3_6858:
	VOICE $06, 4, 2, 5, 2
	RELEASE_VOL 4
Snd54_Ch2_685E:
	VIBRATO_SEMI 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd54_Ch1_686B:
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_RET
Snd54_Ch3_6876:
	RELEASE $0C, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	RELEASE 0, 0
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	SND_RET

Snd54_Drm:
	LEN_UNIT $06
	DRUM 6, 2
	DRUM 9, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 6, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 6, 2
	DRUM 9, 1
	DRUM 9, 1
	SND_CALL Snd54_Drm_68DF
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 6, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_SEGNO
	SND_CALL Snd54_Drm_68DF
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 9, 1
	LOOP_END 7
	LOOP_START
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0C, 1
	SND_JUMP_N 4, Snd54_Drm_68D4
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 5, 1
Snd54_Drm_68D4:
	LOOP_END 4
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP
Snd54_Drm_68DF:
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0C, 1
	LOOP_END 3
	SND_RET

Snd55_Ch2:
	TRANSPOSE_UP 4
	TEMPO $08
	VIBRATO_SEMI 2
	SND_CALL Snd55_Ch1_6A2C
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd55_Ch2_69A9
	SND_CALL Snd55_Ch2_6A4D
	SND_JUMP_N 2, Snd55_Ch2_690B
	SND_CALL Snd55_Ch2_69CC
Snd55_Ch2_690B:
	LOOP2_END 2
	RELEASE $0A, 7
	DUTY 0
	OCTAVE 3
	NOTE A_, 2
	VIBRATO 1, 3, 6
	ATTEN 7
	RELEASE $0A, $0B
	NOTE A_, 7
	VOICE $06, 8, 8, 14, 5
	DUTY_STEP 0, 1
	VIBRATO_SEMI $0E
	ATTEN 4
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 0
	LOOP_END 2
	LOOP2_START
	SND_CALL Snd55_Ch2_69A9
	SND_JUMP_N 2, Snd55_Ch2_693C
	SND_CALL Snd55_Ch2_6A4D
	SND_CALL Snd55_Ch2_69CC
Snd55_Ch2_693C:
	LOOP2_END 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	VOICE $06, 4, 9, 12, 7
	ATTEN 3
	VOL_RAMP 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	VOL_RAMP 9
	NOTE F_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	LOOP2_START
	SND_CALL Snd55_Ch2_69EF
	SND_CALL Snd55_Ch2_6A0D
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 2
	LOOP_START
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	PAN_LEFT 5
	LOOP_END 2
	SND_CALL Snd55_Ch2_69EF
	SND_JUMP_N 2, Snd55_Ch2_698D
	SND_CALL Snd55_Ch2_6A0D
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	LOOP_START
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G#, 2
	PAN_RIGHT 5
	LOOP_END 2
Snd55_Ch2_698D:
	LOOP2_END 2
	VOICE $06, 0, 9, 4, 7
	VIBRATO_OFF
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	LOOP_END 2
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	SND_LOOP
Snd55_Ch2_69A9:
	VOICE $01, 8, 8, 14, 4
	DUTY_STEP 0, 0
	VIBRATO 1, 8, 4
Snd55_Ch1_69B2:
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 8
	LEN_UNIT $06
	NOTE G_, 4
	NOTE F#, 2
	NOTE C#, 3
	NOTE C_, 3
	NOTE F_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	VIBRATO_OFF
	SND_RET
Snd55_Ch2_69CC:
	RELEASE $0F, 7
	DUTY 0
	OCTAVE 3
	NOTE C#, 2
	ATTEN 7
	RELEASE $0A, $0B
	VIBRATO 1, 3, 8
	NOTE C#, 7
	VOICE $06, 8, 8, 14, 5
	DUTY_STEP 0, 1
	VIBRATO_SEMI $0E
	LOOP_START
	ATTEN 3
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	LOOP_END 2
	SND_RET
Snd55_Ch2_69EF:
	VOICE $03, 8, 9, 8, 3
	VIBRATO_SEMI 2
	RELEASE_VOL 2
	OCTAVE 2
	NOTE G_, 2
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	ATTEN 2
	NOTE D_, 2
	SND_RET
Snd55_Ch2_6A0D:
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	VOICE $03, 0, 9, 6, 7
	VIBRATO_OFF
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	RELEASE_VOL 3
	SND_RET
Snd55_Ch1_6A2C:
	VOICE $0A, 0, 8, 13, 7
	DUTY_STEP 8, 2
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	PAN_LEFT 6
	NOTE F_, 1
	PAN_BOTH 0
	LOOP_END 2
	NOTE F_, 1
	NOTE F_, 1
	LOOP2_END 2
	DUTY_STEP 0, 0
	PAN_LEFT 7
	NOTE F_, 1
	REST 2
	VOICE $06, 4, 7, 15, 7
	REST 3
	SND_RET
Snd55_Ch2_6A4D:
	VOICE $06, 8, 8, 8, 7
	RELEASE_VOL 3
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET

Snd55_Ch1:
	TRANSPOSE_DOWN 7
	VIBRATO_SEMI $0F
	SND_CALL Snd55_Ch1_6A2C
	TRANSPOSE_UP 4
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd55_Ch1_6B18
	SND_CALL Snd55_Ch1_69B2
	SND_CALL Snd55_Ch1_6B88
	SND_JUMP_N 2, Snd55_Ch1_6A73
	SND_CALL Snd55_Ch1_6B26
Snd55_Ch1_6A73:
	LOOP2_END 2
	RELEASE $0F, 7
	DUTY 0
	OCTAVE 3
	NOTE C#, 2
	ATTEN 5
	RELEASE $0A, $0B
	NOTE C#, 7
	VOICE $01, 8, 7, 14, 5
	DUTY_STEP 0, 1
	VIBRATO_SEMI $0E
	DETUNE $FD
	PAN_RIGHT 4
	NOTE D_, 6
	NOTE D#, 7
	NOTE D_, 7
	NOTE F_, 7
	NOTE D_, 7
	NOTE G_, 7
	ATTEN 2
	OCTAVE 3
	NOTE D_, 7
	NOTE D#, 7
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 1
	DETUNE $00
	SND_CALL Snd55_Ch1_6B18
	SND_CALL Snd55_Ch1_69B2
	SND_CALL Snd55_Ch1_6B88
	SND_CALL Snd55_Ch1_6B26
	SND_CALL Snd55_Ch1_6B18
	SND_CALL Snd55_Ch1_69B2
	VIBRATO 1, 3, 5
	TRANSPOSE_UP 4
	VOICE $06, 4, 7, 12, 7
	ATTEN 3
	VOL_RAMP 2
	OCTAVE 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	VOL_RAMP $0B
	NOTE D#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	LOOP2_START
	SND_CALL Snd55_Ch1_6B53
	SND_CALL Snd55_Ch1_6B76
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 1
	PAN_LEFT 4
	NOTE A#, 1
	NOTE F_, 1
	SND_CALL Snd55_Ch1_6B53
	SND_JUMP_N 2, Snd55_Ch1_6AFD
	SND_CALL Snd55_Ch1_6B76
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 4
	LOOP_END 2
Snd55_Ch1_6AFD:
	LOOP2_END 2
	VOICE $01, 0, 7, 4, 7
	LOOP_START
	OCTAVE 3
	NOTE A_, 6
	NOTE D#, 6
	OCTAVE 2
	NOTE A#, 6
	LOOP_END 2
	DETUNE $FD
	PAN_RIGHT 4
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE D#, 8
	NOTE D_, 8
	OCTAVE 1
	NOTE G#, 4
	SND_LOOP
Snd55_Ch1_6B18:
	VOICE $01, 8, 5, 14, 5
	TRANSPOSE_DOWN 1
	DETUNE $01
	DUTY_STEP 0, 0
	VIBRATO 7, 0, 0
	SND_RET
Snd55_Ch1_6B26:
	RELEASE $0E, 7
	DUTY 0
	DETUNE $00
	OCTAVE 2
	NOTE A_, 2
	ATTEN 6
	RELEASE $0A, $0B
	VIBRATO 2, 2, 3
	NOTE A_, 7
	VOICE $01, 8, 7, 14, 5
	DUTY_STEP 0, 1
	VIBRATO_SEMI $0E
	DETUNE $FD
	PAN_LEFT 4
	OCTAVE 2
	NOTE G_, 6
	NOTE G#, 7
	NOTE G_, 7
	NOTE A#, 7
	NOTE G_, 7
	OCTAVE 3
	NOTE C_, 7
	ATTEN 2
	OCTAVE 2
	NOTE G_, 7
	NOTE G#, 7
	NOTE G_, 8
	NOTE A#, 8
	NOTE G_, 1
	DETUNE $00
	SND_RET
Snd55_Ch1_6B53:
	VOICE $06, 8, 4, 15, 1
	TRANSPOSE_UP $0C
	RELEASE_VOL 1
	DUTY_STEP 0, 1
	TRANSPOSE_UP $0F
	ATTEN 2
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE E_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 0
	NOTE B_, 1
	NOTE D#, 1
	NOTE F#, 1
	TRANSPOSE_UP 4
	SND_RET
Snd55_Ch1_6B76:
	NOTE A#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE B_, 1
	VOICE $06, 0, 7, 6, 7
	RELEASE_VOL 3
	VIBRATO_OFF
	DUTY_STEP 8, 1
	SND_RET
Snd55_Ch1_6B88:
	VIBRATO 1, 3, 5
	TRANSPOSE_UP 4
	VOICE $06, 8, 7, 8, 7
	RELEASE_VOL 3
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET

Snd55_Ch3:
	TRANSPOSE_UP 4
	VOICE $0A, 6, 2, 12, 7
	VIBRATO_SEMI 2
	OCTAVE 2
	LOOP_START
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	LOOP_END 2
	REST 3
	LEN_UNIT $06
	REST 3
	SND_SEGNO
	VOICE $06, 4, 2, 6, 1
	VIBRATO_SEMI 2
	LOOP2_START
	SND_CALL Snd55_Ch3_6C27
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	SND_CALL Snd55_Ch3_6C27
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE F#, 1
	LOOP2_END 3
	SND_CALL Snd55_Ch3_6C27
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	VOICE $06, 4, 2, 6, 1
	VIBRATO_SEMI 2
	LOOP2_START
	SND_CALL Snd55_Ch3_6C27
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE C_HI, 1
	SND_JUMP_N 2, Snd55_Ch3_6C0D
	SND_CALL Snd55_Ch3_6C27
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE C_HI, 1
Snd55_Ch3_6C0D:
	LOOP2_END 2
	LOOP_START
	NOTE G_, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	LOOP_END 3
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	SND_LOOP
Snd55_Ch3_6C27:
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	SND_RET

Snd55_Drm:
	LEN_UNIT $0A
	LOOP_START
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 1
	DRUM 6, 1
	LOOP_END 2
	REST 3
	LEN_UNIT $06
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 1
	SND_SEGNO
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 15
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 15
	LOOP_START
	DRUM 9, 1
	LOOP_END 6
	LOOP2_START
	LOOP_START
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM $0A, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 2, 1
	LOOP2_END 3
	LOOP_START
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	LOOP_START
	DRUM 5, 1
	LOOP_END 7
	LOOP_START
	DRUM 9, 1
	LOOP_END 5
	SND_LOOP

Snd56_Ch2:
	TEMPO $08
	VOICE $10, 4, 3, 0, 0
	DETUNE $01
	VIBRATO 3, 4, 1
	OCTAVE 1
	NOTE A#, 6
	RELEASE 4, $0F
	ATTEN 1
	OCTAVE 2
	NOTE F_, $0A
	VOICE $01, 8, 5, 0, 0
	VOL_RAMP 0
	NOTE A#, $0B
	OCTAVE 3
	NOTE C_, $0A
	NOTE C#, $0B
	LEN_UNIT $10
	VOL_RAMP 8
	NOTE F#, 8
	VIBRATO_OFF
	NOTE F_, 6
	VIBRATO 3, 4, 1
	NOTE F_, 0
	VOICE $10, 4, 6, 2, 7
	VIBRATO 3, 3, 3
	NOTE A#, 6
	VIBRATO 4, 0, 4
	ATTEN 1
	NOTE A_, 8
	DETUNE $00
	SND_CALL Snd56_Ch1_6E1D
	OCTAVE 3
	SND_CALL Snd56_Ch2_6E13
	OCTAVE 4
	SND_CALL Snd56_Ch2_6E13
	REST 8
	OCTAVE 3
	SND_CALL Snd56_Ch2_6E13
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	LOOP_START
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	ATTEN 5
	LOOP_END 2
	REST 4
	VOICE $04, 0, 4, 8, 4
	OCTAVE 2
	NOTE E_, 6
	VOL_RAMP 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G#, 6
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0B, 3
	LEN_UNIT $06
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	LEN_UNIT $04
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	VOICE $06, 4, 8, 5, 5
	VIBRATO 1, 5, 1
	DUTY_STEP 0, 1
	DETUNE $01
	NOTE F_, 8
	RELEASE 8, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE F#, 4
	NOTE C#, 4
	RELEASE 5, 5
	NOTE F_, 8
	NOTE G_, 8
	RELEASE 8, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE A#, 4
	RELEASE 5, 5
	OCTAVE 3
	NOTE C_, $0C
	VOICE $04, 0, 7, 3, 7
	VIBRATO 2, 0, 2
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	VIBRATO_OFF
	RELEASE $0C, 4
	LEN_UNIT $06
	NOTE G#, 4
	ATTEN 3
	VIBRATO 1, 5, 1
	RELEASE 8, $0C
	NOTE G#, $0C
	RELEASE $0A, 7
	ATTEN 1
	NOTE G_, 2
	VOICE $03, 8, 3, 0, 0
	VIBRATO_OFF
	OCTAVE 3
	NOTE F_, 1
	VOL_RAMP 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	LEN_UNIT $04
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	VOL_RAMP $0B
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	LEN_UNIT $03
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	VOICE $04, 4, 7, 10, 3
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	RELEASE 2, 7
	VOICE $06, 0, 4, 0, 0
	VIBRATO 3, 0, 3
	DETUNE $04
	DUTY_STEP 0, 0
	VOL_RAMP 1
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 8
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE E_, 0
	ATTEN 1
	RELEASE 8, $0F
	NOTE D#, $0C
	DETUNE $00
	VOICE $06, 8, 8, 10, 3
	VIBRATO_OFF
	NOTE A_, 2
	ATTEN 6
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	LEN_UNIT $04
	RELEASE 0, 0
	VOL_RAMP 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	VOICE $04, 8, 7, 2, 7
	OCTAVE 2
	NOTE A#, 5
	LEN_UNIT $01
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	LEN_UNIT $04
	NOTE A#, 5
	ATTEN 5
	NOTE A#, 6
	ATTEN 0
	DUTY 8
	VIBRATO 3, 2, 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, $0C
	VOICE $06, 4, 7, 1, 7
	VIBRATO 1, 6, 2
	OCTAVE 3
	NOTE F_, 8
	NOTE G_, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, $0C
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 8
	VIBRATO_OFF
	ATTEN 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	ATTEN 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	VOICE $04, 0, 8, 4, 4
	DUTY_STEP 4, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE B_, $0C
	NOTE G_, 6
	NOTE E_, 6
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN_UNIT $06
	NOTE B_, 0
	VOICE $0C, 4, 8, 0, 0
	DETUNE $02
	VIBRATO 1, 6, 2
	OCTAVE 1
	ATTEN 2
	NOTE E_, 5
	NOTE F#, 2
	NOTE G_, 1
	ATTEN 0
	DETUNE $00
	NOTE G_, 0
	OCTAVE 2
	NOTE C#, 0
	SND_END
Snd56_Ch2_6E13:
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	ATTEN 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	ATTEN 0
	SND_RET
Snd56_Ch1_6E1D:
	VOICE $06, 0, 8, 11, 3
	VIBRATO 2, 0, 1
	DUTY_STEP 4, 1
	SND_RET

Snd56_Ch1:
	VOICE $10, 4, 2, 0, 0
	VIBRATO 4, 2, 1
	OCTAVE 1
	NOTE A#, 0
	NOTE A#, 2
	VOICE $01, 8, 4, 0, 0
	OCTAVE 2
	NOTE A#, $0B
	OCTAVE 3
	NOTE C_, $0A
	NOTE C#, $0B
	LEN_UNIT $10
	NOTE F#, 2
	NOTE C#, 2
	VIBRATO 4, 0, 1
	NOTE C#, $0F
	OCTAVE 2
	NOTE F#, 4
	NOTE F_, 5
	VOICE $10, 0, 5, 2, 7
	VIBRATO_SEMI 5
	NOTE F_, 6
	ATTEN 1
	NOTE E_, 8
	SND_CALL Snd56_Ch1_6E1D
	OCTAVE 3
	RELEASE $0C, 2
	LOOP_START
	SND_CALL Snd56_Ch1_6F9B
	OCTAVE 4
	LOOP_END 2
	SND_CALL Snd56_Ch1_6FB2
	OCTAVE 3
	SND_CALL Snd56_Ch1_6F9B
	DUTY 0
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	LOOP_END 2
	SND_CALL Snd56_Ch1_6FB2
	VOICE $04, 0, 3, 8, 4
	DETUNE $01
	OCTAVE 1
	VOL_RAMP 1
	LOOP_START
	NOTE E_, 6
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	DETUNE $00
	LOOP_END 2
	RELEASE $0B, 3
	LEN_UNIT $06
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	LEN_UNIT $04
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	VOICE $04, 4, 7, 5, 5
	VIBRATO 3, 2, 1
	DUTY_STEP 0, 0
	RELEASE_VOL 4
	NOTE C#, $0C
	RELEASE 8, 4
	OCTAVE 2
	NOTE A#, 6
	NOTE F_, 6
	OCTAVE 3
	NOTE C#, 6
	OCTAVE 2
	NOTE A_, 6
	RELEASE 5, 5
	OCTAVE 3
	NOTE C#, $0C
	NOTE D_, $0C
	RELEASE 8, 4
	OCTAVE 2
	NOTE A#, 6
	NOTE G_, 6
	DUTY 0
	VIBRATO 2, 0, 2
	VOL_RAMP 3
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	VIBRATO_OFF
	RELEASE $0C, 4
	LEN_UNIT $06
	NOTE B_, 4
	ATTEN 3
	VIBRATO 3, 1, 1
	RELEASE 8, $0C
	NOTE B_, $0C
	RELEASE $0A, 7
	ATTEN 1
	OCTAVE 4
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 2
	VOICE $04, 4, 7, 10, 3
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN_UNIT $06
	RELEASE 0, 0
	OCTAVE 3
	ATTEN 3
	NOTE D#, 0
	ATTEN 1
	OCTAVE 2
	NOTE B_, 0
	RELEASE 8, $0F
	NOTE B_, 0
	VOICE $06, 4, 8, 10, 3
	DUTY_STEP 4, 1
	ATTEN 3
	VIBRATO 2, 0, 1
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	LOOP_END 2
	VOICE $04, 8, 5, 2, 7
	OCTAVE 2
	NOTE E_, 5
	LEN_UNIT $01
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $04
	NOTE E_, 5
	ATTEN 4
	NOTE E_, 6
	VOLUME $07
	OCTAVE 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	DUTY 0
	RELEASE $0A, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	LEN_UNIT $06
	OCTAVE 4
	LOOP_START
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	ATTEN 0
	LOOP_END 2
	LEN_UNIT $04
	RELEASE $0A, 7
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	LEN_UNIT $06
	RELEASE $0A, 7
	NOTE G#, 4
	RELEASE $0A, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 4
	ATTEN 0
	LEN_UNIT $04
	DUTY 8
	VIBRATO 3, 4, 1
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE $0A, 7
	OCTAVE 4
	NOTE C_, 6
	VOICE $06, 0, 8, 4, 4
	DUTY_STEP 4, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE G_, 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	LEN_UNIT $04
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	LEN_UNIT $06
	NOTE G_, 0
	VOICE $0C, 4, 8, 0, 0
	VIBRATO 3, 3, 1
	OCTAVE 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 8
	OCTAVE 2
	NOTE B_, 8
	NOTE A#, 0
	SND_END
Snd56_Ch1_6F9B:
	DUTY 0
	VIBRATO 2, 0, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	DUTY 8
	DETUNE $01
	ATTEN 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	ATTEN 0
	DETUNE $00
	SND_RET
Snd56_Ch1_6FB2:
	DUTY 8
	ATTEN 2
	DETUNE $01
	OCTAVE 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	ATTEN 0
	DETUNE $00
	SND_RET

Snd56_Ch3:
	VOICE $10, 3, 2, 0, 0
	DETUNE $FD
	OCTAVE 1
	NOTE A#, 0
	VIBRATO 1, 4, 4
	NOTE A#, $0C
	DETUNE $FF
	NOTE F#, 4
	NOTE F_, 6
	OCTAVE 2
	NOTE F#, 4
	NOTE F_, 6
	NOTE A#, 6
	VIBRATO 4, 0, 4
	NOTE A_, 8
	VOICE $06, 4, 2, 6, 2
	VIBRATO_SEMI 1
	RELEASE_VOL 4
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP2_END 2
	LEN_UNIT $04
	LOOP_START
	NOTE E_, 6
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LOOP_END 2
	LEN_UNIT $06
	NOTE E_, 2
	NOTE E_, 2
	LEN_UNIT $04
	NOTE E_, 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	VOICE $04, 8, 2, 8, 2
	RELEASE_VOL 4
	LOOP_START
	OCTAVE 1
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	LOOP_END 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	LOOP_START
	NOTE G_, 6
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP_END 2
	OCTAVE 2
	LOOP_START
	NOTE C_, 6
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 2
	OCTAVE 1
	LOOP_START
	NOTE G#, 6
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	LOOP_END 2
	OCTAVE 2
	LOOP_START
	NOTE C_, 6
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 2
	OCTAVE 1
	LOOP_START
	NOTE G#, 2
	LOOP_END 6
	VOICE $06, 14, 2, 0, 0
	VIBRATO 1, 5, 2
	DETUNE $FE
	OCTAVE 1
	NOTE G#, 8
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE E_, 0
	NOTE D#, 0
	VOICE $06, 4, 2, 6, 2
	VIBRATO_SEMI 1
	RELEASE_VOL 4
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	LOOP_END 2
	OCTAVE 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 8
	RELEASE 8, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE D_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_END 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE D_, 2
	LOOP_START
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	LOOP_END 2
	RELEASE 0, 0
	WAVE $0E
	VIBRATO 1, 4, 2
	DETUNE $FE
	OCTAVE 1
	NOTE B_, 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	RELEASE 0, 0
	NOTE E_, 0
	VOICE $0C, 14, 2, 0, 0
	VIBRATO 2, 0, 3
	NOTE E_, 4
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE B_, 8
	NOTE F#, 0
	SND_END

Snd56_Drm:
	LEN_UNIT $10
	REST $0A
	DRUM $0D, 6
	REST 0
	REST 0
	REST $0E
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	LEN_UNIT $04
	LOOP_START
	DRUM 4, 6
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 2
	LEN_UNIT $06
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $04
	LOOP_START
	DRUM 4, 2
	LOOP_END 6
	SND_CALL Snd56_Drm_713E
	LOOP_START
	LEN_UNIT $06
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $04
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 3
	LOOP_START
	DRUM 4, 2
	LOOP_END 18
	LOOP_START
	DRUM 4, 6
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 2
	SND_CALL Snd56_Drm_713E
	LOOP_START
	DRUM 4, 2
	LOOP_END 6
	LEN_UNIT $0C
	DRUM 4, 8
	REST 0
	LEN_UNIT $06
	LOOP_START
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	REST 4
	LOOP_END 2
	LOOP_START
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	LOOP_END 3
	REST 4
	LEN_UNIT $04
	LOOP_START
	DRUM 4, 2
	LOOP_END 6
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 7
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 6
	LOOP_START
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	LOOP_END 3
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 8
	DRUM 4, 8
	DRUM 4, 0
	SND_END
Snd56_Drm_713E:
	LEN_UNIT $06
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $04
	LOOP_START
	DRUM 4, 2
	LOOP_END 9
	SND_RET

Snd57_Ch2:
	TEMPO $18
	SND_SEGNO
	VOICE $06, 0, 7, 10, 3
	VIBRATO_SEMI 5
	RELEASE_VOL 3
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE G_, 4
	SND_CALL Snd57_Ch1_71CF
	NOTE E_, 4
	LEN_UNIT $0C
	ATTEN 1
	RELEASE $0E, 2
	RELEASE_VOL 3
	NOTE D#, $0B
	VOICE $01, 8, 7, 6, 7
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	LEN_UNIT $06
	RELEASE $0C, 5
	DUTY_STEP 4, 1
	VIBRATO 1, 2, 1
	NOTE G_, 4
	OCTAVE 3
	NOTE C#, 2
	PAN_LEFT 4
	NOTE C#, 2
	PAN_BOTH 0
	NOTE C#, 4
	NOTE C#, 4
	NOTE A#, 2
	PAN_LEFT 4
	NOTE A#, 2
	PAN_BOTH 0
	NOTE A#, 4
	SND_LOOP

Snd57_Ch1:
	SND_SEGNO
	VOICE $06, 0, 4, 8, 7
	PAN_RIGHT 0
	DETUNE $02
	VIBRATO 1, 0, 1
	OCTAVE 4
	NOTE G_, 5
	SND_CALL Snd57_Ch1_71CF
	NOTE E_, 3
	VOICE $06, 8, 7, 0, 0
	VIBRATO 3, 0, 1
	PAN_RIGHT 3
	OCTAVE 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	ATTEN 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	PAN_LEFT 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 1
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 0
	LOOP_END 2
	RELEASE $0C, 5
	PAN_BOTH 0
	OCTAVE 1
	LOOP_START
	ATTEN 2
	NOTE G_, 4
	NOTE C_HI, 2
	PAN_LEFT 4
	NOTE C_HI, 2
	PAN_BOTH 1
	NOTE C_HI, 4
	OCTAVE 2
	LOOP_END 2
	SND_LOOP
Snd57_Ch1_71CF:
	NOTE F#, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D#, 4
	SND_RET

Snd57_Ch3:
	VOICE $06, 5, 2, 0, 0
	DETUNE $FF
	VIBRATO 1, 3, 10
	SND_SEGNO
	OCTAVE 2
	LOOP_START
	NOTE G_, 8
	NOTE A#, 4
	LOOP_END 4
	NOTE D#, 8
	NOTE G_, 4
	NOTE D#, 8
	NOTE A#, 4
	NOTE D#, 4
	NOTE C_HI, 8
	NOTE D#, 4
	NOTE C_HI, 8
	SND_LOOP

Snd57_Drm:
	SND_END

Snd58_Ch2:
	TEMPO $10
	LEN_UNIT $10
	REST $0D
	SND_SEGNO
	VOICE $08, 0, 8, 10, 7
	RELEASE_VOL 1
	DUTY_STEP 8, 1
	TRANSPOSE_UP 8
	DETUNE $02
	SND_CALL Snd58_Ch1_7223
	TRANSPOSE_DOWN 4
	VOICE $10, 8, 8, 0, 0
	VIBRATO 1, 4, 3
	DETUNE $00
	ATTEN 5
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	NOTE F_, 4
	ATTEN 1
	NOTE E_, 2
	RELEASE 8, 7
	NOTE D#, $0C
	SND_LOOP
Snd58_Ch1_7223:
	ATTEN 0
	OCTAVE 6
	NOTE B_, 1
	NOTE F_, 1
	LOOP_START
	NOTE C#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D_, 1
	ATTEN 5
	LOOP_END 2
	ATTEN 7
	NOTE C#, 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 6
	NOTE G_, 1
	NOTE D#, 1
	LOOP_START
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE A#, 1
	ATTEN 5
	LOOP_END 2
	ATTEN 7
	NOTE B_, 1
	OCTAVE 6
	NOTE E_, 1
	SND_RET

Snd58_Ch1:
	LEN_UNIT $10
	REST $0D
	SND_SEGNO
	VOICE $08, 0, 8, 10, 7
	RELEASE_VOL 1
	DUTY_STEP 8, 1
	DETUNE $FE
	VIBRATO_SEMI 1
	AUTOPAN 0
	SND_CALL Snd58_Ch1_7223
	TRANSPOSE_DOWN 4
	VOICE $10, 8, 6, 0, 0
	VIBRATO 3, 0, 3
	DETUNE $FC
	ATTEN 5
	OCTAVE 2
	ATTEN 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 6
	ATTEN 2
	RELEASE 8, 7
	NOTE C_, $0C
	SND_LOOP

Snd58_Ch3:
	TRANSPOSE_DOWN 4
	VOICE $10, 4, 2, 10, 7
	RELEASE_VOL 4
	VIBRATO_SEMI 4
	REST 1
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 2
	SND_LOOP

Snd58_Drm:
	LEN_UNIT $10
	DRUM $0B, 1
	SND_SEGNO
	DRUM $0A, 2
	SND_LOOP

Snd59_Ch2:
	TEMPO $E0
	LEN_UNIT $02
	REST 8
	SND_SEGNO
	VOICE $02, 8, 7, 12, 2
	RELEASE_VOL 2
	DETUNE $03
	LOOP_START
	OCTAVE 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE D#, 1
	LOOP_END 4
	DETUNE $00
	DUTY 4
	OCTAVE 3
	ATTEN 4
	VOL_RAMP 0
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	VOL_RAMP 8
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	DUTY 0
	ATTEN 4
	VOL_RAMP 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	VOL_RAMP 9
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	SND_LOOP

Snd59_Ch1:
	LEN_UNIT $02
	REST 8
	SND_SEGNO
	VOICE $02, 4, 7, 12, 2
	RELEASE_VOL 2
	DETUNE $FD
	AUTOPAN 0
	LOOP_START
	OCTAVE 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE D#, 1
	LOOP_END 8
	SND_LOOP

Snd59_Ch3:
	LEN_UNIT $02
	REST 8
	SND_SEGNO
	VOICE $02, 4, 2, 12, 2
	RELEASE_VOL 4
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE D#, 1
	LOOP_END 8
	SND_LOOP

Snd59_Drm:
	LEN_UNIT $02
	REST 8
	SND_SEGNO
	DRUM $0A, 2
	SND_LOOP

Snd5A_Ch2:
	SND_SEGNO
	VOICE $0A, 8, 5, 0, 0
	DETUNE $09
	VIBRATO 1, 0, 8
	PAN_LEFT 0
	OCTAVE 1
	NOTE G_, 6
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 2
	NOTE D#, $0C
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 2
	NOTE A_, $0A
	VIBRATO 1, 0, 1
	DETUNE $01
	PAN_BOTH 0
	DUTY 4
	ATTEN 3
	LOOP2_START
	SND_CALL Snd5A_Ch2_7329
	ATTEN 2
	SND_CALL Snd5A_Ch2_7329
	ATTEN 1
	LOOP2_END 2
	SND_LOOP
Snd5A_Ch2_7329:
	LOOP_START
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	LOOP_END 2
	SND_RET

Snd5A_Ch1:
	SND_SEGNO
	VOICE $0A, 0, 6, 10, 0
	AUTOPAN_BOTH 2
	RELEASE_VOL 2
	LOOP_START
	OCTAVE 5
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D_, 1
	LOOP_END 3
	LOOP_START
	NOTE G_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE C#, 1
	LOOP_END 3
	SND_LOOP

Snd5A_Ch3:
	SND_SEGNO
	VOICE $0A, 5, 2, 0, 0
	VIBRATO 2, 0, 3
	OCTAVE 2
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE D#, $0C
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, $0C
	OCTAVE 3
	NOTE D_, $0C
	NOTE D#, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	SND_LOOP

Snd5A_Drm:
	LEN_UNIT $0A
	SND_SEGNO
	DRUM $0A, 8
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 2
	SND_LOOP

Snd5B_Ch2:
	TEMPO $14
	VOICE $07, 4, 9, 1, 7
	VIBRATO 2, 0, 6
	OCTAVE 1
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE B_, 8
	NOTE A#, 4
	LEN_UNIT $0E
	NOTE A_, $0C
	VOICE $0F, 4, 8, 2, 7
	RELEASE_VOL 4
	NOTE B_, 0

Snd5B_Drm:
	SND_END

Snd5B_Ch1:
	VOICE $07, 4, 9, 2, 7
	VIBRATO 3, 4, 2
	DETUNE $02
	PAN_LEFT 0
	OCTAVE 2
	NOTE D#, 5
	NOTE F_, 4
	NOTE F#, 4
	NOTE B_, 8
	NOTE A#, 3
	VOICE $07, 4, 8, 4, 7
	DETUNE $01
	DUTY_STEP 0, 1
	DETUNE $00
	RELEASE 1, 7
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE F_, 8
	NOTE E_, 4
	VOICE $0F, 4, 7, 3, 4
	RELEASE_VOL 2
	VIBRATO 1, 3, 2
	DUTY_STEP 0, 0
	NOTE D#, 0
	SND_END

Snd5B_Ch3:
	VOICE $07, 4, 4, 12, 7
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F#, 1
	LOOP_END 4
	LOOP_START
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	LOOP_END 4
	SND_SEGNO
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	SND_LOOP

Snd5C_Ch2:
	VOICE $08, 8, 7, 8, 3
	DUTY_STEP 4, 1
	DETUNE $01
	VIBRATO_OFF
	VOL_RAMP $0E
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE F#, 2
	LOOP_END 8
	SND_SEGNO
	KEY_TRANSPOSE 0
	LOOP2_START
	LOOP_START
	VOICE $08, 4, 7, 5, 5
	DUTY_STEP 0, 1
	VIBRATO 1, 3, 4
	OCTAVE 3
	NOTE A_, 6
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	OCTAVE 3
	NOTE A_, 6
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	DUTY 0
	DUTY_STEP 8, 1
	VIBRATO 2, 0, 5
	SND_JUMP_N 2, Snd5C_Ch2_7419
	SND_CALL Snd5C_Ch1_7456
Snd5C_Ch2_7419:
	LOOP_END 2
	SND_CALL Snd5C_Ch1_7465
	LOOP2_END 2
	LOOP2_START
	VOICE $08, 0, 4, 3, 1
	VIBRATO 1, 2, 0
	RELEASE_VOL 2
	VOL_RAMP 0
	OCTAVE 3
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	VOL_RAMP 8
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 4
	VOL_RAMP 0
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	VOL_RAMP 8
	NOTE G#, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE G_, 4
	VOL_RAMP 0
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	VOL_RAMP 8
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F_, 0
	SND_CALL Snd5C_Ch1_7474
	LOOP2_END 2
	SND_LOOP
Snd5C_Ch1_7456:
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN_LEFT 4
	NOTE F#, 1
	PAN_BOTH 0
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	PAN_RIGHT 4
	NOTE G#, 1
	SND_RET
Snd5C_Ch1_7465:
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	PAN_LEFT 4
	NOTE G#, 1
	PAN_BOTH 0
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	PAN_RIGHT 4
	NOTE A#, 1
	SND_RET
Snd5C_Ch1_7474:
	VOICE $08, 4, 7, 10, 5
	DUTY_STEP 0, 1
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE F#, 2
	LOOP_END 2
	SND_RET

Snd5C_Ch1:
	VOICE $08, 4, 6, 8, 3
	DUTY_STEP 4, 1
	DETUNE $FF
	VIBRATO_SEMI 2
	VOL_RAMP $0E
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	LOOP_END 8
	SND_SEGNO
	KEY_TRANSPOSE 0
	LOOP2_START
	LOOP_START
	VOICE $08, 8, 6, 5, 5
	DUTY_STEP 0, 1
	VIBRATO 3, 0, 5
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE D#, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE D#, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	DUTY 0
	DUTY_STEP 8, 1
	VIBRATO 2, 0, 5
	SND_JUMP_N 2, Snd5C_Ch1_74C2
	SND_CALL Snd5C_Ch1_7456
Snd5C_Ch1_74C2:
	LOOP_END 2
	SND_CALL Snd5C_Ch1_7465
	LOOP2_END 2
	LOOP2_START
	VOICE $08, 0, 4, 0, 0
	VIBRATO_SEMI 5
	RELEASE_VOL 2
	VOL_RAMP 0
	OCTAVE 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	VOL_RAMP 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE D#, 4
	NOTE D#, 4
	VOL_RAMP 0
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	VOL_RAMP 8
	NOTE D#, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D_, 4
	VOL_RAMP 0
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 4
	VOL_RAMP 8
	NOTE D_, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE C_, 0
	SND_CALL Snd5C_Ch1_7474
	LOOP2_END 2
	SND_LOOP

Snd5C_Ch3:
	VOICE $08, 1, 2, 8, 5
	RELEASE_VOL 4
	VIBRATO_SEMI 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 2
	LOOP_END 4
	SND_SEGNO
	KEY_TRANSPOSE 0
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 2
	LOOP_END 24
	SND_LOOP

Snd5C_Drm:
	LEN_UNIT $08
	SND_SEGNO
	DRUM $0A, 2
	DRUM $0A, 6
	DRUM 3, 8
	SND_LOOP

Snd5D_Ch2:
	TEMPO $00
	SND_SEGNO
	LOOP2_START
	VOICE $08, 8, 8, 12, 2
	DUTY_STEP 0, 1
	VIBRATO 2, 0, 4
	RELEASE_VOL 2
	ATTEN 3
	OCTAVE 2
	NOTE B_, $0C
	ATTEN 2
	OCTAVE 3
	NOTE C_, $0C
	ATTEN 1
	OCTAVE 2
	NOTE A#, $0C
	ATTEN 2
	NOTE B_, $0C
	LOOP2_END 2
	VOICE $08, 4, 8, 2, 7
	VIBRATO 1, 3, 2
	DUTY_STEP 0, 0
	LOOP_START
	OCTAVE 2
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 8
	OCTAVE 2
	NOTE B_, 4
	NOTE A#, $0C
	SND_JUMP_N 2, Snd5D_Ch2_7557
	NOTE F#, $0C
Snd5D_Ch2_7557:
	LOOP_END 2
	OCTAVE 3
	NOTE F#, $0C
	LOOP2_START
	VOICE $08, 4, 8, 8, 3
	RELEASE_VOL 2
	VIBRATO_OFF
	ATTEN 5
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY 0
	RELEASE 8, 3
	ATTEN 3
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 3
	NOTE F#, 2
	NOTE F#, 2
	LOOP2_END 2
	VOICE $08, 4, 8, 0, 0
	LOOP2_START
	ATTEN 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP2_END 8
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd5D_Ch1:
	SND_SEGNO
	LOOP2_START
	VOICE $08, 0, 8, 12, 2
	VIBRATO 3, 3, 3
	RELEASE_VOL 2
	ATTEN 3
	OCTAVE 2
	NOTE G_, $0C
	ATTEN 2
	NOTE G_, $0C
	ATTEN 1
	NOTE F#, $0C
	ATTEN 2
	NOTE F#, $0C
	LOOP2_END 2
	VOICE $08, 0, 6, 2, 7
	DETUNE $02
	LOOP2_START
	OCTAVE 1
	NOTE B_, 2
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 3
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	ATTEN 0
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	ATTEN 3
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 3
	NOTE A#, 4
	ATTEN 0
	NOTE F#, 2
	ATTEN 3
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 2
	SND_JUMP_N 2, Snd5D_Ch1_7601
	NOTE C#, 2
	ATTEN 3
	NOTE F#, 4
	ATTEN 0
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	ATTEN 0
	NOTE C#, 2
Snd5D_Ch1_7601:
	LOOP2_END 2
	NOTE A#, 2
	ATTEN 3
	OCTAVE 3
	NOTE F#, 4
	OCTAVE 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	LOOP2_START
	VOICE $08, 4, 8, 8, 3
	RELEASE_VOL 1
	VIBRATO_SEMI 5
	DETUNE $00
	ATTEN 5
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C#, 2
	VIBRATO_OFF
	RELEASE 8, 3
	DUTY 0
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 3
	NOTE D#, 2
	NOTE D#, 2
	LOOP2_END 2
	VOICE $08, 4, 8, 0, 0
	VIBRATO 3, 3, 2
	ATTEN 4
	DETUNE $02
	REST 1
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	LOOP2_END 7
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE G_, 1
	ATTEN 0
	DETUNE $00
	DUTY 8
	VIBRATO 3, 1, 4
	OCTAVE 2
	NOTE E_, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	NOTE D#, $0C
	NOTE F#, $0C
	NOTE F#, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	SND_LOOP

Snd5D_Ch3:
	SND_SEGNO
	LOOP2_START
	VOICE $08, 4, 2, 8, 4
	DETUNE $FF
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	LOOP_END 6
	LOOP_START
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	LOOP_END 2
	LOOP2_END 2
	VOICE $08, 4, 2, 8, 4
	LOOP_START
	PAN_BOTH 0
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 2
	NOTE E_, 2
	LOOP_END 16
	LOOP2_START
	VOICE $08, 4, 2, 2, 7
	VIBRATO 2, 0, 5
	OCTAVE 2
	NOTE E_, 6
	NOTE F#, 6
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE B_, 8
	NOTE A#, 4
	NOTE B_, $0C
	LOOP2_END 2
	VOICE $08, 4, 2, 0, 0
	VIBRATO 2, 0, 3
	OCTAVE 3
	NOTE E_, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	NOTE D#, $0C
	NOTE F#, $0C
	NOTE F#, $0C
	NOTE E_, $0E
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D#, 4
	SND_LOOP

Snd5D_Drm:
	LEN_UNIT $08
	SND_SEGNO
	DRUM $0C, 2
	DRUM $0C, 8
	DRUM $0C, 2
	SND_LOOP
	db $FF ; unreachable byte after an end

Snd5E_Ch2:
	TEMPO $10
	RELEASE_VOL 5
	SND_CALL Snd5E_Ch1_77F6
	LOOP2_START
	SND_CALL Snd5E_Ch1_77EC
	SND_CALL Snd5E_Ch1_7800
	OCTAVE 2
	LOOP2_END 2
	LOOP2_START
	VOICE $08, 4, 7, 9, 3
	VIBRATO 1, 2, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	ATTEN 3
	RELEASE 8, $0C
	NOTE C_, 7
	DUTY_STEP 0, 0
	ATTEN 1
	OCTAVE 3
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 1
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE G_, 3
	VOICE $08, 4, 6, 10, 7
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	DUTY 0
	DUTY_STEP 4, 1
	VIBRATO_OFF
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	RELEASE 9, 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	VOLUME $07
	RELEASE $0A, 2
	VOL_RAMP $0B
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0A, 6
	ATTEN 0
	OCTAVE 1
	NOTE D_, 3
	VOICE $08, 4, 7, 5, 7
	DUTY_STEP 0, 0
	VIBRATO 1, 4, 0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A#, 6
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	VOICE $04, 8, 7, 0, 0
	ATTEN 3
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 3
	LEN_UNIT $08
	OCTAVE 4
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 3
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	DUTY 4
	RELEASE 2, 7
	NOTE F_, 6
	NOTE G_, 3
	DUTY_STEP 8, 2
	VIBRATO 1, 3, 1
	RELEASE_VOL 4
	LEN_UNIT $06
	NOTE G_, 8
	NOTE D#, 4
	NOTE C_, 4
	NOTE G#, 4
	NOTE D#, 4
	NOTE G_, 8
	SND_CALL Snd5E_Ch1_781F
	OCTAVE 2
	SND_CALL Snd5E_Ch1_780A
	SND_CALL Snd5E_Ch1_7811
	SND_CALL Snd5E_Ch1_780A
	VOICE $04, 0, 7, 10, 3
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	VOICE $06, 4, 7, 2, 7
	OCTAVE 2
	NOTE D#, 8
	NOTE F_, 4
	NOTE F#, 4
	DUTY_STEP 0, 0
	SND_JUMP_N 2, Snd5E_Ch2_77E2
	NOTE B_, 0
	NOTE A#, 0
	VOICE $04, 0, 3, 8, 3
	VOL_RAMP 1
	OCTAVE 3
	LOOP_START
	NOTE A_, 2
	LOOP_END 6
	LOOP_START
	NOTE B_, 2
	LOOP_END 6
Snd5E_Ch2_77E2:
	LOOP2_END 2
	VIBRATO 1, 10, 3
	NOTE B_, $0C
	RELEASE 8, $0F
	NOTE A#, 0
	SND_END
Snd5E_Ch1_77EC:
	RELEASE 8, 3
	NOTE E_, 6
	RELEASE 8, 2
	LOOP_START
	NOTE E_, 2
	LOOP_END 9
	SND_RET
Snd5E_Ch1_77F6:
	VOICE $04, 4, 3, 8, 4
	DUTY_STEP 0, 1
	VOL_RAMP 5
	OCTAVE 1
	SND_RET
Snd5E_Ch1_7800:
	RELEASE $0C, 4
	NOTE B_, 6
	RELEASE $0C, 2
	LOOP_START
	NOTE B_, 2
	LOOP_END 9
	SND_RET
Snd5E_Ch1_780A:
	NOTE A_, 6
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	SND_RET
Snd5E_Ch1_7811:
	OCTAVE 3
	NOTE C#, 6
	NOTE C#, 3
	NOTE C#, 3
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE E_, 6
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	SND_RET
Snd5E_Ch1_781F:
	VOICE $02, 4, 3, 4, 4
	VOL_RAMP 7
	DUTY_STEP 8, 1
	RELEASE_VOL 2
	SND_RET

Snd5E_Ch1:
	DETUNE $02
	SND_CALL Snd5E_Ch1_77F6
	SND_CALL Snd5E_Ch1_77EC
	SND_CALL Snd5E_Ch1_77EC
	SND_CALL Snd5E_Ch1_7800
	OCTAVE 2
	SND_CALL Snd5E_Ch1_77EC
	LOOP2_START
	VOICE $08, 4, 7, 9, 3
	VIBRATO 3, 1, 1
	DETUNE $00
	ATTEN 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 2
	ATTEN 3
	RELEASE 8, $0C
	NOTE G_, 7
	DUTY 8
	DUTY_STEP 0, 0
	RELEASE $0A, 3
	ATTEN 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	LEN_UNIT $04
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 3
	VOICE $08, 0, 7, 10, 3
	VIBRATO 2, 0, 0
	DETUNE $01
	ATTEN 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	VOICE $08, 0, 7, 2, 7
	VIBRATO 3, 3, 0
	DUTY_STEP 4, 1
	ATTEN 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	ATTEN 0
	NOTE B_, 6
	NOTE A_, 3
	VOICE $08, 8, 7, 10, 2
	VIBRATO 3, 1, 0
	DUTY_STEP 0, 0
	VOL_RAMP $0B
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 8, 7
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A#, 6
	DUTY 0
	DUTY_STEP 0, 1
	RELEASE 2, 7
	ATTEN 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A#, 3
	DUTY 8
	DUTY_STEP 0, 0
	RELEASE 5, 7
	ATTEN 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 3
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F_, 3
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE 5, 7
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 6
	NOTE B_, 3
	VOICE $04, 8, 7, 2, 7
	VIBRATO 3, 2, 0
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE D#, $0C
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE $0A, 7
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C_, 6
	RELEASE $0A, 3
	LOOP_START
	NOTE D#, 2
	LOOP_END 6
	SND_CALL Snd5E_Ch1_781F
	LOOP_START
	OCTAVE 2
	SND_CALL Snd5E_Ch1_780A
	LOOP_END 2
	SND_CALL Snd5E_Ch1_7811
	VOICE $04, 0, 7, 10, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	VOICE $06, 4, 7, 2, 7
	OCTAVE 2
	NOTE D#, 9
	NOTE F_, 4
	NOTE F#, 3
	DUTY_STEP 0, 0
	SND_JUMP_N 2, Snd5E_Ch1_792C
	NOTE F#, 0
	NOTE F#, 0
	VOICE $04, 0, 3, 8, 3
	VOL_RAMP 2
	OCTAVE 3
	LOOP_START
	NOTE F#, 2
	LOOP_END 12
Snd5E_Ch1_792C:
	LOOP2_END 2
	NOTE F#, $0C
	RELEASE 8, $0F
	NOTE F#, 0
	SND_END

Snd5E_Ch3:
	VOICE $04, 4, 2, 5, 2
	VIBRATO_SEMI 2
	DETUNE $FE
	RELEASE_VOL 4
	LOOP2_START
	OCTAVE 2
	NOTE E_, 6
	LOOP_START
	NOTE E_, 2
	LOOP_END 9
	LOOP2_END 4
	LOOP2_START
	VOICE $06, 4, 2, 7, 6
	RELEASE_VOL 4
	LOOP_START
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	LOOP_END 5
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 4
	LOOP_START
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	LOOP_END 5
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 4
	VOICE $08, 4, 2, 0, 0
	VIBRATO 1, 3, 2
	NOTE C_, $0C
	NOTE G#, 6
	NOTE C_, 6
	VOICE $02, 4, 2, 4, 3
	RELEASE_VOL 4
	LOOP_START
	NOTE A_, 6
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LOOP_END 4
	LOOP_START
	NOTE A#, 4
	LOOP_END 12
	LEN_UNIT $06
	RELEASE 0, 0
	VIBRATO 2, 0, 3
	NOTE D#, 8
	NOTE F_, 4
	NOTE F#, 4
	SND_JUMP_N 2, Snd5E_Ch3_799F
	NOTE D#, 0
	NOTE D#, 0
	WAVE 4
	RELEASE 3, 7
	LEN_UNIT $04
	RELEASE_VOL 4
	LOOP_START
	NOTE B_, 2
	LOOP_END 12
Snd5E_Ch3_799F:
	LOOP2_END 2
	NOTE D#, $0C
	NOTE D#, 0
	SND_END

Snd5E_Drm:
	LEN_UNIT $08
	LOOP2_START
	DRUM 2, 3
	LOOP_START
	DRUM 2, 1
	LOOP_END 9
	LOOP2_END 2
	DRUM 4, 3
	LOOP_START
	DRUM 4, 1
	LOOP_END 9
	DRUM 5, 3
	LOOP_START
	DRUM 5, 1
	LOOP_END 9
	SND_CALL Snd5E_Drm_79CF
	SND_CALL Snd5E_Drm_79DF
	REST $0C
	REST $0C
	LOOP_START
	DRUM 4, 1
	LOOP_END 6
	LOOP_START
	DRUM 5, 1
	LOOP_END 6
	SND_CALL Snd5E_Drm_79CF
	SND_CALL Snd5E_Drm_79DF
	SND_END
Snd5E_Drm_79CF:
	LEN_UNIT $02
	LOOP_START
	DRUM 4, $0C
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 6
	DRUM 4, 3
	DRUM 4, 3
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	LOOP_END 7
	SND_RET
Snd5E_Drm_79DF:
	LEN_UNIT $08
	DRUM 6, $0C
	REST $0C
	LEN_UNIT $02
	LOOP_START
	DRUM 2, 6
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	LOOP_END 4
	LOOP_START
	DRUM 5, 4
	LOOP_END 6
	LOOP_START
	DRUM 4, 4
	LOOP_END 6
	LEN_UNIT $08
	DRUM 6, $0C
	SND_RET

Snd5F_Ch2:
	TEMPO $18
	RELEASE_VOL 5
	DETUNE $01
	SND_CALL Snd5E_Ch1_77F6
	REST $0C
	SND_SEGNO
	SND_CALL Snd5E_Ch1_77EC
	SND_CALL Snd5E_Ch1_7800
	OCTAVE 2
	SND_LOOP

Snd5F_Ch1:
	SND_CALL Snd5E_Ch1_77F6
	REST $0C
	SND_CALL Snd5E_Ch1_77EC
	SND_CALL Snd5E_Ch1_77EC
	SND_SEGNO
	SND_CALL Snd5E_Ch1_7800
	OCTAVE 2
	SND_CALL Snd5E_Ch1_77EC
	SND_LOOP

Snd5F_Ch3:
	VOICE $04, 4, 2, 5, 2
	VIBRATO_SEMI 2
	DETUNE $FE
	RELEASE_VOL 4
	REST $0C
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 6
	LOOP_START
	NOTE E_, 2
	LOOP_END 9
	SND_LOOP

Snd5F_Drm:
	LEN_UNIT $08
	REST 6
	LOOP2_START
	DRUM 2, 3
	LOOP_START
	DRUM 2, 1
	LOOP_END 9
	LOOP2_END 2
	DRUM 4, 3
	LOOP_START
	DRUM 4, 1
	LOOP_END 9
	SND_SEGNO
	DRUM 5, 3
	LOOP_START
	DRUM 5, 1
	LOOP_END 9
	SND_LOOP

Snd60_Ch2:
	VOICE $07, 0, 5, 0, 0
	VIBRATO 1, 0, 0
Snd60_Ch1_7A51:
	SND_SEGNO
	SND_CALL Snd60_Ch1_7A63
	SND_CALL Snd60_Ch1_7A63
	TRANSPOSE_DOWN 2
	SND_CALL Snd60_Ch1_7A63
	SND_CALL Snd60_Ch1_7A63
	TRANSPOSE_DOWN 0
	SND_LOOP
Snd60_Ch1_7A63:
	VOL_RAMP 1
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE G_, 2
	NOTE G#, 2
	LOOP_END 3
	VOL_RAMP 9
	LOOP2_END 2
	SND_RET

Snd60_Ch1:
	VOICE $07, 0, 2, 0, 0
	VIBRATO 3, 0, 1
	REST 1
	DETUNE $01
	SND_JUMP Snd60_Ch1_7A51

Snd60_Ch3:
	VOICE $07, 4, 2, 0, 0
	VIBRATO 2, 0, 6
	TRANSPOSE_DOWN 1
	SND_SEGNO
	OCTAVE 3
	NOTE D_, $0C
	NOTE D#, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	NOTE C_, $0C
	NOTE C#, $0C
	NOTE C_, $0C
	NOTE C#, $0C
	SND_LOOP

Snd60_Drm:
	LEN_UNIT $07
	SND_SEGNO
	DRUM $0A, $0A
	DRUM $0A, 2
	SND_LOOP
