; ==========================================================================
; Tiny Toon Adventures 2 - Montana's Movie Madness (U) - Konami sound driver (bank 7)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: MapBank7, SndUpdateFar, PlaySoundFar, SndInit ($03DC-$046C)
;   bank 7: tables, headers, drum hits ($43F9-$4AB9), the driver ($4ABA-$56A9), streams ($56AA-$7F54)
; Build: rgbasm -Wall -o tt2.o TT2_SoundDriver.asm && rgblink -o tt2.gb tt2.o
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
DEF wTrkSfx1 EQU $C080 ; 66 bytes
DEF wTrkSfx2 EQU $C180 ; 66 bytes
DEF wTrkSfxN EQU $C280 ; 66 bytes
DEF wTrkCh1 EQU $C380 ; 66 bytes
DEF wTrkCh2 EQU $C480 ; 66 bytes
DEF wTrkCh3 EQU $C580 ; 66 bytes
DEF wTrkDrm EQU $C680 ; 66 bytes
DEF wTrackDesc EQU $C0C3
DEF wC0C4 EQU $C0C4
DEF wTempo EQU $C0C5
DEF wTempoAcc EQU $C0C6
DEF wReqPrio EQU $C0C7
DEF wReqId EQU $C0C8
DEF wPauseLast EQU $C0C9
DEF wFadeTimer EQU $C0CA
DEF wFadeLevel EQU $C0CB
DEF wFadeRate EQU $C0CC
DEF wWaveId EQU $C0CD
DEF wC0CE EQU $C0CE
DEF wGameMode EQU $C000
DEF wPauseFlags EQU $DD6C
DEF hGameState EQU $FF80
DEF hSndBusy EQU $FF86
DEF rROMB EQU $2180 ; MBC1 bank select as written by this game
DEF hBankId EQU $7FFF ; every bank stores its own number in its last byte

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
DEF TRK_PRIO EQU $80
DEF TRK_ID EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_PANFLAGS EQU $86
DEF TRK_FLOW EQU $87
DEF TRK_VIB EQU $88
DEF TRK_DETUNE EQU $89
DEF TRK_ATTEN EQU $8B
DEF TRK_TRANSP EQU $8C
DEF TRK_JUMPCNT EQU $8D
DEF TRK_DUTYTICKS EQU $8E
DEF TRK_DUTYCNT EQU $8F
DEF TRK_DUTYSTART EQU $90
DEF TRK_UNIT EQU $91
DEF TRK_OCTAVE EQU $92
DEF TRK_PERIOD EQU $93
DEF TRK_LASTPERIOD EQU $95
DEF TRK_VOL EQU $97
DEF TRK_LASTVOL EQU $98
DEF TRK_DUTY EQU $99
DEF TRK_LASTDUTY EQU $9A
DEF TRK_GATE EQU $9B
DEF TRK_RELTICK EQU $9C
DEF TRK_ENV EQU $9D
DEF TRK_CH3CNT EQU $9E
DEF TRK_PAN EQU $9F
DEF TRK_VIBPTR EQU $A0
DEF TRK_VIBCUR EQU $A2
DEF TRK_VIBTIMER EQU $A4
DEF TRK_VIBDELAY EQU $A5
DEF TRK_VIBDELAYCNT EQU $A6
DEF TRK_VIBDEPTH EQU $A7
DEF TRK_VIBLOOP EQU $A8
DEF TRK_VIBLOOPCNT EQU $AA
DEF TRK_VIBMARK EQU $AB
DEF TRK_LOOP1 EQU $AD
DEF TRK_LOOP1CNT EQU $AF
DEF TRK_LOOP2 EQU $B0
DEF TRK_LOOP2CNT EQU $B2
DEF TRK_MARK EQU $B3
DEF TRK_RET EQU $B5
DEF TRK_REG_NRX1 EQU $B7
DEF TRK_REG_NRX2 EQU $B8
DEF TRK_REG_NRX3 EQU $B9
DEF TRK_REG_NRX4 EQU $BA
DEF TRK_LASTPITCH EQU $BB
DEF TRK_FLAGS3 EQU $BC
DEF TRK_RELVOL EQU $BD
DEF TRK_PITCHIDX EQU $BE
DEF TRK_PANATTEN EQU $BF
DEF TRK_WAVEA EQU $C0
DEF TRK_WAVEB EQU $C1

; wTrackDesc: Sfx1 $40, Sfx2 $52, SfxN $63, Ch1 $00, Ch2 $11, Ch3 $22, Drm $34 (low nibble = channel)
; TRK_FLAGS: 0 rest, 1 (cleared at the end of Sfx1/Sfx2, never tested), 2 retrigger a long note,
;   4 tempo skip, 5 reload the duty/wave
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, 5 wave
;   alternation, 6 wave A loaded, 7 autopan with both sides
; TRK_FLOW: 0/1 loops open, 2 in a call, 3 mark set, 4 vibrato loop, 5 vibrato mark
; TRK_FLAGS3: 0 Sfx1/Sfx2 low nibble next, 2 noise retrigger pending, 5 octave 6 (never read)

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
DEF C_HI EQU 13 ; pitch 13: the previous note's pitch one octave up

; sound header: priority, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; music tracks: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0: (unit & 15) x 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = sound id (drum hit) 1-13, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; Sfx1/Sfx2: two notes per byte (high nibble, then low nibble), one unit each; pitch 0 = rest
MACRO NOTES
	db (\1 << 4) | \2
ENDM
; a byte only read for its low nibble (the first byte of a stream before any voice)
MACRO NOTE_LO
	db (\1 << 4) | \2
ENDM
; Sfx1/Sfx2: note \1, then a new unit
MACRO NOTE_UNIT
	db (\1 << 4) | $0E, \2
ENDM
; Sfx1/Sfx2: note \1, then the next byte is a command
MACRO NOTE_CMD
	db (\1 << 4) | $0F
ENDM
; SfxN: NR43 value (no retrigger unless marked), length = unit
MACRO NOISE
	db \1
ENDM
; SfxN: mark a retrigger for the next noise note
MACRO NOISE_TRIG
	db $C0
ENDM
; SfxN: volume \1 (NR42 high nibble), retrigger at the next noise note
MACRO NOISE_VOL
	db $C0 | \1
ENDM
; SfxN: volume \1 and a retrigger now, length = unit (0: NR42 = 8)
MACRO NOISE_VOLNOTE
	db $D0 | \1
ENDM
; $E0: unit (5 bits), octave code (OctaveCodes index), duty<<4|vol, gate<<4|env (CH3: duty = wave)
MACRO VOICE
	db $E0, (\2 << 5) | \1, (\3 << 4) | \4, (\5 << 4) | \6
ENDM
; $E0 unit, NR42 nibble-swapped (noise SFX: retriggered at the next noise note)
MACRO NVOICE
	db $E0, \1, \2
ENDM
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release tick = length * gate / 16), env (NRx2 low nibble at the release)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9: NR10, written at once (never blocked)
MACRO SWEEP
	db $E9, \1
ENDM
; $EA xy
MACRO DUTY
	db $EA, $00 | \1
ENDM
MACRO WAVE
	db $EA, $00 | \1
ENDM
; pan (both sides / NR51 high nibble / low nibble) + attenuation y
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $20 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $30 | \1
ENDM
; autopan: every note alternates low / high nibble side (y kept in TRK_PANATTEN, unused)
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
; autopan: every note alternates low nibble side at attenuation y / both sides at attenuation 0
MACRO AUTOPAN_BOTH
	db $EA, $50 | \1
ENDM
MACRO EXT_6
	db $EA, $60 | \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \1
ENDM
; release volume: at the release tick NRx2 = y << 4 instead of the envelope
MACRO RELEASE_VOL
	db $EA, $90 | \1
ENDM
MACRO EXT_A
	db $EA, $A0 | \1
ENDM
MACRO EXT_B
	db $EA, $B0 | \1
ENDM
MACRO EXT_C
	db $EA, $C0 | \1
ENDM
; $EB n, xy: vibrato table n, delay x * unit, depth y; $EB n | $80: semitone table n (no delay byte)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_SEMI
	db $EB, $80 | \1
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $EC xy: CH3 alternates waves x and y on every note; $EC 0 off (reloads TRK_DUTY's wave)
MACRO WAVE_ALT
	db $EC, (\1 << 4) | \2
ENDM
MACRO WAVE_ALT_OFF
	db $EC, $00
ENDM
; $ED xy: notes start with duty x << 4, the voice duty comes back after y ticks (y = 0: off)
MACRO DUTY_STEP
	db $ED, (\1 << 4) | \2
ENDM
MACRO TEMPO
	db $EE, \1
ENDM
MACRO DETUNE
	db $EF, \1
ENDM
; $F0-$F8: attenuation
MACRO ATTEN
	db $F0 | \1
ENDM
; $F9 n addr: jump on the n-th pass
MACRO SND_JUMP_N
	db $F9, \1
	dw \2
ENDM
MACRO SND_JUMP
	db $FA
	dw \1
ENDM
; $FB / $FC: the first one met marks a loop start, the next one (with a count) loops
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
; $FD addr call, a bare $FD returns
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
; vibrato tables: time << 4 | negative << 3 | offset (x depth); semitone tables: time << 4 | code
; (1-12 semitones, 13 = 19, 14 = 24, 15 = 36); $FB / $FB n loop, $FE mark/jump, $FF end
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
ENDM
MACRO VIB_SEMI_STEP
	db (\1 << 4) | \2
ENDM
MACRO VIB_LOOP_START
	db $FB
ENDM
MACRO VIB_LOOP_END
	db $FB, \1
ENDM
MACRO VIB_MARK
	db $FE
ENDM
MACRO VIB_END
	db $FF
ENDM

SECTION "MapBank7", ROM0[$0388]

MapBank7:
	ld a, $07
	ld [rROMB], a
	ret

SECTION "Sound ROM0", ROM0[$03DC]

; SndUpdateFar (from the VBlank handler): skipped while hSndBusy bit 0 is set; maps bank 7
; (the handler restores the bank) and runs SndUpdate.
SndUpdateFar:
	ld hl, hSndBusy
	bit 0, [hl]
	ret nz
	set 0, [hl]
	call MapBank7
	call SndUpdate
	ld hl, hSndBusy
	res 0, [hl]
	ret

; PlaySoundFar: A = sound id (0 = stop all). Ids $01-$55 except $1C are dropped while
; hGameState = 7 and wGameMode = $0D. Sets hSndBusy, wReqId = A, PlaySound.
PlaySoundFar:
	push hl
	push de
	push bc
	push af
	cp $00
	jr z, .l040F
	cp $1C
	jr z, .l040F
	cp $56
	jr nc, .l040F
	ld b, a
	ldh a, [hGameState]
	cp $07
	jr nz, .l040E
	ld a, [wGameMode]
	cp $0D
	jr z, .l042C
.l040E:
	ld a, b
.l040F:
	ld hl, hSndBusy
	set 0, [hl]
	ld [wReqId], a
	ld a, [hBankId]
	push af
	ld a, $07
	ld [rROMB], a
	call PlaySound
	pop af
	ld [rROMB], a
	ld hl, hSndBusy
	res 0, [hl]
.l042C:
	pop af
	pop bc
	pop de
	pop hl
	ret

; SndInit: stop everything, NR50 = $77, NR51 = $FF, NR52 = $80, and the register
; addresses TRK_REG_NRX1-4 of tracks 0-5 (Sfx1 $11, Sfx2 $1B, SfxN $20, Ch1 $11, Ch2 $16,
; Ch3 $1B). The drum track keeps 0, so its register writes go to $FF00 (the joypad).
SndInit:
	ld a, $00
	call PlaySoundFar
	ld c, $24
	ld a, $77
	ldh [c], a
	inc c
	ld a, $FF
	ldh [c], a
	inc c
	ld a, $80
	ldh [c], a
	ld h, HIGH(wTrkSfx1)
	ld a, $11
	ld l, TRK_REG_NRX1
	call SetRegAddrs
	ld a, $1B
	call SetRegAddrs
	ld a, $20
	call SetRegAddrs
	ld a, $11
	call SetRegAddrs
	ld a, $16
	call SetRegAddrs
	ld a, $1B

SetRegAddrs:
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc h
	ld l, TRK_REG_NRX1
	ret

SECTION "Sound bank 7", ROMX[$43F9], BANK[7]

; SoundTable: ids $01-$70 (entry 0 is other data; the code adds 2 * id).
SoundTable:
	dw $20FA ; $00 (unused: the code adds 2 * id)
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
	dw SndHdr6C ; $6C
	dw SndHdr6D ; $6D
	dw SndHdr6E ; $6E
	dw SndHdr6F ; $6F
	dw SndHdr70 ; $70

SndHdr01:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd06_SfxN

SndHdr0A:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $FF, $03 ; tracks: Sfx1, Sfx2
	dw Snd0B_Sfx1
	dw Snd0B_Sfx2

SndHdr07:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd07_Sfx1

SndHdr08:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd08_Sfx1

SndHdr09:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd09_Sfx1

SndHdr0C:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd0C_Sfx1

SndHdr0D:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd0D_Sfx1

SndHdr0E:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd0E_Sfx1
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd0F_Sfx1
	dw Snd0F_SfxN

SndHdr10:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd10_Sfx1
	dw Snd10_SfxN

SndHdr11:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd12_Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $81, $05 ; tracks: Sfx1, SfxN
	dw Snd13_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $70, $05 ; tracks: Sfx1, SfxN
	dw Snd14_Sfx1
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $82, $03 ; tracks: Sfx1, Sfx2
	dw Snd15_Sfx1
	dw Snd15_Sfx2

SndHdr16:
	SND_HEADER $80, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd16_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr17:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $F5, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd1C_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr1D:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $74, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr1F:
	SND_HEADER $74, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $7F, $01 ; tracks: Sfx1
	dw Snd20_Sfx1

SndHdr21:
	SND_HEADER $72, $04 ; tracks: SfxN
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $78, $05 ; tracks: Sfx1, SfxN
	dw Snd22_Sfx1
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $7F, $05 ; tracks: Sfx1, SfxN
	dw Snd23_Sfx1
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $75, $01 ; tracks: Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $75, $05 ; tracks: Sfx1, SfxN
	dw Snd25_Sfx1
	dw Snd0F_Sfx1

SndHdr26:
	SND_HEADER $76, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $73, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd27_Sfx1
	dw Snd27_Sfx2
	dw Snd27_SfxN
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr28:
	SND_HEADER $73, $05 ; tracks: Sfx1, SfxN
	dw Snd28_Sfx1
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd29_SfxN

SndHdr2A:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $81, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd2B_Sfx1
	dw Snd2B_Sfx2
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr2C:
	SND_HEADER $76, $04 ; tracks: SfxN
	dw Snd14_SfxN

SndHdr2D:
	SND_HEADER $7F, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd2D_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr2E:
	SND_HEADER $73, $05 ; tracks: Sfx1, SfxN
	dw Snd2E_Sfx1
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd2F_Sfx1

SndHdr30:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd30_Sfx1

SndHdr31:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd31_Sfx1

SndHdr32:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $73, $03 ; tracks: Sfx1, Sfx2
	dw Snd33_Sfx1
	dw Snd33_Sfx2

SndHdr34:
	SND_HEADER $73, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd34_Sfx1
	dw Snd34_Sfx2
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $70, $01 ; tracks: Sfx1
	dw Snd35_Sfx1

SndHdr36:
	SND_HEADER $73, $01 ; tracks: Sfx1
	dw Snd36_Sfx1

SndHdr37:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd37_Sfx1

SndHdr38:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr39:
	SND_HEADER $71, $01 ; tracks: Sfx1
	dw Snd38_Sfx1

SndHdr3A:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $74, $05 ; tracks: Sfx1, SfxN
	dw Snd3B_Sfx1
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $74, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd0F_Sfx1

SndHdr3D:
	SND_HEADER $74, $01 ; tracks: Sfx1
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $73, $01 ; tracks: Sfx1
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $7A, $05 ; tracks: Sfx1, SfxN
	dw Snd40_Sfx1
	dw Snd0F_Sfx1

SndHdr41:
	SND_HEADER $72, $05 ; tracks: Sfx1, SfxN
	dw Snd41_Sfx1
	dw Snd41_SfxN

SndHdr42:
	SND_HEADER $73, $05 ; tracks: Sfx1, SfxN
	dw Snd42_Sfx1
	dw Snd42_SfxN

SndHdr43:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $73, $04 ; tracks: SfxN
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $73, $01 ; tracks: Sfx1
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $73, $01 ; tracks: Sfx1
	dw Snd47_Sfx1

SndHdr48:
	SND_HEADER $73, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_Sfx1

SndHdr49:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $79, $01 ; tracks: Sfx1
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd4B_Sfx1

SndHdr4C:
	SND_HEADER $75, $04 ; tracks: SfxN
	dw Snd4C_SfxN

SndHdr4D:
	SND_HEADER $7A, $01 ; tracks: Sfx1
	dw Snd4D_Sfx1

SndHdr4E:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $7A, $06 ; tracks: Sfx2, SfxN
	dw Snd4F_Sfx2
	dw Snd4F_SfxN

SndHdr50:
	SND_HEADER $82, $01 ; tracks: Sfx1
	dw Snd50_Sfx1

SndHdr51:
	SND_HEADER $75, $01 ; tracks: Sfx1
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $84, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd53_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_SfxN
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr54:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd54_SfxN

SndHdr55:
	SND_HEADER $7A, $04 ; tracks: SfxN
	dw Snd55_SfxN

SndHdr56:
	SND_HEADER $82, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd56_Sfx1
	dw Snd56_Sfx2
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr57:
	SND_HEADER $F4, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

SndHdr58:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1
	dw Snd0F_Sfx1

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
	dw Snd0F_Sfx1

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

SndHdr68:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd68_Ch1
	dw Snd68_Ch2
	dw Snd68_Ch3
	dw Snd68_Drm

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

SndHdr6C:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6C_Ch1
	dw Snd6C_Ch2
	dw Snd6C_Ch3
	dw Snd6C_Drm

SndHdr6D:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6D_Ch1
	dw Snd6D_Ch2
	dw Snd6D_Ch3
	dw Snd6D_Drm

SndHdr6E:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6E_Ch1
	dw Snd6E_Ch2
	dw Snd6E_Ch3
	dw Snd6E_Drm

SndHdr6F:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd6F_Ch1
	dw Snd6F_Ch2
	dw Snd6F_Ch3
	dw Snd6F_Drm

SndHdr70:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd70_Ch1
	dw Snd70_Ch2
	dw Snd70_Ch3
	dw Snd0F_Sfx1

; PeriodTable: 120 periods. Notes index it from PeriodTable - 26 by 2 * pitch +
; TRK_OCTAVE + TRK_TRANSP, so pitch 1 of OctaveCodes entry 1 is its first entry.
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F2, $7F3, $7F4, $7F4, $7F5, $7F6, $7F6, $7F7, $7F7 ; octave index 7
	dw $610, $620, $630, $640, $64C, $658, $663, $66E, $67D, $684, $68A, $692 ; octave index 8
	dw $707, $70E, $715, $71B, $721, $727, $72E, $733, $739, $73E, $742, $746 ; octave index 9

Snd0B_Sfx1:
	VOICE $02, 0, 15, 4, 15, 2
	NOTES 0, 1
	LEN_UNIT $04
	DETUNE $FE
	LOOP_START
	OCTAVE 3
	NOTES 5, 9
	NOTES $0C, 9
	NOTE_CMD $0C
	OCTAVE 4
	NOTE_CMD 5
	ATTEN 3
	LOOP_END 2
	ATTEN 3
	SND_END

Snd0B_Sfx2:
	VOICE $04, 0, 5, 2, 15, 2
	EXT_B $0C
	VIBRATO_SEMI 2
	LOOP_START
	OCTAVE 4
	NOTES 5, 9
	NOTES $0C, 9
	NOTE_CMD $0C
	OCTAVE 5
	NOTE_CMD 5
	VOICE $04, 0, 5, 6, 15, 2
	LOOP_END 2
	SND_END

; VibratoTable: 13 pointers (EB n uses entry n; the code adds from VibratoTable - 2).
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

Vib01:
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib02:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 1
	VIB_STEP 5, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib03:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib04:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib05:
	VIB_STEP 2, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 8, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib06:
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 0
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib07:
	VIB_STEP 1, 0, 7
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib08:
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 15, 0, 0
	VIB_STEP 7, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib09:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 3
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 5
	VIB_STEP 2, 0, 4
	VIB_STEP 2, 0, 3
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib0A:
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 2
	VIB_STEP 15, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 9, 0, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Vib0B:
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 15, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

Vib0C:
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 7
	VIB_END

Vib0D:
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 3
	VIB_STEP 1, 1, 2
	VIB_MARK

; WaveTable: 10 waves (wave n = the high nibble of the duty byte; from WaveTable - 2).
; The last wave runs 2 bytes into Vibrato2Table - 2.
WaveTable:
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
Wave1:
	db $12, $34, $56, $FF, $FF, $99, $55, $00, $00, $00, $22, $00, $00, $00, $00, $00
Wave2:
	db $02, $46, $8A, $CE, $FD, $B9, $75, $31, $02, $46, $8A, $CE, $FD, $B9, $75, $31
Wave3:
	db $44, $44, $00, $00, $44, $44, $00, $00, $44, $44, $00, $00, $44, $44, $00, $00
Wave4:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave5:
	db $88, $88, $88, $88, $77, $66, $55, $44, $00, $00, $00, $00, $00, $F0, $00, $00
Wave6:
	db $60, $11, $00, $00, $00, $00, $00, $00, $60, $11, $00, $00, $00, $00, $00, $00
Wave7:
	db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $BB, $BB, $BB, $AA
Wave8:
	db $08, $34, $67, $89, $A9, $87, $65, $31, $02, $34, $67, $89, $A9, $87, $65, $31
Wave9:
	db $77, $77, $00, $00, $00, $00, $00, $00, $77, $77, $00, $00, $00, $00, $00, $00
Wave10:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00

; Vibrato2Table: 8 semitone-step tables (EB n | $80; from Vibrato2Table - 2).
Vibrato2Table:
	dw VibSemi01 ; 1 (EB 1 | $80)
	dw VibSemi02 ; 2 (EB 2 | $80)
	dw VibSemi03 ; 3 (EB 3 | $80)
	dw VibSemi04 ; 4 (EB 4 | $80)
	dw VibSemi05 ; 5 (EB 5 | $80)
	dw VibSemi06 ; 6 (EB 6 | $80)
	dw VibSemi07 ; 7 (EB 7 | $80)
	dw VibSemi08 ; 8 (EB 8 | $80)
VibSemi01:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi02:
	VIB_MARK
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 3, 0
	VIB_MARK
VibSemi03:
	VIB_SEMI_STEP 1, $0E
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi04:
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi05:
	VIB_MARK
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, 7
	VIB_MARK
VibSemi06:
	VIB_SEMI_STEP 1, 7
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi07:
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, $0C
	VIB_MARK
VibSemi08:
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_END

Snd01_SfxN:
	NVOICE $81, $05
	NOISE $1F
	NOISE_VOL 5
	NOISE $21
	NOISE_VOL 2
	NOISE $20
	SND_END

Snd02_SfxN:
	NVOICE $81, $04
	NOISE $14
	NOISE_VOL 2
	NOISE $20
	NOISE $10
	SND_END

Snd03_SfxN:
	NVOICE $82, $17
	NOISE $15
	NVOICE $90, $73
	NOISE $14
	SND_END

Snd04_SfxN:
	NVOICE $81, $0F
	NOISE $35
	NOISE $26
	NVOICE $83, $26
	NOISE $26
	LEN_UNIT $01
	NOISE $34
	SND_END

Snd05_SfxN:
	NVOICE $81, $08
	NOISE $35
	NOISE $26
	NVOICE $83, $43
	NOISE $26
	LEN_UNIT $01
	NOISE $34
	SND_END

Snd06_SfxN:
	NVOICE $82, $0F
	NOISE $14
	NVOICE $B0, $3A
	NOISE $16
	SND_END

Snd0A_SfxN:
	NVOICE $81, $0A
	NOISE $36
	NOISE $57
	SND_END

; PlaySound: wReqId = id (0: StopAll). Header: priority, mask, pointers. If any SFX track
; of the mask holds a higher priority the mask is cleared and nothing starts. SFX tracks
; start without tests (SfxN also NR51 |= $88, and it cancels a fade: wFadeRate = 0, NR50 =
; $77). Music needs the Ch1 bit and a priority >= Ch1's: it resets tempo and fade, NR10 = 8,
; NR50 = $77, and starts Ch1-Ch3/Drm. A started track: LEN 1, $85-$8F = 0, wWaveId = 0,
; TRK_FLAGS3/TRK_RELVOL = 0, NRx2 = 0.
PlaySound:
	ld a, [wReqId]
	or a
	jp z, StopAll
	ld hl, SoundTable
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld e, l
	ld d, h
	rrc b
	ld hl, wTrkSfx1
	call c, CheckSfxPrio
	rrc b
	inc h
	call c, CheckSfxPrio
	rrc b
	inc h
	call c, CheckSfxPrio
	ld a, b
	rlca
	rlca
	rlca
	ld b, a
	srl b
	ld hl, wTrkSfx1
	call c, StartSfxTrack
	srl b
	ld hl, wTrkSfx2
	call c, StartSfxTrack
	srl b
	ld hl, wTrkSfxN
	call c, StartSfxTrack
	xor a
	ld [wC0CE], a
	srl b
	ret nc
	ld hl, wTrkCh1
	ld a, [wReqPrio]
	cp [hl]
	ret c
	xor a
	ld [wTempo], a
	ld [wFadeRate], a
	ld [wFadeLevel], a
	ld [wFadeTimer], a
	ld [wC0C4], a
	ld a, $08
	ld c, $10
	ldh [c], a
	ld a, $77
	ld c, $24
	ldh [c], a
	call StartMusicTrack
	srl b
	ld hl, wTrkCh2
	call c, StartMusicTrack
	srl b
	ld hl, wTrkCh3
	call c, StartMusicTrack
	srl b
	ld hl, wTrkDrm
	ret nc

StartMusicTrack:
	ld a, [wReqPrio]
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a

StartTrackCommon:
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, $01
	ld [hl+], a
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
	ld [wWaveId], a
	ld l, TRK_FLAGS3
	ld [hl+], a
	ld [hl], a
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ldh [c], a
	ret

CheckSfxPrio:
	cp [hl]
	ret nc
	ld b, $00
	ret

StartSfxTrack:
	ld a, [wReqPrio]
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a
	call StartTrackCommon
	ld a, $C0
	cp h
	jp nz, .l4B86
	ld a, $08
	ld c, $10
	ldh [c], a
.l4B86:
	ld a, $C2
	cp h
	ret nz
	push bc
	ld b, $88
	ld l, TRK_PAN
	ld [hl], b
	ld c, $25
	ldh a, [c]
	or b
	ldh [c], a
	pop bc
	ld a, [wFadeRate]
	ret z
	push hl
	xor a
	ld [wFadeRate], a
	pop hl
	ld a, $77
	ld c, $24
	ldh [c], a
	ret

; SndUpdate (once per VBlank): on a change of wPauseFlags bit 0 pause or unpause. Not paused:
; FadeTick, TempoTick, Ch1, Ch2, Ch3, Drm. Then SfxN, Sfx2, Sfx1 (also while paused).
SndUpdate:
	ld a, [wPauseFlags]
	and $01
	ld hl, wPauseLast
	cp [hl]
	jp z, UpdateTracks
	ld [hl], a
	cp $00
	call PauseEdge

UpdateTracks:
	ld a, [wPauseFlags]
	and $01
	or a
	jp nz, UpdateSfx
	ld h, HIGH(wTrkCh1)
	call FadeTick
	call TempoTick
	ld h, HIGH(wTrkCh1)
	xor a
	call RunTrack
	ld h, HIGH(wTrkCh2)
	ld a, $11
	call RunTrack
	ld h, HIGH(wTrkCh3)
	ld a, $22
	call RunTrack
	ld h, HIGH(wTrkDrm)
	ld a, $34
	call RunTrack

UpdateSfx:
	ld h, HIGH(wTrkSfxN)
	ld a, $63
	call RunTrack
	ld h, HIGH(wTrkSfx2)
	ld a, $52
	call RunTrack
	ld h, HIGH(wTrkSfx1)
	ld a, $40
	call RunTrack
	ret

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	jp TrackTick

; Pause: stop SfxN, mute CH4 and CH2. Unpause: stop Sfx1 and Sfx2, mute CH1, NR32 = 0,
; give CH1 and CH3 back to the music (NR51 bits and period, no trigger) and mark Ch1-Ch3
; for a retrigger of a long note (Ch1/Ch3 also reload the duty/wave).
PauseEdge:
	jp z, Unpause
	xor a
	ld h, HIGH(wTrkSfxN)
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ld a, $08
	ld c, $21
	ldh [c], a
	ld a, $80
	ld c, $23
	ldh [c], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ret

Unpause:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $10
	ldh [c], a
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
	inc h
	xor a
	ld [hl-], a
	ld [hl], a
	ld c, $1C
	ldh [c], a
	ld h, HIGH(wTrkCh1)
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $EE
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	inc h
	set 2, [hl]
	inc h
	set 2, [hl]
	set 5, [hl]
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $BB
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

; TempoTick: wTempoAcc += wTempo; the carry sets (else clears) the skip flag of all four
; music tracks, which then skip this update.
TempoTick:
	ld hl, wTempo
	ld a, [hl]
	ld b, a
	or a
	ld h, HIGH(wTrkCh1)
	ret z
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld l, TRK_FLAGS
	jp c, .l4CA0
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l4CA0:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: the game writes wFadeRate. Every wFadeRate updates the master volume NR50 goes
; down by $11 (Vin bits set); at level 3 the rate doubles (rlca); at 0 everything stops.
; wFadeLevel never changes, so the note-volume fade code has no effect.
FadeTick:
	ld a, [wFadeRate]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	xor a
	ld [hl], a
	ld c, $24
	ldh a, [c]
	and $77
	push af
	cp $33
	jr nz, .l4CCA
	ld a, [wFadeRate]
	rlca
	ld [wFadeRate], a
.l4CCA:
	pop af
	sub $11
	push af
	or $88
	ldh [c], a
	pop af
	ret nz
	xor a
	ld [wFadeLevel], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	jp StopAll

; TrackTick: tempo skip; a pending reload of the duty (CH3 with wave alternation: the
; current wave); LEN - 1; at 0 read commands, else Sustain.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jr z, .l4D12
	res 5, [hl]
	ld a, [wTrackDesc]
	cp $22
	jr nz, .l4D0C
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr z, .l4D0C
	bit 6, [hl]
	jr nz, .l4D04
	ld l, TRK_WAVEB
	ld a, [hl]
	call LoadWaveIfFree
	jr .l4D12
.l4D04:
	ld l, TRK_WAVEA
	ld a, [hl]
	call LoadWaveIfFree
	jr .l4D12
.l4D0C:
	ld l, TRK_LASTDUTY
	ld a, [hl]
	call WriteDuty
.l4D12:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

; ReadCmds: $E0-$FF commands. SfxN: NoiseNote. Sfx1/Sfx2: two notes per byte (high
; nibble with TRK_FLAGS3 bit 0 set, then the same byte again for the low nibble; low
; nibble $E: new unit from the next byte, $F: the next byte is a command), one unit each.
; Music: hi = pitch, lo x unit (0: (unit & 15) x 16).
ReadCmds:
	ld a, [de]
	cp $E0
	jp nc, Command
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote
	bit 6, a
	jr z, MusicNote
	ld l, TRK_FLAGS3
	bit 0, [hl]
	jr z, .l4D40
	res 0, [hl]
	dec de
	call SavePtr
.l4D3B:
	ld l, TRK_UNIT
	ld a, [hl]
	jr NoteLen
.l4D40:
	set 0, [hl]
	ld a, [de]
	and $0F
	cp $0E
	jr c, .l4D56
	inc de
	ld a, [de]
	jr z, .l4D50
	jp Command
.l4D50:
	ld l, TRK_UNIT
	ld [hl], a
	jp NextCmd
.l4D56:
	call SavePtr
	dec de
	jr .l4D3B

MusicNote:
	ld l, TRK_FLAGS
	res 2, [hl]
	call SavePtr
	dec de
	ld a, [de]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jr z, .l4D7D
	ld b, a
	xor a
	bit 0, b
	jr nz, .l4D85
	rrc b
.l4D74:
	add a, c
	dec b
	jp nz, .l4D74
	add a, a
	jp NoteLen
.l4D7D:
	swap c
	ld a, c
	and $F0
	jp NoteLen
.l4D85:
	add a, c
	dec b
	jp nz, .l4D85

NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	push hl
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l4D98
	swap a
.l4D98:
	pop hl
	and $F0
	jp nz, Note
	set 0, [hl]
	ld a, $08
	jp WriteVolume

; Note: release tick = length x gate / 16. CH3 with wave alternation loads the other wave;
; else a duty step writes its start duty. Autopan. Pitch 13 = the last pitch + an octave.
; Period from PeriodTable - 26 + 2 x pitch + octave + transpose, + detune (when its low
; byte is not 0). Vibrato restarts (semitone tables when its number has bit 7). NRx2 =
; TRK_VOL - TRK_ATTEN (no borrow test) through WriteVolume.
Note:
	res 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jp z, .l4DC9
	ld e, a
	ld b, $00
	ld hl, $0000
.l4DBE:
	add hl, bc
	dec e
	jp nz, .l4DBE
	ld a, l
	and $F0
	or h
	swap a
.l4DC9:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld a, [wTrackDesc]
	cp $22
	jr nz, .l4DF7
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr z, .l4DF7
	bit 6, [hl]
	jr nz, .l4DEB
	ld l, TRK_WAVEA
	ld a, [hl]
	ld l, TRK_PANFLAGS
	set 6, [hl]
	call LoadWaveIfFree
	jr .l4E03
.l4DEB:
	ld l, TRK_WAVEB
	ld a, [hl]
	ld l, TRK_PANFLAGS
	res 6, [hl]
	call LoadWaveIfFree
	jr .l4E03
.l4DF7:
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l4E03
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l4E03:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS3
	bit 0, [hl]
	ld a, [de]
	jr z, .l4E13
	swap a
.l4E13:
	and $F0
	cp $D0
	jp nz, .l4E25
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, TRK_LASTPITCH
	ld a, [hl]
	jr .l4E2E
.l4E25:
	swap a
	rlca
	ld l, TRK_LASTPITCH
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l4E2E:
	add a, c
	ld l, TRK_TRANSP
	ld c, [hl]
	add a, c
	ld c, a
	ld b, $00
	ld l, TRK_PITCHIDX
	ld [hl], a
	push hl
	ld hl, PeriodTable - 26
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl+]
	or a
	jp z, .l4E51
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l4E51:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l4E84
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jp nc, .l4E6E
	set 4, [hl]
	jp .l4E70
.l4E6E:
	res 4, [hl]
.l4E70:
	set 2, [hl]
	ld l, TRK_VIBPTR
	ld a, [hl+]
	ld b, [hl]
	inc l
	ld [hl+], a
	ld [hl], b
	ld c, a
	inc l
	ld [hl], $01
	inc l
	ld a, [hl+]
	or a
	ld [hl], a
	call z, VibratoStep
.l4E84:
	call WritePeriod
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	ld b, a
	ld a, [wFadeRate]
	or a
	ld a, b
	jp z, WriteVolume
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeLevel]
	ld c, a
	ld a, b
	jp nz, .l4EB3
	add a, c
	jp c, .l4EAE
	cp $70
	jp c, WriteVolume
.l4EAE:
	ld a, $00
	jp WriteVolume
.l4EB3:
	sub c
	jp nc, WriteVolume
	jp WriteVolume8

; Sustain (not SfxN, Drm, rests): duty step countdown, vibrato (after its delay), then
; the release: NRx2 = TRK_RELVOL, or env | level + trigger (env 0: 8); CH3 steps NR32
; down every env ticks. Before the release a pending long-note retrigger rewrites NRx2.
Sustain:
	ld a, [wTrackDesc]
	cp $63
	ret z
	cp $34
	ret z
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret nz
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l4ED9
	dec [hl]
	jp nz, .l4ED9
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l4ED9:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, ReleaseTick
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, ReleaseTick
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	or a
	jp z, .l4EF2
	dec [hl]
	jp ReleaseTick
.l4EF2:
	ld l, TRK_VIBTIMER
	dec [hl]
	jp nz, ReleaseTick
	ld l, TRK_VIBCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	call WritePeriod
	jp ReleaseTick

; VibratoStep: one-byte steps, time << 4 | negative << 3 | offset x depth (semitone
; tables: time << 4 | code from the note's period index), $FB loop marker / $FB n,
; $FE mark / jump, $FF ends (TRK_LASTPERIOD is written again).
VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, .l4F62
	cp $FE
	jp z, .l4F9C
	cp $FB
	jp z, .l4F6E
	ld l, TRK_VIBTIMER
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, TRK_VIBCUR
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	jp z, .l4F5C
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jp nz, VibratoSemitone
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l4F44
	and $07
	jp z, .l4F5C
	cpl
	inc a
	ld e, a
	ld d, $FF
.l4F44:
	ld a, [hl]
	or a
	jp z, .l4F51
	ld b, a
	xor a
.l4F4B:
	add a, e
	dec b
	jp nz, .l4F4B
	ld e, a
.l4F51:
	ld l, TRK_PERIOD + 1
	ld a, [hl-]
	ld l, [hl]
	push hl
	ld h, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ret
.l4F5C:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4F62:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	res 4, [hl]
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4F6E:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l4F83
	set 4, [hl]
	ld l, TRK_VIBLOOP
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l4F83:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l4F92
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l4F92:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l4F9C:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l4FAE
	set 5, [hl]
	inc bc
	ld l, TRK_VIBMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l4FAE:
	ld l, TRK_VIBMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l4FC7
	sub $0D
	jr z, .l4FC5
	dec a
	jr z, .l4FC3
	add a, $0B
.l4FC3:
	add a, $05
.l4FC5:
	add a, $13
.l4FC7:
	rlca
	ld c, a
	ld l, TRK_PITCHIDX
	ld a, [hl]
	add a, c
	ld e, a
	ld d, $00
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld b, a
	ld c, [hl]
	push hl
	ld hl, PeriodTable - 26
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, c
	ld l, b
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ret

ReleaseTick:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, ReleaseCh3
	cp [hl]
	jp z, .l5006
	jp c, .l5005
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l5005:
	ret
.l5006:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, WriteVolume8
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

ReleaseCh3:
	cp [hl]
	inc hl
	jp c, .l5046
	jp z, .l5041
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l5041:
	ld l, TRK_ENV
	ld a, [hl+]
	ld [hl], a
	ret
.l5046:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, WriteVolume
	ld l, TRK_CH3CNT
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $7F
	or a
	ret z
	add a, $20
	cp $A0
	ret nc
	jp WriteVolume

; DrumNote: the drum hit id = the note's high nibble, started on the SFX tracks of its
; header, each with its own priority test (no register writes; NR10 = 8 / NR51 |= $88).
DrumNote:
	ld a, [de]
	and $F0
	swap a
	ld [wReqId], a
	ld hl, SoundTable
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, StartDrumHit
	srl b
	ld hl, wTrkSfx2
	call c, StartDrumHit
	srl b
	ld hl, wTrkSfxN
	ret nc

StartDrumHit:
	ld a, [wReqPrio]
	cp [hl]
	jp c, .l50CB
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, $01
	ld [hl+], a
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld a, $C0
	cp h
	jp nz, .l50BA
	ld a, $08
	ld c, $10
	ldh [c], a
.l50BA:
	ld a, $C2
	cp h
	ret nz
	push bc
	ld b, $88
	ld l, TRK_PAN
	ld [hl], b
	ld c, $25
	ldh a, [c]
	or b
	ldh [c], a
	pop bc
	ret
.l50CB:
	inc de
	inc de
	ret

; NoiseNote: < $C0 NR43 = byte, NR44 = 0 (checked), retrigger if marked; $C0 marks a
; retrigger; $C1-$CF set the volume nibble and mark; $D0-$DF set it and retrigger now
; ($D0: NR42 = 8). Length = unit.
NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	call SavePtr
	cp $C0
	jr c, NoiseFreq
	jr nz, .l50E5
	ld l, TRK_FLAGS3
	set 2, [hl]
	jp ReadCmds
.l50E5:
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $0F
	ld [hl], a
	ld a, b
	and $0F
	swap a
	or [hl]
	ld [hl], a
	bit 4, b
	jr nz, .l50FD
	ld a, [hl]
	ld l, TRK_FLAGS3
	jp VoiceNoise.l51DE
.l50FD:
	ld a, b
	and $0F
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp nz, NoiseTrigger
	ld a, $08
	jp NoiseTrigger

NoiseFreq:
	ld e, a
	ld d, $00
	call WritePeriod
	ld l, TRK_FLAGS3
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]

NoiseTrigger:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld a, $80
	ldh [c], a
	ret

; Command: $E0 voice, $E1-$E6 octave (OctaveCodes), $E7-$FF through CommandTable (which
; the code indexes from CommandTable - 14).
Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
	cp $07
	jp c, Cmd_Octave
	push hl
	ld hl, CommandTable - 14
	call LoadPtrIndexed
	ld a, [de]
	jp hl
CommandTable:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_WaveAlt
	dw Cmd_DutyStep
	dw Cmd_Tempo
	dw Cmd_Detune
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_Atten
	dw Cmd_JumpN
	dw Cmd_Jump
	dw Cmd_Loop1
	dw Cmd_Loop2
	dw Cmd_CallRet
	dw Cmd_Mark
	dw Cmd_End

NoiseUnit:
	ld a, [de]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ret

; Cmd_Voice: unit = u & $1F (SfxN: u & $7F), octave = OctaveCodes[u >> 5] (entries 0 and
; 7 are code bytes). Tone/wave: duty, vol, gate, env, autopan off, attenuation 0, both
; sides; Sfx1/Sfx2 also set TRK_FLAGS3 bit 0 (high nibble next). SfxN: NR42 = swap(v) at
; the next noise note.
Cmd_Voice:
	ld a, [de]
	and $1F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [de]
	and $E0
	swap a
	srl a
	ld c, a
	ld b, $00
	push hl
	ld hl, OctaveCodes - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	ld a, [wTrackDesc]
	cp $63
	call z, NoiseUnit
	ld l, TRK_FLAGS3
	ld a, [wTrackDesc]
	cp $63
	ld a, [de]
	inc de
	jr z, VoiceNoise
	ld a, [wTrackDesc]
	bit 6, a
	jr z, .l51AC
	set 0, [hl]
.l51AC:
	ld a, [de]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [de]
	and $0F
	swap a
	ld l, TRK_VOL
	ld [hl], a
	inc de
	ld a, [de]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	ld l, TRK_PANFLAGS
	res 0, [hl]
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	call PanBoth
	jp NextCmd

VoiceNoise:
	ld a, [de]
	swap a
	inc de
.l51DE:
	set 2, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	jp ReadCmds

Cmd_Octave:
	ld l, TRK_FLAGS3
	res 5, [hl]
	cp $06
	jr c, .l51F0
	set 5, [hl]
.l51F0:
	ld c, a
	ld b, $00
	push hl
	ld hl, OctaveCodes - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	jp ReadCmds
OctaveCodes:
	db $18, $30, $48, $60, $78, $90

Cmd_LenUnit:
	pop hl
	ld l, TRK_UNIT
	ld [hl], a
	jp NextCmd

Cmd_Release:
	pop hl
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	jp NextCmd

Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	jp NextCmd

; Cmd_Ext: $EA xy through ExtTable (13 entries; x >= $D runs into the code).
Cmd_Ext:
	swap a
	and $0F
	ld hl, ExtTable
	call LoadPtrIndexed
	ld a, [de]
	jp hl
ExtTable:
	dw Ext_Duty
	dw Ext_PanBoth
	dw Ext_PanLeft
	dw Ext_PanRight
	dw Ext_Autopan
	dw Ext_AutopanBoth
	dw Ext_Nop
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_ReleaseVol
	dw Ext_Nop
	dw Ext_Nop
	dw Ext_Nop

Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld l, TRK_PANFLAGS
	ld a, [hl]
	and $9F
	ld [hl], a
	jp NextCmd

Ext_PanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	jp Cmd_Atten.l5407

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l527B
.l5275:
	sla b
	dec a
	jp nz, .l5275
.l527B:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp WriteRegChecked

Ext_PanLeft:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanLeft
	jp Cmd_Atten.l5407

Ext_PanRight:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanRight
	jp Cmd_Atten.l5407

AutoPan:
	bit 7, [hl]
	jp nz, .l52AA
	bit 1, [hl]
	jp nz, PanRight.l52E1
	set 1, [hl]
	jp PanRight
.l52AA:
	bit 1, [hl]
	jp z, .l52B8
	res 1, [hl]
	xor a
	call SetAtten
	jp PanBoth
.l52B8:
	set 1, [hl]
	ld l, TRK_PANATTEN
	ld a, [hl]
	call SetAtten

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l52D5
.l52CD:
	rlc b
	rlc l
	dec a
	jp nz, .l52CD
.l52D5:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l52E1:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l52F8
.l52F0:
	rlc b
	rlc l
	dec a
	jp nz, .l52F0
.l52F8:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked

Ext_Autopan:
	pop hl
	call AutopanSetup
	res 1, [hl]
	res 2, [hl]
	jp NextCmd

AutopanSetup:
	ld a, [de]
	and $0F
	ld l, TRK_PANATTEN
	ld [hl], a
	ld l, TRK_PANFLAGS
	set 0, [hl]
	ret

Ext_AutopanBoth:
	pop hl
	call AutopanSetup
	set 7, [hl]
	set 1, [hl]
	jp NextCmd

Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_TransposeDown:
	pop hl
	and $0F
	jp z, .l5338
	rlca
	cpl
	inc a
.l5338:
	ld l, TRK_TRANSP
	ld [hl], a
	jp NextCmd

Ext_ReleaseVol:
	pop hl
	inc de
	and $0F
	swap a
	ld l, TRK_RELVOL
	ld [hl], a
	jp ReadCmds

Ext_Nop:
	pop hl
	jp NextCmd

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l5392
	bit 7, [hl]
	jp nz, .l5395
	and $7F
	push hl
	ld hl, VibratoTable - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc de
	ld a, [de]
	swap a
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jr z, .l538A
	ld b, a
	xor a
	bit 0, b
	jr nz, .l5386
	rrc b
.l537F:
	add a, c
	dec b
	jr nz, .l537F
	add a, a
	jr .l538A
.l5386:
	add a, c
	dec b
	jr nz, .l5386
.l538A:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [de]
	and $0F
	inc l
	ld [hl], a
.l5392:
	jp NextCmd
.l5395:
	and $7F
	push hl
	ld hl, Vibrato2Table - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_VIBDELAY
	ld [hl], $00
	jp NextCmd

Cmd_WaveAlt:
	pop hl
	or a
	jr z, .l53C5
	and $F0
	ld l, TRK_WAVEA
	ld [hl], a
	ld a, [de]
	and $0F
	swap a
	ld l, TRK_WAVEB
	ld [hl], a
	ld l, TRK_PANFLAGS
	set 5, [hl]
	jp NextCmd
.l53C5:
	ld l, TRK_PANFLAGS
	ld a, [hl]
	and $9F
	ld [hl], a
	ld l, TRK_DUTY
	ld a, [hl]
	call LoadWaveIfFree
	jp NextCmd

Cmd_DutyStep:
	pop hl
	and $F0
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld a, [de]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, WriteDuty
	jp NextCmd

Cmd_Tempo:
	pop hl
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	jp NextCmd

Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l5401
	ld a, $FF
.l5401:
	ld [hl], a
	jp NextCmd

Cmd_Atten:
	pop hl
	dec de
.l5407:
	ld a, [de]
	call SetAtten
	jp NextCmd

; SetAtten: TRK_ATTEN = y << 4 (CH3: cpl(rlc(y << 4))).
SetAtten:
	and $0F
	swap a
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l541F
	rlca
	cpl
.l541F:
	ld l, TRK_ATTEN
	ld [hl], a
	ret

Cmd_JumpN:
	pop hl
	ld l, TRK_JUMPCNT
	inc [hl]
	cp [hl]
	inc de
	jp z, .l5431
	inc de
	inc de
	jp ReadCmds
.l5431:
	xor a
	ld [hl], a
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Loop1:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l545A
	set 0, [hl]
	ld l, TRK_LOOP1
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l545A:
	ld l, TRK_LOOP1CNT
	inc [hl]
	cp [hl]
	jp z, .l5468
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5468:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	jp NextCmd

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l5486
	set 1, [hl]
	ld l, TRK_LOOP2
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l5486:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l5494
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5494:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	jp NextCmd

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l54B5
	set 2, [hl]
	inc de
	ld c, a
	ld a, [de]
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, a
	jp ReadCmds
.l54B5:
	res 2, [hl]
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

Cmd_Mark:
	pop hl
	ld l, TRK_FLOW
	bit 3, [hl]
	jp nz, .l54D1
	set 3, [hl]
	ld l, TRK_MARK
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l54D1:
	ld l, TRK_MARK
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; Cmd_End: clear priority and id. Drm: nothing else. Sfx1 (NR10 = 8) and Sfx2 give CH1 /
; CH3 back to a playing music track (NR51 bits, period, retrigger and reload marks). Then
; the channel is muted (CH3: NR32 = 0, else NRx2 = 8 + trigger).
Cmd_End:
	pop hl
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, .l5509
	cp $40
	jp z, .l54F2
	jp MuteChannel
.l54F2:
	ld l, TRK_FLAGS
	res 1, [hl]
	ld a, $08
	ld c, $10
	ldh [c], a
	push hl
	ld h, HIGH(wTrkCh1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, GiveBack
	pop hl
	jp MuteChannel
.l5509:
	ld l, TRK_FLAGS
	res 1, [hl]
	push hl
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, GiveBack
	pop hl
	jp MuteChannel

NextCmd:
	inc de
	jp ReadCmds

SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

GiveBack:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l553C
.l5536:
	rlc b
	dec a
	jp nz, .l5536
.l553C:
	ld c, $25
	ldh a, [c]
	and b
	ld l, TRK_PAN
	or [hl]
	ldh [c], a
	ld l, TRK_LASTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	jp WritePeriod

LoadPtrIndexed:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

WritePeriod:
	ld l, TRK_LASTPERIOD
	ld [hl], e
	inc l
	ld a, d
	and $07
	ld [hl], a
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld a, e
	call WriteRegChecked
	ret nc
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

MuteChannel:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l5588
	ld a, $08
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG_NRX4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ret
.l5588:
	xor a
	ld c, $1C
	jp WriteRegChecked

; WriteVolume: TRK_LASTVOL = A; NRx2 is only written (and triggered, not on CH3) when it
; reads back differently - on CH1 also while NR10 does not read 8.
WriteVolume:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, .l55AC
	ld a, [wTrackDesc]
	and $0F
	ret nz
	ld c, $10
	ldh a, [c]
	and $7F
	cp $08
	ret z
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
.l55AC:
	ld a, [hl]
	call WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

DeadSavePtr:
	call SavePtr ; unreachable

WriteVolume8:
	ld a, $08
	jr WriteVolume

; WriteDuty: NRx1 = A. CH3: the wave (high nibble) if it is not the one loaded (wWaveId);
; music Ch3 only keeps it while Sfx2 plays.
WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l55DF
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jp WriteRegChecked
.l55DF:
	ld a, [wTrackDesc]
	cp $22
	jp nz, .l55F3
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_LASTDUTY
	ld [hl], b
	ret nz
.l55F3:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_LASTDUTY
	ld [hl], a
	ld [wWaveId], a
	jr LoadWave

LoadWaveIfFree:
	ld b, a
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz

LoadWave:
	push hl
	ld c, $1A
	xor a
	ldh [c], a
	ld a, b
	swap a
	ld hl, WaveTable - 2
	call LoadPtrIndexed
	ld c, $30
	ld b, $10
.l561D:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l561D
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_LASTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteRegChecked: [C] = A unless music Ch1 while Sfx1 plays or music Ch3 while Sfx2 plays.
; Carry = written.
WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l5653
	cp $22
	jp nz, .l565F
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l5653:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l565F:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: priority and id of all tracks cleared; NRx2 = 8 on CH1, CH2, CH4, NR30 = 8 and
; NR32 = 8; triggers on CH1, CH2, CH4; NR51 = $FF.
StopAll:
	xor a
	ld hl, wTrkSfx1
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 1, [hl]
	ld hl, wTrkSfx2
	ld [hl+], a
	ld [hl], a
	ld l, TRK_FLAGS
	res 1, [hl]
	ld hl, wTrkSfxN
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	inc h
	ld [hl+], a
	ld [hl-], a
	ld c, $12
	ld a, $08
	ldh [c], a
	ld c, $17
	ldh [c], a
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
	ld c, $21
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
	ld c, $19
	ldh [c], a
	ld c, $23
	ldh [c], a
	ld a, $FF
	ld c, $25
	ldh [c], a
	ret

Snd07_Sfx1:
	VOICE $08, 4, 8, 5, 0, 0
	SWEEP $37
	NOTE_CMD 5
	ATTEN 4
	NOTE_CMD 5
	SND_END

Snd08_Sfx1:
	VOICE $04, 3, 8, 11, 8, 1
	RELEASE_VOL 1
	SWEEP $17
	NOTES 1, 8
	ATTEN 4
	NOTES 8, 0
	ATTEN 8
	NOTE_CMD 8
	SND_END

Snd09_Sfx1:
	VOICE $03, 4, 8, 9, 8, 1
	RELEASE_VOL 3
	NOTES $0C, 8
	ATTEN 6
	NOTES $0C, 8
	ATTEN 8
	NOTES $0C, 8
	SND_END

Snd0C_Sfx1:
	VOICE $03, 4, 8, 9, 8, 1
	RELEASE_VOL 2
	NOTES 8, $0A
	NOTE_CMD $0C
	ATTEN 6
	NOTES 8, $0A
	NOTE_CMD $0C
	ATTEN 8
	NOTES 8, $0A
	NOTE_CMD $0C
	SND_END

Snd0D_Sfx1:
	SND_JUMP Snd08_Sfx1

Snd0E_Sfx1:
	VOICE $1F, 2, 8, 0, 15, 10
	SWEEP $37
	NOTE_CMD 5
	VOICE $1F, 2, 8, 15, 0, 0
	NOTE_CMD $0B
	VOICE $1F, 3, 8, 15, 0, 0
	SWEEP $7F
	NOTES $0A, 4
	SND_END

Snd0E_SfxN:
	NVOICE $01, $0F
	LOOP_START
	NOISE $27
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE_VOLNOTE 0
	NOISE_VOLNOTE 0
	NOISE_VOL 8
	NOISE_VOL 4
	LOOP_END 2
	SND_END

Snd0F_SfxN:
	NVOICE $01, $4F
	NOISE $55
	NOISE $45
	NOISE $35
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE_VOL 8
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE_VOL 2
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END

Snd10_Sfx1:
	SND_CALL Snd10_Sfx1_5719
	SND_END
Snd10_Sfx1_5719:
	VOICE $08, 3, 8, 15, 8, 2
	SWEEP $1B
	DUTY_STEP 0, 1
	NOTES 5, 5
	ATTEN 4
	NOTES 5, 5
	SND_RET

Snd10_SfxN:
	NVOICE $01, $06
	NOISE $47
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	SND_END

Snd11_Sfx1:
	VOICE $02, 1, 0, 15, 0, 0
	SWEEP $12
	LOOP_START
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 7
	LOOP_END 2
	SND_END

Snd12_Sfx1:
	SND_END

Snd13_Sfx1:
	VOICE $02, 6, 8, 15, 0, 0
	SWEEP $1C
	TRANSPOSE_UP $0C
	NOTES $0C, 6
	NOTES $0B, 7
	OCTAVE 5
	NOTES 9, 2
	NOTES 8, 4
	VOICE $05, 1, 8, 13, 0, 0
	SWEEP $15
	NOTES 3, 5
	NOTES 9, $0C
	ATTEN 3
	NOTES 3, 5
	NOTES 9, $0C
	ATTEN 6
	NOTES 3, 5
	NOTES 9, $0C
	ATTEN 8
	NOTES 3, 5
	NOTES 9, $0C
	SND_END

Snd13_SfxN:
	NVOICE $40, $7A
	NOISE $45
	NOISE $14
	SND_END

Snd14_Sfx1:
	VOICE $01, 6, 4, 4, 0, 0
	NOTES 1, 2
	NOTES 3, 0
	NOTES 8, 9
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 5, 4
	NOTES 3, 2
	LOOP2_START
	LOOP_START
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	TRANSPOSE_UP $0C
	LOOP_END 2
	ATTEN 2
	TRANSPOSE_UP 0
	LOOP2_END 2
	PAN_LEFT 0
	LOOP_START
	NOTES 1, 3
	NOTES $0A, 7
	NOTES 4, 1
	NOTES 3, 6
	NOTES 8, $0A
	NOTES $0B, $0C
	PAN_RIGHT 0
	ATTEN 3
	LOOP_END 2
	SND_END

Snd14_SfxN:
	NVOICE $1A, $B2
	NOISE $44
	NVOICE $5A, $7F
	NOISE $44
	SND_END

Snd15_Sfx1:
	VOICE $06, 4, 8, 11, 8, 1
	VIBRATO_SEMI 1
	TRANSPOSE_UP 4
	RELEASE_VOL 2
	LOOP_START
	NOTES 8, 5
	NOTE_CMD 8
	OCTAVE 5
	NOTES 1, 5
	OCTAVE 4
	ATTEN 7
	LOOP_END 2
	SND_END

Snd15_Sfx2:
	VOICE $06, 4, 4, 2, 8, 1
	VIBRATO_SEMI 1
	RELEASE_VOL 6
	TRANSPOSE_UP 4
	LOOP_START
	OCTAVE 5
	NOTE_CMD 1
	OCTAVE 4
	NOTE_CMD 8
	OCTAVE 5
	NOTES 1, 5
	NOTE_CMD 8
	ATTEN 1
	LOOP_END 2
	SND_END

Snd16_Sfx1:
	VOICE $01, 6, 8, 10, 0, 0
	NOTES 5, 7
	NOTES 5, 7
	ATTEN 8
	NOTES 5, 7
	NOTES 5, 7
	ATTEN 0
	LOOP_START
	NOTES 5, 7
	LOOP_END 13
	ATTEN 8
	NOTES 5, 7
	NOTES 5, 7
	SND_END

Snd17_Sfx1:
	VOICE $04, 4, 4, 10, 8, 1
	RELEASE_VOL 1
	NOTE_CMD 6
	OCTAVE 5
	NOTES 1, 0
	ATTEN 6
	NOTES 1, 0
	ATTEN 8
	NOTE_CMD 1
	SND_END

Snd18_Sfx1:
	VOICE $01, 6, 4, 5, 0, 0
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0B
	LEN_UNIT $02
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	SND_END

Snd19_Sfx1:
	TRANSPOSE_DOWN $0C
	SND_JUMP Snd24_Sfx1

Snd1A_Sfx1:
	VOICE $02, 4, 0, 8, 0, 0
	SWEEP $16
	NOTES 8, 8
	NOTES 8, 0
	NOTES 8, 8
	NOTES 8, 8
	NOTES 8, 8
	SND_END

Snd1B_Sfx1:
	VOICE $01, 5, 0, 10, 0, 0
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0A
	NOTES $0C, 8
	NOTES 7, 6
	NOTES 5, 4
	NOTES 3, 2
	SND_END

Snd1C_Sfx1:
	VOICE $01, 3, 0, 10, 0, 0
	NOTES 1, 4
	NOTES 7, $0A
	OCTAVE 4
	NOTES 1, 4
	NOTES 7, $0A
	SND_CALL Snd1C_Sfx1_582F
	ATTEN 4
	SND_CALL Snd1C_Sfx1_582F
	ATTEN 6
	SND_CALL Snd1C_Sfx1_582F
	ATTEN 8
	SND_CALL Snd1C_Sfx1_582F
	SND_END
Snd1C_Sfx1_582F:
	OCTAVE 5
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0B
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	SND_RET

Snd1D_Sfx1:
	VOICE $05, 4, 8, 13, 8, 1
	RELEASE_VOL 1
	VIBRATO_SEMI 7
	ATTEN 8
	NOTES 1, 1
	ATTEN 6
	NOTES 1, 1
	ATTEN 4
	NOTES 1, 1
	ATTEN 2
	NOTES 1, 1
	ATTEN 0
	NOTES 1, 1
	NOTES 1, 1
	ATTEN 3
	NOTES 1, 1
	ATTEN 6
	NOTES 1, 1
	ATTEN 8
	NOTES 1, 1
	SND_END

Snd1E_Sfx1:
	VOICE $03, 3, 4, 15, 15, 1
	RELEASE_VOL 4
	DUTY_STEP 8, 1
	VIBRATO_SEMI 1
	NOTES 8, $0C
	ATTEN 4
	NOTES 0, 8
	NOTES $0C, 0
	ATTEN 6
	NOTES 8, $0C
	ATTEN 8
	NOTES 0, 8
	NOTE_CMD $0C
	SND_END
Data_5868:
	VOICE $10, 0, 0, 0, 1, 4
	SND_END

Snd1F_Sfx1:
	VOICE $03, 4, 4, 13, 8, 1
	RELEASE_VOL 2
	DUTY_STEP 8, 1
	VIBRATO_SEMI 1
	NOTE_CMD $0C
	ATTEN 8
	NOTE_CMD $0C
	ATTEN 0
	NOTE_CMD 1
	ATTEN 8
	NOTE_CMD 1
	OCTAVE 3
	ATTEN 0
	NOTE_CMD 1
	ATTEN 8
	NOTE_CMD 1
	OCTAVE 2
	ATTEN 0
	NOTE_CMD 1
	ATTEN 8
	NOTE_CMD 1
	SND_END

Snd20_Sfx1:
	VOICE $03, 5, 0, 10, 15, 6
	DUTY_STEP 8, 1
	NOTES 1, 6
	NOTES 3, 8
	ATTEN 5
	NOTES 1, 6
	NOTES 3, 8
	ATTEN 8
	NOTES 1, 6
	NOTES 3, 8
	SND_END

Snd21_SfxN:
	NVOICE $02, $E0
	LOOP2_START
	LOOP_START
	NOISE $44
	NOISE $34
	NOISE $24
	NOISE $04
	NOISE $04
	NOISE $04
	NOISE $04
	LOOP_END 7
	NVOICE $02, $7F
	LOOP2_END 2
	SND_END

Snd23_Sfx1:
	VOICE $07, 4, 0, 15, 15, 2
	SWEEP $1E
	NOTES 8, 8
	SWEEP $00
	VOICE $04, 5, 8, 14, 14, 1
	RELEASE_VOL 1
	NOTES 3, 7
	ATTEN 4
	NOTES 3, 7
	ATTEN 6
	NOTES 3, 7
	ATTEN 8
	NOTES 3, 7
	SND_END

Snd23_SfxN:
	NVOICE $02, $74
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $24
	NOISE_VOL 8
	NOISE $24
	NOISE_VOL $0A
	NOISE $24
	NOISE_VOL $0C
	NOISE $24
	SND_END

Snd2D_Sfx1:
	VOICE $01, 4, 8, 13, 0, 0
	SND_CALL Snd2D_Sfx1_5900
	ATTEN 5
	SND_CALL Snd2D_Sfx1_5900
	ATTEN 8
	SND_CALL Snd2D_Sfx1_5900
	VOICE $06, 5, 8, 15, 15, 1
	RELEASE_VOL 5
	DUTY_STEP 0, 2
	SWEEP $3B
	NOTES $0C, 8
	OCTAVE 4
	NOTES $0C, 8
	OCTAVE 3
	NOTES $0C, 7
	VOICE $05, 3, 8, 9, 15, 1
	RELEASE_VOL 1
	NOTES $0C, 8
	ATTEN 4
	NOTES $0C, 8
	ATTEN 6
	NOTES $0C, 8
	ATTEN 8
	NOTES $0C, 8
	SND_END
Snd2D_Sfx1_5900:
	DUTY_STEP 4, 1
	SWEEP $27
	NOTES 9, 5
	NOTES 3, 1
	OCTAVE 5
	NOTES 8, 6
	NOTES 4, 2
	OCTAVE 4
	NOTES $0C, $0A
	NOTES 8, 6
	NOTES 4, 2
	SND_RET

Snd24_Sfx1:
	VOICE $07, 4, 8, 15, 15, 2
	SWEEP $1E
	NOTE_CMD 8
	VOICE $08, 5, 8, 8, 15, 2
	NOTE_CMD 8
	ATTEN 4
	NOTE_CMD 8
	ATTEN 7
	NOTE_CMD 8
	SND_END

Snd25_Sfx1:
	VOICE $02, 4, 8, 11, 0, 0
	SWEEP $6E
	NOTES 1, 1
	NOTES 1, 1
	ATTEN 3
	NOTES 2, 3
	ATTEN 6
	NOTES 4, 5
	ATTEN 8
	NOTES 6, 7
	SND_END

Snd26_Sfx1:
	VOICE $01, 3, 4, 15, 0, 0
	SWEEP $1E
	NOTES 9, 5
	NOTES 3, 1
	NOTES $0C, $0A
	NOTES 8, 6
	NOTES 4, 2
	OCTAVE 3
	NOTES $0C, $0A
	NOTES 8, 6
	NOTES 4, 2
	OCTAVE 2
	NOTES $0C, $0A
	NOTES 8, 6
	NOTES 4, 2
	SND_END

Snd26_SfxN:
	NVOICE $01, $7F
	NOISE $57
	NOISE $56
	NOISE $54
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $17
	NOISE $16
	NOISE $15
	SND_END

Snd27_Sfx1:
	VOICE $10, 1, 4, 5, 0, 0
	NOTES $0C, $0C
	NOTE_CMD $0C
	SND_JUMP Snd14_Sfx1

Snd27_SfxN:
	NVOICE $10, $00
	NOISE $14
	NOISE $14
	NOISE $14
	SND_JUMP Snd14_SfxN

Snd27_Sfx2:
	VOICE $1F, 2, 11, 2, 0, 0
	NOTES $0C, $0C
	ATTEN 1
	NOTES $0C, $0C
	ATTEN 2
	NOTES $0C, $0C
	SND_END

Snd28_Sfx1:
	VOICE $01, 3, 8, 15, 0, 0
	SWEEP $1B
	NOTES 6, 5
	NOTES 4, 3
	NOTES 9, $0C
	OCTAVE 4
	NOTES 8, 9
	NOTES 8, 9
	NOTES 8, 9
	NOTES 7, 8
	NOTES 6, 7
	NOTES 5, 6
	NOTES 4, 5
	NOTES 3, 4
	NOTES 1, 2
	OCTAVE 3
	NOTES $0B, $0C
	NOTES $0A, $0B
	NOTES 9, $0A
	NOTES 8, 9
	NOTES 7, 8
	NOTES 6, 7
	NOTES 5, 6
	NOTES 4, 5
	DUTY_STEP 0, 0
	SWEEP $00
	SND_JUMP Snd28_Sfx1_5A4B

Snd28_SfxN:
	NVOICE $05, $08
	NOISE $57
	NOISE $37
	NOISE $47
	NOISE $47
	NOISE $6A
	NOISE $7A
	SND_JUMP Snd34_SfxN

Snd29_SfxN:
	NVOICE $02, $0D
	NOISE $57
	NOISE $56
	NOISE $45
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE_VOL 6
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE_VOL 3
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE_VOL 1
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	SND_JUMP Snd34_SfxN

Snd2A_SfxN:
	NVOICE $01, $4F
	LOOP_START
	NOISE $14
	NOISE $44
	NOISE $36
	NOISE $26
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $00
	LOOP_END 6
	SND_END

Snd2B_Sfx1:
	VOICE $02, 5, 8, 10, 0, 0
Snd2B_Sfx1_59CE:
	LOOP_START
	NOTES $0C, $0B
	NOTES $0A, 9
	NOTES 8, 7
	NOTES 6, 5
	NOTES 4, 3
	NOTES 2, 1
	OCTAVE 4
	LOOP_END 2
	SND_END

Snd2B_Sfx2:
	VOICE $02, 5, 3, 4, 0, 0
	SND_JUMP Snd2B_Sfx1_59CE

Snd2E_Sfx1:
	VOICE $07, 2, 4, 15, 10, 1
	RELEASE_VOL 2
	VIBRATO_SEMI 1
	SWEEP $17
	TRANSPOSE_DOWN 4
	NOTES 1, $0D
	ATTEN 8
	OCTAVE 3
	NOTE_CMD 1
	SND_END

Snd2E_SfxN:
	NVOICE $02, $63
	NOISE $58
	NOISE $45
	NOISE $46
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $14
	SND_END

Snd2F_Sfx1:
	VOICE $03, 5, 4, 15, 0, 0
	NOTES $0C, 0
	NOTES 8, 0
	ATTEN 6
	NOTES 8, 0
	ATTEN 8
	NOTE_CMD 8
	SND_END

Snd30_Sfx1:
	VOICE $03, 5, 8, 15, 0, 0
	NOTES $0C, 0
	ATTEN 6
	NOTES $0C, 0
	ATTEN 8
	NOTE_CMD $0C
	SND_END

Snd31_Sfx1:
	VOICE $02, 4, 0, 10, 0, 0
	NOTES 8, 0
	ATTEN 6
	NOTES 8, 0
	ATTEN 8
	NOTE_CMD 8
	SND_END

Snd32_Sfx1:
	VOICE $07, 5, 8, 12, 15, 1
	DUTY_STEP 8, 2
	VIBRATO_SEMI 2
	LOOP_START
	NOTES $0C, 1
	LOOP_END 4
	ATTEN 6
	NOTES $0C, 1
	ATTEN 8
	NOTES $0C, 1
	SND_END

Snd33_Sfx2:
	VOICE $05, 2, 4, 2, 0, 0
	NOTES $0C, 0
	NOTES $0C, $0C
	NOTES $0C, $0C
	SND_END

Snd33_Sfx1:
	VOICE $05, 1, 4, 15, 0, 0
	DETUNE $0A
	NOTES $0C, 0
	NOTES $0C, $0C
	NOTES $0C, $0C
	SND_END

Snd34_Sfx1:
	VOICE $02, 2, 4, 3, 0, 0
	VIBRATO_SEMI 7
	DUTY_STEP 8, 1
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
Snd28_Sfx1_5A4B:
	VOICE $02, 2, 4, 3, 0, 0
	VIBRATO_SEMI 7
	DUTY_STEP 8, 1
	SND_SEGNO
	NOTES $0A, $0A
	SND_LOOP

Snd34_Sfx2:
	VOICE $02, 2, 1, 6, 0, 0
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	SND_SEGNO
	NOTES $0A, $0A
	SND_LOOP

Snd34_SfxN:
	NVOICE $01, $03
	SND_SEGNO
	NOISE $58
	NOISE $54
	NOISE $68
	NOISE_VOL 1
	NOISE $58
	NOISE $48
	NOISE $68
	NOISE_VOL 3
	SND_LOOP

Snd35_Sfx1:
	VOICE $03, 4, 8, 9, 7, 1
	RELEASE_VOL 2
	NOTE_CMD 1
	LEN_UNIT $05
	NOTE_CMD 4
	ATTEN 6
	NOTE_CMD 4
	ATTEN 8
	NOTE_CMD 4
	SND_END

Snd36_Sfx1:
	VOICE $04, 4, 8, 9, 0, 0
	RELEASE_VOL 2
	TRANSPOSE_UP 2
	NOTES 1, 4
	NOTES 8, $0B
	ATTEN 7
	NOTES 1, 4
	NOTES 8, $0B
	SND_END

Snd37_Sfx1:
	SND_CALL Snd37_Sfx1_5A90
	SND_END
Snd37_Sfx1_5A90:
	VOICE $02, 1, 4, 15, 0, 0
	VIBRATO_SEMI 2
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 2
	LOOP_START
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	OCTAVE 3
	LOOP_END 2
	SND_RET

Snd38_Sfx1:
	VOICE $01, 4, 8, 8, 0, 0
	SWEEP $27
	TRANSPOSE_UP 4
	NOTES 1, 2
	NOTES 3, 4
	NOTES 2, 1
	ATTEN 3
	NOTES 1, 2
	NOTES 3, 4
	NOTES 2, 1
	ATTEN 5
	NOTES 1, 2
	NOTES 3, 4
	NOTES 2, 1
	SND_END

Snd3A_SfxN:
	NVOICE $81, $F0
	LOOP_START
	NOISE $53
	NOISE $44
	NOISE $61
	NOISE $12
	NOISE $12
	NOISE $12
	LOOP_END 16
	SND_END

Snd3B_Sfx1:
	VOICE $01, 1, 8, 6, 0, 0
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	VIBRATO_SEMI 1
	SWEEP $27
	DUTY_STEP 4, 2
	VOICE $05, 4, 8, 11, 15, 1
	NOTE_CMD 1
	ATTEN 4
	NOTE_CMD 1
	ATTEN 8
	NOTES 1, 1
	SND_END

Snd3B_SfxN:
	NVOICE $02, $00
	NOISE_VOL 1
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE_VOL 6
	NOISE $48
	NOISE $68
	NOISE_VOL 1
	NOISE $16
	NOISE $15
	NOISE $14
	SND_END

Snd3C_Sfx1:
	VOICE $10, 5, 8, 10, 15, 7
	SWEEP $3F
	NOTE_CMD 3
	SND_END

Snd3D_Sfx1:
	SND_JUMP Snd24_Sfx1

Snd3E_Sfx1:
	VOICE $04, 1, 4, 0, 0, 0
	NOTE_CMD 1
	SND_JUMP Snd24_Sfx1

Snd3F_Sfx1:
	VOICE $01, 5, 0, 10, 0, 0
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0A
	NOTES $0C, 8
	NOTES 7, 6
	NOTES 5, 4
	NOTES 3, 2
	VOICE $06, 4, 8, 10, 13, 1
	RELEASE_VOL 1
	SWEEP $17
	LOOP_START
	NOTES 1, $0D
	LOOP_END 8
	SND_END

Snd40_Sfx1:
	VOICE $01, 4, 0, 15, 0, 0
	SWEEP $24
	LOOP_START
	NOTES 7, 7
	NOTES 7, 0
	LOOP_END 31
	SND_END

Snd41_Sfx1:
	SND_CALL Snd41_Sfx1_5B3E
	SND_END

Snd41_SfxN:
	SND_CALL Snd41_SfxN_5B2D
	SND_END
Snd41_SfxN_5B2D:
	NVOICE $02, $0F
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $54
	LEN_UNIT $0A
	NOISE $18
	NOISE_VOL 8
	NOISE $18
	NOISE_VOL 4
	NOISE $18
	NOISE_VOL 2
	NOISE $18
	SND_RET
Snd41_Sfx1_5B3E:
	VOICE $02, 4, 4, 15, 8, 3
	NOTES $0A, 7
	NOTES 3, 1
	LEN_UNIT $0F
	OCTAVE 5
	NOTE_CMD 5
	ATTEN 8
	NOTE_CMD 5
	SND_RET

Snd42_Sfx1:
	SND_CALL Snd41_Sfx1_5B3E
	SND_JUMP Snd28_Sfx1_5A4B

Snd42_SfxN:
	SND_CALL Snd41_SfxN_5B2D
	SND_JUMP Snd34_SfxN
	db $FF ; unreachable byte after an end

Snd43_SfxN:
	NVOICE $01, $5B
	NOISE $14
	NOISE $18
	NOISE $14
	NOISE $18
	NOISE $14
	NOISE $18
	NOISE $24
	NOISE $28
	NOISE $24
	NOISE $28
	NOISE $24
	NOISE $28
	NOISE $24
	NOISE $28
	NOISE $34
	NOISE $38
	NOISE $34
	NOISE $38
	SND_END

Snd44_SfxN:
	NVOICE $02, $4C
	NOISE $34
	NOISE $44
	NOISE_VOL 1
	NOISE $34
	NOISE $44
	NOISE_VOL 4
	NOISE $34
	NOISE $44
	NOISE_VOL 1
	NOISE $14
	NOISE $24
	SND_END

Snd45_SfxN:
	NVOICE $02, $4B
	NOISE $47
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $12
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $34
	NOISE $35
	NOISE $36
	SND_END

Snd46_Sfx1:
	VOICE $04, 3, 8, 13, 15, 1
	NOTE_CMD $0A
	ATTEN 4
	NOTE_CMD $0A
	ATTEN 6
	NOTE_CMD $0A
	ATTEN 8
	NOTE_CMD $0A
	SND_END

Snd47_Sfx1:
	VOICE $1F, 4, 8, 15, 15, 3
	NOTE_CMD $0A
	SND_END

Snd22_Sfx1:
	VOICE $05, 4, 8, 15, 8, 1
	RELEASE_VOL 1
	SWEEP $29
	TRANSPOSE_DOWN 4
	LOOP_START
	NOTES 8, 0
	NOTES 8, 8
	LOOP_END 4
	ATTEN 5
	NOTES 8, 0
	NOTES 8, 8
	NOTES 8, 0
	NOTES 8, 8
	ATTEN 8
	NOTES 8, 0
	NOTES 8, 8
	NOTES 8, 0
	NOTES 8, 8
	SND_END

Snd22_SfxN:
	NVOICE $16, $08
	LOOP_START
	NOISE $56
	LOOP_END 4
	NOISE_VOL 5
	NOISE $56
	NOISE $56
	NOISE_VOL 2
	NOISE $56
	NOISE $56
	SND_END

Snd48_Sfx1:
	SND_END

Snd49_SfxN:
	NVOICE $01, $7F
	NOISE $14
	NOISE $17
	NOISE $24
	NOISE $27
	NOISE $34
	NOISE $37
	NOISE $44
	NOISE $47
	LEN_UNIT $02
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE_VOL 8
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE_VOL 4
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE_VOL 2
	NOISE $64
	NOISE $65
	NOISE $66
	SND_END

Snd4A_Sfx1:
	TRANSPOSE_UP 7
	SND_CALL Snd37_Sfx1_5A90
	TRANSPOSE_DOWN 8
	VOICE $03, 4, 8, 12, 0, 0
	DUTY_STEP 8, 2
	SWEEP $1F
	NOTES $0C, 1
	ATTEN 1
	NOTES 5, 5
	NOTES 5, 5
	ATTEN 4
	NOTES 5, 5
	NOTES 5, 5
	ATTEN 6
	NOTES 5, 5
	NOTES 5, 5
	ATTEN 8
	NOTES 5, 5
	SND_END

Snd4B_Sfx1:
	VOICE $01, 4, 4, 12, 0, 0
	RELEASE_VOL 2
	SWEEP $17
	TRANSPOSE_DOWN $0C
	SND_CALL Snd4B_Sfx1_5C24
	TRANSPOSE_DOWN 6
	SND_CALL Snd4B_Sfx1_5C24
	TRANSPOSE_DOWN 0
	SND_CALL Snd4B_Sfx1_5C24
	TRANSPOSE_UP 6
	SND_CALL Snd4B_Sfx1_5C24
	SND_END
Snd4B_Sfx1_5C24:
	LOOP_START
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 5
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	NOTES 7, 8
	NOTES 9, $0A
	NOTES $0B, $0C
	ATTEN 0
	LOOP_END 2
	SND_RET

Snd4C_SfxN:
	NVOICE $82, $E2
	LOOP_START
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $24
	NOISE $25
	NOISE $34
	NOISE_VOL $0A
	LOOP_END 2
	NOISE_VOL 4
	LOOP_START
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $24
	NOISE $25
	NOISE $34
	NOISE_VOL 2
	LOOP_END 2
	SND_END

Snd4D_Sfx1:
	VOICE $01, 4, 8, 15, 10, 1
	NOTES 4, 5
	NOTES 6, 7
	VIBRATO_SEMI 1
	RELEASE_VOL 5
	LEN_UNIT $06
	NOTES $0C, 8
	OCTAVE 5
	NOTES $0C, 8
	ATTEN 4
	NOTES $0C, 8
	ATTEN 8
	NOTES $0C, 8
	SND_END

Snd4E_SfxN:
	NVOICE $10, $00
	NOISE_VOL 2
	NOISE $44
	NOISE_VOL 3
	NOISE $44
	NOISE_VOL 4
	NOISE $44
	NOISE_VOL 5
	NOISE $44
	NOISE_VOL 6
	NOISE $44
	NOISE_VOL 7
	NOISE $44
	NOISE_VOL 8
	NOISE $44
	NOISE_VOL 9
	NOISE $44
	NOISE_VOL $0A
	SND_SEGNO
	NOISE $44
	SND_LOOP
	db $FE ; unreachable byte after an end

Snd4F_Sfx2:
	VOICE $01, 2, 4, 2, 8, 1
	RELEASE_VOL 6
	NOTES 1, 2
	NOTES 3, 4
	NOTES 5, 6
	OCTAVE 4
	NOTES $0C, 9
	NOTES 6, 5
	ATTEN 1
	NOTES $0C, 9
	NOTES 6, 3
	ATTEN 2
	NOTES $0C, 9
	NOTES 6, 3
	SND_END

Snd4F_SfxN:
	NVOICE $02, $4F
	NOISE $3A
	NOISE $4B
	NOISE $3B
	NOISE $5B
	LEN_UNIT $04
	NOISE $38
	NOISE $28
	NOISE $18
	ATTEN 8
	NOISE $38
	NOISE $28
	NOISE $18
	SND_END

Snd50_Sfx1:
	VOICE $04, 4, 4, 13, 8, 1
	RELEASE_VOL 2
	DUTY_STEP 8, 1
	VIBRATO_SEMI 1
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0B
	OCTAVE 5
	NOTES 1, 3
	NOTES 5, 7
	NOTES 9, $0B
	SND_END

Snd51_Sfx1:
	VOICE $10, 2, 8, 15, 0, 0
	SWEEP $17
	NOTE_CMD 5
	ATTEN 5
	NOTE_CMD 5
	ATTEN 8
	NOTE_CMD 5
	SND_END

Snd52_SfxN:
	NVOICE $10, $00
	NOISE_VOL $0A
	NOISE $44
	NOISE_VOL 9
	NOISE $44
	NOISE_VOL 8
	NOISE $44
	NOISE_VOL 7
	NOISE $44
	NOISE_VOL 6
	NOISE $44
	NOISE_VOL 5
	NOISE $44
	NOISE_VOL 4
	NOISE $44
	NOISE_VOL 3
	NOISE $44
	NOISE_VOL 2
	SND_SEGNO
	NOISE $44
	SND_LOOP

Snd53_Sfx1:
	TRANSPOSE_UP 0
	SND_CALL Snd10_Sfx1_5719
	VOICE $10, 3, 0, 10, 0, 0
	SWEEP $47
	NOTE_CMD 8
	ATTEN 8
	NOTE_CMD 8
	ATTEN 0
	NOTE_CMD 5
	ATTEN 8
	NOTE_CMD 5
	ATTEN 0
	NOTE_CMD 1
	ATTEN 8
	NOTE_CMD 1
	SND_END

Snd54_SfxN:
	NVOICE $40, $0A
	NOISE $44
	NVOICE $40, $7A
	NOISE $44
	SND_END

Snd55_SfxN:
	SND_END

Snd56_Sfx1:
	VOICE $06, 4, 0, 7, 15, 3
	DUTY_STEP 8, 1
	VIBRATO 4, 0, 4
	TEMPO $03
	SND_JUMP Snd56_Sfx1_5D0C

Snd56_Sfx2:
	VOICE $06, 4, 4, 2, 10, 4
	VIBRATO 4, 0, 4
	RELEASE_VOL 6
Snd56_Sfx1_5D0C:
	LOOP_START
	NOTE_CMD 8
	LEN_UNIT $0B
	NOTE_CMD 8
	LEN_UNIT $06
	SND_JUMP_N 2, Snd56_Sfx1_5D21
	NOTES $0B, 8
	ATTEN 1
	NOTE_CMD 8
	ATTEN 1
	NOTE_CMD 8
	ATTEN 2
	NOTE_CMD 8
	ATTEN 0
	LOOP_END 2
Snd56_Sfx1_5D21:
	ATTEN 0
	NOTES $0C, 8
	ATTEN 1
	NOTE_CMD 8
	ATTEN 1
	NOTE_CMD 8
	ATTEN 2
	NOTE_CMD 8
	SND_END
Data_5D2A:
	VOICE $00, 3, 0, 0, 1, 4
	SND_END

Snd59_Ch2:
	TEMPO $2A
	SND_CALL Snd59_Ch2_5D4D
Snd59_Ch2_5D34:
	SND_CALL Snd59_Ch2_5D83
	SND_CALL Snd59_Ch2_5E70
	SND_END

Snd63_Ch2:
	TEMPO $30
	TRANSPOSE_DOWN 2
	SND_CALL Snd59_Ch2_5D4D
	SND_CALL Snd59_Ch2_5D83
	TEMPO $19
	REST 4
	TRANSPOSE_DOWN 1
	SND_JUMP Snd59_Ch2_5D34
Snd59_Ch2_5D4D:
	VOICE $01, 3, 8, 6, 15, 7
	REST 1
	VIBRATO_SEMI 3
	NOTE A_, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 4
	VIBRATO_OFF
	ATTEN 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	DETUNE $01
	OCTAVE 2
	NOTE B_, $0A
	SND_RET
Snd59_Ch2_5D83:
	VOICE $05, 3, 4, 8, 9, 7
	RELEASE_VOL 3
	DETUNE $00
	NOTE B_, 2
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	RELEASE 9, 4
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
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
	VOICE $01, 4, 8, 7, 6, 7
	VIBRATO_SEMI 1
	ATTEN 1
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	LEN_UNIT $05
	RELEASE $0A, 3
	ATTEN 0
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	REST 2
	VOICE $05, 2, 8, 7, 9, 7
	RELEASE_VOL 0
	VIBRATO 3, 0, 5
	NOTE D#, 4
	VOICE $05, 4, 0, 7, 9, 7
	DUTY_STEP 8, 1
	VIBRATO_OFF
	RELEASE_VOL 3
	NOTE C_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 2
	RELEASE_VOL 4
	NOTE D#, 3
	RELEASE_VOL 3
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 2
	RELEASE_VOL 4
	OCTAVE 4
	NOTE G_, 4
	RELEASE_VOL 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	REST 2
	VOICE $05, 4, 4, 7, 4, 7
	DUTY_STEP 0, 0
	NOTE G_, 4
	RELEASE 9, 3
	OCTAVE 5
	NOTE C_, 3
	REST 1
	VOICE $05, 6, 8, 5, 10, 7
	VIBRATO_SEMI 1
	NOTE C_, 3
	OCTAVE 5
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN_UNIT $01
	ATTEN 0
	NOTE C_, $0A
	RELEASE $0A, 7
	VIBRATO_OFF
	RELEASE_VOL 0
	NOTE G_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN_UNIT $05
	RELEASE_VOL 2
	OCTAVE 6
	NOTE C_, 3
	REST 1
	VOICE $05, 3, 4, 8, 8, 7
	VIBRATO_SEMI 1
	DUTY_STEP 0, 1
	RELEASE_VOL 4
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
	NOTE B_, 2
	REST 2
	VOICE $05, 3, 0, 13, 6, 7
	NOTE E_, 4
	VIBRATO_OFF
	VOICE $05, 3, 0, 8, 9, 7
	DUTY_STEP 8, 1
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	VIBRATO_SEMI 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 6
	VIBRATO_OFF
	OCTAVE 4
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	SND_RET
Snd59_Ch2_5E70:
	VOICE $01, 3, 8, 4, 7, 6
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	NOTE B_, 5
	OCTAVE 4
	NOTE C#, 5
	ATTEN 1
	NOTE D#, 7
	NOTE E_, 6
	ATTEN 0
	NOTE F#, 7
	LEN_UNIT $05
	RELEASE_VOL 2
	NOTE G#, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 6
	VOICE $05, 4, 0, 3, 0, 0
	REST 1
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 1
	VOICE $05, 3, 0, 7, 9, 6
	RELEASE_VOL 4
	DUTY_STEP 4, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	REST 2
	VOICE $05, 5, 8, 4, 8, 6
	RELEASE_VOL 2
	DUTY_STEP 0, 0
	NOTE E_, 3
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 2, 3
	NOTE G#, 2
	RELEASE 8, 6
	NOTE B_, 2
	RELEASE 2, 3
	NOTE F#, 2
	RELEASE 8, 6
	NOTE B_, 2
	NOTE E_, 4
	VOICE $05, 5, 0, 7, 8, 6
	RELEASE_VOL 4
	DUTY_STEP 4, 1
	NOTE E_, 2
	REST 2
	DETUNE $01
	OCTAVE 1
	NOTE E_, 4
	SND_RET

Snd59_Ch1:
	SND_CALL Snd59_Ch1_5EF5
Snd59_Ch1_5EE0:
	SND_CALL Snd59_Ch1_5F16
	SND_CALL Snd59_Ch1_6063
	SND_END

Snd63_Ch1:
	TRANSPOSE_DOWN 2
	SND_CALL Snd59_Ch1_5EF5
	SND_CALL Snd59_Ch1_5F16
	REST 4
	TRANSPOSE_DOWN 1
	SND_JUMP Snd59_Ch1_5EE0
Snd59_Ch1_5EF5:
	VOICE $05, 2, 4, 10, 7, 5
	DETUNE $FF
	VIBRATO_SEMI 1
	DUTY_STEP 8, 2
	RELEASE_VOL 4
	ATTEN 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	ATTEN 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	REST 2
	OCTAVE 1
	NOTE B_, 2
	SND_RET
Snd59_Ch1_5F16:
	VOICE $01, 2, 8, 6, 10, 7
	VIBRATO_OFF
	DUTY_STEP 0, 0
	RELEASE_VOL 2
	DETUNE $00
	NOTE B_, $0A
	OCTAVE 3
	NOTE E_, $0A
	LOOP_START
	ATTEN 2
	RELEASE_VOL 0
	OCTAVE 5
	NOTE G#, 4
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 5
	ATTEN 4
	NOTE A_, 3
	NOTE A#, 2
	ATTEN 0
	RELEASE_VOL 2
	OCTAVE 3
	SND_JUMP_N 2, Snd59_Ch1_5F3B
	NOTE E_, $0A
	NOTE A_, $0A
Snd59_Ch1_5F3B:
	LOOP_END 2
	NOTE D#, $0A
	NOTE E_, $0A
	NOTE G#, $0A
	NOTE B_, $0A
	NOTE E_, $0A
	NOTE A_, $0A
	ATTEN 2
	RELEASE_VOL 0
	OCTAVE 5
	NOTE G#, 4
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 5
	ATTEN 4
	NOTE A_, 3
	NOTE A#, 2
	ATTEN 0
	RELEASE_VOL 2
	OCTAVE 3
	NOTE D#, $0A
	NOTE F#, $0A
	NOTE D#, $0A
	REST $0A
	NOTE D#, $0A
	NOTE A_, $0A
	NOTE D#, $0A
	REST $0A
	RELEASE_VOL 0
	NOTE D#, 4
	NOTE E_, 3
	NOTE F_, 3
	DUTY_STEP 4, 1
	RELEASE_VOL 2
	NOTE B_, $0A
	NOTE B_, $0A
	NOTE B_, $0A
	NOTE B_, $0A
	OCTAVE 4
	NOTE E_, $0A
	VOICE $05, 3, 8, 5, 15, 7
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	NOTE G#, 1
	NOTE A#, 1
	LEN_UNIT $01
	OCTAVE 4
	NOTE C_, 4
	NOTE C#, 3
	NOTE D_, 3
	NOTE D#, $0A
	VOICE $01, 4, 8, 3, 6, 7
	RELEASE_VOL 2
	VIBRATO_SEMI 3
	NOTE D#, $0A
	NOTE D#, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE D#, 5
	NOTE C#, 5
	NOTE C_, 5
	NOTE C#, 5
	NOTE C_, 5
	OCTAVE 3
	NOTE A#, 5
	NOTE G#, 5
	NOTE A#, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE G#, 4
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 5
	NOTE C_, $0A
	OCTAVE 3
	NOTE C_, 5
	NOTE C#, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, $0A
	OCTAVE 2
	NOTE A#, 5
	OCTAVE 3
	NOTE C_, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 8
	REST $0C
	VOICE $05, 2, 4, 7, 5, 7
	RELEASE_VOL 3
	VIBRATO_OFF
	NOTE B_, 4
	RELEASE 9, 3
	OCTAVE 3
	NOTE C_, 3
	REST 1
	VOICE $05, 2, 0, 6, 15, 2
	DETUNE $FF
	NOTE C_, 3
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	DETUNE $00
	RELEASE $0A, 6
	ATTEN 2
	OCTAVE 3
	NOTE C_, 4
	DUTY 8
	NOTE C_HI, 2
	REST 2
	VOICE $05, 3, 8, 4, 6, 7
	RELEASE_VOL 2
	VIBRATO_SEMI 3
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 4
	REST 4
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	VIBRATO_OFF
	VOICE $05, 3, 0, 6, 9, 7
	DUTY_STEP 8, 1
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 6
	OCTAVE 3
	NOTE E_, 3
	NOTE E_, 1
	NOTE E_, 2
	VOICE $05, 3, 8, 4, 8, 6
	RELEASE_VOL 0
	VIBRATO 1, 0, 2
	DETUNE $FF
	LEN_UNIT $01
	NOTE B_, 4
	NOTE A#, 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C#, 4
	NOTE C_, 3
	NOTE C#, 3
	NOTE D#, 4
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 4
	NOTE D#, 3
	NOTE E_, 3
	NOTE F#, 4
	NOTE F_, 3
	NOTE F#, 3
	VOICE $05, 3, 8, 6, 10, 9
	RELEASE_VOL 4
	DETUNE $FF
	DUTY_STEP 0, 1
	VIBRATO_SEMI 3
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE E_, 2
	SND_RET
Snd59_Ch1_6063:
	VOICE $01, 3, 8, 2, 3, 7
	RELEASE_VOL 0
	DUTY_STEP 0, 0
	VIBRATO_OFF
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 5
	ATTEN 1
	NOTE D#, 7
	NOTE E_, 6
	ATTEN 0
	NOTE F#, 4
	VOICE $01, 3, 8, 5, 15, 5
	NOTE E_, $0A
	ATTEN 2
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 2
	NOTE B_, $0A
	ATTEN 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 8
	LOOP_START
	OCTAVE 3
	ATTEN 0
	NOTE F#, $0A
	ATTEN 2
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 2
	NOTE B_, $0A
	ATTEN 2
	SND_JUMP_N 2, Snd59_Ch1_609C
	NOTE A#, 2
	NOTE B_, 8
	ATTEN 0
	OCTAVE 3
	NOTE E_, $0A
	NOTE D#, $0A
	NOTE C#, $0A
	OCTAVE 2
	NOTE B_, $0A
Snd59_Ch1_609C:
	LOOP_END 2
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 8
	VOICE $05, 4, 0, 7, 6, 5
	DETUNE $01
	RELEASE_VOL 3
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 2
	DETUNE $00
	VOICE $05, 2, 0, 7, 10, 6
	DUTY_STEP 4, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	VOICE $05, 4, 8, 4, 6, 7
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 2
	REST 6
	VOICE $05, 3, 0, 7, 9, 6
	RELEASE_VOL 4
	REST 0
	REST 4
	NOTE E_, 2
	REST 2
	DETUNE $FE
	OCTAVE 1
	NOTE E_, 4
	SND_RET

Snd59_Ch3:
	SND_CALL Snd59_Ch3_60F8
Snd59_Ch3_60DF:
	SND_CALL Snd59_Ch3_6123
	SND_CALL Snd59_Ch3_61C9
	SND_END

Snd63_Ch3:
	TRANSPOSE_DOWN 2
	SND_CALL Snd59_Ch3_60F8
	SND_CALL Snd59_Ch3_6123
	TRANSPOSE_DOWN 1
	REST 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	SND_JUMP Snd59_Ch3_60DF
Snd59_Ch3_60F8:
	VOICE $01, 3, 4, 4, 2, 7
	DETUNE $01
	NOTE A_, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	OCTAVE 3
	NOTE B_, 5
	OCTAVE 4
	NOTE C_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE D#, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, 5
	NOTE G#, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE B_, 6
	REST $0E
	VOICE $05, 1, 1, 2, 2, 7
	DETUNE $00
	NOTE B_, 4
	SND_RET
Snd59_Ch3_6123:
	RELEASE 8, 7
	RELEASE_VOL 4
	LOOP_START
	WAVE_ALT 1, 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE F#, 2
	LOOP_END 2
	LOOP_START
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE F#, 2
	LOOP_END 3
	WAVE_ALT_OFF
	NOTE E_, 2
	REST 2
	NOTE D#, 4
	LOOP_START
	WAVE_ALT 1, 3
	NOTE G#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE C_, 2
	LOOP_END 2
	RELEASE 4, 7
	WAVE_ALT_OFF
	NOTE G#, 4
	NOTE A_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE C_, 4
	RELEASE $0A, 8
	OCTAVE 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE A#, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	REST 2
	VOICE $05, 2, 1, 2, 2, 7
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	RELEASE 9, 8
	DETUNE $FF
	WAVE 5
	NOTE C_, 3
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE_VOL 0
	NOTE E_, 2
	RELEASE_VOL 6
	NOTE G_, 2
	RELEASE_VOL 0
	NOTE D_, 2
	RELEASE_VOL 6
	NOTE G_, 2
	RELEASE 0, 0
	NOTE C_, 4
	VOICE $05, 2, 1, 2, 8, 7
	NOTE C_HI, 4
	RELEASE 3, 4
	NOTE G_, 6
	RELEASE 9, 7
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	REST 6
	WAVE_ALT 1, 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE F#, 2
	WAVE_ALT_OFF
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	WAVE_ALT 1, 3
	OCTAVE 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE D#, 2
	WAVE_ALT_OFF
	OCTAVE 2
	RELEASE 3, 4
	NOTE E_, 6
	RELEASE $0A, 7
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE E_, 2
	SND_RET
Snd59_Ch3_61C9:
	VOICE $05, 3, 4, 4, 12, 7
	REST 6
	VIBRATO 4, 4, 0
	NOTE G#, 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 6
	VOICE $05, 4, 4, 4, 13, 3
	RELEASE_VOL 0
	DETUNE $00
	NOTE G#, 3
	NOTE G_, 1
	NOTE G#, 2
	VOICE $05, 2, 4, 4, 9, 7
	RELEASE_VOL 6
	NOTE G#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 2
	VOICE $05, 3, 1, 2, 5, 6
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	NOTE C_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	NOTE E_, 2
	REST 2
	WAVE 5
	ATTEN 1
	OCTAVE 3
	NOTE E_, 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 2, 3
	NOTE G#, 2
	RELEASE 9, 6
	NOTE B_, 2
	RELEASE 2, 3
	NOTE F#, 2
	RELEASE 9, 6
	NOTE B_, 2
	NOTE E_, 4
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE E_, 3
	SND_RET

Snd59_Drm:
	SND_CALL Snd59_Drm_623A
Snd59_Drm_6226:
	SND_CALL Snd59_Drm_6240
	SND_CALL Snd59_Drm_6275

Snd0F_Sfx1:
	SND_END

Snd63_Drm:
	SND_CALL Snd59_Drm_623A
	SND_CALL Snd59_Drm_6240
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	SND_JUMP Snd59_Drm_6226
Snd59_Drm_623A:
	LEN_UNIT $05
	REST 0
	REST $0C
	DRUM $0A, 4
	SND_RET
Snd59_Drm_6240:
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 3
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 10
	DRUM $0A, 4
	DRUM $0A, 4
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 8
	LOOP_START
	DRUM 3, 2
	DRUM 5, 2
	LOOP_END 4
	DRUM 5, 3
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 4
	DRUM $0A, 4
	DRUM 5, 4
	REST $0C
	REST $0C
	DRUM 4, 4
	DRUM $0A, 0
	REST 6
	DRUM $0A, 2
	DRUM $0A, 8
	LOOP_START
	DRUM 3, 2
	DRUM 5, 2
	LOOP_END 8
	DRUM 3, 6
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 2
	SND_RET
Snd59_Drm_6275:
	LEN_UNIT $0A
	REST $0A
	REST 0
	DRUM $0A, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	REST $0A
	REST 4
	DRUM $0A, 2
	REST 0
	SND_RET

Snd5A_Ch2:
	DETUNE $01
	SND_CALL Snd5A_Ch1_6391
	RELEASE_VOL 3
	NOTE A#, 2
	VIBRATO 6, 0, 8
	NOTE A#, 1
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 2
	NOTE G_, 1
	RELEASE 5, 4
	REST 2
	NOTE A#, 1
	NOTE B_, 2
	VIBRATO 5, 0, 10
	OCTAVE 4
	NOTE D_, 3
	VIBRATO 6, 0, 8
	OCTAVE 3
	NOTE D_, 4
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd5A_Ch1_6391
	NOTE B_, 2
	VIBRATO 6, 0, 4
	NOTE B_, 1
	OCTAVE 4
	SND_CALL Snd5A_Ch2_6399
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 4
	NOTE E_, 2
	VIBRATO 6, 0, 6
	NOTE E_, 1
	SND_CALL Snd5A_Ch2_6399
	NOTE D_, 1
	NOTE G_, 2
	NOTE D_, 1
	SND_CALL Snd5A_Ch1_6391
	NOTE B_, 2
	VIBRATO 6, 0, 8
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 3
	VIBRATO 5, 0, 10
	NOTE F#, 3
	VIBRATO 6, 0, 8
	NOTE D_, 3
	VIBRATO 6, 0, 10
	NOTE E_, 3
	VIBRATO 6, 0, 8
	SND_CALL Snd5A_Ch2_6399
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 1
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 4
	NOTE C_, 2
	VIBRATO 6, 0, 4
	NOTE C_, 1
	SND_CALL Snd5A_Ch2_6399
	NOTE D_, 1
	NOTE F#, 2
	NOTE D_, 1
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 4
	SND_JUMP_N 2, Snd5A_Ch2_631F
	NOTE E_, 2
	VIBRATO 6, 0, 6
	NOTE E_, 1
	NOTE D_, 2
	NOTE D_, 2
	REST 1
	SND_CALL Snd5A_Ch1_639C
	NOTE D_, 1
	NOTE F#, 2
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 4
	NOTE A_, 3
	VIBRATO 6, 0, 4
	NOTE A_, 1
	NOTE G#, 3
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 2
	SND_CALL Snd5A_Ch1_639C
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 1
Snd5A_Ch2_631F:
	LOOP2_END 2
	NOTE D_, 2
	VIBRATO 6, 0, 4
	NOTE D_, 1
	NOTE F#, 2
	NOTE A_, 2
	REST 1
	SND_CALL Snd5A_Ch1_639C
	NOTE F#, 1
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 4
	NOTE F#, 2
	VIBRATO 6, 0, 4
	NOTE F#, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE G_, 2
	SND_CALL Snd5A_Ch1_639C
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 1
	LOOP2_START
	SND_CALL Snd5A_Ch1_639C
	SND_CALL Snd5A_Ch2_63A4
	SND_CALL Snd5A_Ch1_6391
	SND_JUMP_N 2, Snd5A_Ch2_636B
	NOTE B_, 3
	VIBRATO 6, 0, 5
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 3
	OCTAVE 3
	NOTE B_, 3
	VIBRATO 5, 0, 12
	OCTAVE 4
	NOTE E_, 3
	VIBRATO 6, 0, 5
	NOTE D_, 2
	NOTE D_, 7
Snd5A_Ch2_636B:
	LOOP2_END 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO 6, 0, 2
	NOTE D#, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE D_, 3
	SND_CALL Snd5A_Ch1_639C
	NOTE D_, 2
	NOTE D#, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE D_, 3
	DETUNE $01
	OCTAVE 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 6
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 3
	DETUNE $00
	SND_LOOP
Snd5A_Ch1_6391:
	VOICE $05, 3, 0, 7, 3, 2
	VIBRATO 5, 0, 10
	SND_RET
Snd5A_Ch2_6399:
	NOTE D_, 2
	NOTE D_, 2
	REST 1
Snd5A_Ch1_639C:
	VOICE $05, 3, 0, 7, 10, 2
	VIBRATO 7, 0, 7
	SND_RET
Snd5A_Ch2_63A4:
	NOTE E_, 3
	NOTE G_, 3
	REST 2
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	SND_RET

Snd5A_Ch1:
	RELEASE_VOL 3
	SND_CALL Snd5A_Ch1_639C
	NOTE E_, 2
	VIBRATO 6, 0, 8
	NOTE E_, 1
	NOTE E_, 3
	NOTE E_, 3
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 7
	SND_SEGNO
	LOOP2_START
	LOOP_START
	SND_CALL Snd5A_Ch1_6391
	NOTE G_, 3
	VIBRATO 6, 0, 5
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	SND_CALL Snd5A_Ch1_639C
	NOTE D_, 2
	SND_CALL Snd5A_Ch1_6391
	REST 1
	LOOP_END 2
	NOTE G_, 2
	VIBRATO 6, 0, 8
	NOTE G_, 1
	NOTE G_, 3
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 2
	SND_CALL Snd5A_Ch1_639C
	REST 2
	OCTAVE 2
	NOTE A_, 2
	REST 1
	SND_CALL Snd5A_Ch1_6391
	SND_CALL Snd5A_Ch1_647A
	REST 1
	SND_JUMP_N 2, Snd5A_Ch1_6412
	SND_CALL Snd5A_Ch1_647A
	VOICE $05, 3, 8, 6, 12, 2
	NOTE D_, 3
	NOTE D_, 1
	NOTE D_, 3
	NOTE F#, 3
	NOTE F#, 3
	NOTE G_, 3
	VOICE $05, 3, 0, 6, 10, 2
	VIBRATO 7, 0, 7
	NOTE D_, 2
	REST 4
	NOTE D_, 2
	REST 1
Snd5A_Ch1_6412:
	LOOP2_END 2
	OCTAVE 3
	NOTE A_, 3
	VIBRATO 6, 0, 5
	NOTE A_, 2
	NOTE A_, 2
	REST 1
	SND_CALL Snd5A_Ch1_639C
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 1
	NOTE A_, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE G_, 2
	REST 1
	OCTAVE 2
	NOTE B_, 2
	REST 4
	NOTE B_, 2
	REST 1
	SND_CALL Snd5A_Ch1_6391
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE E_, 9
	NOTE C_, 3
	SND_CALL Snd5A_Ch1_639C
	OCTAVE 2
	NOTE G_, 2
	LOOP_START
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 2
	LOOP_END 2
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 1
	SND_CALL Snd5A_Ch1_6391
	RELEASE 6, 5
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE E_, 9
	NOTE C_, 3
	NOTE A_, 2
	VIBRATO 6, 0, 4
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 3
	SND_CALL Snd5A_Ch1_639C
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	REST 9
	DETUNE $FF
	NOTE D_, 4
	NOTE D_, 6
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 3
	DETUNE $00
	SND_LOOP
Snd5A_Ch1_647A:
	NOTE A_, 3
	VIBRATO 6, 0, 5
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	VOICE $05, 2, 0, 6, 10, 2
	VIBRATO 7, 0, 7
	NOTE A_, 2
	VOICE $05, 3, 0, 6, 3, 3
	VIBRATO 5, 0, 10
	SND_RET

Snd5A_Ch3:
	VOICE $05, 3, 1, 2, 10, 3
	RELEASE_VOL 4
	VIBRATO 7, 0, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C#, 3
	NOTE C#, 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 3
	NOTE C_HI, 4
	SND_SEGNO
	VIBRATO 7, 0, 6
	LOOP2_START
	LOOP_START
	WAVE_ALT 1, 6
	OCTAVE 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE B_, 3
	LOOP_END 3
	LOOP_START
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE D_, 3
	OCTAVE 3
	NOTE C_, 3
	LOOP_END 3
	OCTAVE 2
	SND_JUMP_N 2, Snd5A_Ch3_64D1
	NOTE A_, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE D_, 3
	WAVE_ALT_OFF
	NOTE F#, 3
	NOTE G_, 3
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 3
Snd5A_Ch3_64D1:
	LOOP2_END 2
	WAVE_ALT_OFF
	NOTE G_, 3
	NOTE F#, 3
	NOTE E_, 3
	NOTE D_, 3
	OCTAVE 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	VOICE $05, 2, 1, 2, 10, 3
	RELEASE_VOL 4
	WAVE_ALT 1, 6
	SND_CALL Snd5A_Ch3_650A
	LOOP_START
	NOTE G_, 3
	OCTAVE 3
	NOTE D_, 3
	OCTAVE 2
	NOTE D_, 3
	NOTE C_HI, 3
	LOOP_END 2
	SND_CALL Snd5A_Ch3_650A
	WAVE_ALT_OFF
	NOTE D_, 3
	REST 6
	NOTE D_, 3
	REST 6
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 6
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 3
	NOTE F_, 3
	NOTE F#, 3
	SND_LOOP
Snd5A_Ch3_650A:
	NOTE C_, 3
	NOTE C_HI, 3
	OCTAVE 2
	NOTE G_, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE C_, 3
	NOTE C_HI, 3
	OCTAVE 2
	NOTE G_, 3
	WAVE_ALT_OFF
	NOTE C_, 3
	WAVE_ALT 1, 6
	SND_RET

Snd5A_Drm:
	LEN_UNIT $05
	DRUM $0A, 3
	DRUM 1, 3
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 3
	DRUM 1, 3
	DRUM 3, 2
	DRUM 3, 3
	DRUM 1, 1
	DRUM 1, 2
	DRUM 2, 1
	SND_SEGNO
	LOOP_START
	DRUM $0A, 3
	DRUM 1, 2
	DRUM 2, 1
	LOOP_END 30
	DRUM $0A, 3
	DRUM 1, 2
	DRUM 3, 3
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 1
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 1, 2
	DRUM 2, 1
	LOOP_END 12
	DRUM 1, 9
	DRUM 1, 9
	DRUM 1, 3
	DRUM 3, 2
	DRUM 1, 1
	DRUM 1, 2
	DRUM $0A, 4
	DRUM $0A, 3
	DRUM 1, 2
	DRUM 2, 1
	DRUM $0A, 3
	DRUM 1, 2
	DRUM 2, 1
	DRUM 1, 2
	DRUM 2, 1
	DRUM 3, 3
	SND_LOOP

Snd5B_Ch2:
	TEMPO $10
	VOICE $05, 2, 0, 9, 12, 7
	DUTY_STEP 4, 1
	NOTE A#, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 4
	NOTE F#, 6
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 4
	NOTE F#, 2
	SND_SEGNO
	SND_CALL Snd5B_Ch2_65EF
	NOTE C_, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, $0A
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE $0E, 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	PAN_LEFT 4
	NOTE A#, 2
	PAN_RIGHT 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	PAN_BOTH 0
	NOTE A#, 1
	NOTE A_, 1
	LOOP_START
	NOTE A#, 1
	PAN_LEFT 4
	NOTE A#, 1
	PAN_BOTH 0
	LOOP_END 2
	VOICE $05, 4, 4, 7, 13, 7
	DUTY_STEP 0, 1
	LOOP_START
	NOTE D_, 6
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 2
	LOOP_END 2
	RELEASE 8, 7
	OCTAVE 3
	NOTE A#, 6
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, $0A
	SND_CALL Snd5B_Ch1_660C
	SND_CALL Snd5B_Ch2_65EF
	ATTEN 5
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, $0A
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 6
	NOTE F_, 2
	NOTE D#, 6
	NOTE D#, 2
	NOTE D_, 6
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE $0A, 3
	DUTY_STEP 4, 1
	DUTY 8
	NOTE D#, 2
	NOTE D#, 2
	PAN_LEFT 4
	NOTE D#, 2
	PAN_BOTH 0
	NOTE D#, 2
	NOTE E_, 2
	PAN_RIGHT 4
	NOTE E_, 2
	PAN_BOTH 0
	NOTE E_, 2
	NOTE D#, 2
	PAN_LEFT 4
	REST 2
	NOTE D#, 2
	DUTY 0
	DUTY_STEP 8, 1
	PAN_BOTH 0
	RELEASE $0E, 7
	NOTE D_, 6
	AUTOPAN_BOTH 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	SND_LOOP
Snd5B_Ch2_65EF:
	LOOP_START
	VOICE $01, 4, 4, 7, 0, 0
	DUTY_STEP 0, 0
	RELEASE_VOL 0
	NOTE D_, 2
	NOTE D#, 3
	LEN_UNIT $05
	VIBRATO 4, 3, 1
	RELEASE $0D, 6
	NOTE D#, 5
	DUTY_STEP 0, 1
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 2
	LOOP_END 2
	RELEASE 8, 7
	SND_RET
Snd5B_Ch1_660C:
	RELEASE 0, 0
	DUTY 8
	ATTEN 4
	NOTE A#, 2
	NOTE A_, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE D_, 2
	SND_RET

Snd5B_Ch1:
	VOICE $05, 2, 0, 7, 12, 5
	DETUNE $FE
	DUTY_STEP 4, 1
	NOTE A#, 4
	DETUNE $FF
	NOTE A#, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 6
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 4
	NOTE C#, 2
	SND_SEGNO
	VOICE $05, 4, 8, 6, 10, 6
	ATTEN 3
	NOTE D#, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D#, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	ATTEN 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	REST 2
	OCTAVE 3
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE $0E, 4
	REST 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN_LEFT 4
	NOTE F_, 2
	PAN_RIGHT 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	PAN_BOTH 0
	NOTE F_, 1
	NOTE F_, 1
	LOOP_START
	NOTE F_, 1
	PAN_LEFT 4
	NOTE F_, 1
	PAN_BOTH 0
	LOOP_END 2
	LOOP_START
	DUTY 8
	RELEASE $0A, 5
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 4
	NOTE G#, 2
	ATTEN 3
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	ATTEN 3
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	LOOP_END 2
	RELEASE 8, 7
	VIBRATO 3, 3, 2
	NOTE A#, 6
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, $0A
	TRANSPOSE_DOWN $0C
	SND_CALL Snd5B_Ch1_660C
	TRANSPOSE_DOWN 0
	VOICE $05, 3, 0, 6, 8, 7
	VIBRATO 4, 3, 2
	LOOP_START
	NOTE G_, 6
	NOTE A#, 4
	NOTE G_, 4
	NOTE G_, 2
	LOOP_END 2
	DUTY 8
	NOTE D#, 8
	NOTE F_, 8
	NOTE G#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE A#, 2
	NOTE B_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 2
	NOTE D#, 2
	NOTE G#, 2
	DUTY 0
	NOTE G#, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	DUTY 8
	DUTY_STEP 4, 1
	DUTY 8
	NOTE G_, 2
	NOTE G_, 2
	PAN_LEFT 4
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G_, 2
	NOTE G#, 2
	PAN_RIGHT 4
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G#, 2
	NOTE G_, 2
	PAN_LEFT 4
	REST 2
	NOTE D#, 2
	DUTY 0
	DUTY_STEP 8, 1
	PAN_BOTH 0
	RELEASE $0E, 7
	NOTE G#, 6
	AUTOPAN_BOTH 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	SND_LOOP

Snd5B_Ch3:
	VOICE $05, 2, 7, 2, 8, 7
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 8
	NOTE A#, 2
	NOTE A#, 4
	NOTE A#, 2
	SND_SEGNO
	VOICE $05, 2, 7, 2, 9, 7
	RELEASE_VOL 4
	NOTE D#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE F#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE A#, 2
	RELEASE 4, 7
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	RELEASE 9, 7
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	LOOP_END 2
	LOOP_START
	NOTE F_, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 2
	LOOP_START
	NOTE A#, 2
	NOTE C_HI, 4
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_HI, 2
	LOOP_END 2
	NOTE D#, 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE D#, 2
	REST 4
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_LOOP
	db $FE ; unreachable byte after an end

Snd5B_Drm:
	LEN_UNIT $05
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 6
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM 3, 4
	DRUM 3, 2
	SND_SEGNO
	LEN_UNIT $05
	SND_CALL Snd5B_Drm_67E1
	DRUM 1, 1
	DRUM 1, 1
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM 3, $0A
	DRUM 2, 2
	DRUM 2, 2
	DRUM 1, 2
	SND_CALL Snd5B_Drm_67E1
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 2, 2
	DRUM $0A, 2
	DRUM 3, 2
	DRUM $0A, 4
	DRUM 3, 6
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	SND_LOOP
Snd5B_Drm_67E1:
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 2
	SND_RET

Snd5C_Ch2:
	TEMPO $40
	VOICE $05, 1, 4, 8, 10, 4
	RELEASE_VOL 4
	NOTE C_, 3
	NOTE C_, 1
	NOTE D#, 4
	NOTE C_, 4
	NOTE D#, 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, $0C
	TEMPO $00
	RELEASE $0E, 4
	DUTY_STEP 8, 1
	SND_SEGNO
	NOTE A_, 2
	NOTE A_, 4
	NOTE A_, 2
	SND_LOOP

Snd5C_Ch1:
	VOICE $05, 3, 0, 6, 10, 5
	DETUNE $01
	REST 1
	ATTEN 2
	NOTE D#, 3
	NOTE D#, 1
	NOTE F#, 4
	NOTE D#, 4
	NOTE F#, 2
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, $0B
	VOICE $05, 3, 4, 5, 10, 4
	VIBRATO 3, 4, 2
	SND_SEGNO
	NOTE C#, 8
	NOTE D_, 8
	NOTE D#, 8
	NOTE E_, 8
	SND_LOOP

Snd5C_Ch3:
	VOICE $05, 3, 4, 2, 10, 2
	RELEASE_VOL 4
	NOTE D#, 3
	NOTE D#, 1
	NOTE F#, 4
	NOTE D#, 4
	NOTE F#, 2
	NOTE D#, 1
	NOTE F#, 1
	VIBRATO 5, 0, 4
	NOTE A_, $0C
	VOICE $05, 4, 1, 2, 10, 4
	VIBRATO 4, 6, 3
	SND_SEGNO
	NOTE E_, 8
	NOTE F_, 8
	NOTE F#, 8
	NOTE G_, 8
	SND_LOOP

Snd5C_Drm:
	LEN_UNIT $05
	REST 0
	REST $0C
	SND_SEGNO
	DRUM 1, 2
	DRUM 2, 1
	DRUM 2, 1
	SND_LOOP

Snd5D_Ch2:
	TEMPO $10
	DETUNE $01
	SND_CALL Snd5D_Ch1_6900
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd5D_Ch2_6930
	NOTE G_, 3
	VIBRATO 3, 3, 3
	NOTE F#, 1
	NOTE G_, 8
	VIBRATO_SEMI 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE F_, 1
	LOOP_START
	VOICE $01, 3, 4, 8, 12, 5
	DUTY_STEP 0, 0
	NOTE F_, 1
	NOTE G_, 4
	PAN_LEFT 4
	NOTE G_, $0A
	LEN_UNIT $05
	PAN_BOTH 0
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	VIBRATO 3, 3, 2
	NOTE A_, 3
	VIBRATO 3, 3, 3
	NOTE G#, 1
	NOTE A_, 8
	VIBRATO_SEMI 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE C_, 1
	SND_CALL Snd5D_Ch2_6930
	NOTE A#, 3
	VIBRATO 3, 3, 3
	NOTE A_, 1
	NOTE A#, 8
	VOICE $05, 0, 8, 7, 14, 3
	VIBRATO_SEMI 3
	ATTEN 2
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE B_, 1
	SND_JUMP_N 2, Snd5D_Ch2_68D6
	AUTOPAN_BOTH 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 2
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	REST 1
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
	RELEASE $0C, 9
	VIBRATO 3, 1, 10
	ATTEN 0
	NOTE C_, 4
Snd5D_Ch2_68D6:
	LOOP2_END 2
	LOOP2_START
	VOICE $05, 6, 8, 7, 10, 7
	VIBRATO_OFF
	ATTEN 2
	NOTE C_, 2
	OCTAVE 5
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 6
	NOTE C_, 4
	DUTY 0
	DUTY_STEP 8, 1
	ATTEN 0
	SND_JUMP_N 2, Snd5D_Ch2_68F6
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 2
	PAN_LEFT 4
	NOTE G_, 2
Snd5D_Ch2_68F6:
	LOOP2_END 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_LOOP
Snd5D_Ch1_6900:
	VOICE $05, 4, 0, 8, 10, 7
	DUTY_STEP 4, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	AUTOPAN_BOTH 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 2
	VOICE $05, 3, 8, 8, 0, 0
	VIBRATO_OFF
	LEN_UNIT $01
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
	LEN_UNIT $05
	OCTAVE 4
	NOTE C_, 3
	LEN_UNIT $01
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	SND_RET
Snd5D_Ch2_6930:
	LOOP_START
	VOICE $01, 3, 4, 8, 12, 5
	DUTY_STEP 0, 0
	VIBRATO_SEMI 1
	NOTE G_, 1
	NOTE A_, 4
	PAN_LEFT 4
	NOTE A_, $0A
	LEN_UNIT $05
	PAN_BOTH 0
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 2
	SND_RET

Snd5D_Ch1:
	TRANSPOSE_DOWN 5
	SND_CALL Snd5D_Ch1_6900
	TRANSPOSE_UP 0
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd5D_Ch1_69F1
	OCTAVE 3
	NOTE E_, 3
	NOTE D#, 1
	NOTE E_, 6
	DUTY 8
	ATTEN 3
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	LOOP_START
	VOICE $01, 2, 4, 8, 12, 5
	VIBRATO_SEMI 1
	DETUNE $FF
	NOTE F_, 1
	NOTE G_, 4
	PAN_LEFT 4
	NOTE G_, 5
	LEN_UNIT $05
	PAN_BOTH 3
	DUTY 8
	VIBRATO 3, 4, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	VIBRATO 3, 4, 2
	LOOP_END 2
	ATTEN 1
	DUTY 4
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 2
	DUTY_STEP 8, 1
	OCTAVE 1
	LEN_UNIT $01
	NOTE C_, 4
	NOTE D_, 3
	NOTE E_, 3
	LEN_UNIT $05
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	SND_CALL Snd5D_Ch1_69F1
	OCTAVE 3
	NOTE D_, 3
	NOTE C#, 1
	NOTE D_, 6
	ATTEN 1
	DUTY 8
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	SND_JUMP_N 2, Snd5D_Ch1_69C1
	VIBRATO_SEMI 7
	PAN_LEFT 5
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 1
	VOICE $05, 2, 8, 6, 12, 9
	VIBRATO 4, 0, 4
	NOTE A#, 4
Snd5D_Ch1_69C1:
	LOOP2_END 2
	LOOP_START
	VOICE $05, 6, 8, 7, 10, 7
	VIBRATO_SEMI 7
	DETUNE $FF
	ATTEN 4
	NOTE C_, 2
	OCTAVE 5
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 6
	NOTE C_, 4
	DUTY 0
	DUTY_STEP 8, 1
	ATTEN 0
	VIBRATO_SEMI 1
	SND_JUMP_N 2, Snd5D_Ch1_69E7
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 2
	PAN_RIGHT 5
	NOTE G_, 2
	DETUNE $00
Snd5D_Ch1_69E7:
	LOOP_END 2
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_LOOP
Snd5D_Ch1_69F1:
	LOOP_START
	VOICE $01, 2, 4, 8, 12, 5
	DUTY_STEP 0, 0
	VIBRATO_SEMI 1
	DETUNE $FF
	NOTE G_, 1
	NOTE A_, 4
	PAN_LEFT 4
	NOTE A_, 5
	VOICE $05, 2, 8, 7, 12, 5
	VIBRATO 3, 4, 3
	ATTEN 3
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	LOOP_END 2
	ATTEN 1
	DUTY 4
	SND_RET

Snd5D_Ch3:
	VOICE $05, 2, 4, 2, 8, 7
	RELEASE_VOL 4
	DETUNE $FE
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	PAN_LEFT 1
	NOTE D_, 1
	PAN_BOTH 0
	NOTE C#, 1
	PAN_LEFT 1
	NOTE C#, 1
	PAN_BOTH 0
	NOTE C_, 4
	OCTAVE 1
	NOTE C_, 4
	SND_SEGNO
	LOOP2_START
	VOICE $05, 1, 4, 2, 10, 7
	RELEASE_VOL 4
	VIBRATO_OFF
	SND_CALL Snd5D_Ch3_6AAB
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP_END 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	WAVE_ALT_OFF
	LEN_UNIT $01
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 3
	NOTE E_, 3
	LEN_UNIT $05
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	SND_CALL Snd5D_Ch3_6AAB
	LOOP_START
	NOTE A#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	LOOP_END 2
	WAVE_ALT_OFF
	SND_JUMP_N 2, Snd5D_Ch3_6A8E
	NOTE C_, 2
	WAVE 2
	VIBRATO_SEMI 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO 3, 0, 4
	OCTAVE 2
	PAN_BOTH 0
	NOTE A#, 4
Snd5D_Ch3_6A8E:
	LOOP2_END 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 2
	REST 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_LOOP
Snd5D_Ch3_6AAB:
	WAVE_ALT 4, 3
	LOOP_START
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	LOOP_END 2
	SND_RET

Snd5D_Drm:
	LEN_UNIT $05
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 3, 4
	LEN_UNIT $05
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd5D_Drm_6AE7
	DRUM $0A, 2
	DRUM 2, 2
	SND_CALL Snd5D_Drm_6AE7
	DRUM 3, 4
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 8
	SND_JUMP_N 2, Snd5D_Drm_6ADA
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 8
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 4
	DRUM 3, 4
Snd5D_Drm_6ADA:
	LOOP2_END 2
	DRUM $0A, 6
	DRUM $0A, 4
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 4
	DRUM $0A, 6
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	SND_LOOP
Snd5D_Drm_6AE7:
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 4
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0A, 2
	DRUM 1, 2
	SND_RET

Snd5E_Ch2:
	VOICE $05, 1, 4, 8, 14, 4
	DUTY_STEP 8, 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	REST 2
	SND_SEGNO
	VOICE $05, 1, 4, 9, 2, 0
	RELEASE_VOL 5
	NOTE A_, 4
	RELEASE $0E, 4
	SND_CALL Snd5E_Ch2_6B55
	TRANSPOSE_UP 2
	OCTAVE 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	SND_CALL Snd5E_Ch2_6B55
	RELEASE_VOL 0
	OCTAVE 1
	NOTE D_, 4
	TRANSPOSE_UP 2
	LOOP_START
	SND_CALL Snd5E_Ch2_6B85
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 4
	SND_JUMP_N 2, Snd5E_Ch2_6B39
	TRANSPOSE_DOWN 2
	SND_CALL Snd5E_Ch2_6B85
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 6
	NOTE C#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 4
	TRANSPOSE_UP 5
Snd5E_Ch2_6B39:
	LOOP_END 2
	TRANSPOSE_DOWN 0
	VOICE $05, 4, 4, 8, 11, 4
	VIBRATO 4, 2, 3
	RELEASE_VOL 3
	DUTY_STEP 0, 1
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	REST 2
	SND_LOOP
Snd5E_Ch2_6B55:
	LOOP2_START
	OCTAVE 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_START
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 4
	LOOP_START
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 4
	SND_JUMP_N 2, Snd5E_Ch2_6B7C
	LOOP_START
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 3
	NOTE A_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
Snd5E_Ch2_6B7C:
	LOOP2_END 2
	LOOP_START
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 3
	SND_RET
Snd5E_Ch2_6B85:
	VOICE $05, 4, 8, 7, 10, 4
	VIBRATO 4, 0, 3
	RELEASE_VOL 0
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	VOICE $05, 5, 8, 2, 15, 3
	VIBRATO_OFF
	NOTE A_, 2
	SND_RET

Snd5E_Ch1:
	VOICE $05, 2, 4, 5, 10, 4
	VIBRATO 3, 4, 2
	DETUNE $FF
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	NOTE E_, 2
	REST 2
	SND_SEGNO
	VOICE $05, 2, 8, 6, 3, 5
	DUTY_STEP 8, 1
	VIBRATO 3, 0, 2
	RELEASE_VOL 1
	NOTE E_, 4
	SND_CALL Snd5E_Ch1_6BFE
	TRANSPOSE_UP 2
	OCTAVE 2
	NOTE E_, 4
	SND_CALL Snd5E_Ch1_6BFE
	OCTAVE 2
	NOTE A_, 4
	VOICE $05, 4, 4, 2, 6, 7
	VIBRATO 4, 0, 6
	TRANSPOSE_DOWN 0
	RELEASE_VOL 0
	DETUNE $FF
	REST 3
	NOTE G#, 4
	NOTE E_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	REST 0
	OCTAVE 4
	NOTE E_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 4
	REST 0
	OCTAVE 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	REST $0D
	VOICE $05, 3, 4, 6, 11, 4
	VIBRATO 4, 2, 3
	RELEASE_VOL 3
	DUTY_STEP 0, 1
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	NOTE E_, 2
	REST 2
	SND_LOOP
Snd5E_Ch1_6BFE:
	LOOP_START
	RELEASE 3, 4
	OCTAVE 2
	NOTE A_, 4
	NOTE A#, 4
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	NOTE C#, 4
	NOTE E_, 4
	SND_JUMP_N 2, Snd5E_Ch1_6C22
	ATTEN 2
	RELEASE $0E, 3
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 6
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 5
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	ATTEN 0
Snd5E_Ch1_6C22:
	LOOP_END 2
	ATTEN 2
	RELEASE $0E, 3
	OCTAVE 5
	NOTE D_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	REST 2
	ATTEN 0
	SND_RET

Snd5E_Ch3:
	VOICE $05, 4, 1, 2, 10, 4
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	REST 2
	OCTAVE 2
	SND_SEGNO
	VOICE $05, 2, 7, 2, 2, 3
	VIBRATO 4, 2, 3
	SND_CALL Snd5E_Ch3_6C7F
	TRANSPOSE_UP $0E
	VOICE $05, 2, 8, 2, 2, 3
	SND_CALL Snd5E_Ch3_6C7F
	VOICE $01, 5, 2, 2, 0, 0
	LOOP_START
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END 10
	VOICE $05, 3, 1, 2, 10, 4
	TRANSPOSE_UP 2
	SND_CALL Snd5E_Ch3_6CC0
	TRANSPOSE_DOWN 2
	SND_CALL Snd5E_Ch3_6CD2
	TRANSPOSE_UP 5
	SND_CALL Snd5E_Ch3_6CC0
	TRANSPOSE_DOWN 0
	OCTAVE 3
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	REST 2
	SND_LOOP
Snd5E_Ch3_6C7F:
	RELEASE_VOL 4
	NOTE A_, 4
	RELEASE $0A, 4
	LOOP_START
	OCTAVE 3
	NOTE D_, 8
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	RELEASE_VOL 0
	NOTE A_, 3
	NOTE G#, 1
	NOTE A_, 3
	NOTE G#, 1
	RELEASE_VOL 4
	NOTE A_, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE_VOL 0
	NOTE E_, 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE D#, 1
	RELEASE_VOL 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	RELEASE_VOL 0
	OCTAVE 3
	SND_JUMP_N 2, Snd5E_Ch3_6CB7
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	RELEASE_VOL 4
Snd5E_Ch3_6CB7:
	LOOP_END 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	REST 2
	SND_RET
Snd5E_Ch3_6CC0:
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 4
	RELEASE_VOL 6
	OCTAVE 1
	NOTE A_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 4
	RELEASE_VOL 4
	SND_RET
Snd5E_Ch3_6CD2:
	OCTAVE 3
	NOTE F#, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE A_, 4
	RELEASE_VOL 6
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 4
	OCTAVE 3
	RELEASE_VOL 4
	SND_RET

Snd5E_Drm:
	LEN_UNIT $05
	DRUM 1, 2
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 2
	DRUM 1, 1
	DRUM 2, 1
	SND_SEGNO
	DRUM 3, 4
	LEN_UNIT $01
	LOOP_START
	DRUM 2, 3
	DRUM 2, 2
	LOOP_END 4
	LOOP2_START
	LEN_UNIT $05
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 30
	DRUM 1, 4
	LEN_UNIT $01
	LOOP_START
	DRUM 2, 3
	DRUM 2, 2
	LOOP_END 4
	LOOP2_END 2
	LEN_UNIT $05
	LOOP_START
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 8
	LOOP_END 3
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 1
	DRUM 2, 1
	LOOP_END 2
	SND_LOOP

Snd5F_Ch2:
	VOICE $05, 4, 8, 7, 9, 4
	RELEASE_VOL 4
	VIBRATO 6, 0, 2
	DUTY_STEP 0, 1
	NOTE F_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	REST 2
	NOTE C_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 3
	NOTE D_, 2
	NOTE E_, 1
	REST 2
	NOTE F_, 1
	REST 2
	NOTE C_HI, 1
	REST 3
	OCTAVE 2
	NOTE F_, 2
	SND_END

Snd5F_Ch1:
	VOICE $05, 3, 8, 6, 9, 4
	RELEASE_VOL 4
	DETUNE $01
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A_, 1
	REST 2
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE D_, 3
	NOTE F_, 4
	NOTE A_, 3
	NOTE A#, 2
	NOTE A#, 1
	REST 2
	OCTAVE 4
	NOTE C_, 1
	REST 2
	NOTE C_HI, 1
	REST 3
	OCTAVE 3
	NOTE F_, 2
	SND_END

Snd5F_Ch3:
	VOICE $05, 2, 1, 2, 6, 4
	VIBRATO_SEMI 1
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE A#, 3
	NOTE F_, 3
	NOTE A#, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE E_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	REST 3
	NOTE F_, 3
	SND_END

Snd5F_Drm:
	LEN_UNIT $05
	LOOP_START
	DRUM 3, 3
	DRUM 1, 2
	DRUM 1, 1
	LOOP_END 5
	DRUM 3, 2
	DRUM 1, 3
	DRUM 1, 3
	DRUM 1, 4
	DRUM $0A, 2
	SND_END

Snd60_Ch2:
	SND_CALL Snd60_Ch2_7927
	RELEASE 0, 0
	ATTEN 3
	NOTE E_, 3
	NOTE D#, 2
	TEMPO $10
	NOTE D_, 3
	NOTE C#, 2
	TEMPO $20
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 2
	TEMPO $40
	NOTE A#, 3
	NOTE A_, 2
	TEMPO $10
	LEN_UNIT $06
	NOTE G#, 3
	NOTE G_, 2
	TEMPO $40
	NOTE F#, 3
	TEMPO $70
	NOTE F_, 2
	TEMPO $80
	NOTE D_, 4
	TEMPO $00
	SND_JUMP Snd69_Ch2

Snd60_Ch1:
	SND_CALL Snd60_Ch1_79D8
	RELEASE $0A, 7
	SND_CALL Snd60_Ch1_6DCA
	SND_JUMP Snd69_Ch1

Snd60_Ch3:
	SND_CALL Snd60_Ch3_7A40
	VIBRATO 1, 0, 2
	SND_CALL Snd60_Ch1_6DCA
	SND_JUMP Snd69_Ch3
Snd60_Ch1_6DCA:
	OCTAVE 4
	NOTE G_, 3
	NOTE F#, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE D#, 3
	NOTE D_, 2
	NOTE C#, 3
	NOTE C_, 2
	LEN_UNIT $06
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 2
	NOTE A_, 3
	NOTE G#, 2
	VIBRATO 1, 0, 10
	RELEASE 0, 0
	NOTE G_, 4
	SND_RET

Snd60_Drm:
	LEN_UNIT $03
	DRUM $0A, $0F
	DRUM 5, 5
	DRUM $0A, $0F
	DRUM 5, 5
	DRUM 5, 5
	REST $0F
	LEN_UNIT $06
	REST $0E
	SND_JUMP Snd69_Drm

Snd61_Ch2:
	VOICE $06, 4, 8, 6, 10, 3
	RELEASE_VOL 3
	SND_SEGNO
	NOTE D_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	SND_LOOP

Snd61_Ch1:
	SND_SEGNO
	LOOP_START
	VOICE $06, 3, 8, 6, 10, 3
	RELEASE_VOL 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	LOOP_END 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	SND_LOOP

Snd61_Ch3:
	VOICE $06, 2, 2, 2, 8, 7
	RELEASE_VOL 4
	VIBRATO_SEMI 3
	SND_SEGNO
	LOOP_START
	REST 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE F_, 2
	LOOP_END 2
	LOOP_START
	REST 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	LOOP_END 2
	SND_LOOP

Snd62_Ch2:
	TEMPO $30
	VOICE $02, 2, 0, 8, 10, 3
	RELEASE_VOL 4
	REST $0C
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 7
	NOTE E_, 4
	PAN_LEFT 1
	NOTE E_, 8
	PAN_BOTH 0
	NOTE E_, 4
	NOTE D#, 1
	NOTE F_, 7
	NOTE D#, 4
	PAN_LEFT 1
	NOTE D#, 4
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 4
	LEN_UNIT $04
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 4
	NOTE E_, 0
	SND_END

Snd62_Ch1:
	VOICE $02, 2, 8, 8, 10, 3
	DUTY_STEP 4, 1
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	REST $0C
	NOTE C_, $0C
	OCTAVE 1
	NOTE E_, $0C
	NOTE F_, $0C
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	LEN_UNIT $04
	NOTE G#, 4
	NOTE G#, 2
	NOTE G_, 4
	NOTE C_, 0
	SND_END

Snd62_Ch3:
	VOICE $02, 3, 4, 2, 10, 3
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	REST $0C
	NOTE D#, 1
	NOTE E_, 7
	NOTE G_, 4
	PAN_LEFT 1
	NOTE G_, 8
	PAN_BOTH 0
	NOTE G_, 4
	NOTE G_, 1
	NOTE A_, 7
	NOTE G_, 4
	PAN_LEFT 1
	NOTE G_, 4
	PAN_BOTH 0
	NOTE C_, 4
	NOTE D_, 4
	LEN_UNIT $04
	NOTE D#, 4
	NOTE C_, 2
	NOTE D_, 4
	NOTE C_, 0
	SND_END

Snd62_Drm:
	LEN_UNIT $04
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 3, 6
	DRUM 1, 4
	DRUM 2, 2
	DRUM 3, 6
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 3, 6
	DRUM 3, 4
	DRUM 3, $0C
	SND_END

Snd64_Ch2:
	VOICE $02, 4, 0, 10, 10, 7
	VIBRATO 10, 0, 7
	RELEASE_VOL 0
	DUTY_STEP 8, 4
	NOTE F_, 8
	NOTE D#, 9
	NOTE D_, $0A
	NOTE C#, $0B
	LEN_UNIT $08
	NOTE C_, 0
	VIBRATO_OFF
	SND_END

Snd64_Ch1:
	DETUNE $FD
	VOICE $02, 4, 0, 3, 10, 7
	VIBRATO 10, 0, 6
	RELEASE_VOL 0
	DUTY_STEP 8, 4
	PAN_LEFT 0
	NOTE F_, $0C
	NOTE D#, 9
	NOTE D_, $0A
	NOTE C#, $0B
	LEN_UNIT $08
	NOTE C_, $0F
	VIBRATO_OFF
	DETUNE $00
	SND_END

Snd64_Ch3:
	LEN_UNIT $04
	REST $0C
	REST 9
	LEN_UNIT $08
	REST $0F
	SND_END

Snd64_Drm:
	SND_END

Snd65_Ch2:
	VOICE $03, 3, 0, 7, 12, 4
	DUTY_STEP 8, 1
	VIBRATO_SEMI 3
	NOTE A#, 1
	AUTOPAN_BOTH 4
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	PAN_BOTH 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	AUTOPAN_BOTH 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	VOICE $06, 3, 8, 7, 12, 6
	VIBRATO 3, 2, 1
	SND_CALL Snd65_Ch2_71E5

Snd6D_Ch2:
	SND_SEGNO
	SND_CALL Snd65_Ch2_6FF1
	NOTE E_, 2
	NOTE G_, 2
	ATTEN 5
	PAN_LEFT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE E_, 2
	PAN_LEFT 5
	NOTE E_, 2
	SND_CALL Snd65_Ch2_6FF1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 3
	VIBRATO_OFF
	RELEASE 0, 0
	DUTY_STEP 0, 0
	DUTY 8
	ATTEN 2
	NOTE F_, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 2
	SND_CALL Snd65_Ch2_6FF1
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $0E, 6
	NOTE G_, 4
	VOICE $06, 4, 4, 7, 8, 6
	DUTY_STEP 0, 0
	RELEASE_VOL 4
	VIBRATO 3, 2, 1
	OCTAVE 4
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 3
	NOTE D_, 1
	NOTE E_, 2
	NOTE D_, 2
	VOICE $06, 4, 4, 7, 14, 3
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	RELEASE_VOL 0
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 2
	NOTE G_, 2
	AUTOPAN_BOTH 3
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	VOICE $06, 3, 4, 7, 10, 4
	VIBRATO_SEMI 1
	RELEASE_VOL 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	VOICE $06, 3, 0, 7, 0, 0
	VIBRATO_OFF
	ATTEN 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	ATTEN 1
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	VOICE $06, 4, 4, 7, 10, 5
	VIBRATO_SEMI 1
	RELEASE_VOL 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 2
	VIBRATO_OFF
	DUTY 0
	RELEASE_VOL 0
	ATTEN 2
	NOTE C_, 2
	NOTE D_, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE F_, 1
	NOTE F#, 1
	RELEASE_VOL 4
	DUTY_STEP 8, 1
	LOOP_START
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	LOOP_END 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	VOICE $06, 4, 0, 7, 14, 7
	RELEASE_VOL 0
	VIBRATO_SEMI 3
	SND_CALL Snd65_Ch1_7012
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	VIBRATO_OFF
	DUTY_STEP 0, 0
	DUTY 4
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_LOOP
Snd65_Ch2_6FF1:
	VOICE $06, 4, 4, 7, 8, 6
	DUTY_STEP 0, 0
	RELEASE_VOL 4
	VIBRATO 3, 2, 1
	NOTE C_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 3
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 2
	VOICE $06, 4, 0, 7, 14, 3
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	RELEASE_VOL 0
	SND_RET
Snd65_Ch1_7012:
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	SND_RET

Snd65_Ch1:
	VOICE $06, 3, 0, 7, 12, 4
	DUTY_STEP 8, 1
	RELEASE_VOL 3
	DETUNE $FF
	VIBRATO_SEMI 1
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	RELEASE_VOL 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	RELEASE_VOL 3
	NOTE A_, 2
	NOTE G#, 2
	VOICE $06, 3, 8, 5, 12, 6
	VIBRATO 4, 1, 1
	RELEASE_VOL 0
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 4

Snd6D_Ch1:
	SND_SEGNO
	SND_CALL Snd65_Ch1_7119
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	SND_CALL Snd65_Ch1_7119
	NOTE F_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE C_, 2
	RELEASE 0, 0
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE E_, 2
	SND_CALL Snd65_Ch1_7119
	VOICE $06, 4, 0, 6, 14, 3
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	RELEASE_VOL 0
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0E, 6
	OCTAVE 4
	NOTE D_, 4
	VOICE $06, 3, 4, 7, 14, 3
	VIBRATO 3, 2, 1
	DUTY_STEP 0, 0
	NOTE F_, 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 2
	NOTE F_, 3
	NOTE F_, 1
	NOTE A_, 2
	NOTE F_, 2
	VOICE $06, 2, 0, 6, 14, 3
	VIBRATO_SEMI 1
	DUTY_STEP 8, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	AUTOPAN_BOTH 4
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	VOICE $06, 3, 4, 5, 14, 7
	VIBRATO_SEMI 2
	NOTE A_, 4
	NOTE D#, 4
	NOTE A_, 4
	NOTE D#, 4
	VOICE $06, 3, 0, 7, 14, 5
	VIBRATO_OFF
	ATTEN 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	VOICE $06, 3, 4, 6, 14, 7
	VIBRATO_SEMI 2
	NOTE A_, 4
	NOTE D#, 4
	NOTE A_, 4
	DUTY 0
	VIBRATO_OFF
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	LOOP_START
	OCTAVE 3
	NOTE G_, 2
	PAN_LEFT 3
	NOTE C_HI, 2
	OCTAVE 3
	PAN_BOTH 0
	NOTE D_, 2
	LOOP_END 2
	NOTE G_, 2
	PAN_LEFT 3
	NOTE C_HI, 2
	VOICE $06, 4, 0, 6, 8, 7
	RELEASE_VOL 0
	VIBRATO_SEMI 3
	DETUNE $01
	DUTY_STEP 8, 1
	PAN_LEFT 3
	REST 3
	SND_CALL Snd65_Ch1_7012
	NOTE G_, 1
	DETUNE $00
	PAN_BOTH 0
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	VIBRATO_OFF
	DUTY_STEP 0, 0
	DUTY 4
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	SND_LOOP
Snd65_Ch1_7119:
	VOICE $06, 3, 4, 5, 14, 3
	DUTY_STEP 0, 0
	VIBRATO 3, 2, 1
	NOTE G_, 3
	NOTE G_, 1
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE E_, 1
	NOTE C_, 2
	NOTE E_, 2
	VOICE $06, 3, 8, 4, 14, 3
	SND_RET

Snd65_Ch3:
	VOICE $06, 0, 1, 2, 8, 7
	RELEASE_VOL 4
	OCTAVE 3
	LOOP_START
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 4
	RELEASE_VOL 0
	SND_CALL Snd65_Ch2_71E5

Snd6D_Ch3:
	SND_SEGNO
	SND_CALL Snd65_Ch3_71C1
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	WAVE_ALT_OFF
	OCTAVE 1
	NOTE G_, 2
	NOTE C_, 2
	WAVE_ALT 4, 3
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE B_, 2
	RELEASE 0, 0
	WAVE_ALT_OFF
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE G_, 2
	SND_CALL Snd65_Ch3_71C1
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE B_, 2
	WAVE_ALT_OFF
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE C_HI, 2
	REST 2
	VOICE $06, 0, 4, 2, 10, 7
	RELEASE_VOL 4
	WAVE_ALT 4, 3
	SND_CALL Snd65_Ch3_71DB
	LOOP_START
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_END 2
	SND_CALL Snd65_Ch3_71DB
	WAVE_ALT_OFF
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 1
	LOOP_END 4
	RELEASE_VOL 0
	RELEASE 4, 7
	WAVE 2
	VIBRATO 11, 0, 8
	OCTAVE 2
	NOTE G_, 8
	NOTE G#, 8
	NOTE F_, 8
	NOTE F_, 4
	VIBRATO_OFF
	OCTAVE 1
	NOTE F_, 4
	VIBRATO 11, 0, 8
	OCTAVE 2
	NOTE G_, 4
	VIBRATO_OFF
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	WAVE 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	SND_LOOP
Snd65_Ch3_71C1:
	VOICE $06, 2, 4, 2, 10, 7
	RELEASE_VOL 4
	WAVE_ALT 4, 3
	NOTE C_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_END 3
	SND_RET
Snd65_Ch3_71DB:
	LOOP_START
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 2
	SND_RET
Snd65_Ch2_71E5:
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 4
	SND_RET

Snd65_Drm:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 4
	DRUM 3, 8
	DRUM 3, 2
	DRUM 5, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1

Snd6D_Drm:
	SND_SEGNO
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 14
	DRUM $0A, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 2
	DRUM 1, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 12
	DRUM $0A, 2
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 4
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 2
	DRUM 1, 2
	LOOP_END 10
	DRUM 4, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 4, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0A, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	LOOP_START
	DRUM $0A, 4
	LOOP_END 9
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 3
	DRUM 1, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	SND_LOOP

Snd66_Ch2:
	TRANSPOSE_UP 1
	TEMPO $08
	VOICE $06, 3, 0, 5, 13, 2
	AUTOPAN_BOTH 0
	VIBRATO_OFF
	DUTY_STEP 0, 0
	RELEASE_VOL 0
	LOOP2_START
	LOOP_START
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	LOOP_END 5
	NOTE C_, 1
	LOOP2_END 3
	LOOP_START
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	LOOP_END 4
	NOTE C_, 1
	NOTE C_, 1

Snd6E_Ch2:
	TEMPO $08
	TRANSPOSE_UP 1
	LOOP2_START
	LOOP_START
	SND_CALL Snd66_Ch1_731D
	SND_CALL Snd66_Ch2_72FB
	SND_JUMP_N 2, Snd66_Ch2_7272
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, $0E
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 0
Snd66_Ch2_7272:
	LOOP_END 2
	NOTE D_, 2
	NOTE D#, $0E
	NOTE D#, 2
	NOTE F_, 0
	LOOP2_END 2
	ATTEN 4
	NOTE F_, 2
	LOOP2_START
	SND_CALL Snd66_Ch1_736F
	NOTE E_, 2
	NOTE G_, 2
	PAN_LEFT 4
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G_, 2
	NOTE A_, 2
	NOTE F#, 2
	PAN_RIGHT 4
	NOTE F#, 2
	PAN_BOTH 0
	NOTE F#, 2
	VOICE $06, 6, 4, 7, 10, 7
	SND_CALL Snd66_Ch1_735C
	NOTE C#, 1
	SND_JUMP_N 2, Snd66_Ch2_72A2
	SND_CALL Snd66_Ch1_7367
	NOTE D_, 1
	TRANSPOSE_UP 5
Snd66_Ch2_72A2:
	LOOP2_END 2
	TRANSPOSE_UP 1
	ATTEN 1
	VIBRATO_OFF
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP2_START
	DUTY_STEP 8, 1
	RELEASE_VOL 0
	SND_CALL Snd66_Ch2_733D
	NOTE C_, 6
	VIBRATO_SEMI 3
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	PAN_RIGHT 4
	NOTE G_, 2
	VIBRATO_SEMI 1
	PAN_BOTH 0
	DUTY 0
	NOTE A_, 1
	NOTE A_, 1
	VIBRATO 6, 0, 2
	PAN_BOTH 0
	DUTY 4
	ATTEN 1
	NOTE B_, 2
	NOTE A_, 6
	SND_CALL Snd66_Ch2_733D
	NOTE C_, 4
	NOTE D_, 2
	SND_JUMP_N 2, Snd66_Ch2_72F6
	RELEASE 6, 7
	NOTE E_, 8
	DUTY 0
	DUTY_STEP 4, 1
	RELEASE 3, 1
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
Snd66_Ch2_72F6:
	LOOP2_END 2
	SND_JUMP Snd66_Ch2
Snd66_Ch2_72FB:
	VOICE $06, 3, 0, 7, 10, 7
	DUTY_STEP 8, 2
	VIBRATO_SEMI 3
	RELEASE_VOL 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	VOICE $06, 3, 4, 7, 7, 7
	DUTY_STEP 0, 0
	RELEASE_VOL 0
	VIBRATO 3, 3, 2
	SND_RET
Snd66_Ch1_731D:
	VOICE $06, 4, 0, 7, 10, 3
	DUTY_STEP 4, 1
	VIBRATO 6, 0, 4
	RELEASE_VOL 0
	NOTE C_, 4
	NOTE C_, 2
	VOICE $01, 3, 0, 5, 0, 0
	DUTY_STEP 0, 0
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
Snd66_Ch2_733D:
	VOICE $06, 3, 0, 7, 10, 6
	VIBRATO_SEMI 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	PAN_LEFT 4
	NOTE C_, 2
	VIBRATO_SEMI 1
	PAN_BOTH 0
	DUTY 0
	NOTE C_, 1
	NOTE C_, 1
	VIBRATO 6, 0, 2
	DUTY 4
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	SND_RET
Snd66_Ch1_735C:
	RELEASE_VOL 1
	ATTEN 4
	NOTE B_, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_RET
Snd66_Ch1_7367:
	NOTE C#, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_RET
Snd66_Ch1_736F:
	VOICE $06, 3, 8, 7, 10, 2
	DUTY_STEP 8, 1
	RELEASE_VOL 0
	VIBRATO 6, 0, 1
	DETUNE $00
	SND_RET

Snd66_Ch1:
	TRANSPOSE_UP 1
	VOICE $06, 2, 4, 7, 13, 1
	AUTOPAN 0
	VIBRATO_OFF
	RELEASE_VOL 0
	LOOP2_START
	NOTE C_, 1
	NOTE C_, 1
	SND_CALL Snd66_Ch1_74AF
	SND_JUMP_N 4, Snd66_Ch1_7395
	NOTE C_HI, 1
	NOTE G_, 1
Snd66_Ch1_7395:
	LOOP2_END 4

Snd6E_Ch1:
	LOOP2_START
	TRANSPOSE_DOWN 4
	SND_CALL Snd66_Ch1_731D
	SND_CALL Snd66_Ch1_747B
	VIBRATO_SEMI 2
	ATTEN 2
	SND_CALL Snd66_Ch1_746B
	NOTE F_, 1
	NOTE F_, 1
	SND_CALL Snd66_Ch1_746B
	TRANSPOSE_DOWN 4
	SND_CALL Snd66_Ch1_731D
	SND_CALL Snd66_Ch1_747B
	VIBRATO_SEMI 2
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	LOOP_START
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE G_, 1
	LOOP_END 5
	OCTAVE 4
	NOTE C_, 1
	LOOP_START
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 4
	NOTE C_HI, 1
	LOOP2_END 2
	NOTE C_, 1
	NOTE C_, 1
	LOOP2_START
	SND_CALL Snd66_Ch1_736F
	NOTE C_, 2
	NOTE E_, 2
	PAN_LEFT 4
	NOTE E_, 2
	PAN_BOTH 0
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	PAN_RIGHT 4
	NOTE D_, 2
	PAN_BOTH 0
	NOTE D_, 2
	DETUNE $01
	VOICE $06, 0, 4, 7, 10, 7
	ATTEN 5
	OCTAVE 3
	VIBRATO_SEMI 2
	REST 1
	AUTOPAN 0
	SND_CALL Snd66_Ch1_735C
	SND_JUMP_N 2, Snd66_Ch1_73F9
	NOTE C#, 1
	SND_CALL Snd66_Ch1_7367
	TRANSPOSE_UP 5
Snd66_Ch1_73F9:
	LOOP2_END 2
	TRANSPOSE_UP 1
	PAN_BOTH 0
	ATTEN 1
	VIBRATO_SEMI 1
	LOOP_START
	OCTAVE 4
	NOTE C#, 2
	LOOP_END 4
	LOOP2_START
	SND_CALL Snd66_Ch1_7493
	VIBRATO_SEMI 1
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE E_, 1
	VIBRATO_SEMI 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE E_, 1
	SND_JUMP_N 2, Snd66_Ch1_7450
	SND_CALL Snd66_Ch1_7493
	DUTY 8
	VIBRATO_SEMI 1
	VIBRATO_SEMI 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 1
	DUTY 0
	VIBRATO_OFF
	RELEASE 3, 1
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE G_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE E_, 1
Snd66_Ch1_7450:
	LOOP2_END 2
	VIBRATO_SEMI 1
	DUTY 8
	OCTAVE 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_JUMP Snd66_Ch1
Snd66_Ch1_746B:
	OCTAVE 3
	NOTE A#, 1
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	LOOP_END 2
	OCTAVE 4
	NOTE A#, 1
	SND_RET
Snd66_Ch1_747B:
	VOICE $06, 0, 4, 6, 10, 7
	RELEASE_VOL 2
	TRANSPOSE_UP 1
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END 4
	NOTE G_, 1
	NOTE G_, 1
	SND_RET
Snd66_Ch1_7493:
	VOICE $06, 3, 8, 6, 10, 7
	DUTY_STEP 4, 1
	VIBRATO_SEMI 1
	RELEASE_VOL 2
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	VIBRATO_SEMI 2
	DUTY 0
	LOOP_END 2
	SND_RET
Snd66_Ch1_74AF:
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_, 1
	LOOP_END 2
	SND_RET

Snd66_Ch3:
	TRANSPOSE_UP 1
	VOICE $06, 1, 4, 2, 12, 7
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	DETUNE $FF
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 12
	VIBRATO_OFF
	AUTOPAN_BOTH 0
	ATTEN 2
	SND_CALL Snd66_Ch1_74AF
	NOTE C_HI, 1
	NOTE G_, 1
	VIBRATO_SEMI 1
	PAN_BOTH 0

Snd6E_Ch3:
	TRANSPOSE_UP 1
	LOOP2_START
	SND_CALL Snd66_Ch3_753A
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 11
	NOTE C_, 2
	SND_CALL Snd66_Ch3_753A
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 3
	NOTE C_, 2
	RELEASE_VOL 0
	OCTAVE 1
	NOTE A#, 4
	RELEASE_VOL 4
	LOOP_START
	NOTE C_HI, 2
	NOTE A#, 2
	LOOP_END 3
	RELEASE_VOL 0
	NOTE A_, 4
	RELEASE_VOL 4
	LOOP_START
	NOTE C_HI, 2
	NOTE A_, 2
	LOOP_END 3
	LOOP2_END 2
	NOTE A_, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 8
	TRANSPOSE_UP 5
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 6
	TRANSPOSE_UP 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP2_START
	SND_CALL Snd66_Ch3_754A
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 2
	SND_CALL Snd66_Ch3_754A
	SND_JUMP_N 2, Snd66_Ch3_7535
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 4
Snd66_Ch3_7535:
	LOOP2_END 2
	SND_JUMP Snd66_Ch3
Snd66_Ch3_753A:
	VOICE $06, 2, 7, 2, 12, 7
	RELEASE_VOL 0
	NOTE C_, 4
	RELEASE_VOL 4
	NOTE C_HI, 2
	LOOP_START
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 3
	SND_RET
Snd66_Ch3_754A:
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_HI, 2
	SND_RET

Snd66_Drm:
	LEN_UNIT $06
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 12
	REST $0E

Snd6E_Drm:
	LOOP2_START
	LEN_UNIT $06
	DRUM 3, 4
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 6
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 3, 4
	DRUM $0A, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	LOOP_END 6
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	LOOP2_END 2
	DRUM 5, 1
	DRUM 5, 1
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 14
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	LOOP2_START
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 2
	LOOP2_END 6
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 2
	LOOP_START
	DRUM 5, 1
	LOOP_END 6
	SND_JUMP Snd66_Drm

Snd67_Ch2:
	LOOP_START
	VOICE $09, 4, 4, 8, 10, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	TRANSPOSE_DOWN $0C
	LOOP_END 2
	TRANSPOSE_DOWN 0
	VOICE $09, 1, 8, 9, 2, 7
	VIBRATO 3, 2, 4
	NOTE G_, 8
	RELEASE $0A, 2
	RELEASE_VOL 3
	NOTE C_HI, 0
Snd67_Ch2_75C6:
	LOOP2_START
	VOICE $01, 5, 8, 5, 10, 2
	SND_CALL Snd67_Ch1_766C
	REST 4
	VOICE $09, 2, 8, 8, 2, 7
	VIBRATO 3, 1, 7
	RELEASE_VOL 0
	ATTEN 2
	NOTE B_, 8
	VOICE $06, 3, 4, 8, 0, 0
	SND_CALL Snd67_Ch1_7656
	VOICE $09, 3, 8, 8, 2, 7
	ATTEN 2
	NOTE D_, 8
	VOICE $06, 3, 4, 8, 0, 0
	SND_JUMP_N 2, Snd67_Ch2_75F4
	TRANSPOSE_UP 3
	SND_CALL Snd67_Ch1_7656
Snd67_Ch2_75F4:
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	TRANSPOSE_UP 2
	SND_CALL Snd67_Ch1_7656
	TRANSPOSE_DOWN 0

Snd6F_Ch2:
	LOOP_START
	VOICE $09, 3, 4, 7, 12, 2
	VIBRATO 6, 0, 8
	RELEASE_VOL 0
	NOTE E_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	VOICE $09, 2, 0, 7, 2, 2
	VIBRATO 3, 1, 6
	NOTE C#, 4
	NOTE C#, 4
	LOOP_END 2
	LOOP2_START
	VOICE $09, 2, 0, 7, 8, 7
	VIBRATO_OFF
	NOTE C_, 8
	TRANSPOSE_UP $0C
	SND_CALL Snd67_Ch1_7687
	VOICE $09, 1, 0, 7, 8, 7
	NOTE F#, 8
	TRANSPOSE_DOWN 6
	SND_CALL Snd67_Ch1_7687
	TRANSPOSE_DOWN 0
	LOOP2_END 2
	VOICE $09, 5, 4, 7, 6, 7
	DUTY_STEP 4, 1
	VIBRATO 3, 1, 1
	RELEASE_VOL 2
	SND_CALL Snd67_Ch2_76A2
	TRANSPOSE_DOWN 9
	SND_CALL Snd67_Ch1_76BC
	TRANSPOSE_DOWN 0
	RELEASE_VOL 0
	REST 8
	SND_JUMP Snd67_Ch2_75C6
Snd67_Ch1_7656:
	ATTEN 4
	NOTE D_, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE D#, 1
	SND_RET
Snd67_Ch1_766C:
	RELEASE_VOL 0
	VIBRATO_SEMI 1
	NOTE D#, 2
	NOTE E_, 0
	LEN_UNIT $09
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	LEN_UNIT $01
	NOTE D#, 2
	NOTE E_, 0
	LEN_UNIT $09
	NOTE G_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	SND_RET
Snd67_Ch1_7687:
	VOICE $06, 4, 4, 8, 0, 0
	ATTEN 4
	NOTE C_, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 5
	NOTE C#, 1
	SND_RET
Snd67_Ch2_76A2:
	ATTEN 4
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 2
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 2
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	NOTE F_, 2
	ATTEN 3
	NOTE F_, 2
	NOTE E_, 2
	SND_RET
Snd67_Ch1_76BC:
	OCTAVE 5
	ATTEN 4
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	SND_RET

Snd67_Ch1:
	VOICE $09, 4, 4, 5, 6, 1
	DETUNE $01
	AUTOPAN 0
	NOTE G#, 2
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	VOICE $09, 2, 4, 7, 2, 7
	LOOP_START
	NOTE D_, 1
	NOTE D#, 1
	LOOP_END 4
	RELEASE $0A, 2
	RELEASE_VOL 3
	VIBRATO 5, 0, 4
	NOTE D_, 0
Snd67_Ch1_76FC:
	LOOP2_START
	LEN_UNIT $09
	REST 1
	DETUNE $01
	DUTY_STEP 0, 0
	VOICE $01, 5, 8, 2, 10, 2
	SND_CALL Snd67_Ch1_766C
	REST 3
	SND_CALL Snd67_Ch1_77AA
	ATTEN 4
	NOTE B_, 1
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	ATTEN 2
	NOTE C#, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 4
	NOTE C#, 1
	NOTE C_, 1
	SND_CALL Snd67_Ch1_77AA
	OCTAVE 3
	SND_CALL Snd67_Ch1_7656
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	TRANSPOSE_DOWN 0

Snd6F_Ch1:
	LOOP_START
	VOICE $09, 3, 0, 7, 12, 2
	VIBRATO 6, 0, 8
	RELEASE_VOL 0
	NOTE C_, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	DUTY 8
	VIBRATO 4, 2, 1
	RELEASE 8, 7
	NOTE F_, 4
	NOTE F_, 4
	LOOP_END 2
	LOOP2_START
	VOICE $09, 2, 0, 7, 8, 7
	DETUNE $FD
	VIBRATO 4, 3, 2
	NOTE C_, 8
	TRANSPOSE_UP 7
	DETUNE $00
	SND_CALL Snd67_Ch1_7687
	VOICE $09, 1, 0, 7, 8, 7
	TRANSPOSE_DOWN 0
	DETUNE $FD
	NOTE F#, 8
	TRANSPOSE_DOWN $0B
	DETUNE $00
	SND_CALL Snd67_Ch1_7687
	TRANSPOSE_DOWN 0
	LOOP2_END 2
	VOICE $09, 5, 8, 6, 10, 7
	DETUNE $01
	ATTEN 4
	VIBRATO 4, 1, 1
	AUTOPAN 0
	NOTE C_, 3
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 1
	VOICE $09, 5, 4, 7, 6, 7
	RELEASE_VOL 2
	VIBRATO 4, 0, 2
	TRANSPOSE_DOWN $0D
	SND_CALL Snd67_Ch1_76BC
	TRANSPOSE_DOWN 0
	REST 8
	SND_JUMP Snd67_Ch1_76FC
Snd67_Ch1_77AA:
	VOICE $09, 2, 8, 7, 10, 2
	VIBRATO_SEMI 3
	RELEASE_VOL 3
	DUTY_STEP 8, 1
	ATTEN 2
	NOTE D_, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D#, 2
	VOICE $06, 2, 4, 7, 0, 0
	VIBRATO_OFF
	DUTY_STEP 0, 0
	SND_RET

Snd67_Ch3:
	VOICE $09, 0, 4, 4, 10, 4
	LOOP_START
	OCTAVE 4
	NOTE G#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	TRANSPOSE_DOWN $0C
	LOOP_END 2
	TRANSPOSE_DOWN 0
	VOICE $09, 0, 2, 2, 0, 0
	VIBRATO 5, 0, 8
	OCTAVE 2
	NOTE G_, 8
	RELEASE $0A, 4
	RELEASE_VOL 4
	NOTE C_HI, 0
Snd67_Ch3_77E7:
	LOOP2_START
	VOICE $01, 1, 4, 2, 10, 0
	RELEASE_VOL 4
	VIBRATO_OFF
	NOTE D#, 2
	NOTE E_, 0
	LEN_UNIT $09
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	LEN_UNIT $01
	NOTE D#, 2
	NOTE E_, 0
	LEN_UNIT $09
	NOTE G_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	REST 4
	RELEASE $0A, 3
	OCTAVE 1
	LOOP_START
	NOTE G_, 2
	NOTE G#, 2
	LOOP_END 8
	TRANSPOSE_DOWN 1
	LOOP2_END 2
	TRANSPOSE_DOWN 0

Snd6F_Ch3:
	LOOP2_START
	VOICE $09, 3, 5, 4, 12, 3
	VIBRATO 6, 0, 8
	RELEASE_VOL 6
	LOOP_START
	NOTE C_, 2
	NOTE G_, 2
	LOOP_END 6
	RELEASE_VOL 0
	RELEASE 5, 7
	OCTAVE 2
	NOTE C#, 4
	NOTE C#, 4
	LOOP2_END 2
	LOOP2_START
	VOICE $09, 2, 1, 2, 0, 0
	VIBRATO 6, 0, 2
	NOTE C_, 8
	NOTE C_HI, 8
	OCTAVE 1
	NOTE F#, 8
	NOTE C_HI, 8
	LOOP2_END 2
	VOICE $09, 2, 1, 2, 0, 0
	NOTE C_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE B_, 4
	NOTE A#, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE D#, 4
	NOTE A_, 4
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	NOTE D_, 4
	NOTE C#, 4
	NOTE G_, 4
	NOTE F#, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE G_, 4
	REST 8
	SND_JUMP Snd67_Ch3_77E7

Snd67_Drm:
	LEN_UNIT $09
	REST 0
	DRUM $0A, 0
	REST 8
Snd67_Drm_785E:
	LEN_UNIT $09
	LOOP_START
	REST 0
	REST $0A
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 4
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 8
	DRUM $0A, 6
	DRUM $0A, 2
	DRUM $0A, 8
	LOOP_END 2

Snd6F_Drm:
	LEN_UNIT $09
	LOOP2_START
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 2
	LOOP_END 6
	DRUM 3, 4
	DRUM 3, 4
	LOOP2_END 2
	LOOP_START
	DRUM 3, 8
	DRUM 3, 4
	DRUM 3, 4
	LOOP_END 4
	LEN_UNIT $09
	LOOP_START
	DRUM $0A, 4
	DRUM 2, 4
	LOOP_END 7
	DRUM $0A, 4
	DRUM 2, 2
	DRUM 2, 2
	REST 8
	SND_JUMP Snd67_Drm_785E

Snd68_Ch2:
	SND_CALL Snd60_Ch2_7927
	TRANSPOSE_DOWN 3
	SND_CALL Snd68_Ch1_78F1
	NOTE G#, 2
	TRANSPOSE_DOWN 0
	RELEASE $0A, 7
	OCTAVE 1
	NOTE G_, 3
	NOTE G_, 7
	DETUNE $01
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd68_Ch2_7901
	TRANSPOSE_DOWN 7
	SND_CALL Snd68_Ch2_7901
	TRANSPOSE_DOWN 0
	SND_CALL Snd68_Ch2_7901
	DUTY 8
	VIBRATO_SEMI 1
	SND_JUMP_N 2, Snd68_Ch2_78D2
	OCTAVE 3
	NOTE D_, 2
	PAN_LEFT 5
	NOTE D_, 3
	PAN_BOTH 0
	NOTE F#, 2
	PAN_RIGHT 5
	NOTE F#, 3
	RELEASE 2, 7
	VIBRATO 6, 0, 1
	PAN_BOTH 0
	NOTE B_, 3
	NOTE A#, 2
	NOTE A_, 3
	NOTE G_, 2
	REST 5
	DUTY 0
	OCTAVE 2
	NOTE G_, $0F
Snd68_Ch2_78D2:
	LOOP2_END 2
	DUTY 0
	OCTAVE 3
	NOTE D_, 3
	NOTE E_, 2
	NOTE F_, 3
	NOTE F#, 2
	NOTE G_, 3
	NOTE A_, 2
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	PAN_RIGHT 4
	NOTE C_, 3
	LOOP_START
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 2
	PAN_LEFT 4
	NOTE C_, 3
	LOOP_END 2
	PAN_BOTH 0
	NOTE G_, 7
	SND_LOOP
Snd68_Ch1_78F1:
	VIBRATO_SEMI 1
	OCTAVE 4
	NOTE G_, 3
	NOTE F#, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE D#, 3
	NOTE D_, 2
	NOTE C#, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 3
	NOTE A#, 2
	NOTE A_, 3
	SND_RET
Snd68_Ch2_7901:
	VOICE $03, 3, 8, 7, 13, 4
	DUTY_STEP 4, 1
	VIBRATO_SEMI 1
	NOTE E_, 2
	PAN_LEFT 5
	NOTE E_, 3
	PAN_BOTH 0
	NOTE G_, 2
	PAN_RIGHT 5
	NOTE G_, 6
	PAN_BOTH 0
	DUTY 0
	VIBRATO 6, 0, 1
	NOTE G_, 2
	NOTE A_, 3
	NOTE A#, 5
	NOTE A#, 2
	NOTE A_, 2
	PAN_LEFT 5
	NOTE A_, 3
	PAN_BOTH 0
	NOTE G_, 3
	NOTE E_, 7
	SND_RET
Snd60_Ch2_7927:
	LOOP_START
	VOICE $03, 3, 4, 7, 12, 3
	VIBRATO 6, 0, 1
	NOTE B_, 3
	NOTE A#, 2
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	PAN_LEFT 4
	NOTE B_, 3
	PAN_BOTH 0
	DUTY 0
	OCTAVE 2
	NOTE D_, 5
	LOOP_END 2
	VOICE $03, 4, 4, 7, 14, 2
	SND_RET

Snd68_Ch1:
	SND_CALL Snd60_Ch1_79D8
	ATTEN 3
	REST 2
	SND_CALL Snd68_Ch1_78F1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 7
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd68_Ch1_79B3
	SND_CALL Snd68_Ch1_79CC
	TRANSPOSE_DOWN 7
	SND_CALL Snd68_Ch1_79B3
	SND_CALL Snd68_Ch1_79CC
	TRANSPOSE_DOWN 0
	SND_CALL Snd68_Ch1_79B3
	SND_JUMP_N 2, Snd68_Ch1_798A
	SND_CALL Snd68_Ch1_79CC
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	PAN_LEFT 5
	NOTE A_, 3
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 2
	PAN_RIGHT 5
	NOTE D_, 3
	RELEASE 2, 7
	PAN_BOTH 0
	NOTE G_, 3
	NOTE F#, 2
	NOTE F_, 3
	OCTAVE 2
	NOTE B_, 2
	REST 5
	DUTY 0
	OCTAVE 2
	NOTE D_, $0F
Snd68_Ch1_798A:
	LOOP2_END 2
	NOTE D_, 5
	NOTE D_, 2
	NOTE D_, 2
	PAN_LEFT 5
	NOTE D_, 3
	PAN_BOTH 0
	NOTE C#, 3
	OCTAVE 2
	NOTE C#, 7
	OCTAVE 3
	NOTE D_, 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 3
	NOTE F_, 2
	NOTE G_, 3
	NOTE E_, 2
	PAN_RIGHT 4
	NOTE E_, 3
	LOOP_START
	PAN_BOTH 0
	OCTAVE 2
	NOTE G_, 2
	PAN_LEFT 4
	NOTE G_, 3
	LOOP_END 2
	PAN_BOTH 0
	NOTE B_, 7
	SND_LOOP
Snd68_Ch1_79B3:
	VOICE $03, 3, 8, 7, 13, 4
	VIBRATO_SEMI 1
	NOTE C_, 2
	PAN_LEFT 5
	NOTE C_, 3
	PAN_BOTH 0
	NOTE E_, 2
	PAN_RIGHT 5
	NOTE E_, 6
	PAN_BOTH 0
	DUTY 4
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 3
	OCTAVE 3
	SND_RET
Snd68_Ch1_79CC:
	NOTE G_, 5
	NOTE G_, 2
	NOTE E_, 2
	PAN_LEFT 5
	NOTE E_, 3
	PAN_BOTH 0
	NOTE E_, 3
	OCTAVE 2
	NOTE A#, 7
	SND_RET
Snd60_Ch1_79D8:
	LOOP_START
	VOICE $03, 4, 0, 7, 12, 7
	VIBRATO 6, 0, 1
	ATTEN 3
	REST 2
	NOTE G_, 3
	NOTE F#, 2
	NOTE G_, 3
	NOTE A_, 2
	NOTE G_, 3
	ATTEN 0
	OCTAVE 2
	NOTE G_, 5
	LOOP_END 2
	VOICE $03, 4, 4, 6, 7, 6
	SND_RET

Snd68_Ch3:
	SND_CALL Snd60_Ch3_7A40
	SND_CALL Snd68_Ch1_78F1
	NOTE G#, 2
	VIBRATO_OFF
	TRANSPOSE_DOWN 0
	WAVE 4
	RELEASE 2, 7
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 7
	VOICE $03, 1, 4, 2, 12, 7
	SND_SEGNO
	LOOP2_START
	SND_CALL Snd68_Ch3_7A37
	TRANSPOSE_UP 5
	SND_CALL Snd68_Ch3_7A37
	TRANSPOSE_DOWN 0
	SND_JUMP_N 2, Snd68_Ch3_7A22
	SND_CALL Snd68_Ch3_7A37
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F#, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
Snd68_Ch3_7A22:
	LOOP2_END 2
	OCTAVE 2
	NOTE C_, 5
	NOTE C_, 5
	OCTAVE 1
	NOTE B_, 5
	NOTE B_, 5
	NOTE A#, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE C#, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	SND_LOOP
Snd68_Ch3_7A37:
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE A#, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE E_, 5
	SND_RET
Snd60_Ch3_7A40:
	LOOP_START
	VOICE $03, 4, 4, 2, 13, 7
	VIBRATO 6, 0, 1
	DETUNE $FF
	NOTE G_, 3
	NOTE F#, 2
	NOTE G_, 3
	NOTE A_, 2
	NOTE G_, 2
	PAN_LEFT 2
	NOTE G_, 3
	PAN_BOTH 0
	OCTAVE 1
	NOTE G_, 5
	WAVE 2
	RELEASE $0A, 7
	LOOP_END 2
	SND_RET

Snd68_Drm:
	LEN_UNIT $03
	DRUM $0A, $0F
	DRUM 5, 5
	DRUM $0A, $0F
	DRUM 5, 5
	DRUM $0A, $0F
	REST 5
	DRUM $0A, $0D
	DRUM 5, 2
	DRUM 5, 5
	LEN_UNIT $03
	SND_SEGNO
	DRUM 3, 5
	DRUM 1, 3
	DRUM 2, 2
	SND_LOOP

Snd69_Ch2:
	SND_SEGNO
	LOOP2_START
	VOICE $09, 0, 4, 8, 10, 7
	DETUNE $01
	VIBRATO 10, 0, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	SND_JUMP_N 2, Snd60_Ch2_7A9D
	ATTEN 3
	DUTY 0
	VIBRATO_SEMI 5
	NOTE C_HI, 2
	SND_CALL Snd60_Ch1_7AA5
	NOTE C_, 2
Snd60_Ch2_7A9D:
	LOOP2_END 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE C_, 2
	REST 2
	SND_LOOP
Snd60_Ch1_7AA5:
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
	SND_RET

Snd69_Ch1:
	SND_SEGNO
	LOOP2_START
	VOICE $09, 0, 8, 7, 10, 7
	DETUNE $FF
	VIBRATO_SEMI 1
	OCTAVE 1
	NOTE B_, 4
	RELEASE_VOL 2
	OCTAVE 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	SND_JUMP_N 2, Snd60_Ch1_7AF5
	VOICE $09, 0, 0, 3, 0, 0
	VIBRATO 10, 0, 0
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	SND_CALL Snd60_Ch1_7AA5
	NOTE C_, 1
Snd60_Ch1_7AF5:
	LOOP2_END 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	SND_LOOP

Snd69_Ch3:
	SND_SEGNO
	LOOP2_START
	VOICE $09, 0, 1, 2, 6, 7
	RELEASE_VOL 4
	TRANSPOSE_UP $0A
	VIBRATO_SEMI 8
	OCTAVE 1
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G#, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	SND_JUMP_N 2, Snd60_Ch3_7B30
	VOICE $09, 0, 4, 2, 11, 1
	VIBRATO_SEMI 1
	TRANSPOSE_DOWN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	SND_CALL Snd60_Ch1_7AA5
	NOTE C_, 2
Snd60_Ch3_7B30:
	LOOP2_END 2
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	REST 2
	SND_LOOP

Snd69_Drm:
	LEN_UNIT $09
	SND_SEGNO
	LOOP2_START
	DRUM 3, 4
	LOOP_START
	DRUM $0A, 4
	DRUM 2, 4
	LOOP_END 5
	DRUM $0A, 4
	DRUM 5, 2
	DRUM 5, 2
	SND_JUMP_N 2, Snd60_Drm_7B4D
	DRUM 5, 0
	REST $0C
Snd60_Drm_7B4D:
	LOOP2_END 2
	DRUM $0A, 4
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 4
	SND_LOOP

Snd6A_Ch2:
	SND_CALL Snd6A_Ch1_7B95
	RELEASE 8, 7
	LOOP_START
	OCTAVE 1
	NOTE F_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 8
	LOOP_START
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 4
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	LOOP_START
	NOTE F_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	LOOP_END 4
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE G_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	REST 2
	NOTE C_HI, 2
	SND_END
Snd6A_Ch1_7B95:
	VOICE $05, 4, 0, 8, 10, 7
	RELEASE_VOL 4
	VIBRATO 6, 0, 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	VOICE $01, 4, 0, 8, 0, 0
	VIBRATO_OFF
	NOTE C_, $0A
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
	VOICE $05, 0, 8, 8, 10, 7
	VIBRATO_SEMI 1
	RELEASE_VOL 2
	SND_RET

Snd6A_Ch1:
	TRANSPOSE_DOWN 5
	SND_CALL Snd6A_Ch1_7B95
	TRANSPOSE_DOWN 0
	RELEASE $0E, 1
	RELEASE_VOL 1
	VIBRATO_SEMI 2
	ATTEN 3
	TRANSPOSE_UP $0C
	SND_JUMP Snd6A_Ch1_7BDF

Snd6A_Ch3:
	VOICE $05, 2, 7, 2, 10, 7
	VIBRATO_SEMI 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	RELEASE_VOL 4
	WAVE 2
	TRANSPOSE_DOWN $0C
Snd6A_Ch1_7BDF:
	LOOP_START
	OCTAVE 4
	NOTE A_, 2
	SND_CALL Snd6A_Ch1_7C16
	LOOP_END 2
	OCTAVE 4
	NOTE A#, 2
	SND_CALL Snd6A_Ch1_7C16
	NOTE G_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE A_, 2
	SND_CALL Snd6A_Ch1_7C16
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 5
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	REST 2
	NOTE C_HI, 2
	SND_END
Snd6A_Ch1_7C16:
	OCTAVE 5
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	SND_RET

Snd6A_Drm:
	LEN_UNIT $05
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	LOOP2_START
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 4
	LOOP2_END 6
	DRUM $0A, 0
	REST 8
	DRUM 1, 4
	DRUM 1, 4
	SND_END

Snd6B_Ch2:
	SND_SEGNO
	LOOP2_START
	VOICE $08, 2, 0, 7, 4, 7
	VIBRATO 6, 0, 1
	DETUNE $01
	RELEASE_VOL 0
	LOOP_START
	NOTE D#, 4
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 3
	ATTEN 0
	LOOP_END 2
	RELEASE $0B, 7
	VIBRATO 6, 0, 2
	SND_JUMP_N 2, Snd6B_Ch1_7C60
	OCTAVE 3
	NOTE D#, 4
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	VOICE $08, 3, 8, 5, 4, 7
	VIBRATO 4, 0, 13
	NOTE B_, 4
Snd6B_Ch1_7C60:
	LOOP2_END 2
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 4
	SND_LOOP

Snd6B_Ch1:
	TRANSPOSE_DOWN 5
	SND_JUMP Snd6B_Ch2

Snd6B_Ch3:
	VOICE $08, 2, 1, 2, 4, 7
	VIBRATO 6, 0, 15
	SND_SEGNO
	SND_CALL Snd6B_Ch3_7C91
	NOTE D#, 4
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE C_HI, 4
	SND_CALL Snd6B_Ch3_7C91
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 4
	SND_LOOP
Snd6B_Ch3_7C91:
	LOOP_START
	NOTE D#, 4
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 3
	ATTEN 0
	LOOP_END 2
	SND_RET

Snd6B_Drm:
	LEN_UNIT $08
	SND_SEGNO
	DRUM $0A, 4
	DRUM $0A, 4
	DRUM 3, 8
	SND_LOOP

Snd6C_Ch2:
	SND_SEGNO
	DETUNE $01
	LOOP2_START
	VOICE $05, 3, 0, 7, 10, 4
	DUTY_STEP 8, 2
	VIBRATO_SEMI 3
	RELEASE_VOL 0
	SND_CALL Snd6C_Ch2_7D5C
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	ATTEN 5
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	SND_CALL Snd6C_Ch2_7D5C
	RELEASE 0, 0
	DUTY 4
	VIBRATO 5, 0, 5
	ATTEN 1
	NOTE E_, 4
	NOTE C_HI, 4
	NOTE E_, 4
	NOTE C_HI, 4
	LOOP2_END 2
	LOOP_START
	VOICE $05, 3, 8, 7, 0, 0
	DUTY_STEP 0, 0
	VIBRATO_OFF
	RELEASE_VOL 3
	NOTE E_, 1
	NOTE F_, 1
	ATTEN 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	ATTEN 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	ATTEN 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	ATTEN 0
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	RELEASE 8, 7
	DUTY 0
	ATTEN 0
	OCTAVE 4
	VIBRATO_SEMI 1
	SND_JUMP_N 2, Snd6C_Ch2_7D11
	NOTE F_, 2
	NOTE F_, 2
	PAN_RIGHT 4
	NOTE F_, 2
	PAN_BOTH 0
	NOTE F_, 2
Snd6C_Ch2_7D11:
	LOOP_END 2
	NOTE G#, 2
	NOTE G#, 2
	PAN_RIGHT 4
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G#, 2
	LOOP2_START
	VOICE $05, 0, 0, 7, 10, 7
	DUTY_STEP 8, 2
	VIBRATO_SEMI 3
	RELEASE_VOL 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	PAN_LEFT 4
	NOTE C_, 2
	PAN_BOTH 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	PAN_LEFT 4
	NOTE C_, 2
	PAN_BOTH 0
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	PAN_LEFT 4
	NOTE C_, 2
	PAN_BOTH 0
	NOTE C_, 2
	VIBRATO 6, 0, 0
	SND_CALL Snd6C_Ch1_7D6C
	SND_JUMP_N 2, Snd6C_Ch2_7D54
	SND_CALL Snd6C_Ch1_7D75
	NOTE E_, 4
Snd6C_Ch2_7D54:
	LOOP2_END 2
	SND_CALL Snd6C_Ch1_7D84
	NOTE E_, 4
	NOTE E_, 4
	SND_LOOP
Snd6C_Ch2_7D5C:
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 0
	SND_RET
Snd6C_Ch1_7D6C:
	VOICE $05, 0, 8, 7, 8, 7
	RELEASE_VOL 4
	DUTY_STEP 4, 1
	SND_RET
Snd6C_Ch1_7D75:
	OCTAVE 2
	NOTE E_, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE G#, 4
	LEN_UNIT $01
	NOTE G#, 7
	NOTE G_, 6
	NOTE F#, 7
	LEN_UNIT $05
	NOTE F_, 4
	SND_RET
Snd6C_Ch1_7D84:
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	SND_RET

Snd6C_Ch1:
	SND_SEGNO
	LOOP2_START
	VOICE $05, 3, 8, 6, 10, 5
	VIBRATO_SEMI 1
	RELEASE_VOL 0
	SND_CALL Snd6C_Ch1_7E08
	TRANSPOSE_DOWN 4
	SND_CALL Snd6C_Ch1_7E08
	TRANSPOSE_DOWN 0
	SND_CALL Snd6C_Ch1_7E08
	RELEASE 0, 0
	DUTY 4
	VIBRATO 5, 0, 5
	ATTEN 3
	OCTAVE 2
	NOTE B_, 4
	NOTE C_HI, 4
	NOTE B_, 4
	NOTE C_HI, 4
	LOOP2_END 2
	SND_CALL Snd6C_Ch1_7E16
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	PAN_RIGHT 4
	NOTE B_, 2
	PAN_BOTH 0
	NOTE B_, 2
	SND_CALL Snd6C_Ch1_7E16
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	PAN_RIGHT 4
	NOTE E_, 2
	PAN_BOTH 0
	NOTE E_, 2
	LOOP2_START
	VOICE $05, 2, 8, 7, 10, 7
	DUTY_STEP 4, 1
	VIBRATO_OFF
	RELEASE_VOL 0
	LOOP_START
	NOTE A_, 2
	NOTE G#, 2
	ATTEN 3
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F_, 2
	NOTE F#, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 0
	NOTE G#, 2
	LOOP_END 2
	SND_CALL Snd6C_Ch1_7D6C
	SND_JUMP_N 2, Snd6C_Ch1_7DFB
	TRANSPOSE_DOWN 4
	SND_CALL Snd6C_Ch1_7D75
	TRANSPOSE_DOWN 0
	OCTAVE 1
	NOTE B_, 4
Snd6C_Ch1_7DFB:
	LOOP2_END 2
	TRANSPOSE_DOWN 4
	SND_CALL Snd6C_Ch1_7D84
	TRANSPOSE_DOWN 0
	OCTAVE 3
	NOTE G#, 4
	NOTE G#, 4
	SND_LOOP
Snd6C_Ch1_7E08:
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 3
	NOTE C_, 2
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	NOTE C_, 2
	SND_RET
Snd6C_Ch1_7E16:
	VOICE $05, 2, 0, 6, 10, 7
	DUTY_STEP 4, 1
	RELEASE_VOL 4
	VIBRATO_SEMI 1
	LOOP_START
	NOTE E_, 2
	NOTE E_, 2
	PAN_LEFT 4
	NOTE E_, 2
	PAN_BOTH 0
	NOTE E_, 2
	LOOP_END 2
	NOTE F_, 2
	NOTE F_, 2
	PAN_RIGHT 4
	NOTE F_, 2
	PAN_BOTH 0
	NOTE F_, 2
	SND_RET

Snd6C_Ch3:
	SND_SEGNO
	LOOP2_START
	VOICE $05, 2, 7, 2, 8, 2
	LOOP_START
	NOTE A_, 2
	NOTE E_, 2
	LOOP_END 4
	LOOP_START
	NOTE B_, 2
	NOTE E_, 2
	LOOP_END 4
	LOOP_START
	NOTE A_, 2
	NOTE E_, 2
	LOOP_END 4
	RELEASE_VOL 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE E_, 2
	LOOP2_END 2
	SND_CALL Snd6C_Ch3_7E8B
	LOOP_START
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 2
	SND_CALL Snd6C_Ch3_7E8B
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE C_HI, 2
	OCTAVE 1
	LOOP_START
	NOTE A_, 2
	NOTE C_HI, 2
	LOOP_END 8
	RELEASE_VOL 4
	SND_CALL Snd6C_Ch1_7D75
	NOTE E_, 4
	RELEASE_VOL 0
	OCTAVE 1
	LOOP_START
	NOTE A_, 2
	NOTE C_HI, 2
	LOOP_END 8
	OCTAVE 2
	LOOP_START
	NOTE E_, 2
	NOTE C_HI, 2
	LOOP_END 6
	NOTE E_, 4
	NOTE E_, 4
	SND_LOOP
Snd6C_Ch3_7E8B:
	LOOP_START
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 2
	SND_RET

Snd6C_Drm:
	SND_SEGNO
	LEN_UNIT $05
	LOOP_START
	DRUM $0A, 2
	DRUM 2, 1
	DRUM 2, 1
	LOOP_END 48
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 8
	LOOP_START
	DRUM $0A, 4
	LOOP_END 6
	DRUM 5, 4
	DRUM 5, 4
	LOOP_START
	DRUM $0A, 2
	DRUM 5, 2
	LOOP_END 12
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 3, 4
	DRUM 3, 4
	SND_LOOP

Snd70_Ch2:
	TEMPO $10
	VOICE $08, 3, 8, 7, 10, 5
Snd70_Ch1_7EBB:
	SND_SEGNO
	LOOP_START
	RELEASE $0A, 5
	RELEASE_VOL 2
	DUTY 8
	VIBRATO_SEMI 2
	NOTE G#, 2
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	SND_JUMP_N 2, Snd70_Ch1_7EF4
	REST 2
	NOTE E_, 2
	DUTY 4
	VIBRATO 3, 2, 1
	NOTE G#, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 4
Snd70_Ch1_7EF4:
	LOOP_END 2
	NOTE F#, 2
	NOTE G#, 2
	VIBRATO 3, 2, 1
	DUTY 0
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_LOOP

Snd70_Ch1:
	VOICE $08, 3, 8, 4, 10, 5
	DETUNE $01
	REST 1
	SND_JUMP Snd70_Ch1_7EBB

Snd70_Ch3:
	SND_SEGNO
	LOOP2_START
	VOICE $08, 0, 2, 2, 0, 0
	VIBRATO_SEMI 3
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE G#, 2
	LOOP_END 2
	LOOP_START
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	LOOP_END 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	SND_JUMP_N 2, Snd70_Ch3_7F43
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 4
Snd70_Ch3_7F43:
	LOOP2_END 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
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
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $07
