; ==========================================================================
; Tiny Toon Adventures - Babs' Big Break (E) - Konami sound driver (bank 7)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: AddHLA (rst $28) and the bank-7 wrappers ($04E7-$0540)
;   bank 7: helpers, envelope tables, the driver ($4180-$4E14), tables, headers, streams ($4FF7-$6FA2)
; Build: rgbasm -Wall -o tt.o TT_SoundDriver.asm && rgblink -o tt.gb tt.o
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
DEF wTrkSfx1 EQU $C080 ; 64 bytes
DEF wTrkSfx2 EQU $C180 ; 64 bytes
DEF wTrkSfxN EQU $C280 ; 64 bytes
DEF wTrkCh1 EQU $C380 ; 64 bytes
DEF wTrkCh2 EQU $C480 ; 64 bytes
DEF wTrkCh3 EQU $C580 ; 64 bytes
DEF wTrkDrm EQU $C680 ; 64 bytes
DEF wTrackIdx EQU $C784
DEF wRegBase EQU $C785
DEF wTempo EQU $C786
DEF wTempoAcc EQU $C787
DEF wTempoSkip EQU $C788
DEF wQueuedSnd EQU $C789
DEF wNR51 EQU $C78A
DEF wReg0Val EQU $C78B
DEF wReqId EQU $C78C
DEF wReqPrio EQU $C78D
DEF wRegVal EQU $C78E
DEF wRegOff EQU $C78F
DEF wMusicHold EQU $C790
DEF wCountdown EQU $C791
DEF wFadeReq EQU $C793
DEF wFadeStep EQU $C794
DEF wFadeLevel EQU $C795
DEF wReqRefused EQU $C796
DEF wRegShadow EQU $C79F ; 21 bytes
DEF wSndLock EQU $C985
DEF wC98B EQU $C98B
DEF wFadeTimer EQU wRegShadow ; the NR10 shadow doubles as the fade timer
DEF rROMB EQU $2345 ; MBC1 bank select (the game writes it here)

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
DEF TRK_ID EQU $80
DEF TRK_PRIO EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_FLAGS2 EQU $86
DEF TRK_REPCNT EQU $87
DEF TRK_VIB EQU $89
DEF TRK_TRANSP EQU $8A
DEF TRK_ATTEN EQU $8B
DEF TRK_VIBOFS EQU $8C
DEF TRK_VIBREPCNT EQU $8E
DEF TRK_ENVREPCNT EQU $8F
DEF TRK_UNIT EQU $91
DEF TRK_OCTAVE EQU $92
DEF TRK_PERIOD EQU $93
DEF TRK_RAWPERIOD EQU $95
DEF TRK_VOL EQU $97
DEF TRK_DUTY EQU $98
DEF TRK_ENV EQU $99
DEF TRK_GATE EQU $9A
DEF TRK_RELTICK EQU $9B
DEF TRK_VIBTIMER EQU $9C
DEF TRK_VIBRELOAD EQU $9D
DEF TRK_CH3TIMER EQU $9E
DEF TRK_CH3RELOAD EQU $9F
DEF TRK_LEVEL EQU $A1
DEF TRK_SEGNO EQU $A2
DEF TRK_RET EQU $A6
DEF TRK_VIBPTR EQU $AA
DEF TRK_VIBIDX EQU $AC
DEF TRK_VIBLOOPIDX EQU $AD
DEF TRK_VIBDEPTH EQU $AE
DEF TRK_VIBDELAY EQU $AF
DEF TRK_VIBDELAYRELOAD EQU $B0
DEF TRK_VIBDELAYCNT EQU $B1
DEF TRK_ENVNO EQU $B2
DEF TRK_ENVTIMER EQU $B3
DEF TRK_ENVRELOAD EQU $B4
DEF TRK_ENVVOL EQU $B5
DEF TRK_ENVPTR EQU $B6
DEF TRK_ENVIDX EQU $B8
DEF TRK_ENVLOOPIDX EQU $B9
DEF TRK_DUTYCNT EQU $BA
DEF TRK_DUTYSTART EQU $BB
DEF TRK_DUTYTICKS EQU $BC
DEF TRK_PAN EQU $BD
DEF TRK_OCTSHIFT EQU $BE
DEF TRK_DETUNE EQU $BF

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
; $EA xy: octave shift x (0-7 up, 8-15 down, see OctaveShiftTable; only with OCTAVE > 1),
; semitones y (negated when x >= 8)
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

SECTION "AddHLA", ROM0[$0028]

AddHLA:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "Sound ROM0", ROM0[$04E7]

MapSoundBank:
	ld a, $07
	ld [rROMB], a
	ret

; SndUpdateFar (called from every VBlank): skipped while wSndLock bit 0 is set, else
; map bank 7, SndUpdate, restore the caller's bank (from $7FFF of the bank it had).
SndUpdateFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, [$7FFF]
	push af
	ld a, $07
	ld [rROMB], a
	call SndUpdate

RestoreBank:
	pop af
	ld [rROMB], a
	ld hl, wSndLock
	res 0, [hl]
	ret

StopSoundFar:
	ld a, $00
	jp PlaySoundFar

StopThenPlayFar:
	push af
	call StopSoundFar
	pop af

; PlaySoundFar: A = sound id; dropped while wSndLock bit 0 is set (the update is running).
; StopSoundFar plays 0 (StopAll); StopThenPlayFar does both.
PlaySoundFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld b, a
	ld a, [$7FFF]
	push af
	call MapSoundBank
	ld a, b
	call PlaySound
	jr RestoreBank

; StartFadeFar: wFadeReq = A | $80 (any A starts the fade).
StartFadeFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld b, a
	ld a, [$7FFF]
	push af
	call MapSoundBank
	ld a, b
	call StartFade
	jr RestoreBank

SECTION "Sound bank 7", ROMX[$4000], BANK[7]

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

JumpTable:
	pop hl
	call LoadPtrIndexed
	jp hl

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

; EnvelopeTable: 32 pointers, but EC n only reaches 1-15 (the code adds 2 * ((n & 15) - 1)).
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
	dw Env10 ; 16 (unreachable: EC n uses n & 15)
	dw Env11 ; 17 (unreachable: EC n uses n & 15)
	dw Env12 ; 18 (unreachable: EC n uses n & 15)
	dw Env13 ; 19 (unreachable: EC n uses n & 15)
	dw Env14 ; 20 (unreachable: EC n uses n & 15)
	dw Env15 ; 21 (unreachable: EC n uses n & 15)
	dw Env16 ; 22 (unreachable: EC n uses n & 15)
	dw Env17 ; 23 (unreachable: EC n uses n & 15)
	dw Env18 ; 24 (unreachable: EC n uses n & 15)
	dw Env19 ; 25 (unreachable: EC n uses n & 15)
	dw Env1A ; 26 (unreachable: EC n uses n & 15)
	dw Env1B ; 27 (unreachable: EC n uses n & 15)
	dw Env1C ; 28 (unreachable: EC n uses n & 15)
	dw Env1D ; 29 (unreachable: EC n uses n & 15)
	dw Env1E ; 30 (unreachable: EC n uses n & 15)
	dw Env1F ; 31 (unreachable: EC n uses n & 15)
	dw Env20 ; 32 (unreachable: EC n uses n & 15)
Env01:
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 1, 8
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env02:
	ENV_STEP 3, 1
	ENV_STEP 4, 2
	ENV_STEP 5, 3
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env03:
	ENV_STEP 1, 7
	ENV_STEP 1, 6
	ENV_STEP 1, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env04:
	ENV_STEP 1, 2
	ENV_STEP 2, 4
	ENV_STEP 3, 6
	ENV_STEP 4, 8
	ENV_STEP 5, 9
	ENV_STEP 6, 11
	ENV_STEP 6, 8
	ENV_STEP 5, 6
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env05:
	ENV_STEP 3, 5
	ENV_STEP 4, 6
	ENV_STEP 5, 7
	ENV_STEP 6, 8
	ENV_STEP 7, 9
	ENV_STEP 6, 4
	ENV_STEP 5, 3
	ENV_STEP 4, 2
	ENV_END
Env06:
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 5, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_STEP 1, 1
	ENV_STEP 2, 2
	ENV_STEP 3, 3
	ENV_STEP 4, 4
	ENV_STEP 5, 5
	ENV_STEP 6, 6
	ENV_STEP 7, 7
	ENV_STEP 8, 8
	ENV_STEP 1, 6
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_END
Env07:
	ENV_STEP 1, 7
	ENV_STEP 1, 6
	ENV_STEP 5, 4
	ENV_STEP 4, 3
	ENV_STEP 3, 2
	ENV_STEP 3, 1
	ENV_STEP 2, 2
	ENV_STEP 3, 3
	ENV_STEP 4, 4
	ENV_STEP 5, 5
	ENV_STEP 6, 6
	ENV_STEP 7, 7
	ENV_STEP 8, 8
	ENV_STEP 1, 6
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_END
Env08:
	ENV_STEP 1, 3
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	ENV_END
Env09:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 9
	ENV_STEP 3, 10
	ENV_STEP 3, 11
	ENV_STEP 4, 7
	ENV_STEP 5, 6
	ENV_STEP 6, 5
	ENV_STEP 7, 4
	ENV_END
Env0A:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 3, 8
	ENV_STEP 2, 9
	ENV_STEP 3, 5
	ENV_STEP 6, 4
	ENV_STEP 7, 3
	ENV_STEP 8, 2
	ENV_END
Env0B:
	ENV_STEP 1, 11
	ENV_STEP 2, 10
	ENV_STEP 2, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 1
	ENV_STEP 4, 2
	ENV_STEP 3, 3
	ENV_STEP 2, 4
	ENV_END
Env0C:
	ENV_STEP 2, 9
	ENV_STEP 2, 8
	ENV_STEP 2, 7
	ENV_STEP 2, 6
	ENV_STEP 3, 1
	ENV_STEP 3, 2
	ENV_STEP 4, 3
	ENV_STEP 5, 4
	ENV_STEP 6, 5
	ENV_END
Env0D:
	ENV_STEP 1, 3
	ENV_STEP 1, 6
	ENV_STEP 1, 9
	ENV_STEP 1, 3
	ENV_END
Env0E:
	ENV_STEP 3, 10
	ENV_STEP 4, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 4
	ENV_STEP 2, 3
	ENV_STEP 1, 2
	ENV_END
Env0F:
	ENV_STEP 1, 8
	ENV_STEP 2, 7
	ENV_STEP 2, 6
	ENV_STEP 2, 4
	ENV_STEP 2, 3
	ENV_STEP 1, 2
	ENV_END
Env10:
	ENV_STEP 1, 5
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 9
	ENV_STEP 3, 10
	ENV_STEP 3, 11
	ENV_STEP 3, 12
	ENV_STEP 5, 8
	ENV_STEP 6, 7
	ENV_STEP 7, 6
	ENV_STEP 8, 5
	ENV_STEP 9, 4
	ENV_STEP 10, 3
	ENV_END
Env11:
	ENV_STEP 1, 2
	ENV_STEP 3, 3
	ENV_STEP 4, 4
	ENV_STEP 5, 5
	ENV_STEP 6, 6
	ENV_STEP 7, 5
	ENV_STEP 8, 4
	ENV_STEP 9, 3
	ENV_STEP 10, 2
	ENV_END
Env12:
	ENV_STEP 1, 4
	ENV_STEP 2, 6
	ENV_STEP 3, 8
	ENV_STEP 4, 9
	ENV_STEP 5, 11
	ENV_STEP 6, 8
	ENV_STEP 5, 6
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env13:
	ENV_STEP 3, 2
	ENV_STEP 4, 3
	ENV_STEP 5, 4
	ENV_STEP 6, 5
	ENV_STEP 7, 4
	ENV_STEP 6, 3
	ENV_STEP 5, 2
	ENV_END
Env14:
	ENV_STEP 2, 3
	ENV_STEP 3, 4
	ENV_STEP 4, 5
	ENV_STEP 5, 6
	ENV_STEP 6, 7
	ENV_STEP 6, 5
	ENV_STEP 5, 4
	ENV_STEP 4, 3
	ENV_STEP 3, 2
	ENV_END
Env15:
	ENV_STEP 2, 3
	ENV_STEP 2, 4
	ENV_STEP 2, 5
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 5
	ENV_STEP 2, 4
	ENV_STEP 2, 3
	ENV_STEP 2, 2
	ENV_END
Env16:
	ENV_STEP 2, 3
	ENV_STEP 2, 4
	ENV_STEP 2, 5
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 5
	ENV_STEP 2, 4
	ENV_STEP 2, 3
	ENV_STEP 2, 2
	ENV_END
Env17:
	ENV_STEP 1, 11
	ENV_STEP 2, 10
	ENV_STEP 3, 9
	ENV_STEP 4, 8
	ENV_STEP 5, 1
	ENV_STEP 4, 2
	ENV_STEP 3, 3
	ENV_STEP 2, 4
	ENV_STEP 1, 5
	ENV_END
Env18:
	ENV_STEP 1, 3
	ENV_STEP 2, 4
	ENV_STEP 3, 5
	ENV_STEP 4, 6
	ENV_STEP 5, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_END
Env19:
	ENV_STEP 1, 10
	ENV_STEP 1, 9
	ENV_STEP 5, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	ENV_STEP 1, 1
	ENV_STEP 2, 2
	ENV_STEP 3, 3
	ENV_STEP 4, 4
	ENV_STEP 5, 5
	ENV_STEP 6, 6
	ENV_STEP 7, 7
	ENV_STEP 8, 8
	ENV_STEP 7, 6
	ENV_STEP 6, 5
	ENV_STEP 5, 4
	ENV_STEP 4, 3
	ENV_STEP 3, 2
	ENV_END
Env1A:
	ENV_END
Env1B:
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	ENV_END
Env1C:
	ENV_STEP 1, 8
	ENV_STEP 2, 7
	ENV_STEP 3, 6
	ENV_STEP 4, 4
	ENV_STEP 5, 3
	ENV_STEP 6, 2
	ENV_END
Env1D:
	ENV_STEP 1, 7
	ENV_STEP 2, 6
	ENV_STEP 3, 5
	ENV_STEP 4, 3
	ENV_STEP 5, 2
	ENV_END
Env1E:
	ENV_END
Env1F:
	ENV_END
Env20:
	ENV_END

; FadeTick: while wFadeReq is set, every $30 updates wFadeLevel + 1 (off new music notes;
; half on CH3) and wFadeStep + 1. Step 5 stops the drums, 7 Ch3, 9 Ch1/Ch2 - but when the
; matching SFX track is idle it jumps (or calls) Flow_End, whose `pop hl` takes this
; routine's return address as the track page: the stop writes go to the MBC, NRx2 = 0 is
; written for the last ticked track's channel, and (jp) the rest of the update is skipped.
; Without a request wFadeTimer, which is also the NR10 shadow, is cleared every update.
FadeTick:
	ld a, [wFadeReq]
	or a
	jr nz, FadeReset.l4190

FadeReset:
	ld [wFadeTimer], a
	ld [wFadeLevel], a
	ld [wFadeStep], a
	ret
.l4190:
	ld a, [wFadeTimer]
	inc a
	ld [wFadeTimer], a
	cp $30
	jp z, .l419D
	ret
.l419D:
	xor a
	ld [wFadeTimer], a
	ld a, [wFadeLevel]
	inc a
	ld [wFadeLevel], a
	ld a, [wFadeStep]
	inc a
	ld [wFadeStep], a
	ld a, [wFadeStep]
	cp $05
	jp nz, .l41CD
	ld hl, wTrkSfxN
	ld a, [hl]
	or a
	jr z, .l41C7
	xor a
	ld hl, wTrkDrm
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ret
.l41C7:
	ld hl, wTrkDrm
	jp Flow_End
.l41CD:
	ld a, [wFadeStep]
	cp $07
	jp nz, .l41DB
	ld hl, wTrkCh3
	jp Flow_End
.l41DB:
	ld a, [wFadeStep]
	cp $09
	ret nz
	ld hl, wTrkSfx1
	ld a, [hl]
	or a
	jr z, .l41F2
	xor a
	ld hl, wTrkCh1
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	jr FadeCh2
.l41F2:
	ld hl, wTrkCh1
	call Flow_End

FadeCh2:
	ld hl, wTrkSfx2
	ld a, [hl]
	or a
	jr z, .l420B
	xor a
	ld hl, wTrkCh2
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	jp FadeReset
	ret
.l420B:
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

; SndUpdate (once per VBlank): fade, a countdown nothing sets, tempo, then tracks 0-6 in
; order. On a tempo carry (or wMusicHold) tracks 3-6 all skip the frame. wQueuedSnd is never
; set. The jr z at $424A and the code at $425F are dead.
SndUpdate:
	call FadeTick
	call CountdownTick
	call TempoTick
	xor a

UpdateLoop:
	ld [wTrackIdx], a
	ld a, [wC98B]
	bit 0, a
	jr z, .l424C
.l424C:
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
	jr z, .l427F
	call TrackTick
.l427F:
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
; Else: duty step, released flag, vibrato, envelope, then CH3 decay, the envelope volume
; (retriggered on each step) or, at the release tick, NRx2 = env | level + retrigger.
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
	jr z, .l42DF
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l42DF:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l42EB
	ld l, TRK_FLAGS
	set 0, [hl]
.l42EB:
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
	jr c, .l4363
	xor a
.l4363:
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
	call JumpTable
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
	jr z, .l43BC
	ld l, TRK_REPCNT
	inc [hl]
	cp [hl]
	jr z, .l43C6
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l43BC:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l43C6:
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
	jr nz, .l43EA
	xor a
	ldh [rNR30], a
	ret
.l43EA:
	cp $01
	jr z, .l43F8
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l43FA
.l43F8:
	ld h, HIGH(wTrkCh2)
.l43FA:
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
	call JumpTable
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
	jr z, .l447D
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
.l447D:
	res 4, [hl]
	jp NextCmd

Cmd_Transpose:
	pop hl
	ld a, [de]
	and $F0
	ld l, TRK_OCTSHIFT
	ld [hl], a
	sla a
	jp c, .l4497
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd
.l4497:
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
	jp nz, .l44B2
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp NextCmd
.l44B2:
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAY
	ld [hl], a
	or a
	jp nz, .l44C6
	ld l, TRK_FLAGS2
	res 7, [hl]
	jp .l44DA
.l44C6:
	push bc
	ld l, TRK_VIBDELAY
	ld b, [hl]
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l44CE:
	add a, c
	dec b
	jp nz, .l44CE
	ld l, TRK_VIBDELAYRELOAD
	ld [hl], a
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
	pop bc
.l44DA:
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
	call LoadPtrIndexed
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
	call JumpTable
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
	call JumpTable
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
	jr z, .l4695
	or $02
	jr .l4697
.l4695:
	and $FD
.l4697:
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
	jr nz, .l46B7
	inc de
	jp NextCmd
.l46B7:
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
	call JumpTable
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
; OctaveShiftTable[shift] (the shift only when the octave is not 0), from PeriodTable.
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
.l4756:
	dec b
	jr z, .l475C
	add a, c
	jr .l4756
.l475C:
	ld l, TRK_LEN
	ld [hl], a
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jp z, .l4770
	ld l, TRK_FLAGS2
	set 7, [hl]
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAYCNT
	ld [hl], a
.l4770:
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l479D
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l479D
	ld l, TRK_DUTYSTART
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegOff], a
	call WriteReg
.l479D:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l47AA
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l47BC
.l47AA:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l47B2:
	srl c
	jr nc, .l47B7
	add a, d
.l47B7:
	rra
	dec b
	jr nz, .l47B2
	pop de
.l47BC:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBREPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, OctaveShiftTable.l47F6
	ld b, a
	ld c, $0C
	xor a
.l47CF:
	add a, c
	dec b
	jr nz, .l47CF
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
	jr OctaveShiftTable.l47F5
OctaveShiftTable:
	db $00, $0C, $18, $24, $30, $3C, $48, $54, $F4, $E8, $DC, $D0, $C4, $B8, $AC, $A0
.l47F5:
	ld c, a
.l47F6:
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
	jr .l4819
.l4819:
	push bc
	ld l, TRK_VIB
	ld a, [hl]
	ld l, TRK_ENVNO
	ld b, [hl]
	or b
	pop bc
	jp z, .l4832
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	ld l, TRK_ENVIDX
	ld [hl], a
	call VibratoStep
	call EnvelopeStep
.l4832:
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
	jp nc, .l4874
	inc b
.l4874:
	ld a, [bc]
	cp $FB
	jr z, .l4895
	cp $FE
	jr z, .l489F
	cp $FF
	jr z, .l48BD
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
.l4895:
	ld l, TRK_ENVIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_ENVLOOPIDX
	ld [hl], a
	inc bc
	jr .l4874
.l489F:
	inc bc
	ld a, [bc]
	ld l, TRK_ENVREPCNT
	cp [hl]
	jr z, .l48B4
	cp $FF
	jr z, .l48AB
	inc [hl]
.l48AB:
	ld l, TRK_ENVLOOPIDX
	ld a, [hl]
	ld l, TRK_ENVIDX
	ld [hl], a
	jp EnvelopeStep
.l48B4:
	xor a
	ld [hl], a
	ld l, TRK_ENVIDX
	inc [hl]
	inc bc
	jp .l4874
.l48BD:
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

; CalcVolume: TRK_VOL - TRK_ATTEN (music: - wFadeLevel), 0 on a borrow. CH3: level code
; (vol / 2) & 3 + atten + wFadeLevel / 2, 0 (mute) from 4; NR30 = $80.
CalcVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, CalcVolumeCh3
	ld a, [wTrackIdx]
	cp $03
	jr c, .l48FC
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l48F6
	xor a
.l48F6:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l48FC:
	xor a
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l490B
	xor a
.l490B:
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
	jr c, .l4939
	xor a
.l4939:
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
	jr z, .l4960
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
.l4960:
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
	jr c, .l4978
	add a, c
	ld c, a
	jr nc, WritePeriod
	inc b
	jr WritePeriod
.l4978:
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
	call LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l49E9:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l49E9
	pop hl
	pop de
	ret

IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4A01
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4A0A
.l4A01:
	cp $04
	jr nz, .l4A0C
	ld a, [wTrkSfx2]
	or a
	ret z
.l4A0A:
	scf
	ret
.l4A0C:
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
	jr nz, .l4A2C
	ld a, [hl]
	cp c
	jr z, .l4A2F
.l4A2C:
	ld a, c
	ld [hl], a
	ld [de], a
.l4A2F:
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
; frames (NRx2 = vol << 4, period, trigger, NR51 bits) or $00 rests, one unit each. $E7, $E9,
; $EA, $EE, $EF are commands; $E8 and $EB-$ED go to RawFrame with HL still pushed (crash).
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
	jr z, .l4AA9
	cp $00
	jr z, .l4AA9
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
	jr .l4AB4
.l4AA9:
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
.l4AB4:
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
	call JumpTable
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
	jp z, .l4B6E
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	cp $00
	jp z, .l4B6E
	ld l, TRK_VIBDELAYCNT
	dec [hl]
	ret nz
.l4B6E:
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
	jp nc, .l4B94
	inc b
.l4B94:
	ld a, [bc]
	cp $FB
	jr z, .l4BDF
	cp $FE
	jr z, .l4BE9
	cp $FF
	jr z, .l4C07
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l4BB8
	ld l, TRK_FLAGS
	set 3, [hl]
	jp .l4BBC
.l4BB8:
	ld l, TRK_FLAGS
	res 3, [hl]
.l4BBC:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l4BDB
	push bc
	xor a
	ld c, a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4BD2:
	add a, c
	dec b
	jp nz, .l4BD2
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l4BDB:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4BDF:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4B94
.l4BE9:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBREPCNT
	cp [hl]
	jr z, .l4BFE
	cp $FF
	jr z, .l4BF5
	inc [hl]
.l4BF5:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp VibratoStep
.l4BFE:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4B94
.l4C07:
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

StartFade:
	set 7, a
	ld [wFadeReq], a
	ret

; PlaySoundA: 0 = StopAll. Sfx1, then (unless wReqRefused) Sfx2/SfxN, then (unless
; wReqRefused) the music tracks, then NR51 = wNR51. A refused track (priority lower than the
; running one) jumps out with wReqRefused still 1 (StartRefused pops the wrong values and
; returns from PlaySound), so the next request is dropped after its Sfx1 part.
PlaySoundA:
	ld [wReqId], a
	or a
	jp z, StopAll
	ld [wReqId], a
	push af
	pop af
	ld [wReqId], a
	ld hl, SoundTable
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
	jr nz, .l4C7D
	ld a, $08
	ldh [rNR10], a
	ld [wRegShadow], a
.l4C7D:
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
	jr .l4D02
.l4D02:
	push de
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld l, TRK_PTR + 1
	ld d, [hl]
	ld a, [de]
	cp $01
	jr nz, .l4D18
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr StartTrackEnd
.l4D18:
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

; StopAll: clear the seven track pages, the shadows and the globals; wNR51 = $FF (not
; written); NR12/NR17/NR21/NR32 = 0.
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $0040
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $0040
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
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; RestoreRegs: copy the shadows back to the registers of every channel in use. Never
; called.
RestoreRegs:
	ld a, [wC98B]
	ld b, a
	ld a, [wMusicHold]
	or b
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l4DDB
	ld hl, wRegShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l4DDB:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l4DF0
	ld hl, wRegShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l4DF0:
	ld a, [wTrkCh3]
	or a
	jr z, .l4E01
	ld hl, wRegShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l4E01:
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

; WaveTable: CH3 waves by duty - 1 (15 pointers; the waves overlap).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData2 ; wave 2
	dw WaveData3 ; wave 3
	dw WaveData4 ; wave 4
	dw WaveData5 ; wave 5
	dw WaveData6 ; wave 6
	dw WaveData7 ; wave 7
	dw WaveData8 ; wave 8
	dw $4F30 ; wave 9 (reads the sound table)
	dw $4F30 ; wave 10 (reads the sound table)
	dw $4F30 ; wave 11 (reads the sound table)
	dw $4F30 ; wave 12 (reads the sound table)
	dw WaveData2 ; wave 13
	dw $4F30 ; wave 14 (reads the sound table)
	dw $4F30 ; wave 15 (reads the sound table)
WaveData1:
	db $FF
WaveData2:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData3:
	db $FF
WaveData4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData5:
	db $FF
WaveData6:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
WaveData7:
	db $88, $88, $88, $88, $77, $66, $55, $44, $00, $00, $00, $00, $00, $00, $00, $00
WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63

; SoundTable: ids $01-$63 (entry 0 unused).
SoundTable:
	dw $FF17 ; $00 (unused: the code adds 2 * id)
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
	dw SndHdr07 ; $4D
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

SndHdr07:
	SND_HEADER $27, $01 ; tracks: Sfx1
	dw Snd07_Sfx1

SndHdr08:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd08_Sfx1

SndHdr09:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0A:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0A_Sfx1

SndHdr0B:
	SND_HEADER $27, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd11_Ch1
	dw Snd11_Ch2
	dw Snd11_Ch3
	dw Snd11_Drm

SndHdr12:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $37, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd18_Sfx1
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $34, $04 ; tracks: SfxN
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $34, $05 ; tracks: Sfx1, SfxN
	dw Snd1A_Sfx1
	dw Snd1A_SfxN

SndHdr1B:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1F:
	SND_HEADER $28, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $31, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd20_Sfx1
	dw Snd20_Sfx2
	dw Snd20_Ch3

SndHdr21:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd26_Sfx1

SndHdr27:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $31, $18 ; tracks: Ch1, Ch2
	dw Snd28_Ch1
	dw Snd28_Ch2

SndHdr29:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd2A_Sfx1

SndHdr2B:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $34, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $31, $03 ; tracks: Sfx1, Sfx2
	dw Snd2D_Sfx1
	dw Snd2D_Sfx2

SndHdr2E:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $27, $04 ; tracks: SfxN
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $27, $04 ; tracks: SfxN
	dw Snd30_SfxN

SndHdr31:
	SND_HEADER $27, $04 ; tracks: SfxN
	dw Snd31_SfxN

SndHdr33:
	SND_HEADER $26, $04 ; tracks: SfxN
	dw Snd33_SfxN

SndHdr32:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd32_SfxN

SndHdr34:
	SND_HEADER $29, $01 ; tracks: Sfx1
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd36_Sfx1

SndHdr37:
	SND_HEADER $31, $03 ; tracks: Sfx1, Sfx2
	dw Snd37_Sfx1
	dw Snd37_Sfx2

SndHdr38:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr39:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd39_Sfx1

SndHdr3A:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3C_Sfx1

SndHdr3D:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $35, $04 ; tracks: SfxN
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $28, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd43_Sfx1

SndHdr44:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd44_Sfx1

SndHdr45:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd45_Sfx1

SndHdr46:
	SND_HEADER $37, $04 ; tracks: SfxN
	dw Snd46_SfxN

SndHdr47:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr1E:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr4B:
	SND_HEADER $31, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd4B_Ch1
	dw Snd4B_Ch2
	dw Snd4B_Ch3

SndHdr4C:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd07_Sfx1

SndHdr4E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd4E_Ch1
	dw Snd4E_Ch2
	dw Snd4E_Ch3
	dw Snd4E_Drm

SndHdr4F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd4F_Ch1
	dw Snd4F_Ch2
	dw Snd4F_Ch3
	dw Snd4F_Drm

SndHdr50:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd50_Ch1
	dw Snd50_Ch2
	dw Snd50_Ch3
	dw Snd50_Drm

SndHdr51:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd51_Ch1
	dw Snd51_Ch2
	dw Snd51_Ch3
	dw Snd51_Drm

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

; DrumMap: drum note hi - 1 -> sound id.
DrumMap:
	db $01, $02, $05, $02, $01, $02, $01, $03, $06, $04, $04, $04, $06

SndHdr01:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd06_SfxN

Snd01_SfxN:
	CMD_EF $0F
	NVOICE $01, $52
	NOISE $1C
	SND_END

Snd02_SfxN:
	CMD_EF $F0
	NVOICE $01, $52
	NOISE $1C
	SND_END

Snd03_SfxN:
	NVOICE $01, $A1
	NOISE $41
	NOISE $11
	SND_END

Snd04_SfxN:
	NVOICE $01, $52
	NOISE $58
	SND_END

Snd05_SfxN:
	NVOICE $01, $41
	NOISE $40
	NVOICE $40, $74
	NOISE $00
	SND_END

Snd06_SfxN:
	NVOICE $09, $24
	NOISE $41
	SND_END

; VibratoTable: 15 pointers (EB n uses entry n).
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
	VIB_END

Vib02:
	VIB_END

Vib03:
	VIB_END

Vib04:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 0
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

Vib05:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 1
	VIB_STEP 11, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

Vib06:
	VIB_SEGNO
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

Vib07:
	VIB_END

Vib08:
	VIB_END

Vib09:
	VIB_END

Vib0A:
	VIB_END

Vib0B:
	VIB_END

Vib0C:
	VIB_END

Vib0D:
	VIB_END

Vib0E:
	VIB_END

Vib0F:
	VIB_END

Snd07_Sfx1:
	TRANSPOSE_UP $0E
	VOICE $01, 15, 8, 15, 0
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
	TRANSPOSE_UP 0
	SND_END

Snd08_Sfx1:
	VOICE $03, 14, 8, 15, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE G_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE G_, 1
	SND_END

Snd09_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	ATTEN $0A
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_END

Snd0A_Sfx1:
	VOICE $03, 14, 8, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 1
	ATTEN $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	SND_END

Snd0B_Sfx1:
	VOICE $03, 14, 0, 15, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE G_, 1
	SND_END

Snd0C_Sfx1:
	TRANSPOSE_DOWN 6
	VOICE $03, 15, 8, 1, 15
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 7
	NOTE C#, 1
	ATTEN 8
	OCTAVE 2
	NOTE B_, 1
	SND_END

Snd0D_Sfx1:
	TRANSPOSE_DOWN 6
	VOICE $03, 15, 0, 1, 15
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 2
	NOTE C#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 7
	NOTE F_, 1
	ATTEN 8
	NOTE E_, 1
	SND_END

Snd0E_Sfx1:
	VOICE $01, 15, 4, 15, 0
	OCTAVE 4
	NOTE A#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	SND_END

Snd0F_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE B_, 1
	SND_END

Snd10_Sfx1:
	VOICE $01, 15, 4, 15, 0
	OCTAVE 5
	NOTE B_, 1
	ATTEN $0A
	NOTE B_, 1
	SND_END

Snd13_Sfx1:
	VOICE $05, 15, 8, 5, 15
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd14_Sfx1:
	VOICE $04, 15, 0, 5, 8
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN $0A
	REST 2
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd15_Sfx1:
	VOICE $02, 15, 8, 1, 15
	OCTAVE 5
	NOTE C_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE A_, 1
	SND_END
	db $85 ; unreachable bytes after an end
	db $21

Snd16_Sfx1:
	VOICE $05, 15, 8, 1, 15
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 2
	SND_END

Snd17_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_END

Snd18_Sfx1:
	VOICE $01, 15, 8, 15, 0
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_REPEAT $08
	SND_END

Snd18_SfxN:
	SND_END

Snd19_SfxN:
	NVOICE $06, $F5
	NOISE $61
	NOISE $81
	NOISE $71
	NVOICE $03, $B5
	NOISE $71
	NOISE $71
	NOISE $71
	NVOICE $03, $85
	NOISE $81
	NOISE $81
	NOISE $81
	SND_END

Snd11_Ch2:
	TEMPO $60
	VOICE $01, 8, 8, 0, 0
	OCTAVE 5
	NOTE B_, 3
	REST 1
	OCTAVE 6
	NOTE C_, 3
	REST 1
	OCTAVE 5
	NOTE G#, 3
	REST 1
	NOTE A_, 3
	REST 1
	NOTE D#, 3
	REST 1
	NOTE E_, 3
	REST 1
	OCTAVE 4
	NOTE A#, 3
	REST 1
	NOTE B_, 3
	REST 1
	OCTAVE 5
	NOTE C_, 4
	REST 4
	OCTAVE 1
	NOTE G_, 4
	REST 4
	OCTAVE 2
	NOTE C_, 4
	SND_END

Snd11_Ch1:
	VOICE $01, 6, 8, 3, 15
	SND_CALL Snd11_Ch1_5405
	RELEASE 0, 0
	OCTAVE 3
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
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
	RELEASE $0F, 2
	OCTAVE 2
	NOTE C_, 8
	SND_END
Snd11_Ch1_5405:
	OCTAVE 3
	NOTE E_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE C_, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	SND_RET

Snd11_Ch3:
	VOICE $01, 2, 2, 2, 15
	TRANSPOSE 9, 0
	SND_CALL Snd11_Ch1_5405
	NOTE C_, 4
	REST 4
	NOTE G_, 4
	REST 4
	OCTAVE 2
	NOTE C_, 6
	REST 2
	SND_END

Snd11_Drm:
	SND_END

Snd12_Sfx1:
	VOICE $01, 15, 0, 3, 14
	OCTAVE 4
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 6
	REST 2
	NOTE F_, 1
	NOTE F#, 1
	ATTEN $0A
	REST 2
	NOTE D#, 1
	NOTE E_, 1
	SND_END

Snd1A_Sfx1:
	SND_END

Snd1A_SfxN:
	NVOICE $05, $83
	NOISE $71
	NOISE $51
	SND_END

Snd1B_SfxN:
	NVOICE $02, $F3
	NOISE $3D
	NVOICE $02, $F3
	NOISE $11
	NVOICE $02, $F3
	NOISE $11
	SND_END

Snd1C_Sfx1:
	TRANSPOSE 0, 0
	VOICE $01, 15, 8, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	SND_END

Snd1D_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 8
	NOTE A_, 1
	NOTE A#, 1
	SND_END
	db $FF

Snd1F_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	NOTE G#, 1
	ATTEN 8
	NOTE A#, 1
	ATTEN 9
	OCTAVE 5
	NOTE C_, 1
	ATTEN $0A
	NOTE E_, 1
	SND_END

Snd20_Ch3:
	VIBRATO $04, 6, 0
	VOICE $04, 2, 2, 3, 15
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, $0F
	NOTE C#, $0C
	SND_END

Snd20_Sfx2:
	ENVELOPE $01
	VOICE $04, 9, 0, 0, 0
	OCTAVE 3
	ATTEN 5
	PAN $0F
	FLAGS 2
	REST 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	FLAGS 0
	PAN $FF
	RELEASE 0, $0F
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, $0A
	SND_END

Snd20_Sfx1:
	PAN $0F
	FLAGS 2
	VOICE $04, 12, 8, 15, 0
	OCTAVE 2
	ATTEN 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	PAN $FF
	FLAGS 0
	RELEASE $0F, 8
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 0, $0F
	NOTE A_, $0C
	SND_END

Snd21_Sfx1:
	VOICE $02, 15, 8, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 9
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd22_Sfx1:
	VOICE $04, 15, 8, 8, 13
	OCTAVE 5
	NOTE E_, 1
	NOTE G_, 4
	REST 1
	ATTEN $0A
	NOTE E_, 1
	NOTE G_, 4
	SND_END

Snd23_Sfx1:
	VOICE $01, 15, 8, 8, 13
	OCTAVE 5
	NOTE B_, 1
	NOTE D_, 1
	ATTEN 8
	NOTE B_, 1
	NOTE C_, 1
	SND_END

Snd24_Sfx1:
	TRANSPOSE_UP 6
	VOICE $03, 15, 8, 15, 0
	OCTAVE 5
	NOTE E_, 5
	ATTEN $0A
	NOTE E_, 5
	SND_END

Snd25_Sfx1:
	VOICE $01, 15, 0, 0, 15
	OCTAVE 3
	ATTEN 8
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	TRANSPOSE_DOWN 5
	OCTAVE 6
	ATTEN 5
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE D#, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 5
	NOTE C#, 2
	ATTEN 6
	NOTE E_, 1
	ATTEN 9
	NOTE D#, 2
	ATTEN $0A
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	SND_END

Snd25_SfxN:
	NVOICE $0E, $C7
	NOISE $51
	NOISE $21
	NVOICE $05, $57
	NOISE $11
	SND_END

Snd26_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE B_, 1
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
	ATTEN $0A
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
	SND_END

Snd27_Sfx1:
	VOICE $04, 15, 0, 15, 0
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
	ATTEN 9
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd28_Ch1:
	VOICE $01, 15, 0, 1, 15
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 6
	NOTE C_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE C#, 2
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd28_Ch2:
	VOICE $01, 2, 8, 1, 15
	OCTAVE 2
	NOTE C_, 3
	NOTE E_, 6
	NOTE C_, 1
	NOTE D#, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE C#, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd29_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_END

Snd29_SfxN:
	NVOICE $05, $5A
	NOISE $71
	NOISE $71
	NOISE $81
	NOISE $81
	SND_END

Snd2A_Sfx1:
	TRANSPOSE_UP 6
	VOICE $01, 15, 8, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	REST 2
	ATTEN 8
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd2B_Sfx1:
	VOICE $04, 15, 8, 15, 0
	OCTAVE 5
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	SND_END

Snd2C_Sfx1:
	SND_SEGNO
	VOICE $01, 15, 0, 15, 0
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT $0D
	SND_END

Snd2D_Sfx1:
	VIBRATO $06, 0, 8
	VOICE $06, 15, 0, 15, 0
	OCTAVE 5
	NOTE D#, $0A
	ATTEN 7
	NOTE D#, 6
	ATTEN 8
	NOTE D#, 6
	SND_END

Snd2D_Sfx2:
	VIBRATO $06, 0, 3
	VOICE $06, 5, 0, 15, 0
	OCTAVE 6
	NOTE D#, $0A
	ATTEN 2
	NOTE D#, 6
	ATTEN 3
	NOTE D#, 6
	SND_END

Snd2E_SfxN:
	NVOICE $01, $F1
	NOISE $51
	SND_END

Snd2F_SfxN:
	SND_SEGNO
	NVOICE $07, $F1
	NOISE $4E
	SND_REPEAT $02
	SND_END

Snd30_SfxN:
	SND_SEGNO
	NVOICE $07, $83
	NOISE $5D
	SND_REPEAT $02
	SND_END

Snd33_SfxN:
	SND_END

Snd31_SfxN:
	SND_SEGNO
	NVOICE $40, $3E
	NOISE $41
	SND_REPEAT $02
	SND_END

Snd32_SfxN:
	NVOICE $03, $39
	NOISE $31
	NOISE $41
	NVOICE $05, $16
	NOISE $31
	SND_END

Snd34_Sfx1:
	VOICE $01, 14, 8, 15, 0
	OCTAVE 2
	NOTE E_, 1
	NOTE A#, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE A#, 1
	SND_END

Snd36_Sfx1:
	VOICE $01, 14, 8, 15, 0
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE B_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	SND_END

Snd35_SfxN:
	NVOICE $15, $78
	NOISE $71
	SND_END

Snd37_Sfx1:
	VOICE $06, 15, 0, 1, 15
	OCTAVE 5
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE C#, 1
	NOTE D_, 4
	ATTEN 9
	NOTE D_, 4
	ATTEN $0A
	NOTE D_, 4
	SND_END

Snd37_Sfx2:
	VOICE $06, 2, 8, 15, 0
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE C#, 1
	NOTE D_, 4
	SND_END

Snd38_Sfx1:
	VOICE $01, 15, 0, 1, 15
	OCTAVE 5
	NOTE B_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE C_, 1
	SND_END

Snd39_Sfx1:
	TRANSPOSE_DOWN 5
	VOICE $01, 15, 0, 15, 0
	OCTAVE 3
	NOTE C_, 4
	ATTEN 1
	NOTE D#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 4
	NOTE A#, 1
	SND_END

Snd3A_Sfx1:
	VOICE $01, 15, 8, 15, 0
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
	NOTE A_, 1
	ATTEN $0A
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_END

Snd3B_SfxN:
	NVOICE $08, $A3
	NOISE $41
	NVOICE $04, $48
	NOISE $41
	SND_END

Snd3C_Sfx1:
	TRANSPOSE_UP 6
	VOICE $03, 15, 8, 15, 0
	OCTAVE 6
	NOTE E_, 1
	REST 1
	LEN_UNIT 1
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT $08
	SND_END

Snd3D_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 3
	NOTE C_, 4
	REST 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 7
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 5
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 3
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE B_, 1
	SND_END

Snd3E_SfxN:
	NVOICE $05, $F3
	NOISE $98
	NOISE $6A
	NVOICE $05, $A8
	NOISE $31
	NOISE $11
	NOISE $31
	NOISE $11
	NOISE $21
	NOISE $11
	SND_END

Snd3F_Sfx1:
	VOICE $02, 15, 8, 15, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd40_Sfx1:
	TRANSPOSE 0, 4
	VOICE $02, 15, 8, 15, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd41_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 8
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_END

Snd42_Sfx1:
	VOICE $01, 12, 0, 15, 0
	ATTEN 9
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 7
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	SND_SEGNO
	ATTEN 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	SND_REPEAT $05
	ATTEN 7
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 9
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_END

Snd43_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	REST 2
	NOTE E_, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE C#, 1
	REST 2
	NOTE E_, 1
	NOTE F_, 1
	SND_END

Snd44_Sfx1:
	VOICE $02, 15, 12, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	LEN_UNIT 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 7
	LEN_UNIT 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN $0A
	LEN_UNIT 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd45_Sfx1:
	VOICE $02, 15, 8, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D#, 1
	SND_END

Snd46_SfxN:
	NVOICE $07, $F8
	NOISE $72
	NOISE $41
	SND_END

Snd47_SfxN:
	NVOICE $05, $71
	NOISE $1F
	NVOICE $04, $F4
	NOISE $11
	NOISE $31
	SND_END
	db $FF, $FF

Snd48_Sfx1:
	VOICE $01, 15, 8, 15, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd48_SfxN:
	NVOICE $09, $C6
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd49_SfxN:
	SND_END

Snd4A_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd1E_Sfx1:
	VOICE $03, 15, 0, 15, 0
	OCTAVE 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 9
	REST 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd4B_Ch1:
	TEMPO $40
	VOICE $05, 8, 4, 1, 15
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 5
	NOTE C_, 2
	ATTEN 4
	OCTAVE 5
	NOTE C_, 2
	SND_END

Snd4B_Ch2:
	DETUNE $01
	VOICE $05, 2, 8, 15, 0
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd4B_Ch3:
	VOICE $05, 2, 2, 4, 15
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 1
	NOTE C_, 2
	SND_END

Snd4E_Ch2:
	VOICE $06, 8, 8, 5, 15
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 6

Snd4F_Ch2:
	TRANSPOSE 0, 0
	VOICE $06, 8, 8, 2, 9
	REST 2
Snd4E_Ch2_586B:
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 4
	OCTAVE 1
	NOTE B_, 4
	SND_REPEAT $02
	OCTAVE 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 4
	REST 4
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 4
	NOTE D#, 4
	SND_REPEAT $04
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 8
	DUTY 8
	FLAGS 2
	PAN $0F
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C_, 1
	FLAGS 0
	PAN $FF
	OCTAVE 1
	NOTE B_, 8
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE B_, 4
	SND_REPEAT $04
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 8
	SND_CALL Snd4E_Ch2_586B
	db $FF

Snd4E_Ch1:
	VIBRATO $06, 0, 0
	VOICE $06, 2, 8, 15, 0
	REST 1
	SND_CALL Snd4E_Ch1_591D

Snd4F_Ch1:
	VOICE $06, 2, 8, 15, 0
	SND_CALL Snd4E_Ch1_5939
	SND_CALL Snd4F_Ch1

Snd4E_Ch3:
	VIBRATO $04, 2, 0
	VOICE $06, 2, 2, 5, 15
	SND_CALL Snd4E_Ch1_591D

Snd4F_Ch3:
	TRANSPOSE_UP 0
	VOICE $06, 2, 4, 5, 15
	SND_CALL Snd4E_Ch1_5939
	SND_CALL Snd4F_Ch3
Snd4E_Ch1_591D:
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 6
	SND_RET
Snd4E_Ch1_5939:
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
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G#, 3
	NOTE E_, 1
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
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 6
	RELEASE $0D, 5
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE G#, 1
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 4
	RELEASE 0, $0F
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 8
	RELEASE $0F, 5
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
	NOTE B_, 6
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
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G#, 3
	NOTE E_, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE G#, 3
	NOTE G#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 6
	SND_RET

Snd4E_Drm:
	DRUM_UNIT $06
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $0C
	DRUM 8, 6

Snd4F_Drm:
	DRUM_UNIT $0C
	DRUM 1, 1
Snd4E_Drm_59C8:
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $F0
	SND_CALL Snd4E_Drm_59C8

Snd50_Ch1:
	VIBRATO $06, 0, 0
	VOICE $04, 1, 8, 15, 0
	OCTAVE 4
	NOTE A_, 4
	NOTE G#, 6
	NOTE G_, 6
	NOTE C_, 2
	NOTE D_, 4
	NOTE E_, 3
Snd50_Ch1_59E4:
	SND_CALL Snd50_Ch1_5A52
	SND_CALL Snd50_Ch1_59E4

Snd50_Ch2:
	VOICE $04, 10, 8, 5, 15
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 4
	ATTEN 0
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 4
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 4
	NOTE E_, 2
Snd50_Ch2_59FC:
	SND_SEGNO
	NOTE F_, 6
	ATTEN 3
	NOTE F_, 4
	ATTEN 0
	NOTE F_, 2
	NOTE C_, 6
	ATTEN 3
	NOTE C_, 4
	ATTEN 0
	NOTE C_, 2
	SND_REPEAT $04
	SND_SEGNO
	NOTE G_, 6
	ATTEN 3
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 2
	NOTE D_, 6
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	NOTE D_, 2
	SND_REPEAT $02
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 4
	ATTEN 0
	NOTE E_, 2
	ATTEN 3
	NOTE E_, $0A
	ATTEN 0
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	SND_CALL Snd50_Ch2_59FC

Snd50_Ch3:
	VIBRATO $04, 0, 0
	VOICE $04, 2, 4, 15, 0
	OCTAVE 4
	NOTE A_, 4
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 4
	ATTEN 0
	NOTE C_, 2
	NOTE D_, 4
	NOTE E_, 2
Snd50_Ch3_5A4C:
	SND_CALL Snd50_Ch1_5A52
	SND_CALL Snd50_Ch3_5A4C
Snd50_Ch1_5A52:
	NOTE G_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE G_, $0C
	NOTE G_, 2
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE F_, $0C
	NOTE F_, 2
	NOTE E_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, $0C
	NOTE E_, 2
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE F_, $0C
	NOTE F_, 2
	NOTE A_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE A_, $0C
	NOTE A_, 2
	NOTE G_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE G_, $0C
	NOTE G_, 2
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 4
	ATTEN 0
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 4
	ATTEN 0
	OCTAVE 5
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 3
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 2
	NOTE C_, $0B
	ATTEN 0
	OCTAVE 4
	SND_RET

Snd50_Drm:
	DRUM_UNIT $04
	DRUM 8, 4
	DRUM 8, 6
	DRUM 8, 6
	DRUM 8, 2
	DRUM 8, 4
	DRUM 8, 2
Snd50_Drm_5AA9:
	SND_SEGNO
	DRUM $0B, 6
	DRUM 8, 4
	DRUM $0B, 2
	SND_REPEAT $03
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 1, 2
	SND_CALL Snd50_Drm_5AA9

Snd51_Ch2:
	TRANSPOSE 0, 0
	VOICE $06, 5, 8, 5, 15
Snd51_Ch2_5ABC:
	SND_CALL Snd51_Ch1_5ADD
	SND_CALL Snd51_Ch2_5ABC

Snd51_Ch1:
	DETUNE $01
	TRANSPOSE 0, $0C
	VOICE $06, 1, 8, 5, 8
	REST 3
Snd51_Ch1_5ACB:
	SND_CALL Snd51_Ch1_5ADD
	SND_CALL Snd51_Ch1_5ACB

Snd51_Ch3:
	TRANSPOSE 0, $0C
	VOICE $06, 2, 4, 5, 15
Snd51_Ch3_5AD7:
	SND_CALL Snd51_Ch1_5ADD
	SND_CALL Snd51_Ch3_5AD7
Snd51_Ch1_5ADD:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE C#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	LEN_UNIT 1
	NOTE A_, 8
	NOTE E_, 8
	OCTAVE 1
	NOTE G#, 8
	LEN_UNIT 6
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	SND_REPEAT $02
	OCTAVE 1
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE E_, 4
	LEN_UNIT 1
	NOTE F_, 8
	NOTE C_, 8
	OCTAVE 1
	NOTE E_, 8
	LEN_UNIT 6
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A#, 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE F_, 4
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	SND_REPEAT $02
	SND_RET

Snd51_Drm:
	DRUM_UNIT $06
	DRUM 1, 4
	DRUM 1, 3
	DRUM 1, 1
	SND_CALL Snd51_Drm

Snd52_Ch2:
	TEMPO $30
	VOICE $04, 10, 8, 0, 0
	OCTAVE 4
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	PAN $0F
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 4
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	PAN $F0
	ATTEN 0
	NOTE E_, 1
	NOTE D#, 1
	PAN $FF
	ATTEN 4
Snd52_Ch2_5B44:
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	PAN $0F
	NOTE E_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	PAN $F0
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	ATTEN 0
	NOTE E_, 1
	NOTE D#, 1
	PAN $FF
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $F0
	ATTEN 0
	NOTE E_, 1
	NOTE D#, 1
	PAN $FF
	ATTEN 4
	NOTE E_, 1
	NOTE D_, 1
	PAN $0F
	ATTEN 0
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE B_, 1
	PAN $F0
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	ATTEN 0
	NOTE E_, 1
	NOTE D#, 1
	PAN $FF
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $F0
	ATTEN 0
	NOTE G_, 1
	NOTE G#, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE G_, 1
	PAN $0F
	ATTEN 0
	NOTE F_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 4
	NOTE D_, 1
	NOTE E_, 1
	PAN $F0
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	PAN $0F
	ATTEN 0
	NOTE A_, 1
	NOTE G#, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	PAN $F0
	ATTEN 0
	NOTE A_, 1
	NOTE G#, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE G_, 1
	PAN $0F
	ATTEN 0
	NOTE F_, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 4
	NOTE D_, 1
	NOTE E_, 1
	PAN $F0
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	PAN $FF
	ATTEN 4
	NOTE A_, 1
	NOTE G#, 1
	PAN $0F
	ATTEN 0
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
	ATTEN 4
	NOTE F_, 1
	NOTE E_, 1
	PAN $F0
	ATTEN 0
	NOTE D#, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 4
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 5
	SND_REPEAT $06
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 2
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 1
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 2
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 4
	SND_CALL Snd52_Ch2_5B44

Snd52_Ch1:
	VOICE $04, 4, 4, 4, 15
	RELEASE 0, 0
	OCTAVE 1
	ATTEN 1
	NOTE E_, 4
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G#, 1
Snd52_Ch1_5C0E:
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G#, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C#, 2
	OCTAVE 3
	ATTEN 1
	NOTE G_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE G_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE A_, 2
	SND_SEGNO
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE B_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	SND_REPEAT $02
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE F#, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G#, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	SND_CALL Snd52_Ch1_5C0E
	db $FF

Snd52_Ch3:
	VOICE $04, 2, 2, 4, 15
	RELEASE 0, 0
	OCTAVE 1
	ATTEN 1
	NOTE E_, 4
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G#, 1
Snd52_Ch3_5CA7:
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G#, 2
	OCTAVE 3
	ATTEN 1
	NOTE D_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE D_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	ATTEN 1
	NOTE C_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C#, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE E_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	OCTAVE 1
	ATTEN 0
	NOTE A_, 2
	OCTAVE 3
	ATTEN 1
	NOTE F_, 2
	SND_SEGNO
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 1
	NOTE B_, 2
	OCTAVE 1
	ATTEN 0
	NOTE B_, 2
	OCTAVE 2
	ATTEN 1
	NOTE B_, 2
	SND_REPEAT $02
	ATTEN 0
	NOTE E_, 2
	ATTEN 1
	NOTE B_, 2
	OCTAVE 1
	ATTEN 0
	NOTE E_, 2
	OCTAVE 2
	ATTEN 1
	NOTE B_, 2
	OCTAVE 1
	ATTEN 0
	NOTE F#, 2
	OCTAVE 2
	ATTEN 1
	NOTE B_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G#, 2
	OCTAVE 2
	ATTEN 1
	NOTE B_, 2
	SND_CALL Snd52_Ch3_5CA7
	db $FF

Snd52_Drm:
	DRUM_UNIT $04
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd52_Drm_5D39:
	SND_SEGNO
	DRUM 1, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 2
	SND_REPEAT $F0
	SND_CALL Snd52_Drm_5D39

Snd53_Ch2:
	VOICE $04, 15, 4, 5, 15
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 8
	TEMPO $30
	VOICE $02, 7, 0, 2, 15
Snd53_Ch1_5D55:
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE E_, 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G#, 2
	SND_REPEAT $02
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE E_, 2
	REST 2
	NOTE C#, 2
	RELEASE $0F, 6
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 8
	SND_END

Snd53_Ch1:
	VIBRATO $06, 0, 0
	VOICE $04, 3, 8, 15, 0
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 5
	TRANSPOSE_DOWN 5
	VOICE $02, 6, 0, 2, 15
	SND_CALL Snd53_Ch1_5D55
	db $FF

Snd53_Ch3:
	VOICE $04, 2, 4, 5, 15
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE E_, 8
	VOICE $02, 2, 8, 4, 15
	OCTAVE 1
	NOTE A_, 6
	NOTE E_, 2
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 2
	REST 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 4
	NOTE F#, 4
	NOTE G#, 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 6
	NOTE A_, 2
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 6
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 6
	NOTE A_, 2
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 6
	NOTE E_, 2
	NOTE B_, 4
	NOTE E_, 4
	SND_REPEAT $02
	OCTAVE 1
	NOTE A_, 6
	NOTE E_, 2
	NOTE E_, 4
	NOTE A_, 4
	REST 2
	NOTE A_, 2
	NOTE E_, 4
	NOTE A_, 8
	SND_END

Snd53_Drm:
	DRUM_UNIT $04
	REST $0C
	DRUM_UNIT $04
	DRUM $0B, 3
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 2
	REST 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT $08
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 1
	SND_END

Snd54_Ch2:
	TEMPO $50
	VOICE $03, 15, 0, 1, 15
	SND_CALL Snd54_Ch1_5E22

Snd54_Ch1:
	VOICE $03, 4, 8, 15, 0
	REST 1
Snd54_Ch1_5E22:
	OCTAVE 3
	NOTE C_, 6
	NOTE D_, 2
	NOTE D#, 4
	OCTAVE 2
	NOTE A#, 4
	SND_SEGNO
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT $08
	NOTE C_, 4
	OCTAVE 1
	NOTE C_, 4
	SND_END

Snd54_Ch3:
	VOICE $03, 4, 6, 15, 0
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 8
	NOTE F#, 8
	RELEASE $0F, 4
	NOTE C_, 4
	NOTE C_, 4
	SND_END

Snd54_Drm:
	SND_END

Snd55_Ch1:
	SND_SEGNO
	SND_CALL Snd55_Ch1_5E92
	SND_REPEAT $03
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	ATTEN 2
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	OCTAVE 2
	NOTE C#, 6
	ATTEN 2
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	OCTAVE 1
	NOTE B_, 6
	ATTEN 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 4
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 2
	ATTEN 1
	REST 2
	NOTE F#, 2
	NOTE F_, 4
	ATTEN 7
	NOTE F_, 2
	ATTEN 1
	OCTAVE 3
	PAN $0F
	FLAGS 2
	NOTE A_, $0C
	OCTAVE 4
	NOTE C#, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	FLAGS 0
	PAN $FF
	ATTEN 4
	NOTE E_, 2
	ATTEN 7
	NOTE E_, 4
	ATTEN 4
	NOTE C#, 2
	ATTEN 7
	NOTE C#, 4
	ATTEN 4
	NOTE D_, 4
	NOTE D_, 2
	ATTEN 7
	NOTE D_, 4
	ATTEN 4
	NOTE C#, $0F
	ATTEN 7
	NOTE C#, 4
	ATTEN 0
	REST 7
	SND_CALL Snd55_Ch2
Snd55_Ch1_5E92:
	VOICE $02, 8, 0, 2, 15
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	ATTEN 2
	NOTE E_, 3
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	OCTAVE 2
	NOTE C#, 6
	ATTEN 2
	NOTE A_, 3
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	OCTAVE 1
	NOTE B_, 6
	OCTAVE 2
	ATTEN 2
	NOTE F#, 3
	ATTEN 6
	NOTE F#, 1
	ATTEN 0
	OCTAVE 3
	NOTE E_, 6
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 6
	SND_RET

Snd55_Ch2:
	SND_CALL Snd55_Ch1_5F08
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 2
	DUTY 0
	ATTEN 2
	NOTE A_, 3
	ATTEN 8
	NOTE A_, 3
	OCTAVE 1
	ATTEN 0
	DUTY 8
	NOTE G_, 6
	OCTAVE 2
	ATTEN 2
	DUTY 0
	NOTE G_, 3
	ATTEN 8
	NOTE G_, 3
	ATTEN 0
	DUTY 8
	OCTAVE 1
	NOTE F#, 6
	DUTY 0
	ATTEN 2
	OCTAVE 2
	NOTE F#, 3
	ATTEN 8
	NOTE F#, 3
	ATTEN 0
	DUTY 8
	OCTAVE 1
	NOTE F_, 6
	DUTY 0
	ATTEN 2
	OCTAVE 2
	NOTE F_, 3
	ATTEN 8
	NOTE F_, 3
	ATTEN 0
	DUTY 8
	OCTAVE 1
	NOTE E_, 6
	OCTAVE 2
	DUTY 0
	ATTEN 2
	NOTE E_, 3
	ATTEN 8
	NOTE E_, 3
	ATTEN 0
	DUTY 8
	OCTAVE 1
	NOTE G#, 6
	DUTY 0
	OCTAVE 2
	ATTEN 2
	NOTE G#, 3
	ATTEN 8
	NOTE G#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 1
	NOTE A_, 6
	NOTE A_, 2
	NOTE E_, 6
	NOTE F#, 6
	NOTE G#, 6
	SND_CALL Snd55_Ch1
	db $FF
Snd55_Ch1_5F08:
	TEMPO $50
	VOICE $02, 9, 8, 2, 15
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 6
	DUTY 0
	OCTAVE 2
	ATTEN 2
	NOTE A_, 3
	ATTEN 7
	NOTE A_, 3
	ATTEN 0
	DUTY 8
	NOTE C#, 6
	OCTAVE 3
	DUTY 0
	ATTEN 2
	NOTE C#, 3
	ATTEN 7
	NOTE C#, 3
	ATTEN 0
	OCTAVE 1
	DUTY 8
	NOTE B_, 6
	OCTAVE 2
	DUTY 0
	ATTEN 2
	NOTE B_, 3
	ATTEN 7
	NOTE B_, 1
	ATTEN 0
	DUTY 8
	NOTE E_, 6
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 6
	SND_REPEAT $04
	SND_RET

Snd55_Ch3:
	VOICE $02, 2, 2, 4, 15
	SND_SEGNO
	ATTEN 1
	OCTAVE 2
	REST 6
	NOTE C#, 3
	ATTEN 2
	NOTE C#, 3
	ATTEN 1
	REST 6
	NOTE E_, 3
	ATTEN 2
	NOTE E_, 3
	ATTEN 1
	REST 6
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 3
	REST $0C
	SND_REPEAT $02
	WAVE 7
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 5
	NOTE E_, 3
	REST 3
	NOTE C#, 3
	ATTEN 2
	NOTE E_, 3
	ATTEN 0
	NOTE E_, 8
	ATTEN 2
	NOTE C#, 2
	ATTEN 0
	NOTE C#, 2
	NOTE D_, 6
	NOTE E_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	NOTE E_, $0B
	ATTEN 2
	NOTE E_, 6
	ATTEN 0
	REST 3
	NOTE C#, 3
	REST 3
	NOTE E_, 8
	ATTEN 2
	NOTE C#, 2
	ATTEN 0
	NOTE C#, 2
	NOTE D_, 6
	NOTE E_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	NOTE E_, $0B
	ATTEN 2
	NOTE E_, 6
	ATTEN 0
	WAVE 2
	OCTAVE 4
	REST 3
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	NOTE C#, 8
	ATTEN 2
	NOTE C#, 2
	OCTAVE 3
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 4
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 4
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE B_, 4
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 4
	ATTEN 0
	NOTE A_, $0F
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	REST 7
	SND_CALL Snd55_Ch3

Snd55_Drm:
	DRUM_UNIT $02
	SND_SEGNO
	DRUM $0B, 6
	DRUM 1, 6
	DRUM $0B, 6
	DRUM 8, 4
	DRUM 2, 6
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM 8, 6
	SND_REPEAT $04
	DRUM $0B, 6
	DRUM 8, 6
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 6
	DRUM $0B, 6
	DRUM 8, 4
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM 8, 6
	DRUM $0B, 6
	DRUM 8, 6
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM 8, 4
	DRUM 8, 2
	SND_CALL Snd55_Drm

Snd56_Ch1:
	TEMPO $20
	VOICE $02, 7, 4, 3, 15
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
Snd56_Ch1_5FE6:
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	RELEASE 8, 3
	NOTE E_, 4
	OCTAVE 4
	RELEASE $0F, 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 4
	NOTE F#, 2
	NOTE E_, 2
	RELEASE 8, 3
	NOTE D_, 4
	RELEASE $0F, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	SND_CALL Snd56_Ch1_5FE6

Snd56_Ch2:
	VOICE $02, 10, 8, 2, 14
	NOTE D_, 7
	ATTEN 9
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
Snd56_Ch2_603F:
	OCTAVE 1
	NOTE G_, 6
	ATTEN 7
	NOTE G_, 2
	ATTEN 0
	NOTE D_, 6
	ATTEN 7
	NOTE D_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G_, 6
	ATTEN 7
	NOTE G_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 6
	ATTEN 7
	NOTE D_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G_, 6
	ATTEN 7
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 6
	ATTEN 7
	NOTE F#, 2
	ATTEN 0
	NOTE E_, 6
	ATTEN 7
	NOTE E_, 2
	ATTEN 0
	NOTE D_, 6
	ATTEN 7
	NOTE D_, 2
	OCTAVE 2
	ATTEN 0
	NOTE C_, 6
	ATTEN 7
	NOTE C_, 2
	ATTEN 0
	OCTAVE 1
	NOTE G_, 6
	ATTEN 7
	NOTE G_, 2
	ATTEN 0
	OCTAVE 2
	NOTE C_, 6
	ATTEN 7
	NOTE C_, 2
	OCTAVE 1
	ATTEN 0
	NOTE G_, 6
	ATTEN 7
	NOTE G_, 2
	ATTEN 0
	OCTAVE 2
	NOTE C_, 6
	ATTEN 7
	NOTE C_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 6
	ATTEN 7
	NOTE A_, 2
	ATTEN 0
	NOTE F#, 6
	ATTEN 7
	NOTE F#, 2
	ATTEN 0
	NOTE D_, 6
	ATTEN 7
	NOTE D_, 2
	ATTEN 0
	SND_CALL Snd56_Ch2_603F

Snd56_Ch3:
	VOICE $02, 2, 2, 5, 15
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
Snd56_Ch3_6099:
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 8, 5
	NOTE A_, $0F
	REST 1
	RELEASE $0F, 5
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 8, 5
	NOTE F#, $0F
	REST 1
	RELEASE $0F, 5
	SND_CALL Snd56_Ch3_6099

Snd56_Drm:
	DRUM_UNIT $02
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
Snd56_Drm_60DF:
	SND_SEGNO
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 2
	DRUM $0B, 2
	SND_REPEAT $F0
	SND_CALL Snd56_Drm_60DF

Snd57_Ch2:
	VOICE $03, 8, 0, 0, 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 6
	NOTE A_, 2
	ATTEN 0
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, $0C
	SND_END

Snd57_Ch1:
	VOICE $03, 8, 0, 0, 0
	OCTAVE 1
	NOTE F_, $0E
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE A_, $0C
	SND_END

Snd57_Ch3:
	VOICE $03, 2, 2, 0, 0
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, $0C
	SND_END

Snd57_Drm:
	SND_END

Snd58_Ch1:
	DETUNE $01
	VOICE $02, 3, 8, 0, 0
	REST 1
	SND_CALL Snd58_Ch1_6203
	ATTEN 1
	SND_CALL Snd58_Ch1_621D
	SND_CALL Snd58_Ch1_623E
	SND_CALL Snd58_Ch1_6257
	SND_CALL Snd58_Ch1_621D
	SND_CALL Snd58_Ch1_6263
	SND_END

Snd58_Ch2:
	VOICE $02, 10, 8, 6, 15
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 4
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE G_, 4
	ATTEN 5
	NOTE G_, 8
	ATTEN 0
	OCTAVE 2
	ATTEN 3
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
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 0
	SND_CALL Snd58_Ch2_6179
	SND_CALL Snd58_Ch2_6184
	SND_CALL Snd58_Ch2_6184
	SND_CALL Snd58_Ch2_618E
	SND_CALL Snd58_Ch2_6179
	SND_CALL Snd58_Ch2_6184
	SND_CALL Snd58_Ch2_61A0
	SND_END
Snd58_Ch2_6179:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 6
	NOTE G_, 6
	OCTAVE 1
	NOTE G_, 6
	OCTAVE 2
	NOTE G_, 6
	SND_REPEAT $02
	SND_RET
Snd58_Ch2_6184:
	SND_SEGNO
	NOTE D_, 6
	NOTE G_, 6
	OCTAVE 1
	NOTE G_, 6
	OCTAVE 2
	NOTE G_, 6
	SND_REPEAT $02
	SND_RET
Snd58_Ch2_618E:
	NOTE E_, 6
	OCTAVE 3
	NOTE E_, 6
	OCTAVE 2
	NOTE D#, 6
	OCTAVE 3
	NOTE D#, 6
	OCTAVE 2
	NOTE D_, 6
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 6
	NOTE G_, 2
	NOTE D_, 4
	OCTAVE 1
	NOTE G_, 2
	SND_RET
Snd58_Ch2_61A0:
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 6
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 1
	NOTE G_, 6
	OCTAVE 2
	NOTE G_, 6
	SND_REPEAT $02
	NOTE C_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 1
	NOTE B_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 1
	NOTE A_, 6
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 1
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 6
	OCTAVE 2
	NOTE F_, 6
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 3
	NOTE C_, 6
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 6
	OCTAVE 2
	NOTE F_, 6
	SND_REPEAT $02
	NOTE D_, 4
	NOTE D_, 2
	NOTE A_, 4
	OCTAVE 1
	NOTE G_, 6
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 6
	NOTE A_, 6
	NOTE G_, 6
	OCTAVE 2
	NOTE C_, $0A
	OCTAVE 1
	NOTE C_, 2
	SND_RET

Snd58_Ch3:
	VIBRATO $04, 0, 0
	VOICE $02, 2, 2, 0, 0
	SND_CALL Snd58_Ch1_6203
	SND_CALL Snd58_Ch1_621D
	SND_CALL Snd58_Ch1_623E
	WAVE 8
	SND_CALL Snd58_Ch1_6257
	WAVE 2
	SND_CALL Snd58_Ch1_621D
	SND_CALL Snd58_Ch1_6263
	SND_END
Snd58_Ch1_6203:
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 2
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 4
	ATTEN 0
	OCTAVE 4
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 4
	ATTEN 0
	NOTE G_, 4
	ATTEN 2
	NOTE G_, 8
	ATTEN 0
	OCTAVE 3
	NOTE G_, 4
	ATTEN 2
	NOTE G_, 8
	ATTEN 0
	SND_RET
Snd58_Ch1_621D:
	OCTAVE 3
	NOTE G_, 4
	NOTE D#, 2
	NOTE E_, 4
	NOTE A_, 2
	NOTE D#, 4
	NOTE E_, 2
	NOTE B_, 4
	NOTE D#, 2
	NOTE E_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 2
	NOTE C_, 6
	OCTAVE 3
	NOTE A#, 4
	NOTE B_, 2
	NOTE A#, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE A_, 4
	NOTE G_, $0B
	NOTE G_, $0F
	SND_RET
Snd58_Ch1_623E:
	OCTAVE 3
	NOTE F_, 4
	NOTE C#, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE C#, 4
	NOTE D_, 2
	NOTE A_, 4
	NOTE C#, 2
	NOTE D_, 4
	NOTE B_, 2
	NOTE C#, 4
	NOTE D_, 2
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 4
	NOTE D_, 2
	OCTAVE 3
	LEN_UNIT 4
	NOTE G_, $0C
	LEN_UNIT 2
	SND_RET
Snd58_Ch1_6257:
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	REST 4
	OCTAVE 4
	NOTE A_, 2
	NOTE A#, 2
	REST 4
	NOTE B_, 2
	REST 4
	SND_RET
Snd58_Ch1_6263:
	OCTAVE 3
	NOTE F#, 4
	NOTE G_, 2
	NOTE F#, 4
	NOTE G_, 2
	NOTE A#, 4
	NOTE B_, 2
	NOTE A#, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	NOTE D_, 2
	NOTE C#, 4
	NOTE D_, 2
	NOTE F_, 4
	NOTE F#, 2
	NOTE G_, 4
	OCTAVE 5
	NOTE E_, 2
	LEN_UNIT 8
	NOTE E_, $0C
	LEN_UNIT 2
	REST 6
	OCTAVE 3
	NOTE A_, 3
	REST 3
	OCTAVE 4
	NOTE C_, 3
	REST 3
	OCTAVE 3
	NOTE A_, 3
	REST 3
	OCTAVE 4
	NOTE D#, $0A
	NOTE D_, 8
	NOTE C_, 6
	NOTE D#, 1
	NOTE E_, 5
	OCTAVE 3
	NOTE G_, 6
	NOTE B_, 4
	NOTE A#, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE G_, $0C
	NOTE G_, $0C
	REST 6
	OCTAVE 3
	NOTE A_, 3
	REST 3
	OCTAVE 4
	NOTE C_, 3
	REST 3
	OCTAVE 3
	NOTE A_, 3
	REST 3
	OCTAVE 4
	NOTE E_, 4
	NOTE F_, 2
	NOTE F#, 4
	NOTE G_, 2
	REST 4
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 2
	LEN_UNIT 6
	NOTE C_, $0C
	LEN_UNIT 2
	SND_RET

Snd58_Drm:
	DRUM_UNIT $02
	DRUM $0B, 4
	DRUM $0B, 6
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM $0B, 6
	DRUM $0B, $0C
	DRUM 3, $0C
	SND_SEGNO
	DRUM $0B, 6
	DRUM 1, 6
	DRUM 8, 6
	DRUM 1, 4
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 1, 4
	DRUM $0B, 2
	DRUM 8, 6
	DRUM 1, 4
	DRUM $0B, 2
	SND_REPEAT $08
	SND_SEGNO
	DRUM $0B, 6
	DRUM 1, 6
	DRUM 8, 6
	DRUM 1, 6
	SND_REPEAT $05
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 1, 4
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 2
	DRUM 1, 4
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 6
	DRUM 8, 6
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, $0A
	DRUM 3, 2
	SND_END

Snd59_Ch2:
	VIBRATO $05, 0, 3
	VOICE $08, 8, 8, 15, 0
	SND_CALL Snd59_Ch1_62F8
	SND_CALL Snd59_Ch2_630D

Snd59_Ch1:
	VIBRATO $06, 0, 0
	VOICE $08, 2, 8, 15, 0
	REST 1
	SND_CALL Snd59_Ch1_62F8
	SND_CALL Snd59_Ch1_632B
Snd59_Ch1_62F8:
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	SND_RET
Snd59_Ch2_630D:
	VOICE $08, 8, 4, 2, 15
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch1_6360
	SND_CALL Snd59_Ch2_630D
Snd59_Ch1_632B:
	VOICE $08, 2, 8, 15, 0
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch1_6349
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch1_6360
	SND_CALL Snd59_Ch1_632B
Snd59_Ch1_6349:
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	SND_REPEAT $02
	SND_RET
Snd59_Ch1_6360:
	TRANSPOSE_UP 0
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 8
	NOTE C#, 2
	RELEASE $0D, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	OCTAVE 3
	NOTE F_, 8
	NOTE E_, 2
	RELEASE $0D, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	NOTE A_, 8
	NOTE G#, 8
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 8
	SND_RET

Snd59_Ch3:
	VOICE $08, 2, 2, 5, 15
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
Snd59_Ch3_63A4:
	TRANSPOSE_UP 0
	VOICE $08, 2, 2, 5, 15
	SND_CALL Snd59_Ch3_63C4
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch3_63C4
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch3_63C4
	TRANSPOSE_UP 2
	SND_CALL Snd59_Ch3_63C4
	TRANSPOSE_UP 0
	SND_CALL Snd59_Ch3_63DD
	SND_CALL Snd59_Ch3_63A4
Snd59_Ch3_63C4:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT $02
	SND_RET
Snd59_Ch3_63DD:
	TRANSPOSE_UP 0
	RELEASE 0, $0F
	OCTAVE 2
	NOTE A#, 8
	NOTE A_, 2
	RELEASE $0D, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 8
	NOTE C#, 2
	RELEASE $0D, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	NOTE F_, 8
	NOTE E_, 8
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE D#, 1
	SND_RET

Snd59_Drm:
	DRUM_UNIT $08
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd59_Drm_6422:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM 1, 1
	DRUM 8, 2
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $F0
	SND_CALL Snd59_Drm_6422

Snd5A_Ch1:
	VOICE $04, 5, 4, 4, 15
	SND_CALL Snd5A_Ch1_6582
Snd5A_Ch1_6435:
	SND_SEGNO
	DUTY 8
	OCTAVE 5
	SND_CALL Snd5A_Ch1_6468
	DUTY 4
	RELEASE 0, 0
	DETUNE $01
	SND_CALL Snd5A_Ch1_659C
	RELEASE $0F, 4
	DETUNE $00
	OCTAVE 5
	DUTY 8
	SND_REPEAT $02
	SND_CALL Snd5A_Ch1_647F
	NOTE C_, 6
	NOTE C_, 6
	OCTAVE 2
	NOTE B_, 6
	NOTE B_, 6
	NOTE A#, 6
	NOTE A#, 6
	NOTE G#, 6
	NOTE G#, 6
	SND_CALL Snd5A_Ch1_647F
	NOTE G_, 6
	NOTE G_, 6
	NOTE F_, 6
	NOTE F_, 6
	NOTE D#, 6
	NOTE D#, 6
	NOTE C_, 6
	NOTE C_, 6
	SND_CALL Snd5A_Ch1_6435
Snd5A_Ch1_6468:
	REST 4
	NOTE F_, 2
	NOTE G_, 2
	REST 4
	NOTE G#, 2
	REST 4
	NOTE A#, 2
	REST 4
	NOTE B_, 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 4
	NOTE F_, 2
	NOTE G#, 4
	NOTE A#, 2
	REST 4
	NOTE G#, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE C_, 8
	OCTAVE 3
	SND_RET
Snd5A_Ch1_647F:
	DUTY 0
	OCTAVE 3
	NOTE G_, 6
	NOTE G_, 6
	NOTE F_, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE C_, 6
	SND_RET

Snd5A_Ch2:
	VOICE $04, 8, 8, 4, 15
	SND_CALL Snd5A_Ch1_6582
Snd5A_Ch2_6492:
	SND_CALL Snd5A_Ch1_6582
	SND_CALL Snd5A_Ch1_6582
	SND_CALL Snd5A_Ch2_64C4
	NOTE F#, 6
	NOTE F#, 6
	OCTAVE 1
	NOTE F_, 6
	OCTAVE 2
	NOTE F_, 6
	NOTE D#, 6
	NOTE D#, 6
	NOTE C#, 6
	NOTE C#, 6
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	SND_CALL Snd5A_Ch2_64C4
	NOTE F_, 6
	NOTE F_, 6
	OCTAVE 1
	NOTE C_, 6
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 6
	NOTE A#, 6
	NOTE G#, 6
	NOTE G#, 6
	NOTE G_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G#, 2
	SND_CALL Snd5A_Ch2_6492
Snd5A_Ch2_64C4:
	OCTAVE 1
	NOTE A#, 6
	OCTAVE 2
	NOTE A#, 6
	NOTE G#, 6
	NOTE G#, 6
	NOTE G_, 6
	NOTE G_, 6
	SND_RET

Snd5A_Ch3:
	VOICE $04, 2, 8, 7, 15
	SND_SEGNO
	OCTAVE 4
	REST 6
	NOTE F_, 6
	REST 6
	NOTE F_, 6
	REST 6
	NOTE F_, 6
	REST $0C
	SND_REPEAT $02
Snd5A_Ch3_64DC:
	SND_SEGNO
	OCTAVE 3
	SND_CALL Snd5A_Ch1_6468
	RELEASE 0, 0
	WAVE $0D
	SND_CALL Snd5A_Ch1_659C
	WAVE 8
	RELEASE $0F, 7
	SND_REPEAT $02
	SND_CALL Snd5A_Ch3_6534
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	OCTAVE 4
	RELEASE 8, 7
	NOTE E_, 1
	NOTE F_, $0F
	REST 2
	WAVE 7
	OCTAVE 4
	NOTE G#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	WAVE 8
	OCTAVE 3
	RELEASE $0F, 7
	SND_CALL Snd5A_Ch3_6534
	NOTE F_, 2
	NOTE G#, 4
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, $0E
	OCTAVE 4
	WAVE 7
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	WAVE 8
	SND_CALL Snd5A_Ch3_64DC
Snd5A_Ch3_6534:
	NOTE A#, 6
	NOTE A#, 6
	NOTE G#, 4
	NOTE A#, 2
	NOTE G#, 4
	NOTE G_, 6
	NOTE G_, 2
	NOTE G#, 4
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	SND_RET

Snd5A_Drm:
	DRUM_UNIT $04
	SND_CALL Snd5A_Drm_656D
Snd5A_Drm_6546:
	SND_CALL Snd5A_Drm_656D
	SND_CALL Snd5A_Drm_656D
	SND_SEGNO
	DRUM 3, 6
	DRUM 3, 2
	REST 2
	DRUM 3, 2
	SND_REPEAT $07
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	SND_SEGNO
	DRUM 3, 6
	DRUM 3, 2
	REST 2
	DRUM 3, 2
	SND_REPEAT $06
	DRUM 3, 6
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_CALL Snd5A_Drm_6546
Snd5A_Drm_656D:
	SND_SEGNO
	DRUM $0B, 6
	DRUM 8, 4
	DRUM $0B, 2
	SND_REPEAT $03
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 6, 2
	SND_SEGNO
	DRUM $0B, 6
	DRUM 8, 4
	DRUM $0B, 2
	SND_REPEAT $03
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 6, 2
	SND_RET
Snd5A_Ch1_6582:
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 6
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 1
	NOTE F_, 2
	NOTE D#, 6
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 1
	NOTE D#, 2
	NOTE C#, 6
	OCTAVE 2
	NOTE F_, 4
	NOTE C#, 2
	NOTE C_, 2
	REST 2
	OCTAVE 1
	NOTE A#, 2
	NOTE G#, 2
	REST 2
	NOTE G_, 2
	SND_REPEAT $02
	SND_RET
Snd5A_Ch1_659C:
	NOTE F_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE A#, 2
	SND_RET

Snd5B_Ch3:
	VOICE $02, 2, 3, 0, 0
	TEMPO $30
	REST 8
	REST 8
Snd5B_Ch3_65B5:
	TRANSPOSE 0, 0
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 0, 5
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 0, 0
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 0, 5
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 1, 0
	SND_CALL Snd5B_Ch1_6668
	SND_CALL Snd5B_Ch3_65B5

Snd5B_Ch1:
	VOICE $02, 11, 0, 0, 0
	REST 8
	REST 8
Snd5B_Ch1_65D7:
	TRANSPOSE 9, 5
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 9, 0
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 9, 5
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 9, 0
	SND_CALL Snd5B_Ch1_664B
	TRANSPOSE 8, 5
	SND_CALL Snd5B_Ch1_6668
	SND_CALL Snd5B_Ch1_65D7

Snd5B_Ch2:
	VOICE $02, 12, 8, 1, 15
	REST 8
	REST 8
Snd5B_Ch2_65F9:
	SND_CALL Snd5B_Ch2_6619
	TRANSPOSE 0, 5
	SND_CALL Snd5B_Ch2_6619
	TRANSPOSE 0, 0
	SND_CALL Snd5B_Ch2_6619
	TRANSPOSE 0, 5
	SND_CALL Snd5B_Ch2_6619
	RELEASE 0, 0
	TRANSPOSE 9, 0
	SND_CALL Snd5B_Ch1_6668
	TRANSPOSE 0, 0
	RELEASE $0F, 1
	SND_CALL Snd5B_Ch2_65F9
Snd5B_Ch2_6619:
	OCTAVE 1
	SND_SEGNO
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	SND_REPEAT $04
	SND_RET

Snd5B_Drm:
	DRUM_UNIT $02
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
Snd5B_Drm_6633:
	SND_SEGNO
	SND_CALL Snd5B_Drm_6645
	SND_REPEAT $20
	SND_SEGNO
	DRUM 8, 6
	SND_REPEAT $0B
	DRUM 1, 2
	SND_SEGNO
	DRUM 8, 2
	SND_REPEAT $0B
	SND_CALL Snd5B_Drm_6633
Snd5B_Drm_6645:
	DRUM 1, 4
	DRUM 8, 4
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 4
	SND_RET
Snd5B_Ch1_664B:
	SND_SEGNO
	OCTAVE 4
	REST 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE F_, 2
	REST $0C
	REST $0C
	SND_REPEAT $02
	SND_RET
Snd5B_Ch1_6668:
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 6
	NOTE A#, 6
	NOTE B_, 6
	NOTE A#, 6
	NOTE G#, 6
	NOTE A#, 6
	NOTE G#, 6
	NOTE F_, 6
	NOTE G#, 6
	NOTE A#, 6
	NOTE G#, $0C
	NOTE G#, $0C
	SND_RET

Snd5C_Ch2:
	PAN $0F
	VOICE $04, 9, 0, 2, 15
	OCTAVE 3
	ATTEN 4
	NOTE A_, 6
	ATTEN 0
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 8
	ATTEN 0
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 6
	ATTEN 0
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 4
	NOTE G#, $0C
	ATTEN 0
	SND_CALL Snd5C_Ch2

Snd5C_Ch1:
	PAN $F0
	VOICE $04, 9, 0, 2, 15
	OCTAVE 3
	ATTEN 4
	NOTE F_, 6
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 8
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 6
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 4
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, $0C
	ATTEN 0
	SND_CALL Snd5C_Ch1

Snd5C_Ch3:
	VOICE $04, 2, 2, 6, 15
	OCTAVE 2
	NOTE D_, 6
	NOTE F_, 6
	NOTE E_, 6
	OCTAVE 1
	NOTE A#, 6
	NOTE A_, 6
	OCTAVE 2
	NOTE D_, 6
	NOTE F_, 6
	NOTE A_, 4
	NOTE G#, 2
	NOTE G_, 6
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 6
	NOTE G_, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE F_, 6
	NOTE G_, 6
	SND_CALL Snd5C_Ch3

Snd5C_Drm:
	DRUM_UNIT $04
	DRUM $0B, 6
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 6
	DRUM $0B, 6
	SND_CALL Snd5C_Drm

Snd5D_Ch1:
	VOICE $04, 10, 8, 1, 12
	ATTEN 0
	PAN $0F
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	RELEASE 7, 1
	NOTE F_, 8
	RELEASE $0C, 1
	NOTE E_, 4
	NOTE C_, 4
	RELEASE 7, 1
	NOTE E_, 8
	RELEASE $0C, 1
	NOTE D#, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	RELEASE 7, 1
	NOTE D#, 8
	RELEASE $0C, 1
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	RELEASE 7, 1
	NOTE G#, 4
	ATTEN 7
	PAN $FF
	RELEASE 0, 0
	OCTAVE 4
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	PAN $0F
	RELEASE $0C, 1
	FLAGS 2
	DUTY 4
	OCTAVE 3
	REST 5
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 8
	NOTE G#, 4
	ATTEN 6
	NOTE A_, 4
	NOTE F#, 4
	NOTE A_, 4
	ATTEN 8
	NOTE A_, 4
	ATTEN 6
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 8
	NOTE G#, 4
	ATTEN 6
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 8
	NOTE G#, 4
	ATTEN 6
	NOTE A_, 4
	NOTE F#, 4
	NOTE A_, 3
	RELEASE 7, 1
	ATTEN 4
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	FLAGS 0
	PAN $FF
	ATTEN 5
	NOTE G#, 8
	DUTY 8
	VIBRATO $04, 1, 3
	OCTAVE 2
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 6
	ATTEN 4
	PAN $0F
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	PAN $F0
	NOTE B_, 4
	NOTE F#, 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 6
	PAN $FF
	ATTEN 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C#, 4
	NOTE F_, 1
	NOTE F#, 3
	NOTE F_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 3
	NOTE C#, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	PAN $F0
	ATTEN 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 4
	PAN $FF
	ATTEN 5
	OCTAVE 2
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 6
	ATTEN 4
	PAN $F0
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 6
	OCTAVE 2
	PAN $0F
	NOTE B_, 4
	NOTE F#, 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 6
	PAN $FF
	ATTEN 5
	NOTE G#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE C#, 4
	NOTE E_, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 2
	PAN $0F
	OCTAVE 4
	ATTEN 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 4
	ATTEN 5
	PAN $FF
	VIBRATO_OFF
	SND_CALL Snd5D_Ch1

Snd5D_Ch2:
	VOICE $04, 10, 8, 1, 12
	ATTEN 0
	PAN $F0
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	RELEASE 7, 1
	NOTE F_, 8
	RELEASE $0C, 1
	NOTE E_, 4
	NOTE C_, 4
	RELEASE 7, 1
	NOTE E_, 8
	RELEASE $0C, 1
	NOTE D#, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	RELEASE 7, 1
	NOTE D#, 8
	RELEASE $0C, 1
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	RELEASE 7, 1
	NOTE G#, $0F
	REST 1
	RELEASE $0C, 1
	PAN $FF
	DUTY 0
	OCTAVE 3
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 5
	NOTE G#, 4
	ATTEN 0
	NOTE A_, 4
	NOTE F#, 4
	NOTE A_, 4
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 5
	NOTE G#, 4
	ATTEN 0
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE G#, 4
	ATTEN 5
	NOTE G#, 4
	ATTEN 0
	NOTE A_, 4
	NOTE F#, 4
	NOTE A_, 4
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	RELEASE 7, 1
	NOTE G#, $0F
	REST 1
	DUTY 8
	VIBRATO $04, 1, 3
	ATTEN 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 6
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 6
	NOTE D#, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 6
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE A_, 1
	NOTE A#, 3
	NOTE G#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, $0E
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 6
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 6
	NOTE D#, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 6
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE E_, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, $0E
	ATTEN 5
	VIBRATO_OFF
	SND_CALL Snd5D_Ch2

Snd5D_Ch3:
	VOICE $04, 2, 8, 2, 12
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	RELEASE 7, 2
	NOTE F_, 8
	RELEASE $0C, 2
	NOTE E_, 4
	NOTE C_, 4
	RELEASE 7, 2
	NOTE E_, 8
	RELEASE $0C, 2
	NOTE D#, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	RELEASE 7, 2
	NOTE D#, 8
	RELEASE $0C, 2
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE F_, 4
	RELEASE 7, 4
	NOTE G#, $0C
	RELEASE $0C, 3
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	OCTAVE 2
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	OCTAVE 2
	NOTE F#, 4
	ATTEN 2
	NOTE F#, 4
	ATTEN 0
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	OCTAVE 2
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	OCTAVE 2
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 0
	OCTAVE 2
	NOTE F#, 4
	ATTEN 2
	NOTE F#, 4
	ATTEN 0
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	NOTE C#, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	NOTE C_, 4
	OCTAVE 1
	NOTE F_, 4
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 4
	OCTAVE 5
	RELEASE $0F, 4
	WAVE 4
	RELEASE $0C, 3
	NOTE A_, 1
	NOTE A#, 3
	WAVE 8
	OCTAVE 1
	NOTE A#, 8
	NOTE F_, 4
	RELEASE $0F, 4
	WAVE 4
	OCTAVE 5
	NOTE A_, 1
	NOTE A#, 3
	OCTAVE 1
	WAVE 8
	RELEASE $0C, 3
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE G#, 8
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 1
	NOTE G#, 8
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 1
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 4
	OCTAVE 5
	RELEASE $0F, 4
	WAVE 4
	NOTE A_, 1
	NOTE A#, 3
	WAVE 8
	RELEASE $0C, 3
	OCTAVE 1
	NOTE A#, 8
	NOTE F_, 4
	WAVE 4
	RELEASE $0F, 4
	OCTAVE 5
	NOTE A_, 1
	NOTE A#, 3
	WAVE 8
	RELEASE $0C, 3
	OCTAVE 1
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 1
	NOTE G#, 8
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 1
	NOTE G#, 8
	OCTAVE 2
	NOTE A_, 8
	NOTE E_, 8
	NOTE F_, 4
	NOTE D#, 4
	NOTE C#, 4
	NOTE C_, 4
	SND_CALL Snd5D_Ch3

Snd5D_Drm:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM $0B, 4
	SND_REPEAT $0F
	DRUM 6, 2
	DRUM 1, 1
	DRUM 1, 1
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT $08
	SND_SEGNO
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $10
	SND_CALL Snd5D_Drm

Snd5E_Ch3:
	VIBRATO $05, 0, 0
	TEMPO $30
	VOICE $08, 2, 8, 4, 10
	REST 8
Snd5E_Ch3_69AF:
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_69FB
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_6A17
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch3_69AF

Snd5E_Ch1:
	DETUNE $01
	VOICE $08, 2, 8, 15, 0
	REST 9
Snd5E_Ch1_69CB:
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_69FB
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_6A17
	SND_CALL Snd5E_Ch1_69E0
	SND_CALL Snd5E_Ch1_69CB
Snd5E_Ch1_69E0:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	SND_REPEAT $02
	SND_RET
Snd5E_Ch1_69FB:
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_REPEAT $02
	SND_RET
Snd5E_Ch1_6A17:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	SND_REPEAT $02
	SND_RET

Snd5E_Ch2:
	VOICE $08, 13, 0, 2, 15
	REST 8
Snd5E_Ch2_6A39:
	SND_CALL Snd5E_Ch2_6A56
	SND_CALL Snd5E_Ch2_6A56
	TRANSPOSE_UP 5
	SND_CALL Snd5E_Ch2_6A56
	TRANSPOSE_UP 0
	SND_CALL Snd5E_Ch2_6A56
	TRANSPOSE_UP 2
	SND_CALL Snd5E_Ch2_6A56
	TRANSPOSE_UP 0
	SND_CALL Snd5E_Ch2_6A56
	SND_CALL Snd5E_Ch2_6A39
Snd5E_Ch2_6A56:
	SND_SEGNO
	OCTAVE 2
	ATTEN 9
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 9
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 9
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_REPEAT $02
	SND_RET

Snd5E_Drm:
	DRUM_UNIT $04
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT $08
Snd5E_Drm_6A74:
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $FE
	SND_CALL Snd5E_Drm_6A74

Snd5F_Ch3:
	TEMPO $20
	VIBRATO $04, 0, 0
	VOICE $04, 2, 2, 1, 15
	OCTAVE 4
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
	NOTE C#, 1
	VOICE $08, 2, 2, 15, 0
Snd5F_Ch3_6AA1:
	SND_CALL Snd5F_Ch1_6AA7
	SND_CALL Snd5F_Ch3_6AA1
Snd5F_Ch1_6AA7:
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 3
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 5
	SND_RET

Snd5F_Ch2:
	VOICE $04, 12, 8, 1, 15
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
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
Snd5F_Ch2_6B14:
	VOICE $08, 15, 8, 1, 15
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	SND_REPEAT $02
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT $05
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $04
	OCTAVE 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 5
	SND_CALL Snd5F_Ch2_6B14

Snd5F_Ch1:
	VIBRATO $06, 0, 0
	VOICE $04, 2, 8, 15, 0
	OCTAVE 4
	NOTE E_, 3
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
	NOTE C#, 1
Snd5F_Ch1_6BA4:
	VOICE $08, 2, 8, 15, 0
	SND_CALL Snd5F_Ch1_6AA7
	SND_CALL Snd5F_Ch1_6BA4

Snd5F_Drm:
	DRUM_UNIT $04
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd5F_Drm_6BC0:
	DRUM_UNIT $08
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 2, 1
	SND_CALL Snd5F_Drm_6BC0

Snd60_Ch1:
	TEMPO $10
	DETUNE $02
	VOICE $01, 4, 8, 0, 0
	REST 6
Snd60_Ch1_6BD6:
	SND_CALL Snd60_Ch1_6BE8
	SND_CALL Snd60_Ch1_6BD6

Snd60_Ch2:
	VOICE $01, 10, 4, 0, 0
Snd60_Ch2_6BE0:
	RELEASE $0D, 4
	SND_CALL Snd60_Ch1_6BE8
	SND_CALL Snd60_Ch2_6BE0
Snd60_Ch1_6BE8:
	ATTEN 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE A_, 3
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 3
	NOTE C#, 3
	NOTE D_, $0F
	NOTE D_, $0F
	NOTE D_, $0F
	NOTE D_, $0F
	NOTE D_, 9
	SND_REPEAT $02
	ATTEN 0
	DUTY 0
	PAN $0F
	OCTAVE 1
	NOTE D_, 3
	NOTE C#, 4
	NOTE C_, 8
	NOTE C_, 8
	PAN $F0
	OCTAVE 2
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 8
	NOTE C_, 8
	PAN $0F
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 8
	NOTE C_, 8
	PAN $FF
	OCTAVE 2
	NOTE D_, 8
	NOTE E_, 4
	NOTE F_, 8
	NOTE F#, 4
	SND_SEGNO
	NOTE G_, 6
	ATTEN 3
	NOTE G_, 6
	ATTEN 0
	NOTE D_, 6
	ATTEN 3
	NOTE D_, 6
	ATTEN 0
	NOTE F#, 8
	NOTE D_, 4
	ATTEN 3
	NOTE D_, 8
	ATTEN 0
	NOTE D_, 4
	NOTE F_, 8
	ATTEN 3
	NOTE F_, 4
	ATTEN 0
	DUTY 8
	NOTE G_, 8
	OCTAVE 3
	NOTE C_, 4
	ATTEN 3
	NOTE C_, 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 4
	NOTE A_, 8
	ATTEN 3
	NOTE A_, 4
	ATTEN 0
	DUTY 0
	SND_REPEAT $04
	OCTAVE 3
	SND_SEGNO
	NOTE C_, 6
	ATTEN 3
	NOTE C_, 6
	ATTEN 0
	OCTAVE 2
	NOTE G_, 6
	ATTEN 3
	NOTE G_, 6
	ATTEN 0
	NOTE B_, 8
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 8
	ATTEN 0
	NOTE G_, 4
	NOTE A#, 8
	ATTEN 3
	NOTE G_, 4
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE C_, 8
	NOTE F_, 4
	ATTEN 3
	NOTE F_, 8
	ATTEN 0
	NOTE D#, 4
	NOTE D_, 8
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	DUTY 0
	SND_REPEAT $04
	OCTAVE 2
	NOTE F#, 6
	ATTEN 3
	NOTE F#, 6
	ATTEN 0
	NOTE C#, 6
	ATTEN 3
	NOTE C#, 6
	ATTEN 0
	NOTE F_, 8
	NOTE C#, 4
	ATTEN 3
	NOTE C#, 8
	ATTEN 0
	NOTE C#, 4
	NOTE E_, 8
	ATTEN 3
	NOTE E_, 4
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE C#, 8
	NOTE D_, 4
	NOTE D#, 8
	NOTE D_, 4
	NOTE C#, 8
	ATTEN 3
	NOTE C#, 4
	ATTEN 0
	DUTY 0
	OCTAVE 2
	NOTE G#, 6
	ATTEN 3
	NOTE G#, 6
	ATTEN 0
	NOTE D#, 6
	ATTEN 3
	NOTE D#, 6
	ATTEN 0
	NOTE G_, 8
	NOTE D#, 4
	ATTEN 3
	NOTE D#, 8
	ATTEN 0
	NOTE D#, 4
	NOTE F#, 8
	ATTEN 3
	NOTE F#, 4
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE D#, 8
	NOTE E_, 4
	NOTE F_, 8
	NOTE E_, 4
	NOTE D#, 8
	ATTEN 3
	NOTE D#, 4
	ATTEN 0
	DUTY 0
	OCTAVE 2
	NOTE A#, 6
	ATTEN 3
	NOTE A#, 6
	ATTEN 0
	NOTE F_, 6
	ATTEN 3
	NOTE F_, 6
	ATTEN 0
	NOTE A_, 8
	NOTE F_, 4
	ATTEN 3
	NOTE F_, 8
	ATTEN 0
	NOTE F_, 4
	NOTE G#, 8
	ATTEN 3
	NOTE G#, 4
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE F_, 8
	NOTE F#, 4
	NOTE G_, 8
	NOTE F#, 4
	NOTE F_, 8
	ATTEN 3
	NOTE F_, 4
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE C_, 6
	ATTEN 3
	NOTE C_, 6
	ATTEN 0
	OCTAVE 2
	NOTE G_, 6
	ATTEN 3
	NOTE G_, 6
	ATTEN 0
	NOTE B_, 8
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 8
	ATTEN 0
	NOTE G_, 4
	NOTE A#, 8
	ATTEN 3
	NOTE A#, 4
	ATTEN 0
	OCTAVE 2
	NOTE D_, 8
	NOTE C#, 4
	NOTE C_, 8
	OCTAVE 1
	NOTE A#, 4
	NOTE A_, 8
	NOTE G#, 4
	SND_RET

Snd60_Ch3:
	VOICE $01, 2, 2, 5, 15
	SND_SEGNO
	OCTAVE 1
	NOTE G_, $0C
	NOTE A#, $0C
	NOTE A_, $0C
	OCTAVE 2
	NOTE C_, $0C
	OCTAVE 1
	NOTE G_, $0C
	NOTE A#, $0C
	NOTE F#, $0C
	NOTE A_, $0C
	SND_REPEAT $07
	TRANSPOSE 0, 5
	SND_SEGNO
	OCTAVE 1
	NOTE G_, $0C
	NOTE A#, $0C
	NOTE A_, $0C
	OCTAVE 2
	NOTE C_, $0C
	OCTAVE 1
	NOTE G_, $0C
	NOTE A#, $0C
	NOTE F#, $0C
	NOTE A_, $0C
	SND_REPEAT $04
	TRANSPOSE 0, 0
	NOTE G_, $0C
	NOTE F#, $0C
	NOTE F_, $0C
	NOTE E_, $0C
	NOTE F_, $0C
	NOTE F#, $0C
	NOTE G_, $0C
	NOTE F#, $0C
	NOTE F_, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	NOTE E_, $0C
	NOTE F_, $0C
	NOTE E_, $0C
	OCTAVE 2
	NOTE D#, $0C
	NOTE D_, $0C
	NOTE C#, $0C
	NOTE C_, $0C
	NOTE C#, $0C
	NOTE D_, $0C
	NOTE D#, $0C
	NOTE D_, $0C
	NOTE C#, $0C
	NOTE C_, $0C
	OCTAVE 1
	NOTE B_, $0C
	NOTE A#, $0C
	OCTAVE 2
	NOTE C_, $0C
	OCTAVE 1
	NOTE A#, $0C
	NOTE A_, $0C
	NOTE G#, $0B
	SND_CALL Snd60_Ch3

Snd60_Drm:
	DRUM_UNIT $03
	DRUM 1, 4
	DRUM 1, 3
	DRUM 1, 1
	SND_CALL Snd60_Drm

Snd61_Ch2:
	VIBRATO $05, 0, 1
	VOICE $08, 8, 8, 8, 10
	SND_CALL Snd61_Ch1_6D5F
Snd61_Ch2_6D49:
	SND_CALL Snd61_Ch1_6D74
	SND_CALL Snd61_Ch2_6D49

Snd61_Ch1:
	DETUNE $01
	VOICE $08, 2, 8, 15, 0
	REST 1
	SND_CALL Snd61_Ch1_6D5F
Snd61_Ch1_6D59:
	SND_CALL Snd61_Ch1_6D74
	SND_CALL Snd61_Ch1_6D59
Snd61_Ch1_6D5F:
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	SND_RET
Snd61_Ch1_6D74:
	LEN_UNIT $10
	OCTAVE 4
	NOTE E_, 9
	NOTE E_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	LEN_UNIT 1
	NOTE A_, 5
	NOTE B_, 6
	NOTE A_, 5
	LEN_UNIT $10
	NOTE G#, 1
	NOTE F_, 1
	NOTE E_, 9
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 9
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, $0E
	NOTE E_, 2
	SND_RET

Snd61_Ch3:
	VOICE $08, 2, 2, 4, 15
	TRANSPOSE_DOWN $0C
	SND_CALL Snd61_Ch1_6D5F
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_CALL Snd61_Ch3

Snd61_Drm:
	DRUM_UNIT $08
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $06
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd61_Drm_6DCD:
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd61_Drm_6DCD

Snd62_Ch2:
	DETUNE $02
	PAN $0F
	VOICE $01, 6, 8, 4, 15
	REST 6
Snd62_Ch2_6DE5:
	SND_CALL Snd62_Ch1_6E04
	SND_CALL Snd62_Ch2_6DE5

Snd62_Ch1:
	DETUNE $01
	PAN $F0
	VOICE $01, 6, 8, 4, 15
	REST $0C
Snd62_Ch1_6DF4:
	SND_CALL Snd62_Ch1_6E04
	SND_CALL Snd62_Ch1_6DF4

Snd62_Ch3:
	VOICE $01, 2, 2, 4, 15
	SND_CALL Snd62_Ch1_6E04
	SND_CALL Snd62_Ch3
Snd62_Ch1_6E04:
	TRANSPOSE_UP 5
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 6
	NOTE A#, 6
	NOTE A_, 6
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE G_, 6
	NOTE A#, 6
	NOTE F#, 6
	NOTE A_, 6
	SND_REPEAT $04
	TRANSPOSE_UP 0
	NOTE G_, 6
	NOTE F#, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE F_, 6
	NOTE F#, 6
	NOTE G_, 6
	NOTE F#, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE D#, 6
	NOTE D_, 6
	NOTE D#, 6
	NOTE E_, 6
	NOTE F_, 6
	NOTE E_, 6
	OCTAVE 2
	NOTE D#, 6
	NOTE D_, 6
	NOTE C#, 6
	NOTE C_, 6
	NOTE C#, 6
	NOTE D_, 6
	NOTE D#, 6
	NOTE D_, 6
	NOTE C#, 6
	NOTE C_, 6
	OCTAVE 1
	NOTE B_, 6
	NOTE A#, 6
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 6
	NOTE A_, 6
	NOTE G#, 6
	SND_RET

Snd62_Drm:
	DRUM_UNIT $02
	SND_SEGNO
	DRUM $0B, 6
	DRUM 8, 6
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 2
	SND_REPEAT $17
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 2
	SND_REPEAT $04
	SND_CALL Snd62_Drm

Snd63_Ch3:
	TEMPO $40
	VIBRATO $04, 0, 0
	VOICE $04, 2, 4, 5, 15
	SND_CALL Snd63_Ch1_6E72
Snd63_Ch3_6E5A:
	WAVE 2
	RELEASE 8, 3
	TRANSPOSE_UP 0
	SND_CALL Snd63_Ch1_6E97
	TRANSPOSE_UP $0C
	SND_CALL Snd63_Ch1_6E97
	WAVE 4
	RELEASE 0, $0F
	SND_CALL Snd63_Ch1_6ECF
	SND_CALL Snd63_Ch3_6E5A
Snd63_Ch1_6E72:
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 4
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 4
	SND_RET
Snd63_Ch1_6E97:
	SND_SEGNO
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	SND_REPEAT $04
	SND_RET

Snd63_Ch1:
	VOICE $04, 4, 8, 4, 8
	REST 1
	SND_CALL Snd63_Ch1_6E72
	REST 2
Snd63_Ch1_6EBD:
	TRANSPOSE_UP 0
	SND_CALL Snd63_Ch1_6E97
	TRANSPOSE_UP $0C
	SND_CALL Snd63_Ch1_6E97
	ATTEN 2
	SND_CALL Snd63_Ch1_6ECF
	ATTEN 0
	SND_CALL Snd63_Ch1_6EBD
Snd63_Ch1_6ECF:
	OCTAVE 3
	NOTE F#, 8
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 6
	NOTE F#, 8
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 5
	OCTAVE 3
	NOTE G#, 3
	NOTE B_, 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE C#, 2
	OCTAVE 3
	NOTE F#, 8
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 6
	NOTE F_, 8
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 8
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 4
	SND_RET

Snd63_Ch2:
	PAN $0F
	FLAGS 2
	VOICE $08, 15, 8, 1, 15
	SND_CALL Snd63_Ch2_6F1F
Snd63_Ch2_6F01:
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F37
	SND_CALL Snd63_Ch2_6F4D
	SND_CALL Snd63_Ch2_6F01
Snd63_Ch2_6F1F:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	SND_REPEAT $07
	NOTE G_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT $06
	NOTE D_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 1
	SND_REPEAT $06
	NOTE E_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $07
	SND_RET
Snd63_Ch2_6F37:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	SND_REPEAT $04
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $04
	SND_SEGNO
	NOTE F_, 1
	SND_REPEAT $04
	SND_SEGNO
	NOTE F_, 1
	SND_REPEAT $02
	SND_SEGNO
	NOTE G_, 1
	SND_REPEAT $02
	SND_RET
Snd63_Ch2_6F4D:
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	SND_REPEAT $04
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	SND_REPEAT $08
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT $08
	SND_RET

Snd63_Drm:
	DRUM_UNIT $04
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $07
	DRUM 8, 4
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $06
	DRUM 8, 4
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $06
	DRUM 8, 4
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT $0E
Snd63_Drm_6F98:
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 1, 2
	SND_CALL Snd63_Drm_6F98
