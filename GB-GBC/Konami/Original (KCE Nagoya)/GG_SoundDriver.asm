; ==========================================================================
; Ganbare Goemon: Sarawareta Ebisumaru! (J) - Konami sound driver (fourth GB version, extended)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: timer ISR, PlaySoundFar, sound init, FarRead, update and PlaySound ($2AFB-$2DA7)
;   bank 14: tables, drum hits, the track code (the only copy), StopAll, SFX/jingles, 2 songs
;   bank 15: songs $A1-$BF
;   bank 13 ($7000-$7FFF): songs $F1-$FA
; Build: rgbasm -Wall -o gg.o GG_SoundDriver.asm && rgblink -o gg.gb gg.o
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
DEF rP1 EQU $FF00

; ---------------------------------------------------------------- RAM
DEF wTrkSfx1 EQU $D080 ; 80 bytes
DEF wTrkSfx2 EQU $D180 ; 80 bytes
DEF wTrkSfxN EQU $D280 ; 80 bytes
DEF wTrkCh1 EQU $D380 ; 80 bytes
DEF wTrkCh2 EQU $D480 ; 80 bytes
DEF wTrkCh3 EQU $D580 ; 80 bytes
DEF wTrkDrm EQU $D680 ; 80 bytes
DEF wTrackDesc EQU $D0D0
DEF wMusicSlot EQU $D0D1
DEF wTempo EQU $D0D2
DEF wTempoAcc EQU $D0D3
DEF wReqPrio EQU $D0D4
DEF wReqId EQU $D0D5
DEF wPauseLast EQU $D0D6
DEF wFadeTimer EQU $D0D7
DEF wFadeLevel EQU $D0D8
DEF wFadeRate EQU $D0D9
DEF wWaveId EQU $D0DA
DEF wD0DB EQU $D0DB
DEF wReadBuf EQU $D1D0 ; 4 bytes
DEF wRomBank EQU $C006
DEF wSndLock EQU $C009
DEF wPauseFlags EQU $C0E2
DEF rROMB EQU $2000 ; MBC1 bank select
DEF SND_TABLE EQU $4000 ; sound table of banks 14 and 15 (index 1 = first id)
DEF SND_TABLE_B13 EQU $7000 ; sound table of bank 13

; per-track fields: track n lives at $D080 + n*$100, so H = $D0 + n and L = field
DEF TRK_PRIO EQU $80
DEF TRK_ID EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_PANFLAGS EQU $86
DEF TRK_FLOW EQU $87
DEF TRK_VIB EQU $88
DEF TRK_ENVNO EQU $89
DEF TRK_DETUNE EQU $8A
DEF TRK_ATTEN EQU $8C
DEF TRK_TRANSP EQU $8D
DEF TRK_JUMPCNT EQU $8E
DEF TRK_DUTYTICKS EQU $8F
DEF TRK_DUTYCNT EQU $90
DEF TRK_DUTYSTART EQU $91
DEF TRK_UNIT EQU $92
DEF TRK_OCTAVE EQU $93
DEF TRK_PERIOD EQU $94
DEF TRK_CURPERIOD EQU $96
DEF TRK_VOL EQU $98
DEF TRK_LEVEL EQU $99
DEF TRK_DUTY EQU $9A
DEF TRK_CURDUTY EQU $9B
DEF TRK_GATE EQU $9C
DEF TRK_RELTICK EQU $9D
DEF TRK_ENV EQU $9E
DEF TRK_CH3TIMER EQU $9F
DEF TRK_PAN EQU $A0
DEF TRK_VIBPTR EQU $A1
DEF TRK_VIBCUR EQU $A3
DEF TRK_VIBTIMER EQU $A5
DEF TRK_VIBDELAY EQU $A6
DEF TRK_VIBDELAYCNT EQU $A7
DEF TRK_VIBDEPTH EQU $A8
DEF TRK_VIBLOOPPTR EQU $A9
DEF TRK_VIBLOOPCNT EQU $AB
DEF TRK_VIBSEGNO EQU $AC
DEF TRK_ENVPTR EQU $AE
DEF TRK_ENVCUR EQU $B0
DEF TRK_ENVTIMER EQU $B2
DEF TRK_ENVLOOPPTR EQU $B3
DEF TRK_ENVLOOPCNT EQU $B5
DEF TRK_ENVSEGNO EQU $B6
DEF TRK_LOOPPTR EQU $B8
DEF TRK_LOOPCNT EQU $BA
DEF TRK_LOOP2PTR EQU $BB
DEF TRK_LOOP2CNT EQU $BD
DEF TRK_SEGNO EQU $BE
DEF TRK_RET EQU $C0
DEF TRK_REG1 EQU $C2
DEF TRK_REG2 EQU $C3
DEF TRK_REG3 EQU $C4
DEF TRK_REG4 EQU $C5
DEF TRK_SLIDECNT EQU $C6
DEF TRK_SLIDEVOL EQU $C7
DEF TRK_SLIDEDELTA EQU $C8
DEF TRK_RAWVOL EQU $CA
DEF TRK_RAWOFS EQU $CB
DEF TRK_RAWMARK EQU $CD
DEF TRK_LASTPITCH EQU $CF

; TRK_FLAGS: 0 rest, 1 raw frames, 2 retrigger long notes, 3 noise hold, 4 tempo skip, 5 reload duty,
;   6 slide frames
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running, 3 envelope running
; TRK_FLOW: 0/1 loop open, 2 in a call, 3 mark set, 4/5 vibrato loop/mark, 6/7 envelope loop/mark
; track descriptors (wTrackDesc): hi = track, lo = channel: Ch1 $00, Ch2 $11, Ch3 $22, Drm $34,
; Sfx1 $40, Sfx2 $52 (CH3), SfxN $63

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
DEF OCT_UP EQU 13 ; the previous note's pitch, one octave higher

; sound header: priority, track mask (Sfx1, Sfx2 (CH3), SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; note: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = sound id 1-13 (always from bank 14), lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: NR43 value (no retrigger), length = unit; 0 = rest
MACRO NOISE
	db \1
ENDM
MACRO NOISE_REST
	db $00
ENDM
; noise SFX track in hold mode: volume (NR42 = vol << 4, retriggered if it changed), NR43
MACRO NOISE_HOLD
	db \1, \2
ENDM
; $E0 unit, duty|vol, gate|env (tone/wave tracks; on CH3 duty = wave); turns raw frames and the envelope off
MACRO VOICE
	db $E0, \1, (\2 << 4) | \3, (\4 << 4) | \5
ENDM
; $E0 unit, NR42 (noise SFX track)
MACRO NVOICE
	db $E0, \1, \2
ENDM
; $E0 unit | $80 on the noise SFX track: hold mode (2-byte notes)
MACRO NVOICE_HOLD
	db $E0, $80 | \1
ENDM
; $E0 unit | $80, NRx1 (CH3: wave << 4), NR10 (only written on Ch1/Sfx1): raw frames follow
MACRO RAW_VOICE
	db $E0, $80 | \1, \2, \3
ENDM
; raw frame: NRx2 = vol << 4 (+ TRK_RAWVOL), NRx3/NRx4 = period (+ TRK_RAWOFS), for one unit
MACRO RAW_NOTE
	db (\1 << 4) | HIGH(\2), LOW(\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; slide frame (after SLIDE_ON): for count units, period += delta and level += vol << 4 each unit
; (vneg / pneg negate them)
MACRO SLIDE
	db \1, (\4 << 7) | (\2 << 4) | \3, \5
ENDM
; raw-frame commands: $EB slide frames on, $EC off, $ED mark, $EE n v p: back to the mark until the
; n-th pass, adding v to TRK_RAWVOL and p (signed) to TRK_RAWOFS each time
MACRO SLIDE_ON
	db $EB
ENDM
MACRO SLIDE_OFF
	db $EC
ENDM
MACRO RAW_MARK
	db $ED
ENDM
MACRO RAW_REPEAT
	db $EE, \1, \2, \3
ENDM
; $E1-$E6: octave
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release point = length * gate / 16), env (NRx2 low nibble at the release; 0 = cut)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9: NR10 (written at once)
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
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $20 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $30 | \1
ENDM
MACRO AUTOPAN_R
	db $EA, $40 | \1
ENDM
MACRO AUTOPAN_L
	db $EA, $50 | \1
ENDM
MACRO AUTOPAN_OFF
	db $EA, $60 | \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \1
ENDM
; $EB n, xy: vibrato table n & $7F, delay x * unit ticks, depth y (0 = 1)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $EC n: volume envelope table n (0 = off)
MACRO ENVELOPE
	db $EC, \1
ENDM
MACRO ENVELOPE_OFF
	db $EC, $00
ENDM
; $ED xy: notes start with duty x, the voice duty comes back after y ticks (y = 0: off, duty rewritten)
MACRO DUTY_STEP
	db $ED, (\1 << 4) | \2
ENDM
; $EE: tempo
MACRO TEMPO
	db $EE, \1
ENDM
; $EF: signed period offset
MACRO DETUNE
	db $EF, \1
ENDM
MACRO ATTEN
	db $F0 | \1
ENDM
; $F8 x: TRK_VOL = swap(x)
MACRO VOLUME
	db $F8, \1
ENDM
; $F9 n addr: jump on the n-th pass (counter TRK_JUMPCNT, reset when it jumps), else go on
MACRO JUMP_ON
	db $F9, \1
	dw \2
ENDM
MACRO SND_JUMP
	db $FA
	dw \1
ENDM
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
MACRO SND_CALL
	db $FD
	dw \1
ENDM
MACRO SND_RET
	db $FD
ENDM
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; vibrato tables: one byte per step: time << 4 | negative << 3 | offset (x depth); $FB loop, $FE mark, $FF end
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
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
; envelope tables: one byte per step: time << 4 | volume (minus TRK_ATTEN and the fade); $FB loop, $FE mark,
; $FF end (the volume stays)
MACRO ENV_STEP
	db (\1 << 4) | \2
ENDM
MACRO ENV_LOOP_START
	db $FB
ENDM
MACRO ENV_LOOP_END
	db $FB, \1
ENDM
MACRO ENV_MARK
	db $FE
ENDM
MACRO ENV_END
	db $FF
ENDM

SECTION "Timer vector", ROM0[$0050]

; Timer interrupt (TMA $C0, 16384 Hz -> 256 Hz).
TimerVector:
	jp TimerISR

SECTION "Timer ISR", ROM0[$00DA]

; TimerISR: interrupts are enabled at once; one driver update unless wSndLock bit 0
; (update running) or bit 1 (PlaySoundFar running) is set.
TimerISR:
	ei
	push hl
	push de
	push bc
	push af
	ld hl, wSndLock
	ld a, [hl]
	and $03
	jr nz, .l00F1
	set 0, [hl]
	call SndUpdate
	ld hl, wSndLock
	res 0, [hl]
.l00F1:
	pop af
	pop bc
	pop de
	pop hl
	ret

SECTION "PlaySoundFar", ROM0[$01B2]

; PlaySoundFar: A = sound id (0 = stop all). wSndLock bit 1 is set around PlaySound and
; the game's bank (wRomBank) is mapped again afterwards. Requests are not refused.
PlaySoundFar:
	push hl
	ld hl, wSndLock
	set 1, [hl]
	push de
	push bc
	push af
	call PlaySound
	ld a, [wRomBank]
	ld [rROMB], a
	pop af
	pop bc
	pop de
	ld hl, wSndLock
	res 1, [hl]
	pop hl
	ret

; SoundInit (part of the boot code): NR50 = $77, NR51 = $FF, NR52 = $80, and the
; register address fields TRK_REG1-4 of the six tracks with a channel (the drum track has
; none, so they stay 0 = rP1).
SoundInit:
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
	ld l, TRK_REG1
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
	ld l, TRK_REG1
	ret

SECTION "FarRead", ROM0[$0210]

; FarRead: copy the 4 stream bytes at DE into wReadBuf from the bank of the track's
; sound id ($A0-$EF: 15, >= $F0: 13, else the mapped bank 14), then map bank 14 again.
; Every stream read of the track code goes through here.
FarRead:
	ld l, TRK_ID
	ld a, [hl]
	cp $A0
	jp c, .l0224
	cp $F0
	ld a, $0D
	jp nc, .l0221
	ld a, $0F
.l0221:
	ld [rROMB], a
.l0224:
	push de
	ld a, [de]
	ld [wReadBuf], a
	inc de
	ld a, [de]
	ld [wReadBuf + $01], a
	inc de
	ld a, [de]
	ld [wReadBuf + $02], a
	inc de
	ld a, [de]
	ld [wReadBuf + $03], a
	ld a, $0E
	ld [rROMB], a
	pop de
	ret

SECTION "Sound ROM0", ROM0[$2AFB]

; SndUpdate (256 Hz): pause edges, then (unless paused) one music track per update in
; turn (Ch1, Ch2, Ch3, Drm; fade and tempo before Ch1), then SfxN, Sfx2, Sfx1, all on the
; bank-14 track code. The game's bank is mapped again at the end.
SndUpdate:
	ld a, [wPauseFlags]
	ld hl, wPauseLast
	cp [hl]
	jp z, .l2B0B
	ld [hl], a
	cp $00
	call PauseEdge
.l2B0B:
	ld a, [wPauseFlags]
	or a
	jp nz, .l2B25
	ld a, [wMusicSlot]
	and $03
	call MusicSlot
	ld hl, wMusicSlot
	inc [hl]
	ld h, HIGH(wTrkSfxN)
	ld a, $63
	call RunTrack
.l2B25:
	ld h, HIGH(wTrkSfx2)
	ld a, $52
	call RunTrack
	ld h, HIGH(wTrkSfx1)
	ld a, $40
	call RunTrack
	ld a, [wRomBank]
	ld [rROMB], a
	ret

MusicSlot:
	ld hl, MusicSlotTable
	call LoadPtrIndexed0
	jp hl
MusicSlotTable:
	dw MusicSlotCh1
	dw MusicSlotCh2
	dw MusicSlotCh3
	dw MusicSlotDrm

MusicSlotCh1:
	ld h, HIGH(wTrkCh1)
	call FadeTick
	call TempoTick
	ld h, HIGH(wTrkCh1)
	xor a
	jp RunTrack

MusicSlotCh2:
	ld h, HIGH(wTrkCh2)
	ld a, $11
	jp RunTrack

MusicSlotCh3:
	ld h, HIGH(wTrkCh3)
	ld a, $22
	jp RunTrack

MusicSlotDrm:
	ld h, HIGH(wTrkDrm)
	ld a, $34

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, $0E
	ld [rROMB], a
	jp TrackTick

; PauseEdge (Z = unpause). Pause: stop SfxN, mute CH4 and CH2. Unpause: stop Sfx1 and
; Sfx2 (not SfxN), NR10 = 8, mute CH1, NR32 = 0, give CH1 and CH3 back to the music
; (NR51 bits, period) and mark Ch1-Ch3 for a retrigger on long notes.
PauseEdge:
	jp z, UnpauseRestore
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

UnpauseRestore:
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
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG3
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
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

; TempoTick: wTempoAcc += wTempo once per four updates; a carry sets TRK_FLAGS bit 4
; on all four music tracks, so each skips its next tick.
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
	jp c, .l2C14
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l2C14:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: the game sets wFadeRate. Every wFadeRate calls wFadeLevel += $10 (taken
; off new note and envelope volumes, added to CH3's level code); at $50 the drums stop,
; at $70 all music stops and the fade ends.
FadeTick:
	ld a, [wFadeRate]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld a, [wFadeLevel]
	add a, $10
	ld [wFadeLevel], a
	cp $50
	jp z, FadeStopDrums
	cp $70
	ret nz
	xor a
	ld [wFadeLevel], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jp nz, .l2C5A
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l2C5A:
	xor a
	ld h, HIGH(wTrkCh1)
	ld [hl-], a
	ld [hl+], a
	inc h
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ld h, HIGH(wTrkSfx2)
	ld a, [hl]
	or a
	ld a, $00
	jp nz, .l2C7B
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l2C7B:
	ld h, HIGH(wTrkCh3)
	ld [hl-], a
	ld [hl], a
	ret

FadeStopDrums:
	ld h, HIGH(wTrkDrm)
	xor a
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ret

LoadPtrIndexed0:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

; PlaySound: 0 = StopAll. Ids $01-$9F: header from bank 14, $A0-$EF bank 15 (index
; id - $A0), $F0-$FF bank 13 (index id - $F0, table at $7000). If any SFX track of the mask
; holds a higher priority, nothing is started at all. Music needs the Ch1 bit and a
; priority >= Ch1's; it resets tempo, fade and the music slot and starts Ch2/Ch3/Drm
; without a priority test.
PlaySound:
	ld [wReqId], a
	or a
	jp nz, PlaySoundId
	ld a, $0E
	ld [rROMB], a
	jp StopAll

PlaySoundId:
	ld b, a
	cp $A0
	jp nc, .l2CB5
	ld a, $0E
	ld [rROMB], a
	ld a, b
	ld hl, SND_TABLE - 2
	jp PlaySoundHeader
.l2CB5:
	cp $F0
	jp nc, .l2CC8
	ld a, $0F
	ld [rROMB], a
	ld a, b
	ld hl, SND_TABLE - 2
	sub $A0
	jp PlaySoundHeader
.l2CC8:
	ld a, $0D
	ld [rROMB], a
	ld a, b
	ld hl, SND_TABLE_B13 - 2
	sub $F0

PlaySoundHeader:
	call LoadPtrIndexed0
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
	rrc b
	rrc b
	rrc b
	rrc b
	rrc b
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
	ld [wD0DB], a
	srl b
	ret nc
	ld hl, wTrkCh1
	ld a, [wReqPrio]
	cp [hl]
	ret c
	xor a
	ld [wTempo], a
	ld [wFadeRate], a
	ld [wFadeLevel], a
	ld [wFadeTimer], a
	ld [wMusicSlot], a
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

; Track start: TRK_LEN = 1, TRK_FLAGS..TRK_DUTYCNT = 0, TRK_RAWVOL/TRK_RAWOFS = 0,
; wWaveId = 0, NRx2 = 0 on the track's channel (on the drum track: rP1 = 0).
StartTrackData:
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
	ld [hl+], a
	ld [hl], a
	ld l, TRK_RAWVOL
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld [wWaveId], a
	ld l, TRK_REG2
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
	call StartTrackData
	ld a, $D0
	cp h
	jp nz, .l2D97
	ld a, $08
	ld c, $10
	ldh [c], a
.l2D97:
	ld a, $D2
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

SECTION "Sound bank 14", ROMX[$4000], BANK[14]

; SoundTable: ids $01-$90 (the code loads SND_TABLE - 2 and indexes by id).
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
	dw SndHdr0B ; $0C
	dw SndHdr0B ; $0D
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
	dw SndHdr64 ; $64
	dw SndHdr65 ; $65
	dw SndHdr66 ; $66
	dw SndHdr67 ; $67
	dw SndHdr68 ; $68
	dw SndHdr69 ; $69
	dw SndHdr6A ; $6A
	dw SndHdr6B ; $6B
	dw SndHdr6C ; $6C
	dw SndHdr6D ; $6D
	dw SndHdr6E ; $6E
	dw SndHdr6F ; $6F
	dw SndHdr70 ; $70
	dw SndHdr71 ; $71
	dw SndHdr72 ; $72
	dw SndHdr73 ; $73
	dw SndHdr74 ; $74
	dw SndHdr75 ; $75
	dw SndHdr76 ; $76
	dw SndHdr77 ; $77
	dw SndHdr78 ; $78
	dw SndHdr79 ; $79
	dw SndHdr7A ; $7A
	dw SndHdr7B ; $7B
	dw SndHdr7C ; $7C
	dw SndHdr7D ; $7D
	dw SndHdr7E ; $7E
	dw SndHdr7F ; $7F
	dw SndHdr80 ; $80
	dw SndHdr81 ; $81
	dw SndHdr82 ; $82
	dw SndHdr83 ; $83
	dw SndHdr84 ; $84
	dw SndHdr85 ; $85
	dw SndHdr86 ; $86
	dw SndHdr87 ; $87
	dw SndHdr88 ; $88
	dw SndHdr89 ; $89
	dw SndHdr8A ; $8A
	dw SndHdr8B ; $8B
	dw SndHdr8C ; $8C
	dw SndHdr8D ; $8D
	dw SndHdr8E ; $8E
	dw SndHdr8F ; $8F
	dw SndHdr90 ; $90

; Sound headers: priority, track mask, one stream pointer per set bit.

SndHdr2B:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr48:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr63:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd63_Sfx1

SndHdr7F:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd7F_SfxN

SndHdr29:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd29_SfxN

SndHdr31:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd31_Sfx1

SndHdr52:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd52_Sfx1
	dw Snd52_SfxN

SndHdr0E:
	SND_HEADER $40, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $48, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr6D:
	SND_HEADER $48, $01 ; tracks: Sfx1
	dw Snd6D_Sfx1

SndHdr10:
	SND_HEADER $48, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr3B:
	SND_HEADER $4A, $01 ; tracks: Sfx1
	dw Snd3B_Sfx1

SndHdr59:
	SND_HEADER $4C, $05 ; tracks: Sfx1, SfxN
	dw Snd59_Sfx1
	dw Snd59_SfxN

SndHdr28:
	SND_HEADER $50, $04 ; tracks: SfxN
	dw Snd28_SfxN

SndHdr8D:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd8D_Sfx1

SndHdr42:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr5E:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd5E_Sfx1

SndHdr5C:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd5C_Sfx1

SndHdr7D:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd7D_Sfx1

SndHdr1D:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr21:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr33:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr35:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd35_SfxN

SndHdr67:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd67_SfxN

SndHdr68:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd68_SfxN

SndHdr69:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd69_Sfx1

SndHdr6A:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd6A_SfxN

SndHdr6B:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd6B_SfxN

SndHdr3A:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3F:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr62:
	SND_HEADER $52, $05 ; tracks: Sfx1, SfxN
	dw Snd62_Sfx1
	dw Snd62_SfxN

SndHdr70:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd70_Sfx1

SndHdr71:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd71_SfxN

SndHdr72:
	SND_HEADER $52, $04 ; tracks: SfxN
	dw Snd72_SfxN

SndHdr64:
	SND_HEADER $52, $01 ; tracks: Sfx1
	dw Snd64_Sfx1

SndHdr65:
	SND_HEADER $53, $01 ; tracks: Sfx1
	dw Snd65_Sfx1

SndHdr55:
	SND_HEADER $53, $05 ; tracks: Sfx1, SfxN
	dw Snd55_Sfx1
	dw Snd55_SfxN

SndHdr34:
	SND_HEADER $54, $05 ; tracks: Sfx1, SfxN
	dw Snd34_Sfx1
	dw Snd34_SfxN

SndHdr2A:
	SND_HEADER $54, $05 ; tracks: Sfx1, SfxN
	dw Snd2A_Sfx1
	dw Snd2A_SfxN

SndHdr2E:
	SND_HEADER $56, $01 ; tracks: Sfx1
	dw Snd2E_Sfx1

SndHdr16:
	SND_HEADER $58, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr11:
	SND_HEADER $60, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $60, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr76:
	SND_HEADER $60, $01 ; tracks: Sfx1
	dw Snd76_Sfx1

SndHdr1C:
	SND_HEADER $60, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr5F:
	SND_HEADER $60, $01 ; tracks: Sfx1
	dw Snd5F_Sfx1

SndHdr25:
	SND_HEADER $61, $01 ; tracks: Sfx1
	dw Snd25_Sfx1

SndHdr1F:
	SND_HEADER $62, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr14:
	SND_HEADER $62, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr38:
	SND_HEADER $62, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr13:
	SND_HEADER $62, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr45:
	SND_HEADER $62, $01 ; tracks: Sfx1
	dw Snd45_Sfx1

SndHdr2D:
	SND_HEADER $64, $01 ; tracks: Sfx1
	dw Snd2D_Sfx1

SndHdr43:
	SND_HEADER $66, $01 ; tracks: Sfx1
	dw Snd43_Sfx1

SndHdr80:
	SND_HEADER $66, $05 ; tracks: Sfx1, SfxN
	dw Snd80_Sfx1
	dw Snd80_SfxN

SndHdr53:
	SND_HEADER $66, $04 ; tracks: SfxN
	dw Snd53_SfxN

SndHdr7E:
	SND_HEADER $68, $04 ; tracks: SfxN
	dw Snd7E_SfxN

SndHdr44:
	SND_HEADER $68, $01 ; tracks: Sfx1
	dw Snd44_Sfx1

SndHdr75:
	SND_HEADER $69, $01 ; tracks: Sfx1
	dw Snd75_Sfx1

SndHdr26:
	SND_HEADER $6A, $04 ; tracks: SfxN
	dw Snd26_SfxN

SndHdr20:
	SND_HEADER $6A, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr2C:
	SND_HEADER $6A, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr37:
	SND_HEADER $6C, $05 ; tracks: Sfx1, SfxN
	dw Snd37_Sfx1
	dw Snd37_SfxN

SndHdr58:
	SND_HEADER $6E, $01 ; tracks: Sfx1
	dw Snd58_Sfx1

SndHdr1A:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd1A_SfxN

SndHdr22:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr32:
	SND_HEADER $70, $04 ; tracks: SfxN
	dw Snd32_SfxN

SndHdr19:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr8C:
	SND_HEADER $72, $01 ; tracks: Sfx1
	dw Snd8C_Sfx1

SndHdr2F:
	SND_HEADER $76, $04 ; tracks: SfxN
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $76, $05 ; tracks: Sfx1, SfxN
	dw Snd30_Sfx1
	dw Snd30_SfxN

SndHdr85:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd85_Sfx1

SndHdr87:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd87_Sfx1

SndHdr86:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd86_Sfx1

SndHdr83:
	SND_HEADER $76, $03 ; tracks: Sfx1, Sfx2
	dw Snd83_Sfx1
	dw Snd83_Sfx2

SndHdr84:
	SND_HEADER $76, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd84_Sfx1
	dw Snd84_Sfx2
	dw Snd84_SfxN

SndHdr88:
	SND_HEADER $76, $7B ; tracks: Sfx1, Sfx2, Ch1, Ch2, Ch3, Drm
	dw Snd88_Sfx1
	dw Snd88_Sfx2
	dw Snd88_Ch1
	dw Snd88_Ch1
	dw Snd88_Ch1
	dw Snd88_Ch1

SndHdr3D:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $76, $04 ; tracks: SfxN
	dw Snd3E_SfxN

SndHdr3C:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd3C_Sfx1

SndHdr40:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr5B:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd5B_Sfx1

SndHdr4E:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd4E_Sfx1

SndHdr4F:
	SND_HEADER $76, $04 ; tracks: SfxN
	dw Snd4F_SfxN

SndHdr50:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd50_Sfx1

SndHdr51:
	SND_HEADER $76, $05 ; tracks: Sfx1, SfxN
	dw Snd51_Sfx1
	dw Snd51_SfxN

SndHdr8B:
	SND_HEADER $CF, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd8A_Sfx1
	dw Snd8B_Sfx2
	dw Snd32_SfxN
	dw Snd8B_Ch1
	dw Snd8B_Ch2
	dw Snd8B_Ch3
	dw Snd8B_Drm

SndHdr23:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr6C:
	SND_HEADER $78, $01 ; tracks: Sfx1
	dw Snd6C_Sfx1

SndHdr18:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr17:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr89:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd89_Sfx1

SndHdr8A:
	SND_HEADER $76, $01 ; tracks: Sfx1
	dw Snd8A_Sfx1

SndHdr54:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd54_Sfx1

SndHdr66:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd66_Sfx1

SndHdr60:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd60_Sfx1

SndHdr7B:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd7B_Sfx1

SndHdr56:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd56_Sfx1
	dw Snd56_SfxN

SndHdr7C:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd7C_SfxN

SndHdr36:
	SND_HEADER $A0, $7B ; tracks: Sfx1, Sfx2, Ch1, Ch2, Ch3, Drm
	dw Snd36_Sfx1
	dw Snd36_Sfx2
	dw Snd36_Ch1
	dw Snd36_Ch1
	dw Snd36_Ch1
	dw Snd36_Ch1

SndHdr74:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd74_SfxN

SndHdr78:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd78_SfxN

SndHdr79:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd79_SfxN

SndHdr73:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd73_Sfx1
	dw Snd73_SfxN

SndHdr81:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd81_Sfx1

SndHdr82:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd82_Sfx1

SndHdr4D:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd4D_Sfx1
	dw Snd4D_SfxN

SndHdr5A:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd5A_Sfx1
	dw Snd5A_SfxN

SndHdr49:
	SND_HEADER $A2, $03 ; tracks: Sfx1, Sfx2
	dw Snd49_Sfx1
	dw Snd49_Sfx2

SndHdr4A:
	SND_HEADER $A4, $04 ; tracks: SfxN
	dw Snd4A_SfxN

SndHdr5D:
	SND_HEADER $AC, $04 ; tracks: SfxN
	dw Snd5D_SfxN

SndHdr39:
	SND_HEADER $C0, $04 ; tracks: SfxN
	dw Snd39_SfxN

SndHdr6F:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd6F_Sfx1
	dw Snd6F_SfxN

SndHdr61:
	SND_HEADER $C2, $04 ; tracks: SfxN
	dw Snd61_SfxN

SndHdr4C:
	SND_HEADER $C6, $05 ; tracks: Sfx1, SfxN
	dw Snd4C_Sfx1
	dw Snd4C_SfxN

SndHdr4B:
	SND_HEADER $C6, $05 ; tracks: Sfx1, SfxN
	dw Snd4B_Sfx1
	dw Snd4B_SfxN

SndHdr46:
	SND_HEADER $C6, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd46_Sfx1
	dw Snd46_Sfx2
	dw Snd46_SfxN
	dw Snd46_Ch1
	dw Snd46_Ch1
	dw Snd46_Ch1
	dw Snd46_Ch1

SndHdr47:
	SND_HEADER $C6, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd46_Sfx1
	dw Snd46_Sfx2
	dw Snd46_SfxN

SndHdr7A:
	SND_HEADER $C6, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd7A_Sfx1
	dw Snd7A_Sfx1
	dw Snd7A_SfxN
	dw Snd7A_Sfx1
	dw Snd7A_Sfx1
	dw Snd7A_Sfx1
	dw Snd7A_Sfx1

SndHdr77:
	SND_HEADER $C8, $01 ; tracks: Sfx1
	dw Snd77_Sfx1

SndHdr6E:
	SND_HEADER $CA, $05 ; tracks: Sfx1, SfxN
	dw Snd6E_Sfx1
	dw Snd6E_SfxN

SndHdr41:
	SND_HEADER $CA, $05 ; tracks: Sfx1, SfxN
	dw Snd41_Sfx1
	dw Snd41_SfxN

SndHdr57:
	SND_HEADER $CD, $03 ; tracks: Sfx1, Sfx2
	dw Snd57_Sfx1
	dw Snd57_Sfx2

SndHdr1B:
	SND_HEADER $CD, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr27:
	SND_HEADER $D4, $04 ; tracks: SfxN
	dw Snd27_SfxN

SndHdr15:
	SND_HEADER $D8, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr8E:
	SND_HEADER $E0, $03 ; tracks: Sfx1, Sfx2
	dw Snd8E_Sfx1
	dw Snd8E_Sfx2

SndHdr8F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8F_Ch1
	dw Snd8F_Ch2
	dw Snd8F_Ch3
	dw Snd8F_Drm

SndHdr90:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd90_Ch1
	dw Snd90_Ch2
	dw Snd90_Ch3
	dw Snd90_Drm

; WaveTable: CH3 waves by duty >> 4 (the code adds from WaveTable - 2, whose first word is
; the end of SndHdr90).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData2 ; wave 2
	dw WaveData3 ; wave 3
	dw WaveData4 ; wave 4
	dw WaveData5 ; wave 5
	dw WaveData6 ; wave 6
	dw WaveData7 ; wave 7
	dw WaveData8 ; wave 8
	dw WaveData9 ; wave 9
	dw WaveData10 ; wave 10
	dw WaveData11 ; wave 11
	dw WaveData12 ; wave 12
	dw WaveData13 ; wave 13
	dw WaveData14 ; wave 14
	dw WaveData15 ; wave 15
WaveData1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
WaveData2:
	db $13, $57, $9B, $DF, $FD, $B9, $75, $31, $13, $57, $9B, $DF, $FD, $B9, $75, $31
WaveData3:
	db $11, $12, $22, $33, $34, $45, $57, $79, $9A, $BC, $DE, $FC, $86, $55, $44, $21
WaveData4:
	db $13, $57, $9B, $97, $53, $11, $35, $79, $BD, $FD, $B9, $75, $31, $13, $53, $10
WaveData5:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00
WaveData6:
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $11, $11, $22, $22, $33, $33, $44, $44, $55
WaveData7:
	db $13, $57, $9B, $DF, $FF, $EE, $DD, $CC, $BA, $A9, $98, $87, $65, $44, $32, $10
WaveData8:
	db $BB, $99, $99, $99, $99, $99, $AA, $CC, $00, $00, $00, $00, $00, $00, $00, $00
WaveData9:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData10:
	db $88, $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
WaveData11:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
WaveData12:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00
WaveData13:
	db $13, $57, $9B, $97, $53, $11, $35, $79, $BD, $FD, $B9, $75, $31, $13, $53, $10
WaveData14:
	db $89, $AB, $CD, $EF, $CD, $AB, $89, $67, $89, $AB, $CD, $EF, $CD, $AB, $89, $67
WaveData15:
	db $51, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $11

; PeriodTable: 85 periods from the B below octave 1's C (octave + 2 * pitch indexes from
; PeriodTable - 26). The last entry is also entry 0 of the vibrato table.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; VibratoTable: entries 1-22 (the code adds from VibratoTable - 2).
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib03 ; 3
	dw Vib04 ; 4
	dw Vib05 ; 5
	dw Vib06 ; 6
	dw Vib07 ; 7
	dw Vib08 ; 8
	dw Vib09 ; 9
	dw Vib0A ; 10
	dw Vib0B ; 11
	dw Vib0C ; 12
	dw Vib0D ; 13
	dw Vib0E ; 14
	dw Vib0F ; 15
	dw Vib10 ; 16
	dw Vib11 ; 17
	dw Vib12 ; 18
	dw Vib13 ; 19
	dw Vib14 ; 20
	dw Vib15 ; 21
	dw Vib16 ; 22

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
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib03:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 3
	VIB_STEP 3, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_MARK

Vib04:
	VIB_STEP 1, 0, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib05:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_END

Vib06:
	VIB_MARK
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib07:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_MARK

Vib08:
	VIB_STEP 1, 1, 2
	VIB_STEP 15, 0, 0
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 1
	VIB_MARK

Vib09:
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 0
	VIB_END

Vib0A:
	VIB_STEP 1, 1, 2
	VIB_STEP 15, 0, 0
	VIB_STEP 5, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 1
	VIB_MARK

Vib0B:
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib0C:
	VIB_STEP 1, 1, 2
	VIB_STEP 14, 0, 0
	VIB_STEP 10, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib0D:
	VIB_STEP 3, 0, 7
	VIB_STEP 3, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_END

Vib0E:
	VIB_STEP 1, 0, 7
	VIB_STEP 5, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib0F:
	VIB_STEP 1, 1, 1
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib10:
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 10, 0, 7
	VIB_STEP 15, 0, 7
	VIB_STEP 9, 0, 7
	VIB_STEP 4, 0, 6
	VIB_STEP 4, 0, 5
	VIB_STEP 4, 0, 4
	VIB_STEP 4, 0, 3
	VIB_STEP 4, 0, 2
	VIB_STEP 4, 0, 1

Vib11:
	VIB_MARK
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib12:
	VIB_STEP 2, 0, 0
	VIB_STEP 4, 1, 1
	VIB_STEP 3, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 7
	VIB_END

Vib13:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 2, 0, 2
	VIB_STEP 3, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib14:
	VIB_STEP 1, 0, 5
	VIB_STEP 14, 0, 0
	VIB_STEP 10, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib15:
	VIB_STEP 2, 0, 7
	VIB_STEP 5, 0, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 15, 1, 1
	VIB_STEP 15, 1, 2
	VIB_END

Vib16:
	VIB_MARK
	VIB_STEP 6, 0, 0
	VIB_STEP 6, 0, 1
	VIB_STEP 6, 0, 2
	VIB_STEP 6, 0, 1
	VIB_STEP 6, 0, 0
	VIB_STEP 6, 1, 1
	VIB_STEP 7, 1, 2
	VIB_STEP 6, 1, 1
	VIB_MARK

; EnvelopeTable: entries 1-21 (the code adds from EnvelopeTable - 2, whose first word is
; the end of a vibrato table).
EnvelopeTable:
	dw Env01 ; 1
	dw Env02 ; 2
	dw Env03 ; 3
	dw Env04 ; 4
	dw Env05 ; 5
	dw Env06 ; 6
	dw Env07 ; 7
	dw Env08 ; 8
	dw Env09 ; 9
	dw Env0A ; 10
	dw Env0B ; 11
	dw Env0C ; 12
	dw Env0D ; 13
	dw Env0E ; 14
	dw Env0F ; 15
	dw Env10 ; 16
	dw Env11 ; 17
	dw Env12 ; 18
	dw Env13 ; 19
	dw Env14 ; 20
	dw Env15 ; 21
Env01:
	ENV_STEP 5, 11
	ENV_STEP 5, 10
	ENV_STEP 5, 8
	ENV_STEP 5, 7
	ENV_STEP 5, 6
	ENV_STEP 5, 5
	ENV_STEP 5, 4
	ENV_STEP 9, 3
	ENV_STEP 9, 2
	ENV_STEP 7, 1
	ENV_STEP 7, 2
	ENV_STEP 7, 3
	ENV_STEP 7, 4
	ENV_STEP 7, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP 5, 8
	ENV_STEP 5, 9
	ENV_END
Env02:
	ENV_STEP 1, 11
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_STEP 1, 1
	ENV_END
Env03:
	ENV_STEP 1, 10
	ENV_STEP 2, 8
	ENV_STEP 1, 7
	ENV_STEP 2, 6
	ENV_STEP 2, 5
	ENV_STEP 3, 4
	ENV_STEP 5, 3
	ENV_STEP 3, 4
	ENV_STEP 3, 5
	ENV_STEP 3, 6
	ENV_STEP 3, 7
	ENV_STEP 3, 8
	ENV_END
Env04:
	ENV_STEP 2, 10
	ENV_STEP 2, 8
	ENV_STEP 2, 7
	ENV_STEP 3, 6
	ENV_STEP 7, 5
	ENV_STEP 9, 4
	ENV_STEP 9, 3
	ENV_STEP 9, 2
	ENV_END
Env05:
	ENV_STEP 1, 7
	ENV_STEP 1, 8
	ENV_STEP 3, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 3, 3
	ENV_END
Env06:
	ENV_STEP 1, 9
	ENV_STEP 4, 8
	ENV_STEP 5, 2
	ENV_STEP 1, 6
	ENV_STEP 4, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 1
	ENV_END
Env07:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 8, 8
	ENV_STEP 8, 7
	ENV_STEP 8, 6
	ENV_STEP 8, 5
	ENV_STEP 8, 4
	ENV_STEP 8, 3
	ENV_STEP 8, 2
	ENV_STEP 7, 1
	ENV_STEP 9, 2
	ENV_STEP 9, 3
	ENV_STEP 9, 4
	ENV_STEP 9, 5
	ENV_STEP 9, 6
	ENV_STEP 9, 7
	ENV_STEP 9, 8
	ENV_STEP 9, 7
	ENV_STEP 9, 6
	ENV_STEP 9, 5
	ENV_STEP 9, 4
	ENV_STEP 9, 3
	ENV_END
Env08:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 8, 8
	ENV_STEP 8, 7
	ENV_STEP 8, 6
	ENV_STEP 8, 5
	ENV_STEP 5, 4
	ENV_STEP 5, 3
	ENV_STEP 5, 2
	ENV_STEP 5, 3
	ENV_STEP 5, 4
	ENV_STEP 5, 5
	ENV_STEP 5, 6
	ENV_STEP 9, 7
	ENV_STEP 9, 8
	ENV_STEP 9, 7
	ENV_STEP 9, 6
	ENV_STEP 9, 5
	ENV_STEP 9, 4
	ENV_STEP 9, 3
	ENV_END
Env09:
	ENV_STEP 1, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 4, 4
	ENV_STEP 4, 3
	ENV_STEP 4, 2
	ENV_STEP 4, 1
	ENV_END
Env0A:
	ENV_STEP 1, 10
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 4, 3
	ENV_STEP 4, 4
	ENV_STEP 4, 5
	ENV_STEP 4, 6
	ENV_STEP 4, 7
	ENV_STEP 4, 8
	ENV_END
Env0B:
	ENV_STEP 3, 11
	ENV_STEP 3, 10
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 4, 5
	ENV_STEP 4, 4
	ENV_STEP 4, 3
	ENV_STEP 8, 2
	ENV_STEP 8, 1
	ENV_STEP 4, 2
	ENV_STEP 7, 3
	ENV_STEP 4, 4
	ENV_STEP 4, 5
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 1, 8
	ENV_STEP 1, 9
	ENV_END
Env0C:
	ENV_STEP 1, 10
	ENV_STEP 1, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 6, 5
	ENV_STEP 6, 4
	ENV_STEP 6, 3
	ENV_STEP 6, 2
	ENV_END
Env0D:
	ENV_STEP 1, 10
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 6, 3
	ENV_STEP 6, 4
	ENV_STEP 6, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP 6, 8
	ENV_END
Env0E:
	ENV_STEP 1, 9
	ENV_STEP 4, 8
	ENV_STEP 5, 2
	ENV_STEP 1, 6
	ENV_STEP 4, 5
	ENV_STEP 2, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 1
	ENV_STEP 4, 3
	ENV_STEP 3, 2
	ENV_STEP 2, 1
	ENV_END
Env0F:
	ENV_STEP 1, 11
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 7, 8
	ENV_STEP 7, 7
	ENV_STEP 7, 6
	ENV_STEP 7, 5
	ENV_STEP 7, 4
	ENV_STEP 7, 3
	ENV_STEP 7, 2
	ENV_STEP 7, 1
	ENV_END
Env10:
	ENV_STEP 1, 3
	ENV_STEP 1, 4
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 3, 3
	ENV_STEP 3, 2
	ENV_STEP 3, 1
	ENV_END
Env11:
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 1, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 3, 3
	ENV_END
Env12:
	ENV_STEP 1, 9
	ENV_STEP 4, 8
	ENV_STEP 5, 2
	ENV_STEP 1, 6
	ENV_STEP 4, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 1
	ENV_END
Env13:
	ENV_STEP 1, 10
	ENV_STEP 1, 8
	ENV_STEP 3, 7
	ENV_STEP 4, 6
	ENV_STEP 4, 5
	ENV_STEP 4, 4
	ENV_STEP 4, 3
	ENV_STEP 4, 2
	ENV_END
Env14:
	ENV_STEP 1, 11
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 3, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_STEP 1, 1
	ENV_END
Env15:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 7, 8
	ENV_STEP 7, 7
	ENV_STEP 7, 6
	ENV_STEP 8, 5
	ENV_STEP 8, 4
	ENV_STEP 8, 3
	ENV_STEP 8, 2
	ENV_STEP 9, 1
	ENV_STEP 9, 2
	ENV_STEP 9, 3
	ENV_STEP 9, 4
	ENV_STEP 8, 5
	ENV_STEP 9, 6
	ENV_STEP 9, 5
	ENV_STEP 10, 4
	ENV_STEP 10, 3
	ENV_STEP 10, 2
	ENV_STEP 10, 1
	ENV_END

; Drum hits $01-$0D: headers, then their streams.

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
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd06_Sfx2
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd08_Sfx2
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd09_Sfx2
	dw Snd08_SfxN

SndHdr0A:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0B_SfxN

Snd01_SfxN:
	NVOICE $04, $73
	NOISE $07
	NOISE $02
	NOISE $10
	SND_END

Snd02_SfxN:
	NVOICE $04, $34
	NOISE $07
	NOISE $02
	NOISE $10
	SND_END

Snd03_SfxN:
	NVOICE $03, $70
	NOISE $06
	NVOICE $18, $47
	NOISE $02
	SND_END

Snd04_SfxN:
	NVOICE $01, $C0
	NOISE $44
	NOISE $26
	NOISE $15
	NOISE $43
	NVOICE $1A, $81
	NOISE $26
	SND_END

Snd05_SfxN:
	NVOICE $01, $90
	NOISE $44
	NOISE $26
	NOISE $15
	NOISE $43
	NVOICE $1B, $61
	NOISE $26
	SND_END

Snd06_Sfx2:
	VOICE $02, 15, 2, 0, 0
	OCTAVE 3
	NOTE C_, 1
	SND_END

Snd06_SfxN:
	NVOICE $02, $C0
	NOISE $33
	NOISE $8A
	NOISE $15
	NOISE $35
	NVOICE $18, $67
	NOISE $32
	SND_END

Snd07_SfxN:
	NVOICE $01, $F6
	NOISE $45
	NOISE $6A
	NOISE $33
	NVOICE $02, $F0
	NOISE $73
	NOISE $34
	LOOP_START
	NVOICE $04, $70
	NOISE $17
	NOISE_REST
	LOOP_END 3
	LOOP_START
	NVOICE $04, $60
	NOISE $17
	NOISE_REST
	LOOP_END 3
	LOOP_START
	NVOICE $04, $50
	NOISE $17
	NOISE_REST
	LOOP_END 3
	LOOP_START
	NVOICE $04, $40
	NOISE $17
	NOISE_REST
	LOOP_END 3
	LOOP_START
	NVOICE $04, $30
	NOISE $17
	NOISE_REST
	LOOP_END 3
	LOOP_START
	NVOICE $04, $20
	NOISE $17
	NOISE_REST
	LOOP_END 5
	SND_END

Snd08_Sfx2:
	VOICE $08, 8, 4, 13, 13
	VIBRATO $15, 0, 4
	OCTAVE 5
	NOTE B_, 4
	SND_END

Snd08_SfxN:
	NVOICE $02, $A0
	NOISE $43
	NOISE $16
	NOISE $82
	NVOICE $13, $2D
	NOISE $11
	SND_END

Snd09_Sfx2:
	VOICE $09, 8, 4, 13, 13
	VIBRATO $15, 0, 7
	OCTAVE 5
	NOTE C_, 4
	SND_END

Snd0A_SfxN:
	NVOICE $08, $F7
	NOISE $18
	NVOICE $10, $57
	NOISE $18
	SND_END

Snd0B_SfxN:
	NVOICE $01, $A0
	NOISE $45
	NOISE $23
	NVOICE $10, $44
	NOISE $76
	SND_END

; TrackTick: one tick for track H with descriptor wTrackDesc.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, .l489B
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call WriteDuty
.l489B:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

; ReadCmds: every byte comes through FarRead (wReadBuf = the next 4 bytes). Notes: length =
; lo * unit (lo = 0: (unit & 15) * 16), release tick = length * gate / 16. Pitch 13 plays
; the previous note's pitch one octave higher. The volume is TRK_VOL - TRK_ATTEN (8 = off
; on a borrow) minus the fade (CH3: plus, 0 from $70), or the envelope's first step.
ReadCmds:
	call FarRead
	ld a, [wReadBuf]
	cp $E0
	jp nc, Command
	ld l, TRK_FLAGS
	bit 1, [hl]
	jp nz, RawNote
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote
	res 2, [hl]
	call SavePtr
	ld a, [wReadBuf]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l48E2
	ld b, a
	xor a
	bit 0, b
	jp nz, .l48EA
	rrc b
.l48D9:
	add a, c
	dec b
	jp nz, .l48D9
	add a, a
	jp .l48EF
.l48E2:
	swap c
	ld a, c
	and $F0
	jp .l48EF
.l48EA:
	add a, c
	dec b
	jp nz, .l48EA
.l48EF:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [wReadBuf]
	and $F0
	jp nz, .l4902
	set 0, [hl]
	ld a, $08
	jp WriteVolume
.l4902:
	res 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jp z, .l4926
	ld e, a
	ld b, $00
	ld hl, $0000
.l491B:
	add hl, bc
	dec e
	jp nz, .l491B
	ld a, l
	and $F0
	or h
	swap a
.l4926:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l4937
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l4937:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld a, [wReadBuf]
	and $F0
	cp $D0
	jp nz, .l4954
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, TRK_LASTPITCH
	ld a, [hl]
	jp .l495D
.l4954:
	swap a
	rlca
	ld l, TRK_LASTPITCH
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l495D:
	add a, c
	ld l, TRK_TRANSP
	ld c, [hl]
	add a, c
	ld c, a
	ld b, $00
	push hl
	ld hl, PeriodTable - 26
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl+]
	or a
	jp z, .l497D
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l497D:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l49A5
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
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
.l49A5:
	call WritePeriod
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, .l49C4
	ld l, TRK_FLOW
	res 6, [hl]
	res 7, [hl]
	ld l, TRK_PANFLAGS
	set 3, [hl]
	ld l, TRK_ENVPTR
	ld a, [hl+]
	ld b, [hl]
	inc l
	ld [hl+], a
	ld [hl], b
	ld c, a
	jp EnvelopeStep
.l49C4:
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	jp c, .l49F7
	ld b, a
	ld a, [wFadeRate]
	or a
	ld a, b
	jp z, WriteVolume
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeLevel]
	ld c, a
	ld a, b
	jp nz, .l49F3
	add a, c
	jp c, .l49EE
	cp $70
	jp c, WriteVolume
.l49EE:
	ld a, $00
	jp WriteVolume
.l49F3:
	sub c
	jp nc, WriteVolume
.l49F7:
	ld a, $08
	jp WriteVolume

; Sustain: duty step (back to the voice duty after TRK_DUTYTICKS ticks), vibrato, then
; either the envelope (the release is skipped while it runs) or the release (NRx2 =
; TRK_ENV | level + retrigger; env 0 = cut), CH3 decay one level every TRK_ENV ticks, and
; the retrigger of a long note (>= 128 ticks left) after an SFX gave the channel back.
Sustain:
	ld l, TRK_FLAGS
	bit 1, [hl]
	ret nz
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
	jp z, .l4A20
	dec [hl]
	jp nz, .l4A20
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l4A20:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, SustainEnvelope
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, SustainEnvelope
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	or a
	jp z, .l4A39
	dec [hl]
	jp SustainEnvelope
.l4A39:
	ld l, TRK_VIBTIMER
	dec [hl]
	jp nz, SustainEnvelope
	ld l, TRK_VIBCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	call WritePeriod

SustainEnvelope:
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, SustainRelease
	ld l, TRK_PANFLAGS
	bit 3, [hl]
	jp z, SustainRelease
	ld l, TRK_ENVTIMER
	dec [hl]
	ret nz
	ld l, TRK_ENVCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	jp EnvelopeStep

; VibratoStep: one byte per step: time << 4 | negative << 3 | offset, offset x depth
; added to TRK_PERIOD. $FB loop markers, $FE mark/jump, $FF ends the vibrato.
VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, VibEnd
	cp $FE
	jp z, VibMark
	cp $FB
	jp z, VibLoop
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
	jp z, VibBase
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l4A9B
	and $07
	jp z, VibBase
	cpl
	inc a
	ld e, a
	ld d, $FF
.l4A9B:
	ld a, [hl]
	or a
	jp z, .l4AA8
	ld b, a
	xor a
.l4AA2:
	add a, e
	dec b
	jp nz, .l4AA2
	ld e, a
.l4AA8:
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

VibBase:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

VibEnd:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

VibLoop:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l4AD8
	set 4, [hl]
	ld l, TRK_VIBLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l4AD8:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l4AE7
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l4AE7:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep

VibMark:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l4B03
	set 5, [hl]
	inc bc
	ld l, TRK_VIBSEGNO
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l4B03:
	ld l, TRK_VIBSEGNO
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

; EnvelopeStep: one byte per step: time << 4 | volume. The level is volume << 4 -
; TRK_ATTEN (8 = off on a borrow), with the fade as for notes. $FB loop markers, $FE
; mark/jump, $FF ends the envelope (the level stays, the release logic takes over).
EnvelopeStep:
	ld a, [bc]
	cp $FF
	jp z, EnvEnd
	cp $FE
	jp z, EnvMark
	cp $FB
	jp z, EnvLoop
	ld l, TRK_ENVTIMER
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, TRK_ENVCUR
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	swap a
	ld l, TRK_ATTEN
	sub [hl]
	jp c, .l4B5D
	ld b, a
	ld a, [wFadeRate]
	or a
	ld a, b
	jp z, WriteVolume
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeLevel]
	ld c, a
	ld a, b
	jp nz, .l4B59
	add a, c
	jp c, .l4B54
	cp $70
	jp c, WriteVolume
.l4B54:
	ld a, $00
	jp WriteVolume
.l4B59:
	sub c
	jp nc, WriteVolume
.l4B5D:
	ld a, $08
	jp WriteVolume

EnvEnd:
	ld l, TRK_PANFLAGS
	res 3, [hl]
	ret

EnvLoop:
	ld l, TRK_FLOW
	inc bc
	bit 6, [hl]
	jp nz, .l4B7C
	set 6, [hl]
	ld l, TRK_ENVLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp EnvelopeStep
.l4B7C:
	ld a, [bc]
	ld l, TRK_ENVLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l4B8B
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp EnvelopeStep
.l4B8B:
	ld [hl], $00
	ld l, TRK_FLOW
	res 6, [hl]
	inc bc
	jp EnvelopeStep

EnvMark:
	ld l, TRK_FLOW
	bit 7, [hl]
	jp nz, .l4BA7
	set 7, [hl]
	inc bc
	ld l, TRK_ENVSEGNO
	ld [hl], c
	inc l
	ld [hl], b
	jp EnvelopeStep
.l4BA7:
	ld l, TRK_ENVSEGNO
	ld c, [hl]
	inc l
	ld b, [hl]
	jp EnvelopeStep

SustainRelease:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, Ch3Release
	cp [hl]
	jp z, ReleasePoint
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp WriteVolume

ReleasePoint:
	inc l
	ld a, [hl]
	or a
	jp z, .l4BEF
	ld b, a
	ld l, TRK_LEVEL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret
.l4BEF:
	ld a, $08
	jp WriteVolume

Ch3Release:
	cp [hl]
	inc hl
	jp c, Ch3Decay
	jp z, .l4C0C
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp WriteVolume
.l4C0C:
	ld a, [hl+]
	ld [hl], a
	ret

Ch3Decay:
	ld a, [hl+]
	or a
	jp z, WriteVolume
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LEVEL
	ld a, [hl]
	and $7F
	or a
	ret z
	add a, $20
	cp $A0
	ret nc
	jp WriteVolume

Rest:
	call SavePtr
	ld a, $08
	jp WriteVolume

; DrumNote: start sound (hi nibble) of bank 14 on the SFX tracks it uses, each with its
; own priority test, whatever bank the song is in.
DrumNote:
	ld a, [wReadBuf]
	and $F0
	swap a
	ld [wReqId], a
	ld hl, SND_TABLE - 2
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, StartDrumTrack
	srl b
	ld hl, wTrkSfx2
	call c, StartDrumTrack
	srl b
	ld hl, wTrkSfxN
	ret nc

StartDrumTrack:
	ld a, [wReqPrio]
	cp [hl]
	jp c, SkipDrumTrack
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
	ld [hl+], a
	ld l, TRK_RAWVOL
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld [wWaveId], a
	ld l, TRK_REG2
	ld c, [hl]
	ldh [c], a
	ld a, $D0
	cp h
	jp nz, .l4C96
	ld a, $08
	ld c, $10
	ldh [c], a
.l4C96:
	ld a, $D2
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

SkipDrumTrack:
	inc de
	inc de
	ret

; RawNote: frame vol << 4 | period >> 8, period & $FF for one unit; TRK_RAWOFS is added
; to the period and swap(TRK_RAWVOL) to the level. In slide mode a frame is count, flags,
; delta: for count units the period moves by delta and the level by the flags' volume.
RawNoteBack:
	dec de

RawNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [wReadBuf]
	or a
	jp z, Rest
	ld b, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	jp nz, SlideFrame
	and $F0
	push af
	ld a, [wReadBuf]
	and $0F
	inc de
	ld c, a
	ld a, [wReadBuf + $01]
	call SavePtr
	ld d, c
	ld e, a
	push hl
	ld l, TRK_RAWOFS
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
	call WritePeriod
	pop af
	ld l, TRK_RAWVOL
	ld c, [hl]
	swap c
	add a, c
	and $F0
	jp WriteVolume

SlideFrame:
	ld l, TRK_SLIDECNT
	ld a, [hl]
	or a
	jp nz, .l4D22
	dec de
	call SavePtr
	ld l, TRK_SLIDECNT
	ld [hl], b
	ld l, TRK_SLIDEVOL
	ld a, [wReadBuf + $01]
	ld b, a
	and $0F
	swap a
	bit 4, b
	jp z, .l4D0A
	cpl
	inc a
.l4D0A:
	ld [hl], a
	ld l, TRK_SLIDEDELTA + 1
	ld a, [wReadBuf + $02]
	bit 7, b
	jp z, .l4D1C
	cpl
	inc a
	ld [hl], $FF
	jp .l4D1E
.l4D1C:
	ld [hl], $00
.l4D1E:
	dec l
	ld [hl], a
	ld l, TRK_SLIDECNT
.l4D22:
	dec [hl]
	jp nz, SlideApply
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	inc de
	inc de
	call SavePtr

SlideApply:
	ld l, TRK_CURPERIOD
	ld c, [hl]
	inc l
	ld b, [hl]
	ld l, TRK_SLIDEDELTA
	ld e, [hl]
	inc l
	push hl
	ld h, [hl]
	ld l, e
	add hl, bc
	ld e, l
	ld d, h
	pop hl
	call WritePeriod
	ld l, TRK_LEVEL
	ld a, [hl]
	ld l, TRK_SLIDEVOL
	add a, [hl]
	jp WriteVolume

NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [wReadBuf]
	or a
	jp z, Rest
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, NoiseNoteHold
	call SavePtr
	ld e, a
	ld d, $00
	jp WritePeriod

NoiseNoteHold:
	and $0F
	swap a
	push af
	inc de
	ld a, [wReadBuf + $01]
	call SavePtr
	ld e, a
	ld d, $00
	call WritePeriod
	pop af
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	ret z
	ld a, [hl]
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; Command: $E0 voice; in raw mode $E1-$E6 and $F0-$F7 are raw frames and $EB-$EE are
; slide on, slide off, mark and repeat; $E1-$E6 octave; $E7-$FF through the table
; (the argument in A).
Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
	ld l, TRK_FLAGS
	bit 1, [hl]
	jp nz, CommandRaw
	cp $07
	jp c, Cmd_Octave
	push hl
	ld hl, CommandTable - 14
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
CommandTable:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_Envelope
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
	dw Cmd_JumpOn
	dw Cmd_Jump
	dw Cmd_Loop
	dw Cmd_Loop2
	dw Cmd_Call
	dw Cmd_Segno
	dw Cmd_End

CommandRaw:
	cp $07
	jp c, RawNoteBack
	push hl
	ld hl, CommandTableRaw - 14
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
CommandTableRaw:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Raw_SlideOn
	dw Raw_SlideOff
	dw Raw_Mark
	dw Raw_Repeat
	dw Cmd_Detune
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw RawAtten
	dw Cmd_Volume
	dw Cmd_JumpOn
	dw Cmd_Jump
	dw Cmd_Loop
	dw Cmd_Loop2
	dw Cmd_Call
	dw Cmd_Segno
	dw Cmd_End

Cmd_Voice:
	ld a, [wReadBuf + $01]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wReadBuf + $01]
	ld l, TRK_FLAGS
	bit 7, a
	inc de
	jp nz, VoiceRaw
	ld a, [wTrackDesc]
	cp $63
	jp nz, VoiceTone
	res 3, [hl]
	ld a, [wReadBuf + $02]
	call WriteNoiseVolume
	inc de
	jp ReadCmds

VoiceTone:
	res 1, [hl]
	ld a, [wReadBuf + $02]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [wReadBuf + $02]
	and $0F
	swap a
	ld l, TRK_VOL
	ld [hl], a
	inc de
	ld a, [wReadBuf + $03]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [wReadBuf + $03]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call PanBoth
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_ENVNO
	ld [hl], a
	inc de
	jp ReadCmds

VoiceRaw:
	ld a, [wTrackDesc]
	cp $63
	jp nz, VoiceRawTone
	set 3, [hl]
	jp ReadCmds

VoiceRawTone:
	set 1, [hl]
	ld a, [wReadBuf + $02]
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	ld a, [wTrackDesc]
	and $0F
	jp nz, .l4EA8
	ld c, $10
	ld a, [wReadBuf + $03]
	ldh [c], a
.l4EA8:
	call PanBoth
	inc de
	jp ReadCmds

RawAtten:
	pop hl
	jp RawNoteBack

Cmd_Octave:
	ld c, a
	ld b, $00
	push hl
	ld hl, OctaveTable - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	jp ReadCmds
OctaveTable:
	db $18, $30, $48, $60, $78, $90

Cmd_LenUnit:
	pop hl
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Release:
	pop hl
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [wReadBuf + $01]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	inc de
	jp ReadCmds

Cmd_Ext:
	swap a
	and $0F
	ld hl, ExtTable
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
ExtTable:
	dw Ext_Duty
	dw Ext_PanBoth
	dw Ext_PanRight
	dw Ext_PanLeft
	dw Ext_AutopanR
	dw Ext_AutopanL
	dw Ext_AutopanOff
	dw Ext_TransposeUp
	dw Ext_TransposeDown

Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	jp ReadCmds

Ext_PanBoth:
	pop hl
	call PanBoth
	inc de
	jp ReadCmds

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4F35
.l4F2F:
	sla b
	dec a
	jp nz, .l4F2F
.l4F35:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp WriteRegChecked

Ext_PanRight:
	pop hl
	call PanRight
	inc de
	jp ReadCmds

Ext_PanLeft:
	pop hl
	call PanLeft
	inc de
	jp ReadCmds

AutoPan:
	bit 1, [hl]
	jp nz, .l4F59
	set 1, [hl]
	jp PanLeft
.l4F59:
	res 1, [hl]

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4F70
.l4F68:
	rlc b
	rlc l
	dec a
	jp nz, .l4F68
.l4F70:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4F91
.l4F89:
	rlc b
	rlc l
	dec a
	jp nz, .l4F89
.l4F91:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked

Ext_AutopanR:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 1, [hl]
	inc de
	jp ReadCmds

Ext_AutopanL:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	res 1, [hl]
	inc de
	jp ReadCmds

Ext_AutopanOff:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	inc de
	jp ReadCmds

Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp ReadCmds

Ext_TransposeDown:
	pop hl
	and $0F
	jp z, .l4FD3
	rlca
	cpl
	inc a
.l4FD3:
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l5022
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
	ld a, [wReadBuf + $02]
	and $F0
	swap a
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l5018
	ld b, a
	xor a
	bit 0, b
	jp nz, .l5013
	rrc b
.l500A:
	add a, c
	dec b
	jp nz, .l500A
	add a, a
	jp .l5018
.l5013:
	add a, c
	dec b
	jp nz, .l5013
.l5018:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [wReadBuf + $02]
	and $0F
	inc l
	ld [hl], a
.l5022:
	inc de
	jp ReadCmds

Cmd_Envelope:
	pop hl
	ld l, TRK_ENVNO
	ld [hl], a
	or a
	jp z, .l503D
	push hl
	ld hl, EnvelopeTable - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_ENVPTR
	ld [hl], c
	inc l
	ld [hl], b
.l503D:
	inc de
	jp ReadCmds

Raw_SlideOn:
	pop hl
	ld l, TRK_FLAGS
	set 6, [hl]
	ld l, TRK_SLIDECNT
	ld [hl], $00
	jp ReadCmds

Raw_SlideOff:
	pop hl
	ld l, TRK_FLAGS
	res 6, [hl]
	jp ReadCmds

Cmd_DutyStep:
	pop hl
	and $F0
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld a, [wReadBuf + $01]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, WriteDuty
	inc de
	jp ReadCmds

Raw_Mark:
	pop hl
	ld l, TRK_RAWMARK
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_SLIDECNT
	xor a
	ld [hl], a
	jp ReadCmds

Raw_Repeat:
	pop hl
	ld l, TRK_SLIDECNT
	inc [hl]
	cp [hl]
	jp z, .l50AD
	inc de
	ld l, TRK_RAWVOL
	ld a, [wReadBuf + $02]
	add a, [hl]
	ld [hl], a
	inc de
	ld l, TRK_RAWOFS
	ld a, [wReadBuf + $03]
	bit 7, a
	ld c, a
	ld b, $00
	jp z, .l509A
	ld b, $FF
.l509A:
	push hl
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld c, l
	ld b, h
	pop hl
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_RAWMARK
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds
.l50AD:
	xor a
	ld l, TRK_RAWVOL
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	inc de
	inc de
	inc de
	jp ReadCmds

Cmd_Tempo:
	pop hl
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	inc de
	jp ReadCmds

Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l50D2
	ld a, $FF
.l50D2:
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Atten:
	pop hl
	dec de
	ld a, [wReadBuf]
	and $0F
	swap a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	ld b, a
	ld a, [wTrackDesc]
	cp $63
	jp nz, .l5104
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, .l5108
	ld a, b
	call WriteNoiseVolume
	jp .l5108
.l5104:
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
.l5108:
	inc de
	jp ReadCmds

; $F9 n addr: TRK_JUMPCNT + 1; on the n-th pass reset it and jump, else go on.
Cmd_JumpOn:
	pop hl
	ld l, TRK_JUMPCNT
	inc [hl]
	cp [hl]
	inc de
	jp z, .l511A
	inc de
	inc de
	jp ReadCmds
.l511A:
	xor a
	ld [hl], a
	ld a, [wReadBuf + $02]
	inc de
	ld c, a
	ld a, [wReadBuf + $03]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [wReadBuf + $02]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l5149
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l5149:
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l5157
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5157:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp ReadCmds

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l5176
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l5176:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l5184
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5184:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp ReadCmds

Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l51A8
	set 2, [hl]
	inc de
	ld c, a
	ld a, [wReadBuf + $02]
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, a
	jp ReadCmds
.l51A8:
	res 2, [hl]
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	bit 3, [hl]
	jp nz, .l51C4
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l51C4:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; $FF: end. Sfx1/Sfx2 ending give CH1/CH3 back to the music; id $8E only silences.
Cmd_End:
	pop hl
	xor a
	ld l, TRK_ID
	ld a, [hl]
	cp $8E
	ld a, $00
	ld [hl-], a
	ld [hl], a
	jp z, Silence
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, EndSfx2
	cp $40
	jp z, EndSfx1
	cp $63
	jp nz, Silence
	ld l, TRK_FLAGS
	res 3, [hl]
	jp Silence

EndSfx1:
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
	call nz, RestoreMusic
	pop hl
	jp Silence

EndSfx2:
	ld l, TRK_FLAGS
	res 1, [hl]
	push hl
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, RestoreMusic
	pop hl
	jp Silence

SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

RestoreMusic:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l523C
.l5236:
	rlc b
	dec a
	jp nz, .l5236
.l523C:
	ld c, $25
	ldh a, [c]
	and b
	ld l, TRK_PAN
	or [hl]
	ldh [c], a
	ld l, TRK_CURPERIOD
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
	ld l, TRK_CURPERIOD
	ld [hl], e
	inc l
	ld a, d
	and $07
	ld [hl], a
	ld l, TRK_REG3
	ld c, [hl]
	ld a, e
	call WriteRegChecked
	ret nc
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

Silence:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, SilenceCh3
	ld a, $08
	ld l, TRK_REG2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ret

SilenceCh3:
	xor a
	ld c, $1C
	jp WriteRegChecked

; WriteVolume: NRx2 = A, compared with what the register reads back: unchanged means
; no write and no retrigger (except on CH1 while NR10 is not 8). CH3 is never
; retriggered here.
WriteVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, .l52AC
	ld a, [wTrackDesc]
	and $0F
	ret nz
	ld c, $10
	ldh a, [c]
	and $7F
	cp $08
	ret z
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
.l52AC:
	ld a, [hl]
	call WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

WriteNoiseVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteDuty: NRx1, or on CH3 load wave (A >> 4) unless it is already loaded (music Ch3
; keeps the duty but loads nothing while Sfx2 plays).
WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, WriteDutyCh3
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld l, TRK_REG1
	ld c, [hl]
	jp WriteRegChecked

WriteDutyCh3:
	ld a, [wTrackDesc]
	cp $22
	jp nz, LoadWave
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_CURDUTY
	ld [hl], b
	ret nz

LoadWave:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld [wWaveId], a
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
.l531B:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l531B
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteRegChecked: music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2
; plays; carry = written.
WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l5351
	cp $22
	jp nz, .l535D
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
.l5351:
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
.l535D:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: clear all tracks' priority/id, mute every channel, NR51 = $FF.
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

Snd8E_Sfx1:
	VOICE $12, 8, 5, 0, 0
	DETUNE $FF
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 3
	SND_END

Snd8E_Sfx2:
	VOICE $12, 5, 2, 0, 0
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 4
	SND_END

Snd0E_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 3, $700
	RAW_REPEAT 8, $01, $10
	RAW_NOTE 11, $778
	RAW_NOTE 12, $780
	RAW_NOTE 13, $788
	RAW_NOTE 10, $790
	RAW_NOTE 11, $798
	RAW_NOTE 11, $7A0
	RAW_NOTE 12, $7A8
	RAW_NOTE 12, $7B0
	RAW_NOTE 13, $7B4
	RAW_NOTE 13, $7B8
	RAW_NOTE 15, $7BC
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C2
	RAW_NOTE 15, $7C4
	RAW_NOTE 15, $7C8
	RAW_NOTE 15, $7CA
	RAW_NOTE 12, $7CC
	RAW_NOTE 12, $7CE
	RAW_NOTE 11, $7E0
	RAW_NOTE 11, $7E0
	RAW_NOTE 10, $7D0
	RAW_NOTE 9, $7C0
	RAW_NOTE 8, $7B0
	RAW_NOTE 7, $7A0
	RAW_NOTE 6, $780
	RAW_NOTE 5, $740
	RAW_NOTE 4, $700
	RAW_MARK
	RAW_NOTE 12, $7C0
	RAW_REPEAT 6, $FE, $04
	SND_END

Snd0F_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $708
	RAW_NOTE 15, $710
	RAW_MARK
	RAW_NOTE 15, $718
	RAW_REPEAT 15, $FF, $08
	LEN_UNIT 2
	RAW_MARK
	RAW_NOTE 15, $780
	RAW_REPEAT 14, $FF, $00
	SND_END

Snd10_Sfx1:
	RAW_VOICE $01, $C0, $08
	RAW_MARK
	RAW_NOTE 4, $7E0
	RAW_REPEAT 5, $02, $F8
	RAW_MARK
	RAW_NOTE 15, $7B8
	RAW_REPEAT 12, $FF, $F8
	RAW_MARK
	RAW_NOTE 15, $7A0
	RAW_REPEAT 8, $00, $02
	RAW_NOTE 13, $7B0
	RAW_NOTE 13, $7B2
	RAW_NOTE 13, $7B4
	RAW_NOTE 13, $7B6
	RAW_NOTE 12, $7B8
	RAW_NOTE 12, $7BA
	RAW_NOTE 12, $7BC
	RAW_NOTE 11, $7BE
	RAW_NOTE 11, $7C0
	RAW_NOTE 11, $7C2
	RAW_NOTE 10, $7C4
	RAW_MARK
	RAW_NOTE 10, $7C6
	RAW_REPEAT 8, $FF, $02
	RAW_NOTE 3, $7D6
	RAW_NOTE 3, $7D8
	RAW_NOTE 2, $7DA
	RAW_NOTE 2, $7DC
	RAW_NOTE 1, $7DE
	SND_END

Snd11_Sfx1:
	RAW_VOICE $10, $C0, $08
	RAW_NOTE 13, $7E0
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $7C0
	RAW_NOTE 12, $7D0
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $7E0
	RAW_NOTE 12, $7D0
	LEN_UNIT 6
	DUTY 0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C2
	RAW_NOTE 15, $7C4
	RAW_MARK
	RAW_NOTE 13, $7C6
	RAW_REPEAT 13, $FF, $02
	SND_END

Snd12_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 15, $700
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	LEN_UNIT 2
	RAW_NOTE 12, $6FC
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 10, $7BC
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 10, $6F8
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 8, $7B8
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	LEN_UNIT 3
	RAW_NOTE 8, $6F4
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 6, $7B4
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 6, $6F0
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 4, $7B0
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	LEN_UNIT 4
	RAW_NOTE 4, $6EC
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 2, $7AC
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 2, $6E8
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 1, $7A8
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	SND_END

Snd13_Sfx1:
	RAW_VOICE $01, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $6C8
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6B8
	RAW_NOTE 15, $6B0
	RAW_REPEAT 4, $FE, $E0
	RAW_NOTE 7, $640
	RAW_NOTE 7, $648
	RAW_NOTE 7, $650
	RAW_NOTE 7, $658
	RAW_NOTE 8, $660
	RAW_NOTE 8, $668
	RAW_NOTE 8, $670
	RAW_NOTE 8, $678
	RAW_MARK
	RAW_NOTE 9, $680
	RAW_NOTE 9, $688
	RAW_NOTE 9, $690
	RAW_NOTE 9, $698
	RAW_REPEAT 4, $01, $20
	LEN_UNIT 2
	RAW_NOTE 13, $700
	RAW_NOTE 13, $708
	RAW_NOTE 13, $710
	RAW_NOTE 13, $718
	RAW_MARK
	RAW_NOTE 15, $720
	RAW_REPEAT 16, $00, $08
	RAW_NOTE 12, $7A0
	RAW_NOTE 12, $7A8
	RAW_NOTE 12, $7B0
	RAW_NOTE 12, $7B8
	RAW_NOTE 10, $7C0
	RAW_NOTE 10, $7C8
	RAW_NOTE 10, $7D0
	RAW_NOTE 10, $7D8
	SND_END

Snd14_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 13, $710
	RAW_NOTE 12, $720
	RAW_NOTE 10, $730
	RAW_NOTE 9, $740
	RAW_NOTE 8, $750
	RAW_NOTE 6, $760
	RAW_NOTE 4, $770
	RAW_NOTE 2, $780
	RAW_NOTE 1, $790
	LEN_UNIT 4
	DUTY $0C
	LOOP_START
	RAW_NOTE 15, $700
	RAW_NOTE 15, $720
	LOOP_END 6
	LEN_UNIT 6
	RAW_MARK
	RAW_NOTE 13, $700
	RAW_NOTE 13, $720
	RAW_NOTE 12, $700
	RAW_NOTE 12, $720
	RAW_NOTE 11, $700
	RAW_NOTE 11, $720
	RAW_REPEAT 4, $FD, $00
	RAW_NOTE 1, $700
	RAW_NOTE 1, $720
	SND_END

Snd15_Sfx1:
	RAW_VOICE $02, $00, $08
	LOOP_START
	RAW_MARK
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7B8
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C8
	RAW_REPEAT 4, $FE, $F0
	LOOP_END 2
	RAW_MARK
	RAW_NOTE 15, $760
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 15, $750
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 13, $740
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 13, $730
	RAW_REPEAT 6, $00, $08
	LEN_UNIT 3
	RAW_MARK
	RAW_NOTE 12, $720
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 12, $710
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 11, $700
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 10, $6F0
	RAW_REPEAT 6, $00, $08
	LEN_UNIT 4
	RAW_MARK
	RAW_NOTE 10, $6E0
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 9, $6D0
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 9, $6C0
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 8, $6B0
	RAW_REPEAT 6, $00, $08
	LEN_UNIT 5
	RAW_MARK
	RAW_NOTE 8, $6A0
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 7, $690
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 7, $680
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 6, $660
	RAW_REPEAT 6, $00, $08
	LEN_UNIT 6
	RAW_MARK
	RAW_NOTE 5, $640
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 4, $620
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 3, $600
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 2, $5E0
	RAW_REPEAT 6, $00, $08
	RAW_MARK
	RAW_NOTE 1, $5C0
	RAW_REPEAT 6, $00, $08
	SND_END

Snd16_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_REPEAT 12, $00, $F0
	RAW_NOTE 13, $640
	RAW_NOTE 13, $630
	RAW_NOTE 13, $620
	RAW_NOTE 13, $610
	RAW_MARK
	RAW_NOTE 12, $600
	RAW_NOTE 12, $5F0
	RAW_NOTE 12, $5E0
	RAW_NOTE 12, $5D0
	RAW_REPEAT 6, $FE, $C0
	LEN_UNIT 2
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6E0
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_REPEAT 9, $00, $10
	RAW_NOTE 15, $7A0
	RAW_MARK
	RAW_NOTE 8, $6C0
	RAW_NOTE 8, $6E0
	RAW_NOTE 8, $700
	RAW_NOTE 8, $710
	RAW_NOTE 8, $720
	RAW_NOTE 8, $730
	RAW_NOTE 8, $740
	RAW_NOTE 8, $750
	RAW_NOTE 8, $760
	RAW_NOTE 8, $770
	RAW_NOTE 8, $780
	RAW_NOTE 8, $7A0
	RAW_REPEAT 2, $FC, $00
	SND_END

Snd17_Sfx1:
	RAW_VOICE $12, $80, $08
	RAW_NOTE 15, $7D0
	RAW_NOTE 12, $7B0
	RAW_NOTE 15, $7E0
	RAW_NOTE 12, $7C0
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7E0
	RAW_NOTE 12, $7E0
	RAW_NOTE 10, $7E0
	RAW_NOTE 8, $7E0
	RAW_NOTE 6, $7E0
	RAW_NOTE 4, $7E0
	RAW_NOTE 2, $7E0
	RAW_NOTE 2, $7E0
	RAW_NOTE 1, $7E0
	RAW_NOTE 1, $7E0
	SND_END

Snd18_Sfx1:
	RAW_VOICE $01, $80, $08
	LOOP2_START
	LOOP_START
	RAW_NOTE 15, $780
	RAW_NOTE 12, $700
	LOOP_END 6
	RAW_REST
	RAW_REST
	LOOP2_END 2
	LOOP_START
	RAW_NOTE 15, $780
	RAW_NOTE 12, $700
	LOOP_END $30
	RAW_MARK
	RAW_NOTE 13, $780
	RAW_NOTE 11, $700
	RAW_REPEAT 11, $FF, $00
	LOOP_START
	RAW_NOTE 2, $780
	RAW_NOTE 2, $700
	LOOP_END $18
	SND_END

Snd19_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_MARK
	RAW_NOTE 3, $680
	RAW_NOTE 3, $670
	RAW_NOTE 3, $660
	RAW_NOTE 4, $650
	RAW_NOTE 4, $640
	RAW_NOTE 4, $630
	RAW_REPEAT 2, $02, $00
	RAW_MARK
	RAW_NOTE 7, $670
	RAW_NOTE 7, $660
	RAW_NOTE 7, $650
	RAW_NOTE 8, $640
	RAW_NOTE 8, $630
	RAW_NOTE 8, $620
	RAW_REPEAT 2, $02, $00
	LOOP_START
	RAW_NOTE 15, $660
	RAW_NOTE 15, $650
	RAW_NOTE 15, $640
	RAW_NOTE 15, $630
	RAW_NOTE 15, $620
	RAW_NOTE 15, $610
	LOOP_END 2
	RAW_MARK
	RAW_NOTE 13, $650
	RAW_NOTE 13, $640
	RAW_NOTE 13, $630
	RAW_NOTE 13, $620
	RAW_NOTE 13, $610
	RAW_NOTE 13, $600
	RAW_REPEAT 2, $FF, $00
	RAW_MARK
	RAW_NOTE 10, $640
	RAW_NOTE 10, $630
	RAW_NOTE 10, $620
	RAW_NOTE 9, $610
	RAW_NOTE 9, $600
	RAW_NOTE 9, $5F0
	RAW_REPEAT 2, $FE, $00
	RAW_MARK
	RAW_NOTE 6, $630
	RAW_NOTE 5, $620
	RAW_NOTE 5, $610
	RAW_NOTE 5, $600
	RAW_NOTE 5, $5F0
	RAW_NOTE 5, $5E0
	RAW_NOTE 5, $630
	RAW_NOTE 5, $620
	RAW_NOTE 5, $610
	RAW_NOTE 5, $600
	RAW_NOTE 5, $5F0
	RAW_NOTE 5, $5E0
	RAW_REPEAT 3, $FE, $F0
	SND_END

Snd1A_SfxN:
	NVOICE_HOLD $01
	LOOP2_START
	LOOP_START
	NOISE_HOLD 6, $52
	NOISE_HOLD 6, $42
	LOOP_END $18
	LOOP_START
	NOISE_HOLD 4, $52
	NOISE_HOLD 4, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 3, $52
	NOISE_HOLD 3, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 2, $52
	NOISE_HOLD 2, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 1, $52
	NOISE_HOLD 1, $42
	LOOP_END 3
	LOOP2_END 4
	SND_END

Snd1B_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 4, $6C0
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 8, $6E0
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 10, $700
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 12, $720
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 15, $740
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 15, $760
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 12, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 10, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 4, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 3, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 2, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	RAW_NOTE 1, $780
	SLIDE_ON
	SLIDE 6, 0, 0, 0, $02
	SLIDE_OFF
	SND_END

Snd1C_Sfx1:
	RAW_VOICE $01, $C0, $08
	RAW_NOTE 15, $780
	RAW_MARK
	RAW_NOTE 12, $788
	RAW_REPEAT 12, $FF, $08
	LEN_UNIT 2
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D1
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D1
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D1
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $7D1
	RAW_MARK
	RAW_NOTE 12, $7D0
	RAW_NOTE 12, $7D1
	RAW_REPEAT 10, $FF, $00
	LEN_UNIT $0C
	RAW_NOTE 2, $7D0
	RAW_NOTE 2, $7D0
	SND_END

Snd1D_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $6A0
	RAW_NOTE 15, $680
	RAW_NOTE 15, $660
	RAW_NOTE 15, $640
	RAW_NOTE 10, $620
	RAW_NOTE 10, $600
	RAW_NOTE 10, $5E0
	RAW_NOTE 10, $5C0
	RAW_NOTE 6, $5A0
	RAW_NOTE 6, $580
	RAW_NOTE 6, $560
	RAW_NOTE 6, $540
	RAW_NOTE 4, $520
	RAW_NOTE 4, $500
	RAW_NOTE 4, $4E0
	RAW_NOTE 4, $4C0
	RAW_NOTE 2, $4A0
	RAW_NOTE 2, $480
	RAW_NOTE 2, $460
	RAW_NOTE 2, $440
	LEN_UNIT 2
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $780
	RAW_NOTE 15, $720
	RAW_NOTE 15, $710
	RAW_NOTE 15, $700
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $6D0
	RAW_NOTE 15, $6C0
	RAW_MARK
	RAW_NOTE 13, $6B0
	RAW_NOTE 13, $6A0
	RAW_NOTE 13, $690
	RAW_NOTE 13, $680
	RAW_NOTE 13, $670
	RAW_NOTE 13, $660
	RAW_NOTE 13, $650
	RAW_REPEAT 7, $FE, $A0
	SND_END

Snd1E_Sfx1:
	RAW_VOICE $01, $00, $08
	LOOP_START
	RAW_NOTE 4, $790
	RAW_NOTE 6, $780
	RAW_NOTE 8, $794
	RAW_NOTE 10, $784
	RAW_NOTE 12, $798
	RAW_NOTE 13, $788
	RAW_NOTE 15, $79C
	RAW_NOTE 15, $78C
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $798
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $79C
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7AC
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7AC
	RAW_NOTE 13, $7B4
	RAW_NOTE 13, $7B0
	RAW_NOTE 12, $7B8
	RAW_NOTE 12, $7B4
	RAW_NOTE 11, $7BC
	RAW_NOTE 11, $7B8
	LOOP_END 2
	RAW_NOTE 10, $7C0
	RAW_NOTE 10, $7BE
	RAW_NOTE 9, $7C4
	RAW_NOTE 9, $7C2
	RAW_NOTE 8, $7C8
	RAW_NOTE 8, $7C6
	RAW_NOTE 6, $7CC
	RAW_NOTE 6, $7CA
	RAW_NOTE 5, $7D0
	RAW_NOTE 5, $7D2
	RAW_NOTE 4, $7D4
	RAW_NOTE 4, $7D6
	RAW_NOTE 3, $7D8
	RAW_NOTE 3, $7DA
	RAW_NOTE 2, $7DC
	RAW_NOTE 2, $7DE
	SND_END

Snd1F_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 13, $710
	RAW_NOTE 12, $720
	RAW_NOTE 10, $730
	RAW_NOTE 9, $740
	RAW_NOTE 8, $750
	RAW_NOTE 6, $760
	RAW_NOTE 4, $770
	RAW_NOTE 2, $780
	RAW_NOTE 1, $790
	LEN_UNIT 4
	DUTY $0C
	RAW_NOTE 15, $740
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $740
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $720
	RAW_NOTE 15, $780
	RAW_NOTE 15, $720
	RAW_NOTE 15, $780
	RAW_NOTE 13, $700
	RAW_NOTE 13, $760
	RAW_NOTE 13, $700
	RAW_NOTE 13, $760
	RAW_MARK
	RAW_NOTE 12, $6E0
	RAW_NOTE 12, $740
	RAW_NOTE 12, $6E0
	RAW_NOTE 12, $740
	RAW_REPEAT 6, $FE, $E0
	RAW_NOTE 1, $620
	RAW_NOTE 1, $680
	RAW_NOTE 1, $620
	RAW_NOTE 1, $680
	SND_END

Snd20_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $720
	RAW_NOTE 15, $718
	RAW_NOTE 15, $710
	RAW_REPEAT 7, $FE, $00
	RAW_MARK
	LOOP_START
	RAW_NOTE 15, $780
	RAW_NOTE 15, $778
	RAW_NOTE 15, $770
	LOOP_END 3
	RAW_REPEAT 5, $FE, $00
	RAW_MARK
	RAW_NOTE 4, $780
	RAW_NOTE 4, $778
	RAW_NOTE 4, $770
	RAW_REPEAT 3, $FE, $00
	SND_END

Snd21_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_MARK
	RAW_NOTE 15, $780
	RAW_NOTE 15, $788
	RAW_NOTE 15, $790
	RAW_NOTE 15, $798
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7A8
	RAW_REPEAT 4, $FC, $10
	SND_END

Snd22_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 15, $780
	RAW_NOTE 15, $770
	RAW_NOTE 13, $760
	RAW_NOTE 13, $750
	RAW_NOTE 12, $740
	RAW_NOTE 12, $730
	RAW_NOTE 11, $720
	RAW_NOTE 11, $710
	RAW_NOTE 10, $700
	RAW_NOTE 10, $6F0
	RAW_NOTE 8, $6E0
	RAW_NOTE 8, $6D0
	RAW_NOTE 6, $6C0
	RAW_NOTE 6, $6B0
	RAW_NOTE 4, $6A0
	RAW_NOTE 4, $690
	RAW_NOTE 3, $680
	RAW_NOTE 3, $670
	RAW_NOTE 2, $660
	RAW_NOTE 2, $650
	LEN_UNIT 3
	RAW_MARK
	RAW_NOTE 10, $700
	RAW_NOTE 10, $6F0
	RAW_NOTE 9, $6E0
	RAW_NOTE 9, $6D0
	RAW_REPEAT 5, $FE, $C0
	RAW_MARK
	RAW_NOTE 8, $700
	RAW_NOTE 8, $6F0
	RAW_NOTE 7, $6E0
	RAW_NOTE 7, $6D0
	RAW_REPEAT 4, $FE, $C0
	RAW_NOTE 1, $600
	RAW_NOTE 1, $5F0
	RAW_NOTE 1, $5E0
	RAW_NOTE 1, $5D0
	LEN_UNIT 4
	RAW_MARK
	RAW_NOTE 6, $700
	RAW_NOTE 6, $6F0
	RAW_NOTE 5, $6E0
	RAW_NOTE 5, $6D0
	RAW_REPEAT 3, $FE, $C0
	RAW_NOTE 1, $640
	RAW_NOTE 1, $630
	RAW_NOTE 1, $620
	RAW_NOTE 1, $610
	RAW_NOTE 1, $600
	RAW_NOTE 1, $5F0
	RAW_NOTE 1, $5E0
	RAW_NOTE 1, $5D0
	LEN_UNIT 5
	RAW_NOTE 2, $700
	RAW_NOTE 2, $6F0
	RAW_NOTE 1, $6E0
	RAW_NOTE 1, $6D0
	RAW_MARK
	RAW_NOTE 1, $6C0
	RAW_NOTE 1, $6B0
	RAW_NOTE 1, $6A0
	RAW_NOTE 1, $690
	RAW_REPEAT 4, $00, $C0
	SND_END

Snd23_Sfx1:
	RAW_VOICE $01, $00, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $704
	RAW_NOTE 15, $708
	RAW_NOTE 15, $70C
	RAW_NOTE 15, $710
	RAW_NOTE 15, $714
	RAW_NOTE 12, $718
	RAW_NOTE 10, $71C
	RAW_NOTE 8, $720
	RAW_NOTE 6, $724
	RAW_NOTE 4, $728
	RAW_NOTE 2, $72C
	RAW_NOTE 15, $780
	RAW_NOTE 15, $784
	RAW_NOTE 15, $788
	RAW_NOTE 15, $78C
	RAW_NOTE 15, $790
	RAW_NOTE 15, $794
	RAW_NOTE 12, $798
	RAW_NOTE 10, $79C
	RAW_NOTE 8, $7A0
	RAW_NOTE 6, $7A4
	RAW_NOTE 4, $7A8
	RAW_NOTE 2, $7AC
	SND_END

Snd24_Sfx1:
	RAW_VOICE $01, $80, $08
	LOOP_START
	RAW_NOTE 15, $700
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	LOOP_END 2
	LEN_UNIT 2
	RAW_NOTE 12, $6FC
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 10, $7BC
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 8, $6F8
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 6, $7B8
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	LEN_UNIT 2
	RAW_NOTE 4, $6F4
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 2, $7B4
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	RAW_NOTE 1, $6F0
	SLIDE_ON
	SLIDE 12, 0, 0, 0, $10
	SLIDE_OFF
	RAW_NOTE 1, $7B0
	SLIDE_ON
	SLIDE 12, 0, 0, 1, $10
	SLIDE_OFF
	SND_END

Snd25_Sfx1:
	RAW_VOICE $05, $80, $08
	RAW_MARK
	RAW_NOTE 10, $700
	RAW_NOTE 10, $600
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 12, $740
	RAW_NOTE 12, $640
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 15, $720
	RAW_NOTE 15, $620
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 15, $740
	RAW_NOTE 15, $640
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 15, $740
	RAW_NOTE 15, $640
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 8, $740
	RAW_NOTE 8, $640
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 4, $700
	RAW_NOTE 4, $600
	RAW_REPEAT 4, $00, $04
	RAW_MARK
	RAW_NOTE 2, $740
	RAW_NOTE 2, $640
	RAW_REPEAT 4, $00, $04
	SND_END

Snd26_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 15, $17
	LEN_UNIT $1D
	NOISE_HOLD 15, $47
	NOISE_HOLD 12, $47
	NOISE_HOLD 15, $47
	NOISE_HOLD 12, $47
	NOISE_HOLD 10, $47
	NOISE_HOLD 8, $47
	NOISE_HOLD 6, $47
	NOISE_HOLD 4, $47
	NOISE_HOLD 2, $47
	SND_END

Snd27_SfxN:
	NVOICE_HOLD $14
	NOISE_HOLD 15, $47
	NOISE_HOLD 15, $62
	NOISE_HOLD 15, $47
	NOISE_HOLD 15, $47
	NOISE_HOLD 15, $62
	NOISE_HOLD 15, $47
	NOISE_HOLD 15, $62
	NOISE_HOLD 12, $47
	NOISE_HOLD 12, $62
	NOISE_HOLD 10, $47
	NOISE_HOLD 10, $62
	NOISE_HOLD 8, $47
	NOISE_HOLD 6, $62
	NOISE_HOLD 4, $47
	NOISE_HOLD 4, $62
	NOISE_HOLD 2, $47
	NOISE_HOLD 2, $62
	NOISE_HOLD 1, $47
	NOISE_HOLD 1, $62
	SND_END

Snd28_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 15, $47
	LEN_UNIT $0E
	NOISE_HOLD 15, $27
	NOISE_HOLD 12, $27
	NOISE_HOLD 10, $27
	NOISE_HOLD 8, $27
	NOISE_HOLD 6, $17
	NOISE_HOLD 4, $17
	NOISE_HOLD 2, $17
	SND_END

Snd29_SfxN:
	NVOICE $04, $FF
	NOISE $36
	LEN_UNIT 2
	NOISE $24
	NOISE $24
	NOISE $23
	NOISE $22
	SND_END

Snd2A_Sfx1:
	RAW_VOICE $01, $C0, $08
	RAW_NOTE 15, $780
	RAW_NOTE 15, $700
	RAW_NOTE 15, $680
	RAW_NOTE 15, $600
	RAW_MARK
	RAW_NOTE 12, $780
	RAW_NOTE 12, $700
	RAW_NOTE 12, $680
	RAW_NOTE 12, $600
	RAW_REPEAT 3, $FE, $00
	LEN_UNIT 1
	RAW_NOTE 15, $780
	RAW_NOTE 15, $700
	RAW_NOTE 15, $680
	RAW_NOTE 15, $600
	RAW_NOTE 15, $580
	RAW_NOTE 15, $500
	RAW_MARK
	RAW_NOTE 13, $760
	RAW_NOTE 13, $6E0
	RAW_NOTE 13, $660
	RAW_NOTE 13, $5E0
	RAW_NOTE 13, $560
	RAW_NOTE 13, $4E0
	RAW_REPEAT 6, $FF, $E0
	RAW_MARK
	RAW_NOTE 9, $6E0
	RAW_NOTE 9, $660
	RAW_NOTE 9, $5E0
	RAW_NOTE 9, $560
	RAW_NOTE 9, $4E0
	RAW_NOTE 9, $460
	RAW_NOTE 8, $6E0
	RAW_NOTE 8, $660
	RAW_NOTE 8, $5E0
	RAW_NOTE 8, $560
	RAW_NOTE 8, $4E0
	RAW_NOTE 8, $460
	RAW_REPEAT 4, $FE, $E0
	SND_END

Snd2A_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 4, $64
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $64
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $27
	NOISE_HOLD 4, $27
	NOISE_HOLD 4, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 3, $27
	NOISE_HOLD 2, $27
	NOISE_HOLD 2, $27
	NOISE_HOLD 2, $27
	NOISE_HOLD 1, $27
	NOISE_HOLD 1, $27
	NOISE_HOLD 1, $27
	SND_END

Snd2B_Sfx1:
	RAW_VOICE $01, $C0, $08
	LOOP_START
	RAW_NOTE 8, $7C0
	RAW_NOTE 8, $780
	RAW_NOTE 8, $740
	RAW_NOTE 8, $700
	RAW_NOTE 8, $6C0
	RAW_NOTE 8, $680
	RAW_REST
	RAW_REST
	LOOP_END 4
	SND_END

Snd2C_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 13, $700
	RAW_NOTE 13, $600
	RAW_NOTE 13, $700
	RAW_NOTE 13, $600
	RAW_NOTE 13, $700
	RAW_NOTE 13, $600
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_NOTE 11, $700
	RAW_NOTE 11, $600
	RAW_NOTE 10, $700
	RAW_NOTE 10, $600
	LEN_UNIT 2
	LOOP_START
	RAW_NOTE 15, $740
	RAW_NOTE 15, $640
	LOOP_END 6
	RAW_NOTE 13, $740
	RAW_NOTE 13, $640
	RAW_NOTE 13, $740
	RAW_NOTE 13, $640
	RAW_MARK
	RAW_NOTE 13, $740
	RAW_NOTE 13, $640
	RAW_REPEAT 8, $FF, $00
	LEN_UNIT 1
	DUTY $0C
	RAW_MARK
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	LOOP_START
	RAW_REST
	LOOP_END 6
	RAW_REPEAT 7, $00, $08
	RAW_NOTE 15, $5B8
	RAW_NOTE 15, $738
	RAW_NOTE 15, $5B8
	RAW_NOTE 15, $738
	RAW_NOTE 15, $5B8
	RAW_NOTE 15, $738
	SND_END

Snd2D_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 15, $780
	RAW_NOTE 15, $700
	RAW_NOTE 15, $760
	RAW_NOTE 15, $6E0
	RAW_MARK
	RAW_NOTE 12, $740
	RAW_NOTE 12, $6C0
	RAW_NOTE 12, $720
	RAW_NOTE 12, $6A0
	RAW_REPEAT 6, $FE, $C0
	LEN_UNIT 3
	RAW_NOTE 15, $740
	RAW_NOTE 15, $730
	RAW_NOTE 13, $720
	RAW_NOTE 13, $710
	RAW_NOTE 12, $700
	RAW_NOTE 12, $6F0
	RAW_NOTE 11, $6E0
	RAW_NOTE 11, $6D0
	RAW_NOTE 10, $6C0
	RAW_NOTE 10, $6B0
	RAW_NOTE 9, $6A0
	RAW_NOTE 9, $690
	RAW_MARK
	RAW_NOTE 12, $740
	RAW_NOTE 12, $730
	RAW_NOTE 11, $720
	RAW_NOTE 11, $710
	RAW_NOTE 10, $700
	RAW_NOTE 10, $6F0
	RAW_NOTE 9, $6E0
	RAW_NOTE 9, $6D0
	RAW_NOTE 8, $6C0
	RAW_NOTE 8, $6B0
	RAW_NOTE 7, $6A0
	RAW_NOTE 7, $690
	RAW_REPEAT 4, $FE, $00
	SND_END

Snd2E_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 10, $710
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $790
	RAW_NOTE 10, $750
	RAW_REPEAT 4, $01, $08
	RAW_NOTE 15, $730
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $770
	RAW_NOTE 15, $738
	RAW_NOTE 15, $6F8
	RAW_NOTE 15, $7B8
	RAW_NOTE 15, $778
	RAW_NOTE 12, $740
	RAW_NOTE 12, $700
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $780
	RAW_NOTE 8, $748
	RAW_NOTE 8, $708
	RAW_NOTE 8, $7C8
	RAW_NOTE 8, $788
	SND_END

Snd2F_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 15, $46
	LEN_UNIT 6
	NOISE_HOLD 15, $12
	NOISE_HOLD 10, $12
	NOISE_HOLD 6, $12
	NOISE_HOLD 4, $12
	NOISE_HOLD 2, $12
	NOISE_HOLD 1, $12
	SND_END

Snd30_Sfx1:
	RAW_VOICE $04, $C0, $08
	RAW_NOTE 10, $680
	RAW_NOTE 11, $690
	RAW_NOTE 12, $6A0
	RAW_NOTE 13, $6C0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $700
	RAW_NOTE 12, $740
	RAW_NOTE 10, $780
	RAW_NOTE 8, $7C0
	SND_END

Snd30_SfxN:
	NVOICE_HOLD $24
	NOISE_REST
	LEN_UNIT 8
	NOISE_REST
	NOISE_HOLD 15, $46
	LEN_UNIT 6
	NOISE_HOLD 15, $12
	NOISE_HOLD 10, $12
	NOISE_HOLD 6, $12
	NOISE_HOLD 4, $12
	NOISE_HOLD 2, $12
	NOISE_HOLD 1, $12
	SND_END

Snd31_Sfx1:
	RAW_VOICE $01, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $6C0
	RAW_REPEAT 12, $00, $08
	RAW_NOTE 12, $720
	RAW_NOTE 12, $728
	RAW_NOTE 12, $730
	RAW_NOTE 12, $738
	RAW_NOTE 10, $740
	RAW_NOTE 10, $748
	RAW_NOTE 8, $750
	RAW_NOTE 8, $758
	RAW_NOTE 6, $760
	RAW_NOTE 4, $768
	RAW_NOTE 2, $770
	RAW_NOTE 1, $778
	RAW_NOTE 15, $7DA
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7DE
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7E1
	RAW_NOTE 15, $7E2
	RAW_NOTE 15, $7E3
	RAW_NOTE 15, $7E4
	RAW_NOTE 15, $7DA
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7DE
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7E5
	RAW_NOTE 15, $7E6
	RAW_NOTE 15, $7E7
	RAW_NOTE 15, $7E8
	RAW_MARK
	RAW_NOTE 12, $7DA
	RAW_NOTE 12, $7DC
	RAW_NOTE 12, $7DE
	RAW_NOTE 12, $7E0
	RAW_NOTE 12, $7E1
	RAW_NOTE 12, $7E2
	RAW_NOTE 12, $7E3
	RAW_NOTE 12, $7E4
	RAW_NOTE 12, $7E5
	RAW_NOTE 12, $7E6
	RAW_NOTE 12, $7E7
	RAW_NOTE 12, $7E8
	RAW_REPEAT 5, $FE, $00
	SND_END

Snd32_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 8, $21
	NOISE_HOLD 6, $31
	NOISE_HOLD 4, $12
	LEN_UNIT $20
	NOISE_HOLD 12, $33
	NOISE_HOLD 10, $30
	NOISE_HOLD 8, $04
	NOISE_HOLD 6, $03
	NOISE_HOLD 4, $02
	NOISE_HOLD 2, $01
	SND_END

Snd33_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_REPEAT 9, $00, $08
	RAW_MARK
	RAW_NOTE 13, $738
	RAW_NOTE 13, $730
	RAW_NOTE 12, $728
	RAW_NOTE 12, $720
	RAW_REPEAT 12, $FF, $E0
	SND_END

Snd34_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $500
	RAW_NOTE 15, $400
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_NOTE 12, $500
	RAW_NOTE 12, $400
	RAW_REPEAT 6, $FE, $00
	SND_END

Snd34_SfxN:
	NVOICE_HOLD $02
	NOISE_HOLD 15, $34
	NOISE_HOLD 15, $34
	NOISE_HOLD 15, $34
	NOISE_HOLD 15, $34
	NOISE_HOLD 15, $34
	NOISE_HOLD 12, $34
	NOISE_HOLD 12, $34
	NOISE_HOLD 12, $34
	NOISE_HOLD 12, $34
	NOISE_HOLD 12, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 8, $34
	NOISE_HOLD 8, $34
	NOISE_HOLD 8, $34
	NOISE_HOLD 8, $34
	NOISE_HOLD 8, $34
	NOISE_HOLD 6, $34
	NOISE_HOLD 6, $34
	NOISE_HOLD 6, $34
	NOISE_HOLD 6, $34
	NOISE_HOLD 6, $34
	NOISE_HOLD 4, $34
	NOISE_HOLD 4, $34
	NOISE_HOLD 4, $34
	NOISE_HOLD 4, $34
	NOISE_HOLD 4, $34
	NOISE_HOLD 3, $34
	NOISE_HOLD 3, $34
	NOISE_HOLD 3, $34
	NOISE_HOLD 3, $34
	NOISE_HOLD 3, $34
	NOISE_HOLD 2, $34
	NOISE_HOLD 2, $34
	NOISE_HOLD 2, $34
	NOISE_HOLD 2, $34
	NOISE_HOLD 2, $34
	SND_END

Snd35_SfxN:
	NVOICE_HOLD $10
Snd35_SfxN_5DC8:
	NOISE_HOLD 15, $17
	LEN_UNIT 3
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	SND_END

Snd36_Sfx1:
	RAW_VOICE $01, $80, $08
	LOOP2_START
	LOOP_START
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C3
	LOOP_END $80
	LEN_UNIT 2
	RAW_MARK
	LOOP_START
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $7C3
	RAW_NOTE 12, $7C0
	RAW_NOTE 11, $7C3
	RAW_NOTE 11, $7C0
	RAW_NOTE 11, $7C3
	LOOP_END 2
	RAW_REPEAT 6, $FE, $00
	LEN_UNIT 1
	LOOP2_END 2
	SND_END

Snd36_Sfx2:
	SND_END

Snd36_Ch1:
	SND_END

Snd37_Sfx1:
	RAW_VOICE $02, $00, $08
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7A6
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $7A2
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $780
	RAW_NOTE 15, $760
	RAW_NOTE 15, $740
	RAW_NOTE 12, $790
	RAW_NOTE 12, $770
	RAW_NOTE 12, $750
	RAW_NOTE 12, $730
	RAW_NOTE 10, $780
	RAW_NOTE 10, $760
	RAW_NOTE 10, $740
	RAW_NOTE 10, $720
	RAW_MARK
	RAW_NOTE 8, $770
	RAW_NOTE 8, $750
	RAW_NOTE 8, $730
	RAW_NOTE 8, $710
	RAW_NOTE 8, $768
	RAW_NOTE 8, $748
	RAW_NOTE 8, $728
	RAW_NOTE 8, $708
	RAW_REPEAT 8, $FF, $F0
	SND_END

Snd37_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 10, $3D
	NOISE_HOLD 12, $34
	NOISE_HOLD 10, $34
	NOISE_HOLD 8, $35
	NOISE_HOLD 6, $35
	NOISE_HOLD 4, $36
	NOISE_HOLD 3, $36
	NOISE_HOLD 2, $36
	NOISE_HOLD 1, $36
	SND_END

Snd38_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $780
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $780
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $780
	RAW_NOTE 15, $6C0
	RAW_REPEAT 4, $FD, $00
	LEN_UNIT 1
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $700
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $700
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $700
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $700
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $700
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $700
	RAW_MARK
	RAW_NOTE 13, $7D0
	RAW_NOTE 12, $700
	RAW_NOTE 13, $7D0
	RAW_NOTE 12, $700
	RAW_NOTE 13, $7D0
	RAW_NOTE 12, $700
	RAW_REPEAT 12, $FF, $00
	SND_END

Snd39_SfxN:
	NVOICE_HOLD $01
	LOOP_START
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 10, $37
	NOISE_HOLD 8, $37
	LEN_UNIT $30
	NOISE_REST
	LEN_UNIT 1
	LOOP_END 2
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $37
	NOISE_HOLD 10, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 6, $37
	LEN_UNIT $30
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 8, $37
	NOISE_HOLD 6, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 2, $37
	LEN_UNIT $30
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 4, $37
	NOISE_HOLD 3, $37
	NOISE_HOLD 2, $37
	NOISE_HOLD 1, $37
	SND_END

Snd83_Sfx1:
	RAW_VOICE $02, $80, $08
	PAN_RIGHT 0
	RAW_NOTE 12, $7C6
	RAW_NOTE 11, $7CE
	RAW_NOTE 9, $7D5
	RAW_NOTE 8, $7CE
	RAW_NOTE 8, $7C6
	RAW_NOTE 8, $7CE
	LEN_UNIT $14
	RAW_REST
	LEN_UNIT 3
	LOOP_START
	RAW_NOTE 11, $7C4
	RAW_NOTE 11, $7CC
	RAW_NOTE 12, $7D3
	RAW_NOTE 11, $7CC
	LOOP_END $0C
	RAW_NOTE 11, $7C4
	RAW_NOTE 11, $7CC
	RAW_NOTE 11, $7D3
	RAW_NOTE 10, $7CC
	RAW_NOTE 10, $7C4
	RAW_NOTE 9, $7CC
	SND_END

Snd83_Sfx2:
	RAW_VOICE $03, $10, $00
	PAN_LEFT 0
	RAW_NOTE 2, $7E2
	RAW_NOTE 2, $7E6
	RAW_NOTE 2, $7E9
	RAW_NOTE 4, $7E6
	RAW_NOTE 4, $7E2
	RAW_NOTE 4, $7E6
	LEN_UNIT $14
	RAW_REST
	LEN_UNIT 3
	LOOP_START
	RAW_NOTE 4, $7E2
	RAW_NOTE 4, $7E6
	RAW_NOTE 4, $7E9
	RAW_NOTE 4, $7E6
	LOOP_END $0C
	RAW_NOTE 6, $7E2
	RAW_NOTE 6, $7E6
	RAW_NOTE 6, $7E9
	RAW_NOTE 6, $7E6
	RAW_NOTE 6, $7E2
	RAW_NOTE 6, $7E6
	RAW_NOTE 6, $7E9
	RAW_NOTE 6, $7E6
	SND_END

Snd84_Sfx1:
	RAW_VOICE $28, $80, $08
	RAW_REST
	LEN_UNIT 6
	TRANSPOSE_DOWN 3
	RAW_NOTE 9, $7B6
	RAW_NOTE 9, $7BA
	RAW_NOTE 8, $7BE
	RAW_NOTE 7, $7C2
	RAW_NOTE 6, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 4, $7CC
	RAW_NOTE 3, $7CD
	RAW_NOTE 9, $7B6
	RAW_NOTE 9, $7BA
	RAW_NOTE 8, $7BE
	RAW_NOTE 7, $7C2
	RAW_NOTE 6, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 4, $7CC
	RAW_NOTE 3, $7CD
	RAW_NOTE 5, $7B6
	RAW_NOTE 5, $7B3
	RAW_NOTE 4, $7AC
	RAW_NOTE 4, $7A9
	RAW_NOTE 3, $7A5
	RAW_NOTE 3, $79E
	RAW_NOTE 2, $797
	RAW_NOTE 1, $793
	LEN_UNIT $14
	LOOP_START
	RAW_REST
	LOOP_END 7
	LEN_UNIT 6
	RAW_NOTE 8, $7C8
	RAW_NOTE 8, $7C4
	RAW_NOTE 7, $7BD
	RAW_NOTE 6, $7B6
	RAW_NOTE 6, $7B1
	RAW_NOTE 5, $7AC
	RAW_NOTE 4, $7A8
	RAW_NOTE 4, $7A4
	RAW_NOTE 5, $7A4
	LEN_UNIT 5
	RAW_NOTE 5, $7A4
	RAW_NOTE 6, $7A7
	RAW_NOTE 6, $7AB
	RAW_NOTE 7, $7AF
	RAW_NOTE 7, $7B2
	RAW_NOTE 7, $7B4
	RAW_NOTE 8, $7B7
	RAW_NOTE 9, $7BC
	RAW_NOTE 9, $7BE
	RAW_NOTE 9, $7C3
	RAW_NOTE 9, $7C8
	RAW_NOTE 10, $7CB
	RAW_NOTE 12, $EC2
	RAW_NOTE 11, $7D3
	LEN_UNIT 3
	PAN_RIGHT 0
	RAW_NOTE 6, $7BC
	RAW_NOTE 6, $7BE
	RAW_NOTE 7, $7C3
	RAW_NOTE 7, $7C8
	RAW_NOTE 8, $7CB
	RAW_NOTE 9, $7D2
	PAN_LEFT 0
	RAW_NOTE 4, $7BC
	RAW_NOTE 4, $7BE
	RAW_NOTE 5, $7C3
	RAW_NOTE 5, $7C8
	RAW_NOTE 6, $7CB
	RAW_NOTE 2, $7BC
	RAW_NOTE 2, $7BE
	RAW_NOTE 3, $7C3
	RAW_NOTE 4, $7C8
	SND_END

Snd84_Sfx2:
	RAW_VOICE $14, $60, $00
	LOOP_START
	RAW_REST
	LOOP_END 5
	LEN_UNIT 5
	PAN_LEFT 0
	RAW_NOTE 4, $7B6
	RAW_NOTE 4, $7BA
	RAW_NOTE 4, $7BE
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C4
	RAW_NOTE 6, $7C8
	RAW_NOTE 6, $7CC
	RAW_NOTE 6, $7CD
	PAN_RIGHT 0
	RAW_NOTE 4, $7B6
	RAW_NOTE 4, $7BA
	RAW_NOTE 4, $7BE
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C4
	RAW_NOTE 6, $7C8
	RAW_NOTE 6, $7CC
	RAW_NOTE 6, $7CD
	LEN_UNIT $22
	WAVE 4
	PAN_BOTH 0
	RAW_NOTE 2, $723
	RAW_NOTE 2, $753
	LEN_UNIT $2A
	RAW_REST
	RAW_REST
	LEN_UNIT $22
	RAW_NOTE 4, $723
	RAW_NOTE 4, $753
	RAW_NOTE 4, $723
	RAW_NOTE 4, $753
	SND_END

Snd84_SfxN:
	NVOICE_HOLD $14
	NOISE_HOLD 5, $47
	NOISE_HOLD 7, $62
	NOISE_HOLD 14, $47
	NOISE_HOLD 13, $62
	NOISE_HOLD 15, $47
	LOOP_START
	NOISE_HOLD 15, $62
	NOISE_HOLD 15, $47
	LOOP_END 7
	LEN_UNIT $10
	NOISE_HOLD 11, $47
	NOISE_HOLD 10, $62
	NOISE_HOLD 9, $47
	NOISE_HOLD 8, $62
	NOISE_HOLD 7, $47
	LEN_UNIT $14
	NOISE_HOLD 6, $62
	NOISE_HOLD 5, $47
	NOISE_HOLD 4, $62
	NOISE_HOLD 4, $47
	NOISE_HOLD 3, $62
	NOISE_HOLD 3, $47
	LOOP_START
	NOISE_HOLD 2, $62
	NOISE_HOLD 2, $47
	LOOP_END 4
	LOOP_START
	NOISE_HOLD 1, $62
	NOISE_HOLD 1, $47
	LOOP_END 3
	SND_END

Snd85_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_MARK
	RAW_NOTE 2, $70A
	RAW_REPEAT 5, $02, $F7
	RAW_MARK
	RAW_NOTE 11, $6D3
	RAW_REPEAT 4, $FE, $F5
	LEN_UNIT 4
	RAW_NOTE 5, $6BA
	RAW_NOTE 4, $6C4
	RAW_NOTE 6, $6C9
	RAW_NOTE 7, $6CF
	RAW_MARK
	RAW_NOTE 8, $6D3
	RAW_REPEAT 4, $02, $08
	RAW_MARK
	RAW_NOTE 15, $6F5
	RAW_REPEAT 10, $FF, $09
	SND_END

Snd86_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $79D
	RAW_NOTE 15, $79D
	RAW_NOTE 13, $7CE
	RAW_NOTE 11, $7CE
	LEN_UNIT $0A
	DUTY 0
	RAW_NOTE 15, $75A
	DUTY 8
	LEN_UNIT 9
	RAW_NOTE 15, $7C2
	RAW_NOTE 13, $7C2
	RAW_NOTE 9, $7C2
	RAW_NOTE 6, $7C2
	LEN_UNIT 1
	RAW_NOTE 10, $7CE
	RAW_NOTE 6, $7CE
	LEN_UNIT $0A
	DUTY 0
	RAW_NOTE 8, $75A
	LEN_UNIT 9
	DUTY 8
	RAW_NOTE 6, $7C2
	RAW_NOTE 4, $7C2
	RAW_NOTE 2, $7C2
	RAW_NOTE 1, $7C2
	LEN_UNIT $0A
	DUTY 0
	RAW_NOTE 5, $75A
	LEN_UNIT 9
	DUTY 8
	RAW_NOTE 3, $7C2
	RAW_NOTE 2, $7C2
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C2
	LEN_UNIT 1
	RAW_NOTE 2, $79D
	RAW_NOTE 1, $79D
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CE
	SND_END

Snd87_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_MARK
	DUTY 8
	RAW_NOTE 5, $707
	RAW_NOTE 8, $707
	RAW_NOTE 11, $707
	DUTY 4
	RAW_NOTE 13, $708
	RAW_NOTE 15, $707
	RAW_NOTE 15, $707
	RAW_NOTE 15, $707
	RAW_REST
	RAW_REST
	LEN_UNIT 2
	RAW_REPEAT 2, $FB, $00
	SND_END

Snd89_Sfx1:
	RAW_VOICE $07, $80, $08
	RAW_NOTE 15, $784
	DUTY 0
	RAW_MARK
	RAW_NOTE 10, $787
	RAW_REPEAT 5, $FF, $00
	DUTY 8
	RAW_NOTE 15, $763
	DUTY 0
	RAW_MARK
	RAW_NOTE 11, $764
	RAW_REPEAT 6, $FF, $00
	DUTY 8
	RAW_NOTE 15, $784
	DUTY 0
	RAW_NOTE 12, $785
	RAW_NOTE 10, $786
	RAW_MARK
	RAW_NOTE 8, $786
	RAW_REPEAT 3, $FE, $00
	DUTY 8
	RAW_NOTE 15, $763
	RAW_NOTE 15, $763
	RAW_MARK
	RAW_NOTE 9, $764
	RAW_REPEAT 7, $FF, $00
	DUTY 0
	RAW_NOTE 4, $764
	RAW_NOTE 3, $764
	RAW_NOTE 2, $764
	RAW_NOTE 1, $764
	SND_END
Data_6199:
	RAW_VOICE $07, $50, $00
	RAW_REST
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C3
	LOOP_START
	RAW_NOTE 6, $7C3
	LOOP_END 5
	RAW_NOTE 4, $7B2
	RAW_NOTE 4, $7B2
	LOOP_START
	RAW_NOTE 6, $7B2
	LOOP_END 6
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C2
	RAW_NOTE 10, $7C3
	LOOP_START
	RAW_NOTE 6, $7C4
	LOOP_END 4
	RAW_NOTE 4, $7B2
	RAW_NOTE 15, $7B2
	LOOP_START
	RAW_NOTE 6, $7B2
	LOOP_END $0A
	SND_END

Snd8A_Sfx1:
	RAW_VOICE $0A, $80, $08
	RAW_NOTE 8, $722
	RAW_NOTE 10, $723
	DUTY 0
	RAW_NOTE 11, $726
	RAW_NOTE 12, $729
	RAW_NOTE 13, $72A
	RAW_REST
	RAW_REST
	DUTY 8
	RAW_NOTE 8, $715
	RAW_NOTE 10, $717
	DUTY 0
	RAW_NOTE 11, $719
	RAW_NOTE 12, $71B
	RAW_NOTE 13, $71F
	LEN_UNIT $0D
	RAW_REST
	RAW_REST
	LEN_UNIT $0B
	DUTY 8
	RAW_NOTE 8, $707
	RAW_NOTE 10, $709
	DUTY 0
	RAW_NOTE 11, $70B
	RAW_NOTE 12, $70E
	RAW_NOTE 13, $712
	LEN_UNIT $11
	RAW_REST
	RAW_REST
	LEN_UNIT $0C
	DUTY 8
	RAW_NOTE 8, $6F8
	RAW_NOTE 10, $6FA
	DUTY 0
	RAW_NOTE 11, $6FD
	RAW_NOTE 12, $701
	RAW_NOTE 13, $705
	LEN_UNIT $15
	RAW_REST
	RAW_REST
	LEN_UNIT $0D
	DUTY 8
	RAW_NOTE 8, $6E9
	RAW_NOTE 10, $6EC
	DUTY 0
	RAW_NOTE 11, $6EF
	RAW_NOTE 12, $6F2
	RAW_NOTE 13, $6F6
	DUTY 0
	RAW_NOTE 15, $6F8
	RAW_NOTE 15, $707
	RAW_NOTE 14, $6F8
	RAW_NOTE 13, $707
	RAW_NOTE 12, $6F8
	RAW_NOTE 12, $707
	RAW_NOTE 9, $6F8
	RAW_NOTE 8, $707
	RAW_NOTE 7, $6F8
	RAW_NOTE 6, $707
	RAW_NOTE 5, $6F8
	RAW_NOTE 5, $707
	LEN_UNIT $0A
	VOLUME $46
	VOLUME $46
	SND_END

Snd8B_Sfx2:
	SND_END
	db $FF

Snd8B_Ch1:
	SND_END

Snd8B_Ch2:
	SND_END

Snd8B_Ch3:
	SND_END

Snd8B_Drm:
	SND_END

Snd88_Sfx1:
	VOICE $10, 4, 15, 9, 4
	DUTY_STEP 8, 3
	LOOP_START
	OCTAVE 4
	NOTE C_, 3
	REST 2
	LEN_UNIT $55
	REST 1
	LEN_UNIT $10
	LOOP_END 2
	OCTAVE 4
	NOTE C_, 3
	LEN_UNIT $4C
	REST 1
	LEN_UNIT 3
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 2
	LOOP_START
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	LOOP_END 2
	LEN_UNIT 8
	RELEASE $0C, 2
	DUTY_STEP 0, 12
	OCTAVE 5
	NOTE G_, 3
	DUTY_STEP 0, 0
	ATTEN 7
	RELEASE $0F, 6
	NOTE G_, 3
	VOLUME $06
	SND_CALL Snd88_Sfx1_628F
	VOLUME $04
	SND_CALL Snd88_Sfx1_628F
	SND_CALL Snd88_Sfx1_628F

Snd88_Ch1:
	SND_END
Snd88_Sfx1_628F:
	DUTY_STEP 0, 12
	OCTAVE 5
	NOTE G_, 4
	DUTY_STEP 0, 0
	ATTEN 3
	RELEASE $0F, 4
	NOTE G_, 1
	SND_RET

Snd88_Sfx2:
	VOICE $50, 1, 2, 10, 4
	REST 3
	LEN_UNIT $55
	REST 3
	LEN_UNIT 6
	VIBRATO $01, 0, 1
	OCTAVE 6
	NOTE C_, 1
	VOLUME $06
	LEN_UNIT 3
	RELEASE 8, 6
	LOOP_START
	NOTE C_, 1
	LOOP_END $0A
	SND_END

Snd8C_Sfx1:
	RAW_VOICE $01, $04, $08
	LOOP_START
	RAW_NOTE 15, $779
	RAW_NOTE 15, $778
	LOOP_END 8
	LEN_UNIT $0E
	DUTY 8
	RAW_NOTE 15, $77C
	RAW_NOTE 10, $77B
	RAW_NOTE 8, $77C
	LEN_UNIT 4
	RAW_NOTE 9, $77D
	RAW_NOTE 7, $77E
	RAW_NOTE 9, $77F
	RAW_NOTE 7, $780
	LEN_UNIT 1
	DUTY $0C
	RAW_NOTE 9, $79D
	RAW_NOTE 15, $7A4
	RAW_NOTE 10, $79F
	RAW_NOTE 15, $7A3
	RAW_NOTE 11, $7A3
	RAW_NOTE 15, $7A0
	RAW_NOTE 13, $7A2
	RAW_NOTE 15, $7A1
	RAW_NOTE 15, $7A2
	RAW_NOTE 15, $7A3
	DUTY 0
	LOOP_START
	RAW_NOTE 15, $7A6
	RAW_NOTE 15, $7A4
	LOOP_END 8
	LOOP_START
	RAW_NOTE 15, $7A7
	RAW_NOTE 15, $7A5
	LOOP_END 3
	LOOP_START
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7A7
	LOOP_END 2
	LOOP_START
	RAW_NOTE 15, $7AA
	RAW_NOTE 15, $79F
	LOOP_END 4
	RAW_NOTE 15, $7AC
	RAW_NOTE 15, $79C
	RAW_NOTE 13, $784
	RAW_NOTE 10, $C9D
	LEN_UNIT 6
	RAW_REST
	LEN_UNIT 1
	DUTY 4
	RAW_NOTE 9, $796
	RAW_NOTE 15, $79E
	RAW_NOTE 10, $799
	RAW_NOTE 15, $79E
	RAW_NOTE 11, $79B
	RAW_NOTE 15, $79F
	RAW_NOTE 13, $79E
	RAW_NOTE 15, $79F
	RAW_NOTE 15, $79F
	RAW_NOTE 15, $7A1
	DUTY 8
	RAW_MARK
	LOOP_START
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $79F
	LOOP_END 5
	RAW_REPEAT 3, $00, $01
	RAW_NOTE 13, $7A8
	RAW_NOTE 10, $7A1
	RAW_NOTE 10, $7A7
	RAW_NOTE 10, $2A5
	RAW_NOTE 10, $79F
	RAW_NOTE 9, $7A7
	RAW_NOTE 8, $7A1
	RAW_NOTE 6, $7A8
	RAW_NOTE 7, $7A1
	RAW_NOTE 4, $7A6
	RAW_NOTE 5, $7A1
	RAW_NOTE 3, $7A4
	RAW_NOTE 6, $7A1
	RAW_NOTE 2, $7A1
	LEN_UNIT $42
	RAW_REST
	LEN_UNIT 1
	DUTY 4
	RAW_NOTE 9, $795
	RAW_NOTE 15, $7A2
	RAW_NOTE 10, $797
	RAW_NOTE 15, $7A0
	RAW_NOTE 11, $79B
	RAW_NOTE 15, $7A4
	RAW_NOTE 13, $79C
	RAW_NOTE 15, $79F
	RAW_NOTE 15, $79F
	RAW_NOTE 15, $7A1
	DUTY 8
	RAW_MARK
	LOOP_START
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $7A2
	LOOP_END $1A
	RAW_REPEAT 4, $00, $FF
	RAW_MARK
	LOOP_START
	RAW_NOTE 13, $7A1
	RAW_NOTE 13, $79F
	LOOP_END $10
	RAW_REPEAT 4, $FF, $FF
	RAW_MARK
	LOOP_START
	RAW_NOTE 9, $79D
	RAW_NOTE 9, $79B
	LOOP_END $10
	RAW_REPEAT 8, $FF, $FF
	SND_END

Snd8D_Sfx1:
	RAW_VOICE $01, $00, $08
	LOOP_START
	RAW_NOTE 15, $7E0
	RAW_NOTE 13, $7DC
	RAW_NOTE 12, $7D8
	RAW_NOTE 10, $7D4
	RAW_NOTE 8, $7D0
	RAW_NOTE 6, $7CC
	RAW_NOTE 4, $7C8
	RAW_NOTE 2, $7C4
	RAW_NOTE 15, $7D0
	RAW_NOTE 13, $7CC
	RAW_NOTE 12, $7C8
	RAW_NOTE 10, $7C4
	RAW_NOTE 8, $7C0
	RAW_NOTE 6, $7BC
	RAW_NOTE 4, $7B8
	RAW_NOTE 2, $7B4
	LOOP2_START
	RAW_REST
	LOOP2_END $0C
	LOOP_END 3
	SND_END

Snd3A_Sfx1:
	RAW_VOICE $03, $C0, $08
Snd3A_Sfx1_63C8:
	RAW_NOTE 15, $720
	RAW_NOTE 15, $724
	RAW_NOTE 15, $728
	RAW_NOTE 15, $72C
	RAW_NOTE 15, $730
	RAW_NOTE 15, $72C
	RAW_NOTE 15, $728
	RAW_NOTE 15, $724
	RAW_NOTE 15, $720
	RAW_MARK
	RAW_NOTE 12, $720
	RAW_NOTE 12, $724
	RAW_NOTE 12, $728
	RAW_NOTE 12, $72C
	RAW_NOTE 12, $730
	RAW_NOTE 12, $72C
	RAW_NOTE 12, $728
	RAW_NOTE 12, $724
	RAW_NOTE 12, $720
	RAW_REPEAT 3, $FC, $00
	RAW_NOTE 2, $720
	RAW_NOTE 2, $724
	RAW_NOTE 2, $728
	RAW_NOTE 2, $72C
	RAW_NOTE 2, $730
	RAW_NOTE 2, $72C
	RAW_NOTE 2, $728
	RAW_NOTE 2, $724
	RAW_NOTE 2, $720
	SND_END

Snd3B_Sfx1:
	RAW_VOICE $0A, $C0, $08
	RAW_MARK
	RAW_NOTE 4, $680
	RAW_NOTE 4, $600
	RAW_REPEAT 5, $02, $08
	RAW_NOTE 15, $6A8
	RAW_NOTE 15, $628
	RAW_NOTE 12, $6B0
	RAW_NOTE 12, $630
	RAW_NOTE 8, $6B8
	RAW_NOTE 8, $638
	RAW_NOTE 4, $6C0
	RAW_NOTE 4, $640
	RAW_NOTE 2, $6D0
	RAW_NOTE 2, $650
	RAW_NOTE 1, $6E0
	RAW_NOTE 1, $660
	SND_END

Snd3C_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $780
	RAW_REPEAT 6, $00, $A0
	LOOP_START
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	LOOP_END 3
	LEN_UNIT 3
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_REPEAT 3, $FE, $00
	LEN_UNIT 4
	RAW_MARK
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_REPEAT 3, $FE, $00
	LOOP_START
	RAW_NOTE 1, $700
	RAW_NOTE 1, $600
	LOOP_END 3
	SND_END

Snd3D_Sfx1:
	RAW_VOICE $01, $00, $08
	RAW_MARK
	RAW_NOTE 15, $680
	RAW_NOTE 15, $740
	RAW_NOTE 15, $680
	RAW_NOTE 15, $740
	RAW_NOTE 15, $680
	RAW_NOTE 15, $740
	LOOP_START
	RAW_REST
	LOOP_END 8
	RAW_REPEAT 7, $00, $08
	RAW_NOTE 15, $6B8
	RAW_NOTE 15, $778
	RAW_NOTE 15, $6B8
	RAW_NOTE 15, $778
	RAW_NOTE 15, $6B8
	RAW_NOTE 15, $778
	SND_END

Snd3E_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 15, $17
	NOISE_HOLD 14, $16
	NOISE_HOLD 15, $15
	NOISE_HOLD 14, $14
	NOISE_HOLD 15, $13
	NOISE_HOLD 14, $12
	NOISE_HOLD 15, $11
	NOISE_HOLD 12, $17
	NOISE_HOLD 11, $16
	NOISE_HOLD 12, $15
	NOISE_HOLD 11, $14
	NOISE_HOLD 12, $13
	NOISE_HOLD 11, $12
	NOISE_HOLD 12, $11
	NOISE_HOLD 10, $17
	NOISE_HOLD 9, $16
	NOISE_HOLD 10, $15
	NOISE_HOLD 9, $14
	NOISE_HOLD 10, $13
	NOISE_HOLD 9, $12
	NOISE_HOLD 10, $11
	NOISE_HOLD 8, $17
	NOISE_HOLD 7, $16
	NOISE_HOLD 8, $15
	NOISE_HOLD 7, $14
	NOISE_HOLD 8, $13
	NOISE_HOLD 7, $12
	NOISE_HOLD 8, $11
	NOISE_HOLD 6, $17
	NOISE_HOLD 5, $16
	NOISE_HOLD 6, $15
	NOISE_HOLD 5, $14
	NOISE_HOLD 6, $13
	NOISE_HOLD 5, $12
	NOISE_HOLD 6, $11
	NOISE_HOLD 4, $17
	NOISE_HOLD 3, $16
	NOISE_HOLD 4, $15
	NOISE_HOLD 3, $14
	NOISE_HOLD 4, $13
	NOISE_HOLD 3, $12
	NOISE_HOLD 4, $11
	NOISE_HOLD 2, $17
	NOISE_HOLD 1, $16
	NOISE_HOLD 2, $15
	NOISE_HOLD 1, $14
	NOISE_HOLD 2, $13
	NOISE_HOLD 1, $12
	NOISE_HOLD 2, $11
	SND_END

Snd3F_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $500
	RAW_NOTE 15, $700
	RAW_NOTE 15, $500
	RAW_NOTE 15, $700
	RAW_NOTE 15, $500
	RAW_REPEAT 3, $FF, $10
	RAW_MARK
	RAW_NOTE 12, $730
	RAW_NOTE 12, $530
	RAW_NOTE 12, $730
	RAW_NOTE 12, $530
	RAW_NOTE 12, $730
	RAW_NOTE 12, $530
	RAW_REPEAT 6, $FE, $10
	SND_END

Snd5B_Sfx1:
	RAW_VOICE $02, $80, $08
	LOOP2_START
	RAW_NOTE 15, $780
	RAW_NOTE 15, $780
	RAW_NOTE 15, $780
	RAW_NOTE 15, $780
	RAW_NOTE 15, $780
	RAW_NOTE 12, $780
	RAW_NOTE 12, $780
	RAW_NOTE 12, $780
	RAW_NOTE 12, $780
	RAW_NOTE 12, $780
	LOOP_START
	RAW_NOTE 15, $7B0
	LOOP_END $0F
	LOOP_START
	RAW_NOTE 12, $7B0
	LOOP_END 5
	LOOP2_END 3

Snd40_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_MARK
	RAW_NOTE 8, $700
	RAW_NOTE 8, $708
	RAW_NOTE 8, $710
	RAW_NOTE 8, $718
	RAW_NOTE 8, $720
	RAW_REPEAT 3, $02, $28
	RAW_NOTE 15, $778
	RAW_NOTE 15, $780
	RAW_NOTE 15, $788
	RAW_NOTE 15, $790
	RAW_NOTE 15, $798
	LEN_UNIT 3
	RAW_NOTE 15, $720
	RAW_NOTE 15, $724
	RAW_NOTE 15, $728
	RAW_NOTE 15, $72C
	RAW_NOTE 15, $730
	RAW_NOTE 15, $72C
	RAW_NOTE 15, $728
	RAW_NOTE 15, $724
	RAW_NOTE 15, $720
	RAW_MARK
	RAW_NOTE 12, $720
	RAW_NOTE 12, $724
	RAW_NOTE 12, $728
	RAW_NOTE 12, $72C
	RAW_NOTE 12, $730
	RAW_NOTE 12, $72C
	RAW_NOTE 12, $728
	RAW_NOTE 12, $724
	RAW_NOTE 12, $720
	RAW_REPEAT 3, $FC, $00
	RAW_NOTE 2, $720
	RAW_NOTE 2, $724
	RAW_NOTE 2, $728
	RAW_NOTE 2, $72C
	RAW_NOTE 2, $730
	RAW_NOTE 2, $72C
	RAW_NOTE 2, $728
	RAW_NOTE 2, $724
	RAW_NOTE 2, $720
	SND_END

Snd41_SfxN:
	NVOICE_HOLD $0C
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $35
	NOISE_HOLD 12, $55
	NOISE_HOLD 12, $35
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $45
	NOISE_HOLD 6, $46
	NOISE_HOLD 6, $45
	SND_END

Snd41_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_REPEAT 5, $FD, $00
	SND_END

Snd42_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 8, $5C0
	RAW_NOTE 8, $5E0
	RAW_NOTE 8, $600
	RAW_NOTE 8, $620
	RAW_NOTE 8, $640
	RAW_REPEAT 8, $01, $20
	RAW_MARK
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $700
	RAW_NOTE 15, $720
	RAW_NOTE 15, $740
	RAW_REPEAT 4, $00, $20
	SND_END

Snd5E_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_REPEAT 5, $00, $10
	RAW_MARK
	RAW_NOTE 12, $6F0
	RAW_NOTE 12, $5F0
	RAW_REPEAT 5, $00, $10
	RAW_MARK
	RAW_NOTE 10, $6E0
	RAW_NOTE 10, $5E0
	RAW_REPEAT 5, $00, $10
	RAW_MARK
	RAW_NOTE 8, $6D0
	RAW_NOTE 8, $5D0
	RAW_REPEAT 5, $00, $10
	RAW_MARK
	RAW_NOTE 6, $6C0
	RAW_NOTE 6, $5C0
	RAW_REPEAT 5, $00, $10
	RAW_MARK
	RAW_NOTE 4, $6B0
	RAW_NOTE 4, $5B0
	RAW_REPEAT 5, $00, $10
	SND_END

Snd43_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $740
	RAW_NOTE 15, $6C0
	RAW_REPEAT 9, $00, $F8
	RAW_MARK
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $670
	RAW_REPEAT 10, $00, $F0
	RAW_MARK
	RAW_NOTE 15, $780
	RAW_NOTE 15, $700
	RAW_REPEAT 5, $00, $F0
	RAW_MARK
	RAW_NOTE 15, $720
	RAW_NOTE 15, $6A0
	RAW_REPEAT 5, $00, $E0
	LEN_UNIT 2
	DUTY $0C
	RAW_MARK
	RAW_NOTE 5, $680
	RAW_REPEAT 9, $01, $20
	RAW_NOTE 15, $790
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7C0
	RAW_MARK
	RAW_NOTE 12, $7C8
	RAW_REPEAT 5, $FE, $08
	SND_END

Snd44_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $780
	RAW_REPEAT 17, $00, $04
	LEN_UNIT $0C
	LOOP_START
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7D0
	LOOP_END 3
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7B0
	LEN_UNIT $10
	RAW_NOTE 15, $7C0
	RAW_NOTE 12, $7C0
	RAW_NOTE 10, $7C0
	RAW_NOTE 8, $7C0
	RAW_NOTE 6, $7C0
	RAW_NOTE 4, $7C0
	RAW_NOTE 2, $7C0
	RAW_NOTE 1, $7C0
	SND_END

Snd45_Sfx1:
	RAW_VOICE $02, $00, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $6D0
	RAW_REPEAT 3, $FD, $C0
	RAW_NOTE 7, $640
	RAW_NOTE 7, $648
	RAW_NOTE 7, $650
	RAW_NOTE 7, $658
	RAW_NOTE 8, $660
	RAW_NOTE 8, $668
	RAW_NOTE 8, $670
	RAW_NOTE 8, $678
	LEN_UNIT 4
	RAW_NOTE 9, $680
	RAW_NOTE 9, $690
	RAW_NOTE 9, $6A0
	RAW_NOTE 9, $6B0
	RAW_NOTE 10, $6C0
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $6E0
	RAW_NOTE 10, $6F0
	LEN_UNIT 8
	RAW_NOTE 12, $700
	RAW_NOTE 12, $710
	RAW_NOTE 12, $720
	RAW_NOTE 12, $730
	RAW_NOTE 15, $740
	RAW_NOTE 15, $750
	RAW_NOTE 15, $760
	RAW_NOTE 15, $770
	LEN_UNIT $0C
	RAW_NOTE 15, $780
	RAW_NOTE 15, $790
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7B0
	RAW_MARK
	RAW_NOTE 12, $780
	RAW_NOTE 12, $790
	RAW_NOTE 12, $7A0
	RAW_NOTE 12, $7B0
	RAW_REPEAT 6, $FE, $00
	SND_END

Snd46_Sfx1:
	RAW_VOICE $04, $C0, $08
	RAW_NOTE 10, $700
	RAW_NOTE 10, $600
	RAW_NOTE 10, $704
	RAW_NOTE 10, $604
	RAW_NOTE 10, $708
	RAW_NOTE 10, $608
	RAW_NOTE 10, $70C
	RAW_NOTE 10, $60C
	RAW_NOTE 12, $780
	RAW_NOTE 12, $680
	RAW_NOTE 12, $784
	RAW_NOTE 12, $684
	RAW_NOTE 12, $788
	RAW_NOTE 12, $688
	RAW_NOTE 12, $78C
	RAW_NOTE 12, $68C
	LOOP_START
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $704
	RAW_NOTE 15, $604
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_NOTE 15, $70C
	RAW_NOTE 15, $60C
	RAW_NOTE 15, $780
	RAW_NOTE 15, $680
	RAW_NOTE 15, $784
	RAW_NOTE 15, $684
	RAW_NOTE 15, $788
	RAW_NOTE 15, $688
	RAW_NOTE 15, $78C
	RAW_NOTE 15, $68C
	LOOP_END 6
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $600
	RAW_NOTE 12, $704
	RAW_NOTE 12, $604
	RAW_NOTE 12, $708
	RAW_NOTE 12, $608
	RAW_NOTE 12, $70C
	RAW_NOTE 12, $60C
	RAW_NOTE 12, $780
	RAW_NOTE 12, $680
	RAW_NOTE 12, $784
	RAW_NOTE 12, $684
	RAW_NOTE 12, $788
	RAW_NOTE 12, $688
	RAW_NOTE 12, $78C
	RAW_NOTE 12, $68C
	RAW_REPEAT 6, $FE, $00
	SND_END

Snd46_Sfx2:
	RAW_VOICE $04, $50, $00
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_NOTE 6, $704
	RAW_NOTE 6, $604
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $70C
	RAW_NOTE 4, $60C
	RAW_NOTE 2, $780
	RAW_NOTE 2, $680
	RAW_NOTE 2, $784
	RAW_NOTE 2, $684
	RAW_NOTE 2, $788
	RAW_NOTE 2, $688
	RAW_NOTE 2, $78C
	RAW_NOTE 2, $68C
	LOOP_START
	RAW_NOTE 2, $700
	RAW_NOTE 2, $600
	RAW_NOTE 2, $704
	RAW_NOTE 2, $604
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $60C
	RAW_NOTE 2, $780
	RAW_NOTE 2, $680
	RAW_NOTE 2, $784
	RAW_NOTE 2, $684
	RAW_NOTE 2, $788
	RAW_NOTE 2, $688
	RAW_NOTE 2, $78C
	RAW_NOTE 2, $68C
	LOOP_END 6
	RAW_NOTE 2, $700
	RAW_NOTE 2, $600
	RAW_NOTE 2, $704
	RAW_NOTE 2, $604
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $60C
	RAW_NOTE 2, $780
	RAW_NOTE 2, $680
	RAW_NOTE 2, $784
	RAW_NOTE 2, $684
	RAW_NOTE 2, $788
	RAW_NOTE 2, $688
	RAW_NOTE 2, $78C
	RAW_NOTE 2, $68C
	RAW_NOTE 2, $700
	RAW_NOTE 2, $600
	RAW_NOTE 2, $704
	RAW_NOTE 2, $604
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $60C
	RAW_NOTE 2, $780
	RAW_NOTE 2, $680
	RAW_NOTE 2, $784
	RAW_NOTE 2, $684
	RAW_NOTE 2, $788
	RAW_NOTE 2, $688
	RAW_NOTE 2, $78C
	RAW_NOTE 2, $68C
	RAW_NOTE 4, $700
	RAW_NOTE 4, $600
	RAW_NOTE 4, $704
	RAW_NOTE 4, $604
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $70C
	RAW_NOTE 4, $60C
	RAW_NOTE 4, $780
	RAW_NOTE 4, $680
	RAW_NOTE 4, $784
	RAW_NOTE 4, $684
	RAW_NOTE 4, $788
	RAW_NOTE 4, $688
	RAW_NOTE 4, $78C
	RAW_NOTE 4, $68C
	RAW_NOTE 4, $700
	RAW_NOTE 4, $600
	RAW_NOTE 4, $704
	RAW_NOTE 4, $604
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $70C
	RAW_NOTE 4, $60C
	RAW_NOTE 4, $780
	RAW_NOTE 4, $680
	RAW_NOTE 4, $784
	RAW_NOTE 4, $684
	RAW_NOTE 4, $788
	RAW_NOTE 4, $688
	RAW_NOTE 4, $78C
	RAW_NOTE 4, $68C
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_NOTE 6, $704
	RAW_NOTE 6, $604
	RAW_NOTE 6, $708
	RAW_NOTE 6, $608
	RAW_NOTE 6, $70C
	RAW_NOTE 6, $60C
	RAW_NOTE 6, $780
	RAW_NOTE 6, $680
	RAW_NOTE 6, $784
	RAW_NOTE 6, $684
	RAW_NOTE 6, $788
	RAW_NOTE 6, $688
	RAW_NOTE 6, $78C
	RAW_NOTE 6, $68C
	RAW_NOTE 6, $700
	RAW_NOTE 6, $600
	RAW_NOTE 6, $704
	RAW_NOTE 6, $604
	RAW_NOTE 6, $708
	RAW_NOTE 6, $608
	RAW_NOTE 6, $70C
	RAW_NOTE 6, $60C
	RAW_NOTE 6, $780
	RAW_NOTE 6, $680
	RAW_NOTE 6, $784
	RAW_NOTE 6, $684
	RAW_NOTE 6, $788
	RAW_NOTE 6, $688
	RAW_NOTE 6, $78C
	RAW_NOTE 6, $68C
	SND_END

Snd46_SfxN:
	NVOICE_HOLD $20
	NOISE_HOLD 10, $4B
	NOISE_HOLD 10, $4A
	NOISE_HOLD 10, $49
	NOISE_HOLD 10, $48
	NOISE_HOLD 9, $4B
	NOISE_HOLD 9, $4A
	NOISE_HOLD 9, $49
	NOISE_HOLD 9, $48
	NOISE_HOLD 8, $4B
	NOISE_HOLD 8, $4A
	NOISE_HOLD 8, $49
	NOISE_HOLD 8, $48
	NOISE_HOLD 7, $4B
	NOISE_HOLD 7, $4A
	NOISE_HOLD 7, $49
	NOISE_HOLD 7, $48
	NOISE_HOLD 6, $4B
	NOISE_HOLD 6, $4A
	NOISE_HOLD 6, $49
	NOISE_HOLD 6, $48
	NOISE_HOLD 4, $4B
	NOISE_HOLD 4, $4A
	NOISE_HOLD 4, $49
	NOISE_HOLD 4, $48
	NOISE_HOLD 1, $4B
	NOISE_HOLD 1, $4A
	NOISE_HOLD 1, $49
	NOISE_HOLD 1, $48
	SND_END

Snd46_Ch1:
	SND_END

Snd48_Sfx1:
	RAW_VOICE $02, $C0, $08
	LOOP_START
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $680
	RAW_NOTE 15, $640
	RAW_NOTE 12, $600
	RAW_NOTE 12, $5C0
	RAW_NOTE 10, $580
	RAW_NOTE 10, $540
	RAW_NOTE 8, $500
	RAW_NOTE 8, $4C0
	RAW_NOTE 6, $480
	RAW_NOTE 6, $440
	RAW_REPEAT 2, $00, $80
	LOOP_END $0A
	SND_END

Snd48_SfxN:
	NVOICE_HOLD $02
	LOOP_START
	NOISE_HOLD 6, $53
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $53
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $53
	LOOP_END $2E
	LEN_UNIT 8
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 13, $54
	NOISE_HOLD 13, $54
	NOISE_HOLD 13, $54
	NOISE_HOLD 13, $54
	NOISE_HOLD 13, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 11, $54
	NOISE_HOLD 11, $54
	NOISE_HOLD 11, $54
	NOISE_HOLD 11, $54
	NOISE_HOLD 11, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	SND_END

Snd49_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 4, $6C0
	RAW_NOTE 4, $5C0
	RAW_NOTE 4, $6C0
	RAW_NOTE 4, $5C0
	RAW_REPEAT 6, $01, $02
	RAW_NOTE 9, $6CC
	RAW_NOTE 9, $5CC
	RAW_NOTE 9, $6CC
	RAW_NOTE 9, $5CC
	RAW_NOTE 9, $6CE
	RAW_NOTE 9, $5CE
	RAW_NOTE 9, $6CE
	RAW_NOTE 9, $5CE
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $5D0
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $5D0
	RAW_NOTE 10, $6D4
	RAW_NOTE 10, $5D4
	RAW_NOTE 10, $6D4
	RAW_NOTE 10, $5D4
	RAW_MARK
	RAW_NOTE 11, $6D8
	RAW_NOTE 11, $5D8
	RAW_NOTE 11, $6D8
	RAW_NOTE 11, $5D8
	RAW_NOTE 11, $6DC
	RAW_NOTE 11, $5DC
	RAW_NOTE 11, $6DC
	RAW_NOTE 11, $5DC
	RAW_REPEAT 3, $01, $08
	RAW_MARK
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $5F0
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $5F0
	RAW_REPEAT 6, $00, $04
	LEN_UNIT 2
	RAW_MARK
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_REPEAT 7, $00, $04
	RAW_MARK
	RAW_NOTE 12, $708
	RAW_NOTE 12, $608
	RAW_NOTE 12, $708
	RAW_NOTE 12, $608
	RAW_REPEAT 7, $00, $04
	RAW_MARK
	RAW_NOTE 10, $708
	RAW_NOTE 10, $608
	RAW_NOTE 10, $708
	RAW_NOTE 10, $608
	RAW_REPEAT 7, $00, $04
	RAW_MARK
	RAW_NOTE 8, $708
	RAW_NOTE 8, $608
	RAW_NOTE 8, $708
	RAW_NOTE 8, $608
	RAW_REPEAT 7, $00, $04
	RAW_MARK
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_REPEAT 7, $00, $04
	RAW_MARK
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_REPEAT 7, $00, $04
	SND_END

Snd49_Sfx2:
	RAW_VOICE $01, $50, $00
	RAW_NOTE 6, $6C0
	RAW_NOTE 6, $5C0
	RAW_NOTE 6, $6C0
	RAW_NOTE 6, $5C0
	RAW_NOTE 6, $6C2
	RAW_NOTE 6, $5C2
	RAW_NOTE 6, $6C2
	RAW_NOTE 6, $5C2
	RAW_NOTE 6, $6C4
	RAW_NOTE 6, $5C4
	RAW_NOTE 6, $6C4
	RAW_NOTE 6, $5C4
	RAW_NOTE 6, $6C6
	RAW_NOTE 6, $5C6
	RAW_NOTE 6, $6C6
	RAW_NOTE 6, $5C6
	RAW_NOTE 6, $6C8
	RAW_NOTE 6, $5C8
	RAW_NOTE 6, $6C8
	RAW_NOTE 6, $5C8
	RAW_NOTE 4, $6CA
	RAW_NOTE 4, $5CA
	RAW_NOTE 4, $6CA
	RAW_NOTE 4, $5CA
	RAW_NOTE 4, $6CC
	RAW_NOTE 4, $5CC
	RAW_NOTE 4, $6CC
	RAW_NOTE 4, $5CC
	RAW_NOTE 4, $6CE
	RAW_NOTE 4, $5CE
	RAW_NOTE 4, $6CE
	RAW_NOTE 4, $5CE
	RAW_NOTE 4, $6D0
	RAW_NOTE 4, $5D0
	RAW_NOTE 4, $6D0
	RAW_NOTE 4, $5D0
	RAW_NOTE 6, $6D4
	RAW_NOTE 6, $5D4
	RAW_NOTE 6, $6D4
	RAW_NOTE 6, $5D4
	RAW_NOTE 6, $6D8
	RAW_NOTE 6, $5D8
	RAW_NOTE 6, $6D8
	RAW_NOTE 6, $5D8
	RAW_NOTE 6, $6DC
	RAW_NOTE 6, $5DC
	RAW_NOTE 6, $6DC
	RAW_NOTE 6, $5DC
	RAW_NOTE 6, $6E0
	RAW_NOTE 6, $5E0
	RAW_NOTE 6, $6E0
	RAW_NOTE 6, $5E0
	RAW_NOTE 6, $6E4
	RAW_NOTE 6, $5E4
	RAW_NOTE 6, $6E4
	RAW_NOTE 6, $5E4
	RAW_NOTE 6, $6E8
	RAW_NOTE 6, $5E8
	RAW_NOTE 6, $6E8
	RAW_NOTE 6, $5E8
	RAW_NOTE 6, $6EC
	RAW_NOTE 6, $5EC
	RAW_NOTE 6, $6EC
	RAW_NOTE 6, $5EC
	RAW_NOTE 2, $6F0
	RAW_NOTE 2, $5F0
	RAW_NOTE 2, $6F0
	RAW_NOTE 2, $5F0
	RAW_NOTE 2, $6F4
	RAW_NOTE 2, $5F4
	RAW_NOTE 2, $6F4
	RAW_NOTE 2, $5F4
	RAW_NOTE 2, $6F8
	RAW_NOTE 2, $5F8
	RAW_NOTE 2, $6F8
	RAW_NOTE 2, $5F8
	RAW_NOTE 2, $6FC
	RAW_NOTE 2, $5FC
	RAW_NOTE 2, $6FC
	RAW_NOTE 2, $5FC
	RAW_NOTE 2, $700
	RAW_NOTE 2, $600
	RAW_NOTE 2, $700
	RAW_NOTE 2, $600
	RAW_NOTE 2, $704
	RAW_NOTE 2, $604
	RAW_NOTE 2, $704
	RAW_NOTE 2, $604
	LEN_UNIT 2
	LOOP_START
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $708
	RAW_NOTE 2, $608
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $60C
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $60C
	RAW_NOTE 2, $710
	RAW_NOTE 2, $610
	RAW_NOTE 2, $710
	RAW_NOTE 2, $610
	RAW_NOTE 2, $714
	RAW_NOTE 2, $614
	RAW_NOTE 2, $714
	RAW_NOTE 2, $614
	RAW_NOTE 2, $718
	RAW_NOTE 2, $618
	RAW_NOTE 2, $718
	RAW_NOTE 2, $618
	RAW_NOTE 2, $71C
	RAW_NOTE 2, $61C
	RAW_NOTE 2, $71C
	RAW_NOTE 2, $61C
	RAW_NOTE 2, $720
	RAW_NOTE 2, $620
	RAW_NOTE 2, $720
	RAW_NOTE 2, $620
	LOOP_END 2
	LOOP_START
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $708
	RAW_NOTE 4, $608
	RAW_NOTE 4, $70C
	RAW_NOTE 4, $60C
	RAW_NOTE 4, $70C
	RAW_NOTE 4, $60C
	RAW_NOTE 4, $710
	RAW_NOTE 4, $610
	RAW_NOTE 4, $710
	RAW_NOTE 4, $610
	RAW_NOTE 4, $714
	RAW_NOTE 4, $614
	RAW_NOTE 4, $714
	RAW_NOTE 4, $614
	RAW_NOTE 4, $718
	RAW_NOTE 4, $618
	RAW_NOTE 4, $718
	RAW_NOTE 4, $618
	RAW_NOTE 4, $71C
	RAW_NOTE 4, $61C
	RAW_NOTE 4, $71C
	RAW_NOTE 4, $61C
	RAW_NOTE 4, $720
	RAW_NOTE 4, $620
	RAW_NOTE 4, $720
	RAW_NOTE 4, $620
	LOOP_END 2
	LOOP_START
	RAW_NOTE 6, $708
	RAW_NOTE 6, $608
	RAW_NOTE 6, $708
	RAW_NOTE 6, $608
	RAW_NOTE 6, $70C
	RAW_NOTE 6, $60C
	RAW_NOTE 6, $70C
	RAW_NOTE 6, $60C
	RAW_NOTE 6, $710
	RAW_NOTE 6, $610
	RAW_NOTE 6, $710
	RAW_NOTE 6, $610
	RAW_NOTE 6, $714
	RAW_NOTE 6, $614
	RAW_NOTE 6, $714
	RAW_NOTE 6, $614
	RAW_NOTE 6, $718
	RAW_NOTE 6, $618
	RAW_NOTE 6, $718
	RAW_NOTE 6, $618
	RAW_NOTE 6, $71C
	RAW_NOTE 6, $61C
	RAW_NOTE 6, $71C
	RAW_NOTE 6, $61C
	RAW_NOTE 6, $720
	RAW_NOTE 6, $620
	RAW_NOTE 6, $720
	RAW_NOTE 6, $620
	LOOP_END 2
	SND_END

Snd4A_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	SND_END

Snd4B_Sfx1:
	RAW_VOICE $02, $C0, $08
	LOOP2_START
	LOOP_START
	RAW_NOTE 15, $700
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $680
	RAW_NOTE 15, $640
	RAW_NOTE 12, $600
	RAW_NOTE 12, $5C0
	RAW_NOTE 10, $580
	RAW_NOTE 10, $540
	RAW_NOTE 15, $680
	RAW_NOTE 15, $640
	RAW_NOTE 15, $600
	RAW_NOTE 15, $5C0
	RAW_NOTE 12, $580
	RAW_NOTE 12, $540
	RAW_NOTE 10, $500
	RAW_NOTE 10, $4C0
	LOOP_END 2
	LOOP2_END 7
	SND_END

Snd4B_SfxN:
	NVOICE_HOLD $0C
	LOOP_START
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $54
	NOISE_HOLD 12, $55
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $55
	NOISE_HOLD 12, $54
	LOOP_END 3
	NOISE_HOLD 10, $55
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $55
	NOISE_HOLD 10, $54
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $54
	NOISE_HOLD 6, $55
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $55
	NOISE_HOLD 6, $54
	NOISE_HOLD 4, $55
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $55
	NOISE_HOLD 4, $54
	NOISE_HOLD 3, $55
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $55
	NOISE_HOLD 3, $54
	NOISE_HOLD 2, $55
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $55
	NOISE_HOLD 2, $54
	NOISE_HOLD 1, $55
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $55
	NOISE_HOLD 1, $54
	SND_END

Snd4C_Sfx1:
	RAW_VOICE $01, $C0, $08
	LOOP_START
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7D9
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7D9
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7D9
	RAW_NOTE 13, $7D8
	RAW_NOTE 13, $7D9
	RAW_NOTE 13, $7D8
	RAW_NOTE 13, $7D9
	RAW_NOTE 13, $7D8
	RAW_NOTE 13, $7D9
	RAW_MARK
	RAW_NOTE 12, $7D8
	RAW_NOTE 12, $7D9
	RAW_NOTE 11, $7D8
	RAW_NOTE 11, $7D9
	RAW_NOTE 10, $7D8
	RAW_NOTE 10, $7D9
	RAW_REPEAT 4, $FD, $00
	RAW_REST
	RAW_REST
	RAW_REST
	RAW_REST
	RAW_REST
	RAW_REST
	LOOP_END 2
	SND_END

Snd4C_SfxN:
	NVOICE_HOLD $40
	NOISE_REST
	LEN_UNIT 8
	NOISE_HOLD 15, $17
	LEN_UNIT $14
	NOISE_HOLD 15, $11
	NOISE_HOLD 15, $11
	NOISE_HOLD 15, $11
	NOISE_HOLD 12, $11
	NOISE_HOLD 10, $11
	NOISE_HOLD 8, $11
	NOISE_HOLD 6, $11
	NOISE_HOLD 4, $11
	LEN_UNIT 4
	LOOP_START
	NOISE_HOLD 15, $04
	NOISE_HOLD 15, $09
	NOISE_REST
	NOISE_REST
	NOISE_HOLD 15, $04
	NOISE_HOLD 15, $0A
	NOISE_REST
	NOISE_REST
	LOOP_END $28
	SND_END

Snd4D_Sfx1:
	RAW_VOICE $01, $C0, $08
	LOOP2_START
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	LOOP_START
	RAW_REST
	LOOP_END 4
	LOOP2_END 5
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
Snd4D_Sfx1_6D90:
	LEN_UNIT 2
	DUTY 8
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_REPEAT 4, $FF, $00
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_REPEAT 14, $FF, $00
	SND_END

Snd4D_SfxN:
	NVOICE_HOLD $32
	NOISE_REST
Snd4D_SfxN_6DBA:
	LEN_UNIT 2
	LOOP_START
	NOISE_HOLD 15, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 12, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 10, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 8, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 6, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 4, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 3, $34
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 2, $34
	LOOP_END 5
	SND_END

Snd4E_Sfx1:
	RAW_VOICE $08, $80, $08
	LOOP_START
	RAW_NOTE 15, $680
	RAW_NOTE 15, $6A0
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $700
	RAW_REST
	RAW_REST
	RAW_REST
	LOOP_END 7
	SND_END

Snd4F_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $43
	NOISE_HOLD 12, $44
	NOISE_HOLD 12, $43
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $43
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $43
	NOISE_HOLD 6, $44
	NOISE_HOLD 6, $43
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $43
	NOISE_HOLD 2, $44
	NOISE_HOLD 2, $43
	SND_END

Snd50_Sfx1:
	RAW_VOICE $03, $80, $08
	RAW_NOTE 11, $700
	RAW_NOTE 12, $710
	RAW_NOTE 13, $720
	RAW_NOTE 15, $730
	RAW_NOTE 13, $720
	RAW_NOTE 12, $710
	RAW_NOTE 11, $700
	RAW_MARK
	RAW_NOTE 10, $700
	RAW_NOTE 11, $710
	RAW_NOTE 12, $720
	RAW_NOTE 13, $730
	RAW_NOTE 12, $720
	RAW_NOTE 11, $710
	RAW_NOTE 10, $700
	RAW_REPEAT 5, $FF, $00
	SND_END

Snd51_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $704
	RAW_NOTE 15, $708
	RAW_NOTE 15, $70C
	RAW_NOTE 15, $710
	RAW_NOTE 15, $70C
	RAW_NOTE 15, $708
	RAW_NOTE 15, $704
	RAW_NOTE 15, $700
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $704
	RAW_NOTE 12, $708
	RAW_NOTE 12, $70C
	RAW_NOTE 12, $710
	RAW_NOTE 12, $70C
	RAW_NOTE 12, $708
	RAW_NOTE 12, $704
	RAW_NOTE 12, $700
	RAW_REPEAT 3, $FC, $00
	RAW_NOTE 2, $700
	RAW_NOTE 2, $704
	RAW_NOTE 2, $708
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $710
	RAW_NOTE 2, $70C
	RAW_NOTE 2, $708
	RAW_NOTE 2, $704
	RAW_NOTE 2, $700
	SND_END

Snd51_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $44
	NOISE_HOLD 12, $44
	NOISE_HOLD 12, $44
	NOISE_HOLD 12, $44
	NOISE_HOLD 12, $44
	NOISE_HOLD 12, $44
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $44
	NOISE_HOLD 10, $44
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $44
	NOISE_HOLD 6, $44
	NOISE_HOLD 6, $44
	NOISE_HOLD 6, $44
	NOISE_HOLD 6, $44
	NOISE_HOLD 6, $44
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $44
	NOISE_HOLD 4, $44
	NOISE_HOLD 3, $44
	NOISE_HOLD 3, $44
	NOISE_HOLD 3, $44
	NOISE_HOLD 3, $44
	NOISE_HOLD 3, $44
	NOISE_HOLD 2, $44
	NOISE_HOLD 2, $44
	NOISE_HOLD 2, $44
	NOISE_HOLD 2, $44
	NOISE_HOLD 2, $44
	SND_END

Snd52_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_NOTE 15, $720
	RAW_NOTE 15, $710
	RAW_MARK
	RAW_NOTE 12, $700
	RAW_NOTE 12, $6F0
	RAW_REPEAT 6, $FE, $E0
	RAW_NOTE 1, $640
	RAW_NOTE 1, $630
	RAW_MARK
	RAW_NOTE 6, $720
	RAW_NOTE 6, $724
	RAW_NOTE 6, $728
	RAW_NOTE 6, $72C
	RAW_NOTE 6, $728
	RAW_NOTE 6, $724
	RAW_NOTE 6, $720
	RAW_REPEAT 5, $FF, $00
	SND_END

Snd52_SfxN:
	NVOICE_HOLD $02
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_HOLD 12, $21
	NOISE_HOLD 10, $31
	NOISE_HOLD 8, $12
	LEN_UNIT $18
	NOISE_HOLD 15, $34
	NOISE_HOLD 12, $30
	NOISE_HOLD 10, $04
	NOISE_HOLD 8, $03
	NOISE_HOLD 6, $02
	NOISE_HOLD 4, $01
	SND_END

Snd53_SfxN:
	NVOICE_HOLD $01
	LOOP2_START
	LOOP_START
	NOISE_HOLD 6, $52
	NOISE_HOLD 6, $42
	LOOP_END $18
	LOOP_START
	NOISE_HOLD 4, $52
	NOISE_HOLD 4, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 3, $52
	NOISE_HOLD 3, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 2, $52
	NOISE_HOLD 2, $42
	LOOP_END 3
	LOOP_START
	NOISE_HOLD 1, $52
	NOISE_HOLD 1, $42
	LOOP_END 3
	LOOP2_END 3
	SND_END

Snd54_Sfx1:
	RAW_VOICE $04, $00, $08
	RAW_MARK
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $6D8
	RAW_NOTE 15, $6E8
	RAW_NOTE 15, $6E0
	RAW_REPEAT 3, $00, $10
	RAW_NOTE 13, $710
	RAW_NOTE 13, $708
	RAW_NOTE 13, $718
	RAW_NOTE 13, $710
	RAW_MARK
	RAW_NOTE 12, $720
	RAW_NOTE 12, $718
	RAW_NOTE 12, $728
	RAW_NOTE 12, $720
	RAW_REPEAT 6, $FE, $10
	RAW_NOTE 1, $780
	RAW_NOTE 1, $778
	RAW_NOTE 1, $788
	RAW_NOTE 1, $780
	SND_END

Snd55_Sfx1:
	RAW_VOICE $02, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_REPEAT 14, $FF, $00
	SND_END

Snd55_SfxN:
	NVOICE_HOLD $0C
	NOISE_HOLD 15, $4D
	NOISE_HOLD 15, $4C
	NOISE_HOLD 12, $4B
	NOISE_HOLD 10, $4A
	NOISE_HOLD 8, $45
	NOISE_HOLD 6, $44
	NOISE_HOLD 4, $43
	NOISE_HOLD 2, $42
	SND_END

Snd56_Sfx1:
	RAW_VOICE $0D, $C0, $08
	RAW_MARK
	RAW_NOTE 4, $7E0
	RAW_NOTE 4, $7DE
	RAW_NOTE 4, $7DC
	RAW_NOTE 4, $7DA
	RAW_NOTE 4, $7D8
	RAW_NOTE 4, $7D6
	RAW_NOTE 4, $7D4
	RAW_NOTE 4, $7D2
	RAW_REPEAT 4, $FF, $F0
	RAW_MARK
	RAW_NOTE 1, $7A0
	RAW_NOTE 1, $79E
	RAW_NOTE 1, $79C
	RAW_NOTE 1, $79A
	RAW_NOTE 1, $798
	RAW_NOTE 1, $796
	RAW_NOTE 1, $794
	RAW_NOTE 1, $792
	RAW_REPEAT 2, $00, $F0
	SND_END

Snd56_SfxN:
	NVOICE_HOLD $18
	LOOP_START
	NOISE_HOLD 8, $12
	NOISE_HOLD 8, $12
	NOISE_HOLD 8, $12
	NOISE_HOLD 8, $12
	LOOP_END 4
	NOISE_HOLD 6, $12
	NOISE_HOLD 6, $12
	NOISE_HOLD 5, $12
	NOISE_HOLD 5, $12
	NOISE_HOLD 4, $12
	NOISE_HOLD 4, $12
	NOISE_HOLD 3, $12
	NOISE_HOLD 3, $12
	NOISE_HOLD 2, $12
	NOISE_HOLD 2, $12
	NOISE_HOLD 1, $12
	NOISE_HOLD 1, $12
	SND_END

Snd57_Sfx1:
	RAW_VOICE $10, $80, $08
	PAN_LEFT 0
	RAW_NOTE 2, $6C4
	RAW_NOTE 2, $6D6
	RAW_NOTE 4, $6C5
	RAW_NOTE 4, $6D7
	RAW_NOTE 4, $714
	RAW_NOTE 4, $72E
	RAW_NOTE 4, $714
	RAW_NOTE 4, $72E
	RAW_NOTE 4, $74F
	RAW_NOTE 4, $762
	RAW_NOTE 4, $74F
	RAW_NOTE 4, $762
	RAW_NOTE 4, $76B
	RAW_NOTE 4, $78A
	RAW_NOTE 4, $796
	RAW_NOTE 4, $78A
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B1
	LEN_UNIT 8
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B0
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B0
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B2
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B2
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B0
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B2
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B0
	RAW_NOTE 3, $7B1
	RAW_NOTE 3, $7B2
	SND_END

Snd57_Sfx2:
	RAW_VOICE $10, $90, $08
	RAW_NOTE 2, $6C6
	RAW_NOTE 2, $6D8
	RAW_NOTE 2, $715
	RAW_NOTE 2, $72F
	RAW_NOTE 2, $715
	RAW_NOTE 2, $72F
	RAW_NOTE 2, $750
	RAW_NOTE 2, $763
	RAW_NOTE 2, $750
	RAW_NOTE 2, $763
	RAW_NOTE 2, $76C
	RAW_NOTE 2, $78B
	RAW_NOTE 2, $797
	RAW_NOTE 2, $78B
	RAW_NOTE 2, $797
	RAW_NOTE 2, $7A9
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B2
	LEN_UNIT 8
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B1
	RAW_NOTE 2, $7B0
	RAW_NOTE 2, $7B1
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B3
	RAW_NOTE 2, $7B4
	RAW_NOTE 2, $7B3
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B1
	RAW_NOTE 2, $7B0
	RAW_NOTE 2, $7B1
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B3
	RAW_NOTE 2, $7B4
	RAW_NOTE 2, $7B2
	SND_END

Snd58_Sfx1:
	RAW_VOICE $08, $00, $08
	LOOP_START
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D4
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7E0
	LOOP_END 4
	RAW_MARK
	RAW_NOTE 13, $7D0
	RAW_NOTE 13, $7D4
	RAW_NOTE 13, $7D8
	RAW_NOTE 13, $7DC
	RAW_NOTE 13, $7E0
	RAW_REPEAT 7, $FE, $00
	SND_END

Snd59_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_MARK
	RAW_NOTE 7, $780
	RAW_NOTE 7, $770
	RAW_NOTE 7, $784
	RAW_NOTE 7, $774
	RAW_NOTE 7, $788
	RAW_NOTE 7, $778
	RAW_REPEAT 6, $01, $10
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7CC
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7C8
	RAW_MARK
	RAW_NOTE 12, $7D0
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $7CC
	RAW_NOTE 12, $7BC
	RAW_NOTE 12, $7C8
	RAW_NOTE 12, $7B8
	RAW_REPEAT 6, $FE, $F0
	SND_END

Snd59_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 4, $12
	NOISE_HOLD 6, $12
	NOISE_HOLD 8, $12
	NOISE_HOLD 9, $12
	NOISE_HOLD 10, $12
	NOISE_HOLD 11, $12
	NOISE_HOLD 12, $12
	NOISE_HOLD 11, $12
	NOISE_HOLD 10, $12
	NOISE_HOLD 9, $12
	NOISE_HOLD 8, $11
	NOISE_HOLD 7, $11
	NOISE_HOLD 6, $11
	NOISE_HOLD 5, $11
	NOISE_HOLD 4, $11
	NOISE_HOLD 3, $11
	NOISE_HOLD 2, $11
	NOISE_HOLD 1, $11
	SND_END

Snd5A_Sfx1:
	RAW_VOICE $02, $C0, $08
	LOOP_START
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $680
	RAW_NOTE 15, $640
	RAW_NOTE 12, $600
	RAW_NOTE 12, $5C0
	RAW_NOTE 10, $580
	RAW_NOTE 10, $540
	RAW_NOTE 8, $500
	RAW_NOTE 8, $4C0
	RAW_NOTE 6, $480
	RAW_NOTE 6, $440
	RAW_REPEAT 2, $00, $80
	LOOP_END 4
	SND_END

Snd5A_SfxN:
	NVOICE_HOLD $02
	LOOP_START
	NOISE_HOLD 6, $53
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $53
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $53
	LOOP_END $10
	LEN_UNIT $0C
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $54
	NOISE_HOLD 12, $55
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $54
	NOISE_HOLD 12, $55
	NOISE_HOLD 12, $54
	NOISE_HOLD 10, $55
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $55
	NOISE_HOLD 10, $54
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $54
	NOISE_HOLD 6, $55
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $54
	NOISE_HOLD 6, $55
	NOISE_HOLD 6, $54
	NOISE_HOLD 4, $55
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $55
	NOISE_HOLD 4, $54
	NOISE_HOLD 3, $55
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $55
	NOISE_HOLD 3, $54
	NOISE_HOLD 2, $55
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $55
	NOISE_HOLD 2, $54
	NOISE_HOLD 1, $55
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $54
	NOISE_HOLD 1, $55
	NOISE_HOLD 1, $54
	SND_END

Snd5C_Sfx1:
	RAW_VOICE $04, $00, $08
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $660
	RAW_NOTE 13, $6C0
	RAW_NOTE 13, $640
	RAW_NOTE 12, $6A0
	RAW_NOTE 12, $620
	RAW_NOTE 10, $680
	RAW_NOTE 10, $600
	RAW_NOTE 8, $660
	RAW_NOTE 8, $5E0
	RAW_NOTE 6, $620
	RAW_NOTE 6, $5C0
	RAW_NOTE 4, $600
	RAW_NOTE 4, $5A0
	RAW_NOTE 2, $5E0
	RAW_NOTE 2, $580
	RAW_NOTE 1, $5E0
	RAW_NOTE 1, $560
	SND_END

Snd5D_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	NOISE_HOLD 1, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 3, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 3, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 3, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 5, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 9, $33
	NOISE_HOLD 7, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 13, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 13, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 15, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 12, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 6, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 2, $32
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 4, $33
	NOISE_HOLD 2, $33
	LEN_UNIT $20
	NOISE_REST
	LEN_UNIT 1
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 2, $32
	SND_END

Snd5F_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_NOTE 15, $780
	RAW_MARK
	RAW_NOTE 12, $788
	RAW_REPEAT 12, $FF, $08
	LEN_UNIT 1
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C1
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C1
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C1
	RAW_NOTE 13, $7C0
	RAW_NOTE 13, $7C1
	RAW_NOTE 13, $7C0
	RAW_NOTE 13, $7C1
	RAW_NOTE 13, $7C0
	RAW_NOTE 13, $7C1
	RAW_MARK
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $7C1
	RAW_REPEAT 10, $FF, $02
	LEN_UNIT $0C
	RAW_NOTE 6, $7C0
	RAW_NOTE 6, $7C0
	SND_END

Snd60_Sfx1:
	RAW_VOICE $11, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $7C0
	RAW_REPEAT 64, $00, $FC
	RAW_MARK
	RAW_NOTE 15, $6BE
	RAW_REPEAT 14, $FF, $FC
	SND_END

Snd61_SfxN:
	NVOICE_HOLD $50
	NOISE_HOLD 15, $45
	NOISE_HOLD 13, $45
	NOISE_HOLD 12, $45
	NOISE_HOLD 11, $45
	NOISE_HOLD 10, $45
	NOISE_HOLD 9, $45
	NOISE_HOLD 8, $45
	NOISE_HOLD 7, $45
	NOISE_HOLD 6, $45
	NOISE_HOLD 5, $45
	NOISE_HOLD 4, $45
	NOISE_HOLD 3, $45
	NOISE_HOLD 2, $45
	NOISE_HOLD 1, $45
	SND_END

Snd62_Sfx1:
	RAW_VOICE $03, $00, $08
	LOOP_START
	RAW_NOTE 4, $7C0
	RAW_NOTE 6, $770
	RAW_NOTE 8, $7C4
	RAW_NOTE 10, $774
	RAW_NOTE 12, $7C8
	RAW_NOTE 13, $778
	RAW_NOTE 15, $7CC
	RAW_NOTE 15, $77C
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $788
	RAW_NOTE 15, $7D4
	RAW_NOTE 15, $78C
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $790
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $794
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $79C
	RAW_NOTE 13, $7E4
	RAW_NOTE 13, $7A0
	RAW_NOTE 12, $7E8
	RAW_NOTE 12, $7A4
	RAW_NOTE 11, $7EC
	RAW_NOTE 11, $7A8
	LOOP_END 3
	SND_END

Snd62_SfxN:
	NVOICE_HOLD $18
	LOOP_START
	NOISE_HOLD 10, $12
	NOISE_HOLD 8, $12
	NOISE_HOLD 4, $12
	LOOP_END 3
	SND_END

Snd63_Sfx1:
	RAW_VOICE $04, $80, $08
	RAW_MARK
	RAW_NOTE 4, $6C0
	RAW_NOTE 4, $5C0
	RAW_NOTE 4, $6C0
	RAW_NOTE 4, $5C0
	RAW_REPEAT 6, $01, $02
	LEN_UNIT 2
	RAW_NOTE 9, $6CC
	RAW_NOTE 9, $5CC
	RAW_NOTE 9, $6CC
	RAW_NOTE 9, $5CC
	RAW_NOTE 9, $6CE
	RAW_NOTE 9, $5CE
	RAW_NOTE 9, $6CE
	RAW_NOTE 9, $5CE
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $5D0
	RAW_NOTE 10, $6D0
	RAW_NOTE 10, $5D0
	RAW_NOTE 10, $6D4
	RAW_NOTE 10, $5D4
	RAW_NOTE 10, $6D4
	RAW_NOTE 10, $5D4
	RAW_MARK
	RAW_NOTE 11, $6D8
	RAW_NOTE 11, $5D8
	RAW_NOTE 11, $6D8
	RAW_NOTE 11, $5D8
	RAW_NOTE 11, $6DC
	RAW_NOTE 11, $5DC
	RAW_NOTE 11, $6DC
	RAW_NOTE 11, $5DC
	RAW_REPEAT 3, $01, $08
	LEN_UNIT 1
	RAW_MARK
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $5F0
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $5F0
	RAW_REPEAT 6, $00, $04
	RAW_MARK
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_REPEAT 7, $FF, $04
	SND_END

Snd64_Sfx1:
	RAW_VOICE $06, $C0, $08
	RAW_NOTE 15, $680
	RAW_NOTE 15, $67C
	RAW_NOTE 15, $678
	RAW_MARK
	RAW_NOTE 12, $674
	RAW_REPEAT 12, $FF, $F8
	SND_END

Snd65_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_NOTE 15, $680
	RAW_NOTE 15, $690
	RAW_NOTE 15, $6A0
	RAW_NOTE 15, $6B0
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6B0
	RAW_NOTE 15, $6A0
	RAW_NOTE 15, $690
	RAW_NOTE 15, $680
	RAW_MARK
	RAW_NOTE 12, $680
	RAW_NOTE 12, $690
	RAW_NOTE 12, $6A0
	RAW_NOTE 12, $6B0
	RAW_NOTE 12, $6C0
	RAW_NOTE 12, $6B0
	RAW_NOTE 12, $6A0
	RAW_NOTE 12, $690
	RAW_NOTE 12, $680
	RAW_REPEAT 5, $FE, $00
	RAW_NOTE 2, $680
	RAW_NOTE 2, $690
	RAW_NOTE 2, $6A0
	RAW_NOTE 2, $6B0
	RAW_NOTE 2, $6C0
	RAW_NOTE 2, $6B0
	RAW_NOTE 2, $6A0
	RAW_NOTE 2, $690
	RAW_NOTE 2, $680
	SND_END

Snd66_Sfx1:
	RAW_VOICE $0B, $C0, $08
	RAW_MARK
	RAW_NOTE 1, $7D0
	RAW_NOTE 1, $7D4
	RAW_NOTE 1, $7D8
	RAW_NOTE 1, $7DC
	RAW_NOTE 1, $7E0
	RAW_REPEAT 7, $02, $00
	LOOP_START
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D4
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7E0
	LOOP_END 6
	RAW_MARK
	RAW_NOTE 12, $7D0
	RAW_NOTE 12, $7D4
	RAW_NOTE 12, $7D8
	RAW_NOTE 12, $7DC
	RAW_NOTE 12, $7E0
	RAW_REPEAT 6, $FE, $00
	RAW_NOTE 1, $7D0
	RAW_NOTE 1, $7D4
	RAW_NOTE 1, $7D8
	RAW_NOTE 1, $7DC
	RAW_NOTE 1, $7E0
	SND_END

Snd67_SfxN:
	NVOICE_HOLD $0E
	NOISE_HOLD 15, $49
	NOISE_HOLD 15, $4C
	NOISE_HOLD 15, $4B
	NOISE_HOLD 12, $4A
	NOISE_HOLD 15, $49
	NOISE_HOLD 15, $4C
	NOISE_HOLD 15, $4B
	NOISE_HOLD 12, $4A
	NOISE_HOLD 10, $49
	NOISE_HOLD 8, $49
	NOISE_HOLD 6, $49
	NOISE_HOLD 4, $49
	NOISE_HOLD 2, $49
	NOISE_HOLD 1, $49
	SND_END

Snd68_SfxN:
	NVOICE_HOLD $0C
	LOOP_START
	NOISE_HOLD 15, $5B
	NOISE_HOLD 12, $59
	LOOP_END 4
	NOISE_HOLD 12, $5B
	NOISE_HOLD 10, $59
	NOISE_HOLD 8, $5B
	NOISE_HOLD 6, $59
	NOISE_HOLD 4, $5B
	NOISE_HOLD 2, $59
	NOISE_HOLD 2, $5B
	NOISE_HOLD 1, $59
	LEN_UNIT $0E
	NOISE_HOLD 15, $4B
	NOISE_HOLD 13, $24
	NOISE_HOLD 12, $14
	NOISE_HOLD 10, $14
	NOISE_HOLD 8, $14
	NOISE_HOLD 6, $14
	NOISE_HOLD 4, $14
	NOISE_HOLD 2, $14
	SND_END

Snd69_Sfx1:
	RAW_VOICE $08, $00, $08
	RAW_NOTE 15, $7F0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7EC
	RAW_NOTE 15, $7AC
	RAW_NOTE 15, $7E8
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7E4
	RAW_NOTE 15, $7A4
	RAW_NOTE 12, $7E0
	RAW_NOTE 12, $7A0
	RAW_NOTE 12, $7DC
	RAW_NOTE 12, $79C
	RAW_NOTE 10, $7D8
	RAW_NOTE 10, $798
	RAW_NOTE 10, $7D4
	RAW_NOTE 10, $794
	RAW_NOTE 8, $7D8
	RAW_NOTE 8, $798
	RAW_NOTE 8, $7DC
	RAW_NOTE 8, $79C
	RAW_NOTE 6, $7E0
	RAW_NOTE 6, $7A0
	RAW_NOTE 6, $7E4
	RAW_NOTE 6, $7A4
	RAW_NOTE 4, $7E8
	RAW_NOTE 4, $7A8
	RAW_NOTE 4, $7EC
	RAW_NOTE 4, $7AC
	RAW_NOTE 2, $7F0
	RAW_NOTE 2, $7B0
	SND_END

Snd6A_SfxN:
	NVOICE_HOLD $06
	NOISE_HOLD 15, $5C
	NOISE_HOLD 15, $5B
	NOISE_HOLD 15, $5A
	NOISE_HOLD 15, $59
	NOISE_HOLD 12, $4B
	NOISE_HOLD 10, $4B
	NOISE_HOLD 8, $4A
	NOISE_HOLD 6, $49
	LEN_UNIT 5
	LOOP_START
	NOISE_HOLD 15, $4E
	NOISE_HOLD 12, $4A
	LOOP_END 8
	SND_END

Snd6B_SfxN:
	NVOICE_HOLD $0A
	NOISE_HOLD 15, $3B
	NOISE_HOLD 15, $38
	NOISE_HOLD 15, $3B
	NOISE_HOLD 12, $38
	NOISE_HOLD 10, $3B
	NOISE_HOLD 8, $38
	NOISE_HOLD 6, $3B
	NOISE_HOLD 4, $38
	NOISE_HOLD 2, $3B
	NOISE_HOLD 2, $38
	NOISE_HOLD 2, $3B
	NOISE_HOLD 2, $38
	SND_END

Snd6C_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $710
	RAW_NOTE 15, $720
	RAW_NOTE 15, $730
	RAW_NOTE 15, $740
	RAW_NOTE 15, $750
	RAW_NOTE 15, $760
	RAW_NOTE 15, $6C0
	RAW_NOTE 15, $6D0
	RAW_NOTE 15, $6E0
	RAW_NOTE 15, $6F0
	RAW_NOTE 15, $700
	RAW_NOTE 15, $710
	RAW_NOTE 15, $720
	RAW_REPEAT 3, $00, $10
	RAW_MARK
	RAW_NOTE 12, $730
	RAW_NOTE 12, $740
	RAW_NOTE 12, $750
	RAW_NOTE 12, $760
	RAW_NOTE 12, $770
	RAW_NOTE 12, $780
	RAW_NOTE 12, $790
	RAW_NOTE 11, $6F0
	RAW_NOTE 11, $700
	RAW_NOTE 11, $710
	RAW_NOTE 11, $720
	RAW_NOTE 11, $730
	RAW_NOTE 11, $740
	RAW_NOTE 11, $750
	RAW_REPEAT 6, $FE, $10
	SND_END

Snd6D_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_NOTE 15, $700
	RAW_NOTE 15, $708
	RAW_NOTE 15, $710
	RAW_MARK
	RAW_NOTE 15, $718
	RAW_REPEAT 15, $FF, $08
	LEN_UNIT 6
	DUTY 0
	RAW_NOTE 15, $7E0
	RAW_NOTE 12, $7C0
	RAW_NOTE 10, $7A0
	RAW_NOTE 8, $780
	RAW_NOTE 6, $760
	RAW_NOTE 4, $740
	RAW_NOTE 2, $720
	RAW_NOTE 8, $7E0
	RAW_NOTE 7, $7C0
	RAW_NOTE 6, $7A0
	RAW_NOTE 5, $780
	RAW_NOTE 4, $760
	RAW_NOTE 2, $740
	RAW_NOTE 1, $720
	RAW_NOTE 6, $7E0
	RAW_NOTE 5, $7C0
	RAW_NOTE 4, $7A0
	RAW_NOTE 3, $780
	RAW_NOTE 2, $760
	RAW_NOTE 1, $740
	RAW_NOTE 1, $720
	SND_END

Snd6E_Sfx1:
	RAW_VOICE $02, $C0, $08
	LOOP2_START
	LOOP_START
	RAW_REST
	LOOP_END $0E
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $6C1
	RAW_MARK
	RAW_NOTE 12, $7C0
	RAW_NOTE 12, $6C1
	RAW_REPEAT 12, $FF, $00
	LOOP2_END 2
	SND_JUMP Snd4D_Sfx1_6D90

Snd6E_SfxN:
	NVOICE_HOLD $04
	LOOP2_START
	NOISE_HOLD 15, $4B
	NOISE_HOLD 12, $4B
	NOISE_HOLD 10, $4B
	NOISE_HOLD 8, $4B
	NOISE_HOLD 6, $4B
	NOISE_HOLD 4, $4B
	NOISE_HOLD 2, $4B
	LOOP_START
	NOISE_REST
	LOOP_END $0E
	LOOP2_END 2
	SND_JUMP Snd4D_SfxN_6DBA

Snd6F_Sfx1:
	RAW_VOICE $02, $C0, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $600
	RAW_NOTE 15, $680
	RAW_NOTE 15, $740
	RAW_NOTE 15, $708
	RAW_NOTE 15, $608
	RAW_NOTE 15, $688
	RAW_NOTE 15, $748
	RAW_REPEAT 8, $FF, $10
	SND_END

Snd6F_SfxN:
	NVOICE_HOLD $40
	NOISE_REST
	NOISE_REST
	LEN_UNIT 8
	NOISE_HOLD 15, $17
	LEN_UNIT $14
	NOISE_HOLD 15, $11
	NOISE_HOLD 15, $11
	NOISE_HOLD 15, $11
	NOISE_HOLD 12, $11
	NOISE_HOLD 10, $11
	NOISE_HOLD 8, $11
	NOISE_HOLD 6, $11
	NOISE_HOLD 4, $11
	SND_END

Snd70_Sfx1:
	RAW_VOICE $05, $00, $08
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7D0
	LEN_UNIT 3
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $780
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7E0
	LEN_UNIT 5
	RAW_NOTE 12, $7A0
	RAW_NOTE 10, $7C0
	RAW_NOTE 8, $7E0
	RAW_NOTE 6, $7D0
	RAW_NOTE 4, $7C0
	RAW_NOTE 2, $7B0
	RAW_NOTE 1, $7A0
	SND_END

Snd71_SfxN:
	NVOICE_HOLD $08
	NOISE_HOLD 15, $3C
	NOISE_HOLD 15, $5A
	NOISE_HOLD 12, $59
	NOISE_HOLD 10, $58
	NOISE_HOLD 8, $33
	NOISE_HOLD 6, $32
	NOISE_HOLD 4, $31
	NOISE_HOLD 2, $21
	SND_END

Snd72_SfxN:
	NVOICE_HOLD $14
	SND_JUMP Snd35_SfxN_5DC8

Snd73_Sfx1:
	RAW_VOICE $09, $80, $08
	RAW_NOTE 2, $7D6
	RAW_NOTE 2, $7D8
	RAW_NOTE 2, $7DA
	RAW_NOTE 2, $7DC
	RAW_NOTE 2, $7DE
	RAW_MARK
	RAW_NOTE 4, $7E0
	RAW_NOTE 4, $7DC
	RAW_NOTE 4, $7D8
	RAW_NOTE 4, $7D4
	RAW_NOTE 4, $7D0
	RAW_REPEAT 5, $02, $F4
	RAW_NOTE 15, $7A4
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $79C
	RAW_NOTE 15, $798
	RAW_NOTE 15, $794
	SND_END

Snd73_SfxN:
	NVOICE_HOLD $2D
	LOOP_START
	NOISE_REST
	LOOP_END 7
	LEN_UNIT $0C
	NOISE_HOLD 15, $4D
	NOISE_HOLD 12, $4D
	NOISE_HOLD 10, $4D
	NOISE_HOLD 8, $4D
	NOISE_HOLD 6, $4D
	NOISE_HOLD 4, $4D
	NOISE_HOLD 2, $4D
	LEN_UNIT $14
	NOISE_HOLD 6, $4D
	NOISE_HOLD 5, $4D
	NOISE_HOLD 4, $4D
	NOISE_HOLD 3, $4D
	NOISE_HOLD 2, $4D
	NOISE_HOLD 1, $4D
	NOISE_HOLD 1, $4D
	SND_END

Snd74_SfxN:
	NVOICE_HOLD $1C
	NOISE_HOLD 4, $44
	NOISE_HOLD 6, $45
	NOISE_HOLD 8, $44
	NOISE_HOLD 10, $45
	NOISE_HOLD 12, $44
	NOISE_HOLD 15, $45
	LEN_UNIT 8
	LOOP_START
	NOISE_HOLD 15, $44
	NOISE_HOLD 15, $45
	LOOP_END $7A
	LEN_UNIT $20
	NOISE_HOLD 15, $44
	NOISE_HOLD 13, $45
	NOISE_HOLD 12, $44
	NOISE_HOLD 11, $45
	NOISE_HOLD 10, $44
	NOISE_HOLD 9, $45
	NOISE_HOLD 8, $44
	NOISE_HOLD 7, $45
	NOISE_HOLD 6, $44
	NOISE_HOLD 5, $45
	NOISE_HOLD 4, $44
	NOISE_HOLD 3, $45
	NOISE_HOLD 2, $44
	NOISE_HOLD 1, $45
	SND_END

Snd75_Sfx1:
	RAW_VOICE $01, $80, $08
	LOOP_START
	RAW_MARK
	RAW_NOTE 15, $740
	RAW_NOTE 15, $738
	RAW_NOTE 15, $730
	RAW_REPEAT 7, $FE, $00
	LOOP_END 3
	SND_END

Snd76_Sfx1:
	RAW_VOICE $04, $80, $08
	LOOP_START
	RAW_NOTE 15, $7E0
	RAW_NOTE 15, $7E8
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7EC
	RAW_NOTE 15, $7E4
	LOOP_END 2
	LEN_UNIT $0A
	RAW_MARK
	RAW_NOTE 15, $7DC
	RAW_NOTE 15, $7E4
	RAW_REPEAT 8, $FE, $00
	SND_END

Snd77_Sfx1:
	RAW_VOICE $0C, $00, $08
	RAW_MARK
	RAW_NOTE 15, $7C0
	RAW_NOTE 15, $7C8
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7C8
	RAW_NOTE 15, $7D0
	RAW_NOTE 15, $7D8
	RAW_NOTE 15, $7E0
	RAW_REPEAT 4, $FC, $00
	SND_END

Snd78_SfxN:
	NVOICE_HOLD $08
	LOOP_START
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $56
	NOISE_HOLD 15, $55
	LOOP_END $0C
	LEN_UNIT $20
	NOISE_HOLD 12, $45
	NOISE_HOLD 12, $46
	NOISE_HOLD 12, $45
	NOISE_HOLD 12, $44
	NOISE_HOLD 11, $45
	NOISE_HOLD 11, $46
	NOISE_HOLD 11, $45
	NOISE_HOLD 11, $44
	NOISE_HOLD 10, $45
	NOISE_HOLD 10, $46
	NOISE_HOLD 10, $45
	NOISE_HOLD 10, $44
	NOISE_HOLD 9, $45
	NOISE_HOLD 9, $46
	NOISE_HOLD 9, $45
	NOISE_HOLD 9, $44
	NOISE_HOLD 8, $45
	NOISE_HOLD 8, $46
	NOISE_HOLD 8, $45
	NOISE_HOLD 8, $44
	NOISE_HOLD 7, $45
	NOISE_HOLD 7, $46
	NOISE_HOLD 7, $45
	NOISE_HOLD 7, $44
	NOISE_HOLD 6, $45
	NOISE_HOLD 6, $46
	NOISE_HOLD 6, $45
	NOISE_HOLD 6, $44
	LEN_UNIT $20
	NOISE_HOLD 15, $45
	NOISE_HOLD 12, $4D
	NOISE_HOLD 10, $4D
	NOISE_HOLD 8, $4C
	NOISE_HOLD 6, $4B
	NOISE_HOLD 4, $4A
	NOISE_HOLD 2, $49
	NOISE_HOLD 1, $48
	SND_END

Snd79_SfxN:
	NVOICE_HOLD $20
	NOISE_HOLD 15, $45
	NOISE_HOLD 12, $4D
	NOISE_HOLD 10, $4D
	NOISE_HOLD 8, $4C
	NOISE_HOLD 6, $4B
	NOISE_HOLD 4, $4A
	NOISE_HOLD 2, $49
	NOISE_HOLD 1, $48
	LEN_UNIT $20
	NOISE_HOLD 15, $45
	NOISE_HOLD 15, $46
	NOISE_HOLD 15, $45
	NOISE_HOLD 15, $46
	NOISE_HOLD 15, $45
	NOISE_HOLD 15, $46
	NOISE_HOLD 15, $45
	NOISE_HOLD 15, $46
	LEN_UNIT 8
	LOOP_START
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $56
	NOISE_HOLD 15, $55
	LOOP_END $0C
	LEN_UNIT $20
	NOISE_HOLD 12, $45
	NOISE_HOLD 12, $46
	NOISE_HOLD 12, $45
	NOISE_HOLD 12, $44
	NOISE_HOLD 10, $45
	NOISE_HOLD 10, $46
	NOISE_HOLD 10, $45
	NOISE_HOLD 10, $44
	NOISE_HOLD 8, $45
	NOISE_HOLD 8, $46
	NOISE_HOLD 8, $45
	NOISE_HOLD 8, $44
	NOISE_HOLD 6, $45
	NOISE_HOLD 6, $46
	NOISE_HOLD 6, $45
	NOISE_HOLD 6, $44
	NOISE_HOLD 4, $45
	NOISE_HOLD 4, $46
	NOISE_HOLD 4, $45
	NOISE_HOLD 4, $44
	NOISE_HOLD 2, $45
	NOISE_HOLD 2, $46
	NOISE_HOLD 2, $45
	NOISE_HOLD 2, $44
	NOISE_HOLD 1, $45
	NOISE_HOLD 1, $46
	NOISE_HOLD 1, $45
	NOISE_HOLD 1, $44
	SND_END

Snd7A_SfxN:
	NVOICE_HOLD $0C
	LOOP_START
	NOISE_HOLD 15, $49
	NOISE_HOLD 15, $5C
	NOISE_HOLD 15, $48
	NOISE_HOLD 15, $4D
	NOISE_HOLD 15, $5C
	NOISE_HOLD 15, $4B
	NOISE_HOLD 15, $49
	NOISE_HOLD 15, $4B
	NOISE_HOLD 15, $49
	NOISE_HOLD 15, $5C
	NOISE_HOLD 15, $48
	NOISE_HOLD 15, $4D
	LOOP_END 2
	LEN_UNIT $10
	LOOP_START
	NOISE_HOLD 15, $36
	LOOP_END 6
	LOOP_START
	NOISE_HOLD 15, $35
	LOOP_END 6
	LOOP_START
	NOISE_HOLD 15, $34
	LOOP_END 6
	LOOP_START
	NOISE_HOLD 15, $33
	LOOP_END 6
	LEN_UNIT $30
	NOISE_HOLD 12, $32
	NOISE_HOLD 11, $32
	NOISE_HOLD 10, $32
	NOISE_HOLD 9, $32
	NOISE_HOLD 8, $32
	NOISE_HOLD 7, $32
	NOISE_HOLD 6, $32
	NOISE_HOLD 5, $32
	NOISE_HOLD 4, $32
	NOISE_HOLD 3, $32
	NOISE_HOLD 2, $32
	NOISE_HOLD 1, $32

Snd7A_Sfx1:
	SND_END

Snd7B_Sfx1:
	RAW_VOICE $08, $80, $08
	RAW_MARK
	RAW_NOTE 15, $7A0
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7B8
	RAW_NOTE 15, $7A8
	RAW_NOTE 15, $7B0
	RAW_NOTE 15, $7B8
	RAW_NOTE 15, $7C0
	RAW_REPEAT 8, $FE, $04
	SND_END

Snd7C_SfxN:
	NVOICE_HOLD $30
	LOOP_START
	NOISE_HOLD 4, $33
	NOISE_HOLD 8, $33
	NOISE_HOLD 10, $33
	NOISE_HOLD 12, $33
	NOISE_HOLD 15, $33
	LEN_UNIT $10
	NOISE_HOLD 12, $33
	NOISE_HOLD 12, $34
	NOISE_HOLD 10, $33
	NOISE_HOLD 10, $34
	NOISE_HOLD 8, $33
	NOISE_HOLD 8, $34
	NOISE_HOLD 6, $33
	NOISE_HOLD 6, $34
	NOISE_HOLD 4, $33
	NOISE_HOLD 4, $34
	NOISE_HOLD 2, $33
	NOISE_HOLD 2, $34
	NOISE_HOLD 1, $33
	NOISE_HOLD 1, $34
	LEN_UNIT $30
	NOISE_REST
	LOOP_END 2
	SND_END

Snd7D_Sfx1:
	RAW_VOICE $04, $00, $08
	SND_JUMP Snd3A_Sfx1_63C8

Snd7E_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 15, $17
	LEN_UNIT $10
	LOOP_START
	NOISE_HOLD 15, $47
	LOOP_END $0A
	NOISE_HOLD 12, $47
	NOISE_HOLD 12, $47
	NOISE_HOLD 8, $47
	NOISE_HOLD 8, $47
	NOISE_HOLD 4, $47
	NOISE_HOLD 4, $47
	NOISE_HOLD 2, $47
	NOISE_HOLD 2, $47
	NOISE_HOLD 1, $47
	NOISE_HOLD 1, $47
	SND_END

Snd7F_SfxN:
	NVOICE_HOLD $04
	LOOP_START
	NOISE_HOLD 8, $4D
	NOISE_HOLD 8, $36
	NOISE_HOLD 8, $46
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $44
	NOISE_HOLD 8, $55
	LOOP_END 2
	SND_END

Snd80_Sfx1:
	RAW_VOICE $01, $80, $08
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_REPEAT 4, $FF, $00
	LEN_UNIT 3
	RAW_MARK
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_NOTE 15, $700
	RAW_NOTE 15, $580
	RAW_REPEAT 14, $FF, $00
	SND_END

Snd80_SfxN:
	NVOICE_HOLD $04
	LOOP_START
	NOISE_HOLD 15, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 12, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 10, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 8, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 6, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 4, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 2, $3C
	LOOP_END 5
	LOOP_START
	NOISE_HOLD 1, $3C
	LOOP_END 5
	SND_END

Snd81_Sfx1:
	RAW_VOICE $01, $80, $08
	LOOP_START
	RAW_MARK
	RAW_NOTE 15, $6E0
	RAW_REPEAT 6, $00, $FE
	LOOP_END 2
	LEN_UNIT 2
	RAW_MARK
	RAW_NOTE 12, $720
	RAW_REPEAT 6, $00, $FE
	RAW_MARK
	RAW_NOTE 10, $728
	RAW_REPEAT 6, $00, $FE
	RAW_MARK
	RAW_NOTE 8, $730
	RAW_REPEAT 6, $00, $FE
	RAW_MARK
	RAW_NOTE 6, $738
	RAW_REPEAT 6, $00, $FE
	RAW_MARK
	RAW_NOTE 4, $740
	RAW_REPEAT 6, $00, $FE
	RAW_MARK
	RAW_NOTE 2, $748
	RAW_REPEAT 6, $00, $FE
	SND_END

Snd82_Sfx1:
	RAW_VOICE $0C, $C0, $08
	LOOP_START
	RAW_NOTE 15, $740
	RAW_NOTE 15, $720
	RAW_NOTE 15, $700
	RAW_NOTE 15, $720
	LOOP_END 2
	RAW_MARK
	RAW_NOTE 15, $740
	RAW_NOTE 15, $720
	RAW_NOTE 15, $700
	RAW_NOTE 15, $720
	RAW_REPEAT 8, $FE, $00
	SND_END

Snd8F_Ch2:
	TRANSPOSE_UP 3
	SND_SEGNO
	SND_CALL Snd8F_Ch2_7C07
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, 8
	SND_CALL Snd8F_Ch2_7C07
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, $0A
	SND_CALL Snd8F_Ch2_7C2F
	ENVELOPE_OFF
	RELEASE $0E, 7
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 6
	NOTE F#, 4
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, $0A
	SND_CALL Snd8F_Ch2_7C2F
	ENVELOPE_OFF
	VIBRATO $08, 0, 7
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 8
	DUTY 8
	ATTEN 2
	NOTE D_, 4
	NOTE C#, 4
	SND_LOOP
Snd8F_Ch2_7C07:
	VOICE $08, 0, 8, 15, 7
	VIBRATO $01, 2, 3
	DUTY_STEP 4, 1
	ENVELOPE $12
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE B_, 2
	LEN_UNIT 1
	NOTE A_, 6
	NOTE B_, 5
	NOTE A_, 5
	LEN_UNIT 8
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	REST 2
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd8F_Ch2_7C2F:
	VOICE $08, 4, 8, 14, 6
	VIBRATO $08, 0, 10
	ENVELOPE $13
	DUTY_STEP 0, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE A_, 2
	DUTY_STEP 4, 1
	DUTY 8
	NOTE B_, 2
	NOTE B_, 2
	REST 2
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 2
	REST 6
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	VIBRATO $01, 2, 3
	DUTY 0
	SND_RET

Snd8F_Ch1:
	TRANSPOSE_UP 3
	DETUNE $FF
	SND_SEGNO
	DUTY_STEP 0, 0
	SND_CALL Snd8F_Ch1_7CBB
	REST 4
	OCTAVE 3
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE B_, 4
	LOOP_START
	REST 4
	OCTAVE 3
	NOTE E_, 4
	REST 4
	NOTE C#, 4
	LOOP_END 2
	SND_CALL Snd8F_Ch1_7CBB
	REST 4
	OCTAVE 3
	NOTE E_, 4
	REST 4
	NOTE C#, 4
	REST 4
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE A_, 4
	SND_CALL Snd8F_Ch1_7CDA
	NOTE A#, 4
	VIBRATO_OFF
	ATTEN 0
	LOOP_START
	OCTAVE 3
	REST 4
	NOTE D_, 4
	OCTAVE 2
	REST 4
	NOTE A_, 4
	LOOP_END 2
	REST 4
	OCTAVE 3
	NOTE E_, 4
	REST 4
	NOTE C#, 4
	SND_CALL Snd8F_Ch1_7CDA
	ENVELOPE_OFF
	RELEASE $0E, 7
	DUTY 4
	PAN_LEFT 0
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	REST 2
	ATTEN 0
	PAN_BOTH 0
	DUTY 8
	VIBRATO_OFF
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE A_, 4
	RELEASE $0F, 7
	NOTE E_, 8
	NOTE E_, 8
	SND_LOOP
Snd8F_Ch1_7CBB:
	VOICE $04, 8, 7, 13, 2
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	REST 4
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE A_, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	REST 4
	NOTE E_, 4
	REST 4
	OCTAVE 2
	NOTE B_, 4
	LOOP_END 2
	REST 4
	OCTAVE 3
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE B_, 4
	SND_RET
Snd8F_Ch1_7CDA:
	VIBRATO $08, 0, 4
	RELEASE $0F, 7
	DUTY 4
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE A_, 4
	DUTY 0
	ENVELOPE $13
	DUTY 8
	OCTAVE 4
	NOTE F#, 4
	NOTE F#, 4
	REST 4
	NOTE E_, 4
	NOTE F#, 4
	REST $0C
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 4
	REST 4
	NOTE A_, 4
	NOTE B_, 4
	REST 4
	ENVELOPE_OFF
	ATTEN 2
	RELEASE $0E, 7
	NOTE B_, 4
	SND_RET

Snd8F_Ch3:
	TRANSPOSE_UP $0F
	SND_SEGNO
	VOICE $08, 4, 2, 7, 2
	DETUNE $FF
	SND_CALL Snd8F_Ch3_7D76
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 2
	SND_CALL Snd8F_Ch3_7D76
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE D_, 2
	SND_CALL Snd8F_Ch3_7D8D
	NOTE E_, 2
	NOTE D#, 2
	LOOP_START
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	SND_CALL Snd8F_Ch3_7D8D
	RELEASE 8, 7
	OCTAVE 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	REST $0A
	NOTE F#, 2
	NOTE A_, 2
	RELEASE 6, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	SND_LOOP
Snd8F_Ch3_7D76:
	LOOP_START
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 2
	SND_RET
Snd8F_Ch3_7D8D:
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	REST 2
	NOTE A_, 2
	NOTE B_, 2
	REST 6
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	SND_RET

Snd8F_Drm:
	LEN_UNIT 8
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END $0F
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_CALL Snd8F_Drm_7DCC
	LOOP_START
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_CALL Snd8F_Drm_7DCC
	DRUM 4, $0A
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP
Snd8F_Drm_7DCC:
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 2
	SND_RET

Snd90_Ch2:
	TRANSPOSE_UP 1
	TEMPO $1C
	VOICE $05, 8, 8, 15, 6
	DUTY_STEP 4, 1
	LOOP_START
	REST 6
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	REST 6
	NOTE A_, 4
	NOTE G_, 2
	LOOP_END 4
	SND_SEGNO
	LOOP_START
	DUTY 4
	ENVELOPE $12
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 1
	RELEASE $0F, 7
	PAN_BOTH 0
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 2
	REST $0A
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 2
	NOTE C_, 2
	REST $0A
	DUTY 8
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ENVELOPE $13
	REST 4
	OCTAVE 4
	NOTE G_, 2
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE E_, 2
	JUMP_ON 2, Snd90_Ch2_7E2F
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	REST 2
	ENVELOPE_OFF
	VIBRATO $01, 0, 11
	OCTAVE 3
	NOTE G_, 8
	ATTEN 0
Snd90_Ch2_7E2F:
	LOOP_END 2
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	NOTE C_, 2
	DUTY 0
	ENVELOPE $13
	VIBRATO $08, 0, 4
	SND_CALL Snd90_Ch1_7E5F
	NOTE G_, 2
	DUTY 8
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 4
	NOTE G_, 2
	NOTE G_, $0C
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 4
	NOTE G_, 2
	NOTE G_, 4
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 4
	NOTE G_, 2
	SND_LOOP
Snd90_Ch1_7E5F:
	OCTAVE 4
	REST 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G#, 4
	NOTE G_, 2
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 4
	NOTE D#, 2
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 4
	SND_RET

Snd90_Ch1:
	TRANSPOSE_UP 1
	VOICE $05, 4, 6, 15, 7
	DUTY_STEP 4, 1
	OCTAVE 3
	LOOP_START
	REST 6
	NOTE D_, 4
	NOTE D_, 2
	LOOP_END 8
	SND_SEGNO
	LOOP_START
	VOICE $05, 8, 6, 14, 6
	ATTEN 1
	DUTY_STEP 4, 1
	PAN_BOTH 0
	REST 6
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 2
	REST $0A
	REST 6
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	REST $0A
	ENVELOPE $13
	REST 4
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	JUMP_ON 2, Snd90_Ch1_7EBE
	NOTE A_, 4
	NOTE A_, 2
	NOTE F_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	PAN_RIGHT 0
	VIBRATO $08, 0, 11
	RELEASE $0F, 7
	ENVELOPE_OFF
	OCTAVE 3
	NOTE G_, 8
Snd90_Ch1_7EBE:
	LOOP_END 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE G#, 4
	NOTE F_, 2
	NOTE G_, 2
	REST 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 4
	NOTE G_, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 4
	REST 1
	ENVELOPE_OFF
	DUTY_STEP 8, 1
	SND_CALL Snd90_Ch1_7E5F
	NOTE G_, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE D_, 2
	NOTE D_, $0C
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 2
	NOTE D_, 4
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 4
	NOTE D_, 2
	SND_LOOP

Snd90_Ch3:
	TRANSPOSE_UP 1
	VOICE $05, 15, 2, 6, 2
	VIBRATO $08, 0, 10
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	LOOP_END 4
	SND_SEGNO
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE C_, 2
	REST $0A
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE A_, 2
	REST $0A
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	JUMP_ON 2, Snd90_Ch3_7F30
	NOTE F_, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE B_, 2
Snd90_Ch3_7F30:
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE C_, 2
	REST $0A
	SND_CALL Snd90_Ch1_7E5F
	NOTE G_, 2
	LOOP_START
	OCTAVE 2
	NOTE G_, $0C
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 4
	NOTE G_, 2
	LOOP_END 2
	SND_LOOP

Snd90_Drm:
	LEN_UNIT 5
	LOOP_START
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END 8
	SND_SEGNO
	LOOP_START
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM $0B, 6
	DRUM 8, 6
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM $0B, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	JUMP_ON 2, Snd90_Drm_7F6F
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
Snd90_Drm_7F6F:
	LOOP_END 2
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM $0B, 4
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 4
	DRUM 1, 2
	LOOP2_START
	DRUM $0B, 4
	DRUM $0A, 2
	LOOP_START
	DRUM $0A, 4
	DRUM $0A, 2
	LOOP_END 5
	DRUM $0A, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	LOOP2_END 2
	SND_LOOP
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF

SECTION "Sound bank 15", ROMX[$4000], BANK[15]
B15_SoundTable:
	dw SndHdrA1 ; $A1
	dw SndHdrA2 ; $A2
	dw SndHdrA3 ; $A3
	dw SndHdrA4 ; $A4
	dw SndHdrA5 ; $A5
	dw SndHdrA6 ; $A6
	dw SndHdrA7 ; $A7
	dw SndHdrA8 ; $A8
	dw SndHdrA9 ; $A9
	dw SndHdrAA ; $AA
	dw SndHdrAB ; $AB
	dw SndHdrAC ; $AC
	dw SndHdrAD ; $AD
	dw SndHdrAE ; $AE
	dw SndHdrAF ; $AF
	dw SndHdrB0 ; $B0
	dw SndHdrB1 ; $B1
	dw SndHdrB2 ; $B2
	dw SndHdrB3 ; $B3
	dw SndHdrB4 ; $B4
	dw SndHdrB5 ; $B5
	dw SndHdrB6 ; $B6
	dw SndHdrB7 ; $B7
	dw SndHdrB8 ; $B8
	dw SndHdrB9 ; $B9
	dw SndHdrBA ; $BA
	dw SndHdrBB ; $BB
	dw SndHdrBC ; $BC
	dw SndHdrBD ; $BD
	dw SndHdrBE ; $BE
	dw SndHdrBF ; $BF

SndHdrA2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA2_Ch1
	dw SndA2_Ch2
	dw SndA2_Ch3
	dw SndA2_Drm

SndHdrA3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA3_Ch1
	dw SndA3_Ch2
	dw SndA3_Ch3
	dw SndA3_Drm

SndHdrA4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA4_Ch1
	dw SndA4_Ch2
	dw SndA4_Ch3
	dw SndA4_Drm

SndHdrA5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA5_Ch1
	dw SndA5_Ch2
	dw SndA5_Ch3
	dw SndA5_Drm

SndHdrA6:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA6_Ch1
	dw SndA6_Ch2
	dw SndA6_Ch3
	dw SndA6_Drm

SndHdrA7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA7_Ch1
	dw SndA7_Ch2
	dw SndA7_Ch3
	dw SndA7_Drm

SndHdrA8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA8_Ch1
	dw SndA8_Ch2
	dw SndA8_Ch3
	dw SndA8_Drm

SndHdrA9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA9_Ch1
	dw SndA9_Ch2
	dw SndA9_Ch3
	dw SndA9_Drm

SndHdrAA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAA_Ch1
	dw SndAA_Ch2
	dw SndAA_Ch3
	dw SndAA_Drm

SndHdrAB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAB_Ch1
	dw SndAB_Ch2
	dw SndAB_Ch3
	dw SndAB_Drm

SndHdrAC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAC_Ch1
	dw SndAC_Ch2
	dw SndAC_Ch3
	dw SndAC_Drm

SndHdrAD:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAD_Ch1
	dw SndAD_Ch2
	dw SndAD_Ch3
	dw SndAD_Drm

SndHdrAE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAE_Ch1
	dw SndAE_Ch2
	dw SndAE_Ch3
	dw SndAE_Drm

SndHdrAF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndAF_Ch1
	dw SndAF_Ch2
	dw SndAF_Ch3
	dw SndAF_Drm

SndHdrB0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB0_Ch1
	dw SndB0_Ch2
	dw SndB0_Ch3
	dw SndB0_Drm

SndHdrB1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB1_Ch1
	dw SndB1_Ch2
	dw SndB1_Ch3
	dw SndB1_Drm

SndHdrB2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB2_Ch1
	dw SndB2_Ch2
	dw SndB2_Ch3
	dw SndB2_Drm

SndHdrB3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB3_Ch1
	dw SndB3_Ch2
	dw SndB3_Ch3
	dw SndB3_Drm

SndHdrB4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB4_Ch1
	dw SndB4_Ch2
	dw SndB4_Ch3
	dw SndB4_Drm

SndHdrB5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB5_Ch1
	dw SndB5_Ch2
	dw SndB5_Ch3
	dw SndB5_Drm

SndHdrB6:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB6_Ch1
	dw SndB6_Ch2
	dw SndB6_Ch3
	dw SndB6_Drm

SndHdrB7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB7_Ch1
	dw SndB7_Ch2
	dw SndB7_Ch3
	dw SndB7_Drm

SndHdrB8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB8_Ch1
	dw SndB8_Ch2
	dw SndB8_Ch3
	dw SndB8_Drm

SndHdrA1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndA1_Ch1
	dw SndA1_Ch1
	dw SndA1_Ch1
	dw SndA1_Ch1

SndHdrB9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndB9_Ch1
	dw SndB9_Ch2
	dw SndB9_Ch3
	dw SndB9_Drm

SndHdrBA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBA_Ch1
	dw SndBA_Ch2
	dw SndBA_Ch3
	dw SndBA_Drm

SndHdrBB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBB_Ch1
	dw SndBB_Ch2
	dw SndBB_Ch3
	dw SndBB_Drm

SndHdrBC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBC_Ch1
	dw SndBC_Ch2
	dw SndBC_Ch3
	dw SndBC_Drm

SndHdrBD:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBD_Ch1
	dw SndBD_Ch2
	dw SndBD_Ch3
	dw SndBD_Drm

SndHdrBE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBE_Ch1
	dw SndBE_Ch2
	dw SndBE_Ch3
	dw SndBE_Drm

SndHdrBF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndBF_Ch1
	dw SndBF_Ch2
	dw SndBF_Ch3
	dw SndBF_Ch3

SndA2_Ch2:
	TEMPO $10
	VOICE $06, 0, 8, 11, 6
	VIBRATO $01, 3, 2
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 3
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 6
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 8
	SND_SEGNO
	LOOP_START
	VOLUME $07
	RELEASE 8, 6
	DUTY_STEP 0, 0
	ENVELOPE_OFF
	ATTEN 3
	OCTAVE 2
	NOTE A_, 2
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ENVELOPE $03
	SND_CALL SndA2_Ch1_4293
	NOTE A_, 4
	DUTY 4
	NOTE G_, 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	JUMP_ON 2, SndA2_Ch2_41DC
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE G_, 2
SndA2_Ch2_41DC:
	LOOP_END 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	RELEASE $0D, 2
	LEN_UNIT 6
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 4
	DUTY 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 3
	REST 1
	ATTEN 2
	PAN_RIGHT 0
	SND_CALL SndA2_Ch1_429E
	LOOP_START
	VOICE $06, 0, 8, 0, 0
	ENVELOPE $03
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 2
	NOTE A_, 1
	NOTE B_, 2
	LEN_UNIT 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	LEN_UNIT 6
	NOTE B_, 2
	JUMP_ON 2, SndA2_Ch2_4234
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 4
	VOLUME $0B
	RELEASE 0, 0
	DUTY 8
	DUTY_STEP 0, 0
	ENVELOPE_OFF
	REST 2
	ATTEN 6
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 1
	NOTE A_, 2
	VOLUME $08
SndA2_Ch2_4234:
	LOOP_END 2
	NOTE F_, 2
	NOTE E_, 4
	REST 2
	DUTY 8
	DUTY_STEP 0, 0
	ENVELOPE_OFF
	VOLUME $0B
	ATTEN 6
	OCTAVE 3
	NOTE E_, 1
	SND_CALL SndA2_Ch1_42B2
	NOTE E_, 4
	RELEASE $0E, 3
	LOOP2_START
	ATTEN 0
	ENVELOPE $03
	DUTY 8
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE A_, 1
	NOTE B_, 1
	DUTY 0
	ENVELOPE_OFF
	LOOP_START
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 5
	LOOP_END 2
	LOOP2_END 2
	LOOP2_START
	DUTY 8
	ENVELOPE $03
	ATTEN 0
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	DUTY 0
	ENVELOPE_OFF
	JUMP_ON 2, SndA2_Ch2_4289
	LOOP_START
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 5
	LOOP_END 2
SndA2_Ch2_4289:
	LOOP2_END 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE $0F, 4
	NOTE E_, 4
	SND_LOOP
SndA2_Ch1_4293:
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 5
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	SND_RET
SndA2_Ch1_429E:
	OCTAVE 2
	NOTE A_, 2
	LEN_UNIT 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	LEN_UNIT 6
	SND_RET
SndA2_Ch1_42B2:
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 4
	NOTE E_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET

SndA2_Ch1:
	VOICE $06, 0, 5, 8, 4
	PAN_LEFT 0
	VIBRATO $02, 3, 2
	DETUNE $01
	ATTEN 3
	OCTAVE 5
	NOTE E_, 3
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 6
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 6
	SND_SEGNO
	LOOP_START
	PAN_BOTH 0
	OCTAVE 2
	NOTE E_, 3
	VOLUME $07
	PAN_RIGHT 0
	DUTY 8
	RELEASE 8, 5
	VIBRATO $01, 2, 3
	DETUNE $02
	DUTY_STEP 0, 0
	ATTEN 5
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	SND_CALL SndA2_Ch1_4293
	NOTE A_, 3
	VOICE $06, 4, 7, 15, 3
	DUTY_STEP 8, 1
	DETUNE $00
	OCTAVE 3
	NOTE D_, 3
	RELEASE $0F, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	JUMP_ON 2, SndA2_Ch1_433F
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0D, 2
	DUTY 0
	ENVELOPE_OFF
	OCTAVE 5
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	RELEASE $0D, 6
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE A_, 2
	LEN_UNIT 4
	OCTAVE 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	LEN_UNIT 6
	OCTAVE 5
	NOTE A_, 2
	NOTE G_, 2
	ATTEN 0
	PAN_LEFT 0
SndA2_Ch1_433F:
	LOOP_END 2
	OCTAVE 4
	NOTE D_, 2
	LEN_UNIT 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	LEN_UNIT 6
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 4
	RELEASE $0C, 4
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 2
	REST 2
	PAN_LEFT 0
	SND_CALL SndA2_Ch1_429E
	LOOP_START
	VOICE $06, 4, 7, 15, 3
	DUTY_STEP 8, 2
	DETUNE $00
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	JUMP_ON 2, SndA2_Ch1_438A
	NOTE E_, 2
	RELEASE $0F, 4
	NOTE C_, 4
	RELEASE 0, 0
	DUTY 8
	PAN_RIGHT 0
	DETUNE $02
	REST 2
	ATTEN 5
	OCTAVE 3
	NOTE E_, 4
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 2
	NOTE E_, 2
SndA2_Ch1_438A:
	LOOP_END 2
	NOTE C_, 2
	NOTE C_, 4
	RELEASE 0, 0
	DUTY 8
	PAN_LEFT 0
	DETUNE $02
	REST 2
	ATTEN 5
	OCTAVE 3
	NOTE E_, 3
	SND_CALL SndA2_Ch1_42B2
	NOTE E_, 2
	RELEASE $0A, 7
	DUTY 0
	PAN_BOTH 0
	DUTY_STEP 4, 1
	DETUNE $FF
	LOOP2_START
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE A_, 1
	NOTE B_, 1
	PAN_RIGHT 0
	LOOP_START
	OCTAVE 5
	NOTE E_, 2
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	PAN_LEFT 0
	LOOP_END 2
	PAN_BOTH 0
	LOOP2_END 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	LOOP_START
	OCTAVE 5
	NOTE A_, 2
	NOTE F_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	LOOP_END 2
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	DETUNE $01
	RELEASE $0F, 5
	NOTE B_, 4
	SND_LOOP

SndA2_Ch3:
	VOICE $06, 3, 2, 5, 0
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	REST 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $0B, 0, 15
	NOTE E_, 8
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_SEGNO
	LOOP2_START
	RELEASE 6, 0
	VIBRATO $09, 0, 1
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	OCTAVE 3
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	JUMP_ON 2, SndA2_Ch3_443C
	NOTE A_, 2
	REST $0E
SndA2_Ch3_443C:
	LOOP2_END 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	REST 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 4
	WAVE 1
	LOOP_START
	VIBRATO $0B, 0, 15
	OCTAVE 3
	NOTE E_, 6
	VIBRATO_OFF
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 6
	NOTE E_, 2
	JUMP_ON 2, SndA2_Ch3_4468
	VIBRATO $0B, 0, 7
	NOTE F_, $0A
	VIBRATO_OFF
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
SndA2_Ch3_4468:
	LOOP_END 2
	NOTE F_, 2
	WAVE 3
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 4
	RELEASE 6, 0
	VIBRATO $09, 0, 2
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_LOOP

SndA2_Drm:
	LEN_UNIT 6
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 7, 6
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 2
	DRUM 9, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 2
	DRUM 1, 2
	DRUM 7, 4
	SND_CALL SndA2_Drm_4508
	DRUM 2, $0A
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	SND_CALL SndA2_Drm_4508
	DRUM $0B, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 2
	SND_LOOP
SndA2_Drm_4508:
	DRUM $0B, 2
	LOOP_START
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 2
	LOOP_END 3
	DRUM 4, 1
	DRUM 4, 1
	SND_RET

SndA1_Ch1:
	SND_END

SndA3_Ch2:
	TRANSPOSE_UP 4
	TEMPO $14
	VOICE $06, 8, 8, 15, 2
	ENVELOPE $04
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE A_, 2
	LOOP_END 2
	NOTE C_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 3
	DUTY 8
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 2
	SND_SEGNO
	RELEASE $0E, 3
	DUTY 4
	VIBRATO $01, 2, 3
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	LOOP2_START
	LOOP_START
	NOTE E_, 2
	LOOP_END 5
	LEN_UNIT 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	LEN_UNIT 6
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	JUMP_ON 2, SndA3_Ch2_458D
	NOTE F#, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE G#, 2
	RELEASE $0E, 5
	NOTE B_, 6
	RELEASE $0E, 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 2
	LEN_UNIT 4
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	LEN_UNIT 6
	RELEASE $0E, 5
	NOTE F#, 6
	RELEASE $0E, 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
SndA3_Ch2_458D:
	LOOP2_END 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 2
	NOTE B_, 2
	RELEASE $0E, 5
	OCTAVE 4
	NOTE C#, 6
	RELEASE $0E, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE E_, 2
	RELEASE $0D, 7
	NOTE E_, 8
	REST 2
	SND_CALL SndA3_Ch1_4642
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	SND_CALL SndA3_Ch2_4618
	LEN_UNIT 3
	RELEASE 8, 5
	DUTY_STEP 0, 0
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 2
	ATTEN 6
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 2
	ATTEN 4
	LOOP2_END 2
	ATTEN 2
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 2
	LEN_UNIT 6
	DUTY 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	SND_CALL SndA3_Ch2_4618
	DUTY 0
	ENVELOPE $04
	LOOP_START
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE A_, 2
	LOOP_END 2
	REST 2
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 3
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 2
	SND_LOOP
SndA3_Ch2_4618:
	RELEASE $0D, 3
	DUTY 8
	VIBRATO $0A, 0, 1
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	LOOP_START
	NOTE B_, 2
	LOOP_END 5
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	VIBRATO_OFF
	SND_RET
SndA3_Ch1_4642:
	DUTY 4
	VIBRATO $0E, 0, 8
	ENVELOPE $02
	DUTY_STEP 0, 3
	SND_RET

SndA3_Ch1:
	TRANSPOSE_UP 4
	VOICE $06, 8, 6, 15, 2
	ENVELOPE $04
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE E_, 2
	LOOP_END 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 3
	DUTY 8
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	SND_SEGNO
	DETUNE $00
	LOOP_START
	RELEASE $0E, 2
	DUTY 0
	ENVELOPE_OFF
	DUTY_STEP 0, 0
	VIBRATO $02, 3, 3
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE B_, 2
	JUMP_ON 2, SndA3_Ch1_46B9
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	DUTY 8
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	DUTY 8
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE G#, 2
SndA3_Ch1_46B9:
	LOOP_END 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	DUTY 8
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE A_, 2
	DUTY 0
	NOTE B_, 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 2
	RELEASE $0E, 7
	NOTE B_, 8
	REST 2
	SND_CALL SndA3_Ch1_4642
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 5
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 2
	NOTE F#, 2
	PAN_RIGHT 0
	LOOP2_START
	ATTEN 3
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0A, 7
	DUTY 8
	VIBRATO $0A, 0, 1
	ENVELOPE_OFF
	DUTY_STEP 4, 1
	DETUNE $01
	OCTAVE 3
	NOTE B_, 5
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 1
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 4
	NOTE E_, 4
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 4
	DUTY 8
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 3
	OCTAVE 4
	NOTE C_, 5
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 1
	VIBRATO_OFF
	DETUNE $00
	PAN_BOTH 0
	ATTEN 0
	JUMP_ON 2, SndA3_Ch1_4744
	DUTY 8
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	LOOP_START
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	LOOP_END 2
SndA3_Ch1_4744:
	PAN_LEFT 0
	LOOP2_END 2
	PAN_BOTH 0
	ATTEN 0
	RELEASE $0F, 4
	DUTY 0
	LOOP_START
	REST 2
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE E_, 2
	LOOP_END 2
	PAN_LEFT 0
	ATTEN 3
	REST 2
	OCTAVE 5
	NOTE E_, 2
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	SND_LOOP

SndA3_Ch3:
	TRANSPOSE_UP 4
	AUTOPAN_R 0
	VOICE $06, 4, 2, 7, 0
	VIBRATO $09, 0, 2
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 2
	NOTE C_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	AUTOPAN_OFF 0
	RELEASE 6, 0
	NOTE B_, 3
	RELEASE 8, 0
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	SND_SEGNO
	RELEASE 6, 0
	LOOP2_START
	LOOP_START
	REST 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 2
	NOTE E_, 2
	LOOP_END 2
	JUMP_ON 2, SndA3_Ch3_47BF
	LOOP_START
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE OCT_UP, 2
	NOTE G#, 2
	LOOP_END 2
	LOOP_START
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE OCT_UP, 2
	NOTE A_, 2
	LOOP_END 2
	LOOP_START
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE OCT_UP, 2
	NOTE B_, 2
	LOOP_END 2
SndA3_Ch3_47BF:
	LOOP2_END 2
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE OCT_UP, 2
	NOTE G#, 2
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE OCT_UP, 2
	NOTE A_, 2
	REST 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 2
	NOTE E_, 2
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE OCT_UP, 2
	NOTE G#, 2
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE OCT_UP, 2
	NOTE A_, 2
	REST 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 2
	NOTE E_, 2
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	LOOP_START
	NOTE B_, 2
	LOOP_END 6
	LOOP2_START
	RELEASE 5, 0
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	LOOP_END 2
	JUMP_ON 2, SndA3_Ch3_4814
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	LOOP_END 2
SndA3_Ch3_4814:
	LOOP2_END 2
	LOOP_START
	REST 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE A_, 2
	LOOP_END 3
	NOTE B_, 3
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	SND_LOOP

SndA3_Drm:
	LEN_UNIT 6
	LOOP_START
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 2
	DRUM 7, 8
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM $0B, 2
	LOOP_END $10
	DRUM $0B, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 7
	LOOP_START
	DRUM $0B, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_LOOP

SndA4_Ch2:
	TEMPO $10
	VOICE $04, 0, 8, 14, 4
	VIBRATO $0A, 0, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D#, 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 4
	NOTE D_, 2
	RELEASE $0E, 6
	NOTE D_, $0C
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 8, 14, 5
	VIBRATO $02, 2, 3
	DUTY_STEP 0, 1
	ENVELOPE_OFF
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	SND_CALL SndA4_Ch1_4932
	NOTE E_, 2
	RELEASE $0E, 4
	NOTE G_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	JUMP_ON 2, SndA4_Ch2_48B3
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 2
	RELEASE $0E, 7
	NOTE E_, $0A
	DUTY 8
	RELEASE $0E, 4
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 2
SndA4_Ch2_48B3:
	LOOP_END 2
	LEN_UNIT 2
	DUTY_STEP 0, 0
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	LEN_UNIT 6
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN_UNIT 4
	RELEASE $0E, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	LEN_UNIT 6
	NOTE E_, 2
	NOTE E_, 2
	DUTY 4
	ENVELOPE $04
	OCTAVE 3
	NOTE A_, 1
	SND_CALL SndA4_Ch1_494E
	NOTE A_, 6
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 6
	DUTY 8
	DUTY_STEP 0, 0
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 6
	NOTE A_, 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	LEN_UNIT 6
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	LEN_UNIT 6
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 8
	RELEASE $0E, 3
	DUTY 0
	ATTEN 2
	OCTAVE 5
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_LOOP
SndA4_Ch1_4932:
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 6
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	LEN_UNIT 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	LEN_UNIT 6
	NOTE E_, 6
	DUTY 0
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	SND_RET
SndA4_Ch1_494E:
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 6
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 1
	SND_RET

SndA4_Ch1:
	VOICE $04, 0, 7, 14, 4
	DUTY_STEP 4, 1
	VIBRATO $01, 3, 2
	DETUNE $FF
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE D#, 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 4
	NOTE D_, 2
	RELEASE $0E, 6
	NOTE A_, $0C
	SND_SEGNO
	LOOP2_START
	VOICE $06, 4, 6, 14, 7
	VIBRATO $01, 3, 3
	ENVELOPE_OFF
	DUTY_STEP 0, 0
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	PAN_BOTH 0
	SND_CALL SndA4_Ch1_4932
	NOTE E_, 1
	ATTEN 0
	RELEASE $0E, 3
	NOTE E_, 1
	NOTE E_, 2
	JUMP_ON 2, SndA4_Ch1_49CE
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	PAN_LEFT 0
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	ATTEN 2
	PAN_RIGHT 0
	LOOP_END 2
	ATTEN 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 2
SndA4_Ch1_49CE:
	LOOP2_END 2
	NOTE C_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	REST 2
	OCTAVE 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	DUTY 8
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	LEN_UNIT 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	LEN_UNIT 6
	NOTE B_, 2
	NOTE B_, 2
	VOICE $06, 4, 6, 14, 7
	PAN_LEFT 0
	ATTEN 3
	NOTE A_, 2
	SND_CALL SndA4_Ch1_494E
	NOTE A_, 5
	ATTEN 0
	PAN_BOTH 0
	DUTY 8
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 6
	DUTY 8
	ENVELOPE $04
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 6
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE E_, 6
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 8
	DUTY 0
	PAN_RIGHT 0
	RELEASE 0, 0
	OCTAVE 5
	ATTEN 5
	NOTE E_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 0
	SND_LOOP

SndA4_Ch3:
	VOICE $04, 3, 2, 5, 0
	VIBRATO $09, 0, 2
	DETUNE $FF
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE D#, 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 6
	RELEASE 4, 8
	OCTAVE 2
	NOTE D_, 6
	SND_SEGNO
	VOICE $06, 3, 2, 6, 0
	LOOP2_START
	LOOP_START
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	JUMP_ON 2, SndA4_Ch3_4A8D
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 3
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
SndA4_Ch3_4A8D:
	LOOP2_END 2
	RELEASE 0, 0
	NOTE B_, 2
	LEN_UNIT 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	LEN_UNIT 6
	OCTAVE 1
	RELEASE 6, 0
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP2_START
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	JUMP_ON 2, SndA4_Ch3_4AC7
	OCTAVE 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
SndA4_Ch3_4AC7:
	LOOP2_END 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	JUMP_ON 2, SndA4_Ch3_4AF6
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
SndA4_Ch3_4AF6:
	LOOP_END 2
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_LOOP

SndA4_Drm:
	LEN_UNIT 4
	DRUM $0B, 4
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 4
	DRUM 1, 2
	DRUM 1, 4
	DRUM 1, 2
	DRUM 1, 4
	DRUM 1, 2
	DRUM 4, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 4
	DRUM 1, 2
	LEN_UNIT 6
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LEN_UNIT 6
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 7
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 7, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	LOOP_START
	DRUM 4, 1
	LOOP_END 6
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 8
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndA5_Ch2:
	TEMPO $10
	TRANSPOSE_DOWN 3
	VOICE $06, 8, 8, 14, 4
	VIBRATO $02, 3, 3
	ENVELOPE $08
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 2
	NOTE E_, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	ENVELOPE $0A
	OCTAVE 4
	NOTE B_, 8
	ENVELOPE $08
	OCTAVE 2
	NOTE E_, 1
	DUTY 0
	ENVELOPE_OFF
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	ENVELOPE $0A
	NOTE A_, 8
	DUTY 8
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	SND_SEGNO
	RELEASE $0E, 4
	DUTY 4
	VIBRATO $0A, 0, 1
	ENVELOPE $04
	DUTY_STEP 0, 1
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	JUMP_ON 2, SndA5_Ch2_4C00
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 3
	NOTE E_, 1
	NOTE F#, 2
	NOTE C#, 2
	NOTE E_, 2
	DUTY 0
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 4
	DUTY 4
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	LEN_UNIT 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	LEN_UNIT 6
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
SndA5_Ch2_4C00:
	LOOP_END 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE B_, 4
	SND_CALL SndA5_Ch1_4C83
	DUTY 0
	DUTY_STEP 8, 1
	NOTE A_, 3
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	DUTY 8
	ENVELOPE $08
	NOTE B_, 6
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 6
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 8
	NOTE E_, 6
	LEN_UNIT 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 8
	DUTY 4
	ENVELOPE $04
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	DUTY 0
	LEN_UNIT 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	REST 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 8
	DUTY 0
	OCTAVE 3
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	SND_LOOP
SndA5_Ch1_4C83:
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	SND_RET

SndA5_Ch1:
	TRANSPOSE_DOWN 3
	VOICE $06, 8, 7, 10, 6
	VIBRATO $02, 4, 3
	ENVELOPE $08
	DUTY_STEP 4, 1
	DETUNE $FF
	ATTEN 1
	REST 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE A_, 2
	DUTY 0
	ENVELOPE $0A
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 1
	PAN_LEFT 0
	OCTAVE 5
	ATTEN 4
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 2
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 3
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 3
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 2
	SND_SEGNO
	DUTY 4
	ENVELOPE $04
	DUTY_STEP 0, 1
	ATTEN 2
	OCTAVE 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 3
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	DUTY 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	DUTY 4
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE C#, 2
	NOTE F#, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE A_, 2
	NOTE G#, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE G#, 4
	NOTE G#, 4
	TRANSPOSE_DOWN $0F
	SND_CALL SndA5_Ch1_4C83
	TRANSPOSE_DOWN 3
	OCTAVE 4
	NOTE E_, 3
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY 0
	VIBRATO $0A, 0, 2
	ENVELOPE_OFF
	DUTY_STEP 8, 1
	NOTE G#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	PAN_BOTH 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G#, 4
	NOTE E_, 4
	NOTE G#, 2
	PAN_LEFT 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	PAN_BOTH 0
	ENVELOPE $04
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 4
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 0
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	REST 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 8
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	SND_LOOP

SndA5_Ch3:
	TRANSPOSE_DOWN 3
	VOICE $06, 4, 2, 5, 0
	VIBRATO $09, 0, 3
	OCTAVE 2
	NOTE A_, 6
	NOTE A_, 1
	NOTE A_, 1
	NOTE D_, 6
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	REST 4
	NOTE E_, 2
	NOTE A_, 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE B_, 2
	NOTE B_, 2
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE A_, 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE F#, 2
	LOOP_END 3
	NOTE A_, 3
	NOTE A_, 1
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 3
	NOTE F#, 1
	NOTE C#, 2
	NOTE E_, 2
	NOTE F#, 3
	NOTE F#, 1
	NOTE A_, 2
	NOTE F#, 2
	NOTE B_, 3
	NOTE B_, 1
	NOTE F#, 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE G#, 2
	LOOP_START
	NOTE A_, 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE E_, 2
	LOOP_END 2
	NOTE A_, 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE A_, 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	AUTOPAN_R 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	AUTOPAN_OFF 0
	REST 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE E_, 3
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_LOOP

SndA5_Drm:
	LEN_UNIT 6
	DRUM 4, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 6
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END $0F
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END $0B
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 6
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndA6_Ch2:
	TRANSPOSE_UP 3
	TEMPO $10
	SND_SEGNO
	VOICE $06, 0, 8, 15, 6
	DUTY_STEP 4, 1
	ENVELOPE $04
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	ATTEN 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	ATTEN 1
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 4
	ATTEN 0
	ENVELOPE $03
	NOTE D_, 4
	VIBRATO $01, 4, 4
	LOOP_START
	DUTY 0
	ENVELOPE $04
	DUTY_STEP 0, 0
	OCTAVE 1
	NOTE C_, 2
	DUTY 8
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	JUMP_ON 2, SndA6_Ch2_4EEC
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	NOTE D_, 2
	ENVELOPE $03
	NOTE E_, 6
	ENVELOPE $04
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 4
SndA6_Ch2_4EEC:
	LOOP_END 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE C_, 1
	ENVELOPE $03
	NOTE D_, 6
	ENVELOPE $04
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 2
	LOOP_START
	DUTY 0
	ENVELOPE $05
	DUTY_STEP 4, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 4
	DUTY 4
	JUMP_ON 2, SndA6_Ch2_4F2C
	REST 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 2
SndA6_Ch2_4F2C:
	LOOP_END 2
	NOTE G_, 1
	ATTEN 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE $0F, 6
	VIBRATO $0A, 0, 4
	DUTY_STEP 1, 0
	SND_CALL SndA6_Ch1_4F51
	SND_LOOP
SndA6_Ch1_4F51:
	LOOP_START
	DUTY 4
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 3
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 6
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 3
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	DUTY 0
	REST 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 2
	NOTE E_, 2
	LOOP_END 2
	SND_RET

SndA6_Ch1:
	TRANSPOSE_UP 3
	SND_SEGNO
	VOICE $06, 4, 7, 15, 4
	ENVELOPE $04
	VIBRATO $02, 2, 3
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE G#, 4
	ENVELOPE $03
	NOTE B_, 4
	ENVELOPE_OFF
	RELEASE 8, 3
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	ENVELOPE $03
	NOTE A_, 6
	ENVELOPE_OFF
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F_, 2
	ENVELOPE $03
	NOTE A_, 4
	ENVELOPE_OFF
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE F_, 2
	DETUNE $FF
	LOOP_START
	DUTY 0
	ENVELOPE $05
	ATTEN 2
	OCTAVE 3
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 4
	ENVELOPE_OFF
	ATTEN 4
	DUTY 4
	JUMP_ON 2, SndA6_Ch1_500F
	REST 4
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
SndA6_Ch1_500F:
	LOOP_END 2
	PAN_LEFT 0
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	VIBRATO $0C, 0, 4
	ENVELOPE $05
	DETUNE $00
	TRANSPOSE_DOWN 2
	SND_CALL SndA6_Ch1_4F51
	TRANSPOSE_UP 3
	SND_LOOP

SndA6_Ch3:
	TRANSPOSE_UP 3
	SND_SEGNO
	VOICE $06, 3, 2, 8, 0
	OCTAVE 2
	NOTE A_, 4
	REST 2
	NOTE A_, 2
	NOTE F_, 4
	REST 2
	NOTE F_, 2
	NOTE D_, 4
	REST 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE E_, 4
	NOTE G_, 2
	LEN_UNIT 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT 6
	RELEASE 6, 0
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_CALL SndA6_Ch3_50D4
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F_, 1
	NOTE OCT_UP, 2
	NOTE OCT_UP, 1
	NOTE F_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 2
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_CALL SndA6_Ch3_50D4
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE C_, 1
	NOTE F_, 1
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE F#, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE D_, 1
	NOTE F#, 1
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	RELEASE 2, 0
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	NOTE B_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	NOTE C_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	NOTE F_, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	LOOP_START
	NOTE G_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP2_END 2
	SND_LOOP
SndA6_Ch3_50D4:
	OCTAVE 1
	NOTE G_, 1
	NOTE OCT_UP, 2
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_RET

SndA6_Drm:
	SND_SEGNO
	LEN_UNIT 6
	LOOP_START
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 4, 2
	LOOP_END 3
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 4
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END $0F
	LOOP_START
	DRUM 4, 1
	LOOP_END 8
	SND_LOOP

SndA7_Ch2:
	TRANSPOSE_UP 3
	TEMPO $10
	VOICE $06, 0, 8, 12, 6
	DUTY_STEP 4, 1
	VIBRATO $01, 3, 3
	OCTAVE 4
	NOTE B_, 6
	LEN_UNIT 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	LEN_UNIT 6
	NOTE F#, 6
	NOTE E_, 2
	NOTE C_, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 6
	SND_SEGNO
	VOICE $06, 4, 8, 0, 0
	VIBRATO $0A, 0, 1
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F#, 2
	ATTEN 5
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	NOTE F#, 2
	ENVELOPE $0B
	NOTE G_, $0E
	LOOP_START
	LEN_UNIT 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	LEN_UNIT 6
	RELEASE $0D, 5
	ENVELOPE_OFF
	NOTE E_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 8
	JUMP_ON 2, SndA7_Ch2_5196
	RELEASE $0D, 3
	DUTY 8
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 2
	RELEASE $0C, 5
	PAN_BOTH 0
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 3
	NOTE G_, 1
	NOTE F#, 2
SndA7_Ch2_5196:
	LOOP_END 2
	DUTY_STEP 4, 1
	DUTY 0
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	VOICE $06, 8, 8, 11, 6
	VIBRATO $02, 3, 2
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 6
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 8
	RELEASE $0D, 5
	NOTE E_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	SND_CALL SndA3_Ch1_4642
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	REST 4
	SND_LOOP

SndA7_Ch1:
	TRANSPOSE_UP 3
	VOICE $06, 4, 7, 12, 5
	DUTY_STEP 0, 1
	VIBRATO $02, 3, 3
	OCTAVE 4
	NOTE F#, 6
	LEN_UNIT 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	LEN_UNIT 6
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE F#, 4
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 6
	SND_SEGNO
	VOICE $06, 4, 7, 0, 0
	VIBRATO $02, 2, 2
	DUTY_STEP 4, 1
	DETUNE $FE
	OCTAVE 2
	NOTE F#, 2
	ATTEN 5
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 0
	NOTE B_, 2
	RELEASE 0, 0
	AUTOPAN_R 0
	DETUNE $FF
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 5
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 3
	OCTAVE 3
	NOTE E_, 2
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	AUTOPAN_OFF 0
	ATTEN 0
	NOTE G_, 2
	NOTE B_, 2
	RELEASE $0C, 3
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 2
	DUTY 8
	DUTY_STEP 0, 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	ATTEN 4
	PAN_LEFT 0
	OCTAVE 3
	NOTE C_, 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 3
	VOICE $06, 4, 7, 12, 3
	DUTY_STEP 4, 1
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	AUTOPAN_L 0
	ATTEN 0
	NOTE B_, 2
	NOTE G_, 2
	ATTEN 5
	NOTE B_, 2
	NOTE G_, 2
	ATTEN 3
	NOTE B_, 2
	NOTE G_, 2
	ATTEN 0
	NOTE B_, 2
	NOTE G_, 2
	RELEASE $0C, 3
	DUTY 0
	AUTOPAN_OFF 0
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	DETUNE $FE
	RELEASE $0C, 5
	NOTE A_, 6
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 6
	NOTE A_, 2
	NOTE G_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 6
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 8
	DUTY 4
	RELEASE $0C, 3
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	DETUNE $01
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE C_, 2
	DETUNE $00
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 2
	DETUNE $01
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE E_, 2
	DETUNE $00
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	DUTY 0
	VIBRATO $09, 0, 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	REST 4
	SND_LOOP

SndA7_Ch3:
	TRANSPOSE_UP 3
	VOICE $06, 4, 2, 0, 0
	OCTAVE 2
	NOTE E_, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 6
	REST $0A
	SND_SEGNO
	RELEASE 6, 0
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	LOOP_END 3
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	JUMP_ON 2, SndA7_Ch3_5323
	SND_CALL SndA7_Ch3_5392
SndA7_Ch3_5323:
	LOOP2_END 2
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	SND_CALL SndA7_Ch3_5392
	SND_CALL SndA7_Ch3_5384
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE B_, 1
	NOTE B_, 1
	LOOP_END 2
	SND_CALL SndA7_Ch3_5384
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	REST 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE F#, 2
	SND_LOOP
SndA7_Ch3_5384:
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 2
	SND_RET
SndA7_Ch3_5392:
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	LOOP_END 2
	SND_RET

SndA7_Drm:
	LEN_UNIT 6
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 6
	DRUM 5, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 5, 2
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END $0C
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 7, $0A
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndA8_Ch2:
	TRANSPOSE_DOWN 3
	TEMPO $10
	VOICE $06, 8, 8, 15, 3
	DETUNE $01
	LOOP_START
	SND_CALL SndA8_Ch1_5615
	LOOP_END 2
	DETUNE $00
	SND_SEGNO
	LOOP_START
	VOICE $06, 0, 8, 8, 5
	VIBRATO $01, 3, 3
	SND_CALL SndA8_Ch1_5491
	NOTE B_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	DUTY 4
	ATTEN 1
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 1
	NOTE A_, 2
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE F_, 2
	NOTE A_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	NOTE F_, 2
	NOTE E_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	NOTE E_, 6
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	DUTY 4
	ATTEN 0
	OCTAVE 5
	NOTE F_, 2
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 2
	NOTE D_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 2
	NOTE D_, 2
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	ATTEN 6
	NOTE D_, 1
	OCTAVE 4
	ATTEN 2
	NOTE B_, 2
	NOTE A_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 1
	NOTE A_, 2
	NOTE F_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 2
	NOTE E_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 0
	DUTY 0
	RELEASE $0F, 2
	NOTE B_, 1
	NOTE OCT_UP, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE OCT_UP, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE F_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE F_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP2_START
	VOICE $06, 0, 9, 15, 3
	DUTY_STEP 4, 1
	LOOP_START
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	LOOP_END 3
	ATTEN 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	LOOP_START
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	LOOP_END 2
	JUMP_ON 2, SndA8_Ch2_5482
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
SndA8_Ch2_5482:
	LOOP2_END 2
	DUTY 8
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	SND_LOOP
SndA8_Ch1_5491:
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 6
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 4
	DUTY 8
	SND_RET

SndA8_Ch1:
	TRANSPOSE_DOWN 3
	VOICE $06, 8, 7, 15, 3
	DETUNE $EF
	AUTOPAN_R 0
	VIBRATO $02, 4, 4
	LOOP_START
	SND_CALL SndA8_Ch1_5615
	LOOP_END 2
	DETUNE $FF
	AUTOPAN_OFF 0
	SND_SEGNO
	VOICE $06, 0, 6, 8, 7
	PAN_RIGHT 0
	VIBRATO $02, 0, 2
	LOOP2_START
	DUTY_STEP 0, 0
	ATTEN 2
	REST 1
	SND_CALL SndA8_Ch1_5491
	DUTY 8
	ATTEN 2
	PAN_BOTH 0
	VIBRATO $02, 0, 10
	REST 1
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 2
	VIBRATO $02, 3, 3
	DUTY 4
	ATTEN 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 2
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	ATTEN 5
	NOTE E_, 1
	DUTY 0
	VIBRATO $02, 0, 4
	PAN_LEFT 0
	ATTEN 3
	REST 1
	OCTAVE 4
	NOTE E_, 6
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 1
	VIBRATO $0A, 0, 3
	PAN_BOTH 0
	DUTY 4
	ATTEN 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 4
	NOTE F_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 2
	NOTE E_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 2
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	ATTEN 5
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE F_, 2
	NOTE A_, 2
	DUTY 0
	LOOP_START
	PAN_LEFT 0
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	LOOP_END 2
	DUTY 0
	RELEASE $0A, 5
	AUTOPAN_R 0
	ATTEN 1
	OCTAVE 4
	NOTE B_, 2
	NOTE OCT_UP, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE OCT_UP, 1
	OCTAVE 4
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 2
	NOTE F_, 1
	NOTE OCT_UP, 2
	NOTE A_, 1
	NOTE OCT_UP, 1
	VOICE $06, 0, 6, 8, 7
	AUTOPAN_OFF 0
	PAN_LEFT 0
	LOOP2_END 2
	LOOP2_START
	VOICE $06, 4, 7, 15, 2
	LOOP_START
	PAN_RIGHT 0
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	PAN_LEFT 0
	OCTAVE 3
	NOTE B_, 1
	LOOP_END 4
	PAN_BOTH 0
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE $0A, 5
	NOTE F_, 6
	DUTY 8
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	JUMP_ON 2, SndA8_Ch1_559C
	DUTY 8
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
SndA8_Ch1_559C:
	LOOP2_END 2
	ATTEN 3
	RELEASE 8, 4
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	SND_LOOP

SndA8_Ch3:
	TRANSPOSE_UP 9
	VOICE $06, 3, 2, 13, 4
	LOOP_START
	SND_CALL SndA8_Ch1_5615
	LOOP_END 2
	SND_SEGNO
	RELEASE $0D, 4
	LOOP2_START
	LOOP_START
	SND_CALL SndA8_Ch1_5615
	LOOP_END 2
	LOOP_START
	SND_CALL SndA8_Ch3_5624
	LOOP_END 2
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE F#, 1
	LOOP_START
	SND_CALL SndA8_Ch3_5624
	LOOP_END 2
	LOOP_START
	SND_CALL SndA8_Ch1_5615
	LOOP_END 2
	LOOP2_END 2
	RELEASE 3, 7
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE E_, 1
	LOOP_END 4
	NOTE F_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE E_, 1
	LOOP_END 4
	NOTE F_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	SND_LOOP
SndA8_Ch1_5615:
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	SND_RET
SndA8_Ch3_5624:
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	SND_RET

SndA8_Drm:
	LEN_UNIT 6
	LOOP_START
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 6
	LOOP_START
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	LOOP_END 2
	SND_SEGNO
	LOOP2_START
	LOOP_START
	SND_CALL SndA8_Drm_566B
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0B, 1
	LOOP_END 8
	SND_CALL SndA8_Drm_566B
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LOOP2_END 2
	LOOP_START
	SND_CALL SndA8_Drm_5677
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	SND_CALL SndA8_Drm_5677
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	SND_LOOP
SndA8_Drm_566B:
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	SND_RET
SndA8_Drm_5677:
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	SND_RET

SndA9_Ch2:
	TEMPO $10
	VOICE $06, 8, 8, 10, 6
	SND_CALL SndA9_Ch1_57A0
	VIBRATO $0E, 0, 8
	OCTAVE 4
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	SND_SEGNO
	SND_CALL SndA9_Ch2_5761
	LOOP_START
	VOICE $06, 8, 8, 7, 7
	DUTY_STEP 4, 1
	VIBRATO $01, 4, 2
	ENVELOPE_OFF
	ATTEN 2
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 3
	NOTE C#, 4
	ATTEN 1
	NOTE D#, 4
	ATTEN 0
	NOTE F#, 4
	NOTE F#, 4
	ATTEN 1
	NOTE G#, 4
	ATTEN 2
	OCTAVE 4
	NOTE C#, 4
	ATTEN 1
	OCTAVE 3
	NOTE A#, 8
	JUMP_ON 2, SndA9_Ch2_56DE
	NOTE G#, 4
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	NOTE G#, 4
	ATTEN 1
	NOTE F#, 4
	NOTE D#, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE A#, 0
	RELEASE $0D, 2
	DUTY 0
	OCTAVE 5
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C#, 1
SndA9_Ch2_56DE:
	LOOP_END 2
	ATTEN 2
	OCTAVE 4
	NOTE C#, 4
	NOTE D#, 4
	ATTEN 1
	NOTE F#, 4
	NOTE G#, 4
	ATTEN 0
	NOTE D#, 4
	NOTE C#, 4
	NOTE D#, $0E
	ATTEN 2
	OCTAVE 5
	NOTE D#, 2
	RELEASE $0D, 3
	ATTEN 1
	OCTAVE 4
	LOOP_START
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE G#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE D#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE C#, 1
	JUMP_ON 2, SndA9_Ch2_5718
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
SndA9_Ch2_5718:
	LOOP_END 2
	PAN_BOTH 0
	ATTEN 0
	SND_CALL SndA9_Ch1_57A0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 2
	NOTE A#, 2
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	VIBRATO_OFF
	OCTAVE 5
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	VIBRATO $0E, 0, 2
	LOOP_END 2
	PAN_BOTH 0
	ATTEN 0
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 2
	NOTE G#, 2
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	SND_CALL SndA9_Ch2_5761
	SND_LOOP
SndA9_Ch2_5761:
	VIBRATO $0E, 0, 5
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	LOOP_END 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	VIBRATO $0E, 0, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	VIBRATO $0E, 0, 2
	NOTE F#, 2
	LOOP_START
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 2
	LOOP_END 2
	VIBRATO $0E, 0, 5
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	VIBRATO $0E, 0, 6
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_RET
SndA9_Ch1_57A0:
	DUTY 4
	VIBRATO $0E, 0, 2
	ENVELOPE $0C
	DUTY_STEP 0, 3
	SND_RET

SndA9_Ch1:
	VOICE $06, 4, 7, 12, 6
	SND_CALL SndA9_Ch1_57A0
	VIBRATO $0E, 0, 7
	DETUNE $01
	OCTAVE 3
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	DETUNE $FF
	VIBRATO $0E, 0, 4
	SND_SEGNO
	ATTEN 1
	SND_CALL SndA9_Ch1_58BC
	LOOP2_START
	ATTEN 3
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	ATTEN 2
	LOOP_END 2
	JUMP_ON 2, SndA9_Ch1_57FA
	ATTEN 0
	LOOP_START
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	ATTEN 1
	LOOP_END 2
	SND_CALL SndA9_Ch1_58F3
	ATTEN 0
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 2
	ATTEN 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
SndA9_Ch1_57FA:
	LOOP2_END 2
	ATTEN 0
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 1
	ATTEN 2
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	DUTY 0
	ENVELOPE_OFF
	PAN_RIGHT 0
	ATTEN 4
	DUTY_STEP 4, 1
	VIBRATO_OFF
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	PAN_LEFT 0
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	PAN_BOTH 0
	ATTEN 0
	SND_CALL SndA9_Ch1_57A0
	ATTEN 3
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	ATTEN 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 2
	NOTE A#, 2
	NOTE F#, 2
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G#, 1
	SND_CALL SndA9_Ch1_58F3
	ATTEN 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	DUTY 8
	DUTY_STEP 4, 1
	VIBRATO_OFF
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	LOOP_START
	NOTE G#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 1
	LOOP_END 2
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	SND_CALL SndA9_Ch1_57A0
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 2
	NOTE D#, 2
	VIBRATO_OFF
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 5
	NOTE F_, 2
	NOTE F_, 1
	NOTE D#, 1
	JUMP_ON 2, SndA9_Ch1_58A8
	PAN_BOTH 0
	ATTEN 0
SndA9_Ch1_58A8:
	LOOP_END 2
	REST 3
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 2
	NOTE G#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE G#, 2
	NOTE G#, 2
	SND_CALL SndA9_Ch1_58BC
	SND_LOOP
SndA9_Ch1_58BC:
	ATTEN 0
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 2
	LOOP_END 2
	NOTE A#, 2
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 2
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	LOOP_END 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	SND_RET
SndA9_Ch1_58F3:
	ATTEN 3
	LOOP_START
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 2
	ATTEN 2
	LOOP_END 2
	SND_RET

SndA9_Ch3:
	VOICE $06, 3, 2, 6, 0
	REST $0E
	SND_SEGNO
	SND_CALL SndA9_Ch3_5969
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE C#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	SND_CALL SndA9_Ch3_5994
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	SND_CALL SndA9_Ch3_5994
	LOOP2_END 2
	VIBRATO $0A, 0, 2
	LOOP_START
	RELEASE 6, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	REST 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	RELEASE 4, 4
	NOTE F_, 6
	RELEASE 6, 2
	NOTE F_, 1
	NOTE F_, 1
	JUMP_ON 2, SndA9_Ch3_5955
	RELEASE 4, 4
	NOTE D#, 6
	RELEASE 6, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 2
SndA9_Ch3_5955:
	LOOP_END 2
	RELEASE 2, 0
	OCTAVE 2
	NOTE A#, 8
	RELEASE 6, 0
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	SND_CALL SndA9_Ch3_5969
	VIBRATO_OFF
	SND_LOOP
SndA9_Ch3_5969:
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE D#, 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE C#, 2
	NOTE D#, 2
	NOTE F#, 3
	NOTE F#, 1
	NOTE C#, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 3
	NOTE G#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_RET
SndA9_Ch3_5994:
	LOOP_START
	NOTE G#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE A#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	SND_RET

SndA9_Drm:
	LEN_UNIT 6
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 6, 2
	DRUM 6, 2
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 7
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL SndA9_Drm_59F1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL SndA9_Drm_59F1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM 7, $0A
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 8
	SND_LOOP
SndA9_Drm_59F1:
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 5
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_RET

SndAA_Ch2:
	TEMPO $10
	VOICE $04, 0, 8, 8, 5
	VIBRATO $01, 4, 1
	DUTY_STEP 4, 1
	OCTAVE 5
	NOTE C_, 7
	NOTE C#, 1
	NOTE C_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 8
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 2
	LEN_UNIT 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	LEN_UNIT 6
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 6
	SND_SEGNO
	VOICE $06, 4, 8, 14, 4
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE F_, 2
	SND_CALL SndAA_Ch1_5AEF
	DUTY 8
	RELEASE 0, 0
	DUTY_STEP 0, 0
	ATTEN 3
	OCTAVE 3
	NOTE F_, 2
	ATTEN 1
	NOTE F#, 2
	NOTE A#, 2
	RELEASE $0F, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	ATTEN 6
	PAN_LEFT 0
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 7
	PAN_BOTH 0
	ATTEN 0
	SND_CALL SndA9_Ch1_57A0
	VIBRATO $0E, 0, 2
	DUTY 4
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 5
	OCTAVE 4
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE F_, 2
	OCTAVE 5
	NOTE C_, 2
	LEN_UNIT 4
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT 6
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE D#, 1
	VOICE $06, 8, 8, 14, 5
	VIBRATO_OFF
	DUTY_STEP 0, 1
	ENVELOPE_OFF
	SND_CALL SndAA_Ch1_5AD7
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	DUTY 0
	LOOP_START
	ATTEN 0
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 5
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 5
	OCTAVE 5
	NOTE C_, 1
	PAN_BOTH 0
	JUMP_ON 2, SndAA_Ch2_5AC4
	OCTAVE 4
	NOTE A#, 1
SndAA_Ch2_5AC4:
	LOOP_END 2
	ATTEN 0
	DUTY_STEP 4, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 6
	SND_LOOP
SndAA_Ch1_5AD7:
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	SND_RET
SndAA_Ch1_5AEF:
	NOTE F_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE C#, 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE F#, 2
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	LEN_UNIT 4
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	LEN_UNIT 6
	NOTE F#, 2
	NOTE D#, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	SND_RET

SndAA_Ch1:
	VOICE $04, 0, 7, 8, 5
	ATTEN 3
	VIBRATO $02, 3, 1
	PAN_RIGHT 0
	DETUNE $FF
	REST 3
	OCTAVE 5
	NOTE C_, 7
	NOTE C#, 1
	NOTE C_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 4
	DETUNE $00
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 1
	NOTE F#, 2
	NOTE F_, 2
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 2
	NOTE F_, 2
	LEN_UNIT 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT 6
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 6
	SND_SEGNO
	VOICE $06, 4, 3, 14, 4
	DUTY_STEP 0, 0
	DETUNE $FF
	ATTEN 0
	OCTAVE 4
	NOTE F_, 3
	SND_CALL SndAA_Ch1_5AEF
	VOICE $06, 8, 7, 0, 0
	ATTEN 5
	OCTAVE 3
	NOTE F_, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 3
	NOTE A#, 1
	PAN_BOTH 0
	NOTE F_, 2
	RELEASE 8, 6
	DETUNE $00
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	DUTY 4
	RELEASE $0E, 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 4
	DUTY_STEP 0, 1
	ATTEN 1
	RELEASE $0E, 2
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	LOOP_END 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F#, 2
	LEN_UNIT 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	LEN_UNIT 6
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	REST 1
	ATTEN 5
	PAN_LEFT 0
	SND_CALL SndAA_Ch1_5AD7
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 2
	DETUNE $00
	ATTEN 1
	DUTY 0
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	DUTY_STEP 4, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 6
	SND_LOOP

SndAA_Ch3:
	VOICE $06, 3, 3, 9, 6
	VIBRATO $0A, 0, 5
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 3
	NOTE F_, 1
	NOTE F#, 2
	NOTE A#, 2
	WAVE 2
	LEN_UNIT 4
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 6
	LEN_UNIT 6
	WAVE 3
	OCTAVE 4
	NOTE A#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	SND_SEGNO
	WAVE 3
	RELEASE 6, 1
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 1
	NOTE A#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	LOOP_END 3
	OCTAVE 2
	NOTE D#, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 2
	WAVE 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	RELEASE 6, 5
	OCTAVE 3
	NOTE C_, 2
	DETUNE $FF
	NOTE F_, 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $FE
	NOTE F_, 6
	WAVE 3
	RELEASE 9, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	LOOP_START
	NOTE D#, 2
	NOTE A#, 1
	NOTE A#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END 4
	REST 0
	REST 0
	TRANSPOSE_UP $0C
	SND_CALL SndAA_Ch1_5AD7
	NOTE F_, 2
	TRANSPOSE_UP 0
	SND_LOOP

SndAA_Drm:
	LEN_UNIT 6
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 7, $0A
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 0
	REST $0A
	LOOP_START
	DRUM 4, 1
	LOOP_END 6
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 4
	DRUM 8, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndAB_Ch2:
	TEMPO $08
	VOICE $06, 8, 8, 12, 5
	DUTY_STEP 4, 1
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 6
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 4
	DUTY 0
	LEN_UNIT 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
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
	LEN_UNIT 6
	RELEASE $0E, 3
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	ATTEN 5
	PAN_LEFT 0
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 5
	PAN_RIGHT 0
	NOTE F#, 2
	REST 6
	SND_SEGNO
	LOOP_START
	VIBRATO $01, 3, 2
	VOICE $06, 4, 8, 14, 4
	DUTY_STEP 0, 1
	DETUNE $FF
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0C, 7
	NOTE D#, $0A
	RELEASE $0E, 4
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE B_, 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	LEN_UNIT 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	LEN_UNIT 6
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	LEN_UNIT 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	LEN_UNIT 6
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 2
	RELEASE $0C, 5
	NOTE F#, 4
	RELEASE $0E, 4
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	RELEASE $0C, 5
	NOTE B_, 6
	RELEASE $0E, 4
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	RELEASE $0C, 7
	JUMP_ON 2, SndAB_Ch2_5DD6
	NOTE D#, 5
	RELEASE $0E, 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE C#, 2
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 1
	NOTE F#, 1
	RELEASE $0C, 7
	NOTE G#, 5
	RELEASE $0E, 4
	DUTY 0
	DUTY_STEP 8, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	RELEASE $0C, 7
	NOTE D#, 6
	RELEASE $0E, 4
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 2
	NOTE F#, 1
	NOTE D#, 1
	RELEASE $0C, 7
	NOTE C#, 4
SndAB_Ch2_5DD6:
	LOOP_END 2
	NOTE D#, 5
	DUTY_STEP 8, 1
	DUTY 0
	RELEASE $0E, 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0C, 7
	NOTE B_, 4
	VIBRATO $0A, 0, 3
	SND_CALL SndAB_Ch1_5E06
	NOTE G#, $0C
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, $0A
	RELEASE $0E, 3
	DUTY 0
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	SND_LOOP
SndAB_Ch1_5E06:
	RELEASE $0E, 4
	DUTY 8
	DUTY_STEP 4, 1
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 1
	NOTE D#, 1
	RELEASE $0C, 7
	NOTE D#, 4
	RELEASE $0E, 4
	NOTE F#, 3
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE F#, 2
	NOTE D#, 2
	NOTE C#, 3
	NOTE D#, 1
	RELEASE $0C, 7
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 4
	NOTE D#, 2
	NOTE F#, 2
	SND_RET

SndAB_Ch1:
	VOICE $06, 8, 7, 12, 5
	DUTY_STEP 4, 1
	VIBRATO $02, 3, 3
	OCTAVE 2
	NOTE F#, 6
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 6
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 4
	RELEASE $0E, 3
	DUTY_STEP 0, 0
	DUTY 0
	LEN_UNIT 1
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
	NOTE C_, 1
	LEN_UNIT 6
	DUTY_STEP 4, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	PAN_LEFT 0
	ATTEN 5
	NOTE C#, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	PAN_RIGHT 0
	ATTEN 5
	NOTE C#, 3
	REST 5
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 6, 14, 3
	DETUNE $FE
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE G#, 1
	DETUNE $00
	DUTY 8
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 2
	RELEASE $0C, 5
	NOTE G_, 6
	RELEASE $0E, 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 4
	DUTY 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE G#, 2
	NOTE E_, 2
	DETUNE $FE
	PAN_LEFT 0
	ATTEN 2
	REST 1
	OCTAVE 4
	NOTE C#, 2
	LEN_UNIT 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	LEN_UNIT 6
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE E_, 2
	DETUNE $FE
	PAN_RIGHT 0
	ATTEN 2
	REST 1
	OCTAVE 4
	NOTE C#, 2
	LEN_UNIT 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	LEN_UNIT 6
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 0
	RELEASE $0C, 5
	OCTAVE 3
	NOTE D#, 5
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 4
	NOTE D#, 4
	JUMP_ON 2, SndAB_Ch1_5F23
	NOTE G#, 5
	DUTY 0
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 5
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 4
SndAB_Ch1_5F23:
	LOOP_END 2
	NOTE B_, 5
	DUTY 0
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 3
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 4
	TRANSPOSE_DOWN 5
	SND_CALL SndAB_Ch1_5E06
	TRANSPOSE_DOWN 0
	RELEASE $0C, 5
	NOTE D#, 5
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, $0A
	RELEASE $0E, 4
	DUTY 0
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	SND_LOOP

SndAB_Ch3:
	TRANSPOSE_UP $0C
	VOICE $06, 3, 2, 6, 0
	LOOP_START
	OCTAVE 1
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	NOTE F#, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	REST 8
	SND_SEGNO
	PAN_BOTH 0
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE D#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 8
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	JUMP_ON 2, SndAB_Ch3_5FC8
	NOTE G#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
SndAB_Ch3_5FC8:
	LOOP2_END 2
	NOTE B_, 3
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 4
	NOTE F#, 2
	NOTE G_, 2
	LOOP_START
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 6
	LOOP_START
	PAN_BOTH 0
	NOTE F#, 2
	PAN_RIGHT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	PAN_BOTH 0
	NOTE F#, 2
	PAN_LEFT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	PAN_BOTH 0
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_LOOP

SndAB_Drm:
	LEN_UNIT 6
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	REST 4
	DRUM 7, 4
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END $0F
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END $0D
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM 4, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 4, 2
	DRUM $0B, 2
	LOOP_END 5
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndAC_Ch2:
	TRANSPOSE_DOWN 3
	TEMPO $10
	SND_SEGNO
	VOICE $06, 0, 9, 14, 3
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 5
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 5
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	VOICE $06, 4, 8, 12, 7
	VIBRATO $01, 4, 3
	DUTY_STEP 0, 1
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 6
	NOTE A_, 2
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN_UNIT 1
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN_UNIT 6
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 6
	LEN_UNIT 1
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN_UNIT 6
	NOTE E_, 4
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE $0E, 3
	OCTAVE 5
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0C, 7
	DUTY 4
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 3
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	REST 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN_UNIT 1
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN_UNIT 6
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 6
	NOTE G_, 2
	NOTE E_, 2
	RELEASE $0E, 4
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	LEN_UNIT 1
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN_UNIT 6
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	DUTY 0
	OCTAVE 5
	NOTE E_, 2
	RELEASE $0E, 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	DUTY_STEP 4, 1
	RELEASE $0D, 7
	DUTY 8
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, $0A
	DUTY 0
	LEN_UNIT 1
	OCTAVE 5
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN_UNIT 6
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
	DUTY 8
	NOTE E_, 4
	NOTE E_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	LEN_UNIT 1
	NOTE A_, 4
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE A_, 4
	LEN_UNIT 6
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	LEN_UNIT 1
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE E_, 4
	LEN_UNIT 6
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 2
	LEN_UNIT 1
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN_UNIT 6
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE D_, 2
	DUTY 0
	LEN_UNIT 1
	OCTAVE 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	LEN_UNIT 6
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_LOOP

SndAC_Ch1:
	TRANSPOSE_DOWN 3
	SND_SEGNO
	DETUNE $00
	VOICE $06, 0, 6, 14, 3
	VIBRATO $02, 3, 4
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	ATTEN 2
	PAN_RIGHT 0
	OCTAVE 5
	NOTE E_, 2
	ATTEN 0
	PAN_BOTH 0
	LOOP_END 2
	DUTY 0
	REST 2
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $06, 8, 7, 8, 5
	DUTY_STEP 8, 1
	ATTEN 1
	OCTAVE 2
	NOTE G_, 8
	NOTE B_, 6
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 8
	NOTE C#, 6
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	RELEASE $0E, 3
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 8, 5
	DUTY 8
	DETUNE $FF
	ATTEN 1
	OCTAVE 2
	NOTE G_, 8
	NOTE B_, 6
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 6
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0E, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	DETUNE $00
	ATTEN 0
	DUTY 0
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	LOOP_START
	VOICE $06, 8, 6, 8, 7
	DETUNE $FF
	OCTAVE 4
	PAN_RIGHT 0
	ATTEN 4
	NOTE E_, 5
	NOTE E_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 1
	PAN_BOTH 0
	DUTY 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	RELEASE 0, 0
	JUMP_ON 2, SndAC_Ch1_625E
	OCTAVE 4
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 5
	NOTE E_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 1
	PAN_BOTH 0
	RELEASE $0E, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	DUTY 0
	NOTE A_, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
SndAC_Ch1_625E:
	LOOP_END 2
	RELEASE $0E, 4
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	REST 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 2
	SND_LOOP

SndAC_Ch3:
	TRANSPOSE_UP 9
	SND_SEGNO
	VOICE $06, 3, 2, 6, 0
	DETUNE $FF
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	LOOP_END 2
	DETUNE $00
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 3
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 3
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	LOOP2_START
	OCTAVE 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	JUMP_ON 2, SndAC_Ch3_630C
	OCTAVE 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 2
SndAC_Ch3_630C:
	LOOP2_END 2
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	LOOP_START
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	LOOP_END 2
	SND_LOOP

SndAC_Drm:
	SND_SEGNO
	LEN_UNIT 6
	LOOP_START
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM $0B, 2
	LOOP_END 2
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END $0D
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 2, 2
	LOOP_END $0E
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 2
	SND_LOOP
	db $FF

SndAD_Ch2:
	SND_CALL SndAD_Ch2_6B37
	REST 6
	SND_CALL SndAD_Ch2_6B47
	SND_END

SndAD_Ch1:
	SND_CALL SndAD_Ch1_6B8F
	REST 6
	SND_CALL SndAD_Ch1_6BA1
	SND_END

SndAD_Ch3:
	SND_CALL SndAD_Ch3_6BE0
	REST 6
	SND_CALL SndAD_Ch3_6BEE
	SND_END

SndAD_Drm:
	LEN_UNIT 8
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	REST 6
	LOOP_START
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM 4, 0
	SND_END

SndAE_Ch2:
	SND_SEGNO
	LOOP_START
	VOICE $05, 8, 7, 11, 7
	VIBRATO $01, 4, 3
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE F_, 3
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE G#, 2
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 8
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, $0C
	REST 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE D#, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 8
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, $0C
	REST 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 4
	NOTE G#, 2
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 6
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	NOTE G#, 2
	NOTE F_, 4
	JUMP_ON 2, SndAE_Ch2_63D2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 0
	DUTY 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE G#, 2
	NOTE A#, 3
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 4
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, $0C
SndAE_Ch2_63D2:
	LOOP_END 2
	NOTE D#, 2
	NOTE F_, 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 8
	NOTE G#, 2
	NOTE A#, 2
	NOTE F_, 6
	RELEASE $0E, 2
	DUTY 0
	DUTY_STEP 8, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	LOOP_START
	OCTAVE 5
	NOTE C_, 6
	OCTAVE 4
	NOTE G#, 4
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 6
	NOTE G_, 4
	NOTE A#, 2
	NOTE G#, 6
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	JUMP_ON 2, SndAE_Ch2_63FF
	NOTE G_, 6
	NOTE C_, 6
SndAE_Ch2_63FF:
	LOOP_END 2
	NOTE A#, 6
	OCTAVE 5
	NOTE D#, 6
	SND_LOOP

SndAE_Ch1:
	VOICE $05, 8, 6, 15, 6
	VIBRATO $02, 3, 1
	DETUNE $01
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE F_, 3
	REST 2
	PAN_RIGHT 0
	ATTEN 3
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE G#, 2
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 4
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	REST 6
	NOTE G#, 4
	NOTE G#, 2
	REST 6
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 2
	REST 6
	NOTE C_, 4
	NOTE C_, 2
	REST 6
	NOTE F_, 4
	NOTE F_, 2
	REST 6
	NOTE D_, 4
	NOTE D_, 2
	REST 6
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	REST 6
	OCTAVE 3
	NOTE C#, 4
	NOTE C#, 2
	REST 6
	NOTE D#, 4
	NOTE D#, 2
	REST 6
	NOTE D#, 4
	NOTE D#, 2
	JUMP_ON 2, SndAE_Ch1_645D
	REST 6
	NOTE D#, 4
	NOTE D#, 2
	REST 4
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F_, 2
	NOTE G_, 6
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 2
SndAE_Ch1_645D:
	LOOP_END 2
	LOOP_START
	REST 6
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	REST 6
	NOTE G#, 4
	NOTE G#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTE G#, 4
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 4
	NOTE G#, 2
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 4
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 4
	NOTE F_, 2
	OCTAVE 4
	JUMP_ON 2, SndAE_Ch1_6489
	NOTE E_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 2
SndAE_Ch1_6489:
	LOOP_END 2
	NOTE G_, 6
	NOTE A#, 6
	SND_LOOP

SndAE_Ch3:
	TRANSPOSE_UP $0C
	SND_SEGNO
	VOICE $05, 4, 2, 8, 4
	LOOP_START
	OCTAVE 1
	NOTE F_, 6
	REST $0C
	RELEASE 0, 0
	OCTAVE 2
	NOTE C_, 4
	LEN_UNIT 1
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $05, 4, 2, 8, 4
	OCTAVE 1
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 1
	NOTE C#, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 4
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	JUMP_ON 2, SndAE_Ch3_64F5
	NOTE G#, 4
	NOTE G#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
SndAE_Ch3_64F5:
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE F_, 2
	LOOP_END 2
	LOOP_START
	RELEASE $0A, 5
	WAVE 1
	AUTOPAN_R 0
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 4
	AUTOPAN_OFF 0
	JUMP_ON 2, SndAE_Ch3_652A
	NOTE G_, 2
	NOTE F#, 4
	NOTE G_, 2
SndAE_Ch3_652A:
	LOOP_END 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 4
	NOTE D#, 2
	SND_LOOP

SndAE_Drm:
	SND_SEGNO
	LEN_UNIT 5
	DRUM 4, 6
	REST 6
	REST 4
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 4
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END $0E
	DRUM 4, 6
	REST 6
	REST 4
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 4
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END $0E
	LOOP_START
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM $0A, 4
	DRUM $0A, 1
	DRUM $0A, 1
	LOOP_END 8
	SND_LOOP

SndAF_Ch2:
	TEMPO $30
	TRANSPOSE_UP 3
	VOICE $09, 8, 8, 8, 5
	VIBRATO $0A, 0, 2
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	LEN_UNIT 1
	NOTE E_, $0C
	NOTE E_, $0C
	NOTE E_, $0C
	LEN_UNIT 9
	NOTE E_, 8
	SND_SEGNO
	VOICE $09, 4, 8, 8, 5
	DUTY_STEP 4, 1
	VIBRATO $0A, 0, 3
	REST 2
	SND_CALL SndAF_Ch1_65A0
	NOTE D_, 2
	LEN_UNIT 9
	NOTE E_, $0A
	NOTE C_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 6
	NOTE A_, 1
	NOTE B_, 1
	RELEASE $0E, 7
	DUTY 0
	VIBRATO_OFF
	ATTEN 3
	OCTAVE 3
	NOTE F_, 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 1
	OCTAVE 4
	NOTE E_, 2
	SND_LOOP
SndAF_Ch1_65A0:
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 1
	REST 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	REST 1
	NOTE B_, 2
	NOTE A_, 1
	REST 1
	NOTE A_, 2
	NOTE F_, 6
	LEN_UNIT 1
	NOTE A_, 6
	NOTE B_, 6
	NOTE A_, 6
	LEN_UNIT 9
	NOTE F_, 4
	NOTE E_, 2
	SND_RET

SndAF_Ch1:
	TRANSPOSE_UP 3
	VOICE $09, 0, 7, 8, 6
	VIBRATO $09, 0, 3
	DETUNE $FF
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 4
	OCTAVE 2
	LEN_UNIT 1
	NOTE B_, $0C
	NOTE B_, $0C
	NOTE B_, $0C
	LEN_UNIT 9
	NOTE B_, 8
	SND_SEGNO
	DUTY 4
	VIBRATO $01, 3, 3
	REST 3
	ATTEN 4
	PAN_RIGHT 0
	SND_CALL SndAF_Ch1_65A0
	NOTE D_, 3
	PAN_BOTH 0
	VOICE $09, 8, 7, 5, 6
	ATTEN 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	NOTE E_, 4
	ATTEN 1
	NOTE F_, 8
	DUTY 0
	VIBRATO_OFF
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 1
	NOTE A_, 2
	SND_LOOP

SndAF_Ch3:
	TRANSPOSE_UP $0F
	VOICE $09, 3, 2, 4, 4
	VIBRATO $0A, 0, 9
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 1
	LEN_UNIT 1
	NOTE E_, $0C
	NOTE E_, $0C
	NOTE E_, $0C
	LEN_UNIT 9
	NOTE E_, 8
	VIBRATO $02, 3, 8
	SND_SEGNO
	LOOP_START
	OCTAVE 1
	NOTE E_, 4
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	LEN_UNIT 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT 9
	NOTE E_, 5
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE D_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	LEN_UNIT 3
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	LEN_UNIT 9
	NOTE D_, 5
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	LOOP_END 2
	SND_LOOP

SndAF_Drm:
	LEN_UNIT 9
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 4
	LEN_UNIT 1
	DRUM 4, $0C
	DRUM 4, $0C
	DRUM 4, $0C
	LEN_UNIT 9
	DRUM 3, 8
	SND_SEGNO
	LOOP_START
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM $0B, 8
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 4, 2
	DRUM 4, 2
	LOOP_END 2
	SND_LOOP

SndB0_Ch2:
	TEMPO $08
	SND_SEGNO
	LOOP_START
	VOICE $01, 4, 8, 13, 7
	ENVELOPE $06
	VIBRATO $0A, 0, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	LEN_UNIT $12
	OCTAVE 4
	NOTE E_, 1
	LEN_UNIT $0B
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	LEN_UNIT 1
	NOTE F_, 2
	NOTE A_, 2
	LEN_UNIT $12
	NOTE B_, 1
	LEN_UNIT $0B
	NOTE A_, 2
	JUMP_ON 2, SndB0_Ch2_6697
	NOTE E_, 3
	NOTE D_, 1
	NOTE E_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	SND_CALL SndB0_Ch2_66C0
SndB0_Ch2_6697:
	LOOP_END 2
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE B_, 2
	SND_CALL SndB0_Ch2_66C0
	LEN_UNIT $0B
	VIBRATO $01, 5, 2
	ATTEN 0
	DUTY 8
	ENVELOPE $08
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 8
	SND_CALL SndB0_Ch1_66CC
	REST 2
	SND_LOOP
SndB0_Ch2_66C0:
	PAN_BOTH 0
	REST 2
	ATTEN 2
	VIBRATO $06, 0, 2
	ENVELOPE_OFF
	OCTAVE 6
	NOTE E_, 4
	SND_RET
SndB0_Ch1_66CC:
	DUTY_STEP 8, 1
	DUTY 0
	LEN_UNIT 1
	ENVELOPE $02
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	LEN_UNIT $12
	NOTE E_, 1
	LEN_UNIT $0B
	NOTE D_, 1
	REST 3
	NOTE E_, 2
	REST 2
	OCTAVE 3
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 6
	DUTY_STEP 0, 0
	SND_RET

SndB0_Ch1:
	SND_SEGNO
	LOOP2_START
	VOICE $0B, 8, 7, 15, 4
	DETUNE $01
	ENVELOPE_OFF
	VIBRATO $06, 0, 2
	ATTEN 3
	OCTAVE 5
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 1
	LOOP_START
	RELEASE $0F, 4
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 4
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 4
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 1
	LOOP_END 2
	JUMP_ON 2, SndB0_Ch1_6750
	PAN_BOTH 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 3
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	REST 2
	AUTOPAN_OFF 0
	ATTEN 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 5
	NOTE E_, 4
	VIBRATO_OFF
	RELEASE 7, 6
	ATTEN 3
	OCTAVE 6
	NOTE OCT_UP, 4
	ATTEN 0
SndB0_Ch1_6750:
	LOOP2_END 2
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 4
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 5
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE B_, 1
	REST 2
	PAN_BOTH 0
	VIBRATO_OFF
	ATTEN 3
	RELEASE 7, 6
	OCTAVE 6
	NOTE OCT_UP, 4
	ATTEN 0
	PAN_BOTH 0
	DUTY 8
	ENVELOPE $08
	ATTEN 2
	VIBRATO $02, 4, 3
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 8
	PAN_RIGHT 0
	ATTEN 4
	SND_CALL SndB0_Ch1_66CC
	REST 2
	PAN_BOTH 0
	ATTEN 0
	SND_LOOP

SndB0_Ch3:
	SND_SEGNO
	VOICE $0B, 4, 2, 0, 0
	VIBRATO $08, 0, 10
	LOOP_START
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 2
	NOTE F#, 4
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	REST 6
	LOOP_END 2
	RELEASE 2, 1
	OCTAVE 2
	NOTE E_, 6
	NOTE E_, 2
	NOTE F_, 6
	NOTE F_, 2
	NOTE F#, 6
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 8
	NOTE F_, 2
	NOTE OCT_UP, 1
	REST 3
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	REST 8
	SND_LOOP

SndB0_Drm:
	SND_SEGNO
	LOOP_START
	LEN_UNIT $0B
	DRUM $0B, 4
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 1, 4
	DRUM $0B, 4
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 2, 4
	LOOP_END 2
	DRUM $0B, 4
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 4, 6
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 4, 4
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 5, 4
	DRUM 4, 4
	DRUM 5, 4
	DRUM 5, 4
	REST 6
	SND_LOOP

SndB1_Ch2:
	VOICE $0E, 8, 2, 0, 0
	VIBRATO $02, 0, 0
	DETUNE $FF
	OCTAVE 4
	NOTE C_, 1
	SND_SEGNO
	SND_CALL SndB1_Ch1_682B
	SND_LOOP

SndB1_Ch1:
	VOICE $0E, 8, 2, 0, 0
	PAN_RIGHT 0
	REST 2
	SND_SEGNO
	SND_CALL SndB1_Ch1_682B
	SND_LOOP

SndB1_Ch3:
	VOICE $0E, 2, 2, 0, 0
	TRANSPOSE_UP 6
	VIBRATO $01, 2, 1
	SND_SEGNO
	SND_CALL SndB1_Ch1_682B
	SND_LOOP
SndB1_Ch1_682B:
	TRANSPOSE_DOWN 6
	OCTAVE 4
	NOTE F#, 5
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 5
	NOTE C#, 3
	NOTE C#, 4
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE C#, 6
	OCTAVE 4
	NOTE A#, 5
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE F#, 3
	NOTE F#, 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 6
	NOTE C#, 5
	NOTE D#, 1
	NOTE D#, 3
	OCTAVE 4
	NOTE A#, 3
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 3
	NOTE C#, 3
	NOTE D#, 9
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, $0C
	SND_RET

SndB1_Drm:
	SND_END

SndB2_Ch2:
	VOICE $09, 0, 8, 8, 7
	VIBRATO $02, 2, 10
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 7
	REST 1
	VOICE $09, 0, 13, 8, 5
	VIBRATO $10, 0, 2
	DUTY_STEP 4, 4
	OCTAVE 5
	NOTE F_, 8
	TRANSPOSE_UP 3
	LEN_UNIT 4
	REST 0
	REST 8
	LOOP_START
	VOICE $04, 0, 8, 8, 7
	VIBRATO $02, 3, 2
	DUTY_STEP 4, 1
	REST 3
	LEN_UNIT 1
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 1
	NOTE C#, 1
	LEN_UNIT 4
	OCTAVE 2
	NOTE A_, 2
	REST 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 4
	NOTE E_, 6
	NOTE E_, 6
	NOTE C#, 2
	NOTE F#, 4
	NOTE E_, 6
	DUTY 8
	DUTY_STEP 0, 0
	NOTE D#, 2
	NOTE D_, 4
	NOTE C#, 2
	REST 3
	DUTY 0
	DUTY_STEP 4, 1
	LEN_UNIT 1
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	LEN_UNIT 4
	NOTE F#, 2
	REST 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 4
	NOTE A_, 4
	JUMP_ON 2, SndB2_Ch2_68C3
	NOTE A_, 8
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 4
	DUTY 8
	DUTY_STEP 0, 0
	NOTE F_, 2
	NOTE E_, 4
	NOTE D#, 2
	DUTY 0
	DUTY_STEP 4, 1
SndB2_Ch2_68C3:
	LOOP_END 2
	REST 8
	VOICE $0C, 0, 8, 15, 7
	ENVELOPE $04
	DUTY_STEP 8, 2
	VIBRATO $0E, 0, 7
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 3
	NOTE G_, 1
	NOTE G_, 3
	NOTE D#, 1
	NOTE D#, 9
	LEN_UNIT 4
	VIBRATO_OFF
	ENVELOPE_OFF
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 2
	SND_LOOP

SndB2_Ch1:
	VOICE $09, 0, 6, 8, 7
	VIBRATO $02, 3, 8
	DUTY_STEP 4, 1
	DETUNE $FE
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 7
	REST 1
	REST 8
	LEN_UNIT 4
	REST 0
	REST 8
	DETUNE $00
	TRANSPOSE_UP 3
	LOOP_START
	VOICE $04, 4, 6, 12, 5
	DUTY_STEP 8, 1
	VIBRATO $01, 3, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE C#, 2
	REST 4
	NOTE E_, $0C
	NOTE C#, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C#, 6
	DUTY 8
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 2
	DUTY 4
	NOTE F#, 4
	OCTAVE 3
	NOTE C_, 2
	REST 4
	NOTE C_, 2
	NOTE D_, 4
	NOTE C_, 8
	JUMP_ON 2, SndB2_Ch1_6944
	NOTE C_, 4
	OCTAVE 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 4
	DUTY 8
	NOTE C#, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 2
	DUTY 4
SndB2_Ch1_6944:
	LOOP_END 2
	REST 8
	VOICE $0C, 0, 7, 15, 7
	ENVELOPE $04
	DUTY_STEP 8, 2
	VIBRATO $02, 2, 7
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 3
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 3
	NOTE A_, 1
	VIBRATO $02, 3, 7
	NOTE A_, 9
	SND_SEGNO
	LEN_UNIT 4
	VIBRATO_OFF
	PAN_LEFT 0
	ENVELOPE_OFF
	OCTAVE 3
	REST 2
	NOTE C#, 2
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	SND_LOOP

SndB2_Ch3:
	VOICE $09, 3, 2, 8, 3
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	RELEASE 3, 5
	OCTAVE 3
	NOTE G_, 8
	REST 8
	TRANSPOSE_UP 3
	VOICE $04, 3, 2, 8, 4
	REST 0
	REST 8
	LOOP_START
	OCTAVE 2
	NOTE A_, 6
	NOTE E_, 6
	NOTE F#, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE F#, 6
	NOTE E_, 6
	NOTE D_, 6
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	NOTE C_, 6
	NOTE C#, 6
	JUMP_ON 2, SndB2_Ch3_69A0
	NOTE D_, 6
	NOTE C_, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A_, 6
SndB2_Ch3_69A0:
	LOOP_END 2
	REST 8
	LEN_UNIT $0C
	REST 0
	REST 2
	SND_SEGNO
	LEN_UNIT 4
	RELEASE 6, 0
	OCTAVE 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	SND_LOOP

SndB2_Drm:
	LEN_UNIT 9
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 3, 8
	REST 8
	LEN_UNIT 4
	REST $0C
	LOOP_START
	DRUM 4, 2
	LOOP_END 6
	LOOP_START
	DRUM 3, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END $0E
	REST 8
	LEN_UNIT $0C
	REST 0
	REST 2
	SND_SEGNO
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	SND_LOOP

SndB3_Ch2:
	TRANSPOSE_UP $0F
	VOICE $07, 8, 8, 15, 5
	ENVELOPE $06
	VIBRATO $01, 6, 2
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 4
	NOTE G_, 2
	LOOP_START
	NOTE A_, 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 4
	NOTE D_, 2
	NOTE E_, 6
	NOTE C_, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	JUMP_ON 2, SndB3_Ch2_6A13
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE B_, 2
	LEN_UNIT $0E
	NOTE A_, 9
	LEN_UNIT 7
	NOTE E_, 4
	NOTE G_, 2
SndB3_Ch2_6A13:
	LOOP_END 2
	NOTE C_, 4
	NOTE D_, 2
	LEN_UNIT $0E
	NOTE E_, 9
	LEN_UNIT 7
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	LEN_UNIT $0E
	NOTE D_, 9
	LEN_UNIT 7
	SND_LOOP

SndB3_Ch1:
	TRANSPOSE_DOWN 9
	VOICE $07, 4, 6, 3, 2
	DUTY_STEP 8, 4
	VIBRATO $02, 3, 2
	ENVELOPE $06
	REST 6
	SND_SEGNO
	LOOP_START
	ATTEN 0
	RELEASE $0F, 4
	DUTY 4
	ENVELOPE_OFF
	OCTAVE 3
	NOTE A_, $0A
	NOTE A_, 2
	NOTE B_, 3
	REST 3
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	JUMP_ON 2, SndB3_Ch1_6A62
	NOTE E_, 4
	REST 8
	NOTE A_, $0A
	NOTE A_, 2
	NOTE B_, 3
	REST 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	ATTEN 2
	ENVELOPE $07
	DUTY 8
	OCTAVE 5
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, $0C
SndB3_Ch1_6A62:
	LOOP_END 2
	NOTE E_, 4
	REST 8
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 6
	ENVELOPE $07
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 8
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, $0C
	SND_LOOP

SndB3_Ch3:
	TRANSPOSE_UP 3
	VOICE $07, 4, 2, 1, 0
	REST 6
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE F_, 4
	NOTE OCT_UP, 2
	REST 4
	NOTE F_, 2
	NOTE G_, 3
	REST 3
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 4
	NOTE OCT_UP, 2
	JUMP_ON 2, SndB3_Ch3_6AA9
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 2
	REST $0A
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 2
	REST 4
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 6
	REST 6
SndB3_Ch3_6AA9:
	LOOP_END 2
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 2
	REST $0A
	NOTE B_, 4
	NOTE B_, 2
	REST 4
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 8
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 6
	REST 6
	SND_LOOP

SndB3_Drm:
	LEN_UNIT 7
	REST 6
	SND_SEGNO
	LOOP_START
	DRUM $0B, 4
	DRUM 1, 6
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END 7
	DRUM $0B, 4
	DRUM 1, 6
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	SND_LOOP

SndB5_Ch2:
	SND_JUMP SndB4_Ch2_6AE7

SndB5_Ch1:
	SND_JUMP SndB4_Ch1_6B61

SndB5_Ch3:
	SND_JUMP SndB4_Ch3_6BB8

SndB5_Drm:
	SND_JUMP SndB4_Drm_6C06

SndB4_Ch2:
	SND_CALL SndAD_Ch2_6B37
	REST 0
	SND_CALL SndAD_Ch2_6B47
SndB4_Ch2_6AE7:
	SND_SEGNO
	TRANSPOSE_UP 0
	SND_CALL SndB4_Ch2_6AFD
	TRANSPOSE_UP 3
	SND_CALL SndB4_Ch2_6AFD
	TRANSPOSE_UP 6
	SND_CALL SndB4_Ch2_6AFD
	TRANSPOSE_UP 3
	SND_CALL SndB4_Ch2_6AFD
	SND_LOOP
SndB4_Ch2_6AFD:
	VOICE $0C, 0, 8, 15, 6
	VIBRATO $09, 0, 10
	DUTY_STEP 4, 1
	LOOP2_START
	LOOP_START
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	PAN_LEFT 0
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	ATTEN 0
	PAN_BOTH 0
	NOTE C#, 1
	ATTEN 5
	PAN_RIGHT 0
	NOTE C#, 1
	LOOP_END 2
	LOOP_START
	ATTEN 0
	PAN_BOTH 0
	NOTE D_, 1
	ATTEN 5
	PAN_LEFT 0
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	ATTEN 0
	PAN_BOTH 0
	NOTE D#, 1
	ATTEN 5
	PAN_RIGHT 0
	NOTE D#, 1
	LOOP_END 2
	LOOP2_END 4
	SND_RET
SndAD_Ch2_6B37:
	VOICE $08, 4, 11, 8, 7
	DUTY_STEP 8, 1
	VIBRATO $01, 3, 5
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_RET
SndAD_Ch2_6B47:
	NOTE A#, 1
	NOTE A#, 1
	REST 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE A#, 1
	NOTE A#, 1
	REST 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	VIBRATO $13, 5, 2
	NOTE A#, 0
	SND_RET

SndB4_Ch1:
	SND_CALL SndAD_Ch1_6B8F
	REST 0
	SND_CALL SndAD_Ch1_6BA1
SndB4_Ch1_6B61:
	SND_SEGNO
	TRANSPOSE_UP 0
	LOOP2_START
	SND_CALL SndB4_Ch1_6B76
	TRANSPOSE_UP 3
	SND_CALL SndB4_Ch1_6B76
	JUMP_ON 2, SndB4_Ch1_6B73
	TRANSPOSE_UP 6
SndB4_Ch1_6B73:
	LOOP2_END 2
	SND_LOOP
SndB4_Ch1_6B76:
	VOICE $0C, 0, 5, 14, 6
	VIBRATO $01, 0, 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 5
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE A_, 2
	LOOP_END 4
	SND_RET
SndAD_Ch1_6B8F:
	VOICE $08, 4, 11, 8, 7
	DUTY_STEP 8, 1
	VIBRATO $02, 3, 5
	DETUNE $FF
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_RET
SndAD_Ch1_6BA1:
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE A#, 1
	NOTE A#, 1
	REST 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE A#, 1
	NOTE A#, 1
	REST 1
	OCTAVE 4
	NOTE E_, 0
	SND_RET

SndB4_Ch3:
	SND_CALL SndAD_Ch3_6BE0
	REST 0
	SND_CALL SndAD_Ch3_6BEE
SndB4_Ch3_6BB8:
	SND_SEGNO
	TRANSPOSE_UP 0
	LOOP2_START
	SND_CALL SndB4_Ch3_6BCD
	TRANSPOSE_UP 3
	SND_CALL SndB4_Ch3_6BCD
	JUMP_ON 2, SndB4_Ch3_6BCA
	TRANSPOSE_UP 6
SndB4_Ch3_6BCA:
	LOOP2_END 2
	SND_LOOP
SndB4_Ch3_6BCD:
	VOICE $0C, 4, 2, 6, 0
	DETUNE $FE
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END 4
	SND_RET
SndAD_Ch3_6BE0:
	VOICE $08, 6, 2, 5, 0
	VIBRATO $07, 3, 2
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_RET
SndAD_Ch3_6BEE:
	LOOP_START
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	RELEASE 3, 3
	NOTE E_, 0
	SND_RET

SndB4_Drm:
	LEN_UNIT 8
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	REST 0
	LOOP_START
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM 4, 0
SndB4_Drm_6C06:
	LEN_UNIT $0C
	SND_SEGNO
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	SND_LOOP

SndB6_Ch2:
	TEMPO $24
	TRANSPOSE_DOWN 7
	VOICE $0A, 8, 9, 5, 0
	DUTY_STEP 4, 1
	VIBRATO $09, 0, 10
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_CALL SndB6_Ch2_6C9E
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE C_, 1
	SND_CALL SndB6_Ch2_6C9E
	LOOP_END 2
	TRANSPOSE_DOWN 9
	LOOP2_END 2
	TRANSPOSE_DOWN 7
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_LOOP
SndB6_Ch2_6C9E:
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	SND_RET

SndB6_Ch1:
	SND_SEGNO
	TRANSPOSE_DOWN 7
	LOOP2_START
	LOOP_START
	VOICE $0A, 0, 3, 4, 3
	VIBRATO $02, 2, 2
	DETUNE $FF
	OCTAVE 4
	NOTE C_, 1
	LEN_UNIT 1
	NOTE C_, 4
	NOTE E_, 3
	NOTE F#, 3
	LEN_UNIT $0A
	NOTE B_, 2
	VOICE $0A, 8, 5, 4, 7
	PAN_RIGHT 0
	OCTAVE 3
	NOTE F#, 4
	PAN_LEFT 0
	NOTE E_, 5
	VOICE $0A, 0, 7, 4, 3
	ATTEN 4
	OCTAVE 4
	NOTE A_, 1
	LEN_UNIT 1
	NOTE A_, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE F#, 8
	NOTE E_, 8
	LEN_UNIT $0A
	NOTE F#, 2
	DUTY 8
	PAN_RIGHT 0
	ATTEN 2
	OCTAVE 3
	NOTE C_, 4
	PAN_LEFT 0
	OCTAVE 2
	NOTE B_, 4
	PAN_RIGHT 0
	NOTE A_, 4
	VOICE $0A, 0, 4, 4, 3
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 1
	VOICE $0A, 0, 7, 4, 3
	DUTY_STEP 4, 1
	ATTEN 2
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	PAN_LEFT 0
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 1
	DUTY 8
	ATTEN 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	LOOP_END 2
	TRANSPOSE_DOWN 9
	LOOP2_END 2
	TRANSPOSE_DOWN 7
	ATTEN 4
	PAN_RIGHT 0
	OCTAVE 2
	NOTE A_, 2
	SND_CALL SndB6_Ch1_6D4A
	DUTY_STEP 0, 0
	ATTEN 0
	SND_LOOP
SndB6_Ch1_6D4A:
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	SND_RET

SndB6_Ch3:
	VOICE $0A, 4, 2, 0, 0
	VIBRATO $0C, 0, 2
	TRANSPOSE_UP 5
	SND_SEGNO
	LOOP2_START
	LOOP_START
	LEN_UNIT 1
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 3
	NOTE F#, 3
	LEN_UNIT $0A
	NOTE B_, $0B
	LEN_UNIT 1
	NOTE A_, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE F#, 8
	NOTE E_, 8
	LEN_UNIT $0A
	NOTE F#, $0E
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 9
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	LOOP2_END 2
	TRANSPOSE_UP 5
	OCTAVE 2
	NOTE A_, 1
	SND_CALL SndB6_Ch1_6D4A
	NOTE E_, 1
	SND_LOOP

SndB6_Drm:
	LEN_UNIT 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, $0A
	DRUM $0B, $0A
	DRUM 1, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 5, $0A
	DRUM $0B, $0A
	DRUM 1, $0A
	DRUM $0B, $0A
	DRUM 2, $0A
	DRUM 1, $0A
	DRUM $0B, $0A
	DRUM $0B, $0A
	DRUM 5, $0A
	DRUM 1, $0A
	DRUM 2, $0A
	DRUM 1, $0A
	DRUM $0B, $0A
	DRUM $0B, $0A
	DRUM 1, $0A
	DRUM 1, $0A
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM 1, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 1, $0A
	DRUM 3, $0A
	DRUM $0B, $0A
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM $0B, $0A
	DRUM 1, $0A
	DRUM 3, $0A
	LOOP_END 8
	DRUM $0B, $0A
	DRUM $0B, $0A
	DRUM 1, $0A
	DRUM 2, $0A
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM 1, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 2, 5
	DRUM 5, 5
	DRUM 5, 5
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM 5, 5
	DRUM 5, 5
	DRUM 5, $0A
	DRUM 5, $0A
	DRUM 5, $0A
	SND_LOOP

SndB7_Ch2:
	TEMPO $28
	TRANSPOSE_DOWN 1
	VOICE $05, 4, 8, 10, 1
	SND_CALL SndA3_Ch1_4642
	SND_CALL SndB7_Ch1_6E60
	SND_SEGNO
	TRANSPOSE_DOWN $0D
	LOOP_START
	VOICE $05, 4, 8, 10, 6
	VIBRATO $11, 2, 3
	ENVELOPE_OFF
	DUTY_STEP 8, 1
	OCTAVE 6
	NOTE E_, 6
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE B_, 6
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 6
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 6
	NOTE A_, 1
	NOTE B_, 1
	DUTY 0
	VIBRATO $12, 3, 15
	RELEASE 8, 7
	OCTAVE 5
	NOTE F_, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE C_, 6
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 6
	DUTY 8
	VIBRATO_OFF
	RELEASE $0E, 4
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE A#, 1
	OCTAVE 4
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A#, 1
	LOOP_END 2
	VOICE $05, 8, 9, 7, 1
	DUTY_STEP 4, 1
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	LOOP_END 2
	LOOP2_END 2
	SND_LOOP
SndB7_Ch1_6E60:
	ENVELOPE $0F
	ATTEN 7
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 6
	LOOP_END 2
	ENVELOPE $02
	ATTEN 3
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	LOOP_END 2
	SND_RET

SndB7_Ch1:
	TRANSPOSE_DOWN 1
	VOICE $05, 4, 8, 8, 6
	ENVELOPE $04
	DUTY_STEP 8, 1
	VIBRATO $02, 3, 2
	DETUNE $FF
	SND_CALL SndA9_Ch1_57A0
	SND_CALL SndB7_Ch1_6E60
	SND_SEGNO
	ATTEN 0
	LOOP2_START
	SND_CALL SndA9_Ch1_57A0
	PAN_LEFT 0
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 4
	PAN_RIGHT 0
	LOOP_START
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 2
	NOTE D#, 2
	LOOP_END 3
	DUTY 8
	ENVELOPE_OFF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 0
	LOOP2_END 2
	LOOP_START
	VOICE $05, 8, 7, 8, 7
	ENVELOPE_OFF
	ATTEN 4
	DUTY_STEP 4, 1
	PAN_RIGHT 0
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	PAN_LEFT 0
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	PAN_LEFT 0
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	LOOP_END 2
	ATTEN 0
	SND_LOOP

SndB7_Ch3:
	TRANSPOSE_DOWN 1
	VOICE $05, 8, 2, 3, 7
	REST 0
	REST 0
	SND_SEGNO
	VOICE $05, 5, 2, 7, 0
	LOOP2_START
	VIBRATO_OFF
	SND_CALL SndB7_Ch3_6F50
	TRANSPOSE_DOWN 0
	SND_CALL SndB7_Ch3_6F50
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	LOOP_START
	WAVE 7
	VIBRATO_OFF
	RELEASE $0A, 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	LOOP_END 2
	SND_LOOP
SndB7_Ch3_6F50:
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	SND_RET

SndB7_Drm:
	LEN_UNIT 5
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 6
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 4, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 4, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 4, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 4, 1
	DRUM $0B, 1
	LOOP_END 7
	DRUM $0B, 2
	DRUM 4, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM $0B, 1
	LOOP_START
	DRUM 4, 1
	LOOP_END 7
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0B, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndB8_Ch2:
	TEMPO $00
	VOICE $04, 0, 10, 11, 4
	DUTY_STEP 4, 1
	SND_CALL SndB8_Ch1_708E
	DUTY 0
	VIBRATO $09, 0, 15
	REST 2
	OCTAVE 4
	LOOP_START
	NOTE B_, 1
	ATTEN 4
	PAN_RIGHT 0
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	LOOP_END 4
	NOTE B_, 1
	VIBRATO_OFF
	LEN_UNIT 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_SEGNO
	LOOP2_START
	VOICE $06, 4, 8, 10, 5
	DUTY_STEP 0, 0
	SND_CALL SndB8_Ch1_70A3
	NOTE F#, 6
	VIBRATO_OFF
	DUTY_STEP 4, 1
	RELEASE 0, 0
	DUTY 8
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 5
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE A_, 1
	DUTY 0
	VIBRATO $09, 0, 15
	LOOP_START
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 5
	PAN_LEFT 0
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 0
	LOOP_END 4
	LOOP_START
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	LOOP_END 2
	LOOP2_END 2
	LOOP2_START
	VOICE $04, 8, 9, 0, 0
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 6
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 5
	ATTEN 4
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 3
	ATTEN 1
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 3
	LEN_UNIT 6
	ATTEN 0
	DUTY 0
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	LEN_UNIT 4
	DUTY 8
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 6
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END 5
	ATTEN 4
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END 3
	ATTEN 1
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END 3
	LEN_UNIT 6
	DUTY 0
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	LOOP2_END 2
	SND_LOOP
SndB8_Ch1_708E:
	OCTAVE 1
	NOTE B_, 2
	ATTEN 5
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	ATTEN 3
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	ATTEN 0
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	ATTEN 0
	LEN_UNIT 6
	SND_RET
SndB8_Ch1_70A3:
	DUTY_STEP 8, 1
	VIBRATO $0A, 0, 5
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	NOTE E_, 2
	NOTE G#, 2
	LEN_UNIT 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	LEN_UNIT 6
	NOTE E_, 2
	NOTE C#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	LEN_UNIT 4
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	LEN_UNIT 6
	SND_RET

SndB8_Ch1:
	VOICE $06, 8, 7, 8, 4
	REST 1
	LEN_UNIT 4
	AUTOPAN_R 0
	DETUNE $FF
	ATTEN 3
	SND_CALL SndB8_Ch1_708E
	REST 1
	VIBRATO $09, 0, 15
	DUTY 0
	ATTEN 0
	AUTOPAN_OFF 0
	LOOP_START
	OCTAVE 4
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 0
	LOOP_END 4
	NOTE F#, 1
	LEN_UNIT 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_SEGNO
	LOOP2_START
	VOICE $06, 0, 4, 10, 6
	DETUNE $00
	TRANSPOSE_DOWN $0C
	SND_CALL SndB8_Ch1_70A3
	TRANSPOSE_DOWN 0
	DUTY 8
	VOLUME $07
	RELEASE $0F, 3
	OCTAVE 2
	LOOP_START
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	DUTY 0
	VIBRATO $09, 0, 15
	LOOP_START
	NOTE F#, 1
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 4
	PAN_RIGHT 0
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	LOOP_END 2
	LOOP_START
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	LOOP_END 2
	LOOP2_END 2
	VIBRATO_OFF
	LOOP2_START
	OCTAVE 1
	LOOP_START
	NOTE B_, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	OCTAVE 2
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE B_, 1
	NOTE OCT_UP, 1
	LOOP_END 4
	OCTAVE 3
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE C_, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE C_, 1
	NOTE OCT_UP, 1
	LOOP2_END 2
	SND_LOOP

SndB8_Ch3:
	VOICE $04, 2, 2, 0, 0
	DETUNE $FE
	VIBRATO $09, 0, 10
	SND_CALL SndB8_Ch1_708E
	RELEASE $0D, 5
	WAVE 4
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 2
	DETUNE $00
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	LOOP_END 2
	LOOP2_END 2
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 4
	LOOP2_END 2
	SND_LOOP

SndB8_Drm:
	LEN_UNIT 6
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM $0B, 2
	LOOP_START
	DRUM 4, 2
	DRUM $0B, 1
	LOOP_END 4
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 4, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 4, 2
	LOOP_END $0F
	LOOP_START
	DRUM 4, 1
	LOOP_END $10
	SND_LOOP

SndB9_Ch2:
	VOICE $04, 8, 5, 5, 0
	PAN_LEFT 0
	REST 4
	SND_CALL SndB9_Ch1_7222
	NOTE B_, $0E
	SND_JUMP SndB3_Ch2
SndB9_Ch1_7222:
	TRANSPOSE_UP 5
	OCTAVE 6
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 5
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 3
	NOTE F_, 3
	NOTE A_, 4
	NOTE A_, 5
	LEN_UNIT 8
	RELEASE 0, 0
	SND_RET

SndB9_Ch1:
	VOICE $04, 8, 5, 5, 0
	PAN_RIGHT 0
	REST 2
	SND_CALL SndB9_Ch1_7222
	NOTE B_, $0F
	SND_JUMP SndB3_Ch1

SndB9_Ch3:
	VOICE $04, 2, 2, 5, 0
	VIBRATO $01, 3, 1
	SND_CALL SndB9_Ch1_7222
	NOTE B_, 0
	SND_JUMP SndB3_Ch3

SndB9_Drm:
	LEN_UNIT 4
	REST 0
	REST $0F
	REST 8
	LEN_UNIT 8
	REST 0
	SND_JUMP SndB3_Drm

SndBA_Ch2:
	TRANSPOSE_DOWN 2
	SND_CALL SndBA_Ch2_73BC
	SND_CALL SndBA_Ch2_7374
	NOTE D_, $0C
	LEN_UNIT 8
	REST 8
	SND_CALL SndBA_Ch2_72DD
	SND_CALL SndBA_Ch2_7300
	SND_CALL SndBA_Ch2_72DD
	SND_CALL SndBA_Ch2_7313
	SND_CALL SndBA_Ch1_7330
	SND_CALL SndBA_Ch2_7382
SndBA_Ch2_7280:
	SND_CALL SndBA_Ch2_7353
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	DUTY_STEP 4, 1
	ENVELOPE_OFF
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	SND_CALL SndBA_Ch2_7353
	NOTE G_, 6
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	TRANSPOSE_DOWN 1
	SND_CALL SndBA_Ch2_72DD
	SND_CALL SndBA_Ch2_7300
	SND_CALL SndBA_Ch2_72DD
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	VOICE $08, 0, 8, 14, 4
	VIBRATO $01, 15, 1
	ENVELOPE $12
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 8
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 4
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE C_, 3
	NOTE D_, 5
	ENVELOPE $15
	LEN_UNIT $0E
	NOTE E_, 0
	SND_END
SndBA_Ch2_72DD:
	VOICE $08, 4, 8, 14, 7
	VIBRATO $01, 4, 4
	DUTY_STEP 4, 1
	ENVELOPE_OFF
	OCTAVE 3
	NOTE G_, 4
	LOOP_START
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	LOOP_END 2
	NOTE D_, 6
	NOTE E_, 2
	NOTE D_, 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 6
	LEN_UNIT 1
	NOTE E_, 6
	NOTE G_, 5
	NOTE E_, 5
	LEN_UNIT 8
	SND_RET
SndBA_Ch2_7300:
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 3
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 4
	DUTY 0
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
SndBA_Ch2_7313:
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 6
	LEN_UNIT 1
	OCTAVE 4
	NOTE C_, 6
	NOTE D_, 5
	NOTE C_, 5
	LEN_UNIT 8
	OCTAVE 3
	NOTE A_, 2
	DUTY 0
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
SndBA_Ch1_7330:
	DUTY 8
	RELEASE $0A, 7
	REST 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	LEN_UNIT 1
	NOTE G_, 6
	NOTE A_, 5
	NOTE G_, 5
	LEN_UNIT 8
	NOTE E_, $0C
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 7
	SND_RET
SndBA_Ch2_7353:
	DUTY 8
	DUTY_STEP 0, 0
	ENVELOPE $12
	OCTAVE 4
	NOTE A_, 6
	LEN_UNIT 1
	OCTAVE 5
	NOTE C_, 6
	NOTE D_, 5
	NOTE C_, 5
	LEN_UNIT 8
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	SND_RET
SndBA_Ch2_7374:
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	SND_RET
SndBA_Ch2_7382:
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 8
	DUTY 0
	OCTAVE 5
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 4
	NOTE E_, 4
	OCTAVE 5
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 8
	SND_RET
SndBA_Ch2_73BC:
	TEMPO $10
	VOICE $0B, 8, 8, 8, 7
	VIBRATO $01, 4, 2
	SND_RET

SndBA_Ch1:
	TRANSPOSE_DOWN 2
	SND_CALL SndBA_Ch1_753F
	SND_CALL SndBA_Ch1_7451
	SND_CALL SndBA_Ch1_7487
	SND_CALL SndBA_Ch1_7451
	SND_CALL SndBA_Ch1_74A9
	OCTAVE 2
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	SND_CALL SndBA_Ch1_7330
	SND_CALL SndBA_Ch1_74FB
SndBA_Ch1_73E2:
	SND_CALL SndBA_Ch1_74D6
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 3
	REST 1
	PAN_RIGHT 0
	DETUNE $FF
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 1
	DETUNE $00
	SND_CALL SndBA_Ch1_74D6
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 8
	NOTE F_, 8
	TRANSPOSE_DOWN 1
	SND_CALL SndBA_Ch1_7451
	SND_CALL SndBA_Ch1_7487
	SND_CALL SndBA_Ch1_7451
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE D_, 1
	DUTY 4
	ENVELOPE $12
	ATTEN 0
	PAN_BOTH 0
	VIBRATO $02, 12, 1
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE C_, 6
	NOTE C_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE G#, 4
	NOTE F_, 2
	NOTE G#, 4
	NOTE F_, 3
	NOTE F_, 5
	ATTEN 1
	ENVELOPE $15
	LEN_UNIT $0E
	NOTE B_, 0
	SND_END
SndBA_Ch1_7451:
	VOICE $08, 0, 7, 14, 5
	DETUNE $FF
	VIBRATO $02, 3, 3
	ATTEN 2
	DUTY_STEP 4, 1
	ENVELOPE_OFF
	PAN_LEFT 0
	OCTAVE 2
	NOTE G_, 2
	LOOP_START
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END 4
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 2
	NOTE B_, 2
	LOOP_START
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 4
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	PAN_LEFT 0
	NOTE C_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	SND_RET
SndBA_Ch1_7487:
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	PAN_RIGHT 0
	NOTE C_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_RET
SndBA_Ch1_74A9:
	DUTY 4
	ENVELOPE_OFF
	PAN_BOTH 0
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE D_, 1
	DUTY 0
	ATTEN 2
	PAN_LEFT 0
	OCTAVE 2
	NOTE A_, 2
	LOOP_START
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	LOOP_END 2
	ATTEN 0
	PAN_BOTH 0
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	LOOP_END 2
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	SND_RET
SndBA_Ch1_74D6:
	DUTY 8
	ATTEN 1
	RELEASE $0B, 7
	PAN_BOTH 0
	OCTAVE 4
	NOTE E_, 6
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	DUTY 0
	ENVELOPE $12
	OCTAVE 5
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 2
	NOTE G_, 2
	DUTY 8
	ENVELOPE_OFF
	SND_RET
SndBA_Ch1_74FB:
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 8
	DUTY 0
	RELEASE $0E, 5
	DETUNE $00
	ATTEN 1
	REST 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	NOTE F_, 1
	NOTE A_, 1
	DUTY 4
	RELEASE $0F, 7
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	RELEASE $0E, 5
	DUTY 0
	REST 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 8
	DETUNE $FF
	SND_RET
SndBA_Ch1_753F:
	VOICE $0B, 8, 8, 8, 7
	VIBRATO $02, 5, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE G_, $0C
	LEN_UNIT 8
	REST 8
	SND_RET

SndBA_Ch3:
	TRANSPOSE_DOWN 2
	VOICE $0B, 2, 2, 5, 7
	VIBRATO $01, 10, 6
	DETUNE $FF
	SND_CALL SndBA_Ch2_7374
	OCTAVE 2
	NOTE G_, $0C
	LEN_UNIT 8
	REST 8
	SND_CALL SndBA_Ch3_75E2
	SND_CALL SndBA_Ch3_7617
	SND_CALL SndBA_Ch3_75E2
	SND_CALL SndBA_Ch3_7627
	SND_CALL SndBA_Ch3_7660
SndBA_Ch3_757B:
	SND_CALL SndBA_Ch3_7604
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	SND_CALL SndBA_Ch3_7604
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	TRANSPOSE_DOWN 1
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE F_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE G_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE C_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	LOOP_START
	NOTE C_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 3
	NOTE OCT_UP, 5
	RELEASE 0, 0
	LEN_UNIT $0E
	NOTE C_, 0
	SND_END
SndBA_Ch3_75E2:
	WAVE $0D
	RELEASE 6, 2
	REST 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	REST 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	REST 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	REST 2
	SND_RET
SndBA_Ch3_7604:
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	SND_RET
SndBA_Ch3_7617:
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	REST 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE OCT_UP, 2
	SND_RET
SndBA_Ch3_7627:
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	REST 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 3, 3
	VIBRATO $08, 0, 8
	WAVE 1
	OCTAVE 3
	NOTE F_, 4
	NOTE OCT_UP, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE E_, 4
	NOTE OCT_UP, 2
	NOTE F_, 4
	NOTE OCT_UP, 2
	NOTE F_, 4
	NOTE F_, 4
	NOTE OCT_UP, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE OCT_UP, 2
	NOTE E_, 4
	NOTE OCT_UP, 2
	NOTE A_, 4
	OCTAVE 2
	WAVE $0D
	RELEASE 6, 2
	ATTEN 0
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_RET
SndBA_Ch3_7660:
	VIBRATO_OFF
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	REST 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE OCT_UP, 2
	SND_RET

SndBA_Drm:
	SND_CALL SndBA_Drm_76E6
	SND_CALL SndBA_Drm_76F2
	SND_CALL SndBA_Drm_76D6
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	SND_CALL SndBA_Drm_76D6
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL SndBA_Drm_7707
SndBA_Drm_76A9:
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	LOOP_END $0F
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 3, 2
	LOOP_END $0E
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 3
	DRUM 4, 5
	DRUM 3, 0
	SND_END
SndBA_Drm_76D6:
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 2, 1
	DRUM 3, 1
	SND_RET
SndBA_Drm_76E6:
	LEN_UNIT $0B
	REST 0
	REST 0
	LEN_UNIT 8
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	SND_RET
SndBA_Drm_76F2:
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_RET
SndBA_Drm_7707:
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_RET

SndBB_Ch2:
	TRANSPOSE_DOWN 2
	SND_CALL SndBA_Ch2_73BC
	SND_CALL SndBA_Ch2_7374
	NOTE D_, $0C
	LEN_UNIT 8
	REST 8
	LOOP2_START
	SND_CALL SndBA_Ch2_72DD
	SND_CALL SndBA_Ch2_7300
	SND_CALL SndBA_Ch2_72DD
	SND_CALL SndBA_Ch2_7313
	SND_CALL SndBA_Ch1_7330
	SND_CALL SndBA_Ch2_7382
	LOOP2_END 2
	SND_JUMP SndBA_Ch2_7280

SndBB_Ch1:
	TRANSPOSE_DOWN 2
	SND_CALL SndBA_Ch1_753F
	LOOP2_START
	SND_CALL SndBA_Ch1_7451
	SND_CALL SndBA_Ch1_7487
	SND_CALL SndBA_Ch1_7451
	SND_CALL SndBA_Ch1_74A9
	OCTAVE 2
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	SND_CALL SndBA_Ch1_7330
	SND_CALL SndBA_Ch1_74FB
	LOOP2_END 2
	SND_JUMP SndBA_Ch1_73E2

SndBB_Ch3:
	TRANSPOSE_DOWN 2
	VOICE $0B, 2, 2, 5, 7
	VIBRATO $01, 10, 6
	DETUNE $FF
	SND_CALL SndBA_Ch2_7374
	OCTAVE 2
	NOTE G_, $0C
	LEN_UNIT 8
	REST 8
	LOOP2_START
	SND_CALL SndBA_Ch3_75E2
	SND_CALL SndBA_Ch3_7617
	SND_CALL SndBA_Ch3_75E2
	SND_CALL SndBA_Ch3_7627
	SND_CALL SndBA_Ch3_7660
	LOOP2_END 2
	SND_JUMP SndBA_Ch3_757B

SndBB_Drm:
	SND_CALL SndBA_Drm_76E6
	LOOP2_START
	SND_CALL SndBA_Drm_76F2
	SND_CALL SndBA_Drm_76D6
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	SND_CALL SndBA_Drm_76D6
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL SndBA_Drm_7707
	LOOP2_END 2
	SND_JUMP SndBA_Drm_76A9

SndBC_Ch2:
	TRANSPOSE_UP 2
	TEMPO $10
	VOICE $06, 0, 10, 14, 3
	VIBRATO $08, 0, 10
	DUTY_STEP 4, 1
	SND_CALL SndBC_Ch1_78AB
	SND_SEGNO
	SND_CALL SndBC_Ch2_786E
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	DUTY 8
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_CALL SndBC_Ch2_786E
	NOTE A_, 2
	NOTE G_, 2
	RELEASE $0D, 7
	NOTE E_, 6
	DUTY 0
	RELEASE $0F, 6
	SND_CALL SndBC_Ch1_78F3
	OCTAVE 4
	NOTE D_, 1
	VOICE $06, 8, 7, 14, 3
	DUTY_STEP 4, 1
	VIBRATO $01, 2, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN_UNIT 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	LEN_UNIT 6
	NOTE E_, 4
	DUTY_STEP 0, 1
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	RELEASE $0E, 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	LEN_UNIT 6
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 4
	DUTY_STEP 0, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 4
	REST 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0E, 5
	NOTE E_, 3
	NOTE G_, 1
	RELEASE $0C, 7
	NOTE E_, 8
	RELEASE $0E, 3
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	DUTY 0
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	VIBRATO $08, 0, 4
	OCTAVE 5
	NOTE D_, 3
	NOTE D_, 1
	SND_CALL SndBC_Ch1_78FF
	SND_LOOP
SndBC_Ch2_786E:
	VOICE $06, 4, 8, 14, 3
	DUTY_STEP 0, 1
	VIBRATO $01, 2, 2
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 1
	RELEASE $0E, 7
	NOTE E_, 3
	RELEASE $0F, 3
	OCTAVE 4
	DUTY 0
	DUTY_STEP 8, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	DUTY_STEP 0, 1
	RELEASE $0E, 3
	ATTEN 0
	DUTY_STEP 0, 1
	DUTY 4
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	SND_RET
SndBC_Ch1_78AB:
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE A_, 1
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 1
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 3
	DUTY_STEP 0, 1
	DUTY 8
	OCTAVE 3
	NOTE B_, 1
	REST 2
	RELEASE 0, 0
	NOTE B_, 2
	DUTY_STEP 0, 0
	LEN_UNIT 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
SndBC_Ch1_78F3:
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_RET
SndBC_Ch1_78FF:
	REST 2
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE D_, 6
	LEN_UNIT 1
	DUTY_STEP 0, 0
	ATTEN 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
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
	OCTAVE 3
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
	SND_RET

SndBC_Ch1:
	VOICE $06, 0, 8, 14, 3
	DUTY_STEP 0, 1
	TRANSPOSE_DOWN 3
	SND_CALL SndBC_Ch1_78AB
	SND_SEGNO
	TRANSPOSE_UP 2
	SND_CALL SndBC_Ch1_79E2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE F#, 1
	SND_CALL SndBC_Ch1_79E2
	NOTE D#, 2
	RELEASE $0E, 7
	OCTAVE 2
	NOTE B_, 6
	DUTY 0
	RELEASE $0E, 3
	PAN_LEFT 0
	ATTEN 2
	REST 1
	SND_CALL SndBC_Ch1_78F3
	VOICE $06, 0, 6, 14, 3
	DUTY_STEP 8, 1
	OCTAVE 3
	LOOP_START
	NOTE A_, 2
	LOOP_END 8
	DUTY 8
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 3
	REST 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	DUTY 0
	PAN_BOTH 0
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	PAN_BOTH 0
	LOOP_START
	NOTE G_, 2
	LOOP_END 6
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 0
	DUTY 8
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 3
	REST 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	DUTY 4
	RELEASE $0D, 2
	DETUNE $00
	ATTEN 1
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	RELEASE $0D, 7
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	RELEASE $0E, 4
	REST 2
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	DUTY 0
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D#, 3
	NOTE D#, 1
	TRANSPOSE_DOWN 3
	SND_CALL SndBC_Ch1_78FF
	SND_LOOP
SndBC_Ch1_79E2:
	VOICE $06, 4, 6, 13, 2
	DETUNE $FF
	REST 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 3
	DUTY 0
	PAN_LEFT 0
	ATTEN 2
	REST 2
	RELEASE $0D, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 2
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_RET

SndBC_Ch3:
	TRANSPOSE_UP 2
	VOICE $06, 3, 2, 6, 0
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	VIBRATO $08, 0, 3
	RELEASE 6, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 3
	NOTE B_, 3
	NOTE OCT_UP, 1
	REST 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	LEN_UNIT 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_SEGNO
	SND_CALL SndBC_Ch3_7A9F
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	SND_CALL SndBC_Ch3_7A9F
	OCTAVE 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	NOTE F_, 2
	NOTE OCT_UP, 2
	NOTE E_, 2
	NOTE OCT_UP, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE A_, 2
	NOTE OCT_UP, 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	NOTE B_, 2
	NOTE OCT_UP, 2
	OCTAVE 2
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	NOTE D_, 2
	NOTE OCT_UP, 2
	LOOP_START
	NOTE E_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE C_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	OCTAVE 1
	LOOP_START
	NOTE B_, 2
	NOTE OCT_UP, 2
	LOOP_END 3
	NOTE A#, 2
	NOTE OCT_UP, 2
	LOOP_START
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 2
	REST 1
	OCTAVE 1
	NOTE B_, $0A
	SND_LOOP
SndBC_Ch3_7A9F:
	LEN_UNIT 6
	RELEASE 6, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE D_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C#, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE C_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	SND_RET

SndBC_Drm:
	LEN_UNIT 6
	LOOP_START
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END $0F
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	LOOP_END 4
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

SndBD_Ch2:
	TRANSPOSE_UP 1
	TEMPO $08
	VOICE $06, 0, 8, 14, 3
	SND_CALL SndBD_Ch1_7BC7
	NOTE F#, 8
	SND_SEGNO
	LOOP2_START
	SND_CALL SndBD_Ch2_7BE3
	NOTE F#, 1
	ATTEN 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	ATTEN 4
	NOTE B_, 1
	NOTE A_, 1
	LOOP2_END 3
	SND_CALL SndBD_Ch2_7BE3
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	VIBRATO $01, 4, 3
	VOICE $06, 8, 8, 9, 6
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 3
	NOTE B_, $0A
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 8
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 3
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, $0A
	DUTY 0
	ATTEN 0
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 2
	NOTE A_, 2
	DUTY 8
	ATTEN 1
	NOTE B_, $0A
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	DUTY 0
	ATTEN 0
	DUTY_STEP 8, 1
	NOTE A_, 1
	REST 2
	NOTE F#, 1
	NOTE F#, 6
	DUTY 8
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 0
	RELEASE $0F, 1
	REST 2
	OCTAVE 6
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	LOOP2_START
	VOICE $06, 4, 8, 12, 3
	VIBRATO $01, 1, 3
	SND_CALL SndBD_Ch2_7C10
	SND_CALL SndBD_Ch1_7C28
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	DUTY 8
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP2_END 3
	DUTY 4
	DUTY_STEP 4, 1
	SND_CALL SndBD_Ch2_7C10
	RELEASE $0C, 4
	DUTY 8
	ATTEN 1
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_LOOP
SndBD_Ch1_7BC7:
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 5
	OCTAVE 5
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE F#, 2
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	RELEASE $0C, 6
	SND_RET
SndBD_Ch2_7BE3:
	VOICE $06, 4, 7, 15, 3
	VIBRATO $08, 0, 12
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	LOOP_START
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	LOOP_END 3
	VOICE $06, 0, 8, 10, 5
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_RET
SndBD_Ch2_7C10:
	ATTEN 0
	LOOP_START
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 4
	LOOP_END 2
	ATTEN 3
	LOOP_START
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 2
	LOOP_END 2
	ATTEN 0
	SND_RET
SndBD_Ch1_7C28:
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	SND_RET

SndBD_Ch1:
	VOICE $06, 0, 7, 14, 2
	TRANSPOSE_DOWN 4
	SND_CALL SndBD_Ch1_7BC7
	TRANSPOSE_UP 1
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 4
	VIBRATO_OFF
	SND_SEGNO
	VIBRATO $02, 3, 2
	ATTEN 0
	LOOP2_START
	SND_CALL SndBD_Ch1_7D0F
	PAN_BOTH 0
	ATTEN 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	NOTE E_, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	LOOP2_END 3
	SND_CALL SndBD_Ch1_7D0F
	PAN_BOTH 0
	ATTEN 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	DUTY_STEP 4, 1
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE B_, 5
	NOTE F#, 1
	NOTE A_, 4
	NOTE G#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 4
	DUTY 0
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	NOTE E_, 1
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 6
	DUTY 8
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 0
	REST 8
	PAN_RIGHT 0
	LOOP2_START
	DETUNE $FF
	DUTY_STEP 0, 0
	ATTEN 4
	DUTY 0
	RELEASE $0C, 4
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	LOOP_START
	OCTAVE 5
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	LOOP_END 4
	SND_CALL SndBD_Ch1_7C28
	VOICE $06, 8, 7, 12, 4
	DETUNE $00
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	PAN_LEFT 0
	LOOP2_END 2
	PAN_BOTH 0
	LEN_UNIT 4
	LOOP_START
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END $0C
	LOOP_START
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	LOOP_END $0C
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END $0C
	LEN_UNIT 6
	ATTEN 4
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	SND_LOOP
SndBD_Ch1_7D0F:
	VOICE $06, 8, 7, 12, 6
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	LOOP_START
	ATTEN 2
	OCTAVE 2
	NOTE F#, 1
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 4
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 6
	NOTE F#, 1
	NOTE E_, 1
	PAN_LEFT 0
	LOOP_END 2
	PAN_RIGHT 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_RET

SndBD_Ch3:
	TRANSPOSE_UP 1
	VOICE $06, 4, 2, 12, 3
	VIBRATO $08, 0, 15
	OCTAVE 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE G_, 1
	NOTE OCT_UP, 1
	NOTE G_, 1
	NOTE OCT_UP, 1
	NOTE C#, 1
	NOTE OCT_UP, 1
	RELEASE $0D, 7
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 8, 7
	NOTE F#, 4
	NOTE OCT_UP, 4
	SND_SEGNO
	LOOP_START
	RELEASE $0C, 3
	OCTAVE 1
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE F#, 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE OCT_UP, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE OCT_UP, 2
	LOOP_END 4
	LOOP_START
	NOTE G_, 1
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE A_, 1
	NOTE OCT_UP, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	LOOP_START
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE OCT_UP, 1
	NOTE F#, 1
	LOOP_START
	NOTE G_, 1
	NOTE OCT_UP, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	OCTAVE 2
	NOTE F#, 1
	REST 2
	OCTAVE 1
	NOTE F#, 1
	RELEASE 8, 6
	NOTE F#, 6
	RELEASE $0C, 3
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE G_, 1
	NOTE OCT_UP, 1
	NOTE A_, 1
	NOTE OCT_UP, 1
	LOOP_START
	NOTE B_, 1
	NOTE OCT_UP, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE OCT_UP, 1
	LOOP_END 2
	REST 8
	LOOP_START
	RELEASE $0A, 3
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE OCT_UP, 1
	NOTE C#, 1
	NOTE OCT_UP, 1
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 1
	NOTE OCT_UP, 1
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END 4
	SND_LOOP

SndBD_Drm:
	LEN_UNIT 3
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 2
	LOOP_END 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 2
	LOOP_START
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	LOOP_END 2
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0B, 2
	LOOP_END $0F
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0B, 2
	LOOP_END 5
	DRUM 4, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 9, 4
	DRUM 8, 4
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 4, 2
	LOOP_END 7
	LOOP_START
	DRUM 5, 2
	LOOP_END 8
	DRUM 5, 1
	DRUM 5, 1
	LOOP_START
	DRUM 4, 2
	LOOP_END 7
	SND_LOOP

SndBE_Ch2:
	TRANSPOSE_UP 5
	TEMPO $10
	VOICE $02, 4, 8, 11, 3
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	LEN_UNIT 8
	NOTE A_, 2
	VIBRATO $08, 0, 6
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 3
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	SND_CALL SndBE_Ch2_7ED1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	REST 6
	SND_SEGNO
	VIBRATO $01, 4, 5
	VOICE $08, 0, 7, 8, 6
	DUTY_STEP 8, 2
	ENVELOPE_OFF
	OCTAVE 4
	NOTE E_, 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 2
	NOTE A_, 4
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 0
	NOTE F_, 6
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 8
	NOTE E_, 6
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 8
	DUTY 8
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	SND_LOOP
SndBE_Ch2_7ED1:
	DUTY 4
	VIBRATO $0E, 0, 8
	ENVELOPE $13
	DUTY_STEP 0, 3
	SND_RET

SndBE_Ch1:
	TRANSPOSE_UP 5
	VOICE $02, 4, 7, 11, 3
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT 8
	NOTE E_, 2
	VIBRATO $08, 0, 13
	NOTE E_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 3
	NOTE A_, 1
	NOTE B_, 2
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	REST 6
	SND_SEGNO
	VOICE $08, 4, 7, 14, 5
	VIBRATO $02, 2, 3
	REST 2
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE G#, 4
	NOTE G#, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	LOOP_START
	REST 2
	NOTE F_, 4
	NOTE F_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE E_, 4
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 1
	DUTY 0
	RELEASE 5, 5
	ATTEN 3
	PAN_LEFT 0
	DETUNE $FF
	OCTAVE 3
	NOTE E_, 6
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	VOICE $08, 4, 7, 15, 5
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 4
	NOTE G#, 4
	SND_LOOP

SndBE_Ch3:
	VOICE $08, 3, 2, 8, 3
	TRANSPOSE_UP 5
	OCTAVE 1
	NOTE A_, 4
	REST 4
	OCTAVE 2
	NOTE D_, 4
	REST 4
	OCTAVE 1
	NOTE E_, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE OCT_UP, 2
	NOTE OCT_UP, 1
	NOTE OCT_UP, 1
	NOTE E_, 2
	REST 6
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	LOOP_END 2
	LOOP2_START
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP2_END 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE OCT_UP, 2
	SND_LOOP

SndBE_Drm:
	LEN_UNIT 8
	DRUM 4, 3
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM 4, 3
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 7, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	SND_LOOP

SndBF_Ch2:
	VOICE $07, 0, 11, 8, 7
	VIBRATO $01, 7, 2
	DUTY_STEP 8, 1
	SND_JUMP SndBF_Ch1_7FE0
SndBF_Ch1_7FE0:
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 0
	SND_END

SndBF_Ch1:
	VOICE $07, 0, 6, 8, 7
	REST 2
	PAN_RIGHT 0
	DETUNE $FF
	VIBRATO $02, 1, 1
	SND_JUMP SndBF_Ch1_7FE0

SndBF_Ch3:
	SND_END
	db $FF, $FF, $FF, $FF

SECTION "Sound bank 13", ROMX[$7000], BANK[13]
B13_SoundTable:
	dw SndHdrF1 ; $F1
	dw SndHdrF2 ; $F2
	dw SndHdrF3 ; $F3
	dw SndHdrF4 ; $F4
	dw SndHdrF5 ; $F5
	dw SndHdrF6 ; $F6
	dw SndHdrF7 ; $F7
	dw SndHdrF8 ; $F8
	dw SndHdrF9 ; $F9
	dw SndHdrFA ; $FA

SndHdrF1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF1_Ch1
	dw SndF1_Ch2
	dw SndF1_Ch3
	dw SndF1_Drm

SndHdrF4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF4_Ch1
	dw SndF4_Ch2
	dw SndF4_Ch3
	dw SndF4_Drm

SndHdrF6:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF6_Ch1
	dw SndF6_Ch2
	dw SndF6_Ch3
	dw SndF6_Drm

SndHdrF5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF5_Ch1
	dw SndF5_Ch2
	dw SndF5_Ch3
	dw SndF5_Drm

SndHdrF8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF8_Ch1
	dw SndF8_Ch2
	dw SndF8_Ch3
	dw SndF8_Drm

SndHdrF9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF9_Ch1
	dw SndF9_Ch2
	dw SndF9_Ch3
	dw SndF9_Drm

SndHdrFA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFA_Ch1
	dw SndFA_Ch2
	dw SndFA_Ch3
	dw SndFA_Drm

SndHdrF7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF7_Ch1
	dw SndF7_Ch2
	dw SndF7_Ch3
	dw SndF7_Drm

SndHdrF3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF3_Ch1
	dw SndF3_Ch2
	dw SndF3_Ch3
	dw SndF3_Drm

SndHdrF2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF2_Ch1
	dw SndF2_Ch2
	dw SndF2_Ch3
	dw SndF2_Drm

SndF1_Ch2:
	TEMPO $08
	TRANSPOSE_UP 6
	VOICE $04, 8, 13, 14, 4
	ENVELOPE $02
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 7
	REST $0C
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 2
	NOTE E_, 3
	NOTE D_, 1
	DUTY_STEP 0, 0
	VIBRATO_OFF
	NOTE E_, 1
	NOTE D_, 1
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 7
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE C_, 2
	NOTE D_, 3
	NOTE C_, 1
	DUTY_STEP 0, 0
	VIBRATO_OFF
	NOTE D_, 1
	NOTE C_, 1
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 7
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 2
	DUTY 0
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	SND_END

SndF1_Ch1:
	TRANSPOSE_UP 6
	VOICE $04, 8, 11, 14, 3
	DUTY_STEP 4, 1
	DETUNE $FF
	REST $0C
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 6
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 4
	NOTE D_, 2
	REST 2
	ATTEN 4
	PAN_LEFT 0
	VIBRATO $08, 0, 7
	DUTY_STEP 4, 1
	DUTY 0
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	SND_END

SndF1_Ch3:
	TRANSPOSE_UP 6
	VOICE $04, 4, 2, 9, 6
	REST $0C
	OCTAVE 2
	NOTE C_, 6
	NOTE C_, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A#, 6
	NOTE A_, 6
	NOTE A_, 6
	NOTE E_, 6
	NOTE D#, 6
	NOTE D_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE B_, 6
	AUTOPAN_OFF 0
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 4
	SND_END

SndF1_Drm:
	LEN_UNIT 4
	REST 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 4
	DRUM 8, 2
	LOOP_START
	DRUM 3, 6
	DRUM 1, 4
	DRUM 2, 2
	LOOP_END 3
	DRUM 3, 3
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM 3, 6
	DRUM 4, 4
	DRUM 4, 2
	DRUM 3, 6
	DRUM 4, 4
	DRUM 4, 2
	DRUM $0A, 3
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 6
	DRUM 8, 6
	SND_END

SndF3_Ch2:
	TRANSPOSE_UP 7
	TEMPO $10
	OCTAVE 3
	SND_CALL SndF3_Ch2_76CC
	SND_CALL SndF3_Ch1_71C4
	TEMPO $00
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 4
	REST $0C

SndF2_Ch2:
	TRANSPOSE_UP 7
	SND_SEGNO
	SND_CALL SndF2_Ch1_7162
	SND_LOOP
SndF2_Ch1_7162:
	VOICE $02, 0, 9, 15, 3
	DUTY_STEP 4, 1
	VIBRATO $0A, 0, 12
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, $0B
	LEN_UNIT 6
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 4
	DUTY 8
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	DUTY 0
	LEN_UNIT 2
	NOTE D_, 1
	NOTE E_, $0B
	LEN_UNIT 6
	NOTE E_, 2
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 4
	DUTY 8
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 4
	NOTE E_, 2
	DUTY 0
	LEN_UNIT 2
	NOTE C_, 1
	NOTE D_, $0B
	LEN_UNIT 6
	NOTE D_, 2
	NOTE C_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE A_, 2
	DUTY 8
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE E_, 4
	LEN_UNIT 1
	DUTY_STEP 0, 0
	ATTEN 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	VIBRATO $01, 4, 5
	RELEASE $0F, 7
	LEN_UNIT 6
	NOTE E_, 6
	SND_RET
SndF3_Ch1_71C4:
	LEN_UNIT 5
	REST 7
	DRUM $0A, 7 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 5 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 4 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	LEN_UNIT 4
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	LEN_UNIT 3
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	LEN_UNIT 2
	LOOP_START
	DRUM $0A, 3 ; also played as a DRUM by the drum track (shared subroutine)
	LOOP_END 6
	LEN_UNIT 1
	DRUM $0A, 4 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 4 ; also played as a DRUM by the drum track (shared subroutine)
	DRUM $0A, 0 ; also played as a DRUM by the drum track (shared subroutine)
	REST 0
	LEN_UNIT 6
	SND_RET

SndF3_Ch1:
	TRANSPOSE_UP 2
	VOICE $05, 0, 7, 15, 2
	PAN_RIGHT 0
	OCTAVE 3
	SND_CALL SndF3_Ch1_71C4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 4
	REST $0C

SndF2_Ch1:
	SND_SEGNO
	TRANSPOSE_UP 2
	SND_CALL SndF2_Ch1_7162
	SND_LOOP

SndF3_Ch3:
	TRANSPOSE_UP 7
	VOICE $05, 9, 2, 15, 2
	VIBRATO $0E, 0, 15
	OCTAVE 3
	PAN_LEFT 0
	SND_CALL SndF3_Ch1_71C4
	REST 6
	REST $0C

SndF2_Ch3:
	TRANSPOSE_UP 7
	SND_SEGNO
	TRANSPOSE_DOWN 5
	VIBRATO_OFF
	VIBRATO $0A, 0, 15
	VOICE $06, 4, 2, 5, 0
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE G_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 4
	NOTE C_, 2
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE G_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 4
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 4
	LEN_UNIT 1
	VIBRATO_OFF
	WAVE 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT 6
	VIBRATO $02, 3, 10
	NOTE E_, 6
	SND_LOOP

SndF3_Drm:
	SND_CALL SndF3_Ch1_71C4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 8
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2

SndF2_Drm:
	LEN_UNIT 6
	SND_SEGNO
	LOOP_START
	DRUM 1, 4
	DRUM 2, 2
	DRUM 1, 4
	DRUM 2, 2
	DRUM 4, $0C
	LOOP_END 2
	DRUM 1, 4
	DRUM 2, 2
	DRUM 1, 4
	DRUM 2, 2
	DRUM 4, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM 1, 4
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 4
	DRUM 2, 2
	DRUM 1, 4
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 4
	DRUM 4, 2
	SND_LOOP

SndF4_Ch1:
	VOICE $05, 8, 6, 8, 7
	VIBRATO $01, 2, 1
	REST 3
	PAN_LEFT 0
	DETUNE $01
	SND_JUMP SndF4_Ch1_7297
SndF4_Ch1_7297:
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 0
	SND_END

SndF4_Ch2:
	VOICE $05, 0, 7, 0, 0
	VIBRATO $02, 5, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 0
	SND_END

SndF4_Ch3:
	VOICE $05, 9, 2, 0, 0
	VIBRATO $02, 10, 2
	SND_JUMP SndF4_Ch1_7297

SndF4_Drm:
	SND_END

SndF5_Ch2:
	TEMPO $08
	TRANSPOSE_UP $0D
	SND_SEGNO
	LOOP_START
	VOICE $0C, 8, 8, 15, 3
	DUTY_STEP 4, 1
	VIBRATO $01, 2, 1
	REST 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	VIBRATO $0A, 0, 4
	DUTY 0
	NOTE F#, 2
	NOTE F#, 2
	PAN_RIGHT 0
	ATTEN 6
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 2
	VIBRATO $01, 2, 1
	PAN_BOTH 0
	ATTEN 0
	RELEASE $0F, 7
	NOTE B_, 4
	LOOP_END 2
	VOICE $0C, 4, 8, 15, 3
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	LOOP_END 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	LOOP_END 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	DUTY 0
	DUTY_STEP 0, 0
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	LOOP_END 2
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	RELEASE $0C, 7
	NOTE B_, 8
	REST 8
	SND_LOOP

SndF5_Ch1:
	TRANSPOSE_UP $0D
	SND_SEGNO
	VOICE $0C, 8, 7, 15, 4
	VIBRATO $02, 3, 1
	DETUNE $01
	PAN_RIGHT 0
	LOOP_START
	DUTY 8
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	DUTY 0
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 5
	PAN_LEFT 0
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 4
	PAN_LEFT 0
	LOOP_END 2
	VOICE $0C, 4, 7, 15, 4
	LOOP2_START
	LOOP_START
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 2
	LOOP_START
	NOTE C_, 1
	LOOP_END 8
	OCTAVE 2
	LOOP2_END 2
	DUTY 0
	PAN_LEFT 0
	REST 1
	ATTEN 3
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	LOOP_END 2
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE $0C, 7
	NOTE F#, 8
	REST 8
	SND_LOOP

SndF5_Ch3:
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP_START
	VOICE $0C, 4, 2, 3, 0
	VIBRATO $0A, 0, 4
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	REST $0A
	NOTE F#, 2
	NOTE B_, 2
	NOTE B_, 2
	REST 8
	WAVE 2
	RELEASE 7, 8
	OCTAVE 4
	NOTE B_, 4
	LOOP_END 2
	WAVE 4
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 6
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 4
	REST 8
	SND_LOOP

SndF5_Drm:
	LEN_UNIT $0C
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM $0B, 2
	LOOP_END 8
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 4
	SND_LOOP

SndF6_Ch2:
	TEMPO $20
	VOICE $05, 0, 8, 8, 7
	DUTY_STEP 4, 1
	OCTAVE 1
	NOTE A_, 4
	ATTEN 1
	SND_CALL SndF3_Ch2_76CC
	SND_CALL SndF6_Ch1_7452
	LEN_UNIT $0B
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	ENVELOPE_OFF
	ATTEN 0
	NOTE A_, 8
	SND_END
SndF6_Ch1_7452:
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE A_, 2
	NOTE A_, 6
	SND_RET

SndF6_Ch1:
	VOICE $05, 0, 7, 15, 3
	DUTY_STEP 4, 1
	VIBRATO $08, 0, 1
	DETUNE $FF
	OCTAVE 2
	NOTE E_, 4
	TRANSPOSE_DOWN $0C
	SND_CALL SndF6_Ch1_7452
	LEN_UNIT $0B
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 8, 7
	NOTE E_, 8
	SND_END

SndF6_Ch3:
	VOICE $05, 11, 2, 2, 0
	VIBRATO $08, 0, 5
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE E_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 6
	LEN_UNIT $0B
	NOTE A_, 2
	NOTE A_, 1
	REST 1
	RELEASE 0, 0
	NOTE A_, 8
	SND_END

SndF6_Drm:
	LEN_UNIT 5
	DRUM 4, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM $0B, 3
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM $0B, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 6
	DRUM 4, 4
	DRUM 4, 4
	LEN_UNIT $0B
	DRUM 7, 8
	SND_END

SndFA_Ch2:
	TEMPO $10
	SND_CALL SndFA_Ch2_76AD
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 6
	NOTE F#, 2
	NOTE A_, 3
	ATTEN 4
	NOTE A_, 1
	SND_CALL SndFA_Ch2_76B7
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 4
	NOTE E_, 2
	SND_CALL SndFA_Ch2_76C1
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE B_, 2
	NOTE A_, 4
	RELEASE $0B, 2
	DUTY 0
	VIBRATO $0D, 0, 2
	DUTY_STEP 4, 2
	ATTEN 2
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE D#, 4
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE B_, 2
	SND_CALL SndFA_Ch2_76AD
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 3
	ATTEN 4
	NOTE D_, 1
	SND_CALL SndFA_Ch2_76B7
	OCTAVE 5
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 2
	SND_CALL SndFA_Ch2_76C1
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE E_, 6
	RELEASE 8, 4
	DUTY 4
	VIBRATO $01, 4, 3
	OCTAVE 4
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, $0A
	NOTE E_, 2
	NOTE F#, $0A
	NOTE A_, 2
	ATTEN 1
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE E_, 4
	DUTY 0
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	SND_SEGNO
	RELEASE $0B, 3
	DUTY 8
	VIBRATO $09, 0, 10
	ENVELOPE_OFF
	DUTY_STEP 4, 2
	ATTEN 0
	OCTAVE 4
	NOTE F#, 4
	NOTE F#, 6
	NOTE F#, 2
	NOTE E_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	DUTY 0
	VIBRATO $09, 0, 1
	DUTY_STEP 4, 1
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	SND_CALL SndF3_Ch2_76CC
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE D_, 2
	VOICE $0A, 8, 8, 11, 4
	ENVELOPE $01
	VIBRATO $01, 7, 3
	OCTAVE 3
	NOTE A_, $0C
	LEN_UNIT 5
	ENVELOPE_OFF
	DUTY_STEP 4, 1
	VIBRATO $01, 3, 2
	DUTY 0
	OCTAVE 4
	NOTE A_, 4
	DUTY 8
	OCTAVE 3
	NOTE F#, 2
	NOTE A_, 4
	NOTE F#, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE F#, 4
	NOTE E_, 2
	LEN_UNIT $0A
	ENVELOPE $01
	NOTE F#, $0C
	LEN_UNIT 5
	SND_CALL SndF3_Ch2_76CC
	OCTAVE 4
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE F#, 6
	RELEASE $0B, 4
	DUTY 8
	VIBRATO $01, 3, 2
	ENVELOPE_OFF
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 4
	NOTE F#, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	NOTE E_, 4
	RELEASE 0, 0
	NOTE A_, 4
	LEN_UNIT 1
	DUTY_STEP 0, 0
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 2
	LEN_UNIT 5
	NOTE A_, 2
	RELEASE $0B, 4
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 6
	DUTY 0
	VIBRATO $0D, 0, 2
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE C#, 4
	NOTE B_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE G_, 2
	DUTY 4
	VIBRATO $01, 3, 2
	DUTY_STEP 0, 2
	REST 4
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE F#, 4
	NOTE F#, 2
	NOTE F#, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE A_, 4
	NOTE B_, 2
	NOTE A_, 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 4
	NOTE A_, 2
	SND_CALL SndF3_Ch2_76CC
	LOOP_START
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	LOOP_END 2
	DUTY 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE E_, 6
	NOTE D_, 4
	NOTE E_, 2
	VOICE $05, 4, 9, 8, 5
	VIBRATO $01, 4, 3
	ENVELOPE_OFF
	DUTY_STEP 0, 0
	ATTEN 1
	REST 4
	NOTE F#, 6
	NOTE E_, 2
	NOTE F#, $0A
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, $0C
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 6
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE F#, 2
	NOTE E_, 0
	SND_CALL SndF3_Ch2_76CC
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 4
	NOTE E_, 2
	VOICE $05, 4, 9, 10, 3
	VIBRATO $01, 3, 2
	DUTY_STEP 8, 1
	ENVELOPE_OFF
	OCTAVE 2
	REST 4
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	REST 4
	NOTE F#, 2
	NOTE A_, 4
	NOTE F#, 2
	NOTE A_, 6
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 5
	REST 4
	NOTE E_, 6
	NOTE D_, 2
	NOTE E_, $0A
	NOTE D_, 2
	RELEASE $0C, 3
	DUTY 0
	VIBRATO $0D, 0, 3
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE D_, 6
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 4
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE A_, 2
	SND_CALL SndF3_Ch2_76CC
	REST 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	RELEASE 8, 5
	DUTY 8
	VIBRATO $01, 4, 3
	ENVELOPE_OFF
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE A_, 6
	NOTE F#, 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE E_, 8
	NOTE D_, $0C
	DUTY 4
	DUTY_STEP 0, 2
	NOTE D_, 4
	NOTE D_, 2
	SND_CALL SndF3_Ch2_76CC
	VIBRATO $0E, 0, 3
	REST 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 2
	VIBRATO $0E, 0, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 6
	NOTE D_, 4
	NOTE E_, 2
	SND_LOOP
SndFA_Ch2_76AD:
	VOICE $05, 8, 9, 8, 2
	VIBRATO $09, 0, 15
	DUTY_STEP 0, 2
	SND_RET
SndFA_Ch2_76B7:
	DUTY 8
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 1
	DETUNE $01
	SND_RET
SndFA_Ch2_76C1:
	RELEASE 8, 5
	DUTY 0
	ATTEN 0
	VIBRATO $01, 3, 2
	DETUNE $00
	SND_RET
SndF3_Ch2_76CC:
	DUTY 4
	VIBRATO $0E, 0, 8
	ENVELOPE $02
	DUTY_STEP 0, 3
	SND_RET

SndFA_Ch1:
	VOICE $05, 4, 8, 8, 2
	VIBRATO $02, 2, 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 6
	NOTE D_, 2
	NOTE F#, 3
	ATTEN 4
	NOTE F#, 1
	DUTY 8
	PAN_RIGHT 0
	ATTEN 4
	DETUNE $01
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	NOTE F#, 4
	NOTE E_, 1
	PAN_BOTH 0
	DETUNE $00
	ATTEN 1
	OCTAVE 2
	NOTE A_, 2
	RELEASE 8, 5
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE B_, 2
	NOTE A_, 2
	RELEASE $0F, 3
	DUTY 0
	VIBRATO $01, 0, 6
	ATTEN 1
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE F_, 4
	DUTY_STEP 0, 0
	NOTE C_, 2
	RELEASE 8, 2
	VIBRATO $02, 2, 1
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 6
	NOTE G_, 2
	NOTE B_, 3
	ATTEN 4
	NOTE B_, 1
	DUTY 8
	PAN_LEFT 0
	ATTEN 4
	DETUNE $01
	OCTAVE 5
	NOTE E_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	RELEASE 8, 5
	DUTY 0
	DETUNE $02
	ATTEN 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE E_, 2
	RELEASE $0D, 3
	VIBRATO $0D, 0, 1
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE E_, 2
	VOICE $05, 8, 8, 11, 3
	VIBRATO $02, 2, 1
	DUTY_STEP 0, 1
	DETUNE $00
	ATTEN 1
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	NOTE F#, 2
	NOTE F#, 4
	NOTE D_, 2
	NOTE F#, 4
	NOTE B_, 2
	ATTEN 3
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE A_, 2
	NOTE E_, 4
	DETUNE $01
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	DETUNE $00
	SND_SEGNO
	VOICE $05, 4, 8, 14, 3
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 6
	NOTE D_, 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE E_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 6
	RELEASE $0C, 3
	DUTY 0
	PAN_BOTH 0
	DUTY_STEP 8, 2
	NOTE A_, 4
	NOTE A_, 2
	VOICE $05, 4, 8, 12, 3
	NOTE F#, 4
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 4
	NOTE A_, 2
	RELEASE 8, 5
	DUTY 8
	DUTY_STEP 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 3
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE F#, 4
	PAN_LEFT 0
	DETUNE $01
	ATTEN 3
	OCTAVE 3
	NOTE F#, 4
	NOTE A_, 4
	NOTE F#, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE F#, 2
	PAN_BOTH 0
	RELEASE $0A, 4
	DUTY 0
	DUTY_STEP 4, 2
	DETUNE $00
	ATTEN 0
	OCTAVE 3
	NOTE F#, 6
	NOTE E_, 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 6
	RELEASE $0A, 4
	PAN_LEFT 0
	VIBRATO $02, 4, 4
	ATTEN 2
	OCTAVE 2
	NOTE A_, $0C
	NOTE G_, 6
	NOTE F#, 6
	PAN_RIGHT 0
	NOTE G_, $0C
	NOTE B_, 6
	NOTE G_, 6
	RELEASE 8, 6
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	DETUNE $02
	OCTAVE 1
	NOTE A_, $0A
	DETUNE $00
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, $0C
	OCTAVE 2
	NOTE A_, 6
	ATTEN 2
	DUTY 0
	VIBRATO $01, 0, 3
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE C_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE A_, 4
	NOTE F#, 2
	ATTEN 0
	RELEASE $0C, 3
	DUTY 4
	VIBRATO $09, 0, 2
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 6
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 6
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 4
	NOTE E_, 2
	PAN_RIGHT 0
	OCTAVE 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 2
	RELEASE 8, 7
	PAN_BOTH 0
	VIBRATO $02, 4, 5
	ATTEN 2
	OCTAVE 3
	NOTE F#, $0C
	NOTE D_, $0C
	RELEASE $0A, 5
	NOTE E_, 6
	NOTE E_, 4
	NOTE E_, 2
	NOTE A_, 6
	RELEASE 8, 6
	DUTY 0
	ATTEN 1
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 2
	NOTE B_, 6
	NOTE E_, 6
	NOTE F#, 4
	RELEASE $0D, 4
	DUTY 8
	PAN_LEFT 0
	ATTEN 0
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 4
	NOTE B_, 2
	RELEASE 8, 6
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	NOTE G_, 4
	NOTE F#, 6
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 4
	RELEASE $0D, 4
	DUTY 8
	PAN_RIGHT 0
	DUTY_STEP 0, 2
	ATTEN 1
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE A_, 4
	DETUNE $01
	ATTEN 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 4
	NOTE E_, 2
	RELEASE $0C, 5
	PAN_BOTH 0
	DUTY_STEP 4, 1
	DETUNE $00
	ATTEN 2
	PAN_RIGHT 0
	OCTAVE 2
	NOTE F#, $0C
	NOTE E_, 6
	NOTE F#, 6
	PAN_LEFT 0
	ATTEN 1
	NOTE A_, $0C
	NOTE B_, 6
	NOTE A_, 6
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 6
	PAN_RIGHT 0
	DETUNE $01
	ATTEN 3
	OCTAVE 4
	NOTE E_, 6
	NOTE D_, 2
	NOTE E_, $0A
	ATTEN 1
	RELEASE $0C, 2
	DUTY 0
	PAN_BOTH 0
	VIBRATO $02, 0, 4
	DUTY_STEP 8, 1
	NOTE F#, 4
	OCTAVE 5
	NOTE C#, 6
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 4
	OCTAVE 5
	NOTE D#, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE G_, 2
	RELEASE $0E, 2
	DUTY 4
	VIBRATO $01, 3, 3
	ENVELOPE $02
	ATTEN 0
	OCTAVE 3
	REST 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	RELEASE 8, 5
	DUTY 8
	PAN_RIGHT 0
	ENVELOPE_OFF
	DETUNE $01
	ATTEN 3
	NOTE A_, 8
	NOTE F#, 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	RELEASE $0A, 4
	DUTY 0
	PAN_BOTH 0
	DETUNE $00
	ATTEN 0
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 6
	NOTE A_, 4
	NOTE A_, 2
	DUTY 4
	DUTY_STEP 0, 1
	DETUNE $00
	NOTE A_, 4
	NOTE F#, 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	NOTE F#, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 6
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	SND_LOOP

SndFA_Ch3:
	TRANSPOSE_UP $0C
	VOICE $05, 3, 2, 2, 0
	VIBRATO $09, 0, 8
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 6
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 4
	NOTE E_, 2
	VIBRATO $09, 0, 8
	OCTAVE 2
	NOTE D_, 6
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	NOTE D_, 6
	OCTAVE 1
	NOTE A_, 4
	NOTE F#, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 6
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 2
	VIBRATO $09, 0, 8
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 6
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 4
	RELEASE 5, 0
	WAVE $0A
	VIBRATO $01, 0, 3
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 5
	NOTE C#, 2
	VOICE $05, 3, 2, 3, 0
	VIBRATO $09, 0, 8
	OCTAVE 2
	NOTE D_, $0A
	NOTE D_, 2
	NOTE C#, $0A
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 6
	NOTE B_, 6
	NOTE A_, 6
	NOTE A_, 6
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 6
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE D_, 2
	LOOP_START
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 6
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 2
	NOTE B_, $0A
	NOTE F#, 2
	NOTE B_, 6
	NOTE F#, 6
	NOTE B_, $0A
	NOTE F#, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 6
	NOTE D_, 6
	OCTAVE 1
	NOTE G_, $0A
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 6
	NOTE D_, 6
	OCTAVE 1
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, $0C
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 6
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, $0A
	NOTE F#, 2
	NOTE B_, $0A
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 6
	NOTE E_, 6
	OCTAVE 1
	NOTE A_, 6
	NOTE B_, 4
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 6
	NOTE E_, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE G_, $0A
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, $0A
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, $0A
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 6
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 6
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A_, $0A
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE OCT_UP, 6
	NOTE D_, 2
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	REST $0E
	NOTE A_, 6
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 6
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, $0A
	NOTE D_, 2
	NOTE C#, $0A
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 6
	NOTE B_, 4
	NOTE F#, 2
	NOTE A_, 6
	NOTE A_, 6
	SND_LOOP

SndFA_Drm:
	LEN_UNIT 5
	LOOP_START
	DRUM 4, 4
	DRUM 4, 6
	DRUM 5, 2
	DRUM 4, 6
	DRUM 4, 4
	DRUM 5, 2
	DRUM $0B, 4
	DRUM 4, 2
	DRUM 1, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 4
	DRUM 4, 2
	LOOP_END 2
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0B, 2
	LOOP_END 2
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	LOOP_END 3
	DRUM 4, 4
	DRUM $0B, 2
	SND_SEGNO
	DRUM 4, 4
	DRUM 4, 6
	DRUM 4, 2
	DRUM 4, $0C
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	LOOP2_START
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 4, 2
	LOOP_END 3
	DRUM $0B, 6
	DRUM 4, 4
	DRUM 5, 2
	LOOP2_END 3
	DRUM $0B, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM 4, $0C
	DRUM 4, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	LOOP2_START
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0B, 2
	LOOP_END 3
	DRUM 4, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	LOOP2_END 4
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0B, 2
	DRUM $0A, 4
	DRUM 5, 2
	DRUM $0A, 4
	DRUM 4, 2
	LOOP_END 2
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0B, 2
	LOOP_END 4
	DRUM $0B, 4
	DRUM $0A, 2
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM $0A, 4
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM 4, 0
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0A, 2
	DRUM 4, 4
	DRUM 5, 2
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 6
	DRUM 4, 4
	DRUM 5, 2
	LOOP_START
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM $0B, 2
	LOOP_END 2
	DRUM $0B, 4
	DRUM 4, 2
	DRUM $0B, 4
	DRUM 4, 2
	DRUM $0B, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 4, 2
	SND_LOOP

SndF7_Ch2:
	SND_SEGNO
	SND_CALL SndF7_Ch2_7B2C
	NOTE E_, 2
	RELEASE 0, 0
	DUTY_STEP 0, 0
	SND_CALL SndF7_Ch2_7B75
	SND_CALL SndF7_Ch2_7B2C
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	OCTAVE 2
	NOTE C_, 1
	REST 1
	PAN_RIGHT 0
	LEN_UNIT 1
	OCTAVE 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	LEN_UNIT 5
	PAN_BOTH 0
	DETUNE $03
	VIBRATO $01, 1, 8
	DUTY 4
	SND_CALL SndF7_Ch2_7B63
	NOTE D#, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_CALL SndF7_Ch2_7B63
	ATTEN 0
	NOTE E_, 2
	NOTE G_, 2
	ATTEN 1
	NOTE E_, 2
	RELEASE 0, 0
	DUTY_STEP 0, 0
	SND_CALL SndF7_Ch2_7B75
	LEN_UNIT 5
	VIBRATO_OFF
	DETUNE $00
	SND_LOOP
SndF7_Ch2_7B2C:
	VOICE $05, 0, 11, 14, 1
	DUTY_STEP 8, 2
	OCTAVE 3
	REST 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 2
	REST 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	SND_RET
SndF7_Ch2_7B63:
	OCTAVE 4
	REST 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 2
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE D#, 2
	SND_RET
SndF7_Ch2_7B75:
	LEN_UNIT 3
	NOTE D_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 5
	NOTE E_, 1
	LEN_UNIT 4
	ATTEN 6
	NOTE D_, 1
	ATTEN 7
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 7
	NOTE E_, 1
	LEN_UNIT 3
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	SND_RET

SndF7_Ch1:
	SND_SEGNO
	VOICE $05, 0, 6, 14, 1
	DUTY_STEP 8, 1
	SND_CALL SndF7_Ch1_7BE1
	NOTE A_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VOLUME $07
	SND_CALL SndF7_Ch1_7BE1
	DUTY_STEP 0, 0
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	REST 2
	OCTAVE 2
	NOTE G_, 1
	REST 1
	PAN_LEFT 0
	LEN_UNIT 1
	OCTAVE 1
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
	LEN_UNIT 5
	PAN_BOTH 0
	ATTEN 3
	DUTY $0C
	AUTOPAN_R 0
	VIBRATO $09, 0, 6
	LOOP_START
	OCTAVE 3
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	LOOP_END 7
	AUTOPAN_OFF 0
	VOLUME $07
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	REST 4
	SND_LOOP
SndF7_Ch1_7BE1:
	OCTAVE 2
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	REST 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	SND_RET

SndF7_Ch3:
	SND_SEGNO
	VOICE $05, 8, 2, 15, 3
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	LOOP_END 2
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 4
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	LOOP_END 3
	NOTE B_, 4
	RELEASE $0A, 4
	NOTE G_, 2
	RELEASE 0, 0
	LEN_UNIT 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT 5
	RELEASE $0F, 3
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	LOOP_END 2
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 4
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	LOOP_END 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 2
	REST 2
	RELEASE $0F, 3
	SND_CALL SndF7_Ch3_7CA3
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	WAVE 7
	VIBRATO $09, 0, 8
	VOLUME $04
	OCTAVE 4
	NOTE E_, 2
	WAVE 8
	VIBRATO_OFF
	VOLUME $02
	OCTAVE 2
	NOTE G_, 2
	WAVE 7
	VIBRATO $09, 0, 8
	VOLUME $04
	OCTAVE 4
	NOTE E_, 2
	WAVE 8
	VIBRATO_OFF
	VOLUME $02
	LOOP_END 2
	SND_CALL SndF7_Ch3_7CA3
	OCTAVE 3
	NOTE C_, 2
	WAVE 6
	VIBRATO $09, 0, 8
	VOLUME $04
	OCTAVE 4
	NOTE E_, 2
	WAVE 8
	VIBRATO_OFF
	VOLUME $02
	OCTAVE 2
	NOTE G_, 2
	LEN_UNIT 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	LEN_UNIT 5
	RELEASE $0F, 3
	NOTE G_, 2
	LEN_UNIT 3
	NOTE F_, 1
	NOTE G_, 1
	LEN_UNIT 4
	NOTE F_, 1
	LEN_UNIT 5
	NOTE E_, 2
	NOTE D_, 2
	SND_LOOP
SndF7_Ch3_7CA3:
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	VIBRATO $09, 0, 8
	VOLUME $04
	OCTAVE 4
	NOTE D_, 2
	WAVE 8
	VIBRATO_OFF
	VOLUME $02
	OCTAVE 2
	NOTE G_, 2
	WAVE 1
	VIBRATO $09, 0, 8
	VOLUME $04
	OCTAVE 4
	NOTE D_, 2
	WAVE 8
	VIBRATO_OFF
	VOLUME $02
	LOOP_END 2
	SND_RET

SndF7_Drm:
	SND_SEGNO
	LEN_UNIT 5
	LOOP_START
	DRUM 1, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	LOOP_END 7
	DRUM 3, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM 1, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	LOOP_END 6
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 7, 4
	LOOP_START
	DRUM 1, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	LOOP_END 3
	DRUM 3, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 2
	DRUM $0A, 1
	DRUM $0A, 1
	SND_LOOP

SndF8_Ch2:
	VOICE $0A, 4, 7, 15, 2
	DUTY_STEP 8, 1
	SND_SEGNO
	SND_CALL SndF8_Ch1_7D0A
	SND_LOOP
SndF8_Ch1_7D0A:
	TRANSPOSE_DOWN 9
	OCTAVE 5
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE C#, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE C#, 2
	NOTE A#, 2
	NOTE C#, 2
	OCTAVE 6
	NOTE C_, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE A#, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	OCTAVE 6
	NOTE C_, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE A#, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 5
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE OCT_UP, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	SND_RET

SndF8_Ch1:
	VOICE $0A, 4, 5, 14, 3
	AUTOPAN_R 0
	ENVELOPE $10
	VIBRATO $02, 1, 1
	DETUNE $01
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 2
	SND_SEGNO
	SND_CALL SndF8_Ch1_7D0A
	SND_LOOP

SndF8_Ch3:
	VOICE $0A, 2, 4, 8, 5
	VIBRATO $01, 0, 0
	SND_CALL SndF8_Ch1_7D0A
	SND_SEGNO
	LEN_UNIT $0A
	VIBRATO $01, 4, 3
	TRANSPOSE_DOWN 8
	VOLUME $02
	WAVE 6
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, $0C
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 6
	NOTE E_, 2
	NOTE F#, 4
	NOTE A_, 4
	NOTE B_, 6
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 4
	NOTE B_, 4
	NOTE F#, 6
	NOTE E_, 2
	NOTE F#, 6
	NOTE A_, 2
	NOTE B_, 6
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE E_, 2
	VIBRATO $01, 6, 2
	NOTE F#, 0
	LEN_UNIT 1
	REST $0E
	OCTAVE 4
	NOTE A_, $0D
	NOTE F#, $0D
	NOTE E_, $0E
	NOTE C_, $0D
	OCTAVE 3
	NOTE B_, $0D
	NOTE A_, $0E
	NOTE F#, $0D
	NOTE E_, $0D
	NOTE C_, $0E
	OCTAVE 2
	NOTE B_, $0D
	NOTE A_, $0D
	SND_LOOP

SndF8_Drm:
	SND_END

SndF9_Ch2:
	TEMPO $20
	VOICE $04, 8, 8, 10, 7
	VIBRATO $01, 0, 0
	SND_CALL SndF9_Ch1_7E4E
	NOTE G_, 0
	SND_CALL SndF9_Ch2_7E36
	SND_CALL SndF9_Ch2_7E40
	SND_SEGNO
	SND_CALL SndF9_Ch2_7E36
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 5
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE G_, 2
	NOTE E_, $0C
	NOTE D_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 4
	SND_CALL SndF9_Ch2_7E2E
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 6
	SND_CALL SndF9_Ch2_7E36
	OCTAVE 4
	REST 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE A_, 2
	NOTE E_, $0C
	NOTE D_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE G_, 2
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 2
	SND_CALL SndF9_Ch2_7E2E
	NOTE E_, 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 4
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE G_, 1
	NOTE A_, 1
	RELEASE $0F, 3
	OCTAVE 6
	NOTE C_, 6
	SND_LOOP
SndF9_Ch2_7E2E:
	VIBRATO $01, 4, 1
	DUTY 0
	ENVELOPE $04
	SND_RET
SndF9_Ch2_7E36:
	VOICE $05, 8, 8, 12, 6
	DUTY_STEP 4, 1
	VIBRATO $0A, 0, 15
	SND_RET
SndF9_Ch2_7E40:
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	SND_RET
SndF9_Ch1_7E4E:
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_RET

SndF9_Ch1:
	DETUNE $FF
	VOICE $04, 8, 4, 8, 7
	REST 2
	PAN_RIGHT 0
	SND_CALL SndF9_Ch1_7E4E
	NOTE G_, $0E
	VOICE $05, 0, 6, 14, 4
	DUTY_STEP 4, 2
	VIBRATO $02, 1, 1
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 1
	NOTE C_, 6
	SND_SEGNO
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE E_, 2
	ENVELOPE $12
	DUTY 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 4
	NOTE E_, 2
	ENVELOPE_OFF
	DUTY 0
	LOOP_START
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 2
	NOTE F_, 4
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE D_, 4
	PAN_RIGHT 0
	REST 2
	ATTEN 3
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 4
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE E_, 2
	ENVELOPE $12
	DUTY 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE E_, 2
	ENVELOPE_OFF
	DUTY 0
	OCTAVE 2
	NOTE A_, 6
	NOTE A_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE F_, 6
	PAN_LEFT 0
	ATTEN 3
	OCTAVE 5
	NOTE E_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 4
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 4
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE C_, 6
	REST 5
	SND_LOOP

SndF9_Ch3:
	VOICE $04, 2, 2, 5, 7
	SND_CALL SndF9_Ch1_7E4E
	NOTE G_, 0
	VOICE $05, 4, 2, 10, 6
	DETUNE $FF
	SND_CALL SndF9_Ch2_7E40
	SND_SEGNO
	LOOP_START
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 5
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE A_, 2
	LOOP_END 2
	NOTE C#, 1
	NOTE D_, 5
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 4
	OCTAVE 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 5
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE A_, 2
	NOTE D_, 1
	NOTE E_, 5
	NOTE OCT_UP, 4
	NOTE OCT_UP, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE OCT_UP, 2
	NOTE D_, 4
	NOTE OCT_UP, 2
	NOTE F_, 4
	NOTE OCT_UP, 2
	NOTE F_, 4
	NOTE OCT_UP, 2
	NOTE G_, 4
	NOTE OCT_UP, 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE C_, 6
	SND_LOOP

SndF9_Drm:
	LEN_UNIT 4
	REST 0
	REST $0B
	LEN_UNIT 5
	DRUM $0B, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 6
	DRUM 7, 6
	SND_SEGNO
	LOOP_START
	DRUM $0B, 6
	DRUM 3, 4
	DRUM 2, 2
	DRUM $0B, 6
	DRUM 4, 4
	DRUM 2, 2
	LOOP_END 3
	DRUM $0B, 6
	DRUM 3, 4
	DRUM 1, 2
	DRUM $0B, 6
	DRUM 4, 4
	DRUM 5, 2
	LOOP_START
	DRUM $0B, 6
	DRUM 3, 4
	DRUM 2, 2
	DRUM $0B, 6
	DRUM 4, 4
	DRUM 2, 2
	LOOP_END 3
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 6
	DRUM 4, 4
	DRUM 4, 2
	SND_LOOP
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
