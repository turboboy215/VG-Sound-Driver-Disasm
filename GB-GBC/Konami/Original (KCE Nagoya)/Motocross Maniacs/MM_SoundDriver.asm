; ==========================================================================
; Motocross Maniacs (E) - Konami sound driver (early GB version, 7-track variant)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0 $0028 rst $28, $0038 rst $38, $0050 timer vector, $006D timer ISR,
;        $0229/$0243-$0251/$02B2-$02D0 helpers, $0480-$04AC game pause toggle
;   $6576-$7FFF driver code, tables, sound data, course tempo routine
; Build: rgbasm -Wall -o mm.o MM_SoundDriver.asm && rgblink -o mm.gb mm.o
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
DEF wGameFlags EQU $C008
DEF wIsrLock EQU $C00B
DEF wPause EQU $C012
DEF wCourse EQU $C018
DEF wPlayLock EQU $C01F
DEF wTrkSfx1 EQU $C080 ; 37 bytes
DEF wTrkSfx2 EQU $C180 ; 37 bytes
DEF wTrkSfxN EQU $C280 ; 37 bytes
DEF wTrkCh1 EQU $C380 ; 37 bytes
DEF wTrkCh2 EQU $C480 ; 37 bytes
DEF wTrkCh3 EQU $C580 ; 37 bytes
DEF wTrkDrm EQU $C680 ; 37 bytes
DEF wTrackIdx EQU $C100
DEF wRegBase EQU $C101
DEF wTempo EQU $C102
DEF wTempoAcc EQU $C103
DEF wTempoSkip EQU $C104
DEF wQueuedSnd EQU $C105
DEF wNR51 EQU $C106
DEF wSweepVal EQU $C107
DEF wReqId EQU $C108
DEF wReqPrio EQU $C109
DEF wRegVal EQU $C10A
DEF wRegIdx EQU $C10B
DEF wMusicHold EQU $C10C
DEF wEnginePitch EQU $C10D
DEF wShadow EQU $C200 ; 20 bytes

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 | n and L = field
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

SECTION "rst28", ROM0[$0028]

AddAToHL:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "rst38", ROM0[$0038]

Rst38:
	jp NegateHL

SECTION "Timer vector", ROM0[$0050]

TimerVector:
	jp TimerISR

SECTION "Timer ISR", ROM0[$006D]

; Timer interrupt (64 Hz: TAC = %111, TMA = 0). Re-enables interrupts at once.
; The tick is skipped (lost) while PlaySound runs (wPlayLock) or the ISR is
; already inside SndUpdate (wIsrLock).
TimerISR:
	ei
	push hl
	push de
	push bc
	push af
	ld hl, wPlayLock
	bit 0, [hl]
	jr nz, .l008A
	ld hl, wIsrLock
	bit 0, [hl]
	jr nz, .l008A
	set 0, [hl]
	call SndUpdate
	ld hl, wIsrLock
	res 0, [hl]
.l008A:
	pop af
	pop bc
	pop de
	pop hl
	reti

SECTION "Helpers 1", ROM0[$0229]

; JumpTableInline: pop the return address, jump to word [ret + 2*A].
JumpTableInline:
	pop hl
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

SECTION "Helpers 2", ROM0[$0243]

; NegateHL (reached via rst $38).
NegateHL:
	push af
	xor a
	sub l
	ld l, a
	ld a, $00
	sbc a, h
	ld h, a
	pop af
	ret

SwapHLDE:
	push de
	ld e, l
	ld d, h
	pop hl
	ret

SECTION "Helpers 3", ROM0[$02B2]

; GetTrackPage: H = $C0 | wTrackIdx (tracks are $100 apart, fields at L = $80+).
GetTrackPage:
	ld a, [wTrackIdx]
	or $C0
	ld h, a
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

LoadPtrFromTable:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

SECTION "Pause glue", ROM0[$0480]

; Game pause toggle. Not driver code, kept as the only user of SndPause/Unpause.
PauseToggle:
	ld a, [$C7A9]
	and a
	ret nz
	ld a, [$C00D]
	add a, a
	ld hl, wPause
	jr nc, $04AD
	bit 1, [hl]
	ret nz
	bit 0, [hl]
	jr z, .l049B
	res 0, [hl]
	call SndUnpause
	ret
.l049B:
	set 0, [hl]
	call SndPause
	ld a, $08
	call PlaySound
	call $0957
	call $0957
	pop hl
	ret

SECTION "Sound driver", ROMX[$6576], BANK[1]

; SndInit: clear $C080-$C27F, NR52 = NR51 = $FF, NR50 = $77.
SndInit:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
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

; SndUpdate: one driver tick (64 Hz). Tracks 0-2 (SFX) run every tick, tracks
; 3-6 (music) are skipped on ticks where wTempoAcc += wTempo carried (or while
; wMusicHold != 0, which nothing sets). If the engine sound ($09) owns track 3,
; track 3 runs every tick and the skip starts at track 4.
; While wPause != 0 only track 1 runs, and only for sound 8 (pause jingle).
; Finally a sound queued in wQueuedSnd (by the end of sound $11) is started.
SndUpdate:
	xor a
	ld [wTempoSkip], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	jr nc, .l65A7
	ld a, $01
	ld [wTempoSkip], a
.l65A7:
	xor a
.l65A8:
	ld [wTrackIdx], a
	ld a, [wPause]
	or a
	jr z, .l65C1
	ld a, [wTrackIdx]
	cp $01
	jr nz, .l65F8
	ld a, [wTrkSfx2]
	cp $08
	jr z, .l65EC
	jr SndUpdateDone
.l65C1:
	ld a, [wTrkCh1]
	cp $09
	jr z, .l65DB
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l65EC
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone
	jr .l65EC
.l65DB:
	ld a, [wTrackIdx]
	cp $04
	jr nz, .l65EC
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone
.l65EC:
	call GetTrackPage
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr z, .l65F8
	call TrackTick
.l65F8:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, .l65A8

SndUpdateDone:
	ld a, [wQueuedSnd]
	or a
	ret z
	ld b, a
	xor a
	ld [wQueuedSnd], a
	ld a, b
	jp PlaySound

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
	jr nz, .l6638
	ld l, TRK_FLAGS
	res 0, [hl]
	res 7, [hl]
	ld a, [wTrackIdx]
	cp $05
	jp nz, ReadCmds
	xor a
	ld bc, wShadow + $0A
	ld [bc], a
	ld bc, rNR30
	ld [bc], a
	jp ReadCmds
.l6638:
	ld b, [hl]
	ld l, TRK_RELTICK
	ld a, [hl]
	sub b
	jr c, .l6643
	ld l, TRK_FLAGS
	set 0, [hl]
.l6643:
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
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l6679
	ld l, TRK_ATTEN
	ld c, [hl]
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	swap a
	ld c, a
	ld l, TRK_ENV
	ld a, [hl]
	or c
.l6679:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; Ch3Decay: step the NR32 level 1 -> 2 -> 3 -> 0 after the release point.
Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l66B0
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
	jr z, .l66B0
	inc a
	and $03
	ld [hl], a
	jr z, .l66B0
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l66B0
	xor a
.l66B0:
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
	jr z, .l671E
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l6728
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l671E:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l6728:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	jr ReadCmdsNext

; $FF: end of track. For sound $11 queue the course music first. Silence via
; NRx2 = 0 + trigger. When an SFX on CH1/CH2 ends while music uses the channel,
; restore the music duty and period (CH1 also clears NR10).
Cmd_End:
	pop hl
	ld a, [wGameFlags]
	and $04
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
	call Trigger
	ld a, [wTrackIdx]
	cp $01
	jr z, .l675F
	cp $00
	ret nz
	xor a
	ld bc, rNR10
	ld [bc], a
	ld h, HIGH(wTrkCh1)
	jr .l6761
.l675F:
	ld h, HIGH(wTrkCh2)
.l6761:
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

; QueueFollowUp: sound $11 queues FollowUpTable[wCourse - 1] ($1D-$20).
QueueFollowUp:
	ld l, TRK_ID
	ld a, [hl]
	cp $11
	jr z, .l677C
	ret
.l677C:
	ld a, [wCourse]
	dec a
	ld bc, FollowUpTable
	add a, c
	ld c, a
	jr nc, .l6788
	inc b
.l6788:
	ld a, [bc]
	ld [wQueuedSnd], a
	ret
FollowUpTable:
	db $20, $1E, $1F, $1D, $20, $1E, $1F, $1D

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
	dw Ext_Nop

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

Ext_Nop:
	pop hl
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

; $EF: NR51 bits. Ignored on music CH1 while the CH1 SFX plays (not on CH2).
Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l6873
	ld a, [wTrkSfx1]
	or a
	jp nz, ReadCmdsNext
	ld a, [wTrackIdx]
.l6873:
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
	ld bc, rNR51
	ld [bc], a
	pop hl
	jp ReadCmdsNext

; NR51 masks per track, then a stray, unreachable ret.
PanMaskTable:
	db $EE, $DD, $77, $EE, $DD, $BB, $FF
StrayRet:
	db $C9

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
	jr z, .l68D7
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
.l68D7:
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
	call SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jr z, NoiseNote
	ld a, [de]
	and $0F
	or a
	jr nz, .l6943
.l6943:
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l6948:
	dec b
	jr z, .l694E
	add a, c
	jr .l6948
.l694E:
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
	jr nz, .l696C
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l697E
.l696C:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l6974:
	srl c
	jr nc, .l6979
	add a, d
.l6979:
	rra
	dec b
	jr nz, .l6974
	pop de
.l697E:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l6996
	ld b, a
	ld c, $0C
	xor a
.l6991:
	add a, c
	dec b
	jr nz, .l6991
	ld c, a
.l6996:
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
	jp z, .l69C5
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoStep
.l69C5:
	call WritePeriod
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l69EF
	ld l, TRK_ATTEN
	ld c, [hl]
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger
.l69EF:
	ld a, $80
	ld bc, wShadow + $0A
	ld [bc], a
	ld bc, rNR30
	ld [bc], a
	ld l, TRK_ENV
	ld a, [hl]
	ld l, TRK_CH3TIMER
	ld [hl], a
	ld l, TRK_CH3RELOAD
	ld [hl], a
	ld l, TRK_ATTEN
	ld c, [hl]
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	rra
	and $03
	ld l, TRK_LEVEL
	ld [hl], a
	add a, c
	cp $04
	jr c, .l6A16
	xor a
.l6A16:
	swap a
	rla
	and $F0
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

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
	jr nc, .l6A35
	inc b
.l6A35:
	ld a, [bc]
	cp $FB
	jr z, .l6A67
	cp $FE
	jr z, .l6A71
	cp $FF
	jr z, .l6A8F
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jr z, .l6A55
	ld l, TRK_FLAGS
	set 3, [hl]
.l6A55:
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
.l6A67:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l6A35
.l6A71:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l6A85
	cp $FF
	jr z, .l6A7D
	inc [hl]
.l6A7D:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jr VibratoStep
.l6A85:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr .l6A35
.l6A8F:
	ret

; WritePeriod: NRx3/NRx4 = period + vibrato offset. For sound $09 (engine) the
; offset is replaced by wEnginePitch * 8, set by the game every frame.
WritePeriod:
	ld l, TRK_ID
	ld a, [hl]
	cp $09
	jr nz, .l6AAE
	ld a, [wEnginePitch]
	ld c, a
	ld b, $00
	sla c
	rl b
	sla c
	rl b
	sla c
	rl b
	ld l, TRK_VIBOFS
	ld [hl], c
	inc l
	ld [hl], b
.l6AAE:
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
	jr z, .l6AC6
	call SwapHLBC
	rst $38
	call SwapHLBC
.l6AC6:
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
	ld a, $80
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	call WriteReg
	ret

; DrumNote: start sound DrumMap[hi - 1] immediately.
DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l6B35
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l6B35:
	dec a
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrFromTable
	ld b, $10
	ld de, _AUD3WAVERAM
.l6B43:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l6B43
	pop hl
	pop de
	ret

; IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the
; CH2 SFX active.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l6B5B
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l6B64
.l6B5B:
	cp $04
	jr nz, .l6B66
	ld a, [wTrkSfx2]
	or a
	ret z
.l6B64:
	scf
	ret
.l6B66:
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
	jr nz, .l6B83
	ld a, [hl]
	cp c
	jr z, .l6B86
.l6B83:
	ld a, c
	ld [hl], a
	ld [de], a
.l6B86:
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
RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; SndPause: silence CH1/CH2/CH4 (vol 0, retrigger), CH3 level 0.
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
	ret

; SndUnpause: copy shadows back (no retrigger). CH4 only for ids >= 8.
; wMusicHold is read but never written (always 0).
SndUnpause:
	ld a, [wPause]
	ld b, a
	ld a, [wMusicHold]
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
	ld a, [wTrkSfxN]
	cp $08
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

; PlaySound: A = sound id (0 = stop everything). Sets wPlayLock meanwhile.
PlaySound:
	push hl
	ld hl, wPlayLock
	set 0, [hl]
	push de
	push bc
	push af
	call PlaySoundMain
	pop af
	pop bc
	pop de
	ld hl, wPlayLock
	res 0, [hl]
	pop hl
	ret

; Each mask bit starts one track if the new priority >= that track's priority.
PlaySoundMain:
	ld [wReqId], a
	or a
	jp z, StopAll
	dec a
	ld hl, SoundTable
	add a, a
	ld e, a
	ld d, $00
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld l, e
	ld h, d
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
	jr c, .l6CBD
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
.l6CBD:
	pop hl
	pop af
	ret

StartSfx2:
	push af
	ld a, [wNR51]
	and $DD
	or $22
	ld [wNR51], a
	ld de, wTrkSfx2
	jp StartTrack

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l6CE2
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wShadow
	ld [bc], a
.l6CE2:
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

; StopAll: clear all 7 tracks, the shadows and $C100-$C10D, silence CH1-CH4.
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
	ld bc, $000D
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

; 96 periods (same values as Castlevania Adventure).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7

; CH3 waves 1-9.
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
Wave1:
	db $88, $88, $8F, $F8, $80, $00, $88, $88, $FF, $F8, $00, $88, $88, $FF, $88, $00
Wave2:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
Wave4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
Wave5:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $02, $46, $8A, $CE, $FD, $B9, $75, $31
Wave6:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
Wave7:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
Wave8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
Wave9:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0

; Sound table: 32 ids ($01-$20). Id 0 = StopAll.
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

SndHdr08:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd08_Sfx2

SndHdr09:
	SND_HEADER $08, $08 ; tracks: Ch1
	dw Snd09_Ch1

SndHdr0A:
	SND_HEADER $04, $05 ; tracks: Sfx1, SfxN
	dw Snd0A_Sfx1
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $04, $05 ; tracks: Sfx1, SfxN
	dw Snd0B_Sfx1
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $04, $05 ; tracks: Sfx1, SfxN
	dw Snd0C_Sfx1
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $04, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $04, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $04, $03 ; tracks: Sfx1, Sfx2
	dw Snd0F_Sfx1
	dw Snd0F_Sfx2

SndHdr10:
	SND_HEADER $04, $22 ; tracks: Sfx2, Ch3
	dw Snd10_Sfx2
	dw Snd10_Ch3

SndHdr11:
	SND_HEADER $04, $22 ; tracks: Sfx2, Ch3
	dw Snd11_Sfx2
	dw Snd11_Ch3

SndHdr12:
	SND_HEADER $08, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $03, $04 ; tracks: SfxN
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $04, $04 ; tracks: SfxN
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $04, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $04, $04 ; tracks: SfxN
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $04, $05 ; tracks: Sfx1, SfxN
	dw Snd17_Sfx1
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $08, $04 ; tracks: SfxN
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $10, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd19_Ch1
	dw Snd19_Ch2
	dw Snd19_Ch3
	dw Snd19_Drm

SndHdr1B:
	SND_HEADER $10, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd1B_Ch1
	dw Snd1B_Ch2
	dw Snd1B_Ch3
	dw Snd1B_Drm

SndHdr1A:
	SND_HEADER $10, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd1A_Ch1
	dw Snd1A_Ch2
	dw Snd1A_Ch3
	dw Snd1A_Drm

SndHdr1C:
	SND_HEADER $10, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd1C_Ch1
	dw Snd1C_Ch2
	dw Snd1C_Ch3
	dw Snd1C_Drm

SndHdr1D:
	SND_HEADER $10, $30 ; tracks: Ch2, Ch3
	dw Snd1D_Ch2
	dw Snd1D_Ch3

SndHdr1E:
	SND_HEADER $10, $30 ; tracks: Ch2, Ch3
	dw Snd1E_Ch2
	dw Snd1E_Ch3

SndHdr1F:
	SND_HEADER $10, $30 ; tracks: Ch2, Ch3
	dw Snd1F_Ch2
	dw Snd1F_Ch3

SndHdr20:
	SND_HEADER $10, $30 ; tracks: Ch2, Ch3
	dw Snd20_Ch2
	dw Snd20_Ch3

; Drum map: DRUM n plays sound DrumMap[n-1] (13 entries).
DrumMap:
	db $01, $02, $01, $03, $03, $03, $03, $04, $05, $06, $07, $07, $07

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

SndHdr07:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd07_SfxN

Snd01_SfxN:
	NVOICE 1, 4, 2
	NOISE $31
	SND_END

Snd02_SfxN:
	NVOICE 7, 6, 1
	NOISE $31
	SND_END

Snd03_SfxN:
	NVOICE 1, 6, 1
	NOISE $31
	NVOICE $40, $0F, 4
	NOISE $00
	SND_END

Snd04_SfxN:
	NVOICE 1, $0F, 1
	NOISE $44
	NOISE $44
	NVOICE $40, 0, 3
	NOISE $85
	NOISE $36
	SND_END

Snd05_SfxN:
	NVOICE 1, 6, 1
	NOISE $40
	NVOICE 8, 6, 3
	NOISE $10
	SND_END

Snd06_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE $40, 6, 3
	NOISE $43
	SND_END

Snd07_SfxN:
	NVOICE 1, 7, 1
	NOISE $36
	NOISE $23
	SND_END

; Vibrato table: 15 entries (several share Vib01).
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib03 ; 3
	dw Vib01 ; 4
	dw Vib01 ; 5
	dw Vib01 ; 6
	dw Vib01 ; 7
	dw Vib01 ; 8
	dw Vib09 ; 9
	dw Vib0A ; 10
	dw Vib01 ; 11
	dw Vib0C ; 12
	dw Vib0D ; 13
	dw Vib01 ; 14
	dw Vib0F ; 15

Vib01:
	VIB_STEP 1, 0, $001
	VIB_HOLD

Vib02:
	VIB_STEP 1, 1, $001
	VIB_HOLD

Vib03:
	VIB_STEP 1, 1, $002
	VIB_HOLD

Vib0D:
	VIB_STEP 15, 0, $000
	VIB_STEP 2, 0, $001
	VIB_SEGNO
	VIB_STEP 3, 0, $002
	VIB_STEP 3, 0, $000
	VIB_REPEAT $FF

Vib09:
	VIB_STEP 8, 0, $000

Vib0A:
	VIB_STEP 14, 0, $000
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $002
	VIB_SEGNO
	VIB_STEP 4, 0, $003
	VIB_STEP 4, 0, $000
	VIB_REPEAT $FF

Vib0C:
	VIB_STEP 6, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $002
	VIB_SEGNO
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib0F:
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $002
	VIB_STEP 1, 0, $003
	VIB_STEP 1, 0, $004
	VIB_STEP 1, 0, $005
	VIB_STEP 1, 0, $006
	VIB_STEP 1, 0, $007
	VIB_STEP 1, 0, $008
	VIB_STEP 1, 0, $009
	VIB_STEP 1, 0, $00A
	VIB_STEP 1, 0, $00B
	VIB_STEP 1, 0, $00C
	VIB_HOLD

Snd08_Sfx2:
	VOICE 6, $0F, 8, 5, $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 3
	SND_END

Snd09_Ch1:
	VOICE 1, 8, 3, 0, 0
	OCTAVE 1
Snd09_Ch1_70D8:
	DUTY $0C
	NOTE F#, 1
	DUTY 4
	NOTE G_, 1
	SND_JUMP Snd09_Ch1_70D8

Snd0B_Sfx1:
	VOICE 7, $0F, 4, 0, 0
	SWEEP $1C
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	ATTEN 2
	NOTE C_HI, 1
	VOICE 6, 6, 8, 7, $0F
	SWEEP $08
	OCTAVE 6
	VIBRATO $0F
	NOTE C_HI, 8
	SND_END

Snd0B_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE 9, $0F, 5
	NOISE $46
	NOISE $34
	NVOICE 9, $0F, 6
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd0A_Sfx1:
	VOICE 7, $0F, 4, 0, 0
	SWEEP $1C
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 8
	NOTE B_, 1
	VOICE 7, 4, 4, 0, 0
	NOTE A_, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	SND_END

Snd0A_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE 9, $0F, 5
	NOISE $46
	NOISE $56
	NOISE $55
	NOISE $56
	NOISE $55
	NOISE $52
	NOISE $52
	SND_END

Snd0D_Sfx1:
	VOICE 1, $0F, 8, 1, $0F
	OCTAVE 3
	SND_JUMP Snd0D_Sfx1_714C
Snd0D_Sfx1_713B:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_RET

Snd0E_Sfx1:
	VOICE 1, $0F, 0, 1, $0F
	OCTAVE 4
	SND_CALL Snd0D_Sfx1_713B
Snd0D_Sfx1_714C:
	SND_SEGNO
	SND_CALL Snd0D_Sfx1_713B
	SND_REPEAT 2
	TRANSPOSE_UP 1
	ATTEN 2
	SND_CALL Snd0D_Sfx1_713B
	TRANSPOSE_UP 2
	ATTEN 4
	SND_CALL Snd0D_Sfx1_713B
	TRANSPOSE_UP 3
	ATTEN 8
	SND_CALL Snd0D_Sfx1_713B
	SND_END
Snd10_Sfx2_7165:
	VIBRATO 1
	VOICE 9, $0D, 4, 4, $0F
	SND_RET

Snd10_Sfx2:
	SND_CALL Snd10_Sfx2_7165
	OCTAVE 3
	NOTE A_, 4
	SND_END

Snd11_Sfx2:
	SND_CALL Snd10_Sfx2_7165
	OCTAVE 4
	NOTE A_, 6
	SND_END
Snd10_Ch3_7178:
	VOICE 1, 6, 4, 0, 0
	REST 1
	LEN_UNIT 9
	SND_RET

Snd10_Ch3:
	SND_CALL Snd10_Ch3_7178
	OCTAVE 3
	NOTE A_, 4
	SND_END

Snd11_Ch3:
	SND_CALL Snd10_Ch3_7178
	OCTAVE 4
	NOTE A_, 6
	SND_END

Snd12_Sfx1:
	SND_SEGNO
	VOICE 1, $0C, 0, 0, 0
	OCTAVE 5
	NOTE D_, 1
	DUTY 8
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 5
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 0
	SND_REPEAT 4
	SND_END

Snd13_SfxN:
	NVOICE 1, 6, 1
	NOISE $06
	NVOICE $10, 8, 9
	NOISE $01
	NVOICE $1F, 8, 4
	NOISE $00
	SND_END

Snd14_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE 8, 6, 3
	NOISE $43
	NVOICE 1, 6, 1
	NOISE $31
	NVOICE $10, 8, 4
	NOISE $00
	SND_END

Snd16_SfxN:
	NVOICE 3, 8, 6
	NOISE $41
	NOISE $47
	NOISE $41
	NOISE $46
	NOISE $41
	NOISE $45
	NOISE $41
	NOISE $44
	NOISE $41
	NOISE $45
	NOISE $41
	NOISE $46
	NOISE $41
	NOISE $44
	NOISE $41
	NOISE $45
	NOISE $41
	NOISE $46
	SND_END

Snd15_Sfx1:
	VOICE 1, 6, 8, 1, $0F
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd17_Sfx1:
	VOICE 1, $0F, 4, 0, 0
	OCTAVE 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	SND_END

Snd17_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE 8, 6, 3
	NOISE $46
	NVOICE 1, 6, 1
	NOISE $31
	NVOICE $10, 8, 4
	NOISE $32
	SND_END

Snd18_SfxN:
	NVOICE 8, 4, 9
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $50
	NVOICE 8, 0, 9
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $42
	NOISE $41
	NOISE $42
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $42
	NOISE $44
	NVOICE 8, $0C, 7
	NOISE $45
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd0C_Sfx1:
	VOICE 1, 4, 8, 0, 0
	OCTAVE 6
	NOTE A_, 2
	REST 2
	NOTE C_HI, 2
	SND_END

Snd0C_SfxN:
	NVOICE 1, $0F, 0
	NOISE $33
	NVOICE 2, $0C, 1
	NOISE $13
	NOISE $14
	SND_END

Snd0F_Sfx1:
	VOICE 6, $0D, 4, 1, $0F
	OCTAVE 4
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D#, 1
	ATTEN 5
	SND_SEGNO
	OCTAVE 4
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D#, 1
	ATTEN 9
	SND_REPEAT 2
	SND_END

Snd0F_Sfx2:
	VOICE 6, $0B, 4, 1, $0F
	VIBRATO 2
	OCTAVE 4
	REST 1
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D#, 1
	ATTEN 5
	SND_SEGNO
	OCTAVE 4
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D#, 1
	ATTEN 9
	SND_REPEAT 2
	SND_END

Snd19_Ch2:
	TEMPO $18
Snd19_Ch2_727B:
	SND_SEGNO
	SND_CALL Snd19_Ch2_72A2
	PAN $F0
	RELEASE 1, $0F
	OCTAVE 4
	NOTE D_, 3
	PAN $0F
	RELEASE 3, $0F
	NOTE D_, 3
	SND_CALL Snd19_Ch2_72A2
	PAN $F0
	RELEASE 1, $0F
	OCTAVE 4
	NOTE D#, 3
	PAN $0F
	RELEASE 3, $0F
	NOTE D_, 3
	TRANSPOSE_UP 6
	SND_REPEAT 2
	TRANSPOSE_UP 0
	SND_JUMP Snd19_Ch2_727B
Snd19_Ch2_72A2:
	PAN $FF
	VOICE 7, $0A, 4, 1, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 1
	NOTE A#, 2
	RELEASE 2, $0F
	NOTE G_, 3
	NOTE A#, 3
	RELEASE 1, $0F
	NOTE A#, 3
	RELEASE 3, $0F
	NOTE C_HI, 4
	DUTY 0
	SND_RET

Snd19_Ch1:
	SND_SEGNO
	SND_CALL Snd19_Ch1_72E7
	PAN $F0
	RELEASE 1, $0F
	NOTE A_, 3
	PAN $0F
	LEN_UNIT 4
	RELEASE 3, $0F
	NOTE A_, 5
	SND_CALL Snd19_Ch1_72E7
	PAN $F0
	RELEASE 1, $0F
	NOTE A#, 3
	PAN $0F
	LEN_UNIT 4
	RELEASE 3, $0F
	NOTE A_, 5
	TRANSPOSE_UP 6
	SND_REPEAT 2
	TRANSPOSE_UP 0
	SND_JUMP Snd19_Ch1
Snd19_Ch1_72E7:
	PAN $FF
	VOICE 1, 9, $0C, 1, $0F
	REST 1
	LEN_UNIT 7
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 2
	RELEASE 2, $0F
	NOTE D_, 3
	NOTE F_, 3
	RELEASE 1, $0F
	NOTE F_, 3
	RELEASE 3, $0F
	NOTE G_, 4
	DUTY 0
	SND_RET

Snd19_Ch3:
	SND_SEGNO
	SND_CALL Snd19_Ch3_732F
	PAN $F0
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	PAN $0F
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	SND_CALL Snd19_Ch3_732F
	PAN $F0
	ATTEN 0
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 1
	PAN $0F
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	TRANSPOSE_UP 6
	SND_REPEAT 2
	TRANSPOSE_UP 0
	SND_JUMP Snd19_Ch3
Snd19_Ch3_732F:
	VOICE 7, 2, 7, 3, $0A
	ATTEN 0
	PAN $FF
	OCTAVE 3
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE F_, 2
	ATTEN 2
	NOTE F_, 2
	SND_RET

Snd19_Drm:
	DRUM_UNIT 7
Snd19_Drm_7359:
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_SEGNO
	DRUM 1, 1
	SND_REPEAT $1A
	SND_JUMP Snd19_Drm_7359

Snd1A_Ch2:
	TEMPO $20
	VOICE 1, $0A, 8, 0, 0
	PAN $F0
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	PAN $0F
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	VOICE 6, $0A, 8, 3, 8
	NOTE E_, 2
	VOICE 6, $0A, 4, 1, $0F
	PAN $FF
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	RELEASE 2, $0F
	NOTE E_, 3
	RELEASE 1, $0F
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 4
	NOTE F_, 1
	ATTEN 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	ATTEN 0
	SND_REPEAT 2
	OCTAVE 4
	NOTE F_, 1
	ATTEN 1
	NOTE D_, 1
	SND_SEGNO
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	SND_REPEAT 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	RELEASE 2, $0F
	NOTE A#, 3
	NOTE G#, 2
	VOICE 6, $0A, 8, 1, $0F
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 1, $0F
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 2
	SND_END

Snd1A_Ch1:
	VOICE 1, 9, 8, 0, 0
	PAN $F0
	OCTAVE 2
	NOTE B_, 4
	NOTE C_HI, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	PAN $0F
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	VOICE 6, 9, 4, 3, 8
	OCTAVE 4
	NOTE G_, 2
	RELEASE 1, $0F
	PAN $FF
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	NOTE B_, 1
	RELEASE 2, $0F
	NOTE C_HI, 3
	RELEASE 1, $0F
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 1
	NOTE C_HI, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 2
	VIBRATO 2
	ATTEN 1
	PAN $0F
	RELEASE 1, $0F
	OCTAVE 3
	NOTE C#, 2
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	PAN $FF
	ATTEN 0
	VIBRATO 0
	RELEASE 1, $0F
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 2
	SND_END

Snd1A_Ch3:
	VOICE 1, 2, 7, 0, 0
	OCTAVE 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_HI, 4
	OCTAVE 5
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	VOICE 6, 2, 3, 3, $0F
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	SND_SEGNO
	NOTE C_HI, 1
	NOTE C_, 1
	SND_REPEAT 5
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	RELEASE 6, $0F
	NOTE D#, 3
	NOTE C#, 2
	RELEASE 3, $0F
	NOTE C#, 1
	SND_SEGNO
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	SND_REPEAT 5
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 2
	SND_END

Snd1A_Drm:
	DRUM_UNIT 6
	REST 8
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_REPEAT 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	SND_SEGNO
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT 4
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	SND_SEGNO
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT 3
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	SND_END

Snd1B_Ch3:
	TEMPO $20
	PAN $F0
	SND_SEGNO
	VOICE 6, 2, 8, 4, $0F
	OCTAVE 5
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	RELEASE 8, $0F
	NOTE G_, 3
	SND_REPEAT 2
	RELEASE 4, $0F
	NOTE G_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	PAN $0F
	SND_SEGNO
	RELEASE 4, $0F
	OCTAVE 5
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C_HI, 1
	RELEASE 8, $0F
	NOTE A#, 3
	SND_REPEAT 2
	PAN $FF
	TEMPO $40
	VOICE 1, 2, 8, 3, $0F
	OCTAVE 4
	NOTE A#, 3
	NOTE G#, 3
	NOTE F#, 3
	NOTE G#, 3
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 5
	NOTE C#, 3
	NOTE D#, 3
	TEMPO $18
	VOICE 6, 2, 2, 5, $0F
	OCTAVE 4
	NOTE F#, 3
	NOTE F_, 3
	NOTE G#, 3
	NOTE F#, 3
	NOTE F_, 2
	NOTE C#, 2
	NOTE B_, 3
	NOTE A#, 2
	VOICE 6, 2, 7, 3, $0F
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	VIBRATO 1
	OCTAVE 6
	NOTE C#, 1
	NOTE D#, 1
	VIBRATO 0
	RELEASE 2, 9
	WAVE 2
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 2
	ATTEN 0
	PAN $0F
	SND_REPEAT 2
	PAN $FF
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	SND_END

Snd1B_Ch1:
	VOICE 6, 9, 4, 3, $0F
	OCTAVE 3
	NOTE F_, 3
	NOTE D#, 3
	NOTE F_, 3
	NOTE D#, 3
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 3
	NOTE F#, 3
	NOTE G#, 3
	NOTE F#, 3
	VOICE 1, 9, 8, 3, $0F
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F#, 3
	NOTE G#, 3
	NOTE A#, 3
	NOTE B_, 3
	VOICE 6, 9, 4, 2, $0F
	OCTAVE 3
	NOTE A#, 3
	NOTE G#, 3
	ATTEN 1
	OCTAVE 4
	NOTE F_, 3
	OCTAVE 3
	NOTE A#, 3
	RELEASE 2, $0F
	NOTE G#, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE D#, 3
	NOTE C#, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	RELEASE 1, $0F
	SND_SEGNO
	NOTE A#, 2
	NOTE A#, 1
	NOTE G#, 3
	PAN $0F
	SND_REPEAT 2
	PAN $FF
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	SND_END

Snd1B_Ch2:
	VOICE 6, 9, 4, 3, $0F
	OCTAVE 2
	NOTE C_HI, 3
	NOTE A#, 3
	NOTE C_HI, 3
	NOTE A#, 3
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 3
	NOTE C#, 3
	NOTE D#, 3
	NOTE C#, 3
	VOICE 1, $0A, 8, 3, $0F
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F#, 3
	VOICE 6, $0A, 0, 0, 5
	SND_SEGNO
	PAN $F0
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	PAN $0F
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	SND_REPEAT 2
	PAN $F0
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	SND_SEGNO
	PAN $0F
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	PAN $F0
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	SND_REPEAT 2
	PAN $0F
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	PAN $FF
	SND_SEGNO
	ATTEN 0
	OCTAVE 3
	NOTE C#, 1
	ATTEN 5
	NOTE C#, 1
	ATTEN 0
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 5
	NOTE C#, 1
	NOTE C#, 1
	SND_REPEAT 2
	ATTEN 0
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	SND_END

Snd1B_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 9, 3
	DRUM 1, 2
	DRUM 1, 1
	DRUM 9, 3
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	SND_END

Snd1C_Ch2:
	TEMPO $20
	VOICE 6, 9, 4, 1, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 3
	VOICE 1, 9, 4, 8, $0F
	OCTAVE 4
	NOTE D_, $0F
	REST 1
	PAN $F0
	RELEASE 1, $0F
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE A#, 4
	PAN $0F
	OCTAVE 6
	NOTE D_, 4
	OCTAVE 5
	NOTE A#, 4
	NOTE F_, 4
	PAN $F0
	NOTE D_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE F_, 4
	PAN $FF
	ATTEN 0
	VOICE 6, 9, 8, 2, $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 2
	TEMPO $50
	REST 1
	TEMPO $60
	RELEASE 2, $0F
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	SND_END

Snd1C_Ch1:
	VOICE 6, 8, 4, 1, $0F
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 3
	VOICE 1, 8, 4, 7, $0F
	ATTEN 4
	NOTE A#, $0F
	PAN $F0
	RELEASE 0, 0
	OCTAVE 4
	NOTE F_, 9
	NOTE A#, 4
	OCTAVE 5
	NOTE D_, 4
	NOTE F_, 4
	PAN $0F
	NOTE A#, 4
	OCTAVE 6
	NOTE D_, 4
	OCTAVE 5
	NOTE A#, 4
	PAN $F0
	NOTE F_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE A#, 4
	PAN $FF
	ATTEN 0
	VOICE 6, 8, 8, 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	REST 1
	RELEASE 2, $0F
	OCTAVE 5
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	SND_END

Snd1C_Ch3:
	VOICE 6, 2, 7, 3, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE B_, 3
	RELEASE 8, 8
	NOTE C_HI, $0A
	RELEASE 3, $0F
	WAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 2
	LEN_UNIT 1
	REST 7
	VOICE 6, 2, 2, 8, $0A
	OCTAVE 2
	NOTE E_, 3
	RELEASE 0, 0
	ATTEN 2
	NOTE E_, 2
	SND_END

Snd1C_Drm:
	DRUM_UNIT 1
	SND_SEGNO
	DRUM 9, 6
	DRUM 1, 6
	DRUM 1, 6
	DRUM 1, 6
	SND_REPEAT 3
	DRUM 1, 6
	DRUM 1, 6
	DRUM 4, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	SND_SEGNO
	DRUM 1, 6
	SND_REPEAT 6
	DRUM 9, $0C
	DRUM 9, $0C
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, 6
	REST 6
	REST 6
	REST 1
	DRUM 9, 6
	SND_END

Snd1D_Ch2:
	TEMPO $50
Snd1D_Ch2_770E:
	SND_CALL Snd1D_Ch2_77A7
	DUTY 8
	RELEASE 0, 0
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	OCTAVE 4
	NOTE E_, 4
	VOICE 5, 8, 4, 1, $0F
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 3
	SND_CALL Snd1D_Ch2_77A7
	LEN_UNIT 5
	OCTAVE 3
	NOTE F#, 3
	NOTE F#, 3
	RELEASE 1, $0F
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 1
	VOICE 1, 8, 8, 2, $0F
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE F#, 4
	SND_CALL Snd1D_Ch2_77E9
	RELEASE 3, $0F
	NOTE G#, 3
	NOTE E_, 1
	REST 4
	SND_CALL Snd1D_Ch2_77E9
	RELEASE 3, $0F
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 1
	REST 4
	TRANSPOSE_DOWN 2
	SND_CALL Snd1D_Ch2_77E9
	RELEASE 3, $0F
	NOTE G#, 3
	NOTE E_, 1
	REST 4
	SND_CALL Snd1D_Ch2_77E9
	OCTAVE 4
	RELEASE 3, $0F
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 1
	REST 4
	TRANSPOSE_UP 0
	SND_SEGNO
	REST 1
	OCTAVE 3
	NOTE G_, 3
	NOTE E_, 1
	REST 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 2
	NOTE D_, 1
	RELEASE 1, $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	RELEASE 3, $0F
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A_, 1
	REST 2
	OCTAVE 1
	NOTE A_, 1
	RELEASE 1, $0F
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 2, $0C
	OCTAVE 3
	NOTE F#, 3
	SND_REPEAT 2
	SND_JUMP Snd1D_Ch2_770E
Snd1D_Ch2_77A7:
	SND_SEGNO
	VOICE 5, 8, 4, 2, $0F
	OCTAVE 4
	NOTE F#, 3
	RELEASE 4, $0F
	NOTE E_, 3
	PAN $0F
	ATTEN 3
	RELEASE 3, $0F
	NOTE F#, 3
	RELEASE 4, $0F
	NOTE E_, 3
	PAN $FF
	RELEASE 2, $0F
	ATTEN 0
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE A#, 3
	DUTY 8
	RELEASE 3, $0F
	OCTAVE 3
	NOTE E_, 3
	RELEASE 4, $0F
	NOTE C#, 3
	RELEASE 1, $0F
	NOTE B_, 2
	NOTE B_, 1
	RELEASE 4, $0F
	NOTE A#, 5
	SND_REPEAT 2
	DUTY 4
	RELEASE 2, $0F
	OCTAVE 4
	NOTE G#, 3
	NOTE G#, 2
	NOTE G#, 3
	LEN_UNIT 1
	NOTE F#, 7
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 7
	NOTE F#, 7
	NOTE B_, 6
	OCTAVE 5
	NOTE E_, 7
	SND_RET
Snd1D_Ch2_77E9:
	VOICE 5, 8, 4, 2, $0F
	SND_SEGNO
	PAN $F0
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	SND_REPEAT 3
	PAN $FF
	RELEASE 1, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 2
	SND_RET
	db $FF

Snd1D_Ch3:
	VIBRATO 3
Snd1D_Ch3_780B:
	SND_CALL Snd1D_Ch3_7869
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_CALL Snd1D_Ch3_7869
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	SND_CALL Snd1D_Ch3_78B0
	TRANSPOSE_DOWN 2
	SND_CALL Snd1D_Ch3_78B0
	TRANSPOSE_UP 0
	SND_SEGNO
	RELEASE 4, $0C
	NOTE A_, 3
	NOTE G#, 4
	RELEASE 3, $0C
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT 2
	SND_JUMP Snd1D_Ch3_780B
Snd1D_Ch3_7869:
	SND_SEGNO
	VOICE 5, 2, 2, 2, $0F
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	SND_REPEAT 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	SND_RET
Snd1D_Ch3_78B0:
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_REPEAT 4
	SND_RET
	db $FF

Snd1E_Ch2:
	TEMPO $34
	TRANSPOSE_UP 4
Snd1E_Ch2_78CF:
	VOICE 4, 8, $0C, 2, $0F
	OCTAVE 3
	NOTE C_, 2
	SND_CALL Snd1E_Ch2_7986
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_HI, 4
	SND_CALL Snd1E_Ch2_7986
	RELEASE 1, $0A
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	DUTY 8
	RELEASE 3, $0F
	OCTAVE 4
	NOTE E_, 4
	SND_CALL Snd1E_Ch2_79CA
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	SND_CALL Snd1E_Ch2_79CA
	OCTAVE 3
	NOTE D_, 4
	NOTE C_, 2
	NOTE E_, 4
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 1, $0A
	DUTY 4
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE C_HI, 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 2
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 2
	SND_REPEAT 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE A_, 2
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE A_, 2
	SND_REPEAT 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	DUTY $0C
	SND_JUMP Snd1E_Ch2_78CF
Snd1E_Ch2_7986:
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	SND_RET

; Unreferenced data (41 bytes).
Orphan_79A1:
	db $E3, $82, $62, $E2, $82, $E3, $82, $E2, $82, $E3, $62, $E2, $82, $E3, $82, $E2
	db $82, $E3, $62, $B2, $E2, $82, $E3, $D2, $E2, $82, $E3, $A4, $A2, $82, $E2, $82
	db $E3, $62, $E2, $82, $E3, $52, $E2, $82, $FC
Snd1E_Ch2_79CA:
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 4
	RELEASE 1, 8
	OCTAVE 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE A_, 2
	SND_RET

Snd1E_Ch3:
	VOICE 4, 2, 2, 0, 0
	TRANSPOSE_UP 4
	VIBRATO 2
Snd1E_Ch3_79FB:
	SND_CALL Snd1E_Ch3_7A7E
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	OCTAVE 1
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	SND_CALL Snd1E_Ch3_7A7E
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 1
	NOTE C_HI, 4
	SND_CALL Snd1E_Ch3_7A9E
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_HI, 2
	SND_CALL Snd1E_Ch3_7A9E
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_JUMP Snd1E_Ch3_79FB
Snd1E_Ch3_7A7E:
	OCTAVE 1
	NOTE A#, 1
	RELEASE 4, $0F
	NOTE C_HI, 1
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE A#, 1
	RELEASE 4, $0F
	NOTE C_HI, 1
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	SND_RET
Snd1E_Ch3_7A9E:
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G_, 2
	SND_RET

Snd1F_Ch3:
	TEMPO $84
	VOICE 3, 4, 9, 8, $0A
	VIBRATO $0D
	OCTAVE 1
	NOTE D#, $0C
	RELEASE 4, $0F
	NOTE C#, 3
	NOTE E_, 5
	PAN $0F
	NOTE C_, 3
	RELEASE 7, $0F
	NOTE E_, 9
	PAN $FF
	ATTEN 0
	RELEASE 2, $0F
	NOTE D#, 1
	NOTE D#, 2
	RELEASE 7, $0A
	NOTE D#, 7
	RELEASE 3, $0F
	NOTE D#, 2
	NOTE C#, 2
	NOTE E_, 2
	RELEASE 2, $0F
	NOTE G#, 6
	NOTE G#, 1
	NOTE G#, 3
	VOICE 1, 4, 9, 7, $0F
	NOTE E_, $0E
	VOICE 1, 2, 7, 7, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
Snd1F_Ch3_7AF1:
	SND_CALL Snd1F_Ch3_7B53
	NOTE G#, 4
	WAVE 4
	OCTAVE 4
	NOTE C#, 4
	NOTE G#, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 4
	SND_CALL Snd1F_Ch3_7B53
	VIBRATO $0C
	RELEASE 4, 6
	NOTE G#, 8
	OCTAVE 5
	NOTE C#, 8
	NOTE C_, 8
	VOICE 2, 2, 7, 0, 0
	NOTE E_, $0A
	VOICE 2, 4, 2, 0, 0
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	VOICE 4, 4, 2, 4, 8
	NOTE C#, 8
	RELEASE 2, 8
	NOTE D#, 2
	NOTE E_, 2
	RELEASE 5, 8
	NOTE F#, 6
	NOTE G#, 6
	NOTE E_, 8
	RELEASE 2, 8
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 5, 8
	NOTE A_, 6
	NOTE B_, 6
	RELEASE 2, 8
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 3, 5
	NOTE A_, 6
	OCTAVE 4
	NOTE C_, 6
	LEN_UNIT 2
	OCTAVE 3
	NOTE G_, 9
	RELEASE 0, 0
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	RELEASE 7, 6
	NOTE D#, $0C
	VIBRATO $0D
	SND_JUMP Snd1F_Ch3_7AF1
Snd1F_Ch3_7B53:
	VOICE 4, 2, 7, 7, 8
	OCTAVE 5
	NOTE D#, 8
	RELEASE 2, 8
	NOTE C#, 2
	OCTAVE 4
	NOTE G#, 2
	LEN_UNIT 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F#, 4
	SND_RET
	db $FF

Snd1F_Ch2:
	VOICE 3, 9, 4, 8, 8
	SND_CALL Snd1F_Ch2_7C87
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 1
	ATTEN 1
	RELEASE 1, $0F
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	RELEASE 8, 8
	SND_REPEAT 4
	OCTAVE 1
	NOTE G#, 1
	RELEASE 1, $0F
	ATTEN 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	ATTEN 0
Snd1F_Ch2_7B97:
	SND_CALL Snd1F_Ch2_7C87
	SND_CALL Snd1F_Ch2_7C87
	SND_CALL Snd1F_Ch2_7C87
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	ATTEN 2
	RELEASE 1, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 8, 8
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	ATTEN 2
	RELEASE 1, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	RELEASE 8, 8
	SND_REPEAT 4
	DUTY 8
	OCTAVE 2
	NOTE F#, 1
	ATTEN 2
	RELEASE 1, $0F
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	RELEASE 8, 8
	OCTAVE 2
	NOTE G#, 1
	ATTEN 2
	RELEASE 1, $0F
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 0
	RELEASE 8, 8
	NOTE A_, 1
	ATTEN 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 8, 8
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	ATTEN 0
	RELEASE 8, 8
	DUTY 4
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	RELEASE 1, $0F
	ATTEN 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 8, 8
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	RELEASE 1, $0F
	ATTEN 2
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	RELEASE 8, 8
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	RELEASE 1, $0F
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	RELEASE 8, 8
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	RELEASE 1, $0F
	ATTEN 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	RELEASE 8, 8
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	RELEASE 1, $0F
	ATTEN 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 8, 8
	ATTEN 0
	SND_REPEAT 4
	RELEASE 0, 8
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_JUMP Snd1F_Ch2_7B97
Snd1F_Ch2_7C87:
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 1
	ATTEN 1
	RELEASE 1, $0F
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	RELEASE 8, 8
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	RELEASE 1, $0F
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 0
	RELEASE 8, 8
	SND_REPEAT 4
	SND_RET

Snd20_Ch2:
	TEMPO $34
	VIBRATO 9
	VOICE 5, 9, 8, 6, 5
	OCTAVE 4
	NOTE E_, $0A
	RELEASE 1, $0C
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 2
	RELEASE 6, 5
	NOTE D_, $0B
	RELEASE 1, $0C
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 2
	RELEASE 6, 5
	NOTE C_, $0B
	RELEASE 1, $0C
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE C_HI, 1
	REST 1
	RELEASE 2, 6
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 1
	NOTE D_, 1
Snd20_Ch2_7CDB:
	RELEASE 1, $0C
	SND_SEGNO
	OCTAVE 4
	NOTE D#, 1
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	SND_REPEAT 2
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 2
	RELEASE 0, 0
	NOTE G_, 1
	SND_SEGNO
	SND_CALL Snd20_Ch2_7DD3
	NOTE F_, 1
	VIBRATO 9
	RELEASE 4, $0A
	NOTE G_, 7
	RELEASE 2, $0B
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	RELEASE 4, $0F
	NOTE A#, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	SND_CALL Snd20_Ch2_7DD3
	NOTE D_, 1
	NOTE C_, 2
	ATTEN 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 2
	ATTEN 0
	RELEASE 2, $0C
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	VIBRATO 0
	RELEASE 4, $0F
	OCTAVE 5
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	SND_CALL Snd20_Ch2_7DEF
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	DUTY 4
	ATTEN 2
	RELEASE 0, 6
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 0
	DUTY 8
	SND_CALL Snd20_Ch2_7DEF
	NOTE E_, 3
	NOTE D_, 3
	NOTE F_, 3
	DUTY 4
	RELEASE 0, 6
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	TRANSPOSE_UP 3
	DUTY 8
	SND_CALL Snd20_Ch2_7DEF
	TRANSPOSE_UP 0
	NOTE A#, 3
	NOTE G#, 3
	NOTE G_, 3
	NOTE F_, 2
	NOTE D#, 2
	DUTY 4
	RELEASE 0, 6
	NOTE F_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	NOTE F_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	RELEASE 2, $0F
	DUTY 4
	OCTAVE 3
	NOTE A_, 1
	DUTY 8
	ATTEN 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 0
	DUTY 4
	NOTE B_, 1
	DUTY 8
	ATTEN 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	DUTY 4
	NOTE C_HI, 1
	DUTY 8
	ATTEN 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	REST 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	SND_REPEAT 2
	SND_CALL Snd20_Ch2_7E02
	SND_SEGNO
	OCTAVE 4
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	SND_REPEAT 2
	NOTE F_, 1
	RELEASE 2, $0D
	NOTE F_, 3
	SND_CALL Snd20_Ch2_7E02
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	SND_REPEAT 2
	NOTE B_, 1
	RELEASE 2, 8
	NOTE B_, 3
	RELEASE 3, $0D
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 5
	SND_JUMP Snd20_Ch2_7CDB
Snd20_Ch2_7DD3:
	VIBRATO 9
	RELEASE 4, $0A
	OCTAVE 4
	NOTE G_, 8
	VIBRATO 0
	RELEASE 2, $0F
	NOTE E_, 2
	RELEASE 1, $0F
	NOTE F_, 1
	NOTE G_, 2
	RELEASE 3, $0F
	NOTE C_HI, 3
	RELEASE 4, $0F
	NOTE C_HI, 4
	NOTE A#, 4
	NOTE G_, 4
	NOTE F_, 4
	RELEASE 2, $0F
	NOTE E_, 2
	SND_RET
Snd20_Ch2_7DEF:
	VIBRATO $0A
	RELEASE 3, $0C
	OCTAVE 3
	NOTE C_HI, 6
	NOTE B_, 1
	NOTE C_HI, 1
	VIBRATO 0
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	RELEASE 3, $0F
	OCTAVE 4
	NOTE F_, 3
	SND_RET
Snd20_Ch2_7E02:
	RELEASE 2, $0C
	OCTAVE 4
	NOTE G_, 3
	NOTE G_, 2
	RELEASE 0, 6
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	RELEASE 3, $0A
	NOTE F_, 3
	LEN_UNIT 1
	NOTE G_, 3
	NOTE A_, 2
	LEN_UNIT 5
	NOTE A#, 4
	RELEASE 2, $0C
	NOTE G_, 3
	NOTE G_, 2
	RELEASE 0, 6
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_RET
	db $FF

Snd20_Ch3:
	VOICE 5, 2, 2, 0, 6
	OCTAVE 2
	SND_SEGNO
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	WAVE 2
	OCTAVE 3
	SND_REPEAT 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	WAVE 2
	OCTAVE 2
	SND_SEGNO
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	WAVE 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	WAVE 2
	OCTAVE 2
	SND_SEGNO
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	WAVE 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	WAVE 7
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	WAVE 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
Snd20_Ch3_7E8C:
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 2
	NOTE C_HI, 1
	SND_SEGNO
	SND_CALL Snd20_Ch3_7F6E
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE C_HI, 1
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_CALL Snd20_Ch3_7F6E
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE F#, 3
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	SND_CALL Snd20_Ch3_7F91
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_CALL Snd20_Ch3_7F91
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	TRANSPOSE_UP 3
	SND_CALL Snd20_Ch3_7F91
	TRANSPOSE_UP 0
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 6
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 2
	WAVE 8
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 1
	RELEASE 0, 6
	WAVE 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_REPEAT 2
	SND_CALL Snd20_Ch3_7FC0
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_CALL Snd20_Ch3_7FC0
	SND_SEGNO
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	SND_REPEAT 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_JUMP Snd20_Ch3_7E8C
Snd20_Ch3_7F6E:
	RELEASE 0, 8
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE C_HI, 1
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	SND_RET
Snd20_Ch3_7F91:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	VIBRATO 2
	OCTAVE 4
	NOTE C_, 1
	VIBRATO 0
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	VIBRATO 2
	OCTAVE 4
	NOTE D_, 1
	VIBRATO 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE C_, 1
	SND_RET
Snd20_Ch3_7FC0:
	OCTAVE 3
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	SND_RET

; Course music tempo, called by the game: if a course song ($1D-$20) is on
; CH3, wTempo = table[id - $1D]. Two tables (A = $7FF7, B = $7FFB).
SetCourseTempoB:
	ld hl, CourseTempoB
	jr SetCourseTempoA.l7FE6

SetCourseTempoA:
	ld hl, CourseTempoA
.l7FE6:
	ld a, [wTrkCh3]
	cp $1D
	ret c
	cp $21
	ret nc
	sub $1D
	rst $28
	ld a, [hl]
	ld [wTempo], a
	ret
CourseTempoA:
	db $28, $18, $70, $10
CourseTempoB:
	db $50, $38, $80, $30
BankEndPad:
	db $FF
