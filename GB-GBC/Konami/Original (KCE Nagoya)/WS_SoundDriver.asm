; ==========================================================================
; Tiny Toon Adventures - Wacky Sports (E) - Konami sound driver (bank 7)
; Byte-exact RGBDS disassembly of the driver code and all sound data. Batman's driver (the Tiny Toon
; Adventures 2 line) back in one bank with the update, pause, tempo and fade, without the volume ramp,
; the key transpose or the tempo step; a fade request in place of sound $07.
;   ROM0: the VBlank check, PlaySoundFar ($01D0-$01EF), SndUpdateFar ($0A09-$0A17)
;   bank 7: the driver ($4000-$4A93), tables and headers ($4A94-$505C), drum hits ($505D-$5097),
;           PlaySound ($5098-$5181), SFX and songs ($5182-$7E14); $7E15-$7FFF is unused ($FF)
; Build: rgbasm -Wall -o ws.o WS_SoundDriver.asm && rgblink -o ws.gb ws.o
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
DEF wTrkSfx1 EQU $C180 ; 63 bytes
DEF wTrkSfx2 EQU $C280 ; 63 bytes
DEF wTrkSfxN EQU $C380 ; 63 bytes
DEF wTrkCh1 EQU $C480 ; 63 bytes
DEF wTrkCh2 EQU $C580 ; 63 bytes
DEF wTrkCh3 EQU $C680 ; 63 bytes
DEF wTrkDrm EQU $C780 ; 63 bytes
DEF wTrackDesc EQU $C1BF
DEF wC1C0 EQU $C1C0
DEF wTempo EQU $C1C1
DEF wTempoAcc EQU $C1C2
DEF wReqPrio EQU $C1C3
DEF wReqId EQU $C1C4
DEF wPauseLast EQU $C1C5
DEF wFadeRate EQU $C1C6
DEF wFadeTimer EQU $C1C7
DEF wFadeStep EQU $C1C8
DEF wWaveId EQU $C1C9
DEF wC1CA EQU $C1CA
DEF wMasterVol EQU $C1CC
DEF wRomBank EQU $C002
DEF wSndBusy EQU $C004
DEF wPauseFlag EQU $C011
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

; wTrackDesc: Sfx1 $40, Sfx2 $52, SfxN $63, Ch1 $00, Ch2 $11, Ch3 $22, Drm $34 (low nibble = channel)
; TRK_FLAGS: 0 rest, 1 (cleared at the end of Sfx1/Sfx2, never tested), 2 retrigger a long note,
;   4 tempo skip, 5 reload the duty/wave
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, 7 autopan with
;   both sides
; TRK_FLOW: 0/1 loops open, 2 in a call, 3 mark set, 4 vibrato loop, 5 vibrato mark
; TRK_FLAGS3: 0 Sfx1/Sfx2 high nibble next, 2 noise retrigger pending, 5 set by OCTAVE 6 (never read)

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
; pan (both sides / NR51 high nibble / low nibble); y is ignored
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
; $EA 6y: NR50 = $6y (as MASTER_VOL)
MACRO MASTER_VOL6
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
; $EC x: NR50 = x and wMasterVol = x; NR51 = $DD for x = $66, else $FF
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

SECTION "SndUpdateGlue", ROM0[$008C]

; SndUpdateGlue (in the VBlank handler, after `ei`): SndUpdateFar unless wSndBusy bit 0 or 1
; is set (an update or a request is running).
SndUpdateGlue:
	ld hl, wSndBusy
	ld a, [hl]
	and $03
	jr nz, .l009E
	set 0, [hl]
	call SndUpdateFar
	ld hl, wSndBusy
	res 0, [hl]
.l009E:
	ret

SECTION "PlaySoundFar", ROM0[$01D0]

; PlaySoundFar: wSndBusy bit 1, wReqId = A, map bank 7, PlaySound, map wRomBank again.
PlaySoundFar:
	push hl
	ld hl, wSndBusy
	set 1, [hl]
	ld [wReqId], a
	push af
	ld a, $07
	ld [rROMB], a
	call PlaySound
	ld a, [wRomBank]
	ld [rROMB], a
	pop af
	ld hl, wSndBusy
	res 1, [hl]
	pop hl
	ret

SECTION "SndUpdateFar", ROM0[$0A09]

; SndUpdateFar: map bank 7, SndUpdate, map wRomBank again.
SndUpdateFar:
	ld a, $07
	ld [rROMB], a
	call SndUpdate
	ld a, [wRomBank]
	ld [rROMB], a
	ret

SECTION "Sound bank 7", ROMX[$4000], BANK[7]

; SndUpdate: on a change of wPauseFlag (the game's) pause or unpause. Not paused: FadeTick,
; TempoTick (only while wTempo is not 0), Ch1, Ch2, Ch3, Drm. Then SfxN, Sfx2, Sfx1 (also
; while paused). RunTrack sets wTrackDesc and runs a playing track.
SndUpdate:
	ld a, [wPauseFlag]
	ld hl, wPauseLast
	cp [hl]
	jp z, UpdateTracks
	ld [hl], a
	or a
	call PauseEdge

UpdateTracks:
	ld a, [wPauseFlag]
	or a
	jp nz, UpdateSfx
	call FadeTick
	ld a, [wTempo]
	or a
	call nz, TempoTick
	ld hl, wTrkCh1 + $01
	xor a
	call RunTrack
	ld hl, wTrkCh2 + $01
	ld a, $11
	call RunTrack
	ld hl, wTrkCh3 + $01
	ld a, $22
	call RunTrack
	ld hl, wTrkDrm + $01
	ld a, $34
	call RunTrack

UpdateSfx:
	ld hl, wTrkSfxN + $01
	ld a, $63
	call RunTrack
	ld hl, wTrkSfx2 + $01
	ld a, $52
	call RunTrack
	ld hl, wTrkSfx1 + $01
	ld a, $40

RunTrack:
	ld [wTrackDesc], a
	ld a, [hl]
	or a
	ret z
	jp TrackTick

; PauseEdge (Z = unpaused). Pause: stop SfxN, mute CH4 and CH2. Unpause: stop Sfx1 and
; Sfx2, mute CH1, NR32 = 0, give CH1 and CH3 back to the music (NR51 bits and period, no
; trigger) and mark Ch1-Ch3 for a retrigger of a long note (Ch1/Ch3 also reload the duty).
; Batman's code, back in bank 7.
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
	ld hl, wTempoAcc
	add a, [hl]
	ld [hl], a
	ld hl, wTrkCh1 + $05
	jp c, .l40EE
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l40EE:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: wFadeRate 0: NR50 = wMasterVol on every update. $FF: nothing. Else every
; wFadeRate updates NR50 goes down by $11; at $11 it stays there and wFadeStep goes up by $10
; instead: $10 stops Drm, $20 Ch1 (CH1 muted unless Sfx1 plays), $30 Ch2 (CH2 muted), $40
; Ch3 (NR30/NR32 = 0 unless Sfx2 plays) and ends the fade (rate, timer, step 0), after which
; NR50 is set back to wMasterVol. Request $07 starts it with rate 8.
FadeTick:
	ld a, [wFadeRate]
	or a
	jr nz, .l4107
	ld c, $24
	ld a, [wMasterVol]
	ldh [c], a
	ret
.l4107:
	cp $FF
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld c, $24
	ldh a, [c]
	sub $11
	jr z, .l411B
	ldh [c], a
	ret
.l411B:
	ld a, [wFadeStep]
	add a, $10
	ld [wFadeStep], a
	cp $20
	jr z, FadeStopCh1
	cp $30
	jr z, FadeStopCh2
	cp $10
	jr z, FadeStopDrm
	cp $40
	ret nz
	xor a
	ld hl, wTrkCh3 + $01
	ld [hl-], a
	ld [hl], a
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld a, [wTrkSfx2 + $01]
	or a
	ret nz
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
	ret

FadeStopCh1:
	ld hl, wTrkCh1 + $01
	xor a
	ld [hl-], a
	ld [hl+], a
	ld a, [wTrkSfx1 + $01]
	or a
	ret nz
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
	ret

FadeStopCh2:
	ld hl, wTrkCh2 + $01
	xor a
	ld [hl-], a
	ld [hl], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ret

FadeStopDrm:
	ld hl, wTrkDrm + $01
	xor a
	ld [hl-], a
	ld [hl], a
	ret

; TrackTick: tempo skip; a pending reload of the duty; LEN - 1; at 0 read commands, else
; Sustain.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jr z, .l418C
	res 5, [hl]
	ld l, TRK_LASTDUTY
	ld a, [hl]
	call WriteDuty
.l418C:
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

; ReadCmds: $E0-$FF commands. SfxN: NoiseNote. Sfx1/Sfx2: two notes per byte (as Batman).
; Music: hi = pitch, lo x unit (0: (unit & 15) x 16).
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
	jr z, .l41BC
	res 0, [hl]
	dec de
	call NextCmd
.l41B7:
	ld l, TRK_UNIT
	ld a, [hl]
	jr NoteLen
.l41BC:
	set 0, [hl]
	ld a, [de]
	and $0F
	cp $0E
	jr c, .l41D1
	inc de
	ld a, [de]
	jr z, .l41CC
	jp Command
.l41CC:
	ld l, TRK_UNIT
	ld [hl], a
	jr NextByte
.l41D1:
	call NextCmd
	dec de
	jr .l41B7

MusicNote:
	ld l, TRK_FLAGS
	res 2, [hl]
	call NextCmd
	dec de
	ld a, [de]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jr z, .l41F6
	ld b, a
	xor a
	bit 0, b
	jr nz, .l41FD
	rrc b
.l41EF:
	add a, c
	dec b
	jr nz, .l41EF
	add a, a
	jr NoteLen
.l41F6:
	swap c
	ld a, c
	and $F0
	jr NoteLen
.l41FD:
	add a, c
	dec b
	jr nz, .l41FD

; NoteLen: LEN = A. A rest mutes (NRx2 = 8); a drum-track rest returns.
NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l420E
	swap a
.l420E:
	ld l, TRK_FLAGS
	and $F0
	ld a, [wTrackDesc]
	jr nz, Note
	set 0, [hl]
	cp $34
	ret z
	ld a, $08
	jp WriteVolume

; Note: release tick = length x gate / 16. A duty step writes its start duty. Autopan.
; Pitch 13 = the last pitch + an octave. Period from PeriodTable - 26 + 2 x pitch + octave +
; transpose, + detune. Vibrato restarts. NRx2 = TRK_VOL - TRK_ATTEN through WriteVolume.
Note:
	res 0, [hl]
	cp $34
	jp z, DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jr z, .l4240
	ld e, a
	ld b, $00
	ld hl, $0000
.l4236:
	add hl, bc
	dec e
	jr nz, .l4236
	ld a, l
	and $F0
	or h
	swap a
.l4240:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jr z, .l4250
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l4250:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l4260
	swap a
.l4260:
	and $F0
	cp $D0
	jr nz, .l4271
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, TRK_LASTPITCH
	ld a, [hl]
	jr .l427A
.l4271:
	swap a
	rlca
	ld l, TRK_LASTPITCH
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l427A:
	add a, c
	ld l, TRK_TRANSP
	add a, [hl]
	ld c, a
	ld b, $00
	ld l, TRK_PITCHIDX
	ld [hl], a
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	push hl
	ld hl, PeriodTable - 26
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
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
	jr z, .l42C5
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jr nc, .l42AF
	set 4, [hl]
	jr .l42B1
.l42AF:
	res 4, [hl]
.l42B1:
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
.l42C5:
	call WritePeriod
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	jp WriteVolume

; Sustain (not SfxN, Drm, rests): duty step countdown, vibrato (after its delay), then
; the release: NRx2 = TRK_RELVOL, or env | level + trigger (env 0: 8); CH3 steps NR32
; down every env ticks. A pending long-note retrigger rewrites NRx2 at any tick but the
; release tick.
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
	jr z, .l42EE
	dec [hl]
	jr nz, .l42EE
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l42EE:
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
	jr z, .l4306
	dec [hl]
	jp ReleaseTick
.l4306:
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
	jr z, .l436E
	cp $FE
	jp z, .l43A4
	cp $FB
	jr z, .l437A
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
	jr z, .l4368
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jr nz, VibratoSemitone
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jr z, .l4352
	and $07
	jr z, .l4368
	cpl
	inc a
	ld e, a
	ld d, $FF
.l4352:
	ld a, [hl]
	or a
	jr z, .l435D
	ld b, a
	xor a
.l4358:
	add a, e
	dec b
	jr nz, .l4358
	ld e, a
.l435D:
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
.l4368:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l436E:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	res 4, [hl]
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l437A:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jr nz, .l438D
	set 4, [hl]
	ld l, TRK_VIBLOOP
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jr VibratoStep
.l438D:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l439A
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jr VibratoStep
.l439A:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l43A4:
	ld l, TRK_FLOW
	bit 5, [hl]
	jr nz, .l43B5
	set 5, [hl]
	inc bc
	ld l, TRK_VIBMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l43B5:
	ld l, TRK_VIBMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l43CE
	sub $0D
	jr z, .l43CC
	dec a
	jr z, .l43CA
	add a, $0B
.l43CA:
	add a, $05
.l43CC:
	add a, $13
.l43CE:
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
	jr z, ReleaseCh3
	cp [hl]
	jr z, .l440A
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l440A:
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
	jr c, .l4451
	jr z, .l4445
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4445:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl+]
	ld [hl], a
	ret
.l4451:
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
	and $60
	ret z
	add a, $20
	cp $A0
	ret nc
	jp WriteVolume

; DrumNote: the drum hit id = the note's high nibble, read from SoundTable like any sound
; (ids 1-6 are the drum headers), started on the SFX tracks of its header, each with its own
; priority test.
DrumNote:
	ld a, [de]
	and $F0
	swap a
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
	jr c, .l44DD
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
	jr nz, .l44CC
	ld a, $08
	ld c, $10
	ldh [c], a
.l44CC:
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
.l44DD:
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
	jr nz, .l44F7
	ld l, TRK_FLAGS3
	set 2, [hl]
	jp ReadCmds
.l44F7:
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
	jr nz, .l450F
	ld a, [hl]
	ld l, TRK_FLAGS3
	jp VoiceNoise.l45CC
.l450F:
	ld a, b
	and $0F
	ld l, TRK_LASTVOL
	ld a, [hl]
	jr nz, NoiseTrigger
	ld a, $08
	jr NoiseTrigger

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

; CommandTable: $E7-$FF (the code indexes it from CommandTable - 14 by $E0-$FF).
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

; Command: $E0 voice, $E1-$E6 octave (OctaveCodes; $E6 also sets TRK_FLAGS3 bit 5, which
; nothing reads), $E7-$FF through CommandTable.
Command:
	inc de
	sub $E0
	jr z, Cmd_Voice
	cp $07
	jr c, Cmd_OctaveFlag
	push hl
	ld hl, CommandTable - 14
	call LoadPtrIndexed
	ld a, [de]
	jp hl

; Cmd_Voice: unit = u & $7F. Tone/wave: duty, vol, gate, env, autopan off, attenuation 0,
; release volume 0, both sides; Sfx1/Sfx2 also set TRK_FLAGS3 bit 0 (high nibble next).
; SfxN: NR42 = swap(v) at the next noise note.
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
	jr z, .l4597
	set 0, [hl]
.l4597:
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
.l45CC:
	set 2, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	jp ReadCmds

Cmd_OctaveFlag:
	ld l, TRK_FLAGS3
	res 5, [hl]
	cp $06
	jr c, Cmd_Octave
	set 5, [hl]

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

; Cmd_Ext: $EA xy through ExtTable (11 entries; $EA Bx-$EA Fx would jump through the code
; that follows).
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
	dw Cmd_MasterVol
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_ReleaseVol
	dw Ext_Clear

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
	jp NextByte

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l4661
.l465C:
	sla b
	dec a
	jr nz, .l465C
.l4661:
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
	push hl
	pop hl
	jp NextByte

Ext_PanRight:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanRight
	jp NextByte

AutoPan:
	bit 7, [hl]
	jr nz, .l468F
	bit 1, [hl]
	jr nz, AutoPanLeft
	set 1, [hl]
	jr PanRight
.l468F:
	bit 1, [hl]
	jr z, .l4697
	res 1, [hl]
	jr PanBoth
.l4697:
	set 1, [hl]

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l46AC
.l46A5:
	rlc b
	rlc l
	dec a
	jr nz, .l46A5
.l46AC:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked

AutoPanLeft:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l46CD
.l46C6:
	rlc b
	rlc l
	dec a
	jr nz, .l46C6
.l46CD:
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
	ld l, TRK_PANFLAGS
	set 0, [hl]
	res 1, [hl]
	res 2, [hl]
	jp NextByte

Ext_AutopanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 7, [hl]
	set 1, [hl]
	jp NextByte

Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
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
	jr z, .l4722
	ld l, TRK_VIB
	ld [hl], a
.l4722:
	bit 2, b
	jr z, .l472B
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld [hl-], a
	ld [hl], a
.l472B:
	bit 1, b
	jr z, .l4733
	ld l, TRK_DETUNE
	ld [hl+], a
	ld [hl], a
.l4733:
	bit 0, b
	jp z, ReadCmds
	ld l, TRK_ATTEN
	ld [hl], a
	jp ReadCmds

; Cmd_Vibrato: $EB 0 off; $EB n | $80 semitone table n; $EB n xy table n, delay x * unit,
; depth y.
Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jr z, .l4780
	bit 7, [hl]
	jr nz, .l4783
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
	jr z, .l4778
	ld b, a
	xor a
	bit 0, b
	jr nz, .l4774
	rrc b
.l476D:
	add a, c
	dec b
	jr nz, .l476D
	add a, a
	jr .l4778
.l4774:
	add a, c
	dec b
	jr nz, .l4774
.l4778:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [de]
	and $0F
	inc l
	ld [hl], a
.l4780:
	jp NextByte
.l4783:
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

; Cmd_MasterVol ($EC x, and $EA 6y with x = $6y): NR50 = wMasterVol = x; NR51 = $DD for
; $66, else $FF.
Cmd_MasterVol:
	pop hl
	ld c, $24
	ldh [c], a
	inc c
	ld [wMasterVol], a
	cp $66
	jr nz, .l47AD
	ld a, $DD
	ldh [c], a
	jp NextByte
.l47AD:
	ld a, $FF
	ldh [c], a
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
	jr z, .l47DF
	ld a, $FF
.l47DF:
	ld [hl], a
	jp NextByte

Cmd_Atten:
	pop hl
	dec de
	ld a, [de]

; SetAtten: TRK_ATTEN = y << 4 (CH3: cpl(rlc(y << 4))).
SetAtten:
	and $0F
	swap a
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l47F7
	rlca
	cpl
.l47F7:
	ld l, TRK_ATTEN
	ld [hl], a
	jp NextByte

; Cmd_Volume: TRK_VOL = swap(x), TRK_ATTEN = 0.
Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	ld b, a
	ld a, [wTrackDesc]
	cp $63
	jr nz, .l480C
	ld a, b
.l480C:
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
	jr z, .l481F
	inc de
	jp NextByte
.l481F:
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
	jr nz, .l4847
	set 0, [hl]
	ld l, TRK_LOOP1
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l4847:
	ld l, TRK_LOOP1CNT
	inc [hl]
	cp [hl]
	jr z, .l4854
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l4854:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jp NextByte

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jr nz, .l4871
	set 1, [hl]
	ld l, TRK_LOOP2
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l4871:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l487E
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l487E:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jp NextByte

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jr nz, .l489E
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
.l489E:
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
	jr nz, .l48B9
	set 3, [hl]
	ld l, TRK_MARK
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l48B9:
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
	jr z, .l48EF
	cp $40
	jr z, .l48D8
	jp MuteChannel
.l48D8:
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
.l48EF:
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

GiveBack:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jr z, .l4928
.l4923:
	rlc b
	dec a
	jr nz, .l4923
.l4928:
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

DeadSavePtr:
	call NextCmd ; unreachable

WriteVolume8:
	ld a, $08

; WriteVolume: TRK_LASTVOL = A; NRx2 is only written (and triggered, not on CH3) when it
; reads back differently - on CH1 also while NR10 does not read 8.
WriteVolume:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jr nz, .l496D
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
.l496D:
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

; WriteDuty: NRx1 = A. CH3: the wave (high nibble) if it is not the one loaded (wWaveId);
; music Ch3 only keeps it while Sfx2 plays.
WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jr z, .l4997
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jr WriteRegChecked
.l4997:
	ld a, [wTrackDesc]
	cp $22
	jr nz, .l49AA
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_LASTDUTY
	ld [hl], b
	ret nz
.l49AA:
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
.l49C8:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .l49C8
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

MuteChannel:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jr z, .l49FB
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
.l49FB:
	xor a
	ld c, $1C

; WriteRegChecked: [C] = A unless music Ch1 while Sfx1 plays or music Ch3 while Sfx2 plays.
; Carry = written.
WriteRegChecked:
	ld b, a
	ld a, [wTrackDesc]
	cp $00
	jr z, .l4A0F
	cp $22
	jr nz, .l4A18
	push hl
	ld h, HIGH(wTrkSfx2)
	jr .l4A12
.l4A0F:
	push hl
	ld h, HIGH(wTrkSfx1)
.l4A12:
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
.l4A18:
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

; SndInit (from the boot code): wMasterVol = $77 and the register addresses TRK_REG_NRX1-4 of
; all seven tracks (the drum track too, Batman left it 0).
SndInit:
	ld a, $77
	ld [wMasterVol], a
	ld h, HIGH(wTrkSfx1)
	ld a, $11
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
	call SetRegAddrs
	ld a, $20

SetRegAddrs:
	ld l, TRK_REG_NRX1
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc h
	ret

; SoundTable: ids $01-$71 (the code adds 2 * id to SoundTable - 2, the last two code bytes).
; Drum notes use it too: hi nibble 1-6 are the drum headers.
SoundTable:
	dw SndHdr01 ; $01 (also drum hit)
	dw SndHdr02 ; $02 (also drum hit)
	dw SndHdr03 ; $03 (also drum hit)
	dw SndHdr04 ; $04 (also drum hit)
	dw SndHdr05 ; $05 (also drum hit)
	dw SndHdr06 ; $06 (also drum hit)
	dw SndHdr07 ; $07 (never played: request 7 starts the fade)
	dw SndHdr08 ; $08 (also drum hit)
	dw SndHdr09 ; $09 (also drum hit)
	dw SndHdr0A ; $0A (also drum hit)
	dw SndHdr0B ; $0B (also drum hit)
	dw SndHdr0C ; $0C (also drum hit)
	dw SndHdr0D ; $0D (also drum hit)
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
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $FE, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd07_SfxN
	dw Snd07_SfxN
	dw Snd07_SfxN

SndHdr09:
	SND_HEADER $73, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd07_SfxN
	dw Snd07_SfxN
	dw Snd07_SfxN

SndHdr0A:
	SND_HEADER $FF, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0A_Sfx1
	dw Snd07_SfxN
	dw Snd07_SfxN

SndHdr0B:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd0B_Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $F0, $03 ; tracks: Sfx1, Sfx2
	dw Snd0C_Sfx1
	dw Snd0C_Sfx2

SndHdr0D:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd13_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd0F_Sfx1
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd1E_Sfx1
	dw Snd1E_SfxN

SndHdr1F:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd1F_Sfx1
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $F0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd21_Sfx1
	dw Snd21_Sfx2
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd10_Sfx1
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd25_Sfx1

SndHdr26:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd27_SfxN

SndHdr28:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd2A_Sfx1
	dw Snd2A_SfxN

SndHdr2D:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd2D_Sfx1
	dw Snd2D_SfxN

SndHdr2B:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2E:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd2E_Sfx1
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd2F_Sfx1
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd30_Sfx1
	dw Snd30_SfxN

SndHdr31:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd31_SfxN

SndHdr32:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd36_Sfx1

SndHdr37:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd37_Sfx1

SndHdr38:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr39:
	SND_HEADER $D0, $01 ; tracks: Sfx1
	dw Snd39_Sfx1

SndHdr3A:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd3B_Sfx1

SndHdr3C:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd3C_Sfx1

SndHdr3D:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd43_Sfx1
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd44_Sfx1
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd45_Sfx1

SndHdr46:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd46_SfxN

SndHdr47:
	SND_HEADER $F0, $04 ; tracks: SfxN
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd48_Sfx1

SndHdr49:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd49_Sfx1
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $D0, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $F0, $05 ; tracks: Sfx1, SfxN
	dw Snd4B_Sfx1
	dw Snd4B_SfxN

SndHdr4C:
	SND_HEADER $D0, $01 ; tracks: Sfx1
	dw Snd4C_Sfx1

SndHdr4D:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd4D_Sfx1

SndHdr4E:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd4E_Sfx1

SndHdr4F:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd4F_Sfx1

SndHdr50:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd50_Sfx1

SndHdr51:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd52_Sfx1

SndHdr53:
	SND_HEADER $E0, $04 ; tracks: SfxN
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd54_Sfx1
	dw Snd53_SfxN

SndHdr55:
	SND_HEADER $E0, $04 ; tracks: SfxN
	dw Snd55_SfxN

SndHdr56:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd56_Sfx1

SndHdr57:
	SND_HEADER $E0, $01 ; tracks: Sfx1
	dw Snd57_Sfx1

SndHdr58:
	SND_HEADER $F0, $03 ; tracks: Sfx1, Sfx2
	dw Snd58_Sfx1
	dw Snd58_Sfx2

SndHdr59:
	SND_HEADER $B0, $01 ; tracks: Sfx1
	dw Snd59_Sfx1

SndHdr5A:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd5A_Sfx1
	dw Snd5A_SfxN

SndHdr5B:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd5B_Sfx1
	dw Snd5A_SfxN

SndHdr5C:
	SND_HEADER $D0, $01 ; tracks: Sfx1
	dw Snd5C_Sfx1

SndHdr5D:
	SND_HEADER $F0, $03 ; tracks: Sfx1, Sfx2
	dw Snd5D_Sfx1
	dw Snd5D_Sfx2

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

SndHdr64:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd64_Ch1
	dw Snd64_Ch2
	dw Snd64_Ch3
	dw Snd64_Drm

SndHdr65:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd65_Ch1
	dw Snd65_Ch2
	dw Snd65_Ch3
	dw Snd65_Drm

SndHdr66:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd66_Ch1
	dw Snd66_Ch2
	dw Snd66_Ch3
	dw Snd66_Drm

SndHdr67:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd67_Ch1
	dw Snd67_Ch2
	dw Snd67_Ch3
	dw Snd67_Drm

SndHdr68:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd68_Ch1
	dw Snd68_Ch2
	dw Snd68_Ch3
	dw Snd68_Drm

SndHdr69:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd69_Ch1
	dw Snd69_Ch2
	dw Snd69_Ch3
	dw Snd69_Drm

SndHdr6A:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6A_Ch1
	dw Snd6A_Ch2
	dw Snd6A_Ch3
	dw Snd6A_Drm

SndHdr6B:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6B_Ch1
	dw Snd6B_Ch2
	dw Snd6B_Ch3
	dw Snd6B_Drm

SndHdr6C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6C_Ch1
	dw Snd6C_Ch2
	dw Snd6C_Ch3
	dw Snd6C_Drm

SndHdr6D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6D_Ch1
	dw Snd6D_Ch2
	dw Snd6D_Ch3
	dw Snd6D_Drm

SndHdr6E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6E_Ch1
	dw Snd6E_Ch2
	dw Snd6E_Ch3
	dw Snd6E_Drm

SndHdr6F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6F_Ch1
	dw Snd6F_Ch2
	dw Snd6F_Ch3
	dw Snd6F_Drm

SndHdr70:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd70_Ch1
	dw Snd70_Ch2
	dw Snd70_Ch3
	dw Snd70_Drm

SndHdr71:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd71_Ch1
	dw Snd71_Ch2
	dw Snd71_Ch3
	dw Snd71_Drm

; WaveTable: 15 pointers (wave n = the high nibble of the duty byte; from WaveTable - 2, the
; last pointer of the last header), 10 distinct waves.
WaveTable:
	dw Wave_4E14 ; wave 1
	dw Wave_4E24 ; wave 2
	dw Wave_4E34 ; wave 3
	dw Wave_4E44 ; wave 4
	dw Wave_4E54 ; wave 5
	dw Wave_4E64 ; wave 6
	dw Wave_4E74 ; wave 7
	dw Wave_4E84 ; wave 8
	dw Wave_4E94 ; wave 9
	dw Wave_4EA4 ; wave 10
	dw Wave_4EA4 ; wave 11
	dw Wave_4EA4 ; wave 12
	dw Wave_4EA4 ; wave 13
	dw Wave_4EA4 ; wave 14
	dw Wave_4EA4 ; wave 15
Wave_4E14:
	db $12, $34, $56, $FF, $FF, $99, $55, $00, $00, $00, $22, $00, $00, $00, $00, $00
Wave_4E24:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
Wave_4E34:
	db $44, $44, $00, $00, $44, $44, $00, $00, $44, $44, $00, $00, $44, $44, $00, $00
Wave_4E44:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave_4E54:
	db $88, $88, $88, $88, $77, $66, $55, $44, $00, $00, $00, $00, $00, $F0, $00, $00
Wave_4E64:
	db $60, $11, $00, $00, $00, $00, $00, $00, $60, $11, $00, $00, $00, $00, $00, $00
Wave_4E74:
	db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $BB, $BB, $BB, $AA
Wave_4E84:
	db $08, $34, $67, $89, $A9, $87, $65, $31, $02, $34, $67, $89, $A9, $87, $65, $31
Wave_4E94:
	db $77, $77, $00, $00, $00, $00, $00, $00, $77, $77, $00, $00, $00, $00, $00, $00
Wave_4EA4:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00

; PeriodTable: 85 periods. Notes index it from PeriodTable - 26 by 2 * pitch +
; TRK_OCTAVE + TRK_TRANSP.
PeriodTable:
	dw $02D, $09D, $108, $16C, $1CB, $224, $278, $2C7, $312, $359, $39C, $3DB ; octave index 0
	dw $417, $44F, $484, $4B6, $4E5, $512, $53C, $564, $589, $5AD, $5CE, $5EE ; octave index 1
	dw $60B, $627, $642, $65B, $673, $689, $69E, $6B2, $6C5, $6D6, $6E7, $6F7 ; octave index 2
	dw $706, $714, $721, $72E, $739, $744, $74F, $759, $762, $76B, $774, $77B ; octave index 3
	dw $783, $78A, $791, $797, $79D, $7A2, $7A8, $7AD, $7B1, $7B6, $7BA, $7BE ; octave index 4
	dw $7C1, $7C5, $7C8, $7CB, $7CE, $7D1, $7D4, $7D6, $7D9, $7DB, $7DD, $7DF ; octave index 5
	dw $7E1, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; VibratoTable: 15 pointers (EB n uses entry n; the code adds from VibratoTable - 2).
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

Vib01:
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib02:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 1
	VIB_STEP 5, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib03:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib04:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib05:
	VIB_STEP 2, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib06:
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib07:
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib08:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 7, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib09:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 3
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 3
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib0A:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 15, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 9, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib0B:
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib0C:
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 7
	VIB_END

Vib0D:
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 1, 2
	VIB_MARK

Vib0E:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib0F:
	VIB_STEP 1, 1, 1
	VIB_STEP 5, 0, 1
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_MARK

; Vibrato2Table: 8 semitone-step tables (EB n | $80; from Vibrato2Table - 2).
Vibrato2Table:
	dw VibSemi01 ; 1 (EB 1 | $80)
	dw VibSemi02 ; 2 (EB 2 | $80)
	dw VibSemi03 ; 3 (EB 3 | $80)
	dw VibSemi04 ; 4 (EB 4 | $80)
	dw VibSemi05 ; 5 (EB 5 | $80)
	dw VibSemi06 ; 6 (EB 6 | $80)
	dw VibSemi07 ; 7 (EB 7 | $80)
	dw VibSemi08 ; 8 (EB 8 | $80)
VibSemi01:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi02:
	VIB_MARK
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 3, 0
	VIB_MARK
VibSemi03:
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi04:
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi05:
	VIB_MARK
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, 7
	VIB_MARK
VibSemi06:
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi07:
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_MARK
VibSemi08:
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_END

Snd01_SfxN:
	NVOICE $81, $05
	NOISE $1F
	NOISE_VOL 5
	NOISE $21
	NOISE_VOL 2
	NOISE $20
	SND_END

Snd02_SfxN:
	NVOICE $81, $04
	NOISE $14
	NOISE_VOL 2
	NOISE $20
	NOISE $10
	SND_END

Snd03_SfxN:
	NVOICE $82, $17
	NOISE $15
	NVOICE $90, $73
	NOISE $14
	SND_END

Snd04_SfxN:
	NVOICE $81, $0F
	NOISE $35
	NOISE $26
	NVOICE $83, $26
	NOISE $26
	LEN_UNIT $01
	NOISE $34
	SND_END

Snd05_SfxN:
	NVOICE $81, $08
	NOISE $35
	NOISE $26
	NVOICE $83, $43
	NOISE $26
	LEN_UNIT $01
	NOISE $34
	SND_END

Snd06_SfxN:
	NVOICE $81, $0A
	NOISE $36
	NOISE $57
	SND_END
	db $FF ; unused

; PlaySound (id in wReqId): 7 starts the fade (wFadeRate = 8); 0 StopAll. Header: priority,
; mask, pointers. If any SFX track of the mask holds a higher priority the mask is cleared
; and nothing starts. SFX tracks start without tests (SfxN also NR51 |= $88). Music needs
; the Ch1 bit and a priority >= Ch1's: it resets tempo and fade, NR10 = 8, and starts
; Ch1-Ch3/Drm. A started track: LEN 1, $85-$8F = 0, wWaveId = 0, TRK_FLAGS3/TRK_RELVOL = 0,
; NRx2 = 0.
PlaySound:
	push de
	push bc
	call PlaySoundA
	pop bc
	pop de
	ret

PlaySoundA:
	ld a, [wReqId]
	cp $07
	jr nz, PlaySoundGo
	ld a, $08
	ld [wFadeRate], a
	ret

PlaySoundGo:
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
	ld [wC1CA], a
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
	ld [wC1C0], a
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
	jp nz, .l5171
	ld a, $08
	ld c, $10
	ldh [c], a
.l5171:
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

Snd07_SfxN:
	SND_END

Snd0A_Sfx1:
	MASTER_VOL $77
	SND_END

Snd0B_Sfx1:
	SND_END

Snd5D_Sfx1:
	VOICE $06, 12, 8, 15, 1
	OCTAVE 4
	NOTES 1, 5
	NOTES 8, 5
	NOTE_CMD 8
	OCTAVE 5
	NOTE_CMD 1
	SND_END

Snd5D_Sfx2:
	VOICE $06, 12, 5, 15, 1
	DETUNE $03
	OCTAVE 4
	NOTES 1, 5
	NOTES 8, 5
	NOTE_CMD 8
	OCTAVE 5
	NOTE_CMD 1
	SND_END

Snd0C_Sfx1:
	VOICE $03, 4, 11, 15, 1
	OCTAVE 5
	NOTES 1, 3
	NOTES 5, 6
	NOTES 8, $0A
	NOTE_CMD $0C
	OCTAVE 6
	NOTE_CMD 1
	ATTEN 7
	OCTAVE 5
	NOTES 5, 6
	NOTES 8, $0A
	ATTEN 7
	NOTE_CMD $0C
	OCTAVE 6
	NOTE_CMD 1
	SND_END

Snd0C_Sfx2:
	VOICE $03, 4, 6, 0, 0
	NOTES 0, 0
	OCTAVE 5
	NOTES 1, 3
	NOTES 5, 6
	NOTES 8, $0A
	NOTE_CMD $0C
	OCTAVE 6
	NOTE_CMD 1
	SND_END

Snd0D_Sfx1:
	VOICE $02, 0, 8, 0, 0
	OCTAVE 6
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 4
	OCTAVE 6
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	VOLUME $06
	OCTAVE 6
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 3
	OCTAVE 6
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 4
	LOOP_START
	OCTAVE 6
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	LOOP_END 2
	SND_END

Snd0E_Sfx1:
	VOICE $04, 8, 9, 0, 0
	OCTAVE 5
	NOTES 1, 5
	NOTES 8, $0D
	ATTEN 6
	NOTES 1, 5
	NOTES 8, $0D
	VOLUME $01
	NOTES 1, 5
	NOTES 8, $0D
	SND_END

Snd0F_Sfx1:
	VOICE $01, 8, 7, 0, 0
	OCTAVE 6
	NOTES 6, 4
	NOTES 6, 0
	NOTES 0, 0
	LOOP_START
	NOTES 6, 4
	LOOP_END 9
	ATTEN 6
	LOOP_START
	NOTES 6, 4
	LOOP_END 5
	SND_END

Snd10_Sfx1:
	VOICE $01, 8, 7, 0, 0
	OCTAVE 6
	NOTES 6, 4
	NOTES 6, 4
	NOTES 6, 4
	ATTEN 6
	NOTES 6, 4
	NOTES 6, 4
	NOTES 6, 4
	SND_END

Snd11_Sfx1:
	VOICE $04, 4, 8, 0, 8
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTES 5, 3
	NOTE_CMD 1
	ATTEN 6
	NOTES 5, 3
	NOTE_CMD 1
	SND_END

Snd12_SfxN:
	NVOICE $02, $B1
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $44
	NOISE $36
	NOISE $37
	NOISE $44
	NOISE $37
	NOISE $45
	NVOICE $04, $89
	LOOP_START
	NOISE $46
	LEN_UNIT $02
	NOISE $47
	NOISE $46
	NOISE $47
	NOISE $46
	LEN_UNIT $04
	NOISE $47
	LOOP_END 5
	NVOICE $82, $79
	LOOP_START
	NOISE $46
	NOISE $47
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $47
	NOISE $46
	NOISE $47
	LOOP_END 5
	SND_END

Snd13_Sfx1:
	VOICE $08, 0, 6, 8, 8
	NOTES 0, 0
	LEN_UNIT $01
	OCTAVE 6
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 0
	NOTES 4, 5
	NOTES 6, 7
	NOTES 8, 9
	NOTES $0A, 0
	ATTEN 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 0
	NOTES 4, 5
	NOTES 6, 7
	NOTES 8, 9
	NOTES $0A, 0
	ATTEN 5
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 0
	NOTES 4, 5
	NOTES 6, 7
	NOTES 8, 9
	NOTES $0A, 0
	SND_END

Snd13_SfxN:
	NVOICE $01, $F1
	SND_JUMP Snd12_SfxN

Snd14_SfxN:
	NVOICE $11, $F1
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	SND_JUMP Snd12_SfxN

Snd18_Sfx1:
	VOICE $02, 0, 7, 0, 8
	OCTAVE 5
	NOTES 5, 1
	ATTEN 1
	NOTES 5, 1
	ATTEN 2
	NOTES 5, 1
	ATTEN 3
	NOTES 1, 5
	ATTEN 4
	NOTES 1, 5
	SND_END

Snd22_Sfx1:
	VOICE $04, 8, 9, 15, 2
	OCTAVE 4
	NOTES $0A, 6
	OCTAVE 5
	NOTE_CMD 1
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 1
	OCTAVE 5
	NOTES 6, 1
	NOTE_CMD $0A
	VOLUME $03
	NOTES 6, 1
	NOTES $0A, 6
	ATTEN 1
	NOTES 6, 1
	ATTEN 2
	NOTES $0A, 6
	SND_END

Snd15_Sfx1:
	VOICE $04, 8, 8, 15, 1
	TRANSPOSE_DOWN 2
	DETUNE $02
	OCTAVE 3
	NOTES 8, $0A
	NOTE_CMD $0C
	OCTAVE 4
	NOTES 3, 6
	NOTES 8, $0A
	NOTE_CMD $0C
	OCTAVE 5
	NOTES 3, 6
	NOTE_CMD 8
	ATTEN 6
	RELEASE 8, 1
	OCTAVE 4
	NOTE_CMD $0C
	OCTAVE 5
	NOTES 3, 6
	NOTE_CMD 8
	SND_END

Snd16_Sfx1:
	VOICE $03, 12, 8, 15, 1
	TRANSPOSE_UP $0A
	DETUNE $02
	OCTAVE 3
	NOTES 5, 1
	NOTES 6, 3
	NOTES 8, 5
	NOTES $0A, 6
	NOTES $0C, 8
	OCTAVE 4
	NOTE_CMD 1
	OCTAVE 3
	NOTE_CMD $0A
	OCTAVE 4
	NOTE_CMD 3
	OCTAVE 3
	NOTE_CMD $0B
	OCTAVE 4
	NOTE_CMD 4
	OCTAVE 3
	NOTE_CMD $0C
	OCTAVE 4
	NOTES 5, 1
	ATTEN 6
	RELEASE 8, 1
	OCTAVE 4
	NOTE_CMD 3
	OCTAVE 3
	NOTE_CMD $0B
	OCTAVE 4
	NOTE_CMD 4
	OCTAVE 3
	NOTE_CMD $0C
	OCTAVE 4
	NOTES 5, 1
	SND_END

Snd17_SfxN:
	NVOICE $81, $85
	NOISE $25
	NOISE $46
	NOISE $00
	NOISE $37
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NVOICE $81, $86
	NOISE $14
	NOISE $36
	NOISE $00
	NOISE $37
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NVOICE $81, $82
	NOISE $14
	NOISE $36
	NOISE $00
	NOISE_VOL 1
	NOISE $37
	SND_END

Snd19_Sfx1:
	VOICE $01, 8, 8, 0, 8
	OCTAVE 4
	ATTEN 4
	NOTE_CMD 1
	ATTEN 3
	NOTE_CMD 2
	ATTEN 2
	NOTE_CMD 3
	ATTEN 1
	NOTE_CMD 4
	ATTEN 0
	NOTES 5, 6
	ATTEN 2
	NOTE_CMD 6
	ATTEN 6
	NOTES 1, 2
	NOTES 3, 4
	ATTEN 7
	NOTES 5, 6
	NOTE_CMD 6
	SND_END

Snd1A_Sfx1:
	VOICE $01, 8, 7, 0, 8
	OCTAVE 4
	ATTEN 2
	NOTES 4, 5
	ATTEN 4
	NOTE_CMD 7
	ATTEN 3
	NOTE_CMD 9
	ATTEN 2
	NOTE_CMD $0B
	ATTEN 1
	NOTE_CMD $0C
	ATTEN 0
	OCTAVE 5
	NOTE_CMD 1
	ATTEN 2
	NOTE_CMD 1
	ATTEN 6
	OCTAVE 4
	NOTES 7, 9
	NOTES $0B, $0C
	ATTEN 7
	OCTAVE 5
	NOTES 1, 1
	SND_END

Snd1B_Sfx1:
	VOICE $01, 8, 8, 0, 8
	OCTAVE 5
	NOTES 6, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTES 1, 1
	ATTEN 6
	NOTES 6, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTES 1, 1
	ATTEN 0
	LEN_UNIT $03
	ATTEN 2
	OCTAVE 4
	NOTES 2, 3
	NOTES 2, 3
	ATTEN 7
	NOTES 2, 3
	NOTES 2, 3
	SND_END

Snd1C_Sfx1:
	VOICE $01, 0, 9, 0, 8
	SWEEP $27
	TRANSPOSE_DOWN 3
	OCTAVE 5
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	OCTAVE 5
	NOTES 1, $0D
	NOTES 2, $0D
	NOTES 3, $0D
	ATTEN 1
	NOTES 4, $0D
	NOTES 4, $0D
	NOTES 5, $0D
	NOTES 6, $0D
	ATTEN 2
	NOTES 6, $0D
	ATTEN 3
	NOTES 7, $0D
	ATTEN 4
	NOTES 7, $0D
	ATTEN 5
	NOTES 8, $0D
	ATTEN 6
	NOTES 8, $0D
	LOOP_START
	NOTES 8, $0D
	LOOP_END 4
	VOLUME $01
	LOOP_START
	NOTES 8, $0D
	LOOP_END 3
	SND_END

Snd1C_SfxN:
	NVOICE $02, $83
	NOISE $24
	NOISE_VOL 4
	NOISE $25
	NOISE_VOL 5
	NOISE $26
	NOISE $27
	NVOICE $01, $85
	NOISE $17
	NOISE $17
	NOISE $17
	NOISE $17
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $15
	NOISE $15
	NOISE $15
	NOISE_VOL 3
	NOISE $15
	NOISE $14
	NOISE $14
	NOISE $14
	NOISE $14
	NOISE $14
	NOISE_VOL 2
	NOISE $07
	NOISE $07
	NOISE $07
	NOISE $06
	NOISE $06
	NOISE $06
	NOISE $05
	NOISE $05
	NOISE_VOL 1
	NOISE $04
	NOISE $04
	NOISE $03
	NOISE $03
	NOISE $03
	NOISE $02
	NOISE $02
	NOISE $01
	NOISE $01
	NOISE $01
	SND_END

Snd1D_Sfx1:
	VOICE $03, 8, 4, 15, 9
	SWEEP $2F
	OCTAVE 4
	NOTE_CMD 8
	VOICE $08, 8, 9, 15, 1
	SWEEP $2E
	OCTAVE 4
	NOTE_CMD 3
	RELEASE $0F, 2
	ATTEN 6
	NOTE_CMD 3
	ATTEN 7
	NOTE_CMD 3
	SND_END

Snd1D_SfxN:
	NVOICE $01, $B1
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $02, $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	SND_END

Snd1E_Sfx1:
	VOICE $02, 8, 8, 0, 0
	VIBRATO_SEMI 1
	TRANSPOSE_DOWN 2
	OCTAVE 4
	NOTE_CMD $0B
	VOICE $08, 8, 6, 15, 1
	VIBRATO_OFF
	NOTE_CMD $0C
	VOICE $02, 8, 3, 0, 0
	VIBRATO_SEMI 1
	NOTE_CMD $0B
	VOICE $08, 8, 2, 15, 1
	VIBRATO_OFF
	NOTE_CMD $0C
	SND_END

Snd1E_SfxN:
	NVOICE $82, $15
	NOISE $25
	NVOICE $88, $14
	NOISE $12
	NVOICE $81, $11
	NOISE $25
	NVOICE $88, $11
	NOISE $12
	SND_END

Snd1F_Sfx1:
	VOICE $03, 8, 12, 8, 8
	SWEEP $1B
	OCTAVE 4
	NOTES 8, 2
	VOLUME $05
	NOTES 8, 2
	ATTEN 2
	NOTES 8, 2
	SND_END

Snd1F_SfxN:
	NVOICE $03, $85
	NOISE $59
	NOISE $5C
	NOISE_VOL 3
	NOISE $59
	NOISE $5C
	NOISE_VOL 1
	NOISE $59
	NOISE $5C
	SND_END

Snd20_Sfx1:
	VOICE $01, 4, 12, 0, 8
	OCTAVE 3
	NOTES 1, 2
	DUTY 0
	NOTES 1, 1
	NOTES 1, 1
	OCTAVE 2
	NOTE_CMD $0C
	ATTEN 1
	NOTES $0B, $0A
	NOTES 9, 8
	NOTES 7, 6
	VOLUME $06
	NOTES 4, 3
	NOTES 2, 1
	ATTEN 4
	OCTAVE 1
	NOTES $0B, $0A
	ATTEN 5
	NOTES 8, 6
	NOTE_CMD 5
	ATTEN 4
	OCTAVE 3
	NOTES 1, 1
	NOTES 1, 1
	OCTAVE 2
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 4
	NOTES 3, 2
	NOTE_CMD 1
	OCTAVE 1
	ATTEN 5
	NOTES $0B, $0A
	NOTES 8, 6
	NOTE_CMD 5
	SND_END

Snd21_Sfx1:
	VOICE $04, 0, 10, 8, 1
	OCTAVE 4
	LOOP_START
	ATTEN 0
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	LOOP_END 3
	LOOP_START
	ATTEN 0
	NOTE_CMD 8
	ATTEN 5
	NOTE_CMD 8
	LOOP_END 3
	VOICE $20, 0, 10, 8, 3
	OCTAVE 5
	NOTE_CMD 1
	ATTEN 6
	RELEASE 8, 8
	NOTE_CMD 1
	SND_END

Snd21_Sfx2:
	VOICE $04, 4, 4, 8, 8
	OCTAVE 4
	LOOP_START
	ATTEN 0
	NOTE_CMD 1
	ATTEN 1
	NOTE_CMD 1
	LOOP_END 3
	LOOP_START
	ATTEN 0
	NOTE_CMD 5
	ATTEN 1
	NOTE_CMD 5
	LOOP_END 3
	VOICE $08, 4, 4, 8, 8
	NOTE_CMD 8
	LEN_UNIT $10
	ATTEN 1
	NOTE_CMD 8
	SND_END

Snd21_SfxN:
	NVOICE $A8, $88
	NOISE_VOLNOTE 0
	SND_JUMP Snd12_SfxN

Snd23_Sfx1:
	VOICE $02, 8, 7, 0, 8
	ATTEN 5
	OCTAVE 5
	NOTES $0C, $0B
	ATTEN 4
	NOTES $0A, 9
	ATTEN 3
	NOTES 8, 7
	NOTES 6, 5
	ATTEN 2
	NOTES 4, 3
	NOTES 2, 1
	ATTEN 1
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	ATTEN 0
	NOTES 8, 7
	ATTEN 1
	NOTES 6, 5
	ATTEN 2
	NOTES 4, 3
	ATTEN 3
	NOTES 2, 1
	VOLUME $02
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	ATTEN 1
	NOTES 4, 3
	NOTES 2, 1
	SND_END

Snd24_SfxN:
	NVOICE $01, $8A
	NOISE $17
	NVOICE $08, $1B
	NOISE $54
	NVOICE $08, $34
	NOISE $54
	NVOICE $04, $32
	NOISE $54
	SND_END

Snd25_Sfx1:
	VOICE $01, 8, 7, 0, 8
	TRANSPOSE_DOWN 4
	ATTEN 2
	OCTAVE 4
	NOTE_CMD 5
	ATTEN 1
	NOTE_CMD 6
	ATTEN 0
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 5
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	ATTEN 6
	NOTES $0B, $0C
	SND_END

Snd26_Sfx1:
	VOICE $01, 8, 7, 0, 8
	TRANSPOSE_DOWN 0
	ATTEN 2
	OCTAVE 4
	NOTE_CMD 5
	ATTEN 1
	NOTE_CMD 6
	ATTEN 0
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 6
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	SND_END

Snd26_SfxN:
	NVOICE $02, $98
	NOISE $44
	NVOICE $01, $2A
	NOISE $44
	NOISE $25
	NOISE $25
	NOISE $25
	NOISE $25
	NVOICE $02, $93
	NOISE $44
	NVOICE $01, $34
	NOISE $44
	NOISE $25
	NOISE $25
	NOISE $25
	NOISE $25
	SND_END

Snd27_SfxN:
	NVOICE $02, $89
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL $0D
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL $0E
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL $0B
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL $0A
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL 9
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $45
	NOISE_VOLNOTE 0
	NOISE_VOL 8
	NOISE $44
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	NOISE $44
	SND_END

Snd28_SfxN:
	NVOICE $02, $89
	NOISE $44
	NOISE_VOL 3
	NOISE $44
	NOISE_VOL 5
	NOISE $45
	NOISE_VOL 3
	NOISE $45
	NOISE_VOL $0D
	NOISE $44
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 9
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE_VOL $0E
	NOISE $44
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL $0A
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE_VOL $0B
	NOISE $44
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 7
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE_VOL $0A
	NOISE $44
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 6
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE_VOL 8
	NOISE $44
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 4
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE_VOL 7
	NOISE $44
	NOISE_VOL 1
	NOISE $44
	SND_END

Snd29_Sfx1:
	VOICE $08, 0, 7, 0, 7
	SWEEP $27
	NOTE_CMD 0
	LEN_UNIT $01
	TRANSPOSE_UP 4
	OCTAVE 4
	NOTES $0C, $0C
	NOTES $0B, $0B
	NOTES $0A, $0A
	ATTEN 1
	NOTES 9, 8
	NOTES 7, 6
	NOTES 5, 4
	ATTEN 4
	NOTES $0C, $0C
	NOTES $0B, $0B
	NOTES $0A, $0A
	ATTEN 5
	NOTES 9, 8
	NOTES 7, 6
	NOTES 5, 4
	SND_END

Snd29_SfxN:
	NVOICE $01, $91
	LOOP_START
	NOISE $24
	NOISE $44
	LOOP_END 4
	NVOICE $01, $37
	LOOP_START
	NOISE $04
	NOISE $07
	LOOP_END 4
	LOOP_START
	NOISE $05
	NOISE $07
	LOOP_END 4
	LOOP_START
	NOISE $06
	NOISE $07
	LOOP_END 4
	LOOP_START
	NOISE $07
	NOISE $07
	LOOP_END 4
	SND_END

Snd2A_Sfx1:
	VOICE $01, 8, 13, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTES $0A, $0A
	VOICE $04, 8, 15, 0, 8
	SWEEP $14
	OCTAVE 1
	NOTE_CMD 8
	ATTEN 4
	NOTE_CMD 8
	VOICE $05, 4, 8, 15, 1
	OCTAVE 4
	SWEEP $17
	NOTE_CMD 4
	ATTEN 3
	NOTE_CMD 3
	RELEASE $0F, 2
	ATTEN 4
	NOTE_CMD 2
	RELEASE $0F, 3
	ATTEN 6
	NOTES 4, 3
	SND_END

Snd2A_SfxN:
	NVOICE $01, $88
	NOISE $17
	NVOICE $04, $1B
	NOISE $47
	NOISE $6C
	NVOICE $04, $33
	NOISE $47
	NOISE $6C
	SND_END

Snd2B_Sfx1:
	VOICE $02, 8, 12, 15, 1
	SWEEP $1A
	OCTAVE 3
	NOTE_CMD 7
	ATTEN 5
	NOTE_CMD 7
	VOICE $06, 8, 13, 15, 1
	SWEEP $16
	TRANSPOSE_UP 7
	OCTAVE 2
	NOTE_CMD 4
	ATTEN 4
	NOTE_CMD 4
	ATTEN 7
	NOTE_CMD 4
	VOLUME $03
	NOTE_CMD 4
	ATTEN 1
	NOTE_CMD 4
	SND_END

Snd2C_Sfx1:
	VOICE $01, 8, 12, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 4
	VOICE $09, 8, 13, 15, 1
	SWEEP $17
	OCTAVE 2
	NOTE_CMD 6
	ATTEN 7
	RELEASE $0B, 1
	NOTE_CMD 6
	SND_END

Snd2D_Sfx1:
	VOICE $04, 8, 15, 0, 8
	SWEEP $1C
	OCTAVE 4
	NOTE_CMD 3
	VOLUME $06
	NOTE_CMD 3
	ATTEN 3
	NOTE_CMD 3
	ATTEN 5
	NOTE_CMD 3
	SND_END

Snd2D_SfxN:
	NVOICE $04, $85
	NOISE_VOLNOTE 0
	NVOICE $01, $86
	NOISE $46
	NOISE $44
	NOISE $37
	NOISE $37
	NOISE $36
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE_VOL 2
	NOISE $46
	NOISE $44
	NOISE $37
	NOISE $37
	NOISE $36
	NOISE $36
	NOISE $35
	NOISE $34
	SND_END

Snd2E_Sfx1:
	VOICE $03, 8, 15, 0, 8
	SWEEP $19
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 7
	NOTE_CMD $0A
	VOICE $08, 8, 5, 15, 2
	SWEEP $1C
	OCTAVE 4
	NOTE_CMD 1
	ATTEN 2
	NOTE_CMD 1
	ATTEN 4
	NOTE_CMD 1
	SND_END

Snd2E_SfxN:
	NVOICE $03, $84
	NOISE $59
	NOISE $5C
	NOISE_VOL 1
	NOISE $59
	NOISE $5C
	SND_END

Snd2F_Sfx1:
	VOICE $06, 8, 14, 15, 1
	SWEEP $1A
	OCTAVE 4
	NOTES 7, 2
	VOICE $05, 8, 14, 15, 1
	SWEEP $1E
	OCTAVE 3
	ATTEN 4
	NOTE_CMD $0B
	ATTEN 6
	NOTE_CMD $0B
	VOLUME $04
	NOTE_CMD $0B
	ATTEN 3
	NOTE_CMD $0B
	SND_END

Snd2F_SfxN:
	NVOICE $03, $84
	NOISE $59
	NOISE $5C
	NOISE_VOL 2
	NOISE $59
	NOISE $5C
	NOISE_VOL 1
	NOISE $59
	NOISE $5C
	SND_END

Snd30_Sfx1:
	VOICE $01, 8, 10, 0, 0
	SWEEP $1F
	OCTAVE 4
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 5
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 6
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 7
	NOTES 3, 3
	NOTE_CMD 3
	VOLUME $01
	NOTES 3, 3
	NOTE_CMD 3
	SND_END

Snd30_SfxN:
	NVOICE $01, $89
	NOISE $49
	NOISE $45
	NOISE_VOL 6
	NOISE $49
	NOISE $45
	NOISE_VOL 8
	NOISE $49
	NOISE_VOL $0A
	NOISE $45
	NOISE_VOL 9
	NOISE $49
	NOISE_VOL $0A
	NOISE $45
	NOISE_VOL 6
	NOISE $4A
	NOISE_VOL 7
	NOISE $45
	NOISE_VOL 4
	NOISE $4A
	NOISE_VOL 6
	NOISE $45
	NOISE_VOL 2
	NOISE $4A
	NOISE_VOL 3
	NOISE $45
	NOISE_VOL 1
	NOISE $4A
	NOISE_VOL 1
	NOISE $45
	SND_END

Snd31_SfxN:
	NVOICE $02, $89
	NOISE $6C
	NOISE $57
	NOISE_VOL 9
	NOISE $56
	NOISE $54
	NOISE $46
	NOISE $44
	NOISE $45
	NOISE_VOL 8
	NOISE $47
	NOISE_VOL 7
	NOISE $45
	NOISE $00
	NOISE_VOL 5
	NOISE $64
	NOISE $57
	NOISE $56
	NOISE $54
	NOISE $46
	NOISE $44
	NOISE $46
	NOISE_VOL 4
	NOISE $54
	NOISE_VOL 3
	NOISE $55
	NOISE $00
	NOISE_VOL 2
	NOISE $64
	NOISE $57
	NOISE $56
	NOISE $54
	NOISE $46
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE_VOL 1
	NOISE $55
	NOISE $00
	NOISE $64
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $47
	NOISE $55
	NOISE $56
	NOISE $00
	SND_END

Snd32_Sfx1:
	VOICE $01, 8, 12, 0, 8
	SWEEP $1B
	OCTAVE 5
	NOTE_CMD $0B
	VOICE $06, 8, 12, 15, 1
	SWEEP $2F
	OCTAVE 4
	NOTE_CMD 4
	ATTEN 7
	RELEASE 8, 1
	NOTE_CMD 4
	SND_END

Snd39_Sfx1:
	VOICE $01, 8, 13, 8, 8
	NOTE_CMD 0
	LEN_UNIT $03
	SWEEP $1B
	OCTAVE 4
	NOTES 8, 2
	VOLUME $06
	NOTES 8, 2
	ATTEN 4
	NOTES 8, 2
	SND_END

Snd33_Sfx1:
	VOICE $06, 0, 12, 15, 2
	DUTY_STEP 5, 1
	OCTAVE 5
	NOTE_CMD $0B
	ATTEN 7
	NOTE_CMD $0B
	SND_END

Snd34_Sfx1:
	VOICE $01, 0, 11, 0, 8
	DUTY_STEP 5, 1
	OCTAVE 6
	NOTE_CMD 6
	ATTEN 1
	NOTE_CMD 6
	ATTEN 2
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 2
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTE_CMD 6
	ATTEN 6
	NOTE_CMD 6
	ATTEN 5
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTE_CMD 6
	ATTEN 6
	NOTE_CMD 6
	ATTEN 7
	NOTE_CMD 6
	ATTEN 6
	NOTE_CMD 6
	VOLUME $06
	NOTE_CMD 6
	ATTEN 1
	NOTE_CMD 6
	ATTEN 2
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 2
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 3
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTES 6, 6
	NOTE_CMD 6
	ATTEN 4
	NOTE_CMD 6
	ATTEN 5
	NOTES 6, 6
	NOTES 6, 6
	SND_END

Snd35_Sfx1:
	VOICE $01, 8, 12, 0, 8
	SWEEP $1F
	TRANSPOSE_DOWN 0
	OCTAVE 4
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 5
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 6
	NOTES 3, 3
	NOTE_CMD 3
	ATTEN 7
	NOTES 3, 3
	NOTE_CMD 3
	SWEEP $00
	VOICE $05, 8, 12, 15, 1
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 6
	NOTE_CMD $0A
	ATTEN 0
	NOTE_CMD 6
	ATTEN 6
	NOTE_CMD 6
	VOICE $05, 8, 2, 0, 8
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 1
	NOTE_CMD $0A
	ATTEN 0
	NOTE_CMD 6
	ATTEN 1
	NOTE_CMD 6
	SND_END

Snd35_SfxN:
	NVOICE $01, $83
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	NOISE_VOL 2
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	NOISE_VOL 1
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	SND_END

Snd36_Sfx1:
	VOICE $04, 8, 14, 15, 2
	OCTAVE 5
	LOOP_START
	NOTES $0A, 6
	LOOP_END 4
	VOLUME $03
	NOTES $0A, 6
	ATTEN 1
	NOTES $0A, 6
	ATTEN 2
	NOTES $0A, 6
	SND_END

Snd37_Sfx1:
	VOICE $06, 8, 10, 0, 8
	SWEEP $17
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 4
	NOTE_CMD $0A
	ATTEN 6
	NOTE_CMD $0A
	VOLUME $02
	NOTE_CMD $0A
	SND_END

Snd38_Sfx1:
	VOICE $03, 4, 10, 0, 8
	OCTAVE 6
	LOOP_START
	ATTEN 0
	NOTE_CMD 2
	ATTEN 7
	NOTE_CMD 2
	LOOP_END 3
	VOLUME $02
	LOOP_START
	ATTEN 0
	NOTE_CMD 2
	ATTEN 1
	NOTE_CMD 2
	LOOP_END 2
	SND_END

Snd3A_Sfx1:
	VOICE $01, 8, 14, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 4
	SWEEP $00
	VOICE $04, 8, 13, 15, 1
	OCTAVE 2
	NOTE_CMD 4
	ATTEN 7
	RELEASE $0B, 1
	NOTE_CMD 4
	SND_END

Snd3C_Sfx1:
	VOICE $02, 8, 4, 8, 1
	SND_CALL Snd3B_Sfx1_580E

Snd3D_Sfx1:
	VOICE $01, 8, 4, 8, 1
	SND_CALL Snd3B_Sfx1_580E

Snd3B_Sfx1:
	VOICE $04, 8, 5, 8, 1
Snd3B_Sfx1_580E:
	OCTAVE 3
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 4
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 5
	NOTES 1, 2
	NOTE_CMD 1
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	OCTAVE 3
	NOTES $0C, $0B
	NOTES $0A, 9
	SND_END

Snd3E_Sfx1:
	VOICE $01, 8, 12, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 4
	VOICE $09, 8, 14, 15, 1
	SWEEP $17
	TRANSPOSE_DOWN 4
	OCTAVE 2
	NOTE_CMD 6
	ATTEN 7
	RELEASE $0B, 1
	NOTES 6, 0
	VOICE $01, 8, 10, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 4
	VOICE $09, 8, 12, 15, 1
	SWEEP $17
	TRANSPOSE_DOWN 6
	OCTAVE 2
	NOTE_CMD 6
	ATTEN 7
	RELEASE $0B, 1
	NOTE_CMD 6
	SND_END

Snd3F_Sfx1:
	VOICE $01, 8, 14, 0, 8
	SWEEP $1A
	OCTAVE 4
	NOTE_CMD $0A
	ATTEN 7
	NOTE_CMD $0A
	SWEEP $1D
	VOICE $01, 8, 12, 0, 8
	OCTAVE 2
	NOTES 8, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTE_CMD 1
	ATTEN 1
	OCTAVE 1
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	VOLUME $05
	OCTAVE 2
	NOTES 8, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTE_CMD 1
	ATTEN 1
	OCTAVE 1
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	ATTEN 3
	OCTAVE 2
	NOTES 8, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTE_CMD 1
	ATTEN 3
	OCTAVE 1
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	ATTEN 4
	OCTAVE 2
	NOTES 8, 6
	NOTES 5, 4
	NOTES 3, 2
	NOTE_CMD 1
	OCTAVE 1
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	SND_END

Snd40_Sfx1:
	VOICE $03, 8, 12, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 8
	SWEEP $00
	VOICE $01, 8, 11, 0, 8
	OCTAVE 1
	NOTES $0B, $0C
	OCTAVE 2
	NOTES 1, 2
	VOICE $04, 8, 11, 15, 1
	NOTE_CMD 3
	VOICE $01, 8, 2, 0, 8
	OCTAVE 1
	NOTES $0B, $0C
	OCTAVE 2
	NOTES 1, 2
	VOICE $04, 8, 2, 15, 1
	NOTE_CMD 3
	SND_END

Snd41_Sfx1:
	VOICE $02, 12, 9, 0, 8
	DUTY_STEP 0, 2
	ATTEN 2
	OCTAVE 2
	NOTES 1, 2
	NOTES 3, 4
	ATTEN 1
	NOTES 5, 6
	NOTES 7, 8
	ATTEN 0
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 4
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	SND_END

Snd42_Sfx1:
	VOICE $03, 8, 10, 0, 8
	SWEEP $1A
	OCTAVE 4
	NOTE_CMD 2
	VOICE $08, 4, 10, 12, 1
	SWEEP $1F
	OCTAVE 4
	NOTE_CMD $0C
	VOLUME $05
	RELEASE $0A, 1
	NOTE_CMD $0C
	ATTEN 1
	NOTE_CMD $0C
	ATTEN 2
	NOTE_CMD $0C
	SND_END

Snd43_Sfx1:
	VOICE $02, 12, 8, 8, 8
	SWEEP $1F
	OCTAVE 3
	NOTES 1, 1
	SND_END

Snd43_SfxN:
	NVOICE $02, $89
	NOISE $5C
	NOISE $47
	NOISE_VOL 9
	NOISE $46
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $35
	NOISE_VOL 8
	NOISE $37
	NOISE_VOL 7
	NOISE $35
	NOISE $00
	NOISE_VOL 5
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $36
	NOISE_VOL 4
	NOISE $44
	NOISE_VOL 3
	NOISE $45
	NOISE $00
	NOISE_VOL 2
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE_VOL 1
	NOISE $45
	NOISE $00
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $37
	NOISE $45
	NOISE $46
	NOISE $00
	SND_END

Snd44_Sfx1:
	VOICE $03, 8, 12, 8, 8
	SWEEP $1B
	OCTAVE 4
	NOTES 8, 2
	VOICE $08, 8, 14, 15, 1
	SWEEP $16
	OCTAVE 1
	NOTE_CMD 8
	RELEASE $0F, 3
	ATTEN 7
	NOTE_CMD 8
	VOLUME $03
	RELEASE 0, 8
	NOTE_CMD 8
	ATTEN 2
	NOTE_CMD 8
	SND_END

Snd44_SfxN:
	NVOICE $03, $84
	NOISE $69
	NOISE $6C
	NOISE_VOL 2
	NOISE $69
	NOISE $6C
	NOISE_VOL 1
	NOISE $69
	NOISE $6C
	SND_END

Snd46_SfxN:
	NVOICE $01, $8A
	LOOP_START
	NOISE $5D
	NOISE $18
	NOISE $61
	LOOP_END 4
	NOISE_VOL 2
	LOOP_START
	NOISE $5D
	NOISE $18
	NOISE $61
	LOOP_END 3
	SND_END

Snd47_SfxN:
	NVOICE $01, $8A
	LOOP_START
	NOISE $5D
	NOISE $18
	NOISE $61
	LOOP_END 8
	NOISE_VOL 2
	LOOP_START
	NOISE $5D
	NOISE $18
	NOISE $61
	LOOP_END 6
	SND_END

Snd48_Sfx1:
	VOICE $01, 0, 10, 8, 8
	OCTAVE 6
	NOTE_CMD 8
	VOICE $10, 0, 6, 15, 2
	OCTAVE 6
	NOTE_CMD 8
	SND_END

Snd49_Sfx1:
	VOICE $06, 8, 9, 15, 1
	OCTAVE 4
	NOTE_CMD 2
	LEN_UNIT $01
	NOTES 0, 0
	LEN_UNIT $05
	VOLUME $02
	NOTE_CMD 2
	SND_END

Snd49_SfxN:
	NVOICE $01, $86
	NOISE $26
	NOISE_VOL 4
	NOISE $34
	NOISE_VOL 2
	NOISE $36
	NOISE_VOL 3
	NOISE $26
	NOISE_VOL 2
	NOISE $34
	NOISE $36
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NVOICE $01, $81
	NOISE $27
	NOISE $35
	SND_END

Snd4A_Sfx1:
	VOICE $01, 8, 13, 0, 8
	SWEEP $1B
	OCTAVE 4
	NOTE_CMD 4
	SWEEP $00
	VOICE $04, 8, 12, 15, 1
	OCTAVE 2
	NOTE_CMD 4
	ATTEN 7
	RELEASE $0B, 1
	NOTE_CMD 4
	SND_END

Snd4B_Sfx1:
	VOICE $06, 8, 9, 15, 1
	OCTAVE 4
	NOTE_CMD $0B
	LEN_UNIT $01
	NOTES 0, 0
	LEN_UNIT $05
	VOLUME $02
	NOTE_CMD $0B
	LEN_UNIT $06
	NOTES 0, 0
	LEN_UNIT $06
	VOLUME $06
	NOTE_CMD $0B
	LEN_UNIT $01
	NOTES 0, 0
	LEN_UNIT $05
	VOLUME $02
	NOTE_CMD $0B
	LEN_UNIT $03
	NOTES 0, 0
	LEN_UNIT $06
	VOLUME $04
	NOTE_CMD $0B
	LEN_UNIT $05
	VOLUME $02
	NOTE_CMD $0B
	LEN_UNIT $01
	NOTES 0, 0
	LEN_UNIT $06
	VOLUME $03
	NOTE_CMD $0B
	LEN_UNIT $05
	VOLUME $01
	NOTE_CMD $0B
	LEN_UNIT $06
	VOLUME $02
	NOTE_CMD $0B
	LEN_UNIT $05
	VOLUME $01
	NOTE_CMD $0B
	SND_END

Snd4B_SfxN:
	NVOICE $01, $86
	NOISE $26
	NOISE_VOL 4
	NOISE $34
	NOISE_VOL 2
	NOISE $36
	NOISE_VOL 3
	NOISE $26
	NOISE_VOL 2
	NOISE $34
	NOISE $36
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NVOICE $01, $81
	NOISE $27
	NOISE $35
	SND_END

Snd4C_Sfx1:
	VOICE $03, 8, 13, 0, 8
	OCTAVE 2
	NOTES 1, 2
	NOTES 3, 4
	NOTE_CMD 5
	VOLUME $03
	OCTAVE 2
	NOTES 1, 2
	ATTEN 2
	NOTES 3, 4
	NOTE_CMD 5
	SND_END

Snd4D_Sfx1:
	VOICE $04, 12, 9, 15, 1
	OCTAVE 4
	NOTES 9, $0A
	ATTEN 3
	NOTE_CMD $0B
	VOLUME $02
	OCTAVE 4
	NOTES $0A, $0B
	SND_END

Snd4E_Sfx1:
	VOICE $04, 8, 4, 8, 1
	OCTAVE 3
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 4
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	ATTEN 2
	NOTE_CMD $0A
	ATTEN 0
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	OCTAVE 3
	NOTES $0C, $0B
	NOTES $0A, 9
	SND_END

Snd4F_Sfx1:
	VOICE $05, 4, 12, 15, 1
	SWEEP $2F
	OCTAVE 4
	NOTE_CMD 7
	OCTAVE 5
	NOTE_CMD 2
	ATTEN 6
	RELEASE $0F, 2
	OCTAVE 4
	NOTE_CMD 7
	OCTAVE 5
	NOTE_CMD 2
	VOLUME $03
	RELEASE $0F, 4
	OCTAVE 4
	NOTE_CMD 7
	OCTAVE 5
	NOTE_CMD 2
	ATTEN 2
	RELEASE 0, 8
	OCTAVE 4
	NOTE_CMD 7
	OCTAVE 5
	NOTE_CMD 2
	SND_END

Snd50_Sfx1:
	VOICE $05, 0, 10, 15, 1
	OCTAVE 5
	NOTE_CMD 8
	OCTAVE 6
	NOTES 8, 3
	NOTE_CMD 8
	VOICE $05, 0, 4, 11, 1
	NOTES 3, 8
	ATTEN 2
	NOTES 3, 8
	ATTEN 3
	NOTES 3, 8
	SND_END

Snd51_Sfx1:
	VOICE $02, 8, 7, 15, 9
	SWEEP $1F
	OCTAVE 5
	NOTE_CMD 7
	VOLUME $02
	RELEASE 0, 8
	NOTE_CMD 7
	VOICE $04, 8, 10, 15, 1
	SWEEP $2F
	OCTAVE 5
	NOTE_CMD 3
	VOLUME $01
	RELEASE 0, 8
	NOTE_CMD 3
	VOICE $04, 8, 4, 15, 2
	SWEEP $2F
	OCTAVE 5
	NOTE_CMD 3
	ATTEN 3
	RELEASE 0, 8
	NOTE_CMD 3
	SND_END

Snd52_Sfx1:
	VOICE $05, 8, 8, 11, 2
	SWEEP $4A
	OCTAVE 4
	NOTES 1, 3
	NOTES 5, 6
	NOTES 7, 8
	VOLUME $02
	OCTAVE 4
	NOTES 1, 3
	ATTEN 1
	NOTES 5, 6
	NOTES 7, 8
	SND_END

Snd53_SfxN:
	NVOICE $01, $8A
	NOISE $58
	NVOICE $01, $29
	LOOP_START
	NOISE $5A
	NOISE $4D
	LOOP_END 8
	NVOICE $01, $82
	NOISE $58
	NVOICE $01, $82
	LOOP_START
	NOISE $5A
	NOISE $4D
	LOOP_END 6
	SND_END

Snd54_Sfx1:
	VOICE $03, 8, 15, 0, 8
	TRANSPOSE_DOWN 3
	SWEEP $16
	OCTAVE 2
	NOTE_CMD 1
	OCTAVE 3
	NOTE_CMD 4
	OCTAVE 2
	NOTE_CMD 2
	OCTAVE 3
	NOTE_CMD 5
	OCTAVE 2
	NOTE_CMD 3
	OCTAVE 3
	NOTE_CMD 6
	OCTAVE 2
	NOTE_CMD 4
	OCTAVE 3
	NOTE_CMD 7
	OCTAVE 2
	NOTE_CMD 5
	OCTAVE 3
	NOTE_CMD 8
	VOLUME $03
	OCTAVE 2
	NOTE_CMD 1
	OCTAVE 3
	NOTE_CMD 4
	OCTAVE 2
	NOTE_CMD 2
	OCTAVE 3
	NOTE_CMD 5
	OCTAVE 2
	NOTE_CMD 3
	OCTAVE 3
	NOTE_CMD 6
	OCTAVE 2
	NOTE_CMD 4
	OCTAVE 3
	NOTE_CMD 7
	OCTAVE 2
	NOTE_CMD 5
	OCTAVE 3
	NOTE_CMD 8
	SND_END

Snd55_SfxN:
	NVOICE $01, $89
	NOISE $58
	NVOICE $01, $19
	LOOP_START
	NOISE $5A
	NOISE $5B
	LOOP_END 5
	NVOICE $01, $82
	NOISE $58
	NVOICE $01, $82
	LOOP_START
	NOISE $5A
	NOISE $5B
	LOOP_END 5
	SND_END

Snd56_Sfx1:
	VOICE $01, 8, 5, 0, 8
	OCTAVE 4
	NOTES 4, 6
	NOTES 8, $0A
	NOTE_CMD $0C
	OCTAVE 5
	NOTES 2, 4
	VOICE $02, 8, 5, 0, 8
	NOTES 3, 2
	NOTE_CMD 1
	ATTEN 1
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	ATTEN 2
	NOTES 8, 7
	ATTEN 3
	NOTES 6, 5
	VOLUME $01
	OCTAVE 5
	NOTES 3, 2
	NOTE_CMD 1
	OCTAVE 4
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	SND_END

Snd57_Sfx1:
	VOICE $05, 0, 8, 0, 8
	SWEEP $17
	OCTAVE 4
	NOTE_CMD 3
	ATTEN 6
	NOTE_CMD 3
	ATTEN 0
	NOTE_CMD 8
	ATTEN 6
	NOTE_CMD 8
	VOLUME $02
	OCTAVE 4
	NOTE_CMD 3
	ATTEN 1
	NOTE_CMD 3
	ATTEN 0
	NOTE_CMD 8
	ATTEN 1
	NOTE_CMD 8
	SND_END

Snd58_Sfx1:
	VOICE $04, 0, 7, 8, 1
	OCTAVE 4
	TRANSPOSE_DOWN 0
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	ATTEN 0
	NOTES 1, 5
	NOTE_CMD 8
	ATTEN 5
	NOTE_CMD 8
	ATTEN 0
	NOTES 5, 8
	OCTAVE 5
	NOTE_CMD 1
	ATTEN 5
	NOTE_CMD 1
	ATTEN 0
	OCTAVE 4
	NOTE_CMD 8
	OCTAVE 5
	NOTE_CMD 1
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	ATTEN 0
	NOTES 1, 5
	OCTAVE 4
	NOTE_CMD 7
	ATTEN 5
	NOTE_CMD 7
	ATTEN 0
	NOTES 3, 7
	NOTE_CMD $0A
	ATTEN 5
	NOTE_CMD $0A
	ATTEN 0
	NOTES 7, $0A
	OCTAVE 5
	NOTE_CMD 3
	ATTEN 5
	NOTE_CMD 3
	ATTEN 0
	OCTAVE 4
	NOTE_CMD $0A
	OCTAVE 5
	NOTE_CMD 3
	OCTAVE 5
	NOTE_CMD 7
	ATTEN 5
	NOTE_CMD 7
	ATTEN 0
	NOTES 3, 7
	OCTAVE 4
	NOTE_CMD 9
	ATTEN 5
	NOTE_CMD 9
	ATTEN 0
	NOTES 5, 9
	NOTE_CMD $0C
	ATTEN 5
	NOTE_CMD $0C
	ATTEN 0
	NOTES 9, $0C
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	ATTEN 0
	OCTAVE 4
	NOTE_CMD $0C
	OCTAVE 5
	NOTE_CMD 5
	OCTAVE 5
	NOTE_CMD 9
	ATTEN 5
	NOTE_CMD 9
	ATTEN 0
	OCTAVE 4
	NOTES $0C, $0C
	VOICE $20, 0, 10, 8, 3
	OCTAVE 5
	NOTE_CMD 5
	SND_END

Snd58_Sfx2:
	VOICE $04, 4, 4, 8, 8
	OCTAVE 4
	NOTES 1, 0
	OCTAVE 3
	NOTE_CMD 8
	OCTAVE 4
	NOTE_CMD 1
	OCTAVE 4
	NOTES 5, 0
	NOTES 1, 5
	NOTES 8, 0
	NOTES 5, 8
	OCTAVE 5
	NOTES 1, 0
	OCTAVE 4
	NOTE_CMD 8
	OCTAVE 5
	NOTE_CMD 1
	OCTAVE 4
	NOTES 3, 0
	OCTAVE 3
	NOTE_CMD $0A
	OCTAVE 4
	NOTE_CMD 3
	OCTAVE 4
	NOTES 7, 0
	NOTES 3, 7
	NOTES $0A, 0
	NOTES 7, $0A
	OCTAVE 5
	NOTES 3, 0
	OCTAVE 4
	NOTE_CMD $0A
	OCTAVE 5
	NOTE_CMD 3
	OCTAVE 4
	NOTES 5, 0
	OCTAVE 3
	NOTE_CMD $0C
	OCTAVE 4
	NOTE_CMD 5
	OCTAVE 4
	NOTES 9, 0
	NOTES 5, 9
	NOTES $0C, 0
	NOTES 9, $0C
	OCTAVE 5
	NOTES 5, 0
	OCTAVE 4
	NOTES 9, 9
	VOICE $08, 4, 4, 8, 8
	NOTE_CMD $0C
	LEN_UNIT $10
	ATTEN 1
	NOTE_CMD $0C
	SND_END

Snd59_Sfx1:
	VOICE $06, 8, 8, 15, 2
	SWEEP $1F
	OCTAVE 6
	NOTE_CMD 9
	ATTEN 5
	NOTE_CMD 9
	ATTEN 7
	NOTE_CMD 9
	SND_END

Snd5A_Sfx1:
	VOICE $03, 8, 8, 0, 8
	NOTE_CMD 0
	OCTAVE 4
	NOTE_CMD $0A
	LEN_UNIT $07
	RELEASE $0F, 2
	OCTAVE 5
	NOTE_CMD 3
	ATTEN 6
	LEN_UNIT $03
	RELEASE $0F, 1
	OCTAVE 4
	NOTE_CMD $0A
	LEN_UNIT $07
	RELEASE $0F, 2
	OCTAVE 5
	NOTE_CMD 3
	SND_END

Snd5A_SfxN:
	NVOICE $01, $88
	NOISE $57
	NOISE_VOL 3
	NOISE $37
	NVOICE $01, $28
	LOOP_START
	NOISE $14
	NOISE $17
	LOOP_END 6
	NVOICE $01, $82
	LOOP_START
	NOISE $14
	NOISE $07
	LOOP_END 4
	NOISE_VOL 1
	LOOP_START
	NOISE $14
	NOISE $07
	LOOP_END 3
	SND_END

Snd5B_Sfx1:
	VOICE $01, 4, 13, 0, 8
	NOTES 0, 0
	NOTE_CMD 0
	OCTAVE 3
	NOTES 1, 6
	NOTES 1, 6
	NOTES 0, 0
	NOTES 0, 0
	LOOP_START
	NOTES 1, 6
	LOOP_END 6
	VOLUME $02
	LOOP_START
	NOTES 1, 6
	LOOP_END 6
	SND_END

Snd5C_Sfx1:
	VOICE $03, 0, 9, 15, 1
	DUTY_STEP 8, 2
	SWEEP $2F
	OCTAVE 5
	NOTES $0C, 0
	LEN_UNIT $06
	NOTE_CMD $0C
	ATTEN 6
	NOTE_CMD $0C
	ATTEN 7
	NOTE_CMD $0C
	SND_END

Snd45_Sfx1:
	VOICE $02, 0, 10, 0, 8
	SWEEP $17
	ATTEN 2
	OCTAVE 4
	ATTEN 1
	NOTES 2, 8
	ATTEN 0
	NOTES $0A, $0C
	NOTES $0A, 8
	NOTES 6, 4
	NOTE_CMD 2
	OCTAVE 2
	NOTES $0C, 8
	NOTES 4, 2
	ATTEN 6
	OCTAVE 4
	NOTES $0A, 8
	NOTES 6, 4
	ATTEN 7
	NOTE_CMD 2
	OCTAVE 2
	NOTES $0C, 8
	NOTES 4, 2
	SND_END

Snd5E_Ch2:
	TEMPO $20
	SND_CALL Snd5E_Ch2_5C84
Snd5E_Ch2_5C7D:
	SND_CALL Snd5E_Ch2_5CBB
	SND_CALL Snd5E_Ch2_5DBB
	SND_END
Snd5E_Ch2_5C84:
	VOICE $01, 8, 6, 15, 7
	REST 1
	VIBRATO_SEMI 3
	OCTAVE 3
	NOTE A_, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 4
	VIBRATO_OFF
	ATTEN 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	DETUNE $01
	OCTAVE 2
	NOTE B_, $0A
	SND_RET
Snd5E_Ch2_5CBB:
	VOICE $05, 4, 8, 9, 7
	RELEASE_VOL 3
	DETUNE $00
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	RELEASE_VOL 3
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE_VOL 3
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	VOICE $01, 8, 7, 6, 7
	VIBRATO_SEMI 1
	OCTAVE 4
	ATTEN 1
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	LEN_UNIT $05
	RELEASE $0A, 7
	RELEASE_VOL 3
	ATTEN 0
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	REST 2
	VOICE $05, 8, 7, 9, 7
	RELEASE_VOL 0
	VIBRATO 3, 0, 5
	OCTAVE 3
	NOTE D#, 4
	VOICE $05, 0, 7, 9, 7
	DUTY_STEP 8, 1
	VIBRATO_OFF
	RELEASE_VOL 3
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	RELEASE_VOL 4
	NOTE D#, 3
	RELEASE_VOL 3
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 2
	RELEASE_VOL 4
	OCTAVE 4
	NOTE G_, 4
	RELEASE_VOL 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	REST 2
	VOICE $05, 4, 7, 4, 7
	DUTY_STEP 0, 0
	NOTE G_, 4
	RELEASE 9, 3
	OCTAVE 5
	NOTE C_, 3
	REST 1
	VOICE $05, 8, 5, 10, 7
	VIBRATO_SEMI 1
	OCTAVE 6
	NOTE C_, 3
	OCTAVE 5
	NOTE G_, 1
	RELEASE_VOL 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN_UNIT $01
	ATTEN 0
	NOTE C_, $0A
	RELEASE $0A, 7
	VIBRATO_OFF
	RELEASE_VOL 0
	NOTE G_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN_UNIT $05
	RELEASE_VOL 2
	OCTAVE 6
	NOTE C_, 3
	REST 1
	VOICE $05, 4, 8, 8, 7
	VIBRATO_SEMI 1
	DUTY_STEP 0, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE D_, 3
	NOTE E_, 1
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE B_, 2
	REST 2
	VOICE $05, 0, 13, 6, 7
	NOTE E_, 4
	VIBRATO_OFF
	VOICE $05, 0, 8, 9, 7
	DUTY_STEP 8, 1
	RELEASE_VOL 3
	OCTAVE 3
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	VIBRATO_SEMI 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 6
	VIBRATO_OFF
	RELEASE_VOL 8
	OCTAVE 4
	NOTE G#, 3
	NOTE G_, 1
	RELEASE_VOL 3
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	SND_RET
Snd5E_Ch2_5DBB:
	VOICE $01, 8, 4, 7, 6
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C#, 5
	ATTEN 1
	NOTE D#, 7
	NOTE E_, 6
	ATTEN 0
	NOTE F#, 7
	LEN_UNIT $05
	RELEASE_VOL 2
	OCTAVE 4
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 6
	VOICE $05, 0, 3, 0, 0
	REST 1
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 1
	VOICE $05, 0, 7, 9, 6
	RELEASE_VOL 4
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	REST 2
	VOICE $05, 8, 4, 8, 6
	RELEASE_VOL 2
	DUTY_STEP 0, 0
	OCTAVE 5
	NOTE E_, 3
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 2, 3
	NOTE G#, 2
	RELEASE 8, 1
	NOTE B_, 2
	RELEASE 2, 3
	NOTE F#, 2
	RELEASE 8, 1
	NOTE B_, 2
	NOTE E_, 4
	VOICE $05, 0, 7, 8, 6
	RELEASE_VOL 4
	DUTY_STEP 4, 1
	OCTAVE 5
	NOTE E_, 2
	REST 2
	DETUNE $01
	OCTAVE 1
	NOTE E_, 4
	SND_RET

Snd5E_Ch1:
	SND_CALL Snd5E_Ch1_5E37
Snd5E_Ch1_5E30:
	SND_CALL Snd5E_Ch1_5E59
	SND_CALL Snd5E_Ch1_5FAC
	SND_END
Snd5E_Ch1_5E37:
	VOICE $05, 4, 10, 7, 5
	DETUNE $FF
	VIBRATO_SEMI 1
	DUTY_STEP 8, 2
	RELEASE_VOL 4
	OCTAVE 2
	ATTEN 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	ATTEN 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	REST 2
	OCTAVE 1
	NOTE B_, 2
	SND_RET
Snd5E_Ch1_5E59:
	VOICE $01, 8, 6, 10, 7
	VIBRATO_OFF
	DUTY_STEP 0, 0
	RELEASE_VOL 2
	DETUNE $00
	NOTE B_, $0A
	OCTAVE 3
	NOTE E_, $0A
	LOOP_START
	ATTEN 2
	RELEASE_VOL 0
	OCTAVE 5
	NOTE G#, 4
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 5
	ATTEN 4
	NOTE A_, 3
	NOTE A#, 2
	ATTEN 0
	RELEASE_VOL 1
	OCTAVE 3
	SND_JUMP_N 2, Snd5E_Ch1_5E7E
	NOTE E_, $0A
	NOTE A_, $0A
Snd5E_Ch1_5E7E:
	LOOP_END 2
	NOTE D#, $0A
	NOTE E_, $0A
	NOTE G#, $0A
	NOTE B_, $0A
	NOTE E_, $0A
	NOTE A_, $0A
	ATTEN 2
	RELEASE_VOL 0
	OCTAVE 5
	NOTE G#, 4
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 5
	ATTEN 4
	NOTE A_, 3
	NOTE A#, 2
	ATTEN 0
	RELEASE_VOL 2
	OCTAVE 3
	NOTE D#, $0A
	NOTE F#, $0A
	NOTE D#, $0A
	REST $0A
	NOTE D#, $0A
	NOTE A_, $0A
	NOTE D#, $0A
	REST $0A
	RELEASE_VOL 0
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	DUTY_STEP 4, 1
	RELEASE_VOL 2
	NOTE B_, $0A
	NOTE B_, $0A
	NOTE B_, $0A
	NOTE B_, $0A
	OCTAVE 4
	NOTE E_, $0A
	VOICE $05, 8, 5, 15, 7
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	LEN_UNIT $01
	OCTAVE 4
	NOTE C_, 4
	NOTE C#, 3
	NOTE D_, 3
	NOTE D#, $0A
	VOICE $01, 8, 3, 6, 7
	RELEASE_VOL 2
	VIBRATO_SEMI 3
	NOTE D#, $0A
	NOTE D#, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE C_, 5
	OCTAVE 3
	NOTE A#, 5
	NOTE G#, 5
	NOTE A#, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE G#, 4
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 5
	NOTE C_, $0A
	OCTAVE 3
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, $0A
	OCTAVE 2
	NOTE A#, 5
	OCTAVE 3
	NOTE C_, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 8
	REST $0C
	VOICE $05, 4, 7, 5, 7
	RELEASE_VOL 3
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 4
	RELEASE 9, 3
	OCTAVE 3
	NOTE C_, 3
	REST 1
	VOICE $05, 0, 6, 15, 2
	DETUNE $FF
	OCTAVE 2
	NOTE C_, 3
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	DETUNE $00
	RELEASE $0A, 6
	ATTEN 2
	OCTAVE 3
	NOTE C_, 4
	DUTY 8
	NOTE C_HI, 2
	REST 2
	VOICE $05, 8, 4, 6, 7
	RELEASE_VOL 2
	VIBRATO_SEMI 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 4
	REST 4
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	VIBRATO_OFF
	VOICE $05, 0, 6, 10, 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 6
	RELEASE $0A, 4
	OCTAVE 3
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 2
	VOICE $05, 8, 4, 8, 6
	RELEASE_VOL 0
	VIBRATO 1, 0, 2
	DETUNE $FF
	LEN_UNIT $01
	NOTE B_, 4
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 4
	NOTE C_, 3
	NOTE C#, 3
	NOTE D#, 4
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 4
	NOTE D#, 3
	NOTE E_, 3
	NOTE F#, 4
	NOTE F_, 3
	NOTE F#, 3
	VOICE $05, 8, 6, 10, 9
	RELEASE_VOL 4
	DETUNE $FF
	DUTY_STEP 0, 1
	VIBRATO_SEMI 3
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	SND_RET
Snd5E_Ch1_5FAC:
	VOICE $01, 8, 2, 3, 7
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 5
	ATTEN 1
	NOTE D#, 7
	NOTE E_, 6
	ATTEN 0
	NOTE F#, 4
	VOICE $01, 8, 5, 15, 5
	OCTAVE 3
	NOTE E_, $0A
	ATTEN 2
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 2
	NOTE B_, $0A
	ATTEN 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 8
	LOOP_START
	OCTAVE 3
	ATTEN 0
	NOTE F#, $0A
	ATTEN 2
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 2
	NOTE B_, $0A
	ATTEN 2
	SND_JUMP_N 2, Snd5E_Ch1_5FE8
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 3
	NOTE E_, $0A
	NOTE D#, $0A
	NOTE C#, $0A
	OCTAVE 2
	NOTE B_, $0A
Snd5E_Ch1_5FE8:
	LOOP_END 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 8
	VOICE $05, 0, 7, 6, 5
	DETUNE $01
	RELEASE_VOL 3
	OCTAVE 4
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 2
	DETUNE $00
	VOICE $05, 0, 7, 10, 2
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	VOICE $05, 8, 4, 6, 7
	OCTAVE 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 2
	REST 6
	VOICE $05, 0, 7, 9, 6
	RELEASE_VOL 4
	REST 0
	REST 4
	OCTAVE 3
	NOTE E_, 2
	REST 2
	DETUNE $FE
	OCTAVE 1
	NOTE E_, 4
	SND_RET

Snd5E_Ch3:
	SND_CALL Snd5E_Ch3_6036
Snd5E_Ch3_602F:
	SND_CALL Snd5E_Ch3_6063
	SND_CALL Snd5E_Ch3_613D
	SND_END
Snd5E_Ch3_6036:
	VOICE $01, 4, 4, 2, 7
	DETUNE $01
	OCTAVE 3
	NOTE A_, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 6
	REST $0E
	VOICE $05, 1, 2, 2, 7
	DETUNE $00
	OCTAVE 1
	NOTE B_, 4
	SND_RET
Snd5E_Ch3_6063:
	RELEASE 8, 7
	RELEASE_VOL 4
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	WAVE 3
	NOTE E_, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE G#, 2
	WAVE 1
	NOTE F#, 2
	WAVE 3
	NOTE F#, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE F#, 2
	LOOP_END 2
	LOOP_START
	WAVE 1
	NOTE F#, 2
	WAVE 3
	NOTE F#, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE F#, 2
	LOOP_END 3
	WAVE 1
	NOTE E_, 2
	REST 2
	NOTE D#, 4
	LOOP_START
	WAVE 1
	NOTE G#, 2
	WAVE 3
	NOTE G#, 2
	WAVE 1
	NOTE D#, 2
	WAVE 3
	NOTE G_, 2
	WAVE 1
	NOTE A#, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE D#, 2
	WAVE 3
	NOTE C_, 2
	LOOP_END 2
	WAVE 1
	RELEASE 4, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	RELEASE $0A, 5
	OCTAVE 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	REST 2
	VOICE $05, 1, 2, 2, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	RELEASE 9, 6
	DETUNE $FF
	WAVE 5
	NOTE C_, 3
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE_VOL 0
	NOTE E_, 2
	RELEASE_VOL 6
	NOTE G_, 2
	RELEASE_VOL 0
	NOTE D_, 2
	RELEASE_VOL 6
	NOTE G_, 2
	RELEASE 0, 0
	NOTE C_, 4
	VOICE $05, 1, 2, 8, 4
	NOTE C_HI, 4
	RELEASE 3, 2
	NOTE G_, 6
	RELEASE 9, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	REST 6
	OCTAVE 2
	NOTE E_, 2
	WAVE 3
	NOTE E_, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE G#, 2
	WAVE 1
	NOTE F#, 2
	WAVE 3
	NOTE F#, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE F#, 2
	WAVE 1
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	WAVE 3
	NOTE F#, 2
	WAVE 1
	NOTE B_, 2
	WAVE 3
	NOTE D#, 2
	WAVE 1
	OCTAVE 2
	RELEASE 3, 2
	NOTE E_, 6
	RELEASE $0A, 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE E_, 2
	SND_RET
Snd5E_Ch3_613D:
	VOICE $05, 4, 4, 12, 6
	REST 6
	VIBRATO 4, 4, 0
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 6
	VOICE $05, 4, 4, 13, 4
	RELEASE_VOL 0
	DETUNE $00
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 2
	VOICE $05, 4, 4, 9, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 2
	VOICE $05, 1, 2, 5, 4
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	NOTE E_, 2
	REST 2
	RELEASE 9, 4
	WAVE 5
	ATTEN 1
	OCTAVE 3
	NOTE E_, 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 2, 3
	NOTE G#, 2
	RELEASE 9, 2
	NOTE B_, 2
	RELEASE 2, 3
	NOTE F#, 2
	RELEASE 9, 2
	NOTE B_, 2
	RELEASE 9, 6
	NOTE E_, 4
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE E_, 3
	SND_RET

Snd5E_Drm:
	SND_CALL Snd5E_Drm_61A8
Snd5E_Drm_61A1:
	SND_CALL Snd5E_Drm_61AE
	SND_CALL Snd5E_Drm_61E3
	SND_END
Snd5E_Drm_61A8:
	LEN_UNIT $05
	REST 0
	REST $0C
	DRUM 6, 4
	SND_RET
Snd5E_Drm_61AE:
	LOOP_START
	DRUM 6, 2
	DRUM 5, 2
	LOOP_END 3
	DRUM 6, 2
	DRUM 5, 2
	LOOP_START
	DRUM 6, 2
	DRUM 5, 2
	LOOP_END 10
	DRUM 6, 4
	DRUM 6, 4
	LOOP_START
	DRUM 6, 2
	DRUM 5, 2
	LOOP_END 8
	LOOP_START
	DRUM 3, 2
	DRUM 5, 2
	LOOP_END 4
	DRUM 5, 3
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 4
	DRUM 6, 4
	DRUM 5, 4
	REST $0C
	REST $0C
	DRUM 4, 4
	DRUM 6, 0
	REST 6
	DRUM 6, 2
	DRUM 6, 8
	LOOP_START
	DRUM 3, 2
	DRUM 5, 2
	LOOP_END 8
	DRUM 3, 6
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 2
	SND_RET
Snd5E_Drm_61E3:
	LEN_UNIT $0A
	REST $0A
	REST 0
	DRUM 6, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	REST $0A
	REST 4
	DRUM 6, 2
	REST 0
	SND_RET

Snd5F_Ch2:
	TEMPO $0A
	VOICE $05, 4, 7, 10, 6
	RELEASE_VOL 2
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 6
	NOTE A_, 2
	RELEASE $0A, 6
	RELEASE_VOL 1
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	SND_SEGNO
	SND_CALL Snd5F_Ch2_6280
	NOTE A_, 3
	NOTE G#, 1
	NOTE A_, 6
	SND_CALL Snd5F_Ch2_6280
	NOTE A_, 3
	NOTE G#, 1
	NOTE A_, 6
	TRANSPOSE_UP 2
	SND_CALL Snd5F_Ch2_6280
	TRANSPOSE_UP 0
	RELEASE 9, 6
	NOTE A_, 2
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	REST 3
	NOTE D#, 2
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	REST 3
	VIBRATO_SEMI 3
	DUTY 0
	DUTY_STEP 8, 1
	ATTEN 1
	LEN_UNIT $01
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 4
	NOTE E_, 3
	ATTEN 0
	LEN_UNIT $05
	RELEASE $0A, 6
	RELEASE_VOL 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	REST 2
	SND_CALL Snd5F_Ch2_6280
	NOTE A_, 3
	NOTE G#, 1
	NOTE A_, 6
	TRANSPOSE_UP 2
	SND_CALL Snd5F_Ch2_6280
	TRANSPOSE_UP 0
	NOTE A#, 3
	NOTE A_, 1
	NOTE A#, 6
	RELEASE 9, 6
	RELEASE_VOL 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	VIBRATO_SEMI 3
	LOOP_START
	RELEASE 9, 6
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	TRANSPOSE_DOWN $0C
	ATTEN 6
	LOOP_END 2
	TRANSPOSE_DOWN 0
	ATTEN 0
	VIBRATO 4, 2, 0
	DUTY_STEP 0, 1
	ATTEN 1
	RELEASE $0A, 6
	RELEASE_VOL 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 0
	SND_LOOP
Snd5F_Ch2_6280:
	VOICE $05, 8, 8, 9, 6
	VIBRATO 4, 2, 0
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	SND_RET

Snd5F_Ch1:
	VOICE $01, 8, 4, 9, 6
	DETUNE $01
	LOOP_START
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 4
	NOTE C_, 3
	NOTE D_, 3
	LOOP_END 4
	VOICE $05, 8, 4, 10, 7
	RELEASE_VOL 1
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_, 2
	REST 6
	SND_SEGNO
	DETUNE $00
	RELEASE 8, 7
	VIBRATO 4, 2, 2
	LOOP_START
	OCTAVE 3
	NOTE F_, 3
	NOTE E_, 1
	NOTE F_, 6
	REST 6
	LOOP_END 2
	RELEASE 9, 7
	NOTE F#, 2
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	REST 3
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	REST 3
	VIBRATO_SEMI 3
	DUTY 0
	ATTEN 1
	LEN_UNIT $01
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 4
	NOTE E_, 3
	ATTEN 0
	LEN_UNIT $05
	RELEASE $0A, 7
	RELEASE_VOL 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	REST 2
	REST 6
	DUTY 8
	RELEASE 8, 7
	VIBRATO 4, 0, 1
	LOOP_START
	OCTAVE 3
	NOTE F_, 3
	NOTE E_, 1
	NOTE F_, 6
	REST 6
	TRANSPOSE_UP 2
	LOOP_END 2
	TRANSPOSE_UP 0
	DETUNE $02
	PAN_LEFT 0
	ATTEN 2
	RELEASE 9, 6
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	TRANSPOSE_DOWN $0C
	ATTEN 4
	PAN_RIGHT 0
	RELEASE 9, 6
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 1
	PAN_BOTH 0
	TRANSPOSE_DOWN 0
	VIBRATO 4, 2, 0
	DETUNE $00
	ATTEN 1
	RELEASE $0A, 6
	RELEASE_VOL 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE D#, 2
	ATTEN 3
	NOTE E_, 2
	DETUNE $00
	VIBRATO 4, 0, 2
	DUTY 8
	OCTAVE 3
	NOTE C_, 6
	ATTEN 0
	SND_LOOP

Snd5F_Ch3:
	VOICE $05, 7, 2, 10, 7
	RELEASE_VOL 6
	DETUNE $02
	OCTAVE 3
	NOTE C_, 6
	NOTE D_, 2
	NOTE E_, 6
	NOTE F_, 2
	ATTEN 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	VOLUME $02
	RELEASE 7, 7
	RELEASE_VOL 6
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	OCTAVE 3
	NOTE C_, 2
	SND_SEGNO
	VOICE $05, 1, 2, 10, 7
	RELEASE_VOL 4
	VIBRATO 7, 0, 1
	LOOP_START
	OCTAVE 3
	NOTE F_, 4
	NOTE C_, 4
	LOOP_END 3
	OCTAVE 2
	NOTE F_, 4
	NOTE F#, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE C_, 4
	VOLUME $02
	RELEASE $0A, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	REST 2
	RELEASE 7, 7
	WAVE 4
	RELEASE_VOL 6
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE C_, 2
	VOICE $05, 1, 2, 10, 7
	RELEASE_VOL 4
	OCTAVE 3
	NOTE F_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE F_, 4
	NOTE F#, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE G_, 4
	REST 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE C_, 6
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	VOLUME $02
	VIBRATO 5, 0, 4
	WAVE $0A
	OCTAVE 4
	NOTE C_, 6
	SND_LOOP

Snd5F_Drm:
	LEN_UNIT $05
	REST 0
	REST 0
	SND_SEGNO
	LOOP_START
	REST 2
	DRUM 5, 2
	LOOP_END 12
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	REST 8
	LOOP_START
	REST 2
	DRUM 5, 2
	LOOP_END 8
	DRUM 6, 4
	REST $0C
	REST 0
	SND_LOOP

Snd60_Ch2:
	TEMPO $0D
	SND_SEGNO
	SND_CALL Snd60_Ch2_6434
	SND_CALL Snd60_Ch2_647B
	OCTAVE 5
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	VOICE $04, 8, 7, 10, 7
	RELEASE_VOL 2
	OCTAVE 6
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 5
	NOTE B_, 2
	OCTAVE 6
	NOTE C_, 2
	REST 2
	OCTAVE 5
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	NOTE F_, 2
	REST 2
	NOTE E_, 2
	NOTE D_, 2
	REST 2
	NOTE E_, 2
	NOTE F_, 2
	REST 2
	NOTE F#, 2
	NOTE G_, 2
	REST 4
	RELEASE $0C, 6
	VIBRATO 4, 0, 4
	OCTAVE 3
	NOTE G_, 6
	SND_CALL Snd60_Ch2_6434
	SND_CALL Snd60_Ch2_647B
	OCTAVE 5
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	VOICE $04, 8, 8, 10, 7
	RELEASE_VOL 3
	NOTE A_, 2
	REST 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE B_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	ATTEN 1
	RELEASE_VOL 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F_, 2
	REST 2
	NOTE F#, 2
	NOTE G_, 2
	REST 4
	ATTEN 0
	RELEASE $0C, 7
	VIBRATO 4, 0, 4
	OCTAVE 3
	NOTE G_, 6
	SND_LOOP
Snd60_Ch2_6434:
	VOICE $04, 4, 8, 8, 3
	RELEASE_VOL 6
	VIBRATO_OFF
	DUTY_STEP 8, 1
	TRANSPOSE_DOWN 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	ATTEN 7
	RELEASE 8, 3
	NOTE E_, 2
	RELEASE_VOL 6
	ATTEN 0
	NOTE G_, 2
	NOTE F_, 2
	REST 2
	NOTE E_, 2
	NOTE F_, 2
	REST 2
	NOTE F#, 2
	NOTE A_, 2
	RELEASE 8, 3
	ATTEN 7
	NOTE A_, 2
	REST 2
	ATTEN 0
	RELEASE 0, 0
	DETUNE $01
	NOTE G_, 4
	DUTY_STEP 0, 0
	VIBRATO 4, 0, 1
	ATTEN 7
	NOTE G_, 3
	ATTEN 0
	VOICE $01, 8, 2, 15, 2
	PAN_RIGHT 0
	DETUNE $FE
	OCTAVE 5
	NOTE F_, 4
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 1
	DETUNE $00
	SND_RET
Snd60_Ch2_647B:
	VOICE $04, 8, 6, 14, 2
	VIBRATO_OFF
	LEN_UNIT $02
	REST 6
	SND_RET

Snd60_Ch1:
	SND_SEGNO
	SND_CALL Snd60_Ch1_64DA
	SND_CALL Snd60_Ch1_651B
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	SND_CALL Snd60_Ch1_6524
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN_UNIT $01
	RELEASE $0F, 2
	OCTAVE 5
	DUTY_STEP 0, 0
	ATTEN 1
	NOTE C#, 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE D_, 3
	ATTEN 0
	SND_CALL Snd60_Ch1_651B
	OCTAVE 3
	NOTE F_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE A#, 2
	NOTE B_, 2
	REST $0A
	SND_CALL Snd60_Ch1_64DA
	SND_CALL Snd60_Ch1_651B
	OCTAVE 4
	NOTE F_, 2
	REST 8
	NOTE F_, 2
	NOTE G_, 2
	REST 8
	NOTE G_, 2
	DETUNE $FF
	DUTY_STEP 0, 0
	DUTY 8
	RELEASE $0F, 1
	ATTEN 1
	OCTAVE 5
	NOTE E_, 3
	REST 2
	NOTE E_, 2
	NOTE F_, 2
	REST 2
	NOTE F#, 2
	NOTE G_, 2
	REST 9
	DETUNE $00
	SND_LOOP
Snd60_Ch1_64DA:
	VOICE $04, 4, 4, 8, 3
	TRANSPOSE_DOWN 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE E_, 2
	VOICE $04, 8, 3, 9, 6
	DUTY_STEP 0, 1
	VIBRATO_OFF
	RELEASE_VOL 1
	REST 2
	OCTAVE 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	LEN_UNIT $01
	RELEASE $0F, 2
	DUTY_STEP 0, 0
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	SND_RET
Snd60_Ch1_651B:
	VOICE $04, 0, 4, 13, 2
	DUTY_STEP 4, 1
	TRANSPOSE_DOWN 2
	SND_RET
Snd60_Ch1_6524:
	VOICE $04, 8, 3, 9, 6
	DUTY_STEP 0, 1
	VIBRATO_OFF
	RELEASE_VOL 1
	SND_RET

Snd60_Ch3:
	SND_SEGNO
	VOICE $04, 1, 2, 12, 7
	RELEASE_VOL 6
	VIBRATO 4, 3, 3
	OCTAVE 2
	NOTE A#, 6
	NOTE F_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE F_, 6
	NOTE A#, 6
	NOTE F_, 6
	NOTE A#, 6
	NOTE F_, 6
	NOTE A#, 6
	NOTE F_, 6
	NOTE B_, 6
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE F_, 2
	REST $0A
	OCTAVE 2
	NOTE A#, 6
	NOTE F_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	NOTE F_, 6
	OCTAVE 2
	NOTE A#, 6
	NOTE F_, 6
	NOTE D_, 6
	NOTE F_, 6
	RELEASE $0B, 7
	RELEASE_VOL 4
	OCTAVE 3
	NOTE C_, 2
	REST 8
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	REST 8
	NOTE F_, 2
	ATTEN 1
	RELEASE_VOL 6
	WAVE 3
	OCTAVE 4
	NOTE A#, 2
	REST 2
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 2
	REST 2
	NOTE C#, 2
	NOTE D_, 2
	REST 4
	ATTEN 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 4
	NOTE G_, 1
	NOTE A_, 1
	SND_LOOP

Snd60_Drm:
	SND_SEGNO
	SND_CALL Snd60_Drm_65AD
	LOOP_START
	DRUM 6, 4
	DRUM 1, 2
	LOOP_END 6
	DRUM 6, 6
	LEN_UNIT $03
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_CALL Snd60_Drm_65AD
	LOOP_START
	DRUM 5, 4
	DRUM 6, 2
	DRUM 6, 4
	DRUM 1, 2
	LOOP_END 2
	DRUM 6, $0A
	DRUM 6, 2
	DRUM 6, 6
	LEN_UNIT $03
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_LOOP
Snd60_Drm_65AD:
	LEN_UNIT $04
	LOOP_START
	DRUM 6, 4
	DRUM 1, 2
	LOOP_END 5
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 4
	DRUM 1, 2
	LEN_UNIT $03
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $04
	SND_RET

Snd61_Ch2:
	TEMPO $10
	VOICE $06, 4, 6, 10, 6
	RELEASE_VOL 2
	TRANSPOSE_UP $0C
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	REST 1
	NOTE C#, 1
	REST 1
	NOTE C_, 1
	REST 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 3
	LEN_UNIT $01
	OCTAVE 4
	NOTE A#, 2
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 6
	ATTEN 0
	REST 6
	VOICE $06, 4, 5, 10, 6
	RELEASE_VOL 2
	TRANSPOSE_UP $0C
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_SEGNO
	LOOP_START
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	LOOP_END 5
	LOOP_START
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	LOOP_END 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	SND_LOOP

Snd61_Ch1:
	VOICE $06, 0, 5, 10, 6
	RELEASE_VOL 1
	TRANSPOSE_UP $0C
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	REST 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 3
	LEN_UNIT $01
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 6
	ATTEN 0
	REST 6
	VOICE $01, 4, 2, 10, 6
	RELEASE_VOL 1
	TRANSPOSE_UP $0C
	DETUNE $02
	OCTAVE 3
	NOTE E_, 7
	NOTE F#, 6
	NOTE G_, 6
	SND_SEGNO
	LOOP_START
	OCTAVE 3
	NOTE G#, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 6
	LOOP_END 5
	LOOP_START
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 6
	LOOP_END 3
	LOOP_START
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 6
	LOOP_END 2
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE F#, 6
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C#, 6
	NOTE D#, 6
	NOTE E_, 6
	OCTAVE 3
	NOTE G#, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE G#, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE C#, 6
	OCTAVE 3
	NOTE G#, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 6
	NOTE C#, 6
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 6
	SND_LOOP

Snd61_Ch3:
	VOICE $06, 5, 2, 10, 6
	RELEASE_VOL 6
	TRANSPOSE_UP $0C
	DETUNE $FF
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	OCTAVE 3
	NOTE C#, 1
	REST 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE D#, 3
	LEN_UNIT $01
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 4
	REST 6
	DETUNE $00
	VOICE $06, 4, 2, 10, 7
	TRANSPOSE_UP 0
	OCTAVE 1
	NOTE B_, 3
	LEN_UNIT $01
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	LEN_UNIT $06
	RELEASE $0C, 6
	RELEASE_VOL 6
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE F#, 4
	OCTAVE 1
	NOTE B_, 4
	LOOP_END 4
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE D#, 2
	SND_LOOP

Snd61_Drm:
	LEN_UNIT $06
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 3, 3
	DRUM 1, 2
	REST 4
	SND_SEGNO
	REST 2
	DRUM 5, 2
	SND_LOOP

Snd62_Ch2:
	TEMPO $20
	VOICE $05, 8, 2, 14, 1
	VIBRATO 4, 1, 0
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	ATTEN 0
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	ATTEN 1
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	ATTEN 0
	LOOP_END 2
	SND_LOOP

Snd62_Ch1:
	VOICE $01, 8, 2, 11, 6
	DETUNE $01
	RELEASE_VOL 1
	VIBRATO_SEMI 2
	AUTOPAN_BOTH 0
	REST 2
	SND_SEGNO
	LOOP_START
	OCTAVE 3
	NOTE G#, $0A
	OCTAVE 4
	NOTE C_, $0A
	NOTE D#, $0A
	NOTE C_, $0A
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE A#, $0A
	OCTAVE 4
	NOTE C#, $0A
	NOTE D#, $0A
	NOTE C#, $0A
	LOOP_END 2
	SND_LOOP

Snd62_Ch3:
	VOICE $05, 2, 2, 11, 6
	RELEASE_VOL 6
	VIBRATO_SEMI 3
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 1
	REST 3
	ATTEN 1
	NOTE D#, 1
	REST 5
	LEN_UNIT $01
	RELEASE 9, 6
	VIBRATO_OFF
	OCTAVE 6
	NOTE D_, 2
	RELEASE_VOL 6
	NOTE D#, 8
	ATTEN 0
	LEN_UNIT $05
	RELEASE $0B, 4
	VIBRATO_SEMI 3
	OCTAVE 4
	NOTE D#, 2
	RELEASE_VOL 6
	NOTE F_, 2
	NOTE D#, 1
	REST 3
	ATTEN 1
	NOTE D#, 1
	REST 5
	LEN_UNIT $01
	RELEASE 9, 6
	VIBRATO_OFF
	OCTAVE 6
	NOTE D_, 2
	RELEASE_VOL 6
	NOTE D#, 8
	ATTEN 0
	LEN_UNIT $05
	RELEASE $0B, 4
	VIBRATO_SEMI 3
	OCTAVE 4
	NOTE D#, 2
	RELEASE_VOL 6
	SND_LOOP

Snd62_Drm:
	SND_END

Snd63_Ch2:
	TEMPO $0F
	TRANSPOSE_DOWN 3
	VOICE $05, 8, 5, 10, 6
	VIBRATO 4, 2, 1
	DUTY_STEP 0, 1
	ATTEN 2
	OCTAVE 4
	NOTE G#, 1
	ATTEN 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 3
	NOTE C#, 1
	RELEASE $0A, 0
	NOTE D_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	VOICE $05, 4, 6, 9, 6
	VIBRATO_SEMI 3
	DUTY_STEP 8, 1
	ATTEN 4
	OCTAVE 2
	NOTE E_, 2
	RELEASE 9, 6
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	RELEASE_VOL 2
	PAN_BOTH 0
	NOTE D_, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	SND_END

Snd63_Ch1:
	VOICE $05, 8, 4, 10, 6
	TRANSPOSE_DOWN 3
	VIBRATO 4, 2, 2
	ATTEN 2
	OCTAVE 4
	NOTE F_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 3
	NOTE F_, 1
	RELEASE_VOL 1
	NOTE F#, 2
	NOTE A_, 2
	DETUNE $FF
	NOTE G_, 2
	NOTE G_, 2
	DETUNE $00
	NOTE C_HI, 2
	NOTE G_, 2
	ATTEN 3
	OCTAVE 2
	NOTE C#, 2
	ATTEN 0
	VOICE $01, 8, 5, 9, 6
	DUTY_STEP 4, 1
	AUTOPAN 0
	OCTAVE 5
	NOTE A_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 4
	NOTE G#, 3
	NOTE A_, 3
	RELEASE_VOL 2
	LEN_UNIT $05
	NOTE F#, 2
	REST 2
	VOLUME $06
	OCTAVE 2
	NOTE D_, 2
	REST 2
	SND_END

Snd63_Ch3:
	VOICE $05, 4, 2, 8, 7
	RELEASE_VOL 4
	TRANSPOSE_DOWN 3
	VIBRATO 4, 2, 4
	REST 4
	OCTAVE 2
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE G_, 4
	RELEASE $0A, 6
	RELEASE_VOL 6
	NOTE A_, 2
	VIBRATO 4, 2, 2
	RELEASE 7, 7
	OCTAVE 2
	NOTE A_, 6
	RELEASE_VOL 6
	NOTE D_, 2
	REST 2
	OCTAVE 1
	NOTE F#, 2
	REST 2
	SND_END

Snd63_Drm:
	LEN_UNIT $01
	DRUM 1, 3
	DRUM 1, 3
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	LEN_UNIT $05
	LOOP_START
	DRUM 3, 2
	DRUM 6, 2
	LOOP_END 4
	DRUM 3, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 4
	DRUM 3, 3
	DRUM 2, 1
	SND_END

Snd64_Ch2:
	TEMPO $05
	VOICE $05, 4, 8, 9, 7
	TRANSPOSE_DOWN 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	REST 3
	VOICE $05, 4, 7, 5, 6
	VIBRATO 4, 3, 2
	RELEASE_VOL 3
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	SND_SEGNO
	SND_CALL Snd64_Ch2_69A6
	RELEASE $0A, 7
	NOTE C_, 4
	RELEASE_VOL 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 2, 7
	NOTE D_, 4
	ATTEN 2
	RELEASE $0A, 7
	OCTAVE 5
	NOTE C_, 4
	RELEASE_VOL 2
	OCTAVE 4
	NOTE A#, 2
	RELEASE 2, 7
	NOTE D_, $0C
	RELEASE 8, 2
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 0
	RELEASE $0A, 7
	RELEASE_VOL 2
	OCTAVE 4
	NOTE E_, 2
	REST 1
	RELEASE 2, 7
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 6
	RELEASE 4, 6
	NOTE A_, 2
	RELEASE_VOL 3
	NOTE A#, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	RELEASE 0, 0
	NOTE C_, 0
	VIBRATO 4, 0, 2
	DUTY_STEP 0, 0
	RELEASE 9, 7
	NOTE C_, $0A
	RELEASE 8, 6
	RELEASE_VOL 2
	DUTY_STEP 0, 1
	VIBRATO 4, 4, 2
	DUTY 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	SND_CALL Snd64_Ch2_69A6
	RELEASE $0A, 7
	OCTAVE 4
	NOTE C_, 4
	RELEASE_VOL 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 2, 7
	OCTAVE 4
	NOTE D_, 4
	RELEASE $0A, 7
	RELEASE_VOL 2
	NOTE A_, 2
	NOTE F_, 2
	RELEASE 2, 7
	NOTE D_, $0E
	VOICE $05, 4, 8, 10, 2
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 1
	NOTE A#, 1
	OCTAVE 3
	ATTEN 0
	NOTE C_, 1
	RELEASE_VOL 2
	NOTE D_, 2
	VOICE $05, 8, 10, 11, 2
	RELEASE_VOL 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	REST 2
	VOICE $05, 4, 7, 10, 7
	RELEASE_VOL 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 4, 7
	RELEASE_VOL 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	VOICE $05, 4, 8, 10, 7
	LOOP_START
	RELEASE_VOL 2
	OCTAVE 4
	NOTE F_, 2
	ATTEN 1
	RELEASE 6, 7
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	RELEASE $0A, 7
	RELEASE_VOL 2
	NOTE F_, 2
	RELEASE 6, 7
	NOTE G#, 8
	ATTEN 0
	RELEASE $0A, 7
	RELEASE_VOL 2
	NOTE G#, 2
	LOOP_END 2
	VOICE $05, 4, 7, 4, 0
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	REST 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	VOICE $05, 4, 8, 10, 7
	VIBRATO 4, 2, 1
	NOTE A#, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	VIBRATO 3, 3, 1
	RELEASE 6, 7
	OCTAVE 3
	NOTE A#, 6
	NOTE G_, $0A
	VOICE $05, 4, 7, 9, 7
	RELEASE_VOL 2
	OCTAVE 3
	NOTE E_, 2
	REST 1
	NOTE C_, 1
	RELEASE 6, 7
	NOTE C_, 6
	VOICE $05, 4, 6, 10, 7
	VIBRATO 4, 3, 2
	RELEASE_VOL 3
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	SND_LOOP
Snd64_Ch2_69A6:
	RELEASE $0A, 7
	OCTAVE 4
	NOTE D_, 4
	RELEASE_VOL 2
	OCTAVE 3
	NOTE A_, 2
	RELEASE 2, 7
	OCTAVE 4
	NOTE C_, 6
	RELEASE 8, 2
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 4
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	RELEASE 5, 6
	RELEASE_VOL 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE D_, 4
	SND_RET

Snd64_Ch1:
	VOICE $05, 0, 4, 9, 7
	TRANSPOSE_DOWN 1
	DETUNE $FF
	VIBRATO_SEMI 2
	AUTOPAN 0
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	REST 3
	VOICE $05, 4, 5, 10, 7
	DETUNE $02
	PAN_RIGHT 0
	VIBRATO 4, 0, 2
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	DETUNE $00
	PAN_BOTH 0
	SND_SEGNO
	VOICE $05, 0, 4, 10, 7
	VIBRATO 4, 2, 0
	LOOP2_START
	LOOP_START
	RELEASE $0A, 7
	REST 2
	OCTAVE 2
	NOTE A_, 4
	RELEASE_VOL 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	LOOP_END 2
	TRANSPOSE_DOWN 0
	LOOP2_END 2
	TRANSPOSE_DOWN 1
	RELEASE 2, 7
	ATTEN 1
	OCTAVE 4
	NOTE G_, 0
	NOTE G#, 0
	NOTE A_, 0
	RELEASE 9, 7
	ATTEN 0
	OCTAVE 3
	NOTE A#, 4
	NOTE G_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	LOOP_START
	RELEASE $0A, 7
	REST 2
	OCTAVE 2
	NOTE A_, 4
	RELEASE_VOL 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	LOOP_END 2
	RELEASE $0A, 7
	REST 2
	NOTE A#, 4
	RELEASE_VOL 1
	NOTE A#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A#, 2
	RELEASE $0A, 7
	DETUNE $FF
	OCTAVE 3
	NOTE C_, 4
	DETUNE $00
	OCTAVE 2
	NOTE A#, 2
	RELEASE 4, 7
	DETUNE $01
	OCTAVE 3
	NOTE D_, 8
	DETUNE $00
	NOTE D#, 1
	NOTE E_, 3
	VOICE $05, 4, 6, 10, 7
	RELEASE_VOL 1
	OCTAVE 4
	NOTE F_, 2
	REST 4
	RELEASE $0B, 2
	RELEASE_VOL 1
	OCTAVE 3
	NOTE A#, 2
	REST 2
	RELEASE $0A, 7
	RELEASE_VOL 1
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	VOICE $05, 4, 5, 9, 6
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 4
	VOICE $05, 4, 6, 10, 7
	RELEASE_VOL 1
	OCTAVE 2
	NOTE A_, 2
	NOTE C_, 1
	NOTE F_, 1
	RELEASE_VOL 1
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A#, 2
	VOICE $05, 8, 5, 11, 2
	ATTEN 2
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 0
	LEN_UNIT $01
	NOTE F#, 3
	NOTE F_, 3
	ATTEN 1
	NOTE D#, 3
	NOTE C#, 3
	ATTEN 2
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	ATTEN 3
	NOTE G#, 2
	NOTE F#, 2
	ATTEN 0
	VOICE $05, 4, 6, 10, 7
	RELEASE_VOL 1
	OCTAVE 2
	NOTE A_, 2
	NOTE C_, 1
	NOTE F_, 1
	RELEASE_VOL 1
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A#, 2
	VOICE $05, 8, 5, 11, 2
	ATTEN 2
	OCTAVE 5
	NOTE A#, 1
	NOTE G#, 1
	ATTEN 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 0
	LEN_UNIT $01
	NOTE D#, 3
	NOTE C#, 3
	ATTEN 1
	NOTE C_, 3
	OCTAVE 4
	NOTE A#, 3
	ATTEN 2
	NOTE G#, 2
	NOTE F#, 2
	ATTEN 3
	NOTE F_, 2
	NOTE D#, 2
	ATTEN 0
	VOICE $05, 4, 6, 0, 0
	OCTAVE 3
	NOTE C_, 0
	NOTE G_, 8
	VOICE $05, 4, 6, 10, 6
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE G_, 6
	NOTE E_, 2
	VOICE $05, 8, 4, 11, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	ATTEN 1
	LEN_UNIT $01
	OCTAVE 5
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	LOOP_START
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	LOOP_END 3
	ATTEN 0
	SND_LOOP

Snd64_Ch3:
	VOICE $05, 5, 2, 0, 0
	VIBRATO 4, 3, 4
	TRANSPOSE_DOWN 1
	OCTAVE 2
	NOTE G_, 0
	RELEASE 9, 7
	RELEASE_VOL 6
	OCTAVE 3
	NOTE C_, 2
	REST 2
	WAVE 4
	RELEASE 4, 7
	OCTAVE 3
	NOTE C_, $0C
	SND_SEGNO
	SND_CALL Snd64_Ch3_6BE9
	NOTE C_HI, 2
	NOTE F#, 2
	RELEASE 9, 7
	OCTAVE 3
	NOTE D_, 4
	RELEASE_VOL 6
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 6
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE $0A, 7
	RELEASE_VOL 6
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	RELEASE 9, 4
	VIBRATO 4, 0, 3
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	RELEASE 7, 7
	NOTE F#, 4
	RELEASE 9, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 2
	RELEASE 7, 7
	NOTE G_, 4
	RELEASE 9, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	RELEASE 7, 7
	OCTAVE 3
	NOTE C_, 4
	RELEASE 9, 4
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	VIBRATO 4, 3, 4
	SND_CALL Snd64_Ch3_6BE9
	RELEASE $0A, 5
	NOTE F#, 4
	RELEASE $0A, 7
	OCTAVE 2
	NOTE D_, 4
	RELEASE_VOL 6
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	VOICE $05, 7, 2, 10, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE G_, 2
	REST 4
	NOTE C_HI, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 9, 7
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE G_, 4
	VOICE $05, 7, 2, 10, 7
	RELEASE_VOL 6
	LOOP_START
	WAVE 5
	OCTAVE 2
	NOTE F_, 2
	WAVE 7
	RELEASE $0A, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE_VOL 6
	NOTE F_, 2
	RELEASE 6, 7
	NOTE F#, 8
	RELEASE 9, 7
	RELEASE_VOL 6
	NOTE C_, 2
	LOOP_END 2
	RELEASE 0, 0
	WAVE 5
	OCTAVE 2
	NOTE C_, 0
	NOTE C_HI, 8
	NOTE C_, 0
	NOTE C_, $0A
	WAVE 7
	RELEASE $0A, 7
	RELEASE_VOL 6
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	REST 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 3, 7
	NOTE C_, 6
	OCTAVE 2
	RELEASE $0A, 7
	RELEASE_VOL 6
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_LOOP
Snd64_Ch3_6BE9:
	VOICE $05, 7, 2, 10, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE F_, 2
	RELEASE $0A, 7
	OCTAVE 3
	NOTE C_, 4
	RELEASE_VOL 6
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE F#, 2
	RELEASE $0A, 7
	OCTAVE 3
	NOTE D_, 4
	RELEASE_VOL 6
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	RELEASE $0A, 7
	OCTAVE 3
	NOTE D_, 4
	RELEASE_VOL 6
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_RET

Snd64_Drm:
	LEN_UNIT $01
	LOOP_START
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	LOOP_END 4
	LEN_UNIT $05
	DRUM 4, 4
	LEN_UNIT $01
	LOOP_START
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	LOOP_END 3
	SND_SEGNO
	LEN_UNIT $05
	LOOP_START
	REST 2
	DRUM 1, 2
	REST 2
	DRUM 1, 2
	LOOP_END 12
	DRUM 3, 4
	DRUM 6, 2
	DRUM 3, 6
	DRUM 6, 2
	DRUM 3, 6
	DRUM 6, 2
	DRUM 3, 4
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	REST 2
	DRUM 1, 2
	REST 2
	DRUM 1, 2
	LOOP_END 7
	DRUM 6, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 4
	DRUM 2, 2
	DRUM 2, 2
	REST 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 3, 8
	DRUM 3, 4
	DRUM 3, 4
	DRUM 6, 4
	DRUM 6, 2
	DRUM 3, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 6, 4
	DRUM 6, 2
	DRUM 3, 4
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 8
	LEN_UNIT $01
	LOOP_START
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	LOOP_END 4
	LEN_UNIT $05
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 6
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 4
	LEN_UNIT $01
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 2
	LEN_UNIT $05
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_LOOP

Snd65_Ch2:
	TEMPO $05
	TRANSPOSE_UP 0
	VOICE $03, 4, 9, 8, 7
	VIBRATO 4, 4, 1
	DUTY_STEP 8, 1
	VOICE $03, 4, 7, 10, 7
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 4
	NOTE F#, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 4
	NOTE F#, 2
	NOTE F_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE G_, 2
	REST 4
	OCTAVE 2
	NOTE G_, 6
	VOICE $03, 8, 7, 10, 7
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	REST 4
	VOICE $03, 4, 7, 10, 7
	RELEASE_VOL 2
	NOTE C_HI, 3
	REST 3
	VOICE $03, 8, 7, 10, 7
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 4
	NOTE G_, 2
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	REST 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 4
	NOTE E_, 2
	REST 4
	NOTE E_, 4
	NOTE D#, 2
	NOTE E_, 4
	RELEASE 8, 0
	RELEASE_VOL 1
	NOTE A_, 8
	VOICE $03, 4, 7, 10, 7
	NOTE G_, $0C
	NOTE F_, 4
	REST 2
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 2
	NOTE A_, 4
	RELEASE_VOL 4
	OCTAVE 4
	NOTE C_, 6
	RELEASE $0A, 7
	NOTE D_, 6
	NOTE D#, 2
	NOTE E_, 4
	NOTE D#, 2
	NOTE E_, 4
	RELEASE_VOL 3
	NOTE A_, 6
	RELEASE $0A, 7
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	REST 4
	NOTE C_, 2
	REST 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	REST 4
	OCTAVE 4
	NOTE G_, 8
	NOTE E_, 2
	REST 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 2
	REST 4
	OCTAVE 4
	NOTE C_, 6
	RELEASE 8, 6
	RELEASE_VOL 3
	NOTE C_HI, 2
	REST 6
	NOTE C_HI, 2
	REST 8
	NOTE C_HI, 2
	REST 6
	VOLUME $09
	OCTAVE 3
	NOTE C_, 4
	REST 0
	REST 4
	VIBRATO_OFF
	SND_JUMP Snd71_Ch2

Snd65_Ch1:
	VOICE $03, 8, 6, 9, 7
	TRANSPOSE_UP 0
	DUTY_STEP 8, 1
	VIBRATO 4, 4, 2
	VOICE $03, 4, 5, 10, 7
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	DETUNE $FD
	OCTAVE 2
	NOTE G_, 4
	DETUNE $00
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 4
	NOTE A#, 2
	DETUNE $FD
	OCTAVE 2
	NOTE G_, 4
	DETUNE $00
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE A_, 4
	NOTE B_, 2
	REST 4
	DETUNE $FD
	OCTAVE 2
	NOTE G_, 8
	DETUNE $00
	VOICE $03, 8, 5, 10, 6
	OCTAVE 3
	NOTE C_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE G_, 2
	REST 4
	VOICE $03, 4, 5, 10, 7
	RELEASE_VOL 2
	OCTAVE 4
	NOTE E_, 3
	REST 3
	VOICE $03, 8, 5, 10, 6
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE G_, 2
	OCTAVE 5
	REST 4
	OCTAVE 4
	REST 2
	REST 4
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	DETUNE $FE
	RELEASE 8, 0
	RELEASE_VOL 1
	OCTAVE 3
	NOTE A_, 8
	VOICE $03, 4, 7, 10, 7
	NOTE G_, $0C
	NOTE F_, 4
	REST 2
	DETUNE $00
	RELEASE_VOL 3
	OCTAVE 3
	NOTE D_, 6
	NOTE D_, 6
	NOTE D#, 6
	NOTE C_, 6
	RELEASE $0A, 7
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	RELEASE_VOL 3
	OCTAVE 2
	NOTE A_, 6
	RELEASE 9, 7
	OCTAVE 3
	NOTE C_, 8
	RELEASE $0A, 7
	RELEASE_VOL 3
	NOTE E_, 6
	NOTE E_, 6
	OCTAVE 2
	NOTE A_, 6
	NOTE A_, 4
	RELEASE $0A, 7
	OCTAVE 4
	NOTE E_, 8
	NOTE C_, 2
	REST 4
	OCTAVE 3
	NOTE A_, 4
	NOTE F_, 2
	REST 4
	NOTE E_, 6
	RELEASE 8, 7
	RELEASE_VOL 2
	OCTAVE 4
	NOTE F_, 2
	REST 6
	NOTE F#, 2
	REST 8
	NOTE G_, 2
	REST 6
	DETUNE $FE
	VOLUME $08
	OCTAVE 2
	NOTE C_, 4
	DETUNE $00
	REST 0
	REST 4
	VIBRATO_OFF
	SND_JUMP Snd71_Ch1

Snd65_Ch3:
	VOICE $03, 7, 2, 9, 7
	VIBRATO 4, 3, 3
	TRANSPOSE_UP $0C
	REST 6
	OCTAVE 1
	NOTE G_, 6
	REST 6
	NOTE G_, 6
	NOTE D_, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE G_, 2
	REST 4
	NOTE G_, 6
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE E_, 6
	NOTE G_, 6
	NOTE G#, 6
	NOTE A_, 6
	NOTE C_, 6
	NOTE G_, 6
	NOTE G#, 6
	NOTE A_, 6
	NOTE A_, 6
	OCTAVE 2
	NOTE E_, 4
	NOTE D#, 2
	NOTE E_, 4
	RELEASE 8, 0
	RELEASE_VOL 6
	NOTE A_, 8
	RELEASE 4, 7
	OCTAVE 1
	NOTE A_, $0C
	RELEASE 9, 7
	OCTAVE 2
	NOTE A_, 6
	OCTAVE 1
	NOTE F_, 6
	NOTE F_, 6
	NOTE F#, 6
	NOTE F#, 6
	NOTE G_, 6
	NOTE G#, 4
	NOTE A_, 4
	REST 2
	NOTE A_, 8
	NOTE D_, 6
	NOTE D_, 6
	NOTE F_, 6
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE G_, 6
	OCTAVE 2
	NOTE D_, 6
	NOTE G_, 4
	OCTAVE 1
	NOTE G_, 2
	REST 4
	OCTAVE 2
	NOTE C_, 6
	RELEASE 8, 6
	RELEASE_VOL 6
	NOTE C_HI, 2
	REST 6
	NOTE C_HI, 2
	REST 8
	NOTE C_HI, 2
	REST 6
	WAVE 1
	RELEASE_VOL 4
	OCTAVE 1
	NOTE C_, 4
	REST 0
	REST 4
	VIBRATO_OFF
	SND_JUMP Snd71_Ch3

Snd65_Drm:
	LEN_UNIT $03
	DRUM 3, 4
	DRUM 3, 2
	DRUM 6, 4
	DRUM 2, 2
	DRUM 3, 4
	DRUM 3, 2
	DRUM 6, 4
	DRUM 2, 2
	DRUM 5, 4
	DRUM 5, 2
	DRUM 5, 4
	DRUM 5, 2
	DRUM 6, 4
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM 3, 6
	DRUM 2, 4
	DRUM 2, 2
	LOOP_END 5
	DRUM 3, 6
	DRUM 2, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 6, 2
	DRUM 3, $0C
	DRUM 4, 6
	DRUM 1, 6
	DRUM 2, 6
	DRUM 1, 6
	DRUM 2, 4
	DRUM 2, 2
	DRUM 1, 6
	DRUM 6, 4
	DRUM 5, 2
	DRUM 6, 4
	DRUM 3, 6
	DRUM 5, 2
	DRUM 6, 6
	DRUM 4, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM 4, 6
	DRUM 6, 6
	DRUM 4, 6
	DRUM 1, 4
	DRUM 5, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 3, 8
	DRUM 6, 4
	REST 0
	REST 4
	SND_JUMP Snd71_Drm

Snd66_Ch2:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	SND_CALL Snd66_Ch2_6F41
	OCTAVE 4
	NOTE F_, 3
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE A_, 1
	REST 1
	ATTEN 0
	SND_CALL Snd66_Ch2_6F4C
	OCTAVE 2
	NOTE F_, 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	REST 2
	RELEASE 9, 6
	VIBRATO_OFF
	DETUNE $01
	ATTEN 6
	RELEASE_VOL 1
	OCTAVE 1
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	DETUNE $00
	ATTEN 0
	SND_CALL Snd66_Ch2_6F41
	OCTAVE 4
	NOTE F_, 3
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 1
	REST 1
	NOTE G#, 1
	REST 1
	SND_CALL Snd66_Ch2_6F4C
	OCTAVE 2
	NOTE G_, 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	REST 2
	VOICE $03, 8, 5, 11, 6
	VIBRATO_SEMI 1
	RELEASE_VOL 2
	OCTAVE 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 5
	NOTE D_, 4
	REST 4
	NOTE D_, 4
	NOTE E_, 4
	ATTEN 1
	NOTE D_, 4
	ATTEN 2
	OCTAVE 6
	NOTE F#, 1
	NOTE G_, 1
	REST 2
	VIBRATO_OFF
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	ATTEN 0
	OCTAVE 4
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 4
	REST 4
	NOTE C_, 4
	NOTE D_, 4
	ATTEN 1
	NOTE C_, 4
	ATTEN 2
	VIBRATO_OFF
	OCTAVE 6
	NOTE E_, 1
	NOTE F_, 1
	REST 2
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	REST 2
	ATTEN 0
	RELEASE $0B, 5
	OCTAVE 4
	NOTE B_, 6
	NOTE A#, 2
	RELEASE_VOL 2
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE G_, 4
	ATTEN 1
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	ATTEN 0
	SND_LOOP
Snd66_Ch2_6F41:
	VOICE $06, 4, 7, 10, 6
	VIBRATO_SEMI 2
	RELEASE_VOL 3
	DUTY_STEP 8, 1
	SND_RET
Snd66_Ch2_6F4C:
	VOICE $03, 8, 9, 9, 10
	VIBRATO 1, 0, 4
	DUTY_STEP 0, 0
	SND_RET

Snd66_Ch1:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	SND_CALL Snd66_Ch1_7011
	OCTAVE 4
	NOTE F_, 4
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 1
	SND_CALL Snd66_Ch1_701E
	OCTAVE 2
	NOTE F_, 5
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	REST 2
	RELEASE 9, 6
	VIBRATO_OFF
	DETUNE $01
	ATTEN 2
	RELEASE_VOL 1
	OCTAVE 1
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 3
	DETUNE $00
	ATTEN 0
	SND_CALL Snd66_Ch1_7011
	OCTAVE 4
	NOTE F_, 4
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 1
	REST 1
	NOTE G#, 1
	SND_CALL Snd66_Ch1_701E
	OCTAVE 2
	NOTE G_, 5
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	REST 1
	VOICE $03, 8, 2, 11, 6
	VIBRATO_SEMI 1
	RELEASE_VOL 1
	DETUNE $00
	OCTAVE 4
	NOTE F#, 6
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 5
	NOTE D_, 4
	REST 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	VIBRATO_OFF
	PAN_LEFT 0
	DETUNE $01
	ATTEN 1
	OCTAVE 6
	NOTE F#, 1
	NOTE G_, 1
	REST 2
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	ATTEN 0
	VIBRATO_SEMI 1
	PAN_BOTH 0
	DETUNE $01
	OCTAVE 4
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 4
	REST 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	ATTEN 1
	VIBRATO_OFF
	PAN_RIGHT 0
	DETUNE $01
	OCTAVE 6
	NOTE E_, 1
	NOTE F_, 1
	REST 2
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	REST 2
	ATTEN 0
	DETUNE $01
	PAN_BOTH 0
	RELEASE 5, 6
	OCTAVE 4
	NOTE B_, 6
	NOTE A#, 2
	RELEASE $0F, 2
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE G_, 4
	ATTEN 1
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 2
	ATTEN 0
	SND_LOOP
Snd66_Ch1_7011:
	VOICE $06, 4, 2, 10, 6
	VIBRATO_SEMI 2
	DUTY_STEP 8, 1
	DETUNE $02
	AUTOPAN_BOTH 0
	SND_RET
Snd66_Ch1_701E:
	VOICE $03, 4, 2, 9, 10
	VIBRATO 1, 0, 4
	DUTY_STEP 0, 0
	PAN_BOTH 0
	SND_RET

Snd66_Ch3:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	VOICE $06, 4, 2, 9, 6
	RELEASE_VOL 4
	WAVE 1
	OCTAVE 2
	NOTE F_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE C_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE G_, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE C_, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE F_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE C_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	WAVE 1
	OCTAVE 2
	NOTE F_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE C_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE F_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	WAVE 1
	NOTE F#, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	WAVE 1
	NOTE G_, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE D_, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE 3
	NOTE A#, 2
	WAVE 1
	NOTE F_, 2
	WAVE 3
	NOTE A#, 2
	LOOP_END 2
	LOOP_START
	WAVE 1
	NOTE A_, 2
	WAVE 3
	NOTE A_, 2
	WAVE 1
	NOTE F_, 2
	WAVE 3
	NOTE A_, 2
	LOOP_END 2
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 3
	NOTE B_, 2
	WAVE 1
	NOTE D_, 2
	WAVE 3
	NOTE B_, 2
	WAVE 1
	NOTE G_, 2
	WAVE 3
	NOTE B_, 2
	WAVE 1
	NOTE D_, 2
	WAVE 3
	OCTAVE 3
	NOTE D_, 2
	WAVE 1
	NOTE C_, 2
	REST 2
	REST 4
	REST 2
	RELEASE 6, 6
	RELEASE_VOL 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE 9, 6
	RELEASE_VOL 4
	NOTE C_, 2
	SND_LOOP

Snd66_Drm:
	LEN_UNIT $06
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 4
	SND_SEGNO
	LOOP_START
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 6, 2
	DRUM 2, 2
	LOOP_END 3
	DRUM 6, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LOOP_START
	DRUM 6, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 3, 2
	LOOP_END 3
	DRUM 6, $0A
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 2
	SND_LOOP

Snd67_Ch2:
	VOICE $03, 8, 7, 10, 7
	DUTY_STEP 0, 1
	SND_CALL Snd67_Ch1_71A7
	NOTE E_, $0C
	TRANSPOSE_UP 1
	SND_CALL Snd67_Ch1_71A7
	NOTE E_, $0C
	TRANSPOSE_UP 2
	SND_CALL Snd67_Ch1_71A7
	TRANSPOSE_UP 0
	NOTE F#, 6
	NOTE F#, 6
	RELEASE 0, 0
	NOTE B_, 6
	RELEASE $0A, 7
	DUTY_STEP 0, 0
	NOTE B_, $0C
	SND_END

Snd67_Ch1:
	VOICE $03, 8, 2, 0, 0
	VIBRATO 4, 0, 1
	DETUNE $01
	REST 1
	SND_CALL Snd67_Ch1_71A7
	NOTE E_, $0C
	TRANSPOSE_UP 1
	SND_CALL Snd67_Ch1_71A7
	NOTE E_, $0C
	TRANSPOSE_UP 2
	SND_CALL Snd67_Ch1_71A7
	TRANSPOSE_UP 0
	NOTE F#, 6
	NOTE F#, 6
	NOTE B_, 6
	NOTE B_, $0B
	DETUNE $00
	SND_END

Snd67_Ch3:
	LEN_UNIT $03
	LOOP_START
	REST $0C
	LOOP_END 7
	REST 6
	SND_END

Snd67_Drm:
	LEN_UNIT $03
	LOOP_START
	REST $0C
	LOOP_END 7
	REST 6
	SND_END

Snd68_Ch2:
	TEMPO $2A
	SND_SEGNO
	SND_CALL Snd68_Ch2_71B0
	RELEASE $0A, 7
	NOTE D_, 6
	NOTE G_, 6
	SND_CALL Snd68_Ch2_71B0
	RELEASE $0A, 6
	NOTE D_, $0C
	VOICE $04, 0, 7, 10, 6
	DUTY_STEP 8, 1
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	RELEASE_VOL 3
	NOTE A#, 2
	NOTE B_, 2
	RELEASE $0A, 6
	OCTAVE 4
	NOTE E_, 4
	RELEASE $0A, 6
	NOTE E_, 2
	RELEASE_VOL 4
	NOTE D_, 2
	NOTE C_, 2
	RELEASE $0A, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE E_, 2
	RELEASE $0A, 6
	RELEASE_VOL 3
	NOTE G_, 2
	RELEASE $0A, 6
	NOTE B_, 4
	NOTE B_, 4
	NOTE G_, 4
	RELEASE $0A, 6
	RELEASE_VOL 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	DUTY_STEP 0, 0
	SND_LOOP
Snd67_Ch1_71A7:
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	REST 2
	NOTE C#, 2
	SND_RET
Snd68_Ch2_71B0:
	VOICE $04, 4, 7, 10, 7
	VIBRATO 4, 3, 2
	RELEASE_VOL 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE F_, 2
	NOTE F#, 4
	RELEASE_VOL 3
	RELEASE $0A, 7
	NOTE E_, 2
	NOTE D#, 2
	SND_RET

Snd68_Ch1:
	SND_SEGNO
	SND_CALL Snd68_Ch1_7235
	REST 4
	VOICE $01, 8, 5, 10, 7
	OCTAVE 4
	NOTE G_, 3
	NOTE A_, 2
	NOTE A#, 3
	LEN_UNIT $04
	RELEASE_VOL 1
	NOTE B_, 2
	NOTE G_, 2
	REST 2
	NOTE E_, 2
	NOTE D_, 2
	SND_CALL Snd68_Ch1_7235
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 6, 7
	NOTE B_, 8
	VOICE $04, 8, 3, 10, 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 5, 7
	NOTE E_, $0E
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE B_, 4
	VOICE $04, 4, 6, 8, 10
	OCTAVE 2
	NOTE D_, 6
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 2
	NOTE C_, 2
	RELEASE_VOL 2
	NOTE E_, 2
	RELEASE $0A, 7
	NOTE G_, 4
	VOICE $04, 8, 3, 10, 2
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	LEN_UNIT $01
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	SND_LOOP
Snd68_Ch1_7235:
	VOICE $04, 4, 4, 10, 7
	VIBRATO 4, 8, 0
	RELEASE_VOL 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	RELEASE $0A, 7
	NOTE A_, 4
	NOTE G#, 2
	NOTE A_, 4
	SND_RET

Snd68_Ch3:
	VOICE $04, 4, 2, 9, 7
	RELEASE_VOL 6
	VOICE $04, 7, 2, 9, 7
	RELEASE_VOL 6
	TRANSPOSE_UP $0C
	REST 6
	SND_SEGNO
	SND_CALL Snd68_Ch3_72A7
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 2
	RELEASE 6, 7
	RELEASE_VOL 6
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	SND_CALL Snd68_Ch3_72A7
	NOTE G_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE G_, 4
	RELEASE 8, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 4
	RELEASE 8, $0A
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	RELEASE 9, 7
	RELEASE_VOL 6
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 2
	RELEASE $0A, 4
	NOTE E_, 4
	RELEASE 8, $0A
	NOTE G#, 6
	RELEASE $0A, 4
	NOTE A_, 4
	RELEASE_VOL 6
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 4
	RELEASE 8, $0A
	OCTAVE 1
	NOTE D_, 4
	NOTE E_, 1
	NOTE F#, 1
	RELEASE 9, 7
	RELEASE_VOL 6
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 2
	REST 6
	SND_LOOP
Snd68_Ch3_72A7:
	RELEASE 9, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 2
	RELEASE 8, $0A
	OCTAVE 1
	NOTE D_, 4
	NOTE E_, 1
	NOTE F#, 1
	RELEASE 9, 7
	RELEASE_VOL 6
	SND_RET

Snd68_Drm:
	LEN_UNIT $04
	REST 6
	SND_SEGNO
	LOOP_START
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	REST 4
	LOOP_END 3
	DRUM 3, 2
	DRUM 2, 4
	DRUM 5, 2
	REST 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	REST 2
	DRUM 5, 2
	REST 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 6, 2
	LEN_UNIT $02
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $04
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 6, 2
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 2
	DRUM 6, 2
	DRUM 5, 2
	REST 2
	DRUM 5, 2
	DRUM 5, 4
	REST 4
	SND_LOOP

Snd69_Ch2:
	TEMPO $16
	VOICE $05, 0, 7, 9, 6
	VIBRATO 14, 0, 0
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE G_, 3
	RELEASE_VOL 3
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 9, 6
	OCTAVE 3
	NOTE C#, 2
	RELEASE_VOL 4
	NOTE D_, 2
	REST 6
	SND_SEGNO
	VOICE $05, 8, 7, 10, 6
	VIBRATO 4, 2, 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE A#, 1
	RELEASE_VOL 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	VOICE $05, 8, 6, 9, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI 1
	RELEASE_VOL 2
	OCTAVE 4
	NOTE F#, 1
	REST 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	RELEASE $0A, 3
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE B_, 1
	RELEASE_VOL 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE F#, 1
	REST 1
	REST 6
	VOICE $05, 4, 7, 10, 6
	VIBRATO 4, 2, 0
	DUTY_STEP 0, 0
	ATTEN 1
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE G#, 1
	RELEASE_VOL 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE $0A, 6
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 4
	VIBRATO_SEMI 3
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE D_, 3
	NOTE G_, 1
	RELEASE_VOL 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	REST 2
	RELEASE $0A, 4
	RELEASE_VOL 5
	VIBRATO 4, 0, 2
	DUTY_STEP 0, 0
	NOTE A#, 4
	SND_LOOP

Snd69_Ch1:
	VOICE $05, 8, 5, 9, 7
	VIBRATO 4, 3, 0
	OCTAVE 3
	NOTE B_, 3
	RELEASE_VOL 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	DETUNE $01
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	DETUNE $00
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	REST 8
	REST 6
	SND_SEGNO
	VOICE $05, 8, 3, 9, 7
	VIBRATO 4, 2, 1
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	RELEASE 6, 7
	NOTE G_, 8
	NOTE F#, 4
	NOTE E_, 4
	VOICE $05, 8, 2, 10, 2
	DETUNE $01
	PAN_RIGHT 0
	OCTAVE 4
	NOTE F#, 2
	REST 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE F#, 1
	REST 6
	DETUNE $00
	PAN_BOTH 0
	VOICE $05, 8, 3, 9, 7
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	RELEASE 6, 7
	NOTE F#, 8
	NOTE A_, 4
	NOTE F#, 4
	VOICE $05, 4, 1, 10, 2
	DETUNE $01
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	VOICE $05, 8, 4, 10, 7
	VIBRATO_SEMI 3
	DUTY_STEP 8, 1
	RELEASE_VOL 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	REST 2
	VIBRATO 2, 0, 2
	DUTY_STEP 0, 0
	NOTE F#, 4
	SND_LOOP

Snd69_Ch3:
	VOICE $05, 1, 2, 9, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE G_, 4
	REST 2
	NOTE G_, 2
	NOTE G#, 2
	REST 4
	RELEASE 9, 7
	NOTE G#, 2
	RELEASE_VOL 6
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	RELEASE 9, 7
	NOTE C#, 2
	RELEASE_VOL 6
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	SND_SEGNO
	VOICE $05, 1, 2, 14, 3
	VIBRATO_SEMI 1
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 3
	NOTE B_, 2
	WAVE 1
	NOTE D_, 2
	WAVE 3
	NOTE B_, 2
	LOOP_END 4
	DETUNE $FF
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	DETUNE $00
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	REST 4
	RELEASE 8, $0A
	NOTE C#, 2
	RELEASE $0E, 3
	WAVE 7
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE D#, 2
	RELEASE $0E, 3
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE F#, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	REST 4
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	REST 2
	NOTE D_, 2
	REST 2
	RELEASE $0A, 7
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE C_, 2
	REST 2
	RELEASE $0A, 7
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE C_, 4
	SND_LOOP

Snd69_Drm:
	LEN_UNIT $05
	DRUM 1, 6
	DRUM 2, 2
	DRUM 1, 6
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 8
	SND_SEGNO
	LOOP_START
	DRUM 1, 2
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 2
	LOOP_END 3
	DRUM 5, $0A
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM 1, 2
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 2
	LOOP_END 2
	DRUM 1, 6
	DRUM 5, 2
	DRUM 1, 6
	DRUM 5, 2
	DRUM 1, 4
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 4
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $01
	DRUM 1, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	LEN_UNIT $05
	SND_LOOP

Snd6A_Ch2:
	TEMPO $13
	VOICE $06, 8, 8, 9, 6
	RELEASE_VOL 4
	VIBRATO 2, 0, 1
	SND_SEGNO
	LOOP_START
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE C#, 4
	OCTAVE 1
	NOTE A#, 3
	RELEASE 9, 6
	NOTE D#, 1
	RELEASE_VOL 4
	NOTE F#, 3
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE C#, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE A#, 4
	NOTE B_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE F_, 4
	LOOP_END 2
	SND_LOOP

Snd6A_Ch1:
	SND_SEGNO
	VOICE $04, 8, 4, 13, 1
	TRANSPOSE_DOWN 8
	SND_CALL Snd6A_Ch1_7619
	REST 2
	SND_CALL Snd6A_Ch1_7619
	TRANSPOSE_DOWN 0
	VOICE $02, 0, 2, 7, 6
	VIBRATO 4, 0, 1
	DETUNE $02
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 4
	REST 8
	NOTE D#, 4
	REST $0C
	REST $0C
	NOTE F_, 8
	NOTE D#, 4
	REST 8
	NOTE D#, 4
	REST $0C
	REST 8
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 4
	REST 8
	NOTE D#, 4
	REST $0C
	REST $0C
	NOTE F_, 8
	NOTE D#, 4
	REST 8
	REST 4
	VOICE $02, 0, 2, 10, 3
	OCTAVE 4
	NOTE D#, 4
	NOTE F#, 4
	NOTE D#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE A#, 4
	NOTE B_, 8
	NOTE E_, 4
	NOTE F_, 8
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, $0A
	VOICE $04, 8, 4, 13, 1
	REST $0C
	REST $0C
	REST 6
	VIBRATO_OFF
	DETUNE $00
	TRANSPOSE_DOWN 3
	SND_CALL Snd6A_Ch1_7619
	REST 2
	SND_LOOP

Snd6A_Ch3:
	VOICE $04, 8, 2, 13, 1
	SND_SEGNO
	SND_CALL Snd6A_Ch1_7619
	REST 2
	SND_CALL Snd6A_Ch1_7619
	VOICE $04, 7, 2, 7, 6
	VIBRATO 14, 0, 0
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 4
	RELEASE_VOL 6
	NOTE D#, 2
	REST 4
	NOTE D#, 2
	REST 6
	REST 6
	RELEASE 7, 6
	NOTE F_, 4
	RELEASE_VOL 6
	NOTE D#, 2
	REST 4
	NOTE D#, 2
	REST 6
	REST 4
	RELEASE 7, 6
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 4
	RELEASE_VOL 6
	NOTE D#, 2
	REST 4
	NOTE D#, 2
	REST 6
	REST 6
	RELEASE 7, 6
	NOTE F_, 4
	RELEASE_VOL 6
	NOTE D#, 2
	REST 4
	REST 2
	VOICE $04, 4, 4, 10, 4
	OCTAVE 4
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 2
	RELEASE 9, 7
	NOTE B_, 4
	NOTE E_, 2
	NOTE F_, 4
	OCTAVE 4
	NOTE C#, 2
	RELEASE 7, 7
	VIBRATO 4, 2, 2
	OCTAVE 3
	NOTE B_, 6
	VOICE $04, 4, 4, 14, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 4
	NOTE F_, 6
	RELEASE $0D, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE B_, 1
	RELEASE $0D, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE F_, 2
	VOICE $04, 8, 2, 13, 1
	TRANSPOSE_UP 5
	SND_CALL Snd6A_Ch1_7619
	REST 2
	TRANSPOSE_UP 0
	SND_LOOP
Snd6A_Ch1_7619:
	OCTAVE 5
	REST 2
	REST 2
	NOTE G#, 2
	REST 2
	REST 2
	REST 2
	NOTE G#, 2
	REST 2
	REST 2
	REST 2
	REST 2
	REST 2
	NOTE G#, 2
	REST 2
	REST 2
	REST 2
	REST 2
	NOTE G#, 2
	REST 2
	REST 2
	REST 2
	REST 2
	REST 2
	SND_RET

Snd6A_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM 3, 4
	DRUM 1, 3
	DRUM 2, 1
	SND_LOOP

Snd6B_Ch2:
	TEMPO $3A
	VOICE $02, 4, 8, 10, 7
	VIBRATO 4, 6, 0
	RELEASE_VOL 2
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	REST 4
	NOTE G_, $0E
	NOTE G#, 4
	NOTE G#, 2
	REST 4
	NOTE G#, $0E
	NOTE G_, 2
	REST 2
	VOICE $02, 8, 7, 10, 7
	NOTE G_, 8
	RELEASE $0A, 7
	RELEASE_VOL 2
	NOTE A_, 2
	REST 4
	NOTE A#, 2
	REST 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 4
	NOTE G_, 2
	REST 4
	SND_SEGNO
	SND_CALL Snd6B_Ch2_76A2
	DUTY 4
	NOTE A_, 2
	DUTY 8
	REST 4
	NOTE F#, 2
	NOTE G_, 2
	REST 2
	VIBRATO_OFF
	DUTY 8
	RELEASE $0A, 7
	OCTAVE 5
	NOTE C_, 8
	RELEASE_VOL 2
	OCTAVE 4
	NOTE B_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE G_, 2
	REST $0E
	SND_CALL Snd6B_Ch2_76A2
	RELEASE $0A, 7
	OCTAVE 5
	NOTE E_, 8
	RELEASE_VOL 2
	NOTE C_, 2
	REST 2
	RELEASE $0A, 7
	DUTY 4
	OCTAVE 4
	NOTE G_, 8
	RELEASE_VOL 2
	NOTE F#, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE E_, 2
	REST 2
	DUTY 4
	RELEASE_VOL 3
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE C_, 2
	REST 4
	SND_LOOP
Snd6B_Ch2_76A2:
	VOICE $02, 8, 6, 10, 7
	VIBRATO 4, 6, 0
	RELEASE_VOL 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE G#, 2
	LOOP_START
	NOTE A_, 2
	REST 4
	LOOP_END 4
	NOTE A_, 4
	NOTE G#, 2
	REST 4
	NOTE G_, 2
	REST 4
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 4
	NOTE G#, 2
	NOTE A_, 2
	REST 4
	NOTE A_, 4
	NOTE G#, 2
	NOTE A_, 4
	NOTE D_, 2
	NOTE F_, 4
	NOTE A_, 2
	REST 0
	NOTE G#, 2
	NOTE A_, 4
	NOTE A#, 2
	NOTE B_, 2
	REST 4
	NOTE A#, 4
	NOTE B_, 2
	REST 4
	DUTY 4
	NOTE B_, 2
	REST 4
	DUTY 8
	NOTE G_, 2
	NOTE A_, 2
	REST 4
	NOTE G#, 4
	NOTE A_, 2
	REST 4
	SND_RET

Snd6B_Ch1:
	VOICE $02, 4, 3, 10, 7
	RELEASE_VOL 1
	VIBRATO 4, 0, 2
	DETUNE $03
	OCTAVE 3
	NOTE G_, 5
	NOTE G_, 2
	REST 4
	NOTE G_, $0E
	NOTE G#, 4
	NOTE G#, 2
	REST 4
	NOTE G#, $0E
	NOTE G_, 2
	REST 2
	DUTY 8
	VIBRATO 2, 0, 1
	NOTE G_, 8
	NOTE A_, 2
	REST 4
	NOTE A#, 2
	REST 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 4
	NOTE G_, 2
	REST 3
	SND_SEGNO
	SND_CALL Snd6B_Ch1_771F
	OCTAVE 4
	NOTE F_, 2
	REST $0A
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE B_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE G_, 2
	REST $0E
	SND_CALL Snd6B_Ch1_771F
	NOTE G_, 8
	NOTE E_, 2
	REST 2
	OCTAVE 4
	NOTE C_, 8
	NOTE C_, 2
	REST 4
	NOTE C_, 2
	REST 4
	NOTE C_, 2
	REST $0E
	SND_LOOP
Snd6B_Ch1_771F:
	VOICE $02, 8, 4, 10, 7
	RELEASE_VOL 1
	DETUNE $03
	VIBRATO_OFF
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 4
	NOTE G#, 2
	DETUNE $00
	LOOP_START
	REST 6
	OCTAVE 4
	NOTE E_, 2
	REST 4
	LOOP_END 4
	LOOP_START
	REST 6
	NOTE F_, 2
	REST 4
	LOOP_END 2
	DETUNE $03
	OCTAVE 3
	NOTE D_, 2
	REST 2
	NOTE D_, 8
	NOTE E_, 2
	REST 4
	NOTE F_, 2
	REST 4
	DETUNE $00
	NOTE B_, 2
	REST 4
	NOTE A#, 4
	NOTE B_, 2
	REST 4
	OCTAVE 4
	NOTE G_, 2
	REST 4
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	REST 4
	NOTE G#, 4
	NOTE A_, 2
	REST 4
	SND_RET

Snd6B_Ch3:
	VOICE $02, 4, 2, 10, 7
	VIBRATO 4, 4, 2
	RELEASE_VOL 6
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	REST 4
	NOTE B_, $0E
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	REST 4
	NOTE C_, $0E
	OCTAVE 2
	NOTE B_, 2
	REST $0C
	REST $0C
	REST $0C
	REST $0A
	SND_SEGNO
	SND_CALL Snd6B_Ch3_77B8
	NOTE C_HI, 2
	REST 6
	OCTAVE 2
	NOTE C_, 2
	REST 2
	RELEASE $0A, 7
	WAVE 7
	OCTAVE 3
	NOTE D#, 8
	RELEASE_VOL 6
	OCTAVE 2
	NOTE G#, 2
	REST 4
	OCTAVE 3
	NOTE D#, 2
	REST 4
	RELEASE_VOL 4
	WAVE 4
	OCTAVE 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE D_, 4
	OCTAVE 1
	NOTE G_, 2
	REST $0C
	SND_CALL Snd6B_Ch3_77B8
	RELEASE $0A, 7
	NOTE C_HI, 8
	RELEASE_VOL 6
	OCTAVE 2
	NOTE C_, 2
	REST 2
	RELEASE $0F, 7
	WAVE 6
	NOTE D#, 8
	RELEASE_VOL 6
	NOTE D_, 2
	REST 4
	NOTE C#, 2
	REST 4
	NOTE C_, 2
	REST 2
	DETUNE $0A
	RELEASE_VOL 4
	WAVE 4
	NOTE F#, 2
	NOTE G_, 4
	NOTE C_, 2
	REST $0C
	DETUNE $00
	SND_LOOP
Snd6B_Ch3_77B8:
	VOICE $02, 4, 2, 10, 7
	RELEASE_VOL 6
	OCTAVE 2
	NOTE C_, 4
	REST 8
	OCTAVE 1
	NOTE G_, 4
	REST 8
	NOTE C_, 4
	REST 8
	NOTE G_, 4
	REST 8
	OCTAVE 2
	NOTE D_, 4
	REST 8
	OCTAVE 1
	NOTE A_, 4
	REST 8
	OCTAVE 2
	NOTE D_, 2
	REST 2
	OCTAVE 1
	NOTE D_, 8
	NOTE E_, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE G_, 2
	REST 8
	NOTE G_, 2
	REST 4
	NOTE C_HI, 2
	REST 6
	NOTE G_, 2
	REST 8
	NOTE G_, 2
	REST 4
	SND_RET

Snd6B_Drm:
	LEN_UNIT $02
	LOOP_START
	REST $0C
	REST 6
	DRUM 3, 2
	DRUM 2, 4
	LOOP_END 2
	DRUM 5, 6
	REST $0C
	REST 6
	DRUM 2, 6
	DRUM 2, 4
	DRUM 2, 2
	REST 4
	DRUM 3, 2
	DRUM 2, 6
	SND_SEGNO
	SND_CALL Snd6B_Drm_780F
	DRUM 6, 6
	REST $0C
	REST 6
	DRUM 6, 6
	DRUM 6, 4
	DRUM 6, 6
	DRUM 3, 2
	DRUM 2, 6
	SND_CALL Snd6B_Drm_780F
	DRUM 6, 4
	DRUM 2, 8
	DRUM 2, 6
	DRUM 2, 6
	DRUM 6, 4
	DRUM 2, 2
	DRUM 2, 4
	DRUM 2, 2
	REST 4
	DRUM 3, 2
	DRUM 2, 6
	SND_LOOP
Snd6B_Drm_780F:
	LOOP_START
	REST 6
	DRUM 2, 4
	DRUM 2, 2
	DRUM 1, 6
	DRUM 2, 4
	DRUM 2, 2
	LOOP_END 3
	DRUM 1, 4
	DRUM 6, 8
	DRUM 2, 6
	DRUM 2, 4
	DRUM 2, 2
	LOOP_START
	DRUM 1, 6
	DRUM 6, 4
	DRUM 6, 2
	REST 4
	DRUM 4, 2
	DRUM 2, 2
	REST 4
	LOOP_END 2
	SND_RET

Snd6C_Ch2:
	TEMPO $10
	VOICE $05, 8, 5, 10, 4
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	LOOP_END 8
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	LOOP_END 8
	SND_LOOP

Snd6C_Ch1:
	VOICE $01, 8, 3, 0, 0
	VIBRATO 4, 0, 0
	DETUNE $01
	PAN_LEFT 0
	REST 3
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE B_, 5
	OCTAVE 3
	NOTE C_, 5
	LOOP_END 8
	PAN_RIGHT 0
	LOOP_START
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	LOOP_END 8
	SND_LOOP

Snd6C_Ch3:
	SND_END

Snd6C_Drm:
	SND_END

Snd6D_Ch2:
	VOICE $05, 8, 5, 10, 4
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	SND_SEGNO
	SND_CALL Snd6D_Ch2_78DD
	NOTE D#, 1
	SND_CALL Snd6D_Ch2_78F1
	SND_CALL Snd6D_Ch2_78DD
	NOTE D_, 1
	SND_CALL Snd6D_Ch2_7907
	SND_CALL Snd6D_Ch2_78DD
	NOTE D#, 1
	SND_CALL Snd6D_Ch2_78F1
	SND_CALL Snd6D_Ch2_78DD
	NOTE D_, 1
	SND_CALL Snd6D_Ch2_7907
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP2_START
	LOOP_START
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	LOOP_END 2
	TRANSPOSE_UP $0C
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP_START
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	LOOP_END 2
	OCTAVE 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	SND_LOOP
Snd6D_Ch2_78DD:
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
Snd6D_Ch2_78F1:
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd6D_Ch2_7907:
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	SND_RET

Snd6D_Ch1:
	VOICE $01, 8, 3, 0, 0
	OCTAVE 3
	NOTE A#, 8
	NOTE B_, 5
	OCTAVE 4
	NOTE C#, 5
	NOTE D#, 2
	DETUNE $00
	PAN_BOTH 0
	SND_SEGNO
	VOICE $05, 4, 5, 14, 3
	VIBRATO_OFF
	SND_CALL Snd6D_Ch1_7954
	SND_CALL Snd6D_Ch1_7961
	NOTE E_, 2
	SND_CALL Snd6D_Ch1_7954
	SND_CALL Snd6D_Ch1_7961
	NOTE D_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE B_, 2
	REST $0C
	NOTE E_, 2
	NOTE E_, 2
	REST 4
	NOTE E_, 2
	REST 6
	NOTE F#, 2
	REST 2
	NOTE F#, 2
	REST 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	REST 8
	REST 0
	SND_LOOP
Snd6D_Ch1_7954:
	LOOP_START
	REST 2
	OCTAVE 2
	NOTE G#, 2
	REST 2
	NOTE G#, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	LOOP_END 2
	SND_RET
Snd6D_Ch1_7961:
	REST 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	OCTAVE 3
	NOTE E_, 2
	REST 2
	SND_RET

Snd6D_Ch3:
	VOICE $05, 1, 2, 14, 3
	REST 4
	SND_SEGNO
	VIBRATO_SEMI 1
	SND_CALL Snd6D_Ch3_7A01
	SND_CALL Snd6D_Ch3_7A22
	SND_CALL Snd6D_Ch3_7A01
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE C_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	SND_CALL Snd6D_Ch3_7A01
	SND_CALL Snd6D_Ch3_7A22
	SND_CALL Snd6D_Ch3_7A01
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 3
	OCTAVE 3
	NOTE F#, 2
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 3
	OCTAVE 3
	NOTE G_, 2
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	WAVE 3
	OCTAVE 3
	NOTE A_, 2
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	NOTE C_HI, 2
	REST $0C
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 2
	REST 4
	NOTE C_, 2
	REST 6
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE D_, 2
	REST 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	REST 8
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	LOOP_END 2
	REST 8
	SND_LOOP
Snd6D_Ch3_7A01:
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	WAVE 3
	OCTAVE 3
	NOTE C_, 2
	SND_RET
Snd6D_Ch3_7A22:
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE 3
	OCTAVE 2
	NOTE B_, 2
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	SND_RET

Snd6D_Drm:
	LEN_UNIT $05
	REST 4
	SND_SEGNO
	LOOP_START
	REST 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	LOOP_END 8
	REST 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	REST $0C
	DRUM 2, 2
	DRUM 2, 2
	REST 4
	DRUM 2, 2
	REST 6
	DRUM 5, 2
	REST 2
	DRUM 5, 2
	REST 2
	DRUM 2, 2
	REST $0E
	REST 0
	SND_LOOP

Snd6E_Ch2:
	TEMPO $2A
	SND_SEGNO
	VOICE $05, 0, 6, 6, 2
	VIBRATO 15, 0, 0
	SND_CALL Snd6E_Ch2_7AD7
	REST 6
	SND_CALL Snd6E_Ch2_7AD7
	RELEASE 8, 2
	RELEASE_VOL 3
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE 6, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	RELEASE 4, 2
	OCTAVE 4
	NOTE F_, 4
	RELEASE 7, 2
	RELEASE_VOL 3
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 6, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 2
	RELEASE 4, 2
	NOTE C_, 4
	RELEASE 6, 2
	RELEASE_VOL 3
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	RELEASE 0, 0
	NOTE B_, 3
	LEN_UNIT $01
	RELEASE 0, 0
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 4
	LEN_UNIT $05
	RELEASE 6, 2
	VIBRATO 4, 0, 0
	OCTAVE 4
	NOTE G_, 2
	VIBRATO 15, 0, 0
	NOTE D_, 1
	NOTE E_, 2
	RELEASE 6, 2
	RELEASE_VOL 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 4, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	VOICE $05, 0, 4, 11, 4
	VIBRATO 7, 0, 0
	NOTE G_, 2
	NOTE G_, 4
	SND_LOOP
Snd6E_Ch2_7AD7:
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE C_, 2
	SND_RET

Snd6E_Ch1:
	SND_SEGNO
	VOICE $05, 0, 4, 11, 2
	VIBRATO 7, 0, 0
	DETUNE $FF
	TRANSPOSE_DOWN $0C
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	LOOP_END 2
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	DETUNE $00
	ATTEN 1
	RELEASE $0B, 5
	NOTE D_, 2
	NOTE D_, 4
	ATTEN 0
	SND_LOOP

Snd6E_Ch3:
	SND_SEGNO
	VOICE $05, 1, 2, 10, 3
	RELEASE_VOL 4
	SND_CALL Snd6E_Ch3_7BA5
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_CALL Snd6E_Ch3_7BA5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 4
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_LOOP
Snd6E_Ch3_7BA5:
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 2
	SND_RET

Snd6E_Drm:
	SND_SEGNO
	LEN_UNIT $05
	LOOP2_START
	LOOP_START
	REST 2
	DRUM 5, 2
	LOOP_END 7
	DRUM 5, 2
	DRUM 5, 2
	LOOP2_END 3
	LOOP_START
	REST 2
	DRUM 5, 2
	LOOP_END 7
	DRUM 5, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_LOOP

Snd6F_Ch2:
	VOICE $03, 8, 5, 0, 0
	RELEASE_VOL 1
	VIBRATO_SEMI 3
	DETUNE $FD
	ATTEN 2
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 1
	LEN_UNIT $04
	RELEASE 6, 0
	NOTE F#, 2
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	RELEASE $0B, 6
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 1
	LOOP_END 2
	ATTEN 2
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	VOICE $02, 0, 5, 0, 0
	RELEASE_VOL 1
	VIBRATO 4, 2, 2
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	LEN_UNIT $05
	RELEASE 6, 0
	RELEASE_VOL 2
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	RELEASE 7, $0C
	NOTE C#, 2
	VIBRATO 2, 0, 2
	NOTE C_, 8
	VOICE $05, 4, 5, 9, 0
	RELEASE_VOL 1
	VIBRATO_SEMI 3
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 6, 0
	RELEASE_VOL 3
	VIBRATO_OFF
	OCTAVE 2
	NOTE F_, 2
	SND_END

Snd6F_Ch1:
	VOICE $03, 4, 3, 0, 0
	VIBRATO 4, 0, 1
	DETUNE $02
	AUTOPAN 0
	ATTEN 1
	OCTAVE 2
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	LEN_UNIT $04
	NOTE F#, 3
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	RELEASE $0B, 6
	PAN_BOTH 0
	ATTEN 2
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END 3
	ATTEN 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $02, 4, 3, 0, 0
	RELEASE_VOL 1
	AUTOPAN 0
	VIBRATO 4, 2, 0
	DUTY_STEP 8, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	LEN_UNIT $05
	PAN_BOTH 0
	RELEASE 6, 0
	RELEASE_VOL 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 7, $0D
	NOTE G#, 2
	VIBRATO 4, 0, 0
	NOTE A_, 8
	VOICE $05, 8, 3, 9, 0
	RELEASE_VOL 1
	VIBRATO_OFF
	NOTE A#, 2
	NOTE A_, 2
	VOICE $05, 0, 3, 6, 0
	RELEASE_VOL 2
	DETUNE $03
	OCTAVE 1
	NOTE F_, 2
	SND_END

Snd6F_Ch3:
	VOICE $03, 1, 2, 0, 0
	VIBRATO 2, 0, 2
	ATTEN 2
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 1
	VOICE $04, 1, 2, 8, 0
	RELEASE_VOL 6
	NOTE F#, 2
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	RELEASE $0B, 6
	LOOP2_START
	LOOP_START
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 1
	LOOP_END 2
	ATTEN 2
	LOOP2_END 2
	ATTEN 0
	VOICE $02, 3, 4, 0, 0
	RELEASE_VOL 6
	TRANSPOSE_UP $0C
	DETUNE $FE
	VIBRATO 4, 2, 1
	ATTEN 3
	OCTAVE 2
	NOTE C_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	LEN_UNIT $05
	RELEASE 6, 0
	RELEASE_VOL 6
	NOTE F_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	RELEASE 4, 7
	NOTE C#, 2
	NOTE C_, 8
	VOICE $05, 5, 2, 9, 0
	RELEASE_VOL 6
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 2
	VOICE $05, 7, 2, 6, 0
	RELEASE_VOL 4
	TRANSPOSE_UP 0
	OCTAVE 1
	NOTE F_, 2
	SND_END

Snd6F_Drm:
	LEN_UNIT $03
	REST 3
	LEN_UNIT $04
	REST $0C
	LOOP2_START
	LOOP_START
	REST 4
	LOOP_END 2
	LOOP2_END 2
	LEN_UNIT $02
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	LEN_UNIT $05
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	LEN_UNIT $01
	DRUM 1, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	DRUM 2, 4
	DRUM 2, 3
	DRUM 2, 3
	LEN_UNIT $05
	DRUM 4, 2
	DRUM 4, 2
	DRUM 6, 2
	SND_END

Snd70_Ch2:
	TEMPO $13
	VOICE $04, 8, 7, 9, 7
	VIBRATO 4, 2, 0
	ATTEN 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 1
	NOTE A#, 2
	VOICE $04, 4, 6, 9, 6
	RELEASE_VOL 3
	DUTY_STEP 8, 1
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	REST 4
	NOTE G_, 6
	NOTE D_, 2
	REST 4
	NOTE C_, 2
	RELEASE 9, 4
	VIBRATO 14, 0, 0
	DUTY 0
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE G_, 2
	REST $0A
	VOICE $09, 4, 2, 2, 6
	VIBRATO 10, 0, 2
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTE A_, $0E
	SND_END

Snd70_Ch1:
	VOICE $04, 8, 5, 9, 7
	VIBRATO 4, 2, 1
	ATTEN 1
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	ATTEN 0
	NOTE F#, 2
	RELEASE_VOL 2
	NOTE G_, 4
	NOTE B_, 2
	REST 4
	OCTAVE 4
	NOTE D_, 6
	OCTAVE 3
	NOTE G_, 2
	REST 4
	OCTAVE 4
	NOTE E_, 2
	RELEASE 9, 4
	DUTY_STEP 0, 1
	VIBRATO 14, 0, 1
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	DETUNE $02
	OCTAVE 3
	NOTE B_, 2
	REST 9
	DETUNE $00
	VOICE $09, 4, 2, 2, 7
	VIBRATO 10, 0, 3
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTE F#, $0F
	SND_END

Snd70_Ch3:
	VOICE $04, 1, 2, 9, 6
	RELEASE_VOL 4
	VIBRATO 4, 3, 2
	REST 6
	OCTAVE 1
	NOTE G_, 6
	NOTE B_, 6
	OCTAVE 2
	NOTE C_, 6
	NOTE C#, 6
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 4
	NOTE G_, 2
	REST 9
	VOICE $09, 2, 6, 2, 6
	VIBRATO 10, 0, 3
	OCTAVE 2
	NOTE G_, 0
	SND_END

Snd70_Drm:
	LEN_UNIT $04
	DRUM 4, 2
	DRUM 4, 2
	DRUM 6, 2
	DRUM 3, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM 3, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 3, 4
	DRUM 1, 2
	REST 9
	LEN_UNIT $08
	DRUM 3, 0
	LEN_UNIT $05
	DRUM 2, 1
	DRUM 2, 1
	DRUM 6, 1
	SND_END

Snd71_Ch2:
	TEMPO $25
	TRANSPOSE_DOWN 1
	SND_CALL Snd5E_Ch2_5C84
	SND_CALL Snd5E_Ch2_5CBB
	TEMPO $20
	REST 4
	TRANSPOSE_DOWN 0
	SND_JUMP Snd5E_Ch2_5C7D

Snd71_Ch1:
	TRANSPOSE_DOWN 1
	SND_CALL Snd5E_Ch1_5E37
	SND_CALL Snd5E_Ch1_5E59
	REST 4
	TRANSPOSE_DOWN 0
	SND_JUMP Snd5E_Ch1_5E30

Snd71_Ch3:
	TRANSPOSE_DOWN 1
	SND_CALL Snd5E_Ch3_6036
	SND_CALL Snd5E_Ch3_6063
	TRANSPOSE_DOWN 0
	REST 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	SND_JUMP Snd5E_Ch3_602F

Snd71_Drm:
	SND_CALL Snd5E_Drm_61A8
	SND_CALL Snd5E_Drm_61AE
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	SND_JUMP Snd5E_Drm_61A1
