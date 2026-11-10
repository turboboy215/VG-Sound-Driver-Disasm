; ==========================================================================
; The Spirit of F-1 (E) - Konami sound driver (second-generation layout, Nemesis II track language)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: AddHLA (rst $28), SndUpdateFar ($0095-$00B7), PlaySoundFar and the bank helpers
;   bank 7: the driver ($4000-$4B03), tables, headers and streams ($4B04-$7BD1);
;           $7BD2-$7FFF is game data (not sound), included as bytes
; Build: rgbasm -Wall -o f1.o F1_SoundDriver.asm && rgblink -o f1.gb f1.o
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
DEF wTrkSfx1 EQU $D780 ; 53 bytes
DEF wTrkSfx2 EQU $D880 ; 53 bytes
DEF wTrkSfxN EQU $D980 ; 53 bytes
DEF wTrkCh1 EQU $DA80 ; 53 bytes
DEF wTrkCh2 EQU $DB80 ; 53 bytes
DEF wTrkCh3 EQU $DC80 ; 53 bytes
DEF wTrkDrm EQU $DD80 ; 53 bytes
DEF wTrackIdx EQU $D7B8
DEF wRegBase EQU $D7B9
DEF wTempo EQU $D7BA
DEF wTempoAcc EQU $D7BB
DEF wTempoSkip EQU $D7BC
DEF wQueuedSnd EQU $D7BD
DEF wNR51 EQU $D7BE
DEF wSweepVal EQU $D7BF
DEF wReqId EQU $D7C0
DEF wReqPrio EQU $D7C1
DEF wRegVal EQU $D7C2
DEF wRegIdx EQU $D7C3
DEF wMusicHold EQU $D7C4
DEF wFadeLevel EQU $D7C9
DEF wReqRefused EQU $D7CA
DEF wEnginePhase EQU $D7CB
DEF wEngineTimer EQU $D7CC
DEF wEngineIdx EQU $D7CE
DEF wEnginePtr EQU $D7CF
DEF wEnginePeriod EQU $D7D1
DEF wCh3Mute EQU $D7D3
DEF wEngineOn EQU $D7D4
DEF wShadow EQU $D8B5 ; 20 bytes
DEF wSndLock EQU $C0C1
DEF wPauseFlags EQU $C0C5
DEF wRomBank EQU $C0D5
DEF wEngineVar EQU $C159
DEF rROMB EQU $2000 ; MBC1 bank select

; per-track fields: track n lives at $D780 + n*$100, so H = $D7 + n and L = field
DEF TRK_ID EQU $80
DEF TRK_PRIO EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_FLAGS2 EQU $86
DEF TRK_LOOPCNT EQU $87
DEF TRK_LOOP2CNT EQU $88
DEF TRK_VIB EQU $89
DEF TRK_TRANSP EQU $8A
DEF TRK_ATTEN EQU $8B
DEF TRK_VIBOFS EQU $8C
DEF TRK_VIBLOOPCNT EQU $8E
DEF TRK_FLOW EQU $8F
DEF TRK_UNIT EQU $90
DEF TRK_OCTAVE EQU $91
DEF TRK_PERIOD EQU $92
DEF TRK_RAWLO EQU $94
DEF TRK_RAWHI EQU $95
DEF TRK_VOL EQU $96
DEF TRK_DUTY EQU $97
DEF TRK_ENV EQU $98
DEF TRK_GATE EQU $99
DEF TRK_RELTICK EQU $9A
DEF TRK_VIBTIMER EQU $9B
DEF TRK_VIBRELOAD EQU $9C
DEF TRK_CH3TIMER EQU $9D
DEF TRK_CH3RELOAD EQU $9E
DEF TRK_LEVEL EQU $A0
DEF TRK_LOOPPTR EQU $A1
DEF TRK_LOOP2PTR EQU $A3
DEF TRK_RET EQU $A5
DEF TRK_SEGNO EQU $A7
DEF TRK_VIBPTR EQU $A9
DEF TRK_VIBIDX EQU $AB
DEF TRK_VIBLOOPIDX EQU $AC
DEF TRK_VIBDEPTH EQU $AD
DEF TRK_VIBDELAYUNITS EQU $AE
DEF TRK_VIBDELAY EQU $AF
DEF TRK_VIBDELAYRELOAD EQU $B0
DEF TRK_PAN EQU $B4

; TRK_FLAGS: 0 released, 1 autopan, 2 vibrato on, 3 vibrato negate, 6 force register writes, 7 rest
;   (bit 4 is tested with bit 7 by TrackTick but never set)
; TRK_FLAGS2: 4+5 raw stream
; TRK_FLOW: 0/1 loop open, 2 in a call, 3 mark set

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
DEF C_HI EQU 13

; sound header: priority, track mask, then one dw per set mask bit (low bit first)
MACRO SND_HEADER
	db \1, \2
ENDM
; $00-$DF: note. hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = index into DrumMap (plays that sound id), lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: whole byte -> NR43 (NR44 = $80 at the next write), length = unit
MACRO NOISE
	db \1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #)
MACRO VOICE
	db $E0, \1, (\3 << 4) | \2, (\5 << 4) | \4
ENDM
; $E0 unit, vol<<4|env (noise SFX track: written to NR42 + trigger at once)
MACRO NVOICE
	db $E0, \1, (\2 << 4) | \3
ENDM
MACRO DRUM_UNIT
	db $E0, \1
ENDM
; $E1-$E6: octave 1-6 (pitch index += (n - 1) * 12)
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: release env (NRx2 low nibble) and gate (release tick = length * gate / 16; $F = one tick before the end)
MACRO RELEASE
	db $E8, (\2 << 4) | \1
ENDM
; $E9: NR10
MACRO SWEEP
	db $E9, \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $00 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $10 | \1
ENDM
; $EA 2n: no-op
MACRO EXT_NOP
	db $EA, $20 | \1
ENDM
MACRO DUTY
	db $EA, $30 | \1
ENDM
MACRO WAVE
	db $EA, $30 | \1
ENDM
; $EA 4n: autopan on (n != 0) / off (only the flag bit). Unused by the data
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; $EB n, yz: vibrato table n & 15, delay (y + 1) * unit ticks (y = 0: none), depth z (0 = x1)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
; $EB n with n & 15 = 0: vibrato off (two bytes)
MACRO VIBRATO_OFF
	db $EB, \1
ENDM
; $EC, $ED: no-ops with one argument byte (unused by the data)
MACRO CMD_EC
	db $EC, \1
ENDM
MACRO CMD_ED
	db $ED, \1
ENDM
; $EE: tempo (wTempoAcc += it every update, a carry skips the music tracks for that update)
MACRO TEMPO
	db $EE, \1
ENDM
; $EF: TRK_PAN = raw NR51 bits (this track's bits are used); on the drum track one byte too many is skipped
MACRO PAN
	db $EF, \1
ENDM
; $F0-$FA: attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
; flow: $FB/$FC are loop markers. The first one met marks the start, the next one (with a count) loops.
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
; $FD addr = call; the next $FD (no argument) returns
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
; raw streams (first byte $E1): header unit, duty (low nibble; CH3: wave), NR10 value; then frames.
; A pass that starts on $E1 reads a header again.
MACRO RAW_HEADER
	db $E1, \1, \2, \3
ENDM
; frame: NRx2 = vol << 4 (no envelope), NRx3/NRx4 = period, trigger; one unit
MACRO RAW_NOTE
	db (\1 << 4) | HIGH(\2), LOW(\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; vibrato table: one byte per step: ticks to the next step, negate flag, offset 0-7 (x depth)
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
ENDM
MACRO VIB_SEGNO
	db $FB
ENDM
MACRO VIB_REPEAT
	db $FE, \1
ENDM
MACRO VIB_HOLD
	db $FF
ENDM

SECTION "AddHLA", ROM0[$0028]

; AddHLA (rst $28): HL += A
AddHLA:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "SndUpdateFar", ROM0[$0095]

; SndUpdateFar: called from the VBlank handler (after ei). Skipped while wSndLock bit 0 (an
; update), bit 1 (a PlaySoundFar) or bit 2 is set; maps bank 7 and gives the game its bank back
; from wRomBank. (The ld a, c before the call is left over.)
SndUpdateFar:
	ld hl, wSndLock
	bit 2, [hl]
	ret nz
	bit 1, [hl]
	ret nz
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, $07
	ld [rROMB], a
	ld a, c
	call SndUpdate
	ld a, [wRomBank]
	ld [rROMB], a
	ld hl, wSndLock
	res 0, [hl]
	ret

SECTION "PlaySoundFar", ROM0[$02A6]

; PlaySoundFar: A = sound id. Sets wSndLock bit 1, maps bank 7, PlaySound, then maps bank 1.
PlaySoundFar:
	push hl
	ld hl, wSndLock
	set 1, [hl]
	push de
	push bc
	push af
	call MapBank7
	call PlaySound
	call MapBank1
	pop af
	pop bc
	pop de
	ld hl, wSndLock
	res 1, [hl]
	pop hl
	ret

MapBank1:
	push af
	ld a, $01
	jr SetBank

SECTION "MapBank7", ROM0[$02E0]

MapBank7:
	push af
	ld a, $07

SetBank:
	di
	ld [rROMB], a
	ld [wRomBank], a
	ei
	pop af
	ret

SECTION "Sound driver", ROMX[$4000], BANK[7]

CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyBytes
	ret

LoadPtrIndexed:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

JumpTableInline:
	pop hl
	call LoadPtrIndexed
	jp hl

; PlaySound: A = id; ids >= $31 are ignored, 0 = StopAll. $10 is not restarted while Sfx1 plays
; it. Header from SoundTable; the tracks start in Belmont's Revenge's groups: Sfx1; Sfx2 and
; SfxN; Ch1, Ch2, Ch3, Drm. A refusal in the first or second group (wReqRefused) aborts the
; rest of the request, including the NR51 write. The flag is only cleared by the abort and by
; an accepted track.
PlaySound:
	ld [wReqId], a
	cp $31
	ret nc

PlaySoundMain:
	ld [wReqId], a
	or a
	jp z, StopAll
	ld [wReqId], a
	cp $10
	jp nz, PlaySoundHeader
	ld a, [wTrkSfx1]
	ld b, a
	ld a, [wReqId]
	cp b
	ret z

PlaySoundHeader:
	ld hl, SoundTable - 2
	call LoadPtrIndexed
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
	jr nz, PlaySoundAbort
	ld a, b
	rra
	call c, StartSfx2
	rra
	call c, StartSfxN
	ld b, a
	ld a, [wReqRefused]
	or a
	jr nz, PlaySoundAbort
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

PlaySoundAbort:
	xor a
	ld [wReqRefused], a
	ret

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l4084
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
.l4084:
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld hl, wTrkCh1
	jp StartTrack

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
	jr c, .l40C1
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l40C1:
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

; StartSfx1: on a passed priority NR10 = 8 and the Ch1 NR51 bits; $1A starts the engine
; (EngineStart), $1B stops it (EngineStop), $0E mutes CH3 while it plays (wCh3Mute).
StartSfx1:
	push af
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4118
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld a, [wReqId]
	cp $1A
	jr nz, .l4104
	call z, EngineStart
.l4104:
	ld a, [wReqId]
	cp $1B
	call z, EngineStop
	ld a, [wReqId]
	cp $0E
	jr nz, .l4118
	ld a, $01
	ld [wCh3Mute], a
.l4118:
	dec l

; StartTrack: priority >= the track's: TRK_PRIO, TRK_ID, TRK_PTR, LEN 1, TRK_FLAGS = $40,
; $86-$8F = 0; a stream starting with $E1 is raw (TRK_FLAGS2 bits 4/5). Refused: skip the
; pointer. wReqRefused = 0/1. TRK_PAN = $FF either way.
StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l415C
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
	ld [hl], a
	push de
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld l, TRK_PTR + 1
	ld d, [hl]
	ld a, [de]
	cp $E1
	jr nz, .l4153
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l4160
.l4153:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l4160
.l415C:
	inc de
	inc de
	ld a, $01
.l4160:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

; StopAll: NRx2 = 0 on CH1, CH2, CH4 and NR32 = 0, clears $80-$B4 of every track, the shadows
; and the globals $D7B8-$D7D7, wNR51 = $FF (not written), and SndPause again.
StopAll:
	call SndPause
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	call ClearTrack
	call ClearTrack
	call ClearTrack
	call ClearTrack
	call ClearTrack
	call ClearTrack
	call ClearTrack
	ld hl, wShadow
	ld de, wShadow + $01
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

SndPause:
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; SndUnpause: unless wPauseFlags or wMusicHold is set, copy the shadows back to the channels
; with a playing track (no retrigger).
SndUnpause:
	ld a, [wPauseFlags]
	ld b, a
	ld a, [wMusicHold]
	or b
	ret nz
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l41D5
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
	xor a
	ldh [rNR10], a
.l41D5:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l41EA
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l41EA:
	ld a, [wTrkCh3]
	or a
	jr z, .l41FB
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l41FB:
	ld a, [wTrkSfxN]
	or a
	ret z
	ld hl, wShadow + $10
	ld de, rNR41
	ld b, $04

CopyRegs:
	ld a, [hl+]
	ld [de], a
	inc de
	dec b
	jr nz, CopyRegs
	ret

; EngineStart ($1A): wEnginePhase = wEngineOn = 1, wEngineTimer = $10, the rest cleared.
EngineStart:
	push hl
	ld a, $01
	ld [wEnginePhase], a
	ld [wEngineOn], a
	xor a
	ld [wEngineIdx], a
	ld [wEnginePeriod], a
	ld [wEnginePeriod + $01], a
	ld a, $10
	ld [wEngineTimer], a
	ld c, l
	ld b, h
	ld hl, wEnginePtr
	ld [hl], c
	ld hl, wEnginePtr + $01
	ld [hl], b
	pop hl
	ret

; EngineStop ($1B): wEngineOn = 0 (the engine does not come back after the next Sfx1 SFX).
EngineStop:
	xor a
	ld [wEngineOn], a
	ret

ClearTrack:
	ld bc, $0035
	push hl
	push de
	ld [hl], $00
	call CopyBytes
	pop de
	pop hl
	inc h
	inc d
	ret

; TempoTick: wTempoAcc += wTempo; wTempoSkip = the carry.
TempoTick:
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld a, $01
	jr c, .l4257
	xor a
.l4257:
	ld [wTempoSkip], a
	ret

; SndUpdate (once per VBlank): TempoTick, then tracks 0-6. While wPauseFlags bit 0 is set only
; track 0 runs, and only for id $19 (the pause jingle). Otherwise the loop stops before track 3
; when wTempoSkip or wMusicHold is set (the Ch2 test after it is unreachable). Last,
; wQueuedSnd is started (nothing writes it).
SndUpdate:
	call TempoTick
	xor a

SndUpdateLoop:
	ld [wTrackIdx], a
	ld a, [wPauseFlags]
	rra
	jr nc, .l427A
	ld a, [wTrackIdx]
	cp $00
	jr nz, SndUpdateNext
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	cp $19
	jr z, SndUpdateRun
	jr SndUpdateDone
.l427A:
	ld a, [wTrackIdx]
	cp $03
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone
	jr SndUpdateRun
	ld a, [wTrackIdx] ; unreachable (the loop already stopped at track 3)
	cp $04
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone

SndUpdateRun:
	ld a, [wTrackIdx]
	add a, $D7
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, TrackTick

SndUpdateNext:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, SndUpdateLoop

SndUpdateDone:
	ld a, [wQueuedSnd]
	or a
	ret z
	ld b, a
	xor a
	ld [wQueuedSnd], a
	ld a, b
	jp PlaySound

; TrackTick: TRK_LEN - 1. At 0: clear the released and rest flags; Sfx1 playing $1A goes to
; EngineTick; Ch3 mutes CH3 (NR30 = 0) before the next note; then ReadCmds. Otherwise
; TrackSustain: nothing for rests (and flag bit 4), SfxN and Drm; release flag (TRK_RELTICK >=
; TRK_LEN); vibrato (TRK_FLAGS bit 2: the delay counts down first); CH3 decays (level 0 while
; wCh3Mute); else at the release tick NRx2 = env | level and a trigger.
TrackTick:
	call GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, TrackSustain
	ld l, TRK_FLAGS
	res 0, [hl]
	res 7, [hl]
	ld a, [wTrackIdx]
	cp $00
	jr nz, .l42E6
	ld a, [wTrkSfx1]
	cp $1A
	jp z, EngineTick
.l42E6:
	ld a, [wTrackIdx]
	cp $05
	jp nz, ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp ReadCmds

TrackSustain:
	ld l, TRK_FLAGS
	ld a, [hl]
	and $90
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l4312
	ld l, TRK_FLAGS
	set 0, [hl]
.l4312:
	ld l, TRK_FLAGS
	bit 2, [hl]
	jr z, .l4324
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jr z, .l4321
	dec [hl]
	jr .l4324
.l4321:
	call VibratoTick
.l4324:
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
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l4372
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
	jr z, .l4372
	inc a
	and $03
	ld [hl], a
	jr z, .l4372
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l436F
	xor a
.l436F:
	rla
	swap a
.l4372:
	ld b, a
	ld a, [wCh3Mute]
	or a
	ld a, b
	jr z, .l437B
	xor a
.l437B:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

ReadCmdsNext:
	inc de

; ReadCmds: $FB-$FF flow commands (table at the call), then ReadCmdsNoFlow.
ReadCmds:
	ld a, [de]
	cp $FB
	jp c, ReadCmdsNoFlow
	inc de
	sub $FB
	push hl
	call JumpTableInline
	dw Cmd_LoopFB
	dw Cmd_LoopFC
	dw Cmd_Call
	dw Cmd_Mark
	dw Cmd_End

; $FB: the first one marks the loop start (TRK_FLOW bit 0), the next one, $FB n, loops until the
; count reaches n.
Cmd_LoopFB:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $01
	jp nz, .l43B0
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds
.l43B0:
	ld a, [de]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l43BE
	ld l, TRK_LOOPPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l43BE:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jr ReadCmdsNext

; $FC: a second loop level, as $FB (TRK_FLOW bit 1).
Cmd_LoopFC:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $02
	jp nz, .l43DA
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds
.l43DA:
	push hl
	ld a, [de]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l43EA
	pop hl
	ld l, TRK_LOOP2PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l43EA:
	pop hl
	ld l, TRK_LOOP2CNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jr ReadCmdsNext

; $FD addr: call (TRK_FLOW bit 2, one return slot); a bare $FD while in a call returns.
Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $04
	jp nz, .l4410
	set 2, [hl]
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
	jp ReadCmds
.l4410:
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLOW
	res 2, [hl]
	jp ReadCmds

; $FE: the first one marks (TRK_FLOW bit 3), the next one jumps back to the mark.
Cmd_Mark:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $08
	jp nz, .l442F
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l442F:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; $FF: end. TRK_ID and TRK_PRIO cleared, NRx2 = 0. Ch3: NR30 = 0. Sfx1 / Sfx2 / SfxN give
; the channel back to a playing music track (duty, NR51 bits, period). Sfx1 also writes NR10
; = 0, clears wCh3Mute and, while wEngineOn is set, goes back to the engine (EngineTick).
Cmd_End:
	pop hl
	dec de
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l4454
	xor a
	ldh [rNR30], a
	ret
.l4454:
	cp $02
	jr z, .l4488
	cp $01
	jr z, .l4478
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld a, [wCh3Mute]
	or a
	jp z, .l446D
	xor a
	ld [wCh3Mute], a
.l446D:
	ld a, [wEngineOn]
	or a
	jp nz, EngineTick
	ld h, HIGH(wTrkCh1)
	jr .l447A
.l4478:
	ld h, HIGH(wTrkCh2)
.l447A:
	ld l, TRK_ID
	ld a, [hl]
	cp $00
	ret z
	push hl
	call WriteDuty
	pop hl
	jp .l448F
.l4488:
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
.l448F:
	push hl
	call GetPanBits
	pop hl
	ld b, a
	call IsBlocked
	ld a, b
	jp c, .l44A2
	or c
	ld [wNR51], a
	ldh [rNR51], a
.l44A2:
	ld l, TRK_PERIOD
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld b, [hl]
	jp WritePeriodBC

; ReadCmdsNoFlow: raw streams (TRK_FLAGS2 bit 5) go to RawRead.
ReadCmdsNoFlow:
	ld l, TRK_FLAGS2
	bit 5, [hl]
	jp nz, RawRead

; ReadCmdsLow: $E0 voice, $00-$DF note, $F0-$FA attenuation, $E1-$E6 octave, $E7-$EF through
; the table at the call. Every handler checks TRK_FLAGS2 bit 4 first (raw -> RawRead).
ReadCmdsLow:
	ld a, [de]
	cp $E0
	jp z, Cmd_VoiceChk
	and $F0
	cp $E0
	jp c, NoteChk
	cp $F0
	jp z, Cmd_AttenChk
	ld a, [de]
	cp $E7
	jp c, Cmd_OctaveChk
	inc de
	sub $E7
	push hl
	call JumpTableInline
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_EC
	dw Cmd_ED
	dw Cmd_Tempo
	dw Cmd_Pan

Cmd_LenUnit:
	pop hl
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	jp ReadCmdsNext

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
	jp ReadCmdsNext

Cmd_Sweep:
	pop hl
	ld a, [de]
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call WriteReg
	jp ReadCmdsNext

Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	call JumpTableInline
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_Nop
	dw Ext_Duty
	dw Ext_Autopan

Ext_TransposeUp:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp ReadCmdsNext

Ext_TransposeDown:
	pop hl
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp ReadCmdsNext

Ext_Nop:
	pop hl
	jp ReadCmdsNext

Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp ReadCmdsNext

Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld a, [hl]
	jr z, .l4559
	or $02
	jr .l455B
.l4559:
	and $FD
.l455B:
	ld [hl], a
	jp ReadCmdsNext

; $EB n yz: TRK_VIB = n & 15 (0: off, two bytes, TRK_FLAGS bit 2 cleared). Else bit 2 set,
; TRK_VIBDELAYUNITS = y, delay (y + 1) * unit ticks (0 for y = 0), depth z, table n.
Cmd_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	jr nz, .l4573
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 2, [hl]
	jp ReadCmdsNext
.l4573:
	ld l, TRK_FLAGS
	set 2, [hl]
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAYUNITS
	ld [hl], a
	jr z, .l458B
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l4587:
	add a, c
	dec b
	jr nz, .l4587
.l458B:
	ld l, TRK_VIBDELAY
	ld [hl], a
	ld l, TRK_VIBDELAYRELOAD
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_VIBDEPTH
	ld [hl], a
	ld l, TRK_VIB
	ld a, [hl]
	push hl
	dec a
	ld hl, VibratoTable
	call LoadPtrIndexed
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
	ld l, TRK_VIBLOOPCNT
	ld [hl], a
	jp ReadCmdsNext

Cmd_EC:
	pop hl
	jp ReadCmdsNext

Cmd_ED:
	pop hl
	jp ReadCmdsNext

Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	jp ReadCmdsNext

; $EF x: TRK_PAN = x; this track's NR51 bits are applied (not while the channel is blocked).
; On the drum track the argument is skipped, plus one byte more.
Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $06
	jr nz, .l45CF
	inc de
	jp ReadCmdsNext
.l45CF:
	ld a, [de]
	ld l, TRK_PAN
	ld [hl], a
	call GetPanBits
	ld b, a
	call IsBlocked
	ld a, b
	jp c, ReadCmdsNext
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp ReadCmdsNext

GetPanBits:
	ld a, [wTrackIdx]
	push hl
	call JumpTableInline
	dw PanBits11
	dw PanBits22
	dw PanBits88
	dw PanBits11
	dw PanBits22
	dw PanBits44
	dw PanBits88

PanBits22:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $22
	ld c, a
	ld a, [wNR51]
	and $DD
	ret

PanBits44:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $44
	ld c, a
	ld a, [wNR51]
	and $BB
	ret

PanBits88:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $88
	ld c, a
	ld a, [wNR51]
	and $77
	ret

PanBits11:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $11
	ld c, a
	ld a, [wNR51]
	and $EE
	ret

; AutoPan: swap TRK_PAN's nibbles and apply it (not on SfxN).
AutoPan:
	ld a, [wTrackIdx]
	cp $02
	ret z
	ld l, TRK_PAN
	ld a, [hl]
	swap a
	ld [hl], a
	call GetPanBits
	ld b, a
	call IsBlocked
	ld a, b
	ret c
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ret

Cmd_OctaveChk:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawRead

Cmd_Octave:
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp ReadCmdsNext

Cmd_VoiceChk:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawRead

; $E0: unit; Drm: done. SfxN: env, vol, NR42 = byte + trigger. Else duty (CH3: wave) and vol,
; gate and env.
Cmd_Voice:
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, ReadCmdsNext
	inc de
	cp $02
	jr z, .l4699
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
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp ReadCmdsNext
.l4699:
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
	ld [wRegIdx], a
	call WriteReg
	call Trigger
	jp ReadCmdsNext

Cmd_AttenChk:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawRead

; $F0-$FA: TRK_ATTEN; on SfxN NR42 = (vol - atten) << 4 | env + trigger at once.
Cmd_Atten:
	ld a, [de]
	and $0F
	ld l, TRK_ATTEN
	ld [hl], a
	ld b, a
	ld a, [wTrackIdx]
	cp $02
	jp nz, ReadCmdsNext
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
	ld [wRegIdx], a
	call WriteReg
	call Trigger
	jp ReadCmdsNext

NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	ld c, a
	ld b, $00
	jp WritePeriodBC

NoteChk:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawRead

; Note: autopan, save the pointer. Length = lo * unit (lo 0: (unit & 15) * 16); SfxN: NR43 =
; byte, length = unit. Rest: flags, NRx2 = 0. Drm: DrumNote. Release tick = length * gate / 16
; (gate 15: length - 1). Period from PeriodTable with octave and transpose; the vibrato
; restarts (delay reloaded); NRx2 = volume and a trigger.
Note:
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, AutoPan
	call SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jr z, NoiseNote
	ld a, [de]
	and $0F
	jr nz, .l4722
	ld l, TRK_UNIT
	ld a, [hl]
	and $0F
	swap a
	jr .l472C
.l4722:
	or a
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4728:
	add a, c
	dec b
	jr nz, .l4728
.l472C:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	ld l, TRK_FLAGS
	res 7, [hl]
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l474E
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4760
.l474E:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l4756:
	srl c
	jr nc, .l475B
	add a, d
.l475B:
	rra
	dec b
	jr nz, .l4756
	pop de
.l4760:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l4778
	ld b, a
	ld c, $0C
	xor a
.l4773:
	add a, c
	dec b
	jr nz, .l4773
	ld c, a
.l4778:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld l, TRK_TRANSP
	add a, [hl]
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
	ld l, TRK_FLAGS
	bit 2, [hl]
	jr z, .l47AA
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAY
	ld [hl], a
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoRead
.l47AA:
	call VibratoApply
	jp NoteVolumeWrite

; VibratoTick: every TRK_VIBTIMER + 1 ticks the next step is read and the period written.
VibratoTick:
	ld l, TRK_VIBTIMER
	ld a, [hl]
	or a
	jr z, .l47B8
	dec [hl]
	ret
.l47B8:
	call VibratoRead
	jp VibratoApply

; VibratoRead: steps (ticks << 4 | negate << 3 | offset), $FB loop point, $FE n repeat, $FF hold;
; the offset is multiplied by the depth.
VibratoRead:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l47CB
	inc b
.l47CB:
	ld a, [bc]
	cp $FB
	jr z, .l4814
	cp $FE
	jr z, .l481E
	cp $FF
	jr z, .l483C
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l47EE
	ld l, TRK_FLAGS
	set 3, [hl]
	jr .l47F2
.l47EE:
	ld l, TRK_FLAGS
	res 3, [hl]
.l47F2:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l4810
	push bc
	xor a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4807:
	add a, c
	dec b
	jp nz, .l4807
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l4810:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4814:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l47CB
.l481E:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l4833
	cp $FF
	jr z, .l482A
	inc [hl]
.l482A:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp VibratoRead
.l4833:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l47CB
.l483C:
	ret

NoteVolumeWrite:
	call NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; NoteVolume: TRK_LEVEL = (vol - atten - wFadeLevel) << 4 (0 at a borrow). CH3: NR30 = $80, the
; decay timer from TRK_ENV, level code = (vol >> 1 & 3) + atten + wFadeLevel / 2 (0 from 4);
; 0 while wCh3Mute is set. wFadeLevel is never written.
NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4870
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l486A
	xor a
.l486A:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4870:
	ld a, $80
	ld [wShadow + $0A], a
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
	jr c, .l4898
	xor a
.l4898:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ld b, a
	ld a, [wCh3Mute]
	or a
	ld a, b
	ret z
	xor a
	ret

; VibratoApply: period +/- offset to NRx3/NRx4.
VibratoApply:
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
	jr z, .l48BF
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l48BF:
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

WritePeriodBC:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegIdx], a
	call WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
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
	ld [wRegIdx], a
	jp WriteReg

; DrumNote: PlaySound(DrumMap[hi - 1]).
DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = duty << 4; CH3 copies wave TRK_DUTY (WaveTable, from 1) to the wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4922
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l4922:
	dec a
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l4930:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l4930
	pop hl
	pop de
	ret

; IsBlocked: carry for Ch1 while Sfx1 plays and for Ch2 while Sfx2 plays.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4947
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4950
.l4947:
	cp $04
	jr nz, .l4952
	ld a, [wTrkSfx2]
	or a
	ret z
.l4950:
	scf
	ret
.l4952:
	or a
	ret

; WriteReg: register wRegBase + wRegIdx = wRegVal through the shadow (skipped when equal unless
; TRK_FLAGS bit 6 is set), not while blocked.
WriteReg:
	call IsBlocked
	ret c
	push de
	call GetRegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	ld a, [wTrackIdx]
	add a, $D7
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4972
	ld a, [hl]
	cp c
	jr z, .l4975
.l4972:
	ld a, c
	ld [hl], a
	ld [de], a
.l4975:
	pop de
	ld a, [wTrackIdx]
	add a, $D7
	ld h, a
	ret

Trigger:
	call IsBlocked
	ret c
	push de
	ld a, $04
	ld [wRegIdx], a
	call GetRegAddr
	ld a, [hl]
	or $80
	ld [de], a
	pop de
	ld a, [wTrackIdx]
	add a, $D7
	ld h, a
	ret

GetRegAddr:
	ld a, [wRegIdx]
	ld c, a
	ld a, [wRegBase]
	add a, c
	ld c, a
	ld b, $00
	ld hl, rNR10
	ld de, wShadow
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

; RawRead: a raw stream. $E1 at the start of a pass: unit, duty, NR10 (4 bytes). $00: rest (one
; unit). $FB-$FF: flow. $E7, $E9, $EA, $EE, $EF: as usual; $E8, $EB-$ED go to RawFrame with the
; table's return address still on the stack (not in the data). Anything else: a frame.
RawRead:
	ld l, TRK_RELTICK
	xor a
	ld [hl], a
	ld a, [de]
	cp $E1
	jr nz, .l49E6
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
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call WriteReg
	inc de
.l49E6:
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
	call JumpTableInline
	dw Cmd_LenUnit
	dw RawFrame
	dw Cmd_Sweep
	dw Cmd_Ext
	dw RawFrame
	dw RawFrame
	dw RawFrame
	dw Cmd_Tempo
	dw Cmd_Pan

; RawFrame: hi nibble -> NRx2 (no envelope), lo nibble + next byte -> period, trigger; one unit.
RawFrame:
	ld l, TRK_PAN
	ld a, [hl]
	call GetPanBits
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
	ld l, TRK_RAWHI
	ld [hl], a
	ld b, a
	inc de
	ld a, [de]
	ld l, TRK_RAWLO
	ld [hl], a
	ld c, a
	call WritePeriodBC
	call SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

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
	ld [wRegIdx], a
	jp WriteReg

; EngineTick (Sfx1 playing $1A, every update; not while paused): TRK_ID = $1A, LEN = 1. Every 16
; updates (wEngineTimer) duty 0, NR51 |= $11 and NRx2 = $C0. The period is
; EngineTable[wEngineVar] minus $60 on every other update (wEnginePhase), written with a
; trigger. A wEngineVar of $70 or more returns with HL still pushed (a crash; the game keeps
; it lower). The Sfx1 stream of $1A is never read: the header points at EngineTable.
EngineTick:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, $1A
	ld [hl], a
	ld l, TRK_LEN
	ld a, $01
	ld [hl], a
	ld a, [wPauseFlags]
	rra
	ret c
	ld a, [wEngineTimer]
	dec a
	cp $0F
	ld [wEngineTimer], a
	jr nz, .l4AAC
	xor a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ldh [rNR51], a
	ld a, $C0
	ld l, TRK_LEVEL
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp .l4AB4
.l4AAC:
	or a
	jr nz, .l4AB4
	ld a, $10
	ld [wEngineTimer], a
.l4AB4:
	push hl
	ld hl, EngineTable
	ld a, [wEngineVar]
	ld [wEngineIdx], a
	or a
	cp $70
	ret nc
	rlca
	add a, l
	ld l, a
	ld a, h
	adc a, $00
	ld h, a
	ld c, l
	ld b, h
	ld hl, wEnginePtr
	ld [hl], c
	ld hl, wEnginePtr + $01
	ld [hl], b
	push de
	ld a, [wEnginePtr]
	ld e, a
	ld a, [wEnginePtr + $01]
	ld d, a
	ld a, [wEnginePhase]
	or a
	jr nz, .l4AE9
	ld a, $60
	ld b, a
	ld a, $01
	jr .l4AEB
.l4AE9:
	xor a
	ld b, a
.l4AEB:
	ld [wEnginePhase], a
	ld a, [de]
	sub b
	ld [wEnginePeriod], a
	ld c, a
	inc de
	ld a, [de]
	sbc a, $00
	ld [wEnginePeriod + $01], a
	ld b, a
	pop de
	pop hl
	call WritePeriodBC
	jp Trigger

; SoundTable: ids $01-$30. The unused id-0 entry is the operand of the jp above (the code
; reads SoundTable - 2 + 2 * id).
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

SndHdr1A:
	SND_HEADER $01, $01 ; tracks: Sfx1
	dw EngineTable

SndHdr1B:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr19:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr0E:
	SND_HEADER $31, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0E_Sfx1
	dw Snd0E_Sfx2
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $31, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0F_Sfx1
	dw Snd0F_Sfx2
	dw Snd0F_SfxN

SndHdr10:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd10_Sfx1
	dw Snd10_SfxN

SndHdr11:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr1C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd1C_Ch1
	dw Snd1C_Ch2
	dw Snd1C_Ch3
	dw Snd1C_Drm

SndHdr1D:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd1D_Ch2
	dw Snd1D_Ch3
	dw Snd1D_Drm

SndHdr1E:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd1E_Ch2
	dw Snd1E_Ch3
	dw Snd1E_Drm

SndHdr1F:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd1F_Ch2
	dw Snd1F_Ch3
	dw Snd1F_Drm

SndHdr20:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd20_Ch2
	dw Snd20_Ch3
	dw Snd20_Drm

SndHdr21:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd21_Ch2
	dw Snd21_Ch3
	dw Snd21_Drm

SndHdr22:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd22_Ch2
	dw Snd22_Ch3
	dw Snd22_Drm

SndHdr23:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd23_Ch2
	dw Snd23_Ch3
	dw Snd23_Drm

SndHdr24:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd24_Ch2
	dw Snd24_Ch3
	dw Snd24_Drm

SndHdr25:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd25_Ch2
	dw Snd25_Ch3
	dw Snd25_Drm

SndHdr26:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd26_Ch2
	dw Snd26_Ch3
	dw Snd26_Drm

SndHdr27:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd27_Ch2
	dw Snd27_Ch3
	dw Snd27_Drm

SndHdr28:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd28_Ch2
	dw Snd28_Ch3
	dw Snd28_Drm

SndHdr29:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd29_Ch2
	dw Snd29_Ch3
	dw Snd29_Drm

SndHdr2A:
	SND_HEADER $40, $70 ; tracks: Ch2, Ch3, Drm
	dw Snd2A_Ch2
	dw Snd2A_Ch3
	dw Snd2A_Drm

SndHdr2B:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2B_Ch1
	dw Snd2B_Ch2
	dw Snd2B_Ch3
	dw Snd2B_Drm

SndHdr2C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2C_Ch1
	dw Snd2C_Ch2
	dw Snd2C_Ch3
	dw Snd2C_Drm

SndHdr2D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2D_Ch1
	dw Snd2D_Ch2
	dw Snd2D_Ch3
	dw Snd2D_Drm

SndHdr2E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2E_Ch1
	dw Snd2E_Ch2
	dw Snd2E_Ch3
	dw Snd2E_Drm

SndHdr2F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2F_Ch1
	dw Snd2F_Ch2
	dw Snd2F_Ch3
	dw Snd2F_Drm

SndHdr30:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd30_Ch1
	dw Snd30_Ch2
	dw Snd30_Ch3
	dw Snd30_Drm

; DrumMap: drum note hi 1-13 -> sound id.
DrumMap:
	db $01, $02, $03, $04, $05, $06, $07, $0A, $08, $0B, $09, $0C, $0D

SndHdr01:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr08:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr03:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd03_Sfx1
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd04_Sfx1
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd05_Sfx1
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd06_Sfx1
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd07_Sfx1
	dw Snd07_SfxN

SndHdr0B:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd0C_Sfx1
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd0D_Sfx1
	dw Snd0D_SfxN

Snd01_SfxN:
	NVOICE $02, 8, 1
	NOISE $30
	NOISE $00
	SND_END

Snd02_SfxN:
	NVOICE $05, 5, 2
	NOISE $22
	NOISE $23
	SND_END

Snd03_SfxN:
	PAN $0F
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd03_Sfx1:
	RAW_HEADER 3, 8, $1F
	PAN $0F
	RAW_NOTE 8, $6FF
	RAW_HEADER 6, 8, $1F
	RAW_NOTE 4, $699
	SND_END

Snd04_SfxN:
	PAN $F0
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd04_Sfx1:
	RAW_HEADER 3, 8, $1F
	PAN $F0
	RAW_NOTE 8, $6FF
	RAW_HEADER 6, 8, $1F
	RAW_NOTE 4, $699
	SND_END

Snd05_SfxN:
	PAN $0F
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd05_Sfx1:
	RAW_HEADER 3, 8, $1E
	PAN $0F
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, 8, $1F
	RAW_NOTE 4, $633
	SND_END

Snd06_SfxN:
	PAN $F0
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd06_Sfx1:
	RAW_HEADER 3, 8, $1E
	PAN $F0
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, 8, $1F
	RAW_NOTE 4, $633
	SND_END

Snd07_SfxN:
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd07_Sfx1:
	RAW_HEADER 3, 8, $1D
	RAW_NOTE 8, $6D0
	RAW_HEADER 5, 8, $1F
	RAW_NOTE 4, $5F0
	SND_END

Snd09_SfxN:
	NVOICE $01, 15, 3
	NOISE $7D
	NOISE $74
	SND_END

Snd0A_SfxN:
	NVOICE $01, 8, 1
	NOISE $69
	NVOICE $01, 2, 8
	NOISE $69
	SND_END

Snd08_SfxN:
	NVOICE $01, 13, 0
	NOISE $58
	NOISE $56
	NVOICE $05, 4, 3
	NOISE $23
	NVOICE $01, 2, 2
	NOISE $13
	NOISE $12
	SND_END

Snd0C_SfxN:
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd0C_Sfx1:
	RAW_HEADER 3, 8, $1F
	RAW_NOTE 8, $6FF
	RAW_HEADER 5, 8, $1F
	RAW_NOTE 4, $699
	SND_END

Snd0D_SfxN:
	NVOICE $0F, 9, 1
	NOISE $30
	SND_END

Snd0D_Sfx1:
	RAW_HEADER 3, 8, $1E
	RAW_NOTE 8, $6E0
	RAW_HEADER 5, 8, $1F
	RAW_NOTE 4, $633
	SND_END

Snd0B_SfxN:
	NVOICE $01, 10, 8
	NOISE $23
	NVOICE $0F, 7, 5
	NOISE $12
	NOISE $12
	SND_END

; PeriodTable: 85 periods (from C of octave 1).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; WaveTable: 12 entries, indexed from 1 (entries 11 and 12 point at VibratoTable).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData1 ; wave 2
	dw WaveData1 ; wave 3
	dw WaveData1 ; wave 4
	dw WaveData2 ; wave 5
	dw WaveData2 ; wave 6
	dw WaveData3 ; wave 7
	dw WaveData4 ; wave 8
	dw WaveData4 ; wave 9
	dw WaveData4 ; wave 10
	dw VibratoTable ; wave 11 (the vibrato pointer table; unused)
	dw VibratoTable ; wave 12 (the vibrato pointer table; unused)
WaveData1:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData2:
	db $60, $58, $00, $FF, $F9, $00, $00, $20, $20, $08, $08, $40, $C0, $00, $C0, $00
WaveData3:
	db $FF, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
WaveData4:
	db $66, $60, $8F, $C0, $88, $80, $40, $20, $20, $08, $08, $88, $40, $00, $80, $00

; VibratoTable: 15 tables ($EB n, from 1).
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
	dw Vib0B ; 12
	dw Vib0D ; 13
	dw Vib0E ; 14
	dw Vib0F ; 15

Vib01:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 1, 1
	VIB_REPEAT 255

Vib02:
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_REPEAT 255

Vib03:
	VIB_STEP 1, 0, 1
	VIB_HOLD

Vib04:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_REPEAT 255

Vib05:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_HOLD

Vib06:
	VIB_STEP 4, 1, 7
	VIB_STEP 3, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 0
	VIB_REPEAT 255

Vib07:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_REPEAT 255

Vib08:
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_HOLD

Vib09:
	VIB_STEP 8, 1, 3
	VIB_SEGNO
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 1
	VIB_REPEAT 255

Vib0A:
	VIB_STEP 1, 1, 1
	VIB_HOLD

Vib0B:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT 255

Vib0D:
	VIB_STEP 8, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_REPEAT 255

Vib0E:
	VIB_STEP 8, 1, 2
	VIB_SEGNO
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 0
	VIB_REPEAT 255

Vib0F:
	VIB_HOLD

Snd1B_Sfx1:
	SND_END

Snd12_Sfx1:
	VOICE $04, 15, 8, 5, 12
	OCTAVE 4
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 2
	VOICE $04, 4, 8, 5, 12
	NOTE C_HI, 2
	VOICE $04, 15, 8, 5, 12
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 2
	VOICE $04, 4, 8, 5, 12
	NOTE C_HI, 2
	SND_END

Snd15_Sfx1:
	VOICE $03, 10, 8, 0, 15
	OCTAVE 5
	NOTE B_, 1
	NOTE G_, 2
	ATTEN 6
	NOTE B_, 1
	NOTE G_, 3
	SND_END

Snd16_Sfx1:
	VOICE $01, 15, 8, 0, 15
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 2
	VOICE $01, 4, 8, 2, 15
	NOTE G_, 2
	NOTE D_, 4
	SND_END

Snd13_Sfx1:
	VOICE $03, 14, 8, 0, 15
	LOOP_START
	OCTAVE 5
	NOTE G#, 2
	ATTEN $0A
	NOTE G#, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN $0A
	NOTE E_, 6
	ATTEN 0
	LOOP_END 3
	SND_END

Snd14_Sfx1:
	VOICE $01, 12, 8, 4, 15
	TRANSPOSE_UP 3
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_HI, 8
	ATTEN 6
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_HI, 8
	ATTEN 8
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_HI, 8
	SND_END

Snd11_Sfx1:
	TEMPO $08
	VOICE $09, 15, 8, 0, 15
	OCTAVE 4
	LOOP_START
	VIBRATO 12, 0, 1
	NOTE F_, 3
	ATTEN $0A
	VIBRATO 13, 0, 1
	NOTE F_, 3
	ATTEN 0
	LOOP_END 3
	VOICE $09, 11, 8, 0, 15
	VIBRATO 12, 2, 1
	OCTAVE 5
	NOTE F_, 6
	VIBRATO 13, 0, 1
	ATTEN 6
	NOTE F_, 6
	ATTEN 0
	VIBRATO_OFF $00
	SND_RET ; a return here; as the Sfx1 stream of $11 (never requested) it is a call to $09E0 in ROM0
Snd11_Sfx1_4F71:
	VOICE $09, 6, 3, 3, 8
	VIBRATO 3, 0, 3
	OCTAVE 5
	NOTE F_, 6
	NOTE F_, 6
	NOTE F_, 6
	VIBRATO 3, 0, 1
	RELEASE 7, 8
	OCTAVE 6
	NOTE F_, $0C
	VIBRATO_OFF $00
	SND_RET
Snd1D_Drm_4F86:
	DRUM_UNIT $09
	REST 0
	REST $0E
	SND_RET

Snd10_Sfx1:
	VOICE $01, 13, 4, 1, 15
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	VOICE $01, 4, 4, 0, 15
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	SND_END

Snd10_SfxN:
	NVOICE $01, 13, 6
	NOISE $22
	NOISE $23
	NOISE $22
	NVOICE $02, 12, 6
	NOISE $79
	NOISE $72
	NVOICE $08, 8, 0
	NOISE $32
	NVOICE $0A, 8, 3
	NOISE $34
	SND_END

Snd0F_Sfx1:
	TRANSPOSE_DOWN 1
	PAN $F0
	VOICE $05, 4, 12, 12, 10
	REST 6
	OCTAVE 4
	NOTE G#, 0
	VOICE $05, 9, 12, 0, 15
	PAN $FF
	VIBRATO 8, 0, 9
	OCTAVE 4
	NOTE G_, 3
	PAN $0F
	VIBRATO_OFF $00
	VOICE $07, 11, 12, 7, 15
	NOTE D_, 0
	SND_END

Snd0F_Sfx2:
	TRANSPOSE_DOWN 1
	PAN $F0
	VOICE $05, 2, 0, 11, 8
	REST 6
	OCTAVE 4
	NOTE G_, 0
	VOICE $05, 7, 0, 6, 15
	PAN $FF
	VIBRATO 8, 0, 7
	NOTE F#, 4
	PAN $0F
	VIBRATO 10, 0, 2
	VOICE $07, 11, 0, 7, 15
	NOTE D_, 0
	SND_END

Snd0F_SfxN:
	NVOICE $1E, 0, 8
	NOISE $22
	NVOICE $50, 1, 15
	PAN $F0
	NOISE $21
	NVOICE $07, 6, 5
	PAN $FF
	NOISE $33
	NOISE $33
	NVOICE $70, 10, 7
	PAN $0F
	NOISE $33
	SND_END

Snd0E_Sfx1:
	TRANSPOSE_DOWN 1
	PAN $F0
	VOICE $02, 3, 12, 10, 15
	OCTAVE 4
	NOTE G#, 9
	VOICE $05, 9, 12, 3, 15
	PAN $FF
	VIBRATO 8, 0, 7
	OCTAVE 4
	NOTE G#, 3
	PAN $0F
	VIBRATO_OFF $00
	VOICE $06, 10, 12, 7, 15
	NOTE E_, 0
	SND_END

Snd0E_Sfx2:
	TRANSPOSE_DOWN 1
	PAN $F0
	VOICE $02, 3, 0, 11, 15
	OCTAVE 4
	NOTE G_, 9
	VOICE $05, 7, 0, 6, 15
	PAN $FF
	VIBRATO 8, 0, 5
	NOTE G_, 4
	PAN $0F
	VIBRATO 10, 0, 2
	VOICE $06, 10, 0, 7, 15
	NOTE E_, 0
	SND_END

Snd0E_SfxN:
	NVOICE $12, 3, 12
	PAN $F0
	NOISE $21
	NVOICE $0C, 6, 5
	PAN $FF
	NOISE $33
	NVOICE $50, 10, 7
	PAN $0F
	NOISE $33
	SND_END

Snd17_Sfx1:
	VOICE $01, 12, 8, 0, 15
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 8
	NOTE E_, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE A_, 2
	SND_END

Snd18_Sfx1:
	VOICE $01, 14, 8, 5, 15
	OCTAVE 5
	NOTE C_, 3
	NOTE G_, 4
	NOTE E_, 4
	ATTEN $0A
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 6
	SND_END

Snd19_Sfx1:
	RAW_HEADER 5, 8, $88
	RAW_NOTE 15, $707
	RAW_NOTE 15, $73A
	RAW_NOTE 15, $75A
	RAW_NOTE 15, $73A
	RAW_NOTE 15, $75A
	RAW_NOTE 15, $784
	RAW_NOTE 13, $784
	RAW_NOTE 4, $784
	SND_END

Snd1C_Ch2:
	TEMPO $15
	VOICE $06, 9, 4, 3, 8
	TRANSPOSE_UP 5
	OCTAVE 1
	REST 8
	SND_SEGNO
	LOOP2_START
	VOICE $01, 9, 4, 3, 8
	OCTAVE 3
	NOTE B_, 3
	NOTE C_HI, 9
	REST $0C
	NOTE A#, 3
	NOTE B_, 9
	PAN $F0
	VOICE $01, 15, 8, 0, 15
	OCTAVE 4
	NOTE C_, 4
	REST 2
	NOTE C_, 4
	REST 2
	VOICE $01, 9, 4, 3, 8
	PAN $FF
	OCTAVE 3
	NOTE G#, 3
	NOTE A_, 9
	REST $0C
	NOTE G_, 6
	ATTEN 0
	PAN $F0
	VOICE $06, 15, 0, 4, 15
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $0F
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 1
	PAN $F0
	VOICE $01, 15, 4, 0, 15
	REST $0C
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	REST 6
	PAN $FF
	VOICE $01, 9, 4, 0, 15
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE A_, 6
	VOICE $01, 9, 4, 4, 8
	NOTE A#, 3
	NOTE B_, $0C
	REST 3
	NOTE A_, $0C
	REST 6
	PAN $F0
	VOICE $01, 12, 8, 0, 15
	OCTAVE 4
	NOTE C_, 4
	REST 2
	NOTE C_, 4
	REST 2
	LEN_UNIT $06
	PAN $FF
	OCTAVE 3
	REST 2
	VOICE $01, 9, 4, 0, 15
	LOOP_START
	NOTE G_, 4
	REST 2
	LOOP_END 5
	NOTE A_, 6
	VOICE $01, 9, 4, 3, 12
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, $0C
	REST 3
	NOTE C_, $0C
	REST 6
	PAN $F0
	VOICE $01, 12, 8, 0, 15
	OCTAVE 4
	NOTE C_, 4
	REST 2
	NOTE C_, 4
	REST 2
	VOICE $06, 9, 8, 3, 12
	ATTEN 1
	PAN $FF
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	LOOP2_END 2
	SND_CALL Snd1C_Ch2_5180
	VOICE $01, 14, 4, 0, 15
	PAN $F0
	OCTAVE 3
	NOTE A_, 4
	REST 2
	NOTE A_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE A_, 4
	REST 2
	PAN $FF
	VOICE $06, 6, 8, 4, 12
	REST 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE A_, 3
	REST 1
	SND_CALL Snd1C_Ch2_5180
	VOICE $01, 9, 4, 0, 15
	OCTAVE 3
	LOOP_START
	NOTE B_, 4
	REST 2
	LOOP_END 4
	REST 4
	LOOP_START
	REST 2
	NOTE B_, 4
	LOOP_END 4
	REST 4
	REST 0
	DUTY 8
	OCTAVE 3
	NOTE D_, 4
	REST 2
	NOTE E_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE B_, 4
	REST 2
	PAN $FF
	SND_LOOP
Snd1C_Ch2_5180:
	VOICE $01, 14, 4, 0, 15
	PAN $F0
	OCTAVE 3
	NOTE A_, 4
	REST 2
	NOTE A_, 4
	REST 2
	NOTE G_, 4
	REST 2
	NOTE A_, 4
	REST 2
	PAN $FF
	VOICE $06, 9, 8, 4, 12
	REST 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 2
	NOTE A_, 3
	REST 1
	SND_RET

Snd1C_Ch1:
	VOICE $06, 6, 8, 3, 12
	OCTAVE 1
	REST 8
	SND_SEGNO
	LOOP2_START
	VOICE $01, 6, 8, 3, 12
	TRANSPOSE_UP 5
	OCTAVE 3
	NOTE F#, 3
	NOTE G_, 9
	REST $0C
	NOTE F_, 3
	NOTE F#, 9
	PAN $0F
	VOICE $01, 15, 4, 0, 15
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	VOICE $01, 6, 8, 3, 12
	PAN $FF
	NOTE D#, 3
	NOTE E_, 9
	REST $0C
	NOTE D_, 6
	VOICE $06, 15, 4, 2, 15
	PAN $F0
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	PAN $0F
	NOTE B_, 1
	NOTE A_, 2
	NOTE B_, 1
	PAN $0F
	VOICE $01, 15, 4, 0, 15
	OCTAVE 4
	REST $0C
	LOOP_START
	NOTE C_, 4
	REST 2
	LOOP_END 4
	REST 6
	PAN $FF
	VOICE $01, 6, 8, 0, 15
	OCTAVE 3
	LOOP_START
	NOTE D_, 4
	REST 2
	LOOP_END 5
	NOTE E_, 6
	DUTY 4
	NOTE F_, 3
	NOTE F#, $0C
	REST 3
	NOTE E_, $0C
	REST 6
	PAN $0F
	VOICE $01, 15, 4, 0, 15
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	PAN $FF
	REST $0C
	VOICE $01, 6, 8, 0, 15
	LOOP_START
	NOTE D_, 4
	REST 2
	LOOP_END 5
	NOTE E_, 6
	VOICE $01, 9, 4, 3, 12
	NOTE F_, 3
	NOTE F#, $0C
	REST 3
	NOTE E_, $0C
	REST 6
	PAN $0F
	VOICE $01, 15, 4, 0, 15
	NOTE G_, 4
	REST 2
	NOTE G_, 4
	REST 2
	LEN_UNIT $06
	PAN $FF
	REST 8
	LOOP2_END 2
	LOOP2_START
	VOICE $01, 15, 0, 0, 15
	PAN $0F
	LOOP_START
	NOTE E_, 4
	REST 2
	LOOP_END 4
	LEN_UNIT $06
	REST $0C
	LOOP2_END 3
	PAN $FF
	LEN_UNIT $01
	LOOP_START
	NOTE E_, 4
	REST 2
	LOOP_END 4
	OCTAVE 3
	REST 6
	NOTE E_, 4
	REST 2
	NOTE E_, 4
	REST 2
	NOTE E_, 4
	REST 2
	NOTE E_, 6
	REST 0
	REST 2
	DUTY 8
	OCTAVE 2
	NOTE B_, 4
	REST 2
	OCTAVE 3
	NOTE C_, 4
	REST 2
	NOTE E_, 4
	REST 2
	NOTE G_, 4
	REST 2
	SND_LOOP

Snd1C_Ch3:
	VOICE $06, 2, 10, 3, 9
	REST 8
	TRANSPOSE_UP 5
	SND_SEGNO
	LOOP2_START
	OCTAVE 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 3, 8
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE B_, 1
	NOTE D_, 2
	NOTE E_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D_, 1
	RELEASE 3, 9
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	RELEASE 3, 8
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE C_HI, 1
	RELEASE 3, 9
	LOOP2_END 2
	VOICE $06, 2, 10, 3, 9
	OCTAVE 1
	SND_CALL Snd1C_Ch3_52F1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	REST 1
	LEN_UNIT $01
	NOTE G#, 1
	NOTE A_, 5
	LEN_UNIT $06
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_CALL Snd1C_Ch3_52F1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	REST 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_LOOP
Snd1C_Ch3_52F1:
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 4, $0A
	NOTE E_, 2
	RELEASE 3, 9
	SND_RET

Snd1C_Drm:
	DRUM_UNIT $01
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0D, 4
	DRUM $0D, 4
	DRUM $0D, 4
	DRUM_UNIT $06
	DRUM $0A, 4
	SND_SEGNO
	LOOP2_START
	DRUM_UNIT $06
	LOOP_START
	DRUM $0B, 1
	REST 1
	DRUM 2, 1
	REST 1
	DRUM 9, 1
	REST 1
	DRUM 2, 1
	REST 1
	DRUM $0B, 1
	REST 1
	DRUM 2, 1
	REST 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 1
	REST 1
	DRUM 2, 1
	REST 1
	DRUM 9, 1
	REST 1
	DRUM 2, 1
	REST 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0D, 1
	LOOP2_END 2
	DRUM_UNIT $06
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	REST 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM_UNIT $01
	DRUM $0D, 4
	DRUM $0D, 4
	DRUM $0D, 4
	DRUM_UNIT $06
	DRUM $0A, 4
	SND_LOOP

Snd21_Ch2:
	SND_CALL Snd11_Sfx1

Snd22_Ch2:
	TEMPO $14
	SND_SEGNO
	VOICE $04, 9, 4, 2, 15
	OCTAVE 4
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	PAN $F0
	VOICE $04, 11, 8, 1, 15
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	PAN $FF
	ATTEN 3
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 0
	PAN $0F
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	PAN $FF
	VOICE $04, 9, 4, 2, 15
	OCTAVE 4
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	RELEASE 0, $0F
	VIBRATO 7, 1, 2
	NOTE C_, 6
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 10, 8, 1, 15
	PAN $F0
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	PAN $0F
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $FF
	VOICE $04, 9, 4, 2, 15
	OCTAVE 4
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	PAN $F0
	VOICE $04, 10, 8, 1, 15
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	PAN $FF
	ATTEN 3
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	PAN $0F
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	PAN $FF
	VOICE $04, 9, 4, 2, 15
	OCTAVE 4
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	RELEASE 0, $0F
	VIBRATO 7, 1, 2
	NOTE D_, 6
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 10, 8, 1, 15
	PAN $F0
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $0F
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $FF
	SND_CALL Snd21_Ch2_54C3
	ATTEN 1
	DUTY 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	VIBRATO 1, 2, 1
	NOTE E_, 5
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	VIBRATO_OFF $00
	SND_CALL Snd21_Ch2_54C3
	ATTEN 1
	DUTY 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 9, 8, 0, 15
	VIBRATO 1, 4, 1
	OCTAVE 4
	NOTE C_HI, 8
	ATTEN 6
	NOTE C_HI, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE G_, 6
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO 1, 4, 1
	NOTE G_, 8
	ATTEN 6
	NOTE G_, 8
	ATTEN 0
	VIBRATO_OFF $00
	NOTE C_, 5
	ATTEN 6
	NOTE C_, 5
	ATTEN 0
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	VIBRATO 1, 4, 1
	OCTAVE 4
	NOTE C_HI, 8
	ATTEN 6
	NOTE C_HI, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE G_, 6
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO 7, 2, 1
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 4
	ATTEN 0
	NOTE D_, 6
	ATTEN 6
	NOTE D_, 4
	ATTEN 0
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 4
	ATTEN 0
	NOTE E_, 6
	ATTEN 6
	NOTE E_, 4
	VIBRATO_OFF $00
	ATTEN 0
	SND_CALL Snd21_Ch2_5547
	ATTEN 2
	DUTY 4
	OCTAVE 4
	REST 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	ATTEN 0
	SND_CALL Snd21_Ch2_5547
	REST 8
	SND_LOOP
Snd21_Ch2_54C3:
	VOICE $04, 9, 8, 0, 15
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	NOTE G_, 2
	RELEASE 4, 8
	VIBRATO 1, 1, 1
	NOTE A_, 4
	VIBRATO_OFF $00
	VOICE $04, 10, 4, 2, 15
	ATTEN 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 15, 4, 4, 10
	PAN $0F
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	ATTEN $0A
	NOTE A_, 2
	PAN $F0
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE C_, 2
	VOICE $04, 9, 8, 0, 15
	PAN $FF
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 2
	VIBRATO 1, 1, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 7
	ATTEN 6
	NOTE G_, 5
	VIBRATO_OFF $00
	ATTEN 0
	NOTE E_, 2
	NOTE G_, 2
	VIBRATO 1, 1, 1
	NOTE A_, 4
	VIBRATO_OFF $00
	ATTEN 0
	SND_RET
Snd21_Ch2_5547:
	VOICE $04, 9, 8, 0, 15
	VIBRATO 7, 1, 1
	OCTAVE 4
	NOTE F_, 6
	ATTEN 6
	NOTE F_, 4
	ATTEN 0
	VIBRATO_OFF $00
	RELEASE 3, $0A
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_HI, 6
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	VIBRATO 7, 1, 1
	RELEASE 0, $0F
	NOTE F_, 8
	ATTEN 6
	NOTE F_, 4
	ATTEN 0
	VIBRATO_OFF $00
	RELEASE 3, $0A
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_HI, 6
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	VIBRATO 7, 1, 1
	RELEASE 0, $0F
	NOTE F_, 8
	ATTEN 6
	NOTE F_, 4
	ATTEN 0
	RELEASE 3, $0A
	VIBRATO_OFF $00
	NOTE F_, 2
	NOTE C_HI, 2
	OCTAVE 5
	NOTE F_, 6
	NOTE D#, 2
	REST 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	VIBRATO 7, 1, 1
	RELEASE 4, 8
	OCTAVE 4
	NOTE A#, $0A
	ATTEN 6
	NOTE A#, 2
	ATTEN 0
	VIBRATO_OFF $00
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	VIBRATO 1, 1, 1
	NOTE C_, 8
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	VIBRATO_OFF $00
	SND_RET

Snd21_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd22_Ch3:
	OCTAVE 2
	SND_SEGNO
	VOICE $04, 2, 6, 3, 5
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 1
	RELEASE 4, 8
	VIBRATO 1, 2, 2
	NOTE D_, 5
	NOTE D_, 2
	OCTAVE 1
	NOTE C_HI, 4
	NOTE A#, 4
	NOTE C_HI, 4
	RELEASE 3, 5
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C#, 1
	RELEASE 4, 8
	NOTE D_, 5
	NOTE D_, 2
	OCTAVE 1
	NOTE C_HI, 4
	NOTE B_, 4
	NOTE A#, 4
	RELEASE 3, 5
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 1
	RELEASE 4, 8
	NOTE D_, 5
	NOTE D_, 2
	OCTAVE 1
	NOTE C_HI, 4
	NOTE A#, 4
	NOTE C_HI, 4
	RELEASE 3, 5
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 4, 8
	NOTE D_, 5
	RELEASE 5, 9
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE C_HI, 2
	VOICE $04, 2, 6, 2, 8
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 2
	RELEASE 2, 6
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C_, 2
	RELEASE 2, 8
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 2
	RELEASE 2, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	RELEASE 2, 8
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 2
	RELEASE 2, 6
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	RELEASE 2, 8
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE 2, 6
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 2, 8
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	RELEASE 2, 6
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	RELEASE 2, 8
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 2
	RELEASE 2, 6
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	RELEASE 2, 8
	LOOP_END 2
	VOICE $04, 2, 6, 4, 8
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	REST 2
	OCTAVE 2
	NOTE A#, 2
	REST 2
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE D_, 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	REST 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	REST 2
	NOTE A#, 4
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D_, 6
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_HI, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 4
	NOTE C_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 3
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 3
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 3
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 3
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 3
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE B_, 1
	NOTE C_HI, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE B_, 1
	NOTE C_HI, 3
	SND_LOOP

Snd21_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd22_Drm:
	DRUM_UNIT $04
	SND_SEGNO
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	LOOP_END 3
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 4
	DRUM 9, 4
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_START
	LOOP_START
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 2
	DRUM $0B, 4
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_END 2
	DRUM $0B, 4
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 4
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 2
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 4
	DRUM 9, 2
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_END 2
	SND_LOOP

Snd23_Ch2:
	SND_CALL Snd11_Sfx1

Snd24_Ch2:
	TEMPO $32
	SND_SEGNO
	LOOP_START
	VOICE $01, 9, 4, 0, 15
	OCTAVE 3
	NOTE A_, 6
	ATTEN 4
	NOTE A_, 6
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 3
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	OCTAVE 3
	NOTE G#, 6
	ATTEN 4
	NOTE G#, 6
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 6
	ATTEN 4
	NOTE E_, 5
	ATTEN 0
	OCTAVE 3
	NOTE G_, 6
	ATTEN 4
	NOTE G_, 6
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 6
	ATTEN 4
	NOTE E_, 5
	ATTEN 0
	OCTAVE 3
	NOTE G#, 6
	NOTE G#, 6
	ATTEN 4
	NOTE G#, 6
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 6
	ATTEN 4
	NOTE E_, 5
	ATTEN 0
	LOOP_END 4
	LOOP_START
	VOICE $03, 9, 4, 4, 15
	REST 6
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 4
	NOTE E_, 2
	NOTE C_, 6
	ATTEN 5
	NOTE C_, 6
	ATTEN 0
	PAN $F0
	VOICE $03, 15, 0, 3, 15
	OCTAVE 4
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 5
	ATTEN 0
	PAN $FF
	VOICE $03, 9, 4, 4, 15
	REST 6
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 4
	NOTE C_HI, 2
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 6
	ATTEN 0
	PAN $0F
	VOICE $03, 15, 0, 3, 15
	OCTAVE 4
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 5
	ATTEN 0
	PAN $FF
	LOOP_END 2
	VOICE $03, 9, 8, 0, 15
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	ATTEN 0
	NOTE B_, 4
	ATTEN 1
	NOTE C_HI, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 4
	ATTEN 1
	NOTE D_, 2
	NOTE E_, 2
	VIBRATO 7, 0, 1
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	VOICE $03, 7, 4, 0, 15
	OCTAVE 4
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	VIBRATO 7, 1, 1
	NOTE G_, 5
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	VIBRATO_OFF $00
	OCTAVE 4
	NOTE F_, 3
	ATTEN 6
	NOTE F_, 3
	ATTEN 0
	VIBRATO 7, 1, 1
	NOTE E_, 5
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $03, 9, 8, 0, 15
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	ATTEN 0
	NOTE B_, 4
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 4
	ATTEN 1
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 4
	ATTEN 1
	NOTE E_, 2
	NOTE F_, 4
	VOICE $03, 9, 8, 1, 15
	ATTEN 0
	REST 2
	NOTE G#, 2
	NOTE G#, 2
	REST 2
	NOTE G#, 2
	NOTE G#, 2
	REST 2
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 2
	ATTEN 0
	VOICE $01, 9, 8, 2, 15
	REST 3
	NOTE G#, 9
	NOTE G#, 9
	RELEASE 0, $0F
	NOTE G#, 8
	ATTEN 6
	NOTE G#, 5
	REST $0E
	ATTEN 0
	VOICE $03, 9, 8, 0, 15
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	DUTY 4
	ATTEN 3
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 6
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOICE $03, 9, 8, 0, 15
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 3
	ATTEN 6
	NOTE D_, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VIBRATO 7, 0, 1
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE C_, 2
	DUTY 4
	ATTEN 3
	OCTAVE 5
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VOICE $03, 9, 8, 0, 15
	OCTAVE 3
	NOTE C_HI, 2
	ATTEN 6
	NOTE C_HI, 2
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 2
	VIBRATO 7, 0, 1
	ATTEN 0
	NOTE B_, 4
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $03, 9, 8, 0, 15
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	DUTY 4
	ATTEN 3
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOICE $03, 9, 8, 0, 15
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 4
	ATTEN 6
	NOTE D_, 3
	ATTEN 0
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VIBRATO 7, 0, 1
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE C_, 2
	DUTY 4
	ATTEN 4
	OCTAVE 5
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	VOICE $03, 9, 8, 0, 15
	OCTAVE 3
	NOTE C_HI, 2
	ATTEN 6
	NOTE C_HI, 2
	ATTEN 0
	NOTE B_, 2
	NOTE C_HI, 2
	ATTEN 6
	NOTE C_HI, 2
	VIBRATO 7, 0, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 3
	ATTEN 6
	NOTE D_, 3
	ATTEN 0
	VIBRATO_OFF $00
	SND_LOOP

Snd23_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd24_Ch3:
	SND_SEGNO
	LOOP_START
	VOICE $03, 2, 6, 5, 9
	VIBRATO 5, 0, 5
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE E_, 8
	VIBRATO_OFF $00
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 5
	NOTE G_, 4
	VIBRATO 5, 0, 5
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	NOTE A_, 8
	VIBRATO_OFF $00
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 6
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	LOOP_END 2
	LOOP_START
	VOICE $03, 2, 6, 5, 14
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE G#, 2
	NOTE F_, 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE F_, 3
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F#, 2
	RELEASE 4, $0A
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LOOP_END 4
	VOICE $03, 2, 6, 4, 12
	OCTAVE 1
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 2
	REST 2
	OCTAVE 1
	NOTE G_, 4
	RELEASE 4, $0A
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 5
	RELEASE 4, $0A
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE A_, 3
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	REST 2
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 2
	REST 2
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 5
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	LEN_UNIT $01
	REST 9
	OCTAVE 2
	NOTE E_, 9
	NOTE E_, 9
	OCTAVE 2
	NOTE E_, $0D
	REST $0E
	VOICE $03, 2, 6, 3, 7
	LOOP_START
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 4
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 4
	OCTAVE 1
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 4
	NOTE G_, 2
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	LOOP_END 2
	SND_LOOP

Snd23_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd24_Drm:
	SND_SEGNO
	DRUM_UNIT $03
	DRUM 9, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0D, 2
	DRUM $0D, 2
	DRUM $0D, 2
	DRUM 7, 2
	DRUM 7, 2
	DRUM 7, 2
	LOOP_START
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM_UNIT $01
	DRUM $0B, 9
	DRUM 9, 9
	DRUM 9, 9
	DRUM 9, $0D
	DRUM $0A, $0E
	DRUM_UNIT $03
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	SND_LOOP

Snd25_Ch2:
	SND_CALL Snd11_Sfx1

Snd26_Ch2:
	TEMPO $14
	VOICE $05, 13, 8, 3, 8
	OCTAVE 3
	REST 7
	PAN $0F
	LEN_UNIT $01
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE F#, 2
	SND_SEGNO
	LOOP_START
	PAN $F0
	VOICE $05, 13, 8, 3, 8
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $FF
	ATTEN 8
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $0F
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $FF
	ATTEN 8
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	PAN $F0
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $FF
	ATTEN 8
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $F0
	ATTEN 0
	OCTAVE 5
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 8
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 0
	PAN $0F
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	PAN $F0
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $FF
	ATTEN 8
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $0F
	ATTEN 0
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $FF
	ATTEN 8
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	PAN $F0
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $FF
	ATTEN 8
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	PAN $0F
	ATTEN 0
	OCTAVE 5
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 8
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 0
	PAN $F0
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	LOOP_END 2
	PAN $FF
	VOICE $05, 10, 4, 4, 6
	SND_CALL Snd25_Ch2_5D07
	REST 1
	ATTEN 0
	NOTE E_, 8
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 2
	SND_CALL Snd25_Ch2_5D07
	REST 1
	NOTE E_, 1
	REST 1
	NOTE G_, 9
	REST 4
	VOICE $05, 6, 8, 4, 9
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	VOICE $05, 10, 4, 0, 15
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 3
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE B_, 3
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 3
	ATTEN 6
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE F#, 3
	ATTEN 6
	NOTE F#, 1
	ATTEN 0
	VOICE $05, 6, 8, 4, 8
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 0
	VOICE $05, 10, 4, 0, 15
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE D_, 2
	NOTE F#, 2
	ATTEN 6
	NOTE F#, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 7
	ATTEN 6
	NOTE G_, 6
	ATTEN 0
	DUTY 4
	RELEASE 0, $0F
	NOTE G_, 2
	NOTE A_, 1
	NOTE B_, 1
	VOICE $05, 6, 8, 4, 8
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	VOICE $05, 10, 4, 0, 15
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 3
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE B_, 3
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	VIBRATO 2, 1, 1
	OCTAVE 4
	NOTE E_, 7
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	RELEASE 0, $0F
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	REST 1
	VIBRATO 2, 1, 1
	NOTE G_, 8
	ATTEN 6
	NOTE G_, 7
	VIBRATO_OFF $00
	REST 2
	ATTEN 0
	PAN $F0
	VOICE $05, 15, 0, 2, 8
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $0F
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	LEN_UNIT $01
	PAN $F0
	NOTE G_, 3
	NOTE C_HI, 3
	OCTAVE 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_HI, 4
	OCTAVE 5
	NOTE E_, 4
	PAN $0F
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	OCTAVE 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE C_, 4
	SND_LOOP
Snd25_Ch2_5D07:
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 9
	ATTEN 6
	NOTE B_, 4
	ATTEN 0
	NOTE C_HI, 2
	NOTE B_, 3
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 3
	ATTEN 6
	NOTE G_, 1
	OCTAVE 4
	ATTEN 0
	NOTE D_, 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 9
	ATTEN 6
	NOTE B_, 3
	ATTEN 0
	NOTE B_, 1
	NOTE C_HI, 1
	REST 1
	NOTE B_, 1
	SND_RET

Snd25_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd26_Ch3:
	VOICE $05, 2, 6, 4, 11
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	SND_SEGNO
	RELEASE 3, $0B
	SND_CALL Snd25_Ch3_5DAB
	NOTE F#, 4
	RELEASE 4, $0C
	SND_CALL Snd25_Ch3_5DAB
	NOTE B_, 4
	RELEASE 4, $0A
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	RELEASE 4, $0C
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	RELEASE 4, $0A
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	REST 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	RELEASE 4, $0C
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 6
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	SND_LOOP
Snd25_Ch3_5DAB:
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE D_, 1
	LOOP_END 3
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	REST 2
	RELEASE 7, $0B
	SND_RET

Snd25_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd26_Drm:
	DRUM_UNIT $05
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	LOOP_END 3
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 7, 1
	DRUM 1, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 4
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	SND_LOOP

Snd1F_Ch2:
	SND_CALL Snd11_Sfx1

Snd20_Ch2:
	TEMPO $21
	TRANSPOSE_UP 3
	VOICE $04, 10, 8, 0, 15
	OCTAVE 3
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	ATTEN 6
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	ATTEN 0
	NOTE B_, 1
	REST 1
	NOTE B_, 1
	REST 1
	ATTEN 6
	NOTE B_, 1
	REST 1
	NOTE B_, 1
	REST 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 6
	LEN_UNIT $01
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
	ATTEN 6
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 0
	SND_SEGNO
	VOICE $04, 9, 4, 0, 15
	REST 4
	OCTAVE 3
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 4
	ATTEN 0
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE F_, 4
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	NOTE B_, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 2
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 4
	ATTEN 0
	REST 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 4
	ATTEN 0
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE F_, 4
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 2
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 4
	ATTEN 6
	NOTE D_, 4
	ATTEN 0
	RELEASE 3, $0A
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 4
	NOTE D_, 6
	NOTE C_, 4
	NOTE D_, 2
	VIBRATO 1, 1, 1
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 4
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 8, 8, 2, 15
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE E_, 2
	VOICE $04, 8, 4, 3, 10
	REST 2
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 4
	NOTE D_, 6
	NOTE C_, 4
	NOTE D_, 2
	VIBRATO 1, 1, 1
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 4
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 8, 8, 2, 15
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	LEN_UNIT $01
	NOTE B_, 5
	NOTE E_, 5
	NOTE G_, 6
	NOTE A_, 5
	NOTE C_HI, 5
	OCTAVE 4
	NOTE D_, 6
	LEN_UNIT $04
	RELEASE 4, 8
	VIBRATO 1, 0, 1
	NOTE E_, 4
	ATTEN 5
	NOTE E_, 4
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 8, 8, 0, 15
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	DUTY 4
	ATTEN 2
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	DUTY 8
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 2
	ATTEN 0
	RELEASE 4, 8
	NOTE A_, $0A
	RELEASE 0, $0F
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	DUTY 4
	ATTEN 2
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 0
	DUTY 8
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 2
	ATTEN 0
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	VOICE $04, 11, 8, 0, 15
	PAN $F0
	ATTEN 2
	NOTE D_, 2
	ATTEN 8
	NOTE D_, 2
	PAN $0F
	ATTEN 2
	NOTE D_, 2
	ATTEN 8
	NOTE D_, 2
	PAN $F0
	ATTEN 4
	NOTE D_, 2
	ATTEN 8
	NOTE D_, 4
	PAN $FF
	ATTEN 0
	VOICE $01, 15, 4, 0, 15
	PAN $F0
	NOTE D_, 5
	OCTAVE 4
	NOTE C_HI, 5
	NOTE A_, 6
	NOTE F_, 5
	ATTEN 7
	PAN $FF
	NOTE E_, 5
	NOTE D_, 6
	NOTE C_, 5
	OCTAVE 3
	NOTE A_, 5
	ATTEN 0
	PAN $0F
	NOTE F_, 6
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 6
	LEN_UNIT $04
	PAN $FF
	SND_LOOP

Snd1F_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd20_Ch3:
	TRANSPOSE_UP 3
	VOICE $04, 2, 6, 4, 10
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 2
	LOOP_END 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_SEGNO
	RELEASE 4, $0A
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE C_HI, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 2
	RELEASE 4, $0A
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G_, 2
	SND_LOOP

Snd1F_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd20_Drm:
	DRUM_UNIT $04
	LOOP_START
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 2
	LOOP_END 3
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	SND_SEGNO
	SND_CALL Snd1F_Drm_6247
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	SND_CALL Snd1F_Drm_6247
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 4
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 4
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	SND_LOOP
Snd1F_Drm_6247:
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	SND_RET

Snd1D_Ch2:
	SND_CALL Snd11_Sfx1

Snd1E_Ch2:
	ATTEN 0
	TEMPO $1B
	TRANSPOSE_UP 1
	VOICE $05, 11, 4, 1, 15
	OCTAVE 4
	REST 1
	NOTE F#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 1
	REST 9
	VOICE $05, 9, 4, 0, 15
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_SEGNO
	VOICE $05, 10, 4, 0, 15
	OCTAVE 3
	NOTE B_, 8
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 8
	ATTEN 6
	NOTE C_HI, 4
	ATTEN 0
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, $0E
	ATTEN 6
	NOTE D_, 8
	ATTEN 0
	REST 8
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 8
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 8
	ATTEN 5
	NOTE C_HI, 4
	ATTEN 0
	NOTE A_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, $0E
	ATTEN 5
	NOTE G_, 8
	ATTEN 0
	REST $0C
	VOICE $05, 9, 8, 0, 15
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 4
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	NOTE B_, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE D_, 4
	ATTEN 6
	NOTE D_, 8
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 3
	ATTEN 6
	NOTE G_, 5
	ATTEN 0
	OCTAVE 4
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	PAN $F0
	VOICE $05, 15, 4, 0, 15
	OCTAVE 5
	NOTE E_, 1
	ATTEN $0A
	NOTE E_, 3
	ATTEN 0
	NOTE D_, 1
	ATTEN $0A
	NOTE D_, 3
	ATTEN 0
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 3
	ATTEN 0
	PAN $FF
	VOICE $05, 9, 8, 0, 15
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 4
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 3
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	VOICE $05, 15, 4, 2, 15
	PAN $F0
	OCTAVE 4
	NOTE B_, 1
	ATTEN $0A
	NOTE B_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN $0A
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 3
	ATTEN $0A
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	VOICE $05, 9, 8, 0, 15
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 3
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	VOICE $05, 15, 4, 0, 15
	PAN $F0
	OCTAVE 4
	NOTE G_, 1
	ATTEN $0A
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN $0A
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN $0A
	NOTE B_, 3
	ATTEN 0
	PAN $0F
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $FF
	VOICE $05, 9, 4, 4, 15
	ATTEN 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	VOICE $05, 9, 8, 0, 15
	OCTAVE 4
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	NOTE C_HI, 7
	ATTEN 6
	NOTE C_HI, 3
	ATTEN 0
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 5
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, $0B
	ATTEN 6
	NOTE E_, 5
	ATTEN 0
	RELEASE 2, $0F
	DUTY 0
	OCTAVE 4
	REST 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	DUTY 8
	OCTAVE 4
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	NOTE C_HI, 7
	ATTEN 6
	NOTE C_HI, 3
	ATTEN 0
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 5
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE E_, $0B
	ATTEN 6
	NOTE E_, 5
	ATTEN 0
	REST 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	DUTY 4
	REST 4
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_LOOP

Snd1D_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd1E_Ch3:
	TRANSPOSE_UP 1
	VOICE $05, 2, 6, 4, 10
	OCTAVE 2
	REST 1
	NOTE F#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 1
	REST $0D
	SND_SEGNO
	VOICE $05, 2, 6, 4, 10
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_, 1
	REST 1
	NOTE F_, 1
	REST 1
	NOTE F#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE F#, 1
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	REST 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	OCTAVE 2
	NOTE F_, 1
	LOOP_END 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	REST 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	LOOP_START
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	REST 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	OCTAVE 2
	NOTE F_, 1
	LOOP_END 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	REST 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 3
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 8
	SND_LOOP

Snd1D_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd1E_Drm:
	DRUM_UNIT $05
	DRUM $0B, 1
	DRUM 9, 2
	DRUM 9, 1
	REST 1
	DRUM 9, 1
	DRUM 9, 1
	REST 1
	REST $0C
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 7
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	REST 8
	SND_LOOP

Snd27_Ch2:
	SND_CALL Snd11_Sfx1

Snd28_Ch2:
	ATTEN 0
	TEMPO $28
	TRANSPOSE_UP 2
	VOICE $05, 7, 4, 0, 15
	REST 0
	OCTAVE 3
	REST 2
	NOTE C_, 1
	REST 1
	NOTE E_, 1
	NOTE G_, 3
	OCTAVE 4
	SND_SEGNO
	VOICE $05, 9, 4, 0, 15
	NOTE C_, 2
	REST 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 1
	REST 2
	OCTAVE 3
	VIBRATO 7, 1, 1
	NOTE A#, 5
	ATTEN 6
	NOTE A#, 5
	ATTEN 0
	VIBRATO_OFF $00
	NOTE A#, 4
	NOTE B_, 3
	NOTE C_HI, 1
	REST 6
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 1
	REST 2
	VIBRATO 7, 1, 1
	NOTE D#, 5
	ATTEN 6
	NOTE D#, 5
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $05, 15, 0, 0, 15
	PAN $F0
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	PAN $0F
	ATTEN 0
	NOTE D_, 1
	NOTE C#, 1
	PAN $FF
	VOICE $05, 9, 4, 0, 15
	NOTE C_, 3
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	REST 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 1
	REST 2
	OCTAVE 3
	VIBRATO 7, 1, 1
	NOTE A#, 5
	ATTEN 6
	NOTE A#, 5
	VIBRATO_OFF $00
	ATTEN 0
	NOTE A#, 4
	NOTE B_, 3
	NOTE C_HI, 1
	OCTAVE 4
	REST 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 1
	REST 2
	VIBRATO 7, 1, 1
	NOTE D#, 5
	ATTEN 6
	NOTE D#, 5
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $05, 14, 0, 0, 15
	PAN $F0
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	PAN $0F
	ATTEN 0
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $FF
	VOICE $05, 9, 8, 0, 15
	OCTAVE 4
	REST 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	ATTEN 6
	NOTE D#, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE C_, 3
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 3
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	LEN_UNIT $01
	NOTE E_, 2
	NOTE F_, $0D
	LEN_UNIT $05
	ATTEN 6
	NOTE F_, 3
	ATTEN 0
	NOTE G_, 2
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 2
	VIBRATO 7, 0, 1
	ATTEN 0
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	VIBRATO_OFF $00
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F_, 1
	DUTY 8
	REST 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE C_, 3
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 3
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	LEN_UNIT $01
	NOTE E_, 2
	NOTE F_, $0D
	LEN_UNIT $05
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	VIBRATO 7, 0, 1
	NOTE G_, 4
	ATTEN 5
	NOTE G_, 9
	ATTEN 0
	VIBRATO_OFF $00
	NOTE G_, 1
	REST 2
	NOTE G_, 4
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	DUTY 0
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	VOICE $05, 15, 4, 0, 15
	PAN $F0
	OCTAVE 3
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $0F
	OCTAVE 4
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $F0
	ATTEN 8
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 0
	PAN $FF
	VOICE $05, 10, 8, 4, 15
	OCTAVE 3
	REST 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 3
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 3
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 3
	OCTAVE 3
	NOTE A#, 2
	PAN $0F
	VOICE $05, 15, 4, 0, 15
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	PAN $F0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	PAN $0F
	ATTEN 8
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	ATTEN 0
	PAN $FF
	VOICE $05, 10, 8, 4, 15
	OCTAVE 3
	LOOP_START
	NOTE G#, 1
	REST 1
	LOOP_END 3
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	REST 1
	PAN $F0
	VOICE $05, 15, 4, 0, 15
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE F_, 1
	PAN $FF
	VOICE $05, 10, 8, 4, 15
	OCTAVE 3
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	REST 1
	PAN $0F
	VOICE $05, 15, 4, 0, 15
	OCTAVE 5
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	VOICE $05, 15, 4, 0, 15
	PAN $F0
	OCTAVE 3
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $0F
	OCTAVE 4
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $F0
	ATTEN 8
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 0
	PAN $FF
	VOICE $05, 9, 8, 4, 15
	OCTAVE 3
	REST 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 3
	VIBRATO 7, 1, 1
	NOTE G_, 5
	ATTEN 5
	NOTE G_, 3
	ATTEN 0
	NOTE C_HI, 8
	RELEASE $0C, $0F
	ATTEN 5
	NOTE C_HI, 8
	ATTEN 0
	REST 1
	VIBRATO_OFF $00
	RELEASE 4, $0F
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_LOOP

Snd27_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd28_Ch3:
	TRANSPOSE_UP 2
	VOICE $05, 2, 6, 3, 10
	REST 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	REST 8
	NOTE G_, 1
	REST 1
	NOTE C#, 1
	NOTE D_, 3
	SND_SEGNO
	VOICE $05, 2, 6, 3, 10
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	REST 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	REST 1
	NOTE B_, 1
	REST 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	REST 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A#, 1
	RELEASE 6, 8
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 2
	REST 1
	RELEASE 3, $0A
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	REST 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	REST 1
	NOTE B_, 1
	REST 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	REST 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A#, 1
	RELEASE 6, 8
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	REST 1
	RELEASE 3, $0A
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	RELEASE 3, $0A
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	SND_LOOP

Snd27_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd28_Drm:
	DRUM_UNIT $05
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0A, 3
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	LEN_UNIT $01
	DRUM 1, 3
	DRUM 1, 2
	DRUM 9, 5
	DRUM_UNIT $05
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0A, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM 9, 2
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0A, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0A, 1
	DRUM $0A, 1
	SND_LOOP

Snd29_Ch2:
	SND_CALL Snd11_Sfx1

Snd2A_Ch2:
	TEMPO $2B
	VOICE $04, 2, 8, 0, 15
	REST 0
	SND_SEGNO
	VOICE $04, 9, 4, 4, 10
	OCTAVE 3
	REST 4
	NOTE G_, 1
	NOTE A_, 3
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 8, 8, 2, 15
	OCTAVE 5
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 9, 4, 4, 10
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 4
	ATTEN 5
	NOTE G#, 4
	ATTEN 0
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 2
	VIBRATO 4, 1, 1
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF $00
	DUTY 8
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	VIBRATO 4, 1, 1
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF $00
	DUTY 4
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	VIBRATO 4, 3, 1
	NOTE D_, $0A
	ATTEN 6
	NOTE D_, 8
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $04, 7, 8, 2, 15
	OCTAVE 5
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE F_, 2
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	RELEASE 0, $0F
	VIBRATO 4, 1, 1
	NOTE E_, 3
	ATTEN 5
	NOTE E_, 3
	ATTEN 0
	VIBRATO_OFF $00
	PAN $FF
	VOICE $04, 9, 4, 4, 10
	OCTAVE 3
	REST 2
	NOTE G_, 1
	NOTE A_, 5
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 8, 8, 2, 15
	OCTAVE 5
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	ATTEN 0
	VOICE $04, 9, 4, 4, 10
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	VIBRATO 4, 1, 1
	NOTE G#, 4
	ATTEN 5
	NOTE G#, 4
	ATTEN 0
	VIBRATO_OFF $00
	OCTAVE 5
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	VOICE $04, 14, 8, 0, 15
	PAN $F0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE G_, 2
	PAN $0F
	ATTEN 5
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 0
	PAN $FF
	VOICE $04, 9, 4, 4, 10
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	OCTAVE 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 0
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 8, 2, 15
	OCTAVE 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	DUTY 4
	VOICE $04, 9, 4, 4, 10
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C#, 2
	ATTEN 5
	NOTE C#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 2
	NOTE E_, 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	LOOP_START
	VOICE $01, 10, 4, 0, 15
	OCTAVE 3
	REST 8
	NOTE G_, 3
	REST 1
	NOTE A_, 3
	REST 1
	NOTE C_HI, 4
	ATTEN 6
	NOTE C_HI, 4
	ATTEN 0
	NOTE A_, 4
	ATTEN 6
	NOTE A_, 4
	ATTEN 0
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	VIBRATO 1, 1, 1
	OCTAVE 3
	NOTE A_, 8
	ATTEN 6
	NOTE A_, 8
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $01, 14, 4, 0, 15
	PAN $F0
	OCTAVE 4
	NOTE A_, 3
	REST 1
	NOTE A#, 3
	REST 1
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 0
	OCTAVE 5
	NOTE E_, 4
	ATTEN $0A
	NOTE E_, 4
	ATTEN 0
	PAN $0F
	OCTAVE 5
	NOTE G_, 4
	ATTEN $0A
	NOTE G_, 4
	ATTEN 0
	NOTE F_, 4
	ATTEN $0A
	NOTE F_, 4
	ATTEN 0
	VIBRATO 1, 1, 1
	NOTE D_, 8
	ATTEN $0A
	NOTE D_, 8
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $01, 10, 4, 0, 15
	PAN $FF
	OCTAVE 3
	REST 8
	NOTE G_, 3
	REST 1
	NOTE A_, 3
	REST 1
	NOTE C_HI, 4
	ATTEN 6
	NOTE C_HI, 4
	ATTEN 0
	NOTE A_, 4
	ATTEN 6
	NOTE A_, 4
	ATTEN 0
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE G_, 8
	REST 8
	NOTE G_, 8
	NOTE F_, 8
	ATTEN 5
	NOTE F_, 8
	ATTEN 0
	NOTE C_, 8
	VIBRATO 1, 1, 1
	NOTE D_, 8
	ATTEN 5
	NOTE D_, 8
	ATTEN 0
	REST 8
	VIBRATO_OFF $00
	LOOP_END 2
	SND_LOOP

Snd29_Ch3:
	SND_CALL Snd11_Sfx1_4F71

Snd2A_Ch3:
	VOICE $04, 2, 6, 3, 9
	OCTAVE 1
	REST 8
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	SND_SEGNO
	VOICE $04, 2, 6, 3, 9
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	REST 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE G_, 2
	REST 2
	NOTE G#, 2
	REST 2
	NOTE A_, 2
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 3
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP_START
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	LOOP_END 3
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 1
	LOOP2_END 2
	SND_LOOP

Snd29_Drm:
	SND_CALL Snd1D_Drm_4F86

Snd2A_Drm:
	DRUM_UNIT $04
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	SND_SEGNO
	DRUM_UNIT $04
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 4
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 3
	DRUM 1, 1
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	LOOP_END 2
	SND_LOOP

Snd2B_Ch2:
	TEMPO $21
	VOICE $06, 8, 4, 0, 15
	VIBRATO 7, 2, 1
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 8
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	LEN_UNIT $01
	NOTE D_, 0
	NOTE F_, 0
	NOTE A#, 0
	LEN_UNIT $06
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_HI, 8
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	VIBRATO_OFF $00
	OCTAVE 4
	REST 4
	NOTE G_, 2
	REST 1
	VIBRATO 7, 1, 1
	NOTE F_, 8
	ATTEN 5
	NOTE F_, 2
	ATTEN 0
	LEN_UNIT $01
	VIBRATO_OFF $00
	OCTAVE 4
	NOTE A#, 4
	REST 2
	NOTE A#, 6
	REST 6
	LEN_UNIT $06
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 2
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 3
	OCTAVE 4
	REST 4
	NOTE G_, 2
	REST 1
	VIBRATO 7, 1, 1
	NOTE F_, 6
	ATTEN 5
	NOTE F_, 3
	ATTEN 0
	VIBRATO_OFF $00
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	LEN_UNIT $01
	REST 6
	NOTE A#, 4
	REST 2
	NOTE A#, 6
	REST 6
	LEN_UNIT $06
	NOTE A#, 2
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE $06, 8, 4, 0, 15
	VIBRATO 7, 2, 1
	VOICE $06, 8, 4, 0, 15
	VIBRATO 7, 2, 1
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 8
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	LEN_UNIT $01
	ATTEN 1
	NOTE D_, 0
	NOTE F_, 0
	NOTE A#, 0
	LEN_UNIT $06
	ATTEN 2
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_HI, 8
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 3
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	SND_END

Snd2B_Ch1:
	VOICE $06, 4, 8, 0, 15
	VIBRATO 9, 0, 1
	OCTAVE 4
	REST 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 8
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	LEN_UNIT $01
	NOTE D_, 0
	NOTE F_, 0
	NOTE A#, 0
	LEN_UNIT $06
	NOTE G_, 8
	ATTEN 0
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	VIBRATO 14, 0, 1
	NOTE C_HI, 8
	ATTEN 2
	NOTE C_HI, 2
	ATTEN 0
	VIBRATO 9, 0, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	VOICE $06, 6, 0, 0, 15
	OCTAVE 4
	NOTE D_, 2
	REST 1
	NOTE D_, 7
	ATTEN 3
	NOTE D_, 3
	ATTEN 0
	LEN_UNIT $01
	NOTE F_, 4
	REST 2
	NOTE F_, 6
	REST 6
	LEN_UNIT $06
	NOTE F_, 1
	NOTE F_, 1
	REST 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 3
	REST 4
	NOTE D_, 2
	REST 1
	NOTE D_, 6
	ATTEN 3
	NOTE D_, 3
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	RELEASE 2, $0F
	LEN_UNIT $01
	REST 6
	NOTE F_, 4
	REST 2
	NOTE F_, 6
	REST 6
	LEN_UNIT $06
	NOTE F_, 2
	NOTE F#, 1
	NOTE G_, 1
	VOICE $06, 4, 8, 0, 15
	VIBRATO 9, 0, 1
	OCTAVE 4
	REST 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE C_, 8
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	LEN_UNIT $01
	NOTE D_, 0
	NOTE F_, 0
	NOTE A#, 0
	LEN_UNIT $06
	NOTE G_, 8
	ATTEN 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	VIBRATO 14, 0, 1
	NOTE C_HI, 8
	ATTEN 3
	NOTE C_HI, 2
	VIBRATO 9, 0, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	SND_END

Snd2B_Ch3:
	VOICE $06, 2, 6, 3, 8
	LOOP_START
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	LOOP_END 3
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_END

Snd2B_Drm:
	DRUM_UNIT $06
	LOOP2_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_END

Snd2C_Ch2:
	TEMPO $2F
	TRANSPOSE_DOWN 3
	VOICE $05, 9, 4, 4, 10
	REST $0A
	SND_SEGNO
	SND_CALL Snd2C_Ch2_7032
	LEN_UNIT $01
	NOTE F#, 2
	NOTE G_, $0D
	LEN_UNIT $05
	NOTE F_, 3
	REST 2
	LEN_UNIT $01
	NOTE D#, 2
	NOTE E_, $0D
	LEN_UNIT $05
	NOTE C_, 1
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	SND_CALL Snd2C_Ch2_7032
	NOTE F_, 2
	NOTE G_, 1
	REST 1
	NOTE F_, 2
	NOTE E_, 1
	REST 1
	OCTAVE 3
	NOTE C_HI, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE A#, 2
	NOTE B_, 1
	NOTE C_HI, 1
	SND_LOOP
Snd2C_Ch2_7032:
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	REST 1
	NOTE E_, 2
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	REST 2
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	VOICE $05, 15, 0, 2, 15
	PAN $F0
	OCTAVE 5
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE A#, 1
	VOICE $05, 9, 4, 4, 10
	PAN $FF
	LEN_UNIT $01
	OCTAVE 3
	NOTE B_, 2
	NOTE C_HI, $0D
	LEN_UNIT $05
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	VOICE $05, 15, 0, 1, 15
	PAN $F0
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	REST 2
	VOICE $05, 9, 4, 4, 10
	PAN $FF
	SND_RET

Snd2C_Ch1:
	TRANSPOSE_DOWN 3
	VOICE $05, 7, 0, 0, 15
	REST $0A
	SND_SEGNO
	SND_CALL Snd2C_Ch1_70AC
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 3
	REST 2
	NOTE C_, 3
	OCTAVE 3
	NOTE G_, 1
	REST 2
	NOTE F_, 1
	NOTE G_, 1
	SND_CALL Snd2C_Ch1_70AC
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 1
	REST 1
	NOTE D_, 2
	NOTE C_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE F_, 2
	NOTE F#, 1
	NOTE G_, 1
	SND_LOOP
Snd2C_Ch1_70AC:
	OCTAVE 3
	REST 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 2
	REST 1
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	NOTE G_, 1
	REST 2
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	VOICE $05, 12, 8, 2, 15
	PAN $0F
	OCTAVE 5
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	VOICE $05, 7, 0, 4, 10
	PAN $FF
	OCTAVE 3
	NOTE G_, 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	VOICE $05, 12, 8, 1, 15
	PAN $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	REST 2
	VOICE $05, 7, 0, 4, 10
	PAN $FF
	SND_RET

Snd2C_Ch3:
	TRANSPOSE_DOWN 3
	VOICE $05, 2, 6, 3, 11
	REST $0A
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_HI, 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_LOOP

Snd2C_Drm:
	DRUM_UNIT $01
	DRUM 9, 3
	DRUM 9, 2
	DRUM 9, 5
	DRUM $0C, 5
	DRUM $0C, 5
	DRUM $0B, 5
	DRUM $0D, 5
	DRUM $0D, 5
	DRUM $0D, 5
	DRUM $0A, $0A
	SND_SEGNO
	DRUM_UNIT $05
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 2
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM_UNIT $01
	DRUM $0C, 3
	DRUM $0C, 2
	DRUM $0C, 5
	DRUM $0C, 5
	DRUM $0D, 3
	DRUM $0D, 3
	DRUM $0D, 4
	DRUM $0D, 5
	DRUM $0D, 5
	DRUM $0D, 5
	SND_LOOP

Snd2D_Ch2:
	TEMPO $22
	VOICE $05, 9, 4, 0, 15
	REST 8
	TRANSPOSE_DOWN 2
	SND_SEGNO
	SND_CALL Snd2D_Ch2_71F9
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	REST 1
	NOTE F_, 2
	REST 1
	NOTE C_HI, 1
	REST 2
	VIBRATO 7, 0, 1
	NOTE A#, 8
	ATTEN 5
	NOTE A#, 4
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $05, 15, 0, 0, 15
	PAN $F0
	OCTAVE 4
	NOTE F_, 2
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	REST 1
	ATTEN $0A
	OCTAVE 4
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	REST 1
	ATTEN 0
	PAN $FF
	VOICE $05, 9, 4, 0, 15
	SND_CALL Snd2D_Ch2_71F9
	OCTAVE 5
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE D#, 2
	REST 1
	NOTE F_, 1
	REST 2
	OCTAVE 4
	VIBRATO 7, 0, 1
	NOTE A#, $0A
	VIBRATO_OFF $00
	PAN $F0
	VOICE $05, 15, 0, 0, 15
	NOTE G#, 2
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	REST 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN $0A
	NOTE F_, 1
	REST 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	SND_LOOP
Snd2D_Ch2_71F9:
	VOICE $05, 9, 4, 0, 15
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	REST 1
	NOTE F_, 2
	REST 1
	NOTE A#, 1
	REST 2
	NOTE A#, 3
	ATTEN 5
	NOTE A#, 1
	ATTEN 0
	LEN_UNIT $01
	RELEASE 4, $0F
	NOTE A#, 4
	REST 1
	NOTE A#, 4
	REST 1
	LEN_UNIT $05
	NOTE G#, 2
	NOTE G_, 2
	RELEASE 0, $0F
	NOTE F_, 2
	REST 1
	OCTAVE 3
	NOTE A#, 1
	VOICE $05, 15, 0, 0, 15
	PAN $F0
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	ATTEN $0A
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	VOICE $05, 9, 4, 0, 15
	SND_RET

Snd2D_Ch1:
	VOICE $05, 5, 8, 0, 15
	REST 8
	TRANSPOSE_DOWN 2
	SND_SEGNO
	SND_CALL Snd2D_Ch1_72BD
	REST 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 8
	REST 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 0
	VOICE $05, 5, 8, 0, 15
	PAN $FF
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE C_HI, 1
	REST 1
	OCTAVE 4
	NOTE D_, 2
	REST 1
	NOTE F_, 1
	REST 2
	VIBRATO 6, 0, 2
	ATTEN 1
	NOTE F_, $0C
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $05, 15, 4, 0, 15
	PAN $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 1
	REST 1
	NOTE F_, 1
	REST 1
	ATTEN 8
	NOTE D#, 1
	REST 1
	NOTE F_, 1
	REST 1
	ATTEN 0
	PAN $FF
	SND_CALL Snd2D_Ch1_72BD
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A#, 1
	ATTEN $0A
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A#, 1
	ATTEN 0
	PAN $FF
	VOICE $05, 5, 8, 0, 15
	OCTAVE 4
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	REST 1
	NOTE C_HI, 2
	REST 1
	NOTE A#, 1
	REST 2
	VIBRATO 7, 0, 2
	NOTE F_, $0A
	VIBRATO_OFF $00
	PAN $0F
	VOICE $05, 15, 0, 0, 15
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 1
	REST 1
	OCTAVE 4
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	ATTEN $0A
	OCTAVE 4
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 0
	PAN $FF
	SND_LOOP
Snd2D_Ch1_72BD:
	VOICE $05, 5, 8, 0, 15
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE C_HI, 1
	REST 1
	OCTAVE 4
	NOTE D_, 2
	REST 1
	NOTE F_, 1
	REST 2
	ATTEN 1
	VIBRATO 6, 0, 2
	NOTE F_, $0E
	ATTEN 0
	VIBRATO_OFF $00
	PAN $0F
	VOICE $05, 15, 4, 0, 15
	SND_RET

Snd2D_Ch3:
	TRANSPOSE_DOWN 2
	VOICE $05, 2, 6, 3, 10
	REST 4
	VOICE $05, 2, 6, 3, 10
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 2
	NOTE E_, 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	SND_LOOP

Snd2D_Drm:
	DRUM_UNIT $01
	DRUM $0C, 3
	DRUM $0C, 2
	DRUM $0A, 5
	DRUM $0D, 5
	DRUM $0A, 5
	DRUM_UNIT $05
	SND_SEGNO
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	SND_LOOP

Snd2E_Ch2:
	TEMPO $40
	TRANSPOSE_UP 1
	VOICE $03, 12, 4, 4, 15
	OCTAVE 3
	REST 2
	ATTEN 4
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 3
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	VOICE $03, 14, 4, 4, 10
	PAN $F0
	OCTAVE 4
	REST 2
	NOTE G#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 2
	ATTEN $0A
	NOTE A_, 2
	ATTEN 0
	VOICE $03, 10, 0, 3, 12
	PAN $FF
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 3
	ATTEN 0
	NOTE E_, 4
	ATTEN 7
	NOTE E_, 2
	ATTEN 0
	VOICE $03, 14, 4, 4, 10
	PAN $F0
	NOTE G#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 2
	PAN $FF
	VOICE $02, 10, 0, 4, 15
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	VOICE $01, 10, 0, 2, 15
	OCTAVE 4
	NOTE C_HI, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 7
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	VOICE $03, 14, 4, 4, 10
	PAN $F0
	NOTE G#, 1
	NOTE A_, 1
	ATTEN $0A
	NOTE A_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, 2
	ATTEN $0A
	NOTE A_, 2
	ATTEN 0
	VOICE $03, 10, 0, 4, 15
	PAN $FF
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 7
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	ATTEN 0
	VOICE $03, 9, 8, 3, 15
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	VOICE $02, 3, 8, 0, 15
	NOTE F#, 1
	NOTE D#, 1
	ATTEN 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	SND_END

Snd2E_Ch1:
	TRANSPOSE_UP 1
	VOICE $03, 8, 8, 0, 15
	REST 2
	OCTAVE 2
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 3
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	VOICE $03, 14, 4, 4, 10
	PAN $0F
	OCTAVE 4
	REST 2
	NOTE D#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	ATTEN $0A
	NOTE E_, 2
	ATTEN 0
	VOICE $03, 8, 4, 4, 15
	PAN $FF
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 3
	ATTEN 0
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	VOICE $03, 14, 4, 4, 10
	PAN $0F
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	PAN $FF
	VOICE $02, 8, 4, 4, 15
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	LEN_UNIT $01
	OCTAVE 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 0
	VOICE $03, 14, 4, 4, 10
	PAN $0F
	NOTE D#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	ATTEN $0A
	NOTE E_, 2
	ATTEN 0
	VOICE $03, 8, 4, 4, 15
	PAN $FF
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 5
	OCTAVE 2
	NOTE A_, 4
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 4
	NOTE C_, 6
	NOTE D_, 6
	NOTE E_, 2
	NOTE E_, 2
	VOICE $02, 3, 0, 0, 15
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_END

Snd2E_Ch3:
	TRANSPOSE_UP 1
	VOICE $03, 2, 6, 3, 8
	REST 2
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	OCTAVE 1
	LOOP_START
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 4
	NOTE E_, 4
	NOTE D#, 2
	OCTAVE 1
	LOOP_START
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	OCTAVE 1
	LOOP_START
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	VOICE $02, 6, 6, 4, 12
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_END

Snd2E_Drm:
	DRUM_UNIT $03
	REST 2
	REST 4
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0A, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0A, 2
	SND_END

Snd2F_Ch2:
	TEMPO $21
	VOICE $03, 8, 8, 0, 15
	REST 2
	REST 0
	SND_CALL Snd2F_Ch2_75E5
	OCTAVE 4
	NOTE B_, 3
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	NOTE G_, 5
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	TRANSPOSE_UP 2
	SND_CALL Snd2F_Ch2_75E5
	TRANSPOSE_UP 0
	NOTE C#, 3
	ATTEN 5
	NOTE C#, 3
	OCTAVE 4
	ATTEN 0
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE E_, 2
	OCTAVE 5
	NOTE C#, 2
	SND_CALL Snd2F_Ch2_75E5
	OCTAVE 4
	NOTE B_, 3
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	NOTE G_, 5
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE G_, 4
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE G_, 4
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	TRANSPOSE_UP 2
	LOOP_END 2
	TRANSPOSE_UP 0
	DUTY 8
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 2
	ATTEN 7
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 4
	SND_END
Snd2F_Ch2_75E5:
	VOICE $03, 8, 8, 0, 15
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 2
	ATTEN 0
	NOTE D_, 4
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 4
	ATTEN 0
	OCTAVE 3
	NOTE A_, 5
	ATTEN 5
	NOTE A_, 5
	ATTEN 0
	VOICE $03, 13, 4, 0, 15
	PAN $F0
	REST 4
	OCTAVE 4
	NOTE E_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE G_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE D_, 2
	NOTE E_, 2
	PAN $FF
	VOICE $03, 8, 8, 0, 15
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 2
	ATTEN 0
	NOTE D_, 4
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 3
	ATTEN 5
	NOTE E_, 3
	ATTEN 0
	NOTE A_, 5
	ATTEN 5
	NOTE A_, 5
	ATTEN 0
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	OCTAVE 5
	NOTE C#, 5
	ATTEN 5
	NOTE C#, 5
	ATTEN 0
	SND_RET

Snd2F_Ch1:
	VOICE $03, 8, 8, 0, 15
	REST 2
	REST 0
	SND_CALL Snd2F_Ch1_769C
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 3
	ATTEN 0
	NOTE E_, 5
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	TRANSPOSE_UP 2
	SND_CALL Snd2F_Ch1_769C
	TRANSPOSE_UP 0
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 3
	ATTEN 0
	NOTE E_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE A_, 2
	SND_CALL Snd2F_Ch1_769C
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 3
	ATTEN 0
	NOTE E_, 5
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	LOOP_START
	DUTY $0C
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 3
	ATTEN 5
	NOTE D_, 3
	ATTEN 0
	DUTY 8
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 3
	ATTEN 5
	NOTE D_, 3
	ATTEN 0
	TRANSPOSE_UP 2
	LOOP_END 2
	TRANSPOSE_UP 0
	DUTY 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 7
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 4
	SND_END
Snd2F_Ch1_769C:
	VOICE $03, 8, 12, 3, 15
	OCTAVE 3
	REST 4
	NOTE G_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE G_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE D_, 2
	NOTE E_, 2
	PAN $0F
	VOICE $03, 13, 8, 3, 15
	REST 4
	OCTAVE 4
	NOTE C#, 2
	REST 4
	NOTE D_, 2
	REST 4
	NOTE E_, 2
	REST 4
	NOTE D_, 2
	REST 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	PAN $FF
	VOICE $03, 8, 12, 3, 15
	OCTAVE 3
	REST 4
	NOTE G_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE G_, 2
	REST 4
	NOTE F#, 2
	REST 4
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 6
	NOTE A_, $0A
	SND_RET

Snd2F_Ch3:
	VOICE $03, 2, 6, 3, 8
	REST 2
	REST 0
	SND_CALL Snd2F_Ch3_7730
	LEN_UNIT $04
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	LEN_UNIT $03
	TRANSPOSE_UP 2
	SND_CALL Snd2F_Ch3_7730
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	TRANSPOSE_UP 0
	SND_CALL Snd2F_Ch3_7730
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	VOICE $03, 2, 6, 3, 8
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	LOOP_END 3
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	TRANSPOSE_DOWN 3
	LOOP2_END 2
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	SND_END
Snd2F_Ch3_7730:
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 7
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_END 3
	SND_RET

Snd2F_Drm:
	DRUM_UNIT $03
	REST 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	LOOP2_START
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP2_END 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 2
	LOOP_END 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM $0A, 2
	SND_END

Snd30_Ch2:
	TEMPO $10
	VOICE $07, 0, 4, 0, 15
	REST 4
	VOICE $01, 10, 4, 0, 15
	SND_CALL Snd30_Ch1_783E
	PAN $FF
	VOICE $01, 9, 8, 4, 10
	REST 7
	OCTAVE 3
	NOTE A_, 7
	REST $0E
	NOTE G_, 2
	NOTE A_, $0D
	NOTE G_, 7
	NOTE A_, 7
	REST 7
	NOTE A_, 7
	REST $0E
	NOTE B_, 2
	NOTE C_HI, $0D
	NOTE B_, 7
	NOTE A_, 7
	SND_CALL Snd30_Ch2_78AF
	VOICE $01, 9, 8, 4, 10
	REST 7
	OCTAVE 3
	NOTE A_, 7
	REST $0E
	NOTE G_, 2
	NOTE A_, $0C
	NOTE G_, 7
	NOTE A_, 7
	NOTE C_HI, 7
	REST 7
	NOTE B_, 7
	REST 7
	NOTE A_, 7
	NOTE G_, 7
	REST $0E
	SND_CALL Snd30_Ch2_78AF
	VOICE $07, 9, 8, 0, 15
	OCTAVE 4
	NOTE F_, 4
	ATTEN 4
	VIBRATO 4, 0, 1
	NOTE F_, 4
	VIBRATO_OFF $00
	ATTEN 0
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_HI, 2
	OCTAVE 5
	NOTE D_, 4
	VIBRATO 4, 0, 1
	ATTEN 5
	NOTE D_, 4
	VIBRATO_OFF $00
	ATTEN 0
	OCTAVE 4
	NOTE B_, 4
	NOTE G_, 4
	RELEASE 2, $0A
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	ATTEN 6
	LEN_UNIT $02
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
Snd30_Ch1_783E:
	PAN $F0
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $0F
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $F0
	OCTAVE 5
	NOTE F_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE F_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $0F
	OCTAVE 5
	NOTE F_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE F_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $F0
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $0F
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	OCTAVE 5
	NOTE E_, 5
	NOTE C_, 5
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	PAN $F0
	OCTAVE 5
	NOTE D_, 5
	OCTAVE 4
	NOTE B_, 5
	NOTE G_, 4
	ATTEN 5
	OCTAVE 5
	NOTE D_, 5
	OCTAVE 4
	NOTE B_, 5
	NOTE G_, 4
	ATTEN 0
	PAN $0F
	OCTAVE 5
	NOTE D_, 5
	OCTAVE 4
	NOTE B_, 5
	NOTE G_, 4
	ATTEN 5
	OCTAVE 5
	NOTE D_, 5
	OCTAVE 4
	NOTE B_, 5
	NOTE G_, 4
	ATTEN 0
	SND_RET
Snd30_Ch2_78AF:
	VOICE $01, 15, 4, 4, 8
	PAN $F0
	OCTAVE 3
	NOTE F_, 4
	NOTE C_, 3
	NOTE F_, 4
	NOTE A_, 3
	OCTAVE 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 3
	NOTE F_, 4
	NOTE C_, 3
	OCTAVE 4
	NOTE A_, 4
	NOTE F_, 3
	VOICE $01, 8, 4, 4, 8
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 3
	ATTEN 0
	VOICE $01, 15, 4, 4, 8
	OCTAVE 3
	NOTE G_, 4
	NOTE D_, 3
	NOTE G_, 4
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 3
	NOTE G_, 4
	NOTE D_, 3
	OCTAVE 4
	NOTE B_, 4
	NOTE G_, 3
	VOICE $01, 8, 4, 4, 8
	ATTEN 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 3
	ATTEN 0
	PAN $FF
	SND_RET

Snd30_Ch1:
	VOICE $0E, 0, 4, 0, 15
	REST 2
	VOICE $01, 8, 4, 0, 15
	VIBRATO 3, 0, 1
	SND_CALL Snd30_Ch1_783E
	VIBRATO_OFF $00
	PAN $FF
	VOICE $07, 7, 4, 4, 10
	REST 1
	OCTAVE 3
	NOTE E_, 1
	REST 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE E_, 1
	SND_CALL Snd30_Ch1_795C
	VOICE $07, 7, 4, 4, 10
	REST 1
	OCTAVE 3
	NOTE E_, 1
	REST 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	NOTE D_, 1
	REST 2
	SND_CALL Snd30_Ch1_795C
	VOICE $07, 7, 4, 0, 15
	OCTAVE 4
	NOTE C_, 4
	ATTEN 3
	VIBRATO 4, 0, 1
	NOTE C_, 4
	VIBRATO_OFF $00
	ATTEN 0
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 2
	NOTE B_, 4
	ATTEN 4
	VIBRATO 4, 0, 1
	NOTE B_, 4
	VIBRATO_OFF $00
	ATTEN 0
	NOTE G_, 4
	NOTE D_, 4
	RELEASE 2, $0A
	NOTE C#, 3
	NOTE C#, 3
	NOTE C#, 2
	ATTEN 5
	LEN_UNIT $02
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
Snd30_Ch1_795C:
	VOICE $01, 15, 4, 4, 8
	PAN $0F
	OCTAVE 2
	NOTE C_HI, 4
	NOTE A_, 3
	NOTE C_HI, 4
	OCTAVE 3
	NOTE F_, 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 3
	NOTE F_, 4
	NOTE A_, 3
	NOTE C_HI, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 3
	VOICE $01, 4, 4, 4, 8
	OCTAVE 3
	NOTE A_, 4
	NOTE F_, 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 3
	ATTEN 0
	VOICE $01, 15, 4, 4, 8
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 3
	NOTE G_, 4
	NOTE B_, 3
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 3
	VOICE $01, 4, 4, 4, 8
	ATTEN 2
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 3
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 3
	ATTEN 0
	PAN $FF
	SND_RET

Snd30_Ch3:
	VOICE $0E, 2, 6, 4, 9
	REST 2
	VOICE $01, 2, 6, 4, 11
	OCTAVE 1
	NOTE G_, 4
	NOTE G#, 3
	NOTE A_, 7
	NOTE A_, 7
	NOTE A_, $0E
	NOTE A_, 7
	NOTE A_, 7
	NOTE A_, 7
	NOTE G_, 4
	NOTE G#, 3
	NOTE A_, 7
	NOTE A_, 7
	NOTE A_, $0E
	NOTE A_, 7
	NOTE G#, 7
	NOTE G_, 7
	NOTE E_, 4
	NOTE F_, 3
	NOTE F_, 7
	NOTE F_, 7
	NOTE F_, $0E
	NOTE F_, 7
	NOTE E_, 7
	NOTE F_, 7
	NOTE F_, 4
	NOTE F#, 3
	NOTE G_, 7
	NOTE G_, 7
	NOTE G_, $0E
	NOTE G_, 7
	NOTE E_, 7
	NOTE G_, 7
	VOICE $07, 2, 6, 4, 10
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G#, 1
	VOICE $07, 2, 6, 4, 10
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G_, 1
	RELEASE 4, $0A
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	LEN_UNIT $01
	OCTAVE 2
	NOTE D_, 4
	NOTE C#, 3
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 3
	NOTE A#, 4
	NOTE A_, 3
	NOTE G#, 4
	NOTE G_, 3
	RELEASE 6, 8
	NOTE G_, 3
	NOTE G#, 4
	NOTE A_, $0E
	NOTE G_, 3
	NOTE G#, 4
	NOTE A_, $0E
	NOTE G_, 3
	NOTE G#, 4
	NOTE A_, 7
	SND_END

; Orphan subroutine (no SND_CALL reaches it; decoded as Ch1).
Orphan_7A6E:
	RELEASE 4, 9
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET

Snd30_Drm:
	DRUM_UNIT $01
	DRUM 1, 4
	DRUM 1, 3
	DRUM 9, 7
	DRUM $0A, $0E
	LOOP_START
	DRUM 1, 4
	DRUM 1, 3
	DRUM 2, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	LOOP_END 3
	DRUM 1, 4
	DRUM 1, 3
	DRUM 9, 4
	DRUM 9, 3
	DRUM 9, $0E
	DRUM 9, 7
	DRUM 9, 7
	DRUM $0A, $0E
	DRUM $0B, $0E
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, 7
	DRUM $0B, $0E
	DRUM $0B, 7
	DRUM 9, 4
	DRUM 9, 3
	DRUM 9, 7
	DRUM $0B, $0E
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, 7
	DRUM 9, 7
	DRUM $0B, $0E
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, 7
	DRUM $0B, $0E
	DRUM $0B, 7
	DRUM 9, 4
	DRUM 9, 3
	DRUM 9, 7
	DRUM $0B, $0E
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0C, 4
	DRUM $0C, 3
	DRUM $0D, 7
	DRUM 7, 7
	DRUM 7, 7
	LOOP_START
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	DRUM $0B, 7
	DRUM $0B, 7
	DRUM 9, $0E
	LOOP_END 3
	DRUM $0C, 4
	DRUM $0C, 3
	DRUM $0C, 7
	DRUM $0D, 7
	DRUM $0D, 7
	DRUM 7, 7
	DRUM 7, 7
	DRUM 1, 4
	DRUM 9, $0A
	DRUM $0A, $0E
	DRUM 1, 7
	DRUM $0A, $0E
	DRUM 1, 7
	DRUM $0A, $0E
	DRUM 1, 7
	SND_END

; EngineTable: periods for the engine sound ($1A), indexed by wEngineVar ($00-$6F); the last
; seven ($7BC4-$7BD1) are out of reach.

EngineTable:
	dw $02C3, $02E9, $030F, $0324, $0357, $0379, $039A, $03BA
	dw $03D9, $03F7, $0415, $0431, $044D, $0468, $0483, $049C
	dw $04B5, $04CD, $04E4, $04FB, $0511, $0526, $053B, $054F
	dw $0563, $0575, $0588, $059A, $05AC, $05BC, $05CD, $05DD
	dw $05ED, $05FC, $060B, $0619, $0627, $063C, $0642, $064E
	dw $065B, $0667, $0673, $067E, $068A, $0695, $069F, $06A9
	dw $06B3, $06BC, $06C6, $06CF, $06D8, $06E0, $06E9, $06F1
	dw $06F8, $0701, $0704, $0707, $070A, $070E, $0712, $0713
	dw $0715, $0718, $071B, $071E, $0722, $0725, $0728, $072B
	dw $072F, $0732, $0734, $0737, $073A, $073D, $073F, $0742
	dw $0745, $0748, $074A, $074D, $0750, $0753, $0755, $0758
	dw $075A, $075C, $075E, $075F, $0761, $0763, $0765, $0767
	dw $0769, $0769, $0769, $076A, $076A, $076A, $076B, $076B
	dw $076B, $076B, $076C, $076C, $076C, $076C, $076C, $076C
	dw $076C, $076E, $076F, $0770, $0771, $0772, $0773

; Game data (read by the game code, not by the sound driver).
GameData:
	db $F2, $7B, $F8, $7B, $FF, $7B, $06, $7C, $0D, $7C, $13, $7C, $1A, $7C, $20, $7C
	db $27, $7C, $2E, $7C, $34, $7C, $3B, $7C, $41, $7C, $48, $7C, $4F, $7C, $56, $7C
	db $05, $02, $03, $04, $03, $04, $03, $05, $04, $02, $03, $03, $03, $02, $03, $0F
	db $03, $03, $04, $02, $0F, $03, $0F, $0F, $05, $03, $06, $05, $02, $03, $02, $06
	db $0F, $02, $0F, $05, $03, $0F, $04, $05, $06, $0F, $03, $0F, $03, $05, $03, $04
	db $03, $02, $03, $04, $03, $0F, $03, $0F, $04, $02, $02, $04, $03, $02, $03, $0F
	db $0F, $05, $03, $04, $04, $02, $03, $04, $03, $04, $04, $05, $03, $04, $04, $05
	db $06, $05, $06, $0F, $03, $03, $02, $04, $03, $03, $05, $04, $03, $04, $05, $04
	db $03, $03, $0F, $05, $03, $04, $04, $03, $05, $0F, $04, $10, $60, $10, $F0, $11
	db $60, $14, $90, $14, $F0, $15, $60, $0C, $30, $0C, $F0, $0D, $60, $14, $30, $14
	db $F0, $15, $60, $12, $30, $12, $F0, $13, $60, $0C, $90, $0C, $F0, $0D, $60, $0A
	db $70, $0A, $F0, $0B, $60, $0E, $30, $0E, $F0, $0F, $60, $0C, $30, $0C, $F0, $0D
	db $60, $14, $60, $14, $F0, $15, $60, $18, $30, $18, $F0, $19, $60, $18, $30, $18
	db $F0, $19, $60, $10, $90, $10, $F0, $11, $60, $14, $30, $14, $F0, $15, $60, $14
	db $70, $14, $F0, $15, $60, $12, $70, $12, $F0, $13, $60, $14, $60, $14, $F0, $15
	db $60, $1C, $40, $1C, $F0, $1D, $60, $12, $60, $12, $F0, $13, $60, $1C, $70, $1C
	db $F0, $1D, $60, $18, $30, $18, $F0, $19, $60, $14, $30, $14, $F0, $15, $60, $14
	db $60, $14, $F0, $15, $60, $1A, $60, $1A, $F0, $1B, $60, $12, $60, $12, $F0, $13
	db $60, $A7, $98, $DE, $DC, $E3, $00, $DE, $D9, $FE, $C7, $98, $CC, $CF, $00, $CB
	db $FF, $C7, $98, $E1, $D9, $DC, $D6, $CE, $FE, $E6, $98, $CD, $D2, $CB, $D7, $DA
	db $D3, $D9, $D8, $FF, $87, $98, $DD, $CF, $CD, $D9, $D8, $CE, $FE, $A7, $98, $DA
	db $D6, $CB, $CD, $CF, $FE, $C7, $98, $DE, $DC, $E3, $FE, $E7, $98, $D2, $CB, $DC
	db $CE, $CF, $DC, $FE, $07, $99, $DE, $D9, $00, $E1, $D3, $D8, $FF, $87, $98, $DE
	db $D2, $D3, $DC, $CE, $FF, $53, $7D, $5B, $7D, $5B, $7D, $57, $7D, $5F, $7D, $63
	db $7D, $53, $53, $28, $28, $5C, $3C, $5C, $3C, $27, $27, $56, $56, $5F, $39, $60
	db $38, $60, $38, $61, $37, $55, $7F, $67, $7F, $7D, $7F, $91, $7F, $A5, $7F, $C1
	db $7F, $D1, $7F, $DD, $7F, $F1, $7F, $99, $7D, $B7, $7D, $D1, $7D, $ED, $7D, $07
	db $7E, $27, $7E, $43, $7E, $57, $7E, $73, $7E, $91, $7E, $AF, $7E, $CF, $7E, $E1
	db $7E, $F7, $7E, $19, $7F, $3D, $7F, $36, $02, $44, $06, $54, $08, $70, $06, $7E
	db $08, $96, $0A, $A8, $04, $BC, $0C, $F8, $02, $07, $06, $19, $08, $25, $0A, $37
	db $04, $47, $0C, $4B, $00, $28, $04, $40, $02, $4E, $0A, $58, $04, $68, $08, $9E
	db $06, $D0, $08, $F8, $16, $19, $18, $2B, $12, $43, $06, $67, $14, $89, $00, $24
	db $04, $58, $0C, $68, $02, $8C, $16, $A0, $08, $CC, $06, $E6, $08, $F4, $06, $03
	db $08, $25, $0E, $4B, $16, $5F, $0C, $79, $1A, $8F, $00, $20, $02, $34, $0E, $4E
	db $16, $6C, $18, $76, $16, $84, $08, $92, $0E, $B0, $0E, $BE, $0A, $C8, $1C, $F2
	db $08, $03, $0A, $0F, $00, $20, $02, $2E, $06, $48, $08, $58, $06, $64, $08, $72
	db $0A, $7C, $02, $8A, $1A, $B8, $02, $C4, $06, $E8, $18, $17, $06, $23, $0C, $33
	db $02, $41, $0A, $4B, $00, $4E, $02, $5A, $06, $68, $0C, $9C, $04, $AE, $18, $BA
	db $0A, $C6, $02, $D6, $16, $E4, $08, $F2, $06, $09, $08, $1D, $06, $41, $0C, $4B
	db $00, $2C, $04, $38, $08, $46, $06, $54, $04, $BA, $08, $FA, $16, $07, $0C, $19
	db $04, $29, $0C, $2D, $00, $2E, $02, $56, $0E, $68, $06, $78, $0C, $88, $04, $A6
	db $18, $B2, $0A, $CC, $04, $D8, $18, $F0, $12, $1D, $0A, $25, $04, $37, $0C, $4B
	db $00, $20, $04, $2E, $08, $9E, $0A, $A8, $02, $FA, $0A, $03, $02, $0F, $0A, $17
	db $02, $47, $0A, $4F, $02, $5B, $0A, $93, $02, $9F, $06, $BF, $0C, $CB, $00, $2C
	db $02, $42, $16, $4E, $0C, $54, $1C, $84, $06, $96, $08, $B4, $0A, $C2, $04, $CE
	db $0C, $D4, $04, $E0, $0C, $F4, $02, $13, $06, $29, $0C, $2B, $00, $1E, $04, $28
	db $18, $38, $0A, $78, $06, $B4, $02, $BE, $16, $EA, $18, $03, $0A, $11, $04, $2B
	db $08, $39, $06, $47, $08, $91, $0A, $97, $04, $B5, $1C, $CB, $00, $52, $02, $5E
	db $06, $86, $0C, $AA, $04, $C8, $08, $03, $0E, $15, $06, $57, $0C, $8B, $00, $2C
	db $04, $42, $0C, $52, $02, $72, $06, $94, $08, $B2, $06, $D0, $14, $E4, $08, $11
	db $06, $31, $0C, $4B, $00, $26, $04, $40, $14, $4E, $08, $5A, $0A, $6E, $04, $80
	db $08, $90, $06, $A6, $14, $B0, $08, $C0, $12, $DE, $06, $F6, $14, $03, $0C, $0F
	db $02, $39, $06, $43, $0C, $4B, $00, $34, $02, $50, $0A, $5A, $02, $66, $0A, $74
	db $02, $84, $0A, $92, $04, $A6, $0C, $B0, $02, $CA, $16, $E6, $0C, $F6, $02, $13
	db $0A, $53, $04, $71, $08, $81, $16, $9F, $0C, $AB, $00, $26, $04, $3C, $08, $4C
	db $06, $5C, $08, $6E, $06, $84, $14, $A2, $04, $D8, $18, $E8, $06, $0F, $08, $1B
	db $0A, $2B, $00, $1E, $04, $48, $0C, $4C, $02, $6A, $0A, $AE, $04, $D8, $0C, $DC
	db $02, $07, $0A, $0D, $00, $24, $04, $46, $0C, $7E, $02, $94, $06, $D6, $08, $01
	db $0A, $0D, $02, $1D, $06, $2D, $0C, $37, $02, $4D, $00, $2A, $04, $44, $08, $5A
	db $0A, $68, $02, $78, $0A, $84, $04, $94, $08, $AA, $06, $B6, $0C, $CC, $00, $3E
	db $02, $56, $0A, $68, $04, $84, $08, $A8, $06, $E0, $0C, $EA, $02, $F4, $16, $25
	db $0C, $4D, $00, $26, $04, $34, $0C, $3E, $02, $5A, $06, $8C, $0C, $96, $02, $C2
	db $0A, $CC, $02, $DA, $0A, $E4, $04, $03, $08, $0F, $06, $1F, $0C, $2D, $00, $1E
	db $02, $42, $06, $52, $08, $66, $06, $82, $0C, $90, $06, $C8, $0C, $CC, $00, $20
	db $02, $30, $06, $4A, $0C, $8C, $04, $A4, $0C, $AC, $00, $26, $02, $58, $06, $6E
	db $0C, $78, $02, $8A, $06, $A0, $0C, $B6, $02, $CA, $06, $DA, $0C, $EC, $00, $30
	db $04, $40, $08, $66, $06, $80, $08, $A2, $06, $B8, $0C, $CC, $00, $FF
