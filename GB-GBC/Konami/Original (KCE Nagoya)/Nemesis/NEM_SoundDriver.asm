; ==========================================================================
; Nemesis (E) - Konami sound driver (later GB version: fade-out, lockout, follow-ups)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0 $0008 rst $08, $0028 rst $28, $0050 timer vector, $0222 timer ISR,
;        $0334-$037C bank helpers + PlaySoundFar, $0441-$0478 game pause toggle
;   bank 7 $4000-$7404 driver code, tables, sound data (then $FF up to $7FFF)
; Build: rgbasm -Wall -o nem.o NEM_SoundDriver.asm && rgblink -o nem.gb nem.o
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
DEF wIsrLock EQU $C00D
DEF wJoyPressed EQU $C00F
DEF wPause EQU $C013
DEF wCurBank EQU $C018
DEF wSndCallLock EQU $C025
DEF wGameC081 EQU $C081
DEF wTrkSfx1 EQU $C180 ; 37 bytes
DEF wTrkSfx2 EQU $C280 ; 37 bytes
DEF wTrkSfxN EQU $C380 ; 37 bytes
DEF wTrkCh1 EQU $C480 ; 37 bytes
DEF wTrkCh2 EQU $C580 ; 37 bytes
DEF wTrkCh3 EQU $C680 ; 37 bytes
DEF wTrkDrm EQU $C780 ; 37 bytes
DEF wTrackIdx EQU $C1A7
DEF wRegBase EQU $C1A8
DEF wTempo EQU $C1A9
DEF wTempoAcc EQU $C1AA
DEF wTempoSkip EQU $C1AB
DEF wQueuedSnd EQU $C1AC
DEF wNR51 EQU $C1AD
DEF wSweepVal EQU $C1AE
DEF wReqId EQU $C1AF
DEF wReqPrio EQU $C1B0
DEF wRegVal EQU $C1B1
DEF wRegIdx EQU $C1B2
DEF wMusicHold EQU $C1B3
DEF wLockout EQU $C1B4
DEF wFadeTarget EQU $C1B6
DEF wFadeTimer EQU $C1B7
DEF wFadeLevel EQU $C1B8
DEF wShadow EQU $C2A4 ; 20 bytes
DEF wGameCE13 EQU $CE13
DEF rROMB EQU $2000 ; MBC1 bank select

; per-track fields: track n lives at $C180 + n*$100, so H = $C1 + n and L = field
DEF TRK_ID EQU $80
DEF TRK_PRIO EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_LOOPCNT EQU $86
DEF TRK_VIB EQU $87
DEF TRK_TRANSP EQU $88
DEF TRK_ATTEN EQU $89
DEF TRK_VIBOFS EQU $8A
DEF TRK_VIBLOOPCNT EQU $8C
DEF TRK_UNIT EQU $8D
DEF TRK_OCTAVE EQU $8E
DEF TRK_PERIOD EQU $8F
DEF TRK_VOL EQU $91
DEF TRK_DUTY EQU $92
DEF TRK_ENV EQU $93
DEF TRK_GATE EQU $94
DEF TRK_RELTICK EQU $95
DEF TRK_VIBTIMER EQU $96
DEF TRK_VIBRELOAD EQU $97
DEF TRK_CH3TIMER EQU $98
DEF TRK_CH3RELOAD EQU $99
DEF TRK_LEVEL EQU $9B
DEF TRK_SEGNO EQU $9C
DEF TRK_RET EQU $9E
DEF TRK_VIBPTR EQU $A0
DEF TRK_VIBIDX EQU $A2
DEF TRK_VIBLOOPIDX EQU $A3

; track flags (TRK_FLAGS)
DEF TF_RELEASED EQU 0
DEF TF_AUTOPAN EQU 1
DEF TF_VIBNEG EQU 3
DEF TF_FORCE EQU 6
DEF TF_REST EQU 7

; ---------------------------------------------------------------- sound data macros
; Pitch names for NOTE (high nibble of a note byte). C_HI = C of the next octave.
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
; $00-$DF: note. hi = pitch 1-13 (0 = rest), lo = length multiplier (x LEN_UNIT; 0 = x256 -> 0 = 256 ticks)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = index into the drum map (plays that sound id), lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: whole byte -> NR43, length = LEN_UNIT, no retrigger
MACRO NOISE
	db \1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #)
MACRO VOICE
	db $E0, \1, (\3 << 4) | \2, (\5 << 4) | \4
ENDM
; $E0 unit, vol<<4|env (noise SFX track: written straight to NR42 + retrigger)
MACRO NVOICE
	db $E0, \1, (\2 << 4) | \3
ENDM
; $E0 unit (drum track)
MACRO DRUM_UNIT
	db $E0, \1
ENDM
; $E1-$E6: octave 1-6 (pitch index += (n-1)*12)
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: release envelope (NRx2 low nibble) and gate (16ths, $F = release after 1st tick, 0 = never)
MACRO RELEASE
	db $E8, (\2 << 4) | \1
ENDM
; $E9: write NRx0 (sweep on CH1)
MACRO SWEEP
	db $E9, \1
ENDM
; $EA xy: extended command x with 4-bit argument y
MACRO TRANSPOSE_UP
	db $EA, $00 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $10 | \1
ENDM
MACRO VIBRATO
	db $EA, $20 | \1
ENDM
MACRO DUTY
	db $EA, $30 | \1
ENDM
MACRO WAVE
	db $EA, $30 | \1
ENDM
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
MACRO EXT_NOP
	db $EA, $40 | \1
ENDM
; $EB-$ED: no-ops that skip one argument byte
MACRO CMD_EB
	db $EB, \1
ENDM
MACRO CMD_EC
	db $EC, \1
ENDM
MACRO CMD_ED
	db $ED, \1
ENDM
; $ED (Belmont's Revenge): duty step. Each note starts with duty \1 for \2 ticks, then the voice duty
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
ENDM
; $EE: tempo (music skip accumulator increment)
MACRO TEMPO
	db $EE, \1
ENDM
; $EF: NR51 bits for this track's channel (argument is nibble-swapped)
MACRO PAN
	db $EF, \1
ENDM
; $F0-$FA: volume attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
; flow control
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
; vibrato table: delay (ticks, 0 = 256), negate flag (sticky), 11-bit period offset
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | HIGH(\3), LOW(\3)
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

SECTION "rst08", ROM0[$0008]

; rst $08: HL = word at [HL].
LoadHLFromHL:
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

SECTION "rst28", ROM0[$0028]

; rst $28: HL += A.
AddAToHL:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "Timer vector", ROM0[$0050]

TimerVector:
	jp TimerISR

SECTION "Timer ISR", ROM0[$0222]

; Timer interrupt (64 Hz). Re-enables interrupts at once. The tick is skipped
; (lost) while PlaySoundFar runs (wSndCallLock) or the ISR is already inside
; SndUpdate (wIsrLock). Bank 7 is mapped for the update, then wCurBank again.
TimerISR:
	ei
	push hl
	push de
	push bc
	push af
	ld hl, wSndCallLock
	bit 0, [hl]
	jr nz, .l024A
	ld hl, wIsrLock
	bit 0, [hl]
	jr nz, .l024A
	set 0, [hl]
	ld a, $07
	ld [rROMB], a
	call SndUpdate
	ld a, [wCurBank]
	ld [rROMB], a
	ld hl, wIsrLock
	res 0, [hl]
.l024A:
	pop af
	pop bc
	pop de
	pop hl
	reti

SECTION "Bank helpers", ROM0[$0334]

; Bank helpers: SetBankN maps bank N and records it in wCurBank.
SetBank1:
	push af
	ld a, $01

SetBankA:
	di
	ld [rROMB], a
	ld [wCurBank], a
	ei
	pop af
	ret

SetBank2:
	push af
	ld a, $02
	jr SetBankA

SetBank3:
	push af
	ld a, $03
	jr SetBankA

SetBank4:
	push af
	ld a, $04
	jr SetBankA

SetBank5:
	push af
	ld a, $05
	jr SetBankA

SetBank6:
	push af
	ld a, $06
	jr SetBankA

SetBank7:
	push af
	ld a, $07
	jr SetBankA

; PlaySoundFar: the game's entry. A = sound id. Holds wSndCallLock (so a timer
; tick arriving meanwhile is lost), maps bank 7 for PlaySound, then maps bank 1
; (not the caller's bank).
PlaySoundFar:
	push hl
	ld hl, wSndCallLock
	set 0, [hl]
	push de
	push bc
	push af
	ld c, a
	call SetBank7
	ld a, c
	call PlaySound
	call SetBank1
	pop af
	pop bc
	pop de
	ld hl, wSndCallLock
	res 0, [hl]
	pop hl
	ret

SECTION "Pause glue", ROM0[$0441]

; Game pause toggle (START). Not driver code; kept as the only user of
; SndPause / SndUnpause. Pausing plays $2C, the pause jingle.
PauseToggle:
	ld a, [wJoyPressed]
	add a, a
	ld hl, wPause
	jr nc, .l0474
	bit 1, [hl]
	ret nz
	bit 0, [hl]
	jr z, .l045D
	res 0, [hl]
	call SetBank7
	call SndUnpause
	call SetBank1
	ret
.l045D:
	ld a, [wGameCE13]
	and a
	ret nz
	set 0, [hl]
	call SetBank7
	call SndPause
	call SetBank1
	ld a, $2C
	call PlaySoundFar
	pop hl
	ret
.l0474:
	bit 0, [hl]
	ret z
	pop hl
	ret

SECTION "Sound driver", ROMX[$4000], BANK[7]

; GetTrackPage: H = $C1 + wTrackIdx (tracks are $100 apart, fields at L = $80+).
GetTrackPage:
	push af
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	pop af
	ret

CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyBytes
	ret

NegateHL:
	xor a
	sub l
	ld l, a
	ld a, $00
	sbc a, h
	ld h, a
	ret

SwapHLBC:
	push bc
	ld c, l
	ld b, h
	pop hl
	ret

SwapHLDE:
	push de
	ld e, l
	ld d, h
	pop hl
	ret

LoadPtrFromTable:
	add a, a
	rst $28
	rst $08
	ret

; JumpTableInline: called with A = index; jumps to word [ret + 2*A] with HL
; preserved (via $C026/$C027, outside the driver's RAM).
JumpTableInline:
	ld [$C028], a
	ld a, l
	ld [$C026], a
	ld a, h
	ld [$C027], a
	pop hl
	ld a, [$C028]
	add a, a
	rst $28
	rst $08
	push hl
	ld hl, $C026
	rst $08
	ret

; 96 periods (same values as the earlier games).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7

; SndInit: clear $C180-$C800, NR52 = NR51 = $FF, NR50 = $77.
SndInit:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $0080
	ld [hl], $00
	call CopyBytes
	ld hl, rNR52
	ld a, $FF
	ld [hl], a
	dec hl
	ld [hl], a
	dec hl
	ld a, $77
	ld [hl], a
	ret

; FadeTick: while wFadeTarget != 0 (written by the game), wFadeLevel goes up
; by one every 64 ticks. Every new note is wFadeLevel quieter (CH3: half).
; At level 5: targets < 7 stop everything; others start the target sound
; (via wQueuedSnd) and clear the fade. Frozen while paused.
FadeTick:
	ld a, [wPause]
	or a
	ret nz
	ld a, [wFadeTarget]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	ld a, $3F
	and [hl]
	ret nz
	ld hl, wFadeLevel
	inc [hl]
	ld a, $05
	cp [hl]
	ret nz
	ld a, [wFadeTarget]
	ld [wQueuedSnd], a
	cp $07
	jp c, StopAll
	xor a
	ld [hl], a
	ld [wFadeTarget], a
	ret

; TempoTick: wTempoAcc += wTempo; a carry skips the music tracks this tick.
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

; LockoutTick: count wLockout down to 0 (see CheckLockout).
LockoutTick:
	ld hl, wLockout
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

; SndUpdate: one driver tick (64 Hz). Tracks 0-2 (SFX) run every tick, tracks
; 3-6 (music) are skipped on tempo-skip ticks (or while wMusicHold != 0, which
; nothing sets). While wPause != 0 only track 1 runs, and only for sound $2C.
; Finally a sound in wQueuedSnd (fade target or follow-up) is started.
SndUpdate:
	call FadeTick
	call LockoutTick
	call TempoTick
	xor a
.l41C7:
	ld [wTrackIdx], a
	ld a, [wPause]
	or a
	jr z, .l41E0
	ld a, [wTrackIdx]
	cp $01
	jr nz, SndUpdateNext
	ld a, [wTrkSfx2]
	cp $2C
	jr z, SndUpdateRun
	jr SndUpdateDone
.l41E0:
	ld a, [wTrackIdx]
	cp $03
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone
	jr SndUpdateRun

; Unreachable: the old Motocross Maniacs check that moved the skip to track 4
; while the engine sound held track 3.
	ld a, [wTrackIdx]
	cp $04
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone

SndUpdateRun:
	call GetTrackPage
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr z, SndUpdateNext
	call TrackTick

SndUpdateNext:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, SndUpdate.l41C7

SndUpdateDone:
	ld a, [wQueuedSnd]
	or a
	ret z
	ld b, a
	xor a
	ld [wQueuedSnd], a
	ld a, b
	jp PlaySoundSafe

; TrackTick: one tick for track wTrackIdx (H = its page).
TrackTick:
	call GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, .l424D
	ld l, TRK_FLAGS
	res 0, [hl]
	res 7, [hl]
	ld a, [wTrackIdx]
	cp $05
	jp nz, ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp ReadCmds
.l424D:
	ld b, [hl]
	ld l, TRK_RELTICK
	ld a, [hl]
	sub b
	jr c, .l4258
	ld l, TRK_FLAGS
	set 0, [hl]
.l4258:
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
	ld l, TRK_LEN
	ld b, [hl]
	ld l, TRK_RELTICK
	ld a, [hl]
	sub b
	ret nz
	ld l, TRK_LEVEL
	ld c, [hl]
	ld l, TRK_ENV
	ld a, [hl]
	or c
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; Ch3Decay: step the NR32 level code up (1 -> 2 -> 3 -> off) every env ticks
; after the release point. The stored level already contains the attenuation
; and fade, and the attenuation is added again here.
Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l42B6
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
	jr z, .l42B6
	inc a
	and $03
	ld [hl], a
	jr z, .l42B6
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l42B6
	xor a
.l42B6:
	rla
	swap a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

; VibratoTick: advance the vibrato table every TRK_VIBRELOAD ticks.
VibratoTick:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	ret z
	ld l, TRK_VIBTIMER
	dec [hl]
	ret nz
	ld l, TRK_VIBRELOAD
	ld a, [hl]
	ld l, TRK_VIBTIMER
	ld [hl], a
	call VibratoStep
	jp WritePeriod

ReadCmdsNext:
	inc de

; ReadCmds: execute commands until a note/rest (or $FF end).
ReadCmds:
	ld a, [de]
	cp $FB
	jp c, ReadCmdsLow
	inc de
	sub $FB
	push hl
	call JumpTableInline
	dw Cmd_Segno
	dw Cmd_Ret
	dw Cmd_Call
	dw Cmd_Repeat
	dw Cmd_End

Cmd_Segno:
	pop hl
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds

Cmd_Ret:
	pop hl
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds

Cmd_Call:
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

Cmd_Repeat:
	pop hl
	ld a, [de]
	cp $FF
	jr z, .l4324
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l432E
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l4324:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l432E:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	jr ReadCmdsNext

; $FF: end of track. Sounds $37, $21 and $14 queue a follow-up first. NRx2 = 0
; (no trigger). When an SFX on CH1/CH2 ends while music uses the channel,
; restore the music duty and period (CH1 also clears NR10). CH3: NR30 = 0.
Cmd_End:
	pop hl
	call QueueFollowUp
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l4355
	xor a
	ldh [rNR30], a
	ret
.l4355:
	cp $01
	jr z, .l4363
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l4365
.l4363:
	ld h, HIGH(wTrkCh2)
.l4365:
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
	jp WritePeriodBC

; QueueFollowUp: $37 -> $34, $21 -> $36, $14 -> $34 if wGameC081 = 2, else $33.
QueueFollowUp:
	ld l, TRK_ID
	ld a, [hl]
	cp $37
	jr z, .l4393
	cp $21
	jr z, .l4399
	cp $14
	ret nz
	ld a, [wGameC081]
	cp $02
	jr z, .l4393
	ld a, $33
	ld [wQueuedSnd], a
	ret
.l4393:
	ld a, $34
	ld [wQueuedSnd], a
	ret
.l4399:
	ld a, $36
	ld [wQueuedSnd], a
	ret

ReadCmdsLow:
	ld a, [de]
	cp $E0
	jp z, Cmd_Voice
	and $F0
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
	call JumpTableInline
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_EB
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

; $EA xy: extended commands, x = 0..4 (x >= 5 would jump into garbage).
Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	call JumpTableInline
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_Vibrato
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

Ext_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	or a
	jr nz, .l4439
	xor a
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp ReadCmdsNext
.l4439:
	push hl
	dec a
	ld hl, VibratoTable
	call LoadPtrFromTable
	call SwapHLBC
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	xor a
	ld l, TRK_VIBLOOPCNT
	ld [hl], a
	jp ReadCmdsNext

Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp ReadCmdsNext

; $EA 4n: meant to set/clear TF_AUTOPAN, but stores n (| TF_AUTOPAN) into the
; whole flags byte. Not used by this game's data.
Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l446C
	or $02
	jr .l446E
.l446C:
	and $FD
.l446E:
	ld [hl], a
	jp ReadCmdsNext

Cmd_EB:
	pop hl
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

; $EF: NR51 bits (nibble-swapped). Ignored on music CH1 while the CH1 SFX plays.
Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4498
	ld a, [wTrkSfx1]
	or a
	jp nz, ReadCmdsNext
	ld a, [wTrackIdx]
.l4498:
	push hl
	ld hl, PanMaskTable
	rst $28
	ld a, [wNR51]
	and [hl]
	ld c, a
	ld a, [hl]
	cpl
	ld b, a
	ld a, [de]
	swap a
	and b
	or c
	ld [wNR51], a
	ldh [rNR51], a
	pop hl
	jp ReadCmdsNext

; NR51 bits each track keeps when it pans.
PanMaskTable:
	db $EE, $DD, $77, $EE, $DD, $BB, $FF

AutoPan:
	ld a, [wNR51]
	swap a
	ld c, a
	ld a, [wTrackIdx]
	push hl
	ld hl, PanMaskTable
	rst $28
	ld a, [hl]
	cpl
	and c
	ld c, a
	ld a, [wNR51]
	and [hl]
	or c
	ld [wNR51], a
	ldh [rNR51], a
	pop hl
	ret

Cmd_Octave:
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp ReadCmdsNext

; $E0 unit [voice] [env/gate]: drum track unit only, noise SFX one byte -> NR42
; + retrigger, others vol/duty (+ WriteDuty) and env/gate.
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
	jr z, .l4517
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
.l4517:
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

; Note: length = (lo nibble) * unit; hi 0 = rest; drum track plays a sound.
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
	or a
	jr nz, .l458A
.l458A:
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l458F:
	dec b
	jr z, .l4595
	add a, c
	jr .l458F
.l4595:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l45B3
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l45C5
.l45B3:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l45BB:
	srl c
	jr nc, .l45C0
	add a, d
.l45C0:
	rra
	dec b
	jr nz, .l45BB
	pop de
.l45C5:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l45DD
	ld b, a
	ld c, $0C
	xor a
.l45D8:
	add a, c
	dec b
	jr nz, .l45D8
	ld c, a
.l45DD:
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
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l460C
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoStep
.l460C:
	call WritePeriod
	call NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; NoteVolume: NRx2 for a note-on = (vol - atten - wFadeLevel) << 4, floored at 0
; (CH3: level code from vol/2 + atten + wFadeLevel/2, NR30 on).
NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4642
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l463C
	xor a
.l463C:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4642:
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
	jr c, .l466A
	xor a
.l466A:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

; VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step.
VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jr nc, .l467D
	inc b
.l467D:
	ld a, [bc]
	cp $FB
	jr z, .l46AF
	cp $FE
	jr z, .l46B9
	cp $FF
	jr z, .l46D7
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jr z, .l469D
	ld l, TRK_FLAGS
	set 3, [hl]
.l469D:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS + 1
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	ld a, [bc]
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l46AF:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l467D
.l46B9:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l46CD
	cp $FF
	jr z, .l46C5
	inc [hl]
.l46C5:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jr VibratoStep
.l46CD:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr .l467D
.l46D7:
	ret

; WritePeriod: NRx3/NRx4 = period + vibrato offset (negated if TF_VIBNEG).
WritePeriod:
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
	jr z, .l46F2
	call SwapHLBC
	call NegateHL
	call SwapHLBC
.l46F2:
	call SwapHLDE
	add hl, bc
	call SwapHLBC
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

; Rest: NRx2 = 0 only (no NRx4 write, unlike the earlier games).
Rest:
	ld l, TRK_FLAGS
	ld a, $C0
	or [hl]
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ret

; DrumNote: start sound DrumMap[hi - 1] at once (through the full PlaySound).
DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySoundSafe

; WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4754
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l4754:
	dec a
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrFromTable
	ld b, $10
	ld de, _AUD3WAVERAM
.l4762:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l4762
	pop hl
	pop de
	ret

; IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the
; CH2 SFX active.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l477A
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4783
.l477A:
	cp $04
	jr nz, .l4785
	ld a, [wTrkSfx2]
	or a
	ret z
.l4783:
	scf
	ret
.l4785:
	or a
	ret

; WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal via the shadow (wShadow).
WriteReg:
	call IsBlocked
	ret c
	push de
	call GetRegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	call GetTrackPage
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l47A2
	ld a, [hl]
	cp c
	jr z, .l47A5
.l47A2:
	ld a, c
	ld [hl], a
	ld [de], a
.l47A5:
	pop de
	call GetTrackPage
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
	call GetTrackPage
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
	call SwapHLDE
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

; NR register base per track.
RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; Vibrato table: 15 entries.
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

Vib02:
	VIB_STEP 15, 0, $001
	VIB_STEP 6, 0, $001
	VIB_SEGNO
	VIB_STEP 3, 0, $002
	VIB_STEP 3, 0, $004
	VIB_STEP 3, 0, $002
	VIB_REPEAT $FF

Vib0D:
	VIB_STEP 15, 0, $000
	VIB_STEP 15, 0, $000

Vib03:
	VIB_STEP 3, 0, $000

Vib01:
	VIB_STEP 7, 0, $000

Vib0A:
	VIB_STEP 5, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib04:
	VIB_STEP 15, 1, $001
	VIB_HOLD

Vib06:
	VIB_STEP 15, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $002
	VIB_REPEAT $FF

Vib05:
	VIB_STEP 10, 0, $000
	VIB_STEP 2, 0, $001
	VIB_SEGNO
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib07:
	VIB_STEP 1, 1, $001
	VIB_STEP 1, 1, $004
	VIB_STEP 1, 1, $019
	VIB_STEP 1, 1, $044
	VIB_STEP 1, 1, $068
	VIB_STEP 1, 1, $077
	VIB_STEP 1, 1, $088
	VIB_STEP 1, 1, $099
	VIB_STEP 1, 1, $0A0
	VIB_STEP 1, 1, $0C0
	VIB_STEP 1, 1, $0E0
	VIB_STEP 1, 1, $100
	VIB_STEP 1, 1, $120
	VIB_STEP 1, 1, $140
	VIB_STEP 1, 1, $170
	VIB_STEP 1, 1, $1A0
	VIB_STEP 1, 1, $1D0
	VIB_STEP 1, 1, $200
	VIB_STEP 1, 1, $250
	VIB_STEP 1, 1, $280
	VIB_STEP 1, 1, $2B0
	VIB_STEP 1, 1, $2E1
	VIB_STEP 1, 1, $311
	VIB_STEP 1, 1, $341
	VIB_STEP 1, 1, $391
	VIB_STEP 1, 1, $3F1
	VIB_STEP 1, 1, $441
	VIB_STEP 1, 1, $491
	VIB_HOLD

Vib08:
	VIB_STEP 15, 0, $001
	VIB_HOLD

Vib09:
	VIB_STEP 9, 0, $000

Vib0B:
	VIB_STEP 15, 1, $001
	VIB_STEP 3, 1, $001

Vib0C:
	VIB_STEP 7, 1, $001
	VIB_SEGNO
	VIB_STEP 4, 0, $002
	VIB_STEP 4, 0, $005
	VIB_STEP 4, 0, $002
	VIB_STEP 4, 1, $001
	VIB_REPEAT $FF

Vib0E:
	VIB_STEP 7, 0, $000

Vib0F:
	VIB_STEP 1, 0, $000
	VIB_STEP 15, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Snd2D_Ch1:
	TEMPO $10
	TRANSPOSE_DOWN 2
	VOICE 4, 6, 4, 6, $0A
Snd2D_Ch1_48B0:
	PAN $0F
	SND_CALL Snd2D_Ch1_4906
	RELEASE 2, $0C
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE 3, $0C
	OCTAVE 3
	NOTE F_, 6
	RELEASE 2, $0A
	OCTAVE 4
	NOTE F_, 6
	RELEASE 3, $0F
	NOTE C_HI, 4
	RELEASE 2, $0F
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 3, $0F
	NOTE B_, 4
	RELEASE 2, $0F
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	PAN $F0
	TRANSPOSE_UP 1
	SND_CALL Snd2D_Ch1_4906
	TRANSPOSE_DOWN 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	RELEASE 3, $0C
	OCTAVE 4
	NOTE G#, 6
	RELEASE 2, $0A
	OCTAVE 3
	NOTE G#, 6
	RELEASE 2, $0C
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 2
	NOTE C_HI, 2
	VOICE 4, 7, 4, 2, $0F
	PAN $0F
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE F_, 2
	PAN $F0
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_JUMP Snd2D_Ch1_48B0
Snd2D_Ch1_4906:
	VOICE 4, 5, 4, 6, $0A
	OCTAVE 3
	NOTE E_, $0C
	RELEASE 2, $0A
	NOTE C_HI, 6
	RELEASE 2, $0C
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	RELEASE 2, $0B
	OCTAVE 4
	NOTE G_, 6
	RELEASE 2, $0C
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 3, $0B
	NOTE E_, 6
	OCTAVE 3
	NOTE G_, 6
	NOTE C_HI, 6
	SND_RET

Snd2D_Ch2:
	TRANSPOSE_DOWN 2
	VOICE 4, 7, 4, 6, $0A
	VIBRATO 3
	SND_CALL Snd2D_Ch2_4940
	RELEASE 7, $0A
	NOTE G_, $0C
	TRANSPOSE_UP 1
	SND_CALL Snd2D_Ch2_4940
	RELEASE 7, $0A
	NOTE E_, $0C
	TRANSPOSE_DOWN 2
	SND_JUMP Snd2D_Ch2
Snd2D_Ch2_4940:
	OCTAVE 4
	NOTE C_, $0C
	RELEASE 2, $0A
	NOTE G_, 6
	RELEASE 2, $0C
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	RELEASE 2, $0B
	NOTE A#, 6
	RELEASE 2, $0C
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE 3, $0B
	NOTE G_, 6
	NOTE C_, 6
	RELEASE 2, $0C
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 3, $0C
	NOTE C_HI, 6
	RELEASE 2, $0B
	NOTE C_, 6
	RELEASE 2, $0C
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	SND_RET

Snd2D_Ch3:
	VOICE 4, 2, 7, 6, $0F
	TRANSPOSE_DOWN 2
Snd2D_Ch3_4973:
	SND_CALL Snd2D_Ch3_49D0
	NOTE G#, 2
	NOTE A#, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 4
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 2
	PAN $F0
	NOTE G#, 2
	PAN $0F
	NOTE G#, 2
	PAN $FF
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	PAN $F0
	NOTE G_, 2
	PAN $0F
	NOTE G_, 2
	PAN $FF
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	PAN $F0
	NOTE G_, 2
	PAN $0F
	NOTE G_, 2
	PAN $FF
	TRANSPOSE_UP 1
	SND_CALL Snd2D_Ch3_49D0
	TRANSPOSE_DOWN 2
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	PAN $F0
	NOTE B_, 2
	PAN $0F
	NOTE B_, 2
	PAN $FF
	SND_REPEAT 2
	NOTE A#, 4
	NOTE A#, 2
	NOTE A#, 2
	PAN $F0
	NOTE A#, 2
	PAN $0F
	NOTE A#, 2
	PAN $FF
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	PAN $F0
	NOTE G_, 2
	PAN $0F
	NOTE G_, 2
	PAN $FF
	SND_JUMP Snd2D_Ch3_4973
Snd2D_Ch3_49D0:
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	PAN $0F
	NOTE C_, 2
	PAN $F0
	NOTE C_, 2
	PAN $FF
	SND_REPEAT 3
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	PAN $0F
	NOTE A#, 2
	PAN $F0
	NOTE A#, 2
	PAN $FF
	SND_RET

Snd2D_Drm:
	DRUM_UNIT 4
Snd2D_Drm_49EE:
	SND_SEGNO
	DRUM 1, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	SND_REPEAT 7
	DRUM 1, 4
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_SEGNO
	DRUM 1, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	SND_REPEAT 7
	DRUM 1, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	SND_JUMP Snd2D_Drm_49EE

Snd2E_Ch1:
	TEMPO $20
	TRANSPOSE_DOWN 2
	SND_CALL Snd2E_Ch1_4AEC
	LEN_UNIT 6
	ATTEN 3
	NOTE G_, 2
	SND_CALL Snd2E_Ch1_4B1E
	OCTAVE 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_HI, 2
	SND_CALL Snd2E_Ch1_4B1E
	OCTAVE 3
	NOTE G_, 3
	NOTE C_HI, 3
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 3
	NOTE D_, 1
	NOTE E_, 1
	VOICE 4, 6, 8, 7, 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	VOICE 6, 6, 8, 7, 8
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 3
	NOTE F_, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE D#, 3
	NOTE G#, 4
	RELEASE 3, 2
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 1
	ATTEN 2
	RELEASE 1, $0A
	NOTE F_, 1
	RELEASE 2, $0A
	NOTE G_, 2
	RELEASE 5, $0A
	NOTE G_, 5
	RELEASE 1, $0A
	NOTE G_, 1
	RELEASE 2, $0A
	NOTE A_, 2
	RELEASE 5, $0A
	NOTE A_, 5
	RELEASE 1, $0A
	OCTAVE 4
	NOTE D_, 1
	RELEASE 2, $0A
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 1
	RELEASE 6, 8
	NOTE E_, $0A
	SND_CALL Snd2E_Ch1_4AEC
	VIBRATO 0
Snd2E_Ch1_4A85:
	ATTEN 0
	VOICE 6, 4, 8, 2, $0F
	SND_CALL Snd2E_Ch1_4B2E
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_CALL Snd2E_Ch1_4B2E
	VIBRATO 8
	OCTAVE 5
	NOTE D_, 1
	VIBRATO 0
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 1
	VIBRATO 3
	VOICE 6, 4, $0C, 3, $0C
	OCTAVE 5
	NOTE C_, 3
	NOTE D#, 3
	RELEASE 7, 9
	NOTE G#, $0A
	RELEASE 3, $0C
	OCTAVE 4
	NOTE A#, 3
	OCTAVE 5
	NOTE D_, 3
	RELEASE 7, 9
	NOTE D#, $0A
	RELEASE 3, $0C
	OCTAVE 4
	NOTE C_HI, 3
	NOTE A_, 3
	NOTE C_HI, 2
	OCTAVE 5
	NOTE D_, 3
	OCTAVE 4
	NOTE B_, 3
	OCTAVE 5
	NOTE D_, 2
	NOTE D#, 3
	NOTE C_, 3
	NOTE D#, 2
	NOTE F_, 3
	NOTE D_, 3
	VIBRATO 0
	VOICE $0C, 3, $0C, 7, 3
	NOTE G_, 9
	SND_JUMP Snd2E_Ch1_4A85
Snd2E_Ch1_4AEC:
	VOICE 1, 2, 8, 3, 2
	OCTAVE 3
	NOTE A_, 1
	VOICE 6, 5, 8, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	RELEASE 2, $0C
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	RELEASE 2, $0C
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 1, $0C
	OCTAVE 4
	NOTE C_, 1
	RELEASE 2, $0C
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 1, $0C
	NOTE C_, 1
	RELEASE 2, $0C
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 2
	LEN_UNIT 1
	NOTE G_, 5
	SND_RET
Snd2E_Ch1_4B1E:
	ATTEN 3
	RELEASE 3, 2
	OCTAVE 4
	NOTE G_, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 5
	SND_RET
Snd2E_Ch1_4B2E:
	OCTAVE 4
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $F0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN $FF
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $0F
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN $FF
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	PAN $F0
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	PAN $FF
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	PAN $0F
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	PAN $FF
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $F0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN $FF
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $0F
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	PAN $FF
	SND_RET

Snd2E_Ch2:
	TRANSPOSE_DOWN 2
	SND_CALL Snd2E_Ch2_4C83
	VIBRATO 3
	SND_CALL Snd2E_Ch2_4CDB
	RELEASE 3, 8
	OCTAVE 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_HI, 2
	SND_CALL Snd2E_Ch2_4CDB
	RELEASE 3, 8
	OCTAVE 3
	NOTE G_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE E_, 2
	RELEASE 4, 8
	NOTE G_, 8
	RELEASE 2, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 3
	NOTE D_, 1
	NOTE E_, 1
	VOICE 4, 8, 4, 3, 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	VOICE 6, 8, 4, 2, 8
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 3
	NOTE F_, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE D#, 3
	NOTE G#, 4
	RELEASE 4, 8
	OCTAVE 4
	NOTE G_, 8
	RELEASE 2, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE C_HI, 2
	RELEASE 1, $0C
	OCTAVE 4
	NOTE D_, 1
	RELEASE 2, $0C
	NOTE D#, 2
	RELEASE 5, $0C
	NOTE D#, 5
	RELEASE 1, $0C
	NOTE D#, 1
	RELEASE 2, $0C
	NOTE F_, 2
	RELEASE 5, $0C
	NOTE F_, 5
	RELEASE 1, $0C
	NOTE F_, 1
	RELEASE 2, $0C
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 1
	RELEASE 5, 6
	NOTE G_, $0A
	SND_CALL Snd2E_Ch2_4C83
	TRANSPOSE_DOWN $0E
	VIBRATO 2
Snd2E_Ch2_4BF6:
	SND_CALL Snd2E_Ch2_4CB4
	RELEASE 3, $0C
	OCTAVE 4
	NOTE C_HI, 3
	NOTE A_, 3
	NOTE C_HI, 4
	RELEASE 2, $0C
	OCTAVE 5
	NOTE F_, 2
	RELEASE 1, $0C
	OCTAVE 4
	NOTE A_, 1
	NOTE B_, 1
	RELEASE 2, $0D
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 2, $0E
	NOTE D#, 2
	RELEASE 1, $0D
	NOTE C_, 1
	RELEASE 2, $0D
	OCTAVE 4
	NOTE G#, 2
	OCTAVE 5
	NOTE D#, 2
	RELEASE 1, $0D
	NOTE C_, 1
	RELEASE 2, $0E
	NOTE F_, 2
	RELEASE 1, $0D
	NOTE D_, 1
	RELEASE 2, $0D
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE F_, 2
	RELEASE 1, $0D
	NOTE D_, 1
	SND_CALL Snd2E_Ch2_4CB4
	RELEASE 3, $0D
	NOTE A_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE F_, 2
	NOTE D_, 3
	RELEASE 7, 8
	NOTE G_, $0D
	RELEASE 4, $0E
	OCTAVE 5
	NOTE D#, 3
	NOTE C_, 3
	NOTE D#, 6
	RELEASE 2, $0F
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 3, $0F
	NOTE D#, 2
	RELEASE 4, $0D
	NOTE D_, 3
	OCTAVE 4
	NOTE A#, 3
	RELEASE 7, 8
	NOTE G_, $0A
	RELEASE 2, $0C
	OCTAVE 4
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 3, $0D
	NOTE C_HI, 1
	RELEASE 6, $0F
	OCTAVE 5
	NOTE F_, 5
	RELEASE 2, $0C
	OCTAVE 4
	NOTE B_, 1
	RELEASE 3, $0D
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D_, 1
	RELEASE 6, $0F
	NOTE G_, 5
	RELEASE 2, $0C
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 3, $0D
	NOTE D#, 1
	RELEASE 6, $0F
	NOTE G#, 5
	RELEASE 2, $0C
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 3, $0D
	NOTE F_, 1
	RELEASE 6, $0F
	NOTE A#, 3
	RELEASE 7, 8
	NOTE C_HI, $0A
	NOTE B_, 8
	SND_JUMP Snd2E_Ch2_4BF6
Snd2E_Ch2_4C83:
	VOICE 6, 7, 4, 1, $0D
	OCTAVE 4
	NOTE C_, 1
	RELEASE 2, $0E
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 1, $0E
	NOTE C_, 1
	RELEASE 2, $0E
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 1, $0E
	OCTAVE 4
	NOTE D#, 1
	RELEASE 2, $0E
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	RELEASE 1, $0E
	NOTE D#, 1
	RELEASE 2, $0E
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 2
	RELEASE 1, $0E
	OCTAVE 2
	NOTE G_, 1
	RELEASE 2, $0E
	NOTE G_, 2
	RELEASE 1, $0F
	NOTE G_, 1
	SND_RET
Snd2E_Ch2_4CB4:
	VOICE 6, 7, 4, 3, $0C
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 3
	RELEASE 1, $0C
	NOTE C_HI, 1
	RELEASE 2, $0E
	OCTAVE 5
	NOTE F_, 2
	RELEASE 4, $0C
	NOTE E_, 4
	RELEASE 2, $0C
	NOTE C_, 2
	RELEASE 4, $0C
	NOTE G_, 3
	RELEASE 7, $0A
	OCTAVE 4
	NOTE A#, 7
	RELEASE 1, $0C
	NOTE G_, 1
	NOTE G#, 1
	RELEASE 2, $0F
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_RET
Snd2E_Ch2_4CDB:
	RELEASE 4, 8
	OCTAVE 4
	NOTE G_, 8
	RELEASE 2, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	RELEASE 4, 8
	OCTAVE 3
	NOTE G_, 5
	RELEASE 2, 8
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	RELEASE 4, 8
	OCTAVE 2
	NOTE G_, 5
	SND_RET

Snd2E_Ch3:
	SND_CALL Snd2E_Ch3_4E08
	VOICE 6, 2, 7, 3, $0F
	SND_CALL Snd2E_Ch3_4E2C
	TRANSPOSE_DOWN 2
	SND_CALL Snd2E_Ch3_4E2C
	TRANSPOSE_UP 0
	SND_SEGNO
	PAN $FF
	OCTAVE 2
	NOTE G_, 2
	PAN $F0
	OCTAVE 3
	NOTE G_, 2
	PAN $FF
	OCTAVE 2
	NOTE G_, 2
	PAN $0F
	OCTAVE 3
	NOTE G_, 2
	SND_REPEAT 2
	PAN $FF
	OCTAVE 3
	NOTE C_, 2
	PAN $F0
	OCTAVE 4
	NOTE C_, 2
	PAN $FF
	OCTAVE 3
	NOTE C_, 2
	PAN $0F
	OCTAVE 4
	NOTE C_, 2
	PAN $FF
	OCTAVE 3
	NOTE D_, 2
	PAN $F0
	OCTAVE 4
	NOTE D_, 2
	PAN $FF
	OCTAVE 3
	NOTE D_, 2
	PAN $0F
	OCTAVE 4
	NOTE D_, 2
	PAN $FF
	OCTAVE 3
	NOTE D#, 2
	PAN $F0
	OCTAVE 4
	NOTE D#, 2
	PAN $FF
	OCTAVE 3
	NOTE D#, 2
	PAN $0F
	OCTAVE 4
	NOTE D#, 2
	PAN $FF
	OCTAVE 3
	NOTE D#, 2
	PAN $F0
	OCTAVE 4
	NOTE D#, 2
	PAN $FF
	OCTAVE 3
	NOTE D#, 2
	PAN $0F
	NOTE A#, 2
	SND_SEGNO
	PAN $FF
	OCTAVE 3
	NOTE F_, 2
	PAN $F0
	OCTAVE 4
	NOTE F_, 2
	PAN $FF
	OCTAVE 3
	NOTE F_, 2
	PAN $0F
	OCTAVE 4
	NOTE F_, 2
	SND_REPEAT 2
	SND_SEGNO
	PAN $FF
	OCTAVE 2
	NOTE A#, 2
	PAN $F0
	OCTAVE 3
	NOTE A#, 2
	PAN $FF
	OCTAVE 2
	NOTE A#, 2
	PAN $0F
	OCTAVE 3
	NOTE A#, 2
	SND_REPEAT 2
	PAN $FF
	OCTAVE 3
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	RELEASE 3, 4
	NOTE A#, $0A
	SND_CALL Snd2E_Ch3_4E08
	TRANSPOSE_UP $0A
Snd2E_Ch3_4D94:
	SND_CALL Snd2E_Ch3_4E40
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT 2
	SND_CALL Snd2E_Ch3_4E40
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 3
	RELEASE 6, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 3, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 3
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_JUMP Snd2E_Ch3_4D94
Snd2E_Ch3_4E08:
	VOICE 6, 2, 7, 4, $0F
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	PAN $0F
	NOTE F_, 2
	PAN $FF
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	PAN $F0
	NOTE F_, 1
	PAN $FF
	SND_RET
Snd2E_Ch3_4E2C:
	SND_SEGNO
	PAN $FF
	OCTAVE 2
	NOTE A#, 2
	PAN $F0
	OCTAVE 3
	NOTE A#, 2
	PAN $FF
	OCTAVE 2
	NOTE A#, 2
	PAN $0F
	OCTAVE 3
	NOTE A#, 2
	SND_REPEAT 4
	SND_RET
Snd2E_Ch3_4E40:
	RELEASE 3, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 4
	SND_RET

Snd2F_Ch1:
	TRANSPOSE_UP 3
Snd2F_Ch1_4E5C:
	VOICE 1, 2, $0C, 7, $0C
	VIBRATO 4
	ATTEN 3
	OCTAVE 2
	NOTE D#, 1
	ATTEN 0
	VOICE 6, 5, $0C, 7, $0C
	NOTE D#, 9
	VOICE 1, 4, $0C, 3, 2
	OCTAVE 3
	NOTE A#, 7
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE A#, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 2
	NOTE F_, 9
	VOICE 1, 4, $0C, 3, 2
	OCTAVE 4
	NOTE C_, 7
	NOTE F_, 6
	NOTE C_, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 2
	NOTE G#, 9
	VOICE 1, 4, $0C, 3, 2
	OCTAVE 4
	NOTE D#, 7
	NOTE G#, 6
	NOTE D#, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 3
	NOTE C#, 7
	VOICE 1, 3, $0C, 3, 2
	OCTAVE 4
	NOTE F#, 7
	NOTE C#, 6
	OCTAVE 3
	NOTE A#, 6
	NOTE F#, 6
	NOTE C#, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 3
	NOTE D#, 9
	VOICE 1, 4, $0C, 3, 2
	NOTE A#, 7
	OCTAVE 4
	NOTE D#, 6
	NOTE A#, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 3
	NOTE F_, 9
	VOICE 1, 4, $0C, 3, 2
	OCTAVE 4
	NOTE C_, 7
	NOTE F_, 6
	NOTE C_, 5
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 3
	NOTE G#, 9
	VOICE 1, 4, $0C, 3, 2
	OCTAVE 4
	NOTE D#, 7
	NOTE G#, 6
	NOTE D#, 4
	VOICE 6, 5, $0C, 7, $0C
	OCTAVE 4
	NOTE C#, 4
	VIBRATO 1
	PAN $0F
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	NOTE C#, 1
	NOTE F#, 1
	PAN $F0
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	VOICE 6, 5, $0C, 2, $0F
	SND_CALL Snd2F_Ch1_4F52
	SND_CALL Snd2F_Ch1_4F52
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	RELEASE 7, $0B
	NOTE C_HI, 6
	NOTE G#, 6
	NOTE A#, 6
	RELEASE 2, $0B
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_HI, 1
	RELEASE 7, $0B
	NOTE C_HI, 6
	RELEASE 2, $0B
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	RELEASE 4, $0B
	NOTE C_HI, 3
	RELEASE 2, $0B
	NOTE C_, 2
	NOTE G_, 1
	RELEASE 7, $0B
	NOTE C_HI, 6
	NOTE G#, 6
	NOTE A#, 6
	RELEASE 2, $0B
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	SND_SEGNO
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 4
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	SND_JUMP Snd2F_Ch1_4E5C
Snd2F_Ch1_4F52:
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE C#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C#, 1
	SND_REPEAT 4
	SND_RET

Snd2F_Ch2:
	TEMPO $34
	TRANSPOSE_UP 3
Snd2F_Ch2_4F6D:
	VIBRATO 0
	VOICE 6, 7, 4, 7, $0F
	OCTAVE 2
	NOTE A#, 6
	RELEASE 5, 8
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 1
	RELEASE 2, 8
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	RELEASE 7, $0F
	NOTE C_, 6
	RELEASE 5, 8
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	RELEASE 2, 8
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	RELEASE 7, $0F
	NOTE D#, 6
	RELEASE 5, 8
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 1
	RELEASE 2, 8
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	RELEASE 7, $0F
	NOTE F#, 6
	RELEASE 2, 8
	OCTAVE 4
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 7, $0F
	OCTAVE 3
	NOTE A#, 6
	RELEASE 5, 8
	NOTE D#, 2
	NOTE A#, 1
	RELEASE 2, 8
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	RELEASE 7, $0F
	NOTE C_HI, 6
	RELEASE 5, 8
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	RELEASE 2, 8
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	RELEASE 7, $0F
	OCTAVE 4
	NOTE D#, 6
	RELEASE 5, 8
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 1
	RELEASE 2, 8
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	RELEASE 4, $0C
	OCTAVE 4
	NOTE F#, 3
	RELEASE 2, 8
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	SND_CALL Snd2F_Ch2_5089
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	PAN $FF
	SND_CALL Snd2F_Ch2_5089
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	PAN $FF
	VOICE 6, 7, 4, 4, $0C
	OCTAVE 3
	NOTE C_HI, 3
	RELEASE 2, $0F
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	RELEASE 4, $0C
	NOTE F_, 3
	RELEASE 2, $0F
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE 4, $0C
	NOTE D#, 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	RELEASE 4, $0C
	NOTE D_, 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	OCTAVE 3
	NOTE C_HI, 3
	RELEASE 2, $0F
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	RELEASE 4, $0C
	NOTE F_, 3
	RELEASE 2, $0F
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE 4, $0F
	NOTE C_, 3
	NOTE D_, 3
	NOTE D#, 3
	NOTE F_, 3
	RELEASE 4, $0C
	NOTE G_, 3
	RELEASE 2, $0F
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	RELEASE 4, $0C
	NOTE A#, 3
	RELEASE 2, $0F
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	RELEASE 4, $0C
	NOTE D#, 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	RELEASE 4, $0C
	NOTE F_, 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE 4, $0C
	NOTE F_, 3
	RELEASE 2, $0F
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE 4, $0C
	NOTE D_, 3
	VIBRATO 6
	RELEASE 7, 7
	NOTE C_, $0C
	VIBRATO 3
	RELEASE 7, 8
	NOTE C_HI, 6
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	SND_JUMP Snd2F_Ch2_4F6D
Snd2F_Ch2_5089:
	VIBRATO 5
	RELEASE 2, $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 4, $0B
	NOTE A#, 3
	PAN $F0
	RELEASE 2, $0E
	OCTAVE 4
	NOTE A#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	PAN $FF
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	VIBRATO 1
	RELEASE 4, $0C
	NOTE F#, 4
	PAN $0F
	RELEASE 2, $0E
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET

Snd2F_Ch3:
	TRANSPOSE_UP 3
Snd2F_Ch3_50CF:
	VOICE 6, 2, 7, 5, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	PAN $0F
	OCTAVE 3
	NOTE C_, 1
	PAN $FF
	OCTAVE 2
	NOTE C_, 1
	PAN $F0
	OCTAVE 3
	NOTE C_, 1
	PAN $FF
	OCTAVE 2
	NOTE C_, 1
	PAN $0F
	OCTAVE 3
	NOTE C_, 1
	PAN $FF
	SND_REPEAT 7
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT 2
	VOICE 6, 2, 7, 3, $0F
	SND_CALL Snd2F_Ch3_5199
	SND_CALL Snd2F_Ch3_5199
	RELEASE 5, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	SND_JUMP Snd2F_Ch3_50CF
Snd2F_Ch3_5199:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	SND_REPEAT 3
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_RET

Snd30_Ch1:
	TEMPO $30
	VIBRATO $0E
Snd30_Ch1_51C8:
	VOICE 1, 2, 8, 7, $0F
	OCTAVE 3
	NOTE A#, 1
	SND_CALL Snd30_Ch1_523C
	RELEASE 7, 6
	NOTE F_, $0C
	RELEASE 7, 8
	NOTE C#, 6
	OCTAVE 3
	NOTE G#, 6
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C#, 6
	RELEASE 7, 4
	OCTAVE 3
	NOTE G#, $0E
	RELEASE 2, 8
	NOTE C_HI, 2
	NOTE B_, 2
	SND_CALL Snd30_Ch1_523C
	RELEASE 7, 6
	NOTE F_, 9
	RELEASE 2, $0A
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 6, 8
	OCTAVE 4
	NOTE C#, 6
	OCTAVE 3
	NOTE G#, 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 1
	RELEASE 3, 8
	OCTAVE 3
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 2
	RELEASE 2, 8
	NOTE B_, 2
	NOTE F#, 2
	NOTE B_, 2
	RELEASE 7, 8
	NOTE A#, 6
	LEN_UNIT 7
	NOTE F_, 5
	VOICE 6, 3, 8, 3, 4
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
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
	NOTE F_, 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE F#, 1
	DUTY 4
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	SND_JUMP Snd30_Ch1_51C8
Snd30_Ch1_523C:
	VOICE 6, 3, 8, 7, 8
	OCTAVE 3
	NOTE A#, 6
	NOTE F_, 6
	RELEASE 3, 8
	OCTAVE 4
	NOTE C#, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	NOTE G#, 3
	RELEASE 7, 8
	NOTE A#, 6
	NOTE F_, 3
	RELEASE 2, 8
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	SND_RET

Snd30_Ch2:
	VIBRATO $0E
Snd30_Ch2_5258:
	SND_CALL Snd30_Ch2_52C0
	RELEASE 7, 8
	NOTE A#, $0C
	RELEASE 7, $0A
	NOTE F#, 6
	NOTE C#, 6
	NOTE A_, 6
	NOTE E_, 6
	NOTE F#, 6
	RELEASE 7, 4
	NOTE C#, $0E
	RELEASE 2, $0C
	NOTE F_, 2
	NOTE E_, 2
	SND_CALL Snd30_Ch2_52C0
	RELEASE 7, 8
	NOTE A#, 9
	RELEASE 2, $0C
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	RELEASE 7, $0A
	NOTE F#, 6
	RELEASE 3, $0C
	NOTE C#, 3
	RELEASE 5, $0C
	NOTE C#, 2
	NOTE F#, 1
	RELEASE 2, $0C
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 7, $0A
	NOTE D#, 6
	OCTAVE 3
	NOTE A#, 6
	PAN $FF
	ATTEN 1
	RELEASE 2, $0D
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	DUTY 0
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 2
	RELEASE 1, $0A
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 2
	ATTEN 0
	SND_JUMP Snd30_Ch2_5258
Snd30_Ch2_52C0:
	VOICE 6, 8, 8, 7, $0A
	OCTAVE 4
	NOTE D#, 6
	OCTAVE 3
	NOTE A#, 6
	RELEASE 3, $0C
	OCTAVE 4
	NOTE F#, 3
	NOTE F_, 3
	NOTE D#, 3
	NOTE C#, 3
	RELEASE 7, $0A
	NOTE D#, 6
	RELEASE 3, $0D
	OCTAVE 3
	NOTE A#, 3
	RELEASE 2, $0C
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	SND_RET

Snd30_Ch3:
	SND_CALL Snd30_Ch3_535D
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	SND_REPEAT 4
	SND_CALL Snd30_Ch3_535D
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE A#, 1
	VIBRATO 4
	VOICE 6, 4, 6, 3, $0F
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_SEGNO
	PAN $0F
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 2
	VOICE 6, 2, 8, 2, $0F
	SND_SEGNO
	PAN $0F
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 2
	PAN $FF
	SND_JUMP Snd30_Ch3
Snd30_Ch3_535D:
	VOICE 6, 2, 8, 2, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE A#, 1
	SND_REPEAT 4
	SND_RET

Snd31_Ch1:
	TEMPO $40
	SND_CALL Snd31_Ch1_5492
	PAN $F0
	RELEASE 2, $0C
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	PAN $FF
	SND_CALL Snd31_Ch1_5492
	PAN $0F
	RELEASE 2, $0C
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	PAN $FF
Snd31_Ch1_5393:
	VIBRATO 4
	SND_CALL Snd31_Ch1_54B3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 5
	PAN $0F
	VOICE 6, 6, 4, 2, $0E
	OCTAVE 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $FF
	SND_CALL Snd31_Ch1_54B3
	NOTE F_, 1
	PAN $F0
	VOICE 6, 7, 4, 2, $0C
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	PAN $F0
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	VIBRATO 0
	SND_CALL Snd31_Ch1_54DD
	PAN $0F
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	PAN $FF
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	PAN $F0
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_CALL Snd31_Ch1_54DD
	PAN $0F
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	PAN $FF
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE G#, 1
	RELEASE 2, $0F
	NOTE G#, 2
	NOTE G#, 2
	RELEASE 1, $0C
	NOTE G#, 1
	PAN $F0
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	PAN $FF
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 3, $0C
	NOTE F_, 2
	RELEASE 1, $0C
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	RELEASE 3, $0C
	NOTE G_, 2
	RELEASE 2, $0D
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A_, 1
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 3, $0C
	NOTE F_, 2
	RELEASE 1, $0C
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	RELEASE 3, $0C
	NOTE G_, 2
	RELEASE 1, $0C
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A_, 1
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	ATTEN 3
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_JUMP Snd31_Ch1_5393
Snd31_Ch1_5492:
	VOICE 6, 6, 0, 2, $0F
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	RELEASE 7, 8
	NOTE A_, 7
	SND_RET
Snd31_Ch1_54B3:
	VOICE 6, 3, 4, 3, 4
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 7
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 3
	NOTE F#, 2
	VOICE 1, 6, 4, $0F, 0
	OCTAVE 4
	NOTE F#, 9
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 3
	VOICE 6, 6, 4, 3, $0A
	OCTAVE 3
	NOTE B_, 3
	VOICE 6, 3, 4, 3, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE F_, 4
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd31_Ch1_54DD:
	PAN $FF
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE B_, 1
	RELEASE 2, $0F
	NOTE B_, 2
	NOTE B_, 2
	RELEASE 1, $0C
	NOTE B_, 1
	PAN $0F
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	PAN $FF
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	PAN $F0
	VIBRATO 4
	VOICE 6, 5, 4, 2, $0F
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	PAN $FF
	VIBRATO 0
	VOICE 6, 6, 4, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	SND_RET

Snd31_Ch2:
	VIBRATO $0F
	SND_CALL Snd31_Ch2_5611
	PAN $0F
	VOICE 6, 7, 0, 2, $0C
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	PAN $FF
	SND_CALL Snd31_Ch2_5611
	PAN $F0
	VOICE 6, 7, 0, 2, $0C
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	PAN $FF
Snd31_Ch2_5550:
	SND_CALL Snd31_Ch2_5634
	NOTE E_, 1
	NOTE F_, 1
	RELEASE 7, 8
	NOTE E_, 6
	PAN $F0
	RELEASE 2, $0E
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	PAN $FF
	SND_CALL Snd31_Ch2_5634
	NOTE F_, 1
	NOTE A#, 1
	RELEASE 7, 6
	NOTE A_, $0C
	SND_CALL Snd31_Ch2_5669
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	PAN $FF
	RELEASE 1, $0C
	NOTE D_, 1
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 1, $0C
	NOTE D_, 1
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_CALL Snd31_Ch2_5669
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	PAN $FF
	RELEASE 1, $0C
	NOTE D_, 1
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 1, $0C
	NOTE D_, 1
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	PAN $FF
	RELEASE 1, $0C
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	RELEASE 3, $0C
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 3, $0C
	NOTE B_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	PAN $F0
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	PAN $FF
	RELEASE 1, $0C
	OCTAVE 4
	NOTE F_, 1
	NOTE G_, 1
	RELEASE 3, $0C
	NOTE A_, 2
	RELEASE 1, $0C
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 3, $0C
	NOTE B_, 2
	RELEASE 1, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C#, 1
	PAN $0F
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	PAN $FF
	SND_JUMP Snd31_Ch2_5550
Snd31_Ch2_5611:
	VOICE 6, 7, 8, 2, $0F
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	RELEASE 7, 8
	OCTAVE 4
	NOTE D_, 7
	SND_RET
Snd31_Ch2_5634:
	VOICE 6, 7, 4, 2, $0C
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 7, 8
	NOTE A_, 7
	RELEASE 2, $0C
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 3, $0A
	NOTE B_, 3
	NOTE F#, 3
	PAN $0F
	VOICE 1, 9, 4, $0F, 0
	OCTAVE 4
	NOTE B_, 9
	NOTE A#, 3
	NOTE G#, 3
	NOTE G_, 3
	VOICE 6, 9, 4, 3, $0A
	NOTE F#, 3
	PAN $FF
	RELEASE 2, $0C
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 4, $0A
	NOTE F_, 4
	RELEASE 2, $0C
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd31_Ch2_5669:
	PAN $FF
	RELEASE 1, $0C
	NOTE E_, 1
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 1, $0C
	NOTE E_, 1
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	PAN $FF
	RELEASE 1, $0C
	NOTE E_, 1
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 1, $0C
	NOTE E_, 1
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	PAN $FF
	RELEASE 1, $0C
	NOTE D_, 1
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 1, $0C
	NOTE D_, 1
	SND_RET

Snd31_Ch3:
	VOICE 6, 2, 8, 2, $0F
	SND_CALL Snd31_Ch3_575D
	SND_CALL Snd31_Ch3_575D
Snd31_Ch3_56B0:
	SND_CALL Snd31_Ch3_577C
	SND_CALL Snd31_Ch3_577C
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_REPEAT 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	SND_JUMP Snd31_Ch3_56B0
Snd31_Ch3_575D:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_REPEAT 2
	SND_RET
Snd31_Ch3_577C:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	SND_RET

Snd32_Ch1:
	TRANSPOSE_DOWN 2
Snd32_Ch1_57BB:
	VIBRATO 4
	VOICE 1, 5, 8, 3, 4
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	LEN_UNIT 6
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 5
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE C_HI, 5
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	LEN_UNIT 7
	OCTAVE 5
	NOTE D_, 4
	LEN_UNIT 1
	NOTE D_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 4
	DUTY 4
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 2
	NOTE A_, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	DUTY 8
	ATTEN 2
	RELEASE 3, 4
	OCTAVE 4
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 4
	DUTY 4
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	SND_CALL Snd32_Ch1_58C5
	ATTEN 2
	PAN $0F
	RELEASE 3, 4
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	RELEASE 3, $0A
	OCTAVE 3
	NOTE A#, 3
	NOTE C_HI, 2
	NOTE A_, 1
	NOTE A#, 2
	RELEASE 2, $0C
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 2
	NOTE F_, 1
	RELEASE 5, $0C
	NOTE A#, 4
	RELEASE 2, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_CALL Snd32_Ch1_58C5
	VIBRATO 0
	VOICE 2, 5, 4, 5, $0C
	OCTAVE 3
	NOTE A#, 8
	VOICE 1, 5, 4, 4, $0D
	NOTE A#, 4
	NOTE C_HI, 4
	VOICE 2, 5, 4, 5, $0C
	OCTAVE 4
	NOTE D_, 8
	VOICE 1, 5, 4, 4, $0D
	NOTE D_, 4
	NOTE E_, 4
	VOICE 2, 5, 4, 5, $0C
	NOTE F_, 8
	VOICE 1, 5, 4, 4, $0D
	NOTE F_, 4
	NOTE G_, 4
	RELEASE 4, $0C
	NOTE A_, 8
	NOTE G_, 8
	NOTE D_, 8
	VOICE 6, 7, 4, 5, $0C
	NOTE D_, 5
	RELEASE 2, $0D
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 7, 8
	OCTAVE 4
	NOTE A_, 5
	NOTE G#, 4
	SND_SEGNO
	RELEASE 4, $0C
	OCTAVE 3
	NOTE A_, 3
	NOTE E_, 3
	RELEASE 3, $0C
	NOTE A_, 2
	ATTEN 1
	PAN $F0
	SND_REPEAT 2
	ATTEN 0
	PAN $FF
	RELEASE 4, $0C
	NOTE G_, 3
	NOTE D_, 3
	RELEASE 3, $0C
	NOTE G_, 2
	PAN $0F
	ATTEN 1
	RELEASE 4, $0C
	NOTE G#, 3
	NOTE E_, 3
	RELEASE 3, $0C
	NOTE B_, 2
	ATTEN 0
	PAN $FF
	SND_SEGNO
	RELEASE 4, $0C
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE A_, 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE E_, 2
	PAN $F0
	ATTEN 1
	SND_REPEAT 2
	PAN $FF
	ATTEN 0
	RELEASE 4, $0C
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE D_, 2
	PAN $0F
	ATTEN 1
	RELEASE 4, $0C
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 3
	RELEASE 2, $0C
	OCTAVE 4
	NOTE D_, 2
	PAN $FF
	ATTEN 0
	SND_JUMP Snd32_Ch1_57BB
Snd32_Ch1_58C5:
	ATTEN 2
	PAN $0F
	RELEASE 3, 4
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	PAN $FF
	RELEASE 3, $0D
	OCTAVE 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 2
	ATTEN 2
	PAN $F0
	RELEASE 3, 4
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	OCTAVE 5
	NOTE E_, 1
	ATTEN 0
	PAN $FF
	RELEASE 3, $0D
	OCTAVE 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE E_, 1
	NOTE C_HI, 2
	SND_RET

Snd32_Ch2:
	TEMPO $38
	TRANSPOSE_DOWN 2
Snd32_Ch2_58F7:
	VOICE 6, 7, 4, 2, $0C
	VIBRATO 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 5, $0C
	NOTE A_, 5
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 5, $0C
	NOTE B_, 5
	RELEASE 2, $0F
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	RELEASE 5, $0C
	NOTE C_HI, 5
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	RELEASE 5, $0C
	OCTAVE 5
	NOTE D_, 5
	RELEASE 2, $0C
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE 5, $0C
	NOTE F_, 5
	RELEASE 2, $0C
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	RELEASE 2, $0C
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	RELEASE 5, $0C
	NOTE G_, 5
	RELEASE 2, $0C
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	SND_CALL Snd32_Ch2_59EA
	OCTAVE 5
	SND_SEGNO
	RELEASE 3, $0D
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE C_, 1
	RELEASE 4, $0D
	NOTE D_, 2
	OCTAVE 4
	SND_REPEAT 2
	RELEASE 3, $0D
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE A_, 1
	RELEASE 5, $0C
	OCTAVE 6
	NOTE D_, 4
	RELEASE 3, $0D
	OCTAVE 5
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_CALL Snd32_Ch2_59EA
	VOICE 2, 7, 4, 4, $0C
	NOTE D_, 8
	VOICE 1, 7, 4, 4, $0F
	NOTE D_, 4
	NOTE E_, 4
	VOICE 2, 7, 4, 4, $0C
	NOTE F_, 8
	VOICE 1, 7, 4, 4, $0F
	NOTE F_, 4
	NOTE G_, 4
	VOICE 2, 7, 4, 4, $0C
	NOTE A_, 8
	VOICE 1, 7, 4, 4, $0F
	NOTE A_, 4
	NOTE A#, 4
	RELEASE 4, $0C
	NOTE C_HI, 8
	NOTE A#, 8
	NOTE E_, 8
	VOICE 6, 7, 4, 2, $0F
	RELEASE 5, $0C
	NOTE A_, 5
	RELEASE 2, $0D
	NOTE A_, 1
	NOTE B_, 1
	RELEASE 7, 8
	OCTAVE 5
	NOTE E_, 9
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE A_, 3
	RELEASE 3, $0D
	OCTAVE 4
	NOTE E_, 2
	ATTEN 2
	SND_REPEAT 2
	ATTEN 0
	RELEASE 4, $0D
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 3
	RELEASE 3, $0D
	OCTAVE 4
	NOTE D_, 2
	ATTEN 2
	RELEASE 4, $0D
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 3
	RELEASE 3, $0D
	OCTAVE 4
	NOTE G#, 2
	ATTEN 0
	RELEASE 4, $0D
	NOTE A_, 3
	NOTE E_, 3
	RELEASE 3, $0D
	NOTE A_, 2
	ATTEN 2
	RELEASE 4, $0D
	NOTE A_, 3
	NOTE E_, 3
	RELEASE 3, $0D
	NOTE A_, 2
	ATTEN 0
	RELEASE 4, $0D
	NOTE G_, 3
	NOTE D_, 3
	RELEASE 3, $0D
	NOTE G_, 2
	ATTEN 2
	RELEASE 4, $0D
	NOTE G#, 3
	NOTE E_, 3
	RELEASE 3, $0D
	NOTE G#, 2
	ATTEN 0
	SND_JUMP Snd32_Ch2_58F7
Snd32_Ch2_59EA:
	OCTAVE 4
	SND_SEGNO
	RELEASE 3, $0D
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	RELEASE 4, $0D
	NOTE A_, 2
	OCTAVE 3
	SND_REPEAT 2
	RELEASE 3, $0D
	OCTAVE 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	RELEASE 4, $0D
	OCTAVE 5
	NOTE E_, 2
	RELEASE 3, $0D
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	RELEASE 4, $0D
	OCTAVE 4
	NOTE E_, 2
	SND_RET

Snd32_Ch3:
	TRANSPOSE_UP $0A
Snd32_Ch3_5A14:
	VOICE 6, 2, 7, 6, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	PAN $F0
	OCTAVE 2
	NOTE A_, 1
	PAN $FF
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 2
	NOTE A_, 1
	PAN $FF
	SND_REPEAT 8
	SND_CALL Snd32_Ch3_5ADD
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	RELEASE 3, $0F
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_SEGNO
	RELEASE 6, $0F
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_REPEAT 4
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_CALL Snd32_Ch3_5ADD
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_REPEAT 8
	RELEASE 3, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT 2
	SND_CALL Snd32_Ch3_5AC0
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_CALL Snd32_Ch3_5AC0
	SND_JUMP Snd32_Ch3_5A14
Snd32_Ch3_5AC0:
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_RET
Snd32_Ch3_5ADD:
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 3, $0F
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_SEGNO
	RELEASE 6, $0F
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_REPEAT 4
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 3, $0F
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_SEGNO
	RELEASE 6, $0F
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	SND_REPEAT 4
	SND_RET

; PlaySoundSafe: PlaySound keeping all registers (used for drums and the queue).
PlaySoundSafe:
	push hl
	push de
	push bc
	push af
	call PlaySound
	pop af
	pop bc
	pop de
	pop hl
	ret

; StartFade: wFadeTarget = A. Unreferenced: the game writes wFadeTarget itself.
StartFade:
	push hl
	push de
	push bc
	push af
	ld [wFadeTarget], a
	pop af
	pop bc
	pop de
	pop hl
	ret

; CheckLockout: carry = refuse the request. $2C (pause) and $13 always pass.
; Everything else is refused while wLockout != 0. Ids >= $2E cancel a fade, and
; ids $2E-$32 also start the lockout from LockoutTable.
CheckLockout:
	cp $2C
	ret z
	cp $13
	ret z
	ld hl, wLockout
	ld a, [hl+]
	ld h, [hl]
	or h
	jr nz, .l5B5F
	ld a, [wReqId]
	cp $2E
	jr c, .l5B5C
	cp $33
	jr nc, .l5B55
	sub $2E
	ld hl, LockoutTable
	call LoadPtrFromTable
	ld a, l
	ld [wLockout], a
	ld a, h
	ld [wLockout + $01], a
.l5B55:
	xor a
	ld [wFadeTarget], a
	ld [wFadeLevel], a
.l5B5C:
	or a
	jr .l5B60
.l5B5F:
	scf
.l5B60:
	ld a, [wReqId]
	ret
LockoutTable:
	dw $0165
	dw $003E
	dw $01F4
	dw $0138
	dw $0165

; PlaySound: A = sound id (0 = stop everything). $0F does not restart itself.
; Each mask bit starts one track if the new priority >= that track's priority.
PlaySound:
	ld [wReqId], a
	or a
	jp z, StopAll
	call CheckLockout
	ret c
	cp $0F
	jr nz, .l5B82
	ld hl, wTrkSfx1
	cp [hl]
	ret z
.l5B82:
	ld hl, SoundTable - 2
	call LoadPtrFromTable
	ld a, [hl]
	ld [wReqPrio], a
	inc hl
	ld a, [hl]
	srl a
	call c, StartSfx1
	srl a
	call c, StartSfx2
	srl a
	call c, StartSfxN
	srl a
	call c, StartCh1
	srl a
	call c, StartCh2
	srl a
	call c, StartCh3
	srl a
	call c, StartDrm
	ld hl, rNR51
	ld a, [wNR51]
	ld [hl], a
	ret

StartSfx1:
	push af
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wShadow
	ld [bc], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld de, wTrkSfx1
	jp StartTrack

StartSfx2:
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	ld de, wTrkSfx2
	jp StartTrack

StartSfxN:
	push af
	ld a, [wNR51]
	or $88
	ld [wNR51], a
	ld de, wTrkSfxN
	jp StartTrack

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l5C01
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wShadow
	ld [bc], a
.l5C01:
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld de, wTrkCh1
	jp StartTrack

StartCh2:
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	ld de, wTrkCh2
	jp StartTrack

StartCh3:
	push af
	ld a, [wNR51]
	or $44
	ld [wNR51], a
	ld de, wTrkCh3
	jp StartTrack

StartDrm:
	push af
	ld de, wTrkDrm
	jp StartTrack

StartTrack:
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	push hl
	ld hl, $0001
	add hl, de
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l5C5E
	ld [hl], a
	ld a, [wReqId]
	ld [de], a
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
	inc hl
	ld [hl], $01
	inc hl
	ld [hl], $40
	inc hl
	ld e, l
	inc e
	ld d, h
	ld bc, $0006
	ld [hl], $00
	call CopyBytes
.l5C5E:
	pop hl
	pop af
	ret

; StopAll: clear all 7 tracks, the shadows and the globals, wNR51 = $FF (not
; written to NR51), then fall into SndPause.
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wShadow
	ld de, wShadow + $01
	ld bc, $0014
	ld [hl], $00
	call CopyBytes
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0012
	ld [hl], $00
	call CopyBytes
	ld a, $FF
	ld [wNR51], a

; SndPause: NR12/NR17/NR1C/NR21 = 0.
SndPause:
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ret

; SndUnpause: copy the shadows back (no retrigger), per channel only if one of
; its tracks is active. CH4 only for SfxN ids >= 8 (not a drum).
SndUnpause:
	ld a, [wPause]
	ld b, a
	ld a, [wMusicHold]
	or b
	ret nz
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l5D0D
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l5D0D:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l5D22
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l5D22:
	ld a, [wTrkCh3]
	or a
	jr z, .l5D33
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l5D33:
	ld a, [wTrkSfxN]
	or a
	ret z
	cp $08
	ret c
	ld hl, wShadow + $10
	ld de, rNR41
	ld b, $04
	call CopyRegs
	ret

CopyRegs:
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, CopyRegs
	ret

Snd15_Ch1:
	TEMPO $30
	VOICE 6, 8, 4, 2, $0F
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 3, $0F
	NOTE G_, 4
	SND_END

Snd15_Ch2:
	VOICE 6, 7, 4, 2, $0F
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	RELEASE 3, $0F
	OCTAVE 4
	NOTE B_, 4
	SND_END

Snd08_Sfx1:
	VOICE 1, 9, 8, 1, $0F
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	REST 3
	ATTEN 6
	NOTE C_HI, 1
	REST 3
	ATTEN 7
	NOTE C_HI, 1
	SND_END

Snd09_Sfx1:
	VOICE 1, $0C, 8, 1, $0F
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	REST 3
	ATTEN 7
	NOTE C_HI, 1
	REST 3
	ATTEN 9
	NOTE C_HI, 1
	SND_END

Snd23_Sfx1:
	VOICE 1, $0C, 4, 6, 9
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	DUTY 8
	ATTEN 2
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 4
	OCTAVE 1
	NOTE F#, 1
	NOTE C#, 1
	REST 1
	ATTEN 6
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 7
	OCTAVE 1
	NOTE F#, 1
	NOTE C#, 1
	REST 1
	ATTEN 9
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	ATTEN $0A
	OCTAVE 1
	NOTE F#, 1
	NOTE C#, 1
	SND_END

Snd0A_Sfx1:
	VOICE 1, $0F, $0C, 8, 6
	ATTEN 6
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	DUTY 4
	ATTEN 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	VOICE 1, $0D, 0, 8, 6
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	ATTEN 2
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 2
	ATTEN 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 2
	ATTEN 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 5
	NOTE C#, 1
	NOTE F_, 1
	NOTE G_, 1
	REST 2
	ATTEN 6
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE G_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_END

Snd1D_Ch1:
	TEMPO $00
	VOICE 1, $0F, 8, 1, 0
	ATTEN 6
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 4
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 2
	SND_CALL Snd1D_Ch1_5F4B
	SND_SEGNO
	ATTEN 1
	SND_CALL Snd1D_Ch1_5F4B
	SND_REPEAT 2
	ATTEN 0
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 1
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 2
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 4
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 6
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 7
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN 9
	SND_CALL Snd1D_Ch1_5F4B
	ATTEN $0A
	SND_CALL Snd1D_Ch1_5F4B
	SND_END

Snd1D_Ch2:
	VOICE 1, $0C, 8, 8, 6
	ATTEN 6
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 4
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 2
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 0
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 4
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 6
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 7
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN 9
	SND_CALL Snd1D_Ch2_5F5A
	ATTEN $0A
	SND_CALL Snd1D_Ch2_5F5A
	SND_END

Snd1D_Ch3:
	VOICE 1, 2, 8, 8, 6
	ATTEN 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 1
	SND_CALL Snd1D_Ch3_5F71
	SND_SEGNO
	ATTEN 0
	SND_CALL Snd1D_Ch3_5F71
	SND_REPEAT 3
	ATTEN 1
	SND_CALL Snd1D_Ch3_5F71
	SND_CALL Snd1D_Ch3_5F71
	ATTEN 2
	SND_CALL Snd1D_Ch3_5F71
	SND_END

Snd1D_SfxN:
	NVOICE $17, 3, 7
	NOISE $34
	NOISE $24
	NVOICE $17, 4, 7
	NOISE $17
	NOISE $12
	NVOICE $17, 4, 7
	NOISE $17
	NOISE $24
	NVOICE $17, 3, 7
	NOISE $34

Snd1D_Drm:
	SND_END

Snd1E_Ch1:
	TEMPO $00
	VOICE 1, $0F, 8, 1, 0
	SND_SEGNO
	SND_CALL Snd1E_Ch1_5F88
	SND_REPEAT 3
	VOICE 1, $0C, 8, 1, 0
	SND_CALL Snd1E_Ch1_5F88
	ATTEN 2
	SND_CALL Snd1E_Ch1_5F88
	ATTEN 4
	SND_CALL Snd1E_Ch1_5F88
	ATTEN 6
	SND_CALL Snd1E_Ch1_5F88
	ATTEN 7
	SND_CALL Snd1E_Ch1_5F88
	ATTEN 9
	SND_CALL Snd1E_Ch1_5F88
	SND_END

Snd1E_Ch2:
	VOICE 1, $0F, 4, 1, 0
	SND_SEGNO
	SND_CALL Snd1E_Ch2_5F9B
	SND_REPEAT 3
	VOICE 1, $0C, 8, 1, 0
	SND_CALL Snd1E_Ch2_5F9B
	ATTEN 2
	SND_CALL Snd1E_Ch2_5F9B
	ATTEN 4
	SND_CALL Snd1E_Ch2_5F9B
	ATTEN 6
	SND_CALL Snd1E_Ch2_5F9B
	ATTEN 7
	SND_CALL Snd1E_Ch2_5F9B
	ATTEN 9
	SND_CALL Snd1E_Ch2_5F9B
	SND_END

Snd1E_Ch3:
	VOICE 1, 2, 6, 1, 0
	SND_SEGNO
	PAN $0F
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	PAN $F0
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_REPEAT 2
	PAN $FF
	WAVE 6
	OCTAVE 4
	NOTE F#, 1
	NOTE F_, 1
	REST 4
	SND_SEGNO
	SND_CALL Snd1E_Ch3_5FAD
	SND_REPEAT 6
	SND_SEGNO
	ATTEN 1
	SND_CALL Snd1E_Ch3_5FAD
	SND_REPEAT 2
	SND_END

Snd1E_SfxN:
	NVOICE 1, $0F, 1
	NOISE $11
	NVOICE 7, $0F, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE 9, $0A, 7
	NOISE $71
	NOISE $71
	NOISE $73
	NVOICE $0A, 9, 7
	NOISE $72
	NVOICE $0A, 7, 7
	NOISE $72
	NVOICE $0A, 6, 7
	NOISE $72
	NVOICE $0A, 4, 7
	NOISE $72

Snd1E_Drm:
	SND_END
Snd1D_Ch1_5F4B:
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_RET
Snd1D_Ch2_5F5A:
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
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
	SND_RET
Snd1D_Ch3_5F71:
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
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
	SND_RET
Snd1E_Ch1_5F88:
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	REST 2
	SND_RET
Snd1E_Ch2_5F9B:
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	REST 2
	SND_RET
Snd1E_Ch3_5FAD:
	OCTAVE 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	SND_RET

; Unreferenced stream bytes.
Orphan_5FBC:
	db $E1, $61, $A1, $E2, $21, $41, $71, $FC

Snd26_Ch1:
	SND_CALL Snd1D_Ch1

Snd26_Ch2:
	SND_CALL Snd1D_Ch2

Snd26_Ch3:
	SND_CALL Snd1D_Ch3

Snd26_SfxN:
	SND_CALL Snd1D_SfxN

Snd2A_Sfx1:
	VOICE 1, $0F, 8, 1, 0
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	VOICE 2, $0A, 8, 1, $0F
	TRANSPOSE_UP $0F
	OCTAVE 6
	NOTE D#, 6
	REST 2
	VOICE 1, 6, 8, 1, 0
	TRANSPOSE_UP 0
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	VOICE 2, 4, 8, 1, $0F
	TRANSPOSE_UP $0F
	OCTAVE 6
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	SND_END

Snd2A_Sfx2:
	VOICE 2, $0A, 8, 1, $0F
	TRANSPOSE_UP $0F
	VIBRATO 4
	OCTAVE 6
	ATTEN 2
	NOTE C#, 3
	ATTEN 0
	NOTE D#, 6
	REST 2
	VOICE 1, 6, 8, 1, 0
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	VOICE 2, 4, 8, 1, $0F
	TRANSPOSE_UP $0F
	OCTAVE 6
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	SND_END

Snd2A_SfxN:
	NVOICE 2, $0F, 7
	NOISE $71
	NVOICE $0D, 9, 7
	NOISE $72
	NOISE $73
	NVOICE 6, 4, 1
	NOISE $14
	NOISE $24
	SND_END

Snd25_Ch1:
	VOICE 1, $0D, 8, 1, 0
	ATTEN 4
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	SND_CALL Snd25_Ch1_61BB
	ATTEN 7
	SND_CALL Snd25_Ch1_61BB
	ATTEN 9
	SND_CALL Snd25_Ch1_61BB
	ATTEN 4
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F_, 1
	SND_SEGNO
	ATTEN 6
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	SND_REPEAT 2
	ATTEN 6
	SND_CALL Snd25_Ch1_61BB
	SND_CALL Snd25_Ch1_61BB
	ATTEN 7
	SND_CALL Snd25_Ch1_61BB
	ATTEN 9
	SND_CALL Snd25_Ch1_61BB
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 1
	ATTEN 6
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 6
	OCTAVE 4
	NOTE D#, 1
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 6
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 1
	ATTEN 0
	SND_SEGNO
	SND_CALL Snd25_Ch1_61D1
	SND_REPEAT 7
	ATTEN 1
	SND_CALL Snd25_Ch1_61D1
	ATTEN 2
	SND_CALL Snd25_Ch1_61D1
	ATTEN 4
	SND_CALL Snd25_Ch1_61D1
	ATTEN 6
	SND_CALL Snd25_Ch1_61D1
	ATTEN 7
	SND_CALL Snd25_Ch1_61D1
	ATTEN 9
	SND_CALL Snd25_Ch1_61D1
	ATTEN $0A
	SND_CALL Snd25_Ch1_61D1
	SND_END

Snd25_Ch2:
	VOICE 1, $0D, 8, 1, 0
	ATTEN 4
	SND_CALL Snd25_Ch2_61E7
	ATTEN 6
	SND_CALL Snd25_Ch2_61E7
	ATTEN 7
	SND_CALL Snd25_Ch2_61E7
	ATTEN 9
	SND_CALL Snd25_Ch2_61E7
	ATTEN 2
	SND_CALL Snd25_Ch2_61E7
	SND_CALL Snd25_Ch2_61E7
	ATTEN 4
	SND_CALL Snd25_Ch2_61E7
	ATTEN 6
	SND_CALL Snd25_Ch2_61E7
	ATTEN 7
	SND_CALL Snd25_Ch2_61E7
	ATTEN 9
	SND_CALL Snd25_Ch2_61E7
	ATTEN 0
	SND_SEGNO
	SND_CALL Snd25_Ch2_61FB
	SND_REPEAT 7
	ATTEN 1
	SND_CALL Snd25_Ch2_61FB
	ATTEN 2
	SND_CALL Snd25_Ch2_61FB
	ATTEN 4
	SND_CALL Snd25_Ch2_61FB
	ATTEN 6
	SND_CALL Snd25_Ch2_61FB
	ATTEN 7
	SND_CALL Snd25_Ch2_61FB
	ATTEN 9
	SND_CALL Snd25_Ch2_61FB
	ATTEN $0A
	SND_CALL Snd25_Ch2_61FB
	SND_END

Snd25_Ch3:
	VOICE 1, 4, 6, 1, 0
	SND_SEGNO
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT 3
	SND_SEGNO
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_REPEAT 9
	PAN $FF
	ATTEN 0
	WAVE 9
	SND_SEGNO
	SND_CALL Snd25_Ch3_6212
	SND_REPEAT 7
	ATTEN 1
	SND_SEGNO
	SND_CALL Snd25_Ch3_6212
	SND_REPEAT 4
	SND_END

Snd25_SfxN:
	NVOICE 1, 1, 1
	NOISE $11
	NVOICE $0A, 6, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 4, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 6, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 7, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 6, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 7, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 9, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NVOICE $0A, 6, 7
	NOISE $72
	NVOICE $0A, $0F, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $71
	NOISE $72
	NVOICE $0A, $0C, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $71
	NOISE $72
	NVOICE $0A, $0A, 7
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $71
	NOISE $72
	NVOICE $0A, 7, 7
	NOISE $71
	NVOICE $0A, 4, 7
	NOISE $72
	NVOICE $0A, 3, 7
	NOISE $72

Snd25_Drm:
	SND_END
Snd25_Ch1_61BB:
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET
Snd25_Ch1_61D1:
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_RET
Snd25_Ch2_61E7:
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_RET
Snd25_Ch2_61FB:
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	SND_RET
Snd25_Ch3_6212:
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	REST 6
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	REST 4
	SND_RET

Snd0B_Sfx1:
	VOICE 1, $0F, 0, 1, 0
	ATTEN 2
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	TRANSPOSE_DOWN 6
	SND_CALL Snd0B_Sfx1_625B
	REST 3
	TRANSPOSE_UP 0
	SND_CALL Snd0B_Sfx1_625B
	VOICE 1, 6, 0, 1, 0
	REST 2
	SND_CALL Snd0B_Sfx1_625B
	REST 2
	TRANSPOSE_UP 1
	ATTEN 1
	SND_CALL Snd0B_Sfx1_625B
	REST 2
	TRANSPOSE_UP 2
	ATTEN 2
	SND_CALL Snd0B_Sfx1_625B
	REST 2
	TRANSPOSE_UP 4
	ATTEN 4
	SND_CALL Snd0B_Sfx1_625B
	SND_END
Snd0B_Sfx1_625B:
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_RET

Snd2C_Sfx2:
	VOICE 3, $0F, 8, 1, $0F
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 6
	SND_END

Snd0C_Sfx1:
	VOICE 1, $0C, 0, 8, 6
	OCTAVE 6
	NOTE C#, 1
	ATTEN 4
	OCTAVE 5
	NOTE G#, 1
	VOICE 1, 9, 4, 8, 6
	NOTE F#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	VOICE 1, 5, 4, 8, 6
	ATTEN 2
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 3
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 4
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE D#, 1
	SND_END

Snd0D_Sfx1:
	VOICE 1, $0C, 4, 6, $0F
	OCTAVE 6
	NOTE F_, 1
	ATTEN 2
	OCTAVE 5
	NOTE F_, 1
	ATTEN 4
	SND_CALL Snd0D_Sfx1_62BB
	ATTEN 6
	SND_CALL Snd0D_Sfx1_62BB
	ATTEN 7
	SND_CALL Snd0D_Sfx1_62BB
	ATTEN $0A
	SND_CALL Snd0D_Sfx1_62BB
	SND_END
Snd0D_Sfx1_62BB:
	SND_SEGNO
	OCTAVE 5
	NOTE A_, 1
	NOTE G#, 3
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 3
	SND_REPEAT 2
	SND_RET

Snd0E_Sfx1:
	VOICE 1, $0A, 4, 1, $0F
	OCTAVE 6
	NOTE B_, 1
	NOTE A_, 1
	REST 1
	VOICE 1, 9, 8, 1, $0F
	ATTEN 4
	OCTAVE 6
	NOTE B_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A#, 1
	ATTEN 6
	OCTAVE 6
	NOTE B_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 7
	OCTAVE 6
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 8
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd13_Ch1:
	TEMPO $00
	VOICE 1, $0F, 8, 0, 0
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 4
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 5
	NOTE G_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 6
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 7
	NOTE D#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 9
	NOTE G#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	ATTEN $0A
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D#, 1
	SND_END

Snd13_Ch2:
	VOICE 2, $0B, 8, 6, 9
	OCTAVE 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 1
	SND_CALL Snd13_Ch2_6375
	ATTEN 4
	SND_CALL Snd13_Ch2_6375
	ATTEN 6
	SND_CALL Snd13_Ch2_6375
	ATTEN 9
	SND_CALL Snd13_Ch2_6375
	ATTEN $0A
	SND_CALL Snd13_Ch2_6375
	SND_END
Snd13_Ch2_6375:
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE C#, 1
	NOTE D#, 1
	NOTE G#, 1
	REST 2
	SND_RET

Snd13_SfxN:
	NVOICE 1, $0D, 7
	NOISE $44
	NVOICE $0A, $0A, 7
	NOISE $72
	NOISE $71
	NVOICE $44, 9, 7
	NOISE $72
	SND_END

Snd13_Ch3:
	SND_END

Snd0F_Sfx1:
	TRANSPOSE_DOWN 1
	VOICE 1, 8, 4, 0, 0
	OCTAVE 5
	NOTE B_, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_SEGNO
	DUTY 4
	NOTE B_, 1
	DUTY 0
	NOTE B_, 1
	SND_REPEAT $0F
	ATTEN 4
	SND_SEGNO
	DUTY 4
	NOTE B_, 1
	DUTY 0
	NOTE B_, 1
	SND_REPEAT 3
	ATTEN 6
	SND_SEGNO
	DUTY 4
	NOTE B_, 1
	DUTY 0
	NOTE B_, 1
	SND_REPEAT 3
	SND_END

Snd12_Sfx1:
	VOICE 1, $0E, 0, 4, $0F
	SND_CALL Snd12_Sfx1_63EF
	NOTE B_, 1
	VOICE 1, $0C, 0, $0A, $0F
	ATTEN 4
	SND_CALL Snd12_Sfx1_63FC
	ATTEN 6
	SND_CALL Snd12_Sfx1_63FC
	ATTEN 7
	SND_CALL Snd12_Sfx1_63FC
	ATTEN 9
	SND_CALL Snd12_Sfx1_63FC
	SND_END

Snd12_Sfx2:
	VOICE 1, $0E, 0, 4, $0F
	OCTAVE 2
	NOTE C_, 1
	SND_CALL Snd12_Sfx1_63EF
	ATTEN 2
	SND_CALL Snd12_Sfx2_640A
	ATTEN 4
	SND_CALL Snd12_Sfx2_640A
	ATTEN 6
	SND_CALL Snd12_Sfx2_640A
	ATTEN 9
	SND_CALL Snd12_Sfx2_640A
	SND_END
Snd12_Sfx1_63EF:
	OCTAVE 2
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_RET
Snd12_Sfx1_63FC:
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	SND_RET
Snd12_Sfx2_640A:
	OCTAVE 6
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE D#, 1
	REST 2
	SND_RET

Snd11_Sfx1:
	VOICE 1, $0E, 0, 6, 9
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	VOICE 1, $0A, 0, 6, 9
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_END

Snd10_Sfx1:
	VOICE 1, $0E, 0, 1, 0
	OCTAVE 4
	NOTE A_, 1
	ATTEN 2
	OCTAVE 5
	NOTE A_, 1
	VOICE 1, 8, 0, 1, 0
	SND_SEGNO
	ATTEN 4
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	SND_REPEAT 2
	LEN_UNIT 3
	OCTAVE 6
	NOTE A_, 1
	NOTE C#, 1
	ATTEN 7
	OCTAVE 6
	NOTE A_, 1
	NOTE C#, 1
	OCTAVE 6
	NOTE A_, 1
	NOTE A_, 1
	SND_END

Snd14_Ch2:
	TEMPO $00
	VOICE 1, $0A, 4, 8, 6
	VIBRATO 1
	ATTEN 0
	SND_CALL Snd14_Ch1_64C5
	ATTEN 1
	SND_CALL Snd14_Ch1_64C5
	ATTEN 2
	SND_CALL Snd14_Ch1_64C5
	ATTEN 3
	SND_CALL Snd14_Ch1_64C5
	ATTEN 4
	SND_CALL Snd14_Ch1_64C5
	ATTEN 5
	SND_CALL Snd14_Ch1_64C5
	ATTEN 6
	SND_CALL Snd14_Ch1_64C5
	ATTEN 7
	SND_CALL Snd14_Ch1_64C5
	SND_END

Snd14_Ch1:
	VOICE 4, 4, 4, 8, 6
	REST 4
	VIBRATO 1
	VOICE 1, 4, 4, 8, 6
	ATTEN 0
	SND_CALL Snd14_Ch1_64C5
	ATTEN 0
	SND_CALL Snd14_Ch1_64C5
	ATTEN 1
	SND_CALL Snd14_Ch1_64C5
	ATTEN 1
	SND_CALL Snd14_Ch1_64C5
	ATTEN 2
	SND_CALL Snd14_Ch1_64C5
	ATTEN 2
	SND_CALL Snd14_Ch1_64C5
	ATTEN 3
	SND_CALL Snd14_Ch1_64C5
	ATTEN 3
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, $0A
	SND_END

Snd14_Ch3:
	VOICE 6, 2, 4, 8, 6
	VIBRATO 7
	OCTAVE 3
	ATTEN 0
	NOTE C#, 6
	NOTE C#, 6
	NOTE C#, 6
	ATTEN 1
	NOTE C#, 6
	NOTE C#, 6
	NOTE C#, 6
	NOTE C#, 6
	NOTE C#, 6
	SND_END
Snd14_Ch1_64C5:
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	LEN_UNIT 2
	NOTE A_, $0C
	LEN_UNIT 1
	SND_RET

Snd16_Sfx1:
	VOICE 3, $0A, 4, 1, 1
	OCTAVE 4
	NOTE A_, 1
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 1
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 1
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 2
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 4
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 6
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 7
	SND_CALL Snd16_Sfx1_64FF
	ATTEN 9
	SND_CALL Snd16_Sfx1_64FF
	SND_END
Snd16_Sfx1_64FF:
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE A_, 1
	SND_RET

Snd17_Sfx1:
	VOICE 1, $0C, 4, 6, 9
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE F#, 1
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE F_, 1
	ATTEN 6
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE E_, 1
	SND_END

Snd18_Sfx1:
	VOICE 1, $0C, 4, 6, 9
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
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 6
	SND_CALL Snd18_Sfx1_6557
	ATTEN 7
	SND_CALL Snd18_Sfx1_6557
	SND_END
Snd18_Sfx1_6557:
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	SND_RET

Snd19_Sfx1:
	VOICE 1, 9, 0, 1, $0F
	ATTEN 8
	OCTAVE 5
	NOTE F_, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	OCTAVE 6
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	VOICE 1, 9, 0, 2, $0F
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	ATTEN 6
	NOTE F_, 1
	NOTE C#, 1
	ATTEN 7
	NOTE D#, 1
	SND_END

Snd1A_Sfx1:
	VOICE 1, $0B, 0, 0, 0
	ATTEN $0A
	OCTAVE 6
	NOTE F#, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 5
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	DUTY 8
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_END

Snd1B_Sfx1:
	VOICE 1, $0F, 4, 8, 6
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 4
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	SND_REPEAT 2
	SND_END

Snd1B_SfxN:
	SND_CALL Snd1B_SfxN_663A
	SND_END

Snd1C_Sfx1:
	VOICE 1, $0F, 8, 1, 0
	OCTAVE 3
	NOTE A_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	SND_CALL Snd1C_Sfx1_6626
	VOICE 1, $0A, 8, 1, 0
	REST 4
	SND_CALL Snd1C_Sfx1_6631
	ATTEN 2
	SND_CALL Snd1C_Sfx1_6626
	ATTEN 4
	SND_CALL Snd1C_Sfx1_6631
	ATTEN 6
	SND_CALL Snd1C_Sfx1_6626
	ATTEN 7
	SND_CALL Snd1C_Sfx1_6631
	ATTEN 9
	SND_CALL Snd1C_Sfx1_6631
	SND_END

Snd1C_SfxN:
	SND_CALL Snd1B_SfxN_663A
	SND_END
Snd1C_Sfx1_6626:
	OCTAVE 3
	NOTE A_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	SND_RET
Snd1C_Sfx1_6631:
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 6
	NOTE C_, 1
	SND_RET
Snd1B_SfxN_663A:
	NVOICE 2, 2, 7
	NOISE $77
	NVOICE 1, $0C, 7
	NOISE $44
	NVOICE $12, 9, 7
	NOISE $73
	NVOICE 9, 6, 1
	NOISE $14
	NVOICE 9, 5, 1
	NOISE $24
	SND_RET

Snd1F_Sfx1:
	VOICE 1, $0C, 0, 6, 9
	OCTAVE 6
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE F_, 1
	NOTE C#, 1
	ATTEN 6
	NOTE F#, 1
	ATTEN 7
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 9
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN $0A
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	SND_END

Snd20_Sfx1:
	VOICE 1, 9, 8, 2, $0F
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE F#, 1
	SND_END

Snd21_Ch1:
	SND_END

Snd21_Drm:
	DRUM_UNIT $0C
	DRUM $0D, $0E
	DRUM $0D, 1
	DRUM $0D, $0F
	DRUM $0D, 8
	DRUM $0D, 1
	DRUM $0D, 8
	DRUM $0D, $0C
	DRUM $0D, 4
	DRUM $0D, 7
	DRUM $0D, 7
	SND_SEGNO
	REST $0F
	SND_REPEAT $FE

Snd22_SfxN:
	DRUM_UNIT 5
	DRUM $0C, 0
	DRUM 5, 5
	DRUM 5, 6
	DRUM 5, 7
	DRUM_UNIT 9
	DRUM $0A, 0
	DRUM 5, 5
	DRUM 5, 6
	DRUM 5, 7
	DRUM_UNIT 7
	DRUM 8, 0
	DRUM 7, 1
	DRUM 7, 2
	DRUM 7, 1
	DRUM_UNIT 8
	DRUM 6, 0
	DRUM 6, 2
	DRUM 6, 3
	DRUM 6, 4
	DRUM_UNIT 6
	DRUM 4, 0
	DRUM 5, 5
	DRUM 5, 3
	DRUM 5, 4
	DRUM_UNIT 4
	DRUM 4, 0
	DRUM 5, 3
	DRUM 5, 4
	DRUM 5, 5
	SND_END

Snd27_Sfx1:
	VOICE 1, $0D, 4, 6, 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 3
	OCTAVE 5
	NOTE A_, 1
	NOTE D#, 1
	VOICE 1, $0A, 8, 6, 9
	ATTEN 6
	SND_CALL Snd27_Sfx1_66F4
	SND_SEGNO
	ATTEN 7
	SND_CALL Snd27_Sfx1_66F4
	SND_REPEAT 2
	SND_SEGNO
	ATTEN 9
	SND_CALL Snd27_Sfx1_66F4
	SND_REPEAT 2
	SND_END
Snd27_Sfx1_66F4:
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	SND_RET

Snd28_Sfx1:
	VOICE 1, $0F, 0, 1, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	VOICE 1, $0D, 8, 1, $0F
	SND_CALL Snd27_Sfx1_66F4
	DUTY 4
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE D#, 1
	DUTY 8
	ATTEN 6
	SND_CALL Snd27_Sfx1_66F4
	ATTEN 7
	SND_CALL Snd27_Sfx1_66F4
	ATTEN 9
	SND_CALL Snd27_Sfx1_66F4
	ATTEN $0A
	SND_CALL Snd27_Sfx1_66F4
	SND_END

Snd28_SfxN:
	NVOICE 9, 6, 7
	NOISE $71
	NOISE $72
	NOISE $73
	SND_END

Snd24_Sfx1:
	VOICE 1, $0A, 4, 1, 0
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	SND_REPEAT $0E
	ATTEN 4
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 6
	SND_SEGNO
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 7
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 9
	SND_SEGNO
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	SND_END

Snd29_Sfx1:
	VOICE 1, 5, 8, 1, $0F
	OCTAVE 5
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 6
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 1
	OCTAVE 5
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 6
	NOTE C#, 1
	ATTEN 2
	NOTE C_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE F_, 1
	ATTEN 3
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	ATTEN 4
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	SND_END

Snd2B_Sfx1:
	VOICE 1, 9, 8, 8, 6
	SND_SEGNO
	SND_CALL Snd2B_Sfx1_67A5
	ATTEN 1
	SND_CALL Snd2B_Sfx1_67A5
	ATTEN 2
	SND_CALL Snd2B_Sfx1_67A5
	SND_REPEAT 6
	ATTEN 4
	SND_CALL Snd2B_Sfx1_67A5
	ATTEN 6
	SND_CALL Snd2B_Sfx1_67A5
	ATTEN 7
	SND_CALL Snd2B_Sfx1_67A5
	SND_END
Snd2B_Sfx1_67A5:
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	SND_RET

Snd2B_SfxN:
	SND_SEGNO
	SND_CALL Snd2B_SfxN_67BD
	SND_CALL Snd2B_SfxN_67BD
	SND_CALL Snd2B_SfxN_67BD
	SND_REPEAT 7
	SND_END
Snd2B_SfxN_67BD:
	NVOICE 2, 7, 7
	NOISE $71
	NVOICE 1, 7, 7
	NOISE $21
	NVOICE 2, 6, 7
	NOISE $71
	NVOICE 2, 2, 7
	NOISE $72
	SND_RET

; Sound table: 57 ids ($01-$39). The code indexes it as SoundTable - 2 + 2*id.
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

SndHdr08:
	SND_HEADER $04, $01 ; tracks: Sfx1
	dw Snd08_Sfx1

SndHdr09:
	SND_HEADER $04, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0A:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd0A_Sfx1

SndHdr0B:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $05, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $25, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr13:
	SND_HEADER $41, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd13_SfxN
	dw Snd13_Ch1
	dw Snd13_Ch2
	dw Snd13_Ch3

SndHdr0F:
	SND_HEADER $05, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr12:
	SND_HEADER $2F, $03 ; tracks: Sfx1, Sfx2
	dw Snd12_Sfx1
	dw Snd12_Sfx2

SndHdr11:
	SND_HEADER $20, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr10:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr14:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd14_Ch1
	dw Snd14_Ch2
	dw Snd14_Ch3

SndHdr15:
	SND_HEADER $30, $18 ; tracks: Ch1, Ch2
	dw Snd15_Ch1
	dw Snd15_Ch2

SndHdr16:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd1B_Sfx1
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd1D_SfxN
	dw Snd1D_Ch1
	dw Snd1D_Ch2
	dw Snd1D_Ch3
	dw Snd1D_Drm

SndHdr1E:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd1E_SfxN
	dw Snd1E_Ch1
	dw Snd1E_Ch2
	dw Snd1E_Ch3
	dw Snd1E_Drm

SndHdr1F:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $1F, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd21_Ch1
	dw Snd21_Ch1
	dw Snd21_Ch1
	dw Snd21_Drm

SndHdr22:
	SND_HEADER $40, $04 ; tracks: SfxN
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $15, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd25_SfxN
	dw Snd25_Ch1
	dw Snd25_Ch2
	dw Snd25_Ch3
	dw Snd25_Drm

SndHdr26:
	SND_HEADER $30, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd26_SfxN
	dw Snd26_Ch1
	dw Snd26_Ch2
	dw Snd26_Ch3

SndHdr27:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd28_Sfx1
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $10, $01 ; tracks: Sfx1
	dw Snd29_Sfx1

SndHdr2A:
	SND_HEADER $10, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd2A_Sfx1
	dw Snd2A_Sfx2
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $10, $05 ; tracks: Sfx1, SfxN
	dw Snd2B_Sfx1
	dw Snd2B_SfxN

SndHdr2C:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd2C_Sfx2

SndHdr2D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2D_Ch1
	dw Snd2D_Ch2
	dw Snd2D_Ch3
	dw Snd2D_Drm

SndHdr2E:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd2E_Ch1
	dw Snd2E_Ch2
	dw Snd2E_Ch3

SndHdr2F:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd2F_Ch1
	dw Snd2F_Ch2
	dw Snd2F_Ch3

SndHdr30:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd30_Ch1
	dw Snd30_Ch2
	dw Snd30_Ch3

SndHdr31:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd31_Ch1
	dw Snd31_Ch2
	dw Snd31_Ch3

SndHdr32:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd32_Ch1
	dw Snd32_Ch2
	dw Snd32_Ch3

SndHdr33:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd33_Ch1
	dw Snd33_Ch2
	dw Snd33_Ch3
	dw Snd33_Drm

SndHdr34:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd34_Ch1
	dw Snd34_Ch2
	dw Snd34_Ch3
	dw Snd34_Drm

SndHdr35:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd35_Ch1
	dw Snd35_Ch2
	dw Snd35_Ch3
	db $66, $6E

SndHdr36:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd36_Ch1
	dw Snd36_Ch2
	dw Snd36_Ch3

SndHdr37:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd37_Ch1
	dw Snd37_Ch2
	dw Snd37_Ch3

SndHdr38:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd38_Ch1
	dw Snd38_Ch2
	dw Snd38_Ch3
	dw Snd38_Drm

SndHdr39:
	SND_HEADER $50, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd39_Ch1
	dw Snd39_Ch2
	dw Snd39_Ch3

; Drum map: DRUM n plays sound DrumMap[n-1] (13 entries; 13 = sound $22).
DrumMap:
	db $01, $02, $01, $03, $03, $03, $03, $04, $05, $06, $07, $07, $22

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
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd06_Sfx1
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd07_SfxN

Snd01_SfxN:
	NVOICE 1, 7, 1
	NOISE $01
	SND_END

Snd02_SfxN:
	NVOICE 1, 6, 1
	NOISE $40
	SND_END

Snd03_SfxN:
	NVOICE 1, 4, 1
	NOISE $40
	NVOICE $40, 7, 4
	NOISE $00
	SND_END

Snd04_SfxN:
	NVOICE 1, 7, 1
	NOISE $40
	NVOICE 8, 4, 7
	NOISE $10
	SND_END

Snd05_SfxN:
	NVOICE 1, 7, 1
	NOISE $36
	NOISE $23
	SND_END

Snd06_Sfx1:
	VOICE 2, 7, 8, 1, 7
	VOICE 9, 1, 6, 4, 1
	SND_END

Snd06_SfxN:
	NVOICE 1, 8, $0C
	NOISE $68
	OCTAVE 3
	NOISE $A1
	NOISE $71
	NOISE $41
	OCTAVE 2
	NOISE $91
	NOISE $61
	NOISE $21
	OCTAVE 1
	NOISE $71
	SND_END

Snd07_SfxN:
	NVOICE 1, $0D, 1
	NOISE $01
	SND_END

; CH3 waves 1-10.
WaveTable:
	dw Wave1
	dw Wave2
	dw Wave3
	dw Wave4
	dw Wave5
	dw Wave6
	dw Wave7
	dw Wave8
	dw Wave9
	dw Wave10
Wave1:
	db $88, $88, $8F, $F8, $80, $00, $88, $88, $FF, $F8, $00, $88, $88, $FF, $88, $00
Wave2:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
Wave4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
Wave5:
	db $23, $44, $55, $67, $89, $9A, $BB, $CD, $23, $56, $78, $9A, $CD, $CA, $98, $53
Wave6:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
Wave7:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
Wave8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
Wave9:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
Wave10:
	db $CB, $AA, $CD, $B7, $89, $63, $64, $54, $CB, $AA, $CD, $B7, $89, $63, $64, $54

Snd35_Ch1:
	SND_CALL Snd35_Ch1_6AFD
	VIBRATO 3
	VOICE 6, 5, 4, 2, $0C
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	RELEASE 2, 8
	NOTE F_, 3
	NOTE A#, 3
	RELEASE 4, 7
	OCTAVE 4
	NOTE D_, 4
	RELEASE 3, $0A
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	SND_CALL Snd35_Ch1_6AFD
	VOICE 6, 6, 4, 2, $0C
	OCTAVE 3
	NOTE G_, 2
	RELEASE 2, $0D
	NOTE G_, 1
	RELEASE 7, 6
	NOTE C_HI, $0F
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	SND_CALL Snd35_Ch1_6B12
	VOICE 6, 6, 4, 4, $0F
	NOTE G_, 2
	NOTE A_, 1
	RELEASE 4, $0C
	NOTE B_, 3
	ATTEN 1
	RELEASE 4, $0F
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 1
	RELEASE 7, $0C
	NOTE B_, 7
	ATTEN 0
	SND_CALL Snd35_Ch1_6B12
	VOICE 6, 6, 4, 4, $0F
	NOTE F_, 2
	NOTE F_, 1
	RELEASE 4, $0C
	NOTE G_, 3
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 3
	RELEASE 3, $0C
	NOTE G_, 2
	NOTE D_, 2
	SND_JUMP Snd35_Ch1
Snd35_Ch1_6AFD:
	VOICE 6, 4, 8, 2, $0F
	SND_SEGNO
	OCTAVE 4
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	SND_REPEAT 5
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_RET
Snd35_Ch1_6B12:
	VIBRATO 4
	VOICE 1, 3, 4, 3, 2
	OCTAVE 3
	NOTE A#, 9
	OCTAVE 4
	NOTE D#, 3
	VOICE 6, 3, 4, 3, 2
	NOTE G_, 2
	NOTE D#, 3
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE G_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	VOICE 1, 3, 4, 3, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE F_, 3
	VOICE 6, 3, 4, 3, 2
	NOTE A_, 3
	NOTE F_, 2
	NOTE C_, 4
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	VOICE 1, 3, 4, 3, 2
	OCTAVE 4
	NOTE C_, 3
	NOTE F_, 3
	VOICE 6, 3, 4, 3, 2
	NOTE A_, 2
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 1
	VIBRATO 0
	RELEASE 3, $0C
	SND_RET

Snd35_Ch2:
	TEMPO $20
Snd35_Ch2_6B52:
	SND_CALL Snd35_Ch2_6BB3
	VIBRATO 3
	ATTEN 1
	RELEASE 2, $0B
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE 2, 6
	NOTE D_, 3
	NOTE F_, 3
	RELEASE 4, 6
	NOTE A#, 4
	RELEASE 3, $0A
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	ATTEN 0
	SND_CALL Snd35_Ch2_6BB3
	ATTEN 1
	VIBRATO 3
	RELEASE 2, $0D
	OCTAVE 4
	NOTE C_, 2
	RELEASE 3, $0C
	NOTE F_, 1
	RELEASE 7, 6
	NOTE E_, $0F
	ATTEN 5
	NOTE E_, 2
	ATTEN 0
	SND_CALL Snd35_Ch2_6BC7
	RELEASE 4, $0F
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 1
	VIBRATO $0A
	RELEASE 4, $0C
	NOTE D_, 3
	VIBRATO 3
	PAN $F0
	VOICE 6, 9, 4, 4, $0F
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 1
	RELEASE 7, $0C
	NOTE D_, 7
	PAN $FF
	SND_CALL Snd35_Ch2_6BC7
	RELEASE 4, $0F
	OCTAVE 4
	NOTE C_HI, 2
	NOTE C_HI, 1
	RELEASE 4, $0C
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	RELEASE 3, $0C
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	SND_JUMP Snd35_Ch2_6B52
Snd35_Ch2_6BB3:
	VIBRATO 6
	VOICE 6, 8, 4, 7, 9
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE F_, 8
	RELEASE 2, 6
	NOTE A#, 3
	NOTE F_, 3
	NOTE A#, 2
	NOTE G_, 3
	RELEASE 7, $0C
	NOTE C_, 9
	SND_RET
Snd35_Ch2_6BC7:
	VOICE 1, 7, 4, 2, $0C
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE D#, 3
	VOICE 6, 7, 4, 3, $0A
	NOTE G_, 2
	NOTE D#, 3
	RELEASE 5, $0A
	OCTAVE 3
	NOTE A#, 4
	RELEASE 3, $0A
	OCTAVE 4
	NOTE G_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	SND_SEGNO
	VOICE 1, 7, 4, 2, $0C
	OCTAVE 4
	NOTE C_, 3
	NOTE F_, 3
	VOICE 6, 7, 4, 3, $0A
	NOTE A_, 2
	NOTE F_, 3
	RELEASE 5, $0A
	NOTE C_, 4
	RELEASE 3, $0A
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	SND_REPEAT 2
	SND_RET

Snd35_Ch3:
	SND_CALL Snd35_Ch3_6C79
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE C_, 1
	SND_CALL Snd35_Ch3_6C79
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_CALL Snd35_Ch3_6C90
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	PAN $0F
	OCTAVE 2
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_CALL Snd35_Ch3_6C90
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE G_, 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	PAN $0F
	OCTAVE 2
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_JUMP Snd35_Ch3
Snd35_Ch3_6C79:
	VOICE 6, 2, 7, 4, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	PAN $F0
	NOTE C_HI, 1
	PAN $FF
	NOTE C_, 2
	NOTE C_, 1
	PAN $0F
	NOTE C_HI, 1
	PAN $FF
	NOTE C_, 1
	SND_REPEAT 7
	SND_RET
Snd35_Ch3_6C90:
	SND_SEGNO
	OCTAVE 2
	NOTE D#, 2
	PAN $F0
	OCTAVE 3
	NOTE D#, 1
	PAN $FF
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 1
	PAN $0F
	OCTAVE 3
	NOTE D#, 1
	PAN $FF
	OCTAVE 2
	NOTE D#, 1
	SND_REPEAT 4
	SND_RET

Snd33_Ch1:
	VOICE 6, 4, 0, 3, 4
	VIBRATO 4
	OCTAVE 3
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
Snd33_Ch1_6CFF:
	SND_SEGNO
	VIBRATO $0B
	VOICE $0D, 5, 4, 0, 0
	OCTAVE 3
	NOTE G_, $0C
	VOICE 3, 5, 4, 7, 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	VIBRATO $0C
	NOTE C_HI, 8
	VOICE $0D, 5, 4, 0, 0
	VIBRATO $0B
	OCTAVE 3
	NOTE A_, $0C
	VOICE 3, 5, 4, 7, 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VIBRATO $0C
	OCTAVE 4
	NOTE D_, 8
	SND_REPEAT 2
	SND_JUMP Snd33_Ch1_6CFF

Snd33_Ch2:
	TEMPO $10
	VOICE 6, 7, 4, 1, $0D
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	SND_REPEAT 2
Snd33_Ch2_6D6D:
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_JUMP Snd33_Ch2_6D6D

Snd33_Ch3:
	VIBRATO $0C
	VOICE 6, 2, 7, 7, 4
	OCTAVE 3
	NOTE C_, $0A
	RELEASE 7, $0F
	NOTE C_, 3
	NOTE C_, 2
	RELEASE 3, $0F
	NOTE C_, 1
	RELEASE 7, 6
	NOTE C_, $0A
	RELEASE 7, $0F
	NOTE C_, 3
	NOTE C_, 2
	RELEASE 3, $0F
	NOTE C_, 1
	RELEASE 7, 6
	NOTE D_, $0A
	RELEASE 7, $0F
	NOTE D_, 3
	NOTE D_, 2
	RELEASE 3, $0F
	NOTE D_, 1
	RELEASE 7, 6
	NOTE D_, $0A
	RELEASE 7, $0F
	NOTE D_, 3
	NOTE D_, 2
	RELEASE 3, $0F
	NOTE D_, 1
Snd33_Ch3_6E00:
	VOICE 6, 2, 2, 3, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	SND_REPEAT 2
	SND_SEGNO
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	PAN $0F
	NOTE C_, 1
	PAN $FF
	NOTE C_HI, 1
	PAN $F0
	NOTE C_, 1
	PAN $FF
	NOTE C_HI, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	PAN $0F
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	OCTAVE 3
	NOTE D_, 1
	PAN $F0
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 2
	SND_JUMP Snd33_Ch3_6E00

Snd33_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, $0A
	DRUM $0B, 3
	DRUM 9, 2
	DRUM 9, 1
	SND_REPEAT 3
	DRUM $0B, $0B
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
Snd33_Drm_6E75:
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 7, 2
	SND_REPEAT 4
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	SND_REPEAT 4
	SND_JUMP Snd33_Drm_6E75

Snd34_Ch1:
	TEMPO $34
	VIBRATO 4
Snd34_Ch1_6E99:
	VOICE 6, 6, 0, 4, $0F
	SND_CALL Snd34_Ch1_6EC8
	TRANSPOSE_DOWN 1
	SND_CALL Snd34_Ch1_6EC8
	TRANSPOSE_UP 0
	SND_CALL Snd34_Ch1_6EC8
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_REPEAT 4
	SND_JUMP Snd34_Ch1_6E99
Snd34_Ch1_6EC8:
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	PAN $F0
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	PAN $FF
	SND_REPEAT 4
	SND_RET

Snd34_Ch2:
	SND_CALL Snd34_Ch2_6F0D
	TRANSPOSE_DOWN 1
	SND_CALL Snd34_Ch2_6F0D
	TRANSPOSE_UP 0
	SND_CALL Snd34_Ch2_6F0D
	RELEASE 4, 8
	ATTEN 1
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_REPEAT 4
	SND_JUMP Snd34_Ch2
Snd34_Ch2_6F0D:
	SND_SEGNO
	ATTEN 0
	VOICE 6, $0A, 4, 4, $0A
	OCTAVE 3
	NOTE C_HI, 2
	ATTEN 1
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 5
	NOTE C_HI, 2
	NOTE A#, 2
	PAN $F0
	ATTEN 6
	NOTE C_HI, 2
	NOTE A#, 2
	PAN $FF
	SND_REPEAT 4
	SND_RET

Snd34_Ch3:
	VOICE 6, 2, 8, 6, $0F
	ATTEN 1
Snd34_Ch3_6F2B:
	SND_CALL Snd34_Ch3_6F56
	TRANSPOSE_DOWN 1
	SND_CALL Snd34_Ch3_6F56
	TRANSPOSE_UP 0
	SND_CALL Snd34_Ch3_6F56
	SND_SEGNO
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 2
	NOTE G_, 1
	NOTE B_, 2
	ATTEN 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_REPEAT 4
	SND_JUMP Snd34_Ch3_6F2B
Snd34_Ch3_6F56:
	SND_SEGNO
	OCTAVE 2
	NOTE C_HI, 1
	NOTE C_, 1
	PAN $0F
	NOTE F_, 1
	PAN $FF
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	PAN $F0
	NOTE C_HI, 1
	PAN $FF
	NOTE C_, 1
	PAN $0F
	NOTE F_, 1
	PAN $FF
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	PAN $F0
	NOTE C_HI, 1
	PAN $FF
	NOTE C_, 1
	SND_REPEAT 4
	SND_RET

Snd34_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	SND_REPEAT $0C
	SND_SEGNO
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	SND_REPEAT 3
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 1
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 6
	DRUM $0B, 6
	SND_JUMP Snd34_Drm

Snd37_Ch1:
	VOICE 6, 4, 4, 1, 4
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
	NOTE C_HI, 1
	SND_CALL Snd37_Ch1_7004
	SND_CALL Snd37_Ch1_7004
	SND_CALL Snd37_Ch1_7004
	VOICE 6, 3, 4, 1, 4
	VIBRATO 4
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	ATTEN 1
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	VIBRATO 0
	VOICE 6, 3, 4, 2, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	ATTEN 1
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	SND_END
Snd37_Ch1_7004:
	VOICE 6, 4, 4, 1, 4
	VIBRATO 4
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	VIBRATO 0
	VOICE 6, 6, 4, 2, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	SND_RET

Snd37_Ch2:
	TEMPO $04
	VOICE 6, 9, 0, 2, $0F
	ATTEN 2
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
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_CALL Snd37_Ch2_707E
	SND_CALL Snd37_Ch2_707E
	SND_CALL Snd37_Ch2_707E
	ATTEN 1
	RELEASE 1, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	ATTEN 2
	RELEASE 1, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 4
	ATTEN 3
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 2
	ATTEN 4
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 2
	ATTEN 5
	RELEASE 1, $0F
	SND_SEGNO
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_REPEAT 2
	ATTEN 6
	RELEASE 1, $0F
	SND_SEGNO
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_REPEAT 2
	SND_END
Snd37_Ch2_707E:
	RELEASE 1, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	ATTEN 1
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 4
	RELEASE 1, $0F
	ATTEN 0
	SND_SEGNO
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_REPEAT 4
	SND_RET

Snd37_Ch3:
	VOICE 6, 4, 8, 3, $0F
	OCTAVE 2
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
	NOTE C_HI, 1
	SND_CALL Snd37_Ch3_70D1
	SND_CALL Snd37_Ch3_70D1
	SND_CALL Snd37_Ch3_70D1
	RELEASE 2, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	SND_REPEAT 4
	ATTEN 1
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	SND_REPEAT 8
	ATTEN 2
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	SND_REPEAT 4
	SND_END
Snd37_Ch3_70D1:
	RELEASE 2, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	SND_REPEAT $10
	SND_RET

Snd36_Ch1:
	VOICE 6, 4, 4, 1, 4
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
	NOTE C_HI, 1
Snd36_Ch1_70ED:
	VOICE 6, 4, 4, 1, 4
	VIBRATO 4
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	VIBRATO 0
	VOICE 6, 6, 4, 2, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	SND_JUMP Snd36_Ch1_70ED

Snd36_Ch2:
	TEMPO $04
	VOICE 6, 9, 0, 2, $0F
	ATTEN 2
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
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
Snd36_Ch2_7124:
	RELEASE 1, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_REPEAT 8
	ATTEN 1
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 4
	RELEASE 1, $0F
	ATTEN 0
	SND_SEGNO
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_REPEAT 4
	SND_JUMP Snd36_Ch2_7124

Snd36_Ch3:
	VOICE 6, 4, 8, 3, $0F
	PAN $0F
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $F0
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN $FF
	RELEASE 2, $0F
Snd36_Ch3_7161:
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	SND_JUMP Snd36_Ch3_7161

Snd38_Ch1:
	TEMPO $84
	PAN $F0
	VIBRATO 4
	VOICE 6, 3, 4, $0F, 0
	OCTAVE 3
	NOTE G_, 9
	PAN $FF
	VOICE 1, 3, 4, $0F, 0
	NOTE G_, 3
	NOTE G#, 3
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE C#, 3
	NOTE D_, 3
	PAN $0F
	NOTE D#, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	VOICE 6, 3, 4, 7, 4
	NOTE G_, $0F
	VIBRATO 0
	PAN $FF
Snd38_Ch1_71A0:
	SND_CALL Snd38_Ch1_7211
	RELEASE 4, 8
	OCTAVE 4
	NOTE E_, 4
	VIBRATO 4
	PAN $F0
	ATTEN 1
	RELEASE 2, $0F
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	VIBRATO 0
	PAN $FF
	ATTEN 0
	SND_CALL Snd38_Ch1_7211
	OCTAVE 4
	NOTE E_, 2
	PAN $0F
	RELEASE 5, $0C
	NOTE D_, 3
	NOTE C#, 3
	PAN $FF
	RELEASE 4, $0F
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 3, $0F
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 4, $0F
	NOTE E_, 2
	RELEASE 3, $0F
	NOTE D_, 1
	RELEASE 4, $0F
	NOTE C#, 2
	RELEASE 5, $0C
	OCTAVE 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE E_, 2
	VOICE 3, 7, 4, 1, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE C#, 1
	SND_JUMP Snd38_Ch1_71A0
Snd38_Ch1_7211:
	VOICE 6, 7, 4, 5, $0D
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	RELEASE 4, $0F
	NOTE A_, 2
	NOTE B_, 2
	RELEASE 5, $0D
	NOTE G_, 3
	NOTE C_, 3
	SND_RET

Snd38_Ch2:
	VIBRATO $0D
	PAN $0E
	VOICE 1, 6, 4, $0F, 0
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	VOICE 6, 7, 8, $0F, 0
	NOTE G_, 8
	PAN $FF
	VOICE 1, 7, 4, $0F, 0
	NOTE G#, 3
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	VOICE 6, 6, 4, 7, 4
	NOTE G_, $0F
	REST 1
	VIBRATO 0
Snd38_Ch2_725E:
	SND_CALL Snd38_Ch2_72AB
	RELEASE 4, 8
	OCTAVE 4
	NOTE G_, 3
	RELEASE 2, $0F
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_CALL Snd38_Ch2_72AB
	VIBRATO $0E
	RELEASE 7, 8
	OCTAVE 4
	NOTE G_, 8
	RELEASE 4, $0F
	NOTE F_, 1
	NOTE G_, 1
	RELEASE 3, $0F
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	RELEASE 4, $0F
	NOTE G_, 2
	RELEASE 3, $0F
	NOTE F_, 1
	RELEASE 4, $0F
	NOTE E_, 2
	RELEASE 3, $0F
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 4, $0F
	NOTE E_, 2
	RELEASE 3, $0F
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	RELEASE 5, $0D
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	VIBRATO $0F
	RELEASE 5, 8
	NOTE G#, 4
	NOTE A#, 4
	VIBRATO 0
	SND_JUMP Snd38_Ch2_725E
Snd38_Ch2_72AB:
	VOICE 6, 8, 4, 5, $0D
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 3
	RELEASE 4, $0F
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 5, $0D
	OCTAVE 3
	NOTE C_HI, 3
	NOTE G_, 3
	SND_RET

Snd38_Ch3:
	VOICE 4, 6, 7, 1, $0F
	OCTAVE 5
	NOTE G_, $0F
	REST $0F
	REST $0C
	REST 9
Snd38_Ch3_72CA:
	VOICE 6, 2, 8, 2, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
	VOICE 3, 2, 8, 1, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 2
	RELEASE 2, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 1
	SND_REPEAT 2
	SND_JUMP Snd38_Ch3_72CA

Snd38_Drm:
	DRUM_UNIT 4
	REST $0F
	REST $0F
	REST $0C
	REST 9
	DRUM_UNIT 6
Snd38_Drm_7358:
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_REPEAT $0F
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 4, 1
	SND_JUMP Snd38_Drm_7358

Snd39_Ch1:
	TRANSPOSE_DOWN 2
	TEMPO $10
	VOICE 6, 7, 4, 1, $0B
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_REPEAT 4
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	RELEASE 4, $0F
	NOTE E_, 4
	SND_END

Snd39_Ch2:
	TRANSPOSE_DOWN 2
	VOICE 6, 5, 8, 1, $0A
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 4
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	RELEASE 5, $0F
	NOTE C_HI, 4
	SND_END

Snd39_Ch3:
	TRANSPOSE_DOWN 2
	VOICE 6, 2, 7, 7, 8
	OCTAVE 3
	NOTE C_, 4
	RELEASE 6, $0F
	NOTE C_, 1
	NOTE C_, 1
	RELEASE 6, $0B
	NOTE C_, 3
	OCTAVE 2
	NOTE G_, 3
	RELEASE 7, 8
	OCTAVE 3
	NOTE E_, 4
	RELEASE 6, $0F
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 6, $0B
	NOTE E_, 3
	NOTE C_, 3
	RELEASE 7, 8
	NOTE G_, 4
	RELEASE 6, $0F
	NOTE G_, 1
	NOTE G_, 1
	RELEASE 6, $0B
	NOTE G_, 3
	NOTE C_, 3
	RELEASE 7, 8
	NOTE C_HI, 4
	RELEASE 6, $0F
	NOTE C_, 1
	NOTE C_, 1
	VIBRATO $0D
	RELEASE 7, 8
	NOTE C_, 4
	SND_END
