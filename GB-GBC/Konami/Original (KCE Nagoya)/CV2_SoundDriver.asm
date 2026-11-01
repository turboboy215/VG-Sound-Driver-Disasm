; ==========================================================================
; Castlevania II - Belmont's Revenge (U) - Konami sound driver (later GB version)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0 $0028 rst $28, $3537-$35C6 VBlank update call, far wrappers, bank helpers
;   bank 7 $4000-$7FFF driver code, tables, sound data
; Build: rgbasm -Wall -o cv2.o CV2_SoundDriver.asm && rgblink -o cv2.gb cv2.o
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
DEF wSndLock EQU $C885
DEF wPauseFlags EQU $C88B
DEF wStage EQU $C8C0
DEF wStageMusicOvr EQU $C8CE
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
DEF TRK_PAN EQU $B5

; track flags (TRK_FLAGS)
DEF TF_RELEASED EQU 0
DEF TF_AUTOPAN EQU 1
DEF TF_VIBNEG EQU 3
DEF TF_DUTYSTEP EQU 4
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
; $ED xy (new here): duty step. Each note starts with duty \1 for \2 ticks, then the voice duty
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
ENDM

SECTION "rst28", ROM0[$0028]

; rst $28: HL += A.
AddAToHL:
	add a, l
	ld l, a
	ret nc
	inc h
	ret

SECTION "Sound glue", ROM0[$3537]

; SndUpdateFar: called from the VBlank handler (after ei) on every frame. Skipped
; (tick lost) while the main thread is inside PlaySoundFar (wSndLock).
SndUpdateFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld a, [hBankId]
	push af
	call SetBank7
	call SndUpdate
.l3549:
	pop af
	ld [rROMB], a
	ld hl, wSndLock
	res 0, [hl]
	ret

; PlaySoundFar: A = sound id. Dropped if wSndLock is already held (a request
; from an interrupt during the update). Restores the caller's bank via hBankId.
PlaySoundFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld b, a
	ld a, [hBankId]
	push af
	call SetBank7
	ld a, b
	call PlaySound
	jp SndUpdateFar.l3549

; Game: stage music from StageMusicTable[wStage] (or $5F instead of $5E when
; wStageMusicOvr is set). Not driver code.
PlayStageMusic:
	ld a, [wStageMusicOvr]
	or a
	jr nz, .l357B
	ld a, [wStage]
	ld hl, StageMusicTable
	rst $28
	ld a, [hl]
	jp PlaySoundFar
.l357B:
	cp $5E
	jp nz, PlaySoundFar
	ld a, $5F
	jp PlaySoundFar
StageMusicTable:
	db $56, $56, $5B, $5C, $60, $62, $5D, $67

; StartFadeFar: A = sound to start when the fade-out ends (0 = none).
StartFadeFar:
	ld hl, wSndLock
	bit 0, [hl]
	ret nz
	set 0, [hl]
	ld b, a
	ld a, [hBankId]
	push af
	call SetBank7
	ld a, b
	call StartFade
	jp SndUpdateFar.l3549

StopSoundFar:
	ld a, $00
	jp PlaySoundFar

; Bank helpers (no bank shadow in RAM; hBankId tells the current bank).
SetBank1:
	ld a, $01
	ld [rROMB], a
	ret

SetBank2:
	ld a, $02
	ld [rROMB], a
	ret

SetBank6:
	ld a, $06
	ld [rROMB], a
	ret

SetBank7:
	ld a, $07
	ld [rROMB], a
	ret

SetBank3:
	ld a, $03
	ld [rROMB], a
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

; SndInit: NR52 = NR51 = $FF, NR50 = $77 (the game then calls StopSound).
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

; 85 periods: the same values as the earlier 96-entry table, cut after B-6.
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

; Each mask bit starts one track if the new priority >= that track's priority
; (else wReqRefused = 1, and a later accepted track clears it again). The check
; after Sfx1 and after Sfx2/SfxN aborts the rest of the request (and skips the
; NR51 write) when the flag is set. The flag is never cleared by a new request,
; so a music track refused at the end of one request makes the next request
; abort at the first check.
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
; its tracks is active. Not while paused or wMusicHold.
SndUnpause:
	ld a, [wPauseFlags]
	ld b, a
	ld a, [wMusicHold]
	or b
	bit 0, a
	ret nz
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l427C
	ld hl, wShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l427C:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l4291
	ld hl, wShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l4291:
	ld a, [wTrkCh3]
	or a
	jr z, .l42A2
	ld hl, wShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l42A2:
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

; FadeTick: while wFadeReq bit 7 is set, wFadeLevel goes up by one every 32
; ticks. Every new note is wFadeLevel quieter (CH3: half). At level 5 the
; requested sound (bits 0-6) is queued and the fade cleared. With 0 nothing is
; queued, so the music jumps back to full volume. Frozen while paused.
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
	and $1F
	ret nz
	ld hl, wFadeLevel
	inc [hl]
	ld a, [hl]
	cp $05
	ret nz
	ld a, [wFadeReq]
	res 7, a
	ld [wQueuedSnd], a
	xor a
	ld [hl], a
	ld [wFadeReq], a
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

; SndUpdate: one driver tick (VBlank, 59.7 Hz). Tracks 0-2 (SFX) run every tick,
; tracks 3-6 (music) are skipped on tempo-skip ticks (or while wMusicHold != 0,
; which nothing sets). While paused (wPauseFlags bit 0) only track 1 runs, and
; only for sound $06. Finally a sound in wQueuedSnd (fade target) is started.
SndUpdate:
	call FadeTick
	call TempoTick
	xor a
.l42FD:
	ld [wTrackIdx], a
	ld a, [wPauseFlags]
	bit 0, a
	jr z, .l4317
	ld a, [wTrackIdx]
	cp $01
	jr nz, SndUpdateNext
	ld a, [wTrkSfx2]
	cp $06
	jr z, SndUpdateRun
	jr SndUpdateDone
.l4317:
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
	jr z, SndUpdateNext
	call TrackTick

SndUpdateNext:
	ld a, [wTrackIdx]
	inc a
	cp $07
	jr nz, SndUpdate.l42FD

SndUpdateDone:
	ld a, [wQueuedSnd]
	or a
	ret z
	ld b, a
	xor a
	ld [wQueuedSnd], a
	ld a, b
	jp PlaySound

; TrackTick: one tick for track wTrackIdx (H = its page). With TF_DUTYSTEP the
; voice duty is restored after TRK_DUTYTICKS ticks of a note.
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
	ld l, TRK_LEN
	ld b, [hl]
	ld l, TRK_RELTICK
	ld a, [hl]
	sub b
	jr c, .l43A4
	ld l, TRK_FLAGS
	set 0, [hl]
.l43A4:
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
; after the release point (the attenuation is counted twice, as in Nemesis).
Ch3Decay:
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret z
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l4402
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
	jr z, .l4402
	inc a
	and $03
	ld [hl], a
	jr z, .l4402
	ld l, TRK_ATTEN
	add a, [hl]
	cp $04
	jr c, .l4402
	xor a
.l4402:
	rla
	swap a
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	jp WriteReg

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
	jr z, .l4470
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l447A
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l4470:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr ReadCmds
.l447A:
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
	ld a, $00
	ld [wRegVal], a
	ld a, $02
	ld [wRegIdx], a
	call WriteReg
	ld a, [wTrackIdx]
	cp $05
	jr nz, .l449E
	xor a
	ldh [rNR30], a
	ret
.l449E:
	cp $01
	jr z, .l44AC
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l44AE
.l44AC:
	ld h, HIGH(wTrkCh2)
.l44AE:
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
	dw Cmd_EB
	dw Cmd_EC
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
	jr nz, .l455B
	xor a
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp ReadCmdsNext
.l455B:
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

; $EA 4n: stores n | TF_AUTOPAN into the whole flags byte (0 for n = 0). The
; data uses EA 42 / EA 40, which also clears TF_DUTYSTEP and TF_FORCE.
Ext_Autopan:
	pop hl
	ld a, [de]
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l458F
	or $02
	jr .l4591
.l458F:
	and $FD
.l4591:
	ld [hl], a
	jp ReadCmdsNext

Cmd_EB:
	pop hl
	jp ReadCmdsNext

Cmd_EC:
	pop hl
	jp ReadCmdsNext

; $ED xy: duty step. y = duty for the first x ticks of each note; 0 = off.
Cmd_DutyStep:
	pop hl
	ld l, TRK_FLAGS
	ld a, [de]
	or a
	jr z, .l45B6
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
.l45B6:
	res 4, [hl]
	jp ReadCmdsNext

Cmd_Tempo:
	pop hl
	ld a, [de]
	ld [wTempo], a
	jp ReadCmdsNext

; $EF: TRK_PAN = NR51 bits for this track (not nibble-swapped any more). Dropped
; while the channel is blocked. On the drum track it skips one byte too many.
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

; GetPanBits: C = TRK_PAN & this track's NR51 bits, A = wNR51 without them.
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

; AutoPan: swap TRK_PAN's nibbles and apply it (not on the noise SFX track).
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
	jr z, .l468B
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
.l468B:
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
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l4700:
	dec b
	jr z, .l4706
	add a, c
	jr .l4700
.l4706:
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l4736
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l4736
	ld l, TRK_DUTYSTEP
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	call WriteReg
.l4736:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l4743
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l4755
.l4743:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l474B:
	srl c
	jr nc, .l4750
	add a, d
.l4750:
	rra
	dec b
	jr nz, .l474B
	pop de
.l4755:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBLOOPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l476D
	ld b, a
	ld c, $0C
	xor a
.l4768:
	add a, c
	dec b
	jr nz, .l4768
	ld c, a
.l476D:
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
	jp z, .l479C
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoStep
.l479C:
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
	jr z, .l47D2
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l47CC
	xor a
.l47CC:
	swap a
	ld l, TRK_LEVEL
	ld [hl], a
	ret
.l47D2:
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
	jr c, .l47FA
	xor a
.l47FA:
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
	jr nc, .l480D
	inc b
.l480D:
	ld a, [bc]
	cp $FB
	jr z, .l483F
	cp $FE
	jr z, .l4849
	cp $FF
	jr z, .l4867
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jr z, .l482D
	ld l, TRK_FLAGS
	set 3, [hl]
.l482D:
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
.l483F:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l480D
.l4849:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	cp [hl]
	jr z, .l485D
	cp $FF
	jr z, .l4855
	inc [hl]
.l4855:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jr VibratoStep
.l485D:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr .l480D
.l4867:
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
	jr z, .l4888
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
.l4888:
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
	call WriteReg
	ret

; DrumNote: start sound DrumMap[hi - 1] at once.
DrumNote:
	ld a, [de]
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	add a, l
	ld l, a
	jr nc, .l48D5
	inc h
.l48D5:
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.
WriteDuty:
	ld a, [wRegBase]
	cp $0A
	ld l, TRK_DUTY
	ld a, [hl]
	jr z, .l48F0
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegIdx], a
	jp WriteReg
.l48F0:
	dec a
	push de
	push hl
	ld hl, WaveTable
	call LoadPtrIndexed
	ld b, $10
	ld de, _AUD3WAVERAM
.l48FE:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l48FE
	pop hl
	pop de
	ret

; IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the
; CH2 SFX active.
IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l4916
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l491F
.l4916:
	cp $04
	jr nz, .l4921
	ld a, [wTrkSfx2]
	or a
	ret z
.l491F:
	scf
	ret
.l4921:
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
	jr nz, .l4941
	ld a, [hl]
	cp c
	jr z, .l4944
.l4941:
	ld a, c
	ld [hl], a
	ld [de], a
.l4944:
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
	jr nc, .l4989
	inc h
.l4989:
	ld a, [hl]
	pop hl
	ret

; NR register base per track.
RegBaseTable:
	db $00, $05, $0F, $00, $05, $0A, $0F

; CH3 wave pointers 1-12 (pairs share a wave).
WaveTable:
	dw WaveData1
	dw WaveData1
	dw WaveData2
	dw WaveData2
	dw WaveData3
	dw WaveData3
	dw WaveData4
	dw WaveData4
	dw WaveData5
	dw WaveData6
	dw WaveData6
	dw WaveData6
WaveData1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData2:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData3:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
WaveData4:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
WaveData5:
	db $34, $45, $56, $67, $89, $9A, $AB, $BC, $34, $45, $56, $67, $89, $9A, $AB, $BC
WaveData6:
	db $23, $34, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE

; Vibrato table: 15 entries.
VibratoTable:
	dw Vib01 ; 1
	dw Vib02 ; 2
	dw Vib03 ; 3
	dw Vib04 ; 4
	dw Vib04 ; 5
	dw Vib06 ; 6
	dw Vib07 ; 7
	dw Vib08 ; 8
	dw Vib02 ; 9
	dw Vib02 ; 10
	dw Vib07 ; 11
	dw Vib0C ; 12
	dw Vib08 ; 13
	dw Vib0E ; 14
	dw Vib06 ; 15

Vib01:
	VIB_SEGNO
	VIB_STEP 10, 0, $000
	VIB_STEP 10, 0, $01F
	VIB_REPEAT $FF
	db $FF

Vib02:
	VIB_STEP 1, 0, $006
	VIB_HOLD

Vib03:
	VIB_STEP 14, 0, $000
	VIB_STEP 10, 0, $001
	VIB_STEP 10, 0, $000
	VIB_SEGNO
	VIB_STEP 7, 0, $002
	VIB_STEP 7, 0, $000
	VIB_REPEAT $FF

Vib0E:
	VIB_STEP 1, 0, $001
	VIB_HOLD

Vib04:
	VIB_STEP 14, 0, $000
	VIB_STEP 1, 0, $001
	VIB_STEP 1, 0, $000
	VIB_SEGNO
	VIB_STEP 6, 0, $003
	VIB_STEP 6, 0, $000
	VIB_REPEAT $FF

Vib06:
	VIB_STEP 1, 0, $003
	VIB_HOLD

Vib08:
	VIB_STEP 14, 0, $000
	VIB_STEP 10, 0, $000
	VIB_STEP 10, 0, $000
	VIB_SEGNO
	VIB_STEP 7, 0, $001
	VIB_STEP 7, 0, $000
	VIB_REPEAT $FF

Vib07:
	VIB_STEP 14, 0, $000
	VIB_STEP 7, 0, $001
	VIB_STEP 7, 0, $000
	VIB_SEGNO
	VIB_STEP 8, 0, $00F
	VIB_STEP 8, 0, $000
	VIB_REPEAT $FF

Vib0C:
	VIB_STEP 14, 0, $000
	VIB_STEP 7, 0, $001
	VIB_STEP 7, 0, $000
	VIB_SEGNO
	VIB_STEP 8, 0, $008
	VIB_STEP 8, 0, $000
	VIB_REPEAT $FF

; Sound table: 107 ids ($01-$6B). The code indexes it as SoundTable - 2 + 2*id.
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

SndHdr06:
	SND_HEADER $80, $02 ; tracks: Sfx2
	dw Snd06_Sfx2

SndHdr07:
	SND_HEADER $38, $01 ; tracks: Sfx1
	dw Snd07_Sfx1

SndHdr08:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd0A_Sfx1

SndHdr0B:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $39, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $30, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd0F_Ch1
	dw Snd0F_Ch2
	dw Snd0F_Ch3

SndHdr10:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $38, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd11_Ch1
	dw Snd11_Ch2
	dw Snd11_Ch3

SndHdr12:
	SND_HEADER $38, $05 ; tracks: Sfx1, SfxN
	dw Snd12_Sfx1
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $37, $05 ; tracks: Sfx1, SfxN
	dw Snd13_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $34, $05 ; tracks: Sfx1, SfxN
	dw Snd15_Sfx1
	dw Snd15_SfxN

SndHdr16:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd16_Sfx1
	dw Snd16_Sfx2

SndHdr17:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd17_Sfx1
	dw Snd17_Sfx2

SndHdr18:
	SND_HEADER $39, $04 ; tracks: SfxN
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $36, $05 ; tracks: Sfx1, SfxN
	dw Snd19_Sfx1
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $38, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $37, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd1E_SfxN

SndHdr1F:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $38, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $38, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $36, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $35, $04 ; tracks: SfxN
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $37, $04 ; tracks: SfxN
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd25_Sfx1

SndHdr26:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $37, $05 ; tracks: Sfx1, SfxN
	dw Snd27_Sfx1
	dw Snd27_SfxN

SndHdr28:
	SND_HEADER $35, $05 ; tracks: Sfx1, SfxN
	dw Snd28_Sfx1
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $35, $04 ; tracks: SfxN
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $35, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd2A_Sfx1
	dw Snd2A_Sfx2
	dw Snd2A_Ch3

SndHdr2B:
	SND_HEADER $35, $04 ; tracks: SfxN
	dw Snd2B_SfxN

SndHdr2C:
	SND_HEADER $35, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd2D_SfxN

SndHdr2E:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd2E_Sfx1
	dw Snd2E_Sfx2

SndHdr2F:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $34, $04 ; tracks: SfxN
	dw Snd30_SfxN

SndHdr31:
	SND_HEADER $30, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd31_Sfx1
	dw Snd31_Sfx2
	dw Snd31_Ch3

SndHdr32:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd32_Sfx1
	dw Snd32_SfxN

SndHdr33:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd33_SfxN

SndHdr34:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd37_Sfx1
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd38_Sfx1
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $31, $04 ; tracks: SfxN
	dw Snd39_SfxN

SndHdr3A:
	SND_HEADER $31, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $32, $01 ; tracks: Sfx1
	dw Snd3B_Sfx1

SndHdr3C:
	SND_HEADER $30, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd3D_Sfx1
	dw Snd3D_SfxN

SndHdr3E:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd3F_Sfx1
	dw Snd3F_SfxN

SndHdr40:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd40_Sfx1
	dw Snd40_SfxN

SndHdr41:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd41_SfxN

SndHdr42:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd42_SfxN

SndHdr43:
	SND_HEADER $38, $05 ; tracks: Sfx1, SfxN
	dw Snd43_Sfx1
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $32, $05 ; tracks: Sfx1, SfxN
	dw Snd45_Sfx1
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $32, $04 ; tracks: SfxN
	dw Snd46_SfxN

SndHdr47:
	SND_HEADER $37, $05 ; tracks: Sfx1, SfxN
	dw Snd47_Sfx1
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $31, $05 ; tracks: Sfx1, SfxN
	dw Snd49_Sfx1
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $30, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd4A_Sfx1
	dw Snd4A_Sfx2
	dw Snd4A_SfxN

SndHdr4B:
	SND_HEADER $30, $03 ; tracks: Sfx1, Sfx2
	dw Snd4B_Sfx1
	dw Snd4B_Sfx2

SndHdr4C:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd4C_SfxN

SndHdr4D:
	SND_HEADER $30, $04 ; tracks: SfxN
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd4E_Sfx1

SndHdr4F:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd4F_Sfx1

SndHdr50:
	SND_HEADER $30, $01 ; tracks: Sfx1
	dw Snd50_Sfx1

SndHdr51:
	SND_HEADER $36, $05 ; tracks: Sfx1, SfxN
	dw Snd51_Sfx1
	dw Snd51_SfxN

SndHdr54:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd54_Ch1
	dw Snd54_Ch2
	dw Snd54_Ch3
	dw Snd54_Drm

SndHdr52:
	SND_HEADER $38, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd52_Sfx1
	dw Snd52_Sfx2
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $30, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd53_Ch1
	dw Snd53_Ch2
	dw Snd53_Ch3

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

SndHdr59:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd59_Ch1
	dw Snd59_Ch2
	dw Snd59_Ch3

SndHdr5A:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd5A_Ch1
	dw Snd5A_Ch2
	dw Snd5A_Ch3

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

SndHdr5B:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5B_Ch1
	dw Snd5B_Ch2
	dw Snd5B_Ch3
	dw Snd5B_Drm

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

SndHdr5C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5C_Ch1
	dw Snd5C_Ch2
	dw Snd5C_Ch3
	dw Snd5C_Drm

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

SndHdr68:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd68_Ch1
	dw Snd68_Ch2
	dw Snd68_Ch3
	dw Snd68_Drm

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

; Drum map: DRUM n plays sound DrumMap[n-1] (13 entries).
DrumMap:
	db $01, $02, $05, $02, $01, $02, $01, $03, $04, $04, $04, $04, $04

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
	NVOICE 1, 5, 2
	NOISE $1C
	SND_END

Snd02_SfxN:
	PAN $F0
	NVOICE 1, 5, 2
	NOISE $1C
	SND_END

Snd03_SfxN:
	NVOICE 1, $0C, 1
	NOISE $4D
	NOISE $31
	NOISE $11
	SND_END

Snd04_SfxN:
	NVOICE 1, 7, 2
	NOISE $58
	NOISE $6A
	SND_END

Snd05_SfxN:
	NVOICE 1, 1, 1
	NOISE $11
	SND_END

Snd07_Sfx1:
	DUTY_STEP 8, 1
	TRANSPOSE_UP $0A
	VOICE 5, $0F, $0C, 1, $0C
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	ATTEN $0A
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	SND_END

Snd08_SfxN:
	NVOICE 2, 8, 3
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

Snd09_SfxN:
	NVOICE 2, 8, 5
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

Snd0A_Sfx1:
	VOICE 4, $0F, $0C, $0F, 0
	OCTAVE 5
	NOTE F_, 1
	NOTE C_HI, 1
	PAN $0F
	ATTEN 7
	NOTE F_, 1
	NOTE C_HI, 1
	PAN $F0
	ATTEN 8
	NOTE F_, 1
	NOTE C_HI, 1
	PAN $FF
	SND_END

Snd0B_Sfx1:
	VOICE 2, $0F, 0, $0F, 0
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
	SND_END

Snd0C_Sfx1:
	VOICE 1, $0F, 0, 1, $0E
	SND_CALL Snd0C_Sfx1_4E83
	ATTEN $0A
	SND_CALL Snd0C_Sfx1_4E83
	SND_END
Snd0C_Sfx1_4E83:
	OCTAVE 5
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
	NOTE A#, 1
	SND_RET

Snd0D_Sfx1:
	VOICE 3, $0F, 4, 7, 6
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	PAN $0F
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	PAN $F0
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE D_, 1
	LEN_UNIT 1
	PAN $0F
	ATTEN 3
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C#, 1
	PAN $0F
	ATTEN 3
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D#, 1
	PAN $0F
	ATTEN 3
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE F_, 1
	PAN $F0
	ATTEN 5
	NOTE C_, 1
	NOTE F#, 1
	ATTEN 6
	NOTE C_, 1
	NOTE G_, 1
	PAN $0F
	ATTEN 7
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN $F0
	ATTEN 9
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	ATTEN $0A
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 6
	PAN $0F
	ATTEN 7
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN $F0
	ATTEN 9
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	ATTEN $0A
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN $FF
	SND_END

Snd0E_Sfx1:
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

Snd0F_Ch3:
	SND_END

Snd0F_Ch2:
	SND_END

Snd0F_Ch1:
	SND_END

Snd10_Sfx1:
	VOICE 1, $0F, 0, $0F, 0
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

Snd11_Ch1:
	TEMPO $10
	TRANSPOSE_DOWN $0C
	VOICE 3, $0C, 4, 1, $0B
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

Snd11_Ch2:
	VIBRATO $0E
	VOICE 3, 3, 8, $0F, 0
	OCTAVE 3
	NOTE G_, 5
	NOTE F#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 2
	SND_END

Snd11_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE 3, 2, 6, 4, $0F
	OCTAVE 2
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C#, 4
	SND_END

Snd14_Sfx1:
	VOICE 1, $0F, $0C, $0F, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	ATTEN 7
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE G#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	SND_END

Snd15_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd15_SfxN:
	NVOICE 9, $0C, 6
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	NOISE $71
	SND_END

Snd16_Sfx1:
	VOICE 1, $0F, 4, $0F, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd16_Sfx2:
	VOICE 1, 6, 8, $0F, 0
	REST 4
	OCTAVE 5
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd17_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 6
	NOTE C_HI, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_END

Snd17_Sfx2:
	VIBRATO $0E
	VOICE 1, 6, 8, $0F, 0
	REST 3
	OCTAVE 6
	NOTE C_HI, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_HI, 1
	NOTE C_, 1
	SND_END

Snd18_SfxN:
	NVOICE $18, $0F, 1
	NOISE $5E
	NVOICE $18, 8, 1
	NOISE $5E
	NVOICE $18, 6, 1
	NOISE $5E
	NVOICE $18, 4, 2
	NOISE $5E
	SND_END

Snd12_Sfx1:
	SND_END

Snd12_SfxN:
	NVOICE 5, $0F, 8
	NOISE $71
	NOISE $51
	NOISE $31
	NOISE $11
	NVOICE 5, 8, 8
	NOISE $11
	NVOICE 5, 4, 8
	NOISE $11
	SND_END

Snd13_Sfx1:
	VOICE 1, $0D, 4, 0, $0F
	OCTAVE 4
	ATTEN 5
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	ATTEN 3
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 2
	ATTEN $0A
	NOTE G_, 2
	NOTE C_, 4
	SND_END

Snd13_SfxN:
	NVOICE 3, $0E, 8
	NOISE $51
	NVOICE 5, $0C, 4
	NOISE $56
	NOISE $41
	NOISE $52
	SND_END

Snd19_Sfx1:
	VOICE 2, $0F, 0, 0, 0
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
	NOTE C_HI, 1
	NOTE E_, 1
	VOICE 2, 8, $0C, 0, 0
	OCTAVE 6
	NOTE G_, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 4
	REST 1
	NOTE A#, 1
	ATTEN 5
	REST 3
	NOTE C_HI, 1
	SND_END

Snd19_SfxN:
	NVOICE 4, 8, 4
	NOISE $61
	NOISE $51
	NOISE $41
	NOISE $31
	SND_END

Snd1A_Sfx1:
	DUTY_STEP 8, 2
	VOICE 5, $0F, 4, $0F, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	PAN $0F
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	PAN $FF
	SND_END

Snd1B_Sfx1:
	TRANSPOSE_UP 5
	VOICE 1, $0F, 4, $0F, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_END

Snd1C_Sfx1:
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

Snd1D_Sfx1:
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
	SND_END

Snd1E_SfxN:
	NVOICE 5, 2, 9
	NOISE $31
	NOISE $41
	NVOICE 5, 1, 9
	NOISE $31
	SND_END

Snd1F_SfxN:
	NVOICE 5, 8, 9
	NOISE $11
	NOISE $31
	SND_END

Snd20_Sfx1:
	VOICE 3, $0F, 8, 0, 0
	OCTAVE 4
	NOTE C_HI, 1
	NOTE D#, 1
	PAN $0F
	OCTAVE 3
	NOTE C_HI, 1
	NOTE D#, 1
	PAN $F0
	OCTAVE 4
	NOTE C_HI, 1
	NOTE D#, 1
	PAN $0F
	ATTEN $0A
	OCTAVE 3
	NOTE C_HI, 1
	NOTE D#, 1
	PAN $F0
	ATTEN $0A
	OCTAVE 2
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C_, 1
	PAN $FF
	SND_END

Snd21_Sfx1:
	VOICE 4, $0F, 8, 1, $0F
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	PAN $0F
	NOTE D#, 1
	NOTE E_, 1
	PAN $F0
	NOTE D#, 1
	NOTE E_, 1
	PAN $FF
	ATTEN 9
	NOTE D#, 1
	NOTE E_, 1
	ATTEN $0A
	NOTE D#, 1
	NOTE E_, 1
	SND_END

Snd22_Sfx1:
	SND_END

Snd23_SfxN:
	NVOICE 8, $0F, 2
	NOISE $37
	NOISE $31
	NOISE $21
	SND_END

Snd24_SfxN:
	NVOICE 6, $0F, 4
	NOISE $41
	NOISE $51
	NOISE $41
	NOISE $31
	SND_END

Snd25_Sfx1:
	SND_END

Snd26_SfxN:
	SND_END

Snd27_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN $0A
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE E_, 1
	SND_END

Snd27_SfxN:
	NVOICE $20, $0F, 5
	NOISE $81
	NOISE $71
	SND_END

Snd28_Sfx1:
	VOICE 1, $0F, 0, $0F, 0
	OCTAVE 2
	NOTE C_, 1
	REST 1
	NOTE C#, 1
	NOTE E_, 3
	OCTAVE 3
	NOTE C_, 1
	REST 1
	NOTE C#, 1
	NOTE E_, 3
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 3
	NOTE B_, 1
	REST 1
	NOTE C_HI, 1
	ATTEN $0A
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	SND_END

Snd28_SfxN:
	NVOICE $10, 7, 5
	NOISE $11
	NOISE $11
	NOISE $11
	SND_END

Snd29_SfxN:
	NVOICE $20, $0F, 2
	NOISE $79
	SND_END

Snd2B_SfxN:
	NVOICE $20, $0F, 8
	NOISE $81
	NOISE $81
	SND_END

Snd2C_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F_, 1
	ATTEN 9
	NOTE B_, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE B_, 1
	NOTE F_, 1
	REST 1
	NOTE B_, 1
	NOTE F_, 1
	SND_END

Snd2D_SfxN:
	NVOICE 1, 4, 7
	NOISE $51
	NOISE $41
	SND_END

Snd2E_Sfx1:
	DUTY_STEP 8, 2
	TRANSPOSE_DOWN 6
	VOICE 7, 8, 4, 2, $0D
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE C_, 1
	SND_END

Snd2E_Sfx2:
	VIBRATO $0E
	TRANSPOSE_DOWN 6
	VOICE 7, 3, 8, 1, 8
	OCTAVE 4
	NOTE A_, 4
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 6
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	SND_END

Snd2F_SfxN:
	SND_END

Snd30_SfxN:
	NVOICE 1, $0F, 8
	NOISE $41
	NOISE $11
	SND_END

Snd2A_Sfx1:
	TEMPO $90
	VOICE 4, $0F, 8, $0F, 0
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 7
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 9
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_END

Snd2A_Sfx2:
	VIBRATO $0F
	VOICE 4, 2, 8, $0F, 0
	REST 3
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT $0A
	SND_END

Snd2A_Ch3:
	SND_END

Snd31_Sfx1:
	VOICE 4, $0F, 8, $0F, 0
	SND_CALL Snd31_Sfx1_51F3

Snd31_Sfx2:
	VIBRATO $0F
	VOICE 4, 2, 8, $0F, 0
	SND_CALL Snd31_Sfx1_522A
Snd31_Sfx1_51F3:
	SND_SEGNO
	ATTEN $0A
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT $F0
	SND_RET
Snd31_Sfx1_522A:
	REST 3
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT $F0
	SND_RET
	db $FF

Snd31_Ch3:
	SND_END

Snd32_Sfx1:
	VOICE 1, $0C, 0, 3, $0F
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	REST 2
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 6
	ATTEN 3
	NOTE E_, 4
	ATTEN $0A
	OCTAVE 5
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 6
	NOTE E_, 6
	SND_END

Snd32_SfxN:
	NVOICE $10, $0F, 2
	NOISE $7B
	SND_END

Snd34_Sfx1:
	VOICE 1, $0F, 8, 1, $0F
	OCTAVE 6
	NOTE A_, 1
	REST 2
	ATTEN 1
	NOTE C_HI, 1
	SND_END

Snd33_SfxN:
	NVOICE 3, 3, 9
	NOISE $31
	NOISE $41
	NVOICE 5, 1, 6
	NOISE $31
	SND_END

Snd35_SfxN:
	NVOICE 3, $0F, 8
	NOISE $41
	NOISE $21
	NOISE $11
	NOISE $11
	SND_END

Snd36_Sfx1:
	VOICE 1, $0F, 0, 0, 0
	OCTAVE 2
	NOTE C_HI, 1
	ATTEN 6
	NOTE A#, 1
	SND_END

Snd36_SfxN:
	NVOICE 2, $0F, 8
	NOISE $11
	NOISE $61
	NOISE $11
	NOISE $11
	SND_END

Snd37_Sfx1:
	VOICE 1, $0A, 0, 0, 0
	OCTAVE 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 0
	NOTE C_HI, 1
	SND_END

Snd37_SfxN:
	NVOICE 2, $0F, 3
	NOISE $41
	NOISE $11
	SND_END

Snd38_Sfx1:
	VOICE 1, $0F, 4, 0, 0
	OCTAVE 6
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 3
	OCTAVE 5
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 4
	OCTAVE 6
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 5
	OCTAVE 4
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 6
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 8
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN 9
	OCTAVE 2
	NOTE B_, 1
	NOTE C_HI, 1
	ATTEN $0A
	OCTAVE 6
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_END

Snd38_SfxN:
	NVOICE 4, $0F, 7
	NOISE $4A
	NVOICE 4, $0C, 7
	NOISE $3A
	NVOICE 4, $0A, 7
	NOISE $4A
	NVOICE 4, 8, 7
	NOISE $3A
	NVOICE 4, 6, 7
	NOISE $4A
	SND_END

Snd39_SfxN:
	NVOICE 7, $0F, 8
	NOISE $41
	NOISE $21
	NOISE $11
	NOISE $11
	NVOICE 7, 8, 8
	NOISE $11
	SND_END

Snd3A_Sfx1:
	TRANSPOSE_DOWN 6
	VOICE 2, $0F, 8, 0, 0
	SND_SEGNO
	OCTAVE 3
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 9
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	ATTEN 0
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 7
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE F_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	SND_END

Snd3B_Sfx1:
	TRANSPOSE_DOWN $0C
	VOICE 1, $0F, 0, 3, $0F
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	REST 2
	NOTE G_, 1
	ATTEN 2
	NOTE C_HI, 1
	OCTAVE 4
	ATTEN 3
	NOTE E_, 4
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 6
	SND_END

Snd3C_Sfx1:
	VOICE 1, $0D, 8, 5, $0F
	OCTAVE 6
	NOTE C_HI, 1
	REST 5
	ATTEN 9
	NOTE C_HI, 1
	REST 8
	ATTEN $0A
	NOTE C_HI, 1
	SND_END

Snd3C_SfxN:
	NVOICE $10, $0B, 1
	NOISE $5D
	SND_END

Snd3D_Sfx1:
	VOICE 1, $0C, 0, $0F, 0
	OCTAVE 6
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 7
	OCTAVE 4
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 8
	OCTAVE 3
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN 9
	OCTAVE 2
	NOTE C_HI, 1
	NOTE G_, 1
	ATTEN $0A
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	SND_END
	db $FF

Snd3D_SfxN:
	NVOICE 2, 8, 4
	NOISE $41
	NOISE $11
	SND_END

Snd3E_Sfx1:
	VOICE 2, 8, 0, 0, 0
	OCTAVE 5
	NOTE G_, 1
	ATTEN 7
	NOTE D#, 1
	RELEASE 1, $0F
	NOTE A_, 1
	NOTE C_, 1
	SND_END

Snd3E_SfxN:
	NVOICE 2, $0F, 4
	NOISE $58
	NOISE $28
	SND_END

Snd3F_Sfx1:
	VOICE 2, 8, 4, 3, $0F
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	SND_END

Snd3F_SfxN:
	NVOICE 3, $0F, 5
	NOISE $6A
	NVOICE 2, 8, $0A
	NOISE $11
	NOISE $21
	NOISE $31
	SND_END

Snd40_Sfx1:
	VOICE 2, $0F, 8, 3, $0F
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_END

Snd40_SfxN:
	NVOICE 2, 8, 5
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd41_SfxN:
	NVOICE $0F, $0F, 4
	NOISE $7C
	NVOICE $0F, 6, 5
	NOISE $71
	SND_END

Snd42_SfxN:
	NVOICE 1, 8, 8
	NOISE $11
	NOISE $61
	NOISE $11
	NOISE $11
	SND_END

Snd43_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 1
	NOTE B_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 8
	NOTE C#, 1
	ATTEN $0A
	NOTE C_, 1
	SND_END

Snd43_SfxN:
	NVOICE 2, $0F, 4
	NOISE $11
	NOISE $71
	NOISE $41
	SND_END

Snd44_SfxN:
	NVOICE 1, $0F, 2
	NOISE $51
	NVOICE 2, 6, 8
	NOISE $31
	NOISE $21
	NOISE $11
	SND_END

Snd45_Sfx1:
	VOICE 3, $0F, 0, $0F, 0
	OCTAVE 1
	NOTE E_, 1
	ATTEN $0A
	NOTE E_, 1
	ATTEN 9
	NOTE E_, 1
	ATTEN 8
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	SND_END

Snd45_SfxN:
	NVOICE $20, 4, 8
	NOISE $4B
	SND_END

Snd46_SfxN:
	SND_END

; Unreferenced noise stream.
Orphan_5412:
	db $E0, $02, $F6, $51, $E0, $02, $88, $31, $E0, $02, $68, $21, $21, $E0, $02, $38
	db $11, $FF

Snd47_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	OCTAVE 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 7
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_END

Snd47_SfxN:
	NVOICE 7, $0F, 8
	NOISE $5C
	NVOICE 7, 6, 8
	NOISE $3C
	NVOICE 7, 3, 8
	NOISE $1C
	SND_END

Snd48_Sfx1:
	VOICE 1, $0C, 0, $0F, 0
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_END

Snd48_SfxN:
	NVOICE 3, $0F, 8
	NOISE $31
	NVOICE 3, 6, 8
	NOISE $21
	NVOICE 3, 3, 8
	NOISE $11
	SND_END

Snd49_Sfx1:
	VOICE 3, 5, 0, $0F, 0
	OCTAVE 1
	NOTE G#, 1
	NOTE F#, 1
	SND_END

Snd49_SfxN:
	NVOICE 2, $0F, 8
	NOISE $41
	NVOICE 2, 6, 8
	NOISE $31
	SND_END

Snd4A_Sfx1:
	VOICE 2, $0F, 8, 0, 0
	SND_CALL Snd4A_Sfx1_5490
	SND_END

Snd4A_Sfx2:
	VIBRATO $0F
	VOICE 2, $0C, 0, 0, 0
	REST 3
	SND_CALL Snd4A_Sfx1_5490
	SND_END
Snd4A_Sfx1_5490:
	SND_SEGNO
	OCTAVE 1
	ATTEN $0A
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 9
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 2
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 0
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE C_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE C_, 1
	ATTEN 7
	NOTE E_, 1
	NOTE C_, 1
	ATTEN 8
	NOTE F_, 1
	NOTE C_, 1
	ATTEN $0A
	NOTE E_, 1
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 5
	SND_RET

Snd4A_SfxN:
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
	SND_REPEAT 3
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
	NOISE $91
	SND_REPEAT 2
	NVOICE 9, 7, 7
	NOISE $81
	SND_END

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

Snd4B_Sfx1:
	VOICE 6, $0F, 0, 2, $0F
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 4
	SND_END

Snd4B_Sfx2:
	VIBRATO $0E
	VOICE 6, 5, 8, 4, 8
	REST 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 4
	SND_END

Snd54_Ch3:
	VOICE 4, 2, 2, 5, $0A
	SND_CALL Snd54_Ch1_555D
	SND_CALL Snd54_Ch3_557D
Snd54_Ch1_555D:
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	TRANSPOSE_DOWN 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	SND_RET
Snd54_Ch3_557D:
	NOTE E_, 2
	TEMPO $30
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 1
	NOTE G#, 1
	RELEASE $0F, 0
	NOTE A#, $0E
	OCTAVE 5
	NOTE F#, $0E
	SND_END
Snd54_Ch1_558B:
	VIBRATO 3
	NOTE E_, 1
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, $0E
	OCTAVE 5
	NOTE C#, $0E
	SND_END

Snd54_Ch2:
	DUTY_STEP 0, 2
	TRANSPOSE_DOWN $0C
	VOICE 8, 8, 8, $0F, 0
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE B_, 8
	OCTAVE 2
	NOTE E_, 7
	SND_END

Snd54_Ch1:
	VIBRATO $0E
	VOICE 4, 3, 4, $0F, 0
	REST 1
	SND_CALL Snd54_Ch1_555D
	SND_CALL Snd54_Ch1_558B

Snd54_Drm:
	SND_END

Snd4C_SfxN:
	SND_END

Snd4D_SfxN:
	SND_END

Snd4E_Sfx1:
	SND_END

Snd4F_Sfx1:
	VOICE 2, $0F, 0, $0F, 0
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
	SND_REPEAT $F0
	SND_END

Snd50_Sfx1:
	SND_END

Snd51_Sfx1:
	VOICE 1, $0F, 4, $0F, 0
	SND_CALL Snd51_Sfx1_55FA
	ATTEN $0A
	SND_CALL Snd51_Sfx1_55FA
	VOICE 1, 3, 4, $0F, 0
	SND_CALL Snd51_Sfx1_55FA
	SND_END
Snd51_Sfx1_55FA:
	OCTAVE 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE B_, 1
	SND_RET

Snd51_SfxN:
	NVOICE $0C, 4, 9
	NOISE $78
	NOISE $51
	NOISE $41
	NOISE $11
	SND_END

Snd52_Sfx1:
	VOICE 1, $0F, 8, $0F, 0
	SND_SEGNO
	SND_CALL Snd52_Sfx1_563D
	SND_REPEAT 4
	ATTEN 5
	SND_SEGNO
	SND_CALL Snd52_Sfx1_563D
	SND_REPEAT 4
	ATTEN 7
	SND_SEGNO
	SND_CALL Snd52_Sfx1_563D
	SND_REPEAT 4
	ATTEN $0A
	SND_SEGNO
	SND_CALL Snd52_Sfx1_563D
	SND_REPEAT 4
	SND_END

Snd52_Sfx2:
	VIBRATO $0F
	VOICE 1, 3, 0, $0F, 0
	REST 4
	SND_SEGNO
	SND_CALL Snd52_Sfx1_563D
	SND_REPEAT $10
	SND_END
Snd52_Sfx1_563D:
	OCTAVE 2
	SND_SEGNO
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
	SND_RET

Snd52_SfxN:
	NVOICE 1, 7, 8
	NOISE $71
	SND_END

Snd53_Ch1:
	VOICE $0A, $0C, 8, 3, 0
	REST 1
	ATTEN 3
	OCTAVE 1
	NOTE D_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	TEMPO $40
	ATTEN 3
	NOTE G#, 1
	OCTAVE 2
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	TEMPO $90
	NOTE C#, 1
	RELEASE 4, 6
	NOTE A#, 4
	SND_END

Snd53_Ch2:
	VIBRATO $0E
	VOICE $0A, 5, 8, $0F, 0
	REST 2
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE A#, 1
	SND_END

Snd53_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE $0A, 4, 6, $0F, 0
	REST 1
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE A#, 4
	SND_END

Snd56_Ch3:
	TRANSPOSE_DOWN $0C
	VIBRATO 3
	VOICE 6, 2, 2, 8, 8
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE E_, 3
	OCTAVE 2
	NOTE G_, 3
	NOTE A#, 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_REPEAT 2
Snd56_Ch3_56C8:
	TRANSPOSE_UP 0
	VOICE 6, 2, 9, $0F, 0
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5752
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5758
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5788
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5797
	TRANSPOSE_DOWN $0C
	VOICE 6, 2, 9, $0F, 0
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5752
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5758
	TRANSPOSE_UP 0
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5788
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch3_5766
	SND_CALL Snd56_Ch1_5797
	SND_CALL Snd56_Ch3_56C8
Snd56_Ch1_5739:
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 7
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 3
	SND_RET
Snd56_Ch1_5749:
	NOTE B_, 3
	NOTE A_, 1
	NOTE A_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	NOTE A_, 2
	SND_RET
Snd56_Ch1_5752:
	OCTAVE 4
	NOTE D_, 3
	NOTE C#, 3
	NOTE D_, 3
	NOTE E_, 2
	SND_RET
Snd56_Ch1_5758:
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	RELEASE 4, $0F
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
Snd56_Ch3_5766:
	VOICE 6, 2, 4, 4, 8
Snd56_Ch1_576A:
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 6
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET
Snd56_Ch1_5779:
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 5
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 2
	SND_RET
Snd56_Ch1_5788:
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 5
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE A_, 1
	SND_RET
Snd56_Ch1_5797:
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET

Snd56_Ch1:
	TRANSPOSE_DOWN $0C
	VIBRATO $0E
	VOICE 6, 2, 8, 3, 9
	SND_SEGNO
	PAN $F0
	OCTAVE 4
	NOTE D_, 2
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	NOTE C_, 1
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	PAN $F0
	NOTE B_, 1
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	OCTAVE 3
	NOTE A#, 1
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_REPEAT 4
	REST 1
Snd56_Ch1_57E2:
	TRANSPOSE_UP 0
	VOICE 6, 2, 8, $0F, 0
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5752
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5758
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5788
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5797
	TRANSPOSE_DOWN $0C
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5752
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5749
	SND_CALL Snd56_Ch1_5739
	SND_CALL Snd56_Ch1_5758
	TRANSPOSE_UP 0
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5788
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5779
	SND_CALL Snd56_Ch1_576A
	SND_CALL Snd56_Ch1_5797
	SND_CALL Snd56_Ch1_57E2

Snd56_Ch2:
	TRANSPOSE_DOWN $0C
	TEMPO $40
	DUTY_STEP 8, 1
	VIBRATO 3
	VOICE 6, 8, 4, $0F, 0
	SND_SEGNO
	PAN $F0
	OCTAVE 4
	NOTE D_, 1
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	NOTE C_, 1
	PAN $FF
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	PAN $F0
	NOTE B_, 1
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	OCTAVE 3
	NOTE A#, 1
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	RELEASE $0F, 0
	PAN $F0
	OCTAVE 4
	NOTE D_, 1
	PAN $FF
	RELEASE 3, $0F
	NOTE E_, 1
	NOTE F_, 1
	PAN $0F
	RELEASE $0F, 0
	NOTE C_, 1
	PAN $FF
	RELEASE 1, $0F
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	PAN $F0
	RELEASE $0F, 0
	NOTE B_, 1
	RELEASE 2, $0F
	PAN $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	RELEASE $0F, 0
	PAN $0F
	OCTAVE 3
	NOTE A#, 1
	PAN $FF
	RELEASE 2, $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_REPEAT 2
Snd56_Ch2_58BB:
	DUTY_STEP 0, 2
	PAN $0F
	AUTOPAN 2
	VOICE 6, $0F, 8, 1, $0F
	SND_SEGNO
	SND_CALL Snd56_Ch2_58F8
	SND_CALL Snd56_Ch2_5912
	SND_CALL Snd56_Ch2_58F8
	SND_CALL Snd56_Ch2_591C
	SND_REPEAT 2
	SND_CALL Snd56_Ch2_5926
	SND_CALL Snd56_Ch2_5938
	SND_CALL Snd56_Ch2_5941
	SND_CALL Snd56_Ch2_5926
	SND_CALL Snd56_Ch2_5938
	SND_CALL Snd56_Ch2_594A
	SND_CALL Snd56_Ch2_5926
	SND_CALL Snd56_Ch2_5938
	SND_CALL Snd56_Ch2_5941
	SND_CALL Snd56_Ch2_5926
	SND_CALL Snd56_Ch2_5954
	SND_CALL Snd56_Ch2_58BB
Snd56_Ch2_58F8:
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd56_Ch2_5912:
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	SND_RET
Snd56_Ch2_591C:
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_RET
Snd56_Ch2_5926:
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	SND_RET
Snd56_Ch2_5938:
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	SND_RET
Snd56_Ch2_5941:
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd56_Ch2_594A:
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_RET
Snd56_Ch2_5954:
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET

Snd56_Drm:
	DRUM_UNIT 6
	SND_SEGNO
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
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT 4
Snd56_Drm_5985:
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 1
	SND_REPEAT $F0
	SND_CALL Snd56_Drm_5985
	db $FF

Snd5B_Ch2:
	TEMPO $20
	VOICE 6, 8, 4, $0F, 0
	OCTAVE 3
	NOTE F#, 8
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 2
	RELEASE 4, $0F
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
Snd5B_Ch2_59C3:
	VIBRATO 3
	VOICE 6, 8, 4, $0F, 0
	SND_SEGNO
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A56
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A5F
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A56
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A6F
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A8E
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A9F
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A8E
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5AB3
	SND_REPEAT 2
	TRANSPOSE_DOWN $0C
	PAN $0F
	AUTOPAN 2
	DUTY_STEP 0, 2
	VOICE 6, 9, 8, 8, $0D
	SND_CALL Snd5B_Ch1_5ABD
	SND_CALL Snd5B_Ch1_5ACE
	SND_CALL Snd5B_Ch1_5ABD
	SND_CALL Snd5B_Ch1_5ADF
	TRANSPOSE_UP 0
	VOICE 6, 8, 4, 7, 8
	DUTY_STEP 0, 0
	PAN $FF
	AUTOPAN 0
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B00
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B06
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B0C
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B00
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B06
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B1C
	SND_CALL Snd5B_Ch2_59C3
Snd5B_Ch1_5A47:
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 6
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_RET
Snd5B_Ch1_5A56:
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 5
	NOTE E_, 3
	NOTE F#, 5
	SND_RET
Snd5B_Ch1_5A5F:
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE D_, 5
	NOTE C#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
Snd5B_Ch1_5A6F:
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE D_, 5
	RELEASE 2, $0E
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd5B_Ch1_5A80:
	RELEASE $0F, 0
	DUTY $0C
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 9
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_RET
Snd5B_Ch1_5A8E:
	OCTAVE 3
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 5
	RELEASE 3, $0D
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	RELEASE $0F, 0
	NOTE A_, 3
	SND_RET
Snd5B_Ch1_5A9F:
	LEN_UNIT 1
	NOTE D_, 4
	NOTE C#, 2
	LEN_UNIT 6
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	SND_RET
Snd5B_Ch1_5AB3:
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE C#, 5
	NOTE F#, 3
	NOTE G#, 3
	NOTE A#, 2
	DUTY 4
	SND_RET
Snd5B_Ch1_5ABD:
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	RELEASE $0F, 0
	NOTE G_, 4
	RELEASE 8, $0D
	SND_REPEAT 2
	SND_RET
Snd5B_Ch1_5ACE:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 3
	NOTE E_, 2
	NOTE G_, 2
	RELEASE $0F, 0
	NOTE A_, 4
	RELEASE 8, $0D
	SND_REPEAT 2
	SND_RET
Snd5B_Ch1_5ADF:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 3
	NOTE E_, 2
	NOTE G_, 2
	RELEASE $0F, 0
	NOTE A_, 4
	RELEASE 8, $0D
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE A#, 3
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	RELEASE $0F, 0
	NOTE F#, 4
	RELEASE 8, $0D
	SND_RET
Snd5B_Ch1_5AFA:
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd5B_Ch1_5B00:
	OCTAVE 3
	NOTE F#, $0A
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd5B_Ch1_5B06:
	OCTAVE 3
	NOTE G_, $0A
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	SND_RET
Snd5B_Ch1_5B0C:
	OCTAVE 3
	NOTE G#, $0A
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE A#, 5
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE A#, 3
	OCTAVE 4
	NOTE C#, 2
	SND_RET
Snd5B_Ch1_5B1C:
	OCTAVE 3
	NOTE G#, $0A
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	DUTY $0C
	RELEASE 1, $0D
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0F, 0
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	SND_RET

Snd5B_Ch1:
	VIBRATO $0E
	VOICE 6, 3, 8, $0F, 0
	REST 1
	OCTAVE 3
	NOTE F#, 8
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 2
	RELEASE 4, $0F
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
Snd5B_Ch1_5B62:
	TRANSPOSE_UP 0
	PAN $FF
	AUTOPAN 0
	VIBRATO $0E
	VOICE 6, 3, 8, $0F, 0
	SND_SEGNO
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A56
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A5F
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A56
	SND_CALL Snd5B_Ch1_5A47
	SND_CALL Snd5B_Ch1_5A6F
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A8E
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A9F
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5A8E
	SND_CALL Snd5B_Ch1_5A80
	SND_CALL Snd5B_Ch1_5AB3
	SND_REPEAT 2
	TRANSPOSE_DOWN $0C
	PAN $0F
	AUTOPAN 2
	DUTY_STEP 0, 2
	VOICE 6, 3, 8, $0F, 0
	SND_CALL Snd5B_Ch1_5ABD
	SND_CALL Snd5B_Ch1_5ACE
	SND_CALL Snd5B_Ch1_5ABD
	SND_CALL Snd5B_Ch1_5ADF
	TRANSPOSE_UP 0
	PAN $FF
	AUTOPAN 0
	VIBRATO $0E
	VOICE 6, 3, 8, $0F, 0
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B00
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B06
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B0C
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B00
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B06
	SND_CALL Snd5B_Ch1_5AFA
	SND_CALL Snd5B_Ch1_5B1C
	SND_CALL Snd5B_Ch1_5B62

Snd5B_Ch3:
	VOICE 6, 2, 2, $0F, 0
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	VOICE 6, 2, 6, 3, $0D
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
Snd5B_Ch3_5C2B:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CBE
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CC9
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CBE
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CC9
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CDA
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CDA
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CFC
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CBE
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CC9
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CBE
	SND_CALL Snd5B_Ch3_5CA4
	SND_CALL Snd5B_Ch3_5CC9
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CDA
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CDA
	SND_CALL Snd5B_Ch3_5CE6
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5CFC
	TRANSPOSE_UP 0
	SND_CALL Snd5B_Ch3_5D2F
Snd5B_Ch3_5CA4:
	VOICE 6, 2, 6, 2, $0A
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 7
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd5B_Ch3_5CBE:
	RELEASE 3, 8
	NOTE F#, 2
	RELEASE 2, $0A
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	SND_RET
Snd5B_Ch3_5CC9:
	RELEASE 3, 8
	NOTE A_, 2
	RELEASE 2, $0A
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	SND_RET
Snd5B_Ch3_5CD3:
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT 8
	SND_RET
Snd5B_Ch3_5CDA:
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd5B_Ch3_5CE6:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	SND_RET
Snd5B_Ch3_5CF5:
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 4
	SND_RET
Snd5B_Ch3_5CFC:
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE $0F, 0
	NOTE A#, 3
	RELEASE 4, $0F
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0F, 0
	NOTE F#, 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	RELEASE 2, $0A
	SND_RET
Snd5B_Ch3_5D14:
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 4
	SND_RET
Snd5B_Ch3_5D1B:
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT 4
	SND_RET
Snd5B_Ch3_5D22:
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE $0F, 0
	NOTE A#, 3
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	RELEASE 2, $0A
	SND_RET
Snd5B_Ch3_5D2F:
	VOICE 6, 2, 9, $0E, 0
	SND_CALL Snd5B_Ch3_5D42
	SND_CALL Snd5B_Ch3_5D5E
	SND_CALL Snd5B_Ch3_5D42
	SND_CALL Snd5B_Ch3_5D77
	SND_CALL Snd5B_Ch3_5DA0
Snd5B_Ch3_5D42:
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0F, 0
	OCTAVE 3
	NOTE G_, 3
	RELEASE $0E, 0
	SND_REPEAT 2
	SND_RET
Snd5B_Ch3_5D5E:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE $0F, 0
	OCTAVE 3
	NOTE A_, 3
	RELEASE $0E, 0
	SND_REPEAT 2
	SND_RET
Snd5B_Ch3_5D77:
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE $0F, 0
	OCTAVE 3
	NOTE A_, 3
	RELEASE $0E, 0
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5B_Ch3_5DA0:
	TRANSPOSE_DOWN $0C
	VOICE 6, 2, 6, 2, $0A
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5D14
	SND_CALL Snd5B_Ch3_5D14
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5D1B
	SND_CALL Snd5B_Ch3_5D22
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5CF5
	SND_CALL Snd5B_Ch3_5D14
	SND_CALL Snd5B_Ch3_5D14
	SND_CALL Snd5B_Ch3_5CD3
	SND_CALL Snd5B_Ch3_5D14
	SND_CALL Snd5B_Ch3_5D22
	SND_CALL Snd5B_Ch3_5C2B

Snd5B_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $0C
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 6
Snd5B_Drm_5DEA:
	SND_CALL Snd5B_Drm_5E0B
	SND_CALL Snd5B_Drm_5E27
	SND_CALL Snd5B_Drm_5E0B
	SND_CALL Snd5B_Drm_5E30
	SND_CALL Snd5B_Drm_5E0B
	SND_CALL Snd5B_Drm_5E27
	SND_CALL Snd5B_Drm_5E0B
	SND_CALL Snd5B_Drm_5E30
	SND_CALL Snd5B_Drm_5E41
	SND_CALL Snd5B_Drm_5E66
	SND_CALL Snd5B_Drm_5DEA
Snd5B_Drm_5E0B:
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
	SND_REPEAT 7
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	SND_RET
Snd5B_Drm_5E27:
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5B_Drm_5E30:
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 6
	SND_RET
Snd5B_Drm_5E41:
	SND_SEGNO
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	LEN_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 6
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT 7
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5B_Drm_5E66:
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
	SND_REPEAT 7
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	LEN_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 6
	SND_RET

Snd59_Ch3:
	TEMPO $30
	VIBRATO 3
	VOICE 4, 2, 2, 5, $0A
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
	RELEASE 5, 8
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE $0F, 0
	OCTAVE 4
	NOTE C_, $0C
	SND_END

Snd59_Ch1:
	PAN $0F
	VIBRATO 3
	VOICE 4, 8, 4, 5, 9
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
	RELEASE $0F, 0
	OCTAVE 3
	NOTE G_, $0C
	SND_END

Snd59_Ch2:
	PAN $F0
	VOICE 4, 8, 8, $0F, 0
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

Snd5A_Ch3:
	VIBRATO 3
	VOICE 4, 2, 2, 3, 8
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	ATTEN 0
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	RELEASE 5, 5
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 4
	RELEASE $0F, 0
	NOTE E_, $0C
	SND_END

Snd5A_Ch1:
	TRANSPOSE_UP $0C
	VOICE 4, 4, 8, 1, 9
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

Snd5A_Ch2:
	VOICE 4, 8, 8, $0F, 0
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

Snd55_Ch3:
	TEMPO $20
	VIBRATO 3
	VOICE 6, 2, 4, 8, $0F
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_6001
	SND_CALL Snd55_Ch3

Snd55_Ch1:
	PAN $0F
	VOICE 6, 4, 8, 4, $0F
	REST 3
Snd55_Ch1_5F83:
	RELEASE 4, $0F
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_6001
	SND_CALL Snd55_Ch1_5F83

Snd55_Ch2:
	PAN $F0
	VOICE 6, 4, 8, 4, $0F
	REST 6
Snd55_Ch2_5FB0:
	RELEASE 4, $0F
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_5FD6
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFC
	SND_CALL Snd55_Ch1_5FEC
	SND_CALL Snd55_Ch1_5FFE
	SND_CALL Snd55_Ch1_6001
	SND_CALL Snd55_Ch2_5FB0
Snd55_Ch1_5FD6:
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 5
	NOTE E_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	SND_REPEAT 2
	SND_RET
Snd55_Ch1_5FEC:
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE E_, 2
	SND_RET
Snd55_Ch1_5FFC:
	NOTE G_, 2
	SND_RET
Snd55_Ch1_5FFE:
	OCTAVE 3
	NOTE B_, 2
	SND_RET
Snd55_Ch1_6001:
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE E_, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 6, $0E
	NOTE E_, 6
	ATTEN 2
	NOTE E_, $0C
	ATTEN 0
	SND_RET

Snd55_Drm:
	SND_END

Snd57_Ch2:
	VIBRATO 1
	VOICE 8, 8, 4, $0F, 0
	OCTAVE 1
	NOTE C_, $0E
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	OCTAVE 1
	NOTE C_, $0E
	ATTEN 6
	NOTE C_, 4
	ATTEN 0
	SND_END

Snd58_Ch2:
	TEMPO $30
	VOICE 5, 8, 4, 1, $0E
Snd58_Ch2_605E:
	VOICE 5, 8, 4, 1, $0E
	SND_CALL Snd58_Ch2_60A8
	ATTEN 5
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch2_60A8
	ATTEN 5
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch2_60A8
	ATTEN 5
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch2_60A8
	ATTEN 5
	SND_CALL Snd58_Ch1_60C3
	ATTEN 3
	SND_CALL Snd58_Ch1_60D9
	ATTEN 5
	SND_CALL Snd58_Ch1_60D9
	ATTEN 5
	SND_CALL Snd58_Ch1_60EC
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch2_611C
	SND_CALL Snd58_Ch2_605E
Snd58_Ch2_60A8:
	RELEASE 1, $0E
Snd58_Ch1_60AA:
	ATTEN 0
	TRANSPOSE_DOWN $0C
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_RET
Snd58_Ch1_60C3:
	LEN_UNIT 1
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
	ATTEN 0
	LEN_UNIT 5
	SND_RET
Snd58_Ch1_60D9:
	LEN_UNIT 1
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
	SND_RET
Snd58_Ch1_60EC:
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
Snd58_Ch1_60F7:
	ATTEN 0
	LEN_UNIT 5
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D#, 1
	SND_REPEAT 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE A#, 1
	SND_RET
Snd58_Ch1_610E:
	SND_SEGNO
	NOTE A#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_REPEAT 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	SND_RET
Snd58_Ch2_611C:
	VOICE 5, $0F, 0, 1, $0F
	PAN $0F
	AUTOPAN 2
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT $10
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT 8
	PAN $FF
	AUTOPAN 0
	ATTEN 0
	LEN_UNIT 5
	RELEASE $0F, 0
	TRANSPOSE_UP 0
	REST 4
	SND_RET

Snd57_Ch1:
	VIBRATO 2
	VOICE 8, 2, 8, $0F, 0
	OCTAVE 1
	NOTE C_, $0E
	NOTE C_, 4
	OCTAVE 1
	NOTE C_, $0E
	NOTE C_, 4
	SND_END

Snd58_Ch1:
	VIBRATO $0E
	VOICE 5, 2, 8, 8, 8
	REST 1
Snd58_Ch1_6155:
	VOICE 5, 2, 8, 8, 8
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch1_60C3
	SND_CALL Snd58_Ch1_60D9
	SND_CALL Snd58_Ch1_60D9
	SND_CALL Snd58_Ch1_60EC
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_60F7
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_610E
	SND_CALL Snd58_Ch1_61A3
	SND_CALL Snd58_Ch1_61C0
	TRANSPOSE_DOWN 1
	SND_CALL Snd58_Ch1_61A3
	SND_CALL Snd58_Ch1_61DD
	SND_CALL Snd58_Ch1_6155
Snd58_Ch1_61A3:
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_RET
Snd58_Ch1_61C0:
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_RET
Snd58_Ch1_61DD:
	LEN_UNIT 5
	TRANSPOSE_UP 0
	REST 4
	SND_RET

Snd57_Ch3:
	VIBRATO 1
	VOICE 4, 4, 6, $0F, 0
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT 7
	REST 8
	SND_SEGNO
	OCTAVE 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_REPEAT 7
	REST 8
	SND_END

Snd58_Ch3:
	VIBRATO 0
	VOICE 5, 2, 6, 4, 8
Snd58_Ch3_6202:
	PAN $0F
	AUTOPAN 2
	VOICE 5, 2, 6, 4, 8
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch3_626A
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch3_626A
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch3_626A
	SND_CALL Snd58_Ch1_60AA
	SND_CALL Snd58_Ch3_626A
	ATTEN 2
	PAN $FF
	AUTOPAN 0
	SND_CALL Snd58_Ch1_60D9
	SND_CALL Snd58_Ch1_60D9
	SND_CALL Snd58_Ch1_60EC
	ATTEN 0
	SND_CALL Snd58_Ch3_6249
	TRANSPOSE_UP 0
	WAVE 4
	SND_CALL Snd58_Ch1_61A3
	SND_CALL Snd58_Ch1_61C0
	TRANSPOSE_DOWN 1
	SND_CALL Snd58_Ch1_61A3
	SND_CALL Snd58_Ch1_61DD
	SND_CALL Snd58_Ch3_6202
Snd58_Ch3_6249:
	VOICE 5, 2, 6, $0F, 0
	VIBRATO 3
	OCTAVE 2
	NOTE G#, 8
	NOTE G#, 3
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE C#, 8
	NOTE C#, 7
	OCTAVE 2
	NOTE G#, 1
	NOTE G_, 8
	NOTE G_, 8
	NOTE G_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE G#, 3
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE C#, 8
	NOTE G#, 8
	NOTE G_, 8
	NOTE G_, 8
	NOTE G_, 8
	NOTE G_, 8
	SND_RET
Snd58_Ch3_626A:
	LEN_UNIT 1
	REST $0F
	LEN_UNIT 5
	SND_RET

Snd57_Drm:
	DRUM_UNIT $0F
	REST $0E
	REST 4
	REST $0E
	REST 4
	DRUM_UNIT 5
	SND_END

Snd58_Drm:
	DRUM_UNIT 5
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
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
	SND_REPEAT $0E
	DRUM_UNIT 2
	REST $0A
	DRUM_UNIT 5
	SND_CALL Snd58_Drm

Snd5D_Ch3:
	TEMPO $25
	VIBRATO 4
	TRANSPOSE_DOWN $0C
	VOICE 4, 2, 2, 4, $0F
	SND_CALL Snd5D_Ch1_62E9
Snd5D_Ch3_62C1:
	SND_CALL Snd5D_Ch1_6306
	SND_CALL Snd5D_Ch3_6353
	SND_CALL Snd5D_Ch3_6357
	SND_CALL Snd5D_Ch3_62C1

Snd5D_Ch1:
	TRANSPOSE_DOWN $0C
	VIBRATO $0E
	VOICE 4, 3, 8, $0F, 0
	REST 2
	SND_CALL Snd5D_Ch1_62E9
Snd5D_Ch1_62D9:
	VOICE 4, 2, 8, $0F, 0
	SND_CALL Snd5D_Ch1_6306
	SND_CALL Snd5D_Ch1_6355
	SND_CALL Snd5D_Ch1_6376
	SND_CALL Snd5D_Ch1_62D9
Snd5D_Ch1_62E9:
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	SND_RET
Snd5D_Ch1_6306:
	RELEASE 4, $0F
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 5
	NOTE C#, 4
	RELEASE $0F, 0
	OCTAVE 4
	NOTE B_, $0C
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 4
	RELEASE 5, $0F
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 0
	NOTE F#, 4
	NOTE A_, 4
	LEN_UNIT 8
	NOTE G#, 9
	RELEASE 4, $0F
	LEN_UNIT 4
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	RELEASE 8, 8
	NOTE B_, $0A
	RELEASE 4, $0F
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	RELEASE 8, 8
	NOTE D_, $0A
	RELEASE 4, $0F
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 0
	LEN_UNIT 8
	NOTE F#, 8
	LEN_UNIT 4
	OCTAVE 4
	NOTE F#, $0C
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE B_, $0C
	RELEASE 4, $0F
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D_, 2
	REST 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 4
	SND_RET
Snd5D_Ch3_6353:
	NOTE A_, 4
	SND_RET
Snd5D_Ch1_6355:
	NOTE A_, 2
	SND_RET
Snd5D_Ch3_6357:
	RELEASE $0F, 0
	LEN_UNIT 8
	NOTE G#, $0C
	LEN_UNIT 4
	OCTAVE 4
	NOTE A_, 4
	OCTAVE 5
	NOTE G#, 4
	OCTAVE 4
	NOTE G#, 8
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 5
	NOTE E_, 4
	OCTAVE 4
	NOTE E_, 4
	REST 4
	OCTAVE 4
	NOTE D#, 4
	OCTAVE 5
	NOTE C#, 4
	LEN_UNIT $10
	OCTAVE 4
	NOTE C#, 8
	LEN_UNIT 4
	SND_RET
Snd5D_Ch1_6376:
	VOICE 4, 4, 8, $0F, 0
	VIBRATO 3
	LEN_UNIT 8
	NOTE F#, $0C
	LEN_UNIT 4
	OCTAVE 4
	NOTE F#, 4
	OCTAVE 5
	NOTE E_, 4
	OCTAVE 4
	NOTE F#, 8
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE C#, 4
	REST 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE A_, 4
	LEN_UNIT $10
	OCTAVE 3
	NOTE G#, 8
	LEN_UNIT 4
	REST 2
	SND_RET

Snd5D_Ch2:
	PAN $0F
	AUTOPAN 2
	DUTY_STEP 0, 1
	VOICE 4, $0A, 8, 2, $0C
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
Snd5D_Ch2_63C0:
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE A_, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE C#, 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE E_, 2
	SND_REPEAT 3
	OCTAVE 2
	NOTE C#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE B_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G#, 2
	SND_REPEAT 4
	SND_CALL Snd5D_Ch2_63C0
	db $FF

Snd5D_Drm:
	SND_END

Snd5E_Ch2:
	TEMPO $20
	VIBRATO 3
	VOICE $0E, 8, 4, 1, $0E
	REST 8
	REST 8

Snd5F_Ch2:
	TEMPO $20
	SND_SEGNO
	VOICE 7, 8, 4, 1, $0E
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 7
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 0
	RELEASE 5, 8
	NOTE F_, 3
	OCTAVE 2
	NOTE C_, 3
	SND_REPEAT 4
	LEN_UNIT $0E
	RELEASE $0F, 0
	SND_SEGNO
	OCTAVE 3
	ATTEN 7
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 5
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	OCTAVE 3
	ATTEN 7
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	OCTAVE 3
	ATTEN 7
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 8
	SND_REPEAT 2
	SND_CALL Snd5F_Ch2

Snd5E_Ch1:
	VIBRATO $0E
	VOICE $0E, 5, 8, 4, $0E
	REST 8
	REST 8

Snd5F_Ch1:
	VOICE 7, 5, 8, 4, $0E
	SND_SEGNO
	ATTEN 3
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 3
	OCTAVE 2
	NOTE C_, 2
	SND_REPEAT 4
	LEN_UNIT $0E
	RELEASE $0F, 0
	SND_SEGNO
	OCTAVE 3
	ATTEN 4
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 4
	OCTAVE 3
	ATTEN 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 4
	OCTAVE 2
	ATTEN 4
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 4
	NOTE A#, 8
	SND_REPEAT 2
	SND_CALL Snd5F_Ch1

Snd5E_Ch3:
	PAN $0F
	AUTOPAN 2
	VOICE $0E, 2, 2, 5, $0F
	REST 8
	REST 8

Snd5F_Ch3:
	VOICE 7, 2, 2, 5, $0F
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	REST 8
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 3
	RELEASE 8, 8
	NOTE F_, 3
	OCTAVE 2
	NOTE C_, 3
	RELEASE 5, $0F
	SND_REPEAT 8
	SND_CALL Snd5F_Ch3

Snd5E_Drm:
	DRUM_UNIT $0E
	REST $0C
	DRUM_UNIT 7
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT 8

Snd5F_Drm:
	DRUM_UNIT 7
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd5F_Drm

Snd5C_Ch2:
	VIBRATO 3
	TRANSPOSE_DOWN $0C
	VOICE 8, 8, 0, 1, 9
	SND_SEGNO
	SND_CALL Snd5C_Ch2_65DE
	SND_CALL Snd5C_Ch2_65F6
	SND_CALL Snd5C_Ch2_65DE
	SND_CALL Snd5C_Ch2_65FA
	SND_CALL Snd5C_Ch2_65FE
	SND_CALL Snd5C_Ch2_6613
	SND_CALL Snd5C_Ch2_65FE
	SND_CALL Snd5C_Ch2_661A
	SND_REPEAT 2
	SND_CALL Snd5C_Ch2_6621
Snd5C_Ch2_65DE:
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	SND_RET
Snd5C_Ch2_65F6:
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	SND_RET
Snd5C_Ch2_65FA:
	OCTAVE 3
	NOTE B_, 1
	NOTE F#, 1
	SND_RET
Snd5C_Ch2_65FE:
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	SND_RET
Snd5C_Ch2_6613:
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F#, 1
	SND_RET
Snd5C_Ch2_661A:
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	SND_RET
Snd5C_Ch2_6621:
	VIBRATO $0C
	VOICE 8, 8, 0, $0F, 0
	TRANSPOSE_UP 8
	SND_CALL Snd5C_Ch2_6677
	SND_CALL Snd5C_Ch2_6689
	SND_CALL Snd5C_Ch2_6677
	SND_CALL Snd5C_Ch2_66A1
	SND_SEGNO
	SND_CALL Snd5C_Ch2_6677
	SND_CALL Snd5C_Ch2_6689
	SND_REPEAT 2
	TRANSPOSE_UP 0
	VIBRATO $0B
	VOICE 8, 6, 8, $0F, 0
	SND_CALL Snd5C_Ch2_66BA
	SND_CALL Snd5C_Ch2_66C2
	SND_CALL Snd5C_Ch2_66BA
	SND_CALL Snd5C_Ch2_66C8
	VIBRATO $0C
	SND_CALL Snd5C_Ch2_66CF
	VIBRATO 3
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_6738
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_674F
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_6738
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_675F
	SND_CALL Snd5C_Ch2_676F
	SND_CALL Snd5C_Ch2_6621
Snd5C_Ch2_6677:
	OCTAVE 2
	NOTE C#, $0D
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	RELEASE 3, 9
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 1
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 1
	SND_RET
Snd5C_Ch2_6689:
	ATTEN 0
	NOTE F#, 3
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	OCTAVE 2
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 1
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	RELEASE $0F, 0
	LEN_UNIT $20
	OCTAVE 2
	NOTE C#, 8
	LEN_UNIT 8
	SND_RET
Snd5C_Ch2_66A1:
	ATTEN 0
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	NOTE F#, 2
	LEN_UNIT $10
	RELEASE $0F, 0
	NOTE G#, $0C
	NOTE F#, 4
	LEN_UNIT 8
	SND_RET
Snd5C_Ch2_66BA:
	OCTAVE 1
	NOTE F_, 8
	OCTAVE 1
	NOTE F_, 3
	NOTE A_, 3
	OCTAVE 2
	NOTE C_, 2
	SND_RET
Snd5C_Ch2_66C2:
	OCTAVE 1
	NOTE E_, 8
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 2
	SND_RET
Snd5C_Ch2_66C8:
	OCTAVE 2
	NOTE E_, 8
	NOTE B_, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE C_, 2
	SND_RET
Snd5C_Ch2_66CF:
	TRANSPOSE_DOWN $0C
	VOICE 8, 8, 4, 4, 5
Snd5C_Ch1_66D5:
	TRANSPOSE_DOWN $0C
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F_, 1
	SND_REPEAT 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	SND_SEGNO
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE E_, 1
	SND_REPEAT 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G#, 1
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	SND_REPEAT 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	TRANSPOSE_UP 0
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE $0F, 0
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 5, 8
	SND_RET
Snd5C_Ch1_6724:
	TRANSPOSE_UP 0
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 2
	SND_RET
Snd5C_Ch1_6738:
	NOTE A_, 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 3
	RELEASE 1, 9
	REST 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	RELEASE 5, 8
	SND_RET
Snd5C_Ch1_674F:
	NOTE A_, 9
	OCTAVE 4
	NOTE E_, 1
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
	NOTE G_, 1
	SND_RET
Snd5C_Ch1_675F:
	NOTE A#, 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 3
	SND_RET
Snd5C_Ch2_676F:
	VIBRATO 3
Snd5C_Ch1_6771:
	RELEASE $0F, 0
	NOTE F#, 8
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE F_, 8
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 2
	NOTE F#, 8
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 2
	RELEASE 3, $0D
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0F, 0
	SND_RET

Snd5C_Ch1:
	DUTY_STEP 0, 1
	TRANSPOSE_DOWN $0C
	VIBRATO $0E
	VOICE 8, 2, 8, $0F, 0
	SND_SEGNO
	SND_CALL Snd5C_Ch1_67C1
	SND_CALL Snd5C_Ch1_67D8
	SND_CALL Snd5C_Ch1_67C1
	SND_CALL Snd5C_Ch1_67DA
	SND_CALL Snd5C_Ch1_67DD
	SND_CALL Snd5C_Ch1_67F1
	SND_CALL Snd5C_Ch1_67DD
	SND_CALL Snd5C_Ch1_67F7
	SND_REPEAT 2
	REST 1
	SND_CALL Snd5C_Ch1_67FD
Snd5C_Ch1_67C1:
	OCTAVE 4
	NOTE E_, 2
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	SND_RET
Snd5C_Ch1_67D8:
	NOTE C#, 2
	SND_RET
Snd5C_Ch1_67DA:
	OCTAVE 3
	NOTE B_, 2
	SND_RET
Snd5C_Ch1_67DD:
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
Snd5C_Ch1_67F1:
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	SND_RET
Snd5C_Ch1_67F7:
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE F#, 1
	NOTE G#, 1
	SND_RET
Snd5C_Ch1_67FD:
	DUTY_STEP 0, 0
	VIBRATO $0F
	TRANSPOSE_UP 8
	VOICE 8, 2, 8, $0F, 0
	SND_CALL Snd5C_Ch1_6844
	SND_CALL Snd5C_Ch1_684F
	SND_CALL Snd5C_Ch1_6844
	SND_CALL Snd5C_Ch1_685B
	SND_SEGNO
	SND_CALL Snd5C_Ch1_6844
	SND_CALL Snd5C_Ch1_684F
	SND_REPEAT 2
	TRANSPOSE_UP 0
	VIBRATO $0E
	SND_CALL Snd5C_Ch1_6924
	SND_CALL Snd5C_Ch1_66D5
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_6738
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_674F
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_6738
	SND_CALL Snd5C_Ch1_6724
	SND_CALL Snd5C_Ch1_675F
	SND_CALL Snd5C_Ch1_6771
	SND_CALL Snd5C_Ch1_67FD
Snd5C_Ch1_6844:
	OCTAVE 2
	NOTE C#, $0D
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	NOTE D#, 3
	OCTAVE 1
	NOTE B_, 3
	SND_RET
Snd5C_Ch1_684F:
	NOTE F#, 4
	OCTAVE 2
	NOTE D#, 3
	OCTAVE 1
	NOTE B_, 3
	LEN_UNIT $20
	OCTAVE 2
	NOTE C#, 8
	LEN_UNIT 8
	SND_RET
Snd5C_Ch1_685B:
	NOTE F#, 2
	OCTAVE 3
	NOTE D#, 3
	OCTAVE 2
	NOTE B_, 3
	NOTE F#, 2
	LEN_UNIT $10
	NOTE G#, $0C
	NOTE F#, 4
	LEN_UNIT 8
	SND_RET

Snd5C_Ch3:
	TRANSPOSE_UP 0
	VOICE $10, 2, 2, $0F, 0
	OCTAVE 2
	NOTE C#, 8
	NOTE C#, 8
	OCTAVE 1
	NOTE A_, 8
	NOTE A_, 8
	OCTAVE 2
	NOTE C#, 8
	NOTE C#, 8
	OCTAVE 1
	NOTE A_, 8
	NOTE A_, 4
	VOICE 8, 2, 6, 1, $0D
	PAN $0F
	AUTOPAN 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	PAN $FF
	AUTOPAN 0
	RELEASE 3, $0D
	TRANSPOSE_UP 0
Snd5C_Ch3_6893:
	VIBRATO 3
	VOICE 8, 2, 6, 3, $0D
	PAN $0F
	AUTOPAN 2
	TRANSPOSE_DOWN 4
	SND_CALL Snd5C_Ch3_68EA
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68FE
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_68EA
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68FE
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68EA
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_68FE
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_68F4
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_6908
	SND_CALL Snd5C_Ch3_6912
	SND_CALL Snd5C_Ch3_68FE
	SND_CALL Snd5C_Ch3_68FE
	SND_CALL Snd5C_Ch3_691C
	SND_CALL Snd5C_Ch3_6956
Snd5C_Ch3_68EA:
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	SND_REPEAT 4
	SND_RET
Snd5C_Ch3_68F4:
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_68FE:
	SND_SEGNO
	OCTAVE 1
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	SND_REPEAT 4
	SND_RET
Snd5C_Ch3_6908:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_6912:
	SND_SEGNO
	OCTAVE 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	SND_REPEAT 4
	SND_RET
Snd5C_Ch3_691C:
	PAN $FF
	AUTOPAN 0
	VOICE 8, 2, 4, 2, 5
Snd5C_Ch1_6924:
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE B_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_6956:
	TRANSPOSE_UP 0
	VOICE 8, 2, 9, $0F, 0
	OCTAVE 1
	NOTE F_, 8
	OCTAVE 1
	NOTE F_, 3
	NOTE A_, 3
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE E_, 8
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 8
	NOTE G_, 3
	OCTAVE 1
	NOTE B_, 3
	OCTAVE 2
	NOTE D_, 2
	VOICE 8, 2, 6, 3, $0D
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	SND_CALL Snd5C_Ch3_6998
	SND_CALL Snd5C_Ch3_69C8
	SND_CALL Snd5C_Ch3_6998
	SND_CALL Snd5C_Ch3_69F0
	SND_CALL Snd5C_Ch3_6A15
Snd5C_Ch3_6998:
	TRANSPOSE_UP 0
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	SND_RET
Snd5C_Ch3_69C8:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	SND_RET
Snd5C_Ch3_69F0:
	SND_SEGNO
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_6A15:
	PAN $FF
	AUTOPAN 0
	RELEASE 2, $0D
	TRANSPOSE_DOWN $0C
	SND_CALL Snd5C_Ch3_6A2C
	SND_CALL Snd5C_Ch3_6A3E
	SND_CALL Snd5C_Ch3_6A2C
	SND_CALL Snd5C_Ch3_6A50
	SND_CALL Snd5C_Ch3_6893
Snd5C_Ch3_6A2C:
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_6A3E:
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	SND_REPEAT 2
	SND_RET
Snd5C_Ch3_6A50:
	PAN $0F
	AUTOPAN 2
	TRANSPOSE_UP 0
	RELEASE 3, $0D
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	RELEASE $0F, 0
	SND_RET

Snd5C_Drm:
	DRUM_UNIT $40
	DRUM 3, 8
	DRUM 3, 8
	DRUM_UNIT 8
	SND_SEGNO
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $1C
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT 8
Snd5C_Drm_6A82:
	DRUM_UNIT 8
	SND_SEGNO
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_REPEAT 3
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AE2
	SND_CALL Snd5C_Drm_6AEB
	SND_SEGNO
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_REPEAT 2
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6AD9
	SND_CALL Snd5C_Drm_6AC0
	SND_CALL Snd5C_Drm_6B16
	SND_CALL Snd5C_Drm_6A82
Snd5C_Drm_6AC0:
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	SND_RET
Snd5C_Drm_6AD9:
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	SND_RET
Snd5C_Drm_6AE2:
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5C_Drm_6AEB:
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT 6
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT 2
	SND_SEGNO
	DRUM_UNIT 8
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_REPEAT 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5C_Drm_6B16:
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT 8
	SND_RET

Snd60_Ch2:
	TEMPO $37
	VIBRATO 3
	TRANSPOSE_DOWN 4
	VOICE 6, 8, 4, 3, 8
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B7B
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B95
	SND_CALL Snd60_Ch2_6BB1
	SND_CALL Snd60_Ch2_6BB8
Snd60_Ch1_6B4F:
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	REST 2
	SND_RET
Snd60_Ch1_6B54:
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 5
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F#, 5
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	SND_RET
Snd60_Ch3_6B65:
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 5
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F#, 5
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	SND_RET
Snd60_Ch1_6B76:
	NOTE C_, 1
	NOTE F_, 4
	NOTE D_, 3
	NOTE E_, 2
	SND_RET
Snd60_Ch1_6B7B:
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	SND_RET
Snd60_Ch3_6B88:
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	SND_RET
Snd60_Ch1_6B95:
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_RET
Snd60_Ch3_6BA3:
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_RET
Snd60_Ch2_6BB1:
	RELEASE 5, $0F
	ATTEN 3
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	SND_RET
Snd60_Ch2_6BB8:
	DUTY_STEP 8, 2
	PAN $0F
	AUTOPAN 2
	TRANSPOSE_DOWN 4
	DUTY_STEP 0, 2
	VOICE 6, $0F, 0, $0F, 0
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C5F
	SND_CALL Snd60_Ch2_6C5F
	SND_CALL Snd60_Ch2_6C6A
	SND_CALL Snd60_Ch2_6C76
	SND_REPEAT 2
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C83
	SND_REPEAT 4
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C8C
	SND_REPEAT 4
	SND_CALL Snd60_Ch2_6C93
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C76
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C83
	SND_REPEAT 4
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C8C
	SND_REPEAT 4
	SND_CALL Snd60_Ch2_6C93
	SND_CALL Snd60_Ch2_6CA5
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C5F
	SND_CALL Snd60_Ch2_6C5F
	SND_CALL Snd60_Ch2_6C6A
	SND_CALL Snd60_Ch2_6C76
	SND_REPEAT 2
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C83
	SND_REPEAT 4
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C8C
	SND_REPEAT 4
	SND_CALL Snd60_Ch2_6C93
	SND_CALL Snd60_Ch2_6C50
	SND_CALL Snd60_Ch2_6C76
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C83
	SND_REPEAT 4
	SND_SEGNO
	SND_CALL Snd60_Ch2_6C8C
	SND_REPEAT 4
	SND_CALL Snd60_Ch2_6C93
	SND_CALL Snd60_Ch2_6CB9
	SND_CALL Snd60_Ch2_6CCE

; Unreferenced SND_CALL.
Orphan_6C4D:
	db $FD, $B8, $6B
Snd60_Ch2_6C50:
	RELEASE $0F, 0
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	SND_RET
Snd60_Ch2_6C5F:
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G_, 1
	SND_RET
Snd60_Ch2_6C6A:
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_RET
Snd60_Ch2_6C76:
	OCTAVE 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	SND_RET
Snd60_Ch2_6C83:
	RELEASE 1, $0F
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_RET
Snd60_Ch2_6C8C:
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_RET
Snd60_Ch2_6C93:
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_RET
Snd60_Ch2_6CA5:
	RELEASE 1, $0F
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_RET
Snd60_Ch2_6CB9:
	RELEASE 1, $0F
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_RET
Snd60_Ch2_6CCE:
	PAN $FF
	AUTOPAN 0
	DUTY_STEP 8, 1
	VIBRATO 3
	VOICE 6, $0A, 4, $0F, 0
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D00
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D11
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D1A
	SND_CALL Snd60_Ch2_6BB8
Snd60_Ch1_6CEF:
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 3
	NOTE A_, 3
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_RET
Snd60_Ch1_6D00:
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 3
	NOTE E_, 1
	SND_RET
Snd60_Ch1_6D11:
	NOTE E_, 2
	NOTE F_, 1
	NOTE D_, 3
	NOTE D_, 2
	NOTE E_, 1
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 5
	SND_RET
Snd60_Ch1_6D1A:
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 3
	NOTE D_, 3
	NOTE G_, 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 8
	SND_RET

Snd60_Ch1:
	VIBRATO $0E
	TRANSPOSE_DOWN 4
	VOICE 6, 3, 0, $0F, 0
	REST 1
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B7B
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch1_6B54
	SND_CALL Snd60_Ch1_6B95
	LEN_UNIT 1
	OCTAVE 3
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
	SND_CALL Snd60_Ch1_6D9A
Snd60_Ch1_6D9A:
	TRANSPOSE_DOWN 4
	VIBRATO $0E
	VOICE 6, 3, 8, $0F, 0
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E90
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E9B
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EBB
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EC5
	SND_CALL Snd60_Ch1_6EC9
	SND_CALL Snd60_Ch1_6EDC
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E90
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E9B
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EBB
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EC5
	SND_CALL Snd60_Ch1_6EC9
	SND_CALL Snd60_Ch1_6EE1
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D00
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D11
	SND_CALL Snd60_Ch1_6CEF
	SND_CALL Snd60_Ch1_6D1A
	SND_CALL Snd60_Ch1_6D9A

Snd60_Ch3:
	VIBRATO 3
	TRANSPOSE_DOWN 4
	VOICE 6, 2, 9, $0F, 0
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch3_6B65
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch3_6B65
	SND_CALL Snd60_Ch3_6B88
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch3_6B65
	SND_CALL Snd60_Ch1_6B76
	SND_CALL Snd60_Ch1_6B4F
	SND_CALL Snd60_Ch3_6B65
	SND_CALL Snd60_Ch3_6BA3
	REST 4
	SND_CALL Snd60_Ch3_6E23
Snd60_Ch3_6E23:
	PAN $FF
	AUTOPAN 0
	TRANSPOSE_DOWN 4
	VIBRATO 3
	VOICE 6, 2, $0C, $0F, 0
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E90
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E9B
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EBB
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EC5
	SND_CALL Snd60_Ch1_6EC9
	SND_CALL Snd60_Ch1_6EDC
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E90
	SND_CALL Snd60_Ch1_6E6E
	SND_CALL Snd60_Ch1_6E9B
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EBB
	SND_CALL Snd60_Ch1_6EA7
	SND_CALL Snd60_Ch1_6EC5
	SND_CALL Snd60_Ch1_6EC9
	SND_CALL Snd60_Ch1_6EE1
	SND_CALL Snd60_Ch3_6EE7
Snd60_Ch1_6E6E:
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 3
	NOTE D#, 4
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, $0C
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 3
	NOTE B_, 3
	NOTE A_, $0A
	NOTE D_, 3
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 4
	SND_RET
Snd60_Ch1_6E90:
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	SND_RET
Snd60_Ch1_6E9B:
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_RET
Snd60_Ch1_6EA7:
	OCTAVE 4
	NOTE G_, 3
	NOTE F_, 3
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 4
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 3
	NOTE E_, 3
	OCTAVE 3
	NOTE G#, 8
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 3
	NOTE D_, 3
	OCTAVE 3
	NOTE F#, 8
	SND_RET
Snd60_Ch1_6EBB:
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 8
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE B_, 3
	NOTE A_, 2
	SND_RET
Snd60_Ch1_6EC5:
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	SND_RET
Snd60_Ch1_6EC9:
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_RET
Snd60_Ch1_6EDC:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET
Snd60_Ch1_6EE1:
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_RET
Snd60_Ch3_6EE7:
	PAN $0F
	AUTOPAN 2
	RELEASE 5, $0F
	SND_CALL Snd60_Ch3_6F17
	SND_CALL Snd60_Ch3_6F21
	SND_CALL Snd60_Ch3_6F2E
	SND_CALL Snd60_Ch3_6F17
	SND_CALL Snd60_Ch3_6F21
	SND_CALL Snd60_Ch3_6F2E
	SND_CALL Snd60_Ch3_6F17
	SND_CALL Snd60_Ch3_6F38
	SND_CALL Snd60_Ch3_6F45
	SND_CALL Snd60_Ch3_6F4F
	SND_CALL Snd60_Ch3_6F45
	SND_CALL Snd60_Ch3_6F45
	SND_CALL Snd60_Ch3_6F59
	SND_CALL Snd60_Ch3_6E23
Snd60_Ch3_6F17:
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT 4
	SND_RET
Snd60_Ch3_6F21:
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_RET
Snd60_Ch3_6F2E:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_RET
Snd60_Ch3_6F38:
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd60_Ch3_6F45:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_RET
Snd60_Ch3_6F4F:
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 4
	SND_RET
Snd60_Ch3_6F59:
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 8
	SND_RET

Snd60_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 3, 4
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 3, 4
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT 8
	DRUM 3, 4
Snd60_Drm_6F90:
	SND_SEGNO
	SND_CALL Snd60_Drm_6FD9
	SND_REPEAT 7
	SND_CALL Snd60_Drm_6FEA
	SND_SEGNO
	SND_CALL Snd60_Drm_6FD9
	SND_REPEAT 7
	SND_CALL Snd60_Drm_6FFB
	SND_SEGNO
	SND_CALL Snd60_Drm_6FD9
	SND_REPEAT 7
	SND_CALL Snd60_Drm_6FEA
	SND_SEGNO
	SND_CALL Snd60_Drm_6FD9
	SND_REPEAT 7
	SND_CALL Snd60_Drm_6FFB
	SND_SEGNO
	SND_CALL Snd60_Drm_6FD9
	SND_CALL Snd60_Drm_7006
	SND_REPEAT 3
	SND_CALL Snd60_Drm_6FD9
	SND_CALL Snd60_Drm_6FD9
	SND_CALL Snd60_Drm_7017
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM_UNIT 6
	SND_CALL Snd60_Drm_6F90
Snd60_Drm_6FD9:
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	SND_RET
Snd60_Drm_6FEA:
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd60_Drm_6FFB:
	SND_SEGNO
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_REPEAT 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd60_Drm_7006:
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
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd60_Drm_7017:
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET

Snd61_Ch2:
	TEMPO $20
	TRANSPOSE_DOWN $0C
	VOICE $10, 8, 4, 4, 8
Snd61_Ch2_7030:
	SND_CALL Snd61_Ch1_7045
	SND_CALL Snd61_Ch2_7030

Snd61_Ch1:
	TRANSPOSE_DOWN $0C
	VIBRATO $0E
	VOICE $10, 2, 8, $0F, 0
	REST 1
Snd61_Ch1_703F:
	SND_CALL Snd61_Ch1_7045
	SND_CALL Snd61_Ch1_703F
Snd61_Ch1_7045:
	SND_SEGNO
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	SND_REPEAT 2
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE D#, 1
	SND_RET

Snd61_Ch3:
	TRANSPOSE_DOWN $0C
	VIBRATO 3
	VOICE $10, 2, 9, $0F, 0
	OCTAVE 3
	NOTE C#, 6
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 8
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 8
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D#, 8
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	SND_CALL Snd61_Ch3

Snd61_Drm:
	SND_END

Snd62_Ch2:
	TEMPO $10
	VIBRATO 3
	VOICE 6, 8, 8, 1, $0E
	REST 8
Snd62_Ch2_70A1:
	VOICE 6, 8, 8, 1, $0E
	SND_CALL Snd62_Ch2_70E0
	TRANSPOSE_DOWN $0C
	VOICE 6, 8, 4, $0F, 0
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	TRANSPOSE_UP 0
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	SND_CALL Snd62_Ch2_7142
	SND_CALL Snd62_Ch2_7164
	SND_CALL Snd62_Ch1_7168
	TRANSPOSE_UP $0C
	SND_CALL Snd62_Ch1_7168
	TRANSPOSE_DOWN $0C
	SND_CALL Snd62_Ch2_7199
	TRANSPOSE_UP 0
	SND_CALL Snd62_Ch2_70A1
Snd62_Ch2_70E0:
	RELEASE 3, $0E
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0F, 0
	NOTE C_, 1
	RELEASE 3, $0E
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT 4
	SND_RET
Snd62_Ch1_710B:
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 1
	NOTE D_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 8
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 1
	NOTE D_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	SND_RET
Snd62_Ch1_7140:
	NOTE E_, 1
	SND_RET
Snd62_Ch2_7142:
	DUTY $0C
	SND_SEGNO
	OCTAVE 4
	NOTE F_, $0A
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 3
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 5
	NOTE E_, 4
	SND_REPEAT 3
	OCTAVE 4
	NOTE F_, $0A
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 3
	OCTAVE 4
	NOTE E_, 1
	SND_RET
Snd62_Ch2_7164:
	NOTE D_, 7
	SND_RET
Snd62_Ch1_7166:
	REST 1
	SND_RET
Snd62_Ch1_7168:
	SND_SEGNO
	RELEASE 5, $0E
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE A#, 2
	RELEASE 5, $0E
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE A#, 6
	RELEASE 1, $0E
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	RELEASE $0F, 0
	NOTE C_, 2
	SND_REPEAT 2
	SND_RET
Snd62_Ch2_7199:
	NOTE C_, 2
	SND_RET
Snd62_Ch1_719B:
	NOTE C_, 1
	SND_RET
Snd62_Ch3_719D:
	SND_SEGNO
	RELEASE 3, $0F
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE A#, 2
	RELEASE 3, $0F
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	RELEASE $0F, 0
	NOTE C_, 2
	SND_REPEAT 4
	NOTE C_, 2
	SND_RET

Snd62_Ch1:
	VOICE 6, 6, 0, 3, $0E
	REST 8
Snd62_Ch1_71CF:
	VOICE 6, 5, 0, 3, $0E
	VIBRATO $0E
	SND_CALL Snd62_Ch1_71F9
	TRANSPOSE_DOWN $0C
	VOICE 6, 2, 8, $0F, 0
	REST 1
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	TRANSPOSE_UP 0
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7140
	SND_CALL Snd62_Ch1_710B
	SND_CALL Snd62_Ch1_7222
Snd62_Ch1_71F9:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	RELEASE $0F, 0
	NOTE G_, 1
	RELEASE 3, $0E
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
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_REPEAT 4
	SND_RET
Snd62_Ch1_7222:
	VIBRATO 3
	VOICE 6, 4, 8, $0F, 0
	SND_CALL Snd62_Ch1_7255
	SND_CALL Snd62_Ch1_7264
	SND_CALL Snd62_Ch1_7255
	SND_CALL Snd62_Ch1_7261
	SND_CALL Snd62_Ch1_7255
	SND_CALL Snd62_Ch1_7264
	SND_CALL Snd62_Ch1_7255
	SND_CALL Snd62_Ch1_7267
	SND_CALL Snd62_Ch1_7166
	SND_CALL Snd62_Ch1_7168
	TRANSPOSE_UP $0C
	SND_CALL Snd62_Ch1_7168
	TRANSPOSE_DOWN $0C
	SND_CALL Snd62_Ch1_719B
	TRANSPOSE_UP 0
	SND_CALL Snd62_Ch1_71CF
Snd62_Ch1_7255:
	OCTAVE 3
	NOTE A#, $0A
	OCTAVE 4
	NOTE F_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 3
	NOTE G_, 1
	SND_RET
Snd62_Ch1_7261:
	NOTE B_, 5
	NOTE A_, 4
	SND_RET
Snd62_Ch1_7264:
	NOTE F#, 5
	NOTE A_, 4
	SND_RET
Snd62_Ch1_7267:
	NOTE B_, 7
	SND_RET

Snd62_Ch3:
	TRANSPOSE_UP 0
	VOICE 6, 2, 6, 3, $0F
	REST 8
Snd62_Ch3_7270:
	VOICE 6, 2, 6, 3, $0F
	SND_CALL Snd62_Ch2_70E0
	SND_CALL Snd62_Ch3_7298
	SND_CALL Snd62_Ch3_72EF
	SND_CALL Snd62_Ch3_730B
	SND_CALL Snd62_Ch3_72EF
	SND_CALL Snd62_Ch3_7318
	SND_CALL Snd62_Ch3_72EF
	SND_CALL Snd62_Ch3_730B
	SND_CALL Snd62_Ch3_72EF
	SND_CALL Snd62_Ch3_7324
	SND_CALL Snd62_Ch3_719D
	SND_CALL Snd62_Ch3_7270
Snd62_Ch3_7298:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0F, 0
	OCTAVE 1
	NOTE A#, 1
	RELEASE 3, $0F
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 4
	SND_RET
Snd62_Ch3_72EF:
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	SND_RET
Snd62_Ch3_730B:
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_RET
Snd62_Ch3_7318:
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	SND_RET
Snd62_Ch3_7324:
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_RET

Snd62_Drm:
	DRUM_UNIT 6
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM_UNIT 3
	SND_SEGNO
	DRUM 8, 1
	SND_REPEAT 8
Snd62_Drm_7339:
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
	SND_REPEAT 7
	SND_SEGNO
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_REPEAT 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd62_Drm_7339

Snd63_Ch3:
	TEMPO $50
	VIBRATO $0D
	VOICE $0F, 2, 4, $0F, 0
	OCTAVE 3
	NOTE E_, 3
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	SND_CALL Snd63_Ch3

Snd63_Ch1:
	VIBRATO $0E
	VOICE 8, 2, 8, $0F, 0
	REST 1
Snd63_Ch1_7386:
	VOICE $0F, 2, 8, 5, $0A
	SND_CALL Snd63_Ch1_73A0
	SND_CALL Snd63_Ch1_7386

Snd63_Ch2:
	DUTY_STEP 0, 2
	PAN $0F
	AUTOPAN 2
	VOICE $0F, 8, 8, 3, $0F
	SND_CALL Snd63_Ch1_73A0
	SND_CALL Snd63_Ch2
Snd63_Ch1_73A0:
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	SND_RET

Snd63_Drm:
	SND_END

Snd64_Ch2:
	TRANSPOSE_UP 0
	VOICE 4, 6, 8, $0F, 0
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch2_746D
	SND_CALL Snd64_Ch1_7470
	SND_CALL Snd64_Ch2_74B6
	SND_CALL Snd64_Ch1_74BA
	SND_CALL Snd64_Ch1_74C0
	SND_CALL Snd64_Ch1_74C3
	SND_CALL Snd64_Ch2_7506
	SND_CALL Snd64_Ch1_7509
	SND_CALL Snd64_Ch2

Snd64_Ch1:
	VIBRATO $0E
	VOICE 2, 3, 8, $0F, 0
	OCTAVE 1
	REST 2
Snd64_Ch1_73EF:
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_7470
	SND_CALL Snd64_Ch1_74B2
	SND_CALL Snd64_Ch1_74BA
	SND_CALL Snd64_Ch1_74C0
	SND_CALL Snd64_Ch1_74C3
	SND_CALL Snd64_Ch1_7509
	SND_CALL Snd64_Ch1_73EF

Snd64_Ch3:
	TRANSPOSE_UP $0C
	VOICE 4, 2, 6, $0F, 0
	SND_CALL Snd64_Ch1_7425
	SND_CALL Snd64_Ch1_7470
	SND_CALL Snd64_Ch1_74B2
	SND_CALL Snd64_Ch1_74BA
	SND_CALL Snd64_Ch1_74C0
	SND_CALL Snd64_Ch1_74C3
	SND_CALL Snd64_Ch1_7509
	SND_CALL Snd64_Ch3
Snd64_Ch1_7425:
	TEMPO $30
	LEN_UNIT 4
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	TEMPO $50
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 5
	NOTE E_, 6
	OCTAVE 2
	NOTE A_, 3
	TEMPO $30
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	TEMPO $60
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 6
	TEMPO $90
	NOTE F_, 4
	TEMPO $30
	SND_RET
Snd64_Ch2_746D:
	TRANSPOSE_DOWN $0C
	SND_RET
Snd64_Ch1_7470:
	LEN_UNIT 3
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 2
	SND_RET
Snd64_Ch1_74B2:
	OCTAVE 1
	NOTE C#, 2
	NOTE E_, 2
	SND_RET
Snd64_Ch2_74B6:
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	SND_RET
Snd64_Ch1_74BA:
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	SND_RET
Snd64_Ch1_74C0:
	TRANSPOSE_UP 0
	SND_RET
Snd64_Ch1_74C3:
	LEN_UNIT 6
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_RET
Snd64_Ch2_7506:
	TRANSPOSE_DOWN $0C
	SND_RET
Snd64_Ch1_7509:
	LEN_UNIT 6
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	TEMPO $40
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	TEMPO $30
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	TEMPO $50
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	TEMPO $20
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	TEMPO $00
	NOTE C#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	TEMPO $30
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	TEMPO $50
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	TEMPO $60
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	TEMPO $70
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 8
	SND_RET

Snd64_Drm:
	SND_END

Snd65_Ch2:
	PAN $0F
	VIBRATO $0E
	VOICE $10, 3, 8, 5, $0F
	REST 1
Snd65_Ch2_76D4:
	SND_CALL Snd65_Ch1_76F3
	SND_CALL Snd65_Ch2_76D4

Snd65_Ch1:
	PAN $F0
	VIBRATO $0E
	VOICE $10, 3, 8, 5, $0F
	REST 3
Snd65_Ch1_76E3:
	SND_CALL Snd65_Ch1_76F3
	SND_CALL Snd65_Ch1_76E3

Snd65_Ch3:
	VOICE $10, 2, 4, 5, $0F
	SND_CALL Snd65_Ch1_76F3
	SND_CALL Snd65_Ch3
Snd65_Ch1_76F3:
	TRANSPOSE_UP $0C
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE C#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	SND_RET

Snd65_Drm:
	SND_END

Snd67_Ch2:
	TEMPO $10
	VIBRATO $0C
	VOICE $10, 8, 4, $0F, 0
Snd67_Ch2_771B:
	SND_CALL Snd67_Ch1_772D
	SND_CALL Snd67_Ch2_771B

Snd67_Ch1:
	VOICE $10, 8, 8, $0F, 0
Snd67_Ch1_7725:
	TRANSPOSE_DOWN 6
	SND_CALL Snd67_Ch1_772D
	SND_CALL Snd67_Ch1_7725
Snd67_Ch1_772D:
	OCTAVE 3
	SND_SEGNO
	ATTEN 5
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 5
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	SND_REPEAT 2
	SND_SEGNO
	ATTEN 5
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 1
	SND_REPEAT 2
	SND_RET

Snd67_Ch3:
	TRANSPOSE_DOWN $0C
	VOICE 8, 2, 8, 5, $0F
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	SND_REPEAT $0C
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT $0C
	SND_CALL Snd67_Ch3

Snd67_Drm:
	DRUM_UNIT 4
	SND_SEGNO
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	SND_REPEAT $F0
	SND_CALL Snd67_Drm

Snd66_Ch2:
	VIBRATO 8
	TEMPO $40
	VOICE $10, 8, 8, $0F, 0
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	TEMPO $50
	SND_CALL Snd66_Ch1_782A
	TEMPO $40
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7850
	SND_CALL Snd66_Ch1_7857
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7850
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786D
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786F
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_7871
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786F
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786D
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7876
	SND_END
Snd66_Ch1_7821:
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	SND_RET
Snd66_Ch1_782A:
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	SND_RET
Snd66_Ch1_7833:
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_RET
Snd66_Ch1_783C:
	OCTAVE 4
	NOTE D_, 4
	NOTE A_, 2
	NOTE E_, 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE C_, 2
	SND_RET
Snd66_Ch1_7848:
	NOTE D_, 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_RET
Snd66_Ch1_7850:
	OCTAVE 4
	NOTE E_, 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE C_, 2
	SND_RET
Snd66_Ch1_7857:
	NOTE D_, 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
Snd66_Ch1_7867:
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	SND_RET
Snd66_Ch1_786D:
	NOTE B_, 1
	SND_RET
Snd66_Ch1_786F:
	NOTE A#, 1
	SND_RET
Snd66_Ch1_7871:
	NOTE G#, 1
	SND_RET
Snd66_Ch1_7873:
	NOTE F#, 1
	NOTE D_, 1
	SND_RET
Snd66_Ch1_7876:
	TEMPO $60
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D_, 1
	TEMPO $80
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE D_, 1
	SND_RET

Snd66_Ch1:
	VIBRATO $0E
	VOICE $10, 2, 4, $0F, 0
	REST 1
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7850
	SND_CALL Snd66_Ch1_7857
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_783C
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7850
	SND_CALL Snd66_Ch1_7848
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786D
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786F
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_7871
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786F
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7867
	SND_CALL Snd66_Ch1_786D
	SND_CALL Snd66_Ch1_7873
	SND_CALL Snd66_Ch1_7876
	SND_END

Snd66_Ch3:
	TRANSPOSE_UP $0C
	VOICE $10, 4, 6, 3, $0A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	TRANSPOSE_UP 0
	VOICE $10, 4, 6, $0F, 0
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_7986
	SND_CALL Snd66_Ch3_7986
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_7993
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7821
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch1_7833
	SND_CALL Snd66_Ch1_782A
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_797D
	SND_CALL Snd66_Ch3_7986
	SND_CALL Snd66_Ch3_7986
	SND_CALL Snd66_Ch3_79A3
	SND_CALL Snd66_Ch3_79A3
	RELEASE $0F, 0
	SND_CALL Snd66_Ch3_79AC
	SND_CALL Snd66_Ch3_79B0
	SND_END
Snd66_Ch3_797D:
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	SND_RET
Snd66_Ch3_7986:
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	SND_RET
Snd66_Ch3_7993:
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	SND_RET
Snd66_Ch3_79A3:
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_RET
Snd66_Ch3_79AC:
	OCTAVE 1
	NOTE B_, $0C
	NOTE B_, 6
	SND_RET
Snd66_Ch3_79B0:
	OCTAVE 1
	NOTE B_, $0C
	SND_RET

Snd66_Drm:
	SND_END

Snd68_Ch2:
	TRANSPOSE_DOWN $0C
	PAN $0F
	AUTOPAN 2
	TEMPO $4A
	VOICE $10, $0A, 4, 4, $0F
Snd68_Ch2_79C0:
	SND_SEGNO
	SND_CALL Snd68_Ch2_79F0
	SND_CALL Snd68_Ch2_7A03
	SND_REPEAT 2
	SND_CALL Snd68_Ch2_7A17
	SND_CALL Snd68_Ch2_7A03
	SND_CALL Snd68_Ch2_79F0
	SND_CALL Snd68_Ch2_7A03
	SND_SEGNO
	SND_CALL Snd68_Ch2_79F0
	SND_CALL Snd68_Ch2_7A03
	SND_REPEAT 2
	SND_CALL Snd68_Ch2_7A17
	SND_CALL Snd68_Ch2_7A03
	SND_CALL Snd68_Ch2_79F0
	SND_CALL Snd68_Ch2_7A03
	SND_CALL Snd68_Ch2_7A2C
	SND_CALL Snd68_Ch2_79C0
Snd68_Ch2_79F0:
	ATTEN 4
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	NOTE B_, 1
	OCTAVE 3
	ATTEN 2
	NOTE C_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 3
	NOTE E_, 1
	SND_RET
Snd68_Ch2_7A03:
	ATTEN 4
	OCTAVE 2
	NOTE F_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 2
	NOTE C_, 1
	OCTAVE 2
	ATTEN 3
	NOTE B_, 1
	SND_RET
Snd68_Ch2_7A17:
	ATTEN 4
	OCTAVE 2
	NOTE F#, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	ATTEN 3
	NOTE C_, 1
	SND_RET
Snd68_Ch2_7A2C:
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	TEMPO $5A
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	TEMPO $4A
	SND_RET

Snd68_Ch1:
	VOICE $10, 2, 8, $0F, 0
	REST 1
Snd68_Ch1_7A8D:
	VOICE $10, 2, 8, $0F, 0
	TRANSPOSE_DOWN $0C
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7AFF
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7B03
	SND_CALL Snd68_Ch1_7B08
	TRANSPOSE_UP 0
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7AFF
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7B03
	SND_CALL Snd68_Ch1_7B08
	SND_CALL Snd68_Ch1_7B25
	SND_CALL Snd68_Ch1_7A8D

Snd68_Ch3:
	VIBRATO 8
	VOICE $10, 2, 4, 7, 7
Snd68_Ch3_7ABF:
	VOICE $10, 2, 4, 7, 7
	TRANSPOSE_DOWN $0C
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7AFF
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7B03
	SND_CALL Snd68_Ch1_7B08
	TRANSPOSE_UP 0
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7AFF
	SND_CALL Snd68_Ch1_7AEB
	SND_CALL Snd68_Ch1_7B03
	SND_CALL Snd68_Ch1_7B08
	SND_CALL Snd68_Ch1_7B25
	SND_CALL Snd68_Ch3_7ABF
Snd68_Ch1_7AEB:
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE $0F, 0
	OCTAVE 4
	NOTE E_, 5
	RELEASE 8, 8
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE $0F, 0
	NOTE D_, 4
	SND_RET
Snd68_Ch1_7AFF:
	RELEASE 8, 8
	NOTE G_, 2
	SND_RET
Snd68_Ch1_7B03:
	RELEASE 8, 8
	OCTAVE 4
	NOTE B_, 2
	SND_RET
Snd68_Ch1_7B08:
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	RELEASE $0F, 0
	OCTAVE 4
	NOTE E_, 5
	RELEASE 8, 8
	OCTAVE 5
	NOTE C_, 1
	RELEASE $0F, 0
	OCTAVE 4
	NOTE G_, 7
	RELEASE 8, 8
	NOTE D_, 1
	NOTE D_, 1
	RELEASE $0F, 0
	NOTE E_, 7
	OCTAVE 5
	NOTE E_, 4
	NOTE D_, 4
	RELEASE 8, 8
	SND_RET
Snd68_Ch1_7B25:
	RELEASE $0F, 0
	OCTAVE 4
	NOTE B_, 6
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE B_, 6
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 6
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 6
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 6
	NOTE G_, 2
	NOTE A_, 8
	NOTE A_, 8
	SND_RET

Snd68_Drm:
	SND_END

Snd69_Ch2:
	TRANSPOSE_UP $0C
	VIBRATO $0E
	PAN $0F
	TEMPO $20
	VOICE $0F, 3, 4, 4, $0E
	REST 1
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B6E
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B7A
	SND_CALL Snd69_Ch2_7B89
	SND_CALL Snd69_Ch2_7B95
Snd69_Ch1_7B62:
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_RET
Snd69_Ch1_7B6E:
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_RET
Snd69_Ch1_7B7A:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	TEMPO $30
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	SND_RET
Snd69_Ch2_7B89:
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	SND_RET
Snd69_Ch1_7B8D:
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Snd69_Ch3_7B90:
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	SND_RET
Snd69_Ch2_7B95:
	TEMPO $20
	PAN $0F
	AUTOPAN 2
	VOICE $0F, 8, 8, 4, $0E
	TRANSPOSE_DOWN $0C
	VIBRATO 0
	SND_CALL Snd69_Ch2_7BD0
	SND_CALL Snd69_Ch2_7BF8
	SND_CALL Snd69_Ch2_7C0C
	SND_CALL Snd69_Ch2_7BD0
	SND_CALL Snd69_Ch2_7BF8
	SND_CALL Snd69_Ch2_7C22
	SND_CALL Snd69_Ch2_7C33
	SND_CALL Snd69_Ch2_7C4C
	SND_CALL Snd69_Ch2_7C33
	SND_CALL Snd69_Ch2_7C55
	SND_CALL Snd69_Ch2_7C5E
	SND_SEGNO
	SND_CALL Snd69_Ch2_7BF8
	SND_CALL Snd69_Ch2_7C22
	SND_REPEAT 2
	SND_CALL Snd69_Ch2_7B95
Snd69_Ch2_7BD0:
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_RET
Snd69_Ch2_7BF8:
	TRANSPOSE_DOWN $0C
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	SND_RET
Snd69_Ch2_7C0C:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET
Snd69_Ch2_7C22:
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_RET
Snd69_Ch2_7C33:
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_RET
Snd69_Ch2_7C4C:
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	SND_RET
Snd69_Ch2_7C55:
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE D_, 1
	SND_RET
Snd69_Ch2_7C5E:
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE D_, 1
	SND_RET

Snd69_Ch1:
	TRANSPOSE_UP $0C
	PAN $F0
	VIBRATO $0E
	VOICE $0F, 3, 8, $0F, 0
	REST 3
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B6E
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B7A
	SND_CALL Snd69_Ch1_7B8D
Snd69_Ch1_7CAD:
	TRANSPOSE_UP 0
	PAN $FF
	VOICE $0F, 2, 8, $0F, 0
	SND_CALL Snd69_Ch1_7D3C
	SND_CALL Snd69_Ch1_7D61
	SND_CALL Snd69_Ch1_7D3C
	SND_CALL Snd69_Ch1_7D63
	SND_CALL Snd69_Ch1_7CD0
	VIBRATO $0E
	VOICE $0F, 2, 8, $0F, 0
	SND_CALL Snd69_Ch1_7D7E
	SND_CALL Snd69_Ch1_7CAD
Snd69_Ch1_7CD0:
	VIBRATO 3
	VOICE $0F, 5, 8, $0F, 0
	ATTEN 2
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 4
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 4
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 6
	VIBRATO $0E
	ATTEN 3
	OCTAVE 4
	NOTE E_, 5
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 1
	VIBRATO 3
	RELEASE 5, 8
	ATTEN 0
	PAN $0F
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	PAN $F0
	NOTE E_, 1
	NOTE D_, 2
	PAN $0F
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	PAN $F0
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	PAN $FF
	REST 1
	SND_RET
	db $FF

Snd69_Ch3:
	TRANSPOSE_UP $0C
	VOICE $0F, 2, 4, 8, $0D
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B6E
	SND_CALL Snd69_Ch1_7B62
	SND_CALL Snd69_Ch1_7B7A
	SND_CALL Snd69_Ch3_7B90
Snd69_Ch3_7D22:
	TRANSPOSE_UP 0
	VIBRATO 3
	VOICE $0F, 2, 4, $0F, 0
	SND_CALL Snd69_Ch1_7D3C
	SND_CALL Snd69_Ch1_7D61
	SND_CALL Snd69_Ch1_7D3C
	SND_CALL Snd69_Ch1_7D61
	SND_CALL Snd69_Ch3_7D65
	SND_CALL Snd69_Ch3_7D22
Snd69_Ch1_7D3C:
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 3
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 6
	NOTE F#, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE C#, 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	SND_RET
Snd69_Ch1_7D61:
	NOTE G_, 2
	SND_RET
Snd69_Ch1_7D63:
	NOTE G_, 1
	SND_RET
Snd69_Ch3_7D65:
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 4
	NOTE D_, 2
	NOTE E_, 6
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 4
	NOTE A_, 2
	NOTE G#, 4
	NOTE A_, 1
	NOTE B_, 1
Snd69_Ch1_7D7E:
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, $0C
	NOTE E_, $0B
	NOTE F_, 1
	NOTE E_, $0C
	NOTE E_, $0C
	SND_RET

Snd69_Drm:
	SND_END

Snd6A_Ch2:
	VOICE 6, 8, 8, 5, $0F
	SND_CALL Snd6A_Ch1_7DBF
	SND_CALL Snd6A_Ch2_7DDD
	VOICE 6, $0C, 8, 5, $0F
	SND_CALL Snd6A_Ch1_7DE5
	SND_CALL Snd6A_Ch1_7E30
	SND_CALL Snd6A_Ch1_7DE5
	SND_CALL Snd6A_Ch1_7E4C
	SND_CALL Snd6A_Ch2_7E6C
	SND_CALL Snd6A_Ch2
Snd6A_Ch1_7DBF:
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE F_, 4
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 2
	SND_REPEAT 4
	SND_RET
Snd6A_Ch2_7DDD:
	ATTEN 4
	NOTE B_, 2
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	SND_RET
Snd6A_Ch1_7DE3:
	REST 4
	SND_RET
Snd6A_Ch1_7DE5:
	SND_SEGNO
	PAN $0F
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_SEGNO
	PAN $F0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	PAN $0F
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	PAN $F0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_SEGNO
	PAN $0F
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN $F0
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN $0F
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_REPEAT 2
	PAN $FF
	SND_RET
Snd6A_Ch1_7E30:
	SND_SEGNO
	PAN $F0
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	PAN $F0
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	SND_REPEAT 2
	SND_RET
Snd6A_Ch1_7E4C:
	PAN $F0
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE E_, 1
	PAN $0F
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	PAN $F0
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	PAN $FF
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	SND_RET
Snd6A_Ch2_7E6C:
	ATTEN 4
Snd6A_Ch1_7E6D:
	SND_SEGNO
	OCTAVE 3
	NOTE F#, 2
	NOTE E_, 1
	NOTE B_, 3
	NOTE F#, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE E_, 1
	RELEASE $0F, 0
	OCTAVE 2
	NOTE B_, 9
	RELEASE 5, $0F
	SND_REPEAT 4
	ATTEN 0
	SND_RET

Snd6A_Ch1:
	VOICE 6, 2, 8, $0F, 0
	REST 1
Snd6A_Ch1_7E86:
	RELEASE $0F, 0
	SND_CALL Snd6A_Ch1_7DBF
	SND_CALL Snd6A_Ch1_7DE3
	SND_CALL Snd6A_Ch1_7DE5
	SND_CALL Snd6A_Ch1_7E30
	SND_CALL Snd6A_Ch1_7DE5
	SND_CALL Snd6A_Ch1_7E4C
	SND_CALL Snd6A_Ch1_7E6D
	SND_CALL Snd6A_Ch1_7E86

Snd6A_Ch3:
	VOICE 6, 2, 6, 4, 8
	SND_CALL Snd6A_Ch1_7DBF
	SND_CALL Snd6A_Ch1_7DE3
	RELEASE 2, $0F
	SND_CALL Snd6A_Ch3_7ED3
	SND_CALL Snd6A_Ch3_7EDA
	SND_CALL Snd6A_Ch3_7EE1
	SND_CALL Snd6A_Ch3_7EE8
	SND_CALL Snd6A_Ch3_7ED3
	SND_CALL Snd6A_Ch3_7EDA
	SND_CALL Snd6A_Ch3_7EE1
	SND_CALL Snd6A_Ch3_7EEF
	SND_CALL Snd6A_Ch3_7EDA
	SND_CALL Snd6A_Ch3_7ED3
	SND_CALL Snd6A_Ch3_7EDA
	SND_CALL Snd6A_Ch3_7ED3
	SND_CALL Snd6A_Ch3
Snd6A_Ch3_7ED3:
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	SND_REPEAT $0C
	SND_RET
Snd6A_Ch3_7EDA:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT $0C
	SND_RET
Snd6A_Ch3_7EE1:
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT $0C
	SND_RET
Snd6A_Ch3_7EE8:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT $0C
	SND_RET
Snd6A_Ch3_7EEF:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 8
	SND_RET

Snd6A_Drm:
	DRUM_UNIT 6
	SND_SEGNO
	DRUM 8, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 2
	SND_REPEAT 4
	DRUM 3, 4
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT $0F
	LEN_UNIT 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT 6
	SND_SEGNO
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 1, 1
	SND_REPEAT 6
	SND_CALL Snd6A_Drm

Snd6B_Ch2:
	TEMPO $00
	VOICE 8, 6, 8, 1, $0F
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
Snd6B_Ch2_7F5F:
	RELEASE $0F, 0
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 8
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE B_, 8
	NOTE G#, 8
	NOTE A_, 8
	NOTE B_, 8
	NOTE G#, 8
	NOTE E_, 8
	SND_REPEAT 2
	SND_CALL Snd6B_Ch2_7F5F

Snd6B_Ch1:
	VIBRATO $0E
	TRANSPOSE_DOWN $0C
	VOICE 8, 2, 8, $0F, 0
	REST 2
	SND_CALL Snd6B_Ch1_7F93
Snd6B_Ch1_7F7E:
	SND_CALL Snd6B_Ch1_7FAC
	SND_CALL Snd6B_Ch1_7F7E

Snd6B_Ch3:
	TRANSPOSE_DOWN $0C
	VOICE 8, 2, 4, $0F, 0
	SND_CALL Snd6B_Ch1_7F93
Snd6B_Ch3_7F8D:
	SND_CALL Snd6B_Ch1_7FAC
	SND_CALL Snd6B_Ch3_7F8D
Snd6B_Ch1_7F93:
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	SND_RET
Snd6B_Ch1_7FAC:
	SND_SEGNO
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	SND_REPEAT 3
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	SND_RET

Snd6B_Drm:
	DRUM_UNIT $10
	REST 8
Snd6B_Drm_7FE5:
	SND_SEGNO
	DRUM 1, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	SND_REPEAT $F0
	SND_CALL Snd6B_Drm_7FE5
BankEndPad:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
BankId:
	db $07
