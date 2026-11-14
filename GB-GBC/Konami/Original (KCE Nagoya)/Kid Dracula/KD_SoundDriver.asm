; ==========================================================================
; Kid Dracula (U) - Konami sound driver (bank 14, songs $7F-$8F in bank 15)
; Byte-exact RGBDS disassembly of the driver code and all sound data. Tiny Toon Adventures'
; reworked third-generation driver with Zen's track page ($C0C0), pause and request flag, a stream
; bank in every header (FarRead in ROM0), and no envelopes or raw streams.
;   ROM0: the rst $00/$08/$28 helpers, the bank-14 wrappers ($2BED-$2C51), FarRead ($3FE8)
;   bank 14: the driver ($4000-$4C20), tables, headers, SFX and songs $73-$7E ($4C21-$7BFA)
;   bank 15: songs $7F-$8F ($4000-$5875)
; Build: rgbasm -Wall -o kd.o KD_SoundDriver.asm && rgblink -o kd.gb kd.o
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
DEF wC7CA EQU $C7CA
DEF wReqId EQU $C7CB
DEF wReqPrio EQU $C7CC
DEF wRegVal EQU $C7CD
DEF wRegOff EQU $C7CE
DEF wMusicHold EQU $C7CF
DEF wCountdown EQU $C7D0
DEF wFadeReq EQU $C7D1
DEF wFadeStep EQU $C7D2
DEF wFadeLevel EQU $C7D3
DEF wReqRefused EQU $C7D4
DEF wFadeDiv EQU $C7DD
DEF wReqBank EQU $C7DE
DEF wRegShadow EQU $C7DF ; 21 bytes
DEF wSndLock EQU $C9C5
DEF wPauseFlag EQU $C9CB
DEF rROMB EQU $2345 ; MBC1 bank select (the game writes it here)
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
DEF TRK_UNIT EQU $D0
DEF TRK_OCTAVE EQU $D1
DEF TRK_PERIOD EQU $D2
DEF TRK_VOL EQU $D6
DEF TRK_DUTY EQU $D7
DEF TRK_ENV EQU $D8
DEF TRK_GATE EQU $D9
DEF TRK_RELTICK EQU $DA
DEF TRK_VIBTIMER EQU $DB
DEF TRK_VIBRELOAD EQU $DC
DEF TRK_CH3TIMER EQU $DD
DEF TRK_CH3RELOAD EQU $DE
DEF TRK_LEVEL EQU $E0
DEF TRK_SEGNO EQU $E1
DEF TRK_RET EQU $E5
DEF TRK_VIBPTR EQU $E9
DEF TRK_VIBIDX EQU $EB
DEF TRK_VIBLOOPIDX EQU $EC
DEF TRK_VIBDEPTH EQU $ED
DEF TRK_VIBDELAY EQU $EE
DEF TRK_VIBDELAYRELOAD EQU $EF
DEF TRK_VIBDELAYCNT EQU $F0
DEF TRK_ENVNO EQU $F1
DEF TRK_ENVVOL EQU $F2
DEF TRK_BANK EQU $F3
DEF TRK_ENVIDX EQU $F4
DEF TRK_DUTYCNT EQU $F5
DEF TRK_DUTYSTART EQU $F6
DEF TRK_DUTYTICKS EQU $F7
DEF TRK_PAN EQU $F8
DEF TRK_OCTSHIFT EQU $F9
DEF TRK_DETUNE EQU $FA

; TRK_FLAGS: 0 released, 1 autopan, 3 vibrato negative, 4 duty step, 6 force register writes, 7 rest
; TRK_FLAGS2: 4/5 set by StartTrack when the first stream byte is $01 (never read), 7 vibrato delay
; TRK_ENVNO / TRK_ENVVOL / TRK_ENVIDX: what is left of the envelopes (cleared, tested, never set)
; TRK_BANK: the header's bank; FarRead maps it for every byte of a sound with id >= $7F
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

; sound header: priority, stream bank, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm), one dw per set
; bit. The bank is used for ids >= $7F only (every stream byte through FarRead); it is 14 for all ids
; below, whose streams are read from bank 14 directly
MACRO SND_HEADER
	db \1, \2, \3
ENDM
; note: hi = pitch 1-12 (0 = rest), lo = length multiplier (x unit; 0 = 256 ticks)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = DrumMap entry 1-7, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: NR43 value (NR44 = 0, no retrigger), length = unit
MACRO NOISE
	db \1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3 duty = wave 1-15)
MACRO VOICE
	db $E0, \1, (\3 << 4) | \2, (\5 << 4) | \4
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
; $EA x, $EC x, $EF x, $D0-$D9 x, $DB-$DE x: no-ops (Tiny Toon: $EA octave shift, $EC envelope, $D9 NR10)
MACRO CMD_EA
	db $EA, \1
ENDM
MACRO CMD_EC
	db $EC, \1
ENDM
; $EB n, xy: vibrato table n, delay x * unit ticks, depth y
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $ED x: detune (+2x, or -2(x & $7F) when bit 7 is set)
MACRO DETUNE
	db $ED, \1
ENDM
MACRO TEMPO
	db $EE, \1
ENDM
MACRO CMD_EF
	db $EF, \1
ENDM
; $F0-$FA: attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
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
MACRO CMD_D9
	db $D9, \1
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

SECTION "rst08 carry", ROM0[$0013]

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

SECTION "Sound ROM0", ROM0[$2BED]

; SndUpdateFar (called from every VBlank): skipped while wSndLock bit 0 is set (a request
; in progress), else lock, map bank 14, SndUpdate, unlock and map back the bank the caller
; had (each bank holds its own number at $7FFF).
SndUpdateFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, [BANK_ID]
	push af
	ld a, $0E
	ld [rROMB], a
	push bc
	push de
	call SndUpdate

FarReturn:
	pop de
	pop bc
	pop af
	ld [rROMB], a
	ld hl, wSndLock
	res 0, [hl]
	ret

; PlaySoundFar: A = sound id (0 = StopAll); dropped while wSndLock bit 0 is set.
; StartFadeFar: A | $80 to wFadeReq. StopSoundFar plays 0. The game's pause code ($0460,
; $0361) sets wPauseFlag bit 0 and calls SndMute, its unpause clears it and calls SndUnpause.
PlaySoundFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld l, a
	ld a, [BANK_ID]
	push af
	ld a, $0E
	ld [rROMB], a
	ld a, l
	push bc
	push de
	call PlaySound
	jr FarReturn

StartFadeFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, [BANK_ID]
	push af
	ld a, $0E
	ld [rROMB], a
	push bc
	push de
	call StartFade
	jr FarReturn

SECTION "StopSoundFar", ROM0[$2C4D]

StopSoundFar:
	ld a, $00
	jp PlaySoundFar

SECTION "FarRead", ROM0[$3FE8]

; FarRead: A = [DE] in bank TRK_BANK of the track HL points at, then the caller's bank again.
; Every stream read of a sound with id >= $7F goes through it (`cp $7F` on TRK_ID before each
; one), and so do the arguments of most commands, whatever the id: harmless, as every header
; below $7F names bank 14.
FarRead:
	ld a, [BANK_ID]
	push af
	ld l, TRK_BANK
	ld a, [hl]
	ld [rROMB], a
	ld a, [de]
	ld l, a
	pop af
	ld [rROMB], a
	ld a, l
	ret

SECTION "Sound bank 14", ROMX[$4000], BANK[14]

; CopyBytes: copy BC bytes from HL to DE (StopAll uses it as a fill: [HL] = 0, DE = HL + 1).
CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyBytes
	ret

; SndInit: NR52 = $FF, NR51 = $FF, NR50 = $77.
SndInit:
	ld hl, rNR52
	ld a, $FF
	ld [hl], a
	dec hl
	ld [hl], a
	dec hl
	ld a, $77
	ld [hl], a
	ret

; FadeTick: while wFadeReq is set, every 3 updates wFadeLevel + 1 (off every music note's
; volume, half on CH3, with no upper limit) and wFadeStep + 1. At step $30 the drums stop:
; when SfxN is idle through Flow_End, whose `pop hl` takes this routine's return address as
; the track page (Tiny Toon's bug: the stop writes go to $40C0/$40C1 - the MBC - and the
; rest of the update is skipped), else by clearing the drum track's id and priority. The
; Ch3 and Ch1/Ch2 stops test the same step $30 after it has returned, so they are dead.
; Without a request wFadeDiv, wFadeLevel and wFadeStep are cleared every update.
FadeTick:
	ld a, [wFadeReq]
	or a
	jr nz, FadeReset.l4026

FadeReset:
	ld [wFadeDiv], a
	ld [wFadeLevel], a
	ld [wFadeStep], a
	ret
.l4026:
	ld a, [wFadeDiv]
	inc a
	ld [wFadeDiv], a
	cp $03
	jp z, .l4033
	ret
.l4033:
	xor a
	ld [wFadeDiv], a
	ld a, [wFadeLevel]
	inc a
	ld [wFadeLevel], a
	ld a, [wFadeStep]
	inc a
	ld [wFadeStep], a

FadeStopDrm:
	ld a, [wFadeStep]
	cp $30
	jp nz, FadeStopCh3
	ld hl, wTrkSfxN
	ld a, [hl]
	or a
	jr z, .l405D
	xor a
	ld hl, wTrkDrm
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ret
.l405D:
	ld hl, wTrkDrm
	jp Flow_End

FadeStopCh3:
	ld a, [wFadeStep]
	cp $30
	jp nz, FadeStopCh1Ch2
	ld hl, wTrkCh3
	jp Flow_End

FadeStopCh1Ch2:
	ld a, [wFadeStep]
	cp $30
	ret nz
	ld hl, wTrkSfx1
	ld a, [hl]
	or a
	jr z, .l4088
	xor a
	ld hl, wTrkCh1
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	jr .l408E
.l4088:
	ld hl, wTrkCh1
	call Flow_End
.l408E:
	ld hl, wTrkSfx2
	ld a, [hl]
	or a
	jr z, .l40A1
	xor a
	ld hl, wTrkCh2
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	jp FadeReset
	ret
.l40A1:
	ld hl, wTrkCh2
	call Flow_End
	xor a
	jp FadeReset

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

; CountdownTick: the word at wCountdown counted down to 0. Nothing sets wCountdown, but its
; high byte is wFadeReq (as in Zen), so a running fade request is decremented every 256
; updates (with bit 7 set it stays non-zero for the length of any fade).
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
; set only Sfx1 runs, and only while it plays $08, $0D or $1A; any other id ends the update.
; On a tempo carry (or wMusicHold) the loop ends at track 3, so the music tracks all skip the
; frame. UpdateCheckCh2 is unreachable.
SndUpdate:
	call FadeTick
	call CountdownTick
	call TempoTick
	xor a

UpdateLoop:
	ld [wTrackIdx], a
	ld a, [wPauseFlag]
	or a
	jr z, UpdateCheckSkip
	ld a, [wTrackIdx]
	cp $00
	jr nz, NextTrack
	ld a, [wTrkSfx1]
	cp $08
	jr z, RunTrack
	ld a, [wTrkSfx1]
	cp $0D
	jr z, RunTrack
	ld a, [wTrkSfx1]
	cp $1A
	jr z, RunTrack
	jr PlayQueued

UpdateCheckSkip:
	ld a, [wTrackIdx]
	cp $03
	jr nz, RunTrack
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, PlayQueued
	jr RunTrack

UpdateCheckCh2:
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
	jr z, NextTrack
	call TrackTick

NextTrack:
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
; Else: duty step, released flag; on a note (not a rest) of a tone or wave track the vibrato,
; then the CH3 decay or, at the release tick, NRx2 = env | level + retrigger.
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
	jp nz, ReadCmd
	xor a
	ld [wRegShadow + $0A], a
	ldh [rNR30], a
	jp ReadCmd

Sustain:
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l417F
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l417F:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l418B
	ld l, TRK_FLAGS
	set 0, [hl]
.l418B:
	ld l, TRK_FLAGS
	bit 7, [hl]
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	call VibratoTick
	ld a, [wTrackIdx]
	cp $05
	jr z, Ch3Decay
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
	jp TriggerReg

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
	jr c, .l41E7
	xor a
.l41E7:
	rla
	swap a

Ch3WriteLevel:
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	jp WriteReg

SustainTrigger:
	jp TriggerReg

; NextCmd / ReadCmd: every stream byte is read with `ld a, [de]` for ids < $7F and through
; FarRead for the others. $FB-$FF flow (segno, return, call, repeat/jump, end), $E0 voice,
; $D0-$DF, notes, $F0-$FA attenuation, $E1-$E6 octave, $E7-$EF through the table.
NextCmd:
	inc de

ReadCmd:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, ReadCmdNear
	call FarRead
	jp ReadCmdByte

ReadCmdNear:
	ld a, [de]

ReadCmdByte:
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
	jp ReadCmd

Flow_Ret:
	pop hl
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmd

Flow_Call:
	pop hl
	call FarRead
	ld c, a
	inc de
	call FarRead
	ld b, a
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, b
	jr ReadCmd

Flow_Repeat:
	pop hl
	call FarRead
	cp $FF
	jr z, .l4257
	ld l, TRK_REPCNT
	inc [hl]
	cp [hl]
	jr z, .l4265
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmd
.l4257:
	inc de
	call FarRead
	ld c, a
	inc de
	call FarRead
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmd
.l4265:
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
	jr nz, .l4289
	xor a
	ldh [rNR30], a
	ret
.l4289:
	cp $01
	jr z, .l4297
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l4299
.l4297:
	ld h, HIGH(wTrkCh2)
.l4299:
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
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l42BA
	call FarRead
	jp .l42BB
.l42BA:
	ld a, [de]
.l42BB:
	cp $E0
	jp z, Cmd_Voice
	and $F0
	cp $D0
	jp z, Cmd_D
	cp $E0
	jp c, Note
	cp $F0
	jp z, Cmd_Atten
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l42DF
	call FarRead
	jp .l42E0
.l42DF:
	ld a, [de]
.l42E0:
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
	dw Cmd_EA
	dw Cmd_Vibrato
	dw Cmd_EC
	dw Cmd_Detune
	dw Cmd_Tempo
	dw Cmd_EF

; Commands $E7-$EF. $EA (Tiny Toon: octave shift / transpose), $EC (envelope) and $EF are
; no-ops that skip their argument.
Cmd_LenUnit:
	pop hl
	call FarRead
	ld l, TRK_UNIT
	ld [hl], a
	jp NextCmd

Cmd_Release:
	pop hl
	call FarRead
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call FarRead
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

Cmd_DutyStep:
	pop hl
	ld l, TRK_FLAGS
	push hl
	call FarRead
	pop hl
	or a
	jr z, .l433B
	set 4, [hl]
	and $0F
	ld l, TRK_DUTYSTART
	ld [hl], a
	call FarRead
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	jp NextCmd
.l433B:
	res 4, [hl]
	jp NextCmd

Cmd_EA:
	pop hl
	jp NextCmd

Cmd_Vibrato:
	pop hl
	call FarRead
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp nz, .l4356
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp NextCmd
.l4356:
	inc de
	call FarRead
	swap a
	and $0F
	ld l, TRK_VIBDELAY
	ld [hl], a
	or a
	jp nz, .l436C
	ld l, TRK_FLAGS2
	res 7, [hl]
	jp .l4384
.l436C:
	push bc
	ld l, TRK_VIBDELAY
	ld b, [hl]
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4374:
	add a, c
	dec b
	jp nz, .l4374
	ld l, TRK_VIBDELAYRELOAD
	ld [hl], a
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
	pop bc
	ld l, TRK_FLAGS2
	set 7, [hl]
.l4384:
	call FarRead
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

Cmd_EC:
	pop hl
	jp NextCmd

Cmd_Detune:
	pop hl
	call FarRead
	ld l, TRK_DETUNE
	ld [hl], a
	jp NextCmd

Cmd_Tempo:
	pop hl
	call FarRead
	ld [wTempo], a
	jp NextCmd

Cmd_EF:
	pop hl
	jp NextCmd

Cmd_Octave:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l43D0
	call FarRead
	jp .l43D1
.l43D0:
	ld a, [de]
.l43D1:
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp NextCmd

; Cmd_Voice: TRK_ENVNO = 0, $E0 unit; drums stop there; noise: env | vol << 4 to NR42 +
; trigger (the one byte is read twice); tone and wave: vol | duty << 4, then env | gate << 4
; (always through FarRead).
Cmd_Voice:
	ld a, $00
	ld l, TRK_ENVNO
	ld [hl], a
	inc de
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l43EE
	call FarRead
	jp .l43EF
.l43EE:
	ld a, [de]
.l43EF:
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, NextCmd
	inc de
	cp $02
	jr z, VoiceNoise
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, VoiceTone
	call FarRead
	jp VoiceTone.l440E

VoiceTone:
	ld a, [de]
.l440E:
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4421
	call FarRead
	jp .l4422
.l4421:
	ld a, [de]
.l4422:
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	call FarRead
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call FarRead
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

VoiceNoise:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4450
	call FarRead
	jp .l4451
.l4450:
	ld a, [de]
.l4451:
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4464
	call FarRead
	jp .l4465
.l4464:
	ld a, [de]
.l4465:
	swap a
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l447A
	call FarRead
	jp .l447B
.l447A:
	ld a, [de]
.l447B:
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	call TriggerReg
	jp NextCmd

Cmd_Atten:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l449A
	call FarRead
	jp .l449B
.l449A:
	ld a, [de]
.l449B:
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
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l44DC
	call FarRead
	jp .l44DD
.l44DC:
	ld a, [de]
.l44DD:
	ld c, a
	ld b, $00
	jp WritePeriod

Cmd_D:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l44F1
	call FarRead
	jp .l44F2
.l44F1:
	ld a, [de]
.l44F2:
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
	dw Cmd_D9
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

Cmd_D9:
	pop hl
	jp NextCmd

Cmd_Ext:
	pop hl
	call FarRead
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
	call FarRead
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_TransposeDown:
	pop hl
	call FarRead
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
	call FarRead
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp NextCmd

Ext_Flags:
	pop hl
	call FarRead
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l4592
	or $02
	jr .l4594
.l4592:
	and $FD
.l4594:
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
	jr nz, .l45B4
	inc de
	jp NextCmd
.l45B4:
	call FarRead
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

; Note: autopan, length = lo * unit (0 = 256). Pitch = (hi - 1) + transpose + 12 * octave
; + OctaveShiftTable[shift] (only with an octave; nothing sets the shift any more), from
; PeriodTable. Release tick = length * gate / 16 (gate 15: length - 1). The note-on writes
; NRx2 = vol << 4 and triggers; the release writes env | level.
Note:
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, AutoPan
	call SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jp z, NoiseNote
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4652
	call FarRead
	jp .l4653
.l4652:
	ld a, [de]
.l4653:
	and $0F
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l465A:
	dec b
	jr z, .l4660
	add a, c
	jr .l465A
.l4660:
	ld l, TRK_LEN
	ld [hl], a
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jp z, .l4674
	ld l, TRK_FLAGS2
	set 7, [hl]
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
.l4674:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4682
	call FarRead
	jp .l4683
.l4682:
	ld a, [de]
.l4683:
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNoteFar
	cp $05
	jr z, .l46AF
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l46AF
	ld l, TRK_DUTYSTART
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegOff], a
	call WriteReg
.l46AF:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l46BC
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l46CE
.l46BC:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l46C4:
	srl c
	jr nc, .l46C9
	add a, d
.l46C9:
	rra
	dec b
	jr nz, .l46C4
	pop de
.l46CE:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBREPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, OctaveShiftTable.l4708
	ld b, a
	ld c, $0C
	xor a
.l46E1:
	add a, c
	dec b
	jr nz, .l46E1
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
	jr OctaveShiftTable.l4707
OctaveShiftTable:
	db $00, $0C, $18, $24, $30, $3C, $48, $54, $F4, $E8, $DC, $D0, $C4, $B8, $AC, $A0
.l4707:
	ld c, a
.l4708:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, .l4716
	call FarRead
	jp .l4717
.l4716:
	ld a, [de]
.l4717:
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
	jr .l4739
.l4739:
	push bc
	ld l, TRK_VIB
	ld a, [hl]
	ld l, TRK_ENVNO
	ld b, [hl]
	or b
	pop bc
	jp z, .l474F
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	ld l, TRK_ENVIDX
	ld [hl], a
	call VibratoStep
.l474F:
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

WriteNoteVolume:
	call CalcVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	jp TriggerReg

; CalcVolume: TRK_VOL - TRK_ATTEN (music: - wFadeLevel), 0 on a borrow. CH3: level code
; (vol / 2) & 3 + atten + wFadeLevel / 2, mute from 2 (Tiny Toon: from 4), so CH3 plays
; at 100 % or not at all; NR30 = $80.
CalcVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, CalcVolumeCh3
	ld a, [wTrackIdx]
	cp $03
	jr c, .l479C
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4796
	xor a
.l4796:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l479C:
	xor a
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l47AB
	xor a
.l47AB:
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
	cp $02
	jr c, .l47D9
	xor a
.l47D9:
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
	jr z, .l4800
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
.l4800:
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
	jr c, .l4818
	add a, c
	ld c, a
	jr nc, WritePeriod
	inc b
	jr WritePeriod
.l4818:
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

DrumNoteFar:
	ld l, TRK_ID
	ld a, [hl]
	cp $7F
	jp c, DrumNote
	call FarRead
	jp DrumNote.l4865

DrumNote:
	ld a, [de]
.l4865:
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = swap(duty), or on CH3 (wRegBase $0A) copy wave duty - 1 straight to wave
; RAM (no NR30 off, no blocking check).
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
.l4895:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l4895
	pop hl
	pop de
	ret

IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l48AD
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l48B6
.l48AD:
	cp $04
	jr nz, .l48B8
	ld a, [wTrkSfx2]
	or a
	ret z
.l48B6:
	scf
	ret
.l48B8:
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
	jr nz, .l48D8
	ld a, [hl]
	cp c
	jr z, .l48DB
.l48D8:
	ld a, c
	ld [hl], a
	ld [de], a
.l48DB:
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
	jp z, .l493E
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	cp $00
	jp z, .l493E
	ld l, TRK_VIBDELAYCNT
	dec [hl]
	ret nz
.l493E:
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
	jp nc, .l4964
	inc b
.l4964:
	ld a, [bc]
	cp $FB
	jr z, .l49AF
	cp $FE
	jr z, .l49B9
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
	jp z, .l4988
	ld l, TRK_FLAGS
	set 3, [hl]
	jp .l498C
.l4988:
	ld l, TRK_FLAGS
	res 3, [hl]
.l498C:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l49AB
	push bc
	xor a
	ld c, a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l49A2:
	add a, c
	dec b
	jp nz, .l49A2
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l49AB:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l49AF:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4964
.l49B9:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBREPCNT
	cp [hl]
	jr z, .l49CE
	cp $FF
	jr z, .l49C5
	inc [hl]
.l49C5:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp VibratoStep
.l49CE:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4964

VibratoHold:
	ret

PlaySound:
	call PlaySoundA
	ret

StopSound:
	ld a, $00
	call PlaySoundA
	ret

StartFade:
	set 7, a
	ld [wFadeReq], a
	ret

; PlaySoundA: 0 = StopAll. Header from SoundTable - 2 + 2 * id: priority, bank (wReqBank,
; copied to TRK_BANK of every track started), track mask, pointers. Sfx1, then (unless
; wReqRefused) Sfx2/SfxN, then (unless wReqRefused) the music tracks, then NR51 = wNR51; a
; set flag ends the request and is cleared. Each start sets wReqRefused to 1 (refused) or 0
; (started), so a refused last track leaves it set and the next request without Sfx1 is cut
; at its first check (Zen's behaviour; Tiny Toon jumped out of PlaySound instead).
PlaySoundA:
	ld [wReqId], a
	or a
	jp z, StopAll
	push af
	pop af
	ld [wReqId], a
	ld hl, SoundTable - 2
	push af
	rst $28
	pop af
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl+]
	ld [wReqBank], a
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
	jr nz, .l4A4E
	ld a, $08
	ldh [rNR10], a
	ld [wRegShadow], a
.l4A4E:
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
	ld hl, wTrkSfxN
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4A8A
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l4A8A:
	dec l
	jr StartTrack

StartDrm:
	push af
	ld a, [wNR51]
	or $88
	ld [wNR51], a
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
; $C6-$D0 cleared (the unit included; segno and return slot are not), TRK_BANK, and bits 4/5
; of TRK_FLAGS2 from a first stream byte $01 (read from bank 14 whatever the bank; no reader
; left). TRK_PAN = $FF either way.
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
	ld l, TRK_BANK
	ld a, [wReqBank]
	ld [hl], a
	ld l, TRK_FLAGS
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
	jr .l4AEB
.l4AEB:
	ld l, TRK_BANK
	ld a, [wReqBank]
	ld [hl], a
	push de
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld l, TRK_PTR + 1
	ld d, [hl]
	ld a, [de]
	cp $01
	jr nz, .l4B07
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l4B10
.l4B07:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l4B10
.l4B10:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

StartRefused:
	inc de
	inc de
	ld a, $01

StartTrackEnd:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop af
	ret

; StopAll: clear $C0-$FA of the seven track pages, the shadows and the globals; wNR51 = $FF
; (not written), then SndMute.
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $003A
	ld [hl], $00
	call CopyBytes
	ld hl, wRegShadow
	ld de, wRegShadow + $01
	ld bc, $0014
	ld [hl], $00
	call CopyBytes
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0020
	ld [hl], $00
	call CopyBytes
	ld a, $FF
	ld [wNR51], a

; SndMute (also the game's pause): NR12 = 0 unless the last request was $0D or $1A, then
; NR17/NR21/NR32 = 0.
SndMute:
	ld a, [wReqId]
	cp $0D
	jp z, .l4BC0
	ld a, [wReqId]
	cp $1A
	jp z, .l4BC0
	ld a, $00
	ldh [rNR12], a
.l4BC0:
	ld a, $00
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; SndUnpause (the game's unpause, unless wPauseFlag or wMusicHold is set): copy the shadows
; back to the registers of every channel with a playing track, without a trigger.
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
	jr z, .l4BE7
	ld hl, wRegShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l4BE7:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l4BFC
	ld hl, wRegShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l4BFC:
	ld a, [wTrkCh3]
	or a
	jr z, .l4C0D
	ld hl, wRegShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l4C0D:
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

; PeriodTable: 85 periods from C of octave 1.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; WaveTable: CH3 waves by duty - 1 (15 pointers to 13 waves).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData1 ; wave 2
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
	dw WaveData13 ; wave 14
	dw WaveData15 ; wave 15

; Waves (16 bytes each). The last two bytes of the last wave are also SoundTable entry 0.
WaveData1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData3:
	db $D9, $BB, $CB, $DC, $FC, $A7, $67, $88, $76, $88, $74, $20, $24, $33, $43, $62
WaveData4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData5:
	db $88, $76, $54, $32, $45, $67, $89, $77, $88, $99, $AA, $BB, $CD, $DE, $EF, $FF
WaveData6:
	db $00, $00, $00, $00, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
WaveData7:
	db $88, $88, $88, $88, $77, $66, $55, $44, $00, $00, $00, $00, $00, $00, $00, $00
WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
WaveData9:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $88, $88, $FF, $FF, $88, $88, $00, $00
WaveData10:
	db $13, $57, $9B, $97, $53, $11, $35, $79, $BD, $FD, $B9, $75, $31, $13, $53, $10
WaveData11:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
WaveData12:
	db $23, $34, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE
WaveData13:
	db $78, $88, $88, $CF, $CA, $75, $20, $25, $78, $88, $88, $CF, $CA, $75, $20, $25
WaveData15:
	db $00, $58, $00, $00, $00, $00, $00, $00, $00, $58, $00, $00, $00, $00, $00, $00

; SoundTable: ids $01-$8F (PlaySoundA reads it from SoundTable - 2).
SoundTable:
	dw SndHdr01 ; $01
	dw SndHdr01 ; $02
	dw SndHdr01 ; $03
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

SndHdr08:
	SND_HEADER $80, 14, $01 ; tracks: Sfx1
	dw Snd08_Sfx1

SndHdr09:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0A:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd0A_Sfx1

SndHdr0B:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $80, 14, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $08, 14, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $13, 14, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $28, 14, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $08, 14, $04 ; tracks: SfxN
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $08, 14, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $50, 14, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $50, 14, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $50, 14, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $38, 14, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $35, 14, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $05, 14, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $05, 14, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $13, 14, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $05, 14, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $1E, 14, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr1F:
	SND_HEADER $60, 14, $04 ; tracks: SfxN
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $2A, 14, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $05, 14, $04 ; tracks: SfxN
	dw Snd25_SfxN

SndHdr27:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr26:
	SND_HEADER $05, 14, $01 ; tracks: Sfx1
	dw Snd26_Sfx1

SndHdr28:
	SND_HEADER $05, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd28_Sfx1
	dw Snd28_Sfx2

SndHdr29:
	SND_HEADER $10, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $10, 14, $04 ; tracks: SfxN
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $05, 14, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd2B_Ch1
	dw Snd2B_Ch2
	dw Snd2B_Ch3

SndHdr2C:
	SND_HEADER $18, 14, $04 ; tracks: SfxN
	dw Snd2C_SfxN

SndHdr2D:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd2D_Sfx1

SndHdr2E:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd2E_Sfx1

SndHdr2F:
	SND_HEADER $28, 14, $01 ; tracks: Sfx1
	dw Snd2F_Sfx1

SndHdr30:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd30_Sfx1

SndHdr31:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd31_Sfx1

SndHdr32:
	SND_HEADER $14, 14, $01 ; tracks: Sfx1
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd35_Sfx1

SndHdr36:
	SND_HEADER $40, 14, $02 ; tracks: Sfx2
	dw Snd35_Sfx1

SndHdr37:
	SND_HEADER $50, 14, $02 ; tracks: Sfx2
	dw Snd37_Sfx2

SndHdr38:
	SND_HEADER $10, 14, $04 ; tracks: SfxN
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd39_Sfx1

SndHdr3A:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd3B_Sfx1

SndHdr3C:
	SND_HEADER $15, 14, $04 ; tracks: SfxN
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $40, 14, $04 ; tracks: SfxN
	dw Snd3D_SfxN

SndHdr3E:
	SND_HEADER $18, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $13, 14, $01 ; tracks: Sfx1
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $13, 14, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $13, 14, $01 ; tracks: Sfx1
	dw Snd43_Sfx1

SndHdr44:
	SND_HEADER $13, 14, $04 ; tracks: SfxN
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $13, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd45_Sfx1
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $08, 14, $01 ; tracks: Sfx1
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $30, 14, $04 ; tracks: SfxN
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $0C, 14, $04 ; tracks: SfxN
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd49_Sfx1

SndHdr4A:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd4B_Sfx1

SndHdr4C:
	SND_HEADER $60, 14, $01 ; tracks: Sfx1
	dw Snd4C_Sfx1

SndHdr4D:
	SND_HEADER $34, 14, $04 ; tracks: SfxN
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $60, 14, $01 ; tracks: Sfx1
	dw Snd4E_Sfx1

SndHdr4F:
	SND_HEADER $50, 14, $04 ; tracks: SfxN
	dw Snd4D_SfxN

SndHdr50:
	SND_HEADER $15, 14, $04 ; tracks: SfxN
	dw Snd50_SfxN

SndHdr51:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd52_Sfx1

SndHdr53:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd53_Sfx1

SndHdr54:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd54_Sfx1

SndHdr55:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd55_Sfx1

SndHdr56:
	SND_HEADER $10, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd56_Sfx1
	dw Snd56_Sfx2

SndHdr57:
	SND_HEADER $35, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd57_Sfx1
	dw Snd57_Sfx2

SndHdr58:
	SND_HEADER $28, 14, $04 ; tracks: SfxN
	dw Snd58_SfxN

SndHdr59:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd59_Sfx1

SndHdr5A:
	SND_HEADER $10, 14, $04 ; tracks: SfxN
	dw Snd5A_SfxN

SndHdr5B:
	SND_HEADER $18, 14, $02 ; tracks: Sfx2
	dw Snd5B_Sfx2

SndHdr5C:
	SND_HEADER $18, 14, $01 ; tracks: Sfx1
	dw Snd5C_Sfx1

SndHdr5D:
	SND_HEADER $20, 14, $04 ; tracks: SfxN
	dw Snd5D_SfxN

SndHdr5E:
	SND_HEADER $60, 14, $01 ; tracks: Sfx1
	dw Snd5E_Sfx1

SndHdr5F:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd5F_Sfx1

SndHdr60:
	SND_HEADER $10, 14, $04 ; tracks: SfxN
	dw Snd60_SfxN

SndHdr61:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd61_Sfx1

SndHdr62:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd62_Sfx1

SndHdr63:
	SND_HEADER $48, 14, $04 ; tracks: SfxN
	dw Snd63_SfxN

SndHdr64:
	SND_HEADER $30, 14, $04 ; tracks: SfxN
	dw Snd64_SfxN

SndHdr65:
	SND_HEADER $40, 14, $04 ; tracks: SfxN
	dw Snd64_SfxN

SndHdr66:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd66_Sfx1

SndHdr67:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd67_Sfx1

SndHdr68:
	SND_HEADER $20, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd68_Sfx1
	dw Snd68_SfxN

SndHdr69:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd69_Sfx1

SndHdr6A:
	SND_HEADER $20, 14, $04 ; tracks: SfxN
	dw Snd6A_SfxN

SndHdr6B:
	SND_HEADER $50, 14, $02 ; tracks: Sfx2
	dw Snd6B_Sfx2

SndHdr6C:
	SND_HEADER $50, 14, $02 ; tracks: Sfx2
	dw Snd6C_Sfx2

SndHdr6D:
	SND_HEADER $20, 14, $04 ; tracks: SfxN
	dw Snd6D_SfxN

SndHdr6E:
	SND_HEADER $20, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd6E_Sfx1
	dw Snd6E_SfxN

SndHdr6F:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd6F_Sfx1

SndHdr70:
	SND_HEADER $20, 14, $04 ; tracks: SfxN
	dw Snd70_SfxN

SndHdr71:
	SND_HEADER $20, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd71_Sfx1
	dw Snd71_SfxN

SndHdr72:
	SND_HEADER $20, 14, $05 ; tracks: Sfx1, SfxN
	dw Snd72_Sfx1
	dw Snd72_SfxN

SndHdr73:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd73_Ch1
	dw Snd73_Ch2
	dw Snd73_Ch3
	dw Snd73_Drm

SndHdr74:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd74_Ch1
	dw Snd74_Ch2
	dw Snd74_Ch3
	dw Snd74_Drm

SndHdr75:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd75_Ch1
	dw Snd75_Ch2
	dw Snd75_Ch3
	dw Snd75_Drm

SndHdr76:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd76_Ch1
	dw Snd76_Ch2
	dw Snd76_Ch3
	dw Snd76_Drm

SndHdr77:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd77_Ch1
	dw Snd77_Ch2
	dw Snd77_Ch3
	dw Snd77_Drm

SndHdr78:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd78_Ch1
	dw Snd78_Ch2
	dw Snd78_Ch3
	dw Snd78_Drm

SndHdr79:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd79_Ch1
	dw Snd79_Ch2
	dw Snd79_Ch3
	dw Snd79_Drm

SndHdr7A:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7A_Ch1
	dw Snd7A_Ch2
	dw Snd7A_Ch3
	dw Snd7A_Drm

SndHdr7B:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7B_Ch1
	dw Snd7B_Ch2
	dw Snd7B_Ch3
	dw Snd7B_Drm

SndHdr7C:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7C_Ch1
	dw Snd7C_Ch2
	dw Snd7C_Ch3
	dw Snd7C_Drm

SndHdr7D:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7D_Ch1
	dw Snd7D_Ch2
	dw Snd7D_Ch3
	dw Snd7D_Drm

SndHdr7E:
	SND_HEADER $40, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7E_Ch1
	dw Snd7E_Ch2
	dw Snd7E_Ch3
	dw Snd7E_Drm

SndHdr7F:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd7F_Ch1
	dw Snd7F_Ch2
	dw Snd7F_Ch3
	dw Snd7F_Drm

SndHdr80:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd80_Ch1
	dw Snd80_Ch2
	dw Snd80_Ch3
	dw Snd80_Drm

SndHdr81:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd81_Ch1
	dw Snd81_Ch2
	dw Snd81_Ch3
	dw Snd81_Drm

SndHdr82:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd82_Ch1
	dw Snd82_Ch2
	dw Snd82_Ch3
	dw Snd82_Drm

SndHdr83:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd83_Ch1
	dw Snd83_Ch2
	dw Snd83_Ch3
	dw Snd83_Drm

SndHdr84:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd84_Ch1
	dw Snd84_Ch2
	dw Snd84_Ch3
	dw Snd84_Drm

SndHdr85:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd85_Ch1
	dw Snd85_Ch2
	dw Snd85_Ch3
	dw Snd84_Drm

SndHdr86:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd86_Ch1
	dw Snd86_Ch2
	dw Snd86_Ch3
	dw Snd86_Drm

SndHdr87:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd87_Ch1
	dw Snd87_Ch2
	dw Snd87_Ch3
	dw Snd87_Drm

SndHdr88:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd88_Ch1
	dw Snd88_Ch2
	dw Snd88_Ch3
	dw Snd88_Drm

SndHdr89:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd89_Ch1
	dw Snd89_Ch2
	dw Snd89_Ch3
	dw Snd89_Drm

SndHdr8A:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8A_Ch1
	dw Snd8A_Ch2
	dw Snd8A_Ch3
	dw Snd8A_Drm

SndHdr8B:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8B_Ch1
	dw Snd8B_Ch2
	dw Snd8B_Ch3
	dw Snd8B_Drm

SndHdr8C:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8C_Ch1
	dw Snd8C_Ch2
	dw Snd8C_Ch3
	dw Snd8C_Drm

SndHdr8D:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8D_Ch1
	dw Snd8D_Ch2
	dw Snd8D_Ch3
	dw Snd8D_Drm

SndHdr8E:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8E_Ch1
	dw Snd8E_Ch2
	dw Snd8E_Ch3
	dw Snd8E_Drm

SndHdr8F:
	SND_HEADER $40, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8F_Ch1
	dw Snd8F_Ch2
	dw Snd8F_Ch3
	dw Snd8F_Drm

; DrumMap: drum note hi - 1 -> sound id.
DrumMap:
	db $01, $02, $03, $04, $05, $06, $07

SndHdr01:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr04:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr07:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd07_SfxN

SndHdr06:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd06_SfxN

Snd01_SfxN:
	NVOICE $01, $51
	NOISE $15
	SND_END

Snd04_SfxN:
	NVOICE $01, $91
	NOISE $4F
	NOISE $14
	SND_END

Snd05_SfxN:
	NVOICE $01, $71
	NOISE $58
	NOISE $6A
	SND_END

Snd06_SfxN:
	NVOICE $01, $41
	NOISE $40
	NVOICE $40, $63
	NOISE $00
	SND_END

Snd07_SfxN:
	NVOICE $01, $00
	NOISE $34
	SND_END

; VibratoTable: 11 pointers (EB n uses entry n).
VibratoTable:
	dw Vib01 ; 1
	dw Vib01 ; 2
	dw Vib03 ; 3
	dw Vib03 ; 4
	dw Vib03 ; 5
	dw Vib06 ; 6
	dw Vib06 ; 7
	dw Vib08 ; 8
	dw Vib08 ; 9
	dw Vib08 ; 10
	dw Vib0B ; 11

Vib01:
	VIB_SEGNO
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 0, 2
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 1, 2
	VIB_REPEAT $FF

Vib03:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_END

Vib06:
	VIB_SEGNO
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 0, 4
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 1, 2
	VIB_REPEAT $FF

Vib08:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_REPEAT $FF

Vib0B:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 0, 0
	VIB_REPEAT $FF
	db $FF ; unused byte after the last vibrato table

Snd08_Sfx1:
	VOICE $03, 15, 8, 1, 15
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 3
	SND_END

Snd09_Sfx1:
	TRANSPOSE_UP 5
	VOICE $01, 15, 8, 15, 0
	SND_CALL Snd09_Sfx1_52E6

Snd53_Sfx1:
	VOICE $02, 15, 8, 15, 0
	SND_CALL Snd09_Sfx1_52E6
Snd09_Sfx1_52E6:
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 6
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE A#, 1
	NOTE B_, 1
	SND_END

Snd0A_Sfx1:
	VOICE $02, 13, 12, 15, 0
	OCTAVE 5
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 6
	OCTAVE 6
	NOTE E_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE A_, 2
	OCTAVE 6
	NOTE E_, 2
	SND_END

Snd0B_Sfx1:
	VOICE $03, 13, 12, 15, 0
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE G_, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd0C_Sfx1:
	VOICE $02, 15, 12, 15, 0
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	ATTEN 5
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
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
	NOTE C#, 1
	NOTE C_, 1
	ATTEN $0A
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
	NOTE C_, 1
	SND_END

Snd0D_Sfx1:
	VOICE $01, 12, 8, 15, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE F#, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE F#, 2
	SND_END

Snd0E_Sfx1:
	VOICE $02, 12, 8, 5, 15
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 7
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE A_, 1
	ATTEN $0A
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	SND_END

Snd0F_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 3
	NOTE C_, 3
	REST 3
	NOTE G_, 1
	ATTEN 7
	SND_SEGNO
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN $0A
	SND_REPEAT $02
	SND_END

Snd10_Sfx1:
	VOICE $01, 15, 12, 5, 15
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE B_, 1
	ATTEN 6
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_END

Snd11_Sfx1:
	TRANSPOSE_UP 3
	VOICE $01, 15, 8, 15, 0
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	ATTEN $0A
	SND_REPEAT $02
	SND_END

Snd12_SfxN:
	NVOICE $02, $98
	NOISE $31
	SND_END

Snd14_Sfx1:
	VOICE $02, 15, 8, 15, 0
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_END

Snd15_Sfx1:
	VOICE $02, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE F_, 1
	SND_END

Snd16_Sfx1:
	VOICE $01, 15, 8, 15, 0
	TRANSPOSE_DOWN $0C
	SND_CALL Snd16_Sfx1_53F2
	TRANSPOSE_UP 0
	SND_CALL Snd16_Sfx1_53F2
	TRANSPOSE_UP $0C
	SND_CALL Snd16_Sfx1_53F2
	SND_END
Snd16_Sfx1_53F2:
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	SND_RET

Snd17_Sfx1:
	VOICE $02, 15, 12, 15, 0
	OCTAVE 4
	NOTE C_, 1
	REST 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	ATTEN 5
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	ATTEN 8
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE A#, 1
	NOTE F#, 1
	SND_END

Snd18_Sfx1:
	VOICE $02, 15, 0, 3, 15
	OCTAVE 3
	NOTE C_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_END

Snd19_Sfx1:
	VOICE $01, 15, 8, 15, 0
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 6
	SND_REPEAT $03
	SND_END

Snd1A_Sfx1:
	VOICE $01, 10, 0, 15, 0
	OCTAVE 2
	ATTEN 7
	NOTE E_, 5
	ATTEN 5
	NOTE F_, 3
	ATTEN 3
	NOTE F#, 3
	ATTEN 5
	NOTE G_, 1
	ATTEN 7
	NOTE F#, 8
	ATTEN 8
	NOTE F_, 8
	SND_END

Snd1B_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 2
	ATTEN 7
	NOTE E_, 5
	ATTEN 5
	NOTE F_, 3
	ATTEN 3
	NOTE F#, 3
	ATTEN 5
	NOTE G_, 1
	ATTEN 7
	NOTE F#, 8
	ATTEN 8
	NOTE F_, 8
	SND_END

Snd1C_Sfx1:
	VOICE $01, 9, 8, 0, 0
	OCTAVE 4
	SND_CALL Snd1C_Sfx1_5487

Snd1D_Sfx1:
	VOICE $01, 15, 8, 0, 0
	OCTAVE 2
	SND_CALL Snd1C_Sfx1_5487
Snd1C_Sfx1_5487:
	SND_CALL Snd1C_Sfx1_54A3
	TRANSPOSE_UP 1
	ATTEN 2
	SND_CALL Snd1C_Sfx1_54A3
	TRANSPOSE_UP 2
	ATTEN 4
	SND_CALL Snd1C_Sfx1_54A3
	TRANSPOSE_UP 3
	ATTEN 6
	SND_CALL Snd1C_Sfx1_54A3
	TRANSPOSE_UP 5
	ATTEN 8
	SND_CALL Snd1C_Sfx1_54A3
	SND_END
Snd1C_Sfx1_54A3:
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_RET

Snd1E_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 6
	NOTE A#, 2
	ATTEN $0A
	NOTE A#, 2
	ATTEN 0
	VOICE $04, 3, 0, 15, 0
	NOTE A#, 3
	SND_END

Snd1F_SfxN:
	NVOICE $05, $F2
	NOISE $79
	NOISE $31
	NOISE $13
	NOISE $15
	SND_END

Snd20_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 15, 0, 15, 0
	OCTAVE 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE C#, 5
	SND_END

Snd21_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 12, 12, 15, 0
	OCTAVE 3
	ATTEN 8
	SND_CALL Snd21_Sfx1_54EF
	ATTEN 6
	SND_CALL Snd21_Sfx1_54EF
	ATTEN 4
	SND_CALL Snd21_Sfx1_54EF
	ATTEN 2
	SND_CALL Snd21_Sfx1_54EF
	ATTEN 0
	SND_CALL Snd21_Sfx1_54EF
	ATTEN $0A
	SND_CALL Snd21_Sfx1_54EF
	SND_END
Snd21_Sfx1_54EF:
	SND_SEGNO
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	SND_REPEAT $02
	SND_RET

Snd22_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE E_, 1
	REST 8
	DUTY 8
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 6
	OCTAVE 3
	NOTE F#, 1
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 2
	NOTE F#, 1
	NOTE C_, 1
	SND_END

Snd23_Sfx1:
	VOICE $01, 10, 0, 15, 0
	OCTAVE 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE C_, 3
	ATTEN 7
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE C_, 3
	SND_END

Snd24_Sfx1:
	TRANSPOSE_UP 3
	VOICE $03, 12, 12, 15, 0
	OCTAVE 5
	NOTE E_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE C#, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE A_, 1
	SND_END

Snd25_SfxN:
	NVOICE $02, $D5
	NOISE $41
	NOISE $21
	NOISE $11
	NOISE $21
	NOISE $11
	NOISE $11
	NOISE $11
	SND_END

Snd26_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	SND_SEGNO
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	ATTEN $0A
	SND_REPEAT $02
	SND_END

Snd27_Sfx1:
	VOICE $05, 15, 8, 15, 0
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 6
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd3A_Sfx1:
	VOICE $02, 13, 8, 15, 0
	TRANSPOSE_UP $0A
	SND_CALL Snd13_Sfx1_5577

Snd13_Sfx1:
	VOICE $02, 13, 0, 15, 0
Snd13_Sfx1_5577:
	OCTAVE 3
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 6
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 8
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	ATTEN $0A
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_END

Snd28_Sfx1:
	VOICE $02, 13, 0, 15, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 5
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 7
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN $0A
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_END

Snd28_Sfx2:
	TRANSPOSE_UP 5
	VOICE $02, 5, 0, 15, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_END

Snd39_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd29_Sfx1:
	TRANSPOSE_UP $0C
	VOICE $01, 15, 12, 15, 0
	SND_SEGNO
	OCTAVE 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 7
	SND_REPEAT $03
	SND_END

Snd29_SfxN:
	NVOICE $04, $F3
	NOISE $41
	NOISE $37
	NOISE $52
	NOISE $37
	NOISE $52
	NVOICE $04, $A7
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	ATTEN 4
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	SND_END

Snd2A_SfxN:
	NVOICE $04, $F3
	NOISE $41
	NOISE $37
	NOISE $52
	NOISE $37
	NOISE $52
	NVOICE $04, $F7
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	ATTEN 4
	NOISE $14
	NOISE $62
	NOISE $41
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $41
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $41
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $41
	NOISE $62
	NOISE $14
	NOISE $62
	NOISE $34
	NOISE $62
	SND_END

Snd2B_Ch1:
	TRANSPOSE_DOWN 5
	VOICE $0C, 4, 12, 0, 0
	OCTAVE 5
	NOTE B_, 3
	ATTEN 2
	NOTE B_, 2
	SND_END

Snd2B_Ch2:
	TRANSPOSE_UP $0A
	VOICE $0C, 2, 8, 15, 0
	OCTAVE 5
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	SND_END

Snd2B_Ch3:
	TRANSPOSE_DOWN 1
	VOICE $0C, 2, 4, 7, 10
	OCTAVE 6
	NOTE C_, 3
	SND_END

; Orphan Sfx1 streams (no header points here).
Data_5662:
	TRANSPOSE_DOWN 5
	VOICE $0D, 6, 12, 0, 0
	OCTAVE 5
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 3
	SND_END
Data_566D:
	TRANSPOSE_UP $0A
	VOICE $0D, 2, 8, 15, 0
	OCTAVE 5
	NOTE E_, 4
	SND_END
Data_5676:
	TRANSPOSE_DOWN 1
	VOICE $0D, 2, 4, 7, 10
	OCTAVE 6
	NOTE C_, 3
	SND_END
Data_567F:
	TRANSPOSE_DOWN 1
	VOICE $0D, 6, 4, 7, 10
	OCTAVE 6
	NOTE C_, 3
	SND_END

Snd2C_SfxN:
	NVOICE $03, $F3
	NOISE $5B
	NOISE $11
	NOISE $61
	SND_END

Snd2D_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 3
	SND_SEGNO
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	SND_REPEAT $02
	SND_END

Snd2E_Sfx1:
	VOICE $04, 8, 8, 15, 0
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_END

Snd2F_Sfx1:
	VOICE $02, 13, 0, 15, 0
	OCTAVE 5
	SND_CALL Snd2F_Sfx1_56D4
	OCTAVE 6
	SND_CALL Snd2F_Sfx1_56D4
	LEN_UNIT 4
	SND_CALL Snd2F_Sfx1_56C7
	OCTAVE 5
	ATTEN 3
	SND_CALL Snd2F_Sfx1_56C7
	OCTAVE 4
	ATTEN 5
	SND_CALL Snd2F_Sfx1_56C7
	OCTAVE 3
	ATTEN 8
	SND_CALL Snd2F_Sfx1_56C7
	SND_END
Snd2F_Sfx1_56C7:
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
Snd2F_Sfx1_56D4:
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
	SND_RET

Snd30_Sfx1:
	VOICE $01, 13, 12, 15, 0
	OCTAVE 6
	NOTE G_, 1
	REST 1
	NOTE A_, 3
	SND_END

Snd31_Sfx1:
	VOICE $01, 13, 12, 15, 0
	OCTAVE 6
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 7
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd32_Sfx1:
	VOICE $01, 13, 8, 15, 0
	OCTAVE 4
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	REST 2
	ATTEN $0A
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_END

Snd33_Sfx1:
	VOICE $01, 13, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	REST 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_END

Snd34_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	REST 1
	NOTE G_, 1
	ATTEN 3
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_END

Snd37_Sfx2:
	TRANSPOSE_DOWN $0F

Snd35_Sfx1:
	VOICE $02, 13, 12, 15, 0
	OCTAVE 6
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
	OCTAVE 5
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 3
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN $0A
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd38_SfxN:
	NVOICE $02, $A1
	NOISE $79
	NOISE $41
	NOISE $31
	SND_END

Snd3B_Sfx1:
	TRANSPOSE_UP 6
	VOICE $01, 13, 0, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_END

Snd3C_SfxN:
	NVOICE $05, $A6
	NOISE $31
	NOISE $41
	NOISE $31
	NOISE $24
	NOISE $14
	NOISE $11
	NOISE $24
	NOISE $41
	NOISE $23
	NOISE $14
	SND_END

Snd3D_SfxN:
	NVOICE $04, $F4
	NOISE $41
	NOISE $71
	NOISE $79
	NOISE $51
	NOISE $41
	NOISE $79
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd3E_Sfx1:
	VOICE $01, 12, 8, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	SND_END

Snd3E_SfxN:
	NVOICE $02, $F1
	NOISE $4D
	NOISE $6F
	NVOICE $03, $F1
	NOISE $71
	NOISE $6F
	SND_END

Snd3F_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	SND_SEGNO
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 3
	ATTEN $0A
	SND_REPEAT $02
	SND_END

Snd4B_Sfx1:
	TRANSPOSE_DOWN 8

Snd40_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_END

Snd41_Sfx1:
	VOICE $04, 12, 0, 15, 0
	VIBRATO $04, 0, 15
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 3
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	ATTEN 6
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	ATTEN 8
	OCTAVE 5
	NOTE A_, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE A#, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd42_Sfx1:
	VOICE $07, 15, 12, 15, 0
	VIBRATO $04, 0, 15
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	ATTEN 4
	NOTE C_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN $0A
	NOTE G_, 1
	SND_END

Snd43_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN $0A
	OCTAVE 3
	NOTE D_, 2
	REST 1
	NOTE G_, 1
	SND_END

Snd44_SfxN:
	NVOICE $01, $F1
	NOISE $15
	NOISE $3C
	NOISE $4B
	SND_END

Snd45_Sfx1:
	VOICE $01, 8, 12, 15, 0
	OCTAVE 2
	NOTE C_, 2
	SND_END

Snd45_SfxN:
	NVOICE $02, $A1
	NOISE $41
	NOISE $21
	NVOICE $02, $53
	NOISE $11
	SND_END

Snd47_SfxN:
	NVOICE $03, $F2
	NOISE $31
	NOISE $5C
	NOISE $6D
	NOISE $5D
	NOISE $3D
	NOISE $4D
	SND_END

Snd48_SfxN:
	NVOICE $02, $72
	NOISE $45
	NOISE $44
	NOISE $45
	SND_END

Snd46_Sfx1:
	TRANSPOSE_DOWN 2
	VOICE $01, 14, 8, 15, 0
	REST 4
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	ATTEN $0A
	SND_REPEAT $02
	SND_END

Snd49_Sfx1:
	VOICE $01, 12, 8, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd4C_Sfx1:
	VOICE $01, 15, 0, 15, 0
	SND_CALL Snd4C_Sfx1_587B
	ATTEN 3
	SND_CALL Snd4C_Sfx1_587B
	ATTEN 5
	SND_CALL Snd4C_Sfx1_587B
	ATTEN 8
	SND_CALL Snd4C_Sfx1_587B
	ATTEN $0A
	SND_CALL Snd4C_Sfx1_587B
	SND_END
Snd4C_Sfx1_587B:
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_RET

Snd4D_SfxN:
	NVOICE $03, $F7
	NOISE $3D
	NOISE $4D
	NOISE $5D
	NOISE $6D
	NOISE $5D
	NOISE $4D
	SND_END

Snd4E_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 4
	NOTE C_, 3
	NOTE F#, 1
	SND_SEGNO
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_REPEAT $0E
	ATTEN $0A
	SND_SEGNO
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_REPEAT $05
	SND_END

Snd50_SfxN:
	NVOICE $0A, $F5
	NOISE $71
	NOISE $61
	NOISE $71
	NOISE $61
	NVOICE $0A, $57
	NOISE $61
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd51_Sfx1:
	VOICE $02, 12, 8, 15, 0
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN $0A
	OCTAVE 2
	NOTE D_, 1
	ATTEN 2
	OCTAVE 4
	NOTE F_, 1
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	ATTEN 6
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 7
	OCTAVE 3
	NOTE F_, 1
	ATTEN 8
	OCTAVE 4
	NOTE F_, 1
	ATTEN 7
	OCTAVE 3
	NOTE F_, 1
	ATTEN 8
	OCTAVE 4
	NOTE F_, 1
	ATTEN 9
	OCTAVE 3
	NOTE F_, 1
	ATTEN $0A
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	SND_END

Snd52_Sfx1:
	VOICE $01, 13, 8, 15, 0
	OCTAVE 4
	NOTE G_, 1
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 8
	NOTE A#, 1
	ATTEN $0A
	NOTE A#, 7
	SND_END

Snd55_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 5
	NOTE C_, 2
	NOTE A_, 1
	SND_END

Snd54_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	REST 3
	SND_SEGNO
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	SND_REPEAT $06
	SND_END

Snd56_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 5
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	OCTAVE 6
	NOTE C_, 3
	ATTEN $0A
	OCTAVE 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	OCTAVE 6
	NOTE C_, 4
	SND_END

Snd56_Sfx2:
	DETUNE $01
	VOICE $01, 3, 12, 15, 0
	OCTAVE 5
	NOTE G_, 7
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	OCTAVE 6
	NOTE C_, 3
	ATTEN 1
	OCTAVE 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	SND_END

Snd57_Sfx1:
	DUTY_STEP 1, 8
	VOICE $01, 15, 0, 2, 15
	OCTAVE 3
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE D_, 8
	OCTAVE 3
	NOTE A#, 8
	OCTAVE 4
	NOTE D_, 8
	NOTE F_, 8
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 8
	DUTY_STEP_OFF
	RELEASE 0, $0F
	NOTE A#, $0F
	VIBRATO $08, 0, 1
	NOTE A#, $0F
	NOTE A#, 8
	SND_END

Snd57_Sfx2:
	VOICE $01, 8, 12, 2, 15
	OCTAVE 3
	NOTE F_, 8
	NOTE D_, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE D_, 8
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 8
	RELEASE 0, $0F
	NOTE D_, $0F
	NOTE D_, $0F
	NOTE D_, 8
	SND_END

Snd58_SfxN:
	NVOICE $02, $45
	NOISE $41
	NOISE $5D
	NVOICE $02, $F2
	NOISE $5C
	NOISE $51
	NOISE $41
	SND_END

Snd59_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 3
	NOTE C_, 2
	NOTE F#, 1
	NOTE F_, 1
	VOICE $01, 6, 8, 15, 0
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 3
	SND_END

Snd5A_SfxN:
	NVOICE $09, $A7
	NOISE $61
	NOISE $71
	NOISE $61
	NOISE $71
	SND_END

Snd6C_Sfx2:
	TRANSPOSE_DOWN 8
	VOICE $01, 15, 12, 15, 0
	OCTAVE 3
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 7
	SND_CALL Snd5B_Sfx2_5A69
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 6
	ATTEN 2
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 5
	ATTEN 4
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 4
	ATTEN 6
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 3
	ATTEN 7
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 2
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_DOWN 1
	ATTEN 8
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 0
	ATTEN 9
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 1
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 1
	ATTEN $0A
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 2
	SND_CALL Snd5B_Sfx2_5A69
	VOICE $01, 4, 12, 15, 0
	OCTAVE 3
	TRANSPOSE_UP 3
	ATTEN 0
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 4
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 5
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 6
	ATTEN 1
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 7
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 8
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 9
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0A
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0B
	ATTEN 2
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0C
	SND_CALL Snd5B_Sfx2_5A69
	SND_END

Snd5B_Sfx2:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 3
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 2
	ATTEN 2
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 4
	ATTEN 4
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 6
	ATTEN 6
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 8
	ATTEN 8
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0A
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0C
	SND_CALL Snd5B_Sfx2_5A69
	ATTEN 9
	TRANSPOSE_UP $0E
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP $0F
	SND_CALL Snd5B_Sfx2_5A69
	SND_END
Snd5B_Sfx2_5A69:
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 1
	SND_RET

Snd69_Sfx1:
	VOICE $01, 13, 8, 15, 0
	OCTAVE 4
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 2
	ATTEN 3
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 4
	ATTEN 6
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 6
	ATTEN 8
	SND_CALL Snd5B_Sfx2_5A69
	TRANSPOSE_UP 8
	ATTEN $0A
	SND_CALL Snd5B_Sfx2_5A69
	SND_END

Snd5C_Sfx1:
	TRANSPOSE_UP $0F
	VOICE $01, 15, 12, 0, 0
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP $0E
	ATTEN 2
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP $0C
	ATTEN 4
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP $0A
	ATTEN 6
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP 8
	ATTEN 8
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP 6
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP 4
	SND_CALL Snd5C_Sfx1_5ACA
	ATTEN $0A
	TRANSPOSE_UP 2
	SND_CALL Snd5C_Sfx1_5ACA
	TRANSPOSE_UP 0
	SND_CALL Snd5C_Sfx1_5ACA
	SND_END
Snd5C_Sfx1_5ACA:
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_RET

Snd5D_SfxN:
	NVOICE $04, $A7
	NOISE $31
	NOISE $5D
	NOISE $31
	NOISE $5D
	NOISE $51
	NOISE $31
	NOISE $51
	SND_END

Snd5E_Sfx1:
	VOICE $01, 13, 12, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_SEGNO
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_REPEAT $08
	ATTEN $0A
	SND_SEGNO
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_REPEAT $04
	SND_END

Snd5F_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_END

Snd60_SfxN:
	NVOICE $03, $F4
	NOISE $41
	NOISE $71
	NOISE $79
	NOISE $51
	NOISE $41
	NOISE $79
	NOISE $31
	NOISE $15
	SND_END

Snd61_Sfx1:
	TRANSPOSE_UP 8
	VOICE $01, 15, 8, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	SND_END

Snd62_Sfx1:
	VOICE $03, 12, 8, 15, 0
	REST 3
	OCTAVE 3
	SND_CALL Snd62_Sfx1_5B3C
	ATTEN 5
	SND_CALL Snd62_Sfx1_5B3C
	ATTEN 7
	SND_CALL Snd62_Sfx1_5B3C
	ATTEN 8
	SND_CALL Snd62_Sfx1_5B3C
	ATTEN $0A
	SND_CALL Snd62_Sfx1_5B3C
	SND_END
Snd62_Sfx1_5B3C:
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	SND_RET

Snd63_SfxN:
	NVOICE $06, $D6
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $64
	NOISE $54
	NOISE $64
	NOISE $71
	NOISE $53
	NOISE $63
	NOISE $73
	SND_END

Snd64_SfxN:
	NVOICE $09, $F7
	NOISE $53
	NOISE $63
	NOISE $73
	NOISE $63
	NOISE $73
	NOISE $65
	NOISE $63
	NOISE $73
	NOISE $65
	NOISE $63
	NOISE $73
	NOISE $65
	SND_END

Snd66_Sfx1:
	VOICE $02, 13, 0, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 6
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	SND_END

Snd67_Sfx1:
	VOICE $02, 13, 0, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 7
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 9
	NOTE G_, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE E_, 1
	SND_END

Snd68_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE B_, 1
	ATTEN 6
	OCTAVE 2
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE B_, 1
	ATTEN $0A
	OCTAVE 2
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE B_, 1
	SND_END

Snd68_SfxN:
	NVOICE $01, $D1
	NOISE $5D
	NOISE $4D
	NOISE $51
	NVOICE $01, $61
	NOISE $5D
	NOISE $4D
	NOISE $51
	SND_END

Snd6A_SfxN:
	SND_SEGNO
	NVOICE $02, $DE
	NOISE $4D
	NOISE $15
	SND_REPEAT $04
	SND_END

Snd6B_Sfx2:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 2
	TRANSPOSE_DOWN 3
	ATTEN 8
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_DOWN 2
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_DOWN 1
	ATTEN 7
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 0
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 1
	ATTEN 6
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 2
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 3
	ATTEN 5
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 4
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 5
	ATTEN 4
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 6
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 7
	ATTEN 3
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 8
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP 9
	ATTEN 2
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0A
	ATTEN 1
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0B
	ATTEN 0
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0C
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0D
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0E
	SND_CALL Snd6B_Sfx2_5C46
	TRANSPOSE_UP $0F
	SND_CALL Snd6B_Sfx2_5C46
	SND_CALL Snd6B_Sfx2_5C46
	SND_END
Snd6B_Sfx2_5C46:
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A#, 2
	SND_RET

Snd6D_SfxN:
	NVOICE $04, $A3
	NOISE $61
	NOISE $55
	NOISE $81
	SND_END

Snd6E_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_END

Snd6E_SfxN:
	NVOICE $45, $A5
	NOISE $81
	SND_END

Snd6F_Sfx1:
	VOICE $01, 15, 12, 15, 0
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd70_SfxN:
	NVOICE $14, $F5
	NOISE $5D
	NOISE $66
	SND_END

Snd71_Sfx1:
	VOICE $01, 12, 8, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	SND_END

Snd71_SfxN:
	NVOICE $45, $87
	NOISE $37
	SND_END

Snd72_Sfx1:
	VOICE $02, 12, 12, 15, 0
	TRANSPOSE_UP 4
	OCTAVE 6
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 9
	NOTE G#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE A#, 1
	NOTE B_, 1
	SND_END

Snd72_SfxN:
	NVOICE $02, $82
	NOISE $2D
	NOISE $3D
	NOISE $55
	NOISE $2D
	NOISE $3D
	SND_END

Snd4A_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 10, 8, 15, 0
	ATTEN 4
	OCTAVE 6
	NOTE C_, 2
	ATTEN 3
	OCTAVE 4
	NOTE F#, 1
	REST 2
	OCTAVE 6
	NOTE C_, 2
	ATTEN 2
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 6
	NOTE C_, 2
	SND_END

Snd73_Ch2:
	TEMPO $00
	VOICE $06, 10, 8, 1, 14
Snd73_Ch2_5CD9:
	ATTEN 2
	SND_CALL Snd73_Ch2_5D2D
	ATTEN 0
	SND_CALL Snd73_Ch2_5D40
	SND_CALL Snd73_Ch2_5D4C
	SND_CALL Snd73_Ch2_5D40
	SND_CALL Snd73_Ch2_5D5D
	SND_CALL Snd73_Ch2_5D6F
	SND_CALL Snd73_Ch2_5D93
	DUTY $0C
	SND_CALL Snd73_Ch2_5D6F
	SND_CALL Snd73_Ch2_5CFB
	SND_CALL Snd73_Ch2_5CD9
Snd73_Ch2_5CFB:
	ATTEN 3
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F_, 2
	NOTE D#, 1
	PAN $F0
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	PAN $FF
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	PAN $0F
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	PAN $FF
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE $0E, 1
	PAN $F0
	OCTAVE 1
	NOTE B_, 1
	PAN $0F
	NOTE B_, 1
	ATTEN 0
	PAN $FF
	OCTAVE 2
	NOTE G_, 2
	SND_RET
Snd73_Ch2_5D2D:
	DUTY_STEP 2, 4
	RELEASE $0E, 1
	REST 2
	OCTAVE 2
	NOTE A#, 4
	NOTE A#, 1
	NOTE A#, 1
	REST 2
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 1
	NOTE A#, 1
	REST 2
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 2
	SND_RET
Snd73_Ch2_5D40:
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 2
	NOTE G#, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE D#, 2
	NOTE G_, 2
	SND_REPEAT $04
	SND_RET
Snd73_Ch2_5D4C:
	SND_SEGNO
	NOTE D#, 2
	NOTE F_, 2
	SND_REPEAT $04
	OCTAVE 1
	NOTE A#, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	SND_RET
Snd73_Ch2_5D5D:
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	SND_REPEAT $04
	REST 2
	OCTAVE 3
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 4
	OCTAVE 1
	NOTE A#, 2
	REST 2
	SND_RET
Snd73_Ch2_5D6F:
	ATTEN 2
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE D#, 2
	RELEASE $0F, 4
	NOTE F_, 4
	RELEASE $0F, 2
	OCTAVE 4
	NOTE A#, 2
	PAN $F0
	OCTAVE 5
	NOTE A#, 1
	PAN $0F
	NOTE A#, 1
	PAN $FF
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE A#, 2
	SND_RET
Snd73_Ch2_5D93:
	PAN $F0
	ATTEN 4
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	ATTEN 2
	SND_SEGNO
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	SND_REPEAT $02
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	SND_RET

Snd73_Ch1:
	DETUNE $00
	VOICE $06, 5, 8, 7, 15
Snd73_Ch1_5DBB:
	SND_CALL Snd73_Ch1_5E01
	SND_CALL Snd73_Ch1_5E17
	SND_CALL Snd73_Ch1_5E1E
	SND_CALL Snd73_Ch1_5E17
	SND_CALL Snd73_Ch1_5E39
	DUTY 4
	SND_CALL Snd73_Ch1_5E5B
	SND_CALL Snd73_Ch1_5E70
	DUTY 8
	SND_CALL Snd73_Ch1_5E5B
	SND_CALL Snd73_Ch1_5DDD
	SND_CALL Snd73_Ch1_5DBB
Snd73_Ch1_5DDD:
	DETUNE $81
	PAN $0F
	RELEASE $0F, 6
	ATTEN 4
	OCTAVE 4
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F_, 2
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 5
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 5
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	PAN $FF
	DETUNE $00
	ATTEN 0
	SND_RET
Snd73_Ch1_5E01:
	REST 2
	RELEASE $0E, 2
	OCTAVE 2
	NOTE D#, 2
	REST 2
	NOTE D#, 1
	NOTE D#, 1
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 1
	NOTE D#, 1
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	SND_RET
Snd73_Ch1_5E17:
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 2
	NOTE F_, 2
	SND_REPEAT $08
	SND_RET
Snd73_Ch1_5E1E:
	SND_SEGNO
	NOTE A#, 2
	NOTE D#, 2
	SND_REPEAT $04
	DETUNE $01
	RELEASE $0F, 5
	ATTEN 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	ATTEN 0
	DETUNE $00
	RELEASE $0E, 2
	SND_RET
Snd73_Ch1_5E39:
	DETUNE $01
	ATTEN 3
	RELEASE 0, $0F
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 2
	OCTAVE 5
	NOTE D_, 1
	DETUNE $00
	ATTEN 0
	RELEASE $0E, 4
	OCTAVE 4
	NOTE D_, 4
	RELEASE $0E, 2
	NOTE A#, 4
	SND_RET
Snd73_Ch1_5E5B:
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 2
	NOTE D#, 1
	NOTE D_, 2
	NOTE C_, 2
	RELEASE $0D, 7
	NOTE D_, 8
	RELEASE $0E, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE D#, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 2
	SND_RET
Snd73_Ch1_5E70:
	DETUNE $01
	PAN $0F
	ATTEN 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	ATTEN 0
	SND_SEGNO
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	SND_REPEAT $02
	DETUNE $00
	REST 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE D_, 2
	SND_RET

Snd73_Ch3:
	VOICE $06, 2, 12, 5, 15
Snd73_Ch3_5E98:
	SND_CALL Snd73_Ch3_5ED4
	SND_CALL Snd73_Ch3_5EE5
	SND_CALL Snd73_Ch3_5F0F
	SND_CALL Snd73_Ch3_5EE5
	SND_CALL Snd73_Ch3_5F30
	SND_CALL Snd73_Ch3_5F52
	SND_CALL Snd73_Ch3_5F65
	SND_CALL Snd73_Ch3_5F52
	SND_CALL Snd73_Ch3_5EB6
	SND_CALL Snd73_Ch3_5E98
Snd73_Ch3_5EB6:
	DETUNE $01
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE B_, 2
	DETUNE $00
	NOTE B_, 2
	SND_RET
Snd73_Ch3_5ED4:
	RELEASE $0F, 5
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_RET
Snd73_Ch3_5EE5:
	WAVE 9
	RELEASE $0F, 4
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 2
	VIBRATO $01, 0, 5
	RELEASE $0A, 7
	OCTAVE 3
	NOTE A#, 8
	VIBRATO_OFF
	SND_RET
Snd73_Ch3_5F0F:
	WAVE $0B
	RELEASE $0F, 4
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 2
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G#, 2
	NOTE A#, 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE G#, 2
	NOTE A#, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	WAVE $0C
	RELEASE $0F, 5
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	SND_RET
Snd73_Ch3_5F30:
	WAVE $0B
	RELEASE $0F, 4
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 2
	OCTAVE 5
	NOTE D_, 2
	RELEASE $0D, 7
	OCTAVE 4
	NOTE A#, 4
	WAVE $0C
	RELEASE $0F, 4
	OCTAVE 5
	NOTE A#, 2
	NOTE A#, 2
	SND_RET
Snd73_Ch3_5F52:
	SND_SEGNO
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE A#, 2
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 2
	SND_REPEAT $03
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D#, 2
	SND_RET
Snd73_Ch3_5F65:
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	SND_REPEAT $03
	REST 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	SND_RET

Snd73_Drm:
	DRUM_UNIT $06
Snd73_Drm_5F7B:
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $0A
	REST $0E
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $0C
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $04
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 2
	SND_REPEAT $04
	SND_SEGNO
	DRUM 5, 2
	DRUM 5, 2
	SND_REPEAT $04
	SND_CALL Snd73_Drm_5F7B

Snd74_Ch2:
	TEMPO $10
	VOICE $05, 8, 0, 2, 15
Snd74_Ch2_5FC2:
	ATTEN 2
	PAN $F0
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch1_612F
	TRANSPOSE_UP 3
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch1_612F
	ATTEN 0
	PAN $FF
	TRANSPOSE_UP 0
	DUTY 8
	SND_CALL Snd74_Ch1_6005
	SND_CALL Snd74_Ch1_6024
	TRANSPOSE_UP 3
	SND_CALL Snd74_Ch1_6005
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch1_6031
	TRANSPOSE_UP 5
	SND_CALL Snd74_Ch1_6005
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch1_6042
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	DUTY 0
	SND_CALL Snd74_Ch2_5FC2
Snd74_Ch1_6005:
	OCTAVE 3
	NOTE B_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE C#, 1
	SND_RET
Snd74_Ch1_6024:
	OCTAVE 3
	NOTE A_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	SND_RET
Snd74_Ch1_6031:
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_RET
Snd74_Ch1_6042:
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT $04
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET

Snd74_Ch1:
	VOICE $05, 5, 12, 2, 14
	DETUNE $01
Snd74_Ch1_607E:
	PAN $0F
	OCTAVE 2
	NOTE G_, 2
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch1_612F
	TRANSPOSE_UP 3
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch1_612F
	FLAGS 2
	PAN $F0
	TRANSPOSE_UP 0
	RELEASE 0, $0F
	ATTEN 1
	SND_CALL Snd74_Ch1_6005
	SND_CALL Snd74_Ch1_6024
	TRANSPOSE_UP 3
	SND_CALL Snd74_Ch1_6005
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch1_6031
	TRANSPOSE_UP 5
	SND_CALL Snd74_Ch1_6005
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch1_6042
	ATTEN 0
	RELEASE 9, 7
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	RELEASE $0E, 2
	FLAGS 0
	PAN $FF
	SND_CALL Snd74_Ch1_607E

Snd74_Ch3:
	VOICE $05, 2, 8, 3, 15
Snd74_Ch3_60CB:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch3_6148
	TRANSPOSE_DOWN 9
	SND_CALL Snd74_Ch1_60FE
	SND_CALL Snd74_Ch3_6148
	TRANSPOSE_UP 0
	WAVE 2
	SND_CALL Snd74_Ch3_6152
	SND_CALL Snd74_Ch3_615C
	TRANSPOSE_UP 3
	SND_CALL Snd74_Ch3_6152
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch3_6161
	TRANSPOSE_UP 5
	SND_CALL Snd74_Ch3_6152
	TRANSPOSE_UP 0
	SND_CALL Snd74_Ch3_6166
	WAVE 8
	SND_CALL Snd74_Ch3_60CB
Snd74_Ch1_60FE:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	SND_RET
Snd74_Ch1_612F:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	TEMPO $30
	ATTEN 3
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	TEMPO $00
	SND_RET
Snd74_Ch3_6148:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	REST 4
	SND_RET
Snd74_Ch3_6152:
	RELEASE 9, 7
	OCTAVE 1
	NOTE G_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE F#, 4
	SND_RET
Snd74_Ch3_615C:
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_RET
Snd74_Ch3_6161:
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	SND_RET
Snd74_Ch3_6166:
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	RELEASE 7, 5
	OCTAVE 1
	NOTE D_, 8
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 1
	NOTE D_, 8
	RELEASE $0F, 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_RET

Snd74_Drm:
	DRUM_UNIT $05
Snd74_Drm_6181:
	SND_CALL Snd74_Drm_618D
	SND_CALL Snd74_Drm_618D
	SND_CALL Snd74_Drm_6193
	SND_CALL Snd74_Drm_6181
Snd74_Drm_618D:
	SND_SEGNO
	DRUM 5, 4
	SND_REPEAT $07
	REST 4
	SND_RET
Snd74_Drm_6193:
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $20
	SND_RET

Snd75_Ch2:
	TEMPO $00
	DUTY_STEP 2, 0
	VOICE $08, 8, 8, 4, 14
	ATTEN 4
	PAN $F0
	OCTAVE 2
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	ATTEN 3
	PAN $F0
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	ATTEN 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 2
	VIBRATO $01, 3, 2
	RELEASE $0F, 6
	NOTE E_, 5
Snd75_Ch2_61E3:
	VIBRATO $01, 2, 1
	RELEASE $0F, 4
	SND_CALL Snd75_Ch2_6206
	SND_CALL Snd75_Ch2_623A
	SND_CALL Snd75_Ch2_6206
	SND_CALL Snd75_Ch2_623A
	DUTY_STEP_OFF
	DUTY 8
	RELEASE $0F, 6
	SND_CALL Snd75_Ch1_6252
	NOTE D#, 2
	SND_CALL Snd75_Ch2_6280
	DUTY_STEP 2, 4
	SND_CALL Snd75_Ch2_61E3
Snd75_Ch2_6206:
	DUTY $0C
Snd75_Ch1_6208:
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 4
	PAN $0F
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	PAN $FF
	SND_REPEAT $02
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd75_Ch2_623A:
	NOTE F#, 2
	DUTY 0
	RELEASE 0, $0F
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	RELEASE $0F, 4
	SND_RET
Snd75_Ch1_6252:
	NOTE D_, 3
	OCTAVE 3
	NOTE A#, 3
	NOTE F_, 2
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 3
	NOTE G_, 2
	NOTE F#, 3
	NOTE G_, 3
	NOTE A_, 2
	NOTE A#, 3
	NOTE G_, 3
	NOTE F_, 2
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE A_, 3
	NOTE F_, 1
	NOTE A#, 3
	NOTE F_, 1
	NOTE B_, 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 1
	NOTE D_, 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 1
	NOTE E_, 3
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	SND_RET
Snd75_Ch2_6280:
	RELEASE $0F, 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	RELEASE $0F, 6
	NOTE A#, 4
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 4
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 4
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 1
	NOTE D_, 1
	RELEASE $0E, 2
	NOTE E_, 1
	PAN $F0
	NOTE E_, 1
	PAN $FF
	NOTE F_, 1
	PAN $0F
	NOTE F_, 1
	PAN $FF
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 1
	PAN $0F
	NOTE G_, 1
	PAN $FF
	ATTEN 0
	SND_RET

Snd75_Ch1:
	VOICE $08, 5, 12, 4, 15
	DUTY_STEP 2, 8
	DETUNE $01
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	DETUNE $00
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE B_, 2
	RELEASE $0E, 5
	OCTAVE 4
	NOTE C#, 5
	ATTEN 3
	DUTY_STEP_OFF
Snd75_Ch1_62E9:
	DETUNE $01
	DUTY 8
	RELEASE 0, $0F
	NOTE F#, 1
	SND_CALL Snd75_Ch1_6208
	SND_CALL Snd75_Ch1_6313
	RELEASE 0, $0F
	ATTEN 3
	NOTE F#, 1
	SND_CALL Snd75_Ch1_6208
	SND_CALL Snd75_Ch1_6313
	FLAGS 2
	PAN $F0
	DUTY $0C
	RELEASE 0, $0F
	ATTEN 3
	NOTE D_, 2
	SND_CALL Snd75_Ch1_6252
	SND_CALL Snd75_Ch1_632A
	SND_CALL Snd75_Ch1_62E9
Snd75_Ch1_6313:
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, $0F
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	SND_RET
Snd75_Ch1_632A:
	FLAGS 0
	PAN $FF
	DETUNE $00
	RELEASE $0F, 3
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 0, $0F
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 4
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 1
	NOTE A#, 1
	RELEASE $0D, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 1
	PAN $0F
	NOTE E_, 1
	PAN $FF
	SND_RET

Snd75_Ch3:
	VOICE $08, 2, 12, 5, 15
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 1
	NOTE A_, 1
	WAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
Snd75_Ch3_6389:
	SND_CALL Snd75_Ch3_639E
	SND_CALL Snd75_Ch3_639E
	SND_CALL Snd75_Ch3_63C6
	SND_CALL Snd75_Ch3_63DA
	SND_CALL Snd75_Ch3_63C6
	SND_CALL Snd75_Ch3_63E7
	SND_CALL Snd75_Ch3_6389
Snd75_Ch3_639E:
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_REPEAT $02
	SND_SEGNO
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_REPEAT $02
	SND_RET
Snd75_Ch3_63C6:
	SND_SEGNO
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_REPEAT $02
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_RET
Snd75_Ch3_63DA:
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_RET
Snd75_Ch3_63E7:
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	SND_RET

Snd75_Drm:
	DRUM_UNIT $08
Snd75_Drm_63F8:
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 3, 1
	SND_REPEAT $0F
	SND_CALL Snd75_Drm_63F8

Snd76_Ch2:
	TEMPO $00
	DUTY_STEP 2, 4
	VOICE $06, 8, 0, 3, 15
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE F_, 3
	NOTE E_, 3
	NOTE C_, 3
	RELEASE $0F, 4
	OCTAVE 4
	NOTE A_, 7
	DUTY_STEP_OFF
Snd76_Ch2_6425:
	SND_CALL Snd76_Ch2_6457
	DUTY_STEP 1, $0C
	SND_CALL Snd76_Ch2_648F
	DUTY_STEP_OFF
	SND_CALL Snd76_Ch2_64A3
	NOTE B_, 4
	SND_CALL Snd76_Ch2_64B5
	SND_CALL Snd76_Ch2_64C5
	SND_CALL Snd76_Ch2_6457
	DUTY_STEP 1, $0C
	SND_CALL Snd76_Ch2_648F
	DUTY_STEP_OFF
	SND_CALL Snd76_Ch2_64A3
	NOTE B_, 4
	SND_CALL Snd76_Ch2_64F3
	DUTY 0
	SND_CALL Snd76_Ch2_6516
	RELEASE $0F, 6
	OCTAVE 3
	NOTE B_, 6
	REST 4
	SND_CALL Snd76_Ch2_6425
Snd76_Ch2_6457:
	DUTY $0C
	RELEASE $0F, 3
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 4
	NOTE A#, 3
	RELEASE $0F, 6
	NOTE A_, 8
	RELEASE $0F, 3
	NOTE C_, 2
	NOTE D_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_RET
Snd76_Ch1_6477:
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 4
	NOTE A#, 3
	NOTE A_, 8
	NOTE C_, 2
	NOTE D_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_RET
Snd76_Ch2_648F:
	DUTY 8
	RELEASE $0F, 2
Snd76_Ch1_6493:
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	SND_RET
Snd76_Ch2_64A3:
	DUTY $0C
	RELEASE $0F, 3
Snd76_Ch1_64A7:
	REST 4
	OCTAVE 3
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 3
	NOTE D_, 3
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	SND_RET
Snd76_Ch2_64B5:
	RELEASE $0F, 6
Snd76_Ch1_64B7:
	OCTAVE 4
	NOTE G_, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D#, 1
	SND_RET
Snd76_Ch2_64C5:
	DUTY 8
	RELEASE $0F, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE $0F, 5
	NOTE G_, 6
	LEN_UNIT 1
	OCTAVE 4
	NOTE G_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE D_, 4
	LEN_UNIT 6
	SND_RET
Snd76_Ch1_64DF:
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 6
	LEN_UNIT 1
	OCTAVE 4
	NOTE G_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE D_, 4
	LEN_UNIT 6
	SND_RET
Snd76_Ch2_64F3:
	OCTAVE 4
	NOTE E_, 3
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	RELEASE $0F, 6
	NOTE E_, 6
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Snd76_Ch1_6502:
	FLAGS 0
	PAN $FF
	ATTEN 0
	OCTAVE 3
	NOTE A_, 3
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE G#, 6
	ATTEN 3
	OCTAVE 4
	NOTE B_, 2
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Snd76_Ch2_6516:
	RELEASE $0F, 3
Snd76_Ch1_6518:
	SND_SEGNO
	REST 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE B_, 3
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 3
	SND_REPEAT $02
	REST 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 3
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	NOTE G#, 4
	NOTE A_, 4
	NOTE E_, 3
	NOTE D_, 3
	NOTE C#, 2
	REST 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE B_, 3
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 3
	REST 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 3
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	REST 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 3
	LEN_UNIT 1
	OCTAVE 5
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE F#, 4
	NOTE E_, 4
	LEN_UNIT 6
	OCTAVE 4
	NOTE C#, 3
	NOTE C_, 3
	SND_RET

Snd76_Ch1:
	VOICE $06, 5, 12, 5, 14
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE C_, 7
Snd76_Ch1_6576:
	FLAGS 2
	PAN $F0
	DETUNE $01
	RELEASE 0, $0F
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	SND_CALL Snd76_Ch1_6477
	SND_CALL Snd76_Ch1_6493
	SND_CALL Snd76_Ch1_64A7
	NOTE B_, 4
	SND_CALL Snd76_Ch1_64B7
	SND_CALL Snd76_Ch1_64DF
	SND_CALL Snd76_Ch1_6477
	SND_CALL Snd76_Ch1_6493
	SND_CALL Snd76_Ch1_64A7
	NOTE B_, 3
	SND_CALL Snd76_Ch1_6502
	SND_CALL Snd76_Ch1_6518
	OCTAVE 3
	NOTE B_, 6
	REST 3
	SND_CALL Snd76_Ch1_6576

Snd76_Ch3:
	VOICE $06, 2, 4, 5, 15
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 2
	SND_REPEAT $03
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
Snd76_Ch3_65C4:
	WAVE 2
	SND_CALL Snd76_Ch3_65E1
	SND_CALL Snd76_Ch3_660C
	SND_CALL Snd76_Ch3_65E1
	SND_CALL Snd76_Ch3_6633
	SND_CALL Snd76_Ch3_6642
	SND_CALL Snd76_Ch3_6667
	SND_CALL Snd76_Ch3_6642
	SND_CALL Snd76_Ch3_6690
	SND_CALL Snd76_Ch3_65C4
Snd76_Ch3_65E1:
	RELEASE $0F, 4
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $04
	SND_RET
Snd76_Ch3_660C:
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	LEN_UNIT 1
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE G_, 4
	LEN_UNIT 6
	SND_RET
Snd76_Ch3_6633:
	OCTAVE 2
	NOTE E_, 3
	NOTE E_, 3
	RELEASE $0E, 7
	NOTE E_, 6
	RELEASE $0F, 4
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	SND_RET
Snd76_Ch3_6642:
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_RET
Snd76_Ch3_6667:
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_RET
Snd76_Ch3_6690:
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	NOTE E_, 3
	NOTE E_, 3
	WAVE $0C
	RELEASE $0A, 7
	NOTE E_, 6
	REST 4
	SND_RET

Snd76_Drm:
	DRUM_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	SND_SEGNO
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $04
Snd76_Drm_66BD:
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	SND_REPEAT $0F
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	SND_REPEAT $0D
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	SND_REPEAT $07
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	SND_REPEAT $06
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_SEGNO
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $05
	SND_CALL Snd76_Drm_66BD

Snd77_Ch2:
	TEMPO $00
	DUTY_STEP 2, 0
	VOICE $06, 8, 8, 4, 14
Snd77_Ch2_670F:
	ATTEN 3
	SND_CALL Snd77_Ch1_672A
	ATTEN 2
	SND_CALL Snd77_Ch2_6740
	ATTEN 3
	RELEASE $0E, 4
	SND_CALL Snd77_Ch1_672A
	ATTEN 2
	SND_CALL Snd77_Ch2_6740
	ATTEN 0
	SND_CALL Snd77_Ch2_674A
	RELEASE $0F, 4
	SND_CALL Snd77_Ch2_670F
Snd77_Ch1_672A:
	OCTAVE 1
	NOTE G_, 3
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 3
	NOTE D_, 4
	OCTAVE 1
	NOTE D_, 1
	NOTE F_, 3
	NOTE F#, 1
	NOTE G_, 3
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 3
	NOTE C#, 1
	NOTE D_, 3
	OCTAVE 1
	NOTE D_, 1
	NOTE F_, 3
	NOTE F#, 1
	SND_RET
Snd77_Ch2_6740:
	RELEASE $0D, 4
Snd77_Ch1_6742:
	NOTE G_, 4
	NOTE A#, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 4
	SND_RET
Snd77_Ch2_674A:
	RELEASE $0F, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 3
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 4
	ATTEN 1
	DETUNE $81
	PAN $0F
	OCTAVE 1
	NOTE D_, 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE F_, 4
	NOTE F#, 4
	NOTE F_, 1
	NOTE E_, 3
	NOTE D#, 4
	NOTE D_, 4
	PAN $FF
	NOTE D_, 1
	ATTEN 0
	DETUNE $00
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 3
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 4
	DETUNE $81
	ATTEN 1
	OCTAVE 1
	PAN $F0
	NOTE A_, 3
	NOTE A#, 1
	NOTE B_, 3
	NOTE A#, 4
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 4
	ATTEN 1
	LEN_UNIT 1
	NOTE D_, 8
	NOTE D#, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D#, 8
	PAN $FF
	LEN_UNIT 6
	NOTE D_, 3
	NOTE D_, 1
	DETUNE $00
	ATTEN 0
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G#, 3
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 4
	ATTEN 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE F#, 4
	ATTEN 3
	NOTE F#, 4
	ATTEN 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE D_, 3
	NOTE D_, 1
	SND_RET

Snd77_Ch1:
	DETUNE $01
	VOICE $06, 2, 12, 7, 15
Snd77_Ch1_67C5:
	FLAGS 2
	PAN $F0
	TRANSPOSE_UP $0C
	SND_CALL Snd77_Ch1_672A
	SND_CALL Snd77_Ch1_6742
	SND_CALL Snd77_Ch1_672A
	SND_CALL Snd77_Ch1_6742
	FLAGS 0
	PAN $FF
	TRANSPOSE_UP 0
	RELEASE 0, $0F
	OCTAVE 3
	NOTE B_, 1
	SND_CALL Snd77_Ch1_6829
	NOTE F#, 4
	RELEASE $0F, 7
	SND_CALL Snd77_Ch1_67C5

Snd77_Ch3:
	VOICE $06, 2, 10, 7, 15
Snd77_Ch3_67EE:
	TRANSPOSE_UP $0C
	SND_CALL Snd77_Ch1_672A
	WAVE $0C
	SND_CALL Snd77_Ch3_680D
	WAVE $0A
	SND_CALL Snd77_Ch1_672A
	WAVE $0C
	SND_CALL Snd77_Ch3_680D
	TRANSPOSE_UP 0
	SND_CALL Snd77_Ch1_6829
	NOTE F#, 5
	WAVE $0A
	SND_CALL Snd77_Ch3_67EE
Snd77_Ch3_680D:
	LEN_UNIT 1
	OCTAVE 1
	NOTE G_, 8
	NOTE B_, 8
	OCTAVE 2
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C#, 8
	NOTE E_, 8
	NOTE C#, 8
	NOTE E_, 8
	NOTE C#, 8
	NOTE D#, 8
	NOTE C_, 8
	NOTE D#, 8
	NOTE C_, 8
	NOTE D#, 8
	NOTE C_, 8
	LEN_UNIT 6
	SND_RET
Snd77_Ch1_6829:
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 3
	NOTE B_, 2
	REST 3
	OCTAVE 2
	NOTE D_, 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE F_, 4
	NOTE F#, 4
	NOTE F_, 1
	NOTE E_, 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE E_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	REST 3
	OCTAVE 2
	NOTE A_, 3
	NOTE A#, 1
	NOTE B_, 3
	NOTE A#, 4
	NOTE A_, 2
	REST 3
	LEN_UNIT 1
	NOTE D_, 8
	NOTE D#, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D#, 8
	LEN_UNIT 6
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	REST 2
	VIBRATO $08, 3, 2
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE G_, 3
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 3
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 2
	NOTE G#, 1
	NOTE A_, 3
	OCTAVE 3
	NOTE F#, 4
	OCTAVE 2
	NOTE A_, 2
	REST 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 3
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 3
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 3
	VIBRATO_OFF
	OCTAVE 4
	SND_RET

Snd77_Drm:
	DRUM_UNIT $06
Snd77_Drm_68CE:
	SND_SEGNO
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	SND_REPEAT $08
	SND_CALL Snd77_Drm_68CE

Snd78_Ch2:
	TEMPO $00
	DUTY_STEP 1, 0
	VOICE $06, 8, 12, 3, 14
	SND_CALL Snd78_Ch1_6919
Snd78_Ch2_68E8:
	DUTY 0
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch2_6989
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch2_6989
	TRANSPOSE_UP 5
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch2_6989
	TRANSPOSE_UP 0
	SND_CALL Snd78_Ch2_699F
	TRANSPOSE_UP 2
	SND_CALL Snd78_Ch2_699F
	SND_CALL Snd78_Ch2_69B2
	SND_CALL Snd78_Ch1_69C9
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	SND_CALL Snd78_Ch2_69DD
	SND_CALL Snd78_Ch2_68E8
Snd78_Ch1_6919:
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	LEN_UNIT 1
	PAN $0F
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
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
	PAN $F0
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $FF
	SND_RET
Snd78_Ch1_695C:
	LEN_UNIT 6
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_RET
Snd78_Ch2_6989:
	LEN_UNIT 1
	DUTY $0C
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE C#, 4
	NOTE D_, 4
	NOTE F_, 4
	DUTY 0
	SND_RET
Snd78_Ch2_699F:
	OCTAVE 4
	NOTE G#, 4
	NOTE D#, 4
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE G#, 4
	NOTE D#, 4
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE G#, 4
	NOTE D#, 4
	NOTE G#, 4
	NOTE D#, 4
	OCTAVE 3
	NOTE G#, 4
	NOTE D#, 4
	SND_RET
Snd78_Ch2_69B2:
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE C_, 4
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE C_, 4
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE C#, 4
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE D_, 4
	SND_RET
Snd78_Ch1_69C9:
	REST $0C
	PAN $0F
	OCTAVE 6
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 5
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
Snd78_Ch2_69DD:
	PAN $F0
	OCTAVE 5
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
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
	SND_RET
Snd78_Ch1_69F6:
	PAN $F0
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
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	SND_RET

Snd78_Ch1:
	VOICE $06, 6, 8, 2, 13
	TRANSPOSE_DOWN 5
	SND_CALL Snd78_Ch1_6919
Snd78_Ch1_6A18:
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch1_6A47
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch1_6A47
	TRANSPOSE_UP 0
	SND_CALL Snd78_Ch1_695C
	SND_CALL Snd78_Ch1_6A47
	VIBRATO $08, 4, 2
	RELEASE $0D, 7
	NOTE D#, 8
	NOTE F_, 8
	NOTE G_, 4
	RELEASE $0E, 4
	NOTE G#, 3
	NOTE A_, 1
	LEN_UNIT 1
	REST 4
	ATTEN 3
	SND_CALL Snd78_Ch1_69C9
	SND_CALL Snd78_Ch1_69F6
	TRANSPOSE_DOWN 5
	SND_CALL Snd78_Ch1_6A18
Snd78_Ch1_6A47:
	FLAGS 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	FLAGS 0
	PAN $FF
	SND_RET

Snd78_Ch3:
	VOICE $06, 2, 2, 5, 15
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	RELEASE $0D, 7
	NOTE D_, 6
Snd78_Ch3_6A86:
	RELEASE $0F, 4
	SND_CALL Snd78_Ch3_6A9B
	SND_CALL Snd78_Ch3_6A9B
	TRANSPOSE_UP 5
	SND_CALL Snd78_Ch3_6A9B
	TRANSPOSE_UP 0
	SND_CALL Snd78_Ch3_6AB6
	SND_CALL Snd78_Ch3_6A86
Snd78_Ch3_6A9B:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT $02
	SND_RET
Snd78_Ch3_6AB6:
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	RELEASE $0D, 7
	NOTE C_, 4
	NOTE C#, 3
	NOTE D_, 3
	REST 6
	SND_RET

Snd78_Drm:
	DRUM_UNIT $06
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
Snd78_Drm_6AF0:
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 4, 1
	SND_REPEAT $07
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd78_Drm_6AF0

Snd79_Ch2:
	TEMPO $00
	VOICE $06, 8, 8, 2, 15
Snd79_Ch2_6B1C:
	ATTEN 5
	PAN $F0
	SND_CALL Snd79_Ch1_6BBA
	OCTAVE 2
	NOTE E_, 2
	ATTEN 0
	PAN $FF
	DUTY $0C
	DUTY_STEP 2, 8
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BF5
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BFE
	NOTE E_, 2
	DUTY 0
	SND_CALL Snd79_Ch2_6C06
	SND_CALL Snd79_Ch2_6C26
	RELEASE $0F, 2
	SND_CALL Snd79_Ch2_6C06
	SND_CALL Snd79_Ch2_6C49
	RELEASE $0F, 2
	DUTY_STEP 2, 8
	NOTE E_, 1
	NOTE E_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE A_, 1
	NOTE A_, 1
	REST $0E
	REST 8
	REST 8
	TRANSPOSE_UP $0C
	DUTY $0C
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BF5
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BFE
	NOTE E_, 2
	DUTY 0
	SND_CALL Snd79_Ch2_6C06
	SND_CALL Snd79_Ch2_6C26
	RELEASE $0F, 2
	SND_CALL Snd79_Ch2_6C06
	SND_CALL Snd79_Ch2_6C49
	RELEASE $0D, 3
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE C#, 1
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	DUTY_STEP_OFF
	TRANSPOSE_UP 0
	SND_CALL Snd79_Ch2_6C6E
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	TRANSPOSE_DOWN $0C
	SND_CALL Snd79_Ch2_6C6E
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	TRANSPOSE_UP 0
	SND_CALL Snd79_Ch2_6C6E
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	TRANSPOSE_DOWN $0C
	SND_CALL Snd79_Ch2_6C6E
	TRANSPOSE_UP 0
	REST 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_CALL Snd79_Ch2_6B1C
Snd79_Ch1_6BBA:
	OCTAVE 1
	SND_SEGNO
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	SND_REPEAT $03
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 1
	SND_RET
Snd79_Ch1_6BD3:
	OCTAVE 3
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 2
	REST $0A
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	SND_RET
Snd79_Ch1_6BF5:
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 3
	NOTE E_, 2
	REST 3
	SND_RET
Snd79_Ch1_6BFE:
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 3
	NOTE B_, 3
	SND_RET
Snd79_Ch2_6C06:
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, $0F
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	SND_RET
Snd79_Ch2_6C26:
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	RELEASE $0F, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	DUTY_STEP_OFF
	RELEASE 0, $0F
	NOTE A_, $0C
	VIBRATO $08, 4, 4
	NOTE A_, $0C
	REST 4
	VIBRATO_OFF
	DUTY_STEP 2, 8
	SND_RET
Snd79_Ch2_6C49:
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	SND_RET
Snd79_Ch2_6C6E:
	RELEASE $0F, 2
Snd79_Ch1_6C70:
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 2
	RELEASE 0, $0F
	NOTE A_, 5
	SND_RET

Snd79_Ch1:
	DETUNE $01
	VOICE $06, 5, 12, 5, 15
Snd79_Ch1_6C8F:
	ATTEN 3
	OCTAVE 1
	NOTE A_, 1
	PAN $0F
	SND_CALL Snd79_Ch1_6BBA
	RELEASE 0, $0F
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BF5
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BFE
	NOTE E_, 1
	SND_CALL Snd79_Ch1_6D1E
	SND_CALL Snd79_Ch1_6D4A
	SND_CALL Snd79_Ch1_6D1E
	SND_CALL Snd79_Ch1_6D57
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 2
	NOTE C#, 1
	NOTE C#, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	REST $0E
	REST 8
	REST 8
	TRANSPOSE_UP $0C
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BF5
	SND_CALL Snd79_Ch1_6BD3
	SND_CALL Snd79_Ch1_6BFE
	NOTE E_, 1
	SND_CALL Snd79_Ch1_6D1E
	SND_CALL Snd79_Ch1_6D4A
	SND_CALL Snd79_Ch1_6D1E
	SND_CALL Snd79_Ch1_6D57
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE A#, 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	RELEASE 0, $0F
	TRANSPOSE_UP 0
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	SND_CALL Snd79_Ch1_6C70
	NOTE A_, 8
	TRANSPOSE_DOWN $0C
	SND_CALL Snd79_Ch1_6C70
	NOTE A_, 8
	TRANSPOSE_UP 0
	SND_CALL Snd79_Ch1_6C70
	NOTE A_, 8
	TRANSPOSE_DOWN $0C
	SND_CALL Snd79_Ch1_6C70
	TRANSPOSE_UP 0
	REST 4
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE $0F, 5
	SND_CALL Snd79_Ch1_6C8F
Snd79_Ch1_6D1E:
	PAN $FF
	REST 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	RELEASE 0, $0F
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	SND_RET
Snd79_Ch1_6D4A:
	ATTEN 3
	RELEASE 0, $0F
	NOTE A_, 3
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, $0C
	NOTE A_, $0C
	REST 3
	SND_RET
Snd79_Ch1_6D57:
	NOTE A_, 2
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 2
	ATTEN 0
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	SND_RET

Snd79_Ch3:
	VOICE $06, 2, 2, 4, 15
Snd79_Ch3_6D78:
	SND_CALL Snd79_Ch1_6BBA
	OCTAVE 2
	NOTE E_, 2
	SND_CALL Snd79_Ch3_6DBB
	SND_CALL Snd79_Ch3_6DBB
	SND_CALL Snd79_Ch3_6DD7
	SND_CALL Snd79_Ch3_6DE5
	SND_CALL Snd79_Ch3_6DD7
	SND_CALL Snd79_Ch3_6DFE
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	SND_REPEAT $02
	SND_CALL Snd79_Ch3_6DBB
	SND_CALL Snd79_Ch3_6DBB
	SND_CALL Snd79_Ch3_6DD7
	SND_CALL Snd79_Ch3_6DE5
	SND_CALL Snd79_Ch3_6DD7
	SND_CALL Snd79_Ch3_6DFE
	SND_CALL Snd79_Ch3_6E19
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	REST 2
	NOTE E_, 4
	SND_CALL Snd79_Ch3_6D78
Snd79_Ch3_6DBB:
	OCTAVE 1
	SND_SEGNO
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	SND_REPEAT $03
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	SND_RET
Snd79_Ch3_6DD7:
	OCTAVE 1
	SND_SEGNO
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_REPEAT $02
	SND_RET
Snd79_Ch3_6DE5:
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	SND_RET
Snd79_Ch3_6DFE:
	SND_SEGNO
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	SND_REPEAT $02
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	SND_RET
Snd79_Ch3_6E19:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	SND_REPEAT $07
	SND_RET

Snd79_Drm:
	DRUM_UNIT $06
Snd79_Drm_6E28:
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 4, 1
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6EA7
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6E94
	SND_CALL Snd79_Drm_6EA7
	SND_CALL Snd79_Drm_6E94
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $06
	DRUM 3, 1
	DRUM 4, 3
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd79_Drm_6E28
Snd79_Drm_6E94:
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 3, 1
	DRUM 4, 2
	DRUM 4, 1
	SND_RET
Snd79_Drm_6EA7:
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 3, 1
	DRUM 4, 2
	DRUM 3, 1
	DRUM 4, 1
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 3
	DRUM 4, 3
	DRUM 4, 3
	DRUM 4, 3
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 5, 1
	SND_RET

Snd7A_Ch2:
	TEMPO $00
	DUTY_STEP 1, 8
	VOICE $06, 8, 0, 2, 15
Snd7A_Ch2_6ECB:
	PAN $0F
	ATTEN 3
	OCTAVE 2
	SND_SEGNO
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	SND_REPEAT $02
	PAN $FF
	ATTEN 0
	SND_CALL Snd7A_Ch2_6F07
	SND_CALL Snd7A_Ch2_6F3C
	SND_CALL Snd7A_Ch2_6F07
	SND_CALL Snd7A_Ch2_6F53
	DUTY $0C
	OCTAVE 2
	NOTE A_, 2
	SND_CALL Snd7A_Ch2_6F5A
	SND_CALL Snd7A_Ch2_6F6E
	SND_CALL Snd7A_Ch2_6F5A
	SND_CALL Snd7A_Ch2_6F8B
	SND_CALL Snd7A_Ch2_6FA2
	SND_CALL Snd7A_Ch2_6FC4
	DUTY 0
	SND_CALL Snd7A_Ch2_6F07
	SND_CALL Snd7A_Ch2_6FF5
	SND_CALL Snd7A_Ch2_6ECB
Snd7A_Ch2_6F07:
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE D#, 2
	PAN $0F
	ATTEN 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE D#, 2
	PAN $FF
	ATTEN 0
	NOTE G_, 1
	NOTE A#, 2
	NOTE G_, 1
	NOTE A#, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE F_, 2
	PAN $F0
	ATTEN 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE F_, 2
	PAN $FF
	ATTEN 0
	NOTE G#, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE D#, 2
	PAN $0F
	ATTEN 3
	NOTE G_, 1
	NOTE G_, 1
	PAN $FF
	ATTEN 0
	NOTE G_, 2
	SND_RET
Snd7A_Ch2_6F3C:
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	PAN $0F
	ATTEN 4
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	PAN $FF
	ATTEN 0
	SND_RET
Snd7A_Ch2_6F53:
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	REST 4
	SND_RET
Snd7A_Ch2_6F5A:
	RELEASE $0F, 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_RET
Snd7A_Ch2_6F6E:
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 0
	RELEASE $0F, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	SND_RET
Snd7A_Ch2_6F8B:
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 5
	PAN $0F
	NOTE A_, 1
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	SND_RET
Snd7A_Ch2_6FA2:
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	PAN $0F
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	PAN $FF
	ATTEN 0
	SND_REPEAT $02
	SND_RET
Snd7A_Ch2_6FC4:
	REST 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 2
	REST 4
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $0F
	ATTEN 3
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	SND_RET
Snd7A_Ch2_6FF5:
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 2
	PAN $F0
	NOTE D_, 1
	NOTE D_, 1
	REST 4
	PAN $FF
	SND_RET

Snd7A_Ch1:
	VOICE $06, 6, 12, 3, 14
Snd7A_Ch1_700B:
	DETUNE $81
	PAN $F0
	OCTAVE 2
	SND_SEGNO
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	SND_REPEAT $02
	PAN $FF
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	SND_CALL Snd7A_Ch1_7040
	SND_CALL Snd7A_Ch1_7060
	SND_CALL Snd7A_Ch1_7073
	SND_CALL Snd7A_Ch1_70C3
	SND_CALL Snd7A_Ch1_710F
	SND_CALL Snd7A_Ch1_712C
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	SND_CALL Snd7A_Ch1_7040
	SND_CALL Snd7A_Ch1_714D
	RELEASE $0E, 3
	SND_CALL Snd7A_Ch1_700B
	db $FF ; unreachable end
Snd7A_Ch1_7040:
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 2
	NOTE G_, 1
	NOTE A#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd7A_Ch1_7060:
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	RELEASE $0E, 3
	ATTEN 0
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 2
	ATTEN 0
	SND_RET
Snd7A_Ch1_7073:
	DETUNE $81
	RELEASE 8, $0F
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 2
	ATTEN 0
	RELEASE $0E, 3
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	ATTEN 3
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE D#, 1
	ATTEN 0
	RELEASE 8, $0F
	OCTAVE 3
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	RELEASE $0E, 3
	NOTE F_, 2
	NOTE D_, 2
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	ATTEN 0
	RELEASE 8, $0F
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 2
	ATTEN 0
	RELEASE $0E, 3
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE $0D, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	ATTEN 0
	SND_RET
Snd7A_Ch1_70C3:
	DUTY 8
	DUTY_STEP 1, 0
	RELEASE $0F, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	RELEASE $0F, 3
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	RELEASE $0F, 2
	PAN $F0
	NOTE F_, 2
	NOTE F_, 2
	PAN $FF
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	RELEASE $0E, 4
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	RELEASE $0F, 2
	PAN $0F
	NOTE F_, 2
	NOTE F_, 2
	PAN $FF
	SND_RET
Snd7A_Ch1_710F:
	RELEASE $0E, 4
	ATTEN 3
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_REPEAT $02
	SND_RET
Snd7A_Ch1_712C:
	ATTEN 0
	REST 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	REST 4
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	PAN $F0
	ATTEN 4
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $FF
	SND_RET
Snd7A_Ch1_714D:
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN 4
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	PAN $F0
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	DETUNE $00
	SND_RET

Snd7A_Ch3:
	VOICE $06, 2, 12, 5, 15
Snd7A_Ch3_716C:
	OCTAVE 1
	SND_SEGNO
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	SND_REPEAT $02
	WAVE 2
	SND_CALL Snd7A_Ch3_718B
	SND_CALL Snd7A_Ch3_719B
	SND_CALL Snd7A_Ch3_71A9
	SND_CALL Snd7A_Ch3_71BB
	SND_CALL Snd7A_Ch3_71C2
	WAVE $0C
	SND_CALL Snd7A_Ch3_716C
Snd7A_Ch3_718B:
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	SND_RET
Snd7A_Ch3_719B:
	WAVE $0C
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	REST 4
	SND_RET
Snd7A_Ch3_71A9:
	WAVE 2
	REST 6
	NOTE D_, 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE A_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE A#, 2
	SND_RET
Snd7A_Ch3_71BB:
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 4
	REST 4
	SND_RET
Snd7A_Ch3_71C2:
	SND_SEGNO
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	SND_REPEAT $02
	NOTE G_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE G#, 2
	NOTE G#, 2
	REST 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	REST 4
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 4
	REST 4
	SND_RET

Snd7A_Drm:
	DRUM_UNIT $06
Snd7A_Drm_720C:
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	SND_REPEAT $0F
	SND_CALL Snd7A_Drm_720C

Snd7B_Ch2:
	TEMPO $10
	VOICE $06, 8, 12, 3, 15
Snd7B_Ch2_7225:
	PAN $F0
	TRANSPOSE_UP $0C
	SND_CALL Snd7B_Ch1_72A8
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	TRANSPOSE_UP 0
	DUTY_STEP 1, 8
	RELEASE $0F, 2
	SND_CALL Snd7B_Ch1_72C3
	TRANSPOSE_UP 8
	SND_CALL Snd7B_Ch1_72C3
	TRANSPOSE_UP 0
	DUTY 8
	SND_CALL Snd7B_Ch2_72E6
	OCTAVE 4
	NOTE G#, 3
	NOTE A_, 3
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 3
	OCTAVE 4
	NOTE G#, 3
	NOTE E_, 2
	SND_CALL Snd7B_Ch2_72E6
	RELEASE 0, $0F
	DUTY $0C
	OCTAVE 4
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	VIBRATO_OFF
	SND_CALL Snd7B_Ch1_7303
	PAN $F0
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	PAN $0F
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	SND_CALL Snd7B_Ch1_7303
	PAN $F0
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	PAN $0F
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	RELEASE $0F, 3
	DUTY $0C
	SND_CALL Snd7B_Ch2_7225
Snd7B_Ch1_72A8:
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_RET
Snd7B_Ch1_72C3:
	SND_SEGNO
	PAN $0F
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	PAN $F0
	NOTE D_, 2
	PAN $FF
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_REPEAT $02
	SND_RET
Snd7B_Ch2_72E6:
	VIBRATO $08, 4, 2
	RELEASE $0D, 7
	OCTAVE 4
	NOTE F#, $0A
	RELEASE $0F, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F#, 2
	NOTE G#, 3
	NOTE B_, 3
	RELEASE $0D, 7
	OCTAVE 4
	NOTE E_, $0A
	NOTE F#, $0A
	RELEASE $0F, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F#, 2
	SND_RET
Snd7B_Ch1_7301:
	TRANSPOSE_DOWN 5
Snd7B_Ch1_7303:
	DUTY 0
	RELEASE $0F, 2
	OCTAVE 3
	REST 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	RELEASE 0, $0F
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	RELEASE $0F, 2
	REST 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	RELEASE 0, $0F
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	PAN $0F
	RELEASE 9, 1
	DUTY $0C
	REST 1
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	RELEASE $0F, 2
	NOTE C#, 1
	PAN $FF
	DUTY 0
	REST 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	RELEASE 0, $0F
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 1
	RELEASE $0F, 2
	REST 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE E_, 2
	RELEASE 0, $0F
	OCTAVE 5
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	SND_RET

Snd7B_Ch1:
	DETUNE $01
	VOICE $06, 5, 0, 3, 14
Snd7B_Ch1_736F:
	PAN $0F
	SND_CALL Snd7B_Ch1_72A8
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	PAN $FF
	DETUNE $00
	TRANSPOSE_DOWN 5
	SND_CALL Snd7B_Ch1_72C3
	TRANSPOSE_UP 3
	SND_CALL Snd7B_Ch1_72C3
	TRANSPOSE_UP 0
	DUTY $0C
	SND_CALL Snd7B_Ch1_73C6
	SND_CALL Snd7B_Ch1_7301
	OCTAVE 4
	NOTE C_, 1
	PAN $F0
	ATTEN 3
	NOTE C_, 1
	PAN $FF
	ATTEN 0
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 0
	NOTE D_, 1
	PAN $0F
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	SND_CALL Snd7B_Ch1_7301
	OCTAVE 4
	NOTE C_, 1
	PAN $F0
	ATTEN 3
	NOTE C_, 1
	PAN $FF
	ATTEN 0
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 0
	NOTE D_, 1
	PAN $0F
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	TRANSPOSE_UP 0
	DUTY 0
	RELEASE $0E, 3
	SND_CALL Snd7B_Ch1_736F
Snd7B_Ch1_73C6:
	FLAGS 2
	PAN $F0
	SND_SEGNO
	REST 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	SND_REPEAT $04
	FLAGS 0
	PAN $FF
	SND_RET

Snd7B_Ch3:
	VOICE $06, 2, 8, 5, 15
Snd7B_Ch3_73F9:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd7B_Ch1_72A8
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	TRANSPOSE_UP 0
	WAVE $0C
	SND_CALL Snd7B_Ch3_743C
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 2
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 0
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 2
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 0
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 2
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 0
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 2
	SND_CALL Snd7B_Ch3_7471
	TRANSPOSE_UP 0
	SND_CALL Snd7B_Ch3_7486
	SND_CALL Snd7B_Ch3_7486
	WAVE 8
	SND_CALL Snd7B_Ch3_73F9
Snd7B_Ch3_743C:
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_REPEAT $04
	SND_RET
Snd7B_Ch3_7471:
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd7B_Ch3_7486:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT $03
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_RET

Snd7B_Drm:
	DRUM_UNIT $06
Snd7B_Drm_74AE:
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $18
	SND_CALL Snd7B_Drm_74AE

Snd7C_Ch2:
	TEMPO $00
	VOICE $06, 8, 0, 3, 15
Snd7C_Ch2_74EA:
	DUTY_STEP 2, 4
	ATTEN 5
	SND_CALL Snd7C_Ch1_752C
	ATTEN 0
	SND_CALL Snd7C_Ch2_753F
	ATTEN 5
	SND_CALL Snd7C_Ch1_752C
	ATTEN 0
	SND_CALL Snd7C_Ch2_7546
	SND_CALL Snd7C_Ch2_754F
	DUTY_STEP_OFF
	VIBRATO $08, 4, 4
	RELEASE 0, $0F
	NOTE G_, 4
	NOTE G_, $0F
	REST 6
	VIBRATO_OFF
	DUTY_STEP 2, 4
	RELEASE $0F, 3
	SND_CALL Snd7C_Ch2_753F
	ATTEN 5
	SND_CALL Snd7C_Ch1_752C
	ATTEN 0
	SND_CALL Snd7C_Ch2_7546
	SND_CALL Snd7C_Ch2_754F
	SND_CALL Snd7C_Ch2_75B1
	SND_CALL Snd7C_Ch2_75EA
	SND_CALL Snd7C_Ch2_75B1
	SND_CALL Snd7C_Ch2_75FB
	SND_CALL Snd7C_Ch2_74EA
Snd7C_Ch1_752C:
	OCTAVE 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 2
	SND_RET
Snd7C_Ch2_753F:
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	SND_RET
Snd7C_Ch2_7546:
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_RET
Snd7C_Ch2_754F:
	VIBRATO $08, 3, 2
	RELEASE 3, $0F
	OCTAVE 4
	NOTE D_, 6
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	RELEASE $0F, 3
	NOTE C#, 3
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 3
	ATTEN 0
	REST 9
	RELEASE 3, $0F
	OCTAVE 4
	NOTE D_, 6
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	RELEASE $0F, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE D#, 2
	NOTE F_, 3
	NOTE D#, 3
	RELEASE $0F, 7
	NOTE D_, 8
	VIBRATO_OFF
	RELEASE $0F, 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 3
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 3
	ATTEN 0
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	SND_RET
Snd7C_Ch2_75B1:
	DUTY $0C
	RELEASE $0E, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	SND_RET
Snd7C_Ch2_75EA:
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	SND_RET
Snd7C_Ch2_75FB:
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	DUTY_STEP 2, 0
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	DUTY 0
	SND_RET

Snd7C_Ch1:
	VOICE $06, 5, 8, 3, 14
Snd7C_Ch1_7651:
	DETUNE $01
	PAN $0F
	ATTEN 1
	SND_CALL Snd7C_Ch1_752C
	SND_CALL Snd7C_Ch1_7695
	PAN $0F
	RELEASE $0E, 3
	SND_CALL Snd7C_Ch1_752C
	ATTEN 3
	RELEASE 0, $0F
	SND_CALL Snd7C_Ch1_76A0
	SND_CALL Snd7C_Ch1_76AB
	VIBRATO $08, 4, 4
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, $0F
	REST 6
	VIBRATO_OFF
	PAN $FF
	SND_CALL Snd7C_Ch1_7695
	DETUNE $01
	ATTEN 1
	RELEASE $0E, 3
	PAN $0F
	SND_CALL Snd7C_Ch1_752C
	ATTEN 3
	RELEASE 0, $0F
	SND_CALL Snd7C_Ch1_76A0
	SND_CALL Snd7C_Ch1_76AB
	SND_CALL Snd7C_Ch1_7703
	SND_CALL Snd7C_Ch1_7651
Snd7C_Ch1_7695:
	PAN $FF
	RELEASE $0E, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	SND_RET
Snd7C_Ch1_76A0:
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	PAN $FF
	SND_RET
Snd7C_Ch1_76AB:
	VIBRATO $08, 4, 1
	RELEASE 0, $0F
	OCTAVE 4
	NOTE D_, 9
	NOTE C#, 3
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 3
	NOTE G_, 1
	REST $0B
	ATTEN 0
	DETUNE $00
	RELEASE 6, 7
	OCTAVE 3
	NOTE A#, 8
	RELEASE $0F, 6
	NOTE G_, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 3
	NOTE C_, 3
	RELEASE $0B, 7
	OCTAVE 3
	NOTE A#, 8
	VIBRATO_OFF
	RELEASE $0F, 5
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 2
	NOTE G_, 1
	NOTE D_, 4
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 2
	NOTE G_, 1
	NOTE D_, 4
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 2
	RELEASE $0E, 3
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	SND_RET
Snd7C_Ch1_7703:
	DUTY 8
	DETUNE $01
	ATTEN 3
	RELEASE 0, $0F
	OCTAVE 3
	NOTE G_, 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	DUTY 8
	DUTY_STEP 2, 0
	ATTEN 0
	RELEASE $0A, 7
	OCTAVE 4
	NOTE D_, 1
	PAN $0F
	NOTE D_, 1
	PAN $FF
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	RELEASE $0E, 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 1
	RELEASE $0A, 7
	OCTAVE 4
	NOTE D_, 1
	PAN $0F
	NOTE D_, 1
	PAN $FF
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0E, 4
	REST 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	RELEASE $0E, 7
	OCTAVE 3
	NOTE D_, $0C
	RELEASE $0E, 3
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	RELEASE $0E, 7
	NOTE D_, 8
	RELEASE $0E, 3
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	RELEASE $0E, 7
	NOTE D_, $0C
	RELEASE $0E, 3
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	RELEASE $0E, 7
	NOTE D_, 8
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 1
	DUTY_STEP_OFF
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_RET

Snd7C_Ch3:
	VOICE $06, 2, 2, 4, 15
Snd7C_Ch3_77D6:
	SND_CALL Snd7C_Ch3_77E8
	SND_CALL Snd7C_Ch3_77E8
	SND_CALL Snd7C_Ch3_7837
	SND_CALL Snd7C_Ch3_7837
	SND_CALL Snd7C_Ch3_785D
	SND_CALL Snd7C_Ch3_77D6
Snd7C_Ch3_77E8:
	OCTAVE 1
	SND_SEGNO
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	SND_REPEAT $03
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 1
	SND_SEGNO
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0F, 6
	NOTE G#, 3
	RELEASE $0F, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE G_, 1
	SND_REPEAT $02
	NOTE F_, 2
	NOTE F_, 2
	RELEASE $0F, 6
	NOTE F_, 3
	RELEASE $0F, 4
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	SND_RET
Snd7C_Ch3_7837:
	SND_SEGNO
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $04
	SND_SEGNO
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT $04
	SND_SEGNO
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT $04
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_RET
Snd7C_Ch3_785D:
	RELEASE $0A, 7
	NOTE G_, 8
	RELEASE $0F, 6
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 5
	NOTE G_, 3
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 1
	REST 8
	RELEASE $0A, 7
	NOTE G_, 8
	RELEASE $0F, 6
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 5
	NOTE G_, 3
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0F, 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_RET

Snd7C_Drm:
	DRUM_UNIT $06
Snd7C_Drm_7882:
	SND_SEGNO
	DRUM 8, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 2
	DRUM 4, 2
	DRUM 3, 2
	SND_REPEAT $15
	DRUM 5, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 2
	SND_REPEAT $07
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	SND_REPEAT $03
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd7C_Drm_7882

Snd7D_Ch2:
	TEMPO $00
	VOICE $05, 8, 12, 7, 10
	VIBRATO $01, 3, 7
	OCTAVE 3
	NOTE C_, 8
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE $0F, 5
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 2
	DUTY 0
	DUTY_STEP 1, 8
Snd7D_Ch2_78F3:
	RELEASE $0F, 2
	SND_SEGNO
	NOTE G_, 1
	NOTE G_, 2
	NOTE B_, 1
	NOTE F_, 2
	NOTE F_, 2
	SND_REPEAT $03
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $01, 3, 7
	RELEASE 0, $0F
	NOTE F_, $0E
	VIBRATO_OFF
	RELEASE $0F, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	VIBRATO $01, 3, 7
	RELEASE $0A, 7
	NOTE D_, 8
	REST 4
	VIBRATO_OFF
	RELEASE $0F, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	RELEASE $0A, $0D
	OCTAVE 3
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	RELEASE $0F, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE D#, 2
	NOTE B_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE D#, 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 3
	NOTE C_, 1
	NOTE D_, 3
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_CALL Snd7D_Ch2_78F3

Snd7D_Ch1:
	DUTY_STEP 1, $0C
	VOICE $05, 5, 8, 7, 8
	OCTAVE 2
	NOTE F#, 8
	NOTE G_, 8
	RELEASE $0F, 5
	NOTE G#, 4
	NOTE A_, 4
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0E, 3
Snd7D_Ch1_797A:
	SND_SEGNO
	NOTE D_, 1
	NOTE D_, 2
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 2
	SND_REPEAT $03
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	DUTY_STEP_OFF
	SND_SEGNO
	OCTAVE 5
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	SND_REPEAT $03
	DUTY_STEP 1, $0C
	OCTAVE 5
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE A_, 3
	NOTE D_, 1
	NOTE A_, 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	SND_CALL Snd7D_Ch1_797A

Snd7D_Ch3:
	VOICE $05, 2, 13, 7, 10
	OCTAVE 2
	NOTE C_, 8
	NOTE C#, 8
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 2
Snd7D_Ch3_79F6:
	RELEASE $0F, 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_REPEAT $07
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	SND_SEGNO
	NOTE G#, 2
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	SND_REPEAT $02
	SND_SEGNO
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	SND_REPEAT $02
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE A_, 1
	SND_CALL Snd7D_Ch3_79F6

Snd7D_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 2, 1
	SND_REPEAT $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $02
Snd7D_Drm_7A65:
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $0F
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $0B
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $02
	SND_SEGNO
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $02
	SND_CALL Snd7D_Drm_7A65

Snd7E_Ch2:
	TEMPO $00
	DUTY_STEP 1, 8
	VOICE $06, 9, 12, 3, 15
	REST 7
Snd7E_Ch2_7A95:
	SND_CALL Snd7E_Ch2_7AB9
	TRANSPOSE_UP 5
	SND_CALL Snd7E_Ch2_7AB9
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch2_7AB9
	TRANSPOSE_UP 5
	SND_CALL Snd7E_Ch2_7AB9
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch2_7AC1
	SND_CALL Snd7E_Ch2_7AC1
	DUTY 0
	SND_CALL Snd7E_Ch1_7AE0
	DUTY $0C
	SND_CALL Snd7E_Ch2_7A95
Snd7E_Ch2_7AB9:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT $0E
	SND_RET
Snd7E_Ch2_7AC1:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT $02
	SND_RET
Snd7E_Ch1_7AE0:
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_RET

Snd7E_Ch1:
	TRANSPOSE_DOWN 5
	DUTY_STEP 3, 4
	VOICE $06, 6, 0, 3, 15
	REST 7
Snd7E_Ch1_7B0C:
	FLAGS 2
	PAN $F0
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_DOWN 5
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch1_7B63
	FLAGS 0
	PAN $FF
	TRANSPOSE_DOWN 5
	RELEASE $0E, 5
	DUTY $0C
	SND_CALL Snd7E_Ch1_7B72
	SND_CALL Snd7E_Ch1_7AE0
	RELEASE $0F, 3
	DUTY 0
	SND_CALL Snd7E_Ch1_7B0C

Snd7E_Ch3:
	VOICE $06, 2, 12, 5, 15
	REST 7
Snd7E_Ch3_7B3E:
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 5
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 5
	SND_CALL Snd7E_Ch1_7B63
	TRANSPOSE_UP 0
	SND_CALL Snd7E_Ch1_7B72
	WAVE 2
	RELEASE $0E, 4
	SND_CALL Snd7E_Ch3_7BA4
	WAVE $0C
	RELEASE $0F, 5
	SND_CALL Snd7E_Ch3_7B3E
Snd7E_Ch1_7B63:
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 1
	NOTE F_, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 1
	NOTE F_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_REPEAT $02
	SND_RET
Snd7E_Ch1_7B72:
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN $F0
	NOTE F_, 1
	PAN $FF
	OCTAVE 5
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN $0F
	NOTE F_, 1
	PAN $FF
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	NOTE D#, 1
	PAN $FF
	OCTAVE 5
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	PAN $0F
	NOTE D#, 1
	PAN $FF
	SND_REPEAT $02
	SND_RET
Snd7E_Ch3_7BA4:
	SND_SEGNO
	OCTAVE 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT $02
	SND_RET

Snd7E_Drm:
	DRUM_UNIT $03
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
Snd7E_Drm_7BC7:
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $08
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $05
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd7E_Drm_7BC7

SECTION "Sound bank 15", ROMX[$4000], BANK[15]

; Songs $7F-$8F (headers in bank 14, every byte read through FarRead).

Snd8C_Ch2:
	TEMPO $40
	VOICE $01, 8, 0, 2, 15
Snd8C_Ch2_4006:
	ATTEN 3
	PAN $F0
	SND_CALL Snd8C_Ch2_404A
	ATTEN 0
	PAN $FF
	SND_CALL Snd8C_Ch2_4063
	ATTEN 3
	PAN $F0
	SND_CALL Snd8C_Ch2_404A
	ATTEN 0
	PAN $FF
	SND_CALL Snd8C_Ch2_406B
	SND_CALL Snd8C_Ch2_4079
	SND_CALL Snd8C_Ch2_40BF
	SND_CALL Snd8C_Ch2_4079
	SND_CALL Snd8C_Ch2_40D8
	SND_CALL Snd8C_Ch2_40E5
	SND_CALL Snd8C_Ch2_412F
	DUTY 0
	RELEASE $0F, 3
	SND_CALL Snd8C_Ch1_4167
	SND_CALL Snd8C_Ch2_4175
	TRANSPOSE_UP 5
	SND_CALL Snd8C_Ch1_4167
	SND_CALL Snd8C_Ch2_4175
	SND_CALL Snd8C_Ch2_417F
	SND_CALL Snd8C_Ch2_4006
Snd8C_Ch3_4048:
	TRANSPOSE_DOWN $0C
Snd8C_Ch2_404A:
	OCTAVE 2
	NOTE A_, $0C
	OCTAVE 3
	NOTE C#, $0C
	OCTAVE 2
	NOTE G_, $0C
	NOTE B_, 8
	NOTE A_, $0C
	NOTE A_, 4
	OCTAVE 3
	NOTE C#, $0C
	OCTAVE 2
	NOTE G_, $0C
	NOTE B_, $0C
	NOTE A_, $0C
	OCTAVE 3
	NOTE C#, $0C
	OCTAVE 2
	NOTE G_, 8
	NOTE E_, 4
	NOTE G_, 8
	NOTE A_, $0C
	SND_RET
Snd8C_Ch3_4061:
	WAVE 4
Snd8C_Ch2_4063:
	OCTAVE 5
	NOTE E_, $0C
	OCTAVE 4
	NOTE E_, $0C
	NOTE E_, 4
	OCTAVE 5
	NOTE E_, $0C
	SND_RET
Snd8C_Ch2_406B:
	DUTY $0C
	REST $0C
	OCTAVE 5
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE G#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 4
	SND_RET
Snd8C_Ch2_4079:
	RELEASE $0F, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	RELEASE 0, $0F
	LEN_UNIT 3
	NOTE E_, $0C
	LEN_UNIT 1
	RELEASE $0F, 2
	NOTE A_, 4
	NOTE B_, $0C
	OCTAVE 4
	NOTE C#, $0C
	OCTAVE 3
	NOTE A_, $0C
	RELEASE 0, $0F
	OCTAVE 4
	NOTE D_, $0C
	ATTEN 7
	NOTE D_, $0C
	ATTEN 0
	NOTE C#, $0C
	ATTEN 7
	NOTE C#, $0C
	ATTEN 0
	OCTAVE 3
	NOTE A#, $0C
	ATTEN 7
	NOTE A#, 8
	ATTEN 0
	NOTE B_, $0C
	NOTE B_, $0C
	ATTEN 6
	NOTE B_, 4
	ATTEN 0
	RELEASE $0F, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	LEN_UNIT 3
	RELEASE 0, $0F
	NOTE E_, $0C
	LEN_UNIT 1
	RELEASE $0F, 2
	NOTE A_, 4
	NOTE B_, $0C
	OCTAVE 4
	NOTE C#, $0C
	NOTE E_, $0C
	RELEASE 0, $0F
	NOTE D_, $0C
	ATTEN 7
	NOTE D_, $0C
	SND_RET
Snd8C_Ch2_40BF:
	ATTEN 0
	NOTE E_, $0C
	ATTEN 7
	NOTE E_, $0C
	ATTEN 0
	SND_SEGNO
	RELEASE $0F, 3
	NOTE F#, 8
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	SND_REPEAT $02
	ATTEN 4
	NOTE F#, 8
	OCTAVE 3
	NOTE G#, 4
	ATTEN 6
	OCTAVE 4
	NOTE F#, 8
	OCTAVE 3
	NOTE G#, 4
	ATTEN 0
	SND_RET
Snd8C_Ch2_40D8:
	ATTEN 0
	NOTE D#, $0C
	ATTEN 7
	NOTE D#, $0C
	ATTEN 0
	NOTE E_, $0C
	NOTE F#, 8
	NOTE G#, 4
	NOTE G#, $0C
	ATTEN 7
	NOTE G#, $0C
	ATTEN 0
	SND_RET
Snd8C_Ch2_40E5:
	DUTY 8
	RELEASE $0F, 2
	OCTAVE 4
	NOTE A_, $0C
	NOTE A_, 8
	NOTE F#, $0C
	NOTE F#, 4
	RELEASE 0, $0F
	NOTE D_, $0C
	NOTE D_, 8
	RELEASE $0F, 2
	NOTE F#, $0C
	NOTE F#, 4
	NOTE A_, $0C
	NOTE B_, $0C
	NOTE A_, $0C
	ATTEN 6
	NOTE A_, $0C
	RELEASE $0F, 2
	ATTEN 0
	NOTE E_, $0C
	ATTEN 6
	NOTE E_, $0C
	ATTEN 0
	NOTE E_, $0C
	ATTEN 7
	NOTE E_, 8
	ATTEN 0
	NOTE E_, $0C
	ATTEN 7
	NOTE E_, 4
	ATTEN 0
	NOTE E_, $0C
	NOTE A_, $0C
	NOTE A_, 8
	NOTE F#, $0C
	NOTE F#, 4
	RELEASE 0, $0F
	NOTE D_, $0C
	NOTE D_, 8
	RELEASE $0F, 2
	NOTE F#, $0C
	NOTE F#, 4
	NOTE B_, $0C
	NOTE A_, $0C
	RELEASE 0, $0F
	NOTE G#, $0C
	ATTEN 6
	NOTE G#, $0C
	ATTEN 0
	NOTE A_, $0C
	ATTEN 6
	NOTE A_, 8
	ATTEN 0
	NOTE B_, 4
	VIBRATO $01, 6, 0
	LEN_UNIT 4
	NOTE B_, $0C
	VIBRATO_OFF
	LEN_UNIT 1
	SND_RET
Snd8C_Ch2_412F:
	DUTY $0C
	RELEASE 0, $0F
	OCTAVE 4
	NOTE C#, $0C
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, $0C
	NOTE E_, $0C
	NOTE F#, $0C
	NOTE F#, 8
	NOTE B_, 4
	NOTE B_, $0C
	NOTE A_, $0C
	VIBRATO $01, 15, 2
	LEN_UNIT 4
	NOTE G#, $0C
	NOTE A_, $0C
	VIBRATO_OFF
	LEN_UNIT 1
	PAN $F0
	NOTE D_, 3
	PAN $FF
	NOTE D_, 9
	NOTE D_, 8
	NOTE F#, 4
	NOTE F#, $0C
	NOTE A_, $0C
	OCTAVE 4
	NOTE C#, $0C
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, $0C
	NOTE A_, $0C
	LEN_UNIT 8
	VIBRATO $08, 6, 0
	OCTAVE 4
	NOTE E_, $0C
	VIBRATO_OFF
	LEN_UNIT 4
	SND_RET
Snd8C_Ch1_4167:
	OCTAVE 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 2
	NOTE A_, 3
	OCTAVE 4
	NOTE C#, 4
	NOTE E_, 3
	NOTE C#, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F#, 3
	SND_RET
Snd8C_Ch2_4175:
	RELEASE $0F, 4
	NOTE E_, 9
	RELEASE $0F, 3
	OCTAVE 5
	NOTE E_, 2
	NOTE F#, 1
	NOTE E_, 3
	SND_RET
Snd8C_Ch2_417F:
	LEN_UNIT 1
	TRANSPOSE_UP 0
	DUTY $0C
	RELEASE 0, $0F
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	SND_REPEAT $18
	SND_SEGNO
	OCTAVE 5
	NOTE E_, 2
	NOTE F#, 2
	SND_REPEAT $15
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE $0F, 2
	SND_RET

Snd8C_Ch1:
	VOICE $04, 5, 12, 3, 14
Snd8C_Ch1_41A7:
	SND_CALL Snd8C_Ch1_41C6
	SND_CALL Snd8C_Ch1_41DA
	SND_CALL Snd8C_Ch1_41C6
	SND_CALL Snd8C_Ch1_41E3
	SND_CALL Snd8C_Ch1_41EF
	ATTEN 0
	TRANSPOSE_DOWN $0C
	DUTY $0C
	SND_CALL Snd8C_Ch1_4167
	TRANSPOSE_UP 0
	SND_CALL Snd8C_Ch1_42DD
	SND_CALL Snd8C_Ch1_41A7
Snd8C_Ch1_41C6:
	RELEASE $0E, 3
	OCTAVE 2
	NOTE E_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	SND_RET
Snd8C_Ch1_41DA:
	NOTE E_, 3
	OCTAVE 5
	NOTE D_, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 3
	SND_RET
Snd8C_Ch1_41E3:
	NOTE E_, 6
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	SND_RET
Snd8C_Ch1_41EF:
	LEN_UNIT 1
	ATTEN 2
	DETUNE $01
	FLAGS 2
	PAN $F0
	DUTY 8
	RELEASE 0, $0F
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	LEN_UNIT 3
	NOTE E_, $0C
	LEN_UNIT 1
	NOTE A_, 4
	NOTE B_, $0C
	OCTAVE 4
	NOTE C#, $0C
	OCTAVE 3
	NOTE A_, $0C
	OCTAVE 4
	NOTE D_, $0C
	ATTEN 3
	NOTE D_, $0C
	ATTEN 2
	NOTE C#, $0C
	ATTEN 3
	NOTE C#, $0C
	ATTEN 2
	OCTAVE 3
	NOTE A#, $0C
	ATTEN 3
	NOTE A#, 8
	ATTEN 2
	NOTE B_, $0C
	NOTE B_, $0C
	ATTEN 3
	NOTE B_, 4
	ATTEN 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	LEN_UNIT 3
	NOTE E_, $0C
	LEN_UNIT 1
	NOTE A_, 4
	NOTE B_, $0C
	OCTAVE 4
	NOTE C#, $0C
	NOTE E_, $0C
	NOTE D_, $0C
	ATTEN 3
	NOTE D_, $0C
	ATTEN 2
	NOTE E_, $0C
	ATTEN 3
	NOTE E_, $0C
	ATTEN 0
	SND_SEGNO
	RELEASE $0E, 3
	NOTE D_, 8
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 4
	SND_REPEAT $04
	FLAGS 0
	PAN $FF
	RELEASE 0, $0F
	ATTEN 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	NOTE E_, 4
	ATTEN 0
	RELEASE $0E, 4
	OCTAVE 4
	NOTE G_, 8
	NOTE F#, 4
	NOTE E_, 8
	OCTAVE 3
	NOTE A_, $0C
	NOTE E_, 4
	NOTE F#, $0C
	NOTE A_, $0C
	NOTE E_, $0C
	RELEASE 0, $0F
	NOTE A_, $0C
	ATTEN 3
	NOTE A_, $0C
	ATTEN 0
	NOTE F#, $0C
	ATTEN 3
	NOTE F#, $0C
	ATTEN 0
	NOTE D#, $0C
	ATTEN 3
	NOTE D#, 8
	ATTEN 0
	NOTE E_, 4
	NOTE E_, $0C
	ATTEN 3
	NOTE E_, $0C
	ATTEN 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 8
	NOTE E_, 4
	ATTEN 0
	RELEASE $0E, 4
	OCTAVE 4
	NOTE G_, 8
	NOTE F#, 4
	NOTE E_, 8
	OCTAVE 3
	NOTE A_, $0C
	NOTE E_, 4
	NOTE F#, $0C
	NOTE A_, $0C
	OCTAVE 4
	NOTE C#, $0C
	LEN_UNIT 4
	OCTAVE 3
	NOTE A_, 6
	NOTE A_, 6
	NOTE G#, 3
	NOTE A_, 2
	NOTE B_, 7
	DUTY $0C
	RELEASE $0E, 4
	OCTAVE 3
	NOTE D_, 3
	NOTE F#, 3
	NOTE A_, 2
	NOTE D_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE F#, 3
	NOTE A_, 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D#, 6
	NOTE D#, 5
	NOTE D#, 4
	NOTE D#, 3
	OCTAVE 3
	NOTE D_, 3
	NOTE F#, 3
	NOTE A_, 2
	NOTE D_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE F#, 3
	NOTE E_, 3
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE F#, 3
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE G#, 3
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	DUTY 8
	RELEASE 0, $0F
	OCTAVE 3
	NOTE E_, $0C
	OCTAVE 2
	NOTE A_, $0C
	NOTE B_, 5
	OCTAVE 3
	NOTE C#, 4
	NOTE D_, 3
	NOTE C#, 6
	NOTE F#, 6
	OCTAVE 2
	NOTE B_, $0C
	NOTE B_, $0C
	RELEASE $0E, 4
	OCTAVE 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE F#, 3
	NOTE F#, 3
	NOTE G#, 3
	NOTE E_, 2
	NOTE F#, 3
	NOTE G#, 4
	SND_RET
Snd8C_Ch1_42DD:
	NOTE E_, 9
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 1
	NOTE A_, 3
	OCTAVE 3
	NOTE F#, 3
	NOTE F#, 3
	NOTE G_, 3
	NOTE E_, 2
	NOTE F#, 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE E_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 9
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 3
	RELEASE 0, $0F
	OCTAVE 3
	NOTE E_, 6
	NOTE F#, 6
	NOTE G#, 6
	NOTE A_, 6
	NOTE B_, 6
	OCTAVE 4
	NOTE C#, 6
	NOTE D_, 6
	NOTE E_, 3
	LEN_UNIT 1
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
	LEN_UNIT 4
	SND_RET

Snd8C_Ch3:
	VOICE $01, 2, 12, 5, 14
Snd8C_Ch3_4318:
	RELEASE $0E, 5
	SND_CALL Snd8C_Ch3_4048
	TRANSPOSE_UP 0
	SND_CALL Snd8C_Ch3_4061
	WAVE $0C
	SND_CALL Snd8C_Ch3_4048
	TRANSPOSE_UP 0
	SND_CALL Snd8C_Ch3_434E
	SND_CALL Snd8C_Ch3_4357
	SND_CALL Snd8C_Ch3_4376
	SND_CALL Snd8C_Ch3_4385
	SND_CALL Snd8C_Ch3_4376
	SND_CALL Snd8C_Ch3_4395
	SND_CALL Snd8C_Ch3_43D2
	SND_CALL Snd8C_Ch3_43E0
	TRANSPOSE_UP 5
	SND_CALL Snd8C_Ch3_43D2
	TRANSPOSE_UP 0
	SND_CALL Snd8C_Ch3_43E8
	SND_CALL Snd8C_Ch3_4318
Snd8C_Ch3_434E:
	REST $0C
	REST $0C
	NOTE B_, 4
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE E_, 4
	SND_RET
Snd8C_Ch3_4357:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE C#, $0C
	OCTAVE 1
	NOTE G_, $0C
	NOTE B_, 8
	NOTE A_, $0C
	NOTE A_, 4
	OCTAVE 2
	NOTE C#, $0C
	OCTAVE 1
	NOTE G_, $0C
	NOTE A_, $0C
	NOTE B_, $0C
	OCTAVE 2
	NOTE A_, $0C
	NOTE D_, $0C
	NOTE A_, 8
	OCTAVE 1
	NOTE E_, $0C
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, $0C
	NOTE D_, $0C
	OCTAVE 1
	NOTE B_, $0C
	SND_REPEAT $04
	SND_RET
Snd8C_Ch3_4376:
	OCTAVE 2
	NOTE D_, $0C
	NOTE A_, $0C
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE C_, 8
	NOTE D_, $0C
	NOTE D_, 4
	NOTE A_, $0C
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE D_, $0C
	SND_RET
Snd8C_Ch3_4385:
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE E_, $0C
	NOTE F#, $0C
	NOTE E_, $0C
	NOTE A_, 8
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 8
	NOTE C#, $0C
	OCTAVE 2
	NOTE A_, 4
	NOTE F#, 8
	NOTE E_, 4
	SND_RET
Snd8C_Ch3_4395:
	NOTE E_, $0C
	NOTE B_, $0C
	OCTAVE 1
	NOTE B_, $0C
	OCTAVE 2
	NOTE E_, 8
	OCTAVE 1
	NOTE E_, $0C
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, $0C
	NOTE B_, 4
	NOTE G#, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE E_, 4
	LEN_UNIT 4
	WAVE $0C
	RELEASE 0, $0F
	OCTAVE 1
	NOTE A_, $0C
	OCTAVE 2
	NOTE D_, $0C
	NOTE E_, 6
	NOTE F_, 6
	NOTE F#, 6
	NOTE C#, 6
	NOTE D_, 8
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 3
	NOTE D#, 8
	OCTAVE 1
	NOTE D#, 1
	WAVE $0C
	RELEASE $0F, 7
	OCTAVE 2
	NOTE D#, 3
	OCTAVE 1
	NOTE E_, 3
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE B_, 3
	NOTE E_, 3
	OCTAVE 2
	NOTE E_, 3
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 3
	NOTE B_, 1
	NOTE E_, 3
	SND_RET
Snd8C_Ch3_43D2:
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 2
	NOTE A_, 3
	OCTAVE 2
	NOTE C#, 4
	NOTE E_, 3
	NOTE C#, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F#, 3
	SND_RET
Snd8C_Ch3_43E0:
	NOTE E_, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	SND_RET
Snd8C_Ch3_43E8:
	OCTAVE 2
	NOTE A_, 9
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE A_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE B_, 3
	NOTE D_, 3
	NOTE A_, 3
	SND_REPEAT $02
	LEN_UNIT 1
	SND_RET

Snd8C_Drm:
	DRUM_UNIT $01
Snd8C_Drm_4405:
	SND_CALL Snd8C_Drm_4417
	SND_CALL Snd8C_Drm_4432
	SND_CALL Snd8C_Drm_4432
	SND_CALL Snd8C_Drm_444C
	SND_CALL Snd8C_Drm_4432
	SND_CALL Snd8C_Drm_4405
Snd8C_Drm_4417:
	SND_SEGNO
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, 8
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, 8
	DRUM 3, 4
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, 8
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, 8
	DRUM 4, 4
	DRUM 4, 8
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	SND_REPEAT $02
	SND_RET
Snd8C_Drm_4432:
	SND_SEGNO
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, 8
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, 8
	DRUM 3, 4
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, $0C
	DRUM 4, 8
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, 8
	DRUM 5, 4
	DRUM 5, 8
	DRUM 3, 4
	DRUM 5, 8
	DRUM 5, 4
	SND_REPEAT $03
	SND_RET
Snd8C_Drm_444C:
	SND_SEGNO
	DRUM 5, $0C
	DRUM 5, 8
	DRUM 3, $0C
	DRUM 3, 4
	DRUM 4, 8
	DRUM 3, 4
	SND_REPEAT $02
	DRUM 5, $0C
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, 8
	DRUM 5, $0C
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, $0C
	DRUM 5, $0C
	SND_SEGNO
	DRUM 5, $0C
	DRUM 5, 8
	DRUM 3, $0C
	DRUM 3, 4
	DRUM 4, 8
	DRUM 3, 4
	SND_REPEAT $02
	DRUM 5, $0C
	DRUM 5, $0C
	DRUM 4, $0C
	DRUM 5, 8
	DRUM 5, $0C
	DRUM 5, 4
	DRUM 4, 8
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	SND_RET

Snd80_Ch2:
	TEMPO $00
	VOICE $05, 8, 0, 7, 15
	DETUNE $01
	ATTEN 5
	PAN $F0
	OCTAVE 2
	NOTE G_, 1
	SND_CALL Snd80_Ch1_44D6
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 3
Snd80_Ch2_448E:
	PAN $FF
	DETUNE $00
	RELEASE $0F, 3
	ATTEN 0
	DUTY_STEP 1, $0C
	SND_CALL Snd80_Ch1_44EB
	NOTE D_, 2
	SND_CALL Snd80_Ch2_4509
	DUTY 8
	TRANSPOSE_UP 3
	DUTY_STEP 1, $0C
	SND_CALL Snd80_Ch1_44EB
	NOTE D_, 2
	SND_CALL Snd80_Ch2_4509
	TRANSPOSE_UP 0
	DUTY 0
	DUTY_STEP 2, $0C
	SND_CALL Snd80_Ch1_451C
	DUTY $0C
	NOTE D_, 4
	SND_CALL Snd80_Ch2_4509
	DUTY 8
	DUTY_STEP 2, $0C
	SND_CALL Snd80_Ch1_4538
	ATTEN 3
	DUTY $0C
	NOTE D_, 1
	SND_CALL Snd80_Ch2_454F
	ATTEN 2
	TRANSPOSE_UP 4
	SND_CALL Snd80_Ch2_454F
	TRANSPOSE_UP 0
	SND_CALL Snd80_Ch2_4563
	SND_CALL Snd80_Ch2_448E
Snd80_Ch1_44D6:
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE F#, 4
	OCTAVE 2
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 1
	NOTE B_, 4
	SND_RET
Snd80_Ch1_44EB:
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd80_Ch2_4509:
	DUTY $0C
	DUTY_STEP 2, 0
	SND_SEGNO
	RELEASE $0F, $0D
	NOTE D#, 2
	RELEASE $0F, 3
	NOTE D_, 2
	SND_REPEAT $02
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_RET
Snd80_Ch1_451C:
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	SND_RET
Snd80_Ch1_4538:
	OCTAVE 4
	SND_SEGNO
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	SND_REPEAT $03
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	SND_REPEAT $03
	OCTAVE 3
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE D_, 3
	SND_RET
Snd80_Ch2_454F:
	VIBRATO $01, 3, 7
	RELEASE $0F, $0D
	NOTE D#, 2
	RELEASE $0F, 2
	NOTE D_, 2
	RELEASE $0F, $0D
	NOTE D#, 2
	RELEASE $0A, $0D
	NOTE D_, 8
	ATTEN 5
	NOTE D_, 2
	VIBRATO_OFF
	SND_RET
Snd80_Ch2_4563:
	DUTY 0
	ATTEN 2
	RELEASE $0D, $0D
	NOTE A#, 2
	RELEASE $0F, 3
	NOTE A_, 2
	RELEASE $0D, $0D
	NOTE A#, 2
	RELEASE $0F, 3
	NOTE A_, 2
	ATTEN 0
	RELEASE $0D, $0D
	OCTAVE 4
	NOTE D#, 2
	RELEASE $0F, 2
	NOTE D_, 2
	RELEASE $0D, $0D
	NOTE D#, 2
	RELEASE $0F, 2
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	SND_RET

Snd80_Ch1:
	VOICE $05, 5, 12, 15, 0
	ATTEN 3
	PAN $0F
	OCTAVE 2
	NOTE G_, 2
	SND_CALL Snd80_Ch1_44D6
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 2
	DETUNE $01
Snd80_Ch1_45A0:
	PAN $FF
	RELEASE 0, $0F
	ATTEN 3
	NOTE B_, 2
	SND_CALL Snd80_Ch1_44EB
	SND_CALL Snd80_Ch1_45D8
	TRANSPOSE_UP 3
	NOTE B_, 2
	SND_CALL Snd80_Ch1_44EB
	SND_CALL Snd80_Ch1_45D8
	TRANSPOSE_UP 0
	NOTE B_, 2
	SND_CALL Snd80_Ch1_451C
	NOTE D_, 2
	SND_CALL Snd80_Ch1_45D8
	OCTAVE 4
	NOTE D_, 1
	SND_CALL Snd80_Ch1_4538
	DETUNE $00
	SND_CALL Snd80_Ch1_45E9
	TRANSPOSE_UP 5
	SND_CALL Snd80_Ch1_45E9
	TRANSPOSE_UP 0
	DETUNE $01
	SND_CALL Snd80_Ch1_45F6
	SND_CALL Snd80_Ch1_45A0
Snd80_Ch1_45D8:
	RELEASE $0E, 3
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 3
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, $0F
	SND_RET
Snd80_Ch1_45E9:
	ATTEN 0
	RELEASE $0E, 3
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 0, $0F
	NOTE A_, 8
	ATTEN 3
	NOTE A_, 2
	SND_RET
Snd80_Ch1_45F6:
	ATTEN 0
	RELEASE $0E, 3
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	RELEASE $0F, 7
	ATTEN 2
	PAN $0F
	NOTE D_, 5
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 1
	SND_RET

Snd80_Ch3:
	VOICE $05, 2, 10, 5, 13
	SND_CALL Snd80_Ch1_44D6
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 4
Snd80_Ch3_461D:
	SND_CALL Snd80_Ch1_44D6
	SND_CALL Snd80_Ch3_4662
	TRANSPOSE_UP 3
	SND_CALL Snd80_Ch1_44D6
	SND_CALL Snd80_Ch3_4662
	TRANSPOSE_UP 0
	SND_CALL Snd80_Ch3_463D
	SND_CALL Snd80_Ch3_4662
	SND_CALL Snd80_Ch3_463D
	SND_CALL Snd80_Ch3_466E
	SND_CALL Snd80_Ch3_461D
	db $FF ; unreachable end
Snd80_Ch3_463D:
	FLAGS 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	SND_RET
Snd80_Ch3_4662:
	RELEASE $0F, 5
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 6
	NOTE D_, 2
	RELEASE $0D, 5
	SND_RET
Snd80_Ch3_466E:
	FLAGS 0
	PAN $FF
	RELEASE $0F, 5
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	SND_REPEAT $03
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	RELEASE $0D, 5
	SND_RET

Snd80_Drm:
	SND_END

Snd7F_Ch2:
	TEMPO $40
	TRANSPOSE_UP 0
	VOICE $04, 8, 12, 3, 15
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 4
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F#, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	SND_REPEAT $02
	RELEASE $0E, 5
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	TEMPO $30
	ATTEN 2
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	TEMPO $50
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	TEMPO $60
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	RELEASE $0D, 7
	NOTE G_, 6
	TEMPO $45
	ATTEN 0
	LEN_UNIT 1
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
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	VOICE $04, 10, 0, 3, 15
	DUTY_STEP 2, 4
	OCTAVE 3
	NOTE G#, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE F#, 4
	RELEASE $0F, 2
	LEN_UNIT 1
	OCTAVE 2
	NOTE G#, 5
	NOTE G#, 6
	OCTAVE 3
	NOTE D_, 5
	OCTAVE 2
	NOTE B_, $0B
	OCTAVE 3
	NOTE D_, 5
	OCTAVE 2
	NOTE B_, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	REST $0B
	OCTAVE 1
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	OCTAVE 2
	NOTE D_, 5
	NOTE D#, 6
	NOTE E_, 5
	SND_END

Snd7F_Ch1:
	PAN $F0
	VOICE $04, 4, 12, 4, 14
	REST 5
	OCTAVE 4
	NOTE E_, 1
	SND_SEGNO
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE E_, 1
	SND_REPEAT $02
	PAN $0F
	SND_SEGNO
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE G#, 1
	SND_REPEAT $02
	PAN $F0
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE G#, 1
	PAN $0F
	SND_SEGNO
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	SND_REPEAT $02
	PAN $FF
	SND_SEGNO
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	SND_REPEAT $02
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	ATTEN 2
	NOTE G_, 3
	ATTEN 3
	NOTE G_, 2
	ATTEN 1
	PAN $0F
	LEN_UNIT 1
	NOTE B_, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $F0
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	PAN $FF
	FLAGS 2
	PAN $F0
	LEN_UNIT 4
	OCTAVE 3
	NOTE G#, 5
	NOTE F#, 4
	NOTE G#, 4
	NOTE F#, 4
	LEN_UNIT 1
	OCTAVE 2
	NOTE G#, 5
	NOTE G#, 6
	OCTAVE 3
	NOTE D_, 5
	OCTAVE 2
	NOTE B_, $0B
	OCTAVE 3
	NOTE D_, 5
	OCTAVE 2
	NOTE B_, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	REST $0B
	OCTAVE 1
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	NOTE A#, $0B
	NOTE B_, 5
	OCTAVE 2
	NOTE D_, 5
	NOTE D#, 6
	NOTE E_, 4
	SND_END

Snd7F_Ch3:
	TRANSPOSE_UP 0
	VOICE $04, 2, 4, 3, 15
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, $0C
	REST 2
	TRANSPOSE_UP 0
	LEN_UNIT 1
	RELEASE $0F, 5
	WAVE 2
	NOTE E_, $0B
	NOTE B_, 5
	NOTE D_, $0B
	NOTE A_, 5
	NOTE E_, $0B
	NOTE B_, 5
	NOTE D_, $0B
	NOTE A_, 5
	RELEASE $0F, 4
	NOTE E_, 5
	NOTE E_, 6
	NOTE B_, 5
	OCTAVE 5
	NOTE D_, $0B
	OCTAVE 4
	NOTE B_, 5
	VIBRATO $08, 10, 1
	LEN_UNIT 8
	RELEASE 0, $0F
	OCTAVE 5
	NOTE D_, $0C
	LEN_UNIT 1
	RELEASE $0F, 3
	OCTAVE 4
	NOTE D_, 5
	NOTE D#, 6
	NOTE E_, 5
	SND_END

Snd7F_Drm:
	DRUM_UNIT $08
	REST $0A
	REST 8
	REST $0A
	LEN_UNIT 1
	REST 4
	DRUM 3, $0B
	DRUM 3, 5
	DRUM 3, $0B
	DRUM 3, 5
	DRUM 3, $0B
	DRUM 3, 5
	DRUM 3, $0B
	DRUM 3, 5
	SND_SEGNO
	DRUM 3, 5
	DRUM 3, 6
	DRUM 3, 5
	DRUM 4, $0B
	DRUM 4, 5
	DRUM 4, $0B
	DRUM 4, 5
	DRUM 4, $0B
	DRUM 4, 5
	SND_REPEAT $02
	DRUM 4, 5
	DRUM 4, 6
	DRUM 4, 5
	SND_END

; Orphan drum stream (no header points here).
B15_Data_483B:
	DRUM_UNIT $01
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 5, 8
	DRUM 3, 4
	DRUM 4, 8
	DRUM 3, $0C
	DRUM 3, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 5, 8
	DRUM 3, 4
	DRUM 4, 8
	DRUM 3, $0C
	DRUM 3, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 4
	DRUM 4, 8
	SND_END

Snd8F_Ch2:
	TEMPO $00
	DUTY_STEP 2, 8
	VOICE $06, 8, 0, 2, 15
	VIBRATO $01, 0, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE C_, 2
	RELEASE $0F, 4
	NOTE C_, 4
	RELEASE $0F, 2
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 4
	RELEASE $0E, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	SND_END

Snd8F_Ch1:
	DETUNE $81
	VOICE $06, 6, 4, 2, 14
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F#, 2
	RELEASE $0E, 4
	NOTE F#, 4
	RELEASE $0E, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 4
	RELEASE $0E, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	SND_END

Snd8F_Ch3:
	VOICE $06, 2, 2, 3, 14
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 4
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE A_, 2
	SND_END

Snd8F_Drm:
	DRUM_UNIT $06
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_REPEAT $03
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_END

Snd88_Ch2:
	TEMPO $50
	DUTY_STEP 2, 0
	VOICE $01, 8, 12, 3, 15
	OCTAVE 4
	NOTE G_, $0A
	NOTE A#, 3
	NOTE B_, 3
	NOTE F_, $0A
	NOTE G#, 3
	NOTE A_, 3
	NOTE D#, $0A
	NOTE F#, 3
	NOTE G_, 3
	NOTE C#, $0A
	NOTE E_, 3
	NOTE F_, 3
	LEN_UNIT 4
	RELEASE $0E, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	VIBRATO $08, 2, 1
	RELEASE $0A, 7
	NOTE C_, $0A
	SND_END

Snd88_Ch1:
	DETUNE $01
	VOICE $01, 5, 0, 4, 15
	OCTAVE 3
	NOTE B_, $0A
	OCTAVE 4
	NOTE D_, 3
	NOTE D#, 3
	OCTAVE 3
	NOTE A_, $0A
	OCTAVE 4
	NOTE C_, 3
	NOTE C#, 3
	OCTAVE 3
	NOTE G_, $0A
	NOTE A#, 3
	NOTE B_, 3
	NOTE F_, $0A
	NOTE G#, 3
	NOTE A_, 3
	LEN_UNIT 4
	RELEASE $0E, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	VIBRATO $08, 2, 2
	RELEASE 8, 7
	NOTE E_, $0A
	SND_END

Snd88_Ch3:
	VOICE $01, 2, 12, 5, 13
	OCTAVE 2
	NOTE G_, $0A
	NOTE A#, 3
	NOTE B_, 3
	NOTE F_, $0A
	NOTE G#, 3
	NOTE A_, 3
	NOTE D#, $0A
	NOTE F#, 3
	NOTE G_, 3
	NOTE C#, $0A
	NOTE E_, 3
	NOTE F_, 3
	LEN_UNIT 4
	RELEASE $0F, 3
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	RELEASE 0, $0F
	OCTAVE 2
	NOTE C_, $0A
	SND_END

Snd88_Drm:
	SND_END
	db $FF ; unreachable end

Snd89_Ch2:
	TEMPO $20
	TRANSPOSE_UP 5
	VOICE $04, 8, 12, 3, 15
	PAN $F0
	DUTY_STEP 2, 8
	OCTAVE 2
	SND_CALL Snd89_Ch1_4974
	DUTY_STEP 1, 0
Snd89_Ch2_495B:
	PAN $FF
	SND_CALL Snd89_Ch2_4983
	SND_CALL Snd89_Ch1_498E
	NOTE D_, 1
	SND_CALL Snd89_Ch2_49A7
	SND_CALL Snd89_Ch1_49B1
	PAN $F0
	NOTE G_, 1
	SND_CALL Snd89_Ch1_4A63
	NOTE B_, 1
	SND_CALL Snd89_Ch2_495B
Snd89_Ch1_4974:
	SND_SEGNO
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D#, 3
	NOTE C_, 1
	NOTE D#, 3
	NOTE E_, 4
	NOTE C_, 1
	NOTE E_, 3
	NOTE C_, 1
	SND_REPEAT $02
	SND_RET
Snd89_Ch2_4983:
	REST 4
	OCTAVE 3
	NOTE D#, 3
	NOTE D_, 1
	NOTE C_, 4
	NOTE D#, 3
	NOTE D_, 1
	NOTE C_, 4
	NOTE D#, 3
	NOTE D_, 1
	SND_RET
Snd89_Ch1_498E:
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 3
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 3
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 1
	NOTE D#, 3
	NOTE D_, 1
	NOTE D#, 3
	NOTE G_, 4
	NOTE F_, 1
	NOTE D#, 3
	SND_RET
Snd89_Ch2_49A7:
	REST 4
	NOTE G#, 3
	NOTE G_, 1
	NOTE F_, 4
	NOTE G#, 3
	NOTE G_, 1
	NOTE F_, 4
	NOTE G#, 3
	NOTE G_, 1
	SND_RET
Snd89_Ch1_49B1:
	NOTE F_, 3
	NOTE E_, 1
	NOTE F_, 3
	NOTE G_, 1
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 3
	NOTE G_, 1
	NOTE F_, 3
	NOTE D#, 1
	NOTE D_, 3
	NOTE D#, 1
	NOTE F_, 3
	NOTE D_, 1
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 3
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 4
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 3
	NOTE G_, 4
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 3
	NOTE F#, 4
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE F#, 3
	SND_RET

Snd89_Ch1:
	VOICE $04, 6, 8, 3, 14
	TRANSPOSE_UP 5
	DETUNE $01
	PAN $0F
	OCTAVE 2
	SND_CALL Snd89_Ch1_4974
Snd89_Ch1_49EB:
	PAN $FF
	SND_CALL Snd89_Ch1_4A1B
	FLAGS 2
	PAN $F0
	RELEASE 0, $0F
	NOTE C_, 1
	SND_CALL Snd89_Ch1_498E
	FLAGS 0
	PAN $FF
	SND_CALL Snd89_Ch1_4A27
	FLAGS 2
	PAN $F0
	RELEASE 0, $0F
	NOTE F_, 1
	SND_CALL Snd89_Ch1_49B1
	FLAGS 0
	PAN $FF
	ATTEN 0
	PAN $0F
	RELEASE $0E, 3
	NOTE G_, 1
	SND_CALL Snd89_Ch1_4A63
	SND_CALL Snd89_Ch1_49EB
Snd89_Ch1_4A1B:
	OCTAVE 2
	ATTEN 0
	RELEASE $0F, 4
	REST 4
	NOTE A_, 4
	REST 4
	NOTE A_, 4
	REST 4
	NOTE A_, 4
	ATTEN 3
	SND_RET
Snd89_Ch1_4A27:
	ATTEN 0
	RELEASE $0F, 4
	OCTAVE 3
	REST 4
	NOTE D_, 4
	REST 4
	NOTE D_, 4
	REST 4
	NOTE D_, 4
	ATTEN 3
	SND_RET

Snd89_Ch3:
	VOICE $04, 2, 2, 5, 15
	TRANSPOSE_UP 5
	OCTAVE 1
	SND_CALL Snd89_Ch1_4974
Snd89_Ch3_4A3D:
	SND_CALL Snd89_Ch3_4A47
	SND_CALL Snd89_Ch3_4A74
	NOTE B_, 1
	SND_CALL Snd89_Ch3_4A3D
Snd89_Ch3_4A47:
	OCTAVE 1
	SND_SEGNO
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	SND_REPEAT $03
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	SND_SEGNO
	NOTE A#, 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE F_, 4
	SND_REPEAT $04
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	SND_RET
Snd89_Ch1_4A63:
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 3
	NOTE C#, 1
	NOTE D_, 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE F_, 1
	NOTE F#, 3
	NOTE G_, 1
	NOTE G#, 3
	NOTE A_, 1
	NOTE A#, 3
	SND_RET
Snd89_Ch3_4A74:
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 3
	NOTE C#, 1
	NOTE D_, 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE F_, 1
	NOTE F#, 3
	NOTE G_, 1
	NOTE G#, 3
	NOTE A_, 1
	NOTE A#, 3
	SND_RET

Snd89_Drm:
	DRUM_UNIT $04
Snd89_Drm_4A87:
	SND_SEGNO
	DRUM 6, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 3, 1
	SND_REPEAT $03
	DRUM 6, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 4, 1
	SND_CALL Snd89_Drm_4A87

Snd83_Ch2:
	TEMPO $30
	TRANSPOSE_UP 0
	VOICE $03, 8, 12, 3, 15
	DUTY_STEP 1, 8
	OCTAVE 4
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	TEMPO $20
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
Snd83_Ch2_4ABD:
	SND_CALL Snd83_Ch1_4AD4
	NOTE E_, 1
	SND_CALL Snd83_Ch2_4B28
	SND_CALL Snd83_Ch2_4B42
	SND_CALL Snd83_Ch1_4AD4
	NOTE E_, 1
	SND_CALL Snd83_Ch2_4B28
	SND_CALL Snd83_Ch2_4B77
	SND_CALL Snd83_Ch2_4ABD
Snd83_Ch1_4AD4:
	OCTAVE 3
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	PAN $F0
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	PAN $FF
	OCTAVE 4
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	PAN $0F
	OCTAVE 5
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	PAN $FF
	OCTAVE 4
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	REST 2
	PAN $F0
	NOTE F_, 2
	NOTE F#, 2
	REST 2
	PAN $FF
	OCTAVE 4
	NOTE F_, 2
	NOTE F#, 2
	REST 2
	PAN $0F
	OCTAVE 5
	NOTE F_, 2
	NOTE F#, 2
	REST 2
	PAN $FF
	OCTAVE 4
	NOTE F_, 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	SND_RET
Snd83_Ch2_4B28:
	RELEASE $0F, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 4
	RELEASE $0F, 6
	NOTE D_, $0A
	REST 4
	RELEASE $0F, 4
	OCTAVE 3
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd83_Ch2_4B42:
	NOTE F#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	RELEASE $0F, 3
	OCTAVE 4
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	SND_SEGNO
	OCTAVE 4
	NOTE A_, 2
	PAN $F0
	NOTE A_, 2
	PAN $FF
	ATTEN 5
	SND_REPEAT $02
	ATTEN 0
	SND_RET
Snd83_Ch2_4B77:
	NOTE F#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0F, 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 5
	PAN $F0
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	REST 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 5
	PAN $F0
	NOTE D_, 2
	PAN $0F
	NOTE D_, 4
	PAN $FF
	ATTEN 0
	SND_RET

Snd83_Ch1:
	TRANSPOSE_UP 0
	DETUNE $01
	VOICE $03, 5, 8, 15, 0
	ATTEN 3
	OCTAVE 4
	NOTE A_, 3
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 1
Snd83_Ch1_4BCF:
	RELEASE 0, $0F
	ATTEN 3
	OCTAVE 3
	NOTE F#, 1
	SND_CALL Snd83_Ch1_4AD4
	SND_CALL Snd83_Ch1_4BE9
	SND_CALL Snd83_Ch1_4C1A
	SND_CALL Snd83_Ch1_4C42
	SND_CALL Snd83_Ch1_4BE9
	SND_CALL Snd83_Ch1_4C61
	SND_CALL Snd83_Ch1_4BCF
Snd83_Ch1_4BE9:
	RELEASE $0E, 3
	ATTEN 0
	REST 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	PAN $F0
	NOTE D_, 2
	PAN $FF
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	PAN $F0
	NOTE D_, 2
	PAN $FF
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd83_Ch1_4C1A:
	RELEASE $0E, 3
	NOTE D_, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 4
	NOTE E_, 2
	NOTE B_, 4
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	REST 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE C#, 2
	RELEASE $0F, 2
	OCTAVE 4
	NOTE G#, 4
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE G#, 4
	REST 4
	SND_RET
Snd83_Ch1_4C42:
	RELEASE 0, $0F
	OCTAVE 4
	NOTE D_, 8
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 8
	NOTE G_, $0F
	VIBRATO $08, 3, 2
	NOTE G_, $0F
	REST 2
	VIBRATO_OFF
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE F#, $0F
	VIBRATO $08, 3, 2
	NOTE F#, $0F
	REST 2
	VIBRATO_OFF
	SND_RET
Snd83_Ch1_4C61:
	NOTE D_, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 4
	REST 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	PAN $0F
	NOTE D_, 2
	PAN $FF
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	REST 6
	RELEASE 0, $0F
	SND_RET

Snd83_Ch3:
	TRANSPOSE_DOWN $0C
	VOICE $03, 2, 12, 4, 15
	OCTAVE 2
	NOTE A_, 8
	REST 8
	NOTE A_, 8
	OCTAVE 2
	REST 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
Snd83_Ch3_4C9B:
	SND_CALL Snd83_Ch3_4CAA
	SND_CALL Snd83_Ch3_4CE6
	SND_CALL Snd83_Ch3_4CAA
	SND_CALL Snd83_Ch3_4CFF
	SND_CALL Snd83_Ch3_4C9B
Snd83_Ch3_4CAA:
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT $08
	SND_SEGNO
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE D_, 2
	NOTE A_, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE C_, 2
	NOTE A_, 2
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G_, 2
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT $04
	SND_RET
Snd83_Ch3_4CE6:
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	SND_REPEAT $04
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 4
	REST 6
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 4
	SND_RET
Snd83_Ch3_4CFF:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT $04
	NOTE D_, 4
	REST 2
	NOTE G_, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST 6
	SND_RET

Snd83_Drm:
	DRUM_UNIT $03
	DRUM 5, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 5, 4
	DRUM 3, 4
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
Snd83_Drm_4D1E:
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 6, 2
	SND_REPEAT $0F
	DRUM 4, $0A
	DRUM 5, 2
	DRUM 6, 4
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 6, 2
	SND_REPEAT $0E
	DRUM 4, 4
	DRUM 5, 2
	DRUM 4, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 6, 4
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	SND_CALL Snd83_Drm_4D1E

Snd85_Ch2:
	TRANSPOSE_UP 5
	TEMPO $20
	SND_CALL Snd84_Ch2_4D4F

Snd84_Ch2:
	TEMPO $10
Snd84_Ch2_4D4F:
	VOICE $06, 8, 8, 2, 15
	DUTY_STEP 1, 4
Snd84_Ch2_4D55:
	SND_CALL Snd84_Ch1_4D6C
	OCTAVE 3
	NOTE E_, 1
	SND_CALL Snd84_Ch2_4E00
	SND_CALL Snd84_Ch1_4E19
	OCTAVE 3
	NOTE F_, 1
	SND_CALL Snd84_Ch2_4E31
	SND_CALL Snd84_Ch1_4E56
	NOTE D_, 1
	SND_CALL Snd84_Ch2_4D55
Snd84_Ch1_4D6C:
	OCTAVE 3
	NOTE G_, 2
	NOTE E_, 1
	NOTE A_, 2
	NOTE E_, 1
	NOTE B_, 2
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE A_, 2
	NOTE E_, 1
	NOTE B_, 2
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE A_, 2
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE A_, 2
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 4
	REST 4
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 1
	SND_RET
Snd84_Ch2_4E00:
	OCTAVE 4
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd84_Ch1_4E08:
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	SND_RET
Snd84_Ch1_4E17:
	ATTEN 3
	NOTE G_, 1
Snd84_Ch1_4E19:
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET
Snd84_Ch2_4E31:
	OCTAVE 4
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 2
	NOTE E_, 2
	SND_RET
Snd84_Ch1_4E39:
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_RET
Snd84_Ch1_4E53:
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
Snd84_Ch1_4E56:
	SND_SEGNO
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 2
	SND_REPEAT $02
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET

Snd85_Ch1:
	TRANSPOSE_UP 5

Snd84_Ch1:
	DETUNE $01
	VOICE $06, 5, 12, 15, 0
	ATTEN 3
Snd84_Ch1_4E91:
	OCTAVE 3
	NOTE G_, 1
	SND_CALL Snd84_Ch1_4D6C
	RELEASE $0E, 5
	SND_CALL Snd84_Ch1_4E08
	RELEASE 0, $0F
	SND_CALL Snd84_Ch1_4E17
	RELEASE $0E, 5
	SND_CALL Snd84_Ch1_4E39
	RELEASE 0, $0F
	SND_CALL Snd84_Ch1_4E53
	SND_CALL Snd84_Ch1_4E91

Snd85_Ch3:
	TRANSPOSE_UP 5

Snd84_Ch3:
	VOICE $06, 2, 2, 5, 15
Snd84_Ch3_4EB3:
	SND_CALL Snd84_Ch3_4EC8
	SND_CALL Snd84_Ch3_4EE2
	SND_CALL Snd84_Ch3_4EFF
	SND_CALL Snd84_Ch3_4F0C
	SND_CALL Snd84_Ch3_4EE2
	SND_CALL Snd84_Ch3_4F29
	SND_CALL Snd84_Ch3_4EB3
Snd84_Ch3_4EC8:
	OCTAVE 2
	SND_SEGNO
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $03
	SND_SEGNO
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $04
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_RET
Snd84_Ch3_4EE2:
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE F#, 2
	SND_RET
Snd84_Ch3_4EFF:
	RELEASE $0F, 7
	OCTAVE 1
	NOTE G_, 6
	NOTE G_, 6
	NOTE G_, 6
	NOTE G_, 8
	RELEASE $0F, 5
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_RET
Snd84_Ch3_4F0C:
	OCTAVE 2
	SND_SEGNO
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_SEGNO
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_RET
Snd84_Ch3_4F29:
	RELEASE 0, $0F
	OCTAVE 1
	NOTE G_, 8
	NOTE G_, 8
	RELEASE $0F, 5
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	REST 2
	OCTAVE 1
	NOTE G_, 4
	SND_RET

Snd84_Drm:
	DRUM_UNIT $06
Snd84_Drm_4F3C:
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $0F
	SND_CALL Snd84_Drm_4F3C

Snd87_Ch2:
	TEMPO $24
	DUTY_STEP 1, 8
	VOICE $03, 8, 0, 2, 15
	REST 8
Snd87_Ch2_4F53:
	SND_CALL Snd87_Ch2_4F73
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	SND_CALL Snd87_Ch2_4F73
	DUTY $0C
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	TRANSPOSE_UP 5
	SND_CALL Snd87_Ch2_4F73
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	TRANSPOSE_UP 0
	SND_CALL Snd87_Ch2_4FAB
	DUTY 0
	SND_CALL Snd87_Ch2_4F53
Snd87_Ch2_4F73:
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 8, $0F
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 8, $0F
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	RELEASE $0F, 2
	SND_RET
Snd87_Ch2_4FAB:
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE $0F, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 2
	RELEASE 8, $0F
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	RELEASE $0F, 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	SND_RET

Snd87_Ch1:
	VOICE $03, 5, 12, 15, 0
	REST 8
Snd87_Ch1_4FDF:
	DETUNE $81
	RELEASE 0, $0F
	ATTEN 3
	OCTAVE 3
	NOTE G_, 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, $0A
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	DETUNE $00
	ATTEN 0
	RELEASE $0F, 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	RELEASE $0A, 7
	NOTE B_, $0A
	RELEASE $0F, 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 4
	RELEASE $0E, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	DUTY 8
	RELEASE 8, 7
	NOTE G_, 8
	DETUNE $81
	OCTAVE 4
	NOTE C_, 8
	DETUNE $00
	OCTAVE 3
	NOTE F_, 6
	NOTE E_, $0A
	NOTE G_, 8
	DETUNE $81
	OCTAVE 4
	NOTE C_, 8
	DETUNE $00
	RELEASE $0F, 3
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE $0A, 7
	NOTE E_, $0A
	RELEASE $0F, 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 2
	RELEASE $0E, 4
	NOTE E_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE F#, 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	RELEASE $0E, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	DUTY $0C
	SND_CALL Snd87_Ch1_4FDF

Snd87_Ch3:
	VOICE $03, 2, 2, 5, 15
	REST 8
Snd87_Ch3_5084:
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE $0F, 4
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	RELEASE $0F, 5
	SND_CALL Snd87_Ch3_5084

Snd87_Drm:
	DRUM_UNIT $03
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
Snd87_Drm_5117:
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	SND_REPEAT $07
	DRUM 5, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $07
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	SND_CALL Snd87_Drm_5117

Snd81_Ch2:
	TEMPO $20
	VOICE $04, 8, 8, 3, 15
Snd81_Ch2_5146:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 4
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 4
	SND_REPEAT $04
	SND_CALL Snd81_Ch2_5146

Snd81_Ch1:
	DETUNE $01
	VOICE $04, 2, 8, 15, 0
Snd81_Ch1_5159:
	OCTAVE 4
	NOTE D_, 2
	SND_CALL Snd81_Ch1_5170
	NOTE C#, 2
	SND_CALL Snd81_Ch1_5159

Snd81_Ch3:
	TRANSPOSE_UP 0
	VOICE $04, 2, 4, 7, 15
Snd81_Ch3_5168:
	SND_CALL Snd81_Ch1_5170
	NOTE C#, 3
	NOTE A_, 1
	SND_CALL Snd81_Ch3_5168
Snd81_Ch1_5170:
	OCTAVE 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE C#, 4
	NOTE A_, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 4
	NOTE A_, 1
	NOTE C#, 3
	NOTE D_, 4
	NOTE A_, 1
	NOTE D_, 3
	NOTE C#, 4
	NOTE A_, 1
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 4
	NOTE A_, 1
	SND_RET

Snd81_Drm:
	DRUM_UNIT $04
Snd81_Drm_5191:
	SND_SEGNO
	DRUM 5, 4
	DRUM 4, 3
	DRUM 5, 4
	DRUM 5, 1
	DRUM 4, 3
	DRUM 3, 1
	SND_REPEAT $04
	SND_CALL Snd81_Drm_5191

Snd86_Ch2:
	VOICE $07, 8, 12, 2, 15
	DUTY_STEP 1, 8
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	REST 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	REST 2
	RELEASE $0F, 3
	SND_CALL Snd86_Ch2_51D9
	SND_CALL Snd86_Ch2_5207
	SND_CALL Snd86_Ch2_51D9
	SND_CALL Snd86_Ch2_520C
Snd86_Ch2_51C0:
	TRANSPOSE_UP 5
	SND_CALL Snd86_Ch2_51D9
	SND_CALL Snd86_Ch2_5207
	TRANSPOSE_UP 0
	SND_CALL Snd86_Ch2_51D9
	SND_CALL Snd86_Ch2_5207
	SND_CALL Snd86_Ch2_51D9
	SND_CALL Snd86_Ch2_520C
	SND_CALL Snd86_Ch2_51C0
Snd86_Ch2_51D9:
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd86_Ch2_5207:
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_RET
Snd86_Ch2_520C:
	LEN_UNIT 1
	NOTE A_, 9
	NOTE B_, $0A
	OCTAVE 4
	NOTE C#, 9
	LEN_UNIT 7
	SND_RET

Snd86_Ch1:
	VOICE $07, 6, 8, 15, 0
	DETUNE $01
	ATTEN 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 0
	DETUNE $00
	RELEASE $0E, 3
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 2
	REST 2
	SND_CALL Snd86_Ch1_5254
	SND_CALL Snd86_Ch1_5291
	SND_CALL Snd86_Ch1_5254
	SND_CALL Snd86_Ch1_5297
Snd86_Ch1_523B:
	TRANSPOSE_UP 5
	SND_CALL Snd86_Ch1_5254
	SND_CALL Snd86_Ch1_5291
	TRANSPOSE_UP 0
	SND_CALL Snd86_Ch1_5254
	SND_CALL Snd86_Ch1_5291
	SND_CALL Snd86_Ch1_5254
	SND_CALL Snd86_Ch1_5297
	SND_CALL Snd86_Ch1_523B
Snd86_Ch1_5254:
	OCTAVE 3
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	SND_RET
Snd86_Ch1_5291:
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	SND_RET
Snd86_Ch1_5297:
	LEN_UNIT 1
	NOTE E_, 9
	NOTE G_, $0A
	NOTE A_, 9
	LEN_UNIT 7
	SND_RET

Snd86_Ch3:
	VOICE $07, 2, 12, 6, 15
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 1
	NOTE G#, 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	REST 2
	SND_SEGNO
	SND_CALL Snd86_Ch3_52E2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	SND_CALL Snd86_Ch3_52E2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	SND_REPEAT $02
Snd86_Ch3_52BE:
	TRANSPOSE_UP 5
	SND_SEGNO
	SND_CALL Snd86_Ch3_52E2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	SND_REPEAT $02
	TRANSPOSE_UP 0
	SND_SEGNO
	SND_CALL Snd86_Ch3_52E2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	SND_CALL Snd86_Ch3_52E2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	SND_REPEAT $02
	SND_CALL Snd86_Ch3_52BE
Snd86_Ch3_52E2:
	OCTAVE 2
	NOTE D_, 3
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $F0
	NOTE D_, 1
	PAN $FF
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	PAN $0F
	NOTE E_, 1
	PAN $FF
	NOTE E_, 2
	NOTE E_, 1
	SND_RET

Snd86_Drm:
	DRUM_UNIT $07
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 3
	DRUM 4, 1
	DRUM 4, 2
Snd86_Drm_5316:
	SND_SEGNO
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	SND_REPEAT $1E
	SND_CALL Snd86_Drm_5316

Snd8A_Ch2:
	VOICE $05, 8, 12, 2, 15
	TEMPO $40
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 3
	TEMPO $30
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 6
	TEMPO $20
	SND_CALL Snd8A_Ch1_5365
	TEMPO $10
	TRANSPOSE_UP 9
	SND_CALL Snd8A_Ch1_5365
Snd8A_Ch2_534A:
	TEMPO $00
	TRANSPOSE_UP 0
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 3
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 6
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 9
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 0
	SND_CALL Snd8A_Ch2_534A
Snd8A_Ch1_5365:
	VIBRATO $08, 2, 7
	SND_SEGNO
	RELEASE $0F, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE $0F, 6
	NOTE C#, 6
	SND_REPEAT $02
	SND_RET

Snd8A_Ch1:
	DETUNE $01
	VOICE $05, 5, 8, 2, 15
Snd8A_Ch1_5384:
	PAN $F0
	SND_CALL Snd8A_Ch1_5365
	PAN $0F
	TRANSPOSE_UP 3
	SND_CALL Snd8A_Ch1_5365
	PAN $F0
	TRANSPOSE_UP 6
	SND_CALL Snd8A_Ch1_5365
	PAN $0F
	TRANSPOSE_UP 9
	SND_CALL Snd8A_Ch1_5365
	TRANSPOSE_UP 0
	SND_CALL Snd8A_Ch1_5384

Snd8A_Ch3:
	VOICE $05, 2, 2, 5, 15
	SND_CALL Snd8A_Ch3_53D2
	TRANSPOSE_UP 3
	SND_CALL Snd8A_Ch3_53D2
	TRANSPOSE_UP 6
	SND_CALL Snd8A_Ch3_53DB
	TRANSPOSE_UP 9
	SND_CALL Snd8A_Ch3_53DB
Snd8A_Ch3_53B9:
	TRANSPOSE_UP 0
	SND_CALL Snd8A_Ch3_53E8
	TRANSPOSE_UP 3
	SND_CALL Snd8A_Ch3_53E8
	TRANSPOSE_UP 6
	SND_CALL Snd8A_Ch3_53E8
	TRANSPOSE_UP 9
	SND_CALL Snd8A_Ch3_53E8
	TRANSPOSE_UP 0
	SND_CALL Snd8A_Ch3_53B9
Snd8A_Ch3_53D2:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	NOTE A_, 4
	SND_REPEAT $02
	SND_RET
Snd8A_Ch3_53DB:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_REPEAT $02
	SND_RET
Snd8A_Ch3_53E8:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	SND_REPEAT $02
	SND_RET

Snd8A_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 4
	DRUM 5, 4
	SND_REPEAT $02
	SND_SEGNO
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	SND_REPEAT $02
	SND_SEGNO
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $04
Snd8A_Drm_5414:
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $10
	SND_CALL Snd8A_Drm_5414

Snd8B_Ch2:
	TEMPO $00
	DUTY_STEP 1, 8
	VOICE $07, 8, 0, 2, 15
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE G_, 1
	SND_END

Snd8B_Ch1:
	DETUNE $01
	PAN $F0
	VOICE $07, 5, 12, 3, 14
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	PAN $FF
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 1
	SND_END

Snd8B_Ch3:
	VOICE $07, 2, 2, 7, 8
	OCTAVE 2
	NOTE D_, $0A
	RELEASE $0F, 4
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	SND_END

Snd8B_Drm:
	SND_END

Snd82_Ch2:
	TEMPO $25
	VOICE $04, 8, 0, 4, 15
Snd82_Ch2_5466:
	SND_CALL Snd82_Ch1_546D
	REST 4
	SND_CALL Snd82_Ch2_5466
Snd82_Ch1_546D:
	OCTAVE 3
	NOTE G_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	NOTE F_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	NOTE F_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	NOTE F_, 3
	NOTE D_, 1
	NOTE F#, 3
	NOTE D_, 1
	NOTE F_, 3
	NOTE F#, 1
	NOTE F_, 3
	NOTE F#, 1
	REST 4
	NOTE F_, 3
	NOTE F#, 1
	NOTE F_, 3
	NOTE F#, 1
	SND_RET

Snd82_Ch1:
	DETUNE $01
	VOICE $04, 3, 12, 15, 0
	PAN $0F
Snd82_Ch1_549A:
	OCTAVE 3
	NOTE G_, 1
	SND_CALL Snd82_Ch1_546D
	REST 3
	SND_CALL Snd82_Ch1_549A

Snd82_Ch3:
	VIBRATO $08, 10, 4
	VOICE $08, 2, 12, 15, 0
Snd82_Ch3_54AA:
	RELEASE 0, $0F
	OCTAVE 1
	NOTE G_, $0C
	NOTE A#, $0C
	LEN_UNIT 4
	RELEASE 7, 7
	OCTAVE 2
	NOTE C#, 3
	NOTE D_, 1
	NOTE C#, 3
	NOTE D_, 1
	REST 4
	OCTAVE 2
	NOTE C#, 3
	NOTE D_, 1
	NOTE C#, 3
	NOTE D_, 1
	REST 4
	LEN_UNIT 8
	SND_CALL Snd82_Ch3_54AA

Snd82_Drm:
	DRUM_UNIT $04
Snd82_Drm_54C6:
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 3
	DRUM 3, 1
	DRUM 3, 4
	DRUM 3, 4
	DRUM 4, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 4, 4
	SND_CALL Snd82_Drm_54C6

Snd8E_Ch2:
	TEMPO $00
	VOICE $06, 8, 12, 3, 15
	REST 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	DUTY_STEP 2, 0
	NOTE F#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE A_, 2
	PAN $0F
	NOTE A_, 1
	PAN $FF
	OCTAVE 4
	NOTE D_, 2
	PAN $F0
	NOTE D_, 1
	PAN $FF
	NOTE D_, 2
	NOTE D_, 3
	PAN $0F
	NOTE D_, 1
	NOTE D_, 1
	PAN $FF
	DUTY_STEP_OFF
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
Snd8E_Ch2_5511:
	DUTY_STEP 2, 8
	SND_CALL Snd8E_Ch1_553C
	SND_CALL Snd8E_Ch1_555F
	SND_CALL Snd8E_Ch1_553C
	SND_CALL Snd8E_Ch1_5562
	RELEASE $0F, 2
	SND_CALL Snd8E_Ch2_5576
	SND_CALL Snd8E_Ch1_557C
	RELEASE $0F, 2
	SND_CALL Snd8E_Ch1_5584
	SND_CALL Snd8E_Ch2_5592
	TRANSPOSE_UP $0C
	RELEASE $0F, 2
	SND_CALL Snd8E_Ch1_5584
	SND_CALL Snd8E_Ch2_55AD
	SND_CALL Snd8E_Ch2_5511
Snd8E_Ch1_553C:
	SND_SEGNO
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	SND_REPEAT $02
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 2
	NOTE B_, 3
	NOTE G_, 3
	NOTE F_, 2
	NOTE E_, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 3
	SND_RET
Snd8E_Ch1_555F:
	NOTE E_, 2
	NOTE D_, 1
	SND_RET
Snd8E_Ch1_5562:
	NOTE E_, 3
	NOTE D#, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 2
	NOTE D#, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE G_, 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 3
	NOTE C#, 1
	NOTE C#, 2
	NOTE B_, 1
	NOTE B_, 2
	SND_RET
Snd8E_Ch2_5576:
	RELEASE $0D, 7
	NOTE A_, $0A
	RELEASE $0F, 4
	SND_RET
Snd8E_Ch1_557C:
	NOTE C_, 1
	NOTE C_, 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE A_, 4
	NOTE G_, 3
	NOTE F#, 3
	SND_RET
Snd8E_Ch1_5584:
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 2
	SND_RET
Snd8E_Ch2_5592:
	RELEASE $0F, 3
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F#, 1
	NOTE F#, 1
	PAN $0F
	NOTE F#, 1
	PAN $FF
	NOTE G_, 1
	NOTE G_, 1
	PAN $F0
	NOTE G_, 1
	PAN $FF
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	SND_RET
Snd8E_Ch2_55AD:
	TRANSPOSE_UP 0
	RELEASE $0F, 3
	OCTAVE 4
	REST 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 1
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	DUTY_STEP_OFF
	PAN $FF
	OCTAVE 5
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	SND_RET

Snd8E_Ch1:
	VOICE $06, 5, 8, 15, 0
	ATTEN 3
	DETUNE $01
	REST 3
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	DETUNE $00
	RELEASE $0F, 4
	ATTEN 0
	NOTE A_, 2
	PAN $F0
	NOTE A_, 1
	PAN $FF
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	ATTEN 3
	DETUNE $01
	RELEASE 0, $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
Snd8E_Ch1_55FD:
	OCTAVE 3
	NOTE D_, 1
	SND_CALL Snd8E_Ch1_553C
	SND_CALL Snd8E_Ch1_555F
	SND_CALL Snd8E_Ch1_553C
	SND_CALL Snd8E_Ch1_5562
	SND_CALL Snd8E_Ch1_5624
	SND_CALL Snd8E_Ch1_557C
	SND_CALL Snd8E_Ch1_5584
	ATTEN 0
	SND_CALL Snd8E_Ch1_5626
	TRANSPOSE_UP $0C
	SND_CALL Snd8E_Ch1_5584
	ATTEN 0
	SND_CALL Snd8E_Ch1_562F
	SND_CALL Snd8E_Ch1_55FD
Snd8E_Ch1_5624:
	NOTE A_, $0A
	SND_RET
Snd8E_Ch1_5626:
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 3
	NOTE E_, 3
	NOTE F#, 3
	ATTEN 3
	SND_RET
Snd8E_Ch1_562F:
	TRANSPOSE_UP 0
	RELEASE $0E, 3
	OCTAVE 4
	REST 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 3
	NOTE A_, 1
	RELEASE 0, $0F
	ATTEN 3
	PAN $0F
	OCTAVE 5
	NOTE D_, 2
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	SND_RET

Snd8E_Ch3:
	TRANSPOSE_UP 0
	VOICE $06, 2, 2, 7, 15
	OCTAVE 1
	NOTE D_, 4
	REST 4
	OCTAVE 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 2
	NOTE F#, 3
	OCTAVE 1
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 2
Snd8E_Ch3_565B:
	SND_CALL Snd8E_Ch3_566A
	SND_CALL Snd8E_Ch3_5689
	SND_CALL Snd8E_Ch3_566A
	SND_CALL Snd8E_Ch3_568D
	SND_CALL Snd8E_Ch3_565B
Snd8E_Ch3_566A:
	RELEASE $0F, 5
	OCTAVE 1
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	SND_REPEAT $02
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	SND_RET
Snd8E_Ch3_5689:
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	SND_RET
Snd8E_Ch3_568D:
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	REST 2
	NOTE A#, 2
	NOTE A#, 2
	REST 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT $02
	SND_RET

Snd8E_Drm:
	DRUM_UNIT $06
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $07
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
Snd8E_Drm_56DD:
	SND_SEGNO
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $18
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 2
	SND_REPEAT $04
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_SEGNO
	DRUM 3, 2
	DRUM 3, 2
	SND_REPEAT $04
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd8E_Drm_56DD

Snd8D_Ch2:
	TEMPO $20
	VOICE $06, 8, 12, 2, 15
	REST 3
Snd8D_Ch2_5709:
	DUTY_STEP 1, 8
	TRANSPOSE_UP $0C
	SND_CALL Snd8D_Ch2_5737
	ATTEN 3
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	SND_CALL Snd8D_Ch2_5737
	PAN $F0
	NOTE A_, 1
	NOTE A_, 1
	PAN $0F
	NOTE A_, 1
	NOTE A_, 1
	PAN $FF
	TRANSPOSE_UP 0
	SND_CALL Snd8D_Ch2_574E
	SND_CALL Snd8D_Ch2_574E
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	SND_CALL Snd8D_Ch2_5709
Snd8D_Ch3_5735:
	RELEASE $0F, 5
Snd8D_Ch2_5737:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 4
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 2
	SND_RET
Snd8D_Ch2_574E:
	DUTY 0
	RELEASE $0F, 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	LEN_UNIT 1
	NOTE D#, 2
	NOTE E_, 4
	LEN_UNIT 6
	RELEASE $0F, 7
	OCTAVE 3
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	RELEASE $0F, 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	LEN_UNIT 1
	NOTE D#, 2
	NOTE E_, 4
	LEN_UNIT 6
	RELEASE $0F, 7
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	RELEASE $0F, 2
	DUTY $0C
	SND_RET

Snd8D_Ch1:
	VOICE $06, 6, 0, 2, 14
	REST 3
Snd8D_Ch1_5798:
	SND_CALL Snd8D_Ch1_57BA
	NOTE F#, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd8D_Ch1_57BA
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 2
	PAN $F0
	NOTE E_, 1
	NOTE E_, 1
	PAN $0F
	NOTE E_, 1
	NOTE E_, 1
	PAN $FF
	SND_CALL Snd8D_Ch1_57CD
	SND_CALL Snd8D_Ch1_5798
Snd8D_Ch1_57BA:
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 4
	NOTE E_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd8D_Ch1_57CD:
	DUTY $0C
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 3, 5
	VIBRATO $08, 3, 4
	NOTE A_, 8
	NOTE G#, 8
	NOTE A_, 8
	RELEASE $0F, 4
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 2
	RELEASE 3, 5
	OCTAVE 3
	NOTE G#, 5
	RELEASE $0E, 7
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	VIBRATO_OFF
	RELEASE $0E, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	DUTY 0
	SND_RET

Snd8D_Ch3:
	TRANSPOSE_DOWN $0C
	VOICE $06, 2, 2, 5, 15
	REST 3
Snd8D_Ch3_5806:
	SND_CALL Snd8D_Ch3_5735
	WAVE $0B
	OCTAVE 5
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	WAVE 2
	SND_CALL Snd8D_Ch3_5735
	WAVE $0B
	OCTAVE 5
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	REST 3
	WAVE 2
	SND_CALL Snd8D_Ch3_5828
	SND_CALL Snd8D_Ch3_5806
Snd8D_Ch3_5828:
	RELEASE $0F, 3
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT $03
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_RET

Snd8D_Drm:
	DRUM_UNIT $06
	REST 3
Snd8D_Drm_5854:
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 4, 2
	DRUM 5, 2
	DRUM 4, 2
	SND_REPEAT $07
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_SEGNO
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_REPEAT $07
	DRUM 5, 1
	DRUM 4, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_CALL Snd8D_Drm_5854
