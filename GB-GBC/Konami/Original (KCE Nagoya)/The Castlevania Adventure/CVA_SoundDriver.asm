; ==========================================================================
; The Castlevania Adventure (E) - Konami sound driver (early GB version)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0  $0050-$0052  timer vector
;   ROM0  $0092-$00E3  timer ISR + far PlaySound wrapper
;   ROM0  $02EB-$034C  game pause toggle (calls SndPause / SndUnpause)
;   bank 2 $4000-$663E driver code, tables and sound data
; Build: rgbasm -Wall -o cva.o CVA_SoundDriver.asm && rgblink -o cva.gb cva.o
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
DEF wDrvLock EQU $C00B
DEF wPause EQU $C012
DEF wCurId EQU $C100
DEF wCurPrio EQU $C101
DEF wCurPtr EQU $C102
DEF wCurLen EQU $C104
DEF wCurFlags EQU $C105
DEF wCurLoopCnt EQU $C106
DEF wCurVib EQU $C107
DEF wCurTransp EQU $C108
DEF wCurAtten EQU $C109
DEF wCurVibOfs EQU $C10A
DEF wCurVibOfsHi EQU $C10B
DEF wCurUnit EQU $C10C
DEF wCurOctave EQU $C10D
DEF wCurPeriod EQU $C10E
DEF wCurPeriodHi EQU $C10F
DEF wCurVol EQU $C110
DEF wCurDuty EQU $C111
DEF wCurEnv EQU $C112
DEF wCurGate EQU $C113
DEF wCurRelTick EQU $C114
DEF wCurVibTimer EQU $C115
DEF wCurVibReload EQU $C116
DEF wCurCh3Timer EQU $C117
DEF wCurCh3Reload EQU $C118
DEF wCurCh3Level EQU $C11A
DEF wCurSegno EQU $C11B
DEF wCurSegnoHi EQU $C11C
DEF wCurRet EQU $C11D
DEF wCurRetHi EQU $C11E
DEF wCurVibPtr EQU $C11F
DEF wCurVibPtrHi EQU $C120
DEF wCurVibIdx EQU $C121
DEF wCurVibLoopIdx EQU $C122
DEF wCurVibLoopCnt EQU $C123
DEF wCurUnused24 EQU $C124
DEF wTrkSfx1 EQU $C125 ; 37 bytes
DEF wTrkSfxN EQU $C14A ; 37 bytes
DEF wTrkCh1 EQU $C16F ; 37 bytes
DEF wTrkCh2 EQU $C194 ; 37 bytes
DEF wTrkCh3 EQU $C1B9 ; 37 bytes
DEF wTrkDrm EQU $C1DE ; 37 bytes
DEF wShadow EQU $C228 ; 20 bytes
DEF wNR51 EQU $C23C
DEF wTempoAcc EQU $C23D
DEF wTempo EQU $C23E
DEF wTempoSkip EQU $C23F
DEF wReqId EQU $C240
DEF wReqPrio EQU $C241
DEF wRegIdx EQU $C242
DEF wRegVal EQU $C243
DEF wTrackIdx EQU $C244
DEF wRegBase EQU $C245
DEF wSweepVal EQU $C246
DEF wNoRestore EQU $C248
DEF wTrackPtr EQU $C24A
DEF wTickParity EQU $C24D
DEF rROMB EQU $2180 ; MBC1 bank select as written by this game
DEF hBankId EQU $7FFF ; every bank stores its own number in its last byte

; track flags (wCurFlags)
DEF TF_RELEASED EQU 0 ; release point reached
DEF TF_AUTOPAN EQU 1 ; swap NR51 halves on every note
DEF TF_VIBNEG EQU 3 ; negate vibrato offset (sticky)
DEF TF_FORCE EQU 6 ; write registers even if the shadow matches
DEF TF_REST EQU 7 ; current event is a rest

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

SECTION "Timer vector", ROM0[$0050]

TimerVector:
	jp TimerISR ; timer interrupt

SECTION "Sound ISR glue", ROM0[$0092]

; Timer interrupt (64 Hz: TAC = %111, TMA = 0). Re-enables interrupts at once.
; Skipped while wDrvLock bit 0 is set (PlaySoundFar running) - that tick is lost.
TimerISR:
	ei
	push af
	push bc
	push de
	push hl
	ld hl, wDrvLock
	bit 0, [hl]
	jr nz, .l00B5
	ld a, [hBankId] ; current bank (each bank holds its number at $7FFF)
	push af
	ld a, $02
	ld [rROMB], a
	set 0, [hl]
	call SndUpdate
	ld hl, wDrvLock
	res 0, [hl]
	pop af
	ld [rROMB], a
.l00B5:
	call $0AF0
	pop hl
	pop de
	pop bc
	pop af
	reti

; PlaySoundFar: A = sound id. Switches to bank 2 and calls PlaySound.
; If the driver is already locked (called from an interrupt that nested inside
; the timer ISR), the request is silently dropped.
PlaySoundFar:
	push bc
	push de
	push hl
	ld hl, wDrvLock
	bit 0, [hl]
	jr nz, .l00E0
	ld b, a
	ld a, [hBankId]
	push af
	ld a, $02
	ld [rROMB], a
	ld a, b
	set 0, [hl]
	call PlaySound
	ld hl, wDrvLock
	res 0, [hl]
	pop af
	ld [rROMB], a
.l00E0:
	pop hl
	pop de
	pop bc
	ret

SECTION "Pause glue", ROM0[$02EB]

; Game pause toggle (called each frame while the pause button logic runs).
; Not driver code, kept because it is the only user of SndPause/SndUnpause.
; Note the "pop hl" at .l0327/.l034B: they discard the return address on purpose,
; so the final ret returns from the caller as well.
PauseToggle:
	ld hl, wDrvLock
	bit 0, [hl]
	ret nz
	ld hl, $C41A
	bit 7, [hl]
	ld hl, wPause
	jr z, .l0348
	bit 1, [hl]
	ret nz
	bit 0, [hl]
	jr z, .l0325
	res 0, [hl]
	push hl
	ld hl, wDrvLock
	set 0, [hl]
	ld a, [hBankId]
	push af
	ld a, $02
	ld [rROMB], a
	xor a
	ld [wCurUnused24], a
	call SndUnpause
	pop af
	ld [rROMB], a
	ld hl, wDrvLock
	res 0, [hl]
	pop hl
	ret
.l0325:
	set 0, [hl]
	pop hl
	ld hl, wDrvLock
	set 0, [hl]
	ld a, [hBankId]
	push af
	ld a, $02
	ld [rROMB], a
	ld a, $01
	ld [wCurUnused24], a
	call SndPause
	pop af
	ld [rROMB], a
	ld hl, wDrvLock
	res 0, [hl]
	ret
.l0348:
	bit 0, [hl]
	ret z
	pop hl
	ret

SECTION "Sound driver", ROMX[$4000], BANK[2]

; Utility routines (NegateHL, SwapHLBC, CompareHLDE, AddAToDE are never called).
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
	push af
	ld a, l
	ld l, c
	ld c, a
	ld a, h
	ld h, b
	ld b, a
	pop af
	ret

SwapHLDE:
	push af
	ld a, l
	ld l, e
	ld e, a
	ld a, h
	ld h, d
	ld d, a
	pop af
	ret

CompareHLDE:
	ld a, h
	cp d
	ret nz
	ld a, l
	cp e
	ret

AddAToHL:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

AddAToDE:
	add a, e
	ld e, a
	ret nc
	inc d
	ret

LoadPtrFromTable:
	add a, a
	call AddAToHL
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

JumpTableInline:
	pop hl
	call LoadPtrFromTable
	jp hl

; SndInit: clear $C100-$C2FF, NR52 = NR51 = $FF, NR50 = $77.
SndInit:
	ld hl, wCurId
	ld de, wCurId + 1
	ld bc, $0200
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

; SndUpdate: one driver tick (called from TimerISR, 64 Hz).
; Tracks 0 (Sfx1) and 1 (SfxN) run on every tick. Tracks 2-5 (music) run on
; every 2nd tick (wTickParity odd), and are skipped on ticks where
; wTempoAcc += wTempo carried. While wPause != 0 only track 0 runs, and
; only if it is playing sound 5 (the pause jingle).
SndUpdate:
	xor a
	ld [wTempoSkip], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	jr nc, .l4071
	ld a, $01
	ld [wTempoSkip], a
.l4071:
	xor a
.l4072:
	ld [wTrackIdx], a
	ld a, [wPause]
	or a
	jr z, .l408B
	ld a, [wTrackIdx]
	cp $00
	jr nz, .l40C4
	ld a, [wTrkSfx1]
	cp $05
	jr z, .l40A6
	jr .l40CC
.l408B:
	ld a, [wTrackIdx]
	cp $02
	jr nz, .l40A6
	ld a, [wTickParity]
	inc a
	ld [wTickParity], a
	bit 0, a
	ret z
	ld a, [wPause]
	ld c, a
	ld a, [wTempoSkip]
	or c
	jr nz, .l40CC
.l40A6:
	ld a, [wTrackIdx]
	ld hl, TrackPtrTable ; TrackPtrTable
	call LoadPtrFromTable
	ld a, l
	ld [wTrackPtr], a
	ld a, h
	ld [wTrackPtr + $01], a
	ld a, [hl]
	or a
	jr z, .l40C4
	call LoadTrack
	call TrackTick
	call StoreTrack
.l40C4:
	ld a, [wTrackIdx]
	inc a
	cp $06
	jr nz, .l4072
.l40CC:
	ret

; TrackTick: one tick for the track in the working copy (wCur*).
TrackTick:
	call GetRegBase
	ld [wRegBase], a
	ld a, [wCurPtr]
	ld e, a
	ld a, [wCurPtr + $01]
	ld d, a
	ld hl, wCurLen
	dec [hl]
	jr nz, .l40FD
	ld a, [wCurFlags]
	and $7E
	ld [wCurFlags], a
	ld a, [wTrackIdx]
	cp $04
	jp nz, ReadCmds
	xor a
	ld bc, wShadow + $0A
	ld [bc], a
	ld bc, rNR30
	ld [bc], a
	jp ReadCmds
.l40FD:
	ld b, [hl]
	ld hl, wCurFlags
	ld a, [wCurRelTick]
	sub b
	jr c, .l4109
	set 0, [hl]
.l4109:
	bit 7, [hl]
	ret nz
	ld a, [wTrackIdx]
	cp $01
	ret z
	call VibratoTick
	ld a, [wTrackIdx]
	cp $04
	jr z, Ch3Decay
	ld hl, wCurLen
	ld a, [wCurRelTick]
	sub [hl]
	ret nz
	ld a, [wCurEnv]
	or a
	jr z, .l413B
	ld a, [wCurAtten]
	ld c, a
	ld a, [wCurVol]
	and $0F
	sub c
	swap a
	ld c, a
	ld a, [wCurEnv]
	or c
.l413B:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; Ch3Decay: CH3 has no envelope, so after the release point the driver steps
; the NR32 level code 1 -> 2 -> 3 -> 0 (100% -> 50% -> 25% -> off) every
; wCurCh3Reload ticks. Env = 0 cuts the channel at the release point.
Ch3Decay:
	ld a, [wCurFlags]
	bit 0, a
	ret z
	ld a, [wCurEnv]
	or a
	jr z, .l417B
	ld a, [wCurCh3Timer]
	dec a
	ld [wCurCh3Timer], a
	ret nz
	ld a, [wCurCh3Reload]
	ld [wCurCh3Timer], a
	ld a, [wCurCh3Level]
	or a
	jr z, .l417B
	inc a
	and $03
	ld [wCurCh3Level], a
	jr z, .l417B
	ld c, a
	ld a, [wCurAtten]
	add a, c
	cp $04
	jr c, .l417B
	xor a
.l417B:
	rla
	swap a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

; VibratoTick: advance the vibrato table every wCurVibReload ticks.
VibratoTick:
	ld a, [wCurVib]
	or a
	ret z
	ld a, [wCurVibTimer]
	dec a
	ld [wCurVibTimer], a
	ret nz
	ld a, [wCurVibReload]
	ld [wCurVibTimer], a
	call VibratoStep
	jp WritePeriod

ReadCmdsNext:
	inc de

; ReadCmds: execute commands until a note/rest (or $FF end).
; $FB-$FF are dispatched here, everything else in ReadCmdsLow.
ReadCmds:
	ld a, [de]
	cp $FB
	jp c, ReadCmdsLow
	inc de
	sub $FB
	call JumpTableInline
	dw Cmd_Segno
	dw Cmd_Ret
	dw Cmd_Call
	dw Cmd_Repeat
	dw Cmd_End

Cmd_Segno:
	ld a, e
	ld [wCurSegno], a
	ld a, d
	ld [wCurSegnoHi], a
	jr ReadCmds

Cmd_Ret:
	ld a, [wCurRet]
	ld e, a
	ld a, [wCurRetHi]
	ld d, a
	jr ReadCmds

Cmd_Call:
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de
	ld a, e
	ld [wCurRet], a
	ld a, d
	ld [wCurRetHi], a
	ld e, c
	ld d, b
	jr ReadCmds

Cmd_Repeat:
	ld a, [de]
	ld b, a
	cp $FF
	jr z, .l41F9
	ld a, [wCurLoopCnt]
	inc a
	cp b
	jr z, .l4203
	ld [wCurLoopCnt], a
	ld a, [wCurSegno]
	ld e, a
	ld a, [wCurSegnoHi]
	ld d, a
	jr ReadCmds
.l41F9:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l4203:
	xor a
	ld [wCurLoopCnt], a
	jr ReadCmdsNext

; $FF: end of track. Silence the channel (NRx2 = 0, NRx4 = $80). When the CH1
; SFX ends while music CH1 is active, restore music duty and clear NR10.
Cmd_End:
	xor a
	ld [wCurPrio], a
	ld [wCurId], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld a, $40
	ld [wCurFlags], a
	ld a, $80
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	call WriteReg
	ld a, [wTrackIdx]
	cp $00
	jr z, .l4237
	ret
.l4237:
	ld a, [wTrkCh1]
	or a
	ret z
	ld a, [wTrkCh1 + $11]
	ld [wCurDuty], a
	call WriteDuty
	xor a
	ld bc, rNR10
	ld [bc], a
	ret

; $E0: voice / $00-$DF: note / $F0-$FA: attenuation / $E1-$E6: octave /
; $E7-$EF: table
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
	ld a, [de]
	ld [wCurUnit], a
	jp ReadCmdsNext

Cmd_Release:
	ld a, [de]
	and $0F
	ld [wCurEnv], a
	ld a, [de]
	swap a
	and $0F
	ld [wCurGate], a
	jp ReadCmdsNext

Cmd_Sweep:
	ld a, [de]
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call WriteReg
	jp ReadCmdsNext

; $EA xy: extended commands, x = 0..4 (x >= 5 would jump into garbage).
Cmd_Ext:
	ld a, [de]
	and $F0
	swap a
	call JumpTableInline
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_Vibrato
	dw Ext_Duty
	dw Ext_AutoPan

Ext_TransposeUp:
	ld a, [de]
	and $0F
	ld [wCurTransp], a
	jp ReadCmdsNext

Ext_TransposeDown:
	ld a, [de]
	and $0F
	cpl
	inc a
	ld [wCurTransp], a
	jp ReadCmdsNext

Ext_Vibrato:
	ld a, [de]
	and $0F
	ld [wCurVib], a
	ld bc, VibratoTable
	dec a
	add a, a
	add a, c
	ld c, a
	jr nc, .l42DB
	inc b
.l42DB:
	ld a, [bc]
	ld [wCurVibPtr], a
	inc bc
	ld a, [bc]
	ld [wCurVibPtrHi], a
	jp ReadCmdsNext

Ext_Duty:
	ld a, [de]
	and $0F
	ld [wCurDuty], a
	call WriteDuty
	jp ReadCmdsNext

Ext_AutoPan:
	ld a, [de]
	and $0F
	or a
	ld a, [wCurFlags]
	jr z, .l4300
	or $02
	jr .l4302
.l4300:
	and $FD
.l4302:
	ld [wCurFlags], a
	jp ReadCmdsNext

Cmd_EB:
	jp ReadCmdsNext

Cmd_EC:
	jp ReadCmdsNext

Cmd_ED:
	jp ReadCmdsNext

Cmd_Tempo:
	ld a, [de]
	ld [wTempo], a
	jp ReadCmdsNext

; $EF: NR51 bits for this channel. Ignored on music CH1 while the CH1 SFX plays.
Cmd_Pan:
	ld a, [wTrackIdx]
	cp $02
	jr nz, .l4329
	ld a, [wTrkSfx1]
	or a
	jp nz, ReadCmdsNext
	ld a, [wTrackIdx]
.l4329:
	ld hl, PanMaskTable
	call AddAToHL
	ld a, [wNR51]
	and [hl]
	ld c, a
	ld a, [hl]
	cpl
	ld b, a
	ld a, [de] ; arg is nibble-swapped: lo -> left (bits 4-7)
	swap a
	and b
	or c
	ld [wNR51], a
	ld bc, rNR51
	ld [bc], a
	jp ReadCmdsNext
PanMaskTable:
	db $EE, $77, $EE, $DD, $BB, $FF

; AutoPanSwap: swap the L/R bits of this channel in NR51 (EA 4x = 1).
AutoPanSwap:
	ld a, [wNR51]
	swap a
	ld c, a
	ld a, [wTrackIdx]
	ld hl, PanMaskTable
	call AddAToHL
	ld a, [hl]
	cpl
	and c
	ld c, a
	ld a, [wNR51]
	and [hl]
	or c
	ld [wNR51], a
	ld hl, rNR51
	ld [hl], a
	ret

Cmd_Octave:
	ld a, [de]
	and $0F
	dec a
	ld [wCurOctave], a
	jp ReadCmdsNext

; $E0 unit [voice] [env/gate]. Drum track: unit only. Noise SFX: one byte
; written to NR42 with a retrigger. Others: vol/duty (+ WriteDuty) and env/gate.
Cmd_Voice:
	inc de
	ld a, [de]
	ld [wCurUnit], a
	ld a, [wTrackIdx]
	cp $05
	jp z, ReadCmdsNext
	inc de
	cp $01
	jr z, .l43AB
	ld a, [de]
	and $0F
	ld [wCurVol], a
	ld a, [de]
	swap a
	and $0F
	ld [wCurDuty], a
	call WriteDuty
	inc de
	ld a, [de]
	and $0F
	ld [wCurEnv], a
	ld a, [de]
	swap a
	and $0F
	ld [wCurGate], a
	jp ReadCmdsNext
.l43AB:
	ld a, [de]
	and $0F
	ld [wCurEnv], a
	ld a, [de]
	swap a
	and $0F
	ld [wCurVol], a
	ld a, [de]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	call Trigger
	jp ReadCmdsNext

; $F0-$FA: attenuation. On the noise SFX track it also rewrites NR42 + retrigger.
Cmd_Atten:
	ld a, [de]
	and $0F
	ld [wCurAtten], a
	ld b, a
	ld a, [wTrackIdx]
	cp $01
	jp nz, ReadCmdsNext
	ld a, [wCurVol]
	and $0F
	sub b
	swap a
	ld c, a
	ld a, [wCurEnv]
	or c
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	call Trigger
	jp ReadCmdsNext

; Noise SFX note: NR43 = byte, NR44 = 0 (no retrigger), length = unit.
NoiseNote:
	ld a, [wCurUnit]
	ld [wCurLen], a
	ld a, [de]
	ld l, a
	ld h, $00
	jp WritePeriodHL

; Note: length = (lo nibble) * unit; hi nibble 0 = rest; drum track plays a
; sound; otherwise pitch = (hi-1) + transpose + 12*octave -> PeriodTable.
Note:
	ld a, [wCurFlags]
	bit 1, a
	call nz, AutoPanSwap
	call SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $01
	jr z, NoiseNote
	ld a, [de]
	and $0F
	or a
	jr nz, .l441E ; dead branch (jr nz to the next instruction)
.l441E:
	ld b, a
	ld a, [wCurUnit]
	ld c, a
.l4423:
	dec b
	jr z, .l4429
	add a, c
	jr .l4423
.l4429:
	ld [wCurLen], a
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $05
	jp z, DrumNote
	ld a, [wCurGate]
	cp $0F
	jr nz, .l4447
	ld a, [wCurLen]
	dec a
	jr .l4458
.l4447:
	ld c, a
	ld b, $04
	ld a, [wCurLen]
	ld h, a
	xor a
.l444F:
	srl c
	jr nc, .l4454
	add a, h
.l4454:
	rra
	dec b
	jr nz, .l444F
.l4458:
	ld [wCurRelTick], a ; release tick = len * gate / 16 (gate $F: len - 1)
	xor a
	ld [wCurVibLoopCnt], a
	ld c, $00
	ld a, [wCurOctave]
	or a
	jr z, .l4470
	ld b, a
	ld c, $0C
	xor a
.l446B:
	add a, c
	dec b
	jr nz, .l446B
	ld c, a
.l4470:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld b, a
	ld a, [wCurTransp]
	add a, b
	add a, c
	ld c, a
	ld b, $00
	sla c
	rl b
	ld hl, PeriodTable ; PeriodTable
	add hl, bc
	ld a, [hl]
	ld [wCurPeriod], a
	inc hl
	ld a, [hl]
	ld [wCurPeriodHi], a
	ld a, [wCurVib]
	or a
	jp z, .l449E
	xor a
	ld [wCurVibIdx], a
	call VibratoStep
.l449E:
	call WritePeriod
	ld hl, wCurFlags
	bit 6, [hl]
	jr z, .l44AA
	res 6, [hl]
.l44AA:
	ld a, [wTrackIdx]
	cp $04
	jr z, .l44CB
	ld a, [wCurAtten]
	ld c, a
	ld a, [wCurVol]
	and $0F
	sub c
	swap a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger
.l44CB:
	ld a, $80
	ld bc, wShadow + $0A
	ld [bc], a
	ld bc, rNR30
	ld [bc], a
	ld a, [wCurEnv]
	ld [wCurCh3Timer], a
	ld [wCurCh3Reload], a
	ld a, [wCurVol]
	and $0F
	rra
	and $03
	ld [wCurCh3Level], a
	ld c, a
	ld a, [wCurAtten]
	add a, c
	cp $04
	jr c, .l44F3
	xor a
.l44F3:
	swap a
	rla
	and $F0
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; VibratoStep: read the next vibrato table entry ($FB loop point, $FE n repeat,
; $FF hold, else delay<<4 | neg<<3 | hi3, lo).
VibratoStep:
	ld hl, wCurVibPtr
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, [hl]
	add a, c
	ld c, a
	jr nc, .l4513
	inc b
.l4513:
	ld a, [bc]
	cp $FB
	jr z, .l4545
	cp $FE
	jr z, .l454D
	cp $FF
	jr z, .l456B
	swap a
	and $0F
	ld [wCurVibTimer], a
	ld [wCurVibReload], a
	ld a, [bc]
	bit 3, a
	jr z, .l4537
	ld a, [wCurFlags]
	set 3, a
	ld [wCurFlags], a
.l4537:
	ld a, [bc]
	and $07
	ld [wCurVibOfsHi], a
	inc [hl]
	inc bc
	ld a, [bc]
	ld [wCurVibOfs], a
	inc [hl]
	ret
.l4545:
	inc [hl]
	ld a, [hl]
	ld hl, wCurVibLoopIdx
	ld [hl], a
	jr VibratoStep
.l454D:
	inc bc
	ld a, [bc]
	ld hl, wCurVibLoopCnt
	cp [hl]
	jr z, .l4562
	cp $FF
	jr z, .l455A
	inc [hl]
.l455A:
	dec hl
	ld a, [hl]
	ld hl, wCurVibIdx
	ld [hl], a
	jr VibratoStep
.l4562:
	xor a
	ld [hl], a
	ld hl, wCurVibIdx
	inc [hl]
	inc [hl]
	jr VibratoStep
.l456B:
	ret

; WritePeriod: NRx3/NRx4 = base period + vibrato offset (no trigger).
WritePeriod:
	ld a, [wCurVibOfs]
	ld c, a
	ld a, [wCurVibOfsHi]
	ld b, a
	ld a, [wCurPeriod]
	ld l, a
	ld a, [wCurPeriodHi]
	ld h, a
	ld a, [wCurFlags]
	and $08
	jr z, .l458D
	ld a, b
	cpl
	ld b, a
	ld a, c
	cpl
	inc a
	jr nz, .l458C
	inc b
.l458C:
	ld c, a
.l458D:
	add hl, bc

WritePeriodHL:
	push hl
	ld a, l
	ld [wRegVal], a
	ld a, $03
	ld [wRegIdx], a
	call WriteReg
	pop hl
	ld a, h
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	jp WriteReg

SavePtr:
	inc de
	ld a, e
	ld [wCurPtr], a
	ld a, d
	ld [wCurPtr + $01], a
	ret

Rest:
	ld a, [wCurFlags]
	ld c, $C0
	or c
	ld [wCurFlags], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld a, $80
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	call WriteReg
	ret

DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap ; DrumMap
	call AddAToHL
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld a, [wCurDuty]
	jr z, .l45FD
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l45FD:
	push de
	ld hl, WaveTable ; WaveTable
	ld a, [wCurDuty]
	dec a
	add a, a
	call AddAToHL
	ld b, $10
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, _AUD3WAVERAM
.l4611:
	ld a, [de]
	ld [hl], a
	inc de
	inc hl
	dec b
	jr nz, .l4611
	pop de
	ret

; IsBlocked: carry = this is music CH1 (track 2) and the CH1 SFX is active.
IsBlocked:
	ld a, [wTrackIdx]
	cp $02
	jr nz, .l462A
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4628
.l4628:
	scf
	ret
.l462A:
	or a
	ret

; WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal, via the shadow at wShadow.
; Skipped when the shadow already holds the value, unless TF_FORCE is set.
WriteReg:
	call IsBlocked
	ret c
	push de
	call GetRegAddr
	ld a, [wRegVal]
	ld c, a
	ld a, [wCurFlags]
	bit 6, a
	jr nz, .l4643
	ld a, [hl]
	cp c
	jr z, .l4646
.l4643:
	ld a, c
	ld [hl], a
	ld [de], a
.l4646:
	pop de
	ret

; Trigger: NRx4 = shadow | $80.
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
TrackPtrTable:
	dw wTrkSfx1
	dw wTrkSfxN
	dw wTrkCh1
	dw wTrkCh2
	dw wTrkCh3
	dw wTrkDrm

GetRegBase:
	ld a, [wTrackIdx]
	ld hl, RegBaseTable
	call AddAToHL
	ld a, [hl]
	ret
RegBaseTable:
	db $00, $0F, $00, $05, $0A, $0F

; SndPause: silence CH1/CH2/CH4 (vol 0, retrigger), CH3 level 0, play sound 5.
SndPause:
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ld a, $00
	ldh [rNR32], a
	ld a, $05
	jp PlaySound

; SndUnpause: copy the shadows back to the hardware (no retrigger: sound comes
; back on the next note). CH4 is only restored for ids >= 5 (not drums).
; wNoRestore is never written by the driver (always 0).
SndUnpause:
	ld a, [wPause]
	ld b, a
	ld a, [wNoRestore]
	or b
	ret nz
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
	ld a, [wTrkSfxN] ; sound id on the noise SFX track
	cp $05
	ret c
	ld hl, wShadow + $10
	ld de, rNR41
	ld b, $04

CopyRegs:
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, CopyRegs
	ret

; LoadTrack / StoreTrack: copy a $25-byte slot to / from the working copy.
LoadTrack:
	call TrackCopyArgs
	call CopyBytes
	ret

StoreTrack:
	call TrackCopyArgs
	call SwapHLDE
	call CopyBytes
	ret

TrackCopyArgs:
	ld hl, wTrackPtr
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld de, wCurId
	ld bc, $0025
	ret

; PlaySound: A = sound id (0 = stop everything). Preserves all registers.
PlaySound:
	push hl
	push de
	push bc
	push af
	call PlaySoundMain
	pop af
	pop bc
	pop de
	pop hl
	ret

; Each mask bit starts one track if the new priority >= that slot's priority.
; NR51 / NR10 are set for the channel even when the priority test fails.
PlaySoundMain:
	ld [wReqId], a
	or a
	jp z, StopAll
	dec a
	ld hl, SoundTable ; SoundTable
	call LoadPtrFromTable
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl]
	srl a
	call c, StartSfx1
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
	and $EE
	or $11
	ld [wNR51], a
	ld de, wTrkSfx1

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
	jr c, .l478D
	ld [hl], a
	ld a, [wReqId]
	ld [de], a ; id
	inc hl
	ld [hl], c ; pointer
	inc hl
	ld [hl], b
	inc hl
	ld [hl], $01 ; length counter = 1 -> commands next tick
	inc hl
	ld [hl], $40 ; flags = TF_FORCE
	inc hl
	ld e, l
	inc e
	ld d, h
	ld bc, $0005
	ld [hl], $00 ; zero +6..+11 (loop count .. vibrato offset hi)
	call CopyBytes
.l478D:
	pop hl
	pop af
	ret

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l47A1
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wShadow
	ld [bc], a
.l47A1:
	ld a, [wNR51]
	and $EE
	or $11
	ld [wNR51], a
	ld de, wTrkCh1
	jp StartTrack

StartCh2:
	push af
	ld a, [wNR51]
	and $DD
	or $22
	ld [wNR51], a
	ld de, wTrkCh2
	jp StartTrack

StartCh3:
	push af
	ld a, [wNR51]
	and $BB
	or $44
	ld [wNR51], a
	ld de, wTrkCh3
	jp StartTrack

StartSfxN:
	push af
	ld a, [wNR51]
	and $77
	or $88
	ld [wNR51], a
	ld de, wTrkSfxN
	jp StartTrack

StartDrm:
	push af
	ld de, wTrkDrm
	jp StartTrack

; StopAll (id 0): clear $C100-$C24A and silence CH1/CH2/CH3/CH4.
; NR51 is not written here.
StopAll:
	ld hl, wCurId
	ld de, wCurId + 1
	ld bc, $014B
	ld [hl], $00
	call CopyBytes
	ld hl, rNR12
	ld [hl], $00
	ld hl, rNR14
	ld [hl], $80
	ld hl, rNR22
	ld [hl], $00
	ld hl, rNR24
	ld [hl], $80
	ld hl, rNR32
	ld [hl], $00
	ld hl, rNR42
	ld [hl], $00
	ld hl, rNR44
	ld [hl], $80
	ret

; 96 periods: index 0 = C2 (65.4 Hz) ... 95 = B9.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7

; CH3 waves (EA 3x on CH3 selects wave x). The three 16-byte waves overlap.
WaveTable:
	dw Wave1
	dw Wave2
	dw Wave3
Wave1:
	db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
Wave2:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
Wave3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FF, $FF, $FF, $FF, $FE, $DC, $BA, $98
	db $76, $54, $32, $10

; Sound table: 49 ids ($01-$31). Id 0 = StopAll.
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

SndHdr05:
	SND_HEADER $FF, $01 ; tracks: Sfx1
	dw Snd05_Sfx1

SndHdr06:
	SND_HEADER $FE, $02 ; tracks: SfxN
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd07_SfxN

SndHdr1F:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd1F_SfxN

SndHdr0B:
	SND_HEADER $FC, $02 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd0C_SfxN

SndHdr08:
	SND_HEADER $FA, $02 ; tracks: SfxN
	dw Snd08_SfxN

SndHdr1D:
	SND_HEADER $F9, $02 ; tracks: SfxN
	dw Snd1D_SfxN

SndHdr0D:
	SND_HEADER $F8, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr10:
	SND_HEADER $F7, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $F6, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $F5, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $F4, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr16:
	SND_HEADER $F3, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $F3, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $F2, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr15:
	SND_HEADER $F1, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr0E:
	SND_HEADER $F0, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $EF, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr14:
	SND_HEADER $EE, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr19:
	SND_HEADER $FB, $02 ; tracks: SfxN
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $EC, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $EA, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1E:
	SND_HEADER $E9, $02 ; tracks: SfxN
	dw Snd1E_SfxN

SndHdr20:
	SND_HEADER $E7, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd22_SfxN

SndHdr09:
	SND_HEADER $E3, $02 ; tracks: SfxN
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $E3, $02 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr23:
	SND_HEADER $FE, $02 ; tracks: SfxN
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $FD, $02 ; tracks: SfxN
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $01, $3C ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd25_Ch1
	dw Snd25_Ch2
	dw Snd25_Ch3
	dw Snd25_Drm

SndHdr26:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd26_Ch1
	dw Snd26_Ch2
	dw Snd26_Ch3

SndHdr27:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd27_Ch1
	dw Snd27_Ch2
	dw Snd27_Ch3

SndHdr28:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd28_Ch1
	dw Snd28_Ch2
	dw Snd28_Ch3

SndHdr29:
	SND_HEADER $01, $3C ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd29_Ch1
	dw Snd29_Ch2
	dw Snd29_Ch3
	dw Snd29_Drm

SndHdr2E:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd2E_Ch1
	dw Snd2E_Ch2
	dw Snd2E_Ch3

SndHdr2F:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd2F_Ch1
	dw Snd2F_Ch2
	dw Snd2F_Ch3

SndHdr31:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd31_Ch1
	dw Snd31_Ch2
	dw Snd31_Ch3

SndHdr2A:
	SND_HEADER $01, $3C ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2A_Ch1
	dw Snd2A_Ch2
	dw Snd2A_Ch3
	dw Snd2A_Drm

SndHdr2B:
	SND_HEADER $01, $3C ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2B_Ch1
	dw Snd2B_Ch2
	dw Snd2B_Ch3
	dw Snd25_Drm

SndHdr2C:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd2C_Ch1
	dw Snd2C_Ch2
	dw Snd2C_Ch3

SndHdr30:
	SND_HEADER $01, $3C ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd30_Ch1
	dw Snd30_Ch2
	dw Snd30_Ch3
	dw Snd30_Drm

SndHdr2D:
	SND_HEADER $01, $1C ; tracks: Ch1, Ch2, Ch3
	dw Snd2D_Ch1
	dw Snd2D_Ch2
	dw Snd2D_Ch3

; Drum map: DRUM n plays sound DrumMap[n-1].
DrumMap:
	db $01, $02, $03, $04

SndHdr01:
	SND_HEADER $01, $02 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $01, $02 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $01, $02 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $01, $02 ; tracks: SfxN
	dw Snd04_SfxN

Snd01_SfxN:
	PAN $0F
	NVOICE 1, 9, 1
	NOISE $31
	SND_END

Snd02_SfxN:
	PAN $F0
	NVOICE 1, 9, 1
	NOISE $31
	SND_END

Snd03_SfxN:
	NVOICE 1, 7, 1
	NOISE $31
	NVOICE $40, 7, 4
	NOISE $00
	SND_END

Snd04_SfxN:
	NVOICE 1, 8, 1
	NOISE $45
	NVOICE $20, 8, 1
	NOISE $21
	NOISE $33
	SND_END

; Vibrato table: VIBRATO n uses entry n (1-11; Vib02 is shared by entries 2-7). Entry 11 points into sound 6's
; data and is never selected.
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib02 ; 3
	dw Vib02 ; 4
	dw Vib02 ; 5
	dw Vib02 ; 6
	dw Vib02 ; 7
	dw Vib08 ; 8
	dw Vib09 ; 9
	dw Vib0A ; 10
	dw Snd06_SfxN ; 11

Vib01:
	VIB_STEP 1, 0, $001
	VIB_HOLD

Vib02:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 2, 0, $002
	VIB_SEGNO
	VIB_STEP 2, 0, $008
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib08:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $002
	VIB_SEGNO
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib09:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $002
	VIB_SEGNO
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib0A:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 2, 0, $002
	VIB_SEGNO
	VIB_STEP 3, 0, $00E
	VIB_STEP 3, 0, $000
	VIB_REPEAT $FF

Snd06_SfxN:
	NVOICE $FE, $0E, 6
	SND_SEGNO
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	SND_REPEAT $FD
	SND_SEGNO
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_REPEAT 8
	SND_END

Snd07_SfxN:
	NVOICE 2, $0C, 6
	NOISE $21
	NOISE $D1
	NOISE $C1
	NOISE $B1
	NOISE $A1
	NOISE $91
	NOISE $91
	NOISE $61
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd0C_SfxN:
	NVOICE $0A, $0D, 5
	NOISE $71
	NOISE $31
	NOISE $61
	NOISE $21
	SND_END

Snd1F_SfxN:
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd08_SfxN:
	NVOICE 2, $0A, 3
	NOISE $11
	NOISE $21
	NOISE $31
	NOISE $41
	NOISE $51
	NOISE $61
	NOISE $71
	NOISE $81
	NOISE $91
	NOISE $81
	NOISE $71
	NOISE $61
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $11
	NOISE $D1
	NOISE $C1
	NOISE $B1
	SND_END

Snd0B_SfxN:
	NVOICE 2, $0A, 5
	NOISE $11
	NOISE $41
	NOISE $61
	NOISE $11
	NOISE $81
	NOISE $31
	NOISE $11
	NOISE $11
	NOISE $91
	NOISE $11
	NOISE $71
	SND_END

Snd0D_Sfx1:
	TRANSPOSE_UP $0A
	VOICE 5, $0F, $0C, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	SND_END

Snd0E_Sfx1:
	TRANSPOSE_UP 0
	VOICE 4, $0F, $0C, $0F, 0
	OCTAVE 5
	NOTE F_, 1
	NOTE C_HI, 1
	ATTEN 5
	NOTE F_, 1
	NOTE C_HI, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 8
	NOTE C_HI, 1
	ATTEN 9
	NOTE F_, 1
	NOTE C_HI, 1
	ATTEN 9
	NOTE F_, 1
	SND_END

Snd10_Sfx1:
	VOICE 1, $0F, 0, 1, $0E
	SWEEP $77
	OCTAVE 5
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
	NOTE A#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

; Unreferenced data after sound $10 (looks like a cut echo tail).
Orphan_4B96:
	db $F9, $11, $31, $51, $FF, $FA, $31, $51, $FB, $31, $51, $FC, $31, $51, $FF

Snd11_Sfx1:
	VOICE 2, $0F, 0, $0F, 0
	SWEEP $77
	OCTAVE 5
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
	NOTE A#, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 8
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SWEEP $00
	SND_END

Snd12_Sfx1:
	TRANSPOSE_UP 0
	VOICE 3, $0F, 4, 7, 6
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	PAN $0F
	ATTEN 4
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 3
	PAN $F0
	ATTEN 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 2
	PAN $0F
	ATTEN 7
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	ATTEN 8
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	SND_END

Snd13_Sfx1:
	TRANSPOSE_UP 8
	VOICE 2, $0F, 8, 5, 6
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE A#, 1
	ATTEN 7
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 8
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	SND_END

Snd16_Sfx1:
	VOICE 1, $0F, 0, 0, 0
	OCTAVE 5
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	PAN $0F
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	PAN $F0
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	PAN $0F
	ATTEN 6
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	PAN $F0
	ATTEN 7
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN 8
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_END

Snd18_Sfx1:
	TRANSPOSE_UP 0
	VOICE 5, $0F, 4, 5, 6
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 9
	NOTE C_, 1
	NOTE D#, 1
	SND_END

Snd15_Sfx1:
	TRANSPOSE_UP 0
	VOICE 5, $0F, 4, 5, 6
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 5
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 9
	NOTE C_, 1
	NOTE D#, 1
	SND_END

Snd0F_Sfx1:
	VOICE 2, $0F, 4, 0, 8
	OCTAVE 5
	NOTE E_, 4
	SND_END

Snd14_Sfx1:
	VOICE 1, $0F, 4, $0F, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 1
	NOTE C_, 1
	SND_END

Snd19_SfxN:
	NVOICE 5, $0C, 6
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	SND_END

Snd1A_Sfx1:
	TRANSPOSE_UP 7
	VOICE 1, $0F, $0C, 5, 6
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	SND_END

; Unreferenced 3 bytes after sound $1A.
Orphan_4CC4:
	db $31, $11, $FF

Snd1B_SfxN:
	NVOICE 6, $0F, 1
	NOISE $31
	NVOICE 3, $0F, 1
	NOISE $21
	SND_END

Snd1C_Sfx1:
	TRANSPOSE_UP 0
	VOICE 1, $0F, $0C, 5, 6
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd1D_SfxN:
	NVOICE 9, $0F, 6
	NOISE $71
	SND_END

Snd1E_SfxN:
	NVOICE 3, 6, 9
	NOISE $21
	NOISE $41
	NVOICE 3, 6, 9
	NOISE $06
	NOISE $21
	NOISE $02
	SND_END

Snd20_Sfx1:
	TRANSPOSE_UP $0C
	VOICE 1, $0F, 0, 5, 6
	OCTAVE 2
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd21_SfxN:
	PAN $0F
	NVOICE 3, $0C, 6
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	SND_END

Snd22_SfxN:
	PAN $F0
	NVOICE 3, $0C, 6
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	NOISE $81
	SND_END

Snd0A_SfxN:
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $61
	NOISE $71
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $81
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE $FE, 7, 9
	NOISE $7F
	NOISE $7F
	NOISE $7F
	NOISE $8F
	SND_END

Snd09_SfxN:
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $61
	NOISE $71
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	SND_SEGNO
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $81
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $81
	NOISE $71
	NVOICE 9, $0C, 6
	NOISE $81
	SND_REPEAT 6
	SND_SEGNO
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $91
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $81
	NOISE $91
	NOISE $81
	NVOICE 9, $0C, 6
	NOISE $91
	SND_REPEAT 4
	NOISE $81
	SND_END

Snd23_SfxN:
	NVOICE 3, 1, 9
	SND_SEGNO
	NOISE $21
	NOISE $61
	NOISE $21
	NOISE $61
	NOISE $21
	SND_REPEAT 3
	SND_END

Snd24_SfxN:
	NVOICE 8, $0D, 5
	NOISE $51
	NOISE $21
	NOISE $31
	NOISE $31
	SND_END

Snd17_Sfx1:
	TRANSPOSE_UP $0C
	VOICE 1, $0F, 0, 0, 0
	OCTAVE 5
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
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
	ATTEN 5
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	SND_END

Snd05_Sfx1:
	VOICE 6, $0F, 8, 5, $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 3
	SND_END

Snd25_Ch2:
	VIBRATO 8
	VOICE 4, $0B, 4, 1, $0D
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
Snd25_Ch2_4E34:
	SND_CALL Snd25_Ch2_4E7D
	RELEASE 2, 6
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE E_, 1
	PAN $0F
	ATTEN 4
	NOTE E_, 2
	PAN $FF
	ATTEN 0
	NOTE G_, 2
	PAN $F0
	ATTEN 4
	NOTE G_, 1
	PAN $FF
	ATTEN 0
	NOTE B_, 3
	OCTAVE 4
	NOTE E_, 2
	NOTE B_, 2
	SND_CALL Snd25_Ch2_4E7D
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	PAN $0F
	ATTEN 4
	NOTE B_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $F0
	ATTEN 4
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	NOTE A_, 3
	PAN $0F
	ATTEN 4
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE E_, 1
	PAN $0F
	ATTEN 4
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	RELEASE 4, 8
	NOTE G_, 1
	NOTE A_, 3
	SND_CALL Snd25_Ch2_4ED6
Snd25_Ch2_4E7D:
	DUTY 0
	RELEASE 2, $0A
	OCTAVE 3
	NOTE A_, 2
	PAN $0F
	ATTEN 4
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $F0
	ATTEN 4
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	PAN $0F
	ATTEN 4
	NOTE B_, 3
	PAN $FF
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	PAN $F0
	ATTEN 4
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	NOTE B_, 1
	PAN $0F
	ATTEN 4
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	RELEASE 3, 8
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 2
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 2
	PAN $F0
	ATTEN 4
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $0F
	ATTEN 4
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	PAN $F0
	ATTEN 4
	NOTE B_, 3
	PAN $FF
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
Snd25_Ch2_4ED6:
	SND_CALL Snd25_Ch2_4EED
	NOTE A_, 3
	NOTE F#, 3
	NOTE D_, 2
	SND_CALL Snd25_Ch2_4EED
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	SND_CALL Snd25_Ch2_4F11
Snd25_Ch2_4EED:
	DUTY 8
	VOICE 4, $0B, 4, 1, $0A
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN 4
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE E_, 2
	RELEASE 3, 9
	PAN $F0
	ATTEN 4
	NOTE E_, 2
	PAN $FF
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 2
	SND_RET
Snd25_Ch2_4F11:
	VOICE 4, $0C, 4, 2, 8
	DUTY 4
	OCTAVE 4
	NOTE C_, 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 3
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 3
	NOTE F#, 1
	PAN $0F
	ATTEN 5
	NOTE F#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	NOTE G_, 3
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE F#, 3
	NOTE E_, 2
	RELEASE 1, $0D
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE 2, 8
	OCTAVE 4
	NOTE B_, 3
	NOTE A#, 1
	PAN $F0
	ATTEN 5
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE A_, 2
	PAN $0F
	ATTEN 5
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 3
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_CALL Snd25_Ch2_4FA7
	NOTE G_, 3
	OCTAVE 3
	NOTE B_, 1
	PAN $0F
	ATTEN 5
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE F#, 3
	RELEASE 1, $0D
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_CALL Snd25_Ch2_4FA7
	OCTAVE 4
	NOTE B_, 2
	PAN $0F
	ATTEN 5
	NOTE B_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $F0
	ATTEN 5
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE A_, 3
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	PAN $0F
	ATTEN 5
	NOTE D_, 2
	PAN $FF
	ATTEN 0
	SND_CALL Snd25_Ch2_4E34
Snd25_Ch2_4FA7:
	DUTY 8
	RELEASE 5, $0B
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 1
	PAN $0F
	ATTEN 5
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 2
	PAN $0F
	ATTEN 5
	NOTE G_, 2
	PAN $FF
	ATTEN 0
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 1
	PAN $0F
	ATTEN 5
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	SND_RET

Snd25_Ch1:
	VIBRATO 1
	VOICE 4, 5, 8, 3, 8
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
Snd25_Ch1_501D:
	SND_CALL Snd25_Ch1_5064
	RELEASE 2, 6
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE E_, 1
	PAN $F0
	ATTEN 3
	NOTE E_, 2
	PAN $FF
	ATTEN 0
	NOTE E_, 2
	PAN $0F
	ATTEN 3
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	NOTE G_, 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	SND_CALL Snd25_Ch1_5064
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN 3
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	NOTE D#, 1
	PAN $0F
	ATTEN 3
	NOTE D#, 1
	PAN $FF
	ATTEN 0
	NOTE D#, 1
	NOTE D_, 3
	PAN $F0
	ATTEN 3
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE B_, 1
	PAN $F0
	ATTEN 3
	NOTE B_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 3
	SND_CALL Snd25_Ch1_50C0
Snd25_Ch1_5064:
	VOICE 4, 5, 8, 3, 8
	DUTY 4
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 3
	PAN $F0
	ATTEN 3
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $0F
	ATTEN 3
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	PAN $F0
	ATTEN 3
	NOTE B_, 3
	PAN $FF
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	PAN $0F
	ATTEN 3
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	NOTE B_, 1
	PAN $F0
	ATTEN 3
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	RELEASE 3, 8
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 2
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 2
	PAN $0F
	ATTEN 3
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	PAN $F0
	ATTEN 3
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	PAN $0F
	ATTEN 3
	NOTE B_, 3
	PAN $FF
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 1
	NOTE G_, 1
	SND_RET
Snd25_Ch1_50C0:
	VOICE 4, 7, $0C, 2, $0D
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_REPEAT 2
	VOICE 4, 4, 4, 3, 8
	DUTY 4
	OCTAVE 4
	NOTE C_, 6
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 3
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 3
	NOTE F#, 1
	PAN $0F
	ATTEN 3
	NOTE F#, 2
	PAN $FF
	ATTEN 0
	NOTE B_, 2
	NOTE G_, 3
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE F#, 3
	NOTE E_, 2
	VOICE 4, 6, 0, 3, 8
	RELEASE 3, $0D
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	VOICE 4, 5, 4, 3, 8
	OCTAVE 3
	NOTE B_, 1
	RELEASE 2, 8
	OCTAVE 4
	NOTE B_, 3
	NOTE A#, 1
	PAN $0F
	ATTEN 3
	NOTE A#, 2
	PAN $FF
	ATTEN 0
	NOTE A_, 2
	PAN $F0
	ATTEN 3
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 3
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_CALL Snd25_Ch1_517B
	NOTE E_, 3
	OCTAVE 3
	NOTE G_, 1
	REST 2
	RELEASE 1, $0C
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	SND_CALL Snd25_Ch1_517B
	OCTAVE 4
	NOTE E_, 2
	REST 1
	NOTE D#, 1
	REST 2
	NOTE D_, 3
	RELEASE 1, $0C
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE A_, 1
	REST 2
	SND_CALL Snd25_Ch1_501D
Snd25_Ch1_517B:
	RELEASE 5, 9
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 1
	PAN $F0
	ATTEN 2
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 2
	PAN $F0
	ATTEN 2
	NOTE G_, 2
	PAN $FF
	ATTEN 0
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 1
	PAN $F0
	ATTEN 2
	NOTE B_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 1
	SND_RET

Snd25_Ch3:
	VOICE 4, 3, 3, $0F, 0
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, $0E
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 7
	RELEASE 1, 1
	PAN $0F
	AUTOPAN 2
	RELEASE 3, 5
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
Snd25_Ch3_51CC:
	SND_CALL Snd25_Ch3_51F6
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	SND_CALL Snd25_Ch3_51F6
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 3
	SND_CALL Snd25_Ch3_5233
Snd25_Ch3_51F6:
	TRANSPOSE_UP 0
	VOICE 4, 2, 3, $0F, 0
	PAN $0F
	AUTOPAN 2
	RELEASE 4, $0A
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_RET
Snd25_Ch3_5233:
	TRANSPOSE_UP $0C
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	SND_REPEAT 2
	VOICE 4, 3, 3, $0F, 0
	RELEASE 5, 5
	PAN $FF
	AUTOPAN 0
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 4
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	REST 4
	VOICE 4, 2, 3, 5, 5
	PAN $0F
	AUTOPAN 2
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 1
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	VOICE 4, 3, 3, 5, 5
	PAN $FF
	AUTOPAN 0
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	REST 4
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	REST 4
	RELEASE 4, $0A
	VOICE 4, 2, 3, 5, 5
	PAN $0F
	AUTOPAN 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 3
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 2
	SND_CALL Snd25_Ch3_51CC

Snd25_Drm:
	DRUM_UNIT 4
	SND_SEGNO
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT 6
	DRUM_UNIT 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
Snd25_Drm_5326:
	DRUM_UNIT 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $28
	SND_JUMP Snd25_Drm_5326

Snd26_Ch1:
	VOICE 2, $0C, 0, 1, $0B
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	RELEASE 1, 9
	NOTE C#, 4
	ATTEN 8
	NOTE C#, 4
	ATTEN 9
	NOTE C#, 4
	ATTEN $0A
	NOTE C#, 4
	NOTE C#, 4
	SND_END

Snd26_Ch2:
	VIBRATO 1
	VOICE 2, 4, 8, 1, 9
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 4
	SND_END

Snd26_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE 2, 2, 3, 1, 9
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 6
	SND_END

Snd27_Ch1:
	TEMPO $33
	VIBRATO 8
	VOICE 2, $0C, 0, 1, $0B
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	RELEASE 5, 5
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE D_, 4
	RELEASE 2, 8
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE 5, 8
	OCTAVE 4
	NOTE C_, $0C
	SND_END

Snd27_Ch2:
	TEMPO $33
	VOICE 2, 4, 8, 1, 9
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	RELEASE 5, 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, $0C
	SND_END

Snd27_Ch3:
	TEMPO $33
	VOICE 2, 3, 2, $0F, 0
	OCTAVE 3
	NOTE C_, 4
	NOTE D#, 4
	NOTE G_, 4
	NOTE A#, 4
	NOTE F_, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE G#, 6
	NOTE A#, 6
	OCTAVE 3
	NOTE C_, $0C
	SND_END

Snd28_Ch2:
	VIBRATO 8
	VOICE 5, $0B, $0C, 2, $0B
	OCTAVE 3
	REST 7
	LEN_UNIT 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE $0D, 4
	NOTE G#, 7
	RELEASE 1, $0D
	LEN_UNIT 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
Snd28_Ch2_53DD:
	SND_CALL Snd28_Ch2_5419
	NOTE D_, 2
	PAN $0F
	ATTEN 5
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 3
	NOTE D_, 2
	OCTAVE 2
	PAN $0F
	ATTEN 5
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_CALL Snd28_Ch2_5419
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE G#, 1
	LEN_UNIT 1
	ATTEN 6
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
	LEN_UNIT 3
	RELEASE 1, $0D
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_CALL Snd28_Ch2_5434
Snd28_Ch2_5419:
	VOICE 3, $0B, $0C, 2, $0B
	OCTAVE 4
	NOTE D_, 2
	PAN $F0
	ATTEN 5
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	OCTAVE 3
	NOTE G#, 3
	NOTE G_, 2
	PAN $0F
	ATTEN 5
	NOTE G_, 1
	PAN $FF
	ATTEN 0
	NOTE F_, 3
	NOTE G_, 2
	NOTE G#, 2
	SND_RET
Snd28_Ch2_5434:
	RELEASE 2, $0D
	OCTAVE 3
	ATTEN 0
	NOTE G#, 3
	NOTE G_, 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 3
	RELEASE 1, $0D
	NOTE G_, 2
	NOTE D_, 2
	RELEASE 2, $0D
	NOTE G#, 3
	NOTE G_, 3
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	RELEASE 1, $0E
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	RELEASE 2, $0D
	LEN_UNIT 1
	ATTEN 6
	OCTAVE 4
	NOTE B_, 1
	NOTE C_, 1
	NOTE C#, 1
	LEN_UNIT 3
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE C#, 2
	ATTEN 5
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A#, 1
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE G#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_CALL Snd28_Ch2_53DD

Snd28_Ch1:
	VOICE 5, 4, 8, 4, $0B
	OCTAVE 2
	REST 7
	LEN_UNIT 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	RELEASE $0D, 4
	NOTE F_, 7
	RELEASE 1, $0B
	LEN_UNIT 1
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
Snd28_Ch1_54AB:
	VOICE 3, 5, 8, 1, 9
	SND_SEGNO
	OCTAVE 3
	PAN $F0
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	PAN $0F
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT 8
	SND_SEGNO
	PAN $F0
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F_, 1
	PAN $0F
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 3
	PAN $F0
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	PAN $0F
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT 4
	SND_JUMP Snd28_Ch1_54AB

Snd28_Ch3:
	VOICE 5, 3, 1, 1, 9
	OCTAVE 2
	REST 7
	LEN_UNIT 3
	NOTE A_, 2
	NOTE C#, 2
	NOTE F_, 2
	RELEASE $0D, 4
	OCTAVE 1
	NOTE F_, 7
	RELEASE 1, $0B
	LEN_UNIT 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
Snd28_Ch3_5505:
	SND_CALL Snd28_Ch3_5520
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_CALL Snd28_Ch3_5520
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_CALL Snd28_Ch3_553B
Snd28_Ch3_5520:
	VOICE 3, 2, 1, 1, 9
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE F_, 2
	REST 1
	NOTE D_, 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE D_, 2
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE F_, 2
	SND_RET
Snd28_Ch3_553B:
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 2
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	OCTAVE 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	SND_REPEAT 2
	SND_CALL Snd28_Ch3_5562
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	SND_CALL Snd28_Ch3_5562
	OCTAVE 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_CALL Snd28_Ch3_5505
Snd28_Ch3_5562:
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE F_, 2
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	SND_RET

Snd2E_Ch2:
	TEMPO $33
	TRANSPOSE_UP $0C
	VIBRATO 8
	VOICE 2, $0C, 0, 1, $0B
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 2
	ATTEN 0
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	RELEASE 5, 5
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 4
	RELEASE $0C, 5
	NOTE E_, $0C
	SND_END

Snd2E_Ch1:
	TEMPO $33
	TRANSPOSE_UP $0C
	VOICE 2, 4, 8, 1, 9
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	NOTE G#, 2
	NOTE E_, 2
	NOTE G#, 2
	RELEASE 5, 5
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE B_, 2
	NOTE B_, 4
	OCTAVE 4
	RELEASE $0C, 5
	NOTE C#, $0C
	SND_END

Snd2E_Ch3:
	TEMPO $33
	TRANSPOSE_UP $0C
	VOICE 2, 3, 2, $0F, 0
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 2, 5
	NOTE F_, 2
	NOTE F_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 4
	RELEASE $0C, 5
	NOTE A_, $0C
	SND_END

Snd29_Ch2:
	VIBRATO 8
	VOICE 4, $0C, 4, 1, $0E
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE 5, 6
	OCTAVE 3
	NOTE G_, 9
	RELEASE 1, $0E
	ATTEN 3
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0D
	ATTEN 2
	NOTE C#, 3
	OCTAVE 3
	ATTEN 1
	NOTE G_, 3
	OCTAVE 4
	ATTEN 2
	NOTE C_, 2
	OCTAVE 3
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	NOTE F_, 3
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	RELEASE 1, $0E
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	RELEASE 7, 4
	NOTE G_, 6
	RELEASE 1, 9
	LEN_UNIT 1
	RELEASE 6, 6
	ATTEN 8
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 0
	LEN_UNIT 4
	OCTAVE 3
	ATTEN 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 0
	RELEASE 3, $0D
	ATTEN 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, 1
	ATTEN 1
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 2
	LEN_UNIT $38
	LEN_UNIT 1
	RELEASE 6, 6
	ATTEN 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	LEN_UNIT 4
	ATTEN 0
	SND_CALL Snd29_Ch2_5697
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C_, 1
	PAN $F0
	ATTEN 3
	NOTE C_, 1
	PAN $FF
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	PAN $0F
	ATTEN 3
	NOTE A#, 1
	PAN $FF
	ATTEN 0
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	ATTEN 6
	PAN $F0
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	PAN $0F
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	PAN $FF
	SND_CALL Snd29_Ch2_5697
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	RELEASE 4, $0B
	NOTE G_, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 3
	SND_CALL Snd29_Ch2_56BE
Snd29_Ch2_5697:
	VOICE 4, $0B, 4, 1, $0B
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	PAN $F0
	ATTEN 3
	NOTE C_, 1
	PAN $FF
	ATTEN 1
	NOTE C#, 1
	PAN $0F
	ATTEN 3
	NOTE C#, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	PAN $F0
	ATTEN 3
	NOTE D_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE C#, 1
	ATTEN 5
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 3
	SND_RET
Snd29_Ch2_56BE:
	SND_CALL Snd29_Ch2_56F3
	OCTAVE 3
	RELEASE 4, $0B
	NOTE A#, 3
	RELEASE 1, $0D
	ATTEN 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	SND_CALL Snd29_Ch2_56F3
	RELEASE 4, $0B
	NOTE F_, 6
	SND_CALL Snd29_Ch2_56F3
	RELEASE 4, $0B
	OCTAVE 3
	NOTE A#, 3
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	OCTAVE 4
	ATTEN 2
	NOTE C_, 3
	ATTEN 1
	NOTE C#, 3
	ATTEN 0
	NOTE D_, 2
	PAN $0F
	ATTEN 3
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	RELEASE 1, $0B
	NOTE F_, 2
	RELEASE $0F, 0
	NOTE F_, 5
	SND_CALL Snd29_Ch2_5709
Snd29_Ch2_56F3:
	RELEASE 1, $0D
	NOTE D_, 1
	PAN $0F
	ATTEN 3
	NOTE D_, 1
	PAN $FF
	NOTE D_, 1
	NOTE C#, 1
	PAN $F0
	ATTEN 6
	NOTE C#, 1
	PAN $FF
	ATTEN 0
	NOTE C#, 2
	NOTE C_, 2
	NOTE C_, 1
	SND_RET
Snd29_Ch2_5709:
	SND_CALL Snd29_Ch2_5736
	RELEASE 3, $0B
	NOTE A#, 3
	NOTE G_, 2
	RELEASE 1, $0B
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	RELEASE 3, $0B
	NOTE G_, 2
	NOTE G_, 3
	ATTEN 4
	NOTE G_, 2
	SND_CALL Snd29_Ch2_5736
	RELEASE 3, $0B
	NOTE A#, 3
	RELEASE 1, $0B
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 6, $0B
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 3
	SND_CALL Snd29_Ch2
Snd29_Ch2_5736:
	ATTEN 0
	RELEASE 1, $0D
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE 7, $0E
	OCTAVE 4
	NOTE G_, 9
	RELEASE 1, $0B
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET

Snd29_Ch1:
	VIBRATO 1
	VOICE 4, 3, 8, 5, 5
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 9
	REST 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	OCTAVE 3
	NOTE G_, 3
	NOTE C#, 3
	NOTE E_, 2
	REST 1
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE F_, 2
	REST 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 6
	REST 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE C#, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 2
	NOTE F_, 1
	NOTE A#, 2
	NOTE F_, 1
	NOTE G_, 2
	REST 2
	SND_CALL Snd29_Ch1_57A0
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	REST 3
	SND_CALL Snd29_Ch1_57A0
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 2
	SND_CALL Snd29_Ch1_57C7
Snd29_Ch1_57A0:
	VOICE 4, 4, 4, 5, 5
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	PAN $0F
	ATTEN 1
	NOTE C_, 1
	PAN $FF
	ATTEN 1
	NOTE C#, 1
	PAN $F0
	ATTEN 1
	NOTE C#, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	PAN $0F
	ATTEN 1
	NOTE D_, 1
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 3
	SND_RET
Snd29_Ch1_57C7:
	SND_CALL Snd29_Ch1_57E5
	NOTE G_, 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	SND_CALL Snd29_Ch1_57E5
	OCTAVE 4
	NOTE C_, 6
	SND_CALL Snd29_Ch1_57E5
	NOTE G_, 3
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 3
	NOTE G_, 3
	NOTE A_, 2
	REST 1
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 5
	SND_CALL Snd29_Ch1_57EE
Snd29_Ch1_57E5:
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	REST 1
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 1
	SND_RET
Snd29_Ch1_57EE:
	SND_CALL Snd29_Ch1_580B
	NOTE G_, 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 3
	REST 2
	SND_CALL Snd29_Ch1_580B
	NOTE G_, 3
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 3
	SND_CALL Snd29_Ch1
Snd29_Ch1_580B:
	NOTE C#, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 9
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET

Snd29_Ch3:
	VOICE 4, 2, 3, 3, 8
	PAN $0F
	AUTOPAN 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE D_, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 2
	SND_REPEAT 2
	SND_CALL Snd29_Ch3_5864
Snd29_Ch3_5864:
	VOICE 4, 5, 3, 3, 3
	PAN $FF
	AUTOPAN 0
	RELEASE $0F, 0
	NOTE D_, $0C
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 2
	OCTAVE 2
	NOTE D#, 6
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D_, 6
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 2
	NOTE D#, 4
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D_, 2
	LEN_UNIT 1
	RELEASE $0F, 0
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 2
	LEN_UNIT 4
	NOTE D#, 1
	NOTE A#, 1
	VOICE 4, 2, 3, 3, 8
	PAN $0F
	AUTOPAN 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	SND_CALL Snd29_Ch3_58BA
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 1
	SND_CALL Snd29_Ch3_58BA
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 3
	SND_CALL Snd29_Ch3
Snd29_Ch3_58BA:
	RELEASE 2, 9
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE F_, 2
	SND_RET

Snd29_Drm:
	DRUM_UNIT 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $10
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT $0E
	DRUM_UNIT 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM_UNIT 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 4, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 8
	SND_JUMP Snd29_Drm

Snd2F_Ch2:
	VIBRATO 8
	VOICE 3, 7, $0C, $0F, 0
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 6
	OCTAVE 2
	NOTE D#, 6
	OCTAVE 1
	NOTE F#, $0F
	LEN_UNIT 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 1
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
	NOTE C_, 1
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
	OCTAVE 3
Snd2F_Ch2_592F:
	SND_CALL Snd2F_Ch2_5943
	RELEASE $0F, 0
	LEN_UNIT 4
	NOTE F#, 8
	SND_CALL Snd2F_Ch2_5943
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	RELEASE $0F, 0
	NOTE B_, $0A
	SND_CALL Snd2F_Ch2_5952
Snd2F_Ch2_5943:
	TEMPO $10
	VOICE 2, $0B, 4, 3, 9
	NOTE A#, 6
	NOTE A_, 6
	NOTE G_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 6
	NOTE A_, 6
	SND_RET
Snd2F_Ch2_5952:
	RELEASE 3, 9
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 6
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	RELEASE $0F, 0
	LEN_UNIT 4
	NOTE F#, 8
	RELEASE 3, 9
	LEN_UNIT 2
	NOTE F#, 6
	NOTE G_, 6
	NOTE A#, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE D#, 6
	NOTE F_, 6
	OCTAVE 2
	RELEASE $0F, 0
	LEN_UNIT 4
	NOTE A#, 8
	LEN_UNIT 2
	SND_CALL Snd2F_Ch2_598A
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	SND_CALL Snd2F_Ch2_598A
	NOTE A_, 6
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	SND_CALL Snd2F_Ch2_592F
Snd2F_Ch2_598A:
	OCTAVE 4
	ATTEN 6
	NOTE C_, 4
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	OCTAVE 3
	NOTE A#, $0C
	ATTEN 6
	NOTE A#, 4
	NOTE A#, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 6
	NOTE A#, 4
	ATTEN 0
	SND_RET

Snd2F_Ch1:
	VIBRATO 1
	VOICE 3, 3, 8, $0F, 0
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 6
	OCTAVE 2
	NOTE D#, 6
	OCTAVE 1
	NOTE F#, $0F
	LEN_UNIT 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 1
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
	NOTE C_, 1
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
	OCTAVE 3
Snd2F_Ch1_59CB:
	SND_CALL Snd2F_Ch1_5A03
	NOTE F#, 3
	VOICE 2, 6, 8, 1, $0E
	PAN $0F
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $FF
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	PAN $F0
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	PAN $FF
	NOTE D_, 2
	VOICE 2, 4, 8, 3, 9
	OCTAVE 3
	SND_CALL Snd2F_Ch1_5A03
	NOTE A_, 6
	NOTE G#, 1
	VOICE 2, 7, $0C, 1, $0E
	SND_SEGNO
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	SND_REPEAT 4
	VOICE 2, 8, $0C, 3, 9
	SND_CALL Snd2F_Ch1_5A14
Snd2F_Ch1_5A03:
	TEMPO $10
	TRANSPOSE_DOWN $0C
	VOICE 2, 6, $0C, $0F, 0
	NOTE A#, 7
	NOTE A_, 6
	NOTE G_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 6
	NOTE A_, 6
	SND_RET
Snd2F_Ch1_5A14:
	RELEASE $0F, 0
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 6
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE F#, 8
	VOICE 2, 7, 4, 1, $0E
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	VOICE 2, 6, $0C, $0F, 0
	OCTAVE 3
	NOTE F#, 7
	NOTE G_, 6
	NOTE A#, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE D#, 6
	NOTE F_, 5
	OCTAVE 2
	LEN_UNIT 4
	NOTE A#, 8
	LEN_UNIT 2
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	SND_REPEAT 3
	SND_SEGNO
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT 3
	SND_SEGNO
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT 3
	SND_SEGNO
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 6
	SND_SEGNO
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	SND_REPEAT 6
	SND_SEGNO
	NOTE D_, 1
	NOTE F_, 1
	SND_REPEAT $0C
	SND_SEGNO
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 6
	SND_CALL Snd2F_Ch1_59CB

Snd2F_Ch3:
	VOICE 3, 3, 1, $0F, 0
	OCTAVE 2
	NOTE C_, 6
	OCTAVE 1
	NOTE A#, 6
	OCTAVE 2
	NOTE D#, 6
	OCTAVE 1
	NOTE F#, $0F
	ATTEN 1
	LEN_UNIT 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 1
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
	NOTE C_, 1
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
Snd2F_Ch3_5A9F:
	TEMPO $10
	ATTEN 0
	TRANSPOSE_UP $0C
	LEN_UNIT 2
	PAN $0F
	AUTOPAN 2
	RELEASE 2, 9
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE F_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 1
	NOTE D#, 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE F_, 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_JUMP Snd2F_Ch3_5A9F

Snd31_Ch2:
	TRANSPOSE_DOWN 6
	VIBRATO $0A
	VOICE 1, 8, 0, $0F, 0
	OCTAVE 2
	NOTE F_, 6
	NOTE F#, 6
	NOTE G_, 6
	LEN_UNIT $0B
	NOTE G#, 2
	LEN_UNIT 1
	NOTE G#, 6
	OCTAVE 3
	NOTE D_, 6
	NOTE C#, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE C_, 6
	LEN_UNIT 5
	NOTE B_, 3
	NOTE A#, 8
	SND_END

Snd31_Ch1:
	TRANSPOSE_DOWN 6
	VIBRATO 1
	VOICE 1, 6, 8, $0F, 0
	OCTAVE 2
	NOTE F_, 6
	NOTE F#, 6
	NOTE G_, 6
	LEN_UNIT $0B
	NOTE G#, 2
	LEN_UNIT 1
	ATTEN 2
	NOTE G#, 6
	ATTEN 0
	OCTAVE 3
	NOTE D_, 6
	NOTE C#, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE C_, 6
	VIBRATO 0
	VOICE 5, 4, 8, $0F, 0
	NOTE G#, 3
	NOTE G_, 8
	SND_END

Snd31_Ch3:
	TRANSPOSE_DOWN 6
	VOICE 1, 2, 2, $0F, 0
	OCTAVE 2
	NOTE F#, 6
	NOTE F_, 6
	NOTE G#, 6
	ATTEN 0
	LEN_UNIT $0B
	NOTE G#, 2
	LEN_UNIT 1
	ATTEN 1
	NOTE G#, 6
	ATTEN 0
	OCTAVE 3
	NOTE D_, 6
	NOTE C#, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE C_, 6
	OCTAVE 2
	NOTE F_, 6
	NOTE A#, 6
	OCTAVE 3
	NOTE C#, 6
	NOTE E_, 6
	NOTE G_, 6
	LEN_UNIT 2
	OCTAVE 4
	NOTE E_, $0C
	SND_END

Snd2A_Ch2:
	VIBRATO 7
	VOICE 4, 6, $0C, $0F, 1
	OCTAVE 3
	NOTE A_, $0C
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, $0C
	NOTE G#, 4
	NOTE A#, $0C
	NOTE G_, 4
	NOTE G#, 3
	NOTE A_, $0D
Snd2A_Ch2_5B8A:
	SND_CALL Snd2A_Ch2_5B9E
	NOTE G#, 3
	NOTE G_, 3
	NOTE F_, $0A
	SND_CALL Snd2A_Ch2_5B9E
	NOTE G#, 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 1
	NOTE F_, 3
	SND_CALL Snd2A_Ch2_5BAF
Snd2A_Ch2_5B9E:
	VOICE 4, 9, $0C, $0F, 0
	OCTAVE 3
	NOTE D_, $0C
	NOTE A_, 4
	NOTE G#, 4
	NOTE F_, 8
	ATTEN 7
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, $0C
	NOTE A_, 4
	SND_RET
Snd2A_Ch2_5BAF:
	SND_CALL Snd2A_Ch2_5BCF
	ATTEN 0
	RELEASE 1, 5
	LEN_UNIT 4
	NOTE C#, 3
	NOTE D_, 3
	RELEASE 7, 9
	NOTE F_, $0A
	SND_CALL Snd2A_Ch2_5BCF
	ATTEN 0
	RELEASE 5, 9
	LEN_UNIT 4
	NOTE G#, 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 1
	NOTE F_, 3
	SND_CALL Snd2A_Ch2_5C00
Snd2A_Ch2_5BCF:
	RELEASE $0F, 0
	LEN_UNIT 1
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G#, 3
	ATTEN 3
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 3
	ATTEN 2
	OCTAVE 3
	NOTE F#, 3
	NOTE B_, 2
	NOTE F_, 3
	ATTEN 1
	NOTE A#, 3
	NOTE E_, 2
	NOTE A_, 3
	ATTEN 0
	NOTE D#, 3
	NOTE G#, 2
	NOTE D_, 3
	ATTEN 1
	NOTE G_, 3
	NOTE C_, 2
	NOTE F_, 3
	ATTEN 2
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A#, 3
	ATTEN 3
	OCTAVE 3
	NOTE D#, 3
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 3
	SND_RET
Snd2A_Ch2_5C00:
	RELEASE 5, 8
	OCTAVE 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G#, $0A
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G#, $0A
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 4
	ATTEN 0
	SND_CALL Snd2A_Ch2_5B8A

Snd2A_Ch1:
	TRANSPOSE_DOWN $0C
	PAN $F0
	AUTOPAN 2
	VOICE 4, 3, 8, 3, $0B
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	RELEASE 5, 9
	ATTEN 3
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	RELEASE 2, $0B
	ATTEN 0
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G#, 2
	RELEASE 5, 9
	ATTEN 3
	NOTE G#, 4
	NOTE G#, 4
	OCTAVE 2
	RELEASE 2, $0B
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE 5, 9
	ATTEN 3
	NOTE G#, 4
	NOTE G#, 2
	OCTAVE 2
	RELEASE 2, $0B
	ATTEN 0
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	OCTAVE 2
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
Snd2A_Ch1_5C65:
	SND_CALL Snd2A_Ch1_5C79
	NOTE G#, 3
	NOTE G_, 3
	NOTE F_, 9
	SND_CALL Snd2A_Ch1_5C79
	NOTE G#, 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 1
	NOTE F_, 2
	SND_CALL Snd2A_Ch1_5C92
Snd2A_Ch1_5C79:
	DUTY 4
	RELEASE $0F, 0
	TRANSPOSE_UP 0
	PAN $FF
	AUTOPAN 0
	VIBRATO 1
	OCTAVE 3
	NOTE D_, $0D
	NOTE A_, 4
	NOTE G#, 4
	NOTE F_, 8
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, $0C
	NOTE A_, 4
	SND_RET
Snd2A_Ch1_5C92:
	SND_CALL Snd2A_Ch1_5CAF
	RELEASE 5, 9
	LEN_UNIT 4
	NOTE C#, 3
	NOTE D_, 3
	NOTE F_, $0A
	SND_CALL Snd2A_Ch1_5CAF
	RELEASE 5, 9
	LEN_UNIT 4
	OCTAVE 2
	NOTE G#, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE G#, 2
	NOTE G_, 1
	NOTE F_, 3
	SND_CALL Snd2A_Ch1_5CD5
Snd2A_Ch1_5CAF:
	RELEASE $0F, 0
	LEN_UNIT 1
	OCTAVE 3
	NOTE E_, 5
	NOTE A_, 2
	NOTE D#, 3
	NOTE G#, 3
	NOTE D_, 2
	NOTE G_, 3
	NOTE C#, 3
	NOTE F#, 2
	NOTE C_, 3
	NOTE F_, 3
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 3
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE D_, 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE F#, 3
	NOTE B_, 2
	NOTE F_, 3
	NOTE A#, 3
	NOTE D#, 2
	NOTE A_, 1
	SND_RET
Snd2A_Ch1_5CD5:
	DUTY 8
	RELEASE 5, 8
	OCTAVE 3
	NOTE F_, 3
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE E_, $0A
	NOTE E_, 3
	NOTE C#, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 3
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE E_, $0A
	NOTE E_, 3
	NOTE C#, 3
	NOTE E_, 2
	NOTE D_, 3
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	SND_CALL Snd2A_Ch1_5C65

Snd2A_Ch3:
	TRANSPOSE_UP 0
	PAN $F0
	AUTOPAN 2
	VOICE 4, 2, 1, $0F, 0
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	REST 4
	REST 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G#, 2
	REST 8
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A#, 2
	REST 4
	REST 2
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	REST 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	REST 1
	NOTE A_, 1
Snd2A_Ch3_5D27:
	RELEASE 2, 9
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 1
	ATTEN 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 2
	ATTEN 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE F_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 1
	ATTEN 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 2
	ATTEN 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE D_, 2
	OCTAVE 2
	ATTEN 0
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT 2
	SND_CALL Snd2A_Ch3_5D7D
	REST 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	SND_CALL Snd2A_Ch3_5D7D
	REST 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 3
	SND_CALL Snd2A_Ch3_5D93
Snd2A_Ch3_5D7D:
	TRANSPOSE_UP $0C
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	SND_RET
Snd2A_Ch3_5D93:
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	REST 1
	NOTE F_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	SND_REPEAT 2
	SND_CALL Snd2A_Ch3_5D27

Snd2A_Drm:
	DRUM_UNIT 4
	SND_SEGNO
	DRUM 3, 2
	DRUM 1, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 7
	DRUM 1, 1
	DRUM 1, 1
	DRUM 3, 2
	DRUM 2, 1
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 7
	DRUM 3, 2
	SND_REPEAT 2
Snd2A_Drm_5DC2:
	SND_SEGNO
	DRUM_UNIT 4
	DRUM 3, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 3, 2
	DRUM 2, 1
	DRUM 2, 9
	SND_REPEAT $28
	SND_JUMP Snd2A_Drm_5DC2

Snd2B_Ch2:
	TRANSPOSE_UP 2
	PAN $0F
	AUTOPAN 2
	VOICE 4, 7, 8, 1, 9
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE C_, 3
	PAN $FF
	AUTOPAN 0
Snd2B_Ch2_5DFB:
	SND_CALL Snd2B_Ch2_5E18
	RELEASE $0F, 0
	NOTE E_, 3
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, $0A
	SND_CALL Snd2B_Ch2_5E18
	NOTE E_, 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 1
	NOTE A_, 3
	SND_CALL Snd2B_Ch2_5E2F
Snd2B_Ch2_5E18:
	VIBRATO 8
	VOICE 4, 9, 4, 4, 9
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE G#, 8
	RELEASE 4, 9
	ATTEN 3
	NOTE G#, 2
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	SND_RET
Snd2B_Ch2_5E2F:
	SND_CALL Snd2B_Ch2_5E66
	NOTE F_, 3
	NOTE D_, 1
	PAN $0F
	ATTEN 2
	NOTE D_, 2
	PAN $FF
	ATTEN 0
	NOTE G_, 3
	RELEASE 1, $0D
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	PAN $F0
	ATTEN 2
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	PAN $0F
	ATTEN 2
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	SND_CALL Snd2B_Ch2_5E66
	NOTE F_, 3
	NOTE G_, 1
	PAN $F0
	ATTEN 2
	NOTE G_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 1
	NOTE A_, 3
	SND_CALL Snd2B_Ch2_5E9E
Snd2B_Ch2_5E66:
	RELEASE 1, 9
	OCTAVE 4
	NOTE A_, 1
	PAN $0F
	ATTEN 2
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	PAN $F0
	ATTEN 2
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE G#, 1
	PAN $0F
	ATTEN 2
	NOTE G#, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	PAN $0F
	ATTEN 2
	NOTE D_, 1
	PAN $FF
	ATTEN 0
	NOTE F_, 1
	PAN $F0
	ATTEN 2
	NOTE F_, 2
	PAN $FF
	ATTEN 0
	OCTAVE 3
	RELEASE 4, 9
	NOTE D_, 1
	NOTE E_, 1
	SND_RET
Snd2B_Ch2_5E9E:
	SND_CALL Snd2B_Ch2_5EC9
	RELEASE 5, 6
	OCTAVE 4
	NOTE F_, 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 3
	RELEASE 2, $0D
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE D_, 2
	SND_CALL Snd2B_Ch2_5EC9
	RELEASE 2, 9
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE A#, 3
	NOTE D_, 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 1
	SND_CALL Snd2B_Ch2_5EEC
Snd2B_Ch2_5EC9:
	RELEASE $0F, 0
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
Snd2B_Ch2_5EEC:
	SND_CALL Snd2B_Ch2_5F01
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 2
	SND_CALL Snd2B_Ch2_5F01
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE A_, 2
	NOTE C_, 1
	NOTE D_, 3
	SND_CALL Snd2B_Ch2_5DFB
Snd2B_Ch2_5F01:
	DUTY 4
	RELEASE 5, $0B
	OCTAVE 4
	NOTE F_, 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 3
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 5, 6
	NOTE F_, 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	SND_RET

Snd2B_Ch1:
	TRANSPOSE_UP 2
	PAN $F0
	AUTOPAN 2
	VOICE 4, 3, 8, 3, 9
	VIBRATO 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE C_, 3
Snd2B_Ch1_5F47:
	SND_CALL Snd2B_Ch1_5F64
	RELEASE $0F, 0
	NOTE E_, 3
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, 9
	SND_CALL Snd2B_Ch1_5F64
	NOTE E_, 3
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 1
	NOTE A_, 2
	SND_CALL Snd2B_Ch1_5F7D
Snd2B_Ch1_5F64:
	AUTOPAN 0
	VIBRATO 1
	VOICE 4, 3, 8, $0F, 9
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE G#, 8
	RELEASE 5, 6
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	SND_RET
Snd2B_Ch1_5F7D:
	SND_CALL Snd2B_Ch1_5FA6
	NOTE F_, 4
	NOTE D_, 1
	REST 2
	NOTE G_, 2
	VOICE 4, 6, 4, 1, $0E
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE D_, 2
	SND_CALL Snd2B_Ch1_5FA6
	NOTE F_, 4
	NOTE G_, 1
	REST 2
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 2
	VOICE 4, 4, 8, 5, 6
	NOTE D_, 1
	NOTE E_, 3
	VIBRATO 0
	SND_CALL Snd2B_Ch1_5FC3
Snd2B_Ch1_5FA6:
	VOICE 4, 2, 8, 2, 9
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 1
	REST 1
	OCTAVE 4
	NOTE F_, 1
	REST 2
	VIBRATO 1
	RELEASE 5, 6
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	SND_RET
Snd2B_Ch1_5FC3:
	SND_CALL Snd2B_Ch1_5FED
	RELEASE 5, 6
	OCTAVE 4
	NOTE F_, 3
	NOTE D_, 1
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 2
	RELEASE 2, 9
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 0
	SND_CALL Snd2B_Ch1_5FED
	RELEASE 2, 9
	ATTEN 1
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	ATTEN 0
	NOTE A#, 3
	NOTE D_, 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE D_, 1
	SND_CALL Snd2B_Ch1_6012
Snd2B_Ch1_5FED:
	VOICE 4, 4, 4, $0F, 0
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
Snd2B_Ch1_6012:
	SND_CALL Snd2B_Ch1_6027
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 1
	SND_CALL Snd2B_Ch1_6027
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE A_, 2
	NOTE C_, 1
	NOTE D_, 2
	SND_CALL Snd2B_Ch1_5F47
Snd2B_Ch1_6027:
	VOICE 4, 4, 8, 5, 9
	OCTAVE 4
	NOTE F_, 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 3
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	RELEASE 5, 6
	NOTE F_, 3
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	SND_RET

Snd2B_Ch3:
	TRANSPOSE_UP 2
	PAN $0F
	AUTOPAN 2
	VOICE 4, 2, 1, $0F, 0
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	PAN $FF
	AUTOPAN 0
	LEN_UNIT 1
	ATTEN 1
	OCTAVE 3
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
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 0
Snd2B_Ch3_607E:
	PAN $0F
	AUTOPAN 2
	VOICE 4, 2, 1, 2, 9
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE F_, 2
	SND_REPEAT 4
	SND_CALL Snd2B_Ch3_60A1
	NOTE E_, 2
	NOTE C_, 2
	SND_CALL Snd2B_Ch3_60A1
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	SND_CALL Snd2B_Ch3_60B8
Snd2B_Ch3_60A1:
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	SND_RET
Snd2B_Ch3_60B8:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	SND_REPEAT 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	SND_REPEAT 4
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 3
	NOTE A_, 1
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 3
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 4
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 3
	SND_REPEAT 2
	SND_CALL Snd2B_Ch3_607E

Snd2C_Ch2:
	TEMPO $30
	TRANSPOSE_UP $0C
	VIBRATO 8
	VOICE 3, $0C, 0, 2, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_CALL Snd2C_Ch2_6148
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE F#, 4
	NOTE D_, 4
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	SND_CALL Snd2C_Ch2_6148
	NOTE G_, 4
	NOTE A_, 6
	RELEASE $0F, 0
	NOTE F#, 2
	LEN_UNIT 6
	NOTE E_, $0C
	SND_CALL Snd2C_Ch2_616B
Snd2C_Ch2_6148:
	RELEASE 8, 8
	DUTY 4
	OCTAVE 3
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 2
	RELEASE 3, $0E
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	RELEASE 8, 8
	NOTE E_, 8
	RELEASE 3, $0E
	NOTE B_, 4
	NOTE A_, 4
	NOTE F#, 4
	NOTE D_, 4
	SND_RET
Snd2C_Ch2_616B:
	RELEASE 1, $0D
	DUTY $0C
	TRANSPOSE_UP 0
	LEN_UNIT 3
	ATTEN 5
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	RELEASE 5, 5
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 4
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C_, 4
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	NOTE B_, 8
	ATTEN 6
	NOTE B_, 8
	ATTEN 0
	NOTE E_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	RELEASE 1, 9
	OCTAVE 4
	ATTEN 5
	NOTE C_, 2
	OCTAVE 3
	ATTEN 4
	NOTE A#, 2
	ATTEN 3
	NOTE B_, 2
	OCTAVE 4
	ATTEN 2
	NOTE C#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE F#, 2
	SND_CALL Snd2C_Ch2_6201
	RELEASE $0F, 0
	NOTE A_, $0C
	NOTE B_, $0C
	SND_CALL Snd2C_Ch2_6201
	NOTE G_, 2
	NOTE A_, 2
	NOTE F#, 8
	LEN_UNIT 6
	NOTE E_, $0C
	VOICE 3, 4, 4, 1, 9
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	VOICE 3, 4, 4, 1, 9
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	LEN_UNIT 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	LEN_UNIT 5
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	LEN_UNIT 6
	OCTAVE 4
	NOTE F#, 4
	SND_END
Snd2C_Ch2_6201:
	DUTY 0
	RELEASE 2, 8
	OCTAVE 4
	NOTE G_, 4
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	RELEASE 5, 8
	NOTE E_, 8
	RELEASE 2, 8
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	SND_RET

Snd2C_Ch1:
	TEMPO $30
	TRANSPOSE_UP $0C
	VOICE 3, 5, 8, 5, 8
	OCTAVE 3
	REST 3
	VIBRATO 1
	VOICE 3, 3, 4, 3, 8
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	SND_REPEAT 2
	VOICE 3, 5, 8, 3, 8
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 8
	NOTE B_, 4
	NOTE A_, 4
	NOTE F#, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE F#, 4
	NOTE D_, 6
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 6
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 8
	NOTE B_, 4
	NOTE A_, 4
	NOTE F#, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 6
	NOTE F#, 1
	VOICE 3, 6, 8, 3, 8
	RELEASE 4, 4
	PAN $0F
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	PAN $F0
	OCTAVE 4
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $0F
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	NOTE D_, 2
	VOICE 3, 5, 8, $0F, 0
	PAN $FF
	TRANSPOSE_UP 0
	ATTEN 3
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 6
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE G_, 6
	NOTE F#, 1
	PAN $0F
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	VOICE 3, 6, 8, 4, 4
	PAN $F0
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	PAN $0F
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $F0
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	PAN $0F
	NOTE C_, 2
	NOTE A_, 2
	NOTE D_, 2
	PAN $F0
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	PAN $0F
	NOTE A_, 2
	NOTE D#, 2
	NOTE F#, 2
	PAN $F0
	NOTE A_, 2
	NOTE F#, 2
	NOTE B_, 2
	VOICE 3, 3, 8, 7, 8
	PAN $FF
	OCTAVE 4
	NOTE G_, 7
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	RELEASE $0F, 0
	NOTE E_, 8
	RELEASE 6, 8
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 1
	VOICE 3, 6, 8, 4, 4
	PAN $0F
	NOTE A_, 2
	NOTE C_, 2
	NOTE E_, 2
	PAN $0F
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	PAN $0F
	NOTE B_, 2
	NOTE B_, 2
	NOTE D#, 2
	PAN $0F
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE F#, 2
	VOICE 3, 3, 8, 7, 8
	PAN $FF
	NOTE G_, 7
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 8
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE F#, 6
	VOICE 3, $0B, 0, 1, 9
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	SND_REPEAT 2
	VOICE 3, $0B, 0, 1, 9
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	LEN_UNIT 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0F, 6
	LEN_UNIT 5
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	LEN_UNIT 6
	RELEASE 2, 9
	OCTAVE 4
	NOTE F#, 4
	SND_END

Snd2C_Ch3:
	TEMPO $30
	TRANSPOSE_UP $0C
	PAN $0F
	AUTOPAN 2
	VOICE 3, 2, 3, $0F, 0
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE A_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, $0A
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE A_, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, $0A
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	SND_CALL Snd2C_Ch3_6418
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	SND_CALL Snd2C_Ch3_6418
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	SND_CALL Snd2C_Ch3_644D
Snd2C_Ch3_6418:
	RELEASE 2, 9
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	SND_RET
Snd2C_Ch3_644D:
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F#, 2
	SND_CALL Snd2C_Ch3_64E5
	OCTAVE 1
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D#, 2
	SND_CALL Snd2C_Ch3_64E5
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	LEN_UNIT 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	LEN_UNIT 5
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	LEN_UNIT 6
	OCTAVE 2
	NOTE F#, 4
	SND_END
Snd2C_Ch3_64E5:
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	SND_RET

Snd30_Ch2:
	VIBRATO 8
	VOICE 5, $0A, $0C, 2, $0B
	OCTAVE 3
	REST 7
Snd30_Ch2_652B:
	VOICE 4, 9, 4, $0F, 0
	ATTEN 2
	OCTAVE 3
	NOTE A_, $0F
	NOTE G#, 1
	NOTE G_, $0F
	NOTE G#, 1
	NOTE A_, $0F
	NOTE G#, 1
	RELEASE 2, $0D
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	SND_JUMP Snd30_Ch2_652B

Snd30_Ch1:
	VIBRATO 1
	VOICE 5, $0B, $0C, 2, $0B
	OCTAVE 3
	REST 7
Snd30_Ch1_654F:
	VOICE 4, 5, 8, $0F, 0
	OCTAVE 3
	NOTE F_, $0F
	NOTE E_, 1
	NOTE D#, $0F
	NOTE E_, 1
	NOTE F_, $0F
	NOTE E_, 1
	RELEASE 2, $0D
	NOTE G_, 3
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 1
	SND_JUMP Snd30_Ch1_654F

Snd30_Ch3:
	VOICE 5, $0B, $0C, 2, 1
	OCTAVE 3
	REST 7
Snd30_Ch3_656F:
	VOICE 4, 2, 1, 2, 9
	SND_SEGNO
	OCTAVE 2
	PAN $0F
	NOTE C_, 1
	NOTE D#, 1
	PAN $F0
	NOTE F#, 1
	NOTE G_, 1
	PAN $0F
	NOTE C_, 1
	NOTE D#, 1
	PAN $F0
	NOTE F#, 1
	NOTE A_, 1
	SND_REPEAT 7
	PAN $0F
	NOTE C_, 1
	NOTE D#, 1
	PAN $F0
	NOTE F#, 1
	NOTE G_, 1
	PAN $F0
	NOTE A_, 1
	NOTE A#, 1
	PAN $0F
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	SND_JUMP Snd30_Ch3_656F

Snd30_Drm:
	DRUM_UNIT 5
	OCTAVE 3
	REST 7
	DRUM_UNIT 4
Snd30_Drm_65A2:
	SND_SEGNO
	PAN $0F
	DRUM 1, 1
	DRUM 1, 1
	DRUM 3, 2
	PAN $F0
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	SND_JUMP Snd30_Drm_65A2

Snd2D_Ch2:
	VIBRATO 8
	VOICE 4, $0C, 0, 2, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	SND_JUMP Snd2D_Ch2

Snd2D_Ch1:
	VOICE 4, 5, 8, 5, 8
	OCTAVE 3
	REST 3
Snd2D_Ch1_65EB:
	VIBRATO 1
	VOICE 4, 3, 4, 3, 8
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	SND_JUMP Snd2D_Ch1_65EB

Snd2D_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE 4, 2, 3, $0F, 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE A_, $0A
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, $0A
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	SND_JUMP Snd2D_Ch3
