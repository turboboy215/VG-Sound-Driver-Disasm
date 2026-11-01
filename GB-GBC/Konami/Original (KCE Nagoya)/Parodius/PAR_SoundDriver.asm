; ==========================================================================
; Parodius (UE) - Konami sound driver (second generation, banked streams)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: rst $28, the ReadStreamByte vector and routine, the far wrappers ($042F-$04BD)
;   bank 14: songs $62-$66 ($5BE1-$612B), the driver ($612C-$6B7B), tables, headers, SFX ($6B7C-$7D00)
;   bank 15: songs $4F-$61 and $67-$6A ($4000-$7FFF)
; Build: rgbasm -Wall -o par.o PAR_SoundDriver.asm && rgblink -o par.gb par.o
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
DEF wTrkSfx1 EQU $C080 ; 40 bytes
DEF wTrkSfx2 EQU $C180 ; 40 bytes
DEF wTrkSfxN EQU $C280 ; 40 bytes
DEF wTrkCh1 EQU $C380 ; 40 bytes
DEF wTrkCh2 EQU $C480 ; 40 bytes
DEF wTrkCh3 EQU $C580 ; 40 bytes
DEF wTrkDrm EQU $C680 ; 40 bytes
DEF wTrackIdx EQU $C0AB
DEF wRegBase EQU $C0AC
DEF wTempo EQU $C0AD
DEF wTempoAcc EQU $C0AE
DEF wTempoSkip EQU $C0AF
DEF wQueuedSnd EQU $C0B0
DEF wNR51 EQU $C0B1
DEF wSweepVal EQU $C0B2
DEF wReqId EQU $C0B3
DEF wReqPrio EQU $C0B4
DEF wRegVal EQU $C0B5
DEF wRegOff EQU $C0B6
DEF wMusicHold EQU $C0B7
DEF wLockout EQU $C0B8
DEF wFadeReq EQU $C0BA
DEF wFadeTimer EQU $C0BB
DEF wFadeLevel EQU $C0BC
DEF wReqBank EQU $C0BD
DEF wRegShadow EQU $C1A8 ; 21 bytes
DEF wSndBusy EQU $CB85
DEF wPauseFlags EQU $CB8B
DEF wChanLeft EQU $CBC0 ; 8 bytes
DEF wChanRight EQU $CBC8 ; 8 bytes
DEF wFadeToPlay EQU $DD92
DEF wSndMute EQU $DE02
DEF rROMB EQU $2180 ; MBC1 bank select as written by this game
DEF hBankId EQU $7FFF ; every bank stores its own number in its last byte

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
DEF TRK_ID EQU $80
DEF TRK_PRIO EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_BANK EQU $86
DEF TRK_REPCNT EQU $87
DEF TRK_VIB EQU $88
DEF TRK_TRANSP EQU $89
DEF TRK_ATTEN EQU $8A
DEF TRK_VIBOFS EQU $8B
DEF TRK_VIBREPCNT EQU $8D
DEF TRK_UNIT EQU $8E
DEF TRK_OCTAVE EQU $8F
DEF TRK_PERIOD EQU $90
DEF TRK_VOL EQU $92
DEF TRK_DUTY EQU $93
DEF TRK_ENV EQU $94
DEF TRK_GATE EQU $95
DEF TRK_RELTICK EQU $96
DEF TRK_VIBTIMER EQU $97
DEF TRK_VIBRELOAD EQU $98
DEF TRK_CH3TIMER EQU $99
DEF TRK_CH3RELOAD EQU $9A
DEF TRK_LEVEL EQU $9C
DEF TRK_SEGNO EQU $9D
DEF TRK_RET EQU $9F
DEF TRK_VIBPTR EQU $A1
DEF TRK_VIBIDX EQU $A3
DEF TRK_VIBLOOPIDX EQU $A4
DEF TRK_DUTYCNT EQU $A5
DEF TRK_DUTYSTART EQU $A6
DEF TRK_DUTYTICKS EQU $A7

; TRK_FLAGS: 0 released, 1 autopan, 3 vibrato negative (sticky), 4 duty step, 6 force register
; writes, 7 rest
; register writes: offset (wRegOff) 0-4 from wRegBase (00 05 0F 00 05 0A 0F by track), shadow at
; wRegShadow + base + offset

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

; sound header: priority, ROM bank of the streams, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm),
; then one dw per set mask bit (low bit first)
MACRO SND_HEADER
	db \1, \2, \3
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
; $EB, $EC: no-ops that skip one argument byte
MACRO CMD_EB
	db $EB, \1
ENDM
MACRO CMD_EC
	db $EC, \1
ENDM
; $ED xy: duty step. Each note starts with duty \1 (y), the voice duty comes back after \2 (x) ticks;
; $ED $00 off
MACRO DUTY_STEP
	db $ED, (\2 << 4) | \1
ENDM
MACRO DUTY_STEP_OFF
	db $ED, $00
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

SECTION "ReadStreamByte vector", ROM0[$0153]

; ReadStreamByteVec: one entry of the game's ROM0 jump vectors; the driver reads every
; stream byte through it.
ReadStreamByteVec:
	jp ReadStreamByte

SECTION "Sound far calls", ROM0[$042F]

; SndUpdateFar (called from the VBlank handler): skipped while wSndBusy bit 0 is set, else
; map bank 14, SndUpdate, restore the caller's bank.
SndUpdateFar:
	ld hl, wSndBusy
	bit 0, [hl]
	jr nz, .l044D
	set 0, [hl]
	ld a, [hBankId]
	push af
	ld a, $0E
	ld [rROMB], a
	call SndUpdate
	ld hl, wSndBusy
	res 0, [hl]
	pop af
	ld [rROMB], a
.l044D:
	ret

; PlaySoundFar: A = sound id; dropped while wSndMute bit 0 or wSndBusy bit 0 is set.
PlaySoundFar:
	push hl
	ld hl, wSndMute
	bit 0, [hl]
	jr nz, .l0478
	ld hl, wSndBusy
	bit 0, [hl]
	jr nz, .l0478
	ld h, a
	ld a, [hBankId]
	push af
	ld a, $0E
	ld [rROMB], a
.l0467:
	ld a, h
	ld h, $CB
	set 0, [hl]
	call PlaySound
.l046F:
	ld hl, wSndBusy
	res 0, [hl]
	pop af
	ld [rROMB], a
.l0478:
	pop hl
	ret

; StartFadeFar: A = the id to play when the fade ends (< 6: stop everything). Dropped while
; wSndBusy bit 0 is set; while wFadeToPlay is set the id is played at once instead.
StartFadeFar:
	push hl
	ld hl, wSndBusy
	bit 0, [hl]
	jr nz, PlaySoundFar.l0478
	ld h, a
	ld a, [hBankId]
	push af
	ld a, $0E
	ld [rROMB], a
	ld a, [wFadeToPlay]
	or a
	jr nz, PlaySoundFar.l0467
	ld a, h
	ld h, $CB
	set 0, [hl]
	call StartFade
	jr PlaySoundFar.l046F

; PauseSoundFar / ResumeSoundFar (the game's pause toggle at $3785).
PauseSoundFar:
	ld a, [hBankId]
	push af
	ld a, $0E
	ld [rROMB], a
	call PauseSound
	pop af
	ld [rROMB], a
	ret

ResumeSoundFar:
	ld a, [hBankId]
	push af
	ld a, $0E
	ld [rROMB], a
	call ResumeSound
	pop af
	ld [rROMB], a
	ret

SECTION "ReadStreamByte", ROM0[$0C6E]

; ReadStreamByte: L = the byte at DE in the ROM bank TRK_BANK of the track page H (the
; caller's bank is restored from its $7FFF). Called with H = the track page; returns in L.
ReadStreamByte:
	ld a, [hBankId]
	push af
	ld l, TRK_BANK
	ld a, [hl]
	ld [rROMB], a
	ld a, [de]
	ld l, a
	pop af
	ld [rROMB], a
	ret

SECTION "Sound bank 14", ROMX[$5BE1], BANK[14]

; Songs $62-$66 (bank 14). Every stream byte is read through ReadStreamByte, from the bank
; given in the sound header.

Snd62_Ch2:
	TEMPO $00
	VIBRATO 10
	VOICE $02, 8, 8, 2, 12
	REST 4
	REST $0C
	REST $0C
	OCTAVE 1
	NOTE G_, 8
	NOTE A_, 4
	RELEASE 2, $0D
	OCTAVE 2
	NOTE C_, $0C
	NOTE C_, $0C
	NOTE C_, $0C
	RELEASE 2, $0C
	OCTAVE 1
	NOTE G_, 8
	NOTE A_, 4
	OCTAVE 2
	NOTE C_, 8
	NOTE C_, $0C
	NOTE C_, 4
	RELEASE 2, $0D
	NOTE C_, $0C
	REST $0C
	NOTE C_, $0C
	RELEASE 2, $0C
	NOTE E_, 8
	NOTE G_, 4
	OCTAVE 1
	NOTE G_, $0C
	NOTE B_, 8
	OCTAVE 2
	NOTE D_, 4
	RELEASE 2, $0D
	NOTE C_, $0C
	OCTAVE 1
	NOTE G_, $0C
	OCTAVE 2
	NOTE C_, $0C
	TEMPO $50
	VIBRATO 15
	RELEASE 3, $0D
	OCTAVE 4
	NOTE C_, $0C
	SND_END

Snd62_Ch1:
	VIBRATO 4
	VOICE $02, 7, 0, 2, 9
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 8
	NOTE A#, 4
	NOTE A_, 8
	NOTE G#, 4
	NOTE G_, 8
	NOTE A_, 4
	RELEASE 3, $0A
	OCTAVE 3
	NOTE C_, $0C
	NOTE C_, $0C
	NOTE C_, $0C
	RELEASE 2, 9
	OCTAVE 2
	NOTE G_, 8
	NOTE A_, 4
	OCTAVE 3
	NOTE C_, 8
	NOTE C_, $0C
	NOTE C_, 4
	RELEASE 3, $0A
	NOTE C_, $0C
	REST $0C
	OCTAVE 2
	NOTE G_, $0C
	RELEASE 2, 9
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 4
	RELEASE 3, $0A
	OCTAVE 2
	NOTE G_, $0C
	RELEASE 2, 9
	NOTE B_, 8
	NOTE B_, 4
	RELEASE 3, $0A
	OCTAVE 3
	NOTE C_, $0C
	OCTAVE 2
	NOTE G_, $0C
	OCTAVE 3
	NOTE C_, $0C
	VIBRATO 7
	RELEASE 1, $0D
	OCTAVE 5
	NOTE C_, $0C
	SND_END

Snd62_Ch3:
	VIBRATO 7
	VOICE $02, 2, 2, 5, 10
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 8
	NOTE A#, 4
	NOTE A_, 8
	NOTE G#, 4
	NOTE G_, 8
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, $0C
	NOTE C_, $0C
	NOTE C_, 8
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 8
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE C_, $0C
	NOTE C_, 4
	NOTE C_, $0C
	NOTE C_, 8
	NOTE D_, 4
	NOTE E_, $0C
	NOTE G_, 8
	NOTE G_, 4
	NOTE E_, 8
	NOTE E_, 4
	NOTE D_, 8
	NOTE D_, 4
	NOTE C_, 8
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 8
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, $0C
	NOTE C_, $0C
	SND_END

Snd62_Drm:
	DRUM_UNIT $02
	DRUM 2, 4
	DRUM 8, 8
	DRUM 2, 4
	DRUM 8, 8
	DRUM 2, 4
	DRUM 8, 8
	DRUM 2, 4
	DRUM 8, $0C
	DRUM 8, $0C
	DRUM 8, $0C
	DRUM $0B, 8
	DRUM $0B, 4
	DRUM 8, 8
	DRUM 8, $0C
	DRUM 8, 4
	DRUM 8, 8
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 8
	DRUM 2, 4
	DRUM 8, $0C
	DRUM 8, 8
	DRUM 8, 4
	DRUM $0B, $0C
	DRUM 8, $0C
	DRUM 2, 8
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 8
	DRUM 8, 4
	DRUM 8, $0C
	DRUM 8, $0C
	SND_END

Snd63_Ch2:
	TEMPO $35
	SND_CALL Snd63_Ch2_5CC6
	TEMPO $25
	SND_CALL Snd63_Ch2_5CC6
	TEMPO $15
	SND_CALL Snd63_Ch2_5CC6
Snd63_Ch2_5CBE:
	TEMPO $00
	SND_CALL Snd63_Ch2_5CC6
	SND_CALL Snd63_Ch2_5CBE
Snd63_Ch2_5CC6:
	TRANSPOSE_UP $0C
	VOICE $05, 7, 8, 2, 14
	REST 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 2
	NOTE E_, 4
	ATTEN 0
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	SND_REPEAT 2
	OCTAVE 1
	NOTE E_, 2
	NOTE B_, 2
	ATTEN 2
	OCTAVE 2
	NOTE E_, 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	SND_RET

Snd63_Ch1:
	VIBRATO 4
	DUTY_STEP 8, 2
	VOICE $05, 7, 4, 2, 15
Snd63_Ch1_5D00:
	SND_CALL Snd63_Ch1_5D06
	SND_CALL Snd63_Ch1_5D00
Snd63_Ch1_5D06:
	SND_SEGNO
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 2
	PAN $0F
	VIBRATO 7
	DUTY 0
	LEN_UNIT $01
	OCTAVE 5
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	DUTY 4
	PAN $FF
	VIBRATO 4
	LEN_UNIT $05
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 2
	PAN $F0
	VIBRATO 7
	DUTY 0
	LEN_UNIT $01
	OCTAVE 5
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	PAN $FF
	VIBRATO 4
	DUTY 4
	LEN_UNIT $05
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 4
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 2
	PAN $0F
	VIBRATO 7
	DUTY 0
	LEN_UNIT $01
	OCTAVE 5
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	PAN $FF
	VIBRATO 4
	DUTY 4
	LEN_UNIT $05
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 2
	PAN $F0
	VIBRATO 7
	DUTY 0
	LEN_UNIT $01
	OCTAVE 5
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	NOTE A_, 3
	NOTE E_, 5
	REST 2
	PAN $FF
	VIBRATO 4
	DUTY 4
	LEN_UNIT $05
	OCTAVE 3
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 4
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_RET

Snd63_Ch3:
	VOICE $05, 2, 13, 3, 10
Snd63_Ch3_5D94:
	SND_CALL Snd63_Ch3_5D9A
	SND_CALL Snd63_Ch3_5D94
Snd63_Ch3_5D9A:
	RELEASE 3, $0A
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	RELEASE 2, $0D
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	RELEASE 3, $0A
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 2, $0D
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 3, $0A
	NOTE B_, 1
	NOTE A_, 1
	RELEASE 2, $0D
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 3, $0A
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE 2, $0D
	OCTAVE 1
	NOTE B_, 2
	RELEASE 3, $0A
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	RELEASE 2, $0D
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	RELEASE 3, $0A
	OCTAVE 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 2, $0D
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 3, $0A
	NOTE B_, 1
	NOTE A_, 1
	RELEASE 2, $0D
	NOTE B_, 2
	NOTE E_, 2
	RELEASE 3, $0A
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	RELEASE 2, $0D
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	SND_RET

Snd63_Drm:
	SND_END

Snd64_Ch2:
	TEMPO $10
	VOICE $01, 10, 0, 3, 15
	OCTAVE 3
	NOTE D_, $0C
	SWEEP $57
	OCTAVE 4
	NOTE D_, 7
	SWEEP $00
	OCTAVE 3
	NOTE C#, $0C
	SWEEP $57
	OCTAVE 4
	NOTE C#, 7
	SWEEP $00
	OCTAVE 3
	NOTE C_, $0C
	SWEEP $57
	OCTAVE 4
	NOTE C_, 7
	SWEEP $00
	OCTAVE 2
	NOTE B_, $0C
	SWEEP $57
	OCTAVE 3
	NOTE B_, 7
	LEN_UNIT $05
	SWEEP $00
	OCTAVE 2
	NOTE A#, 4
	TEMPO $15
	VIBRATO 14
	ATTEN 2
	RELEASE 1, $0C
	OCTAVE 4
	NOTE C#, 4
	NOTE C#, 4
	SND_END

Snd64_Ch1:
	VOICE $01, 10, 0, 3, 15
	VIBRATO 7
	OCTAVE 2
	NOTE D_, $0A
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 7
	OCTAVE 2
	NOTE C#, $0A
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 7
	OCTAVE 2
	NOTE C_, $0A
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 7
	OCTAVE 1
	NOTE B_, $0A
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 7
	LEN_UNIT $05
	RELEASE 5, $0F
	OCTAVE 1
	NOTE A#, 4
	VIBRATO 7
	RELEASE 2, $0F
	ATTEN 3
	OCTAVE 3
	NOTE A#, 4
	NOTE A#, 4
	SND_END

Snd64_Ch3:
	VOICE $05, 2, 8, 5, 13
	OCTAVE 2
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	NOTE A#, 3
	WAVE 2
	VIBRATO 15
	RELEASE 6, $0A
	OCTAVE 3
	NOTE A#, 4
	NOTE A#, 4
	SND_END

Snd64_Drm:
	SND_END

Snd65_Ch2:
	TEMPO $40
	DUTY_STEP 0, 2
	VOICE $04, 10, 8, 3, 15
	ATTEN 4
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	ATTEN 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	REST 2
	VIBRATO 7
	OCTAVE 4
	NOTE E_, 6
	NOTE F_, 2
	SND_END

Snd65_Ch1:
	TRANSPOSE_DOWN 6
	LEN_UNIT $01
	REST 2
	VOICE $04, 8, 0, 2, 15
	PAN $F0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE G#, 1
	PAN $FF
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	PAN $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	PAN $FF
	LEN_UNIT $02
	NOTE F_, 1
	REST 4
	TRANSPOSE_UP 0
	LEN_UNIT $04
	RELEASE 5, $0F
	OCTAVE 3
	NOTE A#, 6
	NOTE A_, 2
	SND_END

Snd65_Ch3:
	VOICE $04, 2, 8, 7, 6
	OCTAVE 1
	NOTE F_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE D_, 4
	RELEASE 0, 0
	NOTE C_, 8
	NOTE F_, 3
	OCTAVE 1
	NOTE F_, 1
	SND_END

Snd65_Drm:
	DRUM_UNIT $04
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 4
	SND_SEGNO
	DRUM $0B, 1
	DRUM $0B, 1
	SND_REPEAT 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_END

Snd66_Ch2:
	TEMPO $00
	VOICE $05, 8, 8, 1, 14
	SND_CALL Snd66_Ch2_5EFB
	SND_CALL Snd66_Ch2_5EFB
	SND_CALL Snd66_Ch2_5F39
	SND_CALL Snd66_Ch2
Snd66_Ch2_5EFB:
	RELEASE 1, $0E
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	VIBRATO 7
	RELEASE 3, $0E
	NOTE E_, 4
	VIBRATO 0
	RELEASE 1, $0E
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	VIBRATO 7
	RELEASE 3, $0E
	NOTE E_, 4
	VIBRATO 0
	RELEASE 1, $0E
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	VIBRATO 7
	RELEASE 3, $0E
	NOTE E_, 4
	VIBRATO 0
	RELEASE 1, $0E
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 4, $0F
	NOTE E_, 4
	NOTE C_, 2
	VIBRATO 7
	NOTE D_, 3
	REST 1
	VIBRATO 0
	SND_RET
Snd66_Ch2_5F39:
	RELEASE 1, $0E
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE F_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	PAN $0F
	DUTY 4
	OCTAVE 5
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	PAN $FF
	DUTY 8
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	PAN $F0
	DUTY 4
	OCTAVE 5
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	PAN $FF
	DUTY 8
	SND_SEGNO
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 2
	SND_REPEAT 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET

Snd66_Ch1:
	VOICE $05, 5, 0, 1, 12
	SND_CALL Snd66_Ch1_5FA2
	SND_CALL Snd66_Ch1_5FA2
	SND_CALL Snd66_Ch1_5FFA
	SND_CALL Snd66_Ch1
Snd66_Ch1_5FA2:
	DUTY_STEP 4, 1
	AUTOPAN 2
	PAN $F0
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	AUTOPAN 0
	PAN $FF
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 3, $0C
	NOTE D_, 4
	AUTOPAN 2
	PAN $0F
	RELEASE 1, $0C
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	AUTOPAN 0
	PAN $FF
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 3, $0C
	NOTE C_, 4
	AUTOPAN 2
	PAN $F0
	RELEASE 1, $0C
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	AUTOPAN 0
	PAN $FF
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 3, $0C
	NOTE F_, 4
	AUTOPAN 2
	PAN $F0
	RELEASE 1, $0C
	NOTE F_, 2
	NOTE F_, 2
	AUTOPAN 0
	PAN $FF
	RELEASE 3, $0C
	NOTE G_, 4
	AUTOPAN 2
	PAN $0F
	RELEASE 1, $0C
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	AUTOPAN 0
	PAN $FF
	SND_RET
Snd66_Ch1_5FFA:
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	PAN $F0
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	PAN $FF
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	PAN $0F
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	PAN $FF
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_REPEAT 2
	ATTEN 0
	SND_SEGNO
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_REPEAT 4
	SND_RET

Snd66_Ch3:
	VOICE $05, 2, 8, 3, 13
	SND_CALL Snd66_Ch3_604A
	SND_CALL Snd66_Ch3_604A
	SND_CALL Snd66_Ch3_608D
	SND_CALL Snd66_Ch3
Snd66_Ch3_604A:
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
	RELEASE 4, $0C
	OCTAVE 1
	NOTE A#, 4
	RELEASE 3, $0D
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	RELEASE 4, $0C
	NOTE A_, 4
	RELEASE 3, $0D
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	RELEASE 4, $0C
	OCTAVE 2
	NOTE D_, 4
	RELEASE 3, $0D
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 4, $0C
	OCTAVE 1
	NOTE G_, 4
	RELEASE 3, $0D
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_RET
Snd66_Ch3_608D:
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	SND_REPEAT 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	SND_RET

Snd66_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 4
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 4
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 4
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 4
	DRUM 2, 2
	DRUM 2, 4
	SND_REPEAT 2
	SND_SEGNO
	DRUM 7, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 7, 2
	DRUM 2, 2
	SND_REPEAT 6
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 2
	DRUM 2, 2
	SND_REPEAT 4
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_CALL Snd66_Drm

; CopyBytes: copy BC bytes from HL to DE (used as a fill: the first byte is set first).
; LoadPtrIndexed: HL = word [HL + 2A]. JumpTable: jump through the word table after the call.
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

; SndInit: clear $80-$FF of the seven track pages; NR52 = NR51 = $FF, NR50 = $77.
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

; FadeTick (not while paused): while wFadeReq bit 7 is set, every 32 updates wFadeLevel + 1
; (off the volume of new music notes, half of it on CH3). At level 5 the target id is
; queued; below 6 StopAll is called instead (which also clears the queue), else the fade
; ends (level 0, wFadeReq 0).
FadeTick:
	ld a, [wPauseFlags]
	and $01
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
	cp $06
	jp c, StopAll
	xor a
	ld [hl], a
	ld [wFadeReq], a
	ret

; TempoTick: wTempoAcc += wTempo; wTempoSkip = carry.
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

; LockoutTick: wLockout (set by ids $67-$6A) counts down by one per update.
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

; SndUpdate (once per VBlank): fade, lockout, tempo, then tracks 0-6 in order. Paused: only
; track 1 runs, and only while it plays id $07 (the pause jingle). On a tempo carry (or
; wMusicHold, never set) the loop stops at track 3, so the four music tracks skip the frame.
; Then a queued id (the fade target) is played. DeadCheck is unreachable.
SndUpdate:
	call FadeTick
	call LockoutTick
	call TempoTick
	xor a

UpdateLoop:
	ld [wTrackIdx], a
	ld a, [wPauseFlags]
	and $01
	jr z, UpdateNotPaused
	ld a, [wTrackIdx]
	cp $01
	jr nz, NextTrack
	ld a, [wTrkSfx2]
	cp $07
	jr z, RunTrack
	jr PlayQueued

UpdateNotPaused:
	ld a, [wTrackIdx]
	cp $03
	jr nz, RunTrack
	ld a, [wMusicHold]
	ld b, a
	ld a, [wTempoSkip]
	or b
	jr nz, PlayQueued
	jr RunTrack

DeadCheck:
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
; Else: duty step, released flag, then (not on rests, the noise or the drum track) vibrato,
; and the CH3 decay or, at the release tick, NRx2 = level | env + trigger.
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
	bit 4, [hl]
	jr z, .l62A5
	ld l, TRK_DUTYCNT
	inc [hl]
	ld a, [hl]
	ld l, TRK_DUTYTICKS
	cp [hl]
	call z, WriteDuty
.l62A5:
	ld l, TRK_LEN
	ld b, [hl]
	ld l, TRK_RELTICK
	ld a, [hl]
	sub b
	jr c, .l62B2
	ld l, TRK_FLAGS
	set 0, [hl]
.l62B2:
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
	jr c, Ch3WriteLevel
	xor a

Ch3WriteLevel:
	rla
	swap a
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
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
	jp WritePeriodVib

NextCmd:
	inc de

; ReadCmds: every byte through ReadStreamByte. $FB-$FF flow (segno, return, call,
; repeat/jump, end), $E0 voice, notes, $F0-$FA attenuation, $E1-$E6 octave, $E7-$EF
; through the table.
ReadCmds:
	call ReadStreamByteVec
	ld a, l
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
	call ReadStreamByteVec
	ld c, l
	inc de
	call ReadStreamByteVec
	ld b, l
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
	call ReadStreamByteVec
	ld a, l
	cp $FF
	jr z, .l6388
	ld l, TRK_REPCNT
	inc [hl]
	cp [hl]
	jr z, .l6396
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jr ReadCmds
.l6388:
	inc de
	call ReadStreamByteVec
	ld c, l
	inc de
	call ReadStreamByteVec
	ld b, l
	ld d, b
	ld e, c
	jr ReadCmds
.l6396:
	ld l, TRK_REPCNT
	ld [hl], $00
	jr NextCmd

; Flow_End: clear id/priority, NRx2 = 0 (Ch3: NR30 = 0, not through the shadow). Sfx1
; (NR10 = 0) and Sfx2 give the duty and the plain period back to the music track (with
; the ended SFX track's force flag); not the volume, NR51 or a trigger.
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
	jr nz, .l63BA
	xor a
	ldh [rNR30], a
	ret
.l63BA:
	cp $01
	jr z, .l63C8
	cp $00
	ret nz
	xor a
	ldh [rNR10], a
	ld h, HIGH(wTrkCh1)
	jr .l63CA
.l63C8:
	ld h, HIGH(wTrkCh2)
.l63CA:
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
	call ReadStreamByteVec
	ld a, l
	cp $E0
	jp z, Cmd_Voice
	and $F0
	cp $E0
	jp c, Note
	cp $F0
	jp z, Cmd_Atten
	call ReadStreamByteVec
	ld a, l
	cp $E7
	jp c, Cmd_Octave
	inc de
	sub $E7
	push hl
	call JumpTable
CommandTable:
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
	call ReadStreamByteVec
	ld a, l
	ld l, TRK_UNIT
	ld [hl], a
	jp NextCmd

Cmd_Release:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

Cmd_Sweep:
	pop hl
	call ReadStreamByteVec
	ld a, l
	ld [wSweepVal], a
	ld [wRegVal], a
	ld a, $00
	ld [wRegOff], a
	call WriteReg
	jp NextCmd

; Cmd_Ext: $EA xy, x = 0 transpose up, 1 down, 2 vibrato, 3 duty/wave, 4 flags (| autopan).
; x >= 5 runs past the 5-entry table (into the code at Ext_TransposeUp).
Cmd_Ext:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $F0
	swap a
	push hl
	call JumpTable
ExtTable:
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_Vibrato
	dw Ext_Duty
	dw Ext_Autopan

Ext_TransposeUp:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_TransposeDown:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	cpl
	inc a
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_Vibrato:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_VIB
	ld [hl], a
	or a
	jr nz, .l6495
	xor a
	ld l, TRK_VIBOFS
	ld [hl+], a
	ld [hl], a
	jp NextCmd
.l6495:
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

Ext_Duty:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	jp NextCmd

Ext_Autopan:
	pop hl
	call ReadStreamByteVec
	ld a, l
	and $0F
	or a
	ld l, TRK_FLAGS
	ld [hl], a
	jr z, .l64CF
	or $02
	jr .l64D1
.l64CF:
	and $FD
.l64D1:
	ld [hl], a
	jp NextCmd

Cmd_EB:
	pop hl
	jp NextCmd

Cmd_EC:
	pop hl
	jp NextCmd

Cmd_DutyStep:
	pop hl
	call ReadStreamByteVec
	ld a, l
	or a
	ld l, TRK_FLAGS
	jr z, .l64FC
	set 4, [hl]
	and $0F
	ld l, TRK_DUTYSTART
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	swap a
	and $0F
	ld l, TRK_DUTYTICKS
	ld [hl], a
	jp NextCmd
.l64FC:
	res 4, [hl]
	jp NextCmd

Cmd_Tempo:
	pop hl
	call ReadStreamByteVec
	ld a, l
	ld [wTempo], a
	jp NextCmd

; Cmd_Pan: NR51 = (wNR51 & PanMaskTable[track]) | (swap(x) & ~mask); not on Ch1 while Sfx1
; plays.
Cmd_Pan:
	pop hl
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l651E
	ld a, [wTrkSfx1]
	or a
	jp nz, NextCmd
	ld a, [wTrackIdx]
.l651E:
	push hl
	ld hl, PanMaskTable
	rst $28
	ld a, [wNR51]
	and [hl]
	ld c, a
	ld a, [hl]
	cpl
	ld b, a
	pop hl
	call ReadStreamByteVec
	ld a, l
	swap a
	and b
	or c
	ld [wNR51], a
	ldh [rNR51], a
	jp NextCmd
PanMaskTable:
	db $EE, $DD, $77, $EE, $DD, $BB, $FF

; AutoPan: this track's NR51 bits swapped left/right (each note while TRK_FLAGS bit 1).
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
	call ReadStreamByteVec
	ld a, l
	and $0F
	dec a
	ld l, TRK_OCTAVE
	ld [hl], a
	jp NextCmd

Cmd_Voice:
	inc de
	call ReadStreamByteVec
	ld a, l
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackIdx]
	cp $06
	jp z, NextCmd
	inc de
	cp $02
	jr z, VoiceNoise
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	swap a
	and $0F
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	swap a
	and $0F
	ld l, TRK_GATE
	ld [hl], a
	jp NextCmd

VoiceNoise:
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	swap a
	and $0F
	ld l, TRK_VOL
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	call TriggerReg
	jp NextCmd

Cmd_Atten:
	call ReadStreamByteVec
	ld a, l
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
	call ReadStreamByteVec
	ld c, l
	ld b, $00
	jp WritePeriod

; Note: autopan, save the pointer, then (SfxN and the music tracks Ch1-Ch3) set wChanLeft /
; wChanRight + 2 * (track - 2) to 1 if the real NR51 has the channel on that side (nothing
; else in the game reads these). Noise: NR43 = byte, NR44 = 0 through the shadow (no
; retrigger). Length = lo * unit (0 = 256). Rest: TRK_FLAGS |= $C0, NRx2 = 0. Drums: play
; DrumMap[hi - 1]. Release tick = length * gate / 16 (gate 15: length - 1). Period from
; (hi - 1) + transpose + 12 * octave; vibrato restarts; NRx2 = level (force off first),
; trigger.
Note:
	ld l, TRK_FLAGS
	bit 1, [hl]
	call nz, AutoPan
	call SavePtr
	dec de
	push af
	push bc
	push hl
	ld a, [wTrackIdx]
	sub $02
	cp $04
	jr nc, .l6656
	ld b, a
	ld hl, ChanLeftBits
	rst $28
	ldh a, [rNR51]
	and [hl]
	jr z, .l6644
	ld a, b
	add a, a
	ld hl, wChanLeft
	rst $28
	ld [hl], $01
.l6644:
	ld a, b
	ld hl, ChanRightBits
	rst $28
	ldh a, [rNR51]
	and [hl]
	jr z, .l6656
	ld a, b
	add a, a
	ld hl, wChanRight
	rst $28
	ld [hl], $01
.l6656:
	pop hl
	pop bc
	pop af
	jr NoteLength
ChanLeftBits:
	db $80, $10, $20, $40
ChanRightBits:
	db $08, $01, $02, $04

NoteLength:
	ld a, [wTrackIdx]
	cp $02
	jr z, NoiseNote
	call ReadStreamByteVec
	ld a, l
	and $0F
	ld b, a
	ld l, TRK_UNIT
	ld a, [hl]
	ld c, a
.l6675:
	dec b
	jr z, .l667B
	add a, c
	jr .l6675
.l667B:
	ld l, TRK_LEN
	ld [hl], a
	call ReadStreamByteVec
	ld a, l
	and $F0
	jp z, Rest
	ld a, [wTrackIdx]
	cp $06
	jp z, DrumNote
	cp $05
	jr z, .l66AE
	ld l, TRK_DUTYCNT
	ld [hl], $00
	ld l, TRK_FLAGS
	bit 4, [hl]
	jp z, .l66AE
	ld l, TRK_DUTYSTART
	ld a, [hl]
	swap a
	ld [wRegVal], a
	ld a, $01
	ld [wRegOff], a
	call WriteReg
.l66AE:
	ld l, TRK_GATE
	ld a, [hl]
	cp $0F
	jr nz, .l66BB
	ld l, TRK_LEN
	ld a, [hl]
	dec a
	jr .l66CD
.l66BB:
	push de
	ld c, a
	ld b, $04
	ld l, TRK_LEN
	ld d, [hl]
	xor a
.l66C3:
	srl c
	jr nc, .l66C8
	add a, d
.l66C8:
	rra
	dec b
	jr nz, .l66C3
	pop de
.l66CD:
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_VIBREPCNT
	ld [hl], $00
	ld c, $00
	ld l, TRK_OCTAVE
	ld a, [hl]
	or a
	jr z, .l66E5
	ld b, a
	ld c, $0C
	xor a
.l66E0:
	add a, c
	dec b
	jr nz, .l66E0
	ld c, a
.l66E5:
	call ReadStreamByteVec
	ld a, l
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
	jp z, .l6717
	xor a
	ld l, TRK_VIBIDX
	ld [hl], a
	call VibratoStep
.l6717:
	call WritePeriodVib
	call CalcVolume
	ld [wRegVal], a
	ld a, $02
	ld [wRegOff], a
	call WriteReg
	jp TriggerReg

; CalcVolume: TRK_VOL - TRK_ATTEN - wFadeLevel, 0 on a borrow, swapped. CH3: NR30 = $80,
; level code (vol / 2) & 3 + atten + wFadeLevel / 2, 0 (mute) from 4.
CalcVolume:
	ld l, TRK_FLAGS
	res 6, [hl]
	ld a, [wTrackIdx]
	cp $05
	jr z, CalcVolumeCh3
	ld a, [wFadeLevel]
	ld l, TRK_ATTEN
	ld c, [hl]
	add a, c
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	and $0F
	sub c
	jr nc, .l6747
	xor a
.l6747:
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
	jr c, .l6775
	xor a
.l6775:
	ld l, TRK_LEVEL
	ld [hl], a
	swap a
	rla
	ret

; VibratoStep: steps time << 4 | negative << 3 | offset (11 bits, 2 bytes); $FB loop point,
; $FE n repeat ($FF: forever), $FF hold. The negative flag is never cleared (sticky).
VibratoStep:
	ld l, TRK_VIBPTR
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add a, c
	ld c, a
	jr nc, .l6788
	inc b
.l6788:
	ld a, [bc]
	cp $FB
	jr z, .l67BA
	cp $FE
	jr z, .l67C4
	cp $FF
	jr z, .l67E2
	swap a
	and $0F
	ld l, TRK_VIBTIMER
	ld [hl], a
	ld l, TRK_VIBRELOAD
	ld [hl], a
	ld a, [bc]
	bit 3, a
	jr z, .l67A8
	ld l, TRK_FLAGS
	set 3, [hl]
.l67A8:
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
.l67BA:
	ld l, TRK_VIBIDX
	inc [hl]
	ld a, [hl]
	ld l, TRK_VIBLOOPIDX
	ld [hl], a
	inc bc
	jr .l6788
.l67C4:
	inc bc
	ld a, [bc]
	ld l, TRK_VIBREPCNT
	cp [hl]
	jr z, .l67D8
	cp $FF
	jr z, .l67D0
	inc [hl]
.l67D0:
	ld l, TRK_VIBLOOPIDX
	ld a, [hl]
	ld l, TRK_VIBIDX
	ld [hl], a
	jr VibratoStep
.l67D8:
	xor a
	ld [hl], a
	ld l, TRK_VIBIDX
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr .l6788
.l67E2:
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
	jr z, .l6803
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
.l6803:
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
	call ReadStreamByteVec
	ld a, l
	and $F0
	swap a
	dec a
	ld hl, DrumMap
	rst $28
	ld a, [hl]
	jp PlaySound

; WriteDuty: NRx1 = swap(duty), or on CH3 (wRegBase $0A) copy wave duty - 1 straight to wave
; RAM.
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
.l6878:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, .l6878
	pop hl
	pop de
	ret

IsBlocked:
	ld a, [wTrackIdx]
	cp $03
	jr nz, .l6890
	ld a, [wTrkSfx1]
	or a
	ret z
	jr .l6899
.l6890:
	cp $04
	jr nz, .l689B
	ld a, [wTrkSfx2]
	or a
	ret z
.l6899:
	scf
	ret
.l689B:
	or a
	ret

; WriteReg: register wRegBase + wRegOff = wRegVal, unless blocked (music Ch1 while Sfx1
; plays, music Ch2 while Sfx2 plays) or equal to its shadow (unless the force flag is set).
; TriggerReg: NRx4 = shadow | $80.
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
	jr nz, .l68BB
	ld a, [hl]
	cp c
	jr z, .l68BE
.l68BB:
	ld a, c
	ld [hl], a
	ld [de], a
.l68BE:
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

; PlaySound: A = sound id (saves all registers). StartFade: wFadeReq = A | $80.
PlaySound:
	push hl
	push de
	push bc
	push af
	call PlaySoundA
	pop af
	pop bc
	pop de
	pop hl
	ret

StartFade:
	push hl
	push de
	push bc
	push af
	set 7, a
	ld [wFadeReq], a
	pop af
	pop bc
	pop de
	pop hl
	ret

; CheckLockout: id $07 and ids below 7 always pass. While wLockout runs only ids $67-$6A
; pass; otherwise ids $67-$6A load wLockout from LockoutTable. Carry = refused.
CheckLockout:
	cp $07
	ret z
	cp $07
	jr c, .l6956
	ld hl, wLockout
	ld a, [hl+]
	ld h, [hl]
	or h
	jr z, .l693B
	ld a, [wReqId]
	cp $67
	jr nc, .l6956
	jr .l6959
.l693B:
	ld a, [wReqId]
	cp $67
	jr c, .l6956
	cp $6B
	jr nc, .l6956
	sub $67
	ld hl, LockoutTable
	call LoadPtrIndexed
	ld a, l
	ld [wLockout], a
	ld a, h
	ld [wLockout + $01], a
.l6956:
	or a
	jr .l695A
.l6959:
	scf
.l695A:
	ld a, [wReqId]
	ret
LockoutTable:
	dw $0140
	dw $0140
	dw $0150
	dw $0141

; PlaySoundA: 0 = StopAll. Header: priority, bank, mask, pointers. Each track is started
; when the priority is >= the running one (refused tracks are skipped, the rest still
; start); a started track ORs its NR51 bits into wNR51, Sfx1 (and Ch1 while Sfx1 is idle)
; writes NR10 = 8. Finally NR51 = wNR51.
PlaySoundA:
	ld [wReqId], a
	or a
	jp z, StopAll
	call CheckLockout
	ret c
	ld a, [wReqId]
	ld hl, SoundTable
	call LoadPtrIndexed
	ld a, [hl]
	ld [wReqPrio], a
	inc hl
	ld a, [hl]
	ld [wReqBank], a
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
	ld de, wTrkSfx1
	call StartTrack
	ret c
	push af
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wRegShadow
	ld [bc], a
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	pop af
	ret

StartTrack:
	push af
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	push hl
	ld hl, $0001
	add hl, de
	ld a, [wReqPrio]
	cp [hl]
	jr c, StartRefused
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
	ld a, [wReqBank]
	ld [hl], a
	inc hl
	ld e, l
	inc e
	ld d, h
	ld bc, $0006
	ld [hl], $00
	call CopyBytes
	pop hl
	pop af
	or a
	ret

StartRefused:
	pop hl
	pop af
	scf
	ret

StartSfx2:
	ld de, wTrkSfx2
	call StartTrack
	ret c
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	pop af
	ret

StartCh1:
	ld de, wTrkCh1
	call StartTrack
	ret c
	push af
	ld a, [wTrkSfx1]
	or a
	jr nz, .l6A2E
	ld a, $08
	ld bc, rNR10
	ld [bc], a
	ld bc, wRegShadow
	ld [bc], a
.l6A2E:
	ld a, [wNR51]
	or $11
	ld [wNR51], a
	pop af
	ret

StartCh2:
	ld de, wTrkCh2
	call StartTrack
	ret c
	push af
	ld a, [wNR51]
	or $22
	ld [wNR51], a
	pop af
	ret

StartCh3:
	ld de, wTrkCh3
	call StartTrack
	ret c
	push af
	ld a, [wNR51]
	or $44
	ld [wNR51], a
	pop af
	ret

StartSfxN:
	ld de, wTrkSfxN
	call StartTrack
	ret c
	push af
	ld a, [wNR51]
	or $88
	ld [wNR51], a
	pop af
	ret

StartDrm:
	ld de, wTrkDrm
	jp StartTrack

; StopAll: clear $80-$A7 of the seven track pages, the shadows and the globals; NR51 = $FF;
; NR12/NR22/NR42/NR32 = 0.
StopAll:
	ld hl, wTrkSfx1
	ld de, wTrkSfx1 + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfx2
	ld de, wTrkSfx2 + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkSfxN
	ld de, wTrkSfxN + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh1
	ld de, wTrkCh1 + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh2
	ld de, wTrkCh2 + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkCh3
	ld de, wTrkCh3 + $01
	ld bc, AddAToHL
	ld [hl], $00
	call CopyBytes
	ld hl, wTrkDrm
	ld de, wTrkDrm + $01
	ld bc, AddAToHL
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
	xor a
	ld [wFadeReq], a
	ld [wFadeLevel], a
	ld a, $FF
	ld [wNR51], a
	ld hl, rNR51
	ld [hl], a
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $00
	ldh [rNR32], a
	ret

; PauseSound: silence CH1, CH2, CH4 (NRx2 = 0) and CH3 (NR32 = 0), set wPauseFlags = 1 and
; play $07. ResumeSound: wPauseFlags = 0, copy the shadows back to the registers of each
; channel in use (CH4 only for a noise SFX, id >= 8). No trigger: the music comes back at
; its next note.
PauseSound:
	ld a, $00
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $00
	ldh [rNR32], a
	ld a, $01
	ld [wPauseFlags], a
	ld a, $07
	jp PlaySound

ResumeSound:
	xor a
	ld [wPauseFlags], a
	ld a, [wTrkSfx1]
	ld c, a
	ld a, [wTrkCh1]
	or c
	jr z, .l6B3E
	ld hl, wRegShadow
	ld de, rNR10
	ld b, $05
	call CopyRegs
.l6B3E:
	ld a, [wTrkSfx2]
	ld c, a
	ld a, [wTrkCh2]
	or c
	jr z, .l6B53
	ld hl, wRegShadow + $06
	ld de, rNR21
	ld b, $04
	call CopyRegs
.l6B53:
	ld a, [wTrkCh3]
	or a
	jr z, .l6B64
	ld hl, wRegShadow + $0A
	ld de, rNR30
	ld b, $05
	call CopyRegs
.l6B64:
	ld a, [wTrkSfxN]
	or a
	ret z
	cp $08
	ret c
	ld hl, wRegShadow + $10
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

; PeriodTable: 96 periods from C of octave 1.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7

; WaveTable: CH3 waves by duty - 1 (15 pointers to 12 waves; the last runs 2 bytes into
; the sound table).
WaveTable:
	dw WaveData1 ; wave 1
	dw WaveData1 ; wave 2
	dw WaveData3 ; wave 3
	dw WaveData3 ; wave 4
	dw WaveData5 ; wave 5
	dw WaveData5 ; wave 6
	dw WaveData7 ; wave 7
	dw WaveData8 ; wave 8
	dw WaveData9 ; wave 9
	dw WaveData10 ; wave 10
	dw WaveData11 ; wave 11
	dw WaveData12 ; wave 12
	dw WaveData13 ; wave 13
	dw WaveData14 ; wave 14
	dw WaveData15 ; wave 15
WaveData1:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
WaveData3:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
WaveData5:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
WaveData7:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
WaveData8:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
WaveData9:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
WaveData10:
	db $CB, $AA, $CD, $B7, $89, $63, $64, $54, $CB, $AA, $CD, $B7, $89, $63, $64, $54
WaveData11:
	db $FE, $12, $DC, $34, $BA, $56, $98, $78, $FE, $12, $DC, $34, $BA, $56, $98, $78
WaveData12:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72
WaveData13:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
WaveData14:
	db $34, $45, $56, $67, $89, $AA, $BB, $CD, $34, $45, $56, $67, $89, $AB, $CD, $EF
WaveData15:
	db $11, $33, $55, $77, $99, $BB, $DD, $BB, $22, $44, $66, $88, $AA, $CC

; SoundTable: ids $01-$6A (entry 0 unused; the code adds 2 * id).
SoundTable:
	dw $11BB ; $00 (unused: id 0 is StopAll)
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

SndHdr07:
	SND_HEADER $80, 14, $02 ; tracks: Sfx2
	dw Snd07_Sfx2

SndHdr08:
	SND_HEADER $05, 14, $01 ; tracks: Sfx1
	dw Snd08_Sfx1

SndHdr09:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0A:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd0A_Sfx1

SndHdr0B:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd0B_Sfx1

SndHdr0C:
	SND_HEADER $08, 14, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $08, 14, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd0E_Sfx1

SndHdr0F:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd0F_Sfx1

SndHdr10:
	SND_HEADER $40, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd10_Sfx1
	dw Snd10_Sfx2

SndHdr11:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $40, 14, $04 ; tracks: SfxN
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr1F:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd21_Sfx1

SndHdr22:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr23:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

SndHdr24:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd25_Sfx1

SndHdr26:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd26_Sfx1

SndHdr27:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $25, 14, $04 ; tracks: SfxN
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd29_Sfx1

SndHdr2A:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd2A_Sfx1

SndHdr2B:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd2D_Sfx1

SndHdr2E:
	SND_HEADER $50, 14, $23 ; tracks: Sfx1, Sfx2, Ch3
	dw Snd2E_Sfx1
	dw Snd2E_Sfx2
	dw Snd2E_Ch3

SndHdr2F:
	SND_HEADER $50, 14, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd2F_Ch1
	dw Snd2F_Ch2
	dw Snd2F_Ch3

SndHdr30:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd30_Sfx1

SndHdr31:
	SND_HEADER $10, 14, $01 ; tracks: Sfx1
	dw Snd31_Sfx1

SndHdr32:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $50, 14, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd2E_Sfx1
	dw Snd2E_Sfx2
	dw Snd34_Ch3

SndHdr35:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd35_Sfx1

SndHdr36:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd36_Sfx1

SndHdr37:
	SND_HEADER $25, 14, $04 ; tracks: SfxN
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr39:
	SND_HEADER $50, 14, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd39_Ch1
	dw Snd39_Ch2
	dw Snd39_Ch3

SndHdr3A:
	SND_HEADER $20, 14, $01 ; tracks: Sfx1
	dw Snd3A_Sfx1

SndHdr3B:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd3B_Sfx1

SndHdr3C:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd3C_Sfx1

SndHdr3D:
	SND_HEADER $50, 14, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $40, 14, $01 ; tracks: Sfx1
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $35, 14, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $35, 14, $01 ; tracks: Sfx1
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd43_Sfx1

SndHdr44:
	SND_HEADER $15, 14, $01 ; tracks: Sfx1
	dw Snd44_Sfx1

SndHdr45:
	SND_HEADER $35, 14, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd45_Ch1
	dw Snd45_Ch2
	dw Snd45_Ch3

SndHdr46:
	SND_HEADER $30, 14, $01 ; tracks: Sfx1
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $25, 14, $04 ; tracks: SfxN
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $25, 14, $04 ; tracks: SfxN
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $25, 14, $01 ; tracks: Sfx1
	dw Snd49_Sfx1

SndHdr4A:
	SND_HEADER $35, 14, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $35, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd4B_Sfx1
	dw Snd4B_Sfx2

SndHdr4C:
	SND_HEADER $35, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd4C_Sfx1
	dw Snd4C_Sfx2

SndHdr4D:
	SND_HEADER $35, 14, $03 ; tracks: Sfx1, Sfx2
	dw Snd4D_Sfx1
	dw Snd4D_Sfx2

SndHdr4E:
	SND_HEADER $35, 14, $20 ; tracks: Ch3
	dw Snd4E_Ch3

SndHdr4F:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd4F_Ch1
	dw Snd4F_Ch2
	dw Snd4F_Ch3
	dw Snd4F_Drm

SndHdr50:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd50_Ch1
	dw Snd50_Ch2
	dw Snd50_Ch3
	dw Snd50_Drm

SndHdr51:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd51_Ch1
	dw Snd51_Ch2
	dw Snd51_Ch3
	dw Snd51_Drm

SndHdr52:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd52_Ch1
	dw Snd52_Ch2
	dw Snd52_Ch3
	dw Snd52_Drm

SndHdr53:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd53_Ch1
	dw Snd53_Ch2
	dw Snd53_Ch3
	dw Snd53_Drm

SndHdr54:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd54_Ch1
	dw Snd54_Ch2
	dw Snd54_Ch3
	dw Snd54_Drm

SndHdr55:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd55_Ch1
	dw Snd55_Ch2
	dw Snd55_Ch3
	dw Snd55_Drm

SndHdr56:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd56_Ch1
	dw Snd56_Ch2
	dw Snd56_Ch3
	dw Snd56_Drm

SndHdr57:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd57_Ch1
	dw Snd57_Ch2
	dw Snd57_Ch3
	dw Snd57_Drm

SndHdr58:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd58_Ch1
	dw Snd58_Ch2
	dw Snd58_Ch3
	dw Snd58_Drm

SndHdr59:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd59_Ch1
	dw Snd59_Ch2
	dw Snd59_Ch3
	dw Snd59_Drm

SndHdr5A:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5A_Ch1
	dw Snd5A_Ch2
	dw Snd5A_Ch3
	dw Snd5A_Drm

SndHdr5B:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5B_Ch1
	dw Snd5B_Ch2
	dw Snd5B_Ch3
	dw Snd5B_Drm

SndHdr5C:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5C_Ch1
	dw Snd5C_Ch2
	dw Snd5C_Ch3
	dw Snd5C_Drm

SndHdr5D:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5D_Ch1
	dw Snd5D_Ch2
	dw Snd5D_Ch3
	dw Snd5D_Drm

SndHdr5E:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5E_Ch1
	dw Snd5E_Ch2
	dw Snd5E_Ch3
	dw Snd5E_Drm

SndHdr5F:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd5F_Ch1
	dw Snd5F_Ch2
	dw Snd5F_Ch3
	dw Snd5F_Drm

SndHdr60:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd60_Ch1
	dw Snd60_Ch2
	dw Snd60_Ch3
	dw Snd60_Drm

SndHdr61:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd61_Ch1
	dw Snd61_Ch2
	dw Snd61_Ch3
	dw Snd61_Drm

SndHdr62:
	SND_HEADER $30, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd62_Ch1
	dw Snd62_Ch2
	dw Snd62_Ch3
	dw Snd62_Drm

SndHdr63:
	SND_HEADER $30, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd63_Ch1
	dw Snd63_Ch2
	dw Snd63_Ch3
	dw Snd63_Drm

SndHdr64:
	SND_HEADER $30, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd64_Ch1
	dw Snd64_Ch2
	dw Snd64_Ch3
	dw Snd64_Drm

SndHdr65:
	SND_HEADER $30, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd65_Ch1
	dw Snd65_Ch2
	dw Snd65_Ch3
	dw Snd65_Drm

SndHdr66:
	SND_HEADER $30, 14, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd66_Ch1
	dw Snd66_Ch2
	dw Snd66_Ch3
	dw Snd66_Drm

SndHdr67:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd67_Ch1
	dw Snd67_Ch2
	dw Snd67_Ch3
	dw Snd67_Drm

SndHdr68:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd68_Ch1
	dw Snd68_Ch2
	dw Snd68_Ch3
	dw Snd68_Drm

SndHdr69:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd69_Ch1
	dw Snd69_Ch2
	dw Snd69_Ch3
	dw Snd69_Drm

SndHdr6A:
	SND_HEADER $30, 15, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6A_Ch1
	dw Snd6A_Ch2
	dw Snd6A_Ch3
	dw Snd6A_Drm

; DrumMap: drum note hi - 1 -> sound id.
DrumMap:
	db $01, $02, $01, $03, $03, $03, $03, $04, $05, $06, $06, $06

SndHdr01:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $01, 14, $04 ; tracks: SfxN
	dw Snd06_SfxN

Snd01_SfxN:
	NVOICE $01, 7, 1
	NOISE $01
	SND_END

Snd02_SfxN:
	NVOICE $01, 5, 2
	NOISE $1C
	SND_END

Snd03_SfxN:
	NVOICE $01, 8, 1
	NOISE $11
	NOISE $21
	SND_END

Snd04_SfxN:
	NVOICE $01, 12, 1
	NOISE $4D
	NOISE $31
	NOISE $11
	SND_END

Snd05_SfxN:
	NVOICE $01, 7, 1
	NOISE $36
	NOISE $23
	SND_END

Snd06_SfxN:
	NVOICE $01, 13, 1
	NOISE $01
	SND_END

; VibratoTable: 15 pointers (EA 2n uses entry n).
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
	VIB_HOLD

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
	VIB_STEP 1, 1, $020
	VIB_SEGNO
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $000
	VIB_REPEAT $FF

Vib08:
	VIB_STEP 15, 0, $001
	VIB_HOLD

Vib09:
	VIB_STEP 1, 1, $028
	VIB_STEP 1, 1, $020
	VIB_STEP 1, 1, $010
	VIB_STEP 1, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $004
	VIB_STEP 2, 0, $003
	VIB_STEP 2, 0, $002
	VIB_STEP 2, 0, $001
	VIB_STEP 2, 0, $001
	VIB_REPEAT $FF

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

Vib0F:
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

Vib0E:
	VIB_STEP 1, 1, $001
	VIB_STEP 1, 1, $004
	VIB_STEP 1, 1, $019
	VIB_STEP 1, 1, $044
	VIB_STEP 1, 1, $068
	VIB_STEP 1, 1, $077
	VIB_STEP 1, 1, $088
	VIB_STEP 1, 1, $099
	VIB_HOLD

Vib06:
	VIB_STEP 2, 0, $000
	VIB_SEGNO
	VIB_STEP 2, 0, $0F0
	VIB_STEP 2, 0, $0E0
	VIB_STEP 2, 0, $0F0
	VIB_STEP 2, 0, $0E0
	VIB_REPEAT $FF

Snd07_Sfx2:
	VOICE $03, 15, 8, 1, 15
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 6
	SND_END

Snd08_Sfx1:
	VOICE $01, 9, 8, 1, 15
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
	TRANSPOSE_UP 9
	VIBRATO 10
	VOICE $01, 12, 8, 15, 0
	SND_CALL Snd09_Sfx1_7222
	ATTEN 8
	SND_CALL Snd09_Sfx1_7222
	ATTEN $0A
	SND_CALL Snd09_Sfx1_7222
	SND_CALL Snd09_Sfx1_7222
	SND_END
Data_7207:
	TRANSPOSE_UP 9
	VIBRATO 4
	VOICE $01, 4, 4, 15, 0
	OCTAVE 4
	NOTE C_, 7
	NOTE G_, 4
	NOTE E_, 4
	SND_CALL Snd09_Sfx1_7222
	ATTEN 1
	SND_CALL Snd09_Sfx1_7222
	ATTEN 2
	SND_CALL Snd09_Sfx1_7222
	SND_CALL Snd09_Sfx1_7222
	SND_END
Snd09_Sfx1_7222:
	OCTAVE 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE E_, 4
	SND_RET

Snd0A_Sfx1:
	VOICE $02, 11, 8, 15, 0
	OCTAVE 5
	NOTE A_, 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	ATTEN 5
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	ATTEN 8
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	SND_END

Snd0B_Sfx1:
	VOICE $02, 11, 8, 15, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	SND_END

Snd0C_Sfx1:
	VOICE $01, 8, 4, 0, 0
	OCTAVE 5
	NOTE B_, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_SEGNO
	DUTY 4
	NOTE D#, 1
	DUTY 0
	NOTE D_, 1
	SND_REPEAT $0F
	PAN $F0
	SND_SEGNO
	ATTEN 4
	DUTY 4
	NOTE D#, 1
	DUTY 0
	NOTE D_, 1
	SND_REPEAT 5
	PAN $FF
	SND_END

Snd0D_Sfx1:
	VOICE $01, 12, 0, 8, 6
	OCTAVE 6
	NOTE C#, 1
	ATTEN 4
	OCTAVE 5
	NOTE G#, 1
	VOICE $01, 9, 4, 8, 6
	NOTE F#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F#, 1
	VOICE $01, 5, 4, 8, 6
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

Snd0E_Sfx1:
	VOICE $01, 12, 4, 6, 15
	OCTAVE 6
	NOTE F_, 1
	ATTEN 2
	OCTAVE 5
	NOTE F_, 1
	ATTEN 4
	SND_CALL Snd0E_Sfx1_72B4
	ATTEN 6
	SND_CALL Snd0E_Sfx1_72B4
	ATTEN 7
	SND_CALL Snd0E_Sfx1_72B4
	ATTEN $0A
	SND_CALL Snd0E_Sfx1_72B4
	SND_END
Snd0E_Sfx1_72B4:
	SND_SEGNO
	OCTAVE 5
	NOTE A_, 1
	NOTE G#, 3
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 3
	SND_REPEAT 2
	SND_RET

Snd0F_Sfx1:
	VOICE $01, 10, 8, 2, 15
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

Snd10_Sfx1:
	VOICE $01, 14, 4, 4, 15
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	SND_CALL Snd10_Sfx1_7343
	PAN $0F
	ATTEN 6
	SND_CALL Snd10_Sfx1_7343
	NOTE B_, 1
	OCTAVE 4
	SND_CALL Snd10_Sfx1_7343
	NOTE B_, 1
	OCTAVE 5
	SND_CALL Snd10_Sfx1_7343
	PAN $F0
	ATTEN $0A
	OCTAVE 3
	NOTE C#, 1
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
	PAN $FF
	SND_END

Snd10_Sfx2:
	TRANSPOSE_UP 4
	VIBRATO 4
	VOICE $01, 5, 0, 4, 15
	REST 2
	OCTAVE 1
	SND_CALL Snd10_Sfx1_7343
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	SND_CALL Snd10_Sfx1_7343
	OCTAVE 2
	SND_CALL Snd10_Sfx1_7343
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	SND_CALL Snd10_Sfx1_7343
	SND_END
Snd10_Sfx1_7343:
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET

Snd11_Sfx1:
	TRANSPOSE_UP 9
	VOICE $01, 10, 8, 0, 0
	ATTEN 2
	OCTAVE 5
	NOTE G#, 1
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 5
	NOTE G_, 1
	OCTAVE 6
	NOTE G_, 1
	ATTEN 3
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 6
	NOTE F#, 1
	ATTEN 4
	OCTAVE 5
	NOTE F#, 2
	OCTAVE 6
	NOTE F#, 2
	ATTEN 5
	SND_SEGNO
	OCTAVE 5
	NOTE F#, 2
	OCTAVE 6
	NOTE F#, 2
	SND_REPEAT 3
	SND_END

Snd12_Sfx1:
	VOICE $01, 14, 4, 0, 0
	SND_CALL Snd12_Sfx1_737F
	ATTEN 4
	SND_CALL Snd12_Sfx1_737F
	ATTEN 6
	SND_CALL Snd12_Sfx1_737F
	ATTEN 7
	SND_CALL Snd12_Sfx1_737F
	SND_END
Snd12_Sfx1_737F:
	OCTAVE 5
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 1
	SND_RET

Snd13_Sfx1:
	VOICE $01, 10, 4, 1, 15
	OCTAVE 6
	NOTE B_, 1
	NOTE A_, 1
	REST 1
	VOICE $01, 9, 8, 1, 15
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

Snd14_Sfx1:
	VOICE $01, 15, 4, 6, 9
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

Snd15_Sfx1:
	VOICE $01, 9, 0, 1, 15
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
	VOICE $01, 9, 0, 2, 15
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

Snd16_Sfx1:
	TRANSPOSE_UP 5
	VOICE $01, 11, 0, 0, 0
	SND_CALL Snd16_Sfx1_740D
	SND_END
Snd16_Sfx1_740D:
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
	SND_RET

Snd17_Sfx1:
	TRANSPOSE_DOWN 4
	VOICE $01, 15, 0, 0, 0
	SND_CALL Snd16_Sfx1_740D
	SND_END

Snd18_Sfx1:
	VOICE $01, 15, 0, 6, 9
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	VOICE $01, 10, 0, 6, 9
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	SND_REPEAT 2
	SND_END

Snd19_Sfx1:
	VOICE $01, 12, 0, 6, 9
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

Snd1A_Sfx1:
	VOICE $01, 15, 8, 6, 9
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	SND_SEGNO
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
	SND_REPEAT 3
	SND_SEGNO
	NOTE C_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_END

Snd1B_Sfx1:
	TRANSPOSE_UP 3
	VOICE $01, 13, 8, 15, 0
	SND_CALL Snd1B_Sfx1_74AD
	SND_END
Snd1B_Sfx1_74AD:
	VIBRATO 9
	OCTAVE 3
	NOTE E_, 2
	REST 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE G#, 1
	VOICE $01, 6, 8, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_RET

Snd1C_Sfx1:
	TRANSPOSE_DOWN 3
	VOICE $01, 15, 0, 8, 6
	SND_SEGNO
	ATTEN 2
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	SND_REPEAT 8
	SND_END

Snd1D_SfxN:
	NVOICE $0C, 10, 5
	NOISE $41
	NVOICE $10, 15, 4
	NOISE $31
	NOISE $21
	NOISE $11
	NVOICE $0C, 2, 8
	NOISE $41
	NVOICE $10, 4, 7
	NOISE $31
	NOISE $21
	NOISE $21
	NOISE $21
	NOISE $21
	SND_END

Snd1E_Sfx1:
	VIBRATO 10
	VOICE $03, 15, 12, 4, 15
	OCTAVE 5
	NOTE G#, 2
	NOTE E_, 6
	ATTEN $0A
	NOTE E_, 3
	SND_END

Snd1F_Sfx1:
	VOICE $02, 15, 8, 15, 0
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
	LEN_UNIT $01
	SND_CALL Snd1F_Sfx1_7534
	ATTEN 5
	SND_CALL Snd1F_Sfx1_7534
	ATTEN $0A
	SND_CALL Snd1F_Sfx1_7534
	SND_END
Snd1F_Sfx1_7534:
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

Snd20_Sfx1:
	VOICE $01, 15, 8, 4, 15
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_END

Snd21_Sfx1:
	VOICE $01, 15, 8, 4, 15
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd22_Sfx1:
	VOICE $02, 15, 12, 8, 15
	VIBRATO 7
	SND_CALL Snd22_Sfx1_75BF
	SND_END
Snd22_Sfx1_75BF:
	ATTEN $0A
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE F_, 1
	NOTE F#, 1
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 3
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	ATTEN 7
	NOTE C_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE C_, 1
	SND_RET

Snd23_Sfx1:
	VOICE $01, 12, 8, 15, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	ATTEN $0A
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd24_Sfx1:
	VOICE $01, 15, 4, 4, 15
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE D_, 1
	ATTEN $0A
	SND_REPEAT 3
	SND_END

Snd25_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 13, 8, 15, 0
	SND_CALL Snd25_Sfx1_7613
	ATTEN 3
	SND_CALL Snd25_Sfx1_7613
	ATTEN 7
	SND_CALL Snd25_Sfx1_7613
	SND_END
Snd25_Sfx1_7613:
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	SND_RET

Snd26_Sfx1:
	TRANSPOSE_UP 7
	VOICE $01, 10, 0, 15, 0
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	SND_END

Snd27_Sfx1:
	VOICE $01, 14, 0, 4, 15
	OCTAVE 5
	NOTE C_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 7
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_END

Snd28_SfxN:
	NVOICE $08, 10, 8
	NOISE $3B
	NOISE $3B
	SND_END

Snd29_Sfx1:
	VOICE $02, 14, 0, 2, 15
	DUTY_STEP 4, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE G_, 4
	NOTE A#, 4
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 8
	SND_END

Snd2A_Sfx1:
	VOICE $02, 8, 8, 3, 15
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	SND_END

Snd2B_Sfx1:
	VOICE $02, 8, 8, 3, 15
	DUTY_STEP 0, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd2C_Sfx1:
	VOICE $02, 8, 8, 3, 15
	DUTY_STEP 0, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd2D_Sfx1:
	VOICE $02, 8, 8, 3, 15
	DUTY_STEP 0, 1
	OCTAVE 5
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd2E_Sfx1:
	TRANSPOSE_UP $0A
	TEMPO $00
	VOICE $01, 15, 8, 15, 0
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 5
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 7
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	VOICE $01, 12, 8, 15, 0
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 9
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN $0A
	SND_CALL Snd2E_Sfx1_7738
	SND_END

Snd2E_Sfx2:
	VOICE $01, 13, 4, 15, 0
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 4
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 6
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN $0A
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_END

Snd2E_Ch3:
	VOICE $01, 2, 13, 15, 0
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	ATTEN 2
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_END

Snd34_Ch3:
	VOICE $01, 2, 6, 15, 0
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	ATTEN 2
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_CALL Snd34_Ch3_7764
	SND_END
Snd2E_Sfx1_7738:
	OCTAVE 3
	NOTE A_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_RET
Snd2E_Sfx2_7745:
	PAN $0F
	OCTAVE 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	PAN $F0
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	PAN $FF
	SND_RET
Snd2E_Ch3_7757:
	OCTAVE 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE C_, 1
	SND_RET
Snd34_Ch3_7764:
	OCTAVE 3
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE B_, 1
	SND_RET

Snd2F_Ch1:
	TEMPO $00
	VOICE $03, 10, 8, 15, 0
	OCTAVE 5
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE F_, 1
	TEMPO $40
	ATTEN 4
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 5
	NOTE F_, 1
	NOTE D#, 1
	ATTEN 6
	NOTE E_, 1
	NOTE D_, 1
	ATTEN 7
	NOTE D#, 1
	NOTE C#, 1
	ATTEN 8
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	TEMPO $60
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 9
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
	NOTE C#, 1
	SND_END

Snd2F_Ch2:
	VOICE $03, 10, 4, 15, 0
	OCTAVE 5
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 3
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	ATTEN 4
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	ATTEN 5
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 6
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	PAN $F0
	ATTEN 7
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 8
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	PAN $FF
	SND_END

Snd2F_Ch3:
	VOICE $08, 2, 13, 15, 0
	OCTAVE 3
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

Snd30_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 13, 8, 15, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_CALL Snd30_Sfx1_7816
	ATTEN 6
	SND_CALL Snd30_Sfx1_7816
	ATTEN 8
	SND_CALL Snd30_Sfx1_7816
	ATTEN $0A
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_END
Snd30_Sfx1_7816:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_RET

Snd31_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 12, 0, 3, 15
	OCTAVE 5
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 2
	NOTE G_, 2
	NOTE C_HI, 1
	ATTEN 3
	NOTE A_, 4
	ATTEN 5
	NOTE E_, 2
	NOTE C_HI, 1
	NOTE F_, 2
	NOTE D#, 1
	NOTE G#, 1
	ATTEN $0A
	NOTE F_, 1
	SND_END
Data_7838:
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE A_, 4
	NOTE B_, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE G#, 1
	SND_END

Snd32_Sfx1:
	VOICE $02, 13, 0, 3, 15
	OCTAVE 5
	NOTE C_, 1
	NOTE F#, 1
	SND_END

Snd33_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 15, 4, 15, 0
	SND_CALL Snd33_Sfx1_785A
	ATTEN 5
	SND_CALL Snd33_Sfx1_785A
	ATTEN $0A
	SND_CALL Snd33_Sfx1_785A
	SND_END
Snd33_Sfx1_785A:
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	SND_RET

Snd35_Sfx1:
	TRANSPOSE_UP 0
	VOICE $01, 11, 4, 15, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	REST 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	ATTEN 8
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	REST 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE F#, 1
	SND_END

Snd36_Sfx1:
	VOICE $02, 15, 8, 15, 0
	SND_CALL Snd25_Sfx1_7613
	ATTEN 6
	SND_CALL Snd25_Sfx1_7613
	SND_CALL Snd25_Sfx1_7613
	ATTEN 8
	SND_CALL Snd25_Sfx1_7613
	ATTEN $0A
	SND_CALL Snd25_Sfx1_7613
	SND_END

Snd37_SfxN:
	NVOICE $07, 15, 7
	NOISE $71
	NOISE $64
	NOISE $73
	NOISE $64
	NOISE $74
	NOISE $64
	NOISE $75
	NOISE $64
	NOISE $75
	NOISE $64
	NOISE $75
	NOISE $64
	NOISE $75
	SND_END

Snd38_Sfx1:
	VIBRATO 15
	VOICE $02, 12, 8, 15, 0
	DUTY_STEP 4, 2
	OCTAVE 4
	NOTE F_, 2
	REST 3
	NOTE B_, 2
	REST 4
	SND_END

Snd39_Ch1:
	TEMPO $00
	TRANSPOSE_UP 0
	VOICE $01, 15, 8, 15, 0
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_DOWN 5
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_DOWN 5
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_DOWN 5
	ATTEN 3
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_DOWN 5
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	SND_CALL Snd39_Ch1_7994
	TEMPO $20
	TRANSPOSE_DOWN 5
	ATTEN 5
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	SND_CALL Snd39_Ch1_7994
	TEMPO $30
	TRANSPOSE_DOWN 5
	ATTEN 7
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_UP 0
	VOICE $01, 12, 8, 15, 0
	SND_CALL Snd39_Ch1_7994
	TRANSPOSE_DOWN 5
	SND_CALL Snd39_Ch1_7994
	TEMPO $00
	SND_END

Snd39_Ch2:
	TRANSPOSE_UP 0
	VOICE $01, 12, 0, 15, 0
	REST 2
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 1
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 3
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 5
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 7
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 8
	ATTEN 3
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN 9
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN $0A
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN $0B
	ATTEN 6
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN $0C
	SND_CALL Snd39_Ch2_79A2
	SND_CALL Snd39_Ch2_79A2
	SND_CALL Snd39_Ch2_79A2
	TRANSPOSE_DOWN $0D
	PAN $F0
	ATTEN 8
	SND_CALL Snd39_Ch2_79A2
	SND_CALL Snd39_Ch2_79A2
	SND_END

Snd39_Ch3:
	TRANSPOSE_UP 0
	VOICE $01, 2, 6, 15, 0
	REST 3
	SND_CALL Snd39_Ch3_79AF
	WAVE 2
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	ATTEN 1
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	ATTEN 2
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_CALL Snd39_Ch3_79AF
	SND_END
Snd39_Ch1_7994:
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	SND_RET
Snd39_Ch2_79A2:
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE C_, 1
	SND_RET
Snd39_Ch3_79AF:
	PAN $0F
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_RET

Snd3A_Sfx1:
	TRANSPOSE_DOWN 3
	VOICE $01, 15, 8, 15, 0
	SND_CALL Snd1B_Sfx1_74AD
	SND_END

Snd3B_Sfx1:
	VOICE $01, 15, 8, 6, 9
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	SND_SEGNO
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
	SND_REPEAT 3
	SND_SEGNO
	NOTE C_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT 4
	ATTEN 7
	NOTE C_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd3C_Sfx1:
	TRANSPOSE_UP $0C
	VOICE $01, 10, 4, 15, 0
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	NOTE C#, 1
	NOTE D#, 1
	REST 2
	NOTE D_, 1
	NOTE E_, 1
	SND_END

Snd3D_Sfx1:
	TEMPO $00
	TRANSPOSE_DOWN 6
	VOICE $01, 15, 8, 7, 15
	SND_CALL Snd3D_Sfx1_7A16
	ATTEN 5
	SND_CALL Snd3D_Sfx1_7A16
	ATTEN 9
	SND_CALL Snd3D_Sfx1_7A16
	SND_END
Snd3D_Sfx1_7A16:
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	REST 3
	SND_RET

Snd3E_Sfx1:
	TRANSPOSE_UP $0F
	VOICE $02, 15, 8, 8, 15
	VIBRATO 7
	SND_CALL Snd22_Sfx1_75BF
	SND_END

Snd3F_Sfx1:
	TRANSPOSE_UP $0C
	VOICE $02, 8, 0, 15, 0
	OCTAVE 6
	NOTE G#, 1
	NOTE A_, 1
	REST 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	REST 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_END

Snd40_Sfx1:
	VOICE $01, 9, 4, 15, 0
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE D_, 1
	DUTY 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	ATTEN 2
	DUTY 8
	NOTE G_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE A_, 1
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 6
	ATTEN 1
	SND_SEGNO
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	SND_REPEAT 6
	ATTEN 0
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	ATTEN 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G_, 1
	ATTEN 4
	DUTY 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 6
	DUTY 8
	NOTE D_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE F#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 0
	SND_END
Data_7A9F:
	VOICE $02, 13, 8, 15, 0
	SND_CALL Data_7AB7
	ATTEN 5
	SND_CALL Data_7AB7
	ATTEN 7
	SND_CALL Data_7AB7
	ATTEN 9
	SND_CALL Data_7AB7
	ATTEN $0A
	SND_CALL Data_7AB7
	SND_END
Data_7AB7:
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	SND_RET

Snd41_Sfx1:
	VOICE $01, 13, 8, 15, 0
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 1
	REST 1
	NOTE G_, 1
	ATTEN 7
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_END

Snd42_Sfx1:
	VOICE $01, 15, 0, 15, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	SND_REPEAT $0A
	SND_END

Snd43_Sfx1:
	VOICE $01, 15, 8, 15, 0
	ATTEN 8
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 5
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 1
	ATTEN 3
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 2
	ATTEN 2
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 3
	ATTEN 1
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 4
	ATTEN 0
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 5
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 6
	SND_CALL Snd43_Sfx1_7B1C
	TRANSPOSE_UP 7
	SND_CALL Snd43_Sfx1_7B1C
	SND_CALL Snd43_Sfx1_7B1C
	SND_END
Snd43_Sfx1_7B1C:
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_RET

Snd44_Sfx1:
	VIBRATO 7
	VOICE $01, 13, 0, 15, 0
	OCTAVE 3
	NOTE A#, 4
	SND_CALL Snd44_Sfx1_7B4C
	SND_CALL Snd44_Sfx1_7B4C
	SND_CALL Snd44_Sfx1_7B4C
	ATTEN 4
	SND_CALL Snd44_Sfx1_7B4C
	SND_CALL Snd44_Sfx1_7B4C
	ATTEN 7
	SND_CALL Snd44_Sfx1_7B4C
	SND_CALL Snd44_Sfx1_7B4C
	ATTEN $0A
	SND_CALL Snd44_Sfx1_7B4C
	SND_CALL Snd44_Sfx1_7B4C
	SND_END
Snd44_Sfx1_7B4C:
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C#, 1
	SND_RET

Snd45_Ch1:
	TRANSPOSE_UP $0A
	TEMPO $00
	VOICE $01, 15, 8, 15, 0
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 3
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 4
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	ATTEN 7
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_CALL Snd2E_Sfx1_7738
	SND_END

Snd45_Ch2:
	VOICE $01, 10, 4, 15, 0
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 4
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 5
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 6
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	ATTEN 8
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_CALL Snd2E_Sfx2_7745
	SND_END

Snd45_Ch3:
	VOICE $01, 2, 8, 15, 0
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_CALL Snd2E_Ch3_7757
	SND_END
	db $FF ; unreachable byte after an end

Snd46_Sfx1:
	TRANSPOSE_UP 8
	VOICE $01, 13, 4, 15, 0
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 8
	SND_REPEAT 2
	OCTAVE 4
	NOTE D_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	SND_END

Snd47_SfxN:
	NVOICE $0A, 10, 8
	NOISE $59
	NOISE $59
	NOISE $59
	NVOICE $0A, 9, 8
	NOISE $59
	NOISE $59
	NOISE $59
	NVOICE $0A, 8, 8
	NOISE $59
	NOISE $59
	NOISE $59
	NVOICE $0A, 6, 5
	NOISE $69
	NOISE $69
	SND_END

Snd48_SfxN:
	NVOICE $06, 15, 2
	NOISE $54
	NOISE $35
	NOISE $32
	NOISE $26
	NOISE $98
	NOISE $32
	SND_END

Snd49_Sfx1:
	VOICE $01, 13, 4, 15, 0
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_END

Snd4A_Sfx1:
	VOICE $04, 15, 4, 4, 15
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	ATTEN 6
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 6
	NOTE D_, 1
	LEN_UNIT $02
	REST 1
	ATTEN 8
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	SND_END

Snd4B_Sfx1:
	TRANSPOSE_UP 0
	VOICE $0F, 13, 8, 7, 13
	SWEEP $57
	OCTAVE 1
	NOTE G#, $0A
	SWEEP $00
	SND_END

Snd4B_Sfx2:
	VIBRATO 4
	VOICE $01, 6, 4, 7, 9
	REST 3
	LEN_UNIT $0F
	OCTAVE 1
	NOTE G#, $0A
	SND_END

Snd4C_Sfx1:
	VOICE $01, 12, 0, 3, 15
	OCTAVE 6
	NOTE C_, 1
	ATTEN 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 6
	ATTEN 3
	NOTE E_, 4
	ATTEN 6
	OCTAVE 5
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 6
	NOTE E_, 1
	ATTEN $0A
	OCTAVE 5
	NOTE A_, 1
	NOTE B_, 1
	LEN_UNIT $08
	OCTAVE 6
	NOTE E_, 6
	SND_END

Snd4C_Sfx2:
	VIBRATO 4
	VOICE $01, 8, 0, 3, 10
	OCTAVE 6
	NOTE C_, 1
	ATTEN 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 6
	ATTEN 3
	NOTE E_, 4
	ATTEN 4
	OCTAVE 5
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 6
	NOTE E_, 1
	ATTEN 5
	OCTAVE 5
	NOTE A_, 1
	NOTE B_, 1
	LEN_UNIT $08
	ATTEN 6
	OCTAVE 6
	NOTE E_, 6
	SND_END

Snd4D_Sfx1:
	VOICE $01, 10, 4, 15, 0
	VIBRATO 9
	OCTAVE 4
	NOTE E_, 2
	REST 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	ATTEN 2
	NOTE F_, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 7
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_END

Snd4D_Sfx2:
	VOICE $01, 5, 8, 15, 0
	VIBRATO 4
	REST 2
	OCTAVE 4
	NOTE E_, 2
	REST 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	ATTEN 2
	NOTE F_, 1
	ATTEN 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	SND_END

Snd4E_Ch3:
	VOICE $05, 6, 10, 1, 8
	SND_SEGNO
	OCTAVE 6
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE D#, 1
	SND_REPEAT $F0
	SND_END

SECTION "Sound bank 15", ROMX[$4000], BANK[15]

; Songs $4F-$61 and $67-$6A.

Snd4F_Ch2:
	TEMPO $30
	VOICE $04, 9, 4, 2, 14
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
Snd4F_Ch2_400A:
	VIBRATO 7
	VOICE $04, 9, 4, 2, 14
	DUTY 0
	OCTAVE 4
	NOTE G_, 4
	RELEASE 3, $0F
	NOTE G_, 7
	DUTY 4
	VIBRATO 0
	ATTEN 0
	RELEASE 2, $0E
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
	DUTY 0
	VIBRATO 7
	NOTE G_, 4
	RELEASE 3, $0F
	NOTE G_, 7
	DUTY 4
	VIBRATO 0
	RELEASE 2, $0E
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
	NOTE A#, 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
	VIBRATO 7
	DUTY 0
	RELEASE 3, $0E
	NOTE G_, 4
	NOTE G_, 4
	DUTY 4
	VIBRATO 0
	RELEASE 2, $0E
	NOTE E_, 3
	NOTE D_, 1
	NOTE C_, 3
	DUTY 0
	VIBRATO 7
	RELEASE 3, $0E
	NOTE G_, 5
	NOTE G_, 4
	DUTY 4
	VIBRATO 0
	RELEASE 2, $0E
	NOTE E_, 3
	NOTE D_, 1
	NOTE C_, 3
	NOTE D_, 5
	LEN_UNIT $01
	ATTEN 0
	NOTE D_, 5
	ATTEN 3
	NOTE D_, 6
	ATTEN 4
	NOTE D_, 5
	ATTEN 0
	NOTE E_, 5
	ATTEN 3
	NOTE E_, 6
	ATTEN 4
	NOTE E_, 5
	ATTEN 0
	NOTE E_, 5
	ATTEN 3
	NOTE E_, 6
	ATTEN 4
	NOTE E_, 5
	ATTEN 0
	NOTE F_, 5
	ATTEN 3
	NOTE F_, 6
	ATTEN 4
	NOTE F_, 5
	ATTEN 0
	NOTE F_, 5
	ATTEN 3
	NOTE F_, 6
	ATTEN 4
	NOTE F_, 5
	LEN_UNIT $04
	ATTEN 0
	NOTE F#, 4
	RELEASE 7, 3
	NOTE F#, 3
	NOTE G_, 1
	DUTY $0C
	ATTEN 1
	RELEASE 3, $0E
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 1
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 3
	NOTE D_, 1
	NOTE F#, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN_UNIT $01
	NOTE F#, $0B
	NOTE G_, 5
	LEN_UNIT $04
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 1
	NOTE G_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 3
	NOTE D_, 1
	NOTE F#, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	DUTY $0C
	LEN_UNIT $01
	ATTEN 3
	RELEASE 2, $0C
	OCTAVE 3
	NOTE B_, 5
	NOTE A_, 6
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 5
	NOTE D_, $0B
	ATTEN 0
	RELEASE 3, $0F
	NOTE G_, 5
	NOTE A_, $0B
	NOTE A#, 5
	DUTY_STEP 8, 2
	LEN_UNIT $04
	RELEASE 5, $0D
	OCTAVE 4
	NOTE B_, 4
	LEN_UNIT $01
	NOTE E_, $0B
	NOTE B_, 5
	ATTEN 3
	NOTE B_, $0B
	ATTEN 0
	NOTE E_, 5
	ATTEN 3
	NOTE E_, $0B
	ATTEN 0
	NOTE B_, 5
	ATTEN 3
	NOTE B_, $0B
	ATTEN 0
	NOTE B_, 5
	NOTE A_, $0B
	DUTY 0
	PAN $F0
	OCTAVE 5
	NOTE E_, 5
	ATTEN 3
	NOTE E_, $0B
	ATTEN 0
	NOTE E_, 5
	LEN_UNIT $04
	NOTE D_, 4
	PAN $FF
	DUTY $0C
	OCTAVE 4
	NOTE A_, 4
	LEN_UNIT $01
	NOTE D_, $0B
	NOTE A_, 5
	ATTEN 3
	NOTE A_, $0B
	ATTEN 0
	NOTE D_, 5
	ATTEN 3
	NOTE D_, $0B
	ATTEN 0
	NOTE A_, 5
	RELEASE 3, $0E
	ATTEN 3
	NOTE A_, $0B
	ATTEN 0
	NOTE A_, 5
	NOTE G_, $0B
	DUTY 0
	PAN $0F
	OCTAVE 5
	NOTE F#, 5
	ATTEN 3
	NOTE F#, $0B
	ATTEN 0
	NOTE F#, 5
	LEN_UNIT $04
	NOTE E_, 4
	PAN $FF
	DUTY $0C
	RELEASE 5, $0D
	OCTAVE 4
	NOTE G_, 4
	LEN_UNIT $01
	NOTE C_, $0B
	NOTE G_, 5
	ATTEN 3
	NOTE G_, $0B
	ATTEN 0
	NOTE C_, 5
	ATTEN 3
	NOTE C_, $0B
	ATTEN 0
	NOTE G_, 5
	LEN_UNIT $04
	ATTEN 3
	NOTE G_, 4
	ATTEN 0
	NOTE F#, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE E_, 4
	LEN_UNIT $01
	NOTE E_, $0B
	NOTE D_, 5
	LEN_UNIT $04
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	NOTE B_, 8
	RELEASE 2, $0B
	NOTE G_, 4
	NOTE A_, 4
	NOTE A#, 4
	RELEASE 5, $0D
	OCTAVE 4
	NOTE B_, 4
	LEN_UNIT $01
	NOTE E_, $0B
	NOTE B_, 5
	ATTEN 4
	NOTE B_, $0B
	ATTEN 0
	NOTE E_, 5
	ATTEN 4
	NOTE E_, $0B
	ATTEN 0
	NOTE B_, 5
	ATTEN 4
	NOTE B_, $0B
	ATTEN 0
	NOTE B_, 5
	LEN_UNIT $04
	RELEASE 3, $0E
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	RELEASE 5, $0D
	NOTE A_, 4
	LEN_UNIT $01
	NOTE D_, $0B
	NOTE A_, 5
	ATTEN 4
	NOTE A_, $0B
	ATTEN 0
	NOTE D_, 5
	ATTEN 4
	NOTE D_, $0B
	ATTEN 0
	NOTE A_, 5
	ATTEN 4
	NOTE A_, $0B
	ATTEN 0
	NOTE A_, 5
	LEN_UNIT $04
	RELEASE 3, $0E
	NOTE G_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE E_, 3
	NOTE C_, 1
	NOTE E_, 3
	RELEASE $0F, $0A
	NOTE F#, 3
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	RELEASE 3, $0E
	NOTE D_, 1
	NOTE F#, 3
	RELEASE $0F, $0A
	NOTE G_, 3
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE 3, $0E
	NOTE E_, 1
	NOTE G_, 3
	RELEASE $0F, $0A
	NOTE B_, 3
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	RELEASE 3, $0E
	NOTE A_, 1
	NOTE G_, 4
	DUTY_STEP_OFF
	PAN $F0
	RELEASE 6, $0B
	OCTAVE 5
	NOTE E_, 7
	NOTE D_, 1
	PAN $FF
	ATTEN 5
	OCTAVE 5
	NOTE E_, 7
	NOTE D_, 1
	PAN $0F
	OCTAVE 5
	NOTE E_, 7
	NOTE D_, 1
	PAN $FF
	LEN_UNIT $01
	DUTY 8
	ATTEN 0
	REST $0B
	RELEASE 2, $0E
	OCTAVE 4
	NOTE D_, 5
	NOTE E_, $0B
	NOTE D_, 5
	SND_CALL Snd4F_Ch2_400A

Snd4F_Ch1:
	VIBRATO 4
	VOICE $04, 6, 8, 15, 0
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 3
Snd4F_Ch1_41EC:
	VIBRATO 4
	VOICE $04, 6, 8, 3, 14
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 4
	RELEASE 3, $0A
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 3
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 4
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 3
	RELEASE 3, $0E
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 4
	RELEASE 3, $0A
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 3
	NOTE D_, 1
	NOTE A#, 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 1
	NOTE E_, 3
	RELEASE 3, $0E
	ATTEN 0
	NOTE C_, 4
	NOTE C_, 4
	RELEASE 3, $0B
	ATTEN 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE C_, 2
	RELEASE 3, $0E
	ATTEN 0
	NOTE E_, 5
	NOTE E_, 4
	RELEASE 3, $0B
	ATTEN 4
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE C_, 3
	RELEASE 3, 8
	ATTEN 4
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 4
	ATTEN 3
	NOTE G_, 4
	NOTE G_, 4
	ATTEN 2
	NOTE G#, 4
	NOTE G#, 4
	ATTEN 1
	NOTE A_, 4
	LEN_UNIT $01
	NOTE A_, $0B
	RELEASE 7, $0A
	ATTEN 0
	NOTE B_, 5
	LEN_UNIT $04
	RELEASE 3, $0B
	ATTEN 4
	OCTAVE 3
	REST 5
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 2
	ATTEN 1
	RELEASE 2, $0A
	OCTAVE 3
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 4
	RELEASE 3, $0B
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 2
	ATTEN 1
	RELEASE 2, $0A
	OCTAVE 3
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 3
	RELEASE 3, $0B
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 3
	ATTEN 3
	RELEASE 6, $0D
	OCTAVE 3
	NOTE A_, 7
	NOTE A_, 5
	NOTE A_, 7
	RELEASE 5, $0A
	OCTAVE 5
	NOTE D_, 5
	NOTE D_, 1
	NOTE E_, 3
	NOTE D_, 1
	NOTE C_, 3
	REST 5
	RELEASE 3, $0B
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 2
	RELEASE 2, $0A
	ATTEN 1
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 3
	RELEASE 3, $0B
	NOTE G_, 2
	NOTE A_, 3
	RELEASE 2, $0A
	ATTEN 1
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 3
	RELEASE 3, $0B
	NOTE G_, 4
	NOTE A_, 1
	NOTE A#, 3
	ATTEN 1
	RELEASE 3, $0C
	NOTE E_, 7
	NOTE C_, 5
	NOTE A_, 4
	RELEASE 4, $0D
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE F#, 4
	RELEASE 3, $0B
	OCTAVE 3
	REST 4
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	RELEASE 2, $0A
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 4
	RELEASE 3, $0B
	ATTEN 1
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	RELEASE 3, $0B
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 3
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 3
	NOTE A#, 1
	ATTEN 3
	RELEASE 6, $0C
	NOTE A_, 7
	NOTE A_, 5
	NOTE A_, 4
	LEN_UNIT $01
	RELEASE 4, $0A
	OCTAVE 5
	NOTE D_, 5
	NOTE D#, 6
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 6
	NOTE D#, 5
	LEN_UNIT $04
	NOTE D_, 3
	RELEASE 3, $0B
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE C_, 3
	NOTE C_, 1
	RELEASE 5, $0A
	NOTE C_, 7
	OCTAVE 3
	NOTE B_, 5
	NOTE B_, 4
	RELEASE 3, $0C
	OCTAVE 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	RELEASE 5, $0A
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 4
	ATTEN 4
	NOTE B_, 4
	LEN_UNIT $01
	DUTY_STEP 8, 2
	ATTEN 3
	RELEASE 3, $0F
	NOTE B_, 5
	NOTE A_, 6
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 6
	OCTAVE 4
	NOTE C_, 5
	RELEASE 2, $0F
	OCTAVE 4
	NOTE D_, $0B
	DUTY 8
	DUTY_STEP 0, 2
	RELEASE 4, $0E
	NOTE G_, 5
	NOTE A_, $0B
	NOTE A#, 5
	ATTEN 0
	DUTY_STEP_OFF
	LEN_UNIT $04
	RELEASE 4, $0C
	OCTAVE 4
	NOTE G_, 4
	LEN_UNIT $01
	NOTE E_, $0B
	NOTE G_, 5
	ATTEN 3
	NOTE G_, $0B
	ATTEN 0
	NOTE E_, 5
	ATTEN 3
	NOTE E_, $0B
	ATTEN 0
	NOTE G_, 5
	ATTEN 3
	NOTE G_, $0B
	ATTEN 0
	NOTE G_, 5
	NOTE F#, $0B
	PAN $F0
	DUTY 0
	RELEASE 5, $0F
	OCTAVE 4
	NOTE F#, 5
	RELEASE 4, $0B
	NOTE F#, $0B
	NOTE F#, 5
	LEN_UNIT $04
	NOTE F#, 4
	PAN $FF
	DUTY 8
	RELEASE 4, $0C
	NOTE F#, 4
	LEN_UNIT $01
	NOTE D_, $0B
	NOTE F#, 5
	ATTEN 3
	NOTE F#, $0B
	ATTEN 0
	NOTE D_, 5
	ATTEN 3
	NOTE D_, $0B
	ATTEN 0
	NOTE F#, 5
	ATTEN 3
	NOTE F#, $0B
	ATTEN 0
	NOTE F#, 5
	NOTE E_, $0B
	PAN $0F
	DUTY 0
	RELEASE 5, $0F
	NOTE A_, 5
	RELEASE 4, $0B
	NOTE A_, $0B
	NOTE A_, 5
	LEN_UNIT $04
	NOTE G_, 4
	PAN $FF
	DUTY 8
	RELEASE 4, $0C
	NOTE E_, 4
	LEN_UNIT $01
	NOTE C_, $0B
	NOTE E_, 5
	ATTEN 3
	NOTE E_, $0B
	ATTEN 0
	NOTE C_, 5
	ATTEN 3
	NOTE C_, $0B
	ATTEN 0
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 5, $0F
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $01
	ATTEN 3
	NOTE C_, $0B
	ATTEN 0
	OCTAVE 3
	NOTE B_, 5
	LEN_UNIT $04
	ATTEN 3
	NOTE B_, 4
	ATTEN 0
	OCTAVE 4
	NOTE D_, 8
	RELEASE 3, $0C
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	RELEASE 4, $0C
	OCTAVE 4
	NOTE G_, 4
	LEN_UNIT $01
	NOTE C_, $0B
	NOTE G_, 5
	ATTEN 3
	NOTE G_, $0B
	ATTEN 0
	NOTE C_, 5
	ATTEN 3
	NOTE C_, $0B
	ATTEN 0
	NOTE G_, 5
	LEN_UNIT $04
	RELEASE 4, $0E
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE F#, 4
	RELEASE 4, $0C
	NOTE F#, 4
	LEN_UNIT $01
	OCTAVE 3
	NOTE B_, $0B
	OCTAVE 4
	NOTE F#, 5
	ATTEN 3
	NOTE F#, $0B
	ATTEN 0
	OCTAVE 3
	NOTE B_, 5
	ATTEN 3
	NOTE B_, $0B
	ATTEN 0
	OCTAVE 4
	NOTE F#, 5
	LEN_UNIT $04
	RELEASE 3, $0F
	OCTAVE 4
	NOTE F#, 4
	RELEASE 4, $0E
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	RELEASE 3, $0E
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 3
	NOTE E_, 4
	NOTE C_, 1
	NOTE E_, 3
	NOTE G_, 4
	NOTE F#, 1
	NOTE E_, 4
	PAN $F0
	RELEASE 7, $0A
	OCTAVE 5
	NOTE E_, 8
	NOTE D_, 1
	PAN $FF
	ATTEN 3
	OCTAVE 5
	NOTE E_, 7
	NOTE D_, 1
	PAN $0F
	ATTEN 4
	OCTAVE 5
	NOTE E_, 7
	PAN $FF
	LEN_UNIT $01
	ATTEN 2
	REST $0B
	DUTY 4
	RELEASE 3, $0E
	OCTAVE 4
	NOTE D_, 5
	NOTE E_, $0B
	NOTE D_, 5
	SND_CALL Snd4F_Ch1_41EC

Snd4F_Ch3:
	VOICE $04, 2, 8, 5, 13
	REST 5
Snd4F_Ch3_43FE:
	VOICE $04, 2, 8, 5, 13
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 4
	REST 8
	REST 8
	REST 8
	NOTE F_, 4
	NOTE F_, 4
	REST 8
	REST 8
	REST 8
	NOTE E_, 4
	NOTE E_, 4
	REST 8
	NOTE C_, 4
	NOTE C_, 4
	REST 8
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAVE 2
	LEN_UNIT $04
	RELEASE 7, $0A
	ATTEN 0
	REST 4
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	RELEASE 5, $0D
	NOTE D_, 5
	RELEASE 7, $0A
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	RELEASE 5, $0D
	NOTE D_, 4
	RELEASE 7, $0A
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE C#, 1
	RELEASE 7, $0C
	NOTE D_, 7
	NOTE E_, 5
	NOTE D_, 6
	REST 1
	PAN $F0
	WAVE 4
	RELEASE 4, $0C
	OCTAVE 5
	NOTE D_, 4
	NOTE D_, 1
	RELEASE 7, 6
	NOTE E_, 3
	NOTE D_, 1
	NOTE C_, 3
	OCTAVE 4
	NOTE A_, 1
	PAN $FF
	WAVE 2
	RELEASE 7, $0A
	REST 4
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	RELEASE 5, $0D
	NOTE B_, 4
	RELEASE 7, $0A
	NOTE G_, 1
	NOTE A_, 3
	NOTE A#, 1
	RELEASE 5, $0D
	NOTE B_, 4
	RELEASE 7, $0A
	NOTE G_, 3
	NOTE A_, 1
	NOTE A#, 3
	NOTE B_, 1
	RELEASE 7, $0B
	OCTAVE 4
	NOTE C_, 7
	OCTAVE 3
	NOTE E_, 5
	OCTAVE 4
	NOTE C_, 4
	VIBRATO 7
	RELEASE 4, $0A
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	VIBRATO 0
	RELEASE 7, $0A
	OCTAVE 3
	REST 4
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	RELEASE 5, $0D
	NOTE D_, 5
	RELEASE 7, $0A
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 3
	RELEASE 5, $0D
	NOTE D_, 4
	RELEASE 7, $0A
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE C#, 1
	RELEASE 7, $0C
	NOTE D_, 7
	NOTE E_, 5
	NOTE D_, 4
	LEN_UNIT $01
	PAN $0F
	WAVE 4
	RELEASE 4, $0C
	OCTAVE 5
	NOTE D_, 5
	NOTE D#, 6
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 6
	NOTE D#, 5
	LEN_UNIT $04
	RELEASE 7, $0A
	NOTE D_, 3
	PAN $FF
	WAVE 2
	RELEASE 3, $0A
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 3
	RELEASE 2, $0F
	NOTE F#, 1
	RELEASE 7, $0A
	NOTE F#, 7
	RELEASE 5, $0B
	NOTE G_, 5
	NOTE G_, 4
	RELEASE 4, $0A
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE A_, 6
	RELEASE $0F, 0
	NOTE G_, $0A
	WAVE 8
	LEN_UNIT $01
	RELEASE 5, $0C
	OCTAVE 1
	NOTE G_, 5
	NOTE F#, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 6
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 6
	NOTE B_, 5
	OCTAVE 2
	NOTE C_, 5
	NOTE C#, 6
	NOTE D_, 5
	LEN_UNIT $04
	SND_SEGNO
	RELEASE 3, $0E
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $01
	NOTE C_, $0B
	NOTE C_, 5
	PAN $F0
	NOTE C_, $0B
	PAN $FF
	NOTE C_, 5
	LEN_UNIT $04
	RELEASE 4, $0D
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	RELEASE 3, $0E
	OCTAVE 1
	NOTE B_, 4
	NOTE B_, 4
	LEN_UNIT $01
	NOTE B_, $0B
	NOTE B_, 5
	PAN $0F
	NOTE B_, $0B
	PAN $FF
	NOTE B_, 5
	LEN_UNIT $04
	RELEASE 4, $0D
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 3, $0E
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 4
	LEN_UNIT $01
	NOTE A_, $0B
	NOTE A_, 5
	PAN $F0
	NOTE A_, $0B
	PAN $FF
	NOTE A_, 5
	LEN_UNIT $04
	RELEASE 4, $0D
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 4
	PAN $0F
	OCTAVE 1
	NOTE D_, 4
	NOTE D_, 4
	PAN $FF
	OCTAVE 1
	NOTE G_, 4
	PAN $F0
	NOTE G_, 4
	PAN $FF
	NOTE A_, 4
	PAN $0F
	NOTE A_, 4
	PAN $FF
	LEN_UNIT $01
	RELEASE 3, $0D
	NOTE A#, $0B
	NOTE A#, 5
	NOTE A#, $0B
	NOTE A#, 5
	NOTE B_, 5
	NOTE B_, 6
	NOTE B_, 5
	NOTE B_, 5
	NOTE B_, 6
	NOTE B_, 5
	RELEASE 4, $0E
	OCTAVE 2
	NOTE C_, $0B
	NOTE C_, 5
	NOTE C_, $0B
	NOTE C_, 5
	NOTE C_, $0B
	NOTE C_, 5
	PAN $F0
	NOTE C_, $0B
	PAN $FF
	NOTE C_, 5
	OCTAVE 2
	NOTE D_, $0B
	NOTE D_, 5
	NOTE D_, $0B
	NOTE D_, 5
	NOTE D_, $0B
	NOTE D_, 5
	PAN $0F
	NOTE D_, $0B
	PAN $FF
	NOTE D_, 5
	OCTAVE 1
	NOTE B_, $0B
	NOTE B_, 5
	NOTE B_, $0B
	NOTE B_, 5
	NOTE B_, $0B
	NOTE B_, 5
	PAN $F0
	NOTE B_, $0B
	PAN $FF
	NOTE B_, 5
	NOTE E_, $0B
	NOTE E_, 5
	NOTE E_, $0B
	NOTE E_, 5
	NOTE F#, $0B
	NOTE F#, 5
	NOTE G_, $0B
	NOTE G_, 5
	LEN_UNIT $04
	RELEASE 7, 8
	NOTE A_, 7
	NOTE B_, 8
	OCTAVE 2
	NOTE C_, 8
	NOTE C#, 8
	RELEASE 5, $0E
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 3
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 1
	NOTE F_, 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 3
	OCTAVE 1
	NOTE F_, 1
	LEN_UNIT $01
	NOTE F#, $0B
	NOTE F#, 5
	OCTAVE 2
	NOTE F#, $0B
	OCTAVE 1
	NOTE F#, 5
	SND_CALL Snd4F_Ch3_43FE

Snd4F_Drm:
	DRUM_UNIT $04
	REST 5
Snd4F_Drm_45AF:
	DRUM_UNIT $04
	SND_SEGNO
	DRUM 8, 4
	DRUM 8, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 8, 4
	DRUM 8, 4
	REST 8
	DRUM 8, 4
	DRUM 8, 4
	REST 8
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 3
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 3
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 4
	LEN_UNIT $01
	DRUM $0B, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_SEGNO
	LEN_UNIT $04
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 3
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 4
	LEN_UNIT $01
	DRUM $0B, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_SEGNO
	DRUM 2, 5
	DRUM 2, 6
	DRUM 2, 5
	DRUM 8, $0B
	DRUM 2, 5
	SND_REPEAT $0E
	DRUM $0B, 5
	DRUM 2, 6
	DRUM $0B, 5
	DRUM 2, 5
	DRUM $0B, 6
	DRUM 2, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_SEGNO
	DRUM 2, 5
	DRUM 2, 6
	DRUM 2, 5
	DRUM 8, $0B
	DRUM 2, 5
	SND_REPEAT 3
	DRUM $0B, 5
	DRUM 2, 6
	DRUM $0B, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_SEGNO
	DRUM 2, 5
	DRUM 2, 6
	DRUM 2, 5
	DRUM 8, $0B
	DRUM 2, 5
	SND_REPEAT 3
	DRUM $0B, 5
	DRUM 2, 6
	DRUM $0B, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	LEN_UNIT $04
	DRUM 8, 4
	DRUM $0B, 3
	DRUM 8, 5
	DRUM $0B, 3
	DRUM 8, 5
	DRUM $0B, 3
	DRUM 8, 5
	DRUM $0B, 3
	DRUM 8, 1
	DRUM $0B, 4
	DRUM 8, 3
	DRUM 2, 1
	DRUM 8, 4
	DRUM 8, 3
	DRUM 2, 1
	DRUM 8, 4
	DRUM 8, 3
	DRUM 2, 1
	LEN_UNIT $01
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_CALL Snd4F_Drm_45AF

Snd50_Ch2:
	TEMPO $00
	TRANSPOSE_DOWN 1
	VIBRATO 10
	VOICE $05, 9, 8, 7, 10
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE B_, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, $0B
	REST 3
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE B_, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, $0B
	REST 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A#, $0B
	REST 3
Snd50_Ch2_4687:
	VIBRATO 0
	VOICE $05, 10, 0, 2, 14
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE E_, 2
	RELEASE 2, $0D
	NOTE G#, 4
	VIBRATO 7
	RELEASE 3, $0D
	NOTE G_, 6
	NOTE D#, 6
	VIBRATO 0
	RELEASE 2, $0C
	NOTE G_, 4
	VIBRATO 7
	RELEASE 3, $0D
	NOTE F#, 6
	NOTE D_, 6
	VIBRATO 0
	RELEASE 2, $0C
	NOTE F#, 4
	RELEASE 3, $0D
	NOTE E_, 6
	NOTE C#, $0A
	RELEASE 2, $0C
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE G#, 4
	VIBRATO 7
	RELEASE 3, $0D
	OCTAVE 4
	NOTE C#, 6
	OCTAVE 3
	NOTE G#, 6
	VIBRATO 0
	RELEASE 2, $0C
	OCTAVE 4
	NOTE C#, 4
	VIBRATO 7
	RELEASE 3, $0D
	NOTE D#, 6
	OCTAVE 3
	NOTE B_, 6
	VIBRATO 0
	RELEASE 2, $0C
	OCTAVE 4
	NOTE D#, 4
	RELEASE $0F, $0D
	NOTE E_, 8
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	VOICE $05, 9, 4, 2, 14
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 2
	RELEASE 2, $0F
	NOTE G#, 4
	NOTE G#, 4
	RELEASE 3, $0D
	NOTE B_, 4
	RELEASE 2, $0F
	NOTE F#, 4
	RELEASE 3, $0D
	NOTE B_, 4
	RELEASE 2, $0F
	NOTE F#, 2
	RELEASE 3, $0D
	NOTE B_, 4
	RELEASE 2, $0E
	NOTE B_, 4
	NOTE B_, 2
	NOTE F#, 4
	NOTE F#, 4
	DUTY_STEP_OFF
	VIBRATO 10
	VOICE $05, 9, 8, 3, 13
	DUTY_STEP 4, 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT 4
	DUTY_STEP 4, 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	SND_REPEAT 8
	OCTAVE 1
	NOTE G#, 2
	PAN $F0
	OCTAVE 2
	NOTE G#, 2
	PAN $FF
	OCTAVE 1
	NOTE G#, 2
	NOTE A_, 2
	PAN $0F
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	PAN $F0
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	OCTAVE 1
	NOTE A#, 2
	PAN $0F
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 2
	PAN $FF
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	PAN $F0
	OCTAVE 3
	NOTE C_, 2
	PAN $FF
	OCTAVE 2
	NOTE C_, 2
	PAN $0F
	OCTAVE 3
	NOTE C_, 2
	PAN $FF
	DUTY_STEP_OFF
	SND_CALL Snd50_Ch2_4687

Snd50_Ch1:
	TRANSPOSE_DOWN 1
	VIBRATO 4
	VOICE $05, 6, 4, 7, 10
	SND_SEGNO
	RELEASE 7, $0A
	OCTAVE 3
	NOTE E_, 8
	PAN $0F
	AUTOPAN 2
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 4
	SND_SEGNO
	RELEASE 7, $0A
	OCTAVE 4
	NOTE E_, 8
	PAN $F0
	AUTOPAN 2
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 4
Snd50_Ch1_47D1:
	TRANSPOSE_DOWN 1
	VIBRATO 4
	RELEASE 3, $0C
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 4
	NOTE D#, 6
	NOTE C#, 6
	NOTE D#, 4
	NOTE D_, 6
	OCTAVE 2
	NOTE A_, 6
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 6
	OCTAVE 2
	NOTE G#, $0A
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 4
	NOTE G#, 6
	NOTE D#, 6
	NOTE G#, 4
	NOTE F#, 6
	NOTE D#, 6
	NOTE F#, 4
	RELEASE 7, $0A
	NOTE G#, $0C
	REST 4
	RELEASE 3, $0C
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE D#, 4
	NOTE D#, 4
	NOTE F#, 4
	NOTE D#, 4
	NOTE F#, 4
	NOTE D#, 2
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 2
	NOTE D#, 4
	NOTE D#, 4
	ATTEN 1
	RELEASE 4, 9
	OCTAVE 4
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	OCTAVE 3
	NOTE A_, 6
	RELEASE 6, $0A
	NOTE A_, $0A
	RELEASE 4, 9
	NOTE B_, 6
	RELEASE 6, $0A
	NOTE B_, $0A
	RELEASE 4, 9
	OCTAVE 4
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	NOTE D#, 6
	RELEASE 6, $0A
	NOTE D#, $0A
	OCTAVE 3
	RELEASE 4, 9
	NOTE B_, 6
	RELEASE 6, $0A
	NOTE B_, $0A
	RELEASE 4, 9
	OCTAVE 4
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	NOTE C#, 6
	RELEASE 6, $0A
	NOTE C#, $0A
	RELEASE 4, 9
	OCTAVE 3
	NOTE A_, 6
	RELEASE 6, $0A
	NOTE A_, $0A
	RELEASE 4, 9
	NOTE B_, 6
	RELEASE 6, $0A
	NOTE B_, $0A
	RELEASE 5, $0A
	OCTAVE 4
	NOTE C#, 6
	NOTE C#, 6
	NOTE C#, 4
	RELEASE 7, $0A
	NOTE F#, 8
	NOTE F#, 8
	ATTEN 2
	RELEASE 2, $0C
	OCTAVE 4
	NOTE C#, 2
	RELEASE 3, $0A
	NOTE C_, 4
	RELEASE 2, $0C
	NOTE C_, 2
	RELEASE 3, $0A
	OCTAVE 3
	NOTE B_, 4
	RELEASE 2, $0C
	NOTE B_, 2
	RELEASE 3, $0A
	NOTE A#, 4
	NOTE A#, 2
	NOTE A_, 4
	RELEASE 3, $0C
	NOTE G#, 4
	NOTE G#, 4
	ATTEN 0
	SND_CALL Snd50_Ch1_47D1

Snd50_Ch3:
	TRANSPOSE_DOWN 1
	VOICE $05, 2, 8, 3, 12
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_REPEAT 7
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_REPEAT 7
	OCTAVE 2
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
Snd50_Ch3_48BD:
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_REPEAT 6
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 3
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	SND_SEGNO
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	SND_REPEAT 8
	VOICE $05, 2, 2, 6, 9
	OCTAVE 4
	NOTE G#, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE F_, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE C#, 6
	RELEASE 6, 7
	NOTE D#, $0A
	RELEASE 6, 9
	NOTE E_, 6
	RELEASE 6, 7
	NOTE G#, $0A
	RELEASE 6, 9
	NOTE G#, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE F_, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE F_, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE A_, 6
	RELEASE 6, 7
	NOTE G#, $0A
	RELEASE 6, 9
	OCTAVE 4
	NOTE G#, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE F_, 6
	RELEASE 6, 7
	NOTE F#, $0A
	RELEASE 6, 9
	NOTE C#, 6
	RELEASE 6, 7
	NOTE D#, $0A
	RELEASE 6, 9
	NOTE E_, 6
	RELEASE 6, 7
	NOTE G#, $0A
	RELEASE 6, 9
	NOTE G#, 6
	NOTE F#, 6
	NOTE G#, 4
	RELEASE 6, 7
	OCTAVE 5
	NOTE D#, 8
	NOTE C#, 8
	RELEASE 3, $0A
	OCTAVE 4
	NOTE C#, 2
	RELEASE 6, $0C
	NOTE C_, 4
	RELEASE 3, $0A
	NOTE C_, 2
	RELEASE 6, $0C
	OCTAVE 3
	NOTE B_, 4
	RELEASE 4, $0A
	NOTE B_, 2
	RELEASE 6, $0C
	NOTE A#, 4
	NOTE A#, 2
	NOTE A_, 4
	RELEASE 3, $0C
	NOTE G#, 4
	NOTE G#, 4
	SND_CALL Snd50_Ch3_48BD

Snd50_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
Snd50_Drm_49AD:
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 2, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 2, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $0E
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	SND_REPEAT 3
	DRUM 8, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd50_Drm_49AD

Snd51_Ch2:
	TEMPO $10
	VOICE $05, 8, 8, 4, 15
	DUTY_STEP 0, 2
	REST 2
	SND_CALL Snd51_Ch2_4A68
	SND_CALL Snd51_Ch2_4A96
	SND_CALL Snd51_Ch2_4A68
	SND_CALL Snd51_Ch2_4A99
	SND_CALL Snd51_Ch2_4A9D
	SND_CALL Snd51_Ch2
Snd51_Ch2_4A68:
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 6
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
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	SND_REPEAT 4
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE D_, 2
	SND_RET
Snd51_Ch2_4A96:
	NOTE G_, 2
	REST 2
	SND_RET
Snd51_Ch2_4A99:
	LEN_UNIT $01
	NOTE G_, $0A
	SND_RET
Snd51_Ch2_4A9D:
	DUTY 4
	RELEASE 2, $0F
	OCTAVE 4
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 3
	SND_SEGNO
	LEN_UNIT $05
	DUTY_STEP_OFF
	RELEASE 3, $0E
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	LEN_UNIT $01
	NOTE F#, $0A
	DUTY_STEP 0, 2
	RELEASE 3, $0F
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 3
	SND_REPEAT 2
	LEN_UNIT $01
	NOTE F#, $0A
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 3
	NOTE F#, $0A
	NOTE B_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 3
	LEN_UNIT $05
	DUTY_STEP_OFF
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE E_, 2
	LEN_UNIT $01
	NOTE E_, $0A
	DUTY_STEP 0, 2
	RELEASE 2, $0F
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	SND_SEGNO
	LEN_UNIT $05
	DUTY_STEP_OFF
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE E_, 2
	LEN_UNIT $01
	NOTE E_, $0A
	DUTY_STEP 0, 2
	RELEASE 3, $0F
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	SND_REPEAT 2
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 3
	DUTY_STEP_OFF
	SND_SEGNO
	RELEASE 3, $0E
	ATTEN 1
	OCTAVE 4
	NOTE D_, 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 3
	SND_REPEAT 4
	SND_SEGNO
	ATTEN 2
	NOTE D_, 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 3
	SND_REPEAT $0B
	ATTEN 0
	SND_RET

Snd51_Ch1:
	VOICE $05, 6, 4, 3, 14
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 4, $0C
	NOTE F#, 5
	RELEASE 3, $0E
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 1
	NOTE G_, 1
	RELEASE 4, $0C
	NOTE F#, 5
	RELEASE 3, $0E
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D_, 2
	NOTE G_, 2
	LEN_UNIT $01
	NOTE D_, $0A
	VIBRATO 4
	DUTY 0
	OCTAVE 4
	NOTE F#, 3
	NOTE F#, 4
	NOTE F#, 3
	SND_SEGNO
	LEN_UNIT $05
	RELEASE 3, $0E
	NOTE F#, 2
	NOTE F#, 2
	LEN_UNIT $01
	RELEASE 1, $0E
	NOTE F#, $0A
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 3
	SND_REPEAT 2
	LEN_UNIT $01
	NOTE F#, $0A
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 3
	NOTE F#, $0A
	NOTE B_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 3
	LEN_UNIT $05
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE E_, 2
	LEN_UNIT $01
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	SND_SEGNO
	LEN_UNIT $05
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE E_, 2
	LEN_UNIT $01
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	SND_REPEAT 2
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 4
	NOTE F#, 3
	LEN_UNIT $01
	NOTE E_, $0A
	NOTE A_, 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 3
	VOICE $05, 5, 8, 3, 14
	DUTY_STEP 0, 2
	REST 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	NOTE B_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 1
	REST 1
	NOTE A_, 1
	NOTE A_, 1
	TRANSPOSE_UP 0
	SND_CALL Snd51_Ch1

Snd51_Ch3:
	VIBRATO 10
	VOICE $05, 2, 2, 3, 10
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 7, $0A
	OCTAVE 4
	NOTE D_, 5
	RELEASE 3, $0A
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 7, $0A
	OCTAVE 5
	NOTE D_, 5
	RELEASE 3, $0A
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	REST 2
	SND_SEGNO
	WAVE 8
	LEN_UNIT $05
	RELEASE 4, $0A
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	SND_REPEAT 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	SND_SEGNO
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	SND_REPEAT 3
	RELEASE $0D, $0F
	OCTAVE 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	NOTE A_, 3
	NOTE A_, 3
	SND_CALL Snd51_Ch3

Snd51_Drm:
	DRUM_UNIT $05
	DRUM 2, 1
	DRUM 2, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 3
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	REST 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 3
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	REST 2
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 3
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_CALL Snd51_Drm

Snd52_Ch2:
	TEMPO $00
	VOICE $01, 9, 8, 3, 13
	SND_SEGNO
	PAN $F0
	OCTAVE 4
	NOTE D_, 4
	NOTE D#, 4
	PAN $FF
	NOTE D_, 4
	NOTE D#, 4
	PAN $0F
	NOTE D_, 4
	NOTE D#, 4
	SND_REPEAT 4
	SND_SEGNO
	PAN $F0
	OCTAVE 3
	NOTE D_, 4
	NOTE D#, 4
	PAN $FF
	NOTE D_, 4
	NOTE D#, 4
	PAN $0F
	NOTE D_, 4
	NOTE D#, 4
	SND_REPEAT 4
	PAN $FF
	VIBRATO 10
	VOICE $06, 9, 0, 2, 13
	SND_SEGNO
	RELEASE 2, $0D
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 6, $0A
	OCTAVE 4
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	RELEASE 2, $0D
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 6, $0A
	OCTAVE 4
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 2
	ATTEN 0
	RELEASE 2, $0D
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	RELEASE 6, $0A
	OCTAVE 4
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 3
	ATTEN 0
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	RELEASE 4, $0A
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	RELEASE 6, $0A
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 2
	ATTEN 0
	RELEASE 4, $0A
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 1
	ATTEN 0
	RELEASE 2, $0D
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 6, $0A
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	RELEASE 2, $0D
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 6, $0A
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 2
	ATTEN 0
	RELEASE 2, $0D
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 6, $0A
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 3
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 2
	ATTEN 0
	RELEASE 4, $0A
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	RELEASE 6, $0A
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 2
	ATTEN 0
	RELEASE 4, $0A
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	SND_REPEAT 2
	TRANSPOSE_UP 0
	VOICE $06, 9, 8, 1, 12
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE $0A, 9
	NOTE E_, 2
	RELEASE 1, $0F
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	RELEASE $0A, 9
	NOTE D#, 2
	RELEASE 1, $0E
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	SND_REPEAT 2
	SND_CALL Snd52_Ch2

Snd52_Ch1:
	VIBRATO 4
	VOICE $01, 6, 4, 3, 13
	SND_CALL Snd52_Ch1_4DF2
	SND_CALL Snd52_Ch1_4DFF
	SND_CALL Snd52_Ch1_4E12
	SND_CALL Snd52_Ch1_4E4D
	SND_CALL Snd52_Ch1_4E12
	SND_CALL Snd52_Ch1_4E4D
	SND_CALL Snd52_Ch1_4E86
	SND_CALL Snd52_Ch1
Snd52_Ch1_4DF2:
	ATTEN 3
	REST 3
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	SND_REPEAT 4
	SND_RET
Snd52_Ch1_4DFF:
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	SND_REPEAT 3
	OCTAVE 3
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 1
	ATTEN 0
	SND_RET
Snd52_Ch1_4E12:
	VOICE $06, 6, 0, 3, 14
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	RELEASE $0E, 6
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	RELEASE $0E, 6
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	RELEASE $0E, 6
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE G_, 2
	RELEASE $0E, 6
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE G_, 2
	SND_RET
Snd52_Ch1_4E4D:
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	RELEASE $0E, 6
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	RELEASE 3, $0E
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	RELEASE $0E, 6
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	RELEASE 3, $0E
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	RELEASE $0E, 6
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 3
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	RELEASE 4, $0F
	NOTE C_, 2
	RELEASE $0E, 6
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE C_, 2
	SND_RET
Snd52_Ch1_4E86:
	VOICE $06, 6, 4, 13, 8
	DUTY_STEP_OFF
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE G_, 2
	RELEASE $0D, 8
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	RELEASE 3, $0E
	NOTE F#, 2
	RELEASE $0D, 8
	SND_REPEAT 2
	SND_RET

Snd52_Ch3:
	VOICE $06, 2, 6, 7, 11
	SND_CALL Snd52_Ch3_4EC7
	SND_CALL Snd52_Ch3_4ECF
	SND_CALL Snd52_Ch3_4EE2
	SND_CALL Snd52_Ch3_4F2B
	SND_CALL Snd52_Ch3_4EE2
	SND_CALL Snd52_Ch3_4F2B
	SND_CALL Snd52_Ch3_4F68
	SND_CALL Snd52_Ch3
Snd52_Ch3_4EC7:
	OCTAVE 2
	NOTE D_, 3
	NOTE D#, 3
	NOTE C#, 2
	NOTE D_, 3
	NOTE D#, 3
	NOTE C#, 2
	SND_RET
Snd52_Ch3_4ECF:
	RELEASE 6, 8
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 3
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 3
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	SND_RET
Snd52_Ch3_4EE2:
	SND_SEGNO
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_REPEAT 5
	NOTE G_, 1
	PAN $F0
	RELEASE $0D, $0A
	OCTAVE 2
	NOTE C_, 1
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	PAN $0F
	RELEASE $0D, $0A
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	PAN $F0
	RELEASE $0D, $0A
	OCTAVE 2
	NOTE D#, 1
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	PAN $0F
	RELEASE $0D, $0A
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	PAN $F0
	RELEASE $0D, $0A
	OCTAVE 2
	NOTE C_, 1
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 1
	NOTE A#, 1
	SND_RET
Snd52_Ch3_4F2B:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	SND_REPEAT 5
	NOTE C_, 1
	PAN $F0
	RELEASE $0D, $0A
	NOTE F_, 1
	PAN $FF
	RELEASE 4, $0F
	NOTE C_, 1
	PAN $0F
	RELEASE $0D, $0A
	NOTE G_, 1
	PAN $FF
	RELEASE 4, $0F
	NOTE C_, 1
	PAN $F0
	RELEASE $0D, $0A
	NOTE G#, 1
	PAN $FF
	RELEASE 4, $0F
	NOTE C_, 1
	PAN $0F
	RELEASE $0D, $0A
	NOTE G_, 1
	PAN $FF
	RELEASE 4, $0F
	NOTE C_, 1
	PAN $F0
	RELEASE $0D, $0A
	NOTE F_, 1
	PAN $FF
	RELEASE 4, $0F
	NOTE C_, 1
	NOTE D#, 1
	SND_RET
Snd52_Ch3_4F68:
	VOICE $06, 2, 2, 3, 13
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_RET

Snd52_Drm:
	DRUM_UNIT $06
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 1
	DRUM 2, 2
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 2, 2
	DRUM 8, 1
	DRUM 2, 2
	DRUM 2, 1
	DRUM 8, 2
	SND_REPEAT 5
	SND_CALL Snd52_Drm

Snd53_Ch2:
	TEMPO $00
	VOICE $05, 9, 8, 3, 14
	DUTY_STEP 0, 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	NOTE A#, 2
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_REPEAT 2
	RELEASE 6, $0E
	OCTAVE 2
	NOTE F_, 2
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_SEGNO
	RELEASE 3, $0E
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	NOTE A#, 2
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE D#, 2
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	SND_REPEAT 2
	RELEASE 6, $0E
	OCTAVE 2
	NOTE D_, 2
	RELEASE 2, $0F
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	NOTE A#, 2
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	NOTE A#, 2
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE D#, 2
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE C#, 2
	RELEASE 2, $0F
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE G#, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	NOTE G_, 2
	RELEASE 2, $0F
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	SND_REPEAT 4
	RELEASE 4, $0E
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	RELEASE 2, $0F
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	RELEASE 6, $0E
	NOTE G_, 8
	SND_CALL Snd53_Ch2

Snd53_Ch1:
	VIBRATO 4
	VOICE $05, 6, 4, 5, 15
	OCTAVE 4
	NOTE E_, 6
	NOTE E_, 6
	NOTE E_, 4
	NOTE D_, 6
	NOTE D_, 6
	NOTE D_, 4
	NOTE E_, 6
	NOTE E_, 6
	NOTE C_, 1
	NOTE E_, 3
	RELEASE 0, 0
	ATTEN 1
	NOTE C_, 4
	ATTEN 0
	RELEASE 5, $0A
	NOTE C_, 8
	REST 4
	RELEASE 5, $0F
	NOTE E_, 6
	NOTE E_, 6
	NOTE E_, 4
	NOTE D_, 6
	NOTE D_, 6
	NOTE D_, 2
	RELEASE 6, $0E
	OCTAVE 3
	NOTE A#, 6
	RELEASE 4, $0F
	OCTAVE 4
	NOTE D#, 2
	RELEASE 6, $0E
	OCTAVE 3
	NOTE A#, 7
	RELEASE 2, $0E
	NOTE G_, 1
	NOTE A#, 1
	RELEASE 5, 6
	NOTE B_, $0B
	PAN $F0
	AUTOPAN 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	AUTOPAN 0
	PAN $FF
	RELEASE 5, $0F
	OCTAVE 4
	NOTE E_, 6
	NOTE E_, 6
	NOTE E_, 4
	NOTE D_, 6
	NOTE D_, 6
	NOTE D_, 4
	NOTE E_, 6
	NOTE E_, 6
	NOTE E_, 4
	RELEASE 7, 6
	NOTE F_, $0C
	REST 4
	RELEASE 5, $0F
	NOTE G_, 6
	NOTE G_, 6
	NOTE G_, 4
	NOTE G#, 6
	NOTE G#, 6
	NOTE G#, 4
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 5
	NOTE C_, 6
	OCTAVE 4
	NOTE B_, 6
	PAN $F0
	AUTOPAN 2
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 2
	LEN_UNIT $01
	VIBRATO 7
	RELEASE 3, 8
	OCTAVE 4
	NOTE F_, $0D
	NOTE E_, $0E
	NOTE D#, $0D
	NOTE D_, $0D
	NOTE C#, $0E
	NOTE C_, $0D
	LEN_UNIT $05
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 2
	NOTE A_, 1
	RELEASE 7, $0C
	NOTE G#, 8
	SND_CALL Snd53_Ch1

Snd53_Ch3:
	VOICE $05, 2, 2, 6, 10
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 6
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 6
	NOTE G_, 6
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 6
	RELEASE 3, 9
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	RELEASE 7, 6
	NOTE F_, $0A
	RELEASE 6, $0A
	NOTE E_, 4
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 6
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 6
	NOTE G_, 6
	NOTE F_, 2
	RELEASE 7, 6
	NOTE G_, $0F
	RELEASE 3, 9
	NOTE D#, 1
	NOTE F_, 1
	RELEASE 7, 6
	NOTE G_, $0B
	RELEASE 6, $0A
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 6
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 6
	NOTE G_, 6
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 6
	RELEASE 3, 8
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	RELEASE 7, 7
	NOTE D_, $0D
	RELEASE 7, 5
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	RELEASE 6, $0A
	NOTE D#, 6
	OCTAVE 3
	NOTE A#, 6
	RELEASE 3, 8
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	RELEASE 6, $0A
	NOTE F_, 6
	NOTE C#, 6
	RELEASE 3, 8
	NOTE C#, 1
	NOTE E_, 1
	NOTE F_, 2
	SND_SEGNO
	RELEASE 7, 6
	NOTE G_, $0C
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_REPEAT 2
	LEN_UNIT $01
	VIBRATO 7
	RELEASE 3, 6
	OCTAVE 4
	NOTE A#, $0D
	NOTE A_, $0E
	NOTE G#, $0D
	NOTE G_, $0D
	NOTE F#, $0E
	NOTE F_, $0D
	RELEASE 6, $0E
	LEN_UNIT $05
	NOTE E_, 1
	NOTE D#, 2
	NOTE D_, 1
	RELEASE 6, $0A
	NOTE C#, 8
	VIBRATO 13
	SND_CALL Snd53_Ch3

Snd53_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	LEN_UNIT $01
	DRUM 8, $0D
	DRUM 8, $0E
	DRUM 8, $0D
	DRUM 8, $0D
	DRUM 8, $0E
	DRUM 8, $0D
	LEN_UNIT $05
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_CALL Snd53_Drm

Snd54_Ch2:
	VIBRATO 10
	VOICE $06, 10, 8, 5, 14
	ATTEN 6
	OCTAVE 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
Snd54_Ch2_5231:
	VIBRATO 1
	SND_SEGNO
	DUTY_STEP 0, 2
	PAN $F0
	AUTOPAN 2
	RELEASE 1, $0D
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	AUTOPAN 0
	PAN $FF
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	SND_REPEAT 4
	SND_SEGNO
	PAN $F0
	RELEASE 2, $0E
	OCTAVE 2
	NOTE D_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	PAN $0F
	OCTAVE 2
	NOTE D_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	SND_REPEAT 4
	SND_CALL Snd54_Ch2_5231

Snd54_Ch1:
	VIBRATO 3
	VOICE $06, 10, 4, 3, 12
	OCTAVE 3
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
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
Snd54_Ch1_5279:
	VIBRATO 4
	VOICE $06, 7, 4, 2, 15
	SND_SEGNO
	ATTEN 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	SND_REPEAT 7
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 8
	SND_CALL Snd54_Ch1_5279

Snd54_Ch3:
	TEMPO $00
	VOICE $06, 2, 8, 5, 14
	OCTAVE 2
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
Snd54_Ch3_52B6:
	WAVE 2
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_REPEAT 4
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 4
	SND_CALL Snd54_Ch3_52B6

Snd54_Drm:
	SND_END
	db $FF ; unreachable byte after an end

Snd56_Ch2:
	TEMPO $10
	VIBRATO 10
	VOICE $06, 9, 0, 10, 15
	DUTY_STEP 4, 2
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
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
	NOTE F#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE G_, 1
	SND_REPEAT 3
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
Snd56_Ch2_532A:
	DUTY 8
	DUTY_STEP 0, 2
	SND_SEGNO
	RELEASE 2, $0D
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	SND_REPEAT 8
	DUTY_STEP 4, 2
	DUTY 0
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_REPEAT 4
	SND_SEGNO
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_REPEAT 4
	SND_CALL Snd56_Ch2_532A

Snd56_Ch1:
	VIBRATO 3
	VOICE $06, 6, 4, 1, 13
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	SND_REPEAT 3
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	RELEASE 3, $0D
	OCTAVE 3
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
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
Snd56_Ch1_539B:
	SND_SEGNO
	RELEASE 2, $0E
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_REPEAT 8
	SND_SEGNO
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_REPEAT 4
	PAN $FF
	SND_CALL Snd56_Ch1_539B

Snd56_Ch3:
	VOICE $06, 2, 6, 3, 12
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	SND_REPEAT 5
	OCTAVE 1
	NOTE A_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	PAN $F0
	NOTE A_, 1
	PAN $FF
	SND_REPEAT 5
	OCTAVE 1
	NOTE A_, 1
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	SND_REPEAT 5
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $F0
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $0F
	NOTE G_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $0F
	NOTE G_, 1
	PAN $FF
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
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
Snd56_Ch3_541F:
	SND_SEGNO
	WAVE $0F
	RELEASE 4, $0D
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	SND_REPEAT 5
	OCTAVE 2
	NOTE D_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	SND_REPEAT 5
	OCTAVE 2
	NOTE D_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	SND_REPEAT 2
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $0F
	NOTE A_, 1
	PAN $FF
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	PAN $F0
	NOTE A_, 1
	PAN $FF
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	PAN $0F
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	PAN $FF
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	SND_REPEAT 2
	SND_CALL Snd56_Ch3_541F

Snd56_Drm:
	DRUM_UNIT $06
	SND_SEGNO
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	SND_REPEAT 7
	SND_SEGNO
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT 3
Snd56_Drm_5497:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd56_Drm_5497

Snd55_Ch2:
	TEMPO $10
	VIBRATO 7
	VOICE $05, 9, 4, 2, 15
	SND_CALL Snd55_Ch2_5504
	SND_CALL Snd55_Ch2_55A2
	SND_CALL Snd55_Ch2_55A2
	SND_CALL Snd55_Ch2

Snd55_Ch1:
	VIBRATO 4
	VOICE $05, 6, 8, 2, 14
	SND_CALL Snd55_Ch1_55DD
	SND_CALL Snd55_Ch1_565F
	SND_CALL Snd55_Ch1_565F
	SND_CALL Snd55_Ch1

Snd55_Ch3:
	VOICE $05, 2, 6, 3, 12
	SND_CALL Snd55_Ch3_5698
	SND_CALL Snd55_Ch3_5771
	SND_CALL Snd55_Ch3_579C
	SND_CALL Snd55_Ch3_5771
	SND_CALL Snd55_Ch3_57AA
	SND_CALL Snd55_Ch3

Snd55_Drm:
	DRUM_UNIT $05
	SND_CALL Snd55_Drm_57B7
	SND_CALL Snd55_Drm
Snd55_Ch2_5504:
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	VIBRATO 13
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 2
	NOTE A_, 2
	VIBRATO 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	VIBRATO 9
	DUTY_STEP 0, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	VIBRATO 13
	DUTY 8
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 8
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_REPEAT 4
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE C_, 6
	NOTE C_, 2
	NOTE C_, 6
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	OCTAVE 2
	NOTE C_, 4
	DUTY 0
	RELEASE 3, $0F
	OCTAVE 3
	NOTE G_, 3
	NOTE G_, 1
	VIBRATO 7
	VOICE $05, 9, 0, 2, 8
	OCTAVE 4
	NOTE G_, 4
	NOTE E_, 8
	RELEASE 4, $0F
	NOTE D_, 3
	NOTE E_, 1
	RELEASE 2, 8
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 8
	NOTE C_, 6
	NOTE D_, 2
	NOTE E_, $0C
	RELEASE 4, $0F
	NOTE E_, 3
	NOTE F_, 1
	RELEASE 2, 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 6
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, $0C
	RELEASE 4, $0F
	NOTE G_, 3
	NOTE A_, 1
	RELEASE 2, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 6
	NOTE E_, 2
	NOTE C_, 8
	RELEASE 2, $0F
	OCTAVE 5
	NOTE C_, 6
	DUTY 8
	OCTAVE 1
	NOTE G_, 2
	SND_RET
Snd55_Ch2_55A2:
	DUTY_STEP 4, 2
	SND_SEGNO
	RELEASE 2, $0E
	OCTAVE 1
	NOTE F_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT 4
	SND_SEGNO
	NOTE C_, 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 2
	SND_SEGNO
	NOTE C_, 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 4
	SND_RET
Snd55_Ch1_55DD:
	ATTEN 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	DUTY 4
	ATTEN 2
	RELEASE $0F, 4
	OCTAVE 4
	NOTE E_, 8
	NOTE C_, 8
	NOTE D_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE D_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 4
	NOTE E_, 8
	NOTE C_, 8
	NOTE D_, 8
	ATTEN 0
	RELEASE 4, $0E
	OCTAVE 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE 2, $0E
	OCTAVE 4
	NOTE C_, 6
	NOTE C_, 2
	NOTE C_, 6
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	REST 4
	RELEASE 2, 8
	OCTAVE 4
	NOTE G_, 4
	NOTE E_, 8
	NOTE D_, 3
	NOTE E_, 1
	RELEASE 2, 8
	NOTE D_, 4
	NOTE C_, 6
	OCTAVE 3
	NOTE G_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE E_, 6
	NOTE G_, 2
	RELEASE 2, 6
	NOTE G_, $0C
	RELEASE 3, $0D
	NOTE E_, 3
	NOTE F_, 1
	RELEASE 2, 8
	NOTE E_, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 6
	NOTE E_, 2
	SND_SEGNO
	RELEASE 2, $0F
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	SND_REPEAT 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 4
	SND_RET
Snd55_Ch1_565F:
	SND_SEGNO
	RELEASE 2, $0F
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	SND_REPEAT 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	SND_RET
Snd55_Ch3_5698:
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 2
	WAVE 8
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 2
	NOTE A_, 2
	WAVE 6
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	VOICE $05, 2, 2, 5, 11
	OCTAVE 3
	NOTE G_, 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 5, $0B
	NOTE D_, 3
	RELEASE 3, $0C
	NOTE C_, 1
	RELEASE 5, $0B
	NOTE D_, 3
	RELEASE 3, $0C
	NOTE E_, 1
	RELEASE 7, $0A
	NOTE D_, 8
	RELEASE 5, $0C
	OCTAVE 3
	NOTE G_, 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 5, $0B
	NOTE C_, 3
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 1
	RELEASE 7, $0A
	NOTE E_, 8
	RELEASE 5, $0B
	OCTAVE 3
	NOTE G_, 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 5, $0B
	NOTE D_, 3
	RELEASE 3, $0C
	NOTE E_, 1
	NOTE G_, 2
	NOTE C_, 2
	RELEASE 7, $0A
	NOTE G_, 8
	RELEASE 5, $0C
	NOTE G_, 3
	RELEASE 3, $0C
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	RELEASE 5, $0C
	NOTE G_, 3
	RELEASE 3, $0C
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 2
	SND_SEGNO
	VIBRATO 7
	NOTE D_, 2
	VIBRATO 0
	NOTE G_, 2
	SND_REPEAT 2
	NOTE C_, 4
	REST 4
	VOICE $05, 2, 8, 4, 13
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 4
	SND_SEGNO
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	SND_REPEAT 6
	NOTE C_, 4
	REST 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_SEGNO
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	SND_REPEAT 4
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	WAVE $0D
	OCTAVE 1
	NOTE C_, 1
	NOTE F_, 1
	SND_RET
Snd55_Ch3_5771:
	SND_SEGNO
	RELEASE 3, $0C
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE C_, 1
	NOTE F_, 1
	SND_REPEAT 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	RELEASE 4, $0A
	NOTE C_, 4
	RELEASE 3, $0C
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	SND_RET
Snd55_Ch3_579C:
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	REST 2
	SND_RET
Snd55_Ch3_57AA:
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	REST 2
	SND_RET
Snd55_Drm_57B7:
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 8, 4
	DRUM 8, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 6
	DRUM 8, 2
	DRUM 8, 6
	DRUM 8, 2
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 8
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 8
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $0F
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $0F
	DRUM 8, 4
	SND_RET

Snd57_Ch2:
	TEMPO $00
	VOICE $06, 9, 8, 3, 12
	DUTY_STEP 0, 3
	OCTAVE 1
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE E_, 4
	OCTAVE 1
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 4
	DUTY 0
	DUTY_STEP 8, 2
	RELEASE $0D, $0A
	OCTAVE 4
	NOTE C_, 4
	RELEASE 5, $0D
	NOTE C_, 4
	RELEASE $0D, $0A
	OCTAVE 3
	NOTE B_, 4
	RELEASE 3, $0D
	NOTE B_, 4
	VOICE $06, 9, 0, 3, 14
	LEN_UNIT $02
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE F_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE G#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE A#, 5
	REST 3
	DUTY 4
	RELEASE 2, $0E
	ATTEN 5
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 4
	DUTY 0
	RELEASE 3, $0E
	ATTEN 0
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE A#, 4
	DUTY 4
	RELEASE 2, $0E
	ATTEN 5
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	DUTY 0
	RELEASE 3, $0E
	ATTEN 0
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE A#, 5
	REST 3
	DUTY 4
	RELEASE 2, $0E
	ATTEN 5
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 4
	DUTY 0
	RELEASE 3, $0E
	ATTEN 3
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE E_, 4
	ATTEN 2
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE E_, 4
	ATTEN 1
	RELEASE $0A, $0B
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE E_, 4
	ATTEN 0
	RELEASE $0A, $0F
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE E_, 4
	SND_CALL Snd57_Ch2

Snd57_Ch1:
	VIBRATO 10
	VOICE $06, 6, 4, 3, 14
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	RELEASE 4, $0D
	OCTAVE 3
	NOTE C_, 6
	NOTE F_, 2
	RELEASE 3, $0E
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 4, $0D
	NOTE C_, 6
	NOTE E_, 2
	RELEASE 3, $0E
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	RELEASE 4, $0D
	OCTAVE 3
	NOTE C_, 6
	NOTE F_, 2
	RELEASE 3, $0E
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 4, $0D
	NOTE C_, 6
	NOTE E_, 2
	RELEASE 3, $0E
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN_UNIT $02
	DUTY_STEP 8, 2
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	VOICE $02, 6, 12, 2, 12
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE F_, 4
	OCTAVE 2
	NOTE B_, 4
	SND_SEGNO
	OCTAVE 3
	NOTE E_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE F_, 4
	REST $0C
	REST $0C
	SND_REPEAT 3
	SND_SEGNO
	ATTEN 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE B_, 4
	SND_REPEAT 2
	ATTEN 0
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 4
	PAN $0F
	OCTAVE 3
	NOTE A#, 4
	PAN $FF
	NOTE B_, 4
	SND_REPEAT 2
	SND_CALL Snd57_Ch1

Snd57_Ch3:
	VOICE $06, 2, 2, 6, 11
	OCTAVE 3
	NOTE A_, 4
	NOTE E_, 4
	RELEASE 6, $0A
	NOTE A_, 6
	RELEASE 5, $0B
	NOTE B_, 2
	RELEASE 7, $0E
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 1
	RELEASE 6, $0A
	OCTAVE 4
	NOTE E_, 6
	RELEASE 5, $0B
	NOTE C_, 2
	RELEASE 6, $0B
	NOTE D_, 4
	NOTE E_, 4
	RELEASE 5, $0B
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 6, $0B
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 4
	RELEASE 5, $0B
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE E_, 4
	RELEASE 6, $0A
	NOTE A_, 6
	RELEASE 5, $0B
	NOTE B_, 2
	RELEASE 7, $0E
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 1
	RELEASE 6, $0A
	OCTAVE 4
	NOTE E_, 6
	RELEASE 5, $0B
	NOTE C_, 2
	RELEASE 6, $0B
	NOTE D_, 4
	NOTE E_, 4
	RELEASE 5, $0B
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	LEN_UNIT $02
	WAVE 6
	PAN $F0
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE D_, 4
	PAN $FF
	NOTE G_, 4
	NOTE D_, 4
	PAN $0F
	NOTE G_, 4
	OCTAVE 3
	NOTE D_, 4
	PAN $F0
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	PAN $FF
	OCTAVE 3
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 4
	PAN $0F
	OCTAVE 3
	NOTE E_, 4
	NOTE B_, 4
	PAN $FF
	VIBRATO 7
	RELEASE 3, $0C
	OCTAVE 2
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE F_, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE G#, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE E_, 4
	VIBRATO 13
	RELEASE 5, $0A
	OCTAVE 1
	NOTE A_, 4
	PAN $F0
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 4
	PAN $FF
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 4
	PAN $0F
	OCTAVE 2
	NOTE A#, 4
	PAN $FF
	NOTE A#, 4
	WAVE 7
	OCTAVE 3
	REST 4
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 4
	WAVE 6
	RELEASE 5, $0A
	OCTAVE 1
	NOTE A_, 4
	PAN $F0
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 4
	PAN $FF
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 4
	PAN $0F
	OCTAVE 2
	NOTE A#, 4
	PAN $FF
	NOTE A#, 4
	WAVE 7
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE F_, 4
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	WAVE 6
	RELEASE 5, $0A
	OCTAVE 1
	NOTE A_, 4
	PAN $F0
	RELEASE 3, $0C
	OCTAVE 2
	NOTE A_, 4
	PAN $FF
	NOTE A_, 4
	OCTAVE 1
	NOTE A_, 4
	PAN $0F
	OCTAVE 2
	NOTE A#, 4
	PAN $FF
	NOTE A#, 4
	REST 4
	WAVE 7
	OCTAVE 3
	NOTE E_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 4
	WAVE 6
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 4
	OCTAVE 2
	NOTE D#, 4
	NOTE E_, 4
	SND_REPEAT 2
	SND_SEGNO
	VIBRATO 7
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE E_, 4
	SND_REPEAT 2
	VIBRATO 0
	SND_CALL Snd57_Ch3

Snd57_Drm:
	DRUM_UNIT $06
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	LEN_UNIT $02
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM_UNIT $06
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	LEN_UNIT $02
	SND_SEGNO
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	SND_REPEAT 4
	DRUM_UNIT $06
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	LEN_UNIT $02
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	SND_SEGNO
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 8, 4
	DRUM 2, 4
	DRUM 2, 4
	SND_REPEAT 3
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_CALL Snd57_Drm

Snd58_Ch2:
	TEMPO $00
	VIBRATO 1
	DUTY_STEP 4, 2
	VOICE $05, 9, 8, 2, 14
	SND_CALL Snd58_Ch2_5B34
	SND_CALL Snd58_Ch2_5B34
	SND_CALL Snd58_Ch2_5B8C
	SND_CALL Snd58_Ch2

Snd58_Ch1:
	VOICE $05, 6, 0, 2, 13
	SND_CALL Snd58_Ch1_5C16
	SND_CALL Snd58_Ch1_5C16
	SND_CALL Snd58_Ch1_5C4F
	SND_CALL Snd58_Ch1

Snd58_Ch3:
	VOICE $05, 2, 8, 3, 12
	SND_CALL Snd58_Ch3_5CEA
	SND_CALL Snd58_Ch3_5CEA
	SND_CALL Snd58_Ch3_5D15
	SND_CALL Snd58_Ch3
Snd58_Ch2_5B34:
	REST 2
	RELEASE 2, $0E
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_REPEAT 2
	RELEASE $0D, $0D
	NOTE F#, 2
	RELEASE 1, $0C
	NOTE F_, 2
	RELEASE $0D, $0D
	NOTE F_, 2
	RELEASE 1, $0C
	NOTE E_, 2
	RELEASE $0D, $0D
	NOTE E_, 2
	RELEASE 1, $0C
	NOTE D#, 2
	RELEASE $0D, $0D
	NOTE D#, 2
	RELEASE 1, $0C
	NOTE D_, 2
	DUTY_STEP_OFF
	RELEASE $0D, $0D
	NOTE D_, 4
	PAN $0F
	RELEASE 5, $0A
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	RELEASE $0D, $0D
	NOTE D_, 4
	PAN $FF
	DUTY 0
	RELEASE 5, $0A
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	RELEASE $0D, $0D
	NOTE D_, 4
	PAN $F0
	DUTY 8
	ATTEN 3
	RELEASE 5, $0A
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	RELEASE 5, $0F
	NOTE D_, 8
	PAN $FF
	ATTEN 0
	SND_RET
Snd58_Ch2_5B8C:
	DUTY 0
	DUTY_STEP 8, 2
	RELEASE 2, $0D
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	DUTY_STEP_OFF
	RELEASE $0F, $0D
	NOTE E_, 4
	RELEASE 1, $0D
	NOTE F#, 2
	NOTE D_, 2
	RELEASE $0F, $0D
	NOTE E_, 4
	RELEASE 1, $0D
	NOTE F#, 2
	NOTE D_, 2
	RELEASE 5, $0F
	NOTE E_, 8
	DUTY_STEP 8, 2
	RELEASE 2, $0D
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	DUTY_STEP_OFF
	RELEASE $0F, $0D
	NOTE F#, 4
	RELEASE 1, $0D
	NOTE G#, 2
	NOTE E_, 2
	RELEASE $0F, $0D
	NOTE F#, 4
	RELEASE 1, $0D
	NOTE G#, 2
	NOTE E_, 2
	RELEASE 5, $0F
	NOTE F#, 8
	VOICE $05, 9, 8, 1, 14
	REST 2
	SND_SEGNO
	DUTY_STEP 0, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 2
	RELEASE 5, $0A
	NOTE E_, 2
	RELEASE 1, $0E
	PAN $0F
	SND_REPEAT 2
	PAN $FF
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	RELEASE 4, $0E
	NOTE A_, 4
	SND_SEGNO
	RELEASE 5, $0C
	OCTAVE 1
	NOTE G_, 2
	RELEASE 1, $0D
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 4
	SND_SEGNO
	RELEASE 5, $0C
	OCTAVE 1
	NOTE G_, 2
	RELEASE 1, $0D
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 4
	SND_SEGNO
	RELEASE 5, $0C
	NOTE D_, 2
	RELEASE 1, $0D
	NOTE A_, 2
	SND_REPEAT 6
	DUTY_STEP_OFF
	RELEASE 3, $0C
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_RET
Snd58_Ch1_5C16:
	VIBRATO 4
	VOICE $05, 6, 0, 2, 13
	ATTEN 2
	REST 2
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_SEGNO
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_REPEAT 2
	RELEASE 5, $0A
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	RELEASE $0D, $0C
	NOTE D_, 4
	ATTEN 5
	RELEASE 2, $0D
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	RELEASE 5, $0A
	NOTE D_, $0C
	ATTEN 5
	RELEASE 2, $0D
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	RELEASE 5, $0A
	NOTE D_, 8
	SND_RET
Snd58_Ch1_5C4F:
	DUTY 4
	VIBRATO 3
	ATTEN 0
	RELEASE 3, $0D
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	RELEASE 4, $0B
	OCTAVE 4
	NOTE C#, 4
	RELEASE 2, $0D
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 4, $0B
	OCTAVE 4
	NOTE C#, 4
	RELEASE 2, $0D
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 4, $0A
	OCTAVE 4
	NOTE C#, 8
	RELEASE 3, $0D
	OCTAVE 3
	NOTE F#, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE 4, $0B
	OCTAVE 4
	NOTE D#, 4
	RELEASE 2, $0D
	NOTE E_, 2
	NOTE C#, 2
	RELEASE 4, $0B
	NOTE D#, 4
	RELEASE 2, $0D
	NOTE E_, 2
	NOTE C#, 2
	RELEASE 4, $0A
	NOTE D#, 8
	VIBRATO 4
	ATTEN 2
	RELEASE 3, $0F
	REST 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	RELEASE 4, $0A
	NOTE E_, 2
	RELEASE 2, $0F
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	RELEASE 4, $0B
	NOTE A_, 4
	ATTEN 2
	RELEASE 3, $0D
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 4
	RELEASE 3, $0F
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	RELEASE 3, $0D
	NOTE A_, 4
	RELEASE 3, $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 2
	REST 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 3, $0D
	NOTE D_, 4
	LEN_UNIT $02
	RELEASE 5, $0A
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	ATTEN 0
	SND_RET
Snd58_Ch3_5CEA:
	VOICE $05, 2, 8, 3, 12
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	SND_REPEAT 3
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	SND_REPEAT 2
	SND_RET
Snd58_Ch3_5D15:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 6
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	SND_REPEAT 6
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	RELEASE 5, $0A
	NOTE C_, $0A
	RELEASE 3, $0C
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 5, $0A
	OCTAVE 2
	NOTE C_, 8
	ATTEN 1
	WAVE 3
	RELEASE 3, $0C
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 4
	ATTEN 0
	VOICE $05, 2, 2, 3, 11
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	WAVE 2
	REST 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A_, 4
	LEN_UNIT $02
	PAN $0F
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
	OCTAVE 3
	NOTE B_, 1
	PAN $FF
	SND_RET

Snd58_Drm:
	SND_END
	db $FF ; unreachable byte after an end

Snd59_Ch2:
	DUTY_STEP 8, 2
	TEMPO $00
	VIBRATO 10
	VOICE $05, 9, 0, 2, 15
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	PAN $F0
	AUTOPAN 2
	DUTY_STEP 8, 2
	VIBRATO 7
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	AUTOPAN 0
	PAN $FF
	VIBRATO 10
	SND_SEGNO
	DUTY_STEP 8, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	PAN $F0
	AUTOPAN 2
	DUTY_STEP 8, 2
	VIBRATO 7
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	AUTOPAN 0
	PAN $FF
	VIBRATO 10
	SND_REPEAT 2
	DUTY_STEP 8, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	AUTOPAN 2
	DUTY_STEP 8, 2
	VIBRATO 7
	NOTE D_, 2
	NOTE D_, 2
	AUTOPAN 0
	PAN $FF
	SND_SEGNO
	DUTY_STEP 8, 2
	VIBRATO 10
	NOTE D_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE F_, 1
	NOTE F_, 1
	PAN $F0
	AUTOPAN 2
	DUTY_STEP 8, 2
	VIBRATO 7
	NOTE D_, 2
	NOTE D_, 2
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 2
	DUTY_STEP 8, 2
	NOTE D_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	SND_CALL Snd59_Ch2

Snd59_Ch1:
	VIBRATO 4
	VOICE $05, 6, 4, 2, 15
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	PAN $F0
	AUTOPAN 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE F_, 1
	SND_SEGNO
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN $F0
	AUTOPAN 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	AUTOPAN 0
	PAN $FF
	SND_REPEAT 3
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	SND_CALL Snd59_Ch1

Snd59_Ch3:
	VIBRATO 10
	VOICE $05, 2, 8, 3, 12
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 3
	OCTAVE 1
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE F_, 1
	VIBRATO 7
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 3
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	SND_CALL Snd59_Ch3

Snd59_Drm:
	SND_END
	db $FF ; unreachable byte after an end

Snd5A_Ch2:
	TEMPO $00
	VIBRATO 10
	VOICE $05, 8, 8, 2, 15
	DUTY_STEP 4, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	DUTY_STEP_OFF
	VIBRATO 7
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_REPEAT 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	VIBRATO 10
	DUTY_STEP 4, 2
	RELEASE 2, $0F
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	DUTY_STEP_OFF
	VIBRATO 7
	SND_SEGNO
	RELEASE 3, $0C
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 4
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 2, $0E
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	VIBRATO 10
	DUTY_STEP 4, 2
	RELEASE 2, $0D
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 3, $0C
	OCTAVE 3
	NOTE B_, 4
	NOTE E_, 4
	RELEASE 2, $0D
	NOTE A_, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 3, $0C
	NOTE F#, 4
	NOTE B_, 4
	RELEASE 2, $0D
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	VIBRATO 7
	SND_SEGNO
	RELEASE 5, $0E
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT $10
	DUTY_STEP 0, 1
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	SND_REPEAT $0F
	RELEASE 2, $0F
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	SND_CALL Snd5A_Ch2

Snd5A_Ch1:
	VIBRATO 1
	VOICE $05, 6, 4, 4, 14
	OCTAVE 3
	NOTE B_, 2
	REST 2
	ATTEN 3
	RELEASE 2, $0F
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 0
	RELEASE 4, $0E
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	ATTEN 3
	RELEASE 2, $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 0
	RELEASE 4, $0E
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE B_, 1
	SND_SEGNO
	REST 2
	NOTE F#, 2
	SND_REPEAT 4
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	REST 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	ATTEN 3
	RELEASE 2, $0F
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 0
	RELEASE 4, $0E
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	ATTEN 3
	RELEASE 2, $0F
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 0
	RELEASE 4, $0E
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE G_, 1
	NOTE B_, 1
	SND_SEGNO
	REST 2
	NOTE F#, 2
	SND_REPEAT 4
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	RELEASE 3, $0E
	OCTAVE 4
	NOTE G_, 4
	RELEASE 2, $0F
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	LEN_UNIT $01
	REST 2
	LEN_UNIT $05
	RELEASE $0F, $0A
	ATTEN 3
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	RELEASE 3, $0E
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	LEN_UNIT $04
	REST 7
	ATTEN 0
	VIBRATO 4
	LEN_UNIT $01
	REST 3
	LEN_UNIT $05
	PAN $F0
	RELEASE 5, $0D
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 4
	NOTE B_, 2
	RELEASE 7, $0A
	NOTE A_, 6
	RELEASE 2, $0D
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 5, $0D
	NOTE A_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 4
	NOTE B_, 2
	RELEASE 7, $0A
	NOTE A_, 6
	PAN $0F
	RELEASE 2, $0D
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 5, $0D
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE C#, 4
	NOTE E_, 2
	RELEASE 7, $0A
	NOTE D#, 6
	RELEASE 2, $0D
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 5, $0D
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE C#, 4
	NOTE E_, 2
	RELEASE 5, $0A
	NOTE D#, 4
	PAN $FF
	RELEASE 2, $0D
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	LEN_UNIT $01
	NOTE A_, 2
	LEN_UNIT $05
	SND_CALL Snd5A_Ch1

Snd5A_Ch3:
	VOICE $05, 2, 8, 5, 10
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	SND_REPEAT 2
	WAVE $0F
	SND_SEGNO
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	WAVE 8
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE D_, 2
	SND_REPEAT 2
	WAVE $0F
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	OCTAVE 5
	NOTE G_, 4
	WAVE 8
	OCTAVE 1
	NOTE D_, 6
	NOTE A_, 2
	NOTE G_, 4
	NOTE E_, 4
	NOTE A_, 6
	NOTE G_, 2
	NOTE F#, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	VIBRATO 7
	RELEASE 2, $0C
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	REST 4
	WAVE 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	VOICE $05, 2, 2, 5, 13
	NOTE A_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 4
	NOTE B_, 2
	RELEASE 7, $0A
	NOTE A_, 6
	RELEASE 2, $0A
	NOTE A_, 1
	NOTE A_, 1
	RELEASE 5, $0D
	NOTE A_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 4
	NOTE B_, 2
	RELEASE 7, $0A
	NOTE A_, 6
	RELEASE 2, $0A
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	VIBRATO 7
	RELEASE 5, $0D
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE C#, 4
	NOTE E_, 2
	RELEASE 7, $0A
	NOTE D#, 6
	RELEASE 2, $0A
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 5, $0D
	NOTE D_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE C#, 4
	NOTE E_, 2
	RELEASE 5, $0A
	NOTE D#, 4
	VIBRATO 13
	RELEASE 2, $0A
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	SND_CALL Snd5A_Ch3

Snd5A_Drm:
	DRUM_UNIT $05
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 6
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	SND_REPEAT 7
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd5A_Drm

Snd5B_Ch2:
	TEMPO $00
	VIBRATO 10
	VOICE $05, 8, 4, 3, 14
	SND_CALL Snd5B_Ch2_624B
Snd5B_Ch2_61D3:
	SND_CALL Snd5B_Ch2_6272
	SND_CALL Snd5B_Ch2_6293
	SND_CALL Snd5B_Ch2_6272
	SND_CALL Snd5B_Ch2_62A4
	SND_CALL Snd5B_Ch2_62C1
	SND_CALL Snd5B_Ch2_62E0
	SND_CALL Snd5B_Ch2_62C1
	SND_CALL Snd5B_Ch2_62EB
	SND_CALL Snd5B_Ch2_61D3

Snd5B_Ch1:
	VIBRATO 4
	LEN_UNIT $01
	REST 1
	VOICE $05, 6, 0, 2, 12
	SND_CALL Snd5B_Ch1_62F7
Snd5B_Ch1_61FA:
	SND_CALL Snd5B_Ch1_6314
	SND_CALL Snd5B_Ch1_632F
	SND_CALL Snd5B_Ch1_6314
	SND_CALL Snd5B_Ch1_6347
	SND_CALL Snd5B_Ch1_635B
	SND_CALL Snd5B_Ch1_637F
	SND_CALL Snd5B_Ch1_635B
	SND_CALL Snd5B_Ch1_638C
	SND_CALL Snd5B_Ch1_61FA

Snd5B_Ch3:
	VOICE $05, 2, 8, 5, 10
	SND_CALL Snd5B_Ch3_639C
Snd5B_Ch3_621C:
	SND_CALL Snd5B_Ch3_63C1
	SND_CALL Snd5B_Ch3_63DE
	SND_CALL Snd5B_Ch3_63C1
	SND_CALL Snd5B_Ch3_63FB
	SND_CALL Snd5B_Ch3_6407
	SND_CALL Snd5B_Ch3_642A
	SND_CALL Snd5B_Ch3_6407
	SND_CALL Snd5B_Ch3_6437
	SND_CALL Snd5B_Ch3_621C

Snd5B_Drm:
	DRUM_UNIT $05
	SND_CALL Snd5B_Drm_6443
Snd5B_Drm_623C:
	SND_CALL Snd5B_Drm_6452
	SND_CALL Snd5B_Drm_6475
	SND_CALL Snd5B_Drm_6492
	SND_CALL Snd5B_Drm_649E
	SND_CALL Snd5B_Drm_623C
Snd5B_Ch2_624B:
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	REST 4
	PAN $F0
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	REST 4
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	SND_REPEAT 4
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	PAN $F0
	NOTE B_, 1
	NOTE A_, 3
	PAN $FF
	NOTE B_, 1
	NOTE A_, 3
	PAN $0F
	NOTE B_, 1
	NOTE A_, 3
	PAN $FF
	SND_RET
Snd5B_Ch2_6272:
	VIBRATO 1
	VOICE $05, 8, 8, 2, 14
	DUTY_STEP 4, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	LEN_UNIT $01
	NOTE F#, 3
	NOTE E_, 7
	LEN_UNIT $05
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 4
	SND_RET
Snd5B_Ch2_6293:
	NOTE B_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F#, 2
	SND_SEGNO
	LEN_UNIT $01
	NOTE G#, 3
	NOTE F#, 7
	NOTE E_, $0A
	SND_REPEAT 4
	SND_RET
Snd5B_Ch2_62A4:
	SND_SEGNO
	LEN_UNIT $01
	NOTE A_, 3
	NOTE B_, 7
	NOTE A_, $0A
	LEN_UNIT $05
	NOTE A_, 4
	SND_REPEAT 2
	LEN_UNIT $01
	NOTE A_, 3
	NOTE B_, 7
	NOTE A_, $0A
	NOTE A_, 3
	NOTE B_, 7
	NOTE A_, $0A
	LEN_UNIT $05
	NOTE A_, 4
	RELEASE 4, $0A
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_RET
Snd5B_Ch2_62C1:
	DUTY_STEP 0, 3
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 4
	SND_RET
Snd5B_Ch2_62E0:
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_RET
Snd5B_Ch2_62EB:
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	RELEASE 4, $0E
	NOTE D_, 4
	NOTE D_, 4
	SND_RET
Snd5B_Ch1_62F7:
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	REST 4
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	REST 4
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 3
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 3
	SND_REPEAT 3
	OCTAVE 4
	NOTE B_, 1
	LEN_UNIT $02
	NOTE A_, 7
	SND_RET
Snd5B_Ch1_6314:
	VOICE $05, 6, 4, 2, 12
	DUTY_STEP 0, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_RET
Snd5B_Ch1_632F:
	OCTAVE 4
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 0
	NOTE C#, 2
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_RET
Snd5B_Ch1_6347:
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 4
	DUTY_STEP_OFF
	SND_RET
Snd5B_Ch1_635B:
	LEN_UNIT $01
	REST 2
	VOICE $05, 6, 0, 6, 15
	OCTAVE 4
	NOTE D_, 8
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	RELEASE 4, $0F
	NOTE A_, 4
	NOTE A_, 4
	RELEASE 2, $0F
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 4, $0F
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 2, $0F
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_RET
Snd5B_Ch1_637F:
	NOTE D_, 2
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	LEN_UNIT $02
	NOTE E_, 4
	SND_RET
Snd5B_Ch1_638C:
	NOTE D_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 4
	VIBRATO 15
	LEN_UNIT $03
	RELEASE 5, $0E
	OCTAVE 6
	NOTE D_, 6
	VIBRATO 4
	SND_RET
Snd5B_Ch3_639C:
	OCTAVE 1
	NOTE A_, 8
	NOTE A_, 8
	NOTE A_, 8
	NOTE A_, 8
	NOTE A_, 4
	PAN $F0
	NOTE A_, 4
	PAN $FF
	NOTE A_, 4
	PAN $0F
	NOTE A_, 4
	PAN $FF
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	PAN $0F
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	SND_REPEAT 2
	SND_RET
Snd5B_Ch3_63C1:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT 2
	SND_RET
Snd5B_Ch3_63DE:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_RET
Snd5B_Ch3_63FB:
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 7
	WAVE 2
	OCTAVE 3
	NOTE A_, 4
	SND_RET
Snd5B_Ch3_6407:
	VIBRATO 0
	VOICE $05, 2, 2, 7, 14
	OCTAVE 4
	NOTE D_, 8
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	RELEASE 5, $0E
	NOTE A_, 4
	NOTE A_, 4
	RELEASE 3, $0E
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 5, $0E
	NOTE E_, 4
	NOTE E_, 4
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_RET
Snd5B_Ch3_642A:
	NOTE D_, 2
	VIBRATO 7
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_RET
Snd5B_Ch3_6437:
	NOTE D_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 4
	WAVE 8
	RELEASE 5, $0E
	OCTAVE 2
	NOTE D_, 4
	SND_RET
Snd5B_Drm_6443:
	DRUM 9, 8
	DRUM 9, 8
	DRUM 9, 8
	DRUM 9, 8
	DRUM 9, 4
	DRUM 8, 4
	DRUM 9, 4
	DRUM 8, 4
	DRUM 9, 4
	DRUM 8, 4
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_RET
Snd5B_Drm_6452:
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5B_Drm_6475:
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5B_Drm_6492:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT $0D
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_RET
Snd5B_Drm_649E:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT $0C
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_RET

Snd5C_Ch2:
	TEMPO $40
	VOICE $04, 9, 4, 5, 10
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 6
	ATTEN 5
	NOTE G_, 3
	ATTEN 4
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 2
	DUTY_STEP 8, 3
	NOTE F#, 6
	DUTY_STEP_OFF
	ATTEN 4
	NOTE F#, 3
	ATTEN 5
	NOTE F#, 2
	ATTEN 3
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	NOTE F#, 2
	DUTY_STEP 8, 3
	NOTE F_, 6
	DUTY_STEP_OFF
	ATTEN 4
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 2
	ATTEN 3
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	ATTEN 0
	OCTAVE 4
	NOTE F_, 2
	DUTY_STEP 8, 3
	NOTE G_, 6
	DUTY_STEP_OFF
	ATTEN 4
	NOTE G_, 3
	ATTEN 5
	NOTE G_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	ATTEN 0
	SND_REPEAT 2
	VOICE $04, 8, 8, 6, 15
	OCTAVE 4
	NOTE D_, 4
	RELEASE 6, $0E
	NOTE F#, 8
	RELEASE 6, $0F
	NOTE E_, 4
	RELEASE 6, $0C
	NOTE G_, $0A
	RELEASE 3, $0C
	NOTE F#, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 6, $0F
	OCTAVE 3
	NOTE B_, 4
	RELEASE 6, $0E
	OCTAVE 4
	NOTE E_, 8
	RELEASE 6, $0E
	NOTE F#, 4
	RELEASE 6, $0C
	OCTAVE 3
	NOTE B_, $0A
	RELEASE 3, $0C
	OCTAVE 4
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 6, $0F
	NOTE A_, 4
	RELEASE 6, $0E
	OCTAVE 4
	NOTE E_, 8
	RELEASE 6, $0E
	NOTE F#, 4
	RELEASE 6, $0C
	NOTE A_, $0A
	RELEASE 3, $0C
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	RELEASE 6, $0C
	NOTE A_, $0A
	RELEASE 3, $0C
	NOTE F#, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 6, $0E
	NOTE E_, 8
	LEN_UNIT $01
	RELEASE 6, $0E
	NOTE E_, 5
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 6
	NOTE E_, 5
	LEN_UNIT $04
	OCTAVE 4
	NOTE D_, 4
	RELEASE 6, $0E
	NOTE F#, 8
	RELEASE 6, $0F
	NOTE E_, 4
	RELEASE 6, $0C
	NOTE G_, $0A
	RELEASE 3, $0C
	NOTE F#, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 6, $0F
	OCTAVE 3
	NOTE B_, 4
	RELEASE 6, $0E
	OCTAVE 4
	NOTE E_, 8
	RELEASE 6, $0F
	NOTE F#, 4
	RELEASE 6, $0C
	NOTE A_, $0A
	RELEASE 3, $0C
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	DUTY_STEP 4, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	DUTY_STEP_OFF
	RELEASE 6, $0E
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE F#, 2
	NOTE A_, 8
	DUTY 4
	RELEASE 3, $0F
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	VIBRATO 10
	VOICE $04, 8, 8, 7, 10
	DUTY_STEP 4, 2
	SND_SEGNO
	ATTEN 3
	RELEASE 5, $0A
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_REPEAT 3
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	DUTY_STEP_OFF
	RELEASE 7, $0D
	ATTEN 2
	OCTAVE 2
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 2
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 2
	RELEASE 7, $0A
	NOTE G_, 4
	REST 8
	NOTE A_, 4
	REST 4
	NOTE D_, 6
	DUTY 4
	LEN_UNIT $01
	REST 1
	LEN_UNIT $04
	RELEASE 6, $0D
	OCTAVE 3
	NOTE A_, 4
	LEN_UNIT $01
	OCTAVE 4
	NOTE D_, 7
	ATTEN 0
	SND_CALL Snd5C_Ch2

Snd5C_Ch1:
	VOICE $04, 5, 0, 7, 10
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 3
	DUTY_STEP_OFF
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	DUTY_STEP 8, 2
	DUTY_STEP 8, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 3
	DUTY_STEP_OFF
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	DUTY_STEP 8, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 3
	DUTY_STEP_OFF
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
	SND_REPEAT 2
	VIBRATO 4
	LEN_UNIT $01
	REST 1
	LEN_UNIT $04
	DUTY 4
	RELEASE 6, $0E
	OCTAVE 4
	NOTE D_, 4
	NOTE F#, 8
	NOTE E_, 4
	NOTE G_, $0A
	RELEASE 3, $0E
	NOTE F#, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 6, $0E
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 8
	NOTE F#, 4
	OCTAVE 3
	NOTE B_, $0A
	RELEASE 3, $0E
	OCTAVE 4
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 3, $0C
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, 8
	NOTE F#, 4
	NOTE A_, $0A
	RELEASE 3, $0E
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	RELEASE 6, $0E
	NOTE A_, $0A
	RELEASE 3, $0E
	NOTE F#, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 6, $0E
	NOTE E_, 7
	LEN_UNIT $01
	REST 4
	PAN $0F
	NOTE E_, 5
	NOTE C#, 6
	OCTAVE 3
	NOTE B_, 5
	PAN $F0
	NOTE A_, 5
	NOTE G_, 6
	NOTE E_, 4
	PAN $FF
	LEN_UNIT $04
	LEN_UNIT $01
	REST 1
	LEN_UNIT $04
	RELEASE 6, $0E
	OCTAVE 4
	NOTE D_, 4
	NOTE F#, 8
	NOTE E_, 4
	NOTE G_, $0A
	RELEASE 3, $0E
	NOTE F#, 2
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 6, $0E
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE E_, 8
	NOTE F#, 4
	NOTE A_, $0A
	RELEASE 3, $0E
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 3, $0E
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	RELEASE 6, $0E
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE D_, 3
	NOTE F#, 2
	NOTE A_, 8
	PAN $0F
	RELEASE 3, $0F
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	PAN $0F
	NOTE D_, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE A_, 1
	PAN $FF
	VOICE $04, 5, 8, 4, 13
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 4
	NOTE C#, 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	RELEASE 6, $0E
	NOTE F#, 8
	RELEASE 4, $0F
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE F#, 2
	RELEASE 6, $0E
	NOTE D_, 6
	OCTAVE 5
	NOTE D_, 2
	NOTE C#, 7
	LEN_UNIT $01
	REST 3
	LEN_UNIT $04
	VIBRATO 10
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE A_, 2
	SND_REPEAT 2
	NOTE G_, 4
	LEN_UNIT $01
	REST 1
	LEN_UNIT $04
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE A#, 4
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT $01
	NOTE D_, 7
	LEN_UNIT $04
	OCTAVE 3
	NOTE A_, 4
	RELEASE 2, $0D
	NOTE A_, 2
	ATTEN 0
	SND_CALL Snd5C_Ch1

Snd5C_Ch3:
	VOICE $04, 2, 8, 6, 11
	OCTAVE 2
	NOTE D_, 4
	SND_SEGNO
	RELEASE 6, $0C
	NOTE D_, 2
	NOTE D_, 2
	PAN $F0
	NOTE D_, 2
	PAN $FF
	NOTE A_, 2
	PAN $0F
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	RELEASE 6, $0A
	OCTAVE 2
	NOTE D_, 6
	SND_REPEAT 3
	RELEASE 6, $0C
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	OCTAVE 2
	NOTE D_, 2
	PAN $0F
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	RELEASE 6, $0B
	OCTAVE 2
	NOTE D_, 4
	SND_SEGNO
	RELEASE 6, $0C
	NOTE D_, 2
	NOTE D_, 2
	PAN $F0
	NOTE D_, 2
	PAN $FF
	NOTE A_, 2
	PAN $0F
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	RELEASE 6, $0A
	OCTAVE 2
	NOTE D_, 6
	SND_REPEAT 3
	RELEASE 6, $0C
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	PAN $F0
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	OCTAVE 2
	NOTE D_, 2
	PAN $0F
	OCTAVE 3
	NOTE D_, 2
	PAN $FF
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	LEN_UNIT $01
	RELEASE 5, $0A
	NOTE E_, 5
	OCTAVE 3
	NOTE C#, 6
	OCTAVE 2
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 6
	NOTE E_, 5
	LEN_UNIT $04
	SND_SEGNO
	RELEASE 6, $0E
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 2
	SND_REPEAT 2
	SND_SEGNO
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	SND_REPEAT 2
	RELEASE 6, $0E
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, 2
	SND_SEGNO
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 2
	VOICE $04, 2, 4, 2, 10
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 3, $0C
	NOTE D_, 4
	NOTE C#, 4
	NOTE E_, 4
	RELEASE 2, $0A
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	RELEASE 6, $0D
	NOTE F#, 8
	RELEASE 2, $0A
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE F#, 2
	RELEASE 5, $0E
	NOTE D_, 6
	RELEASE 2, $0A
	OCTAVE 5
	NOTE D_, 2
	RELEASE 6, $0D
	NOTE C#, 8
	SND_SEGNO
	RELEASE 2, $0A
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE 3, $0C
	NOTE B_, 4
	NOTE A_, 4
	SND_REPEAT 2
	OCTAVE 4
	NOTE B_, 4
	RELEASE 2, $0A
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE A#, 1
	RELEASE 3, $0C
	NOTE A#, 4
	RELEASE 2, $0A
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	RELEASE 3, $0C
	NOTE A_, 4
	RELEASE 2, $0A
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	WAVE 8
	RELEASE 6, $0C
	OCTAVE 1
	NOTE A_, 4
	OCTAVE 2
	NOTE A_, 2
	SND_CALL Snd5C_Ch3

Snd5C_Drm:
	DRUM_UNIT $04
	DRUM $0B, 4
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 8, 6
	SND_REPEAT 3
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 4
	SND_SEGNO
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM 8, 6
	SND_REPEAT 3
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	LEN_UNIT $01
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	LEN_UNIT $04
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 2, 2
	SND_REPEAT 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 2
	SND_REPEAT $0F
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 2
	SND_REPEAT 8
	DRUM $0B, 8
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 8
	DRUM $0B, 4
	REST 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_CALL Snd5C_Drm

Snd5D_Ch2:
	TEMPO $25
	VOICE $06, 9, 0, 3, 14
	SND_CALL Snd5D_Ch2_69B7
	SND_CALL Snd5D_Ch2_69D2
	SND_CALL Snd5D_Ch2_69B7
	SND_CALL Snd5D_Ch2_69EB
	SND_CALL Snd5D_Ch2

Snd5D_Ch1:
	VIBRATO 4
	LEN_UNIT $01
	REST 1
	ATTEN 1
	VOICE $06, 6, 4, 3, 12
	SND_CALL Snd5D_Ch1_6A14
	SND_CALL Snd5D_Ch1_6A34
	SND_CALL Snd5D_Ch1_6A14
	SND_CALL Snd5D_Ch1_6A50
	SND_CALL Snd5D_Ch1

Snd5D_Ch3:
	VOICE $06, 2, 8, 3, 12
	SND_CALL Snd5D_Ch3_6A94
	SND_CALL Snd5D_Ch3_6AAC
	SND_CALL Snd5D_Ch3_6A94
	SND_CALL Snd5D_Ch3_6ACC
	SND_CALL Snd5D_Ch3

Snd5D_Drm:
	DRUM_UNIT $06
	SND_CALL Snd5D_Drm_6AF3
	SND_CALL Snd5D_Drm_6B06
	SND_CALL Snd5D_Drm_6B11
	SND_CALL Snd5D_Drm_6B1C
	SND_CALL Snd5D_Drm
Snd5D_Ch2_69B7:
	SND_SEGNO
	VIBRATO 7
	OCTAVE 4
	NOTE C_, 2
	VIBRATO 9
	RELEASE 7, $0F
	OCTAVE 3
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 2
	VIBRATO 5
	ATTEN 6
	NOTE A#, 2
	ATTEN 7
	NOTE A#, 2
	ATTEN 8
	NOTE A#, 2
	ATTEN 0
	SND_REPEAT 4
	SND_RET
Snd5D_Ch2_69D2:
	SND_SEGNO
	VIBRATO 7
	NOTE B_, 2
	VIBRATO 9
	RELEASE 7, $0F
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	VIBRATO 5
	ATTEN 6
	NOTE A_, 2
	ATTEN 7
	NOTE A_, 2
	ATTEN 8
	NOTE A_, 2
	ATTEN 0
	SND_REPEAT 4
	SND_RET
Snd5D_Ch2_69EB:
	SND_SEGNO
	DUTY 8
	VIBRATO 7
	ATTEN 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 1
	NOTE B_, 2
	NOTE G_, 1
	PAN $F0
	OCTAVE 2
	NOTE C_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	PAN $0F
	OCTAVE 2
	NOTE C#, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	PAN $F0
	OCTAVE 2
	NOTE D_, 1
	PAN $FF
	OCTAVE 1
	NOTE G_, 1
	SND_REPEAT 4
	ATTEN 0
	SND_RET
Snd5D_Ch1_6A14:
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	SND_REPEAT 4
	SND_RET
Snd5D_Ch1_6A34:
	SND_SEGNO
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	SND_REPEAT 4
	SND_RET
Snd5D_Ch1_6A50:
	SND_SEGNO
	ATTEN 3
	VOICE $06, 6, 0, 2, 14
	NOTE G_, 2
	NOTE G_, 2
	RELEASE $0D, $0C
	NOTE A#, 2
	RELEASE 3, $0E
	NOTE G_, 1
	RELEASE $0D, $0C
	NOTE B_, 2
	RELEASE 3, $0E
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
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
	SND_REPEAT 3
	RELEASE 2, $0E
	NOTE G_, 2
	NOTE G_, 2
	RELEASE $0D, $0C
	NOTE A#, 2
	RELEASE 3, $0E
	NOTE G_, 1
	RELEASE $0D, $0C
	NOTE B_, 2
	RELEASE 3, $0E
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT $01
	OCTAVE 3
	NOTE G_, 5
	LEN_UNIT $06
	ATTEN 0
	SND_RET
Snd5D_Ch3_6A94:
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_REPEAT 4
	SND_RET
Snd5D_Ch3_6AAC:
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	SND_REPEAT 4
	SND_RET
Snd5D_Ch3_6ACC:
	SND_SEGNO
	VOICE $06, 2, 2, 3, 14
	PAN $FF
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	VIBRATO 7
	RELEASE $0D, $0F
	NOTE A#, 2
	RELEASE 4, $0E
	NOTE G_, 1
	RELEASE $0D, $0F
	NOTE B_, 2
	RELEASE 4, $0E
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	VIBRATO 13
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 2
	SND_REPEAT 4
	SND_RET
Snd5D_Drm_6AF3:
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	SND_REPEAT 3
	SND_RET
Snd5D_Drm_6B06:
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	SND_REPEAT 4
	SND_RET
Snd5D_Drm_6B11:
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 2
	SND_REPEAT 4
	SND_RET
Snd5D_Drm_6B1C:
	SND_SEGNO
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 6, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 3
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET

Snd5E_Ch2:
	TRANSPOSE_UP $0C
	TEMPO $20
	VOICE $05, 8, 0, 3, 10
	SND_CALL Snd5E_Ch2_6B6B
	SND_CALL Snd5E_Ch2

Snd5E_Ch1:
	VIBRATO 10
	VOICE $05, 6, 12, 7, 10
	SND_CALL Snd5E_Ch1_6BA6
	SND_CALL Snd5E_Ch1

Snd5E_Ch3:
	VIBRATO 4
	VOICE $05, 2, 8, 4, 14
	SND_CALL Snd5E_Ch3_6BEE
	SND_CALL Snd5E_Ch3

Snd5E_Drm:
	DRUM_UNIT $05
	SND_CALL Snd5E_Drm_6C35
	SND_CALL Snd5E_Drm_6C35
Snd5E_Drm_6B65:
	SND_CALL Snd5E_Drm_6C3E
	SND_CALL Snd5E_Drm_6B65
Snd5E_Ch2_6B6B:
	SND_SEGNO
	DUTY 0
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	SND_REPEAT 2
	DUTY $0C
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE G_, 1
	SND_REPEAT 2
	SND_RET
Snd5E_Ch1_6BA6:
	DUTY $0C
	SND_SEGNO
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE D_, 1
	SND_REPEAT 2
	DUTY 0
	LEN_UNIT $01
	REST 2
	LEN_UNIT $05
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE B_, 1
	LEN_UNIT $01
	NOTE G_, 3
	ATTEN 0
	LEN_UNIT $05
	SND_RET
Snd5E_Ch3_6BEE:
	SND_SEGNO
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	SND_REPEAT 2
	SND_RET
Snd5E_Drm_6C35:
	SND_SEGNO
	DRUM 8, $0C
	REST 2
	DRUM 8, 2
	DRUM 8, $0C
	REST 4
	SND_REPEAT 2
	SND_RET
Snd5E_Drm_6C3E:
	SND_SEGNO
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT 8
	SND_RET

Snd5F_Ch2:
	TEMPO $00
	VOICE $05, 8, 12, 7, 8
	SND_CALL Snd5F_Ch2_6CCE
Snd5F_Ch2_6C53:
	SND_CALL Snd5F_Ch2_6CDF
	SND_CALL Snd5F_Ch2_6D02
	SND_CALL Snd5F_Ch2_6CDF
	SND_CALL Snd5F_Ch2_6D18
	SND_CALL Snd5F_Ch2_6D37
	SND_CALL Snd5F_Ch2_6D5B
	SND_CALL Snd5F_Ch2_6D92
	SND_CALL Snd5F_Ch2_6C53

Snd5F_Ch1:
	VOICE $05, 6, 4, 7, 9
	SND_CALL Snd5F_Ch1_6DCB
Snd5F_Ch1_6C72:
	SND_CALL Snd5F_Ch1_6DE7
	SND_CALL Snd5F_Ch1_6E26
	SND_CALL Snd5F_Ch1_6DE7
	SND_CALL Snd5F_Ch1_6E4F
	SND_CALL Snd5F_Ch1_6E7A
	SND_CALL Snd5F_Ch1_6EB8
	SND_CALL Snd5F_Ch1_6F03
	SND_CALL Snd5F_Ch1_6EB8
	SND_CALL Snd5F_Ch1_6F23
	SND_CALL Snd5F_Ch1_6C72

Snd5F_Ch3:
	VIBRATO 10
	VOICE $05, 2, 2, 0, 0
	SND_CALL Snd5F_Ch3_6F3B
Snd5F_Ch3_6C99:
	SND_CALL Snd5F_Ch3_6F5F
	SND_CALL Snd5F_Ch3_6F89
	SND_CALL Snd5F_Ch3_6F5F
	SND_CALL Snd5F_Ch3_6FB0
	SND_CALL Snd5F_Ch3_6FCC
	SND_CALL Snd5F_Ch3_700B
	SND_CALL Snd5F_Ch3_7030
	SND_CALL Snd5F_Ch3_6C99

Snd5F_Drm:
	DRUM_UNIT $05
	SND_CALL Snd5F_Drm_7057
Snd5F_Drm_6CB6:
	SND_CALL Snd5F_Drm_7069
	SND_CALL Snd5F_Drm_7077
	SND_CALL Snd5F_Drm_7069
	SND_CALL Snd5F_Drm_708B
	SND_CALL Snd5F_Drm_709E
	SND_CALL Snd5F_Drm_70BA
	SND_CALL Snd5F_Drm_70CC
	SND_CALL Snd5F_Drm_6CB6
Snd5F_Ch2_6CCE:
	DUTY_STEP 8, 2
	OCTAVE 1
	NOTE G_, $0C
	RELEASE 7, $0C
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_RET
Snd5F_Ch2_6CDF:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 4
	NOTE D_, 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 4
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 4
	SND_RET
Snd5F_Ch2_6D02:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 8
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 7
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5F_Ch2_6D18:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 4
	SND_SEGNO
	NOTE D_, 2
	NOTE A_, 2
	SND_REPEAT 4
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_RET
Snd5F_Ch2_6D37:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_REPEAT 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	OCTAVE 1
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 2
	SND_RET
Snd5F_Ch2_6D5B:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 1
	NOTE G_, 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 2
	PAN $FF
	OCTAVE 1
	NOTE G_, 2
	PAN $0F
	OCTAVE 2
	NOTE G_, 2
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	PAN $0F
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_REPEAT 4
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 4
	SND_RET
Snd5F_Ch2_6D92:
	SND_SEGNO
	RELEASE 4, $0D
	OCTAVE 1
	NOTE G_, 2
	PAN $F0
	OCTAVE 2
	NOTE G_, 2
	PAN $FF
	OCTAVE 1
	NOTE G_, 2
	PAN $0F
	OCTAVE 2
	NOTE G_, 2
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE A_, 2
	PAN $F0
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	OCTAVE 1
	NOTE A_, 2
	PAN $0F
	OCTAVE 2
	NOTE A_, 2
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	SND_REPEAT 4
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	SND_RET
Snd5F_Ch1_6DCB:
	OCTAVE 2
	NOTE G_, 4
	LEN_UNIT $01
	RELEASE 4, $0C
	OCTAVE 3
	NOTE D_, 7
	NOTE G_, 6
	NOTE B_, 7
	LEN_UNIT $05
	RELEASE 7, 9
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 4
	RELEASE $0D, $0A
	NOTE A_, 4
	ATTEN 1
	NOTE A_, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 4
	ATTEN 0
	SND_RET
Snd5F_Ch1_6DE7:
	VIBRATO 4
	VOICE $01, 6, 4, 5, 10
	REST 4
	LEN_UNIT $05
	ATTEN 3
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $06
	NOTE C_, 6
	LEN_UNIT $05
	VIBRATO 7
	PAN $F0
	ATTEN 0
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 4
	NOTE D_, 2
	REST 2
	PAN $FF
	VIBRATO 13
	ATTEN 2
	RELEASE 5, $0A
	OCTAVE 3
	NOTE G_, 8
	NOTE G_, 8
	VIBRATO 7
	PAN $0F
	ATTEN 0
	RELEASE 5, $0A
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 2
	REST 2
	PAN $FF
	ATTEN 0
	SND_RET
Snd5F_Ch1_6E26:
	VIBRATO 4
	RELEASE 5, $0F
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F#, 4
	RELEASE 3, $0F
	NOTE D_, 3
	NOTE D_, 1
	NOTE D_, 3
	NOTE D_, 1
	RELEASE 5, $0E
	NOTE D_, 5
	ATTEN 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE G_, 4
	RELEASE 3, $0F
	OCTAVE 3
	NOTE B_, 3
	NOTE B_, 1
	NOTE B_, 3
	NOTE B_, 1
	RELEASE 5, $0E
	NOTE B_, 8
	SND_RET
Snd5F_Ch1_6E4F:
	VIBRATO 1
	VOICE $05, 7, 4, 3, 15
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F#, 4
	NOTE F#, 3
	NOTE F#, 1
	NOTE F#, 3
	NOTE F#, 1
	RELEASE 5, $0E
	NOTE F#, 4
	LEN_UNIT $01
	REST 2
	LEN_UNIT $05
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	LEN_UNIT $02
	OCTAVE 4
	NOTE C#, 4
	LEN_UNIT $05
	SND_RET
Snd5F_Ch1_6E7A:
	RELEASE 3, $0F
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	VIBRATO 9
	RELEASE 5, $0E
	NOTE D_, 6
	VIBRATO 1
	RELEASE 3, $0F
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	VIBRATO 9
	RELEASE 5, $0E
	NOTE D_, 8
	VIBRATO 1
	SND_SEGNO
	RELEASE $0D, 9
	OCTAVE 3
	NOTE G#, 4
	RELEASE 3, $0F
	NOTE D_, 4
	SND_REPEAT 2
	LEN_UNIT $01
	REST 2
	LEN_UNIT $05
	ATTEN 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	LEN_UNIT $02
	NOTE A_, 4
	SND_RET
Snd5F_Ch1_6EB8:
	VIBRATO 4
	LEN_UNIT $01
	REST 2
	VOICE $05, 8, 8, 3, 12
	ATTEN 2
	OCTAVE 4
	NOTE C_, 2
	PAN $0F
	OCTAVE 5
	NOTE C_, 2
	PAN $FF
	OCTAVE 3
	NOTE B_, 2
	PAN $F0
	OCTAVE 4
	NOTE B_, 2
	PAN $FF
	OCTAVE 3
	NOTE A_, 2
	PAN $0F
	OCTAVE 4
	NOTE A_, 2
	PAN $FF
	OCTAVE 3
	NOTE G_, 2
	PAN $F0
	OCTAVE 4
	NOTE G_, 2
	PAN $FF
	OCTAVE 3
	NOTE F#, 2
	PAN $0F
	OCTAVE 4
	NOTE F#, 2
	PAN $FF
	OCTAVE 3
	NOTE E_, 2
	PAN $F0
	OCTAVE 4
	NOTE E_, 2
	PAN $FF
	OCTAVE 3
	NOTE D#, 2
	PAN $0F
	OCTAVE 4
	NOTE D#, 2
	PAN $FF
	OCTAVE 3
	NOTE E_, 2
	PAN $F0
	OCTAVE 4
	NOTE E_, 2
	PAN $FF
	SND_RET
Snd5F_Ch1_6F03:
	LEN_UNIT $03
	RELEASE 3, $0C
	OCTAVE 4
	NOTE D_, 6
	LEN_UNIT $05
	ATTEN 0
	RELEASE 2, $0F
	NOTE F#, 3
	NOTE D_, 1
	RELEASE 6, $0E
	NOTE D_, 8
	RELEASE 2, $0F
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE G_, 3
	OCTAVE 3
	NOTE B_, 1
	RELEASE 6, $0E
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd5F_Ch1_6F23:
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 3
	NOTE G_, 1
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN_UNIT $02
	REST 4
	LEN_UNIT $05
	SND_RET
Snd5F_Ch3_6F3B:
	OCTAVE 2
	NOTE G_, 4
	LEN_UNIT $01
	RELEASE 3, $0D
	OCTAVE 3
	NOTE G_, 7
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 7
	LEN_UNIT $05
	RELEASE 7, $0A
	NOTE D_, 4
	LEN_UNIT $01
	RELEASE 3, $0D
	OCTAVE 3
	NOTE G_, 7
	NOTE B_, 6
	OCTAVE 4
	NOTE E_, 7
	LEN_UNIT $05
	RELEASE 0, 0
	NOTE D_, 8
	RELEASE 7, 8
	NOTE D_, 6
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5F_Ch3_6F5F:
	VIBRATO 0
	RELEASE 6, $0D
	OCTAVE 4
	NOTE C_, 8
	NOTE C_, 8
	WAVE $0B
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 2
	NOTE F#, 4
	NOTE D_, 2
	WAVE 2
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 8
	NOTE B_, 8
	WAVE $0B
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 4
	NOTE D_, 2
	WAVE 2
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5F_Ch3_6F89:
	RELEASE 6, $0D
	OCTAVE 4
	NOTE C_, 4
	NOTE F#, 4
	NOTE F#, 4
	OCTAVE 5
	NOTE C_, 4
	RELEASE 4, $0D
	OCTAVE 4
	NOTE F#, 3
	NOTE F#, 1
	NOTE F#, 3
	NOTE F#, 1
	RELEASE 6, $0B
	NOTE F#, 5
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE B_, 4
	RELEASE 4, $0D
	NOTE G_, 3
	NOTE G_, 1
	NOTE G_, 3
	NOTE G_, 1
	RELEASE 6, $0B
	NOTE G_, 6
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5F_Ch3_6FB0:
	OCTAVE 4
	NOTE C#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE B_, 4
	RELEASE 4, $0D
	NOTE A_, 3
	NOTE A_, 1
	NOTE A_, 3
	NOTE A_, 1
	RELEASE 6, $0D
	NOTE A_, 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	SND_RET
Snd5F_Ch3_6FCC:
	VIBRATO 10
	VOICE $05, 2, 2, 7, 8
	RELEASE $0A, $0D
	OCTAVE 5
	NOTE D_, 2
	WAVE $0D
	RELEASE 4, $0D
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 7, $0A
	NOTE F_, 6
	RELEASE 4, $0C
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	RELEASE 7, $0A
	NOTE F#, 6
	RELEASE 4, $0C
	NOTE D_, 2
	RELEASE $0D, $0C
	NOTE G#, 4
	RELEASE 4, $0C
	NOTE D_, 4
	RELEASE $0D, $0C
	NOTE G#, 4
	RELEASE 4, $0C
	NOTE D_, 4
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	WAVE 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	SND_RET
Snd5F_Ch3_700B:
	RELEASE 6, $0E
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE C_, 3
	RELEASE 3, $0E
	OCTAVE 3
	NOTE F#, 1
	RELEASE 7, $0A
	NOTE F#, 8
	RELEASE 6, $0E
	NOTE D_, 4
	NOTE B_, 3
	RELEASE 3, $0E
	NOTE G_, 1
	RELEASE 6, $0E
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	SND_RET
Snd5F_Ch3_7030:
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 4
	NOTE E_, 4
	NOTE D#, 4
	NOTE E_, 4
	RELEASE $0F, $0D
	NOTE D_, 4
	RELEASE 3, $0F
	NOTE B_, 3
	NOTE G_, 1
	RELEASE $0F, $0D
	NOTE D_, 4
	RELEASE 3, $0F
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd5F_Drm_7057:
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 4
	LEN_UNIT $01
	DRUM 8, 7
	DRUM 8, 6
	DRUM 8, 7
	LEN_UNIT $05
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_RET
Snd5F_Drm_7069:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	REST 8
	REST 8
	SND_REPEAT 2
	SND_RET
Snd5F_Drm_7077:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 6
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 6
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_RET
Snd5F_Drm_708B:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 6
	DRUM $0B, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_RET
Snd5F_Drm_709E:
	SND_SEGNO
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	REST 6
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_REPEAT 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_RET
Snd5F_Drm_70BA:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 8
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 2
	DRUM $0B, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 2
	SND_REPEAT 2
	SND_RET
Snd5F_Drm_70CC:
	SND_SEGNO
	DRUM $0C, 2
	DRUM 8, 2
	SND_REPEAT 8
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 4
	DRUM 8, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_RET

Snd61_Ch2:
	TEMPO $00
	VOICE $06, 9, 8, 2, 14
	SND_CALL Snd61_Ch2_711C
Snd61_Ch2_70E8:
	SND_CALL Snd61_Ch2_7138
	SND_CALL Snd61_Ch2_716A
	SND_CALL Snd61_Ch2_7194
	SND_CALL Snd61_Ch2_70E8

Snd61_Ch1:
	DUTY_STEP 0, 2
	VOICE $06, 7, 4, 2, 14
	SND_CALL Snd61_Ch1_71D2
Snd61_Ch1_70FD:
	SND_CALL Snd61_Ch1_71EE
	SND_CALL Snd61_Ch1_7229
	SND_CALL Snd61_Ch1_7254
	SND_CALL Snd61_Ch1_70FD

Snd61_Ch3:
	VOICE $06, 2, 6, 4, 15
	SND_CALL Snd61_Ch3_7290
Snd61_Ch3_7110:
	SND_CALL Snd61_Ch3_72A4
	SND_CALL Snd61_Ch3_72F1
	SND_CALL Snd61_Ch3_7330
	SND_CALL Snd61_Ch3_7110
Snd61_Ch2_711C:
	PAN $F0
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $FF
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $0F
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	PAN $FF
	SND_RET
Snd61_Ch2_7138:
	VIBRATO 9
	DUTY 4
	DUTY_STEP 8, 2
	RELEASE 3, $0E
	SND_SEGNO
	OCTAVE 1
	NOTE G_, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT $0C
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE G_, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE A_, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE A#, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE A#, 2
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE B_, 2
	RELEASE 2, $0E
	OCTAVE 2
	NOTE B_, 2
	SND_RET
Snd61_Ch2_716A:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0E
	OCTAVE 3
	NOTE C_, 2
	SND_REPEAT $0C
	RELEASE $0B, $0D
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE A_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0B, $0D
	OCTAVE 1
	NOTE A#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	RELEASE $0B, $0D
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE C_, 2
	SND_RET
Snd61_Ch2_7194:
	DUTY_STEP_OFF
	RELEASE 4, $0C
	OCTAVE 1
	NOTE D_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE D_, 2
	RELEASE 4, $0C
	OCTAVE 1
	NOTE C#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE C#, 2
	RELEASE 4, $0C
	OCTAVE 1
	NOTE D_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE D_, 2
	RELEASE 4, $0C
	OCTAVE 1
	NOTE D#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE D#, 2
	SND_SEGNO
	RELEASE 3, $0F
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	SND_REPEAT 2
	SND_SEGNO
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	SND_REPEAT 4
	SND_RET
Snd61_Ch1_71D2:
	PAN $F0
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $FF
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $0F
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	PAN $FF
	SND_RET
Snd61_Ch1_71EE:
	VIBRATO 4
	DUTY_STEP_OFF
	DUTY 0
	LEN_UNIT $01
	REST 1
	LEN_UNIT $06
	SND_SEGNO
	RELEASE 2, $0E
	OCTAVE 3
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	SND_REPEAT 3
	DUTY_STEP 8, 2
	PAN $0F
	RELEASE 1, $0F
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	PAN $FF
	DUTY_STEP_OFF
	SND_RET
Snd61_Ch1_7229:
	SND_SEGNO
	RELEASE 2, $0E
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_REPEAT 3
	DUTY_STEP 8, 2
	PAN $F0
	RELEASE 1, $0F
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	LEN_UNIT $01
	NOTE F#, 5
	PAN $FF
	SND_RET
Snd61_Ch1_7254:
	LEN_UNIT $06
	RELEASE $0D, 9
	ATTEN 1
	OCTAVE 3
	NOTE F#, 3
	REST 1
	NOTE G_, 3
	REST 1
	NOTE F#, 3
	REST 1
	NOTE G_, 3
	REST 1
	PAN $F0
	RELEASE 2, $0F
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	PAN $0F
	OCTAVE 4
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	PAN $FF
	RELEASE 9, 5
	ATTEN 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	RELEASE 4, $0C
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 5
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	NOTE D_, 1
	SND_RET
Snd61_Ch3_7290:
	OCTAVE 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	SND_RET
Snd61_Ch3_72A4:
	VIBRATO 10
	WAVE 2
	SND_SEGNO
	RELEASE 4, $0C
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	SND_REPEAT 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	RELEASE $0F, $0F
	NOTE D_, 4
	WAVE 7
	PAN $F0
	RELEASE 3, $0D
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	PAN $FF
	SND_RET
Snd61_Ch3_72F1:
	WAVE 2
	SND_SEGNO
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_REPEAT 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE $0F, $0A
	NOTE G_, 4
	PAN $0F
	WAVE 7
	RELEASE 3, $0D
	OCTAVE 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	PAN $FF
	SND_RET
Snd61_Ch3_7330:
	WAVE 2
	RELEASE 6, $0A
	OCTAVE 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE D#, 4
	SND_SEGNO
	RELEASE 2, $0D
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 4
	SND_REPEAT 3
	NOTE D_, 2
	NOTE D#, 2
	PAN $F0
	RELEASE 4, $0C
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $FF
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	PAN $F0
	PAN $0F
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	PAN $FF
	SND_RET

Snd61_Drm:
	DRUM_UNIT $02
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 8, 6
	LEN_UNIT $06
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
Snd61_Drm_7374:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $0C
	REST 2
	DRUM 2, 1
	DRUM 2, 1
	REST 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_REPEAT $0F
	LEN_UNIT $02
	DRUM 2, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 8, 3
	DRUM 8, 3
	LEN_UNIT $06
	DRUM $0B, 4
	DRUM 8, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 4
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_CALL Snd61_Drm_7374

Snd60_Ch2:
	VOICE $05, 9, 8, 2, 15
	SND_CALL Snd60_Ch2_73EE
Snd60_Ch2_73B7:
	SND_CALL Snd60_Ch2_745B
	SND_CALL Snd60_Ch2_74A7
	SND_CALL Snd60_Ch2_7531
	SND_CALL Snd60_Ch2_73B7

Snd60_Ch1:
	VIBRATO 4
	LEN_UNIT $01
	REST 1
	VOICE $05, 5, 4, 2, 15
	SND_CALL Snd60_Ch1_756C
Snd60_Ch1_73CF:
	SND_CALL Snd60_Ch1_7582
	SND_CALL Snd60_Ch1_75D5
	SND_CALL Snd60_Ch1_760E
	SND_CALL Snd60_Ch1_73CF

Snd60_Ch3:
	VOICE $05, 2, 8, 4, 12
	SND_CALL Snd60_Ch3_766B
Snd60_Ch3_73E2:
	SND_CALL Snd60_Ch3_7671
	SND_CALL Snd60_Ch3_76AB
	SND_CALL Snd60_Ch3_7734
	SND_CALL Snd60_Ch3_73E2
Snd60_Ch2_73EE:
	TEMPO $90
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	TEMPO $80
	PAN $F0
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $FF
	TEMPO $70
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	TEMPO $60
	PAN $0F
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $FF
	TEMPO $50
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	TEMPO $40
	PAN $F0
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $FF
	TEMPO $30
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	TEMPO $20
	PAN $0F
	OCTAVE 5
	NOTE C_, 2
	TEMPO $15
	OCTAVE 3
	NOTE B_, 2
	TEMPO $10
	RELEASE 2, $0F
	PAN $0F
	OCTAVE 4
	NOTE C_, 2
	TEMPO $00
	RELEASE 1, $0E
	OCTAVE 3
	NOTE B_, 2
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 4
	NOTE C_, 2
	RELEASE 1, $0E
	OCTAVE 3
	NOTE B_, 2
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 4
	NOTE C_, 2
	RELEASE 1, $0E
	OCTAVE 3
	NOTE B_, 2
	PAN $FF
	RELEASE 2, $0F
	OCTAVE 4
	NOTE C_, 2
	RELEASE 1, $0F
	NOTE C_, 1
	NOTE D_, 1
	SND_RET
Snd60_Ch2_745B:
	VIBRATO 10
	DUTY_STEP 4, 2
	VOICE $05, 9, 8, 2, 15
	ATTEN 1
	OCTAVE 4
	NOTE D#, 2
	RELEASE 1, $0F
	NOTE D#, 1
	NOTE D#, 1
	RELEASE 1, $0E
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 2, $0F
	OCTAVE 4
	NOTE F_, 2
	RELEASE 1, $0F
	NOTE F_, 1
	NOTE F_, 1
	RELEASE 1, $0E
	NOTE E_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 4
	RELEASE 2, $0F
	OCTAVE 3
	NOTE D#, 2
	RELEASE 1, $0F
	NOTE D#, 1
	NOTE D#, 1
	RELEASE 1, $0E
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE F_, 2
	RELEASE 1, $0F
	NOTE F_, 1
	NOTE F_, 1
	RELEASE 1, $0E
	NOTE E_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 4
	RELEASE 1, $0F
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 2
	ATTEN 0
	SND_RET
Snd60_Ch2_74A7:
	VIBRATO 0
	DUTY_STEP 0, 3
	SND_SEGNO
	RELEASE 4, $0F
	OCTAVE 1
	NOTE A#, 2
	PAN $0F
	ATTEN 0
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE A#, 2
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	SND_REPEAT 4
	RELEASE 4, $0F
	OCTAVE 1
	NOTE F_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE F_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G#, 2
	RELEASE 4, $0F
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE C_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE A#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G#, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE F_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE F_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE D#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE D#, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE F_, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE F_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G#, 2
	RELEASE 4, $0F
	NOTE D_, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE D_, 2
	RELEASE 4, $0F
	OCTAVE 2
	NOTE C_, 2
	RELEASE 2, $0F
	OCTAVE 3
	NOTE C_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G_, 2
	SND_RET
Snd60_Ch2_7531:
	VIBRATO 9
	SND_SEGNO
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G#, 2
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE G#, 2
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 2
	NOTE G#, 2
	PAN $FF
	SND_REPEAT 2
	SND_SEGNO
	RELEASE 4, $0F
	OCTAVE 1
	NOTE A#, 2
	PAN $0F
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	RELEASE 4, $0F
	OCTAVE 1
	NOTE A#, 2
	PAN $F0
	RELEASE 2, $0F
	OCTAVE 2
	NOTE A#, 2
	PAN $FF
	SND_REPEAT 2
	DUTY_STEP_OFF
	SND_RET
Snd60_Ch1_756C:
	SND_SEGNO
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	SND_REPEAT 5
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 1
	LEN_UNIT $01
	NOTE D_, 4
	SND_RET
Snd60_Ch1_7582:
	VIBRATO 4
	LEN_UNIT $01
	REST 2
	VOICE $05, 5, 0, 3, 15
	ATTEN 4
	OCTAVE 4
	NOTE D#, 2
	RELEASE 1, $0D
	NOTE D#, 1
	NOTE D#, 1
	RELEASE 2, $0E
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 3, $0F
	OCTAVE 4
	NOTE F_, 2
	RELEASE 1, $0D
	NOTE F_, 1
	NOTE F_, 1
	RELEASE 2, $0E
	NOTE E_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 4
	RELEASE 3, $0F
	OCTAVE 3
	NOTE D#, 2
	RELEASE 1, $0D
	NOTE D#, 1
	NOTE D#, 1
	RELEASE 2, $0E
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	RELEASE 3, $0F
	OCTAVE 3
	NOTE F_, 2
	RELEASE 1, $0D
	NOTE F_, 1
	NOTE F_, 1
	RELEASE 2, $0E
	NOTE E_, 2
	NOTE C_, 2
	RELEASE 1, $0A
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 4
	NOTE A#, 2
	LEN_UNIT $02
	OCTAVE 5
	NOTE A#, 4
	ATTEN 0
	SND_RET
Snd60_Ch1_75D5:
	LEN_UNIT $01
	REST 2
	SND_SEGNO
	VOICE $05, 5, 4, 2, 15
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE C_, 1
	RELEASE 1, $0E
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	SND_REPEAT 3
	RELEASE 2, $0A
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 4
	RELEASE 2, $0D
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	RELEASE 3, $0D
	OCTAVE 5
	NOTE C_, 4
	LEN_UNIT $03
	OCTAVE 4
	NOTE A#, 6
	SND_RET
Snd60_Ch1_760E:
	VIBRATO 4
	LEN_UNIT $01
	REST 2
	LEN_UNIT $05
	OCTAVE 4
	RELEASE 2, $0F
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	LEN_UNIT $01
	NOTE A#, 3
	LEN_UNIT $05
	ATTEN 4
	OCTAVE 3
	RELEASE 3, $0F
	NOTE G#, 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	DUTY 8
	PAN $0F
	ATTEN 0
	RELEASE 2, $0F
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 2
	NOTE C_, 2
	PAN $FF
	DUTY 4
	ATTEN 4
	RELEASE 3, $0F
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE $0D, $0E
	ATTEN 1
	PAN $F0
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	PAN $FF
	ATTEN 3
	NOTE D_, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	PAN $0F
	NOTE G#, 1
	NOTE A#, 1
	PAN $FF
	SND_RET
Snd60_Ch3_766B:
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 4
	SND_REPEAT $0C
	SND_RET
Snd60_Ch3_7671:
	VOICE $05, 2, 8, 5, 13
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 4, $0F
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 3, $0A
	NOTE A#, 4
	REST 4
	SND_RET
Snd60_Ch3_76AB:
	VIBRATO 10
	VOICE $05, 2, 2, 3, 12
	SND_SEGNO
	RELEASE 4, $0C
	OCTAVE 4
	NOTE D_, 3
	RELEASE 2, $0C
	NOTE D#, 1
	NOTE D_, 2
	NOTE C_, 2
	SND_REPEAT 3
	PAN $F0
	RELEASE 3, $0D
	NOTE D_, 1
	NOTE D#, 1
	PAN $FF
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	PAN $0F
	NOTE G#, 1
	NOTE A#, 1
	RELEASE 3, $0A
	OCTAVE 5
	NOTE C_, 2
	RELEASE 2, $0C
	OCTAVE 4
	NOTE A#, 2
	PAN $FF
	RELEASE 3, $0A
	NOTE A#, 2
	RELEASE 2, $0C
	NOTE G#, 2
	RELEASE 3, $0A
	NOTE G#, 2
	RELEASE 2, $0C
	NOTE G_, 2
	RELEASE 3, $0A
	NOTE G_, 2
	RELEASE 2, $0C
	NOTE F_, 2
	RELEASE 3, $0A
	NOTE F_, 2
	RELEASE 2, $0C
	NOTE D#, 2
	PAN $F0
	RELEASE 3, $0A
	NOTE D#, 2
	RELEASE 2, $0C
	NOTE D_, 2
	PAN $FF
	RELEASE 3, $0D
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	PAN $0F
	RELEASE 3, $0A
	OCTAVE 4
	NOTE F_, 2
	PAN $FF
	RELEASE 2, $0C
	NOTE D#, 2
	RELEASE 3, $0A
	NOTE D#, 2
	RELEASE 2, $0C
	NOTE D_, 2
	RELEASE 3, $0A
	NOTE D_, 2
	PAN $F0
	RELEASE 2, $0C
	NOTE C_, 2
	PAN $0F
	RELEASE 3, $0A
	NOTE F_, 2
	PAN $FF
	RELEASE 2, $0C
	NOTE D#, 2
	RELEASE 3, $0A
	NOTE D#, 2
	RELEASE 2, $0C
	NOTE D_, 2
	RELEASE 3, $0A
	NOTE C_, 2
	PAN $F0
	RELEASE 2, $0C
	OCTAVE 3
	NOTE A#, 2
	PAN $FF
	SND_RET
Snd60_Ch3_7734:
	VOICE $05, 2, 15, 1, 14
	RELEASE 4, $0D
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G#, 2
	PAN $0F
	WAVE $0D
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G#, 2
	PAN $FF
	WAVE $0F
	OCTAVE 4
	NOTE A#, 2
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 2
	OCTAVE 4
	NOTE A#, 2
	PAN $F0
	WAVE $0D
	RELEASE $0F, $0F
	OCTAVE 1
	NOTE D_, 1
	NOTE D#, 1
	PAN $FF
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 0
	NOTE G#, 1
	NOTE A#, 1
	PAN $0F
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	PAN $FF
	SND_RET

Snd60_Drm:
	DRUM_UNIT $05
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 2
	SND_REPEAT $0B
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
Snd60_Drm_777C:
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 3
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 8, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM $0B, 4
	DRUM $0B, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 7
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 6
	DRUM 8, 4
	DRUM 8, 4
	SND_SEGNO
	DRUM $0B, 2
	DRUM 8, 2
	SND_REPEAT 4
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_SEGNO
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 2
	DRUM $0B, 2
	SND_REPEAT 3
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 8, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_CALL Snd60_Drm_777C

Snd67_Ch2:
	TEMPO $32
	VIBRATO 10
	VOICE $04, 8, 8, 6, 14
	SND_CALL Snd67_Ch2_781F
Snd67_Ch2_77CD:
	SND_CALL Snd67_Ch2_793F
	SND_CALL Snd67_Ch2_79AF
	SND_CALL Snd67_Ch2_79AF
	SND_CALL Snd67_Ch2_77CD

Snd67_Ch1:
	VIBRATO 4
	LEN_UNIT $01
	REST 1
	VOICE $04, 6, 0, 3, 12
	SND_CALL Snd67_Ch1_7855
	NOTE B_, 2
	SND_CALL Snd67_Ch1_7855
	LEN_UNIT $01
	NOTE B_, 7
Snd67_Ch1_77EC:
	SND_CALL Snd67_Ch1_79FA
	SND_CALL Snd67_Ch1_7A5D
	SND_CALL Snd67_Ch1_7A65
	SND_CALL Snd67_Ch1_7A88
	SND_CALL Snd67_Ch1_7A65
	SND_CALL Snd67_Ch1_7A8E
	SND_CALL Snd67_Ch1_77EC

Snd67_Ch3:
	VOICE $04, 2, 7, 2, 11
	SND_CALL Snd67_Ch3_7869
Snd67_Ch3_7808:
	SND_CALL Snd67_Ch3_7ADA
	SND_CALL Snd67_Ch3_7B1A
	SND_CALL Snd67_Ch3_7808

Snd67_Drm:
	DRUM_UNIT $04
	SND_CALL Snd67_Drm_7880
Snd67_Drm_7816:
	SND_CALL Snd67_Drm_7B65
	SND_CALL Snd67_Drm_7B80
	SND_CALL Snd67_Drm_7816
Snd67_Ch2_781F:
	ATTEN 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 1
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 0
	SND_RET
Snd67_Ch1_7855:
	ATTEN 5
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 4
	RELEASE 4, $0E
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	RELEASE 3, $0C
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	SND_RET
Snd67_Ch3_7869:
	SND_SEGNO
	OCTAVE 4
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	RELEASE 4, $0B
	NOTE B_, 4
	OCTAVE 5
	NOTE E_, 4
	OCTAVE 4
	NOTE B_, 4
	NOTE A_, 4
	RELEASE 2, $0B
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_REPEAT 2
	SND_RET
Snd67_Drm_7880:
	SND_SEGNO
	DRUM $0C, 4
	DRUM 8, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 2
	DRUM 2, 2
	DRUM $0C, 2
	DRUM 2, 2
	SND_REPEAT 3
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET

Snd68_Ch2:
	TEMPO $32
	VIBRATO 10
	VOICE $04, 8, 4, 1, 13
	DUTY_STEP 8, 1
	SND_CALL Snd68_Ch2_78F4
Snd68_Ch2_78A7:
	SND_CALL Snd67_Ch2_793F
	SND_CALL Snd67_Ch2_79AF
	SND_CALL Snd67_Ch2_79AF
	SND_CALL Snd68_Ch2_78A7

Snd68_Ch1:
	VIBRATO 4
	LEN_UNIT $01
	REST 2
	VOICE $04, 8, 0, 3, 15
	SND_CALL Snd68_Ch1_79C7
Snd68_Ch1_78BF:
	SND_CALL Snd67_Ch1_79FA
	SND_CALL Snd67_Ch1_7A5D
	SND_CALL Snd67_Ch1_7A65
	SND_CALL Snd67_Ch1_7A88
	SND_CALL Snd67_Ch1_7A65
	SND_CALL Snd67_Ch1_7A8E
	SND_CALL Snd68_Ch1_78BF

Snd68_Ch3:
	TRANSPOSE_UP $0C
	VOICE $04, 2, 7, 2, 15
	SND_CALL Snd68_Ch3_7A93
Snd68_Ch3_78DD:
	SND_CALL Snd67_Ch3_7ADA
	SND_CALL Snd67_Ch3_7B1A
	SND_CALL Snd68_Ch3_78DD

Snd68_Drm:
	DRUM_UNIT $04
	SND_CALL Snd68_Drm_7B52
Snd68_Drm_78EB:
	SND_CALL Snd67_Drm_7B65
	SND_CALL Snd67_Drm_7B80
	SND_CALL Snd68_Drm_78EB
Snd68_Ch2_78F4:
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	DUTY_STEP_OFF
	SND_RET
Snd67_Ch2_793F:
	DUTY 4
	ATTEN 1
	RELEASE 4, $0B
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 4, $0A
	OCTAVE 3
	NOTE A_, 2
	PAN $0F
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 4, $0A
	OCTAVE 3
	NOTE A_, 2
	PAN $F0
	ATTEN 5
	RELEASE 4, $0B
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 3, $0D
	OCTAVE 3
	NOTE A_, 4
	PAN $FF
	ATTEN 0
	RELEASE 4, $0B
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 4, $0A
	OCTAVE 3
	NOTE B_, 2
	PAN $0F
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 4, $0A
	OCTAVE 3
	NOTE B_, 2
	PAN $F0
	RELEASE 4, $0B
	ATTEN 5
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 3, $0D
	OCTAVE 3
	NOTE B_, 4
	PAN $FF
	ATTEN 0
	RELEASE 4, $0B
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	DUTY 8
	DUTY_STEP 4, 2
	RELEASE 2, $0E
	NOTE C#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE G#, 2
	RELEASE 3, $0C
	NOTE D_, 4
	RELEASE 2, $0E
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	SND_RET
Snd67_Ch2_79AF:
	LEN_UNIT $01
	RELEASE 5, $0E
	OCTAVE 1
	NOTE D#, 4
	LEN_UNIT $04
	NOTE E_, 5
	NOTE E_, 6
	NOTE E_, 6
	RELEASE 2, $0E
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 4, $0D
	SND_RET
Snd68_Ch1_79C7:
	DUTY_STEP 4, 2
	ATTEN 4
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 6
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 4
	RELEASE 3, $0C
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 3, $0F
	NOTE C#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	LEN_UNIT $02
	NOTE A_, 3
	LEN_UNIT $04
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	SND_RET
Snd67_Ch1_79FA:
	VOICE $04, 8, 8, 2, 12
	ATTEN 3
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	PAN $0F
	ATTEN 5
	RELEASE 7, $0A
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	PAN $F0
	ATTEN 6
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 6
	PAN $FF
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	ATTEN 3
	RELEASE 2, $0C
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	PAN $0F
	ATTEN 5
	RELEASE 7, $0A
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	PAN $F0
	ATTEN 6
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	PAN $FF
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	ATTEN 3
	RELEASE 3, $0E
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	SND_RET
Snd67_Ch1_7A5D:
	LEN_UNIT $01
	REST 2
	VOICE $04, 8, 4, 3, 12
	SND_RET
Snd67_Ch1_7A65:
	ATTEN 4
	OCTAVE 3
	NOTE E_, 4
	RELEASE 4, $0E
	OCTAVE 4
	NOTE E_, 2
	RELEASE 3, $0C
	OCTAVE 3
	NOTE E_, 4
	RELEASE 4, $0E
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 3, $0C
	OCTAVE 3
	NOTE E_, 4
	RELEASE 4, $0E
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	DUTY_STEP 0, 2
	RELEASE 4, $0A
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	SND_RET
Snd67_Ch1_7A88:
	NOTE B_, 2
	RELEASE 3, $0C
	DUTY_STEP_OFF
	SND_RET
Snd67_Ch1_7A8E:
	LEN_UNIT $02
	NOTE B_, 3
	ATTEN 0
	SND_RET
Snd68_Ch3_7A93:
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 7, $0C
	NOTE A_, 4
	RELEASE 2, $0F
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE 6, $0B
	NOTE E_, 6
	RELEASE 4, $0D
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 4
	RELEASE 6, $0A
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	RELEASE 2, $0F
	NOTE C#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 1
	RELEASE 7, $0C
	NOTE A_, 4
	RELEASE 2, $0F
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE 6, $0A
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	RELEASE 5, $0D
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	SND_RET
Snd67_Ch3_7ADA:
	SND_SEGNO
	TRANSPOSE_UP 0
	WAVE 8
	RELEASE 6, $0B
	OCTAVE 1
	NOTE A_, 2
	RELEASE 3, $0D
	OCTAVE 2
	NOTE A_, 2
	SND_REPEAT 8
	SND_SEGNO
	RELEASE 6, $0B
	OCTAVE 1
	NOTE G_, 2
	RELEASE 3, $0D
	OCTAVE 2
	NOTE G_, 2
	SND_REPEAT 6
	RELEASE 4, $0A
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 1
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	RELEASE 7, $0A
	NOTE D_, 4
	RELEASE 4, $0A
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE D_, 2
	SND_RET
Snd67_Ch3_7B1A:
	VOICE $04, 2, 2, 6, 13
	SND_SEGNO
	RELEASE 6, $0D
	OCTAVE 3
	NOTE E_, 4
	RELEASE 2, $0A
	LEN_UNIT $01
	OCTAVE 4
	NOTE D#, 2
	LEN_UNIT $02
	NOTE E_, 3
	LEN_UNIT $04
	RELEASE 6, $0D
	OCTAVE 3
	NOTE E_, 4
	RELEASE 2, $0A
	NOTE E_, 2
	LEN_UNIT $01
	OCTAVE 4
	NOTE C#, 2
	LEN_UNIT $02
	NOTE D_, 3
	LEN_UNIT $04
	RELEASE 6, $0D
	OCTAVE 3
	NOTE E_, 4
	RELEASE 2, $0A
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	RELEASE 2, $0B
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	SND_REPEAT 2
	SND_RET
Snd68_Drm_7B52:
	SND_SEGNO
	DRUM $0C, 2
	DRUM 2, 2
	SND_REPEAT $0C
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 2
	SND_RET
Snd67_Drm_7B65:
	DRUM_UNIT $04
	SND_SEGNO
	DRUM $0C, 4
	DRUM 8, 4
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 8, 4
	DRUM $0C, 4
	DRUM 8, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 2, 2
	SND_REPEAT 2
	SND_SEGNO
	DRUM $0C, 4
	DRUM 8, 2
	DRUM $0C, 4
	DRUM 8, 2
	DRUM $0C, 2
	DRUM 8, 1
	DRUM 2, 1
	SND_REPEAT 2
	SND_RET
Snd67_Drm_7B80:
	DRUM_UNIT $04
	DRUM $0C, 4
	DRUM 8, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM 8, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM 8, 2
	DRUM $0C, 4
	DRUM 8, 2
	DRUM 8, 2
	REST 2
	DRUM $0C, 4
	DRUM 8, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM 8, 2
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM 8, 2
	DRUM $0C, 2
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_RET

Snd69_Ch2:
	TEMPO $38
	VOICE $04, 8, 0, 7, 15
	SND_CALL Snd69_Ch2_7BE2
Snd69_Ch2_7BA9:
	SND_CALL Snd69_Ch2_7C28
	SND_CALL Snd69_Ch2_7CAA
	SND_CALL Snd69_Ch2_7BA9

Snd69_Ch1:
	VIBRATO 1
	VOICE $04, 6, 4, 7, 14
	SND_CALL Snd69_Ch1_7CD9
Snd69_Ch1_7BBB:
	SND_CALL Snd69_Ch1_7D09
	SND_CALL Snd69_Ch1_7D8A
	SND_CALL Snd69_Ch1_7BBB

Snd69_Ch3:
	VOICE $04, 2, 8, 15, 15
	SND_CALL Snd69_Ch3_7DF5
Snd69_Ch3_7BCB:
	SND_CALL Snd69_Ch3_7E10
	SND_CALL Snd69_Ch3_7E5F
	SND_CALL Snd69_Ch3_7BCB

Snd69_Drm:
	DRUM_UNIT $04
	SND_CALL Snd69_Drm_7E9A
Snd69_Drm_7BD9:
	SND_CALL Snd69_Drm_7EB0
	SND_CALL Snd69_Drm_7EBE
	SND_CALL Snd69_Drm_7BD9
Snd69_Ch2_7BE2:
	VIBRATO 7
	OCTAVE 4
	NOTE D#, 4
	VIBRATO 0
	RELEASE 2, $0F
	NOTE F#, 4
	VIBRATO 7
	RELEASE 7, $0F
	NOTE C#, 4
	VIBRATO 0
	RELEASE 2, $0F
	NOTE E_, 4
	VIBRATO 7
	RELEASE 7, $0F
	OCTAVE 3
	NOTE B_, 4
	VIBRATO 0
	RELEASE 2, $0F
	OCTAVE 4
	NOTE D_, 4
	VIBRATO 7
	RELEASE 7, $0F
	OCTAVE 3
	NOTE A_, 4
	VIBRATO 0
	RELEASE 2, $0F
	OCTAVE 4
	NOTE D_, 4
	RELEASE 0, 8
	OCTAVE 3
	NOTE B_, $0C
	LEN_UNIT $01
	NOTE B_, $0B
	OCTAVE 4
	NOTE C#, 5
	LEN_UNIT $04
	NOTE D_, 8
	LEN_UNIT $01
	DUTY 8
	RELEASE $0F, $0F
	OCTAVE 2
	NOTE B_, 5
	OCTAVE 3
	NOTE C#, 6
	NOTE D_, 5
	NOTE E_, 5
	NOTE F#, 6
	NOTE G#, 5
	SND_RET
Snd69_Ch2_7C28:
	SND_SEGNO
	VIBRATO 4
	VOICE $04, 8, 8, 7, 8
	OCTAVE 3
	NOTE A_, $0C
	LEN_UNIT $01
	RELEASE 6, $0F
	NOTE E_, 5
	NOTE A_, 6
	OCTAVE 4
	NOTE C#, 5
	LEN_UNIT $04
	RELEASE 2, $0E
	NOTE D_, 4
	RELEASE 3, $0F
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	LEN_UNIT $01
	RELEASE 6, $0F
	OCTAVE 4
	NOTE C#, $0B
	OCTAVE 3
	NOTE B_, 5
	LEN_UNIT $04
	RELEASE 3, $0F
	NOTE B_, 4
	PAN $0F
	NOTE B_, 4
	PAN $FF
	NOTE A_, 4
	PAN $F0
	NOTE A_, 4
	PAN $FF
	NOTE G_, 4
	PAN $0F
	NOTE G_, 4
	PAN $FF
	OCTAVE 4
	NOTE D_, 4
	PAN $F0
	NOTE D_, 4
	PAN $FF
	RELEASE 7, 8
	NOTE C#, $0C
	LEN_UNIT $01
	RELEASE 6, $0F
	OCTAVE 3
	NOTE A_, 5
	OCTAVE 4
	NOTE C#, 6
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 3, $0F
	NOTE G_, 4
	RELEASE 3, $0F
	NOTE F#, 4
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE 6, $0F
	NOTE F#, $0B
	RELEASE 7, 5
	NOTE E_, 5
	LEN_UNIT $04
	NOTE E_, 4
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE 3, $0E
	NOTE E_, $0B
	NOTE E_, 5
	NOTE F#, $0B
	RELEASE $0F, 1
	NOTE G_, 5
	LEN_UNIT $04
	RELEASE $0F, 7
	NOTE G_, 8
	LEN_UNIT $01
	PAN $0F
	RELEASE 3, $0C
	OCTAVE 3
	NOTE G_, 5
	NOTE F#, 6
	NOTE F_, 5
	PAN $F0
	NOTE E_, 5
	NOTE D#, 6
	NOTE D_, 5
	PAN $FF
	SND_RET
Snd69_Ch2_7CAA:
	SND_SEGNO
	OCTAVE 1
	NOTE E_, $0B
	OCTAVE 2
	NOTE E_, 5
	SND_REPEAT 4
	OCTAVE 1
	NOTE E_, $0B
	OCTAVE 2
	NOTE E_, 5
	OCTAVE 1
	NOTE F_, $0B
	OCTAVE 2
	NOTE F_, 5
	OCTAVE 1
	NOTE F#, $0B
	OCTAVE 2
	NOTE F#, 5
	OCTAVE 1
	NOTE F_, $0B
	OCTAVE 2
	NOTE F_, 5
	SND_SEGNO
	OCTAVE 1
	NOTE E_, $0B
	OCTAVE 2
	NOTE E_, 5
	SND_REPEAT 4
	OCTAVE 1
	NOTE E_, $0B
	OCTAVE 2
	NOTE E_, 5
	OCTAVE 1
	NOTE F#, $0B
	OCTAVE 2
	NOTE F#, 5
	OCTAVE 1
	NOTE G_, $0B
	OCTAVE 2
	NOTE G_, 5
	OCTAVE 1
	NOTE G#, $0B
	OCTAVE 2
	NOTE G#, 5
	SND_RET
Snd69_Ch1_7CD9:
	OCTAVE 3
	NOTE B_, 4
	RELEASE 3, $0E
	OCTAVE 4
	NOTE D#, 4
	RELEASE 7, $0E
	OCTAVE 3
	NOTE A_, 4
	RELEASE 3, $0E
	OCTAVE 4
	NOTE C#, 4
	RELEASE 7, $0E
	OCTAVE 3
	NOTE G_, 4
	RELEASE 3, $0E
	NOTE B_, 4
	RELEASE 7, $0E
	NOTE F_, 4
	RELEASE 3, $0E
	NOTE A_, 4
	RELEASE 0, 6
	NOTE G#, $0C
	LEN_UNIT $01
	NOTE G#, $0A
	NOTE A_, 6
	LEN_UNIT $04
	NOTE B_, 8
	LEN_UNIT $01
	RELEASE $0F, $0F
	NOTE D#, 5
	NOTE E_, 6
	NOTE F#, 5
	NOTE G#, 5
	NOTE A_, 6
	NOTE B_, 5
	SND_RET
Snd69_Ch1_7D09:
	VIBRATO 0
	VOICE $04, 6, 4, 7, 8
	OCTAVE 3
	NOTE A_, $0C
	LEN_UNIT $01
	RELEASE 6, $0E
	NOTE E_, 5
	NOTE A_, 6
	OCTAVE 4
	NOTE C#, 5
	LEN_UNIT $04
	RELEASE 3, $0E
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	LEN_UNIT $01
	RELEASE 6, $0E
	OCTAVE 4
	NOTE C#, $0B
	OCTAVE 3
	NOTE B_, 5
	LEN_UNIT $04
	RELEASE 3, $0E
	NOTE B_, 4
	PAN $0F
	NOTE B_, 4
	PAN $FF
	NOTE A_, 4
	PAN $F0
	NOTE A_, 4
	PAN $FF
	NOTE G_, 4
	PAN $0F
	NOTE G_, 4
	PAN $FF
	OCTAVE 4
	NOTE D_, 4
	PAN $F0
	NOTE D_, 4
	PAN $FF
	RELEASE 7, 8
	NOTE C#, $0C
	LEN_UNIT $01
	RELEASE 6, $0E
	OCTAVE 3
	NOTE A_, 5
	OCTAVE 4
	NOTE C#, 6
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 3, $0E
	NOTE G_, 4
	RELEASE 3, $0F
	NOTE F#, 4
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE 6, $0E
	NOTE F#, $0B
	RELEASE 7, 5
	NOTE E_, 5
	LEN_UNIT $04
	NOTE E_, 4
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE 3, $0E
	NOTE E_, $0B
	NOTE E_, 5
	NOTE F#, $0B
	RELEASE $0F, 2
	NOTE G_, 5
	LEN_UNIT $04
	RELEASE $0F, 6
	NOTE G_, 8
	LEN_UNIT $01
	PAN $0F
	RELEASE 7, $0A
	ATTEN 0
	OCTAVE 4
	NOTE D_, 5
	NOTE C#, 6
	NOTE C_, 5
	PAN $F0
	OCTAVE 3
	NOTE B_, 5
	NOTE A#, 6
	NOTE A_, 5
	PAN $FF
	SND_RET
Snd69_Ch1_7D8A:
	RELEASE 5, $0E
	OCTAVE 3
	NOTE B_, $0A
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, $0A
	NOTE A_, 6
	NOTE B_, $0A
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, $0A
	NOTE A_, 6
	OCTAVE 2
	NOTE B_, $0A
	VIBRATO 7
	OCTAVE 3
	NOTE B_, 6
	VIBRATO 13
	PAN $0F
	AUTOPAN 2
	NOTE C_, $0A
	VIBRATO 7
	OCTAVE 4
	NOTE C_, 6
	VIBRATO 13
	OCTAVE 3
	NOTE C#, $0A
	VIBRATO 7
	OCTAVE 4
	NOTE C#, 6
	VIBRATO 13
	OCTAVE 3
	NOTE C_, $0A
	VIBRATO 7
	OCTAVE 4
	NOTE C_, 6
	VIBRATO 13
	AUTOPAN 0
	PAN $FF
	OCTAVE 3
	NOTE B_, $0A
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, $0A
	NOTE A_, 6
	NOTE B_, $0A
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	NOTE B_, $0A
	NOTE A_, 6
	OCTAVE 2
	NOTE B_, $0A
	PAN $0F
	AUTOPAN 2
	VIBRATO 7
	OCTAVE 3
	NOTE B_, 6
	VIBRATO 13
	NOTE C_, $0A
	VIBRATO 7
	OCTAVE 4
	NOTE C_, 6
	VIBRATO 13
	OCTAVE 3
	NOTE D_, $0A
	VIBRATO 7
	OCTAVE 4
	NOTE D_, 6
	VIBRATO 13
	OCTAVE 3
	NOTE D#, $0A
	OCTAVE 4
	NOTE D#, 6
	AUTOPAN 0
	PAN $FF
	SND_RET
Snd69_Ch3_7DF5:
	OCTAVE 1
	NOTE B_, 8
	NOTE A_, 8
	NOTE G_, 8
	NOTE F_, 8
	RELEASE 4, 7
	OCTAVE 2
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE $0F, $0F
	OCTAVE 1
	NOTE B_, 5
	OCTAVE 2
	NOTE C#, 6
	NOTE D_, 5
	NOTE E_, 5
	NOTE F#, 6
	NOTE G#, 5
	SND_RET
Snd69_Ch3_7E10:
	SND_SEGNO
	RELEASE 5, $0A
	OCTAVE 1
	NOTE A_, $0B
	NOTE A_, 5
	NOTE A_, 5
	OCTAVE 2
	NOTE E_, 6
	NOTE A_, 5
	SND_REPEAT 3
	OCTAVE 1
	NOTE A_, $0B
	NOTE A_, 5
	NOTE A_, 5
	OCTAVE 2
	NOTE E_, 6
	OCTAVE 1
	NOTE G_, $0F
	NOTE G_, 6
	NOTE G_, 5
	OCTAVE 2
	NOTE D_, 6
	NOTE G_, 5
	SND_SEGNO
	OCTAVE 1
	NOTE G_, $0B
	NOTE G_, 5
	NOTE G_, 5
	OCTAVE 2
	NOTE D_, 6
	NOTE G_, 5
	SND_REPEAT 3
	SND_SEGNO
	OCTAVE 1
	NOTE A_, $0B
	NOTE A_, 5
	NOTE A_, 5
	OCTAVE 2
	NOTE E_, 6
	NOTE A_, 5
	SND_REPEAT 3
	OCTAVE 1
	NOTE A_, $0B
	NOTE A_, 5
	NOTE A_, 5
	OCTAVE 2
	NOTE E_, 6
	OCTAVE 1
	NOTE E_, $0F
	NOTE E_, 6
	NOTE E_, 5
	NOTE B_, 6
	OCTAVE 2
	NOTE E_, 5
	OCTAVE 1
	NOTE E_, $0B
	NOTE E_, 5
	NOTE E_, 5
	NOTE B_, 6
	OCTAVE 2
	NOTE E_, 5
	OCTAVE 1
	NOTE G_, $0B
	NOTE G_, 5
	NOTE G_, 5
	OCTAVE 2
	NOTE D_, 6
	NOTE G_, 5
	NOTE G_, 5
	NOTE F#, 6
	NOTE F_, 5
	NOTE E_, 5
	NOTE D#, 6
	NOTE D_, 5
	SND_RET
Snd69_Ch3_7E5F:
	VOICE $01, 2, 2, 5, 15
	OCTAVE 4
	NOTE E_, $0A
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, $0A
	NOTE D_, 6
	NOTE E_, $0A
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, $0A
	NOTE D_, 6
	NOTE E_, $0A
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE F_, $0A
	OCTAVE 4
	NOTE F_, 6
	OCTAVE 3
	NOTE F#, $0A
	OCTAVE 4
	NOTE F#, 6
	OCTAVE 3
	NOTE F_, $0A
	OCTAVE 4
	NOTE F_, 6
	OCTAVE 4
	NOTE E_, $0A
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, $0A
	NOTE D_, 6
	NOTE E_, $0A
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, $0A
	NOTE D_, 6
	NOTE E_, $0A
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE F#, $0A
	OCTAVE 4
	NOTE F#, 6
	OCTAVE 3
	NOTE G_, $0A
	OCTAVE 4
	NOTE G_, 6
	OCTAVE 3
	NOTE G#, $0A
	OCTAVE 4
	NOTE G#, 6
	WAVE 8
	SND_RET
Snd69_Drm_7E9A:
	SND_SEGNO
	DRUM $0C, 4
	DRUM 8, 4
	DRUM $0C, 4
	DRUM 8, 4
	SND_REPEAT 2
	DRUM 8, 4
	DRUM 8, 4
	LEN_UNIT $01
	DRUM $0C, $0A
	DRUM 8, 6
	DRUM $0C, $0A
	DRUM 8, 6
	SND_SEGNO
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_REPEAT 4
	SND_RET
Snd69_Drm_7EB0:
	SND_SEGNO
	DRUM $0C, $0A
	DRUM $0C, 6
	DRUM 8, $0A
	DRUM $0C, 6
	SND_REPEAT $0F
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_RET
Snd69_Drm_7EBE:
	SND_SEGNO
	DRUM $0C, $0A
	DRUM 8, 6
	SND_REPEAT 6
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_SEGNO
	DRUM $0C, $0A
	DRUM 8, 6
	SND_REPEAT 4
	SND_SEGNO
	DRUM 8, 5
	DRUM 8, 6
	DRUM 8, 5
	SND_REPEAT 4
	SND_RET

Snd6A_Ch2:
	TEMPO $38
	VIBRATO 4
	VOICE $01, 8, 12, 7, 10
	SND_CALL Snd6A_Ch2_7F19
Snd6A_Ch2_7EE0:
	SND_CALL Snd69_Ch2_7C28
	SND_CALL Snd69_Ch2_7CAA
	SND_CALL Snd6A_Ch2_7EE0

Snd6A_Ch1:
	VIBRATO 3
	VOICE $01, 6, 0, 5, 10
	SND_CALL Snd6A_Ch1_7F70
Snd6A_Ch1_7EF2:
	SND_CALL Snd69_Ch1_7D09
	SND_CALL Snd69_Ch1_7D8A
	SND_CALL Snd6A_Ch1_7EF2

Snd6A_Ch3:
	VOICE $01, 2, 10, 4, 13
	SND_CALL Snd6A_Ch3_7FA8
Snd6A_Ch3_7F02:
	SND_CALL Snd69_Ch3_7E10
	SND_CALL Snd69_Ch3_7E5F
	SND_CALL Snd6A_Ch3_7F02

Snd6A_Drm:
	DRUM_UNIT $04
	SND_CALL Snd6A_Drm_7FE6
Snd6A_Drm_7F10:
	SND_CALL Snd69_Drm_7EB0
	SND_CALL Snd69_Drm_7EBE
	SND_CALL Snd6A_Drm_7F10
Snd6A_Ch2_7F19:
	PAN $F0
	REST 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 6
	REST 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE A_, 6
	OCTAVE 4
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 3, 6
	NOTE D_, 4
	NOTE C#, 4
	PAN $0F
	LEN_UNIT $01
	RELEASE 7, $0A
	NOTE D_, 5
	NOTE C#, 6
	OCTAVE 3
	NOTE A_, 5
	LEN_UNIT $04
	RELEASE 0, 0
	NOTE E_, 4
	PAN $F0
	LEN_UNIT $01
	RELEASE 7, $0A
	OCTAVE 5
	NOTE D_, 5
	NOTE C#, 6
	OCTAVE 4
	NOTE A_, 5
	LEN_UNIT $04
	PAN $FF
	RELEASE 0, 0
	NOTE E_, 4
	LEN_UNIT $01
	RELEASE 7, $0A
	OCTAVE 3
	NOTE E_, 6
	REST 5
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 6, $0A
	NOTE E_, 8
	RELEASE 3, 6
	NOTE E_, 4
	RELEASE 6, $0A
	NOTE E_, 8
	LEN_UNIT $01
	DUTY 8
	RELEASE $0F, $0F
	OCTAVE 2
	NOTE B_, 5
	OCTAVE 3
	NOTE C#, 6
	NOTE D_, 5
	NOTE E_, 5
	NOTE F#, 6
	NOTE G#, 5
	VIBRATO 0
	SND_RET
Snd6A_Ch1_7F70:
	DUTY_STEP 8, 2
	VIBRATO 1
	OCTAVE 2
	NOTE A_, 6
	REST 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE E_, 6
	NOTE A_, 5
	NOTE A_, 6
	REST 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 6
	NOTE A_, 5
	SND_SEGNO
	NOTE G_, 6
	REST 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 6
	NOTE G_, 5
	SND_REPEAT 2
	NOTE G#, 6
	REST 5
	NOTE A_, 5
	LEN_UNIT $04
	RELEASE 6, $0C
	NOTE A_, 8
	RELEASE 4, 8
	NOTE F#, 4
	RELEASE 6, $0C
	NOTE G#, 8
	LEN_UNIT $01
	DUTY 4
	RELEASE $0F, $0F
	OCTAVE 3
	NOTE D#, 5
	NOTE E_, 6
	NOTE F#, 5
	NOTE G#, 5
	NOTE A_, 6
	NOTE B_, 5
	DUTY_STEP_OFF
	SND_RET
Snd6A_Ch3_7FA8:
	OCTAVE 3
	NOTE E_, 6
	REST 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE A_, 6
	OCTAVE 4
	NOTE E_, 5
	LEN_UNIT $04
	RELEASE 3, 7
	NOTE D_, 4
	NOTE C#, 4
	LEN_UNIT $01
	RELEASE 4, $0B
	NOTE D_, 5
	NOTE C#, 6
	OCTAVE 3
	NOTE A_, 5
	LEN_UNIT $04
	RELEASE 0, 0
	NOTE E_, $0C
	LEN_UNIT $01
	RELEASE 4, $0B
	NOTE B_, 6
	REST 5
	OCTAVE 4
	NOTE C#, 5
	LEN_UNIT $04
	RELEASE 6, $0A
	NOTE C#, 8
	RELEASE 7, 8
	OCTAVE 3
	NOTE A_, 4
	RELEASE 6, $0A
	NOTE B_, 8
	LEN_UNIT $01
	WAVE 8
	RELEASE $0F, $0F
	OCTAVE 1
	NOTE B_, 5
	OCTAVE 2
	NOTE C#, 6
	NOTE D_, 5
	NOTE E_, 5
	NOTE F#, 6
	NOTE G#, 5
	SND_RET
Snd6A_Drm_7FE6:
	SND_SEGNO
	REST 8
	SND_REPEAT 7
	LEN_UNIT $01
	DRUM 2, 5
	DRUM 2, 6
	DRUM 2, 5
	DRUM 2, 5
	DRUM 2, 6
	DRUM 2, 5
	SND_RET
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $0F
