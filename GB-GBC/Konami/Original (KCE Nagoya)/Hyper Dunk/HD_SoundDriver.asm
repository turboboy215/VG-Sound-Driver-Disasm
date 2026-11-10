; ==========================================================================
; Hyper Dunk (U) - Konami sound driver (second-generation layout, Nemesis II track language)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: AddHLA (rst $28), SndUpdateFar ($0099-$00B5), PlaySoundFar and the bank helpers
;   bank 7: the driver ($4000-$4D0F), tables, headers and streams ($4D10-$6CD1), $FF to the end
; Build: rgbasm -Wall -o hd.o HD_SoundDriver.asm && rgblink -o hd.gb hd.o
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
DEF wTrkSfx1 EQU $C080 ; 62 bytes
DEF wTrkSfx2 EQU $C180 ; 62 bytes
DEF wTrkSfxN EQU $C280 ; 62 bytes
DEF wTrkCh1 EQU $C380 ; 62 bytes
DEF wTrkCh2 EQU $C480 ; 62 bytes
DEF wTrkCh3 EQU $C580 ; 62 bytes
DEF wTrkDrm EQU $C680 ; 62 bytes
DEF wTrackIdx EQU $C0C1
DEF wRegBase EQU $C0C2
DEF wTempo EQU $C0C3
DEF wTempoAcc EQU $C0C4
DEF wTempoSkip EQU $C0C5
DEF wQueuedSnd EQU $C0C6
DEF wNR51 EQU $C0C7
DEF wSweepVal EQU $C0C8
DEF wReqId EQU $C0C9
DEF wReqPrio EQU $C0CA
DEF wRegVal EQU $C0CB
DEF wRegIdx EQU $C0CC
DEF wMusicHold EQU $C0CD
DEF wC0D0 EQU $C0D0
DEF wFadeLevel EQU $C0D2
DEF wReqRefused EQU $C0D3
DEF wVarToneStart EQU $C0D4
DEF wVarToneIdx EQU $C0D5
DEF wVarTonePeriod EQU $C0D6
DEF wVarTonePtr EQU $C0D8
DEF wShadow EQU $C1BE ; 20 bytes
DEF wSndLock EQU $C00D
DEF wPauseFlags EQU $C014
DEF wRomBank EQU $C024
DEF wVarToneVar EQU $C122
DEF rROMB EQU $2000 ; MBC1 bank select

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
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
DEF TRK_ENVLOOPCNT EQU $8F
DEF TRK_FLOW EQU $90
DEF TRK_UNIT EQU $91
DEF TRK_OCTAVE EQU $92
DEF TRK_PERIOD EQU $93
DEF TRK_RAWLO EQU $95
DEF TRK_RAWHI EQU $96
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
DEF TRK_LOOPPTR EQU $A2
DEF TRK_LOOP2PTR EQU $A4
DEF TRK_RET EQU $A6
DEF TRK_SEGNO EQU $A8
DEF TRK_VIBPTR EQU $AA
DEF TRK_VIBIDX EQU $AC
DEF TRK_VIBLOOPIDX EQU $AD
DEF TRK_VIBDEPTH EQU $AE
DEF TRK_VIBDELAYUNITS EQU $AF
DEF TRK_VIBDELAYRELOAD EQU $B0
DEF TRK_VIBDELAY EQU $B1
DEF TRK_ENVNUM EQU $B2
DEF TRK_ENVTIMER EQU $B3
DEF TRK_ENVRELOAD EQU $B4
DEF TRK_ENVVOL EQU $B5
DEF TRK_ENVPTR EQU $B6
DEF TRK_ENVIDX EQU $B8
DEF TRK_ENVLOOPIDX EQU $B9
DEF TRK_DUTYCNT EQU $BA
DEF TRK_DUTYSTEP EQU $BB
DEF TRK_DUTYTICKS EQU $BC
DEF TRK_PAN EQU $BD

; TRK_FLAGS: 0 released, 1 autopan, 3 vibrato negate, 4 duty step, 6 force register writes, 7 rest
; TRK_FLAGS2: 0 envelope step pending (retrigger), 1 envelope held ($FF), 4+5 raw stream,
;   7 vibrato delay running
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
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #). Also ends an
; envelope table (TRK_ENVNUM = 0).
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
; $EA 2n: vibrato table n without touching the delay and depth (0 = off). Unused by the data
MACRO EXT_VIBRATO
	db $EA, $20 | \1
ENDM
MACRO DUTY
	db $EA, $30 | \1
ENDM
MACRO WAVE
	db $EA, $30 | \1
ENDM
; $EA 4n: TRK_FLAGS = n, then autopan bit (1) set for n != 0, cleared for 0. Unused by the data
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; $EB x, yz: vibrato table x (the whole byte), delay y * unit ticks (0 = none), depth z (offset * z; 0 = x1)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
; $EB 0: vibrato off (two bytes)
MACRO VIBRATO_OFF
	db $EB, \1
ENDM
; $EC n: volume envelope table n (0 = off): each step sets the note volume and lasts its ticks
MACRO ENVELOPE
	db $EC, \1
ENDM
; $ED xy: duty step. Each note starts with duty \1, the voice duty comes back after \2 ticks; $ED 0: off.
; Unused by the data
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
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
; envelope table: one byte per step: ticks to the next step, volume; $FB/$FE n/$FF as in the vibrato tables
MACRO ENV_STEP
	db (\1 << 4) | \2
ENDM

SECTION "AddHLA", ROM0[$0028]

; AddHLA (rst $28): HL += A
AddHLA:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "SndUpdateFar", ROM0[$0099]

; SndUpdateFar: called from the VBlank handler (after ei) while the game runs its normal VBlank
; path. Skipped while wSndLock bit 0 (an update) or bit 1 (a PlaySoundFar) is set; maps bank 7
; and gives the game its bank back from wRomBank.
SndUpdateFar:
	ld hl, wSndLock
	ld a, [hl]
	and $03
	ret nz
	set 0, [hl]
	ld a, $07
	ld [rROMB], a
	call SndUpdate
	ld a, [wRomBank]
	ld [rROMB], a
	ld hl, wSndLock
	res 0, [hl]
	ret

SECTION "PlaySoundFar", ROM0[$02B0]

; PlaySoundFar: A = sound id. Sets wSndLock bit 1, maps bank 7, PlaySound, then maps bank 1
; (always bank 1, whatever the caller had).
PlaySoundFar:
	push hl
	ld hl, wSndLock
	set 1, [hl]
	push de
	push bc
	push af
	ld c, a
	call MapBank7
	ld a, c
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

SetBank:
	di
	ld [rROMB], a
	ld [wRomBank], a
	ei
	pop af
	ret

SECTION "MapBank7", ROM0[$02F4]

MapBank7:
	push af
	ld a, $07
	jr SetBank

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

; SndInit (from the boot code): clears $80 bytes of every track page (that also clears the
; globals and the shadows), NR52 = $FF, NR51 = $FF, NR50 = $77.
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

; FadeTick: a bare ret. NoteVolume still adds wFadeLevel, which nothing writes.
FadeTick:
	ret ; FadeTick

; TempoTick: wTempoAcc += wTempo; wTempoSkip = the carry.
TempoTick:
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld a, $01
	jr c, .l4094
	xor a
.l4094:
	ld [wTempoSkip], a
	ret

; SndUpdate (once per VBlank): FadeTick (empty), TempoTick, then tracks 0-6. While
; wPauseFlags is non-zero only track 1 runs, and only for id $10 (the pause jingle). Otherwise
; the loop stops before track 3 when wTempoSkip or wMusicHold is set (the Ch2 test after it
; is unreachable). Last, wQueuedSnd is started (nothing writes it).
SndUpdate:
	call FadeTick
	call TempoTick
	xor a

SndUpdateLoop:
	ld [wTrackIdx], a
	ld a, [wPauseFlags]
	or a
	jr z, .l40BD
	ld a, [wTrackIdx]
	cp $01
	jr nz, SndUpdateNext
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	ld a, [wTrkSfx2]
	cp $10
	jr z, SndUpdateRun
	jr SndUpdateDone
.l40BD:
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
	add a, $C0
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

; TrackTick: TRK_LEN - 1. At 0: clear the released and rest flags; Sfx1/Ch1 playing id $11
; or $12 go to VarToneTick; Ch3 mutes CH3 (NR30 = 0) before the next note; then ReadCmds.
; Otherwise TrackSustain: nothing for rests, raw streams, SfxN and Drm; duty step, release
; flag (TRK_RELTICK >= TRK_LEN), VibratoTick, EnvTick; CH3 decays; an envelope writes its
; volume (EnvVolume); else at the release tick NRx2 = env | level and a trigger.
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
	ld a, [wRegBase]
	or a
	jp nz, .l412E
	ld l, TRK_ID
	ld a, [hl]
	cp $11
	jp z, VarToneTick
	cp $12
	jp z, VarToneTick
.l412E:
	ld a, [wTrackIdx]
	cp $05
	jp nz, ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp ReadCmds

TrackSustain:
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
	jr z, .l4162
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l4162:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l416E
	ld l, TRK_FLAGS
	set 0, [hl]
.l416E:
	call VibratoTick
	call EnvTick
	ld a, [wTrackIdx]
	cp $05
	jr z, Ch3Decay
	ld l, TRK_ENVNUM
	ld a, [hl]
	or a
	jp nz, EnvVolume
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	ret nz
	ld l, TRK_ENV
	ld a, [hl]
	ld l, TRK_LEVEL
	or [hl]
.l418F:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld l, TRK_ENVNUM
	ld a, [hl]
	or a
	jp z, Trigger
	ld l, TRK_FLAGS2
	bit 0, [hl]
	ret z
	ld l, TRK_FLAGS2
	bit 1, [hl]
	ret nz
	ld l, TRK_FLAGS2
	res 0, [hl]
	jp Trigger

EnvVolume:
	ld l, TRK_ENVVOL
	ld a, [hl]
	ld l, TRK_VOL
	ld [hl], a
	swap a
	jp TrackSustain.l418F

Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l41E9
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
	jr z, .l41E9
	inc a
	and $03
	ld [hl], a
	jr z, .l41E9
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l41E6
	xor a
.l41E6:
	rla
	swap a
.l41E9:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

ReadCmdsNext:
	inc de

; ReadCmds: $FB-$FF flow commands (CommandTable at the call), then ReadCmdsNoFlow.
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
	jp nz, .l421E
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds
.l421E:
	ld a, [de]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l422C
	ld l, TRK_LOOPPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l422C:
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
	jp nz, .l4248
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadCmds
.l4248:
	push hl
	ld a, [de]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l4258
	pop hl
	ld l, TRK_LOOP2PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l4258:
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
	jp nz, .l427E
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
.l427E:
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
	jp nz, .l429D
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l429D:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; $FF: end. Clears TRK_FLAGS2 bits 4-7, TRK_ID and TRK_PRIO, NRx2 = 0. Ch3: NR30 = 0. Sfx1 /
; Sfx2 / SfxN give the channel back to a playing music track (duty, NR51 bits, period); Sfx1
; and Sfx2 also write NR10 = 0. A Sfx2 that ends while Sfx1 plays the variable tone ($11/$12)
; requests $12 again.
Cmd_End:
	pop hl
	dec de
	ld l, TRK_FLAGS2
	ld a, [hl]
	and $0F
	ld [hl], a
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
	jr nz, .l42C8
	xor a
	ldh [rNR30], a
	ret
.l42C8:
	cp $02
	jr z, .l4306
	cp $01
	jr z, .l42DA
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l42F3
.l42DA:
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	cp $11
	jp z, .l42EC
	cp $12
	jp nz, .l42F1
.l42EC:
	ld a, $12
	call PlaySound
.l42F1:
	ld h, HIGH(wTrkCh2)
.l42F3:
	ld l, TRK_ID
	ld a, [hl]
	cp $00
	ret z
	push hl
	call WriteDuty
	pop hl
	push hl
	call GetPanBits
	pop hl
	jp .l4312
.l4306:
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	push hl
	call GetPanBits
	pop hl
.l4312:
	ld b, a
	call IsBlocked
	ld a, b
	jp c, .l4320
	or c
	ld [wNR51], a
	ldh [rNR51], a
.l4320:
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
	dw Cmd_Envelope
	dw Cmd_DutyStep
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

; $EA 2n: vibrato table n (0: off, offset cleared); TRK_VIBLOOPCNT = 0. Delay and depth stay.
Ext_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	or a
	jr nz, .l43CA
	xor a
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp ReadCmdsNext
.l43CA:
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

Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp ReadCmdsNext

; $EA 4n: TRK_FLAGS = n (the other flags are lost), then bit 1 (autopan) set or cleared.
Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l43FE
	or $02
	jr .l4400
.l43FE:
	and $FD
.l4400:
	ld [hl], a
	jp ReadCmdsNext

; $EB x yz: TRK_VIB = x (the whole byte; 0: off, two bytes). TRK_VIBDELAYUNITS = y; for y > 0
; the delay is y * unit ticks (otherwise TRK_FLAGS2 bit 7 is cleared); depth z.
Cmd_Vibrato:
	pop hl
	ld a, [de]
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp nz, .l4414
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp ReadCmdsNext
.l4414:
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAYUNITS
	ld [hl], a
	or a
	jp nz, .l4428
	ld l, TRK_FLAGS2
	res 7, [hl]
	jp .l443C
.l4428:
	push bc
	ld l, TRK_VIBDELAYUNITS
	ld b, [hl]
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4430:
	add a, c
	dec b
	jp nz, .l4430
	ld l, TRK_VIBDELAYRELOAD
	ld [hl], a
	ld l, TRK_VIBDELAY
	ld [hl], a
	pop bc
.l443C:
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

; $EC n: TRK_ENVNUM = n; n > 0 takes EnvelopeTable entry n (index cleared at every note).
Cmd_Envelope:
	pop hl
	ld a, [de]
	ld l, TRK_ENVNUM
	ld [hl], a
	or a
	jp z, ReadCmdsNext
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
	ld l, TRK_ENVLOOPCNT
	ld [hl], a
	jp ReadCmdsNext

; $ED xy: duty step on (duty y for x ticks at every note start) / off for 0.
Cmd_DutyStep:
	pop hl
	ld l, TRK_FLAGS
	ld a, [de]
	or a
	jr z, .l4499
	set 4, [hl]
	and $0F
	ld l, TRK_DUTYSTEP
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	jp ReadCmdsNext
.l4499:
	res 4, [hl]
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
	jr nz, .l44B2
	inc de
	jp ReadCmdsNext
.l44B2:
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
	ld a, $00
	ld l, TRK_ENVNUM
	ld [hl], a
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, RawRead

; $E0: unit; Drm: done. SfxN: env, vol, NR42 = byte + trigger. Else duty (CH3: wave) and vol,
; gate and env. Cmd_VoiceChk also clears TRK_ENVNUM (no envelope after a voice).
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
	jr z, .l4581
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
.l4581:
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
; byte, length = unit. Rest: flags, NRx2 = 0. Drm: DrumNote. Duty step start; release tick
; = length * gate / 16 (gate 15: length - 1). Period from PeriodTable with octave and
; transpose; vibrato and envelope restart; NRx2 = volume (TRK_ENVVOL when an envelope runs)
; and a trigger.
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
	jr nz, .l460A
	ld l, TRK_UNIT
	ld a, [hl]
	and $0F
	swap a
	jr .l4614
.l460A:
	or a
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4610:
	add a, c
	dec b
	jr nz, .l4610
.l4614:
	ld l, TRK_LEN
	ld [hl], a
	ld l, TRK_VIBDELAYUNITS
	ld a, [hl]
	or a
	jp z, .l4628
	ld l, TRK_FLAGS2
	set 7, [hl]
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAY
	ld [hl], a
.l4628:
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l4655
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l4655
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	call WriteReg
.l4655:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4662
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4674
.l4662:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l466A:
	srl c
	jr nc, .l466F
	add a, d
.l466F:
	rra
	dec b
	jr nz, .l466A
	pop de
.l4674:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l468C
	ld b, a
	ld c, $0C
	xor a
.l4687:
	add a, c
	dec b
	jr nz, .l4687
	ld c, a
.l468C:
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
	push bc
	ld l, TRK_VIB
	ld a, [hl]
	ld l, TRK_ENVNUM
	ld b, [hl]
	or b
	pop bc
	jp z, .l46C4
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	ld l, TRK_ENVIDX
	ld [hl], a
	call VibratoRead
	call EnvRead
.l46C4:
	call VibratoApply
	ld l, TRK_ENVNUM
	ld a, [hl]
	or a
	jp z, NoteVolumeWrite
	ld l, TRK_ENVVOL
	ld a, [hl]
	ld l, TRK_VOL
	ld [hl], a
	jp NoteVolumeWrite

; VibratoTick: after the delay (TRK_VIBDELAY counts down when TRK_VIBDELAYUNITS > 0) every
; TRK_VIBTIMER ticks the next step is read and the period written.
VibratoTick:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	ret z
	ld l, TRK_VIBDELAYUNITS
	ld a, [hl]
	or a
	jp z, .l46EF
	ld l, TRK_VIBDELAY
	ld a, [hl]
	cp $00
	jp z, .l46EF
	ld l, TRK_VIBDELAY
	dec [hl]
	ret nz
.l46EF:
	ld l, TRK_FLAGS2
	res 7, [hl]
	ld l, TRK_VIBTIMER
	dec [hl]
	ret nz
	ld l, TRK_VIBRELOAD
	ld a, [hl]
	ld l, TRK_VIBTIMER
	ld [hl], a
	call VibratoRead
	jp VibratoApply

; VibratoRead: steps (ticks << 4 | negate << 3 | offset), $FB loop point, $FE n repeat, $FF hold;
; the offset is multiplied by the depth.
VibratoRead:
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
	jp nc, .l4715
	inc b
.l4715:
	ld a, [bc]
	cp $FB
	jr z, .l4760
	cp $FE
	jr z, .l476A
	cp $FF
	jr z, .l4788
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l4739
	ld l, TRK_FLAGS
	set 3, [hl]
	jp .l473D
.l4739:
	ld l, TRK_FLAGS
	res 3, [hl]
.l473D:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l475C
	push bc
	xor a
	ld c, a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4753:
	add a, c
	dec b
	jp nz, .l4753
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l475C:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4760:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4715
.l476A:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l477F
	cp $FF
	jr z, .l4776
	inc [hl]
.l4776:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp VibratoRead
.l477F:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4715
.l4788:
	ret

; EnvTick: every TRK_ENVTIMER ticks the next envelope step is read (TRK_FLAGS2 bit 0 = retrigger).
EnvTick:
	ld l, TRK_ENVNUM
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
	call EnvRead
	jp VibratoApply

; EnvRead: steps (ticks << 4 | volume), $FB loop point, $FE n repeat (TRK_ENVLOOPCNT), $FF hold
; (TRK_FLAGS2 bit 1).
EnvRead:
	ld l, TRK_ENVNUM
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
	jp nc, .l47B8
	inc b
.l47B8:
	ld a, [bc]
	cp $FB
	jr z, .l47D9
	cp $FE
	jr z, .l47E3
	cp $FF
	jr z, .l4801
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
.l47D9:
	ld l, TRK_ENVIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_ENVLOOPIDX
	ld [hl], a
	inc bc
	jr .l47B8
.l47E3:
	inc bc
	ld a, [bc]
	ld l, TRK_ENVLOOPCNT
	cp [hl]
	jr z, .l47F8
	cp $FF
	jr z, .l47EF
	inc [hl]
.l47EF:
	ld l, TRK_ENVLOOPIDX
	ld a, [hl]
	ld l, TRK_ENVIDX
	ld [hl], a
	jp EnvRead
.l47F8:
	xor a
	ld [hl], a
	ld l, TRK_ENVIDX
	inc [hl]
	inc bc
	jp .l47B8
.l4801:
	ld l, TRK_FLAGS2
	set 1, [hl]
	ret

NoteVolumeWrite:
	call NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; NoteVolume: TRK_LEVEL = (vol - atten - wFadeLevel) << 4 (0 at a borrow). CH3: NR30 = $80, the
; decay timer from TRK_ENV, level code = (vol >> 1 & 3) + atten + wFadeLevel / 2 (0 from 4).
NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4839
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4833
	xor a
.l4833:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4839:
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
	jr c, .l4861
	xor a
.l4861:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

; VibratoApply: period +/- offset (0 while the vibrato delay runs) to NRx3/NRx4.
VibratoApply:
	ld l, TRK_FLAGS2
	bit 7, [hl]
	jp nz, .l4877
	ld l, TRK_VIBOFS
	ld c, [hl]
	inc l
	ld b, [hl]
	jp .l487B
.l4877:
	ld a, $00
	ld c, a
	ld b, a
.l487B:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLAGS
	bit 3, [hl]
	push hl
	jr z, .l488E
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l488E:
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

; WriteDuty: NRx1 = duty << 4; CH3 copies wave TRK_DUTY (WaveTable, from 0) to the wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l48F1
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l48F1:
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l48FE:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l48FE
	pop hl
	pop de
	ret

; IsBlocked: carry for Ch1 while Sfx1 plays and for Ch2 while Sfx2 plays.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4915
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l491E
.l4915:
	cp $04
	jr nz, .l4920
	ld a, [wTrkSfx2]
	or a
	ret z
.l491E:
	scf
	ret
.l4920:
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
	add a, $C0
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4940
	ld a, [hl]
	cp c
	jr z, .l4943
.l4940:
	ld a, c
	ld [hl], a
	ld [de], a
.l4943:
	pop de
	ld a, [wTrackIdx]
	add a, $C0
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
	add a, $C0
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
	jr nz, .l49C9
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
	jr z, .l49BD
	cp $00
	jr z, .l49BD
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call WriteReg
	jr .l49C8
.l49BD:
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call WriteReg
.l49C8:
	inc de
.l49C9:
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
	call RawWritePeriod
	call SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

RawWritePeriod:
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
	call WriteReg
	ret

; VarToneTick (Sfx1 playing $11 or $12, every update): LEN = 1; at the start (wVarToneStart) duty
; 2, NRx2 = $40; then the period VarToneTable[wVarToneVar] (the index doubled with rla, so the
; carry from before goes in), written every update (with a trigger the first time). The
; Sfx1 stream of $11/$12 is never read: the header points at VarToneTable.
VarToneTick:
	ld hl, wTrkSfx1
	ld l, TRK_LEN
	ld a, $01
	ld [hl], a
	ld a, [wVarToneStart]
	or a
	jr z, .l4A93
	ld hl, wTrkSfx1
	ld a, $08
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, $40
	ld l, TRK_LEVEL
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
.l4A93:
	push hl
	ld hl, VarToneTable
	ld a, [wVarToneVar]
	ld [wVarToneIdx], a
	rla
	add a, l
	ld l, a
	ld a, h
	adc a, $00
	ld h, a
	push de
	ld e, l
	ld d, h
	ld hl, wVarTonePtr
	ld [hl], e
	ld hl, wVarTonePtr + $01
	ld [hl], d
	ld a, [de]
	ld [wVarTonePeriod], a
	ld c, a
	inc de
	ld a, [de]
	ld [wVarTonePeriod + $01], a
	ld b, a
	pop de
	pop hl
	ld a, [wVarToneStart]
	or a
	jp z, WritePeriodBC
	call WritePeriodBC
	ld a, $00
	ld [wVarToneStart], a
	jp Trigger

; SetC0D0: wC0D0 = A. Unreferenced.
SetC0D0:
	ld [wC0D0], a
	ret

; PlaySound: A = id; ids >= $31 are ignored, 0 = StopAll. $21 stops everything first. $14 is not
; restarted while Sfx1 plays it. $11/$12 set wVarToneStart. Header from SoundTable: priority,
; mask; the tracks start in the order Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm, each with its
; own priority test (no request groups: wReqRefused is set but never read). Then NR51.
PlaySound:
	ld [wReqId], a
	ld b, $31
	cp b
	ret nc
	or a
	jp z, StopAll
	cp $21
	jr nz, .l4AE9
	call StopAll
	ld a, $21
	ld [wReqId], a
.l4AE9:
	cp $14
	jp nz, .l4AF6
	ld hl, wTrkSfx1
	cp [hl]
	ret z
	jp PlaySoundHeader
.l4AF6:
	cp $11
	jp z, .l4B00
	cp $12
	jp nz, PlaySoundHeader
.l4B00:
	ld b, a
	ld a, $01
	ld [wVarToneStart], a
	ld a, b
	jp PlaySoundHeader

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
	rra
	call c, StartSfx2
	rra
	call c, StartSfxN
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

; ClearReqRefused: unreferenced.
ClearReqRefused:
	xor a
	ld [wReqRefused], a
	ret

StartCh1:
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l4B4C
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
.l4B4C:
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
	jr c, .l4B88
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l4B88:
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

; StartSfx1: when the priority passes, NR10 = 8 and the Ch1 NR51 bits; for $11/$12
; (wVarToneStart set) VarToneReset clears wVarToneIdx and wVarTonePeriod.
StartSfx1:
	push af
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4BC8
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld a, [wVarToneStart]
	or a
	call nz, VarToneReset
.l4BC8:
	dec l

; StartTrack: priority >= the track's: TRK_PRIO, TRK_ID, TRK_PTR, LEN 1, TRK_FLAGS = $40,
; $86-$90 = 0; a stream starting with $E1 is raw (TRK_FLAGS2 bits 4/5). Refused: skip the
; pointer. wReqRefused = 0/1. TRK_PAN = $FF either way.
StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4C0D
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
	push de
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld l, TRK_PTR + 1
	ld d, [hl]
	ld a, [de]
	cp $E1
	jr nz, .l4C04
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l4C11
.l4C04:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l4C11
.l4C0D:
	inc de
	inc de
	ld a, $01
.l4C11:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

; StopAll: clears $80-$BD of every track, the shadows and the globals $C0C1-$C0E0; wNR51 = $FF
; (not written); falls into SndPause (NRx2 = 0 on CH1, CH2, CH4; NR32 = 0).
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $003E
	ld [hl], $00
	call CopyBytes
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
	ld a, $00
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
	jr z, .l4CCB
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
	xor a
	ldh [rNR10], a
.l4CCB:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l4CE0
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l4CE0:
	ld a, [wTrkCh3]
	or a
	jr z, .l4CF1
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l4CF1:
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

VarToneReset:
	xor a
	ld [wVarToneIdx], a
	ld [wVarTonePeriod], a
	ld [wVarTonePeriod + $01], a
	ret

; PeriodTable: 96 periods (8 octaves from C; pitch index 0 = C of octave 1).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7

; WaveTable: 16 waves, indexed from 0. The last wave's last two bytes are SoundTable's unused
; id-0 entry (the code reads SoundTable - 2 + 2 * id).
WaveTable:
	dw Wave0 ; wave 0
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
Wave0:
	db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $11
Wave1:
	db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $11
Wave2:
	db $11, $33, $55, $77, $33, $55, $77, $55, $55, $77, $11, $33, $77, $11, $33, $11
Wave3:
	db $AA, $BB, $CC, $DD, $BB, $CC, $DD, $CC, $CC, $DD, $AA, $BB, $DD, $AA, $BB, $AA
Wave4:
	db $89, $AB, $CD, $EF, $CD, $AB, $89, $67, $89, $AB, $CD, $EF, $CD, $AB, $89, $67
Wave5:
	db $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $0E, $0D, $0C
Wave6:
	db $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
Wave7:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $04, $04, $04, $04, $04, $04
Wave8:
	db $55, $66, $77, $88, $99, $00, $00, $00, $00, $00, $99, $88, $55, $FF, $55, $BB
Wave9:
	db $44, $55, $66, $77, $88, $00, $00, $00, $00, $00, $88, $77, $44, $FF, $44, $AA
Wave10:
	db $66, $33, $00, $33, $66, $33, $00, $33, $66, $77, $88, $99, $AA, $BB, $CC, $DD
Wave11:
	db $99, $55, $99, $55, $99, $55, $00, $55, $99, $55, $00, $99, $55, $99, $55, $00
Wave12:
	db $34, $45, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE
Wave13:
	db $32, $52, $42, $12, $32, $52, $42, $12, $32, $52, $42, $12, $32, $52, $42, $12
Wave14:
	db $33, $33, $34, $34, $33, $33, $34, $34, $33, $33, $34, $34, $33, $33, $34, $34
Wave15:
	db $88, $44, $00, $88, $44, $00, $88, $44, $00, $44, $88, $22, $44, $66, $88, $AA

; SoundTable: ids $01-$30.
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

SndHdr10:
	SND_HEADER $A0, $02 ; tracks: Sfx2
	dw Snd10_Sfx2

SndHdr11:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw VarToneTable
	dw Snd11_SfxN

SndHdr12:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw VarToneTable

SndHdr13:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd13_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $78, $05 ; tracks: Sfx1, SfxN
	dw Snd14_Sfx1
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd16_Sfx1
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd17_Sfx1
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd19_Sfx1
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd1B_Sfx1
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $90, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_Sfx2
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $A0, $02 ; tracks: Sfx2
	dw Snd1E_Sfx2

SndHdr1F:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd1F_Sfx2

SndHdr20:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd20_Sfx2

SndHdr21:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $88, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd23_Sfx1
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd24_Sfx1
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $30, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd26_SfxN
	dw Snd26_Ch1
	dw Snd26_Ch2

SndHdr27:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd27_Ch1
	dw Snd27_Ch2
	dw Snd27_Ch3
	dw Snd27_Drm

SndHdr28:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd28_Ch1
	dw Snd28_Ch2
	dw Snd28_Ch3
	dw Snd28_Drm

SndHdr29:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd29_Ch1
	dw Snd29_Ch2
	dw Snd29_Ch3
	dw Snd29_Drm

SndHdr2A:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2A_Ch1
	dw Snd2A_Ch2
	dw Snd2A_Ch3
	dw Snd27_Drm

SndHdr2B:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2B_Ch1
	dw Snd2B_Ch2
	dw Snd2B_Ch3
	dw Snd28_Drm

SndHdr2C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2C_Ch1
	dw Snd2C_Ch2
	dw Snd2C_Ch3
	dw Snd29_Drm

SndHdr2D:
	SND_HEADER $40, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd2D_SfxN
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

; DrumMap: drum note hi 1-15 -> sound id.
DrumMap:
	db $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F

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
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd04_Sfx1
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $01, $01 ; tracks: Sfx1
	dw Snd07_Sfx1

SndHdr08:
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd08_Sfx1
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd09_Sfx1
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd0A_Sfx1
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $01, $05 ; tracks: Sfx1, SfxN
	dw Snd0C_Sfx1
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd0D_SfxN

SndHdr0E:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $01, $04 ; tracks: SfxN
	dw Snd0F_SfxN

Snd01_SfxN:
	NVOICE $01, 10, 0
	PAN $F0
	NOISE $12
	NOISE $11
	NVOICE $08, 7, 6
	NOISE $00
	SND_END

Snd02_SfxN:
	NVOICE $01, 10, 0
	PAN $0F
	NOISE $12
	NOISE $11
	NVOICE $08, 7, 6
	NOISE $00
	SND_END

Snd03_SfxN:
	NVOICE $08, 7, 4
	NOISE $13
	NOISE $14
	NOISE $15
	SND_END

Snd04_Sfx1:
	VOICE $01, 8, 8, 0, 0
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $01, 3, 8, 0, 0
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $01, 2, 8, 0, 0
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_END

Snd04_SfxN:
	NVOICE $01, 12, 0
	NOISE $58
	NOISE $57
	NVOICE $06, 4, 2
	NOISE $00
	SND_END

Snd05_SfxN:
	NVOICE $01, 15, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE $01, 2, 2
	NOISE $13
	NOISE $12
	SND_END

Snd06_SfxN:
	NVOICE $01, 15, 0
	NOISE $A0
	NOISE $00
	SND_END

Snd07_Sfx1:
	VOICE $01, 7, 4, 0, 0
	OCTAVE 6
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	REST 4
	LOOP_START
	NOTE F_, 1
	NOTE D#, 1
	LOOP_END 13
	ATTEN 5
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 0
	SND_END

Snd08_Sfx1:
	VOICE $03, 7, 8, 0, 0
	SWEEP $3D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd08_SfxN:
	NVOICE $01, 15, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE $01, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd09_Sfx1:
	VOICE $03, 7, 8, 0, 0
	SWEEP $2D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd09_SfxN:
	NVOICE $01, 15, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE $01, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd0A_Sfx1:
	VOICE $03, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd0A_SfxN:
	NVOICE $01, 15, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE $01, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd0B_SfxN:
	NVOICE $01, 7, 0
	NOISE $12
	NOISE $11
	NVOICE $08, 3, 2
	NOISE $11
	SND_END

Snd0C_Sfx1:
	VOICE $01, 7, 4, 0, 0
	PAN $F0
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	PAN $0F
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_END

Snd0C_SfxN:
	NVOICE $08, 4, 15
	NOISE $44
	NOISE $44
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $46
	NOISE $46
	NOISE $46
	NVOICE $0A, 7, 7
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	SND_END

Snd0D_SfxN:
	NVOICE $08, 3, 15
	NOISE $44
	NOISE $44
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $46
	NOISE $46
	NOISE $46
	NVOICE $10, 8, 0
	NOISE $46
	NVOICE $10, 8, 0
	NOISE $46
	NVOICE $10, 7, 0
	NOISE $46
	NVOICE $10, 7, 0
	NOISE $46
	NVOICE $10, 6, 0
	NOISE $46
	NVOICE $10, 6, 0
	NOISE $46
	NVOICE $10, 6, 0
	NOISE $46
	NVOICE $10, 5, 0
	NOISE $46
	NVOICE $10, 5, 0
	NOISE $46
	NVOICE $10, 5, 0
	NOISE $46
	NVOICE $10, 4, 0
	NOISE $46
	NVOICE $10, 4, 0
	NOISE $46
	NVOICE $10, 3, 0
	NOISE $46
	NVOICE $10, 2, 0
	NOISE $46
	NVOICE $10, 1, 0
	NOISE $46
	SND_END

Snd0E_SfxN:
	SND_END

Snd0F_SfxN:
	SND_END

; VibratoTable: 15 tables ($EB x / $EA 2x, from 1).
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
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_HOLD

Vib02:
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 0, 7
	VIB_HOLD

Vib03:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_HOLD

Vib04:
	VIB_SEGNO
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
	VIB_REPEAT 255

Vib06:
	VIB_SEGNO
	VIB_STEP 1, 1, 1
	VIB_REPEAT 255

Vib07:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_HOLD

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
	VIB_REPEAT 255

Vib09:
	VIB_STEP 2, 1, 7
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 1
	VIB_STEP 1, 0, 0
	VIB_HOLD

Vib0A:
	VIB_HOLD

Vib0B:
	VIB_HOLD

Vib0C:
	VIB_HOLD

Vib0D:
	VIB_HOLD

Vib0E:
	VIB_HOLD

Vib0F:
	VIB_HOLD

; EnvelopeTable: 32 volume envelopes ($EC n, from 1).
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
	dw Env16 ; 22
	dw Env17 ; 23
	dw Env18 ; 24
	dw Env19 ; 25
	dw Env1A ; 26
	dw Env1B ; 27
	dw Env1C ; 28
	dw Env1D ; 29
	dw Env1E ; 30
	dw Env1F ; 31
	dw Env20 ; 32
Env01:
	ENV_STEP 1, $0A
	ENV_STEP 1, 9
	ENV_STEP 1, 8
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env02:
	ENV_STEP 3, 1
	ENV_STEP 4, 2
	ENV_STEP 5, 3
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env03:
	ENV_STEP 1, 7
	ENV_STEP 1, 6
	ENV_STEP 1, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env04:
	ENV_STEP 1, 2
	ENV_STEP 2, 4
	ENV_STEP 3, 6
	ENV_STEP 4, 8
	ENV_STEP 5, 9
	ENV_STEP 6, $0B
	ENV_STEP 6, 8
	ENV_STEP 5, 6
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env05:
	ENV_STEP 3, 5
	ENV_STEP 4, 6
	ENV_STEP 5, 7
	ENV_STEP 6, 8
	ENV_STEP 7, 9
	ENV_STEP 6, 4
	ENV_STEP 5, 3
	ENV_STEP 4, 2
	VIB_HOLD
Env06:
	ENV_STEP 1, $0A
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
	VIB_HOLD
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
	VIB_HOLD
Env08:
	ENV_STEP 1, 3
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	VIB_HOLD
Env09:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 9
	ENV_STEP 3, $0A
	ENV_STEP 3, $0B
	ENV_STEP 4, 7
	ENV_STEP 5, 6
	ENV_STEP 6, 5
	ENV_STEP 7, 4
	VIB_HOLD
Env0A:
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 3, 8
	ENV_STEP 2, 9
	ENV_STEP 3, 5
	ENV_STEP 6, 4
	ENV_STEP 7, 3
	ENV_STEP 8, 2
	VIB_HOLD
Env0B:
	ENV_STEP 1, $0B
	ENV_STEP 2, $0A
	ENV_STEP 2, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 1
	ENV_STEP 4, 2
	ENV_STEP 3, 3
	ENV_STEP 2, 4
	VIB_HOLD
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
	VIB_HOLD
Env0D:
	ENV_STEP 1, 3
	ENV_STEP 1, 6
	ENV_STEP 1, 9
	ENV_STEP 1, 3
	VIB_HOLD
Env0E:
	ENV_STEP 3, $0A
	ENV_STEP 4, 9
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 4
	ENV_STEP 2, 3
	ENV_STEP 1, 2
	VIB_HOLD
Env0F:
	ENV_STEP 1, 8
	ENV_STEP 2, 7
	ENV_STEP 2, 6
	ENV_STEP 2, 4
	ENV_STEP 2, 3
	ENV_STEP 1, 2
	VIB_HOLD
Env10:
	ENV_STEP 1, 5
	ENV_STEP 2, 6
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 9
	ENV_STEP 3, $0A
	ENV_STEP 3, $0B
	ENV_STEP 3, $0C
	ENV_STEP 5, 8
	ENV_STEP 6, 7
	ENV_STEP 7, 6
	ENV_STEP 8, 5
	ENV_STEP 9, 4
	ENV_STEP $0A, 3
	VIB_HOLD
Env11:
	ENV_STEP 1, 2
	ENV_STEP 3, 3
	ENV_STEP 4, 4
	ENV_STEP 5, 5
	ENV_STEP 6, 6
	ENV_STEP 7, 5
	ENV_STEP 8, 4
	ENV_STEP 9, 3
	ENV_STEP $0A, 2
	VIB_HOLD
Env12:
	ENV_STEP 1, 4
	ENV_STEP 2, 6
	ENV_STEP 3, 8
	ENV_STEP 4, 9
	ENV_STEP 5, $0B
	ENV_STEP 6, 8
	ENV_STEP 5, 6
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env13:
	ENV_STEP 3, 2
	ENV_STEP 4, 3
	ENV_STEP 5, 4
	ENV_STEP 6, 5
	ENV_STEP 7, 4
	ENV_STEP 6, 3
	ENV_STEP 5, 2
	VIB_HOLD
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
	VIB_HOLD
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
	VIB_HOLD
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
	VIB_HOLD
Env17:
	ENV_STEP 1, $0B
	ENV_STEP 2, $0A
	ENV_STEP 3, 9
	ENV_STEP 4, 8
	ENV_STEP 5, 1
	ENV_STEP 4, 2
	ENV_STEP 3, 3
	ENV_STEP 2, 4
	ENV_STEP 1, 5
	VIB_HOLD
Env18:
	ENV_STEP 1, 3
	ENV_STEP 2, 4
	ENV_STEP 3, 5
	ENV_STEP 4, 6
	ENV_STEP 5, 5
	ENV_STEP 4, 4
	ENV_STEP 3, 3
	ENV_STEP 2, 2
	VIB_HOLD
Env19:
	ENV_STEP 1, $0A
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
	VIB_HOLD
Env1A:
	VIB_HOLD
Env1B:
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	VIB_HOLD
Env1C:
	ENV_STEP 1, 8
	ENV_STEP 2, 7
	ENV_STEP 3, 6
	ENV_STEP 4, 4
	ENV_STEP 5, 3
	ENV_STEP 6, 2
	VIB_HOLD
Env1D:
	ENV_STEP 1, 7
	ENV_STEP 2, 6
	ENV_STEP 3, 5
	ENV_STEP 4, 3
	ENV_STEP 5, 2
	VIB_HOLD
Env1E:
	VIB_HOLD
Env1F:
	VIB_HOLD
Env20:
	VIB_HOLD

Snd10_Sfx2:
	RAW_HEADER 5, 8, $88
	RAW_NOTE 13, $707
	RAW_NOTE 13, $73A
	RAW_NOTE 13, $75A
	RAW_NOTE 13, $73A
	RAW_NOTE 13, $75A
	RAW_NOTE 13, $784
	RAW_NOTE 11, $784
	RAW_NOTE 2, $784
	SND_END

Snd11_SfxN:
	NVOICE $01, 10, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 3, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 2, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 1, 0
	NOISE $11
	NOISE $12
	NOISE $13
	SND_END

Snd13_Sfx1:
	SND_END

Snd13_SfxN:
	NVOICE $01, 12, 0
	NOISE $78
	NOISE $87
	NVOICE $04, 7, 3
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd14_Sfx1:
	RAW_HEADER 1, 8, $88
	RAW_NOTE 8, $5FD
	RAW_NOTE 8, $5BC
	RAW_NOTE 8, $598
	RAW_NOTE 8, $573
	RAW_NOTE 8, $54B
	RAW_NOTE 8, $521
	RAW_NOTE 8, $4F4
	RAW_NOTE 8, $4C5
	RAW_NOTE 2, $5FD
	RAW_NOTE 2, $5BC
	RAW_NOTE 2, $598
	RAW_NOTE 2, $573
	RAW_NOTE 2, $54B
	RAW_NOTE 2, $521
	RAW_NOTE 2, $4F4
	RAW_NOTE 2, $4C5
	SND_END

Snd14_SfxN:
	NVOICE $01, 9, 0
	NOISE $41
	NVOICE $04, 1, 2
	NOISE $11
	SND_END

Snd15_Sfx1:
	RAW_HEADER 2, 8, $88
	RAW_NOTE 7, $534
	RAW_NOTE 7, $58B
	RAW_NOTE 6, $4D3
	RAW_NOTE 6, $534
	RAW_NOTE 5, $58B
	RAW_NOTE 5, $4D3
	RAW_NOTE 2, $500
	RAW_NOTE 2, $597
	RAW_NOTE 2, $4DF
	RAW_NOTE 1, $504
	RAW_NOTE 1, $59B
	RAW_NOTE 1, $4E3
	SND_END

Snd16_Sfx1:
	RAW_HEADER 1, 0, $88
	RAW_NOTE 7, $65B
	RAW_NOTE 7, $68A
	RAW_NOTE 7, $6B3
	RAW_NOTE 7, $6D8
	RAW_NOTE 2, $65B
	RAW_NOTE 2, $68A
	RAW_NOTE 2, $6B3
	RAW_NOTE 2, $6D8
	RAW_NOTE 1, $65B
	RAW_NOTE 1, $68A
	RAW_NOTE 1, $6B3
	RAW_NOTE 1, $6D8
	SND_END

Snd16_SfxN:
	NVOICE $01, 10, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 3, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 2, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $01, 1, 0
	NOISE $11
	NOISE $12
	NOISE $13
	SND_END

Snd17_Sfx1:
	VOICE $01, 0, 0, 0, 0
	REST 0
	SND_END

Snd17_SfxN:
	NVOICE $01, 10, 0
	NOISE $44
	NOISE $43
	NOISE $42
	NVOICE $01, 3, 0
	NOISE $20
	NOISE $21
	NOISE $22
	NVOICE $01, 2, 0
	NOISE $20
	NOISE $21
	NOISE $22
	NVOICE $01, 1, 0
	NOISE $20
	NOISE $21
	NOISE $22
	SND_END

Snd18_Sfx1:
	RAW_HEADER 1, 0, $88
	RAW_NOTE 15, $627
	RAW_NOTE 15, $673
	RAW_NOTE 15, $73A
	RAW_NOTE 15, $75A
	RAW_NOTE 15, $627
	RAW_NOTE 15, $673
	RAW_NOTE 15, $6B3
	RAW_NOTE 3, $627
	RAW_NOTE 3, $637
	RAW_NOTE 3, $6B3
	RAW_NOTE 2, $673
	RAW_NOTE 2, $6B3
	RAW_NOTE 2, $6F8
	RAW_NOTE 1, $673
	RAW_NOTE 1, $6B3
	RAW_NOTE 1, $6F8
	SND_END

Snd19_Sfx1:
	SND_END

Snd19_SfxN:
	NVOICE $01, 14, 0
	NOISE $78
	NOISE $87
	NVOICE $01, 8, 0
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $01, 3, 0
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $01, 2, 0
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $01, 1, 0
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	SND_END

Snd1A_Sfx1:
	RAW_HEADER 1, 8, $88
	RAW_NOTE 15, $3F4
	RAW_NOTE 15, $54B
	RAW_NOTE 15, $493
	RAW_NOTE 15, $3F4
	RAW_NOTE 15, $54B
	RAW_NOTE 15, $493
	RAW_NOTE 12, $3F4
	RAW_NOTE 12, $54B
	RAW_NOTE 12, $493
	RAW_NOTE 5, $3F4
	RAW_NOTE 5, $54B
	RAW_NOTE 5, $493
	RAW_NOTE 3, $3F4
	RAW_NOTE 3, $54B
	RAW_NOTE 3, $493
	RAW_NOTE 1, $3F4
	RAW_NOTE 1, $54B
	RAW_NOTE 1, $493
	SND_END

Snd1B_Sfx1:
	RAW_HEADER 1, 0, $88
	RAW_NOTE 5, $7C2
	RAW_NOTE 5, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 5, $7CB
	LEN_UNIT $03
	RAW_NOTE 5, $7CE
	LEN_UNIT $01
	RAW_NOTE 5, $7C2
	RAW_NOTE 5, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 5, $7CB
	RAW_NOTE 5, $7CE
	RAW_NOTE 5, $7CD
	RAW_NOTE 5, $7D3
	RAW_NOTE 5, $7D6
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7D1
	LEN_UNIT $03
	RAW_NOTE 2, $7D3
	LEN_UNIT $01
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7D3
	RAW_NOTE 2, $7D6
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7D1
	LEN_UNIT $03
	RAW_NOTE 1, $7D3
	LEN_UNIT $01
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7CE
	SND_END

Snd1B_SfxN:
	NVOICE $08, 4, 0
	NOISE $44
	NVOICE $08, 4, 0
	NOISE $44
	NVOICE $08, 4, 0
	NOISE $45
	NVOICE $08, 4, 0
	NOISE $45
	NOISE $45
	NVOICE $08, 4, 0
	NOISE $46
	NVOICE $08, 4, 0
	NOISE $46
	NOISE $46
	NVOICE $08, 5, 0
	NOISE $46
	NOISE $46
	NOISE $46
	NVOICE $08, 4, 0
	NOISE $46
	NOISE $46
	NOISE $46
	NVOICE $08, 3, 0
	NOISE $46
	NOISE $46
	NVOICE $08, 2, 0
	NOISE $46
	NOISE $46
	NVOICE $08, 1, 0
	NOISE $46
	NOISE $46
	SND_END

Snd1C_Sfx1:
	RAW_HEADER 1, 4, $88
	RAW_NOTE 6, $7C2
	RAW_NOTE 6, $7C4
	RAW_NOTE 6, $7C8
	RAW_NOTE 6, $7CB
	LEN_UNIT $03
	RAW_NOTE 6, $7CE
	LEN_UNIT $01
	RAW_NOTE 6, $7C2
	RAW_NOTE 6, $7C4
	RAW_NOTE 6, $7C8
	RAW_NOTE 6, $7CB
	RAW_NOTE 6, $7CE
	RAW_NOTE 6, $7CD
	RAW_NOTE 6, $7D3
	RAW_NOTE 6, $7D6
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7D1
	LEN_UNIT $03
	RAW_NOTE 3, $7D3
	LEN_UNIT $01
	RAW_NOTE 3, $7D1
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7D1
	RAW_NOTE 3, $7D3
	RAW_NOTE 3, $7D6
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7D1
	LEN_UNIT $03
	RAW_NOTE 2, $7D3
	LEN_UNIT $01
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7CE
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7D1
	LEN_UNIT $03
	RAW_NOTE 1, $7D3
	LEN_UNIT $01
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7CE
	SND_END

Snd1C_Sfx2:
	RAW_HEADER 11, 4, $88
	RAW_REST
	PAN $F0
	LEN_UNIT $01
	RAW_NOTE 5, $7C2
	RAW_NOTE 5, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 5, $7CB
	LEN_UNIT $03
	RAW_NOTE 5, $7CE
	LEN_UNIT $01
	RAW_NOTE 5, $7C2
	RAW_NOTE 5, $7C4
	RAW_NOTE 5, $7C8
	RAW_NOTE 5, $7CB
	RAW_NOTE 5, $7CE
	RAW_NOTE 5, $7CD
	RAW_NOTE 5, $7D3
	RAW_NOTE 5, $7D6
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7D1
	LEN_UNIT $03
	RAW_NOTE 2, $7D3
	LEN_UNIT $01
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7D3
	RAW_NOTE 2, $7D6
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7D1
	LEN_UNIT $03
	RAW_NOTE 1, $7D3
	LEN_UNIT $01
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7CE
	SND_END

Snd1C_SfxN:
	NVOICE $01, 0, 0
	NOISE $00
	NVOICE $08, 5, 0
	NOISE $43
	NVOICE $08, 5, 0
	NOISE $43
	NVOICE $08, 6, 0
	NOISE $44
	NVOICE $08, 6, 0
	NOISE $44
	NVOICE $08, 7, 0
	NOISE $44
	NOISE $46
	NVOICE $08, 8, 0
	NOISE $46
	NVOICE $08, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	NVOICE $0A, 7, 0
	NOISE $46
	NVOICE $0A, 6, 0
	NOISE $46
	NVOICE $0A, 5, 0
	NOISE $46
	NVOICE $0A, 4, 0
	NOISE $46
	NVOICE $0A, 3, 0
	NOISE $46
	NVOICE $0A, 2, 0
	NOISE $46
	NVOICE $0A, 1, 0
	NOISE $46
	SND_END

Snd1D_Sfx1:
	RAW_HEADER 1, 0, $88
	RAW_NOTE 10, $7A3
	RAW_NOTE 10, $7AD
	RAW_NOTE 10, $7B6
	RAW_NOTE 2, $7A3
	RAW_NOTE 2, $7B2
	RAW_NOTE 2, $7B6
	RAW_NOTE 1, $7A3
	RAW_NOTE 1, $7B2
	RAW_NOTE 1, $7B6
	SND_END

Snd1E_Sfx2:
	VOICE $01, 4, 8, 0, 0
	OCTAVE 4
	NOTE A#, 3
	REST 2
	VOICE $01, 6, 0, 0, 0
	NOTE A#, 1
	VOICE $01, 6, 8, 0, 0
	NOTE A#, 7
	VOICE $02, 2, 8, 0, 0
	NOTE A#, 5
	VOICE $04, 1, 8, 0, 0
	NOTE A#, $0C
	SND_END

Snd1F_Sfx2:
	RAW_HEADER 1, 0, $88
	RAW_NOTE 10, $72A
	DUTY 8
	RAW_NOTE 9, $742
	RAW_NOTE 9, $74D
	RAW_NOTE 9, $758
	RAW_NOTE 9, $762
	RAW_NOTE 5, $74D
	RAW_NOTE 5, $762
	RAW_NOTE 5, $76B
	RAW_NOTE 5, $758
	RAW_NOTE 4, $762
	RAW_NOTE 4, $76B
	RAW_NOTE 4, $774
	RAW_NOTE 2, $762
	RAW_NOTE 2, $76B
	RAW_NOTE 2, $774
	RAW_NOTE 2, $784
	RAW_NOTE 1, $762
	RAW_NOTE 1, $76B
	RAW_NOTE 1, $774
	RAW_NOTE 1, $784
	SND_END

Snd20_Sfx2:
	RAW_HEADER 2, 4, $88
	RAW_NOTE 15, $483
	RAW_NOTE 15, $642
	RAW_NOTE 15, $722
	RAW_NOTE 15, $791
	RAW_NOTE 15, $7C8
	RAW_NOTE 11, $483
	RAW_NOTE 11, $642
	RAW_NOTE 11, $722
	RAW_NOTE 11, $791
	RAW_NOTE 11, $7C8
	RAW_NOTE 6, $483
	RAW_NOTE 6, $642
	RAW_NOTE 6, $722
	RAW_NOTE 6, $791
	RAW_NOTE 6, $7C8
	PAN $F0
	RAW_NOTE 5, $483
	RAW_NOTE 5, $642
	RAW_NOTE 5, $722
	RAW_NOTE 5, $791
	RAW_NOTE 5, $7C8
	PAN $0F
	RAW_NOTE 4, $483
	RAW_NOTE 4, $642
	RAW_NOTE 4, $722
	RAW_NOTE 4, $791
	RAW_NOTE 4, $7C8
	PAN $F0
	RAW_NOTE 3, $483
	RAW_NOTE 3, $642
	RAW_NOTE 3, $722
	RAW_NOTE 3, $791
	RAW_NOTE 3, $7C8
	PAN $0F
	RAW_NOTE 2, $483
	RAW_NOTE 2, $642
	RAW_NOTE 2, $722
	RAW_NOTE 2, $791
	RAW_NOTE 2, $7C8
	SND_END

Snd21_Sfx1:
	RAW_HEADER 1, 4, $88
	RAW_NOTE 13, $7CB
	RAW_NOTE 13, $7C4
	RAW_NOTE 13, $7CB
	LEN_UNIT $04
	RAW_REST
	LEN_UNIT $01
	LOOP_START
	RAW_NOTE 13, $7CB
	RAW_NOTE 13, $7C4
	LOOP_END 24
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7C4
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7C4
	SND_END

Snd22_Sfx1:
	RAW_HEADER 1, 4, $88
	RAW_NOTE 13, $7C2
	RAW_NOTE 13, $7CB
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7CB
	LEN_UNIT $02
	RAW_REST
	LEN_UNIT $01
	LOOP_START
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7CB
	LOOP_END 3
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	SND_END

Snd23_Sfx1:
	RAW_HEADER 1, 4, $88
	RAW_NOTE 15, $5FD
	RAW_NOTE 15, $573
	RAW_NOTE 15, $4F4
	RAW_NOTE 15, $425
	RAW_NOTE 12, $5FD
	RAW_NOTE 12, $573
	RAW_NOTE 12, $4F4
	RAW_NOTE 12, $425
	LEN_UNIT $02
	RAW_NOTE 11, $61B
	RAW_NOTE 11, $5FD
	RAW_NOTE 11, $573
	RAW_NOTE 11, $4F4
	RAW_NOTE 11, $5FD
	RAW_NOTE 11, $573
	RAW_NOTE 11, $4F4
	RAW_NOTE 11, $425
	RAW_NOTE 2, $61B
	RAW_NOTE 2, $5FD
	RAW_NOTE 2, $573
	RAW_NOTE 2, $4F4
	RAW_NOTE 2, $5FD
	RAW_NOTE 2, $573
	RAW_NOTE 2, $4F4
	RAW_NOTE 2, $425
	RAW_HEADER 1, 4, $88
	RAW_NOTE 13, $7C2
	RAW_NOTE 13, $7CB
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7CB
	LEN_UNIT $02
	RAW_REST
	LEN_UNIT $01
	LOOP_START
	RAW_NOTE 13, $7D1
	RAW_NOTE 13, $7CB
	LOOP_END 3
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7D1
	RAW_NOTE 2, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7D1
	RAW_NOTE 1, $7CB
	SND_END

Snd23_SfxN:
	NVOICE $01, 15, 0
	NOISE $78
	NOISE $87
	SND_END

Snd24_Sfx1:
	SND_END

Snd24_SfxN:
	NVOICE $02, 7, 0
	NOISE $11
	NOISE $22
	NOISE $23
	NOISE $34
	NOISE $35
	NOISE $46
	NOISE $47
	NVOICE $02, 6, 0
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NVOICE $02, 5, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NVOICE $02, 4, 0
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NVOICE $02, 3, 0
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NVOICE $02, 3, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NVOICE $01, 2, 0
	NOISE $17
	NVOICE $01, 4, 0
	NOISE $16
	NVOICE $01, 6, 0
	NOISE $15
	NVOICE $01, 8, 0
	NOISE $14
	NVOICE $01, 10, 0
	NOISE $13
	NVOICE $01, 12, 0
	NOISE $12
	NVOICE $01, 14, 0
	NOISE $11
	NVOICE $01, 13, 0
	NOISE $78
	NOISE $87
	NVOICE $02, 10, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 3, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 2, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 1, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END

Snd25_Sfx1:
	SND_END

Snd25_SfxN:
	NVOICE $02, 7, 0
	NOISE $11
	NOISE $22
	NOISE $23
	NOISE $34
	NOISE $35
	NOISE $46
	NOISE $47
	NVOICE $02, 6, 0
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NVOICE $02, 5, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NVOICE $02, 4, 0
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NVOICE $02, 3, 0
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NVOICE $02, 3, 0
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NVOICE $01, 2, 0
	NOISE $17
	NVOICE $01, 4, 0
	NOISE $16
	NVOICE $01, 6, 0
	NOISE $15
	NVOICE $01, 8, 0
	NOISE $14
	NVOICE $01, 10, 0
	NOISE $13
	NVOICE $01, 12, 0
	NOISE $12
	NVOICE $01, 14, 0
	NOISE $11
	NVOICE $01, 13, 0
	NOISE $78
	NOISE $87
	NVOICE $02, 10, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 3, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 2, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 1, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END

Snd26_Ch1:
	RAW_HEADER 1, 12, $88
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C4
	RAW_NOTE 4, $7C8
	RAW_NOTE 4, $7CB
	LEN_UNIT $03
	RAW_NOTE 4, $7CE
	LEN_UNIT $01
	RAW_NOTE 4, $7C2
	RAW_NOTE 4, $7C4
	RAW_NOTE 4, $7C8
	RAW_NOTE 4, $7CB
	RAW_NOTE 4, $7CE
	RAW_NOTE 4, $7CD
	RAW_NOTE 4, $7D3
	RAW_NOTE 4, $7D6
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	LEN_UNIT $03
	RAW_NOTE 3, $7CE
	LEN_UNIT $01
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7CD
	RAW_NOTE 3, $7D3
	RAW_NOTE 3, $7D6
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	LEN_UNIT $03
	RAW_NOTE 2, $7CE
	LEN_UNIT $01
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7CD
	RAW_NOTE 2, $7D3
	RAW_NOTE 2, $7D6
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	LEN_UNIT $03
	RAW_NOTE 1, $7CE
	LEN_UNIT $01
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CD
	RAW_NOTE 1, $7D3
	RAW_NOTE 1, $7D6
	SND_END

Snd26_Ch2:
	RAW_HEADER 2, 0, $88
	PAN $F0
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	LEN_UNIT $03
	RAW_NOTE 3, $7CE
	LEN_UNIT $01
	RAW_NOTE 3, $7C2
	RAW_NOTE 3, $7C4
	RAW_NOTE 3, $7C8
	RAW_NOTE 3, $7CB
	RAW_NOTE 3, $7CE
	RAW_NOTE 3, $7CD
	RAW_NOTE 3, $7D3
	RAW_NOTE 3, $7D6
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	LEN_UNIT $03
	RAW_NOTE 2, $7CE
	LEN_UNIT $01
	RAW_NOTE 2, $7C2
	RAW_NOTE 2, $7C4
	RAW_NOTE 2, $7C8
	RAW_NOTE 2, $7CB
	RAW_NOTE 2, $7CE
	RAW_NOTE 2, $7CD
	RAW_NOTE 2, $7D3
	RAW_NOTE 2, $7D6
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	LEN_UNIT $03
	RAW_NOTE 1, $7CE
	LEN_UNIT $01
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CD
	RAW_NOTE 1, $7D3
	RAW_NOTE 1, $7D6
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	LEN_UNIT $03
	RAW_NOTE 1, $7CE
	LEN_UNIT $01
	RAW_NOTE 1, $7C2
	RAW_NOTE 1, $7C4
	RAW_NOTE 1, $7C8
	RAW_NOTE 1, $7CB
	RAW_NOTE 1, $7CE
	RAW_NOTE 1, $7CD
	RAW_NOTE 1, $7D3
	RAW_NOTE 1, $7D6
	SND_END

Snd26_SfxN:
	NVOICE $0B, 4, 8
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NVOICE $01, 15, 0
	NOISE $78
	NOISE $87
	NVOICE $02, 11, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 5, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 4, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 3, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 2, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 1, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NVOICE $02, 1, 0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END

; VarToneTable: 144 periods for the game-controlled Sfx1 tone of $11/$12, indexed by wVarToneVar.

VarToneTable:
	dw $05FF, $0602, $0607, $060C, $0611, $0616, $061B, $0620
	dw $0625, $062A, $062F, $0634, $0639, $063E, $0643, $0648
	dw $064D, $0652, $0657, $065C, $0661, $0666, $066B, $0670
	dw $0675, $067A, $067F, $0684, $0689, $068E, $0693, $0698
	dw $069D, $06A2, $06A7, $06AC, $06B1, $06B6, $06BB, $06C0
	dw $06C5, $06CA, $06CF, $06D4, $06D9, $06DE, $06E3, $06E8
	dw $06ED, $06F2, $06F6, $06FA, $06FE, $0702, $0706, $070A
	dw $070E, $0711, $0714, $0717, $071A, $071D, $0720, $0723
	dw $0726, $0729, $072C, $072E, $0731, $0734, $0737, $073A
	dw $073D, $0740, $0742, $0744, $0746, $0748, $074A, $074C
	dw $074E, $0750, $0752, $0754, $0756, $0758, $075A, $075C
	dw $075E, $0760, $0761, $0762, $0763, $0764, $0765, $0766
	dw $0767, $0768, $0769, $076A, $076B, $076C, $076D, $076E
	dw $076F, $0770, $0771, $0772, $0773, $0774, $0775, $0776
	dw $0777, $0778, $0779, $077A, $077B, $077C, $077D, $077E
	dw $077F, $0780, $0781, $0782, $0783, $0784, $0785, $0786
	dw $0787, $0788, $0789, $078A, $078B, $078C, $078D, $078E
	dw $078F, $0790, $0791, $0792, $0793, $0794, $0795, $0796

Snd27_Ch1:
	VOICE $01, 11, 0, 3, 13
	TEMPO $00
	OCTAVE 5
	NOTE F#, 4
	REST 2
	VOICE $01, 6, 0, 0, 0
	NOTE E_, 1
	NOTE F_, 1
	VOICE $04, 13, 0, 3, 13
	NOTE F#, 8
	VOICE $04, 2, 0, 4, 12
	NOTE F#, $0B

Snd2A_Ch1:
	TEMPO $24
	SND_END

Snd27_Ch2:
	VOICE $01, 14, 4, 3, 13
	OCTAVE 5
	NOTE E_, 4
	REST 2
	VOICE $01, 7, 4, 0, 0
	NOTE D_, 1
	NOTE D#, 1
	VOICE $04, 15, 4, 3, 13
	NOTE E_, 8
	VOICE $04, 2, 4, 4, 12
	NOTE E_, $0B
	VOICE $05, 0, 0, 0, 0
	ENVELOPE 8
	VIBRATO 4, 4, 4
	OCTAVE 4
	NOTE E_, 0
	NOTE D_, 0
	NOTE F_, 8
	NOTE A_, 8
	ENVELOPE $1B
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 4
	LEN_UNIT $02
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

Snd2A_Ch2:
	SND_SEGNO
	VOICE $05, 0, 0, 0, 0
	ENVELOPE 8
	VIBRATO 4, 4, 4
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 1
	REST 2
	NOTE A#, 2
	REST 2
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 7
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE C_, 7
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	REST 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 1
	REST 2
	NOTE A#, 2
	REST 2
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 7
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE C_, 7
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	REST 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 5
	REST 2
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 1
	REST 1
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE F_, 5
	NOTE F_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE F_, 1
	REST 2
	NOTE D#, 5
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 4
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 5
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	REST 2
	NOTE D#, 5
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 1
	SND_LOOP

Snd27_Ch3:
	VOICE $06, 0, 0, 0, 0
	REST $0E
	VOICE $05, 6, 8, 0, 0
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G_, 2
	REST 2

Snd2A_Ch3:
	SND_SEGNO
	VOICE $05, 6, 9, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 3
	NOTE D#, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE A_, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE C_HI, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 3
	NOTE F_, 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE A_, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE C_HI, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE G#, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_LOOP

Snd27_Drm:
	SND_END

Snd28_Ch1:
	VOICE $01, 11, 0, 3, 13
	TEMPO $00
	OCTAVE 5
	NOTE F#, 4
	REST 2
	VOICE $01, 6, 0, 0, 0
	NOTE E_, 1
	NOTE F_, 1
	VOICE $04, 13, 0, 3, 13
	NOTE F#, 8
	VOICE $04, 2, 0, 4, 12
	NOTE F#, $0B

Snd2B_Ch1:
	TEMPO $24
	SND_END

Snd28_Ch2:
	VOICE $01, 14, 4, 3, 13
	OCTAVE 5
	NOTE E_, 4
	REST 2
	VOICE $01, 7, 4, 0, 0
	NOTE D_, 1
	NOTE D#, 1
	VOICE $04, 15, 4, 3, 13
	NOTE E_, 8
	VOICE $04, 2, 4, 4, 12
	NOTE E_, $0B
	VOICE $05, 0, 0, 0, 0
	ENVELOPE 8
	VIBRATO 4, 4, 4
	OCTAVE 4
	NOTE E_, 0
	NOTE D_, 0
	NOTE F_, 8
	NOTE A_, 8
	ENVELOPE $1B
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 4
	LEN_UNIT $02
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

Snd2B_Ch2:
	SND_SEGNO
	VOICE $05, 0, 0, 0, 0
	ENVELOPE 8
	VIBRATO 4, 4, 4
	OCTAVE 3
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A#, 1
	NOTE C_HI, 1
	REST 4
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE E_, 2
	NOTE G_, 1
	NOTE C_HI, 5
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	REST 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	REST 1
	NOTE C_, 3
	OCTAVE 3
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A#, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A#, 1
	NOTE C_HI, 1
	REST 4
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE E_, 2
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	REST 2
	NOTE C_, $0A
	NOTE E_, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE G#, 1
	REST 1
	NOTE A_, 9
	OCTAVE 4
	NOTE D#, 1
	REST 2
	NOTE F_, 1
	REST 2
	NOTE D#, 4
	REST 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE G#, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 3
	NOTE F_, 3
	NOTE G_, 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 4
	NOTE G_, $0C
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	REST 3
	NOTE G_, 4
	SND_LOOP

Snd28_Ch3:
	VOICE $06, 0, 0, 0, 0
	REST $0E
	VOICE $05, 6, 8, 0, 0
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G_, 2
	REST 2

Snd2B_Ch3:
	SND_SEGNO
	VOICE $05, 6, 8, 0, 0
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 3
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE F_, 2
	NOTE D_, 1
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE G_, 3
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 3
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE F_, 2
	NOTE D_, 1
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE G_, 3
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE C_HI, 2
	NOTE C_HI, 1
	NOTE A#, 2
	NOTE A_, 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 3
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	REST 3
	NOTE G_, 4
	SND_LOOP

Snd28_Drm:
	SND_END

Snd29_Ch1:
	VOICE $01, 11, 0, 3, 13
	OCTAVE 5
	NOTE F#, 4
	REST 2
	VOICE $01, 6, 0, 0, 0
	NOTE E_, 1
	NOTE F_, 1
	VOICE $04, 13, 0, 3, 13
	NOTE F#, 8
	VOICE $04, 2, 0, 4, 12
	NOTE F#, $0B

Snd2C_Ch1:
	TEMPO $10
	SND_END

Snd29_Ch2:
	VOICE $01, 14, 4, 3, 13
	OCTAVE 5
	NOTE E_, 4
	REST 2
	VOICE $01, 7, 4, 0, 0
	NOTE D_, 1
	NOTE D#, 1
	VOICE $04, 15, 4, 3, 13
	NOTE E_, 8
	VOICE $04, 2, 4, 4, 12
	NOTE E_, $0B

Snd2C_Ch2:
	SND_SEGNO
	VOICE $05, 0, 0, 0, 0
	ENVELOPE 8
	VIBRATO 4, 2, 3
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	REST 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 9
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 4
	NOTE A_, 4
	NOTE G#, 3
	NOTE E_, 5
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 2
	NOTE D_, 3
	NOTE E_, 6
	NOTE A_, 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 4
	NOTE G#, 4
	NOTE A_, 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	REST 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 9
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 4
	NOTE A_, 4
	NOTE G#, 3
	NOTE E_, 5
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 2
	NOTE D_, 3
	NOTE E_, 6
	OCTAVE 4
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, $0A
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 4
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	NOTE A#, 1
	REST 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 5
	OCTAVE 4
	NOTE F#, 4
	SND_LOOP

Snd29_Ch3:
	VOICE $06, 6, 8, 0, 0
	REST $0E

Snd2C_Ch3:
	SND_SEGNO
	VOICE $05, 6, 8, 0, 0
	LOOP_START
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 2
	LOOP_END 3
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	LOOP_START
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 2
	LOOP_END 3
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	LOOP_START
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 2
	LOOP_END 3
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	LOOP_START
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 2
	LOOP_END 3
	OCTAVE 1
	NOTE E_, 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D#, 1
	NOTE D_, 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE C#, 1
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE B_, 1
	REST 4
	NOTE F#, 4
	SND_LOOP

Snd29_Drm:
	SND_END

Snd2D_SfxN:
	SND_END

Snd2D_Ch2:
	VOICE $06, 0, 4, 0, 0
	TEMPO $1C
	REST 4
	SND_SEGNO
	PAN $F0
	VOICE $06, 0, 4, 0, 0
	ENVELOPE 2
	VIBRATO 6, 0, 2
	OCTAVE 2
	NOTE A_, 7
	OCTAVE 3
	NOTE D_, 1
	REST 2
	NOTE G_, 4
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 3
	NOTE D_, 3
	NOTE E_, $0A
	PAN $F0
	OCTAVE 3
	NOTE D_, $0C
	REST 1
	NOTE F#, 3
	NOTE E_, 5
	PAN $FF
	DUTY 0
	ENVELOPE 3
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 3
	ENVELOPE 2
	DUTY 4
	PAN $F0
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 1
	REST 2
	NOTE G_, 4
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 3
	NOTE D_, 3
	NOTE E_, $0A
	PAN $F0
	OCTAVE 3
	NOTE D_, $0C
	REST 1
	NOTE F#, 1
	PAN $FF
	DUTY 0
	ENVELOPE 6
	VIBRATO 4, 3, 3
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 4
	REST 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C_, 4
	REST 2
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 9
	PAN $FF
	ENVELOPE 6
	VIBRATO 4, 3, 3
	REST 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 4
	REST 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	VOICE $06, 5, 12, 3, 13
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	SND_LOOP

Snd2D_Ch1:
	VOICE $06, 0, 0, 0, 0
	REST 4
	SND_SEGNO
	VOICE $06, 0, 4, 0, 0
	ENVELOPE 5
	VIBRATO 4, 3, 6
	OCTAVE 2
	NOTE A_, 3
	ENVELOPE $0C
	OCTAVE 3
	NOTE D_, 3
	ENVELOPE 5
	NOTE G_, 4
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 3
	NOTE D_, 3
	NOTE E_, $0A
	OCTAVE 3
	NOTE D_, $0C
	REST 1
	NOTE F#, 3
	NOTE E_, 6
	DUTY 0
	ENVELOPE 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 3
	ENVELOPE 5
	DUTY 4
	OCTAVE 2
	NOTE A_, 3
	ENVELOPE $0C
	OCTAVE 3
	NOTE D_, 3
	ENVELOPE 5
	NOTE G_, 4
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 3
	NOTE D_, 3
	NOTE E_, $0A
	OCTAVE 3
	NOTE D_, $0C
	REST 1
	NOTE F#, 3
	OCTAVE 3
	NOTE G_, 2
	ENVELOPE 7
	DUTY 0
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE A_, 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 9
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 2
	NOTE A#, 1
	NOTE A_, 3
	NOTE A_, 1
	REST 2
	NOTE A_, 1
	NOTE A_, 1
	REST 8
	SND_LOOP

Snd2D_Ch3:
	VOICE $06, 2, 11, 4, 12
	REST 4
	SND_SEGNO
	VOICE $06, 2, 11, 4, 12
	VIBRATO 4, 3, 15
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	ATTEN 2
	RELEASE 0, 0
	NOTE A_, $0E
	ATTEN 0
	RELEASE 4, $0C
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	ATTEN 2
	RELEASE 0, 0
	NOTE G_, 7
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	REST 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 3
	NOTE A_, 3
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	ATTEN 2
	RELEASE 0, 0
	NOTE A_, $0E
	ATTEN 0
	RELEASE 4, $0C
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	ATTEN 2
	RELEASE 0, 0
	NOTE G_, 7
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 2
	WAVE $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	WAVE 4
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	OCTAVE 2
	WAVE $0A
	RELEASE 4, $0C
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 4
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	WAVE 4
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	OCTAVE 2
	WAVE $0A
	RELEASE 4, $0C
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 2
	RELEASE 0, 0
	NOTE F_, 4
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	WAVE 4
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 1
	OCTAVE 2
	WAVE $0A
	RELEASE 4, $0C
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 2
	RELEASE 0, 0
	NOTE C_, 6
	ATTEN 0
	RELEASE 4, $0C
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 2
	RELEASE 0, 0
	NOTE F_, 4
	ATTEN 0
	RELEASE 4, $0C
	NOTE G_, 1
	NOTE A_, 1
	VOICE $06, 2, 10, 4, 12
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 1
	SND_LOOP

Snd2D_Drm:
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	LEN_UNIT $06
	SND_SEGNO
	LOOP_START
	DRUM 6, 3
	DRUM 6, 1
	DRUM 5, 2
	DRUM 6, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 5, 2
	DRUM 6, 2
	LOOP_END 7
	DRUM 6, 1
	DRUM 6, 2
	DRUM 6, 1
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM 5, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 2
	DRUM 6, 1
	DRUM 5, 2
	DRUM 6, 2
	DRUM 3, 2
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 4
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 4
	LEN_UNIT $06
	SND_LOOP

Snd2E_Ch1:
	VOICE $06, 0, 4, 0, 0
	TEMPO $00
	REST 4
	ENVELOPE $19
	VIBRATO 4, 4, 4
	OCTAVE 4
	REST 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	REST 2
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	LEN_UNIT $0C
	OCTAVE 3
	NOTE G_, $0A
	LEN_UNIT $06
	REST 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	REST 2
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	REST 4
	DUTY 0
	ENVELOPE $1C
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE E_, 1
	NOTE D_, 1
	REST 1
	OCTAVE 2
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE C_, 4
	NOTE E_, 4
	REST 1
	REST 1
	REST 1
	REST 1
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	REST 1
	REST $0E
	DUTY $0C
	REST 2
	ENVELOPE $11
	VIBRATO 5, 0, 2
	OCTAVE 4
	NOTE E_, $0C
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE G#, 8
	NOTE E_, 3
	NOTE F_, 1
	REST 2
	NOTE F#, $0E
	NOTE B_, 4
	OCTAVE 4
	NOTE A#, 1
	DUTY 0
	ENVELOPE $1D
	VIBRATO_OFF $00
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A#, 1
	DUTY $0C
	ENVELOPE $1C
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 1
	REST 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 1
	REST 2
	OCTAVE 4
	NOTE C#, 2
	REST 1
	OCTAVE 3
	NOTE G#, 7
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 1
	REST 2
	NOTE A#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE D#, 3
	NOTE D#, 1
	REST 2
	NOTE G#, 6
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	REST 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	REST 4
	NOTE G#, 2
	ENVELOPE $1C
	REST 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G#, 1
	ATTEN 3
	LEN_UNIT $01
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 5
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 6
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

Snd2E_Ch2:
	VOICE $06, 0, 4, 0, 0
	ENVELOPE $19
	VIBRATO 4, 4, 4
	REST 4
	OCTAVE 4
	REST 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	REST 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	LEN_UNIT $0C
	NOTE C_, $0A
	LEN_UNIT $06
	REST 1
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	REST 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 1
	REST 4
	DUTY 0
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	DUTY 4
	ENVELOPE $1C
	OCTAVE 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F#, 1
	NOTE D_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	REST 1
	DUTY 0
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	REST 1
	REST 4
	DUTY $0C
	ENVELOPE $10
	VIBRATO 5, 0, 2
	OCTAVE 4
	NOTE E_, $0C
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE G#, 8
	NOTE E_, 3
	NOTE F_, 1
	REST 2
	NOTE F#, $0E
	NOTE B_, 4
	OCTAVE 4
	NOTE A#, 1
	DUTY 0
	ENVELOPE $1C
	VIBRATO_OFF $00
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	DUTY $0C
	OCTAVE 4
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE F#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE F#, 2
	REST 1
	NOTE F_, 7
	OCTAVE 4
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE F#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 3
	NOTE F#, 3
	NOTE F#, 1
	REST 2
	NOTE F_, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE E_, 4
	NOTE G#, 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 4
	OCTAVE 3
	NOTE B_, 2
	REST 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G#, 1
	ATTEN 3
	LEN_UNIT $01
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 5
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 6
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

Snd2E_Ch3:
	VOICE $06, 2, 11, 5, 14
	REST 4
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 5
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END 2
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	REST 4
	NOTE G#, 2
	REST 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G#, 1
	SND_END

Snd2E_Drm:
	DRUM_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 2
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 3, 2
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 3
	DRUM 5, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 9, 1
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 5, 1
	LEN_UNIT $08
	DRUM $0C, 0
	SND_END

Snd2F_Ch1:
	VOICE $06, 0, 4, 0, 0
	TEMPO $00
	REST 4
	ENVELOPE $1C
	VIBRATO 7, 0, 8
	LOOP_START
	REST 2
	OCTAVE 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 2
	LOOP_END 2
	LOOP_START
	REST 2
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE E_, 2
	LOOP_END 2
	VIBRATO 4, 4, 3
	DUTY $0C
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	REST 2
	DUTY 0
	REST 2
	OCTAVE 3
	REST 1
	REST 1
	REST 1
	REST 1
	REST 1
	REST 1
	REST 1
	REST 5
	DUTY 4
	ENVELOPE $11
	REST 2
	VIBRATO 5, 0, 2
	OCTAVE 2
	REST 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE G#, 4
	NOTE B_, 8
	NOTE G#, 8
	NOTE A#, 4
	NOTE F#, 4
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 1
	REST 2
	NOTE A#, 2
	NOTE A#, 0
	OCTAVE 2
	NOTE G#, 6
	NOTE B_, 6
	NOTE G#, 4
	NOTE F#, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE C#, $0A
	OCTAVE 3
	NOTE D#, 6
	NOTE G#, 6
	NOTE F#, 4
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE C#, 6
	OCTAVE 1
	NOTE B_, 8
	OCTAVE 2
	NOTE C#, 6
	NOTE C#, 2
	DUTY 0
	ENVELOPE $1C
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 4
	NOTE G#, 2
	REST 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	LEN_UNIT $01
	ATTEN 3
	OCTAVE 3
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 4
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 5
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd2F_Ch2:
	VOICE $06, 0, 4, 0, 0
	ENVELOPE $1C
	VIBRATO 7, 0, 8
	REST 4
	LOOP_START
	REST 2
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A#, 2
	LOOP_END 2
	LOOP_START
	REST 2
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	LOOP_END 2
	VIBRATO 4, 4, 3
	DUTY $0C
	OCTAVE 4
	NOTE E_, 8
	NOTE F#, 8
	DUTY 0
	ENVELOPE 1
	REST 2
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE D_, 1
	REST 5
	DUTY 4
	VIBRATO 5, 0, 2
	ENVELOPE $10
	OCTAVE 2
	REST 4
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE G#, 4
	NOTE B_, 8
	NOTE G#, 8
	NOTE A#, 4
	NOTE F#, 4
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 1
	REST 2
	NOTE A#, 2
	NOTE A#, 0
	OCTAVE 2
	NOTE G#, 6
	NOTE B_, 6
	NOTE G#, 4
	NOTE F#, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE C#, $0A
	OCTAVE 3
	NOTE D#, 6
	NOTE G#, 6
	NOTE F#, 4
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE C#, 8
	OCTAVE 2
	NOTE E_, 8
	NOTE F#, 6
	NOTE F#, 2
	DUTY 0
	ENVELOPE $1C
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	REST 4
	NOTE B_, 2
	REST 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G#, 1
	LEN_UNIT $01
	ATTEN 3
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 5
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_END

Snd2F_Ch3:
	VOICE $06, 2, 11, 5, 14
	REST 4
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 2
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 2
	NOTE A_, 1
	NOTE C_, 2
	NOTE A#, 1
	NOTE C_HI, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_HI, 2
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 2
	NOTE B_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE F#, 2
	NOTE G_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE D_, 1
	REST 5
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	REST 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	REST 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE G#, 2
	REST 1
	OCTAVE 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE F#, 1
	REST 2
	NOTE F#, 7
	OCTAVE 1
	NOTE G#, 3
	NOTE G#, 1
	REST 2
	NOTE G#, 2
	REST 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 3
	NOTE F#, 1
	REST 2
	NOTE F_, 2
	REST 1
	NOTE F_, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	REST 4
	NOTE G#, 2
	REST 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	SND_END

Snd2F_Drm:
	DRUM_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $06
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 2
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 3, 2
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 3
	DRUM 5, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	LOOP_START
	DRUM 6, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 6, 1
	LEN_UNIT $03
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT $06
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 3, 2
	LOOP_END 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT $03
	DRUM 8, 1
	DRUM 9, 1
	LEN_UNIT $06
	DRUM $0A, 1
	DRUM 5, 1
	SND_END

Snd30_Ch1:
	VOICE $04, 0, 0, 0, 0
	TEMPO $20
	REST 8
	VOICE $04, 0, 0, 0, 0
	ENVELOPE $0B
	VIBRATO 4, 2, 3
	REST 4
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 8
	REST 0
	REST 4
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 8
	REST 0
	DUTY 8
	ENVELOPE $17
	VIBRATO 4, 4, 6
	NOTE B_, $0C
	VIBRATO 4, 4, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 6
	NOTE D#, 4
	VIBRATO 5, 0, 4
	NOTE D_, 0
	VIBRATO_OFF $00
	VOICE $01, 7, 4, 0, 0
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	LEN_UNIT $04
	DUTY 0
	ENVELOPE $0B
	VIBRATO 5, 0, 15
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 4
	NOTE D_, 6
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 4
	NOTE D_, 6
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 4
	NOTE E_, 4
	DUTY 8
	ENVELOPE $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	SND_END

Snd30_Ch2:
	VOICE $01, 7, 4, 0, 0
	OCTAVE 6
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	REST 4
	LOOP_START
	NOTE F_, 1
	NOTE D#, 1
	LOOP_END 13
	ATTEN 5
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 0
	VOICE $04, 0, 0, 0, 0
	ENVELOPE $0B
	VIBRATO 4, 2, 3
	OCTAVE 3
	NOTE C#, 4
	NOTE D_, 8
	DUTY 8
	VIBRATO 5, 0, 8
	ENVELOPE $0C
	OCTAVE 3
	NOTE G_, 6
	NOTE F#, 6
	NOTE E_, 4
	DUTY 0
	VIBRATO 4, 2, 3
	ENVELOPE $0B
	OCTAVE 3
	REST 4
	NOTE F#, 4
	NOTE G_, 8
	DUTY 8
	VIBRATO 5, 0, 8
	ENVELOPE $0C
	OCTAVE 3
	NOTE C_HI, 6
	NOTE B_, 6
	NOTE A_, 4
	DUTY 0
	ENVELOPE $0D
	VIBRATO_OFF $00
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	VOICE $01, 7, 4, 0, 0
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	LEN_UNIT $04
	DUTY 0
	ENVELOPE $0C
	VIBRATO 5, 0, 15
	OCTAVE 3
	NOTE G#, 4
	NOTE A_, 8
	NOTE A_, 6
	NOTE A_, 6
	OCTAVE 3
	NOTE G#, 4
	NOTE A_, 8
	NOTE A_, 6
	NOTE A_, 6
	OCTAVE 3
	NOTE G#, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE B_, 4
	DUTY 8
	ENVELOPE $0F
	NOTE A_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE B_, 2
	SND_END

Snd30_Ch3:
	VOICE $04, 2, 10, 5, 12
	REST 8
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 2
	WAVE $0A
	RELEASE 4, $0C
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 2
	REST 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	WAVE $0A
	RELEASE 5, $0C
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE E_, 2
	SND_END

Snd30_Drm:
	DRUM_UNIT $04
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0A, 1
	DRUM $0A, 1
	DRUM $0A, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 3, 2
	LOOP_END 3
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 6, 2
	DRUM 5, 2
	DRUM 5, 1
	LEN_UNIT $0E
	DRUM $0C, $0A
	SND_END

; Unused ($FF) to the end of the bank.
SoundDataEnd:
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
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
