; ==========================================================================
; Zen - Intergalactic Ninja (E) - Konami sound driver (bank 7)
; Byte-exact RGBDS disassembly of the driver code and all sound data. Tiny Toon Adventures'
; reworked third-generation driver, moved to $C0C0 and with a pause, a new fade and 5-byte voices.
;   ROM0: the rst $00/$08/$28 helpers and the bank-7 wrappers
;   bank 7: the driver ($4F16-$5ABE), tables, headers, streams ($5ABF-$7F07)
; Build: rgbasm -Wall -o zen.o ZEN_SoundDriver.asm && rgblink -o zen.gb zen.o
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
DEF wTrkSfx1 EQU $C0C0 ; 64 bytes
DEF wTrkSfx2 EQU $C1C0 ; 64 bytes
DEF wTrkSfxN EQU $C2C0 ; 64 bytes
DEF wTrkCh1 EQU $C3C0 ; 64 bytes
DEF wTrkCh2 EQU $C4C0 ; 64 bytes
DEF wTrkCh3 EQU $C5C0 ; 64 bytes
DEF wTrkDrm EQU $C6C0 ; 64 bytes
DEF wTrackIdx EQU $C7C3
DEF wRegBase EQU $C7C4
DEF wTempo EQU $C7C5
DEF wTempoAcc EQU $C7C6
DEF wTempoSkip EQU $C7C7
DEF wQueuedSnd EQU $C7C8
DEF wNR51 EQU $C7C9
DEF wReg0Val EQU $C7CA
DEF wReqId EQU $C7CB
DEF wReqPrio EQU $C7CC
DEF wRegVal EQU $C7CD
DEF wRegOff EQU $C7CE
DEF wMusicHold EQU $C7CF
DEF wCountdown EQU $C7D0
DEF wFadeReq EQU $C7D1
DEF wFadeTimer EQU $C7D2
DEF wFadeLevel EQU $C7D3
DEF wReqRefused EQU $C7D4
DEF wRegShadow EQU $C7DD ; 21 bytes
DEF wSndLock EQU $DEE5
DEF wPauseFlag EQU $DEEB
DEF rROMB EQU $2180 ; MBC1 bank select (the game writes it here)
DEF BANK_ID EQU $7FFF ; every ROM bank ends with its own number

; per-track fields: track n lives at $C0C0 + n*$100, so H = $C0 + n and L = field
DEF TRK_ID EQU $C0
DEF TRK_PRIO EQU $C1
DEF TRK_PTR EQU $C2
DEF TRK_LEN EQU $C4
DEF TRK_FLAGS EQU $C5
DEF TRK_FLAGS2 EQU $C6
DEF TRK_REPCNT EQU $C7
DEF TRK_VIB EQU $C9
DEF TRK_TRANSP EQU $CA
DEF TRK_ATTEN EQU $CB
DEF TRK_VIBOFS EQU $CC
DEF TRK_VIBREPCNT EQU $CE
DEF TRK_ENVREPCNT EQU $CF
DEF TRK_UNIT EQU $D1
DEF TRK_OCTAVE EQU $D2
DEF TRK_PERIOD EQU $D3
DEF TRK_RAWPERIOD EQU $D5
DEF TRK_VOL EQU $D7
DEF TRK_DUTY EQU $D8
DEF TRK_ENV EQU $D9
DEF TRK_GATE EQU $DA
DEF TRK_RELTICK EQU $DB
DEF TRK_VIBTIMER EQU $DC
DEF TRK_VIBRELOAD EQU $DD
DEF TRK_CH3TIMER EQU $DE
DEF TRK_CH3RELOAD EQU $DF
DEF TRK_LEVEL EQU $E1
DEF TRK_SEGNO EQU $E2
DEF TRK_RET EQU $E6
DEF TRK_VIBPTR EQU $EA
DEF TRK_VIBIDX EQU $EC
DEF TRK_VIBLOOPIDX EQU $ED
DEF TRK_VIBDEPTH EQU $EE
DEF TRK_VIBDELAY EQU $EF
DEF TRK_VIBDELAYRELOAD EQU $F0
DEF TRK_VIBDELAYCNT EQU $F1
DEF TRK_ENVNO EQU $F2
DEF TRK_ENVTIMER EQU $F3
DEF TRK_ENVRELOAD EQU $F4
DEF TRK_ENVVOL EQU $F5
DEF TRK_ENVPTR EQU $F6
DEF TRK_ENVIDX EQU $F8
DEF TRK_ENVLOOPIDX EQU $F9
DEF TRK_DUTYCNT EQU $FA
DEF TRK_DUTYSTART EQU $FB
DEF TRK_DUTYTICKS EQU $FC
DEF TRK_PAN EQU $FD
DEF TRK_OCTSHIFT EQU $FE
DEF TRK_DETUNE EQU $FF

; TRK_FLAGS: 0 released, 1 autopan, 3 vibrato negative, 4 duty step, 6 force register writes, 7 rest
; TRK_FLAGS2: 0 envelope step due, 1 envelope ended, 4/5 raw stream, 7 vibrato delay running
; register writes: offset (wRegOff) 0-4 from wRegBase (00 05 0F 00 05 0A 0F by track), shadow at
; wRegShadow + base + offset

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

; sound header: priority, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; note: hi = pitch 1-12 (0 = rest), lo = length multiplier (x unit; 0 = 256 ticks)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = DrumMap entry 1-12, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: NR43 value (NR44 = 0, no retrigger), length = unit
MACRO NOISE
	db \1
ENDM
; $E0 unit, vol|duty<<4, x, env|gate<<4 (tone tracks; on CH3 duty = wave 1-15). The 4th byte (x) is
; skipped by the reader (always 0 in the data except once)
MACRO VOICE
	db $E0, \1, (\3 << 4) | \2, \6, (\5 << 4) | \4
ENDM
; $E0 unit, vol<<4|env (noise SFX track: written to NR42 + trigger)
MACRO NVOICE
	db $E0, \1, \2
ENDM
; $E0 unit (drum track)
MACRO DRUM_UNIT
	db $E0, \1
ENDM
; $E1-$E6: octave
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release point = length * gate / 16; 15 = one tick before the end), env (NRx2 low nibble)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9 xy: notes start with duty y, the voice duty comes back after x ticks; $E9 0 off
MACRO DUTY_STEP
	db $E9, (\1 << 4) | \2
ENDM
MACRO DUTY_STEP_OFF
	db $E9, $00
ENDM
; $EA xy: octave shift x (OctaveShiftTable: 0-7 up 0-7 octaves, 8 none, 9-15 down 1-7; only with
; OCTAVE > 1), semitones y (negated when x >= 8)
MACRO TRANSPOSE
	db $EA, (\1 << 4) | \2
ENDM
; $EB n, xy: vibrato table n, delay x * unit ticks, depth y
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $EC n: volume envelope table n & 15 (0 = off)
MACRO ENVELOPE
	db $EC, \1
ENDM
MACRO ENVELOPE_OFF
	db $EC, $00
ENDM
; $ED x: detune (+2x, or -2(x & $7F) when bit 7 is set)
MACRO DETUNE
	db $ED, \1
ENDM
MACRO TEMPO
	db $EE, \1
ENDM
; $EF x: no-op
MACRO CMD_EF
	db $EF, \1
ENDM
; $F0-$FA: attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
; $D0-$D8, $DB-$DE x: no-ops
MACRO CMD_D0
	db $D0, \1
ENDM
MACRO CMD_D1
	db $D1, \1
ENDM
MACRO CMD_D2
	db $D2, \1
ENDM
MACRO CMD_D3
	db $D3, \1
ENDM
MACRO CMD_D4
	db $D4, \1
ENDM
MACRO CMD_D5
	db $D5, \1
ENDM
MACRO CMD_D6
	db $D6, \1
ENDM
MACRO CMD_D7
	db $D7, \1
ENDM
MACRO CMD_D8
	db $D8, \1
ENDM
MACRO CMD_DB
	db $DB, \1
ENDM
MACRO CMD_DC
	db $DC, \1
ENDM
MACRO CMD_DD
	db $DD, \1
ENDM
MACRO CMD_DE
	db $DE, \1
ENDM
; $D9 x: register offset 0 of the channel = x (NR10 / NR30)
MACRO REG0
	db $D9, \1
ENDM
; $DA xy: 0 transpose up y, 1 down y, 2 no-op, 3 duty (CH3: wave) y, 4 TRK_FLAGS = y (| 2 = autopan)
MACRO TRANSPOSE_UP
	db $DA, $00 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $DA, $10 | \1
ENDM
MACRO EXT_NOP
	db $DA, $20 | \1
ENDM
MACRO DUTY
	db $DA, $30 | \1
ENDM
MACRO WAVE
	db $DA, $30 | \1
ENDM
MACRO FLAGS
	db $DA, $40 | \1
ENDM
; $DF x: this channel's NR51 bits from x
MACRO PAN
	db $DF, \1
ENDM
; $DF x on the drum track: skips one more byte
MACRO PAN_DRUM
	db $DF, \1, \2
ENDM
MACRO SND_SEGNO
	db $FB
ENDM
MACRO SND_RET
	db $FC
ENDM
MACRO SND_CALL
	db $FD
	dw \1
ENDM
; $FE n: back to the segno until the n-th pass
MACRO SND_REPEAT
	db $FE, \1
ENDM
MACRO SND_JUMP
	db $FE, $FF
	dw \1
ENDM
MACRO SND_END
	db $FF
ENDM
; raw streams (first byte $01): header, then 2-byte frames NRx2 = vol << 4, period (one unit each)
MACRO RAW_HEADER
	db $01, \1, \2, \3
ENDM
MACRO RAW_NOTE
	db (\1 << 4) | HIGH(\2), LOW(\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; vibrato tables: time << 4 | negative << 3 | offset (x depth); $FB loop point, $FE n repeat ($FF: forever),
; $FF hold
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
ENDM
MACRO VIB_SEGNO
	db $FB
ENDM
MACRO VIB_REPEAT
	db $FE, \1
ENDM
MACRO VIB_END
	db $FF
ENDM
; envelope tables: time << 4 | volume; $FB loop point, $FE n repeat ($FF: forever), $FF end
MACRO ENV_STEP
	db (\1 << 4) | \2
ENDM
MACRO ENV_SEGNO
	db $FB
ENDM
MACRO ENV_REPEAT
	db $FE, \1
ENDM
MACRO ENV_END
	db $FF
ENDM

SECTION "rst00", ROM0[$0000]

; rst $00 / rst $08 / rst $28: the game's helpers the driver uses. rst $00 after a
; `push hl` = jump through the inline word table that follows (index A); rst $08 = HL +=
; 2 * A (with the carry of add a,a), HL = [HL]; rst $28 = HL += A.
JumpTableInline:
	pop hl
	rst $08
	jp hl

SECTION "rst08", ROM0[$0008]

LoadPtrIndexed:
	add a, a
	jr LoadPtrCarry

LoadPtr:
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

LoadPtrCarry:
	jr nc, LoadPtr
	inc h
	jr LoadPtr

SECTION "rst28", ROM0[$0028]

AddHLA:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "Sound ROM0", ROM0[$0318]

; SndUpdateFar (called from every VBlank): skipped while wSndLock bit 0 is set (a request
; in progress), else lock, map bank 7, SndUpdate, unlock and map back the bank the caller had
; (each bank holds its own number at $7FFF).
SndUpdateFar:
	push hl
	ld hl, wSndLock
	bit 0, [hl]
	jr nz, FarReturn
	set 0, [hl]
	ld a, [BANK_ID]
	push af
	ld a, $07
	ld [rROMB], a
	call SndUpdate
.l032E:
	ld hl, wSndLock
	res 0, [hl]
	pop af
	ld [rROMB], a

FarReturn:
	pop hl
	ret

; PlaySoundFar: A = sound id (0 = StopAll); dropped while wSndLock bit 0 is set.
; StartFadeFar: A | $80 to wFadeReq. StopSoundFar plays 0.
PlaySoundFar:
	push hl
	ld hl, wSndLock
	bit 0, [hl]
	jr nz, FarReturn
	set 0, [hl]
	ld b, a
	ld a, [BANK_ID]
	push af
	call MapBank7
	ld a, b
	call PlaySound
	jr SndUpdateFar.l032E

StartFadeFar:
	push hl
	ld hl, wSndLock
	bit 0, [hl]
	jr nz, FarReturn
	set 0, [hl]
	ld b, a
	ld a, [BANK_ID]
	push af
	call MapBank7
	ld a, b
	call StartFade
	jr SndUpdateFar.l032E

StopSoundFar:
	ld a, $00
	jp PlaySoundFar

SECTION "MapBank7", ROM0[$0392]

MapBank7:
	ld a, $07
	ld [rROMB], a
	ret

SECTION "Sound bank 7", ROMX[$4F16], BANK[7]

; SndInit: NR52 = $FF, NR51 = $FF, NR50 = $77. Never called (and neither is StopSound).
SndInit:
	ld hl, rNR52
	ld a, $FF
	ld [hl-], a
	ld [hl-], a
	ld a, $77
	ld [hl], a
	ret

PlaySound:
	push de
	call PlaySoundA
	pop de
	ret

StopSound:
	push de
	ld a, $00
	call PlaySoundA
	pop de
	ret

; StartFade: wFadeReq = A | $80. The game calls it once (A = $6A).
StartFade:
	set 7, a
	ld [wFadeReq], a
	ret

; PlaySoundA: 0 = StopAll. Header from SoundTable - 2 + 2 * id: priority, track mask,
; pointers. Sfx1, then (unless wReqRefused) Sfx2/SfxN, then (unless wReqRefused) the music
; tracks, then NR51 = wNR51; a set flag ends the request and is cleared. Each start sets
; wReqRefused to 1 (refused) or 0 (started), so a refused last track (SfxN, Ch3, Drm) leaves
; it set and the next request without Sfx1 is cut at its first check.
PlaySoundA:
	ld [wReqId], a
	or a
	jp z, StopAll
	ld [wReqId], a
	push af
	pop af
	ld [wReqId], a
	ld hl, SoundTable - 2
	rst $08
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl+]
	ld d, h
	ld e, l
	rra
	call c, StartSfx1
	ld b, a
	ld a, [wReqRefused]
	or a
	jr nz, RequestAbort
	ld a, b
	rra
	call c, StartSfx2
	rra
	call c, StartSfxN
	ld b, a
	ld a, [wReqRefused]
	or a
	jr nz, RequestAbort
	ld a, b
	rra
	call c, StartCh1
	rra
	call c, StartCh2
	rra
	call c, StartCh3
	rra
	call c, StartDrm
	ld a, [wNR51]
	ldh [rNR51], a
	ret

RequestAbort:
	xor a
	ld [wReqRefused], a
	ret

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l4F94
	ld a, $08
	ldh [rNR10], a
	ld [wRegShadow], a
.l4F94:
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld hl, wTrkCh1
	jr StartTrack

StartCh2:
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	ld hl, wTrkCh2
	jr StartTrack

StartCh3:
	push af
	ld a, [wNR51]
	or $44
	ld [wNR51], a
	ld hl, wTrkCh3
	jr StartTrack

StartSfxN:
	push af
	ld a, [wNR51]
	or $88
	ld [wNR51], a
	ld hl, wTrkSfxN
	jr StartTrack

StartDrm:
	push af
	ld hl, wTrkDrm
	jr StartTrack

StartSfx2:
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	ld hl, wTrkSfx2
	jr StartTrack

StartSfx1:
	push af
	ld a, $08
	ldh [rNR10], a
	ld [wRegShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld hl, wTrkSfx1

; StartTrack: started when the new priority is >= the track's. TRK_FLAGS = $40 (force),
; TRK_FLAGS2-$D0 cleared (segno and return slot are not), raw-stream bits if the stream
; starts with $01; refused: skip the pointer. TRK_PAN = $FF either way.
StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, StartRefused
	ld [hl-], a
	ld a, [wReqId]
	ld [hl+], a
	inc l
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl+], a
	inc de
	ld [hl], $01
	inc l
	ld [hl], $40
	inc l
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
	jr .l5019
.l5019:
	push de
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld l, TRK_PTR + 1
	ld d, [hl]
	ld a, [de]
	cp $01
	jr nz, .l502F
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr StartTrackEnd
.l502F:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr StartTrackEnd

StartRefused:
	inc de
	inc de
	ld a, $01

StartTrackEnd:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

; StopAll: clear $C0-$FF of pages $C0-$C7 (all seven tracks, the globals and the shadows),
; wNR51 = $FF (not written), then SndMute.
StopAll:
	ld hl, wTrkSfx1
.l504A:
	xor a
	ld [hl+], a
	ld a, l
	or a
	jr nz, .l504A
	ld l, TRK_ID
	ld a, h
	cp $C8
	jr nz, .l504A
	ld a, $FF
	ld [wNR51], a

; SndMute: NR12/NR17/NR21/NR32 = 0. The game's pause code calls it (then plays $09).
SndMute:
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; SndUnpause (the game's unpause code, unless wPauseFlag or wMusicHold is set): copy the
; shadows back to the registers of every channel with a playing track (CH1 5 registers, CH2
; 4, CH3 5, CH4 4), without a trigger. This is Tiny Toon's unused RestoreRegs.
SndUnpause:
	ld a, [wPauseFlag]
	ld b, a
	ld a, [wMusicHold]
	or b
	ret nz
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l5085
	ld hl, wRegShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l5085:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l509A
	ld hl, wRegShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l509A:
	ld a, [wTrkCh3]
	or a
	jr z, .l50AB
	ld hl, wRegShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l50AB:
	ld a, [wTrkSfxN]
	or a
	ret z
	ld hl, wRegShadow + $10
	ld de, rNR41
	ld b, $04

CopyRegs:
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, CopyRegs
	ret

; FadeTick (not while paused): while wFadeReq is set, every 32 updates wFadeLevel + 1 (it
; comes off every note volume, SFX included; half on CH3). At level 5 the fade ends:
; wQueuedSnd = wFadeReq (StopAll if < 2, which bit 7 rules out), level and request 0. The
; queued id is played at the end of the same update. Bugs: the queued id keeps bit 7, and
; CountdownTick counts down wCountdown/wFadeReq as one word (see the doc).
FadeTick:
	ld a, [wPauseFlag]
	or a
	ret nz
	ld a, [wFadeReq]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	ld a, $1F
	and [hl]
	ret nz
	ld hl, wFadeLevel
	inc [hl]
	ld a, $05
	cp [hl]
	ret nz

FadeEnd:
	ld a, [wFadeReq]
	ld [wQueuedSnd], a
	cp $02
	jp c, StopAll
	xor a
	ld [hl], a
	ld [wFadeReq], a
	ret

TempoTick:
	xor a
	ld [wTempoSkip], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ret nc
	ld a, $01
	ld [wTempoSkip], a
	ret

; CountdownTick: a word at $C7D0 counted down to 0. Nothing sets $C7D0, but its high byte
; is wFadeReq, so a running fade request is decremented every 256 updates.
CountdownTick:
	ld hl, wCountdown
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	or b
	ret z
	dec bc
	ld [hl], b
	dec l
	ld [hl], c
	ret

; SndUpdate (once per VBlank): fade, countdown, tempo, then tracks 0-6. While wPauseFlag is
; set only Sfx1 runs, and only while it plays $09 (the pause jingle). On a tempo carry (or
; wMusicHold) tracks 3-6 skip the update. The test for track 4 ($5143) is dead.
SndUpdate:
	call FadeTick
	call CountdownTick
	call TempoTick
	xor a

UpdateLoop:
	ld [wTrackIdx], a
	ld a, [wPauseFlag]
	or a
	jr z, .l5130
	ld a, [wTrackIdx]
	cp $00
	jr nz, RunTrack.l5163
	ld a, [wTrkSfx1]
	cp $09
	jr z, RunTrack
	jr PlayQueued
.l5130:
	ld a, [wTrackIdx]
	cp $03
	jr nz, RunTrack
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, PlayQueued
	jr RunTrack
	ld a, [wTrackIdx]
	cp $04
	jr nz, RunTrack
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, PlayQueued

RunTrack:
	ld a, [wTrackIdx]
	add a, $C0
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr z, .l5163
	call TrackTick
.l5163:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, UpdateLoop

PlayQueued:
	ld a, [wQueuedSnd]
	or a
	ret z
	ld b, a
	xor a
	ld [wQueuedSnd], a
	ld a, b
	jp PlaySound

; TrackTick: wRegBase for the track, LEN - 1; at 0 read commands (Ch3: NR30 = 0 first).
; Else: duty step, released flag, vibrato, envelope, then CH3 decay, the envelope volume or,
; at the release tick, NRx2 = env | level + retrigger.
TrackTick:
	call GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, Sustain
	ld l, TRK_FLAGS
	res 0, [hl]
	res 7, [hl]
	ld a, [wTrackIdx]
	cp $05
	jp nz, ReadCmds
	xor a
	ld [wRegShadow + $0A], a
	ldh [rNR30], a
	jp ReadCmds

Sustain:
	ld l, TRK_FLAGS
	bit 7, [hl]
	ret nz
	ld l, TRK_FLAGS2
	bit 4, [hl]
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l51C3
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l51C3:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l51CF
	ld l, TRK_FLAGS
	set 0, [hl]
.l51CF:
	call VibratoTick
	call EnvelopeTick
	ld a, [wTrackIdx]
	cp $05
	jr z, Ch3Decay
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp nz, SustainEnvelope
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	ret nz
	ld l, TRK_ENV
	ld a, [hl]
	ld l, TRK_LEVEL
	or [hl]

SustainWriteVol:
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, TriggerReg
	ld l, TRK_FLAGS2
	bit 0, [hl]
	ret z
	ld l, TRK_FLAGS2
	bit 1, [hl]
	ret nz
	ld l, TRK_FLAGS2
	res 0, [hl]
	jp TriggerReg

SustainEnvelope:
	ld l, TRK_ENVVOL
	ld a, [hl]
	ld l, TRK_VOL
	ld [hl], a
	swap a
	jp SustainWriteVol

Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, Ch3WriteLevel
	ld l, TRK_CH3TIMER
	dec [hl]
	ret nz
	ld l, TRK_CH3RELOAD
	ld a, [hl]
	ld l, TRK_CH3TIMER
	ld [hl], a
	ld l, TRK_LEVEL
	ld a, [hl]
	or a
	jr z, Ch3WriteLevel
	inc a
	and $03
	ld [hl], a
	jr z, Ch3WriteLevel
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l5247
	xor a
.l5247:
	rla
	swap a

Ch3WriteLevel:
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	jp WriteReg

NextCmd:
	inc de

; ReadCmds: $FB-$FF flow (segno, return, call, repeat/jump, end), $E0 voice, $D0-$DF,
; notes, $F0-$FA attenuation, $E1-$E6 octave, $E7-$EF through the table.
ReadCmds:
	ld a, [de]
	cp $FB
	jp c, Command
	inc de
	sub $FB
	push hl
	rst $00
FlowTable:
	dw Flow_Segno
	dw Flow_Ret
	dw Flow_Call
	dw Flow_Repeat
	dw Flow_End

Flow_Segno:
	pop hl
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds

Flow_Ret:
	pop hl
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds

Flow_Call:
	pop hl
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, b
	jr ReadCmds

Flow_Repeat:
	pop hl
	ld a, [de]
	cp $FF
	jr z, .l529E
	ld l, TRK_REPCNT
	inc [hl]
	cp [hl]
	jr z, .l52A8
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l529E:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l52A8:
	ld l, TRK_REPCNT
	ld [hl], $00
	jr NextCmd

; Flow_End: clear id/priority, NRx2 = 0 (Ch3: NR30 = 0). Sfx1 (NR10 = 0) and Sfx2 give
; the duty and the plain period back to the music track; NR51 and the volume are not.
Flow_End:
	pop hl
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l52CC
	xor a
	ldh [rNR30], a
	ret
.l52CC:
	cp $01
	jr z, .l52DA
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l52DC
.l52DA:
	ld h, HIGH(wTrkCh2)
.l52DC:
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	push hl
	call WriteDuty
	pop hl
	ld l, TRK_PERIOD
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld b, [hl]
	jp WritePeriod

Command:
	ld l, TRK_FLAGS2
	bit 5, [hl]
	jp nz, RawStream
	ld a, [de]
	cp $E0
	jp z, Cmd_Voice
	and $F0
	cp $D0
	jp z, Cmd_D
	cp $E0
	jp c, Note
	cp $F0
	jp z, Cmd_Atten
	ld a, [de]
	cp $E7
	jp c, Cmd_Octave
	inc de
	sub $E7
	push hl
	rst $00
CommandTable:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_DutyStep
	dw Cmd_Transpose
	dw Cmd_Vibrato
	dw Cmd_Envelope
	dw Cmd_Detune
	dw Cmd_Tempo
	dw Cmd_EF

Cmd_LenUnit:
	pop hl
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	jp NextCmd

Cmd_Release:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

Cmd_DutyStep:
	pop hl
	ld l, TRK_FLAGS
	ld a, [de]
	or a
	jr z, .l535D
	set 4, [hl]
	and $0F
	ld l, TRK_DUTYSTART
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	jp NextCmd
.l535D:
	res 4, [hl]
	jp NextCmd

Cmd_Transpose:
	pop hl
	ld a, [de]
	and $F0
	ld l, TRK_OCTSHIFT
	ld [hl], a
	sla a
	jp c, .l5377
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd
.l5377:
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Cmd_Vibrato:
	pop hl
	ld a, [de]
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp nz, .l5392
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp NextCmd
.l5392:
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAY
	ld [hl], a
	or a
	jp nz, .l53A6
	ld l, TRK_FLAGS2
	res 7, [hl]
	jp .l53BA
.l53A6:
	push bc
	ld l, TRK_VIBDELAY
	ld b, [hl]
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l53AE:
	add a, c
	dec b
	jp nz, .l53AE
	ld l, TRK_VIBDELAYRELOAD
	ld [hl], a
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
	pop bc
.l53BA:
	ld a, [de]
	and $0F
	ld l, TRK_VIBDEPTH
	ld [hl], a
	ld l, TRK_VIB
	ld a, [hl]
	push hl
	dec a
	ld hl, VibratoTable
	rst $08
	push bc
	ld c, l
	ld b, h
	pop hl
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	xor a
	ld l, TRK_VIBREPCNT
	ld [hl], a
	jp NextCmd

Cmd_Envelope:
	pop hl
	ld a, [de]
	ld l, TRK_ENVNO
	ld [hl], a
	or a
	jp z, NextCmd
	and $0F
	ld l, TRK_ENVNO
	ld [hl], a
	push hl
	dec a
	ld hl, EnvelopeTable
	rst $08
	push bc
	ld c, l
	ld b, h
	pop hl
	pop hl
	ld l, TRK_ENVPTR
	ld [hl], c
	inc l
	ld [hl], b
	xor a
	ld l, TRK_ENVREPCNT
	ld [hl], a
	jp NextCmd

Cmd_Detune:
	pop hl
	ld a, [de]
	ld l, TRK_DETUNE
	ld [hl], a
	jp NextCmd

Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	jp NextCmd

Cmd_EF:
	pop hl
	jp NextCmd

Cmd_Octave:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawStream
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp NextCmd

; Cmd_Voice: $E0 unit; drums stop there; noise: vol << 4 | env to NR42 + trigger; tone and
; wave: duty << 4 | vol, one skipped byte, gate << 4 | env (Tiny Toon: no skipped byte).
; Turns the envelope off.
Cmd_Voice:
	ld a, $00
	ld l, TRK_ENVNO
	ld [hl], a
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawStream
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, NextCmd
	inc de
	cp $02
	jr z, VoiceNoise
	ld a, [de]
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	inc de
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

VoiceNoise:
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	call TriggerReg
	jp NextCmd

Cmd_Atten:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawStream
	ld a, [de]
	and $0F
	ld l, TRK_ATTEN
	ld [hl], a
	ld b, a
	ld a, [wTrackIdx]
	cp $02
	jp nz, NextCmd
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub b
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ld l, TRK_ENV
	or [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	call TriggerReg
	jp NextCmd

NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	ld c, a
	ld b, $00
	jp WritePeriod

Cmd_D:
	ld a, [de]
	cp $D0
	inc de
	sub $D0
	push hl
	rst $00
DCommandTable:
	dw Cmd_D0
	dw Cmd_D1
	dw Cmd_D2
	dw Cmd_D3
	dw Cmd_D4
	dw Cmd_D5
	dw Cmd_D6
	dw Cmd_D7
	dw Cmd_D8
	dw Cmd_Reg0
	dw Cmd_Ext
	dw Cmd_DB
	dw Cmd_DC
	dw Cmd_DD
	dw Cmd_DE
	dw Cmd_Pan

Cmd_D0:
	pop hl
	jp NextCmd

Cmd_D1:
	pop hl
	jp NextCmd

Cmd_D2:
	pop hl
	jp NextCmd

Cmd_D3:
	pop hl
	jp NextCmd

Cmd_D4:
	pop hl
	jp NextCmd

Cmd_D5:
	pop hl
	jp NextCmd

Cmd_D6:
	pop hl
	jp NextCmd

Cmd_D7:
	pop hl
	jp NextCmd

Cmd_D8:
	pop hl
	jp NextCmd

Cmd_Reg0:
	pop hl
	ld a, [de]
	ld [wReg0Val], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
	jp NextCmd

Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	rst $00
ExtTable:
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_Nop
	dw Ext_Duty
	dw Ext_Flags

Ext_TransposeUp:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_TransposeDown:
	pop hl
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_Nop:
	pop hl
	jp NextCmd

Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp NextCmd

Ext_Flags:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l556E
	or $02
	jr .l5570
.l556E:
	and $FD
.l5570:
	ld [hl], a
	jp NextCmd

Cmd_DB:
	pop hl
	jp NextCmd

Cmd_DC:
	pop hl
	jp NextCmd

Cmd_DD:
	pop hl
	jp NextCmd

Cmd_DE:
	pop hl
	jp NextCmd

Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $06
	jr nz, .l5590
	inc de
	jp NextCmd
.l5590:
	ld a, [de]
	ld l, TRK_PAN
	ld [hl], a
	call PanMask
	ld b, a
	call IsBlocked
	ld a, b
	jp c, NextCmd
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp NextCmd

PanMask:
	ld a, [wTrackIdx]
	push hl
	rst $00
PanMaskTable:
	dw PanMaskCh1
	dw PanMaskCh2
	dw PanMaskCh4
	dw PanMaskCh1
	dw PanMaskCh2
	dw PanMaskCh3
	dw PanMaskCh4

PanMaskCh2:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $22
	ld c, a
	ld a, [wNR51]
	and $DD
	ret

PanMaskCh3:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $44
	ld c, a
	ld a, [wNR51]
	and $BB
	ret

PanMaskCh4:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $88
	ld c, a
	ld a, [wNR51]
	and $77
	ret

PanMaskCh1:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $11
	ld c, a
	ld a, [wNR51]
	and $EE
	ret

AutoPan:
	ld a, [wTrackIdx]
	cp $02
	ret z
	ld l, TRK_PAN
	ld a, [hl]
	swap a
	ld [hl], a
	call PanMask
	ld b, a
	call IsBlocked
	ld a, b
	ret c
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ret

; Note: length = lo * unit (0 = 256). Pitch = (hi - 1) + transpose + 12 * octave +
; OctaveShiftTable[shift] (only when the octave is not 0), from PeriodTable.
; Release tick = length * gate / 16 (gate 15: length - 1). The note-on writes NRx2 =
; vol << 4 (envelope 0) and triggers; the release writes env | level.
Note:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawStream
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, AutoPan
	call SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jp z, NoiseNote
	ld a, [de]
	and $0F
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l562D:
	dec b
	jr z, .l5633
	add a, c
	jr .l562D
.l5633:
	ld l, TRK_LEN
	ld [hl], a
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jp z, .l5647
	ld l, TRK_FLAGS2
	set 7, [hl]
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
.l5647:
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l5674
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l5674
	ld l, TRK_DUTYSTART
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegOff], a
	call WriteReg
.l5674:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l5681
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l5693
.l5681:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l5689:
	srl c
	jr nc, .l568E
	add a, d
.l568E:
	rra
	dec b
	jr nz, .l5689
	pop de
.l5693:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBREPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, OctaveShiftTable.l56CD
	ld b, a
	ld c, $0C
	xor a
.l56A6:
	add a, c
	dec b
	jr nz, .l56A6
	ld c, a
	ld l, TRK_OCTSHIFT
	ld a, [hl]
	and $F0
	swap a
	push hl
	ld hl, OctaveShiftTable
	rst $28
	ld a, [hl]
	add a, c
	pop hl
	jr OctaveShiftTable.l56CC

; OctaveShiftTable: 0-7 = +0..+7 octaves, 8 = 0, 9-15 = -1..-7 (Tiny Toon: 8-15 = -1..-8).
OctaveShiftTable:
	db $00, $0C, $18, $24, $30, $3C, $48, $54, $00, $F4, $E8, $DC, $D0, $C4, $B8, $AC
.l56CC:
	ld c, a
.l56CD:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld b, a
	ld l, TRK_TRANSP
	ld a, [hl]
	add a, b
	add a, c
	ld c, a
	ld b, $00
	sla c
	rl b
	push hl
	ld hl, PeriodTable
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop hl
	ld l, TRK_PERIOD
	ld [hl], c
	inc l
	ld [hl], b
	jr .l56F0
.l56F0:
	push bc
	ld l, TRK_VIB
	ld a, [hl]
	ld l, TRK_ENVNO
	ld b, [hl]
	or b
	pop bc
	jp z, .l5709
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	ld l, TRK_ENVIDX
	ld [hl], a
	call VibratoStep
	call EnvelopeStep
.l5709:
	call WritePeriodVib
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, WriteNoteVolume
	ld l, TRK_ENVVOL
	ld a, [hl]
	ld l, TRK_VOL
	ld [hl], a
	jp WriteNoteVolume

EnvelopeTick:
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	ret z
	ld l, TRK_ENVTIMER
	dec [hl]
	ret nz
	ld l, TRK_ENVRELOAD
	ld a, [hl]
	ld l, TRK_ENVTIMER
	ld [hl], a
	ld l, TRK_FLAGS2
	res 1, [hl]
	ld l, TRK_FLAGS2
	set 0, [hl]
	call EnvelopeStep
	jp WritePeriodVib

EnvelopeStep:
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	ret z
	ld l, TRK_ENVPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l574B
	inc b
.l574B:
	ld a, [bc]
	cp $FB
	jr z, .l576C
	cp $FE
	jr z, .l5776
	cp $FF
	jr z, .l5794
	swap a
	and $0F
	ld l, TRK_ENVTIMER
	ld [hl], a
	ld l, TRK_ENVRELOAD
	ld [hl], a
	ld a, [bc]
	and $0F
	ld l, TRK_ENVVOL
	ld [hl], a
	ld l, TRK_ENVIDX
	inc [hl]
	ret
.l576C:
	ld l, TRK_ENVIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_ENVLOOPIDX
	ld [hl], a
	inc bc
	jr .l574B
.l5776:
	inc bc
	ld a, [bc]
	ld l, TRK_ENVREPCNT
	cp [hl]
	jr z, .l578B
	cp $FF
	jr z, .l5782
	inc [hl]
.l5782:
	ld l, TRK_ENVLOOPIDX
	ld a, [hl]
	ld l, TRK_ENVIDX
	ld [hl], a
	jp EnvelopeStep
.l578B:
	xor a
	ld [hl], a
	ld l, TRK_ENVIDX
	inc [hl]
	inc bc
	jp .l574B
.l5794:
	ld l, TRK_FLAGS2
	set 1, [hl]
	ret

WriteNoteVolume:
	call CalcVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	jp TriggerReg

; CalcVolume: TRK_VOL - TRK_ATTEN - wFadeLevel (every track, SFX too; Tiny Toon: music only),
; 0 on a borrow. CH3: level code (vol / 2) & 3 + atten + wFadeLevel / 2, 0 from 4.
CalcVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, CalcVolumeCh3
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l57C6
	xor a
.l57C6:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret

CalcVolumeCh3:
	ld a, $80
	ld [wRegShadow + $0A], a
	ldh [rNR30], a
	ld l, TRK_ENV
	ld a, [hl]
	ld l, TRK_CH3TIMER
	ld [hl], a
	ld l, TRK_CH3RELOAD
	ld [hl], a
	ld a, [wFadeLevel]
	srl a
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	rra
	and $03
	add a, c
	cp $04
	jr c, .l57F4
	xor a
.l57F4:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

WritePeriodVib:
	ld l, TRK_VIBOFS
	ld c, [hl]
	inc l
	ld b, [hl]
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLAGS
	bit 3, [hl]
	push hl
	jr z, .l581B
	push bc
	ld c, l
	ld b, h
	pop hl
	xor a
	sub l
	ld l, a
	ld a, $00
	sbc a, h
	ld h, a
	push bc
	ld c, l
	ld b, h
	pop hl
.l581B:
	push de
	ld e, l
	ld d, h
	pop hl
	add hl, bc
	push bc
	ld c, l
	ld b, h
	pop hl
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl]
	sla a
	jr c, .l5833
	add a, c
	ld c, a
	jr nc, WritePeriod
	inc b
	jr WritePeriod
.l5833:
	ld e, a
	ld a, c
	sub e
	ld c, a
	jr nc, WritePeriod
	dec b
	jr WritePeriod

WritePeriod:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegOff], a
	call WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegOff], a
	jp WriteReg

SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

Rest:
	ld l, TRK_FLAGS
	ld a, $C0
	or [hl]
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	ret

DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = swap(duty), or on CH3 copy wave duty - 1 to wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, LoadWave
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegOff], a
	jp WriteReg

LoadWave:
	dec a
	push de
	push hl
	ld hl, WaveTable
	rst $08
	ld b, $10
	ld de, _AUD3WAVERAM
.l58A2:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l58A2
	pop hl
	pop de
	ret

IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l58BA
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l58C3
.l58BA:
	cp $04
	jr nz, .l58C5
	ld a, [wTrkSfx2]
	or a
	ret z
.l58C3:
	scf
	ret
.l58C5:
	or a
	ret

; WriteReg: register wRegBase + wRegOff = wRegVal, unless blocked (music Ch1 while Sfx1
; plays, music Ch2 while Sfx2 plays) or equal to its shadow (unless the force flag is set).
WriteReg:
	call IsBlocked
	ret c
	push de
	call RegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	ld a, [wTrackIdx]
	add a, $C0
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l58E5
	ld a, [hl]
	cp c
	jr z, .l58E8
.l58E5:
	ld a, c
	ld [hl], a
	ld [de], a
.l58E8:
	pop de
	ld a, [wTrackIdx]
	add a, $C0
	ld h, a
	ret

TriggerReg:
	call IsBlocked
	ret c
	push de
	ld a, $04
	ld [wRegOff], a
	call RegAddr
	ld a, [hl]
	or $80
	ld [de], a
	pop de
	ld a, [wTrackIdx]
	add a, $C0
	ld h, a
	ret

RegAddr:
	ld a, [wRegOff]
	ld c, a
	ld a, [wRegBase]
	add a, c
	ld c, a
	ld b, $00
	ld hl, rNR10
	ld de, wRegShadow
	add hl, bc
	push de
	ld e, l
	ld d, h
	pop hl
	add hl, bc
	ret

GetRegBase:
	ld a, [wTrackIdx]
	push hl
	ld hl, RegBaseTable
	rst $28
	ld a, [hl]
	pop hl
	ret
RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; RawStream (first byte of the stream was $01): $01 unit duty NR10 header, then 2-byte
; frames or $00 rests, one unit each. $E8 and $EB-$ED go to RawFrame with HL still pushed.
; No data uses raw streams.
RawStream:
	ld l, TRK_RELTICK
	xor a
	ld [hl], a
	ld a, [de]
	cp $01
	jr nz, RawByte
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	ld a, [de]
	cp $88
	jr z, .l5962
	cp $00
	jr z, .l5962
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
	jr .l596D
.l5962:
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
.l596D:
	inc de

RawByte:
	ld a, [de]
	or a
	jp z, RawRest
	ld a, [de]
	cp $E7
	jr c, RawFrame
	cp $FB
	jp nc, ReadCmds
	cp $F0
	jr nc, RawFrame
	ld a, [de]
	inc de
	sub $E7
	push hl
	rst $00
RawCommandTable:
	dw Cmd_LenUnit
	dw RawFrame
	dw Cmd_Reg0
	dw Cmd_Ext
	dw RawFrame
	dw RawFrame
	dw RawFrame
	dw Cmd_Tempo
	dw Cmd_Pan

RawFrame:
	ld l, TRK_PAN
	ld a, [hl]
	call PanMask
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_RAWPERIOD + 1
	ld [hl], a
	ld b, a
	inc de
	ld a, [de]
	ld l, TRK_RAWPERIOD
	ld [hl], a
	ld c, a
	call RawWritePeriod
	call SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	jp TriggerReg

RawWritePeriod:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegOff], a
	call WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegOff], a
	jp WriteReg

RawRest:
	call SavePtr
	dec de
	ld l, TRK_FLAGS
	ld a, $80
	ld [hl], a
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	ret

; VibratoTick / VibratoStep: steps time << 4 | negative << 3 | offset (x depth), $FB loop
; point, $FE n repeat (FF: forever), $FF hold. After a finished repeat the index lags one
; byte, so the next step is read twice.
VibratoTick:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	ret z
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jp z, .l5A25
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	cp $00
	jp z, .l5A25
	ld l, TRK_VIBDELAYCNT
	dec [hl]
	ret nz
.l5A25:
	ld l, TRK_FLAGS2
	res 7, [hl]
	ld l, TRK_VIBTIMER
	dec [hl]
	ret nz
	ld l, TRK_VIBRELOAD
	ld a, [hl]
	ld l, TRK_VIBTIMER
	ld [hl], a
	call VibratoStep
	jp WritePeriodVib

VibratoStep:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	ret z
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l5A4B
	inc b
.l5A4B:
	ld a, [bc]
	cp $FB
	jr z, .l5A96
	cp $FE
	jr z, .l5AA0
	cp $FF
	jr z, VibratoHold
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l5A6F
	ld l, TRK_FLAGS
	set 3, [hl]
	jp .l5A73
.l5A6F:
	ld l, TRK_FLAGS
	res 3, [hl]
.l5A73:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l5A92
	push bc
	xor a
	ld c, a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l5A89:
	add a, c
	dec b
	jp nz, .l5A89
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l5A92:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l5A96:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l5A4B
.l5AA0:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBREPCNT
	cp [hl]
	jr z, .l5AB5
	cp $FF
	jr z, .l5AAC
	inc [hl]
.l5AAC:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp VibratoStep
.l5AB5:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l5A4B

VibratoHold:
	ret

; SoundTable: ids $01-$6E (the code adds 2 * id to SoundTable - 2, the last code bytes).
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

SndHdr09:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0A:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd0A_Sfx1
	dw Snd0A_Sfx2

SndHdr0B:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd0C_Sfx1
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd0D_Sfx1
	dw Snd0D_SfxN

SndHdr0E:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd0E_Sfx1
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd10_Sfx1
	dw Snd10_SfxN

SndHdr11:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd12_Sfx1
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd0E_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd14_Sfx1
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd15_Sfx1
	dw Snd15_SfxN

SndHdr16:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd16_Sfx1
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $37, $05 ; tracks: Sfx1, SfxN
	dw Snd17_Sfx1
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $39, $05 ; tracks: Sfx1, SfxN
	dw Snd18_Sfx1
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd19_Sfx1
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd1B_Sfx1
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $39, $05 ; tracks: Sfx1, SfxN
	dw Snd17_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd1E_Ch1
	dw Snd1E_Ch2
	dw Snd1E_Ch3

SndHdr21:
	SND_HEADER $35, $05 ; tracks: Sfx1, SfxN
	dw Snd21_Sfx1
	dw Snd21_SfxN

SndHdr1F:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd20_Sfx1
	dw Snd20_SfxN

SndHdr24:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr22:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd22_Sfx1
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $39, $05 ; tracks: Sfx1, SfxN
	dw Snd23_Sfx1
	dw Snd23_SfxN

SndHdr25:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $29, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd28_Sfx1
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $29, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $40, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd2A_Sfx1
	dw Snd2A_Sfx2
	dw Snd2A_Ch3

SndHdr2B:
	SND_HEADER $40, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd2B_Sfx1
	dw Snd2B_Sfx2
	dw Snd2B_Ch3

SndHdr2C:
	SND_HEADER $37, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $40, $01 ; tracks: Sfx1
	dw Snd2D_Sfx1

SndHdr2E:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd2E_Sfx1

SndHdr2F:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd2F_Sfx1
	dw Snd2F_Sfx2

SndHdr30:
	SND_HEADER $30, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd30_Sfx1
	dw Snd30_Sfx2
	dw Snd30_Ch3

SndHdr31:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd31_Ch1
	dw Snd31_Ch2
	dw Snd31_Ch3
	dw Snd31_Drm

SndHdr32:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd32_Sfx1
	dw Snd32_SfxN

SndHdr33:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd33_SfxN

SndHdr34:
	SND_HEADER $36, $04 ; tracks: SfxN
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $37, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd37_Sfx1
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd38_Sfx1
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd39_Sfx1

SndHdr3A:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $36, $04 ; tracks: SfxN
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd3D_Sfx1
	dw Snd3D_SfxN

SndHdr3E:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $34, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd41_SfxN

SndHdr42:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd43_Sfx1

SndHdr44:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd44_Sfx1
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd45_Sfx1

SndHdr46:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd47_Sfx1

SndHdr48:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd48_Sfx1

SndHdr49:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd49_Sfx1

SndHdr4A:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd4A_SfxN

SndHdr4B:
	SND_HEADER $36, $05 ; tracks: Sfx1, SfxN
	dw Snd4B_Sfx1
	dw Snd4B_SfxN

SndHdr4C:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd4C_Sfx1
	dw Snd4C_SfxN

SndHdr4D:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd4D_Sfx1

SndHdr4E:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd4F_Sfx1

SndHdr50:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd50_Sfx1

SndHdr51:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd52_Sfx1

SndHdr53:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd54_SfxN

SndHdr55:
	SND_HEADER $33, $04 ; tracks: SfxN
	dw Snd55_SfxN

SndHdr56:
	SND_HEADER $35, $04 ; tracks: SfxN
	dw Snd56_SfxN

SndHdr57:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd57_Sfx1

SndHdr58:
	SND_HEADER $45, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd58_SfxN
	dw Snd58_Ch1
	dw Snd58_Ch2
	dw Snd58_Ch3
	dw Snd58_Drm

SndHdr59:
	SND_HEADER $45, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd59_Ch1
	dw Snd59_Ch2
	dw Snd59_Ch3

SndHdr5A:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd5A_Sfx1

SndHdr5B:
	SND_HEADER $50, $01 ; tracks: Sfx1
	dw Snd5B_Sfx1

SndHdr5C:
	SND_HEADER $39, $01 ; tracks: Sfx1
	dw Snd5C_Sfx1

SndHdr5D:
	SND_HEADER $45, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd5D_SfxN
	dw Snd5D_Ch1
	dw Snd5D_Ch2

SndHdr5E:
	SND_HEADER $45, $18 ; tracks: Ch1, Ch2
	dw Snd5E_Ch1
	dw Snd5E_Ch2

SndHdr5F:
	SND_HEADER $45, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd5F_SfxN
	dw Snd5F_Ch1
	dw Snd5F_Ch2
	dw Snd5F_Ch3

SndHdr60:
	SND_HEADER $45, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd60_SfxN
	dw Snd60_Ch1
	dw Snd60_Ch2

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
	dw Snd68_Ch3 ; the next pointer is the first word of SndHdr69

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

; EnvelopeTable: a single entry, pointing at an empty envelope. EC n would read entries 2-15
; from the period table; no data uses $EC.
EnvelopeTable:
	dw Env01 ; 1 (EC n reaches 1-15; entries 2-15 would read the period table)
Env01:
	db $FF

; PeriodTable: 85 periods from C of octave 1 (the same as Tiny Toon's).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; WaveTable: CH3 waves by duty - 1 (15 pointers; 11-15 point at the drum map).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData1 ; wave 2
	dw WaveData3 ; wave 3
	dw WaveData3 ; wave 4
	dw WaveData5 ; wave 5
	dw WaveData6 ; wave 6
	dw WaveData7 ; wave 7
	dw WaveData7 ; wave 8
	dw WaveData9 ; wave 9
	dw WaveData10 ; wave 10
	dw DrumMap ; wave 11 (reads the drum map and the drum headers)
	dw DrumMap ; wave 12 (reads the drum map and the drum headers)
	dw DrumMap ; wave 13 (reads the drum map and the drum headers)
	dw DrumMap ; wave 14 (reads the drum map and the drum headers)
	dw DrumMap ; wave 15 (reads the drum map and the drum headers)
WaveData1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData3:
	db $79, $BC, $DF, $FF, $AA, $87, $54, $32, $45, $66, $77, $87, $42, $10, $00, $02
WaveData5:
	db $00, $00, $00, $00, $00, $00, $99, $FF, $99, $98, $88, $77, $76, $66, $FF, $66
WaveData6:
	db $88, $80, $8B, $BB, $88, $84, $88, $84, $44, $48, $48, $88, $84, $44, $84, $44
WaveData7:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
WaveData9:
	db $03, $57, $9A, $CF, $AA, $AB, $DE, $FF, $00, $13, $45, $55, $03, $56, $8A, $CF
WaveData10:
	db $01, $22, $34, $56, $6A, $A8, $37, $75, $04, $68, $99, $99, $6D, $FE, $9C, $C8

; DrumMap: drum note hi - 1 -> sound id (12 reachable; the last two bytes are unreachable).
DrumMap:
	db $01, $02, $07, $02, $01, $02, $01, $03, $04, $05, $06, $08, $06, $06

SndHdr01:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $00, $05 ; tracks: Sfx1, SfxN
	dw Snd04_Sfx1
	dw Snd03_SfxN

SndHdr05:
	SND_HEADER $00, $05 ; tracks: Sfx1, SfxN
	dw Snd05_Sfx1
	dw Snd03_SfxN

SndHdr06:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $00, $04 ; tracks: SfxN
	dw Snd08_SfxN

Snd01_SfxN:
	PAN $0F
	NVOICE $01, $81
	NOISE $11
	SND_END

Snd02_SfxN:
	PAN $F0
	NVOICE $01, $81
	NOISE $11
	SND_END

Snd05_Sfx1:
	TRANSPOSE_DOWN 2

Snd04_Sfx1:
	VOICE $01, 13, 8, 15, 0, 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 8
	NOTE F_, 1
	SND_END

Snd03_SfxN:
	NVOICE $01, $A1
	NOISE $31
	NVOICE $07, $91
	NOISE $11
	SND_END

Snd06_SfxN:
	NVOICE $01, $7F
	NOISE $17
	NOISE $67
	SND_END

Snd07_SfxN:
	NVOICE $0A, $41
	NOISE $11
	SND_END

Snd08_SfxN:
	NVOICE $06, $44
	NOISE $41
	SND_END

; VibratoTable: 15 pointers (EB n uses entry n).
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib02 ; 3
	dw Vib02 ; 4
	dw Vib05 ; 5
	dw Vib06 ; 6
	dw Vib07 ; 7
	dw Vib07 ; 8
	dw Vib07 ; 9
	dw Vib07 ; 10
	dw Vib0B ; 11
	dw Vib0B ; 12
	dw Vib0B ; 13
	dw Vib0B ; 14
	dw Vib0B ; 15

Vib01:
	VIB_SEGNO
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 0, 2
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 1, 2
	VIB_REPEAT $FF

Vib02:
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

Vib05:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib06:
	VIB_SEGNO
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

Vib07:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF
	db $FF ; unreachable

Vib0B:
	VIB_END

Snd09_Sfx1:
	VOICE $03, 15, 4, 1, 15, 0
	OCTAVE 4
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 4
	SND_END

Snd0A_Sfx1:
	VOICE $01, 14, 0, 0, 15, 0
	SND_SEGNO
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $03
	PAN $0F
	ATTEN $0A
	REST 6
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $02
	PAN $F0
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $02
	SND_END

Snd0A_Sfx2:
	VIBRATO $06, 0, 0
	VOICE $01, 4, 8, 0, 15, 0
	REST 4
	SND_SEGNO
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $03
	SND_END

Snd0B_Sfx1:
	VOICE $01, 14, 8, 1, 15, 0
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_END

Snd0C_Sfx1:
	VOICE $01, 6, 4, 15, 0, 0
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_END

Snd19_Sfx1:
	VOICE $01, 10, 8, 15, 0, 0
	ATTEN $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	SND_END

Snd0D_Sfx1:
	VOICE $01, 15, 8, 0, 15, 0
	OCTAVE 1
	NOTE C#, 1
	ATTEN 1
	OCTAVE 2
	NOTE D_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 4
	NOTE A_, 1
	SND_END

Snd0C_SfxN:
	NVOICE $02, $F3
	NOISE $23
	NOISE $82
	NVOICE $08, $84
	NOISE $12
	SND_END

Snd0D_SfxN:
	NVOICE $03, $F5
	NOISE $21
	NOISE $11
	SND_END

Snd0E_Sfx1:
	TRANSPOSE_DOWN $0C
	VOICE $01, 13, 4, 15, 0, 0
	OCTAVE 3
	ATTEN 8
	NOTE C_, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 8
	NOTE C_, 1
	SND_END

Snd0E_SfxN:
	SND_END

Snd0F_Sfx1:
	VOICE $01, 8, 8, 0, 15, 0
	ATTEN 6
	TRANSPOSE_DOWN 6
	SND_CALL Snd0F_Sfx1_60F6
	ATTEN 5
	TRANSPOSE_DOWN 5
	SND_CALL Snd0F_Sfx1_60F6
	ATTEN 4
	TRANSPOSE_DOWN 4
	SND_CALL Snd0F_Sfx1_60F6
	ATTEN 3
	TRANSPOSE_DOWN 3
	SND_CALL Snd0F_Sfx1_60F6
	ATTEN 2
	TRANSPOSE_DOWN 2
	SND_CALL Snd0F_Sfx1_60F6
	ATTEN 1
	TRANSPOSE_DOWN 1
	SND_CALL Snd0F_Sfx1_60F6
Snd0F_Sfx1_60ED:
	ATTEN 0
	TRANSPOSE_UP 0
	SND_CALL Snd0F_Sfx1_60F6
	SND_CALL Snd0F_Sfx1_60ED
Snd0F_Sfx1_60F6:
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_RET

Snd10_Sfx1:
	VOICE $01, 15, 8, 0, 15, 0
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 8
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd10_SfxN:
	NVOICE $09, $80
	NOISE $4C
	NVOICE $0F, $B1
	NOISE $5F
	SND_END

Snd11_Sfx1:
	VOICE $01, 11, 8, 0, 15, 0
	OCTAVE 5
	NOTE B_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE E_, 1
	ATTEN 4
	NOTE A_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE G#, 1
	NOTE D_, 1
	ATTEN 8
	NOTE G_, 1
	NOTE C#, 1
	ATTEN $0A
	NOTE F#, 1
	NOTE C_, 1
	SND_END

Snd12_Sfx1:
	VOICE $06, 0, 0, 0, 15, 0
	REST 1
	SND_END

Snd12_SfxN:
	NVOICE $01, $F1
	NOISE $78
	NVOICE $08, $71
	NOISE $21
	NVOICE $07, $21
	NOISE $11
	SND_END

Snd20_Sfx1:
	VOICE $01, 15, 8, 0, 15, 0
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 8
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd20_SfxN:
	NVOICE $09, $80
	NOISE $4C
	NVOICE $0F, $B1
	NOISE $5F
	SND_END

Snd21_Sfx1:
	VOICE $01, 15, 0, 0, 15, 0
	OCTAVE 3
	ATTEN 2
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 2
	ATTEN 4
	NOTE G_, 2
	NOTE C_, 4
	SND_END

Snd21_SfxN:
	NVOICE $03, $A8
	NOISE $51
	NVOICE $05, $54
	NOISE $56
	NOISE $41
	NOISE $52
	SND_END

Snd22_Sfx1:
	SND_END

Snd22_SfxN:
	NVOICE $06, $F4
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd23_Sfx1:
	VOICE $02, 15, 8, 15, 0, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN $0A
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd23_SfxN:
	NVOICE $07, $F8
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd24_Sfx1:
	VOICE $01, 15, 0, 0, 15, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	ATTEN 8
	NOTE D_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN $0A
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	SND_END

Snd13_SfxN:
	NVOICE $03, $70
	NOISE $52
	NOISE $53
	NOISE $42
	NOISE $43
	NVOICE $01, $20
	NOISE $33
	NOISE $42
	NOISE $33
	SND_END

Snd14_Sfx1:
	VOICE $02, 15, 8, 0, 0, 0
	OCTAVE 1
	SND_SEGNO
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_REPEAT $02
	SND_END

Snd14_SfxN:
	SND_END

Snd15_Sfx1:
	SND_END

Snd15_SfxN:
	NVOICE $09, $D6
	NOISE $5D
	NOISE $5E
	NVOICE $03, $F6
	NOISE $55
	SND_END

Snd16_Sfx1:
	SND_END

Snd16_SfxN:
	NVOICE $20, $F2
	NOISE $79
	SND_END

Snd17_Sfx1:
	VOICE $01, 11, 8, 0, 0, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_REPEAT $05
	SND_END

Snd17_SfxN:
	NVOICE $02, $D0
	ATTEN 4
	SND_SEGNO
	NOISE $5D
	NOISE $56
	NOISE $43
	SND_REPEAT $04
	ATTEN 0
	SND_SEGNO
	NOISE $5E
	NOISE $57
	NOISE $5D
	SND_REPEAT $08
	SND_SEGNO
	NOISE $5D
	NOISE $56
	NOISE $57
	SND_REPEAT $08
	SND_END

Snd1C_SfxN:
	NVOICE $04, $E0
	NOISE $5D
	ATTEN 9
	NOISE $5D
	ATTEN 4
	NOISE $5D
	ATTEN 9
	NOISE $5D
	ATTEN 6
	NOISE $5D
	ATTEN 9
	NOISE $5D
	ATTEN 8
	NOISE $5D
	NOISE $54
	NOISE $54
	SND_END

Snd18_Sfx1:
	VOICE $01, 9, 8, 0, 0, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_REPEAT $03
	SND_END

Snd18_SfxN:
	NVOICE $01, $A0
	SND_SEGNO
	NOISE $57
	NOISE $55
	NOISE $54
	NOISE $55
	NOISE $53
	NOISE $56
	NOISE $54
	SND_REPEAT $03
	SND_END

Snd19_SfxN:
	NVOICE $0A, $FA
	NOISE $11
	SND_END

Snd1A_Sfx1:
	VOICE $01, 12, 0, 0, 0, 0
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	SND_END

Snd1B_Sfx1:
	VOICE $01, 9, 8, 0, 0, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_REPEAT $02
	SND_END

Snd1B_SfxN:
	NVOICE $02, $D0
	SND_SEGNO
	NOISE $5D
	NOISE $56
	NOISE $43
	SND_REPEAT $02
	ATTEN 8
	NOISE $35
	NOISE $33
	NOISE $37
	SND_END

Snd1D_Sfx1:
	VOICE $02, 10, 0, 0, 0, 0
	OCTAVE 4
	NOTE A#, 3
	OCTAVE 5
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 8
	NOTE F#, 1
	SND_END

Snd1D_SfxN:
	NVOICE $06, $A0
	NOISE $78
	NVOICE $06, $C1
	NOISE $35
	SND_END

Snd25_Sfx1:
	VOICE $01, 13, 8, 1, 15, 0
	OCTAVE 4
	NOTE D_, 3
	ATTEN 4
	NOTE F#, 9
	SND_END

Snd25_SfxN:
	NVOICE $03, $F1
	NOISE $35
	NVOICE $09, $A1
	NOISE $35
	SND_END

Snd1E_Ch1:
	VOICE $05, 11, 0, 0, 0, 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 9
	NOTE B_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 9
	NOTE C#, 1
	ATTEN 0
	NOTE F#, $0C
	SND_END

Snd1E_Ch2:
	VOICE $05, 11, 8, 0, 0, 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 9
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 9
	NOTE A_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 9
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 0
	NOTE B_, $0C
	SND_END

Snd1E_Ch3:
	VOICE $05, 2, 2, 0, 0, 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	ATTEN 0
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 2
	NOTE C#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 2
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	ATTEN 0
	NOTE D#, $0C
	SND_END

Snd26_Sfx1:
	VOICE $09, 15, 4, 0, 15, 0
	REST 1
	SND_END

Snd26_SfxN:
	NVOICE $03, $B0
	NOISE $42
	NOISE $43
	NOISE $32
	NOISE $33
	NVOICE $01, $40
	NOISE $33
	NOISE $42
	NOISE $33
	SND_END

Snd27_Sfx1:
	VOICE $01, 14, 4, 0, 0, 0
	SND_SEGNO
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN $0A
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 0
	SND_REPEAT $02
	ATTEN $0A
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_END

Snd28_Sfx1:
	VOICE $01, 15, 0, 0, 0, 0
	ATTEN 4
	OCTAVE 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	DUTY 8
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	DUTY 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_END

Snd28_SfxN:
	NVOICE $04, $00
	NOISE $22
	NVOICE $05, $F0
	NOISE $3B
	NOISE $46
	SND_END
Data_63D4:
	VOICE $01, 7, 8, 0, 0, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END
Data_63EE:
	NVOICE $01, $F0
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $3B
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $3B
	ATTEN 9
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $24
	NOISE $3B
	NOISE $3B
	SND_END

Snd1F_Sfx1:
	VOICE $01, 13, 8, 0, 0, 0
	OCTAVE 4
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE G_, 1
	NOTE C#, 1
	ATTEN 6
	NOTE G_, 1
	NOTE C#, 1
	ATTEN 8
	NOTE G_, 1
	NOTE C#, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE C#, 1
	SND_END

Snd29_Sfx1:
	VOICE $01, 8, 8, 0, 0, 0
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_END

Snd29_SfxN:
	NVOICE $01, $F0
	NOISE $3D
	NOISE $1B
	NOISE $3D
	NOISE $1B
	NOISE $3C
	NOISE $1B
	ATTEN 9
	NOISE $3C
	NOISE $1B
	NOISE $3B
	NOISE $1B
	NOISE $3B
	NOISE $1B
	SND_END

Snd2A_Sfx1:
	TRANSPOSE 9, 0

Snd2A_Sfx2:
	VOICE $04, 10, 4, 7, 7, 0
	OCTAVE 3
	NOTE C_, $0C
	NOTE C_, 1
	OCTAVE 2
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
	NOTE C_, $0C
	ATTEN 3
	NOTE C_, $0C
	SND_END

Snd2A_Ch3:
	VOICE $04, 2, 10, 2, 15, 0
	OCTAVE 4
	NOTE D#, 1
	REST 1
	NOTE G_, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	OCTAVE 4
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	ATTEN 1
	SND_SEGNO
	OCTAVE 5
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 2
	SND_REPEAT $02
	SND_END

Snd2B_Sfx2:
	TRANSPOSE 9, 0

Snd2B_Sfx1:
	VOICE $01, 10, 0, 0, 0, 0
Snd2B_Sfx1_64C1:
	OCTAVE 3
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
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE A#, 3
	NOTE A_, 3
	NOTE G#, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE G#, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE F_, 3
	NOTE F#, 4
	NOTE F_, 4
	NOTE E_, 4
	ATTEN 6
	SND_SEGNO
	NOTE F#, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE D#, 3
	ATTEN 9
	SND_REPEAT $03
	SND_END

Snd2B_Ch3:
	VOICE $01, 2, 5, 0, 15, 0
	DETUNE $02
	SND_CALL Snd2B_Sfx1_64C1

Snd2C_Sfx1:
	VOICE $04, 15, 8, 1, 15, 0
	OCTAVE 5
	NOTE A_, 2
	NOTE F_, 1
	NOTE A_, 2
	NOTE F_, 1
	SND_END

Snd2D_Sfx1:
	VOICE $01, 15, 8, 1, 15, 0
	ATTEN 7
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 7
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 1
	ATTEN 8
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_END

Snd2E_Sfx1:
	VOICE $01, 15, 0, 15, 0, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	SND_END

Snd2F_Sfx1:
	TRANSPOSE_DOWN $0C
	VOICE $05, 15, 8, 1, 15, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	ATTEN 8
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	ATTEN $0A
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	SND_END

Snd2F_Sfx2:
	SND_END

Snd31_Ch3:
	TRANSPOSE_UP $0C
	VOICE $07, 2, 5, 8, 15, 0
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 8
	SND_END

Snd31_Ch2:
	PAN $0F
	FLAGS 2
	VOICE $07, 15, 8, 3, 15, 0
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 1
	PAN $FF
	FLAGS 0
	OCTAVE 1
	NOTE G_, 8
	SND_END

Snd31_Ch1:
	TRANSPOSE_UP $0C
	VOICE $07, 3, 8, 15, 0, 0
	OCTAVE 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 1
	SND_END

Snd31_Drm:
	DRUM_UNIT $07
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 3
	SND_END

Snd32_Sfx1:
	VOICE $01, 15, 8, 0, 0, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_END

Snd32_SfxN:
	NVOICE $02, $F0
	NOISE $5D
	NOISE $56
	NOISE $43
	ATTEN 8
	NOISE $35
	NOISE $33
	NOISE $37
	SND_END

Snd33_SfxN:
	NVOICE $30, $F6
	NOISE $71
	SND_END

Snd34_SfxN:
	SND_SEGNO
	NVOICE $02, $FA
	NOISE $2B
	NVOICE $02, $FA
	NOISE $2D
	SND_REPEAT $08
	SND_END

Snd35_Sfx1:
	SND_END

Snd35_SfxN:
	SND_END

Snd36_SfxN:
	NVOICE $06, $F1
	NOISE $11
	NOISE $21
	NOISE $51
	NOISE $11
	SND_END

Snd37_Sfx1:
	TRANSPOSE_DOWN 6
	VOICE $01, 15, 8, 15, 0, 15
Snd37_Sfx1_662E:
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 6
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd37_SfxN:
	SND_END

Snd38_Sfx1:
	VOICE $02, 15, 0, 0, 0, 0
	OCTAVE 6
	NOTE G_, 2
	ATTEN 3
	NOTE D#, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 7
	NOTE D#, 1
	CMD_D1 $51
	VOICE $02, 8, 12, 6, 14, 0
	NOTE G_, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 4
	REST 1
	NOTE A#, 1
	ATTEN 5
	REST 3
	CMD_D1 $FF

Snd38_SfxN:
	NVOICE $04, $84 ; loop byte read both as a start and as an end (see doc)
	NOISE $61
	NOISE $51
	NOISE $41 ; loop byte read both as a start and as an end (see doc)
	NOISE $31 ; loop byte read both as a start and as an end (see doc)
	NVOICE $14, $F4 ; loop byte read both as a start and as an end (see doc)
	NOISE $71
	NOISE $71
	SND_END
	db $FF

Snd39_Sfx1:
	VOICE $02, 8, 4, 15, 0, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	SND_REPEAT $08
	SND_END

Snd3A_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 15, 0, 15, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	ATTEN 8
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd3B_SfxN:
	NVOICE $80, $19
	NOISE $51
	SND_END

Snd3C_SfxN:
	SND_SEGNO
	NVOICE $01, $61
	NOISE $68
	NOISE $11
	NOISE $21
	NOISE $31
	SND_REPEAT $F0
	SND_END

Snd3D_Sfx1:
	VOICE $01, 15, 8, 15, 0, 0
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_END

Snd3D_SfxN:
	SND_END

Snd3E_Sfx1:
	VOICE $01, 15, 8, 15, 0, 0
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd3E_SfxN:
	NVOICE $0D, $F1
	NOISE $61
	NOISE $11
	SND_END

Snd3F_Sfx1:
	TRANSPOSE_UP $0C
	VOICE $01, 13, 8, 15, 0, 0
	OCTAVE 1
	SND_SEGNO
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT $08
	SND_END
	db $FF

Snd40_Sfx1:
	TRANSPOSE_UP $0C
	VOICE $03, 15, 8, 15, 0, 0
	OCTAVE 1
	SND_SEGNO
	NOTE C_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN $0A
	NOTE G#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	SND_REPEAT $03
	SND_END
	db $FF

Snd41_SfxN:
	SND_SEGNO
	NVOICE $02, $F1
	NOISE $1E
	NOISE $28
	NOISE $1A
	NOISE $3D
	SND_REPEAT $08
	SND_END

Snd42_Sfx1:
	TRANSPOSE_UP 0
	VOICE $02, 15, 0, 15, 0, 0
	OCTAVE 1
	SND_SEGNO
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT $10
	SND_END
	db $FF

Snd43_Sfx1:
	VOICE $01, 15, 8, 1, 15, 0
	SND_SEGNO
	OCTAVE 6
	NOTE A_, 1
	REST 2
	ATTEN $0A
	NOTE B_, 1
	REST 3
	ATTEN 0
	OCTAVE 6
	NOTE A_, 1
	REST 2
	ATTEN $0A
	NOTE B_, 1
	SND_REPEAT $03
	SND_END

Snd44_Sfx1:
	SND_END

Snd44_SfxN:
	NVOICE $08, $F4
	NOISE $41
	NOISE $51
	NOISE $41
	NOISE $31
	SND_END
	db $FF, $FF

Snd45_Sfx1:
	VOICE $01, 15, 0, 15, 0, 0
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	REST 4
	ATTEN $0A
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_END

Snd46_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 15, 8, 15, 0, 0
	SND_CALL Snd37_Sfx1_662E

Snd47_Sfx1:
	TRANSPOSE_UP 6
	VOICE $01, 15, 8, 15, 0, 0
	OCTAVE 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_END

Snd48_Sfx1:
	TRANSPOSE_UP 0
	VOICE $02, 13, 0, 15, 0, 0
	OCTAVE 1
	SND_SEGNO
	NOTE C_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN $0A
	NOTE G#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	SND_REPEAT $10
	SND_END
	db $FF

Snd49_Sfx1:
	TRANSPOSE_UP 8
	VOICE $01, 15, 8, 15, 0, 0
	OCTAVE 3
	NOTE C_, 4
	ATTEN 7
	NOTE D#, 1
	ATTEN 8
	NOTE F_, 1
	ATTEN 9
	NOTE G_, 1
	ATTEN $0A
	NOTE A#, 1
	ATTEN 9
	NOTE G_, 1
	SND_END

Snd4A_SfxN:
	NVOICE $06, $F1
	NOISE $11
	NOISE $21
	NOISE $51
	NOISE $11
	SND_END

Snd4B_Sfx1:
	SND_END

Snd4B_SfxN:
	NVOICE $0F, $F4
	NOISE $7C
	NVOICE $0F, $65
	NOISE $71
	SND_END

Snd4C_Sfx1:
	VOICE $01, 15, 0, 15, 0, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd4C_SfxN:
	NVOICE $01, $66
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd4D_Sfx1:
	VOICE $01, 13, 8, 15, 0, 0
	OCTAVE 4
	ATTEN $0A
	NOTE B_, 9
	ATTEN 9
	NOTE A#, 1
	ATTEN 8
	NOTE A_, 1
	ATTEN 7
	NOTE G#, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 1
	SND_END

Snd4E_SfxN:
	NVOICE $04, $F4
	NOISE $61
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd4F_Sfx1:
	VOICE $03, 15, 8, 1, 15, 0
	OCTAVE 5
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd50_Sfx1:
	VOICE $01, 15, 0, 5, 15, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE B_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE B_, 1
	NOTE C_, 1
	SND_END
	db $E0 ; unreachable
	db $01

Snd51_Sfx1:
	VOICE $01, 15, 8, 1, 15, 0
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd52_Sfx1:
	VOICE $01, 15, 0, 1, 15, 0
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT $04
	REST 3
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT $08
	SND_END

Snd53_SfxN:
	NVOICE $40, $C9
	NOISE $71
	SND_END

Snd54_SfxN:
	NVOICE $10, $FA
	NOISE $91
	NVOICE $10, $FA
	NOISE $81
	NVOICE $10, $FA
	NOISE $71
	NOISE $71
	SND_END

Snd55_SfxN:
	NVOICE $0C, $F3
	NOISE $61
	NOISE $91
	SND_END

Snd56_SfxN:
	NVOICE $80, $FE
	NOISE $11
	SND_END

Snd57_Sfx1:
	TRANSPOSE_UP 0
	VOICE $02, 15, 8, 15, 0, 0
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_END

Snd58_Ch1:
	VOICE $01, 13, 0, 15, 0, 0
	SND_SEGNO
	ATTEN 0
	OCTAVE 1
	NOTE A_, 8
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 8
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	REST $0E
	SND_REPEAT $02
	REST $0E
	REST $0E
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
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
	ATTEN $0A
	OCTAVE 1
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
	REST $0E
	REST $0E
	VOICE $03, 15, 0, 15, 0, 0
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT $06
	LEN_UNIT 1
	TRANSPOSE_DOWN 6
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 6
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_REPEAT $04
	ATTEN 5
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 8
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 6
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 9
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 7
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd58_Ch2:
	VIBRATO $06, 0, 3
	VOICE $01, 4, 8, 15, 0, 0
	REST 5
	SND_SEGNO
	ATTEN 0
	OCTAVE 1
	NOTE A_, 8
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 8
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	REST $0E
	SND_REPEAT $02
	REST $0E
	REST $0E
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
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
	OCTAVE 1
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
	REST $0E
	REST $0E
	VOICE $03, 4, 8, 15, 0, 0
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT $06
	LEN_UNIT 1
	TRANSPOSE_DOWN 6
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_REPEAT $07
	SND_END

Snd58_Ch3:
	VOICE $01, 4, 5, 15, 0, 0
	SND_SEGNO
	ATTEN 0
	OCTAVE 1
	NOTE A_, 8
	NOTE A#, 1
	NOTE A_, 1
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
	REST $0E
	SND_REPEAT $02
	REST $0E
	REST $0E
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
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
	OCTAVE 1
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
	REST $0E
	REST $0E
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT $1B
	SND_END

Snd58_SfxN:
	SND_SEGNO
	NVOICE $10, $19
	NOISE $01
	SND_REPEAT $05
	SND_SEGNO
	NVOICE $10, $19
	NOISE $5C
	SND_REPEAT $07
	SND_SEGNO
	NVOICE $10, $F9
	NOISE $81
	SND_REPEAT $0A
	SND_END

Snd58_Drm:
	SND_END

Snd59_Ch1:
	PAN $0F
	VOICE $06, 6, 8, 15, 0, 0
	REST 1
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	ATTEN 3
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	SND_END

Snd59_Ch2:
	PAN $F0
	VIBRATO $06, 0, 0
	VOICE $06, 2, 8, 15, 0, 0
	REST 3
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	SND_END

Snd59_Ch3:
	VOICE $06, 2, 4, 4, 15, 0
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	SND_END

Snd5A_Sfx1:
	VOICE $03, 13, 12, 1, 15, 0
	ATTEN 6
	SND_CALL Snd5A_Sfx1_6A86
	ATTEN 4
	SND_CALL Snd5A_Sfx1_6A86
	ATTEN 2
	SND_CALL Snd5A_Sfx1_6A86
	ATTEN 0
	SND_CALL Snd5A_Sfx1_6A86
	SND_CALL Snd5A_Sfx1_6A86
	SND_END
Snd5A_Sfx1_6A86:
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_RET

Snd5B_Sfx1:
	VOICE $04, 14, 8, 1, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd5C_Sfx1:
	VOICE $04, 15, 8, 1, 15, 0
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd5D_Ch1:
	VOICE $01, 15, 8, 15, 0, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	LEN_UNIT 2
	OCTAVE 1
	SND_CALL Snd5D_Ch1_6B08
	OCTAVE 2
	SND_CALL Snd5D_Ch1_6B08
	OCTAVE 3
	SND_CALL Snd5D_Ch1_6B08
	ATTEN 5
	SND_CALL Snd5D_Ch1_6B08
	ATTEN $0A
	SND_CALL Snd5D_Ch1_6B08
	SND_END

Snd5D_Ch2:
	VIBRATO $06, 0, 0
	VOICE $02, 5, 8, 15, 0, 0
	REST 3
	OCTAVE 6
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 1
	SND_CALL Snd5D_Ch1_6B08
	OCTAVE 2
	SND_CALL Snd5D_Ch1_6B08
	OCTAVE 3
	SND_CALL Snd5D_Ch1_6B08
	SND_CALL Snd5D_Ch1_6B08
	SND_CALL Snd5D_Ch1_6B08
	SND_END
Snd5D_Ch1_6B08:
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
	SND_RET

Snd5D_SfxN:
	NVOICE $08, $3E
	NOISE $81
	NVOICE $08, $4E
	NOISE $71
	NVOICE $10, $7E
	NOISE $61
	NVOICE $10, $AE
	NOISE $51
	NVOICE $10, $DE
	NOISE $41
	NVOICE $50, $FE
	NOISE $31
	SND_END

Snd5E_Ch1:
	VOICE $05, 15, 0, 1, 15, 0
	ATTEN $0A
	SND_CALL Snd5E_Ch1_6B54
	ATTEN 6
	SND_CALL Snd5E_Ch1_6B54
	ATTEN 4
	SND_CALL Snd5E_Ch1_6B54
	ATTEN 0
	SND_CALL Snd5E_Ch1_6B54
	SND_END

Snd5E_Ch2:
	VIBRATO $06, 0, 0
	VOICE $05, 2, 8, 15, 0, 0
	REST 2
	SND_SEGNO
	SND_CALL Snd5E_Ch1_6B54
	SND_REPEAT $04
	SND_END
Snd5E_Ch1_6B54:
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	SND_RET

Snd5F_Ch1:
	TRANSPOSE_DOWN 4
	VOICE $02, 15, 8, 15, 0, 0
	OCTAVE 3
	SND_CALL Snd5F_Ch1_6B99
	OCTAVE 2
	SND_CALL Snd5F_Ch1_6B99
	OCTAVE 1
	SND_CALL Snd5F_Ch1_6B99
	ATTEN 5
	SND_CALL Snd5F_Ch1_6B99
	ATTEN $0A
	SND_CALL Snd5F_Ch1_6B99
	SND_END

Snd5F_Ch2:
	TRANSPOSE_DOWN 4
	VIBRATO $06, 0, 0
	VOICE $02, 5, 8, 15, 0, 0
	REST 6
	OCTAVE 3
	SND_CALL Snd5F_Ch1_6B99
	OCTAVE 2
	SND_CALL Snd5F_Ch1_6B99
	OCTAVE 1
	SND_CALL Snd5F_Ch1_6B99
	SND_CALL Snd5F_Ch1_6B99
	SND_CALL Snd5F_Ch1_6B99
	SND_END
Snd5F_Ch1_6B99:
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
	SND_RET

Snd5F_Ch3:
	SND_END

Snd5F_SfxN:
	SND_END

Snd60_Ch1:
	TRANSPOSE_UP $0C
	VOICE $01, 12, 12, 0, 15, 0
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	NOTE C_, 1
	VOICE $02, 15, 0, 0, 15, 0
	NOTE F#, 3
	ATTEN $0A
	NOTE F#, 3
	REST 6
	SND_CALL Snd5F_Ch1

Snd60_Ch2:
	TRANSPOSE_UP $0C
	VOICE $01, 5, 8, 0, 15, 0
	REST 6
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	NOTE C_, 1
	VOICE $02, 4, 0, 0, 15, 0
	NOTE F#, 3
	NOTE F#, 3
	REST 6
	SND_CALL Snd5F_Ch2

Snd60_SfxN:
	NVOICE $08, $73
	NOISE $43
	NOISE $22
	NOISE $22
	NVOICE $06, $03
	NOISE $11
	SND_CALL Snd5F_SfxN

Snd62_Ch2:
	TRANSPOSE_DOWN 6
	VOICE $05, 13, 0, 0, 15, 0
	OCTAVE 2
	NOTE E_, 7
	NOTE C_, 9
	NOTE A_, 7
	NOTE G_, 5
	NOTE C_, 2
	NOTE D_, 2
	PAN $0F
	ATTEN 7
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	PAN $F0
	ATTEN $0A
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	PAN $FF
	ATTEN 0
Snd62_Ch2_6C07:
	PAN $0F
	FLAGS 2
	VOICE $05, 14, 0, 3, 13, 0
	SND_CALL Snd62_Ch2_6C28
	SND_CALL Snd62_Ch2_6C28
	SND_CALL Snd62_Ch2_6C5A
	SND_CALL Snd62_Ch2_6C28
	SND_CALL Snd62_Ch2_6C28
	SND_CALL Snd62_Ch2_6C5A
	SND_CALL Snd62_Ch2_6CA0
	SND_CALL Snd62_Ch2_6C07
Snd62_Ch2_6C28:
	RELEASE $0D, 3
	PAN $0F
	FLAGS 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 4
	NOTE G_, 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 4
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	ATTEN 3
	PAN $FF
	FLAGS 0
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	ATTEN 0
	PAN $0F
	FLAGS 2
	SND_RET
Snd62_Ch2_6C5A:
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_REPEAT $02
	SND_SEGNO
	NOTE F#, 3
	NOTE E_, 3
	NOTE D#, 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT $02
	SND_SEGNO
	NOTE A_, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $02
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	PAN $FF
	FLAGS 0
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd62_Ch2_6CA0:
	RELEASE 0, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 6
	NOTE B_, 4
	NOTE E_, 3
	ATTEN 7
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 2
	NOTE D_, 6
	NOTE B_, 4
	NOTE D_, 3
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 2
	NOTE C_, 6
	NOTE B_, 4
	NOTE C_, 3
	ATTEN 7
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	NOTE B_, 6
	NOTE F#, 4
	NOTE B_, 3
	ATTEN 7
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 6
	NOTE E_, 4
	NOTE A_, 3
	ATTEN 7
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 6
	NOTE F#, 4
	NOTE B_, 3
	ATTEN 7
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE C_, 6
	NOTE G_, 4
	NOTE C_, 3
	ATTEN 7
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 6
	NOTE A_, 4
	NOTE D_, 3
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 2
	SND_REPEAT $02
	RELEASE $0D, 3
	SND_RET

Snd62_Ch1:
	VIBRATO $06, 0, 3
	TRANSPOSE_DOWN 6
	VOICE $05, 3, 8, 15, 0, 0
	REST 2
	SND_CALL Snd62_Ch1_6D96
	SND_CALL Snd62_Ch1_6DA5
	SND_CALL Snd62_Ch1_6D96
	SND_CALL Snd62_Ch1_6DAB
Snd62_Ch1_6CF8:
	SND_SEGNO
	SND_CALL Snd62_Ch1_6DBC
	SND_CALL Snd62_Ch1_6DBC
	SND_CALL Snd62_Ch1_6DD7
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DD7
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DEB
	SND_REPEAT $02
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E00
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E0E
	SND_CALL Snd62_Ch1_6E23
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E00
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E0E
	SND_CALL Snd62_Ch1_6E27
	SND_CALL Snd62_Ch1_6CF8

Snd62_Ch3:
	VIBRATO $01, 10, 0
	TRANSPOSE_DOWN 6
	VOICE $05, 2, 5, 4, 7, 0
	SND_CALL Snd62_Ch1_6D96
	SND_CALL Snd62_Ch1_6DA5
	SND_CALL Snd62_Ch1_6D96
	SND_CALL Snd62_Ch1_6DAB
Snd62_Ch3_6D50:
	SND_SEGNO
	SND_CALL Snd62_Ch3_6DB8
	SND_CALL Snd62_Ch3_6DB8
	WAVE 2
	SND_CALL Snd62_Ch1_6DD7
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DD7
	SND_CALL Snd62_Ch1_6DE4
	SND_CALL Snd62_Ch1_6DEB
	WAVE 5
	SND_REPEAT $02
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E00
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E0E
	SND_CALL Snd62_Ch1_6E23
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E00
	SND_CALL Snd62_Ch1_6DF2
	SND_CALL Snd62_Ch1_6E0E
	SND_CALL Snd62_Ch1_6E27
	SND_CALL Snd62_Ch3_6D50
Snd62_Ch1_6D96:
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	SND_RET
Snd62_Ch1_6DA5:
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	SND_RET
Snd62_Ch1_6DAB:
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	REST 4
	ATTEN 0
	SND_RET
Snd62_Ch3_6DB8:
	RELEASE 0, $0F
	WAVE 9
Snd62_Ch1_6DBC:
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 5
	NOTE F#, 6
	NOTE F#, 1
	NOTE G_, 2
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, $0F
	ATTEN 1
	NOTE E_, 3
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 5
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	SND_RET
Snd62_Ch1_6DD7:
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 2
	SND_RET
Snd62_Ch1_6DE4:
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 2
	SND_RET
Snd62_Ch1_6DEB:
	NOTE B_, 8
	NOTE B_, 2
	REST 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 3
	SND_RET
Snd62_Ch1_6DF2:
	NOTE D_, 1
	NOTE E_, 5
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	SND_RET
Snd62_Ch1_6E00:
	NOTE D_, 1
	NOTE E_, 5
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, $0A
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 2
	SND_RET
Snd62_Ch1_6E0E:
	NOTE E_, 1
	NOTE F#, 5
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 3
	NOTE F#, 2
	NOTE G_, 4
	NOTE F#, 2
	NOTE G_, 2
	SND_RET
Snd62_Ch1_6E23:
	NOTE A_, $0A
	NOTE F#, 2
	NOTE D_, 6
	SND_RET
Snd62_Ch1_6E27:
	NOTE B_, $0A
	NOTE B_, 2
	NOTE A_, 6
	SND_RET

Snd62_Drm:
	TEMPO $20
	DRUM_UNIT $05
	SND_SEGNO
	DRUM $0B, 4
	SND_REPEAT $06
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	REST 8
Snd62_Drm_6E3C:
	SND_CALL Snd62_Drm_6E48
	SND_CALL Snd62_Drm_6E48
	SND_CALL Snd62_Drm_6E7A
	SND_CALL Snd62_Drm_6E3C
Snd62_Drm_6E48:
	SND_SEGNO
	DRUM $0B, 3
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 3
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT $07
	DRUM $0B, 3
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 2
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 2
	SND_REPEAT $07
	SND_SEGNO
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_REPEAT $03
	SND_SEGNO
	DRUM 9, 1
	SND_REPEAT $07
	SND_RET
Snd62_Drm_6E7A:
	SND_SEGNO
	DRUM $0B, 3
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 3
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT $0F
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 3
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0A, 1
	SND_RET

Snd6B_Ch2:
	VIBRATO $04, 0, 0
	VOICE $08, 8, 4, 5, 15, 0
	REST 8
	REST 8
Snd6B_Ch2_6E9A:
	PAN $0F
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EBD
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EC8
	PAN $FF
	SND_CALL Snd6B_Ch1_6ED3
	SND_CALL Snd6B_Ch2_6E9A
Snd6B_Ch1_6EB0:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET
Snd6B_Ch1_6EBD:
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_RET
Snd6B_Ch1_6EC8:
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	SND_RET
Snd6B_Ch1_6ED3:
	SND_SEGNO
	OCTAVE 4
	NOTE G#, 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 3
	NOTE G#, 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	SND_REPEAT $04
	SND_RET

Snd6B_Ch1:
	VIBRATO $06, 0, 0
	VOICE $08, 2, 8, 15, 0, 0
	REST 8
	REST $0A
Snd6B_Ch1_6EFA:
	PAN $F0
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EBD
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EC8
	PAN $FF
	SND_CALL Snd6B_Ch1_6ED3
	SND_CALL Snd6B_Ch1_6EFA

Snd6B_Ch3:
	VOICE $08, 2, 9, 4, 15, 0
	REST 8
	REST 8
Snd6B_Ch3_6F17:
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EBD
	SND_CALL Snd6B_Ch1_6EB0
	SND_CALL Snd6B_Ch1_6EC8
	SND_CALL Snd6B_Ch3_6F17

Snd6B_Drm:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_REPEAT $04
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
Snd6B_Drm_6F32:
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	SND_CALL Snd6B_Drm_6F32

Snd67_Ch1:
	VOICE $04, 4, 0, 5, 15, 0
	REST 7
Snd67_Ch1_6F3F:
	SND_CALL Snd67_Ch1_6F50
	SND_CALL Snd67_Ch1_6F3F

Snd67_Ch2:
	VOICE $04, 9, 0, 2, 15, 0
Snd67_Ch2_6F4A:
	SND_CALL Snd67_Ch1_6F50
	SND_CALL Snd67_Ch2_6F4A
Snd67_Ch1_6F50:
	OCTAVE 3
	NOTE D#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C_, 2
	SND_RET

Snd67_Ch3:
	VOICE $30, 2, 9, 15, 0, 0
Snd67_Ch3_6F63:
	OCTAVE 1
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE G#, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE A#, 4
	SND_CALL Snd67_Ch3_6F63

Snd67_Drm:
	DRUM_UNIT $04
Snd67_Drm_6F71:
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	SND_CALL Snd67_Drm_6F71

Snd69_Ch2:
	VOICE $03, 8, 4, 0, 0, 0
	DETUNE $01
Snd69_Ch2_6F82:
	ATTEN 4
	REST 2
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	NOTE G#, $0C
	NOTE G#, $0C
	NOTE G#, 8
	NOTE G#, 6
	NOTE D#, 6
	NOTE C#, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A#, 4
	NOTE G#, 4
	NOTE A_, $0C
	NOTE A_, 4
	NOTE A_, 6
	OCTAVE 2
	NOTE C#, 6
	NOTE E_, 4
	NOTE F#, $0C
	NOTE F#, $0C
	NOTE F#, 7
	NOTE G#, $0C
	NOTE G#, $0C
	NOTE G#, 8
	NOTE G#, 6
	NOTE D#, 6
	NOTE C#, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A#, 4
	NOTE G#, 4
	NOTE A_, $0C
	NOTE A_, 4
	NOTE A_, 6
	OCTAVE 2
	NOTE C#, 6
	NOTE E_, 4
	NOTE F#, $0C
	NOTE F#, $0C
	NOTE F#, 7
	ATTEN 0
	SND_SEGNO
	OCTAVE 1
	NOTE D#, 6
	NOTE E_, 4
	OCTAVE 2
	NOTE G#, 6
	NOTE A_, 4
	NOTE G#, 4
	OCTAVE 1
	NOTE D#, 6
	NOTE E_, 6
	NOTE D#, 4
	NOTE F_, 6
	NOTE F#, 4
	OCTAVE 2
	NOTE A#, 6
	NOTE B_, 4
	NOTE A#, 4
	OCTAVE 1
	NOTE F_, 6
	NOTE F#, 6
	NOTE A_, 4
	SND_REPEAT $02
	SND_CALL Snd69_Ch2_6F82

Snd69_Ch1:
	VOICE $03, 8, 4, 0, 0, 0
Snd69_Ch1_6FDF:
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE E_, 2
	SND_REPEAT $05
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C#, 2
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE E_, 2
	SND_REPEAT $05
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C#, 2
	TRANSPOSE_UP 7
	SND_SEGNO
	OCTAVE 1
	NOTE D#, 6
	NOTE E_, 4
	OCTAVE 2
	NOTE G#, 6
	NOTE G#, 4
	NOTE G#, 4
	OCTAVE 1
	NOTE D#, 6
	NOTE E_, 6
	NOTE D#, 4
	NOTE F_, 6
	NOTE F#, 4
	OCTAVE 2
	NOTE A#, 6
	NOTE A#, 4
	NOTE A#, 4
	OCTAVE 1
	NOTE F_, 6
	NOTE F#, 6
	NOTE A_, 4
	SND_REPEAT $02
	TRANSPOSE_UP 0
	SND_CALL Snd69_Ch1_6FDF

Snd69_Ch3:
	VOICE $03, 2, 6, 0, 0, 0
Snd69_Ch3_705F:
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 5
	SND_CALL Snd69_Ch1_70EB
	TRANSPOSE_UP 0
	WAVE 5
	SND_SEGNO
	NOTE G#, $0C
	NOTE G#, $0C
	NOTE G#, 8
	NOTE G#, 6
	NOTE D#, 6
	NOTE C#, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A#, 4
	NOTE G#, 4
	OCTAVE 1
	NOTE A_, $0C
	NOTE A_, 4
	NOTE A_, 6
	OCTAVE 2
	NOTE C#, 6
	NOTE E_, 4
	NOTE F#, $0C
	NOTE F#, $0C
	NOTE F#, 8
	SND_REPEAT $02
	WAVE 6
	SND_SEGNO
	NOTE D#, 6
	NOTE E_, 4
	REST $0E
	NOTE D#, 6
	NOTE E_, 6
	NOTE D#, 4
	NOTE F_, 6
	NOTE F#, 4
	REST $0E
	NOTE F_, 6
	NOTE F#, 6
	NOTE A_, 4
	SND_REPEAT $02
	SND_CALL Snd69_Ch3_705F

Snd69_Drm:
	DRUM_UNIT $03
Snd69_Drm_70A2:
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	SND_REPEAT $0F
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	SND_REPEAT $08
	SND_SEGNO
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 6
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT $03
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 6
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_CALL Snd69_Drm_70A2
Snd69_Ch1_70EB:
	SND_SEGNO
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE F#, 4
	OCTAVE 2
	NOTE F#, 4
	SND_REPEAT $04
	SND_RET

Snd61_Ch1:
	VOICE $03, 4, 4, 4, 15, 0
	REST 3
Snd61_Ch1_7101:
	OCTAVE 4
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G#, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 2
	SND_CALL Snd61_Ch1_7101

Snd61_Ch2:
	TEMPO $20
	VOICE $03, 8, 4, 4, 15, 0
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	SND_REPEAT $02
Snd61_Ch2_714C:
	SND_CALL Snd61_Ch2_719B
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	SND_CALL Snd61_Ch2_719B
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_SEGNO
	TRANSPOSE 8, 7
	SND_CALL Snd61_Ch2_719B
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	SND_REPEAT $02
	TRANSPOSE 0, 0
	SND_CALL Snd61_Ch2_714C

Snd61_Ch3:
	VOICE $03, 2, 10, 7, 15, 0
	SND_CALL Snd61_Ch1_7101

Snd61_Drm:
	DRUM_UNIT $03
	SND_SEGNO
	DRUM $0B, 6
	SND_REPEAT $0E
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
Snd61_Drm_7189:
	SND_SEGNO
	DRUM $0B, 2
	REST 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	REST 2
	SND_REPEAT $07
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_CALL Snd61_Drm_7189
Snd61_Ch2_719B:
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	SND_RET

Snd63_Ch3:
	TRANSPOSE_UP 3
	VIBRATO $04, 0, 2
	TEMPO $10
	VOICE $06, 2, 2, 5, 15, 0
	SND_CALL Snd63_Ch1_7200
Snd63_Ch3_71C4:
	WAVE 8
	RELEASE $0B, 4
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_723E
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_7245
	RELEASE $0F, 5
	WAVE 2
	SND_CALL Snd63_Ch1_7249
	RELEASE $0B, 4
	WAVE 8
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_723E
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_7245
	RELEASE $0F, 5
	WAVE 2
	SND_CALL Snd63_Ch1_7255
	RELEASE 0, $0F
	SND_SEGNO
	SND_CALL Snd63_Ch1_7261
	SND_CALL Snd63_Ch1_7277
	SND_REPEAT $04
	SND_CALL Snd63_Ch3_71C4
Snd63_Ch1_7200:
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_REPEAT $02
	SND_RET
Snd63_Ch1_7227:
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE $0F, 5
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd63_Ch1_723E:
	RELEASE 0, $0F
	NOTE D_, 5
	NOTE D_, 8
	RELEASE $0B, 4
	SND_RET
Snd63_Ch1_7245:
	RELEASE 0, $0F
	NOTE D_, 5
	SND_RET
Snd63_Ch1_7249:
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D#, 1
	SND_RET
Snd63_Ch1_7255:
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	SND_RET
Snd63_Ch1_7261:
	OCTAVE 3
	NOTE E_, 4
	NOTE F#, 1
	NOTE G_, 2
	NOTE C_, 5
	NOTE F#, 1
	NOTE G_, 2
	NOTE D_, 5
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	RELEASE $0F, 5
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_RET
Snd63_Ch1_7277:
	NOTE A_, 1
	RELEASE 0, $0F
	SND_RET
Snd63_Ch1_727B:
	VOICE $06, 3, 8, 15, 0, 0
	VIBRATO $06, 0, 0
	REST 1
	SND_CALL Snd63_Ch1_7295

Snd63_Ch1:
	TRANSPOSE_UP 3
	VIBRATO $06, 0, 2
	VOICE $06, 3, 8, 15, 0, 0
	REST 1
	SND_CALL Snd63_Ch1_7200
Snd63_Ch1_7295:
	TRANSPOSE_DOWN 9
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_723E
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_7245
	TRANSPOSE_UP 3
	SND_CALL Snd63_Ch1_7249
	TRANSPOSE_DOWN 9
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_723E
	SND_CALL Snd63_Ch1_7227
	SND_CALL Snd63_Ch1_7245
	TRANSPOSE_UP 3
	SND_CALL Snd63_Ch1_7255
	SND_CALL Snd63_Ch1_7261
	SND_CALL Snd63_Ch1_7277
	SND_CALL Snd63_Ch1_7261
	SND_CALL Snd63_Ch1_72CD
	SND_CALL Snd63_Ch1_727B
	db $FD ; unreachable call after a jump
	db $95, $72
Snd63_Ch1_72CD:
	VIBRATO $04, 0, 2
	VOICE $06, 6, 4, 15, 0, 0
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 4
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 5
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE A_, 5
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_REPEAT $02
	SND_RET

Snd63_Ch2:
	TRANSPOSE_DOWN 9
	VOICE $0C, 15, 0, 15, 0, 0
	OCTAVE 2
	NOTE E_, 8
	OCTAVE 2
	NOTE C_, 8
	LEN_UNIT 6
	DUTY_STEP 1, 8
	RELEASE $0F, 1
	FLAGS 2
	PAN $0F
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	SND_REPEAT $10
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $08
Snd63_Ch2_7314:
	SND_CALL Snd63_Ch2_733A
	SND_CALL Snd63_Ch2_7354
	SND_CALL Snd63_Ch2_733A
	SND_CALL Snd63_Ch2_735D
	SND_CALL Snd63_Ch2_733A
	SND_CALL Snd63_Ch2_7354
	SND_CALL Snd63_Ch2_733A
	SND_CALL Snd63_Ch2_7366
	PAN $FF
	FLAGS 0
	SND_CALL Snd63_Ch2_736F
	PAN $F0
	FLAGS 2
	SND_CALL Snd63_Ch2_7314
Snd63_Ch2_733A:
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd63_Ch2_7354:
	NOTE G_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_RET
Snd63_Ch2_735D:
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_RET
Snd63_Ch2_7366:
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd63_Ch2_736F:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT $04
	SND_RET

Snd63_Drm:
	DRUM_UNIT $06
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $20
Snd63_Drm_739B:
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd63_Drm_739B

Snd64_Ch2:
	TRANSPOSE_DOWN $0C
	VIBRATO $01, 0, 0
	VOICE $08, 8, 4, 15, 0, 0
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 6
	SND_REPEAT $02
Snd64_Ch2_73CB:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7439
	TRANSPOSE_UP 0
	SND_CALL Snd64_Ch1_7445
	SND_CALL Snd64_Ch1_7452
	SND_CALL Snd64_Ch1_7445
	SND_CALL Snd64_Ch1_7454
	SND_CALL Snd64_Ch1_7456
	SND_CALL Snd64_Ch1_745D
	SND_CALL Snd64_Ch1_7456
	NOTE B_, 4
	SND_CALL Snd64_Ch1_745D
	NOTE E_, 4
	SND_CALL Snd64_Ch2_73CB
Snd64_Ch1_741C:
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 1
	SND_RET
Snd64_Ch1_7425:
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_RET
Snd64_Ch1_7432:
	OCTAVE 4
	NOTE D_, 6
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	SND_RET
Snd64_Ch1_7439:
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_RET
Snd64_Ch1_7445:
	OCTAVE 4
	NOTE G#, 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	SND_RET
Snd64_Ch1_7452:
	NOTE G#, 9
	SND_RET
Snd64_Ch1_7454:
	NOTE E_, 9
	SND_RET
Snd64_Ch1_7456:
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, $0D
	SND_RET
Snd64_Ch1_745D:
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, $0E
	NOTE F#, 3
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 1
	SND_RET

Snd64_Ch1:
	TRANSPOSE_DOWN $0C
	VOICE $08, 6, 8, 15, 0, 0
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G_, 6
	SND_REPEAT $02
	VIBRATO $06, 0, 0
	VOICE $08, 2, 8, 15, 0, 0
	REST 2
Snd64_Ch1_74A7:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7432
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_741C
	SND_CALL Snd64_Ch1_7439
	TRANSPOSE_UP 0
	SND_CALL Snd64_Ch1_7445
	SND_CALL Snd64_Ch1_7452
	SND_CALL Snd64_Ch1_7445
	SND_CALL Snd64_Ch1_7454
	SND_CALL Snd64_Ch1_7456
	SND_CALL Snd64_Ch1_745D
	SND_CALL Snd64_Ch1_7456
	NOTE B_, 4
	SND_CALL Snd64_Ch1_745D
	NOTE E_, 4
	SND_CALL Snd64_Ch1_74A7

Snd64_Ch3:
	TEMPO $10
	TRANSPOSE_DOWN $0C
	VOICE $08, 2, 9, 4, 15, 0
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT $02
Snd64_Ch3_751E:
	SND_CALL Snd64_Ch3_7536
	SND_CALL Snd64_Ch3_7536
	SND_CALL Snd64_Ch3_7536
	SND_CALL Snd64_Ch3_7541
	SND_CALL Snd64_Ch3_754E
	SND_CALL Snd64_Ch3_756F
	SND_CALL Snd64_Ch3_756F
	SND_CALL Snd64_Ch3_751E
Snd64_Ch3_7536:
	OCTAVE 2
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $17
	NOTE D_, 2
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $07
	SND_RET
Snd64_Ch3_7541:
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $17
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd64_Ch3_754E:
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $07
	NOTE C_, 2
	SND_SEGNO
	NOTE C_, 1
	SND_REPEAT $07
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $07
	NOTE E_, 2
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $0E
	NOTE C_, 2
	SND_SEGNO
	NOTE C_, 1
	SND_REPEAT $07
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $07
	NOTE A_, 2
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $07
	SND_RET
Snd64_Ch3_756F:
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $10
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $07
	SND_SEGNO
	NOTE B_, 1
	SND_REPEAT $10
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $08
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $08
	SND_RET

Snd64_Drm:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM 8, 1
	DRUM $0B, 1
	SND_REPEAT $0E
	DRUM_UNIT $04
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd64_Drm_75A0:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	SND_REPEAT $1E
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	SND_REPEAT $04
	DRUM_UNIT $08
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	SND_REPEAT $1F
	DRUM_UNIT $04
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd64_Drm_75A0

Snd65_Ch2:
	VIBRATO $04, 0, 0
	VOICE $06, 10, 4, 1, 15, 0
	SND_CALL Snd65_Ch1_7610
	PAN $FF
	RELEASE 0, $0F
	DUTY 8
	ATTEN 1
	VIBRATO $05, 0, 15
	SND_CALL Snd65_Ch1_7634
	VIBRATO $04, 0, 0
	LEN_UNIT 6
	DUTY_STEP 1, 0
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_DOWN 2
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_UP 2
	SND_CALL Snd65_Ch1_7643
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_UP 0
	DUTY_STEP_OFF
	ATTEN 0
	SND_CALL Snd65_Ch2
Snd65_Ch1_7610:
	SND_SEGNO
	PAN $FF
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	PAN $0F
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	PAN $F0
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	PAN $0F
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	PAN $F0
	NOTE D_, 1
	NOTE D_, 1
	PAN $0F
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $08
	PAN $FF
	SND_RET
Snd65_Ch1_7634:
	LEN_UNIT $18
	OCTAVE 2
	NOTE F#, 4
	NOTE B_, 2
	NOTE D_, 2
	NOTE C_, 8
	NOTE F#, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 8
	RELEASE $0D, 2
	SND_RET
Snd65_Ch1_7643:
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	SND_RET

Snd65_Ch1:
	VIBRATO $06, 0, 0
	VOICE $06, 4, 8, 5, 15, 0
	REST 4
Snd65_Ch1_767A:
	SND_CALL Snd65_Ch1_7610
	VIBRATO $05, 0, 8
	VOICE $06, 5, 8, 15, 0, 0
	PAN $0F
	FLAGS 2
	SND_CALL Snd65_Ch1_7634
	VIBRATO $06, 0, 0
	LEN_UNIT 6
	PAN $FF
	FLAGS 0
	VOICE $06, 4, 8, 5, 15, 0
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_DOWN 2
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_UP 2
	SND_CALL Snd65_Ch1_7643
	SND_CALL Snd65_Ch1_7643
	TRANSPOSE_UP 0
	SND_CALL Snd65_Ch1_767A

Snd65_Ch3:
	VOICE $06, 2, 9, 15, 0, 0
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 3
	OCTAVE 2
	NOTE C#, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 2
	NOTE G_, 2
	SND_REPEAT $0A
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 3
	OCTAVE 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 3
	OCTAVE 2
	NOTE C#, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 3
	OCTAVE 2
	NOTE E_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 3
	OCTAVE 2
	NOTE D_, 3
	NOTE A_, 3
	NOTE A#, 3
	NOTE A_, 2
	NOTE A#, 2
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 3
	OCTAVE 2
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE C#, 2
	NOTE D_, 2
	SND_REPEAT $04
	SND_CALL Snd65_Ch3

Snd65_Drm:
	TEMPO $20
	DRUM_UNIT $06
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 1
	SND_REPEAT $F0
	SND_CALL Snd65_Drm
	db $FF

Snd30_Sfx2:
	VOICE $06, 9, 4, 6, 15, 0
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE D_, 1
	NOTE E_, 2
	ATTEN 6
	NOTE D_, 1
	NOTE E_, 2
	ATTEN 7
	NOTE D_, 1
	NOTE E_, 2
	SND_END

Snd30_Sfx1:
	VIBRATO $06, 0, 0
	VOICE $06, 2, 8, 15, 0, 0
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE D_, 1
	NOTE E_, 8
	SND_END

Snd30_Ch3:
	VOICE $06, 2, 9, 5, 15, 0
	OCTAVE 2
	NOTE E_, 3
	NOTE C#, 3
	OCTAVE 1
	NOTE A#, 3
	NOTE G_, 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 4
	SND_END

Snd66_Ch2:
	TEMPO $00
	VOICE $04, 8, 12, 7, 15, 0
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE D_, 6
	VIBRATO $01, 3, 3
	RELEASE $0A, $0F
	NOTE C#, $0C
	VIBRATO_OFF
	RELEASE $0E, 5
	NOTE D_, 6
	NOTE D#, 6
	NOTE E_, 4
	NOTE F_, 4
	NOTE F#, 4
	OCTAVE 3
	NOTE G_, 6
	OCTAVE 4
	NOTE D_, 6
	VIBRATO $01, 3, 2
	RELEASE $0A, $0F
	NOTE C#, $0C
	VIBRATO_OFF
	RELEASE $0E, 5
	NOTE D_, 6
	NOTE D#, 6
	NOTE E_, 4
	NOTE F_, 4
	NOTE F#, 4
	DUTY 0
Snd66_Ch2_77A9:
	SND_CALL Snd66_Ch2_77D1
	SND_CALL Snd66_Ch2_77D1
	TRANSPOSE_UP 5
	SND_CALL Snd66_Ch2_77D1
	SND_CALL Snd66_Ch2_77D1
	DUTY 0
	TRANSPOSE_UP 0
	SND_CALL Snd66_Ch2_7828
	SND_CALL Snd66_Ch2_7842
	SND_CALL Snd66_Ch2_7828
	DUTY $0C
	SND_CALL Snd66_Ch2_784B
	SND_CALL Snd66_Ch1_785D
	NOTE A_, 2
	SND_CALL Snd66_Ch2_77A9
	db $FF
Snd66_Ch2_77D1:
	RELEASE $0F, 4
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	FLAGS 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	FLAGS 0
	PAN $FF
	SND_REPEAT $03
	RELEASE 0, $0F
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	RELEASE $0F, 4
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	FLAGS 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	FLAGS 0
	PAN $FF
	SND_REPEAT $02
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	FLAGS 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	FLAGS 0
	PAN $FF
	RELEASE $0A, $0F
	OCTAVE 3
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	NOTE F_, 7
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	SND_RET
Snd66_Ch2_7828:
	RELEASE $0F, 7
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE A#, 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE C#, 4
	NOTE C_, 4
	NOTE F_, 6
	NOTE D#, 4
	NOTE C#, 2
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE F_, 4
	NOTE A#, 6
	OCTAVE 3
	NOTE C_, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4

Snd68_Drm:
	DRUM 1, 4 ; loop byte read both as a start and as an end (see doc)
	SND_RET
Snd66_Ch2_7842:
	RELEASE $0A, 7
	NOTE F_, 6
	NOTE D#, 6
	RELEASE 6, 7
	OCTAVE 3
	NOTE A#, $0C
	SND_RET
Snd66_Ch2_784B:
	RELEASE $0F, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	SND_RET
Snd66_Ch1_785D:
	SND_SEGNO
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 6
	SND_REPEAT $03
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	SND_RET

Snd66_Ch1:
	VOICE $04, 6, 8, 7, 14, 0
	SND_SEGNO
	RELEASE $0E, 7
	OCTAVE 2
	NOTE D_, 6
	NOTE A#, 6
	RELEASE 6, $0F
	NOTE A_, $0C
	RELEASE $0E, 7
	NOTE A#, 6
	NOTE A#, 6
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	TRANSPOSE_UP $0C
	SND_REPEAT $02
	TRANSPOSE_UP 0
Snd66_Ch1_7892:
	DETUNE $01
	SND_CALL Snd66_Ch1_78BC
	SND_CALL Snd66_Ch1_78BC
	TRANSPOSE_UP 5
	SND_CALL Snd66_Ch1_78BC
	SND_CALL Snd66_Ch1_78BC
	TRANSPOSE_UP 0
	SND_CALL Snd66_Ch1_78EE
	DUTY 0
	FLAGS 2
	PAN $F0
	RELEASE 0, $0F
	NOTE A#, 2
	SND_CALL Snd66_Ch1_785D
	DUTY 8
	FLAGS 0
	PAN $FF
	SND_CALL Snd66_Ch1_7892
Snd66_Ch1_78BC:
	RELEASE 0, $0F
	ATTEN 4
	OCTAVE 2
	NOTE G_, 2
	SND_SEGNO
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 6
	SND_REPEAT $03
	NOTE G#, 2
	ATTEN 0
	RELEASE $0F, 7
	NOTE G#, 4
	OCTAVE 3
	NOTE C_, 4
	ATTEN 4
	RELEASE 0, $0F
	OCTAVE 2
	NOTE G_, 2
	SND_SEGNO
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 6
	SND_REPEAT $02
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 4
	ATTEN 0
	RELEASE $0F, 7
	OCTAVE 3
	NOTE C_, 4
	RELEASE 0, $0F
	NOTE D_, 8
	SND_RET
Snd66_Ch1_78EE:
	ATTEN 1
	LEN_UNIT 8
	VIBRATO $01, 6, 4
	OCTAVE 3
	NOTE F_, $0C
	NOTE C_, $0C
	NOTE F_, $0C
	OCTAVE 4
	NOTE C_, $0C
	VIBRATO $01, 6, 2
	NOTE F_, $0C
	NOTE C_, $0C
	OCTAVE 3
	NOTE F_, $0C
	LEN_UNIT 4
	VIBRATO_OFF
	RELEASE $0F, 7
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 2
	SND_RET

Snd66_Ch3:
	VOICE $04, 2, 2, 5, 15, 0
	SND_CALL Snd66_Ch3_7925
	SND_CALL Snd66_Ch3_7925
	SND_CALL Snd66_Ch3_7933
Snd66_Ch3_7925:
	OCTAVE 1
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	SND_REPEAT $09
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT $03
	SND_RET
Snd66_Ch3_7933:
	SND_CALL Snd66_Ch3_7953
	SND_CALL Snd66_Ch3_7953
	TRANSPOSE_UP 5
	SND_CALL Snd66_Ch3_7953
	SND_CALL Snd66_Ch3_7953
	TRANSPOSE_UP 0
	SND_CALL Snd66_Ch3_7973
	SND_CALL Snd66_Ch3_7996
	SND_CALL Snd66_Ch3_7973
	SND_CALL Snd66_Ch3_799C
	SND_CALL Snd66_Ch3_7933
	db $FF
Snd66_Ch3_7953:
	OCTAVE 1
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	SND_REPEAT $03
	NOTE G#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE F_, 2
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	SND_REPEAT $03
	NOTE G#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE A#, 2
	SND_RET
Snd66_Ch3_7973:
	WAVE 6
	FLAGS 2
	PAN $F0
	OCTAVE 1
	SND_SEGNO
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_REPEAT $02
	SND_SEGNO
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	SND_REPEAT $02
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_RET
Snd66_Ch3_7996:
	SND_SEGNO
	NOTE F#, 2
	NOTE F#, 2
	SND_REPEAT $06
	SND_RET
Snd66_Ch3_799C:
	SND_SEGNO
	NOTE F#, 2
	SND_REPEAT $06
	SND_SEGNO
	NOTE G#, 2
	SND_REPEAT $06
	FLAGS 0
	PAN $FF
	WAVE 2
	OCTAVE 1
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	SND_SEGNO
	NOTE C#, 2
	NOTE G#, 2
	SND_REPEAT $04
	NOTE C#, 2
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	SND_SEGNO
	NOTE D_, 2
	NOTE G#, 2
	NOTE D_, 2
	SND_REPEAT $03
	NOTE D_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	SND_RET

Snd66_Drm:
	DRUM_UNIT $04
	SND_CALL Snd66_Drm_79E9
	SND_CALL Snd66_Drm_79E9
	SND_CALL Snd66_Drm_79F7
Snd66_Drm_79E9:
	SND_SEGNO
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	SND_REPEAT $06
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 1, 2
	DRUM 8, 2
	DRUM 1, 2
	SND_RET
Snd66_Drm_79F7:
	SND_CALL Snd66_Drm_7A12
	SND_CALL Snd66_Drm_7A12
	SND_CALL Snd66_Drm_7A12
	SND_CALL Snd66_Drm_7A12
	SND_CALL Snd66_Drm_7A22
	SND_CALL Snd66_Drm_7A49
	SND_CALL Snd66_Drm_7A22
	SND_CALL Snd66_Drm_7A56
	SND_CALL Snd66_Drm_79F7
Snd66_Drm_7A12:
	SND_SEGNO
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 4, 2
	DRUM 1, 2
	DRUM 2, 2
	SND_REPEAT $07
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_RET
Snd66_Drm_7A22:
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 1, 2
	SND_RET
Snd66_Drm_7A49:
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_RET
Snd66_Drm_7A56:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_REPEAT $04
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 2
	SND_REPEAT $05
	DRUM 8, 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 2
	SND_REPEAT $05
	DRUM 8, 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 2
	SND_REPEAT $05
	DRUM 8, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 8, 2
	SND_REPEAT $02
	SND_RET

Snd6A_Ch2:
	TEMPO $20
	VIBRATO $04, 0, 8
	VOICE $06, 8, 0, 15, 0, 0
Snd6A_Ch2_7A83:
	SND_CALL Snd6A_Ch1_7A98
	SND_CALL Snd6A_Ch2_7A83

Snd6A_Ch1:
	VIBRATO $06, 0, 3
	VOICE $06, 3, 8, 15, 0, 0
	REST 1
Snd6A_Ch1_7A92:
	SND_CALL Snd6A_Ch1_7A98
	SND_CALL Snd6A_Ch1_7A92
Snd6A_Ch1_7A98:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 3
	NOTE B_, 3
	OCTAVE 2
	NOTE C_, 3
	NOTE D#, 3
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT $08
	RELEASE 8, 2
	TRANSPOSE_DOWN $0C
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 3
	NOTE D#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	SND_REPEAT $02
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT $04
	TRANSPOSE_UP 0
	RELEASE 0, $0F
	SND_RET

Snd6A_Ch3:
	VIBRATO $04, 0, 0
	PAN $0F
	FLAGS 2
	VOICE $06, 2, 6, 3, 9, 0
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT $08
	VIBRATO $04, 0, 8
	PAN $FF
	FLAGS 0
	RELEASE 0, $0F
	TRANSPOSE_DOWN $0C
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, $0D
	NOTE D#, $0E
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE D_, $0D
	NOTE C#, $0E
	NOTE C#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_, $0D
	OCTAVE 2
	NOTE B_, $0E
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, $0D
	NOTE A_, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	TRANSPOSE_UP 0
	SND_CALL Snd6A_Ch3

Snd6A_Drm:
	DRUM_UNIT $06
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	SND_REPEAT $F0
	SND_CALL Snd6A_Drm

Snd68_Ch2:
	TEMPO $50
	VOICE $06, 12, 0, 5, 15, 0
	OCTAVE 3
	ATTEN 6
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 5
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 3
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 1
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 0
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 1
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 3
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 5
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 6
	NOTE F_, 1
	NOTE F#, 1
	SND_CALL Snd68_Ch2

Snd68_Ch1:
	VOICE $06, 3, 8, 15, 0, 0
	REST 1
Snd68_Ch1_7BBB:
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	SND_CALL Snd68_Ch1_7BBB

Snd68_Ch3:
	VOICE $06, 2, 9, 15, 0, 0
	OCTAVE 1
	NOTE B_, 8
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE A_, 8
	NOTE G_, 8
	NOTE F#, 8
	NOTE F_, 8
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE A#, 8
	SND_CALL Snd68_Ch3
	db $FF

Snd6C_Ch2:
	VOICE $07, 10, 8, 15, 0, 0
	DUTY_STEP 1, 0
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_CALL Snd6C_Ch2

Snd6C_Ch1:
	VIBRATO $06, 0, 0
	VOICE $07, 2, 8, 15, 0, 0
	REST 1
Snd6C_Ch1_7C08:
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_CALL Snd6C_Ch1_7C08

Snd6C_Ch3:
	TEMPO $10
	VOICE $07, 2, 10, 8, 15, 0
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_CALL Snd6C_Ch3

Snd6C_Drm:
	SND_END

Snd6D_Ch2:
	PAN $F0
	FLAGS 2
	VOICE $09, 8, 4, 2, 15, 0
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd6D_Ch2

Snd6D_Ch1:
	PAN $0F
	FLAGS 2
	VIBRATO $06, 0, 0
	VOICE $09, 3, 8, 15, 0, 0
	REST 2
Snd6D_Ch1_7C5E:
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd6D_Ch1_7C5E

Snd6D_Ch3:
	VOICE $09, 2, 6, 4, 15, 0
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_CALL Snd6D_Ch3

Snd6D_Drm:
	TEMPO $20
	DRUM_UNIT $09
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	SND_CALL Snd6D_Drm

Snd6E_Ch2:
	PAN $F0
	FLAGS 2
	DUTY_STEP 2, 8
	VOICE $08, 15, 0, 1, 15, 0
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE B_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE E_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE D_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE B_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE F#, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE B_, 1
	SND_REPEAT $09
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE F#, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE B_, 1
	SND_REPEAT $09
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A#, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE A_, 1
	SND_REPEAT $09
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_CALL Snd6E_Ch2

Snd6E_Ch1:
	VIBRATO $06, 0, 1
	VOICE $08, 3, 0, 15, 0, 0
	REST 1
Snd6E_Ch1_7D87:
	SND_SEGNO
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 9
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE G#, 3
	NOTE E_, 3
	NOTE G#, 3
	NOTE B_, 3
	NOTE F#, 9
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE C#, 3
	NOTE E_, 3
	NOTE D#, 9
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE A_, $0C
	NOTE A_, 6
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_REPEAT $02
	RELEASE 0, $0F
	OCTAVE 2
	NOTE B_, 9
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE C#, 9
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 9
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	OCTAVE 2
	NOTE B_, 9
	NOTE B_, 3
	NOTE B_, 6
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 9
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE C#, 9
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 9
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE D_, 9
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 3
	OCTAVE 2
	NOTE G_, 3
	NOTE E_, 3
	SND_CALL Snd6E_Ch1_7D87

Snd6E_Ch3:
	VIBRATO $0B, 0, 0
	VOICE $08, 2, 2, 15, 0, 0
	SND_SEGNO
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 9
	RELEASE $0F, 5
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	RELEASE 5, 7
	NOTE G#, 3
	NOTE E_, 3
	NOTE G#, 3
	NOTE B_, 3
	RELEASE 0, $0F
	NOTE F#, 9
	RELEASE $0F, 5
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, 7
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE C#, 3
	NOTE E_, 3
	RELEASE 0, $0F
	NOTE D#, 9
	RELEASE $0F, 5
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	RELEASE 5, 7
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	RELEASE 0, $0F
	NOTE A_, $0C
	NOTE A_, 6
	WAVE 4
	RELEASE $0F, 5
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	WAVE 2
	SND_REPEAT $02
	WAVE 2
	RELEASE 0, $0F
	OCTAVE 2
	NOTE B_, 9
	RELEASE $0F, 5
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 5, 7
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	RELEASE 0, $0F
	OCTAVE 3
	NOTE C#, 9
	RELEASE $0F, 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 5, 7
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 3
	RELEASE 0, $0F
	OCTAVE 2
	NOTE B_, 9
	RELEASE $0F, 5
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 5, 7
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	RELEASE 0, $0F
	OCTAVE 2
	NOTE B_, 9
	NOTE B_, 3
	NOTE B_, 6
	WAVE 4
	RELEASE $0F, 5
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 0, $0F
	WAVE 2
	OCTAVE 2
	NOTE B_, 9
	RELEASE $0F, 5
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 5, 7
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	RELEASE 0, $0F
	OCTAVE 3
	NOTE C#, 9
	RELEASE $0F, 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 5, 7
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 9
	RELEASE $0F, 5
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 5, 7
	NOTE C#, 3
	OCTAVE 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 9
	RELEASE $0F, 5
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	RELEASE 5, 7
	NOTE E_, 3
	NOTE C_, 3
	OCTAVE 2
	NOTE G_, 3
	NOTE E_, 3
	SND_CALL Snd6E_Ch3

Snd6E_Drm:
	TEMPO $10
	DRUM_UNIT $08
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $0F
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd6E_Drm
