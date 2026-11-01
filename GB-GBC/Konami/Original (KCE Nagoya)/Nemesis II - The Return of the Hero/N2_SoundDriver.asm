; ==========================================================================
; Nemesis II - The Return of the Hero (E) - Konami sound driver (third GB version)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: rst $28, timer vector/ISR, bank helpers, PlaySound/StopAll/update ($09AE-$0C6C), CopyBytes
;   banks 13, 14, 15: each holds a copy of the track code, its tables and its sounds
;     (ids $01-$5D, $81-$96, $C1-$D9)
; Build: rgbasm -Wall -o n2.o N2_SoundDriver.asm && rgblink -o n2.gb n2.o
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
DEF rTMA EQU $FF06
DEF rTAC EQU $FF07

; ---------------------------------------------------------------- RAM
DEF wTrkSfx1 EQU $C080 ; 56 bytes
DEF wTrkSfx2 EQU $C180 ; 56 bytes
DEF wTrkSfxN EQU $C280 ; 56 bytes
DEF wTrkCh1 EQU $C380 ; 56 bytes
DEF wTrkCh2 EQU $C480 ; 56 bytes
DEF wTrkCh3 EQU $C580 ; 56 bytes
DEF wTrkDrm EQU $C680 ; 56 bytes
DEF wTrackIdx EQU $C0BB
DEF wRegBase EQU $C0BC
DEF wTempo EQU $C0BD
DEF wTempoAcc EQU $C0BE
DEF wTempoPhase EQU $C0BF
DEF wTempoOn EQU $C0C0
DEF wTempoSkip EQU $C0C1
DEF wNR51 EQU $C0C3
DEF wSweepVal EQU $C0C4
DEF wReqId EQU $C0C5
DEF wReqPrio EQU $C0C6
DEF wRegVal EQU $C0C7
DEF wRegIdx EQU $C0C8
DEF wMusicHold EQU $C0C9
DEF wFadeReq EQU $C0CB
DEF wFadeStep EQU $C0CC
DEF wFadeTimer EQU $C0CD
DEF wFadeLevel EQU $C0CE
DEF wReqRefused EQU $C0CF
DEF wHalfPhase EQU $C0D0
DEF wFade2Req EQU $C0D3
DEF wFade2Timer EQU $C0D4
DEF wFade2Level EQU $C0D5
DEF wShadow EQU $C1B7 ; 20 bytes
DEF wSndLock EQU $C78D
DEF wPauseFlags EQU $C794
DEF wRomBank EQU $C7A4
DEF wRomBankSave EQU $C7C6
DEF wSndDisable EQU $CC0E
DEF rROMB EQU $2000 ; MBC1 bank select
DEF SOUND_TABLE_M2 EQU $3FFE ; every sound bank has its sound table at $4000 (index from 1)

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
DEF TRK_DUTYSTEP EQU $B2
DEF TRK_VOICEDUTY EQU $B3
DEF TRK_DUTYTICKS EQU $B4
DEF TRK_DUTYRELOAD EQU $B5
DEF TRK_PAN EQU $B6

; TRK_FLAGS
DEF TF_AUTOPAN EQU 1
DEF TF_VIBRATO EQU 2
DEF TF_VIBNEG EQU 3
DEF TF_DUTYSTEP EQU 4
DEF TF_FORCE EQU 6
; TRK_FLAGS2
DEF TF2_RELEASED EQU 2
DEF TF2_REST EQU 3
DEF TF2_RAW EQU 4 ; 4 and 5: the stream starts with $E1
; TRK_FLOW: bit 0/1 loop open, bit 2 in a call, bit 3 segno set

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
; $00-$DF: note. hi = pitch 1-13 (0 = rest), lo = length multiplier (x LEN_UNIT; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: whole byte -> NR43 (NR44 = $80), length = LEN_UNIT
MACRO NOISE
	db \1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #)
MACRO VOICE
	db $E0, \1, (\3 << 4) | \2, (\5 << 4) | \4
ENDM
MACRO NVOICE
	db $E0, \1, (\2 << 4) | \3
ENDM
MACRO DRUM_UNIT
	db $E0, \1
ENDM
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
MACRO RELEASE
	db $E8, (\2 << 4) | \1
ENDM
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
; $EA 4n: autopan on (n != 0) / off
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; $EB n, xy: vibrato table n (low nibble only), delay (x + 1) * unit ticks (x = 0: none), depth y (0 = 1)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
; $EB n with n & 15 = 0: vibrato off
MACRO VIBRATO_OFF
	db $EB, \1
ENDM
MACRO CMD_EC
	db $EC, \1
ENDM
; $ED xy: duty step. Each note starts with duty \1, the voice duty comes back after \2 ticks; \2 = 0: off
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
ENDM
; $EE: tempo (the tempo accumulator is reset to it too)
MACRO TEMPO
	db $EE, \1
ENDM
; $EF: TRK_PAN = raw NR51 bits (this track's bits are used)
MACRO PAN
	db $EF, \1
ENDM
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
; $FE: first one marks, the next one jumps back to the mark (forever)
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; raw streams (first byte $E1): header unit, duty (low nibble), NR10 value; then frames
MACRO RAW_HEADER
	db $E1, \1, \2, \3
ENDM
; frame: NRx2 = vol << 4 (no envelope), NRx3/NRx4 = period (bit 11 unused), for one unit
MACRO RAW_NOTE
	db (\1 << 4) | HIGH(\2), LOW(\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; $EB in a raw stream sets the unit
MACRO RAW_UNIT
	db $EB, \1
ENDM
; vibrato table: one byte per step: delay (ticks), negate flag, offset 0-7 (x depth)
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

SECTION "rst28", ROM0[$0028]

; rst $28: HL += A.
AddAToHL:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "Timer vector", ROM0[$0050]

; Timer interrupt (TMA $80, TAC 16384 Hz -> 128 Hz). Interrupts are enabled at once.
TimerVector:
	ei
	jp TimerISR

SECTION "Timer ISR", ROM0[$00B3]

; TimerISR: one driver update unless wSndLock bit 0 (update running) or bit 1
; (PlaySoundFar running) is set.
TimerISR:
	push hl
	push bc
	push de
	push af
	ld hl, wSndLock
	ld a, [hl]
	and $03
	jr nz, .l00C9
	set 0, [hl]
	call SndUpdate
	ld hl, wSndLock
	res 0, [hl]
.l00C9:
	pop af
	pop de
	pop bc
	pop hl
	ret

SECTION "LoadPtrIndexed0", ROM0[$0254]

LoadPtrIndexed0:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

SECTION "PlaySoundFar", ROM0[$0283]

; PlaySoundFar: A = sound id. Ignored while wSndDisable bit 0 is set. Sets wSndLock
; bit 1 around PlaySound and maps bank 2 afterwards if the caller was in bank 2,
; else bank 1. The helpers below map bank n and record it in wRomBank.
PlaySoundFar:
	push af
	ld a, [wRomBank]
	ld [wRomBankSave], a
	pop af
	push hl
	ld hl, wSndDisable
	bit 0, [hl]
	jr nz, .l02A6
	ld hl, wSndLock
	set 1, [hl]
	push de
	push bc
	push af
	call PlaySound
	pop af
	pop bc
	pop de
	ld hl, wSndLock
	res 1, [hl]
.l02A6:
	pop hl
	push af
	ld a, [wRomBankSave]
	cp $02
	jr z, .l02B2
	pop af
	jr SetBank1
.l02B2:
	pop af
	jr SetBank2

SetBank1:
	push af
	ld a, $01

SetBankA:
	di
	ld [rROMB], a
	ld [wRomBank], a
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

SetBank8:
	push af
	ld a, $08
	jr SetBankA

SetBank9:
	push af
	ld a, $09
	jr SetBankA

SetBank10:
	push af
	ld a, $0A
	jr SetBankA

SetBank11:
	push af
	ld a, $0B
	jr SetBankA

SetBank12:
	push af
	ld a, $0C
	jr SetBankA

SetBank13:
	push af
	ld a, $0D
	jr SetBankA

SetBank14:
	push af
	ld a, $0E
	jr SetBankA

SetBank15:
	push af
	ld a, $0F
	jr SetBankA

SECTION "Sound ROM0", ROM0[$09AE]

; StartMusicFade: wFadeReq = A (the game writes wFadeReq directly instead).
StartMusicFade:
	ld [wFadeReq], a
	ret

; PlaySound: A = sound id, 0 = StopAll. $96 stops everything first, $56 is not
; restarted while it plays on Sfx1. Bits 7-6 of the id pick the bank (0x/40: 13,
; 80: 14, C0: 15) whose sound table is read.
PlaySound:
	ld [wReqId], a
	or a
	jp z, StopAll
	cp $96
	push af
	call z, StopAll
	pop af
	ld [wReqId], a
	cp $56
	jp nz, .l09D1
	ld a, [wTrkSfx1]
	ld b, a
	ld a, [wReqId]
	cp b
	ret z
.l09D1:
	cp $C0
	jr c, .l09E6
	call SetBank15
	ld a, [wReqId]
	and $3F
	ld hl, SOUND_TABLE_M2
	call PlaySoundHeader
	jp SetBank1
.l09E6:
	cp $80
	jr c, .l09FB
	call SetBank14
	ld a, [wReqId]
	and $3F
	ld hl, SOUND_TABLE_M2
	call PlaySoundHeader
	jp SetBank1
.l09FB:
	call SetBank13
	ld a, [wReqId]
	and $7F
	ld hl, SOUND_TABLE_M2
	call PlaySoundHeader
	jp SetBank1

; As in Belmont's Revenge, wReqRefused after Sfx1 and after Sfx2/SfxN aborts the
; rest of the request and is never cleared by a new one.
PlaySoundHeader:
	call LoadPtrIndexed0
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
	jr nz, .l0A5B
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
.l0A5B:
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld hl, wTrkCh1
	jr StartTrack

; StartCh2 also clears the tempo state and wFadeReq.
StartCh2:
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	xor a
	ld [wTempo], a
	ld [wTempoAcc], a
	ld [wTempoPhase], a
	ld [wTempoOn], a
	ld [wTempoSkip], a
	xor a
	ld [wFadeReq], a
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
	jr c, .l0AAC
	ld [hl], a
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l0AAC:
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
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l0AE6
	ld [hl], a
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
.l0AE6:
	dec l

; StartTrack: a refused track leaves DE unchanged, so the next track of the mask
; is started with the refused track's pointer; it also gets TRK_PAN = $FF. An
; accepted track whose stream starts with $E1 is a raw stream (TF2_RAW).
StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l0B2A
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
	jr nz, .l0B21
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l0B2F
.l0B21:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l0B2F
.l0B2A:
	push de
	inc de
	inc de
	ld a, $01
.l0B2F:
	ld [wReqRefused], a
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

; StopAll: clear the 7 tracks ($38 bytes), the shadows and the globals, wNR51 =
; $FF (not written), then SndPause (NR12/NR17/NR21/NR1C = 0).
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld b, $07
.l0B42:
	push bc
	push hl
	push de
	ld [hl], $00
	ld bc, $0037
	call CopyBytes0
	pop de
	pop hl
	pop bc
	inc h
	inc d
	dec b
	jr nz, .l0B42
	ld hl, wShadow
	ld de, wShadow + $01
	ld bc, $0014
	ld [hl], $00
	call CopyBytes0
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0020
	ld [hl], $00
	call CopyBytes0
	ld a, $FF
	ld [wNR51], a

SndPause:
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; SndUnpause: copy the shadows back per active channel, then NR10 = 0.
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
	jr z, .l0BA1
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
	xor a
	ldh [rNR10], a
.l0BA1:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l0BB6
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l0BB6:
	ld a, [wTrkCh3]
	or a
	jr z, .l0BC7
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l0BC7:
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

; SndUpdate: run each track in the bank of its sound id (id 0: bank 13). Then the
; unused second fade (wFade2Req) and, unless paused, the half-rate phase.
SndUpdate:
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	cp $C0
	ld a, [hl]
	jr nc, .l0BFE
	cp $80
	ld a, [hl]
	jr nc, .l0C0E
	ld a, $0D
	ld [rROMB], a
	call B13_TrackEntry
	ld a, [wRomBank]
	ld [rROMB], a
	jr SndUpdateNext
.l0BFE:
	ld a, $0F
	ld [rROMB], a
	call B15_TrackEntry
	ld a, [wRomBank]
	ld [rROMB], a
	jr SndUpdateNext
.l0C0E:
	ld a, $0E
	ld [rROMB], a
	call B14_TrackEntry
	ld a, [wRomBank]
	ld [rROMB], a

SndUpdateNext:
	ld a, [wTrackIdx]
	inc a
	ld [wTrackIdx], a
	cp $07
	jr nz, SndUpdate
	xor a
	ld [wTrackIdx], a

Fade2Tick:
	ld a, [wFade2Req]
	or a
	jr z, HalfPhaseTick
	ld a, [wFade2Timer]
	or a
	jr z, .l0C3D
	dec a
	ld [wFade2Timer], a
	jr HalfPhaseTick
.l0C3D:
	ld a, $FF
	ld [wFade2Timer], a
	ld a, [wFade2Level]
	inc a
	ld [wFade2Level], a
	cp $05
	jr nz, HalfPhaseTick
	xor a
	ld [wFade2Req], a
	ld [wFade2Timer], a
	ld [wFade2Level], a

HalfPhaseTick:
	ld a, [wPauseFlags]
	rra
	ret c
	ld a, [wHalfPhase]
	cp $01
	jr nz, .l0C68
	xor a
	ld [wHalfPhase], a
	ret
.l0C68:
	ld hl, wHalfPhase
	inc [hl]
	ret

SECTION "CopyBytes0", ROM0[$0D85]

CopyBytes0:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, c
	or b
	jr nz, CopyBytes0
	ret

SECTION "Sound bank 13", ROMX[$4000], BANK[13]
B13_SoundTable:
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
	dw SndHdr36 ; $3A
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
	dw SndHdr4A ; $4B
	dw SndHdr4A ; $4C
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

SndHdr0E:
	SND_HEADER $2F, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd10_Sfx1
	dw Snd10_SfxN

SndHdr11:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd11_Sfx1
	dw Snd11_Sfx2

SndHdr12:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd12_Sfx1
	dw Snd12_Sfx2
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd13_Sfx1
	dw Snd13_Sfx2
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd14_Sfx1
	dw Snd14_Sfx2
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $31, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd15_Sfx1
	dw Snd15_Sfx2
	dw Snd15_SfxN

SndHdr16:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd16_Sfx1
	dw Snd16_Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd17_Sfx1
	dw Snd17_Sfx2
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd18_Sfx1
	dw Snd18_Sfx2
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd19_Sfx1
	dw Snd19_Sfx2
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd1A_Sfx1
	dw Snd1A_SfxN

SndHdr1B:
	SND_HEADER $33, $04 ; tracks: SfxN
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd1E_Sfx1
	dw Snd1E_SfxN

SndHdr1F:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd20_Sfx1
	dw Snd20_SfxN

SndHdr21:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd21_Sfx1
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd22_Sfx1
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd23_Sfx1
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd24_Sfx1
	dw Snd23_SfxN

SndHdr25:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd25_Sfx1

SndHdr26:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd26_Sfx1

SndHdr27:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd28_Sfx1

SndHdr29:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd29_Sfx1
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $31, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd2A_Sfx1
	dw Snd2A_Sfx2
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $31, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd2B_Sfx1
	dw Snd2B_Sfx2
	dw Snd2B_SfxN

SndHdr2C:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd2C_SfxN

SndHdr2D:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd2D_Sfx1
	dw Snd2D_SfxN

SndHdr2E:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd2E_Sfx1
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd2F_Sfx1
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $31, $03 ; tracks: Sfx1, Sfx2
	dw Snd30_Sfx1
	dw Snd30_Sfx2

SndHdr31:
	SND_HEADER $32, $03 ; tracks: Sfx1, Sfx2
	dw Snd31_Sfx1
	dw Snd31_Sfx2

SndHdr32:
	SND_HEADER $31, $24 ; tracks: SfxN, Ch3
	dw Snd32_SfxN
	dw Snd32_Ch3

SndHdr33:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd33_SfxN

SndHdr34:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr37:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd38_Sfx1
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd38_Sfx1
	dw Snd39_SfxN

SndHdr36:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd36_SfxN

SndHdr3B:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd3B_Sfx1
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $33, $05 ; tracks: Sfx1, SfxN
	dw Snd3D_Sfx1
	dw Snd3D_SfxN

SndHdr3E:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd3F_Sfx1
	dw Snd3F_SfxN

SndHdr40:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd40_SfxN

SndHdr41:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd41_Sfx1
	dw Snd41_SfxN

SndHdr42:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd42_SfxN

SndHdr43:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd43_Sfx1
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd44_Sfx1

SndHdr45:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd45_Sfx1

SndHdr46:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd47_Sfx1

SndHdr48:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd49_Sfx1
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $32, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd4A_SfxN
	dw Snd4A_Ch1
	dw Snd4A_Ch2

SndHdr4D:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd4D_Sfx1
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd4E_Sfx1

SndHdr4F:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd4F_Sfx1
	dw Snd4F_SfxN

SndHdr50:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd50_Sfx1
	dw Snd50_SfxN

SndHdr51:
	SND_HEADER $32, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd51_SfxN
	dw Snd51_Ch1
	dw Snd51_Ch2

SndHdr52:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd52_Sfx1
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $32, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd53_Sfx1
	dw Snd53_Sfx2
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd54_Sfx1

SndHdr55:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd55_Sfx1

SndHdr56:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd56_Sfx1

SndHdr57:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd57_Sfx1

SndHdr58:
	SND_HEADER $34, $01 ; tracks: Sfx1
	dw Snd58_Sfx1

SndHdr59:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd59_Sfx1

SndHdr5A:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd5A_Sfx1

SndHdr5B:
	SND_HEADER $34, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd5B_Sfx1
	dw Snd5B_Sfx2
	dw Snd5B_SfxN

SndHdr5C:
	SND_HEADER $3F, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd5C_Sfx1
	dw Snd5C_Sfx2
	dw Snd5C_SfxN

SndHdr5D:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd5D_Sfx1
B13_DrumMap:
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
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd04_Sfx1
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $02, $04 ; tracks: SfxN
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
	NVOICE 1, $0F, 1
	NOISE $01
	NVOICE 1, $0A, 1
	NOISE $11
	SND_END

Snd05_SfxN:
	NVOICE 1, 9, 1
	NOISE $01
	NVOICE 1, 6, 1
	NOISE $11
	SND_END

Snd02_SfxN:
	NVOICE 1, 6, 0
	NOISE $02
	NVOICE 3, 8, 0
	NOISE $02
	NVOICE $0A, 4, 5
	NOISE $02
	SND_END

Snd09_SfxN:
	NVOICE 1, $0F, 3
	NOISE $3D
	NOISE $74
	SND_END

Snd0A_SfxN:
	NVOICE 1, $0F, 1
	NOISE $0A
	NVOICE 1, 8, 0
	NOISE $71
	SND_END

Snd08_SfxN:
	NVOICE 1, $0F, 0
	NOISE $01
	NOISE $72
	NVOICE 1, $0C, 0
	NOISE $25
	NVOICE 5, 5, 3
	NOISE $07
	SND_END

Snd06_SfxN:
	NVOICE 1, $0F, 0
	NOISE $43
	NOISE $24
	NVOICE $0A, 8, 1
	NOISE $33
	SND_END

Snd03_SfxN:
	NVOICE 5, 3, $0B
	NOISE $01
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $13
	NOISE $14
	NOISE $14
	NOISE $15
	NOISE $15
	NOISE $16
	NOISE $16
	NOISE $17
	NOISE $17
	SND_END
B13_Orphan_4310:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B13_Orphan_4317:
	RAW_HEADER 2, $08, $1F
	PAN $F0
	RAW_NOTE 8, $6FF
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $699
	SND_END
B13_Orphan_4326:
	PAN $0F
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B13_Orphan_432D:
	RAW_HEADER 2, $08, $1E
	PAN $0F
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END
B13_Orphan_433C:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B13_Orphan_4343:
	RAW_HEADER 2, $08, $1E
	PAN $F0
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END

Snd0B_SfxN:
	NVOICE 1, $0F, 1
	NOISE $79
	NVOICE $0C, 7, 0
	NOISE $02
	NVOICE $18, 4, 7
	NOISE $02
	SND_END

Snd0C_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $3D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd0C_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd0D_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $2D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd0D_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd07_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd07_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd04_Sfx1:
	VOICE 5, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 6
	SND_END

Snd04_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

B13_CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, B13_CopyBytes
	ret

B13_LoadPtrIndexed:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

B13_JumpTableInline:
	pop hl
	call B13_LoadPtrIndexed
	jp hl
B13_PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7
B13_WaveTable:
	dw B13_WaveData1
	dw B13_WaveData2
	dw B13_WaveData3
	dw B13_WaveData4
	dw B13_WaveData5
	dw B13_WaveData6
	dw B13_WaveData7
	dw B13_WaveData8
	dw B13_WaveData9
	dw B13_WaveData10
	dw B13_WaveData11
	dw B13_WaveData12
B13_WaveData1:
	db $F0, $EE, $CA, $86, $0A, $46, $8A, $CE, $FF, $EE, $CA, $86, $0A, $46, $8A, $CE
B13_WaveData2:
	db $F8, $23, $45, $67, $89, $AB, $CD, $EF, $F8, $23, $45, $67, $89, $AB, $CD, $EF
B13_WaveData3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
B13_WaveData4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
B13_WaveData5:
	db $23, $44, $55, $67, $89, $9A, $BB, $CD, $23, $56, $78, $9A, $CD, $CA, $98, $53
B13_WaveData6:
	db $60, $58, $00, $FF, $F9, $00, $00, $20, $20, $08, $08, $40, $C0, $00, $C0, $00
B13_WaveData7:
	db $FF, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
B13_WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
B13_WaveData9:
	db $88, $80, $8F, $FF, $88, $88, $88, $80, $40, $08, $08, $88, $40, $00, $80, $00
B13_WaveData10:
	db $66, $60, $8F, $C0, $88, $80, $40, $20, $20, $08, $08, $88, $40, $00, $80, $00
B13_WaveData11:
	db $F8, $88, $44, $33, $22, $22, $11, $00, $00, $11, $00, $00, $00, $88, $FF, $11
B13_WaveData12:
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $11, $11, $22, $22, $33, $33, $44, $44, $55
	db $02, $46, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $45, $65, $43, $21, $00
	db $ED, $44, $EF, $44, $F6, $44, $F8, $44, $02, $45, $0D, $45, $31, $45, $3A, $45
B13_VibratoTable:
	dw B13_Vib01 ; 1
	dw B13_Vib02 ; 2
	dw B13_Vib03 ; 3
	dw B13_Vib04 ; 4
	dw B13_Vib05 ; 5
	dw B13_Vib06 ; 6
	dw B13_Vib07 ; 7
	dw B13_Vib08 ; 8
	dw B13_Vib09 ; 9
	dw B13_Vib0A ; 10
	dw B13_Vib0B ; 11
	dw B13_Vib0C ; 12
	dw B13_Vib0D ; 13
	dw B13_Vib0E ; 14
	dw B13_Vib0F ; 15

B13_Vib01:
	VIB_STEP 1, 1, 1
	VIB_HOLD

B13_Vib02:
	VIB_SEGNO
	VIB_STEP 12, 0, 1
	VIB_STEP 12, 0, 1
	VIB_STEP 12, 0, 0
	VIB_STEP 12, 0, 0
	VIB_REPEAT $FF

B13_Vib03:
	VIB_STEP 1, 0, 1
	VIB_HOLD

B13_Vib04:
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

B13_Vib05:
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

B13_Vib06:
	VIB_SEGNO
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 1, 1
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 1, 2
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 1, 3
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 1, 4
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 1, 5
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 1, 6
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 7
	VIB_REPEAT 3
	VIB_HOLD

B13_Vib07:
	VIB_STEP 4, 1, 0
	VIB_STEP 4, 1, 1
	VIB_STEP 4, 1, 2
	VIB_STEP 4, 1, 3
	VIB_STEP 4, 1, 4
	VIB_STEP 4, 1, 5
	VIB_STEP 4, 1, 6
	VIB_STEP 4, 1, 7
	VIB_HOLD

B13_Vib08:
	VIB_STEP 15, 0, 1
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B13_Vib09:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 0
	VIB_HOLD

B13_Vib0A:
	VIB_STEP 15, 1, 2
	VIB_SEGNO
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B13_Vib0B:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

B13_Vib0C:
	VIB_STEP 8, 1, 1
	VIB_STEP 8, 1, 2
	VIB_STEP 8, 1, 3
	VIB_STEP 8, 1, 4
	VIB_STEP 8, 1, 5
	VIB_STEP 8, 1, 6
	VIB_STEP 8, 1, 7
	VIB_HOLD

B13_Vib0D:
	VIB_STEP 8, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_REPEAT $FF

B13_Vib0E:
	VIB_STEP 8, 1, 2
	VIB_SEGNO
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 0
	VIB_REPEAT $FF

B13_Vib0F:
	VIB_HOLD

B13_PlayDrumSound:
	ld [wReqId], a
	or a
	jp z, B13_StopAll
	and $7F
	ld hl, SOUND_TABLE_M2
	call B13_LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl+]
	ld d, h
	ld e, l
	cp $05
	jr nz, .l4637
	call B13_StartSfx1
.l4637:
	call B13_StartSfxN
	ld a, [wNR51]
	ldh [rNR51], a
	ret

; (unreachable)
	ret

B13_StartSfxN:
	push af
	ld hl, wTrkSfxN
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4654
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l4654:
	dec l
	jr B13_StartTrack

B13_StartSfx1:
	push af
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4671
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
.l4671:
	dec l

B13_StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l46B5
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
	jr nz, .l46AC
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l46B8
.l46AC:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l46B8
.l46B5:
	push de
	inc de
	inc de
.l46B8:
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

B13_StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0037
	ld [hl], $00
	call B13_CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0037
	ld [hl], $00
	call B13_CopyBytes
	ld hl, wShadow
	ld de, wShadow + $01
	ld bc, $0014
	ld [hl], $00
	call B13_CopyBytes
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0020
	ld [hl], $00
	call B13_CopyBytes
	ld a, $FF
	ld [wNR51], a

B13_FadeStep:
	ld a, [wFadeReq]
	or a
	jr nz, B13_FadeCount
.l4703:
	ld [wFadeTimer], a
	ld [wFadeLevel], a
	ld [wFadeStep], a
	ld [wFadeReq], a
	ret

B13_FadeCount:
	ld a, [wFadeTimer]
	inc a
	ld [wFadeTimer], a
	cp $70
	jp z, B13_FadeNextStep
	ret

B13_FadeNextStep:
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
	jp nz, .l4740
	xor a
	ld hl, wTrkDrm
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ret
.l4740:
	ld a, [wFadeStep]
	cp $07
	jp nz, .l4755
	xor a
	ld hl, wTrkCh3
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ldh [rNR32], a
	ldh [rNR30], a
	ret
.l4755:
	ld a, [wFadeStep]
	cp $09
	ret nz
	xor a
	ld hl, wTrkCh1
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx1
	ld a, [hl]
	or a
	jr nz, .l4775
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
.l4775:
	xor a
	ld hl, wTrkCh2
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx2
	ld a, [hl]
	or a
	jr nz, .l478F
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
.l478F:
	xor a
	jp B13_FadeStep.l4703

B13_TrackEntry:
	ld a, [wPauseFlags]
	rra
	jr nc, .l479F
	ld l, TRK_ID
	ld a, [hl]
	cp $5D
	ret nz
.l479F:
	ld a, [wTrackIdx]
	cp $03
	jp c, B13_TrackTick
	ld a, [wTempoSkip]
	or a
	jr nz, .l47EE
	ld a, [wTempo]
	or a
	jr nz, .l47B9
	xor a
	ld [wTempoOn], a
	jr B13_HalfRate
.l47B9:
	ld a, $01
	ld [wTempoOn], a
	ld a, [wTempoPhase]
	cp $03
	jr z, .l47CB
	inc a
	ld [wTempoPhase], a
	jr B13_HalfRate
.l47CB:
	xor a
	ld [wTempoPhase], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	jr nc, .l47E8
	ld a, [wTempo]
	ld [wTempoAcc], a
	ld a, $01
	ld [wTempoSkip], a
	ret
.l47E8:
	xor a
	ld [wTempoSkip], a
	jr B13_HalfRate
.l47EE:
	ld a, [wTempoPhase]
	cp $03
	jr z, .l47E8
	inc a
	ld [wTempoPhase], a
	ret

; (unreachable)
	ld a, [wTempoSkip]
	or a
	ret nz

B13_HalfRate:
	ld a, [wHalfPhase]
	or a
	jr z, .l480A
	cp $01
	jr z, .l4819
	ret
.l480A:
	ld a, [wTrackIdx]
	cp $03
	jr z, .l4828
	ld a, [wTrackIdx]
	cp $04
	jr z, .l4828
	ret
.l4819:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4828
	ld a, [wTrackIdx]
	cp $06
	jr z, .l4828
	ret
.l4828:
	call B13_FadeStep

B13_TrackTick:
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	call B13_GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, .l4864
	ld l, TRK_FLAGS2
	res 2, [hl]
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $00
	jr nz, .l4853
.l4853:
	ld a, [wTrackIdx]
	cp $05
	jp nz, B13_ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp B13_ReadCmds
.l4864:
	ld l, TRK_FLAGS2
	ld a, [hl]
	and $18
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l4889
	ld l, TRK_DUTYTICKS
	ld a, [hl]
	dec a
	ld [hl], a
	jr nz, .l4889
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B13_WriteDuty
.l4889:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l4895
	ld l, TRK_FLAGS2
	set 2, [hl]
.l4895:
	ld l, TRK_FLAGS
	bit 2, [hl]
	jr z, .l48A7
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jr z, .l48A4
	dec [hl]
	jr .l48A7
.l48A4:
	call B13_VibratoTick
.l48A7:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l48C9
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
	call B13_WriteReg
	jp B13_Trigger
.l48C9:
	ld l, TRK_FLAGS2
	bit 2, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l48F5
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
	jr z, .l48F5
	inc a
	and $03
	ld [hl], a
	jr z, .l48F5
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l48F2
	xor a
.l48F2:
	rla
	swap a
.l48F5:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B13_WriteReg

B13_ReadCmdsNext:
	inc de

B13_ReadCmds:
	ld a, [de]
	cp $FB
	jp c, B13_ReadCmdsLow
	inc de
	sub $FB
	push hl
	call B13_JumpTableInline
	dw B13_Cmd_Loop
	dw B13_Cmd_Loop2
	dw B13_Cmd_Call
	dw B13_Cmd_Segno
	dw B13_Cmd_End

B13_Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $01
	jp nz, .l492A
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B13_ReadCmds
.l492A:
	ld a, [de]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l4938
	ld l, TRK_LOOPPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B13_ReadCmds
.l4938:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jr B13_ReadCmdsNext

B13_Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $02
	jp nz, .l4954
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B13_ReadCmds
.l4954:
	push hl
	ld a, [de]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l4964
	pop hl
	ld l, TRK_LOOP2PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B13_ReadCmds
.l4964:
	pop hl
	ld l, TRK_LOOP2CNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jr B13_ReadCmdsNext

B13_Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $04
	jp nz, .l498A
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
	jp B13_ReadCmds
.l498A:
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLOW
	res 2, [hl]
	jp B13_ReadCmds

B13_Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $08
	jp nz, .l49A9
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp B13_ReadCmds
.l49A9:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B13_ReadCmds

B13_Cmd_End:
	pop hl
	dec de
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B13_WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l49CE
	xor a
	ldh [rNR30], a
	ret
.l49CE:
	cp $02
	jr z, .l49F0
	cp $01
	jr z, .l49E0
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l49E2
.l49E0:
	ld h, HIGH(wTrkCh2)
.l49E2:
	ld l, TRK_ID
	ld a, [hl]
	cp $00
	ret z
	push hl
	call B13_WriteDuty
	pop hl
	jp .l49F7
.l49F0:
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
.l49F7:
	push hl
	call B13_GetPanBits
	pop hl
	ld b, a
	call B13_IsBlocked
	ld a, b
	jp c, .l4A0A
	or c
	ld [wNR51], a
	ldh [rNR51], a
.l4A0A:
	ld l, TRK_PERIOD
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld b, [hl]
	jp B13_WritePeriodBC

B13_ReadCmdsLow:
	ld l, TRK_FLAGS2
	bit 5, [hl]
	jp nz, B13_RawReader
	ld a, [de]
	cp $E0
	jp z, B13_Cmd_Voice
	and $F0
	cp $E0
	jp c, B13_Note
	cp $F0
	jp z, B13_Cmd_Atten
	ld a, [de]
	cp $E7
	jp c, B13_Cmd_Octave
	inc de
	sub $E7
	push hl
	call B13_JumpTableInline
	dw B13_Cmd_LenUnit
	dw B13_Cmd_Release
	dw B13_Cmd_Sweep
	dw B13_Cmd_Ext
	dw B13_Cmd_Vibrato
	dw B13_Cmd_EC
	dw B13_Cmd_DutyStep
	dw B13_Cmd_Tempo
	dw B13_Cmd_Pan

B13_Cmd_LenUnit:
	pop hl
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Cmd_Release:
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
	jp B13_ReadCmdsNext

B13_Cmd_Sweep:
	pop hl
	ld a, [de]
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B13_WriteReg
	jp B13_ReadCmdsNext

B13_Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	call B13_JumpTableInline
	dw B13_Ext_TransposeUp
	dw B13_Ext_TransposeDown
	dw B13_Ext_Nop
	dw B13_Ext_Duty
	dw B13_Ext_Autopan

B13_Ext_TransposeUp:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Ext_TransposeDown:
	pop hl
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Ext_Nop:
	pop hl
	jp B13_ReadCmdsNext

B13_Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VOICEDUTY
	ld [hl], a
	ld l, TRK_DUTY
	ld [hl], a
	call B13_WriteDuty
	jp B13_ReadCmdsNext

B13_Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld a, [hl]
	jr z, .l4AC4
	or $02
	jr .l4AC6
.l4AC4:
	and $FD
.l4AC6:
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Cmd_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	jr nz, .l4ADE
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 2, [hl]
	jp B13_ReadCmdsNext
.l4ADE:
	ld l, TRK_FLAGS
	set 2, [hl]
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAYUNITS
	ld [hl], a
	jr z, .l4AF6
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l4AF2:
	add a, c
	dec b
	jr nz, .l4AF2
.l4AF6:
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
	ld hl, B13_VibratoTable
	call B13_LoadPtrIndexed
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
	jp B13_ReadCmdsNext

B13_Cmd_EC:
	pop hl
	jp B13_ReadCmdsNext

B13_Cmd_DutyStep:
	pop hl
	ld a, [de]
	and $F0
	jr nz, .l4B35
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_FLAGS
	res 4, [hl]
	jp B13_ReadCmdsNext
.l4B35:
	ld l, TRK_FLAGS
	set 4, [hl]
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYRELOAD
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_DUTYSTEP
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	ld [wTempoAcc], a
	jp B13_ReadCmdsNext

B13_Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $06
	jr nz, .l4B63
	inc de
	jp B13_ReadCmdsNext
.l4B63:
	ld a, [de]
	ld l, TRK_PAN
	ld [hl], a
	call B13_GetPanBits
	ld b, a
	call B13_IsBlocked
	ld a, b
	jp c, B13_ReadCmdsNext
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp B13_ReadCmdsNext

B13_GetPanBits:
	ld a, [wTrackIdx]
	push hl
	call B13_JumpTableInline
	dw B13_PanBits11
	dw B13_PanBits22
	dw B13_PanBits88
	dw B13_PanBits11
	dw B13_PanBits22
	dw B13_PanBits44
	dw B13_PanBits88

B13_PanBits22:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $22
	ld c, a
	ld a, [wNR51]
	and $DD
	ret

B13_PanBits44:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $44
	ld c, a
	ld a, [wNR51]
	and $BB
	ret

B13_PanBits88:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $88
	ld c, a
	ld a, [wNR51]
	and $77
	ret

B13_PanBits11:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $11
	ld c, a
	ld a, [wNR51]
	and $EE
	ret

B13_AutoPan:
	ld a, [wTrackIdx]
	cp $02
	ret z
	ld l, TRK_PAN
	ld a, [hl]
	swap a
	ld [hl], a
	call B13_GetPanBits
	ld b, a
	call B13_IsBlocked
	ld a, b
	ret c
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ret

B13_Cmd_Octave:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B13_RawReader
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp B13_ReadCmdsNext

B13_Cmd_Voice:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B13_RawReader
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, B13_ReadCmdsNext
	inc de
	cp $02
	jr z, .l4C30
	ld a, [de]
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_VOICEDUTY
	ld [hl], a
	call B13_WriteDuty
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
	jp B13_ReadCmdsNext
.l4C30:
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
	call B13_WriteReg
	call B13_Trigger
	jp B13_ReadCmdsNext

B13_Cmd_Atten:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B13_RawReader
	ld a, [de]
	and $0F
	ld l, TRK_ATTEN
	ld [hl], a
	ld b, a
	ld a, [wTrackIdx]
	cp $02
	jp nz, B13_ReadCmdsNext
	ret
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
	call B13_WriteReg
	call B13_Trigger
	jp B13_ReadCmdsNext

B13_NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	ld c, a
	ld b, $80
	jp B13_WritePeriodBC

B13_Note:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B13_RawReader
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, B13_AutoPan
	call B13_SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jr z, B13_NoiseNote
	ld a, [de]
	and $0F
	jr nz, .l4CBA
	ld l, TRK_UNIT
	ld a, [hl]
	and $0F
	swap a
	jr .l4CC4
.l4CBA:
	or a
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4CC0:
	add a, c
	dec b
	jr nz, .l4CC0
.l4CC4:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, B13_Rest
	ld l, TRK_FLAGS2
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $06
	jp z, B13_DrumNote
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l4CFB
	ld l, TRK_DUTYRELOAD
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B13_WriteDuty
	jr .l4CFB

; (unreachable)
	ld l, TRK_FLAGS
	res 4, [hl]
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld [hl], a
	call B13_WriteDuty
.l4CFB:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4D08
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4D1A
.l4D08:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l4D10:
	srl c
	jr nc, .l4D15
	add a, d
.l4D15:
	rra
	dec b
	jr nz, .l4D10
	pop de
.l4D1A:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l4D32
	ld b, a
	ld c, $0C
	xor a
.l4D2D:
	add a, c
	dec b
	jr nz, .l4D2D
	ld c, a
.l4D32:
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
	ld hl, B13_PeriodTable
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
	jr z, .l4D64
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAY
	ld [hl], a
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call B13_VibratoStep
.l4D64:
	call B13_WritePeriod
	jp B13_NoteFinish

B13_VibratoTick:
	ld l, TRK_VIBTIMER
	ld a, [hl]
	or a
	jr z, .l4D72
	dec [hl]
	ret
.l4D72:
	call B13_VibratoStep
	jp B13_WritePeriod

B13_VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l4D85
	inc b
.l4D85:
	ld a, [bc]
	cp $FB
	jr z, .l4DCE
	cp $FE
	jr z, .l4DD8
	cp $FF
	jr z, .l4DF6
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l4DA8
	ld l, TRK_FLAGS
	set 3, [hl]
	jr .l4DAC
.l4DA8:
	ld l, TRK_FLAGS
	res 3, [hl]
.l4DAC:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l4DCA
	push bc
	xor a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4DC1:
	add a, c
	dec b
	jp nz, .l4DC1
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l4DCA:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4DCE:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4D85
.l4DD8:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l4DED
	cp $FF
	jr z, .l4DE4
	inc [hl]
.l4DE4:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp B13_VibratoStep
.l4DED:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4D85
.l4DF6:
	ret

B13_NoteFinish:
	call B13_NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B13_WriteReg
	jp B13_Trigger

B13_NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4E46
	ld a, [wTrackIdx]
	cp $03
	jr c, .l4E31
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4E2B
	xor a
.l4E2B:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4E31:
	xor a
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4E40
	xor a
.l4E40:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4E46:
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
	jr c, .l4E6E
	xor a
.l4E6E:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

; (unreachable)
	xor a

B13_WritePeriod:
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
	jr z, .l4E8E
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l4E8E:
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

B13_WritePeriodBC:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegIdx], a
	call B13_WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	jp B13_WriteReg

B13_SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

B13_Rest:
	ld l, TRK_FLAGS2
	ld a, $08
	or [hl]
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B13_WriteReg

B13_DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, B13_DrumMap
	rst $28
	ld a, [hl]
	jp B13_PlayDrumSound

B13_WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4EF1
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp B13_WriteReg
.l4EF1:
	dec a
	push de
	push hl
	ld hl, B13_WaveTable
	call B13_LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l4EFF:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l4EFF
	pop hl
	pop de
	ret

B13_IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4F16
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4F1F
.l4F16:
	cp $04
	jr nz, .l4F21
	ld a, [wTrkSfx2]
	or a
	ret z
.l4F1F:
	scf
	ret
.l4F21:
	or a
	ret

B13_WriteReg:
	call B13_IsBlocked
	ret c
	push de
	call B13_GetRegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4F41
	ld a, [hl]
	cp c
	jr z, .l4F44
.l4F41:
	ld a, c
	ld [hl], a
	ld [de], a
.l4F44:
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B13_Trigger:
	call B13_IsBlocked
	ret c
	push de
	ld a, $04
	ld [wRegIdx], a
	call B13_GetRegAddr
	ld a, [hl]
	or $80
	ld [de], a
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B13_GetRegAddr:
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

B13_GetRegBase:
	ld a, [wTrackIdx]
	push hl
	ld hl, B13_RegBaseTable
	rst $28
	ld a, [hl]
	pop hl
	ret
B13_RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

B13_RawReader:
	ld l, TRK_RELTICK
	xor a
	ld [hl], a
	ld a, [de]
	cp $E1
	jr nz, B13_RawNext
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call B13_WriteDuty
	inc de
	ld a, [de]
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B13_WriteReg
	inc de

B13_RawNext:
	ld a, [de]
	or a
	jp z, B13_RawRest
	ld a, [de]
	cp $E7
	jr c, B13_RawNote
	cp $FB
	jp nc, B13_ReadCmds
	cp $F0
	jr nc, B13_RawNote
	ld a, [de]
	inc de
	sub $E7
	push hl
	call B13_JumpTableInline
	dw B13_RawNoteBack
	dw B13_RawNoteBack
	dw B13_Cmd_Sweep
	dw B13_Cmd_Ext
	dw B13_Cmd_LenUnit
	dw B13_RawNoteBack
	dw B13_RawNoteBack
	dw B13_RawNoteBack
	dw B13_Cmd_Pan

B13_RawNoteBack:
	dec de

B13_RawNote:
	ld l, TRK_PAN
	ld a, [hl]
	call B13_GetPanBits
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
	call B13_WritePeriodBC
	call B13_SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B13_WriteReg
	jp B13_Trigger

B13_RawRest:
	call B13_SavePtr
	dec de
	ld l, TRK_FLAGS2
	set 3, [hl]
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B13_WriteReg

Snd41_Sfx1:
	VOICE 2, $0F, 0, 0, 0
	DUTY_STEP 0, 0
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
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
	SND_END

Snd41_SfxN:
	NVOICE 4, $0F, 0
	NOISE $44
	NOISE $44
	NVOICE $10, 8, 3
	NOISE $55
	SND_END

Snd25_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 4
	VOICE 1, 7, 0, 0, $0F
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 4
	ATTEN 1
	LOOP_END 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 4
	SND_END

Snd13_Sfx1:
	VOICE 2, $0A, 8, 1, $0F
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 2
	ATTEN 7
	NOTE C_, 4
	ATTEN 0
	LOOP_END 2
	DUTY_STEP 0, 1
	PAN $F0
	VOICE 2, $0F, 8, 1, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 4
	ATTEN 0
	VOICE 2, $0A, 8, 1, $0F
	PAN $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE C_, 4
	ATTEN 2
	PAN $FF
	PAN $0F
	ATTEN 6
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE C_, 4
	ATTEN 6
	PAN $FF
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE C_, 4
	SND_END

Snd13_Sfx2:
	VOICE 2, $0A, 4, 1, $0F
	REST 1
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 7
	NOTE C_, 4
	ATTEN 0
	LOOP_END 2
	DUTY_STEP 0, 1
	PAN $0F
	VOICE 2, $0F, 8, 1, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 2
	ATTEN $0A
	NOTE C_, 4
	ATTEN 0
	PAN $F0
	VOICE 2, 8, 8, 1, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 4
	ATTEN 2
	PAN $FF
	PAN $F0
	ATTEN 5
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 4
	ATTEN 5
	PAN $FF
	OCTAVE 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 4
	SND_END

Snd13_SfxN:
	NVOICE 1, $0A, 0
	NOISE $04
	NVOICE 8, 8, 0
	NOISE $22
	NOISE $23
	NOISE $33
	NOISE $34
	NOISE $45
	NOISE $55
	NVOICE $10, 6, 0
	NOISE $45
	NVOICE 2, $0F, 0
	NOISE $02
	NOISE $72
	NOISE $55
	NOISE $02
	NOISE $04
	NVOICE 4, $0E, 0
	NOISE $33
	NVOICE 8, $0D, 0
	NOISE $23
	NOISE $33
	NOISE $44
	NVOICE 8, $0C, 0
	NOISE $44
	NOISE $45
	NVOICE 8, $0A, 0
	NOISE $44
	NOISE $45
	NVOICE 9, 8, 0
	NOISE $44
	NOISE $45
	NVOICE 9, 6, 0
	NOISE $44
	NOISE $45
	NVOICE $0A, 5, 0
	NOISE $44
	NOISE $45
	NVOICE $0A, 4, 0
	NOISE $44
	NOISE $45
	NVOICE $0B, 3, 0
	NOISE $44
	NOISE $45
	NVOICE $0B, 2, 0
	NOISE $44
	NOISE $45
	SND_END

Snd14_Sfx1:
	PAN $F0
	VOICE 2, $0C, 0, 0, $0F
	OCTAVE 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 6
	NOTE F#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 8
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	PAN $FF
	VOICE 2, $0C, 0, 0, $0F
	SND_CALL Snd14_Sfx1_52B3
	db $FF

Snd14_Sfx2:
	PAN $0F
	VOICE 2, $0C, 4, 0, $0F
	OCTAVE 1
	REST 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 6
	NOTE F#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 8
	OCTAVE 5
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	PAN $FF
	VOICE 2, $0C, 4, 0, $0F
Snd14_Sfx1_52B3:
	OCTAVE 6
	NOTE C_HI, 1
	NOTE C_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 0
	ATTEN 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	ATTEN 2
	ATTEN 3
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	ATTEN 4
	ATTEN 5
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 6
	ATTEN 7
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	ATTEN 8
	ATTEN 9
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN $0A
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	LOOP_START
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE A#, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	LOOP_END 2
	SND_END

Snd14_SfxN:
	NVOICE 2, $0F, 0
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $22
	NVOICE 6, $0F, 0
	NOISE $34
	NOISE $55
	NOISE $45
	NOISE $56
	NVOICE $0A, $0E, 0
	NOISE $55
	NVOICE $0A, $0D, 0
	NOISE $55
	NVOICE $0B, $0C, 0
	NOISE $55
	NVOICE $0C, $0B, 0
	NOISE $55
	NVOICE $0D, $0A, 0
	NOISE $55
	NVOICE $0D, 9, 0
	NOISE $55
	NVOICE $0E, 8, 0
	NOISE $55
	NVOICE $0E, 7, 0
	NOISE $55
	NVOICE $0F, 6, 0
	NOISE $55
	NVOICE $0F, 5, 0
	NOISE $55
	NVOICE $10, 4, 0
	NOISE $55
	NVOICE $10, 3, 0
	NOISE $55
	NVOICE $10, 2, 0
	NOISE $55
	SND_END

Snd15_Sfx1:
	VOICE 1, 8, 0, 1, $0F
	ATTEN 8
	OCTAVE 6
	NOTE C_HI, 1
	NOTE B_, 1
	ATTEN 7
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 3
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 0
	VOICE 2, $0C, 8, 1, $0F
	OCTAVE 6
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 4
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 6
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 8
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	SND_END

Snd15_Sfx2:
	PAN $0F
	VOICE 1, 8, 4, 1, $0F
	ATTEN 8
	OCTAVE 6
	NOTE C_HI, 1
	NOTE B_, 1
	ATTEN 7
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 3
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 0
	PAN $F0
	VOICE 2, $0C, 8, 1, $0F
	OCTAVE 6
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 4
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 6
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	ATTEN 8
	NOTE C_, 2
	NOTE C_HI, 4
	ATTEN $0A
	NOTE C_HI, 4
	SND_END

Snd15_SfxN:
	NVOICE 2, 3, 0
	NOISE $22
	NVOICE 3, 4, 0
	NOISE $22
	NVOICE 4, 5, 0
	NOISE $22
	NVOICE 5, 6, 0
	NOISE $23
	NVOICE 8, 6, 4
	NOISE $33

Snd16_Sfx1:
	SND_END

Snd19_Sfx1:
	PAN $F0
	VOICE 1, $0F, 4, 0, 0
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
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
	NOTE G_, 1
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
	PAN $0F
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
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
	NOTE G_, 1
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
	SND_END

Snd19_Sfx2:
	VOICE 1, $0F, 4, 0, 0
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
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
	NOTE G_, 1
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
	SND_END

Snd19_SfxN:
	NVOICE 2, $0F, 0
	NOISE $02
	NOISE $72
	NVOICE 8, $0F, 0
	LOOP_START
	NOISE $35
	NOISE $45
	LOOP_END 3
	NVOICE 8, $0D, 0
	LOOP_START
	NOISE $34
	NOISE $45
	LOOP_END 3
	NVOICE $10, 8, 0
	NOISE $45
	NVOICE $10, 6, 0
	NOISE $45
	NVOICE $10, 3, 0
	NOISE $45
	NVOICE 4, 3, 0
	NOISE $13
	NVOICE 4, 4, 0
	NOISE $13
	NVOICE 4, 5, 0
	NOISE $13
	NVOICE 4, 6, 0
	NOISE $13
	NVOICE 4, 7, 0
	NOISE $13
	NVOICE 4, 8, 0
	NOISE $13
	NVOICE 4, 9, 0
	NOISE $13
	NVOICE 4, $0A, 0
	NOISE $13
	NVOICE 4, $0B, 0
	NOISE $13
	NVOICE 4, $0C, 0
	NOISE $13
	NVOICE 2, $0F, 0
	NOISE $02
	NVOICE 6, $0D, 0
	NOISE $34
	NVOICE 8, $0B, 0
	NOISE $34
	NVOICE $0C, 9, 0
	NOISE $34
	NVOICE $10, 7, 0
	NOISE $34
	NVOICE $10, 5, 0
	NOISE $34
	NVOICE $14, 3, 0
	NOISE $34
	NVOICE $18, 2, 0
	NOISE $34
	SND_END

Snd31_Sfx2:
	VOICE 3, $0C, 0, 0, $0F
	LOOP_START
	OCTAVE 5
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	ATTEN 9
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	ATTEN 0
	LOOP_END 2
	ATTEN 9
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	ATTEN 0
	SND_END

Snd31_Sfx1:
	VOICE 3, $0C, 0, 0, $0F
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	ATTEN 9
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	ATTEN 0
	LOOP_END 2
	ATTEN 9
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C_HI, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE B_, 1
	ATTEN 0
	SND_END

Snd4E_Sfx1:
	TRANSPOSE_UP 4
	VOICE 2, $0D, 8, 0, $0F
	ATTEN 9
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 9
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_END

Snd50_Sfx1:
	VOICE 1, $0F, 4, 0, $0F
	OCTAVE 5
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 6
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 9
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_END

Snd50_SfxN:
	NVOICE 1, 6, 0
	NOISE $02
	NOISE $04
	NOISE $23
	NVOICE $10, $0D, 2
	NOISE $33
	NVOICE $20, $0C, 2
	NOISE $34
	SND_END

Snd4F_Sfx1:
	VOICE 1, $0F, 4, 0, $0F
	OCTAVE 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_HI, 1
	LOOP_START
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	LOOP_END 3
	VOICE 1, 6, 4, 0, $0F
	LOOP_START
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	LOOP_END 2
	SND_END

Snd4F_SfxN:
	NVOICE 1, $0F, 1
	NOISE $02
	NVOICE 4, $0C, 0
	NOISE $22
	NVOICE 6, 8, 0
	NOISE $34
	NVOICE $20, 6, 3
	NOISE $44
	SND_END

Snd51_Ch1:
	VOICE 2, $0C, 8, 0, $0F
Snd51_Ch1_55D8:
	ATTEN 8
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 6
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	LEN_UNIT 2
	ATTEN 4
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 2
	LEN_UNIT 2
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	ATTEN 0
	LEN_UNIT 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE A_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE A#, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE A#, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE A#, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE A#, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE A_, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE E_, 1
	ATTEN 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE C#, 1
	ATTEN 2
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	ATTEN 3
	LEN_UNIT 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	LEN_UNIT 2
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 5
	LEN_UNIT 3
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 6
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 8
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
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
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
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
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	SND_END

Snd51_Ch2:
	VOICE 1, $0B, 4, 0, $0F
	REST 4
	SND_CALL Snd51_Ch1_55D8

Snd51_SfxN:
	NVOICE 8, $0A, 0
	NOISE $33
	NVOICE $0C, 8, 0
	NOISE $33
	NVOICE $0C, 7, 0
	NOISE $33
	NVOICE $0C, 6, 0
	NOISE $33
	NVOICE $0C, 5, 0
	NOISE $33
	NVOICE $0C, 4, 0
	NOISE $33
	NVOICE $0C, 3, 0
	NOISE $33
	NVOICE $10, 2, 0
	NOISE $33
	SND_END

Snd52_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 6
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	LOOP_START
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END $10
	ATTEN 3
	LOOP_START
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END $0C
	ATTEN 6
	LOOP_START
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END $0C
	ATTEN 9
	LOOP_START
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END $0C
	SND_END

Snd52_SfxN:
	NVOICE 3, $0F, 0
	LOOP_START
	NOISE $29
	NOISE $1A
	LOOP_END 3
	NVOICE 3, $0D, 0
	LOOP_START
	NOISE $29
	NOISE $1A
	LOOP_END 8
	NVOICE 3, $0B, 0
	LOOP_START
	NOISE $29
	NOISE $1A
	LOOP_END 4
	NVOICE 3, 6, 0
	LOOP_START
	NOISE $29
	NOISE $1A
	LOOP_END 6
	SND_END

Snd53_Sfx1:
	VOICE 2, $0B, 4, 0, $0F
	REST 1
	SND_CALL Snd53_Sfx1_5871

Snd53_Sfx2:
	VOICE 2, $0B, 8, 0, $0F
Snd53_Sfx1_5871:
	ATTEN 4
	LOOP_START
	OCTAVE 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C_, 1
	LOOP_END 1
	ATTEN 0
	OCTAVE 2
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	ATTEN 8
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	ATTEN 6
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 4
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	ATTEN 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	ATTEN 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	ATTEN 6
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	SND_END

Snd53_SfxN:
	NVOICE 2, $0F, 1
	LOOP_START
	NOISE $02
	NOISE $33
	LOOP_END 5
	NVOICE 8, $0C, 2
	NOISE $23
	NOISE $34
	NVOICE 8, $0A, 0
	NOISE $45
	NOISE $44
	NVOICE 8, 9, 0
	NOISE $45
	NOISE $44
	NVOICE 8, 7, 0
	NOISE $45
	NOISE $44
	NVOICE 8, 4, 0
	NOISE $45
	NOISE $44
	SND_END

Snd48_Sfx1:
	VOICE 2, $0D, 0, 0, $0F
	OCTAVE 1
	LOOP_START
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END 8
	SND_END

Snd48_SfxN:
	NVOICE 3, $0F, 0
	NOISE $55
	NOISE $72
	NOISE $35
	NOISE $55
	NOISE $75
	NVOICE 3, $0F, 0
	NOISE $03
	NOISE $35
	NOISE $45
	NOISE $55
	NOISE $75
	NVOICE 3, $0D, 0
	NOISE $02
	NOISE $24
	NOISE $44
	NOISE $55
	NOISE $56
	LOOP_START
	NVOICE 3, $0E, 0
	NOISE $03
	NOISE $34
	NOISE $55
	NOISE $62
	NOISE $55
	LOOP_END 4
	NVOICE 4, $0D, 0
	NOISE $02
	NOISE $34
	NOISE $44
	NOISE $45
	NVOICE 8, $0B, 0
	NOISE $13
	NOISE $44
	NOISE $45
	NOISE $55
	NVOICE 8, 8, 0
	NOISE $55
	NOISE $55
	NOISE $56
	NOISE $56
	NVOICE $10, 6, 0
	NOISE $56
	SND_END

Snd49_Sfx1:
	VOICE 2, $0D, 8, 1, $0F
	OCTAVE 3
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	DUTY 0
	TRANSPOSE_UP 8
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	VOICE 2, 7, 0, 1, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_END

Snd49_SfxN:
	NVOICE 2, $0C, 9
	NOISE $03
	NOISE $13
	NOISE $45
	NOISE $44
	NOISE $45
	NOISE $44
	NVOICE $21, $0A, 1
	NOISE $44
	SND_END

Snd4A_Ch1:
	VOICE 4, $0A, 4, 0, $0F
	REST 4
	SND_CALL Snd4A_Ch1_5A35
	VOICE 4, $0A, 4, 0, 0
	VIBRATO 3, 0, 1
	OCTAVE 5
	ATTEN 9
	NOTE C_HI, 0
	ATTEN 8
	NOTE C_HI, $0B
	ATTEN 7
	NOTE C_HI, $0A
	ATTEN 6
	NOTE C_HI, $0A
	ATTEN 5
	NOTE C_HI, 9
	ATTEN 4
	NOTE C_HI, 8
	ATTEN 3
	NOTE C_HI, 8
	ATTEN 2
	NOTE C_HI, 8
	ATTEN 1
	NOTE C_HI, 8
	ATTEN 0
	NOTE C_HI, 8
	ATTEN 1
	NOTE C_HI, 8
	ATTEN 2
	NOTE C_HI, 8
	VIBRATO_OFF $00
	VOICE 2, 8, 4, 0, $0F
	SND_CALL Snd4A_Ch1_5A83
	VOICE 4, 4, 4, 0, $0F
	ATTEN 0
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 3
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd4A_Ch2:
	VOICE 4, $0A, 0, 0, $0F
	SND_CALL Snd4A_Ch1_5A35
	VOICE 4, $0A, 0, 0, 0
	OCTAVE 5
	ATTEN 9
	NOTE C_HI, 0
	ATTEN 8
	NOTE C_HI, $0B
	ATTEN 7
	NOTE C_HI, $0A
	ATTEN 6
	NOTE C_HI, $0A
	ATTEN 5
	NOTE C_HI, 9
	ATTEN 4
	NOTE C_HI, 8
	ATTEN 3
	NOTE C_HI, 8
	ATTEN 2
	NOTE C_HI, 8
	ATTEN 1
	NOTE C_HI, 8
	ATTEN 0
	NOTE C_HI, 8
	ATTEN 1
	NOTE C_HI, 8
	ATTEN 2
	NOTE C_HI, 8
	VOICE 2, 8, 0, 0, $0F
	SND_CALL Snd4A_Ch1_5A83
	VOICE 4, 3, 0, 0, $0F
	ATTEN 0
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END
Snd4A_Ch1_5A35:
	OCTAVE 3
	REST 0
	REST 0
	REST 0
	REST 0
	VOICE 1, $0A, 0, 0, $0F
	ATTEN 7
	NOTE C_HI, 1
	NOTE B_, 1
	ATTEN 6
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 5
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 5
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	OCTAVE 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET
Snd4A_Ch1_5A83:
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LEN_UNIT 3
	ATTEN 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 3
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LEN_UNIT 4
	ATTEN 4
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
	LEN_UNIT 5
	ATTEN 6
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
	SND_RET

Snd4A_SfxN:
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $60, $0C, 5
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $5A, $0B, 4
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $38, $0C, 3
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $4A, $0C, 3
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $68, $0C, 5
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $4A, $0B, 3
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE $78, $0D, 4
	NOISE $02
	NVOICE 2, $0F, 0
	NOISE $72
	LOOP_START
	NVOICE $20, 4, 7
	NOISE $03
	LOOP_END $20
	SND_END
	db $FF

Snd4D_Sfx1:
	VOICE 1, $0E, 0, 4, $0F
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 8
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 7
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 6
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 5
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 4
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN $0A
	LOOP_START
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	LOOP_END 5
	ATTEN 0
	VOICE 1, 2, 0, 4, $0F
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd4D_SfxN:
	NVOICE 2, $0F, 0
	LOOP_START
	NOISE $49
	NOISE $32
	LOOP_END 7
	NVOICE 2, 8, 2
	LOOP_START
	NOISE $49
	NOISE $32
	LOOP_END 5
	NVOICE 2, 4, 0
	LOOP_START
	NOISE $49
	NOISE $32
	LOOP_END 3
	NVOICE 2, 2, 0
	LOOP_START
	NOISE $49
	NOISE $32
	LOOP_END 3
	SND_END

Snd44_Sfx1:
	VOICE 1, 8, $0C, 0, $0F
	TRANSPOSE_DOWN 4
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G#, 1
	LOOP_START
	NOTE E_, 1
	NOTE G_, 1
	LOOP_END 6
	LOOP_START
	NOTE D#, 1
	NOTE F#, 1
	LOOP_END 8
	LOOP_START
	NOTE D_, 1
	NOTE F_, 1
	LOOP_END $0A
	LOOP_START
	NOTE C#, 1
	NOTE E_, 1
	LOOP_END $0C
	LOOP_START
	NOTE C_, 1
	NOTE D#, 1
	LOOP_END $0C
	ATTEN 3
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END $10
	ATTEN 4
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	LOOP_END $10
	SND_END

Snd45_Sfx1:
	VOICE 1, 8, $0C, 0, $0F
	TRANSPOSE_DOWN 2
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F#, 1
	SND_END

Snd46_Sfx1:
	VOICE 1, 7, $0C, 0, $0F
	TRANSPOSE_DOWN 2
	OCTAVE 4
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	SND_END

Snd47_Sfx1:
	VOICE 1, 6, $0C, 0, $0F
	TRANSPOSE_UP 3
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1

Snd42_SfxN:
	SND_END

Snd43_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 6
	NOTE G_, 1
	LOOP_START
	ATTEN 2
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C#, 1
	LOOP_END 2
	LOOP_START
	ATTEN 2
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 2
	ATTEN 3
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 4
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 5
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd43_SfxN:
	NVOICE 3, $0A, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	NVOICE 3, 4, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $3A
	SND_END

Snd29_Sfx1:
	VOICE 1, 6, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 3
	NOTE D#, 8
	ATTEN 0
	VOICE 1, 7, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 4
	NOTE D#, 8
	ATTEN 0
	VOICE 1, 8, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 4
	NOTE D#, 8
	ATTEN 0
	VOICE 1, 9, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 5
	NOTE D#, 8
	ATTEN 0
	LOOP_START
	VOICE 1, $0A, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 6
	NOTE D#, 8
	ATTEN 0
	LOOP_END 3
	LOOP_START
	VOICE 1, $0B, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 7
	NOTE D#, 8
	ATTEN 0
	LOOP_END 5
	LOOP_START
	VOICE 1, $0C, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 7
	NOTE D#, 8
	ATTEN 0
	LOOP_END 4
	LOOP_START
	VOICE 1, $0D, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 7
	NOTE D#, 8
	ATTEN 0
	LOOP_END 3
	LOOP_START
	VOICE 1, $0A, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 7
	NOTE D#, 8
	ATTEN 0
	LOOP_END 2
	LOOP_START
	VOICE 1, 8, 8, 0, $0F
	SND_CALL Snd29_Sfx1_5D3C
	ATTEN 7
	NOTE D#, 8
	ATTEN 0
	LOOP_END 4
	SND_END
Snd29_Sfx1_5D3C:
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 8
	SND_RET

Snd29_SfxN:
	LOOP_START
	NVOICE 1, 2, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	NOISE $4A
	LOOP_END 4
	LOOP_START
	NVOICE 1, 3, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 5
	LOOP_START
	NVOICE 1, 4, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 5
	LOOP_START
	NVOICE 1, 5, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 5
	LOOP_START
	NVOICE 1, 6, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 5
	LOOP_START
	NVOICE 1, 7, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 6
	LOOP_START
	NVOICE 1, 8, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 6
	LOOP_START
	NVOICE 1, 9, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 7
	LOOP_START
	NVOICE 1, $0A, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 8
	LOOP_START
	NVOICE 1, $0B, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 9
	LOOP_START
	NVOICE 1, 8, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 8
	LOOP_START
	NVOICE 1, 4, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 8
	LOOP_START
	NVOICE 1, 3, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END 8
	LOOP_START
	NVOICE 1, 2, 0
	NOISE $49
	NOISE $5A
	NOISE $39
	LOOP_END $10
	SND_END

Snd2A_Sfx1:
	VOICE 2, $0F, 8, 0, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	VOICE 4, $0C, 8, 0, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd2A_Sfx2:
	VOICE $0F, 0, 8, 0, $0F
	OCTAVE 6
	REST 2
	VOICE 2, 0, 8, 0, $0F
	REST 0
	VOICE 3, 6, 8, 0, $0F
	TRANSPOSE_UP 4
	OCTAVE 6
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	TRANSPOSE_UP 3
	OCTAVE 6
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	TRANSPOSE_UP 2
	OCTAVE 6
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	TRANSPOSE_UP 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	TRANSPOSE_UP 0
	OCTAVE 6
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 5
	NOTE B_, 1
	ATTEN 3
	OCTAVE 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 5
	NOTE A#, 1
	ATTEN 3
	OCTAVE 6
	NOTE A#, 1
	ATTEN 0
	OCTAVE 5
	NOTE A_, 1
	ATTEN 3
	OCTAVE 6
	NOTE A_, 1
	ATTEN 0
	OCTAVE 5
	NOTE G#, 1
	ATTEN 3
	OCTAVE 6
	NOTE G#, 1
	ATTEN 0
	OCTAVE 5
	NOTE G_, 1
	ATTEN 3
	OCTAVE 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 5
	NOTE F#, 1
	ATTEN 3
	OCTAVE 6
	NOTE F#, 1
	ATTEN 0
	OCTAVE 5
	NOTE F_, 1
	ATTEN 3
	OCTAVE 6
	NOTE F_, 1
	ATTEN 0
	OCTAVE 5
	NOTE E_, 1
	ATTEN 3
	OCTAVE 6
	NOTE E_, 1
	ATTEN 0
	OCTAVE 5
	NOTE D#, 1
	ATTEN 3
	OCTAVE 6
	NOTE D#, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 3
	OCTAVE 6
	NOTE D_, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	ATTEN 3
	OCTAVE 6
	NOTE C#, 1
	ATTEN 0
	OCTAVE 5
	NOTE C_, 1
	ATTEN 3
	OCTAVE 6
	NOTE C_, 1
	ATTEN 0
	ATTEN 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 4
	OCTAVE 5
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE A#, 1
	ATTEN 4
	OCTAVE 5
	NOTE A#, 1
	ATTEN 1
	OCTAVE 4
	NOTE A_, 1
	ATTEN 4
	OCTAVE 5
	NOTE A_, 1
	ATTEN 2
	OCTAVE 4
	NOTE G#, 1
	ATTEN 5
	OCTAVE 5
	NOTE G#, 1
	ATTEN 2
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	OCTAVE 5
	NOTE G_, 1
	ATTEN 2
	OCTAVE 4
	NOTE F#, 1
	ATTEN 5
	OCTAVE 5
	NOTE F#, 1
	ATTEN 3
	OCTAVE 4
	NOTE F_, 1
	ATTEN 6
	OCTAVE 5
	NOTE F_, 1
	SND_END

Snd2A_SfxN:
	LOOP_START
	NVOICE 1, 5, 0
	NOISE $22
	NOISE $45
	LOOP_END 5
	LOOP_START
	NVOICE 1, 6, 0
	NOISE $22
	NOISE $45
	LOOP_END 6
	LOOP_START
	NVOICE 1, 7, 0
	NOISE $22
	NOISE $45
	LOOP_END 7
	LOOP_START
	NVOICE 1, 8, 0
	NOISE $22
	NOISE $45
	LOOP_END 8
	LOOP_START
	NVOICE 1, 9, 0
	NOISE $22
	NOISE $45
	LOOP_END 9
	LOOP_START
	NVOICE 1, $0A, 0
	NOISE $22
	NOISE $45
	LOOP_END $0A
	LOOP_START
	NVOICE 1, $0B, 0
	NOISE $22
	NOISE $45
	LOOP_END 8
	LOOP_START
	NVOICE 1, $0C, 0
	NOISE $22
	NOISE $45
	LOOP_END 3
	LOOP_START
	NVOICE 1, $0A, 0
	NOISE $22
	NOISE $45
	LOOP_END $0A
	LOOP_START
	NVOICE 1, 8, 0
	NOISE $22
	NOISE $45
	LOOP_END 8
	LOOP_START
	NVOICE 1, 6, 0
	NOISE $22
	NOISE $45
	LOOP_END 8
	LOOP_START
	NVOICE 1, 4, 0
	NOISE $22
	NOISE $45
	LOOP_END 8
	LOOP_START
	NVOICE 1, 2, 0
	NOISE $22
	NOISE $45
	LOOP_END $0A
	SND_END

Snd2B_Sfx1:
	VOICE 2, 6, 8, 0, $0F
	OCTAVE 6
	ATTEN 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	ATTEN 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	VOICE 2, $0F, 8, 0, $0F
	ATTEN 8
	LOOP_START
	NOTE D#, 1
	NOTE G#, 1
	LOOP_END 3
	ATTEN 7
	LOOP_START
	NOTE E_, 1
	NOTE A_, 1
	LOOP_END 3
	ATTEN 6
	LOOP_START
	NOTE F_, 1
	NOTE A#, 1
	LOOP_END 3
	ATTEN 5
	LOOP_START
	NOTE F#, 1
	NOTE B_, 1
	LOOP_END 3
	TRANSPOSE_UP 1
	ATTEN 4
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 2
	ATTEN 3
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 3
	ATTEN 2
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 4
	ATTEN 1
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 0
	ATTEN 0
	VOICE 2, $0F, 8, 0, $0F
	OCTAVE 5
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE B_, 1
	VOICE 1, $0F, 8, 2, 8
	NOTE A#, 0
	ATTEN 4
	NOTE A#, 0
	ATTEN 0
	VOICE 3, 4, 8, 0, $0F
	NOTE A#, 0
	ATTEN 2
	NOTE A#, 0
	VOICE 2, 2, 8, 0, $0F
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd2B_SfxN:
	NVOICE $40, 3, 0
	NOISE $22
	NVOICE $40, 3, 0
	NOISE $22
	NVOICE 3, $0F, 0
	NOISE $03
	NVOICE 4, $0A, 0
	NOISE $22
	NOISE $23
	NOISE $33
	NOISE $34
	NVOICE $10, 4, 0
	NOISE $34
	NVOICE $18, 3, 0
	NOISE $34
	NVOICE $18, 2, 0
	NOISE $34
	SND_END

Snd2B_Sfx2:
	VIBRATO 3, 0, 1
	VOICE 2, 4, 8, 0, $0F
	OCTAVE 6
	ATTEN 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	VOICE 2, $0A, 8, 0, $0F
	ATTEN 5
	LOOP_START
	NOTE D#, 1
	NOTE G#, 1
	LOOP_END 3
	LOOP_START
	NOTE E_, 1
	NOTE A_, 1
	LOOP_END 3
	ATTEN 4
	LOOP_START
	NOTE F_, 1
	NOTE A#, 1
	LOOP_END 3
	LOOP_START
	NOTE F#, 1
	NOTE B_, 1
	LOOP_END 3
	TRANSPOSE_UP 1
	ATTEN 3
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 2
	ATTEN 3
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 3
	ATTEN 2
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 4
	ATTEN 2
	LOOP_START
	NOTE G_, 1
	NOTE C_HI, 1
	LOOP_END 3
	TRANSPOSE_UP 0
	ATTEN 0
	VOICE 2, 4, 8, 0, $0F
	OCTAVE 4
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE F#, 1

Snd2E_Sfx1:
	SND_END

Snd2E_SfxN:
	LOOP_START
	NVOICE 1, 2, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	NOISE $2A
	LOOP_END 3
	LOOP_START
	NVOICE 1, 3, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 4, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 5, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 6, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 7, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 7, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 8, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	LOOP_START
	NVOICE 1, 9, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	LOOP_END 3
	SND_SEGNO
	NVOICE 1, $0A, 0
	NOISE $29
	NOISE $3A
	NOISE $19
	SND_LOOP
	db $03, $FF

Snd2F_Sfx1:
	VOICE 2, $0A, 0, 0, $0F
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 6
	NOTE B_, 0
	ATTEN 7
	NOTE B_, 0
	SND_END

Snd2F_SfxN:
	NVOICE 1, $0F, 0
	NOISE $02
	NOISE $72
	NOISE $23
	NVOICE 8, $0A, 0
	NOISE $03
	NOISE $13
	NOISE $23
	NVOICE $10, 8, 0
	NOISE $23
	NVOICE $40, 7, 3
	NOISE $23
	SND_END

Snd2D_Sfx1:
	VOICE 3, 8, 0, 0, $0F
	OCTAVE 5
	ATTEN 5
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 3
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	ATTEN 3
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE A_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	REST 1
	VOICE 2, $0C, 0, 1, $0F
	OCTAVE 6
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 6
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 8
	ATTEN 7
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 8
	ATTEN 8
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 8
	REST 7
	REST 0
	ATTEN 2
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 8
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 8
	SND_END

Snd2D_SfxN:
	NVOICE $0A, 2, 0
	NOISE $29
	NOISE $29
	NVOICE $0A, 3, 0
	NOISE $29
	NOISE $29
	NVOICE $0A, 4, 0
	NOISE $29
	NOISE $29
	NVOICE $0A, 5, 0
	NOISE $29
	NOISE $29
	NVOICE $0A, 6, 0
	NOISE $29
	NOISE $2A
	NVOICE $0A, 7, 0
	NOISE $2A
	NOISE $2A
	NVOICE 2, $0F, 0
	NOISE $02
	NVOICE 8, $0C, 0
	NOISE $22
	NOISE $23
	NOISE $33
	NOISE $34
	NOISE $44
	NOISE $45
	NVOICE 8, $0A, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 8, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 6, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 4, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 2, 0
	NOISE $45
	NOISE $55
	NOISE $44
	NOISE $45
	NOISE $55
	NVOICE $10, 2, 0
	NOISE $44
	NOISE $45
	NVOICE 2, $0D, 0
	NOISE $02
	NOISE $04
	NVOICE 8, $0C, 0
	NOISE $12
	NVOICE 8, $0B, 0
	NOISE $22
	NOISE $23
	NVOICE 8, $0A, 0
	NOISE $33
	NVOICE 8, 9, 0
	NOISE $34
	NOISE $44
	NVOICE 8, 8, 0
	NOISE $44
	NVOICE 8, 7, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 6, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 5, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 4, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 3, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 3, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 2, 0
	NOISE $45
	NOISE $55
	SND_END

Snd2C_SfxN:
	SND_SEGNO
	LOOP2_START
	LOOP_START
	NVOICE 1, 4, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 5, 1
	NOISE $3B
	NVOICE 1, 3, 1
	NOISE $09
	NOISE $19
	LOOP_END 9
	LOOP_START
	NVOICE 1, 9, 1
	NOISE $02
	NOISE $39
	NOISE $2A
	NVOICE 1, 4, 1
	NOISE $3B
	NVOICE 1, 5, 1
	NOISE $09
	NOISE $19
	LOOP_END 4
	LOOP_START
	NVOICE 1, 3, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 5, 1
	NOISE $3B
	NVOICE 1, 5, 1
	NOISE $09
	NOISE $19
	LOOP_END $0D
	LOOP_START
	NVOICE 1, 3, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 8, 1
	NOISE $3B
	NOISE $09
	NVOICE 1, 4, 1
	NOISE $09
	NOISE $19
	LOOP_END 4
	LOOP_START
	NVOICE 1, 4, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 6, 1
	NOISE $3B
	NVOICE 1, 6, 1
	NOISE $09
	NOISE $19
	LOOP_END 7
	LOOP_START
	NVOICE 1, 4, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 6, 1
	NOISE $3B
	NVOICE 1, 6, 1
	NOISE $29
	NOISE $19
	NVOICE 1, 3, 1
	NOISE $39
	NOISE $19
	LOOP_END $0E
	LOOP2_END 2
	LOOP_START
	NVOICE 1, 8, 1
	NOISE $29
	NOISE $1A
	NVOICE 1, 6, 1
	NOISE $3B
	NVOICE 1, 2, 1
	NOISE $09
	NOISE $19
	LOOP_END 5
	LOOP_START
	NVOICE 1, 6, 1
	NOISE $2A
	NOISE $3A
	NVOICE 1, 4, 1
	NOISE $3B
	NVOICE 1, 7, 1
	NOISE $29
	NVOICE 1, 6, 1
	NOISE $09
	NOISE $19
	LOOP_END 8
	LOOP_START
	NVOICE 1, 4, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, 6, 1
	NOISE $3B
	NVOICE 1, $0A, 1
	NOISE $09
	NOISE $19
	LOOP_END 8
	LOOP_START
	NVOICE 1, 4, 1
	NOISE $39
	NOISE $2A
	NVOICE 1, $0B, 1
	NOISE $3B
	NOISE $09
	NVOICE 1, 6, 1
	NOISE $0B
	NOISE $2A
	NVOICE 1, 3, 1
	NOISE $49
	NOISE $19
	NVOICE 1, $0B, 1
	NOISE $2B
	NOISE $1A
	LOOP_END 3
	SND_LOOP

Snd30_Sfx2:
	TRANSPOSE_DOWN 8
	VOICE 3, 8, 4, 0, $0F
	SND_CALL Snd30_Sfx1_626C
	ATTEN 5
	NOTE C_HI, 0
	ATTEN 6
	NOTE C_HI, 0
	LEN_UNIT 3
	ATTEN 0
	SND_END

Snd30_Sfx1:
	TRANSPOSE_DOWN 8
	VOICE 3, 5, 4, 0, $0F
	REST 3
	VIBRATO 1, 0, 7
	SND_CALL Snd30_Sfx1_626C
	NOTE C_HI, 0
	NOTE C_HI, 0
	LEN_UNIT 3
	ATTEN 0
	SND_END
Snd30_Sfx1_626C:
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	LEN_UNIT 2
	NOTE C_HI, 0
	NOTE C_HI, 0
	ATTEN 1
	NOTE C_HI, 0
	ATTEN 2
	NOTE C_HI, 0
	ATTEN 3
	NOTE C_HI, 0
	ATTEN 4
	NOTE C_HI, 0
	SND_RET

Snd32_SfxN:
	NVOICE 2, $0A, 0
	NOISE $02
	NOISE $72
	NOISE $34
	NOISE $03
	NVOICE $90, 3, 0
	NOISE $33
	NVOICE $80, 3, 0
	NOISE $33
	NVOICE 2, $0F, 0
	NOISE $01
	NOISE $02
	NOISE $03
	NOISE $12
	NOISE $22
	NOISE $23
	NVOICE 2, $0F, 0
	NOISE $72
	NVOICE 2, $0E, 0
	NOISE $01
	NOISE $72
	NVOICE 2, $0D, 0
	NOISE $02
	NOISE $52
	NVOICE 2, $0C, 0
	NOISE $12
	NOISE $23
	NVOICE 3, $0B, 0
	NOISE $23
	NOISE $33
	NVOICE 4, $0A, 0
	NOISE $33
	NOISE $34
	NVOICE 5, 8, 0
	NOISE $34
	NOISE $35
	NVOICE 6, 6, 0
	NOISE $44
	NOISE $44
	NVOICE 7, 5, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 4, 0
	NOISE $45
	NOISE $55
	NVOICE 8, 3, 0
	NOISE $55
	NOISE $56
	NVOICE 8, 2, 0
	NOISE $55
	NOISE $56
	NVOICE 8, 1, 0
	NOISE $44
	NOISE $45
	NOISE $45
	NOISE $55
	NOISE $43
	NOISE $45
	NOISE $55
	NOISE $55
	NOISE $56
	NOISE $45
	NOISE $45
	SND_END
Snd33_SfxN_62EA:
	NVOICE 2, $0F, 0
	NOISE $01
	NOISE $02
	NOISE $03
	NOISE $12
	NOISE $22
	NOISE $23
	NOISE $72
	NOISE $55
	NOISE $33
	NVOICE 2, $0E, 0
	NOISE $01
	NOISE $72
	NOISE $02
	NOISE $52
	NOISE $33
	NVOICE 2, $0D, 0
	NOISE $12
	NOISE $23
	NOISE $12
	NVOICE 3, $0D, 0
	NOISE $23
	NOISE $33
	NOISE $23
	NVOICE 3, $0C, 0
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $34
	NOISE $35
	NOISE $44
	NVOICE 4, $0B, 0
	NOISE $44
	NOISE $45
	NOISE $44
	NVOICE 4, $0A, 0
	NOISE $44
	NOISE $45
	NOISE $45
	NVOICE 8, 9, 0
	NOISE $45
	NOISE $55
	NOISE $56
	NVOICE 8, 8, 0
	NOISE $55
	NOISE $56
	NOISE $55
	NVOICE 8, 7, 0
	NOISE $55
	NOISE $56
	NOISE $55
	NVOICE 8, 4, 0
	NOISE $56
	NOISE $55
	NOISE $56
	SND_END

Snd32_Ch3:
	VOICE 3, 2, 8, 4, 1
	OCTAVE 4
	NOTE C_, 1
	VOICE 8, 4, 8, 4, 1
	OCTAVE 3
	VIBRATO 6, 0, 3
	NOTE D#, 1
	NOTE E_, 1
	VOICE 8, 4, 8, 4, 1
	VIBRATO 11, 0, 2
	NOTE F_, 0
	SND_END

Snd33_SfxN:
	LOOP_START
	NVOICE 1, $0F, 0
	NOISE $72
	NOISE $35
	NVOICE 1, $0D, 0
	NOISE $23
	NOISE $34
	NVOICE 1, $0C, 0
	NOISE $24
	NOISE $35
	NVOICE 1, $0B, 0
	NOISE $23
	NOISE $34
	NVOICE 1, 8, 0
	NOISE $24
	NOISE $35
	NVOICE 1, 6, 0
	NOISE $23
	NOISE $34
	LOOP_END $18
	SND_CALL Snd33_SfxN_62EA

Snd34_SfxN:
	LOOP_START
	NVOICE 1, $0F, 0
	NOISE $72
	NOISE $35
	NVOICE 1, $0D, 0
	NOISE $23
	NOISE $34
	NVOICE 1, $0C, 0
	NOISE $24
	NOISE $35
	NVOICE 1, $0B, 0
	NOISE $23
	NOISE $34
	NVOICE 1, 8, 0
	NOISE $24
	NOISE $35
	NVOICE 1, 6, 0
	NOISE $23
	NOISE $34
	LOOP_END 9
	SND_CALL Snd33_SfxN_62EA

Snd12_Sfx1:
	VOICE 1, 5, 4, $0A, $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	VOICE $20, 4, 4, 0, 8
	NOTE F#, 7
	VOICE 2, 7, 0, 4, $0F
	OCTAVE 4
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
	VOICE 8, 4, 4, 0, 8
	REST 4
	VOICE 9, $0F, 8, 0, $0F
	REST $0C
	VOICE 9, $0A, 0, 0, $0F
	ATTEN 8
	NOTE C_HI, 1
	ATTEN 6
	NOTE C_HI, 1
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 0
	NOTE C_HI, 1
	VOICE 1, $0A, 0, 0, $0F
	OCTAVE 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 5
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	VOICE 2, 5, 4, 0, $0F
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE F#, 1
	VOICE 1, 4, 4, 0, $0F
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 9
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 3
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 6
	NOTE C#, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 6
	NOTE D#, 1
	ATTEN 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	ATTEN 2
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_END

Snd12_Sfx2:
	VOICE 1, 5, 4, $0C, $0C
	REST 3
	VIBRATO 3, 0, 3
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	VOICE $20, 3, 4, 0, $0F
	VIBRATO 4, 0, 6
	NOTE F#, 3
	NOTE F#, 2
	NOTE F#, 2
	VIBRATO_OFF $00
	VOICE 2, 3, 4, 4, $0F
	OCTAVE 5
	LOOP_START
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 3
	REST $0D
	VOICE 8, 4, 4, 0, 8
	REST 4
	VOICE 9, $0F, 8, 0, $0F
	REST $0C
	VOICE 9, $0A, 0, 0, $0F
	ATTEN 8
	NOTE C_HI, 1
	ATTEN 6
	NOTE C_HI, 1
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 0
	NOTE C_HI, 1
	VOICE 1, $0A, 0, 0, $0F
	OCTAVE 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 5
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	VOICE 2, 3, 4, 0, $0F
	VIBRATO 3, 0, 7
	OCTAVE 3
	REST 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE F#, 1
	SND_END

Snd12_SfxN:
	NVOICE $80, 0, 0
	NOISE $01
	NVOICE $60, 0, 0
	NOISE $01
	NVOICE 2, $0F, 0
	NOISE $02
	NVOICE 4, 7, 0
	NOISE $03
	NVOICE 4, 7, 0
	NOISE $04
	NVOICE 8, 6, 0
	NOISE $14
	NVOICE $10, 5, 0
	NOISE $24
	NVOICE $10, 4, 0
	NOISE $04
	NVOICE $10, 3, 0
	NOISE $04
	NVOICE $10, 2, 0
	NOISE $04
	NVOICE $20, 1, 0
	NOISE $04
	NVOICE $4E, 0, 0
	NOISE $23
	NVOICE 7, 2, 0
	NOISE $15
	NVOICE 6, 3, 0
	NOISE $15
	NVOICE 7, 4, 0
	NOISE $15
	NVOICE 6, 5, 0
	NOISE $15
	NVOICE 7, 6, 0
	NOISE $15
	NVOICE 6, 7, 0
	NOISE $15
	NVOICE 7, 8, 0
	NOISE $15
	NVOICE 7, 9, 0
	NOISE $15
	NVOICE 2, $0F, 0
	NOISE $72
	NOISE $01
	NOISE $11
	NOISE $12
	NVOICE 2, $0E, 0
	NOISE $21
	NOISE $22
	NOISE $22
	NOISE $23
	NVOICE 2, $0D, 0
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $44
	NVOICE 4, $0C, 0
	NOISE $34
	NOISE $44
	NVOICE 4, $0B, 0
	NOISE $45
	NOISE $55
	NVOICE 4, $0A, 0
	NOISE $54
	NOISE $55
	NVOICE 4, 8, 0
	NOISE $45
	NOISE $55
	NVOICE 5, 6, 0
	NOISE $54
	NVOICE 4, 3, 0
	NOISE $55
	NVOICE 4, 2, 0
	NOISE $56
	NVOICE 8, 1, 0
	NOISE $23
	NVOICE 8, 2, 0
	NOISE $23
	NVOICE 4, 3, 0
	NOISE $23
	NVOICE 4, 5, 0
	NOISE $23
	NVOICE 4, 7, 0
	NOISE $23
	NVOICE 4, 9, 0
	NOISE $23
	NVOICE 4, $0B, 0
	NOISE $23
	NVOICE 4, $0D, 0
	NOISE $23
	NVOICE 4, $0F, 0
	NOISE $02
	NVOICE 5, $0E, 0
	NOISE $14
	NOISE $02
	NVOICE 5, $0E, 0
	NOISE $24
	NOISE $02
	NVOICE $0B, $0D, 0
	NOISE $34
	NVOICE $0B, $0C, 0
	NOISE $44
	NVOICE $0B, $0B, 0
	NOISE $44
	NVOICE $0C, $0A, 0
	NOISE $45
	NVOICE $0C, 9, 0
	NOISE $45
	NVOICE $0C, 8, 0
	NOISE $55
	NVOICE $0D, 7, 0
	NOISE $55
	NVOICE $0D, 6, 0
	NOISE $56
	NVOICE $0D, 5, 0
	NOISE $56
	NVOICE $0D, 4, 0
	NOISE $56
	NVOICE $0D, 3, 0
	NOISE $56
	NVOICE $20, 2, 0
	NOISE $56
	SND_END

Snd11_Sfx1:
	VOICE 4, $0F, 0, 2, $0F
	OCTAVE 1
	NOTE C_, 1
	VOICE 1, 8, 0, 0, $0F
Snd11_Sfx1_6677:
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END $10
	ATTEN 1
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 6
	ATTEN 2
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 6
	NOTE C_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 6
	NOTE C#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 6
	NOTE C#, 1
	LOOP_END 2
	ATTEN 3
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 6
	NOTE C#, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 6
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 6
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 6
	NOTE D_, 1
	LOOP_END 2
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE F_, 1
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_END

Snd11_Sfx2:
	VOICE 2, $0F, 0, 3, $0F
	OCTAVE 1
	NOTE C#, 4
	VOICE 1, 8, 0, 0, $0F
	REST 2
	SND_CALL Snd11_Sfx1_6677
	db $FF

Snd18_Sfx1:
	VOICE 2, $0C, 0, 0, $0F
	OCTAVE 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	ATTEN 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE C_, 1
	DUTY 4
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE C_, 4
	ATTEN 8
	LOOP_END 2
	VOICE 2, 4, 0, 0, $0F
	OCTAVE 1
	ATTEN 0
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D_, 4
	SND_END

Snd18_Sfx2:
	SND_END

Snd18_SfxN:
	NVOICE 4, $0A, 0
	NOISE $31
	NOISE $22
	NVOICE 7, $0A, 0
	NOISE $72
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE 4, $0C, 0
	NOISE $21
	NOISE $02
	NOISE $72
	NOISE $55
	NOISE $55
	NOISE $55
	NOISE $21
	NOISE $02
	NOISE $72
	NOISE $55
	NOISE $44
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE $10, $0A, 0
	NOISE $44
	NVOICE $10, 8, 0
	NOISE $45
	NVOICE $10, 6, 0
	NOISE $55
	NVOICE $10, 4, 0
	NOISE $56
	NVOICE $20, 4, 6
	NOISE $56
	SND_END

Snd17_Sfx1:
	PAN $F0
	VOICE 2, $0F, 0, 0, $0F
	REST 1
	OCTAVE 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $0F
	REST 8
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $F0
	REST 5
	ATTEN 5
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $0F
	REST 8
	ATTEN 6
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $FF
	REST $0A
	ATTEN $0A
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd17_Sfx2:
	PAN $0F
	VOICE 2, $0F, 4, 0, $0F
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $F0
	REST 9
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $0F
	REST 6
	ATTEN 5
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $F0
	REST $0A
	ATTEN 6
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	PAN $FF
	REST $0A
	ATTEN $0A
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd17_SfxN:
	NVOICE 4, $0A, 0
	NOISE $31
	NOISE $22
	NVOICE 7, $0A, 0
	NOISE $72
	NVOICE 8, $0F, 0
	NOISE $02
	NOISE $44
	NVOICE 8, $0A, 0
	NOISE $44
	NOISE $44
	NVOICE 8, 8, 0
	NOISE $55
	NOISE $44
	NVOICE 4, $0A, 0
	NOISE $31
	NOISE $22
	NVOICE 7, $0A, 0
	NOISE $72
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE 4, $0C, 0
	NOISE $21
	NOISE $02
	NOISE $72
	NOISE $55
	NOISE $55
	NOISE $55
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE $30, $0A, 0
	NOISE $44
	NVOICE 3, $0A, 0
	NOISE $01
	NOISE $03
	NOISE $72
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE 3, $0A, 0
	NOISE $31
	NOISE $22
	NVOICE 7, $0A, 0
	NOISE $72
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE 4, $0C, 0
	NOISE $21
	NOISE $02
	NOISE $72
	NOISE $55
	NOISE $55
	NOISE $55
	NVOICE 3, $0F, 0
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $46
	NVOICE 8, $0C, 0
	NOISE $44
	NOISE $45
	NVOICE 8, $0A, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 8, 0
	NOISE $44
	NOISE $43
	NVOICE $10, 6, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 4, 0
	NOISE $44
	NOISE $43
	NVOICE $10, 2, 0
	NOISE $44
	NOISE $45
	SND_END

Snd1C_Sfx1:
	LOOP_START
	VOICE 2, 6, 8, 0, $0F
	OCTAVE 1
	NOTE C_, 2
	NOTE G_, 2
	REST 2
	LOOP_END $13
	PAN $F0
	LOOP_START
	VOICE 2, 5, 8, 7, 8
	OCTAVE 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 0
	NOTE C_, 0
	LOOP_END 2
	SND_END

Snd1C_SfxN:
	NVOICE 2, $0F, 0
	NOISE $02
	NOISE $12
	NOISE $33
	NVOICE 4, $0D, 0
	NOISE $22
	NOISE $24
	NVOICE 8, $0C, 6
	NOISE $45
	NVOICE 8, $0C, 7
	NOISE $45
	NVOICE 8, 4, 6
	NOISE $45
	NVOICE 2, $0A, 7
	NOISE $16
	NVOICE 4, 8, 7
	NOISE $33
	NVOICE 8, 6, 7
	NOISE $45
	NVOICE 8, 4, 6
	NOISE $45
	NVOICE 4, 3, 4
	NOISE $26
	NVOICE 4, 8, 7
	NOISE $33
	NVOICE $10, 5, 7
	NOISE $45
	NVOICE $20, 4, 6
	NOISE $45
	NVOICE 2, $0A, 6
	NOISE $23
	NVOICE 4, $0D, 5
	NOISE $01
	NVOICE 8, $0A, 6
	NOISE $23
	NVOICE $0C, 8, 6
	NOISE $34
	NVOICE 2, $0A, 6
	NOISE $23
	NVOICE 4, $0D, 5
	NOISE $01
	NVOICE 8, $0A, 6
	NOISE $23
	NVOICE $0C, 8, 6
	NOISE $34
	NVOICE $20, 7, 6
	NOISE $45
	NVOICE $20, 6, 6
	NOISE $45
	PAN $F0
	NVOICE 2, $0F, 0
	NOISE $13
	NOISE $24
	NVOICE 2, $0F, 7
	NOISE $34
	NVOICE 8, $0E, 7
	NOISE $43
	NVOICE $0C, $0C, 7
	NOISE $34
	NVOICE $10, $0A, 7
	NOISE $35
	NVOICE $18, 8, 7
	NOISE $45
	NVOICE $18, 6, 6
	NOISE $55
	NVOICE 2, $0F, 0
	NOISE $24
	NVOICE 2, $0E, 6
	NOISE $13
	NVOICE 8, $0C, 6
	NOISE $11
	NVOICE $10, $0A, 6
	NOISE $23
	NVOICE $18, 8, 6
	NOISE $24
	NVOICE $20, 7, 6
	NOISE $34
	NVOICE $0A, 6, 0
	NOISE $35
	NOISE $34
	NVOICE $0A, 5, 0
	NOISE $35
	NOISE $34
	NVOICE $0A, 4, 0
	NOISE $35
	NOISE $34
	NVOICE $0A, 3, 0
	NOISE $35
	NOISE $34
	NVOICE $0A, 2, 0
	NOISE $35
	NOISE $34
	NVOICE $0A, 1, 0
	NOISE $35
	NOISE $34
	SND_END

Snd1A_Sfx1:
	LOOP_START
	VOICE 2, 8, 8, 1, $0F
	OCTAVE 1
	NOTE C_, 2
	NOTE G_, 2
	REST 2
	LOOP_END 8
	SND_END

Snd1A_SfxN:
	NVOICE 2, $0F, 8
	NOISE $02
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $44
	NVOICE $10, $0E, 7
	NOISE $45
	NVOICE $20, $0B, 7
	NOISE $45
	NVOICE $20, 4, 6
	NOISE $45
	PAN $F0
	NVOICE 3, $0F, 8
	NOISE $02
	NOISE $72
	NOISE $23
	NOISE $55
	NVOICE 6, $0E, 7
	NOISE $22
	NVOICE $0A, $0B, 7
	NOISE $44
	NVOICE $10, 8, 6
	NOISE $44
	PAN $0F
	NVOICE 3, $0F, 6
	NOISE $03
	NOISE $72
	NOISE $23
	NOISE $55
	NVOICE 5, $0E, 7
	NOISE $23
	NVOICE 8, $0D, 7
	NOISE $33
	NVOICE $10, $0C, 7
	NOISE $35
	NVOICE $20, $0A, 7
	NOISE $45
	NVOICE $20, 7, 6
	NOISE $44
	SND_END

Snd1B_SfxN:
	NVOICE 4, $0F, 5
	NOISE $03
	NOISE $42
	NOISE $44
	NOISE $44
	NOISE $54
	NVOICE 4, 6, 7
	NOISE $35
	NVOICE $3C, 4, 7
	NOISE $44
	SND_END

Snd10_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 4
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 8
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 6
	NOTE G#, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd10_SfxN:
	LOOP_START
	NVOICE 2, 6, 0
	NOISE $39
	NOISE $2B
	LOOP_END $0C
	LOOP_START
	NVOICE 2, 3, 0
	NOISE $39
	NOISE $2B
	LOOP_END $0C
	SND_END

Snd54_Sfx1:
	VOICE 1, 6, 0, 1, $0F
	OCTAVE 6
	NOTE A#, 2
	VOICE 1, 6, 4, 2, 8
	OCTAVE 5
	NOTE G#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F#, 1
	ATTEN 2
	LOOP_START
	OCTAVE 5
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	LOOP_END 2
	SND_END

Snd58_Sfx1:
	VOICE 7, $0C, 8, 4, 8
	LOOP_START
	OCTAVE 5
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE G_, 1
	ATTEN 6
	LOOP_END 2
	ATTEN 8
	LOOP_START
	OCTAVE 5
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE G_, 1
	LOOP_END 2
	SND_END

Snd59_Sfx1:
	TRANSPOSE_DOWN 4
	VOICE 2, $0E, 4, 3, $0A
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 6
	NOTE C_HI, 2
	ATTEN $0A
	NOTE C_HI, 2
	ATTEN 4
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 6
	NOTE C_HI, 2
	ATTEN $0A
	NOTE C_HI, 2
	ATTEN 6
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 6
	NOTE C_HI, 2
	ATTEN $0A
	NOTE C_HI, 2
	ATTEN 8
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 6
	NOTE C_HI, 2
	ATTEN $0A
	NOTE C_HI, 2
	LOOP_START
	ATTEN $0A
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 6
	NOTE C_HI, 2
	ATTEN $0A
	NOTE C_HI, 2
	LOOP_END 2
	SND_END

Snd57_Sfx1:
	VOICE 2, $0E, 8, 0, $0F
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	TRANSPOSE_UP 4
	ATTEN 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	TRANSPOSE_UP 8
	ATTEN 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	TRANSPOSE_UP $0C
	ATTEN 0
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	VOICE 2, 6, 8, 0, $0F
	TRANSPOSE_UP 8
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	TRANSPOSE_UP $0C
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G_, 1
	SND_END

Snd5C_Sfx1:
	VOICE 2, $0F, 8, 0, 0
	DUTY_STEP 4, 1
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
	DUTY_STEP 0, 0
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

Snd5C_Sfx2:
	VOICE 4, $0B, 8, 6, 9
	OCTAVE 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 1
	SND_CALL Snd5C_Sfx2_6BDE
	ATTEN 4
	SND_CALL Snd5C_Sfx2_6BDE
	ATTEN 6
	SND_CALL Snd5C_Sfx2_6BDE
	ATTEN 9
	SND_CALL Snd5C_Sfx2_6BDE
	ATTEN $0A
	SND_CALL Snd5C_Sfx2_6BDE
	SND_END
Snd5C_Sfx2_6BDE:
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

Snd5C_SfxN:
	NVOICE 1, $0D, 7
	NOISE $44
	NVOICE 5, $0A, 7
	NOISE $72
	NOISE $71
	NVOICE $22, 9, 7
	NOISE $72
	SND_END

Snd56_Sfx1:
	TRANSPOSE_UP 1
	VOICE 1, 8, 4, 0, $0F
	OCTAVE 6
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE 1, $0E, 8, 0, $0F
	ATTEN $0A
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 7
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE G#, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE 1, 5, 8, 0, $0F
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_END

Snd55_Sfx1:
	VOICE 2, $0D, 8, 1, $0F
	OCTAVE 5
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 9
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

Snd5A_Sfx1:
	VOICE 2, $0C, $0C, 2, 8
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 2
	VOICE 1, 5, $0C, 3, $0A
	LOOP_START
	NOTE G_, 2
	LOOP_END 5
	SND_END

Snd5B_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_CALL Snd5B_Sfx1_6CB2
	VOICE 1, 4, 0, 0, $0F
	LOOP_START
	SND_CALL Snd5B_Sfx1_6CB2
	LOOP_END 3
	SND_END

Snd5B_Sfx2:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 3
	REST 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_CALL Snd5B_Sfx1_6CB2
	VOICE 1, $0A, 0, 0, $0F
	ATTEN 0
	PAN $F0
	SND_CALL Snd5B_Sfx1_6CB2
	ATTEN 3
	PAN $0F
	SND_CALL Snd5B_Sfx1_6CB2
	ATTEN 6
	PAN $F0
	SND_CALL Snd5B_Sfx1_6CB2
	SND_END
Snd5B_Sfx1_6CB2:
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 3
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_RET

Snd5B_SfxN:
	NVOICE 1, $0F, 0
	NOISE $02
	NOISE $55
	NOISE $59
	NVOICE 1, $0A, 0
	NOISE $33
	NOISE $22
	NOISE $22
	SND_END

Snd26_Sfx1:
	TRANSPOSE_UP 4
	VOICE 1, $0F, 8, 0, 0
	OCTAVE 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE G_, 2
	NOTE D#, 1
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 0
	VOICE 1, 6, 8, 1, $0F
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE D#, 1
	SND_END
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Snd27_Sfx1:
	RAW_HEADER 1, $00, $88
	RAW_NOTE 8, $780
	RAW_NOTE 9, $77C
	RAW_NOTE 10, $778
	RAW_NOTE 11, $774
	RAW_NOTE 12, $770
	RAW_NOTE 13, $760
	RAW_NOTE 15, $750
	RAW_NOTE 15, $740
	RAW_NOTE 15, $730
	RAW_NOTE 15, $720
	RAW_NOTE 15, $700
	RAW_NOTE 13, $6E0
	RAW_NOTE 12, $6C0
	RAW_NOTE 11, $6A0
	RAW_NOTE 10, $680
	RAW_NOTE 9, $640
	RAW_NOTE 8, $600
	RAW_NOTE 15, $640
	RAW_NOTE 13, $660
	RAW_NOTE 12, $680
	RAW_NOTE 11, $690
	RAW_NOTE 10, $6A0
	RAW_NOTE 9, $6B0
	RAW_NOTE 8, $6B8
	RAW_NOTE 7, $6C0
	RAW_NOTE 6, $6C8
	RAW_NOTE 5, $6D0
	RAW_NOTE 12, $660
	RAW_NOTE 11, $670
	RAW_NOTE 10, $680
	RAW_NOTE 9, $690
	RAW_NOTE 8, $6A0
	RAW_NOTE 7, $6B0
	RAW_NOTE 6, $6B8
	RAW_NOTE 5, $6C0
	RAW_NOTE 4, $6C8
	RAW_NOTE 3, $6D0
	SND_END

Snd28_Sfx1:
	VOICE 1, $0C, 8, 0, $0F
	OCTAVE 4
	ATTEN 6
	NOTE C_HI, 1
	NOTE C_, 1
	ATTEN 5
	NOTE A#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE G#, 1
	NOTE C_, 1
	ATTEN 3
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	SND_END

Snd37_SfxN:
	NVOICE 1, $0C, 0
	NOISE $49
	NOISE $55
	NOISE $45
	NOISE $34
	NVOICE $20, $0F, 1
	NOISE $44
	SND_END
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Snd38_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE G_, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 2
	SND_END

Snd38_SfxN:
	NVOICE 2, $0F, 0
	NOISE $44
	NOISE $02
	NOISE $33
	NOISE $34
	NOISE $35
	NVOICE 8, 6, 0
	NOISE $45
	NVOICE $10, 4, 0
	NOISE $56
	SND_END

Snd39_SfxN:
	NVOICE 3, $0A, 0
	NOISE $02
	NOISE $79
	NOISE $53
	NVOICE 8, $0A, 0
	NOISE $55
	NVOICE $10, 5, 0
	NOISE $33
	NOISE $34
	NVOICE $40, 2, 0
	NOISE $44
	SND_END

Snd3B_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 6
	NOTE C_, 4
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE G_, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE G#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 2
	SND_END

Snd3B_SfxN:
	NVOICE 2, $0F, 0
	NOISE $01
	NOISE $12
	NOISE $33
	NOISE $55
	NOISE $64
	NVOICE 8, 6, 0
	NOISE $03
	NVOICE $10, 4, 0
	NOISE $45
	SND_END

Snd1D_Sfx1:
	VOICE 1, $0A, 8, 1, $0F
	OCTAVE 6
	LOOP_START
	NOTE C_HI, 1
	NOTE C#, 1
	LOOP_END 3
	ATTEN 7
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	ATTEN 8
	LOOP_START
	NOTE C_HI, 1
	NOTE C#, 1
	LOOP_END 3
	SND_END

Snd1D_SfxN:
	NVOICE $0A, 7, 1
	NOISE $49
	SND_END

Snd1E_Sfx1:
	VOICE 1, $0C, 0, 1, $0F
	OCTAVE 6
	NOTE G_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	VOICE 1, 6, 0, 0, $0F
	LOOP_START
	NOTE G_, 1
	NOTE C#, 1
	LOOP_END 4
	VOICE 1, 4, 0, 0, $0F
	LOOP_START
	NOTE G_, 1
	NOTE C#, 1
	LOOP_END 6
	SND_END

Snd1E_SfxN:
	NVOICE 1, $0C, 0
	NOISE $49
	NOISE $4B
	NOISE $49
	NOISE $4B
	NVOICE 1, 3, 0
	NOISE $49
	NOISE $4B
	NOISE $49
	NOISE $4B
	NVOICE 1, 2, 0
	NOISE $49
	NOISE $4B
	NOISE $49
	NOISE $4B
	SND_END

Snd36_Sfx1:
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_END

Snd36_SfxN:
	NVOICE 1, $0F, 0
	NOISE $02
	NOISE $79
	NVOICE 4, $0C, 0
	NOISE $33
	NOISE $34
	NVOICE 8, $0A, 0
	NOISE $44
	NOISE $45
	NVOICE 8, 8, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 6, 0
	NOISE $45
	NVOICE $10, 4, 0
	NOISE $45
	NVOICE $10, 4, 0
	NOISE $55
	NVOICE $10, 2, 0
	NOISE $55
	SND_END

Snd1F_Sfx1:
	VOICE 1, $0F, 4, 0, $0F
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	VOICE 1, 5, 4, 0, $0F
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	LOOP_END 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_END

Snd20_Sfx1:
	VOICE 1, $0F, 4, 0, $0F
	OCTAVE 6
	NOTE C_, 1
	TRANSPOSE_DOWN 8
	OCTAVE 4
	NOTE G#, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1
	VOICE 1, 4, 4, 0, $0F
	LOOP_START
	NOTE F#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F_, 1
	LOOP_END 3
	SND_END

Snd20_SfxN:
	NVOICE 1, $0F, 0
	NOISE $02
	NVOICE $10, 8, 2
	NOISE $03
	SND_END

Snd22_Sfx1:
	VOICE 1, $0C, 0, 0, $0F
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 8
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 0
	VOICE 1, 4, 0, 0, $0F
	LOOP_START
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G#, 1
	LOOP_END 3
	SND_END

Snd22_SfxN:
	NVOICE 2, $0F, 0
	NOISE $02
	NOISE $03
	NVOICE $0A, 4, 3
	NOISE $02
	SND_END

Snd23_Sfx1:
	VOICE 1, $0C, 8, 1, $0F
	OCTAVE 6
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	VOICE 1, 5, 4, 0, $0F
	LOOP_START
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 0
	LOOP_END 4
	VOICE 1, 4, 0, 0, $0F
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	SND_END

Snd23_SfxN:
	NVOICE 1, $0C, 0
	NOISE $02
	NOISE $04
	NOISE $39
	NOISE $3B
	NVOICE 2, 4, 0
	NOISE $39
	NOISE $3B
	NOISE $49
	NOISE $3B
	NVOICE 2, 2, 0
	NOISE $39
	NOISE $3B
	NOISE $49
	NOISE $3B
	SND_END

Snd24_Sfx1:
	VOICE 1, $0E, 4, 1, $0F
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	VOICE 1, $0A, 4, 0, $0F
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	VOICE 1, 6, 4, 0, $0F
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	VOICE 1, 4, 4, 0, $0F
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	SND_END

Snd21_Sfx1:
	VOICE 1, $0A, 0, 0, $0F
	OCTAVE 6
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, $0A
	ATTEN 7
	NOTE D_, 0
	SND_END

Snd21_SfxN:
	NVOICE 3, $0F, 0
	NOISE $11
	NVOICE $11, 6, 2
	NOISE $4A
	SND_END

Snd3E_Sfx1:
	TRANSPOSE_DOWN 3
	VOICE 1, $0B, 4, 1, $0F
	OCTAVE 5
	NOTE C_HI, 1
	ATTEN 3
	LOOP_START
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	LOOP_END 2
	LOOP_START
	NOTE A#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 0
	VOICE 1, 4, 4, 1, $0F
	LOOP_END 2
	SND_END

Snd3F_Sfx1:
	VOICE 1, $0C, 0, 1, $0F
	OCTAVE 6
	NOTE G_, 1
	NOTE C#, 1
	VOICE 1, 6, 0, 0, $0F
	NOTE G_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	VOICE 1, 4, 0, 0, $0F
	NOTE G_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1

Snd3E_SfxN:
	SND_END

Snd3F_SfxN:
	NVOICE 1, $0A, 4
	NOISE $39
	NOISE $2B
	NVOICE 1, 6, 0
	NOISE $39
	NOISE $2B
	NOISE $39
	NOISE $2B
	NVOICE 1, 6, 0
	NOISE $39
	NOISE $2B
	NVOICE 1, 5, 0
	NOISE $39
	NOISE $2B
	NVOICE 1, 4, 0
	NOISE $49
	NOISE $3B
	SND_END

Snd40_SfxN:
	NVOICE 1, $0F, 0
	NOISE $15
	NOISE $55
	NOISE $72
	NVOICE 4, $0E, 0
	NOISE $55
	NVOICE 4, $0A, 0
	NOISE $4A
	NOISE $49
	NOISE $39
	NOISE $3A
	NVOICE 4, 9, 0
	NOISE $04
	NOISE $2A
	NOISE $04
	NOISE $1A
	NVOICE 4, 8, 0
	NOISE $05
	NOISE $0A
	NOISE $05
	NOISE $0A
	NVOICE 4, 3, 0
	NOISE $04
	NOISE $29
	NOISE $04
	NOISE $2A
	NVOICE 4, 2, 0
	NOISE $05
	NOISE $19
	NOISE $05
	NOISE $1A
	SND_END

Snd35_Sfx1:
	TRANSPOSE_DOWN 5
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 5
	ATTEN 7
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G#, 1
	VOICE 1, $0F, 0, 0, $0F
	OCTAVE 5
	LOOP_START
	NOTE C_, 1
	NOTE A_, 1
	LOOP_END $0A
	ATTEN 7
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 5
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	ATTEN 0
	SND_CALL Snd35_Sfx1_70BF
	ATTEN 9
	SND_CALL Snd35_Sfx1_70BF
	SND_END
Snd35_Sfx1_70BF:
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
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd35_SfxN:
	NVOICE $10, 4, 0
	NOISE $19
	NVOICE 6, $0F, 0
	NOISE $19
	NOISE $29
	NOISE $39
	NOISE $29
	NOISE $19
	NOISE $29
	NOISE $39
	NOISE $29
	NVOICE 3, 0, 2
	NOISE $72
	NVOICE $10, $0A, 0
	NOISE $02
	NOISE $12
	NOISE $23
	NOISE $33
	NOISE $34
	NOISE $44
	NOISE $45
	NOISE $55
	SND_END

Snd3C_Sfx1:
	VOICE 1, 8, 8, 0, $0F
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	LOOP_END 5
	VOICE 4, 4, 0, 0, $0F
	OCTAVE 3
	NOTE E_, 1
	LOOP_START
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 3
	SND_END

Snd3C_SfxN:
	NVOICE 1, $0F, 0
	NOISE $01
	NOISE $72
	NOISE $55
	NOISE $45
	NVOICE 6, $0F, 0
	NOISE $02
	NVOICE 6, $0D, 0
	NOISE $23
	NOISE $55
	NVOICE 6, $0B, 0
	NOISE $33
	NOISE $45
	NVOICE 4, $0A, 0
	NOISE $13
	NOISE $56
	NVOICE $10, 8, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 5, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 4, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 3, 0
	NOISE $44
	NOISE $45
	NVOICE $10, 2, 0
	NOISE $55
	NOISE $55
	SND_END

Snd3D_Sfx1:
	VOICE 3, 6, 8, 1, $0F
	OCTAVE 2
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE C#, 1
	LOOP_START
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 2
	ATTEN 2
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	VOICE 4, 4, 0, 0, $0F
	OCTAVE 5
	REST 0
	NOTE C_HI, 0
	ATTEN 3
	NOTE C_HI, 0
	VOICE 3, 5, 8, 0, $0F
	OCTAVE 2
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D_, 1
	LOOP_START
	NOTE A_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 3
	LOOP_END 2
	SND_END

Snd3D_SfxN:
	NVOICE 1, $0F, 0
	NOISE $01
	NOISE $72
	NOISE $55
	NVOICE 2, $0E, 0
	NOISE $24
	NOISE $02
	NOISE $33
	NVOICE 4, $0D, 0
	NOISE $55
	NVOICE 4, $0C, 0
	NOISE $34
	NVOICE 2, $0D, 0
	NOISE $02
	NVOICE 4, $0C, 0
	NOISE $12
	NOISE $23
	NVOICE 4, $0B, 0
	NOISE $22
	NOISE $22
	NOISE $23
	NVOICE 4, $0A, 0
	NOISE $23
	NOISE $22
	NOISE $22
	NVOICE 4, $0B, 0
	NOISE $23
	NOISE $33
	NVOICE 4, $0A, 0
	NOISE $03
	NOISE $23
	NOISE $33
	NOISE $34
	NVOICE 4, 9, 0
	NOISE $34
	NOISE $33
	NOISE $02
	NOISE $34
	NVOICE 5, $0A, 0
	NOISE $44
	NOISE $34
	NOISE $23
	NOISE $44
	NVOICE 6, 9, 0
	NOISE $34
	NOISE $33
	NOISE $44
	NOISE $34
	NVOICE 8, 8, 0
	NOISE $33
	NOISE $34
	NOISE $33
	NOISE $34
	NVOICE $0A, 7, 0
	NOISE $55
	NOISE $45
	NOISE $43
	NOISE $45
	NVOICE $0C, 6, 0
	NOISE $34
	NOISE $44
	NOISE $45
	NVOICE $10, 6, 0
	NOISE $44
	NVOICE $10, 5, 0
	NOISE $44
	NOISE $34
	NVOICE $18, 4, 0
	NOISE $34
	NVOICE $1C, 4, 0
	NOISE $44
	NVOICE $20, 3, 0
	NOISE $44
	NVOICE $24, 2, 0
	NOISE $44
	NVOICE $28, 2, 0
	NOISE $45
	NOISE $55
	NVOICE $2C, 1, 0
	NOISE $45
	NOISE $55
	NVOICE $2C, 1, 0
	NOISE $55
	SND_END

Snd0E_Sfx1:
	VOICE 2, $0C, 8, 0, $0F
	ATTEN 6
	SND_CALL Snd0E_Sfx1_722C
	ATTEN 4
	SND_CALL Snd0E_Sfx1_722C
	ATTEN 0
	VOICE 2, 3, 8, 0, $0F
	LOOP_START
	SND_CALL Snd0E_Sfx1_722C
	LOOP_END 2
	SND_END
Snd0E_Sfx1_722C:
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	NOTE B_, 2
	SND_RET

Snd0F_Sfx1:
	VOICE 2, $0F, 8, 0, $0F
	ATTEN 2
	SND_CALL Snd0F_Sfx1_7262
	ATTEN 6
	SND_CALL Snd0F_Sfx1_7262
	ATTEN 4
	TRANSPOSE_UP 1
	SND_CALL Snd0F_Sfx1_7262
	ATTEN 9
	TRANSPOSE_UP 2
	LOOP_START
	SND_CALL Snd0F_Sfx1_7262
	TRANSPOSE_UP 3
	LOOP_END 2
	ATTEN 0
	VOICE 2, 2, 8, 0, $0F
	TRANSPOSE_UP 4
	LOOP_START
	SND_CALL Snd0F_Sfx1_7262
	TRANSPOSE_UP 5
	LOOP_END 2
	SND_END
Snd0F_Sfx1_7262:
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE D_, 1
	NOTE C_HI, 2
	SND_RET

Snd5D_Sfx1:
	RAW_HEADER 10, $08, $88
	RAW_NOTE 15, $707
	RAW_NOTE 15, $73A
	RAW_NOTE 15, $75A
	RAW_NOTE 15, $73A
	RAW_NOTE 15, $75A
	RAW_NOTE 15, $784
	RAW_NOTE 13, $784
	RAW_NOTE 4, $784
	SND_END
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF

SECTION "Sound bank 14", ROMX[$4000], BANK[14]
B14_SoundTable:
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
	dw SndHdr90 ; $90
	dw SndHdr91 ; $91
	dw SndHdr92 ; $92
	dw SndHdr93 ; $93
	dw SndHdr94 ; $94
	dw SndHdr95 ; $95
	dw SndHdr96 ; $96

SndHdr8E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8E_Ch1
	dw Snd8E_Ch2
	dw Snd8E_Ch3
	dw Snd8E_Drm

SndHdr8F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd8F_Ch1
	dw Snd8F_Ch2
	dw Snd8F_Ch3
	dw Snd8F_Drm

SndHdr90:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd90_Ch1
	dw Snd90_Ch2
	dw Snd90_Ch3
	dw Snd90_Drm

SndHdr91:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd91_Ch1
	dw Snd91_Ch2
	dw Snd91_Ch3
	dw Snd91_Drm

SndHdr92:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd92_Ch1
	dw Snd92_Ch2
	dw Snd92_Ch3
	dw Snd92_Drm

SndHdr93:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd93_Ch1
	dw Snd93_Ch2
	dw Snd93_Ch3
	dw Snd93_Drm

SndHdr94:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd94_Ch1
	dw Snd94_Ch2
	dw Snd94_Ch3
	dw Snd94_Drm

SndHdr95:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd95_Ch1
	dw Snd95_Ch2
	dw Snd95_Ch3
	dw Snd95_Drm

SndHdr96:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd96_Ch1
	dw Snd96_Ch2
	dw Snd96_Ch3
	dw Snd96_Drm
B14_DrumMap:
	db $81, $82, $83, $84, $85, $86, $87, $8A, $88, $8B, $89, $8C, $8D

SndHdr81:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd81_SfxN

SndHdr82:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd82_SfxN

SndHdr88:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd88_SfxN

SndHdr89:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd89_SfxN

SndHdr8A:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd8A_SfxN

SndHdr83:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd83_SfxN

SndHdr84:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd84_Sfx1
	dw Snd84_SfxN

SndHdr85:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd85_SfxN

SndHdr86:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd86_SfxN

SndHdr87:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd87_Sfx1
	dw Snd87_SfxN

SndHdr8B:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw Snd8B_SfxN

SndHdr8C:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd8C_Sfx1
	dw Snd8C_SfxN

SndHdr8D:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw Snd8D_Sfx1
	dw Snd8D_SfxN

Snd81_SfxN:
	NVOICE 1, $0F, 1
	NOISE $01
	NVOICE 1, $0A, 1
	NOISE $11
	SND_END

Snd85_SfxN:
	NVOICE 1, 9, 1
	NOISE $01
	NVOICE 1, 6, 1
	NOISE $11
	SND_END

Snd82_SfxN:
	NVOICE 1, 6, 0
	NOISE $02
	NVOICE 3, 8, 0
	NOISE $02
	NVOICE $0A, 4, 5
	NOISE $02
	SND_END

Snd89_SfxN:
	NVOICE 1, $0F, 3
	NOISE $3D
	NOISE $74
	SND_END

Snd8A_SfxN:
	NVOICE 1, $0F, 1
	NOISE $0A
	NVOICE 1, 8, 0
	NOISE $71
	SND_END

Snd88_SfxN:
	NVOICE 1, $0F, 0
	NOISE $01
	NOISE $72
	NVOICE 1, $0C, 0
	NOISE $25
	NVOICE 5, 5, 3
	NOISE $07
	SND_END

Snd86_SfxN:
	NVOICE 1, $0F, 0
	NOISE $43
	NOISE $24
	NVOICE $0A, 8, 1
	NOISE $33
	SND_END

Snd83_SfxN:
	NVOICE 5, 3, $0B
	NOISE $01
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $13
	NOISE $14
	NOISE $14
	NOISE $15
	NOISE $15
	NOISE $16
	NOISE $16
	NOISE $17
	NOISE $17
	SND_END
B14_Orphan_4126:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B14_Orphan_412D:
	RAW_HEADER 2, $08, $1F
	PAN $F0
	RAW_NOTE 8, $6FF
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $699
	SND_END
B14_Orphan_413C:
	PAN $0F
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B14_Orphan_4143:
	RAW_HEADER 2, $08, $1E
	PAN $0F
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END
B14_Orphan_4152:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B14_Orphan_4159:
	RAW_HEADER 2, $08, $1E
	PAN $F0
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END

Snd8B_SfxN:
	NVOICE 1, $0F, 1
	NOISE $79
	NVOICE $0C, 7, 0
	NOISE $02
	NVOICE $18, 4, 7
	NOISE $02
	SND_END

Snd8C_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $3D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd8C_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd8D_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $2D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd8D_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd87_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 4
	SND_END

Snd87_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd84_Sfx1:
	VOICE 5, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 6
	SND_END

Snd84_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

B14_CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, B14_CopyBytes
	ret

B14_LoadPtrIndexed:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

B14_JumpTableInline:
	pop hl
	call B14_LoadPtrIndexed
	jp hl
B14_PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7
B14_WaveTable:
	dw B14_WaveData1
	dw B14_WaveData2
	dw B14_WaveData3
	dw B14_WaveData4
	dw B14_WaveData5
	dw B14_WaveData6
	dw B14_WaveData7
	dw B14_WaveData8
	dw B14_WaveData9
	dw B14_WaveData10
	dw B14_WaveData11
	dw B14_WaveData12
	dw B14_WaveData13
	dw B14_WaveData14
B14_WaveData1:
	db $F0, $EE, $CA, $86, $0A, $46, $8A, $CE, $FF, $EE, $CA, $86, $0A, $46, $8A, $CE
B14_WaveData2:
	db $F8, $23, $45, $67, $89, $AB, $CD, $EF, $F8, $23, $45, $67, $89, $AB, $CD, $EF
B14_WaveData3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
B14_WaveData4:
	db $11, $12, $22, $33, $34, $45, $57, $79, $9A, $BC, $DE, $FC, $86, $55, $44, $21
B14_WaveData5:
	db $23, $44, $55, $67, $89, $9A, $BB, $CD, $23, $56, $78, $9A, $CD, $CA, $98, $53
B14_WaveData6:
	db $60, $58, $00, $FF, $F9, $00, $00, $20, $20, $08, $08, $40, $C0, $00, $C0, $00
B14_WaveData7:
	db $FF, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
B14_WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
B14_WaveData9:
	db $88, $80, $8F, $FF, $88, $88, $88, $80, $40, $08, $08, $88, $40, $00, $80, $00
B14_WaveData10:
	db $66, $60, $8F, $C0, $88, $80, $40, $20, $20, $08, $08, $88, $40, $00, $80, $00
B14_WaveData11:
	db $F8, $88, $44, $33, $22, $22, $11, $00, $00, $11, $00, $00, $00, $88, $FF, $11
B14_WaveData12:
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $11, $11, $22, $22, $33, $33, $44, $44, $55
B14_WaveData13:
	db $02, $46, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $45, $65, $43, $21, $00
B14_WaveData14:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
B14_VibratoTable:
	dw B14_Vib01 ; 1
	dw B14_Vib02 ; 2
	dw B14_Vib03 ; 3
	dw B14_Vib04 ; 4
	dw B14_Vib05 ; 5
	dw B14_Vib06 ; 6
	dw B14_Vib07 ; 7
	dw B14_Vib08 ; 8
	dw B14_Vib09 ; 9
	dw B14_Vib0A ; 10
	dw B14_Vib0B ; 11
	dw B14_Vib0C ; 12
	dw B14_Vib0D ; 13
	dw B14_Vib0E ; 14
	dw B14_Vib0F ; 15

B14_Vib01:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

B14_Vib02:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

B14_Vib03:
	VIB_SEGNO
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 0, 1
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 1, 1
	VIB_REPEAT $FF

B14_Vib04:
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 0, 0
	VIB_HOLD

B14_Vib05:
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

B14_Vib06:
	VIB_SEGNO
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 1, 1
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 6
	VIB_STEP 1, 1, 2
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 5
	VIB_STEP 1, 1, 3
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 4
	VIB_STEP 1, 1, 4
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 1, 5
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 1, 6
	VIB_REPEAT 3
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 7
	VIB_REPEAT 3
	VIB_HOLD

B14_Vib07:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_REPEAT $FF

B14_Vib08:
	VIB_STEP 15, 0, 1
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B14_Vib09:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 0
	VIB_HOLD

B14_Vib0A:
	VIB_STEP 15, 1, 2
	VIB_SEGNO
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B14_Vib0B:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

B14_Vib0C:
	VIB_STEP 8, 1, 1
	VIB_STEP 8, 1, 2
	VIB_STEP 8, 1, 3
	VIB_STEP 8, 1, 4
	VIB_STEP 8, 1, 5
	VIB_STEP 8, 1, 6
	VIB_STEP 8, 1, 7
	VIB_HOLD

B14_Vib0D:
	VIB_STEP 1, 0, 4
	VIB_STEP 12, 0, 0
	VIB_SEGNO
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

B14_Vib0E:
	VIB_STEP 12, 0, 0
	VIB_SEGNO
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 0, 0
	VIB_REPEAT $FF

B14_Vib0F:
	VIB_HOLD

; PlayDrumSound: the drum track's PlaySound. Only Sfx1 (when the mask is 5) and
; SfxN are started, from this bank's table, without wReqRefused.
B14_PlayDrumSound:
	ld [wReqId], a
	or a
	jp z, B14_StopAll
	and $3F
	ld hl, SOUND_TABLE_M2
	call B14_LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl+]
	ld d, h
	ld e, l
	cp $05
	jr nz, .l4454
	call B14_StartSfx1
.l4454:
	call B14_StartSfxN
	ld a, [wNR51]
	ldh [rNR51], a
	ret

; (unreachable)
	ret

B14_StartSfxN:
	push af
	ld hl, wTrkSfxN
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l4471
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l4471:
	dec l
	jr B14_StartTrack

B14_StartSfx1:
	push af
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l448E
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
.l448E:
	dec l

B14_StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l44D2
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
	jr nz, .l44C9
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l44D5
.l44C9:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l44D5
.l44D2:
	push de
	inc de
	inc de
.l44D5:
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

; StopAll (bank copy): clears only Sfx1 and SfxN, then falls into FadeStep.
B14_StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0037
	ld [hl], $00
	call B14_CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0037
	ld [hl], $00
	call B14_CopyBytes
	ld hl, wShadow
	ld de, wShadow + $01
	ld bc, $0014
	ld [hl], $00
	call B14_CopyBytes
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0020
	ld [hl], $00
	call B14_CopyBytes
	ld a, $FF
	ld [wNR51], a

; FadeStep: while wFadeReq is set, every $70 calls one step (wFadeLevel + 1, one
; more step of attenuation on new music notes). Step 5 stops the drums, 7 CH3,
; 9 CH1/CH2 (NRx2 = 8 + trigger if their SFX is idle) and ends the fade.
B14_FadeStep:
	ld a, [wFadeReq]
	or a
	jr nz, B14_FadeCount
.l4520:
	ld [wFadeTimer], a
	ld [wFadeLevel], a
	ld [wFadeStep], a
	ld [wFadeReq], a
	ret

B14_FadeCount:
	ld a, [wFadeTimer]
	inc a
	ld [wFadeTimer], a
	cp $70
	jp z, B14_FadeNextStep
	ret

B14_FadeNextStep:
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
	jp nz, .l455D
	xor a
	ld hl, wTrkDrm
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ret
.l455D:
	ld a, [wFadeStep]
	cp $07
	jp nz, .l4572
	xor a
	ld hl, wTrkCh3
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ldh [rNR32], a
	ldh [rNR30], a
	ret
.l4572:
	ld a, [wFadeStep]
	cp $09
	ret nz
	xor a
	ld hl, wTrkCh1
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx1
	ld a, [hl]
	or a
	jr nz, .l4592
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
.l4592:
	xor a
	ld hl, wTrkCh2
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx2
	ld a, [hl]
	or a
	jr nz, .l45AC
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
.l45AC:
	xor a
	jp B14_FadeStep.l4520

; TrackEntry: called for every track on every update. Paused: nothing (bank 13: only
; the track playing $5D). Music tracks: every call advances wTempoPhase; on every
; fourth call wTempoAcc += wTempo, and a carry skips the next four music calls.
; Then only one pair of music tracks runs per update (wHalfPhase 0: Ch1/Ch2,
; 1: Ch3/Drm; bank 15: 0: Drm/Ch2, 1: Ch3/Ch1), calling FadeStep first.
B14_TrackEntry:
	ld a, [wPauseFlags]
	rra
	ret c
	ld a, [wTrackIdx]
	cp $03
	jp c, B14_TrackTick
	ld a, [wTempoSkip]
	or a
	jr nz, .l4604
	ld a, [wTempo]
	or a
	jr nz, .l45CF
	xor a
	ld [wTempoOn], a
	jr B14_HalfRate
.l45CF:
	ld a, $01
	ld [wTempoOn], a
	ld a, [wTempoPhase]
	cp $03
	jr z, .l45E1
	inc a
	ld [wTempoPhase], a
	jr B14_HalfRate
.l45E1:
	xor a
	ld [wTempoPhase], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	jr nc, .l45FE
	ld a, [wTempo]
	ld [wTempoAcc], a
	ld a, $01
	ld [wTempoSkip], a
	ret
.l45FE:
	xor a
	ld [wTempoSkip], a
	jr B14_HalfRate
.l4604:
	ld a, [wTempoPhase]
	cp $03
	jr z, .l45FE
	inc a
	ld [wTempoPhase], a
	ret

; (unreachable)
	ld a, [wTempoSkip]
	or a
	ret nz

B14_HalfRate:
	ld a, [wHalfPhase]
	or a
	jr z, .l4620
	cp $01
	jr z, .l462F
	ret
.l4620:
	ld a, [wTrackIdx]
	cp $03
	jr z, .l463E
	ld a, [wTrackIdx]
	cp $04
	jr z, .l463E
	ret
.l462F:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l463E
	ld a, [wTrackIdx]
	cp $06
	jr z, .l463E
	ret
.l463E:
	call B14_FadeStep

; TrackTick: one tick for track wTrackIdx (H = its page).
B14_TrackTick:
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	call B14_GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, .l467A
	ld l, TRK_FLAGS2
	res 2, [hl]
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $00
	jr nz, .l4669
.l4669:
	ld a, [wTrackIdx]
	cp $05
	jp nz, B14_ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp B14_ReadCmds
.l467A:
	ld l, TRK_FLAGS2
	ld a, [hl]
	and $18
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l469F
	ld l, TRK_DUTYTICKS
	ld a, [hl]
	dec a
	ld [hl], a
	jr nz, .l469F
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
.l469F:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l46AB
	ld l, TRK_FLAGS2
	set 2, [hl]
.l46AB:
	ld l, TRK_FLAGS
	bit 2, [hl]
	jr z, .l46BD
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jr z, .l46BA
	dec [hl]
	jr .l46BD
.l46BA:
	call B14_VibratoTick
.l46BD:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l46DF
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
	call B14_WriteReg
	jp B14_Trigger
.l46DF:
	ld l, TRK_FLAGS2
	bit 2, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l470B
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
	jr z, .l470B
	inc a
	and $03
	ld [hl], a
	jr z, .l470B
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l4708
	xor a
.l4708:
	rla
	swap a
.l470B:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B14_WriteReg

B14_ReadCmdsNext:
	inc de

; ReadCmds: execute commands until a note/rest (or $FF end).
B14_ReadCmds:
	ld a, [de]
	cp $FB
	jp c, B14_ReadCmdsLow
	inc de
	sub $FB
	push hl
	call B14_JumpTableInline
	dw B14_Cmd_Loop
	dw B14_Cmd_Loop2
	dw B14_Cmd_Call
	dw B14_Cmd_Segno
	dw B14_Cmd_End

; $FB: the first one marks the loop start, the next one (FB n) loops n times.
; $FC: the same with the second loop level.
B14_Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $01
	jp nz, .l4740
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B14_ReadCmds
.l4740:
	ld a, [de]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l474E
	ld l, TRK_LOOPPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B14_ReadCmds
.l474E:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jr B14_ReadCmdsNext

B14_Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $02
	jp nz, .l476A
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B14_ReadCmds
.l476A:
	push hl
	ld a, [de]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l477A
	pop hl
	ld l, TRK_LOOP2PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B14_ReadCmds
.l477A:
	pop hl
	ld l, TRK_LOOP2CNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jr B14_ReadCmdsNext

; $FD addr: call; the next $FD (no argument) returns.
B14_Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $04
	jp nz, .l47A0
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
	jp B14_ReadCmds
.l47A0:
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLOW
	res 2, [hl]
	jp B14_ReadCmds

; $FE: the first one marks, the next one jumps back to the mark.
B14_Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $08
	jp nz, .l47BF
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp B14_ReadCmds
.l47BF:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B14_ReadCmds

; $FF: end of track. When an SFX on CH1/CH2 ends while music uses the channel,
; restore the music duty, its PAN bits and its period. CH3: NR30 = 0.
B14_Cmd_End:
	pop hl
	dec de
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B14_WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l47E4
	xor a
	ldh [rNR30], a
	ret
.l47E4:
	cp $02
	jr z, .l4806
	cp $01
	jr z, .l47F6
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l47F8
.l47F6:
	ld h, HIGH(wTrkCh2)
.l47F8:
	ld l, TRK_ID
	ld a, [hl]
	cp $00
	ret z
	push hl
	call B14_WriteDuty
	pop hl
	jp .l480D
.l4806:
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
.l480D:
	push hl
	call B14_GetPanBits
	pop hl
	ld b, a
	call B14_IsBlocked
	ld a, b
	jp c, .l4820
	or c
	ld [wNR51], a
	ldh [rNR51], a
.l4820:
	ld l, TRK_PERIOD
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld b, [hl]
	jp B14_WritePeriodBC

B14_ReadCmdsLow:
	ld l, TRK_FLAGS2
	bit 5, [hl]
	jp nz, B14_RawReader
	ld a, [de]
	cp $E0
	jp z, B14_Cmd_Voice
	and $F0
	cp $E0
	jp c, B14_Note
	cp $F0
	jp z, B14_Cmd_Atten
	ld a, [de]
	cp $E7
	jp c, B14_Cmd_Octave
	inc de
	sub $E7
	push hl
	call B14_JumpTableInline
	dw B14_Cmd_LenUnit
	dw B14_Cmd_Release
	dw B14_Cmd_Sweep
	dw B14_Cmd_Ext
	dw B14_Cmd_Vibrato
	dw B14_Cmd_EC
	dw B14_Cmd_DutyStep
	dw B14_Cmd_Tempo
	dw B14_Cmd_Pan

B14_Cmd_LenUnit:
	pop hl
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	jp B14_ReadCmdsNext

B14_Cmd_Release:
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
	jp B14_ReadCmdsNext

B14_Cmd_Sweep:
	pop hl
	ld a, [de]
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B14_WriteReg
	jp B14_ReadCmdsNext

B14_Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	call B14_JumpTableInline
	dw B14_Ext_TransposeUp
	dw B14_Ext_TransposeDown
	dw B14_Ext_Nop
	dw B14_Ext_Duty
	dw B14_Ext_Autopan

B14_Ext_TransposeUp:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp B14_ReadCmdsNext

B14_Ext_TransposeDown:
	pop hl
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp B14_ReadCmdsNext

B14_Ext_Nop:
	pop hl
	jp B14_ReadCmdsNext

B14_Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VOICEDUTY
	ld [hl], a
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
	jp B14_ReadCmdsNext

B14_Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld a, [hl]
	jr z, .l48DA
	or $02
	jr .l48DC
.l48DA:
	and $FD
.l48DC:
	ld [hl], a
	jp B14_ReadCmdsNext

; $EB n xy: vibrato table n & 15 (0 = off, no second byte), delay (x + 1) * unit
; ticks before it starts (x = 0: none), depth y multiplies the offsets.
B14_Cmd_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	jr nz, .l48F4
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 2, [hl]
	jp B14_ReadCmdsNext
.l48F4:
	ld l, TRK_FLAGS
	set 2, [hl]
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAYUNITS
	ld [hl], a
	jr z, .l490C
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l4908:
	add a, c
	dec b
	jr nz, .l4908
.l490C:
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
	ld hl, B14_VibratoTable
	call B14_LoadPtrIndexed
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
	jp B14_ReadCmdsNext

B14_Cmd_EC:
	pop hl
	jp B14_ReadCmdsNext

; $ED xy: duty step: notes start with duty y, the voice duty comes back after x
; ticks (also on CH3, where it means a wave). ED 0y: off.
B14_Cmd_DutyStep:
	pop hl
	ld a, [de]
	and $F0
	jr nz, .l494B
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_FLAGS
	res 4, [hl]
	jp B14_ReadCmdsNext
.l494B:
	ld l, TRK_FLAGS
	set 4, [hl]
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYRELOAD
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_DUTYSTEP
	ld [hl], a
	jp B14_ReadCmdsNext

B14_Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	ld [wTempoAcc], a
	jp B14_ReadCmdsNext

; $EF: TRK_PAN = raw NR51 bits. On the drum track it skips one byte too many.
B14_Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $06
	jr nz, .l4979
	inc de
	jp B14_ReadCmdsNext
.l4979:
	ld a, [de]
	ld l, TRK_PAN
	ld [hl], a
	call B14_GetPanBits
	ld b, a
	call B14_IsBlocked
	ld a, b
	jp c, B14_ReadCmdsNext
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp B14_ReadCmdsNext

B14_GetPanBits:
	ld a, [wTrackIdx]
	push hl
	call B14_JumpTableInline
	dw B14_PanBits11
	dw B14_PanBits22
	dw B14_PanBits88
	dw B14_PanBits11
	dw B14_PanBits22
	dw B14_PanBits44
	dw B14_PanBits88

B14_PanBits22:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $22
	ld c, a
	ld a, [wNR51]
	and $DD
	ret

B14_PanBits44:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $44
	ld c, a
	ld a, [wNR51]
	and $BB
	ret

B14_PanBits88:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $88
	ld c, a
	ld a, [wNR51]
	and $77
	ret

B14_PanBits11:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $11
	ld c, a
	ld a, [wNR51]
	and $EE
	ret

B14_AutoPan:
	ld a, [wTrackIdx]
	cp $02
	ret z
	ld l, TRK_PAN
	ld a, [hl]
	swap a
	ld [hl], a
	call B14_GetPanBits
	ld b, a
	call B14_IsBlocked
	ld a, b
	ret c
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ret

B14_Cmd_Octave:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B14_RawReader
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp B14_ReadCmdsNext

B14_Cmd_Voice:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B14_RawReader
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, B14_ReadCmdsNext
	inc de
	cp $02
	jr z, .l4A46
	ld a, [de]
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_VOICEDUTY
	ld [hl], a
	call B14_WriteDuty
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
	jp B14_ReadCmdsNext
.l4A46:
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
	call B14_WriteReg
	call B14_Trigger
	jp B14_ReadCmdsNext

; $F0-$FA: attenuation. On the noise SFX track it ends the command reading without
; saving the pointer, so the track would hang (not in the data).
B14_Cmd_Atten:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B14_RawReader
	ld a, [de]
	and $0F
	ld l, TRK_ATTEN
	ld [hl], a
	ld b, a
	ld a, [wTrackIdx]
	cp $02
	jp nz, B14_ReadCmdsNext
	ret
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
	call B14_WriteReg
	call B14_Trigger
	jp B14_ReadCmdsNext

B14_NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	ld c, a
	ld b, $80
	jp B14_WritePeriodBC

; Note: length = (lo nibble) * unit, lo = 0: (unit & 15) * 16; hi 0 = rest; drum
; track plays a sound of this bank. Noise SFX: NR43 = byte, NR44 = $80.
B14_Note:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B14_RawReader
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, B14_AutoPan
	call B14_SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jr z, B14_NoiseNote
	ld a, [de]
	and $0F
	jr nz, .l4AD0
	ld l, TRK_UNIT
	ld a, [hl]
	and $0F
	swap a
	jr .l4ADA
.l4AD0:
	or a
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4AD6:
	add a, c
	dec b
	jr nz, .l4AD6
.l4ADA:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, B14_Rest
	ld l, TRK_FLAGS2
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $06
	jp z, B14_DrumNote
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l4B11
	ld l, TRK_DUTYRELOAD
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
	jr .l4B11

; (unreachable)
	ld l, TRK_FLAGS
	res 4, [hl]
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld [hl], a
	call B14_WriteDuty
.l4B11:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4B1E
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4B30
.l4B1E:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l4B26:
	srl c
	jr nc, .l4B2B
	add a, d
.l4B2B:
	rra
	dec b
	jr nz, .l4B26
	pop de
.l4B30:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l4B48
	ld b, a
	ld c, $0C
	xor a
.l4B43:
	add a, c
	dec b
	jr nz, .l4B43
	ld c, a
.l4B48:
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
	ld hl, B14_PeriodTable
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
	jr z, .l4B7A
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAY
	ld [hl], a
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call B14_VibratoStep
.l4B7A:
	call B14_WritePeriod
	jp B14_NoteFinish

; VibratoTick: wait TRK_VIBTIMER ticks, then step. Steps are one byte now.
B14_VibratoTick:
	ld l, TRK_VIBTIMER
	ld a, [hl]
	or a
	jr z, .l4B88
	dec [hl]
	ret
.l4B88:
	call B14_VibratoStep
	jp B14_WritePeriod

B14_VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l4B9B
	inc b
.l4B9B:
	ld a, [bc]
	cp $FB
	jr z, .l4BE4
	cp $FE
	jr z, .l4BEE
	cp $FF
	jr z, .l4C0C
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l4BBE
	ld l, TRK_FLAGS
	set 3, [hl]
	jr .l4BC2
.l4BBE:
	ld l, TRK_FLAGS
	res 3, [hl]
.l4BC2:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l4BE0
	push bc
	xor a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4BD7:
	add a, c
	dec b
	jp nz, .l4BD7
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l4BE0:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4BE4:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4B9B
.l4BEE:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l4C03
	cp $FF
	jr z, .l4BFA
	inc [hl]
.l4BFA:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp B14_VibratoStep
.l4C03:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4B9B
.l4C0C:
	ret

B14_NoteFinish:
	call B14_NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B14_WriteReg
	jp B14_Trigger

; NoteVolume: (vol - atten - wFadeLevel) << 4 on music tracks, vol - atten on SFX
; (bank 15 still fades the SFX tracks too); CH3: level code as before.
B14_NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4C5C
	ld a, [wTrackIdx]
	cp $03
	jr c, .l4C47
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4C41
	xor a
.l4C41:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4C47:
	xor a
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4C56
	xor a
.l4C56:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4C5C:
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
	jr c, .l4C84
	xor a
.l4C84:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret
	xor a

B14_WritePeriod:
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
	jr z, .l4CA4
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l4CA4:
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

B14_WritePeriodBC:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegIdx], a
	call B14_WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	jp B14_WriteReg

B14_SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

B14_Rest:
	ld l, TRK_FLAGS2
	ld a, $08
	or [hl]
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B14_WriteReg

B14_DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, B14_DrumMap
	rst $28
	ld a, [hl]
	jp B14_PlayDrumSound

B14_WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4D07
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp B14_WriteReg
.l4D07:
	dec a
	push de
	push hl
	ld hl, B14_WaveTable
	call B14_LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l4D15:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l4D15
	pop hl
	pop de
	ret

B14_IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4D2C
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4D35
.l4D2C:
	cp $04
	jr nz, .l4D37
	ld a, [wTrkSfx2]
	or a
	ret z
.l4D35:
	scf
	ret
.l4D37:
	or a
	ret

B14_WriteReg:
	call B14_IsBlocked
	ret c
	push de
	call B14_GetRegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4D57
	ld a, [hl]
	cp c
	jr z, .l4D5A
.l4D57:
	ld a, c
	ld [hl], a
	ld [de], a
.l4D5A:
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B14_Trigger:
	call B14_IsBlocked
	ret c
	push de
	ld a, $04
	ld [wRegIdx], a
	call B14_GetRegAddr
	ld a, [hl]
	or $80
	ld [de], a
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B14_GetRegAddr:
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

B14_GetRegBase:
	ld a, [wTrackIdx]
	push hl
	ld hl, B14_RegBaseTable
	rst $28
	ld a, [hl]
	pop hl
	ret
B14_RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; RawReader: raw streams. $E1 unit duty sweep, then 2-byte frames (vol << 4 |
; period high, period low) of one unit each, 00 = rest. $E9/$EA/$EF work as
; usual, $EB sets the unit. $E7/$E8/$EC/$ED/$EE would jump to RawNoteBack without
; popping HL (not in the data).
B14_RawReader:
	ld l, TRK_RELTICK
	xor a
	ld [hl], a
	ld a, [de]
	cp $E1
	jr nz, B14_RawNext
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
	inc de
	ld a, [de]
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B14_WriteReg
	inc de

B14_RawNext:
	ld a, [de]
	or a
	jp z, B14_RawRest
	ld a, [de]
	cp $E7
	jr c, B14_RawNote
	cp $FB
	jp nc, B14_ReadCmds
	cp $F0
	jr nc, B14_RawNote
	ld a, [de]
	inc de
	sub $E7
	push hl
	call B14_JumpTableInline
	dw B14_RawNoteBack
	dw B14_RawNoteBack
	dw B14_Cmd_Sweep
	dw B14_Cmd_Ext
	dw B14_Cmd_LenUnit
	dw B14_RawNoteBack
	dw B14_RawNoteBack
	dw B14_RawNoteBack
	dw B14_Cmd_Pan

B14_RawNoteBack:
	dec de

B14_RawNote:
	ld l, TRK_PAN
	ld a, [hl]
	call B14_GetPanBits
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
	call B14_WritePeriodBC
	call B14_SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B14_WriteReg
	jp B14_Trigger

B14_RawRest:
	call B14_SavePtr
	dec de
	ld l, TRK_FLAGS2
	set 3, [hl]
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B14_WriteReg

Snd8E_Ch2:
	TRANSPOSE_UP 3
	SND_SEGNO
	LOOP2_START
	VIBRATO_OFF $00
	VOICE 4, $0A, 4, 6, $0F
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	PAN $0F
	ATTEN 5
	LOOP_END 2
	SND_CALL Snd8E_Ch2_4F2E
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	ATTEN 4
	RELEASE 4, $0F
	LOOP_START
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	ATTEN 3
	RELEASE 3, $0F
	LOOP_END 2
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	DUTY 4
	RELEASE 7, $0F
	VIBRATO_OFF $00
	LOOP_START
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	PAN $F0
	ATTEN 5
	LOOP_END 2
	SND_CALL Snd8E_Ch2_4F2E
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 4
	RELEASE 4, $0F
	LOOP_START
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 3
	RELEASE 3, $0F
	LOOP_END 2
	ATTEN 0
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	DUTY 4
	RELEASE 7, $0F
	VIBRATO_OFF $00
	LOOP_START
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN $0F
	ATTEN 5
	LOOP_END 2
	SND_CALL Snd8E_Ch2_4F2E
	RELEASE 5, $0F
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 4
	RELEASE 4, $0F
	LOOP_START
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 3
	RELEASE 3, $0F
	LOOP_END 2
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY 4
	RELEASE 7, $0F
	VIBRATO_OFF $00
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	PAN $F0
	ATTEN 5
	LOOP_END 2
	SND_CALL Snd8E_Ch2_4F2E
	VIBRATO_OFF $00
	RELEASE 5, $0F
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	ATTEN 4
	RELEASE 4, $0F
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE 3, $0E
	DUTY_STEP 0, 1
	ATTEN 1
	RELEASE 3, $0F
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE G#, 2
	DUTY 4
	RELEASE 3, $0F
	DUTY_STEP 0, 0
	OCTAVE 4
	ATTEN 0
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 0
	LOOP2_END 2
	TRANSPOSE_UP 6
	SND_LOOP
Snd8E_Ch2_4F2E:
	DUTY 0
	PAN $FF
	DUTY_STEP 8, 1
	ATTEN 5
	VIBRATO $89, 0, 1
	RELEASE 4, $0F
	SND_RET

Snd8E_Ch1:
	TRANSPOSE_UP 3
	SND_SEGNO
	LOOP2_START
	VOICE 4, 9, 4, 3, $0C
	VIBRATO $88, 0, 0
	ATTEN 3
	PAN $F0
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 2
	PAN $0F
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 3
	PAN $0F
	OCTAVE 3
	NOTE G#, 2
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D#, 2
	PAN $F0
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE D#, 2
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE D#, 2
	ATTEN 3
	PAN $F0
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	PAN $0F
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	PAN $0F
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 2
	PAN $F0
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	PAN $0F
	DUTY 0
	RELEASE 4, $0F
	ATTEN 4
	OCTAVE 4
	NOTE F#, 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE F#, 2
	DUTY 0
	PAN $F0
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	PAN $0F
	NOTE F#, 1
	NOTE C#, 1
	ATTEN 0
	LOOP2_END 2
	TRANSPOSE_UP 6
	SND_LOOP

Snd8E_Ch3:
	TRANSPOSE_UP 3
	SND_SEGNO
	LOOP2_START
	VOICE 4, 2, 1, 6, $0F
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 4
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	LOOP_END 3
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 4
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE F#, 1
	LOOP2_END 2
	TRANSPOSE_UP 6
	SND_LOOP

Snd8E_Drm:
	SND_SEGNO
	DRUM_UNIT 4
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	LOOP_END 7
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	SND_LOOP

Snd8F_Ch2:
	TEMPO $10
	VOICE 6, 8, 0, 2, $0F
	REST 6
	SND_SEGNO
	VOICE 6, 8, 0, 2, $0F
	VIBRATO_OFF $00
	DUTY_STEP 4, 1
	SND_CALL Snd8F_Ch2_51C2
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd8F_Ch2_51C8
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $0F
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd8F_Ch2_51CE
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd8F_Ch2_51D4
	NOTE A#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $0F
	NOTE D_, 1
	NOTE D_, 1
	SND_CALL Snd8F_Ch2_51C2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51C8
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $0F
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51CE
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51D4
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN $0F
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51C2
	NOTE G#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN $F0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	SND_CALL Snd8F_Ch2_51C8
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	SND_CALL Snd8F_Ch2_51CE
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN $F0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	SND_CALL Snd8F_Ch2_51D4
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	SND_CALL Snd8F_Ch2_51C2
	OCTAVE 4
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN $F0
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51C8
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN $0F
	NOTE C#, 1
	NOTE C#, 1
	SND_CALL Snd8F_Ch2_51CE
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 1
	PAN $F0
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 0
	PAN $FF
	VOICE 6, 8, 8, 6, 7
	VIBRATO $87, 3, 2
	SND_CALL Snd8F_Ch1_51DA
	ATTEN 1
	NOTE D#, 6
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 8
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 4
	DUTY 4
	ATTEN 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 8
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 8
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 6
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 6
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 7
	VOICE 6, $0A, 0, 5, $0D
	DUTY_STEP 4, 1
	ATTEN 0
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 0
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	VOICE 6, 7, 8, 6, 7
	DUTY_STEP 4, 1
	LOOP_START
	OCTAVE 3
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, $0A
	OCTAVE 3
	NOTE B_, 2
	LOOP_END 2
	ATTEN 1
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 2
	OCTAVE 5
	NOTE C#, $0A
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 2
	VOICE 6, $0A, 0, 4, $0D
	DUTY_STEP 0, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 2
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 1
	NOTE F#, 1
	NOTE E_, 1
	SND_LOOP
Snd8F_Ch2_51C2:
	PAN $FF
	ATTEN 0
	RELEASE 2, $0E
	SND_RET
Snd8F_Ch2_51C8:
	PAN $FF
	ATTEN 5
	RELEASE 3, $0E
	SND_RET
Snd8F_Ch2_51CE:
	PAN $FF
	ATTEN 4
	RELEASE 3, $0E
	SND_RET
Snd8F_Ch2_51D4:
	PAN $FF
	ATTEN 1
	RELEASE 2, $0E
	SND_RET
Snd8F_Ch1_51DA:
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 8
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	SND_RET

Snd8F_Ch1:
	VOICE 6, 8, 0, 2, $0F
	REST 6
	SND_SEGNO
	VOICE 6, 8, 8, 6, $0E
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 5
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 4
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	ATTEN 5
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 4
	LOOP_START
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 2
	LOOP_START
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 5
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 4
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 2
	LOOP_START
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 1
	LOOP_END 2
	ATTEN 0
	NOTE C#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE F#, 1
	ATTEN 5
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 4
	LOOP_START
	NOTE C#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 2
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	DUTY_STEP 0, 0
	VOICE 6, 7, 8, 6, 7
	VIBRATO $88, 0, 1
	ATTEN 2
	OCTAVE 3
	NOTE D#, 2
	SND_CALL Snd8F_Ch1_51DA
	NOTE D#, 4
	ATTEN 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 8
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE F_, 4
	DUTY 4
	NOTE D#, 2
	NOTE G#, 2
	NOTE A_, 2
	PAN $F0
	NOTE G#, 2
	NOTE A_, 2
	NOTE G#, 2
	PAN $FF
	NOTE C#, 2
	NOTE F#, 2
	NOTE G#, 2
	PAN $0F
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	PAN $FF
	NOTE C#, 2
	NOTE G#, 2
	DUTY 8
	NOTE A_, 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 7
	RELEASE 5, $0A
	PAN $F0
	AUTOPAN 2
	ATTEN 5
	DUTY 4
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	AUTOPAN 0
	ATTEN 0
	DUTY_STEP 4, 1
	VIBRATO $88, 0, 0
	LOOP2_START
	SND_CALL Snd8F_Ch1_534B
	OCTAVE 3
	SND_CALL Snd8F_Ch1_5355
	ATTEN 2
	LOOP_START
	NOTE A_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	DUTY 0
	ATTEN 0
	PAN $F0
	LOOP_END 2
	LOOP2_END 2
	SND_CALL Snd8F_Ch1_534B
	OCTAVE 4
	SND_CALL Snd8F_Ch1_5355
	ATTEN 2
	LOOP_START
	NOTE A_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	DUTY 0
	ATTEN 0
	OCTAVE 3
	PAN $F0
	LOOP_END 2
	SND_CALL Snd8F_Ch1_534B
	OCTAVE 4
	NOTE A#, 3
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 1
	ATTEN 0
	ATTEN 4
	PAN $F0
	AUTOPAN 2
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	AUTOPAN 0
	PAN $FF
	SND_LOOP
Snd8F_Ch1_534B:
	RELEASE 6, $0A
	DUTY 8
	DUTY_STEP 0, 0
	PAN $0F
	ATTEN 4
	SND_RET
Snd8F_Ch1_5355:
	NOTE A#, 3
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 1
	ATTEN 1
	DUTY 8
	RELEASE 4, $0F
	PAN $FF
	SND_RET

Snd8F_Ch3:
	VOICE 6, 2, 1, 2, $0F
	REST 6
	SND_SEGNO
	VOICE 6, 2, $0E, 3, $0A
	LOOP_START
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	LOOP_END $16
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE G#, 2
	LOOP_END 2
	LOOP2_START
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	LOOP_START
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_END 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	LOOP2_END 3
	LOOP2_START
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	LOOP_START
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_END 2
	LOOP2_END 2
	LOOP2_START
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	LOOP_START
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	LOOP_END 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	LOOP2_END 4
	LOOP_START
	OCTAVE 1
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE D_, 2
	LOOP_END 3
	OCTAVE 1
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE G#, 2
	OCTAVE 1
	NOTE E_, 2
	SND_LOOP

Snd8F_Drm:
	DRUM_UNIT 6
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	SND_SEGNO
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 4
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_START
	DRUM 6, 1
	LOOP_END $0C
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 1, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 6, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 2
	SND_LOOP

Snd90_Ch2:
	TEMPO $08
	VOICE 3, 8, 0, 0, 0
	SND_CALL Snd90_Ch1_54FF
	NOTE D_, 1
	NOTE D#, 1
	SND_SEGNO
	VOICE 6, 9, 0, 2, $0E
	DUTY_STEP 4, 1
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch2_54B9
	TRANSPOSE_UP 2
	SND_CALL Snd90_Ch2_54B9
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch2_54B9
	TRANSPOSE_UP 2
	SND_CALL Snd90_Ch2_54B9
	VOICE 6, 8, 0, 2, $0F
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch2_54C9
	TRANSPOSE_DOWN 1
	SND_CALL Snd90_Ch2_54C9
	SND_LOOP
Snd90_Ch2_54B9:
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	LOOP_END 2
	SND_RET
Snd90_Ch2_54C9:
	DUTY 4
	RELEASE 5, $0F
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE A#, 1
	RELEASE 4, $0F
	DUTY 8
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 2
	NOTE E_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	SND_RET
Snd90_Ch1_54FF:
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 2
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
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	SND_RET

Snd90_Ch1:
	VOICE 3, 6, 0, 8, 8
	ATTEN 3
	PAN $F0
	REST 2
	SND_CALL Snd90_Ch1_54FF
	ATTEN 0
	SND_SEGNO
	VOICE 6, 6, 0, 3, $0E
	DUTY_STEP 8, 1
	VIBRATO 8, 0, 0
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch1_555B
	TRANSPOSE_UP 2
	SND_CALL Snd90_Ch1_555B
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch1_555B
	TRANSPOSE_UP 2
	SND_CALL Snd90_Ch1_555B
	RELEASE 5, $0E
	DUTY 4
	TRANSPOSE_UP 0
	SND_CALL Snd90_Ch1_557A
	TRANSPOSE_DOWN 1
	SND_CALL Snd90_Ch1_557A
	SND_LOOP
Snd90_Ch1_555B:
	OCTAVE 3
	LOOP_START
	PAN $F0
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 2
	PAN $0F
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 4
	ATTEN 0
	LOOP_END 2
	ATTEN 2
	PAN $F0
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	PAN $0F
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	ATTEN 0
	SND_RET
Snd90_Ch1_557A:
	OCTAVE 2
	NOTE G#, 1
	PAN $0F
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 2
	PAN $FF
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 1
	PAN $0F
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 0
	PAN $FF
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 1
	PAN $F0
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 2
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	ATTEN 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_RET

Snd90_Ch3:
	VOICE 6, 2, $0A, 3, $0F
	REST 0
	SND_SEGNO
	VOICE 6, 2, 1, 3, $0F
	TRANSPOSE_UP 0
	LOOP2_START
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	LOOP_START
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	LOOP_END 2
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	SND_LOOP

Snd90_Drm:
	DRUM_UNIT 6
	REST $0C
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	LOOP_START
	DRUM 6, 1
	LOOP_END 8
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	SND_LOOP
	db $FF

Snd93_Ch2:
	TEMPO $16
	VOICE $10, 3, 4, $0F, $0A
	PAN $0F
	VIBRATO 8, 0, 10
	OCTAVE 1
	NOTE C_, $0C
	PAN $FF
	VIBRATO 8, 0, 4
	VOICE $10, 8, 8, 0, 0
	ATTEN 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE F#, 4
	NOTE C_, 4
	NOTE F#, $0C
	VIBRATO $89, 0, 0
	VOICE 6, $0C, 8, 2, $0F
	VIBRATO_OFF $00
	ATTEN 3
	SND_CALL Snd93_Ch1_56DA
	TRANSPOSE_UP 4
	SND_CALL Snd93_Ch1_56DA
	TRANSPOSE_UP 8
	ATTEN 2
	SND_CALL Snd93_Ch1_56DA
	LEN_UNIT 4
	ATTEN 1
	TRANSPOSE_UP $0B
	SND_CALL Snd93_Ch1_56DA
	TRANSPOSE_UP 0
	ATTEN 0
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	SND_SEGNO
	VIBRATO_OFF $00
	DUTY_STEP 0, 1
	SND_CALL Snd93_Ch2_56E9
	DUTY 8
	DUTY_STEP 4, 1
	SND_CALL Snd93_Ch2_56FE
	VOICE 6, $0B, 0, 2, $0E
	TRANSPOSE_UP $0C
	DUTY_STEP 0, 0
	SND_CALL Snd93_Ch2_56FE
	TRANSPOSE_UP 2
	DUTY_STEP 0, 1
	SND_CALL Snd93_Ch2_56E9
	DUTY 8
	DUTY_STEP 4, 1
	SND_CALL Snd93_Ch2_56FE
	TRANSPOSE_UP $0E
	VOICE 6, 8, 0, 2, $0E
	DUTY_STEP 0, 0
	SND_CALL Snd93_Ch2_56FE
	TRANSPOSE_UP 0
	SND_LOOP
Snd93_Ch1_56DA:
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_RET
Snd93_Ch2_56E9:
	VOICE 6, $0C, 4, 1, $0F
	DUTY_STEP 8, 1
	LOOP_START
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 0
	LOOP_END 4
	SND_RET
Snd93_Ch2_56FE:
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	PAN $FF
	ATTEN 0
	SND_RET

Snd93_Ch1:
	VOICE $10, 1, 4, $0F, $0A
	VIBRATO 10, 0, 4
	PAN $F0
	OCTAVE 1
	NOTE C_, $0C
	PAN $0F
	VOICE $10, 5, 8, 0, 0
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE F#, 4
	NOTE C_, 4
	NOTE F#, $0B
	VOICE 6, 9, 8, 5, $0F
	VIBRATO_OFF $00
	REST 2
	PAN $0F
	ATTEN 5
	SND_CALL Snd93_Ch1_56DA
	TRANSPOSE_UP 4
	SND_CALL Snd93_Ch1_56DA
	ATTEN 4
	TRANSPOSE_UP 8
	SND_CALL Snd93_Ch1_56DA
	LEN_UNIT 4
	TRANSPOSE_UP $0B
	SND_CALL Snd93_Ch1_56DA
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	TRANSPOSE_UP 0
	SND_SEGNO
	VIBRATO $88, 0, 0
	TRANSPOSE_UP 0
	DUTY_STEP 4, 1
	VOICE 6, 8, 0, 2, $0F
	SND_CALL Snd93_Ch1_5798
	DUTY 8
	SND_CALL Snd93_Ch1_57CA
	TRANSPOSE_UP $0C
	DUTY 0
	SND_CALL Snd93_Ch1_57F4
	TRANSPOSE_UP 2
	SND_CALL Snd93_Ch1_5798
	DUTY 8
	SND_CALL Snd93_Ch1_57CA
	TRANSPOSE_UP $0E
	DUTY 0
	SND_CALL Snd93_Ch1_57F4
	SND_LOOP
Snd93_Ch1_5798:
	LOOP_START
	PAN $F0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	PAN $0F
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	LOOP_END 2
	SND_RET
Snd93_Ch1_57CA:
	PAN $F0
	AUTOPAN 0
	RELEASE 2, $0F
	DUTY 4
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	PAN $0F
	LOOP_END 2
	PAN $FF
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	SND_RET
Snd93_Ch1_57F4:
	ATTEN 3
	PAN $0F
	OCTAVE 4
	NOTE D#, 2
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	PAN $F0
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	PAN $0F
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	PAN $F0
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	PAN $FF
	ATTEN 0
	SND_RET

Snd93_Ch3:
	VOICE $10, 2, $0C, 0, 0
	VIBRATO 7, 0, 3
	OCTAVE 2
	NOTE C_, 0
	NOTE C_, $0C
	OCTAVE 1
	NOTE B_, $0C
	TRANSPOSE_DOWN $0C
	PAN $FF
	VOICE 6, 4, 1, 7, 8
	VIBRATO_OFF $00
	SND_CALL Snd93_Ch3_58C0
	TRANSPOSE_DOWN 8
	SND_CALL Snd93_Ch3_58C0
	TRANSPOSE_DOWN 4
	SND_CALL Snd93_Ch3_58C0
	LEN_UNIT 4
	TRANSPOSE_DOWN 1
	SND_CALL Snd93_Ch3_58C0
	TRANSPOSE_UP 0
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	TRANSPOSE_UP 0
	SND_SEGNO
	TRANSPOSE_UP 0
	ATTEN 0
	VOICE 6, 2, 1, 3, $0D
	SND_CALL Snd93_Ch3_5873
	SND_CALL Snd93_Ch3_58A8
	TRANSPOSE_UP 2
	SND_CALL Snd93_Ch3_5873
	SND_CALL Snd93_Ch3_58A8
	SND_LOOP
Snd93_Ch3_5873:
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_START
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_END 2
	SND_RET
Snd93_Ch3_58A8:
	LOOP_START
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_END 4
	SND_RET
Snd93_Ch3_58C0:
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	SND_RET

Snd93_Drm:
	DRUM_UNIT $10
	REST 0
	REST $0C
	REST 8
	DRUM 3, 4
	DRUM_UNIT 6
	LOOP_START
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM_UNIT 4
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_END 3
	LOOP_START
	DRUM $0D, 1
	DRUM $0D, 1
	LOOP_END 3
	SND_SEGNO
	SND_CALL Snd93_Drm_590A
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	SND_CALL Snd93_Drm_590A
	DRUM 6, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0C, 1
	DRUM $0C, 1
	SND_LOOP
Snd93_Drm_590A:
	DRUM_UNIT 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 6, 1
	SND_RET

Snd91_Ch2:
	TRANSPOSE_UP 1
	SND_SEGNO
	SND_CALL Snd91_Ch2_5B2F
	VOICE 4, 8, 4, 3, $0E
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_CALL Snd91_Ch2_5B2F
	VOICE 6, 8, 8, 4, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE 2, 8, 8, 4, 8
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 2
	LEN_UNIT 6
	VIBRATO 11, 1, 3
	OCTAVE 4
	NOTE D_, 5
	ATTEN 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	ATTEN 0
	NOTE C_HI, 6
	ATTEN 1
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 6
	ATTEN 1
	NOTE B_, 1
	NOTE G_, 1
	VIBRATO_OFF $00
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	LEN_UNIT 2
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 2
	LEN_UNIT 6
	VIBRATO 11, 1, 3
	NOTE D_, 5
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE B_, 6
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 8
	VOICE 6, 9, 8, 1, $0F
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	VOICE 2, 8, 8, 4, 8
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 2
	LEN_UNIT 6
	VIBRATO 11, 1, 2
	OCTAVE 4
	NOTE G_, 5
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 5
	VIBRATO_OFF $00
	VOICE 6, 9, 4, 3, $0A
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	VOICE 6, 8, 8, 4, 8
	NOTE D#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	VIBRATO 11, 1, 2
	NOTE G_, 7
	ATTEN 5
	NOTE G_, 7
	ATTEN 0
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 4
	ATTEN 5
	NOTE F#, 4
	ATTEN 0
	VOICE 6, 8, 0, 2, $0E
	ATTEN 2
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	ATTEN 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	DUTY_STEP 0, 0
	VOICE 6, 9, 8, 1, $0F
	OCTAVE 3
	NOTE G_, 2
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 3
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 4
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 1
	ATTEN 0
	NOTE A_, 2
	RELEASE 1, $0D
	PAN $0F
	ATTEN 3
	NOTE A_, 2
	PAN $FF
	RELEASE 4, $0F
	DUTY_STEP 8, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	DUTY_STEP 0, 0
	VOICE 6, 9, 8, 1, $0F
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 3
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 4
	SND_CALL Snd91_Ch2_5BA3
	TRANSPOSE_UP 1
	ATTEN 0
	NOTE C_HI, 2
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 4, $0F
	ATTEN 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	VOICE 6, 8, 4, 4, $0A
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	VIBRATO 11, 1, 2
	NOTE G_, 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 4
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 2
	RELEASE 1, $0A
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	LEN_UNIT 1
	RELEASE 0, 0
	ATTEN 3
	NOTE A#, 4
	ATTEN 0
	NOTE A#, $0E
	ATTEN 3
	NOTE A_, 4
	ATTEN 0
	NOTE A_, $0E
	ATTEN 3
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 9
	LEN_UNIT 6
	RELEASE 6, $0F
	NOTE A_, 6
	NOTE F_, 6
	NOTE C_, 5
	VOICE 1, $0F, 4, 4, $0F
	PAN $F0
	OCTAVE 3
	NOTE F_, 5
	REST 1
	OCTAVE 4
	NOTE F_, 5
	REST 1
	OCTAVE 3
	NOTE F_, 5
	REST 1
	PAN $FF
	VOICE 6, 7, 4, 1, $0F
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	PAN $0F
	VOICE 1, $0F, 4, 4, $0F
	NOTE F_, 5
	REST 1
	OCTAVE 3
	NOTE F_, 5
	REST 1
	NOTE A_, 5
	REST 1
	NOTE F_, 5
	REST 1
	PAN $FF
	VOICE 6, 7, 4, 1, $0F
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	VOICE 6, 8, 4, 4, $0A
	ATTEN 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	VIBRATO 11, 1, 2
	NOTE G_, 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 3
	RELEASE 2, $0F
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 4
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 4
	RELEASE 4, $0A
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 3
	RELEASE 2, $0F
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 4, $0A
	VIBRATO 11, 1, 2
	NOTE A_, 9
	VIBRATO_OFF $00
	NOTE C_, 1
	NOTE F_, 2
	NOTE A_, 1
	VIBRATO 11, 1, 2
	VOICE 6, 8, 4, 5, $0B
	OCTAVE 4
	NOTE G_, $0C
	RELEASE 4, $0F
	ATTEN 2
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	RELEASE 5, $0E
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 5, $0B
	VIBRATO 11, 1, 3
	NOTE B_, 8
	RELEASE 2, $0F
	VIBRATO_OFF $00
	ATTEN 1
	DUTY 0
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 0
	SND_LOOP
Snd91_Ch2_5B2F:
	VOICE 6, 9, 0, 2, $0F
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 0
	LEN_UNIT 4
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	LEN_UNIT 6
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 4
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 0
	LEN_UNIT 4
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	LEN_UNIT 6
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	LEN_UNIT 4
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	LEN_UNIT 6
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE D_, 1
	SND_RET
Snd91_Ch2_5BA3:
	ATTEN 0
	OCTAVE 4
	NOTE G_, 2
	PAN $0F
	RELEASE 1, $0D
	ATTEN 2
	NOTE G_, 2
	PAN $F0
	ATTEN 4
	NOTE G_, 2
	PAN $FF
	SND_RET

Snd91_Ch1:
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP_START
	VOICE 6, 6, 4, 2, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	VOICE 4, 6, 4, 1, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 2
	ATTEN 0
	VOICE 6, 6, 4, 2, $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 3
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 0
	VOICE 4, 6, 4, 1, $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 2
	ATTEN 0
	VOICE 6, 6, 4, 1, 9
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 3
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	ATTEN 0
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	VOICE 4, 6, 4, 3, $0E
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	VOICE 6, 6, 4, 1, 9
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	VOICE 4, 6, 4, 3, $0E
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	VOICE 6, 9, 8, 4, 8
	VIBRATO 11, 1, 2
	PAN $F0
	OCTAVE 3
	NOTE B_, 6
	ATTEN 1
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 0
	PAN $0F
	NOTE A_, 6
	ATTEN 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 0
	PAN $F0
	NOTE G_, 6
	ATTEN 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	VIBRATO_OFF $00
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	ATTEN 0
	PAN $F0
	VIBRATO 11, 1, 2
	PAN $0F
	NOTE B_, 6
	ATTEN 1
	NOTE F_, 1
	NOTE A_, 1
	ATTEN 0
	PAN $F0
	NOTE G_, 6
	ATTEN 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	ATTEN 3
	OCTAVE 2
	NOTE B_, 8
	ATTEN 0
	RELEASE 1, $0F
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	PAN $F0
	VOICE 6, 9, 8, 4, 8
	VIBRATO 11, 1, 1
	OCTAVE 4
	NOTE D#, 6
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 5
	VIBRATO_OFF $00
	PAN $FF
	DUTY_STEP 4, 1
	VOICE 6, 6, 0, 2, $0B
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	DUTY_STEP 0, 0
	ATTEN 3
	VOICE 6, 9, 8, 4, 8
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE 0, $0F
	PAN $0F
	ATTEN 0
	VIBRATO 11, 1, 2
	NOTE C_HI, 7
	ATTEN 5
	NOTE C_HI, 7
	ATTEN 0
	ATTEN 3
	PAN $FF
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 0
	PAN $F0
	NOTE D_, 4
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	PAN $FF
	DUTY_STEP 4, 1
	VOICE 6, 6, 8, 2, $0B
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	DUTY_STEP 0, 0
	VOICE 6, 7, 8, 2, $0C
	ATTEN 4
	OCTAVE 2
	NOTE A#, 2
	ATTEN 0
	OCTAVE 3
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	DUTY 4
	ATTEN 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 2
	DUTY 4
	ATTEN 1
	OCTAVE 2
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	VOICE 6, 6, 8, 4, $0A
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 4
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 4
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 2
	RELEASE 1, $0A
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT 1
	RELEASE 0, 0
	ATTEN 2
	NOTE G_, 4
	ATTEN 0
	NOTE G_, $0E
	ATTEN 2
	NOTE D#, 4
	ATTEN 0
	NOTE D#, $0E
	ATTEN 2
	OCTAVE 3
	NOTE A#, 3
	ATTEN 0
	NOTE A#, 9
	ATTEN 0
	LEN_UNIT 6
	RELEASE 4, $0A
	OCTAVE 4
	NOTE F_, 6
	NOTE C_, 6
	OCTAVE 3
	NOTE F_, 5
	ATTEN 1
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	RELEASE 2, $0B
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	VOICE 6, 6, 8, 5, $0B
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 4
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE F_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 3
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 9
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 1
	VOICE 6, 6, 8, 5, $0B
	VIBRATO 11, 1, 2
	OCTAVE 3
	NOTE B_, $0C
	RELEASE 4, 8
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 2
	RELEASE 5, $0B
	NOTE G_, 8
	DUTY 4
	RELEASE 2, $0F
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	SND_LOOP

Snd91_Ch3:
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP_START
	VOICE 6, 2, $0B, 2, $0B
	LOOP2_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	NOTE E_, 1
	RELEASE 2, $0B
	LOOP2_END 3
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE D_, 1
	RELEASE 4, $0A
	NOTE E_, 2
	RELEASE 2, $0B
	NOTE C_, 1
	LOOP2_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	NOTE E_, 1
	RELEASE 2, $0B
	LOOP2_END 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE D_, 1
	RELEASE 4, $0A
	NOTE G_, 2
	NOTE D_, 1
	RELEASE 2, $0B
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END 2
	LOOP_START
	VOICE 6, 2, $0B, 2, $0B
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 1
	NOTE F_, 1
	LOOP_END 8
	LOOP_START
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END 6
	OCTAVE 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE A#, 1
	NOTE A#, 1
	LOOP_END 8
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE A_, 1
	LOOP_END 6
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	VOICE 6, 2, $0B, 2, $0B
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	LOOP_END 3
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	VOICE 6, 2, $0B, 2, $0B
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE D#, 1
	LOOP_END 3
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G_, 1
	LOOP_START
	NOTE C_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	LOOP_END 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE D#, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP2_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE B_, 1
	RELEASE 4, $0A
	OCTAVE 2
	NOTE G_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE B_, 1
	LOOP_END 3
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G_, 1
	SND_LOOP

Snd91_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	LOOP2_START
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
	LOOP_END 2
	SND_CALL Snd91_Drm_5FAA
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP2_END 2
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
	LOOP_END 4
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
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
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM_UNIT 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM_UNIT 6
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	SND_CALL Snd91_Drm_5FAA
	LOOP_END 4
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM_UNIT 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM_UNIT 6
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP
Snd91_Drm_5FAA:
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
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_RET

Snd92_Ch2:
	TEMPO $20
	VOICE 4, 8, 8, 1, 9
	DUTY_STEP 0, 1
	LOOP2_START
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	OCTAVE 4
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	ATTEN 5
	OCTAVE 4
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	LOOP2_END 2
	SND_SEGNO
	LOOP2_START
	DUTY_STEP 0, 1
	VOICE 8, 6, 4, $0B, $0E
	VIBRATO 14, 0, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 3
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE A#, 1
	NOTE G#, 3
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G#, 1
	NOTE G_, 3
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 3
	VOICE 4, 8, 4, 0, $0F
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	ATTEN 5
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 5
	NOTE A#, 1
	ATTEN 0
	LOOP_END 2
	VOICE 8, 6, 4, $0B, $0E
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F#, 3
	VOICE 4, 8, 4, 0, $0F
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	LOOP_END 2
	LOOP2_END 2
	VOICE 8, 8, 8, 4, 6
	VIBRATO 13, 0, 5
	LOOP_START
	OCTAVE 3
	NOTE G_, 9
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 3
	VOICE 4, 9, 0, 0, 0
	VIBRATO_OFF $00
	ATTEN 6
	OCTAVE 4
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 6
	NOTE C_HI, 1
	ATTEN 7
	NOTE C_HI, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 4
	NOTE C_HI, 1
	ATTEN 7
	NOTE C_HI, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 2
	NOTE C_HI, 1
	ATTEN 7
	NOTE C_HI, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 7
	NOTE C_HI, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 0
	VOICE 8, 8, 8, 4, 6
	VIBRATO 13, 0, 5
	OCTAVE 3
	NOTE G_, 9
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 5
	NOTE A_, 4
	NOTE F_, 3
	LOOP_END 2
	VOICE 8, 6, 4, $0B, $0E
	VIBRATO 14, 0, 3
	LOOP_START
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 3
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE A#, 1
	NOTE G#, 3
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G#, 1
	NOTE G_, 3
	LOOP_END 2
	DUTY_STEP 0, 0
	VOICE 8, 8, 8, 5, 8
	VIBRATO 13, 0, 3
	OCTAVE 3
	NOTE B_, 9
	NOTE D#, 1
	NOTE G#, 1
	NOTE B_, 1
	LEN_UNIT 4
	OCTAVE 4
	NOTE D_, 9
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, $0C
	LEN_UNIT 8
	NOTE B_, 9
	NOTE D#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A#, 1
	VIBRATO_OFF $00
	DUTY 0
	ATTEN 2
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	DUTY 8
	VIBRATO 13, 0, 2
	NOTE E_, 9
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	LEN_UNIT 4
	NOTE G_, 9
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, $0C
	LEN_UNIT 8
	NOTE E_, 9
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE D#, 1
	VIBRATO_OFF $00
	DUTY 0
	ATTEN 2
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	ATTEN 0
	SND_LOOP

Snd92_Ch1:
	VOICE 8, 6, 8, 1, $0A
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	LOOP2_END 2
	SND_SEGNO
	LOOP2_START
	VOICE 8, 4, 4, $0C, $0C
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 3
	VOICE 8, 8, 8, 4, 8
	PAN $F0
	REST 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 3
	PAN $0F
	RELEASE 1, $0F
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A#, 1
	LOOP_END 2
	RELEASE 4, 8
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F#, 3
	PAN $F0
	RELEASE 1, $0F
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G#, 1
	PAN $FF
	LOOP2_END 2
	VOICE 8, 6, 8, 4, 6
	LOOP_START
	OCTAVE 3
	NOTE D#, 9
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 3
	NOTE F#, 9
	VOICE 8, 6, 8, 4, 6
	OCTAVE 3
	NOTE D#, 9
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 5
	NOTE F_, 4
	NOTE C_, 3
	LOOP_END 2
	VOICE 8, 4, 4, $0C, $0C
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 3
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 3
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 3
	LOOP_END 2
	VOICE 8, 6, 8, 5, 8
	OCTAVE 3
	NOTE G#, 9
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	NOTE F_, $0C
	NOTE G#, 9
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	REST $0C
	OCTAVE 4
	NOTE C#, 9
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, $0C
	OCTAVE 4
	NOTE C#, 9
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	REST $0C
	SND_LOOP

Snd92_Ch3:
	VOICE 8, 4, $0B, 2, $0B
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 3
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	LEN_UNIT 4
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_SEGNO
	VOICE 8, 4, $0B, 2, $0B
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 6
	LOOP2_END 2
	VOICE 8, 4, $0B, 2, $0B
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 1
	LOOP_END 6
	LOOP_START
	NOTE C_, 1
	NOTE C_HI, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 1
	LOOP_END 6
	VOICE 8, 2, $0B, 2, $0C
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	LOOP2_END 2
	VOICE 8, 4, $0B, 2, $0B
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_END 6
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	LOOP_END 6
	LOOP2_END 2
	VOICE 8, 2, $0B, 2, $0D
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END 6
	LOOP2_END 3
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	LOOP_END 6
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	LOOP_END 6
	LOOP2_END 3
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	LOOP_END 6
	SND_LOOP

Snd92_Drm:
	DRUM_UNIT 8
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 7
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 7, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 4
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 8
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0D, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 8
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM_UNIT 8
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 4
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM_UNIT 8
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 8
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM_UNIT 8
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM 9, 1
	DRUM 9, 1
	DRUM_UNIT 8
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM_UNIT 4
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 8
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0D, 1
	SND_LOOP

Snd94_Ch2:
	VOICE 6, 6, 8, 6, $0B
	OCTAVE 2
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	LEN_UNIT 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	SND_SEGNO
	VOICE 6, $0C, 4, 1, $0F
	LOOP_START
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END 4
	VOICE 6, $0D, 8, 1, $0F
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	ATTEN 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	TRANSPOSE_UP $0C
	VOICE 6, $0B, 0, 1, $0E
	DUTY_STEP 0, 0
	LOOP_END 2
	TRANSPOSE_UP 2
	VOICE 6, $0C, 4, 1, $0E
	LOOP_START
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END 4
	TRANSPOSE_UP 2
	VOICE 6, $0D, 8, 1, $0E
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	ATTEN 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	ATTEN 0
	TRANSPOSE_UP $0E
	VOICE 6, $0B, 0, 1, $0E
	DUTY_STEP 0, 0
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE 6, $0C, 4, 1, $0E
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	ATTEN 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	LOOP_END 2
	VOICE 6, $0D, 8, 1, $0F
	LOOP_START
	OCTAVE 3
	DUTY_STEP 0, 1
	NOTE B_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 3
	VOICE 6, $0C, 4, 1, $0D
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	ATTEN 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 3
	VOICE 6, $0D, 8, 1, $0E
	LOOP_START
	OCTAVE 3
	DUTY_STEP 0, 1
	NOTE B_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE 6, $0C, 8, 2, $0E
	OCTAVE 4
	NOTE G_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE C#, 1
	VOICE 6, 9, 8, 2, $0E
	ATTEN 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	LEN_UNIT 4
	OCTAVE 4
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	ATTEN 0
	LEN_UNIT 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE C#, 1
	SND_LOOP

Snd94_Ch1:
	VOICE 6, 6, 8, 6, $0B
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	LEN_UNIT 4
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	SND_SEGNO
	VOICE 6, 8, 0, 2, $0F
	PAN $F0
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	PAN $0F
	ATTEN 0
	LOOP_END 2
	PAN $F0
	LOOP2_END 2
	VOICE 6, 8, 4, 2, $0F
	LOOP2_START
	PAN $F0
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN 0
	PAN $0F
	LOOP_END 2
	PAN $FF
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	TRANSPOSE_UP $0C
	LOOP2_END 2
	TRANSPOSE_UP 2
	VOICE 6, 8, 0, 2, $0E
	PAN $F0
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	ATTEN 0
	PAN $0F
	LOOP_END 2
	PAN $F0
	LOOP2_END 2
	TRANSPOSE_UP 2
	VOICE 6, 8, 4, 2, $0E
	LOOP2_START
	PAN $F0
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN 0
	PAN $0F
	LOOP_END 2
	PAN $FF
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	TRANSPOSE_UP $0E
	LOOP2_END 2
	TRANSPOSE_UP 0
	VOICE 6, 8, 0, 2, $0E
	PAN $F0
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	PAN $0F
	LOOP_END 2
	PAN $FF
	TRANSPOSE_UP 0
	VOICE 6, 8, 4, 2, $0E
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 3
	VOICE 6, 8, 0, 2, $0D
	PAN $F0
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	PAN $0F
	LOOP_END 2
	PAN $FF
	TRANSPOSE_UP 0
	VOICE 6, 8, 4, 2, $0E
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE 6, 8, 4, 2, $0E
	OCTAVE 4
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	VOICE 6, $0A, 4, 2, $0D
	ATTEN 2
	OCTAVE 1
	NOTE B_, 1
	NOTE F#, 1
	ATTEN 1
	LEN_UNIT 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	ATTEN 0
	LEN_UNIT 3
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_LOOP

Snd94_Ch3:
	VOICE 6, 2, 7, 6, $0B
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE C_HI, 1
	LEN_UNIT 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	SND_SEGNO
	VOICE 6, 2, 1, 3, $0D
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	VOICE 6, 2, 1, 3, $0D
	LOOP_START
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_END 4
	TRANSPOSE_UP 2
	VOICE 6, 2, 1, 3, $0D
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	TRANSPOSE_UP 2
	VOICE 6, 2, 1, 3, $0D
	LOOP_START
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	LOOP_END 4
	TRANSPOSE_UP 0
	VOICE 6, 2, 1, 3, $0D
	LOOP_START
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	LOOP_END 2
	VOICE 6, 2, 1, 3, $0C
	LOOP_START
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	VOICE 6, 2, 1, 3, $0C
	LOOP_START
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	VOICE 6, 2, 1, 3, $0B
	LOOP_START
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE 6, 2, 1, 3, $0E
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE F#, 1
	VOICE 6, 2, 3, 2, $0E
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	LEN_UNIT 4
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	LEN_UNIT 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_LOOP

Snd94_Drm:
	DRUM_UNIT 6
	LOOP_START
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 6
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_SEGNO
	DRUM_UNIT 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 2
	DRUM_UNIT 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 2
	DRUM_UNIT 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 2
	DRUM_UNIT 6
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	LOOP_END 2
	DRUM_UNIT 6
	LOOP_START
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END 2
	DRUM_UNIT 6
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LEN_UNIT 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_LOOP

Snd95_Ch2:
	VOICE 2, $0C, 8, 4, 8
	OCTAVE 3
	NOTE G#, 1
	DUTY_STEP 0, 0
	NOTE A_, 3
	LEN_UNIT 8
	ATTEN 5
	NOTE A_, 3
	ATTEN 0
	DUTY_STEP 0, 2
	NOTE D_, 1
	ATTEN 5
	DUTY_STEP 0, 0
	NOTE D_, 3
	ATTEN 0
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE D_, 1
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE D_, 3
	ATTEN 0
	DUTY_STEP 0, 2
	RELEASE 1, $0B
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	RELEASE 4, $0A
	NOTE G_, 2
	RELEASE 0, 8
	NOTE A_, 1
	DUTY_STEP 0, 0
	ATTEN 5
	VIBRATO 1, 5, 4
	RELEASE $0B, 7
	NOTE A_, $0B
	ATTEN $0A
	NOTE A_, 1
	ATTEN 0
	VIBRATO_OFF $00
	DUTY_STEP 0, 2
	RELEASE 1, $0A
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	VOICE 2, $0C, 8, 4, 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 3
	LEN_UNIT 8
	ATTEN 5
	NOTE C_HI, 3
	ATTEN 0
	DUTY_STEP 0, 2
	NOTE F_, 1
	DUTY_STEP 0, 0
	ATTEN 5
	NOTE F_, 3
	ATTEN 0
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE F_, 1
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE F_, 3
	ATTEN 0
	DUTY_STEP 0, 2
	RELEASE 1, $0C
	NOTE D#, 1
	NOTE D_, 1
	RELEASE 4, $0A
	OCTAVE 3
	NOTE A#, 2
	ATTEN 0
	VIBRATO 1, 5, 4
	RELEASE 0, 8
	NOTE C_HI, 1
	DUTY_STEP 0, 0
	ATTEN 5
	RELEASE $0B, 7
	NOTE C_HI, $0A
	ATTEN $0A
	NOTE C_HI, 1
	ATTEN 0
	VIBRATO_OFF $00
	DUTY_STEP 0, 1
	RELEASE 1, $0A
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	RELEASE 1, $0F
	NOTE A_, 1
	NOTE C_HI, 1
	DUTY_STEP 0, 1
	RELEASE 1, 1
	VIBRATO 2, 8, 2
	LEN_UNIT $0C
	OCTAVE 4
	NOTE D_, 0
	VIBRATO_OFF $00
	LEN_UNIT $0F
	REST 2
	VOICE 1, 5, 0, 0, 0
	OCTAVE 5
	NOTE D_, 4
	ATTEN 1
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D#, 3
	ATTEN 2
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 3
	OCTAVE 3
	ATTEN 1
	NOTE B_, 3
	NOTE A#, 3
	NOTE A_, 3
	NOTE G#, 3
	NOTE G_, 3
	ATTEN 0
	VOICE $0B, 7, 4, 6, 8
	VIBRATO 2, 0, 1
	OCTAVE 2
	NOTE B_, 4
	RELEASE 4, 9
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 7, 5
	NOTE D_, 6
	NOTE G_, 1
	RELEASE 1, $0C
	NOTE B_, 1
	RELEASE 7, 5
	NOTE B_, 6
	NOTE C_HI, 2
	RELEASE 5, 4
	VIBRATO 2, 3, 4
	NOTE A_, 9
	VIBRATO_OFF $00
	REST 4
	ATTEN 8
	NOTE C_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE 5, $0B
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 3
	RELEASE 7, 8
	NOTE C_, 2
	RELEASE 3, 2
	VIBRATO 1, 5, 3
	OCTAVE 3
	NOTE B_, 8
	DUTY 0
	VIBRATO_OFF $00
	RELEASE 6, $0C
	OCTAVE 4
	NOTE C_, 4
	RELEASE 6, $0A
	NOTE D_, 4
	VOICE $0B, 7, 4, 5, 8
	REST 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 4, 8
	NOTE D_, 2
	RELEASE 5, 8
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 4, 8
	NOTE G_, 2
	RELEASE 3, $0A
	NOTE B_, 1
	RELEASE 1, $0C
	OCTAVE 4
	NOTE D_, 1
	VIBRATO 2, 3, 3
	RELEASE 4, 3
	NOTE D_, 6
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE 3, 3
	OCTAVE 4
	NOTE C_, 7
	RELEASE 1, $0C
	NOTE E_, 1
	VIBRATO 2, 3, 3
	RELEASE 4, 4
	NOTE E_, 5
	VIBRATO_OFF $00
	NOTE F#, 1
	NOTE D_, 1
	NOTE C_, 1
	RELEASE 4, 4
	NOTE D_, 5
	RELEASE 5, 8
	NOTE D_, 1
	NOTE F#, 2
	VOICE $0B, $0A, 4, 4, 4
	ATTEN 2
	OCTAVE 4
	NOTE G_, 6
	NOTE B_, 1
	RELEASE 4, $0C
	NOTE A_, 2
	RELEASE 5, $0B
	NOTE D_, 2
	RELEASE 5, 9
	OCTAVE 5
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	RELEASE 3, 3
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	RELEASE 2, $0F
	DUTY_STEP 0, 1
	NOTE B_, 1
	ATTEN 2
	RELEASE 8, 8
	DUTY_STEP 0, 0
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 0
	RELEASE 3, 8
	DUTY_STEP 0, 1
	NOTE B_, 1
	RELEASE 2, $0F
	NOTE A_, 1
	DUTY_STEP 0, 0
	ATTEN 2
	RELEASE 8, 8
	NOTE D_, 1
	ATTEN 0
	RELEASE 4, 8
	DUTY_STEP 0, 1
	NOTE A_, 1
	RELEASE 5, $0A
	NOTE G_, 5
	DUTY_STEP 0, 0
	ATTEN 3
	RELEASE 5, 5
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 2
	VIBRATO 2, 6, 1
	RELEASE 4, 2
	NOTE G_, $0E
	DUTY 8
	RELEASE 3, 8
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	VIBRATO_OFF $00
	VOICE $0B, 7, 8, 3, 6
	VIBRATO 2, 1, 2
	ATTEN 1
	OCTAVE 3
	NOTE A#, 3
	VIBRATO_OFF $00
	RELEASE 8, 8
	ATTEN 0
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	RELEASE 3, 8
	NOTE G_, 1
	ATTEN 1
	RELEASE 4, 9
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 1
	RELEASE 5, $0B
	NOTE F_, 2
	RELEASE 7, $0B
	NOTE C_HI, 2
	RELEASE 5, 8
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	LEN_UNIT 1
	RELEASE 0, 0
	NOTE B_, 3
	RELEASE 5, 9
	NOTE C_HI, 8
	LEN_UNIT $0B
	NOTE C_HI, 2
	NOTE B_, 2
	DUTY 0
	ATTEN 1
	DUTY_STEP 8, 1
	OCTAVE 5
	RELEASE 4, $0D
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 6, $0D
	OCTAVE 4
	NOTE B_, 2
	RELEASE 4, $0D
	NOTE B_, 1
	NOTE B_, 1
	RELEASE 6, $0D
	NOTE G_, 2
	RELEASE 4, $0D
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	DUTY_STEP 0, 0
	VOICE $0B, 7, 8, 3, 6
	VIBRATO 2, 1, 2
	ATTEN 1
	OCTAVE 3
	NOTE A#, 3
	VIBRATO_OFF $00
	RELEASE 8, 8
	ATTEN 0
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	RELEASE 3, 8
	NOTE G_, 1
	ATTEN 1
	RELEASE 4, 9
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 1
	RELEASE 5, $0B
	NOTE F_, 2
	RELEASE 6, 8
	NOTE C_HI, 2
	RELEASE 5, 8
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 5, 4
	VIBRATO 2, 1, 1
	OCTAVE 4
	NOTE D_, 5
	ATTEN 2
	VIBRATO_OFF $00
	DUTY 0
	LEN_UNIT 3
	NOTE D#, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VIBRATO 2, 0, 1
	LEN_UNIT $0B
	RELEASE 7, 5
	OCTAVE 5
	NOTE D_, 6
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $0B, 8, 4, 3, 8
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE $0B, 8, 4, 2, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 3, 9
	VIBRATO 2, 0, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO_OFF $00
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	RELEASE 3, $0A
	NOTE C_HI, 2
	RELEASE 4, $0A
	OCTAVE 4
	NOTE D_, 3
	RELEASE 5, 8
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	RELEASE 3, 8
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0A
	NOTE G_, 3
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE $0B, 8, 4, 2, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 3, 9
	OCTAVE 4
	NOTE D_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	RELEASE 3, $0A
	NOTE C_HI, 2
	RELEASE 3, 8
	VIBRATO 2, 0, 2
	OCTAVE 4
	NOTE D_, 3
	VIBRATO_OFF $00
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	RELEASE 4, 8
	NOTE C_HI, 3
	OCTAVE 5
	NOTE D_, 1
	RELEASE 4, 9
	VIBRATO 2, 0, 1
	OCTAVE 4
	NOTE G_, 3
	VIBRATO_OFF $00
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE $0B, 8, 4, 2, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 3, 9
	OCTAVE 4
	NOTE D_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	RELEASE 3, $0A
	NOTE C_HI, 2
	RELEASE 4, $0A
	VIBRATO 2, 0, 2
	OCTAVE 4
	NOTE D_, 3
	VIBRATO_OFF $00
	RELEASE 5, 8
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	RELEASE 3, 8
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0A
	NOTE G_, 3
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE $0B, 8, 4, 2, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 3, 9
	OCTAVE 4
	NOTE D_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 1
	RELEASE 3, $0A
	NOTE C_HI, 2
	RELEASE 4, $0A
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 2
	NOTE A#, 1
	NOTE A_, 1
	VIBRATO 3, 0, 2
	NOTE G_, 4
	VIBRATO_OFF $00
	DUTY 0
	DUTY_STEP 0, 1
	LEN_UNIT 1
	NOTE G_, 6
	NOTE A_, 5
	VOICE $0B, 7, 8, 6, 8
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 1
	VIBRATO 3, 1, 1
	RELEASE 6, 8
	NOTE B_, 4
	VIBRATO_OFF $00
	NOTE B_, 1
	RELEASE 5, $0A
	NOTE C_HI, 2
	NOTE B_, 2
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 2
	DUTY_STEP 0, 0
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	RELEASE 5, 8
	VIBRATO 2, 0, 1
	OCTAVE 4
	NOTE G_, 3
	VIBRATO_OFF $00
	RELEASE 2, 9
	LEN_UNIT 1
	NOTE G_, 6
	NOTE D#, 5
	LEN_UNIT $0B
	RELEASE 5, 8
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, 9
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, 1
	RELEASE 5, 5
	VIBRATO 3, 1, 2
	NOTE C_, 4
	OCTAVE 4
	VIBRATO_OFF $00
	DUTY_STEP 0, 0
	ATTEN 2
	DUTY 4
	RELEASE 6, 8
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	VOICE $0B, 7, 4, 5, 8
	VIBRATO 1, 1, 2
	OCTAVE 4
	NOTE B_, 3
	VIBRATO_OFF $00
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	VIBRATO 2, 4, 3
	RELEASE 6, 4
	NOTE C_HI, 8
	VIBRATO_OFF $00
	LEN_UNIT $0C
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	LEN_UNIT $0D
	VIBRATO 1, 1, 2
	RELEASE 4, 8
	OCTAVE 5
	NOTE D_, 3
	VIBRATO_OFF $00
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	RELEASE 6, 8
	NOTE G_, 2
	ATTEN 1
	DUTY 0
	LEN_UNIT 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	LEN_UNIT $10
	VIBRATO 1, 1, 2
	RELEASE 6, 7
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 5
	VIBRATO 2, 4, 3
	RELEASE 0, 0
	NOTE B_, 8
	RELEASE 6, 7
	VIBRATO 2, 0, 3
	NOTE B_, 8
	SND_END

Snd95_Ch1:
	VOICE 2, 8, 4, 5, 8
	VIBRATO 1, 0, 3
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE F_, 1
	DUTY_STEP 0, 0
	NOTE F#, 3
	LEN_UNIT 8
	ATTEN 5
	NOTE F#, 3
	ATTEN 0
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 5
	DUTY_STEP 0, 0
	NOTE A_, 3
	ATTEN 0
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE F#, 1
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE F#, 3
	ATTEN 0
	DUTY_STEP 0, 1
	RELEASE 1, $0B
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	RELEASE 5, $0A
	NOTE D_, 2
	ATTEN 0
	RELEASE 0, 8
	NOTE F#, 1
	DUTY_STEP 0, 0
	ATTEN 5
	RELEASE $0B, 7
	NOTE F#, 3
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 8, 8, 4, $0B, 7
	DUTY_STEP 8, 2
	ATTEN 1
	PAN $F0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	PAN $0F
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 2
	PAN $FF
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	VOICE 2, 8, 4, 5, 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 3
	LEN_UNIT 8
	ATTEN 5
	NOTE F_, 3
	ATTEN 0
	DUTY_STEP 0, 1
	NOTE C_, 1
	ATTEN 5
	DUTY_STEP 0, 0
	NOTE C_, 3
	ATTEN 0
	DUTY_STEP 0, 1
	NOTE A_, 1
	ATTEN 4
	DUTY_STEP 0, 0
	NOTE A_, 3
	RELEASE 1, $0B
	ATTEN 0
	DUTY_STEP 0, 1
	NOTE A#, 1
	NOTE A#, 1
	RELEASE 5, $0A
	NOTE F_, 2
	ATTEN 0
	RELEASE 0, 8
	NOTE A_, 1
	DUTY_STEP 0, 0
	ATTEN 5
	RELEASE $0C, 7
	NOTE A_, 3
	DUTY_STEP 8, 1
	VOICE 8, 9, 4, $0C, 7
	ATTEN 2
	PAN $F0
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	PAN $0F
	ATTEN 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 1
	PAN $FF
	OCTAVE 4
	NOTE F_, 1
	ATTEN 3
	NOTE A_, 1
	OCTAVE 5
	ATTEN 0
	NOTE C_, 1
	NOTE F_, 1
	LEN_UNIT $0C
	VIBRATO 2, 1, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 5
	NOTE A_, 1
	NOTE G_, 1
	RELEASE 2, 2
	VIBRATO 3, 0, 1
	NOTE F#, 9
	ATTEN 0
	VIBRATO_OFF $00
	LEN_UNIT $0F
	REST 2
	VOICE 1, 2, 0, 0, 0
	REST 2
	OCTAVE 5
	NOTE D_, 4
	ATTEN 1
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D#, 3
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 3
	OCTAVE 3
	ATTEN 0
	NOTE B_, 3
	NOTE A#, 3
	NOTE A_, 3
	NOTE G#, 3
	NOTE G_, 1
	VOICE $0B, 5, 4, 7, 8
	OCTAVE 2
	NOTE G_, 4
	RELEASE 4, 9
	NOTE G_, 1
	NOTE A_, 2
	RELEASE 7, 4
	NOTE B_, 6
	NOTE B_, 1
	RELEASE 2, 9
	OCTAVE 3
	NOTE D_, 1
	RELEASE 6, 4
	NOTE D_, 6
	NOTE E_, 2
	RELEASE 6, 4
	VIBRATO 3, 3, 1
	NOTE C_, 9
	VIBRATO_OFF $00
	REST 4
	ATTEN 4
	OCTAVE 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	RELEASE 6, $0B
	OCTAVE 3
	NOTE D_, 3
	NOTE D_, 3
	RELEASE 8, 8
	NOTE F#, 2
	VIBRATO 2, 5, 2
	RELEASE 4, 2
	NOTE G_, 8
	VIBRATO_OFF $00
	RELEASE 7, $0C
	NOTE E_, 4
	RELEASE 6, $0A
	NOTE F#, 4
	VOICE $0B, 5, 4, 6, 8
	REST 4
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 2
	RELEASE 5, 8
	NOTE B_, 2
	RELEASE 6, 8
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 5, 8
	NOTE B_, 2
	RELEASE 4, $0A
	OCTAVE 3
	NOTE D_, 1
	RELEASE 2, $0C
	NOTE G_, 1
	RELEASE 5, 3
	VIBRATO 3, 3, 2
	NOTE B_, 6
	VIBRATO_OFF $00
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE G_, 1
	RELEASE 4, 3
	NOTE A_, 7
	RELEASE 2, $0C
	NOTE C_HI, 1
	RELEASE 5, 4
	VIBRATO 3, 3, 2
	NOTE C_HI, 5
	VIBRATO_OFF $00
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	RELEASE 5, 4
	NOTE A_, 5
	RELEASE 6, 8
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 2
	VOICE $0B, 8, 4, 5, 8
	ATTEN 2
	OCTAVE 4
	NOTE E_, 3
	RELEASE 4, 8
	ATTEN 0
	RELEASE 0, 0
	DUTY_STEP 0, 3
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	ATTEN 1
	RELEASE 2, $0B
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 0
	RELEASE 3, 9
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	RELEASE 2, $0F
	OCTAVE 4
	NOTE F#, 1
	RELEASE 5, 9
	NOTE F#, 1
	ATTEN 3
	DUTY_STEP 0, 0
	NOTE F#, 2
	RELEASE 3, 3
	NOTE E_, 1
	NOTE F#, 1
	DUTY_STEP 8, 1
	RELEASE 3, $0A
	NOTE G_, 3
	NOTE G_, 1
	RELEASE 3, 8
	NOTE F#, 2
	NOTE F#, 1
	RELEASE 6, 9
	NOTE E_, 5
	DUTY_STEP 0, 0
	ATTEN 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 2
	RELEASE 4, 4
	OCTAVE 3
	NOTE C_HI, 5
	NOTE A_, 1
	NOTE C_HI, 2
	VIBRATO 3, 0, 1
	RELEASE 5, 7
	NOTE B_, 8
	ATTEN 0
	VIBRATO_OFF $00
	VOICE $0B, 5, 8, 3, 6
	VIBRATO 3, 1, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 3
	VIBRATO_OFF $00
	RELEASE 8, 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 3
	RELEASE 4, 8
	NOTE D#, 1
	ATTEN 1
	RELEASE 5, 9
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 3
	ATTEN 0
	NOTE F_, 1
	RELEASE 6, $0B
	NOTE C_, 2
	RELEASE 8, $0B
	NOTE A_, 2
	RELEASE 6, 8
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	LEN_UNIT 1
	RELEASE 0, 0
	NOTE G#, 3
	RELEASE 6, 9
	NOTE A_, 8
	LEN_UNIT $0B
	NOTE A_, 2
	NOTE G_, 2
	DUTY 0
	ATTEN 1
	DUTY_STEP 8, 1
	OCTAVE 4
	RELEASE 5, $0D
	NOTE B_, 1
	NOTE B_, 1
	RELEASE 7, $0D
	NOTE G_, 2
	RELEASE 5, $0D
	NOTE G_, 1
	NOTE G_, 1
	RELEASE 7, $0D
	NOTE D_, 2
	RELEASE 5, $0D
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	DUTY_STEP 0, 0
	VOICE $0B, 7, 8, 3, 6
	VIBRATO 3, 1, 1
	ATTEN 2
	OCTAVE 3
	NOTE D#, 3
	VIBRATO_OFF $00
	RELEASE 8, 8
	ATTEN 0
	OCTAVE 2
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	RELEASE 3, 8
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	RELEASE 4, 9
	NOTE G_, 1
	NOTE D#, 1
	ATTEN 0
	NOTE F_, 1
	RELEASE 5, $0B
	NOTE C_, 2
	RELEASE 4, 8
	NOTE F_, 2
	RELEASE 5, 8
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	RELEASE 5, 6
	NOTE G_, 5
	DUTY 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	VIBRATO 2, 1, 2
	NOTE F#, 6
	VIBRATO_OFF $00
	NOTE G_, 1
	NOTE A_, 1
	VOICE $0B, 7, 4, 3, $0C
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 3, $0F
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 9
	NOTE B_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 3, $0F
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	VIBRATO 3, 0, 1
	RELEASE 5, $0A
	NOTE B_, 3
	VIBRATO_OFF $00
	RELEASE 6, 8
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 4, 8
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0A
	NOTE A#, 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	VOICE $0B, 7, 4, 3, $0C
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 9
	NOTE B_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	RELEASE 4, 8
	VIBRATO 3, 0, 1
	OCTAVE 3
	NOTE B_, 3
	VIBRATO_OFF $00
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	RELEASE 5, 8
	NOTE A_, 3
	NOTE B_, 1
	RELEASE 5, 9
	VIBRATO 3, 0, 2
	NOTE D#, 3
	VIBRATO_OFF $00
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	VOICE $0B, 7, 4, 3, $0C
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 9
	NOTE B_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	RELEASE 5, $0A
	VIBRATO 3, 0, 1
	NOTE B_, 3
	RELEASE 6, 8
	VIBRATO_OFF $00
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 4, 8
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0A
	NOTE A#, 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	VOICE $0B, 7, 4, 3, $0C
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 3, $0F
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 9
	NOTE B_, 2
	ATTEN 1
	DUTY_STEP 0, 1
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 5, $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 1
	RELEASE 4, $0A
	NOTE A_, 2
	RELEASE 5, $0A
	NOTE B_, 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	VIBRATO 3, 0, 1
	NOTE A_, 2
	VIBRATO_OFF $00
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 5
	VOICE $0B, 5, 4, 7, 8
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 1
	RELEASE 6, 8
	NOTE G_, 4
	NOTE G_, 1
	RELEASE 5, 5
	NOTE F_, 4
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	RELEASE 5, $0A
	NOTE F_, 1
	ATTEN 3
	DUTY_STEP 0, 0
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	RELEASE 3, 5
	OCTAVE 4
	NOTE E_, 2
	NOTE C_, 2
	RELEASE 5, 8
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	RELEASE 5, 8
	NOTE A_, 3
	VIBRATO 3, 3, 2
	RELEASE 5, 8
	NOTE F_, 6
	VIBRATO_OFF $00
	VOICE $0B, 5, 4, 6, 8
	OCTAVE 4
	NOTE E_, 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	VIBRATO 3, 4, 2
	RELEASE 7, 4
	NOTE A_, 8
	VIBRATO_OFF $00
	LEN_UNIT $0C
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	LEN_UNIT $0D
	RELEASE 5, 8
	NOTE A#, 3
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	RELEASE 6, 8
	NOTE D#, 3
	LEN_UNIT $10
	VIBRATO 2, 1, 1
	RELEASE 6, 7
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 5
	RELEASE 0, 0
	VIBRATO 3, 4, 1
	NOTE F#, 8
	RELEASE 7, 7
	VIBRATO 3, 0, 1
	NOTE F#, 8
	SND_END

Snd95_Ch3:
	VOICE 8, 2, 1, 8, 3
	VIBRATO 1, 0, 6
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	NOTE D_, $0B
	ATTEN 0
	RELEASE 1, 6
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	RELEASE 6, 9
	NOTE G_, 2
	ATTEN 0
	RELEASE 8, 3
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	NOTE D_, $0C
	ATTEN 0
	RELEASE 1, 6
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	VOICE 8, 2, 1, 5, 2
	OCTAVE 2
	NOTE F_, 1
	ATTEN 1
	NOTE F_, $0B
	ATTEN 0
	RELEASE 1, 6
	OCTAVE 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	RELEASE 8, $0A
	NOTE A#, 2
	RELEASE 5, 2
	OCTAVE 2
	NOTE F_, 1
	ATTEN 1
	NOTE F_, $0B
	ATTEN 0
	RELEASE 2, $0A
	NOTE F_, 2
	RELEASE 1, 9
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 1
	LEN_UNIT $0C
	RELEASE 1, 1
	NOTE D_, 0
	ATTEN 0
	VIBRATO_OFF $00
	TRANSPOSE_UP $0C
	VIBRATO 4, 0, 1
	LEN_UNIT $0F
	REST 2
	VOICE $0B, 2, 4, 6, 3
	REST 6
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 3
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 1
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 3
	OCTAVE 2
	NOTE D_, 3
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D#, 2
	NOTE E_, 4
	NOTE E_, 3
	OCTAVE 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 3
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 3
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE C_HI, 3
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 3
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE C_HI, 2
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE A_, 5
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 2
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 2
	NOTE D#, 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 3
	LEN_UNIT 1
	RELEASE 1, 9
	NOTE G_, 6
	NOTE G_, 5
	LEN_UNIT $0B
	RELEASE 6, 3
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 2
	NOTE D#, 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 3
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 3
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F_, 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 2
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE F_, 2
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	OCTAVE 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	LEN_UNIT 1
	OCTAVE 1
	NOTE C_HI, 6
	NOTE B_, 5
	LEN_UNIT $0B
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	VOICE $0B, 2, 4, 6, 3
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 8
	LEN_UNIT $0C
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	LEN_UNIT $0D
	OCTAVE 2
	NOTE D#, 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 3
	LEN_UNIT $10
	OCTAVE 1
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 5
	OCTAVE 1
	RELEASE 0, 0
	NOTE G_, 8
	RELEASE 7, 7
	NOTE G_, 8
	SND_END

Snd95_Drm:
	DRUM_UNIT 8
	REST 0
	REST 0
	REST 0
	REST 0
	LEN_UNIT $0C
	REST 0
	DRUM_UNIT $0F
	REST 2
	DRUM_UNIT $0B
	REST 6
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	LOOP_END 4
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	LOOP_END 3
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	LEN_UNIT 1
	DRUM 6, 6
	DRUM 6, 5
	LEN_UNIT $0B
	DRUM 6, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM 6, 2
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	LEN_UNIT 1
	DRUM 1, 5
	DRUM 1, 6
	LEN_UNIT $0B
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	DRUM_UNIT $0B
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	DRUM_UNIT $0B
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 1, 1
	LEN_UNIT 1
	DRUM 1, 6
	DRUM 1, 5
	LEN_UNIT $0B
	DRUM 1, 1
	DRUM 1, 1
	DRUM 6, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM_UNIT $0B
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 1, 1
	LEN_UNIT 1
	DRUM 1, 6
	DRUM 1, 5
	LEN_UNIT $0B
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM_UNIT $0B
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 1
	LEN_UNIT $0C
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	LEN_UNIT $0D
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 8, 1
	LEN_UNIT $10
	DRUM 2, 4
	DRUM 2, 5
	DRUM 2, 0
	SND_END

Snd96_Ch2:
	TEMPO $08
	VOICE 6, 7, 8, 4, $0A
	REST 8
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 6
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	VIBRATO 1, 2, 3
	RELEASE 0, $0F
	NOTE E_, 7
	ATTEN 5
	VIBRATO 2, 0, 3
	NOTE E_, 7
	ATTEN 0
	VIBRATO 2, 2, 3
	DUTY_STEP 0, 1
	VOICE 8, 8, 8, 0, $0F
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	VOICE 6, 7, 8, 0, $0F
	DUTY_STEP 0, 0
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 3
	ATTEN 0
	OCTAVE 4
	NOTE D_, 5
	ATTEN 5
	NOTE D_, 5
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 6, 7, 4, 1, $0A
	DUTY_STEP 4, 1
	OCTAVE 3
	ATTEN 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	ATTEN 0
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	DUTY_STEP 0, 0
	SND_SEGNO
	VIBRATO 2, 1, 3
	VOICE 6, 9, 4, 0, $0F
	OCTAVE 3
	NOTE F_, 4
	VIBRATO 2, 0, 3
	VOICE 6, 6, 4, 0, $0F
	ATTEN 0
	NOTE F_, 4
	ATTEN 3
	NOTE F_, 4
	ATTEN 0
	VOICE 6, 7, 4, $0C, $0F
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	VOICE 6, 9, 4, 0, $0F
	VIBRATO 2, 1, 3
	NOTE C_, 4
	VIBRATO 2, 0, 3
	ATTEN 6
	NOTE C_, 5
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 6, 8, 0, 1, $0C
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 0
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 0
	VOICE 6, 9, 4, 0, $0F
	OCTAVE 3
	NOTE F_, 6
	ATTEN 4
	NOTE F_, 6
	ATTEN 0
	VOICE 6, 7, 4, $0C, $0F
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	VOICE 6, 8, 0, 1, $0C
	ATTEN 3
	NOTE B_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	ATTEN 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 1, $0F
	ATTEN 0
	NOTE B_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	NOTE B_, 1
	SND_LOOP

Snd96_Ch1:
	VOICE 6, 6, 4, 4, $0A
	REST 8
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 6
	NOTE A_, 1
	NOTE B_, 1
	RELEASE 0, $0F
	OCTAVE 4
	NOTE C#, 7
	ATTEN 3
	NOTE C#, 7
	ATTEN 0
	VOICE 8, 7, 4, 0, $0F
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	VOICE 6, 6, 4, 0, $0F
	NOTE E_, 3
	ATTEN 3
	NOTE E_, 3
	ATTEN 0
	NOTE B_, 5
	ATTEN 3
	NOTE B_, 5
	ATTEN 0
	VOICE 6, 6, 4, 1, $0A
	ATTEN 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_SEGNO
	VOICE 6, 5, 4, 1, $0C
	OCTAVE 4
	NOTE A#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	VOICE 6, 6, 8, 2, $0C
	ATTEN 2
	NOTE C_HI, 1
	NOTE E_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	VOICE 6, 8, 4, 1, $0C
	ATTEN 4
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	VOICE 6, 6, 8, 2, $0C
	ATTEN 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE G_, 1
	ATTEN 0
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	SND_LOOP

Snd96_Ch3:
	VOICE 6, 4, 1, 3, $0A
	REST 8
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
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
	SND_SEGNO
	VOICE 6, 4, 1, 3, $0A
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_LOOP

Snd96_Drm:
	DRUM_UNIT 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0D, 3
	DRUM $0D, 3
	DRUM 7, 3
	DRUM 7, 3
	DRUM 4, 6
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
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
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	SND_SEGNO
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 2, 2
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
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	SND_LOOP
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

SECTION "Sound bank 15", ROMX[$4000], BANK[15]
B15_SoundTable:
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

SndHdrCE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndCE_Ch1
	dw SndCE_Ch2
	dw SndCE_Ch3
	dw SndCE_Drm

SndHdrCF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndCF_Ch1
	dw SndCF_Ch2
	dw SndCF_Ch3
	dw SndCF_Drm

SndHdrD0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD0_Ch1
	dw SndD0_Ch2
	dw SndD0_Ch3
	dw SndD0_Drm

SndHdrD1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD1_Ch1
	dw SndD1_Ch2
	dw SndD1_Ch3
	dw SndD1_Drm

SndHdrD2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD2_Ch1
	dw SndD2_Ch2
	dw SndD2_Ch3
	dw SndD2_Drm

SndHdrD3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD3_Ch1
	dw SndD3_Ch2
	dw SndD3_Ch3
	dw SndD3_Drm

SndHdrD4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD4_Ch1
	dw SndD4_Ch2
	dw SndD4_Ch3
	dw SndD4_Drm

SndHdrD5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD5_Ch1
	dw SndD5_Ch2
	dw SndD5_Ch3
	dw SndD5_Drm

SndHdrD6:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD6_Ch1
	dw SndD6_Ch2
	dw SndD6_Ch3
	dw SndD6_Drm

SndHdrD7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD7_Ch1
	dw SndD7_Ch2
	dw SndD7_Ch3
	dw SndD7_Drm

SndHdrD8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD8_Ch1
	dw SndD8_Ch2
	dw SndD8_Ch3
	dw SndD8_Drm

SndHdrD9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD9_Ch1
	dw SndD9_Ch2
	dw SndD9_Ch3
	dw SndD9_Drm
B15_DrumMap:
	db $C1, $C2, $C3, $C4, $C5, $C6, $C7, $CA, $C8, $CB, $C9, $CC, $CD

SndHdrC1:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC1_SfxN

SndHdrC2:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC2_SfxN

SndHdrC8:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC8_SfxN

SndHdrC9:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC9_SfxN

SndHdrCA:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndCA_SfxN

SndHdrC3:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC3_SfxN

SndHdrC4:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw SndC4_Sfx1
	dw SndC4_SfxN

SndHdrC5:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC5_SfxN

SndHdrC6:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndC6_SfxN

SndHdrC7:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw SndC7_Sfx1
	dw SndC7_SfxN

SndHdrCB:
	SND_HEADER $02, $04 ; tracks: SfxN
	dw SndCB_SfxN

SndHdrCC:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw SndCC_Sfx1
	dw SndCC_SfxN

SndHdrCD:
	SND_HEADER $02, $05 ; tracks: Sfx1, SfxN
	dw SndCD_Sfx1
	dw SndCD_SfxN

SndC1_SfxN:
	NVOICE 1, $0F, 1
	NOISE $01
	NVOICE 1, $0A, 1
	NOISE $11
	SND_END

SndC5_SfxN:
	NVOICE 1, 9, 1
	NOISE $01
	NVOICE 1, 6, 1
	NOISE $11
	SND_END

SndC2_SfxN:
	NVOICE 1, 6, 0
	NOISE $02
	NVOICE 3, 8, 0
	NOISE $02
	NVOICE $0A, 4, 5
	NOISE $02
	SND_END

SndC9_SfxN:
	NVOICE 1, $0F, 3
	NOISE $3D
	NOISE $74
	SND_END

SndCA_SfxN:
	NVOICE 1, $0F, 1
	NOISE $0A
	NVOICE 1, 8, 0
	NOISE $71
	SND_END

SndC8_SfxN:
	NVOICE 1, $0F, 0
	NOISE $01
	NOISE $72
	NVOICE 1, $0C, 0
	NOISE $25
	NVOICE 5, 5, 3
	NOISE $07
	SND_END

SndC6_SfxN:
	NVOICE 1, $0F, 0
	NOISE $43
	NOISE $24
	NVOICE $0A, 8, 1
	NOISE $33
	SND_END

SndC3_SfxN:
	NVOICE 5, 3, $0B
	NOISE $01
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $13
	NOISE $14
	NOISE $14
	NOISE $15
	NOISE $15
	NOISE $16
	NOISE $16
	NOISE $17
	NOISE $17
	SND_END
B15_Orphan_414A:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B15_Orphan_4151:
	RAW_HEADER 2, $08, $1F
	PAN $F0
	RAW_NOTE 8, $6FF
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $699
	SND_END
B15_Orphan_4160:
	PAN $0F
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B15_Orphan_4167:
	RAW_HEADER 2, $08, $1E
	PAN $0F
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END
B15_Orphan_4176:
	PAN $F0
	NVOICE 7, 9, 1
	NOISE $30
	SND_END
B15_Orphan_417D:
	RAW_HEADER 2, $08, $1E
	PAN $F0
	RAW_NOTE 8, $6F0
	RAW_HEADER 6, $08, $1F
	RAW_NOTE 4, $633
	SND_END

SndCB_SfxN:
	NVOICE 1, $0F, 1
	NOISE $79
	NVOICE $0C, 7, 0
	NOISE $02
	NVOICE $18, 4, 7
	NOISE $02
	SND_END

SndCC_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $3D
	OCTAVE 3
	NOTE C_, 4
	SND_END

SndCC_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

SndCD_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $2D
	OCTAVE 3
	NOTE C_, 4
	SND_END

SndCD_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

SndC7_Sfx1:
	VOICE 3, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 4
	SND_END

SndC7_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

SndC4_Sfx1:
	VOICE 5, 7, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C_, 6
	SND_END

SndC4_SfxN:
	NVOICE 1, $0F, 0
	NOISE $58
	NOISE $57
	NVOICE $0A, 4, 3
	NOISE $13
	NVOICE 1, 2, 3
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

B15_CopyBytes:
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, B15_CopyBytes
	ret

B15_LoadPtrIndexed:
	add a, a
	rst $28
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

B15_JumpTableInline:
	pop hl
	call B15_LoadPtrIndexed
	jp hl
B15_PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7
B15_WaveTable:
	dw B15_WaveData1
	dw B15_WaveData2
	dw B15_WaveData3
	dw B15_WaveData4
	dw B15_WaveData5
	dw B15_WaveData6
	dw B15_WaveData7
	dw B15_WaveData8
	dw B15_WaveData9
	dw B15_WaveData10
	dw B15_WaveData11
	dw B15_WaveData12
	dw B15_WaveData13
	dw B15_WaveData14
B15_WaveData1:
	db $F0, $EE, $CA, $86, $0A, $46, $8A, $CE, $FF, $EE, $CA, $86, $0A, $46, $8A, $CE
B15_WaveData2:
	db $F0, $EE, $DC, $BA, $98, $76, $65, $3F, $F3, $45, $67, $89, $AB, $CD, $EE, $0F
	db $F8
B15_WaveData3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
B15_WaveData4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
B15_WaveData5:
	db $23, $44, $55, $67, $89, $9A, $BB, $CD, $23, $56, $78, $9A, $CD, $CA, $98, $53
B15_WaveData6:
	db $60, $58, $00, $FF, $F9, $00, $00, $20, $20, $08, $08, $40, $C0, $00, $C0, $00
B15_WaveData7:
	db $FF, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
B15_WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
B15_WaveData9:
	db $88, $80, $8F, $FF, $88, $88, $88, $80, $40, $08, $08, $88, $40, $00, $80, $00
B15_WaveData10:
	db $66, $60, $8F, $C0, $88, $80, $40, $20, $20, $08, $08, $88, $40, $00, $80, $00
B15_WaveData11:
	db $44, $33, $22, $11, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $DD, $00
B15_WaveData12:
	db $FF, $FF, $FF, $11, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
B15_WaveData13:
	db $02, $46, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $45, $65, $43, $21, $00
B15_WaveData14:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
B15_VibratoTable:
	dw B15_Vib01 ; 1
	dw B15_Vib02 ; 2
	dw B15_Vib03 ; 3
	dw B15_Vib04 ; 4
	dw B15_Vib05 ; 5
	dw B15_Vib06 ; 6
	dw B15_Vib07 ; 7
	dw B15_Vib08 ; 8
	dw B15_Vib09 ; 9
	dw B15_Vib0A ; 10
	dw B15_Vib0B ; 11
	dw B15_Vib0C ; 12
	dw B15_Vib0D ; 13
	dw B15_Vib0E ; 14
	dw B15_Vib0F ; 15
	dw B15_Vib10 ; 16

B15_Vib01:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

B15_Vib02:
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 0
	VIB_HOLD

B15_Vib03:
	VIB_SEGNO
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_REPEAT $FF

B15_Vib04:
	VIB_STEP 6, 1, 6
	VIB_STEP 4, 1, 5
	VIB_STEP 4, 1, 4
	VIB_STEP 4, 1, 3
	VIB_STEP 4, 1, 2
	VIB_STEP 3, 1, 1
	VIB_SEGNO
	VIB_STEP 3, 1, 0
	VIB_STEP 3, 1, 2
	VIB_REPEAT $FF

B15_Vib05:
	VIB_STEP 4, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B15_Vib06:
	VIB_STEP 4, 0, 1
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B15_Vib07:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF

B15_Vib08:
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 0
	VIB_HOLD

B15_Vib09:
	VIB_SEGNO
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 0, 0
	VIB_REPEAT $FF

B15_Vib0A:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_HOLD

B15_Vib0B:
	VIB_STEP 1, 0, 1
	VIB_HOLD

B15_Vib0C:
	VIB_SEGNO
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_REPEAT $FF

B15_Vib0D:
	VIB_STEP 8, 0, 0
	VIB_SEGNO
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_REPEAT $FF

B15_Vib0E:
	VIB_STEP 8, 1, 2
	VIB_SEGNO
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 0
	VIB_REPEAT $FF

B15_Vib0F:
	VIB_SEGNO
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_REPEAT $FF
	db $FF

B15_Vib10:
	VIB_SEGNO
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 2
	VIB_REPEAT $FF

B15_PlayDrumSound:
	ld [wReqId], a
	or a
	jp z, B15_StopAll
	and $3F
	ld hl, SOUND_TABLE_M2
	call B15_LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld a, [hl+]
	ld d, h
	ld e, l
	cp $05
	jr nz, .l4460
	call B15_StartSfx1
.l4460:
	call B15_StartSfxN
	ld a, [wNR51]
	ldh [rNR51], a
	ret

; (unreachable)
	ret

B15_StartSfxN:
	push af
	ld hl, wTrkSfxN
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l447D
	ld a, [wNR51]
	or $88
	ld [wNR51], a
.l447D:
	dec l
	jr B15_StartTrack

B15_StartSfx1:
	push af
	ld hl, wTrkSfx1
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l449A
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
.l449A:
	dec l

B15_StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l44DE
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
	jr nz, .l44D5
	ld l, TRK_FLAGS2
	set 4, [hl]
	set 5, [hl]
	xor a
	jr .l44E1
.l44D5:
	ld l, TRK_FLAGS2
	res 4, [hl]
	res 5, [hl]
	xor a
	jr .l44E1
.l44DE:
	push de
	inc de
	inc de
.l44E1:
	ld a, $FF
	ld l, TRK_PAN
	ld [hl], a
	pop de
	pop af
	ret

B15_StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0037
	ld [hl], $00
	call B15_CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0037
	ld [hl], $00
	call B15_CopyBytes
	ld hl, wShadow
	ld de, wShadow + $01
	ld bc, $0014
	ld [hl], $00
	call B15_CopyBytes
	ld hl, wTrackIdx
	ld de, wRegBase
	ld bc, $0020
	ld [hl], $00
	call B15_CopyBytes
	ld a, $FF
	ld [wNR51], a

B15_FadeStep:
	ld a, [wFadeReq]
	or a
	jr nz, B15_FadeCount
.l452C:
	ld [wFadeTimer], a
	ld [wFadeLevel], a
	ld [wFadeStep], a
	ld [wFadeReq], a
	ret

B15_FadeCount:
	ld a, [wFadeTimer]
	inc a
	ld [wFadeTimer], a
	cp $70
	jp z, B15_FadeNextStep
	ret

B15_FadeNextStep:
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
	jp nz, .l4569
	xor a
	ld hl, wTrkDrm
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ret
.l4569:
	ld a, [wFadeStep]
	cp $07
	jp nz, .l457E
	xor a
	ld hl, wTrkCh3
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ldh [rNR32], a
	ldh [rNR30], a
	ret
.l457E:
	ld a, [wFadeStep]
	cp $09
	ret nz
	xor a
	ld hl, wTrkCh1
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx1
	ld a, [hl]
	or a
	jr nz, .l459E
	ld a, $08
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
.l459E:
	xor a
	ld hl, wTrkCh2
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld l, TRK_LEVEL
	ld [hl], a
	ld hl, wTrkSfx2
	ld a, [hl]
	or a
	jr nz, .l45B8
	ld a, $08
	ldh [rNR22], a
	ld a, $80
	ldh [rNR24], a
.l45B8:
	xor a
	jp B15_FadeStep.l452C

B15_TrackEntry:
	ld a, [wPauseFlags]
	rra
	ret c
	ld a, [wTrackIdx]
	cp $03
	jp c, B15_TrackTick
	ld a, [wTempoSkip]
	or a
	jr nz, .l4610
	ld a, [wTempo]
	or a
	jr nz, .l45DB
	xor a
	ld [wTempoOn], a
	jr B15_HalfRate
.l45DB:
	ld a, $01
	ld [wTempoOn], a
	ld a, [wTempoPhase]
	cp $03
	jr z, .l45ED
	inc a
	ld [wTempoPhase], a
	jr B15_HalfRate
.l45ED:
	xor a
	ld [wTempoPhase], a
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	jr nc, .l460A
	ld a, [wTempo]
	ld [wTempoAcc], a
	ld a, $01
	ld [wTempoSkip], a
	ret
.l460A:
	xor a
	ld [wTempoSkip], a
	jr B15_HalfRate
.l4610:
	ld a, [wTempoPhase]
	cp $03
	jr z, .l460A
	inc a
	ld [wTempoPhase], a
	ret

; (unreachable)
	ld a, [wTempoSkip]
	or a
	ret nz

B15_HalfRate:
	ld a, [wHalfPhase]
	or a
	jr z, .l462C
	cp $01
	jr z, .l463B
	ret
.l462C:
	ld a, [wTrackIdx]
	cp $06
	jr z, .l464A
	ld a, [wTrackIdx]
	cp $04
	jr z, .l464A
	ret
.l463B:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l464A
	ld a, [wTrackIdx]
	cp $03
	jr z, .l464A
	ret
.l464A:
	call B15_FadeStep

B15_TrackTick:
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	call B15_GetRegBase
	ld [wRegBase], a
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_LEN
	dec [hl]
	jr nz, .l4686
	ld l, TRK_FLAGS2
	res 2, [hl]
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $00
	jr nz, .l4675
.l4675:
	ld a, [wTrackIdx]
	cp $05
	jp nz, B15_ReadCmds
	xor a
	ld [wShadow + $0A], a
	ldh [rNR30], a
	jp B15_ReadCmds
.l4686:
	ld l, TRK_FLAGS2
	ld a, [hl]
	and $18
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l46AB
	ld l, TRK_DUTYTICKS
	ld a, [hl]
	dec a
	ld [hl], a
	jr nz, .l46AB
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
.l46AB:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l46B7
	ld l, TRK_FLAGS2
	set 2, [hl]
.l46B7:
	ld l, TRK_FLAGS
	bit 2, [hl]
	jr z, .l46C9
	ld l, TRK_VIBDELAY
	ld a, [hl]
	or a
	jr z, .l46C6
	dec [hl]
	jr .l46C9
.l46C6:
	call B15_VibratoTick
.l46C9:
	ld a, [wTrackIdx]
	cp $05
	jr z, .l46EB
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
	call B15_WriteReg
	jp B15_Trigger
.l46EB:
	ld l, TRK_FLAGS2
	bit 2, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l4717
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
	jr z, .l4717
	inc a
	and $03
	ld [hl], a
	jr z, .l4717
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l4714
	xor a
.l4714:
	rla
	swap a
.l4717:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B15_WriteReg

B15_ReadCmdsNext:
	inc de

B15_ReadCmds:
	ld a, [de]
	cp $FB
	jp c, B15_ReadCmdsLow
	inc de
	sub $FB
	push hl
	call B15_JumpTableInline
	dw B15_Cmd_Loop
	dw B15_Cmd_Loop2
	dw B15_Cmd_Call
	dw B15_Cmd_Segno
	dw B15_Cmd_End

B15_Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $01
	jp nz, .l474C
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B15_ReadCmds
.l474C:
	ld a, [de]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l475A
	ld l, TRK_LOOPPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B15_ReadCmds
.l475A:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jr B15_ReadCmdsNext

B15_Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $02
	jp nz, .l4776
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	jr B15_ReadCmds
.l4776:
	push hl
	ld a, [de]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jr z, .l4786
	pop hl
	ld l, TRK_LOOP2PTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jr B15_ReadCmds
.l4786:
	pop hl
	ld l, TRK_LOOP2CNT
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jr B15_ReadCmdsNext

B15_Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $04
	jp nz, .l47AC
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
	jp B15_ReadCmds
.l47AC:
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_FLOW
	res 2, [hl]
	jp B15_ReadCmds

B15_Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	ld a, [hl]
	and $08
	jp nz, .l47CB
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp B15_ReadCmds
.l47CB:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B15_ReadCmds

B15_Cmd_End:
	pop hl
	dec de
	xor a
	ld l, TRK_ID
	ld [hl+], a
	ld [hl], a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B15_WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l47F0
	xor a
	ldh [rNR30], a
	ret
.l47F0:
	cp $02
	jr z, .l4812
	cp $01
	jr z, .l4802
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l4804
.l4802:
	ld h, HIGH(wTrkCh2)
.l4804:
	ld l, TRK_ID
	ld a, [hl]
	cp $00
	ret z
	push hl
	call B15_WriteDuty
	pop hl
	jp .l4819
.l4812:
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
.l4819:
	push hl
	call B15_GetPanBits
	pop hl
	ld b, a
	call B15_IsBlocked
	ld a, b
	jp c, .l482C
	or c
	ld [wNR51], a
	ldh [rNR51], a
.l482C:
	ld l, TRK_PERIOD
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld b, [hl]
	jp B15_WritePeriodBC

B15_ReadCmdsLow:
	ld l, TRK_FLAGS2
	bit 5, [hl]
	jp nz, B15_RawReader
	ld a, [de]
	cp $E0
	jp z, B15_Cmd_Voice
	and $F0
	cp $E0
	jp c, B15_Note
	cp $F0
	jp z, B15_Cmd_Atten
	ld a, [de]
	cp $E7
	jp c, B15_Cmd_Octave
	inc de
	sub $E7
	push hl
	call B15_JumpTableInline
	dw B15_Cmd_LenUnit
	dw B15_Cmd_Release
	dw B15_Cmd_Sweep
	dw B15_Cmd_Ext
	dw B15_Cmd_Vibrato
	dw B15_Cmd_EC
	dw B15_Cmd_DutyStep
	dw B15_Cmd_Tempo
	dw B15_Cmd_Pan

B15_Cmd_LenUnit:
	pop hl
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Cmd_Release:
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
	jp B15_ReadCmdsNext

B15_Cmd_Sweep:
	pop hl
	ld a, [de]
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B15_WriteReg
	jp B15_ReadCmdsNext

B15_Cmd_Ext:
	pop hl
	ld a, [de]
	and $F0
	swap a
	push hl
	call B15_JumpTableInline
	dw B15_Ext_TransposeUp
	dw B15_Ext_TransposeDown
	dw B15_Ext_Nop
	dw B15_Ext_Duty
	dw B15_Ext_Autopan

B15_Ext_TransposeUp:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Ext_TransposeDown:
	pop hl
	ld a, [de]
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Ext_Nop:
	pop hl
	jp B15_ReadCmdsNext

B15_Ext_Duty:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VOICEDUTY
	ld [hl], a
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
	jp B15_ReadCmdsNext

B15_Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld a, [hl]
	jr z, .l48E6
	or $02
	jr .l48E8
.l48E6:
	and $FD
.l48E8:
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Cmd_Vibrato:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	jr nz, .l4900
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 2, [hl]
	jp B15_ReadCmdsNext
.l4900:
	ld l, TRK_FLAGS
	set 2, [hl]
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_VIBDELAYUNITS
	ld [hl], a
	jr z, .l4918
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l4914:
	add a, c
	dec b
	jr nz, .l4914
.l4918:
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
	ld hl, B15_VibratoTable
	call B15_LoadPtrIndexed
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
	jp B15_ReadCmdsNext

B15_Cmd_EC:
	pop hl
	jp B15_ReadCmdsNext

B15_Cmd_DutyStep:
	pop hl
	ld a, [de]
	and $F0
	jr nz, .l4957
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_FLAGS
	res 4, [hl]
	jp B15_ReadCmdsNext
.l4957:
	ld l, TRK_FLAGS
	set 4, [hl]
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYRELOAD
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_DUTYSTEP
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	ld [wTempoAcc], a
	jp B15_ReadCmdsNext

B15_Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $06
	jr nz, .l4985
	inc de
	jp B15_ReadCmdsNext
.l4985:
	ld a, [de]
	ld l, TRK_PAN
	ld [hl], a
	call B15_GetPanBits
	ld b, a
	call B15_IsBlocked
	ld a, b
	jp c, B15_ReadCmdsNext
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp B15_ReadCmdsNext

B15_GetPanBits:
	ld a, [wTrackIdx]
	push hl
	call B15_JumpTableInline
	dw B15_PanBits11
	dw B15_PanBits22
	dw B15_PanBits88
	dw B15_PanBits11
	dw B15_PanBits22
	dw B15_PanBits44
	dw B15_PanBits88

B15_PanBits22:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $22
	ld c, a
	ld a, [wNR51]
	and $DD
	ret

B15_PanBits44:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $44
	ld c, a
	ld a, [wNR51]
	and $BB
	ret

B15_PanBits88:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $88
	ld c, a
	ld a, [wNR51]
	and $77
	ret

B15_PanBits11:
	pop hl
	ld l, TRK_PAN
	ld a, [hl]
	and $11
	ld c, a
	ld a, [wNR51]
	and $EE
	ret

B15_AutoPan:
	ld a, [wTrackIdx]
	cp $02
	ret z
	ld l, TRK_PAN
	ld a, [hl]
	swap a
	ld [hl], a
	call B15_GetPanBits
	ld b, a
	call B15_IsBlocked
	ld a, b
	ret c
	or c
	ld [wNR51], a
	ldh [rNR51], a
	ret

B15_Cmd_Octave:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B15_RawReader
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp B15_ReadCmdsNext

B15_Cmd_Voice:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B15_RawReader
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, B15_ReadCmdsNext
	inc de
	cp $02
	jr z, .l4A52
	ld a, [de]
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	ld l, TRK_VOICEDUTY
	ld [hl], a
	call B15_WriteDuty
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
	jp B15_ReadCmdsNext
.l4A52:
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
	call B15_WriteReg
	call B15_Trigger
	jp B15_ReadCmdsNext

B15_Cmd_Atten:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B15_RawReader
	ld a, [de]
	and $0F
	ld l, TRK_ATTEN
	ld [hl], a
	ld b, a
	ld a, [wTrackIdx]
	cp $02
	jp nz, B15_ReadCmdsNext
	ret
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
	call B15_WriteReg
	call B15_Trigger
	jp B15_ReadCmdsNext

B15_NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	ld c, a
	ld b, $80
	jp B15_WritePeriodBC

B15_Note:
	ld l, TRK_FLAGS2
	bit 4, [hl]
	jp nz, B15_RawReader
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, B15_AutoPan
	call B15_SavePtr
	dec de
	ld a, [wTrackIdx]
	cp $02
	jr z, B15_NoiseNote
	ld a, [de]
	and $0F
	jr nz, .l4ADC
	ld l, TRK_UNIT
	ld a, [hl]
	and $0F
	swap a
	jr .l4AE6
.l4ADC:
	or a
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4AE2:
	add a, c
	dec b
	jr nz, .l4AE2
.l4AE6:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, B15_Rest
	ld l, TRK_FLAGS2
	res 3, [hl]
	ld a, [wTrackIdx]
	cp $06
	jp z, B15_DrumNote
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l4B1D
	ld l, TRK_DUTYRELOAD
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	ld [hl], a
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
	jr .l4B1D

; (unreachable)
	ld l, TRK_FLAGS
	res 4, [hl]
	ld l, TRK_VOICEDUTY
	ld a, [hl]
	ld [hl], a
	call B15_WriteDuty
.l4B1D:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4B2A
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4B3C
.l4B2A:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l4B32:
	srl c
	jr nc, .l4B37
	add a, d
.l4B37:
	rra
	dec b
	jr nz, .l4B32
	pop de
.l4B3C:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l4B54
	ld b, a
	ld c, $0C
	xor a
.l4B4F:
	add a, c
	dec b
	jr nz, .l4B4F
	ld c, a
.l4B54:
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
	ld hl, B15_PeriodTable
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
	jr z, .l4B86
	ld l, TRK_VIBDELAYRELOAD
	ld a, [hl]
	ld l, TRK_VIBDELAY
	ld [hl], a
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call B15_VibratoStep
.l4B86:
	call B15_WritePeriod
	jp B15_NoteFinish

B15_VibratoTick:
	ld l, TRK_VIBTIMER
	ld a, [hl]
	or a
	jr z, .l4B94
	dec [hl]
	ret
.l4B94:
	call B15_VibratoStep
	jp B15_WritePeriod

B15_VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jp nc, .l4BA7
	inc b
.l4BA7:
	ld a, [bc]
	cp $FB
	jr z, .l4BF0
	cp $FE
	jr z, .l4BFA
	cp $FF
	jr z, .l4C18
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jp z, .l4BCA
	ld l, TRK_FLAGS
	set 3, [hl]
	jr .l4BCE
.l4BCA:
	ld l, TRK_FLAGS
	res 3, [hl]
.l4BCE:
	ld a, [bc]
	and $07
	ld l, TRK_VIBOFS
	ld [hl], a
	ld l, TRK_VIBDEPTH
	ld a, [hl]
	or a
	jp z, .l4BEC
	push bc
	xor a
	ld l, TRK_VIBOFS
	ld c, [hl]
	ld l, TRK_VIBDEPTH
	ld b, [hl]
.l4BE3:
	add a, c
	dec b
	jp nz, .l4BE3
	pop bc
	ld l, TRK_VIBOFS
	ld [hl], a
.l4BEC:
	ld l, TRK_VIBIDX
	inc [hl]
	ret
.l4BF0:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l4BA7
.l4BFA:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l4C0F
	cp $FF
	jr z, .l4C06
	inc [hl]
.l4C06:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jp B15_VibratoStep
.l4C0F:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc bc
	jp .l4BA7
.l4C18:
	ret

B15_NoteFinish:
	call B15_NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B15_WriteReg
	jp B15_Trigger

B15_NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l4C4C
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4C46
	xor a
.l4C46:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l4C4C:
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
	jr c, .l4C74
	xor a
.l4C74:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

B15_WritePeriod:
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
	jr z, .l4C93
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l4C93:
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

B15_WritePeriodBC:
	push bc
	ld a, c
	ld [wRegVal], a
	ld a, $03
	ld [wRegIdx], a
	call B15_WriteReg
	pop bc
	ld a, b
	ld [wRegVal], a
	ld a, $04
	ld [wRegIdx], a
	jp B15_WriteReg

B15_SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

B15_Rest:
	ld l, TRK_FLAGS2
	ld a, $08
	or [hl]
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B15_WriteReg

B15_DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, B15_DrumMap
	rst $28
	ld a, [hl]
	jp B15_PlayDrumSound

B15_WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4CF6
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp B15_WriteReg
.l4CF6:
	dec a
	push de
	push hl
	ld hl, B15_WaveTable
	call B15_LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l4D04:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l4D04
	pop hl
	pop de
	ret

B15_IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4D1B
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4D24
.l4D1B:
	cp $04
	jr nz, .l4D26
	ld a, [wTrkSfx2]
	or a
	ret z
.l4D24:
	scf
	ret
.l4D26:
	or a
	ret

B15_WriteReg:
	call B15_IsBlocked
	ret c
	push de
	call B15_GetRegAddr
	ld a, [wRegVal]
	ld c, a
	push hl
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4D46
	ld a, [hl]
	cp c
	jr z, .l4D49
.l4D46:
	ld a, c
	ld [hl], a
	ld [de], a
.l4D49:
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B15_Trigger:
	call B15_IsBlocked
	ret c
	push de
	ld a, $04
	ld [wRegIdx], a
	call B15_GetRegAddr
	ld a, [hl]
	or $80
	ld [de], a
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ret

B15_GetRegAddr:
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

B15_GetRegBase:
	ld a, [wTrackIdx]
	push hl
	ld hl, B15_RegBaseTable
	rst $28
	ld a, [hl]
	pop hl
	ret
B15_RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

B15_RawReader:
	ld l, TRK_RELTICK
	xor a
	ld [hl], a
	ld a, [de]
	cp $E1
	jr nz, B15_RawNext
	inc de
	ld a, [de]
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	ld a, [de]
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
	inc de
	ld a, [de]
	ld [wRegVal], a
	ld a, $00
	ld [wRegIdx], a
	call B15_WriteReg
	inc de

B15_RawNext:
	ld a, [de]
	or a
	jp z, B15_RawRest
	ld a, [de]
	cp $E7
	jr c, B15_RawNote
	cp $FB
	jp nc, B15_ReadCmds
	cp $F0
	jr nc, B15_RawNote
	ld a, [de]
	inc de
	sub $E7
	push hl
	call B15_JumpTableInline
	dw B15_RawNoteBack
	dw B15_RawNoteBack
	dw B15_Cmd_Sweep
	dw B15_Cmd_Ext
	dw B15_Cmd_LenUnit
	dw B15_RawNoteBack
	dw B15_RawNoteBack
	dw B15_RawNoteBack
	dw B15_Cmd_Pan

B15_RawNoteBack:
	dec de

B15_RawNote:
	ld l, TRK_PAN
	ld a, [hl]
	call B15_GetPanBits
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
	call B15_WritePeriodBC
	call B15_SavePtr
	dec de
	ld l, TRK_VOL
	ld a, [hl]
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call B15_WriteReg
	jp B15_Trigger

B15_RawRest:
	call B15_SavePtr
	dec de
	ld l, TRK_FLAGS2
	set 3, [hl]
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp B15_WriteReg

SndCE_Ch2:
	TEMPO $20
	VOICE 6, 9, 8, 0, 0
	REST 4
	SND_SEGNO
	SND_CALL SndCE_Ch2_4FA7
	DUTY 4
	ATTEN 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 1
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	VOICE 6, 8, 8, 3, $0A
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 3
	ATTEN 6
	NOTE A#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE G_, 1
	RELEASE 1, 8
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	VOICE 1, 9, 8, 0, 0
	NOTE A#, 1
	NOTE C_HI, 5
	VIBRATO 12, 0, 6
	LEN_UNIT 6
	NOTE C_HI, 8
	VOICE 6, 4, 8, 4, 4
	NOTE C_HI, 7
	VIBRATO_OFF $00
	SND_CALL SndCE_Ch2_4FA7
	DUTY 4
	ATTEN 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 1
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	VOICE 6, 9, 8, 3, $0A
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 0
	RELEASE 0, 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE D#, 1
	NOTE D_, 1
	RELEASE 1, 8
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	VOICE 1, 9, 8, 0, 0
	NOTE F#, 1
	NOTE G_, 5
	VOICE 6, 9, 8, 0, 0
	VIBRATO 12, 0, 4
	NOTE G_, 8
	VOICE 6, 3, 8, 4, 4
	NOTE G_, 7
	VIBRATO_OFF $00
	DUTY_STEP 8, 1
	VOICE 6, 8, 4, 4, 8
	OCTAVE 4
	NOTE D#, 6
	NOTE C#, 1
	NOTE C_, 1
	VOICE 6, 8, 4, 0, 0
	VIBRATO 12, 1, 4
	NOTE C#, 7
	DUTY_STEP 0, 0
	VIBRATO 12, 0, 4
	VOICE 6, 4, 4, 4, 8
	NOTE C#, 7
	VOICE 6, 8, 4, 3, $0A
	VIBRATO_OFF $00
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 3
	OCTAVE 4
	NOTE C#, 3
	NOTE G#, 2
	VOICE 6, 9, 4, 4, 8
	OCTAVE 4
	NOTE G#, 6
	NOTE F#, 1
	NOTE F_, 1
	VOICE 6, 8, 4, 0, 0
	VIBRATO 12, 1, 2
	NOTE F#, 8
	VOICE 6, 4, 4, 4, 4
	VIBRATO 12, 0, 2
	NOTE F#, 8
	VIBRATO_OFF $00
	DUTY_STEP 8, 1
	VOICE 6, 8, 4, 3, $0A
	NOTE C#, 4
	NOTE D#, 4
	VOICE 6, 8, 4, 3, $0E
	OCTAVE 4
	NOTE F#, 3
	NOTE F_, 3
	NOTE C#, 2
	VOICE 6, 8, 4, 0, 0
	VIBRATO 12, 1, 4
	OCTAVE 3
	NOTE G#, 5
	VOICE 6, 4, 4, 4, 4
	VIBRATO 12, 0, 4
	NOTE G#, 3
	VIBRATO_OFF $00
	VOICE 6, 9, 4, 3, $0E
	DUTY_STEP 8, 2
	RELEASE 2, 9
	OCTAVE 4
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 1
	ATTEN 1
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	RELEASE 2, 7
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 4, 8
	OCTAVE 3
	NOTE C_HI, 2
	NOTE F_, 1
	VOICE 6, 8, 4, 0, 0
	VIBRATO 12, 1, 3
	OCTAVE 4
	NOTE F_, 8
	VOICE 6, 4, 4, 4, 4
	VIBRATO 12, 0, 3
	NOTE F_, 5
	VIBRATO_OFF $00
	VOICE 6, 8, 4, 4, 8
	OCTAVE 3
	NOTE A#, 2
	NOTE E_, 1
	VIBRATO 12, 1, 3
	VOICE 6, 8, 4, 0, 0
	OCTAVE 4
	NOTE E_, 6
	VIBRATO 12, 0, 3
	VOICE 6, 4, 4, 4, 4
	NOTE E_, 4
	VIBRATO_OFF $00
	VOICE 6, 8, 8, 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_LOOP
SndCE_Ch2_4FA7:
	VOICE 1, 9, 8, 0, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, $0B
	VOICE 6, 9, 8, 0, 0
	VIBRATO 12, 0, 3
	NOTE C_HI, 5
	VOICE 6, 4, 8, 4, 4
	NOTE C_HI, 5
	VOICE 6, 9, 8, 5, 8
	VIBRATO_OFF $00
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	RELEASE 0, 0
	LEN_UNIT 1
	NOTE F#, 2
	NOTE G_, 4
	LEN_UNIT 6
	VIBRATO 12, 0, 4
	NOTE G_, 4
	VIBRATO_OFF $00
	SND_RET

SndCE_Ch1:
	VOICE 6, 9, 8, 0, 0
	REST 4
	SND_SEGNO
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 5
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F_, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 5
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 5
	NOTE D_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C#, 1
	NOTE D#, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE C#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE C#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE C#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 5
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C#, 1
	VOICE 6, 5, 0, 2, $0C
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_LOOP

SndCE_Ch3:
	TRANSPOSE_UP $0C
	VOICE 6, 9, 8, 0, 0
	REST 4
	SND_SEGNO
	VOICE 2, 2, 5, 0, 0
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 5
	VOICE 6, 2, 5, 4, 6
	NOTE C_HI, 6
	VOICE 6, 2, 5, 4, 6
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 1
	NOTE G_, 9
	NOTE C_HI, 3
	NOTE G_, 3
	NOTE C_HI, 2
	VOICE 6, 2, 5, 4, 6
	OCTAVE 1
	NOTE D#, 8
	OCTAVE 2
	NOTE C#, 3
	NOTE D#, 3
	OCTAVE 1
	NOTE A#, 2
	VOICE 1, 2, 5, 0, 0
	NOTE E_, 2
	NOTE F_, 4
	VOICE 6, 2, 5, 4, 6
	NOTE F_, $0A
	VOICE 2, 2, 5, 0, 0
	NOTE B_, 1
	NOTE C_HI, 2
	VOICE 6, 2, 5, 5, 6
	NOTE C_HI, 2
	VOICE 6, 2, 5, 4, 8
	OCTAVE 2
	NOTE D#, 2
	VOICE 2, 2, 5, 0, 0
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 5
	VOICE 6, 2, 5, 4, 8
	NOTE C_HI, 6
	VOICE 6, 2, 5, 4, 8
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 1
	NOTE G_, 9
	NOTE C_HI, 3
	NOTE G_, 3
	NOTE C_HI, 2
	VOICE 1, 2, 5, 0, 0
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, $0A
	VOICE 6, 2, 5, 4, 6
	NOTE A#, 6
	NOTE G#, 3
	NOTE A#, 3
	NOTE F_, 2
	VOICE 2, 2, 5, 0, 0
	NOTE B_, 1
	NOTE C_HI, 2
	VOICE 6, 2, 5, 4, 6
	NOTE C_HI, 7
	VOICE 2, 2, 5, 4, 8
	NOTE B_, 1
	NOTE C_HI, 2
	VOICE 6, 2, 5, 4, 8
	NOTE C_HI, 2
	NOTE G_, 3
	NOTE A#, 2
	VOICE 1, 2, 5, 0, 0
	OCTAVE 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C#, 3
	VOICE 6, 2, 5, 4, 5
	NOTE C#, $0D
	VOICE 6, 2, 5, 4, 8
	OCTAVE 1
	NOTE G#, 2
	VOICE 6, 2, 5, 4, 5
	OCTAVE 2
	NOTE C#, $0E
	VOICE 6, 2, 5, 4, 8
	NOTE C_, 2
	VOICE 1, 2, 5, 4, 8
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 4
	VOICE 6, 2, 5, 4, 5
	OCTAVE 1
	NOTE B_, $0D
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, $0E
	NOTE B_, 1
	NOTE C_HI, 1
	VOICE 1, 2, 5, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 5
	VOICE 6, 2, 5, 4, 5
	OCTAVE 2
	NOTE C#, $0D
	OCTAVE 1
	NOTE G#, 2
	VOICE 1, 2, 5, 0, 0
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 3
	VOICE 6, 2, 5, 4, 5
	NOTE B_, $0F
	VOICE 1, 2, 5, 0, 0
	OCTAVE 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 3
	VOICE 6, 2, 5, 5, 5
	NOTE F_, $0B
	VOICE 6, 2, 5, 4, 8
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	VOICE 1, 2, 5, 0, 0
	OCTAVE 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 3
	VOICE 6, 2, 5, 5, 5
	NOTE E_, $0B
	VOICE 6, 2, 5, 4, 8
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_LOOP

SndCE_Drm:
	DRUM_UNIT 1
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM 4, $0C
	SND_SEGNO
	DRUM_UNIT 6
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
	DRUM $0B, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 4, 2
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
	DRUM $0B, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM_UNIT 1
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM_UNIT 6
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 4, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
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
	DRUM_UNIT 1
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM_UNIT 6
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0C, 1
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
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
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
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM_UNIT 1
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM_UNIT 6
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 4, 2
	SND_LOOP

SndCF_Ch2:
	VOICE 5, $0A, 4, 3, 6
	OCTAVE 3
	LEN_UNIT 1
	DUTY_STEP 8, 1
	ATTEN 5
	NOTE C_, 6
	ATTEN 3
	NOTE G_, 7
	ATTEN 0
	NOTE C_HI, 7
	NOTE B_, 6
	ATTEN 3
	NOTE F#, 7
	ATTEN 5
	OCTAVE 2
	NOTE B_, 7
	LEN_UNIT 1
	OCTAVE 3
	ATTEN 4
	RELEASE 2, $0E
	NOTE C_, 5
	ATTEN 3
	NOTE F#, 5
	ATTEN 2
	NOTE C_HI, 5
	ATTEN 0
	OCTAVE 4
	NOTE F#, 5
	ATTEN 5
	OCTAVE 2
	NOTE B_, 5
	ATTEN 3
	OCTAVE 3
	NOTE F#, 5
	ATTEN 2
	NOTE B_, 5
	ATTEN 0
	OCTAVE 4
	NOTE F#, 5
	VOICE 1, $0B, 4, 1, $0D
	NOTE B_, 4
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	NOTE F#, 5
	ATTEN 6
	NOTE F#, 2
	ATTEN 0
	NOTE C_, 5
	ATTEN 6
	NOTE C_, 2
	ATTEN 3
	ATTEN 3
	NOTE B_, 4
	ATTEN 7
	NOTE B_, 2
	ATTEN 3
	NOTE F#, 5
	ATTEN 7
	NOTE F#, 2
	ATTEN 3
	NOTE C_, 5
	ATTEN 7
	NOTE C_, 2
	ATTEN 6
	NOTE B_, 7
	NOTE F#, 8
	NOTE C_, 9
	ATTEN 7
	NOTE B_, 9
	NOTE F#, $0A
	NOTE C_, $0B
	ATTEN 0
	VOICE 1, $0A, 0, 0, $0F
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 3
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 4
	RELEASE 3, $0E
	ATTEN 2
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 5
	ATTEN 1
	OCTAVE 4
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 5
	RELEASE 0, $0F
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 4
	RELEASE 3, $0E
	ATTEN 0
	OCTAVE 4
	NOTE D#, 7
	ATTEN 0
	VOICE $0B, $0A, 4, 4, 8
	VIBRATO 12, 3, 2
	NOTE A_, 6
	SND_END

SndCF_Ch1:
	VOICE 5, 5, 8, 3, 7
	OCTAVE 3
	LEN_UNIT 1
	REST 6
	ATTEN 3
	NOTE C_, 6
	RELEASE 1, 8
	ATTEN 1
	NOTE G_, 7
	ATTEN 0
	NOTE C_HI, 7
	NOTE B_, 6
	ATTEN 1
	NOTE F#, 7
	RELEASE 2, 8
	ATTEN 3
	OCTAVE 2
	NOTE B_, 1
	LEN_UNIT 1
	OCTAVE 3
	ATTEN 3
	REST 4
	NOTE C_, 5
	RELEASE 1, 8
	ATTEN 1
	NOTE F#, 5
	ATTEN 1
	NOTE C_HI, 5
	ATTEN 0
	OCTAVE 4
	NOTE F#, 5
	ATTEN 3
	OCTAVE 2
	NOTE B_, 5
	ATTEN 1
	OCTAVE 3
	NOTE F#, 5
	ATTEN 1
	NOTE B_, 5
	ATTEN 0
	OCTAVE 4
	NOTE F#, 1
	VOICE 1, 8, 8, 1, $0D
	PAN $0F
	REST 5
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	NOTE F#, 5
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE C_, 5
	ATTEN 4
	NOTE C_, 2
	PAN $F0
	ATTEN 2
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 2
	ATTEN 2
	NOTE F#, 5
	ATTEN 4
	NOTE F#, 2
	ATTEN 2
	NOTE C_, 5
	ATTEN 4
	NOTE C_, 2
	PAN $0F
	ATTEN 3
	NOTE B_, 7
	NOTE F#, 8
	NOTE C_, 9
	PAN $F0
	ATTEN 4
	NOTE B_, 9
	NOTE F#, $0A
	NOTE C_, 6
	PAN $FF
	ATTEN 0
	VOICE 1, 9, 0, 0, $0F
	ATTEN 2
	OCTAVE 2
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 5
	OCTAVE 3
	RELEASE 2, $0F
	ATTEN 2
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 5
	ATTEN 1
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 5
	RELEASE 0, $0F
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 5
	RELEASE 2, $0F
	ATTEN 0
	NOTE A_, 7
	VOICE $0B, 9, 4, 4, 8
	VIBRATO 12, 2, 1
	OCTAVE 4
	NOTE D#, 6
	SND_END

SndCF_Ch3:
	VOICE 1, 4, 1, 4, 8
	OCTAVE 2
	NOTE C_, 6
	NOTE C_HI, 7
	NOTE C_, 7
	NOTE F#, 6
	NOTE B_, 7
	NOTE F#, 7
	NOTE C_, 6
	NOTE C_HI, 7
	NOTE C_, 7
	NOTE C_HI, 6
	NOTE C_, 7
	NOTE C_HI, 7
	LEN_UNIT 5
	OCTAVE 3
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 7
	LEN_UNIT $0B
	VIBRATO 12, 0, 15
	ATTEN 1
	NOTE F#, 4
	VIBRATO_OFF $00
	ATTEN 0
	VOICE 1, 4, 1, 3, 8
	OCTAVE 1
	NOTE A#, 6
	NOTE D#, 7
	NOTE A#, 7
	NOTE D#, 6
	NOTE A_, 7
	VOICE $0B, 2, 1, 5, 7
	OCTAVE 3
	NOTE D#, 6
	SND_END

SndCF_Drm:
	DRUM_UNIT 1
	LOOP_START
	DRUM 1, 6
	DRUM 1, 7
	DRUM 1, 7
	LOOP_END 5
	REST 6
	REST 6
	REST 7
	LEN_UNIT 9
	REST 6
	LEN_UNIT 1
	DRUM 1, 6
	DRUM 1, 7
	DRUM 1, 7
	DRUM 1, 6
	DRUM 1, 7
	DRUM 2, 7
	SND_END

SndD0_Ch2:
	TEMPO $0C
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP_START
	SND_CALL SndD0_Ch2_557B
	REST 6
	VOICE 5, 8, 4, 1, $0B
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	TRANSPOSE_UP 4
	SND_CALL SndD0_Ch2_557B
	TRANSPOSE_UP 1
	PAN $FF
	VOICE 5, 8, 4, 1, $0B
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	DUTY_STEP 4, 2
	VOICE 5, 8, 8, 1, $0A
	VIBRATO 8, 0, 2
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	VOICE 5, 5, 4, $0E, $0C
	VIBRATO 12, 0, 3
	OCTAVE 4
	NOTE C#, $0A
	VOICE 5, 8, 8, 1, $0A
	VIBRATO 8, 0, 2
	OCTAVE 3
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	DUTY_STEP 0, 0
	VOICE 5, 8, 4, 4, 8
	VIBRATO_OFF $00
	OCTAVE 4
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE C#, 2
	ATTEN 5
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 1
	ATTEN 0
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 1
	ATTEN 0
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 1
	ATTEN 0
	LOOP_END 2
	VOICE 5, 8, 4, 2, $0A
	REST 3
	OCTAVE 4
	NOTE D_, 7
	VIBRATO 12, 1, 3
	RELEASE 4, 6
	NOTE C_, $0E
	DUTY_STEP 0, 1
	NOTE F_, 2
	NOTE F#, 2
	VOICE 5, 8, 4, $0C, $0E
	NOTE G_, 8
	DUTY_STEP 0, 0
	VOICE 5, 8, 4, 2, $0A
	REST 3
	OCTAVE 4
	NOTE D_, 7
	VIBRATO 12, 1, 3
	RELEASE 4, 6
	NOTE C_, $0E
	DUTY_STEP 0, 1
	OCTAVE 3
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	VOICE 5, 8, 0, 4, 8
	REST 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 4
	NOTE F#, 2
	SND_LOOP
SndD0_Ch2_557B:
	VOICE 5, 9, 4, 3, $0B
	OCTAVE 3
	NOTE E_, 2
	PAN $0F
	NOTE E_, 4
	PAN $FF
	OCTAVE 3
	NOTE D_, 2
	PAN $F0
	NOTE D_, 4
	PAN $FF
	OCTAVE 3
	NOTE E_, 2
	PAN $0F
	NOTE E_, 4
	PAN $FF
	OCTAVE 3
	NOTE G_, 2
	PAN $F0
	NOTE G_, 4
	PAN $0F
	OCTAVE 3
	NOTE F#, 4
	ATTEN 2
	NOTE F#, 2
	PAN $FF
	DUTY 0
	ATTEN 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	DUTY 4
	ATTEN 0
	PAN $F0
	OCTAVE 3
	NOTE D_, 4
	ATTEN 2
	NOTE D_, 2
	PAN $FF
	DUTY 0
	ATTEN 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 0
	DUTY 4
	ATTEN 2
	OCTAVE 3
	NOTE E_, 4
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	SND_RET

SndD0_Ch1:
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP2_START
	SND_CALL SndD0_Ch1_5683
	ATTEN 0
	OCTAVE 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	TRANSPOSE_UP 4
	SND_CALL SndD0_Ch1_5683
	TRANSPOSE_UP 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	RELEASE 2, $0A
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOICE 5, 6, 8, 2, $0F
	LOOP_START
	OCTAVE 3
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE F_, 2
	LOOP_END 2
	VOICE 5, 6, 0, 1, $0A
	OCTAVE 4
	ATTEN 3
	NOTE F_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 2
	OCTAVE 5
	NOTE C#, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 0
	VOICE 5, 5, 8, 1, $0A
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 2
	RELEASE 2, $0A
	OCTAVE 3
	LOOP_START
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	LOOP_END 3
	NOTE F_, 2
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 1
	ATTEN 0
	LOOP2_END 2
	VOICE 5, 6, 4, 4, $0A
	OCTAVE 3
	REST 3
	NOTE A_, 7
	NOTE G_, 2
	VOICE 5, 6, 0, 2, $0C
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE C_, 2
	VOICE 5, 6, 4, 4, $0A
	REST 3
	NOTE A_, 7
	NOTE G_, 2
	VOICE 5, 6, 0, 2, $0C
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	REST 2
	RELEASE 0, $0F
	ATTEN 1
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	ATTEN 0
	VOICE 5, 6, 4, 1, $0A
	REST 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 4
	NOTE B_, 2
	SND_LOOP
SndD0_Ch1_5683:
	VOICE 5, 6, 4, 3, $0A
	OCTAVE 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 4
	ATTEN 0
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE C_HI, 2
	ATTEN 2
	NOTE C_HI, 4
	ATTEN 0
	RELEASE 0, $0F
	NOTE B_, 3
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 3
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	RELEASE 4, 8
	SND_RET

SndD0_Ch3:
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP2_START
	VOICE 5, 4, $0E, 4, $0A
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP_START
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 2
	LOOP_END 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	VOICE 5, 4, $0E, 4, $0A
	LOOP_START
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE A#, 2
	LOOP_END 4
	NOTE F#, 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE A#, 2
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE A#, 2
	LOOP_END 4
	VOICE 5, 4, $0E, 4, $0A
	OCTAVE 1
	NOTE A#, 3
	NOTE G#, 3
	NOTE G_, 3
	OCTAVE 2
	NOTE F_, 3
	NOTE D#, 3
	NOTE C#, 3
	LOOP2_END 2
	VOICE 5, 4, $0E, 4, $0A
	OCTAVE 2
	LOOP_START
	NOTE D_, 6
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	LOOP_END 2
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	LOOP_START
	NOTE D_, 6
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	LOOP_END 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	VOICE 5, 4, 8, 4, 8
	REST 2
	NOTE B_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE C#, 4
	NOTE D_, 2
	SND_LOOP

SndD0_Drm:
	SND_SEGNO
	LOOP2_START
	DRUM_UNIT 5
	SND_CALL SndD0_Drm_57AE
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 2, 2
	SND_CALL SndD0_Drm_57AE
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0A, 2
	SND_CALL SndD0_Drm_57CA
	DRUM 2, 3
	DRUM 2, 3
	DRUM $0A, 4
	SND_CALL SndD0_Drm_57CA
	DRUM 9, 3
	DRUM 9, 3
	DRUM 2, 3
	DRUM 9, 3
	DRUM 2, 3
	DRUM $0A, 3
	LOOP2_END 2
	LOOP2_START
	LOOP_START
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	LOOP_END 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0D, 2
	DRUM 7, 2
	LOOP2_END 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	REST 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 4
	DRUM 9, 2
	SND_LOOP
SndD0_Drm_57AE:
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	SND_RET
SndD0_Drm_57CA:
	LOOP_START
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 2, 2
	LOOP_END 2
	SND_RET

SndD1_Ch2:
	TEMPO $30
	VOICE 5, $0A, 0, 4, $0A
	OCTAVE 4
	NOTE C_HI, 1
	ATTEN 2
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 4
	RELEASE 0, $0F
	VIBRATO 1, 0, 2
	OCTAVE 3
	NOTE F#, 3
	ATTEN 0
	VIBRATO_OFF $00
	LEN_UNIT 1
	DUTY_STEP 8, 1
	ATTEN 8
	NOTE G_, 3
	NOTE G#, 2
	NOTE A_, 3
	ATTEN 5
	NOTE A#, 2
	NOTE B_, 3
	NOTE C_HI, 2
	ATTEN 3
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, 2
	NOTE D#, 3
	ATTEN 1
	NOTE E_, 2
	NOTE F_, 3
	NOTE F#, 2
	ATTEN 4
	RELEASE 0, $0F
	ATTEN 0
	OCTAVE 5
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	ATTEN 8
	NOTE C#, 5
	ATTEN 4
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	ATTEN 8
	NOTE C#, 5
	ATTEN 2
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	ATTEN 8
	NOTE C#, 5
	ATTEN 0
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	VOICE 5, $0A, 0, 4, $0A
	OCTAVE 4
	NOTE G#, 1
	ATTEN 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	DUTY_STEP 8, 1
	RELEASE 0, $0F
	LEN_UNIT 1
	ATTEN 7
	NOTE A_, 3
	NOTE A#, 2
	NOTE B_, 3
	ATTEN 5
	NOTE C_HI, 2
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, 2
	ATTEN 3
	NOTE D#, 3
	NOTE E_, 2
	NOTE F_, 3
	ATTEN 1
	NOTE F#, 2
	NOTE G_, 3
	NOTE G#, 2
	ATTEN 0
	OCTAVE 5
	NOTE D#, 4
	REST 1
	NOTE D#, 4
	REST 1
	ATTEN 8
	NOTE D#, 5
	ATTEN 3
	NOTE D#, 4
	REST 1
	NOTE D#, 4
	REST 1
	ATTEN 8
	NOTE D#, 5
	ATTEN 1
	NOTE D#, 4
	REST 1
	NOTE D#, 4
	REST 1
	ATTEN 8
	NOTE D#, 5
	ATTEN 0
	NOTE D#, 4
	REST 1
	NOTE D#, 4
	REST 1
	ATTEN 8
	NOTE D#, 5
	ATTEN 0
	DUTY_STEP 0, 0
	TEMPO $00
	SND_CALL SndD1_Ch2_5918
	VOICE 5, 9, 8, 2, $0B
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 4
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 0
	TRANSPOSE_UP 2
	LOOP_END 2
	TRANSPOSE_UP 0
	LOOP_START
	VOICE 5, $0E, 4, 4, $0F
	PAN $0F
	OCTAVE 5
	NOTE D_, 1
	ATTEN 4
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	PAN $F0
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 4
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	PAN $FF
	ATTEN 0
	VOICE 5, $0A, 4, 2, $0B
	ATTEN 2
	NOTE D_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE D_, 1
	TRANSPOSE_UP 1
	LOOP_END 2
	SND_CALL SndD1_Ch2_5918
	LOOP_START
	TRANSPOSE_UP 0
	VOICE 1, $0B, 0, 0, $0F
	OCTAVE 4
	NOTE C_HI, 4
	REST 1
	NOTE C_HI, 4
	REST 1
	LEN_UNIT 5
	ATTEN 9
	NOTE C_HI, 2
	ATTEN 5
	DUTY_STEP 4, 3
	RELEASE 2, $0B
	OCTAVE 3
	NOTE C_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 9
	NOTE F#, 1
	ATTEN 0
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	VOICE 1, $0B, 0, 0, $0F
	OCTAVE 5
	NOTE C#, 4
	REST 1
	NOTE C#, 4
	REST 1
	LEN_UNIT 5
	ATTEN 9
	NOTE C#, 2
	ATTEN 5
	DUTY_STEP 4, 3
	RELEASE 2, $0B
	OCTAVE 3
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	ATTEN 9
	NOTE C#, 1
	ATTEN 0
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	LOOP_END 3
	SND_END
SndD1_Ch2_5918:
	VOICE 5, $0C, 4, 2, $0B
	LOOP2_START
	TRANSPOSE_UP 0
	LOOP_START
	PAN $FF
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	PAN $FF
	ATTEN 0
	NOTE A_, 1
	NOTE E_, 1
	PAN $F0
	ATTEN 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	TRANSPOSE_UP 1
	ATTEN 0
	LOOP_END 2
	PAN $FF
	LOOP2_END 2
	SND_RET

SndD1_Ch1:
	VOICE 5, 7, 0, 4, $0A
	OCTAVE 4
	NOTE F#, 1
	ATTEN 2
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	ATTEN 4
	RELEASE 0, $0F
	NOTE C_, 3
	LEN_UNIT 1
	ATTEN 6
	NOTE C#, 3
	NOTE D_, 2
	NOTE D#, 3
	ATTEN 4
	NOTE E_, 2
	NOTE F_, 3
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 3
	NOTE G#, 2
	NOTE A_, 3
	ATTEN 1
	NOTE A#, 2
	NOTE B_, 3
	NOTE C_HI, 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 4
	REST 1
	NOTE G_, 4
	REST 1
	ATTEN 5
	NOTE G_, 5
	ATTEN 3
	NOTE G_, 4
	REST 1
	NOTE G_, 4
	REST 1
	ATTEN 5
	NOTE G_, 5
	ATTEN 2
	NOTE G_, 4
	REST 1
	NOTE G_, 4
	REST 1
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	NOTE G_, 4
	REST 1
	NOTE G_, 4
	REST 1
	NOTE G_, 4
	REST 1
	VOICE 5, 7, 0, 4, $0A
	OCTAVE 4
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	ATTEN 0
	LEN_UNIT 1
	ATTEN 6
	NOTE D#, 3
	NOTE E_, 2
	NOTE F_, 3
	ATTEN 4
	NOTE F#, 2
	NOTE G_, 3
	NOTE G#, 2
	ATTEN 2
	NOTE A_, 3
	NOTE A#, 2
	NOTE B_, 3
	ATTEN 1
	NOTE C_HI, 2
	OCTAVE 4
	NOTE C#, 3
	NOTE D_, 2
	ATTEN 0
	OCTAVE 4
	NOTE A_, 4
	REST 1
	NOTE A_, 4
	REST 1
	ATTEN 5
	NOTE A_, 5
	ATTEN 1
	NOTE A_, 4
	REST 1
	NOTE A_, 4
	REST 1
	ATTEN 5
	NOTE A_, 5
	ATTEN 1
	NOTE A_, 4
	REST 1
	NOTE A_, 4
	REST 1
	ATTEN 5
	NOTE A_, 5
	ATTEN 0
	NOTE A_, 4
	REST 1
	NOTE A_, 4
	REST 1
	ATTEN 5
	NOTE A_, 5
	ATTEN 0
	SND_CALL SndD1_Ch1_5A65
	VOICE 5, 6, 8, 2, $0B
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	ATTEN 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	TRANSPOSE_UP 2
	LOOP_END 2
	TRANSPOSE_UP 0
	SND_CALL SndD1_Ch1_5A8C
	PAN $F0
	VOICE 5, $0B, 4, 2, $0B
	NOTE D_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE D_, 1
	TRANSPOSE_UP 1
	SND_CALL SndD1_Ch1_5A8C
	PAN $0F
	VOICE 5, $0B, 4, 2, $0B
	NOTE D_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	SND_CALL SndD1_Ch1_5A65
	VIBRATO 11, 0, 2
	LOOP_START
	VOICE 5, $0B, 8, 2, $0B
	TRANSPOSE_UP 0
	PAN $0F
	OCTAVE 4
	NOTE F#, 1
	PAN $F0
	NOTE F#, 1
	PAN $FF
	ATTEN 8
	NOTE F#, 2
	DUTY 4
	ATTEN 6
	OCTAVE 2
	NOTE C_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	ATTEN 9
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	ATTEN 0
	PAN $0F
	OCTAVE 4
	NOTE G_, 1
	PAN $F0
	NOTE G_, 1
	PAN $FF
	DUTY 4
	ATTEN 8
	NOTE G_, 2
	ATTEN 6
	OCTAVE 2
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 9
	NOTE C#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	ATTEN 0
	LOOP_END 3
	SND_END
SndD1_Ch1_5A65:
	LOOP2_START
	VIBRATO 11, 0, 3
	VOICE 5, 8, 4, 2, $0B
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	TRANSPOSE_UP 1
	LOOP_END 2
	LOOP2_END 2
	SND_RET
SndD1_Ch1_5A8C:
	PAN $FF
	VOICE 5, 7, 4, 2, $0B
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	VOICE 5, 7, 8, 2, $0B
	ATTEN 4
	NOTE D_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET

SndD1_Ch3:
	LOOP_START
	VOICE 1, 2, 1, 4, $0A
	LOOP2_START
	OCTAVE 1
	NOTE F#, 5
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 7
	LOOP2_END 3
	LEN_UNIT 5
	OCTAVE 2
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	TRANSPOSE_UP 1
	LOOP_END 2
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	TRANSPOSE_UP 1
	LOOP_END 2
	TRANSPOSE_UP 0
	VOICE 5, 2, 1, 2, $0B
	LOOP2_START
	TRANSPOSE_UP 0
	SND_CALL SndD1_Ch3_5B60
	TRANSPOSE_UP 1
	SND_CALL SndD1_Ch3_5B60
	LOOP2_END 2
	TRANSPOSE_UP 0
	LOOP_START
	VOICE 5, 2, 1, 3, 8
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	LOOP_END 8
	LOOP_START
	NOTE C#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END 3
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	LOOP2_START
	VOICE 5, 2, 1, 3, $0A
	LOOP_START
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END 4
	TRANSPOSE_UP 1
	LOOP2_END 2
	VOICE 5, 2, 1, 2, $0B
	LOOP2_START
	TRANSPOSE_UP 0
	SND_CALL SndD1_Ch3_5B49
	TRANSPOSE_UP 1
	SND_CALL SndD1_Ch3_5B49
	LOOP2_END 2
	VOICE 5, 2, 1, 2, $0B
	LOOP2_START
	TRANSPOSE_UP 0
	SND_CALL SndD1_Ch3_5B53
	TRANSPOSE_UP 1
	SND_CALL SndD1_Ch3_5B53
	LOOP2_END 3
	SND_END
SndD1_Ch3_5B49:
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	LOOP_END 4
	SND_RET
SndD1_Ch3_5B53:
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_HI, 1
	LOOP_END 2
	SND_RET
SndD1_Ch3_5B60:
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	LOOP_END 4
	SND_RET

SndD1_Drm:
	DRUM_UNIT 5
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 3
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 5, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 1
	LOOP_END 2
	SND_CALL SndD1_Drm_5BC5
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END 2
	LOOP_START
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END 2
	SND_CALL SndD1_Drm_5BC5
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	LOOP_END 6
	SND_END
SndD1_Drm_5BC5:
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	LOOP_END 2
	SND_RET

SndD2_Ch2:
	LOOP_START
	VOICE 9, 9, 8, 1, $0C
	ATTEN 5
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 3
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 5
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 6
	OCTAVE 4
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	ATTEN 5
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	ATTEN 6
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	LOOP_END 2
	SND_SEGNO
	LOOP_START
	VOICE 9, 8, 8, 4, 9
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	VIBRATO 12, 1, 4
	ATTEN 1
	OCTAVE 4
	NOTE E_, 4
	VIBRATO_OFF $00
	ATTEN 0
	NOTE E_, 1
	NOTE A_, 1
	VIBRATO 12, 1, 3
	ATTEN 1
	OCTAVE 5
	NOTE E_, 4
	SND_CALL SndD2_Ch2_5D6F
	VOICE 9, 8, 8, 4, 8
	ATTEN 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	VIBRATO 12, 1, 4
	ATTEN 1
	OCTAVE 4
	NOTE E_, 3
	VIBRATO_OFF $00
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	VIBRATO 12, 1, 3
	ATTEN 1
	OCTAVE 5
	NOTE E_, 3
	RELEASE 1, 8
	VIBRATO_OFF $00
	SND_CALL SndD2_Ch2_5D6F
	SND_CALL SndD2_Ch2_5D57
	VOICE 9, 8, 4, 1, $0C
	ATTEN 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	ATTEN 0
	NOTE E_, 1
	SND_CALL SndD2_Ch2_5D57
	VOICE 9, 8, 4, 1, $0C
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	ATTEN 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 0
	NOTE F_, 1
	LOOP_END 2
	SND_CALL SndD2_Ch2_5D0E
	DUTY_STEP 0, 0
	VOICE 9, 8, 8, 4, $0A
	NOTE F_, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	VOICE 9, 7, 8, 4, 8
	VIBRATO 12, 1, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 6
	VIBRATO_OFF $00
	SND_CALL SndD2_Ch2_5D0E
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	DUTY_STEP 0, 0
	VOICE 9, $0A, 0, 4, 9
	ATTEN 4
	NOTE E_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE F_, 1
	SND_LOOP
SndD2_Ch2_5D0E:
	VOICE 9, $0A, 0, 1, 9
	ATTEN 4
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	RELEASE 1, $0B
	ATTEN 3
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 2
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 3
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	RELEASE 1, 9
	ATTEN 6
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 4, 1
	VOICE 9, 7, 8, 1, $0A
	ATTEN 4
	NOTE E_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	SND_RET
SndD2_Ch2_5D57:
	VOICE 9, $0A, 8, 1, $0A
	REST 1
	OCTAVE 4
	ATTEN 7
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	VOICE 9, 8, 8, 2, $0A
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_RET
SndD2_Ch2_5D6F:
	VOICE 9, 7, 8, 4, 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	RELEASE 4, 8
	NOTE A#, 3
	VOICE 9, $0B, 0, 1, $0C
	PAN $F0
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A#, 1
	PAN $0F
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	PAN $FF
	SND_RET

SndD2_Ch1:
	LOOP_START
	VOICE 9, 7, 4, 2, $0C
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 3
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 3
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 3
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 0
	LOOP_END 2
	SND_SEGNO
	LOOP2_START
	VOICE 9, 6, 4, 2, $0A
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 3, 8
	ATTEN 0
	NOTE A_, 4
	RELEASE 2, $0A
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 3, 8
	OCTAVE 4
	NOTE A_, 4
	ATTEN 1
	SND_CALL SndD2_Ch1_5ECD
	VOICE 9, 6, 8, 2, 9
	OCTAVE 3
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 4, 8
	ATTEN 0
	NOTE A_, 3
	RELEASE 2, 9
	ATTEN 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 3, 8
	ATTEN 0
	NOTE A_, 3
	ATTEN 1
	SND_CALL SndD2_Ch1_5ECD
	SND_CALL SndD2_Ch1_5EE7
	SND_CALL SndD2_Ch1_5F05
	SND_CALL SndD2_Ch1_5EE7
	TRANSPOSE_UP 1
	SND_CALL SndD2_Ch1_5F05
	TRANSPOSE_UP 0
	LOOP2_END 2
	SND_CALL SndD2_Ch1_5E7E
	VOICE 9, 4, 4, 4, 8
	OCTAVE 4
	NOTE E_, 3
	NOTE D_, 3
	VOICE 9, $0A, 0, 4, 8
	NOTE C#, 1
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 3
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 0
	SND_CALL SndD2_Ch1_5E7E
	VOICE 9, 8, 4, 4, 9
	OCTAVE 4
	ATTEN 4
	NOTE C_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE D_, 1
	SND_LOOP
SndD2_Ch1_5E7E:
	PAN $F0
	VOICE 1, 4, 0, 2, 7
	REST 7
	LEN_UNIT 9
	ATTEN 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	LEN_UNIT 1
	NOTE D_, 2
	ATTEN 0
	PAN $FF
	VOICE 9, 4, 8, 2, $0A
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE C_, 1
	VOICE 9, 4, 4, 2, 7
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE A#, 1
	SND_RET
SndD2_Ch1_5ECD:
	OCTAVE 3
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	RELEASE 1, 7
	NOTE D#, 1
	ATTEN 0
	VOICE 9, 5, 8, 4, 8
	NOTE D#, 3
	VOICE 9, 4, 0, 1, $0C
	OCTAVE 4
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	SND_RET
SndD2_Ch1_5EE7:
	VOICE 9, 8, 8, 1, $0A
	OCTAVE 4
	REST 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	VOICE 9, 6, 8, 3, 8
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	VOICE 1, 4, 8, 3, 8
	REST 8
	ATTEN 1
	SND_RET
SndD2_Ch1_5F05:
	OCTAVE 4
	NOTE D#, 9
	OCTAVE 3
	NOTE A#, 9
	NOTE E_, 9
	OCTAVE 4
	NOTE D#, 9
	OCTAVE 3
	NOTE A#, 9
	NOTE E_, 9
	OCTAVE 5
	NOTE D#, 9
	OCTAVE 4
	NOTE A#, 9
	NOTE E_, 9
	OCTAVE 5
	NOTE D#, 9
	OCTAVE 4
	NOTE A#, 9
	NOTE E_, 1
	ATTEN 0
	SND_RET

SndD2_Ch3:
	VOICE 9, 3, 8, 2, $0A
	LOOP2_START
	LOOP_START
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
	LOOP_END 4
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END 4
	LOOP2_END 2
	SND_SEGNO
	LOOP2_START
	VOICE 9, 2, 8, 3, 8
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	LOOP_END 2
	SND_CALL SndD2_Ch3_5FE0
	SND_CALL SndD2_Ch3_6024
	SND_CALL SndD2_Ch3_5FE0
	TRANSPOSE_UP 1
	SND_CALL SndD2_Ch3_6024
	TRANSPOSE_UP 0
	LOOP2_END 2
	SND_CALL SndD2_Ch3_5FF9
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_CALL SndD2_Ch3_5FF9
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_LOOP
SndD2_Ch3_5FE0:
	VOICE 9, 2, 8, 3, $0A
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 4, 8
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	VOICE 9, 2, 5, 3, $0A
	SND_RET
SndD2_Ch3_5FF9:
	VOICE 9, 2, 8, 3, $0A
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	SND_RET
SndD2_Ch3_6024:
	LOOP_START
	PAN $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	PAN $F0
	OCTAVE 2
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	LOOP_END 2
	PAN $FF
	SND_RET

SndD2_Drm:
	DRUM_UNIT 1
	DRUM 1, 5
	DRUM 1, 4
	DRUM_UNIT 9
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_CALL SndD2_Drm_6120
	SND_CALL SndD2_Drm_612B
	DRUM 1, 1
	SND_CALL SndD2_Drm_6120
	SND_CALL SndD2_Drm_612B
	DRUM 9, 1
	SND_CALL SndD2_Drm_6120
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 4
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP2_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP
SndD2_Drm_6120:
	DRUM_UNIT 1
	DRUM 1, 5
	DRUM 1, 4
	DRUM_UNIT 9
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_RET
SndD2_Drm_612B:
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_RET

SndD3_Ch2:
	TEMPO $24
	TRANSPOSE_DOWN 1
	SND_SEGNO
	SND_CALL SndD3_Ch2_62FC
	VOICE 2, 8, $0C, 0, $0F
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 7
	ATTEN 5
	NOTE D_, 6
	ATTEN 0
	LEN_UNIT 7
	RELEASE 1, $0A
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	RELEASE 0, $0F
	VIBRATO 12, 0, 2
	OCTAVE 4
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 3
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 7, 8, $0C, 0, $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 0
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	PAN $F0
	VOICE 7, $0C, 8, 2, $0F
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	DUTY_STEP 0, 2
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	PAN $FF
	VOICE 7, 8, $0C, 0, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	DUTY_STEP 0, 0
	PAN $0F
	VOICE 7, $0C, 8, 2, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	VOICE 7, 8, $0C, 4, $0A
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT 1
	NOTE E_, 1
	NOTE F_, $0A
	ATTEN 5
	NOTE F_, $0A
	ATTEN 0
	LEN_UNIT 7
	NOTE F_, 2
	NOTE C_, 1
	NOTE F_, 2
	LEN_UNIT 1
	NOTE A_, 1
	NOTE A#, 3
	REST 3
	NOTE A_, 1
	NOTE A#, 3
	REST 3
	ATTEN 5
	NOTE A#, 7
	ATTEN 0
	VIBRATO 12, 1, 2
	NOTE G#, 1
	NOTE A_, 6
	ATTEN 4
	NOTE A_, 7
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 7, 8, $0C, 3, $0F
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G#, 1
	ATTEN 3
	SND_CALL SndD3_Ch2_62FC
	ATTEN 1
	TRANSPOSE_UP 2
	SND_CALL SndD3_Ch2_62FC
	ATTEN 0
	TRANSPOSE_UP 4
	SND_CALL SndD3_Ch2_62FC
	TRANSPOSE_DOWN 1
	VOICE 1, 9, $0C, 0, $0F
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 6
	VOICE 7, 9, $0C, 3, $0A
	ATTEN 2
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 4
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	VOICE 1, 8, $0C, 4, $0A
	NOTE A_, 1
	NOTE A#, 3
	REST 3
	NOTE A_, 1
	NOTE A#, 3
	REST 3
	ATTEN 5
	NOTE A#, 7
	ATTEN 0
	VOICE 1, 8, $0C, 0, $0F
	VIBRATO 12, 1, 2
	NOTE G#, 1
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 7
	ATTEN 0
	VIBRATO_OFF $00
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	DUTY_STEP 4, 1
	SND_CALL SndD3_Ch2_6325
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	RELEASE 2, $0F
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 2
	PAN $0F
	RELEASE 1, $0C
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	PAN $FF
	SND_CALL SndD3_Ch2_6325
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	RELEASE 2, $0F
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 2
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	ATTEN 3
	NOTE A_, 1
	NOTE B_, 1
	RELEASE 2, $0D
	OCTAVE 4
	ATTEN 2
	NOTE C#, 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	RELEASE 4, 8
	VIBRATO 12, 1, 2
	NOTE F#, 2
	SND_CALL SndD3_Ch2_6347
	VOICE 7, 8, 8, 0, $0F
	VIBRATO 12, 0, 3
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 7, 8, 8, 3, $0F
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	VOICE 7, 8, 8, 0, $0F
	VIBRATO 12, 0, 3
	OCTAVE 4
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	VIBRATO_OFF $00
	RELEASE 1, $0A
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE 0, $0F
	NOTE C_HI, 1
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 0
	LEN_UNIT 7
	RELEASE 1, $0A
	NOTE C_HI, 1
	NOTE C_HI, 2
	NOTE G_, 1
	RELEASE 0, 0
	VIBRATO 12, 0, 2
	NOTE A_, 2
	NOTE B_, 5
	ATTEN 6
	NOTE B_, 6
	ATTEN 0
	VIBRATO_OFF $00
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	SND_CALL SndD3_Ch2_6347
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	VOICE 7, 8, 8, 0, $0F
	VIBRATO 12, 1, 2
	OCTAVE 4
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	VIBRATO_OFF $00
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	VIBRATO 12, 1, 2
	NOTE A#, 3
	ATTEN 5
	NOTE A#, 2
	ATTEN 0
	RELEASE 1, $0A
	VIBRATO_OFF $00
	LEN_UNIT 1
	NOTE B_, 2
	NOTE C_HI, 5
	LEN_UNIT 7
	NOTE A#, 1
	NOTE A_, 1
	RELEASE 0, $0F
	VIBRATO 12, 1, 2
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 3
	ATTEN 3
	NOTE F#, 2
	VIBRATO_OFF $00
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 0, 0
	LEN_UNIT 2
	ATTEN 0
	NOTE C_HI, 4
	NOTE B_, 1
	NOTE A#, 2
	SND_LOOP
SndD3_Ch2_62FC:
	VOICE 2, 8, $0C, 0, $0F
	VIBRATO 12, 0, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 7
	ATTEN 5
	NOTE G_, 6
	ATTEN 0
	LEN_UNIT 7
	RELEASE 1, $0A
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	RELEASE 0, $0F
	LEN_UNIT 1
	NOTE B_, 1
	NOTE C_HI, $0A
	ATTEN 5
	NOTE C_HI, $0A
	ATTEN 0
	LEN_UNIT 7
	NOTE B_, 1
	REST 1
	NOTE A_, 1
	RELEASE 0, $0F
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	SND_RET
SndD3_Ch2_6325:
	VOICE 7, $0A, 0, 1, $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	PAN $F0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	PAN $FF
	RELEASE 1, $0F
	DUTY 0
	SND_RET
SndD3_Ch2_6347:
	VOICE 7, 8, 8, 0, $0F
	VIBRATO 12, 0, 3
	OCTAVE 4
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	VIBRATO_OFF $00
	NOTE F_, 1
	NOTE E_, 1
	RELEASE 0, 0
	VIBRATO 12, 0, 3
	NOTE D_, 4
	ATTEN 5
	NOTE D_, 3
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 7, $0A, 8, 1, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	VOICE 7, 8, 8, 0, $0F
	VIBRATO 12, 0, 3
	NOTE C_HI, 3
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 0
	VIBRATO_OFF $00
	RELEASE 2, $0A
	ATTEN 2
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	VIBRATO 12, 0, 3
	RELEASE 0, $0F
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	RELEASE 2, $0A
	VIBRATO_OFF $00
	NOTE C_, 1
	NOTE E_, 1
	SND_RET

SndD3_Ch1:
	TRANSPOSE_DOWN 1
	SND_SEGNO
	SND_CALL SndD3_Ch1_653E
	VOICE 2, 5, 4, 0, $0F
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 6
	ATTEN 3
	NOTE A_, 6
	ATTEN 0
	LEN_UNIT 7
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 3
	ATTEN 3
	NOTE C_HI, 3
	ATTEN 0
	VOICE 7, 6, $0C, 4, $0A
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	RELEASE 2, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	RELEASE 4, $0A
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	RELEASE 2, $0F
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	RELEASE 4, $0A
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 0, $0F
	LEN_UNIT 1
	NOTE B_, 2
	NOTE C_HI, 9
	ATTEN 3
	NOTE C_HI, 9
	REST 1
	ATTEN 0
	LEN_UNIT 7
	NOTE C_HI, 2
	RELEASE 2, $0F
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	VOICE 1, 6, $0C, 0, $0F
	NOTE E_, 1
	NOTE F_, 3
	REST 3
	NOTE E_, 1
	NOTE F_, 3
	REST 3
	ATTEN 4
	NOTE F_, 7
	ATTEN 0
	VOICE 1, 6, $0C, 0, $0F
	VIBRATO 12, 1, 2
	NOTE E_, 1
	NOTE F_, 6
	ATTEN 3
	NOTE F_, 7
	ATTEN 0
	VIBRATO_OFF $00
	VOICE 7, 6, $0C, 3, $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	ATTEN 2
	SND_CALL SndD3_Ch1_653E
	ATTEN 1
	TRANSPOSE_UP 2
	SND_CALL SndD3_Ch1_653E
	ATTEN 0
	TRANSPOSE_DOWN 1
	VOICE 2, 5, 4, 0, $0F
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 6
	ATTEN 3
	NOTE E_, 6
	ATTEN 0
	LEN_UNIT 7
	RELEASE 2, $0A
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	LEN_UNIT 1
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, $0A
	ATTEN 3
	NOTE C_HI, $0A
	ATTEN 0
	LEN_UNIT 7
	NOTE C_HI, 1
	REST 1
	NOTE G_, 1
	NOTE E_, 2
	REST 1
	LEN_UNIT 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 6
	LEN_UNIT 7
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 2, $0A
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	VOICE 1, 6, $0C, 0, $0F
	NOTE E_, 1
	NOTE F_, 3
	REST 3
	NOTE E_, 1
	NOTE F_, 3
	REST 3
	ATTEN 4
	NOTE F_, 7
	ATTEN 0
	VOICE 1, 6, $0C, 0, $0F
	VIBRATO 12, 1, 2
	NOTE E_, 1
	NOTE F_, 6
	ATTEN 3
	NOTE F_, 7
	ATTEN 0
	VIBRATO_OFF $00
	LEN_UNIT 7
	RELEASE 3, $0A
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F_, 1
	SND_CALL SndD3_Ch1_6562
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	REST 1
	ATTEN 1
	RELEASE 2, $0D
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE B_, 1
	ATTEN 0
	SND_CALL SndD3_Ch1_6562
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	REST 1
	ATTEN 1
	RELEASE 2, $0D
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C#, 2
	RELEASE 2, $0D
	DUTY 8
	ATTEN 3
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	ATTEN 1
	NOTE C#, 1
	NOTE D_, 2
	ATTEN 0
	SND_CALL SndD3_Ch1_657E
	RELEASE 0, $0F
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	RELEASE 2, $0B
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	VOICE 7, 5, 8, 0, $0F
	OCTAVE 4
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 2
	ATTEN 0
	RELEASE 2, $0B
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 2
	ATTEN 3
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 0
	RELEASE 0, $0F
	NOTE D#, 1
	NOTE F#, 2
	NOTE G_, 2
	VOICE 7, 8, $0C, 2, $0A
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE 2, $0B
	NOTE G_, 3
	VOICE 7, 5, 8, 4, $0E
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	SND_CALL SndD3_Ch1_657E
	RELEASE 0, $0F
	NOTE C_HI, 1
	ATTEN 3
	REST 1
	ATTEN 0
	RELEASE 2, $0B
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	VOICE 7, 5, 8, 0, $0F
	OCTAVE 4
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 2
	ATTEN 0
	RELEASE 2, $0B
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE 0, $0F
	NOTE D#, 3
	ATTEN 3
	NOTE D#, 2
	ATTEN 0
	RELEASE 2, $0B
	LEN_UNIT 1
	NOTE G#, 2
	NOTE A_, 5
	LEN_UNIT 7
	NOTE G_, 1
	NOTE F_, 1
	RELEASE 0, $0F
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	RELEASE 2, $0A
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	RELEASE 0, $0F
	LEN_UNIT 2
	OCTAVE 4
	NOTE A_, 4
	NOTE G#, 1
	NOTE G_, 2
	SND_LOOP
SndD3_Ch1_653E:
	VOICE 2, 5, 4, 0, $0F
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 6
	ATTEN 3
	NOTE D_, 7
	ATTEN 0
	LEN_UNIT 7
	RELEASE 2, $0A
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	LEN_UNIT 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, $0A
	ATTEN 3
	NOTE A_, $0A
	ATTEN 0
	LEN_UNIT 7
	NOTE G_, 1
	REST 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 3
	SND_RET
SndD3_Ch1_6562:
	VOICE 7, 8, 0, 1, $0D
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	ATTEN 1
	RELEASE 2, $0D
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE B_, 2
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	RELEASE 1, $0D
	ATTEN 0
	SND_RET
SndD3_Ch1_657E:
	VOICE 7, 5, 8, 0, $0F
	OCTAVE 4
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 3
	ATTEN 3
	NOTE B_, 4
	ATTEN 0
	RELEASE 2, $0D
	ATTEN 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 0, $0F
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 2
	ATTEN 0
	RELEASE 2, $0B
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET

SndD3_Ch3:
	TRANSPOSE_DOWN 1
	SND_SEGNO
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	LEN_UNIT 1
	RELEASE 4, 8
	OCTAVE 2
	NOTE F#, 2
	NOTE G_, 5
	OCTAVE 1
	NOTE F#, 2
	NOTE G_, $0C
	RELEASE 3, $0A
	LEN_UNIT 7
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE C_HI, 1
	LEN_UNIT 1
	RELEASE 4, 8
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 5
	RELEASE 3, $0A
	LEN_UNIT 7
	OCTAVE 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	VOICE 7, 4, 1, 4, $0C
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 2
	NOTE D#, 1
	NOTE E_, 6
	RELEASE 3, $0A
	LEN_UNIT 7
	OCTAVE 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 2
	NOTE D#, 1
	NOTE E_, 6
	RELEASE 3, $0A
	LEN_UNIT 7
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 6
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE C_HI, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 6
	VOICE 7, 4, 1, 3, $0A
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 6
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C_HI, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 6
	LEN_UNIT 7
	RELEASE 3, $0A
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 6
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	LEN_UNIT 1
	RELEASE 4, 8
	OCTAVE 1
	NOTE B_, 2
	NOTE C_HI, 5
	OCTAVE 2
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE D#, 2
	NOTE A#, 1
	LEN_UNIT 1
	RELEASE 4, 8
	NOTE D_, 2
	NOTE D#, $0C
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	SND_CALL SndD3_Ch3_676C
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_CALL SndD3_Ch3_676C
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	LEN_UNIT 1
	RELEASE 4, 8
	OCTAVE 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 3
	NOTE C_HI, 3
	OCTAVE 2
	NOTE C#, 3
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 3
	SND_CALL SndD3_Ch3_6797
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	LOOP_END 2
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE D#, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 6
	RELEASE 3, $0A
	LEN_UNIT 7
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	SND_CALL SndD3_Ch3_6797
	LOOP_START
	NOTE E_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE A#, 1
	LEN_UNIT 2
	RELEASE 4, 8
	NOTE D_, 1
	NOTE D#, 6
	LEN_UNIT 7
	RELEASE 3, $0A
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_LOOP
SndD3_Ch3_676C:
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	VOICE 7, 2, 4, 2, $0B
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	VOICE 7, 4, 1, 3, $0A
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	VOICE 7, 2, 4, 2, $0B
	SND_RET
SndD3_Ch3_6797:
	VOICE 7, 4, 1, 3, $0A
	OCTAVE 2
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 6
	LEN_UNIT 7
	RELEASE 3, $0A
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	LEN_UNIT 2
	RELEASE 4, 8
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 6
	RELEASE 3, $0A
	LEN_UNIT 7
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	SND_RET

SndD3_Drm:
	SND_SEGNO
	DRUM_UNIT 7
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 2, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 2
	LOOP_END 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 1, 1
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
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 2
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 2
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM_UNIT 1
	DRUM 9, 5
	DRUM 9, 5
	DRUM 9, 4
	SND_LOOP

SndD4_Ch2:
	TRANSPOSE_UP 2
	TEMPO $10
	VOICE $0C, 8, 4, 1, 7
	REST 0
	REST 0
	SND_SEGNO
	SND_CALL SndD4_Ch2_6994
	VOICE 6, $0F, 4, 1, $0F
	PAN $F0
	DUTY_STEP 0, 1
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	ATTEN 7
	NOTE E_, 1
	OCTAVE 3
	NOTE C_HI, 1
	PAN $0F
	ATTEN 1
	ATTEN 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 0
	PAN $FF
	DUTY_STEP 0, 0
	SND_CALL SndD4_Ch2_6994
	VOICE 6, $0F, 4, 1, $0F
	DUTY_STEP 0, 1
	PAN $0F
	ATTEN 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN $FF
	ATTEN 7
	NOTE G_, 1
	NOTE D_, 1
	PAN $F0
	ATTEN 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	PAN $FF
	DUTY_STEP 0, 0
	VOICE 6, 8, 8, 4, 8
	OCTAVE 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VIBRATO 12, 0, 2
	RELEASE 0, $0F
	NOTE A_, 5
	VIBRATO_OFF $00
	DUTY 4
	OCTAVE 4
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VIBRATO 12, 0, 1
	NOTE A_, 5
	VIBRATO_OFF $00
	VOICE 3, $0C, 4, 1, $0F
	PAN $F0
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	PAN $0F
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	PAN $FF
	DUTY_STEP 0, 0
	SND_CALL SndD4_Ch2_69D1
	VIBRATO_OFF $00
	VOICE 1, $0F, 4, 1, $0F
	PAN $F0
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE E_, 8
	PAN $0F
	NOTE C#, 8
	NOTE E_, 8
	NOTE A_, 8
	PAN $FF
	SND_CALL SndD4_Ch2_69D1
	PAN $F0
	VIBRATO_OFF $00
	VOICE 6, 8, 0, 1, $0A
	OCTAVE 5
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_CALL SndD4_Ch2_6A1C
	NOTE D#, 1
	NOTE E_, 9
	ATTEN 5
	NOTE E_, 8
	ATTEN 0
	NOTE D_, $0A
	ATTEN 5
	NOTE D_, 8
	ATTEN 0
	OCTAVE 3
	NOTE A_, 7
	ATTEN 5
	NOTE A_, 5
	ATTEN 0
	REST 3
	VIBRATO_OFF $00
	VOICE 6, $0A, 0, 1, $0F
	ATTEN 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	ATTEN 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	SND_CALL SndD4_Ch2_6A1C
	NOTE F#, 1
	NOTE G_, 9
	ATTEN 5
	NOTE G_, 8
	ATTEN 0
	NOTE F#, $0A
	ATTEN 5
	NOTE F#, 8
	ATTEN 0
	NOTE D_, 7
	ATTEN 5
	NOTE D_, 5
	ATTEN 0
	VIBRATO_OFF $00
	DUTY_STEP 0, 0
	VOICE 1, $0A, 0, 1, $0A
	ATTEN 3
	NOTE A_, 8
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE E_, 8
	ATTEN 2
	NOTE A_, 8
	NOTE E_, 8
	NOTE A_, 8
	ATTEN 1
	NOTE G#, 8
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 8
	ATTEN 0
	NOTE G#, 8
	OCTAVE 4
	NOTE E_, 8
	NOTE F#, 8
	SND_LOOP
SndD4_Ch2_6994:
	VOICE 6, $0B, 8, 0, $0F
	OCTAVE 4
	REST 4
	NOTE E_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 0
	REST 3
	NOTE F#, 1
	ATTEN 9
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 0
	REST 3
	NOTE D_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	REST 3
	NOTE E_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 0
	REST 3
	NOTE C_, 1
	ATTEN 9
	NOTE C_, 1
	ATTEN 7
	NOTE C_, 1
	ATTEN 0
	REST 3
	NOTE D_, 1
	ATTEN 9
	NOTE D_, 1
	ATTEN 7
	NOTE D_, 1
	ATTEN 0
	REST 3
	OCTAVE 3
	NOTE B_, 1
	ATTEN 9
	NOTE B_, 1
	ATTEN 7
	NOTE B_, 1
	ATTEN 0
	REST 3
	NOTE C_HI, 1
	ATTEN 9
	NOTE C_HI, 1
	ATTEN 0
	SND_RET
SndD4_Ch2_69D1:
	PAN $FF
	DUTY_STEP 0, 0
	VOICE 6, 8, 8, 4, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	VIBRATO 12, 0, 2
	RELEASE 0, $0F
	NOTE E_, 5
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	VIBRATO_OFF $00
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	VIBRATO 12, 0, 1
	NOTE A_, 5
	ATTEN 5
	NOTE A_, 6
	ATTEN 0
	VIBRATO_OFF $00
	RELEASE 1, 8
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 4, 8
	OCTAVE 3
	NOTE B_, 1
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 0, $0F
	VIBRATO 12, 0, 1
	OCTAVE 4
	NOTE G_, 5
	ATTEN 5
	NOTE G_, 5
	ATTEN 0
	VIBRATO_OFF $00
	NOTE F#, 1
	NOTE D_, 1
	VIBRATO 12, 0, 1
	NOTE E_, 4
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	VIBRATO_OFF $00
	SND_RET
SndD4_Ch2_6A1C:
	PAN $FF
	VOICE 6, 8, 4, 0, $0F
	DUTY_STEP 4, 1
	LEN_UNIT 2
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 2
	LEN_UNIT 6
	VIBRATO 12, 0, 3
	NOTE E_, 6
	ATTEN 5
	NOTE E_, 5
	ATTEN 0
	VIBRATO_OFF $00
	DUTY_STEP 0, 0
	ATTEN 2
	OCTAVE 3
	NOTE C_HI, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	DUTY_STEP 4, 1
	LEN_UNIT 2
	NOTE G#, 1
	VIBRATO 12, 0, 2
	NOTE A_, 9
	ATTEN 5
	NOTE A_, 8
	ATTEN 0
	NOTE G_, $0A
	ATTEN 5
	NOTE G_, 8
	ATTEN 0
	NOTE F#, 7
	ATTEN 5
	NOTE F#, 5
	ATTEN 0
	VIBRATO 12, 0, 3
	SND_RET

SndD4_Ch1:
	TRANSPOSE_UP 2
	VOICE $0C, 5, 4, 1, 7
	REST 0
	REST 0
	SND_SEGNO
	SND_CALL SndD4_Ch1_6B24
	VOICE 6, 6, 0, 1, $0A
	OCTAVE 4
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_CALL SndD4_Ch1_6B24
	VOICE 6, 6, 0, 1, $0A
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	VOICE 6, 6, 4, 1, $0A
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 8
	NOTE F_, 5
	RELEASE 1, $0A
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	RELEASE 4, 8
	NOTE F_, 5
	RELEASE 1, $0A
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	SND_CALL SndD4_Ch1_6B61
	LEN_UNIT 1
	OCTAVE 3
	NOTE E_, 8
	NOTE A_, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE E_, 8
	SND_CALL SndD4_Ch1_6B61
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	VOICE 6, 5, 8, 0, $0F
	OCTAVE 3
	NOTE C_HI, 7
	ATTEN 3
	NOTE C_HI, 5
	ATTEN 0
	RELEASE 2, $0A
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, 8
	NOTE F#, 6
	NOTE E_, 6
	NOTE D_, 4
	OCTAVE 3
	NOTE A_, 6
	NOTE A_, 6
	NOTE F#, 4
	RELEASE 2, $0A
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE 6, 5, 8, 0, $0F
	OCTAVE 3
	NOTE C_HI, 7
	ATTEN 3
	NOTE C_HI, 5
	ATTEN 0
	RELEASE 2, $0A
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE 4, 8
	NOTE F#, 6
	NOTE E_, 6
	NOTE D_, 4
	NOTE E_, 6
	NOTE D_, 6
	OCTAVE 3
	NOTE A_, 4
	VOICE 1, 7, 8, 2, $0A
	OCTAVE 4
	ATTEN 3
	NOTE E_, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE B_, 8
	ATTEN 2
	OCTAVE 4
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE E_, 8
	ATTEN 1
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE G#, 8
	ATTEN 0
	NOTE E_, 8
	NOTE G#, 8
	NOTE B_, 8
	SND_LOOP
SndD4_Ch1_6B24:
	VOICE 6, 9, 8, 1, $0E
	OCTAVE 4
	REST 4
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	REST 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	REST 3
	OCTAVE 3
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	REST 3
	NOTE C_HI, 1
	ATTEN 6
	NOTE C_HI, 1
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 0
	REST 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	REST 3
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 0
	REST 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	REST 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	SND_RET
SndD4_Ch1_6B61:
	VOICE 6, 5, 4, 4, 8
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 4
	RELEASE 0, $0F
	NOTE C#, 5
	ATTEN 3
	NOTE C#, 5
	ATTEN 0
	RELEASE 1, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE B_, 1
	NOTE A_, 1
	RELEASE 0, $0F
	NOTE E_, 5
	ATTEN 3
	NOTE E_, 6
	ATTEN 0
	RELEASE 4, 8
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	RELEASE 0, $0F
	NOTE D_, 5
	ATTEN 3
	NOTE D_, 5
	ATTEN 0
	RELEASE 4, 8
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	RELEASE 0, $0F
	NOTE C#, 4
	ATTEN 3
	NOTE C#, 5
	ATTEN 0
	RELEASE 4, 8
	SND_RET

SndD4_Ch3:
	TRANSPOSE_UP 2
	VOICE 6, 2, 1, 2, $0B
	LOOP_START
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 1
	LOOP_END 2
	SND_SEGNO
	VOICE 6, 4, 1, 3, $0A
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
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
	NOTE G_, 1
	NOTE A_, 1
	LOOP_END 5
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
	NOTE A_, 1
	OCTAVE 2
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
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP2_END 2
	OCTAVE 1
	NOTE F_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	LOOP2_START
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
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
	NOTE G_, 1
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
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
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
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	LOOP_END 2
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
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	LOOP2_END 2
	LOOP_START
	OCTAVE 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 1
	LOOP_END 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE E_, 1
	SND_LOOP

SndD4_Drm:
	DRUM_UNIT 6
	DRUM $0B, 4
	DRUM 9, 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 9, 4
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_SEGNO
	LOOP_START
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 4
	LOOP_END 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	LOOP_START
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 4
	LOOP_END 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 3
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	LOOP2_START
	LOOP_START
	DRUM $0B, 4
	DRUM 9, 4
	DRUM $0B, 4
	DRUM 9, 4
	LOOP_END 7
	DRUM $0B, 4
	DRUM 9, 4
	DRUM 1, 1
	DRUM 9, 3
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP2_END 2
	SND_LOOP

SndD5_Ch2:
	SND_SEGNO
	SND_CALL SndD5_Ch2_6DE6
	VOICE 9, 5, 4, 9, $0F
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE C_HI, 2
	VOICE 9, 3, 4, 9, $0F
	NOTE A_, 3
	VOICE 9, 8, 4, 0, $0F
	NOTE A_, 3
	VOICE 9, 3, 4, 9, $0F
	OCTAVE 4
	NOTE F_, 3
	VIBRATO 12, 0, 3
	VOICE 9, 8, 4, 0, $0F
	NOTE F_, 3
	VIBRATO_OFF $00
	VOICE 9, 7, 8, 2, 8
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	LOOP_END 2
	SND_CALL SndD5_Ch2_6DE6
	VOICE 9, 5, 4, 9, $0F
	OCTAVE 3
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A#, 2
	VOICE 9, 3, 4, 9, $0F
	NOTE A_, 3
	VOICE 9, 8, 4, 0, $0F
	NOTE A_, 3
	VOICE 9, 3, 4, 9, $0F
	NOTE D#, 3
	VIBRATO 12, 0, 4
	VOICE 9, 8, 4, 0, $0F
	NOTE D#, 3
	VIBRATO_OFF $00
	VOICE 9, 9, 8, 3, $0A
	OCTAVE 4
	ATTEN 4
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	ATTEN 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	SND_LOOP
SndD5_Ch2_6DE6:
	VOICE 9, 3, 4, 9, $0F
	OCTAVE 3
	NOTE G_, 3
	VOICE 9, 8, 4, 0, $0F
	OCTAVE 3
	NOTE G_, 3
	VOICE 9, 3, 4, 9, $0F
	OCTAVE 4
	NOTE D_, 3
	VIBRATO 12, 0, 3
	VOICE 9, 8, 4, 0, $0F
	OCTAVE 4
	NOTE D_, 3
	ATTEN 5
	NOTE D_, 6
	ATTEN 0
	VIBRATO_OFF $00
	SND_RET

SndD5_Ch1:
	SND_SEGNO
	SND_CALL SndD5_Ch1_6E6F
	VOICE 9, 5, 4, 4, 8
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	VOICE 9, 4, 4, 0, $0F
	NOTE F_, 6
	OCTAVE 4
	NOTE C_, 6
	VOICE 9, 6, 4, 3, $0A
	PAN $0F
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	VOICE 9, 8, 4, 3, $0A
	PAN $F0
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	PAN $FF
	SND_CALL SndD5_Ch1_6E6F
	VOICE 9, 5, 4, 4, 8
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	VOICE 9, 4, 4, 0, $0F
	NOTE F_, 6
	VOICE 9, 4, 4, 0, $0F
	NOTE C_, 6
	VOICE 9, 6, 4, 3, $0A
	PAN $0F
	OCTAVE 4
	ATTEN 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	VOICE 9, 8, 4, 3, $0A
	PAN $F0
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F_, 1
	PAN $FF
	SND_LOOP
SndD5_Ch1_6E6F:
	VOICE 9, 4, 4, 0, $0F
	OCTAVE 3
	NOTE D_, 6
	NOTE G_, 3
	VOICE 3, 7, 0, 4, 9
	DUTY_STEP 4, 1
	NOTE C_, 1
	NOTE D_, 5
	DUTY_STEP 0, 0
	VOICE 9, 7, 0, 4, 9
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	VIBRATO 12, 0, 5
	OCTAVE 2
	NOTE G_, 3
	VIBRATO_OFF $00
	SND_RET

SndD5_Ch3:
	SND_SEGNO
	VOICE 9, 2, 1, 5, $0B
	OCTAVE 1
	LOOP_START
	NOTE G_, 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	LOOP_END 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP_START
	NOTE F_, 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	LOOP_END 3
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	SND_LOOP

SndD5_Drm:
	DRUM_UNIT 9
	SND_SEGNO
	SND_CALL SndD5_Drm_6EE1
	DRUM_UNIT 1
	DRUM 1, 9
	DRUM 1, 5
	DRUM 1, 4
	DRUM 1, 9
	DRUM_UNIT 9
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM_UNIT 1
	DRUM 1, 5
	DRUM 1, 4
	DRUM 1, 9
	DRUM 1, 9
	DRUM_UNIT 9
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_CALL SndD5_Drm_6EE1
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 1, 1
	DRUM 2, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_LOOP
SndD5_Drm_6EE1:
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 3
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_RET

SndD6_Ch2:
	TRANSPOSE_UP 1
	SND_CALL SndD6_Ch2_6FE3
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	SND_CALL SndD6_Ch2_6FE3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	ATTEN 0
	VOICE 8, 8, 4, 0, $0F
	OCTAVE 3
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 3
	VOICE 8, 7, 4, 2, $0B
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 0
	VOICE 8, 8, 4, 0, $0F
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 3
	VOICE 8, 7, 4, 2, $0B
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 0
	VOICE 8, 8, 4, 0, $0F
	OCTAVE 3
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 3
	VOICE 8, 7, 4, 2, $0B
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	ATTEN 0
	VOICE 8, 8, 4, 4, 8
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	RELEASE 0, $0F
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 3
	RELEASE 4, 8
	LEN_UNIT 1
	OCTAVE 3
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 6
	NOTE D_, 4
	VIBRATO_OFF $00
	SND_SEGNO
	SND_CALL SndD6_Ch2_700A
	ATTEN 4
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	SND_CALL SndD6_Ch2_700A
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	SND_CALL SndD6_Ch2_7042
	VOICE 4, 8, 0, 0, $0F
	NOTE D_, 3
	ATTEN 5
	NOTE D_, 3
	ATTEN 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 3
	ATTEN 0
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 2, $0B
	ATTEN 4
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 0
	SND_CALL SndD6_Ch2_7042
	VOICE 2, 8, 0, 0, $0F
	NOTE D_, 5
	ATTEN 4
	NOTE D_, 4
	ATTEN 0
	NOTE F_, 5
	ATTEN 4
	NOTE F_, 4
	ATTEN 0
	NOTE G#, 5
	ATTEN 4
	NOTE G#, 4
	ATTEN 0
	NOTE B_, 5
	ATTEN 4
	NOTE B_, 4
	ATTEN 0
	OCTAVE 5
	NOTE D_, 3
	ATTEN 0
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 1
	OCTAVE 4
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	SND_LOOP
SndD6_Ch2_6FE3:
	VOICE 8, 8, 4, 0, $0F
	OCTAVE 2
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE C_HI, 3
	VOICE 8, 6, 4, 4, $0A
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 0
	VOICE 8, 8, 4, 0, $0F
	OCTAVE 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 3
	VOICE 8, 6, 4, 4, $0A
	SND_RET
SndD6_Ch2_700A:
	VOICE 4, 8, 0, 0, $0F
	DUTY_STEP 8, 2
	OCTAVE 3
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 3
	ATTEN 0
	NOTE C_HI, 3
	ATTEN 5
	NOTE C_HI, 3
	ATTEN 0
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 3, $0A
	ATTEN 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	DUTY_STEP 8, 2
	VOICE 4, 8, 0, 0, $0F
	OCTAVE 3
	NOTE B_, 3
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	OCTAVE 4
	NOTE D_, 3
	ATTEN 5
	NOTE D_, 3
	ATTEN 0
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 3, $0A
	SND_RET
SndD6_Ch2_7042:
	DUTY_STEP 8, 2
	VOICE 4, 8, 0, 0, $0F
	OCTAVE 4
	NOTE C_, 3
	ATTEN 5
	NOTE C_, 3
	ATTEN 0
	NOTE D#, 3
	ATTEN 5
	NOTE D#, 3
	ATTEN 0
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 3, $0A
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 0
	DUTY_STEP 8, 2
	SND_RET

SndD6_Ch1:
	TRANSPOSE_UP 1
	SND_CALL SndD6_Ch1_7121
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 0
	SND_CALL SndD6_Ch1_7121
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	ATTEN 0
	VOICE 8, 6, 0, 4, 5
	OCTAVE 2
	NOTE G_, 3
	NOTE C_HI, 3
	VOICE 8, 6, 8, 4, 8
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 0
	VOICE 8, 6, 0, 4, 5
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE D_, 3
	VOICE 8, 6, 8, 4, 8
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	VOICE 8, 6, 0, 4, 5
	OCTAVE 2
	NOTE G_, 3
	NOTE C_HI, 3
	VOICE 8, 6, 8, 4, 8
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 0
	VOICE 8, 6, 0, 4, 5
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 3
	NOTE F_, 3
	LEN_UNIT 1
	OCTAVE 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	SND_SEGNO
	SND_CALL SndD6_Ch1_7141
	ATTEN 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	ATTEN 0
	PAN $FF
	SND_CALL SndD6_Ch1_7141
	ATTEN 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	ATTEN 0
	SND_CALL SndD6_Ch1_715D
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D_, 4
	PAN $0F
	ATTEN 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	SND_CALL SndD6_Ch1_715D
	LEN_UNIT 2
	OCTAVE 3
	NOTE B_, 9
	OCTAVE 4
	NOTE D_, 9
	NOTE F_, 9
	NOTE G#, 9
	NOTE B_, 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 1
	SND_LOOP
SndD6_Ch1_7121:
	VOICE 8, 6, 0, 4, 6
	OCTAVE 2
	NOTE E_, 3
	NOTE A_, 3
	VOICE 8, 6, 8, 4, 8
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	VOICE 8, 6, 0, 4, 5
	OCTAVE 2
	NOTE G_, 3
	NOTE B_, 3
	VOICE 8, 6, 8, 4, 8
	SND_RET
SndD6_Ch1_7141:
	VOICE 6, 6, 4, 4, 8
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	PAN $F0
	ATTEN 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE E_, 1
	ATTEN 0
	PAN $FF
	NOTE G_, 4
	NOTE B_, 4
	PAN $0F
	SND_RET
SndD6_Ch1_715D:
	PAN $FF
	OCTAVE 3
	NOTE G_, 4
	NOTE C_HI, 4
	PAN $F0
	ATTEN 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	PAN $FF
	SND_RET

SndD6_Ch3:
	TRANSPOSE_UP 1
	VOICE 8, 4, 1, 4, 8
	LOOP_START
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE A_, 1
	LOOP_END 2
	OCTAVE 1
	NOTE A_, 3
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	LEN_UNIT 1
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN_UNIT 8
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE C_, 3
	NOTE C_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE D_, 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE D_, 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE C_, 3
	NOTE C_, 1
	NOTE G_, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	SND_SEGNO
	SND_CALL SndD6_Ch3_7202
	LEN_UNIT 2
	OCTAVE 1
	NOTE B_, 9
	NOTE B_, 9
	NOTE B_, 9
	NOTE B_, 9
	NOTE B_, 6
	NOTE B_, 6
	SND_CALL SndD6_Ch3_7202
	VOICE 6, 4, 1, 3, 8
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	SND_LOOP
SndD6_Ch3_7202:
	VOICE 3, 4, 1, 2, 8
	LOOP_START
	LOOP2_START
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 4
	LOOP2_END 3
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	LOOP_END 3
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	LOOP_START
	LOOP2_START
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 4
	LOOP2_END 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	LOOP_END 3
	SND_RET

SndD6_Drm:
	DRUM_UNIT 8
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	SND_CALL SndD6_Drm_72BF
	DRUM 9, 1
	DRUM 9, 1
	DRUM_UNIT 4
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM_UNIT 8
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 1
	SND_CALL SndD6_Drm_72BF
	DRUM_UNIT 3
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM $0D, 4
	DRUM $0D, 2
	DRUM $0D, 2
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 4
	SND_SEGNO
	DRUM_UNIT 3
	LOOP2_START ; loop byte read both as a start and as an end (see doc)
	SND_CALL SndD6_Drm_7296
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0D, 2
	DRUM $0D, 2
	SND_CALL SndD6_Drm_7296
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0D, 2
	DRUM $0D, 2
	DRUM $0B, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 7, 2
	SND_LOOP
SndD6_Drm_7296:
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 4
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 4
	SND_RET
SndD6_Drm_72BF:
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 7, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 1, 1
	SND_RET

SndD7_Ch2:
	TEMPO $0C
	TRANSPOSE_UP 1
	VOICE 6, $0B, 4, 3, $0F
	OCTAVE 2
	ATTEN 5
	NOTE D#, 4
	ATTEN 4
	NOTE E_, 4
	ATTEN 2
	NOTE F_, 4
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	VOICE 6, $0A, 0, 1, 7
	OCTAVE 1
	ATTEN 2
	NOTE A_, 2
	OCTAVE 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE C_HI, 2
	RELEASE 1, 8
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE F_, 1
	LEN_UNIT 4
	ATTEN 2
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	SND_SEGNO
	LOOP_START
	DUTY_STEP 4, 2
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE E_, 4
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE E_, 4
	ATTEN 4
	NOTE E_, 8
	ATTEN 0
	NOTE F_, 4
	ATTEN 4
	NOTE F_, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE D_, 4
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE G_, 4
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	OCTAVE 4
	NOTE E_, 4
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE D_, 4
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C_, 4
	ATTEN 4
	NOTE C_, 8
	ATTEN 0
	NOTE E_, 4
	ATTEN 4
	NOTE E_, 8
	ATTEN 0
	OCTAVE 4
	NOTE D#, 4
	ATTEN 4
	NOTE D#, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	LOOP_END 2
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE A_, 4
	ATTEN 4
	NOTE A_, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE A_, 4
	ATTEN 4
	NOTE A_, 8
	ATTEN 0
	NOTE A#, 4
	ATTEN 4
	NOTE A#, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE G_, 4
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE C_HI, 4
	ATTEN 4
	NOTE C_HI, 2
	ATTEN 0
	OCTAVE 4
	NOTE A_, 4
	ATTEN 5
	NOTE A_, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE G_, 4
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 4
	ATTEN 4
	NOTE F_, 8
	ATTEN 0
	NOTE A_, 4
	ATTEN 4
	NOTE A_, 8
	ATTEN 0
	NOTE G#, 4
	ATTEN 4
	NOTE G#, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	NOTE F#, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE A_, 4
	ATTEN 4
	NOTE A_, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	OCTAVE 3
	NOTE F#, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE F#, 4
	ATTEN 4
	NOTE F#, 8
	ATTEN 0
	VOICE 6, 6, 0, 3, $0F
	OCTAVE 3
	NOTE F#, 1
	VOICE 1, 8, 8, 2, 8
	OCTAVE 4
	NOTE F_, 4
	ATTEN 4
	NOTE F_, 8
	ATTEN 0
	SND_LOOP

SndD7_Ch1:
	TRANSPOSE_UP 1
	VOICE 6, 8, 0, 3, $0F
	OCTAVE 2
	ATTEN 2
	NOTE G#, 4
	NOTE A_, 4
	ATTEN 1
	NOTE A#, 4
	NOTE B_, 4
	ATTEN 0
	VOICE 6, 6, 4, 2, 6
	RELEASE $0C, $0D
	ATTEN 4
	NOTE A_, $0C
	ATTEN 0
	RELEASE 2, 6
	LEN_UNIT 4
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_SEGNO
	LOOP_START
	VOICE 6, 6, 4, 4, $0A
	OCTAVE 3
	NOTE A_, 2
	REST $0B
	NOTE A_, 2
	NOTE A#, 2
	REST $0D
	NOTE A#, 2
	NOTE A_, 2
	REST $0B
	NOTE A_, 2
	NOTE G#, 2
	REST $0F
	LOOP_END 2
	OCTAVE 4
	NOTE D_, 2
	REST $0B
	NOTE D_, 2
	NOTE D#, 2
	REST $0D
	NOTE D#, 2
	NOTE D_, 2
	REST $0C
	NOTE D_, 2
	NOTE C#, 2
	REST 6
	OCTAVE 3
	NOTE C_HI, 1
	REST 2
	NOTE C_HI, 1
	REST 2
	NOTE A#, 1
	REST 1
	SND_LOOP

SndD7_Ch3:
	TRANSPOSE_UP 1
	VOICE 6, 2, 1, 4, $0A
	OCTAVE 1
	NOTE G#, 4
	NOTE A_, 4
	NOTE A#, 4
	NOTE B_, 4
	VOICE 6, 4, 1, 3, $0A
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 2
	SND_SEGNO
	VOICE 6, 4, 1, 3, 8
	LOOP2_START ; loop byte read both as a start and as an end (see doc)
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE F_, 1
	NOTE G_, 1
	LOOP_END 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 2
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 1
	NOTE G#, 1
	SND_LOOP

SndD7_Drm:
	DRUM_UNIT 6
	REST 0
	REST 8
	DRUM 9, 1
	DRUM 9, 2
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 2
	SND_SEGNO
	SND_CALL SndD7_Drm_757B
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM_UNIT 3
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0D, 2
	DRUM $0D, 2
	DRUM 7, 2
	DRUM 7, 2
	DRUM 7, 4
	DRUM_UNIT 6
	SND_CALL SndD7_Drm_757B
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM_UNIT 3
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM_UNIT 6
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 2
	SND_CALL SndD7_Drm_759A
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_CALL SndD7_Drm_759A
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0D, 1
	DRUM $0D, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 7, 2
	SND_LOOP
SndD7_Drm_757B:
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM $0A, 2
	DRUM $0A, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM $0A, 2
	DRUM $0A, 1
	SND_RET
SndD7_Drm_759A:
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 2
	DRUM 2, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 1, 1
	DRUM $0A, 2
	DRUM $0A, 1
	SND_RET

SndD8_Ch2:
	SND_SEGNO
	VOICE 6, $0D, $0C, 1, 6
	DUTY_STEP 8, 2
	PAN $0F
	OCTAVE 4
	NOTE A#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE G_, 1
	PAN $F0
	NOTE C#, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	PAN $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	PAN $FF
	DUTY_STEP 0, 0
	VOICE 1, $0B, 0, $0A, 0
	OCTAVE 3
	NOTE C_HI, 2
	ATTEN 4
	NOTE C_HI, 2
	NOTE B_, 4
	ATTEN 1
	NOTE A#, 4
	NOTE A_, 4
	ATTEN 0
	NOTE G#, 4
	NOTE G_, 4
	LEN_UNIT 6
	VOICE 6, 9, 4, 3, $0F
	OCTAVE 4
	DUTY_STEP 0, 0
	LOOP2_START
	LOOP_START
	RELEASE 4, $0F
	ATTEN 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	RELEASE 2, $0F
	ATTEN 2
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch2_7676
	TRANSPOSE_UP 0
	LOOP2_END 2
	TRANSPOSE_UP 0
	VOICE 6, 8, 0, 2, $0E
	DUTY_STEP 4, 1
	ATTEN 3
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END 2
	ATTEN 1
	RELEASE 3, $0E
	TRANSPOSE_UP 1
	SND_CALL SndD8_Ch2_769B
	TRANSPOSE_UP 0
	ATTEN 3
	RELEASE 4, $0E
	SND_CALL SndD8_Ch2_769B
	ATTEN 1
	RELEASE 3, $0E
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch2_769B
	TRANSPOSE_UP 0
	DUTY_STEP 0, 1
	VOICE 6, 7, 8, 3, $0E
	LOOP2_START
	LOOP_START
	RELEASE 5, $0E
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 2, $0E
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT 1
	NOTE F_, 3
	ATTEN 3
	NOTE F_, 3
	LEN_UNIT 6
	RELEASE 2, $0E
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	LOOP_END 2
	TRANSPOSE_UP 1
	LOOP2_END 2
	TRANSPOSE_UP 0
	SND_CALL SndD8_Ch2_76AD
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch2_76AD
	TRANSPOSE_UP 0
	SND_LOOP
SndD8_Ch2_7676:
	LOOP_START
	RELEASE 4, $0F
	ATTEN 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	RELEASE 2, $0F
	ATTEN 2
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END 2
	SND_RET
SndD8_Ch2_769B:
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END 2
	SND_RET
SndD8_Ch2_76AD:
	LOOP_START
	RELEASE 5, $0E
	ATTEN 3
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	RELEASE 2, $0E
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT 1
	NOTE F_, 3
	ATTEN 3
	NOTE F_, 3
	LEN_UNIT 6
	RELEASE 2, $0E
	ATTEN 2
	OCTAVE 3
	NOTE A#, 1
	LOOP_END 2
	SND_RET

SndD8_Ch1:
	SND_SEGNO
	VOICE 1, 8, 8, 1, 7
	DUTY_STEP 8, 2
	REST 4
	OCTAVE 4
	NOTE A#, 6
	ATTEN 2
	NOTE E_, 6
	NOTE A#, 6
	ATTEN 0
	NOTE G_, 6
	ATTEN 2
	NOTE C#, 6
	NOTE G_, 6
	ATTEN 0
	NOTE E_, 6
	ATTEN 2
	OCTAVE 3
	NOTE A#, 6
	OCTAVE 4
	NOTE E_, 6
	ATTEN 0
	NOTE C#, 6
	ATTEN 2
	OCTAVE 3
	NOTE G_, 6
	OCTAVE 4
	NOTE C#, 2
	DUTY_STEP 0, 0
	VOICE 1, 7, 8, $0A, 0
	OCTAVE 2
	NOTE C_HI, 2
	ATTEN 4
	NOTE C_HI, 2
	NOTE B_, 4
	ATTEN 1
	NOTE A#, 4
	NOTE A_, 4
	ATTEN 0
	NOTE G#, 4
	NOTE G_, 4
	LEN_UNIT 6
	VOICE 6, 8, 4, 3, $0F
	DUTY_STEP 0, 0
	LOOP2_START
	LOOP_START
	PAN $FF
	RELEASE 4, $0F
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	RELEASE 2, $0F
	VOICE 6, $0A, 4, 3, $0F
	PAN $0F
	ATTEN 2
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE G#, 1
	NOTE C_, 1
	PAN $F0
	ATTEN 0
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	VOICE 6, 8, 4, 3, $0F
	LOOP_END 2
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch1_77B5
	TRANSPOSE_UP 0
	LOOP2_END 2
	ATTEN 3
	LOOP_START
	VOICE 6, 9, 0, 2, $0E
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	PAN $0F
	AUTOPAN 2
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	AUTOPAN 0
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	AUTOPAN 2
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	AUTOPAN 0
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	PAN $0F
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 2
	ATTEN 1
	TRANSPOSE_UP 1
	SND_CALL SndD8_Ch1_77E2
	TRANSPOSE_UP 0
	ATTEN 3
	RELEASE 3, $0E
	SND_CALL SndD8_Ch1_77E2
	ATTEN 1
	RELEASE 2, $0E
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch1_77E2
	TRANSPOSE_UP 0
	PAN $FF
	DUTY_STEP 0, 1
	VOICE 6, 9, 0, 3, $0E
	LOOP2_START
	LOOP_START
	RELEASE 5, $0E
	ATTEN 4
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 3
	OCTAVE 2
	NOTE A#, 1
	ATTEN 0
	RELEASE 2, $0E
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 2
	RELEASE 2, $0E
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	LOOP_END 2
	TRANSPOSE_UP 1
	LOOP2_END 2
	TRANSPOSE_UP 0
	SND_CALL SndD8_Ch1_7810
	TRANSPOSE_UP 3
	RELEASE 2, $0E
	SND_CALL SndD8_Ch1_7810
	TRANSPOSE_UP 0
	SND_LOOP
SndD8_Ch1_77B5:
	LOOP_START
	PAN $FF
	RELEASE 4, $0F
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	ATTEN 3
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	RELEASE 2, $0F
	VOICE 6, $0A, 4, 3, $0F
	PAN $0F
	ATTEN 2
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE G#, 1
	NOTE C_, 1
	PAN $F0
	ATTEN 0
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	VOICE 6, 8, 4, 3, $0F
	LOOP_END 2
	SND_RET
SndD8_Ch1_77E2:
	LOOP_START
	VOICE 6, 9, 0, 2, $0E
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	PAN $0F
	AUTOPAN 2
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	AUTOPAN 0
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	AUTOPAN 2
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	AUTOPAN 0
	PAN $FF
	ATTEN 2
	OCTAVE 2
	NOTE F_, 1
	PAN $0F
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 2
	SND_RET
SndD8_Ch1_7810:
	LOOP_START
	RELEASE 5, $0E
	ATTEN 4
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 3
	OCTAVE 2
	NOTE A#, 1
	ATTEN 0
	RELEASE 2, $0E
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 2
	RELEASE 2, $0E
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	LOOP_END 2
	SND_RET

SndD8_Ch3:
	SND_SEGNO
	VOICE 6, 2, 2, 4, $0E
	OCTAVE 3
	NOTE E_, 1
	ATTEN 0
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	RELEASE 4, $0E
	ATTEN 0
	NOTE C#, 1
	RELEASE 2, $0F
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	RELEASE 4, $0E
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	RELEASE 2, $0F
	ATTEN 0
	NOTE E_, 1
	NOTE A#, 1
	RELEASE 4, $0E
	ATTEN 0
	NOTE G_, 1
	RELEASE 2, $0F
	ATTEN 0
	NOTE C#, 1
	NOTE G_, 1
	ATTEN 0
	VOICE 1, 2, 2, 0, 0
	ATTEN 1
	NOTE F#, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D#, 4
	ATTEN 0
	NOTE D_, 4
	NOTE C#, 4
	LEN_UNIT 6
	VOICE 6, 2, 1, 3, $0F
	OCTAVE 1
	LOOP2_START
	LOOP_START
	RELEASE 2, $0B
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 4, $0A
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	LOOP_END 2
	RELEASE 3, $0F
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch3_78E8
	TRANSPOSE_UP 0
	LOOP2_END 2
	TRANSPOSE_UP 0
	VOICE 6, 2, 1, 2, $0A
	LOOP_START
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	TRANSPOSE_UP 1
	SND_CALL SndD8_Ch3_7908
	TRANSPOSE_UP 0
	SND_CALL SndD8_Ch3_7908
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch3_7908
	TRANSPOSE_UP 0
	VOICE 6, 2, 1, 2, $0A
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE E_, 1
	TRANSPOSE_UP 1
	SND_CALL SndD8_Ch3_791A
	TRANSPOSE_UP 0
	SND_CALL SndD8_Ch3_791A
	TRANSPOSE_UP 3
	SND_CALL SndD8_Ch3_791A
	TRANSPOSE_UP 0
	SND_LOOP
SndD8_Ch3_78E8:
	LOOP_START
	RELEASE 2, $0B
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 4, $0A
	NOTE C_HI, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	LOOP_END 2
	SND_RET
SndD8_Ch3_7908:
	LOOP_START
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	LOOP_END 2
	SND_RET
SndD8_Ch3_791A:
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE E_, 1
	SND_RET

SndD8_Drm:
	SND_SEGNO
	DRUM_UNIT 6
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END 4
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0B, 1
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
	DRUM 1, 1
	DRUM 1, 1
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
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END 2
	SND_LOOP

SndD9_Ch2:
	SND_SEGNO
	DUTY_STEP 0, 0
	VOICE 6, 8, 4, 3, $0A
	SND_CALL SndD9_Ch2_7AA5
	VOICE 6, 8, 4, 3, $0A
	TRANSPOSE_UP 3
	SND_CALL SndD9_Ch2_7AA5
	DUTY_STEP 0, 0
	TRANSPOSE_UP 0
	VOICE 6, 9, 4, 3, 9
	LOOP_START
	DUTY_STEP 0, 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	RELEASE 2, $0C
	NOTE D#, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	RELEASE $0A, $0F
	ATTEN 2
	VIBRATO $87, 0, 1
	NOTE A#, 2
	ATTEN 0
	LOOP_END 2
	DUTY_STEP 0, 0
	VIBRATO_OFF $00
	VOICE 6, 9, 8, 2, $0C
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 3
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 0
	TRANSPOSE_UP 2
	VOICE 6, 9, 4, 3, 9
	LOOP_START
	DUTY_STEP 8, 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	RELEASE 2, $0C
	NOTE D#, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	RELEASE $0A, $0F
	NOTE A#, 2
	ATTEN 0
	LOOP_END 2
	VIBRATO_OFF $00
	VOICE 6, $0A, 8, 2, $0D
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 7
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	NOTE A#, 1
	ATTEN 5
	NOTE B_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 7
	NOTE G#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 0
	DUTY_STEP 0, 0
	LOOP_START
	VOICE 6, 9, 8, 2, $0A
	DUTY_STEP $0C, 1
	OCTAVE 4
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	DUTY_STEP 0, 0
	ATTEN 3
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 0
	DUTY_STEP $0C, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	DUTY_STEP 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 4
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	ATTEN 3
	OCTAVE 4
	NOTE F_, 1
	ATTEN 0
	LOOP_END 2
	SND_LOOP
SndD9_Ch2_7AA5:
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 5
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 5
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 0
	SND_RET

SndD9_Ch1:
	SND_SEGNO
	VOICE 1, $0A, 8, 3, $0A
	PAN $0F
	SND_CALL SndD9_Ch1_7BD0
	VOICE 1, $0A, $0C, 3, $0E
	TRANSPOSE_UP 3
	SND_CALL SndD9_Ch1_7BD0
	TRANSPOSE_UP 0
	VOICE 6, 6, 4, 4, $0F
	VIBRATO $87, 0, 1
	PAN $FF
	LOOP_START
	DUTY_STEP 0, 3
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	RELEASE 2, $0D
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, $0F
	NOTE F#, 2
	ATTEN 0
	LOOP_END 2
	DUTY_STEP 0, 0
	VIBRATO_OFF $00
	VOICE 1, 5, 4, 2, $0C
	REST 6
	OCTAVE 4
	ATTEN 2
	NOTE C_, 6
	NOTE D#, 6
	ATTEN 1
	NOTE G_, 6
	ATTEN 0
	NOTE A#, 6
	ATTEN 1
	NOTE C_, 6
	NOTE D#, 6
	NOTE G_, 6
	NOTE C_, 6
	ATTEN 0
	NOTE A#, 6
	NOTE A_, 6
	ATTEN 3
	NOTE A#, 6
	ATTEN 0
	NOTE G#, 6
	ATTEN 3
	NOTE A#, 6
	ATTEN 1
	NOTE G_, 6
	NOTE F#, 6
	NOTE F_, 6
	ATTEN 2
	NOTE D#, 6
	NOTE D_, 6
	NOTE C#, 6
	ATTEN 0
	TRANSPOSE_UP 2
	VOICE 6, 6, 4, 4, $0E
	VIBRATO $87, 0, 1
	LOOP_START
	DUTY_STEP 8, 3
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	RELEASE 2, $0D
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, $0F
	NOTE F#, 2
	ATTEN 0
	LOOP_END 2
	VIBRATO_OFF $00
	VOICE 1, 5, 0, 2, $0C
	ATTEN 2
	REST 6
	OCTAVE 4
	NOTE C_, 6
	ATTEN 1
	NOTE D#, 6
	NOTE G_, 6
	ATTEN 0
	NOTE A#, 6
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE D_, 6
	OCTAVE 4
	NOTE A_, 6
	NOTE C_HI, 6
	ATTEN 2
	NOTE A_, 6
	ATTEN 0
	NOTE B_, 6
	NOTE A#, 6
	ATTEN 2
	NOTE B_, 6
	ATTEN 1
	NOTE A_, 6
	NOTE G#, 6
	NOTE G_, 6
	ATTEN 2
	NOTE G#, 6
	ATTEN 1
	NOTE F#, 6
	ATTEN 2
	NOTE F#, 6
	ATTEN 1
	NOTE F_, 6
	NOTE E_, 6
	ATTEN 0
	DUTY_STEP 0, 0
	TRANSPOSE_UP 0
	VOICE 6, 7, 4, 3, $0A
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 2
	NOTE C#, 1
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 3
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	ATTEN 2
	OCTAVE 4
	NOTE F_, 1
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	ATTEN 2
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C#, 1
	LOOP_END 2
	SND_LOOP
SndD9_Ch1_7BD0:
	PAN $0F
	ATTEN 1
	REST 6
	OCTAVE 3
	NOTE E_, 6
	NOTE G_, 6
	ATTEN 2
	NOTE A_, 6
	ATTEN 3
	NOTE G_, 6
	ATTEN 4
	NOTE A_, 6
	OCTAVE 4
	NOTE D_, 6
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	NOTE D_, 6
	ATTEN 3
	NOTE E_, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE G_, 6
	ATTEN 2
	NOTE D_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE A_, 6
	PAN $F0
	ATTEN 0
	OCTAVE 5
	NOTE D_, 6
	OCTAVE 4
	NOTE A_, 6
	NOTE G_, 6
	NOTE A_, 6
	ATTEN 3
	NOTE G_, 6
	NOTE D_, 6
	NOTE G_, 6
	NOTE D_, 6
	ATTEN 4
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	OCTAVE 3
	NOTE A_, 6
	ATTEN 6
	NOTE C_HI, 6
	NOTE A_, 6
	NOTE G_, 6
	ATTEN 0
	SND_RET

SndD9_Ch3:
	SND_SEGNO
	VOICE 6, 2, 1, 2, $0B
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 6, $0F
	NOTE A_, 1
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	VOICE 6, 2, 1, 2, $0B
	TRANSPOSE_UP 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 6, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 6, $0F
	NOTE A_, 1
	RELEASE 2, $0B
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	TRANSPOSE_UP 0
	VOICE 6, 2, 1, 2, $0B
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	TRANSPOSE_UP 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE D#, 1
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	TRANSPOSE_UP 0
	LOOP_START
	VOICE 6, 2, 1, 3, $0A
	OCTAVE 1
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	REST 4
	ATTEN 1
	RELEASE 4, $0A
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 3, $0A
	ATTEN 0
	OCTAVE 1
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	REST 8
	RELEASE 4, $0A
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	ATTEN 0
	LOOP_END 2
	SND_LOOP

SndD9_Drm:
	SND_SEGNO
	DRUM_UNIT 6
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 2, 2
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 2, 2
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	LOOP_START
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	LOOP_END 2
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
