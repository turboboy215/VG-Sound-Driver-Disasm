; ==========================================================================
; Teenage Mutant Hero Turtles - Back from the Sewers (E) - Konami sound driver (fourth GB version)
; Byte-exact RGBDS disassembly of the driver code and all sound data.
;   ROM0: sound init at boot, timer ISR, PlaySoundFar, bank helpers, PlaySound/update ($04D2-$07C7)
;   bank 14: track code, StopAll, tables, SFX/jingles, the PCM player and 4 PCM samples
;   bank 15: track code (no raw frames), tables, drum hits, music
; Build: rgbasm -Wall -o tm2.o TM2_SoundDriver.asm && rgblink -o tm2.gb tm2.o
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
DEF rP1 EQU $FF00

; ---------------------------------------------------------------- RAM
DEF wTrkSfx1 EQU $C080 ; 70 bytes
DEF wTrkSfx2 EQU $C180 ; 70 bytes
DEF wTrkSfxN EQU $C280 ; 70 bytes
DEF wTrkCh1 EQU $C380 ; 70 bytes
DEF wTrkCh2 EQU $C480 ; 70 bytes
DEF wTrkCh3 EQU $C580 ; 70 bytes
DEF wTrkDrm EQU $C680 ; 70 bytes
DEF wTrackDesc EQU $C0CA
DEF wMusicSlot EQU $C0CB
DEF wTempo EQU $C0CC
DEF wTempoAcc EQU $C0CD
DEF wReqPrio EQU $C0CE
DEF wReqId EQU $C0CF
DEF wPauseLast EQU $C0D1
DEF wFadeTimer EQU $C0D2
DEF wFadeLevel EQU $C0D3
DEF wFadeRate EQU $C0D4
DEF wWaveId EQU $C0D5
DEF wC0D6 EQU $C0D6
DEF wPcmPtr EQU $C0D8
DEF wSndLock EQU $C78D
DEF wPauseFlags EQU $C794
DEF wRomBank EQU $C7A7
DEF wRomBankSave EQU $C7BF
DEF rROMB EQU $2000 ; MBC1 bank select

; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field
DEF TRK_PRIO EQU $80
DEF TRK_ID EQU $81
DEF TRK_PTR EQU $82
DEF TRK_LEN EQU $84
DEF TRK_FLAGS EQU $85
DEF TRK_PANFLAGS EQU $86
DEF TRK_FLOW EQU $87
DEF TRK_VIB EQU $88
DEF TRK_DETUNE EQU $8A
DEF TRK_ATTEN EQU $8C
DEF TRK_TRANSP EQU $8D
DEF TRK_DUTYTICKS EQU $8E
DEF TRK_DUTYCNT EQU $8F
DEF TRK_SWEEP EQU $90
DEF TRK_ED_HI EQU $91
DEF TRK_UNIT EQU $92
DEF TRK_OCTAVE EQU $93
DEF TRK_PERIOD EQU $94
DEF TRK_CURPERIOD EQU $96
DEF TRK_VOL EQU $98
DEF TRK_LEVEL EQU $99
DEF TRK_DUTY EQU $9A
DEF TRK_CURDUTY EQU $9B
DEF TRK_GATE EQU $9C
DEF TRK_RELTICK EQU $9D
DEF TRK_ENV EQU $9E
DEF TRK_CH3TIMER EQU $9F
DEF TRK_PAN EQU $A0
DEF TRK_VIBPTR EQU $A1
DEF TRK_VIBCUR EQU $A3
DEF TRK_VIBTIMER EQU $A5
DEF TRK_VIBDELAY EQU $A6
DEF TRK_VIBDELAYCNT EQU $A7
DEF TRK_VIBDEPTH EQU $A8
DEF TRK_VIBLOOPPTR EQU $A9
DEF TRK_VIBLOOPCNT EQU $AB
DEF TRK_VIBSEGNO EQU $AC
DEF TRK_LOOPPTR EQU $B8
DEF TRK_LOOPCNT EQU $BA
DEF TRK_LOOP2PTR EQU $BB
DEF TRK_LOOP2CNT EQU $BD
DEF TRK_SEGNO EQU $BE
DEF TRK_RET EQU $C0
DEF TRK_REG1 EQU $C2
DEF TRK_REG2 EQU $C3
DEF TRK_REG3 EQU $C4
DEF TRK_REG4 EQU $C5

; TRK_FLAGS: 0 rest, 1 raw frames, 2 retrigger long notes, 3 noise hold, 4 tempo skip, 5 reload duty
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running
; TRK_FLOW: 0/1 loop open, 2 in a call, 3 mark set, 4 vibrato loop open, 5 vibrato mark set
; track descriptors (wTrackDesc): hi = track, lo = channel: Ch1 $00, Ch2 $11, Ch3 $22, Drm $34,
; Sfx1 $40, Sfx2 $52 (CH3), SfxN $63

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

; sound header: priority, track mask (Sfx1, Sfx2 (CH3), SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; note: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = sound index 1-13 of this bank, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; noise SFX track: NR43 value (no retrigger), length = unit; 0 = rest
MACRO NOISE
	db \1
ENDM
MACRO NOISE_REST
	db $00
ENDM
; noise SFX track in hold mode: volume (NR42 = vol << 4, retriggered if it changed), NR43
MACRO NOISE_HOLD
	db \1, \2
ENDM
; $E0 unit, duty|vol, gate|env (tone/wave tracks; on CH3 duty = wave)
MACRO VOICE
	db $E0, \1, (\2 << 4) | \3, (\4 << 4) | \5
ENDM
; $E0 unit, NR42 (noise SFX track)
MACRO NVOICE
	db $E0, \1, \2
ENDM
; $E0 unit | $80 on the noise SFX track: hold mode (2-byte notes)
MACRO NVOICE_HOLD
	db $E0, $80 | \1
ENDM
; $E0 unit | $80, NRx1, NR10 (bank 14 tone/wave tracks): raw frames follow
MACRO RAW_VOICE
	db $E0, $80 | \1, \2, \3
ENDM
; $E0 unit | $80 on a bank 15 tone track: only the unit
MACRO VOICE_FLAG
	db $E0, $80 | \1
ENDM
; raw frame: NRx2 = vol << 4, NRx3/NRx4 = period, for one unit
MACRO RAW_NOTE
	db (\1 << 4) | HIGH(\2), LOW(\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; $E1-$E6: octave
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8: gate (release point = length * gate / 16), env (NRx2 low nibble at the release; 0 = cut)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9: NR10 (written at once)
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
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $20 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $30 | \1
ENDM
MACRO AUTOPAN_R
	db $EA, $40 | \1
ENDM
MACRO AUTOPAN_L
	db $EA, $50 | \1
ENDM
MACRO AUTOPAN_OFF
	db $EA, $60 | \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \1
ENDM
; $EB n, xy: vibrato table n & $7F, delay x * unit ticks, depth y (0 = 1)
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
MACRO CMD_EC
	db $EC, \1
ENDM
; $ED x: TRK_SWEEP = TRK_DUTYCNT = x & 15, TRK_ED_HI = x & $F0 (see the doc)
MACRO CMD_ED
	db $ED, \1
ENDM
; $EE: tempo
MACRO TEMPO
	db $EE, \1
ENDM
; $EF: signed period offset
MACRO DETUNE
	db $EF, \1
ENDM
MACRO ATTEN
	db $F0 | \1
ENDM
; $F8 x / $F9 x: TRK_VOL = swap(x)
MACRO VOLUME
	db $F8, \1
ENDM
MACRO VOLUME_F9
	db $F9, \1
ENDM
MACRO SND_JUMP
	db $FA
	dw \1
ENDM
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
MACRO SND_CALL
	db $FD
	dw \1
ENDM
MACRO SND_RET
	db $FD
ENDM
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; vibrato tables: one byte per step: time << 4 | negative << 3 | offset (x depth); $FB loop, $FE mark, $FF end
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
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

SECTION "Timer vector", ROM0[$0050]

; Timer interrupt (TMA $C0, 16384 Hz -> 256 Hz); interrupts are enabled at once.
TimerVector:
	jp TimerISR

SECTION "Timer ISR", ROM0[$00A1]

; TimerISR: one driver update unless wSndLock bit 0 (update running) or bit 1
; (PlaySoundFar running) is set.
TimerISR:
	ei
	push hl
	push bc
	push de
	push af
	ld hl, wSndLock
	ld a, [hl]
	and $03
	jr nz, .l00B8
	set 0, [hl]
	call SndUpdate
	ld hl, wSndLock
	res 0, [hl]
.l00B8:
	pop af
	pop de
	pop bc
	pop hl
	ret

SECTION "Sound init", ROM0[$0168]

; Part of the boot code: NR50 = $77, NR51 = $FF, NR52 = $80, and the register
; address fields TRK_REG1-4 of the six tracks with a channel (the drum track has
; none, so they stay 0 = rP1).
SoundInit:
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
	ld l, TRK_REG1
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
	call SetRegAddrs

SECTION "SetRegAddrs", ROM0[$021A]

SetRegAddrs:
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc h
	ld l, TRK_REG1
	ret

SECTION "PlaySoundFar", ROM0[$029A]

; PlaySoundFar: A = sound id. PlaySoundFarChecked drops the request in one game
; state ([$C788] = 6, [$CB80] = 1, [$C7B3] = 0). wSndLock bit 1 is set around
; PlaySound; the caller's bank is restored afterwards.
PlaySoundFar:
	push af
	jr PlaySoundFarChecked.l02B3

PlaySoundFarChecked:
	push af
	ld a, [$C788]
	cp $06
	jr nz, .l02B3
	ld a, [$CB80]
	dec a
	jr nz, .l02B3
	ld a, [$C7B3]
	and a
	jr nz, .l02B3
	pop af
	ret
.l02B3:
	ld a, [wRomBank]
	ld [wRomBankSave], a
	pop af
	push hl
	ld hl, wSndLock
	set 1, [hl]
	push de
	push bc
	push af
	call PlaySound
	ld a, [wRomBank]
	ld [rROMB], a
	pop af
	pop bc
	pop de
	ld hl, wSndLock
	res 1, [hl]
	pop hl
	ld a, [wRomBankSave]
	cp $0A
	jp z, SetBankA.l032C
	cp $02
	jp z, SetBankA.l0304
	cp $09
	jp z, SetBankA.l0327
	cp $08
	jp z, SetBankA.l0322
	cp $03
	jp z, SetBankA.l0309
	cp $0B
	jp z, SetBankA.l0331
	ret

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
.l0304:
	push af
	ld a, $02
	jr SetBankA
.l0309:
	push af
	ld a, $03
	jr SetBankA
	push af
	ld a, $04
	jr SetBankA
	push af
	ld a, $05
	jr SetBankA
	push af
	ld a, $06
	jr SetBankA
	push af
	ld a, $07
	jr SetBankA
.l0322:
	push af
	ld a, $08
	jr SetBankA
.l0327:
	push af
	ld a, $09
	jr SetBankA
.l032C:
	push af
	ld a, $0A
	jr SetBankA
.l0331:
	push af
	ld a, $0B
	jr SetBankA
	push af
	ld a, $0C
	jr SetBankA
	push af
	ld a, $0D
	jr SetBankA

SetBank14:
	push af
	ld a, $0E
	jr SetBankA
	push af
	ld a, $0F
	jr SetBankA

SECTION "Sound ROM0", ROM0[$04D2]

; PlaySound: 0 = StopAll (bank 14). $9A-$9D: PCM voice (bank 14, blocking, interrupts
; off). Else the header from bank 14 (id < $C0, index id) or bank 15 (index id - $C0).
; If any SFX track of the mask holds a higher priority, nothing is started at all.
; Music needs the Ch1 bit and a priority >= Ch1's; it resets tempo, fade and the
; music slot, and starts Ch2/Ch3/Drm without a priority test.
PlaySound:
	ld [wReqId], a
	or a
	jp nz, PlayPcmVoice
	ld a, $0E
	ld [rROMB], a
	jp B14_StopAll

PlayPcmVoice:
	cp $9A
	jp c, PlaySoundTable
	cp $9E
	jp nc, PlaySoundTable
	cp $9A
	jp nz, .l04F6
	ld hl, $6A1A
	jp .l050F
.l04F6:
	cp $9B
	jp nz, .l0501
	ld hl, $6FFB
	jp .l050F
.l0501:
	cp $9C
	jp nz, .l050C
	ld hl, $74DC
	jp .l050F
.l050C:
	ld hl, $77ED
.l050F:
	ld c, l
	ld b, h
	ld hl, wPcmPtr
	ld [hl], c
	inc l
	ld [hl], b
	call SetBank14
	call B14_PlayPcm
	jp SetBank1

PlaySoundTable:
	ld b, a
	cp $C0
	jp nc, .l0532
	ld a, $0E
	ld [rROMB], a
	ld a, b
	ld hl, $49C8
	jp .l053D
.l0532:
	ld a, $0F
	ld [rROMB], a
	ld a, b
	ld hl, $4975
	sub $C0
.l053D:
	call LoadPtrIndexed0
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
	rrc b
	rrc b
	rrc b
	rrc b
	rrc b
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
	ld [wC0D6], a
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
	ld [wMusicSlot], a
	ld a, $08
	ld c, $10
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

; Track start: TRK_LEN = 1, TRK_FLAGS..TRK_SWEEP = 0, wWaveId = 0, NRx2 = 0 on the
; track's channel (on the drum track: rP1 = 0).
StartTrackData:
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
	ld [hl+], a
	ld [hl], a
	ld [wWaveId], a
	ld l, TRK_REG2
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
	call StartTrackData
	ld a, $C0
	cp h
	jp nz, .l05FF
	ld a, $08
	ld l, TRK_SWEEP
	ld [hl], a
	ld c, $10
	ldh [c], a
.l05FF:
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

; SndUpdate (256 Hz): pause edges, then one music track per update in turn (Ch1, Ch2,
; Ch3, Drm; fade and tempo before Ch1), then SfxN, Sfx2, Sfx1. Each runs in the
; bank its id came from (>= $C0: 15).
SndUpdate:
	ld a, [wPauseFlags]
	and $01
	ld hl, wPauseLast
	cp [hl]
	jp z, SndUpdateMusic
	ld [hl], a
	cp $00
	call PauseEdge

SndUpdateMusic:
	ld a, [wPauseFlags]
	and $01
	jp nz, SndUpdateSfx
	ld a, [wMusicSlot]
	and $03
	call MusicSlot
	ld hl, wMusicSlot
	inc [hl]

SndUpdateSfx:
	ld h, HIGH(wTrkSfxN)
	ld a, $63
	call RunTrack
	ld h, HIGH(wTrkSfx2)
	ld a, $52
	call RunTrack
	ld h, HIGH(wTrkSfx1)
	ld a, $40
	call RunTrack
	ld a, [wRomBank]
	ld [rROMB], a
	ret

MusicSlot:
	ld hl, MusicSlotTable
	call LoadPtrIndexed0
	jp hl
MusicSlotTable:
	dw MusicSlotCh1
	dw MusicSlotCh2
	dw MusicSlotCh3
	dw MusicSlotDrm

MusicSlotCh1:
	ld h, HIGH(wTrkCh1)
	call FadeTick
	call TempoTick
	ld h, HIGH(wTrkCh1)
	xor a
	jp RunTrack

MusicSlotCh2:
	ld h, HIGH(wTrkCh2)
	ld a, $11
	jp RunTrack

MusicSlotCh3:
	ld h, HIGH(wTrkCh3)
	ld a, $22
	jp RunTrack

MusicSlotDrm:
	ld h, HIGH(wTrkDrm)
	ld a, $34

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	cp $C0
	jp nc, .l0696
	ld a, $0E
	ld [rROMB], a
	jp B14_TrackTick
.l0696:
	ld a, $0F
	ld [rROMB], a
	jp B15_TrackTick

; Pause: stop SfxN, mute CH4 and CH2. Unpause: stop all SFX, mute CH1/CH4, NR32 = 0,
; give CH1 and CH3 back to the music (NR51 bits, period) and mark Ch1-Ch3 for a
; retrigger on long notes.
PauseEdge:
	jp z, UnpauseRestore
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

UnpauseRestore:
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
	ld [hl+], a
	ld c, $1C
	ldh [c], a
	inc h
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $21
	ldh [c], a
	ld a, $80
	ld c, $23
	ldh [c], a
	ld h, HIGH(wTrkCh1)
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $EE
	or [hl]
	ldh [c], a
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG3
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
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld l, TRK_PAN
	ld c, $25
	ldh a, [c]
	and $BB
	or [hl]
	ldh [c], a
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, TRK_REG3
	ld c, [hl]
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

; TempoTick: wTempoAcc += wTempo once per four updates; a carry sets TRK_FLAGS bit 4
; on all four music tracks, so each skips its next tick.
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
	jp c, .l0748
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l0748:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeTick: the game sets wFadeRate. Every wFadeRate calls wFadeLevel += $10 (taken
; off new notes); at $40 the drums stop, at $70 all music stops and the fade ends.
FadeTick:
	ld a, [wFadeRate]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld a, [wFadeLevel]
	add a, $10
	ld [wFadeLevel], a
	cp $40
	jp z, FadeStopDrums
	cp $70
	ret nz
	xor a
	ld [wFadeLevel], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jp nz, .l078E
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l078E:
	xor a
	ld h, HIGH(wTrkCh1)
	ld [hl-], a
	ld [hl+], a
	inc h
	ld [hl-], a
	ld [hl+], a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ld h, HIGH(wTrkSfx2)
	ld a, [hl]
	or a
	ld a, $00
	jp nz, .l07AF
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l07AF:
	ld h, HIGH(wTrkCh3)
	ld [hl-], a
	ld [hl], a
	ret

FadeStopDrums:
	ld h, HIGH(wTrkDrm)
	xor a
	ld l, TRK_ID
	ld [hl-], a
	ld [hl], a
	ret

LoadPtrIndexed0:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

SECTION "Sound bank 14", ROMX[$4000], BANK[14]

; TrackTick: one tick for track H with descriptor wTrackDesc.
B14_TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, B14_TrackCount
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call B14_WriteDuty

B14_TrackCount:
	ld l, TRK_LEN
	dec [hl]
	jp nz, B14_Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

; ReadCmds. Notes: length = lo * unit (lo = 0: (unit & 15) * 16), release tick =
; length * gate / 16. The note-on volume is TRK_VOL - TRK_ATTEN - wFadeLevel, but only
; the second subtraction's borrow is tested (a large TRK_ATTEN wraps to loud).
B14_ReadCmds:
	ld a, [de]
	cp $E0
	jp nc, B14_Command
	ld l, TRK_FLAGS
	bit 1, [hl]
	jp nz, B14_RawNote
	ld a, [wTrackDesc]
	cp $63
	jp z, B14_NoiseNote
	res 2, [hl]
	call B14_SavePtr
	dec de
	ld a, [de]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l4053
	ld b, a
	xor a
	bit 0, b
	jp nz, .l405B
	rrc b
.l404A:
	add a, c
	dec b
	jp nz, .l404A
	add a, a
	jp .l4060
.l4053:
	swap c
	ld a, c
	and $F0
	jp .l4060
.l405B:
	add a, c
	dec b
	jp nz, .l405B
.l4060:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [de]
	and $F0
	jp nz, .l4071
	set 0, [hl]
	ld a, $08
	jp B14_WriteVolume
.l4071:
	res 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, B14_DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jp z, .l4095
	ld e, a
	ld b, $00
	ld hl, $0000
.l408A:
	add hl, bc
	dec e
	jp nz, .l408A
	ld a, l
	and $F0
	or h
	swap a
.l4095:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l40A6
	ld [hl+], a
	ld a, [hl]
	call B14_WriteDuty
.l40A6:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, B14_AutoPan
	ld a, [de]
	and $F0
	swap a
	rlca
	ld l, TRK_OCTAVE
	ld c, [hl]
	add a, c
	ld l, TRK_TRANSP
	ld c, [hl]
	add a, c
	ld c, a
	ld b, $00
	push hl
	ld hl, B14_PeriodTable - 26
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl+]
	or a
	jp z, .l40D6
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l40D6:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l40FE
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
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
	call z, B14_VibratoStep
.l40FE:
	call B14_WritePeriod
	ld l, TRK_SWEEP
	ld a, [hl]
	or a
	jp z, .l410A
	ldh [rNR10], a
.l410A:
	ld a, [wFadeLevel]
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	sub c
	jp nc, B14_WriteVolume
	ld a, $08
	jp B14_WriteVolume

; Sustain: duty restore (never active: nothing sets TRK_DUTYTICKS), vibrato, the
; release (NRx2 = TRK_ENV | level + retrigger; env 0 = cut), CH3 decay one level
; every TRK_ENV ticks, and the retrigger of a long note (>= 128 ticks left) after an
; SFX gave the channel back.
B14_Sustain:
	ld l, TRK_FLAGS
	bit 1, [hl]
	ret nz
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
	jp z, .l4141
	dec [hl]
	jp nz, .l4141
	ld l, TRK_DUTY
	ld a, [hl]
	call B14_WriteDuty
.l4141:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, B14_SustainRelease
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, B14_SustainRelease
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	or a
	jp z, .l415A
	dec [hl]
	jp B14_SustainRelease
.l415A:
	ld l, TRK_VIBTIMER
	dec [hl]
	jp nz, B14_SustainRelease
	ld l, TRK_VIBCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	call B14_VibratoStep
	call B14_WritePeriod

B14_SustainRelease:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, B14_Ch3Release
	cp [hl]
	jp z, B14_ReleasePoint
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp B14_WriteVolume

B14_ReleasePoint:
	inc l
	ld a, [hl]
	or a
	jp z, .l41A7
	ld l, TRK_LEVEL
	or [hl]
	ld l, TRK_REG2
	ld c, [hl]
	call B14_WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret
.l41A7:
	ld a, $08
	jp B14_WriteVolume

B14_Ch3Release:
	cp [hl]
	inc hl
	jp c, B14_Ch3Decay
	jp z, .l41C4
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp B14_WriteVolume
.l41C4:
	ld a, [hl+]
	ld [hl], a
	ret

B14_Ch3Decay:
	ld a, [hl+]
	or a
	jp z, B14_WriteVolume
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LEVEL
	ld a, [hl]
	add a, $20
	cp $A0
	ret nc
	jp B14_WriteVolume

; VibratoStep: one byte per step: time << 4 | negative << 3 | offset, offset x depth
; added to TRK_PERIOD. $FB loop markers, $FE mark/jump, $FF ends the vibrato.
B14_VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, B14_VibEnd
	cp $FE
	jp z, B14_VibMark
	cp $FB
	jp z, B14_VibLoop
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
	jp z, B14_VibBase
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l4213
	and $07
	jp z, B14_VibBase
	cpl
	inc a
	ld e, a
	ld d, $FF
.l4213:
	ld a, [hl]
	or a
	jp z, .l4220
	ld b, a
	xor a
.l421A:
	add a, e
	dec b
	jp nz, .l421A
	ld e, a
.l4220:
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

B14_VibBase:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

B14_VibEnd:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

B14_VibLoop:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l4250
	set 4, [hl]
	ld l, TRK_VIBLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp B14_VibratoStep
.l4250:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l425F
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp B14_VibratoStep
.l425F:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp B14_VibratoStep

B14_VibMark:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l427B
	set 5, [hl]
	inc bc
	ld l, TRK_VIBSEGNO
	ld [hl], c
	inc l
	ld [hl], b
	jp B14_VibratoStep
.l427B:
	ld l, TRK_VIBSEGNO
	ld c, [hl]
	inc l
	ld b, [hl]
	jp B14_VibratoStep

B14_Rest:
	call B14_SavePtr
	ld a, $08
	jp B14_WriteVolume

; DrumNote: start sound (hi nibble) of this bank on the SFX tracks it uses, each with
; its own priority test. In bank 14 all 13 drum sounds are an empty stream.
B14_DrumNote:
	ld a, [de]
	and $F0
	swap a
	ld [wReqId], a
	ld hl, B14_SoundTable
	call B14_LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, B14_StartDrumTrack
	srl b
	ld hl, wTrkSfx2
	call c, B14_StartDrumTrack
	srl b
	ld hl, wTrkSfxN
	ret nc

B14_StartDrumTrack:
	ld a, [wReqPrio]
	cp [hl]
	jp c, B14_SkipDrumTrack
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
	ld l, TRK_REG2
	ld c, [hl]
	ldh [c], a
	ld a, $C0
	cp h
	jp nz, .l42EE
	ld a, $08
	ld l, TRK_SWEEP
	ld [hl], a
	ld c, $10
	ldh [c], a
.l42EE:
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

B14_SkipDrumTrack:
	inc de
	inc de
	ret

B14_RawNoteBack:
	dec de

B14_RawNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	or a
	jp z, B14_Rest
	and $F0
	push af
	ld a, [de]
	and $0F
	inc de
	ld c, a
	ld a, [de]
	call B14_SavePtr
	ld d, c
	ld e, a
	call B14_WritePeriod
	pop af
	jp B14_WriteVolume

B14_NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	or a
	jp z, B14_Rest
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, B14_NoiseNoteHold
	call B14_SavePtr
	ld e, a
	ld d, $00
	jp B14_WritePeriod

B14_NoiseNoteHold:
	and $0F
	swap a
	push af
	inc de
	ld a, [de]
	call B14_SavePtr
	ld e, a
	ld d, $00
	call B14_WritePeriod
	pop af
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	ret z
	ld a, [hl]
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; Command: $E0 voice; in raw mode $E1-$E6 and $F0-$F7 are raw frames; $E1-$E6 octave;
; $E7-$FF through the table (the argument byte in A, DE pointing at it).
B14_Command:
	inc de
	sub $E0
	jp z, B14_Cmd_Voice
	ld l, TRK_FLAGS
	bit 1, [hl]
	jp nz, B14_CommandRaw
	cp $07
	jp c, B14_Cmd_Octave
	push hl
	ld hl, B14_CommandTable - 14
	call B14_LoadPtrIndexed
	ld a, [de]
	jp hl
B14_CommandTable:
	dw B14_Cmd_LenUnit
	dw B14_Cmd_Release
	dw B14_Cmd_Sweep
	dw B14_Cmd_Ext
	dw B14_Cmd_Vibrato
	dw B14_Cmd_EC
	dw B14_Cmd_ED
	dw B14_Cmd_Tempo
	dw B14_Cmd_Detune
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Atten
	dw B14_Cmd_Volume
	dw B14_Cmd_Volume
	dw B14_Cmd_Jump
	dw B14_Cmd_Loop
	dw B14_Cmd_Loop2
	dw B14_Cmd_Call
	dw B14_Cmd_Segno
	dw B14_Cmd_End

B14_CommandRaw:
	cp $07
	jp c, B14_RawNoteBack
	push hl
	ld hl, B14_CommandRaw
	call B14_LoadPtrIndexed
	ld a, [de]
	jp hl
B14_CommandTableRaw:
	dw B14_Cmd_LenUnit
	dw B14_Cmd_Release
	dw B14_Cmd_Sweep
	dw B14_Cmd_Ext
	dw B14_Cmd_Vibrato
	dw B14_Cmd_EC
	dw B14_Cmd_ED
	dw B14_Cmd_Tempo
	dw B14_Cmd_Detune
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_RawAtten
	dw B14_Cmd_Volume
	dw B14_Cmd_Volume
	dw B14_Cmd_Jump
	dw B14_Cmd_Loop
	dw B14_Cmd_Loop2
	dw B14_Cmd_Call
	dw B14_Cmd_Segno
	dw B14_Cmd_End

B14_Cmd_Voice:
	ld a, [de]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [de]
	ld l, TRK_FLAGS
	bit 7, a
	inc de
	jp nz, B14_VoiceFlag
	ld a, [wTrackDesc]
	cp $63
	jp nz, B14_VoiceTone
	res 3, [hl]
	ld a, [de]
	call B14_WriteNoiseVolume
	inc de
	jp B14_ReadCmds

B14_VoiceTone:
	res 1, [hl]
	ld a, [de]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
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
	call B14_PanBoth
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_VoiceFlag:
	ld a, [wTrackDesc]
	cp $63
	jp nz, B14_VoiceRaw
	set 3, [hl]
	jp B14_ReadCmds

B14_VoiceRaw:
	set 1, [hl]
	ld a, [de]
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
	inc de
	ld a, [wTrackDesc]
	and $0F
	jp nz, .l4462
	ld a, [de]
	ld c, $10
	ldh [c], a
.l4462:
	call B14_PanBoth
	inc de
	jp B14_ReadCmds

B14_RawAtten:
	pop hl
	jp B14_RawNoteBack

B14_Cmd_Octave:
	ld c, a
	ld b, $00
	push hl
	ld hl, B14_OctaveTable - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	jp B14_ReadCmds
B14_OctaveTable:
	db $18, $30, $48, $60, $78, $90

B14_Cmd_LenUnit:
	pop hl
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Release:
	pop hl
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Sweep:
	pop hl
	and $7F
	ld l, TRK_SWEEP
	ld [hl], a
	ldh [rNR10], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Ext:
	swap a
	and $0F
	ld hl, B14_ExtTable
	call B14_LoadPtrIndexed
	ld a, [de]
	jp hl
B14_ExtTable:
	dw B14_Ext_Duty
	dw B14_Ext_PanBoth
	dw B14_Ext_PanRight
	dw B14_Ext_PanLeft
	dw B14_Ext_AutopanR
	dw B14_Ext_AutopanL
	dw B14_Ext_AutopanOff
	dw B14_Ext_TransposeUp
	dw B14_Ext_TransposeDown

B14_Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call B14_WriteDuty
	inc de
	jp B14_ReadCmds

B14_Ext_PanBoth:
	pop hl
	call B14_PanBoth
	inc de
	jp B14_ReadCmds

B14_PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l44EF
.l44E9:
	sla b
	dec a
	jp nz, .l44E9
.l44EF:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp B14_WriteRegChecked

B14_Ext_PanRight:
	pop hl
	call B14_PanRight
	inc de
	jp B14_ReadCmds

B14_Ext_PanLeft:
	pop hl
	call B14_PanLeft
	inc de
	jp B14_ReadCmds

B14_AutoPan:
	bit 1, [hl]
	jp nz, .l4513
	set 1, [hl]
	jp B14_PanLeft
.l4513:
	res 1, [hl]

B14_PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l452A
.l4522:
	rlc b
	rlc l
	dec a
	jp nz, .l4522
.l452A:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp B14_WriteRegChecked

B14_PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l454B
.l4543:
	rlc b
	rlc l
	dec a
	jp nz, .l4543
.l454B:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp B14_WriteRegChecked

B14_Ext_AutopanR:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 1, [hl]
	inc de
	jp B14_ReadCmds

B14_Ext_AutopanL:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	res 1, [hl]
	inc de
	jp B14_ReadCmds

B14_Ext_AutopanOff:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call B14_PanBoth
	inc de
	jp B14_ReadCmds

B14_Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_Ext_TransposeDown:
	pop hl
	and $0F
	jp z, .l458D
	rlca
	cpl
	inc a
.l458D:
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp B14_ReadCmds

; $EB n xy: vibrato table n & $7F. Bank 14 has only entries 1 and 2: song $41 uses
; $8A, whose pointer ($E0FE) reads echo RAM.
B14_Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l45D8
	and $7F
	push hl
	ld hl, B14_VibratoTable - 2
	call B14_LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc de
	ld a, [de]
	and $F0
	swap a
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l45D0
	ld b, a
	xor a
	bit 0, b
	jp nz, .l45CB
	rrc b
.l45C2:
	add a, c
	dec b
	jp nz, .l45C2
	add a, a
	jp .l45D0
.l45CB:
	add a, c
	dec b
	jp nz, .l45CB
.l45D0:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [de]
	and $0F
	inc l
	ld [hl], a
.l45D8:
	inc de
	jp B14_ReadCmds

B14_Cmd_EC:
	pop hl
	inc de
	jp B14_ReadCmds

; $ED x: TRK_ED_HI = x & $F0, TRK_SWEEP = TRK_DUTYCNT = x & 15; with 0 the duty is
; rewritten. In bank 14 a non-zero TRK_SWEEP is written to NR10 at every note-on.
B14_Cmd_ED:
	pop hl
	and $F0
	ld l, TRK_ED_HI
	ld [hl-], a
	ld a, [de]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, B14_WriteDuty
	inc de
	jp B14_ReadCmds

B14_Cmd_Tempo:
	pop hl
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l4610
	ld a, $FF
.l4610:
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Atten:
	pop hl
	dec de
	ld a, [de]
	and $0F
	swap a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp B14_ReadCmds

B14_Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	ld b, a
	ld a, [wTrackDesc]
	cp $63
	jp nz, .l4640
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, .l4644
	ld a, b
	call B14_WriteNoiseVolume
	jp .l4644
.l4640:
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
.l4644:
	inc de
	jp B14_ReadCmds

B14_Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp B14_ReadCmds

B14_Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l4666
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp B14_ReadCmds
.l4666:
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l4674
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp B14_ReadCmds
.l4674:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp B14_ReadCmds

B14_Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l4693
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp B14_ReadCmds
.l4693:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l46A1
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp B14_ReadCmds
.l46A1:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp B14_ReadCmds

B14_Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l46C3
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
	jp B14_ReadCmds
.l46C3:
	res 2, [hl]
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B14_ReadCmds

B14_Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	bit 3, [hl]
	jp nz, .l46DF
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp B14_ReadCmds
.l46DF:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B14_ReadCmds

; $FF: end. Sfx1/Sfx2 ending give CH1/CH3 back to the music; id $9E only silences.
B14_Cmd_End:
	pop hl
	xor a
	ld l, TRK_ID
	ld a, [hl]
	cp $9E
	ld a, $00
	ld [hl-], a
	ld [hl], a
	jp z, B14_Silence
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, B14_EndSfx2
	cp $40
	jp z, B14_EndSfx1
	cp $63
	jp nz, B14_Silence
	ld l, TRK_FLAGS
	res 3, [hl]
	jp B14_Silence

B14_EndSfx1:
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
	call nz, B14_RestoreMusic
	pop hl
	jp B14_Silence

B14_EndSfx2:
	ld l, TRK_FLAGS
	res 1, [hl]
	push hl
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, B14_RestoreMusic
	pop hl
	jp B14_Silence

B14_SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

B14_RestoreMusic:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld l, TRK_PAN
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l4759
.l4753:
	rlc b
	dec a
	jp nz, .l4753
.l4759:
	ld c, $25
	ldh a, [c]
	and b
	or [hl]
	ldh [c], a
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B14_WritePeriod

B14_LoadPtrIndexed:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

B14_WritePeriod:
	ld l, TRK_CURPERIOD
	ld [hl], e
	inc l
	ld a, d
	and $07
	ld [hl], a
	ld l, TRK_REG3
	ld c, [hl]
	ld a, e
	call B14_WriteRegChecked
	ret nc
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

B14_Silence:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, B14_SilenceCh3
	ld a, $08
	ld l, TRK_REG2
	ld c, [hl]
	call B14_WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ret

B14_SilenceCh3:
	xor a
	ld c, $1C
	jp B14_WriteRegChecked

; WriteVolume: NRx2 = A, compared with what the register reads back: unchanged means
; no write and no retrigger (except on CH1 while TRK_SWEEP is not 8). CH3 is never
; retriggered here.
B14_WriteVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, B14_WriteVolumeTrigger
	ld a, [wTrackDesc]
	and $0F
	ret nz
	ld l, TRK_SWEEP
	ld a, [hl]
	cp $08
	ret z
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL

B14_WriteVolumeTrigger:
	ld a, [hl]
	call B14_WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

B14_WriteNoiseVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteDuty: NRx1, or on CH3 load wave (A >> 4) unless it is already loaded.
B14_WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, B14_LoadWave
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld l, TRK_REG1
	ld c, [hl]
	jp B14_WriteRegChecked

B14_LoadWave:
	ld a, [wTrackDesc]
	cp $22
	jp nz, .l4813
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
.l4813:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld [wWaveId], a
	push hl
	ld c, $1A
	xor a
	ldh [c], a
	ld a, b
	swap a
	ld hl, B14_WaveTable
	call B14_LoadPtrIndexed
	ld c, $30
	ld b, $10
.l4831:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l4831
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

; WriteRegChecked: music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2
; plays; carry = written.
B14_WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l4867
	cp $22
	jp nz, .l4873
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
.l4867:
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
.l4873:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: clear all tracks' priority/id, mute every channel, NR51 = $FF.
B14_StopAll:
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

; Periods from C of octave 1 (TRK_OCTAVE + 2 * pitch indexes from $48A4).
B14_PeriodTable:
	dw $02A, $09B, $103, $168, $1C8, $221, $276, $2C5, $311, $357, $39B, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69E, $6B2, $6C5, $6D6, $6E7, $6F7 ; octave index 2
	dw $706, $714, $721, $72D, $73A, $745, $74F, $759, $762, $76B, $774, $77B ; octave index 3
	dw $783, $78A, $2791, $797, $79D, $7A2, $7A8, $7AD, $7B1, $7B5, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E3, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; CH3 wave pointers by duty >> 4 (entry 0 is the last period; 14-15 point into the
; sound table).
B14_WaveTable:
	dw $07F1
	dw B14_WaveData1
	dw B14_WaveData1
	dw B14_WaveData1
	dw B14_WaveData2
	dw B14_WaveData2
	dw B14_WaveData2
	dw B14_WaveData3
	dw B14_WaveData3
	dw B14_WaveData3
	dw B14_WaveData4
	dw B14_WaveData4
	dw B14_WaveData4
	dw B14_WaveData4
	dw $49CA
	dw $49CA
	dw $49CA
B14_WaveData1:
	db $11, $33, $55, $77, $33, $55, $77, $55, $55, $77, $11, $33, $77, $11, $33, $11
B14_WaveData2:
	db $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $0E, $0D, $0C
B14_WaveData3:
	db $55, $66, $77, $88, $99, $00, $00, $00, $00, $00, $99, $88, $55, $FF, $55, $BB
B14_WaveData4:
	db $34, $45, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A
B14_SoundTable:
	db $BC, $DE
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
	dw SndHdr71 ; $71
	dw SndHdr72 ; $72
	dw SndHdr73 ; $73
	dw SndHdr74 ; $74
	dw SndHdr75 ; $75
	dw SndHdr76 ; $76
	dw SndHdr77 ; $77
	dw SndHdr78 ; $78
	dw SndHdr79 ; $79
	dw SndHdr7A ; $7A
	dw SndHdr7B ; $7B
	dw SndHdr7C ; $7C
	dw SndHdr7D ; $7D
	dw SndHdr7E ; $7E
	dw SndHdr7F ; $7F
	dw SndHdr80 ; $80
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
	dw SndHdr97 ; $97
	dw SndHdr98 ; $98
	dw SndHdr99 ; $99
	dw SndHdr9A ; $9A
	dw SndHdr9B ; $9B
	dw SndHdr9C ; $9C
	dw SndHdr9D ; $9D
	dw SndHdr9E ; $9E

SndHdr01:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr03:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr04:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr05:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr06:
	SND_HEADER $10, $05 ; tracks: Sfx1, SfxN
	dw Snd01_SfxN
	dw Snd01_SfxN

SndHdr07:
	SND_HEADER $10, $05 ; tracks: Sfx1, SfxN
	dw Snd01_SfxN
	dw Snd01_SfxN

SndHdr08:
	SND_HEADER $10, $05 ; tracks: Sfx1, SfxN
	dw Snd01_SfxN
	dw Snd01_SfxN

SndHdr09:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr0A:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr0B:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr0C:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr0D:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw Snd01_SfxN

SndHdr0E:
	SND_HEADER $80, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd0E_SfxN
	dw Snd0E_Ch1
	dw Snd0E_Ch2
	dw Snd0E_Ch3

SndHdr0F:
	SND_HEADER $80, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd0F_SfxN
	dw Snd0F_Ch1
	dw Snd0F_Ch2
	dw Snd0F_Ch3

SndHdr10:
	SND_HEADER $88, $01 ; tracks: Sfx1
	dw Snd10_Sfx1

SndHdr11:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd11_Sfx1
	dw Snd11_SfxN

SndHdr12:
	SND_HEADER $88, $04 ; tracks: SfxN
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd13_Sfx1
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $88, $04 ; tracks: SfxN
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $88, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd17_Sfx1
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd18_Sfx1

SndHdr19:
	SND_HEADER $88, $01 ; tracks: Sfx1
	dw Snd19_Sfx1

SndHdr1A:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd1A_Sfx1
	dw Snd1A_SfxN

SndHdr1B:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd1E_Sfx1

SndHdr1F:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $A0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd20_Sfx1
	dw Snd20_Sfx2
	dw Snd20_SfxN

SndHdr21:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd21_Sfx1
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd22_Sfx1
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd23_Sfx1
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd24_Sfx1
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd26_Sfx1
	dw Snd26_SfxN

SndHdr27:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $A8, $01 ; tracks: Sfx1
	dw Snd28_Sfx1

SndHdr29:
	SND_HEADER $B0, $01 ; tracks: Sfx1
	dw Snd29_Sfx1

SndHdr2A:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2A_Sfx1

SndHdr2B:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd2D_Sfx1
	dw Snd2D_SfxN

SndHdr2E:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd2E_Sfx1
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $80, $04 ; tracks: SfxN
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd30_Sfx1

SndHdr31:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd31_Sfx1
	dw Snd31_SfxN

SndHdr32:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd32_Sfx1
	dw Snd32_SfxN

SndHdr33:
	SND_HEADER $80, $01 ; tracks: Sfx1
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd34_Sfx1
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd37_Sfx1
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr39:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr3A:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd3A_Sfx1
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $84, $05 ; tracks: Sfx1, SfxN
	dw Snd31_Sfx1
	dw Snd31_SfxN

SndHdr3C:
	SND_HEADER $80, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $94, $05 ; tracks: Sfx1, SfxN
	dw Snd3D_Sfx1
	dw Snd3D_SfxN

SndHdr3E:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr3F:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd40_Sfx1
	dw Snd40_SfxN

SndHdr41:
	SND_HEADER $B8, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd41_Sfx1
	dw Snd41_Sfx1
	dw Snd41_Sfx1
	dw Snd41_Ch1
	dw Snd41_Ch2
	dw Snd41_Ch3
	dw Snd41_Drm

SndHdr42:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd42_Sfx1
	dw Snd42_SfxN

SndHdr43:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd43_Sfx1
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd2D_Sfx1
	dw Snd2D_SfxN

SndHdr45:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd45_Sfx1
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd46_Sfx1
	dw Snd46_SfxN

SndHdr47:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd47_Sfx1
	dw Snd47_SfxN

SndHdr48:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd49_Sfx1
	dw Snd49_SfxN

SndHdr4A:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd4A_Sfx1
	dw Snd4A_SfxN

SndHdr4B:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd4B_Sfx1
	dw Snd4B_SfxN

SndHdr4C:
	SND_HEADER $88, $02 ; tracks: Sfx2
	dw Snd4C_Sfx2

SndHdr4D:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd4D_Sfx1
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd4E_Sfx1
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $84, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_SfxN

SndHdr50:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd50_Sfx1
	dw Snd50_SfxN

SndHdr51:
	SND_HEADER $84, $01 ; tracks: Sfx1
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd52_Sfx1
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $88, $05 ; tracks: Sfx1, SfxN
	dw Snd53_Sfx1
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd54_Sfx1
	dw Snd54_SfxN

SndHdr55:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_SfxN

SndHdr56:
	SND_HEADER $90, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd56_Sfx1
	dw Snd56_Sfx2
	dw Snd56_SfxN

SndHdr57:
	SND_HEADER $80, $06 ; tracks: Sfx2, SfxN
	dw Snd57_Sfx2
	dw Snd57_SfxN

SndHdr58:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd58_Sfx1

SndHdr59:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd58_Sfx1

SndHdr5A:
	SND_HEADER $90, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd5A_SfxN
	dw Snd5A_Ch1
	dw Snd5A_Ch2
	dw Snd5A_Ch2
	dw Snd5A_Ch2

SndHdr5B:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd5B_Sfx1

SndHdr5C:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd5C_Sfx1
	dw Snd5C_SfxN

SndHdr5D:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd36_Sfx1
	dw Snd36_SfxN

SndHdr5E:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd47_Sfx1
	dw Snd47_SfxN

SndHdr5F:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd5F_SfxN

SndHdr60:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd60_SfxN

SndHdr61:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd61_Sfx1
	dw Snd61_SfxN

SndHdr62:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd62_Sfx1

SndHdr63:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd63_SfxN

SndHdr64:
	SND_HEADER $E0, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd64_Sfx1
	dw Snd64_Sfx2
	dw Snd64_SfxN
	dw Snd64_Ch1
	dw Snd64_Ch1
	dw Snd64_Ch1
	dw Snd64_Ch1

SndHdr65:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd65_Sfx1
	dw Snd65_SfxN

SndHdr66:
	SND_HEADER $90, $03 ; tracks: Sfx1, Sfx2
	dw Snd66_Sfx1
	dw Snd66_Sfx2

SndHdr67:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd67_Sfx1
	dw Snd67_SfxN

SndHdr68:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd61_Sfx1
	dw Snd61_SfxN

SndHdr69:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd4A_Sfx1
	dw Snd4A_SfxN

SndHdr6A:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd40_Sfx1
	dw Snd40_SfxN

SndHdr6B:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd67_Sfx1
	dw Snd67_SfxN

SndHdr6C:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd6C_Sfx1

SndHdr6D:
	SND_HEADER $E0, $05 ; tracks: Sfx1, SfxN
	dw Snd6D_Sfx1
	dw Snd6D_SfxN

SndHdr6E:
	SND_HEADER $84, $04 ; tracks: SfxN
	dw Snd6E_SfxN

SndHdr6F:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd6F_SfxN

SndHdr70:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd70_SfxN

SndHdr71:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd71_Sfx1
	dw Snd71_SfxN

SndHdr72:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd3E_Sfx1
	dw Snd3E_SfxN

SndHdr73:
	SND_HEADER $C0, $7F ; tracks: Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm
	dw Snd73_Sfx1
	dw Snd73_Sfx2
	dw Snd73_SfxN
	dw Snd73_Ch1
	dw Snd73_Ch2
	dw Snd73_Ch3
	dw Snd73_Drm

SndHdr74:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd48_Sfx1
	dw Snd48_SfxN

SndHdr75:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd75_Sfx1
	dw Snd75_SfxN

SndHdr76:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd76_Sfx1
	dw Snd76_SfxN

SndHdr77:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd77_SfxN

SndHdr78:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd78_Sfx1
	dw Snd78_SfxN

SndHdr79:
	SND_HEADER $B0, $04 ; tracks: SfxN
	dw Snd79_SfxN

SndHdr7A:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd7A_Sfx1

SndHdr7B:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd7B_Sfx1
	dw Snd7B_SfxN

SndHdr7C:
	SND_HEADER $80, $1C ; tracks: SfxN, Ch1, Ch2
	dw Snd7C_SfxN
	dw Snd7C_Ch1
	dw Snd7C_Ch2

SndHdr7D:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd7D_Sfx1
	dw Snd7D_SfxN

SndHdr7E:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd4A_Sfx1
	dw Snd4A_SfxN

SndHdr7F:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd78_Sfx1
	dw Snd78_SfxN

SndHdr80:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd70_SfxN

SndHdr81:
	SND_HEADER $B0, $05 ; tracks: Sfx1, SfxN
	dw Snd6D_Sfx1
	dw Snd6D_SfxN

SndHdr82:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd63_SfxN

SndHdr83:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd47_Sfx1
	dw Snd47_SfxN

SndHdr84:
	SND_HEADER $98, $04 ; tracks: SfxN
	dw Snd77_SfxN

SndHdr85:
	SND_HEADER $98, $01 ; tracks: Sfx1
	dw Snd85_Sfx1

SndHdr86:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd45_Sfx1
	dw Snd45_SfxN

SndHdr87:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd78_Sfx1
	dw Snd78_SfxN

SndHdr88:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd88_Sfx1

SndHdr89:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd89_Sfx1

SndHdr8A:
	SND_HEADER $90, $04 ; tracks: SfxN
	dw Snd8A_SfxN

SndHdr8B:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd8B_Sfx1

SndHdr8C:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd7D_Sfx1
	dw Snd7D_SfxN

SndHdr8D:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd67_Sfx1
	dw Snd67_SfxN

SndHdr8E:
	SND_HEADER $88, $03 ; tracks: Sfx1, Sfx2
	dw Snd8E_Sfx1
	dw Snd8E_Sfx2

SndHdr8F:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd8F_Sfx1
	dw Snd8F_SfxN

SndHdr90:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd90_Sfx1
	dw Snd90_SfxN

SndHdr91:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd52_Sfx1
	dw Snd52_SfxN

SndHdr92:
	SND_HEADER $98, $05 ; tracks: Sfx1, SfxN
	dw Snd53_Sfx1
	dw Snd53_SfxN

SndHdr93:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd78_Sfx1
	dw Snd78_SfxN

SndHdr94:
	SND_HEADER $98, $01 ; tracks: Sfx1
	dw Snd94_Sfx1

SndHdr95:
	SND_HEADER $B0, $05 ; tracks: Sfx1, SfxN
	dw Snd8B_Sfx1
	dw Snd95_SfxN

SndHdr96:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd96_Sfx1

SndHdr97:
	SND_HEADER $90, $01 ; tracks: Sfx1
	dw Snd97_Sfx1

SndHdr98:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd98_Sfx1

SndHdr99:
	SND_HEADER $D0, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw Snd99_SfxN
	dw Snd99_Ch1
	dw Snd99_Ch2
	dw Snd99_Ch3

SndHdr9A:
	SND_HEADER $F0, $02 ; tracks: Sfx2
	dw Snd9A_Sfx2

SndHdr9B:
	SND_HEADER $F0, $02 ; tracks: Sfx2
	dw Snd9B_Sfx2

SndHdr9C:
	SND_HEADER $F0, $02 ; tracks: Sfx2
	dw Snd9C_Sfx2

SndHdr9D:
	SND_HEADER $F0, $02 ; tracks: Sfx2
	dw Snd9D_Sfx2

SndHdr9E:
	SND_HEADER $F0, $03 ; tracks: Sfx1, Sfx2
	dw Snd9E_Sfx1
	dw Snd9E_Sfx2

Snd01_SfxN:
	SND_END
B14_VibratoTable:
	dw B14_Vib01 ; 1
	dw B14_Vib02 ; 2

B14_Vib01:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

B14_Vib02:
	VIB_MARK
	VIB_STEP 4, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 4, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

Snd0E_SfxN:
	NVOICE $40, $09
	NOISE $30
	SND_CALL Snd0E_SfxN_4EBB
	NVOICE $08, $90
	NOISE $30
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $08
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $07
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $06
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $05
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $04
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $03
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $02
	SND_CALL Snd0E_SfxN_4EBB
	VOLUME $01
	SND_CALL Snd0E_SfxN_4EBB
	SND_END
Snd0E_SfxN_4EBB:
	NOISE $30
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	SND_RET

Snd0E_Ch1:
	VOICE $01, 0, 8, 0, 0
	OCTAVE 1
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 3
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 4
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 5
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 6
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	OCTAVE 6
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 5
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 4
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 3
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F23
	VOLUME $06
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 1
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 2
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 3
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 4
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 5
	SND_CALL Snd0E_Ch1_4F23
	SND_END
Snd0E_Ch1_4F16:
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
	SND_RET
Snd0E_Ch1_4F23:
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

Snd0E_Ch2:
	VOICE $01, 0, 6, 0, 0
	REST 3
	OCTAVE 1
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 3
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 4
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 5
	SND_CALL Snd0E_Ch1_4F16
	OCTAVE 6
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	OCTAVE 6
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 5
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 4
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 3
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F23
	OCTAVE 2
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 1
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 2
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 3
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 4
	SND_CALL Snd0E_Ch1_4F23
	ATTEN 5
	SND_CALL Snd0E_Ch1_4F23
	SND_END

Snd0E_Ch3:
	SND_END

Snd0F_SfxN:
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	VOLUME $08
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	VOLUME $0D
	NOISE $40
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NVOICE $18, $8F
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NVOICE $08, $80
	SND_CALL Snd0F_SfxN_4FD4
	VOLUME $07
	SND_CALL Snd0F_SfxN_4FD4
	VOLUME $06
	SND_CALL Snd0F_SfxN_4FDB
	VOLUME $05
	SND_CALL Snd0F_SfxN_4FDB
	VOLUME $04
	SND_CALL Snd0F_SfxN_4FE2
	VOLUME $03
	SND_CALL Snd0F_SfxN_4FE2
	VOLUME $02
	SND_CALL Snd0F_SfxN_4FE2
	VOLUME $01
	SND_CALL Snd0F_SfxN_4FE2
	SND_END
Snd0F_SfxN_4FD4:
	NOISE $31
	NOISE $31
	NOISE $31
	NOISE $31
	NOISE $31
	NOISE $31
	SND_RET
Snd0F_SfxN_4FDB:
	NOISE $21
	NOISE $21
	NOISE $21
	NOISE $21
	NOISE $21
	NOISE $21
	SND_RET
Snd0F_SfxN_4FE2:
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	SND_RET

Snd0F_Ch1:
	VOICE $01, 0, 7, 0, 0
	OCTAVE 5
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 4
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 3
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 2
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 3
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 4
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 5
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 6
	SND_CALL Snd0F_Ch1_503D
	VOLUME $05
	OCTAVE 6
	SND_CALL Snd0F_Ch1_503D
	ATTEN 1
	SND_CALL Snd0F_Ch1_503D
	ATTEN 2
	SND_CALL Snd0F_Ch1_503D
	ATTEN 3
	SND_CALL Snd0F_Ch1_503D
	ATTEN 4
	SND_CALL Snd0F_Ch1_503D
	ATTEN 0
	SND_END
Snd0F_Ch1_5030:
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
Snd0F_Ch1_503D:
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
	SND_RET

Snd0F_Ch2:
	VOICE $01, 0, 5, 0, 0
	REST 3
	OCTAVE 5
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 4
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 3
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 2
	SND_CALL Snd0F_Ch1_5030
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 2
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 3
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 4
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 5
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 6
	SND_CALL Snd0F_Ch1_503D
	OCTAVE 6
	SND_CALL Snd0F_Ch1_503D
	ATTEN 1
	SND_CALL Snd0F_Ch1_503D
	ATTEN 2
	SND_CALL Snd0F_Ch1_503D
	ATTEN 3
	SND_CALL Snd0F_Ch1_503D
	ATTEN 4
	SND_CALL Snd0F_Ch1_503D
	ATTEN 0
	SND_END

Snd0F_Ch3:
	SND_END

Snd10_Sfx1:
	VOICE $04, 8, 15, 0, 0
	OCTAVE 6
	NOTE C_, 1
	VOICE $04, 4, 8, 0, 0
	OCTAVE 5
	SND_CALL Snd10_Sfx1_50A8
	ATTEN 4
	SND_CALL Snd10_Sfx1_50A8
	ATTEN 6
	SND_CALL Snd10_Sfx1_50A8
	SND_END
Snd10_Sfx1_50A8:
	NOTE C_, 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET

Snd11_Sfx1:
	LOOP_START
	VOICE $04, 0, 5, 0, 0
	SND_CALL Snd11_Sfx1_50BF
	REST 9
	LOOP_END 3
	VOLUME $07
	SND_CALL Snd11_Sfx1_50BF
	SND_END
Snd11_Sfx1_50BF:
	OCTAVE 6
	NOTE G#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 6
	NOTE E_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 6
	NOTE C_, 1
	SND_RET

Snd11_SfxN:
	LOOP_START
	NVOICE $04, $90
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	SND_CALL Snd11_SfxN_50F0
	LOOP_END 3
	NVOICE $04, $B0
	SND_CALL Snd11_SfxN_5102
	VOLUME $03
	SND_CALL Snd11_SfxN_5102
	SND_CALL Snd11_SfxN_50F0
	SND_END
Snd11_SfxN_50F0:
	NVOICE $04, $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	VOLUME $01
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	SND_RET
Snd11_SfxN_5102:
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	SND_RET

Snd12_SfxN:
	NVOICE $03, $A0
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	LOOP_START
	NVOICE $04, $F0
	NOISE $44
	NOISE $45
	SND_CALL Snd12_SfxN_5130
	SND_CALL Snd12_SfxN_5139
	NVOICE $14, $00
	NOISE_REST
	LOOP_END 2
	NVOICE $04, $F0
	NOISE $44
	NOISE $45
	SND_CALL Snd12_SfxN_5130
	NOISE $18
	NOISE $18
	SND_CALL Snd12_SfxN_5139
	SND_END
Snd12_SfxN_5130:
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $10
	SND_RET
Snd12_SfxN_5139:
	NOISE $18
	NOISE $18
	NOISE $08
	NOISE $08
	NOISE $08
	NOISE $08
	SND_RET

Snd13_Sfx1:
	VOICE $04, 8, 10, 0, 0
	SND_CALL Snd13_Sfx1_5150
	REST $0E
	LOOP_START
	SND_CALL Snd13_Sfx1_5150
	REST 5
	LOOP_END 2
	SND_END
Snd13_Sfx1_5150:
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	SND_RET

Snd13_SfxN:
	NVOICE $14, $F1
	NOISE $44
	NOISE $33
	NOISE $44
	NOISE $55
	NVOICE $14, $00
	NOISE $11
	NVOICE $10, $F1
	NOISE $44
	NOISE $33
	NOISE $44
	NOISE $55
	NVOICE $10, $E1
	NOISE $44
	NOISE $33
	NOISE $44
	NOISE $55
	SND_END

Snd14_SfxN:
	LOOP_START
	NVOICE $04, $90
	NOISE $42
	NOISE $41
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NVOICE $04, $20
	NOISE $42
	NOISE $41
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $10
	LOOP_END 3
	NVOICE $04, $F0
	NOISE $44
	NOISE $45
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $18
	NOISE $18
	SND_CALL Snd12_SfxN_5139
	SND_END

Snd15_Sfx1:
	VOICE $04, 8, 8, 0, 0
	OCTAVE 4
	NOTE E_, 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	SND_CALL Snd15_Sfx1_51C4
	ATTEN 7
	SND_CALL Snd15_Sfx1_51C4
	SND_END
Snd15_Sfx1_51C4:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd16_SfxN:
	NVOICE $04, $70
	NOISE $40
	NOISE $30
	NOISE $20
	NOISE $18
	NOISE $08
	SND_END

Snd17_Sfx1:
	VOICE $04, 8, 12, 0, 0
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	REST $0C
	SND_END

Snd17_SfxN:
	NVOICE $04, $F0
	NOISE $26
	NOISE $27
	VOLUME $04
	NOISE $31
	SND_CALL Snd17_SfxN_51FA
	VOLUME $03
	SND_CALL Snd17_SfxN_51FA
	VOLUME $02
	SND_CALL Snd17_SfxN_51FA
	VOLUME $01
	SND_CALL Snd17_SfxN_51FA
	SND_END
Snd17_SfxN_51FA:
	NOISE $11
	NOISE $11
	NOISE $11
	SND_RET

Snd18_Sfx1:
	SND_CALL Snd18_Sfx1_5202
	SND_END
Snd18_Sfx1_5202:
	VOICE $08, 8, 10, 0, 0
	OCTAVE 6
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	VOLUME $02
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_HI, 1
	SND_RET

Snd19_Sfx1:
	VOICE $04, 12, 15, 0, 0
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	VOLUME $05
	SND_CALL Snd19_Sfx1_5246
	OCTAVE 4
	VOLUME $0D
	SND_CALL Snd19_Sfx1_5246
	VOLUME $04
	SND_CALL Snd19_Sfx1_5246
	OCTAVE 3
	VOLUME $0B
	SND_CALL Snd19_Sfx1_524C
	VOLUME $03
	SND_CALL Snd19_Sfx1_524C
	SND_END
Snd19_Sfx1_5246:
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_RET
Snd19_Sfx1_524C:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	SND_RET

Snd1A_Sfx1:
	VOICE $04, 4, 13, 0, 0
	SWEEP $1D
	OCTAVE 3
	SND_CALL Snd1A_Sfx1_526E
	OCTAVE 4
	SND_CALL Snd1A_Sfx1_526E
	VOLUME $04
	SND_CALL Snd1A_Sfx1_526E
	ATTEN 2
	SND_CALL Snd1A_Sfx1_526E
	ATTEN 3
	SND_CALL Snd1A_Sfx1_526E
	SND_END
Snd1A_Sfx1_526E:
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
	SND_RET

Snd1A_SfxN:
	NVOICE $10, $5F
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	SND_END

Snd1B_Sfx1:
	TRANSPOSE_DOWN $0C
	SND_CALL Snd18_Sfx1_5202
	SND_END

Snd1C_Sfx1:
	TRANSPOSE_UP 8
	SND_CALL Snd18_Sfx1_5202
	SND_END

Snd1D_Sfx1:
	VOICE $04, 8, 15, 0, 0
	SWEEP $15
	OCTAVE 2
	NOTE C_, 8
	VOICE $04, 8, 10, 0, 0
	SWEEP $00
	SND_CALL Snd1D_Sfx1_52B5
	OCTAVE 4
	SND_CALL Snd1D_Sfx1_52B5
	ATTEN 6
	SND_CALL Snd1D_Sfx1_52B5
	ATTEN 7
	SND_CALL Snd1D_Sfx1_52B5
	VOLUME $02
	SND_CALL Snd1D_Sfx1_52B5
	SND_END
Snd1D_Sfx1_52B5:
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_RET

Snd1D_SfxN:
	NVOICE $04, $C3
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd1E_Sfx1:
	VOICE $02, 8, 15, 0, 0
	TRANSPOSE_UP 8
	SND_CALL Snd1E_Sfx1_52DA
	VOLUME $0A
	SND_CALL Snd1E_Sfx1_52DA
	ATTEN 5
	SND_CALL Snd1E_Sfx1_52DA
	ATTEN 7
	SND_CALL Snd1E_Sfx1_52DA
	SND_END
Snd1E_Sfx1_52DA:
	OCTAVE 3
	NOTE C_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 2
	NOTE E_, 1
	NOTE G_, 2
	NOTE B_, 1
	SND_RET

Snd1F_Sfx1:
	VOICE $08, 8, 15, 0, 0
	SWEEP $26
	OCTAVE 4
	NOTE C_, 2
	SWEEP $36
	ATTEN 7
	NOTE C_, 4
	SND_END

Snd21_Sfx1:
	VOICE $04, 0, 12, 0, 0
	OCTAVE 6
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 6
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	VOLUME $04
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_END

Snd21_SfxN:
	NVOICE $04, $D0
	NOISE $43
	NVOICE $10, $C3
	NOISE $12
	NOISE $11
	NOISE $10
	SND_END

Snd22_Sfx1:
	VOICE $04, 0, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	NOTE C_HI, 1
	OCTAVE 5
	NOTE A_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 6
	NOTE C_HI, 1
	SND_CALL Snd22_Sfx1_533F
	VOLUME $08
	SND_CALL Snd22_Sfx1_533F
	ATTEN 6
	SND_CALL Snd22_Sfx1_533F
	SND_END
Snd22_Sfx1_533F:
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 6
	NOTE B_, 1
	OCTAVE 5
	NOTE C_HI, 1
	OCTAVE 4
	NOTE B_, 1
	SND_RET

Snd22_SfxN:
	NVOICE $01, $D0
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NVOICE $10, $B3
	NOISE $40
	NOISE $41
	NOISE $42
	SND_END

Snd23_Sfx1:
	VOICE $04, 8, 12, 0, 0
	TRANSPOSE_UP 5
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 1
	SND_CALL Snd23_Sfx1_536C
	VOLUME $02
	OCTAVE 3
	SND_CALL Snd23_Sfx1_536C
	SND_END
Snd23_Sfx1_536C:
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_RET

Snd23_SfxN:
	NVOICE $0C, $B3
	NOISE $34
	NOISE $23
	NOISE $34
	NOISE $35
	SND_END

Snd24_Sfx1:
	VOICE $04, 12, 10, 0, 0
	TRANSPOSE_UP 4
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 1
	SND_CALL Snd23_Sfx1_536C
	ATTEN 7
	OCTAVE 3
	SND_CALL Snd23_Sfx1_536C
	SND_END

Snd24_SfxN:
	NVOICE $0C, $A3
	NOISE $24
	NOISE $22
	NOISE $24
	NOISE $26
	SND_END

Snd25_SfxN:
	NVOICE $04, $D0
	NOISE $22
	NOISE $23
	NOISE $34
	NOISE $35
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $43
	NOISE $32
	NOISE $31
	NVOICE $04, $30
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $22
	NOISE $21
	SND_END

Snd26_Sfx1:
	VOICE $04, 8, 4, 0, 0
	SWEEP $17
	OCTAVE 5
	NOTE C_, 8
	SND_END

Snd26_SfxN:
	NVOICE $04, $C0
	NOISE $43
	NOISE $12
	NOISE $11
	NOISE $10
	SND_END

Snd27_Sfx1:
	VOICE $04, 8, 13, 0, 0
	OCTAVE 2
	NOTE E_, 1
	SND_CALL Snd27_Sfx1_53D2
	VOLUME $04
	LOOP_START
	SND_CALL Snd27_Sfx1_53D2
	ATTEN 2
	LOOP_END 2
	SND_END
Snd27_Sfx1_53D2:
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_RET

Snd28_Sfx1:
	VOICE $08, 0, 15, 0, 0
	SWEEP $3E
	OCTAVE 5
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
	NOTE C#, 1
	NOTE C_, 1
	VOLUME $05
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd29_Sfx1:
	VOICE $08, 8, 8, 0, 0
	TRANSPOSE_UP $0A
	SND_CALL Snd29_Sfx1_5414
	SND_CALL Snd29_Sfx1_5414
	SND_CALL Snd29_Sfx1_5414
	SND_CALL Snd29_Sfx1_5414
	SND_END
Snd29_Sfx1_5414:
	ATTEN 0
	LOOP_START
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END 4
	ATTEN 5
	LOOP_START
	OCTAVE 6
	NOTE F#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END 3
	SND_RET

Snd2A_Sfx1:
	VOICE $04, 8, 15, 0, 0
	SWEEP $1F
	OCTAVE 6
	NOTE C_, 0
	SWEEP $00
	DUTY 0
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	VOLUME $05
	OCTAVE 5
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	VOLUME $0A
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 2
	OCTAVE 5
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 5
	OCTAVE 4
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 7
	OCTAVE 5
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_END

Snd2B_Sfx1:
	VOICE $0C, 8, 13, 0, 0
	SWEEP $2E
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	VOLUME $04
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_END

Snd2C_Sfx1:
	VOICE $0C, 8, 15, 0, 0
	SWEEP $2E
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_CALL Snd2C_Sfx1_5492
	VOICE $0C, 8, 5, 0, 0
	VOLUME $05
	LOOP_START
	SND_CALL Snd2C_Sfx1_5492
	ATTEN 3
	LOOP_END 2
	SND_END
Snd2C_Sfx1_5492:
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_RET

Snd2D_Sfx1:
	VOICE $04, 8, 12, 0, 0
	SWEEP $47
	OCTAVE 6
	NOTE C_, 8
	VOICE $04, 0, 9, 0, 0
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	ATTEN 7
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_END

Snd2D_SfxN:
	NVOICE $08, $F3
	NOISE $33
	NOISE $17
	NOISE $15
	NOISE $13
	NOISE $11
	NOISE $18
	NOISE $08
	NOISE $08
	SND_END

Snd2E_Sfx1:
	VOICE $08, 8, 15, 0, 0
	SWEEP $24
	OCTAVE 3
	NOTE C#, 4
	SND_END

Snd2E_SfxN:
	NVOICE $04, $F0
	NOISE $34
	NOISE $35
	NVOICE $08, $43
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd2F_SfxN:
	LOOP_START
	NVOICE $04, $C0
	NOISE $43
	NOISE $12
	NOISE $11
	NOISE $10
	VOLUME $03
	NOISE $43
	NOISE $12
	NOISE $11
	NOISE $10
	NVOICE $28, $00
	NOISE $10
	LOOP_END 5
	SND_END

Snd30_Sfx1:
	VOICE $03, 12, 15, 0, 0
	OCTAVE 4
	SND_CALL Snd30_Sfx1_5509
	VOLUME $03
	SND_CALL Snd30_Sfx1_5509
	VOLUME $0A
	OCTAVE 3
	SND_CALL Snd30_Sfx1_5509
	ATTEN 6
	SND_CALL Snd30_Sfx1_5509
	ATTEN 2
	OCTAVE 5
	SND_CALL Snd30_Sfx1_5509
	ATTEN 6
	SND_CALL Snd30_Sfx1_5509
	SND_END
Snd30_Sfx1_5509:
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_RET

Snd31_Sfx1:
	VOICE $04, 0, 15, 0, 0
	TRANSPOSE_UP $0F
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOLUME $08
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	ATTEN 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	SND_END

Snd31_SfxN:
	NVOICE $04, $F0
	NOISE $27
	NOISE $28
	NVOICE $14, $B3
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

Snd32_Sfx1:
	VOICE $04, 0, 15, 8, 0
	TRANSPOSE_UP 4
	SWEEP $2D
	OCTAVE 5
	NOTE G_, 8
	VOICE $04, 0, 8, 8, 0
	OCTAVE 5
	SWEEP $2D
	NOTE G_, 8
	SND_END

Snd32_SfxN:
	NVOICE $04, $80
	NOISE $23
	NOISE $13
	NOISE $03
	SND_END

Snd33_Sfx1:
	VOICE $02, 8, 15, 0, 0
	TRANSPOSE_DOWN 4
	SND_CALL Snd33_Sfx1_556C
	VOLUME $0A
	SND_CALL Snd33_Sfx1_556C
	ATTEN 5
	SND_CALL Snd33_Sfx1_556C
	ATTEN 7
	SND_CALL Snd33_Sfx1_556C
	SND_END
Snd33_Sfx1_556C:
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	SND_RET

Snd34_Sfx1:
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP 8
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $04, 8, 7, 0, 0
	TRANSPOSE_UP 2
	SND_CALL Snd34_Sfx1_559D
	SND_END
Snd34_Sfx1_559D:
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd34_SfxN:
	NVOICE $04, $F0
	NOISE $37
	NOISE $38
	NVOICE $10, $A5
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END

Snd35_Sfx1:
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $04, 8, 7, 0, 0
	TRANSPOSE_UP 2
	SND_CALL Snd34_Sfx1_559D
	SND_END

Snd35_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 15, $25
	NOISE_HOLD 15, $26
	NVOICE_HOLD $10
	NOISE_HOLD 10, $21
	NOISE_HOLD 10, $22
	NOISE_HOLD 9, $23
	NOISE_HOLD 9, $24
	NOISE_HOLD 8, $25
	NOISE_HOLD 7, $26
	NOISE_HOLD 6, $27
	NOISE_HOLD 5, $34
	NOISE_HOLD 4, $35
	NOISE_HOLD 3, $36
	SND_END

Snd36_Sfx1:
	VOICE $08, 12, 15, 0, 0
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $04, 8, 7, 0, 0
	TRANSPOSE_DOWN 1
	SND_CALL Snd34_Sfx1_559D
	SND_END

Snd36_SfxN:
	LOOP_START
	NVOICE $04, $F0
	NOISE $26
	NOISE $25
	NVOICE $04, $40
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	LOOP_END 2
	NVOICE $10, $B4
	NOISE $40
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	SND_END

Snd37_Sfx1:
	TRANSPOSE_DOWN $0C
	VOICE $04, 8, 12, 0, 0
	SWEEP $17
	OCTAVE 6
	NOTE C_, 8
	VOICE $04, 0, 11, 0, 0
	SND_CALL Snd37_Sfx1_5651
	VOLUME $03
	SND_CALL Snd37_Sfx1_5651
	ATTEN 1
	SND_CALL Snd37_Sfx1_5651
	SND_END
Snd37_Sfx1_5651:
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd37_SfxN:
	NVOICE $08, $D3
	NOISE $23
	NOISE $17
	NOISE $15
	NOISE $13
	NOISE $11
	NOISE $18
	NOISE $18
	SND_END

Snd3A_Sfx1:
	VOICE $04, 8, 8, 0, 0
	SND_CALL Snd3A_Sfx1_566A
	SND_END
Snd3A_Sfx1_566A:
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 7
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_RET

Snd3A_SfxN:
	NVOICE $04, $90
	NOISE $12
	NOISE $13
	NOISE $24
	NOISE $25
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $33
	NOISE $22
	NOISE $21
	NVOICE $04, $30
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $12
	NOISE $11
	SND_END

Snd3C_Sfx1:
	VOICE $04, 8, 9, 0, 0
	TRANSPOSE_DOWN 6
	SND_CALL Snd3A_Sfx1_566A
	SND_END

Snd3C_SfxN:
	NVOICE $04, $90
	NOISE $22
	NOISE $23
	NOISE $34
	NOISE $35
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $43
	NOISE $32
	NOISE $31
	NVOICE $04, $30
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $32
	NOISE $33
	SND_END

Snd3D_Sfx1:
	VOICE $01, 0, 15, 0, 0
	TRANSPOSE_UP 8
	OCTAVE 3
	SND_CALL Snd3D_Sfx1_56E1
	VOLUME $0A
	SND_CALL Snd3D_Sfx1_56E1
	ATTEN 2
	SND_CALL Snd3D_Sfx1_56E1
	ATTEN 4
	SND_CALL Snd3D_Sfx1_56E1
	ATTEN 6
	SND_CALL Snd3D_Sfx1_56E1
	VOLUME $02
	SND_CALL Snd3D_Sfx1_56E1
	SND_END

Snd3D_SfxN:
	NVOICE $08, $84
	NOISE $34
	NOISE $23
	NOISE $34
	NOISE $35
	SND_END
	db $FF
Snd3D_Sfx1_56E1:
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
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd3E_Sfx1:
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0A
	OCTAVE 3
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
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	VOLUME $0A
	OCTAVE 4
	SND_CALL Snd3E_Sfx1_573F
	ATTEN 4
	SND_CALL Snd3E_Sfx1_573F
	ATTEN 6
	SND_CALL Snd3E_Sfx1_573F
	ATTEN 7
	SND_CALL Snd3E_Sfx1_573F
	SND_END
Snd3E_Sfx1_573F:
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_RET

Snd3E_SfxN:
	NVOICE $04, $60
	NOISE $44
	NOISE $33
	NOISE $42
	NOISE $43
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $21
	SND_END

Snd3F_Sfx1:
	VOICE $02, 8, 15, 0, 0
	SND_CALL Snd3F_Sfx1_5763
	SND_CALL Snd3F_Sfx1_578E
	VOLUME $05
	SND_CALL Snd3F_Sfx1_57CD
	SND_END
Snd3F_Sfx1_5763:
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
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
	NOTE C#, 1
	SND_RET
Snd3F_Sfx1_578E:
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET
Snd3F_Sfx1_57CD:
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET

Snd20_Sfx1:
	LOOP_START
	VOICE $04, 0, 15, 0, 0
	TRANSPOSE_UP $0F
	OCTAVE 2
	SND_CALL Snd20_Sfx1_5831
	VOLUME $04
	SND_CALL Snd20_Sfx1_5831
	LOOP_END 4

Snd40_Sfx1:
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $08, 8, 10, 0, 0
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END
Snd20_Sfx1_5831:
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
	SND_RET

Snd20_Sfx2:
	DETUNE $E0
	TRANSPOSE_UP $0F
	LOOP_START
	VOICE $04, 8, 2, 0, 0
	OCTAVE 4
	SND_CALL Snd20_Sfx1_5831
	VOICE $04, 8, 6, 0, 0
	SND_CALL Snd20_Sfx1_5831
	LOOP_END 4
	SND_END

Snd20_SfxN:
	LOOP_START
	NVOICE $10, $00
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_REST
	NOISE_REST
	LOOP_END 4

Snd40_SfxN:
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $36
	NOISE $37
	NOISE $55
	NOISE $53
	NOISE $54
	NOISE $56
	NOISE $57
	NOISE $51
	NOISE $52
	NVOICE $10, $A5
	NOISE $53
	NOISE $54
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	SND_END

Snd41_Sfx1:
	SND_END

Snd41_Ch1:
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_UP 8
	SND_CALL Snd41_Ch1_58DE
	VOLUME $0A
	SND_CALL Snd41_Ch1_5900
	SND_END

Snd41_Ch2:
	VOICE $01, 4, 15, 0, 0
	REST 2
	TRANSPOSE_UP 7
	SND_CALL Snd41_Ch1_58DE
	VOLUME $0A
	SND_CALL Snd41_Ch1_5900
	SND_END

Snd41_Ch3:
	VOICE $01, 9, 2, 0, 0
	REST 2
	TRANSPOSE_UP 3
	SND_CALL Snd41_Ch1_58DE
	VOICE $01, 9, 4, 0, 0
	LOOP_START
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 4
	VOICE $01, 9, 6, 0, 0
	LOOP_START
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	LOOP_END 4
	SND_END

Snd41_Drm:
	SND_END
Snd41_Ch1_58DE:
	VIBRATO $8A, 0, 15
	OCTAVE 3
	LOOP_START
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
	LOOP_END 2
	OCTAVE 5
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
	SND_RET
Snd41_Ch1_5900:
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 3
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 4
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 5
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	VOLUME $02
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd42_Sfx1:
	VOICE $04, 4, 15, 0, 0
	SWEEP $1D
	OCTAVE 5
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
	VOLUME $0A
	ATTEN 2
	SND_CALL Snd42_Sfx1_598F
	ATTEN 3
	SND_CALL Snd42_Sfx1_598F
	ATTEN 4
	SND_CALL Snd42_Sfx1_598F
	ATTEN 5
	SND_CALL Snd42_Sfx1_598F
	ATTEN 6
	SND_CALL Snd42_Sfx1_598F
	SND_END
Snd42_Sfx1_598F:
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd42_SfxN:
	NVOICE $04, $60
	NOISE $44
	NOISE $33
	NOISE $42
	NOISE $43
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $21
	SND_END

Snd43_Sfx1:
	VOICE $04, 4, 12, 0, 0
	TRANSPOSE_UP $0F
	OCTAVE 6
	LOOP_START
	SWEEP $1D
	NOTE A_, 8
	LOOP_END 3
	SWEEP $00
	VOICE $04, 0, 10, 0, 0
	TRANSPOSE_UP 4
	OCTAVE 2
	SND_CALL Snd43_Sfx1_59C8
	ATTEN 5
	SND_CALL Snd43_Sfx1_59C8
	ATTEN 7
	SND_CALL Snd43_Sfx1_59C8
	SND_END
Snd43_Sfx1_59C8:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd43_SfxN:
	NVOICE $04, $A0
	LOOP_START
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	LOOP_END 3
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	SND_END

Snd45_Sfx1:
	VOICE $04, 0, 15, 0, 0
	SND_CALL Snd45_Sfx1_59FF
	VOLUME $0A
	SND_CALL Snd45_Sfx1_59FF
	ATTEN 2
	SND_CALL Snd45_Sfx1_59FF
	ATTEN 4
	SND_CALL Snd45_Sfx1_59FF
	ATTEN 6
	SND_CALL Snd45_Sfx1_59FF
	SND_END
Snd45_Sfx1_59FF:
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	SND_RET

Snd45_SfxN:
	NVOICE $04, $F0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	VOLUME $0A
	SND_CALL Snd45_SfxN_5A33
	VOLUME $08
	SND_CALL Snd45_SfxN_5A33
	VOLUME $06
	SND_CALL Snd45_SfxN_5A33
	VOLUME $04
	SND_CALL Snd45_SfxN_5A33
	VOLUME $02
	SND_CALL Snd45_SfxN_5A33
	SND_END
Snd45_SfxN_5A33:
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_RET

Snd46_Sfx1:
	VOICE $04, 0, 4, 15, 1
	SWEEP $17
	OCTAVE 6
	LOOP_START
	ATTEN 0
	SND_CALL Snd46_Sfx1_5A6D
	ATTEN 2
	SND_CALL Snd46_Sfx1_5A6D
	LOOP_END 3
	LOOP_START
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	LOOP_END 4
	VOICE $08, 8, 10, 0, 0
	OCTAVE 1
	SND_CALL Snd46_Sfx1_5A7B
	ATTEN 6
	SND_CALL Snd46_Sfx1_5A7B
	ATTEN 7
	SND_CALL Snd46_Sfx1_5A7B
	SND_END
Snd46_Sfx1_5A6D:
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_RET
Snd46_Sfx1_5A7B:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd46_SfxN:
	NVOICE $04, $70
	LOOP_START
	NOISE $54
	NOISE $45
	NOISE $56
	NOISE $57
	NOISE $53
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $54
	NOISE $64
	NOISE $67
	NOISE $64
	NOISE $55
	NOISE $66
	NOISE $57
	NOISE $63
	NOISE $52
	NOISE $64
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $53
	LOOP_END 3
	LOOP_START
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	LOOP_END 4
	NOISE $36
	NOISE $37
	NOISE $55
	NOISE $53
	NOISE $54
	NOISE $56
	NOISE $57
	NOISE $51
	NOISE $52
	NVOICE $14, $A5
	NOISE $53
	NOISE $54
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	SND_END

Snd47_Sfx1:
	VOICE $04, 0, 13, 0, 0
	SWEEP $1D
	OCTAVE 3
	SND_CALL Snd47_Sfx1_5AFD
	OCTAVE 4
	SND_CALL Snd47_Sfx1_5AFD
	OCTAVE 5
	SND_CALL Snd47_Sfx1_5AFD
	VOLUME $06
	SND_CALL Snd47_Sfx1_5AFD
	ATTEN 1
	SND_CALL Snd47_Sfx1_5AFD
	ATTEN 2
	SND_CALL Snd47_Sfx1_5AFD
	ATTEN 3
	SND_CALL Snd47_Sfx1_5AFD
	ATTEN 4
	SND_CALL Snd47_Sfx1_5AFD
	SND_END
Snd47_Sfx1_5AFD:
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
	SND_RET

Snd47_SfxN:
	NVOICE $10, $5C
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	SND_END

Snd48_Sfx1:
	VOICE $04, 0, 15, 0, 0
	SWEEP $1D
	TRANSPOSE_UP 8
	OCTAVE 2
	SND_CALL Snd48_Sfx1_5B49
	OCTAVE 3
	SND_CALL Snd48_Sfx1_5B49
	OCTAVE 4
	SND_CALL Snd48_Sfx1_5B49
	OCTAVE 5
	SND_CALL Snd48_Sfx1_5B49
	OCTAVE 6
	SND_CALL Snd48_Sfx1_5B49
	VOLUME $0A
	OCTAVE 4
	SND_CALL Snd48_Sfx1_5B56
	OCTAVE 3
	SND_CALL Snd48_Sfx1_5B56
	OCTAVE 2
	SND_CALL Snd48_Sfx1_5B56
	ATTEN 6
	SND_CALL Snd48_Sfx1_5B56
	VOLUME $02
	SND_CALL Snd48_Sfx1_5B56
	SND_END
Snd48_Sfx1_5B49:
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
Snd48_Sfx1_5B56:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	SND_RET

Snd48_SfxN:
	NVOICE $10, $A5
	NOISE $44
	NOISE $33
	NOISE $42
	NOISE $43
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	SND_END

Snd49_Sfx1:
	VOICE $04, 0, 4, 15, 1
	SWEEP $17
	OCTAVE 6
	LOOP_START
	ATTEN 0
	SND_CALL Snd49_Sfx1_5B83
	ATTEN 2
	SND_CALL Snd49_Sfx1_5B83
	LOOP_END 3
	SND_END
Snd49_Sfx1_5B83:
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_RET

Snd49_SfxN:
	NVOICE_HOLD $04
	LOOP_START
	NOISE_HOLD 7, $54
	NOISE_HOLD 7, $45
	NOISE_HOLD 7, $56
	NOISE_HOLD 7, $57
	NOISE_HOLD 7, $53
	NOISE_HOLD 7, $52
	NOISE_HOLD 7, $54
	NOISE_HOLD 7, $55
	NOISE_HOLD 7, $56
	NOISE_HOLD 7, $57
	NOISE_HOLD 7, $54
	NOISE_HOLD 7, $64
	NOISE_HOLD 7, $67
	NOISE_HOLD 7, $64
	NOISE_HOLD 7, $55
	NOISE_HOLD 7, $66
	NOISE_HOLD 7, $57
	NOISE_HOLD 7, $63
	NOISE_HOLD 7, $52
	NOISE_HOLD 7, $64
	NOISE_HOLD 7, $55
	NOISE_HOLD 7, $54
	NOISE_HOLD 7, $53
	NOISE_HOLD 7, $52
	NOISE_HOLD 7, $51
	NOISE_HOLD 7, $53
	LOOP_END 3
	NVOICE_HOLD $08
	NOISE_HOLD 15, $57
	NOISE_HOLD 15, $56
	NOISE_HOLD 15, $51
	NOISE_HOLD 15, $52
	NOISE_HOLD 15, $53
	NOISE_HOLD 15, $54
	NOISE_HOLD 15, $55
	NOISE_HOLD 15, $56
	NOISE_HOLD 10, $51
	NOISE_HOLD 10, $52
	NOISE_HOLD 10, $53
	NOISE_HOLD 10, $54
	NOISE_HOLD 10, $55
	NOISE_HOLD 10, $56
	NOISE_HOLD 8, $51
	NOISE_HOLD 8, $52
	NOISE_HOLD 8, $53
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $55
	NOISE_HOLD 8, $56
	NOISE_HOLD 5, $51
	NOISE_HOLD 5, $52
	NOISE_HOLD 5, $53
	NOISE_HOLD 5, $54
	NOISE_HOLD 5, $55
	NOISE_HOLD 5, $56
	NOISE_HOLD 4, $51
	NOISE_HOLD 4, $52
	NOISE_HOLD 4, $53
	NOISE_HOLD 4, $54
	NOISE_HOLD 4, $55
	NOISE_HOLD 4, $56
	NOISE_HOLD 3, $51
	NOISE_HOLD 3, $52
	NOISE_HOLD 3, $53
	NOISE_HOLD 3, $54
	NOISE_HOLD 3, $55
	NOISE_HOLD 3, $56
	NOISE_HOLD 2, $51
	NOISE_HOLD 2, $52
	NOISE_HOLD 2, $53
	NOISE_HOLD 2, $54
	NOISE_HOLD 2, $55
	NOISE_HOLD 2, $56
	SND_END

Snd4A_Sfx1:
	VOICE $04, 0, 15, 0, 0
	OCTAVE 2
	SND_CALL Snd4A_Sfx1_5C41
	VOLUME $0C
	ATTEN 4
	SND_CALL Snd4A_Sfx1_5C41
	ATTEN 5
	SND_CALL Snd4A_Sfx1_5C41
	ATTEN 7
	SND_CALL Snd4A_Sfx1_5C41
	VOLUME $03
	SND_CALL Snd4A_Sfx1_5C41
	SND_END
Snd4A_Sfx1_5C41:
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd4A_SfxN:
	NVOICE $08, $90
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $07
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $05
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $03
	SND_CALL Snd4A_SfxN_5C74
	SND_END
Snd4A_SfxN_5C74:
	NOISE $61
	NOISE $62
	NOISE $57
	NOISE $55
	NOISE $56
	NOISE $62
	NOISE $61
	NOISE $55
	NOISE $66
	NOISE $57
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $60
	NOISE $56
	NOISE $57
	SND_RET

Snd4B_Sfx1:
	VOICE $04, 4, 15, 0, 0
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $08, 8, 10, 0, 0
	OCTAVE 2
	SND_CALL Snd4B_Sfx1_5CA1
	ATTEN 6
	SND_CALL Snd4B_Sfx1_5CA1
	ATTEN 7
	SND_CALL Snd4B_Sfx1_5CA1
	SND_END
Snd4B_Sfx1_5CA1:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd4B_SfxN:
	NVOICE $04, $F0
	NOISE $47
	NOISE $48
	NVOICE $14, $C5
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $67
	SND_END

Snd4C_Sfx2:
	LOOP_START
	VOICE $08, 12, 2, 0, 0
	OCTAVE 6
	NOTE C_, 1
	REST 1
	NOTE C_, 8
	VOICE $08, 12, 4, 0, 0
	NOTE C_, 8
	LOOP_END 4
	SND_END

Snd4D_Sfx1:
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $08, 8, 10, 0, 0
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd4D_SfxN:
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NVOICE $08, $A0
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	VOLUME $08
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	VOLUME $06
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	VOLUME $04
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	VOLUME $02
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_END
	db $41, $42, $43, $44, $45, $46, $FD

Snd4E_Sfx1:
	VOICE $04, 0, 15, 0, 0
	OCTAVE 1
	NOTE C_, 4
	TRANSPOSE_UP $0C
	OCTAVE 6
	SND_CALL Snd4E_Sfx1_5D6F
	VOLUME $08
	SND_CALL Snd4E_Sfx1_5D6F
	ATTEN 4
	SND_CALL Snd4E_Sfx1_5D6F
	ATTEN 7
	SND_CALL Snd4E_Sfx1_5D6F
	SND_END

Snd4E_SfxN:
	NVOICE $04, $D0
	NOISE $78
	NOISE $87
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $04, $D0
	NOISE $78
	NOISE $87
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $D0
	NOISE $78
	NOISE $87
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $26
	NOISE $27
	NOISE $45
	NOISE $43
	NOISE $44
	NOISE $46
	NOISE $47
	NOISE $41
	NOISE $42
	NVOICE $08, $A3
	NOISE $43
	NOISE $44
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $43
	SND_END
Snd4E_Sfx1_5D6F:
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE B_, 1
	SND_RET

Snd50_Sfx1:
	VOICE $04, 0, 15, 0, 0
	OCTAVE 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	REST 2
	VOICE $10, 0, 10, 0, 0
	NOTE E_, 8
	VOLUME $02
	NOTE E_, 8
	SND_END

Snd50_SfxN:
	NVOICE $10, $F0
	NOISE $22
	NVOICE $04, $00
	NOISE $22
	NVOICE $20, $C5
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

Snd51_Sfx1:
	VOICE $06, 8, 12, 0, 0
	SWEEP $1F
	TRANSPOSE_DOWN 8
	OCTAVE 5
	SND_CALL Snd51_Sfx1_5DC2
	ATTEN 5
	SND_CALL Snd51_Sfx1_5DC2
	ATTEN 6
	SND_CALL Snd51_Sfx1_5DC2
	ATTEN 7
	SND_CALL Snd51_Sfx1_5DC2
	VOLUME $03
	SND_CALL Snd51_Sfx1_5DC2
	SND_END
Snd51_Sfx1_5DC2:
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	SND_RET

Snd52_Sfx1:
	VOICE $02, 4, 12, 0, 0
	TRANSPOSE_UP $0F
	OCTAVE 6
	LOOP_START
	SWEEP $1D
	NOTE A_, 8
	LOOP_END $0A
	SWEEP $00
	VOICE $04, 0, 10, 0, 0
	TRANSPOSE_UP 4
	OCTAVE 2
	SND_CALL Snd52_Sfx1_5DF0
	ATTEN 5
	SND_CALL Snd52_Sfx1_5DF0
	ATTEN 7
	SND_CALL Snd52_Sfx1_5DF0
	SND_END
Snd52_Sfx1_5DF0:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd52_SfxN:
	NVOICE $02, $A0
	LOOP_START
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	LOOP_END $0A
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	SND_END

Snd53_Sfx1:
	VOICE $04, 0, 10, 0, 0
	OCTAVE 5
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 6
	ATTEN 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	VOLUME $02
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_END

Snd53_SfxN:
	NVOICE $04, $F0
	NOISE $37
	NVOICE $08, $64
	NOISE $17
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	SND_END

Snd54_Sfx1:
	VOICE $04, 0, 15, 0, 0
	OCTAVE 2
	SND_CALL Snd54_Sfx1_5E54
	VOLUME $0B
	SND_CALL Snd54_Sfx1_5E54
	ATTEN 5
	SND_CALL Snd54_Sfx1_5E54
	ATTEN 6
	SND_CALL Snd54_Sfx1_5E54
	SND_END
Snd54_Sfx1_5E54:
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	SND_RET

Snd54_SfxN:
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	VOLUME $0A
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	VOLUME $08
	SND_CALL Snd54_SfxN_5E76
	VOLUME $04
	SND_CALL Snd54_SfxN_5E76
	VOLUME $02
	SND_CALL Snd54_SfxN_5E76
	SND_END
Snd54_SfxN_5E76:
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	SND_RET

Snd56_Sfx1:
	LOOP2_START
	TRANSPOSE_UP 2
	SND_CALL Snd56_Sfx1_5E8B
	TRANSPOSE_UP $0F
	SND_CALL Snd56_Sfx1_5E8B
	LOOP2_END 2
	SND_END
Snd56_Sfx1_5E8B:
	LOOP_START
	VOICE $01, 0, 12, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	VOLUME $03
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END $20
	TRANSPOSE_UP 2
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	VOICE $04, 8, 6, 0, 0
	OCTAVE 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	REST 2
	VOICE $20, 8, 4, 0, 0
	NOTE E_, 8
	ATTEN 2
	NOTE E_, 8
	SND_RET

Snd56_Sfx2:
	LOOP2_START
	VOICE $04, 5, 6, 0, 0
	REST 8
	OCTAVE 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	REST 2
	NOTE C_HI, 8
	LEN_UNIT 8
	NOTE C_HI, $0C
	LEN_UNIT 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	REST 4
	NOTE E_, 8
	LEN_UNIT 2
	LOOP_START
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	LOOP_END 4
	REST $0F
	LOOP2_END $0A
	SND_END

Snd56_SfxN:
	LOOP2_START
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NVOICE $08, $A0
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $05
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $04
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $03
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $02
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $01
	SND_CALL Snd56_SfxN_5F1B
	NVOICE $30, $10
	NOISE $46
	LOOP2_END $0A
	SND_END
Snd56_SfxN_5F1B:
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_RET

Snd57_Sfx2:
	LOOP2_START
	TRANSPOSE_UP 2
	SND_CALL Snd57_Sfx2_5F30
	TRANSPOSE_UP $0F
	SND_CALL Snd57_Sfx2_5F30
	LOOP2_END 2
	SND_END
Snd57_Sfx2_5F30:
	LOOP_START
	VOICE $01, 8, 2, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	VOICE $01, 8, 4, 0, 0
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END $20
	TRANSPOSE_UP 1
	OCTAVE 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	VOICE $04, 11, 6, 0, 0
	OCTAVE 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	REST 2
	LEN_UNIT $20
	NOTE E_, 0
	SND_RET

Snd57_SfxN:
	LOOP2_START
	NVOICE $04, $A0
	NOISE $78
	NOISE $87
	LEN_UNIT 8
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $04
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $03
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $02
	SND_CALL Snd56_SfxN_5F1B
	VOLUME $01
	SND_CALL Snd56_SfxN_5F1B
	SND_CALL Snd56_SfxN_5F1B
	NVOICE $30, $10
	NOISE $46
	LOOP2_END $0A
	SND_END

Snd58_Sfx1:
	TRANSPOSE_UP $0B
	VOICE $01, 8, 12, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	LOOP_START
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $20
Snd58_Sfx1_5FA0:
	LOOP_START
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $18
	VOLUME $03
	LOOP_START
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $28
	SND_END

Snd5A_SfxN:
	NVOICE $01, $F0
	NOISE $58
	NOISE $57
	NOISE $56
	NOISE $54
	NVOICE $10, $F0
	NOISE $22
	NVOICE $04, $00
	NOISE $22
	NVOICE $20, $A7
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

Snd5A_Ch1:
	VOICE $08, 8, 15, 0, 0
	OCTAVE 3
	SWEEP $1D
	NOTE C_, 4
	SND_END

Snd5A_Ch2:
	SND_END

Snd5B_Sfx1:
	VOICE $01, 8, 15, 0, 0
	TRANSPOSE_DOWN 8
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	SND_CALL Snd5B_Sfx1_6006
	VOICE $02, 8, 10, 0, 0
	SND_CALL Snd5B_Sfx1_6006
	TRANSPOSE_DOWN 0
	ATTEN 5
	SND_CALL Snd5B_Sfx1_6006
	TRANSPOSE_UP 2
	ATTEN 6
	SND_CALL Snd5B_Sfx1_6006
	TRANSPOSE_UP 4
	ATTEN 7
	SND_CALL Snd5B_Sfx1_6006
	TRANSPOSE_UP 6
	VOLUME $02
	SND_CALL Snd5B_Sfx1_6006
	SND_END
Snd5B_Sfx1_6006:
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd5C_Sfx1:
	VOICE $02, 0, 12, 0, 0
	OCTAVE 1
	NOTE C_, 4
	VOLUME $07
	OCTAVE 6
	SND_CALL Snd5C_Sfx1_602D
	ATTEN 3
	SND_CALL Snd5C_Sfx1_602D
	ATTEN 4
	SND_CALL Snd5C_Sfx1_602D
	ATTEN 5
	SND_CALL Snd5C_Sfx1_602D
	SND_END
Snd5C_Sfx1_602D:
	NOTE F_, 1
	NOTE C_, 2
	NOTE G_, 1
	NOTE D#, 2
	NOTE D_, 1
	NOTE C_HI, 2
	NOTE D_, 1
	NOTE D#, 2
	NOTE A_, 1
	NOTE D_, 2
	NOTE C_HI, 1
	NOTE C#, 2
	NOTE B_, 1
	SND_RET

Snd5C_SfxN:
	NVOICE $01, $F0
	NOISE $78
	NOISE $87
	NOISE $58
	NOISE $57
	NVOICE $04, $D0
	NOISE $78
	NOISE $87
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $D0
	NOISE $78
	NOISE $87
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $26
	NOISE $27
	NOISE $45
	NOISE $43
	NOISE $44
	NOISE $46
	NOISE $47
	NOISE $41
	NOISE $42
	NVOICE $08, $A3
	NOISE $43
	NOISE $44
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $43
	SND_END

Snd5F_SfxN:
	NVOICE $16, $F0
	SND_CALL Snd5F_SfxN_6073
	SND_END

Snd60_SfxN:
	NVOICE $04, $F0
	SND_CALL Snd5F_SfxN_6073
	SND_END
Snd5F_SfxN_6073:
	NOISE $11
	NOISE $11
	NOISE $12
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
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $62
	NOISE $63
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $67
	VOLUME $05
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	VOLUME $03
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	VOLUME $02
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	VOLUME $02
	NOISE $63
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $67
	SND_RET

Snd61_Sfx1:
	VOICE $04, 4, 13, 0, 0
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $08, 8, 8, 0, 0
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd61_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 13, $78
	NOISE_HOLD 13, $87
	NOISE_HOLD 13, $11
	NOISE_HOLD 13, $12
	NOISE_HOLD 13, $13
	NOISE_HOLD 12, $78
	NOISE_HOLD 12, $87
	NOISE_HOLD 12, $24
	NOISE_HOLD 12, $25
	NOISE_HOLD 12, $26
	NOISE_HOLD 11, $78
	NOISE_HOLD 11, $87
	NOISE_HOLD 11, $17
	NOISE_HOLD 11, $16
	NOISE_HOLD 11, $15
	NOISE_HOLD 10, $36
	NOISE_HOLD 10, $37
	NOISE_HOLD 9, $55
	NOISE_HOLD 9, $53
	NOISE_HOLD 8, $54
	NOISE_HOLD 8, $56
	NOISE_HOLD 7, $57
	NOISE_HOLD 6, $51
	NOISE_HOLD 5, $52
	SND_END

Snd62_Sfx1:
	LOOP_START
	VOICE $02, 8, 10, 0, 0
	SWEEP $17
	OCTAVE 4
	NOTE C_, 8
	VOLUME $04
	SWEEP $17
	OCTAVE 4
	NOTE C_, 8
	ATTEN 1
	SWEEP $17
	OCTAVE 4
	NOTE C_, 8
	ATTEN 2
	SWEEP $17
	OCTAVE 4
	NOTE C_, 8
	LOOP_END 4
	SND_END

Snd63_SfxN:
	NVOICE_HOLD $02
	NOISE_HOLD 15, $78
	NOISE_HOLD 15, $87
	NVOICE_HOLD $04
	NOISE_HOLD 15, $6D
	NOISE_HOLD 15, $5C
	NOISE_HOLD 15, $4B
	NOISE_HOLD 15, $3A
	NOISE_HOLD 15, $29
	NOISE_HOLD 15, $18
	NOISE_HOLD 8, $6D
	NOISE_HOLD 8, $5C
	NOISE_HOLD 8, $4B
	NOISE_HOLD 8, $3A
	NOISE_HOLD 8, $29
	NOISE_HOLD 8, $18
	NOISE_HOLD 4, $6D
	NOISE_HOLD 4, $5C
	NOISE_HOLD 4, $4B
	NOISE_HOLD 4, $3A
	NOISE_HOLD 4, $29
	NOISE_HOLD 4, $18
	NOISE_HOLD 3, $6D
	NOISE_HOLD 3, $5C
	NOISE_HOLD 3, $4B
	NOISE_HOLD 3, $3A
	NOISE_HOLD 3, $29
	NOISE_HOLD 3, $18
	NOISE_HOLD 2, $6D
	NOISE_HOLD 2, $5C
	NOISE_HOLD 2, $4B
	NOISE_HOLD 2, $3A
	NOISE_HOLD 2, $29
	NOISE_HOLD 2, $18
	NOISE_HOLD 1, $6D
	NOISE_HOLD 1, $5C
	NOISE_HOLD 1, $4B
	NOISE_HOLD 1, $3A
	NOISE_HOLD 1, $29
	NOISE_HOLD 1, $18
	SND_END

Snd64_Sfx1:
	LOOP_START
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	LOOP_END 5
	VOICE $08, 8, 10, 0, 0
	OCTAVE 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 7
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_END

Snd64_Sfx2:
	SND_END

Snd64_SfxN:
	LOOP_START
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $11
	NOISE $12
	NOISE $13
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $F0
	NOISE $78
	NOISE $87
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	LOOP_END 5
	NOISE $36
	NOISE $37
	NOISE $55
	NOISE $53
	NOISE $54
	NOISE $56
	NOISE $57
	NOISE $51
	NOISE $52
	NVOICE $14, $88
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $63
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $67
	NOISE $73
	NOISE $74
	NOISE $75
	NOISE $76
	NOISE $77
	SND_END

Snd64_Ch1:
	SND_END

Snd65_Sfx1:
	VOICE $02, 4, 15, 0, 0
	SWEEP $4D
	OCTAVE 5
	NOTE C_, 8
	VOICE $02, 0, 10, 0, 0
	SND_CALL Snd65_Sfx1_6212
	ATTEN 3
	SND_CALL Snd65_Sfx1_6212
	ATTEN 4
	SND_CALL Snd65_Sfx1_6212
	ATTEN 5
	SND_CALL Snd65_Sfx1_6212
	SND_END
Snd65_Sfx1_6212:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_RET

Snd65_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 15, $33
	NOISE_HOLD 15, $14
	NOISE_HOLD 15, $13
	NOISE_HOLD 15, $12
	NOISE_HOLD 15, $11
	NOISE_HOLD 15, $18
	NOISE_HOLD 15, $18
	NOISE_HOLD 15, $08
	NOISE_HOLD 15, $08
	NOISE_HOLD 15, $08
	NOISE_HOLD 15, $08
	SND_END

Snd8E_Sfx1:
	TRANSPOSE_DOWN 8

Snd66_Sfx1:
	VOICE $04, 0, 5, 0, 0
	DETUNE $FE
	REST 3
	SND_CALL Snd66_Sfx1_6256
	ATTEN 3
	SND_CALL Snd66_Sfx1_62AE
	SND_END

Snd8E_Sfx2:
	TRANSPOSE_DOWN 8

Snd66_Sfx2:
	VOICE $04, 8, 2, 0, 0
	SND_CALL Snd66_Sfx1_6256
	VOICE $04, 8, 6, 0, 0
	SND_CALL Snd66_Sfx1_62AE
	SND_END
Snd66_Sfx1_6256:
	OCTAVE 5
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
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
	NOTE C#, 1
	OCTAVE 5
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	LOOP_END 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET
Snd66_Sfx1_62AE:
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	SND_RET

Snd67_Sfx1:
	VOICE $04, 0, 4, 15, 1
	SWEEP $17
	OCTAVE 6
	LOOP_START
	ATTEN 0
	SND_CALL Snd67_Sfx1_62F9
	ATTEN 2
	SND_CALL Snd67_Sfx1_62F9
	LOOP_END 7
	VOLUME $02
	LOOP_START
	ATTEN 0
	SND_CALL Snd67_Sfx1_62F9
	ATTEN 1
	SND_CALL Snd67_Sfx1_62F9
	LOOP_END 6
	SND_END
Snd67_Sfx1_62F9:
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_RET

Snd67_SfxN:
	NVOICE $04, $C0
	LOOP_START
	SND_CALL Snd67_SfxN_6329
	LOOP_END 7
	VOLUME $06
	LOOP_START
	SND_CALL Snd67_SfxN_6329
	LOOP_END 2
	VOLUME $04
	LOOP_START
	SND_CALL Snd67_SfxN_6329
	LOOP_END 2
	VOLUME $02
	LOOP_START
	SND_CALL Snd67_SfxN_6329
	LOOP_END 2
	SND_END
Snd67_SfxN_6329:
	NOISE $54
	NOISE $45
	NOISE $56
	NOISE $57
	NOISE $53
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $54
	NOISE $64
	NOISE $67
	NOISE $64
	NOISE $55
	NOISE $66
	NOISE $57
	NOISE $63
	NOISE $52
	NOISE $64
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $53
	SND_RET

Snd6C_Sfx1:
	VOICE $08, 8, 15, 0, 0
	SWEEP $1F
	OCTAVE 6
	NOTE C_, $0C
	VOLUME $05
	NOTE C_, 4
	SND_END

Snd6D_Sfx1:
	VOICE $04, 8, 15, 0, 0
	SWEEP $1D
	OCTAVE 6
	NOTE C_HI, 0
	SWEEP $15
	OCTAVE 1
	NOTE C_HI, 0
	SND_END

Snd6D_SfxN:
	NVOICE $01, $F0
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NVOICE $04, $A5
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	SND_END

Snd6E_SfxN:
	NVOICE $06, $F0
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NVOICE $0A, $A0
	LOOP_START
	NOISE $54
	NOISE $55
	LOOP_END $0C
	NVOICE $0A, $40
	LOOP_START
	NOISE $54
	NOISE $55
	LOOP_END 8
	SND_END

Snd6F_SfxN:
	NVOICE $02, $F0
	NOISE $22
	NVOICE $10, $D3
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

Snd70_SfxN:
	NVOICE $08, $F0
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NVOICE $04, $F0
	SND_CALL Snd5F_SfxN_6073
	SND_END

Snd71_Sfx1:
	VOICE $01, 0, 12, 0, 0
	OCTAVE 5
	NOTE G_, 3
	NOTE G#, 4
	NOTE A_, 5
	NOTE A#, 6
	NOTE B_, 7
	NOTE C_HI, 8
	NOTE B_, 9
	NOTE A#, $0A
	NOTE A_, $0B
	NOTE G#, $0A
	NOTE G_, 9
	NOTE F#, 8
	NOTE F_, 7
	NOTE E_, 6
	NOTE D#, 5
	NOTE D_, 4
	NOTE C#, 3
	NOTE C_, 2
	VOLUME $06
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END 8
	ATTEN 2
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END 4
	ATTEN 4
	LOOP_START
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	LOOP_END 4
	SND_END

Snd71_SfxN:
	NVOICE_HOLD $14
	NOISE_HOLD 10, $28
	NOISE_HOLD 10, $29
	NOISE_HOLD 9, $2A
	NOISE_HOLD 8, $2B
	NOISE_HOLD 7, $2C
	NOISE_HOLD 6, $2D
	NOISE_HOLD 5, $2E
	SND_END

Snd73_Sfx1:
	VOICE $02, 4, 15, 0, 0
	OCTAVE 5
	SND_CALL Snd4A_Sfx1_5C41
	SND_CALL Snd4A_Sfx1_5C41
	OCTAVE 4
	SND_CALL Snd4A_Sfx1_5C41
	OCTAVE 5
	SND_CALL Snd4A_Sfx1_5C41
	OCTAVE 4
	VOLUME $0C
	ATTEN 4
	SND_CALL Snd4A_Sfx1_5C41
	ATTEN 5
	SND_CALL Snd4A_Sfx1_5C41
	ATTEN 6
	SND_CALL Snd4A_Sfx1_5C41
	ATTEN 7
	SND_CALL Snd4A_Sfx1_5C41
	VOLUME $03
	SND_CALL Snd4A_Sfx1_5C41
	SND_END

Snd73_Sfx2:
	SND_END

Snd73_SfxN:
	NVOICE $08, $F0
	SND_CALL Snd4A_SfxN_5C74
	SND_CALL Snd4A_SfxN_5C74
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $0A
	SND_CALL Snd4A_SfxN_5C74
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $05
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $04
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $03
	SND_CALL Snd4A_SfxN_5C74
	VOLUME $02
	SND_CALL Snd4A_SfxN_5C74
	SND_END

Snd73_Ch1:
	SND_END

Snd73_Ch2:
	SND_END

Snd73_Ch3:
	SND_END

Snd73_Drm:
	SND_END

Snd75_Sfx1:
	VOICE $04, 0, 12, 0, 0
	SWEEP $1F
	OCTAVE 5
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
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	VOICE $04, 4, 15, 0, 0
	TRANSPOSE_UP 8
	OCTAVE 6
	SWEEP $1D
	NOTE C_, 8
	NOTE C_, 8
	SWEEP $00
	VOICE $08, 8, 8, 0, 0
	TRANSPOSE_DOWN 1
	OCTAVE 2
	SND_CALL Snd75_Sfx1_648E
	ATTEN 4
	SND_CALL Snd75_Sfx1_648E
	ATTEN 5
	SND_CALL Snd75_Sfx1_648E
	ATTEN 6
	SND_CALL Snd75_Sfx1_648E
	SND_END
Snd75_Sfx1_648E:
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_RET

Snd75_SfxN:
	NVOICE $04, $50
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NVOICE $04, $F0
	NOISE $37
	NOISE $38
	NVOICE $14, $96
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	SND_END

Snd76_Sfx1:
	VOICE $01, 0, 15, 0, 0
	OCTAVE 6
	SND_CALL Snd76_Sfx1_64D0
	VOLUME $0A
	ATTEN 5
	SND_CALL Snd76_Sfx1_64D0
	ATTEN 3
	SND_CALL Snd76_Sfx1_64D0
	SND_END
Snd76_Sfx1_64D0:
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
	SND_RET

Snd76_SfxN:
	NVOICE $01, $F0
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NVOICE $08, $A5
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	SND_END

Snd77_SfxN:
	NVOICE $01, $F0
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $58
	NVOICE $02, $F0
	SND_CALL Snd5F_SfxN_6073
	SND_END

Snd78_Sfx1:
	VOICE $02, 4, 15, 0, 0
	TRANSPOSE_DOWN 8
	OCTAVE 4
	SND_CALL Snd78_Sfx1_650E
	VOLUME $0A
	SND_CALL Snd78_Sfx1_650E
	ATTEN 5
	SND_CALL Snd78_Sfx1_650E
	SND_END
Snd78_Sfx1_650E:
	NOTE C_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE B_, 1
	SND_RET

Snd78_SfxN:
	NVOICE $01, $F0
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $58
	NVOICE $08, $C5
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	SND_END

Snd79_SfxN:
	NVOICE $10, $A0
	LOOP_START
	SND_CALL Snd79_SfxN_654F
	LOOP_END 3
	VOLUME $08
	LOOP_START
	SND_CALL Snd79_SfxN_654F
	LOOP_END 3
	VOLUME $05
	LOOP_START
	SND_CALL Snd79_SfxN_654F
	LOOP_END 2
	SND_END
Snd79_SfxN_654F:
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	SND_RET

Snd7A_Sfx1:
	VOICE $04, 0, 15, 0, 0
	SWEEP $1F
	OCTAVE 4
	LOOP_START
	SND_CALL Snd7A_Sfx1_6581
	LOOP_END 3
	LOOP_START
	VOLUME $08
	SND_CALL Snd7A_Sfx1_6581
	LOOP_END 3
	VOLUME $0F
	LOOP_START
	SND_CALL Snd7A_Sfx1_6581
	LOOP_END 3
	LEN_UNIT $0A
	ATTEN 6
	SND_CALL Snd7A_Sfx1_6581
	VOLUME $02
	SND_CALL Snd7A_Sfx1_6581
	SND_END
Snd7A_Sfx1_6581:
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	SND_RET

Snd7B_Sfx1:
	VOICE $04, 8, 10, 0, 0
	SWEEP $1F
	OCTAVE 5
	SND_CALL Snd7B_Sfx1_659C
	ATTEN 7
	SND_CALL Snd7B_Sfx1_659C
	SND_END
Snd7B_Sfx1_659C:
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 3
	NOTE A#, 3
	NOTE B_, 3
	NOTE C_HI, 4
	SND_RET

Snd7B_SfxN:
	NVOICE $08, $80
	LOOP_START
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $27
	NOISE $26
	NOISE $25
	VOLUME $03
	LOOP_END 2
	SND_END

Snd7C_SfxN:
	LEN_UNIT $40
	NOISE_REST
	NOISE_REST
	LEN_UNIT 4
	NOISE_REST
	NOISE_REST
	NOISE_REST
	LEN_UNIT $10
	NOISE_REST
	NOISE_REST
	NOISE_REST
	LEN_UNIT $40
	NOISE_REST
	NOISE_REST
	NVOICE $20, $D0
	SND_CALL Snd7C_SfxN_65F7
	NVOICE $10, $C0
	SND_CALL Snd7C_SfxN_65F7
	VOLUME $0B
	SND_CALL Snd7C_SfxN_65F7
	NVOICE $10, $A6
	NOISE $35
	NOISE $46
	NOISE $35
	NOISE $46
	NOISE $45
	NOISE $35
	NOISE $45
	NOISE $35
	NOISE $36
	NOISE $46
	NOISE $36
	NOISE $46
	NOISE $47
	NOISE $37
	NOISE $47
	NOISE $37
	SND_END
Snd7C_SfxN_65F7:
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $34
	NOISE $35
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $44
	NOISE $46
	NOISE $44
	NOISE $46
	NOISE $44
	NOISE $46
	NOISE $45
	NOISE $47
	SND_RET

Snd7C_Ch1:
	VOICE $04, 8, 15, 0, 0
	SWEEP $17
	OCTAVE 4
	NOTE B_, 1
	VOICE $01, 8, 9, 0, 0
	SWEEP $00
	OCTAVE 5
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 7
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	VOLUME $02
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	LEN_UNIT $10
	REST 4
	VOICE $01, 4, 7, 0, 0
	SND_CALL Snd7C_Ch1_6663
	LEN_UNIT $20
	REST 1
	VOICE $01, 4, 7, 0, 0
	SND_CALL Snd7C_Ch1_6663
	LEN_UNIT $10
	REST 1
	VOICE $01, 4, 7, 0, 0
	SND_CALL Snd7C_Ch1_6663
	SND_END

Snd7C_Ch2:
	LEN_UNIT 8
	REST 1
	LEN_UNIT $10
	REST 5
	LEN_UNIT $28
	REST 1
	VOICE $01, 4, 7, 0, 0
	LOOP_START
	SND_CALL Snd7C_Ch1_6663
	LOOP_END 2
	SND_END
Snd7C_Ch1_6663:
	OCTAVE 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	LEN_UNIT 3
	NOTE E_, 1
	LEN_UNIT 1
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
	LEN_UNIT 3
	NOTE F#, 1
	LEN_UNIT 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	LEN_UNIT 3
	NOTE F#, 1
	LEN_UNIT 1
	ATTEN 5
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 1
	ATTEN 6
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	LEN_UNIT 3
	NOTE F#, 1
	LEN_UNIT 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE E_, 1
	SND_RET

Snd7D_Sfx1:
	VOICE $01, 8, 15, 0, 0
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	SND_CALL Snd7D_Sfx1_66C6
	VOLUME $09
	SND_CALL Snd7D_Sfx1_66C6
	ATTEN 5
	SND_CALL Snd7D_Sfx1_66C6
	ATTEN 7
	SND_CALL Snd7D_Sfx1_66C6
	SND_END
Snd7D_Sfx1_66C6:
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_RET

Snd7D_SfxN:
	NVOICE $04, $F0
	NOISE $27
	NVOICE $10, $A5
	NOISE $63
	NOISE $53
	NOISE $43
	NOISE $33
	NOISE $23
	NOISE $13
	NOISE $03
	NVOICE $04, $40
	NOISE $33
	NOISE $23
	NOISE $13
	NOISE $03
	SND_END

Snd85_Sfx1:
	VOICE $01, 0, 15, 0, 0
	OCTAVE 5
	SND_CALL Snd58_Sfx1_5FA0

Snd88_Sfx1:
	VOICE $04, 8, 15, 0, 0
	OCTAVE 6
	NOTE D#, 2
	REST 2
	VOICE $08, 8, 10, 0, 0
	NOTE D#, 8
	ATTEN 5
	NOTE D#, 0
	SND_END

Snd89_Sfx1:
	VOICE $04, 4, 15, 0, 0
	OCTAVE 6
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	REST 4
	LOOP_START
	NOTE D#, 1
	NOTE C_, 1
	LOOP_END $18
	VOLUME $04
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 2
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	SND_END

Snd8A_SfxN:
	NVOICE $04, $A0
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NVOICE $08, $88
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $42
	NOISE $41
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NVOICE $10, $30
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	VOLUME $02
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	VOLUME $01
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd8B_Sfx1:
	VOICE $01, 0, 11, 0, 0
	OCTAVE 4
	TRANSPOSE_DOWN 4
	SND_CALL Snd8B_Sfx1_67A0
	TRANSPOSE_DOWN 2
	SND_CALL Snd8B_Sfx1_67A0
	ATTEN 2
	TRANSPOSE_UP 0
	SND_CALL Snd8B_Sfx1_67A0
	TRANSPOSE_UP 2
	SND_CALL Snd8B_Sfx1_67A0
	ATTEN 0
	TRANSPOSE_UP 4
	SND_CALL Snd8B_Sfx1_67A0
	TRANSPOSE_UP 6
	SND_CALL Snd8B_Sfx1_67A0
	TRANSPOSE_UP 8
	LOOP_START
	OCTAVE 4
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $20
	VOLUME $05
	LOOP_START
	OCTAVE 4
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $10
	SND_END
Snd8B_Sfx1_67A0:
	LOOP2_START
	OCTAVE 4
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE A#, 1
	LOOP2_END 2
	SND_RET

Snd8F_Sfx1:
	LEN_UNIT $40
	REST 2
Snd8F_Sfx1_67AD:
	TRANSPOSE_UP 4
	VOICE $01, 8, 10, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	LOOP_START
	NOTE F#, 1
	NOTE A#, 1
	LOOP_END $30
	LOOP_START
	NOTE F#, 1
	NOTE A#, 1
	LOOP_END $18
	VOLUME $03
	LOOP_START
	NOTE F#, 1
	NOTE A#, 1
	LOOP_END $28
	SND_END

Snd8F_SfxN:
	SND_CALL Snd50_SfxN

Snd90_Sfx1:
	SND_CALL Snd8F_Sfx1_67AD

Snd90_SfxN:
	NVOICE $40, $00
	NOISE_REST
	NOISE_REST
	SND_CALL Snd50_SfxN

Snd94_Sfx1:
	VOICE $02, 0, 15, 0, 0
	OCTAVE 4
	SND_CALL Snd58_Sfx1_5FA0
	db $FF

Snd95_SfxN:
	NVOICE_HOLD $08
	LOOP_START
	NOISE_HOLD 15, $28
	NOISE_HOLD 15, $38
	NOISE_HOLD 15, $48
	NOISE_HOLD 15, $38
	NOISE_HOLD 15, $48
	NOISE_HOLD 15, $58
	LOOP_END 4
	NVOICE_HOLD $10
	NOISE_HOLD 8, $48
	NOISE_HOLD 7, $58
	NOISE_HOLD 6, $68
	NOISE_HOLD 5, $58
	NOISE_HOLD 4, $68
	NOISE_HOLD 3, $78
	SND_END

Snd96_Sfx1:
	VOICE $01, 4, 15, 0, 0
	OCTAVE 5
	TRANSPOSE_UP 8
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	SND_CALL Snd96_Sfx1_6829
	VOICE $03, 0, 9, 0, 0
	SND_CALL Snd96_Sfx1_6829
	ATTEN 5
	SND_CALL Snd96_Sfx1_6829
	ATTEN 7
	SND_CALL Snd96_Sfx1_6829
	SND_END
Snd96_Sfx1_6829:
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 1
	SND_RET

Snd97_Sfx1:
	VOICE $02, 0, 12, 0, 0
	OCTAVE 6
	LOOP_START
	ATTEN 0
	SND_CALL Snd49_Sfx1_5B83
	ATTEN 2
	SND_CALL Snd49_Sfx1_5B83
	LOOP_END 4
	SND_END

Snd98_Sfx1:
	VOICE $03, 0, 15, 0, 0
	TRANSPOSE_DOWN 6
	SND_CALL Snd98_Sfx1_6880
	ATTEN 4
	TRANSPOSE_DOWN 3
	SND_CALL Snd98_Sfx1_6880
	ATTEN 3
	TRANSPOSE_UP 0
	SND_CALL Snd98_Sfx1_6880
	ATTEN 2
	TRANSPOSE_UP 3
	SND_CALL Snd98_Sfx1_6880
	ATTEN 1
	TRANSPOSE_UP 6
	SND_CALL Snd98_Sfx1_6880
	ATTEN 0
	TRANSPOSE_UP 9
	SND_CALL Snd98_Sfx1_6880
	TRANSPOSE_UP $0C
	LOOP_START
	SND_CALL Snd98_Sfx1_6880
	LOOP_END 4
	VOLUME $08
	LOOP_START
	SND_CALL Snd98_Sfx1_6880
	LOOP_END 4
	ATTEN 5
	LOOP_START
	SND_CALL Snd98_Sfx1_6880
	LOOP_END 4
	SND_END
Snd98_Sfx1_6880:
	LOOP2_START
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	LOOP2_END 2
	SND_RET

Snd99_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 15, $38
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $36
	NOISE_HOLD 15, $34
	NVOICE_HOLD $10
	NOISE_HOLD 15, $22
	NVOICE_HOLD $30
	NOISE_HOLD 6, $35
	NOISE_HOLD 6, $34
	NOISE_HOLD 5, $33
	NOISE_HOLD 4, $32
	NOISE_HOLD 3, $31
	NOISE_HOLD 2, $30
	SND_END

Snd99_Ch1:
	VOICE $02, 0, 15, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SND_CALL Snd99_Ch1_693A
	VOLUME $0A
	SND_CALL Snd99_Ch1_693A
	ATTEN 2
	SND_CALL Snd99_Ch1_693A
	ATTEN 4
	SND_CALL Snd99_Ch1_693A
	ATTEN 6
	SND_CALL Snd99_Ch1_693A
	ATTEN 7
	SND_CALL Snd99_Ch1_693A
	SND_END

Snd99_Ch2:
	VOICE $01, 0, 15, 0, 0
	SND_CALL Snd99_Ch2_6948
	ATTEN 1
	TRANSPOSE_DOWN 1
	SND_CALL Snd99_Ch2_6948
	ATTEN 2
	TRANSPOSE_DOWN 2
	SND_CALL Snd99_Ch2_6948
	ATTEN 3
	TRANSPOSE_DOWN 3
	SND_CALL Snd99_Ch2_6948
	ATTEN 4
	TRANSPOSE_DOWN 4
	SND_CALL Snd99_Ch2_6948
	ATTEN 5
	TRANSPOSE_DOWN 5
	SND_CALL Snd99_Ch2_6948
	ATTEN 6
	TRANSPOSE_DOWN 6
	SND_CALL Snd99_Ch2_6948
	ATTEN 7
	TRANSPOSE_DOWN 7
	SND_CALL Snd99_Ch2_6948
	VOLUME $06
	TRANSPOSE_DOWN 8
	SND_CALL Snd99_Ch2_6948
	ATTEN 1
	TRANSPOSE_DOWN 9
	SND_CALL Snd99_Ch2_6948
	ATTEN 2
	TRANSPOSE_DOWN $0A
	SND_CALL Snd99_Ch2_6948
	ATTEN 3
	TRANSPOSE_DOWN $0B
	SND_CALL Snd99_Ch2_6948
	ATTEN 4
	TRANSPOSE_DOWN $0C
	SND_CALL Snd99_Ch2_6948
	SND_END

Snd99_Ch3:
	VOICE $02, 10, 2, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 6
	SND_CALL Snd99_Ch1_693A
	SND_CALL Snd99_Ch1_693A
	VOICE $02, 10, 4, 0, 0
	SND_CALL Snd99_Ch1_693A
	SND_CALL Snd99_Ch1_693A
	VOICE $02, 10, 6, 0, 0
	SND_CALL Snd99_Ch1_693A
	SND_CALL Snd99_Ch1_693A
	SND_END
Snd99_Ch1_693A:
	NOTE F_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	SND_RET
Snd99_Ch2_6948:
	OCTAVE 6
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	SND_RET

Snd9A_Sfx2:
	SND_END

Snd9B_Sfx2:
	SND_END

Snd9C_Sfx2:
	SND_END

Snd9D_Sfx2:
	SND_END

Snd9E_Sfx1:
	VOICE $08, 0, 15, 15, 2
	VIBRATO $01, 0, 8
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	ATTEN 7
	NOTE G_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE G_, 4
	VIBRATO $02, 2, 6
	ATTEN 6
	NOTE G_, 8
	SND_END

Snd9E_Sfx2:
	VOICE $08, 1, 2, 12, 3
	VIBRATO $01, 0, 8
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	VOICE $08, 1, 4, 0, 0
	NOTE G_, 2
	VOICE $08, 1, 2, 12, 3
	NOTE E_, 2
	NOTE G_, 4
	VIBRATO $02, 2, 6
	VOICE $08, 1, 4, 0, 0
	NOTE G_, 8
	SND_END

; PlayPcm: 1-bit PCM. CH3 plays a fixed wave at the lowest frequency and every sample
; bit (LSB first) sets NR32 to 100% or mute, ~10.5 kHz, with interrupts off, until a
; $DD byte.
B14_PlayPcm:
	ld c, $26
	ld a, $8F
	ldh [c], a
	dec c
	ld a, $FF
	ldh [c], a
	dec c
	ld a, $77
	ldh [c], a
	ld c, $1A
	ld a, $00
	ldh [c], a
	ld hl, B14_PcmWave
	ld b, $10
	ld c, $30
.l69A9:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .l69A9
	ld c, $1A
	ld a, $80
	ldh [c], a
	inc c
	ld a, $00
	ldh [c], a
	inc c
	ld a, $20
	ldh [c], a
	inc c
	ld a, $00
	ldh [c], a
	inc c
	ld a, $80
	ldh [c], a
	ld a, [wPcmPtr]
	ld l, a
	ld a, [wPcmPtr + $01]
	ld h, a
	di

B14_PcmByte:
	ld b, $08
	ld c, $1C
	ld a, [hl+]
	ld d, a
	cp $DD
	jp z, B14_PcmEnd
	xor a

B14_PcmBit:
	rr d
	rra
	rra
	rra
	ldh [c], a
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	push hl
	pop hl
	nop
	nop
	dec b
	jp nz, B14_PcmBit
	jp B14_PcmByte

B14_PcmEnd:
	ei
	ld c, $1C
	ld a, $00
	ldh [c], a
	ld [wWaveId], a
	ret
B14_PcmWave:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
PcmSample9A:
	db $7E, $00, $00, $FE, $FF, $FF, $3F, $00, $00, $FB, $FF, $FF, $3F, $00, $40, $FC
	db $FF, $FF, $1F, $00, $10, $CE, $FF, $77, $00, $20, $E2, $FF, $FF, $01, $00, $80
	db $FF, $FF, $01, $00, $80, $FF, $FF, $00, $00, $80, $FF, $7F, $EC, $00, $18, $FE
	db $3F, $F8, $01, $10, $FC, $3F, $FE, $C0, $03, $7E, $3E, $7E, $E1, $03, $3F, $8E
	db $9F, $F0, $80, $1F, $8F, $CF, $78, $C0, $87, $E3, $23, $3E, $F0, $E3, $F9, $18
	db $0F, $F8, $70, $7C, $C4, $03, $3F, $8E, $87, $78, $F0, $C7, $F1, $10, $0F, $7F
	db $1C, $0F, $F9, $E0, $E7, $F8, $30, $0F, $7F, $86, $87, $7B, $F8, $39, $3E, $F0
	db $C1, $E7, $F0, $50, $0F, $9F, $C3, $C3, $3D, $3C, $0E, $0F, $77, $F8, $38, $1E
	db $8E, $E1, $71, $3C, $1C, $C3, $63, $78, $38, $86, $C7, $F0, $78, $8E, $C7, $F1
	db $70, $1C, $8F, $E3, $E1, $18, $1E, $C3, $E3, $31, $1E, $C7, $C3, $71, $3C, $86
	db $87, $23, $3C, $0E, $87, $E3, $78, $8C, $07, $07, $78, $1C, $0F, $C7, $F1, $84
	db $0F, $0F, $7C, $1C, $0F, $87, $FB, $C7, $87, $0F, $3C, $0E, $0F, $C3, $FD, $E3
	db $C3, $07, $1E, $C7, $C3, $43, $3F, $F0, $E0, $81, $0F, $F0, $F0, $C0, $0F, $7C
	db $F8, $E0, $03, $1E, $7C, $F0, $81, $0F, $1E, $FC, $E0, $83, $0F, $3E, $F8, $E0
	db $87, $1F, $3E, $F0, $E1, $87, $0F, $7C, $F0, $C1, $03, $1F, $7C, $F0, $C0, $0F
	db $1F, $7C, $F0, $83, $0F, $1F, $FC, $E1, $C3, $07, $3F, $F8, $E0, $C1, $0F, $3E
	db $78, $F0, $81, $0F, $1E, $F8, $E0, $83, $0F, $3E, $F8, $E0, $83, $0F, $3E, $F8
	db $E0, $83, $1F, $7C, $F0, $E1, $07, $1F, $7C, $F0, $C1, $07, $1E, $FC, $E0, $83
	db $0F, $3E, $F8, $E0, $83, $0F, $3E, $F0, $E1, $07, $1F, $7C, $F0, $C1, $0F, $3E
	db $F8, $E0, $03, $1F, $3E, $F8, $C1, $07, $1F, $7C, $E0, $C3, $07, $3E, $F0, $E1
	db $83, $1F, $FC, $F8, $C0, $07, $3E, $7C, $F0, $03, $1F, $1F, $F8, $C0, $CF, $0F
	db $7E, $E0, $F7, $03, $1F, $F8, $FD, $C0, $0F, $FC, $7E, $F0, $03, $BF, $1F, $FC
	db $C0, $C7, $07, $3F, $F8, $F1, $C1, $07, $3E, $7C, $F0, $81, $0F, $1F, $7C, $F0
	db $E1, $83, $0F, $3C, $F8, $E0, $83, $07, $1F, $7C, $F0, $E1, $07, $1F, $3C, $FC
	db $E0, $83, $87, $1F, $7C, $F0, $E0, $83, $0F, $1E, $FC, $F0, $C1, $83, $1F, $3C
	db $78, $E0, $83, $07, $0F, $7C, $F0, $E1, $21, $1F, $3E, $3C, $C0, $83, $87, $87
	db $78, $F0, $F0, $10, $1F, $1E, $1C, $C2, $C3, $87, $07, $78, $F0, $F0, $0C, $0F
	db $1E, $9E, $E3, $C3, $C3, $33, $7C, $78, $F0, $87, $0F, $1F, $FE, $F0, $E1, $C3
	db $1F, $3E, $7C, $F0, $C1, $87, $0F, $3E, $F8, $F0, $C1, $07, $0F, $1E, $F8, $F0
	db $E1, $03, $1F, $3E, $7C, $E0, $C3, $87, $0F, $3E, $78, $F0, $C0, $87, $0F, $1F
	db $F8, $F0, $E1, $03, $1F, $3E, $7C, $F0, $C1, $87, $0F, $3E, $F8, $F0, $C1, $07
	db $1F, $3E, $F8, $E0, $C3, $03, $1F, $3C, $78, $F0, $83, $0F, $0F, $7C, $F0, $E1
	db $83, $0F, $3E, $7C, $F0, $C3, $87, $0F, $7F, $F8, $F0, $E1, $0F, $1F, $3E, $FC
	db $C3, $83, $07, $77, $F8, $F0, $E0, $1E, $1F, $3E, $9C, $C3, $83, $87, $E3, $F8
	db $F0, $60, $3C, $1E, $3C, $1C, $CF, $07, $0F, $87, $E7, $C3, $C3, $C3, $F0, $3C
	db $88, $03, $80, $FF, $F3, $00, $E0, $F1, $FF, $00, $38, $C0, $FF, $03, $07, $E0
	db $FF, $41, $00, $00, $FC, $3C, $10, $00, $FE, $1F, $0E, $00, $E0, $FF, $1F, $00
	db $C0, $FF, $FF, $01, $00, $F0, $FF, $07, $00, $00, $FE, $FF, $07, $00, $80, $FF
	db $FF, $00, $00, $F0, $FF, $7F, $00, $00, $F8, $FF, $7F, $00, $00, $E0, $FF, $FF
	db $01, $00, $80, $FF, $FF, $0F, $00, $00, $F0, $FF, $FF, $01, $00, $00, $FE, $FF
	db $3F, $00, $00, $C0, $FF, $FF, $1F, $00, $00, $E0, $FF, $FF, $1F, $00, $00, $00
	db $FF, $FF, $FF, $00, $00, $00, $F8, $FF, $FF, $0F, $00, $00, $80, $FF, $FF, $7F
	db $00, $00, $00, $F0, $FF, $FF, $01, $00, $00, $00, $FF, $FF, $7F, $00, $00, $00
	db $C0, $FF, $FF, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $F8, $FF, $03, $80, $E3, $1E, $00, $00, $00, $FF, $FF, $01, $00
	db $FF, $C3, $03, $80, $E0, $3F, $7F, $30, $78, $FE, $C1, $C1, $83, $EF, $03, $87
	db $0F, $FE, $07, $06, $0F, $FE, $00, $C0, $87, $3F, $F0, $78, $F0, $07, $1E, $0E
	db $FE, $81, $0F, $C0, $3F, $F0, $01, $FC, $0E, $3E, $C0, $CF, $C1, $07, $FC, $38
	db $7C, $F0, $8F, $C3, $07, $FF, $3D, $7C, $F0, $8F, $C3, $07, $FF, $3C, $7C, $F0
	db $C7, $C3, $83, $7B, $1C, $3C, $F8, $E3, $C1, $C3, $07, $1F, $1E, $3C, $F8, $E0
	db $E1, $E1, $0F, $1E, $0E, $FF, $E1, $E1, $83, $0F, $0F, $0F, $FF, $F0, $70, $78
	db $0F, $0F, $8F, $7F, $78, $70, $F8, $87, $87, $C3, $7E, $3C, $38, $EE, $C3, $C3
	db $79, $3E, $3C, $1C, $FE, $C3, $C1, $E1, $3F, $1C, $1E, $FE, $E1, $E1, $E0, $1F
	db $0E, $0E, $FC, $F0, $F0, $E0, $0F, $0F, $0F, $FF, $F0, $70, $F8, $8F, $87, $C7
	db $F7, $78, $78, $F0, $87, $C7, $E1, $F1, $F0, $70, $F8, $87, $C3, $E1, $E1, $F0
	db $F0, $F8, $87, $87, $C3, $E3, $F0, $70, $78, $87, $87, $C3, $7F, $78, $38, $3C
	db $8F, $87, $C3, $7F, $78, $18, $FE, $C7, $C3, $F1, $7F, $38, $1C, $9E, $87, $C3
	db $F1, $3C, $1C, $1E, $CF, $87, $87, $E7, $39, $3C, $1E, $8E, $0F, $87, $C1, $7B
	db $78, $1C, $8F, $0F, $87, $C1, $F3, $F0, $38, $1C, $1E, $1E, $00, $E3, $E1, $C1
	db $20, $FC, $66, $00, $C4, $0F, $06, $00, $F8, $BF, $08, $80, $BF, $F1, $01, $F8
	db $3B, $1C, $00, $FF, $E3, $01, $E0, $FF, $7C, $00, $FC, $9F, $03, $00, $FF, $F3
	db $00, $F0, $6F, $1E, $00, $FC, $DF, $01, $80, $BF, $39, $00, $F0, $7F, $0F, $00
	db $FC, $CF, $01, $80, $FF, $39, $00, $F0, $3F, $07, $00, $FE, $E7, $01, $C0, $FF
	db $3D, $00, $F0, $BF, $07, $00, $FE, $7F, $00, $80, $FF, $3F, $00, $F8, $FF, $07
	db $00, $F8, $FF, $01, $00, $FE, $7F, $00, $00, $FF, $3F, $00, $80, $FF, $1F, $00
	db $80, $FF, $3F, $00, $00, $FF, $3F, $00, $00, $FE, $FF, $00, $00, $F8, $FF, $03
	db $00, $C0, $FF, $3F, $00, $00, $F8, $FF, $01, $00, $08, $FF, $0F, $00, $20, $F3
	db $7F, $00, $00, $BE, $3B, $03, $88, $FF, $CE, $08, $20, $FE, $3B, $03, $80, $FD
	db $77, $00, $80, $FF, $67, $00, $30, $FF, $67, $00, $F8, $FF, $67, $00, $F8, $FF
	db $33, $00, $7C, $FF, $33, $00, $3F, $FE, $19, $80, $1F, $FE, $09, $C0, $0F, $FE
	db $09, $E0, $07, $FE, $09, $F8, $07, $FF, $01, $FC, $07, $FF, $01, $FC, $03, $FF
	db $03, $FC, $03, $FF, $03, $FC, $00, $E7, $03, $FC, $00, $E7, $03, $F8, $00, $CF
	db $07, $FF, $00, $CE, $07, $FF, $01, $9E, $0F, $FE, $01, $3C, $1F, $FC, $83, $7F
	db $3C, $78, $0F, $EF, $F8, $F0, $1C, $1C, $F3, $C1, $79, $78, $C0, $07, $E7, $E1
	db $11, $1F, $9C, $87, $07, $7C, $70, $1E, $1E, $F0, $83, $7F, $F0, $C1, $0F, $FE
	db $C1, $07, $7E, $F0, $0F, $1E, $F0, $07, $3F, $E0, $C1, $3F, $FC, $01, $0F, $FE
	db $C1, $07, $78, $E0, $3F, $7C, $80, $0F, $FE, $C1, $07, $78, $E0, $3F, $F8, $00
	db $0F, $FE, $0F, $1F, $E6, $C1, $8F, $C3, $C7, $71, $F0, $F8, $C1, $61, $38, $3C
	db $FE, $F0, $30, $1E, $BE, $7B, $78, $18, $0F, $FF, $78, $78, $1C, $0F, $4F, $7C
	db $78, $18, $0F, $DF, $78, $78, $18, $0E, $CF, $F1, $F0, $30, $1E, $DE, $E1, $E1
	db $61, $3C, $F8, $C3, $C3, $C7, $F0, $F0, $87, $0F, $0F, $E3, $C1, $0F, $3E, $7C
	db $00, $0F, $FE, $F0, $E1, $03, $7C, $F0, $C3, $0F, $1F, $C0, $03, $1F, $7C, $F0
	db $01, $3E, $F0, $C1, $0F, $3E, $C0, $03, $3F, $FC, $C0, $03, $78, $F0, $87, $3F
	db $F8, $00, $1E, $FC, $E1, $1F, $3C, $80, $07, $7E, $F0, $0F, $1E, $C0, $83, $3F
	db $F8, $0F, $0F, $E3, $C3, $39, $FC, $0F, $1E, $C2, $83, $73, $F8, $1F, $3C, $88
	db $07, $E7, $E0, $E1, $E1, $E1, $78, $38, $0E, $9F, $3F, $78, $1C, $0F, $E7, $C1
	db $E3, $0F, $1E, $C6, $83, $71, $F0, $F0, $0F, $0F, $C3, $C3, $71, $F0, $E1, $1F
	db $3E, $82, $07, $E3, $E1, $03, $7F, $F0, $01, $3C, $C0, $07, $3F, $F8, $0F, $1F
	db $C0, $83, $FF, $E0, $03, $FF, $C3, $83, $F0, $F0, $3C, $7C, $E0, $E7, $E1, $E1
	db $78, $38, $1E, $7C, $E0, $F3, $C1, $C3, $F0, $70, $3C, $FC, $C1, $EF, $07, $0F
	db $C3, $C3, $F1, $E0, $0E, $3E, $7F, $F0, $30, $3C, $1C, $0F, $C6, $C3, $E3, $3F
	db $78, $0C, $1E, $86, $87, $C7, $E1, $E1, $7F, $F0, $00, $3C, $08, $0F, $86, $C3
	db $C7, $FF, $0F, $0F, $83, $83, $E1, $E1, $38, $78, $CE, $FF, $07, $1F, $80, $C7
	db $DD
PcmSample9B:
	db $00, $F0, $BB, $5C, $40, $06, $20, $50, $BF, $0B, $00, $92, $00, $53, $20, $40
	db $81, $00, $FD, $FF, $03, $00, $F0, $FF, $01, $00, $F8, $FF, $00, $00, $F8, $7F
	db $00, $00, $E0, $3F, $00, $37, $E0, $FF, $00, $0F, $80, $FF, $03, $3E, $80, $FF
	db $CF, $34, $00, $FF, $3E, $51, $00, $FC, $F8, $66, $01, $F8, $F1, $CD, $03, $F0
	db $EB, $99, $17, $E0, $F7, $93, $17, $E0, $F7, $93, $1F, $E0, $FF, $89, $17, $E0
	db $FF, $C9, $1F, $70, $FF, $C4, $0F, $B0, $7F, $F2, $07, $CC, $9F, $F8, $01, $F6
	db $07, $7E, $C0, $FC, $89, $1F, $F0, $7F, $D1, $07, $CC, $0F, $FC, $00, $FF, $81
	db $1E, $C0, $BF, $E0, $01, $FC, $13, $3D, $C0, $7F, $C1, $03, $F8, $17, $38, $80
	db $7F, $81, $0F, $E8, $1F, $FC, $80, $FE, $C0, $0D, $F0, $0F, $7C, $00, $7F, $E0
	db $07, $F8, $03, $3F, $80, $3F, $D0, $09, $FC, $05, $4C, $E0, $2F, $60, $02, $7F
	db $01, $12, $F8, $0B, $90, $C4, $4F, $04, $20, $7F, $03, $00, $F9, $9B, $04, $C0
	db $4F, $00, $20, $7F, $83, $00, $F8, $0F, $00, $E0, $3F, $10, $00, $FF, $01, $00
	db $FC, $0F, $00, $E0, $3F, $00, $00, $FF, $03, $00, $FC, $1F, $00, $E0, $FF, $02
	db $00, $FF, $3F, $00, $F0, $FF, $03, $80, $FF, $3F, $00, $F8, $FF, $01, $80, $FF
	db $1F, $00, $FC, $FF, $00, $80, $FF, $0F, $00, $F8, $FF, $01, $00, $FF, $3F, $00
	db $E0, $FF, $0F, $00, $F8, $FF, $03, $00, $FA, $FF, $03, $00, $F0, $FF, $17, $00
	db $00, $F3, $DF, $07, $80, $F0, $BF, $0C, $20, $F7, $2F, $00, $C0, $FF, $1F, $80
	db $1F, $7C, $C0, $83, $3F, $00, $00, $C0, $9D, $5C, $FC, $00, $06, $40, $FF, $FF
	db $03, $0A, $FF, $A1, $FD, $FF, $01, $00, $40, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30, $49, $9A, $74, $97, $B4
	db $A5, $CD, $83, $20, $94, $94, $FA, $68, $B9, $A6, $A1, $25, $2D, $57, $5B, $29
	db $DB, $96, $94, $70, $E9, $D7, $5A, $5B, $81, $CB, $9A, $92, $72, $B5, $B6, $42
	db $49, $11, $50, $4B, $2D, $25, $A9, $A4, $24, $A5, $B4, $95, $D4, $DA, $4A, $DA
	db $94, $96, $D6, $95, $52, $B7, $4A, $A5, $BA, $94, $AA, $AB, $35, $05, $6B, $54
	db $94, $DA, $52, $4D, $A9, $92, $A0, $49, $4A, $A5, $AD, $B5, $48, $D5, $48, $4A
	db $54, $A9, $92, $94, $29, $28, $4D, $54, $B5, $A4, $0A, $00, $80, $FA, $FF, $07
	db $00, $E0, $FF, $FF, $00, $00, $FE, $FF, $1F, $00, $00, $FF, $FF, $7F, $00, $00
	db $FF, $FF, $7F, $00, $00, $FF, $FF, $FF, $03, $00, $E8, $FF, $FF, $0F, $00, $E0
	db $FF, $FF, $FF, $00, $00, $F6, $FF, $FF, $27, $00, $E0, $FF, $FF, $FF, $00, $00
	db $FE, $FF, $FF, $0F, $00, $60, $FF, $FF, $FF, $01, $00, $FC, $FF, $FF, $7F, $00
	db $00, $FF, $FF, $FF, $1F, $00, $C0, $FF, $FF, $FF, $07, $00, $F0, $FF, $FF, $FF
	db $03, $00, $F8, $FF, $FF, $FF, $01, $00, $FC, $FF, $FF, $FF, $00, $00, $FE, $FF
	db $FF, $37, $00, $00, $FF, $FF, $FF, $3F, $00, $80, $FF, $FF, $FF, $1F, $00, $C0
	db $FF, $FF, $FF, $0F, $00, $E0, $FF, $FF, $FF, $03, $00, $C0, $FF, $FF, $FF, $03
	db $00, $00, $FE, $FF, $FF, $3F, $00, $00, $80, $FF, $FF, $FF, $03, $00, $00, $E0
	db $FF, $FF, $FF, $03, $00, $00, $F0, $FF, $FF, $BF, $01, $00, $00, $00, $D8, $FF
	db $0D, $00, $00, $00, $C0, $FE, $03, $00, $00, $00, $00, $70, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $FE, $FF, $4F, $00, $00
	db $F6, $FF, $FF, $7F, $03, $00, $00, $00, $00, $00, $00, $00, $52, $58, $AD, $6A
	db $41, $29, $95, $55, $8B, $2A, $BD, $22, $00, $B6, $CA, $6A, $68, $15, $A5, $42
	db $CD, $AC, $56, $B4, $52, $B5, $AA, $AA, $A8, $AE, $12, $51, $56, $58, $1D, $AD
	db $12, $E2, $1A, $19, $55, $AA, $8A, $48, $6C, $26, $22, $44, $94, $19, $25, $94
	db $4A, $A8, $89, $44, $53, $E2, $9C, $58, $33, $27, $95, $91, $8A, $59, $89, $8C
	db $9C, $11, $A5, $91, $48, $BA, $DB, $D9, $9D, $98, $8C, $CC, $EC, $28, $34, $12
	db $23, $93, $D4, $FF, $6E, $00, $00, $88, $FD, $FF, $07, $00, $80, $FF, $FF, $0F
	db $00, $00, $FC, $FF, $1F, $00, $00, $FC, $FF, $0F, $00, $00, $FF, $FF, $01, $00
	db $C0, $FF, $3F, $00, $00, $F0, $FF, $03, $00, $00, $FF, $FF, $00, $00, $00, $FC
	db $FF, $00, $00, $00, $FE, $FF, $01, $42, $00, $F8, $FF, $47, $08, $01, $00, $FE
	db $1F, $61, $0C, $80, $F1, $7F, $8C, $21, $10, $C2, $FF, $23, $8C, $80, $10, $FF
	db $8F, $31, $04, $42, $FC, $3F, $C6, $11, $08, $E1, $FF, $11, $C6, $60, $8C, $FF
	db $47, $18, $82, $21, $FE, $1F, $63, $18, $86, $F8, $7F, $08, $E1, $10, $C2, $FF
	db $23, $8C, $C3, $18, $FF, $8F, $30, $0C, $63, $FC, $3F, $40, $00, $00, $F1, $7F
	db $00, $00, $00, $E4, $FF, $01, $40, $00, $F0, $FF, $03, $84, $01, $C0, $FF, $07
	db $00, $03, $80, $FF, $0F, $00, $0C, $00, $FF, $1F, $00, $38, $00, $FE, $3F, $00
	db $70, $00, $FC, $3F, $00, $F0, $03, $FC, $7F, $00, $F0, $07, $F8, $7F, $02, $E0
	db $0F, $F0, $7F, $03, $E0, $1F, $F0, $3F, $03, $80, $0D, $F0, $BF, $03, $00, $09
	db $F8, $FF, $07, $00, $08, $F0, $FF, $0F, $40, $00, $C6, $FF, $1F, $80, $00, $80
	db $FF, $7F, $00, $00, $80, $FF, $FF, $00, $00, $40, $FE, $7F, $00, $18, $03, $F9
	db $07, $20, $1C, $83, $FF, $07, $70, $1C, $C3, $FF, $01, $38, $8E, $E1, $FF, $00
	db $1E, $C2, $F1, $7F, $00, $07, $E1, $F8, $3F, $80, $87, $71, $F8, $1F, $C8, $C3
	db $38, $FC, $0F, $E4, $61, $1C, $FE, $07, $FB, $30, $0E, $FE, $83, $3F, $70, $07
	db $FF, $C0, $1F, $FC, $C3, $7F, $F0, $07, $FE, $E0, $1F, $F8, $03, $3F, $F8, $0F
	db $FE, $C0, $1F, $FC, $03, $3F, $F0, $07, $FF, $C0, $07, $F8, $C1, $3F, $F8, $01
	db $7E, $F0, $07, $7E, $C0, $1F, $FE, $81, $0F, $F0, $87, $3F, $F0, $03, $FE, $E1
	db $07, $7E, $C0, $3F, $FC, $80, $0F, $F0, $C7, $1F, $F0, $01, $FE, $F8, $03, $3F
	db $C0, $1F, $7F, $E0, $03, $F8, $F1, $07, $3E, $00, $1F, $7F, $C0, $03, $F0, $F3
	db $07, $1E, $00, $FF, $3F, $A0, $00, $F0, $FF, $81, $05, $80, $FF, $0F, $1C, $00
	db $FE, $3F, $F0, $00, $F8, $FF, $81, $03, $E0, $FF, $07, $0F, $C0, $EF, $1F, $3C
	db $00, $FF, $3F, $F0, $00, $FC, $7F, $E0, $01, $F8, $FF, $C0, $03, $E0, $FF, $81
	db $07, $E0, $FF, $03, $0F, $C0, $FF, $03, $0F, $C0, $FF, $03, $1F, $C0, $FF, $03
	db $1F, $80, $FF, $03, $1E, $80, $FF, $03, $1E, $80, $FF, $01, $1C, $80, $FF, $01
	db $00, $80, $FF, $01, $00, $80, $FF, $01, $00, $C0, $FF, $01, $00, $C0, $FF, $0F
	db $00, $C0, $FF, $7F, $00, $C0, $FF, $FF, $03, $00, $F8, $FF, $0F, $00, $FC, $37
	db $0F, $00, $1C, $E7, $13, $13, $D0, $DE, $38, $06, $C0, $01, $98, $6E, $80, $CC
	db $C8, $0C, $18, $64, $0A, $E0, $98, $47, $81, $07, $C1, $E2, $41, $9C, $18, $7C
	db $50, $C0, $0B, $E4, $40, $83, $08, $07, $00, $04, $04, $B8, $08, $3F, $E2, $F1
	db $E8, $85, $FF, $0F, $60, $F8, $7F, $60, $96, $81, $7A, $30, $04, $C0, $1D, $AC
	db $DD
PcmSample9C:
	db $00, $00, $60, $FF, $3F, $63, $90, $FE, $FF, $FF, $84, $99, $13, $00, $00, $00
	db $00, $00, $00, $C1, $18, $FF, $FF, $BF, $8F, $39, $FE, $FF, $9F, $00, $00, $FF
	db $FF, $01, $00, $F8, $FF, $01, $00, $F0, $FF, $03, $00, $C0, $FF, $07, $00, $00
	db $FF, $0F, $00, $00, $FF, $1F, $00, $00, $FF, $1F, $00, $22, $FF, $1F, $00, $60
	db $FF, $4F, $00, $30, $FF, $2F, $00, $B1, $FF, $27, $80, $D8, $FF, $13, $40, $EC
	db $FF, $19, $20, $F2, $FF, $06, $10, $F9, $3F, $01, $C0, $FC, $9F, $00, $22, $FF
	db $6F, $00, $91, $FF, $37, $00, $C4, $FF, $09, $00, $C2, $FF, $04, $00, $E0, $7F
	db $03, $00, $E0, $FF, $07, $00, $00, $FF, $3F, $00, $00, $FE, $FF, $03, $00, $E0
	db $FF, $7F, $00, $00, $FC, $FF, $0F, $00, $80, $FF, $FF, $07, $00, $C0, $FF, $FF
	db $03, $00, $E0, $FF, $FF, $01, $00, $FC, $FF, $7F, $00, $80, $FF, $FF, $3F, $01
	db $F0, $FF, $7F, $00, $90, $EC, $3F, $07, $00, $10, $B0, $77, $16, $00, $90, $01
	db $04, $00, $00, $10, $08, $02, $0A, $04, $01, $A2, $81, $00, $C1, $04, $0B, $03
	db $48, $60, $89, $00, $13, $30, $EC, $2E, $35, $3F, $20, $94, $47, $C5, $36, $B7
	db $2C, $96, $8C, $60, $A5, $55, $A9, $2B, $55, $59, $4A, $75, $52, $49, $D8, $FF
	db $03, $00, $C0, $FF, $0F, $00, $00, $FC, $FF, $03, $00, $80, $FD, $7F, $00, $00
	db $E0, $FF, $0F, $00, $00, $F0, $FF, $01, $70, $01, $F8, $FF, $00, $F8, $01, $FC
	db $7F, $00, $FE, $00, $FC, $7F, $00, $FE, $00, $FC, $7F, $00, $FC, $00, $FC, $FF
	db $00, $F8, $01, $F8, $FF, $01, $E0, $07, $F0, $FF, $0F, $80, $1F, $C0, $FF, $3F
	db $00, $4C, $00, $FE, $FF, $07, $00, $00, $90, $D0, $FF, $FF, $07, $00, $00, $FC
	db $FF, $FF, $07, $00, $00, $F0, $FF, $FF, $3F, $00, $00, $00, $F0, $FF, $FF, $FF
	db $0B, $00, $00, $E0, $FF, $FF, $FF, $FF, $03, $00, $00, $F0, $FF, $FF, $7F, $00
	db $00, $00, $00, $E0, $7F, $DF, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $B0, $46, $A1, $DC, $65, $C3, $DA, $57, $09, $C4, $F0, $86
	db $04, $11, $A1, $35, $9B, $AB, $94, $64, $64, $A2, $95, $B6, $29, $9D, $AD, $B4
	db $26, $2A, $B9, $B5, $FB, $5D, $00, $00, $00, $FB, $FF, $7F, $00, $00, $00, $F8
	db $FF, $FF, $00, $00, $00, $F8, $FF, $FF, $01, $00, $00, $F8, $FF, $FF, $03, $F0
	db $00, $F8, $FF, $FF, $0F, $D8, $01, $F0, $FF, $FF, $7F, $E0, $07, $E0, $1F, $FF
	db $FF, $83, $3F, $80, $1F, $F0, $FF, $0F, $7E, $00, $F6, $00, $FF, $7F, $F0, $01
	db $3C, $0F, $FE, $FF, $07, $1F, $C0, $03, $F0, $FF, $FF, $E0, $03, $78, $70, $38
	db $FF, $3F, $78, $18, $1E, $1C, $CC, $FF, $07, $0F, $82, $87, $87, $F9, $F9, $C1
	db $C3, $E0, $E0, $E1, $FE, $7E, $F0, $61, $78, $78, $F8, $FF, $7F, $F8, $30, $38
	db $38, $3C, $FF, $3F, $F8, $30, $3C, $3C, $3C, $FF, $7F, $F8, $30, $38, $78, $3C
	db $FE, $7F, $F0, $21, $78, $F0, $78, $FC, $FF, $C1, $83, $E0, $E1, $E1, $F1, $FF
	db $07, $1F, $82, $07, $87, $C3, $FF, $3F, $78, $00, $3C, $3C, $1E, $FF, $FF, $C1
	db $03, $E0, $E1, $E1, $F8, $FF, $1F, $3E, $10, $1E, $1E, $8E, $FF, $FF, $E1, $03
	db $E1, $E1, $E1, $F8, $FD, $1F, $3C, $00, $1E, $1C, $BC, $FF, $FF, $83, $07, $C0
	db $83, $87, $FF, $FF, $FF, $E0, $03, $F0, $E0, $81, $3F, $FE, $7F, $F0, $01, $F0
	db $F0, $81, $1F, $FE, $FF, $E0, $03, $F0, $E0, $81, $7F, $FC, $FF, $83, $0F, $C0
	db $83, $07, $FF, $E1, $FF, $3F, $78, $00, $3C, $78, $38, $1E, $FE, $FF, $87, $0F
	db $80, $87, $C7, $E3, $F1, $F9, $FF, $C1, $03, $E0, $81, $FB, $F0, $F9, $FE, $FF
	db $E0, $03, $F0, $C0, $3F, $F0, $EF, $FF, $FF, $C1, $43, $F0, $00, $3C, $18, $1E
	db $FE, $FF, $07, $0F, $C1, $C3, $F0, $70, $78, $F8, $FF, $FF, $E0, $21, $78, $08
	db $0F, $CB, $C1, $FF, $FF, $7F, $F0, $00, $1C, $C0, $A3, $F9, $F0, $BF, $FF, $FF
	db $E0, $08, $B0, $07, $FE, $E0, $19, $FE, $F7, $FF, $0F, $F6, $00, $3D, $E0, $0F
	db $FC, $81, $FF, $FC, $FF, $81, $3D, $80, $0F, $F0, $03, $7E, $C0, $7F, $FE, $FF
	db $81, $0C, $C0, $1F, $F0, $07, $F8, $80, $7F, $F8, $FF, $07, $70, $00, $FC, $00
	db $FF, $E0, $0F, $F0, $FF, $FF, $7F, $80, $03, $80, $07, $F0, $0F, $E8, $0D, $FE
	db $FF, $FF, $07, $98, $01, $F8, $07, $F8, $11, $E2, $3D, $FF, $FF, $7F, $00, $39
	db $00, $FF, $00, $FF, $00, $EE, $F9, $FF, $FF, $1F, $00, $06, $C0, $7F, $00, $8F
	db $DD
PcmSample9D:
	db $1E, $00, $00, $F0, $FF, $FF, $7F, $00, $00, $F0, $FF, $FF, $3F, $00, $00, $F0
	db $FE, $FF, $07, $00, $00, $3C, $FE, $3F, $30, $00, $E0, $C3, $FF, $E0, $07, $C0
	db $8F, $FF, $E0, $0F, $E0, $07, $FF, $C0, $1F, $E0, $03, $7F, $80, $0F, $E0, $E3
	db $0F, $E6, $03, $FC, $FC, $C0, $7E, $80, $CF, $0F, $C4, $07, $F8, $FC, $00, $7C
	db $00, $C7, $0F, $C2, $07, $20, $7E, $10, $3E, $60, $E0, $83, $A1, $41, $02, $3F
	db $1C, $1C, $16, $F0, $C1, $C1, $E0, $81, $1F, $9C, $0F, $5E, $F8, $C1, $F9, $C0
	db $07, $3F, $D8, $0F, $7C, $F0, $03, $FF, $81, $0F, $7E, $E0, $1F, $F0, $C1, $0F
	db $FC, $06, $3E, $F8, $83, $BF, $C0, $0F, $FE, $E0, $27, $F0, $81, $3F, $F8, $03
	db $7C, $E0, $1F, $FC, $00, $3F, $F8, $0F, $7E, $80, $1F, $7C, $1E, $3C, $00, $1F
	db $7C, $7E, $F0, $10, $3E, $F0, $FF, $07, $0F, $E0, $03, $3F, $FC, $E0, $01, $7C
	db $E0, $81, $7F, $F0, $00, $3E, $E0, $07, $FF, $E0, $01, $F8, $C0, $1F, $FC, $07
	db $2F, $E0, $07, $3F, $F0, $FF, $E0, $01, $F8, $E0, $EF, $E3, $FF, $C0, $03, $7C
	db $C0, $7F, $F8, $7F, $70, $00, $70, $F0, $5F, $FF, $7B, $5E, $07, $00, $00, $FB
	db $FC, $7C, $6E, $72, $30, $0A, $00, $60, $FD, $F9, $3C, $FC, $CC, $F8, $28, $0E
	db $87, $10, $0C, $CF, $EF, $FF, $E7, $38, $0C, $46, $02, $03, $01, $1C, $0E, $E7
	db $BB, $9F, $C7, $20, $20, $05, $E3, $18, $08, $0C, $8E, $8F, $C7, $E0, $68, $7C
	db $3C, $38, $18, $8E, $C3, $39, $DE, $6F, $96, $83, $E1, $E1, $11, $C0, $30, $3C
	db $5F, $CF, $87, $E3, $7B, $70, $10, $8E, $C3, $B9, $90, $78, $3C, $DE, $2D, $1C
	db $CE, $43, $38, $1C, $86, $E7, $F7, $30, $70, $78, $38, $18, $02, $86, $E3, $1F
	db $0E, $4C, $EF, $72, $04, $00, $34, $9E, $67, $00, $86, $E7, $71, $03, $00, $78
	db $39, $1C, $08, $8E, $CF, $E7, $11, $00, $38, $0F, $CF, $03, $C0, $79, $3C, $3F
	db $00, $00, $03, $80, $1D, $00, $87, $E3, $71, $08, $00, $00, $00, $FC, $83, $21
	db $30, $1C, $8F, $00, $00, $C0, $78, $0E, $86, $E1, $F9, $3C, $07, $01, $00, $00
	db $87, $81, $30, $38, $B8, $1E, $01, $00, $1C, $C6, $61, $20, $8C, $C0, $78, $17
	db $00, $38, $02, $00, $00, $00, $FC, $FF, $FF, $FF, $7F, $00, $00, $00, $FE, $FF
	db $FF, $7F, $00, $00, $80, $F0, $FF, $FF, $0F, $00, $C0, $00, $FC, $FF, $7F, $00
	db $04, $6E, $C0, $FF, $FF, $C0, $08, $8C, $8E, $F8, $FF, $60, $4C, $00, $0E, $FC
	db $3F, $30, $13, $80, $03, $FF, $07, $0E, $02, $3F, $E0, $3F, $70, $07, $F8, $03
	db $FF, $81, $1F, $C0, $1F, $F8, $07, $FF, $80, $3F, $E0, $1F, $FC, $03, $FE, $80
	db $7F, $F0, $07, $F8, $01, $FF, $C0, $1F, $F0, $03, $FC, $83, $7F, $C0, $0F, $F0
	db $0F, $FC, $00, $3F, $E0, $3F, $F0, $03, $F8, $80, $FF, $03, $1F, $C0, $07, $FC
	db $7F, $F0, $00, $7C, $E0, $BF, $0F, $1E, $80, $0F, $FC, $F7, $C1, $03, $F0, $81
	db $FF, $3E, $78, $00, $3E, $F0, $DF, $0F, $0F, $C0, $07, $FC, $E1, $C3, $03, $F0
	db $01, $7F, $F8, $E0, $01, $FC, $C0, $1F, $FE, $F0, $04, $7C, $40, $1F, $FE, $E0
	db $09, $F8, $00, $3E, $F8, $07, $2F, $E0, $03, $7F, $E0, $7F, $78, $00, $3E, $F0
	db $07, $FE, $1F, $1E, $84, $0F, $FE, $80, $FF, $0F, $1E, $C0, $07, $FE, $80, $FF
	db $3F, $3C, $00, $1F, $FC, $83, $3F, $FE, $C1, $01, $F8, $C0, $1F, $F8, $F3, $3F
	db $3C, $00, $1F, $F8, $03, $FE, $DF, $0F, $0E, $C0, $0F, $FC, $07, $FF, $FF, $0F
	db $1E, $E0, $03, $3E, $87, $DF, $FF, $1F, $00, $80, $83, $CF, $FF, $F1, $1F, $F0
	db $81, $F7, $07, $00, $00, $E0, $F0, $FF, $FF, $FF, $E7, $63, $00, $00, $E0, $F8
	db $FE, $FF, $1F, $08, $80, $03, $F0, $18, $BC, $80, $0E, $C0, $09, $CF, $47, $03
	db $0E, $E0, $1E, $F8, $E0, $D7, $1F, $61, $00, $80, $C3, $E1, $07, $26, $3C, $CE
	db $67, $3C, $4E, $07, $04, $C6, $C1, $E0, $61, $3C, $1C, $07, $02, $C7, $67, $03
	db $30, $78, $98, $43, $73, $1F, $C3, $30, $40, $73, $3C, $0E, $0E, $83, $61, $70
	db $0E, $C6, $10, $06, $83, $30, $B8, $7F, $3C, $0C, $8E, $C3, $70, $3C, $06, $06
	db $CE, $E7, $11, $01, $18, $8F, $01, $F0, $7A, $3F, $C3, $71, $18, $9C, $CE, $06
	db $80, $67, $30, $30, $8E, $E7, $71, $00, $C0, $3C, $8E, $E3, $60, $30, $30, $18
	db $1F, $10, $0C, $C7, $83, $F0, $30, $00, $80, $19, $83, $C3, $71, $5C, $00, $E0
	db $71, $3C, $07, $01, $30, $07, $F7, $04, $00, $38, $00, $20, $0E, $C3, $E3, $61
	db $00, $0C, $C7, $31, $07, $00, $3C, $0F, $80, $C1, $61, $70, $08, $0C, $8F, $C3
	db $60, $30, $10, $1E, $8F, $C1, $52, $00, $00, $E3, $42, $0C, $04, $A0, $70, $00
	db $00, $04, $C2, $FF, $7F, $CC, $FF, $05, $00, $40, $78, $FE, $FF, $FF, $3F, $00
	db $04, $07, $C0, $F3, $FF, $FF, $00, $08, $1C, $80, $E3, $FF, $3F, $00, $32, $02
	db $20, $FF, $FF, $03, $20, $21, $10, $F8, $FF, $07, $03, $80, $3F, $E0, $FF, $C1
	db $39, $00, $1F, $F8, $7F, $F0, $06, $F8, $03, $FF, $07, $7F, $80, $3F, $E0, $7F
	db $E0, $0F, $F0, $03, $FC, $0F, $FE, $00, $1F, $E0, $FF, $C0, $0F, $F0, $01, $FC
	db $3F, $78, $00, $3E, $80, $3F, $0F, $0F, $C0, $0F, $E0, $E7, $87, $07, $E0, $03
	db $F0, $F3, $83, $03, $E0, $03, $F8, $F9, $C3, $81, $F0, $01, $FC, $F8, $C1, $03
	db $F0, $01, $FC, $F0, $83, $23, $E0, $03, $FC, $E0, $0F, $5E, $C0, $07, $F8, $83
	db $3F, $F8, $03, $3F, $E0, $0F, $FE, $83, $17, $F0, $01, $7F, $E0, $7F, $F0, $00
	db $3E, $F0, $03, $FC, $1F, $3C, $80, $0F, $FC, $03, $9F, $1F, $1E, $84, $0F, $FE
	db $83, $1F, $3F, $3C, $08, $0F, $FE, $03, $1F, $FE, $F0, $24, $7C, $60, $0F, $F8
	db $F0, $07, $2F, $E0, $07, $FE, $80, $0F, $FF, $E1, $01, $F8, $C0, $7F, $E0, $C3
	db $FF, $F0, $00, $7C, $E0, $1F, $F8, $E0, $FF, $E0, $01, $FC, $E0, $3F, $F0, $E0
	db $FF, $0F, $1E, $C0, $0F, $FC, $03, $FF, $C7, $FF, $C1, $03, $F8, $81, $1F, $D8
	db $7F, $FE, $1F, $10, $00, $0C, $F8, $C7, $FF, $F7, $F9, $DC, $01, $00, $00, $00
	db $F8, $F9, $FF, $FF, $18, $38, $00, $05, $00, $00, $02, $F0, $F9, $FF, $FF, $7F
	db $10, $04, $30, $00, $06, $80, $2F, $F8, $9F, $FF, $C1, $87, $FF, $04, $04, $80
	db $81, $39, $1C, $80, $81, $81, $21, $78, $3F, $FF, $38, $18, $03, $F7, $0C, $05
	db $80, $C6, $7F, $7C, $24, $44, $8E, $E7, $61, $38, $8E, $C7, $3F, $00, $0C, $C2
	db $C3, $84, $10, $04, $E0, $7F, $F8, $40, $0C, $8E, $C3, $E3, $30, $30, $10, $3B
	db $1F, $83, $81, $81, $EF, $78, $0C, $00, $70, $1C, $8C, $07, $0F, $23, $61, $08
	db $80, $FF, $38, $88, $0F, $61, $1E, $00, $C1, $40, $30, $3E, $37, $82, $C1, $70
	db $3C, $9E, $07, $80, $C0, $E0, $FD, $3C, $0C, $86, $E3, $70, $1C, $0E, $01, $C0
	db $61, $38, $1E, $01, $10, $18, $0E, $83, $81, $81, $E0, $38, $0E, $02, $40, $60
	db $10, $1C, $0F, $00, $00, $80, $F8, $19, $00, $00, $03, $E3, $F1, $38, $18, $0C
	db $03, $00, $00, $8E, $00, $00, $00, $43, $F0, $00, $00, $00, $00, $D0, $01, $00
	db $00, $00, $80, $C7, $21, $00, $00, $06, $C1, $00, $10, $0E, $00, $00, $00, $FE
	db $FF, $FF, $FF, $0F, $00, $00, $BC, $07, $E7, $FF, $FF, $FF, $03, $00, $60, $00
	db $18, $F8, $FF, $FF, $1F, $00, $00, $02, $81, $E1, $F1, $FF, $0F, $18, $01, $90
	db $03, $F0, $FF, $FF, $03, $21, $80, $BB, $10, $BE, $FF, $1F, $08, $00, $FC, $01
	db $FF, $FD, $3F, $30, $00, $F8, $03, $FC, $FC, $3F, $70, $00, $F8, $01, $78, $F8
	db $3F, $F0, $00, $F8, $01, $38, $F8, $1F, $F8, $01, $FC, $80, $1F, $F8, $0F, $FC
	db $00, $7E, $E0, $07, $FE, $07, $3F, $80, $1F, $F8, $03, $FF, $C1, $0F, $E0, $07
	db $7E, $C0, $7F, $E0, $03, $F8, $80, $1F, $F0, $1F, $F8, $00, $7E, $E0, $07, $FC
	db $0F, $7C, $80, $1F, $F8, $03, $FE, $0F, $3E, $80, $1F, $F8, $01, $7E, $3E, $7C
	db $00, $3E, $F8, $07, $7E, $F8, $07, $07, $E0, $03, $DE, $81, $0F, $FC, $83, $07
	db $F0, $03, $FF, $C0, $07, $FF, $07, $0F, $E0, $03, $3F, $80, $07, $FE, $F9, $F0
	db $20, $7E, $E0, $03, $F8, $01, $F9, $7D, $70, $90, $3E, $F0, $01, $F8, $E0, $FD
	db $FC, $C1, $83, $F0, $80, $6F, $E0, $03, $7E, $F8, $1F, $7C, $C8, $1F, $F8, $01
	db $3E, $F0, $87, $3F, $07, $07, $B2, $07, $3F, $80, $0F, $7C, $E0, $9F, $83, $03
	db $D3, $83, $8F, $81, $07, $DE, $C3, $FF, $07, $07, $E0, $07, $FF, $83, $0F, $E0
	db $C3, $FF, $0F, $1C, $80, $0F, $FC, $07, $7F, $80, $8F, $FF, $7F, $F0, $00, $7C
	db $00, $3E, $F0, $1F, $FE, $CF, $CF, $1D, $08, $00, $00, $C0, $FF, $F8, $81, $7F
	db $FF, $63, $38, $00, $00, $00, $6E, $7F, $3F, $C7, $E7, $FF, $7F, $0C, $86, $C3
	db $60, $60, $1C, $CF, $F7, $FE, $FF, $DF, $0F, $06, $60, $40, $00, $00, $64, $E0
	db $E3, $7F, $7E, $FE, $E3, $00, $0E, $80, $40, $70, $00, $06, $00, $E0, $18, $0F
	db $83, $F9, $FF, $80, $6F, $70, $00, $07, $0E, $03, $80, $0F, $0F, $F0, $00, $0E
	db $46, $E0, $3F, $1C, $0E, $8F, $C3, $03, $18, $88, $C7, $60, $08, $8C, $C3, $7F
	db $3C, $00, $87, $63, $DC, $03, $30, $10, $1E, $8F, $03, $40, $00, $C7, $E3, $38
	db $1C, $80, $E3, $F3, $38, $3C, $00, $06, $83, $C3, $01, $38, $78, $00, $1E, $83
	db $03, $3B, $08, $0E, $80, $63, $F0, $C1, $31, $38, $00, $C0, $1F, $00, $EC, $00
	db $00, $1E, $7F, $00, $00, $60, $78, $78, $00, $00, $18, $E0, $03, $00, $0C, $83
	db $E1, $70, $30, $06, $C2, $70, $00, $0C, $06, $C0, $00, $10, $00, $00, $30, $10
	db $06, $02, $60, $00, $00, $86, $00, $E0, $61, $00, $00, $00, $00, $00, $00, $0E
	db $87, $C3, $F1, $60, $F8, $00, $00, $C8, $07, $E0, $FF, $FF, $FF, $7F, $00, $00
	db $20, $00, $FE, $01, $F8, $FF, $FF, $1F, $00, $0C, $00, $FE, $03, $F8, $FF, $FF
	db $7F, $00, $38, $00, $FC, $03, $E0, $FF, $FF, $7F, $00, $78, $00, $FC, $0F, $80
	db $FF, $FD, $3F, $00, $16, $00, $92, $0F, $C0, $7F, $FE, $0F, $00, $04, $06, $C4
	db $07, $E0, $0F, $FF, $07, $02, $02, $03, $83, $07, $F0, $83, $FF, $03, $03, $81
	db $87, $C1, $03, $F0, $C3, $FF, $03, $03, $81, $0F, $C9, $03, $CF, $83, $FF, $07
	db $0F, $00, $0F, $9A, $07, $9E, $03, $FF, $0F, $3C, $00, $3E, $38, $1F, $F8, $00
	db $FE, $FC, $C0, $01, $F0, $03, $7E, $C0, $1F, $F0, $E3, $7F, $E0, $01, $F8, $81
	db $FF, $E0, $07, $E0, $83, $FF, $0F, $3C, $80, $0F, $F8, $07, $FE, $80, $1F, $F0
	db $87, $7F, $F0, $03, $7C, $80, $1F, $F8, $03, $FC, $C0, $07, $FE, $1F, $1C, $C0
	db $0F, $FC, $03, $3E, $80, $1F, $F0, $81, $3F, $78, $30, $30, $3D, $D8, $1F, $F8
	db $00, $7F, $C0, $07, $FE, $C0, $0F, $36, $A2, $07, $F8, $03, $3F, $C0, $07, $FC
	db $E0, $1F, $F8, $81, $0D, $E8, $C1, $7E, $E0, $07, $FC, $00, $1F, $F8, $03, $7F
	db $70, $03, $7B, $F0, $1F, $F8, $01, $3F, $E0, $03, $FF, $E0, $1F, $5C, $C0, $0E
	db $FC, $03, $7E, $E0, $07, $F8, $C0, $1F, $FC, $83, $0B, $D8, $81, $FE, $C0, $0F
	db $FC, $80, $0F, $FC, $C1, $1F, $D8, $80, $1F, $F0, $07, $7C, $C0, $0F, $F8, $C0
	db $3F, $FC, $C1, $03, $FC, $80, $7F, $E0, $07, $FC, $C0, $CF, $FE, $C3, $3F, $38
	db $80, $1F, $F8, $01, $7E, $00, $0E, $FC, $E1, $1F, $0E, $FC, $80, $01, $78, $F8
	db $0F, $01, $3E, $F8, $E3, $9F, $9F, $00, $00, $00, $81, $41, $60, $00, $3E, $C4
	db $C3, $71, $FC, $07, $3F, $07, $02, $00, $0A, $06, $83, $03, $02, $01, $7C, $F8
	db $C3, $1F, $FE, $60, $00, $06, $00, $00, $00, $00, $00, $20, $00, $01, $30, $F8
	db $80, $1B, $1C, $80, $01, $DD
B14_BankEnd:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

SECTION "Sound bank 15", ROMX[$4000], BANK[15]

B15_TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, B15_TrackCount
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call B15_WriteDuty

B15_TrackCount:
	ld l, TRK_LEN
	dec [hl]
	jp nz, B15_Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

B15_ReadCmds:
	ld a, [de]
	cp $E0
	jp nc, B15_Command
	ld a, [wTrackDesc]
	cp $63
	jp z, B15_NoiseNote
	ld l, TRK_FLAGS
	res 2, [hl]
	call B15_SavePtr
	dec de
	ld a, [de]
	and $0F
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l404E
	ld b, a
	xor a
	bit 0, b
	jp nz, .l4056
	rrc b
.l4045:
	add a, c
	dec b
	jp nz, .l4045
	add a, a
	jp .l405B
.l404E:
	swap c
	ld a, c
	and $F0
	jp .l405B
.l4056:
	add a, c
	dec b
	jp nz, .l4056
.l405B:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [de]
	and $F0
	jp nz, .l406C
	set 0, [hl]
	ld a, $08
	jp B15_WriteVolume
.l406C:
	res 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	jp z, B15_DrumNote
	push de
	push hl
	ld l, TRK_GATE
	ld a, [hl]
	or a
	jp z, .l4090
	ld e, a
	ld b, $00
	ld hl, $0000
.l4085:
	add hl, bc
	dec e
	jp nz, .l4085
	ld a, l
	and $F0
	or h
	swap a
.l4090:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYTICKS
	ld a, [hl+]
	or a
	jp z, .l40A1
	ld [hl+], a
	ld a, [hl]
	call B15_WriteDuty
.l40A1:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, B15_AutoPan
	ld a, [de]
	and $F0
	swap a
	rlca
	ld l, TRK_OCTAVE
	ld c, [hl]
	add a, c
	ld l, TRK_TRANSP
	ld c, [hl]
	add a, c
	ld c, a
	ld b, $00
	push hl
	ld hl, B15_PeriodTable - 26
	add hl, bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld l, TRK_DETUNE
	ld a, [hl+]
	or a
	jp z, .l40D1
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l40D1:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l40F9
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
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
	call z, B15_VibratoStep
.l40F9:
	call B15_WritePeriod
	ld a, [wFadeLevel]
	ld c, a
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	sub c
	jp nc, B15_WriteVolume
	ld a, $08
	jp B15_WriteVolume

B15_Sustain:
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
	jp z, .l412E
	dec [hl]
	jp nz, .l412E
	ld l, TRK_DUTY
	ld a, [hl]
	call B15_WriteDuty
.l412E:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, B15_SustainRelease
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, B15_SustainRelease
	ld l, TRK_VIBDELAYCNT
	ld a, [hl]
	or a
	jp z, .l4147
	dec [hl]
	jp B15_SustainRelease
.l4147:
	ld l, TRK_VIBTIMER
	dec [hl]
	jp nz, B15_SustainRelease
	ld l, TRK_VIBCUR
	ld c, [hl]
	inc l
	ld b, [hl]
	call B15_VibratoStep
	call B15_WritePeriod

B15_SustainRelease:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, B15_Ch3Release
	cp [hl]
	jp z, B15_ReleasePoint
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp B15_WriteVolume

B15_ReleasePoint:
	inc l
	ld a, [hl]
	or a
	jp z, .l4194
	ld l, TRK_LEVEL
	or [hl]
	ld l, TRK_REG2
	ld c, [hl]
	call B15_WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret
.l4194:
	ld a, $08
	jp B15_WriteVolume

B15_Ch3Release:
	cp [hl]
	inc hl
	jp c, B15_Ch3Decay
	jp z, .l41B1
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	cp $80
	ret c
	res 2, [hl]
	ld l, TRK_LEVEL
	ld a, [hl]
	jp B15_WriteVolume
.l41B1:
	ld a, [hl+]
	ld [hl], a
	ret

B15_Ch3Decay:
	ld a, [hl+]
	or a
	jp z, B15_WriteVolume
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LEVEL
	ld a, [hl]
	add a, $20
	cp $A0
	ret nc
	jp B15_WriteVolume

B15_VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, B15_VibEnd
	cp $FE
	jp z, B15_VibMark
	cp $FB
	jp z, B15_VibLoop
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
	jp z, B15_VibBase
	ld l, TRK_VIBDEPTH
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l4200
	and $07
	jp z, B15_VibBase
	cpl
	inc a
	ld e, a
	ld d, $FF
.l4200:
	ld a, [hl]
	or a
	jp z, .l420D
	ld b, a
	xor a
.l4207:
	add a, e
	dec b
	jp nz, .l4207
	ld e, a
.l420D:
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

B15_VibBase:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

B15_VibEnd:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret

B15_VibLoop:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l423D
	set 4, [hl]
	ld l, TRK_VIBLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp B15_VibratoStep
.l423D:
	ld a, [bc]
	ld l, TRK_VIBLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l424C
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp B15_VibratoStep
.l424C:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp B15_VibratoStep

B15_VibMark:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l4268
	set 5, [hl]
	inc bc
	ld l, TRK_VIBSEGNO
	ld [hl], c
	inc l
	ld [hl], b
	jp B15_VibratoStep
.l4268:
	ld l, TRK_VIBSEGNO
	ld c, [hl]
	inc l
	ld b, [hl]
	jp B15_VibratoStep

B15_Rest:
	call B15_SavePtr
	ld a, $08
	jp B15_WriteVolume

B15_DrumNote:
	ld a, [de]
	and $F0
	swap a
	ld [wReqId], a
	ld hl, B15_SoundTable
	call B15_LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, B15_StartDrumTrack
	srl b
	ld hl, wTrkSfx2
	call c, B15_StartDrumTrack
	srl b
	ld hl, wTrkSfxN
	ret nc

B15_StartDrumTrack:
	ld a, [wReqPrio]
	cp [hl]
	jp c, B15_SkipDrumTrack
	ld [hl+], a
	ld a, [wReqId]
	or $C0
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
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [wWaveId], a
	ld l, TRK_REG2
	ld c, [hl]
	ldh [c], a
	ld a, $C0
	cp h
	jp nz, .l42DD
	ld a, $08
	ld l, TRK_SWEEP
	ld [hl], a
	ld c, $10
	ldh [c], a
.l42DD:
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

B15_SkipDrumTrack:
	inc de
	inc de
	ret

B15_NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [de]
	or a
	jp z, B15_Rest
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, B15_NoiseNoteHold
	call B15_SavePtr
	ld e, a
	ld d, $00
	jp B15_WritePeriod

B15_NoiseNoteHold:
	and $0F
	swap a
	push af
	inc de
	ld a, [de]
	call B15_SavePtr
	ld e, a
	ld d, $00
	call B15_WritePeriod
	pop af
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	ret z
	ld a, [hl]
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

B15_Command:
	inc de
	sub $E0
	jp z, B15_Cmd_Voice

B15_CommandRaw:
	cp $07
	jp c, B15_Cmd_Octave
	push hl
	ld hl, B15_CommandTable - 14
	call B15_LoadPtrIndexed
	ld a, [de]
	jp hl
B15_CommandTable:
	dw B15_Cmd_LenUnit
	dw B15_Cmd_Release
	dw B15_Cmd_Sweep
	dw B15_Cmd_Ext
	dw B15_Cmd_Vibrato
	dw B15_Cmd_EC
	dw B15_Cmd_ED
	dw B15_Cmd_Tempo
	dw B15_Cmd_Detune
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Atten
	dw B15_Cmd_Volume
	dw B15_Cmd_Volume
	dw B15_Cmd_Jump
	dw B15_Cmd_Loop
	dw B15_Cmd_Loop2
	dw B15_Cmd_Call
	dw B15_Cmd_Segno
	dw B15_Cmd_End

B15_Cmd_Voice:
	ld a, [de]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [de]
	ld l, TRK_FLAGS
	bit 7, a
	inc de
	jp nz, B15_VoiceFlag
	ld a, [wTrackDesc]
	cp $63
	jp nz, B15_VoiceTone
	res 3, [hl]
	ld a, [de]
	call B15_WriteNoiseVolume
	inc de
	jp B15_ReadCmds

B15_VoiceTone:
	res 1, [hl]
	ld a, [de]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
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
	call B15_PanBoth
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_VoiceFlag:
	ld a, [wTrackDesc]
	cp $63
	jp nz, B15_ReadCmds
	set 3, [hl]
	jp B15_ReadCmds

B15_Cmd_Octave:
	ld c, a
	ld b, $00
	push hl
	ld hl, B15_OctaveTable - 1
	add hl, bc
	ld a, [hl]
	pop hl
	ld l, TRK_OCTAVE
	ld [hl], a
	jp B15_ReadCmds
B15_OctaveTable:
	db $18, $30, $48, $60, $78, $90

B15_Cmd_LenUnit:
	pop hl
	ld l, TRK_UNIT
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Release:
	pop hl
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Ext:
	swap a
	and $0F
	ld hl, B15_ExtTable
	call B15_LoadPtrIndexed
	ld a, [de]
	jp hl
B15_ExtTable:
	dw B15_Ext_Duty
	dw B15_Ext_PanBoth
	dw B15_Ext_PanRight
	dw B15_Ext_PanLeft
	dw B15_Ext_AutopanR
	dw B15_Ext_AutopanL
	dw B15_Ext_AutopanOff
	dw B15_Ext_TransposeUp
	dw B15_Ext_TransposeDown

B15_Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call B15_WriteDuty
	inc de
	jp B15_ReadCmds

B15_Ext_PanBoth:
	pop hl
	call B15_PanBoth
	inc de
	jp B15_ReadCmds

B15_PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4451
.l444B:
	sla b
	dec a
	jp nz, .l444B
.l4451:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp B15_WriteRegChecked

B15_Ext_PanRight:
	pop hl
	call B15_PanRight
	inc de
	jp B15_ReadCmds

B15_Ext_PanLeft:
	pop hl
	call B15_PanLeft
	inc de
	jp B15_ReadCmds

B15_AutoPan:
	bit 1, [hl]
	jp nz, .l4475
	set 1, [hl]
	jp B15_PanLeft
.l4475:
	res 1, [hl]

B15_PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l448C
.l4484:
	rlc b
	rlc l
	dec a
	jp nz, .l4484
.l448C:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], $0B
	jp B15_WriteRegChecked

B15_PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l44AE
.l44A6:
	rlc b
	rlc l
	dec a
	jp nz, .l44A6
.l44AE:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp B15_WriteRegChecked

B15_Ext_AutopanR:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 1, [hl]
	inc de
	jp B15_ReadCmds

B15_Ext_AutopanL:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	res 1, [hl]
	inc de
	jp B15_ReadCmds

B15_Ext_AutopanOff:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call B15_PanBoth
	inc de
	jp B15_ReadCmds

B15_Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Ext_TransposeDown:
	pop hl
	and $0F
	jp z, .l44F0
	rlca
	cpl
	inc a
.l44F0:
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l453B
	and $7F
	push hl
	ld hl, B15_VibratoTable - 2
	call B15_LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc de
	ld a, [de]
	and $F0
	swap a
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l4533
	ld b, a
	xor a
	bit 0, b
	jp nz, .l452E
	rrc b
.l4525:
	add a, c
	dec b
	jp nz, .l4525
	add a, a
	jp .l4533
.l452E:
	add a, c
	dec b
	jp nz, .l452E
.l4533:
	ld l, TRK_VIBDELAY
	ld [hl+], a
	ld a, [de]
	and $0F
	inc l
	ld [hl], a
.l453B:
	inc de
	jp B15_ReadCmds

B15_Cmd_EC:
	pop hl
	inc de
	jp B15_ReadCmds

B15_Cmd_ED:
	pop hl
	and $F0
	ld l, TRK_ED_HI
	ld [hl-], a
	ld a, [de]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, B15_WriteDuty
	inc de
	jp B15_ReadCmds

B15_Cmd_Tempo:
	pop hl
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l4573
	ld a, $FF
.l4573:
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Atten:
	pop hl
	dec de
	ld a, [de]
	and $0F
	swap a
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp B15_ReadCmds

B15_Cmd_Volume:
	pop hl
	swap a
	ld l, TRK_VOL
	ld [hl], a
	ld b, a
	ld a, [wTrackDesc]
	cp $63
	jp nz, .l45A3
	ld l, TRK_FLAGS
	bit 3, [hl]
	jp nz, .l45A7
	ld a, b
	call B15_WriteNoiseVolume
	jp .l45A7
.l45A3:
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
.l45A7:
	inc de
	jp B15_ReadCmds

B15_Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [de]
	ld d, a
	ld e, c
	jp B15_ReadCmds

B15_Cmd_Loop:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l45C9
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp B15_ReadCmds
.l45C9:
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l45D7
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp B15_ReadCmds
.l45D7:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp B15_ReadCmds

B15_Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l45F6
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp B15_ReadCmds
.l45F6:
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l4604
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp B15_ReadCmds
.l4604:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp B15_ReadCmds

B15_Cmd_Call:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l4626
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
	jp B15_ReadCmds
.l4626:
	res 2, [hl]
	ld l, TRK_RET
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B15_ReadCmds

B15_Cmd_Segno:
	pop hl
	ld l, TRK_FLOW
	bit 3, [hl]
	jp nz, .l4642
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp B15_ReadCmds
.l4642:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B15_ReadCmds

B15_Cmd_End:
	pop hl
	xor a
	ld l, TRK_ID
	ld a, $00
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, B15_EndSfx2
	cp $40
	jp z, B15_EndSfx1
	cp $63
	jp nz, B15_Silence
	ld l, TRK_FLAGS
	res 3, [hl]
	jp B15_Silence

B15_EndSfx1:
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
	call nz, B15_RestoreMusic
	pop hl
	jp B15_Silence

B15_EndSfx2:
	ld l, TRK_FLAGS
	res 1, [hl]
	push hl
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	call nz, B15_RestoreMusic
	pop hl
	jp B15_Silence

B15_SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

B15_RestoreMusic:
	ld l, TRK_FLAGS
	set 2, [hl]
	set 5, [hl]
	ld l, TRK_PAN
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l46B6
.l46B0:
	rlc b
	dec a
	jp nz, .l46B0
.l46B6:
	ld c, $25
	ldh a, [c]
	and b
	or [hl]
	ldh [c], a
	ld l, TRK_CURPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	jp B15_WritePeriod

B15_LoadPtrIndexed:
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ret

B15_WritePeriod:
	ld l, TRK_CURPERIOD
	ld [hl], e
	inc l
	ld a, d
	and $07
	ld [hl], a
	ld l, TRK_REG3
	ld c, [hl]
	ld a, e
	call B15_WriteRegChecked
	ret nc
	inc c
	ld a, d
	and $07
	ldh [c], a
	ret

B15_Silence:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, B15_SilenceCh3
	ld a, $08
	ld l, TRK_REG2
	ld c, [hl]
	call B15_WriteRegChecked
	ret nc
	ld l, TRK_REG4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ret

B15_SilenceCh3:
	xor a
	ld c, $1C
	jp B15_WriteRegChecked

B15_WriteVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, B15_WriteVolumeTrigger
	ld a, [wTrackDesc]
	and $0F
	ret nz
	ld c, $10
	ldh a, [c]
	and $7F
	cp $08
	ret z
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL

B15_WriteVolumeTrigger:
	ld a, [hl]
	call B15_WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

B15_WriteNoiseVolume:
	ld l, TRK_REG2
	ld c, [hl]
	ld l, TRK_LEVEL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

B15_WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, B15_LoadWave
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld l, TRK_REG1
	ld c, [hl]
	jp B15_WriteRegChecked

B15_LoadWave:
	ld a, [wTrackDesc]
	cp $22
	jp nz, .l4772
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ret nz
.l4772:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld [wWaveId], a
	push hl
	ld c, $1A
	xor a
	ldh [c], a
	ld a, b
	swap a
	ld hl, B15_WaveTable
	call B15_LoadPtrIndexed
	ld c, $30
	ld b, $10
.l4790:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l4790
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG4
	ld c, [hl]
	ld l, TRK_CURPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

B15_WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l47C6
	cp $22
	jp nz, .l47D2
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
.l47C6:
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
.l47D2:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret
B15_PeriodTable:
	dw $02A, $09B, $103, $168, $1C8, $221, $276, $2C5, $311, $357, $39B, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69E, $6B2, $6C5, $6D6, $6E7, $6F7 ; octave index 2
	dw $706, $714, $721, $72D, $73A, $745, $74F, $759, $762, $76B, $774, $77B ; octave index 3
	dw $783, $78A, $2791, $797, $79D, $7A2, $7A8, $7AD, $7B1, $7B5, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
B15_WaveTable:
	dw $07E0
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
	dw B15_WaveData15
B15_WaveData1:
	db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $11
B15_WaveData2:
	db $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $11
B15_WaveData3:
	db $11, $33, $55, $77, $33, $55, $77, $55, $55, $77, $11, $33, $77, $11, $33, $11
B15_WaveData4:
	db $AA, $BB, $CC, $DD, $BB, $CC, $DD, $CC, $CC, $DD, $AA, $BB, $DD, $AA, $BB, $AA
B15_WaveData5:
	db $89, $AB, $CD, $EF, $CD, $AB, $89, $67, $89, $AB, $CD, $EF, $CD, $AB, $89, $67
B15_WaveData6:
	db $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $0E, $0D, $0C
B15_WaveData7:
	db $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08
B15_WaveData8:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $04, $04, $04, $04, $04, $04
B15_WaveData9:
	db $55, $66, $77, $88, $99, $00, $00, $00, $00, $00, $99, $88, $55, $FF, $55, $BB
B15_WaveData10:
	db $44, $55, $66, $77, $88, $00, $00, $00, $00, $00, $88, $77, $44, $FF, $44, $AA
B15_WaveData11:
	db $66, $33, $00, $33, $66, $33, $00, $33, $66, $77, $88, $99, $AA, $BB, $CC, $DD
B15_WaveData12:
	db $88, $44, $88, $44, $88, $44, $00, $44, $88, $44, $00, $88, $44, $88, $44, $00
B15_WaveData13:
	db $34, $45, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE
B15_WaveData14:
	db $00, $11, $12, $46, $9B, $DE, $EF, $FF, $FF, $EE, $ED, $B9, $64, $21, $11, $00
B15_WaveData15:
	db $02, $46, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $45, $65, $43
B15_SoundTable:
	db $21, $00
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
	dw SndHdrDA ; $DA
	dw SndHdrDB ; $DB
	dw SndHdrDC ; $DC
	dw SndHdrDD ; $DD
	dw SndHdrDE ; $DE
	dw SndHdrDF ; $DF
	dw SndHdrE0 ; $E0
	dw SndHdrE1 ; $E1
	dw SndHdrE2 ; $E2
	dw SndHdrE3 ; $E3
	dw SndHdrE4 ; $E4
	dw SndHdrE5 ; $E5
	dw SndHdrE6 ; $E6
	dw SndHdrE7 ; $E7
	dw SndHdrE8 ; $E8
	dw SndHdrE9 ; $E9
	dw SndHdrEA ; $EA
	dw SndHdrEB ; $EB
	dw SndHdrEC ; $EC
	dw SndHdrED ; $ED
	dw SndHdrEE ; $EE
	dw SndHdrEF ; $EF
	dw SndHdrF0 ; $F0
	dw SndHdrF1 ; $F1
	dw SndHdrF2 ; $F2
	dw SndHdrF3 ; $F3

SndHdrC1:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndC1_SfxN

SndHdrC2:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndC2_SfxN

SndHdrC3:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndC3_SfxN

SndHdrC4:
	SND_HEADER $18, $04 ; tracks: SfxN
	dw SndC4_SfxN

SndHdrC5:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndC5_SfxN

SndHdrC6:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw SndC6_Sfx1
	dw SndC6_SfxN

SndHdrC7:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw SndC7_Sfx1
	dw SndC6_SfxN

SndHdrC8:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw SndC8_Sfx1
	dw SndC6_SfxN

SndHdrC9:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndC9_SfxN

SndHdrCA:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndCA_SfxN

SndHdrCB:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndCB_SfxN

SndHdrCC:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndCC_SfxN

SndHdrCD:
	SND_HEADER $10, $04 ; tracks: SfxN
	dw SndCD_SfxN

SndHdrCE:
	SND_HEADER $80, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndCE_Ch1
	dw SndCE_Ch2
	dw SndCE_Ch3
	dw SndCE_Drm

SndHdrCF:
	SND_HEADER $40, $3C ; tracks: SfxN, Ch1, Ch2, Ch3
	dw SndCF_SfxN
	dw SndCF_Ch1
	dw SndCF_Ch2
	dw SndCF_Ch3

SndHdrD0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD0_Ch1
	dw SndD0_Ch2
	dw SndD0_Ch3
	dw SndD0_Drm

SndHdrD1:
	SND_HEADER $A0, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD1_Ch1
	dw SndD1_Ch2
	dw SndD1_Ch3
	dw SndD1_Drm

SndHdrD2:
	SND_HEADER $A0, $7C ; tracks: SfxN, Ch1, Ch2, Ch3, Drm
	dw SndD2_SfxN
	dw SndD2_Ch1
	dw SndD2_Ch2
	dw SndD2_Ch3
	dw SndD2_Drm

SndHdrD3:
	SND_HEADER $A0, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD3_Ch1
	dw SndD3_Ch2
	dw SndD3_Ch3
	dw SndD3_Drm

SndHdrD4:
	SND_HEADER $A0, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndD4_Ch1
	dw SndD4_Ch2
	dw SndD4_Ch3
	dw SndD3_Drm

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

SndHdrDA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDA_Ch1
	dw SndDA_Ch2
	dw SndDA_Ch3
	dw SndDA_Drm

SndHdrDB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDB_Ch1
	dw SndDB_Ch2
	dw SndDB_Ch3
	dw SndDB_Drm

SndHdrDC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDC_Ch1
	dw SndDC_Ch2
	dw SndDC_Ch3
	dw SndDC_Drm

SndHdrDD:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDD_Ch1
	dw SndDD_Ch2
	dw SndDD_Ch3
	dw SndDD_Drm

SndHdrDE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDE_Ch1
	dw SndDE_Ch2
	dw SndDE_Ch3
	dw SndDE_Drm

SndHdrDF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndDF_Ch1
	dw SndDF_Ch2
	dw SndDF_Ch3
	dw SndDF_Drm

SndHdrE0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE0_Ch1
	dw SndE0_Ch2
	dw SndE0_Ch3
	dw SndE0_Drm

SndHdrE1:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE1_Ch1
	dw SndE1_Ch2
	dw SndE1_Ch3
	dw SndE1_Drm

SndHdrE2:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE2_Ch1
	dw SndE2_Ch2
	dw SndE2_Ch3
	dw SndE2_Drm

SndHdrE3:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE3_Ch1
	dw SndE3_Ch2
	dw SndE3_Ch3
	dw SndE3_Drm

SndHdrE4:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE4_Ch1
	dw SndE4_Ch2
	dw SndE4_Ch3
	dw SndE4_Drm

SndHdrE5:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE5_Ch1
	dw SndE5_Ch2
	dw SndE5_Ch3
	dw SndE5_Drm

SndHdrE6:
	SND_HEADER $F1, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw SndE6_Sfx1
	dw SndE6_Sfx2
	dw SndE6_SfxN

SndHdrE7:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE7_Ch1
	dw SndE7_Ch2
	dw SndE7_Ch3
	dw SndE7_Drm

SndHdrE8:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE8_Ch1
	dw SndE8_Ch2
	dw SndE8_Ch3
	dw SndE8_Drm

SndHdrE9:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndE9_Ch1
	dw SndE9_Ch2
	dw SndE9_Ch3
	dw SndE9_Drm

SndHdrEA:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEA_Ch1
	dw SndEA_Ch2
	dw SndEA_Ch3
	dw SndEA_Drm

SndHdrEB:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEB_Ch1
	dw SndEB_Ch2
	dw SndEB_Ch3
	dw SndEB_Drm

SndHdrEC:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEC_Ch1
	dw SndEC_Ch2
	dw SndEC_Ch3
	dw SndEC_Drm

SndHdrED:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndED_Ch1
	dw SndED_Ch2
	dw SndED_Ch3
	dw SndED_Drm

SndHdrEE:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEE_Ch1
	dw SndEE_Ch2
	dw SndEE_Ch3
	dw SndEE_Drm

SndHdrEF:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndEF_Ch1
	dw SndEF_Ch2
	dw SndEF_Ch3
	dw SndEF_Drm

SndHdrF0:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw SndF0_Ch1
	dw SndF0_Ch2
	dw SndF0_Ch3
	dw SndF0_Drm

SndHdrF1:
	SND_HEADER $40, $38 ; tracks: Ch1, Ch2, Ch3
	dw SndF1_Ch1
	dw SndF1_Ch2
	dw SndF1_Ch3

SndHdrF2:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndF2_Sfx1
	dw SndF2_SfxN

SndHdrF3:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw SndF3_Sfx1
	dw SndF3_SfxN

SndC1_SfxN:
	NVOICE $20, $61
	NOISE $02
	SND_END

SndC2_SfxN:
	NVOICE $20, $81
	NOISE $03
	SND_END

SndC3_SfxN:
	NVOICE $40, $73
	NOISE $05
	SND_END

SndC4_SfxN:
	NVOICE $04, $C0
	NOISE $53
	NOISE $42
	NOISE $41
	NOISE $40
	NVOICE $04, $40
	NOISE $53
	NOISE $42
	NOISE $41
	NOISE $40
	SND_END

SndC5_SfxN:
	NVOICE $01, $F0
	NOISE $78
	NOISE $77
	NOISE $76
	NOISE $75
	NVOICE $20, $51
	NOISE $03
	SND_END

SndC6_Sfx1:
	VOICE $08, 8, 10, 0, 0
	SWEEP $3D
	OCTAVE 3
	NOTE C#, 4
	SND_END

SndC6_SfxN:
	NVOICE_HOLD $04
	NOISE_HOLD 11, $58
	NOISE_HOLD 11, $57
	NVOICE_HOLD $0A
	NOISE_HOLD 4, $13
	NVOICE_HOLD $01
	NOISE_HOLD 3, $14
	NOISE_HOLD 2, $13
	NOISE_HOLD 1, $12
	SND_END

SndC7_Sfx1:
	VOICE $0C, 8, 8, 0, 0
	SWEEP $2D
	OCTAVE 3
	NOTE C#, 4
	SND_END

SndC8_Sfx1:
	VOICE $0C, 8, 8, 0, 0
	SWEEP $1D
	OCTAVE 3
	NOTE C#, 4
	SND_END

SndC9_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 12, $38
	NOISE_HOLD 12, $37
	NOISE_HOLD 12, $36
	NOISE_HOLD 12, $35
	NVOICE_HOLD $10
	NOISE_HOLD 5, $13
	NOISE_HOLD 4, $13
	NOISE_HOLD 3, $13
	NOISE_HOLD 2, $13
	SND_END

SndCA_SfxN:
	NVOICE $7F, $76
	NOISE $23
	NOISE $22
	SND_END

SndCB_SfxN:
	NVOICE_HOLD $01
	NOISE_HOLD 15, $38
	NOISE_HOLD 15, $37
	NOISE_HOLD 15, $36
	NOISE_HOLD 15, $35
	NVOICE_HOLD $10
	NOISE_HOLD 6, $23
	NOISE_HOLD 3, $23
	NOISE_HOLD 2, $23
	NOISE_HOLD 1, $23
	SND_END

SndCC_SfxN:
	NVOICE $01, $F0
	NOISE $58
	NOISE $57
	NOISE $56
	NOISE $54
	NVOICE $10, $F0
	NOISE $22
	NVOICE $04, $00
	NOISE $22
	NVOICE $10, $A7
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

SndCD_SfxN:
	SND_END
B15_VibratoTable:
	dw B15_Vib01 ; 1
	dw B15_Vib02 ; 2
	dw B15_Vib03 ; 3
	dw B15_Vib04 ; 4
	dw B15_Vib05 ; 5
	dw B15_Vib06 ; 6
	dw B15_Vib07 ; 7
	dw B15_Vib02 ; 8
	dw B15_Vib09 ; 9
	dw B15_Vib02 ; 10
	dw B15_Vib0B ; 11
	dw B15_Vib0C ; 12
	dw B15_Vib0D ; 13
	dw B15_Vib0E ; 14

B15_Vib01:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_MARK

B15_Vib03:
	VIB_LOOP_START
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 0, 1
	VIB_STEP 3, 0, 0
	VIB_STEP 3, 1, 1
	VIB_LOOP_END 2
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 1, 1
	VIB_MARK

B15_Vib04:
	VIB_STEP 1, 1, 1
	VIB_END

B15_Vib05:
	VIB_LOOP_START
	VIB_STEP 2, 0, 0
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_LOOP_END 4
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_MARK

B15_Vib06:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_MARK

B15_Vib07:
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

B15_Vib09:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_END

B15_Vib02:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

B15_Vib0B:
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_END

B15_Vib0C:
	VIB_MARK
	VIB_STEP 4, 0, 0
	VIB_STEP 4, 0, 1
	VIB_STEP 4, 0, 2
	VIB_STEP 4, 0, 1
	VIB_MARK
	db $FF

B15_Vib0D:
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 10, 0, 0
	VIB_MARK
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

B15_Vib0E:
	VIB_STEP 4, 1, 3
	VIB_STEP 4, 1, 2
	VIB_STEP 4, 1, 1
	VIB_STEP 10, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 10, 0, 0
	VIB_MARK
	VIB_STEP 4, 0, 0
	VIB_STEP 4, 0, 1
	VIB_STEP 4, 0, 2
	VIB_STEP 4, 0, 1
	VIB_STEP 4, 0, 0
	VIB_STEP 4, 1, 1
	VIB_STEP 4, 1, 2
	VIB_STEP 4, 1, 1
	VIB_MARK

SndCE_Ch1:
	VOICE $04, 0, 10, 12, 3
	TEMPO $1C
	REST 0
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	RELEASE $0C, 1
	NOTE E_, 2
	RELEASE $0C, 3
	NOTE E_, 4
	RELEASE $0C, 1
	NOTE E_, 2
	RELEASE $0C, 3
	NOTE E_, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	RELEASE $0C, 1
	NOTE G_, 2
	RELEASE $0C, 3
	NOTE G_, 4
	RELEASE $0C, 1
	NOTE G_, 2
	RELEASE $0C, 3
	NOTE G_, 4
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	RELEASE $0C, 1
	NOTE C_, 2
	RELEASE $0C, 3
	NOTE C_, 4
	RELEASE $0C, 1
	NOTE C_, 2
	RELEASE $0C, 3
	NOTE C_, 4
	RELEASE $0C, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $0C, 3
	NOTE D_, 4
	NOTE E_, 4
	RELEASE $0C, 1
	REST 4
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $0C, 3
	NOTE E_, 4
	ATTEN 5
	LEN_UNIT 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	SND_END

SndCE_Ch2:
	VOICE $04, 0, 10, 12, 3
	REST 0
	OCTAVE 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	RELEASE $0C, 1
	NOTE A_, 2
	RELEASE $0C, 3
	NOTE G_, 4
	RELEASE $0C, 1
	NOTE G_, 2
	RELEASE $0C, 3
	NOTE A_, 4
	NOTE D#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	RELEASE $0C, 1
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0C, 3
	OCTAVE 3
	NOTE A#, 4
	RELEASE $0C, 1
	NOTE A#, 2
	RELEASE $0C, 3
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 4
	RELEASE $0C, 1
	NOTE F_, 2
	RELEASE $0C, 3
	NOTE D#, 4
	RELEASE $0C, 1
	NOTE D#, 2
	RELEASE $0C, 3
	NOTE F_, 4
	RELEASE $0C, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	RELEASE $0C, 3
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	REST 4
	RELEASE $0C, 1
	NOTE C_, 2
	NOTE C_, 2
	RELEASE $0C, 3
	NOTE C_, 4
	ATTEN 5
	LEN_UNIT 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

SndCE_Ch3:
	VOICE $04, 8, 2, 11, 3
	REST 0
	OCTAVE 2
	LOOP_START
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END 7
	NOTE D_, 2
	NOTE D_, 2
	LOOP_START
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END 7
	NOTE C_, 2
	NOTE C_, 2
	LOOP_START
	NOTE F_, 2
	NOTE F_, 2
	LOOP_END 4
	LOOP_START
	NOTE G#, 2
	NOTE G#, 2
	LOOP_END 3
	NOTE A#, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 4
	REST 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 4
	SND_END

SndCE_Drm:
	LEN_UNIT 4
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 8, 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 4
	DRUM 2, 2
	DRUM 9, 2
	DRUM 3, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 6, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	LEN_UNIT 5
	DRUM $0A, 0
	SND_END

SndCF_SfxN:
	SND_SEGNO
	NVOICE $50, $28
	NOISE $10
	NOISE $10
	NOISE $10
	NOISE $10
	NOISE $10
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $10
	SND_LOOP

SndCF_Ch1:
	VOICE $08, 0, 5, 11, 4
	SND_SEGNO
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	SND_LOOP

SndCF_Ch2:
	VOICE $08, 0, 5, 11, 4
	REST 2
	OCTAVE 2
	SND_SEGNO
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 4
	NOTE A#, 4
	SND_LOOP

SndCF_Ch3:
	SND_SEGNO
	VOICE $20, 6, 6, 0, 0
	VIBRATO $81, 1, 2
	OCTAVE 5
	NOTE A_, $0F
	VOICE $20, 6, 6, 0, 0
	VIBRATO $81, 0, 2
	OCTAVE 5
	NOTE A_, $0F
	NOTE A_, $0F
	SND_LOOP

SndD0_Ch1:
	VOICE $05, 0, 5, 8, 5
	TEMPO $10
	DETUNE $FE
	REST 4
	AUTOPAN_L 0
	SND_SEGNO
	SND_CALL SndD0_Ch1_4E2A
	SND_LOOP

SndD0_Ch2:
	VOICE $05, 0, 7, 12, 3
	CMD_ED $41
	SND_SEGNO
	SND_CALL SndD0_Ch1_4E2A
	SND_LOOP
SndD0_Ch1_4E2A:
	OCTAVE 2
	LOOP_START
	ATTEN 0
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	ATTEN 4
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	LOOP_END 2
	ATTEN 0
	OCTAVE 3
	LOOP_START
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	LOOP_END 2
	LOOP_START
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 2
	LOOP_START
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	LOOP_END 2
	LOOP_START
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	LOOP_END 2
	LOOP_START
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 2
	LOOP_START
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	LOOP_END 2
	LOOP_START
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 2
	OCTAVE 4
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 2
	SND_RET

SndD0_Ch3:
	VOICE $05, 2, 2, 6, 8
	VIBRATO $83, 0, 15
	SND_SEGNO
	OCTAVE 2
	NOTE G_, 0
	NOTE C#, 0
	NOTE D_, 8
	NOTE D#, 8
	NOTE D_, 8
	NOTE D#, 8
	NOTE F_, 8
	NOTE F#, 8
	NOTE F_, 8
	NOTE F#, 8
	SND_LOOP

SndD0_Drm:
	LEN_UNIT 5
	SND_SEGNO
	LOOP_START
	DRUM 5, 4
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 4
	DRUM 2, 4
	LOOP_END 5
	DRUM 5, 4
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 4
	DRUM $0A, 4
	SND_LOOP

SndD1_Ch1:
	VOICE $03, 0, 8, 13, 1
	TEMPO $58
	OCTAVE 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE A#, 1
	SND_CALL SndD1_Ch1_4EFC
	OCTAVE 3
	NOTE C_HI, 4
	NOTE A#, 2
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	NOTE C_HI, 2
	REST 2
	NOTE G#, 6
	REST 2
	NOTE A#, 6
	VIBRATO_OFF
	LEN_UNIT 1
	ATTEN 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 6
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	SND_END

SndD2_SfxN:
	SND_END

SndD2_Ch1:
	SND_CALL SndD1_Ch1_4EFC
	TEMPO $58
	REST 4
	OCTAVE 4
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 2
	SND_END
SndD1_Ch1_4EFC:
	VOICE $03, 0, 9, 11, 4
	CMD_ED $41
	VIBRATO $8D, 0, 2
	SND_RET

SndD1_Ch2:
	VOICE $03, 0, 8, 13, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 6
	NOTE D_, 1
	DETUNE $00
	SND_CALL SndD1_Ch1_4EFC
	OCTAVE 4
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 2
	ATTEN 0
	NOTE F_, 2
	REST 2
	NOTE C#, 6
	REST 2
	NOTE D#, 6
	VIBRATO_OFF
	LEN_UNIT 1
	ATTEN 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	ATTEN 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 6
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	SND_END

SndD2_Ch2:
	SND_CALL SndD1_Ch1_4EFC
	REST 4
	OCTAVE 4
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 2
	ATTEN 0
	NOTE D#, 2
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 2
	SND_END

SndD1_Ch3:
	VOICE $03, 5, 2, 0, 0
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE A#, 1
	OCTAVE 6
	NOTE D_, 1
	OCTAVE 5
	NOTE A#, 1
	OCTAVE 6
	NOTE D_, 1
	NOTE A#, 1
	TRANSPOSE_UP $0C
	OCTAVE 6
	NOTE D_, 1
	TRANSPOSE_UP 0
	VOICE $03, 9, 2, 11, 4
	OCTAVE 2
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	VOICE $03, 12, 2, 11, 4
	LOOP_START
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	LOOP_END 2
	OCTAVE 2
	NOTE D#, 2
	VOICE $03, 9, 2, 11, 6
	NOTE D#, 6
	SND_END

SndD2_Ch3:
	VOICE $03, 9, 2, 11, 4
	REST 4
	OCTAVE 2
	NOTE F_, 2
	VOICE $03, 9, 4, 0, 0
	NOTE F_, 2
	VOICE $03, 9, 2, 11, 4
	NOTE D#, 2
	NOTE G#, 2
	VOICE $03, 9, 4, 0, 0
	NOTE G#, 2
	VOICE $03, 9, 2, 11, 4
	NOTE F_, 2
	VOICE $03, 9, 4, 0, 0
	NOTE F_, 2
	SND_END

SndD1_Drm:
	LEN_UNIT 3
	REST 0
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 3, 6
	SND_END

SndD2_Drm:
	LEN_UNIT 3
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_END

SndD3_Ch1:
	SND_CALL SndD3_Ch1_4FFC
	SND_END

SndD4_Ch1:
	SND_CALL SndD3_Ch1_4FFC
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 2
	ATTEN 5
	NOTE D#, 1
	ATTEN 0
	NOTE A#, 1
	RELEASE $0D, 4
	NOTE A#, 9
	SND_END
SndD3_Ch1_4FFC:
	VOICE $04, 0, 8, 13, 1
	VIBRATO $87, 2, 2
	CMD_ED $41
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	RELEASE $0D, 4
	NOTE G_, 8
	SND_RET

SndD3_Ch2:
	SND_CALL SndD3_Ch2_5035
	SND_END

SndD4_Ch2:
	SND_CALL SndD3_Ch2_5035
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 1
	ATTEN 0
	OCTAVE 5
	NOTE D#, 1
	RELEASE $0D, 4
	NOTE D#, 9
	SND_END
SndD3_Ch2_5035:
	VOICE $04, 0, 8, 13, 1
	VIBRATO $87, 2, 2
	CMD_ED $41
	OCTAVE 3
	NOTE D#, 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	RELEASE $0D, 4
	NOTE A#, 8
	SND_RET

SndD3_Ch3:
	SND_CALL SndD3_Ch3_506E
	SND_END

SndD4_Ch3:
	SND_CALL SndD3_Ch3_506E
	OCTAVE 5
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE A#, 2
	VOICE $04, 5, 4, 0, 0
	NOTE A#, 1
	VOICE $04, 5, 2, 11, 5
	OCTAVE 5
	NOTE D#, 1
	NOTE D#, 9
	SND_END
SndD3_Ch3_506E:
	VOICE $04, 5, 2, 11, 5
	VIBRATO $87, 2, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 8
	SND_RET

SndD3_Drm:
	SND_END

SndD5_Ch1:
	VOICE $04, 4, 9, 13, 1
	REST 8
	CMD_ED $01
	VIBRATO $88, 0, 4
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	RELEASE $0A, 3
	NOTE G_, 6
	LEN_UNIT 1
	VIBRATO_OFF
	ATTEN 6
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_END

SndD5_Ch2:
	VOICE $04, 4, 9, 13, 1
	CMD_ED $01
	VIBRATO $88, 0, 4
	REST 8
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE $0A, 3
	NOTE C_HI, 6
	LEN_UNIT 1
	VIBRATO_OFF
	ATTEN 6
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
	OCTAVE 3
	NOTE A#, 1
	SND_END

SndD5_Ch3:
	VOICE $04, 10, 2, 11, 3
	REST 8
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE C_HI, 6
	SND_END

SndD5_Drm:
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0A, $0A
	SND_END

SndD6_Ch1:
	VOICE $04, 0, 9, 13, 2
	TEMPO $20
	REST 8
	CMD_ED $41
	VIBRATO $88, 0, 4
	OCTAVE 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE A#, 2
	RELEASE $0A, 5
	NOTE G_, $0A
	SND_END

SndD6_Ch2:
	VOICE $04, 0, 9, 13, 2
	CMD_ED $41
	VIBRATO $88, 0, 4
	REST 8
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	RELEASE $0A, 5
	NOTE C_, $0A
	SND_END

SndD6_Ch3:
	VOICE $04, 12, 2, 11, 4
	REST 8
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO $86, 2, 15
	RELEASE $0A, 6
	NOTE C_, $0A
	SND_END

SndD6_Drm:
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0A, $0A
	SND_END

SndD7_Ch1:
	SND_CALL SndD7_Ch1_518C
	SND_END

SndD8_Ch1:
	SND_CALL SndD7_Ch1_518C
	REST 4
	RELEASE $0D, 2
	ATTEN 0
	VIBRATO $82, 0, 4
	NOTE E_, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 2
	ATTEN 6
	LEN_UNIT 1
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
	SND_END
SndD7_Ch1_518C:
	VOICE $04, 0, 10, 13, 2
	CMD_ED $18
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $0C, 3
	NOTE D_, 2
	ATTEN 7
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 7
	NOTE E_, 2
	SND_RET

SndD7_Ch2:
	SND_CALL SndD7_Ch2_51C5
	SND_END

SndD8_Ch2:
	SND_CALL SndD7_Ch2_51C5
	ATTEN 0
	RELEASE $0D, 2
	REST 4
	VIBRATO $82, 0, 4
	NOTE C_HI, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE C_HI, 2
	ATTEN 5
	LEN_UNIT 1
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
	NOTE C#, 1
	NOTE C_, 1
	SND_END
SndD7_Ch2_51C5:
	VOICE $04, 0, 11, 13, 1
	TEMPO $1C
	CMD_ED $18
	OCTAVE 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE $0C, 3
	NOTE A#, 2
	ATTEN 7
	NOTE A#, 2
	ATTEN 0
	NOTE C_HI, 2
	ATTEN 7
	NOTE C_HI, 2
	SND_RET

SndD7_Ch3:
	SND_CALL SndD7_Ch3_51F1
	SND_END

SndD8_Ch3:
	SND_CALL SndD7_Ch3_51F1
	VOICE $04, 8, 6, 0, 0
	NOTE C_, 4
	VOICE $04, 8, 2, 11, 3
	NOTE C_, 4
	RELEASE $0B, 5
	NOTE C_, 4
	SND_END
SndD7_Ch3_51F1:
	VOICE $04, 8, 2, 11, 3
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	RELEASE $0B, 5
	NOTE C_, 4
	NOTE C_, 4
	SND_RET

SndD7_Drm:
	SND_CALL SndD7_Drm_520C
	SND_END

SndD8_Drm:
	SND_CALL SndD7_Drm_520C
	DRUM 7, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0A, 6
	SND_END
SndD7_Drm_520C:
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	SND_RET

SndD9_Ch1:
	VOICE $04, 12, 4, 0, 0
	TEMPO $10
	LOOP_START
	REST 0
	LOOP_END 4
	SND_SEGNO
	VOICE $04, 12, 8, 12, 3
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE E_, 4
	VOICE $04, 4, 6, 12, 2
	LOOP_START
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	LOOP_END 3
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	LOOP_END 2
	SND_CALL SndD9_Ch1_5282
	VOICE $04, 12, 8, 12, 3
	LOOP_START
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	LOOP_END 2
	SND_CALL SndD9_Ch1_5282
	SND_LOOP
SndD9_Ch1_5282:
	LOOP_START
	VOICE $04, 12, 8, 10, 5
	OCTAVE 2
	NOTE A#, 0
	NOTE A_, 8
	NOTE G#, 8
	RELEASE $0C, 3
	OCTAVE 2
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 4
	LOOP_END 2
	RELEASE $0A, 6
	OCTAVE 3
	NOTE C_, 0
	NOTE D_, 0
	NOTE D#, 0
	NOTE F_, 0
	SND_RET

SndD9_Ch2:
	VOICE $04, 0, 7, 12, 2
	DETUNE $FC
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_END 3
	RELEASE $0C, 4
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
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	DETUNE $00
	SND_SEGNO
	VOICE $04, 12, 8, 12, 4
	CMD_ED $01
	OCTAVE 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE D#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 6
	CMD_ED $00
	LEN_UNIT 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	LEN_UNIT 4
	CMD_ED $41
	OCTAVE 4
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 6
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 2
	NOTE G_, 6
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, $0C
	VOICE $04, 8, 8, 12, 3
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	VOICE $04, 12, 8, 12, 4
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 6
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 6
	NOTE D#, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D#, $0C
	VOICE $04, 8, 8, 12, 3
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	VOICE $04, 12, 8, 12, 4
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 2
	OCTAVE 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, $0E
	NOTE D#, 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE F_, 6
	NOTE D#, 4
	RELEASE $0C, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 8
	RELEASE $0C, 4
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 4
	LOOP_END 2
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE F_, 6
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, $0C
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 8
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 6
	NOTE F_, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 6
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D#, $0C
	OCTAVE 3
	NOTE F_, 4
	NOTE D#, 8
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE F_, 6
	NOTE D#, 4
	NOTE G_, $0C
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 2
	NOTE F_, 6
	NOTE F_, 2
	NOTE D#, 2
	RELEASE $0C, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	CMD_ED $00
	LEN_UNIT 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_LOOP

SndD9_Ch3:
	VOICE $04, 10, 2, 11, 3
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_END 3
	VOICE $04, 1, 2, 12, 3
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
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_SEGNO
	VOICE $04, 10, 2, 11, 3
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 7
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END 7
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_START
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	LOOP_END 3
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 7
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_CALL SndD9_Ch3_546D
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END $10
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 7
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	SND_CALL SndD9_Ch3_546D
	SND_LOOP
SndD9_Ch3_546D:
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 8
	LOOP_START
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_END 4
	LOOP_START
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	LOOP_END 4
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	SND_RET

SndD9_Drm:
	LEN_UNIT 4
	LOOP_START
	REST 0
	LOOP_END 3
	DRUM 7, 4
	DRUM 8, 4
	DRUM 6, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 8, 2
	LEN_UNIT 4
	SND_SEGNO
	LOOP_START
	SND_CALL SndD9_Drm_5506
	LOOP_END 3
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_CALL SndD9_Drm_54E0
	LOOP_START
	SND_CALL SndD9_Drm_5506
	LOOP_END 2
	SND_CALL SndD9_Drm_54E0
	SND_LOOP
SndD9_Drm_54E0:
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 3, 2
	LOOP_END 4
	LOOP_START
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 3, 4
	DRUM 9, 2
	DRUM 2, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 6, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 8, 2
	SND_RET
SndD9_Drm_5506:
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 3, 2
	SND_RET

SndDA_Ch1:
	VOICE $05, 4, 4, 13, 4
	CMD_ED $01
	DETUNE $FF
	REST 2
	OCTAVE 3
	NOTE A_, 2
	AUTOPAN_L 0
	SND_CALL SndDA_Ch1_5635
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	AUTOPAN_OFF 0

SndDB_Ch1:
	VOICE $05, 4, 4, 0, 0
	CMD_ED $01
	DETUNE $FE
	REST 2
	OCTAVE 3
	NOTE A_, 2
	SND_SEGNO
	VOICE $05, 4, 4, 0, 0
	CMD_ED $01
	DETUNE $FE
	AUTOPAN_L 0
	SND_CALL SndDA_Ch1_5635
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	AUTOPAN_OFF 0
	LOOP_START
	VOICE $05, 12, 8, 10, 5
	DETUNE $00
	CMD_ED $01
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 3
	NOTE E_, 2
	NOTE G_, 2
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	VIBRATO $87, 0, 8
	NOTE G_, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE E_, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 2
	DETUNE $FD
	DUTY 0
	OCTAVE 2
	REST 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	REST 2
	NOTE E_, 1
	NOTE F_, 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	VIBRATO $87, 0, 4
	NOTE G_, 4
	VIBRATO_OFF
	LOOP_END 2
	DUTY $0C
	DETUNE $00
	VIBRATO $87, 3, 8
	OCTAVE 3
	NOTE C_, 6
	ATTEN 3
	NOTE C_, 6
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 4
	REST 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	DETUNE $FE
	VIBRATO $87, 3, 8
	NOTE C_, 5
	ATTEN 3
	NOTE C_, 5
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 4
	REST 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 6
	VIBRATO_OFF
	DETUNE $00
	RELEASE $0D, 3
	ATTEN 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	VOLUME $0B
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 5
	NOTE E_, 4
	VIBRATO_OFF
	ATTEN 0
	REST 2
	SND_LOOP
SndDA_Ch1_5635:
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	LOOP2_END 2
	SND_RET

SndDA_Ch2:
	VOICE $05, 4, 8, 13, 3
	CMD_ED $01
	OCTAVE 3
	NOTE A_, 2
	SND_CALL SndDA_Ch1_5635
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1

SndDB_Ch2:
	VOICE $05, 4, 6, 0, 0
	CMD_ED $01
	OCTAVE 3
	NOTE A_, 2
	SND_SEGNO
	VOICE $05, 4, 6, 0, 0
	CMD_ED $01
	SND_CALL SndDA_Ch1_5635
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 2
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	LOOP_END 2
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	LOOP_START
	VOICE $05, 12, 8, 10, 5
	CMD_ED $01
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE D#, 2
	NOTE D_, 2
	REST 2
	VIBRATO $87, 0, 8
	NOTE C_, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE B_, 4
	DUTY 0
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 2
	REST 2
	NOTE E_, 1
	NOTE F_, 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	VIBRATO $87, 0, 4
	NOTE G_, 4
	VIBRATO_OFF
	LOOP_END 2
	DUTY $0C
	VIBRATO $87, 3, 8
	NOTE C_, 6
	ATTEN 3
	NOTE C_, 6
	ATTEN 0
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 4
	REST 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	VIBRATO $87, 3, 8
	NOTE C_, 5
	ATTEN 3
	NOTE C_, 5
	ATTEN 0
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 4
	REST 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE $0D, 3
	ATTEN 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOLUME $0B
	ATTEN 0
	NOTE G_, 2
	NOTE E_, 2
	ATTEN 3
	NOTE G_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE G_, 2
	NOTE E_, 2
	VIBRATO_OFF
	ATTEN 5
	OCTAVE 3
	NOTE A_, 4
	ATTEN 0
	SND_LOOP

SndDA_Ch3:
	VOICE $05, 9, 2, 11, 4
	REST 0
	REST 0
	REST 0
	REST 0

SndDB_Ch3:
	VOICE $05, 9, 2, 11, 4
	OCTAVE 2
	NOTE A_, 4
	SND_SEGNO
	VOICE $05, 9, 2, 11, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	LOOP_START ; loop byte read both as a start and as an end (see doc)
	VOICE $05, 9, 2, 11, 5
	SND_CALL SndDA_Ch3_5811
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	SND_CALL SndDA_Ch3_5811
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	VOICE $05, 9, 2, 11, 4
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	VOICE $05, 12, 2, 11, 4
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOICE $05, 8, 2, 11, 3
	OCTAVE 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 2
	VOICE $05, 9, 2, 11, 4
	OCTAVE 2
	NOTE A_, 4
	SND_LOOP
SndDA_Ch3_5811:
	VOICE $05, 9, 2, 11, 4
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	VOICE $05, 12, 2, 11, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	SND_RET

SndDA_Drm:
	LEN_UNIT 5
	REST 0
	REST 0
	REST 0
	REST 8
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2

SndDB_Drm:
	DRUM 8, 2
	SND_SEGNO
	SND_CALL SndDA_Drm_589E
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 7, 2
	DRUM 8, 2
	SND_CALL SndDA_Drm_589E
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 3, 2
	SND_CALL SndDA_Drm_589E
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM $0B, 2
	LOOP_END 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 9, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 6, 1
	DRUM 7, 1
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	SND_LOOP
SndDA_Drm_589E:
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 9, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 5, 1
	DRUM 1, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 9, 2
	DRUM 5, 2
	SND_RET

SndDC_Ch1:
	SND_SEGNO
	SND_CALL SndDC_Ch1_59A5
	OCTAVE 3
	NOTE A#, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	VIBRATO $87, 0, 2
	NOTE A#, 6
	VIBRATO_OFF
	NOTE A#, 4
	NOTE D_, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	ATTEN 1
	DUTY 8
	CMD_ED $00
	RELEASE $0D, 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	ATTEN 0
	SND_CALL SndDC_Ch1_59A5
	OCTAVE 3
	NOTE A#, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 4
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE A_, 2
	ATTEN 1
	DUTY 8
	CMD_ED $00
	RELEASE $0D, 3
	LEN_UNIT 1
	OCTAVE 4
	NOTE F_, 3
	NOTE C_, 4
	OCTAVE 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A_, 3
	ATTEN 0
	VOICE $05, 0, 8, 13, 4
	CMD_ED $C1
	SND_CALL SndDC_Ch1_5981
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	REST 4
	SND_CALL SndDC_Ch1_5981
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	VOICE $05, 8, 7, 10, 3
	CMD_ED $41
	VIBRATO $88, 0, 3
	SND_CALL SndDC_Ch1_59CB
	NOTE B_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	SND_CALL SndDC_Ch1_59CB
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	OCTAVE 4
	NOTE D_, 4
	VIBRATO_OFF
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	VOICE $05, 0, 8, 13, 4
	CMD_ED $C1
	VIBRATO $87, 0, 2
	NOTE C_, 6
	VIBRATO_OFF
	SND_CALL SndDC_Ch1_5996
	NOTE A_, 2
	REST 2
	NOTE B_, 2
	NOTE A_, 2
	REST 2
	VIBRATO $87, 0, 2
	NOTE C_HI, 4
	VIBRATO_OFF
	NOTE C_HI, 2
	NOTE A#, 2
	REST 2
	NOTE G#, 2
	NOTE A#, 4
	VIBRATO $87, 0, 2
	NOTE C_HI, 6
	VIBRATO_OFF
	SND_CALL SndDC_Ch1_5996
	NOTE A_, 2
	REST 2
	NOTE B_, 2
	REST 2
	NOTE A_, 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE D_, 4
	VIBRATO_OFF
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	SND_LOOP
SndDC_Ch1_5981:
	OCTAVE 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 4
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 4
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE G_, 6
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	SND_RET
SndDC_Ch1_5996:
	OCTAVE 3
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE E_, 2
	NOTE D_, 2
	REST 2
	NOTE F_, 6
	SND_RET
SndDC_Ch1_59A5:
	VOICE $05, 0, 8, 13, 4
	CMD_ED $C1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE C_, 6
	VIBRATO_OFF
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	VIBRATO $87, 0, 2
	NOTE C_, 6
	VIBRATO_OFF
	SND_RET
SndDC_Ch1_59CB:
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	REST 2
	ATTEN 0
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 2
	ATTEN 5
	REST 2
	ATTEN 0
	SND_RET

SndDC_Ch2:
	SND_SEGNO
	SND_CALL SndDC_Ch2_5AE2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE F_, 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE D_, 6
	VIBRATO_OFF
	NOTE D_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 1
	DUTY 8
	CMD_ED $01
	RELEASE $0D, 3
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE D_, 1
	ATTEN 0
	SND_CALL SndDC_Ch2_5AE2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	ATTEN 1
	VOICE $05, 8, 7, 11, 4
	CMD_ED $01
	LEN_UNIT 1
	OCTAVE 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 3
	ATTEN 0
	VOICE $05, 0, 9, 13, 4
	CMD_ED $C1
	SND_CALL SndDC_Ch2_5AB3
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	REST 4
	SND_CALL SndDC_Ch2_5AB3
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	VOICE $05, 8, 8, 11, 4
	CMD_ED $41
	VIBRATO $88, 0, 3
	SND_CALL SndDC_Ch2_5B09
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE B_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	SND_CALL SndDC_Ch2_5B09
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	OCTAVE 4
	NOTE F_, 4
	VIBRATO_OFF
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	VOICE $05, 0, 9, 13, 4
	CMD_ED $C1
	VIBRATO $87, 0, 2
	NOTE E_, 6
	VIBRATO_OFF
	SND_CALL SndDC_Ch2_5AD3
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 4
	VIBRATO $87, 0, 2
	NOTE E_, 6
	VIBRATO_OFF
	SND_CALL SndDC_Ch2_5AD3
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	SND_LOOP
SndDC_Ch2_5AB3:
	OCTAVE 3
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO $87, 0, 2
	NOTE C_HI, 4
	VIBRATO_OFF
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE D_, 6
	VIBRATO_OFF
	NOTE D_, 4
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE C_, 4
	SND_RET
SndDC_Ch2_5AD3:
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	NOTE A#, 4
	NOTE A#, 2
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	NOTE A_, 6
	SND_RET
SndDC_Ch2_5AE2:
	VOICE $05, 0, 8, 13, 4
	CMD_ED $C1
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE E_, 6
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	VIBRATO $87, 0, 2
	OCTAVE 4
	NOTE E_, 6
	VIBRATO_OFF
	SND_RET
SndDC_Ch2_5B09:
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 2
	ATTEN 0
	SND_RET

SndDC_Ch3:
	SND_SEGNO
	VOICE $05, 10, 2, 11, 5
	TRANSPOSE_DOWN 0
	SND_CALL SndDC_Ch3_5C42
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	SND_CALL SndDC_Ch3_5C42
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	SND_CALL SndDC_Ch3_5BE2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE E_, 2
	SND_CALL SndDC_Ch3_5BE2
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
	NOTE F_, 4
	VOICE $05, 9, 2, 11, 5
	SND_CALL SndDC_Ch3_5C0A
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 4
	SND_CALL SndDC_Ch3_5C0A
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 4
	TRANSPOSE_DOWN 0
	VOICE $05, 10, 2, 11, 5
	SND_CALL SndDC_Ch3_5C2C
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G#, 4
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 4
	SND_CALL SndDC_Ch3_5C2C
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_LOOP
SndDC_Ch3_5BE2:
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
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 4
	SND_RET
SndDC_Ch3_5C0A:
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 4
	SND_RET
SndDC_Ch3_5C2C:
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 4
	SND_RET
SndDC_Ch3_5C42:
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	SND_RET

SndDC_Drm:
	SND_SEGNO
	LEN_UNIT 5
	LOOP_START
	SND_CALL SndDC_Drm_5CC0
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	SND_CALL SndDC_Drm_5CC0
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM $0B, 2
	LOOP_END 2
	LOOP_START
	SND_CALL SndDC_Drm_5CC0
	LOOP_END 3
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 2
	LOOP_START
	SND_CALL SndDC_Drm_5CC0
	LOOP_END 2
	SND_CALL SndDC_Drm_5CC0
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 3, 2
	LOOP_END 6
	DRUM 3, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0B, 2
	LOOP_START
	SND_CALL SndDC_Drm_5CC0
	LOOP_END 7
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2
	DRUM 8, 1
	DRUM 8, 1
	SND_LOOP
SndDC_Drm_5CC0:
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	SND_RET

SndDD_Ch1:
	SND_SEGNO
	VOICE $04, 12, 7, 11, 3
	TEMPO $50
	OCTAVE 3
	REST 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 2
	NOTE F_, 1
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 2
	NOTE G_, 3
	NOTE E_, 1
	VOICE $04, 0, 8, 13, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	VOICE $04, 12, 7, 11, 3
	OCTAVE 4
	REST 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 3
	OCTAVE 3
	NOTE G_, 3
	NOTE C_HI, 2
	NOTE C_HI, 1
	REST 2
	NOTE C_HI, 4
	NOTE G_, 3
	VOICE $04, 0, 8, 13, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 2
	NOTE C_HI, 1
	VOICE $04, 12, 7, 11, 3
	REST 3
	OCTAVE 4
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, $0A
	VOICE $04, 12, 7, 11, 3
	REST 3
	OCTAVE 3
	NOTE C_HI, 3
	NOTE C_HI, 3
	NOTE C_HI, 2
	NOTE G_, 1
	NOTE C_HI, 2
	NOTE C_HI, 6
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 3
	REST 6
	REST 6
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 1
	NOTE E_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE G_, 3
	VOICE $04, 0, 8, 13, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	VOICE $04, 12, 7, 11, 3
	OCTAVE 3
	NOTE C_HI, 5
	NOTE C_HI, 1
	REST 2
	NOTE A_, 1
	NOTE A#, 2
	NOTE A_, 1
	NOTE C_HI, 3
	NOTE A#, 2
	NOTE A_, 1
	REST 2
	NOTE F_, 1
	REST 3
	OCTAVE 3
	NOTE E_, 5
	NOTE E_, 1
	REST 2
	NOTE E_, 1
	NOTE F_, 2
	NOTE E_, 1
	NOTE G_, 3
	NOTE F_, 2
	NOTE E_, 1
	REST 3
	NOTE A_, 2
	NOTE C_HI, 6
	NOTE C_HI, 1
	REST 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A#, 1
	NOTE B_, 2
	RELEASE 3, 3
	OCTAVE 4
	NOTE D_, $0D
	VOICE $04, 8, 8, 15, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	VOICE $04, 0, 9, 11, 5
	NOTE E_, 1
	NOTE F_, 2
	NOTE G_, 8
	REST 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE A_, 8
	REST 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE G_, 4
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 4
	REST 3
	NOTE C_HI, 1
	REST 1
	NOTE C_HI, 1
	REST 2
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	REST 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 1
	REST 2
	OCTAVE 3
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	RELEASE 3, 3
	NOTE G_, $0B
	VIBRATO $87, 2, 4
	OCTAVE 2
	NOTE B_, $0D
	VIBRATO_OFF
	SND_LOOP

SndDD_Ch2:
	SND_SEGNO
	VOICE $04, 12, 8, 11, 3
	OCTAVE 3
	REST 3
	NOTE C_HI, 3
	NOTE C_HI, 3
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 3
	NOTE A_, 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D#, 3
	NOTE C_, 1
	VOICE $04, 0, 8, 13, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	VOICE $04, 12, 8, 11, 4
	OCTAVE 4
	REST 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE D#, 2
	NOTE C_, 1
	NOTE D#, 3
	NOTE C_, 3
	NOTE D#, 2
	NOTE F_, 1
	REST 2
	NOTE D#, 4
	NOTE C_, 3
	VOICE $04, 0, 8, 13, 2
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	NOTE C_HI, 1
	VOICE $04, 12, 8, 11, 3
	REST 3
	OCTAVE 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 2
	NOTE D#, 1
	NOTE F_, 2
	NOTE G_, $0A
	VOICE $04, 12, 8, 11, 3
	REST 3
	OCTAVE 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE D#, 2
	NOTE C_, 1
	NOTE D#, 2
	NOTE F_, 6
	NOTE D#, 1
	NOTE F_, 2
	NOTE D#, 4
	NOTE C_, 3
	REST 6
	REST 6
	NOTE F_, 2
	NOTE F#, 1
	NOTE G_, 2
	NOTE D#, 4
	NOTE C_, 3
	VOICE $04, 0, 8, 13, 2
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	VOICE $04, 12, 8, 11, 3
	OCTAVE 4
	NOTE F_, 5
	NOTE F_, 1
	REST 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE D#, 3
	NOTE D_, 2
	NOTE C_, 1
	REST 2
	OCTAVE 3
	NOTE A_, 1
	REST 3
	OCTAVE 3
	NOTE C_HI, 5
	NOTE C_HI, 1
	REST 2
	NOTE G_, 1
	NOTE A_, 2
	NOTE G_, 1
	NOTE A#, 3
	NOTE A_, 2
	NOTE G_, 1
	REST 2
	NOTE A_, 1
	NOTE C_HI, 2
	OCTAVE 4
	NOTE F_, 6
	NOTE F_, 1
	REST 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE D#, 3
	NOTE D_, 2
	NOTE C_, 1
	REST 2
	NOTE D#, 1
	NOTE E_, 2
	RELEASE 3, 3
	NOTE G_, $0D
	VOICE $04, 8, 8, 15, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	VOICE $04, 0, 9, 11, 5
	NOTE G_, 1
	NOTE A_, 2
	NOTE C_HI, 8
	REST 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE C_HI, 8
	REST 1
	NOTE G_, 1
	NOTE A_, 2
	OCTAVE 5
	NOTE D#, 4
	NOTE D_, 1
	REST 2
	NOTE C_, 1
	REST 2
	NOTE D_, 1
	REST 1
	OCTAVE 4
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 4
	REST 3
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	REST 2
	NOTE D#, 1
	REST 2
	NOTE C_, 1
	REST 3
	NOTE G_, 2
	NOTE F_, 1
	REST 2
	NOTE D#, 1
	REST 2
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	RELEASE 3, 3
	NOTE C_, $0B
	VIBRATO $87, 2, 4
	OCTAVE 3
	NOTE G_, $0D
	VIBRATO_OFF
	SND_LOOP

SndDD_Ch3:
	SND_SEGNO
	VOICE $06, 2, 2, 11, 5
	LOOP_START
	SND_CALL SndDD_Ch3_5F77
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_CALL SndDD_Ch3_5F77
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_CALL SndDD_Ch3_5F77
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	SND_CALL SndDD_Ch3_5F77
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN_UNIT 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	REST 1
	OCTAVE 2
	NOTE C_, 4
	LEN_UNIT 6
	NOTE E_, 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE A_, 2
	NOTE F_, 4
	LEN_UNIT 6
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	LEN_UNIT 4
	NOTE D_, 2
	OCTAVE 2
	NOTE C_, 4
	LEN_UNIT 6
	NOTE E_, 2
	NOTE G_, 2
	LEN_UNIT 4
	NOTE A_, 2
	NOTE F_, 4
	LEN_UNIT 6
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN_UNIT 4
	NOTE F#, 2
	NOTE G_, 3
	OCTAVE 1
	NOTE G_, 1
	REST 2
	NOTE G_, 7
	SND_LOOP
SndDD_Ch3_5F77:
	VOICE $06, 9, 2, 11, 5
	OCTAVE 2
	NOTE C_, 2
	VOICE $06, 2, 2, 11, 5
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	SND_RET

SndDD_Drm:
	SND_SEGNO
	LEN_UNIT 4
	LOOP_START
	SND_CALL SndDD_Drm_5FC4
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 3, 3
	LOOP_END 4
	LOOP_START
	SND_CALL SndDD_Drm_5FC4
	LOOP_END 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 3, 2
	LOOP_START
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 3, 4
	DRUM 2, 2
	DRUM 2, 1
	DRUM 3, 2
	LOOP_END 3
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM 3, 4
	DRUM 2, 2
	DRUM 2, 1
	DRUM 3, 3
	DRUM 6, 3
	LOOP_START
	SND_CALL SndDD_Drm_5FC4
	LOOP_END 2
	SND_LOOP
SndDD_Drm_5FC4:
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	DRUM 1, 3
	DRUM 2, 3
	SND_RET

SndDE_Ch1:
	TEMPO $03
	VOICE $05, 0, 0, 0, 0
	REST 0
	REST 0
	REST 0
	REST 0
	SND_SEGNO
	VOICE $05, 4, 4, 3, 4
	REST 3
	DETUNE $FE
	CMD_ED $C4
	SND_CALL SndDE_Ch1_6119
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	LEN_UNIT $0A
	NOTE G_, 0
	REST 1
	LEN_UNIT 5
	SND_CALL SndDE_Ch1_6119
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	LEN_UNIT $0A
	NOTE G_, 0
	REST 1
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT 5
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 4
	NOTE F_, 2
	NOTE D#, 1
	VOICE $05, 0, 9, 11, 4
	DETUNE $00
	CMD_ED $C1
	VIBRATO $89, 0, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 3
	REST 2
	NOTE A_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A#, 4
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A#, 4
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 4
	REST 2
	VOICE $05, 4, 4, 3, 4
	DETUNE $FF
	OCTAVE 3
	NOTE A_, 6
	NOTE G_, 8
	DETUNE $00
	VIBRATO_OFF
	VOICE $05, 0, 8, 13, 3
	CMD_ED $00
	LEN_UNIT 1
	OCTAVE 3
	NOTE A#, 7
	NOTE G_, 6
	NOTE D_, 7
	NOTE A_, 7
	NOTE F_, 6
	NOTE C_, 7
	NOTE G_, 7
	NOTE D_, 6
	OCTAVE 2
	NOTE A#, 7
	OCTAVE 2
	NOTE F_, 7
	NOTE C_, 6
	OCTAVE 2
	NOTE A_, 7
	LEN_UNIT 5
	VIBRATO_OFF
	SND_LOOP

SndDE_Ch2:
	VOICE $05, 0, 8, 12, 5
	DETUNE $FD
	LOOP_START
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 4
	NOTE F#, 4
	LOOP_END 2
	DETUNE $00
	SND_SEGNO
	DETUNE $00
	VOICE $05, 4, 7, 3, 3
	CMD_ED $C4
	VIBRATO $83, 6, 15
	SND_CALL SndDE_Ch1_6119
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	LEN_UNIT $0A
	NOTE G_, 0
	REST 1
	LEN_UNIT 5
	SND_CALL SndDE_Ch1_6119
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	LEN_UNIT $0A
	NOTE G_, 0
	REST 1
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT 5
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	VOICE $05, 0, 9, 11, 5
	CMD_ED $C1
	VIBRATO $89, 0, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 4
	VOICE $05, 4, 8, 3, 3
	VIBRATO $83, 6, 15
	OCTAVE 3
	NOTE A_, 6
	NOTE G_, $0A
	VIBRATO_OFF
	VOICE $05, 0, 8, 13, 3
	CMD_ED $00
	LEN_UNIT 1
	OCTAVE 4
	NOTE D_, 7
	OCTAVE 3
	NOTE A#, 6
	NOTE G_, 7
	OCTAVE 4
	NOTE C_, 7
	OCTAVE 3
	NOTE A_, 6
	NOTE F_, 7
	NOTE A#, 7
	NOTE G_, 6
	NOTE D_, 7
	NOTE A_, 7
	NOTE F_, 6
	NOTE C_, 7
	LEN_UNIT 5
	SND_LOOP
SndDE_Ch1_6119:
	OCTAVE 3
	NOTE D_, 6
	LEN_UNIT $0A
	NOTE G_, 9
	LEN_UNIT 5
	NOTE F#, 4
	NOTE D_, 2
	LEN_UNIT $0A
	NOTE F_, $0E
	LEN_UNIT 5
	NOTE E_, 2
	NOTE D#, 2
	NOTE C_, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, $0A
	SND_RET

SndDE_Ch3:
	VOICE $05, 9, 2, 11, 4
	LOOP_START
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 4
	NOTE F#, 4
	LOOP_END 2
	SND_SEGNO
	LOOP_START
	VOICE $05, 2, 2, 11, 5
	OCTAVE 2
	NOTE G_, 4
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 4
	NOTE F#, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE A#, 2
	NOTE C_HI, 6
	OCTAVE 3
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 4
	NOTE E_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE D#, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 6
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE B_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 4
	NOTE F#, 4
	LOOP_END 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	VOICE $05, 1, 2, 11, 4
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D#, 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	SND_LOOP

SndDE_Drm:
	LEN_UNIT 5
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	LOOP_END 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 4
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 6, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	LEN_UNIT 5
	LOOP_START
	LOOP2_START
	SND_CALL SndDE_Drm_623D
	LOOP2_END 3
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 3, 2
	LOOP_END 3
	LOOP_START
	SND_CALL SndDE_Drm_623D
	LOOP_END 3
	DRUM 3, 4
	DRUM 9, 2
	DRUM 1, 2
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_START
	SND_CALL SndDE_Drm_623D
	LOOP_END 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 3, 4
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 2
	SND_CALL SndDE_Drm_623D
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2
	DRUM 8, 2
	SND_LOOP
SndDE_Drm_623D:
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	SND_RET

SndED_Ch1:
	LEN_UNIT 1
	TRANSPOSE_UP $0F
	SND_CALL SndDF_Ch1_6265

SndDF_Ch1:
	VOICE $01, 8, 13, 0, 0
	OCTAVE 1
	SND_CALL SndDF_Ch1_6286
	ATTEN 4
	OCTAVE 2
	SND_CALL SndDF_Ch1_6286
	ATTEN 7
	OCTAVE 3
	SND_CALL SndDF_Ch1_6286
	VOLUME $03
	OCTAVE 4
	SND_CALL SndDF_Ch1_6286
SndDF_Ch1_6265:
	SND_SEGNO
	VOICE $01, 8, 8, 0, 0
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
	ATTEN 5
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
	SND_LOOP
SndDF_Ch1_6286:
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
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
	NOTE B_, 1
	SND_RET

SndED_Ch2:
	LEN_UNIT 1
	TRANSPOSE_UP $0F
	SND_CALL SndDF_Ch2_62C0

SndDF_Ch2:
	VOICE $01, 8, 13, 0, 0
	DETUNE $F0
	OCTAVE 1
	SND_CALL SndDF_Ch1_6286
	VOICE $01, 8, 9, 0, 0
	OCTAVE 2
	SND_CALL SndDF_Ch1_6286
	VOICE $01, 8, 6, 0, 0
	OCTAVE 3
	SND_CALL SndDF_Ch1_6286
	VOICE $01, 8, 3, 0, 0
	OCTAVE 4
	SND_CALL SndDF_Ch1_6286
SndDF_Ch2_62C0:
	LOOP_START
	VOICE $01, 8, 6, 0, 0
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
	ATTEN 4
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
	LOOP_END 4
	VOICE $04, 0, 8, 10, 5
	TRANSPOSE_UP 0
	DETUNE $FD
	OCTAVE 2
	NOTE F_, 3
	NOTE C_HI, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE A#, 3
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE C#, 2
	AUTOPAN_L 0
	SND_SEGNO
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C#, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE F#, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C#, 4
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE C#, 2
	SND_LOOP

SndDF_Ch3:
	LEN_UNIT 4
	REST 0

SndED_Ch3:
	LEN_UNIT 1
	REST 0
	REST 0
	REST 0
	REST 0
	REST 0
	REST 0
	VOICE $04, 8, 2, 10, 4
	OCTAVE 2
	NOTE F_, 3
	NOTE C_HI, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE A#, 3
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE C#, 2
	SND_SEGNO
	VOICE $04, 8, 2, 10, 4
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C#, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE F#, 4
	LOOP_END 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	OCTAVE 2
	NOTE C#, 4
	LOOP_END 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE C#, 2
	SND_LOOP

SndDF_Drm:
	LEN_UNIT 4
	DRUM $0C, 0

SndED_Drm:
	LEN_UNIT 1
	REST 0
	REST 0
	REST 0
	REST 0
	REST 0
	REST 0
	LEN_UNIT 4
	DRUM 6, 3
	DRUM 7, 3
	DRUM 8, 3
	DRUM 6, 3
	DRUM 7, 3
	DRUM 8, 3
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_SEGNO
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 3, 4
	LOOP_END 6
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 4
	LOOP_END 3
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 6, 4
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 7, 4
	DRUM 6, 2
	DRUM 7, 2
	SND_LOOP

SndE0_Ch1:
	VOICE $05, 0, 8, 13, 4
	REST 6
	OCTAVE 2
	NOTE C_, 4
	SND_SEGNO
	VIBRATO $87, 3, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 4
	REST 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 4
	REST 2
	OCTAVE 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 4
	REST 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 4
	REST 2
	OCTAVE 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	NOTE C_HI, 4
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE F_, 2
	REST 2
	NOTE D#, 2
	VOICE $05, 4, 7, 13, 4
	CMD_ED $01
	VIBRATO $8A, 0, 2
	LOOP_START
	REST 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 4
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A#, 4
	NOTE G_, 2
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A#, 6
	LOOP_END 2
	REST 4
	OCTAVE 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE F_, 6
	NOTE F_, 4
	NOTE D_, 4
	REST 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE E_, 2
	REST 4
	OCTAVE 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE F_, 6
	NOTE F_, 4
	NOTE D_, 4
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE D#, 2
	VOICE $05, 0, 7, 13, 4
	OCTAVE 2
	NOTE C_, 4
	SND_LOOP

SndE0_Ch2:
	VOICE $05, 0, 7, 13, 3
	REST 6
	VOICE $05, 0, 7, 13, 4
	OCTAVE 3
	NOTE F_, 4
	SND_SEGNO
	VIBRATO $87, 3, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 4
	REST 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G#, 4
	REST 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 4
	REST 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G#, 4
	REST 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE C_HI, 2
	REST 2
	NOTE B_, 2
	REST 2
	NOTE A#, 2
	REST 2
	NOTE G#, 2
	VOICE $05, 4, 7, 13, 4
	CMD_ED $01
	VIBRATO $8A, 0, 2
	LOOP_START
	REST 2
	OCTAVE 5
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE D#, 4
	NOTE C_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE D#, 6
	LOOP_END 2
	VIBRATO_OFF
	VOICE $05, 0, 8, 13, 4
	CMD_ED $00
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	VOICE $05, 4, 7, 13, 4
	CMD_ED $01
	OCTAVE 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE F_, 2
	NOTE D_, 4
	NOTE A#, 6
	NOTE A_, 4
	NOTE F_, 4
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	VOICE $05, 0, 8, 13, 4
	CMD_ED $00
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE F_, 1
	VOICE $05, 4, 7, 13, 4
	CMD_ED $01
	OCTAVE 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE F_, 2
	NOTE D_, 4
	NOTE A#, 6
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	VOICE $05, 0, 7, 13, 4
	NOTE F_, 4
	SND_LOOP

SndE0_Ch3:
	VOICE $05, 9, 2, 12, 5
	REST 6
	VOICE $05, 9, 2, 12, 5
	OCTAVE 2
	NOTE D_, 4
	SND_SEGNO
	VOICE $05, 9, 2, 12, 5
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE C_HI, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE C_, 2
	LOOP_END 2
	LOOP_START
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	LOOP_END 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE F_, 4
	SND_LOOP

SndE0_Drm:
	LEN_UNIT 5
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 3, 2
	SND_SEGNO
	LOOP2_START
	LOOP_START
	SND_CALL SndE0_Drm_6681
	SND_CALL SndE0_Drm_6681
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 3, 2
	LOOP_END 3
	SND_CALL SndE0_Drm_6681
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM $0B, 2
	LOOP2_END 2
	LOOP_START
	SND_CALL SndE0_Drm_6681
	LOOP_END 6
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 3, 2
	SND_LOOP
SndE0_Drm_6681:
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	SND_RET

SndE1_Ch1:
	SND_SEGNO
	TEMPO $05
	VOICE $05, 0, 5, 13, 2
	REST 3
	DETUNE $FD
	AUTOPAN_R 0
	OCTAVE 3
	LOOP_START
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	LOOP_END 3
	NOTE B_, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	VOICE $05, 8, 5, 3, 3
	NOTE G_, $0C
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 6
	OCTAVE 2
	NOTE G_, 4
	NOTE C_HI, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE G#, 4
	NOTE C#, 4
	NOTE A#, 1
	AUTOPAN_OFF 0
	VOICE $05, 8, 7, 3, 3
	DETUNE $00
	NOTE D#, $0C
	NOTE C#, $0C
	NOTE C#, $0C
	NOTE C#, $0C
	DETUNE $FD
	AUTOPAN_R 0
	VOICE $05, 12, 4, 3, 3
	REST 2
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE A#, 8
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE C#, 6
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE G#, 4
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE F_, 4
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE G#, 4
	NOTE C#, 4
	NOTE G#, 4
	SND_CALL SndE1_Ch1_66FF
	NOTE G#, 2
	SND_CALL SndE1_Ch1_66FF
	SND_LOOP
SndE1_Ch1_66FF:
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D#, 2
	SND_RET

SndE1_Ch2:
	SND_SEGNO
	VOICE $05, 0, 8, 13, 1
	OCTAVE 3
	LOOP_START
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_, 2
	LOOP_END 3
	NOTE B_, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE B_, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D#, 2
	VOICE $05, 8, 8, 8, 3
	VIBRATO $83, 4, 10
	NOTE G_, $0C
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 6
	OCTAVE 2
	NOTE G_, 4
	NOTE C_HI, 4
	OCTAVE 3
	NOTE G_, 4
	NOTE G#, 4
	NOTE C#, 4
	NOTE A#, 4
	VOICE $05, 8, 6, 5, 4
	NOTE G_, $0C
	NOTE F#, $0C
	NOTE G_, $0C
	NOTE G#, $0C
	VOICE $05, 0, 8, 4, 3
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE A#, 8
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE F_, 2
	NOTE C#, 6
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C#, 4
	NOTE G#, 4
	OCTAVE 2
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE C#, 4
	OCTAVE 2
	NOTE A#, 4
	NOTE F_, 4
	NOTE G_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE G#, 4
	NOTE C#, 4
	NOTE G#, 4
	VIBRATO_OFF
	SND_CALL SndE1_Ch1_66FF
	NOTE G#, 2
	SND_CALL SndE1_Ch1_66FF
	NOTE G#, 2
	SND_LOOP

SndE1_Ch3:
	SND_SEGNO
	VOICE $0A, 2, 2, 2, 13
	VIBRATO $83, 0, 15
	OCTAVE 2
	NOTE C_, $0C
	NOTE D#, $0C
	NOTE F_, $0C
	NOTE G#, $0C
	VIBRATO_OFF
	VOICE $05, 9, 2, 10, 3
	SND_CALL SndE1_Ch3_67DB
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G#, 2
	NOTE C_HI, 2
	SND_CALL SndE1_Ch3_67DB
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE D#, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE D#, 2
	LOOP_END 2
	SND_LOOP
SndE1_Ch3_67DB:
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	SND_RET

SndE1_Drm:
	LEN_UNIT 5
	SND_SEGNO
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	LOOP_END 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 3, 2
	SND_LOOP

SndE2_Ch1:
	VOICE $03, 0, 4, 10, 2
	REST 2
	CMD_ED $41
	DETUNE $FF
	SND_SEGNO
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	SND_CALL SndE2_Ch1_68CA
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D#, 1
	SND_LOOP

SndE2_Ch2:
	VOICE $03, 0, 7, 13, 3
	CMD_ED $41
	SND_SEGNO
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	SND_CALL SndE2_Ch1_68CA
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	LOOP_START
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE C_HI, 1
	LOOP_END 2
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch1_68CA
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D#, 1
	SND_LOOP
SndE2_Ch1_68CA:
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	LOOP_END 2
	SND_RET

SndE2_Ch3:
	SND_SEGNO
	VIBRATO $83, 0, 15
	TRANSPOSE_UP 0
	SND_CALL SndE2_Ch3_68E7
	TRANSPOSE_UP 3
	SND_CALL SndE2_Ch3_68E7
	SND_LOOP
SndE2_Ch3_68E7:
	LOOP_START
	VOICE $03, 8, 2, 10, 5
	OCTAVE 2
	NOTE C_, 4
	NOTE D#, 4
	VOICE $03, 8, 4, 0, 0
	NOTE D#, 8
	VOICE $03, 8, 2, 10, 5
	OCTAVE 2
	NOTE C_, 4
	NOTE F#, 4
	VOICE $03, 8, 4, 0, 0
	NOTE F#, 8
	LOOP_END 2
	SND_RET

SndE2_Drm:
	LEN_UNIT 3
	SND_SEGNO
	LOOP_START
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	LOOP_END 3
	DRUM $0B, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	SND_LOOP

SndE3_Ch1:
	TEMPO $18
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	VOICE $04, 0, 8, 13, 4
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_END 2
	LOOP_START
	VOICE $04, 0, 8, 11, 3
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 6
	VOICE $04, 0, 8, 11, 3
	DETUNE $FD
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D_, 1
	DETUNE $00
	LOOP_END 2
	DETUNE $FD
	LEN_UNIT 4
	REST 2
	VOICE $02, 4, 6, 0, 0
	SND_CALL SndE3_Ch1_6A96
	NOTE G_, 2
	NOTE A_, 2
	DETUNE $00
	VOICE $04, 8, 5, 0, 0
	SND_CALL SndE3_Ch1_6AAA
	NOTE D_, 2
	NOTE D#, 2
	DETUNE $FD
	VOICE $02, 4, 6, 0, 0
	SND_CALL SndE3_Ch1_6A96
	NOTE G_, 2
	DETUNE $00
	VOICE $04, 0, 8, 13, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE G#, 1
	SND_LOOP

SndE3_Ch2:
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	VOICE $04, 0, 8, 13, 4
	LOOP_START
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 2
	LOOP_END 2
	VOICE $04, 0, 8, 11, 3
	LOOP_START
	OCTAVE 4
	NOTE C_HI, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	LOOP_END 2
	VOICE $02, 4, 9, 11, 4
	SND_CALL SndE3_Ch1_6A96
	NOTE G_, 2
	NOTE A_, 2
	VOICE $04, 8, 8, 13, 1
	SND_CALL SndE3_Ch1_6AAA
	NOTE D_, 2
	NOTE D#, 2
	VOICE $02, 4, 9, 11, 4
	SND_CALL SndE3_Ch1_6A96
	NOTE G_, 2
	NOTE A_, 2
	VOICE $04, 0, 8, 13, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 2
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	SND_LOOP
SndE3_Ch1_6A96:
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	LEN_UNIT 4
	NOTE G#, 1
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 6
	SND_RET
SndE3_Ch1_6AAA:
	REST 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C_, 2
	SND_RET

SndE3_Ch3:
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	VOICE $04, 8, 2, 11, 4
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	LOOP_END 4
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	NOTE G_, 4
	NOTE G_, 4
	LOOP_END 2
	LOOP_START
	NOTE F_, 2
	LOOP_END $0A
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	LOOP_START
	NOTE A_, 2
	LOOP_END $0A
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_START
	NOTE F_, 2
	LOOP_END $0A
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_HI, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
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
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	SND_LOOP

SndE3_Drm:
	LEN_UNIT 4
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 8, 2
	SND_SEGNO
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_END 2
	LOOP_START
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_END 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 7
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	SND_LOOP

SndE5_Ch1:
	TEMPO $20
	LEN_UNIT 4
	REST 8

SndE4_Ch1:
	TRANSPOSE_DOWN 2
	TEMPO $20
	SND_SEGNO
	VOICE $04, 0, 9, 10, 4
	SND_CALL SndE4_Ch1_6CA6
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	ATTEN 4
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 6
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 7
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 0
	SND_CALL SndE4_Ch1_6CA6
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 6
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 0
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE A_, 2
	REST 2
	REST 2
	VOICE $04, 0, 8, 11, 3
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	CMD_ED $41
	SND_CALL SndE4_Ch1_6CBB
	OCTAVE 3
	NOTE B_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	SND_CALL SndE4_Ch1_6CBB
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	CMD_ED $81
	VOICE $04, 12, 7, 10, 6
	VIBRATO $83, 4, 4
	OCTAVE 4
	NOTE D_, 0
	NOTE C#, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE B_, $0E
	CMD_ED $01
	VOICE $04, 12, 8, 11, 5
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	CMD_ED $81
	VOICE $04, 12, 7, 10, 6
	VIBRATO $83, 4, 4
	OCTAVE 4
	NOTE G_, 0
	NOTE G_, 8
	NOTE F_, 8
	OCTAVE 3
	NOTE B_, $0E
	CMD_ED $00
	VOICE $04, 12, 8, 10, 6
	VIBRATO_OFF
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	NOTE F#, 2
	REST 2
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, $0A
	NOTE E_, 2
	NOTE C_, 4
	NOTE F#, 0
	NOTE E_, $0A
	NOTE E_, 2
	NOTE C_, 4
	VOICE $04, 12, 8, 11, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	LEN_UNIT 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 6
	LEN_UNIT 4
	RELEASE $0A, 6
	NOTE A_, 6
	VOICE $04, 12, 8, 10, 5
	CMD_ED $01
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE G#, 4
	NOTE F#, 2
	LOOP_END 3
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 0
	CMD_ED $00
	SND_LOOP
SndE4_Ch1_6CA6:
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 3
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 5
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 6
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 7
	NOTE A_, 2
	NOTE B_, 2
	ATTEN 0
	SND_RET
SndE4_Ch1_6CBB:
	OCTAVE 3
	NOTE G#, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	NOTE E_, 2
	REST 2
	NOTE B_, 4
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE B_, 2
	REST 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	NOTE D_, 6
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE E_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	SND_RET

SndE5_Ch2:
	LEN_UNIT 4
	REST 8

SndE4_Ch2:
	TRANSPOSE_DOWN 2
	SND_SEGNO
	VOICE $04, 0, 9, 10, 4
	SND_CALL SndE4_Ch2_6DD8
	OCTAVE 4
	NOTE E_, 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 4
	ATTEN 4
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 5
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 6
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 7
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 0
	SND_CALL SndE4_Ch2_6DD8
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 6
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	REST 2
	VOICE $04, 0, 8, 11, 3
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	CMD_ED $41
	SND_CALL SndE4_Ch2_6DED
	OCTAVE 4
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	REST 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	NOTE A#, 2
	SND_CALL SndE4_Ch2_6DED
	OCTAVE 5
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	CMD_ED $81
	VOICE $04, 12, 7, 10, 6
	VIBRATO $83, 4, 4
	OCTAVE 4
	NOTE G_, 0
	NOTE F#, 8
	NOTE F_, 8
	NOTE E_, $0E
	CMD_ED $00
	VOICE $04, 12, 8, 11, 5
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	CMD_ED $81
	VOICE $04, 12, 7, 10, 6
	VIBRATO $83, 4, 4
	OCTAVE 4
	NOTE B_, 0
	NOTE A#, 8
	NOTE A_, 8
	NOTE E_, $0E
	CMD_ED $81
	VOICE $04, 12, 8, 10, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	NOTE B_, 2
	REST 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 4
	NOTE A_, $0A
	NOTE G_, 2
	NOTE E_, 4
	NOTE B_, 0
	OCTAVE 4
	NOTE A_, $0A
	NOTE G_, 2
	NOTE E_, 4
	VOICE $04, 12, 8, 11, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN_UNIT 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 6
	LEN_UNIT 4
	RELEASE $0A, 6
	OCTAVE 5
	NOTE D_, 6
	VOICE $04, 12, 8, 10, 5
	CMD_ED $01
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	LOOP_END 3
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 0
	CMD_ED $00
	SND_LOOP
SndE4_Ch2_6DD8:
	OCTAVE 4
	NOTE E_, 8
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 3
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 5
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 6
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 7
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 0
	SND_RET
SndE4_Ch2_6DED:
	OCTAVE 3
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE E_, 4
	NOTE G_, 6
	NOTE E_, 6
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE A_, 2
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 4
	SND_RET

SndE5_Ch3:
	LEN_UNIT 4
	REST 8

SndE4_Ch3:
	TRANSPOSE_DOWN 2
	SND_SEGNO
	VOICE $04, 9, 2, 11, 5
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP_END 3
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	LOOP_END 3
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END 3
	OCTAVE 3
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	VOICE $04, 9, 6, 0, 0
	NOTE E_, 4
	VOICE $04, 9, 2, 11, 4
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 2
	RELEASE 0, 0
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	VOICE $04, 9, 2, 12, 6
	SND_CALL SndE4_Ch3_6F5F
	RELEASE $0B, 5
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VOICE $04, 9, 2, 12, 6
	SND_CALL SndE4_Ch3_6F5F
	RELEASE $0B, 5
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	VOICE $04, 8, 2, 11, 5
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	VOICE $04, 9, 2, 12, 6
	SND_CALL SndE4_Ch3_6F94
	RELEASE $0B, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	RELEASE $0C, 6
	NOTE D_, 4
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	SND_CALL SndE4_Ch3_6F94
	RELEASE $0B, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	RELEASE $0C, 6
	NOTE D_, 4
	NOTE E_, 2
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_HI, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	VOICE $04, 9, 4, 0, 0
	NOTE D_, 4
	VOICE $04, 8, 2, 10, 5
	LOOP_START
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 2
	NOTE B_, 2
	LOOP_END 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	VOICE $04, 8, 2, 0, 0
	OCTAVE 3
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	SND_LOOP
SndE4_Ch3_6F5F:
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_RET
SndE4_Ch3_6F94:
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	SND_RET

SndE5_Drm:
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM $0B, 2

SndE4_Drm:
	SND_SEGNO
	LEN_UNIT 4
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 6
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0A, 8
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_CALL SndE4_Drm_702E
	DRUM 5, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_CALL SndE4_Drm_702E
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 9, 4
	DRUM 5, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 2, 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 2, 2
	LOOP_END 7
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 6, 1
	DRUM 7, 1
	DRUM 2, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 2, 2
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM 8, 2
	LOOP_START
	DRUM 5, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 3, 4
	DRUM $0B, 2
	DRUM 2, 2
	LOOP_END 3
	DRUM $0B, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0A, 8
	SND_LOOP
SndE4_Drm_702E:
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 2, 2
	LOOP_END 3
	SND_RET

SndE6_Sfx1:
	VOICE $10, 4, 6, 13, 3
	REST $0C
	REST 6
	VIBRATO $82, 0, 4
	LOOP_START
	OCTAVE 1
	NOTE F_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE A_, 6
	NOTE A#, 6
	NOTE B_, 4
	NOTE C_HI, 6
	NOTE C_HI, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE C_, 2
	LOOP_END 2
	SND_SEGNO
	LOOP_START
	OCTAVE 1
	NOTE F_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE A_, 6
	NOTE A#, 6
	NOTE B_, 4
	NOTE C_HI, 6
	NOTE C_HI, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE C_, 2
	LOOP_END 4
	OCTAVE 1
	NOTE A#, 6
	NOTE A#, 6
	OCTAVE 2
	NOTE D_, 6
	NOTE D#, 4
	NOTE F_, 2
	NOTE C_, 6
	NOTE C_, 6
	NOTE E_, 6
	NOTE F_, 4
	NOTE G_, 2
	OCTAVE 1
	NOTE F_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE A_, 6
	NOTE A#, 6
	NOTE B_, 4
	NOTE C_HI, 6
	NOTE C_HI, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE C_, 2
	SND_LOOP

SndE6_Sfx2:
	VOICE $10, 5, 4, 11, 3
	REST $0C
	REST 6
	LOOP_START
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END $2D
	VOICE $10, 13, 4, 11, 3
	VIBRATO $8E, 0, 4
	OCTAVE 3
	REST 4
	NOTE G#, 2
	SND_SEGNO
	NOTE A_, 4
	NOTE C_HI, 2
	REST 6
	NOTE C_HI, 2
	REST 8
	NOTE A_, 2
	NOTE C_HI, 2
	REST 8
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 4
	NOTE D_, 2
	REST 4
	NOTE C_, 2
	OCTAVE 3
	REST 4
	NOTE F_, 2
	REST 6
	OCTAVE 4
	NOTE F_, 2
	REST 8
	NOTE G#, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	REST 4
	OCTAVE 4
	NOTE F_, 2
	REST 6
	NOTE F_, 2
	REST 8
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 4
	NOTE C_HI, 2
	REST 4
	OCTAVE 4
	NOTE D#, 6
	NOTE D_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	REST 4
	NOTE F_, 2
	REST 6
	NOTE F_, 2
	REST 8
	NOTE G#, 2
	NOTE A_, 2
	NOTE C_HI, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G#, 6
	NOTE F_, 6
	NOTE G#, 4
	NOTE F_, 2
	REST 4
	NOTE G#, 6
	NOTE G_, 2
	NOTE F_, 4
	NOTE G#, 2
	REST 4
	NOTE F_, 2
	REST 4
	VOICE $10, 5, 2, 11, 3
	OCTAVE 4
	NOTE F_, 2
	VOICE $10, 5, 4, 0, 0
	OCTAVE 4
	NOTE F_, 4
	VOICE $10, 5, 2, 11, 3
	NOTE F_, 2
	OCTAVE 5
	NOTE F_, 2
	VOICE $10, 5, 4, 0, 0
	NOTE F_, 4
	VOICE $10, 5, 2, 11, 3
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 5
	NOTE F_, 2
	VOICE $10, 5, 4, 0, 0
	NOTE F_, 4
	VOICE $10, 5, 2, 11, 3
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 5
	NOTE F_, 2
	VOICE $10, 5, 4, 0, 0
	NOTE F_, 4
	VOICE $10, 5, 2, 11, 3
	OCTAVE 4
	NOTE F_, 4
	OCTAVE 5
	NOTE F_, 2
	VOICE $10, 5, 4, 0, 0
	NOTE F_, 4
	VOICE $10, 5, 2, 11, 3
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 5
	NOTE F_, 4
	VOICE $10, 13, 4, 11, 3
	OCTAVE 3
	NOTE G#, 2
	SND_LOOP

SndE6_SfxN:
	LOOP_START
	NVOICE $60, $00
	NOISE_REST
	LOOP_END 3
	SND_SEGNO
	NVOICE $10, $33
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $13
	NOISE $03
	NVOICE $10, $61
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $13
	NOISE $03
	SND_LOOP

SndE7_Ch1:
	TEMPO $08
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	VOICE $04, 0, 8, 13, 3
	SND_CALL SndE7_Ch1_71C7
	VOICE $04, 0, 9, 11, 2
	REST 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	NOTE C#, 2
	NOTE C#, 2
	REST 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A#, 4
	VOICE $04, 0, 8, 13, 3
	SND_CALL SndE7_Ch1_71C7
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	LOOP_END 2
	OCTAVE 4
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	VOICE $04, 0, 6, 10, 3
	REST 3
	VIBRATO $84, 0, 1
	SND_CALL SndE7_Ch1_7274
	VIBRATO_OFF
	SND_LOOP
SndE7_Ch1_71C7:
	OCTAVE 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE G_, 4
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 4
	SND_RET

SndE7_Ch2:
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	VOICE $04, 0, 8, 13, 3
	SND_CALL SndE7_Ch2_724F
	VOICE $04, 0, 9, 11, 2
	REST 2
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE F#, 2
	NOTE F#, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	REST 2
	NOTE E_, 4
	NOTE D#, 4
	VOICE $04, 0, 8, 13, 3
	SND_CALL SndE7_Ch2_724F
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	LOOP_END 2
	LOOP_START
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	LOOP_END 2
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 2
	SND_CALL SndE7_Ch1_7274
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	SND_LOOP
SndE7_Ch2_724F:
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE F#, 4
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	SND_RET
SndE7_Ch1_7274:
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	SND_RET

SndE7_Ch3:
	LEN_UNIT 4
	REST 8
	SND_SEGNO
	SND_CALL SndE7_Ch3_72C7
	VOICE $04, 9, 2, 11, 4
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE F_, 2
	SND_CALL SndE7_Ch3_72C7
	RELEASE 3, 4
	NOTE G_, $0C
	NOTE G#, $0C
	NOTE G_, $0C
	NOTE G#, $0C
	RELEASE 2, 4
	LEN_UNIT 8
	NOTE C_, $0C
	NOTE D#, $0C
	NOTE F_, $0C
	LEN_UNIT 4
	NOTE F#, $0C
	NOTE G_, $0C
	SND_LOOP
SndE7_Ch3_72C7:
	VOICE $04, 9, 2, 11, 5
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE G_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 4
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	SND_RET

SndE7_Drm:
	LEN_UNIT 4
	DRUM $0B, 2
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 2
	DRUM 8, 2
	SND_SEGNO
	LEN_UNIT 4
	SND_CALL SndE7_Drm_7342
	DRUM $0A, 6
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM $0A, 4
	SND_CALL SndE7_Drm_7342
	DRUM $0A, 4
	DRUM 8, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 3, 2
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 3, 2
	LOOP_END 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 3, 4
	DRUM 2, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 6, 1
	DRUM 6, 1
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 8, 1
	SND_LOOP
SndE7_Drm_7342:
	LOOP_START
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 3, 4
	LOOP_END 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	SND_RET

SndE8_Ch1:
	VOICE $04, 0, 6, 11, 3
	REST 1
	TEMPO $18
	REST $0C
	OCTAVE 4
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_SEGNO
	TRANSPOSE_UP 0
	SND_CALL SndE8_Ch1_737B
	TRANSPOSE_UP 2
	SND_CALL SndE8_Ch1_737B
	SND_LOOP
SndE8_Ch1_737B:
	VOICE $08, 0, 8, 13, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	VOICE $04, 0, 6, 11, 3
	REST 1
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	SND_RET

SndE8_Ch2:
	VOICE $04, 0, 8, 13, 4
	REST $0C
	OCTAVE 4
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_SEGNO
	TRANSPOSE_UP 0
	SND_CALL SndE8_Ch2_7446
	TRANSPOSE_UP 2
	SND_CALL SndE8_Ch2_7446
	SND_LOOP
SndE8_Ch2_7446:
	VOICE $08, 0, 8, 13, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT 4
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_, 1
	LOOP_END 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	SND_RET

SndE8_Ch3:
	VOICE $08, 9, 2, 11, 5
	REST 6
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_SEGNO
	TRANSPOSE_UP 0
	SND_CALL SndE8_Ch3_7515
	TRANSPOSE_UP 2
	SND_CALL SndE8_Ch3_7515
	SND_LOOP
SndE8_Ch3_7515:
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_RET

SndE8_Drm:
	LEN_UNIT 4
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 6, 1
	DRUM 7, 1
	DRUM 7, 2
	DRUM 8, 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	REST 2
	DRUM 2, 2
	REST 2
	LEN_UNIT 8
	SND_SEGNO
	LOOP_START
	DRUM 5, 2
	DRUM 1, 1
	DRUM 9, 2
	DRUM 5, 1
	DRUM 5, 2
	DRUM 1, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END 8
	LOOP_START
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	LOOP_END 3
	LEN_UNIT 4
	DRUM 7, 1
	DRUM 8, 1
	DRUM 2, 2
	DRUM 1, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 2, 2
	DRUM 1, 2
	LEN_UNIT 8
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0B, 1
	SND_LOOP

SndE9_Ch1:
	VOICE $02, 0, 15, 0, 0
	REST 8
	DETUNE $FD
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 4
	VOLUME $05
	NOTE C_HI, 0
	DETUNE $00
	LEN_UNIT 6
	REST 6
	SND_SEGNO
	VOICE $06, 4, 9, 12, 3
	OCTAVE 3
	TEMPO $20
	CMD_ED $01
	SND_CALL SndE9_Ch1_769D
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_CALL SndE9_Ch1_76B2
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	SND_CALL SndE9_Ch1_769D
	ATTEN 0
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	DUTY 0
	CMD_ED $C1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	DUTY 4
	CMD_ED $01
	SND_CALL SndE9_Ch1_76B2
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 7
	NOTE A#, 1
	ATTEN 1
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 2
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 5
	NOTE A#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE G#, 1
	SND_CALL SndE9_Ch1_76B2
	ATTEN 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	DUTY 0
	CMD_ED $C1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	DUTY 4
	CMD_ED $01
	SND_LOOP
SndE9_Ch1_769D:
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 0
	ATTEN 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 3
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	SND_RET
SndE9_Ch1_76B2:
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 7
	NOTE G_, 1
	ATTEN 0
	ATTEN 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 2
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 3
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	SND_RET

SndE9_Ch2:
	VOICE $02, 0, 15, 0, 0
	REST 8
	DETUNE $FE
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 4
	VOLUME $05
	NOTE C_HI, 0
	DETUNE $00
	LEN_UNIT 6
	REST 6
	SND_SEGNO
	VOICE $06, 4, 9, 12, 3
	OCTAVE 3
	CMD_ED $01
	SND_CALL SndE9_Ch2_7765
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_CALL SndE9_Ch2_7779
	ATTEN 0
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	SND_CALL SndE9_Ch2_7765
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C_, 1
	DUTY 0
	CMD_ED $C1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	DUTY 4
	CMD_ED $01
	SND_CALL SndE9_Ch2_7779
	ATTEN 0
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	ATTEN 7
	NOTE D#, 1
	ATTEN 1
	NOTE C#, 1
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 2
	NOTE C#, 1
	NOTE D#, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 3
	NOTE C#, 1
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_CALL SndE9_Ch2_7779
	ATTEN 0
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE E_, 1
	DUTY 0
	CMD_ED $C1
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	DUTY 4
	CMD_ED $01
	SND_LOOP
SndE9_Ch2_7765:
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 7
	NOTE A_, 1
	ATTEN 1
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 3
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	SND_RET
SndE9_Ch2_7779:
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 7
	NOTE C_HI, 1
	ATTEN 1
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 6
	NOTE C_HI, 1
	ATTEN 2
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 5
	NOTE C_HI, 1
	ATTEN 3
	NOTE A#, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_HI, 1
	SND_RET

SndE9_Ch3:
	VOICE $02, 8, 2, 0, 0
	REST 8
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 4
	VOICE $02, 8, 6, 0, 0
	NOTE C_HI, 0
	LEN_UNIT 6
	REST 6
	SND_SEGNO
	VOICE $06, 8, 2, 13, 2
	SND_CALL SndE9_Ch3_781D
	SND_CALL SndE9_Ch3_7831
	NOTE B_, 1
	NOTE A#, 1
	SND_CALL SndE9_Ch3_781D
	VOICE $06, 12, 2, 13, 3
	TRANSPOSE_UP $0C
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE C#, 1
	VOICE $06, 8, 2, 13, 2
	TRANSPOSE_UP 0
	SND_CALL SndE9_Ch3_7831
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	SND_CALL SndE9_Ch3_7831
	NOTE A#, 1
	NOTE C_HI, 1
	VOICE $06, 12, 2, 13, 3
	TRANSPOSE_UP $0C
	OCTAVE 2
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D#, 1
	TRANSPOSE_UP 0
	SND_LOOP
SndE9_Ch3_781D:
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_RET
SndE9_Ch3_7831:
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE C_HI, 1
	SND_RET

SndE9_Drm:
	LEN_UNIT 2
	REST 8
	LEN_UNIT 4
	DRUM $0A, 0
	LEN_UNIT 3
	DRUM 6, 1
	DRUM 6, 1
	DRUM 6, 2
	LEN_UNIT 6
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	SND_SEGNO
	LOOP_START
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 9, 2
	LOOP_END 3
	DRUM 5, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	LOOP_END 2
	DRUM $0B, 1
	LOOP_START
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 9, 1
	LOOP_END 2
	SND_LOOP

SndEA_Ch1:
	VOICE $03, 0, 7, 13, 3
	VIBRATO $84, 0, 5
	REST 3
	AUTOPAN_R 0
	SND_CALL SndEA_Ch1_78F8
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE A_, 1
	SND_SEGNO
	VOICE $06, 0, 7, 13, 3
	VIBRATO $84, 0, 3
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C#, 1
	LOOP_END 4
	LOOP2_END 2
	PAN_BOTH 0
	VOICE $06, 0, 10, 13, 3
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
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
	AUTOPAN_R 0
	VOICE $06, 0, 7, 13, 3
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP2_END 2
	SND_LOOP
SndEA_Ch1_78F8:
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE A_, 1
	SND_RET

SndEA_Ch2:
	VOICE $03, 0, 7, 13, 3
	SND_CALL SndEA_Ch1_78F8
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D#, 1
	SND_SEGNO
	VOICE $06, 0, 7, 13, 3
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE D_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C#, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C#, 1
	LOOP_END 4
	LOOP2_END 2
	VOICE $06, 0, 10, 13, 3
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
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
	OCTAVE 2
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
	VOICE $06, 0, 7, 13, 3
	LOOP2_START
	LOOP_START
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F_, 1
	LOOP_END 4
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	LOOP_END 4
	LOOP2_END 2
	SND_LOOP

SndEA_Ch3:
	VOICE $03, 12, 2, 11, 5
	VIBRATO $84, 0, 2
	SND_CALL SndEA_Ch1_78F8
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE D#, 1
	SND_SEGNO
	VOICE $06, 10, 2, 11, 5
	LOOP_START
	OCTAVE 2
	NOTE D_, 3
	NOTE D#, 3
	OCTAVE 3
	NOTE D_, 3
	NOTE D#, 3
	LOOP_END 8
	OCTAVE 2
	LOOP_START
	NOTE C_, 3
	NOTE D#, 3
	NOTE F#, 3
	NOTE A_, 3
	OCTAVE 3
	LOOP_END 2
	LOOP_START
	OCTAVE 2
	NOTE F_, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE F_, 3
	NOTE F#, 3
	LOOP_END 8
	SND_LOOP

SndEA_Drm:
	LEN_UNIT 6
	DRUM $0A, $0F
	SND_SEGNO
	SND_CALL SndEA_Drm_79F6
	DRUM 2, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 7, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 6, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 7, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	SND_CALL SndEA_Drm_79F6
	SND_LOOP
SndEA_Drm_79F6:
	LOOP_START
	DRUM 5, 3
	DRUM 5, 3
	DRUM $0B, 3
	DRUM 9, 3
	DRUM 5, 3
	DRUM 5, 3
	DRUM $0B, 3
	DRUM 3, 3
	LOOP_END 4
	SND_RET

SndEB_Ch1:
	VOICE $07, 0, 8, 13, 3
	REST 3
	CMD_ED $41
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 2
	LEN_UNIT 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 5
	SND_END

SndEB_Ch2:
	VOICE $07, 0, 8, 13, 3
	REST 3
	CMD_ED $41
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_HI, 2
	LEN_UNIT 1
	NOTE A#, 1
	NOTE B_, 1
	NOTE C_HI, 5
	SND_END

SndEB_Ch3:
	VOICE $07, 8, 2, 11, 3
	REST 3
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 1
	SND_END

SndEB_Drm:
	LEN_UNIT 7
	DRUM 6, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 1, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 1
	SND_END

SndEC_Ch1:
	TEMPO $30
	VOICE $06, 8, 8, 0, 0
	OCTAVE 3
	DETUNE $FF
	LOOP_START
	VOLUME $08
	LEN_UNIT 3
	NOTE A_, 3
	REST 1
	LEN_UNIT 6
	VOLUME $03
	NOTE A_, 2
	LOOP_END 3
	VOLUME $07
	OCTAVE 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, $0A
	LEN_UNIT 3
	REST $0C
	REST $0C
	SND_SEGNO
	TRANSPOSE_DOWN $0C
	VOICE $03, 0, 8, 13, 4
	SND_CALL SndEC_Ch1_7BA4
	VOICE $03, 8, 3, 5, 3
	TRANSPOSE_DOWN 0
	CMD_ED $00
	VIBRATO_OFF
	REST 2
	OCTAVE 3
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 3
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 4
	ATTEN 0
	NOTE D#, 6
	NOTE D_, 2
	NOTE C_, 4
	VOICE $03, 0, 8, 13, 4
	TRANSPOSE_DOWN $0C
	CMD_ED $42
	SND_CALL SndEC_Ch1_7BC8
	VOICE $03, 8, 3, 5, 3
	TRANSPOSE_DOWN 0
	CMD_ED $00
	VIBRATO_OFF
	REST 2
	NOTE G_, 6
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	VOICE $03, 0, 8, 13, 4
	TRANSPOSE_DOWN $0C
	CMD_ED $42
	REST 6
	OCTAVE 4
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 4
	ATTEN 0
	NOTE G_, 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	OCTAVE 5
	NOTE D#, 8
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	OCTAVE 4
	NOTE C_HI, 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	NOTE C_HI, $0E
	VOICE $03, 8, 3, 5, 3
	TRANSPOSE_DOWN 0
	CMD_ED $00
	VIBRATO_OFF
	REST 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	SND_LOOP

SndEC_Ch2:
	VOICE $06, 8, 8, 0, 0
	OCTAVE 3
	LOOP_START
	VOLUME $08
	LEN_UNIT 3
	NOTE A_, 3
	REST 1
	LEN_UNIT 6
	VOLUME $03
	NOTE A_, 2
	LOOP_END 3
	VOLUME $07
	OCTAVE 4
	NOTE A_, 2
	ATTEN 4
	NOTE A_, $0A
	LEN_UNIT 3
	REST $0C
	REST $0C
	SND_SEGNO
	VOICE $03, 0, 8, 13, 4
	SND_CALL SndEC_Ch1_7BA4
	VOICE $03, 8, 7, 13, 3
	CMD_ED $02
	OCTAVE 3
	NOTE C_HI, 4
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 3
	NOTE G_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE C_HI, 4
	OCTAVE 4
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE D#, 6
	NOTE D_, 2
	NOTE C_, 4
	ATTEN 5
	NOTE C_, 2
	ATTEN 0
	DUTY 0
	CMD_ED $42
	SND_CALL SndEC_Ch1_7BC8
	VOICE $03, 8, 7, 13, 3
	CMD_ED $02
	NOTE G_, 6
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	DUTY 0
	CMD_ED $42
	REST 6
	OCTAVE 4
	NOTE C_HI, 2
	ATTEN 5
	NOTE C_HI, 4
	ATTEN 0
	NOTE G_, 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	OCTAVE 5
	NOTE D#, 8
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	OCTAVE 4
	NOTE C_HI, 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	NOTE C_HI, $0E
	VOICE $03, 8, 7, 13, 3
	CMD_ED $02
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_HI, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE C_HI, 2
	VIBRATO $8D, 0, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	SND_LOOP
SndEC_Ch1_7BA4:
	CMD_ED $42
	VIBRATO $8D, 0, 6
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	NOTE G_, 1
	NOTE A_, 3
	NOTE G_, 2
	NOTE A_, 1
	NOTE A#, 3
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 4
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 4
	ATTEN 0
	NOTE E_, 6
	ATTEN 5
	NOTE E_, 2
	ATTEN 0
	SND_RET
SndEC_Ch1_7BC8:
	VIBRATO $8D, 0, 6
	OCTAVE 5
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 4
	ATTEN 0
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 4
	ATTEN 0
	NOTE D_, 4
	NOTE C_, 2
	NOTE D_, 1
	NOTE D#, 3
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 4
	ATTEN 0
	OCTAVE 4
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	NOTE F#, 1
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 4
	ATTEN 0
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 4
	ATTEN 0
	NOTE D#, 4
	NOTE C_, 2
	ATTEN 5
	NOTE C_, 4
	ATTEN 0
	SND_RET

SndEC_Ch3:
	VOICE $03, 11, 2, 11, 4
	REST $0C
	REST $0C
	REST $0C
	REST $0C
	REST $0C
	REST $0C
	SND_SEGNO
	SND_CALL SndEC_Ch3_7C71
	NOTE E_, 2
	NOTE G_, 2
	SND_CALL SndEC_Ch3_7C71
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE C_HI, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE C_HI, 2
	SND_CALL SndEC_Ch3_7C8E
	OCTAVE 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 2
	SND_CALL SndEC_Ch3_7C8E
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A#, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G#, 4
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 2
	SND_LOOP
SndEC_Ch3_7C71:
	OCTAVE 2
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 4
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE D#, 2
	SND_RET
SndEC_Ch3_7C8E:
	OCTAVE 2
	NOTE C_, 4
	NOTE C_HI, 2
	NOTE E_, 4
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 4
	OCTAVE 3
	NOTE G_, 2
	SND_RET

SndEC_Drm:
	LEN_UNIT 3
	REST $0C
	REST $0C
	REST $0C
	REST $0C
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 8, 6
	SND_SEGNO
	LOOP_START
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 2, 4
	DRUM 1, 2
	DRUM 9, 4
	DRUM 1, 2
	LOOP_END 4
	LOOP_START
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	LOOP_END 4
	SND_LOOP

SndEE_Ch1:
	VOICE $08, 0, 4, 13, 3
	REST 1
	SND_SEGNO
	DUTY 0
	OCTAVE 4
	SND_CALL SndEE_Ch1_7D1C
	DUTY $0C
	SND_CALL SndEE_Ch1_7D56
	SND_LOOP

SndEE_Ch2:
	VOICE $08, 4, 10, 15, 1
	OCTAVE 2
	SND_SEGNO
	LOOP_START
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	LOOP_END 6
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	LOOP_START
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	LOOP_END 8
	LOOP_START
	NOTE F_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	LOOP_END 8
	LOOP_START
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	LOOP_END 8
	SND_LOOP

SndEE_Ch3:
	SND_SEGNO
	VOICE $08, 5, 2, 12, 5
	OCTAVE 4
	SND_CALL SndEE_Ch1_7D1C
	VOICE $08, 1, 2, 13, 3
	OCTAVE 3
	SND_CALL SndEE_Ch1_7D56
	SND_LOOP
SndEE_Ch1_7D1C:
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	LOOP_START
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END 2
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 5
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	SND_RET
SndEE_Ch1_7D56:
	LOOP_START
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	LOOP_END 2
	SND_RET

SndEE_Drm:
	SND_END

SndEF_Ch1:
	LEN_UNIT 5
	REST 8
	SND_SEGNO
	VOICE $05, 0, 8, 13, 4
	SND_CALL SndEF_Ch1_7DAE
	TRANSPOSE_UP 2
	SND_CALL SndEF_Ch1_7DAE
	TRANSPOSE_UP 0
	SND_LOOP

SndEF_Ch2:
	LEN_UNIT 5
	REST 8
	SND_SEGNO
	VOICE $05, 0, 8, 13, 4
	SND_CALL SndEF_Ch2_7E0E
	TRANSPOSE_UP 2
	SND_CALL SndEF_Ch2_7E0E
	TRANSPOSE_UP 0
	SND_LOOP

SndEF_Ch3:
	LEN_UNIT 5
	REST 8
	SND_SEGNO
	VOICE $05, 2, 2, 11, 5
	SND_CALL SndEF_Ch3_7E5D
	TRANSPOSE_UP 2
	SND_CALL SndEF_Ch3_7E5D
	TRANSPOSE_UP 0
	SND_LOOP

SndEF_Drm:
	LEN_UNIT 5
	DRUM $0B, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM 8, 2
	DRUM 6, 1
	DRUM 6, 1
	SND_SEGNO
	LEN_UNIT 5
	SND_CALL SndEF_Drm_7E99
	SND_CALL SndEF_Drm_7E99
	SND_LOOP
SndEF_Ch1_7DAE:
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_HI, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 4
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	SND_RET
SndEF_Ch2_7E0E:
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE A#, 6
	NOTE A_, 4
	NOTE F_, 2
	NOTE D#, 6
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE C_HI, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE C_HI, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE C_HI, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE A#, 2
	SND_RET
SndEF_Ch3_7E5D:
	OCTAVE 2
	NOTE F_, 6
	NOTE A_, 6
	NOTE A#, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE D#, 4
	VOICE $05, 2, 4, 0, 0
	NOTE D#, 4
	VOICE $05, 2, 2, 11, 5
	OCTAVE 2
	NOTE F_, 6
	NOTE A_, 6
	NOTE A#, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 2
	NOTE G#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE D#, 4
	NOTE F_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE D#, 4
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	SND_RET
SndEF_Drm_7E99:
	LOOP_START
	DRUM 2, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 4
	LOOP_START
	DRUM 2, 2
	DRUM 5, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 5, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 1, 2
	LOOP_END 3
	DRUM 5, 2
	DRUM 5, 2
	DRUM $0B, 2
	DRUM 1, 2
	DRUM $0B, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 9, 2
	SND_RET

SndF0_Ch1:
	VOICE $05, 0, 5, 0, 0
	TRANSPOSE_UP 5
	REST 2
	VOICE $05, 0, 8, 13, 3
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	RELEASE $0A, 3
	OCTAVE 2
	NOTE G_, $0A
	SND_END

SndF0_Ch2:
	VOICE $05, 0, 5, 0, 0
	TRANSPOSE_UP 5
	REST 2
	VOICE $05, 0, 8, 13, 3
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	RELEASE $0A, 3
	NOTE C_, $0A
	SND_END

SndF0_Ch3:
	VOICE $05, 9, 2, 11, 3
	TRANSPOSE_UP 5
	OCTAVE 2
	NOTE C_, 2
	VOICE $05, 9, 6, 0, 0
	NOTE C_, 4
	VOICE $05, 9, 2, 11, 3
	NOTE C_HI, 2
	VOICE $05, 9, 6, 0, 0
	NOTE C_HI, 2
	VOICE $05, 9, 2, 11, 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	VOICE $05, 1, 2, 13, 3
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	VOICE $05, 8, 2, 11, 6
	OCTAVE 2
	NOTE C_, $0D
	SND_END

SndF0_Drm:
	LEN_UNIT 5
	DRUM 9, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 2, 2
	DRUM 1, 2
	DRUM 6, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 0
	SND_END

SndF1_Ch1:
	VOICE $05, 0, 6, 0, 0
	CMD_ED $81
	REST 1
	DETUNE $FF
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 7
	NOTE C_, 1
	SND_END

SndF1_Ch2:
	VOICE $05, 0, 5, 0, 0
	CMD_ED $81
	REST 2
	DETUNE $FE
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 7
	SND_END

SndF1_Ch3:
	VOICE $05, 8, 2, 11, 5
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	LOOP_START
	NOTE C_, 1
	NOTE C#, 1
	LOOP_END 8
	SND_END

SndF2_Sfx1:
	VOICE $04, 8, 5, 0, 0
	OCTAVE 4
	NOTE F#, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 3
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE E_, 1
	SND_END

SndF2_SfxN:
	NVOICE $06, $40
	NOISE $12
	NOISE $13
	NOISE $24
	NOISE $25
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $33
	NOISE $22
	NOISE $21
	NVOICE $06, $10
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $12
	NOISE $11
	SND_END

SndF3_Sfx1:
	VOICE $02, 8, 15, 0, 0
	SWEEP $1D
	OCTAVE 5
	NOTE C_HI, 0
	SWEEP $15
	OCTAVE 1
	NOTE C_HI, 0
	SND_END

SndF3_SfxN:
	NVOICE $04, $F0
	NOISE $27
	NVOICE $04, $76
	NOISE $63
	NOISE $53
	NOISE $43
	NOISE $33
	NOISE $23
	NOISE $13
	NOISE $03
	NVOICE $18, $10
	NOISE $34
	VOLUME $03
	NOISE $33
	VOLUME $02
	NOISE $32
	VOLUME $01
	NOISE $31
	NOISE $30
	SND_END
B15_BankEnd:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
