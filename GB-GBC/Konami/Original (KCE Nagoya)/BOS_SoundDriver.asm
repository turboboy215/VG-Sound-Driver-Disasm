; ==========================================================================
; Blades of Steel (E) - Konami sound driver (later GB version)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0 $0F01-$0F80 VBlank update call, far wrappers
;   bank 7 $4000-$6C2E driver code, tables, sound data ($6C2F-$7FFF: graphics, not included)
; Build: rgbasm -Wall -o bos.o BOS_SoundDriver.asm && rgblink -o bos.gb bos.o
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
DEF wTrkSfx1 EQU $C080 ; 55 bytes
DEF wTrkSfx2 EQU $C180 ; 55 bytes
DEF wTrkSfxN EQU $C280 ; 55 bytes
DEF wTrkCh1 EQU $C380 ; 55 bytes
DEF wTrkCh2 EQU $C480 ; 55 bytes
DEF wTrkCh3 EQU $C580 ; 55 bytes
DEF wTrkDrm EQU $C680 ; 55 bytes
DEF wTrackIdx EQU $C0B9
DEF wRegBase EQU $C0BA
DEF wTempo EQU $C0BB
DEF wTempoAcc EQU $C0BC
DEF wTempoSkip EQU $C0BD
DEF wQueuedSnd EQU $C0BE
DEF wNR51 EQU $C0BF
DEF wSweepVal EQU $C0C0
DEF wReqId EQU $C0C1
DEF wReqPrio EQU $C0C2
DEF wRegVal EQU $C0C3
DEF wRegIdx EQU $C0C4
DEF wMusicHold EQU $C0C5
DEF wFadeReq EQU $C0C8
DEF wFadeTimer EQU $C0C9
DEF wFadeLevel EQU $C0CA
DEF wReqRefused EQU $C0CB
DEF wShadow EQU $C1B6 ; 20 bytes
DEF wSndLock EQU $D805
DEF wPauseFlags EQU $D81D
DEF rROMB EQU $2180 ; MBC1 bank select as written by this game
DEF hBankId EQU $7FFF ; every bank stores its own number in its last byte

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
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
DEF TRK_DUTYCNT EQU $A4
DEF TRK_DUTYSTEP EQU $A5
DEF TRK_DUTYTICKS EQU $A6
DEF TRK_GLLEN EQU $A7
DEF TRK_GLOCTAVE EQU $A8
DEF TRK_GLTARGET EQU $A9
DEF TRK_GLPERIOD EQU $AB
DEF TRK_GLSTART EQU $AD
DEF TRK_GLDIR EQU $AE
DEF TRK_GLDELTA EQU $AF
DEF TRK_GLTIMER EQU $B1
DEF TRK_GLRELOAD EQU $B2
DEF TRK_GLSTEP EQU $B3
DEF TRK_GLLOOPCNT EQU $B4

; track flags (TRK_FLAGS)
DEF TF_RELEASED EQU 0
DEF TF_AUTOPAN EQU 1
DEF TF_VIBNEG EQU 3
DEF TF_DUTYSTEP EQU 4
DEF TF_GLIDE EQU 5
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
; $ED xy: duty step. Each note starts with duty \1 for \2 ticks, then the voice duty
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
ENDM
; $EA 5n (new here, unused by the data): glide to the next note over its last n units; 0 = off
MACRO GLIDE
	db $EA, $50 | \1
ENDM

SECTION "Sound glue", ROM0[$0F01]

; SndUpdateFar: called from the VBlank handler on every frame. Skipped (tick
; lost) while the main thread is inside PlaySoundFar (wSndLock).
SndUpdateFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	call SndUpdate
	ld hl, wSndLock
	res 0, [hl]
	pop af
	ld [rROMB], a
	ret

; PlaySoundFar: A = sound id. Dropped if wSndLock is already held. Keeps HL/BC;
; the lock is only set once bank 7 is mapped.
PlaySoundFar:
	push hl
	push bc
	ld hl, wSndLock
	bit 0, [hl]
	jr nz, .l0F43
	ld h, a
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	ld a, h
	ld h, $D8
	set 0, [hl]
	call PlaySound
	ld hl, wSndLock
	res 0, [hl]
	pop af
	ld [rROMB], a
.l0F43:
	pop bc
	pop hl
	ret

; SndPauseFar / SndUnpauseFar: the game sets/clears wPauseFlags itself.
SndPauseFar:
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	call SndPause
	pop af
	ld [rROMB], a
	ret

SndUnpauseFar:
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	call SndUnpause
	pop af
	ld [rROMB], a
	ret

; StartFadeFar: A = sound to start when the fade-out ends (< 5 = stop). No lock.
StartFadeFar:
	push hl
	push de
	push bc
	ld b, a
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	ld a, b
	call StartFade
	pop af
	ld [rROMB], a
	pop bc
	pop de
	pop hl
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

; LoadPtrIndexed: HL = word at [HL + 2*A].
LoadPtrIndexed:
	add a, a
	add a, l
	ld l, a
	jr nc, .l400F
	inc h
.l400F:
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

; JumpTableInline: called with A = index; jumps to word [ret + 2*A].
; The handlers start with pop hl (the caller pushed HL before the call).
JumpTableInline:
	pop hl
	call LoadPtrIndexed
	jp hl

; SndInit: NR52 = NR51 = $FF, NR50 = $77.
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

; 85 periods, the same table as Belmont's Revenge.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; PlaySound: A = sound id, 0 = StopSound. Keeps DE.
PlaySound:
	push de
	call PlaySoundMain
	pop de
	ret

StopSound:
	push de
	ld a, $00
	call PlaySoundMain
	pop de
	ret

; StartFade: wFadeReq = A | $80 (A = sound to start when the fade ends).
StartFade:
	set 7, a
	ld [wFadeReq], a
	ret

; As in Belmont's Revenge: the check after Sfx1 and after Sfx2/SfxN aborts the
; rest of the request (and the NR51 write) when wReqRefused is set, and the flag
; is never cleared by a new request.
PlaySoundMain:
	ld [wReqId], a
	or a
	jp z, StopAll
	ld [wReqId], a
	push af
	pop af
	ld [wReqId], a
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
	jr nz, .l4144
	ld a, $08
	ldh [rNR10], a
	ld [wShadow], a
.l4144:
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
	ld [wShadow], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	ld hl, wTrkSfx1

StartTrack:
	inc l
	ld a, [wReqPrio]
	cp [hl]
	jr c, .l41C5
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
	ld [hl], a
	jr .l41C9
.l41C5:
	inc de
	inc de
	ld a, $01
.l41C9:
	ld [wReqRefused], a
	pop af
	ret

; StopAll: clear all 7 tracks ($37 bytes each), the shadows and the globals,
; wNR51 = $FF (not written to NR51), then fall into SndPause.
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, $0036
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, $0036
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

; SndPause: NR12/NR17/NR21/NR1C = 0.
SndPause:
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ldh [rNR32], a
	ret

; SndUnpause: copy the shadows back (no retrigger), per channel only if one of
; its tracks is active. Not while wPauseFlags or wMusicHold is non-zero.
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
	jr z, .l427A
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l427A:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l428F
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l428F:
	ld a, [wTrkCh3]
	or a
	jr z, .l42A0
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l42A0:
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

; FadeTick: while wFadeReq bit 7 is set, wFadeLevel goes up by one every 16
; ticks. At level 5 bits 0-6 are queued; a target below 5 (0 included) calls
; StopAll instead, which also clears the queue. Frozen while paused.
FadeTick:
	ld a, [wPauseFlags]
	bit 0, a
	ret nz
	ld a, [wFadeReq]
	bit 7, a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	ld a, [hl]
	and $0F
	ret nz
	ld hl, wFadeLevel
	inc [hl]
	ld a, [hl]
	cp $05
	ret nz
	ld a, [wFadeReq]
	res 7, a
	ld [wQueuedSnd], a
	cp $05
	jp c, StopAll
	xor a
	ld [hl], a
	ld [wFadeReq], a
	ret

; TempoTick: wTempoAcc += wTempo; a carry skips the music tracks this tick.
TempoTick:
	ld a, [wTempo]
	ld b, a
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld a, $01
	jr c, .l42F3
	xor a
.l42F3:
	ld [wTempoSkip], a
	ret

; SndUpdate: one driver tick (VBlank, 59.7 Hz). Tracks 0-2 (SFX) run every tick,
; tracks 3-6 (music) are skipped on tempo-skip ticks. While paused (wPauseFlags
; bit 0) only track 1 runs, and only for sound $06. Then wQueuedSnd is started.
SndUpdate:
	call FadeTick
	call TempoTick
	xor a
.l42FE:
	ld [wTrackIdx], a
	ld a, [wPauseFlags]
	or a
	bit 0, a
	jr z, .l4319
	ld a, [wTrackIdx]
	cp $01
	jr nz, SndUpdateNext
	ld a, [wTrkSfx2]
	cp $06
	jr z, SndUpdateRun
	jr SndUpdateDone
.l4319:
	ld a, [wTrackIdx]
	cp $03
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone
	jr SndUpdateRun
	ld a, [wTrackIdx]
	cp $04
	jr nz, SndUpdateRun
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, SndUpdateDone

SndUpdateRun:
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, TrackTick

SndUpdateNext:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, SndUpdate.l42FE

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
	jr nz, .l4387
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
.l4387:
	ld l, TRK_FLAGS
	bit 4, [hl]
	jr z, .l4397
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l4397:
	ld l, TRK_RELTICK
	ld a, [hl]
	ld l, TRK_LEN
	sub [hl]
	jr c, .l43A3
	ld l, TRK_FLAGS
	set 0, [hl]
.l43A3:
	ld l, TRK_FLAGS
	bit 7, [hl]
	ret nz
	ld a, [wTrackIdx]
	cp $02
	ret z
	cp $06
	ret z
	call GlideTick
	call GlideOrVibrato

; TrackTickTail: CH3 decay, or the release (env write + retrigger) at TRK_RELTICK.
; GlideTick and GlideOrVibrato jump here with their return address still on the
; stack, so with TF_GLIDE set this runs twice per tick (three times while the
; glide timer is counting): CH3 decays two or three times as fast and the
; release retriggers more than once.
TrackTickTail:
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

; Ch3Decay: step the NR32 level code up (1 -> 2 -> 3 -> off) every env ticks
; after the release point (the attenuation is counted twice).
Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l4405
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
	jr z, .l4405
	inc a
	and $03
	ld [hl], a
	jr z, .l4405
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l4402
	xor a
.l4402:
	rla
	swap a
.l4405:
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

; GlideTick: once the note has TRK_GLSTART ticks or fewer left, every
; TRK_GLRELOAD ticks move TRK_GLPERIOD by TRK_GLSTEP towards the target and write
; it (no vibrato). It doesn't stop at the target.
GlideTick:
	ld l, TRK_FLAGS
	bit 5, [hl]
	ret z
	ld l, TRK_GLSTART
	ld a, [hl]
	or a
	ret z
	ld l, TRK_LEN
	cp [hl]
	ret c
	ld l, TRK_GLTIMER
	dec [hl]
	jr nz, TrackTickTail
	ld l, TRK_GLRELOAD
	ld a, [hl]
	ld l, TRK_GLTIMER
	ld [hl], a
	ld l, TRK_GLSTEP
	ld c, [hl]
	ld b, $00
	ld l, TRK_GLPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_GLDIR
	bit 0, [hl]
	push hl
	jp z, .l4442
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l4442:
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
	ld a, c
	ld l, TRK_GLPERIOD
	ld [hl+], a
	ld [hl], b
	jp WritePeriodBC

; GlideOrVibrato: vibrato only without TF_GLIDE.
GlideOrVibrato:
	ld l, TRK_FLAGS
	bit 5, [hl]
	jp nz, TrackTickTail

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
	jr z, .l44BB
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l44C5
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l44BB:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l44C5:
	ld l, TRK_LOOPCNT
	ld [hl], $00
	jr ReadCmdsNext

; $FF: end of track. NRx2 = 0 (no trigger). When an SFX on CH1/CH2 ends while
; music uses the channel, restore the music duty and period (CH1 also clears
; NR10). CH3: NR30 = 0.
Cmd_End:
	pop hl
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
	jr nz, .l44E7
	xor a
	ldh [rNR30], a
	ret
.l44E7:
	cp $01
	jr z, .l44F5
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l44F7
.l44F5:
	ld h, HIGH(wTrkCh2)
.l44F7:
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
	dw Cmd_EB_EC
	dw Cmd_EB_EC
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

; $EA xy: extended commands, x = 0..5.
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
	dw Ext_Glide

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
	jr nz, .l45A5
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp ReadCmdsNext
.l45A5:
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

; $EA 4n: stores n | TF_AUTOPAN into the whole flags byte (0 for n = 0), which also
; clears TF_DUTYSTEP, TF_GLIDE and TF_FORCE.
Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, Ext_Glide.l45EF
	or $02
	jr Ext_Glide.l45F1

; $EA 5n (new): TF_GLIDE on with TRK_GLLEN = n, or off for n = 0. Not used by the
; data.
Ext_Glide:
	pop hl
	ld a, [de]
	and $0F
	jr z, .l45E8
	ld l, TRK_FLAGS
	set 5, [hl]
	ld l, TRK_GLLEN
	ld [hl], a
	jp ReadCmdsNext
.l45E8:
	ld l, TRK_FLAGS
	res 5, [hl]
	jp ReadCmdsNext
.l45EF:
	and $FD
.l45F1:
	ld [hl], a
	jp ReadCmdsNext

Cmd_EB_EC:
	pop hl
	jp ReadCmdsNext

; $ED xy: duty step. y = duty for the first x ticks of each note; 0 = off.
Cmd_DutyStep:
	pop hl
	ld l, TRK_FLAGS
	ld a, [de]
	or a
	jr z, .l4612
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
.l4612:
	res 4, [hl]
	jp ReadCmdsNext

Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	jp ReadCmdsNext

; $EF x: NR51 bits for this track = swap(x), as in Nemesis (Belmont's Revenge
; stored raw bits per track). Dropped on music CH1 while the CH1 SFX plays (not
; on CH2).
Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4631
	ld a, [wTrkSfx1]
	or a
	jp nz, ReadCmdsNext
	ld a, [wTrackIdx]
.l4631:
	push hl
	ld hl, PanKeepMask
	add a, l
	ld l, a
	jr nc, .l463A
	inc h
.l463A:
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

; NR51 bits each track keeps when it pans (the others come from the argument).
PanKeepMask:
	db $EE, $DD, $77, $EE, $DD, $BB, $FF

; AutoPan: swap the halves of this track's NR51 bits (every track, no blocking).
AutoPan:
	ld a, [wNR51]
	swap a
	ld c, a
	ld a, [wTrackIdx]
	push hl
	ld hl, PanKeepMask
	add a, l
	ld l, a
	jr nc, .l4669
	inc h
.l4669:
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

; $E1-$E6: octave (also the look-ahead octave TRK_GLOCTAVE).
Cmd_Octave:
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	ld l, TRK_GLOCTAVE
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
	jr z, .l46BB
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
.l46BB:
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
	ld b, a
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l4731:
	add a, c
	dec b
	jr nz, .l4731
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l4765
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l4765
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	call WriteReg
.l4765:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4772
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4784
.l4772:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l477A:
	srl c
	jr nc, .l477F
	add a, d
.l477F:
	rra
	dec b
	jr nz, .l477A
	pop de
.l4784:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l479C
	ld b, a
	ld c, $0C
	xor a
.l4797:
	add a, c
	dec b
	jr nz, .l4797
	ld c, a
.l479C:
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
	jp GlideSetup

NoteGlideDone:
	pop de

NoteStart:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jr z, .l47CC
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoStep
.l47CC:
	call WritePeriod
	call NoteVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	jp Trigger

; GlideSetup: TRK_GLPERIOD = the new period. With TF_GLIDE, read ahead (following
; calls, returns, loops and jumps, and writing TRK_SEGNO/TRK_RET on the way, with
; its own loop counter TRK_GLLOOPCNT) to the next note, whose period is the target.
; An $FF ahead turns TF_GLIDE off. The glide starts TRK_GLLEN units before the
; note ends; TRK_GLSTEP/TRK_GLRELOAD are set so it covers the distance in that time.
GlideSetup:
	ld l, TRK_GLPERIOD
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_FLAGS
	bit 5, [hl]
	jr z, NoteStart
	push de
.l47EC:
	inc de

GlideScan:
	ld a, [de]
	or a
	cp $FB
	jr z, .l4808
	jr c, .l484F
	cp $FC
	jr z, .l4810
	cp $FD
	jr z, .l4817
	cp $FE
	jr z, .l4827
	ld l, TRK_FLAGS
	res 5, [hl]
	jp NoteGlideDone
.l4808:
	inc de
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jr GlideScan
.l4810:
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jr GlideScan
.l4817:
	inc de
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
	jr GlideScan
.l4827:
	inc de
	ld a, [de]
	cp $FF
	jr z, .l483A
	ld l, TRK_GLLOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l4844
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr GlideScan
.l483A:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr GlideScan
.l4844:
	ld l, TRK_GLLOOPCNT
	ld [hl], $00
	jr GlideSetup.l47EC
.l484A:
	inc de
	inc de
.l484C:
	inc de
	jr GlideSetup.l47EC
.l484F:
	cp $E0
	jr z, .l484A
	and $F0
	cp $E0
	jr c, GlideTarget
	cp $F0
	jp z, GlideSetup.l47EC
	ld a, [de]
	cp $E7
	jr nc, .l484C
	ld a, [de]
	and $0F
	dec a
	ld l, TRK_GLOCTAVE
	ld [hl], a
	jp GlideSetup.l47EC

GlideTarget:
	ld c, $00
	ld l, TRK_GLOCTAVE
	ld a, [hl]
	or a
	jr z, .l487E
	ld b, a
	ld c, $0C
	xor a
.l4879:
	add a, c
	dec b
	jr nz, .l4879
	ld c, a
.l487E:
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
	ld l, TRK_GLTARGET
	ld [hl], c
	inc l
	ld [hl], b
	pop de
	ld l, TRK_GLLEN
	ld b, [hl]
	ld l, TRK_UNIT
	ld c, [hl]
	xor a
.l48A5:
	add a, c
	dec b
	jr nz, .l48A5
	ld b, a
	ld l, TRK_LEN
	ld a, [hl]
	sub b
	ld l, TRK_GLSTART
	ld [hl], a
	jp z, NoteStart
	push de
	ld l, TRK_GLTARGET + 1
	ld a, [hl]
	ld l, TRK_PERIOD + 1
	cp [hl]
	jr z, .l48D9
	jr c, .l48F1
.l48BF:
	ld l, TRK_GLTARGET
	ld a, [hl]
	ld l, TRK_PERIOD
	sub [hl]
	ld e, a
	inc l
	ld c, [hl]
	ld l, TRK_GLTARGET + 1
	ld a, [hl]
	sbc a, c
	ld d, a
	ld l, TRK_GLDIR
	res 0, [hl]
.l48D1:
	ld l, TRK_GLDELTA
	ld [hl], e
	inc l
	ld [hl], d
	pop de
	jr GlideStep
.l48D9:
	dec l
	ld c, [hl]
	ld l, TRK_GLTARGET
	ld a, [hl]
	cp c
	jr z, .l48E5
	jr c, .l48F1
	jr .l48BF
.l48E5:
	xor a
	ld l, TRK_GLSTEP
	ld [hl], a
	dec a
	ld l, TRK_GLTIMER
	ld [hl+], a
	ld [hl], a
	jp NoteGlideDone
.l48F1:
	ld l, TRK_PERIOD
	ld a, [hl]
	ld l, TRK_GLTARGET
	sub [hl]
	ld e, a
	inc l
	ld c, [hl]
	ld l, TRK_PERIOD + 1
	ld a, [hl]
	sbc a, c
	ld d, a
	ld l, TRK_GLDIR
	set 0, [hl]
	jr .l48D1

GlideStep:
	push de
	ld l, TRK_GLDELTA + 1
	ld a, [hl]
	or a
	jr nz, .l4916
	ld l, TRK_GLDELTA
	ld a, [hl]
	ld l, TRK_GLSTART
	cp [hl]
	jr z, .l4950
	jr c, .l4941
.l4916:
	ld l, TRK_GLDELTA
	ld a, [hl+]
	ld d, [hl]
	ld l, TRK_GLSTART
	ld c, [hl]
	ld b, $00
.l491F:
	sub c
	inc b
	jr nc, .l491F
	push af
	ld a, d
	or a
	jr z, .l4932
	pop af
.l4929:
	sub c
	inc b
	jr nc, .l4929
	dec d
	jr nz, .l4929
	jr .l4933
.l4932:
	pop af
.l4933:
	ld l, TRK_GLSTEP
	ld [hl], b
	ld l, TRK_GLTIMER
	ld [hl], $01
	inc l
	ld [hl], $01
	pop de
	jp NoteStart
.l4941:
	ld b, $00
	ld l, TRK_GLSTART
	ld a, [hl]
	ld l, TRK_GLDELTA
	ld c, [hl]
.l4949:
	sub c
	inc b
	jr nc, .l4949
	jp .l495F
.l4950:
	ld l, TRK_GLSTEP
	ld [hl], $01
	ld l, TRK_GLTIMER
	ld [hl], $01
	inc l
	ld [hl], $01
	pop de
	jp NoteStart
.l495F:
	ld l, TRK_GLSTEP
	ld [hl], $01
	ld l, TRK_GLTIMER
	ld [hl], b
	inc l
	ld [hl], b
	pop de
	jp NoteStart

; NoteVolume: NRx2 for a note-on = (vol - atten - wFadeLevel) << 4, floored at 0
; (CH3: level code from vol/2 + atten + wFadeLevel/2, NR30 on).
NoteVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, .l498E
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l4988
	xor a
.l4988:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l498E:
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
	jr c, .l49B6
	xor a
.l49B6:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

; VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step. The negate
; flag is now set or cleared by every step.
VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jr nc, .l49C9
	inc b
.l49C9:
	ld a, [bc]
	cp $FB
	jr z, .l49FF
	cp $FE
	jr z, .l4A09
	cp $FF
	jr z, .l4A27
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	ld l, TRK_FLAGS
	jr z, .l49EB
	set 3, [hl]
	jr .l49ED
.l49EB:
	res 3, [hl]
.l49ED:
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
.l49FF:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l49C9
.l4A09:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l4A1D
	cp $FF
	jr z, .l4A15
	inc [hl]
.l4A15:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jr VibratoStep
.l4A1D:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr .l49C9
.l4A27:
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
	jr z, .l4A40
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc a, b
	ld b, a
.l4A40:
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

; Rest: NRx2 = 0 only.
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

; DrumNote: start sound DrumMap[hi - 1] at once.
DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	add a, l
	ld l, a
	jr nc, .l4A8C
	inc h
.l4A8C:
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l4AA7
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l4AA7:
	dec a
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l4AB5:
	ld a, [hl+]
	ld [de], a
	inc e
	dec b
	jr nz, .l4AB5
	pop hl
	pop de
	ret

; IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the
; CH2 SFX active.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4ACC
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l4AD5
.l4ACC:
	cp $04
	jr nz, .l4AD7
	ld a, [wTrkSfx2]
	or a
	ret z
.l4AD5:
	scf
	ret
.l4AD7:
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
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
	ld h, a
	ld l, TRK_FLAGS
	bit 6, [hl]
	pop hl
	jr nz, .l4AF7
	ld a, [hl]
	cp c
	jr z, .l4AFA
.l4AF7:
	ld a, c
	ld [hl], a
	ld [de], a
.l4AFA:
	pop de
	ld a, [wTrackIdx]
	add a, HIGH(wTrkSfx1)
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
	add a, HIGH(wTrkSfx1)
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
	add a, l
	ld l, a
	jr nc, .l4B3F
	inc h
.l4B3F:
	ld a, [hl]
	pop hl
	ret

; NR register base per track.
RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; Sound table: 51 ids ($01-$33). The code indexes it as SoundTable - 2 + 2*id.
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

SndHdr06:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd06_Sfx2

SndHdr07:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd07_Sfx1
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd09_Sfx1
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $41, $05 ; tracks: Sfx1, SfxN
	dw Snd0A_Sfx1
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $41, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0B_Sfx1
	dw Snd0B_Sfx2
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $42, $03 ; tracks: Sfx1, Sfx2
	dw Snd0C_Sfx1
	dw Snd0C_Sfx2

SndHdr0D:
	SND_HEADER $42, $04 ; tracks: SfxN
	dw Snd0D_SfxN

SndHdr0E:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $33, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $33, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd13_Ch1
	dw Snd13_Ch2
	dw Snd13_Ch3

SndHdr15:
	SND_HEADER $33, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd15_Ch1
	dw Snd15_Ch2
	dw Snd15_Ch3
	dw Snd15_Drm

SndHdr16:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd18_Sfx1
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd1A_SfxN

SndHdr1B:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $32, $03 ; tracks: Sfx1, Sfx2
	dw Snd1E_Sfx1
	dw Snd1E_Sfx2

SndHdr1F:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $32, $03 ; tracks: Sfx1, Sfx2
	dw Snd22_Sfx1
	dw Snd22_Sfx2

SndHdr23:
	SND_HEADER $32, $03 ; tracks: Sfx1, Sfx2
	dw Snd23_Sfx1
	dw Snd23_Sfx2

SndHdr24:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd24_Sfx1
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr14:
	SND_HEADER $41, $3F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3
	dw Snd0C_Sfx1
	dw Snd0C_Sfx2
	dw Snd0D_SfxN
	dw Snd13_Ch1
	dw Snd13_Ch2
	dw Snd13_Ch3

SndHdr27:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd27_Ch1
	dw Snd27_Ch2
	dw Snd27_Ch3
	dw Snd27_Drm

SndHdr28:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd28_Ch1
	dw Snd28_Ch2
	dw Snd28_Ch3
	dw Snd28_Drm

SndHdr29:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd29_Ch1
	dw Snd29_Ch2
	dw Snd29_Ch3
	dw Snd29_Drm

SndHdr2A:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2A_Ch1
	dw Snd2A_Ch2
	dw Snd2A_Ch3
	dw Snd2A_Drm

SndHdr2B:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2B_Ch1
	dw Snd2B_Ch2
	dw Snd2B_Ch3
	dw Snd2B_Drm

SndHdr2C:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2C_Ch1
	dw Snd2C_Ch2
	dw Snd2C_Ch3
	dw Snd2C_Drm

SndHdr2D:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2D_Ch1
	dw Snd2D_Ch2
	dw Snd2D_Ch3
	dw Snd2D_Drm

SndHdr2E:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2E_Ch1
	dw Snd2E_Ch2
	dw Snd2E_Ch3
	dw Snd2E_Drm

SndHdr2F:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd2F_Ch1
	dw Snd2F_Ch2
	dw Snd2F_Ch3
	dw Snd2F_Drm

SndHdr30:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd30_Ch1
	dw Snd30_Ch2
	dw Snd30_Ch3
	dw Snd30_Drm

SndHdr31:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd31_Ch1
	dw Snd31_Ch2
	dw Snd31_Ch3
	dw Snd31_Drm

SndHdr32:
	SND_HEADER $30, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd32_Ch1
	dw Snd32_Ch2
	dw Snd32_Ch3
	dw Snd32_Drm

SndHdr33:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd33_Ch1
	dw Snd33_Ch2
	dw Snd33_Ch3
	dw Snd33_Drm

Snd06_Sfx2:
	VOICE 3, $0F, 8, 1, $0F
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 6
	SND_END

Snd07_Sfx1:
	VOICE 1, $0C, 8, $0F, 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE 1, $0E
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	ATTEN 7
	OCTAVE 5
	NOTE C_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd07_SfxN:
	NVOICE 1, $0F, 4
	NOISE $2A
	SND_END

Snd08_SfxN:
	SND_END

; Unreferenced noise stream.
Orphan_4D0C:
	NVOICE 2, 2, 9
	NOISE $01
	NOISE $51
	NOISE $01
	NOISE $11
	SND_END

Snd09_Sfx1:
	VOICE 1, $0F, 0, $0F, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_END

Snd09_SfxN:
	NVOICE 1, $0F, 1
	NOISE $6A
	NOISE $11
	NOISE $11
	SND_END

Snd0A_Sfx1:
	SND_END

Snd0A_SfxN:
	NVOICE 9, 0, 9
	SND_CALL Snd0A_SfxN_4D33
	NVOICE $0A, 8, 7
	SND_CALL Snd0A_SfxN_4D44
	SND_END
Snd0A_SfxN_4D33:
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $32
	NOISE $31
	NOISE $32
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $32
	NOISE $34
	SND_RET
Snd0A_SfxN_4D44:
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	SND_RET

Snd0B_Sfx1:
	SND_END

Snd0B_Sfx2:
	SND_END

Snd0B_SfxN:
	NVOICE $0B, 8, 9
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
Snd0B_SfxN_4D74:
	SND_CALL Snd0B_SfxN_4D7A
	SND_CALL Snd0B_SfxN_4D74
Snd0B_SfxN_4D7A:
	NVOICE 8, 8, 0
	NOISE $46
	NVOICE 8, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	NVOICE $0A, 8, 0
	NOISE $46
	SND_RET

Snd0C_Sfx1:
	VOICE 1, 6, 8, $0F, 0
	REST 8
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT $10
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	ATTEN 3
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT $10
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	ATTEN 4
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT 8
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_END

Snd0C_Sfx2:
	VIBRATO $0E
	VOICE 1, 4, 8, $0F, 0
	REST $0B
	REST 8
	REST 8
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT $10
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	REST 8
	REST 8
	REST 8
	ATTEN 2
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT $10
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	REST 8
	OCTAVE 6
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	SND_REPEAT 8
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_END

Snd0D_SfxN:
	NVOICE $0B, 0, 9
	NOISE $35
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NVOICE 1, 0, 0
	NOISE $00
	NVOICE 8, 5, 0
	NOISE $43
	NVOICE 8, 5, 0
	NOISE $43
	NVOICE 8, 6, 0
	NOISE $44
	NVOICE 8, 6, 0
	NOISE $44
	NVOICE 8, 7, 0
	NOISE $44
	NOISE $46
	NVOICE 8, 8, 0
	NOISE $46
	NVOICE 8, 8, 0
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

Snd0E_Sfx1:
	VOICE 1, 8, 8, $0F, 0
	SND_CALL Snd0E_Sfx1_4E63
	RELEASE 3, $0D
	ATTEN 6
	SND_CALL Snd0E_Sfx1_4E63
	ATTEN 7
	LEN_UNIT 2
	SND_CALL Snd0E_Sfx1_4E63
	SND_END
Snd0E_Sfx1_4E63:
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_RET

Snd0F_Sfx1:
	VOICE 3, $0F, 8, $0F, 0
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
	SND_REPEAT 8
	SND_END

Snd10_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	SND_SEGNO
	OCTAVE 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT $0C
	SND_END

Snd11_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST $0D
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT $0A
	SND_END

Snd12_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 8
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 3
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT 6
	SND_END

Snd16_Sfx1:
	VOICE 1, $0F, 0, 1, $0F
	OCTAVE 4
	NOTE C_HI, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE C_HI, 1
	SND_END

Snd17_Sfx1:
	DUTY_STEP 0, 2
	VOICE 6, $0F, 8, 1, $0F
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN $0A
	NOTE C_HI, 1
	SND_END

Snd18_Sfx1:
	VOICE 1, 5, 8, 0, 0
	OCTAVE 6
	NOTE A_, 2
	REST 2
	NOTE C_HI, 2
	SND_END

Snd18_SfxN:
	NVOICE 2, $0F, 1
	NOISE $41
	NOISE $11
	SND_END

Snd19_SfxN:
	NVOICE 1, $0F, 4
	NOISE $34
	NVOICE 8, 8, 2
	NOISE $53
	SND_END

Snd1A_SfxN:
	NVOICE 3, 8, 2
	NOISE $71
	NOISE $47
	NOISE $41
	NOISE $46
	SND_END

Snd1B_Sfx1:
	VOICE 1, 8, 8, $0F, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 4
	OCTAVE 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 7
	OCTAVE 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd1C_Sfx1:
	VOICE 4, 8, 4, 1, $0F
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 4
	ATTEN 5
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 4
	ATTEN 7
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 4
	SND_END

Snd1D_Sfx1:
	VOICE 1, $0C, 0, 1, $0F
	OCTAVE 5
	NOTE G_, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	SND_END

Snd1E_Sfx1:
	VOICE 6, 8, 4, 1, $0F
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 5
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd1E_Sfx2:
	VIBRATO $0E
	VOICE 6, 2, 8, $0F, 0
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd1F_SfxN:
	NVOICE 6, 8, 6
	NOISE $41
	NOISE $11
	NVOICE 6, 5, 6
	NOISE $11
	NVOICE 6, 4, 6
	NOISE $11
	SND_END

Snd20_Sfx1:
	VOICE 6, 8, 8, 1, $0F
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	ATTEN 6
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE G_, 1
	SND_END

Snd21_Sfx1:
	VOICE 1, $0B, 8, $0F, 0
	OCTAVE 5
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 8
	NOTE E_, 1
	NOTE G_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE G_, 1
	SND_END

Snd22_Sfx1:
	VOICE 3, $0B, 8, $0F, 0
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	PAN $F0
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 9
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 2
	SND_END

Snd22_Sfx2:
	LEN_UNIT 1
	REST 2
	VOICE 3, 4, 0, $0F, 0
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	SND_END

Snd23_Sfx1:
	VIBRATO 5
	VOICE 6, $0A, 0, $0F, 0
	OCTAVE 3
	NOTE D#, $0C
	ATTEN 7
	NOTE D#, 6
	ATTEN 8
	NOTE D#, 6
	SND_END

Snd23_Sfx2:
	VIBRATO $0E
	VOICE 6, 5, 0, $0F, 0
	OCTAVE 3
	NOTE D#, $0C
	ATTEN 2
	NOTE D#, 6
	ATTEN 3
	NOTE D#, 6
	SND_END

Snd24_Sfx1:
	TRANSPOSE_DOWN $0F
	VOICE 1, $0A, $0C, $0F, 0
	OCTAVE 3
	NOTE G_, 3
	OCTAVE 4
	NOTE C#, 1
	ATTEN 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 3
	ATTEN 9
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_END

Snd24_SfxN:
	NVOICE $0A, 5, 2
	NOISE $13
	SND_END

Snd25_Sfx1:
	VOICE 1, 4, 8, $0F, 0
	OCTAVE 5
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	ATTEN 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	SND_END

Snd25_SfxN:
	NVOICE 9, 6, 6
	NOISE $37
	NVOICE 5, 3, 7
	NOISE $14
	NOISE $14
	SND_END

Snd26_Sfx1:
	VOICE 2, 6, 4, $0F, 0
	OCTAVE 3
	NOTE C#, 2
	NOTE A_, 1
	ATTEN 4
	NOTE C#, 1
	NOTE A_, 1
	SND_END

Snd26_SfxN:
	NVOICE 4, $0F, 8
	NOISE $41
	NVOICE 4, 6, 8
	NOISE $21
	NOISE $11
	SND_END

Snd13_Ch1:
	VIBRATO $0E
	TEMPO $20
	VOICE 4, 4, 4, $0F, 0
	REST 1
	LEN_UNIT 1
	OCTAVE 2
	NOTE G_, 5
	OCTAVE 3
	NOTE C_, 6
	NOTE E_, 5
	NOTE G_, $0B
	NOTE E_, 5
	LEN_UNIT 4
	NOTE G_, $0F
	REST 1
	LEN_UNIT 1
	OCTAVE 2
	NOTE G#, 5
	OCTAVE 3
	NOTE C#, 6
	NOTE F_, 5
	NOTE G#, $0B
	NOTE F_, 5
	LEN_UNIT 4
	NOTE G#, $0F
	REST 1
	LEN_UNIT 1
	OCTAVE 2
	NOTE A_, 5
	OCTAVE 3
	NOTE D_, 6
	NOTE F#, 5
	NOTE A_, $0B
	NOTE F#, 5
	LEN_UNIT 4
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, $0F
	TEMPO $00
	SND_END

Snd13_Ch2:
	VIBRATO $0E
	VOICE 4, 2, 8, $0F, 0
	REST 3
	LEN_UNIT 1
	OCTAVE 2
	NOTE G_, 5
	OCTAVE 3
	NOTE C_, 6
	NOTE E_, 5
	NOTE G_, $0B
	NOTE E_, 5
	LEN_UNIT 4
	NOTE G_, $0F
	REST 1
	LEN_UNIT 1
	OCTAVE 2
	NOTE G#, 5
	OCTAVE 3
	NOTE C#, 6
	NOTE F_, 5
	NOTE G#, $0B
	NOTE F_, 5
	LEN_UNIT 4
	NOTE G#, $0F
	REST 1
	LEN_UNIT 1
	OCTAVE 2
	NOTE A_, 5
	OCTAVE 3
	NOTE D_, 6
	NOTE F#, 5
	NOTE A_, $0B
	NOTE F#, 5
	LEN_UNIT 4
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, $0F
	SND_END

Snd13_Ch3:
	VIBRATO 3
	VOICE 4, 2, 2, 5, $0F
	LEN_UNIT 1
	OCTAVE 2
	NOTE G_, 5
	OCTAVE 3
	NOTE C_, 6
	NOTE E_, 5
	NOTE G_, $0B
	NOTE E_, 5
	LEN_UNIT 4
	RELEASE $0F, 0
	NOTE G_, $0F
	REST 1
	LEN_UNIT 1
	RELEASE 5, $0F
	OCTAVE 2
	NOTE G#, 5
	OCTAVE 3
	NOTE C#, 6
	NOTE F_, 5
	NOTE G#, $0B
	NOTE F_, 5
	LEN_UNIT 4
	RELEASE $0F, 0
	NOTE G#, $0F
	REST 1
	LEN_UNIT 1
	RELEASE 5, $0F
	OCTAVE 2
	NOTE A_, 5
	OCTAVE 3
	NOTE D_, 6
	NOTE F#, 5
	NOTE A_, $0B
	NOTE F#, 5
	LEN_UNIT 4
	NOTE A_, 4
	NOTE A_, 4
	RELEASE $0F, 0
	OCTAVE 4
	NOTE D_, $0F
	SND_END

Snd15_Ch1:
	VIBRATO $0A
	VOICE 4, 8, 4, 7, $0A
	OCTAVE 1
	NOTE G_, $0C
	NOTE F_, $0C
	NOTE E_, $0C
	NOTE D#, $0C
	LEN_UNIT $0A
	RELEASE $0D, 0
	NOTE G_, 8
	SND_END

Snd15_Ch2:
	TEMPO $20
	VIBRATO 4
	LEN_UNIT 1
	REST 4
	VOICE 2, 5, $0C, $0F, 0
	ATTEN 2
	OCTAVE 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	TEMPO $40
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D_, 4
	TEMPO $60
	NOTE G_, 4
	NOTE A_, 4
	LEN_UNIT 1
	NOTE A#, 4
	LEN_UNIT $0A
	RELEASE $0F, 0
	ATTEN 0
	NOTE G_, 8
	SND_END

Snd15_Ch3:
	VOICE 2, 2, 2, 5, $0A
	OCTAVE 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	VIBRATO $0A
	LEN_UNIT $0A
	RELEASE $0F, 0
	NOTE B_, 8
	SND_END

Snd15_Drm:
	SND_END

; CH3 wave pointers 1-15 (9-11 share a wave).
WaveTable:
	dw WaveData1
	dw WaveData2
	dw WaveData3
	dw WaveData4
	dw WaveData5
	dw WaveData6
	dw WaveData7
	dw WaveData8
	dw WaveData9
	dw WaveData9
	dw WaveData9
	dw WaveData10
	dw WaveData11
	dw WaveData12
	dw WaveData13
WaveData1:
	db $88, $88, $8F, $F8, $80, $00, $88, $88, $FF, $F8, $00, $88, $88, $FF, $88, $00
WaveData2:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData3:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10
WaveData4:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData5:
	db $23, $44, $55, $67, $89, $9A, $BB, $CD, $23, $56, $78, $9A, $CD, $CA, $98, $53
WaveData6:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
WaveData7:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
WaveData9:
	db $34, $45, $56, $67, $89, $9A, $AB, $BC, $34, $45, $56, $67, $89, $9A, $AB, $BC
WaveData10:
	db $88, $88, $88, $88, $00, $00, $00, $00, $88, $88, $88, $88, $00, $00, $00, $00
WaveData11:
	db $88, $88, $88, $88, $FF, $FF, $FF, $FF, $88, $88, $88, $88, $00, $00, $00, $00
WaveData12:
	db $88, $88, $88, $88, $FF, $FF, $FF, $FF, $88, $88, $88, $88, $00, $00, $00, $00
WaveData13:
	db $66, $66, $66, $66, $00, $00, $00, $00, $66, $66, $66, $66, $00, $00, $00, $00

; Drum map: DRUM n plays sound DrumMap[n-1] (11 entries).
DrumMap:
	db $01, $02, $01, $03, $03, $03, $03, $04, $05, $05, $05

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

Snd01_SfxN:
	PAN $0F
	NVOICE 1, 9, 1
	NOISE $01
	SND_END

Snd02_SfxN:
	PAN $F0
	NVOICE 1, 9, 1
	NOISE $01
	SND_END

Snd03_SfxN:
	SND_END

Snd04_SfxN:
	NVOICE 1, $0C, 1
	NOISE $4D
	NVOICE 1, 8, 1
	NOISE $21
	NOISE $11
	SND_END

Snd05_SfxN:
	NVOICE 1, 7, 2
	NOISE $58
	NOISE $6A
	SND_END

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

Vib01:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $006
	VIB_SEGNO
	VIB_STEP 1, 0, $00A
	VIB_STEP 1, 0, $000
	VIB_REPEAT $FF

Vib02:
	VIB_STEP 15, 1, $001
	VIB_HOLD

Vib0A:
	VIB_STEP 1, 0, $000
	VIB_HOLD

Vib09:
	VIB_STEP 15, 0, $000
	VIB_HOLD

Vib03:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $000
	VIB_SEGNO
	VIB_STEP 4, 0, $002
	VIB_STEP 4, 0, $000
	VIB_REPEAT $FF

Vib0E:
	VIB_STEP 1, 0, $001
	VIB_HOLD

Vib05:
	VIB_SEGNO
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $008
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib04:
	VIB_STEP 8, 0, $000
	VIB_STEP 1, 0, $001
	VIB_SEGNO
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $000
	VIB_STEP 2, 1, $002
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib06:
	VIB_STEP 15, 0, $000

Vib0F:
	VIB_STEP 1, 0, $003
	VIB_HOLD

Vib0D:
	VIB_STEP 15, 0, $000
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $000
	VIB_STEP 2, 1, $001
	VIB_STEP 2, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $000
	VIB_STEP 2, 1, $002
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib08:
	VIB_STEP 12, 0, $000
	VIB_STEP 4, 0, $00F
	VIB_STEP 4, 1, $00F
	VIB_STEP 4, 0, $00F
	VIB_STEP 4, 1, $00F
	VIB_STEP 4, 0, $00F
	VIB_SEGNO
	VIB_STEP 3, 1, $00F
	VIB_STEP 3, 0, $00F
	VIB_REPEAT $FF

Vib07:
	VIB_STEP 15, 0, $000
	VIB_STEP 6, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $003
	VIB_STEP 1, 0, $005
	VIB_SEGNO
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $000
	VIB_STEP 2, 1, $004
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib0B:
	VIB_STEP 8, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $002
	VIB_SEGNO
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $000
	VIB_STEP 2, 1, $003
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib0C:
	VIB_STEP 4, 0, $000
	VIB_STEP 1, 0, $002
	VIB_SEGNO
	VIB_STEP 1, 0, $004
	VIB_STEP 1, 0, $000
	VIB_STEP 1, 1, $004
	VIB_STEP 1, 0, $000
	VIB_REPEAT $FF

Snd29_Ch2:
	PAN $0F
	AUTOPAN 2
	VOICE 6, 8, 4, 1, 8
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 5
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd29_Ch1:
	PAN $F0
	AUTOPAN 2
	VIBRATO 1
	VOICE 6, 2, 8, 4, 8
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 2
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	SND_REPEAT 2
	OCTAVE 2
	REST 1
	NOTE A#, 1
	REST 2
	OCTAVE 3
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 2
	NOTE E_, 1
	REST 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd29_Ch3:
	VOICE 6, 2, 2, 5, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	REST 1
	NOTE A#, 3
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	RELEASE 3, $0F
	LEN_UNIT 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	RELEASE 4, $0F
	LEN_UNIT 6
	NOTE F_, 1
	NOTE D#, 1
	TRANSPOSE_DOWN $0C
	OCTAVE 2
	REST 1
	NOTE A#, 1
	REST 2
	OCTAVE 3
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 2
	NOTE E_, 1
	REST 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd29_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 3, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT 2
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
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
	SND_END
	db $FF

Snd27_Ch3:
	VOICE 8, 2, 2, 3, 8
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE F_, 1
	NOTE F_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE B_, 1
	RELEASE 7, $0A
	OCTAVE 2
	NOTE C_, $0F
	REST 1
	SND_END

Snd27_Ch1:
	VIBRATO 3
	VOICE 8, 4, 4, 2, $0F
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	RELEASE 7, $0A
	NOTE E_, $0F
	REST 1
	SND_END

Snd27_Ch2:
	VIBRATO 3
	VOICE 8, 8, 4, 5, $0A
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	RELEASE 3, $0D
	NOTE E_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	RELEASE 7, $0A
	OCTAVE 4
	NOTE C_, $0F
	REST 1
	SND_END

Snd27_Drm:
	SND_END

Snd28_Ch3:
	VOICE 1, 2, 2, 2, $0E
	SND_CALL Snd28_Ch3_5488
	NOTE D_, 8
	NOTE G_, 8
	NOTE E_, 8
	OCTAVE 4
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	SND_CALL Snd28_Ch3_5488
	NOTE D_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE E_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE A_, 8
	OCTAVE 4
	NOTE C_, 8
	SND_CALL Snd28_Ch3_54AB
	SND_CALL Snd28_Ch3_54D6
	SND_CALL Snd28_Ch3_54AB
	SND_CALL Snd28_Ch3_5502
	SND_CALL Snd28_Ch3
	db $FF
Snd28_Ch3_5488:
	VIBRATO 0
	VOICE 1, 2, 2, 4, $0F
	OCTAVE 4
	NOTE D_, 8
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 8
	NOTE G_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE F_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	SND_RET
Snd28_Ch3_54AB:
	VOICE 1, 2, 7, 8, 8
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE A_, 8
	VOICE 1, 2, 2, 4, $0F
	NOTE C_, 8
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 8
	NOTE G_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE F_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE D_, 8
	NOTE B_, 8
	NOTE E_, 8
	NOTE E_, 8
	VOICE 1, 2, 7, 8, 8
	NOTE A_, 8
	OCTAVE 4
	NOTE C_, 8
	SND_RET
Snd28_Ch3_54D6:
	VOICE 1, 2, 7, 8, 8
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	NOTE D_, 8
	VOICE 1, 2, 2, 4, $0F
	NOTE C_, 8
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 8
	NOTE G_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE F_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE D_, 8
	NOTE B_, 8
	NOTE E_, 8
	OCTAVE 4
	NOTE G_, 8
	VOICE 1, 2, 7, 8, 8
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 4
	NOTE C_, 8
	SND_RET
Snd28_Ch3_5502:
	VOICE 1, 2, 7, 8, 8
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	NOTE D_, 8
	VOICE 1, 2, 2, 4, $0F
	NOTE C_, 8
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 8
	NOTE G_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE F_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	TRANSPOSE_UP $0C
	VOICE 1, 2, 4, 3, $0F
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	TRANSPOSE_UP 0
	SND_RET

Snd28_Ch1:
	VOICE 1, 8, 8, 2, $0E
	SND_CALL Snd28_Ch1_556B
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE C_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE E_, $0A
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 6
	VIBRATO 0
	ATTEN 0
	SND_CALL Snd28_Ch1_556B
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 3
	NOTE E_, $0A
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE C_, 6
	VIBRATO 0
	ATTEN 0
	SND_CALL Snd28_Ch1_559E
	SND_CALL Snd28_Ch1_55D1
	SND_CALL Snd28_Ch1_559E
	SND_CALL Snd28_Ch1_5604
	SND_CALL Snd28_Ch1
	db $FF
Snd28_Ch1_556B:
	VIBRATO 0
	VOICE 1, 6, 8, 4, $0D
	OCTAVE 3
	NOTE F_, 8
	NOTE D_, 8
	NOTE E_, 8
	ATTEN 2
	VIBRATO $0E
	NOTE G_, $0A
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 6
	VIBRATO 0
	ATTEN 0
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 2
	NOTE B_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE B_, $0A
	NOTE G_, 8
	NOTE D_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE A_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE F_, $0A
	NOTE C_, 8
	NOTE G_, 6
	VIBRATO 0
	ATTEN 0
	SND_RET
Snd28_Ch1_559E:
	OCTAVE 3
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 2
	NOTE B_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE B_, $0A
	NOTE G_, 8
	NOTE D_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE A_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE F_, $0A
	NOTE C_, 8
	OCTAVE 3
	NOTE F_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE C_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE C_, 8
	SND_RET
Snd28_Ch1_55D1:
	OCTAVE 3
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE D_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 2
	NOTE B_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE B_, $0A
	NOTE G_, 8
	NOTE D_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE A_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE F_, $0A
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE C_, 8
	OCTAVE 4
	NOTE G_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE C_, 8
	SND_RET
Snd28_Ch1_5604:
	OCTAVE 3
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE D_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 2
	NOTE B_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE B_, $0A
	NOTE G_, 8
	NOTE D_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE A_, 8
	ATTEN 2
	VIBRATO $0E
	OCTAVE 4
	NOTE F_, $0A
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 6
	VIBRATO 0
	ATTEN 0
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE G_, 8
	SND_RET

Snd28_Ch2:
	PAN $0F
	AUTOPAN 2
	DUTY_STEP 0, 2
	VOICE 8, 8, 8, 1, $0F
	SND_CALL Snd28_Ch2_5669
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_CALL Snd28_Ch2_5669
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	RELEASE 4, $0D
	SND_CALL Snd28_Ch2_568F
	SND_CALL Snd28_Ch2_56A6
	SND_CALL Snd28_Ch2_568F
	SND_CALL Snd28_Ch2_56A6
	SND_CALL Snd28_Ch2
	db $FF
Snd28_Ch2_5669:
	VIBRATO 0
	VOICE 8, $0F, 8, 2, $0D
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_RET
Snd28_Ch2_568F:
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	SND_REPEAT 3
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	SND_RET
Snd28_Ch2_56A6:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT 3
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
	db $FF

Snd28_Drm:
	DRUM_UNIT 8
	SND_SEGNO
	DRUM $0B, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_REPEAT $F0
	SND_END

Snd2A_Ch2:
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5732
	SND_CALL Snd2A_Ch2_5732
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5708
	SND_CALL Snd2A_Ch2_5732
	SND_CALL Snd2A_Ch2_5732
	REST 8
	REST 8
	PAN $0F
	AUTOPAN 2
	SND_CALL Snd2A_Ch2_579A
	SND_CALL Snd2A_Ch2_579A
	SND_CALL Snd2A_Ch2_57D5
	PAN $FF
	AUTOPAN 0
	SND_CALL Snd2A_Ch2
Snd2A_Ch2_5708:
	DUTY_STEP 8, 1
	VOICE 7, 8, 4, 1, $0D
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	RELEASE $0F, 0
	NOTE A_, 2
	RELEASE 1, $0D
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd2A_Ch2_5732:
	DUTY_STEP 8, 1
	VIBRATO 3
	VOICE 7, 8, 4, 2, $0D
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 2
	PAN $0F
	NOTE E_, 1
	PAN $F0
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	RELEASE 7, 5
	NOTE D_, $0A
	RELEASE 2, $0D
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 2
	PAN $0F
	NOTE A_, 1
	PAN $F0
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 2
	PAN $0F
	NOTE G#, 1
	PAN $F0
	NOTE G#, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 2
	PAN $0F
	NOTE E_, 1
	PAN $F0
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	RELEASE 5, 5
	NOTE D_, $0A
	RELEASE 2, $0D
	ATTEN 3
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 2
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 0
	SND_RET
Snd2A_Ch2_579A:
	VOICE 7, $0F, 8, 1, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd2A_Ch2_57D5:
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_REPEAT 2
	SND_RET

Snd2A_Ch1:
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_585B
	SND_CALL Snd2A_Ch1_585B
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_5832
	SND_CALL Snd2A_Ch1_585B
	SND_CALL Snd2A_Ch1_585B
	REST 8
	REST 8
	SND_CALL Snd2A_Ch1_58B8
	SND_CALL Snd2A_Ch1
Snd2A_Ch1_5832:
	VIBRATO $0E
	VOICE 7, 2, 0, 2, 8
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	RELEASE $0F, 0
	NOTE A_, 2
	RELEASE 8, 8
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	SND_RET
Snd2A_Ch1_585B:
	VIBRATO $0E
	VOICE 7, 2, 8, 8, 8
	OCTAVE 4
	NOTE E_, 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 1
	PAN $0F
	NOTE E_, 1
	PAN $F0
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	RELEASE 7, 5
	NOTE D_, $0A
	RELEASE 2, $0D
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 1
	PAN $0F
	NOTE A_, 1
	PAN $F0
	NOTE A_, 1
	PAN $FF
	ATTEN 0
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 1
	PAN $0F
	NOTE G#, 1
	PAN $F0
	NOTE G#, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	ATTEN 1
	PAN $0F
	NOTE E_, 1
	PAN $F0
	NOTE E_, 1
	PAN $FF
	ATTEN 0
	NOTE D_, 7
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 2
	NOTE D_, 1
	SND_RET
Snd2A_Ch1_58B8:
	RELEASE $0F, 0
	OCTAVE 4
	NOTE C#, 8
	NOTE C#, 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, $0A
	OCTAVE 4
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 7
	NOTE C#, 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, $0A
	OCTAVE 4
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 3
	NOTE D_, 3
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 7
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 9
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 9
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE A_, $0A
	NOTE A_, 4
	NOTE G#, 3
	TRANSPOSE_UP 0
	SND_RET

Snd2A_Ch3:
	PAN $0F
	AUTOPAN 2
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	PAN $FF
	AUTOPAN 0
	SND_CALL Snd2A_Ch3_5970
	SND_CALL Snd2A_Ch3_5970
	PAN $0F
	AUTOPAN 2
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	SND_CALL Snd2A_Ch3_5948
	PAN $FF
	AUTOPAN 0
	SND_CALL Snd2A_Ch3_5970
	SND_CALL Snd2A_Ch3_5970
	REST 8
	REST 8
	SND_CALL Snd2A_Ch3_59BE
	SND_CALL Snd2A_Ch3
Snd2A_Ch3_5948:
	VOICE 7, 2, 2, 4, $0F
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	RELEASE $0F, 0
	NOTE A_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd2A_Ch3_5970:
	VOICE 7, 2, 6, 4, $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	RELEASE $0F, 0
	NOTE A_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
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
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_RET
Snd2A_Ch3_59BE:
	VIBRATO 3
	VOICE 7, 2, 9, $0F, 0
	OCTAVE 4
	NOTE C#, 7
	RELEASE 6, 5
	NOTE C#, 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 0
	OCTAVE 3
	NOTE B_, $0A
	RELEASE 6, 5
	OCTAVE 4
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0F, 0
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 7
	RELEASE 6, 5
	NOTE C#, 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 0
	OCTAVE 3
	NOTE B_, $0A
	RELEASE 6, 5
	OCTAVE 4
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 3
	NOTE D_, 3
	NOTE C#, 2
	RELEASE $0F, 0
	OCTAVE 3
	NOTE A_, 7
	RELEASE 8, 5
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0F, 0
	OCTAVE 3
	NOTE A_, 9
	RELEASE 8, 5
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0F, 0
	OCTAVE 3
	NOTE A_, 9
	RELEASE 8, 5
	NOTE A_, 1
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE 8, 5
	NOTE A_, $0A
	NOTE A_, 4
	NOTE G#, 4
	TRANSPOSE_UP 0
	SND_RET

Snd2A_Drm:
	DRUM_UNIT 7
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 1
	SND_REPEAT $F0
	SND_END

Snd2C_Ch2:
	TEMPO $00
	DUTY_STEP 0, 2
	VOICE 6, 8, 8, 3, $0E
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	SND_CALL Snd2C_Ch2

Snd2C_Ch1:
	VIBRATO $0E
	LEN_UNIT 1
	REST 6
	VOICE 6, 2, 8, 8, 8
	OCTAVE 3
	NOTE E_, 4
	NOTE G_, 1
	NOTE G#, 3
	NOTE F#, 6
	NOTE E_, 1
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 4
	LEN_UNIT 1
	NOTE A_, 6
	LEN_UNIT 6
	OCTAVE 4
	NOTE D_, 1
	PAN $F0
	NOTE A_, 1
	PAN $FF
	NOTE C#, 1
	PAN $0F
	NOTE G#, 1
	PAN $FF
	NOTE C_, 1
	PAN $F0
	NOTE G_, 1
	PAN $FF
	OCTAVE 3
	NOTE B_, 1
	PAN $0F
	OCTAVE 4
	NOTE F#, 1
	PAN $FF
	LEN_UNIT 1
	REST 6
	VOICE 6, 2, 8, 8, 8
	OCTAVE 3
	NOTE E_, 4
	NOTE G_, 1
	NOTE G#, 3
	NOTE F#, 6
	NOTE E_, 1
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 4
	LEN_UNIT 1
	NOTE A_, 6
	TRANSPOSE_DOWN 3
	VOICE 6, 5, 0, 2, $0D
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	TRANSPOSE_UP 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE F#, 5
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE E_, 5
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 2
	LEN_UNIT 1
	REST 6
	LEN_UNIT 6
	PAN $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	PAN $FF
	NOTE G_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	PAN $F0
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	PAN $FF
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 3
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 3
	NOTE A_, 1
	NOTE G#, 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	SND_CALL Snd2C_Ch1

Snd2C_Ch3:
	VOICE 6, 2, 4, 6, $0C
	OCTAVE 3
	NOTE E_, 4
	NOTE G_, 1
	NOTE G#, 3
	RELEASE 5, $0D
	NOTE F#, 6
	RELEASE 6, $0C
	NOTE E_, 1
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	OCTAVE 3
	RELEASE 5, $0D
	NOTE B_, 6
	RELEASE 6, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 4
	NOTE G_, 1
	NOTE G#, 3
	RELEASE 5, $0D
	NOTE F#, 6
	RELEASE 6, $0C
	NOTE E_, 1
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 4
	NOTE E_, 3
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	OCTAVE 3
	RELEASE 5, $0D
	NOTE B_, 6
	RELEASE 6, $0C
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	WAVE 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 5
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	WAVE 4
	SND_CALL Snd2C_Ch3

Snd2C_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 1, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 2
	SND_REPEAT $0C
	SND_CALL Snd2C_Drm

Snd2B_Ch2:
	VOICE 6, $0A, 4, 3, $0E
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D#, 2
	NOTE D_, 2
Snd2B_Ch2_5C76:
	VIBRATO 3
	TRANSPOSE_DOWN $0C
	TEMPO $00
	VOICE 6, $0A, 4, 4, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 2
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 8
	TRANSPOSE_UP 0
	RELEASE 5, 8
	SND_SEGNO
	OCTAVE 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 5
	NOTE D_, 3
	NOTE C_, 5
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 5
	NOTE A#, 3
	NOTE A_, 5
	NOTE A_, 3
	NOTE D_, 5
	NOTE D_, 3
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_REPEAT 2
	SND_CALL Snd2B_Ch2_5C76
	db $FF

Snd2B_Ch1:
	VOICE 6, 5, 8, 1, $0E
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 2
	NOTE F#, 2
Snd2B_Ch1_5CD0:
	TRANSPOSE_DOWN $0C
	VOICE 6, 6, 8, 4, $0E
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 8
	VIBRATO $0E
	TRANSPOSE_UP 0
	RELEASE 5, 8
	SND_SEGNO
	ATTEN 4
	OCTAVE 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 5
	NOTE D_, 3
	NOTE C_, 5
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 5
	NOTE A#, 3
	NOTE A_, 5
	NOTE A_, 3
	NOTE D_, 5
	NOTE D_, 3
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 2
	ATTEN 0
	SND_CALL Snd2B_Ch1_5CD0

Snd2B_Ch3:
	VOICE 6, 2, 6, 5, $0F
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
Snd2B_Ch3_5D25:
	VOICE 6, 2, 6, 4, $0E
	SND_SEGNO
	RELEASE $0F, 0
	OCTAVE 2
	NOTE G_, 1
	RELEASE 4, $0E
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 8
	SND_CALL Snd2B_Ch3_5D25

Snd2B_Drm:
	DRUM_UNIT 6
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
Snd2B_Drm_5D5D:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	SND_REPEAT 8
	SND_CALL Snd2B_Drm_5D5D

Snd2D_Ch2:
	DUTY_STEP 0, 2
	TRANSPOSE_UP 0
	VOICE 8, 8, 4, 1, $0F
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 5, $0F
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 1, $0F
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 8, 8
	NOTE F#, 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 5, $0F
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 1, $0F
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 8, 8
	NOTE F#, 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 5, $0F
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 1, $0F
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 8, 8
	NOTE F#, 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 5, $0F
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 1, $0F
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 8, 8
	NOTE F#, 2
	RELEASE 1, $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	RELEASE 5, $0F
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	SND_CALL Snd2D_Ch2

Snd2D_Ch1:
	DUTY_STEP 4, 2
	VIBRATO 1
	TRANSPOSE_UP 0
	VOICE 8, 2, 8, $0F, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	VOICE 8, 2, 8, $0F, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 0
	VOICE 8, 2, 8, $0F, 0
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	SND_CALL Snd2D_Ch1
	db $FF

Snd2D_Ch3:
	PAN $0F
	AUTOPAN 2
	TRANSPOSE_UP 0
	VOICE 8, 2, 2, 5, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	VOICE 8, 2, 2, 5, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 0
	VOICE 8, 2, 2, 5, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT 2
	TRANSPOSE_UP 3
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	TRANSPOSE_UP 0
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	SND_CALL Snd2D_Ch3
	db $FF

Snd2D_Drm:
	DRUM_UNIT 8
	SND_SEGNO
	DRUM_UNIT 4
	DRUM 1, 1
	DRUM 2, 1
	DRUM_UNIT 8
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT 2
	SND_CALL Snd2D_Drm
	db $FF

Snd2E_Ch2:
	TEMPO $00
	VOICE 6, 8, 8, 2, $0E
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
	OCTAVE 3
	NOTE C_, 1
	REST 8
	SND_REPEAT 2
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
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 8
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
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 4
	LEN_UNIT 1
	RELEASE 5, $0D
	OCTAVE 3
	NOTE G_, 6
	NOTE F#, 3
	NOTE E_, 3
	PAN $0F
	NOTE D_, 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 3
	PAN $FF
	LEN_UNIT 6
	SND_SEGNO
	RELEASE 2, $0E
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
	OCTAVE 3
	NOTE C_, 1
	REST 8
	SND_REPEAT 2
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
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 8
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
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	REST 4
	LEN_UNIT 1
	RELEASE 5, $0D
	OCTAVE 3
	NOTE G_, 6
	NOTE F#, 3
	NOTE E_, 3
	PAN $F0
	NOTE D_, 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 3
	PAN $FF
	LEN_UNIT 3
	RELEASE 2, $0E
	OCTAVE 3
	NOTE E_, $0A
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, $0C
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 2
	NOTE A_, $0A
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, $0C
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, $0C
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 6
	NOTE B_, 2
	NOTE A_, 6
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	PAN $0F
	REST 2
	NOTE G_, 2
	PAN $F0
	REST 2
	NOTE G_, 2
	PAN $FF
	SND_CALL Snd2E_Ch2

Snd2E_Ch1:
	TRANSPOSE_UP 0
	VIBRATO 4
	VOICE 6, 6, 4, 2, $0E
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	SND_REPEAT 2
	LEN_UNIT 3
	OCTAVE 3
	NOTE C_, $0A
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, $0C
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F_, $0A
	NOTE F_, 4
	NOTE F_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, $0C
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, $0C
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F_, 6
	NOTE F_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE B_, 2
	REST 8
	SND_CALL Snd2E_Ch1

Snd2E_Ch3:
	TRANSPOSE_UP $0C
	VOICE 6, 2, $0E, 3, $0C
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	NOTE F_, 1
	RELEASE 4, $0D
	NOTE E_, 2
	SND_REPEAT 2
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 2
	NOTE G_, 1
	RELEASE 4, $0D
	NOTE F#, 2
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	REST 4
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 2
	NOTE F_, 1
	RELEASE 4, $0D
	NOTE E_, 2
	SND_REPEAT 2
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 2
	NOTE G_, 1
	RELEASE 4, $0D
	NOTE F#, 2
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	REST 4
	TRANSPOSE_UP 0
	WAVE 8
	RELEASE 5, $0E
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_REPEAT 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_CALL Snd2E_Ch3

Snd2E_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	SND_REPEAT 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 9, 2
	SND_REPEAT 4
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd2E_Drm

Snd2F_Ch2:
	TEMPO $00
	VOICE 6, 8, 4, 3, $0E
Snd2F_Ch2_61E1:
	VOICE 6, 8, 4, 3, $0E
	RELEASE 3, $0E
	SND_CALL Snd2F_Ch2_61FC
	SND_CALL Snd2F_Ch2_622B
	SND_CALL Snd2F_Ch2_622B
	SND_CALL Snd2F_Ch2_61FC
	SND_CALL Snd2F_Ch2_622B
	SND_CALL Snd2F_Ch2_622B
	SND_CALL Snd2F_Ch2_61E1
Snd2F_Ch2_61FC:
	ATTEN 2
	TRANSPOSE_DOWN $0C
	RELEASE 3, $0E
	OCTAVE 2
	NOTE E_, 5
	NOTE D_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 3
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE D_, 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	ATTEN 0
	SND_RET
Snd2F_Ch2_622B:
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	DUTY_STEP 0, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	DUTY_STEP 0, 0
	NOTE E_, 1
	NOTE G_, 1
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	DUTY_STEP 4, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_RET

; Unreferenced music subroutines.
Orphan_6270:
	TRANSPOSE_UP 0
	PAN $0F
	AUTOPAN 2
	VOICE 6, $0F, 8, 2, $0E
	RELEASE $0F, 0
	OCTAVE 2
	NOTE F#, 7
	RELEASE 4, $0E
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 4
	OCTAVE 2
	NOTE C#, 1
	NOTE F#, 1
	RELEASE $0F, 0
	NOTE D_, 7
	RELEASE 4, $0E
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D#, 1
	RELEASE $0F, 0
	NOTE E_, 7
	RELEASE 4, $0E
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE E_, 4
	NOTE A_, 1
	NOTE B_, 1
	RELEASE $0F, 0
	OCTAVE 2
	NOTE C_, 6
	RELEASE 4, $0E
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	RELEASE 6, $0C
	NOTE G_, 8
	RELEASE $0F, 0
	OCTAVE 2
	NOTE F#, 7
	RELEASE 4, $0E
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 4
	NOTE F#, 2
	RELEASE $0F, 0
	OCTAVE 2
	NOTE D_, 7
	RELEASE 4, $0E
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D#, 1
	RELEASE $0F, 0
	NOTE E_, 7
	RELEASE 4, $0E
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE E_, 4
	NOTE A_, 1
	NOTE B_, 1
	RELEASE $0F, 0
	OCTAVE 2
	NOTE C_, 6
	RELEASE 4, $0E
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE G_, 6
	RELEASE 4, $0E
	NOTE G_, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE A#, 6
	RELEASE 4, $0E
	NOTE A_, 1
	NOTE G_, 1
	RELEASE $0F, 0
	NOTE F_, 8
	PAN $FF
	AUTOPAN 0
	SND_RET

Snd2F_Ch1:
	VIBRATO $0E
	TEMPO $00
	VOICE 6, 2, 8, 5, 8
	REST 1
Snd2F_Ch1_6303:
	SND_CALL Snd2F_Ch1_6318
	SND_CALL Snd2F_Ch1_6345
	SND_CALL Snd2F_Ch1_6345
	SND_CALL Snd2F_Ch1_6318
	SND_CALL Snd2F_Ch1_6345
	SND_CALL Snd2F_Ch1_6345
	SND_CALL Snd2F_Ch1_6303
Snd2F_Ch1_6318:
	TRANSPOSE_DOWN $0C
	RELEASE 5, 8
	OCTAVE 2
	NOTE E_, 5
	NOTE D_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 3
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE D_, 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Snd2F_Ch1_6345:
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Orphan_637E:
	TRANSPOSE_DOWN $0C
	DUTY_STEP 0, 0
	RELEASE $0F, 0
	RELEASE 7, $0E
	OCTAVE 4
	NOTE F#, 6
	REST 4
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE E_, 9
	REST 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 4
	NOTE F#, 6
	REST 4
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE E_, 9
	REST 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE F_, 4
	NOTE F_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 4
	TRANSPOSE_UP 0
	SND_RET
	db $FF

Snd2F_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE 6, 2, 1, 4, 8
Snd2F_Ch3_63BB:
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63D0
	SND_CALL Snd2F_Ch3_63BB
Snd2F_Ch3_63D0:
	RELEASE 4, $0E
	OCTAVE 2
	NOTE E_, 5
	NOTE D_, 2
	NOTE E_, 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 5
	NOTE E_, 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 4
	NOTE D_, 3
	NOTE F#, 2
	NOTE D_, 1
	NOTE E_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE D_, 3
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Orphan_63FB:
	PAN $FF
	AUTOPAN 0
	WAVE 2
	TRANSPOSE_DOWN $0C
	VIBRATO 3
	DUTY_STEP 0, 0
	RELEASE $0F, 0
	OCTAVE 4
	NOTE F#, 6
	ATTEN 5
	NOTE F#, 4
	ATTEN 0
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE E_, 9
	ATTEN 5
	NOTE E_, 3
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 4
	NOTE F#, 6
	ATTEN 5
	NOTE F#, 4
	ATTEN 0
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 6
	NOTE A_, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE E_, 9
	ATTEN 5
	NOTE E_, 3
	ATTEN 0
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 6
	NOTE G_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE F_, 4
	NOTE F_, 2
	NOTE E_, 4
	NOTE D_, 2
	NOTE C_, 4
	WAVE 4
	TRANSPOSE_UP 0
	PAN $0F
	AUTOPAN 2
	SND_RET

Snd2F_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	SND_REPEAT 4
	SND_CALL Snd2F_Drm

Snd31_Ch2:
	TEMPO $40
	VOICE 6, 7, 8, 6, $0D
	SND_SEGNO
	OCTAVE 1
	NOTE D#, 4
	OCTAVE 2
	NOTE D#, 4
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE D#, 2
	SND_REPEAT 3
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	REST 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	VIBRATO 3
	TRANSPOSE_DOWN $0C
	VOICE 6, 9, 8, 7, $0F
	OCTAVE 4
	NOTE G_, 8
	LEN_UNIT 2
	NOTE D#, 8
	NOTE F_, 8
	NOTE G_, 8
	LEN_UNIT 6
	RELEASE 5, $0A
	NOTE A#, $0A
	OCTAVE 5
	NOTE C_, 4
	RELEASE 3, $0E
	OCTAVE 4
	NOTE A#, 2
	RELEASE 7, $0F
	NOTE A#, 6
	NOTE G#, 1
	NOTE G_, 1
	RELEASE 5, $0A
	NOTE G#, $0C
	RELEASE 7, $0F
	NOTE D#, 8
	NOTE F_, 4
	NOTE G_, 8
	LEN_UNIT 2
	NOTE G_, 8
	NOTE G#, 8
	NOTE A#, 8
	LEN_UNIT 6
	RELEASE 5, $0A
	OCTAVE 5
	NOTE D#, $0A
	RELEASE 7, $0F
	OCTAVE 4
	NOTE D#, 4
	NOTE F_, 2
	RELEASE 7, $0A
	NOTE G_, $0E
	RELEASE 3, $0E
	NOTE G#, 1
	NOTE G_, 1
	RELEASE 7, $0F
	NOTE G_, 4
	NOTE F_, 4
	LEN_UNIT 2
	NOTE F_, 8
	NOTE D#, 8
	NOTE D_, 8
	LEN_UNIT 6
	RELEASE 5, $0A
	NOTE D#, $0A
	RELEASE 7, $0F
	NOTE F_, 4
	RELEASE 3, $0E
	NOTE G_, 2
	RELEASE 5, $0A
	NOTE G_, 8
	LEN_UNIT 2
	RELEASE 7, $0F
	NOTE F_, 8
	NOTE D#, 8
	NOTE D_, 8
	LEN_UNIT 6
	RELEASE 5, $0A
	NOTE D#, $0A
	RELEASE 7, $0F
	NOTE C_, 2
	NOTE D#, 2
	NOTE G_, 2
	RELEASE 5, $0A
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	OCTAVE 5
	NOTE D#, 4
	NOTE D_, $0A
	RELEASE 7, $0F
	OCTAVE 4
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 4
	RELEASE 7, $0A
	NOTE C_, $0E
	RELEASE 7, $0F
	OCTAVE 4
	NOTE A#, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE A#, 8
	DUTY 4
	ATTEN 5
	RELEASE 7, $0F
	OCTAVE 4
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE D#, 1
	VIBRATO 3
	TRANSPOSE_UP 0
	DUTY 8
	RELEASE 5, $0A
	OCTAVE 3
	NOTE A#, 8
	OCTAVE 4
	NOTE C_, 8
	RELEASE 7, $0F
	NOTE D_, 4
	NOTE D#, 4
	LEN_UNIT 2
	NOTE F_, 8
	NOTE G_, 8
	NOTE G#, 8
	LEN_UNIT 6
	RELEASE 7, $0A
	NOTE A#, 6
	LEN_UNIT 1
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN_UNIT 6
	RELEASE 5, $0A
	NOTE D#, $0A
	RELEASE 7, $0F
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 2
	RELEASE 7, $0A
	OCTAVE 4
	NOTE G#, 6
	LEN_UNIT 1
	NOTE F#, 4
	NOTE F_, 4
	NOTE D#, 4
	LEN_UNIT 6
	RELEASE 5, $0A
	NOTE C#, $0A
	RELEASE 7, $0F
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE A#, 2
	RELEASE 7, $0A
	NOTE G#, $0E
	NOTE G_, 1
	NOTE F_, 1
	RELEASE $0F, 0
	NOTE G_, 8
	RELEASE 7, $0F
	NOTE G_, 8
	RELEASE 5, $0A
	OCTAVE 4
	NOTE D#, $0A
	RELEASE 7, $0F
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	NOTE B_, 2
	RELEASE 5, $0A
	OCTAVE 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A#, 8
	OCTAVE 5
	NOTE D#, $0C
	RELEASE 7, $0F
	OCTAVE 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE F_, 4
	RELEASE $0F, 0
	NOTE G_, 8
	RELEASE 7, $0A
	NOTE G_, $0A
	RELEASE 4, $0E
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	RELEASE $0F, 0
	NOTE G_, $0C
	RELEASE 5, $0A
	NOTE G_, $0C
	RELEASE 7, $0F
	NOTE F_, 8
	TEMPO $40
	RELEASE 7, $0A
	NOTE D#, $0A
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	TEMPO $50
	NOTE B_, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE F_, 4
	TEMPO $90
	RELEASE 7, 6
	NOTE G_, 5
	RELEASE 6, $0C
	ATTEN 3
	NOTE G_, $0F
	SND_END
	db $FF

Snd31_Ch1:
	VIBRATO $0E
	LEN_UNIT 1
	REST 3
	VOICE 6, 4, $0C, 7, 7
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 4
	NOTE D#, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE G#, 2
	NOTE D#, 2
	LEN_UNIT 1
	NOTE C_, 9
	VOICE 6, 5, $0C, 4, $0D
	DUTY_STEP 0, 1
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	SND_REPEAT 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 4
	NOTE D#, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 2
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A_, 2
	ATTEN 2
	OCTAVE 4
	ATTEN 0
	NOTE C_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D_, 2
	PAN $0F
	RELEASE 7, $0A
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	PAN $F0
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	PAN $FF
	RELEASE 4, $0D
	OCTAVE 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN_UNIT 1
	NOTE A#, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE F_, 8
	NOTE A#, 8
	NOTE F_, 8
	NOTE D_, 8
	LEN_UNIT 6
	OCTAVE 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	LEN_UNIT 1
	NOTE A#, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 3
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE D#, 8
	NOTE D_, 8
	NOTE D#, 8
	NOTE F#, 8
	LEN_UNIT 6
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 2
	NOTE A#, 2
	LEN_UNIT 1
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE F#, 8
	NOTE C#, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE G_, 8
	NOTE G#, 8
	OCTAVE 3
	NOTE C#, 8
	NOTE F_, 8
	NOTE G#, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE C#, 8
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 8
	OCTAVE 3
	NOTE C#, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE E_, 8
	LEN_UNIT 6
	NOTE G#, 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE G#, 2
	LEN_UNIT 1
	OCTAVE 3
	NOTE C#, 8
	NOTE G#, 8
	NOTE E_, 8
	NOTE D#, 8
	NOTE C#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE G#, 8
	NOTE D#, 8
	NOTE G#, 8
	NOTE A#, 8
	OCTAVE 3
	NOTE C#, 8
	NOTE D#, 8
	NOTE G#, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE D#, 8
	NOTE C#, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE G_, 8
	NOTE D#, 8
	NOTE C#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE G_, 8
	NOTE A#, 8
	LEN_UNIT 6
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	LEN_UNIT 1
	OCTAVE 3
	NOTE B_, 8
	NOTE F#, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE B_, 8
	NOTE F#, 8
	NOTE D#, 8
	NOTE G#, 8
	NOTE B_, 8
	OCTAVE 3
	NOTE D#, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE G#, 8
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE G#, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE G#, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE D#, 8
	NOTE G#, 8
	NOTE D#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE G#, 8
	NOTE A#, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE G_, 8
	NOTE A#, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE A#, 8
	NOTE D#, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE G_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE D#, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 3
	NOTE C_, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE F_, 8
	NOTE G#, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE F_, 8
	NOTE G#, 8
	NOTE F_, 8
	NOTE G#, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE F_, 8
	LEN_UNIT 6
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	LEN_UNIT 1
	RELEASE 5, $0D
	OCTAVE 3
	NOTE A#, 8
	NOTE G_, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE G_, 8
	NOTE D#, 8
	NOTE G_, 8
	NOTE A#, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE G_, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE G#, 8
	NOTE F_, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE F_, 8
	NOTE G#, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE F_, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE D#, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE D#, 8
	LEN_UNIT 6
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	LEN_UNIT 1
	NOTE B_, 8
	NOTE G#, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE G#, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE D#, 8
	NOTE G#, 8
	NOTE D#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE G#, 8
	LEN_UNIT 6
	RELEASE $0F, 0
	OCTAVE 2
	NOTE A#, $0A
	RELEASE 5, $0C
	ATTEN 3
	NOTE A#, 5
	SND_END
	db $FF

Snd31_Ch3:
	VOICE 6, 2, 4, 6, $0A
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 4
	NOTE D#, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE G#, 2
	NOTE D#, 2
	NOTE C_, 2
	WAVE $0F
	RELEASE 7, 8
	OCTAVE 2
	NOTE D#, 4
	NOTE D#, 8
	NOTE D#, 4
	NOTE C#, 4
	NOTE C#, 8
	NOTE C#, 4
	NOTE C_, 4
	NOTE C_, 8
	OCTAVE 1
	NOTE G#, 4
	NOTE B_, 4
	NOTE B_, 8
	NOTE G#, 4
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 1
	NOTE A#, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 1
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 1
	NOTE A#, 8
	NOTE B_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE G_, 4
	OCTAVE 2
	NOTE D_, 4
	NOTE D#, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE F_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE F_, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 2
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 4
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE F_, 4
	OCTAVE 1
	NOTE A#, 4
	SND_SEGNO
	RELEASE 7, 7
	OCTAVE 1
	NOTE G#, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE D_, 4
	PAN $F0
	NOTE F_, 4
	PAN $FF
	OCTAVE 1
	NOTE G#, 4
	SND_REPEAT 2
	RELEASE 7, 7
	NOTE G_, 4
	RELEASE 7, $0A
	NOTE A#, 4
	PAN $0F
	OCTAVE 2
	NOTE D#, 4
	PAN $FF
	OCTAVE 1
	NOTE G_, 4
	RELEASE 7, 7
	NOTE F#, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE D#, 4
	PAN $F0
	NOTE F#, 4
	PAN $FF
	OCTAVE 1
	NOTE F#, 4
	RELEASE 7, 7
	NOTE F_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE C#, 4
	PAN $0F
	NOTE F_, 4
	PAN $FF
	OCTAVE 1
	NOTE F_, 4
	RELEASE 7, 7
	NOTE E_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE C#, 4
	PAN $F0
	NOTE E_, 4
	PAN $FF
	OCTAVE 1
	NOTE E_, 4
	RELEASE 7, 7
	NOTE D#, 4
	RELEASE 7, $0A
	NOTE A#, 4
	PAN $0F
	OCTAVE 2
	NOTE D#, 4
	PAN $FF
	OCTAVE 1
	NOTE A#, 4
	OCTAVE 2
	NOTE D#, 4
	OCTAVE 1
	NOTE A#, 4
	NOTE D#, 4
	PAN $0F
	OCTAVE 2
	NOTE C#, 4
	PAN $FF
	RELEASE 7, 7
	OCTAVE 1
	NOTE B_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE F#, 4
	PAN $F0
	NOTE B_, 4
	PAN $FF
	OCTAVE 1
	NOTE A#, 4
	RELEASE 7, 7
	NOTE G#, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE D#, 4
	PAN $0F
	NOTE G#, 4
	PAN $FF
	OCTAVE 1
	NOTE G#, 4
	RELEASE 7, 7
	NOTE G_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE D#, 4
	PAN $F0
	NOTE G_, 4
	PAN $FF
	NOTE D#, 4
	RELEASE 7, 7
	NOTE C_, 4
	RELEASE 7, $0A
	OCTAVE 1
	NOTE G_, 4
	NOTE C_, 4
	PAN $0F
	OCTAVE 2
	NOTE C_, 4
	PAN $FF
	RELEASE 7, 7
	OCTAVE 1
	NOTE F_, 4
	RELEASE 7, $0A
	OCTAVE 2
	NOTE C_, 4
	NOTE F_, 4
	OCTAVE 1
	NOTE F_, 4
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 1
	NOTE F_, 4
	NOTE G#, 4
	NOTE A_, 4
	RELEASE 0, 0
	NOTE A#, 8
	NOTE A#, 8
	RELEASE 6, $0A
	NOTE A#, 8
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 1
	NOTE A#, 4
	RELEASE 7, 8
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 1
	NOTE G#, 4
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 4
	OCTAVE 1
	NOTE G#, 4
	RELEASE 7, 6
	NOTE D#, $0F
	SND_END
	db $FF

Snd31_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 1, 4
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 4
	DRUM 8, 4
	SND_REPEAT 4
	SND_SEGNO
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 2, 2
	SND_REPEAT $0F
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 1, 2
	SND_REPEAT $0F
	SND_END
	db $FF

Snd30_Ch2:
	VIBRATO 3
	VOICE 1, 3, 8, $0F, 0
	TRANSPOSE_DOWN 6
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	TRANSPOSE_DOWN 8
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT 5
Snd30_Ch2_6981:
	TRANSPOSE_UP 0
	VOICE 7, 8, 4, 5, $0F
	SND_SEGNO
	RELEASE 5, $0F
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	RELEASE $0F, 0
	NOTE G_, 3
	RELEASE 5, $0F
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_REPEAT 3
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	RELEASE $0F, 0
	NOTE G_, 3
	RELEASE 3, $0F
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	RELEASE $0F, 0
	TRANSPOSE_UP 0
	DUTY 8
	DUTY_STEP 0, 2
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	LEN_UNIT 1
	NOTE G_, 3
	NOTE G#, 4
	LEN_UNIT 7
	NOTE G#, 3
	NOTE E_, 3
	NOTE D_, 8
	RELEASE 3, $0F
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	RELEASE $0F, 0
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	LEN_UNIT 1
	NOTE G_, 3
	NOTE G#, 4
	LEN_UNIT 7
	NOTE G#, 3
	NOTE E_, 3
	NOTE D_, 8
	RELEASE 3, $0F
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 2
	RELEASE $0F, 0
	SND_REPEAT 2
	SND_CALL Snd30_Ch2_6981
	db $FF

Snd30_Ch1:
	VIBRATO $0E
	VOICE $0E, 8, 4, 5, $0F
	REST 3
	VOICE 7, 8, 8, 5, $0F
	REST 3
Snd30_Ch1_6A19:
	VOICE 7, 2, 8, $0F, 0
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE G_, 3
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_REPEAT 3
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	RELEASE $0F, 0
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE E_, 3
	NOTE D_, 8
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 3
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE E_, 3
	NOTE D_, 8
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 2
	SND_REPEAT 2
	SND_CALL Snd30_Ch1_6A19
	db $FF

Snd30_Ch3:
	VOICE $0E, 2, 2, 5, $0F
	REST 3
Snd30_Ch3_6A84:
	VOICE 7, 4, 6, 5, $0F
	SND_SEGNO
	RELEASE 5, $0A
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	RELEASE $0F, 0
	NOTE G_, 3
	RELEASE 5, $0A
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_REPEAT 3
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	RELEASE $0F, 0
	NOTE G_, 3
	RELEASE 8, $0A
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	SND_CALL Snd30_Ch3_6A84

Snd30_Drm:
	DRUM_UNIT 1
	DRUM 8, 4
	DRUM 8, 3
	DRUM_UNIT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM_UNIT 7
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	SND_REPEAT $F0
	SND_END
	db $FF

Snd32_Ch3:
	TEMPO $40
	AUTOPAN 2
	PAN $0F
	TRANSPOSE_UP 0
	VOICE 4, 2, 2, 5, 6
	SND_SEGNO
	RELEASE 5, 6
	OCTAVE 2
	NOTE G_, 4
	RELEASE 3, $0D
	NOTE B_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 5, 6
	OCTAVE 2
	NOTE D_, 4
	RELEASE 3, $0D
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE D_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 5, 6
	OCTAVE 2
	NOTE G_, 4
	RELEASE 3, $0D
	NOTE B_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	SND_REPEAT 2
	RELEASE 5, 6
	NOTE C_, 4
	RELEASE 3, $0D
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 5, 6
	NOTE D_, 4
	RELEASE 3, $0D
	NOTE A_, 4
	NOTE F#, 4
	RELEASE 3, $0D
	NOTE G_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 4
	RELEASE $0D, 7
	NOTE G_, 4
	RELEASE 1, $0D
	OCTAVE 2
	NOTE G_, 4
	REST 4
	SND_END

Snd32_Ch1:
	VIBRATO $0E
	VOICE 4, 3, 8, $0F, 0
	ATTEN 2
	OCTAVE 3
	NOTE B_, 4
	ATTEN 0
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	ATTEN 2
	RELEASE $0F, 0
	OCTAVE 4
	NOTE D_, 4
	ATTEN 0
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	ATTEN 2
	RELEASE $0F, 0
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE D_, 4
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	OCTAVE 1
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	SND_REPEAT 2
	ATTEN 2
	RELEASE $0F, 0
	NOTE B_, 4
	ATTEN 0
	RELEASE 2, 8
	NOTE D_, 4
	NOTE D_, 4
	ATTEN 2
	RELEASE $0F, 0
	OCTAVE 4
	NOTE D_, 4
	ATTEN 0
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	ATTEN 2
	RELEASE $0F, 0
	OCTAVE 4
	NOTE A_, 4
	ATTEN 0
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	REST 4
	RELEASE 2, 8
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 6
	NOTE B_, 2
	NOTE B_, 4
	NOTE B_, 4
	REST 8
	SND_END

Snd32_Ch2:
	TRANSPOSE_DOWN $0C
	VIBRATO 3
	VOICE 4, 8, 8, $0F, 0
	ATTEN 2
	OCTAVE 4
	NOTE B_, $0C
	OCTAVE 5
	ATTEN 1
	NOTE D_, $0C
	ATTEN 0
	NOTE A_, 6
	RELEASE $0F, 0
	NOTE G_, 2
	NOTE D_, 6
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	ATTEN 3
	OCTAVE 4
	NOTE B_, 4
	ATTEN 2
	OCTAVE 5
	NOTE D_, 4
	ATTEN 5
	NOTE D_, 4
	ATTEN 2
	NOTE C_, 4
	ATTEN 1
	OCTAVE 4
	NOTE B_, 4
	ATTEN 5
	NOTE B_, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 1
	NOTE B_, 4
	ATTEN 5
	NOTE B_, 4
	ATTEN 2
	OCTAVE 5
	NOTE C_, 4
	ATTEN 1
	NOTE C#, 4
	ATTEN 5
	NOTE C#, 4
	ATTEN 0
	NOTE E_, 4
	ATTEN 2
	NOTE D_, 4
	RELEASE $0F, 0
	ATTEN 2
	OCTAVE 4
	NOTE B_, $0C
	OCTAVE 5
	ATTEN 1
	NOTE D_, $0C
	ATTEN 0
	NOTE A_, 6
	RELEASE $0F, 0
	NOTE G_, 2
	NOTE D_, 6
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	ATTEN 2
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 4
	ATTEN 1
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	ATTEN 0
	NOTE F#, 4
	NOTE D_, 4
	NOTE G_, 6
	RELEASE 1, 8
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	SND_END

Snd32_Drm:
	SND_END
	db $FF

Snd33_Ch2:
	VOICE 6, 0, 8, 6, $0D
	OCTAVE 1
	SND_END

Snd33_Ch1:
	VOICE 6, 0, 8, 6, $0D
	OCTAVE 1
	SND_END

Snd33_Ch3:
	VOICE 6, 6, 2, 6, $0D
	OCTAVE 1
	SND_END

Snd33_Drm:
	DRUM_UNIT 6
	SND_END
