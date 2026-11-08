; ==========================================================================
; Raging Fighter (UE) - Konami sound driver (ROM0 + banks 14 and 15)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: SndUpdateFar ($0098-$00AA), FarRead ($01E2-$0212), PlaySoundFar, SndInit, PlaySound,
;         SndUpdate, tempo, fade, delayed request ($0EA4-$1119)
;   bank 14: tables, headers, drum hits ($4000-$4653), the track code ($4654-$4FC2), songs
;   bank 15: sound table of ids $A1-$FF, SFX and songs
; Build: rgbasm -Wall -o rf.o RF_SoundDriver.asm && rgblink -o rf.gb rf.o
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
DEF wTrkSfx1 EQU $C0A0 ; 65 bytes
DEF wTrkSfx2 EQU $C1A0 ; 65 bytes
DEF wTrkSfxN EQU $C2A0 ; 65 bytes
DEF wTrkCh1 EQU $C3A0 ; 65 bytes
DEF wTrkCh2 EQU $C4A0 ; 65 bytes
DEF wTrkCh3 EQU $C5A0 ; 65 bytes
DEF wTrkDrm EQU $C6A0 ; 65 bytes
DEF wTrackDesc EQU $C0E1
DEF wTempo EQU $C0E3
DEF wTempoAcc EQU $C0E4
DEF wReqPrio EQU $C0E5
DEF wReqId EQU $C0E6
DEF wFadeRate EQU $C0E8
DEF wFadeTimer EQU $C0E9
DEF wFadeStep EQU $C0EA
DEF wWaveId EQU $C0EB
DEF wC0EC EQU $C0EC
DEF wDelayTimer EQU $C0EE
DEF wReadBuf EQU $C1E1 ; 4 bytes
DEF wRomBank EQU $C002
DEF wSndBusy EQU $C004
DEF wSndMute EQU $C15B
DEF wSndLock15 EQU $C26B
DEF rROMB EQU $2000

; per-track fields: track n lives at $C0A0 + n*$100, so H = $C0 + n and L = field
DEF TRK_PRIO EQU $A0
DEF TRK_ID EQU $A1
DEF TRK_PTR EQU $A2
DEF TRK_LEN EQU $A4
DEF TRK_FLAGS EQU $A5
DEF TRK_PANFLAGS EQU $A6
DEF TRK_FLOW EQU $A7
DEF TRK_VIB EQU $A8
DEF TRK_A9 EQU $A9
DEF TRK_DETUNE EQU $AA
DEF TRK_ATTEN EQU $AC
DEF TRK_TRANSP EQU $AD
DEF TRK_JUMPCNT EQU $AE
DEF TRK_DUTYTICKS EQU $AF
DEF TRK_DUTYCNT EQU $B0
DEF TRK_DUTYSTART EQU $B1
DEF TRK_UNIT EQU $B2
DEF TRK_OCTAVE EQU $B3
DEF TRK_PERIOD EQU $B4
DEF TRK_LASTPERIOD EQU $B6
DEF TRK_VOL EQU $B8
DEF TRK_LASTVOL EQU $B9
DEF TRK_DUTY EQU $BA
DEF TRK_LASTDUTY EQU $BB
DEF TRK_GATE EQU $BC
DEF TRK_RELTICK EQU $BD
DEF TRK_ENV EQU $BE
DEF TRK_CH3CNT EQU $BF
DEF TRK_PAN EQU $C0
DEF TRK_VIBPTR EQU $C1
DEF TRK_VIBCUR EQU $C3
DEF TRK_VIBTIMER EQU $C5
DEF TRK_VIBDELAY EQU $C6
DEF TRK_VIBDELAYCNT EQU $C7
DEF TRK_VIBDEPTH EQU $C8
DEF TRK_VIBLOOP EQU $C9
DEF TRK_VIBLOOPCNT EQU $CB
DEF TRK_VIBMARK EQU $CC
DEF TRK_LOOP1 EQU $CE
DEF TRK_LOOP1CNT EQU $D0
DEF TRK_LOOP2 EQU $D1
DEF TRK_LOOP2CNT EQU $D3
DEF TRK_MARK EQU $D4
DEF TRK_RET EQU $D6
DEF TRK_REG_NRX1 EQU $D8
DEF TRK_REG_NRX2 EQU $D9
DEF TRK_REG_NRX3 EQU $DA
DEF TRK_REG_NRX4 EQU $DB
DEF TRK_LASTPITCH EQU $DC
DEF TRK_FLAGS3 EQU $DD
DEF TRK_RELVOL EQU $DE
DEF TRK_PITCHIDX EQU $DF
DEF TRK_MUTE EQU $E0

; wTrackDesc: Sfx1 $40, Sfx2 $52, SfxN $63, Ch1 $00, Ch2 $11, Ch3 $22, Drm $34 (low nibble = channel)
; TRK_FLAGS: 0 rest, 1 (cleared by a voice and at the end of Sfx1/Sfx2, never tested), 2 retrigger
;   a long note, 4 tempo skip, 5 reload the duty/wave
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, 5 pitch-13 note
;   (never read), 6 autopan with both sides
; TRK_FLOW: 0/1 loops open, 2 in a call, 3 mark set, 4 vibrato loop, 5 vibrato mark
; TRK_FLAGS3: 0 Sfx1/Sfx2 low nibble next, 2 noise retrigger pending
; TRK_MUTE: bit 7 makes every stream byte a mute (nothing sets it)

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
; Sfx1/Sfx2: note \1, then a new unit
MACRO NOTE_UNIT
	db (\1 << 4) | $0E, \2
ENDM
; Sfx1/Sfx2: note \1 only (the low nibble $F skips to the next byte, read as usual)
MACRO NOTE_SKIP
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
; SfxN: volume \1 (NR42 high nibble, written at once), retrigger at the next noise note
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
; $E0 unit | $80, v: unit & $7F, NRx2 = swap(v) at once and a retrigger mark (used on SfxN)
MACRO NVOICE
	db $E0, \1, \2
ENDM
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release tick = length * gate / 16), env (NRx2 low nibble at the release);
; also clears the release volume
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
; pan (both sides / NR51 high nibble / low nibble); y unused
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $20 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $30 | \1
ENDM
; autopan: every note alternates low / high nibble side (y unused)
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; autopan: every note alternates low nibble side / both sides (y unused)
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
; $EC x: start a fade: wFadeRate = x (NR50 - $11 every x updates, then the music stops)
MACRO FADE
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

SECTION "SndUpdateFar", ROM0[$0098]

; SndUpdateFar (from the VBlank handler, also the timer vector's target, but the timer
; interrupt returns at once): runs SndUpdate unless wSndBusy bit 0/1 is set.
SndUpdateFar:
	ld hl, wSndBusy
	ld a, [hl]
	and $03
	jr nz, .l00AA
	set 0, [hl]
	call SndUpdate
	ld hl, wSndBusy
	res 0, [hl]
.l00AA:
	ret

SECTION "FarRead", ROM0[$01E2]

; FarRead: map bank 15 (TRK_ID >= $A0) or 14 and copy 4 stream bytes from DE into wReadBuf;
; bank 14 is mapped again. Every stream read of the track code goes through here.
FarRead:
	push af
	ld l, TRK_ID
	ld a, [hl]
	cp $A0
	jr c, .l01F2
	ld a, $0F
	ld [rROMB], a
	pop af
	jr .l01F8
.l01F2:
	ld a, $0E
	ld [rROMB], a
	pop af
.l01F8:
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

SECTION "Sound ROM0", ROM0[$0EA4]

; PlaySoundFar: A = sound id; dropped while wSndMute is set (most game calls go straight to
; PlaySoundAlways). Sets wSndBusy bit 1, PlaySound, maps the game's bank again.
PlaySoundFar:
	push af
	ld a, [wSndMute]
	or a
	jr z, .l0EAD
	pop af
	ret
.l0EAD:
	pop af

PlaySoundAlways:
	push hl
	ld hl, wSndBusy
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
	ld hl, wSndBusy
	res 1, [hl]
	pop hl
	ret

; SndInit: NR50 = $77, NR51 = $FF, NR52 = $80, and the register addresses TRK_REG_NRX1-4
; of tracks 0-5. The drum track keeps 0, so its register writes go to $FF00 (the joypad).
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

; PlaySound: wReqId = id. 0: StopAll (bank 14). $0F: start the delay (wDelayTimer = 1; id $10
; follows after 47 updates). Else NR50 = $77, and the header comes from bank 14 (ids
; < $A0, SoundTable) or bank 15 (ids >= $A0, SoundTable15, refused while wSndLock15 is set).
; If any SFX track of the mask holds a higher priority nothing starts. Music needs the Ch1
; bit and a priority >= Ch1's: tempo and fade reset, Ch1-Ch3/Drm started. A started track:
; LEN 1, $A5-$AF = 0, TRK_FLAGS3/TRK_RELVOL = 0, wWaveId = 0 (no register writes; Sfx1 NR10 = 8,
; SfxN NR51 |= $88).
PlaySound:
	ld [wReqId], a
	or a
	ld b, a
	jr nz, .l0F10
	ld a, $0E
	ld [rROMB], a
	jp StopAll
.l0F10:
	cp $0F
	jr nz, .l0F1A
	ld a, $01
	ld [wDelayTimer], a
	ret
.l0F1A:
	ld c, $24
	ld a, $77
	ldh [c], a
	ld a, b
	cp $A0
	jr nc, PlaySound15
	ld a, $0E
	ld [rROMB], a
	ld a, b
	ld hl, SoundTable - 2
	jp ReadHeader

PlaySound15:
	ld a, [wSndLock15]
	or a
	ret nz
	ld a, $0F
	ld [rROMB], a
	ld a, b
	ld hl, SoundTable15 - 2
	sub $A0

ReadHeader:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
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
	ld [wC0EC], a
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
	ld l, TRK_FLAGS3
	ld [hl+], a
	ld [hl], a
	ld [wWaveId], a
	ret

CheckSfxPrio:
	cp [hl]
	ret nc
	ld b, $00
	ret

StartSfxTrack:
	call StartMusicTrack
	ld a, $C0
	cp h
	jr nz, .l0FF0
	ld a, $08
	ld c, $10
	ldh [c], a
.l0FF0:
	ld a, $C2
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

; SndUpdate (once per VBlank): FadeTick, TempoTick, DelayTick, Ch1, Ch2, Ch3, Drm, SfxN, Sfx2,
; Sfx1, each through RunTrack (bank 14, TrackTick); then the game's bank (wRomBank). No pause.
SndUpdate:
	call FadeTick
	call TempoTick
	call DelayTick
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
	ld a, [wRomBank]
	ld [rROMB], a
	ret

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, $0E
	ld [rROMB], a
	jp TrackTick

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
	jr c, .l1071
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l1071:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: every wFadeRate updates NR50 goes down by $11 (rate 0 = off; a stopped Ch2 also
; ends it). From $11 on the rate is 1 and wFadeStep counts: $10 stops Drm, $18 Ch1, $1C Ch2,
; $20 Ch3 (and the fade ends; NR50 stays at $11 until the next request).
FadeTick:
	ld a, [wFadeRate]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld a, [wTrkCh2 + $01]
	or a
	jr nz, .l1093
	ld [wFadeRate], a
.l1093:
	ld c, $24
	ldh a, [c]
	cp $11
	jr z, FadeStep
	sub $11
	jr z, FadeStep
	ldh [c], a
	ret

FadeStep:
	ld a, $01
	ld [wFadeRate], a
	ld a, [wFadeStep]
	inc a
	ld [wFadeStep], a
	cp $10
	jr z, FadeStopDrm
	cp $18
	jr z, FadeStopCh1
	cp $1C
	jr z, FadeStopCh2
	cp $20
	ret nz

FadeStopCh3:
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ld a, $00
	jr nz, .l10CB
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l10CB:
	ld h, HIGH(wTrkCh3)
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	jr FadeStopTrack

FadeStopCh1:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr nz, .l10EA
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l10EA:
	ld h, HIGH(wTrkCh1)
	jr FadeStopTrack

FadeStopCh2:
	ld h, HIGH(wTrkCh2)
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	jr FadeStopTrack

FadeStopDrm:
	ld h, HIGH(wTrkDrm)

FadeStopTrack:
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl], a
	ret

; DelayTick: after request $0F, wDelayTimer counts to $30 and then requests $10.
DelayTick:
	ld a, [wDelayTimer]
	or a
	ret z
	inc a
	cp $30
	ld [wDelayTimer], a
	ret nz
	xor a
	ld [wDelayTimer], a
	ld a, $10
	call PlaySoundAlways
	ret

SECTION "Sound bank 14", ROMX[$4000], BANK[14]

; SoundTable: bank-14 ids $01-$18 (the code adds 2 * id to $3FFE).
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
	dw SndHdr0F ; $10
	dw SndHdr11 ; $11
	dw SndHdr12 ; $12
	dw SndHdr13 ; $13
	dw SndHdr14 ; $14
	dw SndHdr15 ; $15
	dw SndHdr16 ; $16
	dw SndHdr17 ; $17
	dw SndHdr18 ; $18

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
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd07_Sfx2
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd08_Sfx2
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $20, $06 ; tracks: Sfx2, SfxN
	dw Snd09_Sfx2
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd0C_Ch1
	dw Snd0C_Ch2
	dw Snd0C_Ch3
	dw Snd0C_Drm

SndHdr0D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd0D_Ch1
	dw Snd0D_Ch2
	dw Snd0D_Ch3
	dw Snd0D_Drm

SndHdr0E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd0E_Ch1
	dw Snd0E_Ch2
	dw Snd0E_Ch3
	dw Snd0E_Drm

SndHdr0F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd0F_Ch1
	dw Snd0F_Ch2
	dw Snd0F_Ch3
	dw Snd0F_Drm

; An unreferenced header (prio $40, Ch1-Ch3 + Drm) with the streams of ids $0F/$10.
	db $40, $78, $23, $54, $99, $53, $B7, $54, $E4, $54

SndHdr11:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd11_Ch1
	dw Snd11_Ch2
	dw Snd11_Ch3
	dw Snd11_Drm

SndHdr12:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd12_Ch1
	dw Snd12_Ch2
	dw Snd12_Ch3
	dw Snd12_Drm

SndHdr13:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd13_Ch1
	dw Snd13_Ch2
	dw Snd13_Ch3
	dw Snd13_Drm

SndHdr14:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd14_Ch1
	dw Snd14_Ch2
	dw Snd14_Ch3
	dw Snd14_Drm

SndHdr15:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd15_Ch1
	dw Snd15_Ch2
	dw Snd15_Ch3
	dw Snd15_Drm

SndHdr16:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd16_Ch1
	dw Snd16_Ch2
	dw Snd16_Ch3
	dw Snd16_Drm

SndHdr17:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd17_Ch1
	dw Snd17_Ch2
	dw Snd17_Ch3
	dw Snd17_Drm

SndHdr18:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd18_Ch1
	dw Snd18_Ch2
	dw Snd18_Ch3
	dw Snd18_Drm

; WaveTable: 15 waves (wave n = the high nibble of the duty byte; from WaveTable - 2).
WaveTable:
	dw Wave1 ; wave 1
	dw Wave2 ; wave 2
	dw Wave3 ; wave 3
	dw Wave4 ; wave 4
	dw Wave5 ; wave 5
	dw Wave6 ; wave 6
	dw Wave7 ; wave 7
	dw Wave8 ; wave 8
	dw Wave9 ; wave 9
	dw Wave10 ; wave 10
	dw Wave11 ; wave 11
	dw Wave12 ; wave 12
	dw Wave13 ; wave 13
	dw Wave14 ; wave 14
	dw Wave15 ; wave 15
Wave1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
Wave2:
	db $14, $7A, $DF, $DB, $A7, $41, $00, $00, $00, $00, $00, $37, $33, $33, $33, $33
Wave3:
	db $89, $AB, $CD, $EF, $CD, $AB, $89, $67, $89, $AB, $CD, $EF, $CD, $AB, $89, $67
Wave4:
	db $66, $33, $00, $33, $66, $33, $00, $33, $66, $77, $88, $99, $AA, $BB, $CC, $DD
Wave5:
	db $00, $00, $00, $00, $00, $00, $00, $00, $88, $88, $88, $88, $88, $88, $88, $88
Wave6:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave7:
	db $12, $34, $56, $78, $9A, $98, $76, $54, $56, $78, $9A, $BC, $DE, $FF, $00, $00
Wave8:
	db $FF, $EE, $DC, $BA, $98, $76, $54, $32, $10, $AA, $99, $87, $65, $43, $21, $00
Wave9:
	db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave10:
	db $FF, $00, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $FF, $00, $FF, $00
Wave11:
	db $11, $88, $22, $77, $33, $66, $44, $55, $66, $79, $AC, $EE, $FF, $EF, $DC, $B7
Wave12:
	db $70, $07, $00, $34, $00, $0D, $E9, $AA, $23, $02, $46, $8A, $00, $2F, $FD, $A9
Wave13:
	db $42, $34, $55, $78, $9A, $CD, $FF, $FF, $DC, $BA, $55, $35, $11, $77, $11, $22
Wave14:
	db $77, $00, $77, $77, $00, $77, $77, $77, $00, $77, $77, $77, $77, $00, $77, $00
Wave15:
	db $13, $57, $9B, $DF, $81, $80, $00, $00, $00, $88, $88, $CF, $08, $85, $84, $04

; PeriodTable: 85 periods (from PeriodTable - 26 by 2 * pitch + TRK_OCTAVE + TRK_TRANSP).
PeriodTable:
	dw $03A, $0AB, $113, $177, $1D5, $22D, $281, $2D0, $31A, $361, $3A3, $3E2 ; octave index 0
	dw $41D, $455, $48A, $4BB, $4EA, $517, $541, $568, $58D, $5B1, $5D2, $5F1 ; octave index 1
	dw $60F, $62B, $645, $65E, $675, $68B, $6A1, $6B4, $6C7, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73B, $746, $750, $75A, $763, $76B, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A8, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C5, $7C9, $7CC, $7CF, $7D1, $7D4, $7D7, $7D9, $7DB, $7DD, $7DF ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; VibratoTable: 38 pointers (EB n uses entry n; from VibratoTable - 2).
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib03 ; 3
	dw Vib04 ; 4
	dw Vib05 ; 5
	dw Vib06 ; 6
	dw Vib06 ; 7
	dw Vib06 ; 8
	dw Vib09 ; 9
	dw Vib09 ; 10
	dw Vib0B ; 11
	dw Vib0B ; 12
	dw Vib0B ; 13
	dw Vib0B ; 14
	dw Vib0B ; 15
	dw Vib10 ; 16
	dw Vib11 ; 17
	dw Vib12 ; 18
	dw Vib13 ; 19
	dw Vib14 ; 20
	dw Vib15 ; 21
	dw Vib16 ; 22
	dw Vib17 ; 23
	dw Vib18 ; 24
	dw Vib19 ; 25
	dw Vib1A ; 26
	dw Vib1B ; 27
	dw Vib1C ; 28
	dw Vib1D ; 29
	dw Vib1E ; 30
	dw Vib1F ; 31
	dw Vib20 ; 32
	dw Vib21 ; 33
	dw Vib22 ; 34
	dw Vib23 ; 35
	dw Vib24 ; 36
	dw Vib25 ; 37
	dw Vib26 ; 38

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

Vib03:
	VIB_STEP 2, 0, 6
	VIB_STEP 2, 0, 5
	VIB_STEP 3, 0, 4
	VIB_STEP 2, 0, 3
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib04:
	VIB_STEP 2, 1, 7
	VIB_STEP 3, 1, 6
	VIB_STEP 3, 1, 5
	VIB_STEP 4, 1, 3
	VIB_STEP 5, 1, 2
	VIB_STEP 6, 1, 1
	VIB_STEP 7, 1, 0
	VIB_STEP 1, 0, 0
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

Vib05:
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 3, 1, 4
	VIB_STEP 4, 1, 5
	VIB_END

Vib06:
	VIB_STEP 2, 0, 1
	VIB_END

Vib09:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 0, 0
	VIB_END

Vib0B:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 2, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 2, 0, 7
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_END

Vib10:
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 1
	VIB_END

; An unreferenced vibrato table (no VibratoTable entry points here).
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 2, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 2, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_END

Vib11:
	VIB_MARK
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
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib12:
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

Vib13:
	VIB_STEP 1, 0, 2
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

Vib14:
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 0, 0
	VIB_END

Vib15:
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 7, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib16:
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 4
	VIB_STEP 1, 0, 0
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib17:
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 7
	VIB_END

Vib18:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_END

Vib19:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_MARK

Vib1A:
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 15, 0, 0
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

Vib1B:
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 0
	VIB_END

Vib1C:
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 0, 0
	VIB_END

Vib1D:
	VIB_STEP 1, 0, 2
	VIB_STEP 15, 0, 0
	VIB_STEP 15, 0, 0
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_MARK

Vib1E:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib1F:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_MARK

Vib20:
	VIB_MARK
	VIB_STEP 14, 0, 1
	VIB_STEP 14, 0, 2
	VIB_STEP 14, 0, 3
	VIB_STEP 14, 0, 4
	VIB_STEP 14, 0, 3
	VIB_STEP 14, 0, 2
	VIB_STEP 14, 0, 1
	VIB_STEP 14, 1, 1
	VIB_STEP 14, 1, 2
	VIB_STEP 14, 1, 3
	VIB_STEP 14, 1, 4
	VIB_STEP 14, 1, 3
	VIB_STEP 14, 1, 2
	VIB_STEP 14, 1, 1
	VIB_MARK

Vib21:
	VIB_STEP 8, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_END

Vib22:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib23:
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 6
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 15, 0, 0
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

Vib24:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 15, 0, 0
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

Vib25:
	VIB_STEP 1, 1, 7
	VIB_STEP 15, 0, 0
	VIB_STEP 8, 0, 0
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib26:
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 15, 0, 0
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

; Vibrato2Table: 32 semitone-step tables (EB n | $80; from Vibrato2Table - 2).
Vibrato2Table:
	dw VibSemi01 ; 1 (EB 1 | $80)
	dw VibSemi02 ; 2 (EB 2 | $80)
	dw VibSemi03 ; 3 (EB 3 | $80)
	dw VibSemi04 ; 4 (EB 4 | $80)
	dw VibSemi05 ; 5 (EB 5 | $80)
	dw VibSemi06 ; 6 (EB 6 | $80)
	dw VibSemi07 ; 7 (EB 7 | $80)
	dw VibSemi08 ; 8 (EB 8 | $80)
	dw VibSemi09 ; 9 (EB 9 | $80)
	dw VibSemi0A ; 10 (EB 10 | $80)
	dw VibSemi0B ; 11 (EB 11 | $80)
	dw VibSemi0C ; 12 (EB 12 | $80)
	dw VibSemi0D ; 13 (EB 13 | $80)
	dw VibSemi0D ; 14 (EB 14 | $80)
	dw VibSemi0D ; 15 (EB 15 | $80)
	dw VibSemi0D ; 16 (EB 16 | $80)
	dw VibSemi0D ; 17 (EB 17 | $80)
	dw VibSemi12 ; 18 (EB 18 | $80)
	dw VibSemi13 ; 19 (EB 19 | $80)
	dw VibSemi14 ; 20 (EB 20 | $80)
	dw VibSemi15 ; 21 (EB 21 | $80)
	dw VibSemi16 ; 22 (EB 22 | $80)
	dw VibSemi17 ; 23 (EB 23 | $80)
	dw VibSemi18 ; 24 (EB 24 | $80)
	dw VibSemi19 ; 25 (EB 25 | $80)
	dw VibSemi1A ; 26 (EB 26 | $80)
	dw VibSemi1B ; 27 (EB 27 | $80)
	dw VibSemi1C ; 28 (EB 28 | $80)
	dw VibSemi1D ; 29 (EB 29 | $80)
	dw VibSemi1E ; 30 (EB 30 | $80)
	dw VibSemi1F ; 31 (EB 31 | $80)
	dw VibSemi20 ; 32 (EB 32 | $80)
VibSemi01:
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi02:
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi03:
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi04:
	VIB_MARK
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 0
	VIB_MARK
VibSemi05:
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi06:
	VIB_MARK
	VIB_SEMI_STEP 3, 0
	VIB_SEMI_STEP 1, $0A
	VIB_MARK
VibSemi07:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 1
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 2, 1
	VIB_MARK
VibSemi08:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0F, 0
	VIB_SEMI_STEP 8, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 2, 1
	VIB_MARK
VibSemi09:
	VIB_SEMI_STEP 1, $0D
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi0A:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0F, 0
	VIB_SEMI_STEP 5, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 1, 1
	VIB_MARK
VibSemi0B:
	VIB_SEMI_STEP 2, $0F
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 2, $0D
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, $0B
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, 8
	VIB_SEMI_STEP $0F, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_MARK
VibSemi0C:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0E, 0
	VIB_SEMI_STEP $0A, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 2, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 1, 9
	VIB_MARK
VibSemi0D:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi12:
	VIB_SEMI_STEP 1, $0D
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi13:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi14:
	VIB_MARK
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_MARK
VibSemi15:
	VIB_SEMI_STEP 1, $0D
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi16:
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi17:
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi18:
	VIB_SEMI_STEP 3, 0
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, $0C
	VIB_END
VibSemi19:
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi1A:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 4, 0
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi1B:
	VIB_MARK
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 3, 0
	VIB_MARK
VibSemi1C:
	VIB_SEMI_STEP 1, $0D
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi1D:
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi1E:
	VIB_SEMI_STEP 1, $0F
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi1F:
	VIB_MARK
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 2, 0
	VIB_MARK
VibSemi20:
	VIB_END

Snd01_SfxN:
	NVOICE $81, $05
	NOISE $17
	NVOICE $88, $32
	NOISE $03
	SND_END

Snd02_SfxN:
	NVOICE $81, $03
	NOISE $17
	NVOICE $88, $31
	NOISE $03
	SND_END

Snd03_SfxN:
	NVOICE $82, $14
	NOISE $15
	NVOICE $86, $73
	NOISE $14
	NVOICE $A0, $72
	NOISE $14
	SND_END

Snd04_SfxN:
	NVOICE $81, $0D
	NOISE $35
	NOISE $26
	NVOICE $82, $26
	NOISE $26
	NVOICE $88, $01
	NOISE $17
	SND_END

Snd05_SfxN:
	NVOICE $81, $08
	NOISE $35
	NOISE $26
	NVOICE $83, $43
	NOISE $26
	NVOICE $88, $01
	NOISE $17
	SND_END
	db $FF ; unreachable

Snd06_SfxN:
	NVOICE $82, $06
	NOISE $67
	NOISE $66
	NOISE $65
	NOISE $64
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	LEN_UNIT $01
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $15
	NOISE $14
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	SND_END

Snd0A_SfxN:
	NVOICE $81, $1F
	NOISE $99
	NOISE $89
	SND_END

Snd0B_SfxN:
	NVOICE $98, $B0
	NOISE $24
	NVOICE $81, $0F
	LOOP_START
	NOISE $14
	NOISE $15
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE_VOL 3
	LOOP_END 2
	SND_END

; Orphan SfxN stream (no header points here).
Data_45D7:
	NVOICE $81, $06
	LOOP_START
	NOISE $01
	NOISE $02
	NOISE $03
	NOISE $04
	NOISE $05
	NOISE $06
	NOISE $07
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
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
	NOISE_VOL 1
	LOOP_END 2
	SND_END

Snd07_SfxN:
	NVOICE $81, $0B
	PAN_LEFT 0
	NOISE $4A
	NOISE $34
	LEN_UNIT $03
	NOISE_VOL 2
	NOISE $22
	NVOICE $88, $01
	NOISE $01
	SND_END

Snd07_Sfx2:
	VOICE $02, 1, 2, 0, 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE_SKIP $0A
	LEN_UNIT $01
	NOTES 7, 4
	NOTE_SKIP 1
	OCTAVE 3
	NOTE_SKIP $0B
	SND_END

Snd08_SfxN:
	NVOICE $81, $09
	NOISE $4A
	NOISE $34
	LEN_UNIT $03
	NOISE_VOL 2
	NOISE $22
	NVOICE $88, $01
	NOISE $01
	SND_END

Snd08_Sfx2:
	TRANSPOSE_UP 1
	VOICE $02, 1, 2, 0, 0
	OCTAVE 4
	NOTE_SKIP 4
	LEN_UNIT $01
	NOTE_SKIP 2
	OCTAVE 3
	NOTES $0C, $0A
	NOTE_SKIP 8
	SND_END

Snd09_SfxN:
	NVOICE $81, $0B
	PAN_RIGHT 0
	NOISE $4A
	NOISE $34
	LEN_UNIT $03
	NOISE_VOL 2
	NOISE $22
	NVOICE $88, $01
	NOISE $01
	SND_END

Snd09_Sfx2:
	TRANSPOSE_UP 5
	VOICE $02, 1, 2, 0, 0
	PAN_RIGHT 0
	OCTAVE 3
	NOTE_SKIP 7
	LEN_UNIT $01
	ATTEN 1
	NOTES 5, 3
	NOTE_SKIP 1
	OCTAVE 2
	NOTE_SKIP $0B
	SND_END

; TrackTick: tempo skip; a pending reload of the duty; LEN - 1; at 0 FarRead and read
; commands, else Sustain. With TRK_MUTE bit 7 every byte only mutes the channel.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, .l4666
	res 5, [hl]
	ld l, TRK_LASTDUTY
	ld a, [hl]
	call WriteDuty
.l4666:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

; ReadCmds: FarRead, then $E0-$FF commands. SfxN: NoiseNote. Sfx1/Sfx2: two notes per byte,
; high nibble first (TRK_FLAGS3 bit 0 clear), then the same byte for the low nibble (bit 0
; set; low nibble $E: new unit from the next byte, $F: go on with the next byte). Music: hi =
; pitch, lo x unit (0: (unit & 15) x 16).
ReadCmds:
	call FarRead
	ld l, TRK_MUTE
	bit 7, [hl]
	jp nz, MutedByte
	ld a, [wReadBuf]
	cp $E0
	jp nc, Command
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote
	bit 6, a
	jp z, MusicNote
	ld l, TRK_FLAGS3
	bit 0, [hl]
	jr nz, SfxNoteLow
	set 0, [hl]
	dec de

SfxNoteHigh:
	call NextCmd
	dec de
	ld l, TRK_UNIT
	ld a, [hl]
	jp NoteLen

SfxNoteLow:
	res 0, [hl]
	ld a, [wReadBuf]
	call NextCmd
	dec de
	and $0F
	cp $0E
	jr c, .l46C0
	jr z, .l46B8
	inc de
	jp ReadCmds
.l46B8:
	ld a, $E7
	ld [wReadBuf], a
	jp Command
.l46C0:
	ld a, [wReadBuf]
	swap a
	ld [wReadBuf], a
	jp SfxNoteHigh

MusicNote:
	res 2, [hl]
	call NextCmd
	dec de
	ld a, [wReadBuf]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l46EE
	ld b, a
	xor a
	bit 0, b
	jp nz, .l46F6
	rrc b
.l46E5:
	add a, c
	dec b
	jp nz, .l46E5
	add a, a
	jp NoteLen
.l46EE:
	swap c
	ld a, c
	and $F0
	jp NoteLen
.l46F6:
	add a, c
	dec b
	jp nz, .l46F6

; NoteLen: LEN = A. A rest mutes (NRx2 = 8; on the drum track the write goes to $FF00).
NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [wReadBuf]
	and $F0
	jp nz, Note
	set 0, [hl]
	ld a, $08
	jp WriteVolume

; Note: release tick = length x gate / 16. A duty step writes its start duty. Autopan.
; Pitch 13 = the last pitch + an octave. Period from PeriodTable - 26 + 2 x pitch + octave +
; transpose, + detune (when its low byte is not 0). Vibrato restarts. NRx2 = TRK_VOL -
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
	jp z, .l4732
	ld e, a
	ld b, $00
	ld hl, $0000
.l4727:
	add hl, bc
	dec e
	jp nz, .l4727
	ld a, l
	and $F0
	or h
	swap a
.l4732:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l4743
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l4743:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld a, [wReadBuf]
	and $F0
	cp $D0
	jp nz, .l4764
	ld l, TRK_PANFLAGS
	set 5, [hl]
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, TRK_LASTPITCH
	ld a, [hl]
	jp .l4771
.l4764:
	ld l, TRK_PANFLAGS
	res 5, [hl]
	swap a
	rlca
	ld l, TRK_LASTPITCH
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l4771:
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
	or a
	jp z, .l4794
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l4794:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l47C7
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jp nc, .l47B1
	set 4, [hl]
	jp .l47B3
.l47B1:
	res 4, [hl]
.l47B3:
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
.l47C7:
	call WritePeriod
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	jp WriteVolume

; Sustain (not SfxN, Drm, rests): duty step countdown, vibrato (after its delay), then
; the release: NRx2 = TRK_RELVOL, or env | level + trigger (env 0: 8); CH3 steps NR32
; down every env ticks. A pending long-note retrigger rewrites NRx2 before the release.
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
	jp z, .l47F2
	dec [hl]
	jp nz, .l47F2
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l47F2:
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
	jp z, .l480B
	dec [hl]
	jp ReleaseTick
.l480B:
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

VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, .l487B
	cp $FE
	jp z, .l48B3
	cp $FB
	jp z, .l4885
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
	jp z, .l4875
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jp nz, VibratoSemitone
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l485D
	and $07
	jp z, .l4875
	cpl
	inc a
	ld e, a
	ld d, $FF
.l485D:
	ld a, [hl]
	or a
	jp z, .l486A
	ld b, a
	xor a
.l4864:
	add a, e
	dec b
	jp nz, .l4864
	ld e, a
.l486A:
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
.l4875:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l487B:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4885:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l489A
	set 4, [hl]
	ld l, TRK_VIBLOOP
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l489A:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l48A9
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l48A9:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l48B3:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l48C5
	set 5, [hl]
	inc bc
	ld l, TRK_VIBMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l48C5:
	ld l, TRK_VIBMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l48DE
	sub $0D
	jr z, .l48DC
	dec a
	jr z, .l48DA
	add a, $0B
.l48DA:
	add a, $05
.l48DC:
	add a, $13
.l48DE:
	rlca
	ld c, a
	ld l, TRK_PITCHIDX
	ld a, [hl]
	add a, c
	ld e, a
	ld d, $00
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld c, [hl]
	push hl
	ld hl, PeriodTable - 26
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, c
	ld l, a
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
	jp z, .l4919
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4919:
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
	jp c, .l4957
	jp z, .l4954
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4954:
	ld a, [hl+]
	ld [hl], a
	ret
.l4957:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
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

; DrumNote: the drum hit id = the note's high nibble (bank 14), started on the SFX tracks
; of its header, each with its own priority test.
DrumNote:
	ld a, [wReadBuf]
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
	jp c, .l49E6
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
	ld a, $C0
	cp h
	jp nz, .l49D5
	ld a, $08
	ld c, $10
	ldh [c], a
.l49D5:
	ld a, $C2
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
.l49E6:
	inc de
	inc de
	ret

; NoiseNote: LEN = unit. < $C0 NR43 = byte, NR44 = 0 (checked), retrigger if marked; $C0
; marks a retrigger; $C1-$CF set the volume nibble, write NR42 at once and mark; $D0-$DF set
; it and retrigger now ($D0: NR42 = 8).
NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [wReadBuf]
	call NextCmd
	cp $C0
	ld l, TRK_FLAGS3
	jr c, NoiseFreq
	set 2, [hl]
	jp z, ReadCmds
	and $0F
	swap a
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $0F
	or b
	ld [hl], a
	ld a, [wReadBuf]
	bit 4, a
	jr nz, .l4A1A
	ld a, [hl]
	call WriteVolumeNow
	jp ReadCmds
.l4A1A:
	inc de
	and $0F
	jp z, .l4A25
	ld l, TRK_LASTVOL
	ld a, [hl]
	jr .l4A27
.l4A25:
	ld a, $08
.l4A27:
	call WriteVolumeNow
	jr NoiseTrigger

NoiseFreq:
	ld e, a
	ld d, $00
	call WritePeriod

NoiseTrigger:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS3
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld a, $80
	ldh [c], a
	ret

; Command: $E0 voice, $E1-$E6 octave (OctaveCodes), $E7-$FF through CommandTable (from
; CommandTable - 14). Arguments come from wReadBuf; each consumed byte is an inc de.
Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
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
	dw Cmd_Fade
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

; Cmd_Voice: unit = u & $7F. u bit 7: NRx2 = swap(v) at once and a retrigger mark (3 bytes).
; Else duty, vol, gate, env, autopan off, attenuation 0, release volume 0, both sides.
Cmd_Voice:
	ld a, [wReadBuf + $01]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wReadBuf + $01]
	ld l, TRK_FLAGS
	rlca
	inc de
	jr c, VoiceNoise
	res 1, [hl]
	ld a, [wReadBuf + $02]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [wReadBuf + $02]
	and $0F
	swap a
	inc de
	ld l, TRK_VOL
	ld [hl], a
	ld a, [wReadBuf + $03]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [wReadBuf + $03]
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
	inc de
	jp ReadCmds

VoiceNoise:
	ld l, TRK_FLAGS3
	set 2, [hl]
	ld a, [wReadBuf + $02]
	swap a
	call WriteVolumeNow
	inc de
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
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	inc de
	jp ReadCmds

; Cmd_Ext: $EA xy through ExtTable (11 entries; x >= $B runs into the code).
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
	dw Ext_PanLeft
	dw Ext_PanRight
	dw Ext_Autopan
	dw Ext_AutopanBoth
	dw Ext_Nop
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
	inc de
	jp ReadCmds

Ext_PanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	inc de
	jp ReadCmds

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4B7A
.l4B74:
	sla b
	dec a
	jp nz, .l4B74
.l4B7A:
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
	inc de
	jp ReadCmds

Ext_PanRight:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanRight
	inc de
	jp ReadCmds

AutoPan:
	bit 6, [hl]
	jp nz, .l4BAB
	bit 1, [hl]
	jp nz, PanRight.l4BD8
	set 1, [hl]
	jp PanRight
.l4BAB:
	bit 1, [hl]
	jp z, .l4BB5
	res 1, [hl]
	jp PanBoth
.l4BB5:
	set 1, [hl]

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4BCC
.l4BC4:
	rlc b
	rlc l
	dec a
	jp nz, .l4BC4
.l4BCC:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l4BD8:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4BEF
.l4BE7:
	rlc b
	rlc l
	dec a
	jp nz, .l4BE7
.l4BEF:
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
	res 6, [hl]
	inc de
	jp ReadCmds

Ext_AutopanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 6, [hl]
	set 1, [hl]
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
	jp z, .l4C29
	rlca
	cpl
	inc a
.l4C29:
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp ReadCmds

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
	jr z, .l4C49
	ld l, TRK_VIB
	ld [hl], a
.l4C49:
	bit 2, b
	jr z, .l4C52
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld [hl-], a
	ld [hl], a
.l4C52:
	bit 1, b
	jr z, .l4C5A
	ld l, TRK_DETUNE
	ld [hl+], a
	ld [hl], a
.l4C5A:
	bit 0, b
	jp z, ReadCmds
	ld l, TRK_ATTEN
	ld [hl], a
	jp ReadCmds

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l4CAD
	bit 7, [hl]
	jp nz, .l4CB1
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
	swap a
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jr z, .l4CA3
	ld b, a
	xor a
	bit 0, b
	jr nz, .l4C9F
	rrc b
.l4C98:
	add a, c
	dec b
	jr nz, .l4C98
	add a, a
	jr .l4CA3
.l4C9F:
	add a, c
	dec b
	jr nz, .l4C9F
.l4CA3:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [wReadBuf + $02]
	and $0F
	inc l
	ld [hl], a
.l4CAD:
	inc de
	jp ReadCmds
.l4CB1:
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
	inc de
	jp ReadCmds

; Cmd_Fade: wFadeRate = x.
Cmd_Fade:
	ld hl, wFadeRate
	ld [hl], a

NextArg:
	pop hl
	inc de
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
	jp z, .l4D04
	ld a, $FF
.l4D04:
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Atten:
	pop hl
	dec de
	ld a, [wReadBuf]

; SetAtten: TRK_ATTEN = y << 4 (CH3: cpl(rlc(y << 4))).
SetAtten:
	and $0F
	swap a
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l4D1F
	rlca
	cpl
.l4D1F:
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

; Cmd_Volume: TRK_VOL = swap(x), TRK_ATTEN = 0.
Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_JumpN:
	pop hl
	ld l, TRK_JUMPCNT
	inc [hl]
	cp [hl]
	inc de
	jp z, .l4D42
	inc de
	inc de
	jp ReadCmds
.l4D42:
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

Cmd_Loop1:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l4D71
	set 0, [hl]
	ld l, TRK_LOOP1
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l4D71:
	ld l, TRK_LOOP1CNT
	inc [hl]
	cp [hl]
	jp z, .l4D7F
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l4D7F:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp ReadCmds

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l4D9E
	set 1, [hl]
	ld l, TRK_LOOP2
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l4D9E:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l4DAC
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l4DAC:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp ReadCmds

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l4DD0
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
.l4DD0:
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
	jp nz, .l4DEC
	set 3, [hl]
	ld l, TRK_MARK
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l4DEC:
	ld l, TRK_MARK
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; Cmd_End: clear priority and id. Drm: nothing else. Sfx1 (NR10 = 8) and Sfx2 give CH1 /
; CH3 back to a playing music track. Then the channel is muted (CH3: NR32 = 0, else NRx2 = 8
; + trigger).
Cmd_End:
	pop hl
	ld l, TRK_ID
	xor a
	ld a, $00
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, .l4E26
	cp $40
	jp z, .l4E0F
	jp MuteChannel
.l4E0F:
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
.l4E26:
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

Ext_Nop:
	pop hl
	inc de
	jp ReadCmds

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
	jp z, .l4E5A
.l4E54:
	rlc b
	dec a
	jp nz, .l4E54
.l4E5A:
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
	jp z, .l4EA4
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
.l4EA4:
	xor a
	ld c, $1C
	jp WriteRegChecked

MutedByte:
	call NextCmd

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
	jp nz, .l4ECD
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
.l4ECD:
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

WriteVolumeNow:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh [c], a
	ret

; WriteDuty: NRx1 = A. CH3: the wave (high nibble) if it is not the one loaded (wWaveId);
; music Ch3 only keeps it while Sfx2 plays.
WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l4F01
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jp WriteRegChecked
.l4F01:
	ld a, [wTrackDesc]
	cp $22
	jp nz, .l4F15
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_LASTDUTY
	ld [hl], b
	ret nz
.l4F15:
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
.l4F33:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l4F33
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
	jp z, .l4F69
	cp $22
	jp nz, .l4F75
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
.l4F69:
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
.l4F75:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: priority and id of all tracks cleared; NRx2 = 8 on CH1, CH2, CH4, NR30 = 8 and
; NR32 = 8; triggers on CH1, CH2, CH4; NR10 = 8; NR51 = $FF.
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
	ld c, $10
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

Snd0C_Ch2:
	TEMPO $08
	TRANSPOSE_DOWN 3
	VOICE $06, 0, 9, 10, 3
	DUTY_STEP 4, 1
	DETUNE $01
	VIBRATO 18, 2, 4
	REST $0F
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	DUTY 4
	LEN_UNIT $01
	OCTAVE 3
	NOTE E_, 1
	DUTY_STEP 0, 0
	NOTE F_, 1
	NOTE F#, 1
	LEN_UNIT $03
	NOTE G_, 4
	LEN_UNIT $01
	ATTEN 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOICE $06, 4, 9, 13, 4
	DUTY_STEP 8, 1
	NOTE A_, 3
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 7
	NOTE A_, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE $0B, 4
	VIBRATO 18, 4, 6
	RELEASE_VOL 3
	NOTE B_, $0B
	VOICE $06, 0, 9, 10, 4
	VIBRATO_SEMI $13
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	VOLUME $08
	PAN_LEFT 0
	ATTEN 7
	NOTE E_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	ATTEN 7
	NOTE E_, 1
	NOTE E_, 2
	SND_END

Snd0C_Ch1:
	TRANSPOSE_DOWN 3
	VOICE $06, 0, 8, 10, 3
	DUTY_STEP 4, 1
	REST $0F
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	LEN_UNIT $01
	DUTY 0
	DUTY_STEP 0, 0
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	DUTY_STEP 0, 0
	NOTE C_, 1
	NOTE C#, 1
	LEN_UNIT $03
	OCTAVE 3
	NOTE D_, 4
	LEN_UNIT $01
	ATTEN 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	LEN_UNIT $06
	DUTY_STEP 4, 1
	RELEASE $0D, 4
	NOTE E_, 3
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	RELEASE $0F, 7
	VIBRATO 17, 3, 4
	NOTE F#, 2
	DETUNE $FF
	PAN_RIGHT 0
	DUTY 8
	VIBRATO_SEMI $13
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	PAN_BOTH 0
	NOTE B_, 1
	NOTE G_, 1
	PAN_LEFT 0
	NOTE A_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 1
	NOTE D_, 1
	VOICE $06, 0, 9, 10, 4
	VIBRATO_SEMI $13
	PAN_BOTH 0
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	VOLUME $08
	PAN_LEFT 0
	ATTEN 7
	NOTE B_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	ATTEN 7
	NOTE B_, 1
	NOTE B_, 2
	SND_END

Snd0C_Ch3:
	TRANSPOSE_DOWN 3
	VOICE $06, 4, 2, 3, 4
	RELEASE_VOL 4
	VIBRATO_SEMI $12
	REST $0F
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE A_, 1
	NOTE D_, 1
	WAVE 5
	PAN_BOTH 0
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	SND_END

Snd0C_Drm:
	LEN_UNIT $03
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 4, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 7, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_END

Snd0D_Ch2:
	TEMPO $08
	TRANSPOSE_DOWN 3
	VOICE $06, 4, 7, 10, 5
	VIBRATO_SEMI $13
	REST $0F
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	TRANSPOSE_UP 9
	ATTEN 0
	PAN_BOTH 0
	DETUNE $01
	DUTY 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	DETUNE $00
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	NOTE D_, 1
	VOICE $06, 4, 7, 11, 4
	PAN_BOTH 0
	VIBRATO_SEMI $13
	OCTAVE 3
	NOTE E_, 1
	ATTEN 7
	PAN_LEFT 0
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	NOTE E_, 1
	NOTE E_, 2
	SND_END

Snd0D_Ch1:
	TRANSPOSE_DOWN 3
	VOICE $06, 4, 7, 10, 5
	VIBRATO_SEMI $13
	REST $0F
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	DETUNE $FD
	LEN_UNIT $06
	RELEASE_VOL 0
	ATTEN 0
	PAN_LEFT 0
	DUTY 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	TRANSPOSE_UP 9
	VOLUME $04
	LEN_UNIT $03
	REST 1
	LEN_UNIT $06
	VIBRATO 17, 0, 3
	DETUNE $01
	PAN_RIGHT 0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	ATTEN 1
	NOTE A_, 1
	LEN_UNIT $03
	NOTE D_, 1
	VOICE $06, 4, 7, 11, 4
	PAN_BOTH 0
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 1
	ATTEN 7
	PAN_LEFT 0
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	NOTE E_, 1
	NOTE E_, 2
	SND_END

Snd0D_Ch3:
	TRANSPOSE_DOWN 3
	VOICE $06, 11, 2, 3, 4
	RELEASE_VOL 4
	VIBRATO_SEMI $12
	REST $0F
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE A_, 1
	NOTE D_, 1
	WAVE 5
	PAN_BOTH 0
	OCTAVE 2
	ATTEN 0
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE E_, 1
	OCTAVE 3
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	SND_END

Snd0D_Drm:
	LEN_UNIT $03
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 4, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 7, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_END

Snd0E_Ch2:
	TRANSPOSE_DOWN 0
	VOICE $06, 4, 9, 14, 6
	DETUNE $01
	AUTOPAN 0
	VIBRATO 20, 0, 5
	REST 9
	ATTEN 6
	OCTAVE 1
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 3
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE C_HI, 1
	NOTE G#, 1
	ATTEN 0
	LEN_UNIT $03
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	DUTY_STEP 8, 1
	LEN_UNIT $06
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 5
	NOTE G_, 3
	NOTE F#, 4
	DUTY_STEP 0, 0
	VIBRATO 18, 0, 6
	VOICE $06, 4, 2, 15, 10
	NOTE F#, 4
	VIBRATO_SEMI $13
	VOICE $06, 0, 9, 8, 7
	OCTAVE 4
	NOTE E_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ATTEN 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 3
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $02
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
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
	VOLUME $01
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
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
	SND_END

Snd0E_Ch1:
	TRANSPOSE_DOWN 0
	VOICE $06, 0, 8, 14, 5
	VIBRATO 20, 0, 8
	DETUNE $FD
	REST 9
	ATTEN 4
	OCTAVE 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE G#, 1
	LEN_UNIT $03
	DETUNE $00
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	LEN_UNIT $06
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 5
	OCTAVE 3
	NOTE E_, 3
	NOTE D_, 5
	DUTY 0
	DUTY_STEP 4, 1
	ATTEN 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	VIBRATO_SEMI $13
	VOICE $06, 0, 8, 8, 7
	OCTAVE 3
	NOTE B_, 1
	VOLUME $03
	PAN_LEFT 0
	OCTAVE 4
	NOTE E_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ATTEN 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $01
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
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
	SND_END

Snd0E_Ch3:
	TRANSPOSE_DOWN 0
	DETUNE $FF
	VOICE $06, 11, 2, 6, 7
	RELEASE_VOL 4
	VIBRATO_SEMI $11
	REST 9
	OCTAVE 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE D_, 8
	OCTAVE 1
	NOTE E_, 2
	SND_END

Snd0E_Drm:
	LEN_UNIT $03
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 4, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 7, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	SND_END

Snd0F_Ch2:
	TRANSPOSE_DOWN $0C
	LEN_UNIT $08
	REST 6
	SND_SEGNO
	VOICE $08, 4, 7, 13, 7
	VIBRATO 18, 1, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE C#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 2
	NOTE G#, 1
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE F_, 1
	NOTE F#, 1
	RELEASE 9, 7
	NOTE G#, 6
	VIBRATO_SEMI $13
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 4
	DUTY 0
	VIBRATO 18, 1, 2
	RELEASE $0D, 7
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 1
	NOTE G_, 1
	VIBRATO 18, 2, 4
	RELEASE 9, 7
	NOTE A_, 6
	DUTY 8
	ATTEN 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 1
	VIBRATO 18, 2, 3
	OCTAVE 5
	NOTE D_, 4
	SND_LOOP

Snd0F_Ch1:
	TRANSPOSE_DOWN $0C
	LEN_UNIT $08
	REST 6
	SND_SEGNO
	VOICE $08, 4, 6, 13, 7
	REST 2
	ATTEN 2
	PAN_RIGHT 0
	VIBRATO_SEMI $13
	DETUNE $02
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	PAN_LEFT 0
	NOTE F_, 1
	NOTE F#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE C#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 2
	PAN_RIGHT 0
	NOTE G#, 1
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 2
	PAN_LEFT 0
	NOTE F_, 1
	NOTE F#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 4
	PAN_BOTH 0
	DETUNE $00
	VIBRATO_SEMI $13
	RELEASE_VOL 4
	ATTEN 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE G#, 4
	DUTY 0
	RELEASE $0D, 7
	VIBRATO 18, 2, 3
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 8, 7
	NOTE F#, 6
	DUTY 8
	VIBRATO 18, 0, 4
	RELEASE_VOL 4
	ATTEN 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 4
	SND_LOOP

Snd0F_Ch3:
	TRANSPOSE_DOWN $0C
	VOICE $08, 11, 2, 6, 3
	RELEASE_VOL 6
	VIBRATO_SEMI $11
	REST 6
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	LOOP_END 4
	SND_LOOP

Snd0F_Drm:
	LEN_UNIT $04
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $08
	SND_SEGNO
	LOOP_START
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	LEN_UNIT $04
	DRUM 1, 1
	DRUM 2, 1
	LEN_UNIT $08
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	LEN_UNIT $04
	DRUM 1, 1
	DRUM 2, 1
	LEN_UNIT $08
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

Snd11_Ch2:
	TRANSPOSE_UP 1
	LEN_UNIT $08
	REST 2
	SND_SEGNO
	VOICE $08, 4, 8, 12, 7
	DUTY_STEP 8, 1
	VIBRATO 18, 2, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 3
	NOTE G_, 5
	NOTE G_, 3
	NOTE F#, 5
	NOTE F#, 3
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 5
	NOTE D_, 3
	NOTE E_, 5
	DUTY 0
	RELEASE $0A, 7
	ATTEN 2
	DUTY_STEP 8, 1
	LEN_UNIT $01
	NOTE G#, 1
	DUTY_STEP 0, 0
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $08
	NOTE E_, 2
	DUTY_STEP 8, 1
	NOTE D_, 5
	NOTE D_, 3
	RELEASE $0C, 7
	VIBRATO_SEMI $13
	NOTE E_, 2
	RELEASE $0A, 3
	ATTEN 5
	NOTE E_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_LOOP

Snd11_Ch1:
	LEN_UNIT $08
	REST 2
	TRANSPOSE_UP 1
	SND_SEGNO
	DETUNE $01
	VOICE $04, 4, 6, 12, 7
	DUTY_STEP 0, 1
	VIBRATO 17, 2, 1
	PAN_LEFT 0
	ATTEN 3
	OCTAVE 2
	NOTE F#, 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 1
	DETUNE $00
	LEN_UNIT $08
	ATTEN 0
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 3
	NOTE E_, 2
	DUTY 8
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	DUTY 4
	VIBRATO 17, 2, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 3
	NOTE D_, 2
	DUTY 8
	VIBRATO_SEMI $12
	PAN_RIGHT 0
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	DUTY 4
	VIBRATO 17, 2, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 3
	OCTAVE 2
	NOTE B_, 2
	DUTY 8
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	VIBRATO 17, 2, 1
	DUTY 4
	OCTAVE 2
	NOTE B_, 3
	DUTY_STEP 0, 0
	DUTY 0
	RELEASE $0B, 3
	DUTY 0
	VIBRATO_SEMI $13
	PAN_RIGHT 0
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	PAN_LEFT 0
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	VOLUME $07
	VIBRATO_SEMI $13
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0A, 3
	ATTEN 5
	NOTE C_, 1
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	SND_LOOP

Snd11_Ch3:
	LEN_UNIT $08
	REST 2
	TRANSPOSE_DOWN $0B
	VOICE $08, 13, 2, 7, 5
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	LOOP_END 4
	SND_LOOP

Snd11_Drm:
	LEN_UNIT $08
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP_START
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	LEN_UNIT $04
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $08
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $04
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $08
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

; Orphan music streams: eight streams that no header or call reaches (decoded as Ch1).
Data_568F:
	TEMPO $08
	TRANSPOSE_DOWN 2
	VOICE $09, 4, 8, 11, 7
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	REST 4
	SND_SEGNO
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE G_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE G_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE G_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A#, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE A#, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	SND_LOOP
Data_5762:
	TRANSPOSE_DOWN 2
	VOICE $09, 0, 8, 10, 7
	VIBRATO 17, 0, 0
	DUTY_STEP 8, 1
	REST 5
	SND_SEGNO
	DETUNE $02
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 3
	NOTE G_, 1
	DETUNE $02
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 3
	NOTE A_, 1
	DETUNE $02
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	DETUNE $02
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	DETUNE $00
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE F_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	DETUNE $02
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 3
	NOTE A_, 1
	SND_LOOP
Data_583F:
	TRANSPOSE_DOWN 2
	LEN_UNIT $09
	REST 4
	SND_SEGNO
	VOICE $09, 11, 2, 8, 7
	VIBRATO_SEMI $13
	RELEASE_VOL 4
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 1
	SND_LOOP
Data_585F:
	LEN_UNIT $01
	NOTE E_, 5
	NOTE E_, 4
	NOTE E_, 9
	NOTE E_, 9
	NOTE E_, 9
	LEN_UNIT $09
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_SEGNO
	LOOP_START
	NOTE A_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE A_, 1
	LOOP_END 7
	NOTE A_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 1
	LEN_UNIT $01
	NOTE D#, 5
	NOTE D#, 4
	LEN_UNIT $09
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_LOOP
Data_5896:
	TEMPO $18
	LEN_UNIT $08
	REST 3
	SND_SEGNO
	TRANSPOSE_UP 6
	LOOP2_START
	LOOP_START
	OCTAVE 2
	VOICE $04, 4, 10, 8, 4
	VIBRATO 18, 1, 2
	RELEASE_VOL 6
	ATTEN 5
	NOTE G_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	VIBRATO_SEMI $13
	DUTY 0
	RELEASE $0F, 3
	ATTEN 5
	NOTE D#, 2
	VIBRATO_OFF
	NOTE A#, 2
	VIBRATO_SEMI $13
	NOTE D_, 2
	ATTEN 4
	VIBRATO_OFF
	RELEASE $0F, 2
	NOTE A#, 2
	VIBRATO_SEMI $13
	NOTE C_, 2
	VIBRATO_OFF
	NOTE A#, 2
	VIBRATO_SEMI $13
	ATTEN 2
	NOTE D_, 2
	VIBRATO_OFF
	ATTEN 1
	NOTE A#, 2
	VIBRATO_SEMI $13
	ATTEN 0
	NOTE D#, 2
	VIBRATO_OFF
	RELEASE $0F, 3
	ATTEN 2
	NOTE A#, 2
	VIBRATO_SEMI $13
	ATTEN 3
	NOTE F_, 2
	VIBRATO_OFF
	ATTEN 4
	NOTE A#, 2
	LOOP_END 2
	TRANSPOSE_UP 5
	LOOP2_END 2
	SND_LOOP
Data_58EA:
	TRANSPOSE_UP 6
	VOICE $04, 4, 3, 0, 0
	REST 2
	DETUNE $FE
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	REST 6
	SND_SEGNO
	TRANSPOSE_UP 6
	LOOP2_START
	LOOP_START
	OCTAVE 2
	PAN_LEFT 0
	DUTY 4
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE F_, 1
	DUTY 0
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE F_, 1
	LOOP_END 2
	TRANSPOSE_UP 5
	LOOP2_END 2
	SND_LOOP
Data_594C:
	TRANSPOSE_UP 2
	VOICE $08, 4, 2, 8, 7
	RELEASE_VOL 6
	VIBRATO_SEMI $11
	REST 3
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 2
	SND_LOOP
Data_5977:
	LEN_UNIT $04
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE D#, 2
	LEN_UNIT $04
	SND_SEGNO
	NOTE A_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	SND_LOOP

Snd12_Ch2:
	TEMPO $10
	TRANSPOSE_DOWN $0B
	DETUNE $01
	VOICE $06, 4, 10, 15, 6
	DETUNE $01
	DUTY_STEP 8, 1
	REST 2
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G#, 1
	NOTE G_, 4
	LEN_UNIT $01
	NOTE E_, 1
	DUTY_STEP 0, 0
	NOTE F_, 1
	NOTE F#, 1
	LEN_UNIT $03
	NOTE G_, 5
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F#, 1
	DUTY_STEP 0, 0
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT $0A
	OCTAVE 3
	NOTE C_, $0F
	SND_END

Snd12_Ch1:
	TRANSPOSE_DOWN $0B
	VOICE $06, 4, 8, 15, 5
	VIBRATO 18, 2, 2
	DUTY_STEP 0, 1
	REST 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 4
	LEN_UNIT $01
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	DUTY_STEP 0, 1
	LEN_UNIT $03
	NOTE D_, 5
	DETUNE $02
	VOICE $0A, 8, 5, 8, 7
	PAN_LEFT 0
	OCTAVE 3
	NOTE C_, 0
	SND_END

Snd12_Ch3:
	TRANSPOSE_UP 1
	VOICE $06, 11, 2, 10, 7
	VIBRATO_SEMI $11
	REST 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	RELEASE 6, 7
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE G_, 3
	VOICE $0A, 4, 2, 7, 7
	DETUNE $FF
	OCTAVE 2
	NOTE C_, 0
	SND_END

Snd12_Drm:
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 4, 1
	SND_END
Snd15_Ch2_5A64:
	VOICE $06, 0, 8, 12, 6
	VIBRATO_SEMI $12
	DUTY_STEP 4, 1
	REST 4
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	LOOP_END 3
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	VIBRATO 18, 1, 2
	NOTE C_, 3
	SND_RET
Snd13_Ch2_5A8C:
	VOICE $06, 8, 8, 5, 6
	RELEASE_VOL 3
	DUTY_STEP 4, 1
	PAN_BOTH 0
	VIBRATO_SEMI $13
	ATTEN 1
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 3
	ATTEN 0
	NOTE D_, 3
	ATTEN 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 1
	ATTEN 2
	OCTAVE 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C#, 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 3
	NOTE C#, 1
	SND_RET
Snd13_Ch2_5AC2:
	OCTAVE 3
	NOTE D_, 3
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE_VOL 3
	ATTEN 5
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 2
	ATTEN 4
	NOTE C_, 1
	OCTAVE 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 1
	OCTAVE 1
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 3
	NOTE A#, 1
	ATTEN 4
	OCTAVE 2
	NOTE C_, 1
	DUTY 0
	PAN_BOTH 0
	DUTY_STEP 4, 1
	OCTAVE 3
	ATTEN 0
	NOTE F_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	DUTY 4
	OCTAVE 1
	NOTE A#, 1
	DUTY 0
	PAN_RIGHT 0
	ATTEN 6
	OCTAVE 3
	NOTE A_, 1
	DUTY 4
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 2
	NOTE C_, 1
	DUTY 0
	PAN_RIGHT 0
	ATTEN 6
	OCTAVE 3
	NOTE G_, 1
	SND_RET
Snd13_Ch2_5B1C:
	NOTE G_, 3
	NOTE G_, 1
	PAN_LEFT 0
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE G_, 1
	DUTY 0
	VIBRATO_OFF
	AUTOPAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 3
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	ATTEN 2
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	ATTEN 1
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd13_Ch2_5B5C:
	RELEASE_VOL 3
	NOTE G_, 3
	NOTE G_, 1
	PAN_LEFT 0
	VIBRATO_OFF
	ATTEN 5
	NOTE G_, 3
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 0
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 1
	OCTAVE 1
	NOTE D_, 1
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 1
	NOTE F_, 1
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	PAN_BOTH 0
	DUTY_STEP 8, 1
	VIBRATO_SEMI $13
	ATTEN 2
	OCTAVE 1
	NOTE F_, 1
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 1
	NOTE D#, 1
	PAN_LEFT 0
	DUTY 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 6
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	RELEASE_VOL 0
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 3
	SND_RET
Snd13_Ch2_5BC7:
	VOICE $06, 0, 9, 10, 2
	DUTY_STEP 4, 3
	OCTAVE 3
	VIBRATO_SEMI $13
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 1
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	DUTY_STEP 4, 3
	PAN_BOTH 0
	VIBRATO_SEMI $13
	ATTEN 0
	DUTY 0
	NOTE G_, 3
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE D_, 1
	ATTEN 3
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE A_, 1
	SND_RET
Snd13_Ch2_5C63:
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ATTEN 2
	DUTY 4
	ATTEN 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	SND_RET
Snd14_Ch2_5C93:
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 1
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 5
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 5
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 0
	VIBRATO 17, 1, 4
	OCTAVE 4
	NOTE D_, 3
	SND_RET
Snd14_Ch2_5CC4:
	VOICE $06, 8, 8, 3, 3
	DUTY_STEP 0, 1
	RELEASE_VOL 4
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE F#, 1
	NOTE F#, 1
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE C_, 1
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	NOTE D_, 1
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE F_, 1
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 4
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE D#, 1
	PAN_RIGHT 0
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE D_, 1
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE F#, 1
	NOTE F#, 1
	DUTY 0
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE E_, 1
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE A_, 1
	PAN_LEFT 0
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd14_Ch2_5D88:
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 1
	NOTE E_, 1
	DUTY 8
	VIBRATO 17, 2, 1
	RELEASE $0A, 7
	ATTEN 3
	OCTAVE 2
	NOTE B_, 3
	ATTEN 2
	OCTAVE 3
	NOTE C#, 4
	ATTEN 1
	NOTE D_, 4
	ATTEN 0
	NOTE E_, 4
	SND_RET
Snd14_Ch2_5D9F:
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO 17, 2, 3
	RELEASE $0A, 7
	OCTAVE 3
	NOTE E_, 8
	NOTE D#, 8
	SND_RET
Snd15_Ch2_5DAD:
	VOICE $06, 8, 8, 10, 7
	VIBRATO 17, 3, 1
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 4
	LEN_UNIT $02
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $06
	SND_RET
Snd15_Ch2_5DE2:
	RELEASE 6, 7
	NOTE E_, $0C
	SND_RET
Snd15_Ch2_5DE6:
	NOTE E_, 5
	DUTY 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
Snd15_Ch2_5DF3:
	VOICE $06, 4, 8, 10, 7
	VIBRATO 17, 3, 1
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 4
	LEN_UNIT $02
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $06
	SND_RET
Snd15_Ch1_5E28:
	VOICE $06, 0, 8, 13, 6
	DUTY_STEP 4, 2
	REST 4
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	LOOP_END 3
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	VIBRATO 17, 1, 3
	NOTE D#, 3
	SND_RET
Snd13_Ch1_5E4E:
	VOICE $06, 8, 7, 5, 6
	RELEASE_VOL 3
	DUTY_STEP 4, 1
	PAN_BOTH 0
	VIBRATO 18, 0, 3
	ATTEN 2
	DETUNE $FE
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	DETUNE $00
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 3
	ATTEN 0
	NOTE B_, 3
	ATTEN 1
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 1
	OCTAVE 2
	NOTE A_, 3
	DUTY 0
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE A_, 3
	NOTE A_, 1
	SND_RET
Snd13_Ch1_5E8B:
	OCTAVE 2
	NOTE A#, 3
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 3
	DUTY 0
	RELEASE_VOL 3
	OCTAVE 2
	ATTEN 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	ATTEN 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	ATTEN 1
	NOTE C_, 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	DUTY 0
	PAN_BOTH 0
	DUTY_STEP 4, 1
	OCTAVE 3
	ATTEN 0
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	ATTEN 2
	DUTY 8
	OCTAVE 2
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 6
	OCTAVE 3
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	SND_RET
Snd13_Ch1_5EE1:
	OCTAVE 3
	NOTE D#, 3
	NOTE D#, 1
	PAN_LEFT 0
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE D#, 1
	DUTY 0
	VIBRATO_OFF
	AUTOPAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 2
	ATTEN 0
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 2
	OCTAVE 3
	ATTEN 0
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 6
	PAN_LEFT 0
	NOTE D#, 1
	NOTE D#, 1
	SND_RET
Snd13_Ch1_5F26:
	OCTAVE 3
	NOTE D#, 3
	NOTE D#, 1
	PAN_LEFT 0
	VIBRATO_OFF
	ATTEN 5
	NOTE D#, 3
	NOTE D#, 1
	PAN_BOTH 0
	DUTY 4
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 1
	NOTE D_, 1
	DUTY 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	DUTY 4
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	DUTY 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN_BOTH 0
	DUTY 4
	DUTY_STEP 8, 1
	VIBRATO_SEMI $13
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	DUTY 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY 4
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 2
	NOTE D#, 1
	DUTY 0
	PAN_LEFT 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 6
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	RELEASE_VOL 0
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 3
	SND_RET
Snd13_Ch1_5FA1:
	VOICE $06, 0, 7, 10, 2
	DUTY_STEP 4, 3
	OCTAVE 3
	VIBRATO_SEMI $13
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	RELEASE $0A, 7
	PAN_LEFT 0
	ATTEN 7
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	OCTAVE 2
	NOTE A_, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE D_, 1
	RELEASE $0A, 2
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $0A, 7
	DUTY_STEP 4, 3
	PAN_BOTH 0
	VIBRATO_SEMI $13
	ATTEN 0
	DUTY 0
	NOTE E_, 3
	RELEASE $0A, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 1
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	RELEASE $0A, 7
	PAN_RIGHT 0
	ATTEN 7
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE F#, 1
	RELEASE $0A, 2
	SND_RET
Snd13_Ch1_6055:
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	DUTY_STEP 8, 1
	VIBRATO_OFF
	ATTEN 2
	DUTY 4
	RELEASE $0A, 7
	ATTEN 3
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE $0A, 2
	SND_RET
Snd14_Ch1_6089:
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 5
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 4
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	RELEASE $0A, 7
	VIBRATO 17, 1, 4
	NOTE B_, 3
	SND_RET
Snd14_Ch1_60BB:
	VOICE $06, 8, 8, 3, 3
	DUTY_STEP 0, 1
	RELEASE_VOL 4
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D_, 1
	NOTE D_, 1
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 6
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	ATTEN 3
	VIBRATO_OFF
	OCTAVE 4
	NOTE F#, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	VIBRATO_SEMI $12
	PAN_BOTH 0
	ATTEN 0
	DUTY 0
	OCTAVE 2
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 2
	VIBRATO_OFF
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	VIBRATO_SEMI $12
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO_SEMI $12
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D#, 1
	NOTE D#, 1
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 6
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F_, 1
	DUTY 4
	VIBRATO_OFF
	ATTEN 3
	OCTAVE 4
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 4
	ATTEN 6
	NOTE D_, 1
	PAN_BOTH 0
	VIBRATO_SEMI $12
	ATTEN 0
	DUTY 0
	OCTAVE 2
	NOTE D#, 1
	VIBRATO_OFF
	PAN_RIGHT 0
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE D_, 1
	VIBRATO_SEMI $12
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO_SEMI $13
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D_, 1
	NOTE D_, 1
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 6
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE E_, 1
	VIBRATO_OFF
	ATTEN 3
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	PAN_LEFT 0
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	VIBRATO_SEMI $12
	PAN_BOTH 0
	ATTEN 0
	DUTY 0
	OCTAVE 2
	NOTE A_, 1
	VIBRATO_OFF
	PAN_LEFT 0
	DUTY 4
	OCTAVE 4
	ATTEN 6
	NOTE F#, 1
	VIBRATO_SEMI $12
	DUTY 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd14_Ch1_619B:
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 1
	NOTE A_, 1
	DUTY 8
	VIBRATO 18, 0, 7
	RELEASE $0A, 7
	ATTEN 3
	OCTAVE 2
	NOTE G_, 3
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	SND_RET
Snd14_Ch1_61B1:
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO 17, 1, 5
	RELEASE 8, 7
	OCTAVE 3
	NOTE C#, 8
	NOTE C_, 8
	SND_RET
Snd15_Ch1_61BF:
	VOICE $06, 4, 6, 10, 7
	VIBRATO 18, 1, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE B_, 3
	VOLUME $07
	VIBRATO_SEMI $12
	DUTY 8
	DUTY_STEP 4, 1
	PAN_LEFT 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN_RIGHT 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	PAN_BOTH 0
	DUTY 4
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 4
	ATTEN 0
	VOLUME $06
	SND_RET
Snd15_Ch1_6213:
	VOLUME $06
	OCTAVE 3
	NOTE D_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE D_, 6
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	AUTOPAN 0
	ATTEN 3
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE B_, 4
	DUTY 8
	VIBRATO_SEMI $12
	DUTY_STEP 4, 1
	ATTEN 0
	PAN_BOTH 0
	VOLUME $07
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	NOTE D_, 2
	VOLUME $06
	SND_RET
Snd15_Ch1_6258:
	VOLUME $06
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE B_, 2
	SND_RET
Snd15_Ch1_627E:
	VOLUME $06
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	NOTE A_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 3
	SND_RET
Snd15_Ch1_629B:
	VOLUME $06
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE B_, 5
	PAN_BOTH 0
	ATTEN 0
	DUTY 4
	DUTY 4
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_RET

; Orphan subroutine (no SND_CALL reaches it; decoded as Ch1).
Data_62B7:
	DETUNE $FF
	VOICE $06, 4, 4, 4, 7
	VIBRATO 18, 2, 1
	PAN_LEFT 0
	REST 3
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 4
	LEN_UNIT $02
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $06
	RELEASE 6, 7
	NOTE E_, $0C
	SND_RET
Snd15_Ch1_62F6:
	VOICE $06, 0, 7, 10, 7
	VIBRATO 18, 1, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	PAN_RIGHT 0
	ATTEN 3
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 3
	NOTE B_, 3
	VIBRATO_SEMI $12
	DUTY 8
	DUTY_STEP 4, 1
	VOLUME $07
	PAN_LEFT 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN_RIGHT 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	PAN_BOTH 0
	DUTY 4
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 4
	ATTEN 0
	SND_RET
Snd15_Ch3_6348:
	DETUNE $FC
	LEN_UNIT $06
	REST 4
	VOICE $06, 13, 2, 6, 7
	RELEASE_VOL 6
	VIBRATO_SEMI $11
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	LOOP_END 3
	OCTAVE 2
	NOTE F_, 1
	NOTE C_HI, 2
	NOTE F_, 1
	SND_RET
Snd13_Ch3_6363:
	LOOP_START
	VOICE $06, 13, 2, 7, 4
	RELEASE_VOL 4
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 2
	SND_RET
Snd13_Ch3_638F:
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	WAVE $0B
	VIBRATO_SEMI $13
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	WAVE 4
	VIBRATO_OFF
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	SND_RET
Snd13_Ch3_63CE:
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 1
	SND_RET
Snd13_Ch3_6402:
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	WAVE $0B
	VIBRATO_SEMI $13
	NOTE C_, 2
	NOTE C_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd13_Ch3_643A:
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE F_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0B
	VIBRATO_SEMI $13
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 2
	WAVE $0B
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	WAVE 4
	VIBRATO_OFF
	NOTE F_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	SND_RET
Snd13_Ch3_647A:
	VOICE $06, 13, 2, 8, 7
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	RELEASE_VOL 0
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE_VOL 4
	OCTAVE 2
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 1
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 1
	REST 4
	SND_RET
Snd14_Ch3_6500:
	VOICE $06, 4, 2, 8, 4
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE C_HI, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE C_HI, 1
	OCTAVE 2
	NOTE F_, 5
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	SND_RET
Snd15_Ch3_658C:
	VOICE $06, 4, 2, 5, 4
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE F#, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE D_, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_HI, 3
	NOTE A_, 2
	NOTE G#, 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 2
	SND_RET
Snd15_Ch3_6605:
	TRANSPOSE_UP $0F
	DETUNE $00
	VOICE $06, 1, 2, 0, 0
	VIBRATO 18, 4, 0
	RELEASE_VOL 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE G_, 7
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE F#, 5
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE D_, 3
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE E_, $0D
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE F#, 3
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE G_, 3
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE E_, 3
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE E_, 3
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE E_, $0D
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE G_, 7
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE F#, 5
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE D_, 3
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE E_, $0D
	ATTEN 1
	NOTE A_, 4
	NOTE G_, 4
	ATTEN 2
	NOTE A_, 4
	NOTE B_, 2
	NOTE E_, 4
	OCTAVE 5
	NOTE E_, 5
	REST $0E
	SND_RET
Snd15_Drm_6691:
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	LEN_UNIT $03
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $06
	SND_RET
Snd13_Drm_66B5:
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	LEN_UNIT $03
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $06
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	LOOP_END 3
	SND_RET
Snd13_Drm_66DF:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_RET
Snd13_Drm_6700:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_RET
Snd13_Drm_6721:
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	LOOP_END 3
	SND_RET
Snd13_Drm_6735:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_RET
Snd13_Drm_6746:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd14_Drm_675C:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	LOOP_END 3
	SND_RET
Snd14_Drm_6772:
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	SND_RET
Snd14_Drm_6783:
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_RET
Snd15_Drm_6794:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	SND_RET
Snd15_Drm_67BA:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	SND_RET
Snd15_Drm_67DB:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	SND_RET
Snd15_Drm_67FC:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0A, 4
	SND_RET

Snd13_Ch2:
	LEN_UNIT $06
	REST 0
	LOOP2_START
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B1C
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B5C
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd13_Ch2_5C63
	SND_JUMP_N 2, Snd13_Ch2_684D
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd13_Ch2_5C63
Snd13_Ch2_684D:
	LOOP2_END 2
	VOICE $06, 0, 9, 10, 2
	DUTY_STEP 4, 3
	OCTAVE 3
	VIBRATO_SEMI $13
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 1
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	DUTY_STEP 4, 3
	PAN_BOTH 0
	VIBRATO_SEMI $13
	ATTEN 0
	DUTY 0
	NOTE G_, 3
	NOTE A_, 2
	FADE $20
	ATTEN 2
	NOTE A_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	PAN_BOTH 0
	VIBRATO_OFF
	DUTY 8
	DUTY_STEP 4, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE D_, 1
	ATTEN 3
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	DUTY_STEP 4, 3
	VIBRATO_SEMI $13
	DUTY 0
	ATTEN 0
	NOTE A_, 1
	SND_CALL Snd13_Ch2_5C63
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_END

Snd13_Ch1:
	LEN_UNIT $06
	REST 0
	SND_SEGNO
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5EE1
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5F26
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd13_Ch1_6055
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd13_Ch1_6055
	SND_LOOP

Snd13_Ch3:
	LEN_UNIT $06
	REST 0
	SND_SEGNO
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_638F
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_63CE
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_6402
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_643A
	SND_CALL Snd13_Ch3_647A
	SND_LOOP

Snd13_Drm:
	LEN_UNIT $03
	REST 0
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_66DF
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_6700
	LEN_UNIT $06
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6735
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6746
	SND_LOOP

Snd14_Ch2:
	VOICE $06, 4, 8, 11, 6
	DUTY_STEP 4, 1
	VIBRATO_SEMI $13
	REST 8
	OCTAVE 3
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE E_, 2
	PAN_RIGHT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE G_, 4
	LOOP2_START
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B1C
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B5C
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd13_Ch2_5C63
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd14_Ch2_5C93
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D88
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D9F
	LOOP2_END 2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	NOTE G_, 3
	NOTE G_, 1
	PAN_LEFT 0
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE G_, 1
	DUTY 0
	VIBRATO_OFF
	AUTOPAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 3
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	FADE $21
	ATTEN 2
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	ATTEN 1
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 3
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	SND_CALL Snd13_Ch2_5A8C
	SND_END

Snd14_Ch1:
	VOICE $06, 0, 8, 11, 6
	DUTY_STEP 4, 1
	VIBRATO_SEMI $13
	REST 8
	OCTAVE 3
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE C#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE C#, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE C#, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE C#, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE C#, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE C#, 2
	PAN_RIGHT 0
	ATTEN 5
	NOTE C#, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 4
	SND_SEGNO
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5EE1
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5F26
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd13_Ch1_6055
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd14_Ch1_6089
	DETUNE $FF
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_619B
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_61B1
	DETUNE $00
	SND_LOOP

Snd14_Ch3:
	VOICE $06, 13, 2, 7, 6
	VIBRATO_SEMI $13
	RELEASE_VOL 4
	REST 8
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	RELEASE_VOL 0
	NOTE F_, 4
	SND_SEGNO
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_638F
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_63CE
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_6402
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_643A
	SND_CALL Snd13_Ch3_647A
	SND_CALL Snd14_Ch3_6500
	SND_LOOP

Snd14_Drm:
	LEN_UNIT $03
	REST 8
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_66DF
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_6700
	LEN_UNIT $06
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6735
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6746
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6772
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6783
	SND_LOOP

Snd15_Ch2:
	TEMPO $02
	LEN_UNIT $06
	REST 5
	SND_CALL Snd15_Ch2_5A64
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B1C
	LOOP2_START
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B5C
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd13_Ch2_5C63
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd14_Ch2_5C93
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D88
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D9F
	LOOP2_END 2
	SND_CALL Snd15_Ch2_5DAD
	SND_CALL Snd15_Ch2_5DE2
	SND_CALL Snd15_Ch2_5DAD
	SND_CALL Snd15_Ch2_5DE6
	TRANSPOSE_UP 3
	SND_CALL Snd15_Ch2_5DF3
	SND_CALL Snd15_Ch2_5DE2
	VOICE $06, 4, 8, 10, 7
	VIBRATO 17, 3, 1
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	FADE $22
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE 0, 0
	ATTEN 1
	NOTE A_, 4
	ATTEN 3
	NOTE G_, 4
	RELEASE 8, 7
	ATTEN 4
	NOTE A_, 4
	ATTEN 6
	NOTE B_, 2
	ATTEN 7
	OCTAVE 3
	NOTE E_, 4
	DUTY_STEP 0, 0
	LEN_UNIT $02
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $06
	SND_CALL Snd15_Ch2_5DE2
	DETUNE $01
	SND_END

Snd15_Ch1:
	LEN_UNIT $06
	REST 5
	SND_CALL Snd15_Ch1_5E28
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5EE1
	LOOP2_START
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5F26
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd13_Ch1_6055
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd14_Ch1_6089
	DETUNE $FF
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_619B
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_61B1
	DETUNE $00
	LOOP2_END 2
	SND_CALL Snd15_Ch1_61BF
	SND_CALL Snd15_Ch1_6213
	SND_CALL Snd15_Ch1_61BF
	SND_CALL Snd15_Ch1_6258
	SND_CALL Snd15_Ch1_627E
	SND_CALL Snd15_Ch1_61BF
	SND_CALL Snd15_Ch1_6213
	SND_CALL Snd15_Ch1_61BF
	SND_CALL Snd15_Ch1_6258
	SND_CALL Snd15_Ch1_629B
	TRANSPOSE_UP 3
	SND_CALL Snd15_Ch1_62F6
	SND_CALL Snd15_Ch1_6213
	SND_CALL Snd15_Ch1_62F6
	SND_CALL Snd15_Ch1_6258
	SND_CALL Snd15_Ch1_627E
	DETUNE $FF
	VOICE $06, 4, 4, 4, 7
	VIBRATO 18, 2, 1
	PAN_LEFT 0
	REST 3
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 6
	NOTE D_, 4
	RELEASE 6, 7
	NOTE E_, $0E
	RELEASE $0A, 7
	NOTE A_, 4
	ATTEN 1
	NOTE G_, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 3
	NOTE B_, 2
	ATTEN 3
	OCTAVE 3
	NOTE E_, 4
	LEN_UNIT $02
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT $06
	RELEASE 2, 7
	NOTE E_, $0C
	SND_END

Snd15_Ch3:
	LEN_UNIT $06
	REST 5
	SND_CALL Snd15_Ch3_6348
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_638F
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_63CE
	LOOP2_START
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_6402
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_643A
	SND_CALL Snd13_Ch3_647A
	SND_CALL Snd14_Ch3_6500
	LOOP2_END 2
	LOOP_START
	SND_CALL Snd15_Ch3_658C
	LOOP_END 2
	TRANSPOSE_DOWN 9
	SND_CALL Snd15_Ch3_658C
	LOOP_START
	SND_CALL Snd15_Ch3_6605
	LOOP_END 2
	SND_END

Snd15_Drm:
	LEN_UNIT $06
	REST 5
	SND_CALL Snd15_Drm_6691
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_66DF
	LOOP2_START
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_6700
	LEN_UNIT $06
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6735
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6746
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6772
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6783
	LOOP2_END 2
	LEN_UNIT $06
	SND_CALL Snd15_Drm_6794
	SND_CALL Snd15_Drm_67BA
	SND_CALL Snd15_Drm_6794
	SND_CALL Snd15_Drm_67DB
	SND_CALL Snd15_Drm_6794
	SND_CALL Snd15_Drm_67FC
	SND_END

Snd16_Ch2:
	VOICE $06, 0, 8, 10, 7
	DUTY_STEP 8, 1
	VIBRATO_SEMI $13
	DETUNE $01
	REST 8
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE D_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 3
	DETUNE $00
	SND_SEGNO
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B1C
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5B5C
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd13_Ch2_5C63
	SND_CALL Snd13_Ch2_5BC7
	SND_CALL Snd14_Ch2_5C93
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D88
	SND_CALL Snd14_Ch2_5CC4
	SND_CALL Snd14_Ch2_5D9F
	SND_CALL Snd13_Ch2_5A8C
	SND_CALL Snd13_Ch2_5AC2
	VOICE $06, 8, 8, 5, 6
	RELEASE_VOL 3
	DUTY_STEP 4, 1
	PAN_BOTH 0
	VIBRATO_SEMI $13
	ATTEN 1
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE C#, 1
	ATTEN 2
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 1
	ATTEN 2
	OCTAVE 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 3
	FADE $1E
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 3
	NOTE C#, 1
	SND_CALL Snd13_Ch2_5B1C
	SND_LOOP

Snd16_Ch1:
	VOICE $06, 4, 7, 10, 7
	DUTY_STEP 8, 1
	VIBRATO 17, 1, 2
	REST 8
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 3
	SND_SEGNO
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5EE1
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5F26
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd13_Ch1_6055
	SND_CALL Snd13_Ch1_5FA1
	SND_CALL Snd14_Ch1_6089
	DETUNE $FF
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_619B
	SND_CALL Snd14_Ch1_60BB
	SND_CALL Snd14_Ch1_61B1
	DETUNE $00
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5E8B
	SND_CALL Snd13_Ch1_5E4E
	SND_CALL Snd13_Ch1_5EE1
	SND_LOOP

Snd16_Ch3:
	VOICE $06, 13, 2, 6, 6
	VIBRATO_SEMI $13
	DETUNE $FF
	REST 8
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 5
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 3
	DETUNE $00
	SND_SEGNO
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_638F
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_63CE
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_6402
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_643A
	SND_CALL Snd13_Ch3_647A
	SND_CALL Snd14_Ch3_6500
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_638F
	SND_CALL Snd13_Ch3_6363
	SND_CALL Snd13_Ch3_63CE
	SND_LOOP

Snd16_Drm:
	LEN_UNIT $03
	REST 8
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_66DF
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_6700
	LEN_UNIT $06
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6735
	SND_CALL Snd13_Drm_6721
	SND_CALL Snd13_Drm_6746
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6772
	SND_CALL Snd14_Drm_675C
	SND_CALL Snd14_Drm_6783
	SND_CALL Snd13_Drm_66B5
	SND_CALL Snd13_Drm_66DF
	SND_LOOP

Snd17_Ch2:
	TEMPO $18
	TRANSPOSE_UP 6
	LEN_UNIT $08
	REST 2
	LOOP2_START
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE E_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	VIBRATO 17, 2, 5
	RELEASE $0C, 7
	OCTAVE 2
	NOTE B_, 9
	VOICE $08, 8, 7, 13, 6
	VIBRATO 18, 0, 3
	OCTAVE 3
	ATTEN 0
	NOTE C#, 3
	ATTEN 1
	NOTE C_, 2
	VOICE $08, 4, 8, 10, 7
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE E_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	VIBRATO 18, 3, 5
	RELEASE 8, 7
	ATTEN 1
	NOTE B_, 7
	VOICE $08, 0, 4, 8, 7
	AUTOPAN 0
	VIBRATO_SEMI $13
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_JUMP_N 2, Snd17_Ch2_703A
	VOICE $08, 0, 8, 12, 7
	VIBRATO 37, 0, 1
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE E_, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 3
	NOTE E_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 3
	RELEASE $0A, 7
	OCTAVE 3
	NOTE C#, 5
	DUTY 4
	VIBRATO_SEMI $12
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 6
	PAN_RIGHT 0
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE B_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE B_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE G#, 1
	NOTE G#, 1
	RELEASE $0C, 7
	VIBRATO 37, 0, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 3
	NOTE G_, 2
	NOTE F#, 1
	NOTE D_, 3
	ATTEN 1
	NOTE B_, 5
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	RELEASE $0A, 7
	DUTY_STEP 8, 1
	VIBRATO_SEMI $13
	RELEASE $0A, 3
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 5
	PAN_LEFT 0
	NOTE B_, 1
	ATTEN 4
	PAN_BOTH 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 2
	VIBRATO_OFF
	DUTY_STEP 0, 0
	LEN_UNIT $01
	RELEASE 0, 0
	PAN_LEFT 0
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 0
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
Snd17_Ch2_703A:
	LOOP2_END 2
	VOICE $08, 8, 8, 11, 7
	VIBRATO 37, 0, 2
	DUTY_STEP 0, 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 3
	NOTE E_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 3
	RELEASE $0A, 7
	OCTAVE 3
	NOTE C#, 7
	PAN_BOTH 0
	DUTY 0
	VOICE $04, 4, 7, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	ATTEN 0
	NOTE G#, 1
	NOTE A_, 1
	LOOP_START
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 4
	PAN_RIGHT 0
	LOOP_END 2
	VOICE $08, 8, 8, 11, 7
	VIBRATO 37, 0, 2
	DUTY_STEP 0, 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 3
	NOTE E_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 3
	RELEASE $0B, 7
	VIBRATO_OFF
	LEN_UNIT $01
	OCTAVE 3
	NOTE D#, 1
	DUTY_STEP 0, 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	LEN_UNIT $08
	NOTE B_, 6
	DUTY 0
	DUTY_STEP 4, 1
	LEN_UNIT $04
	NOTE F#, 1
	NOTE G#, 1
	LEN_UNIT $08
	VIBRATO_SEMI $13
	RELEASE $0A, 7
	NOTE A_, 1
	NOTE G#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY_STEP 4, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE F#, 2
	DUTY_STEP 0, 0
	VIBRATO_OFF
	LEN_UNIT $01
	ATTEN 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	VOICE $08, 4, 8, 11, 7
	VIBRATO 37, 0, 2
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE E_, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 3
	NOTE E_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 3
	RELEASE $0A, 7
	OCTAVE 3
	NOTE C#, 5
	DUTY 0
	VIBRATO_SEMI $12
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 6
	PAN_RIGHT 0
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE B_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE B_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE G#, 1
	NOTE G#, 1
	RELEASE $0B, 7
	VIBRATO 37, 0, 2
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE E_, 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 3
	NOTE G_, 2
	NOTE F#, 1
	NOTE D_, 3
	ATTEN 1
	NOTE B_, 5
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	RELEASE 8, 7
	NOTE B_, $0C
	RELEASE 8, 7
	LEN_UNIT $01
	NOTE A_, $0B
	NOTE B_, $0A
	NOTE A_, $0B
	LEN_UNIT $08
	NOTE G#, $0D
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	FADE $20
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE E_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_CALL Snd17_Ch2_71C6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE A_, 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	VOICE $08, 4, 8, 13, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	VIBRATO 17, 2, 5
	RELEASE $0C, 7
	OCTAVE 2
	NOTE B_, 9
	VOICE $08, 8, 7, 13, 6
	VIBRATO 18, 0, 3
	OCTAVE 3
	ATTEN 0
	NOTE C#, 3
	ATTEN 1
	NOTE C_, 2
	VOICE $08, 4, 8, 10, 7
	DUTY_STEP 8, 1
	VIBRATO_OFF
	SND_END
Snd17_Ch2_71C6:
	RELEASE $0C, 7
	LEN_UNIT $01
	OCTAVE 2
	NOTE A#, 1
	DUTY_STEP 0, 0
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, $0C
	DUTY_STEP 8, 1
	LEN_UNIT $08
	NOTE C_, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	ATTEN 5
	DUTY 0
	PAN_LEFT 0
	RELEASE 2, 7
	LEN_UNIT $01
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A#, 1
	DUTY_STEP 0, 0
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	VIBRATO 17, 0, 1
	NOTE D_, $0C
	DUTY_STEP 8, 1
	LEN_UNIT $08
	PAN_RIGHT 0
	NOTE C_, 1
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE C_, 1
	VIBRATO_OFF
	VOICE $08, 0, 7, 13, 4
	PAN_BOTH 0
	DUTY_STEP 4, 1
	SND_RET

Snd17_Ch1:
	TRANSPOSE_UP 6
	LEN_UNIT $08
	REST 2
	SND_SEGNO
	LOOP2_START
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	SND_CALL Snd17_Ch1_758F
	NOTE A_, 2
	NOTE E_, 2
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE A_, 4
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	SND_CALL Snd17_Ch1_758F
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	PAN_LEFT 0
	ATTEN 4
	DUTY_STEP 0, 0
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE C_, 4
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	SND_CALL Snd17_Ch1_75C9
	NOTE A_, 2
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 4
	DUTY_STEP 0, 0
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE G_, 4
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	SND_CALL Snd17_Ch1_75C9
	VOICE $08, 8, 6, 10, 7
	OCTAVE 1
	NOTE B_, 1
	VIBRATO 17, 0, 4
	OCTAVE 2
	NOTE A_, 3
	ATTEN 1
	NOTE G#, 2
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	SND_CALL Snd17_Ch1_758F
	NOTE A_, 2
	NOTE E_, 2
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE A_, 4
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	VOICE $04, 4, 7, 15, 6
	DUTY_STEP 0, 0
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 5
	OCTAVE 2
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 4
	NOTE D_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 6
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE A_, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 5
	NOTE D_, 1
	VOICE $04, 4, 5, 12, 7
	PAN_BOTH 0
	DUTY_STEP 4, 1
	VIBRATO_OFF
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 4
	VOICE $04, 0, 8, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE A_, 2
	VOICE $04, 4, 7, 15, 6
	DUTY_STEP 0, 0
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 5
	OCTAVE 2
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 4
	NOTE E_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE E_, 1
	VOICE $04, 4, 5, 12, 7
	PAN_BOTH 0
	DUTY_STEP 4, 1
	VIBRATO_OFF
	NOTE B_, 2
	NOTE F_, 2
	ATTEN 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	NOTE F_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE G_, 4
	VOICE $08, 0, 7, 13, 3
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	VIBRATO 18, 3, 2
	RELEASE $0A, 7
	ATTEN 1
	NOTE G_, 6
	VOICE $08, 0, 6, 12, 7
	VIBRATO_SEMI $14
	DETUNE $FF
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	SND_JUMP_N 2, Snd17_Ch1_742B
	VOICE $04, 0, 5, 11, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 6
	NOTE G#, 4
	VOICE $04, 4, 7, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	PAN_LEFT 0
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	PAN_RIGHT 0
	NOTE C#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE D#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	VOICE $04, 0, 5, 11, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, $0A
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 6
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, $0A
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 6
	NOTE A_, 4
	NOTE G_, 2
	NOTE F#, 6
	DUTY_STEP 8, 1
	VIBRATO_SEMI $13
	RELEASE $0A, 3
	LEN_UNIT $08
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 5
	PAN_LEFT 0
	NOTE E_, 1
	ATTEN 3
	PAN_BOTH 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 2
	VIBRATO_OFF
	DUTY_STEP 0, 0
	LEN_UNIT $01
	RELEASE 0, 0
	PAN_LEFT 0
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	PAN_RIGHT 0
	ATTEN 4
	OCTAVE 3
	NOTE E_, 0
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
Snd17_Ch1_742B:
	LOOP2_END 2
	VOICE $04, 8, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 3
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 6
	NOTE G#, 4
	VOICE $04, 4, 6, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	DETUNE $FF
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE C#, 4
	PAN_LEFT 0
	DUTY 0
	ATTEN 4
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE D#, 2
	VOICE $04, 8, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	PAN_BOTH 0
	DETUNE $00
	OCTAVE 2
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 6
	OCTAVE 2
	NOTE G#, 2
	DUTY_STEP 0, 0
	VOLUME $07
	VIBRATO_OFF
	DETUNE $FF
	ATTEN 3
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 2
	VOICE $04, 4, 6, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_OFF
	DUTY 0
	DUTY_STEP 4, 1
	LEN_UNIT $04
	OCTAVE 3
	NOTE F#, 1
	NOTE G#, 1
	DETUNE $00
	RELEASE $0A, 7
	NOTE F#, 2
	NOTE D#, 2
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE D#, 2
	PAN_BOTH 0
	ATTEN 0
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE B_, 2
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 5
	NOTE B_, 2
	PAN_BOTH 0
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 3
	NOTE D#, 4
	LEN_UNIT $01
	DUTY_STEP 0, 0
	ATTEN 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	VOICE $04, 8, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 6
	NOTE G#, 4
	VOICE $04, 0, 7, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	PAN_LEFT 0
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	PAN_RIGHT 0
	NOTE C#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE D#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, $0A
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 6
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, $0A
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 6
	NOTE A_, 4
	NOTE G_, 2
	NOTE F#, 6
	LEN_UNIT $08
	PAN_BOTH 0
	VOICE $04, 0, 7, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	ATTEN 4
	PAN_RIGHT 0
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	LOOP_END 2
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	ATTEN 2
	PAN_LEFT 0
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	LOOP_END 2
	OCTAVE 2
	NOTE A_, 2
	PAN_RIGHT 0
	ATTEN 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 2
	PAN_LEFT 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 2
	ATTEN 0
	PAN_BOTH 0
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 2
	LOOP_END 2
	OCTAVE 2
	NOTE B_, 2
	SND_LOOP
Snd17_Ch1_758F:
	VOICE $04, 4, 7, 15, 6
	DUTY_STEP 0, 0
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 5
	OCTAVE 2
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 4
	NOTE E_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE E_, 1
	VOICE $04, 4, 5, 13, 5
	PAN_BOTH 0
	DUTY_STEP 4, 1
	VIBRATO_OFF
	SND_RET
Snd17_Ch1_75C9:
	VOICE $04, 4, 7, 15, 6
	DUTY_STEP 0, 0
	VIBRATO_SEMI $12
	PAN_LEFT 0
	ATTEN 5
	OCTAVE 2
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 6
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 4
	NOTE D_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE B_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	VOICE $04, 4, 6, 13, 5
	PAN_BOTH 0
	DUTY_STEP 4, 1
	VIBRATO_OFF
	SND_RET

; Orphan subroutine (no SND_CALL reaches it; decoded as Ch1).
Data_7603:
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE A_, $0A
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 6
	NOTE G#, 4
	VOICE $04, 0, 7, 14, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	PAN_LEFT 0
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	PAN_RIGHT 0
	NOTE C#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE E_, 2
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE D#, 2
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO 18, 2, 2
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, $0A
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 6
	VOICE $04, 0, 6, 13, 7
	DUTY_STEP 0, 0
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, $0A
	NOTE C_, 2
	NOTE E_, 2
	NOTE F#, 6
	NOTE A_, 4
	NOTE G_, 2
	NOTE F#, 6
	SND_RET

Snd17_Ch3:
	TRANSPOSE_DOWN 6
	LEN_UNIT $08
	REST 2
	VOICE $08, 13, 2, 4, 3
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_SEGNO
	LOOP2_START
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 2
	NOTE F_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE G_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE F_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE A_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE B_, 1
	RELEASE 2, 7
	OCTAVE 2
	NOTE B_, 3
	NOTE A#, 3
	NOTE G_, 1
	RELEASE 4, 3
	RELEASE_VOL 4
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 2
	NOTE F#, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE D_, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	VIBRATO_OFF
	NOTE C_HI, 1
	VIBRATO_SEMI $13
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	SND_JUMP_N 2, Snd17_Ch3_772A
	SND_CALL Snd17_Ch3_7774
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	REST 5
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
Snd17_Ch3_772A:
	LOOP2_END 2
	VOICE $08, 2, 2, 1, 7
	LOOP_START
	RELEASE 1, 7
	VIBRATO 17, 2, 5
	OCTAVE 2
	NOTE F#, 5
	OCTAVE 3
	NOTE C#, 1
	NOTE A_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 5
	OCTAVE 3
	NOTE D#, 1
	NOTE B_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 5
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE E_, 1
	LOOP_END 2
	SND_CALL Snd17_Ch3_7774
	LOOP_START
	NOTE E_, 1
	LOOP_END 8
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 2
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_LOOP
Snd17_Ch3_7774:
	RELEASE 4, 3
	RELEASE_VOL 4
	WAVE $0D
	OCTAVE 2
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	SND_RET

Snd17_Drm:
	LEN_UNIT $08
	LEN_UNIT $04
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $08
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	LEN_UNIT $04
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	LEN_UNIT $08
	DRUM 2, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	LEN_UNIT $04
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	LEN_UNIT $08
	SND_JUMP_N 2, Snd17_Drm_7857
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	LOOP_END 4
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
Snd17_Drm_7857:
	LOOP2_END 2
	LEN_UNIT $08
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	LEN_UNIT $04
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $08
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	LEN_UNIT $04
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $08
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	LEN_UNIT $04
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $08
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0A, 1
	LEN_UNIT $04
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $08
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	LOOP_END 5
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

Snd18_Ch2:
	TRANSPOSE_UP 1
	VOICE $0A, 0, 2, 10, 3
	RELEASE_VOL 1
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $03
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $04
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $05
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $06
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $07
	LOOP_START
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $07
	LOOP_END 9
	SND_SEGNO
	TRANSPOSE_UP 1
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 32
	LEN_UNIT $05
	DUTY 0
	RELEASE_VOL 0
	VIBRATO 37, 0, 8
	RELEASE $0D, 2
	TRANSPOSE_UP 2
	LOOP_START
	VOLUME $02
	OCTAVE 4
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_HI, 1
	VOLUME $03
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	VOLUME $04
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	VOLUME $05
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	VOLUME $04
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 2
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 2
	NOTE C_, 1
	VOLUME $03
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_HI, 1
	VOLUME $02
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_HI, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 1
	NOTE C_, 1
	LOOP_END 2
	VIBRATO_OFF
	LEN_UNIT $0A
	SND_LOOP
	db $FE ; unreachable

Snd18_Ch1:
	TRANSPOSE_UP 1
	VOICE $0A, 0, 2, 10, 3
	DETUNE $FA
	RELEASE_VOL 1
	AUTOPAN 0
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $03
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $04
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $05
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $06
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $07
	LOOP_START
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	VOLUME $07
	LOOP_END 9
	SND_SEGNO
	TRANSPOSE_UP 1
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 32
	TRANSPOSE_UP 2
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 32
	SND_LOOP

Snd18_Ch3:
	TRANSPOSE_UP 1
	VOICE $0A, 4, 6, 10, 3
	DETUNE $01
	OCTAVE 2
	LOOP_START
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	LOOP_END 4
	LOOP_START
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	LOOP_END 4
	VOLUME $04
	LOOP_START
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 4
	SND_SEGNO
	TRANSPOSE_UP 1
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 2
	TRANSPOSE_UP 2
	LOOP_START
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 2
	SND_LOOP

Snd18_Drm:
	LEN_UNIT $0A
	REST 0
	REST 0
	REST 0
	REST $0C
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 2
	SND_SEGNO
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM $0A, 1
	LEN_UNIT $05
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $0A
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_START
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LEN_UNIT $05
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $0A
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 3, 2
	LOOP_END 7
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LEN_UNIT $05
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LEN_UNIT $0A
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_LOOP

; Unused ($FF) to the end of the bank.
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF

SECTION "Sound bank 15", ROMX[$4000], BANK[15]

; SoundTable15: bank-15 ids $A1-$FF (the code adds 2 * (id - $A0) to $3FFE).
SoundTable15:
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
	dw SndHdrC0 ; $C0
	dw SndHdrC1 ; $C1
	dw SndHdrC2 ; $C2
	dw SndHdrC3 ; $C3
	dw SndHdrC4 ; $C4
	dw SndHdrC5 ; $C5
	dw SndHdrC6 ; $C6
	dw SndHdrC7 ; $C7
	dw SndHdrC8 ; $C8
	dw SndHdrC9 ; $C9
	dw SndHdrCA ; $CA
	dw SndHdrCB ; $CB
	dw SndHdrCC ; $CC
	dw SndHdrCD ; $CD
	dw SndHdrCE ; $CE
	dw SndHdrCF ; $CF
	dw SndHdrD0 ; $D0
	dw SndHdrD1 ; $D1
	dw SndHdrD2 ; $D2
	dw SndHdrD3 ; $D3
	dw SndHdrD4 ; $D4
	dw SndHdrD5 ; $D5
	dw SndHdrD6 ; $D6
	dw SndHdrD7 ; $D7
	dw SndHdrD8 ; $D8
	dw SndHdrD9 ; $D9
	dw SndHdrDA ; $DA
	dw SndHdrDB ; $DB
	dw SndHdrDC ; $DC
	dw SndHdrDD ; $DD
	dw SndHdrDE ; $DE
	dw SndHdrDF ; $DF
	dw SndHdrE0 ; $E0
	dw SndHdrE1 ; $E1
	dw SndHdrE2 ; $E2
	dw SndHdrE3 ; $E3
	dw SndHdrE4 ; $E4
	dw SndHdrE5 ; $E5
	dw SndHdrE6 ; $E6
	dw SndHdrE7 ; $E7
	dw SndHdrE8 ; $E8
	dw SndHdrE9 ; $E9
	dw SndHdrEA ; $EA
	dw SndHdrEB ; $EB
	dw SndHdrEC ; $EC
	dw SndHdrED ; $ED
	dw SndHdrEE ; $EE
	dw SndHdrEF ; $EF
	dw SndHdrF0 ; $F0
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
	dw SndHdrFB ; $FB
	dw SndHdrFC ; $FC
	dw SndHdrFD ; $FD
	dw SndHdrFE ; $FE
	dw SndHdrFF ; $FF

SndHdrA2:
	SND_HEADER $FF, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndA1_SfxN
	dw SndA1_SfxN
	dw SndA1_SfxN

SndHdrA1:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw SndA1_SfxN
	dw SndA1_Ch1
	dw SndA1_Ch2
	dw SndA1_Ch3
	dw SndA1_Drm

SndHdrA3:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw SndA3_Sfx1

SndHdrA4:
	SND_HEADER $90, $03 ; tracks: Sfx1, Sfx2
	dw SndA4_Sfx1
	dw SndA4_Sfx2

SndHdrA5:
	SND_HEADER $91, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndA4_Sfx1
	dw SndA5_Sfx2
	dw SndA5_SfxN

SndHdrA6:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw SndA6_Sfx1

SndHdrA7:
	SND_HEADER $A1, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndA7_Sfx1
	dw SndA7_Sfx2
	dw SndA1_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrA8:
	SND_HEADER $A1, $03 ; tracks: Sfx1, Sfx2
	dw SndA8_Sfx1
	dw SndA8_Sfx2

SndHdrA9:
	SND_HEADER $A0, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndA4_Sfx1
	dw SndA4_Sfx2
	dw SndA9_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrAA:
	SND_HEADER $A1, $03 ; tracks: Sfx1, Sfx2
	dw SndAA_Sfx1
	dw SndAA_Sfx2

SndHdrAB:
	SND_HEADER $A0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndAB_Sfx1
	dw SndAB_Sfx2
	dw SndAB_SfxN

SndHdrAC:
	SND_HEADER $A0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndAC_Sfx1
	dw SndAC_Sfx2
	dw SndAC_SfxN

SndHdrAD:
	SND_HEADER $A1, $03 ; tracks: Sfx1, Sfx2
	dw SndAD_Sfx1
	dw SndAD_Sfx2

SndHdrAE:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndAE_Sfx1
	dw SndAE_SfxN

SndHdrAF:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndAF_Sfx1
	dw SndAF_SfxN

SndHdrB0:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB0_Sfx1
	dw SndB0_SfxN

SndHdrB1:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw SndB1_Sfx1
	dw SndB1_SfxN

SndHdrB2:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw SndB2_Sfx1
	dw SndB2_SfxN

SndHdrB3:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw SndB3_Sfx1
	dw SndB3_SfxN

SndHdrB4:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB4_Sfx1
	dw SndB4_SfxN

SndHdrB5:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB5_Sfx1
	dw SndB5_SfxN

SndHdrB6:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB6_Sfx1
	dw SndB6_SfxN

SndHdrB7:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB7_Sfx1
	dw SndB7_SfxN

SndHdrB8:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndB8_Sfx1
	dw SndB8_SfxN

SndHdrB9:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndB9_Sfx1
	dw SndB9_SfxN

SndHdrBA:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndBA_Sfx1
	dw SndBA_SfxN

SndHdrBB:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndBB_Sfx1
	dw SndBB_SfxN

SndHdrBC:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndBC_Sfx1
	dw SndBC_SfxN

SndHdrBD:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndBD_Sfx1
	dw SndBD_SfxN

SndHdrBE:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndBE_Sfx1
	dw SndBE_SfxN

SndHdrBF:
	SND_HEADER $A1, $05 ; tracks: Sfx1, SfxN
	dw SndBF_Sfx1
	dw SndBF_SfxN

SndHdrC0:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndC0_Sfx1
	dw SndC0_SfxN

SndHdrC1:
	SND_HEADER $A4, $7D ; tracks: Sfx1, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndC1_Sfx1
	dw SndC1_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrC2:
	SND_HEADER $A4, $7D ; tracks: Sfx1, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndC2_Sfx1
	dw SndC2_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrC3:
	SND_HEADER $A4, $7D ; tracks: Sfx1, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndC3_Sfx1
	dw SndC3_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrC4:
	SND_HEADER $A4, $7D ; tracks: Sfx1, SfxN, Ch1, Ch2, Ch3, Drm
	dw SndC1_Sfx1
	dw SndC4_SfxN
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1
	dw SndA7_Ch1

SndHdrC5:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndC5_Sfx1
	dw SndC5_SfxN

SndHdrC6:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndC6_Sfx1
	dw SndC6_SfxN

SndHdrC7:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndC7_Sfx1
	dw SndC7_SfxN

SndHdrC8:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndC8_Sfx1
	dw SndC8_SfxN

SndHdrC9:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndC9_Sfx1
	dw SndC9_SfxN

SndHdrCA:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndCA_Sfx1
	dw SndCA_SfxN

SndHdrCB:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndCB_Sfx1
	dw SndCB_SfxN

SndHdrCC:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndCC_Sfx1
	dw SndCC_SfxN

SndHdrCD:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndCD_Sfx1
	dw SndCD_SfxN

SndHdrCE:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndCE_Sfx1
	dw SndCE_SfxN

SndHdrCF:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndCF_Sfx1
	dw SndCF_SfxN

SndHdrD0:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndD0_Sfx1
	dw SndD0_SfxN

SndHdrD1:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndD1_Sfx1
	dw SndD1_SfxN

SndHdrD2:
	SND_HEADER $A3, $05 ; tracks: Sfx1, SfxN
	dw SndD2_Sfx1
	dw SndD2_SfxN

SndHdrD3:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD3_Sfx1
	dw SndD3_SfxN

SndHdrD4:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD4_Sfx1
	dw SndD4_SfxN

SndHdrD5:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD5_Sfx1
	dw SndD5_SfxN

SndHdrD6:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD6_Sfx1
	dw SndD6_SfxN

SndHdrD7:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD7_Sfx1
	dw SndD7_SfxN

SndHdrD8:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD8_Sfx1
	dw SndD8_SfxN

SndHdrD9:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndD9_Sfx1
	dw SndD9_SfxN

SndHdrDA:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndDA_Sfx1
	dw SndDA_SfxN

SndHdrDB:
	SND_HEADER $A2, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndDB_Sfx1
	dw SndDB_Sfx2
	dw SndDB_SfxN

SndHdrDC:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndDC_Sfx1
	dw SndDC_SfxN

SndHdrDD:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndDD_Sfx1
	dw SndDD_SfxN

SndHdrDE:
	SND_HEADER $A4, $05 ; tracks: Sfx1, SfxN
	dw SndDE_Sfx1
	dw SndDE_SfxN

SndHdrDF:
	SND_HEADER $A4, $05 ; tracks: Sfx1, SfxN
	dw SndDF_Sfx1
	dw SndDF_SfxN

SndHdrE0:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndE0_Sfx1
	dw SndE0_SfxN

SndHdrE1:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndE1_Sfx1
	dw SndE1_SfxN

SndHdrE2:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndE2_Sfx1
	dw SndE2_SfxN

SndHdrE3:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw SndE3_Sfx1
	dw SndE3_SfxN

SndHdrE4:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndE4_Sfx1
	dw SndE4_SfxN

SndHdrE5:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndE5_Sfx1
	dw SndE4_SfxN

SndHdrE6:
	SND_HEADER $A2, $05 ; tracks: Sfx1, SfxN
	dw SndE6_Sfx1
	dw SndE6_SfxN

SndHdrE7:
	SND_HEADER $91, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndE7_Sfx1
	dw SndE7_Sfx2
	dw SndA1_SfxN

SndHdrE8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE8_Ch1
	dw SndE8_Ch2
	dw SndE8_Ch3
	dw SndE8_Drm

SndHdrE9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE9_Ch1
	dw SndE9_Ch2
	dw SndE9_Ch3
	dw SndE9_Drm

SndHdrEA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEA_Ch1
	dw SndEA_Ch2
	dw SndEA_Ch3
	dw SndEA_Drm

SndHdrEB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEB_Ch1
	dw SndEB_Ch2
	dw SndEB_Ch3
	dw SndEB_Drm

SndHdrEC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEC_Ch1
	dw SndEC_Ch2
	dw SndEC_Ch3
	dw SndEC_Drm

SndHdrED:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndED_Ch1
	dw SndED_Ch2
	dw SndED_Ch3
	dw SndED_Drm

SndHdrEE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEE_Ch1
	dw SndEE_Ch2
	dw SndEE_Ch3
	dw SndEE_Drm

SndHdrEF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEF_Ch1
	dw SndEF_Ch2
	dw SndEF_Ch3
	dw SndEF_Drm

SndHdrF0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF0_Ch1
	dw SndF0_Ch2
	dw SndF0_Ch3
	dw SndF0_Drm

SndHdrF1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF1_Ch1
	dw SndF1_Ch2
	dw SndF1_Ch3
	dw SndF1_Drm

SndHdrF2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF2_Ch1
	dw SndF2_Ch2
	dw SndF2_Ch3
	dw SndF2_Drm

SndHdrF3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF3_Ch1
	dw SndF3_Ch2
	dw SndF3_Ch3
	dw SndF3_Drm

SndHdrF4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF4_Ch1
	dw SndF4_Ch2
	dw SndF4_Ch3
	dw SndF4_Drm

SndHdrF5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF5_Ch1
	dw SndF5_Ch2
	dw SndF5_Ch3
	dw SndF5_Drm

SndHdrF6:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF6_Ch1
	dw SndF6_Ch1
	dw SndF6_Ch1
	dw SndF6_Ch1

SndHdrF7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF7_Ch1
	dw SndF7_Ch2
	dw SndF7_Ch3
	dw SndF7_Drm

SndHdrF8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF8_Ch1
	dw SndF8_Ch2
	dw SndF7_Ch3
	dw SndF7_Drm

SndHdrF9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF9_Ch1
	dw SndF9_Ch2
	dw SndF9_Ch3
	dw SndF9_Drm

SndHdrFA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFA_Ch1
	dw SndFA_Ch1
	dw SndFA_Ch1
	dw SndFA_Ch1

SndHdrFB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFB_Ch1
	dw SndFB_Ch2
	dw SndFB_Ch3
	dw SndFB_Drm

SndHdrFC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFC_Ch1
	dw SndFC_Ch2
	dw SndFC_Ch3
	dw SndFC_Drm

SndHdrFD:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFD_Ch1
	dw SndFD_Ch2
	dw SndFD_Ch3
	dw SndFD_Drm

SndHdrFE:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw SndFE_SfxN
	dw SndFE_Ch1
	dw SndFE_Ch2
	dw SndFE_Ch3
	dw SndA1_SfxN

SndHdrFF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndFF_Ch1
	dw SndFF_Ch2
	dw SndFF_Ch3
	dw SndFF_Drm

SndE9_Ch2:
	TEMPO $10
	SND_SEGNO
	VOICE $05, 8, 3, 8, 7
	RELEASE_VOL 2
	PAN_RIGHT 0
	DUTY_STEP 4, 1
	VIBRATO 18, 1, 5
	DETUNE $01
	RELEASE_VOL 2
	LOOP_START
	SND_CALL SndE9_Ch1_4450
	LOOP_END 4
	DETUNE $00
	LOOP_START
	SND_CALL SndE9_Ch2_4429
	LEN_UNIT $01
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	LEN_UNIT $05
	NOTE G_, 1
	ATTEN 7
	REST 1
	NOTE G_, 1
	ATTEN 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	SND_CALL SndE9_Ch2_4429
	OCTAVE 3
	LEN_UNIT $01
	NOTE D_, 3
	NOTE E_, 2
	LEN_UNIT $05
	NOTE F_, 1
	ATTEN 6
	REST 1
	NOTE F_, 1
	ATTEN 3
	RELEASE 4, 7
	VIBRATO 18, 2, 15
	NOTE F_, 5
	LEN_UNIT $01
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 4
	LOOP_START
	VOICE $05, 8, 7, 6, 1
	DUTY_STEP 4, 1
	VIBRATO_OFF
	RELEASE_VOL 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 6
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 2
	VOICE $05, 0, 8, 4, 3
	DUTY_STEP 0, 0
	RELEASE_VOL 2
	VIBRATO_SEMI $13
	ATTEN 4
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	LOOP_END 4
	SND_LOOP
SndE9_Ch2_4429:
	VOICE $05, 0, 8, 6, 0
	VIBRATO 27, 0, 5
	RELEASE_VOL 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	RELEASE_VOL 0
	ATTEN 4
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	VOICE $01, 4, 8, 15, 7
	ATTEN 3
	VIBRATO_OFF
	NOTE F#, 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	LEN_UNIT $05
	NOTE B_, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	SND_RET
SndE9_Ch1_4450:
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE A_, 4
	NOTE F#, 1
	NOTE A_, 1
	SND_RET

SndE9_Ch1:
	SND_SEGNO
	VOICE $05, 8, 4, 9, 7
	VIBRATO 17, 1, 5
	DETUNE $FE
	DUTY_STEP 4, 1
	RELEASE_VOL 2
	LOOP_START
	SND_CALL SndE9_Ch1_4450
	LOOP_END 4
	LOOP_START
	SND_CALL SndE9_Ch1_44CF
	NOTE G_, 1
	REST 3
	NOTE A_, 2
	NOTE G_, 2
	SND_CALL SndE9_Ch1_44CF
	OCTAVE 3
	LEN_UNIT $01
	NOTE D_, 3
	NOTE E_, 2
	LEN_UNIT $05
	NOTE F_, 1
	REST 2
	VIBRATO 17, 1, 3
	NOTE F_, 4
	LEN_UNIT $05
	LOOP_END 4
	LOOP_START
	SND_CALL SndE9_Ch1_451E
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	SND_CALL SndE9_Ch1_44F4
	NOTE A#, 1
	ATTEN 6
	OCTAVE 3
	NOTE C#, 1
	ATTEN 2
	OCTAVE 2
	NOTE A#, 1
	ATTEN 6
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	ATTEN 1
	NOTE F#, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 5
	NOTE B_, 1
	DETUNE $00
	SND_CALL SndE9_Ch1_451E
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	SND_CALL SndE9_Ch1_44F4
	NOTE G_, 1
	ATTEN 6
	OCTAVE 3
	NOTE C#, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	ATTEN 6
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	ATTEN 1
	NOTE E_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE B_, 1
	LOOP_END 2
	SND_LOOP
SndE9_Ch1_44CF:
	VOICE $05, 0, 7, 5, 0
	VIBRATO_OFF
	RELEASE_VOL 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	RELEASE_VOL 0
	ATTEN 5
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	REST 2
	VOICE $01, 4, 7, 10, 7
	ATTEN 5
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 2
	LEN_UNIT $05
	NOTE B_, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	SND_RET
SndE9_Ch1_44F4:
	ATTEN 1
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C#, 2
	ATTEN 5
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	VOICE $05, 0, 8, 2, 7
	DUTY_STEP 0, 0
	RELEASE_VOL 2
	DETUNE $FD
	AUTOPAN 0
	VIBRATO_SEMI $13
	ATTEN 4
	OCTAVE 2
	NOTE B_, 1
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	ATTEN 3
	NOTE B_, 1
	ATTEN 6
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	OCTAVE 2
	SND_RET
SndE9_Ch1_451E:
	VOICE $05, 8, 6, 5, 4
	DUTY_STEP 4, 1
	VIBRATO_OFF
	RELEASE_VOL 2
	ATTEN 2
	OCTAVE 2
	SND_RET

SndE9_Ch3:
	SND_SEGNO
	VOICE $05, 4, 2, 7, 7
	VIBRATO_OFF
	RELEASE_VOL 4
	LOOP_START
	SND_CALL SndE9_Ch1_4450
	LOOP_END 4
	RELEASE $0A, 7
	LOOP_START
	SND_CALL SndE9_Ch1_4450
	LOOP_END 8
	LOOP2_START
	VOICE $05, 11, 2, 10, 2
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	WAVE 5
	OCTAVE 2
	NOTE C#, 2
	NOTE F#, 2
	LOOP_END 4
	RELEASE 7, 3
	WAVE 7
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE F#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 1
	NOTE E_, 2
	WAVE 5
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP_END 4
	RELEASE 7, 3
	WAVE 4
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP2_END 2
	SND_LOOP

SndE9_Drm:
	LEN_UNIT $05
	SND_SEGNO
	LOOP_START
	SND_CALL SndE9_Drm_45C7
	SND_CALL SndE9_Drm_45D8
	LOOP_END 3
	SND_CALL SndE9_Drm_45C7
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_START
	SND_CALL SndE9_Drm_45C7
	SND_CALL SndE9_Drm_45D8
	LOOP_END 7
	SND_CALL SndE9_Drm_45C7
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP2_START
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP2_END 3
	LOOP_START
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	LOOP_END 3
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_START
	DRUM 5, 1
	LOOP_END 8
	SND_LOOP
SndE9_Drm_45C7:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	SND_RET
SndE9_Drm_45D8:
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_RET

SndEA_Ch2:
	TEMPO $20
	VOICE $06, 8, 7, 10, 1
	DETUNE $01
	DUTY_STEP 8, 1
	SND_SEGNO
	TRANSPOSE_UP $0A
	LOOP2_START
	LOOP_START
	SND_CALL SndEA_Ch2_4619
	LOOP_END 2
	TRANSPOSE_UP 7
	LOOP2_END 2
	TRANSPOSE_UP $0B
	LOOP_START
	SND_CALL SndEA_Ch2_4619
	LOOP_END 2
	TRANSPOSE_UP 8
	SND_CALL SndEA_Ch2_4619
	LOOP_START
	DUTY 0
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	DUTY 8
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 1
	LOOP_END 2
	SND_LOOP
SndEA_Ch2_4619:
	DUTY 0
	OCTAVE 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	DUTY 8
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 1
	DUTY 0
	ATTEN 0
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	DUTY 8
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 1
	SND_RET

SndEA_Ch1:
	SND_SEGNO
	VOICE $06, 8, 6, 10, 1
	DETUNE $FF
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	TRANSPOSE_DOWN 2
	LOOP2_START
	LOOP_START
	SND_CALL SndEA_Ch1_4672
	LOOP_END 2
	TRANSPOSE_DOWN 5
	LOOP2_END 2
	TRANSPOSE_DOWN 1
	LOOP_START
	SND_CALL SndEA_Ch1_4672
	LOOP_END 2
	TRANSPOSE_DOWN 4
	SND_CALL SndEA_Ch1_4672
	LOOP_START
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LOOP_END 2
	SND_LOOP
SndEA_Ch1_4672:
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 2
	ATTEN 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	ATTEN 0
	OCTAVE 2
	DUTY 0
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	SND_RET

SndEA_Ch3:
	VOICE $06, 4, 2, 13, 4
	VIBRATO_SEMI $13
	SND_SEGNO
	TRANSPOSE_UP $0A
	LOOP2_START
	LOOP_START
	SND_CALL SndEA_Ch3_46C1
	LOOP_END 2
	TRANSPOSE_UP 7
	LOOP2_END 2
	TRANSPOSE_UP $0B
	LOOP_START
	SND_CALL SndEA_Ch3_46C1
	LOOP_END 2
	TRANSPOSE_UP 8
	SND_CALL SndEA_Ch3_46C1
	LOOP_START
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 1
	LOOP_END 2
	SND_LOOP
SndEA_Ch3_46C1:
	OCTAVE 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 1
	SND_RET

SndEA_Drm:
	LEN_UNIT $06
	SND_SEGNO
	LOOP_START
	SND_CALL SndEA_Drm_46FC
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM $0A, 1
	LOOP_END 3
	SND_CALL SndEA_Drm_46FC
	LOOP_START
	DRUM 5, 1
	LOOP_END 6
	LOOP_START
	SND_CALL SndEA_Drm_46FC
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM $0A, 1
	LOOP_END 3
	SND_CALL SndEA_Drm_46FC
	LOOP_START
	DRUM 5, 1
	LOOP_END 8
	SND_LOOP
SndEA_Drm_46FC:
	DRUM $0A, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	SND_RET

SndEB_Ch2:
	TEMPO $10
	SND_SEGNO
	LOOP_START
	VOICE $03, 4, 6, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 2
	OCTAVE 2
	NOTE B_, 6
	NOTE B_, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE B_, $0A
	SND_CALL SndEB_Ch2_47E3
	OCTAVE 3
	NOTE C_, 6
	NOTE C_, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE C_, $0A
	SND_CALL SndEB_Ch2_47E3
	OCTAVE 2
	NOTE B_, 6
	NOTE B_, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	OCTAVE 3
	ATTEN 3
	NOTE D_, $0A
	VOICE $03, 0, 5, 15, 7
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	VOICE $03, 4, 6, 15, 7
	DUTY_STEP 8, 1
	VIBRATO 18, 4, 6
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 6
	VOICE $03, 4, 6, 15, 4
	VIBRATO 27, 0, 2
	OCTAVE 3
	NOTE C_, 6
	NOTE C_, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	OCTAVE 3
	ATTEN 3
	NOTE C_, $0A
	SND_CALL SndEB_Ch2_47E3
	LOOP_END 2
	LOOP_START
	VOICE $03, 4, 6, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 2
	OCTAVE 3
	NOTE C#, 6
	VIBRATO_OFF
	NOTE C#, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE C#, $0A
	SND_CALL SndEB_Ch2_47FC
	OCTAVE 3
	NOTE D#, 6
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE D#, $0A
	SND_CALL SndEB_Ch2_47FC
	OCTAVE 3
	NOTE C#, 6
	VIBRATO_OFF
	NOTE C#, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE E_, $0A
	VOICE $03, 0, 5, 15, 7
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	VOICE $03, 4, 6, 15, 7
	OCTAVE 3
	NOTE C#, 2
	VIBRATO 18, 4, 6
	NOTE E_, 6
	VOICE $03, 4, 6, 15, 4
	VIBRATO 27, 0, 2
	NOTE D#, 6
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	ATTEN 3
	NOTE D#, $0A
	SND_CALL SndEB_Ch2_47FC
	LOOP_END 2
	SND_LOOP
SndEB_Ch2_47E3:
	VOICE $03, 0, 6, 15, 7
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	VOICE $03, 4, 6, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 2
	SND_RET
SndEB_Ch2_47FC:
	VOICE $03, 0, 6, 15, 7
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	VOICE $03, 4, 6, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 2
	SND_RET

SndEB_Ch1:
	DETUNE $FF
	SND_SEGNO
	LOOP_START
	VOICE $03, 4, 5, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 3
	DETUNE $FF
	OCTAVE 2
	NOTE G_, 6
	NOTE G_, 2
	ATTEN 4
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	NOTE B_, $0A
	SND_CALL SndEB_Ch1_48D5
	NOTE A_, 6
	NOTE A_, 2
	ATTEN 4
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, $0A
	SND_CALL SndEB_Ch1_48D5
	NOTE G_, 6
	NOTE G_, 2
	ATTEN 4
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	NOTE B_, $0A
	VOICE $03, 8, 1, 2, 0
	DUTY_STEP 4, 0
	VIBRATO 18, 0, 3
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	VOICE $03, 4, 5, 15, 7
	OCTAVE 2
	NOTE G_, 2
	VIBRATO 18, 4, 10
	NOTE B_, 6
	RELEASE $0F, 4
	VIBRATO 27, 0, 3
	NOTE A_, 6
	NOTE A_, 2
	ATTEN 4
	DUTY 0
	VIBRATO 28, 0, 15
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, $0A
	SND_CALL SndEB_Ch1_48D5
	LOOP_END 2
	LOOP_START
	NOTE A_, 6
	NOTE A_, 2
	ATTEN 4
	RELEASE 0, 0
	DUTY 0
	VIBRATO 28, 0, 15
	OCTAVE 3
	NOTE C#, $0A
	SND_CALL SndEB_Ch1_48F0
	NOTE B_, 6
	NOTE B_, 2
	ATTEN 4
	RELEASE 0, 0
	DUTY 0
	VIBRATO 28, 0, 15
	OCTAVE 3
	NOTE D#, $0A
	SND_CALL SndEB_Ch1_48F0
	NOTE A_, 6
	NOTE A_, 2
	ATTEN 4
	RELEASE 0, 0
	DUTY 0
	VIBRATO 28, 0, 15
	OCTAVE 3
	NOTE C#, $0A
	VOICE $03, 8, 1, 2, 0
	DUTY_STEP 4, 0
	VIBRATO 18, 0, 3
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	VOICE $03, 4, 6, 15, 7
	VIBRATO 18, 4, 6
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 6
	RELEASE $0F, 4
	VIBRATO 27, 0, 3
	OCTAVE 2
	NOTE B_, 6
	NOTE B_, 2
	ATTEN 4
	VIBRATO 28, 0, 15
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, $0A
	SND_CALL SndEB_Ch1_48F0
	LOOP_END 2
	SND_LOOP
SndEB_Ch1_48D5:
	VOICE $03, 8, 1, 2, 0
	DUTY_STEP 4, 1
	VIBRATO 18, 0, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	VOICE $03, 4, 5, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 3
	OCTAVE 2
	SND_RET
SndEB_Ch1_48F0:
	VOICE $03, 8, 1, 2, 0
	DUTY_STEP 4, 0
	VIBRATO 18, 0, 6
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	VOICE $03, 4, 5, 15, 4
	DUTY_STEP 8, 1
	VIBRATO 27, 0, 3
	OCTAVE 2
	SND_RET

SndEB_Ch3:
	VOICE $06, 4, 2, 14, 4
	SND_SEGNO
	TRANSPOSE_UP 0
	LOOP2_START
	LOOP_START
	SND_CALL SndEB_Ch3_4938
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	LOOP_END 3
	SND_CALL SndEB_Ch3_4938
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	LOOP_START
	SND_CALL SndEB_Ch3_4938
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	LOOP_END 3
	SND_CALL SndEB_Ch3_4938
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	TRANSPOSE_DOWN 3
	LOOP2_END 2
	SND_LOOP
SndEB_Ch3_4938:
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE D_, 1
	SND_RET

SndEB_Drm:
	LEN_UNIT $03
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 2, 2
	LOOP_END 7
	SND_JUMP_N 2, SndEB_Drm_4971
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	LOOP_START
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 2
SndEB_Drm_4971:
	LOOP2_END 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	SND_LOOP

SndEC_Ch2:
	TRANSPOSE_UP 6
	SND_SEGNO
	LOOP_START
	VOICE $06, 0, 6, 10, 1
	DUTY_STEP 8, 1
	SND_CALL SndEC_Ch2_49FF
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 1
	SND_CALL SndEC_Ch2_49FF
	DUTY 0
	RELEASE 8, 2
	OCTAVE 3
	ATTEN 0
	LEN_UNIT $01
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN_UNIT $06
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	LOOP_END 2
	LOOP2_START
	SND_CALL SndEC_Ch1_4A23
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	DUTY 4
	VIBRATO 20, 0, 15
	SND_CALL SndEC_Ch1_4A56
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE F_, 1
	NOTE F_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE F_, 1
	LOOP_END 2
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE G_, 1
	LOOP_END 2
	VIBRATO_SEMI $13
	RELEASE $0F, 2
	ATTEN 0
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	VIBRATO_OFF
	LOOP2_END 2
	SND_LOOP
SndEC_Ch2_49FF:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_RET
SndEC_Ch1_4A23:
	DUTY 8
	RELEASE $0F, 3
	VIBRATO_SEMI $17
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 3
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	SND_RET
SndEC_Ch1_4A56:
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE E_, 1
	LOOP_END 2
	ATTEN 0
	DUTY_STEP 8, 1
	SND_RET

SndEC_Ch1:
	TRANSPOSE_UP 6
	SND_SEGNO
	LOOP_START
	VOICE $06, 0, 5, 10, 1
	DUTY_STEP 8, 1
	SND_CALL SndEC_Ch1_4AF4
	REST 2
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	SND_CALL SndEC_Ch1_4AF4
	RELEASE $0A, 3
	DUTY 0
	DUTY 0
	RELEASE 8, 2
	OCTAVE 3
	ATTEN 0
	OCTAVE 2
	LEN_UNIT $01
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN_UNIT $06
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	LOOP_END 2
	LOOP2_START
	REST 3
	DETUNE $FE
	SND_CALL SndEC_Ch1_4A23
	DUTY 4
	VIBRATO 20, 0, 15
	DETUNE $00
	RELEASE $0E, 3
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE A#, 1
	LOOP_END 2
	LOOP_START
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE C_, 1
	LOOP_END 2
	SND_CALL SndEC_Ch1_4A56
	VIBRATO_SEMI $13
	RELEASE $0F, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	VIBRATO_OFF
	LOOP2_END 2
	SND_LOOP
SndEC_Ch1_4AF4:
	REST 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE E_, 1
	REST 2
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	NOTE D_, 1
	REST 2
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 3
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	SND_RET

SndEC_Ch3:
	VOICE $06, 2, 2, 10, 3
	VIBRATO_SEMI $13
	SND_SEGNO
	TRANSPOSE_UP 6
	LOOP2_START
	LOOP_START
	SND_CALL SndEC_Ch3_4B31
	LOOP_END 3
	SND_CALL SndEC_Ch3_4B3F
	LOOP2_END 2
	TRANSPOSE_UP 4
	LOOP2_START
	LOOP_START
	SND_CALL SndEC_Ch3_4B31
	LOOP_END 3
	SND_CALL SndEC_Ch3_4B3F
	LOOP2_END 2
	SND_LOOP
SndEC_Ch3_4B31:
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
SndEC_Ch3_4B3F:
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	SND_RET

SndEC_Drm:
	LEN_UNIT $03
	SND_SEGNO
	LOOP_START
	SND_CALL SndEC_Drm_4B85
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	LOOP_END 7
	SND_CALL SndEC_Drm_4B85
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	LOOP_START
	SND_CALL SndEC_Drm_4B8E
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 7
	SND_CALL SndEC_Drm_4B8E
	LOOP_START
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_END 2
	SND_LOOP
SndEC_Drm_4B85:
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	SND_RET
SndEC_Drm_4B8E:
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	SND_RET

SndED_Ch2:
	TEMPO $20
	SND_SEGNO
	TRANSPOSE_UP 7
	DETUNE $15
	VOICE $05, 0, 1, 2, 0
	SND_CALL SndED_Ch2_4C2D
	NOTE D_, 2
	NOTE C#, 2
	SND_CALL SndED_Ch2_4C2D
	DETUNE $00
	TRANSPOSE_DOWN 4
	LOOP_START
	VOICE $05, 0, 6, 14, 4
	DUTY_STEP 0, 0
	VIBRATO 20, 0, 4
	SND_CALL SndED_Ch1_4C08
	VOICE $05, 4, 6, 13, 7
	VIBRATO 18, 1, 6
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 1
	NOTE B_, 2
	ATTEN 1
	OCTAVE 3
	NOTE B_, 4
	ATTEN 0
	NOTE B_, 4
	NOTE B_, 2
	LOOP_END 2
	LOOP_START
	VOICE $05, 4, 6, 15, 5
	VIBRATO_SEMI $17
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 0
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 2
	DUTY 0
	VIBRATO 18, 3, 3
	DUTY_STEP 8, 1
	VOICE $05, 0, 7, 14, 7
	OCTAVE 4
	ATTEN 2
	NOTE D#, 4
	ATTEN 1
	NOTE D#, 4
	ATTEN 0
	LOOP_END 2
	NOTE D#, 4
	SND_LOOP
SndED_Ch1_4C08:
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	SND_RET
SndED_Ch2_4C2D:
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	SND_RET

SndED_Ch1:
	SND_SEGNO
	VOICE $05, 8, 6, 3, 0
	DETUNE $FC
	VIBRATO 18, 0, 3
	TRANSPOSE_DOWN 4
	LOOP2_START
	ATTEN 5
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 4
	NOTE F_, 2
	NOTE F_, 2
	ATTEN 3
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 1
	NOTE A#, 2
	NOTE F_, 2
	ATTEN 2
	NOTE F_, 2
	NOTE A#, 2
	ATTEN 3
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 5
	NOTE B_, 2
	NOTE B_, 2
	LOOP2_END 2
	LOOP_START
	REST 2
	VOICE $05, 0, 2, 14, 6
	VIBRATO 20, 0, 4
	DUTY_STEP 0, 0
	DETUNE $FF
	SND_CALL SndED_Ch1_4C08
	DUTY_STEP 8, 1
	VOICE $05, 4, 6, 15, 7
	VIBRATO 18, 1, 10
	DETUNE $00
	OCTAVE 3
	ATTEN 2
	NOTE F#, 4
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	NOTE F#, 2
	LOOP_END 2
	LOOP_START
	VOICE $05, 4, 6, 15, 4
	VIBRATO_SEMI $17
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	ATTEN 0
	VIBRATO 17, 2, 4
	DUTY 0
	VOICE $05, 0, 7, 15, 5
	VIBRATO 17, 2, 3
	DUTY_STEP 8, 1
	OCTAVE 3
	ATTEN 2
	NOTE A#, 4
	ATTEN 1
	NOTE A#, 4
	ATTEN 0
	LOOP_END 2
	NOTE A#, 4
	SND_LOOP

SndED_Ch3:
	TRANSPOSE_DOWN 4
	SND_SEGNO
	VOICE $05, 5, 2, 10, 2
	VIBRATO_SEMI $11
	LOOP2_START
	OCTAVE 2
	LOOP_START
	NOTE A#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	LOOP_END 2
	NOTE B_, 2
	LOOP2_END 4
	VIBRATO_OFF
	LOOP2_START
	WAVE 1
	RELEASE 0, 0
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE C_HI, 2
	LOOP_END 3
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	LOOP2_END 2
	NOTE D#, 2
	NOTE C_HI, 2
	SND_LOOP

SndED_Drm:
	LEN_UNIT $05
	SND_SEGNO
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	LOOP_END 4
	SND_CALL SndED_Drm_4D3E
	DRUM 1, 1
	DRUM 1, 1
	SND_CALL SndED_Drm_4D3E
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_LOOP
SndED_Drm_4D3E:
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0A, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_RET

SndEE_Ch2:
	TEMPO $18
	TRANSPOSE_UP 2
	VOICE $06, 8, 4, 10, 2
	DETUNE $FE
	RELEASE_VOL 2
	SND_CALL SndEE_Ch1_4DFE
	VOICE $06, 0, 6, 10, 7
	DETUNE $00
	DUTY_STEP 4, 1
	RELEASE_VOL 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 2
	LEN_UNIT $01
	DUTY_STEP 0, 0
	VIBRATO_OFF
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 6, 5, 7
	VIBRATO 29, 0, 5
	SND_CALL SndEE_Ch1_4DDA
	SND_JUMP_N 2, SndEE_Ch2_4DBF
	NOTE D#, $0B
	VOICE $06, 4, 6, 15, 7
	VIBRATO 20, 0, 10
	OCTAVE 2
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	LEN_UNIT $02
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 1
	LEN_UNIT $06
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
SndEE_Ch2_4DBF:
	LOOP_END 2
	NOTE D#, $0A
	RELEASE $0F, 7
	VIBRATO 20, 0, 10
	DUTY 0
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 4
	NOTE D#, 3
	NOTE F_, 2
	NOTE G_, 3
	SND_CALL SndEE_Ch2_4E1D
	TRANSPOSE_UP 6
	SND_CALL SndEE_Ch2_4E1D
	TRANSPOSE_UP 2
	SND_LOOP
SndEE_Ch1_4DDA:
	OCTAVE 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 0
	NOTE D_, 4
	NOTE C_, 3
	NOTE D#, 3
	NOTE G_, 2
	NOTE A#, 4
	NOTE A#, 3
	LEN_UNIT $13
	NOTE A_, 6
	LEN_UNIT $06
	NOTE D#, 3
	NOTE G_, 3
	OCTAVE 3
	NOTE D_, 4
	NOTE D#, 3
	LEN_UNIT $13
	NOTE C_, 6
	LEN_UNIT $06
	OCTAVE 2
	NOTE G_, 3
	NOTE A#, 3
	OCTAVE 3
	NOTE F_, 4
	NOTE F_, 3
	SND_RET
SndEE_Ch1_4DFE:
	LOOP2_START
	OCTAVE 1
	NOTE A#, 1
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	LOOP_END 7
	LOOP2_END 3
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	LOOP2_START
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	LOOP_START
	NOTE C_, 1
	LOOP_END 7
	LOOP2_END 2
	SND_RET
SndEE_Ch2_4E1D:
	VOICE $03, 8, 5, 5, 7
	VIBRATO 18, 4, 3
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	LEN_UNIT $06
	NOTE D#, $0A
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE G#, 9
	OCTAVE 2
	LEN_UNIT $03
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	LEN_UNIT $06
	NOTE D#, $0A
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE G_, 9
	SND_RET

SndEE_Ch1:
	VOICE $06, 0, 3, 10, 4
	DETUNE $FE
	VIBRATO 17, 10, 5
	RELEASE_VOL 2
	TRANSPOSE_UP 9
	SND_CALL SndEE_Ch1_4DFE
	VOICE $06, 0, 5, 12, 7
	TRANSPOSE_UP 2
	DUTY_STEP 4, 1
	RELEASE_VOL 0
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G#, 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 2
	LEN_UNIT $01
	ATTEN 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 5, 0, 0
	VIBRATO 17, 2, 0
	DUTY_STEP 0, 0
	ATTEN 3
	REST 3
	SND_CALL SndEE_Ch1_4DDA
	SND_JUMP_N 2, SndEE_Ch1_4EB0
	NOTE D#, 8
	VOICE $06, 4, 5, 10, 7
	VIBRATO 20, 0, 10
	OCTAVE 2
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 2
	LEN_UNIT $02
	VIBRATO_OFF
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE G_, 3
	NOTE A#, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE D#, 3
	NOTE F_, 3
	OCTAVE 2
	NOTE A#, 3
SndEE_Ch1_4EB0:
	LOOP_END 2
	NOTE D#, 7
	RELEASE $0F, 7
	DUTY 0
	VIBRATO 20, 0, 10
	ATTEN 0
	OCTAVE 2
	NOTE G_, 3
	NOTE A_, 4
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 3
	VOICE $06, 0, 7, 10, 4
	RELEASE_VOL 2
	DUTY_STEP 4, 1
	SND_CALL SndEE_Ch1_4ED5
	TRANSPOSE_UP 6
	SND_CALL SndEE_Ch1_4ED5
	TRANSPOSE_UP 2
	SND_LOOP
SndEE_Ch1_4ED5:
	LOOP2_START
	VIBRATO 20, 0, 10
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	LOOP_END 2
	OCTAVE 2
	NOTE E_, 1
	ATTEN 2
	NOTE G#, 1
	OCTAVE 3
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 2
	NOTE G#, 1
	LOOP2_END 2
	LOOP2_START
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	LOOP_END 2
	OCTAVE 2
	NOTE E_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	LOOP2_END 2
	SND_RET

SndEE_Ch3:
	TRANSPOSE_UP 2
	VOICE $06, 4, 2, 8, 7
	RELEASE_VOL 4
	VIBRATO_SEMI $13
	SND_CALL SndEE_Ch3_4FD8
	SND_CALL SndEE_Ch3_5007
	SND_CALL SndEE_Ch3_5016
	RELEASE_VOL 0
	NOTE D_, 1
	NOTE C_HI, 1
	RELEASE_VOL 4
	NOTE D#, 1
	RELEASE_VOL 0
	NOTE D#, 1
	NOTE C_HI, 1
	RELEASE_VOL 4
	NOTE D#, 1
	RELEASE_VOL 0
	NOTE D#, 1
	RELEASE_VOL 4
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_SEGNO
	LOOP2_START
	SND_CALL SndEE_Ch3_4FD8
	SND_CALL SndEE_Ch3_5007
	SND_CALL SndEE_Ch3_4FD8
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE_VOL 4
	NOTE D_, 1
	SND_CALL SndEE_Ch3_4FD8
	SND_CALL SndEE_Ch3_5007
	SND_JUMP_N 2, SndEE_Ch3_4F70
	SND_CALL SndEE_Ch3_4FD8
	RELEASE_VOL 0
	NOTE C_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F_, 1
	RELEASE_VOL 4
	OCTAVE 1
	NOTE A#, 1
SndEE_Ch3_4F70:
	LOOP2_END 2
	SND_CALL SndEE_Ch3_5016
	RELEASE_VOL 0
	NOTE C_HI, 1
	RELEASE_VOL 4
	NOTE D_, 1
	RELEASE_VOL 0
	NOTE D_, 1
	RELEASE_VOL 4
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	RELEASE_VOL 0
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	RELEASE_VOL 4
	NOTE C_HI, 1
	RELEASE_VOL 4
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE G#, 1
	LOOP_END 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	LOOP2_END 2
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE G_, 1
	LOOP_END 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	LOOP2_END 2
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	LOOP2_END 2
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE B_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	LOOP2_END 2
	SND_LOOP
SndEE_Ch3_4FD8:
	LOOP_START
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 1
	RELEASE_VOL 4
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 3
	SND_RET

; Orphan subroutine (no SND_CALL reaches it; decoded as Ch1).
B15_Data_4FEA:
	OCTAVE 1
	RELEASE_VOL 0
	NOTE A#, 1
	RELEASE_VOL 4
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	LOOP2_START
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 1
	RELEASE_VOL 4
	OCTAVE 2
	LOOP_START
	NOTE C_, 1
	LOOP_END 7
	LOOP2_END 2
	SND_RET
SndEE_Ch3_5007:
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE_VOL 4
	NOTE F_, 1
	SND_RET
SndEE_Ch3_5016:
	LOOP2_START
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 1
	RELEASE_VOL 4
	OCTAVE 2
	LOOP_START
	NOTE C_, 1
	LOOP_END 7
	LOOP2_END 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_RET

SndEE_Drm:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM $0A, 2
	DRUM $0A, 1
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM 5, 2
	DRUM 2, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM 5, 2
	DRUM $0A, 1
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_SEGNO
	SND_CALL SndEE_Drm_5074
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 1
	DRUM 5, 2
	DRUM 2, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 5, 1
	LOOP_END 7
	SND_CALL SndEE_Drm_5074
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	LOOP_START
	DRUM 5, 1
	LOOP_END 13
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 15
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_LOOP
SndEE_Drm_5074:
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM $0A, 2
	DRUM $0A, 1
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 6
	DRUM $0A, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM $0A, 2
	DRUM $0A, 1
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 1
	DRUM 5, 1
	SND_RET

SndEF_Ch2:
	TRANSPOSE_UP 2
	TEMPO $10
	VOICE $03, 4, 6, 13, 2
	VIBRATO_SEMI $13
	DETUNE $01
	LOOP_START
	SND_CALL SndEF_Ch1_5150
	LOOP_END 3
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	DETUNE $00
	SND_SEGNO
	LOOP2_START
	VOICE $03, 0, 7, 0, 0
	VIBRATO_OFF
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_START
	RELEASE 7, 2
	ATTEN 0
	OCTAVE 3
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 1
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	OCTAVE 2
	NOTE A#, 2
	ATTEN 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A#, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 1
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 1
	LOOP_END 2
	SND_CALL SndEF_Ch2_5163
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	OCTAVE 2
	NOTE A#, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 1
	SND_CALL SndEF_Ch2_5163
	LOOP2_END 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	OCTAVE 2
	NOTE A#, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 4
	OCTAVE 3
	NOTE C_, 2
	CLEAR 5
	OCTAVE 3
	VIBRATO_SEMI $13
	DUTY 4
	SND_CALL SndEF_Ch1_517B
	VIBRATO_SEMI 3
	RELEASE 5, 1
	DUTY 0
	DUTY_STEP 4, 1
	OCTAVE 3
	ATTEN 1
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 1
	NOTE C_, 2
	ATTEN 5
	NOTE D#, 2
	ATTEN 1
	NOTE D_, 2
	NOTE D#, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 1
	DUTY 8
	RELEASE $0F, 5
	VIBRATO 20, 0, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, 2
	OCTAVE 3
	VIBRATO_SEMI $13
	DUTY 4
	SND_CALL SndEF_Ch1_517B
	DUTY 8
	VIBRATO 20, 0, 2
	RELEASE $0F, 5
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE A#, 4
	NOTE G#, 6
	NOTE G_, 4
	SND_LOOP
SndEF_Ch1_5150:
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 2
	SND_RET
SndEF_Ch2_5163:
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 1
	NOTE D#, 2
	NOTE F_, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 1
	NOTE D_, 2
	NOTE D#, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 1
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 1
	OCTAVE 2
	NOTE A#, 2
	SND_RET
SndEF_Ch1_517B:
	DUTY_STEP 8, 1
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	NOTE D_, 4
	ATTEN 3
	NOTE D#, 4
	NOTE C_, 4
	NOTE D_, 2
	NOTE D#, 4
	NOTE C_, 4
	ATTEN 2
	NOTE D_, 4
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 3
	SND_RET

SndEF_Ch1:
	TRANSPOSE_UP 2
	VOICE $03, 4, 5, 13, 2
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 2
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	LOOP_END 4
	SND_SEGNO
	TRANSPOSE_DOWN $0A
	DETUNE $FD
	VIBRATO_SEMI $12
	VOICE $03, 0, 5, 13, 4
	DUTY_STEP 4, 1
	LOOP2_START
	LOOP_START
	SND_CALL SndEF_Ch1_5150
	LOOP_END 2
	SND_CALL SndEF_Ch1_5284
	LOOP2_END 2
	TRANSPOSE_UP 2
	VOICE $03, 0, 5, 15, 5
	VIBRATO_SEMI $18
	SND_CALL SndEF_Ch1_517B
	VIBRATO_SEMI 3
	DETUNE $00
	DUTY 0
	RELEASE 5, 1
	OCTAVE 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 3
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 3
	OCTAVE 2
	NOTE A#, 2
	ATTEN 0
	DETUNE $FD
	DUTY 8
	RELEASE $0F, 5
	ATTEN 3
	VIBRATO 20, 0, 2
	OCTAVE 3
	ATTEN 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 2
	VIBRATO_SEMI $18
	ATTEN 1
	DUTY 0
	VIBRATO_SEMI $18
	SND_CALL SndEF_Ch1_517B
	DUTY 8
	VIBRATO 20, 0, 2
	RELEASE $0F, 5
	ATTEN 2
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE A#, 4
	NOTE G#, 6
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 2
	NOTE G_, 6
	SND_LOOP

SndEF_Ch3:
	TRANSPOSE_UP 2
	VOICE $03, 4, 2, 8, 4
	VIBRATO_SEMI $13
	RELEASE_VOL 6
	LOOP_START
	SND_CALL SndEF_Ch1_5150
	LOOP_END 4
	SND_SEGNO
	LOOP2_START
	LOOP_START
	SND_CALL SndEF_Ch1_5150
	LOOP_END 2
	SND_CALL SndEF_Ch1_5284
	LOOP2_END 2
	RELEASE_VOL 4
	SND_CALL SndEF_Ch3_5261
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	SND_CALL SndEF_Ch3_5261
	NOTE C#, 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_HI, 2
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE C#, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	SND_LOOP
SndEF_Ch3_5261:
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE G#, 2
	NOTE C_HI, 2
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 2
	NOTE C_HI, 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE F#, 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE F#, 4
	NOTE F#, 2
	SND_RET
SndEF_Ch1_5284:
	LOOP_START
	OCTAVE 2
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	LOOP_END 2
	SND_RET

SndEF_Drm:
	LEN_UNIT $03
	LOOP_START
	SND_CALL SndEF_Drm_52E7
	LOOP_END 3
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	SND_SEGNO
	LOOP_START
	SND_CALL SndEF_Drm_52E7
	LOOP_END 7
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	LOOP_END 7
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 2
	SND_LOOP
SndEF_Drm_52E7:
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	SND_RET

SndF0_Ch2:
	SND_SEGNO
	TRANSPOSE_DOWN 4
	LOOP2_START
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5397
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5401
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5397
	SND_CALL SndF0_Ch1_5418
	SND_CALL SndF0_Ch2_53B0
	NOTE A#, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE A#, $0A
	SND_CALL SndF0_Ch2_53B0
	NOTE A#, $0F
	ATTEN 2
	NOTE A#, 5
	ATTEN 3
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
	LOOP2_END 2
	TRANSPOSE_DOWN 2
	LOOP2_START
	SND_CALL SndF0_Ch2_53C3
	NOTE C#, 8
	VOICE $05, 4, 6, 15, 5
	VIBRATO_SEMI $13
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 4
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	SND_CALL SndF0_Ch2_53C3
	NOTE C#, 6
	VOICE $05, 4, 7, 10, 7
	VIBRATO 20, 0, 4
	OCTAVE 3
	NOTE C#, 2
	ATTEN 3
	NOTE D#, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	ATTEN 1
	NOTE A#, 2
	NOTE F#, 2
	LOOP2_END 2
	SND_LOOP
SndF0_Ch1_5369:
	VOICE $01, 0, 7, 8, 7
	VIBRATO 27, 0, 7
	VIBRATO_SEMI $13
	ATTEN 4
	OCTAVE 2
	NOTE C#, 5
	REST 5
	LOOP_START
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F#, $0A
	ATTEN 4
	NOTE F#, 8
	REST 2
	LOOP_END 2
	DUTY_STEP 4, 1
	ATTEN 3
	NOTE F#, 5
	NOTE F#, 5
	ATTEN 0
	NOTE F#, 9
	REST 1
	NOTE F#, 5
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE F#, $0F
	DUTY_STEP 4, 1
	ATTEN 0
	SND_RET
SndF0_Ch1_5397:
	ATTEN 0
	NOTE F#, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE F#, $0A
	VIBRATO 18, 2, 3
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE E_, $0F
	DUTY_STEP 0, 0
	ATTEN 2
	NOTE E_, $0A
	LEN_UNIT $01
	NOTE D#, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET
SndF0_Ch2_53B0:
	VIBRATO_OFF
	VOICE $01, 4, 6, 8, 7
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE B_, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE B_, $0A
	DUTY_STEP 8, 1
	ATTEN 0
	SND_RET
SndF0_Ch2_53C3:
	VOICE $05, 0, 7, 13, 5
	VIBRATO 27, 0, 10
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 3
	ATTEN 2
	CLEAR $0C
	LEN_UNIT $01
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $05, 0, 7, 4, 1
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE F#, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 4
	NOTE E_, 2
	NOTE F#, 2
	ATTEN 3
	NOTE B_, 2
	NOTE E_, 2
	ATTEN 2
	NOTE F#, 2
	NOTE B_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE F#, 2
	NOTE B_, 2
	DUTY_STEP 0, 0
	DUTY 4
	OCTAVE 3
	NOTE D#, 4
	RELEASE $0F, 7
	NOTE C#, 4
	ATTEN 3
	VIBRATO 17, 4, 10
	RELEASE $0A, 7
	SND_RET
SndF0_Ch1_5401:
	NOTE A_, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE A_, $0A
	VIBRATO 18, 2, 3
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE A_, $0F
	ATTEN 3
	DUTY_STEP 0, 0
	NOTE A_, $0A
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
SndF0_Ch1_5418:
	VIBRATO 27, 0, 10
	OCTAVE 2
	NOTE C#, 5
	REST 5
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE F#, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F#, $0A
	ATTEN 4
	NOTE F#, 8
	REST 2
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE F#, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F#, $0A
	DUTY_STEP 4, 1
	ATTEN 3
	OCTAVE 2
	NOTE C#, 5
	NOTE C#, 5
	SND_RET

SndF0_Ch1:
	SND_SEGNO
	VIBRATO_SEMI $13
	LOOP2_START
	TRANSPOSE_DOWN 9
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5397
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5401
	SND_CALL SndF0_Ch1_5369
	SND_CALL SndF0_Ch1_5397
	SND_CALL SndF0_Ch1_5418
	TRANSPOSE_DOWN 4
	SND_CALL SndF0_Ch1_54AC
	NOTE E_, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE E_, $0A
	SND_CALL SndF0_Ch1_54AC
	VIBRATO 17, 6, 4
	LEN_UNIT $05
	NOTE E_, 5
	LEN_UNIT $01
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP2_END 2
	LOOP2_START
	TRANSPOSE_DOWN 2
	SND_CALL SndF0_Ch1_54BD
	NOTE G#, 8
	VOICE $05, 4, 6, 15, 5
	VIBRATO_SEMI $13
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE F#, 2
	SND_CALL SndF0_Ch1_54BD
	NOTE G#, 6
	VOICE $05, 4, 3, 10, 7
	VIBRATO 20, 0, 4
	DETUNE $FF
	OCTAVE 3
	NOTE C#, 5
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 1
	LOOP2_END 2
	SND_LOOP
SndF0_Ch1_54AC:
	DUTY 4
	CLEAR 9
	OCTAVE 3
	DUTY_STEP 4, 1
	NOTE E_, 8
	REST 2
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE E_, $0A
	DUTY_STEP 8, 1
	ATTEN 0
	SND_RET
SndF0_Ch1_54BD:
	VOICE $05, 0, 6, 13, 5
	VIBRATO 19, 0, 5
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 3
	ATTEN 2
	CLEAR $0C
	LEN_UNIT $01
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	VOICE $05, 0, 1, 10, 6
	VIBRATO 17, 1, 0
	LOOP_START
	OCTAVE 6
	NOTE C#, 2
	NOTE F#, 2
	OCTAVE 5
	NOTE B_, 2
	LOOP_END 3
	OCTAVE 6
	NOTE C#, 2
	NOTE F#, 2
	VOICE $05, 8, 6, 15, 7
	OCTAVE 2
	NOTE B_, 4
	NOTE G#, 4
	ATTEN 3
	VIBRATO 17, 4, 15
	RELEASE 8, 7
	SND_RET

SndF0_Ch3:
	SND_SEGNO
	VOICE $05, 4, 2, 9, 7
	VIBRATO 27, 0, 15
	RELEASE_VOL 4
	TRANSPOSE_DOWN 4
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_HI, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE F#, 4
	NOTE G#, 4
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	LOOP_END 8
	TRANSPOSE_DOWN 2
	WAVE 2
	LOOP2_END 2
	SND_LOOP

SndF0_Drm:
	LEN_UNIT $05
	SND_SEGNO
	SND_CALL SndF0_Drm_5542
	SND_CALL SndF0_Drm_5555
	DRUM $0A, 2
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM 5, 1
	DRUM 2, 1
	DRUM $0A, 2
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	SND_CALL SndF0_Drm_5542
	SND_CALL SndF0_Drm_5555
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_START
	DRUM 5, 1
	LOOP_END 6
	SND_LOOP
SndF0_Drm_5542:
	LOOP2_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM $0A, 1
	DRUM 2, 1
	LOOP_START
	DRUM 2, 2
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM $0A, 1
	DRUM 2, 1
	LOOP_END 3
	LOOP2_END 3
	SND_RET
SndF0_Drm_5555:
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM $0A, 1
	DRUM 2, 1
	SND_RET

SndF1_Ch2:
	TEMPO $30
	SND_SEGNO
	LOOP2_START
	LOOP_START
	VOICE $03, 4, 6, 10, 2
	DUTY_STEP 8, 1
	VIBRATO_OFF
	OCTAVE 3
	NOTE E_, 4
	RELEASE $0A, 4
	ATTEN 3
	NOTE E_, 4
	ATTEN 2
	NOTE E_, 2
	RELEASE $0A, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 4
	DUTY 0
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	DUTY 4
	ATTEN 0
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 4
	ATTEN 2
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 4
	DUTY 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 3
	NOTE D#, 2
	DUTY 4
	ATTEN 3
	NOTE G_, 4
	ATTEN 2
	NOTE G_, 4
	ATTEN 1
	NOTE A#, 4
	ATTEN 0
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	LOOP2_END 4
	LOOP2_START
	SND_CALL SndF1_Ch2_55D0
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	TRANSPOSE_UP 2
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP2_START
	SND_CALL SndF1_Ch2_55D0
	SND_JUMP_N 2, SndF1_Ch2_55C7
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	TRANSPOSE_UP 2
SndF1_Ch2_55C7:
	LOOP2_END 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	TRANSPOSE_UP 0
	SND_LOOP
SndF1_Ch2_55D0:
	VOICE $03, 0, 6, 15, 4
	DUTY_STEP 0, 0
	VIBRATO 20, 0, 8
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 2
	NOTE F#, 2
	DUTY 0
	VIBRATO_SEMI $14
	ATTEN 4
	LOOP_START
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	ATTEN 3
	LOOP_END 2
	ATTEN 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	ATTEN 0
	SND_RET

SndF1_Ch1:
	SND_SEGNO
	LOOP2_START
	LOOP_START
	VOICE $03, 0, 6, 9, 3
	DUTY_STEP 8, 1
	DETUNE $FF
	VIBRATO_SEMI $13
	RELEASE_VOL 2
	OCTAVE 3
	NOTE C_, 4
	ATTEN 3
	NOTE C_, 4
	ATTEN 2
	NOTE C_, 2
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 4
	VIBRATO 17, 0, 1
	ATTEN 5
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	LOOP_END 2
	VIBRATO_SEMI $13
	ATTEN 0
	OCTAVE 3
	NOTE D#, 4
	ATTEN 3
	NOTE D#, 4
	ATTEN 2
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE D#, 4
	VIBRATO 17, 0, 1
	ATTEN 5
	OCTAVE 4
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	VIBRATO_SEMI $13
	DUTY 4
	ATTEN 3
	OCTAVE 3
	NOTE D#, 4
	ATTEN 2
	NOTE D#, 4
	ATTEN 1
	NOTE G_, 4
	ATTEN 0
	NOTE F_, 4
	NOTE D#, 4
	NOTE D_, 4
	LOOP2_END 4
	LOOP2_START
	SND_CALL SndF1_Ch1_5663
	NOTE A_, 2
	NOTE F_, 2
	ATTEN 0
	TRANSPOSE_UP 2
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP2_START
	SND_CALL SndF1_Ch1_5663
	SND_JUMP_N 2, SndF1_Ch1_565A
	NOTE A_, 2
	NOTE F_, 2
	ATTEN 0
	TRANSPOSE_UP 2
SndF1_Ch1_565A:
	LOOP2_END 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	ATTEN 0
	TRANSPOSE_UP 0
	SND_LOOP
SndF1_Ch1_5663:
	VOICE $03, 0, 6, 15, 3
	DUTY_STEP 0, 0
	VIBRATO 20, 0, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	RELEASE $0F, 7
	VIBRATO_SEMI $14
	REST 2
	ATTEN 4
	LOOP_START
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	ATTEN 3
	LOOP_END 3
	SND_RET

SndF1_Ch3:
	SND_SEGNO
	VOICE $03, 4, 2, 14, 4
	VIBRATO_SEMI $11
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	LOOP_END 8
	LOOP_START
	OCTAVE 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 4
	OCTAVE 1
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE G#, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	LOOP2_END 4
	VIBRATO_SEMI $13
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE C_HI, 2
	LOOP_END 6
	LOOP_START
	NOTE D#, 2
	NOTE C_HI, 2
	LOOP_END 6
	LOOP_START
	NOTE F#, 2
	NOTE C_HI, 2
	LOOP_END 6
	LOOP_START
	NOTE F_, 2
	NOTE C_HI, 2
	LOOP_END 6
	LOOP2_END 2
	SND_LOOP

SndF1_Drm:
	LEN_UNIT $03
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	LOOP_END 15
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP2_END 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_END 7
	LOOP_START
	DRUM 5, 2
	LOOP_END 12
	SND_LOOP

SndF2_Ch2:
	TEMPO $20
	TRANSPOSE_DOWN $0A
	SND_SEGNO
	VOICE $06, 4, 6, 15, 3
	DUTY_STEP 8, 1
	VIBRATO 18, 6, 15
	DETUNE $01
	ATTEN 2
	LOOP_START
	SND_CALL SndF2_Ch1_574C
	ATTEN 3
	LOOP_END 2
	LOOP2_START
	ATTEN 4
	SND_CALL SndF2_Ch1_5762
	SND_CALL SndF2_Ch2_578C
	NOTE C#, 1
	REST 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 5
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 1
	SND_CALL SndF2_Ch1_5778
	SND_CALL SndF2_Ch1_5762
	SND_CALL SndF2_Ch2_578C
	NOTE F_, 1
	REST 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	SND_CALL SndF2_Ch1_5778
	LOOP2_END 2
	DUTY 0
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	ATTEN 0
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	LOOP_END 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	LOOP_END 4
	OCTAVE 4
	NOTE D#, 2
	NOTE F_, 2
	LOOP2_END 4
	SND_LOOP
SndF2_Ch1_574C:
	RELEASE $0E, 4
	DUTY 0
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	CLEAR 3
	SND_RET
SndF2_Ch1_5762:
	RELEASE $0E, 4
	DUTY 0
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 1
	CLEAR 3
	RELEASE 7, 7
	DUTY 4
	SND_RET
SndF2_Ch1_5778:
	RELEASE $0E, 4
	DUTY 0
	ATTEN 4
	OCTAVE 2
	NOTE D#, 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	DETUNE $00
	SND_RET
SndF2_Ch2_578C:
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE D_, 3
	ATTEN 5
	RELEASE 8, $0D
	NOTE D_, $0C
	RELEASE 7, 7
	ATTEN 0
	DUTY_STEP 8, 1
	SND_RET

SndF2_Ch1:
	TRANSPOSE_DOWN $0A
	SND_SEGNO
	VOICE $06, 4, 6, 8, 6
	DUTY_STEP 8, 1
	DETUNE $FF
	VIBRATO 17, 6, 9
	ATTEN 2
	LOOP_START
	SND_CALL SndF2_Ch1_574C
	ATTEN 3
	LOOP_END 2
	LOOP2_START
	ATTEN 4
	SND_CALL SndF2_Ch1_5762
	SND_CALL SndF2_Ch1_57F6
	NOTE G#, 1
	REST 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	SND_CALL SndF2_Ch1_5778
	SND_CALL SndF2_Ch1_5762
	SND_CALL SndF2_Ch1_57F6
	OCTAVE 4
	NOTE C_, 1
	REST 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	SND_CALL SndF2_Ch1_5778
	LOOP2_END 2
	DUTY 0
	DUTY_STEP 4, 1
	VIBRATO_SEMI $12
	RELEASE $0F, 7
	DETUNE $FE
	ATTEN 3
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	LOOP2_START
	SND_CALL SndF2_Ch1_5807
	NOTE F_, 2
	LOOP2_END 3
	SND_CALL SndF2_Ch1_5807
	SND_LOOP
SndF2_Ch1_57F6:
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	DUTY_STEP 0, 0
	ATTEN 2
	NOTE A_, 3
	ATTEN 5
	RELEASE 8, $0D
	NOTE A_, $0C
	RELEASE 7, 7
	ATTEN 0
	DUTY_STEP 8, 1
	SND_RET
SndF2_Ch1_5807:
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	LOOP_END 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	LOOP_END 4
	OCTAVE 4
	NOTE D#, 2
	SND_RET

SndF2_Ch3:
	TRANSPOSE_UP 2
	VOICE $06, 4, 2, 14, 4
	VIBRATO_SEMI $11
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	SND_LOOP

SndF2_Drm:
	LEN_UNIT $03
	SND_SEGNO
	LOOP_START
	SND_CALL SndF2_Drm_5858
	LOOP_END 27
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	SND_CALL SndF2_Drm_5858
	LOOP_END 15
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	SND_LOOP
SndF2_Drm_5858:
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	SND_RET

SndF3_Ch2:
	TRANSPOSE_UP 2
	TEMPO $10
	SND_CALL SndF3_Ch1_58E1
	NOTE A_, 1
	SND_CALL SndF3_Ch1_58E1
	SND_SEGNO
	SND_CALL SndF3_Ch2_58F7
	NOTE A_, 3
	RELEASE 2, 3
	ATTEN 4
	NOTE A_, 4
	SND_CALL SndF3_Ch2_593E
	ATTEN 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE A_, 1
	SND_CALL SndF3_Ch2_58F7
	OCTAVE 3
	NOTE D_, 3
	RELEASE 2, 3
	ATTEN 4
	NOTE D_, 4
	SND_CALL SndF3_Ch2_593E
	ATTEN 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	LOOP_START
	DETUNE $00
	SND_CALL SndF3_Ch2_5953
	NOTE F#, 9
	VIBRATO 25, 0, 6
	RELEASE 0, 0
	NOTE F#, 3
	VOICE $03, 0, 6, 14, 7
	NOTE F#, 1
	NOTE G_, 1
	LEN_UNIT $06
	VIBRATO_SEMI $13
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE G#, 1
	LOOP_END 3
	SND_CALL SndF3_Ch2_5953
	NOTE F#, 9
	VOICE $06, 0, 6, 14, 4
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	SND_LOOP
SndF3_Ch1_58E1:
	VOICE $06, 4, 4, 15, 7
	DETUNE $03
	DUTY_STEP 8, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE A_, 1
	NOTE C_, 1
	SND_RET
SndF3_Ch2_58F7:
	VOICE $06, 4, 6, 13, 1
	VIBRATO 25, 2, 6
	CLEAR 6
	RELEASE $0F, 6
	LOOP_START
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 4
	RELEASE 8, 7
	ATTEN 4
	LOOP_END 2
	RELEASE $0F, 6
	ATTEN 0
	LOOP_START
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 4
	RELEASE 8, 7
	ATTEN 4
	LOOP_END 2
	RELEASE $0F, 6
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 4
	RELEASE 8, 7
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	VOICE $03, 4, 6, 15, 6
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT $06
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 1
	SND_RET
SndF3_Ch2_593E:
	VOICE $02, 0, 6, 8, 7
	DUTY_STEP 8, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	LEN_UNIT $06
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	NOTE A_, 1
	SND_RET
SndF3_Ch2_5953:
	VOICE $06, 0, 7, 14, 4
	VIBRATO 20, 0, 15
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE $0F, 5
	VIBRATO 25, 6, 3
	OCTAVE 3
	NOTE F#, 3
	RELEASE 8, $0D
	DUTY_STEP 0, 0
	ATTEN 5
	SND_RET

SndF3_Ch1:
	TRANSPOSE_UP 2
	VOICE $06, 4, 3, 15, 4
	DETUNE $FF
	SND_CALL SndF3_Ch1_58E1
	NOTE A_, 1
	SND_CALL SndF3_Ch1_58E1
	SND_SEGNO
	VOICE $06, 0, 5, 0, 0
	DETUNE $FE
	VIBRATO 18, 2, 5
	DUTY_STEP 0, 0
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	SND_CALL SndF3_Ch1_59F6
	NOTE A_, 7
	SND_CALL SndF3_Ch1_5A25
	NOTE F_, 1
	NOTE A_, 1
	SND_CALL SndF3_Ch1_59F6
	OCTAVE 3
	NOTE D_, 7
	SND_CALL SndF3_Ch1_5A25
	NOTE E_, 1
	NOTE F_, 1
	LOOP2_START
	CLEAR 3
	SND_CALL SndF3_Ch1_5A12
	RELEASE $0A, $0D
	ATTEN 4
	NOTE D_, 9
	VIBRATO 18, 0, 6
	RELEASE 0, 0
	NOTE D_, 3
	VOICE $03, 0, 5, 14, 3
	VIBRATO 20, 0, 9
	NOTE C#, 1
	NOTE D_, 1
	LEN_UNIT $06
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	LOOP_START
	ATTEN 0
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	LOOP_END 2
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	LOOP2_END 3
	SND_CALL SndF3_Ch1_5A12
	RELEASE 8, $0D
	ATTEN 4
	NOTE D_, 9
	VOICE $06, 4, 5, 14, 4
	VIBRATO_SEMI $13
	DETUNE $FE
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	SND_LOOP
SndF3_Ch1_59F6:
	DUTY 4
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, $0C
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, $0C
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 9
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 1
	SND_RET
SndF3_Ch1_5A12:
	VOICE $06, 0, 5, 14, 4
	DUTY_STEP 4, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0F, 5
	VIBRATO 18, 3, 4
	OCTAVE 3
	NOTE D_, 3
	SND_RET
SndF3_Ch1_5A25:
	DUTY_STEP 4, 1
	LEN_UNIT $02
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	LEN_UNIT $06
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_RET

SndF3_Ch3:
	TRANSPOSE_UP 2
	VOICE $06, 4, 2, 10, 2
	VIBRATO_SEMI $11
	LOOP_START
	SND_CALL SndF3_Ch3_5A58
	LOOP_END 2
	SND_SEGNO
	TRANSPOSE_UP 2
	LOOP_START
	SND_CALL SndF3_Ch3_5A58
	LOOP_END 8
	TRANSPOSE_DOWN 1
	LOOP_START
	SND_CALL SndF3_Ch3_5A58
	LOOP_END 8
	SND_LOOP
SndF3_Ch3_5A58:
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_RET

SndF3_Drm:
	LEN_UNIT $06
	SND_CALL SndF3_Drm_5AA7
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	SND_SEGNO
	LOOP_START
	SND_CALL SndF3_Drm_5AA7
	LOOP_END 7
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM $0A, 1
	LOOP_START
	SND_CALL SndF3_Drm_5AA7
	LOOP_END 7
	LEN_UNIT $03
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $06
	LOOP_START
	DRUM 5, 1
	LOOP_END 15
	SND_LOOP
SndF3_Drm_5AA7:
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	SND_RET

SndF4_Ch2:
	SND_SEGNO
	VOICE $04, 0, 7, 15, 5
	TRANSPOSE_DOWN 3
	DUTY_STEP 4, 1
	VIBRATO 20, 0, 7
	ATTEN 3
	OCTAVE 3
	NOTE D#, 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 1
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 4
	NOTE D#, 2
	NOTE G_, 4
	NOTE D#, 2
	ATTEN 0
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 4
	NOTE D#, 2
	NOTE G_, 4
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_CALL SndF4_Ch2_5B73
	NOTE F#, 2
	VIBRATO 17, 5, 2
	NOTE G_, $0A
	DUTY 4
	RELEASE $0A, 7
	DUTY_STEP 4, 1
	VIBRATO 20, 0, 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	SND_CALL SndF4_Ch2_5B73
	NOTE D#, 2
	VIBRATO 17, 4, 2
	NOTE C_, 6
	VIBRATO 20, 0, 4
	DUTY_STEP 4, 1
	RELEASE $0A, 7
	DUTY 4
	ATTEN 2
	NOTE C_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, 2
	LOOP2_START
	SND_CALL SndF4_Ch2_5BBD
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 3
	REST 1
	ATTEN 4
	NOTE G_, 4
	DUTY 4
	ATTEN 3
	OCTAVE 3
	NOTE G_, 3
	REST 1
	ATTEN 5
	NOTE G_, 4
	ATTEN 2
	NOTE G_, 3
	REST 1
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 3
	REST 1
	ATTEN 4
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 4
	SND_CALL SndF4_Ch2_5BBD
	SND_JUMP_N 2, SndF4_Ch2_5B58
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 3
	REST 1
	ATTEN 4
	NOTE G#, 4
	DUTY 4
	ATTEN 3
	OCTAVE 4
	NOTE D_, 3
	REST 1
	ATTEN 5
	NOTE D_, 4
	ATTEN 2
	NOTE D_, 3
	REST 1
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE D_, 3
	REST 1
	ATTEN 4
	NOTE D_, 4
	ATTEN 0
	NOTE D_, 4
SndF4_Ch2_5B58:
	LOOP2_END 2
	LEN_UNIT $04
	ATTEN 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	ATTEN 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 1
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	ATTEN 0
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	NOTE A#, 2
	SND_LOOP
SndF4_Ch2_5B73:
	VOICE $04, 8, 7, 15, 5
	TRANSPOSE_DOWN 3
	VIBRATO 20, 0, 1
	DUTY_STEP 8, 1
	ATTEN 1
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 0
	DUTY 0
	NOTE C_HI, 4
	CLEAR $0C
	NOTE B_, 4
	VIBRATO 20, 0, 1
	DUTY_STEP 8, 1
	ATTEN 2
	DUTY 8
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 0
	DUTY 0
	NOTE A#, 4
	CLEAR $0C
	NOTE A_, 4
	VIBRATO 20, 0, 1
	DUTY_STEP 8, 1
	ATTEN 2
	DUTY 8
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 0
	DUTY 0
	NOTE G#, 4
	CLEAR $0C
	NOTE G_, 4
	VOICE $04, 0, 7, 12, 7
	VIBRATO 20, 0, 1
	DUTY_STEP 8, 1
	SND_RET
SndF4_Ch2_5BBD:
	VOICE $02, 0, 7, 15, 7
	VIBRATO 20, 0, 15
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 3
	REST 1
	ATTEN 4
	NOTE G#, 4
	DUTY 4
	ATTEN 3
	OCTAVE 3
	NOTE A#, 3
	REST 1
	ATTEN 5
	NOTE A#, 4
	ATTEN 1
	NOTE A#, 3
	REST 1
	ATTEN 5
	NOTE A#, 4
	ATTEN 0
	NOTE A#, 3
	REST 1
	ATTEN 4
	NOTE A#, 4
	ATTEN 0
	NOTE A#, 4
	DUTY 0
	SND_RET

SndF4_Ch1:
	SND_SEGNO
	VOICE $04, 0, 6, 15, 6
	TRANSPOSE_DOWN 3
	DUTY_STEP 4, 1
	VIBRATO 17, 3, 1
	ATTEN 3
	OCTAVE 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	SND_CALL SndF4_Ch1_5C7F
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	RELEASE $0A, 7
	DUTY 4
	ATTEN 3
	OCTAVE 2
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 1
	NOTE A#, 2
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	SND_CALL SndF4_Ch1_5C7F
	DUTY_STEP 4, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	RELEASE $0A, 7
	DUTY 4
	ATTEN 3
	NOTE A_, 2
	NOTE A#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 2
	OCTAVE 3
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	SND_CALL SndF4_Ch1_5CCF
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	ATTEN 1
	LOOP_END 2
	ATTEN 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	LOOP_END 2
	SND_CALL SndF4_Ch1_5CCF
	DUTY 4
	DUTY_STEP 8, 1
	VIBRATO 18, 0, 3
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	SND_LOOP
SndF4_Ch1_5C7F:
	VOICE $04, 8, 6, 15, 6
	DUTY_STEP 8, 1
	TRANSPOSE_DOWN 3
	DETUNE $FF
	VIBRATO 17, 2, 3
	ATTEN 1
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	VIBRATO_SEMI $16
	DUTY 0
	NOTE G_, 4
	NOTE G_, 4
	VIBRATO 17, 2, 3
	ATTEN 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	VIBRATO_SEMI $16
	DUTY 0
	NOTE D#, 4
	NOTE D#, 4
	VIBRATO 17, 2, 3
	ATTEN 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	VIBRATO_SEMI $16
	DUTY 0
	NOTE D#, 4
	NOTE D#, 4
	VIBRATO 20, 0, 3
	DETUNE $00
	SND_RET
SndF4_Ch1_5CCF:
	VOICE $04, 8, 6, 15, 4
	VIBRATO_SEMI $17
	DUTY_STEP 4, 1
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	LOOP_END 2
	ATTEN 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	ATTEN 1
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	ATTEN 0
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D#, 2
	ATTEN 1
	LOOP_END 2
	ATTEN 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D#, 2
	ATTEN 3
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	LOOP_END 2
	ATTEN 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	ATTEN 1
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	ATTEN 0
	LOOP_END 2
	SND_RET

SndF4_Ch3:
	SND_SEGNO
	VOICE $04, 4, 2, 6, 9
	VIBRATO_SEMI $13
	TRANSPOSE_UP 9
	RELEASE_VOL 4
	SND_CALL SndF4_Ch3_5D52
	WAVE 2
	LOOP2_START
	SND_CALL SndF4_Ch3_5D52
	LOOP2_END 2
	TRANSPOSE_DOWN 3
	LOOP_START
	SND_CALL SndF4_Ch3_5D61
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE C_, 2
	LOOP_END 3
	SND_CALL SndF4_Ch3_5D61
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 2
	SND_LOOP
SndF4_Ch3_5D52:
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE A#, 2
	LOOP_END 4
	SND_RET
SndF4_Ch3_5D61:
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	NOTE C#, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE C#, 2
	SND_RET

SndF4_Drm:
	LEN_UNIT $04
	SND_SEGNO
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 3
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 7
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 6
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	LOOP_START
	DRUM 5, 2
	LOOP_END 12
	SND_LOOP

SndF5_Ch2:
	TEMPO $20
	SND_SEGNO
	VOICE $06, 8, 5, 12, 5
	VIBRATO_SEMI $13
	DETUNE $FD
	RELEASE_VOL 2
	DUTY_STEP 0, 0
	SND_CALL SndF5_Ch1_60C7
	ATTEN 1
	SND_CALL SndF5_Ch1_60C7
	ATTEN 2
	SND_CALL SndF5_Ch1_60C7
	ATTEN 3
	SND_CALL SndF5_Ch1_5EF8
	ATTEN 0
	LOOP2_START
	SND_CALL SndF5_Ch2_5E8D
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	DUTY 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 2
	VIBRATO 20, 0, 8
	DUTY 0
	ATTEN 4
	OCTAVE 4
	NOTE E_, 2
	DUTY 4
	RELEASE $0B, 7
	VIBRATO 18, 2, 6
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C#, 2
	REST 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE D_, 6
	ATTEN 1
	NOTE C#, 8
	SND_CALL SndF5_Ch2_5E8D
	SND_JUMP_N 2, SndF5_Ch2_5E24
	VIBRATO_SEMI $13
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	REST 2
	ATTEN 3
	NOTE B_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	REST 2
SndF5_Ch2_5E24:
	LOOP2_END 2
	VIBRATO 20, 0, 1
	RELEASE $0F, 6
	ATTEN 2
	DUTY 8
	DUTY_STEP 0, 1
	OCTAVE 1
	NOTE E_, 2
	DUTY 8
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	LOOP2_START
	SND_CALL SndF5_Ch2_5ECA
	SND_CALL SndF5_Ch2_5F20
	LOOP_START
	SND_CALL SndF5_Ch2_5EE9
	LOOP_END 2
	SND_CALL SndF5_Ch2_5ECA
	SND_JUMP_N 2, SndF5_Ch2_5E7C
	SND_CALL SndF5_Ch2_5F20
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	VOICE $03, 8, 6, 15, 7
	VIBRATO 20, 2, 1
	ATTEN 3
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	NOTE F#, 2
SndF5_Ch2_5E7C:
	LOOP2_END 2
	VOICE $04, 0, 7, 15, 7
	OCTAVE 1
	NOTE B_, 3
	CLEAR $0A
	SND_CALL SndF5_Ch1_5F07
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	SND_LOOP
SndF5_Ch2_5E8D:
	VOICE $03, 4, 6, 13, 5
	CLEAR $0C
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	VIBRATO_SEMI $13
	DUTY 0
	DUTY_STEP 4, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 1
	REST 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 1
	REST 1
	ATTEN 3
	NOTE F#, 2
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE E_, 2
	VIBRATO_OFF
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	DUTY_STEP 4, 1
	DUTY 0
	VIBRATO 20, 0, 3
	RELEASE 6, 1
	SND_RET
SndF5_Ch2_5ECA:
	VOICE $03, 0, 6, 15, 7
	DUTY_STEP 4, 1
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_START
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 2
	SND_RET
SndF5_Ch2_5EE9:
	ATTEN 4
	OCTAVE 2
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	SND_RET
SndF5_Ch1_5EF8:
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	LOOP_START
	NOTE E_, 2
	LOOP_END 5
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	DETUNE $00
	SND_RET
SndF5_Ch1_5F07:
	ATTEN 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	LEN_UNIT $03
	ATTEN 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 1
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	SND_RET
SndF5_Ch2_5F20:
	DUTY 4
	DUTY_STEP 0, 2
	VIBRATO_SEMI $12
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	SND_RET

SndF5_Ch1:
	SND_SEGNO
	VOICE $06, 0, 5, 8, 2
	DUTY_STEP 8, 1
	VIBRATO_OFF
	DETUNE $02
	SND_CALL SndF5_Ch1_60C7
	ATTEN 1
	SND_CALL SndF5_Ch1_60C7
	ATTEN 1
	SND_CALL SndF5_Ch1_60C7
	SND_CALL SndF5_Ch1_5EF8
	LOOP2_START
	SND_CALL SndF5_Ch1_5FF2
	DUTY 4
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0B, 5
	DUTY 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE G_, 1
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE B_, 1
	DUTY 4
	VIBRATO 17, 2, 2
	OCTAVE 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	REST 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 3
	ATTEN 1
	NOTE A_, 4
	SND_CALL SndF5_Ch1_5FF2
	SND_JUMP_N 2, SndF5_Ch1_5F8C
	VIBRATO_SEMI $13
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE F#, 1
	REST 1
SndF5_Ch1_5F8C:
	LOOP2_END 2
	VIBRATO 20, 0, 1
	RELEASE $0C, 4
	DETUNE $FF
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	DUTY 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
	DETUNE $00
	LOOP2_START
	SND_CALL SndF5_Ch1_602E
	VIBRATO_SEMI $13
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_START
	SND_CALL SndF5_Ch1_604E
	LOOP_END 2
	SND_CALL SndF5_Ch1_602E
	SND_JUMP_N 2, SndF5_Ch1_5FE3
	VIBRATO_SEMI $13
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_CALL SndF5_Ch1_604E
	VOICE $06, 8, 5, 15, 7
	VIBRATO 17, 1, 2
	ATTEN 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
SndF5_Ch1_5FE3:
	LOOP2_END 2
	REST 4
	CLEAR $0C
	VOICE $04, 0, 4, 15, 7
	DETUNE $FE
	SND_CALL SndF5_Ch1_5F07
	SND_LOOP
SndF5_Ch1_5FF2:
	VOICE $06, 4, 5, 10, 7
	CLEAR $0E
	ATTEN 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	ATTEN 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	DUTY 0
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	DETUNE $FE
	REST 1
	ATTEN 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	DUTY 8
	OCTAVE 2
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	VOICE $06, 0, 5, 6, 1
	VIBRATO 20, 0, 3
	DUTY_STEP 4, 1
	DETUNE $00
	SND_RET
SndF5_Ch1_602E:
	VOICE $06, 0, 5, 14, 2
	CLEAR $0C
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	LOOP_START
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	LOOP_END 2
	SND_RET
SndF5_Ch1_604E:
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_RET

SndF5_Ch3:
	SND_SEGNO
	VOICE $06, 2, 2, 9, 7
	RELEASE_VOL 6
	VIBRATO_SEMI $13
	LOOP2_START
	SND_CALL SndF5_Ch1_60C7
	LOOP2_END 12
	LOOP2_START
	SND_CALL SndF5_Ch3_60B3
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_CALL SndF5_Ch3_60B3
	SND_JUMP_N 2, SndF5_Ch3_609E
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
SndF5_Ch3_609E:
	LOOP2_END 2
	OCTAVE 1
	NOTE B_, 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	SND_LOOP
SndF5_Ch3_60B3:
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	SND_RET
SndF5_Ch1_60C7:
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	LOOP_START
	NOTE E_, 2
	LOOP_END 5
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	SND_RET

SndF5_Drm:
	SND_SEGNO
	LEN_UNIT $06
	LOOP_START
	SND_CALL SndF5_Drm_6121
	LOOP_END 3
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 5, 1
	LOOP_END 8
	LOOP_START
	SND_CALL SndF5_Drm_6121
	LOOP_END 7
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM $0A, 1
	DRUM 2, 1
	LEN_UNIT $04
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $06
	LOOP_START
	DRUM 5, 1
	LOOP_END 12
	SND_LOOP
SndF5_Drm_6121:
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_RET

SndF6_Ch1:
	SND_END

SndF7_Ch2:
	TRANSPOSE_DOWN 2
	LEN_UNIT $06
	REST 4
	SND_SEGNO
	SND_CALL SndF7_Ch1_628B
	VOICE $06, 0, 6, 0, 0
	VIBRATO 21, 0, 3
	OCTAVE 4
	NOTE B_, 2
	VIBRATO_OFF
	ATTEN 2
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 4
	ATTEN 5
	NOTE B_, 4
	NOTE B_, $0D
	SND_CALL SndF7_Ch1_6178
	VIBRATO 24, 0, 3
	OCTAVE 4
	NOTE G_, 3
	VIBRATO 19, 0, 12
	NOTE G_, 2
	LOOP2_START
	LOOP_START
	VIBRATO 24, 0, 3
	NOTE G_, 2
	VIBRATO 19, 0, 12
	NOTE G_, 1
	LOOP_END 4
	VIBRATO 24, 0, 3
	NOTE G_, 2
	VIBRATO 19, 0, 12
	NOTE G_, 2
	LOOP2_END 2
	VIBRATO 24, 0, 3
	NOTE G_, 2
	SND_CALL SndF7_Ch1_620F
	SND_LOOP
SndF7_Ch1_6178:
	VIBRATO 19, 0, 12
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	VIBRATO 22, 0, 3
	NOTE A_, 1
	VIBRATO 19, 0, 12
	NOTE E_, 2
	LOOP_START
	VIBRATO 19, 0, 12
	NOTE E_, 1
	NOTE D_, 1
	VIBRATO 21, 0, 3
	NOTE E_, 2
	LOOP_END 2
	VIBRATO 19, 0, 12
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	VIBRATO 21, 0, 8
	NOTE B_, 2
	VIBRATO 19, 0, 8
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	VIBRATO 23, 2, 12
	NOTE E_, 4
	REST 2
	OCTAVE 2
	LEN_UNIT $04
	NOTE A_, 1
	VIBRATO_OFF
	NOTE A#, 1
	NOTE B_, 1
	VIBRATO 19, 0, 12
	OCTAVE 3
	LEN_UNIT $06
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	VIBRATO 21, 0, 10
	NOTE G_, 5
	VIBRATO 22, 1, 3
	NOTE G_, 2
	VIBRATO 19, 0, 12
	NOTE E_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	VIBRATO 23, 2, 12
	NOTE E_, 4
	VIBRATO 19, 0, 12
	REST 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	VIBRATO 21, 1, 3
	NOTE B_, 2
	VIBRATO 19, 0, 12
	NOTE A_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET
SndF7_Ch1_620F:
	VIBRATO 19, 0, 12
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	VIBRATO 21, 0, 3
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	VIBRATO 19, 0, 12
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	VIBRATO 22, 0, 3
	NOTE C_, 2
	VIBRATO 19, 0, 12
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	VIBRATO 22, 0, 3
	OCTAVE 4
	NOTE C_, 2
	REST 1
	VIBRATO 23, 1, 15
	NOTE C_, 3
	VIBRATO 19, 0, 12
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE A#, 2
	VIBRATO 21, 0, 10
	OCTAVE 4
	NOTE C_, 2
	VIBRATO 19, 0, 12
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	REST 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	VIBRATO 22, 0, 3
	NOTE E_, 2
	VIBRATO 19, 0, 12
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	VIBRATO 22, 0, 3
	OCTAVE 5
	NOTE C_, 2
	VIBRATO 19, 0, 12
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
SndF7_Ch1_628B:
	VOICE $01, 0, 8, 0, 0
	VIBRATO 19, 0, 15
	OCTAVE 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	SND_RET

SndF7_Ch1:
	LEN_UNIT $01
	REST 1
	DETUNE $01
	TRANSPOSE_DOWN 2
	LEN_UNIT $06
	REST 4
	SND_SEGNO
	SND_CALL SndF7_Ch1_628B
	VOICE $06, 8, 6, 8, 7
	VIBRATO_OFF
	ATTEN 2
	OCTAVE 4
	NOTE B_, $0A
	RELEASE 0, 0
	OCTAVE 5
	ATTEN 4
	NOTE B_, 4
	VIBRATO 17, 0, 1
	ATTEN 3
	NOTE B_, 4
	ATTEN 1
	NOTE B_, 4
	ATTEN 0
	NOTE B_, 2
	VIBRATO 23, 0, 1
	NOTE B_, 3
	DUTY 0
	VOICE $06, 4, 4, 4, 7
	SND_CALL SndF7_Ch1_6178
	VOICE $06, 4, 5, 4, 4
	OCTAVE 4
	NOTE G_, 3
	REST 2
	LOOP2_START
	LOOP_START
	NOTE G_, 2
	NOTE G_, 1
	LOOP_END 4
	NOTE G_, 2
	NOTE G_, 2
	LOOP2_END 2
	NOTE G_, 2
	VOICE $06, 4, 3, 4, 4
	SND_CALL SndF7_Ch1_620F
	SND_LOOP

SndF7_Ch3:
	LEN_UNIT $06
	REST 4
	RELEASE_VOL 4
	SND_SEGNO
	TRANSPOSE_DOWN 2
	LOOP2_START
	LOOP_START
	VOICE $03, 4, 2, 12, 3
	VIBRATO 19, 0, 10
	SND_CALL SndF7_Ch3_6330
	SND_CALL SndF7_Ch3_633C
	SND_CALL SndF7_Ch3_6330
	OCTAVE 1
	NOTE E_, 1
	REST 1
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	SND_CALL SndF7_Ch3_6330
	SND_CALL SndF7_Ch3_633C
	SND_CALL SndF7_Ch3_6330
	OCTAVE 1
	NOTE E_, 1
	REST 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE D_, 2
	LOOP_END 2
	TRANSPOSE_UP 1
	LOOP2_END 2
	SND_LOOP
SndF7_Ch3_6330:
	OCTAVE 1
	NOTE E_, 4
	NOTE E_, 1
	REST 1
	NOTE C_HI, 2
	NOTE E_, 1
	REST 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	SND_RET
SndF7_Ch3_633C:
	OCTAVE 1
	NOTE E_, 4
	NOTE E_, 1
	REST 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE E_, 1
	REST 1
	OCTAVE 2
	NOTE G_, 2
	NOTE E_, 4
	SND_RET

SndF7_Drm:
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 15
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 15
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	SND_LOOP

SndF8_Ch2:
	DUTY_STEP 4, 1
	LEN_UNIT $06
	REST 4
	SND_SEGNO
	TRANSPOSE_DOWN 2
	VOICE $06, 8, 5, 15, 4
	LOOP2_START
	LOOP_START
	SND_CALL SndF8_Ch2_63B2
	SND_CALL SndF8_Ch2_63C5
	SND_CALL SndF8_Ch2_63B2
	VIBRATO_SEMI $11
	DUTY 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 3
	SND_CALL SndF8_Ch2_63B2
	SND_CALL SndF8_Ch2_63C5
	SND_CALL SndF8_Ch2_63B2
	VIBRATO_SEMI $11
	DUTY 0
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	NOTE D_, 1
	NOTE E_, 2
	LOOP_END 2
	TRANSPOSE_UP 1
	LOOP2_END 2
	SND_LOOP
SndF8_Ch2_63B2:
	DUTY 8
	VIBRATO_OFF
	OCTAVE 3
	REST 1
	NOTE B_, 1
	REST 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	REST 1
	ATTEN 3
	NOTE C#, 1
	REST 1
	ATTEN 0
	SND_RET
SndF8_Ch2_63C5:
	ATTEN 0
	NOTE D_, 1
	REST 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 1
	REST 1
	NOTE C#, 1
	REST 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 0
	SND_RET

SndF8_Ch1:
	DUTY_STEP 4, 1
	LEN_UNIT $06
	REST 4
	SND_SEGNO
	TRANSPOSE_DOWN 2
	VOICE $06, 8, 5, 15, 3
	LOOP2_START
	LOOP_START
	SND_CALL SndF8_Ch1_6412
	SND_CALL SndF8_Ch1_6424
	SND_CALL SndF8_Ch1_6412
	VIBRATO_SEMI $11
	DUTY 0
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 3
	SND_CALL SndF8_Ch1_6412
	SND_CALL SndF8_Ch1_6424
	SND_CALL SndF8_Ch1_6412
	VIBRATO_SEMI $11
	DUTY 0
	REST 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 2
	LOOP_END 2
	TRANSPOSE_UP 1
	LOOP2_END 2
	SND_LOOP
SndF8_Ch1_6412:
	VIBRATO_OFF
	DUTY 8
	OCTAVE 3
	REST 1
	NOTE G_, 1
	REST 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	REST 1
	ATTEN 3
	NOTE A_, 1
	REST 1
	ATTEN 0
	SND_RET
SndF8_Ch1_6424:
	NOTE B_, 1
	REST 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	SND_RET

SndF9_Ch2:
	TEMPO $10
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 8, 15, 7
	VIBRATO 30, 0, 10
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE G#, 3
	DUTY_STEP 4, 1
	VIBRATO_OFF
	NOTE G_, 1
	VOICE $06, 8, 7, 14, 2
	PAN_LEFT 0
	VIBRATO 27, 0, 7
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	VOICE $06, 0, 6, 13, 6
	VIBRATO_SEMI $13
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	PAN_RIGHT 0
	VIBRATO_OFF
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	VOICE $06, 8, 6, 14, 2
	PAN_LEFT 0
	VIBRATO 27, 0, 7
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	VOICE $06, 4, 8, 15, 7
	ATTEN 1
	VIBRATO_OFF
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 0
	DUTY_STEP 0, 1
	VIBRATO 30, 0, 10
	NOTE G_, 3
	VIBRATO_OFF
	DUTY_STEP 4, 1
	NOTE F_, 1
	VOICE $06, 8, 7, 14, 2
	PAN_RIGHT 0
	VIBRATO 17, 0, 2
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	VOICE $06, 0, 6, 13, 6
	VIBRATO_SEMI $13
	SND_JUMP_N 2, SndF9_Ch2_64BE
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	PAN_LEFT 0
	VIBRATO_OFF
	ATTEN 5
	NOTE G#, 1
	VOICE $06, 8, 7, 15, 5
	VIBRATO 27, 0, 15
	PAN_BOTH 0
	PAN_RIGHT 0
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE A#, 1
SndF9_Ch2_64BE:
	LOOP_END 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_LOOP

SndF9_Ch1:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	LOOP_START
	VOICE $06, 4, 7, 15, 7
	DETUNE $00
	VIBRATO 30, 0, 10
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE D#, 3
	RELEASE $0D, 1
	VIBRATO_OFF
	NOTE D_, 1
	DETUNE $FF
	VOICE $06, 0, 7, 14, 3
	VIBRATO 17, 0, 3
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	DETUNE $00
	VIBRATO_SEMI $13
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	PAN_LEFT 0
	VIBRATO_OFF
	ATTEN 4
	NOTE C_, 1
	DETUNE $FF
	VIBRATO 17, 0, 2
	DUTY 0
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	REST 1
	VOICE $06, 4, 7, 10, 5
	CLEAR $0A
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	VIBRATO 30, 0, 10
	OCTAVE 3
	NOTE D#, 3
	RELEASE $0D, 1
	VIBRATO_OFF
	NOTE D_, 1
	DETUNE $FF
	VOICE $06, 8, 6, 14, 2
	VIBRATO 17, 0, 3
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	REST 1
	DETUNE $00
	VOICE $06, 0, 6, 15, 7
	OCTAVE 3
	VIBRATO_SEMI $13
	SND_JUMP_N 2, SndF9_Ch1_6545
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	REST 1
	VIBRATO 17, 0, 3
	DETUNE $FF
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE A#, 1
SndF9_Ch1_6545:
	LOOP_END 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_LOOP

SndF9_Ch3:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	VOICE $06, 2, 2, 6, 4
	VIBRATO_SEMI $13
	RELEASE_VOL 6
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	LOOP_END 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 1
	LOOP2_END 3
	REST 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_LOOP

SndF9_Drm:
	LEN_UNIT $01
	DRUM 7, 3
	DRUM 7, 3
	DRUM 7, 6
	DRUM 7, 6
	DRUM 8, 3
	DRUM 8, 3
	DRUM 8, 6
	DRUM 8, 6
	DRUM 9, 3
	DRUM 9, 3
	DRUM 9, 6
	SND_SEGNO
	DRUM $0A, 6
	DRUM 1, 6
	DRUM $0A, 6
	DRUM 2, 6
	DRUM 4, 6
	DRUM 2, 6
	DRUM 2, 6
	DRUM 5, 6
	DRUM 2, 3
	DRUM 2, 3
	DRUM 5, 6
	DRUM 2, 6
	DRUM $0A, 6
	DRUM 4, 6
	DRUM 2, 6
	DRUM 2, 6
	DRUM $0A, 6
	SND_LOOP

SndFA_Ch1:
	SND_END

SndFB_Ch2:
	TEMPO $20
	VOICE $06, 0, 8, 15, 6
	VIBRATO 20, 0, 4
	TRANSPOSE_DOWN $0A
	DUTY_STEP 4, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	PAN_BOTH 0
	VIBRATO 17, 5, 5
	RELEASE 8, 7
	DUTY 8
	ATTEN 3
	OCTAVE 3
	NOTE A#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	PAN_BOTH 0
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 1
	ATTEN 1
	PAN_BOTH 0
	VIBRATO 17, 5, 5
	RELEASE 8, 7
	NOTE C#, $0C
	SND_END
	db $FF ; unreachable

SndFB_Ch1:
	VOICE $06, 0, 8, 14, 3
	DUTY_STEP 4, 1
	VIBRATO 20, 0, 6
	TRANSPOSE_UP 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 2
	VIBRATO 20, 0, 15
	DUTY 0
	RELEASE $0F, 6
	ATTEN 3
	OCTAVE 2
	NOTE F#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 1
	PAN_BOTH 0
	ATTEN 2
	NOTE G_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE G#, 1
	ATTEN 1
	PAN_BOTH 0
	VIBRATO 18, 4, 3
	RELEASE 8, 7
	NOTE A_, $0C
	CLEAR $0C
	SND_END

SndFB_Ch3:
	VOICE $06, 4, 2, 3, 0
	VIBRATO_SEMI $13
	RELEASE_VOL 3
	TRANSPOSE_UP 2
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	WAVE 2
	OCTAVE 1
	NOTE G_, 1
	PAN_LEFT 0
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	PAN_RIGHT 0
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	PAN_LEFT 0
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	PAN_BOTH 0
	VIBRATO 17, 3, 7
	RELEASE 0, 0
	NOTE B_, $0C
	SND_END

SndFB_Drm:
	LEN_UNIT $06
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 0
	SND_END

SndFC_Ch2:
	TRANSPOSE_DOWN 9
	TEMPO $20
	VOICE $05, 4, 8, 12, 3
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	LEN_UNIT $05
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE A_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE A#, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE G_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A_, 1
	PAN_BOTH 0
	VOLUME $EF
	REST 2
	RELEASE 0, 0
	DUTY 0
	VIBRATO 18, 0, 9
	VOICE $05, 0, 1, 15, 15
	OCTAVE 1
	NOTE A_, 8
	VOICE $05, 0, 6, 0, 0
	NOTE A_, 8
	SND_END

SndFC_Ch1:
	TRANSPOSE_DOWN 9
	VOICE $05, 0, 7, 12, 3
	DETUNE $FF
	LEN_UNIT $01
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 3
	NOTE E_, 8
	NOTE A_, 5
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D_, 5
	NOTE G_, 2
	VOLUME $06
	LEN_UNIT $05
	PAN_BOTH 0
	ATTEN 0
	DUTY_STEP 4, 1
	DUTY 0
	VIBRATO_SEMI $14
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE E_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE D_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 3
	VOLUME $07
	VOICE $05, 0, 8, 0, 0
	DETUNE $FA
	VIBRATO 17, 1, 10
	OCTAVE 1
	NOTE A_, 0
	SND_END

SndFC_Ch3:
	TRANSPOSE_UP 3
	VOICE $05, 4, 2, 4, 3
	VIBRATO_SEMI $11
	REST 4
	RELEASE_VOL 6
	OCTAVE 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE A_, 2
	RELEASE_VOL 0
	TRANSPOSE_DOWN 9
	VOLUME $04
	WAVE 4
	OCTAVE 1
	NOTE A_, 0
	SND_END

SndFC_Drm:
	LEN_UNIT $05
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LOOP_START
	DRUM 4, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 5, 1
	LOOP_END 3
	DRUM 4, 1
	SND_END

SndFD_Ch2:
	TEMPO $10
	TRANSPOSE_DOWN 1
	VOICE $06, 0, 9, 14, 2
	DUTY_STEP 4, 1
	LEN_UNIT $01
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, 3
	LEN_UNIT $06
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	VIBRATO_SEMI $19
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 8, 1
	PAN_RIGHT 0
	ATTEN 6
	NOTE E_, 1
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE A_, 1
	NOTE B_, 1
	VOICE $06, 0, 9, 14, 5
	DUTY_STEP 8, 1
	VIBRATO 33, 1, 10
	OCTAVE 4
	NOTE D_, 3
	NOTE D#, 3
	VIBRATO_OFF
	RELEASE 8, 7
	OCTAVE 4
	NOTE E_, 3
	DUTY_STEP 0, 0
	LEN_UNIT $01
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $02
	OCTAVE 4
	NOTE E_, 7
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $01
	OCTAVE 4
	NOTE E_, 7
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

SndFD_Ch1:
	TRANSPOSE_DOWN 6
	VOICE $06, 0, 8, 14, 2
	DUTY_STEP 4, 1
	VIBRATO_SEMI $13
	ATTEN 2
	LEN_UNIT $01
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, 3
	LEN_UNIT $06
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	ATTEN 0
	DUTY 8
	DUTY_STEP 0, 1
	VIBRATO_SEMI $13
	DETUNE $FF
	TRANSPOSE_DOWN 1
	PAN_LEFT 0
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	VIBRATO_OFF
	TRANSPOSE_DOWN 6
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 6
	NOTE A_, 1
	NOTE B_, 1
	VOICE $06, 0, 7, 14, 3
	VIBRATO 18, 3, 5
	DUTY_STEP 8, 1
	VIBRATO 33, 1, 12
	OCTAVE 4
	NOTE D_, 3
	NOTE D#, 3
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 8, 7
	NOTE E_, 3
	DUTY_STEP 0, 0
	LEN_UNIT $01
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $02
	OCTAVE 4
	NOTE E_, 7
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOLUME $01
	NOTE E_, 7
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

SndFD_Ch3:
	TRANSPOSE_DOWN 1
	VOICE $06, 4, 2, 5, 7
	RELEASE_VOL 4
	REST 1
	VIBRATO_SEMI $13
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 8, 7
	OCTAVE 2
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 6
	SND_END

SndFD_Drm:
	LEN_UNIT $06
	LEN_UNIT $01
	DRUM 5, 3
	DRUM 5, 3
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 2
	SND_END

SndFE_Ch1:
	DETUNE $0A
	TRANSPOSE_UP 7

SndFE_Ch2:
	VOICE $08, 4, 1, 15, 9
	REST 1
	REST 1
	OCTAVE 1
	NOTE C_, 1
	VOICE $08, 4, 2, 0, 0
	NOTE C_, 4
	VOLUME $04
	NOTE C_, 3
	RELEASE 0, 0
	VOLUME $02
	NOTE C_, 1
	ATTEN 1
	NOTE C_, $0E
	SND_END

SndFE_Ch3:
	VOICE $08, 9, 6, 0, 0
	REST 1
	OCTAVE 1
	NOTE C_, 2
	VOLUME $04
	NOTE C_, 2
	VOLUME $02
	NOTE C_, 3
	VOLUME $04
	NOTE C_, 1
	VOLUME $06
	NOTE C_, $0F
	SND_END

SndFE_SfxN:
	LEN_UNIT $0C
	NOISE_VOLNOTE 0
	NVOICE $85, $01
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $7F
	NOISE_VOLNOTE 3
	LEN_UNIT $1F
	NOISE $7F
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

SndA1_Ch1:
	VOICE $03, 4, 5, 15, 9
	REST 0
	REST 0
	REST 7
	OCTAVE 1
	NOTE E_, 1
	RELEASE $0A, 5
	VOLUME $0F
	NOTE E_, 7
	LEN_UNIT $06
	VOLUME $02
	NOTE E_, 4
	ATTEN 1
	RELEASE 0, 0
	NOTE E_, 2
	REST 0
	REST $0B
	SND_JUMP SndFF_Ch2

SndA1_Ch2:
	DETUNE $FD
	TRANSPOSE_UP 0
	VOICE $03, 4, 5, 15, 9
	REST 0
	REST 0
	REST 7
	OCTAVE 1
	NOTE E_, 1
	RELEASE $0A, 5
	VOLUME $0F
	NOTE E_, 7
	LEN_UNIT $06
	VOLUME $02
	NOTE E_, 4
	ATTEN 1
	RELEASE 0, 0
	NOTE E_, 3
	REST 0
	REST $0A
	SND_JUMP SndFF_Ch1

SndA1_Ch3:
	VOICE $03, 9, 4, 15, 13
	REST 0
	REST 0
	REST 7
	DETUNE $02
	OCTAVE 1
	NOTE E_, 1
	VOLUME $02
	RELEASE 0, 0
	NOTE E_, 7
	LEN_UNIT $06
	VOLUME $04
	NOTE E_, 3
	VOLUME $06
	NOTE E_, 1
	REST 0
	REST $0D
	SND_JUMP SndFF_Ch3

SndA1_Drm:
	LEN_UNIT $03
	REST 0
	REST 0
	REST 7
	REST 8
	LEN_UNIT $06
	REST 9
	REST 0
	REST 8
	SND_JUMP SndFF_Drm

SndFF_Ch2:
	TEMPO $0C
	SND_CALL SndA1_Ch1_6AAC
	SND_CALL SndA1_Ch1_6B91
	SND_CALL SndA1_Ch1_6AAC
	SND_CALL SndA1_Ch1_6C2C
	VOICE $06, 8, 8, 9, 7
	VIBRATO 36, 0, 10
	OCTAVE 3
	NOTE F#, $0C
	VIBRATO_OFF
	NOTE F#, 3
	VIBRATO 36, 0, 5
	NOTE G#, $0D
	VIBRATO_OFF
	NOTE G#, 3
	VIBRATO 36, 0, 5
	NOTE A#, $0D
	VIBRATO_OFF
	OCTAVE 4
	NOTE D#, 3
	VIBRATO 36, 0, 5
	NOTE C_, $0B
	VOICE $06, 0, 10, 13, 3
	VIBRATO_OFF
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE D#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE D#, 1
	DUTY_STEP 4, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE D_, 1
	NOTE C#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE C#, 1
	SND_CALL SndA1_Ch1_6AAC
	VOICE $06, 8, 6, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE D#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE F_, 1
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	VOICE $06, 4, 7, 10, 1
	VIBRATO_SEMI $17
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	VOICE $06, 4, 11, 14, 2
	DUTY_STEP 0, 0
	PAN_BOTH 0
	VIBRATO_SEMI $13
	OCTAVE 3
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE C_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE F_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE A#, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE D#, 1
	NOTE D#, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE D#, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE G#, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE G#, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F#, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE B_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE B_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE C_, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE F_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F_, 1
	RELEASE $0F, 1
	PAN_BOTH 0
	DUTY_STEP 0, 1
	ATTEN 0
	NOTE A#, 2
	FADE $04
	DUTY_STEP 0, 0
	RELEASE 0, 0
	VOLUME $01
	NOTE A#, 2
	PAN_LEFT 0
	NOTE A#, 5
	SND_END
SndA1_Ch1_6AAC:
	VOICE $06, 0, 10, 12, 3
	VIBRATO_OFF
	PAN_BOTH 0
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 7
	OCTAVE 2
	NOTE C_, 1
	DUTY 0
	DUTY_STEP 0, 0
	OCTAVE 4
	PAN_RIGHT 0
	NOTE C_, 1
	DUTY 8
	PAN_BOTH 0
	VIBRATO_OFF
	ATTEN 6
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE A#, 1
	VOICE $06, 8, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE C_, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE C_, 1
	VOICE $06, 4, 7, 10, 1
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 4
	NOTE F_, 1
	DUTY 8
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 2
	NOTE A#, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	NOTE A#, 1
	DUTY 8
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	DUTY 8
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE A#, 1
	DUTY 8
	VIBRATO_OFF
	DUTY_STEP 0, 0
	ATTEN 1
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	DUTY 8
	VIBRATO_OFF
	ATTEN 1
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE G_, 1
	DUTY 4
	VIBRATO_SEMI $12
	ATTEN 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	NOTE A#, 1
	DUTY 8
	VIBRATO_OFF
	ATTEN 1
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE D_, 1
	VOICE $06, 0, 11, 14, 3
	VIBRATO_OFF
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY_STEP 0, 0
	ATTEN 1
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 6
	OCTAVE 2
	NOTE C_, 1
	VOLUME $0A
	DUTY 0
	VIBRATO_OFF
	PAN_LEFT 0
	ATTEN 7
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	PAN_BOTH 0
	VIBRATO_OFF
	ATTEN 6
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	SND_RET
SndA1_Ch1_6B91:
	VOICE $06, 8, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE D#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE F_, 1
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE D#, 1
	VOICE $06, 4, 7, 10, 1
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	OCTAVE 3
	ATTEN 4
	NOTE A#, 1
	DUTY 8
	VIBRATO_OFF
	ATTEN 1
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE A#, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	VIBRATO_OFF
	ATTEN 1
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	DUTY 8
	VIBRATO_OFF
	ATTEN 1
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE C_, 1
	DUTY 4
	VIBRATO_SEMI $12
	DUTY_STEP 8, 1
	ATTEN 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	VOICE $02, 0, 10, 13, 3
	DUTY_STEP 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	LEN_UNIT $06
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE C_, 1
	ATTEN 1
	PAN_BOTH 0
	DUTY_STEP 4, 1
	NOTE F_, 1
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE F_, 1
	DUTY_STEP 4, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE A#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE A#, 1
	SND_RET
SndA1_Ch1_6C2C:
	VOICE $06, 8, 6, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE D#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE F_, 1
	NOTE F_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	VOICE $06, 4, 7, 10, 1
	VIBRATO_SEMI $17
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	VOICE $06, 4, 11, 13, 2
	DUTY_STEP 8, 1
	PAN_BOTH 0
	VIBRATO_OFF
	OCTAVE 3
	DUTY_STEP 8, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE C_, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE F_, 1
	NOTE F_, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE F_, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D#, 1
	NOTE D#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE D#, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G#, 1
	NOTE G#, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE G#, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G_, 1
	DUTY_STEP 8, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	SND_RET

SndFF_Ch1:
	DETUNE $01
	SND_CALL SndA1_Ch2_6D75
	SND_CALL SndA1_Ch2_6DE2
	SND_CALL SndA1_Ch2_6D75
	SND_CALL SndA1_Ch2_6E59
	VOICE $06, 4, 5, 0, 0
	VIBRATO_SEMI $1F
	ATTEN 0
	AUTOPAN 0
	OCTAVE 3
	NOTE C#, 4
	ATTEN 1
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	NOTE C#, 3
	NOTE C_, 3
	ATTEN 1
	NOTE C_, 3
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	NOTE F#, 3
	ATTEN 0
	NOTE A#, 3
	LEN_UNIT $09
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 2
	NOTE G#, 1
	NOTE G#, 1
	LEN_UNIT $03
	NOTE G#, 1
	VOICE $06, 0, 9, 13, 3
	VIBRATO_OFF
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE A#, 1
	DUTY_STEP 4, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE A_, 1
	NOTE G#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	SND_CALL SndA1_Ch2_6D75
	VOICE $06, 0, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 2
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	VOICE $03, 4, 2, 15, 7
	VIBRATO_SEMI $17
	AUTOPAN 0
	DUTY_STEP 8, 1
	REST 1
	LEN_UNIT $06
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 1
	LEN_UNIT $03
	OCTAVE 2
	NOTE C_, 1
	VOICE $06, 8, 7, 13, 3
	DUTY_STEP 4, 1
	PAN_BOTH 0
	VIBRATO_SEMI $12
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	RELEASE $0F, 1
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 0, 0
	VOLUME $01
	NOTE F_, 2
	PAN_LEFT 0
	NOTE F_, 5
	SND_END
SndA1_Ch2_6D75:
	VOICE $06, 0, 9, 13, 3
	VIBRATO_OFF
	PAN_BOTH 0
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE G_, 1
	REST 1
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	ATTEN 7
	NOTE G_, 1
	REST 4
	VOICE $06, 0, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 2
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE F_, 1
	NOTE F_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE F_, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE G_, 1
	VOICE $03, 4, 2, 15, 7
	VIBRATO_SEMI $12
	AUTOPAN 0
	DUTY_STEP 8, 1
	REST 1
	LEN_UNIT $06
	OCTAVE 3
	ATTEN 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A#, 1
	ATTEN 0
	LOOP_START
	NOTE A#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A#, 1
	LOOP_END 2
	LEN_UNIT $03
	NOTE A#, 1
	VOICE $06, 0, 9, 13, 3
	VIBRATO_OFF
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 3
	NOTE F_, 1
	DUTY_STEP 0, 0
	NOTE G_, 1
	REST 1
	PAN_LEFT 0
	ATTEN 7
	NOTE F_, 1
	NOTE G_, 1
	REST 3
	DUTY_STEP 0, 0
	SND_RET
SndA1_Ch2_6DE2:
	VOICE $06, 0, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 2
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE A#, 1
	LEN_UNIT $03
	NOTE A#, 1
	VOICE $06, 4, 2, 15, 7
	VIBRATO_SEMI $12
	AUTOPAN 0
	DUTY_STEP 8, 1
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	ATTEN 0
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	LEN_UNIT $03
	REST 1
	VOICE $02, 0, 9, 14, 3
	VIBRATO_OFF
	DUTY_STEP 0, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	LEN_UNIT $06
	VIBRATO_SEMI $13
	DUTY_STEP 4, 1
	ATTEN 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G_, 1
	DUTY_STEP 4, 1
	ATTEN 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	DUTY_STEP 4, 1
	PAN_BOTH 0
	ATTEN 1
	NOTE F_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE F_, 1
	SND_RET
SndA1_Ch2_6E59:
	VOICE $06, 0, 5, 10, 2
	VIBRATO_OFF
	DUTY_STEP 4, 1
	PAN_BOTH 0
	OCTAVE 2
	NOTE A#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	VOICE $03, 4, 2, 15, 7
	VIBRATO_SEMI $17
	AUTOPAN 0
	DUTY_STEP 8, 1
	REST 1
	LEN_UNIT $06
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 1
	LEN_UNIT $03
	OCTAVE 2
	NOTE C_, 1
	VOICE $06, 4, 8, 13, 3
	DUTY_STEP 0, 0
	PAN_BOTH 0
	VIBRATO_SEMI $1D
	OCTAVE 2
	DUTY_STEP 0, 1
	NOTE G_, 1
	NOTE G_, 1
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 6
	NOTE G_, 1
	DUTY_STEP 0, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE C_, 1
	DUTY_STEP 0, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE A#, 1
	DUTY_STEP 0, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	DUTY_STEP 0, 0
	PAN_RIGHT 0
	ATTEN 6
	NOTE D#, 1
	DUTY_STEP 0, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	DUTY_STEP 0, 0
	PAN_LEFT 0
	ATTEN 6
	NOTE D_, 1
	DUTY_STEP 0, 1
	PAN_BOTH 0
	ATTEN 0
	NOTE G_, 1
	SND_RET

SndFF_Ch3:
	VOICE $06, 2, 2, 10, 7
	RELEASE_VOL 4
	DETUNE $FF
	OCTAVE 3
	NOTE C_, 1
	LOOP_START
	SND_CALL SndA1_Ch3_6F64
	LOOP_END 3
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE A#, 2
	NOTE C_, 1
	RELEASE_VOL 6
	NOTE D#, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE_VOL 4
	LOOP_START
	SND_CALL SndA1_Ch3_6F64
	LOOP_END 3
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE C#, 1
	NOTE D#, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 2
	OCTAVE 1
	NOTE D#, 3
	OCTAVE 2
	NOTE D#, 2
	NOTE C#, 1
	NOTE D#, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 2
	NOTE C_, 1
	LOOP_START
	SND_CALL SndA1_Ch3_6F64
	LOOP_END 3
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	SND_END
	db $14 ; unreachable
	db $FF
SndA1_Ch3_6F64:
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE A#, 2
	NOTE A#, 1
	SND_RET

SndFF_Drm:
	LEN_UNIT $06
	DRUM 4, 1
	SND_CALL SndA1_Drm_7054
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 2, 1
	SND_CALL SndA1_Drm_7054
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 2, 1
	LEN_UNIT $03
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $06
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 4, 1
	SND_CALL SndA1_Drm_7054
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $06
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 4, 1
	SND_CALL SndA1_Drm_7054
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 8, 1
	DRUM 8, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 4, 1
	DRUM $0A, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 3, 8
	SND_END
SndA1_Drm_7054:
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	SND_RET

SndA1_SfxN:
	SND_END

SndA3_Sfx1:
	VOICE $01, 8, 10, 15, 1
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE_SKIP 6
	OCTAVE 4
	NOTE_SKIP 1
	DUTY 4
	NOTE_SKIP 6
	VOLUME $03
	LOOP_END 3
	SND_END

SndA4_Sfx1:
	VOICE $04, 8, 10, 15, 9
	DUTY_STEP $0C, 2
	LOOP_START
	OCTAVE 3
	NOTES $0A, $0D
	LEN_UNIT $02
	VIBRATO_OFF
	VOLUME $03
	NOTES $0A, $0D
	VOLUME $05
	LEN_UNIT $04
	LOOP_END 2
	SND_END

SndA5_Sfx2:
	SND_END

SndA5_SfxN:
	SND_END

SndA6_Sfx1:
	VOICE $02, 8, 15, 0, 0
	OCTAVE 5
	LOOP_START
	NOTES 1, 8
	NOTES 4, $0B
	NOTE_SKIP 8
	VOLUME $03
	LOOP_END 3
	SND_END

SndA7_Sfx1:
	VOICE $06, 8, 15, 15, 1
	VIBRATO_SEMI 1
	OCTAVE 5
	LOOP_START
	NOTES 1, 1
	LEN_UNIT $0A
	NOTE_UNIT 1, $06
	VOLUME $06
	LOOP_END 2
	VOLUME $04
	NOTES 1, 1
	LEN_UNIT $0A
	NOTE_UNIT 1, $06
	SND_END

SndA7_Sfx2:
	VOICE $06, 3, 2, 15, 3
	VIBRATO_SEMI 1
	OCTAVE 4
	LOOP_START
	NOTES 8, 8
	LEN_UNIT $0A
	NOTE_UNIT 8, $06
	VOLUME $04
	LOOP_END 2
	VOLUME $06
	WAVE 1
	OCTAVE 5
	LOOP_START
	NOTES 8, 8
	LEN_UNIT $0A
	NOTE_UNIT 8, $06
	SND_END

SndA8_Sfx1:
	VOICE $01, 8, 7, 0, 0
	VIBRATO_SEMI 1
	OCTAVE 5
	NOTE_SKIP 1
	ATTEN 5
	NOTE_SKIP 1
	SND_END

SndA8_Sfx2:
	VOICE $03, 1, 2, 0, 0
	VIBRATO_SEMI 1
	DETUNE $01
	OCTAVE 6
	NOTE_SKIP 1
	VOLUME $06
	NOTE_SKIP 1
	SND_END

SndA4_Sfx2:
	VOICE $04, 1, 4, 15, 9
	DETUNE $FF
	LOOP_START
	OCTAVE 4
	NOTES $0A, $0D
	LEN_UNIT $02
	VOLUME $06
	NOTES $0A, $0D
	VOLUME $05
	LEN_UNIT $04
	LOOP_END 2
	SND_END

SndA9_SfxN:
	NVOICE $98, $B0
	NOISE $24
	NVOICE $81, $0F
	LOOP_START
	NOISE $14
	NOISE $15
	NOISE $24
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE_VOL 3
	LOOP_END 2
	SND_END

SndAA_Sfx1:
	VOICE $02, 8, 15, 0, 0
	DETUNE $FF
	LOOP_START
	OCTAVE 4
	NOTES 3, 8
	NOTE_SKIP $0A
	OCTAVE 5
	NOTES 3, 5
	NOTE_SKIP 8
	VOLUME $02
	LOOP_END 2
	SND_END

SndAA_Sfx2:
	VOICE $01, 5, 4, 0, 0
	NOTE_UNIT 0, $02
	LOOP_START
	OCTAVE 5
	NOTES 3, 8
	NOTE_SKIP $0A
	OCTAVE 6
	NOTES 3, 5
	NOTE_SKIP 8
	VOLUME $06
	LOOP_END 2
	SND_END

SndE7_Sfx2:
	VOICE $01, 14, 2, 0, 0
	OCTAVE 2
	LOOP_START
	NOTES 7, 7
	LOOP_END 3
	NOTES 0, 0
	LOOP2_START
	LOOP_START
	NOTES 7, 7
	LOOP_END 10
	VOLUME $06
	LOOP2_END 2

SndE7_Sfx1:
	SND_END

SndAB_Sfx1:
	SND_END

SndAB_Sfx2:
	SND_END

SndAB_SfxN:
	NVOICE $81, $0F
	NOISE $3E
	NOISE $4E
	NOISE $7F
	NOISE $34
	NOISE $27
	NOISE $25
	NOISE $24
	NOISE $25
	LOOP_START
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE_VOL 2
	LOOP_END 2
	SND_END

SndAC_Sfx1:
	VOICE $01, 4, 15, 0, 0
	OCTAVE 1
	NOTES 4, 5
	NOTE_SKIP 6
	VOLUME $02
	NOTES 4, 5
	NOTE_SKIP 6

SndAC_Sfx2:
	SND_END

SndAC_SfxN:
	NVOICE $81, $0F
	NOISE $4D
	NOISE $37
	NOISE $7F
	NOISE_VOL $0A
	NOISE $54
	NOISE_VOL 8
	NOISE $1F
	NOISE $4D
	NVOICE $81, $0F
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE $0A
	NOISE $47
	NOISE $27
	NOISE $25
	NVOICE $86, $1F
	NOISE $15
	SND_END

SndAD_Sfx1:
	VOICE $02, 8, 10, 0, 0
	OCTAVE 5
	NOTES 8, 5
	ATTEN 7
	NOTES 8, 5
	SND_END

SndAD_Sfx2:
	VOICE $02, 5, 4, 0, 0
	OCTAVE 6
	NOTES 8, 5
	NOTES 8, 5
	SND_END

SndAE_Sfx1:
	SND_CALL SndAE_Sfx1_71A3
	db $FF ; unreachable
SndAE_Sfx1_71A3:
	VOICE $01, 4, 1, 0, 0
	PAN_RIGHT 0
	OCTAVE 1
	NOTES 2, 4
	NOTE_SKIP 2
	SND_END
	db $FD ; unreachable

SndAE_SfxN:
	SND_CALL SndAE_SfxN_71B2
	SND_END
SndAE_SfxN_71B2:
	NVOICE $81, $07
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE 3
	NOISE $44
	NOISE $25
	NOISE $17
	NVOICE $86, $16
	NOISE $14
	SND_RET

SndAF_Sfx1:
	VOICE $01, 4, 2, 0, 0
	PAN_RIGHT 0
	OCTAVE 1
	NOTES 2, 4
	NOTE_SKIP 2
	SND_END
	db $FF ; unreachable

SndAF_SfxN:
	NVOICE $81, $0A
	LOOP_START
	NOISE $2F
	NOISE $7F
	NOISE_VOL 3
	LOOP_END 2
	SND_END

SndB0_Sfx1:
	VOICE $01, 4, 5, 0, 0
	SWEEP $13
	OCTAVE 1
	NOTES 9, 5
	NOTES 3, 1
	NOTES 1, 2
	NOTE_SKIP 1
	SND_END

SndB0_SfxN:
	NVOICE $82, $0F
	NOISE $4F
	LEN_UNIT $01
	NOISE $7F
	NOISE_VOL 3
	NOISE $6D
	NOISE $24
	NOISE $37
	SND_END

SndB1_Sfx1:
	VOICE $05, 8, 2, 0, 0
	NOTE_UNIT 0, $02
	SWEEP $16
	SND_CALL SndB1_Sfx1_71F9
	SND_END
SndB1_Sfx1_71F9:
	ATTEN 1
	OCTAVE 3
	NOTE_SKIP $0C
	OCTAVE 4
	NOTE_SKIP 1
	ATTEN 0
	LEN_UNIT $01
	OCTAVE 4
	NOTES 2, 1
	OCTAVE 3
	NOTES $0C, $0B
	NOTES 9, 7
	NOTE_SKIP 5
	SND_RET
	db $FF ; unreachable

SndB1_SfxN:
	NVOICE $85, $A1
	NOISE $36
	NVOICE $82, $04
	NOISE $26
	NOISE $34
	NVOICE $87, $23
	NOISE $16
	SND_END

SndB2_Sfx1:
	VOICE $04, 8, 1, 0, 0
	NOTE_UNIT 0, $02
	TRANSPOSE_UP 2
	SND_CALL SndB1_Sfx1_71F9
	SND_END

SndB2_SfxN:
	NVOICE $85, $92
	NOISE $14
	NVOICE $82, $04
	NOISE $07
	NOISE $15
	NVOICE $87, $22
	NOISE $36
	SND_END

SndB3_Sfx1:
	VOICE $01, 8, 2, 0, 0
	SWEEP $16
	SND_CALL SndB3_Sfx1_723B
	SND_END
SndB3_Sfx1_723B:
	OCTAVE 3
	NOTES $0B, 9
	OCTAVE 4
	NOTES 6, 5
	NOTE_SKIP 3
	OCTAVE 3
	NOTE_SKIP $0B
	SND_RET

SndB3_SfxN:
	NVOICE $81, $A3
	NOISE $34
	NOISE_VOL 5
	NOISE $16
	NOISE $25
	NOISE $14
	NOISE $06
	SND_END

SndB4_Sfx1:
	VOICE $01, 8, 1, 0, 0
	SWEEP $17
	TRANSPOSE_UP 5
	SND_CALL SndB3_Sfx1_723B
	SND_END

SndB4_SfxN:
	NVOICE $82, $D3
	NOISE $26
	NVOICE $81, $03
	NOISE $16
	NOISE $14
	NOISE $24
	SND_END

SndB5_Sfx1:
	VOICE $01, 12, 3, 0, 0
	SWEEP $17
	TRANSPOSE_DOWN 3
	ATTEN 2
	OCTAVE 4
	NOTES 2, 3
	ATTEN 0
	NOTES 4, 3
	ATTEN 1
	NOTES 2, 1
	OCTAVE 3
	NOTES $0C, $0B
	ATTEN 2
	NOTES $0A, 9
	NOTE_SKIP 8
	SND_END

SndB5_SfxN:
	NVOICE $81, $0F
	NOISE $6C
	NOISE_VOL $0F
	NOISE $7F
	NOISE_VOL 6
	NOISE $47
	NOISE $37
	NOISE_VOL $0A
	NOISE $14
	NOISE_VOL 8
	NOISE $16
	NOISE $24
	NOISE_VOL 5
	NOISE $27
	NOISE $34
	NOISE_VOL 3
	NOISE $37
	NOISE_VOL 2
	NOISE $44
	NOISE $45
	SND_END

SndB6_Sfx1:
	VOICE $0C, 4, 7, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $16
	OCTAVE 3
	NOTES $0A, $0C
	NOTES 3, 1
	NOTE_SKIP $0D
	OCTAVE 2
	NOTES 4, 1
	NOTES 9, $0D
	SND_END

SndB6_SfxN:
	LEN_UNIT $0C
	NOISE_VOLNOTE 0
	NVOICE $81, $06
	NOISE $55
	NOISE $45
	NOISE $24
	NOISE $27
	NOISE $34
	NVOICE $86, $16
	NOISE $35
	SND_END

SndB7_Sfx1:
	VOICE $0E, 4, 6, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $1D
	OCTAVE 2
	NOTES 4, 7
	OCTAVE 3
	NOTES 1, 4
	NOTE_SKIP $0D
	DUTY 8
	OCTAVE 4
	NOTES 6, 3
	NOTES 5, 2
	SND_END

SndB7_SfxN:
	LEN_UNIT $0E
	NOISE_VOLNOTE 0
	NVOICE $81, $07
	NOISE $55
	NOISE $45
	NOISE $24
	NOISE $27
	NOISE $34
	NVOICE $86, $16
	NOISE $35
	SND_END

SndB8_Sfx1:
	VOICE $0C, 8, 6, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $16
	LOOP_START
	SND_CALL SndB8_Sfx1_72E2
	LOOP_END 2
	SND_END
SndB8_Sfx1_72E2:
	OCTAVE 3
	NOTES 7, $0A
	NOTE_SKIP $0D
	OCTAVE 4
	NOTES 9, 3
	OCTAVE 3
	NOTES $0A, 7
	OCTAVE 2
	NOTES $0A, 4
	LEN_UNIT $17
	NOTE_UNIT 0, $01
	SND_RET

SndB8_SfxN:
	LEN_UNIT $0C
	NOISE_VOLNOTE 0
	LOOP_START
	SND_CALL SndB8_SfxN_72FA
	LOOP_END 2
	SND_END
SndB8_SfxN_72FA:
	NVOICE $81, $0F
	NOISE $55
	NOISE $45
	NOISE $24
	NOISE $26
	NOISE $34
	NVOICE $87, $1C
	NOISE $35
	NVOICE $83, $93
	NOISE $14
	NVOICE $81, $03
	NOISE $17
	NOISE $25
	LEN_UNIT $02
	NOISE $7F
	NOISE_VOLNOTE 7
	NOISE $4F
	NOISE_VOLNOTE 4
	NOISE_VOLNOTE 2
	SND_RET

SndB9_Sfx1:
	VOICE $05, 8, 4, 0, 0
	NOTE_UNIT 0, $02
	SWEEP $16
	SND_CALL SndB1_Sfx1_71F9
	SND_END

SndB9_SfxN:
	NVOICE $85, $91
	NOISE $36
	NVOICE $82, $0B
	NOISE $26
	NOISE $34
	NVOICE $87, $24
	NOISE $16
	NVOICE $94, $A0
	NOISE $14
	NVOICE $81, $0A
	LOOP_START
	NOISE $4F
	NOISE $6C
	NOISE $14
	NOISE_VOL 3
	LOOP_END 2
	SND_END

SndBA_Sfx1:
	LEN_UNIT $06
	NOTE_SKIP 0
	SND_JUMP SndB8_Sfx1

SndBA_SfxN:
	LEN_UNIT $06
	NOISE_VOLNOTE 0
	SND_JUMP SndB8_SfxN

SndBB_Sfx1:
	SND_CALL SndBB_Sfx1_734F
	SND_END
SndBB_Sfx1_734F:
	VOICE $03, 8, 11, 0, 0
	SWEEP $2A
	OCTAVE 3
	NOTE_SKIP $0A
	ATTEN 5
	OCTAVE 2
	NOTE_SKIP $0A
	ATTEN 7
	NOTE_SKIP 9
	SND_RET

SndBB_SfxN:
	SND_CALL SndBB_SfxN_7361
	SND_END
SndBB_SfxN_7361:
	NVOICE $82, $0F
	NOISE $37
	NOISE $25
	NOISE $43
	NOISE_VOL 5
	NOISE $17
	NOISE $16
	SND_RET

SndBC_Sfx1:
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_DOWN 4
	OCTAVE 2
	NOTES 3, $0C
	NOTE_SKIP 9
	ATTEN 7
	LOOP_START
	OCTAVE 2
	NOTES 3, $0C
	NOTE_SKIP 9
	LOOP_END 2
	SND_END

SndBC_SfxN:
	NVOICE $81, $0F
	NOISE $2E
	NOISE $37
	NOISE $44
	NOISE_VOLNOTE $0E
	NOISE_VOLNOTE 8
	NOISE $46
	NOISE_VOLNOTE 6
	NOISE_VOLNOTE $0A
	NOISE $44
	NOISE $36
	NOISE $34
	SND_END

SndBD_Sfx1:
	VOICE $01, 4, 12, 0, 0
	VIBRATO_SEMI 2
	OCTAVE 1
	NOTE_UNIT 1, $01
	SWEEP $14
	VIBRATO_OFF
	NOTES 2, 3
	NOTES 6, 7
	NOTES 8, 9
	NOTES $0A, $0B
	OCTAVE 3
	NOTE_SKIP 8
	SND_END

SndBD_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $3E
	LEN_UNIT $01
	NOISE $37
	NOISE $44
	NOISE_VOLNOTE $0E
	NOISE_VOLNOTE 8
	NOISE $46
	NOISE_VOLNOTE 6
	NOISE_VOLNOTE $0A
	NOISE $44
	NOISE $36
	NOISE $34
	LOOP_START
	NOISE $24
	NOISE $14
	NOISE $04
	NOISE_VOL 2
	LOOP_END 3
	SND_END

SndBE_Sfx1:
	VOICE $01, 4, 1, 0, 0
	NOTES 0, 0
	OCTAVE 4
	NOTE_SKIP 9
	OCTAVE 3
	NOTE_SKIP 3
	SND_END

SndBE_SfxN:
	NVOICE $81, $0F
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	NOISE $4E
	NOISE $05
	NOISE_VOLNOTE 4
	NOISE $34
	NOISE_VOLNOTE $0F
	NOISE_VOLNOTE 2
	SND_END

SndBF_Sfx1:
	VOICE $01, 4, 5, 0, 0
	LOOP_START
	OCTAVE 3
	NOTE_SKIP $0A
	OCTAVE 2
	NOTES 4, 1
	OCTAVE 1
	NOTES 8, 6
	NOTES 8, 6
	ATTEN 7
	NOTES 0, 0
	VOLUME $03
	OCTAVE 2
	NOTES 4, 1
	OCTAVE 1
	NOTES 8, 6
	NOTES 8, 6
	SND_END

SndBF_SfxN:
	NVOICE $82, $05
	NOISE $3E
	LEN_UNIT $01
	NOISE $26
	NOISE $27
	NOISE_VOLNOTE 2
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $25
	NOISE_VOLNOTE 0
	NOISE_VOL 1
	NOISE $26
	NOISE $27
	NOISE_VOLNOTE 1
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $25
	SND_END

SndC0_Sfx1:
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_DOWN 4
	OCTAVE 1
	NOTES $0C, $0A
	OCTAVE 2
	NOTE_SKIP 6
	ATTEN 4
	LOOP_START
	OCTAVE 2
	NOTES 3, $0C
	NOTE_SKIP 9
	VOLUME $02
	LOOP_END 3
	SND_END

SndC0_SfxN:
	NVOICE $82, $0F
	NOISE $4E
	NOISE $27
	NOISE $46
	NOISE_VOL 8
	NOISE $17
	NVOICE $81, $03
	NOISE $57
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $34
	NOISE $26
	NOISE $17
	NOISE $15
	NOISE $07
	NOISE $04
	NOISE $01
	NOISE_VOL 1
	NOISE $57
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $34
	NOISE $26
	NOISE $17
	SND_END

SndC1_Sfx1:
	SND_CALL SndBB_Sfx1_734F
	SND_END
SndC2_Sfx1_7434:
	VOICE $01, 4, 9, 0, 0
	LOOP_START
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 4
	NOTE_SKIP 1
	VOLUME $03
	LOOP_END 2
	ATTEN 1
	LOOP_START
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 4
	NOTE_SKIP 1
	ATTEN 2
	LOOP_END 2
	SND_RET

SndC1_SfxN:
	SND_CALL SndBB_SfxN_7361
	SND_CALL SndC1_SfxN_7496
	SND_END
SndC2_SfxN_745C:
	NVOICE $82, $0F
	NOISE $7F
	NOISE $6D
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	LOOP_START
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $26
	LEN_UNIT $01
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	LEN_UNIT $02
	NOISE_VOL 2
	LOOP_END 2
	LOOP_START
	NOISE_VOL 1
	LEN_UNIT $02
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	LEN_UNIT $01
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	LOOP_END 2
	SND_RET
SndC1_SfxN_7496:
	NVOICE $82, $0F
	LOOP_START
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $36
	NOISE $35
	LEN_UNIT $01
	NOISE $26
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE $14
	LEN_UNIT $05
	NOISE_VOLNOTE 0
	LEN_UNIT $02
	NOISE_VOL 5
	LOOP_END 2
	LEN_UNIT $02
	NOISE_VOL 4
	LOOP_START
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	LEN_UNIT $01
	NOISE $26
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE $14
	LEN_UNIT $05
	NOISE_VOLNOTE 0
	LEN_UNIT $02
	NOISE_VOL 1
	LOOP_END 2
	SND_RET

SndA7_Ch1:
	SND_END

SndC2_Sfx1:
	TRANSPOSE_DOWN 5
	SND_CALL SndC2_Sfx1_7C38
	NOTES 0, 0
	NOTES 0, 0
	TRANSPOSE_DOWN 0
	SWEEP $14
	SND_CALL SndC2_Sfx1_7434
	SND_END

SndC2_SfxN:
	SND_CALL SndC2_SfxN_7C59
	SND_CALL SndC2_SfxN_745C
	SND_END

SndC3_Sfx1:
	VOICE $06, 4, 15, 0, 0
	SWEEP $1D
	NOTE_UNIT 0, $01
	OCTAVE 2
	NOTES 4, 5
	NOTES 6, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	LOOP_START
	DUTY $0C
	OCTAVE 3
	NOTES 1, 3
	NOTES 5, 7
	OCTAVE 2
	VOLUME $02
	LOOP_END 4
	SND_END

SndC3_SfxN:
	NVOICE $82, $0F
	NOISE $26
	NOISE $5C
	LEN_UNIT $01
	NOISE $7F
	NOISE $6D
	NOISE $6C
	LEN_UNIT $02
	LOOP_START
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE_VOL 2
	LOOP_END 3
	SND_CALL SndC2_SfxN_745C
	SND_END

SndC4_SfxN:
	NVOICE $82, $0F
	NOISE $6C
	NOISE $7F
	LEN_UNIT $01
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	LOOP_START
	NOISE $15
	NOISE $14
	NOISE_VOL 2
	LOOP_END 4
	SND_CALL SndC4_SfxN_7CBB
	SND_CALL SndC4_SfxN_7CCF
	SND_CALL SndC2_SfxN_745C
	SND_END

SndC5_Sfx1:
	VOICE $01, 4, 15, 0, 0
	LOOP_START
	OCTAVE 3
	NOTE_SKIP 5
	OCTAVE 1
	NOTES $0C, 8
	NOTES 3, 1
	NOTES 3, 1
	NOTES 4, 2
	ATTEN 7
	NOTES 0, 0
	LOOP_END 2
	VOLUME $03
	OCTAVE 1
	NOTES $0C, 8
	NOTES 3, 1
	NOTES 3, 1
	NOTES 4, 2
	ATTEN 7
	SND_END

SndC5_SfxN:
	NVOICE $82, $0F
	NOISE $3E
	LEN_UNIT $01
	NOISE $46
	NOISE $47
	NOISE_VOLNOTE 4
	NOISE $55
	NOISE $57
	NOISE $45
	NOISE $6C
	NOISE $7F
	NOISE_VOLNOTE 0
	NOISE_VOL 5
	LEN_UNIT $02
	NOISE $3E
	LEN_UNIT $01
	NOISE $46
	NOISE $47
	NOISE_VOLNOTE 1
	NOISE $55
	NOISE $57
	NOISE $45
	NOISE $6C
	NOISE $7F
	NOISE_VOLNOTE 0
	NOISE_VOL 3
	LEN_UNIT $02
	NOISE $2E
	LEN_UNIT $01
	NOISE $46
	NOISE $47
	NOISE_VOLNOTE 1
	NOISE $55
	NOISE $57
	NOISE $45
	NOISE $57
	NOISE $6C
	NOISE $7F
	SND_END

SndC6_Sfx1:
	VOICE $01, 4, 7, 0, 0
	OCTAVE 1
	NOTES 3, 4
	NOTES 0, 0
SndC6_Sfx1_7592:
	VOLUME $04
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	SND_END

SndC6_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $55
	NOISE $6C
	NOISE_VOL 4
	NOISE $24
	NVOICE $87, $97
	NOISE $24
	NVOICE $82, $0A
	NOISE $34
	NOISE_VOL 7
	NOISE $26
	NOISE_VOL 4
	NOISE $24
	NOISE_VOL 3
	NOISE $16
	NOISE_VOL 1
	NOISE $06
	SND_END

SndC7_Sfx1:
	VOICE $05, 8, 10, 0, 0
	SWEEP $16
	NOTE_UNIT 0, $01
SndC7_Sfx1_75BC:
	OCTAVE 3
	NOTES 7, $0A
	NOTE_SKIP $0D
	OCTAVE 4
	NOTES 9, 5
	NOTE_SKIP 2
	OCTAVE 3
	NOTES $0A, 7
	OCTAVE 2
	NOTES $0A, 7
	NOTE_SKIP 4
	SND_END

SndC7_SfxN:
	LEN_UNIT $05
	NOISE_VOLNOTE 0
	NVOICE $81, $0F
	NOISE $55
	NOISE $45
	NOISE $24
	NOISE $26
	NOISE $27
	NOISE $34
	NVOICE $88, $1C
	NOISE $35
	SND_END

SndC8_Sfx1:
	VOICE $01, 4, 15, 0, 0
	AUTOPAN 0
	OCTAVE 1
	NOTES 7, 4
	NOTES 6, 3
	VOICE $01, 12, 15, 0, 0
	SWEEP $15
	ATTEN 3
	TRANSPOSE_UP 1
	SND_CALL SndC8_Sfx1_7A53
	SND_END

SndC8_SfxN:
	SND_CALL SndC8_SfxN_7AB3
SndC8_SfxN_75F2:
	NVOICE $84, $0F
	NOISE $7F
	NOISE $6E
	LEN_UNIT $02
	NOISE $6D
	NOISE $6C
	NOISE $57
	NOISE $56
	LEN_UNIT $01
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE_VOL 7
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE_VOL 5
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE_VOL 4
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE_VOL 3
	NOISE $26
	NOISE $34
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	NOISE $56
	NOISE_VOL 2
	SND_END

; Orphan SfxN stream (no header points here).
B15_Data_7628:
	LOOP_START
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE_VOL 1
	LOOP_END 3
	SND_END

SndC9_Sfx1:
	SND_CALL SndC9_Sfx1_7636
	SND_END
SndC9_Sfx1_7636:
	VOICE $02, 4, 8, 0, 0
	ATTEN 2
	OCTAVE 1
	LOOP_START
	NOTES 1, 7
	NOTE_SKIP $0B
	ATTEN 0
	LOOP_END 2
	SND_RET

SndC9_SfxN:
	SND_CALL SndC9_SfxN_7647
	SND_END
SndC9_SfxN_7647:
	NVOICE $82, $08
	NOISE $4D
	LEN_UNIT $01
	NOISE $37
	NOISE_VOL 6
	NOISE $7F
	NOISE_VOL 4
	NOISE $54
	NOISE $1F
	LEN_UNIT $02
	NOISE $4D
	LEN_UNIT $03
	NOISE_VOLNOTE 0
	LEN_UNIT $02
	NOISE_VOL $0F
	NOISE $3E
	LEN_UNIT $01
	NOISE $37
	NOISE $7F
	NOISE_VOL 5
	NOISE $54
	NOISE $1F
	SND_RET

SndCA_Sfx1:
	VOICE $01, 8, 8, 0, 0
	SWEEP $16
	OCTAVE 3
	NOTES 7, $0A
	NOTE_SKIP $0D
	OCTAVE 4
	NOTES 9, 5
	OCTAVE 3
	NOTES $0A, 7
	OCTAVE 2
	NOTES $0A, 7
	SND_END

SndCA_SfxN:
	NVOICE $81, $0F
	NOISE $55
	NOISE $45
	NOISE $24
	NOISE $27
	NOISE $34
	NVOICE $86, $1C
	NOISE $35
	SND_END

SndCB_Sfx1:
	VOICE $01, 8, 10, 0, 0
	SWEEP $16
	OCTAVE 3
	NOTES 5, 8
	NOTE_SKIP $0D
	OCTAVE 4
	NOTES 7, 3
	OCTAVE 3
	NOTES 8, 4
	OCTAVE 2
	NOTES 8, 4
	NOTES 7, 3
	SND_END

SndCB_SfxN:
	NVOICE $81, $0F
	NOISE $57
	NOISE $47
	NOISE $26
	NOISE $34
	NOISE $36
	NVOICE $86, $1C
	NOISE $37
	NOISE $34
	NVOICE $84, $59
	NOISE $25
	SND_END

SndCC_Sfx1:
	VOICE $05, 8, 5, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $16
	TRANSPOSE_UP 7
	SND_JUMP SndC7_Sfx1_75BC

SndCC_SfxN:
	SND_JUMP SndC7_SfxN

SndCD_Sfx1:
	VOICE $01, 4, 9, 0, 0
	SWEEP $15
	LOOP_START
	OCTAVE 2
	NOTES 1, 4
	NOTE_SKIP 7
	LOOP_END 3
	DUTY 8
	SWEEP $14
	VOLUME $03
	OCTAVE 3
	NOTES 1, 3
	NOTES 2, 4
	NOTES 3, 5
	NOTES 4, 6
	NOTES 5, 7
	NOTES 6, 8
	NOTE_SKIP 7
	LEN_UNIT $04
	NOTE_SKIP 0
	SND_JUMP SndB7_Sfx1

SndCD_SfxN:
	NVOICE $82, $0F
	NOISE $4E
	NVOICE $81, $05
	NOISE $55
	NVOICE $82, $06
	NOISE $4E
	NVOICE $81, $03
	NOISE $55
	NVOICE $82, $04
	NOISE $4E
	NVOICE $81, $02
	NOISE $55
	NVOICE $8A, $B1
	NOISE $24
	NVOICE $81, $08
	NOISE $26
	NOISE $34
	NOISE $36
	LEN_UNIT $04
	NOISE_VOLNOTE 0
	SND_JUMP SndB7_SfxN

SndCE_Sfx1:
	VOICE $0C, 4, 3, 0, 0
	NOTE_UNIT 0, $01
	OCTAVE 1
	NOTES 3, 4
	NOTES 0, 0
	SND_JUMP SndC6_Sfx1_7592
	db $FF ; unreachable

SndCE_SfxN:
	LEN_UNIT $0C
	NOISE_VOLNOTE 0
	SND_JUMP SndC6_SfxN

SndCF_Sfx1:
	VOICE $01, 4, 9, 0, 0
	SWEEP $1D
	TRANSPOSE_DOWN 6
	OCTAVE 3
	NOTES 8, 2
	NOTE_SKIP 3
	SND_END

SndCF_SfxN:
	NVOICE $81, $0F
	NOISE $27
	NOISE $5C
	NOISE $7F
	NVOICE $81, $95
	NOISE $37
	NOISE $35
	NOISE $34
	NOISE $4F
	NOISE $55
	NOISE $6D
	LEN_UNIT $08
	NOISE_VOLNOTE 0
	NOISE_VOL 9
	LEN_UNIT $02
	NOISE $4E
	NOISE $5C
	NVOICE $81, $0A
	NOISE $4E
	NOISE $55
	NOISE $47
	NOISE $46
	NOISE $45
	LOOP_START
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE_VOL 3
	LOOP_END 2
	SND_END

SndD0_Sfx1:
	VOICE $15, 0, 0, 0, 0
	NOTE_SKIP 0
	SND_CALL SndD0_Sfx1_7756
	SND_END
SndD0_Sfx1_7756:
	VOICE $06, 0, 15, 0, 0
	SWEEP $15
	NOTE_UNIT 0, $01
	OCTAVE 2
	NOTES 4, 5
	NOTES 6, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	LOOP_START
	DUTY 4
	OCTAVE 3
	NOTES 1, 3
	NOTES 5, 7
	OCTAVE 2
	VOLUME $02
	LOOP_END 4
	SND_RET

SndD0_SfxN:
	NVOICE $82, $0F
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	LOOP_START
	LEN_UNIT $01
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE_VOL 2
	LOOP_END 3
	SND_JUMP SndC8_SfxN_75F2

SndD1_Sfx1:
	SND_CALL SndC9_Sfx1_7636
	LEN_UNIT $0A
	NOTE_SKIP 0
	TRANSPOSE_UP 3
	SND_CALL SndD0_Sfx1_7756
	SND_END

SndD1_SfxN:
	NVOICE $82, $08
	NOISE $4D
	LEN_UNIT $02
	NOISE $37
	NOISE_VOL 6
	NOISE $7F
	NOISE_VOL 4
	NOISE $54
	NOISE $1F
	NOISE $4D
	NOISE_VOLNOTE 0
	LEN_UNIT $01
	NOISE_VOL $0F
	NOISE $3E
	NOISE $37
	NOISE $7F
	NOISE_VOL 5
	NOISE $54
	NOISE $1F
	NVOICE $83, $B3
	NOISE $54
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $27
	NVOICE $81, $3F
	SND_CALL SndD1_SfxN_77CA
	LOOP_START
	NOISE_VOL 5
	LOOP_END 2
	NOISE_VOL 3
	SND_CALL SndD1_SfxN_77CA
	NOISE_VOL 2
	LOOP_START
	NOISE_VOL 1
	SND_END
SndD1_SfxN_77CA:
	NOISE $6C
	NOISE $4F
	NOISE $55
	NOISE $27
	NOISE $37
	NOISE $35
	NOISE $26
	NOISE $24
	NOISE_VOL 5
	SND_RET

SndD2_Sfx1:
	VOICE $01, 4, 9, 0, 0
	SWEEP $1D
	OCTAVE 1
	NOTES 7, 6
	NOTES 5, 4
	ATTEN 5
	NOTES 3, 2
	ATTEN 7
	NOTES 1, 7
	NOTE_SKIP 6
	LEN_UNIT $08
	NOTE_SKIP 0
	LOOP_START
	VOICE $01, 4, 12, 0, 0
	VIBRATO_SEMI 2
	OCTAVE 1
	NOTE_SKIP 1
	SWEEP $14
	VIBRATO_OFF
	NOTES 2, 3
	NOTES 6, 7
	NOTES 8, 9
	NOTES $0A, $0B
	OCTAVE 3
	NOTE_UNIT 8, $05
	NOTE_SKIP 0
	LOOP_END 2
	SND_END

SndD2_SfxN:
	NVOICE $82, $0F
	NOISE $4E
	NVOICE $81, $05
	NOISE $55
	NVOICE $82, $06
	NOISE $4E
	NVOICE $81, $03
	NOISE $55
	NVOICE $82, $04
	NOISE $4E
	NVOICE $81, $02
	NOISE $55
	LEN_UNIT $08
	NOISE_VOLNOTE 0
	LOOP_START
	NVOICE $81, $0F
	NOISE $4E
	NOISE $3E
	NOISE $37
	NOISE $44
	NOISE_VOLNOTE $0E
	NOISE_VOLNOTE 8
	NOISE $46
	NOISE_VOLNOTE 6
	NOISE_VOLNOTE $0A
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $24
	NOISE $14
	NOISE $04
	LOOP_END 2
	NVOICE $88, $D0
	NVOICE $82, $0A
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $23
	NOISE_VOL 7
	LEN_UNIT $01
	LOOP_START
	NOISE $27
	NOISE $25
	NOISE $24
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE_VOL 2
	LOOP_END 3
	SND_END

SndD3_Sfx1:
	VOICE $01, 4, 10, 0, 0
	SWEEP $1F
	OCTAVE 2
	NOTES 4, 7
	OCTAVE 3
	NOTES 1, 4
	NOTE_SKIP $0D
	DUTY 8
	OCTAVE 4
	NOTES 6, 3
	NOTES 5, 2
	SND_END

SndD3_SfxN:
	NVOICE $82, $A5
	NOISE $34
	NOISE_VOL $0A
	NOISE $16
	NOISE $25
	NOISE $14
	NOISE $06
	SND_END

SndD4_Sfx1:
	VOICE $01, 4, 10, 0, 0
	SWEEP $1D
	OCTAVE 2
	LOOP_START
	NOTES 3, 5
	NOTES $0A, 8
	OCTAVE 3
	LOOP_END 2
	OCTAVE 2
	NOTES 3, 5
	NOTES $0A, 8
	VOICE $01, 4, 1, 0, 0
	PAN_RIGHT 0
	OCTAVE 1
	NOTES 2, 4
	NOTE_SKIP 2
	PAN_BOTH 0
	LEN_UNIT $09
	NOTES 0, 0
	LEN_UNIT $01
	VOICE $01, 4, 4, 0, 0
	SWEEP $17
	LOOP_START
	SND_CALL SndD4_Sfx1_78AC
	SND_JUMP_N 4, SndD4_Sfx1_789D
	LEN_UNIT $08
	NOTE_UNIT 0, $01
	VOLUME $01
SndD4_Sfx1_789D:
	LOOP_END 4
	LOOP_START
	LEN_UNIT $06
	NOTE_UNIT 0, $01
	VOLUME $04
	SND_CALL SndD4_Sfx1_78AC
	LOOP_END 2
	SND_END
SndD4_Sfx1_78AC:
	OCTAVE 2
	NOTES 1, 4
	NOTE_SKIP $0B
	OCTAVE 3
	NOTES 3, $0D
	DUTY 8
	OCTAVE 4
	NOTES 4, 1
	NOTE_SKIP 3
	OCTAVE 3
	NOTE_SKIP $0B
	OCTAVE 4
	NOTE_SKIP 1
	SND_RET

SndD4_SfxN:
	NVOICE $81, $93
	NOISE $6D
	NOISE $57
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE $14
	LEN_UNIT $09
	NOISE_VOLNOTE 0
	NVOICE $81, $0F
	NOISE $2F
	NOISE $7F
	NOISE_VOLNOTE 3
	NOISE $44
	NOISE $25
	NOISE $17
	NVOICE $86, $1C
	NOISE $14
	NVOICE $81, $0F
	LOOP_START
	SND_CALL SndD4_SfxN_78FA
	SND_JUMP_N 4, SndD4_SfxN_78EB
	LEN_UNIT $08
	NOISE_VOLNOTE 0
	NVOICE $81, $08
SndD4_SfxN_78EB:
	LOOP_END 4
	LOOP_START
	LEN_UNIT $06
	NOISE_VOLNOTE 0
	NVOICE $81, $0B
	SND_CALL SndD4_SfxN_78FA
	LOOP_END 2
	SND_END
SndD4_SfxN_78FA:
	NOISE $7F
	NOISE $6D
	NOISE $55
	NOISE $45
	NOISE $26
	NVOICE $85, $14
	NOISE $26
	SND_RET

SndD5_Sfx1:
	SND_CALL SndAE_Sfx1_71A3

; Orphan Sfx1 stream (no header points here).
B15_Data_7907:
	SND_CALL B15_Data_791F
	PAN_LEFT 0
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	PAN_BOTH 0
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	PAN_RIGHT 0
	NOTES $0B, $0C
	OCTAVE 4
	NOTES 1, 2
	NOTE_SKIP 3
	PAN_BOTH 0
	SND_JUMP SndDB_Sfx1
B15_Data_791F:
	VOICE $12, 4, 15, 0, 0
	PAN_BOTH 0
	NOTE_UNIT 0, $01
	SWEEP $14
	TRANSPOSE_DOWN 4
	SND_RET

SndD5_SfxN:
	SND_CALL SndAE_SfxN_71B2
	NVOICE $90, $B0
	NOISE $24
	NVOICE $81, $0F
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $34
	NOISE $35
	PAN_RIGHT 0
	NOISE $36
	NOISE $44
	NOISE $46
	NOISE $54
	PAN_BOTH 0
	LOOP_START
	NOISE_VOL 3
	NOISE $37
	NOISE $45
	NOISE $47
	NOISE $55
	PAN_LEFT 0
	LOOP_END 2
	SND_END

SndD6_Sfx1:
	VOICE $01, 0, 15, 0, 0
	TRANSPOSE_DOWN 2
	OCTAVE 1
	NOTES 3, 6
	NOTES 4, 7
	NOTES 5, 8
	NOTES 6, 9
	NOTES 7, $0A
	TRANSPOSE_DOWN 3
	SND_JUMP SndDC_Sfx1

SndD6_SfxN:
	NVOICE $81, $0F
	NOISE $4E
	NOISE $6C
	NOISE $7F
	NOISE_VOL 8
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE_VOL 5
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE_VOL 2
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NVOICE $82, $0F
	NOISE $27
	NOISE $56
	NOISE $4E
	NOISE $6D
	NOISE $55
	NOISE $47
	LOOP_START
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE_VOL 2
	LOOP_END 3
	SND_END

SndD7_Sfx1:
	VOICE $22, 4, 15, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $14
	LOOP_START
	AUTOPAN 0
	OCTAVE 1
	NOTES 2, 5
	NOTES 8, 2
	NOTES 5, 8
	PAN_BOTH 0
	OCTAVE 2
	LOOP_END 2
	SND_END

SndD7_SfxN:
	NVOICE $8F, $0F
	NOISE_VOLNOTE 0
	NVOICE $82, $0F
	NOISE $4E
	NOISE_VOL 3
	NOISE $36
	NOISE $45
	NOISE $46
	NVOICE $8A, $90
	NOISE $6D
	NVOICE $81, $0F
	NOISE $4F
	NOISE $6C
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE $0F
	NOISE $27
	NOISE $24
	NOISE $6C
	NOISE $7C
	NVOICE $81, $0F
	NOISE $37
	NOISE $36
	NOISE $35
	LOOP_START
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	LEN_UNIT $02
	NOISE $16
	NOISE $15
	LEN_UNIT $01
	NOISE_VOL 3
	LOOP_END 2
	NOISE_VOL 1
	NOISE $34
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $17
	LEN_UNIT $02
	NOISE $16
	NOISE $15
	SND_END

SndD8_Sfx1:
	NVOICE $82, $4F
	NOTES 0, 0
	OCTAVE 1
	NOTES 1, 4
	NOTES 3, 7
	NOTES 5, 9
	NOTES 8, $0C
	NOTES 9, $0C
	SND_END

SndD8_SfxN:
	NVOICE $82, $0F
	NOISE $4E
	NOISE $7F
	LEN_UNIT $01
	NOISE_VOL $0A
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $6C
	NOISE_VOL 3
	NOISE $55
	NOISE $54
	NOISE $53
	LEN_UNIT $04
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	NOISE $47
	NOISE $45
	NOISE $36
	NOISE $34
	NOISE $27
	NVOICE $81, $0F
	LOOP_START
	NOISE $4F
	NOISE $57
	NOISE $55
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE $07
	NOISE $05
	NOISE_VOL 2
	LOOP_END 2
	SND_END

SndD9_Sfx1:
	VOICE $02, 4, 15, 0, 0
	OCTAVE 1
	NOTES 4, 8
	NOTES 2, 7
	ATTEN 7
	NOTES 2, 5
	SND_END

SndD9_SfxN:
	NVOICE $82, $1F
	NOISE $4E
	NOISE $47
	NOISE_VOL $0A
	LEN_UNIT $01
	NOISE $55
	NOISE_VOL 8
	NOISE $47
	NOISE $45
	NVOICE $87, $19
	NOISE $24
	SND_END

SndDA_Sfx1:
	VOICE $01, 12, 15, 0, 0
	SWEEP $15
	ATTEN 3
	SND_CALL SndC8_Sfx1_7A53
	LEN_UNIT $0B
	NOTES 0, 0
	LEN_UNIT $01
	DUTY 8
	ATTEN 3
	OCTAVE 3
	NOTES 4, 9
	NOTES 1, 5
	NOTES $0B, 6
	NOTES $0C, 7
	OCTAVE 3
	NOTES 2, 4
	OCTAVE 2
	NOTES 4, $0B
	OCTAVE 1
	NOTES 8, $0C
	SND_END
SndC8_Sfx1_7A53:
	OCTAVE 3
	NOTES 1, 2
	NOTES 1, 2
	NOTES 1, 2
	NOTES 1, 2
	ATTEN 2
	NOTES 2, 3
	NOTES 3, 4
	ATTEN 1
	LOOP_START
	NOTES 4, 5
	LOOP_END 5
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
	SND_RET

SndDA_SfxN:
	SND_CALL SndDA_SfxN_7A8B
	LEN_UNIT $15
	NOISE_VOLNOTE 0
	PAN_BOTH 0
	NVOICE $81, $0F
	LOOP2_START
	LOOP_START
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	LOOP_END 2
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $6C
	NOISE_VOL 3
	LOOP2_END 3
	SND_END
SndDA_SfxN_7A8B:
	NVOICE $8A, $0A
	NOISE $4E
	NOISE $6C
	NVOICE $84, $07
	AUTOPAN 0
	NOISE $47
	NOISE $55
	NOISE $6C
	SND_RET

SndDB_Sfx1:
	VOICE $01, 4, 15, 0, 0
	AUTOPAN 0
	OCTAVE 1
	NOTES 7, 4
	NOTES 6, 3
	SND_END

SndDB_Sfx2:
	VOICE $02, 5, 2, 0, 0
	NOTE_UNIT 0, $01
	PAN_RIGHT 0
	OCTAVE 2
	NOTES 7, 4
	NOTES 6, 3
	SND_END

SndDB_SfxN:
	SND_CALL SndC8_SfxN_7AB3
	SND_END
SndC8_SfxN_7AB3:
	NVOICE $81, $0F
	NOISE $2E
	NOISE $6C
	NOISE $2F
	NOISE $55
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
	NOISE $6F
	NOISE_VOL 3
	LOOP_END 2
	SND_RET

SndDC_Sfx1:
	VOICE $0C, 0, 15, 0, 0
	SWEEP $15
	NOTE_UNIT 0, $01
	OCTAVE 2
	NOTES 2, 3
	NOTES 4, 6
	NOTES 8, $0A
	NOTES $0B, $0C
	LOOP_START
	DUTY 4
	OCTAVE 3
	NOTES 1, 2
	NOTES 4, 5
	NOTES 6, 7
	NOTES 8, 9
	NOTE_SKIP $0A
	VOLUME $02
	LOOP_END 4
	SND_END

SndDC_SfxN:
	LEN_UNIT $0F
	NOISE_VOLNOTE 0
	NVOICE $89, $0A
	NOISE $4E
	LEN_UNIT $18
	NOISE_VOLNOTE 0
SndDC_SfxN_7AF0:
	NVOICE $81, $0F
	NOISE $24
	NOISE $55
	NOISE $47
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NOISE_VOL $0F
	NOISE $55
	LOOP_START
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $17
	NOISE $15
	NOISE_VOL 2
	LOOP_END 2
	SND_END

SndDD_Sfx1:
	VOICE $06, 4, 7, 0, 0
	NOTE_UNIT 0, $01
	SWEEP $1D
	ATTEN 6
	OCTAVE 3
	NOTES 1, 2
	NOTES 3, 4
	ATTEN 5
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 3
	OCTAVE 4
	NOTES 2, 4
	ATTEN 2
	NOTES 6, 8
	NOTES $0A, $0C
	OCTAVE 5
	ATTEN 1
	ATTEN 0
	NOTES 2, 4
	NOTES 6, 9
	NOTE_SKIP $0B
	OCTAVE 6
	NOTES 1, 3
	NOTES 7, $0A
	NOTES $0B, $0C
	LEN_UNIT $01
	SWEEP $14
	DUTY 4
	OCTAVE 3
	NOTES $0A, 8
	OCTAVE 2
	NOTES 8, 6
	NOTES 5, 3
	SND_END

SndDD_SfxN:
	NVOICE $82, $0F
	NOISE $4E
	NVOICE $81, $05
	NOISE $55
	NVOICE $82, $06
	NOISE $4E
	NVOICE $81, $03
	NOISE $55
	NVOICE $82, $B0
	NOISE $3F
	LEN_UNIT $05
	NOISE $6C
	NOISE $56
	NOISE $54
	LEN_UNIT $03
	NOISE $47
	NOISE $45
	NOISE $37
	LEN_UNIT $01
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $27
	NOISE $25
	SND_JUMP SndDC_SfxN_7AF0

SndDE_Sfx1:
	VOICE $02, 4, 15, 0, 0
	OCTAVE 1
	LOOP_START
	NOTES $0B, 8
	NOTE_SKIP 5
	ATTEN 7
	LOOP_END 2
	SND_END

SndDE_SfxN:
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
	LEN_UNIT $02
	SND_END

SndDF_Sfx1:
	VOICE $02, 4, 15, 0, 0
	OCTAVE 1
	LOOP_START
	NOTES 6, 3
	NOTE_SKIP 1
	ATTEN 7
	LOOP_END 2
	SND_END

SndDF_SfxN:
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
	LEN_UNIT $02
	SND_END

SndE0_Sfx1:
	VOICE $02, 4, 8, 0, 0
	LOOP_START
	OCTAVE 1
	NOTES $0B, 8
	NOTE_SKIP 5
	ATTEN 6
	LOOP_END 2
	SND_END

SndE0_SfxN:
	NVOICE $82, $07
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 4
	NOISE $7F
	NOISE_VOL 3
	NOISE $54
	NOISE $1F
	NOISE_VOL 4
	LEN_UNIT $02
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 1
	NOISE $7F
	NOISE $54
	NOISE $1F
	NOISE_VOL 2
	LEN_UNIT $02
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 1
	NOISE $7F
	NOISE $54
	NOISE $1F
	SND_END

SndE1_Sfx1:
	VOICE $02, 4, 10, 0, 0
	OCTAVE 1
	LOOP_START
	NOTES 5, 2
	NOTE_SKIP 1
	ATTEN 6
	LOOP_END 2
	SND_END

SndE1_SfxN:
	NVOICE $82, $07
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 4
	NOISE $7F
	NOISE_VOL 2
	NOISE $54
	NOISE $1F
	NOISE_VOL 3
	LEN_UNIT $02
	LOOP_START
	NOISE $3E
	LEN_UNIT $01
	NOISE $6C
	NOISE_VOL 1
	NOISE $7F
	NOISE $54
	NOISE $1F
	LEN_UNIT $02
	LOOP_END 2
	SND_END

SndE2_Sfx1:
	VOICE $01, 4, 8, 0, 0
	SWEEP $1D
	OCTAVE 2
	NOTES 8, 1
	OCTAVE 3
	NOTES 1, 8
	NOTES 3, $0D
	OCTAVE 4
	NOTES 8, 1
	NOTES 3, $0A
	SND_END

SndE2_SfxN:
	NVOICE $81, $06
	NOISE $14
	NVOICE $82, $08
	NOISE $55
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	SND_END

SndE3_Sfx1:
	VOICE $03, 8, 0, 0, 0
	NOTE_SKIP 0
	SND_END

SndE3_SfxN:
	NVOICE $82, $93
	NOISE $14
	NVOICE $81, $03
	NOISE $17
	NOISE $25
	LEN_UNIT $02
	NOISE $7F
	NOISE_VOLNOTE 7
	NOISE $4F
	SND_END

SndE4_Sfx1:
	TRANSPOSE_DOWN 6
	SND_CALL SndC2_Sfx1_7C38
	SND_END
SndC2_Sfx1_7C38:
	VOICE $01, 12, 15, 0, 0
	OCTAVE 3
	NOTES 5, 3
	ATTEN 5
	DUTY 4
	SWEEP $15
	NOTES 1, 2
	ATTEN 3
	NOTES 3, 4
	ATTEN 2
	NOTES 5, 6
	ATTEN 1
	NOTES 7, 9
	ATTEN 0
	NOTES $0A, $0B
	LOOP_START
	NOTES $0C, $0A
	NOTES $0C, $0A
	LOOP_END 2
	SND_RET

SndE4_SfxN:
	SND_CALL SndC2_SfxN_7C59
	SND_CALL SndE4_SfxN_7C68
	SND_END
SndC2_SfxN_7C59:
	NVOICE $85, $0F
	NOISE $37
	NVOICE $8A, $03
	NOISE $4E
	NOISE $24
	NVOICE $81, $0A
	NOISE $6C
	NOISE $7F
	SND_RET
SndE4_SfxN_7C68:
	LEN_UNIT $02
	LOOP_START
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	NOISE_VOL 3
	LOOP_END 2
	NOISE_VOL 1
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $17
	NOISE $15
	SND_RET

SndE5_Sfx1:
	VOICE $09, 4, 10, 0, 0
	SWEEP $15
	NOTE_UNIT 0, $01
	SND_CALL SndE5_Sfx1_7C86
	SND_END
SndE5_Sfx1_7C86:
	OCTAVE 2
	NOTES 2, 3
	NOTES 4, 6
	NOTES 8, $0A
	NOTES $0B, $0C
	LOOP_START
	DUTY 4
	OCTAVE 3
	NOTES 8, 7
	NOTES 6, 5
	NOTES 5, 4
	NOTES 3, 2
	NOTES 2, 1
	VOLUME $02
	LOOP_END 2
	SND_RET

SndE6_Sfx1:
	NVOICE $81, $85
	NOTES 0, 0
	AUTOPAN 0
	OCTAVE 1
	NOTES 1, 4
	NOTE_SKIP 2
	SND_END

SndE6_SfxN:
	SND_CALL SndC4_SfxN_7CBB
	SND_CALL SndC4_SfxN_7CCF
	LOOP2_START
	NVOICE $81, $0A
	LOOP_START
	NOISE $44
	NOISE $36
	NOISE $34
	NOISE $26
	NOISE $24
	NOISE $17
	NOISE $15
	NOISE_VOL 2
	LOOP_END 3
	LOOP2_END 2
	SND_END
SndC4_SfxN_7CBB:
	NVOICE $81, $0F
	NOISE $4F
	NOISE $6C
	NOISE_VOL 7
	NOISE $36
	NOISE $6C
	NOISE_TRIG
	NOISE $55
	NOISE $54
	NOISE $47
	NOISE $45
	NOISE $37
	NOISE $35
	NOISE $27
	NOISE $25
	NOISE $24
	NOISE $23
	SND_RET
SndC4_SfxN_7CCF:
	NVOICE $81, $0F
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
	SND_RET

SndE8_Ch2:
	TEMPO $1C
	VOICE $06, 8, 7, 11, 1
	ATTEN 2
	AUTOPAN_BOTH 0
	TRANSPOSE_DOWN 3
	SND_CALL SndE8_Ch1_7D14
	SND_CALL SndE8_Ch1_7D88
	DUTY_STEP 0, 1
	DUTY 4
	SND_CALL SndE8_Ch2_7D30
	SND_SEGNO
	TRANSPOSE_DOWN 0
	SND_CALL SndE8_Ch2_7D30
	TRANSPOSE_UP 3
	SND_CALL SndE8_Ch2_7D30
	TRANSPOSE_UP 6
	SND_CALL SndE8_Ch2_7D30
	TRANSPOSE_DOWN 3
	OCTAVE 4
	SND_CALL SndE8_Ch2_7D30
	SND_LOOP
SndE8_Ch1_7D14:
	REST 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	DUTY 4
	RELEASE $0F, 2
	DUTY_STEP 3, 8
	VIBRATO 10, 0, 4
	RELEASE $0B, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 4
	SND_RET
	db $FD ; unreachable
SndE8_Ch2_7D30:
	NOTE A_, 1
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ATTEN 6
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0F, 3
	ATTEN 5
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 2
	OCTAVE 2
	DUTY_STEP 0, 1
	VIBRATO_SEMI 1
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 1
	LOOP_END 4
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 3
	DUTY_STEP 3, 8
	VIBRATO 10, 0, 4
	RELEASE $0E, 2
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	VIBRATO_OFF
	DUTY_STEP 0, 0
	RELEASE 0, 0
	ATTEN 7
	NOTE A_, 2
	ATTEN 5
	RELEASE $0F, 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 2
	OCTAVE 2
	DUTY_STEP 0, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 1
	ATTEN 1
	VIBRATO 10, 0, 4
	DUTY_STEP 3, 8
	RELEASE $0E, 2
	OCTAVE 3
	NOTE G_, 1
	SND_RET
SndE8_Ch1_7D88:
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	SND_RET

SndE8_Ch1:
	VOICE $06, 8, 6, 11, 1
	ATTEN 3
	AUTOPAN 0
	DETUNE $FE
	TRANSPOSE_DOWN 3
	SND_CALL SndE8_Ch1_7D14
	TRANSPOSE_DOWN 8
	SND_CALL SndE8_Ch1_7D88
	VOICE $06, 4, 6, 0, 0
	DETUNE $00
	TRANSPOSE_DOWN 3
	SND_CALL SndE8_Ch1_7DCD
	SND_SEGNO
	TRANSPOSE_UP 0
	SND_CALL SndE8_Ch1_7DCD
	TRANSPOSE_UP 3
	SND_CALL SndE8_Ch1_7DCD
	TRANSPOSE_UP 6
	SND_CALL SndE8_Ch1_7DCD
	TRANSPOSE_DOWN 3
	OCTAVE 4
	SND_CALL SndE8_Ch1_7DCD
	SND_LOOP
SndE8_Ch1_7DCD:
	ATTEN 2
	NOTE E_, 1
	DUTY_STEP 0, 0
	VIBRATO_OFF
	ATTEN 5
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0F, 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 3
	OCTAVE 2
	DUTY_STEP 0, 1
	DETUNE $06
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 1
	LOOP_END 4
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	DETUNE $00
	ATTEN 2
	DUTY_STEP 3, 8
	VIBRATO 10, 0, 4
	RELEASE $0E, 2
	ATTEN 2
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	VIBRATO_OFF
	DUTY_STEP 0, 0
	RELEASE 0, 0
	ATTEN 5
	NOTE E_, 2
	ATTEN 3
	RELEASE $0F, 3
	NOTE E_, 1
	RELEASE 0, 0
	DETUNE $06
	OCTAVE 2
	DUTY_STEP 0, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 1
	DETUNE $00
	ATTEN 2
	VIBRATO 10, 0, 4
	DUTY_STEP 3, 8
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 1
	SND_RET

SndE8_Ch3:
	VOICE $06, 4, 2, 10, 4
	TRANSPOSE_DOWN 3
	RELEASE_VOL 4
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	WAVE $0F
	RELEASE 9, 4
	VOLUME $04
	RELEASE_VOL 6
	LEN_UNIT $03
	SND_SEGNO
	VIBRATO_SEMI $11
	TRANSPOSE_DOWN 3
	SND_CALL SndE8_Ch3_7E68
	TRANSPOSE_DOWN 0
	SND_CALL SndE8_Ch3_7E68
	TRANSPOSE_UP 3
	SND_CALL SndE8_Ch3_7E68
	TRANSPOSE_UP 6
	SND_CALL SndE8_Ch3_7E68
	SND_LOOP
SndE8_Ch3_7E68:
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 3
	REST 1
	OCTAVE 2
	NOTE E_, 3
	REST 1
	NOTE D_, 3
	REST 1
	NOTE G_, 2
	LOOP_END 6
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	SND_RET

SndE8_Drm:
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 3, 1
	SND_SEGNO
	DRUM 4, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	LOOP_START
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 2
	DRUM $0A, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM 2, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 5, 1
	SND_LOOP

; Unused ($FF) to the end of the bank.
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
